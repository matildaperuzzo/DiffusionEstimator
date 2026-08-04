function prob = to_prob(p, k)
    prob = 1./(1 + exp(-k * (p - 0.5)));
end