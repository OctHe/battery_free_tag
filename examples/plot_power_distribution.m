%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the power distribution that received by the receiver
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% File options
file_options.fft_size = 16;
file_options.tx = 4;
file_options.sym_sync = 8;
file_options.sym_pd = 188;

fft_size = file_options.fft_size;
sym_sync = file_options.sym_sync;
tx = file_options.tx;
sym_pd = file_options.sym_pd;

ignore_pkt = 10;    % Ignore the *ignore_pkt* packets at the file begin
                    % The packets at the file begin may not correct
                    % because the USRP hardware
                        
%% File path
file_dir = "./power_distri_200cmx200cm/";
files = dir(file_dir);

%% DOF signal files
file_offset = 3;
file_num = 16;
for file_index = 1: file_num
    
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);

    power_pd_mat = power_mat.pd(ignore_pkt +1: end);
    power_norm_mat = power_mat.norm(ignore_pkt +1: end);
    power_max_mat = power_mat.max(ignore_pkt +1: end);
    power_noise_mat = power_mat.noise(ignore_pkt +1: end);

    power_pd_dof(file_index) = mean(power_pd_mat); 
    power_norm_dof(file_index) = mean(power_norm_mat);
    power_max_dof(file_index) = mean(power_max_mat);
    power_noise_dof(file_index) = mean(power_noise_mat);


end

%% Single-carrier signal files
file_offset = file_num + file_offset;
for file_index = 1: file_num
	
    file_name = files(file_index + file_offset).name;
    [power_mat, ch_mat] = pkt_demux(file_dir + file_name, file_options);


    power_pd_mat = power_mat.pd(ignore_pkt +1: end);
    power_norm_mat = power_mat.norm(ignore_pkt +1: end);
    power_max_mat = power_mat.max(ignore_pkt +1: end);
    power_noise_mat = power_mat.noise(ignore_pkt +1: end);

    power_pd_sc(file_index) = mean(power_pd_mat); 
    power_norm_sc(file_index) = mean(power_norm_mat);
    power_max_sc(file_index) = mean(power_max_mat);
    power_noise_sc(file_index) = mean(power_noise_mat);
        


end

figure; hold on;
cdfplot(sort((power_pd_dof - power_noise_dof) ./ power_norm_dof));
cdfplot(sort((power_pd_sc - power_noise_sc) ./ power_norm_sc));