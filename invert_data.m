function [posterior , out] = invert_data(Y, U)


switch nargin
    case 0
        fprintf('no inputs provided, generating simulated behavior')
        [Y , U, Mtype, SimulParams] = simul_data(3, 1, 1, 0) ;
    case 2
        fprintf('using provided behavior')
    otherwise
        error('*** wrong num of args')

end


%% Inversion

% select data
y_test = Y{1} ;

% y_test(y_test == -1) = NaN;  % VBA can handle NaN as missing data , to get rid of -1 binary problem
%option 2 for binary -1 problem is instructing on skipping those trials
nt = (size(Y{1}, 2)) ;
disp(nt) ;
options.isYout = zeros(2, nt);  % Which observations to include
no_go_trial_indices = find((Y{1}(1,:) ~= 1));
options.isYout(:, no_go_trial_indices) = 1;  % disregard non go trials

% currently only over first participant
theta = SimulParams(1).theta ;
phi = SimulParams(1).phi ;
x0 = SimulParams(1).x0 ;

% set up dims
dim.n_theta =length(theta) ;
dim.n_phi =length(phi);
dim.n = 6 ; % num hidden states, from x

% setup the priors, can be informed or uninformed (such as the zeros array)
%    estimated params
% priors.muTheta = zeros(dim.n_theta, 1) ;  % should I use theta or Ptheta ?
priors.muTheta = theta ;
priors.SigmaTheta = 0.1 * eye(dim.n_theta);  % 0.1 for some variance
%   estimated observation params
% priors.muPhi  = zeros(dim.n_phi, 1) ; % same question

priors.muPhi = phi;
priors.SigmaPhi = 0.1 * eye(dim.n_phi);



priors.muX0 = x0 ;
priors.SigmaX0 = 0.1 * eye(dim.n);

priors.a_alpha = 1e8; % Very high nearly deterministic to match inf passed in during simulation
priors.b_alpha = 1;

priors.a_sigma = 1e8;
priors.b_sigma = 1;

options.priors = priors ;
% for options lets keep the same ones as the simulation
options.sources(1).out = 1 ;
options.sources(1).type = 1 ;
options.sources(2).out = 2 ;
options.sources(2).type = 0 ;
options.inG.PhiOpt = 0 ;

invert_gname = @g_invert;
f_name = @f_Audio_H1; % can later have this based on m type

% invert model
[posterior , out] = VBA_NLStateSpaceModel(y_test, U , f_name, invert_gname, dim, options) ;


% evaluate
displayResults(posterior, out, y_test)
% can also pass these in to above function x,x0,theta,phi,alpha,sigma










% print stats
% Compare true vs estimated parameters
fprintf('\n=== PARAMETER RECOVERY ===\n');
fprintf('True theta: %.3f\n', Ptheta);
fprintf('Estimated theta: %.3f\n', posterior.muTheta);
fprintf('True phi: %.3f %.3f %.3f %.3f %.3f\n', Pphi);
fprintf('Estimated phi: %.3f %.3f %.3f %.3f %.3f\n', posterior.muPhi);

% Plot belief trajectory
figure;
subplot(2,1,1);
plot(posterior.muX(1,:));
title('Estimated ISI Beliefs Over Time');
ylabel('Predicted ISI (ms)');

subplot(2,1,2);
plot(exp(posterior.muX(5,:)));
title('Estimated Precision Over Time');
ylabel('Precision');
xlabel('Trial');


