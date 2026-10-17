configfile: "config.yaml"

KNOWN = {"samplesheet", "ref", "region", "outdir", "platform", "executor", "containers"}
unknown = sorted(set(config) - KNOWN)
if unknown:
    raise ValueError(f"unknown config key(s): {', '.join(unknown)}")

import csv
import os
import re

PIPELINE = {"name": "variant-call", "version": "1.0.0"}
OUT = config["outdir"]
BIN = os.path.join(workflow.basedir, "bin")
IMAGES = {name: f"docker://{image}" for name, image in config["containers"].items()}

REF = config["ref"]
REF_FAI = REF + ".fai"
REF_BWA = [REF + ext for ext in (".amb", ".ann", ".bwt", ".pac", ".sa")]
REF_DICT = os.path.splitext(REF)[0] + ".dict"
SHEET = config["samplesheet"]

with open(SHEET) as fh:
    ROWS = list(csv.DictReader(fh))

SAMPLES = [row["sample_id"] for row in ROWS]
PAIRED = [row["sample_id"] for row in ROWS if row["library_type"] == "paired"]
SINGLE = [row["sample_id"] for row in ROWS if row["library_type"] == "single"]

def resolve(path):
    return path if os.path.isabs(path) else os.path.join(os.path.dirname(SHEET), path)

READS = {
    row["sample_id"]: [resolve(row["r1_fastq"])] +
    ([resolve(row["r2_fastq"])] if row["library_type"] == "paired" else [])
    for row in ROWS
}

def one_of(names):
    return "|".join(map(re.escape, names)) if names else "(?!)"

def trimmed(wc):
    reads = [f"work/trim/{wc.sample}_R1.trim.fastq.gz"]
    if wc.sample in PAIRED:
        reads.append(f"work/trim/{wc.sample}_R2.trim.fastq.gz")
    return reads

rule all:
    input:
        f"{OUT}/cohort.filtered.vcf.gz",
        f"{OUT}/variants.tsv",
        f"{OUT}/multiqc_report.html",
        f"{OUT}/samples.tsv",
        f"{OUT}/manifest.json"

# Stage 0: Validate inputs
rule validate:
    input:
        sheet=SHEET,
        reads=[p for paths in READS.values() for p in paths],
        ref=REF,
        fai=REF_FAI,
        bwa=REF_BWA,
        dict=REF_DICT
    output:
        "work/validate/samplesheet.csv"
    log:
        "logs/validate.log"
    shell:
        "({BIN}/validate_samplesheet.sh {input.sheet} {input.ref} && cp {input.sheet} {output}) 2> {log}"

# Stage 1: Raw read quality control
rule fastqc:
    input:
        checked=rules.validate.output,
        reads=lambda wc: READS[wc.sample]
    output:
        html="work/fastqc/{sample}_fastqc.html",
        zip="work/fastqc/{sample}_fastqc.zip"
    threads: 2
    log:
        "logs/fastqc/{sample}.log"
    container:
        IMAGES["fastqc"]
    shell:
        """
        mkdir -p work/fastqc/raw_{wildcards.sample}
        fastqc --threads {threads}             --outdir work/fastqc/raw_{wildcards.sample}             {input.reads} 2> {log}
        cp "$(find work/fastqc/raw_{wildcards.sample} -name '*_fastqc.html' -print -quit)" {output.html}
        cp "$(find work/fastqc/raw_{wildcards.sample} -name '*_fastqc.zip' -print -quit)" {output.zip}
        """

# Stage 2: Paired-end trimming
rule fastp_paired:
    input:
        checked=rules.validate.output,
        r1=lambda wc: READS[wc.sample][0],
        r2=lambda wc: READS[wc.sample][1]
    output:
        r1="work/trim/{sample}_R1.trim.fastq.gz",
        r2="work/trim/{sample}_R2.trim.fastq.gz",
        html="work/trim/{sample}_fastp.html",
        json="work/trim/{sample}_fastp.json"
    wildcard_constraints:
        sample=one_of(PAIRED)
    threads: 4
    log:
        "logs/fastp/{sample}.log"
    container:
        IMAGES["fastp"]
    shell:
        """
        fastp -i {input.r1} -I {input.r2} \
              -o {output.r1} -O {output.r2} \
              -w {threads} -h {output.html} -j {output.json} 2> {log}
        """

# Stage 2: Single-end trimming
rule fastp_single:
    input:
        checked=rules.validate.output,
        r1=lambda wc: READS[wc.sample][0]
    output:
        r1="work/trim/{sample}_R1.trim.fastq.gz",
        html="work/trim/{sample}_fastp.html",
        json="work/trim/{sample}_fastp.json"
    wildcard_constraints:
        sample=one_of(SINGLE)
    threads: 4
    log:
        "logs/fastp/{sample}.log"
    container:
        IMAGES["fastp"]
    shell:
        """
        fastp -i {input.r1} -o {output.r1} \
              -w {threads} -h {output.html} -j {output.json} 2> {log}
        """

# Stage 3: Align reads
rule bwa_mem:
    input:
        reads=trimmed,
        ref=REF,
        fai=REF_FAI,
        bwa=REF_BWA
    output:
        "work/aligned/{sample}.sam"
    params:
        rg=lambda wc: f"@RG\\tID:{wc.sample}\\tSM:{wc.sample}\\tPL:ILLUMINA"
    threads: 8
    log:
        "logs/bwa_mem/{sample}.log"
    container:
        IMAGES["bwa"]
    shell:
        """
        bwa mem -t {threads} -R '{params.rg}' {input.ref} {input.reads} \
            > {output} 2> {log}
        """

# Stage 4: Sort and mark duplicates
rule markduplicates:
    input:
        sam=rules.bwa_mem.output
    output:
        bam="work/markdup/{sample}.markdup.bam",
        bai="work/markdup/{sample}.markdup.bam.bai",
        metrics="work/markdup/{sample}.duplicate_metrics.txt"
    params:
        sorted=lambda wc: f"work/markdup/{wc.sample}.sorted.bam"
    threads: 4
    log:
        "logs/markduplicates/{sample}.log"
    container:
        IMAGES["gatk"]
    shell:
        """
        (
        samtools sort -@ {threads} -o {params.sorted} {input.sam}
        gatk MarkDuplicates \
            -I {params.sorted} \
            -O {output.bam} \
            -M {output.metrics} \
            --CREATE_INDEX false
        samtools index {output.bam} {output.bai}
        ) 2> {log}
        """

# Stage 5: Per-sample GVCF
rule haplotypecaller:
    input:
        bam=rules.markduplicates.output.bam,
        bai=rules.markduplicates.output.bai,
        ref=REF,
        fai=REF_FAI,
        dict=REF_DICT
    output:
        gvcf="work/gvcf/{sample}.g.vcf.gz",
        tbi="work/gvcf/{sample}.g.vcf.gz.tbi"
    threads: 8
    params:
        region=config["region"]
    log:
        "logs/haplotypecaller/{sample}.log"
    container:
        IMAGES["gatk"]
    shell:
        """
        gatk HaplotypeCaller -R {input.ref} -I {input.bam} \
            -O {output.gvcf} -ERC GVCF \
            --native-pair-hmm-threads {threads} \
            -L {params.region} 2> {log}
        """

# Stage 6: Joint genotyping
rule joint_genotype:
    input:
        gvcfs=expand("work/gvcf/{sample}.g.vcf.gz", sample=SAMPLES),
        tbis=expand("work/gvcf/{sample}.g.vcf.gz.tbi", sample=SAMPLES),
        ref=REF,
        fai=REF_FAI,
        dict=REF_DICT
    output:
        vcf="work/joint/joint.vcf.gz",
        tbi="work/joint/joint.vcf.gz.tbi"
    params:
        variants=lambda wc, input: " ".join(f"-V {g}" for g in input.gvcfs),
        region=config["region"]
    threads: 4
    log:
        "logs/joint_genotype.log"
    container:
        IMAGES["gatk"]
    shell:
        """
        gatk CombineGVCFs -R {input.ref} {params.variants} \
            -O work/joint/combined.g.vcf.gz -L {params.region} 2> {log}
        gatk GenotypeGVCFs -R {input.ref} \
            -V work/joint/combined.g.vcf.gz \
            -O {output.vcf} -L {params.region} 2>> {log}
        """

# Stage 7: Filter variants and create TSV
rule filter:
    input:
        vcf=rules.joint_genotype.output.vcf,
        tbi=rules.joint_genotype.output.tbi,
        ref=REF
    output:
        vcf=f"{OUT}/cohort.filtered.vcf.gz",
        tbi=f"{OUT}/cohort.filtered.vcf.gz.tbi",
        table=f"{OUT}/variants.tsv"
    log:
        "logs/filter.log"
    container:
        IMAGES["gatk"]
    shell:
        r"""
        (
        gatk VariantFiltration -R {input.ref} -V {input.vcf} \
            -O {output.vcf} \
            --filter-name "LowQual" \
            --filter-expression "QUAL < 30"
        printf 'chrom\tpos\tref\talt\tqual\tfilter\n' > {output.table}
        bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\t%FILTER\n' \
            {output.vcf} >> {output.table}
        ) 2> {log}
        """

# Stage 8: MultiQC
rule multiqc:
    input:
        fastqc=expand("work/fastqc/{sample}_fastqc.zip", sample=SAMPLES),
        fastp=expand("work/trim/{sample}_fastp.json", sample=SAMPLES),
        metrics=expand("work/markdup/{sample}.duplicate_metrics.txt", sample=SAMPLES)
    output:
        f"{OUT}/multiqc_report.html"
    log:
        "logs/multiqc.log"
    container:
        IMAGES["multiqc"]
    shell:
        """
        mkdir -p work/multiqc
        multiqc -q -f -o work/multiqc {input} 2> {log}
        cp work/multiqc/multiqc_report.html {output}
        """

# Stage 9: Course-provided publishing
PUBLISH_SHEET = rules.validate.output
PUBLISH_RESULTS = [*rules.filter.output, *rules.multiqc.output]
include: "rules/publish.smk"
