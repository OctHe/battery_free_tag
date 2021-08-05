%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the threshold of tag group with channel correlation
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

%% Correlation
file_offset = 3;
files_order = [4:6, 1:3];

interval = (30: 30: 180)';

corr_tag_1_3ps = [];
corr_tag_2_3ps = [];
for file_index = files_order
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    [tag_1, tag_2, corr_res] = tag_demux_2tags(ch_mat, power_mat.pkt_num, 0.95);
    
    corr_tag_1_3ps = [corr_tag_1_3ps; mean(corr_res(tag_1))];
    corr_tag_2_3ps = [corr_tag_2_3ps; mean(corr_res(tag_2))];

end

%% File options
file_options.tx = 4;

%% Correlation
file_offset = 3 + length(files_order);

corr_tag_1_4ps = [];
corr_tag_2_4ps = [];
for file_index = files_order
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    [tag_1, tag_2, corr_res] = tag_demux_2tags(ch_mat, power_mat.pkt_num, 0.95);
    
    corr_tag_1_4ps = [corr_tag_1_4ps; mean(corr_res(tag_1))];
    corr_tag_2_4ps = [corr_tag_2_4ps; mean(corr_res(tag_2))];

end


%% figure;
figure; hold on;
cdfplot(corr_tag_1_3ps);
cdfplot(corr_tag_2_3ps);

cdfplot(corr_tag_1_4ps);
cdfplot(corr_tag_2_4ps);

figure; hold on;
[f,xi] = ksdensity(corr_tag_1_3ps, 'bandwidth', 0.02); 
plot(xi,f);
[f,xi] = ksdensity(corr_tag_2_3ps, 'bandwidth', 0.2); 
plot(xi,f);
[f,xi] = ksdensity(corr_tag_1_4ps, 'bandwidth', 0.02); 
plot(xi,f);
[f,xi] = ksdensity(corr_tag_2_4ps, 'bandwidth', 0.2); 
plot(xi,f);
xlim([0, 1]);

figure; hold on;
plot(interval, corr_tag_2_3ps);
plot(interval, corr_tag_2_4ps);
