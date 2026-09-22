process psas_calculate {
  label 'low_cpu_low_mem'

  container = params.containers.psas

  tag "Sample - ${sampleId}"

  input:
  tuple val(sampleId), path(bafTsv), path(peakFile)
  path psasScript

  output:
  tuple val(sampleId), path("${sampleId}.psas.tsv")

  script:
  """
  bash "${psasScript}" "${bafTsv}" "${peakFile}" "${sampleId}" "${sampleId}.psas.tsv"
  """
}
