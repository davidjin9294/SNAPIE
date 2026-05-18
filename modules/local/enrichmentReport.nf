process enrichmentReport {
    label 'low_cpu_low_mem'
    container params.containers.python
    tag "Sample - $sampleId" 

    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/multiqc/", mode: 'copy'

    input:
    tuple val (sampleId), val (enrichment_mark), val(bam), val(control), val(read_method) 
    path(csvFiles)
    each path(chReportEnrichment)

    output:
    path ("*_report.csv")

    script:
    """
    # create an empty file to satisfy the output requirement if no enrichment mark is available
    touch ${sampleId}_report.csv
    python $chReportEnrichment --mark ${enrichment_mark} --samplename ${sampleId}
    """
}