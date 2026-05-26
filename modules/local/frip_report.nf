process frip_report {
    label 'low_cpu_low_mem'
    container = params.containers.bedtools
    tag "All Samples"

    input:
    path (bed_files)
    path (peak_files)

    output:
    path "frip_mqc.csv"

    script:
    """
    echo "SampleName,FragmentsInPeaks,FRiP" > frip_mqc.csv

    for bed in *.bed; do
        sample=\${bed%.bed}
        peak="\${sample}_peaks.narrowPeak"

        if [[ ! -f "\$peak" ]]; then
            echo "WARNING: No peak file for \$sample" >&2
            continue
        fi

        total_fragments=\$(wc -l < "\$bed")

        fragments_in_peaks=\$(bedtools intersect \\
            -u \\
            -a "\$bed" \\
            -b "\$peak" \\
            | wc -l)

        frip=\$(awk -v x="\$fragments_in_peaks" -v y="\$total_fragments" \\
            'BEGIN{if(y>0){printf "%.6f", x/y}else{print ""}}')

        echo "\$sample,\$fragments_in_peaks,\$frip" >> frip_mqc.csv
    done
    """
}