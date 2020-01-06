/* vatactrl
 * ========
 * 
 * Program for performing basic interactions with a single vata asic.
 *
 * Return codes:
 * -------------
 *      * 0: all good
 *      * 1: error parsing command line args
 *      * 2: invalid vata number provided
 *      * 3: error setting asic configuration.
 *      * 4: invalid cal-dac value.
 */

#include <cassert>
#include <cstring>

#include "vata_ctrl.hpp"

#define VT_PARSE_ARGS_ERR 1
#define VT_VATA_NUM_ERR   2
#define VT_SET_CONFIG_ERR 3
#define VT_CAL_DAC_ERR    4

void usage(char *argv0) {
    std::cout << "Usage: " << argv0 << " ASIC-NUM [OPTIONS]" << std::endl
              << "  ASIC-NUM : Number of the ASIC we are targeting" << std::endl
              << "  OPTIONS:" << std::endl
              << "    --set-config FNAME  : set configuration from file FNAME" << std::endl
              << "    --get-config FNAME  : get configuration, write to file FNAME" << std::endl
              << "    --set-hold HOLD     : set the ASIC hold time to HOLD clk-cycles" << std::endl
              << "    --get-hold          : write ASIC hold time to stdout" << std::endl
              << "    --get-counters      : print 'running' and 'live' counters to stdout" << std::endl
              << "    --reset-counters    : reset the 'running' and 'live' counters" << std::endl
              << "    --trigger-enable    : enable triggered data readout" << std::endl
              << "    --trigger-disable   : disable triggered data readout" << std::endl
              << "    --get-event-count   : print event counter to stdout" << std::endl
              << "    --reset-event-count : reset the event counter" << std::endl
              << "    --cal-pulse         : fire the external calibrator" << std::endl
              << "    --set-cal-dac VALUE : set the external calibrator dac value to VALUE" << std::endl
              << "    --get-n-fifo        : print number of data packets in fifo to stdout" << std::endl
              << "    --single-read-fifo  : read a single data packet, print to stdout" << std::endl
              << "    --read-fifo         : read the entire fifo, each packet to a single line of stdout" << std::endl;
}

VataCtrl get_vata_from_args(int argc, char **argv) {
    assert (argc > 1);    
    char *endptr;
    int nvata = strtol(argv[1], &endptr, 0);
    if (*endptr != '\0') {
        // Could not parse arg... throw error
        std::cerr << "ERROR: first argument (" << argv[1] << ") is not a number." << std::endl;
        throw 1;
    }
    if (nvata < 0 || nvata >= N_VATA) {
        std::cerr << "ERROR: Provided vata number (" << argv[1] << ") is not valid." << std::endl;
        std::cerr << "       Vata number should be in [0, " << N_VATA << ")." << std::endl;
        throw 2;
    }
    return VataCtrl(nvata);
}

int parse_args(VataCtrl vata, int argc, char **argv) {
    for (int i=0; i<argc; i++) {
        if (strcmp("--help", argv[i]) == 0 || strcmp("-h", argv[i]) == 0) {
            // Exit and print usage...
            return VT_PARSE_ARGS_ERR;
        } else if (strcmp("--set-config", argv[i]) == 0) { 
            if (++i >= argc) {
                std::cerr << "ERROR: No configuration source file given." << std::endl;
                return VT_PARSE_ARGS_ERR;
            }
            if (!vata.set_check_config(argv[i])) {
                std::cerr << "ERROR: Configuration file setting unsuccessful." << std::endl;
                return VT_SET_CONFIG_ERR;
            }
        } else if (strcmp("--get-config", argv[i]) == 0) { 
            if (++i >= argc) {
                std::cerr << "ERROR: No configuration destination file given." << std::endl;
                return VT_PARSE_ARGS_ERR;
            }
            vata.get_config(argv[i]); 
        } else if (strcmp("--set-hold", argv[i]) == 0) { 
            if (++i >= argc) {
                std::cerr << "ERROR: No hold time specified." << std::endl;
                return VT_PARSE_ARGS_ERR;
            }
            u32 hold_time = (u32)atoi(argv[i]);
            vata.set_hold_delay(hold_time);
        } else if (strcmp("--get-hold", argv[i]) == 0) { 
            int hold_time = (int)vata.get_hold_delay();
            std::cout << hold_time << std::endl;
        } else if (strcmp("--get-counters", argv[i]) == 0) { 
            u64 running, live;
            vata.get_counters(running, live);
            std::cout << running << " " << live << std::endl;
        } else if (strcmp("--reset-counters", argv[i]) == 0) { 
            vata.reset_counters();
        } else if (strcmp("--trigger-enable", argv[i]) == 0) { 
            vata.trigger_enable();
        } else if (strcmp("--trigger-disable", argv[i]) == 0) { 
            vata.trigger_disable();
        } else if (strcmp("--get-event-count", argv[i]) == 0) { 
            std::cout << vata.get_event_count() << std::endl;
        } else if (strcmp("--reset-event-count", argv[i]) == 0) { 
            vata.reset_event_count();
        } else if (strcmp("--cal-pulse", argv[i]) == 0) { 
            vata.cal_pulse_trigger();
        } else if (strcmp("--set-cal-dac", argv[i]) == 0) { 
            if (++i >= argc) {
                std::cerr << "ERROR: No calibration dac value provided." << std::endl;
                return VT_PARSE_ARGS_ERR;
            }
            u32 dac_value = (u32)atoi(argv[i]);
            if (vata.set_cal_dac(dac_value) != 0) {
                std::cerr << "ERROR: Invalid dac value (" << dac_value << ")." << std::endl
                          << "       dac_value must be in [0, " << MAX_CAL_DAC_VAL << ")." << std::endl;
                return VT_CAL_DAC_ERR;
            }
        } else if (strcmp("--cal-pulse", argv[i]) == 0) { 
            vata.cal_pulse_trigger();
        } else if (strcmp("--get-n-fifo", argv[i]) == 0) { 
            std::cout << vata.get_n_fifo() << std::endl;
        } else if (strcmp("--single-read-fifo", argv[i]) == 0) { 
            if (vata.get_n_fifo() == 0) {
                std::cout << "FIFO empty." << std::endl;
            } else { 
                std::vector<u32> data;
                int nread;
                u32 nremain;
                vata.read_fifo(data, nread, nremain);
                for (int i=0; i<nread; i++) {
                    printf("%08X", data[i]);
                }
                std::cout << std::endl;
            }
        } else if (strcmp("--read-fifo", argv[i]) == 0) { 
            if (vata.get_n_fifo() == 0) {
                std::cout << "FIFO empty." << std::endl;
            } else { 
                std::vector<u32> data;
                int nread;
                u32 nremain;
                while (vata.get_n_fifo() > 0) {
                    vata.read_fifo(data, nread, nremain);
                    for (int i=0; i<nread; i++) {
                        printf("%08X", data[i]);
                    }
                    std::cout << std::endl;
                }
            }
        } else {
            std::cerr << "ERROR: Unrecognized command line option: " << argv[i] << std::endl;
            return VT_PARSE_ARGS_ERR;
        }
    }
    return 0;
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        usage(argv[0]);
        return VT_PARSE_ARGS_ERR;
    }

    VataCtrl vata;
    try {
        vata = get_vata_from_args(argc, argv);
    } catch (int e) {
        usage(argv[0]);
        return VT_VATA_NUM_ERR;
    }

    int ret;
    if ((ret = parse_args(vata, argc-2, argv+2)) == VT_PARSE_ARGS_ERR) {
        usage(argv[0]);
    }
    return ret;
}
// vim: set ts=4 sw=4 sts=4 et:
