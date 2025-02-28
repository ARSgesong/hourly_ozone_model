clear all

filepath = '/.../TROPOMI/';
filepath2 = '/.../GEMS/';


filelist = dir([filepath '*.tif']);

for i = 1:10
    disp(filelist(i).name);
    O3_TROPOMI = importdata([filepath filelist(i).name]);
    O3_GEMS = importdata([filepath2 filelist(i).name]);

    O3_difference = O3_GEMS - O3_TROPOMI;
%     O3_deviatrion = O3_difference./ O3_TROPOMI;
    O3_difference(O3_GEMS==0 | O3_TROPOMI==0) = 0;
    a = O3_difference > 0 ;
    b = O3_difference < 0 ;
    
    O3_GEMS_session(:,:,i) = O3_GEMS;

    O3_difference_year(:,:,i) = O3_difference;

    TIFdata = flip(O3_difference);
    fileName = [filepath3 filelist(i).name];
   
    
    DTM=TIFdata;                
    rasterSize=size(DTM);       
    latlim= [18,54];
    lonlim= [73,135];
    R = georefcells(latlim,lonlim,rasterSize);   
    geotiffwrite(fileName, DTM, R);    
    
    TIFdata = flip(b);
    fileName = [filepath4 filelist(i).name];
  
    
    DTM=TIFdata;               
    rasterSize=size(DTM);       
    latlim= [18,54];
    lonlim= [73,135];
    R = georefcells(latlim,lonlim,rasterSize);    
    geotiffwrite(fileName, DTM, R);    
    
end

O3_difference_year(O3_difference_year==0)=nan;
O3_difference_year = nanmean(O3_difference_year,3);
O3_difference_year(O3_difference_year==0)=nan;
TIFdata = flip(O3_difference_year);
TIFdata(isnan(TIFdata)) = 0;
fileName = [filepath3 'Surface_O3_yearly.tif'];


DTM=TIFdata;                 
rasterSize=size(DTM);       
latlim= [18,54];
lonlim= [73,135];
R = georefcells(latlim,lonlim,rasterSize);    
geotiffwrite(fileName, DTM, R);    

O3_GEMS_session(O3_GEMS_session==0)=nan;
O3_GEMS_session = nanmean(O3_GEMS_session,3);
O3_GEMS_session(O3_GEMS_session==0)=nan;
TIFdata = flip(O3_GEMS_session);
TIFdata(isnan(TIFdata)) = 0;
fileName = [filepath3 'Surface_O3_cool.tif'];
