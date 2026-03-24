# nf-cf-random

Nextflow pipeline wrapping [CF-random_software](https://github.com/ncbi/CF-random_software): one samplesheet row per job, parallel runs across rows. Style matches [nf-ligand-bind](https://github.com/pansapiens/nf-ligand-bind) and [nf-binder-design](https://github.com/Australian-Protein-Design-Initiative/nf-binder-design) (manifest, Apptainer, profiles).

## Requirements

- Nextflow `>= 23.04.0`
- Apptainer/Singularity with NVIDIA (`--nv`) for GPU
- CF-random is packaged as an Apptainer image, including AlphaFold2 weights, so no additional software installation is required. You should set `NXF_APPTAINER_CACHEDIR` to a directory with enough space (~17Gb) where Apptainer can cache the image.

## Usage

```bash
nextflow run main.nf -profile local \
  --samplesheet samplesheet.csv \
  --outdir results
```

On M3, use the platform profile (adjust Slurm account as required):

```bash
nextflow run main.nf -profile m3 \
  --samplesheet samplesheet.csv \
  --slurm_account YOUR_ACCOUNT
```

## Samplesheet (CSV)

Header row required. Column names match CF-random CLI flags **without** the leading `--**.

Rows whose **first character** (leftmost in the file, same order as the header) starts with `#` after trimming are skipped (comment lines).

Unused options can be **left empty** in the CSV (trailing commas are fine), or you can **omit optional columns** entirely from the header row if you never use them. Path columns (`fname`, `pdb1`, `pdb2`, …) are Nextflow `file()` inputs: **relative to where you launch Nextflow**, or absolute.

| Column | Required | Description |
|--------|----------|-------------|
| `option` | yes | `AC`, `FS`, or `blind` |
| `fname` | yes | **Recommended:** path to one **`.a3m` file** per row (MSA). Each job stages that file into its own folder (as `0.a3m` for ColabFold). **Alternatively:** path to an **MSA-only directory** (e.g. ColabFold output containing `0.a3m`)—avoid folders that also hold PDBs or other junk, which can break ColabFold |
| `pdb1` | AC / FS | Reference PDB (dominant fold) |
| `pdb2` | AC / FS | Reference PDB (alternate fold) |
| `pname` | no | Optional. When set, used as run **`id`** (and `publishDir`); **must be unique** |
| `nMSA` | no | Extra MSA samples (string integer, passed through to CF-random) |
| `nENS` | no | Ensemble-related parameter |
| `type` | no | ColabFold model: `ptm`, `monomer`, or `multimer` |
| `fmname` | no | Multimer MSA directory |
| `pdb1_range` | no | FS only: residue range in PDB1 (e.g. `50-99`) |
| `pdb2_range` | no | FS only: residue range in PDB2 |
| `pred1_range` | no | FS only: residue range in predictions vs PDB1 |
| `pred2_range` | no | FS only: residue range in predictions vs PDB2 |

For **`option == FS`**, the pipeline writes `range_fs_pairs_all.txt` before calling CF-random. Any of the four range columns that are empty default independently to `1-N`, where `N` is the maximum residue number in **pdb1** (BioPython). If all four are empty, they all become `1-N`.

Run **`id`** (used for `publishDir` and `tag`):

- **`pname` set:** `pname` (then sanitised)
- **`pname` empty:** `pdb1_basename_pdb2_basename_option_nMSA_nENS_type_rowIndex` using the row’s `option`, `nMSA`, `nENS`, `type`, and a **1-based index** over non-comment data rows. Missing `type` is treated as `ptm`; missing `nMSA` / `nENS` as `0`. For blind rows (no PDBs), `none` is used for the missing `pdb1` / `pdb2` basename slots.

Non-alphanumeric characters in `id` are replaced with `_`.

Duplicate non-empty `pname` values are rejected at startup.

## Example rows

Fold-switching (reference structures + MSA):

```csv
option,fname,pdb1,pdb2,pdb1_range,pdb2_range,pred1_range,pred2_range
FS,/path/to/2oug_C.a3m,/path/to/2oug_C.pdb,/path/to/6c6s_D.pdb,112-162,115-162,112-162,112-162
```

Same FS row with automatic full-length ranges (omit the four range columns or leave them empty):

```csv
option,fname,pdb1,pdb2
FS,/path/to/2oug_C.a3m,/path/to/2oug_C.pdb,/path/to/6c6s_D.pdb
```

Alternative conformation:

```csv
option,fname,pdb1,pdb2,nMSA
AC,/path/to/5olw_A.a3m,/path/to/5olw_A.pdb,/path/to/5olx_A.pdb,5
```

Blind (no reference PDBs):

```csv
option,fname,pname
blind,/path/to/2vfx_L.a3m,Mad2_test
```

### Blind mode and Foldseek

Upstream README text about symlinking a Foldseek PDB library is misleading for current code: blind mode runs Foldseek **self-search** on predicted structures only. See [cf-random-blind-foldseek.md](cf-random-blind-foldseek.md).

## Outputs

Published under `params.outdir/<id>/` (prediction directories, CSV summaries, plots), depending on mode and success path (`successed_prediction`, `failed_prediction`, `blind_prediction`, `multimer_prediction`).

## Project layout

- `main.nf` – samplesheet parsing and workflow
- `modules/cf_random.nf` – containerised `CF_RANDOM` process
- `bin/generate_range_fs_pairs.py` – FS `range_fs_pairs_all.txt` generation
- `conf/platforms/m3.config` – optional M3 Slurm / Apptainer binds

## Licence

See repository licence (to be added if publishing).
