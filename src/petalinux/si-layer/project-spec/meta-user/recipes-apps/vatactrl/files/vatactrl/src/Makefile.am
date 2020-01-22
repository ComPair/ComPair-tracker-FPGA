AM_CXXFLAGS = -g -std=c++11 -Wall -fPIC

bin_PROGRAMS = vatactrl             \
               vt_set_conf          \
               vt_get_conf          \
               vt_set_cal_dac       \
               vt_cal_pulse_trigger \
               ##vt_cal_pulse_repeat  \
               vt_set_hold_delay    \
               vt_get_hold_delay    \
               vt_force_trigger     \
               ##vt_trigger_and_acq   \
               ##vt_packet_emit       \
               vt_trigger_enable    \
               vt_read_fifo         \
               vt_packet_emit           \
               vt_set_trigger_ack_timeout \
               vt_test_emit \
               vt_udp_server \
               vt_udp_server_single_asic \
               vt_power_cycle \
               vt_get_running_clock \
               vt_get_live_clock \
               vt_get_event_count \
               vt_get_clocks \
               vt_rst_counters \
               vt_rst_ev_count \
	       axi_cal_trigger \
	       axi_cal_set

##bin_SCRIPTS = vt_asic_init vt_set_check_config

lib_LTLIBRARIES = libvatactrl.la
libvatactrl_la_SOURCES = vata_ctrl.cpp

##vt_zmq_pub_data_LDFLAGS = -lzmq -L/local/data/puff/sgriffi4/xilinx/lucas/local/lib

##vatactrl_SOURCES = vatactrl.cpp vata_ctrl.cpp
##vatactrl_CFLAGS = $(AM_CXXFLAGS)
vatactrl_SOURCES = vatactrl.cpp
vatactrl_LDADD = libvatactrl.la

vt_set_conf_SOURCES = set_conf.c vata_util.c
vt_get_conf_SOURCES = get_conf.c vata_util.c
vt_set_cal_dac_SOURCES = set_cal_dac.c vata_util.c
vt_cal_pulse_trigger_SOURCES = cal_pulse_trigger.c vata_util.c
##vt_cal_pulse_repeat_SOURCES = cal_pulse_repeat.c mmap_addr.c
vt_trigger_enable_SOURCES = trigger_enable.c vata_util.c
vt_set_hold_delay_SOURCES = set_hold_delay.c vata_util.c
vt_get_hold_delay_SOURCES = get_hold_delay.c vata_util.c
vt_force_trigger_SOURCES = force_trigger.c vata_util.c
##vt_trigger_and_acq_SOURCES = trigger_and_acq.c mmap_addr.c
vt_packet_emit_SOURCES = packet_emit.c vata_util.c
vt_read_fifo_SOURCES = read_fifo.c vata_util.c
vt_set_trigger_ack_timeout_SOURCES = set_trigger_ack_timeout.c vata_util.c
vt_test_emit_SOURCES = test_emit.c
vt_udp_server_SOURCES = udp_server.c vata_util.c
vt_udp_server_single_asic_SOURCES = udp_server_single_asic.c vata_util.c
##vt_zmq_pub_data_SOURCES = zmq_pub_data.c vata_util.c
vt_power_cycle_SOURCES = power_cycle.c vata_util.c
vt_get_running_clock_SOURCES = get_running_clock.c vata_util.c
vt_get_live_clock_SOURCES = get_live_clock.c vata_util.c
vt_get_event_count_SOURCES = get_event_count.c vata_util.c
vt_get_clocks_SOURCES = get_clocks.c vata_util.c
vt_rst_counters_SOURCES = rst_counters.c vata_util.c
vt_rst_ev_count_SOURCES = rst_ev_count.c vata_util.c


axi_cal_set_SOURCES = axi_cal_set.c
axi_cal_trigger_SOURCES = axi_cal_trigger.c
