# Conformal Risk Control under Non-Monotone Losses

Code accompanying the manuscript **"Conformal Risk Control under Non-Monotone
Losses: Theory and Finite-Sample Guarantees"** (T. Aldirawi, Y. Li, and W. Guo).

> Preprint: arXiv:2604.01502 — *verify this link resolves before relying on it.*

## Overview

Standard conformal risk control (CRC) assumes the loss is monotone in the
threshold. This repository implements the finite-sample correction and
experiments for the **non-monotone** case. For bounded, possibly non-monotone
losses over a grid of `m` candidate thresholds, selecting the threshold by the
standard CRC rule controls the risk up to an excess of order
`sqrt(log(m) / n)` in the calibration size `n`, and this rate is matched by a
minimax lower bound. Faster rates hold under Lipschitz losses, exact control is
recovered under monotone losses, and the guarantee extends to covariate and
label shift by importance weighting.

## Repository structure

- **Synthetic experiments** — synthetic multi-label simulations.
- **CRC vs. Learn-Then-Test / RCPS** — comparisons against LTT and RCPS under
  FDR and FNR losses.
- **Pima diabetes (FDR)** — an FDR experiment on the Pima diabetes benchmark.
- **COCO object detection** — an R + Python experiment
  (`run_coco_from_lossmatrix.R` and the COCO folder).

> Note: a couple of folder names currently contain a backslash
> (e.g. `CRC vs LTT\RCPS using FDR`). Renaming them to plain hyphenated names
> (see the setup notes) avoids cross-platform path issues.

## Requirements

- R >= 4.0
- Python >= 3.7 (only for the COCO object-detection experiment)
- ~10 GB free disk for the COCO 2017 validation set (~1.2 GB download)

Each experiment folder is self-contained; run its scripts from inside that
folder.

## Data

- The **COCO 2017** validation set is downloaded by the setup script and is
  distributed under the Creative Commons Attribution 4.0 license (this covers
  the dataset only, not the code in this repository).
- The **Pima diabetes** data is a standard public benchmark.

## Citation

```bibtex
@misc{aldirawi2026nonmonotonic,
  author = {Aldirawi, Tareq and Li, Yun and Guo, Wenge},
  title  = {Conformal Risk Control under Non-Monotone Losses:
            Theory and Finite-Sample Guarantees},
  year   = {2026},
  eprint = {2604.01502},
  archivePrefix = {arXiv},
  primaryClass  = {stat.ML}
}
```

## License

Released under the MIT License (see `LICENSE`). The COCO dataset retains its own
CC-BY 4.0 license.
