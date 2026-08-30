nextflow.enable.dsl=2

// Import the required processes from the modules
include {createSamplesheetFasta} from '../../modules/local/createSamplesheet'
include {createSamplesheetBam} from '../../modules/local/createSamplesheet'
include {fastqc} from '../../modules/local/fastqc'
include {multiqc} from '../../modules/local/multiqc'
include {moveSoftFiles} from '../../modules/local/moveSoftFiles'

workflow PREPROCESSING {

    take:
    chMultiQCConfig
    chSkipAlignment

    main:

    // Create the genome directory if it doesn't exist
    """
    mkdir -p ${projectDir}/ref_files/genome
    """.execute().waitFor()
    refDir = Channel.fromPath("${projectDir}/ref_files/genome")

    // Read the GenomePaths spreadsheet and filter the row that matches the genome parameter
    chGenomesSheet = Channel.fromPath(params.genomeInfoPaths)
    chGenomesInfo = chGenomesSheet \
        | splitCsv(header:true) \
        | filter { row -> row.Genome == params.genome } \
        | ifEmpty { error "No matching Genome found in the GenomePaths spreadsheet. Exiting workflow." }
        | map { row-> tuple(row.Genome,row.faGZFile,row.GeneAnotation, row.DACList,row.SNP,row.TSSPromoterPeaks) }

    // The dm3 metadata is kept separate from the selected primary genome.  It is
    // used only to construct a composite alignment reference when requested.
    chDm3Info = Channel.empty()
    if (params.dm3_control_included) {
        chDm3Info = Channel.fromPath(params.genomeInfoPaths) \
            | splitCsv(header:true) \
            | filter { row -> row.Genome == 'dm3' } \
            | ifEmpty { error "dm3_control_included is enabled, but no dm3 row was found in ${params.genomeInfoPaths}." } \
            | map { row-> tuple(row.Genome,row.faGZFile,row.GeneAnotation, row.DACList,row.SNP,row.TSSPromoterPeaks) }
    }
    // Destructure and store each column into separate variables
    chGenomesInfo
        .map { genome, faGZFile, geneAnnotation, dacList, snp, tssPromoterPeaks ->
            [genome, faGZFile, geneAnnotation, dacList, snp, tssPromoterPeaks]
        }

    if (chSkipAlignment) {
        if (params.samplesheetBams) {
            chSampleSheetBams = Channel.fromPath(params.samplesheetBams)
        } else if (params.sample_dir_bam) {
            chSampleSheetBams = createSamplesheetBam(params.sample_dir_bam, params.enrichment_mark, params.sample_control,params.read_method)
        } 
        
    } else {
        if (params.samplesheetfasta) {
            //Using provided samplesheet: ${params.samplesheet}
            chSampleSheetFasta = Channel.fromPath(params.samplesheetfasta)
        } else if (params.sample_dir_fasta) {
            //Creating samplesheet because none was provided
            chSampleSheetFasta = createSamplesheetFasta (params.sample_dir_fasta, params.enrichment_mark, params.sample_control)
        }    
    }

    chFastaQC = Channel.of("NO_DATA")
    chFilesReportInitialization = Channel.of("NO_DATA")
    chInitReport = Channel.of("NO_DATA")
    
    if (chSkipAlignment) {
        chSampleInfo = chSampleSheetBams \
            | splitCsv(header:true) \
            | map { row-> tuple(row.sampleId,row.enrichment_mark, row.bam, row.control, row.read_method) 
            }
    } else {
        chSampleInfo = chSampleSheetFasta \
            | splitCsv(header: true) \
            | map { row ->
                def reads = [file(row.read1)]
                def read_method = "SE"
                if (row.read2) {
                    reads << file(row.read2)
                    read_method = "PE"
                }
                tuple(row.sampleId, row.enrichment_mark, row.control, read_method, reads)
            }

            // Run FastQC on the samples
            chFastaQC = fastqc(chSampleInfo)
            chFastaQCAll = chFastaQC.collect()

            // Filter only the files that will be used in the MultiQC report and remove duplicates
            chOnlyFiles = chFastaQCAll
            .flatten() // Make sure the files are in a single flow
            .collect() // Joins all files before processing them
            .map { files -> 
                def uniqueFiles = [:] as LinkedHashMap
                files.findAll { it instanceof Path } // Keeps only files (Path)
                    .each { file -> uniqueFiles.putIfAbsent(file.getName(), file) } // Keeps only the first occurrence of the name
                return uniqueFiles.values()  // Returns only unique files
            } 
            .flatten()
            chFilesReportInitialization = chOnlyFiles.collect()

            // Create the MultiQC report and move the soft files only if this is the last process
            if (params.until == 'PREPROCESSING' || params.until == 'DOWNLOAD_REFERENCES') {
                chInitReport = multiqc(chFastaQCAll,chFilesReportInitialization,chMultiQCConfig)
                moveSoftFiles(chInitReport)
            }
        }
    
    emit: sample_info = chSampleInfo
    emit: genomes_info = chGenomesInfo
    emit: dm3_info = chDm3Info
    emit: fastqc_files = chFastaQC
    emit: ref_dir = refDir
    emit: files_report_initialization = chFilesReportInitialization
    emit: init_report = chInitReport

}
