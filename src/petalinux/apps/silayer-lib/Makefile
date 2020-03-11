CC = g++
TARGET = libsictrl.a
SRCS = src/cal_ctrl.cpp src/dac_ctrl.cpp src/vata_ctrl.cpp

ZYNQ_DIR = $(HOME)/zynq

CXXFLAGS = -std=c++11 -Wall -I./include -I$(ZYNQ_DIR)/include


all: $(TARGET)

$(TARGET): sictrl.o
	ar rcs $@ $<

sictrl.o: $(SRCS)
	$(CC) $(CXXFLAGS) -c $^ -o $@

