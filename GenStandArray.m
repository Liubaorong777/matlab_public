%% outputStandArray = GenStandArray(instrumentsArray,outputStandInitArray);
% 输入标准化的初始矩阵：outputStandInitArray，输入提取后的结构矩阵：instrumentsArray，
% 输出标准化数组数据：outputStandArray
function [outputStandArray] = GenStandArray(inputArray,standArray)
%inputArray=instrumentsArray;
%standArray = outputArray1;
% 
outputStandArray = standArray;
for n = 1:size(inputArray,1)
    for m = 1:size(inputArray,2)
        switch inputArray(n,m,3)
            case "28V_1"
                outputStandArray(5*(n-1)+1,4:size(outputStandArray,2)) = inputArray(n,m,4:size(inputArray,3));
            case "28V_2"
                outputStandArray(5*(n-1)+2,4:size(outputStandArray,2)) = inputArray(n,m,4:size(inputArray,3));
            case "115V_1"
                outputStandArray(5*(n-1)+3,4:size(outputStandArray,2)) = inputArray(n,m,4:size(inputArray,3));
            case "270V_1"
                outputStandArray(5*(n-1)+4,4:size(outputStandArray,2)) = inputArray(n,m,4:size(inputArray,3));
            case "Vothers"
                outputStandArray(5*(n-1)+5,4:size(outputStandArray,2)) = inputArray(n,m,4:size(inputArray,3));
            otherwise
        end
    end
end
end

