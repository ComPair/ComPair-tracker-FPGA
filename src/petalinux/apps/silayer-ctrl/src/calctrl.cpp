/* calctrl
 * =======
 * 
 * Program for controlling the external calibrator.
 *
 * Return codes:
 * -------------
 *      * 0: all good
 *      * 1: error parsing command line args
 */
#include <cstring> // strcmp

#include "cal_ctrl.hpp"

#define CAL_PARSE_ARGS_ERR 1

void usage(char *argv0) {
    std::cout << "Usage: " << argv0 << " [OPTIONS] [PULSE-FIRE-CMDS]" << std::endl
              << "  OPTIONS:" << std::endl
              << "    --cal-pulse-disable   : Disable the firing of calibration pulses." << std::endl
              << "                          : Default behavior: cal pulse is enabled." << std::endl
              << "    --vata-trigger-enable : Enable firing of vata triggers with calibration pulses." << std::endl
              << "                          : Default behavior: vata triggers disabled." << std::endl
              << "    --fast-or-disable     : Disable the fast-or trigger acceptance by vatas." << std::endl
              << "                          : Default behavior: fast-or is enabled." << std::endl
              << "    --pulse-width WIDTH   : Set the pulse width in number of clock cycles." << std::endl
              << "    --trigger-delay DELAY : Set the trigger delay in number of clock cyles." << std::endl
              << "    --repeat-delay DELAY  : Set the delay between successive calibration pulses." << std::endl
              << "    --set-cal-dac VALUE   : Set the calibration dac value." << std::endl
              << "  PULSE-FIRE-CMDS: only one of the below may be specified:" << std::endl
              << "    --start      : Start firing infinite train of calibration pulses." << std::endl
              << "    --stop       : Stop firing infinite set of calibration pulses." << std::endl
              << "    --n-pulses N : Fire N calibration pulses." << std::endl;
}

int parse_args(int argc, char **argv) {
    bool write_settings = false, start_inf = false, stop_inf = false, fire_cmd_issued = false;
    int n_pulses = -1;
    CalCtrl calctrl;
    for (int i=0; i<argc; i++) {
        if (strcmp("--help", argv[i]) == 0 || strcmp("-h", argv[i]) == 0) {
            // Exit and print usage...
            return CAL_PARSE_ARGS_ERR;
        } else if (strcmp("--cal-pulse-disable", argv[i]) == 0) { 
            calctrl.cal_pulse_ena = false; 
            write_settings = true;        
        } else if (strcmp("--vata-trigger-enable", argv[i]) == 0) { 
            calctrl.vata_trigger_ena = true; 
            write_settings = true;        
        } else if (strcmp("--fast-or-disable", argv[i]) == 0) { 
            calctrl.vata_fast_or_disable = true; 
            write_settings = true;        
        } else if (strcmp("--pulse-width", argv[i]) == 0) { 
            if (++i >= argc) {
                std::cerr << "ERROR: No pulse width specified." << std::endl;
                return CAL_PARSE_ARGS_ERR;
            }
            calctrl.cal_pulse_width = (u32)atoi(argv[i]);
            write_settings = true;
        } else if (strcmp("--trigger-delay", argv[i]) == 0) { 
            if (++i >= argc) {
                std::cerr << "ERROR: No trigger delay specified." << std::endl;
                return CAL_PARSE_ARGS_ERR;
            }
            calctrl.vata_trigger_delay = (u32)atoi(argv[i]);
            write_settings = true;
        } else if (strcmp("--repeat-delay", argv[i]) == 0) { 
            if (++i >= argc) {
                std::cerr << "ERROR: No repetition delay specified." << std::endl;
                return CAL_PARSE_ARGS_ERR;
            }
            calctrl.repetition_delay = (u32)atoi(argv[i]);
            write_settings = true;
        } else if (strcmp("--start", argv[i]) == 0) { 
            if (fire_cmd_issued) {
                std::cerr << "ERROR: Only one of '--start', '--stop', or '--n-pulses' can be issued." << std::endl;
                return CAL_PARSE_ARGS_ERR;
            }
            start_inf = true;
            fire_cmd_issued = true;
        } else if (strcmp("--stop", argv[i]) == 0) { 
            if (fire_cmd_issued) {
                std::cerr << "ERROR: Only one of '--start', '--stop', or '--n-pulses' can be issued." << std::endl;
                return CAL_PARSE_ARGS_ERR;
            }
            stop_inf = true;
            fire_cmd_issued = true;
        } else if (strcmp("--n-pulses", argv[i]) == 0) { 
            if (fire_cmd_issued) {
                std::cerr << "ERROR: Only one of '--start', '--stop', or '--n-pulses' can be issued." << std::endl;
                return CAL_PARSE_ARGS_ERR;
            }
            if (++i >= argc) {
                std::cerr << "ERROR: Number of pulses not provided." << std::endl;
                return CAL_PARSE_ARGS_ERR;
            }
            n_pulses = atoi(argv[i]);
            fire_cmd_issued = true;
        } else {
            std::cerr << "ERROR: Unrecognized command line option: " << argv[i] << std::endl;
            return CAL_PARSE_ARGS_ERR;
        }
    }

    if (write_settings) {
        calctrl.write_settings();
    } 

    if (start_inf) {
        calctrl.start_inf_pulses();
    } else if (stop_inf) {
        calctrl.stop_inf_pulses();
    } else if (n_pulses > 0) {
        calctrl.n_pulses((u32)n_pulses);
    }

    return 0;
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        usage(argv[0]);
        return CAL_PARSE_ARGS_ERR;
    }

    int ret;
    if ((ret = parse_args(argc-1, argv+1)) == CAL_PARSE_ARGS_ERR) {
        usage(argv[0]);
    }
    return ret;
}
// vim: set ts=4 sw=4 sts=4 et:
