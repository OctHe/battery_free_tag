%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the received power for multiple tags
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

%% File path
file_dir = "multiple_tags_ce_4ps_420cmx420cm/";
files = dir(file_dir);

%% Correlation
corr_thr = 0.95;

file_offset = 3;
file_num = 12;

corr_tag_1 = zeros(file_num, 1);
corr_tag_2 = zeros(file_num, 1);
for file_index = 1: file_num
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    corr_res = zeros(power_mat.pkt_num, 1);
    for pkt_index = 1: power_mat.pkt_num
        corr_res(pkt_index) = abs(ch_mat(1, :) * ch_mat(pkt_index, :)') / ...
            (norm(ch_mat(1, :)) * norm(ch_mat(pkt_index, :)));
    end
    
    corr_tag_1(file_index) = mean(corr_res(corr_res >= corr_thr));
    corr_tag_2(file_index) = mean(corr_res(corr_res < corr_thr));

end

figure; hold on;
cdfplot(sort(corr_tag_1));
cdfplot(sort(corr_tag_2));


