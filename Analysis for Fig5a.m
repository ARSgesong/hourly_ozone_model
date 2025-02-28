clear all

filepath = '/.../mortality/';
pop_path = '/.../';
shp_path = '/.../shp/';
maskfile = '/TsE1.shp';
filelist = dir([filepath 'mortality_MDA8_GEMS_all_*.mat']);
shp_list = dir([shp_path 'MASK_*.mat']);
pop = importdata(pop_path);
landusepath = '/.../';
landuse = load(landusepath).kind_label;
urban_idx = (landuse==2 | landuse==3) ;
rural_idx  =(landuse==0);
mix_idx = (landuse==1  );
map = shaperead(maskfile);
R=makerefmat('RasterSize',size(pop),'Latlim',[18 54],'Lonlim',[73 135]);
MASK=vec2mtx(map.Y,map.X,pop,R,'filled');
MASK = flip(MASK);
MASK = logical(MASK);
mortality = [];

province_name = [];
for i = 1:length(filelist)
    pYearStr = filelist(i).name(end-9:end-6);
    pMonthStr = filelist(i).name(end-5:end-4);
    
    mortality_MDA8_GEMS_all = importdata([filepath filelist(i).name]);
    mortality_MDA8_GEMS_cardio = importdata([filepath 'mortality_MDA8_GEMS_cardio_' filelist(i).name(end-9:end)]);
    mortality_MDA8_GEMS_respiratory = importdata([filepath 'mortality_MDA8_GEMS_respi_' filelist(i).name(end-9:end)]);
    mortality_MDA8_TROPOMI_all = importdata([filepath 'mortality_MDA8_TROPOMI_all_' filelist(i).name(end-9:end)]);
    mortality_MDA8_TROPOMI_cardio = importdata([filepath 'mortality_MDA8_TROPOMI_cardio_' filelist(i).name(end-9:end)]);
    mortality_MDA8_TROPOMI_respiratory = importdata([filepath 'mortality_MDA8_TROPOMI_respi_' filelist(i).name(end-9:end)]);

    
    for j = 1:length(shp_list)
        disp(shp_list(j).name(6:end-4));
        province_name{j} = shp_list(j).name(6:end-4);
        MASK_province = load([shp_path shp_list(j).name]).MASK;
        province_mortality_MDA8_GEMS_all = mortality_MDA8_GEMS_all(MASK_province);
        province_mortality_MDA8_GEMS_cardio = mortality_MDA8_GEMS_cardio(MASK_province);
        province_mortality_MDA8_GEMS_respiratory = mortality_MDA8_GEMS_respiratory(MASK_province);
        province_mortality_MDA8_TROPOMI_all = mortality_MDA8_TROPOMI_all(MASK_province);
        province_mortality_MDA8_TROPOMI_cardio = mortality_MDA8_TROPOMI_cardio(MASK_province);
        province_mortality_MDA8_TROPOMI_respiratory = mortality_MDA8_TROPOMI_respiratory(MASK_province);
        
        GEMS_all_cause(j,str2num(pMonthStr)) = sum(province_mortality_MDA8_GEMS_all(province_mortality_MDA8_GEMS_all>0 & province_mortality_MDA8_TROPOMI_all>0)); 
        GEMS_cardio(j,str2num(pMonthStr)) = sum(province_mortality_MDA8_GEMS_cardio(province_mortality_MDA8_GEMS_cardio>0 & province_mortality_MDA8_TROPOMI_cardio>0)); 
        GEMS_respi(j,str2num(pMonthStr)) = sum(province_mortality_MDA8_GEMS_respiratory(province_mortality_MDA8_GEMS_respiratory>0 & province_mortality_MDA8_TROPOMI_respiratory>0)) ; 
        
        TROPOMI_all_cause(j,str2num(pMonthStr)) = sum(province_mortality_MDA8_TROPOMI_all(province_mortality_MDA8_TROPOMI_all>0)); 
        TROPOMI_cardio(j,str2num(pMonthStr)) = sum(province_mortality_MDA8_TROPOMI_cardio(province_mortality_MDA8_TROPOMI_cardio>0)); 
        TROPOMI_respi(j,str2num(pMonthStr)) = sum(province_mortality_MDA8_TROPOMI_respiratory(province_mortality_MDA8_TROPOMI_respiratory>0)) ; 
    end
end
deviation_all_cause = (TROPOMI_all_cause-GEMS_all_cause)./GEMS_all_cause.*100;
deviation_cardio = (TROPOMI_cardio-GEMS_cardio)./GEMS_cardio.*100;
deviation_respi = (TROPOMI_respi-GEMS_respi)./GEMS_respi.*100;

deviation_all_cause(GEMS_all_cause<10) = nan;
deviation_cardio(GEMS_cardio<10) = nan;
deviation_respi(GEMS_respi<10) = nan;

clims = [0 80];
mycolorpoint=flip([[0 0 166];...
    [8 69 99];...
    [57 174 156];...
    [198 243 99];...
    [222 251 123];...
    [255 255 255]]);
mycolorposition=[0 20 40 60 80 100];
mycolormap_r=interp1(mycolorposition,mycolorpoint(:,1),0:80,'linear','extrap');
mycolormap_g=interp1(mycolorposition,mycolorpoint(:,2),0:80,'linear','extrap');
mycolormap_b=interp1(mycolorposition,mycolorpoint(:,3),0:80,'linear','extrap');
mycolor=[mycolormap_r',mycolormap_g',mycolormap_b']./256;
mycolor=round(mycolor*10^4)/10^4;

set(gcf,'unit','normalized','position',[0.1,0.1,0.24,0.64])
X = deviation_all_cause(:,3:10);
% X = deviation_cardio(:,3:10);
% X = deviation_respi(:,3:8);
xname = {'Mar','Apr','May','Jun','Jul','Aug','Sep','Oct'};
% xname = {'Mar','Apr','May','Jun','Jul','Aug'};
yname = province_name;
h = heatmap(xname,yname,X) ;
h.CellLabelColor = 'none';
colormap(gca, mycolor)
set(gca,'FontSize',15,'FontNAme','Arial');
title('Deviated mortality (%)')
