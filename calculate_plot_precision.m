function [] = calculate_plot_precision(Ns, Mtype, SimulParam1 , SimulParam2)


    % SimulParam1 is across all ns subjects, but seems to auto take first since we have one anyway


    x1 = SimulParam1.x ; % should be PP
    x2 = SimulParam2.x ; % should be UP
    pred_precision_values_PP = exp(x1(5, :)) ; % take predictive precision
    % alpha_PP = exp(x1(7, :)) ;
    % beta_PP = exp(x1(8, :)) ;

    pred_precision_values_UP = exp(x2(5, :)) ;
    % alpha_UP = exp(x2(7, :)) ;
    % beta_UP = exp(x2(8, :)) ;


    posterior_precision_values_PP = exp(x1(2, :)) ;
    posterior_precision_values_UP = exp(x2(2, :)) ;



    % figure ;
    % h = histogram(post_precision_values_PP , 15);  %
    % h.FaceColor = [0.2 0.6 0.8];  % Set bar color
    % title(['Predictive precision values histogram with model ' Mtype ' and ' num2str(Ns) ' subjects for case PP' ]);    %% plotting histograms

    figure;
    plot(pred_precision_values_PP, 'LineWidth',0.8)
    xlabel('Trials')
    ylabel('Predictive Precision')
    title(['Predictive precision values across time, Model:' Mtype ' and ' num2str(Ns) ' subjects, case:{PP}' ]);

    % px as (alpha_pX - 1) / beta_pX;
    % figure;
    % plot((alpha_PP) ./ (beta_PP + eps), 'LineWidth',0.8)
    % % plot(beta_PP ./ ((alpha_PP - 1) + eps) , 'Linewidth' , 0.8) ;
    % xlabel('Trials')
    % ylabel('pX from alpha/beta')
    % title(['Precision on prior across time, Model:' Mtype ' and ' num2str(Ns) ' subjects, case:{PP}' ]);

    % figure;
    % plot(alpha_PP, 'LineWidth',0.8)
    % xlabel('Time')
    % ylabel('alpha')
    % title(['Precision on prior across time, Model:' Mtype ' and ' num2str(Ns) ' subjects, case:{PP}' ]);

    % figure;
    % plot(beta_PP, 'LineWidth',0.8)
    % xlabel('Time')
    % ylabel('beta')
    % title(['Precision on prior across time, Model:' Mtype ' and ' num2str(Ns) ' subjects, case:{PP}' ]);



    % figure ;
    % h = histogram(post_precision_values_UP , 15);  %
    % h.FaceColor = [0.2 0.6 0.8];  % Set bar color
    % title(['Predictive precision values histogram with model ' Mtype  ' and ' num2str(Ns) ' subjects for case UP' ]);    %% plotting histograms


    figure;
    plot(pred_precision_values_UP, 'LineWidth',0.8)
    xlabel('Trials')
    ylabel('Predictive Precision')
    title(['Predictive precision values across time, Model:' Mtype ' and ' num2str(Ns) ' subjects, case:{UP}' ]);


    compPlot = figure('Name', 'PP/UP precision');
    ax1 = axes('Parent', compPlot);
    plot(ax1, pred_precision_values_PP, 'Color', 'blue');
    hold(ax1, 'on');
    plot(pred_precision_values_UP, 'Color', 'red');
    hold(ax1, 'off');
    title(ax1, 'PP vs UP predictive precision');
    legend('PP', 'UP');

    compPlot = figure('Name', 'PP/UP posterior');
    ax1 = axes('Parent', compPlot);
    plot(ax1, posterior_precision_values_PP, 'Color', 'blue');
    hold(ax1, 'on');
    plot(posterior_precision_values_UP, 'Color', 'red');
    hold(ax1, 'off');
    title(ax1, 'PP vs UP posterior precision');
    legend('PP', 'UP');

    % % px as (alpha_pX - 1) / beta_pX;
    % figure;
    % % current_pX = alpha_pX / (beta_pX + eps) ;
    % plot((alpha_UP ) ./ (beta_UP +eps), 'LineWidth',0.8)
    % xlabel('Trials')
    % ylabel('pX from alpha/beta')
    % title(['Precision on prior across time, Model:' Mtype ' and ' num2str(Ns) ' subjects, case:{UP}' ]);


    % figure;
    % plot(alpha_UP, 'LineWidth',0.8)
    % xlabel('Time')
    % ylabel('alpha')
    % title(['Precision on prior across time, Model:' Mtype ' and ' num2str(Ns) ' subjects, case:{UP}' ]);


    % figure;
    % plot(beta_UP, 'LineWidth',0.8)
    % xlabel('Time')
    % ylabel('beta')
    % title(['Precision on prior across time, Model:' Mtype ' and ' num2str(Ns) ' subjects, case:{UP}' ]);




    % figure ;
    % h_rt = histogram(alpha_phase_values_UP{1});  %
    % h_rt.FaceColor = [0.2 0.6 0.8];  % Set bar color
    % title(['Alpha phase histogram with model ' Mtype ' and ' num2str(Ns) ' subjects for case UP' ]);



end