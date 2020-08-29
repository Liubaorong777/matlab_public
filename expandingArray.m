%% [componentID,instrumentsArray,instrumentNumCap,instrumentArray1] = expandingArray(triggerSigAddArray);
function [componentID,instrumentsArray,instrumentNumCap,instrumentArray1] = expandingArray(inputArray)
%expandingArray 此处显示有关此函数的摘要
%   此处显示详细说明
%inputArray=triggerSigAddArray;
componentID = 0;
instrumentNumCap=[];
zerosVector = zeros(1,size(inputArray,2)-3);% 零数据
emptyVector = ["","","",zerosVector];       % 空数据
for n = 1 : size(inputArray,1)
    if(inputArray(n,1)~="")             % 若设备名称行不为空，则增加一个新设备
        componentID = componentID+1;    % 记录增加一个新设备
        index0 = 1;
        instrumentNumCap(componentID) = str2double(inputArray(n,2));    % 使用componentID记录设备数量
        instrumentsArray(componentID,index0,:)=inputArray(n,:);   % 提取新设备第一行数据
    else
        index0=index0+1;                                        % 下一行
        instrumentsArray(componentID,index0,:)=inputArray(n,:);   % 提取新设备下一行数据
    end
end
% 扩充inputArray为“设备种类” X 5 X ：，
if(size(instrumentsArray,2)<5)
    for n = 1:size(instrumentsArray,1)
        instrumentsArray(n,5,:)=emptyVector;
    end
end
% 替换所有内容missing的行，为“空数据”行
for n =1:size(instrumentsArray,1)
    for m =1:size(instrumentsArray,2)
        if(ismissing(instrumentsArray(n,m,1)))
            instrumentsArray(n,m,:)=emptyVector;
        end
    end
end
% 
for n =1:size(instrumentsArray,1)
    instrumentArrayTemp=instrumentsArray(n,1,:);
    instrumentArray1(n,:)=instrumentArrayTemp(:)';
    instrumentArrayTemp=instrumentsArray(n,2,:);
    instrumentArray2(n,:)=instrumentArrayTemp(:)';
    instrumentArrayTemp=instrumentsArray(n,3,:);
    instrumentArray3(n,:)=instrumentArrayTemp(:)';
    instrumentArrayTemp=instrumentsArray(n,4,:);
    instrumentArray4(n,:)=instrumentArrayTemp(:)';
    instrumentArrayTemp=instrumentsArray(n,5,:);
    instrumentArray5(n,:)=instrumentArrayTemp(:)';
end
end
