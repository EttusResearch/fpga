##
## Copyright 2015 Ettus Research LLC
##

## -*- texinfo -*- 
## @deftypefn {Function File} {@var{retval} =} llse (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

function [retval] = llse (s, preamble)

diff = preamble./complex(s);
#figure;
#plot(arg(diff));
args = [];
adder = 0;
prev_arg = arg(diff(1));

for ii = 1:length(diff)

  if((arg(diff(ii)) < 0) & ( prev_arg > 0 ))
    adder = adder + 2*pi;
  endif
  if((arg(diff(ii)) > 0) & (prev_arg < 0))
    adder = adder - 2*pi;
  endif
  args = [args arg(diff(ii))+adder];
  prev_arg = arg(diff(ii));
  
endfor
retval = polyfit([1:1:52],args,1);
#hold on;
#stem(args);

endfunction
