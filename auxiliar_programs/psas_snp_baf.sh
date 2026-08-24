#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 input.vcf.gz [output.tsv]" >&2
    exit 1
fi

vcf="$1"
if [ ! -f "$vcf" ]; then
    echo "Error: input VCF not found: $vcf" >&2
    exit 1
fi

if [ "$#" -eq 2 ]; then
    out="$2"
else
    base="$(basename "$vcf")"
    base="${base%.vcf.gz}"
    base="${base%.vcf}"
    out="${base}.baf.tsv"
fi

bcftools query \
    -i 'GT="het" && FMT/DP>=0' \
    -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT\t%AD\t%DP]\n' \
    "$vcf" | \
awk 'BEGIN {
    OFS="\t"
    print "CHROM","POS","REF","ALT","GT","AD","DP","BAF"
}
{
    split($6, a, ",")
    ref_depth=a[1]
    alt_depth=a[2]
    if ((ref_depth + alt_depth) > 0) {
        baf=alt_depth/(ref_depth + alt_depth)
        print $1,$2,$3,$4,$5,$6,$7,baf
    }
}' > "$out"

echo "Wrote: $out"
