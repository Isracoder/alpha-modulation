function [gx] = g_Audio_Resp(x,P,u,inG)


% added by me
gx = zeros(2, 1) ; % the choice and reaction time

% trying to specify to speed up computations specify dgdx and dgdP should
% be here



PhiOpt = inG.PhiOpt;  % how to check that phase aligns with stimulus timing ?


% states
mu    = x(3) ;  %  mean for hidden state of ISI prediction
Ppost = exp(x(5));  % predictive precision, sigma^2 , optimal case assumes same as posterior
Tref  = x(6);  % elapsed time
% fprintf('mu= %.4d Ppost= %.d, Tref= %.4f ()\n', mu, Ppost, Tref); % average vals seem to be 4-7e2, 4, 365-380

% parameters
A0  = exp(P(1)); % amplitude
f   = exp(P(2)); % frequency
sig = exp(P(3)); % noise / covariance ?
gam = exp(P(4)); % decision threshold
t0  = exp(P(5)); % initial non-decision time ?

% input , experiment params
Uv  = u(1);  % whether or not it's a visual trial
Ua  = u(2);  % whether it's an auditory std/dev
isi = u(3);  % the isi

% entropy of the predictive density
S = 0.5*log(2*pi*exp(1)/Ppost);  % entropy of gaussian

% phase resetting
Phi = PhiOpt - 2*pi*f*(Tref+mu);
phase_term = sin(2*pi*f*(Tref+isi)+Phi);

% Compute drift rate with stimulus-driven baseline
% Phase modulates sensitivity (multiplicative effect)
phase_sensitivity = 0 + 0.2 * (1 + phase_term);  % Range: [0, 1] , phase term always seems to be 0, leading this to be 1 since initially 0.5 for both terms

if Uv

    if Ua == 1  % Deviant
        nu = (A0/S) * (0.0 + phase_sensitivity);  % Range: [1, 2] * A0/S
        % initially had this as a/s * 1 + ps, reason of change was that
        % a/s * phase_term gave 0 which lead to chance accuracy
        % nu = 1 ; % this drives accuracy, having value >= 1 for example gives 100%, while 0.5 already gives 91%
    else  % Standard
        nu = -(A0/S) * (0.0 + 0.2 * phase_sensitivity);  % Asymmetric - standards less affected
        % nu = -1 ;
    end

    % fprintf('(A/S)term= %.4d phase sensitivity= %.d, nu= %.4f ()\n', (A0/S), phase_sensitivity, nu);

    % Reaction time
    dt = 1e-2; % time step , 0.01
    N = 1e3;   % #Monte-Carlo simulations, 1000


    choices = zeros(N, 1);
    RTs = zeros(N, 1);

    for i=1:N
        z = 0;
        t = 1;
        while true
            z(t+1) = z(t) + nu*dt + sig*sqrt(dt)*randn;
            t = t + 1;

            if z(t) >= gam
                choices(i) = 0;
                RTs(i) = t0 + t*dt;
                break;
            elseif z(t) <= -gam
                choices(i) = 1;
                RTs(i) = t0 + t*dt;
                break;
            end
        end
    end

    % Aggregate: Probability of choosing 0 vs 1
    p_choice_0 = mean(choices == 0);

    % Probabilistic choice
    % gx(1) = (rand < p_choice_0);  % Bernoulli sample


    gx(1) = (p_choice_0 > 0.5);  % Majority vote

    gx(2) = mean(RTs);  % average RT, verify if ms or s

    gx(3) = (A0 / S)  ;% amp
    gx(4) = phase_sensitivity ;


elseif Uv == 0
    % case when I don't have to respond
    gx(1) = -1 ;
    gx(2) = -1 ;
    gx(3) = (A0 / S)  ;% amp
    gx(4) = phase_sensitivity ;
    % gx(3) = x(3) ; % for now crude assumption that it's the same but this should change
    % gx(4) = x(4) ;
    % changed both of these from -1 to evade p [0,1] problem for bernoulli distribution,
    % then kept it as -1 but added max to change p to 0 in vba


end

