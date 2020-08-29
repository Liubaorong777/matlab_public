function [outModalVal,outModalNum] = capModals(inputModalData)
%capModals 此处显示有关此函数的摘要
%   根据输入的模态数据，分析得到，模态属性
% inputModalData = modalData;
    outModalVal = zeros(size(inputModalData));
    simd = size(inputModalData);
    for n = 1: simd(1)
        uimd = unique(inputModalData(n,:));
        for m = 1:length(uimd)
            outModalVal(n,m) = str2double(uimd(m));
        end
        outModalNum(n) = length(uimd);
    end    
    outModalVal = outModalVal';
    outModalVal(all(outModalVal==0,2),:)=[];
    outModalVal = outModalVal';
end

