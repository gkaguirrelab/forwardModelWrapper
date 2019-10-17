function plotPRF(results,data,stimulus,outPath)


%% modelPlotPRF
% Visualize some results

% Define some variables
sizer = size(stimulus{1});
res = sizer(1:2);                   % row x column resolution of the stimuli
resmx = max(res);                   % maximum resolution (along any dimension)
hrf = results.options.hrf;          % HRF that was used in the model
degs = results.options.maxpolydeg;  % vector of maximum polynomial degrees used in the model
vxs = results.options.vxs;          % vector of analyzed vertices / voxels
fitThresh = 0.15;                   % R^2 threshold to display
plotSymbolScale = 100;              % The amount to scale up the plot symbols

% Pre-compute cache for faster execution
[~,xx,yy] = makegaussian2d(resmx,2,2,2,2);

% Prepare the stimuli for use in the model
stimulusPP = {};
for p=1:length(stimulus)
  stimulusPP{p} = squish(stimulus{p},2)';  % this flattens the image so that the dimensionality is now frames x pixels
  stimulusPP{p} = [stimulusPP{p} p*ones(size(stimulusPP{p},1),1)];  % this adds a dummy column to indicate run breaks
end

% Define the model function.  This function takes parameters and stimuli as input and
% returns a predicted time-series as output.  Specifically, the variable <pp> is a vector
% of parameter values (1 x 5) and the variable <dd> is a matrix with the stimuli (frames x pixels).
% Although it looks complex, what the function does is pretty straightforward: construct a
% 2D Gaussian, crop it to <res>, compute the dot-product between the stimuli and the
% Gaussian, raise the result to an exponent, and then convolve the result with the HRF,
% taking care to not bleed over run boundaries.
modelfun = @(pp,dd) modelCore(pp,dd,xx,yy,res,resmx,hrf);

% Construct projection matrices that fit and remove the polynomials.
% Note that a separate projection matrix is constructed for each run.
polymatrix = {};
for p=1:length(degs)
  polymatrix{p} = projectionmatrix(constructpolynomialmatrix(size(data{p},2),0:degs(p)));
end

%% Inspect the data and the model fit

% Pick the voxel with the best model fit
[~,tmp]=max(results.R2(vxs));
vx = vxs(tmp);

% For each run, collect the data and the model fit.  We project out polynomials
% from both the data and the model fit.  This deals with the problem of
% slow trends in the data.
datats = {};
modelts = {};
for p=1:length(data)
  datats{p} =  polymatrix{p}*data{p}(vx,:)';
  modelts{p} = polymatrix{p}*modelfun(results.params(1,:,vxs==vx),stimulusPP{p});
end

% Visualize the model fit
fig1 = figure('visible','off');
set(fig1,'PaperOrientation','landscape');
set(fig1,'PaperUnits','normalized');
set(fig1,'PaperPosition', [0 0 1 1]);

hold on;
set(gcf,'Units','points','Position',[100 100 1000 100]);
plot(cat(1,datats{:}),'r-');
plot(cat(1,modelts{:}),'b-');
xlabel('Time (s)');
ylabel('BOLD signal');
ax = axis;
axis([.5 size(datats{1},1)+.5 ax(3:4)]);
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
scatter(results.cartX(goodIdx),results.cartY(goodIdx),...
    results.rfsize(goodIdx)*plotSymbolScale,...
    'o','filled', ...
    'MarkerFaceAlpha',1/8,'MarkerFaceColor','red');
% Highlight the pRF for which we have plotted a time series
hold on
scatter(results.cartX(vx),results.cartY(vx),...
    results.rfsize(vx)*plotSymbolScale,...
    'o', 'MarkerEdgeColor','blue','MarkerFaceColor','none');
xlabel('X-position (deg)');
ylabel('Y-position (deg)');
title('pRF centers and sizes in visual field degrees');

% Save the figure
plotFileName = fullfile(outPath,'visualFieldCoverage.pdf');
saveas(fig2,plotFileName)
close(fig2);

end