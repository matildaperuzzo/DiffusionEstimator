# bottlenecks

An estimator that determines geographical influence on large-scale diffusion processes.

# Model
A diffusion process implemented in src/run_model. It consists of a Monte Carlo simulation of a diffusive process where the speed of diffusion is spatially dependent. The process is then averaged over many runs.
The result of the diffusive process is the matrix A of dimensions size_x X size_y X n. time steps. Each entry gives the probability of the diffusion having reached point x,y at time t.
For each individual run an error is obtained by calculating MSE with respect to the original dataset.
run_model.m returns a result object which contains errors and the matrix A for the run.

# Estimator
The estimator process can be found in tests/fit_model.
It includes the choice of dataset and layers. Data is not found on the public repository due to size constraints.
The estimator conducts an initial wide sweep of parameters to determine the area of lowest error. Next, a gradient descent optimizer finds the optimal set of parameters theta.
Finally a bootstraps method is used to obtain errors on the theta estimates.