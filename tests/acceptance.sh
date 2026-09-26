#!/usr/bin/env bash
set -euo pipefail

VCF="${1:?Usage: acceptance.sh filtered.vcf.gz truth_dir}"
TRUTH_DIR="${2:?Missing truth directory}"
THRESHOLD=80

python3 - "$VCF" "$TRUTH_DIR" "$THRESHOLD" <<'PY'
import gzip
import sys
from pathlib import Path

vcf_path = Path(sys.argv[1])
truth_dir = Path(sys.argv[2])
threshold = float(sys.argv[3])

samples_expected = ["smoke_01", "smoke_02", "smoke_03"]

iupac = {
    "A": {"A"}, "C": {"C"}, "G": {"G"}, "T": {"T"},
    "R": {"A", "G"}, "Y": {"C", "T"},
    "S": {"G", "C"}, "W": {"A", "T"},
    "K": {"G", "T"}, "M": {"A", "C"},
    "B": {"C", "G", "T"}, "D": {"A", "G", "T"},
    "H": {"A", "C", "T"}, "V": {"A", "C", "G"},
}

if not vcf_path.is_file():
    sys.exit(f"ERROR: VCF not found: {vcf_path}")

variants = {}
samples = []

with gzip.open(vcf_path, "rt") as f:
    for line in f:
        if line.startswith("#CHROM"):
            samples = line.rstrip().split("\t")[9:]
        elif not line.startswith("#"):
            fields = line.rstrip().split("\t")
            variants[(fields[0], int(fields[1]))] = fields[9:]

if samples != samples_expected:
    sys.exit(f"FAIL: Expected samples {samples_expected}, found {samples}")

print("Sample\tRecovered\tTotal\tRecovery\tStatus")
failed = False

for i, sample in enumerate(samples):
    truth_file = truth_dir / f"{sample}.truth.txt"
    if not truth_file.is_file():
        sys.exit(f"ERROR: Missing truth file: {truth_file}")

    total = recovered = 0

    with open(truth_file) as f:
        for line in f:
            fields = line.split()
            if len(fields) < 4:
                continue

            chrom, pos, ref, alt = fields[:4]

            if ref not in "ACGT" or len(ref) != 1:
                continue
            if alt not in iupac or len(alt) != 1:
                continue
            if iupac[alt] == {ref}:
                continue

            total += 1
            genotypes = variants.get((chrom, int(pos)))

            if genotypes is not None:
                gt = genotypes[i].split(":")[0]
                alleles = gt.replace("|", "/").split("/")
                if any(a not in ("0", ".") for a in alleles):
                    recovered += 1

    rate = 100 * recovered / total if total else 0
    passed = total > 0 and rate >= threshold
    status = "PASS" if passed else "FAIL"

    print(f"{sample}\t{recovered}\t{total}\t{rate:.2f}%\t{status}")

    if not passed:
        failed = True

if failed:
    sys.exit(1)

print(f"\nPASS: All samples meet the {threshold:.0f}% recovery threshold.")
PY
