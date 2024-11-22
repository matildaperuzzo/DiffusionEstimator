function [model_percentage, data_percentage] = get_percentages(parameters, A)
    [~,~,nt] = size(A);
    data_percentage = zeros(nt,1);
    model_percentage = zeros(nt,1);
    for i=1:nt
        t_ind = parameters.dataset_idx(:,3)<=i;
        data_percentage(i) = sum(t_ind)/length(parameters.dataset_idx);
        x_ind = parameters.dataset_idx(:,1);
        y_ind = parameters.dataset_idx(:,2);
        values = A(sub2ind(size(A), x_ind, y_ind, i*ones(length(x_ind),1)));
        model_percentage(i) = sum(values)/length(parameters.dataset_idx);
    end

end