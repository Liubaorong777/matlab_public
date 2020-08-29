%% ��ȡExcel���ݣ����������ת�����ַ������ݴ���
clear;
clc;
importExcelStringArray = importfile2cellarray("������1.xlsx", "Sheet1", [1, 49]);
% ��ȡ�����С
se = size(importExcelStringArray);
% ����excel��ʽ��ָ����ȡ���10�м����е�ǰ5�����ݣ��ֱ�Ϊ��ϵͳ��������ϵͳ�������豸������������������ѹ��
architectStringArray=importExcelStringArray(10:se(1),1:5);
sa = size(architectStringArray);

%
stageNum = (se(2) - 5)/2;
% ��ȡ�׶�ʱ������
for n = 1 : stageNum
    stageTime(n) = str2double(importExcelStringArray(8,6+(n-1)*2));
end


% ͬһ���豸����
instrumentNum = 1;
% ͬһ����ϵͳ���еİ������豸�����ۼ�
instrumentNumInOneSubsystem = [];
%% ����Bus����
load('interfaceBusDefine.mat');
ID = 0;
%% �½�simulink��ģ�ͣ�ɨ��architectStringArray��������ϵͳ����ϵͳ���豸��ģ�飬���Ӹ���ģ�ͼ��ź���
% ���ӡ�ϵͳ���е�Addģ�������롰ϵͳ���и�����ϵͳ���������Addģ������˿ڸ����ɡ���ϵͳ����������
% ���ӡ���ϵͳ���е�Addģ�������롰��ϵͳ���и����豸���������Addģ������˿ڸ����ɡ��豸����������
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

% ����simulinkģ�ͻ�������Ϊ������������� ���������� 1ms ������ʱ�� 30s
sampleTime = 0.001;
stopTime =  sum(stageTime);
set_param(mdlName,'SolverType','Fixed-step','FixedStep',char(string(sampleTime)),'StopTime',char(string(stopTime)));

% ģ�ͳߴ綨��
heights=100;
widths=120;

% ģ����
H1=[]; % ϵͳģ����
H2=[]; % ��ϵͳģ����
H3=[]; % �豸ģ����

% ģ������
    % ϵͳ��������
    systemHNum=0;
    % ��ϵͳ��������
    subsystemHNum=0;
    % �豸��������
    instrumentsHNum=0;

% ģ��·��

versions = '_R2019b';
%versions = '_R2020a';
simulink_block_ScenarioEditor = 'simulink/Sources/Signal Editor';
mylib_block_Plant = ['myLib',versions,'/plant'];
mylib_block_Sys = ['myLib',versions,'/ϵͳ'];
mylib_block_Subsys= ['myLib',versions,'/��ϵͳ'];
mylib_block_Instrument = ['myLib',versions,'/�豸'];
mylib_block_V28_path = ['myLib',versions,'/V28'];
mylib_block_V115_path = ['myLib',versions,'/V115'];
mylib_block_V270_path = ['myLib',versions,'/V270'];
mylib_block_Vothers_path = ['myLib',versions,'/Vothers'];


%���plant
ScenarioName = [mdlName,'/Scenario'];
add_block(simulink_block_ScenarioEditor,ScenarioName,'Position',[200,50,200+heights,50+widths]);
set_param(ScenarioName,'Filename','ScenarioData.mat','SampleTime',char(string(sampleTime)),'OutputAfterFinalValue','Holding final value');
plantName = [mdlName,'/plant'];
add_block(mylib_block_Plant,plantName,'Position',[600,50,600+heights,50+widths]);
% ��ȡ��plant���е�����˿�λ��
pPlant(1) = get_param([plantName,'/externalInterface'],'PortConnectivity');
pPlant(2) = get_param([plantName,'/scenarioInterface'],'PortConnectivity');
pPlant(3) = get_param([plantName,'/selector'],'PortConnectivity');
% ��architectStringArray��������ɨ��
for n = 1:sa(1)
    if(architectStringArray(n,1)~="") % ɨ�衰ϵͳ��
        systemHNum=systemHNum+1; % ��ϵͳ����������ͳ��
        subsystemHNum=1;
        instrumentsHNum=1;
        
        % ָ����ϵͳ����
        systemName=string([mdlName,'/plant','/'])+ architectStringArray(n,1);
        % ��ӡ�ϵͳ��ģ��
        H1(systemHNum) = add_block(mylib_block_Sys,char(systemName),'Position',[200,50+(systemHNum-1)*200,200+heights,50+widths+(systemHNum-1)*200]);
        % ��ȡ��plant���еġ�ϵͳ������������˿�λ��
        pSys = get_param(char(systemName),'PortConnectivity');
        % ���ӡ�ϵͳ���е�����˿ڵ���ϵͳ���еġ���ϵͳ������˿�
        add_line(plantName,[pPlant(1).Position;pSys(1).Position]);
        add_line(plantName,[pPlant(2).Position;pSys(2).Position]);
        add_line(plantName,[pPlant(3).Position;pSys(3).Position]);
        % ���á�plant���е�Addģ���������ΪsystemHNum
        addInputsSet(systemHNum,plantName);
        % ��ȡ��plant���е�Add������������˿�λ��
        pAdd = get_param(char(plantName + "/Add"),'PortConnectivity');
        % ���ӡ�palnt���еġ�ϵͳ��������˿��롰plant���е�Add����˿�systemHNum
        add_line(plantName,[pSys(4).Position;pAdd(systemHNum).Position]);
           
        
        
        % ��ȡ��ϵͳ���е�����˿�λ��
        pSys(1) = get_param(char(systemName+"/externalInterface"),'PortConnectivity');
        pSys(2) = get_param(char(systemName+"/scenarioInterface"),'PortConnectivity');
        pSys(3) = get_param(char(systemName+"/selector"),'PortConnectivity');
        
        % ָ����ϵͳ���еġ���ϵͳ����
        subsystemName = systemName + "/" + architectStringArray(n,2);
        % ��ӡ�ϵͳ���еġ���ϵͳ��ģ��
        H2(systemHNum,subsystemHNum) = add_block(mylib_block_Subsys,char(subsystemName),'Position',[150,-15,250+heights,-15+widths]);
        % ��ȡ��ϵͳ���еġ���ϵͳ������������˿�λ��
        pSubsys = get_param(char(subsystemName),'PortConnectivity');
        % ���ӡ�ϵͳ���е�����˿ڵ���ϵͳ���еġ���ϵͳ������˿�
        add_line(char(systemName),[pSys(1).Position;pSubsys(1).Position]);
        add_line(char(systemName),[pSys(2).Position;pSubsys(2).Position]);
        add_line(char(systemName),[pSys(3).Position;pSubsys(3).Position]);
        % ���á�ϵͳ���е�Addģ���������ΪsystemHNum
        %addInputsSet(systemHNum,char(systemName));
        % ��ȡ��ϵͳ���е�Add������������˿�λ��
        pAdd = get_param(char(systemName + "/Add"),'PortConnectivity');
        % ���ӡ�ϵͳ���еġ���ϵͳ��������˿��롰ϵͳ���е�Add����˿�subsystemHNum
        add_line(char(systemName),[pSubsys(4).Position;pAdd(subsystemHNum).Position]);
        
        % ��ȡ��ϵͳ���еġ���ϵͳ���е�����������˿�λ��
        pSubsys(1) = get_param(char(subsystemName+"/externalInterface"),'PortConnectivity');
        pSubsys(2) = get_param(char(subsystemName+"/scenarioInterface"),'PortConnectivity');
        pSubsys(3) = get_param(char(subsystemName+"/selector"),'PortConnectivity');
        pSubsys(4) = get_param(char(subsystemName+"/wattBus"),'PortConnectivity');
        % ��ȡͬһ���豸����
        instrumentNum = str2double(architectStringArray(n,4));
        % ���á�ϵͳ���еġ���ϵͳ���е�Addģ���������ΪsubsystemHNum*instrumentNum
        addInputsSet(subsystemHNum*instrumentNum,char(subsystemName));
        for m = 1:instrumentNum
            % ָ����ϵͳ���еġ���ϵͳ���еġ��豸����
            instrumentsName(m) = subsystemName + "/" + architectStringArray(n,3) + "_" + string(m);
            % ��ӡ�ϵͳ���еġ���ϵͳ���еġ��豸��ģ��
            H3(systemHNum,subsystemHNum,instrumentsHNum,m) = add_block(mylib_block_Instrument,char(instrumentsName(m)),'Position',[-150,50+ 200*(m-1),-50+heights,50+widths+ 200*(m-1)]);
            % ��ȡ��ϵͳ���еġ���ϵͳ���еġ��豸��������������˿�λ��
            pInstrument = get_param(char(instrumentsName(m)),'PortConnectivity');
            % ���ӡ�ϵͳ���еġ���ϵͳ���е�����˿��롰ϵͳ���С���ϵͳ���еġ��豸������˿�
            add_line(char(subsystemName),[pSubsys(1).Position;pInstrument(1).Position]);
            add_line(char(subsystemName),[pSubsys(2).Position;pInstrument(2).Position]);
            add_line(char(subsystemName),[pSubsys(3).Position;pInstrument(3).Position]);
            
            % ��ȡ��ϵͳ���еġ���ϵͳ���е�Add������������˿�λ��
            pAdd = get_param(char(subsystemName + "/Add"),'PortConnectivity');
            % ���ӡ�ϵͳ���еġ���ϵͳ���еġ��豸��������˿��롰ϵͳ���С���ϵͳ���е�Add����˿�m
            add_line(char(subsystemName),[pInstrument(4).Position;pAdd(m).Position]); 
        end
        instrumentNumInOneSubsystem(subsystemHNum) = instrumentsHNum*instrumentNum;
    else
        if(architectStringArray(n,2)~="")
            subsystemHNum = subsystemHNum + 1;
            instrumentsHNum=1;
            % ָ����ϵͳ���еġ���ϵͳ������
            subsystemName = systemName + "/" + architectStringArray(n,2);
            % ��ӡ�ϵͳ���еġ���ϵͳ��ģ��
            H2(systemHNum,subsystemHNum) = add_block(mylib_block_Subsys,char(subsystemName),'Position',[150,-20+(subsystemHNum-1)*200,250+heights,-20+widths+(subsystemHNum-1)*200]);
            % ��ȡ��ϵͳ���е���������˿�λ��
            pSys(1) = get_param(char(systemName+"/externalInterface"),'PortConnectivity');
            pSys(2) = get_param(char(systemName+"/scenarioInterface"),'PortConnectivity');
            % ��ȡ��ϵͳ���еġ���ϵͳ������������Ķ˿�λ��
            pSubsys = get_param(char(subsystemName),'PortConnectivity');
            % ���ӡ�ϵͳ���е����뵽��ϵͳ���еġ���ϵͳ���Ķ�Ӧ����˿�
            add_line(char(systemName),[pSys(1).Position;pSubsys(1).Position]);
            add_line(char(systemName),[pSys(2).Position;pSubsys(2).Position]);
            add_line(char(systemName),[pSys(3).Position;pSubsys(3).Position]);
            % ���á�ϵͳ���е�Addģ���������ΪsubsystemHNum
            addInputsSet(subsystemHNum,char(systemName));
            % ��ȡ��ϵͳ���е�Add������������˿�λ��
            pAdd = get_param(char(systemName + "/Add"),'PortConnectivity');
            % ���ӡ�ϵͳ���еġ���ϵͳ��������˿��롰ϵͳ���е�Add����˿�subsystemHNum
            add_line(char(systemName),[pSubsys(4).Position;pAdd(subsystemHNum).Position]);            
            
            % ��ȡ��ϵͳ���еġ���ϵͳ���е����롢����˿�λ��
            pSubsys(1) = get_param(char(subsystemName+"/externalInterface"),'PortConnectivity');
            pSubsys(2) = get_param(char(subsystemName+"/scenarioInterface"),'PortConnectivity');
            pSubsys(3) = get_param(char(subsystemName+"/selector"),'PortConnectivity');
            pSubsys(4) = get_param(char(subsystemName+"/wattBus"),'PortConnectivity');
            % ��ȡͬһ���豸����
            instrumentNum = str2double(architectStringArray(n,4));
            % ���á�ϵͳ���еġ���ϵͳ���е�Addģ���������ΪinstrumentsHNum*instrumentNum
            addInputsSet(instrumentsHNum*instrumentNum,char(subsystemName));
            for m = 1 : instrumentNum
                % ָ����ϵͳ���еġ���ϵͳ���еġ��豸������
                instrumentsName(m) = subsystemName + "/" + architectStringArray(n,3) + "_" + string(m);
                % ��ӡ�ϵͳ���еġ���ϵͳ���еġ��豸��ģ��
                H3(systemHNum,subsystemHNum,instrumentsHNum,m) = add_block(mylib_block_Instrument,char(instrumentsName(m)),'Position',[-150,50+200*(m-1),-50+heights,50+widths+200*(m-1)]);
                % ��ȡ��ϵͳ���еġ���ϵͳ���еġ��豸������������˿�λ��
                pInstrument = get_param(char(instrumentsName(m)),'PortConnectivity');
                % ���ӡ�ϵͳ���еġ���ϵͳ���е�����˿ڵ���ϵͳ���еġ���ϵͳ���еġ��豸����Ӧ����˿�
                add_line(char(subsystemName),[pSubsys(1).Position;pInstrument(1).Position]);
                add_line(char(subsystemName),[pSubsys(2).Position;pInstrument(2).Position]);
                add_line(char(subsystemName),[pSubsys(3).Position;pInstrument(3).Position]);
                
                % ��ȡ��ϵͳ���еġ���ϵͳ���е�Add������������˿�λ��
                pAdd = get_param(char(subsystemName + "/Add"),'PortConnectivity');
                % ���ӡ�ϵͳ���еġ���ϵͳ���еġ��豸��������˿��롰ϵͳ���С���ϵͳ���е�Add����˿�instrumentNum
                add_line(char(subsystemName),[pInstrument(4).Position;pAdd(m).Position]);
            end
            instrumentNumInOneSubsystem(subsystemHNum) = instrumentsHNum*instrumentNum;
        else
            if(architectStringArray(n,3)~="")
                % �ۼơ�ϵͳ���еġ���ϵͳ���еġ��豸��������
                instrumentsHNum = instrumentsHNum + 1;
                
                pSubsys(1) = get_param(char(subsystemName+"/externalInterface"),'PortConnectivity');
                pSubsys(2) = get_param(char(subsystemName+"/scenarioInterface"),'PortConnectivity');
                pSubsys(3) = get_param(char(subsystemName+"/selector"),'PortConnectivity');
                pSubsys(4) = get_param(char(subsystemName+"/wattBus"),'PortConnectivity');
                % ��ȡͬһ�ࡰ�豸������
                instrumentNum = str2double(architectStringArray(n,4));
                % ������ǰͬһ����ϵͳ���е����С��豸��������
                preInstrumentNumInOneSubsystem(subsystemHNum) = instrumentNumInOneSubsystem(subsystemHNum);
                % ���㵱ǰͬһ����ϵͳ���е����С��豸��������
                instrumentNumInOneSubsystem(subsystemHNum) = instrumentNumInOneSubsystem(subsystemHNum) + instrumentNum;
                % ���á�ϵͳ���еġ���ϵͳ���е�Addģ���������Ϊ��ǰ���豸��������instrumentNumInOneSubsystem(subsystemHNum)
                addInputsSet(instrumentNumInOneSubsystem(subsystemHNum),char(subsystemName));
                
                for m = 1 : instrumentNum
                    instrumentsName(m) = subsystemName + "/" + architectStringArray(n,3) + "_" + string(m);
                    H3(systemHNum,subsystemHNum,instrumentsHNum,m) = add_block(mylib_block_Instrument,char(instrumentsName(m)),'Position',[-150,50+(preInstrumentNumInOneSubsystem(subsystemHNum)+m-1)*200,-50+heights,50+widths+(preInstrumentNumInOneSubsystem(subsystemHNum)+m-1)*200]);

                    pInstrument = get_param(char(instrumentsName(m)),'PortConnectivity');
                    add_line(char(subsystemName),[pSubsys(1).Position;pInstrument(1).Position]);
                    add_line(char(subsystemName),[pSubsys(2).Position;pInstrument(2).Position]);
                    add_line(char(subsystemName),[pSubsys(3).Position;pInstrument(3).Position]);

                    % ��ȡ��ϵͳ���еġ���ϵͳ���е�Add������������˿�λ��
                    pAdd = get_param(char(subsystemName + "/Add"),'PortConnectivity');
                    % ���ӡ�ϵͳ���еġ���ϵͳ���еġ��豸��������˿��롰ϵͳ���С���ϵͳ���е�Add����˿�instrumentNum
                    add_line(char(subsystemName),[pInstrument(4).Position;pAdd(preInstrumentNumInOneSubsystem(subsystemHNum)+m).Position]);
                end
            else
            end
        end
    end
end
%%
% ����excel��ʽ����ȡ�������
dataArray = importExcelStringArray(9:se(1),:);
dataArray1 = importExcelStringArray(9:se(1),3:se(2));
sd = size(dataArray);
sd1 = size(dataArray1);
dataArray1WithSingleTime=dataArray1(2:sd1(1),4:sd1(2));
sda1wst = size(dataArray1WithSingleTime);
for n = 1:sda1wst(1)
    % ʹ�á��׶Ρ�����ʱ�����dataArray1WithSingleTime�еġ�C��
    for m = 1:sda1wst(2)/2
        if (dataArray1WithSingleTime(n,2+(m-1)*2)=="C")
            dataArray1WithSingleTime(n,2+(m-1)*2) = string(stageTime(m));
        end
    end
    % ��ȡģ̬���ݺͽ׶ε���ʱ��
    for n = 1:sda1wst(1)
        for m = 1:sda1wst(2)/2
            modalData(n,m) = dataArray1WithSingleTime(n,1+2*(m-1));
            sigleTime(n,m) = dataArray1WithSingleTime(n,2*m);
        end
    end
    % modalValue��ģ̬��ֵ
    % modalNum��ģ̬����
    [modalValue,modalNum] = capModals(modalData);
end
% ģ̬ѡ���ź� modalSelector
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
% ģ̬ѡ���ź�����
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
% ���γ���ʱ��(��λ��s) timeLast
timeLast = str2double(dataArray1WithSingleTime(:,2:2:sda1wst(2)));
% ����ִ��ʱ���ڽ׶���ʼʱ��ƫ����(��λ��s) timeOffSet
for n = 1:sda1wst(1)
    for m = 1:sda1wst(2)/2
        if(stageTime(m) == timeLast(n,m))
            timeOffSet(n,m) = 0;
        else
            timeOffSet(n,m) = (stageTime(m) - timeLast(n,m))/2;
        end
    end
end
%% wave���ι���
waveData=[];
% �׶�ʱ���
stageTimeMax = max(stageTime);
% ������������鳤��
stepsMax = stageTimeMax / sampleTime;
waveData(1,:) = ones(1,stepsMax);
% ����ʱ��
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
% �ṹԪ������ͳ��
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
%% �����ź�
% ͳ���豸���ࣺriggerSigcomponentID
% �������䴥���źž���triggerSiginstrumentsArray
% ͳ�Ƹ����豸������triggerSiginstrumentNumCap
% ���ܸ����豸�����ࡢ��������Ϣ��triggerSiginstrumentArray1
[triggerSigcomponentID,triggerSiginstrumentsArray,triggerSiginstrumentNumCap,triggerSiginstrumentArray1] = expandingArray(triggerSigAddArray);
% ������׼����ʼ�籾����
triggerSigStandInitArray = newStandInitArray(triggerSiginstrumentsArray);
% 
triggerSigStandArray = GenStandArray(triggerSiginstrumentsArray,triggerSigStandInitArray);
triggerSigStandData = str2double(triggerSigStandArray(:,4:size(triggerSigStandArray,2)));
%% ģ̬ѡ���ź�
[modalSelectorSigcomponentID,modalSelectorSiginstrumentsArray,modalSelectorSiginstrumentNumCap,modalSelectorSiginstrumentArray1] = expandingArray(modalSelectorSigAddArray);
modalSelectorSigStandInitArray = newStandInitArray(modalSelectorSiginstrumentsArray);
modalSelectorSigStandArray = GenStandArray(modalSelectorSiginstrumentsArray,modalSelectorSigStandInitArray);
modalSelectorSigStandData = str2double(modalSelectorSigStandArray(:,4:size(modalSelectorSigStandArray,2)));
%% �籾��������
for n = 1:triggerSigcomponentID
    scenarioData(n,:,:)=[modalSelectorSigStandData(((n-1)*5+1):(5*n),:);triggerSigStandData(((n-1)*5+1):(5*n),:)];
end
timeStep = [0:sampleTime:(stopTime-sampleTime)];
reshape(scenarioData(1,:,:), 10, stopTime/sampleTime);
%% �籾����
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