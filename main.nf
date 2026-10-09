#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Include all process modules
include { VALIDATE } from './modules/validate'
include { FASTQC } from './modules/fastqc'
include { FASTP } from './modules/fastp'
include { BWA_MEM } from './modules/bwa_mem'
include { MARKDUPLICATES } from './modules/markduplicates'
include { HAPLOTYPECALLER } from './modules/haplotypecaller'
include { JOINT_GENOTYPE } from './modules/joint_genotype'
include { FILTER } from './modules/filter'
include { MULTIQC } from './modules/multiqc'
include { PUBLISH } from './modules/publish'

workflow {
    main:
    // Read reference files as value channels
    ref       = file(params.ref)
    ref_index = files("${params.ref}.*")
    ref_dict  = file("${ref.parent}/${ref.baseName}.dict")
    
    // Read samplesheet and create channel
    sheet = file(params.samplesheet)
    ch_samples = channel.fromPath(sheet)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample_id, single_end: row.library_type == 'single']
            def r1 = sheet.parent.resolve(row.r1_fastq)
            def reads = meta.single_end ? [r1] : [r1, sheet.parent.resolve(row.r2_fastq)]
            [meta, reads]
        }
    
    // Stage 0: Validate samplesheet
    VALIDATE(sheet, ch_samples.map { _meta, reads -> reads }.collect(),
             ref, ref_index, ref_dict)
    
    // Every sample waits for validation
    ch_checked = ch_samples
        .combine(VALIDATE.out.sheet)
        .map { meta, reads, _validated -> [meta, reads] }
    
    // Stage 1: FastQC
    FASTQC(ch_checked)
    
    // Stage 2: Fastp
    FASTP(ch_checked)
    
    // Stage 3: BWA alignment
    BWA_MEM(FASTP.out.reads, ref, ref_index)
    
    // Stage 4: Mark duplicates
    MARKDUPLICATES(BWA_MEM.out.bam)
    
    // Stage 5: HaplotypeCaller
    HAPLOTYPECALLER(MARKDUPLICATES.out.bam, ref, ref_index, ref_dict, params.region)
    
    // Stage 6: Joint genotyping
    JOINT_GENOTYPE(HAPLOTYPECALLER.out.gvcf.collect(),
                   HAPLOTYPECALLER.out.tbi.collect(),
                   ref, ref_index, ref_dict, params.region)
    
    // Stage 7: Filter variants
    FILTER(JOINT_GENOTYPE.out.vcf, ref, ref_index, ref_dict)
    
    // Stage 8: MultiQC
    MULTIQC(FASTQC.out.zip.collect(), FASTP.out.json.collect())
    
    // Stage 9: Publish results
    PUBLISH(VALIDATE.out.sheet, FILTER.out.vcf.mix(FILTER.out.table, MULTIQC.out.report).collect())
    
    publish:
    vcf      = FILTER.out.vcf
    variants = FILTER.out.table
    multiqc  = MULTIQC.out.report
    manifest = PUBLISH.out.manifest
    samples  = PUBLISH.out.samples
}

output {
    vcf {
        path '.'
    }
    variants {
        path '.'
    }
    multiqc {
        path '.'
    }
    manifest {
        path '.'
    }
    samples {
        path '.'
    }
}
