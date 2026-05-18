process peaks_annotations {
    label 'low_cpu_low_mem'
    container params.containers.snap_genomic_annotation
    tag "All Samples" 

    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/multiqc/", mode : 'copy'
    
    input:
    path (chNarrowPeakFiles)
    each path (chRGenomicAnnotation)

    output:
    path ("z*.jpg")

    script:
    """
    Rscript $chRGenomicAnnotation -i . -o . --force_barplot TRUE
    """
}