##
## Copyright 2015 Ettus Research LLC
##

## -*- texinfo -*- 
## @deftypefn {Function File} {@var{retval} =} decode_ofdm_symbol (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

function [S_ofdm, S_pilots] = decode_ofdm_symbol (r, H)
debug = 0;
fft_input = r;
fft_out = fft(fft_input);
fft_out = fftshift(fft_out);

#########################################################
################ Aplly channel equalizer ################
#########################################################
fft_out = fft_out ./ transpose(H);
#########################################################

fft_out = fft_out(7:end-5); # remove guard carriers
S_ofdm = [fft_out(1:5) fft_out(7:19) fft_out(21:26) fft_out(28:33) fft_out(35:47) fft_out(49:end)];
S_pilots = [fft_out(6) fft_out(20) fft_out(34) fft_out(48)];

if(debug == 1)
  figure;
  plot(abs(fft_out));
  hold on;
  plot(real(fft_out), 'r');
  plot(imag(fft_out), 'g');
  title('OFDM frame after equalization');
endif
if(debug == 2)
  plot(real(fft_out), imag(fft_out), '.');
  axis([-1 1 -1 1], "manual");
  title('OFDM frame after equalization');
endif

endfunction
