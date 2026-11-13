PRAGMA foreign_keys = ON;

CREATE TABLE pipelines (
    pipeline_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    version TEXT NOT NULL,
    implementation TEXT NOT NULL
);

CREATE TABLE runs (
    run_id TEXT PRIMARY KEY,
    pipeline_id INTEGER NOT NULL,
    started_at TEXT,
    finished_at TEXT,
    status TEXT,
    platform TEXT,
    executor TEXT,
    samplesheet TEXT,
    reference TEXT,
    region TEXT,
    folder TEXT NOT NULL,
    FOREIGN KEY (pipeline_id)
        REFERENCES pipelines(pipeline_id)
);

CREATE TABLE samples (
    sample_id TEXT PRIMARY KEY,
    sex TEXT,
    population TEXT,
    family TEXT,
    father TEXT,
    mother TEXT,
    phenotype TEXT,
    is_synthetic_phenotype TEXT
);

CREATE TABLE run_samples (
    run_id TEXT NOT NULL,
    sample_id TEXT NOT NULL,
    condition TEXT,
    library_type TEXT,
    PRIMARY KEY (run_id, sample_id),
    FOREIGN KEY (run_id)
        REFERENCES runs(run_id),
    FOREIGN KEY (sample_id)
        REFERENCES samples(sample_id)
);

CREATE TABLE variants (
    variant_id INTEGER PRIMARY KEY,
    run_id TEXT NOT NULL,
    chrom TEXT,
    pos INTEGER,
    ref TEXT,
    alt TEXT,
    qual REAL,
    filter TEXT,
    FOREIGN KEY (run_id)
        REFERENCES runs(run_id)
);

CREATE TABLE outputs (
    output_id INTEGER PRIMARY KEY,
    run_id TEXT NOT NULL,
    path TEXT NOT NULL,
    sha256 TEXT,
    FOREIGN KEY (run_id)
        REFERENCES runs(run_id),
    UNIQUE (run_id, path)
);
