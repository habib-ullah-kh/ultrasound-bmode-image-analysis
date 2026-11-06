function metrics = compute_bmode_metrics(I, signalMask, backgroundMask)
%COMPUTE_BMODE_METRICS Descriptive statistics of normalized pixel values.
%   METRICS = COMPUTE_BMODE_METRICS(I, SIGNALMASK, BACKGROUNDMASK)
%   computes ROI mean, SD, coefficient of variation, entropy and a
%   difference-over-variation CNR proxy (only with nonoverlapping ROIs).
%   If SIGNALMASK is empty, the entire frame is used as the signal ROI.
%
    validateattributes(I, {'double'}, {'2d','real','finite','>=',0,'<=',1});
    if nargin < 2 || isempty(signalMask)
        signalMask = true(size(I));
        selectedSignal = false;
    else
        selectedSignal = true;
    end
    if nargin < 3 || isempty(backgroundMask)
        backgroundMask = false(size(I));
        selectedBackground = false;
    else
        selectedBackground = true;
    end

    if ~isequal(size(signalMask),size(I)) || ~isequal(size(backgroundMask),size(I))
        error('BMode:MaskSize', 'ROI masks must match image dimensions.');
    end
    signalMask = logical(signalMask);
    backgroundMask = logical(backgroundMask);
    if ~any(signalMask(:))
        error('BMode:EmptySignalROI', 'Signal ROI must contain pixels.');
    end

    sv = I(signalMask);
    mu = mean(sv);
    sigma = std(sv,1);
    [p,~] = histcounts(sv, linspace(0,1,257));
    p = p / max(sum(p),1);
    nonzero = p(p > 0);
    entropyBits = -sum(nonzero .* log2(nonzero));

    metrics = struct();
    metrics.SignalROIPixels = numel(sv);
    metrics.SignalROISelected = selectedSignal;
    metrics.SignalMean = mu;
    metrics.SignalSD = sigma;
    metrics.SignalCV = sigma / max(abs(mu),eps);
    metrics.SignalEntropyBits = entropyBits;
    metrics.SignalMinimum = min(sv);
    metrics.SignalMaximum = max(sv);
    metrics.BackgroundROISelected = selectedBackground;
    metrics.BackgroundROIPixels = 0;
    metrics.BackgroundMean = NaN;
    metrics.BackgroundSD = NaN;
    metrics.ROIsOverlap = false;
    metrics.CNRProxy = NaN;

    if selectedBackground
        if ~any(backgroundMask(:))
            error('BMode:EmptyBackgroundROI', 'Background ROI must contain pixels.');
        end
        bv = I(backgroundMask);
        metrics.BackgroundROIPixels = numel(bv);
        metrics.BackgroundMean = mean(bv);
        metrics.BackgroundSD = std(bv,1);
        metrics.ROIsOverlap = any(signalMask(:) & backgroundMask(:));
        if ~metrics.ROIsOverlap && selectedSignal
            denominator = sqrt(metrics.SignalSD^2 + metrics.BackgroundSD^2);
            if denominator > 1e-12
                metrics.CNRProxy = abs(mu - metrics.BackgroundMean) / denominator;
            end
        end
    end
end
