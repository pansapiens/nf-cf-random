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

DATESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p results

#nextflow run pansapiens/nf-cf-random \
nextflow run "../../main.nf" \
  -profile m3_bdi \
  --slurm_account yt41 \
  --samplesheet "samplesheet.csv" \
  --outdir "results" \
  -resume \
  -with-report "results/report-${DATESTAMP}.html" \
  -with-trace "results/trace-${DATESTAMP}.txt"
