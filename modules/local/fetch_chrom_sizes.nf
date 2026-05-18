process fetch_chrom_sizes{
  label 'process_low'
  
  //Docker Image
  container params.containers.ucsc_fetchchromsizes

  tag "Fetch Chrom Sizes - $genome"   
  //publishDir "$refDir/genome", mode : 'copy'

  input:
  tuple val(genome), val(faGZFile), val(geneAnnotation), val(dacList), val(snp), val(tssPromoterPeaks)
  path refDir

  output:
  path ('*.sizes')
  
  script:
  def chromSizeFile = "${genome}.chrom.sizes"
  """
  if [ ! -f ${refDir}/${chromSizeFile} ]; then
    echo "Downloading chrom sizes for $genome using fetchChromSizes..."
    fetchChromSizes $genome > ${refDir}/${chromSizeFile}
  else
    echo "File ${refDir}/${chromSizeFile} already exists. Skipping download."
  fi

  if [ ! -L ${chromSizeFile} ]; then
    ln -s ${refDir}/${chromSizeFile} ${chromSizeFile}
  else
    echo "Symbolic link ${chromSizeFile} already exists. Skipping link creation."
  fi
  """

  /*if [ ! -f ${refDir}/${chromSizeFile} ]; then
    fetchChromSizes $genome > ${chromSizeFile}
  else
    echo "File ${refDir}/${chromSizeFile} already exists. Skipping download."
  fi
  
  ln -s ${refDir}/${chromSizeFile} ${chromSizeFile}*/
}
