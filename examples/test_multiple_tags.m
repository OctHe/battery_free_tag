%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the packet and the received power for multiple tags
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% File options
file_options.fft_size = 16;
file_options.tx = 4;
file_options.sym_sync = 8;
file_options.sym_pd = 180;

fft_size = file_options.fft_size;
sym_sync = file_options.sym_sync;
tx = file_options.tx;
sym_pd = file_options.sym_pd;

pkt_size = (sym_sync + tx + sym_pd) * fft_size;

%% File name
file_name = "multiple_tags_bf_interval_420cmx420cm/tag_pkt_mtdeb_4ps_60cm.bin";

%% Correlation
[power_mat, ch_mat] = pkt_demux(file_name, file_options);

[~, ~, corr_res] = tag_demux_2tags(ch_mat, power_mat.pkt_num, 0.95);

%% Received packets
read_file_size = pkt_size * power_mat.pkt_num;

fid = fopen(file_name, 'r');
raw = fread(fid, 2 * read_file_size, 'float32');
fclose(fid);
raw = reshape(raw, 2, []).';
read_pkt = raw(:, 1) + 1j * raw(:, 2);
read_pkt = reshape(read_pkt, pkt_size, power_mat.pkt_num);

for pkt_index = 1: power_mat.pkt_num
    
    figure; hold on;
    plot(real(read_pkt(:, pkt_index)));
    plot(imag(read_pkt(:, pkt_index)));

end

%% Figures
figure;
stem((power_mat.pd - power_mat.noise) ./ power_mat.max);
title('RX relative power');

figure;
stem(corr_res);
title('Channel correlation');

figure;
plot(abs(ch_mat'));
title('Channel matrix');


