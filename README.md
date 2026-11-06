# Ultrasound B-mode Image Analysis in MATLAB

**Interactive grayscale ultrasound processing, region-of-interest (ROI) analysis, and reproducible image statistics.**

This repository contains a MATLAB application and reusable processing functions for exploring **real still B-mode ultrasound images**. Users can change speckle-reduction and contrast settings, compare images, draw tissue/background ROIs, inspect pixel-intensity histograms, and export the measurements and processing settings.

This project develops the B-mode image-processing exercise used during preparation for an ultrasound research interview. It is an **educational image-analysis and research-software demonstration**, not a clinical decision-support tool. 

## Features

| Module | What it does |
|---|---|
| Interactive MATLAB GUI | Open a single real ultrasound image and adjust processing interactively |
| Speckle-oriented filtering | None, median (3×3 by default), adaptive Wiener, or Gaussian smoothing |
| Contrast processing | None, contrast-limited adaptive histogram equalization (CLAHE), global histogram equalization, or contrast stretching |
| Gamma control | Adjust grayscale display mapping |
| Original versus processed | Compare the same source image side-by-side with consistent normalized display limits |
| ROI measurement | Select a signal/tissue ROI and optionally a separate background ROI |
| Quantitative features | ROI mean, standard deviation, coefficient of variation, Shannon entropy, intensity range, and an optional CNR proxy |
| Intensity histogram | Compare original and processed whole-frame pixel distributions |
| Result export | Save processed image, comparison image, ROI masks, metrics CSV, settings JSON, and an image-derived histogram (where supported) |
| Scriptable workflow | Run the same processing functions without the GUI |
| Real-image parameter study | Generate a six-panel comparison from **your own image** when you run `compare_bmode_settings` |

## Repository structure

```text
ultrasound-bmode-matlab/
├── UltrasoundBModeExplorer.m       # Interactive MATLAB GUI
├── load_bmode_image.m             # Read and normalize one ultrasound still image
├── process_bmode_image.m          # Configurable grayscale image processing
├── compute_bmode_metrics.m        # ROI feature extraction
├── analyse_bmode_file.m           # Scriptable single-image workflow
├── compare_bmode_settings.m       # Optional real-image six-panel figure
├── tests/
│   └── run_smoke_tests.m          # Synthetic-array software checks, not research results
├── data/
│   └── README.md                  # Data sourcing / privacy guidance; no images included
├── figures/
│   └── README.md                  # Planned authentic result figures; none pre-generated
├── outputs/
│   └── README.md                  # Exported results are created by MATLAB, not supplied
├── docs/
│   ├── METHODOLOGY.md
│   ├── VALIDATION.md
│   └── FIGURE_CHECKLIST.md
├── .gitignore
└── README.md
```

## Requirements

- **MATLAB desktop or MATLAB Online** (R2021b or newer recommended; exact version compatibility has not yet been checked).
- **Image Processing Toolbox**, for functions including `medfilt2`, `wiener2`, `imgaussfilt`, `adapthisteq`, `drawrectangle`, and `createMask`.
- A **single de-identified still B-mode ultrasound image** in `.png`, `.jpg`, `.tif`, `.bmp`, or single-frame `.dcm` format. Multiple-frame DICOM video and ultrasound RF/IQ acquisition data are not supported.



## Quick start: interactive GUI

1. Download or clone the repository and open the folder in MATLAB. Make it the **Current Folder**, or add the repository root to the MATLAB path.
2. In the MATLAB Command Window, run:

   ```matlab
   UltrasoundBModeExplorer
   ```

3. Click **Open ultrasound image** and select a still image you are allowed to process.
4. Compare the original image with the automatically processed result.
5. Adjust the filter, kernel size, contrast method, CLAHE clip limit/tiles, and gamma. Changes refresh the analysis.
6. Click **Draw signal ROI**, then draw a rectangle over the tissue/region being studied **on the original image**. Optionally draw a distinct **background ROI** for the CNR proxy.
7. Drag/resize the ROIs to explore sensitivity. Keep ROIs in anatomically and visually defensible regions.
8. Click **Export images and measurements** to select a local destination. Review all exported images for private information before uploading them anywhere.

You can also launch with a specific image:

```matlab
UltrasoundBModeExplorer('path/to/deidentified_ultrasound.png')
```

**Note:** This is a MATLAB GUI created programmatically by an `.m` function. It is **not** a pre-built `.mlapp` App Designer file; open it by running the function above.

## Script-based use

The same pipeline can be run without a GUI:

```matlab
opts = struct( ...
    'denoiseMethod', 'Median', ...
    'kernelSize', 3, ...
    'gaussianSigma', 1.0, ...
    'contrastMethod', 'CLAHE', ...
    'claheClipLimit', 0.01, ...
    'claheTiles', 8, ...
    'gamma', 1.0);

result = analyse_bmode_file('path/to/deidentified_ultrasound.png', opts);

figure;
subplot(1,2,1); imshow(result.original); title('Original');
subplot(1,2,2); imshow(result.processed); title('Processed');
```

If you also provide an output destination, the script writes images, a CSV and settings:

```matlab
result = analyse_bmode_file('path/to/deidentified_ultrasound.png', ...
                            opts, 'my_local_results');
```

For an optional six-panel comparison using that **same real image**, run:

```matlab
compare_bmode_settings('path/to/deidentified_ultrasound.png');

% Save an actual image-derived figure when ready:
compare_bmode_settings('path/to/deidentified_ultrasound.png', ...
                       'figures/04_parameter_comparison.png');
```

This comparison is **not pre-generated** or populated with a substitute image.

The **noninteractive** function calculates **full-frame** intensity statistics; the **GUI** supports manually selected tissue and background ROIs. Neither mode estimates clinical or acoustic ground truth.

## What the settings mean

- **Median filtering** reduces impulsive variations using a local median; it can also alter fine anatomical features.
- **Wiener filtering** uses local estimated mean/variance to adapt smoothing; assumptions may not match actual multiplicative ultrasound speckle.
- **Gaussian filtering** smooths spatial detail and may blur interfaces.
- **CLAHE** improves local intensity contrast but can amplify noise or create visually misleading appearance. Its clip limit and tile count should be recorded.
- **Gamma adjustment** transforms image brightness/contrast mapping. A value of 1 leaves gamma unchanged.
- **Intensity normalisation** uses the input image's observed minimum and maximum to scale pixel values to [0,1]. Thus, results are **not comparable across different scans without an explicit acquisition/calibration protocol**.

See [Methodology and interpretation](docs/METHODOLOGY.md) for the calculation definitions and important limitations.

## Figures and experimental results

**No example ultrasound photographs, graphical outputs, or measurements are included in this starter repository.** All figures should come from a **specific real input image** you process with this code. The file `figures/README.md` lists suggested screenshot names and how to caption them accurately.

Suggested figures after running your image:

1. Original-versus-processed B-mode image (record settings and input source).
2. Histogram comparison for the same image.
3. ROI selection screenshot with mean/SD/entropy values.
4. Sensitivity comparison for selected CLAHE or denoising parameters, **if actually evaluated**.

A prettier result does **not** mean better diagnosis, restored anatomy, higher resolution, or successful speckle suppression. All examples must be labelled as processing demonstrations unless validated with suitable reference data.

## Data privacy and provenance

Medical images, including DICOM and exported PNG screenshots, may contain patient identifiers in metadata or *burned into the pixels*. The loader deliberately does not export DICOM patient metadata, but **does not anonymize the pixels**. Use only images for which you have permission and remove identifying overlays before publicly sharing any image. See [`data/README.md`](data/README.md).

## Software checks and validation status

Run the included checks from MATLAB:

Because `tests` is a regular subfolder, add it to the MATLAB path first:

```matlab
addpath('tests')
run_smoke_tests
```




## Scientific scope

This is a **2-D still-frame image-processing project**, not a SHAPE subharmonic ultrasound pressure-estimation implementation and not a clinical diagnostic algorithm. The statistics describe normalized grayscale pixel distributions. Validating anatomical accuracy, repeatability, diagnostic performance, or downstream biomarker associations would require independent reference data and a study-specific protocol.



## Selected MATLAB documentation

- [CLAHE: `adapthisteq`](https://www.mathworks.com/help/images/ref/adapthisteq.html)
- [Rectangle ROIs: `drawrectangle`](https://www.mathworks.com/help/images/ref/drawrectangle.html)
- [UI axes: `uiaxes`](https://www.mathworks.com/help/matlab/ref/uiaxes.html)
