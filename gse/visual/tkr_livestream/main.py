import numpy as np
from bokeh.io import curdoc

import numpy as np
from bokeh.layouts import row, column, layout
from bokeh.models.widgets import Panel, Tabs

from bokeh.io import push_notebook, show, output_notebook
from bokeh.plotting import figure
from bokeh.models import ColumnDataSource, Range1d, TextInput

import time
import datetime
import bokeh
from bokeh.palettes import Dark2_5 as palette
# itertools handles the cycling
import itertools  

colors = itertools.cycle(palette)
from bokeh.models.widgets import Button, Toggle
from bokeh.models.widgets import RadioButtonGroup, DataTable, DateFormatter, TableColumn, CheckboxButtonGroup
from bokeh.models.callbacks import CustomJS

from functools import partial

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


#### For testing only.
n_ASICs = 4
n_ch = 32

show_ch = []
channel_active = np.array([False for i in range(n_ch)])
for i in range(n_ch):
    if channel_active[i]:
        show_ch += [i] 
    else:
        continue



############## 
# Main plot update loop
##############
event_number = 0

def patch_channelds_only():
    global stats_ds, channel_ds, binned_data_ds, timestream_ds
    global socket, GO
    global event_number


    if GO:
        data = socket.recv()

        dp = DataPacket(data)
        ap = dp.asic_packets[0]
        event_number += 1
        
        timeseries = {'time': [event_number]}
        patches = {}
        
        for ch in range(n_ch):
            timeseries[f'ch{ch:02d}'] = [ap.data[ch]]

        channel_ds.data['values'] = ap.data
        timestream_ds.stream(timeseries, rollover=250)


def patch_plots():
    global stats_ds, channel_ds, binned_data_ds, timestream_ds
    global socket, GO
    global event_number


    if GO:
        data = socket.recv()

        dp = DataPacket(data)
        ap = dp.asic_packets[0]
        event_number += 1
        
        timeseries = {'time': [event_number]}
        patches = {}
        
        for ch in range(n_ch):
            ch_name = f'ch{ch:02d}'
            timeseries[ch_name] = [ap.data[ch]]
            bin_number = ap.data[ch] #int(np.histogram(ap.data[ch], bins=bin_edges)[0].argmax())   
            
            old_bin_content = binned_data_ds.data[ch_name][bin_number]
            
            patches[f'ch{ch:02d}'] = [(bin_number, old_bin_content+1)]

        channel_ds.data['values'] = ap.data
        binned_data_ds.patch(patches)
        timestream_ds.stream(timeseries, rollover=250)    

        '''
        stats_patches = {}

        stats_patches['mean'] = []
        stats_patches['sigma'] = []
        stats_patches['N'] = []
        for ch in range(n_ch):
            ch_name = f'ch{ch:02d}'        
            stats_patches['mean'] += [(ch, calc_mean(bin_centers, binned_data_ds.data[ch_name]))]   
            stats_patches['sigma'] += [(ch, np.sqrt(calc_var(bin_centers, binned_data_ds.data[ch_name])))]   
            stats_patches['N'] += [(ch, np.sum(binned_data_ds.data[ch_name]))]   


        stats_ds.patch(stats_patches)
        '''


################################
# Construct datasources.
################################
# Step plot

channel_ds = ColumnDataSource(data={'values': np.zeros(n_ch), 'channels': np.array(range(n_ch))})
     

### Timeseries
timeseries = {'time': np.zeros(0)}
for ch in range(32):
    timeseries[f'ch{ch:02d}'] = []

#print(timeseries.keys())
timestream_ds = ColumnDataSource(data=timeseries)


ch_display = make_channel_display(channel_ds)
ts_display, ts_list = make_channel_timestream(timestream_ds, n_ch, show_ch=show_ch)

checkbox = CheckboxButtonGroup(labels=[f"ch{ch:02d}" for ch in range(n_ch)], active=show_ch)

#callback_dict = 

#def set_channel_visibility(checkbox, plot_list):
#    for index, active in enumerate(checkbox.active):
#        print(index, active)
#        plot_list[i].visible = active

#checkbox.callback = set_channel_visibility(checkbox, ts_list)
'''checkbox.callback = CustomJS(args=dict(x=ts_list[0], y=ts_list[1], z=ts_list[2]), code="""
    //console.log(cb_obj.active);
    x.visible = false;
    y.visible = false;
    z.visible = false;
    for (i in cb_obj.active) {
        //console.log(cb_obj.active[i]);
        if (cb_obj.active[i] == 0) {
            x.visible = true;
        } else if (cb_obj.active[i] == 1) {
            y.visible = true;
        } else if (cb_obj.active[i] == 2) {
            z.visible = true;
        }
    }
""")'''

checkbox.callback = CustomJS(args=dict(ts_list=ts_list), code="""
    
    for (i=0; i < 32; i++){
        ts_list[i].visible = false;
    }

    for (i in cb_obj.active) {
        for (j=0; j < 32; j++){
            if (cb_obj.active[i] == j) {
                ts_list[j].visible = true;
            }
        }
    }


""")




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

### Same histogram, but fast (?)
hist_display, hist_list = make_channel_binner(binned_data_ds, n_ch, [0, 1, 2])

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
def click_connect(button, start_daq_button):
    global layer_server_ip_input
    global socket
    global GO
    #global start_daq_button

    if socket is None:
        socket = connect_to_host(layer_server_ip_input.value)
        button.button_type = 'success'
        button.label = "CONNECTED"
        start_daq_button.disabled = False
        print(layer_server_ip_input.value)
        print(socket)
    else:
        socket.close()
        button.button_type = 'warning'
        button.label = "CONNECT"

        #Update DAQ button.
        start_daq_button.disabled = True
        start_daq_button.button_type = 'danger'
        start_daq_button.label = "STOPPED"
        GO = False



        socket = None

#layer_server_ip = "10.10.0.11"
layer_server_ip = "localhost"

layer_server_ip_input = TextInput(value=layer_server_ip, title="Data source IP")
connect_buttion = Button(label='Connect', button_type="success")
connect_buttion.on_click(lambda : click_connect(connect_buttion, start_daq_button))

###### DAQ button
def start_DAQ(button):
    global GO
    global nclick
    global socket

    if socket is not None:
        if GO:          
            button.button_type = 'danger'
            GO = False
        else:
            button.label = "GO"
            button.button_type = 'success'
            GO = True
        
        button.label = "RUNNING" if GO else "STOPPED"

start_daq_button = Button(label='STOPPED', button_type='warning', disabled=True)

GO = False
    
start_daq_button.on_click(lambda : start_DAQ(start_daq_button))

inputs = column(column(
                layer_server_ip_input, connect_buttion), 
                start_daq_button,
                checkbox)

ASIC_layout = layout(row(column(ch_display, row(ts_display))))#, data_table))
#ASIC_layout = layout(row(column(ch_display, row(hist_display, ts_display)) ))#, data_table))
display_list = [ASIC_layout for i in range(n_ASICs)]


tabs = Tabs(tabs=[Panel(child=display_list[i], title=f'ASIC {i:02d}') for i in range(len(display_list))])


# tabs.js_on_change("active", CustomJS(args=dict(tabs=tabs), code="""
#            if (typeof(previously_active) == "undefined") {
#                 previously_active = 0
#            }
           
#            tabs.tabs[tabs.active].child.visible = true
#            tabs.tabs[previously_active].child.visible = false
#            previously_active = tabs.active
#         """))


#ASIC_tabs
#ist_display_list = [make_channel_binner(binned_data_ds, [i]) for i in range(n_ch)]
#show(Tabs(tabs=[Panel(child=hist_display_list[i], title=f'ch{i:02d}') for i in range(3)]))
#ASIC_panels = [Panel()]
#ASIC_tabs = Tabs(tabs=[i for i in ASIC_panels])
#curdoc().add_root(column(inputs, column(ch_display, ts_display), width=800))



curdoc().add_root(row(inputs, tabs))

#click_connect(connect_buttion, start_daq_button)

#start_DAQ(start_daq_button)

#curdoc().add_periodic_callback(patch_plots, 50)

curdoc().add_periodic_callback(patch_channelds_only, 50)