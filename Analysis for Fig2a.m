clear all

filepath = '/.../'; %applyset for TROPOMI
filepath2 = '/.../'; %applyset for GEMS
filepath3 = '/.../'; %savepath

filelist = dir([filepath '*.mat']);

pPM25Spath = '/.../'; % site location file
pPM25SpathSheet = 'Sheet1';
pPM25SpathRange = 'A2:G2027';
pPM25path = '/.../'; % site monitored air pollution


[mPM25LocationdataNUM,mPM25LocationdataNAME] = xlsread(pPM25Spath,pPM25SpathSheet,pPM25SpathRange);

record_total = [];
applyset_TROPOMI = importdata(filepath3);

landusepath = '/.../'; % landuse filepath
landuse = load(landusepath).kind_label;
urban_idx = (landuse==2 | landuse==3 ) ;
rural_idx  = (landuse==0);
mix_idx = (landuse==1 );

applyset_GEMS = importdata(filepath2);

for i = 1:pf
    disp(filelist(i).name);
    applyset = importdata([filepath filelist(i).name]);
    applyset_filter = applyset(applyset(:,28)>0,:);
%     applyset_GEMS = importdata([filepath2 'Surface_O3_MDA8_' filelist(i).name(end-11:end-4) '.tif']);
    for m = 1:length(applyset_filter)
        record(m,1) = applyset_filter(m,28);
        record(m,2) = applyset_filter(m,36);
%         record(m,3) = applyset_GEMS(applyset_filter(m,4),applyset_filter(m,5));
        record(m,4) = applyset_filter(m,4);
        record(m,5) = applyset_filter(m,5);
        record(m,6:8) = applyset_filter(m,7:9);
        idx = find(applyset_TROPOMI(:,4) == applyset_filter(m,4) & applyset_TROPOMI(:,5) == applyset_filter(m,5) & applyset_TROPOMI(:,7) == applyset_filter(m,7) & applyset_TROPOMI(:,8) == applyset_filter(m,8)& applyset_TROPOMI(:,9) == applyset_filter(m,9));
        idx2 = find(applyset_GEMS(:,1) == applyset_filter(m,4) & applyset_GEMS(:,2) == applyset_filter(m,5) & applyset_GEMS(:,3) == applyset_filter(m,7) & applyset_GEMS(:,4) == applyset_filter(m,8)& applyset_GEMS(:,5) == applyset_filter(m,9));
        if isempty(idx) | isempty(idx2)
            continue
        end
        record(m,2) = applyset_TROPOMI(idx,37);
        record(m,3) = applyset_GEMS(idx2,6);
    end
    if isempty(record)
        continue
    end
    record = record(record(:,2)>0 & record(:,3)>0,: );
    record_total = [record_total;record];
    record = [];
end


for j = 1:size(mPM25LocationdataNUM,1)
    disp(j);
    X = mPM25LocationdataNUM(j,3);
    if isnan(X) | isnan(mPM25LocationdataNUM(j,1)) | X>720
        continue
    end
    Y = mPM25LocationdataNUM(j,4);
    site_idx = find(record_total(:,4) == X & record_total(:,5) == Y);
    record = record_total(site_idx,:);
    ARF1=double(record(:,1));
    BRF1=double(record(:,3));
    
    r = 1 - sum((ARF1 - BRF1).^2)/sum((ARF1 - mean(ARF1)).^2);
        
    RMSE =sqrt(mean((ARF1 - BRF1).^2));
    bias = mean(abs(ARF1 - BRF1));
    mPM25LocationdataNUM(j,5) = r;
    mPM25LocationdataNUM(j,6) = bias;

    ARF1=double(record(:,1));
    BRF1=double(record(:,2));
    
    r = 1 - sum((ARF1 - BRF1).^2)/sum((ARF1 - mean(ARF1)).^2);
        
    RMSE =sqrt(mean((ARF1 - BRF1).^2));
    bias = mean(abs(ARF1 - BRF1));
    mPM25LocationdataNUM(j,7) = r;
    mPM25LocationdataNUM(j,8) = bias;

    mPM25LocationdataNUM(j,9) = urban_idx(X,Y);
    mPM25LocationdataNUM(j,10) = mix_idx(X,Y);
    mPM25LocationdataNUM(j,11) = rural_idx(X,Y);
end

site_enhance_R = mPM25LocationdataNUM;

urban = site_enhance_R(site_enhance_R(:,9)==1,4)' - site_enhance_R(site_enhance_R(:,9)==1,6)' ;
mix = site_enhance_R(site_enhance_R(:,10)==1,4)' - site_enhance_R(site_enhance_R(:,10)==1,6)' ;
rural = site_enhance_R(site_enhance_R(:,11)==1,4)' - site_enhance_R(site_enhance_R(:,11)==1,6)' ;

urban = urban(urban>0 & urban<1);
rural = rural(rural>0 & rural<1);
mix = mix(mix>0 & mix<1);

combineData = [urban,mix,rural];        % 组合

group = [1*ones(size(urban)),2*ones(size(mix)),3*ones(size(rural))];  

boxplot(combineData,group,'Symbol','o','OutlierSize',3,'Colors',[0,0,0])
ax=gca;hold on;
ax.LineWidth=1.1;
ax.FontSize=12;
ax.FontName='Arial';
ax.XTickLabel={'Urban','Semi-urban','Rural'};
ax.Title.String='Enhanced model accuracy of sites';
ax.Title.FontSize=14;
ax.YLabel.String='Enhanced R2';

lineObj=findobj(gca,'Type','Line');
for i=1:length(lineObj)
    lineObj(i).LineWidth=1;
    lineObj(i).MarkerFaceColor=[1,1,1].*.3;
    lineObj(i).MarkerEdgeColor=[1,1,1].*.3;
end

C1=[59 125 183;244 146 121;242 166 31;180 68 108;220 211 30]./255;
C2=[102,173,194;36,59,66;232,69,69;194,148,102;54,43,33]./255;
C3=[38,140,209;219,51,46;41,161,153;181,138,0;107,112,196]./255;
C4=[110,153,89;230,201,41;79,79,54;245,245,245;199,204,158]./255;
C5=[235,75,55;77,186,216;2,162,136;58,84,141;245,155,122]./255;
C6=[23,23,23;121,17,36;44,9,75;31,80,91;61,36,42]./255;
C7=[126,15,4;122,117,119;143,188,143;135,146,73;30,93,134]./255;
colorList=C7;


boxObj=findobj(gca,'Tag','Box');
for i=1:length(boxObj)
    patch(boxObj(i).XData,boxObj(i).YData,colorList(length(boxObj)+1-i,:),'FaceAlpha',0.5,...
        'LineWidth',1.1);
end

set(gca,'YLim',[-0.05 0.9]);               
