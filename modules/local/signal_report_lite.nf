process signal_report_lite {
    label 'low_cpu_low_mem'
    container params.containers.python

    tag "All Samples"
    publishDir "${workflow.projectDir}/${params.outputFolder}/reports/metrics_lite/", mode: 'copy'

    input:
    path chMergedSignalReport

    output:
    path "SignalMetrics.csv" 

    script:
    """
    touch signal_report_lite_test.csv
    """
}