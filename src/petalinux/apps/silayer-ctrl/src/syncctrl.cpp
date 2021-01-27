/* syncctrl
 * =======
 * 
 * Program for controlling the signals synchronous to all vata's
 *
 * Return codes:
 * -------------
 *      * 0: All good.
 *      * 1: Error parsing command line args.
 *      * 2: Invalid asic number.
 */
#include <cstring> // strcmp

#include "sync_ctrl.hpp"

#define SYNC_PARSE_ARGS_ERR 1
#define SYNC_BAD_ASIC_NUM_ERR 2

void usage(char *argv0) {
    std::cout << "Usage: " << argv0 << " [OPTIONS]" << std::endl
              << "  OPTIONS:" << std::endl
              << "    --counter-reset         : Reset the global counter." << std::endl
              << "    --get-counter           : Print the current counter value to stdout." << std::endl
              << "    --force-trigger         : Force trigger all ASIC's simultaneously." << std::endl
              << "    --get-global-hit-enable : Print the global hit enable bit value (1 or 0)." << std::endl
              << "    --global-hit-enable     : Enable the global hit bit." << std::endl
              << "    --global-hit-disable    : Disable the global hit bit." << std::endl
              << "    --asic-hit-disable N    : Disable hits from asic `N`." << std::endl
              << "    --asic-hit-enable N     : Enable hits from asic `N`." << std::endl
              << "    --asic-hit-disable-mask : Print the current asic-hit-disable bitmask (asic0 bit is last)." << std::endl;
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
        } else if (strcmp("--force-trigger", argv[i]) == 0) {
            syncctrl.force_trigger();
        } else if (strcmp("--get-global-hit-enable", argv[i]) == 0) {
            std::cout << syncctrl.is_global_hit_enabled() << std::endl;
        } else if (strcmp("--global-hit-enable", argv[i]) == 0) {
            syncctrl.global_hit_enable();
        } else if (strcmp("--global-hit-disable", argv[i]) == 0) {
            syncctrl.global_hit_disable();
        } else if (strcmp("--asic-hit-disable", argv[i]) == 0) {
            if (++i >= argc) {
                std::cerr << "ERROR: No asic number provided." << std::endl;
                return SYNC_PARSE_ARGS_ERR;
            }
            int asic = atoi(argv[i]);
            if (syncctrl.asic_hit_disable(asic) != 0) {
                std::cerr << "ERROR: Bad asic number provided." << std::endl;
                return SYNC_BAD_ASIC_NUM_ERR;
            }
        } else if (strcmp("--asic-hit-enable", argv[i]) == 0) {
            if (++i >= argc) {
                std::cerr << "ERROR: No asic number provided." << std::endl;
                return SYNC_PARSE_ARGS_ERR;
            }
            int asic = atoi(argv[i]);
            if (syncctrl.asic_hit_enable(asic) != 0) {
                std::cerr << "ERROR: Bad asic number provided." << std::endl;
                return SYNC_BAD_ASIC_NUM_ERR;
            }
        } else if (strcmp("--asic-hit-disable-mask", argv[i]) == 0) {
            u32 mask = syncctrl.get_asic_hit_disable_mask();
            for (int j = N_VATA-1; j >= 0; j--) {
                u32 bit = (mask & (1 << j)) >> j;
                std::cout << bit;
            }
            std::cout << std::endl;
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
