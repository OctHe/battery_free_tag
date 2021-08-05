%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot tags' performance
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% File path and options
file_dir = "./power_distri_bs_dist_1ps/";
files = dir(file_dir);

file_options.fft_size = 16;
file_options.tx = 1;
file_options.sym_sync = 8;
file_options.sym_pd = 180;

ignore_pkt = 10;    % Ignore the *ignore_pkt* packets at the file begin
                    % The packets at the file begin may not correct
                    % because the USRP hardware

                    
%% Power distance signal files
file_offset = 3;
files_order = [5, 1:4];

dist = 60: 60: 300;

power_pd_dist = [];
power_var = [];
for file_index = files_order
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);

    power_pd_mat = power_mat.pd(ignore_pkt +1: end);
    
    power_pd_dist = [power_pd_dist; mean(power_pd_mat)];
    power_var = [power_var; std(power_pd_mat)];
end

figure;
plot(dist, 10 * log10(power_pd_dist));

figure;
errorbar(dist, 10 * log10(power_pd_dist), 10 * log10(power_var));

%% File path and options
file_dir = "./tag_reflection_bs_dist_1ps/";
files = dir(file_dir);

file_options.fft_size = 16;
file_options.tx = 1;
file_options.sym_sync = 8;
file_options.sym_pd = 180;
    
%% tag reflection files
files_order = [3:5, 1:2];
dist = [30:30:120, 180];
file_num = length(files_order);
file_offset = 3 + file_num;

charging_time = [];
charging_time_std = [];
for file_index = files_order
    
    file_name = files(file_index + file_offset).name;
    [timestamp, pkt_num] = tag_reflection_timestamp(file_dir + file_name, 1e6, 1e-7);

    charging_time = [charging_time; mean(timestamp(2: end) - timestamp(1: end-1))];
    charging_time_std = [charging_time_std; std(timestamp(2: end) - timestamp(1: end-1))];
    
end

figure;
plot(dist, charging_time);

figure;
errorbar(dist, charging_time, charging_time_std);