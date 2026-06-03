process igv_reports {
    label 'high_cpu_high_plus_mem'
    container params.containers.igv_reports
    tag "All Samples"

    publishDir "$path_sample_multiqc", mode : 'copy'

    input:
    path (bedgraphs)
    path (house_keeping_genes)
    path (genomeFile)
    path (genomeIndexFiles)
    tuple val(_), val(_),val(path_analysis),val(_), val(_)

    exec:
    path_sample_multiqc =  path_analysis + "/reports/multiqc/" 
    htmlFile = "igv_housekeeping_genes_report.html"

    output:
    path ("igv_housekeeping_genes_report.html")

    script:
    """
    create_report $house_keeping_genes --fasta $genomeFile --tracks $bedgraphs --output $htmlFile --flanking 100
    """
}

process igv_sample_reports {
    label 'high_cpu_high_plus_mem'
    container params.containers.igv_reports
    tag "Sample - $sampleId"

    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/multiqc/", mode : 'copy'

    input:
    tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path(bedgraph), val(_)
    each path (house_keeping_genes)
    each path (genomeFile)
    each path (genomeIndexFiles)

    exec:
    htmlFile = sampleId + "_igv_housekeeping_genes_report.html"

    output:
    path ("*.html")

    script:
    """
    create_report $house_keeping_genes --fasta $genomeFile --tracks $bedgraph --output $htmlFile 

    """
}

process igv_consolidate_report {
    label 'low_cpu_low_plus_mem'
    container params.containers.ubuntu
    tag "All Samples"

    //publishDir "${workflow.projectDir}/${params.outputFolder}/reports/multiqc/BAM_SIGNAL_PROCESSING/", mode : 'copy'

    input:
    path (samples_report)
    path (house_keeping_header)

    exec:
    htmlFile = "igv_housekeeping_genes_mqc.html"

    output:
    path ("*.html")

    script:
    """
    # Define the output HTML file
    cat $house_keeping_header > $htmlFile

    # Append HTML links for matching files to the consolidated HTML file
    for file in *_igv_housekeeping_genes_report.html; do
        # Extract the string before '_igv_housekeeping_genes_report.html'
        link_text=\$(basename "\$file" "_igv_housekeeping_genes_report.html")
        echo "<a href='\${file}' target='_blank' class='btn btn-primary'>\${link_text}</a>" >> $htmlFile
    done
    """
}

process igv_session {
    label 'med_cpu_med_mem'
    container params.containers.python
    tag "All Samples"

    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/igv_session/", mode : 'copy'

    input:
    path (bw)
    path (chIGVFilestoSessions)
    path (chEnrichmentColors)
    tuple val(genome), val(_), val(_), val(_), val(_),val(_)
    path (house_keeping_genes)

    exec:
    fileOut = "IGV_Session.xml"

    output:
    tuple path ("*.xml"),path (bw)

    script:
    """
    python $chIGVFilestoSessions $fileOut $house_keeping_genes $genome
    """

}