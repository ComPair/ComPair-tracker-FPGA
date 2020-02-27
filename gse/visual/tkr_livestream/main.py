import numpy as np
from bokeh.io import curdoc

from bokeh.layouts import row, column
from bokeh.io import push_notebook, show, output_notebook
from bokeh.plotting import figure
from bokeh.models import ColumnDataSource, Range1d
from bokeh.models.widgets import Button
import time

t0 = time.time()

import zmq
from silayer.raw2hdf import DataPacket

def loop(data_socket):
    while True:
        data = data_socket.recv() ## This should block until data shows up
        dp = DataPacket(data)
        ## Then do whatever...
        
def main(host="si-layer.local", data_port=9998):
    ctx = zmq.Context()
    data_addr = f"tcp://{host}:{data_port}"
    data_socket = ctx.socket(zmq.SUB)
    data_socket.setsockopt_string(zmq.SUBSCRIBE, "")
    data_socket.connect(data_addr)
    
    return data_socket


socket = main("10.10.0.11")


p = figure(title='ASIC_<x>', tools='', 
       plot_height=350, plot_width=800,
       background_fill_color="#fafafa", )
p.xaxis.axis_label = "channel"
p.yaxis.axis_label = "adc counts (LSB)"
#p.y_range = Range1d(0, 400)

n_ch = 32
channels = np.array(range(n_ch)) - 1.5

data_dict = {} 
data_dict['pedestals'] = np.zeros(n_ch) -100 #+ np.random.normal(scale=5, size=n_ch)
data_dict['channels'] = channels

data = ColumnDataSource(data_dict)
steps = p.step('channels', 'pedestals', source=data)

 

channel_stream0 = figure(title='ASIC_<x> ch<y>', tools='', 
       plot_height=350, plot_width=800,
       background_fill_color="#fafafa", )

channel_stream0.xaxis.axis_label = "event number"
channel_stream0.yaxis.axis_label = "adc counts (LSB)"


channel_stream1 = figure(title='ASIC_<x> ch<y>', tools='', 
       plot_height=350, plot_width=800,
       background_fill_color="#fafafa", )

channel_stream1.xaxis.axis_label = "event number"
channel_stream1.yaxis.axis_label = "adc counts (LSB)"


data = {'time': np.zeros(0), 'adc0': np.zeros(0), 'adc1': np.zeros(0)}
datastream = ColumnDataSource(data=data)

timeseries = channel_stream0.line('time', 'adc0', source=datastream)
timeseries = channel_stream0.circle('time', 'adc0', source=datastream)
timeseries = channel_stream0.line('time', 'adc1', source=datastream, color='green')
timeseries = channel_stream0.circle('time', 'adc1', source=datastream, color='green')

#t = show(column(p, channel_stream0), notebook_handle=True)

event_counter = 5000

def run():
  for i in range(100000):
    event_counter += 1
      
    data = 250 + np.random.normal(scale=5, size=n_ch)
    steps.data_source.data['pedestals'] = data
    datastream.stream({'time': [event_counter], 
                     'adc0':[data[0]], 
                     'adc1':[data[1]]}, 
                     rollover=100)
      #data_dict['pedestals'] = 250 + np.random.normal(scale=5, size=n_ch)
      #data.stream(data_dict)
      #push_notebook(t)
    time.sleep(np.abs(np.random.normal(0.05, scale=0.01)))
        


button = Button(label="GO", button_type="success")

button.on_click(run)


inputs = column(button)

curdoc().add_root(row(inputs, column(p, channel_stream0), width=800))
#curdoc().title = "Sliders"

#curdoc().add_root(column(p, timeseries, button), width=800)
#curdoc().title = "tkr_livestream"