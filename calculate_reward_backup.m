function calculate_reward_debug(u_x,u_y,u_z)
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

% initialize w greedy
w = (randn(params.M,1) + 1i*randn(params.M,1));
w = w / norm(w) * sqrt(params.P_t_max);

% greedy theta to favor user
g = channels.H_sr * w;              % N x 1
a_u_ris = conj(channels.H_ru) .* g; % N x 1
theta_phases = -angle(a_u_ris);
ris_amp = sqrt(params.P_r_max / params.N);
Theta_diag = ris_amp .* exp(1i*theta_phases);

% compute components
Theta = diag(Theta_diag);
eff_user = channels.h_su + channels.H_sr' * Theta.' * channels.H_ru;
eff_eave = channels.h_se_est + channels.H_sr' * Theta.' * channels.H_re_est;

user_ris_term = channels.H_sr' * Theta.' * channels.H_ru;
eave_ris_term = channels.H_sr' * Theta.' * channels.H_re_est;

fprintf('\n--- COMPONENTS ---\n');
fprintf('|h_su| = %.3e, |h_se| = %.3e\n', norm(channels.h_su), norm(channels.h_se_est));
fprintf('||H_sr||_F = %.3e, ||H_ru|| = %.3e, ||H_re|| = %.3e\n', norm(channels.H_sr,'fro'), norm(channels.H_ru), norm(channels.H_re_est));

fprintf('\nUser direct projection: |h_su^H w| = %.3e\n', abs(channels.h_su' * w));
fprintf('User RIS projection (per-element, abs):\n');
disp(abs(conj(channels.H_ru).* (channels.H_sr * w)));

fprintf('Sum magnitude of RIS contribution to user: |(H_sr'' Theta'' H_ru)^H w| = %.3e\n', abs(user_ris_term' * w));
fprintf('User effective |eff_user^H w| = %.3e\n', abs(eff_user' * w));

fprintf('\nEve direct projection: |h_se^H w| = %.3e\n', abs(channels.h_se_est' * w));
fprintf('Eve RIS projection (per-element, abs):\n');
disp(abs(conj(channels.H_re_est).* (channels.H_sr * w)));

fprintf('Sum magnitude of RIS contribution to eve: |(H_sr'' Theta'' H_re)^H w| = %.3e\n', abs(eave_ris_term' * w));
fprintf('Eve effective |eff_eave^H w| = %.3e\n', abs(eff_eave' * w));

% robust error term and signals
error_term = params.epsilon_se * norm(w) + params.epsilon_re * norm(Theta * channels.H_sr * w);
signal_user = abs(eff_user' * w)^2;
signal_eave_worst = (abs(eff_eave' * w) + error_term)^2;

rate_user = log2(1 + max(signal_user,0)/max(params.noise_power,eps) + params.log_eps);
rate_eave = log2(1 + max(signal_eave_worst,0)/max(params.noise_power,eps) + params.log_eps);
sr = max(0, real(rate_user - rate_eave));
power = real(norm(w)^2 + sum(abs(Theta_diag).^2)) + params.P_circuit;
see = sr / max(power, params.power_floor);

fprintf('\n--- SIGNALS & RATES ---\n');
fprintf('error_term = %.3e\n', error_term);
fprintf('signal_user = %.3e, signal_eave_worst = %.3e\n', signal_user, signal_eave_worst);
fprintf('rate_user = %.6f, rate_eave_worst = %.6f, sr = %.6f\n', rate_user, rate_eave, sr);
fprintf('power = %.3e, see = %.3e\n', power, see);
end

%% Include the channel helper (copy from your main file)
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
