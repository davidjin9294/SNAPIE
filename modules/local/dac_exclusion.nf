process dac_exclusion {
  label 'low_cpu_low_mem'

  container params.containers.bedtools
  
  tag "Sample - $sampleId"  
  publishDir "${workflow.projectDir}/${params.outputFolder}/align/${sampleId}", mode : 'copy'

  input:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(dedupBam),val(_),val(_)
  each path (sampleDAC)

  exec:
  strBam = sampleId + '.dac_filtered.dedup.unique.sorted.bam'

  output:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(strBam),path ("dac_exclusion_mqc_versions.yml")

  script:
  """
  bedtools intersect -v -abam $dedupBam -b $sampleDAC > ${sampleId}.tmp
  mv ${sampleId}.tmp $strBam
  
  cat <<-END_VERSIONS > dac_exclusion_mqc_versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
  END_VERSIONS
	"""
}
