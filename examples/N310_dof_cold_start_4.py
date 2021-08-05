#!/usr/bin/env python2
# -*- coding: utf-8 -*-
##################################################
# GNU Radio Python Flow Graph
# Title: Top Block
# GNU Radio version: 3.7.13.5
##################################################

from gnuradio import blocks
from gnuradio import eng_notation
from gnuradio import fft
from gnuradio import filter
from gnuradio import gr
from gnuradio import uhd
from gnuradio.eng_option import eng_option
from gnuradio.fft import window
from gnuradio.filter import firdes
from optparse import OptionParser
import beamnet
import numpy as np
import time


class top_block(gr.top_block):

    def __init__(self):
        gr.top_block.__init__(self, "Top Block")

        ##################################################
        # Variables
        ##################################################
        # RF and hardware variables
        self.center_freq_tx = center_freq_tx = 915e6
        self.center_freq_rx = center_freq_rx = 915e6
        self.power_gain_tx = power_gain_tx = 57
        self.power_gain_rx = power_gain_rx = 0
        self.sig_coeff = sig_coeff = 0.1
        self.samp_rate = samp_rate = 1e6
        self.fft_size = fft_size = 16

        # MT-DEB variables
        rx_file_name = "debug_tag_reflection.bin"
        pkt_file_name = "debug_tag_pkt.bin"

        self.tx = tx = 2
        self.sym_sync = sym_sync = 8
        self.sym_pd = sym_pd = 180
        self.work_mode = work_mode = 1
        sym_pkt = sym_sync + tx + sym_pd

        self.win_size = win_size = 640
        self.thr = thr = 1e-7
        self.sync_word = sync_word = (0, 0, -0.7485-0.6631j, 0.8855+0.4647j, 0.5681-0.8230j, 0.8855-0.4647j, -0.3546+0.9350j, 1, 0, -0.3546+0.9350j, 0.8855-0.4647j, 0.5681-0.8230j, 0.8855+0.4647j, -0.7485-0.6631j, -0.9709+0.2393j, 0)

        ##################################################
        # Blocks
        ##################################################
        self.uhd_usrp_source_0 = uhd.usrp_source(
        	",".join(("serial=320F337", "")),
        	uhd.stream_args(
        		cpu_format="fc32",
        		channels=range(1),
        	),
        )
        self.uhd_usrp_source_0.set_subdev_spec('A:A', 0)
        self.uhd_usrp_source_0.set_samp_rate(samp_rate)
        self.uhd_usrp_source_0.set_time_unknown_pps(uhd.time_spec())
        self.uhd_usrp_source_0.set_center_freq(center_freq_rx, 0)
        self.uhd_usrp_source_0.set_gain(power_gain_rx, 0)
        self.uhd_usrp_source_0.set_antenna('RX2', 0)
        self.uhd_usrp_source_0.set_bandwidth(samp_rate, 0)
        self.uhd_usrp_source_0.set_auto_dc_offset(True, 0)
        self.uhd_usrp_source_0.set_auto_iq_balance(True, 0)
        
        self.uhd_usrp_sink_0 = uhd.usrp_sink(
        	",".join(("addr=192.168.10.2", "")),
        	uhd.stream_args(
        		cpu_format="fc32",
        		channels=range(tx),
        	),
        )
        if tx == 1:
            self.uhd_usrp_sink_0.set_subdev_spec('A:0', 0)
        elif tx == 2:
            self.uhd_usrp_sink_0.set_subdev_spec('A:0 B:1', 0)
        elif tx == 3:
            self.uhd_usrp_sink_0.set_subdev_spec('A:0 A:1 B:1', 0)
        elif tx == 4:
            self.uhd_usrp_sink_0.set_subdev_spec('A:0 A:1 B:0 B:1', 0)
        else:
            print("TX Number error: TX must be one of [1, 2, 3, 4]\n")
            return
        self.uhd_usrp_sink_0.set_samp_rate(samp_rate)
        self.uhd_usrp_sink_0.set_time_unknown_pps(uhd.time_spec())
        for i in range(self.tx):
            self.uhd_usrp_sink_0.set_center_freq(center_freq_tx, i)
            self.uhd_usrp_sink_0.set_gain(power_gain_tx, i)
            self.uhd_usrp_sink_0.set_antenna('TX/RX', i)
            self.uhd_usrp_sink_0.set_bandwidth(samp_rate, i)

        self.beamnet_source_signal = [beamnet.source_signal(tx, i, fft_size, sym_sync, sym_pd, sync_word, work_mode) for i in range(self.tx)]
        self.reverse_fft_vxx = [fft.fft_vcc(fft_size, False, (()), True, 1) for i in range(self.tx)]
        self.blocks_vector_to_stream = [blocks.vector_to_stream(gr.sizeof_gr_complex*1, fft_size) for i in range(self.tx)]
        self.blocks_multiply_const_vxx = [blocks.multiply_const_vcc((sig_coeff, )) for i in range(self.tx)]

        self.beamnet_energy_detector_0 = beamnet.energy_detector(win_size)
        self.beamnet_symbol_sync_0 = beamnet.symbol_sync(sym_sync, np.fft.ifft(np.fft.fftshift(sync_word)))
        self.beamnet_packet_extraction_0 = beamnet.packet_extraction(samp_rate, fft_size, sym_pkt, win_size + sym_pkt * fft_size, thr, 0.1)
        self.beamnet_packet_demux_0 = beamnet.packet_demux(tx, fft_size, sym_sync, sym_pd)

        self.blocks_file_sink_0 = blocks.file_sink(gr.sizeof_gr_complex*1, rx_file_name, False)
        self.blocks_file_sink_0.set_unbuffered(False)
        self.blocks_file_sink_1 = blocks.file_sink(gr.sizeof_float*1, 'debug_sync_nrg.bin', False)
        self.blocks_file_sink_1.set_unbuffered(False)
        self.blocks_file_sink_2 = blocks.file_sink(gr.sizeof_float*1, 'debug_sync_symbol.bin', False)
        self.blocks_file_sink_2.set_unbuffered(False)
        self.blocks_file_sink_3 = blocks.file_sink(gr.sizeof_gr_complex*fft_size, pkt_file_name, False)
        self.blocks_file_sink_3.set_unbuffered(False)

        ##################################################
        # Connections
        ##################################################
        for i in range(self.tx):
            self.connect((self.beamnet_source_signal[i], 0), (self.reverse_fft_vxx[i], 0))
            self.connect((self.reverse_fft_vxx[i], 0), (self.blocks_vector_to_stream[i], 0))
            self.connect((self.blocks_vector_to_stream[i], 0), (self.blocks_multiply_const_vxx[i], 0))
            self.connect((self.blocks_multiply_const_vxx[i], 0), (self.uhd_usrp_sink_0, i))

        self.connect((self.uhd_usrp_source_0, 0), (self.beamnet_energy_detector_0, 0))
        self.connect((self.uhd_usrp_source_0, 0), (self.beamnet_packet_extraction_0, 0))
        self.connect((self.uhd_usrp_source_0, 0), (self.beamnet_symbol_sync_0, 0))
        self.connect((self.beamnet_energy_detector_0, 0), (self.beamnet_packet_extraction_0, 1))
        self.connect((self.beamnet_symbol_sync_0, 0), (self.beamnet_packet_extraction_0, 2))
        self.connect((self.beamnet_packet_extraction_0, 0), (self.beamnet_packet_demux_0, 0))

        self.connect((self.uhd_usrp_source_0, 0), (self.blocks_file_sink_0, 0))
        self.connect((self.beamnet_energy_detector_0, 0), (self.blocks_file_sink_1, 0))
        self.connect((self.beamnet_symbol_sync_0, 0), (self.blocks_file_sink_2, 0))
        self.connect((self.beamnet_packet_extraction_0, 0), (self.blocks_file_sink_3, 0))


if __name__ == '__main__':
    tb = top_block()
    tb.start()
    try:
        raw_input('Press Enter to quit: \n')
    except EOFError:
        pass
    tb.stop()
    tb.wait()
