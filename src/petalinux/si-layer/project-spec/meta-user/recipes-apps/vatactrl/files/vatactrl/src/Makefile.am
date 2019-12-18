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
               vt_power_cycle

bin_SCRIPTS = vt_asic_init vt_set_check_config

##vt_zmq_pub_data_LDFLAGS = -lzmq -L/local/data/puff/sgriffi4/xilinx/lucas/local/lib

vatactrl_SOURCES = vatactrl.c

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
