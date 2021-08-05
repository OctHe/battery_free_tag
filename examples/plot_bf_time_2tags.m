%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the beamforming performance for multiple tags
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% File options
file_dir = "multiple_tags_bf_interval_420cmx420cm/";
files = dir(file_dir);

file_options.fft_size = 16;
file_options.tx = 3;
file_options.sym_sync = 8;
file_options.sym_pd = 180;

%% 3 power sources
files_order = [4:6, 1:3];
time_file_offset = 3 + 2 * length(files_order);
pkt_file_offset = 3;

interval = (30: 30: 180)';

timestamp_3ps = [];
corr_res_3ps = [];
for file_index = files_order
    
    % Files for timestamp
    file_name = files(file_index + time_file_offset).name;
    [timestamp, pkt_num] = tag_reflection_timestamp(file_dir + file_name, 1e6, 1e-7);
    
    % Files for channel
    file_name = files(file_index + pkt_file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    [tag_1, tag_2, corr_res] = tag_demux_2tags(ch_mat, power_mat.pkt_num, 0.95);
    
    corr_res_3ps = [corr_res_3ps; mean(corr_res(tag_2))];

    timestamp_1 = timestamp(tag_1);
    timestamp_2 = timestamp(tag_2);
    
    timestamp_3ps = [timestamp_3ps; ...
        mean(timestamp_1(end) - timestamp_1(end-1)), ...
        mean(timestamp_2(end) - timestamp_2(end-1))];
    

end

%% File options
file_options.tx = 4;

%% 4 power sources
time_file_offset = 3 + 3 * length(files_order);
pkt_file_offset = 3 + length(files_order);

timestamp_4ps = [];
corr_res_4ps = [];
for file_index = files_order
    
    % Files for timestamp
    file_name = files(file_index + time_file_offset).name;
    [timestamp, pkt_num] = tag_reflection_timestamp(file_dir + file_name, 1e6, 1e-7);
    
    % Files for channel
    file_name = files(file_index + pkt_file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    [tag_1, tag_2, corr_res] = tag_demux_2tags(ch_mat, power_mat.pkt_num, 0.95);
    
    corr_res_4ps = [corr_res_4ps; mean(corr_res(tag_2))];

    timestamp_1 = timestamp(tag_1);
    timestamp_2 = timestamp(tag_2);
    
    timestamp_4ps = [timestamp_4ps; ...
        mean(timestamp_1(end) - timestamp_1(end-1)), ...
        mean(timestamp_2(end) - timestamp_2(end-1))];

end

%% Figure;
figure; hold on;
cdfplot(timestamp_3ps(:, 1));
cdfplot(timestamp_3ps(:, 2));

cdfplot(timestamp_4ps(:, 1));
cdfplot(timestamp_4ps(:, 2));

figure;
plot(interval, timestamp_3ps);

figure;
plot(interval, timestamp_4ps);