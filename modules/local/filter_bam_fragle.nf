process filter_bam_fragle {

    label 'low_cpu_low_mem'
    container params.containers.samtools
    tag "$sampleId"

    input:
    tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path(sortedBam), path(sampleBamIndex), val(_)
    each path(chFragleSites)

    output:
    tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path("*.bam"), path("*.bai"), val(_)

    script:
    """
    SITES_BED="$chFragleSites/$enrichment_mark/sites.bed"

    if [ -f "\$SITES_BED" ]; then
        echo "Filtrando $sortedBam com \$SITES_BED"

        samtools view -b -L "\$SITES_BED" "$sortedBam" > "${sampleId}.filtered.fragle.bam"
        samtools index "${sampleId}.filtered.fragle.bam"
    else
        echo "Arquivo \$SITES_BED não encontrado. Usando arquivos BAM originais."
        cp "$sortedBam" "${sampleId}.filtered.fragle.bam"
        cp "$sampleBamIndex" "${sampleId}.filtered.fragle.bam.bai"
    fi
    """
}