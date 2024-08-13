clear all

pFilePath = '/data01/sg/静止卫星数据/UVindex/';
pSaveDatapath = '/data01/sg/数据处理备份/GEMS-UV-L3/p1/';

Filelist = dir([pFilePath '*.nc']);
pf = length(Filelist);

%% 指定中国的范围
GRID_LAT_RANGE = [18,54];
GRID_LONG_RANGE = [73,135];
GRID_GAP_LAT = 0.05;
GRID_GAP_LONG = 0.05;

%% 格网
GRID_LAT_RANGE = minmax(GRID_LAT_RANGE);
GRID_LONG_RANGE = minmax(GRID_LONG_RANGE);
GRID_BIN_LAT = GRID_LAT_RANGE(1):GRID_GAP_LAT:GRID_LAT_RANGE(2);
GRID_BIN_LONG = GRID_LONG_RANGE(1):GRID_GAP_LONG:GRID_LONG_RANGE(2);
GRID_EDGE_LAT = (GRID_LAT_RANGE(1):GRID_GAP_LAT:(GRID_LAT_RANGE(2)+GRID_GAP_LAT))-GRID_GAP_LAT/2;
GRID_EDGE_LONG = (GRID_LONG_RANGE(1):GRID_GAP_LONG:(GRID_LONG_RANGE(2)+GRID_GAP_LONG))-GRID_GAP_LONG/2;
data.Latitude = GRID_BIN_LAT;
data.Longitude = GRID_BIN_LONG;

grid_rows = length(data.Latitude);
grid_cols = length(data.Longitude);
mDay = -1;

data.GroudArea = ones(grid_rows,grid_cols,'single')*single(1e10);

total_num = pf;
cnt = 1;
for i = 3214:pf
    disp("执行文件数");
    disp(i);
    disp(Filelist(i))
    pPath = strcat(pFilePath,Filelist(i).name);
    pYearStr = Filelist(i).name(13:16);
    pMonthStr = Filelist(i).name(17:18);
    pDayStr = Filelist(i).name(19:20);
    pHourStr = Filelist(i).name(22:23);
    
    pYear = str2double (pYearStr);
    pMonth = str2double (pMonthStr);
    pDay = str2double (pDayStr);
    pHour = str2double (pHourStr);
    
    date_update = datetime([pYear pMonth pDay pHour 0 0]) +1/24;
    date_updateStr = datestr(date_update,'yyyymmddhh');
    pYearStr =date_updateStr(1:4);
    pMonthStr =date_updateStr(5:6);
    pDayStr =date_updateStr(7:8);
    pHourStr =date_updateStr(9:10);
    
    swaths.photolysis = ncread([pFilePath Filelist(i).name],'/Data Fields/SurfacePhotolysisFrequencyO(1D)');
    swaths.uvindex = ncread([pFilePath Filelist(i).name],'/Data Fields/UVIndex');
    swaths.Latitude = ncread([pFilePath Filelist(i).name],'/Geolocation Fields/Latitude');
    swaths.Longitude = ncread([pFilePath Filelist(i).name],'/Geolocation Fields/Longitude');
   
%     is_lat = min(swaths.Latitude,[],2) <= GRID_LAT_RANGE(2)+3 & max(swaths.Latitude,[],2) >= GRID_LAT_RANGE(1)-3;
%     swaths.photolysis = swaths.photolysis(is_lat,:);
%     swaths.uvindex = swaths.uvindex(is_lat,:);
%     swaths.Latitude = swaths.Latitude(is_lat,:);
%     swaths.Longitude = swaths.Longitude(is_lat,:);
%     
   %!!!!!! swath_latitude should look like swath.latitude, so as longitude
   [swaths_rows,swaths_cols] = size(swaths.Latitude);
    swaths_longitude = nan([swaths_rows+1,swaths_cols+1],class(swaths.Longitude));
    for r = 1:swaths_rows
      temp = 0.5:(swaths_cols+0.5);
      temp2 = 1:swaths_cols;
      swaths_longitude(r,~isnan(swaths.Longitude(r,:))) = interp1(temp2(~isnan(swaths.Longitude(r,:))),swaths.Longitude(r,~isnan(swaths.Longitude(r,:))),temp(~isnan(swaths.Longitude(r,:))),'pchip','extrap');
    end
    for c = 1:(swaths_cols+1)
      temp = 0.5:(swaths_rows+0.5); 
      temp2 = swaths_longitude(1:swaths_rows,c);
      temp3 = 1:swaths_rows;
      if isempty(temp2(~isnan(temp2)))
          continue
      end
      swaths_longitude(~isnan(temp2),c) = interp1(temp3(~isnan(temp2)),temp2(~isnan(temp2)),temp(~isnan(temp2)),'pchip','extrap');
    end
    swaths_latitude = nan([swaths_rows+1,swaths_cols+1],class(swaths.Latitude));
    for r = 1:swaths_rows
      temp = 0.5:(swaths_cols+0.5);
      temp2 = swaths.Latitude(r,:);
      temp3 = 1:swaths_cols;
      swaths_latitude(r,~isnan(temp2)) = interp1(temp3(~isnan(temp2)),temp2(~isnan(temp2)),temp(~isnan(temp2)),'pchip','extrap');
    end
    for c = 1:(swaths_cols+1)
      temp = 0.5:(swaths_rows+0.5); 
      temp2 = swaths_latitude(1:swaths_rows,c);
      temp3 = 1:swaths_rows;
      if isempty(temp2(~isnan(temp2)))
          continue
      end
      swaths_latitude(~isnan(temp2),c) = interp1(temp3(~isnan(temp2)),temp2(~isnan(temp2)),temp(~isnan(temp2)),'pchip','extrap');
    end
    swaths.area_long = nan(swaths_rows,swaths_cols,4,class(swaths_longitude));
    swaths.area_long(:,:,1) = swaths_longitude(1:swaths_rows  ,1:swaths_cols  );
    swaths.area_long(:,:,2) = swaths_longitude(1:swaths_rows  ,2:swaths_cols+1);
    swaths.area_long(:,:,3) = swaths_longitude(2:swaths_rows+1,2:swaths_cols+1);
    swaths.area_long(:,:,4) = swaths_longitude(2:swaths_rows+1,1:swaths_cols  );
    swaths.area_lat = nan(swaths_rows,swaths_cols,4,class(swaths_latitude));
    swaths.area_lat(:,:,1) = swaths_latitude(1:swaths_rows  ,1:swaths_cols  );
    swaths.area_lat(:,:,2) = swaths_latitude(1:swaths_rows  ,2:swaths_cols+1);
    swaths.area_lat(:,:,3) = swaths_latitude(2:swaths_rows+1,2:swaths_cols+1);
    swaths.area_lat(:,:,4) = swaths_latitude(2:swaths_rows+1,1:swaths_cols  );
    swaths.area = nan(swaths_rows,swaths_cols,class(swaths_latitude));
    
     % 定位
    grid.swaths_ridx = nan(length(GRID_BIN_LAT),length(GRID_BIN_LONG));
    grid.swaths_cidx = nan(length(GRID_BIN_LAT),length(GRID_BIN_LONG));
%         [grid_bin_lon,grid_bin_lat] = meshgrid(GRID_BIN_LONG,GRID_BIN_LAT);

%     grid_bin_lat = [18,18,54,54];
%     grid_bin_lon = [73,135,135,73];
    for r = 1:swaths_rows
      for c = 1:swaths_cols
        x = permute(swaths.area_long(r,c,:),[3,1,2]);
        y = permute(swaths.area_lat(r,c,:),[3,1,2]);
        
        [val,idx1]= min(abs(x(2)-GRID_BIN_LONG))  ;
        [val,idx2]= min(abs(x(4)-GRID_BIN_LONG))  ;
        [val,idx3]= min(abs(y(1)-GRID_BIN_LAT))  ;
        [val,idx4]= min(abs(y(3)-GRID_BIN_LAT))  ;
        grid_lon =GRID_EDGE_LONG(idx2)-GRID_GAP_LAT:GRID_GAP_LAT:GRID_EDGE_LONG(idx1)+GRID_GAP_LAT;
        grid_lat =GRID_EDGE_LAT(idx3)-GRID_GAP_LAT:GRID_GAP_LAT:GRID_EDGE_LAT(idx4)+GRID_GAP_LAT;
        [grid_bin_lon,grid_bin_lat] = meshgrid(grid_lon,grid_lat);
        [in_idx1,in_idx2] = find(inpolygon(grid_bin_lon, grid_bin_lat,x,y));
        
%         in_idx = find(inpolygon(grid_bin_lon(:), grid_bin_lat(:),x,y));
%         in_idx = find(inpolygon(y,x,grid_bin_lat(:), grid_bin_lon(:)));
        if ~isempty(in_idx1)
          grid.swaths_ridx(in_idx1+idx3-1,in_idx2+idx2-1) = r;
          grid.swaths_cidx(in_idx1+idx3-1,in_idx2+idx2-1) = c;
        end
        x = [x;x(1)];
        y = [y;y(1)];
        s=0;
        for t = 1:4
          a = x(t)*y(t+1)-x(t+1)*y(t);
          s = s+a;
        end
        swaths.area(r,c) = s*0.5;
      end
    end
    
     % 赋值
%     for r = 1:grid_rows
%       for c = 1:grid_cols
%         switch_ridx = grid.swaths_ridx(r,c);
%         switch_cidx = grid.swaths_cidx(r,c);
%         if ~isnan(switch_ridx) && ~isnan(switch_cidx)
%           if data.GroudArea(r,c) > swaths.area(switch_ridx,switch_cidx)
%             data.GroudArea(r,c) = swaths.area(switch_ridx,switch_cidx);
%             data.o3column(r,c,:) = swaths.o3column(switch_ridx,switch_cidx,:);
%           end
%         end
%       end
%     end

     data.photolysis=nan(grid_rows,grid_cols);
     data.uvindex=nan(grid_rows,grid_cols);
     for r = 1:grid_rows
      for c = 1:grid_cols
        switch_ridx = grid.swaths_ridx(r,c);
        switch_cidx = grid.swaths_cidx(r,c);
                                                                                                                                                                                                                                  if ~isnan(switch_ridx) && ~isnan(switch_cidx)
            data.GroudArea(r,c) = swaths.area(switch_ridx,switch_cidx);
            data.photolysis(r,c) = swaths.photolysis(switch_ridx,switch_cidx);
            data.uvindex(r,c) = swaths.uvindex(switch_ridx,switch_cidx);
        end
      end
     end
     
   % cnt 
%    os.F_ProgressBar(total_num,1,cnt);
%   cnt = cnt + 1;  
  
%     data.target = data.no2column;
    out_path = strcat(pSaveDatapath,pYearStr,'m',pMonthStr,pDayStr,'t',pHourStr,'UVColumnL3.mat');
    save(out_path,'-struct','data','*');

   clear swaths
   clear grids   
end