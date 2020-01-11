CXX_FLAGS = -I$(HOME)/local/include -I$(HOME)/include -Wall
TARGETS = vtctrl_server vtctrl_client silayer_server

LD_FLAGS = -L$(HOME)/lib
SERVER_LIBS = -lzmq -lvatactrl

all: $(TARGETS)

vtctrl_server: vtctrl_server.cpp
	g++ -o $@ $(CXX_FLAGS) $(LD_FLAGS) $< $(SERVER_LIBS)

vtctrl_client: vtctrl_client.cpp
	g++ -o $@ $(CXX_FLAGS) $< -lzmq


silayer_server.o: silayer_server.cpp
	g++ -o $@ $(CXX_FLAGS) $<

data_emitter.o: data_emitter.cpp
	g++ -o $@ $(CXX_FLAGS) $<

silayer_server: data_emitter.o silayer_server.o
	g++ -o $@ $(CXX_FLAGS) $(LD_FLAGS) $< $(SERVER_LIBS)

clean:
	rm $(TARGETS) *~
