process createGenomeIndex {
    label 'high_cpu_high_mem'
    container params.containers.bwa

    tag "Creating Index - $genome" 

    input:
    tuple val(genome), val(faGZFile), val(geneAnnotation), val(dacList), val(snp), val(tssPromoterPeaks)
    path genomeFile
    path refDir

    output:
    path ("${genome}.fa.*")

    script:
    def genomeFilePac = "${genome}.fa.pac"
    """
    if [ ! -f ${refDir}/${genomeFilePac} ]; then
        echo "${refDir}/${genomeFilePac} file not found. Creating index files."
        bwa index ${refDir}/${genome}.fa

    else
        echo "Index files already exist in ${refDir}. Skipping index creation."
        echo "Creating symlinks to index files."
    fi
    ln -s ${refDir}/${genome}.fa.* .

    cat <<-END_VERSIONS > index_creation_mqc_versions.yml
    "${task.process}":
        bwa: \$( bwa 2>&1 | grep Version | sed -e "s/Version: //g" )
    END_VERSIONS
    """
}