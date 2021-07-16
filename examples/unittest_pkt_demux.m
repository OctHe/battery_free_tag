%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Unittest of the tag_pkt_demux file.
% It cannot be revised unless new test case need to be added.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% Params
file_name = 'tag_reflection_cs_420cmx420cm/tag_pkt_dof_1.bin';

file_options.fft_size = 16;
file_options.tx = 4;
file_options.sym_sync = 8;
file_options.sym_pd = 188;

fft_size = file_options.fft_size;
sym_sync = file_options.sym_sync;
tx = file_options.tx;
sym_pd = file_options.sym_pd;

dc_index = fft_size / 2 + 1;
data_index = dc_index + 1;

read_pkt_num = 2;
pkt_size = (sym_sync + tx + sym_pd) * fft_size;
read_pkt_size = read_pkt_num * pkt_size;

%% CE WORD
if tx == 1
    ce_data = 1;
    ce_data_inv = 1;

elseif tx == 2
    ce_data = [1, 1; 1, -1];
    ce_data_inv = [0.5, 0.5; 0.5, -0.5];

elseif tx == 4
    ce_data = [
        1, 1, 1, 1
        1, 1j, -1, -1j
        1, -1, 1, -1
        1, -1j, -1, 1j
        ];
    ce_data_inv = [
        0.25, 0.25, 0.25, 0.25
        0.25, -0.25j, -0.25, 0.25j
        0.25, -0.25, 0.25, -0.25
        0.25, 0.25j, -0.25, -0.25j
        ];
    
else
    error("TX error");
end

ce_word_f = zeros(fft_size, 1);
ce_word_f(data_index) = 1;
ce_word = fft_size * ifft(ifftshift(ce_word_f));
ce_word = kron(ce_data, ce_word.');

%% Signal processing
fid = fopen(file_name, 'r');
raw = fread(fid, 2 * read_pkt_size, 'float32');
fclose(fid);
raw = reshape(raw, 2, []).';
read_pkt = raw(:, 1) + 1j * raw(:, 2);
read_pkt = reshape(read_pkt, pkt_size, read_pkt_num);

ch_baseline_mat = zeros(read_pkt_num, tx);
power_max_baseline_mat = zeros(read_pkt_num, 1);
power_pd_rx_baseline_mat = zeros(read_pkt_num, 1);
power_ce_rx_baseline_mat = zeros(read_pkt_num, 1);
power_ce_rcvr_baseline_mat = zeros(read_pkt_num, 1);

for pkt_index = 1: read_pkt_num
    
    each_pkt = read_pkt(:, pkt_index);
    
    sync_word_rx = each_pkt(1: sym_sync * fft_size);
    
    % Channel estimation from ce_data
    ce_word_rx = each_pkt(sym_sync * fft_size +1: (sym_sync + tx) * fft_size);
    ce_word_rx_f = 1 / fft_size * ...
        fftshift(fft(reshape(ce_word_rx, fft_size, tx), fft_size, 1), 1);
    
    ce_data_rx = ce_word_rx_f(data_index, :);
    
    H = ce_data_rx * ce_data_inv;
    H = H / H(1) * abs(H(1));
    
    power_max = sum(abs(H), 2)^2;
    
    % CE from ce_word
    Hmat = zeros(fft_size, tx);
    for fft_index = 1: fft_size
        ce_word_slot = ce_word(:, fft_index: fft_size: end);
        ce_word_rx_slot = ce_word_rx(fft_index: fft_size: end).';
        Hmat(fft_index, :) = ce_word_rx_slot / ce_word_slot;
    end
    H_from_word = mean(Hmat, 1);
    H_from_word = H_from_word / H_from_word(1) * abs(H_from_word(1));
    
    % Payload power
    rx_pd = each_pkt((sym_sync + tx) * fft_size +1: end);
    rx_pd_f = 1 / fft_size * ...
        fftshift(fft(reshape(rx_pd, fft_size, sym_pd), fft_size, 1), 1);
    
    rx_pd_data = rx_pd_f(data_index, :);
    
    power = (rx_pd' * rx_pd) / (sym_pd * fft_size);
    power_f = (rx_pd_data * rx_pd_data') / sym_pd;
    
    % Packet recovery
    ce_word_rcvr = H * ce_word;
    
    power_ce_rcvr = (ce_word_rcvr * ce_word_rcvr') / fft_size / tx;
    power_ce_rx = (ce_word_rx' * ce_word_rx) / fft_size / tx;

    % Results
    ch_baseline_mat(pkt_index, :) = H;
    power_pd_rx_baseline_mat(pkt_index) = power;
    power_max_baseline_mat(pkt_index) = power_max;
    power_ce_rx_baseline_mat(pkt_index) = power_ce_rx;
    power_ce_rcvr_baseline_mat(pkt_index) = power_ce_rcvr;
    
end

[power_mat, ch_mat] = pkt_demux(file_name, file_options);

%% Figure;
% ch_diff = ch_baseline_mat - ch_mat

figure; hold on;
plot(power_pd_rx_baseline_mat);
plot(power_mat.pd);

figure; hold on;
plot(power_max_baseline_mat);
plot(power_mat.max);