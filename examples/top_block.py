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
from gnuradio import blocks
from gnuradio import eng_notation
from gnuradio import fft
from gnuradio import gr
from gnuradio import qtgui
from gnuradio.eng_option import eng_option
from gnuradio.fft import window
from gnuradio.filter import firdes
from optparse import OptionParser
import beamnet
import numpy as np
import sip
import sys
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
        self.tx = tx = 2
        self.sym_sync = sym_sync = 4
        self.sym_pd = sym_pd = 194
        self.fft_size = fft_size = 16
        self.work_mode = work_mode = 2
        self.sync_word = sync_word = (0, 0, -0.7485-0.6631j, 0.8855+0.4647j, 0.5681-0.8230j, 0.8855-0.4647j, -0.3546+0.9350j, 1, 0, -0.3546+0.9350j, 0.8855-0.4647j, 0.5681-0.8230j, 0.8855+0.4647j, -0.7485-0.6631j, -0.9709+0.2393j, 0)
        self.samp_rate = samp_rate = 1e6
        self.pkt_size = pkt_size = fft_size * (sym_sync + tx + sym_pd)

        ##################################################
        # Blocks
        ##################################################
        self.reverse_fft_vxx_1_0 = fft.fft_vcc(fft_size, False, (()), True, 1)
        self.reverse_fft_vxx_1 = fft.fft_vcc(fft_size, False, (()), True, 1)
        self.qtgui_edit_box_msg_0 = qtgui.edit_box_msg(qtgui.FLOAT_VEC, '0, 0', '', True, True, '()')
        self._qtgui_edit_box_msg_0_win = sip.wrapinstance(self.qtgui_edit_box_msg_0.pyqwidget(), Qt.QWidget)
        self.top_grid_layout.addWidget(self._qtgui_edit_box_msg_0_win)
        self.blocks_vector_to_stream_0 = blocks.vector_to_stream(gr.sizeof_gr_complex*1, fft_size)
        self.blocks_throttle_0_0 = blocks.throttle(gr.sizeof_gr_complex*fft_size, samp_rate,True)
        self.blocks_throttle_0 = blocks.throttle(gr.sizeof_gr_complex*fft_size, samp_rate,True)
        self.blocks_file_sink_3 = blocks.file_sink(gr.sizeof_float*1, '/home/shiyue_deep/Projects/gr-beamnet/examples/debug_source_corr.bin', False)
        self.blocks_file_sink_3.set_unbuffered(False)
        self.blocks_file_sink_2 = blocks.file_sink(gr.sizeof_float*1, '/home/shiyue_deep/Projects/gr-beamnet/examples/debug_source_nrg.bin', False)
        self.blocks_file_sink_2.set_unbuffered(False)
        self.blocks_file_sink_1 = blocks.file_sink(gr.sizeof_gr_complex*fft_size, '/home/shiyue_deep/Projects/gr-beamnet/examples/debug_source_signal_tx1.bin', False)
        self.blocks_file_sink_1.set_unbuffered(False)
        self.blocks_file_sink_0 = blocks.file_sink(gr.sizeof_gr_complex*fft_size, '/home/shiyue_deep/Projects/gr-beamnet/examples/debug_source_signal_tx0.bin', False)
        self.blocks_file_sink_0.set_unbuffered(False)
        self.beamnet_symbol_sync_0 = beamnet.symbol_sync(sym_sync, np.fft.ifft(np.fft.fftshift(sync_word)))
        self.beamnet_source_signal_1 = beamnet.source_signal(3, 1, fft_size, sym_sync, sym_pd, sync_word, work_mode)
        self.beamnet_source_signal_0 = beamnet.source_signal(3, 0, fft_size, sym_sync, sym_pd, sync_word, work_mode)
        self.beamnet_energy_detector_0 = beamnet.energy_detector(160)



        ##################################################
        # Connections
        ##################################################
        self.msg_connect((self.qtgui_edit_box_msg_0, 'msg'), (self.beamnet_source_signal_1, 'phase'))
        self.connect((self.beamnet_energy_detector_0, 0), (self.blocks_file_sink_2, 0))
        self.connect((self.beamnet_source_signal_0, 0), (self.blocks_throttle_0, 0))
        self.connect((self.beamnet_source_signal_1, 0), (self.blocks_throttle_0_0, 0))
        self.connect((self.beamnet_symbol_sync_0, 0), (self.blocks_file_sink_3, 0))
        self.connect((self.blocks_throttle_0, 0), (self.reverse_fft_vxx_1, 0))
        self.connect((self.blocks_throttle_0_0, 0), (self.reverse_fft_vxx_1_0, 0))
        self.connect((self.blocks_vector_to_stream_0, 0), (self.beamnet_energy_detector_0, 0))
        self.connect((self.blocks_vector_to_stream_0, 0), (self.beamnet_symbol_sync_0, 0))
        self.connect((self.reverse_fft_vxx_1, 0), (self.blocks_file_sink_0, 0))
        self.connect((self.reverse_fft_vxx_1, 0), (self.blocks_vector_to_stream_0, 0))
        self.connect((self.reverse_fft_vxx_1_0, 0), (self.blocks_file_sink_1, 0))

    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "top_block")
        self.settings.setValue("geometry", self.saveGeometry())
        event.accept()

    def get_tx(self):
        return self.tx

    def set_tx(self, tx):
        self.tx = tx
        self.set_pkt_size(self.fft_size * (self.sym_sync + self.tx + self.sym_pd))

    def get_sym_sync(self):
        return self.sym_sync

    def set_sym_sync(self, sym_sync):
        self.sym_sync = sym_sync
        self.set_pkt_size(self.fft_size * (self.sym_sync + self.tx + self.sym_pd))

    def get_sym_pd(self):
        return self.sym_pd

    def set_sym_pd(self, sym_pd):
        self.sym_pd = sym_pd
        self.set_pkt_size(self.fft_size * (self.sym_sync + self.tx + self.sym_pd))

    def get_fft_size(self):
        return self.fft_size

    def set_fft_size(self, fft_size):
        self.fft_size = fft_size
        self.set_pkt_size(self.fft_size * (self.sym_sync + self.tx + self.sym_pd))

    def get_work_mode(self):
        return self.work_mode

    def set_work_mode(self, work_mode):
        self.work_mode = work_mode

    def get_sync_word(self):
        return self.sync_word

    def set_sync_word(self, sync_word):
        self.sync_word = sync_word

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.blocks_throttle_0_0.set_sample_rate(self.samp_rate)
        self.blocks_throttle_0.set_sample_rate(self.samp_rate)

    def get_pkt_size(self):
        return self.pkt_size

    def set_pkt_size(self, pkt_size):
        self.pkt_size = pkt_size


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
