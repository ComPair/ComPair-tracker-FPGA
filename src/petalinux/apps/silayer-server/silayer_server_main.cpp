#include "silayer_server.hpp"

int main (int argc, char **argv) {
    // Setup logging first
    loguru::init(argc, argv);
    char log_file[128];
    loguru::suggest_log_path("~/zynq/log/", log_file, 128);
    loguru::add_file(log_file, loguru::Append, loguru::Verbosity_MAX);

    // Now run the server.
    LayerServer layer_server;
    return layer_server.run();
}
// vim: set ts=4 sw=4 sts=4 et:
