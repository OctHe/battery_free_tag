%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Simulation of power distribution under the distributed deployment of
% transmitters
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% System params
init_loc = -0.2;
D = 8;
Ntx = 4;

Interval = 0.1;

Ptx = 1e3;              % Transmit power of each power source(20 dBm)

fc = 915e6;

%% Channel model
loc_tx = device_deployment(init_loc, D, Ntx, "rectangle");
loc_rx = [1.1 * D; 1.1 * D];

loc_vec = Interval: Interval: D;
mat_len = length(loc_vec);

power_tag_norm = zeros(mat_len, mat_len);
power_tag_rx = zeros(mat_len, mat_len);
for x = 1: mat_len
   for y = 1: mat_len
       loc_tag = [loc_vec(x); loc_vec(y)];
       Hf = channel_model(loc_tx, loc_tag, fc);
       Hb = channel_model(loc_tag, loc_rx, fc);
       
       power_tag_norm(x, y) = (Hf * Hf');
       power_tag_rx(x, y) = sum(Hf) * sum(Hf)';
   end
end
power_tag_norm = reshape(power_tag_norm, [], 1);
power_tag_rx = reshape(power_tag_rx, [], 1);

figure; hold on;
cdfplot(power_tag_norm ./ power_tag_norm);
cdfplot(power_tag_rx ./ power_tag_norm);
