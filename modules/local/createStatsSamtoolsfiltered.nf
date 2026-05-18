process createStatsSamtoolsfiltered {
    label 'low_cpu_low_mem'
    container params.containers.samtools

    publishDir "${workflow.projectDir}/${params.outputFolder}/align/${sampleId}", mode : 'copy'
    
    tag "Sample - $sampleId" 

    input:
    tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(sampleBam),val (_)

    output:
    tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path ('*.stats'),path ('*.idxstats'),path ('*.flagstat'),path ("samtools_stats_filtered_mqc_versions.yml")

    script:
    """
    # Generate stats file
    samtools stats $sampleBam > ${sampleId}.AfterFilter.stats

    # Generate idxstats file
    samtools idxstats $sampleBam > ${sampleId}.AfterFilter.idxstats

    # Generate flagstat file
    samtools flagstat $sampleBam > ${sampleId}.AfterFilter.flagstat

    cat <<-END_VERSIONS > samtools_stats_filtered_mqc_versions.yml
    "${task.process}":
      samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}