CXX_FLAGS = -std=c++11 -I$(HOME)/local/include -I$(HOME)/include -Wall
TARGETS = vtctrl_server vtctrl_client silayer_server

LD_FLAGS = -L$(HOME)/lib
SERVER_LIBS = -lzmq -lvatactrl

all: $(TARGETS)

vtctrl_server: vtctrl_server.cpp
	g++ -o $@ $(CXX_FLAGS) $(LD_FLAGS) $< $(SERVER_LIBS)

vtctrl_client: vtctrl_client.cpp
	g++ -o $@ $(CXX_FLAGS) $< -lzmq

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

clean:
	rm *~ *.o
