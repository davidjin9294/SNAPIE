process align {
  label 'high_cpu_high_mem'

  container params.containers.bwa_and_samtools

  tag "Sample - $sampleId"
  //publishDir "${workflow.projectDir}/${params.outputFolder}/align/${sampleId}", mode : 'copy'
  
  input:
  tuple val(sampleId), val(enrichment_mark), val(control), val(read_method), path(trimmedFiles), val(_), val(_)
  each path (genomeFile)
  each path (genomeIndexFiles)

  output:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path('*.bam'),path ("align_mqc_versions.yml")

  exec:
  String strBam = sampleId + '.bam'

  script:
  """
  bwa mem $genomeFile $trimmedFiles -t $task.cpus $params.bwa_params | \
   samtools view --threads $task.cpus -Sb -u > $strBam

  cat <<-END_VERSIONS > align_mqc_versions.yml
  "${task.process}":
     bwa: \$( bwa 2>&1 | grep Version | sed -e "s/Version: //g" )
     samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
  END_VERSIONS
  """
}