import numpy as np
from bokeh.io import curdoc

import numpy as np
from bokeh.layouts import row, column, layout
from bokeh.models.widgets import Panel, Tabs

from bokeh.io import push_notebook, show, output_notebook
from bokeh.plotting import figure
from bokeh.models import ColumnDataSource, Range1d, TextInput
import time
import bokeh
from bokeh.palettes import Dark2_5 as palette
# itertools handles the cycling
import itertools  

colors = itertools.cycle(palette)
from bokeh.models.widgets import Button, Toggle
from bokeh.models.widgets import RadioButtonGroup, DataTable, DateFormatter, TableColumn


t0 = time.time()

import zmq
from silayer.raw2hdf import DataPacket


def calc_mean(bin_centers, binned_data):
    return np.sum(bin_centers*binned_data) / np.sum(binned_data)
def calc_var(bin_centers, binned_data):
    mean = calc_mean(bin_centers, binned_data)
    return np.sum(binned_data*(bin_centers - mean)**2) / (np.sum(binned_data))

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
    channel_display = figure(title='channel', tools='', 
           plot_height=350, plot_width=800,
           background_fill_color="#fafafa", )
    channel_display.xaxis.axis_label = "channel"
    channel_display.yaxis.axis_label = "adc counts (LSB)"
    #p.y_range = Range1d(0, 400)

    steps = channel_display.step('channels', 'values', source=datasource)
    
    return channel_display

def make_channel_timestream(datasource, show_ch = [0, 1, 2]):
    channel_stream = figure(title='ASIC_<x>', tools='', 
           plot_height=350, plot_width=400,
           background_fill_color="#fafafa", )

    channel_stream.xaxis.axis_label = "time (s)"
    channel_stream.yaxis.axis_label = "adc counts (LSB)"

    for ch in show_ch:
        color=next(colors)
        channel_stream.line('time', f'ch{ch:02d}', source=datasource, color=color)
        channel_stream.circle('time', f'ch{ch:02d}', source=datasource, legend_label=f'ch{ch:02d}', color=color)

    return channel_stream

def make_channel_binner(datasource, show_ch = [0, 1, 2]):
    hist_fig = figure(title='ASIC_<x>', #tools='', 
                      plot_height=350, plot_width=400,
                      background_fill_color="#fafafa", )

    hist_fig.xaxis.axis_label = "adc counts (LSB)"

    rate_fig = figure(title='event rate', tools='',
                      plot_height=350, plot_width=400,
                      background_fill_color="#fafafa", )                  


    #print("Making histograms for channels: ", show_ch)
    for ch in show_ch:
        hist_fig.quad(top=f'ch{ch:02d}', left='left', right='right', bottom='bottom', 
                      source=datasource, color=next(colors), legend_label=f'ch{ch:02d}')
                
    return hist_fig


################################
# Construct datasources.
################################
# Step plot
n_ch = 32
channel_ds = ColumnDataSource(data={'values': np.zeros(n_ch), 'channels': np.array(range(n_ch))})
     

### Timeseries
timeseries = {'time': np.zeros(0)}
for ch in range(32):
    timeseries[f'ch{ch:02d}'] = []

#print(timeseries.keys())
timestream_ds = ColumnDataSource(data=timeseries)


ch_display = make_channel_display(channel_ds)
ts_display = make_channel_timestream(timestream_ds)


### Histogram
bin_edges = np.array(range(1025)) - 0.5
bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
binned_data = np.zeros(len(bin_centers))

hdict = {}
for ch in range(n_ch):
    hdict[f'ch{ch:02d}'] = np.zeros(len(bin_centers))

hdict['bin_centers'] = bin_centers
hdict['left'] = bin_edges[0:-1]
hdict['right'] = bin_edges[1::]
hdict['bottom'] = np.zeros(len(bin_centers))

binned_data_ds = ColumnDataSource(hdict)

hist_display = make_channel_binner(binned_data_ds)
hist_display_list = [make_channel_binner(binned_data_ds, [i]) for i in range(n_ch)]
#show(Tabs(tabs=[Panel(child=hist_display_list[i], title=f'ch{i:02d}') for i in range(3)]))

### Statistics
stats_ds = ColumnDataSource({'mean': np.zeros(n_ch), 'sigma': np.zeros(n_ch), 'N': np.zeros(n_ch)})

hfmt = bokeh.models.NumberFormatter(format="0.00", text_align='center')     
columns = [TableColumn(field="mean", title="μ", formatter=hfmt), 
           TableColumn(field="sigma", title="σ", formatter=hfmt), 
           TableColumn(field="N", title="N", formatter=hfmt)]
                        
data_table = DataTable(source=stats_ds, columns=columns, width=400, height=280, 
                       #index_position=None, 
                       sortable=False,
                      editable=False, selectable=False, reorderable=False,fit_columns=True
                      )




###### Connections
def click_connect():
    global layer_server_ip_input
    global socket 

    socket = connect_to_host(layer_server_ip_input.value)
    print(layer_server_ip_input.value)
    print(socket)

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

inputs = column(column(layer_server_ip_input,connect_buttion), start_daq_button)

#curdoc().add_root(column(inputs, column(ch_display, ts_display), width=800))

curdoc().add_root(row(inputs, column(ch_display, row(hist_display, ts_display), data_table)))

#curdoc().add_periodic_callback(run, 100)