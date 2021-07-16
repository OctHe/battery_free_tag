/* -*- c++ -*- */
/* 
 * Copyright 2021 gr-beamnet author.
 * 
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <gnuradio/io_signature.h>
#include "packet_demux_impl.h"
#include <volk/volk.h>

namespace gr {
  namespace beamnet {

    packet_demux::sptr
    packet_demux::make(int tx, int fft_size, int sym_sync, int sym_pd)
    {
      return gnuradio::get_initial_sptr
        (new packet_demux_impl(tx, fft_size, sym_sync, sym_pd));
    }

    /*
     * The private constructor
     */
    packet_demux_impl::packet_demux_impl(int tx, int fft_size, int sym_sync, int sym_pd)
      : gr::sync_block("packet_demux",
              gr::io_signature::make(1, 1, sizeof(gr_complex) * fft_size),
              gr::io_signature::make(0, 0, 0)),
        d_tx(tx),
        d_fft_size(fft_size),
        d_sym_sync(sym_sync),
        d_sym_pd(sym_pd),
        d_rx_state(STATE_RX_SYNC)
    {
        d_sym_offset = 0;
        d_nrg = 0;

        d_ce_word.resize(d_fft_size * tx);

        message_port_register_out(pmt::mp("ce"));
    }

    /*
     * Our virtual destructor.
     */
    packet_demux_impl::~packet_demux_impl()
    {
    }

    int
    packet_demux_impl::work(int noutput_items,
        gr_vector_const_void_star &input_items,
        gr_vector_void_star &output_items)
    {
      const gr_complex *in = (const gr_complex *) input_items[0];

      float nrg[noutput_items * d_fft_size];

      // Demux the packet
      volk_32fc_magnitude_squared_32f(nrg, in, noutput_items * d_fft_size);

        for(unsigned i = 0; i < noutput_items; i++)
        {
            switch(d_rx_state)
            {
                case STATE_RX_SYNC:

                    d_sym_offset ++;

                    if(d_sym_offset == d_sym_sync)
                    {

                        d_sym_offset = 0;
                        d_rx_state = STATE_RX_CE;
                    }

                    break;
                    
                case STATE_RX_CE:

                    for(unsigned j = 0; j < d_fft_size; j++)
                        d_ce_word[d_sym_offset * d_fft_size + j] = in[i * d_fft_size + j];

                    d_sym_offset ++;

                    if(d_sym_offset == d_tx)
                    {

                        // Send the received CE_WORD to next block with message
                        pmt::pmt_t msg_vec = pmt::make_vector(d_tx * d_fft_size, pmt::from_complex(gr_complex(0, 0)));
                        for(unsigned j = 0; j < d_fft_size * d_tx; j++)
                            pmt::vector_set(msg_vec, j, pmt::from_complex(d_ce_word[j]));

                        pmt::pmt_t msg_pair = pmt::cons(pmt::make_dict(), msg_vec);
                        message_port_pub(pmt::mp("ce"), msg_pair);

                        d_sym_offset = 0;
                        d_rx_state = STATE_RX_PD;
                    }

                    break;

                case STATE_RX_PD:

                    // Calculate the energy
                    for(unsigned j = 0; j < d_fft_size; j++)
                        d_nrg += nrg[i * d_fft_size + j];

                    d_sym_offset ++;
        
                    if(d_sym_offset == d_sym_pd)
                    {
                        // Output the energy
                        d_nrg = d_nrg / (d_sym_pd * d_fft_size);
                        
                        std::cout << "Received power: " << d_nrg << std::endl;
                        
                        d_sym_offset = 0;
                        d_rx_state = STATE_RX_SYNC;
                    }
                    break;

                default:
                    throw std::runtime_error("invalid state");
                    break;
            }
        }

      // Tell runtime system how many output items we produced.
      return noutput_items;
    }

  } /* namespace beamnet */
} /* namespace gr */

