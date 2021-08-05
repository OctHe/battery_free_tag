%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Tag dumux: It divides the signal from 2 tags into 2 groups. Each group
% includes the power and channel for each tag
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tag_1_index, tag_2_index, corr_res] = tag_demux_2tags(ch_mat, pkt_num, corr_thr)

corr_res = zeros(pkt_num, 1);
for pkt_index = 1: pkt_num
    corr_res(pkt_index) = abs(ch_mat(1, :) * ch_mat(pkt_index, :)') / ...
        (norm(ch_mat(1, :)) * norm(ch_mat(pkt_index, :)));
end

tag_1_index = find(corr_res >= corr_thr);
tag_2_index = find(corr_res < corr_thr);