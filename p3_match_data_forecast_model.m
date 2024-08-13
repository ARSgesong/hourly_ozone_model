clear all
%%
GEMS_NO2_path = '/data01/sg/数据处理备份/GEMS-NO2-L3/p2/';
GEMS_HCHO_path = '/data01/sg/数据处理备份/GEMS-HCHO-L3/p2/';
GEMS_UV_path = '/data01/sg/数据处理备份/GEMS-UV-L3/p2/';
AUX_path = '/data01/sg/2023-静止卫星臭氧光化学反演/中间数据/AuxiliaryData/';

O3_GRD_path = '/data01/sg/2023-静止卫星臭氧光化学反演/中间数据/GRDdata/';

pSaveDatapath = '/data01/sg/2023-静止卫星臭氧光化学反演/匹配数据集_卫星全_Forecast/';
% pSaveDatapath = '/data01/sg/2023-静止卫星臭氧光化学反演/匹配数据集_MDA8_ratio/';

pSaveSDatapath = '/data01/sg/2023-静止卫星臭氧光化学反演/训练数据集_Forecast/';
% pSaveSDatapath = '/data01/sg/2023-静止卫星臭氧光化学反演/训练数据集_ratio/';

Filelist = dir([GEMS_NO2_path,'*.mat']);
pf = length(Filelist);
%分辨率网格数量
fb1 = 0.05;
fb2 = 0.05;
CONUSC = round(roundn((135-73)/fb1,-2));
CONUSR =  round(roundn((54-18)/fb2,-2));

Longitude_China=73+fb1/2:fb1:135-fb1/2;
Latitude_China=flip(18+fb2/2:fb2:54-fb2/2);
record=[];
mDataTableS_GEMS = [];

for i = 1:length(Filelist)
    date(i,1) = str2num(Filelist(i).name([1:4,6:9]));
end
dateList = unique(date);

for i = 1:length(dateList)
    datestr = num2str(dateList(i));
    disp(datestr);
    pYearStr = datestr(1:4);
    pDayStr = datestr(5:8);
    files_NO2_04 = dir([GEMS_NO2_path pYearStr 'm' pDayStr 't' '04' '*.mat']);
    files_NO2_05 = dir([GEMS_NO2_path pYearStr 'm' pDayStr 't' '05' '*.mat']);
    files_NO2_06 = dir([GEMS_NO2_path pYearStr 'm' pDayStr 't' '06' '*.mat']);
    
    files_UV_04 = dir([GEMS_UV_path pYearStr 'm' pDayStr 't' '04' '*.mat']);
    files_UV_05 = dir([GEMS_UV_path pYearStr 'm' pDayStr 't' '05' '*.mat']);
    files_UV_06 = dir([GEMS_UV_path pYearStr 'm' pDayStr 't' '06' '*.mat']);

    files_HCHO_04 = dir([GEMS_HCHO_path pYearStr 'm' pDayStr 't' '04' '*.mat']);
    files_HCHO_05 = dir([GEMS_HCHO_path pYearStr 'm' pDayStr 't' '05' '*.mat']);
    files_HCHO_06 = dir([GEMS_HCHO_path pYearStr 'm' pDayStr 't' '06' '*.mat']);
    
    if ~isempty(files_NO2_04)
        no2column_04 = load([GEMS_NO2_path files_NO2_04(1).name]).no2column;
    else
        no2column_04 =zeros([720,1240]);
    end
    if ~isempty(files_NO2_05)
        no2column_05 = load([GEMS_NO2_path files_NO2_05(1).name]).no2column;
    else
        no2column_05 =zeros([720,1240]);
    end
    if ~isempty(files_NO2_06)
        no2column_06 = load([GEMS_NO2_path files_NO2_06(1).name]).no2column;
    else
        no2column_06 =zeros([720,1240]);
    end
    
    
    if ~isempty(files_HCHO_04)
        hchocolumn_04 = load([GEMS_HCHO_path files_HCHO_04(1).name]).hchocolumn;
    else
        hchocolumn_04 =zeros([720,1240]);
    end
    if ~isempty(files_HCHO_05)
        hchocolumn_05 = load([GEMS_HCHO_path files_HCHO_05(1).name]).hchocolumn;
    else
        hchocolumn_05 =zeros([720,1240]);
    end
    if ~isempty(files_HCHO_06)
        hchocolumn_06 = load([GEMS_HCHO_path files_HCHO_06(1).name]).hchocolumn;
    else
        hchocolumn_06 =zeros([720,1240]);
    end
    
    
    if ~isempty(files_UV_04)
        uvindex_04 = load([GEMS_UV_path files_UV_04(1).name]).uvindex;
    else
        uvindex_04 =zeros([720,1240]);
    end
    if ~isempty(files_UV_05)
        uvindex_05 = load([GEMS_UV_path files_UV_05(1).name]).uvindex;
    else
        uvindex_05 =zeros([720,1240]);
    end
    if ~isempty(files_UV_06)
        uvindex_06 = load([GEMS_UV_path files_UV_06(1).name]).uvindex;
    else
        uvindex_06 =zeros([720,1240]);
    end
    
    

    mData_GEMS_NO2 = no2column_06;
    mData_GEMS_NO2(isnan(mData_GEMS_NO2)) = -9999;
    [Rindex,Cindex]= find(~isnan(mData_GEMS_NO2));
    index = find(~isnan(mData_GEMS_NO2));
    pTableCol = Cindex;
    pTableRow = Rindex;
    pTableID =  index;
    pTablelat = Latitude_China(Rindex)';
    pTablelon = Longitude_China(Cindex)';
    pTableDay = ones(size(pTableID)).*str2num(pDayStr(3:4));
    pTableMonth = ones(size(pTableID)).*str2num(pDayStr(1:2));
    pTableYear = ones(size(pTableID)).*str2num(pYearStr);

    load([AUX_path,'AUX_',pYearStr,pDayStr,'06','.mat']);
    pTablet2_06 = reshape(t2,size(pTableID));
    pTabled2_06 = reshape(d2,size(pTableID));
    pTablesp_06 = reshape(sp,size(pTableID));
    pTableu10_06 = reshape(u10,size(pTableID));
    pTablev10_06 = reshape(v10,size(pTableID));
    pTabletp_06 = reshape(tp,size(pTableID));
    pTablee_06 = reshape(e,size(pTableID));
    pTableRH_06 = reshape(RH,size(pTableID));
    
    load([AUX_path,'AUX_',pYearStr,pDayStr,'09','.mat']);
    pTablet2_09 = reshape(t2,size(pTableID));
    pTabled2_09 = reshape(d2,size(pTableID));
    pTablesp_09 = reshape(sp,size(pTableID));
    pTableu10_09 = reshape(u10,size(pTableID));
    pTablev10_09 = reshape(v10,size(pTableID));
    pTabletp_09 = reshape(tp,size(pTableID));
    pTablee_09 = reshape(e,size(pTableID));
    pTableRH_09 = reshape(RH,size(pTableID));
    
    load([AUX_path,'AUX_',pYearStr,pDayStr,'10','.mat']);
    pTablet2_10 = reshape(t2,size(pTableID));
    pTabled2_10 = reshape(d2,size(pTableID));
    pTablesp_10 = reshape(sp,size(pTableID));
    pTableu10_10 = reshape(u10,size(pTableID));
    pTablev10_10 = reshape(v10,size(pTableID));
    pTabletp_10 = reshape(tp,size(pTableID));
    pTablee_10 = reshape(e,size(pTableID));
    pTableRH_10 = reshape(RH,size(pTableID));

    load([AUX_path,'AUX_',pYearStr,pDayStr,'11','.mat']);
    pTablet2_11 = reshape(t2,size(pTableID));
    pTabled2_11 = reshape(d2,size(pTableID));
    pTablesp_11 = reshape(sp,size(pTableID));
    pTableu10_11 = reshape(u10,size(pTableID));
    pTablev10_11 = reshape(v10,size(pTableID));
    pTabletp_11 = reshape(tp,size(pTableID));
    pTablee_11 = reshape(e,size(pTableID));
    pTableRH_11 = reshape(RH,size(pTableID));

    load([AUX_path,'AUX_',pYearStr,pDayStr,'12','.mat']);
    pTablet2_12 = reshape(t2,size(pTableID));
    pTabled2_12 = reshape(d2,size(pTableID));
    pTablesp_12 = reshape(sp,size(pTableID));
    pTableu10_12 = reshape(u10,size(pTableID));
    pTablev10_12 = reshape(v10,size(pTableID));
    pTabletp_12 = reshape(tp,size(pTableID));
    pTablee_12 = reshape(e,size(pTableID));
    pTableRH_12 = reshape(RH,size(pTableID));
    
    load([AUX_path,'AUX_',pYearStr,pDayStr,'08','.mat']);
    pTablet2_08 = reshape(t2,size(pTableID));
    pTabled2_08 = reshape(d2,size(pTableID));
    pTablesp_08 = reshape(sp,size(pTableID));
    pTableu10_08 = reshape(u10,size(pTableID));
    pTablev10_08 = reshape(v10,size(pTableID));
    pTabletp_08 = reshape(tp,size(pTableID));
    pTablee_08 = reshape(e,size(pTableID));
    pTableRH_08 = reshape(RH,size(pTableID));

    pTableSRTM = reshape(mSRTMdata,size(pTableID));
    pTableNDVI = reshape(mNDVIdata,size(pTableID));

    
    pTableNO2_04 = reshape(no2column_04,size(pTableID));
    pTableNO2_05 = reshape(no2column_05,size(pTableID));
    pTableNO2_06 = reshape(no2column_06,size(pTableID));
    
    pTableHCHO_04 = reshape(hchocolumn_04,size(pTableID));
    pTableHCHO_05 = reshape(hchocolumn_05,size(pTableID));
    pTableHCHO_06 = reshape(hchocolumn_06,size(pTableID));
    
    pTableUV_04 = reshape(uvindex_04,size(pTableID));
    pTableUV_05 = reshape(uvindex_05,size(pTableID));
    pTableUV_06 = reshape(uvindex_06,size(pTableID));

    O3_MDA_17 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'09.mat']).GRD;
    pTableO3_17 = reshape(O3_MDA_17,size(pTableID));
    O3_MDA_18 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'10.mat']).GRD;
    pTableO3_18 = reshape(O3_MDA_18,size(pTableID));
    O3_MDA_19 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'11.mat']).GRD;
    pTableO3_19 = reshape(O3_MDA_19,size(pTableID));
    O3_MDA_20 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'12.mat']).GRD;
    pTableO3_20 = reshape(O3_MDA_20,size(pTableID));
    O3_MDA_16 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'08.mat']).GRD;
    pTableO3_16 = reshape(O3_MDA_16,size(pTableID));
    O3_MDA_15 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'07.mat']).GRD;
    pTableO3_15 = reshape(O3_MDA_16,size(pTableID));
    O3_MDA_14 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'06.mat']).GRD;
    pTableO3_14 = reshape(O3_MDA_14,size(pTableID));
    O3_MDA_13 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'05.mat']).GRD;
    pTableO3_13 = reshape(O3_MDA_13,size(pTableID));
    O3_MDA_12 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'04.mat']).GRD;
    pTableO3_12 = reshape(O3_MDA_12,size(pTableID));
    O3_MDA_11 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'03.mat']).GRD;
    pTableO3_11 = reshape(O3_MDA_11,size(pTableID));
    O3_MDA_10 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'02.mat']).GRD;
    pTableO3_10 = reshape(O3_MDA_10,size(pTableID));
    O3_MDA_09 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'01.mat']).GRD;
    pTableO3_09 = reshape(O3_MDA_09,size(pTableID));
    O3_MDA_08 = load([O3_GRD_path,'GRD_',pYearStr,pDayStr,'00.mat']).GRD;
    pTableO3_08 = reshape(O3_MDA_08,size(pTableID));
    
    pMatchData = [pTablelon    pTablelat    pTableID     pTableRow     pTableCol  zeros(size(pTableID))...
        pTableYear   pTableMonth     pTableDay  zeros(size(pTableID)) zeros(size(pTableID))    ...
        pTableSRTM    pTableNDVI   zeros(size(pTableID))...
        pTablet2_06 pTabled2_06 pTablesp_06 pTableu10_06 pTablev10_06 pTabletp_06...
        pTablee_06 pTableRH_06 zeros(size(pTableID))...
        pTablet2_09 pTabled2_09 pTablesp_09 pTableu10_09 pTablev10_09 pTabletp_09...
        pTablee_09 pTableRH_09 zeros(size(pTableID))...
        pTablet2_10 pTabled2_10 pTablesp_10 pTableu10_10 pTablev10_10 pTabletp_10...
        pTablee_10 pTableRH_10 zeros(size(pTableID))...
        pTablet2_11 pTabled2_11 pTablesp_11 pTableu10_11 pTablev10_11 pTabletp_11...
        pTablee_11 pTableRH_11 zeros(size(pTableID))...
        pTablet2_12 pTabled2_12 pTablesp_12 pTableu10_12 pTablev10_12 pTabletp_12...
        pTablee_12 pTableRH_12 zeros(size(pTableID))...
        pTablet2_08 pTabled2_08 pTablesp_08 pTableu10_08 pTablev10_08 pTabletp_08...
        pTablee_08 pTableRH_08 zeros(size(pTableID))...
        pTableNO2_04 pTableNO2_05 pTableNO2_06 zeros(size(pTableID)) pTableHCHO_04 pTableHCHO_05 ...
        pTableHCHO_06 pTableUV_04 pTableUV_05 pTableUV_06 zeros(size(pTableID)) pTableO3_08 pTableO3_09 pTableO3_10 pTableO3_11 pTableO3_12 pTableO3_13 pTableO3_14 pTableO3_15 pTableO3_16 pTableO3_17 pTableO3_18 pTableO3_19 pTableO3_20   ];

    pMatchData(:,94) = day(datetime( pMatchData(:,7), pMatchData(:,8), pMatchData(:,9)),'dayofyear');
    pMatchData(:,95) = weekday(datetime( pMatchData(:,7), pMatchData(:,8), pMatchData(:,9)),'dayofyear');

    pMatchData = pMatchData(pMatchData(:,70)> 0 & pMatchData(:,74 )~=0 & pMatchData(:,77 )>0 ,:);
    index=find(~isnan(pMatchData(:,20)));
    pMatchData = pMatchData(index,:);
    pMatchDataS = pMatchData(pMatchData(:,80)>0 & pMatchData(:,81)>0 & pMatchData(:,82)>0 & pMatchData(:,83)>0 & pMatchData(:,84)>0 & pMatchData(:,85)>0 & pMatchData(:,86)>0,:);
    mDataTableS_GEMS = [mDataTableS_GEMS;pMatchDataS];
%     mDataTableS_GEMS = mDataTableS_GEMS(mDataTableS_GEMS(:,24)<1e17,:);
%     mDataTableS_GEMS = mDataTableS_GEMS(mDataTableS_GEMS(:,28)<1e17,:);
    record=[record;size(mDataTableS_GEMS,1)];
    if ~isempty(pMatchData)
     save ([pSaveDatapath,'mDataTable_GEMS_',pYearStr,pDayStr,'.mat'],'pMatchData');
    end
end
%     save ([pSaveDatapath,'mDataTable_GEMS_total.mat'],'mDataTable_GEMS');
    
%     pMatchDataS = pMatchData(pMatchData(:,33)>0,:);
% mDataTableS_GEMS = mDataTableS_GEMS(mDataTableS_GEMS(:,24)<1e17,:);
% mDataTableS_GEMS = mDataTableS_GEMS(mDataTableS_GEMS(:,28)<1e17,:);
save ([pSaveSDatapath,'mDataTableS_GEMS_train_MDA8.mat'],'mDataTableS_GEMS');

