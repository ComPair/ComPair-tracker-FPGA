/* dacctrl
 * =======
 * 
 * Program for dealing with the dac.
 *
 * Return codes:
 * -------------
 *      * 0: all good
 *      * 1: error parsing command line args
 *      * 2: invalid dac value.
 *      * 3: invalid dac delay.
 */

#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <cstring> // strcmp

#include "dac_ctrl.hpp"

#define PARSE_ARGS_ERR 1
#define DAC_VALUE_ERR  2
#define DAC_DELAY_ERR  3

void usage(char *argv0) {
    std::cout << "Usage: " << argv0 << " [OPTIONS] [PULSE-FIRE-CMDS]" << std::endl
              << "  OPTIONS:" << std::endl
              << "    --set-delay DELAY : Set the delay value." << std::endl
              << "    --get-delay       : Print the current delay value." << std::endl
              << "    --set-counts SIDE DAC VALUE : Set the dac input to the given value." << std::endl
              << "    --get-input       : Print the current input value, according to the axi register." << std::endl;
}

//int parse_set_counts_args(char *silayer_side_str, char *dac_choice_str, char *counts_str,
//        enum SilayerSide *silayer_side, enum DacChoice *dac_choice, u32 *counts) {
//    if (parse_silayer_side(silayer_side_str, silayer_side) != 0)
//        return 1;
//    if (parse_dac_choice(dac_choice_str, dac_choice) != 0)
//        return 1;
//    *counts = (u32)atoi(counts_str); 
//    return 0; // success
//}

int parse_args(int argc, char **argv) {
    DacCtrl dacctrl;
    for (int i=0; i<argc; i++) {
        if (strcmp("--help", argv[i]) == 0 || strcmp("-h", argv[i]) == 0) {
            // Exit and print usage...
            return PARSE_ARGS_ERR;
        } else if (strcmp("--set-delay", argv[i]) == 0) { 
            if (++i >= argc) {
                std::cerr << "ERROR: No delay value specified." << std::endl;
                return PARSE_ARGS_ERR;
            }
            if (dacctrl.set_delay((u32)atoi(argv[i])) == 1) {
                std::cerr << "ERROR: Delay value too large." << std::endl;
                return DAC_DELAY_ERR;
            }
        } else if (strcmp("--get-delay", argv[i]) == 0) { 
            std::cout << dacctrl.get_delay() << std::endl;
            
        } else if (strcmp("--set-counts", argv[i]) == 0) { 
            if ((++i)+2 >= argc) {
                std::cerr << "ERROR: Must pass <SIDE> <DAC> <VALUE> with --set_counts." << std::endl;
                return PARSE_ARGS_ERR;
            }
            enum SilayerSide silayer_side;
            enum DacChoice dac_choice;
            u32 counts;
            if (parse_set_counts_args(argv[i], argv[i+1], argv[i+2], &silayer_side, &dac_choice, &counts) != 0) {
                // Could not parse silayer_side and/or dac_choice
                std::cerr << "ERROR: Could not parse " << argv[i] << " as SilayerSide, " 
                          << argv[i+1] << " as DacChoice." << std::endl;
                return PARSE_ARGS_ERR;
            }
            if (dacctrl.set_counts(silayer_side, dac_choice, counts) == 1) {
                std::cerr << "ERROR: Input value too large." << std::endl;
                return DAC_VALUE_ERR;
            }
            i += 2;
        } else if (strcmp("--get-input", argv[i]) == 0) { 
            std::cout << dacctrl.get_input() << std::endl;
        } else {
            std::cerr << "ERROR: Unrecognized command line option: " << argv[i] << std::endl;
            return PARSE_ARGS_ERR;
        }
    }
    return 0;
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        usage(argv[0]);
        return PARSE_ARGS_ERR;
    }

    int ret;
    if ((ret = parse_args(argc-1, argv+1)) == PARSE_ARGS_ERR) {
        usage(argv[0]);
    }
    return ret;
}

// vim: set ts=4 sw=4 sts=4 et:
