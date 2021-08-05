%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function is used to get the timestamp when the tag starts to reflect
% the incoming signal
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [timestamp, pkt_num] = tag_reflection_timestamp(file_name, samp_rate, thr)

fid = fopen(file_name, 'r');
raw = fread(fid, 'float32');
fclose(fid);
raw = reshape(raw, 2, []).';
read_signal = raw(:, 1) + 1j * raw(:, 2);

power = abs(read_signal) .^ 2;
power = smoothdata(power, 'movmean', 640);

pkt_num = 0;
timestamp = [];
for index = 2: length(power)
    if(power(index) >= thr && power(index -1) < thr)
        pkt_num = pkt_num + 1;
        timestamp(pkt_num) = index / samp_rate;
    end
end
