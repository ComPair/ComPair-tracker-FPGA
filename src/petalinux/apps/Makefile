# BUILD = dbe_production
SILAYER_IP = $(ZYNQ-IP-ADDR) #10.10.0.11

all: server

## This one takes a while (~15 minutes).
## Currently not automatically run when building server,
## although it is a dependency of the server.
zmq:
	cd build-scripts && ./make-zmq $(SILAYER_IP)

server: ctrl
	cd build-scripts && ./make-server $(SILAYER_IP)

ctrl: lib
	cd build-scripts && ./make-ctrl $(SILAYER_IP)

lib: zynq-dirs
	cd build-scripts && ./make-lib $(SILAYER_IP)

## This will scp over the bps headers.
zynq-dirs:
	cd build-scripts && ./make-zynq-dirs $(BUILD) $(SILAYER_IP)

.PHONY: zynq-dirs lib ctrl server
