function [SumofElementsH,Mux_pathH,mylib_block_H,endPosition] = genVsub(startPosition,mdlName,blockName,SumName,MuxName,blockNum,heights,weights,SumofElements_path,Mux_path,mylib_block_path)
%UNTITLED 此处显示有关此函数的摘要
%   此处显示详细说明
    %% 创建V28元件并连线    
    sizeblock = [0 0 heights weights];
    rightBias = [100 0 100 0];
    downBias = [0 100 0 100];
    SumofElementsH = add_block(SumofElements_path,[mdlName,'/',SumName],'Position',startPosition + sizeblock + 4*rightBias);
    Mux_pathH = add_block(Mux_path,[mdlName,'/',MuxName],'Position',startPosition + sizeblock.*[0 0 10/weights blockNum] + rightBias*2);
    % 根据设备数量（V28_blockNum）设置V28_Mux输入通道个数
    set_param([mdlName,'/', MuxName],'Inputs',char(string(blockNum)));
    % 根据设备数量（V28_blockNum）创建V28_blockNum个V28模块，并命名为V28_n；同时逐个连接V28_n输出到V28_Mux输入
    for n = 1:blockNum
        addBlockName=[blockName,char(string(n))];
        mylib_block_H(n) = add_block(mylib_block_path,[mdlName,'/',addBlockName],'Position',startPosition + sizeblock + downBias*0.5*n,'MakeNameUnique','on');
        addedBlockOutPort=[blockName,char(string(n)),'/1'];
        add_line(mdlName,addedBlockOutPort,[MuxName,'/',char(string(n))]);
    end
    add_line(mdlName,[MuxName,'/1'],[SumName,'/1']);
    endPosition = get_param([mdlName,'/',addBlockName],'Position');
end

