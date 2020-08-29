function addInputsSet(Num,parents_path)
    if Num>0
        addInputs = [];
        for n = 1:Num
            addInputs = [addInputs,'+'];
        end
        set_param([parents_path, '/', 'Add'],'Inputs',addInputs);
    else
    end
end
