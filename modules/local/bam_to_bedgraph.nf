process bam_to_bedgraph {
  label 'med_cpu_med_mem'
  container params.containers.bedtools

  tag "Sample - $sampleId"  

  //publishDir "${workflow.projectDir}/${params.outputFolder}/peaks/${sampleId}", mode : 'copy'

  input:
  tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path(sortedBam), path(sampleBamIndex), val(_)

  output:
  tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path('*.bedgraph'), path("bam_to_bedgraph_mqc_versions.yml")

  script:
  def covCmd = ""
  def strBedgraph = "${sampleId}.bedgraph"

  if (read_method == "PE") {
    covCmd = "bedtools genomecov -ibam $sortedBam -bg -pc > $strBedgraph"
  } else {
    covCmd = "bedtools genomecov -ibam $sortedBam -bg > $strBedgraph"
  }

  """
  echo "Running bedtools genomecov for sample $sampleId in $read_method mode"
  $covCmd

  cat <<-END_VERSIONS > bam_to_bedgraph_mqc_versions.yml
  "${task.process}":
      bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
  END_VERSIONS
  """
}