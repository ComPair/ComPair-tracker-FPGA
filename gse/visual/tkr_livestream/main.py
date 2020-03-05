import numpy as np
from bokeh.io import curdoc

from bokeh.layouts import row, column
from bokeh.io import push_notebook, show, output_notebook
from bokeh.plotting import figure
from bokeh.models import ColumnDataSource, Range1d
from bokeh.models.widgets import Button, Toggle
from bokeh.models.widgets import TextInput

import time

from bokeh.palettes import Dark2_5 as palette
# itertools handles the cycling
import itertools  

colors = itertools.cycle(palette)

t0 = time.time()

import zmq
from silayer.raw2hdf import DataPacket

#def loop(data_socket):
#    while True:
#        data = data_socket.recv() ## This should block until data shows up
#        dp = DataPacket(data)
#        ## Then do whatever...
        
def connect_to_host(host="si-layer.local", data_port=9998):
    ctx = zmq.Context()
    data_addr = f"tcp://{host}:{data_port}"
    data_socket = ctx.socket(zmq.SUB)
    data_socket.setsockopt_string(zmq.SUBSCRIBE, "")
    data_socket.connect(data_addr)

    return data_socket


socket = None #


def make_channel_display(datasource):
    channel_display = figure(title='ASIC_<x>', tools='', 
           plot_height=350, plot_width=800,
           background_fill_color="#fafafa", )
    channel_display.xaxis.axis_label = "channel"
    channel_display.yaxis.axis_label = "adc counts (LSB)"

    steps = channel_display.step('channel_number', 'channel_value', source=datasource)
    
    return channel_display

def make_channel_timestream(datasource):
    channel_stream = figure(title='ASIC_<x>', tools='', 
           plot_height=350, plot_width=800,
           background_fill_color="#fafafa", )

    channel_stream.xaxis.axis_label = "time (s)"
    channel_stream.yaxis.axis_label = "adc counts (LSB)"

    for ch in range(3):
        color=next(colors)
        channel_stream.line('time', f'ch{ch:02d}', source=datasource, color=color)
        channel_stream.circle('time', f'ch{ch:02d}', source=datasource, legend_label=f'ch{ch:02d}', color=color)

    return channel_stream


################################
# Construct datasources.
################################
# Step plot
n_ch = 32
channel_ds = ColumnDataSource(data={'channel_value': np.zeros(n_ch), 'channel_number': np.array(range(n_ch))})
               
# Timeseries
timeseries = {'time': np.zeros(0)}
for ch in range(32):
    timeseries[f'ch{ch:02d}'] = []

timestream_ds = ColumnDataSource(data=timeseries)

# Generate the display handles
ch_display = make_channel_display(channel_ds)
ts_display = make_channel_timestream(timestream_ds)



###### Connections
def click_connect():
    global layer_server_ip_input
    global socket 

    socket = connect_to_host(layer_server_ip_input.value)
    print(layer_server_ip_input.value)

layer_server_ip = "10.10.0.11"

layer_server_ip_input = TextInput(value=layer_server_ip, title="Data source IP")
connect_buttion = Button(label='Connect', button_type="success")
connect_buttion.on_click(click_connect)



###### DAQ button
def start_DAQ(button):
    global GO
    global nclick 

    nclick += 1
    if button.label == "GO":

        button.label = "STOP" 
        GO = False
    else:
        button.label = "GO"
        GO = True

start_daq_button = Button(label='GO', button_type='danger')

GO = False
nclick = 0
    
start_daq_button.on_click(lambda : start_DAQ(start_daq_button))

inputs = row(start_daq_button, column(layer_server_ip_input,connect_buttion))

curdoc().add_root(column(inputs, column(ch_display, ts_display), width=800))

#curdoc().add_periodic_callback(run, 100)