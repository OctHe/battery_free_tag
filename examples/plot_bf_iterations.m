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

dist = [60, 150, 240];

power_pd_mtdeb = zeros(length(files_order), 2);
power_pd_innout_1 = zeros(length(files_order), 2);
power_pd_innout_2 = zeros(length(files_order), 2);
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
    power_pd_innout_1_type = []; 
    power_pd_innout_2_type = []; 
    power_max_type = [];
    power_norm_type = [];
    power_noise_type = [];
    for file_index = files_order

        file_name = files(file_index + file_offset).name;
        [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
        
        power_pd_mtdeb_type = [power_pd_mtdeb_type; mean(power_mat.pd(2: end))]; 
        
        % Trace-driven simulation for In-N-out
        Hest = mean(ch_mat, 1);
        
        bf_weight = iterative_phase_alignment(Hest, file_options.tx, 20, "maxmin");
        power_pd_innout_1_type = [power_pd_innout_1_type; abs(Hest * bf_weight).^2];
        
        bf_weight = iterative_phase_alignment(Hest, file_options.tx, 10, "maxmin");
        power_pd_innout_2_type = [power_pd_innout_2_type; abs(Hest * bf_weight).^2];
            
        power_max_type = [power_max_type; mean(power_mat.max)]; 
        power_norm_type = [power_norm_type; mean(power_mat.norm)];
        power_noise_type = [power_noise_type; mean(power_mat.noise)]; 

    end
    
    power_pd_mtdeb(:, type_index) = power_pd_mtdeb_type;
    power_pd_innout_1(:, type_index) = power_pd_innout_1_type;
    power_pd_innout_2(:, type_index) = power_pd_innout_2_type;
    
    power_max(:, type_index) = power_max_type;
    power_norm(:, type_index) = power_norm_type;
    power_noise(:, type_index) = power_noise_type;
end

relative_power_mtdeb = (power_pd_mtdeb - power_noise) ./ power_max;
relative_power_innout_2 = (power_pd_innout_2 - power_noise) ./ power_max;
relative_power_innout_1 = (power_pd_innout_1 - power_noise) ./ power_max;


power_gain_mtdeb = power_pd_mtdeb ./ power_norm;
power_gain_innout_1 = power_pd_innout_1 ./ power_norm;
power_gain_innout_2 = power_pd_innout_2 ./ power_norm;


%% Figure
for dist_index = 1: length(dist)
    figure; hold on;
    bar([power_gain_mtdeb(dist_index, :); power_gain_innout_1(dist_index, :); power_gain_innout_2(dist_index, :)].');
end