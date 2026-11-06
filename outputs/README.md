# Local output files

MATLAB generates these files when a  image is opened and results are exported:

- `processed_bmode.png` — processed pixels of that image.
- `side_by_side_bmode.png` — original and processed pixels, horizontally concatenated.
- `intensity_histogram.png` — measured whole-frame histogram, if `exportgraphics` is supported.
- `signal_roi_mask.png` and `background_roi_mask.png` — if ROI rectangles were drawn.
- `metrics.csv` — normalized grayscale ROI descriptors for original and processed conditions.
- `analysis_settings.json` — source dimensions, min–max normalization metadata and processing parameters. Patient DICOM metadata and the source file path are not deliberately exported.

Nothing in this folder represents an output until you run MATLAB. Keep private or sensitive exports locally and add only safe, genuine results to `figures/`.
