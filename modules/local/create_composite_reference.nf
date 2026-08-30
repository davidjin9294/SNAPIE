process createCompositeReference {
    label 'high_cpu_high_mem'
    container params.containers.bwa_and_samtools

    tag "Creating composite reference - ${genome}_dm3"

    input:
    val genome
    path primaryFasta
    path dm3Fasta
    path primaryChromSizes
    path dm3ChromSizes
    path primaryDAC
    path dm3DAC
    path refDir

    output:
    path "${genome}_dm3.fa", emit: composite_fasta
    path "${genome}_dm3.fa.*", emit: composite_index
    path "${genome}_dm3.chrom.sizes", emit: composite_chrom_sizes
    path "${genome}_dm3.DAC.bed", emit: composite_dac

    script:
    def composite = "${genome}_dm3"
    """
    # Prefix only the dm3 sequence identifier. Any description after the first
    # whitespace is retained in the FASTA header.
    cp "$primaryFasta" "${composite}.fa"
    awk '/^>/ { sub(/^>/, ">dm3_") } { print }' "$dm3Fasta" >> "${composite}.fa"

    # Preserve the ordering of the two source size files and make the dm3 names
    # agree with the prefixed FASTA headers.
    awk 'BEGIN { FS=OFS="\\t" } NF >= 2 { print \$1, \$2 }' \
        "$primaryChromSizes" > "${composite}.chrom.sizes"
    awk 'BEGIN { FS=OFS="\\t" } NF >= 2 { print "dm3_" \$1, \$2 }' \
        "$dm3ChromSizes" >> "${composite}.chrom.sizes"

    # Normalize both blacklist sources to valid BED3 records. This supports
    # BED3, BED4, BED6, narrowPeak, and other BED-compatible inputs.
    awk 'BEGIN { FS=OFS="\\t" }
        !/^#/ && NF >= 3 && \$2 ~ /^[0-9]+\$/ && \$3 ~ /^[0-9]+\$/ && \$2 >= 0 && \$3 > \$2 {
            print \$1, \$2, \$3
        }' "$primaryDAC" > "${composite}.DAC.bed"
    awk 'BEGIN { FS=OFS="\\t" }
        !/^#/ && NF >= 3 && \$2 ~ /^[0-9]+\$/ && \$3 ~ /^[0-9]+\$/ && \$2 >= 0 && \$3 > \$2 {
            print "dm3_" \$1, \$2, \$3
        }' "$dm3DAC" >> "${composite}.DAC.bed"

    bwa index "${composite}.fa"
    samtools faidx "${composite}.fa"

    # Verify that the concatenated size files exactly describe the FASTA used
    # for alignment.
    cut -f1,2 "${composite}.fa.fai" > "${composite}.chrom.sizes.from_fasta"
    cmp "${composite}.chrom.sizes" "${composite}.chrom.sizes.from_fasta"
    rm "${composite}.chrom.sizes.from_fasta"

    # Keep the generated composite reference beside the downloaded references,
    # matching the existing reference-cache behavior of the pipeline.
    cp "${composite}.fa" "${refDir}/${composite}.fa"
    cp "${composite}.fa.amb" "${refDir}/${composite}.fa.amb"
    cp "${composite}.fa.ann" "${refDir}/${composite}.fa.ann"
    cp "${composite}.fa.bwt" "${refDir}/${composite}.fa.bwt"
    cp "${composite}.fa.pac" "${refDir}/${composite}.fa.pac"
    cp "${composite}.fa.sa" "${refDir}/${composite}.fa.sa"
    cp "${composite}.fa.fai" "${refDir}/${composite}.fa.fai"
    cp "${composite}.chrom.sizes" "${refDir}/${composite}.chrom.sizes"
    cp "${composite}.DAC.bed" "${refDir}/${composite}.DAC.bed"
    """
}
