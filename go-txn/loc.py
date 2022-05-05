#!/usr/bin/env python3

# To run this script, set PERENNIAL_PATH, GO_JOURNAL_PATH, GO_NFSD_PATH, and
# MARSHAL_PATH to checkouts of those four projects.

import glob
import os

import numpy as np
import pandas as pd


def goto_path(var_prefix):
    assert var_prefix in ["perennial", "go_nfsd", "go_journal", "marshal"]
    os.chdir(os.environ[var_prefix.upper() + "_PATH"])


def count_lines_file(p):
    """Return the number of lines in file at path p."""
    with open(p) as f:
        return sum(1 for _ in f)


def count_lines_pattern(pat):
    if isinstance(pat, list):
        return sum(count_lines_pattern(sub_pat) for sub_pat in pat)
    return sum(count_lines_file(fname) for fname in glob.glob(pat))


def wc_l(*patterns):
    return sum(count_lines_pattern(pat) for pat in patterns)


def prefix_patterns(prefix, patterns):
    return [prefix + p for p in patterns]


def perennial_table():
    """Generate table with Perennial lines of code."""
    goto_path("perennial")
    helpers = wc_l(
        "src/Helpers/*.v",
        "src/iris_lib/*.v",
        "src/algebra/big_op/*.v",
        "src/algebra/liftable.v",
    )
    ghost_state = wc_l("src/algebra/*.v") - wc_l("src/algebra/liftable.v")
    program_logic = wc_l("src/program_logic/*.v")
    data = [
        (
            "Helper libraries (maps, lifting, tactics)",
            helpers,
        ),
        (
            "Ghost state and resources",
            ghost_state,
        ),
        (
            "Program logic for crashes",
            program_logic,
        ),
        (
            "Perennial total",
            helpers + ghost_state + program_logic,
        ),
    ]
    return pd.DataFrame.from_records(data, columns=["Component", "Lines of Coq"])


def gooselang_table():
    """Generate table with GooseLang lines of code."""
    goto_path("perennial")
    # this is the "core" of GooseLang, which is a bit subjective
    # mainly the intent was to exclude the refinement proof infrastructure
    goose_lang = wc_l(
        prefix_patterns(
            "src/goose_lang/",
            """lang.v lifting.v notation.v proofmode.v
               tactics.v recovery_adequacy.v disk.v""".split(),
        )
    )
    goose_lang_lib_impl = wc_l("src/goose_lang/lib/*/impl.v")
    goose_lang_lib = wc_l(
        prefix_patterns("src/goose_lang/", ["lib/*.v", "lib/*/*.v"]),
        "src/program_proof/disk_lib.v",
    )
    goose_lang_lib_proof = goose_lang_lib - goose_lang_lib_impl
    data = [
        ("GooseLang definition", goose_lang),
        ("Libraries (implementation)", goose_lang_lib_impl),
        ("Libraries (proof)", goose_lang_lib_proof),
        ("GooseLang total", goose_lang + goose_lang_lib),
    ]
    return pd.DataFrame.from_records(data, columns=["Component", "Lines of Coq"])


def program_proof_table():
    """Generate program proof lines of code."""

    # get all lines of code from go-journal
    goto_path("go_journal")
    circ_c = wc_l("wal/0circular.go")
    wal_c = wc_l("wal/*.go") - circ_c - wc_l("wal/*_test.go")
    obj_c = wc_l("obj/obj.go", "buf/buf.go")
    jrnl_c = wc_l("jrnl/jrnl.go", "buf/bufmap.go")
    lockmap_c = wc_l("lockmap/lock.go")
    misc_c = wc_l(
        "addr/addr.go",
        "util/util.go",
        "common/common.go",
    )
    txn_c = wc_l("txn/txn.go", "alloc/alloc.go")
    goto_path("marshal")
    misc_c += wc_l("marshal.go")

    # get all lines of proof from Perennial
    goto_path("perennial")

    goose_refinement_p = wc_l(
        prefix_patterns(
            "src/goose_lang/ffi/", ["jrnl_ffi_facts.v", "atomic_refinement.v"]
        )
    )

    os.chdir("src/program_proof")
    circ_p = wc_l("wal/circ_proof*.v")
    wal_heapspec_p = wc_l("wal/heapspec.v") + wc_l("wal/heapspec_lib.v")
    wal_p = (
        wc_l("wal/*.v")
        # don't double-count
        - circ_p
        - wal_heapspec_p
        # just an experiment, not used
        - wc_l("wal/heapspec_list.v")
    )
    obj_p = wc_l("obj/*.v", "buf/defs.v", "buf/buf_proof.v")
    jrnl_p = wc_l("jrnl/jrnl_proof.v", "buf/bufmap_proof.v")
    sep_jrnl_p = wc_l("jrnl/sep_jrnl_*.v")
    lockmap_p = wc_l("lockmap_proof.v", "crash_lockmap_proof.v")
    misc_p = wc_l(
        "addr/*.v",
        "marshal_block.v",
        "marshal_proof.v",
        "util_proof.v",
    )
    txn_p = wc_l(
        prefix_patterns("txn/", ["twophase_proof.v", "wrapper_proof.v"]),
        "alloc/alloc_proof.v",
    )
    txn_refinement_p = goose_refinement_p + wc_l(
        prefix_patterns(
            "txn/twophase_",
            [
                "refinement_defs.v",
                "sub_logical_reln_defs.v",
                "refinement_proof.v",
                "refinement_thm.v",
            ],
        )
    )
    simulation_p = wc_l("../goose_lang/ffi/atomic_refinement.v")

    # note that the table uses -1 as a sentinel for missing data; these are
    # converted to proper pandas missing records at the end, then printed as "---"

    def ratio(n, m):
        if m == 0:
            return -1
        return int(round(float(n) / m))

    def entry(name, code, proof):
        return (name, code, proof, ratio(proof, code))

    def entry_nocode(name, proof):
        return (name, -1, proof, -1)

    schema = [
        ("layer", "U25"),
        ("Lines of code", "i8"),
        ("Lines of proof", "i8"),
        ("Ratio", "i8"),
    ]

    data = np.array(
        [
            entry("circular", circ_c, circ_p),
            ("wal-sts", wal_c, wal_p, ratio(wal_p + wal_heapspec_p, wal_c)),
            entry_nocode("wal", wal_heapspec_p),
            entry("obj", obj_c, obj_p),
            (
                "jrnl-sts",
                jrnl_c,
                jrnl_p,
                ratio(jrnl_p + sep_jrnl_p, jrnl_c),
            ),
            entry_nocode("jrnl", sep_jrnl_p),
            entry("lockmap", lockmap_c, lockmap_p),
            entry("Misc.", misc_c, misc_p),
            entry("txn", txn_c, txn_p),
            entry_nocode("Transaction refinement", txn_refinement_p),
            entry_nocode("Simulation transfer", simulation_p),
        ],
        dtype=schema,
    )
    df = pd.DataFrame.from_records(data)
    total_c = df["Lines of code"].sum()
    total_p = df["Lines of proof"].sum()
    df = df.append(
        pd.DataFrame.from_records(
            np.array(
                [
                    entry("GoTxn total", total_c, total_p),
                ],
                dtype=schema,
            )
        ),
        ignore_index=True,
    ).replace(-1, pd.NA)
    return df


def array_to_latex_table(rows):
    latex_rows = [" & ".join(str(x) for x in row) for row in rows]
    latex = ""
    for index, row in enumerate(latex_rows):
        latex += row
        if row == "\\midrule":
            # hack to make \midrule work
            latex += "\n"
        else:
            latex += " \\\\\n"
    # this has to be in the \input file, otherwise LaTeX adds an extra space to
    # the bottom right cell
    latex += "\\bottomrule"
    return latex


def loc(x):
    if isinstance(x, int):
        return "\\loc{" + str(x) + "}"
    return x


def latex_ratio(x):
    if isinstance(x, int):
        return f"${x}\\times$"
    return x


def perennial_to_latex(df):
    rows = []
    for index, row in df.iterrows():
        if index == len(df) - 1:
            rows.append(["\\midrule"])
        rows.append([row[0], loc(row[1])])
    return array_to_latex_table(rows)


def get_multirow(df, index, col, f):
    x = df.iloc[index, col]
    if index + 1 < len(df) and df.iloc[index + 1, col] == "---":
        return "\\multirow{2}{*}{" + str(f(x)) + "}"
    if x == "---":
        return ""
    return f(x)


def impl_to_latex(df):
    rows = []
    for index, row in df.iterrows():
        layer = row[0]
        if layer.islower():
            layer = "\\textsc{" + layer + "}"
        lines_c = loc(row[1])
        lines_p = loc(row[2])
        # total hack to fix last line lines
        if index == len(df) - 1:
            rows.append(["\\midrule"])
        else:
            ratio = latex_ratio(row[3])
        rows.append([layer, lines_c, lines_p, ratio])
    return array_to_latex_table(rows)


if __name__ == "__main__":
    import argparse
    from os.path import join

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--latex",
        help="output LaTeX table to this directory",
        default=None,
    )

    args = parser.parse_args()

    original_pwd = os.getcwd()

    perennial_df = perennial_table()
    gooselang_df = gooselang_table()
    impl_df = program_proof_table().fillna("---")

    os.chdir(original_pwd)

    if args.latex is None:
        print("Lines of code in Perennial")
        print(perennial_df.to_string(index=False))
        print()

        print("Lines of code in GooseLang")
        print(gooselang_df.to_string(index=False))
        print()

        print("Lines of code for GoTxn")
        print(impl_df.to_string(index=False))
    else:
        with open(join(args.latex, "perennial-loc.tex"), "w") as f:
            print(perennial_to_latex(perennial_df), file=f)
        with open(join(args.latex, "gooselang-loc.tex"), "w") as f:
            print(perennial_to_latex(gooselang_df), file=f)
        with open(join(args.latex, "impl-loc.tex"), "w") as f:
            print(impl_to_latex(impl_df), file=f)
