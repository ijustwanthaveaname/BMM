# BMM: Bayesian Mixture Model for Mendelian Randomization

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

MRBMM implements a robust Bayesian mixture model for Mendelian Randomization that explicitly models horizontal pleiotropy with automatic model selection.

### Key Features

✅ **Explicit pleiotropy modeling** - Handles UHP and CHP with 3/4-component models  
✅ **Automatic model selection** - LOO-CV based comparison  
✅ **Comprehensive harmonization** - Local plink-based proxy SNP search; harmonized data can be used directly with TwoSampleMR's **mr()** function to run multiple MR methods
✅ **Sample overlap correction** - Support for overlapping samples 
✅ **Parallel processing** - Multi-core MCMC sampling  

## Installation

### Install BMM

```r
# From GitHub
devtools::install_github("ijustwanthaveaname/MRBMM")

# Or from source
R CMD INSTALL MRBMM_1.0.0.tar.gz
```

### Prerequisites
#### Install cmdstanr, cmdstan, TwoSampleMR and ieugwasr using R
```r
# 1. Install cmdstanr
install.packages("cmdstanr", 
                repos = c("https://mc-stan.org/r-packages/", 
                         getOption("repos")))

# 2. Install CmdStan, TwoSampleMR and ieugwasr
cmdstanr::install_cmdstan()
remotes::install_github("MRCIEU/TwoSampleMR")
remotes::install_github("MRCIEU/ieugwasr")
# OR install in 1 line 
install_bmm_dependencies()
```
#### Install cmdstanr using conda
if failed use conda
`conda install -c conda-forge cmdstan`
Then, tell R where to find it
```r
library(cmdstanr)
set_cmdstan_path("PATH_TO_YOUR_CONDA_ENV/bin/cmdstan")
 # Usually: ~/miniconda3/bin/cmdstan 
```
#### Install plink and reference panel for clumping and proxy SNP searching
**PLINK v1.9**: Download from: https://www.cog-genomics.org/plink/
**1000 genome phase 3 reference panel**: Download from: https://cncr.nl/research/magma/
Unpack reference panel `gunzip g1000_EUR.zip`.

## ⚠️ Sample Overlap Notice

For accurate Mendelian Randomization (MR) analysis, we **recommend using independent samples**. The BMM package **does not provide methods to calculate the sample overlap coefficient (\(\rho\))**.

If your study may involve overlapping samples, you can use [MR.CUE](https://github.com/QingCheng0218/MR.CUE) to estimate \(\rho\). Install it with:

```r
library(devtools)
install_github("QingCheng0218/MR.CUE@main")
library(MR.CUE)
```
**Quick Example**
Required Files
1. Exposure and Outcome Summary Statistics


**Table 1: Format for exposure and outcome data**

| SNP       | chr | BP        | A1 | A2 | beta   | se     | pvalue |
|-----------|-----|-----------|----|----|--------|--------|--------|
| rs1000050 | 1   | 162736463 | C  | T  | 0.0002 | 0.0054 | 0.9705 |
| rs1000073 | 1   | 157255396 | A  | G  | 0.0007 | 0.0038 | 0.8538 |
| rs1000075 | 1   | 95166832  | T  | C  | -0.0028| 0.0040 | 0.4839 |
| rs1000085 | 1   | 66857915  | C  | G  | 0.0020 | 0.0044 | 0.6494 |
| rs1000127 | 1   | 63432716  | C  | T  | -0.0019| 0.0042 | 0.6510 |


1. LD Reference Panel

**Table 2: Format for reference panel data**

| CHR | BlockID | SNP1       | SNP2       | r          |
|-----|---------|------------|------------|------------|
| 1   | 1       | rs12562034 | rs4040617  | -0.12635628|
| 1   | 1       | rs12562034 | rs2980300  | -0.13086387|
| 1   | 1       | rs12562034 | rs4475691  | 0.04401255 |
| 1   | 1       | rs12562034 | rs1806509  | 0.09783578 |
| 1   | 1       | rs12562034 | rs7537756  | 0.0371671  |

```r
# Load MR.CUE
library(MR.CUE)

# Example: define file paths (replace with your data)
fileexp <- "BMICHR1CHR2CHR3.txt"  # Exposure data
fileout <- "T2DCHR1CHR2CHR3.txt"  # Outcome data
snpinfo <- "UK10Ksnpinforhm3.RDS" # SNP info
filepan <- list(
  "UK10KCHR1LDhm3.RDS",
  "UK10KCHR2LDhm3.RDS",
  "UK10KCHR3LDhm3.RDS"
)

# Use MR.CUE functions to estimate rho
# See MR.CUE documentation for full usage
```

## Quick Start
```r
library(MRBMM)

# Assign the appropriate value to TBB_CXX_TYPE
Sys.setenv(TBB_CXX_TYPE = "gcc")

# Paths to plink and reference panel
PLINK_BIN <- "/usr/bin/plink"
REF_PANEL <- "/data/1kg_eur/EUR"  # Without .bed/.bim/.fam extension

# Read GWAS summary statistics
exposure <- read_gwas_data(
  file_path = "exposure.txt",
  snp_col = "SNP",
  beta_col = "BETA",
  se_col = "SE",
  pval_col = "P",
  ea_col = "EA",
  oa_col = "OA"
)

outcome <- read_gwas_data(
  file_path = "outcome.txt",
  snp_col = "SNP",
  beta_col = "BETA",
  se_col = "SE",
  pval_col = "P",
  ea_col = "EA",
  oa_col = "OA"
)

# Harmonize with local plink
harmonized <- harmonize_for_mr(
  exp_gwas = exposure,
  otc_gwas = outcome,
  exp_name = "BMI",
  otc_name = "CAD",
  plink_bin = PLINK_BIN,
  ref_panel = REF_PANEL
)

# Extract data for BMM
bmm_data <- extract_bmm_data(harmonized)

# Compile Stan models (required each session, takes 1-2 min)
compiled <- compile_bmm_models()

# Run BMM analysis
results <- run_bmm_analysis(
  beta_X = bmm_data$beta_X,
  beta_Y = bmm_data$beta_Y,
  se_X = bmm_data$se_X,
  se_Y = bmm_data$se_Y,
  rho_e = 0,  # No sample overlap
  compiled_models = compiled
)

# View results
summary(results)
```

## Output

```
══════════════════════════════════════════════════════════
 BMM Analysis Results
══════════════════════════════════════════════════════════

Selected model: 3-comp
Number of SNPs used: 127

─── Causal Effect (theta) ───
  Estimate: 0.1234
  Std Error: 0.0456
  95% CI: [0.0340, 0.2128]
  P-value: 6.82e-03 ***
  → Significant POSITIVE causal effect

─── Component Weights (Posterior Mean) ───
  π[1] (          Valid): 0.687 (SD = 0.124)
  π[2] (     Valid+UHP): 0.245 (SD = 0.108)
  π[3] (       NULL/UHP): 0.068 (SD = 0.043)

─── Convergence Diagnostics ───
  ✓ All chains converged successfully
    Min ESS ratio: 0.456

══════════════════════════════════════════════════════════
```

## Documentation
- [Complete Workflow](examples/complete_workflow.R) - End-to-end analysis

## Method

BMM uses a Bayesian mixture model to classify SNPs into:

**3-Component Model:**
1. **Valid IVs** - No pleiotropy (βY = θ·βX)
2. **Valid + UHP** - Uncorrelated horizontal pleiotropy
3. **NULL/UHP** - Null or invalid IVs

**4-Component Model:**
1. **Valid IVs** - No pleiotropy
2. **Valid + UHP** - Uncorrelated horizontal pleiotropy
3. **Valid + UHP + CHP** - Correlated horizontal pleiotropy  
4. **NULL** - Null IVs

Model selection via LOO-CV. Weighted Mode provides robust initialization.

## License

MIT License - see LICENSE file

## Contact

- Issues: https://github.com/ijustwanthaveaname/BMM/issues
- Email: b627926373@gmail.com
