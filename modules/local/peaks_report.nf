process peaks_report {
    label 'low_cpu_low_mem'
    container params.containers.python
    tag "All Samples" 

    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/multiqc/", mode : 'copy'
    

    input:
    path (chNarrowPeakFiles)
    each path (chMultiQCPeaksHeader)
    each path (chReportPeaks)

    output:
    path ("*_mqc.csv")

    script:
    """
    python $chReportPeaks
    """
}