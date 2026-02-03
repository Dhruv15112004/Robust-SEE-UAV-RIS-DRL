function see = calculate_reward_debug(u_x,u_y,u_z)
% Quick debug helper: build channels + greedy init and print all components
rng(42,'twister');

% params (match your main code)
params.M = 2; params.N = 4;
params.P_t_max = 1;
params.P_r_max = 0.5;
params.noise_power = 1e-9;
params.epsilon_se = 1e-6;
params.epsilon_re = 1e-6;
params.P_circuit = 1e-3;
params.power_floor = 1e-6;
params.log_eps = 1e-18;

% geometry
locations.ris  = [50,50,15];
locations.user = [47,47,2];
locations.eave = [100,100,1.5];
locations.uav  = [u_x,u_y,u_z];

fprintf('DEBUG RUN for UAV at (%.1f,%.1f,%.1f)\n', u_x,u_y,u_z);
channels = generate_3d_channels(params, locations);

% ... your existing debug code (w, Theta, eff_user, eff_eave, see, etc.) ...

% At the very end, make sure `see` is computed and not overwritten:
% see = sr / max(power, params.power_floor);

fprintf('\n--- SIGNALS & RATES ---\n');
fprintf('power = %.3e, see = %.3e\n', power, see);
end

% ===== helper functions in same file OR separate files =====
function [channels] = generate_3d_channels(params, locations)
    fprintf('--- Generating channel links (Rician) ---\n');
    channels.h_su = get_channel_link(locations.uav, locations.user, params.M, 1, 20);
    H_sr_MN = get_channel_link(locations.uav, locations.ris, params.M, params.N, 20);
    channels.H_sr = H_sr_MN.';  % N x M
    channels.H_ru = get_channel_link(locations.ris, locations.user, params.N, 1, 10);
    channels.h_se_est = get_channel_link(locations.uav, locations.eave, params.M, 1, 10);
    channels.H_re_est = get_channel_link(locations.ris, locations.eave, params.N, 1, 10);
end

function [H] = get_channel_link(pos1, pos2, num_ant1, num_ant2, rician_K)
    G_0 = 1; alpha = 1.2;
    d = norm(pos1 - pos2); if d < 1.0, d = 1.0; end
    gain_lin = sqrt(G_0 / (d^alpha));
    fprintf('DEBUG link: [%5.1f %5.1f %4.1f] -> [%5.1f %5.1f %4.1f], d=%.2f, gain=%.3e\n', pos1, pos2, d, gain_lin);
    H_nlos = (randn(num_ant1,num_ant2) + 1i*randn(num_ant1,num_ant2))/sqrt(2);
    H_los  = ones(num_ant1, num_ant2);
    H_rician = sqrt(rician_K/(rician_K+1)) * H_los + sqrt(1/(rician_K+1)) * H_nlos;
    H = gain_lin * H_rician;
end
