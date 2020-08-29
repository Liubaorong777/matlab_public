function Untitled = importfile2cellarray(workbookFile, sheetName, dataLines)
%IMPORTFILE 导入电子表格中的数据
%  UNTITLED = IMPORTFILE(FILE) 读取名为 FILE 的 Microsoft Excel
%  电子表格文件的第一张工作表中的数据。  以字符串数组形式返回数据。
%
%  UNTITLED = IMPORTFILE(FILE, SHEET) 从指定的工作表中读取。
%
%  UNTITLED = IMPORTFILE(FILE, SHEET,
%  DATALINES)按指定的行间隔读取指定工作表中的数据。对于不连续的行间隔，请将 DATALINES 指定为正整数标量或 N×2
%  正整数标量数组。
%
%  示例:
%  Untitled = importfile("G:\MatlabWorkspace\systemComposerDemo\工作簿1.xlsx", "Sheet1", [1, 25]);
%
%  另请参阅 READTABLE。
%
% 由 MATLAB 于 2020-07-13 17:59:15 自动生成

%% 输入处理

% 如果未指定工作表，则将读取第一张工作表
if nargin == 1 || isempty(sheetName)
    sheetName = 1;
end

% 如果未指定行的起点和终点，则会定义默认值。
if nargin <= 2
    dataLines = [1, 25];
end

%% 设置导入选项并导入数据
opts = spreadsheetImportOptions("NumVariables", 17);

% 指定工作表和范围
opts.Sheet = sheetName;
opts.DataRange = "A" + dataLines(1, 1) + ":Q" + dataLines(1, 2);

% 指定列名称和类型
opts.VariableNames = ["VarName1", "VarName2", "VarName3", "VarName4", "VarName5", "VarName6", "VarName7", "VarName8", "VarName9", "VarName10", "VarName11", "VarName12", "VarName13", "VarName14", "VarName15", "VarName16", "VarName17"];
opts.VariableTypes = ["string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string"];

% 指定变量属性
opts = setvaropts(opts, ["VarName1", "VarName2", "VarName3", "VarName4", "VarName5", "VarName6", "VarName7", "VarName8", "VarName9", "VarName10", "VarName11", "VarName12", "VarName13", "VarName14", "VarName15", "VarName16", "VarName17"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["VarName1", "VarName2", "VarName3", "VarName4", "VarName5", "VarName6", "VarName7", "VarName8", "VarName9", "VarName10", "VarName11", "VarName12", "VarName13", "VarName14", "VarName15", "VarName16", "VarName17"], "EmptyFieldRule", "auto");

% 导入数据
Untitled = readmatrix(workbookFile, opts, "UseExcel", false);

for idx = 2:size(dataLines, 1)
    opts.DataRange = "A" + dataLines(idx, 1) + ":Q" + dataLines(idx, 2);
    tb = readmatrix(workbookFile, opts, "UseExcel", false);
    Untitled = [Untitled; tb]; %#ok<AGROW>
end

end