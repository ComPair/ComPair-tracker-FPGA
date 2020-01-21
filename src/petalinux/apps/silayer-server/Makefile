CXX_FLAGS = -I$(HOME)/local/include -I$(HOME)/include -Wall
TARGETS = vtctrl_server vtctrl_client silayer_server

LD_FLAGS = -L$(HOME)/lib
SERVER_LIBS = -lzmq -lvatactrl

.PHONY: clean

all: $(TARGETS)

vtctrl_server: vtctrl_server.cpp
	g++ -o $@ $(CXX_FLAGS) $(LD_FLAGS) $< $(SERVER_LIBS)

vtctrl_client: vtctrl_client.cpp
	g++ -o $@ $(CXX_FLAGS) $< -lzmq

silayer_server.o: silayer_server.cpp
	g++ -o $@ $(CXX_FLAGS) -c $<

silayer_server_main.o: silayer_server_main.cpp
	g++ -o $@ $(CXX_FLAGS) -c $<

data_emitter.o: data_emitter.cpp
	g++ -o $@ $(CXX_FLAGS) -c $<

data_packet.o: data_packet.cpp
	g++ -o $@ $(CXX_FLAGS) -c $<

silayer_server: data_packet.o data_emitter.o silayer_server.o
	g++ -o $@ $(LD_FLAGS) $< $(SERVER_LIBS)

clean:
	$(RM) $(TARGETS) *.o *~

