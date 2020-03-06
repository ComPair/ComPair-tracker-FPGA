#include "raw2hdf.h"

struct module_state {
    PyObject *error;
};

static PyMethodDef raw2hdf_methods[] = {
    {"init_parser", init_parser, METH_VARARGS,
        "init_parser(fname): Initialize the data packet parser. Returns a capsule\n"
        "                    Fname is path to data file."},
    {"parse_data_packet", parse_data_packet, METH_VARARGS,
        "parse_data_packets(capsule): Parse a data packet."
        "                             Return a dictionary of parsed data."},
    {"bytes2packet", bytes2packet, METH_VARARGS,
        "bytes2packet(b : bytes) -> dict()
        "   Parse bytes, returns a dictionary with the data packet data."
    {NULL, NULL, 0, NULL}
};

static int raw2hdf_traverse(PyObject *m, visitproc visit, void *arg) {
    Py_VISIT(((struct module_state*)PyModule_GetState(m))->error);
    return 0;
}

static int raw2hdf_clear(PyObject *m) {
    Py_CLEAR(((struct module_state*)PyModule_GetState(m))->error);
    return 0;
}

static struct PyModuleDef moduledef = {
    PyModuleDef_HEAD_INIT,
    "_raw2hdf",
    NULL,
    sizeof(struct module_state),
    raw2hdf_methods,
    NULL,
    raw2hdf_traverse,
    raw2hdf_clear,
    NULL
};

PyMODINIT_FUNC PyInit__raw2hdf(void) {
    PyObject *module = PyModule_Create(&moduledef);
    if (module == NULL)
        return NULL;
    return module;
}

/*     init_parser
 * Currently this will just open a FILE, return a capsule of the FILE pointer.
 */
static PyObject *init_parser(PyObject *dummy, PyObject *args) {
    char *fname; // Does this need to be freed???
    if (!PyArg_ParseTuple(args, "s", &fname)) {
        fprintf(stderr, "Error: usage: init_parser(fname)\n");
        return NULL;
    }
    FILE *fp = fopen(fname, "r");
    if (fp == NULL) {
        fprintf(stderr, "Error: fopen failed on file %s\n", fname);
        return NULL;
    }
    return PyCapsule_New((void *)fp, CAPSULE_NAME, &destroy_capsule);
}

/*     parse_data_packet
 * Return a dictionary for the given data packet.
 * Asic data returned as bytes. I think.
 */
static PyObject *parse_data_packet(PyObject *dummy, PyObject *args) {
    PyObject *capsule;
    if (!PyArg_ParseTuple(args, "O", &capsule)) {
        fprintf(stderr, "Error: usage: parse_data_packet(capsule)\n");
        return NULL;
    }
    FILE *fp = PyCapsule_GetPointer(capsule, CAPSULE_NAME);
    if (feof(fp) != 0) {
        return PyDict_New();
    }
    DataPacket dp;
    fread(&(dp.packet_size), sizeof(u16), 1, fp);
    fread(&(dp.header_size), sizeof(u8), 1, fp);
    fread(&(dp.packet_flags), sizeof(u16), 1, fp);
    fread(&(dp.real_time_counter), sizeof(u64), 1, fp);
    fread(&(dp.live_time_counter), sizeof(u64), 1, fp);
    fread(&(dp.event_type), sizeof(u16), 1, fp);
    fread(&(dp.event_counter), sizeof(u32), 1, fp);
    fread(&(dp.nasic), sizeof(u8), 1, fp);
    dp.asic_nbytes = (u16 *)malloc(dp.nasic * sizeof(u16));
    fread(dp.asic_nbytes, sizeof(u16), dp.nasic, fp);
    dp.total_asic_sz = 0;
    for(u8 i=0; i<dp.nasic; i++) {
        if (dp.asic_nbytes[i] > 0)
            dp.asic_nbytes[i]--; // XXX KLUDGE!!!! THIS SUCKS!!!!
        dp.total_asic_sz += (u32)dp.asic_nbytes[i];
    }
    dp.asic_data = malloc(sizeof(u8) * dp.total_asic_sz);
    fread(dp.asic_data, sizeof(u8), dp.total_asic_sz, fp);
    PyObject *dp_dict = dp2dict(&dp);

    free(dp.asic_nbytes);
    // XXX Unusre if PyBytes_FromStringAndSize does a copy so that this is safe:
    free(dp.asic_data);
    return dp_dict;
}

static PyObject *bytes2packet(PyObject *dummy, PyObject *args) {
    PyObject *py_bytes;
    if (!PyArg_ParseTuple(args, "O", &py_bytes)) {
        fprintf(stderr, "Error: usage: bytes2packet(bytes)\n");
        return NULL;
    }
    char *data = PyBytes_AsString(py_bytes);

    DataPacket dp;
    memcpy(&(dp.packet_size), data, sizeof(u16)); data += sizeof(u16);
    memcpy(&(dp.header_size), data, sizeof(u8)); data += sizeof(u8);
    memcpy(&(dp.packet_flags), data, sizeof(u16)); data += sizeof(u16);
    memcpy(&(dp.real_time_counter), data, sizeof(u64)); data += sizeof(u64);
    memcpy(&(dp.live_time_counter), data, sizeof(u64)); data += sizeof(u64);
    memcpy(&(dp.event_type), data, sizeof(u16)); data += sizeof(u16);
    memcpy(&(dp.event_counter), data, sizeof(u32)); data += sizeof(u32);
    memcpy(&(dp.nasic), data, sizeof(u8)); data += sizeof(u8);
    dp.asic_nbytes = (u16 *)malloc(dp.nasic * sizeof(u16));
    memcpy(dp.asic_nbytes, data, dp.nasic * sizeof(u16)); data += dp.nasic * sizeof(u16);
    dp.total_asic_sz = 0;
    for(u8 i=0; i<dp.nasic; i++) {
        if (dp.asic_nbytes[i] > 0)
            dp.asic_nbytes[i]--; // XXX KLUDGE!!!! THIS SUCKS!!!!
        dp.total_asic_sz += (u32)dp.asic_nbytes[i];
    }
    dp.asic_data = malloc(dp.total_asic_sz * sizeof(u8));
    memcpy(dp.asic_data, data, dp.total_asic_sz * sizeof(u8));
    PyObject *dp_dict = dp2dict(&dp);
    free(dp.asic_nbytes);
    free(dp.asic_data);
    return dp_dict;
}

/*     dp2dict
 * function that turns DataPacket struct into a PyObject dictionary...
 */
PyObject *dp2dict(DataPacket *dp) {
    PyObject *dict = PyDict_New();
    PyDict_SetItemString(dict, "packet_size", PyLong_FromUnsignedLong((unsigned long)dp->packet_size));
    PyDict_SetItemString(dict, "header_size", PyLong_FromUnsignedLong((unsigned long)dp->header_size));
    PyDict_SetItemString(dict, "packet_flags", PyLong_FromUnsignedLong((unsigned long)dp->packet_flags));
    PyDict_SetItemString(dict, "real_time_counter", PyLong_FromUnsignedLong((unsigned long)dp->real_time_counter));
    PyDict_SetItemString(dict, "live_time_counter", PyLong_FromUnsignedLong((unsigned long)dp->live_time_counter));
    PyDict_SetItemString(dict, "event_type", PyLong_FromUnsignedLong((unsigned long)dp->event_type));
    PyDict_SetItemString(dict, "event_counter", PyLong_FromUnsignedLong((unsigned long)dp->event_counter));
    PyDict_SetItemString(dict, "nasic", PyLong_FromUnsignedLong((unsigned long)dp->nasic));

    // XXX HOW DO REFS WORK WITH py_asic_nbytes??? XXX
    PyObject *py_asic_nbytes = PyList_New(dp->nasic);
    for (u8 i=0; i<dp->nasic; i++)
        PyList_SetItem(py_asic_nbytes, i, PyLong_FromUnsignedLong((unsigned long)(dp->asic_nbytes[i])));

    PyDict_SetItemString(dict, "asic_nbytes", py_asic_nbytes);
    PyDict_SetItemString(dict, "asic_data", PyBytes_FromStringAndSize((char *)dp->asic_data, dp->total_asic_sz));

    return dict;
}

void destroy_capsule(PyObject *capsule) {
    FILE *fp = PyCapsule_GetPointer(capsule, CAPSULE_NAME);
    fclose(fp);
}
    
// vim: set ts=4 sw=4 sts=4 et:
