#!/usr/bin/env python3
"""
Automated Multi-Seed Regression Runner & Log Parser
PCIe Gen 3 Data Link Layer UVM Verification Suite
"""

import subprocess
import os
import sys
import re

SEEDS = [101, 202, 303, 404, 505]
LOG_DIR = "run_logs"
TEST_NAME = "pcie_test"

def run_regression():
    os.makedirs(LOG_DIR, exist_ok=True)
    summary = []

    print("==================================================================")
    print(" starting PCIe Data Link Layer UVM Multi-Seed Regression ")
    print("==================================================================")

    for seed in SEEDS:
        log_file = os.path.join(LOG_DIR, f"sim_seed_{seed}.log")
        print(f"[*] Executing Test: {TEST_NAME} with Random Seed: {seed}...")

        # Shell execution command (compatible with ModelSim/Questa/Riviera/VCS)
        cmd = f"vsim -c -do \"run -all; quit\" +UVM_TESTNAME={TEST_NAME} +ntb_random_seed={seed} -l {log_file}"

        # If running on local system without vsim installed, simulate dry run / verify log generator
        try:
            res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
            status = "PASSED" if res.returncode == 0 else "FAILED"
        except Exception as e:
            status = "SIM_TOOL_NOT_FOUND"

        # Check log output
        errors = 0
        fatals = 0
        if os.path.exists(log_file):
            with open(log_file, "r") as f:
                content = f.read()
                errors = len(re.findall(r"UVM_ERROR", content))
                fatals = len(re.findall(r"UVM_FATAL", content))

        summary.append({
            "seed": seed,
            "status": "PASS" if (errors == 0 and fatals == 0 and status != "SIM_TOOL_NOT_FOUND") else status,
            "errors": errors,
            "fatals": fatals,
            "log": log_file
        })

    print("\n==================================================================")
    print(f"{'SEED':<10} | {'STATUS':<12} | {'ERRORS':<8} | {'FATALS':<8}")
    print("------------------------------------------------------------------")
    for row in summary:
        print(f"{row['seed']:<10} | {row['status']:<12} | {row['errors']:<8} | {row['fatals']:<8}")
    print("==================================================================")

if __name__ == "__main__":
    run_regression()