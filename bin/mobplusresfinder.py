#!/usr/bin/env python3

import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-m', '--mobsuite', required=True, help='mobsuite contig report file')
parser.add_argument('-r', '--resfinder', required=True, help='resfinder results tab file')
parser.add_argument('-o', '--output', required=True, help='output file')
args = parser.parse_args()

# read in both tables
try:
    mob = pd.read_csv(args.mobsuite, sep="\t", usecols=["sample_id", "molecule_type", "primary_cluster_id", "secondary_cluster_id", "contig_id", "rep_type(s)"])
except FileNotFoundError:
    print("Specified mobsuite output file doesn't exist: " + args.mobsuite)
    exit(0)

try:
    res = pd.read_csv(args.resfinder, sep="\t")
except FileNotFoundError:
    print("Specified resfinder output file doesn't exist: " + args.resfinder)
    exit(0)

mob = mob.drop(columns=["sample_id"]).rename(columns={"contig_id": "Contig"})
print(mob)
# merge the dataframes, write result to file
out = pd.merge(res, mob, how="left", on="Contig")
out.to_csv(args.output, sep="\t", index=False)
