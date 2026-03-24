# cxcr2 example (`examples/cxcr2`)

- **MSA:** `input/cxcr2/` holds only the ColabFold MSA (`bfd.mgnify30.metaeuk30.smag30.a3m` and a `0.a3m` symlink). The blind row uses `fname=input/cxcr2/` so `colabfold_batch` does not see PDBs or other files under `input/`.
- **Structures for FS/AC (commented rows):** PDBs live under `input/` (`cxcr2_active.pdb`, `cxcr2_inactive.pdb`); paths in the samplesheet are relative to the example directory when you run `./run-m3.sh`.
- Remove stray `*_predicted_models_*` trees from `input/` if you re-run locally outside Nextflow—they are not needed for the pipeline and clutter the parent folder.

Run: `./run-m3.sh` (adjust `-profile` / account in the script as needed).

The `cxcr2_active.pdb` and `cxcr2_inactive.pdb` files are from [gpcrdb](https://gpcrdb.org/protein/cxcr2_human/).