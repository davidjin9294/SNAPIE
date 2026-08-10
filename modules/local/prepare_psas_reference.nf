process prepare_psas_reference {
  label 'process_low'

  container = params.containers.psas

  tag 'Preparing PSAS reference'

  input:
  path genomeFile
  path refDir

  output:
  tuple path("${params.genome}.fa"), path("${params.genome}.fa.fai"), path("${params.genome}.dict")

  script:
  """
  if [ ! -s "${refDir}/${params.genome}.fa.fai" ]; then
      samtools faidx "${refDir}/${params.genome}.fa"
  fi

  if [ ! -s "${refDir}/${params.genome}.dict" ]; then
      gatk CreateSequenceDictionary \
          -R "${refDir}/${params.genome}.fa" \
          -O "${refDir}/${params.genome}.dict"
  fi

  ln -sf "${refDir}/${params.genome}.fa" "${params.genome}.fa"
  ln -sf "${refDir}/${params.genome}.fa.fai" "${params.genome}.fa.fai"
  ln -sf "${refDir}/${params.genome}.dict" "${params.genome}.dict"
  """
}
