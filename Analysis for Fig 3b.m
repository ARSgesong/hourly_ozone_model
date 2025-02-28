clear all

filepath1 = '/.../TROPOMI/';
filepath2 = '/.../GEMS/';

filelist = dir([filepath1 '*.tif']);

landusepath = '/.../';
landuse = load(landusepath).kind_label;
urban_idx = (landuse==2 | landuse==3 ) ;
rural_idx  = (landuse==0);
mix_idx = (landuse==1 );

for i =1:pf
    disp(filelist(i).name);
    O3_TROPOMI(:,:,i) = importdata([filepath1 filelist(i).name]);
    O3_GEMS(:,:,i) = importdata([filepath2 filelist(i).name(1:11) 'MDA8_' filelist(i).name(12:end)]);
    nan_idx = O3_TROPOMI==0 | O3_GEMS==0;
    O3_TROPOMI(nan_idx)=nan;
    O3_GEMS(nan_idx)=nan;
end


bias = -(O3_TROPOMI-O3_GEMS);
bias(bias==0)=nan;
% bias_mean = nanmean(bias,3)./nanmean(O3_GEMS,3);
bias_mean = nanmean(bias,3);

pop_path = '/.../';
pop = importdata(pop_path);
maskfile = '/data01/sg/TsE1.shp';
map = shaperead(maskfile);
R=makerefmat('RasterSize',size(pop),'Latlim',[18 54],'Lonlim',[73 135]);
MASK=vec2mtx(map.Y,map.X,pop,R,'filled');
MASK = flip(MASK);
MASK = logical(MASK);

bias_mean(~MASK) = nan;

urban_idx = (landuse==2 & MASK ) ;
rural_idx = (landuse==0 & MASK);
mix_idx = (landuse==1 & MASK );



urban = bias_mean(urban_idx);
rural = bias_mean(rural_idx);
mix = bias_mean(mix_idx);

combineData = [urban',mix',rural'];        % 组合

group = [1*ones(size(urban))',2*ones(size(mix))',3*ones(size(rural))'];  

boxplot(combineData,group,'Symbol','o','OutlierSize',3,'Colors',[0,0,0],sym=' ');
ax=gca;hold on;
ax.LineWidth=1.1;
ax.FontSize=12;
ax.FontName='Arial';
ax.XTickLabel={'Urban','Semi-urban','Rural'};
ax.Title.String='Differences between GEMS and TROPOMI';
ax.Title.FontSize=14;
ax.YLabel.String='\Delta ozone concentration';

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
C7=[126,15,4;122,117,119;255,163,25;135,146,73;30,93,134]./255;
colorList=C7;


boxObj=findobj(gca,'Tag','Box');
for i=1:length(boxObj)
    patch(boxObj(i).XData,boxObj(i).YData,colorList(length(boxObj)+1-i,:),'FaceAlpha',0.5,...
        'LineWidth',1.1);
end

set(gca,'YLim',[-20 20]);               
