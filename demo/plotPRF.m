%% modelPlotPRF
% Visualize some results

% Define some variables
res = [108 108];                    % row x column resolution of the stimuli
resmx = 108;                        % maximum resolution (along any dimension)
hrf = results.options.hrf;          % HRF that was used in the model
degs = results.options.maxpolydeg;  % vector of maximum polynomial degrees used in the model

% Pre-compute cache for faster execution
[d,xx,yy] = makegaussian2d(resmx,2,2,2,2);

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
modelfun = @(pp,dd) conv2run(posrect(pp(4)) * (dd*[vflatten(placematrix(zeros(res),makegaussian2d(resmx,pp(1),pp(2),abs(pp(3)),abs(pp(3)),xx,yy,0,0) / (2*pi*abs(pp(3))^2))); 0]) .^ posrect(pp(5)),hrf,dd(:,prod(res)+1));

% Construct projection matrices that fit and remove the polynomials.
% Note that a separate projection matrix is constructed for each run.
polymatrix = {};
for p=1:length(degs)
  polymatrix{p} = projectionmatrix(constructpolynomialmatrix(size(data{p},2),0:degs(p)));
end

%% Inspect the data and the model fit

% Which voxel of the vxs should we inspect? 
vx = 34;

% For each run, collect the data and the model fit.  We project out polynomials
% from both the data and the model fit.  This deals with the problem of
% slow trends in the data.
datats = {};
modelts = {};
for p=1:length(data)
  datats{p} =  polymatrix{p}*data{p}(vxs(vx),:)';
  modelts{p} = polymatrix{p}*modelfun(results.params(1,:,vx),stimulusPP{p});
end

% Visualize the model fit
figure; hold on;
set(gcf,'Units','points','Position',[100 100 1000 100]);
plot(cat(1,datats{:}),'r-');
plot(cat(1,modelts{:}),'b-');
xlabel('Time (s)');
ylabel('BOLD signal');
ax = axis;
axis([.5 size(datats{1},1)+.5 ax(3:4)]);
title(['Time-series data, CIFTI vertex ' num2str(vxs(vx))]);

% Visualize the location of each voxel's pRF
figure; hold on;
set(gcf,'Units','points','Position',[100 100 400 400]);
cmap = jet(size(length(vxs),1));
scatter(modifiedResults.cartX(vxs),modifiedResults.cartY(vxs),...
    modifiedResults.rfsize(vxs)*200,...
    'o','filled', ...
    'MarkerFaceAlpha',1/8,'MarkerFaceColor','red');
xlabel('X-position (deg)');
ylabel('Y-position (deg)');
