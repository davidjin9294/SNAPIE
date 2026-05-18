process quality_filter {
  label 'low_cpu_low_mem'
  container params.containers.samtools

  tag "Sample - $sampleId" 
  publishDir "${workflow.projectDir}/${params.outputFolder}/align/${sampleId}", mode: 'copy'

  input:
  tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path(sampleBam), val(_)

  output:
  tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path('*.bam'), path("samtools_QualityFilter_mqc_versions.yml")

  script:
  String strBam = sampleId + '.filtered.unique.sorted.bam'
  String filterCommand = ""

  if (read_method == "PE") {
    // Only apply inclusion flag (-f) for paired-end
    filterCommand = "samtools view -bh ${params.filter_samtools_pe_params} --threads $task.cpus $sampleBam > $strBam"
  } else {
    // Skip -f for single-end
    filterCommand = "samtools view -bh ${params.filter_samtools_se_params} --threads $task.cpus $sampleBam > $strBam"
  }

  """
  echo "Running samtools quality filter for sample $sampleId in $read_method mode"
  $filterCommand

  cat <<-END_VERSIONS > samtools_QualityFilter_mqc_versions.yml
  "${task.process}":
    samtools: \$(samtools --version | sed 's/^.*samtools //; s/Using.*\$//')
  END_VERSIONS
  """
}