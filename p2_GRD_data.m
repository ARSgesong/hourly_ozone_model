clear all
%%
pPM25Spath = '/data01/sg/卫星数据备份/辅助数据/pm/s2022_5km.xlsx';
pPM25SpathSheet = 'Sheet1';%站点sheet页
pPM25SpathRange = 'A2:G2027';%注意表中“行”“列”两列需先在XLS中计算好，保存为数值（已处理完成，计算方式已在XLS中公式保存，行列值以中国矩形区域（73,135E;18,54N）0.25°分辨率计算）
pPM25path = '/data01/sg/卫星数据备份/辅助数据/pm/2023/';

%1读取中国pm25站点经纬度位置及编号文件（固定）1ID(char) 2name 3city 4lon 5lat
[mPM25LocationdataNUM,mPM25LocationdataNAME] = xlsread(pPM25Spath,pPM25SpathSheet,pPM25SpathRange);

%分辨率网格数量
fb1 = 0.05;
fb2 = 0.05;
chinaC = round(roundn((135-73)/fb1,-2));
chinaR =  round(roundn((54-18)/fb2,-2));
GRD = zeros(chinaR,chinaC);
fillin =[];
Filelist = dir([pPM25path,'*.csv']);
% 152:length(Filelist)
for i = 274:length(Filelist)
    disp(['执行文件数' num2str(i) ',共' num2str(length(Filelist)) '个文件']);
    pYearStr = Filelist(i).name(13:16);
    pMonthStr = Filelist(i).name(17:18);
    pDayStr = Filelist(i).name(19:20);

    for BJhour = 0:23
        pHourStr = num2str(BJhour);
        pYear = str2double(pYearStr);
        pMonth = str2double(pMonthStr);
        pDay = str2double(pDayStr);
        pHour = BJhour;
    
        clear mO3 ;
        clear mO3data ;
        clear mO3textdata ;
        pDelimiterIn   = ','; % 字符分隔符
        pHeaderlinesIn = 1;   % 文件头的行数

        mNO2 = importdata([pPM25path,'china_sites_',pYearStr,pMonthStr,pDayStr,'.csv'], pDelimiterIn, pHeaderlinesIn);
        if(iscell(mNO2))
            continue;
        end
        mNO2data       = mNO2.data;
        mNO2textdata   = mNO2.textdata;
    
        pMDA8 = [];
        for m = 1:chinaR
            for n = 1:chinaC
            pStationIndex = find(mPM25LocationdataNUM(:,3) ==m  & mPM25LocationdataNUM(:,4) == n);
            if isempty(pStationIndex)
                continue
            end
            for q = 1:length(pStationIndex)
                pStationIndexNum = pStationIndex(q);
                %获取站点属性信息
                pStationName = mPM25LocationdataNAME(pStationIndexNum,2);
                pCity = mPM25LocationdataNAME(pStationIndexNum,3);
                pStationID = mPM25LocationdataNAME(pStationIndexNum,1);
                pStationLon = mPM25LocationdataNUM(pStationIndexNum,1);
                pStationLat = mPM25LocationdataNUM(pStationIndexNum,2);
                
                mO3data       = mNO2.data;
                mO3textdata   = mNO2.textdata;
                pO3StationCol = find(strcmp(mO3textdata(1,:),pStationID))';
                pO3StationRow = find(strcmp(mO3textdata(:,3),'O3') & strcmp(mO3textdata(:,2),pHourStr));
                    if(length(pO3StationCol) <= 0)
                        continue;
                    end
                    if(length(pO3StationRow) <= 0)
                        continue;
                    end
                    if (pO3StationCol  - 3 > size(mO3data,2))
                        continue;
                    end
                    pO3StationRow = pO3StationRow(pO3StationRow  - 1<= size(mO3data,1));
                    if (pO3StationRow  - 1 > size(mO3data,1))
                        continue;
                    end
                 pO3Value = mO3data(pO3StationRow  - 1,pO3StationCol  - 3);
%                  fillin(q) = max(pO3Value(pO3Value>0));
                 fillin(q) = max(pO3Value);
                 if(length(fillin) <= 0)
                    continue;
                 end
            end
             if isempty(fillin)
                 GRD(m,n) = 0;
                 continue
             end
             GRD(m,n) = max(fillin);
             fillin =[];
            end
        end
        data.GRD = GRD;
        
        UTCTimeStr = datestr(datetime(pYear,pMonth,pDay,pHour,0,0,'Format','yyyy-MM-dd HH:mm:ss') - 8/24,'yyyymmddHH');
    
        out_path = strcat('/data01/sg/2023-静止卫星臭氧光化学反演/中间数据/GRDdata/','GRD_',UTCTimeStr,'.mat');
        save(out_path,'-struct','data','*');
        GRD = zeros(chinaR,chinaC);
    end
end