process fragle_ct_estimation {

    label 'high_cpu_high_plus_mem'
    container params.containers.fragle

    tag "All Samples"
    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/fragle/", mode : 'copy'
    
    input:
    path (chBamAndBai)
    
    output:
    path ("Fragle.txt")
    
    script:
    """
    # Rename  .bam e .bai
    for bam in *.filtered.fragle.bam; do
        base=\$(basename "\$bam" .filtered.fragle.bam)
        bai="\$bam.bai"

        mv "\$bam" "\$base.bam"

        if [ -f "\$bai" ]; then
            mv "\$bai" "\$base.bam.bai"
        fi
    done

    WORKDIR=\$PWD
    cd /usr/src/app
    python /usr/src/app/main.py --input \$WORKDIR --output \$WORKDIR --mode R --cpu ${task.cpus} --threads ${task.cpus}
    cd \$WORKDIR
    mv Fragle.csv Fragle.txt
    """
}