process downloadSNPRef {

    label 'low_cpu_low_mem'
    tag "Downloading SNPs - ${genome}"

    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/multiqc/", mode: 'copy'

    container params.containers.wget

    input:
    tuple val(genome), val(_), val(_), val(_), val(snp), val(_)

    output:
    file "snps_${genome}.vcf"

    script:
    def snpFile = "snps_${genome}.vcf"

    """
    if [[ "${snp}" =~ ^https?:// ]]; then
        echo "[INFO] Detected URL input"

        if wget --spider -q "${snp}"; then
            echo "[INFO] URL exists. Downloading..."
            wget -O ${snpFile} "${snp}"
        else
            echo "[WARNING] URL not accessible. Creating empty VCF file."
            : > ${snpFile}
        fi

    else
        echo "[INFO] Detected local file input"

        if [[ -f "${snp}" ]]; then
            echo "[INFO] Local file exists. Copying..."
            cp "${snp}" ${snpFile}
        else
            echo "[WARNING] Local file not found. Creating empty VCF file."
            : > ${snpFile}
        fi
    fi
    """
}

process downloadTSSPromoterPeaks {

    label 'low_cpu_low_mem'
    tag "Downloading TSS Promoter Peaks - ${genome}"

    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/multiqc/", mode: 'copy'

    container params.containers.wget

    input:
    tuple val(genome), val(_), val(_), val(_), val(_), val(tssPromoterPeaks)

    output:
    file "tss_promoter_peaks_${genome}.bed"

    script:
    def tssFile = "tss_promoter_peaks_${genome}.bed"

    """
    if [[ "${tssPromoterPeaks}" =~ ^https?:// ]]; then
        echo "[INFO] Detected URL input"

        if wget --spider -q "${tssPromoterPeaks}"; then
            echo "[INFO] URL exists. Downloading..."
            wget -O ${tssFile} "${tssPromoterPeaks}"
        else
            echo "[WARNING] URL not accessible. Creating empty BED file."
            : > ${tssFile}
        fi

    else
        echo "[INFO] Detected local file input"

        if [[ -f "${tssPromoterPeaks}" ]]; then
            echo "[INFO] Local file exists. Copying..."
            cp "${tssPromoterPeaks}" ${tssFile}
        else
            echo "[WARNING] Local file not found. Creating empty BED file."
            : > ${tssFile}
        fi
    fi
    """
}

process downloadDACFile {

    label 'low_cpu_low_mem'
    tag "Dowloading DAC File - ${genome}"

    container params.containers.wget

    input:
    tuple val(genome), val(faGZFile), val(geneAnnotation), val(dacList), val(snp), val(tssPromoterPeaks)
    path refDir

    output:
    file "${genome}.DAC.bed"

    script:
    def dacFile   = "${genome}.DAC.bed"
    def dacFilegz = "${genome}.DAC.bed.gz"

    """
    mkdir -p "${refDir}"

    # If cached uncompressed file exists, reuse it
    if [[ -f "${refDir}/${dacFile}" ]]; then
        echo "[INFO] File ${refDir}/${dacFile} already exists. Skipping download."

    else
        # Need to create it (from URL or local)
        if [[ "${dacList}" =~ ^https?:// ]]; then
            echo "[INFO] Detected URL input"

            if wget --spider -q "${dacList}"; then
                echo "[INFO] URL exists. Downloading gz and unzipping..."
                wget -O "${refDir}/${dacFilegz}" "${dacList}"

                if gunzip -f "${refDir}/${dacFilegz}"; then
                    echo "[INFO] Unzipped successfully."
                else
                    echo "[WARNING] gunzip failed. Creating empty DAC BED."
                    : > "${refDir}/${dacFile}"
                    rm -f "${refDir}/${dacFilegz}" || true
                fi
            else
                echo "[WARNING] URL not accessible. Creating empty DAC BED."
                : > "${refDir}/${dacFile}"
            fi

        else
            echo "[INFO] Detected local file input"

            if [[ -f "${dacList}" ]]; then
                echo "[INFO] Local file exists. Copying into refDir..."
                cp "${dacList}" "${refDir}/${dacFile}"
            else
                echo "[WARNING] Local file not found. Creating empty DAC BED."
                : > "${refDir}/${dacFile}"
            fi
        fi
    fi

    # Link into task workdir as the official process output
    ln -sf "${refDir}/${dacFile}" "${dacFile}"
    """
}

process downloadGeneAnotation {

    label 'low_cpu_low_mem'
    tag "Dowloading Gene Anotation File - $genome" 

    container params.containers.wget
    
    input:
    tuple val(genome), val(faGZFile), val(geneAnnotation), val(dacList), val(snp), val(tssPromoterPeaks)
    path refDir

    output:
    file "${genome}.GeneAnotation.gtf"

    script:
    def gtfFile = "${genome}.GeneAnotation.gtf"
    def gtfFilegz = "${genome}.GeneAnotation.gtf.gz"
    

    """
    if [ ! -f ${refDir}/${gtfFile} ]; then
        wget -O ${refDir}/${gtfFilegz} ${geneAnnotation}
        gunzip ${refDir}/${gtfFilegz} 
    else
        echo "File ${refDir}/${gtfFile} already exists. Skipping download."
    fi
    ln -s ${refDir}/${gtfFile} ${gtfFile}
    """
}

process downloadGenome {

    label 'low_cpu_low_mem'
    tag "Dowloading - $genome" 
    //publishDir "$genomeOut", mode : 'copy'

    container params.containers.wget
    
    exec:
    genomeOut = refDir

    input:
    tuple val(genome), val(faGZFile), val(geneAnnotation), val(dacList), val(snp), val(tssPromoterPeaks)
    path refDir

    output:
    file "${genome}.fa"

    script:
    def genomeFile = "${genome}.fa"
    def genomeFilegz = "${genome}.fa.gz"
    
    """
    if [ ! -f ${refDir}/${genomeFile} ]; then
        wget -O ${refDir}/${genomeFilegz} ${faGZFile}
        gunzip ${refDir}/${genomeFilegz} 
    else
        echo "File ${refDir}/${genomeFile} already exists. Skipping download."
    fi
    ln -s ${refDir}/${genomeFile} ${genomeFile}
    """
}