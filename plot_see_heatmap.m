function plot_see_heatmap(z_fixed)
% PLOT_SEE_HEATMAP  Visualize SEE as UAV moves in X-Y plane at altitude z_fixed

rng(42,'twister');  % deterministic results

x_vals = 0:10:100;   % UAV X coordinates (tune range & step)
y_vals = 0:10:100;   % UAV Y coordinates
SEE_map = zeros(length(y_vals), length(x_vals));

fprintf('Computing SEE over grid...\n');
for ix = 1:length(x_vals)
    for iy = 1:length(y_vals)
        x = x_vals(ix);
        y = y_vals(iy);
        SEE_map(iy, ix) = calculate_reward_3d(x, y, z_fixed);
    end
end

% ---- PLOT ----
figure;
imagesc(x_vals, y_vals, SEE_map);
set(gca,'YDir','normal');
colorbar;
title(sprintf('Secrecy Energy Efficiency (SEE) vs UAV position (z=%.1f m)', z_fixed));
xlabel('UAV X-coordinate (m)');
ylabel('UAV Y-coordinate (m)');
colormap jet;

% annotate RIS, user, eavesdropper positions for context
hold on;
plot(50, 50, 'ws', 'MarkerFaceColor','w','MarkerSize',8); % RIS
plot(47, 47, 'wo', 'MarkerFaceColor','g','MarkerSize',8); % User
plot(100, 100, 'wo', 'MarkerFaceColor','r','MarkerSize',8); % Eavesdropper
legend({'RIS','User','Eavesdropper'}, 'TextColor','w', 'Location','southoutside');
hold off;
end
