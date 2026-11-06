#!/usr/bin/env python3
# Merges per-sample TSV rows (produced by xlsxreport.py) into one Excel file.

import argparse
import pandas as pd
import json

# this seems like an inefficient way to handle this problem, but it is the easiest for now
def emptyheader(infile, sep="\t"):
    rows = 0
    with open(infile) as f:
        for line in f:
            n = line.count(sep)
            if n > rows:
                rows = n

    return [str(i) for i in range(0, rows + 1)]


def parse_parameters(params_path):
    with open(params_path) as f:
        params_dict = json.load(f)
    manifest = params_dict.pop("manifest", {})
    df = pd.DataFrame.from_dict(params_dict, orient='index', columns=["value"])
    return df, manifest.get("version", "")

def parse_versions(versions_path):
    """
    Parse versions.json (a flat list of [process, tool, version] triples,
    written by COMBINE_XLSX via topic channel + JsonBuilder) into a
    deduplicated, sorted DataFrame.
    """
    with open(versions_path) as f:
        versions_list = json.load(f)
    versions_dict = {it[1]: it[2:] for it in versions_list}
    return versions_dict


def makepretty(ws):
    for col_cells in ws.columns:
        max_len = max(len(str(c.value)) if c.value is not None else 0
                for c in col_cells)
        ws.column_dimensions[col_cells[0].column_letter].width = max_len + 2

        
def main():
    tooltab = {
    "sistr":    "SISTR",
    "mlst":     "MLST",
    "res":      "Resfinder",
    "point":    "Pointfinder",
    "spi":      "SPIfinder",
    "abricate": "Abricate",
    "seqsero":  "SeqSero",
    "mob":      "Mobsuite_summary",
    "mge": "Mobsuite_mge",
    }
    parser = argparse.ArgumentParser()
    for flag, tab in tooltab.items():
        parser.add_argument(f"--{flag}", help=f"table to put under {tab} tab")
    parser.add_argument("--versions", help="YAML formatted tool versions")
    parser.add_argument("--params", help="YAML formatted pipeline parameters")
    parser.add_argument("--sep", default="\t", help="delimiter for the input files")
    parser.add_argument("--output", default="summary_report.xlsx")
    args = parser.parse_args()

    if args.versions:
        vdict = parse_versions(args.versions)
    else:
        vdict = {}

    if args.params:
        paramdf, pversion = parse_parameters(args.params)
    else:
        pversion = ""
    
    ws = {}
    with pd.ExcelWriter(args.output, engine="openpyxl") as writer:
        for flag, tab in tooltab.items():
            path = getattr(args, flag)   # None if the flag wasn't given
            if path is None:
                continue
            try:
                df = pd.read_csv(path, sep=args.sep, header=None, names=emptyheader(path, args.sep))
            except:
                continue
            df.to_excel(writer, sheet_name=tab, index=False, header=False)
            ws[flag] = writer.sheets[tab]
            makepretty(ws[flag])

        if vdict:
            if pversion:
                vdict["this pipeline"] = pversion

            vdf = pd.DataFrame.from_dict(vdict, orient='index', columns=["value"])
            vdf.to_excel(writer, sheet_name="Versions")
            wsv = writer.sheets["Versions"]
            makepretty(wsv)
                

        if args.params:
            paramdf.to_excel(writer, index=True, sheet_name="Parameters")
            wsp = writer.sheets["Parameters"]
            makepretty(wsp)

    print(f"Wrote {args.output}", flush=True)


if __name__ == "__main__":
    main()
