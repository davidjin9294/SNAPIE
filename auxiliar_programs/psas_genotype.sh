#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 5 ] || [ "$#" -gt 6 ]; then
    echo "Usage: $0 input.bam reference.fa reference.fa.fai reference.dict output.vcf.gz [threads]" >&2
    exit 1
fi

input_bam="$1"
input_ref="$2"
input_ref_fai="$3"
input_ref_dict="$4"
out_vcf="$5"
threads="${6:-1}"

for input_file in "$input_bam" "$input_ref" "$input_ref_fai" "$input_ref_dict"; do
    if [ ! -f "$input_file" ]; then
        echo "Error: input file not found: $input_file" >&2
        exit 1
    fi
done

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

bam_base="$(basename "$input_bam")"
sid="${bam_base%.bam}"
work_bam="${tmpdir}/${sid}.rgfixed.bam"

gatk AddOrReplaceReadGroups \
    -I "$input_bam" \
    -O "$work_bam" \
    -RGID "$sid" \
    -RGLB lib1 \
    -RGPL ILLUMINA \
    -RGPU "${sid}.unit1" \
    -RGSM "$sid"
samtools index -@ "$threads" "$work_bam"

chroms=()
while IFS=$'\t' read -r chrom _; do
    if [[ "$chrom" =~ ^chr([1-9]|1[0-9]|2[0-2]|X|Y)$ ]] || [[ "$chrom" =~ ^([1-9]|1[0-9]|2[0-2]|X|Y)$ ]]; then
        chroms+=("$chrom")
    fi
done < "$input_ref_fai"

if [ "${#chroms[@]}" -eq 0 ]; then
    echo "Error: reference has no canonical human chromosomes" >&2
    exit 1
fi

raw_vcfs=()
for chrom in "${chroms[@]}"; do
    gvcf="${tmpdir}/${sid}.${chrom}.g.vcf.gz"
    raw_vcf="${tmpdir}/${sid}.${chrom}.raw.vcf.gz"
    gatk HaplotypeCaller \
        -R "$input_ref" -I "$work_bam" -L "$chrom" \
        -O "$gvcf" -ERC GVCF \
        --native-pair-hmm-threads "$threads"
    gatk GenotypeGVCFs \
        -R "$input_ref" -V "$gvcf" -O "$raw_vcf"
    raw_vcfs+=("$raw_vcf")
done

bcftools concat -Oz -o "${tmpdir}/merged.vcf.gz" "${raw_vcfs[@]}"
bcftools index -t "${tmpdir}/merged.vcf.gz"
bcftools norm -f "$input_ref" -m -any "${tmpdir}/merged.vcf.gz" \
    -Oz -o "${tmpdir}/norm.vcf.gz"
bcftools index -t "${tmpdir}/norm.vcf.gz"
bcftools view -v snps -m2 -M2 -i 'QUAL>=30' "${tmpdir}/norm.vcf.gz" \
    -Oz -o "$out_vcf"
tabix -p vcf "$out_vcf"

echo "Done: $out_vcf"
