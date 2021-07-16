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
#include <gnuradio/expj.h>
#include <volk/volk.h>
#include "source_signal_impl.h"


namespace gr {
  namespace beamnet {

    source_signal::sptr
    source_signal::make(int tx, int index, int fft_size, int hd_len, int pd_len, const std::vector<gr_complex> &sync_word, int mode)
    {
      return gnuradio::get_initial_sptr
        (new source_signal_impl(tx, index, fft_size, hd_len, pd_len, sync_word, mode));
    }

    /*
     * The private constructor
     */
    source_signal_impl::source_signal_impl(int tx, int index, int fft_size, int sym_sync, int sym_pd, const std::vector<gr_complex> &sync_word, int mode)
      : gr::sync_block("source_signal",
              gr::io_signature::make(0, 0, 0),
              gr::io_signature::make(1, 1, sizeof(gr_complex) * fft_size)),
      d_tx(tx),
      d_fft_size(fft_size),
      d_sym_sync(sym_sync),
      d_sym_pd(sym_pd),
      d_sync_word(sync_word),
      d_tx_state(STATE_TX_SYNC),
      d_pd_state(STATE_TX_PD_CS),
      d_mode(mode)
    {
        // SYNC WORD (Normalization)
        gr_complex sync_word_en_c;
        float sync_word_en;
        volk_32fc_x2_conjugate_dot_prod_32fc(&sync_word_en_c, sync_word.data(), sync_word.data(), sync_word.size());
        volk_32fc_deinterleave_real_32f(&sync_word_en, &sync_word_en_c, 1);
        for(int i = 0; i < fft_size; i++)
            d_sync_word[i] = sync_word[i] / std::sqrt(sync_word_en);

        // CE_WORD
        if(tx == 4)
            d_ce_word = {
                {gr_complex(1, 0), gr_complex(1, 0), gr_complex(1, 0), gr_complex(1, 0)},
                {gr_complex(1, 0), gr_complex(0, 1), gr_complex(-1, 0), gr_complex(0, -1)},
                {gr_complex(1, 0), gr_complex(-1, 0), gr_complex(1, 0), gr_complex(-1, 0)},
                {gr_complex(1, 0), gr_complex(0, -1), gr_complex(-1, 0), gr_complex(0, 1)}
            };
        else if(tx == 2)
            d_ce_word = {
                {gr_complex(1, 0), gr_complex(1, 0)},
                {gr_complex(1, 0), gr_complex(-1, 0)}
            };
        else if(tx == 1)
            d_ce_word = {
                {gr_complex(1, 0)}
            };
        else
            throw std::runtime_error("The number of TXs must be {1, 2, 4}");

       d_weight = gr_complex(1, 0);     // Beamforming weight
       d_index = index % tx;            // TX index
       d_sym_offset = 0;

       // Message port
       message_port_register_in(pmt::mp("phase"));
       set_msg_handler(pmt::mp("phase"), boost::bind(&source_signal_impl::phase_msg, this, _1));

    }
    
    /*
     * Message handler
     */
    void
    source_signal_impl::phase_msg(pmt::pmt_t msg)
    {
        float phase;

        phase = pmt::f32vector_ref(pmt::cdr(msg), d_index);

        if(d_mode & MODE_BF)
        {
            d_weight = gr_expj(TWO_PI * phase);
            d_pd_state = STATE_TX_PD_BF;
        }

    }

    /*
     * Our virtual destructor.
     */
    source_signal_impl::~source_signal_impl()
    {
    }

    int
    source_signal_impl::work(int noutput_items,
        gr_vector_const_void_star &input_items,
        gr_vector_void_star &output_items)
    {
      gr_complex *out = (gr_complex *) output_items[0];

      int DC_INDEX = d_fft_size / 2;
      int BASIC_INDEX = DC_INDEX +1; 
      std::vector<gr_complex> ce_signal(d_fft_size, 0); 
      size_t block_size = output_signature()->sizeof_stream_item (0);

      for(int i = 0; i < noutput_items; i++)
      {
       switch(d_tx_state)
       {

            case STATE_TX_SYNC:

                memcpy(out, d_sync_word.data(), block_size);

                // volk_32fc_s32fc_multiply_32fc(out, out, d_weight, d_fft_size);
                
                out += d_fft_size;
                d_sym_offset ++;

                if(d_sym_offset == d_sym_sync)       // The length of SYNC_WORD is d_fft_size
                {
                    d_sym_offset = 0;
                    d_tx_state = STATE_TX_CE;
                }
                break;

            case STATE_TX_CE:

                ce_signal[BASIC_INDEX] = d_ce_word[d_index][d_sym_offset];
                memcpy(out, ce_signal.data(), block_size);

                // volk_32fc_s32fc_multiply_32fc(out, out, d_weight, d_fft_size);

                out += d_fft_size;
                d_sym_offset ++;

                if(d_sym_offset == d_tx)
                {
                    d_sym_offset = 0;
                    d_tx_state = STATE_TX_PD;
                }

                break;

            case STATE_TX_PD:
                switch(d_pd_state)
                {
                    case STATE_TX_PD_CS:
                        
                        memset(out, 0, block_size);
                        if(d_mode & MODE_DOF_SIG)  // Cold start with distributed Orthogonal Frequency (DOF) signal
                            out[BASIC_INDEX + d_index] = 1;
                        else                    // Single-tone signal
                            out[BASIC_INDEX] = 1;

                        volk_32fc_s32fc_multiply_32fc(out, out, d_weight, d_fft_size);
                        
                        out += d_fft_size;
                        d_sym_offset ++;
                        
                        break;

                    case STATE_TX_PD_BF:

                        memset(out, 0, block_size);
                        out[BASIC_INDEX] = 1;

                        volk_32fc_s32fc_multiply_32fc(out, out, d_weight, d_fft_size);

                        out += d_fft_size;
                        d_sym_offset ++;

                        break;

                    default:
                        throw std::runtime_error("invalid state");
                        break;
                }

                if(d_sym_offset == d_sym_pd)
                {
                    d_sym_offset = 0;
                    d_tx_state = STATE_TX_SYNC;
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

