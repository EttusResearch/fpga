#!/usr/bin/python3
#
# Copyright 2018 Ettus Research, a National Instruments Company
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#

import argparse
import os
import sys
import subprocess
import logging
import re
import io
import time
import datetime
from queue import Queue
from threading import Thread

#-------------------------------------------------------
# Utilities
#-------------------------------------------------------

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
BASE_DIR = os.path.split(os.path.split(SCRIPT_DIR)[0])[0]

_LOG = logging.getLogger(os.path.basename(__file__))
_LOG.setLevel(logging.INFO)
_STDOUT = logging.StreamHandler()
_LOG.addHandler(_STDOUT)
_FORMATTER = logging.Formatter('[%(name)s] - %(levelname)s - %(message)s')
_STDOUT.setFormatter(_FORMATTER)

RETCODE_SUCCESS     = 0
RETCODE_PARSE_ERR   = -1
RETCODE_EXEC_ERR    = -2
RETCODE_UNKNOWN_ERR = -3

def retcode_to_str(code):
    """ Convert internal status code to string
    """
    if code == RETCODE_SUCCESS:
        return 'Success'
    elif code > RETCODE_SUCCESS:
        return 'AppError({code}})'.format(code=code)
    else:
        msgs = {
            RETCODE_PARSE_ERR:'ParseError', 
            RETCODE_EXEC_ERR:'ExecError', 
            RETCODE_UNKNOWN_ERR:'UnknownError'}
        return msgs[code]

def log_with_header(what, minlen = 0, ch = '#'):
    """ Print with a header around the text
    """
    padlen = max(int((minlen - len(what))/2), 1) 
    toprint = (' '*padlen) + what + (' '*padlen)
    _LOG.info(ch * len(toprint))
    _LOG.info(toprint)
    _LOG.info(ch * len(toprint))

#-------------------------------------------------------
# Simulation Functions
#-------------------------------------------------------

def find_sims(base_dir):
    """ Find all testbenches in the specific base_dir
        Testbenches are defined as directories with a
        Makefile that includes viv_sim_preamble.mak
    """
    sims = {}
    for root, _, files in os.walk(base_dir):
        if 'Makefile' in files:
            with open(os.path.join(root, 'Makefile'), 'r') as mfile:
                for l in mfile.readlines():
                    if re.match('.*include.*viv_sim_preamble.mak.*', l) is not None:
                        sims.update({os.path.relpath(root, base_dir): root})
                        break
    return sims

def run_sim(path, simulator, basedir, setupenv):
    """ Run the simulation at the specified path
        The simulator can be specified as the target
        A environment script can be run optionally
    """
    try:
        os.chdir(os.path.join(basedir, path))
        if setupenv is None:
            setupenv = ''
            # Check if environment was setup
            if 'VIVADO_PATH' not in os.environ:
                raise RuntimeError('Simulation environment was uninitialized') 
        else:
            setupenv = '. ' + os.path.realpath(setupenv) + ';'
        simout = subprocess.check_output(
            '{setupenv} make {simulator} 2>&1'.format(setupenv=setupenv, simulator=simulator), shell=True)
        tb_match_arr = ([
            b'.*TESTBENCH FINISHED: (.+)\n',
            b' - Time elapsed:   (.+) ns.*\n',
            b' - Tests Expected: (.+)\n',
            b' - Tests Run:      (.+)\n',
            b' - Tests Passed:   (.+)\n',
            b'Result: (PASSED|FAILED).*',
        ])
        m = re.match(b''.join(tb_match_arr), simout, re.DOTALL)
        if m is not None:
            return {'retcode': 0, 'passed':(m.group(6) == b'PASSED'), 
                    'module':m.group(1), 'ns_elapsed':int(m.group(2)), 
                    'tc_expected':int(m.group(3)), 'tc_run':int(m.group(4)), 'tc_passed':int(m.group(5)),
                    'stdout':simout}
        else:
            return {'retcode': RETCODE_PARSE_ERR, 'passed':False, 'stdout':simout}
    except subprocess.CalledProcessError as e:
        return {'retcode': abs(e.returncode), 'passed':False, 'stdout':e.output}
    except Exception as e:
        _LOG.error('Target ' + path + ' failed to run:\n' + str(e))
        return {'retcode': RETCODE_EXEC_ERR, 'passed':False, 'stdout':bytes(str(e), 'utf-8')}
    except:
        _LOG.error('Target ' + path + ' failed to run')
        return {'retcode': RETCODE_UNKNOWN_ERR, 'passed':False, 'stdout':bytes('Unknown Exception', 'utf-8')}

def run_sim_queue(run_queue, out_queue, simulator, basedir, setupenv):
    """ Thread worker for a simulation runner
        Pull a job from the run queue, run the sim, then place
        output in out_queue
    """
    while not run_queue.empty():
        (name, path) = run_queue.get()
        result = {}
        try:
            _LOG.info('Running simulation: %s', name)
            out_queue.put((name, run_sim(path, simulator, basedir, setupenv)))
            _LOG.info('DONE: %s', name)
        except KeyboardInterrupt:
            _LOG.warning('Target ' + name + ' received SIGINT. Aborting...')
            out_queue.put((name, {'retcode': RETCODE_EXEC_ERR, 'passed':False, 'stdout':bytes('Aborted by user', 'utf-8')}))
        except Exception as e:
            _LOG.error('Target ' + name + ' failed to run:\n' + str(e))
            out_queue.put((name, {'retcode': RETCODE_UNKNOWN_ERR, 'passed':False, 'stdout':bytes(str(e), 'utf-8')}))
        finally:
            run_queue.task_done()

#-------------------------------------------------------
# Script Actions
#-------------------------------------------------------

def do_list(args):
    """ List all simulations that can be run
    """
    sims = find_sims(args.basedir)
    result_all = 0
    if not isinstance(args.target, list):
        args.target = [args.target]
    for target in args.target:
        for name in sorted(sims):
            if re.match(target, name) is not None:
                print(name)
    return 0

def do_run(args):
    """ Build a simulation queue based on the specified
        args and process it
    """
    run_queue = Queue(maxsize=0)
    out_queue = Queue(maxsize=0)
    _LOG.info('Queueing the following targets to simulate:')
    sims = find_sims(args.basedir)
    if not isinstance(args.target, list):
        args.target = [args.target]
    for target in args.target:
        for name in sorted(sims):
            if re.match(target, name) is not None:
                run_queue.put((name, sims[name]))
                _LOG.info('* ' + name)
    # Spawn tasks to run builds
    num_sims = run_queue.qsize()
    num_jobs = min(num_sims, int(args.threads))
    _LOG.info('Starting ' + str(num_jobs) + ' job(s) to process queue...')
    results = {}
    for i in range(num_jobs):
        worker = Thread(target=run_sim_queue, args=(run_queue, out_queue, args.simulator, args.basedir, args.setupenv))
        worker.setDaemon(False)
        worker.start()
    # Wait for build queue to become empty
    start = datetime.datetime.now()
    try:
        while out_queue.qsize() < num_sims:
            tdiff = str(datetime.datetime.now() - start).split('.', 2)[0]
            print("\r>>> [%s] (%d/%d simulations completed) <<<" % (tdiff, out_queue.qsize(), num_sims), end='\r', flush=True)
            time.sleep(1.0)
        sys.stdout.write("\n")
    except (KeyboardInterrupt):
        _LOG.info('Received SIGINT. Aborting...')
        raise SystemExit(1)

    results = {}
    result_all = 0
    while not out_queue.empty():
        (name, result) = out_queue.get()
        results[name] = result
        log_with_header(name)
        sys.stdout.buffer.write(result['stdout'])
        if not result['passed']:
            result_all += 1

    log_with_header('RESULTS', 30)
    for name in results:
        r = results[name]
        if 'module' in r:
            _LOG.info('* %s : %s (Expected=%d, Run=%d, Passed=%d)',
                ('PASS' if r['passed'] else 'FAIL'), name, r['tc_expected'], r['tc_run'], r['tc_passed'])
        else:
            _LOG.info('* %s : %s (Status=%s)', ('PASS' if r['passed'] else 'FAIL'), name, retcode_to_str(r['retcode']))
    return result_all


def do_cleanup(args):
    """ Run make cleanall for all simulations
    """
    setupenv = args.setupenv
    if setupenv is None:
        setupenv = ''
        # Check if environment was setup
        if 'VIVADO_PATH' not in os.environ:
            raise RuntimeError('Simulation environment was uninitialized') 
    else:
        setupenv = '. ' + os.path.realpath(setupenv) + ';'
    sims = find_sims(args.basedir)
    if not isinstance(args.target, list):
        args.target = [args.target]
    for target in args.target:
        for name in sorted(sims):
            if re.match(target, name) is not None:
                _LOG.info('Cleaning up %s', name)
                os.chdir(os.path.join(args.basedir, sims[name]))
                subprocess.Popen('{setupenv} make cleanall'.format(setupenv=setupenv), shell=True).wait()
    return 0

# Parse command line options
def get_options():
    parser = argparse.ArgumentParser(description='Batch testbench execution script')
    parser.add_argument('--basedir', default=BASE_DIR, help='Base directory for the usrp3 codebase')
    parser.add_argument('--simulator', choices=['xsim', 'vsim'], default='xsim', help='Simulator name')
    parser.add_argument('--setupenv', default=None, help='Optional environment setup script to run for each TB')
    parser.add_argument('--threads', default=4, help='Number of parallel simulations to run')
    parser.add_argument('action', choices=['run', 'cleanup', 'list'], default='list', help='What to do?')
    parser.add_argument('target', nargs='*', default='.*', help='Space separated simulation target regexes')
    return parser.parse_args()

def main():
    args = get_options()
    actions = {'list': do_list, 'run': do_run, 'cleanup': do_cleanup}
    return actions[args.action](args)

if __name__ == '__main__':
    exit(main())
