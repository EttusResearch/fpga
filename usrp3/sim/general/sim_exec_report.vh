//
// Copyright 2015 Ettus Research LLC
//

// Initializes state for a test bench.
// This macro *must be* called within the testbench module but 
// outside the primary initial block
// Its sets up boilerplate code for:
// - Logging to console
// - Test execution tracking
// - Gathering test results
// - Bounding execution time based on the SIM_RUNTIME_NS vdef
//
// Usage: `TEST_BENCH_INIT(test_name,min_tc_run_count,ns_per_tick)
// where
//  - tb_name:          Name of the testbench. (Only used during reporting)
//  - min_tc_run_count: Number of test cases in testbench. (Used to detect stalls and inf-loops)
//  - ns_per_tick:      The time_unit_base from the timescale declaration
//
`define TEST_BENCH_INIT(tb_name, min_tc_run_count, ns_per_tick) \
  reg tc_running = 0; \
  reg tc_failed = 0; \
  integer tc_run_count = 0; \
  integer tc_pass_count = 0; \
  \
  initial begin \
    $display("========================================================"); \
    $display("TESTBENCH STARTED: %s", tb_name); \
    $display("========================================================"); \
    tc_running = 0; \
    tc_failed = 0; \
    tc_run_count = 0; \
    tc_pass_count = 0; \
    #((1.0*`SIM_RUNTIME_NS)/ns_per_tick); \
    $display("========================================================"); \
    $display("TESTBENCH FINISHED: %s", tb_name); \
    $display(" - Time elapsed:   %0d ticks", (1.0*`SIM_RUNTIME_NS)/ns_per_tick); \
    $display(" - Tests Expected: %0d", min_tc_run_count); \
    $display(" - Tests Run:      %0d", tc_run_count); \
    $display(" - Tests Passed:   %0d", tc_pass_count); \
    $display("Result: %s", ((tc_run_count>=min_tc_run_count)&&(tc_run_count==tc_pass_count)?"PASSED   ":"FAILED!!!")); \
    $display("========================================================"); \
  end

// Indicates the start of a test case
// This macro *must be* called inside the primary initial block
//
// Usage: `TEST_CASE_START(test_name)
// where
//  - test_name:        The name of the test.
//
`define TEST_CASE_START(test_name) \
  tc_running = 1; \
  tc_failed = 0; \
  tc_run_count = tc_run_count + 1; \
  $display("[TEST CASE %3d] Starting %s...", tc_run_count, test_name);

// Indicates the end of a test case
// This macro *must be* called inside the primary initial block
// The pass/fail status of test case is determined based on the
// the user specified outcome and the number of fatal or error
// ASSERTs triggered in the test case.
//
// Usage: `TEST_CASE_DONE(test_result)
// where
//  - test_result:  User specified outcome
//
`define TEST_CASE_DONE(result) \
  tc_running = 0; \
  $display("[TEST CASE %3d] Done... %s", tc_run_count, ((result&~tc_failed)?"Passed":"FAILED")); \
  if (result&~tc_failed) tc_pass_count = tc_pass_count + 1;

// Wrapper around a an assert.
// ASSERT_FATAL throws an error assertion and halts the simulator
// if cond is not satisfied
//
// Usage: `ASSERT_FATAL(cond,msg)
// where
//  - cond: Condition for the assert
//  - msg:  Message for the assert
//
`define ASSERT_FATAL(cond, msg) \
  assert(cond) else begin \
    tc_failed = 1; \
    $error(msg); \
    $stop(); \
  end

// Wrapper around a an assert.
// ASSERT_ERROR throws an error assertion and fails the test case
// if cond is not satisfied. The simulator will *not* halt
//
// Usage: `ASSERT_ERROR(cond,msg)
// where
//  - cond: Condition for the assert
//  - msg:  Message for the assert
//
`define ASSERT_ERROR(cond, msg) \
  assert(cond) else begin \
    tc_failed = 1; \
    $error(msg); \
  end

// Wrapper around a an assert.
// ASSERT_WARNING throws an warning assertion but does not fail the
// test case if cond is not satisfied. The simulator will *not* halt
//
// Usage: `ASSERT_WARNING(cond,msg)
// where
//  - cond: Condition for the assert
//  - msg:  Message for the assert
//
`define ASSERT_WARN(cond, msg) \
  assert(cond) else $warning(msg);
