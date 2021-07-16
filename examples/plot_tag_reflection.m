%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the power distribution from only one tag
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
file_dir = "./tag_reflection_cs_420cmx420cm/";
files = dir(file_dir);

%% DOF signal files
file_offset = 3;
file_num = 16;

power_pd_dof = zeros(file_num, 1); 
power_norm_dof = zeros(file_num, 1);
power_max_dof = zeros(file_num, 1);
power_noise_dof = zeros(file_num, 1);
for file_index = 1: file_num
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    if power_mat.pkt_num > 0
        power_pd_dof(file_index) = mean(power_mat.pd); 
        power_norm_dof(file_index) = mean(power_mat.norm);
        power_max_dof(file_index) = mean(power_mat.max);
        power_noise_dof(file_index) = mean(power_mat.noise);
    else
        power_pd_dof(file_index) = 0;
        power_norm_dof(file_index) = 1;
        power_max_dof(file_index) = 1;
        power_noise_dof(file_index) = 0;
    end

end

%% Single-carrier signal files
file_offset = file_num + file_offset;
for file_index = 1: file_num
	
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);
    
    if power_mat.pkt_num > 0
        power_pd_sc(file_index) = mean(power_mat.pd); 
        power_norm_sc(file_index) = mean(power_mat.norm);
        power_max_sc(file_index) = mean(power_mat.max);
        power_noise_sc(file_index) = mean(power_mat.noise);
    else
        power_pd_sc(file_index) = 0;
        power_norm_sc(file_index) = 1;
        power_max_sc(file_index) = 1;
        power_noise_sc(file_index) = 0;
    end
    
end

figure; hold on;
cdfplot(sort((power_pd_dof - power_noise_dof) ./ power_norm_dof));
cdfplot(sort((power_pd_sc - power_noise_sc) ./ power_norm_sc));

figure;
plot([length(power_pd_dof(power_pd_dof >0)) / file_num; length(power_pd_sc(power_pd_sc >0)) / file_num]);