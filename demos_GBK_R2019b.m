%% 读取Excel数据，将表格数据转换成字符串数据存入
clear;
clc;
importExcelStringArray = importfile2cellarray("工作簿1.xlsx", "Sheet1", [1, 49]);
% 获取数组大小
se = size(importExcelStringArray);
% 根据excel格式，指定提取表格10行及以中的前5列数据，分别为“系统”、“子系统”、“设备”、“数量”、“电压”
architectStringArray=importExcelStringArray(10:se(1),1:5);
sa = size(architectStringArray);

%
stageNum = (se(2) - 5)/2;
% 提取阶段时长数据
for n = 1 : stageNum
    stageTime(n) = str2double(importExcelStringArray(8,6+(n-1)*2));
end


% 同一类设备数量
instrumentNum = 1;
% 同一“子系统”中的包含的设备数量累计
instrumentNumInOneSubsystem = [];
%% 载入Bus定义
load('interfaceBusDefine.mat');
ID = 0;
%% 新建simulink空模型，扫描architectStringArray，并创建系统、子系统、设备等模块，连接各级模型间信号线
% 连接“系统”中的Add模块输入与“系统”中各“子系统”的输出，Add模块输入端口个数由“子系统”个数决定
% 连接“子系统”中的Add模块输入与“子系统”中各“设备”的输出，Add模块输入端口个数由“设备”个数决定
ID = ID + 1;
mdlName = ['temp',char(string(ID))];
try 
    open_system(mdlName);
    delete_block([mdlName,'/plant']);
    delete_block([mdlName,'/Scenario']);
catch
    new_system(mdlName);
    open_system(mdlName);
end

% 设置simulink模型环境参数为：定步长求解器 ，采样周期 1ms ，仿真时长 30s
sampleTime = 0.001;
stopTime =  sum(stageTime);
set_param(mdlName,'SolverType','Fixed-step','FixedStep',char(string(sampleTime)),'StopTime',char(string(stopTime)));

% 模型尺寸定义
heights=100;
widths=120;

% 模块句柄
H1=[]; % 系统模块句柄
H2=[]; % 子系统模块句柄
H3=[]; % 设备模块句柄

% 模块数量
    % 系统种类数量
    systemHNum=0;
    % 子系统种类数量
    subsystemHNum=0;
    % 设备种类数量
    instrumentsHNum=0;

% 模块路径

versions = '_R2019b';
%versions = '_R2020a';
simulink_block_ScenarioEditor = 'simulink/Sources/Signal Editor';
mylib_block_Plant = ['myLib',versions,'/plant'];
mylib_block_Sys = ['myLib',versions,'/系统'];
mylib_block_Subsys= ['myLib',versions,'/子系统'];
mylib_block_Instrument = ['myLib',versions,'/设备'];
mylib_block_V28_path = ['myLib',versions,'/V28'];
mylib_block_V115_path = ['myLib',versions,'/V115'];
mylib_block_V270_path = ['myLib',versions,'/V270'];
mylib_block_Vothers_path = ['myLib',versions,'/Vothers'];


%添加plant
ScenarioName = [mdlName,'/Scenario'];
add_block(simulink_block_ScenarioEditor,ScenarioName,'Position',[200,50,200+heights,50+widths]);
set_param(ScenarioName,'Filename','ScenarioData.mat','SampleTime',char(string(sampleTime)),'OutputAfterFinalValue','Holding final value');
plantName = [mdlName,'/plant'];
add_block(mylib_block_Plant,plantName,'Position',[600,50,600+heights,50+widths]);
% 获取“plant”中的输入端口位置
pPlant(1) = get_param([plantName,'/externalInterface'],'PortConnectivity');
pPlant(2) = get_param([plantName,'/scenarioInterface'],'PortConnectivity');
pPlant(3) = get_param([plantName,'/selector'],'PortConnectivity');
% 对architectStringArray进行逐行扫描
for n = 1:sa(1)
    if(architectStringArray(n,1)~="") % 扫描“系统”
        systemHNum=systemHNum+1; % “系统”种类数量统计
        subsystemHNum=1;
        instrumentsHNum=1;
        
        % 指定“系统”名
        systemName=string([mdlName,'/plant','/'])+ architectStringArray(n,1);
        % 添加“系统”模块
        H1(systemHNum) = add_block(mylib_block_Sys,char(systemName),'Position',[200,50+(systemHNum-1)*200,200+heights,50+widths+(systemHNum-1)*200]);
        % 获取“plant”中的“系统”输入与输出端口位置
        pSys = get_param(char(systemName),'PortConnectivity');
        % 连接“系统”中的输入端口到“系统”中的“子系统”输入端口
        add_line(plantName,[pPlant(1).Position;pSys(1).Position]);
        add_line(plantName,[pPlant(2).Position;pSys(2).Position]);
        add_line(plantName,[pPlant(3).Position;pSys(3).Position]);
        % 设置“plant”中的Add模块输入个数为systemHNum
        addInputsSet(systemHNum,plantName);
        % 获取“plant”中的Add的输入与输出端口位置
        pAdd = get_param(char(plantName + "/Add"),'PortConnectivity');
        % 连接“palnt”中的“系统”的输出端口与“plant”中的Add输入端口systemHNum
        add_line(plantName,[pSys(4).Position;pAdd(systemHNum).Position]);
           
        
        
        % 获取“系统”中的输入端口位置
        pSys(1) = get_param(char(systemName+"/externalInterface"),'PortConnectivity');
        pSys(2) = get_param(char(systemName+"/scenarioInterface"),'PortConnectivity');
        pSys(3) = get_param(char(systemName+"/selector"),'PortConnectivity');
        
        % 指定“系统”中的“子系统”名
        subsystemName = systemName + "/" + architectStringArray(n,2);
        % 添加“系统”中的“子系统”模块
        H2(systemHNum,subsystemHNum) = add_block(mylib_block_Subsys,char(subsystemName),'Position',[150,-15,250+heights,-15+widths]);
        % 获取“系统”中的“子系统”输入与输出端口位置
        pSubsys = get_param(char(subsystemName),'PortConnectivity');
        % 连接“系统”中的输入端口到“系统”中的“子系统”输入端口
        add_line(char(systemName),[pSys(1).Position;pSubsys(1).Position]);
        add_line(char(systemName),[pSys(2).Position;pSubsys(2).Position]);
        add_line(char(systemName),[pSys(3).Position;pSubsys(3).Position]);
        % 设置“系统”中的Add模块输入个数为systemHNum
        %addInputsSet(systemHNum,char(systemName));
        % 获取“系统”中的Add的输入与输出端口位置
        pAdd = get_param(char(systemName + "/Add"),'PortConnectivity');
        % 连接“系统”中的“子系统”的输出端口与“系统”中的Add输入端口subsystemHNum
        add_line(char(systemName),[pSubsys(4).Position;pAdd(subsystemHNum).Position]);
        
        % 获取“系统”中的“子系统”中的输入与输出端口位置
        pSubsys(1) = get_param(char(subsystemName+"/externalInterface"),'PortConnectivity');
        pSubsys(2) = get_param(char(subsystemName+"/scenarioInterface"),'PortConnectivity');
        pSubsys(3) = get_param(char(subsystemName+"/selector"),'PortConnectivity');
        pSubsys(4) = get_param(char(subsystemName+"/wattBus"),'PortConnectivity');
        % 获取同一类设备数量
        instrumentNum = str2double(architectStringArray(n,4));
        % 设置“系统”中的“子系统”中的Add模块输入个数为subsystemHNum*instrumentNum
        addInputsSet(subsystemHNum*instrumentNum,char(subsystemName));
        for m = 1:instrumentNum
            % 指定“系统”中的“子系统”中的“设备”名
            instrumentsName(m) = subsystemName + "/" + architectStringArray(n,3) + "_" + string(m);
            % 添加“系统”中的“子系统”中的“设备”模块
            H3(systemHNum,subsystemHNum,instrumentsHNum,m) = add_block(mylib_block_Instrument,char(instrumentsName(m)),'Position',[-150,50+ 200*(m-1),-50+heights,50+widths+ 200*(m-1)]);
            % 获取“系统”中的“子系统”中的“设备”的输入与输出端口位置
            pInstrument = get_param(char(instrumentsName(m)),'PortConnectivity');
            % 连接“系统”中的“子系统”中的输入端口与“系统”中“子系统”中的“设备”输入端口
            add_line(char(subsystemName),[pSubsys(1).Position;pInstrument(1).Position]);
            add_line(char(subsystemName),[pSubsys(2).Position;pInstrument(2).Position]);
            add_line(char(subsystemName),[pSubsys(3).Position;pInstrument(3).Position]);
            
            % 获取“系统”中的“子系统”中的Add的输入与输出端口位置
            pAdd = get_param(char(subsystemName + "/Add"),'PortConnectivity');
            % 连接“系统”中的“子系统”中的“设备”的输出端口与“系统”中“子系统”中的Add输入端口m
            add_line(char(subsystemName),[pInstrument(4).Position;pAdd(m).Position]); 
        end
        instrumentNumInOneSubsystem(subsystemHNum) = instrumentsHNum*instrumentNum;
    else
        if(architectStringArray(n,2)~="")
            subsystemHNum = subsystemHNum + 1;
            instrumentsHNum=1;
            % 指定“系统”中的“子系统”名称
            subsystemName = systemName + "/" + architectStringArray(n,2);
            % 添加“系统”中的“子系统”模块
            H2(systemHNum,subsystemHNum) = add_block(mylib_block_Subsys,char(subsystemName),'Position',[150,-20+(subsystemHNum-1)*200,250+heights,-20+widths+(subsystemHNum-1)*200]);
            % 获取“系统”中的输入输出端口位置
            pSys(1) = get_param(char(systemName+"/externalInterface"),'PortConnectivity');
            pSys(2) = get_param(char(systemName+"/scenarioInterface"),'PortConnectivity');
            % 获取“系统”中的“子系统”的输入输出的端口位置
            pSubsys = get_param(char(subsystemName),'PortConnectivity');
            % 连接“系统”中的输入到“系统”中的“子系统”的对应输入端口
            add_line(char(systemName),[pSys(1).Position;pSubsys(1).Position]);
            add_line(char(systemName),[pSys(2).Position;pSubsys(2).Position]);
            add_line(char(systemName),[pSys(3).Position;pSubsys(3).Position]);
            % 设置“系统”中的Add模块输入个数为subsystemHNum
            addInputsSet(subsystemHNum,char(systemName));
            % 获取“系统”中的Add的输入与输出端口位置
            pAdd = get_param(char(systemName + "/Add"),'PortConnectivity');
            % 连接“系统”中的“子系统”的输出端口与“系统”中的Add输入端口subsystemHNum
            add_line(char(systemName),[pSubsys(4).Position;pAdd(subsystemHNum).Position]);            
            
            % 获取“系统”中的“子系统”中的输入、输出端口位置
            pSubsys(1) = get_param(char(subsystemName+"/externalInterface"),'PortConnectivity');
            pSubsys(2) = get_param(char(subsystemName+"/scenarioInterface"),'PortConnectivity');
            pSubsys(3) = get_param(char(subsystemName+"/selector"),'PortConnectivity');
            pSubsys(4) = get_param(char(subsystemName+"/wattBus"),'PortConnectivity');
            % 获取同一类设备数量
            instrumentNum = str2double(architectStringArray(n,4));
            % 设置“系统”中的“子系统”中的Add模块输入个数为instrumentsHNum*instrumentNum
            addInputsSet(instrumentsHNum*instrumentNum,char(subsystemName));
            for m = 1 : instrumentNum
                % 指定“系统”中的“子系统”中的“设备”名称
                instrumentsName(m) = subsystemName + "/" + architectStringArray(n,3) + "_" + string(m);
                % 添加“系统”中的“子系统”中的“设备”模块
                H3(systemHNum,subsystemHNum,instrumentsHNum,m) = add_block(mylib_block_Instrument,char(instrumentsName(m)),'Position',[-150,50+200*(m-1),-50+heights,50+widths+200*(m-1)]);
                % 获取“系统”中的“子系统”中的“设备”的输入输出端口位置
                pInstrument = get_param(char(instrumentsName(m)),'PortConnectivity');
                % 连接“系统”中的“子系统”中的输入端口到“系统”中的“子系统”中的“设备”响应输入端口
                add_line(char(subsystemName),[pSubsys(1).Position;pInstrument(1).Position]);
                add_line(char(subsystemName),[pSubsys(2).Position;pInstrument(2).Position]);
                add_line(char(subsystemName),[pSubsys(3).Position;pInstrument(3).Position]);
                
                % 获取“系统”中的“子系统”中的Add的输入与输出端口位置
                pAdd = get_param(char(subsystemName + "/Add"),'PortConnectivity');
                % 连接“系统”中的“子系统”中的“设备”的输出端口与“系统”中“子系统”中的Add输入端口instrumentNum
                add_line(char(subsystemName),[pInstrument(4).Position;pAdd(m).Position]);
            end
            instrumentNumInOneSubsystem(subsystemHNum) = instrumentsHNum*instrumentNum;
        else
            if(architectStringArray(n,3)~="")
                % 累计“系统”中的“子系统”中的“设备”的数量
                instrumentsHNum = instrumentsHNum + 1;
                
                pSubsys(1) = get_param(char(subsystemName+"/externalInterface"),'PortConnectivity');
                pSubsys(2) = get_param(char(subsystemName+"/scenarioInterface"),'PortConnectivity');
                pSubsys(3) = get_param(char(subsystemName+"/selector"),'PortConnectivity');
                pSubsys(4) = get_param(char(subsystemName+"/wattBus"),'PortConnectivity');
                % 获取同一类“设备”数量
                instrumentNum = str2double(architectStringArray(n,4));
                % 保存先前同一“子系统”中的所有“设备”的数量
                preInstrumentNumInOneSubsystem(subsystemHNum) = instrumentNumInOneSubsystem(subsystemHNum);
                % 计算当前同一“子系统”中的所有“设备”的数量
                instrumentNumInOneSubsystem(subsystemHNum) = instrumentNumInOneSubsystem(subsystemHNum) + instrumentNum;
                % 设置“系统”中的“子系统”中的Add模块输入个数为当前“设备”的数量instrumentNumInOneSubsystem(subsystemHNum)
                addInputsSet(instrumentNumInOneSubsystem(subsystemHNum),char(subsystemName));
                
                for m = 1 : instrumentNum
                    instrumentsName(m) = subsystemName + "/" + architectStringArray(n,3) + "_" + string(m);
                    H3(systemHNum,subsystemHNum,instrumentsHNum,m) = add_block(mylib_block_Instrument,char(instrumentsName(m)),'Position',[-150,50+(preInstrumentNumInOneSubsystem(subsystemHNum)+m-1)*200,-50+heights,50+widths+(preInstrumentNumInOneSubsystem(subsystemHNum)+m-1)*200]);

                    pInstrument = get_param(char(instrumentsName(m)),'PortConnectivity');
                    add_line(char(subsystemName),[pSubsys(1).Position;pInstrument(1).Position]);
                    add_line(char(subsystemName),[pSubsys(2).Position;pInstrument(2).Position]);
                    add_line(char(subsystemName),[pSubsys(3).Position;pInstrument(3).Position]);

                    % 获取“系统”中的“子系统”中的Add的输入与输出端口位置
                    pAdd = get_param(char(subsystemName + "/Add"),'PortConnectivity');
                    % 连接“系统”中的“子系统”中的“设备”的输出端口与“系统”中“子系统”中的Add输入端口instrumentNum
                    add_line(char(subsystemName),[pInstrument(4).Position;pAdd(preInstrumentNumInOneSubsystem(subsystemHNum)+m).Position]);
                end
            else
            end
        end
    end
end
%%
% 根据excel格式，提取表格数据
dataArray = importExcelStringArray(9:se(1),:);
dataArray1 = importExcelStringArray(9:se(1),3:se(2));
sd = size(dataArray);
sd1 = size(dataArray1);
dataArray1WithSingleTime=dataArray1(2:sd1(1),4:sd1(2));
sda1wst = size(dataArray1WithSingleTime);
for n = 1:sda1wst(1)
    % 使用“阶段”持续时间更新dataArray1WithSingleTime中的“C”
    for m = 1:sda1wst(2)/2
        if (dataArray1WithSingleTime(n,2+(m-1)*2)=="C")
            dataArray1WithSingleTime(n,2+(m-1)*2) = string(stageTime(m));
        end
    end
    % 提取模态数据和阶段单次时间
    for n = 1:sda1wst(1)
        for m = 1:sda1wst(2)/2
            modalData(n,m) = dataArray1WithSingleTime(n,1+2*(m-1));
            sigleTime(n,m) = dataArray1WithSingleTime(n,2*m);
        end
    end
    % modalValue：模态数值
    % modalNum：模态数量
    [modalValue,modalNum] = capModals(modalData);
end
% 模态选择信号 modalSelector
modalSelectorTemp = str2double(dataArray1WithSingleTime(:,1:2:(sda1wst(2)-1)));
for n = 1:sda1wst(1)
    for m = 1:sda1wst(2)/2
        for t = 1:length(modalValue(n,:))
            if(modalSelectorTemp(n,m) == modalValue(n,t))
                modalSelector(n,m) = t;
            end
        end
    end
end
% 模态选择信号生成
modalSelectorSig=[];%zeros(1,sum(stageTime)/sampleTime);

for n = 1:size(modalSelector,1)
    for m = 1:size(modalSelector,2)
        modalSelectorSigTemp(m,:) = modalSelector(n,m)*ones(1,stageTime(m)/sampleTime);
    end
    temp=[];
    for m = 1:size(modalSelector,2)
        temp=[temp,modalSelectorSigTemp(m,:)];
    end
    modalSelectorSig(n,:)=temp;
end
% 单次持续时间(单位：s) timeLast
timeLast = str2double(dataArray1WithSingleTime(:,2:2:sda1wst(2)));
% 单次执行时间在阶段起始时的偏移量(单位：s) timeOffSet
for n = 1:sda1wst(1)
    for m = 1:sda1wst(2)/2
        if(stageTime(m) == timeLast(n,m))
            timeOffSet(n,m) = 0;
        else
            timeOffSet(n,m) = (stageTime(m) - timeLast(n,m))/2;
        end
    end
end
%% wave波形构造
waveData=[];
% 阶段时长最长
stageTimeMax = max(stageTime);
% 计算最大波形数组长度
stepsMax = stageTimeMax / sampleTime;
waveData(1,:) = ones(1,stepsMax);
% 触发时刻
stageMoment = zeros(1,length(stageTime));
for n = 1:length(stageTime)-1
    stageMoment(n+1) = stageMoment(n) + stageTime(n);
end
triggerMoment = timeOffSet + stageMoment;
for j = 1:size(timeOffSet,1)
    for n = 1:sum(stageTime)/sampleTime
        for m = 1:length(stageTime)
            if((triggerMoment(j,m)/sampleTime) == (n-1))
                triggerSig(j,n) = 1;break;
            else
                triggerSig(j,n) = 0;
            end
        end
    end
end
figure
plot(0:0.001:60-0.001,triggerSig);
% 结构元素数量统计
systemsNum=0;
subsystemsNum=0;
instrumentsNum=0;
for n=1:sa(1)
    if(architectStringArray(n,1)~="")
        systemsNum=systemsNum+1;
    end
    if(architectStringArray(n,2)~="")
        subsystemsNum = subsystemsNum+1;
    end
    if(architectStringArray(n,3)~="")
        instrumentsNum = instrumentsNum + 1;
    end
end
%% 
addArray=importExcelStringArray(10:se(1),3:5);
triggerSigAddArray = [addArray,triggerSig];
modalSelectorSigAddArray = [addArray,modalSelectorSig];
%% 触发信号
% 统计设备种类：riggerSigcomponentID
% 整理扩充触发信号矩阵：triggerSiginstrumentsArray
% 统计各类设备数量：triggerSiginstrumentNumCap
% 汇总各类设备的种类、数量等信息：triggerSiginstrumentArray1
[triggerSigcomponentID,triggerSiginstrumentsArray,triggerSiginstrumentNumCap,triggerSiginstrumentArray1] = expandingArray(triggerSigAddArray);
% 创建标准化初始剧本矩阵
triggerSigStandInitArray = newStandInitArray(triggerSiginstrumentsArray);
% 
triggerSigStandArray = GenStandArray(triggerSiginstrumentsArray,triggerSigStandInitArray);
triggerSigStandData = str2double(triggerSigStandArray(:,4:size(triggerSigStandArray,2)));
%% 模态选择信号
[modalSelectorSigcomponentID,modalSelectorSiginstrumentsArray,modalSelectorSiginstrumentNumCap,modalSelectorSiginstrumentArray1] = expandingArray(modalSelectorSigAddArray);
modalSelectorSigStandInitArray = newStandInitArray(modalSelectorSiginstrumentsArray);
modalSelectorSigStandArray = GenStandArray(modalSelectorSiginstrumentsArray,modalSelectorSigStandInitArray);
modalSelectorSigStandData = str2double(modalSelectorSigStandArray(:,4:size(modalSelectorSigStandArray,2)));
%% 剧本数据生成
for n = 1:triggerSigcomponentID
    scenarioData(n,:,:)=[modalSelectorSigStandData(((n-1)*5+1):(5*n),:);triggerSigStandData(((n-1)*5+1):(5*n),:)];
end
timeStep = [0:sampleTime:(stopTime-sampleTime)];
reshape(scenarioData(1,:,:), 10, stopTime/sampleTime);
%% 剧本生成
Scenario = Simulink.SimulationData.Dataset;
element = Simulink.SimulationData.Signal;
instrumentName = char(triggerSiginstrumentArray1(:,1));
instrumentSubName = instrumentName(:,3:size(instrumentName,2));
for n =1:triggerSigcomponentID
    elementName = ['instrument_',instrumentSubName(n,:)];
    element.Name = elementName;
    element.Values=timeseries(reshape(scenarioData(n,:,:), 10, stopTime/sampleTime),timeStep);
    Scenario=Scenario.addElement(element);
end
%Scenario=Scenario.setElement(4,element,'Signal4');