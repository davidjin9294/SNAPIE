process bam_to_bed {
  label 'process_medium'

  //Docker Image
  container params.containers.bedtools

  tag "Sample - $sampleId"  

  publishDir "${workflow.projectDir}/${params.outputFolder}/frags/${sampleId}", mode : 'copy'
  
  input:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path(sampleBam),val (_)

  exec:
  String strBed = sampleId + '.bed'

  output:
  tuple val(sampleId),val(enrichment_mark),val(control),val(read_method),path ('*.bed'),path ("bam_to_bed_mqc_versions.yml")

  script:
    def bedCommand = ""

    if (read_method == "PE") {
      bedCommand = "bedtools bamtobed -i $sampleBam -bedpe | awk 'BEGIN{OFS=\"\\t\";FS=\"\\t\"} (\$1==\$4){print \$1, \$2, \$6}' > $strBed"
    } else {
      bedCommand = "bedtools bamtobed -i $sampleBam | awk 'BEGIN{OFS=\"\\t\"} {print \$1, \$2, \$3}' > $strBed"
    }

    """
    echo "Running bedtools bamtobed for sample $sampleId in $read_method mode"
    $bedCommand

      cat <<-END_VERSIONS > bam_to_bed_mqc_versions.yml
      "${task.process}":
          bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
    END_VERSIONS
    """
  }