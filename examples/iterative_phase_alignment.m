%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Iterative phase alignment
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function bf_weight = iterative_phase_alignment(H, Ntx, Nloop, OPT_TYPE)

% Params
phase_now = zeros(Ntx, 1);           % The updated phase
phase_opt = zeros(Ntx, 1);           % The optimal phase
power_opt = 0;

power_now_mat = zeros(Nloop, 1);

rx_power_max = sum(abs(H), 2).^2;

% Iteration loop
for ite_index = 1: Nloop
    % Generate the phase
    phase_delta = 2 * pi / 20 * rand(Ntx, 1);
    phase_now = phase_now + phase_delta;
    bf_weight = exp(1j * phase_now);
    
    % Power comparison (max-min optimization)
    rx_power = abs(H * bf_weight).^2;
    relative_power = rx_power ./ rx_power_max;
    
    if OPT_TYPE == "maxmin"
        power_now = min(relative_power);
    elseif OPT_TYPE == "sum"
        power_now = sum(relative_power);
    else
        error("OTP_TYPE must be maxmin or sum");
    end
        
    power_now_mat(ite_index) = power_now;

    if power_now > power_opt
        power_opt = power_now;
        phase_opt = phase_now;
    else
        phase_now = phase_opt;
    end
end
bf_weight = exp(1j * phase_opt);
