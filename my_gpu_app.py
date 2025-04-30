#!/usr/bin/env python3
import os, subprocess, ctypes, re

# Example of how to extract useful information from the gpu and cpu to inject into the logs

def get_gpu_name():
    gpu_env = os.environ.get("CUDA_VISIBLE_DEVICES", "").split(',')[0] or "0"
    try:
        return subprocess.check_output(
            ["nvidia-smi","--query-gpu=name","--format=csv,noheader","-i",gpu_env],
            encoding="utf-8"
        ).strip()
    except:
        return "<nvidia-smi error>"

def get_cpu_model():
    # read the first "model name" from /proc/cpuinfo
    with open("/proc/cpuinfo") as f:
        for line in f:
            if line.startswith("model name"):
                return line.split(":",1)[1].strip()
    return "<unknown>"

def get_slurm_features():
    # ask Slurm which features that node has
    node = os.environ.get("SLURM_JOB_NODELIST")
    if not node:
        return None
    out = subprocess.check_output(["scontrol","show","node", node], encoding="utf-8")
    m = re.search(r"Features=(\S+)", out)
    return m.group(1) if m else None

if __name__ == "__main__":
    print("GPU →", get_gpu_name())
    print("CPU →", get_cpu_model())
    feats = get_slurm_features()
    if feats:
        print("Slurm Features →", featsg

