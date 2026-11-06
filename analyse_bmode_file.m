function result = analyse_bmode_file(filePath, opts, outputFolder)
%ANALYSE_BMODE_FILE Noninteractive reproducible processing of one image.
%   RESULT = ANALYSE_BMODE_FILE(FILEPATH)
%   RESULT = ANALYSE_BMODE_FILE(FILEPATH, OPTS, OUTPUTFOLDER)
%   Full-frame metrics are calculated unless ROIs are selected in the GUI.
%   Output is only written if OUTPUTFOLDER is given.
%
    if nargin < 2, opts = struct(); end
    if nargin < 3, outputFolder = ''; end
    [I, info] = load_bmode_image(filePath);
    J = process_bmode_image(I, opts);
    originalMetrics = compute_bmode_metrics(I);
    processedMetrics = compute_bmode_metrics(J);
    result = struct('original',I,'processed',J,'imageInfo',info, ...
        'originalMetrics',originalMetrics,'processedMetrics',processedMetrics, ...
        'settings',opts);

    if ~isempty(outputFolder)
        if ~isfolder(outputFolder), mkdir(outputFolder); end
        imwrite(J, fullfile(outputFolder,'processed_bmode.png'));
        imwrite([I J], fullfile(outputFolder,'side_by_side_bmode.png'));
        before = originalMetrics; before.Stage = 'Original';
        after = processedMetrics; after.Stage = 'Processed';
        writetable(struct2table([before;after]), fullfile(outputFolder,'metrics.csv'));
        record = struct('ImageInfo',info, 'ProcessingOptions',opts, ...
            'Notes','Descriptive pixel-level features; no diagnostic ground truth.');
        f = fopen(fullfile(outputFolder,'analysis_settings.json'),'w');
        if f < 0, error('BMode:WriteFailed','Cannot write settings JSON.'); end
        cleaner = onCleanup(@() fclose(f));
        fprintf(f,'%s',jsonencode(record));
        clear cleaner
    end
end
