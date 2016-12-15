#!/usr/bin/env python2
#
# Copyright 2016 Ettus Research LLC
#

import argparse
import os
import subprocess
import logging
import re
import json

_LIB_DIR = os.path.join("lib")
_RFNOC_DIR = os.path.join("lib", "rfnoc")
_SIM_DIR = os.path.join("lib", "sim")
_BASE_DIR = os.path.dirname(os.path.realpath(__file__))

_SEARCH_BASE = [_RFNOC_DIR, _SIM_DIR]
_LOG = logging.getLogger(os.path.basename(__file__))
_LOG.setLevel(logging.INFO)
_STDOUT = logging.StreamHandler()
_LOG.addHandler(_STDOUT)
_FORMATTER = logging.Formatter('[%(name)s] - %(levelname)s - %(message)s')
_STDOUT.setFormatter(_FORMATTER)


def match_file(expr, path):
    matches = []
    with open(path) as f:
        for line in f:
            match = expr.match(line)
            if match:
                matches.append(match)
    return matches


def create_index(paths):
    verilog_file = re.compile(".*\.v$")
    verilog_module = re.compile("module (?P<mod_name>[\w]+) *$", re.IGNORECASE)
    vhdl_file = re.compile(".*\.vhd$")
    vhdl_module = re.compile("entity (?P<mod_name>[\w]+) is *$", re.IGNORECASE)

    modules = {}
    for path in paths:
        for root, dirs, files in os.walk(os.path.join(_BASE_DIR, path)):
            if "build-ip" in dirs:
                dirs.pop(dirs.index("build-ip"))
            if "sim" in dirs:
                dirs.pop(dirs.index("sim"))
            for f in files:
                if verilog_file.match(f):
                    matches = match_file(verilog_module, os.path.join(root, f))
                elif vhdl_file.match(f):
                    matches = match_file(vhdl_module, os.path.join(root, f))
                else:
                    continue
                for match in matches:
                    if match.group("mod_name") in modules:
                        _LOG.error("{} is already in modules".format(
                            match.group("mod_name")))
                        _LOG.error("Old Path: {}".format(modules[match.group(
                            "mod_name")]))
                        _LOG.error("New Path: {}".format(
                            os.path.join(root, f)))
                    else:
                        modules.update({
                            match.group("mod_name"): os.path.join(root, f)
                        })
    with open("modules.json", "w") as f:
        json.dump(modules, f, sort_keys=True, indent=4, separators=(',', ': '))


def call_xsim(path):
    os.chdir(os.path.join(_BASE_DIR, path))
    d = os.environ
    d["REPO_BASE_PATH"] = _BASE_DIR
    d["DISPLAY_NAME"] = "USRP-XSIM"
    d["VIVADO_VER"] = "2015.4"
    d["PRODUCT_ID_MAP"] = "kintex7/xc7k325t/ffg900/-2"
    setup_env = os.path.join(_BASE_DIR, "tools", "scripts", "setupenv_base.sh")
    result = subprocess.Popen(
        ". {setup}; make xsim".format(setup=setup_env), env=d,
        shell=True).wait()
    return result


def find_xsims():
    # Find testbenches in lib/sim (dirs with Makefile)
    sims = {}
    for basedir in _SEARCH_BASE:
        for root, dirs, files in os.walk(os.path.join(_BASE_DIR, basedir)):
            if "Makefile" in files:
                sims.update({os.path.basename(root): root})
    return sims


def run_xsim(args):
    sims = find_xsims()
    result_all = 0
    if not isinstance(args.target, list):
        args.target = [args.target]
    if "cleanall" in args.target:
        d = os.environ
        d["REPO_BASE_PATH"] = _BASE_DIR
        for name, path in sims.iteritems():
            _LOG.info("Cleaning {}".format(name))
            os.chdir(os.path.join(_BASE_DIR, path))
            cleanup = subprocess.Popen(
                "make cleanall", env=d, shell=True).wait()
    elif "all" in args.target:
        for name, path in sims.iteritems():
            _LOG.info("Running {} xsim".format(name))
            result = call_xsim(path)
            if result:
                result_all = result
    else:
        for target in args.target:
            _LOG.info("Running {} xsim".format(target))
            result = call_xsim(sims[target])
            if result:
                result_all = result
    return result_all


def parse_args():
    test_benches = find_xsims()
    parser = argparse.ArgumentParser()
    subparser = parser.add_subparsers(dest="command", metavar="")
    xsim_parser = subparser.add_parser(
        "xsim", help="Run available testbenches")
    xsim_parser.add_argument(
        "target",
        nargs="+",
        choices=test_benches.keys() + ["all", "cleanall"],
        help="Space separated simulation target(s) or all. Available targets: "
        + ", ".join(test_benches.keys() + ["all", "cleanall"]),
        metavar="")
    index_parser = subparser.add_parser(
        "index", help="Index available HDL modules")
    index_parser.add_argument(
        "create",
        help="Create a modules.json of available HDL modules in lib/")
    return parser.parse_args()


def main():
    args = parse_args()
    result = 0
    if args.command == "xsim":
        result = run_xsim(args)
    elif args.command == "index":
        create_index([_LIB_DIR])

    return result


if __name__ == "__main__":
    exit(not main())
