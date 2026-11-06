function [I, info] = load_bmode_image(filePath)
%LOAD_BMODE_IMAGE Read one B-mode ultrasound image as normalized grayscale.
%   [I, INFO] = LOAD_BMODE_IMAGE(FILEPATH) supports PNG, JPEG, TIFF, BMP,
%   and single-frame DICOM images. I is double in [0,1]. The minimum and
%   maximum raw pixel values are used for per-image normalization.
%
    if ~(ischar(filePath) || (isstring(filePath) && isscalar(filePath)))
        error('BMode:InvalidInput', 'filePath must be a string or character vector.');
    end
    filePath = char(filePath);
    if ~isfile(filePath)
        error('BMode:FileMissing', 'Image file does not exist.');
    end

    [~, ~, ext] = fileparts(filePath);
    ext = lower(ext);
    isDICOM = ismember(ext, {'.dcm', '.dicom'});

    if isDICOM
        dcmInfo = dicominfo(filePath);
        raw = dicomread(dcmInfo);
        if isfield(dcmInfo,'NumberOfFrames') && double(dcmInfo.NumberOfFrames) > 1
            error('BMode:MultiFrame', ...
                'Multi-frame DICOM is not supported; export one permitted still frame.');
        end
        if ndims(raw) == 3 && size(raw,3) == 3 && ...
                isfield(dcmInfo,'PhotometricInterpretation') && ...
                ~strcmpi(strtrim(dcmInfo.PhotometricInterpretation),'RGB')
            error('BMode:MultiFrame', '3-D grayscale DICOM data are not supported.');
        end
        if ndims(raw) > 3 || (ndims(raw) == 3 && size(raw,3) ~= 3 && size(raw,3) ~= 1)
            error('BMode:MultiFrame', ...
                'This viewer supports one still frame. Export one frame from a multi-frame DICOM.');
        end
        if isfield(dcmInfo, 'PhotometricInterpretation')
            invertGray = strcmpi(strtrim(dcmInfo.PhotometricInterpretation), 'MONOCHROME1');
        else
            invertGray = false;
        end
    else
        supported = {'.png','.jpg','.jpeg','.tif','.tiff','.bmp'};
        if ~ismember(ext, supported)
            error('BMode:UnsupportedFormat', ...
                'Supported formats are PNG, JPG, TIF, BMP and single-frame DICOM.');
        end
        raw = imread(filePath);
        invertGray = false;
    end

    raw = squeeze(raw);
    if ndims(raw) == 3 && size(raw,3) == 3
        raw = rgb2gray(raw);
    end
    if ~ismatrix(raw) || ~isnumeric(raw) && ~islogical(raw)
        error('BMode:Not2D', 'Input must contain one 2-D grayscale or RGB frame.');
    end
    if min(size(raw)) < 16
        error('BMode:ImageTooSmall', 'Image must be at least 16 by 16 pixels.');
    end

    raw = double(raw);
    if any(~isfinite(raw(:)))
        error('BMode:NonFinite', 'Image contains Inf or NaN pixel values.');
    end
    low = min(raw(:));
    high = max(raw(:));
    if high > low
        I = (raw - low) ./ (high - low);
    else
        I = zeros(size(raw));
    end
    if invertGray
        I = 1 - I;
    end

    % Deliberately exclude patient information and original file name.
    info = struct('Height', size(I,1), 'Width', size(I,2), ...
        'SourceFormat', ext, 'RawMinimum', low, 'RawMaximum', high, ...
        'PerImageMinMaxNormalization', true, 'InvertedMONOCHROME1', invertGray);
end
