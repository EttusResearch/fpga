##
## Copyright 2015 Ettus Research LLC
##

function [D, corr, pow, phase, trigger] = schmidl_cox(samples,window_len)

  N       = length(samples)-2*window_len;
  D       = zeros(1,N);
  corr    = zeros(1,N);
  pow     = zeros(1,N);
  phase   = zeros(1,N);
  trigger = zeros(1,N);

  for i = 1:400
    corr(i+1) = corr(i) + conj(samples(i+window_len))*samples(i+2*window_len) - conj(samples(i))*samples(i+window_len);
    pow(i+1) = pow(i) + abs(samples(i+2*window_len))^2 - abs(samples(i+window_len))^2;
    phase(i+1) = angle(corr(i+1))/pi; # Scaled radians
    if (pow(i) == 0)
      D(i+1) = 0;
    else
      D(i+1) = abs(corr(i))^2/pow(i)^2;
    endif
  endfor

endfunction