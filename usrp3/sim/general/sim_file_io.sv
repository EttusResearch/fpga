//
// Copyright 2015 Ettus Research LLC
//

`ifndef WORKING_DIR
  `define WORKING_DIR "."
`endif

`define ABSPATH(name) {`WORKING_DIR, "/", name}

typedef enum {
  READ, WRITE, APPEND
} fopen_mode_t;

typedef enum {
  HEX, DEC, OCT, BIN, FLOAT
} fformat_t;

//TODO: We would ideally use a class but that is not
//      supported by most simulators.
interface data_file_t #(
  parameter FILENAME = "test.hex", 
  parameter FORMAT = HEX, 
  parameter DWIDTH = 64
) (input clk);
  bit     is_open;
  integer handle;

  function open(fopen_mode_t mode = READ);
    if (mode == APPEND)
      handle  = $fopen(`ABSPATH(FILENAME), "a");
    else if (mode == WRITE)
      handle  = $fopen(`ABSPATH(FILENAME), "w");
    else
      handle  = $fopen(`ABSPATH(FILENAME), "r");

    if (handle == 0) begin
      $error("Could not open file: %s", `ABSPATH(FILENAME));
      $finish();
    end
    is_open = 1;
  endfunction

  function close();
    $fclose(handle);
    handle  = 0;
    is_open = 0;
  endfunction

  function logic is_eof();
    return ($feof(handle));
  endfunction

  function logic [DWIDTH-1:0] readline();
    automatic logic [DWIDTH-1:0] word = 64'h0;
    automatic integer status;

    if (FORMAT == HEX)
      status = $fscanf(handle, "%x\n", word);
    else if (FORMAT == DEC)
      status = $fscanf(handle, "%d\n", word);
    else if (FORMAT == OCT)
      status = $fscanf(handle, "%o\n", word);
    else if (FORMAT == BIN)
      status = $fscanf(handle, "%b\n", word);
    else if (FORMAT == DEC)
      status = $fscanf(handle, "%g\n", word);
    else
      $error("Invalid format");

    return word;
  endfunction

  function void writeline(logic [DWIDTH-1:0] word);
    if (FORMAT == HEX)
      $fdisplay(handle, "%x", word);
    else if (FORMAT == DEC)
      $fdisplay(handle, "%d", word);
    else if (FORMAT == OCT)
      $fdisplay(handle, "%o", word);
    else if (FORMAT == BIN)
      $fdisplay(handle, "%b", word);
    else if (FORMAT == DEC)
      $fdisplay(handle, "%g", word);
    else
      $error("Invalid format");
  endfunction

endinterface

