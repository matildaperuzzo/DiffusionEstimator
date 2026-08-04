function result = same_layers(layers1,layers2)
    result = true;
    if length(layers1) ~= length(layers2)
        result = false;
    else
        for l = 1:length(layers1)
            if ~ismember(layers1(l),layers2)
                result = false;
                break
            end
                
        end
    end