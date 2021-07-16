#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
# Copyright 2021 gr-beamnet author.
# 
# This is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
# 
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this software; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.
# 

import numpy as np
from gnuradio import gr
import pmt

class phase_alignment(gr.sync_block):
    """
    docstring for block phase_alignment
    """
    def __init__(self, fft_size, tx, tag, Nloop):
        gr.sync_block.__init__(self,
            name="phase_alignment",
            in_sig=None,
            out_sig=None)

        self.fft_size = fft_size
        self.tx = tx
        self.tag = tag
        self.ite_loop = Nloop

        # Inverse of the ce_word matrix
        if tx == 1:
            self.ce_word_inv = np.array([1]);
        elif tx == 2:
            self.ce_word_inv = np.array([[0.5, 0.5], [0.5, -0.5]])
        elif tx == 4:
            self.ce_word_inv = np.array([
                [0.25, 0.25, 0.25, 0.25],
                [0.25, -0.25j, -0.25, 0.25j],
                [0.25, -0.25, 0.25, -0.25],
                [0.25, 0.25j, -0.25, -0.25j]
                ])

        self.ref_ch = np.zeros([1, tx], dtype=complex)
        self.ch_list = np.zeros([tag, tx], dtype=complex)
        self.phase = np.zeros([tx, 1], dtype=float)

        self.pkt_num = 0
        self.collected_ch_num = 0

        self.message_port_register_in(pmt.intern('ce'))
        self.message_port_register_out(pmt.intern('phase'))
        self.set_msg_handler(pmt.intern('ce'), self.ce_and_pa)

    def ce_and_pa(self, msg):
        """TODO: Docstring for function.

        :arg1: TODO
        :returns: TODO

        """

        dc_index = self.fft_size / 2
        DATA_INDEX = dc_index + 1

        corr_vec = np.zeros(self.tag, dtype=float)
        corr_thr = 0.95

        # Packet counter
        self.pkt_num = self.pkt_num + 1

        print "Packet Index: ", self.pkt_num

        # Sync word processing
        ce_word_sig = np.zeros([self.tx * self.fft_size, 1], dtype=complex)
        ce_word_rx = np.zeros(self.tx, dtype=complex)

        for sig_index in range(self.tx * self.fft_size):
            ce_word_sig[sig_index] = pmt.to_complex(pmt.vector_ref(pmt.cdr(msg), sig_index))
        ce_word_sig_reshape = np.reshape(ce_word_sig, newshape=[self.fft_size, self.tx], order='F')

        ce_word_sig_reshape = 1. / self.fft_size * np.fft.fft(ce_word_sig_reshape, n=self.fft_size, axis=0)
        ce_word_sig_reshape = np.fft.fftshift(ce_word_sig_reshape, axes=(0, ))

        for tx_index in range(self.tx):
            ce_word_rx[tx_index] = ce_word_sig_reshape[DATA_INDEX][tx_index]

        # Channel estimation for the received signal
        rx_ch = np.dot(ce_word_rx, self.ce_word_inv)
        rx_ch = rx_ch / rx_ch[0] * np.abs(rx_ch[0])

        # Channel collection at the cold start process 
        if self.collected_ch_num < self.tag:

            # Coefficient
            for tag_index in range(self.collected_ch_num):
                corr_vec[tag_index] = np.abs(np.dot(self.ch_list[tag_index, :], rx_ch.conj().T)) \
                        / np.linalg.norm(self.ch_list[tag_index, :]) \
                        / np.linalg.norm(rx_ch)

            # Check whether the channel has been received before
            # If the channel has been received, than update it
            if np.max(corr_vec) > corr_thr:
                self.ch_list[np.argmax(corr_vec), :] = rx_ch
                print "Frame from tag ", np.argmax(corr_vec) +1
            else:
                self.ch_list[self.collected_ch_num, :] = rx_ch
                self.collected_ch_num = self.collected_ch_num +1
                print "Frame from tag ", self.collected_ch_num
            
            if self.collected_ch_num == self.tag:
                print "Transfer to beamforming mode"

                # Phase alignment
                self.phase = self.iterative_phase_alignment(self.ite_loop, 0.01)

                # Send the aligned phase using message to each power source
                msg_vec = pmt.make_f32vector(self.tx, 0)
                for tx_index in range(self.tx):
                    pmt.f32vector_set(msg_vec, tx_index, self.phase[tx_index][0])

                msg_pair = pmt.cons(pmt.make_dict(), msg_vec)
                self.message_port_pub(pmt.intern("phase"), msg_pair)

            return
        
        # Beamforming mode
        if self.collected_ch_num >= self.tag:
        
            # Channel update
            for tag_index in range(self.tag):
                corr_vec[tag_index] = np.abs(np.dot(self.ch_list[tag_index, :], rx_ch.conj().T)) \
                        / np.linalg.norm(self.ch_list[tag_index, :]) \
                        / np.linalg.norm(rx_ch)

            print "Frame from tag ", np.argmax(corr_vec) +1
            
            if np.argmax(corr_vec) > corr_thr:
                self.ch_list[np.argmax(corr_vec), :] = rx_ch

            # Phase alignment
            self.phase = self.iterative_phase_alignment(self.ite_loop, 0.01)

            # Send the aligned phase using message to each power source
            msg_vec = pmt.make_f32vector(self.tx, 0)
            for tx_index in range(self.tx):
                pmt.f32vector_set(msg_vec, tx_index, self.phase[tx_index][0])

            msg_pair = pmt.cons(pmt.make_dict(), msg_vec)
            self.message_port_pub(pmt.intern("phase"), msg_pair)

    def iterative_phase_alignment(self, ite_loop, delta_phase_base):
        """TODO: Docstring for function.

        :arg1: TODO
        :returns: TODO

        """

        phase_now = np.zeros([self.tx, 1], dtype=float)
        phase_opt = np.zeros([self.tx, 1], dtype=float)
        power_opt = 0

        rx_power_max = np.sum(np.abs(self.ch_list), axis=1, keepdims=True)**2

        print "The maximum power: ", rx_power_max

        for ite_index in range(ite_loop):

            # Generate random phase
            delta_phase = delta_phase_base * np.random.rand(self.tx, 1)
            phase_now = phase_now + delta_phase

            bf_weight = np.exp(2j * np.pi * phase_now)

            # Power comparison
            rx_power = np.abs(np.dot(self.ch_list, bf_weight))**2
            relative_power = rx_power / rx_power_max
            power_now = np.min(relative_power)

            if power_now > power_opt:
                power_opt = power_now
                phase_opt = phase_now
            else:
                phase_now = phase_opt

        # Normalization
        phase_opt = phase_opt - phase_opt[0]

        return phase_opt
