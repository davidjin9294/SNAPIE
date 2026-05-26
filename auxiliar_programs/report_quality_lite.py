#!/usr/bin/env python
# coding: utf-8

import os
import pandas as pd

def load_csv_from_current_directory(filename):
    current_files = os.listdir(os.getcwd())
    if filename in current_files:
        return pd.read_csv(filename, comment='#')
    else:
        return pd.DataFrame()

str_frags = 'frags_mqc.csv'
str_peaks = 'peaks_mqc.csv'
str_fragle = 'fragle_mqc.csv'
str_frip = 'frip_mqc.csv'

df_frags = load_csv_from_current_directory(str_frags)
df_peaks = load_csv_from_current_directory(str_peaks)
df_fragle = load_csv_from_current_directory(str_fragle)
df_frip = load_csv_from_current_directory(str_frip)

def load_enrichment_csvs():
    current_files = os.listdir(os.getcwd())

    enrichment_files = [
        f for f in current_files
        if f.startswith('enrichment') and f.endswith('.csv')
    ]

    if enrichment_files:
        dataframes = [pd.read_csv(f) for f in enrichment_files]
        return pd.concat(dataframes, ignore_index=True)
    else:
        return pd.DataFrame()

df_enrichment = load_enrichment_csvs()

def join_sample_dataframes(df_frags, df_peaks, df_fragle, df_enrichment, df_frip):
    merged = pd.merge(df_frags, df_peaks, on='SampleName', how='inner')

    if not df_fragle.empty:
        merged = pd.merge(
            merged,
            df_fragle,
            left_on='SampleName',
            right_on='Sample_ID',
            how='left'
        )

    if not df_enrichment.empty:
        merged = pd.merge(
            merged,
            df_enrichment,
            on='SampleName',
            how='outer'
        )

    if not df_frip.empty:
        merged = pd.merge(
            merged,
            df_frip,
            on='SampleName',
            how='outer'
        )

    return merged

dfJoin = join_sample_dataframes(
    df_frags,
    df_peaks,
    df_fragle,
    df_enrichment,
    df_frip
)

dfJoin = dfJoin.drop(
    columns=[
        'on_bp',
        'off_bp',
        'on_reads',
        'Sample_ID',
        'off_reads'
    ],
    errors='ignore'
)

dfJoin = dfJoin.rename(columns={
    'SampleName': 'Sample',
    'Fragments': 'TotalFragments',
    'Peaks': 'TotalPeaks',
    'Peaks_FE_gt10': 'Peaks_FE_gt10',
    'Peaks_FE_gt20': 'Peaks_FE_gt20',
    'ctDNA_Burden': 'ctDNA',
    'mark': 'Enrichment_Mark',
    'enrichment': 'Enrichment_Score'
})

# Put important columns in a clean order at the front.
preferred_order = [
    'Sample',
    'TotalFragments',
    'TotalPeaks',
    'Peaks_FE_gt10',
    'Peaks_FE_gt20',
    'FragmentsInPeaks',
    'FRiP',
    'ctDNA',
    'Enrichment_Mark',
    'Enrichment_Score'
]

existing_preferred = [c for c in preferred_order if c in dfJoin.columns]
remaining_cols = [c for c in dfJoin.columns if c not in existing_preferred]

dfJoin = dfJoin[existing_preferred + remaining_cols]

dfJoin = dfJoin.where(pd.notnull(dfJoin), '')

filename = 'QualityMetrics.csv'
dfJoin.to_csv(filename, index=False, encoding='utf-8')