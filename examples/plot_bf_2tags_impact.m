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
file_options.samp_rate = 1e6;

%% In-N-out
file_num = 10;
file_offset = 3;

file_dir = "multiple_tags_bf_4ps_impact_420cmx420cm/";
files = dir(file_dir);

power_pd = zeros(file_num, 2);
power_max = zeros(file_num, 2);

corr_res_vec = zeros(file_num, 1);

for file_index = 1: file_num
    
    file_name = files(file_index + file_offset).name
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
        
    [tag_1, tag_2, corr_res] = tag_demux_2tags(ch_mat, power_mat.pkt_num, 0.95);
    
    power_pd_tag_1 = power_mat.pd(tag_1);
    power_max_tag_1 = power_mat.max(tag_1);
    if(isempty(tag_2))
        power_pd_tag_2 = 0;
        power_max_tag_2 = 1;
        corr_res_vec(file_index) = 0;
    else
        power_pd_tag_2 = power_mat.pd(tag_2);
        power_max_tag_2 = power_mat.max(tag_2);
        corr_res_vec(file_index) = mean(corr_res(tag_2));
    end
    
    
    power_pd(file_index, :) = [max(power_pd_tag_1), max(power_pd_tag_2)];
    power_max(file_index, :) = [max(power_max_tag_1), max(power_max_tag_2)];
    
end

figure; hold on;
plot(corr_res_vec, power_pd(:, 1) ./ power_max(:, 1), 'o');
plot(corr_res_vec, power_pd(:, 2) ./ power_max(:, 2), 'o');