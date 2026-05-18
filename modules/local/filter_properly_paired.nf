process filter_properly_paired {
  label 'low_cpu_high_mem'

  container params.containers.samtools

  tag "Sample - $sampleId" 
  
  //publishDir "${workflow.projectDir}/${params.outputFolder}/align/${sampleId}", mode : 'copy'
  
  input:
  tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path(sampleBam), val(_)
  
  output:
  tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path('*.bam'), path("samtools_filter_pp_mqc_versions.yml")

  script:
  String strPPBam = sampleId + '.pp.sorted.bam'

  def filterCommand = ""

  if (read_method == "PE") {
    filterCommand = "samtools view -b -f 2 $sampleBam > ${strPPBam}"
  } else {
    // Just copy the original BAM
    filterCommand = "cp $sampleBam ${strPPBam}"
  }

  """
  echo "Filtering BAM for sample $sampleId (mode: $read_method)"
  $filterCommand

  cat <<-END_VERSIONS > samtools_filter_pp_mqc_versions.yml
  "${task.process}":
      samtools: \$(samtools --version | sed 's/^.*samtools //; s/Using.*\$//')
  END_VERSIONS
  """
}