function [] = calculate_plot_neural(Ns, Mtype, Gt,  U1, Y1, U2, Y2)

% Extract go trials (where visual input = 1)
disp(size(Y1))
disp(size(Y1{1}))
disp(size(Y1{1}, 1))
if (size(Y1{1}, 1) == 2) % check rows to get correct ind for amp/phase
    ind = 1  ; % [amp phase]
else
    ind = 3 ; % [c rt amp phase]
end
disp(["ind is : "  ind])
% alpha_amp_values_PP = cell2mat(cellfun(@(x) x(ind,:), Y1, 'UniformOutput', true));   % getting the all col values for the second row for each cell
alpha_amp_values_PP = cellfun(@(x) x(ind,:), Y1, 'UniformOutput', false);
% assuming Y is structured [amp phase] ind is 1
% later on Y may be structured [c rt amp phase], in that case take third ind
% here we want the amp for all subjs across all trials (go/no-go)
alpha_phase_values_PP = cellfun(@(x) x(ind + 1,:), Y1, 'UniformOutput', false);

alpha_amp_values_UP = cellfun(@(x) x(ind,:), Y2, 'UniformOutput', false);
alpha_phase_values_UP = cellfun(@(x) x(ind + 1,:), Y2, 'UniformOutput', false);

disp(size(alpha_amp_values_PP{1})) ;
figure ;
h = histogram(alpha_amp_values_PP{1} , 15);  %
h.FaceColor = [0.2 0.6 0.8];  % Set bar color
title(['Alpha amplitude histogram with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP' ]);    %% plotting histograms

figure ;
h_rt = histogram(alpha_phase_values_PP{1});  %
h_rt.FaceColor = [0.2 0.6 0.8];  % Set bar color
title(['Alpha phase histogram with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP' ]);

% disp("size of values compared: ")
% disp(size(alpha_phase_values_PP))
% disp(size(alpha_amp_values_PP))
figure;
hold on;

% Plot the main trajectory line
plot(alpha_phase_values_PP{1}, alpha_amp_values_PP{1}, 'b-', 'LineWidth', 1.5);

% Add distinctive markers for start and end points
plot(alpha_phase_values_PP{1}(1), alpha_amp_values_PP{1}(1), 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'LineWidth', 2);
plot(alpha_phase_values_PP{1}(end), alpha_amp_values_PP{1}(end), 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'LineWidth', 2);

% Add labels for start and end points
text(alpha_phase_values_PP{1}(1), alpha_amp_values_PP{1}(1), 'Start', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontSize', 10, 'FontWeight', 'bold');
text(alpha_phase_values_PP{1}(end), alpha_amp_values_PP{1}(end), 'End', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'FontSize', 10, 'FontWeight', 'bold');

% Compute differences (direction vectors)
dx = diff(alpha_phase_values_PP{1});
dy = diff(alpha_amp_values_PP{1});

% Select every 5th data point for arrows
arrow_indices = 1:5:length(alpha_phase_values_PP{1})-1;

% Add arrows at selected points
quiver(alpha_phase_values_PP{1}(arrow_indices), ...
    alpha_amp_values_PP{1}(arrow_indices), ...
    dx(arrow_indices), dy(arrow_indices), ...
    0.3, 'Color', 'r', 'LineWidth', 0.8, 'MaxHeadSize', 0.9);

% Add legend
legend('Trajectory', 'Start', 'End', 'Location', 'best');

% Set axis properties
axis equal;
xlabel('Phase');
ylabel('Amplitude');
title(['Amplitude/Phase relationship with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case PP']);

hold off;


figure ;
h = histogram(alpha_amp_values_UP{1} , 15);  %
h.FaceColor = [0.2 0.6 0.8];  % Set bar color
title(['Alpha amplitude histogram with model ' Mtype ' /G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP' ]);    %% plotting histograms

figure ;
h_rt = histogram(alpha_phase_values_UP{1});  %
h_rt.FaceColor = [0.2 0.6 0.8];  % Set bar color
title(['Alpha phase histogram with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP' ]);

figure;
plot(alpha_phase_values_UP{1}, alpha_amp_values_UP{1}, 'b-', 'LineWidth', 1.5);
hold on ;
% Compute differences (direction vectors)
dx = diff(alpha_phase_values_UP{1});
dy = diff(alpha_amp_values_UP{1});

% Add arrows at each segment using quiver
quiver(alpha_phase_values_UP{1}(1:end-1), alpha_amp_values_UP{1}(1:end-1), ...
    dx, dy, 0.3, 'Color', 'r', 'LineWidth', 0.8, 'MaxHeadSize', 0.9);
axis equal;
title(['Amplitude/Phase relationship with model ' Mtype '/G' num2str(Gt) ' and ' num2str(Ns) ' subjects for case UP']);
xlabel('Phase');
ylabel('Amplitude');
hold off;

% Add directional arrows
% n_arrows = 15; % Number of arrows to display (adjust as needed)
% step_size = floor(length(alpha_phase_values_UP{1})/n_arrows);
% indices = 1:step_size:length(alpha_phase_values_UP{1})-1;

% % Calculate arrow displacements
% dx = alpha_phase_values_UP{1}(indices+1) - alpha_phase_values_UP{1}(indices);
% dy = alpha_amp_values_UP{1}(indices+1) - alpha_amp_values_UP{1}(indices);

% % Plot arrows
% quiver(alpha_phase_values_UP{1}(indices), alpha_amp_values_UP{1}(indices), ...
%     dx, dy, 'k', 'filled', 'MaxHeadSize', 0.3, 'LineWidth', 1.2 , 'Color', [0 0 0 0.5]);

% % Add grid for better readability
% grid on;


end