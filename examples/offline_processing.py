#!/usr/bin/env python2
# -*- coding: utf-8 -*-
##################################################
# GNU Radio Python Flow Graph
# Title: Top Block
# GNU Radio version: 3.7.13.5
##################################################

from gnuradio import blocks
#  from gnuradio import eng_notation
from gnuradio import gr
from gnuradio.eng_option import eng_option
#  from gnuradio.filter import firdes
from optparse import OptionParser
import beamnet
import numpy as np
import pmt

class top_block(gr.top_block):

    def __init__(self, options):
        gr.top_block.__init__(self, "Top Block")

        ##################################################
        # Variables
        ##################################################
        input_file = options.input_file
        output_file = options.output_file
        tx = options.tx
        tag = options.tag
        sym_sync = options.sync_word
        sym_pd = options.payload
        sym_pkt = sym_sync + tx + sym_pd

        samp_rate = 1e6
        fft_size = 16
        win_size = 640
        thr = 1e-7
        sync_word = (0, 0, -0.7485-0.6631j, 0.8855+0.4647j, 0.5681-0.8230j, 0.8855-0.4647j, -0.3546+0.9350j, 1, 0, -0.3546+0.9350j, 0.8855-0.4647j, 0.5681-0.8230j, 0.8855+0.4647j, -0.7485-0.6631j, -0.9709+0.2393j, 0)

        ##################################################
        # Blocks
        ##################################################

        # File sources
        self.blocks_file_source_0 = blocks.file_source(gr.sizeof_gr_complex*1, input_file, False)
        self.blocks_file_source_0.set_begin_tag(pmt.PMT_NIL)
        self.blocks_file_sink_2 = blocks.file_sink(gr.sizeof_gr_complex*fft_size, output_file, False)
        self.blocks_file_sink_2.set_unbuffered(False)

        # File sinks
        if options.debug:
            self.blocks_file_sink_0 = blocks.file_sink(gr.sizeof_float*1, 'debug_sync_nrg.bin', False)
            self.blocks_file_sink_0.set_unbuffered(False)
            self.blocks_file_sink_1 = blocks.file_sink(gr.sizeof_float*1, 'debug_sync_symbol.bin', False)
            self.blocks_file_sink_1.set_unbuffered(False)

        # Signal processing
        self.blocks_throttle_0 = blocks.throttle(gr.sizeof_gr_complex*1, samp_rate,True)
        self.beamnet_energy_detector_0 = beamnet.energy_detector(win_size)
        self.beamnet_symbol_sync_0 = beamnet.symbol_sync(sym_sync, np.fft.ifft(np.fft.fftshift(sync_word)))
        self.beamnet_packet_extraction_0 = beamnet.packet_extraction(samp_rate, fft_size, sym_pkt, win_size + sym_pkt * fft_size, thr, 0.1)
        self.beamnet_packet_demux_0 = beamnet.packet_demux(tx, fft_size, sym_sync, sym_pd)
        self.beamnet_phase_alignment_0 = beamnet.phase_alignment(fft_size, tx, tag, 1000)

        ##################################################
        # Connections
        ##################################################
        self.connect((self.blocks_file_source_0, 0), (self.blocks_throttle_0, 0))
        self.connect((self.blocks_throttle_0, 0), (self.beamnet_energy_detector_0, 0))
        self.connect((self.blocks_throttle_0, 0), (self.beamnet_packet_extraction_0, 0))
        self.connect((self.blocks_throttle_0, 0), (self.beamnet_symbol_sync_0, 0))
        self.connect((self.beamnet_energy_detector_0, 0), (self.beamnet_packet_extraction_0, 1))
        self.connect((self.beamnet_symbol_sync_0, 0), (self.beamnet_packet_extraction_0, 2))
        self.connect((self.beamnet_packet_extraction_0, 0), (self.beamnet_packet_demux_0, 0))
        self.connect((self.beamnet_packet_extraction_0, 0), (self.blocks_file_sink_2, 0))

        self.msg_connect((self.beamnet_packet_demux_0, 'ce'), (self.beamnet_phase_alignment_0, 'ce'))

        if options.debug:
            self.connect((self.beamnet_energy_detector_0, 0), (self.blocks_file_sink_0, 0))
            self.connect((self.beamnet_symbol_sync_0, 0), (self.blocks_file_sink_1, 0))

if __name__ == '__main__':

    usage = "Usage: This is the offline process for the distributed energy beamforming system. \n" + \
    "Please set the following options according to the input file."

    parser = OptionParser(usage=usage, option_class=eng_option, conflict_handler="resolve")
    parser.add_option("-i", "--input_file", type="string",
                      help="set the input file")
    parser.add_option("-o", "--output_file", type="string", default="debug_tag_pkt",
                      help="set the output file [default=%default]")
    parser.add_option("-t", "--tx", type="int",
                      help="set the number of power sources")
    parser.add_option("-g", "--tag", type="int",
                      help="set the number of tags")
    parser.add_option("-s", "--sync_word", type="int",
                      help="set the number of sync words")
    parser.add_option("-p", "--payload", type="int",
                      help="set the number of payload")
    parser.add_option("","--debug", action="store_true",
                      help="Log files for debug. These files are at the work directory")

    (options, args) = parser.parse_args ()

    tb = top_block(options)
    tb.start()
    try:
        raw_input('Press Enter to quit: ')
    except EOFError:
        pass
    tb.stop()
    tb.wait()
