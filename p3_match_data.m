clear all
%%
GEMS_NO2_path = '/data01/sg/数据处理备份/GEMS-NO2-L3/p2/';
GEMS_HCHO_path = '/data01/sg/数据处理备份/GEMS-HCHO-L3/p2/';
GEMS_UV_path = '/data01/sg/数据处理备份/GEMS-UV-L3/p2/';
AUX_path = '/data01/sg/2023-静止卫星臭氧光化学反演/中间数据/AuxiliaryData/';

O3_GRD_path = '/data01/sg/2023-静止卫星臭氧光化学反演/中间数据/GRDdata/';
pSaveDatapath = '/data01/sg/2023-静止卫星臭氧光化学反演/匹配数据集_卫星全_0711/';
pSaveSDatapath = '/data01/sg/2023-静止卫星臭氧光化学反演/训练数据集_1023/';

Filelist = dir([GEMS_NO2_path,'*.mat']);
pf = length(Filelist)
%分辨率网格数量
fb1 = 0.05;
fb2 = 0.05;
CONUSC = round(roundn((135-73)/fb1,-2));
CONUSR =  round(roundn((54-18)/fb2,-2));

Longitude_China=73+fb1/2:fb1:135-fb1/2;
Latitude_China=flip(18+fb2/2:fb2:54-fb2/2);
record=[];
mDataTableS_GEMS = [];
for i = 2080:pf
    disp(['执行文件数' num2str(i) ',共' num2str(length(Filelist)) '个文件']);
    pYearStr = Filelist(i).name(1:4);
    pMonthStr = Filelist(i).name(6:7);
    pDayStr = Filelist(i).name(8:9);
    pHourStr = Filelist(i).name(11:12);
    
    %!!!!!!!Satellite is flipped!!!!!!!
    load([GEMS_NO2_path,pYearStr,'m',pMonthStr,pDayStr,'t',pHourStr,'NO2ColumnL3.mat']);
%     no2column = flip(no2column);
%     o3column = flip(o3column);
%     sza = flip(sza);
%     Slantno2column = flip(Slantno2column);
    
    load([AUX_path,'AUX_',pYearStr,pMonthStr,pDayStr,pHourStr,'.mat']);

     alist = dir([GEMS_HCHO_path,pYearStr,'m',pMonthStr,pDayStr,'t',pHourStr,'HCHOColumnL3.mat']);
     if length(alist)==0
         hchocolumn = zeros([CONUSR CONUSC]);
         hchocolumnuncertainty = zeros([CONUSR CONUSC]);
     else
         load([GEMS_HCHO_path,pYearStr,'m',pMonthStr,pDayStr,'t',pHourStr,'HCHOColumnL3.mat']);
%          hchocolumn = flip(hchocolumn);
%          hchocolumnuncertainty = flip(hchocolumnuncertainty);
%          hchocolumn = imresize(hchocolumn,[CONUSR CONUSC],'nearest');
%          hchocolumnuncertainty = imresize(hchocolumnuncertainty,[CONUSR CONUSC],'nearest');

     end
     
     blist = dir([GEMS_UV_path,pYearStr,'m',pMonthStr,pDayStr,'t',pHourStr,'UVColumnL3.mat']);
     if length(blist)==0
         uvindex = zeros([CONUSR CONUSC]);
         photolysis = zeros([CONUSR CONUSC]);
     else
         load([GEMS_UV_path,pYearStr,'m',pMonthStr,pDayStr,'t',pHourStr,'UVColumnL3.mat']);
%          uvindex = flip(uvindex);
%          photolysis = flip(photolysis);
     end
     
     clist = dir([O3_GRD_path,'GRD_',pYearStr,pMonthStr,pDayStr,pHourStr,'.mat']);
     if length(clist)==0
         GRD = zeros([CONUSR CONUSC]);
     else
         load([O3_GRD_path,'GRD_',pYearStr,pMonthStr,pDayStr,pHourStr,'.mat']);
     end
    
    mData_GEMS_NO2 = no2column;
    mData_GEMS_NO2(isnan(mData_GEMS_NO2)) = -9999;
    [Rindex,Cindex]= find(~isnan(mData_GEMS_NO2));
    index = find(~isnan(mData_GEMS_NO2));
    pTableCol = Cindex;
    pTableRow = Rindex;
    pTableID =  index;
    pTablelat = Latitude_China(Rindex)';
    pTablelon = Longitude_China(Cindex)';
    pTableHour = ones(size(pTableID)).*str2num(pHourStr);
    pTableDay = ones(size(pTableID)).*str2num(pDayStr);
    pTableMonth = ones(size(pTableID)).*str2num(pMonthStr);
    pTableYear = ones(size(pTableID)).*str2num(pYearStr);
    pTableSRTM = reshape(mSRTMdata,size(pTableID));
    pTableNDVI = reshape(mNDVIdata,size(pTableID));

    pTablet2 = reshape(t2,size(pTableID));
    pTabled2 = reshape(d2,size(pTableID));
    pTablesp = reshape(sp,size(pTableID));
    pTableu10 = reshape(u10,size(pTableID));
    pTablev10 = reshape(v10,size(pTableID));
    pTabletp = reshape(tp,size(pTableID));
    pTablee = reshape(e,size(pTableID));
    pTableRH = reshape(RH,size(pTableID));

    pTableNO2 = reshape(mData_GEMS_NO2,size(pTableID));
    pTableO3 = reshape(o3column,size(pTableID));
    pTableSZA = reshape(sza,size(pTableID));

    pTableHCHO = reshape(hchocolumn,size(pTableID));
    pTableHCHO_uncertainty = reshape(hchocolumnuncertainty,size(pTableID));
    pTableUVindex = reshape(uvindex,size(pTableID));
    pTablephotolysis = reshape(photolysis,size(pTableID));

    pTableO3_GRD = reshape(GRD,size(pTableID));
    
    pMatchData = [pTablelon    pTablelat    pTableID     pTableRow     pTableCol  zeros(size(pTableID))...
        pTableYear   pTableMonth     pTableDay  pTableHour zeros(size(pTableID))    ...
        pTableSRTM    pTableNDVI   zeros(size(pTableID))...
        pTablet2 pTabled2 pTablesp pTableu10 pTablev10 pTabletp...
        pTablee pTableRH zeros(size(pTableID)) pTableNO2 pTableO3 pTableSZA zeros(size(pTableID)) pTableHCHO pTableHCHO_uncertainty ...
        pTableUVindex pTablephotolysis  zeros(size(pTableID)) pTableO3_GRD];
    pMatchData(:,34) = day(datetime( pMatchData(:,7), pMatchData(:,8), pMatchData(:,9)),'dayofyear');
    pMatchData(:,35) = weekday(datetime( pMatchData(:,7), pMatchData(:,8), pMatchData(:,9)),'dayofyear');
    
    pMatchData = pMatchData(pMatchData(:,24)> 0 & pMatchData(:,28 )~=0 & pMatchData(:,30 )>0 ,:);
    index=find(~isnan(pMatchData(:,20)));
    pMatchData = pMatchData(index,:);
    pMatchDataS = pMatchData(pMatchData(:,33)>0,:);
    mDataTableS_GEMS = [mDataTableS_GEMS;pMatchDataS];

    mDataTableS_GEMS = mDataTableS_GEMS(mDataTableS_GEMS(:,24)<1e17,:);
    mDataTableS_GEMS = mDataTableS_GEMS(mDataTableS_GEMS(:,28)<1e17,:);
    record=[record;size(mDataTableS_GEMS,1)];
    if ~isempty(pMatchData)
     save ([pSaveDatapath,'mDataTable_GEMS_',pYearStr,pMonthStr,pDayStr,pHourStr,'.mat'],'pMatchData');
    end
end
%     save ([pSaveDatapath,'mDataTable_GEMS_total.mat'],'mDataTable_GEMS');
    
%     pMatchDataS = pMatchData(pMatchData(:,33)>0,:);
% mDataTableS_GEMS = mDataTableS_GEMS(mDataTableS_GEMS(:,24)<1e17,:);
% mDataTableS_GEMS = mDataTableS_GEMS(mDataTableS_GEMS(:,28)<1e17,:);
% save ([pSaveSDatapath,'mDataTableS_GEMS_train.mat'],'mDataTableS_GEMS');

% mDataTableS_GEMS(:,37)= mDataTableS_GEMS(:,29)./mDataTableS_GEMS(:,28);
% mDataTableS_GEMS_HCHOfilter = mDataTableS_GEMS(mDataTableS_GEMS(:,37)<1,:);
% save ([pSaveSDatapath,'mDataTableS_GEMS_train_HCHOfilter.mat'],'mDataTableS_GEMS_HCHOfilter');
% 
% 
