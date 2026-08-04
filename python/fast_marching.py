import numpy as np

def fast_marching(speed, start_points, W = None):
    """
    Perform the Fast Marching Method to compute the arrival time of a front propagating through a
    medium with a given speed function.
    
    Parameters:
    speed : ndarray
        A 2D array representing the speed function of the medium.
    start_points : list of tuples
        A list of (x, y, time) tuples representing the initial points and their arrival times.
    W : ndarray, optional
        A 2D array representing the weight function of the medium. If None, it defaults to ones.

    Returns:
    T : ndarray
        A 2D array representing the arrival time of the front at each point.
    """

    T = np.ones_like(speed) * np.inf
    accepted = np.zeros_like(speed, dtype=bool)
    considered = np.zeros_like(speed, dtype=bool)

    neighbours = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    h = [1.0, 1.0, 1.0, 1.0]

    if W is None:
        W = np.ones_like(speed)

    for start_point in start_points:
        T[start_point[0], start_point[1]] = start_point[2]
        accepted[start_point[0], start_point[1]] = True

        for i, (dx, dy) in enumerate(neighbours):
            x = int(start_point[0])
            y = int(start_point[1])
            new_x = x + dx
            new_y = y + dy
            if 0 <= new_x < speed.shape[0] and 0 <= new_y < speed.shape[1]:
                if not accepted[new_x, new_y]:
                    considered[new_x, new_y] = True
                    s = h[i] * W[new_x, new_y] / speed[new_x, new_y]
                    T_candidate = calculate_T(T, new_x, new_y, s)
                    if T_candidate < T[new_x, new_y]:
                        T[new_x, new_y] = T_candidate

    all_reached = False
    while not all_reached:
        if np.all(accepted):
            all_reached = True
            break

        considered_times = np.ones_like(T) * np.inf
        considered_times[considered] = T[considered]

        min_time = np.min(considered_times)

        if min_time == np.inf:
            all_reached = True
            break
        else:
            min_index = np.unravel_index(np.argmin(considered_times), considered_times.shape)
            accepted[min_index] = True
            considered[min_index] = False

            for i, (dx, dy) in enumerate(neighbours):
                x = int(min_index[0])
                y = int(min_index[1])
                new_x = x + dx
                new_y = y + dy
                if 0 <= new_x < speed.shape[0] and 0 <= new_y < speed.shape[1]:
                    if not accepted[new_x, new_y]:
                        considered[new_x, new_y] = True
                        s = h[i] * W[new_x, new_y] / speed[new_x, new_y]
                        T_candidate = calculate_T(T, new_x, new_y, s)
                        if T_candidate < T[new_x, new_y]:
                            T[new_x, new_y] = T_candidate

    return T

def calculate_T(T,i,j,s):
    nx = T.shape[0]
    ny = T.shape[1]

    if i == 0:
        a = T[i+1,j]
    elif i == nx-1:
        a = T[i-1,j]
    else:
        a = min(T[i-1,j], T[i+1,j])

    if j == 0:
        b = T[i,j+1]
    elif j == ny-1:
        b = T[i,j-1]
    else:
        b = min(T[i,j-1], T[i,j+1])

    if abs(a-b) >= s:
        T_candidate = min(a,b) + s
    else:
        T_candidate = 0.5 * (a + b + np.sqrt(np.maximum(0, 2*s**2 - (a-b)**2)));

    return T_candidate