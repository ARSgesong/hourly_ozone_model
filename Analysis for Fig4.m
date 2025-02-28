clear all

filepath = '/.../GEMS/';

filelist = dir([filepath 'Surface_O3*.tif']);
filepath3 = '/.../TROPOMI/';
shp_path = '/.../shp/';
shp_list = dir([shp_path '*.shp']);

landusepath = '/../';
landuse = load(landusepath).kind_label;

for i = 1:length(filelist)
    date(i) = str2num(filelist(i).name(12:19));
end
 
 clear MASK*
%% Original data collection
urban_idx = (landuse==2 | landuse==3 ) ;
rural_idx  =(landuse==0);
mix_idx = (landuse==1 );
datelist = unique(date);
record_total =[];
 clear MASK*
shapelist = dir([shp_path 'MASK*.mat']);

for aa = 1:length(shapelist)
    eval(['O3_' shapelist(aa).name(6:end-4) '= [];' ]);
end


for i = 180:210
    pYear = floor(datelist(i)/10000);
    pMonth = floor((datelist(i) - pYear*10000)/100);
    pDay = mod(datelist(i),100);
%     if ~(pMonth >=6 & pMonth <=8)
%         continue
%     end
    
    file_idx1 = find(date(:)==datelist(i));
    
    for n = 1:length(shapelist)
        MASK = load([shp_path shapelist(n).name]).MASK;
        O3 = [];
        O3_province = [];
        for j = 1:length(file_idx1)
            disp(filelist(file_idx1(j)).name);
            try 
                O3_new = importdata([filepath filelist(file_idx1(j)).name]);
            catch
                continue
            end
            O3_new = O3_new(MASK);
            O3(:,j) = O3_new;
            O3_province(j,1) = str2num(filelist(file_idx1(j)).name(end-5:end-4));
        end
        try
            O3_TROPOMI = importdata([filepath3 'Surface_O3_' num2str(datelist(i)) '.tif']);
        catch
            continue
        end
        O3_TROPOMI = O3_TROPOMI(MASK);
        O3_TROPOMI(O3_TROPOMI==0)=nan;
        O3(O3==0) = nan;
        O3_province(:,2) = nanmean(O3,1);
        O3_province(:,3) = nanmean(O3_TROPOMI,1);
        eval(['O3_' shapelist(n).name(6:end-4) '= [' strcat('O3_',shapelist(n).name(6:end-4)) '; O3_province];' ]);
    end
end

for i = 1:length(shapelist)
    record_hour = [];
    province_name = shapelist(i).name(6:end-4);
    eval(['hourlist = unique(O3_' province_name '(:,1));' ]);
    eval(['O3_' province_name  '=' 'O3_' province_name '(O3_' province_name '(:,3)>0,:);' ]);
    for j = 1:length(hourlist)
        eval([ 'hour_idx = find(O3_' province_name '(:,1) == hourlist(j));' ]);
        record_hour(j,1) = hourlist(j);
        eval([ 'record_hour(j,2:3) = nanmean(O3_' province_name '(hour_idx,2:3));' ]);
    end
    MDA8 = max(movmean(record_hour(:,2),8));
    MDA1 = max(record_hour(:,2));
    ratio(1,i)= MDA8/nanmean(record_hour(:,3));
        ratio(2,i)= MDA1./MDA8;
        ratio(3,i)= std(record_hour(:,2))./MDA8;
        ratio(4,i)= MDA8;
%     ratio(i)= min(MDA8/nanmean(record_hour(:,3)),nanmean(record_hour(:,3))/MDA8);

    figure 
    set(gcf,'unit','normalized','position',[0.1,0.5,0.08,0.12]);%figture
    plot(record_hour(:,1),nanmean(record_hour(:,3))*ones(size(record_hour,1)),'--','color','k','LineWidth',1.5); 
    hold on 
%     plot(record_hour(:,1),MDA8*ones(size(record_hour,1)),'-.','color','k','LineWidth',1.5);
%     hold on 
    plot(record_hour(:,1),record_hour(:,2),'color',[0/256 0/256 128/256],'LineWidth',1.5);
    axis([8,20,0,200]) 
    set(gca,'XTick',[8,20]) 
    set(gca,'YTick',[0:100:200]) 
    set(gca,'FontSize',15);

    clims = [0.92 1.03];
%     mycolorpoint=[154/256 205/256 50/256; 255/256 106/256 106/256];
    mycolorpoint=[255/256 255/256 255/256; 255/256 171/256 91/256];

    mycolorposition=linspace(clims(2),clims(1),2);
    inp_100 = min(ratio(1,i),1);
    mycolormap_r=interp1(mycolorposition,mycolorpoint(:,1),inp_100,'linear','extrap');
    mycolormap_g=interp1(mycolorposition,mycolorpoint(:,2),inp_100,'linear','extrap');
    mycolormap_b=interp1(mycolorposition,mycolorpoint(:,3),inp_100,'linear','extrap');
    mycolor=[mycolormap_r',mycolormap_g',mycolormap_b'];

    set(gca, 'color', mycolor)
    set(gcf, 'color', 'w')
    set(gca,'FontSize',15,'FontNAme','Arial');
    title(province_name,'FontWeight','Normal')
%     title('Inner-Mongolia','FontWeight','Normal')
%   title('Tibet','FontWeight','Normal')
    set(gcf, 'InvertHardCopy', 'off');
    
end

a = ratio(1,:);
b = ratio(2,:);
c = ratio(4,:);

figure
bubblechart(abs(1-a),b-1,c,'#00868B');
hold on
lm = fitlm(abs(1-a), b-1, 'Poly1'); % '
 

x_fit = min(abs(1-a))-0.1:0.001:max(abs(1-a))+0.1;
y_fit = lm.Coefficients.Estimate(2) * x_fit + lm.Coefficients.Estimate(1);
 

hold on;
line(x_fit, y_fit, 'LineWidth', 2,'color',[205/256 173/256 0]); 
xlim([min(abs(1-a))-0.01 max(abs(1-a))+0.01])
