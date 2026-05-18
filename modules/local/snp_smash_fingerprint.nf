process createSMaSHFingerPrint {

    label 'med_cpu_med_mem'
    tag "All Samples"

    container params.containers.python

    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/SMaSH/", mode: 'copy'

    input:
    path (chSNPSMaSH)
    path (chSNPS_ref)
    path (chBamAndBai)

    output:
    path('pval_out.txt')

    script:
    """
    
    # Count BAM files
    num_bams=\$(ls *.bam 2>/dev/null | wc -l)
    echo "[INFO] Number of BAM files: \$num_bams"

    # Check SNP file
    if [[ ! -f "${chSNPS_ref}" ]]; then
        echo "[WARNING] SNP reference file not found: ${chSNPS_ref}"
        snp_ok=false
    elif [[ ! -s "${chSNPS_ref}" ]]; then
        echo "[WARNING] SNP reference file is empty: ${chSNPS_ref}"
        snp_ok=false
    else
        echo "[INFO] SNP reference file is present and non-empty"
        snp_ok=true
    fi

    # Decision logic
    if [[ "\$num_bams" -gt 1 && "\$snp_ok" == true ]]; then
        echo "[INFO] Running SMaSH fingerprint"
        python3 ${chSNPSMaSH} -i ${chSNPS_ref} ALL
    else
        echo "[INFO] Conditions not met. Creating empty pval_out.txt"
        : > pval_out.txt
    fi
    """
}

process createSMaSHFingerPrintPlot{
    label 'med_cpu_med_mem'

    container params.containers.snp_smash_plot

    tag "All Samples"   

    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/SMaSH/", mode : 'copy'
    
    input:
    path (chSMaSHOutout)
    path (chSNPSMaSHPyPlot)

    output:
    path('*.jpg')

    script:
    """
    #Empty input detected. Create an empty JPG.
    if [[ ! -s "$chSMaSHOutout" ]]; then
        touch empty.jpg
    else
        python3 $chSNPSMaSHPyPlot -i $chSMaSHOutout -o Dendrogram_of_Samples_by_SNP_Profile.jpg --logp-max 400 --cmap coolwarm
    fi
    """
}