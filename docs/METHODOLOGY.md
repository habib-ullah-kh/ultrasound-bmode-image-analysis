# Methodology and interpretation

## Intended input

One display-domain (typically log-compressed) **B-mode still image**. This is not RF or IQ ultrasound data. The project does not recover physical acoustic scattering amplitudes from display intensities. A grayscale input is normalized independently to [0,1] using its minimum and maximum; RGB files are converted to grayscale. For single-frame DICOM with MONOCHROME1 interpretation, intensities are inverted after normalization.

## Preprocessing order

1. Load one image and min–max normalize grayscale to `[0,1]`. Constant-valued images become zero.
2. Apply one optional local filter: median, local adaptive Wiener, Gaussian, or none.
3. Apply one optional contrast method: CLAHE, global histogram equalization, contrast stretching using the 1st and 99th intensity percentiles, or none.
4. Apply gamma mapping to the processed image.
5. Compare original and processed in matched display ranges; keep ROI locations consistent between conditions.
6. Compute descriptive metrics for the selected tissue ROI (or full frame if no ROI was drawn). If a **different and nonoverlapping** background ROI was drawn, compute a CNR proxy.

## Feature definitions

Let `x_i` be the normalized pixel intensities in the selected tissue ROI, and let `n` be its number of pixels:

- **Mean:** `mu = sum(x_i) / n`.
- **Population standard deviation:** `sigma = sqrt(sum((x_i - mu)^2) / n)`.
- **Coefficient of variation:** `sigma / max(abs(mu), eps)`. Sensitive to low mean intensity; not a calibrated speckle estimator.
- **Entropy:** `-sum_k p_k log2(p_k)` from a 256-bin normalized intensity histogram. Describes the intensity distribution, not anatomical information content.
- **Intensity minimum and maximum:** observed values in the selected ROI.
- **CNR proxy:** `abs(mu_tissue - mu_background) / sqrt(sigma_tissue^2 + sigma_background^2)`. Reported only when **both** ROI masks are explicitly selected, do not overlap, and their combined variance is nonzero. Other CNR definitions exist, and this pixel-based metric is not calibrated or a validated diagnostic CNR.

The full-frame histogram uses 64 bins. Histogram binning is distinct from the 256 bins used for ROI entropy. Mask area is in **pixels**, not square millimetres; no spatial calibration is performed.

## Limitations

- **Brightness is not sound pressure**. B-mode display grayscale values depend on acquisition settings, compression, and postprocessing.
- **Apparent contrast improvements can amplify noise or artifacts** and can destroy subtle image structure.
- A reduction in ROI variance alone does not establish improved speckle suppression or preservation of anatomy.
- A single ROI is subject to researcher selection bias; sensitivity to ROI placement should be assessed.
- Multiple images are **not quantitatively comparable** if they undergo different acquisition and per-image normalization without a defined calibration protocol.
- ROI statistics on pixels are descriptive, not clinical validation or a test of disease detection.
- Exported comparison images are suitable for demonstration, subject to consent, licence and de-identification checks.
- Multi-frame DICOM, Doppler video, raw RF and SHAPE pressure estimation are outside this project's scope.

## Recommended image study protocol

1. Document the source (dataset identifier or explicit permission), anatomy, frame, format and acquisition context where lawfully available.
2. Select and record the signal ROI; if estimating CNR, select a distinct background ROI.
3. Record original images and **all** processing settings before comparison.
4. Try one parameter at a time while keeping ROI position fixed.
5. Save actual outputs through the application's export function.
6. Report qualitative appearance, ROI pixel metrics and methodological limitations without causal or diagnostic claims.
7. Check public figures for patient identifiers or personally revealing details.
