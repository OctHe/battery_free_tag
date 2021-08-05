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
#include "packet_extraction_impl.h"

namespace gr {
  namespace beamnet {

    packet_extraction::sptr
    packet_extraction::make(float samp_rate, int fft_size, int sym_pkt, int detect_size, float thr, float inr)
    {
      return gnuradio::get_initial_sptr
        (new packet_extraction_impl(samp_rate, fft_size, sym_pkt, detect_size, thr, inr));
    }

    /*
     * The private constructor
     */
    packet_extraction_impl::packet_extraction_impl(float samp_rate, int fft_size, int sym_pkt, int detect_size, float thr, float inr)
      : gr::block("packet_extraction",
              gr::io_signature::make3(3, 3, sizeof(gr_complex), sizeof(float), sizeof(float)),
              gr::io_signature::make(1, 1, sizeof(gr_complex) * fft_size)),
        d_samp_rate(samp_rate),
        d_fft_size(fft_size),
        d_detect_size(detect_size),
        d_thr(thr),
        d_rx_state(STATE_RX_ED)
    {

        d_sym_pkt = sym_pkt;
        d_inr_samp = samp_rate * inr; // Packet interval in samples

        d_tstamp = 0;
        d_offset = 0;
        d_pkt_index = 0;
        d_peak = 0;
    }

    /*
     * Our virtual destructor.
     */
    packet_extraction_impl::~packet_extraction_impl()
    {
    }

    void
    packet_extraction_impl::forecast (int noutput_items, gr_vector_int &ninput_items_required)
    {
      /* <+forecast+> e.g. ninput_items_required[0] = noutput_items */
      for (unsigned i = 0; i < ninput_items_required.size(); i++) 
          ninput_items_required[i] = noutput_items * d_fft_size;
    }

    int
    packet_extraction_impl::general_work (int noutput_items,
                       gr_vector_int &ninput_items,
                       gr_vector_const_void_star &input_items,
                       gr_vector_void_star &output_items)
    {
      // in_sig: Input of the complex received signal
      // in_ed: Input of the energy detection result
      // in_ss: Input of the symbol sync result
      const gr_complex *in_sig = (const gr_complex *) input_items[0];
      const float *in_ed = (const float *) input_items[1];
      const float *in_ss = (const float *) input_items[2];
      gr_complex *out = (gr_complex *) output_items[0];

      switch(d_rx_state)
      {
            case STATE_RX_ED:

                // Detect the packet (Coarse time sync)
                // It returns immediately when the energy have been detected
                // Output 0 item
                for(unsigned i = 0; i < noutput_items * d_fft_size; i++)
                {
                    d_tstamp ++;

                    if(in_ed[i] >= d_thr)   
                    {
                        d_pkt_index = 0;
                        d_peak = 0;
                        
                        // Display the timestamp when detect the signal
                        std::cout << "********************" << std::endl;
                        std::cout << "Timestamp: " << d_tstamp / d_samp_rate << " s" << std::endl;

                        d_rx_state = STATE_RX_SS;

                        consume_each (i+1);
                        return 0;
                        }
                    }
              
                consume_each (noutput_items * d_fft_size);
                return 0;
            
            case STATE_RX_SS: 
                
                // Find the start of the packet (Fine time sync)
                // If tag cannot detect the SYNC_WORD, the first reflected frame when
                // the tag is activated will be broken, and this block ignores it.
                // Thus, it finds the peak in the following d_detect_size buffer and outputs 0 item
                for(unsigned i = 0; i < noutput_items * d_fft_size; i++)
                {
                    d_tstamp ++;

                    if(in_ss[i] > d_peak)
                    {
                        d_pkt_index = d_offset;
                        d_peak = in_ss[i];
                    }

                    d_offset ++;

                    if(d_offset == d_detect_size)
                    {
                        d_offset = 0;
                        if(d_detect_size >= d_sym_pkt * d_fft_size)
                            d_pkt_index -= (d_detect_size - d_sym_pkt * d_fft_size);
                        else
                            throw std::runtime_error("Detection buffer cannot smaller than packet size");

                        d_rx_state = STATE_RX_DETECTED;

                        consume_each (i+1);
                        return 0;
                        
                    }
                }
                
                consume_each (noutput_items * d_fft_size);
                return 0;

            case STATE_RX_DETECTED:

                // Output 0 item until the block gets the first sample of the next unbroken frame
                for(unsigned i = 0; i < noutput_items * d_fft_size; i++)
                {
                    d_tstamp ++;
                    d_pkt_index --;

                    if(d_pkt_index == 0)
                    {
                        d_rx_state = STATE_RX_PKT;

                        consume_each (i+1);
                        return 0;
                        
                    }
                }

                consume_each (noutput_items * d_fft_size);
                return 0;

            case STATE_RX_PKT:

                for(unsigned i = 0; i < noutput_items * d_fft_size; i++)
                {
                    

                    out[i] = in_sig[i];

                    d_offset ++;
                    
                    if(d_offset == d_sym_pkt * d_fft_size)
                    {
                        d_offset = 0;
                        d_rx_state = STATE_RX_INR;

                        consume_each (i+1);
                        return (i+1) / d_fft_size;
                        
                    }
                }

                consume_each (noutput_items * d_fft_size);
                return noutput_items;

            case STATE_RX_INR:

                // Output 0 item
                for(unsigned i = 0; i < noutput_items * d_fft_size; i++)
                {
                    d_tstamp ++;
                    d_offset ++;

                    if(d_offset == d_inr_samp)
                    {
                        d_offset = 0;
                        d_rx_state = STATE_RX_ED;

                        consume_each (i+1);
                        return 0;
                        }
                    }
              
                consume_each (noutput_items * d_fft_size);
                return 0;

            default:

                throw std::runtime_error("invalid state");

                consume_each (noutput_items * d_fft_size);
                return 0;
      }
    }

  } /* namespace beamnet */
} /* namespace gr */

