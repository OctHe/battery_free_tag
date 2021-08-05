%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the power distribution for 3, 4 power sources
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% File path and options
file_dir = "./power_distri_cs_420cmx420cm/";
files = dir(file_dir);

file_options.fft_size = 16;
file_options.tx = 3;
file_options.sym_sync = 8;
file_options.sym_pd = 180;

%% DOF signal files with 3 power sources
file_num = 11;
file_offset = 3;

power_pd_3ps_dof = zeros(file_num, 1); 
power_norm_3ps_dof = zeros(file_num, 1);
power_noise_3ps_dof = zeros(file_num, 1);
for file_index = 1: file_num
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    power_pd_3ps_dof(file_index) = mean(power_mat.pd); 
    power_norm_3ps_dof(file_index) = mean(power_mat.norm);
    power_noise_3ps_dof(file_index) = mean(power_mat.noise);

end

%% Single-carrier signal files with 3 power sources
file_offset = 3 + file_num;

power_pd_3ps_sc = zeros(file_num, 1); 
power_norm_3ps_sc = zeros(file_num, 1);
power_noise_3ps_sc = zeros(file_num, 1);
for file_index = 1: file_num
	
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    power_pd_3ps_sc(file_index) = mean(power_mat.pd); 
    power_norm_3ps_sc(file_index) = mean(power_mat.norm);
    power_noise_3ps_sc(file_index) = mean(power_mat.noise);
    
end

%% File options
file_options.tx = 4;

%% DOF signal files with 4 power sources
file_num = 11;
file_offset = 3 + 2 * file_num;

power_pd_4ps_dof = zeros(file_num, 1); 
power_norm_4ps_dof = zeros(file_num, 1);
power_noise_4ps_dof = zeros(file_num, 1);
for file_index = 1: file_num
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    
    power_pd_4ps_dof(file_index) = mean(power_mat.pd); 
    power_norm_4ps_dof(file_index) = mean(power_mat.norm);
    power_noise_4ps_dof(file_index) = mean(power_mat.noise);

end

%% Single-carrier signal files with 4 power sources
file_offset = 3 + 3 * file_num;

power_pd_4ps_sc = zeros(file_num, 1); 
power_norm_4ps_sc = zeros(file_num, 1);
power_noise_4ps_sc = zeros(file_num, 1);
for file_index = 1: file_num
	
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);

    power_pd_4ps_sc(file_index) = mean(power_mat.pd); 
    power_norm_4ps_sc(file_index) = mean(power_mat.norm);
    power_noise_4ps_sc(file_index) = mean(power_mat.noise);
    
end

%% Figure;
figure; hold on;
cdfplot(sort(10 * log10(power_pd_3ps_dof)));
cdfplot(sort(10 * log10(power_pd_3ps_sc)));

figure; hold on;
cdfplot(sort(10 * log10(power_pd_4ps_dof)));
cdfplot(sort(10 * log10(power_pd_4ps_sc)));


figure; hold on;
cdfplot(power_pd_3ps_dof ./ power_norm_3ps_dof);
cdfplot(power_pd_4ps_dof ./ power_norm_4ps_dof);
xlim([0.5, 1.5]);

figure; hold on;
[f,xi] = ksdensity(power_pd_3ps_dof ./ power_norm_3ps_dof, 'bandwidth', 0.1); 
plot(xi,f);
[f,xi] = ksdensity(power_pd_4ps_dof ./ power_norm_4ps_dof, 'bandwidth', 0.1); 
plot(xi,f);
xlim([0, 2]);

power_pd_3ps_dof = sort(power_pd_3ps_dof);
power_pd_3ps_dof = power_pd_3ps_dof(2: end);
figure; hold on;
cdfplot(10 * log10(power_pd_3ps_dof));
cdfplot(10 * log10(power_pd_4ps_dof));