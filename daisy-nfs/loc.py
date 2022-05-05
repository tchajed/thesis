#!/usr/bin/env python3

# To run this script, set DAISY_NFSD to a path to mit-pdos/daisy-nfsd

import glob
import os
import shutil
import sqlite3
import subprocess
import sys
import tempfile


def goto_path(var_prefix):
    assert var_prefix in ["daisy_nfsd"]
    os.chdir(os.environ[var_prefix.upper() + "_PATH"])


def count_lines_file(p):
    """Return the number of lines in file at path p."""
    with open(p) as f:
        return sum(1 for _ in f)


def prefix_with(prefix, pats):
    return [prefix + p for p in pats]


def count_lines_pat(pat):
    files = glob.glob(pat, recursive=True)
    if len(files) == 0:
        print(f"pattern {pat} did not match any files", file=sys.stderr)
        sys.exit(1)
    return sum(count_lines_file(f) for f in files)


def wc_l(*pats):
    return sum(count_lines_pat(pat) for pat in pats)


def dirfs_spec_lines():
    sed_cmd = "sed"
    if shutil.which("gsed") is not None:
        sed_cmd = "gsed"
    done = subprocess.run(
        [sed_cmd, "-n", """/public/,/^\s*{/p""", "src/fs/dir_fs.dfy"],
        capture_output=True,
        check=True,
    )
    return sum(1 for _ in done.stdout.split(b"\n"))


def cloc_total(arg):
    with tempfile.NamedTemporaryFile("w") as lang_def_f:
        lang_def_f.write(
            """
Dafny
    filter rm_comments_in_strings " /* */
    filter rm_comments_in_strings " //
    filter call_regexp_common C++
    extension dfy
    3rd_gen_scale 5.00
        """
        )
        lang_def_f.flush()
        cmd = [
            "cloc",
            "--quiet",
            "--sql=-",
            "--include-lang=Dafny",
            "--read-lang-def",
            lang_def_f.name,
            arg,
        ]
        done = subprocess.run(cmd, capture_output=True, check=True)
    conn = sqlite3.connect(":memory:")
    for line in done.stdout.decode("utf-8").split(";"):
        conn.execute(line)
    c = conn.cursor()
    # NOTE: the use of cloc as all kind of unnecessary since we include
    # comments, it's just counting non-blank lines
    c.execute("select sum(nCode + nComment) from t")
    return c.fetchone()[0]


def nfs_spec_lines():
    return cloc_total("src/fs/nfs.s.dfy")


def total_lines():
    return cloc_total("src")


def code_lines():
    # re-implementation of this fish script:
    # rm -rf src-compiled
    # for file in src/*/**.dfy
    #         set -l path (string sub --start 4 $file)
    #         set -l dir (dirname $path)
    #         mkdir -p src-compiled/$dir
    #         dafny /printMode:NoGhost /dafnyVerify:0 /rprint:src-compiled/$path $file &
    #     end
    # wait
    # cloc --read-lang-def ~/dafny-lang.txt src-compiled

    shutil.rmtree("src-compiled", ignore_errors=True)
    # run these in parallel because it's actually quite slow
    procs = []
    for file_path in glob.iglob("src/**/*.dfy", recursive=True):
        path = file_path.lstrip("src/")
        out_path = os.path.join("src-compiled", path)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        p = subprocess.Popen(
            [
                "dafny",
                "/printMode:NoGhost",
                "/dafnyVerify:0",
                "/rprint:" + out_path,
                file_path,
            ],
        )
        procs.append(p)
    for p in procs:
        p.wait()
        if p.returncode != 0:
            print("dafny /printMode:NoGhost failed", file=sys.stderr)
            sys.exit(1)
    lines = cloc_total("src-compiled")
    shutil.rmtree("src-compiled")
    return lines


def trusted_spec_lines():
    # wc -l src/jrnl/*.s.dfy src/machine/*.s.dfy
    # 558 trusted lines of code
    # \newcommand{\daisyTrustedSpec}{\loc{558}\xspace}
    return wc_l("src/jrnl/*.s.dfy", "src/machine/*.s.dfy")


def trusted_code_lines():
    # wc -l nfsd/{fh,mkfs,mount,ops}.go cmd/daisy-nfsd/main.go
    # \newcommand{\daisyTrustedCode}{\loc{1142}\xspace}
    return wc_l(
        *prefix_with("nfsd/", ["fh.go", "mkfs.go", "mount.go", "ops.go"])
    ) + wc_l("cmd/daisy-nfsd/main.go")


def main():
    import argparse
    from os.path import join

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--latex", default=None, help="directory to output latex file to"
    )

    args = parser.parse_args()

    if args.latex:
        args.latex = os.path.abspath(args.latex)

    goto_path("daisy_nfsd")

    lines = {
        "method specs": dirfs_spec_lines(),
        "nfs spec": nfs_spec_lines(),
        "code": code_lines(),
        "total": total_lines(),
        "trusted spec": trusted_spec_lines(),
        "trusted code": trusted_code_lines(),
    }
    lines["spec"] = lines["method specs"] + lines["nfs spec"]
    lines["proof"] = lines["total"] - lines["code"]

    if args.latex:
        with open(join(args.latex, "loc-cmds.tex"), "w") as f:
            for cat, lines in lines.items():
                cmd_name = "\\daisy" + "".join([s.capitalize() for s in cat.split()])
                # triple {{{ }}} means one layer of literal curly braces, then
                # an escaped identifier
                print(
                    f"\\def{cmd_name}{{{lines}}}",
                    file=f,
                )
    else:
        for cat, lines in lines.items():
            print(f"{cat:<15} {lines}")


if __name__ == "__main__":
    main()
