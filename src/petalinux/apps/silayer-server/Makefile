##CXX_FLAGS = -std=c++11 -I$(HOME)/local/include -I$(HOME)/include -Wall
ZYNQ = $(HOME)/zynq
LOCAL = $(HOME)/local
CXX_FLAGS = -std=c++11 -I$(LOCAL)/include -I$(ZYNQ)/include -I$(ZYNQ)/include/bsp -Wall
TARGETS = silayer_server

LD_FLAGS = -L$(ZYNQ)/lib -L$(LOCAL)/lib
SERVER_LIBS = -lzmq -lsictrl

all: $(TARGETS)

silayer_server.o: silayer_server.cpp silayer_server.hpp
	g++ -o $@ $(CXX_FLAGS) -c $<

data_emitter.o: data_emitter.cpp data_emitter.hpp
	g++ -o $@ $(CXX_FLAGS) -c $<

data_packet.o: data_packet.cpp data_packet.hpp
	g++ -o $@ $(CXX_FLAGS) -c $<

silayer_server_main.o: silayer_server_main.cpp
	g++ -o $@ $(CXX_FLAGS) -c $<

silayer_server: data_packet.o data_emitter.o silayer_server.o silayer_server_main.o
	g++ -o $@ $(LD_FLAGS) $^ $(SERVER_LIBS) -pthread

install: $(TARGETS)
	install -d $(ZYNQ)/bin
	install -m 755 silayer_server $(ZYNQ)/bin

clean:
	$(RM) *~ *.o

.PHONY: clean
