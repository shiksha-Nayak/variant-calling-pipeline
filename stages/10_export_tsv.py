#!/usr/bin/env python3

import csv
import gzip
import sys
from pathlib import Path

vcf_path = Path(sys.argv[1])
outdir = Path(sys.argv[2])
outdir.mkdir(parents=True, exist_ok=True)

output_path = outdir / "variants.tsv"

with gzip.open(vcf_path, "rt") as vcf, \
     open(output_path, "w", newline="") as out:

    writer = csv.writer(out, delimiter="\t")
    samples = []

    for line in vcf:
        if line.startswith("##"):
            continue

        if line.startswith("#CHROM"):
            header = line.rstrip().split("\t")
            samples = header[9:]

            writer.writerow([
                "CHROM", "POS", "ID", "REF", "ALT",
                "QUAL", "FILTER", *samples
            ])
            continue

        fields = line.rstrip().split("\t")

        genotypes = []
        for sample_data in fields[9:]:
            gt = sample_data.split(":")[0]
            genotypes.append(gt)

        writer.writerow([
            fields[0], fields[1], fields[2], fields[3],
            fields[4], fields[5], fields[6], *genotypes
        ])

print(f"TSV created: {output_path}")
