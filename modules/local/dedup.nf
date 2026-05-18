process dedup {
  label 'process_high'

  container params.containers.picard

  tag "Sample - $sampleId"  
  
  input:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(sampleBam),val(_)

  exec:
  strDedupBam = sampleId + '.dedup.unique.sorted.bam'
  strTxt = sampleId + '-MarkDuplicates.metrics.txt'

  output:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path('*.bam'),path("*.txt"),path ("picard_MarkDuplicates_mqc_versions.yml")
  
  script:
  """
  picard -Xmx${ task.memory.toGiga() - 4 }g MarkDuplicates \\
  I=$sampleBam \\
  O=$strDedupBam \\
  REMOVE_DUPLICATES=true \\
  ASSUME_SORT_ORDER=coordinate \\
  VALIDATION_STRINGENCY=LENIENT \\
  METRICS_FILE=$strTxt

  cat <<-END_VERSIONS > picard_MarkDuplicates_mqc_versions.yml
    "${task.process}":
        picard: \$(echo \$(picard MarkDuplicates --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
  END_VERSIONS
	"""

  
}
