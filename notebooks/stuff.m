errors = zeros(length(pinhasi_active),1);
for d = 1:length(pinhasi_active)
    errors(d) = calculate_error(A,pinhasi_active(d,:,:));
end

figure
histogram(errors*dt,10)
% Label the axes
xlabel('Error (years)');
ylabel('Frequency');

% Add a title to the histogram
title('Histogram of Errors');

% Optionally, you can add grid lines for better readability
grid on;

%%
