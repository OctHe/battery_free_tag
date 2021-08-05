%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the output file of the gnuradio *sim_source_signal* flowgraph
% This can debug the output of the *source_signal* block by ploting the 
% signal wave from the above block.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% Params
sync_word_f = [
    0, 0, -0.7485-0.6631j, 0.8855+0.4647j, 0.5681-0.8230j, ...
    0.8855-0.4647j, -0.3546+0.9350j, 1, 0, -0.3546+0.9350j, ...
    0.8855-0.4647j, 0.5681-0.8230j, 0.8855+0.4647j, -0.7485-0.6631j, ...
    -0.9709+0.2393j, 0
    ];

tx = 3;
fft_size = 16;
sym_sync = 4;
sym_pd = 194;

read_pkt_num = 1;

pkt_size = (sym_sync + tx + sym_pd) * fft_size;

read_size = pkt_size * read_pkt_num;

%% Sync word
sync_word_f = sync_word_f / sqrt(sync_word_f * sync_word_f');
sync_word = ifft(fftshift(sync_word_f)) * fft_size;

en_sync = (sync_word * sync_word') / (fft_size * sym_sync);

%% File data
fid = fopen('debug_source_signal_tx0.bin', 'r');
raw = fread(fid, 2 * read_size, 'float32');
fclose(fid);
raw = reshape(raw, 2, []).';
tx0 = raw(:, 1) + 1j * raw(:, 2);

en_pkt = sum(abs(tx0).^2) / (pkt_size * read_pkt_num);

fid = fopen('debug_source_signal_tx1.bin', 'r');
raw = fread(fid, 2 * read_size, 'float32');
fclose(fid);
raw = reshape(raw, 2, []).';
tx1 = raw(:, 1) + 1j * raw(:, 2);

fid = fopen('debug_source_nrg.bin', 'r');
ed_res = fread(fid, read_size, 'float32');
fclose(fid);

fid = fopen('debug_source_corr.bin', 'r');
ss_res = fread(fid, read_size, 'float32');
fclose(fid);

%% Figure
disp(['Energy of sync word: ' num2str(en_sync)]);
disp(['Energy of packet: ' num2str(en_pkt)]);

figure; hold on;
plot(real(sync_word));
plot(imag(sync_word));
title('Sync word');

figure; hold on;
plot(real(tx0));
plot(imag(tx0));
title('Packet from TX 0');

figure; hold on;
plot(real(tx1));
plot(imag(tx1));
title('Packet from TX 1');

figure;
plot(ed_res);
ylim([0, 1.1]);
title('Packet Energy');

figure;
plot(ss_res);
title('Symbol Peak');