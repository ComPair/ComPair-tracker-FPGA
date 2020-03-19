/* syncctrl
 * =======
 * 
 * Program for controlling the signals synchronous to all vata's
 *
 * Return codes:
 * -------------
 *      * 0: all good
 *      * 1: error parsing command line args
 */
#include <cstring> // strcmp

#include "sync_ctrl.hpp"

#define SYNC_PARSE_ARGS_ERR 1

void usage(char *argv0) {
    std::cout << "Usage: " << argv0 << " [OPTIONS]" << std::endl
              << "  OPTIONS:" << std::endl
              << "    --counter-reset : Reset the global counter." << std::endl
              << "    --get-counter   : Print the current counter value to stdout." << std::endl
              << "    --force-trigger : Force trigger all ASIC's simultaneously. NOT YET IMPLEMENTED." << std::endl;

}

int parse_args(int argc, char **argv) {
    SyncCtrl syncctrl;
    for (int i=0; i<argc; i++) {
        if (strcmp("--help", argv[i]) == 0 || strcmp("-h", argv[i]) == 0) {
            // Exit and print usage...
            return SYNC_PARSE_ARGS_ERR;
        } else if (strcmp("--counter-reset", argv[i]) == 0) { 
            syncctrl.counter_reset();
        } else if (strcmp("--get-counter", argv[i]) == 0) { 
            u64 counter = syncctrl.get_counter();
            std::cout << counter << std::endl;
        } else {
            std::cerr << "ERROR: Unrecognized command line option: " << argv[i] << std::endl;
            return SYNC_PARSE_ARGS_ERR;
        }
    }

    return 0;
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        usage(argv[0]);
        return SYNC_PARSE_ARGS_ERR;
    }

    int ret;
    if ((ret = parse_args(argc-1, argv+1)) == SYNC_PARSE_ARGS_ERR) {
        usage(argv[0]);
    }
    return ret;
}
// vim: set ts=4 sw=4 sts=4 et:
