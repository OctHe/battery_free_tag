%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the beamforming performance for multiple tags
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

%% File path
file_dir = "multiple_tags_bf_4ps_420cmx420cm/";
files = dir(file_dir);

%% 4 power sources
file_num = 12;
file_offset = 3 + file_num;

power_pd_mtdeb = zeros(file_num, 2);
power_pd_ivn = zeros(file_num, 2);
power_max = zeros(file_num, 2);
power_norm = zeros(file_num, 2);

corr_res_vec = zeros(file_num, 1);
for file_index = 1: file_num
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    [tag_1, tag_2, corr_res] = tag_demux_2tags(ch_mat, power_mat.pkt_num, 0.95);

    corr_res_vec(file_index) = mean(corr_res(tag_2));
    
    power_pd_mtdeb(file_index, :) = [max(power_mat.pd(tag_1)), max(power_mat.pd(tag_2))];
    power_pd_ivn(file_index, :) = [min(power_mat.pd(tag_1)), min(power_mat.pd(tag_2))];
    power_max(file_index, :) = [max(power_mat.max(tag_1)), max(power_mat.max(tag_2))];
    power_norm(file_index, :) = [max(power_mat.norm(tag_1)), max(power_mat.norm(tag_2))];
end



%% File options
file_dir = "multiple_tags_bf_interval_420cmx420cm/";
files = dir(file_dir);

file_options.fft_size = 16;
file_options.tx = 3;
file_options.sym_sync = 8;
file_options.sym_pd = 180;

%% 3 power sources
file_offset = 3;
files_order = [4:6, 1:3];

interval = (30: 30: 180)';

power_pd_3ps_mtdeb = [];
power_pd_3ps_ivn = [];
power_max_3ps = [];
power_norm_3ps = [];

corr_res_3ps = [];
for file_index = files_order
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    [tag_1, tag_2, corr_res] = tag_demux_2tags(ch_mat, power_mat.pkt_num, 0.95);
    
    corr_res_3ps = [corr_res_3ps; mean(corr_res(tag_2))];

    power_pd_3ps_mtdeb = [power_pd_3ps_mtdeb; max(power_mat.pd(tag_1)), max(power_mat.pd(tag_2))];
    power_pd_3ps_ivn = [power_pd_3ps_ivn; min(power_mat.pd(tag_1)), min(power_mat.pd(tag_2))];
    power_max_3ps = [power_max_3ps; max(power_mat.max(tag_1)), max(power_mat.max(tag_2))];
    power_norm_3ps = [power_norm_3ps; max(power_mat.norm(tag_1)), max(power_mat.norm(tag_2))];
end

%% File options
file_options.tx = 4;

%% 4 power sources
file_offset = 3 + length(files_order);

power_pd_4ps_mtdeb = [];
power_pd_4ps_ivn = [];
power_max_4ps = [];
power_norm_4ps = [];

corr_res_4ps = [];
for file_index = files_order
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    [tag_1, tag_2, corr_res] = tag_demux_2tags(ch_mat, power_mat.pkt_num, 0.95);
    
    corr_res_4ps = [corr_res_4ps; mean(corr_res(tag_2))];

    power_pd_4ps_mtdeb = [power_pd_4ps_mtdeb; max(power_mat.pd(tag_1)), max(power_mat.pd(tag_2))];
    power_pd_4ps_ivn = [power_pd_4ps_ivn; min(power_mat.pd(tag_1)), min(power_mat.pd(tag_2))];
    power_max_4ps = [power_max_4ps; max(power_mat.max(tag_1)), max(power_mat.max(tag_2))];
    power_norm_4ps = [power_norm_4ps; max(power_mat.norm(tag_1)), max(power_mat.norm(tag_2))]; 
end

%% Figure
figure; hold on;
plot(corr_res_3ps, min(power_pd_3ps_mtdeb ./ power_max_3ps, [], 2), 'o');
plot(corr_res_3ps, min(power_pd_3ps_ivn ./ power_max_3ps, [], 2), 'o');
ylim([0, 1]);

figure; hold on;
plot([corr_res_4ps; corr_res_vec], [min(power_pd_4ps_mtdeb ./ power_max_4ps, [], 2); min(power_pd_mtdeb ./ power_max, [], 2)], 'o');
plot([corr_res_4ps; corr_res_vec], [min(power_pd_4ps_ivn ./ power_max_4ps, [], 2); min(power_pd_ivn ./ power_max, [], 2)], 'o');
ylim([0, 1]);

figure; hold on;
plot(corr_res_3ps, min(power_pd_3ps_mtdeb ./ power_norm_3ps, [], 2), 'o');
plot(corr_res_3ps, min(power_pd_3ps_ivn ./ power_norm_3ps, [], 2), 'o');

figure; hold on;
plot([corr_res_4ps; corr_res_vec], [min(power_pd_4ps_mtdeb ./ power_norm_4ps, [], 2); min(power_pd_mtdeb ./ power_norm, [], 2)], 'o');
plot([corr_res_4ps; corr_res_vec], [min(power_pd_4ps_ivn ./ power_norm_4ps, [], 2); min(power_pd_ivn ./ power_norm, [], 2)], 'o');