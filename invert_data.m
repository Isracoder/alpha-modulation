function [posterior , out] = invert_data(Y, U, SimulParams, options, Mtype, gname, Pobs)


    switch nargin
        case 0
            fprintf('no inputs provided, generating simulated behavior')
            error('*** implementation not updated')
            % [Y , U, Mtype, SimulParams] = simul_data(3, 1, 1, 0) ;
        case {4, 5, 6, 7}
            fprintf('using provided behavior')
        otherwise
            error('*** wrong num of args')

    end


    %% Inversion and model comparison

    Nmcmc = 1 ;
    num_sub = 1 ;

    % later should have flag for each model type that also sets gaussian sources, options
    % obs_models = {@observation.neural.g_null @observation.neural.g_amp_precision @observation.neural.g_phase_precision @observation.neural.g_amp_phase_pe} ; % these are the neural data observation models, map mu and precision to neural outcomes such as amp phase
    obs_models = {@observation.choice.g_Audio_Resp @observation.choice.g_choice2} ; % and these are the behavioral observation models , map mu and precision to behavioral outcomes such as choice and rt
    gaussian_sources = find([options.sources.type]==0);
    % disp("Gaussian sources: ")
    % disp(gaussian_sources) ; % here this shows [1 2] as those are my gaussians
    nm = length(obs_models);
    disp(["num of models: " nm]) ;
    p = cell(nm,nm,Nmcmc);
    log_likelihood = cell(length(gaussian_sources), nm, num_sub) ; % for each gaussian for each model store the log-likelihood for each subj
    o = cell(nm,nm,Nmcmc);
    % F = zeros(nm,nm,Nmcmc);
    F = zeros(nm,num_sub);
    for s =1:num_sub


        for j=1:nm

            % select data
            y_test = Y{1} ;

            % y_test(y_test == -1) = NaN;  % VBA can handle NaN as missing data , to get rid of -1 binary problem in the case of returning choice from g function
            %option 2 for binary -1 problem is instructing on skipping those trials
            nt = (size(Y{1}, 2)) ; % number of trials
            options.isYout = zeros(2, nt);  % Which observations to include
            no_go_trial_indices = find((Y{1}(1,:) ~= 1));
            options.isYout(:, no_go_trial_indices) = 1;  % disregard non go trials

            % currently only over first participant
            theta = SimulParams(1).theta ;
            phi = SimulParams(1).phi ;

            % phi = cell2mat(Pobs(j)); % use phi params for each g function, in the case of using the neural models since each has diff params

            x0 = SimulParams(1).x0 ;
            x = SimulParams(1).x ;
            alpha = SimulParams(1).alpha ;
            sigma = SimulParams(1).sigma ;


            % set up dims
            dim.n = 6 ; % num hidden states, from x
            dim.n_phi =length(phi);
            dim.n_theta =length(theta) ;

            % setup the priors, can be informed or uninformed (such as the zeros array)
            % estimated evolution params
            priors.muTheta = zeros(dim.n_theta, 1) ;  % should I use theta to inform prior ?
            priors.SigmaTheta = 0.1 * eye(dim.n_theta);  % 0.1 for some variance

            % estimated observation params
            priors.muPhi  = zeros(dim.n_phi, 1) ; % same question
            priors.SigmaPhi = 0.1 * eye(dim.n_phi);
            % priors.muPhi = testPhi;

            priors.muX0 = x0 ;
            priors.SigmaX0 = 0.1 * eye(dim.n);

            priors.a_sigma = [1e8 1e8] ; % Very high nearly deterministic to match inf passed in during simulation
            priors.b_sigma = [1 1];

            options.priors = priors ;

            % invert_gname = gname


            invert_gname = obs_models{j} ;
            f_name = @learning.f_Audio_H1; % can later have this based on m type

            % invert model
            % [posterior , out] = VBA_NLStateSpaceModel(y_test, U , f_name, invert_gname, dim, options) ;

            [p{1,j,s},o{1,j,s}] = VBA_NLStateSpaceModel(y_test,U, f_name ,invert_gname, dim, options);
            % F(1,j,1) = o{1,j,1}.F; % free energy

            F(j, s) = o{1, j, s}.F ;
            disp(['The free energy for model ' j ' is: ' num2str(F(j,s))]) ;

            disp(['The ' j ' model fit log likelihood'])
            disp(o{1,j,s}.fit.LL) ;
            for k = 1:length(gaussian_sources)
                % source_index = gaussian_sources(k) % for example I may have 1 gaussian but it's index is 3 (the third source)
                % log_likelihood(k, j,1) = o{1,j,1}.fit.LL(k) ;
                log_likelihood{k, j,s} = o{1,j,s}.fit.LL(k) ;
            end
            % evaluate
            displayResults(p{1,j,s}, o{1,j,s}, y_test, x, x0, theta, phi, alpha, sigma) ;
            % can also pass these in to above function x,x0,theta,phi,alpha,sigma

        end

    end
    % hf = figure('color',[1 1 1]);
    % ha = axes('parent',hf);
    % dF = F(:,1,:) - F(:,2,:);
    % mdF = mean(dF,3);
    % vdF = var(dF,[],3)./Nmcmc;
    % plotUncertainTimeSeries(mdF,vdF,[],ha);
    % set(ha,'xlim',[0,3],'xtick',[1,2],'xticklabels',models)
    % xlabel(ha,'type of simulated data')
    % ylabel(ha,['log p(y|', func2str(models{1}),') - log p(y|' , func2str(models{2}),')'])
    % box(ha,'off')


    %% comparison from demo comparison
    % perform model selection with the VBA
    % =========================================================================
    options.verbose = false;
    % options.DisplayWin = false ;

    % [p, o] = VBA_groupBMC(F, options);
    [p, o] = VBA_groupBMC(log_likelihood{1}, options); % for first gaussian source

    % Display results
    fprintf('Protected exceedance probabilities:\n');
    disp(o.pxp);
    fprintf('Expected frequencies:\n');
    disp(o.Ef);


    % perform group-BMS on data generated under the full model
    % [p1, o1] = VBA_groupBMC (log_likelihood(1,1), options); % for the first gaussian and first model
    % set (o1.options.handles.hf, 'name', 'group BMS: y_1')
    % % VBA_random
    % fprintf('Statistics in favor of the true model (m1): pxp = %04.3f (Ef = %04.3f)\n', o1.pxp(1), o1.Ef(1));

    % % perform group-BMS on data generated under the nested model
    % [p2, o2] = VBA_groupBMC (log_likelihood(1,2), options); % for the first gaussian and second model
    % set (o2.options.handles.hf, 'name', 'group BMS: y_2')

    % fprintf('Statistics in favor of the true model (m2): pxp = %04.3f (Ef = %04.3f)\n', o2.pxp(2), o2.Ef(2));

    % classical hypothesis testing
    % =========================================================================
    % for the sake of the example, perform same analysis using an F-test

    % check if X1 better than X2 on y1
    % c = [zeros(2); eye(2)];
    % [pv,stat,df] = GLM_contrast (X1, y1, c, 'F', true);
    % set(gcf,'name','classical analysis of y1')

    % fprintf('Statistics in favor of the full model (m1): p = %04.3f (F = %04.3f)\n', pv, stat, df(1), df(2));

    % % check if X1 better than X2 on y2
    % [pv,stat,df] = GLM_contrast (X1, y2, c, 'F', true);
    % set(gcf,'name','classical analysis of y2')

    % fprintf('Statistics in favor of the full model (m1): p = %04.3f (F = %04.3f)\n', pv, stat, df(1), df(2));
    % note that an absence of significance does not mean significant absence!






    % print stats
    % Compare true vs estimated parameters
    % fprintf('\n=== PARAMETER RECOVERY ===\n');
    % % fprintf('True theta: %.3f\n', Ptheta);
    % fprintf('True theta: %.3f\n', SimulParams.theta);
    % fprintf('Estimated theta: %.3f\n', posterior.muTheta);
    % % fprintf('True phi: %.3f %.3f %.3f %.3f %.3f\n', Pphi);
    % fprintf('True phi: %.3f %.3f %.3f %.3f %.3f\n', SimulParams.phi);
    % fprintf('Estimated phi: %.3f %.3f %.3f %.3f %.3f\n', posterior.muPhi);

    % % Plot belief trajectory
    % figure;
    % subplot(2,1,1);
    % plot(posterior.muX(1,:));
    % title('Estimated ISI Beliefs Over Time');
    % ylabel('Predicted ISI (ms)');

    % subplot(2,1,2);
    % plot(exp(posterior.muX(5,:)));
    % title('Estimated Precision Over Time');
    % ylabel('Precision');
    % xlabel('Trial');


    %% Dummy inversion

    % specify Yout to ignore no-go trials
    % dummy VB inversion (with ideal priors) of volatile learner
    % d00 = struct('n',2*5,'n_theta',3,'n_phi',2);
    % priors = [];
    % priors.muPhi = SimulParam(1).phi    ; % initially give them dummy whatever
    % priors.muTheta = SimulParam(1).theta;
    % priors.muX0 = x0;
    % priors.SigmaPhi = 0*eye(d00.n_phi);
    % priors.SigmaTheta = 0*eye(d00.n_theta);
    % priors.SigmaX0 = 0*eye(d00.n);
    % priors.a_alpha = Inf;
    % priors.b_alpha = 0;
    % opt00 = options;
    % opt00.priors = priors;
    % [p00,o00] = VBA_NLStateSpaceModel(y,u,@f_OpLearn,@g_VBvolatile0,d00,opt00);  % how to make sure in inversion that there is no loop


