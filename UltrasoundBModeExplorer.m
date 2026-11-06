function UltrasoundBModeExplorer(inputFile)
%ULTRASOUNDBMODEEXPLORER Interactive B-mode ultrasound image exploration.
%   ULTRASOUNDBMODEEXPLORER opens an image-selection and analysis interface.
%   ULTRASOUNDBMODEEXPLORER(FILEPATH) opens a given still image.
%
    if nargin < 1, inputFile = ''; end
    state = struct('original',[],'processed',[],'imageInfo',[], ...
        'signalROI',[],'backgroundROI',[],'signalListener',[], ...
        'backgroundListener',[],'originalMetrics',[], ...
        'processedMetrics',[]);

    fig = uifigure('Name','Ultrasound B-mode Explorer', ...
        'Position',[100 80 1270 830]);
    root = uigridlayout(fig,[3 2]);
    root.RowHeight = {48,'1x',35};
    root.ColumnWidth = {320,'1x'};
    root.Padding = [12 10 12 10];
    root.RowSpacing = 8;

    heading = uilabel(root, 'Text','Ultrasound B-mode Image Explorer  |  Interactive image processing and ROI statistics', ...
        'FontWeight','bold','FontSize',18);
    heading.Layout.Row = 1; heading.Layout.Column = [1 2];

    controlPanel = uipanel(root,'Title','Analysis controls');
    controlPanel.Layout.Row = 2; controlPanel.Layout.Column = 1;
    cg = uigridlayout(controlPanel,[15 2]);
    cg.ColumnWidth = {120,'1x'};
    cg.RowHeight = repmat({32},1,15);
    cg.RowSpacing = 7;
    cg.Padding = [10 8 10 8];

    openBtn = uibutton(cg, 'Text','Open ultrasound image', ...
        'ButtonPushedFcn',@(~,~)chooseImage());
    place(openBtn,1,[1 2]);

    fgBtn = uibutton(cg, 'Text','Draw signal ROI', ...
        'ButtonPushedFcn',@(~,~)drawROI('signal'));
    place(fgBtn,2,1);
    bgBtn = uibutton(cg, 'Text','Draw background ROI', ...
        'ButtonPushedFcn',@(~,~)drawROI('background'));
    place(bgBtn,2,2);

    clearBtn = uibutton(cg,'Text','Clear both ROIs', ...
        'ButtonPushedFcn',@(~,~)clearROIs());
    place(clearBtn,3,[1 2]);

    place(uilabel(cg,'Text','Speckle filter'),4,1);
    denoiseDropdown = uidropdown(cg,'Items',{'None','Median','Wiener','Gaussian'}, ...
        'Value','Median');
    place(denoiseDropdown,4,2);

    place(uilabel(cg,'Text','Kernel size (odd)'),5,1);
    kernelField = uispinner(cg,'Limits',[1 15],'Step',2,'Value',3);
    place(kernelField,5,2);

    place(uilabel(cg,'Text','Gaussian sigma'),6,1);
    sigmaField = uispinner(cg,'Limits',[0.1 5],'Step',0.1,'Value',1);
    place(sigmaField,6,2);

    place(uilabel(cg,'Text','Contrast mode'),7,1);
    contrastDropdown = uidropdown(cg, ...
        'Items',{'None','CLAHE','Global equalization','Contrast stretch'}, ...
        'Value','CLAHE');
    place(contrastDropdown,7,2);

    place(uilabel(cg,'Text','CLAHE clip limit'),8,1);
    clipField = uispinner(cg,'Limits',[0 0.2],'Step',0.005,'Value',0.01);
    place(clipField,8,2);

    place(uilabel(cg,'Text','CLAHE tiles'),9,1);
    tilesDropdown = uidropdown(cg,'Items',{'4','8','16'},'Value','8');
    place(tilesDropdown,9,2);

    place(uilabel(cg,'Text','Gamma'),10,1);
    gammaField = uispinner(cg,'Limits',[0.2 3],'Step',0.1,'Value',1);
    place(gammaField,10,2);

    processBtn = uibutton(cg,'Text','Apply processing', ...
        'ButtonPushedFcn',@(~,~)refreshResults());
    place(processBtn,11,[1 2]);

    exportBtn = uibutton(cg,'Text','Export images and measurements', ...
        'ButtonPushedFcn',@(~,~)exportResults());
    place(exportBtn,12,[1 2]);

    resetBtn = uibutton(cg,'Text','Restore default settings', ...
        'ButtonPushedFcn',@(~,~)resetSettings());
    place(resetBtn,13,[1 2]);

    hint1 = uilabel(cg,'Text','1. Open a de-identified still ultrasound image.', ...
        'FontSize',11);
    place(hint1,14,[1 2]);
    hint2 = uilabel(cg,'Text','2. Draw ROIs on the ORIGINAL (left) image.', ...
        'FontSize',11);
    place(hint2,15,[1 2]);

    vg = uigridlayout(root,[2 2]);
    vg.Layout.Row = 2; vg.Layout.Column = 2;
    vg.RowHeight = {'1.35x','1x'};
    vg.ColumnWidth = {'1x','1x'};
    vg.Padding = [0 0 0 0];

    axOriginal = uiaxes(vg);
    axOriginal.Layout.Row = 1; axOriginal.Layout.Column = 1;
    title(axOriginal,'Original image');
    axProcessed = uiaxes(vg);
    axProcessed.Layout.Row = 1; axProcessed.Layout.Column = 2;
    title(axProcessed,'Processed image');
    axHistogram = uiaxes(vg);
    axHistogram.Layout.Row = 2; axHistogram.Layout.Column = 1;
    title(axHistogram,'Intensity distribution');
    xlabel(axHistogram,'Normalized intensity [0,1]');
    ylabel(axHistogram,'Pixel count');
    summaryArea = uitextarea(vg,'Editable','off','FontName','Courier New', ...
        'Value',{'Open an image to begin.','No measured results are included with this repository.'});
    summaryArea.Layout.Row = 2; summaryArea.Layout.Column = 2;

    statusLabel = uilabel(root,'Text','Ready. Load a real B-mode ultrasound image.');
    statusLabel.Layout.Row = 3; statusLabel.Layout.Column = [1 2];

    denoiseDropdown.ValueChangedFcn = @(~,~)refreshResults();
    kernelField.ValueChangedFcn = @(~,~)refreshResults();
    sigmaField.ValueChangedFcn = @(~,~)refreshResults();
    contrastDropdown.ValueChangedFcn = @(~,~)refreshResults();
    clipField.ValueChangedFcn = @(~,~)refreshResults();
    tilesDropdown.ValueChangedFcn = @(~,~)refreshResults();
    gammaField.ValueChangedFcn = @(~,~)refreshResults();

    if ~isempty(inputFile)
        openImage(inputFile);
    end

    function place(control,row,col)
        control.Layout.Row = row;
        control.Layout.Column = col;
    end

    function chooseImage()
        [name,path] = uigetfile( ...
            {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp;*.dcm;*.dicom', ...
            'Ultrasound still images'; '*.*','All files'}, ...
            'Choose a de-identified ultrasound image');
        if isequal(name,0), return; end
        openImage(fullfile(path,name));
    end

    function openImage(filePath)
        try
            [I,info] = load_bmode_image(filePath);
            clearROIs(false);
            state.original = I;
            state.imageInfo = info;
            cla(axOriginal);
            imagesc(axOriginal,I,[0 1]);
            colormap(axOriginal,gray(256));
            axis(axOriginal,'image');
            axOriginal.XTick = []; axOriginal.YTick = [];
            title(axOriginal,'Original | Draw ROIs here');
            refreshResults();
            statusLabel.Text = sprintf('Loaded image: %d x %d pixels. Draw ROIs as needed.',size(I,1),size(I,2));
        catch ME
            uialert(fig,ME.message,'Unable to load image');
        end
    end

    function opts = currentOptions()
        opts = struct('denoiseMethod',denoiseDropdown.Value, ...
            'kernelSize',round(kernelField.Value), ...
            'gaussianSigma',sigmaField.Value, ...
            'contrastMethod',contrastDropdown.Value, ...
            'claheClipLimit',clipField.Value, ...
            'claheTiles',str2double(tilesDropdown.Value), ...
            'gamma',gammaField.Value);
        if mod(opts.kernelSize,2)==0
            opts.kernelSize = min(opts.kernelSize+1,15);
            kernelField.Value = opts.kernelSize;
        end
    end

    function drawROI(which)
        if isempty(state.original)
            uialert(fig,'Open an image before drawing a region.','No image');
            return
        end
        try
            if strcmp(which,'signal')
                if ~isempty(state.signalROI) && isvalid(state.signalROI)
                    delete(state.signalROI);
                end
                state.signalROI = drawrectangle(axOriginal,'Color',[0.2 0.85 0.35]);
                state.signalListener = addlistener(state.signalROI,'ROIMoved',@(~,~)refreshResults());
            else
                if ~isempty(state.backgroundROI) && isvalid(state.backgroundROI)
                    delete(state.backgroundROI);
                end
                state.backgroundROI = drawrectangle(axOriginal,'Color',[0.95 0.65 0.2]);
                state.backgroundListener = addlistener(state.backgroundROI,'ROIMoved',@(~,~)refreshResults());
            end
            refreshResults();
        catch ME
            uialert(fig,ME.message,'ROI selection error');
        end
    end

    function clearROIs(doRefresh)
        if nargin < 1, doRefresh = true; end
        if ~isempty(state.signalROI) && isvalid(state.signalROI)
            delete(state.signalROI);
        end
        if ~isempty(state.backgroundROI) && isvalid(state.backgroundROI)
            delete(state.backgroundROI);
        end
        state.signalROI = []; state.backgroundROI = [];
        state.signalListener = []; state.backgroundListener = [];
        if doRefresh, refreshResults(); end
    end

    function [signalMask,backgroundMask] = getMasks()
        signalMask = [];
        backgroundMask = [];
        if isempty(state.original), return; end
        h = size(state.original,1); w = size(state.original,2);
        if ~isempty(state.signalROI) && isvalid(state.signalROI) && ...
                ~isempty(state.signalROI.Position)
            signalMask = createMask(state.signalROI,h,w);
        end
        if ~isempty(state.backgroundROI) && isvalid(state.backgroundROI) && ...
                ~isempty(state.backgroundROI.Position)
            backgroundMask = createMask(state.backgroundROI,h,w);
        end
    end

    function refreshResults()
        if isempty(state.original), return; end
        try
            J = process_bmode_image(state.original,currentOptions());
            [signalMask,backgroundMask] = getMasks();
            state.originalMetrics = compute_bmode_metrics(state.original,signalMask,backgroundMask);
            state.processedMetrics = compute_bmode_metrics(J,signalMask,backgroundMask);
            state.processed = J;

            cla(axProcessed);
            imagesc(axProcessed,J,[0 1]);
            colormap(axProcessed,gray(256));
            axis(axProcessed,'image');
            axProcessed.XTick = []; axProcessed.YTick = [];
            % Draw mirrored ROI outlines on the processed view so both
            % images can be compared at exactly the same pixel locations.
            hold(axProcessed,'on');
            if ~isempty(state.signalROI) && isvalid(state.signalROI) && ...
                    ~isempty(state.signalROI.Position)
                rectangle(axProcessed,'Position',state.signalROI.Position, ...
                    'EdgeColor',[0.2 0.85 0.35],'LineWidth',1.4);
            end
            if ~isempty(state.backgroundROI) && isvalid(state.backgroundROI) && ...
                    ~isempty(state.backgroundROI.Position)
                rectangle(axProcessed,'Position',state.backgroundROI.Position, ...
                    'EdgeColor',[0.95 0.65 0.2],'LineWidth',1.4);
            end
            hold(axProcessed,'off');
            title(axProcessed,'Processed | Matching ROI outlines');

            edges = linspace(0,1,65);
            mid = (edges(1:end-1) + edges(2:end))/2;
            c1 = histcounts(state.original(:),edges);
            c2 = histcounts(J(:),edges);
            cla(axHistogram);
            plot(axHistogram,mid,c1,'-','LineWidth',1.3);
            hold(axHistogram,'on');
            plot(axHistogram,mid,c2,'-','LineWidth',1.3);
            hold(axHistogram,'off');
            title(axHistogram,'Whole-image intensity histogram');
            xlabel(axHistogram,'Normalized intensity [0,1]');
            ylabel(axHistogram,'Pixel count');
            legend(axHistogram,{'Original','Processed'},'Location','best');
            xlim(axHistogram,[0 1]);

            a = state.originalMetrics; b = state.processedMetrics;
            roiText = 'Entire image (no signal ROI)';
            if a.SignalROISelected, roiText = 'Selected signal ROI'; end
            lines = { ...
                'DESCRIPTIVE INTENSITY METRICS', ...
                ['Region: ' roiText], ...
                '                        ORIGINAL      PROCESSED', ...
                sprintf('Mean intensity          %10.4f     %10.4f',a.SignalMean,b.SignalMean), ...
                sprintf('Standard deviation      %10.4f     %10.4f',a.SignalSD,b.SignalSD), ...
                sprintf('Coefficient of variation%10.4f     %10.4f',a.SignalCV,b.SignalCV), ...
                sprintf('Entropy (bits)          %10.4f     %10.4f',a.SignalEntropyBits,b.SignalEntropyBits), ...
                sprintf('Signal pixels           %10d     %10d',a.SignalROIPixels,b.SignalROIPixels), ...
                sprintf('CNR proxy               %10.4f     %10.4f',a.CNRProxy,b.CNRProxy), ...
                '', ...
                'CNR requires two distinct, nonoverlapping ROIs.', ...
                'Pixel metrics are NOT diagnostic accuracy.'};
            if a.ROIsOverlap
                lines{end+1} = 'WARNING: ROIs overlap; CNR omitted.';
            end
            summaryArea.Value = lines;
            statusLabel.Text = 'Settings applied. Drag ROI corners to update measurements.';
        catch ME
            statusLabel.Text = ['Analysis error: ' ME.message];
            uialert(fig,ME.message,'Processing error');
        end
    end

    function resetSettings()
        denoiseDropdown.Value = 'Median'; kernelField.Value = 3;
        sigmaField.Value = 1; contrastDropdown.Value = 'CLAHE';
        clipField.Value = 0.01; tilesDropdown.Value = '8';
        gammaField.Value = 1;
        refreshResults();
    end

    function exportResults()
        if isempty(state.original) || isempty(state.processed)
            uialert(fig,'Load an image and run processing before exporting.','Nothing to export');
            return
        end
        answer = uiconfirm(fig, ...
            ['Exporting may write identifiable anatomy or burned-in patient labels. ' ...
             'Confirm the source image is permitted for export and public sharing.'], ...
             'Image confidentiality check','Options',{'Continue','Cancel'}, ...
             'DefaultOption','Cancel','CancelOption','Cancel');
        if ~strcmp(answer,'Continue'), return; end
        folder = uigetdir(pwd,'Select a folder for the current measured results');
        if isequal(folder,0), return; end
        try
            [signalMask,backgroundMask] = getMasks();
            imwrite(state.processed,fullfile(folder,'processed_bmode.png'));
            imwrite([state.original state.processed],fullfile(folder,'side_by_side_bmode.png'));
            if ~isempty(signalMask)
                imwrite(signalMask,fullfile(folder,'signal_roi_mask.png'));
            end
            if ~isempty(backgroundMask)
                imwrite(backgroundMask,fullfile(folder,'background_roi_mask.png'));
            end
            orig = state.originalMetrics; orig.Stage = 'Original';
            proc = state.processedMetrics; proc.Stage = 'Processed';
            writetable(struct2table([orig;proc]),fullfile(folder,'metrics.csv'));
            record = struct('ImageInfo',state.imageInfo, ...
                'ProcessingOptions',currentOptions(), ...
                'HasSignalROI',~isempty(signalMask), ...
                'HasBackgroundROI',~isempty(backgroundMask), ...
                'Notes','Normalized pixel metrics only. No ground-truth diagnostic validation.');
            f = fopen(fullfile(folder,'analysis_settings.json'),'w');
            if f < 0, error('BMode:WriteFailed','Cannot create settings file.'); end
            closer = onCleanup(@() fclose(f));
            fprintf(f,'%s',jsonencode(record));
            clear closer
            % If exportgraphics is supported, include an actual measured histogram.
            try
                exportgraphics(axHistogram,fullfile(folder,'intensity_histogram.png'),'Resolution',160);
            catch
                % All essential data and metrics were saved successfully.
            end
            statusLabel.Text = 'Export complete. Review all images and labels before publishing.';
            uialert(fig,'Exported current processed images, settings and ROI measurements.', ...
                'Results saved','Icon','success');
        catch ME
            uialert(fig,ME.message,'Export failed');
        end
    end
end
