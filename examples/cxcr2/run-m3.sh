#!/usr/bin/env bash
# Run nf-cf-random blind mode on the M3 HPC cluster (Slurm account yt41). 
# Execute from anywhere;
# work and results are written under this example directory.
#
# Samplesheet: blind mode, pname cxcr2, MSA-only folder input/cxcr2/ (see README.md).
set -euo pipefail

module load nextflow/24.04.3

export APPTAINER_CACHEDIR=/scratch2/yt41/${USER}/apptainer_cache
export NXF_APPTAINER_CACHEDIR=$APPTAINER_CACHEDIR
mkdir -p $APPTAINER_CACHEDIR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NF_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${SCRIPT_DIR}"

nextflow run "${NF_ROOT}/main.nf" \
  -profile m3 \
  -work-dir "${SCRIPT_DIR}/work" \
  --slurm_account yt41 \
  --samplesheet "${SCRIPT_DIR}/samplesheet.csv" \
  --outdir "${SCRIPT_DIR}/results"
