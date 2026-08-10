process psas_calculate {
  label 'low_cpu_low_mem'

  container = params.containers.psas

  tag "Sample - ${sampleId}"

  publishDir "${workflow.projectDir}/${params.outputFolder}/psas/${sampleId}", mode: 'copy'

  input:
  tuple val(sampleId), path(bafTsv), path(narrowPeak)
  path psasScript

  output:
  tuple val(sampleId), path("${sampleId}.psas.tsv")

  script:
  """
  bash "${psasScript}" "${bafTsv}" "${narrowPeak}" "${sampleId}" "${sampleId}.psas.tsv"
  """
}
