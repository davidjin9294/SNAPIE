process sort_bam {
  label 'low_cpu_high_mem'

  container params.containers.samtools

  tag "Sample - $sampleId" 
  
  //publishDir "${workflow.projectDir}/${params.outputFolder}/align/${sampleId}", mode : 'copy'
  
  input:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(sampleBam),val(_)
  
  output:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path('*.bam'),path ("samtools_sort_mqc_versions.yml")

  exec:
  String strBam = sampleId + '.sorted.bam'

  //samtools sort -@ $task.cpus $sampleBam -o $strBam

  script:
  """
  samtools sort -@ $task.cpus $sampleBam -o $strBam

  cat <<-END_VERSIONS > samtools_sort_mqc_versions.yml
  "${task.process}":
      samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
  END_VERSIONS
  """
}

process sort_readname_bam {
  label 'low_cpu_high_mem'

  container params.containers.samtools

  tag "Sample - $sampleId" 
  
  input:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(sampleBam),val (_)
  
  output:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path('*.bam'),path ("samtools_sort_mqc_versions.yml")

  exec:
  String strBam = sampleId + '.n_sorted.bam'


  script:
  def motifCommand = ""
  if (read_method == "PE") {
    sortCommand = "samtools sort -@ $task.cpus -n $sampleBam -o $strBam"
  } else {
    sortCommand = "touch mark_for_deletion_$strBam"  // Create an empty file because this analysis is not valid for single-end reads
  }
  """
  echo "Generating sorting by name sample $sampleId ($read_method)"
  $sortCommand 


  cat <<-END_VERSIONS > samtools_sort_mqc_versions.yml
  "${task.process}":
      samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
  END_VERSIONS
  """
}
