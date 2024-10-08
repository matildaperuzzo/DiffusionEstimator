figure
hold on
load("no_rand.mat","all_errors")
histogram(all_errors(:),'BinEdges',linspace(0,5,50))
load("20_rand.mat","all_errors")
histogram(all_errors(:),'BinEdges',linspace(0,5,50))
load("50_rand.mat","all_errors")
histogram(all_errors(:),'BinEdges',linspace(0,5,50))
load("80_rand.mat","all_errors")
histogram(all_errors(:),'BinEdges',linspace(0,5,50))
xlabel("absolute mean error")
ylabel("frequency")

legend('0%','20%','50%','80%')