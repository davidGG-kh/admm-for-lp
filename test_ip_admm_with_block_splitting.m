clear;clc;close all
seed = 0;

%% generate problem
m = 100;
n = 400;
prob_seed = 0;
[c, A, b, opt_val] = generate_linprog_problem(m, n , prob_seed);

%% parameters
MAX_ITER = 1e4; % max # of iterations
TOL = 1e-4;     % Tolerance
beta = 0.9;     % parameter (for augmenting lagrangian)
gamma = 0.1;
precondition = true;
verb = true; 

%% Primal IP ADMM with 1 block (no splitting)
tic
NUM_BLOCKS = 1;
rnd_permute = true; % This would have no effect anyways
[ov1,~,~,~,eh1] = lp_primal_ip_admm_with_splitting(c, A, b, MAX_ITER, TOL, beta, gamma, ...
                                    precondition, NUM_BLOCKS, rnd_permute, seed, verb);
toc
%% Primal IP ADMM with 5 blocks
tic
NUM_BLOCKS = 5;
rnd_permute = true;
[ov2,~,~,~,eh2] = lp_primal_ip_admm_with_splitting(c, A, b, MAX_ITER, TOL, beta, gamma,...
                                    precondition, NUM_BLOCKS, rnd_permute, seed, verb);
toc                             
%% Primal IP ADMM with 10 blocks
tic
NUM_BLOCKS = 10;
rnd_permute = true;
[ov3,~,~,~,eh3] = lp_primal_ip_admm_with_splitting(c, A, b, MAX_ITER, TOL, beta,gamma, ...
                                    precondition, NUM_BLOCKS, rnd_permute, seed, verb);
toc

%% Plot                        
figure(2)
semilogy(1:length(eh1),eh1, 'r')
hold on
semilogy(1:length(eh2),eh2, 'g')
semilogy(1:length(eh3),eh3, 'b')
xlabel('Iteration')
ylabel('Abs Error: ||A*x1-b||')

%% Prepare to Run Extensive Block-Splitting Experiments
clear;clc;close all

%% Parameters
m = 20;
n = 100;

MAX_ITER = 1e4; % max # of iterations
TOL = 1e-4;     % Tolerance
beta = 0.9;     % parameter (for augmenting lagrangian)
gamma = 0.1;
seed = 0; % solver seed

N = 10; % # number of problems to solve
corr_tol = 0.01; % Tolerance for correctness
num_blocks_range = [1, 5, 10, 15, 20]; % # of blocks to use for each splitting experiment
verb = false;

%% Experiment with various block sizes

for i_prob = 1:N
    prob_seed = i_prob-1;
    disp(' ')
    disp(['Problem ',num2str(i_prob)])
    [c, A, b, opt_val] = generate_linprog_problem(m,n,prob_seed);
    for i_num_blocks = 1:length(num_blocks_range)
        num_blocks = num_blocks_range(i_num_blocks);
        for rnd_perm = [true, false]  
            for precond = [true, false]
                [ov_ip,~,~,~,eh_ip] = lp_primal_ip_admm_with_splitting(c, A, b, MAX_ITER, TOL, beta, gamma, ...
                                        precond, num_blocks, rnd_perm, seed, verb);

                if abs(ov_ip - opt_val) > corr_tol
                    disp(['Block size: ',num2str(num_blocks)])
                    if precond
                        disp('Using Preconditioning')
                    end
                    disp(['Converged at:', num2str(length(eh_ip))])
                    warning('Incorrect Solution!')
                    % store the number of steps used for convergence
                    result_ip{rnd_perm+1, precond+1}(i_num_blocks, i_prob) = -1;
                else 
                    % store the number of steps used for convergence
                    result_ip{rnd_perm+1, precond+1}(i_num_blocks, i_prob) = length(eh_ip);
                end
            end    
        end
    end
end

save('test_admm_primal_ip_block_split.mat','result_ip','num_blocks_range')

%% Plot Results

figure
subplot(1,2,1)
title('Interior Point Primal')
plot_errorbar_param_conv(result_ip(:,1),num_blocks_range, ...
                {'Sequential', 'Rand Permute'}, [0,10000], '# of Blocks')

subplot(1,2,2)
title('Interior Point Primal With Preconditioning')
plot_errorbar_param_conv(result_ip(:,2),num_blocks_range, ...
                {'Sequential', 'Rand Permute'}, [0,10000], '# of Blocks')


