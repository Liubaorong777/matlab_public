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
catch
    new_system(mdlName);
    open_system(mdlName);
end

% 设置simulink模型环境参数为：定步长求解器 ，采样周期 1ms ，仿真时长 30s
set_param(mdlName,'SolverType','Fixed-step','FixedStep','0.001','StopTime','30');

% 模型尺寸定义
heights=100;
weights=120;

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
mylib_block_Sys = 'myLib/系统';
mylib_block_Subsys= 'myLib/子系统';
mylib_block_Instrument = 'myLib/设备';
mylib_block_V28_path = 'myLib/V28';
mylib_block_V115_path = 'myLib/V115';
mylib_block_V270_path = 'myLib/V270';
mylib_block_Vothers_path = 'myLib/Vothers';

% 对architectStringArray进行逐行扫描
for n = 1:sa(1)
    if(architectStringArray(n,1)~="") % 扫描“系统”
        systemHNum=systemHNum+1; % “系统”种类数量统计
        subsystemHNum=1;
        instrumentsHNum=1;
        
        % 指定“系统”名
        systemName=string([mdlName,'/'])+ architectStringArray(n,1);
        % 添加“系统”模块
        H1(systemHNum) = add_block(mylib_block_Sys,char(systemName),'Position',[20,50+(systemHNum-1)*200,20+heights,50+weights+(systemHNum-1)*200]);
        % 获取“系统”中的输入端口位置
        pSys(1) = get_param(char(systemName+"/externalInterface"),'PortConnectivity');
        pSys(2) = get_param(char(systemName+"/scenarioInterface"),'PortConnectivity');
        pSys(3) = get_param(char(systemName+"/selector"),'PortConnectivity');
        
        % 指定“系统”中的“子系统”名
        subsystemName = systemName + "/" + architectStringArray(n,2);
        % 添加“系统”中的“子系统”模块
        H2(systemHNum,subsystemHNum) = add_block(mylib_block_Subsys,char(subsystemName),'Position',[150,-15,250+heights,-15+weights]);
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
            H3(systemHNum,subsystemHNum,instrumentsHNum,m) = add_block(mylib_block_Instrument,char(instrumentsName(m)),'Position',[-150,50+ 200*(m-1),-50+heights,50+weights+ 200*(m-1)]);
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
            H2(systemHNum,subsystemHNum) = add_block(mylib_block_Subsys,char(subsystemName),'Position',[150,-20+(subsystemHNum-1)*200,250+heights,-20+weights+(subsystemHNum-1)*200]);
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
                H3(systemHNum,subsystemHNum,instrumentsHNum,m) = add_block(mylib_block_Instrument,char(instrumentsName(m)),'Position',[-150,50+200*(m-1),-50+heights,50+weights+200*(m-1)]);
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
                    H3(systemHNum,subsystemHNum,instrumentsHNum,m) = add_block(mylib_block_Instrument,char(instrumentsName(m)),'Position',[-150,50+(preInstrumentNumInOneSubsystem(subsystemHNum)+m-1)*200,-50+heights,50+weights+(preInstrumentNumInOneSubsystem(subsystemHNum)+m-1)*200]);

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
    [modalValue,modalNum] = capModals(modalData);
end
%%
componentID = 0;
for n = 2 : sd(1)
    if (addArray(n,3)~="") % 捕获同一类“设备”
        componentID=componentID+1;
        instrumentNumCap = str2double(addArray(n,4)); % 捕获同一类“设备”的数量
        switch addArray(n,5)
            case "28"
                
            case "115"
                statements
            case "270"
                statements
            otherwise
                statements
        end
        
    else
    end
    
end
%%
set_param([mdlName,'/系统2/externalInterface'],'position',[220,80,260,120]);
se = get_param([mdlName,'/系统2/externalInterface'],'PortConnectivity');
s1 = get_param([mdlName,'/系统2/子系统3'],'PortConnectivity');
mm=[s1(1).Position,s1(2).Position,s1(3).Position];
add_line([mdlName,'/系统2'],[se.Position;mm]);

