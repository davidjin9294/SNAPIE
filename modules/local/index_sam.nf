process index_sam {
  label 'low_cpu_low_mem'

  container params.containers.samtools

  tag "Sample - $sampleId"   

  publishDir "${workflow.projectDir}/${params.outputFolder}/align/${sampleId}", mode : 'copy'
  
  input:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(sampleBam),val (_)

  output:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(sampleBam),path ('*.bai'),path ("index_sam_mqc_versions.yml")
  
  script:
  """
  samtools index -@ $task.cpus $sampleBam

  cat <<-END_VERSIONS > index_sam_mqc_versions.yml
  "${task.process}":
      samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
  END_VERSIONS
  """
}
