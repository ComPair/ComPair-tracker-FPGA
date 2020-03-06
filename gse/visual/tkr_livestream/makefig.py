import bokeh
from bokeh.plotting import figure

from bokeh.palettes import Dark2_5 as palette
# itertools handles the cycling
import itertools  

colors = itertools.cycle(palette)


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
    
    colors = itertools.cycle(palette)        

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

    colors = itertools.cycle(palette)        

    #print("Making histograms for channels: ", show_ch)
    for ch in show_ch:
        hist_fig.quad(top=f'ch{ch:02d}', left='left', right='right', bottom='bottom', 
                      source=datasource, color=next(colors), legend_label=f'ch{ch:02d}')
                
    return hist_fig
