function compare_bmode_settings(filePath, outputPath)
%COMPARE_BMODE_SETTINGS Display an actual image with six processing settings.
%   COMPARE_BMODE_SETTINGS(FILEPATH) opens a 2x3 comparison figure.
%   COMPARE_BMODE_SETTINGS(FILEPATH, OUTPUTPATH) additionally saves that
%   same image-derived comparison. No example data or results are bundled.

    if nargin < 2, outputPath = ''; end
    [I,~] = load_bmode_image(filePath);
    defaults = struct('denoiseMethod','Median','kernelSize',3, ...
        'gaussianSigma',1,'contrastMethod','CLAHE', ...
        'claheClipLimit',0.01,'claheTiles',8,'gamma',1);
    methods = cell(1,6);
    labels = { ...
        'Original (normalized)', ...
        'Median 3x3 + CLAHE (0.01)', ...
        'Wiener 3x3 + CLAHE (0.01)', ...
        'Gaussian sigma=1 + CLAHE (0.01)', ...
        'Median 3x3 only', ...
        'CLAHE only (clip 0.01)'};
    methods{1} = I;
    cfg = defaults;
    methods{2} = process_bmode_image(I,cfg);
    cfg.denoiseMethod = 'Wiener';
    methods{3} = process_bmode_image(I,cfg);
    cfg.denoiseMethod = 'Gaussian';
    methods{4} = process_bmode_image(I,cfg);
    cfg.denoiseMethod = 'Median'; cfg.contrastMethod = 'None';
    methods{5} = process_bmode_image(I,cfg);
    cfg.denoiseMethod = 'None'; cfg.contrastMethod = 'CLAHE';
    methods{6} = process_bmode_image(I,cfg);

    fig = figure('Name','B-mode processing parameter comparison', ...
        'Color','w','Position',[100 100 1250 780]);
    layout = tiledlayout(fig,2,3,'Padding','compact','TileSpacing','compact');
    for k = 1:6
        ax = nexttile(layout);
        imshow(methods{k},[0 1],'Parent',ax);
        title(ax,labels{k},'FontSize',10);
    end
    sgtitle(layout,'Real input frame: appearance comparison (not diagnostic validation)');
    if ~isempty(outputPath)
        exportgraphics(fig,outputPath,'Resolution',180);
    end
end
