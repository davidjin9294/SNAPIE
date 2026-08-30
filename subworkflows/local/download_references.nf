nextflow.enable.dsl=2

// Import the required processes from the modules
include {downloadGenome} from '../../modules/local/download'
include {downloadGenome as downloadDm3Genome} from '../../modules/local/download'
include {downloadDACFile} from '../../modules/local/download'
include {downloadDACFile as downloadDm3DACFile} from '../../modules/local/download'
include {downloadSNPRef} from '../../modules/local/download'
include {downloadTSSPromoterPeaks} from '../../modules/local/download'
include {createGenomeIndex} from '../../modules/local/createGenomeIndex'
include {fetch_chrom_sizes} from '../../modules/local/fetch_chrom_sizes'
include {fetch_chrom_sizes as fetch_dm3_chrom_sizes} from '../../modules/local/fetch_chrom_sizes'
include {createCompositeReference} from '../../modules/local/create_composite_reference'

workflow DOWNLOAD_REFERENCES {

    take:
    chGenomesInfo
    chDm3Info
    chrefDir

    main:

    chGenome = downloadGenome(chGenomesInfo, chrefDir)
    chChromSizes = fetch_chrom_sizes(chGenomesInfo,chrefDir)
    chDACFileRef = downloadDACFile(chGenomesInfo,chrefDir)
    chSNPS_ref = downloadSNPRef(chGenomesInfo)
    chTSSPromoterPeaks_ref = downloadTSSPromoterPeaks(chGenomesInfo)

    if (params.dm3_control_included) {
        chDm3Genome = downloadDm3Genome(chDm3Info, chrefDir)
        chDm3ChromSizes = fetch_dm3_chrom_sizes(chDm3Info, chrefDir)
        chDm3DACFileRef = downloadDm3DACFile(chDm3Info, chrefDir)

        chPrimaryGenomeName = chGenomesInfo.map { genome, faGZFile, geneAnnotation, dacList, snp, tssPromoterPeaks -> genome }
        chComposite = createCompositeReference(
            chPrimaryGenomeName,
            chGenome,
            chDm3Genome,
            chChromSizes,
            chDm3ChromSizes,
            chDACFileRef,
            chDm3DACFileRef,
            chrefDir
        )

        chGenome = chComposite.composite_fasta
        chGenomeIndex = chComposite.composite_index
        chChromSizes = chComposite.composite_chrom_sizes
        chDACFileRef = chComposite.composite_dac
    } else {
        chGenomeIndex = createGenomeIndex(chGenomesInfo,chGenome, chrefDir)
    }

    emit: genome = chGenome
    emit: genome_index = chGenomeIndex
    emit: chrom_sizes = chChromSizes
    emit: dac_file_ref = chDACFileRef
    emit: snp_ref = chSNPS_ref
    emit: tss_promoter_peaks_ref = chTSSPromoterPeaks_ref

}
