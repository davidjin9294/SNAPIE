process merge_signal_reports {
    label 'low_cpu_low_mem'
    container params.containers.python
    tag "Sample - $sampleId"

    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/multiqc/", mode: 'copy'

    input:
    path (chSignalFilesReport)
    each path (chMultiQCSignalHeader)
    each path (chMergeReportSignal)
    tuple val (sampleId), val (enrichment_mark), val(bam), val(control), val(read_method)
    
    output:
    path ("merged_signal*.csv")

    script:
    """
    python $chMergeReportSignal
    
    """
}