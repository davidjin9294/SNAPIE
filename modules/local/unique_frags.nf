process unique_frags {
  label 'process_low'

  container params.containers.ubuntu

  tag "Sample - $sampleId" 
  publishDir "${workflow.projectDir}/${params.outputFolder}/frags/${sampleId}", mode : 'copy'

  input:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path (sampleBed),val(_)

  output:
  path ('*.csv')

  exec:
  strCSV = sampleId + '_unique_frags.csv'
  
  script:
  """
  echo $sampleId && wc -l $sampleBed | cut -f1 -d' '  >> $strCSV
  """

}
