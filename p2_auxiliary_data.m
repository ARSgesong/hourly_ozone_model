clear all
%% elevation and land use dataset
disp('read fixed dataset');
%1read SRTM20s files（fixed tif）
mSRTMdata=imread('/.../'); %The filepath that stored the SRTM datasets
%2read LandUC20s files（fixed tif）
% mLandUCdata=imread('/.../'); %The filepath that stored the Land use datasets

mSRTMdata =double(mSRTMdata);
% mLandUCdata =double(mLandUCdata);
%specify the spatial resolution
fbl = 0.05;
fb2 = 0.05;
CONUSC = round(roundn((135-73)/fb2,-2));
CONUSR =  round(roundn((54-18)/fb2,-2));

%resample to 0.25-deg
mSRTMdata = imresize(mSRTMdata,[CONUSR CONUSC],'nearest');
% mLandUCdata = imresize(mLandUCdata,[CONUSR CONUSC],'nearest');

data.mSRTMdata = mSRTMdata;
% data.mLandUCdata = mLandUCdata;


%% read ERA5 files
max_day = [31 28 31 30 31 30 31 31 30 31 30 31];

pERA5path = '/.../'; %The filepath that stored the ERA5 datasets

clear mERA_s_time;
clear mERA_s_u10china;
clear mERA_s_v10china;
clear mERA_s_d2mchina;
clear mERA_s_t2mchina;
clear mERA_s_blhchina;
clear mERA_s_echina;
clear mERA_s_spchina;
clear mERA_s_tco3china;
clear mERA_s_tcwchina;
clear mERA_s_tpchina;

sFilelist = dir([pERA5path 'S/' '*.nc']);
pFilelist = dir([pERA5path 'P/' '*.nc']);

for i = 1:pf
    disp(['number of documents processed' num2str(i) ',total of ' num2str(length(sFilelist))]);
    pYearStr = sFilelist(i).name(1:4);
    pMonthStr = sFilelist(i).name(5:6);
%     pHourStr = '20'; %if a specific hour of observation is needed, please specify here
    month = str2num(pMonthStr);
    
    mNDVIdata=imread(['/.../']); %The filepath that stored the NDVI datasets
    mNDVIdata =double(mNDVIdata);
    mNDVIdata = imresize(mNDVIdata,[CONUSR CONUSC],'bilinear');
    data.mNDVIdata = mNDVIdata./10000;%scaled into -1，1  value >10000 is invalid
    
    mERA_s_time = ncread([pERA5path,'S/',sFilelist(i).name],'time');
    mERA_s_u10china = ncread([pERA5path,'S/',sFilelist(i).name],'u10');
    mERA_s_v10china = ncread([pERA5path,'S/',sFilelist(i).name],'v10');
    mERA_s_d2mchina = ncread([pERA5path,'S/',sFilelist(i).name],'d2m');
    mERA_s_t2mchina = ncread([pERA5path,'S/',sFilelist(i).name],'t2m');
%     mERA_s_blhchina = ncread([pERA5path,'S/',sFilelist(i).name],'blh');
    mERA_s_echina = ncread([pERA5path,'S/',sFilelist(i).name],'e');
    mERA_s_spchina = ncread([pERA5path,'S/',sFilelist(i).name],'sp');
%     mERA_s_tco3china = ncread([pERA5path,'S/',sFilelist(i).name],'tco3');
%     mERA_s_tcwchina = ncread([pERA5path,'S/',sFilelist(i).name],'tcwv');
    mERA_s_tpchina = ncread([pERA5path,'S/',sFilelist(i).name],'tp');
%     mERA_s_tccchina = ncread([pERA5path,'S/',sFilelist(i).name],'tcc');
%     mERA_s_tciwchina = ncread([pERA5path,'S/',sFilelist(i).name],'tciw');
%     mERA_s_tclwchina = ncread([pERA5path,'S/',sFilelist(i).name],'tclw');
%     mERA_s_capechina = ncread([pERA5path,'S/',sFilelist(i).name],'cape');
%     
    mLeftCol = 1;
    mTopRow =  1;
    mRightCol = size(mERA_s_u10china,1);
    mButtomRow = size(mERA_s_u10china,2);
    
    mERA_p_time = ncread([pERA5path,'P/',pFilelist(i).name],'time');
    atime =length(mERA_p_time(:));
    a = mLeftCol-1;
    b= mTopRow-1;
    c= mRightCol-mLeftCol;
    d= mButtomRow-mTopRow;
    id = netcdf.open([pERA5path,'P/',pFilelist(i).name]);
    varid = netcdf.inqVarID(id,'r');
    mERA_p_levelchina = ncread([pERA5path,'P/',pFilelist(i).name],'level');
    temp =  netcdf.getVar(id,varid);
    offset = netcdf.getAtt(id,varid,'add_offset');
    factor = netcdf.getAtt(id,varid,'scale_factor');
    mERA_p_rchina = double(temp)*factor + offset;
    netcdf.close(id);
    
    for m = 1:size(mERA_p_rchina,3)
        for n = 1:size(mERA_p_rchina,4)
            mERA_p_rchina2(:,:,m,n) = imresize(mERA_p_rchina(:,:,m,n),[size(mERA_s_u10china,1) size(mERA_s_u10china,2)],'bilinear');
        end
    end

    for day = 1:max_day(month)
        if day<10
            pDayStr = ['0' num2str(day)];
        else
            pDayStr =num2str(day);
        end
        
        for hour = 0:23
            if hour<10
                pHourStr = ['0' num2str(hour)];
            else
                pHourStr =num2str(hour);
            end
            pStrTime = [pYearStr,'-',pMonthStr,'-',pDayStr,' ',pHourStr,':00:00'];
            v0 = datevec(pStrTime);
            v = datevec('1900-01-01 00:00:00');
            pDayandHourNUM = fix(etime(v0,v)/3600);
            pERATimeIndex = find(mERA_s_time == pDayandHourNUM);
            if isempty(pERATimeIndex)
             continue;
            end

            %*****************************************************************************
            % row-column conversion index
            indexRERA = size(mERA_s_u10china,1);
            indexCERA = size(mERA_s_u10china,2);
            pERATimeIndex= ones(indexRERA*indexCERA,1).*pERATimeIndex;
        %     indexRC = (pTableERA5Col -1).*indexRERA + pTableERA5Row;
            indexRCERA = (pERATimeIndex -1).*(indexRERA*indexCERA)+ [1:indexRERA*indexCERA]';
        %   pTableu10 = mERA_s_u10china(pTableERA5Col,pTableERA5Row,pERATimeIndex);
            pTableu10 = mERA_s_u10china(indexRCERA);
            pTablev10 = mERA_s_v10china(indexRCERA);
            pTabled2 = mERA_s_d2mchina(indexRCERA);
            pTablet2 = mERA_s_t2mchina(indexRCERA);
%             pTableblh = mERA_s_blhchina(indexRCERA);
            pTablee = mERA_s_echina(indexRCERA);
            pTablesp = mERA_s_spchina(indexRCERA);
%             pTabletco3 = mERA_s_tco3china(indexRCERA);
%             pTabletcw = mERA_s_tcwchina(indexRCERA);
            pTabletp = mERA_s_tpchina(indexRCERA);
%             pTabletcc = mERA_s_tccchina(indexRCERA);
%             pTabletciw = mERA_s_tciwchina(indexRCERA);
%             pTabletclw = mERA_s_tclwchina(indexRCERA);
%             pTablecape = mERA_s_capechina(indexRCERA);
            %find the level-specific pressure
            mERA_p_levelchina = (mERA_p_levelchina.* 100)';
            if size(mERA_p_levelchina,1)>1
             mERA_p_levelchina = mERA_p_levelchina';
            end    
            pERARHIndex= repmat(mERA_p_levelchina,length(indexRCERA),1);
            %batch test
            testaa = size(mERA_p_levelchina,2);
            if testaa ==1
            testaa = size(mERA_p_levelchina,1);
            end
            testsp = repmat(pTablesp,1,testaa);
            pERARHIndex = abs(double(pERARHIndex) -testsp );
            [~,pTableRHindex]=min(pERARHIndex,[],2);

            %read relative humidity at the surface
            %row-column conversion index
            

            indexH1ERA = size(mERA_p_rchina2,3);

            %define the new dimension
            indexRERAp = size(mERA_p_rchina2,1);
            indexCERAp = size(mERA_p_rchina2,2);
            indexRCERA4 = (pERATimeIndex -1).*(indexRERAp*indexCERAp*indexH1ERA);
            %locate the 3D variable
        %     indexRC = (pTableERA5Col -1).*indexRERA + pTableERA5Row;
            indexRCERA3 = (pTableRHindex -1).*(indexRERA*indexCERA)+ [0:indexRERA*indexCERA-1]';
            indexRCERAt = indexRCERA4 + indexRCERA3;

            %pTableRH = mERA_p_rchina(pTableERA5Col,pTableERA5Row,pTableRHindex,pERATimeIndex);
            pTableRH = mERA_p_rchina2(indexRCERAt);

            data.t2 = imresize(reshape(pTablet2,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
            data.d2 = imresize(reshape(pTabled2,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
            data.sp = imresize(reshape(pTablesp,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
            data.u10 = imresize(reshape(pTableu10,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
            data.v10 = imresize(reshape(pTablev10,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
%             data.blh = imresize(reshape(pTableblh,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
            data.tp = imresize(reshape(pTabletp,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
            data.e = imresize(reshape(pTablee,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
            data.RH = imresize(reshape(pTableRH,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
%             data.tcw = imresize(reshape(pTabletcw,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
%             data.tco3 = imresize(reshape(pTabletco3,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
%             data.tcc = imresize(reshape(pTabletcc,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
%             data.tciw = imresize(reshape(pTabletciw,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
%             data.tclw = imresize(reshape(pTabletclw,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');
%             data.cape = imresize(reshape(pTablecape,[indexRERA indexCERA])',[CONUSR CONUSC],'nearest');

            out_path = strcat('/../'); %The filepath to store the processed auxiliary datasets
            save(out_path,'-struct','data','*');

        end
    end
end

