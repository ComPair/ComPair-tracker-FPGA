CC = g++
TARGET = libsictrl.a
OBJS = src/cal_ctrl.o src/dac_ctrl.o src/sync_ctrl.o src/vata_ctrl.o

ZYNQ_DIR = $(HOME)/zynq

CXXFLAGS = -std=c++11 -Wall -I./include -I $(ZYNQ_DIR)/include/bsp -I$(ZYNQ_DIR)/include


all: $(TARGET)

$(TARGET): $(OBJS)
	ar rcs $@ $^

install: $(TARGET)
	install -d $(ZYNQ_DIR)/include
	install -m 644 include/*.hpp $(ZYNQ_DIR)/include
	install -d $(ZYNQ_DIR)/lib
	install -m 644 $(TARGET) $(ZYNQ_DIR)/lib

src/cal_ctrl.o: src/cal_ctrl.cpp
	$(CC) $(CXXFLAGS) -o $@ -c $^ 

src/dac_ctrl.o: src/dac_ctrl.cpp
	$(CC) $(CXXFLAGS) -o $@ -c $^ 

src/sync_ctrl.o: src/sync_ctrl.cpp
	$(CC) $(CXXFLAGS) -o $@ -c $^ 

src/vata_ctrl.o: src/vata_ctrl.cpp
	$(CC) $(CXXFLAGS) -o $@ -c $^ 

clean:
	$(RM) src/*.o *~
