clear all
%% read and process the gridded satellite dataset
pLoadDatapath = '/.../'; The filepath that stored the processed L2 NO2 datasets
pSaveDatapath = '/.../'; The filepath to store the processed L3 NO2 datasets
mFilelistNO2 = dir([pLoadDatapath,'*.mat']);
pf = length(mFilelistNO2);
j = -1;

%% designate the spatial range
GRID_LAT_RANGE = [18,54];
GRID_LONG_RANGE = [73,135];
GRID_GAP_LAT = 0.05;
GRID_GAP_LONG = 0.05;

%% gridding
GRID_LAT_RANGE = minmax(GRID_LAT_RANGE);
GRID_LONG_RANGE = minmax(GRID_LONG_RANGE);
GRID_BIN_LAT = GRID_LAT_RANGE(1):GRID_GAP_LAT:GRID_LAT_RANGE(2);
GRID_BIN_LONG = GRID_LONG_RANGE(1):GRID_GAP_LONG:GRID_LONG_RANGE(2);

grid_col = length(GRID_BIN_LONG);
grid_row = length(GRID_BIN_LAT);

total_num = pf;
cnt = 1;
for i = 1:pf
    % avoid repetations
    if i <= j-1
        continue
    end
    
%     disp("number of processed documents");
%     disp(i);
%     disp(mFilelistNO2(i))
    pYearStr = mFilelistNO2(i).name(1:4);
    pMonthStr = mFilelistNO2(i).name(6:7);
    pDayStr = mFilelistNO2(i).name(8:9);
    pHourStr = mFilelistNO2(i).name(11:12);
    
    pYear = str2double (pYearStr);
    pMonth = str2double (pMonthStr);
    pDay = str2double (pDayStr);
    pHour = str2double (pHourStr);

    load([pLoadDatapath mFilelistNO2(i).name]);
      
    data.no2column = imresize(flip(no2column),[length(GRID_BIN_LAT)-1 length(GRID_BIN_LONG)-1],'bilinear');
    data.o3column = imresize(flip(o3column),[length(GRID_BIN_LAT)-1 length(GRID_BIN_LONG)-1],'bilinear');
    data.sza = imresize(flip(sza),[length(GRID_BIN_LAT)-1 length(GRID_BIN_LONG)-1],'bilinear');
    data.Slantno2column = imresize(flip(Slantno2column),[length(GRID_BIN_LAT)-1 length(GRID_BIN_LONG)-1],'bilinear');
  
    out_path = strcat(pSaveDatapath,pYearStr,'m',pMonthStr,pDayStr,'t',pHourStr,'NO2ColumnL3.mat');
    save(out_path,'-struct','data','*');
    
    clear grid
    clear quality
    % cnt 
   os.F_ProgressBar(total_num,1,cnt);
  cnt = cnt + 1;  
end
