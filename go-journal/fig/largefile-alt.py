#!/usr/bin/env python3

import pandas as pd

import os

_script_dir = os.path.dirname(os.path.realpath(__file__))
os.chdir(_script_dir)

df1 = pd.read_csv("bench.data", sep="\t").set_index("bench")
df2 = pd.read_csv("aws-spectre/bench.data", sep="\t").set_index("bench")

df = {"ssd": df1, "nvme": df2}


def get(disk, system):
    return df[disk].loc["largefile", system + "-ssd"]


print("disk\t" + "Linux\t" + "GoNFS")
print("SSD\t" + f"{get('ssd', 'linux')}\t" + f"{get('ssd', 'gonfs')}")
print("NVMe\t" + f"{get('nvme', 'linux')}\t" + f"{get('nvme', 'gonfs')}")
