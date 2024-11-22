load("pinhasi_dataset_theta_0_2_detail.mat")
% load("pinhasi_sweep_with_exit_flags.mat")
[min_error, min_error_idx] = min(all_errors(:));
[idx_0, idx_1, idx_2] = ind2sub(size(all_errors), min_error_idx);

figure(1)
plot(theta_2(2:end),squeeze(all_errors(idx_0,1,2:end)),'LineWidth',1,'Color',[30/255, 51/255, 110/255])
xlabel('theta_2')
ylabel('Error')

figure(2)
plot(theta_0(2:end),squeeze(all_errors(2:end,1,idx_2)),'LineWidth',1,'Color',[110/255, 20/255, 30/255])
xlabel('theta_0')
ylabel('Error')