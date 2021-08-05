%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the output file of the gnuradio *packet demux* block.
% This can display the results of the above
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% Params
samp_rate = 1e6;
fft_size = 16;

tx = 4;

sym_sync = 8;
sym_pd = 180;

DC_INDEX = fft_size / 2 + 1;
data_index = DC_INDEX + 1;

read_pkt_num = 3;

pkt_size = (sym_sync + tx + sym_pd) * fft_size;
read_pkt_size = read_pkt_num * pkt_size;

%% CE WORD
if tx == 1
    ce_data = 1;
    ce_data_inv = 1;

elseif tx == 2
    ce_data = [1, 1; 1, -1];
    ce_data_inv = [0.5, 0.5; 0.5, -0.5];

elseif tx == 3
    ce_data = [
        1, 1, 1
        1, -0.5 + 0.8660254j, -0.5 - 0.8660254j
        1, -0.5 - 0.8660254j, -0.5 + 0.8660254j
        ];
    
    ce_data_inv = 1 / 3 * [
        1, 1, 1
        1, -0.5 - 0.8660254j, -0.5 + 0.8660254j
        1, -0.5 + 0.8660254j, -0.5 - 0.8660254j
        ];
    
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

%% File data
fid = fopen('tag_reflection_bf_dist_420cmx420cm/tag_pkt_ivn_4ps_60cm.bin', 'r');
raw = fread(fid, 2 * read_pkt_size, 'float32');
fclose(fid);
raw = reshape(raw, 2, []).';
read_pkt = raw(:, 1) + 1j * raw(:, 2);
read_pkt = reshape(read_pkt, pkt_size, read_pkt_num);

%% Signal processing
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
    
    % Channel estimation from ce_word
    Hmat = zeros(fft_size, tx);
    for fft_index = 1: fft_size
        ce_word_slot = ce_word(:, fft_index: fft_size: end);
        ce_word_rx_slot = ce_word_rx(fft_index: fft_size: end).';
        Hmat(fft_index, :) = ce_word_rx_slot / ce_word_slot;
    end
    H_from_word = mean(Hmat, 1);
    H_from_word = H_from_word / H_from_word(1) * abs(H_from_word(1));
    
    power_max = sum(abs(H), 2)^2;
    
    % Payload power
    rx_pd = each_pkt((sym_sync + tx) * fft_size +1: end);
    rx_pd_f = 1 / fft_size * ...
        fftshift(fft(reshape(rx_pd, fft_size, sym_pd), fft_size, 1), 1);
    
    rx_pd_data = rx_pd_f(data_index, :);
    
    power = (rx_pd' * rx_pd) / (sym_pd * fft_size);
    power_f = (rx_pd_data * rx_pd_data') / sym_pd;
    
    % Packet recovery
    ce_word_recovery = H * ce_word;
    
    power_ce_word_recovery = (ce_word_recovery * ce_word_recovery') / fft_size / tx;
    power_ce_word_rx = (ce_word_rx' * ce_word_rx) / fft_size / tx;

    % Results
    disp(['******************************']);
    disp(['Packe index: ' num2str(pkt_index)]);
    disp(['H:   (' num2str(H) ')']);
    disp(['RX power (time): ' num2str(power)]);
    disp(['Max power: ' num2str(power_max)]);
    disp(['Power CE recovery: ' num2str(power_ce_word_recovery)]);
    disp(['Power CE: ' num2str(power_ce_word_rx)]);
    
    if pkt_index <= 10
        figure; hold on;
        plot(real(each_pkt));
        plot(imag(each_pkt));
    end
    
end
