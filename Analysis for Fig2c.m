clear all


filepath2 = '/.../NO2/'; %change to HCHO or UV to analyze these variables
filelist = dir([filepath2 'Column_NO2' '*.tif']);



landusepath = '/.../';
landuse = load(landusepath).kind_label;

MDA8_path = '/.../';
site_idx = importdata(MDA8_path);
site_idx = site_idx>0;

urban_idx = (landuse==2 | landuse==3 ) ;
rural_idx  = (landuse==0);
mix_idx = (landuse==1 );

for i = 1:length(filelist)
    date(i) = str2num(filelist(i).name(12:19));
end

datelist = unique(date);
%% Original data collection
record_total =[];
for i = 1:length(datelist)
    file_idx = find(date(:)==datelist(i));
    pMonth = str2num(filelist(file_idx(1)).name(16:17));
    % 0 -Fall;  1 -Winter; 2 -Spring; 3 -Summer
    if pMonth<=2 || pMonth>=11
        pSeason = 1;
    elseif pMonth<=5 
        pSeason = 2;
    elseif pMonth<=8 
        pSeason = 3;
    else
        pSeason = 0;
    end
    for j = 1:length(file_idx)
        disp(filelist(file_idx(j)).name);
        pHour = str2num(filelist(file_idx(j)).name(end-5:end-4))+8;
        if pHour>24
            pHour = pHour-24;
        end
        NO2 = importdata([filepath2 filelist(file_idx(j)).name]);
        NO2_urban = NO2(urban_idx);
        NO2_urban = mean(NO2_urban(NO2_urban>0));
        NO2_rural = NO2(rural_idx);
        NO2_rural = mean(NO2_rural(NO2_rural>0));
        NO2_mix = NO2(mix_idx);
        NO2_mix = mean(NO2_mix(NO2_mix>0));
        record = [pSeason pHour NO2_urban NO2_rural NO2_mix];
        record_total = [record_total;record];
    end
end

save ([pSavepath,'diurnal_variation.mat'],'record_total');

Fall_diurnal = record_total(record_total(:,1)==0,:);
save ([pSavepath,'Fall_diurnal_variation.mat'],'Fall_diurnal');
Winter_diurnal = record_total(record_total(:,1)==1,:);
save ([pSavepath,'Winter_diurnal_variation.mat'],'Winter_diurnal');
Spring_diurnal = record_total(record_total(:,1)==2,:);
save ([pSavepath,'Spring_diurnal_variation.mat'],'Spring_diurnal');
Summer_diurnal = record_total(record_total(:,1)==3,:);
save ([pSavepath,'Summer_diurnal_variation.mat'],'Summer_diurnal');

%% Draw pics
set(gcf,'unit','normalized','position',[0.1,0.3,0.32,0.32]);
X = unique(Summer_diurnal(:,2));
position_urban = 0.75:1:9.75;
boxplot(Summer_diurnal(:,3),Summer_diurnal(:,2),'colors',[70/256 130/256 180/256],'positions',position_urban,'width',0.25,'symbol','','BoxStyle','filled');
hold on
position_rural = 1.25:1:10.25; 
boxplot(Summer_diurnal(:,4),Summer_diurnal(:,2),'colors',[60/256 179/256 113/256],'positions',position_rural,'width',0.25,'symbol','','BoxStyle','filled');
hold on
position_mix = 1:1:10; 
boxplot(Summer_diurnal(:,5),Summer_diurnal(:,2),'colors',[238/256 213/256 183/256],'positions',position_mix,'width',0.25,'symbol','','BoxStyle','filled');

set(gca,'XLim',[1.5 10.75]);                         
% set(gca,'YLim',[3e15 1.5e16]);                         

hTitle = title('NO2 Column diurnal patterns');
hXLabel = xlabel('Standard Beijing Time');
hYLabel = ylabel('NO2 Column Concentration (moles/cm2)');


set(gca, 'Box', 'on', ...                                       
         'LineWidth', 1,...                                    
         'XGrid', 'off', 'YGrid', 'off', ...                    
         'TickDir', 'in', 'TickLength', [.015 .015], ...         
         'XMinorTick', 'off', 'YMinorTick', 'off', ...           
         'XTick', [1:14],...
         'XColor', [.1 .1 .1],  'YColor', [.1 .1 .1])           


set(gca, 'FontName', 'Arial')
set([hXLabel, hYLabel], 'FontName', 'Arial')
set(gca, 'FontSize', 14)
set(hTitle, 'FontSize', 18, 'FontWeight' , 'bold')
t = findall(gca,'Tag','Box');
hLegend = legend(t([29 1 15]), {'Urban','Semi-urban','Rural'},'Position',[0.75 0.78 0.1 0.12]);
% xticklabels({'Heavy', 'Medium', 'Light'}); 
