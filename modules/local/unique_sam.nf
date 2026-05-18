process unique_sam {
  label 'process_low'

  container params.containers.samtools

  tag "Sample - $sampleId" 
  
  input:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(sampleBam),val(_)

  output:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path('*.bam'),path ("samtools_unique_mqc_versions.yml")

  exec:
  String strBam = sampleId + '.unique.sorted.bam'
  
  script:
  """
  samtools view --threads $task.cpus -b -q 1 $sampleBam > $strBam

  cat <<-END_VERSIONS > samtools_unique_mqc_versions.yml
  "${task.process}":
      samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
  END_VERSIONS
  """
}
