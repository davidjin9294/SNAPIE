#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 BAF_TSV NARROW_PEAK SAMPLE_ID OUTPUT_TSV" >&2
    exit 1
fi

python3 - "$@" <<'PYTHON'
"""Calculate PSAS from a sample BAF TSV and its MACS2 narrowPeak file."""

import argparse
import bisect
import csv
import math


MIN_DEPTH = 3
AUTOSOMES = {str(chrom) for chrom in range(1, 23)}


def arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baf_tsv")
    parser.add_argument("narrow_peak")
    parser.add_argument("sample_id")
    parser.add_argument("output_tsv")
    return parser.parse_args()


def chromosome(value):
    value = value.strip()
    return value[3:] if value.lower().startswith("chr") else value


def load_peaks(path):
    peaks = {}
    with open(path) as handle:
        for line in handle:
            if not line.strip() or line.startswith("#"):
                continue
            fields = line.rstrip("\n").split("\t")
            if len(fields) < 3:
                continue
            chrom = chromosome(fields[0])
            if chrom not in AUTOSOMES:
                continue
            try:
                start, end = int(fields[1]), int(fields[2])
            except ValueError:
                continue
            if end > start:
                peaks.setdefault(chrom, []).append((start, end))

    for chrom, intervals in peaks.items():
        merged = []
        for start, end in sorted(intervals):
            if not merged or start > merged[-1][1]:
                merged.append([start, end])
            else:
                merged[-1][1] = max(merged[-1][1], end)
        peaks[chrom] = (merged, [start for start, _ in merged])
    return peaks


def in_peak(peaks, chrom, position):
    indexed = peaks.get(chromosome(chrom))
    if not indexed:
        return False
    intervals, starts = indexed
    position0 = position - 1
    index = bisect.bisect_right(starts, position0) - 1
    return index >= 0 and position0 < intervals[index][1]


def calculate_psas(baf_path, peak_path):
    peaks = load_peaks(peak_path)
    total = 0.0
    count = 0

    with open(baf_path, newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        required = {"CHROM", "POS", "DP", "BAF"}
        if reader.fieldnames is None or not required.issubset(reader.fieldnames):
            missing = sorted(required.difference(reader.fieldnames or []))
            raise ValueError(f"{baf_path}: missing required columns: {', '.join(missing)}")

        for row in reader:
            chrom = chromosome(row["CHROM"])
            if chrom not in AUTOSOMES:
                continue
            try:
                position = int(row["POS"])
                depth = float(row["DP"])
                baf = float(row["BAF"])
            except (TypeError, ValueError):
                continue
            if (
                not math.isfinite(depth)
                or not math.isfinite(baf)
                or depth < MIN_DEPTH
                or not 0.0 <= baf <= 1.0
                or not in_peak(peaks, chrom, position)
            ):
                continue

            deviation = abs(baf - 0.5)
            total += math.sqrt(max(deviation * deviation - 0.25 / depth, 0.0))
            count += 1

    return total / count if count else None


def main():
    args = arguments()
    psas = calculate_psas(args.baf_tsv, args.narrow_peak)
    if psas is not None:
        psas = psas * (-1)
    with open(args.output_tsv, "w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(["sample_id", "psas"])
        writer.writerow([args.sample_id, "NA" if psas is None else f"{psas:.8g}"])


if __name__ == "__main__":
    main()
PYTHON
