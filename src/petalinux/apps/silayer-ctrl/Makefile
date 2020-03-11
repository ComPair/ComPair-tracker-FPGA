CC = g++

ZYNQ_DIR = $(HOME)/zynq

CXXFLAGS = -std=c++11 -Wall -I./include -I$(ZYNQ_DIR)/include
LDFLAGS = -L$(ZYNQ_DIR)/lib -lsictrl

TARGETS = calctrl dacctrl vatactrl

all: $(TARGETS)

calctrl: src/calctrl.cpp
	$(CC) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

dacctrl: src/dacctrl.cpp
	$(CC) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

vatactrl: src/vatactrl.cpp
	$(CC) $(CXXFLAGS) -o $@ $< $(LDFLAGS)


install: $(TARGET)
	install -d $(ZYNQ_DIR)/bin
	install -m 755 calctrl $(ZYNQ_DIR)/bin
	install -m 755 dacctrl $(ZYNQ_DIR)/bin
	install -m 755 vatactrl $(ZYNQ_DIR)/bin

clean:
	$(RM) *~
