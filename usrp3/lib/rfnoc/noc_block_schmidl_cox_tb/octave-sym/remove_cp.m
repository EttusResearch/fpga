##
## Copyright 2015 Ettus Research LLC
##

## -*- texinfo -*- 
## @deftypefn {Function File} {@var{retval} =} remove_cp (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

function [r] = remove_cp (r)
  #GI is T_fft/4 = 16 samples 
  r = r(17:end);
endfunction
