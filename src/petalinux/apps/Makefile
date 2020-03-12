
BUILD = dbe_production
SILAYER_IP = 192.168.1.69

all: server

server: ctrl
	cd build-scripts && ./make-server $(SILAYER_IP)

ctrl: lib
	cd build-scripts && ./make-ctrl $(SILAYER_IP)

lib: zynq-dirs
	cd build-scripts && ./make-lib $(SILAYER_IP)

zynq-dirs:
	cd build-scripts && ./make-zynq-dirs $(BUILD) $(SILAYER_IP)

.PHONY: zynq-dirs lib ctrl server
