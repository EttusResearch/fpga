close all;
clear all;
clc;

r = read_complex_binary('samples.dat');
#r = r(9.404e6:9.414e6);
r = r(7.315e6:7.325e6);
figure;
plot(abs(r));

#############################################################
#### Run
#############################################################
if(1)
#### returns frequency corrected input starting at the beginning edge of the plateau.
[D, f, corr, power, frame_start, d_f, sig_out, sig_out_corr] = schmidl_corr(r, 32);

figure;
hold on;
grid on;
plot(D,'r');
plot(f,'g');
plot(abs(sig_out_corr), 'b');
title('Schmidl Cox out');

long_preamble_f = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 0 1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1];
long_preamble_start = 0;

##############################################################
#### Fine timing by finding correlation with long preamble 
##############################################################
if(0)
ifft_data = [long_preamble_f(27:end) 0 0 0 0 0 0 0 0 0 0 0 long_preamble_f(1:26)];
long_preamble_t = ifft(ifft_data);
correlation = conv(conj(sig_out_corr), fliplr(long_preamble_t));
[max, long_preamble_start] = max(abs(correlation));
long_preamble_start
endif
###############################################################

###############################################################
#### 160 Samples SP + 32 Samples LP CP.
#### Step a few samples back to make sure to be in CP LP1 and not in the crossover between LP1 and LP2.
#### The channel equalizer in conjuntion with the pilots will handle the introduced frequency offset (in the F domain) for us.
#### The channel equalizer can remove the f offset introduced by the timing offset completely. However,
#### due to residual f offset in t domain, which also results amongst others in f offset in F domain, the initial phase of every OFDM symbol is 
#### linearly increasing or decreasing. That results in constant rotation of the constellation between OFDM symbols. Therefore, we need to use the 
#### pilot symbols to derotate. That is why timing sync does not affect the speed of rotation observed for the pilot constellations.
###############################################################
sig_out_corr = sig_out_corr(160+32-5:end);
###############################################################

###############################################################
###################### Run channel equalizer ##################
###############################################################
fft_input = sig_out_corr(1:64);
#fft_input = sig_out(1:64);
fft_out = fft(fft_input);
fft_out = fftshift(fft_out);
fft_out = circshift(fft_out, [0 0]);
data_out = fft_out(7:end-5);

H_ls = inv(diag(circshift([0 0 0 0 0 0 long_preamble_f 0 0 0 0 0], [0 0])))*transpose([0 0 0 0 0 0 data_out 0 0 0 0 0]);
H_ls
figure;
hold on;
plot(abs(H_ls));
plot(arg(H_ls), 'r');
title('Channel response H(f)');

figure;
plot(abs(data_out));
hold on;
plot(real(data_out), 'r');
plot(imag(data_out), 'g');
plot(arg(data_out), 'b');
title('OFDM frame 1 before equalization');

figure;
plot(real(data_out), imag(data_out), '.');
axis([-1 1 -1 1], "manual");
title('OFDM frame 1 before equalization');

data_out = data_out ./ transpose(H_ls)(7:end-5);

#figure;
#plot(abs(data_out));
#hold on;
#plot(real(data_out), 'r');
#plot(imag(data_out), 'g');
#title('OFDM frame after equalization');

#figure;
#plot(real(data_out), imag(data_out), '.');
#axis([-1 1 -1 1], "manual");
#title('OFDM frame after equalization');
###########################################################

###########################################################
################ Decode, baby! ############################
###########################################################
#### Pilots can be found in bins -21, -7, 7, 21
#### For the SYMBOL symbol their values are 1, 1, 1, -1
###########################################################

fig = figure;
curr_ofdm_sym_start_index = 129;
phi = 0;
phi_log = [];
pilot_zero = [];
polarity_seq = [1 1 1 1 -1 -1 -1 1 -1 -1 -1 -1 1 1 -1 1 -1 -1 1 1 -1 1 1 -1 1 1 1 1 1 1 -1 1 1 1 -1 1 1 -1 -1 1 1 1 -1 1 -1 -1 -1 1 -1 1 -1 -1 1 -1 -1 1 1 1 1 1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 -1 -1 -1 1 1 -1 -1 -1 -1 1 -1 -1 1 -1 1 1 1 1 -1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 -1 1 1 -1 1 -1 1 1 1 -1 -1 1 -1 -1 -1 1 1 1 -1 -1 -1 -1 -1 -1 -1];

for ii = 1:10
  curr_ofdm_sym = sig_out_corr(curr_ofdm_sym_start_index:curr_ofdm_sym_start_index+63+16);
  curr_ofdm_sym = remove_cp(curr_ofdm_sym);
  curr_ofdm_wo_eq = curr_ofdm_sym;
  [curr_ofdm_sym curr_ofdm_pilots] = decode_ofdm_symbol(curr_ofdm_sym, H_ls);
  pilot_zero = [pilot_zero curr_ofdm_pilots(1)];
  curr_ofdm_sym = derotate_ofdm_symbol(curr_ofdm_sym, curr_ofdm_pilots, polarity_seq(ii));
  curr_ofdm_sym_start_index = curr_ofdm_sym_start_index+16+64;

  ############## PLOT ##################
  plot(real(curr_ofdm_pilots), imag(curr_ofdm_pilots), 'marker', 'x', 'color', 'r');
  hold on;
  plot(real(curr_ofdm_sym), imag(curr_ofdm_sym), '.', 'color', 'b');
  axis([-2 2 -2 2], "manual");
  title('OFDM Symbols After Equalization and BB Derotation');
  legend("Pilot Symbols", "Derotated Data Symbols");
  grid on;
  drawnow;
  sleep(0.5);
  #######################################
endfor
#figure;
#plot(phi_log./(2*pi));
#title('Phi/2pi');
#mean(phi_log./(2*pi))
#figure;
#plot(arg(pilot_zero)./(2*pi));
#title('Pilot Zero Phase Data');
endif