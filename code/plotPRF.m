function plotPRF(results,data,outPath)


%% modelPlotPRF

% Define some variables
vxs = results.meta.vxs;          % vector of analyzed vertices / voxels
fitThresh = 0.20;                   % R^2 threshold to display

% Instantial the model
class = results.model.class;
inputs = results.model.inputs;
opts = results.model.opts;
model = feval(class,data,inputs{:},opts{:});

% Pick the voxel with the best model fit
[~,tmp]=nanmax(results.R2(vxs));
vx = vxs(tmp);

% Prep the raw data
data = model.prep(data);

% Grab a time series
data2 = cellfun(@(x) x(vx,:),data,'UniformOutput',0);
data3 = @(vxs) cellfun(@(x) subscript(squish(x,1),{1 ':'})',data2,'UniformOutput',0);
datats = catcell(1,data3(1));
datats = model.clean(datats);

% Obtain the model fit
modelts = model.forward(results.params(vx,:));

% Visualize the model fit
fig1 = figure('visible','off');
set(fig1,'PaperOrientation','landscape');
set(fig1,'PaperUnits','normalized');
set(fig1,'PaperPosition', [0 0 1 1]);

hold on;
set(gcf,'Units','points','Position',[100 100 1000 100]);
plot(datats,'r-');
plot(modelts,'b-');
xlabel('Time (TRs)');
ylabel('BOLD signal');
ax = axis;
axis([.5 size(datats,1)+.5 ax(3:4)]);
title(['Time-series data, CIFTI vertex ' num2str(vx)]);

% Save the figure
plotFileName = fullfile(outPath,'exampleTimeSeriesFit.pdf');
print(fig1,plotFileName,'-dpdf','-fillpage')
close(fig1);

% Visualize the location of each voxel's pRF
fig2 = figure('visible','off');
hold on;

goodIdx = results.R2 > fitThresh;
set(gcf,'Units','points','Position',[100 100 400 400]);
h = scatter(results.cartX(goodIdx),results.cartY(goodIdx),...
    'o','filled', ...
    'MarkerFaceAlpha',1/8,'MarkerFaceColor','red');

currentunits = get(gca,'Units');
set(gca, 'Units', 'Points');
axpos = get(gca,'Position');
set(gca, 'Units', currentunits);
markerWidth = (results.rfsize(goodIdx))./diff(xlim)*axpos(3); % Calculate Marker width in points
set(h, 'SizeData', markerWidth.^2)

% Highlight the pRF for which we have plotted a time series
hold on
h = scatter(results.cartX(vx),results.cartY(vx),...    
    'o', 'MarkerEdgeColor','blue','MarkerFaceColor','none');
currentunits = get(gca,'Units');
set(gca, 'Units', 'Points');
axpos = get(gca,'Position');
set(gca, 'Units', currentunits);
markerWidth = (results.rfsize(vx))./diff(xlim)*axpos(3); % Calculate Marker width in points
set(h, 'SizeData', markerWidth.^2)


xlabel('X-position (deg)');
ylabel('Y-position (deg)');
title('pRF centers and sizes in visual field degrees');

% Save the figure
plotFileName = fullfile(outPath,'visualFieldCoverage.pdf');
saveas(fig2,plotFileName)
close(fig2);

end