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

from makefig import *

def calc_mean(bin_centers, binned_data):
    return np.sum(bin_centers*binned_data) / np.sum(binned_data)
def calc_var(bin_centers, binned_data):
    mean = calc_mean(bin_centers, binned_data)
    return np.sum(binned_data*(bin_centers - mean)**2) / (np.sum(binned_data))

def connect_to_host(host="si-layer.local", data_port=9998):
    ctx = zmq.Context()
    data_addr = f"tcp://{host}:{data_port}"
    data_socket = ctx.socket(zmq.SUB)
    data_socket.setsockopt_string(zmq.SUBSCRIBE, "")
    data_socket.connect(data_addr)

    return data_socket

socket = None #



############## 
# Main plot update loop
##############

def patch_plots():
    global stats_ds, channel_ds, binned_data_ds, timestream_ds
    global socket
    global GO

    if GO:

        data = socket.recv()
        
        #n_received += 1
        #i += 1
        
        dp = DataPacket(data)
        ap = dp.asic_packets[0]
        
        
        timeseries = {'time': [time.time()]}
        patches = {}
        
        for ch in range(n_ch):
            ch_name = f'ch{ch:02d}'
            
            timeseries[ch_name] = [ap.data[ch]]
            
            bin_number = int(np.histogram(ap.data[ch], bins=bin_edges)[0].argmax())   
            
            old_bin_content = binned_data_ds.data[ch_name][bin_number]
            
            patches[f'ch{ch:02d}'] = [(bin_number, old_bin_content+1)]

        channel_ds.data['values'] = ap.data
        binned_data_ds.patch(patches)
        timestream_ds.stream(timeseries, rollover=250)    
        #print(timeseries['time'])
        
        #Downscale updating of rolling average. 
        #if i %10 == 0 and i != 0:
        stats_patches = {}

        stats_patches['mean'] = []
        stats_patches['sigma'] = []
        stats_patches['N'] = []
        for ch in range(3):
            ch_name = f'ch{ch:02d}'        
            stats_patches['mean'] += [(ch, calc_mean(bin_centers, binned_data_ds.data[ch_name]))]   
            stats_patches['sigma'] += [(ch, np.sqrt(calc_var(bin_centers, binned_data_ds.data[ch_name])))]   
            stats_patches['N'] += [(ch, np.sum(binned_data_ds.data[ch_name]))]   


        stats_ds.patch(stats_patches)




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
def click_connect(button):
    global layer_server_ip_input
    global socket 

    if socket is None:
        socket = connect_to_host(layer_server_ip_input.value)
        button.button_type = 'success'
        button.label = "CONNECTED"
        print(layer_server_ip_input.value)
        print(socket)
    else:
        socket.close()
        button.button_type = 'warning'
        button.label = "CONNECT"

#layer_server_ip = "10.10.0.11"
layer_server_ip = "localhost"

layer_server_ip_input = TextInput(value=layer_server_ip, title="Data source IP")
connect_buttion = Button(label='Connect', button_type="success")
connect_buttion.on_click(lambda : click_connect(connect_buttion))



###### DAQ button
def start_DAQ(button):
    global GO
    global nclick
    global socket

    nclick += 1
    if socket is not None:
        if GO:

            button.label = "STOP" 
            button.button_type = 'danger'
            GO = False
        else:
            button.label = "GO"
            button.button_type = 'success'
            GO = True

start_daq_button = Button(label='STOPPED', button_type='warning')

GO = False
nclick = 0
    
start_daq_button.on_click(lambda : start_DAQ(start_daq_button))

inputs = column(column(layer_server_ip_input,connect_buttion), start_daq_button)

#curdoc().add_root(column(inputs, column(ch_display, ts_display), width=800))

curdoc().add_root(row(inputs, column(ch_display, row(hist_display, ts_display), data_table)))

#curdoc().add_periodic_callback(patch_plots, 100)