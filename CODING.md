# UHD FPGA Coding Standards

## Preamble

To quote R. W. Emerson: "A foolish consistency is the hobgoblin of little minds,
adored by little statesmen and philosophers and divines". Ignoring the little
statesmen for a minute, these coding standards are here to make our life
*easier*, not simply add additional rules. They are meant as additional guidance
for developers, and are not meant to be interpreted as law.

So, ultimately, it is up to the developer to decide how much these guidelines
should be heeded when writing code, and up to reviewers how much they are
relevant to new submissions.
That said, a consistent codebase is easier to maintain, read, understand, and
extend. Choosing personal preferences over these coding guidelines is not a
helpful move for the team and future maintainability of the UHD FPGA codebase.

## General Coding Guidelines

* Code layout: We use 3 spaces for indentation levels, and never tabs.
* Never submit code with trailing whitespace.
* Code is read more often than it's written. Code readability is thus something
  worth optimizing for.
* Comment your code. Especially if your code is tricky or makes unique assumptions.

## Verilog Style Guidelines

### General Syntax

* Always use `begin`and `end` statements for more complex code blocks even if the enclosing code is only
one line.
* Indent begin/end as follows:
```
if (foo) begin
    // Do something
end else if (bar) begin
    // Do something else
end else begin
    // Do nothing
end
```
* Instantiate and declare modules as follows:
```
dummy_module #(
    .PARAM1(0), .PARAM2(1)
) inst (
    .clk(clk), .rst(rst)
)
```

### Assignments

* Sequential blocks **must** only have non-blocking assignments (`<=`)
* Combinational blocks should only have blocking assignments (`=`)
* Don't mix blocking and non-blocking assignments

### Modules

* Each module should be defined in a separate file
* Use Verilog 2001 ANSI-C style port declarations
```
(
   ...
   output reg foo,
   input      bar
);
```
* Declare inputs and outputs one per line. It makes searching and commenting easier.
* Group signals logically instead of by direction. If a single AXI-Stream bus has multiple inputs and
outputs, keep them together.
* Instantiate all ports for a module even if they are tied off or unconnected. Don't let the compiler
insert values for any signals automatically.
```
dummy_module inst (
   .clk(clk), .rst(1'b0), .status(/* unused */)
);
```
* Don't instantiate modules using positional arguments. Use the dot form illustrated above.
* Every module requires a header giving a synopsis of its function below the
  copyright header.

### Clocking and Resets

* Name clocks as `clk`. If there are multiple clocks then use a prefix like `bus_clk` and `radio_clk`.
* If a module has signals or input/outputs whose clock domain is not obvious, use a clock suffix
to be explicit about the domain, for example `axi_tdata_bclk`, `axi_tdata_rclk`.
* Try not to encode the frequency of the clock in the name unless the particular clock can
*never* take on any other frequency.
* Name resets as `rst`. If there are multiple clocks then use a prefix like `bus_rst` and `radio_rst`.
* If a reset is asynchronous, call it `arst`.
* Try to avoid asynchronous resets as much as possible.
* Don't active low resets unless it is used to drive IO.


### Parameters, defines and constants

* Parametrize modules wherever possible, especially if they are designed for reuse. Bus widths, addresses,
buffer sizes, etc are good candidates for parametrizations.
* Propagate parameters as far up the hierarchy as possible as long as it makes sense.
* Place `` `define`` statements in Verilog header file (.vh) and include them in modules.
* Avoid placing `` `define`` statements in modules
* For local parameters, use `localparam` instead on hardcoding things like widths, etc.

## Design Best Practices

TBD
