%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the beamforming performance for the single-tag case
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% File options
file_dir = "tag_reflection_bf_dist_420cmx420cm/";
files = dir(file_dir);

file_options.fft_size = 16;
file_options.tx = 3;
file_options.sym_sync = 8;
file_options.sym_pd = 180;
file_options.samp_rate = 1e6;

%% Recevied power for 3, 4 power sources
files_order = [3, 1:2];
file_offset = 3;

dist = [60, 150, 240]';

power_pd_mtdeb = zeros(length(files_order), 2);
power_pd_ivn = zeros(length(files_order), 2);
power_pd_innout_100 = zeros(length(files_order), 2);
power_pd_innout_50 = zeros(length(files_order), 2);
power_pd_innout_10 = zeros(length(files_order), 2);
power_max = zeros(length(files_order), 2);
power_norm = zeros(length(files_order), 2);
power_noise = zeros(length(files_order), 2);
for type_index = 1: 2
    file_offset = 3 + (type_index -1) * files_order;
    
    if type_index == 1
        file_options.tx = 3;
    elseif type_index == 2
        file_options.tx = 4;
    end
    
    power_pd_mtdeb_type = []; 
    power_pd_ivn_type = []; 
    power_pd_innout_type_100 = []; 
    power_pd_innout_type_50 = []; 
    power_pd_innout_type_10 = []; 
    power_max_type = [];
    power_norm_type = [];
    power_noise_type = [];
    for file_index = files_order

        file_name = files(file_index + file_offset).name;
        [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
        
        power_pd_mtdeb_type = [power_pd_mtdeb_type; mean(power_mat.pd(2: end))]; 
        power_pd_ivn_type = [power_pd_ivn_type; power_mat.pd(1)]; 
        
        % Trace-driven simulation for In-N-out
        Hest = mean(ch_mat, 1);
        
        bf_weight = iterative_phase_alignment(Hest, file_options.tx, 1e2, "maxmin");
        power_pd_innout_type_100 = [power_pd_innout_type_100; abs(Hest * bf_weight).^2];
        
        bf_weight = iterative_phase_alignment(Hest, file_options.tx, 50, "maxmin");
        power_pd_innout_type_50 = [power_pd_innout_type_50; abs(Hest * bf_weight).^2];
        
        bf_weight = iterative_phase_alignment(Hest, file_options.tx, 10, "maxmin");
        power_pd_innout_type_10 = [power_pd_innout_type_10; abs(Hest * bf_weight).^2];
            
        power_max_type = [power_max_type; mean(power_mat.max)]; 
        power_norm_type = [power_norm_type; mean(power_mat.norm)];
        power_noise_type = [power_noise_type; mean(power_mat.noise)]; 

    end
    
    power_pd_mtdeb(:, type_index) = power_pd_mtdeb_type;
    power_pd_ivn(:, type_index) = power_pd_ivn_type;
    power_pd_innout_100(:, type_index) = power_pd_innout_type_100;
    power_pd_innout_50(:, type_index) = power_pd_innout_type_50;
    power_pd_innout_10(:, type_index) = power_pd_innout_type_10;
    
    power_max(:, type_index) = power_max_type;
    power_norm(:, type_index) = power_norm_type;
    power_noise(:, type_index) = power_noise_type;
end

power_gain_mtdeb = power_pd_mtdeb ./ power_norm;
power_gain_ivn = power_pd_ivn ./ power_norm;
power_gain_innout_100 = power_pd_innout_100 ./ power_norm;
power_gain_innout_50 = power_pd_innout_50 ./ power_norm;
power_gain_innout_10 = power_pd_innout_10 ./ power_norm;

%% Charging time for 3, 4 power sources
for type_index = 1: 2
    
    file_offset = 3 + (1 + type_index) * files_order;
    if type_index == 1
        file_options.tx = 3;
    elseif type_index == 2
        file_options.tx = 4;
    end
    
    charging_time_type = [];
    charging_time_std_type = [];
    for file_index = files_order

        file_name = files(file_index + file_offset).name;
        [timestamp, pkt_num] = tag_reflection_timestamp(file_dir + file_name, 1e6, 1e-7);
        
        charging_time_type = [charging_time_type; mean(timestamp(2: end) - timestamp(1: end-1))];
        charging_time_std_type = [charging_time_std_type; std(timestamp(2: end) - timestamp(1: end-1))];
        
    end
    charging_time(:, type_index) = charging_time_type;
    charging_time_std(:, type_index) = charging_time_std_type;
    
end

%% Figure
for dist_index = 1: length(dist)
    figure; hold on;
    bar([power_gain_mtdeb(dist_index, :); power_gain_innout_100(dist_index, :); ...
        power_gain_innout_50(dist_index, :); power_gain_innout_10(dist_index, :); ...
        power_gain_ivn(dist_index, :)].');
end

figure; hold on;
plot(dist, charging_time);

figure; hold on;
errorbar([dist, dist], charging_time, charging_time_std);