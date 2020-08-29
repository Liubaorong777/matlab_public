function [triggerValue,triggerTime] = genTrigger(stageTime,modalData,sigleTime,sampleTime)
%genTrigger 此处显示有关此函数的摘要
%   stageTime：阶段时长
%   modalData：“设备”在某一“电压”下的模态数据
%   sigleTime：“设备”在某一“电压”下的模态单次持续时间
%   sampleTime：系统采样时间
%   triggerValue：触发信号数值
%   triggerTime：触发信号变化的时刻

for n = 1:length(stageTime)
    if (stageTime())
    else
    end
end
triggerValue = stageTime;
triggerTime = modalData;
end

