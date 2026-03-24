#!/usr/bin/env python3
# /// script
# dependencies = [
#   "biopython",
# ]
# ///
"""Write range_fs_pairs_all.txt for CF-random FS mode."""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

from Bio.PDB import PDBParser

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s", stream=sys.stderr)
log = logging.getLogger(__name__)


def max_residue_id(pdb_path: Path) -> int:
    parser = PDBParser(QUIET=True)
    structure = parser.get_structure("x", str(pdb_path))
    max_id = 0
    for model in structure:
        for chain in model:
            for residue in chain:
                rid = residue.get_id()
                if rid[0] != " ":
                    continue
                max_id = max(max_id, int(rid[1]))
    return max_id


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--pdb1", type=Path, required=True)
    p.add_argument("--pdb2", type=Path, required=True)
    p.add_argument("--pdb1-range", dest="pdb1_range", default="")
    p.add_argument("--pdb2-range", dest="pdb2_range", default="")
    p.add_argument("--pred1-range", dest="pred1_range", default="")
    p.add_argument("--pred2-range", dest="pred2_range", default="")
    p.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("range_fs_pairs_all.txt"),
        help="Output path (default: ./range_fs_pairs_all.txt)",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()
    pdb1 = args.pdb1.resolve()
    pdb2 = args.pdb2.resolve()
    if not pdb1.is_file() or not pdb2.is_file():
        log.error("pdb1 and pdb2 must exist and be files")
        sys.exit(1)

    n = max_residue_id(pdb1)
    default_range = f"1-{n}"

    pdb1_r = args.pdb1_range.strip() or default_range
    pdb2_r = args.pdb2_range.strip() or default_range
    pred1_r = args.pred1_range.strip() or default_range
    pred2_r = args.pred2_range.strip() or default_range

    name1 = pdb1.stem
    name2 = pdb2.stem

    out = args.output
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8") as fh:
        fh.write("# pdb1,pdb2,pred1,pred2\n")
        fh.write(f"{name1},{name2},{pdb1_r},{pdb2_r},{pred1_r},{pred2_r}\n")
    log.info("Wrote %s", out)


if __name__ == "__main__":
    main()
