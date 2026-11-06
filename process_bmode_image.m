function J = process_bmode_image(I, opts)
%PROCESS_BMODE_IMAGE Process one normalized 2-D B-mode image.
%   J = PROCESS_BMODE_IMAGE(I, OPTS) performs optional speckle reduction,
%   contrast enhancement and gamma adjustment (in that order).
%   I and J are grayscale doubles in [0,1]. Processing changes appearance;
%   it is not proof of improved diagnostic performance.
%
    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    validateattributes(I, {'double'}, {'2d','nonempty','real','finite','>=',0,'<=',1});
    defaults = struct('denoiseMethod','Median', 'kernelSize',3, ...
        'gaussianSigma',1.0, 'contrastMethod','CLAHE', ...
        'claheClipLimit',0.01, 'claheTiles',8, 'gamma',1.0);
    fields = fieldnames(defaults);
    for k = 1:numel(fields)
        f = fields{k};
        if ~isfield(opts,f) || isempty(opts.(f))
            opts.(f) = defaults.(f);
        end
    end

    k = opts.kernelSize;
    validateattributes(k, {'numeric'}, {'scalar','integer','positive','<=',15});
    if mod(k,2) == 0
        error('BMode:EvenKernel', 'Filter kernelSize must be an odd integer.');
    end
    validateattributes(opts.gaussianSigma, {'numeric'}, {'scalar','real','finite','positive'});
    validateattributes(opts.claheClipLimit, {'numeric'}, {'scalar','real','finite','>=',0,'<=',1});
    validateattributes(opts.claheTiles, {'numeric'}, {'scalar','integer','>=',2,'<=',32});
    validateattributes(opts.gamma, {'numeric'}, {'scalar','real','finite','positive'});

    J = I;
    switch lower(char(opts.denoiseMethod))
        case 'none'
        case 'median'
            J = medfilt2(J, [k k], 'symmetric');
        case 'wiener'
            J = wiener2(J, [k k]);
        case 'gaussian'
            J = imgaussfilt(J, opts.gaussianSigma);
        otherwise
            error('BMode:UnknownDenoise', 'Unknown denoising method.');
    end
    J = min(max(J,0),1);

    switch lower(char(opts.contrastMethod))
        case 'none'
        case 'clahe'
            tileN = min([opts.claheTiles, size(J,1), size(J,2)]);
            tileN = max(tileN,2);
            J = adapthisteq(J, 'NumTiles',[tileN tileN], ...
                'ClipLimit',opts.claheClipLimit);
        case 'global equalization'
            J = histeq(J);
        case 'contrast stretch'
            levels = stretchlim(J, [0.01 0.99]);
            if levels(2) > levels(1)
                J = imadjust(J, levels, [0 1]);
            end
        otherwise
            error('BMode:UnknownContrast', 'Unknown contrast method.');
    end
    J = imadjust(min(max(J,0),1), [], [], opts.gamma);
    J = min(max(J,0),1);
end
