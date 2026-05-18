process fastqc {
  label 'med_cpu_med_mem'

  container params.containers.fastqc

  tag "Sample - $sampleId"  
  publishDir "${workflow.projectDir}/${params.outputFolder}/fastqc/${sampleId}", mode : 'copy'
  
  input:
  tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path(reads)

  output:
  tuple val(sampleId), path('*fastqc.html'), path('fastqc_mqc_versions.yml'), path('*fastqc.zip')
  
  script:
  def fastqcCommand = ""

  if (read_method == "PE") {
    fastqcCommand = "fastqc --threads $task.cpus ${reads[0]} ${reads[1]}"
  } else {
    fastqcCommand = "fastqc --threads $task.cpus ${reads[0]}"
  }

  """
  echo "Running FastQC for sample $sampleId in $read_method mode"
  $fastqcCommand

  cat <<-END_VERSIONS > fastqc_mqc_versions.yml
  "${task.process}":
     fastqc: \$( fastqc --version | sed -e "s/FastQC v//g" )
  END_VERSIONS
  """
}