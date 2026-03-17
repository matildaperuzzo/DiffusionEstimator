Requested combinations imply 4 scripts, not 6:

- `cobo` with `{'av'}`
- `cobo` with `{'av','sea'}`
- `maize` with `{'av'}`
- `maize` with `{'av','sea'}`

Approximate wall-clock durations assuming:

- one `run_model` call takes about 3 seconds
- MATLAB parallel execution is available for the `parfor` sections used by `sweep` and `grad_descent`
- the new `grad_descent` uses 4 starts and computes a variance ellipse before each optimization
- bootstrap count is 100

Estimated durations:

- `fit_cobo_av.m`: about 2h 37m
- `fit_cobo_av_sea.m`: about 3h 27m
- `fit_maize_av.m`: about 2h 37m
- `fit_maize_av_sea.m`: about 3h 27m

If MATLAB parallel execution is unavailable, runtimes will be substantially longer.
