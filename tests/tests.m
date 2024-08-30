figure
hold on;
for e = 1:length(terrains(1,:))

    histogram(errors(e,:))
    title('Error histogram')
    xlabel('Error')
    ylabel('Frequency')
    % add legend
end

legend(num2str(terrains'))