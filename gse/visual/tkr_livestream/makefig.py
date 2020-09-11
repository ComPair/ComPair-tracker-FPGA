import bokeh
from bokeh.plotting import figure

from bokeh.palettes import Dark2_5 as palette
# itertools handles the cycling
import itertools  

colors = itertools.cycle(palette)


def make_channel_display(datasource):
    channel_display = figure(title='channel', tools='', 
           plot_height=350, plot_width=800,
           background_fill_color="#fafafa")  #)output_backend="webgl")
    channel_display.xaxis.axis_label = "channel"
    channel_display.yaxis.axis_label = "adc counts (LSB)"
    #p.y_range = Range1d(0, 400)

    steps = channel_display.step('channels', 'values', source=datasource)
    
    return channel_display

def make_channel_timestream(datasource, n_ch, show_ch = [0, 1, 2]):
    channel_stream = figure(title='ASIC_<x>', tools='', 
           plot_height=350, plot_width=400,
           background_fill_color="#fafafa")#,  output_backend="webgl")

    channel_stream.xaxis.axis_label = "time (s)"
    channel_stream.yaxis.axis_label = "adc counts (LSB)"
    
    colors = itertools.cycle(palette)        

    line_list = []
    for ch in range(n_ch):
        color=next(colors)
        ch_line = channel_stream.line('time', f'ch{ch:02d}', 
            source=datasource, color=next(colors), legend_label=f'ch{ch:02d}')
        if ch not in show_ch:
            ch_line.visible = False

        line_list += [ch_line]
    
    return channel_stream, line_list

def make_channel_binner(datasource, n_ch, show_ch = []):
    hist_fig = figure(title='ASIC_<x>', #tools='', 
                      plot_height=350, plot_width=400,
                      background_fill_color="#fafafa")#,  output_backend="webgl")

    hist_fig.xaxis.axis_label = "adc counts (LSB)"

    colors = itertools.cycle(palette)        

    hist_list = []
    for ch in range(n_ch):
        color=next(colors)
        ch_hist = hist_fig.quad(top=f'ch{ch:02d}', left='left', right='right', bottom='bottom', 
                      source=datasource, color=next(colors), legend_label=f'ch{ch:02d}')
        hist_list += [ch_hist]
        if ch not in show_ch:
            ch_hist.visible = False

    return hist_fig, hist_list