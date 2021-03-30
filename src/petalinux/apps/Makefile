# BUILD = dbe_production
SILAYER_IP = $(ZYNQIP) 

all: server

## This one takes a while (~15 minutes).
## Currently not automatically run when building server,
## although it is a dependency of the server.
zmq:
	cd build-scripts && ./make-zmq.sh $(SILAYER_IP)

loguru:
	cd build-scripts && ./make-loguru.sh $(SILAYER_IP)

server: ctrl
	cd build-scripts && ./make-server.sh $(SILAYER_IP)

ctrl: lib
	cd build-scripts && ./make-ctrl.sh $(SILAYER_IP)

lib: zynq-dirs
	cd build-scripts && ./make-lib.sh $(SILAYER_IP)

supervisord:
	cd build-scripts && ./make-supervisord.sh $(SILAYER_IP)

## This will scp over the bps headers.
zynq-dirs:
	cd build-scripts && ./make-zynq-dirs.sh $(BUILD) $(SILAYER_IP)

.PHONY: zmq loguru server ctrl lib supervisord zynq-dirs zynq-dirs
