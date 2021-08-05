%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Plot the packet and the received power for multiple tags
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

%% File options
samp_rate = 1e6;

thr = 1e-7;

%% File
file_name = "debug_tag_reflection.bin";

fid = fopen(file_name, 'r');
raw = fread(fid, 'float32');
fclose(fid);
raw = reshape(raw, 2, []).';
read_signal = raw(:, 1) + 1j * raw(:, 2);

%% Baseline
power = abs(read_signal) .^ 2;
power = smoothdata(power, 'movmean', 640);

pkt = 0;
for index = 2: length(power)
    if(power(index) >= thr && power(index -1) < thr)
        pkt = pkt + 1;
        timestamp(pkt) = index / samp_rate;
    end
end
timestamp

%% Funtion
[timestamp, pkt_num] = tag_reflection_timestamp(file_name, samp_rate, 1e-7);
timestamp

%% Figure
figure; hold on;
plot((1: length(read_signal)) / samp_rate, real(read_signal));
plot((1: length(read_signal)) / samp_rate, imag(read_signal));

figure;
plot((1: length(read_signal)) / samp_rate, power);


