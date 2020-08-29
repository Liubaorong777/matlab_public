%% outputStandInitArray = newStandInitArray(instrumentsArray);
function [outputStandInitArray] = newStandInitArray(inputArray)
%inputArray = instrumentsArray;
zerosVector = zeros(1,size(inputArray,3)-3);% 零数据
zerosVector5 = [... % 5行零数据
    zerosVector;...
    zerosVector;...
    zerosVector;...
    zerosVector;...
    zerosVector;];
siA1=size(inputArray,1);%设备种类
outputStandInitArray=[];
temp=[["设备1" "1" "28V_1"];...% 设备级数组标准初始化结构
    ["" "" "28V_2"];...
    ["" "" "115V_1"];...
    ["" "" "270V_1"];...
    ["" "" "Vothers"];];
temp = [temp,zerosVector5]; % 设备级数组标准初始化数据
for n = 1:siA1
    temp(1) = inputArray(n,1,1);
    temp(1,2) = inputArray(n,1,2);
    outputStandInitArray = [outputStandInitArray;temp];% 系统级（即，汇总所有设备）数组标准初始化数据
end
end

