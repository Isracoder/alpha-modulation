function [] = calculate_plot_precision(Ns, Mtype, SimulParam1 , SimulParam2)

% Extract go trials (where visual input = 1)


% post_precision_values_PP = cellfun(@(x) x(ind,:), Y1, 'UniformOutput', false);
x1 = SimulParam1.x ;
x2 = SimulParam2.x ;
post_precision_values_PP = exp(x1(2, :)) ;

post_precision_values_UP = exp(x2(2, :)) ;


figure ;
h = histogram(post_precision_values_PP , 15);  %
h.FaceColor = [0.2 0.6 0.8];  % Set bar color
title(['Posterior precision values histogram with model ' Mtype ' and ' num2str(Ns) ' subjects for case PP' ]);    %% plotting histograms

% figure ;
% h_rt = histogram(alpha_phase_values_PP{1});  %
% h_rt.FaceColor = [0.2 0.6 0.8];  % Set bar color
% title(['Alpha phase histogram with model ' Mtype ' and ' num2str(Ns) ' subjects for case PP' ]);

figure ;
h = histogram(post_precision_values_UP , 15);  %
h.FaceColor = [0.2 0.6 0.8];  % Set bar color
title(['Posterior precision values histogram with model ' Mtype  ' and ' num2str(Ns) ' subjects for case UP' ]);    %% plotting histograms

% figure ;
% h_rt = histogram(alpha_phase_values_UP{1});  %
% h_rt.FaceColor = [0.2 0.6 0.8];  % Set bar color
% title(['Alpha phase histogram with model ' Mtype ' and ' num2str(Ns) ' subjects for case UP' ]);



end