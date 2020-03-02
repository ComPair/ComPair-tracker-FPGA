#ifndef __RAW2HDF_H__
#define __RAW2HDF_H__
#include <Python.h>

// Unsure what numpy version is used on gse...
//#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION
//#include <numpy/arrayobject.h>

#include <stdio.h>  // fread, fopen, fclose, fprintf,...
#include <stdlib.h> // malloc, free
#include <stdint.h> // uint*_t
#include <string.h> // memcpy

#define CAPSULE_NAME "dp_parser_capsule"

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef struct DataPacket {
    u16 packet_size;
    u8 header_size;
    u16 packet_flags;
    u64 real_time_counter;
    u64 live_time_counter;
    u16 event_type;
    u32 event_counter;
    u8 nasic;
    u16 *asic_nbytes;
    u32 total_asic_sz;
    void *asic_data; 
} DataPacket;

// Exported functions
static PyObject *init_parser(PyObject *dummy, PyObject *args);
static PyObject *parse_data_packet(PyObject *dummy, PyObject *args);

static PyObject *bytes2packet(PyObject *dummy, PyObject *args);

// Private functions
PyObject *dp2dict(DataPacket *dp);
void destroy_capsule(PyObject *capsule);

#endif
// vim: set ts=4 sw=4 sts=4 et:
