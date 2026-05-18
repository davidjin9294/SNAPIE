process bedgraph_to_bigwig {
    label 'med_cpu_med_mem'
    tag "Sample - $sampleId"  

    container params.containers.bedgraphtobigwig

    publishDir "${workflow.projectDir}/${params.outputFolder}/peaks/${sampleId}", mode : 'copy'

    input:
    tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path(chbedgraph), val (_)
    each path (chrom_sizes)

    output:
    tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path("*.bw"), path ("bedgraph_to_bigwig_mqc_versions.yml")

    exec:
    str_bw = sampleId + '_' + enrichment_mark + '.bw'

    script:
    """
    bedGraphToBigWig $chbedgraph $chrom_sizes $str_bw

    cat <<-END_VERSIONS > bedgraph_to_bigwig_mqc_versions.yml
    "${task.process}":
        ucsc: $params.containers.bedgraphtobigwig_version
    END_VERSIONS
    """
}