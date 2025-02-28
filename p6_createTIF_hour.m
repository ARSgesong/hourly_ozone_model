clear all
filepath = ['/.../']; 
TIFpath = ['/.../'];
filelist = dir([filepath '*.mat']);

calcmean = 1; %!!!!!!
calctrend = 0; %!!!!!
hourlist = [23 0 1 2 3 4 5 6 7 8];
for hour_idx = 1:length(hourlist)
    meanvalue=[];
    hour_sum = 0;
    
    for i=1:length(filelist)
        load([filepath filelist(i).name]);
        if isempty(applyset)
            continue
        end
        disp("day of the image");
        disp(i);
        O3 = zeros([720 1240]);
    
        for j = 1:size(applyset,1)
            O3(applyset(j,4),applyset(j,5)) = applyset(j,36);
        end

        if applyset(j,10)==hourlist(hour_idx)
            meanvalue(:,:,i) = O3;
            meanvalue(meanvalue==0)=nan;
            hour_sum = hour_sum + 1;
        end
    end   
    
    meanvalue2 = nanmean(meanvalue,3);
    for m = 1:size(meanvalue,1)
        for n = 1:size(meanvalue,2)
        record = meanvalue(m,n,:);
        if sum(~isnan(record)) < (hour_sum.*0.4 )
            meanvalue2(m,n) = nan;
        end
        end
    end
    
    TIFdata = flip(meanvalue2);
    TIFdata(isnan(TIFdata)) = 0;

    fileName = [TIFpath 'Mean_Surface_O3_LT' num2str(hourlist(hour_idx)+8) '.tif'];
    %write georeference
    
    DTM=TIFdata;                 
    rasterSize=size(DTM);      
    latlim= [18,54];
    lonlim= [73,135];
    R = georefcells(latlim,lonlim,rasterSize);   
    geotiffwrite(fileName, DTM, R);   

end
