process calcFragsLengthDistribuition {
  label 'med_cpu_med_mem'
  container params.containers.deeptools

  tag "Sample - $sampleId"  
  publishDir "${workflow.projectDir}/${params.outputFolder}/frags/${sampleId}", mode : 'copy'

  input:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(sortedBam),path (sampleBamIndex),val (_)

  output:
  tuple path("*fragment_sizes.txt"), path ("bamPEFragmentSize_mqc_versions.yml")

  script:
  def bamPEFragmentSizeCommand = ""

  if (read_method == "PE") {
    bamPEFragmentSizeCommand = "bamPEFragmentSize -b $sortedBam --outRawFragmentLengths ${sampleId}.fragment_sizes.txt"
    //bamPEFragmentSizeCommand = "touch ${sampleId}.fragment_sizes.txt"
  } else {
    bamPEFragmentSizeCommand = "touch mark_for_deletion_${sampleId}.fragment_sizes.txt"
  }
  """
  echo "Running bamPEFragmentSize for sample $sampleId in $read_method mode"
  $bamPEFragmentSizeCommand

  cat <<-END_VERSIONS > bamPEFragmentSize_mqc_versions.yml
    "${task.process}":
    bamPEFragmentSize: \$(bamPEFragmentSize --version | sed -e "s/bamPEFragmentSize //g")
  END_VERSIONS
  """
}