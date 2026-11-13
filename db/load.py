#!/usr/bin/env python3
"""Load variant-calling pipeline runs into a SQLite database."""

import csv
import json
import os
import sqlite3
import sys


METADATA_COLUMNS = [
    "sex", "population", "family", "father",
    "mother", "phenotype", "is_synthetic_phenotype"
]


def read_tsv(path):
    """Read TSV data while skipping comment lines."""
    with open(path, newline="") as handle:
        rows = (line for line in handle
                if not line.startswith("#"))
        return list(csv.DictReader(rows, delimiter="\t"))


def load_metadata(con, metadata_path):
    """Add all samples described in the metadata file."""
    rows = read_tsv(metadata_path)

    columns = ["sample_id"] + METADATA_COLUMNS
    placeholders = ", ".join("?" for _ in columns)
    names = ", ".join(columns)

    sql = (
        f"INSERT INTO samples ({names}) "
        f"VALUES ({placeholders}) "
        "ON CONFLICT(sample_id) DO NOTHING"
    )

    with con:
        for row in rows:
            con.execute(sql, [row[col] for col in columns])

    print(f"Metadata loaded: {len(rows)} samples")


def load_run(con, folder):
    """Import one run as a single transaction."""
    folder = os.path.abspath(folder)

    with open(os.path.join(folder, "manifest.json")) as handle:
        manifest = json.load(handle)

    samples = read_tsv(os.path.join(folder, "samples.tsv"))
    variants = read_tsv(os.path.join(folder, "variants.tsv"))

    pipeline = manifest["pipeline"]
    params = manifest.get("params", {})
    platform = manifest["platform"]
    run_id = pipeline["run_id"]

    manifest_samples = manifest["samples"]
    library_types = {
        s["sample_id"]: s.get("library_type")
        for s in manifest_samples
    }

    if len(library_types) != len(manifest_samples):
        raise ValueError(
            f"{run_id}: duplicate sample in manifest.json"
        )

    with con:
        existing = con.execute(
            "SELECT 1 FROM runs WHERE run_id = ?",
            (run_id,)
        ).fetchone()

        if existing:
            print(f"Skipped existing run: {run_id}")
            return

        # Find or create the pipeline version.
        pipeline_key = (
            pipeline["name"],
            pipeline["version"],
            pipeline["implementation"]
        )

        row = con.execute(
            """SELECT pipeline_id FROM pipelines
               WHERE name = ? AND version = ?
               AND implementation = ?""",
            pipeline_key
        ).fetchone()

        if row:
            pipeline_id = row[0]
        else:
            cursor = con.execute(
                """INSERT INTO pipelines
                   (name, version, implementation)
                   VALUES (?, ?, ?)""",
                pipeline_key
            )
            pipeline_id = cursor.lastrowid

        # Insert the run.
        con.execute(
            """INSERT INTO runs
               (run_id, pipeline_id, started_at, finished_at,
                status, platform, executor, samplesheet,
                reference, region, folder)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                run_id,
                pipeline_id,
                pipeline.get("started_at"),
                pipeline.get("finished_at"),
                pipeline.get("exit_status"),
                platform.get("kind"),
                platform.get("executor"),
                params.get("samplesheet"),
                params.get("ref"),
                params.get("region"),
                folder
            )
        )

        # Add samples not already listed in the metadata.
        for sample in samples:
            sample_id = sample["sample_id"]

            con.execute(
                """INSERT INTO samples (sample_id)
                   VALUES (?)
                   ON CONFLICT(sample_id) DO NOTHING""",
                (sample_id,)
            )

            # The composite primary key rejects duplicates.
            con.execute(
                """INSERT INTO run_samples
                   (run_id, sample_id, condition, library_type)
                   VALUES (?, ?, ?, ?)""",
                (
                    run_id,
                    sample_id,
                    sample.get("condition"),
                    library_types.get(sample_id)
                )
            )

        # Import every variant.
        con.executemany(
            """INSERT INTO variants
               (run_id, chrom, pos, ref, alt, qual, filter)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (
                (
                    run_id,
                    v["chrom"],
                    int(v["pos"]),
                    v["ref"],
                    v["alt"],
                    float(v["qual"]),
                    v["filter"]
                )
                for v in variants
            )
        )

        # Import output filenames and SHA-256 checksums.
        for output in manifest["outputs"]:
            checksum = output["checksum"]

            if checksum.lower().startswith("sha256:"):
                checksum = checksum[7:]

            con.execute(
                """INSERT INTO outputs (run_id, path, sha256)
                   VALUES (?, ?, ?)""",
                (run_id, output["path"], checksum)
            )

    print(
        f"Loaded {run_id}: "
        f"{len(samples)} samples, "
        f"{len(variants)} variants, "
        f"{len(manifest['outputs'])} outputs"
    )


def main():
    if len(sys.argv) < 4:
        sys.exit(
            "Usage: python3 db/load.py "
            "<database> <metadata.tsv> <run-folder> ..."
        )

    db_path = sys.argv[1]
    metadata_path = sys.argv[2]
    run_folders = sys.argv[3:]

    con = sqlite3.connect(db_path)

    try:
        con.execute("PRAGMA foreign_keys = ON")
        load_metadata(con, metadata_path)

        for folder in run_folders:
            load_run(con, folder)
    finally:
        con.close()


if __name__ == "__main__":
    main()
