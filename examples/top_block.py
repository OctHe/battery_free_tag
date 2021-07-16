#!/usr/bin/env python2
# -*- coding: utf-8 -*-
##################################################
# GNU Radio Python Flow Graph
# Title: Top Block
# GNU Radio version: 3.7.13.5
##################################################

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print "Warning: failed to XInitThreads()"

from PyQt4 import Qt
from gnuradio import analog
from gnuradio import blocks
from gnuradio import eng_notation
from gnuradio import gr
from gnuradio import qtgui
from gnuradio import uhd
from gnuradio.eng_option import eng_option
from gnuradio.filter import firdes
from optparse import OptionParser
import sip
import sys
import time
from gnuradio import qtgui


class top_block(gr.top_block, Qt.QWidget):

    def __init__(self):
        gr.top_block.__init__(self, "Top Block")
        Qt.QWidget.__init__(self)
        self.setWindowTitle("Top Block")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except:
            pass
        self.top_scroll_layout = Qt.QVBoxLayout()
        self.setLayout(self.top_scroll_layout)
        self.top_scroll = Qt.QScrollArea()
        self.top_scroll.setFrameStyle(Qt.QFrame.NoFrame)
        self.top_scroll_layout.addWidget(self.top_scroll)
        self.top_scroll.setWidgetResizable(True)
        self.top_widget = Qt.QWidget()
        self.top_scroll.setWidget(self.top_widget)
        self.top_layout = Qt.QVBoxLayout(self.top_widget)
        self.top_grid_layout = Qt.QGridLayout()
        self.top_layout.addLayout(self.top_grid_layout)

        self.settings = Qt.QSettings("GNU Radio", "top_block")
        self.restoreGeometry(self.settings.value("geometry").toByteArray())


        ##################################################
        # Variables
        ##################################################
        self.sig_coeff = sig_coeff = 0.1
        self.samp_rate = samp_rate = 1e6
        self.power_gain = power_gain = 48
        self.center_freq = center_freq = 915e6
        self.Np = Np = 100

        ##################################################
        # Blocks
        ##################################################
        self.uhd_usrp_source_0 = uhd.usrp_source(
        	",".join(("addr=192.168.10.2", "")),
        	uhd.stream_args(
        		cpu_format="fc32",
        		channels=range(1),
        	),
        )
        self.uhd_usrp_source_0.set_subdev_spec('A:0', 0)
        self.uhd_usrp_source_0.set_samp_rate(samp_rate)
        self.uhd_usrp_source_0.set_time_unknown_pps(uhd.time_spec())
        self.uhd_usrp_source_0.set_center_freq(center_freq, 0)
        self.uhd_usrp_source_0.set_gain(0, 0)
        self.uhd_usrp_source_0.set_antenna('RX2', 0)
        self.uhd_usrp_source_0.set_bandwidth(samp_rate, 0)
        self.uhd_usrp_source_0.set_auto_dc_offset(True, 0)
        self.uhd_usrp_source_0.set_auto_iq_balance(True, 0)
        self.uhd_usrp_sink_0 = uhd.usrp_sink(
        	",".join(("addr=192.168.10.2", "")),
        	uhd.stream_args(
        		cpu_format="fc32",
        		channels=range(4),
        	),
        )
        self.uhd_usrp_sink_0.set_subdev_spec('A:0 A:1 B:0 B:1', 0)
        self.uhd_usrp_sink_0.set_samp_rate(samp_rate)
        self.uhd_usrp_sink_0.set_time_unknown_pps(uhd.time_spec())
        self.uhd_usrp_sink_0.set_center_freq(center_freq, 0)
        self.uhd_usrp_sink_0.set_gain(power_gain, 0)
        self.uhd_usrp_sink_0.set_antenna('TX/RX', 0)
        self.uhd_usrp_sink_0.set_bandwidth(samp_rate, 0)
        self.uhd_usrp_sink_0.set_center_freq(center_freq, 1)
        self.uhd_usrp_sink_0.set_gain(power_gain, 1)
        self.uhd_usrp_sink_0.set_antenna('TX/RX', 1)
        self.uhd_usrp_sink_0.set_bandwidth(samp_rate, 1)
        self.uhd_usrp_sink_0.set_center_freq(center_freq, 2)
        self.uhd_usrp_sink_0.set_gain(power_gain, 2)
        self.uhd_usrp_sink_0.set_antenna('TX/RX', 2)
        self.uhd_usrp_sink_0.set_bandwidth(samp_rate, 2)
        self.uhd_usrp_sink_0.set_center_freq(center_freq, 3)
        self.uhd_usrp_sink_0.set_gain(power_gain, 3)
        self.uhd_usrp_sink_0.set_antenna('TX/RX', 3)
        self.uhd_usrp_sink_0.set_bandwidth(samp_rate, 3)
        self.qtgui_time_sink_x_0 = qtgui.time_sink_c(
        	8*Np, #size
        	samp_rate, #samp_rate
        	"", #name
        	1 #number of inputs
        )
        self.qtgui_time_sink_x_0.set_update_time(0.10)
        self.qtgui_time_sink_x_0.set_y_axis(-1, 1)

        self.qtgui_time_sink_x_0.set_y_label('Amplitude', "")

        self.qtgui_time_sink_x_0.enable_tags(-1, True)
        self.qtgui_time_sink_x_0.set_trigger_mode(qtgui.TRIG_MODE_FREE, qtgui.TRIG_SLOPE_POS, 0.0, 0, 0, "")
        self.qtgui_time_sink_x_0.enable_autoscale(True)
        self.qtgui_time_sink_x_0.enable_grid(False)
        self.qtgui_time_sink_x_0.enable_axis_labels(True)
        self.qtgui_time_sink_x_0.enable_control_panel(False)
        self.qtgui_time_sink_x_0.enable_stem_plot(False)

        if not True:
          self.qtgui_time_sink_x_0.disable_legend()

        labels = ['', '', '', '', '',
                  '', '', '', '', '']
        widths = [1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1]
        colors = ["blue", "red", "green", "black", "cyan",
                  "magenta", "yellow", "dark red", "dark green", "blue"]
        styles = [1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1]
        markers = [-1, -1, -1, -1, -1,
                   -1, -1, -1, -1, -1]
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
                  1.0, 1.0, 1.0, 1.0, 1.0]

        for i in xrange(2):
            if len(labels[i]) == 0:
                if(i % 2 == 0):
                    self.qtgui_time_sink_x_0.set_line_label(i, "Re{{Data {0}}}".format(i/2))
                else:
                    self.qtgui_time_sink_x_0.set_line_label(i, "Im{{Data {0}}}".format(i/2))
            else:
                self.qtgui_time_sink_x_0.set_line_label(i, labels[i])
            self.qtgui_time_sink_x_0.set_line_width(i, widths[i])
            self.qtgui_time_sink_x_0.set_line_color(i, colors[i])
            self.qtgui_time_sink_x_0.set_line_style(i, styles[i])
            self.qtgui_time_sink_x_0.set_line_marker(i, markers[i])
            self.qtgui_time_sink_x_0.set_line_alpha(i, alphas[i])

        self._qtgui_time_sink_x_0_win = sip.wrapinstance(self.qtgui_time_sink_x_0.pyqwidget(), Qt.QWidget)
        self.top_grid_layout.addWidget(self._qtgui_time_sink_x_0_win)
        self.blocks_stream_mux_1_0 = blocks.stream_mux(gr.sizeof_gr_complex*1, (2*Np, Np, Np))
        self.blocks_stream_mux_1 = blocks.stream_mux(gr.sizeof_gr_complex*1, (Np, Np, 2*Np))
        self.blocks_stream_mux_0_0 = blocks.stream_mux(gr.sizeof_gr_complex*1, (3*Np, Np))
        self.blocks_stream_mux_0 = blocks.stream_mux(gr.sizeof_gr_complex*1, (Np, 3*Np))
        self.blocks_multiply_const_vxx_3 = blocks.multiply_const_vcc((sig_coeff, ))
        self.blocks_multiply_const_vxx_2 = blocks.multiply_const_vcc((sig_coeff, ))
        self.blocks_multiply_const_vxx_1 = blocks.multiply_const_vcc((sig_coeff, ))
        self.blocks_multiply_const_vxx_0 = blocks.multiply_const_vcc((sig_coeff, ))
        self.analog_sig_source_x_3 = analog.sig_source_c(samp_rate, analog.GR_SIN_WAVE, 80e3, 1, 0)
        self.analog_sig_source_x_2 = analog.sig_source_c(samp_rate, analog.GR_SIN_WAVE, 40e3, 1, 0)
        self.analog_sig_source_x_1 = analog.sig_source_c(samp_rate, analog.GR_SIN_WAVE, 20e3, 1, 0)
        self.analog_sig_source_x_0 = analog.sig_source_c(samp_rate, analog.GR_SIN_WAVE, 10e3, 1, 0)
        self.analog_const_source_x_3 = analog.sig_source_c(0, analog.GR_CONST_WAVE, 0, 0, 0)
        self.analog_const_source_x_2_1 = analog.sig_source_c(0, analog.GR_CONST_WAVE, 0, 0, 0)
        self.analog_const_source_x_2_0 = analog.sig_source_c(0, analog.GR_CONST_WAVE, 0, 0, 0)
        self.analog_const_source_x_1_1 = analog.sig_source_c(0, analog.GR_CONST_WAVE, 0, 0, 0)
        self.analog_const_source_x_1_0 = analog.sig_source_c(0, analog.GR_CONST_WAVE, 0, 0, 0)
        self.analog_const_source_x_0 = analog.sig_source_c(0, analog.GR_CONST_WAVE, 0, 0, 0)



        ##################################################
        # Connections
        ##################################################
        self.connect((self.analog_const_source_x_0, 0), (self.blocks_stream_mux_0, 1))
        self.connect((self.analog_const_source_x_1_0, 0), (self.blocks_stream_mux_1, 0))
        self.connect((self.analog_const_source_x_1_1, 0), (self.blocks_stream_mux_1, 2))
        self.connect((self.analog_const_source_x_2_0, 0), (self.blocks_stream_mux_1_0, 0))
        self.connect((self.analog_const_source_x_2_1, 0), (self.blocks_stream_mux_1_0, 2))
        self.connect((self.analog_const_source_x_3, 0), (self.blocks_stream_mux_0_0, 0))
        self.connect((self.analog_sig_source_x_0, 0), (self.blocks_stream_mux_0, 0))
        self.connect((self.analog_sig_source_x_1, 0), (self.blocks_stream_mux_1, 1))
        self.connect((self.analog_sig_source_x_2, 0), (self.blocks_stream_mux_1_0, 1))
        self.connect((self.analog_sig_source_x_3, 0), (self.blocks_stream_mux_0_0, 1))
        self.connect((self.blocks_multiply_const_vxx_0, 0), (self.uhd_usrp_sink_0, 0))
        self.connect((self.blocks_multiply_const_vxx_1, 0), (self.uhd_usrp_sink_0, 1))
        self.connect((self.blocks_multiply_const_vxx_2, 0), (self.uhd_usrp_sink_0, 2))
        self.connect((self.blocks_multiply_const_vxx_3, 0), (self.uhd_usrp_sink_0, 3))
        self.connect((self.blocks_stream_mux_0, 0), (self.blocks_multiply_const_vxx_0, 0))
        self.connect((self.blocks_stream_mux_0_0, 0), (self.blocks_multiply_const_vxx_3, 0))
        self.connect((self.blocks_stream_mux_1, 0), (self.blocks_multiply_const_vxx_1, 0))
        self.connect((self.blocks_stream_mux_1_0, 0), (self.blocks_multiply_const_vxx_2, 0))
        self.connect((self.uhd_usrp_source_0, 0), (self.qtgui_time_sink_x_0, 0))

    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "top_block")
        self.settings.setValue("geometry", self.saveGeometry())
        event.accept()

    def get_sig_coeff(self):
        return self.sig_coeff

    def set_sig_coeff(self, sig_coeff):
        self.sig_coeff = sig_coeff
        self.blocks_multiply_const_vxx_3.set_k((self.sig_coeff, ))
        self.blocks_multiply_const_vxx_2.set_k((self.sig_coeff, ))
        self.blocks_multiply_const_vxx_1.set_k((self.sig_coeff, ))
        self.blocks_multiply_const_vxx_0.set_k((self.sig_coeff, ))

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.uhd_usrp_source_0.set_samp_rate(self.samp_rate)
        self.uhd_usrp_source_0.set_bandwidth(self.samp_rate, 0)
        self.uhd_usrp_sink_0.set_samp_rate(self.samp_rate)
        self.uhd_usrp_sink_0.set_bandwidth(self.samp_rate, 0)
        self.uhd_usrp_sink_0.set_bandwidth(self.samp_rate, 1)
        self.uhd_usrp_sink_0.set_bandwidth(self.samp_rate, 2)
        self.uhd_usrp_sink_0.set_bandwidth(self.samp_rate, 3)
        self.qtgui_time_sink_x_0.set_samp_rate(self.samp_rate)
        self.analog_sig_source_x_3.set_sampling_freq(self.samp_rate)
        self.analog_sig_source_x_2.set_sampling_freq(self.samp_rate)
        self.analog_sig_source_x_1.set_sampling_freq(self.samp_rate)
        self.analog_sig_source_x_0.set_sampling_freq(self.samp_rate)

    def get_power_gain(self):
        return self.power_gain

    def set_power_gain(self, power_gain):
        self.power_gain = power_gain
        self.uhd_usrp_sink_0.set_gain(self.power_gain, 0)

        self.uhd_usrp_sink_0.set_gain(self.power_gain, 1)

        self.uhd_usrp_sink_0.set_gain(self.power_gain, 2)

        self.uhd_usrp_sink_0.set_gain(self.power_gain, 3)


    def get_center_freq(self):
        return self.center_freq

    def set_center_freq(self, center_freq):
        self.center_freq = center_freq
        self.uhd_usrp_source_0.set_center_freq(self.center_freq, 0)
        self.uhd_usrp_source_0.set_center_freq(self.center_freq, 1)
        self.uhd_usrp_sink_0.set_center_freq(self.center_freq, 0)
        self.uhd_usrp_sink_0.set_center_freq(self.center_freq, 1)
        self.uhd_usrp_sink_0.set_center_freq(self.center_freq, 2)
        self.uhd_usrp_sink_0.set_center_freq(self.center_freq, 3)

    def get_Np(self):
        return self.Np

    def set_Np(self, Np):
        self.Np = Np


def main(top_block_cls=top_block, options=None):

    from distutils.version import StrictVersion
    if StrictVersion(Qt.qVersion()) >= StrictVersion("4.5.0"):
        style = gr.prefs().get_string('qtgui', 'style', 'raster')
        Qt.QApplication.setGraphicsSystem(style)
    qapp = Qt.QApplication(sys.argv)

    tb = top_block_cls()
    tb.start()
    tb.show()

    def quitting():
        tb.stop()
        tb.wait()
    qapp.connect(qapp, Qt.SIGNAL("aboutToQuit()"), quitting)
    qapp.exec_()


if __name__ == '__main__':
    main()
