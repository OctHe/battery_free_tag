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

pkt_size = sym_pd * fft_size;

%% File path
file_name = "multiple_tags_bf_4ps_420cmx420cm/tag_pkt_innout_1.bin";

%% Correlation
corr_thr = 0.95;

[power_mat, ch_mat] = pkt_demux(file_name, file_options);

corr_res = zeros(power_mat.pkt_num, 1);
for pkt_index = 1: power_mat.pkt_num
    corr_res(pkt_index) = abs(ch_mat(1, :) * ch_mat(pkt_index, :)') / ...
        (norm(ch_mat(1, :)) * norm(ch_mat(pkt_index, :)));
end

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

figure;
stem(corr_res);

figure;
plot(abs(ch_mat'));



