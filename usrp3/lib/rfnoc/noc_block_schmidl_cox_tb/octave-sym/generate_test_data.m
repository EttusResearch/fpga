##
## Copyright 2015 Ettus Research LLC
##
## Generate test data for use with Schmidl Cox testbench.
## Also generates several plots of interesting parts of the Schmidl Cox algorithm.
##
clc;
close all;
clear all;

# User variables
timing_error    = 0;     # Offset error
freq_offset_ppm = 40;    # TCXO frequency offset in parts per million, typical value would be +/-20
gain            = 10;    # dB
snr             = 40;    # dB
packet_length   = 12;    # Number of symbols per packet (excluding preamble)
num_packets     = 10;    # Number of packets to generate

# Simulation variables (generally should not need to touch these)
tx_freq         = 2.4e9;
sample_rate     = 200e6;
cp_length       = 16;
symbol_length   = 64;
window_length   = 64;
cordic_bitwidth = 24;
cordic_bitwidth_adj = cordic_bitwidth-3; # Lose 3 bits due to Xilinx's CORDIC scaled radians format
plateau_index   = 125;

##### Generate test data
# From 802.11 specification
short_ts_f = sqrt(13/6)*[0,0,0,0,0,0,0,0,1+j,0,0,0,-1-j,0,0,0,1+j,0,0,0,-1-j,0,0,0,-1-j,0,0,0,1+j,0,0,0,0,0,0,0,-1-j,0,0,0,-1-j,0,0,0,1+j,0,0,0,1+j,0,0,0,1+j,0,0,0,1+j,0,0,0,0,0,0,0];
short_ts_f = ifftshift(short_ts_f);
short_ts_t = ifft(short_ts_f);
#12/52 carrier used + DC
long_ts_f = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 0 1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1];
ifft_data = [long_ts_f(27:end) 0 0 0 0 0 0 0 0 0 0 0 long_ts_f(1:26)];
long_ts_t = ifft(ifft_data);

short_preamble = zeros(1,160);
for i=1:10
  short_preamble(16*(i-1)+1:16*i) = short_ts_t(1:(64/4));
endfor
long_preamble = [long_ts_t(end-31:end) long_ts_t long_ts_t];

for i=1:4096
  ramp(i) = i/(2^15);
end

# First packet
test_data = [zeros(1,128) short_preamble long_preamble];
preamble_offset = length(test_data);
for i=1:packet_length
  test_data = [test_data long_ts_t(end-15:end) long_ts_t];
end
# Additional packets
for k=1:num_packets-1
  test_data = [test_data short_preamble long_preamble];
  for i=1:packet_length
    test_data = [test_data long_ts_t(end-15:end) long_ts_t];
  end
end

# Add frequency offset
offset = ((freq_offset_ppm/1e6)*tx_freq)/sample_rate;
expected_phase_word = ((2^cordic_bitwidth_adj)/window_length)*angle(exp(j*(window_length)*2*pi*offset))/pi;
printf("Expected phase word: %d (%f)\n",round(expected_phase_word),expected_phase_word);
test_data = add_freq_offset(test_data, offset);

# Add noise
test_data = awgn(test_data, snr);

# Add gain
test_data = test_data .* 10^(gain/20);

# Software based Schmidl Cox implementation for reference
[D, corr, pow, phase, trigger] = schmidl_cox(test_data, window_length);
printf("Actual phase word: %d (%f)\n",round(phase(plateau_index)*2^cordic_bitwidth_adj/window_length),phase(plateau_index)*2^cordic_bitwidth_adj/window_length);

##### Plotting
# Long preamble
figure;
subplot(1,2,1)
hold on;
title('Long preamble')
plot(real(fftshift(fft(test_data(preamble_offset+cp_length+timing_error+1:preamble_offset+cp_length+symbol_length+timing_error)))));
plot(imag(fftshift(fft(test_data(preamble_offset+cp_length+timing_error+1:preamble_offset+cp_length+symbol_length+timing_error)))),'r');

# Frequency corrected long preamble
long_preamble = add_freq_offset(test_data(preamble_offset+cp_length+timing_error+1:preamble_offset+cp_length+symbol_length+timing_error),-phase(125)/(2*window_length)); # Correct for 2*pi & window len
subplot(1,2,2)
hold on;
title('Long preamble frequency corrected')
plot(real(fftshift(fft(long_preamble))));
plot(imag(fftshift(fft(long_preamble))),'r');

# Plot long term effect of CORDIC phase bit width on frequency accuracy
figure;
hold on;
long_preamble_pre_fft = add_freq_offset(test_data(preamble_offset+timing_error+1:preamble_offset+timing_error+packet_length*(window_length+cp_length)),-round(phase(125)*2^cordic_bitwidth_adj/window_length)/(2*2^cordic_bitwidth_adj));
long_preamble = [];
for i = 1:packet_length
  long_preamble = [long_preamble fft(fftshift(long_preamble_pre_fft((i-1)*80+16+1:i*80)))];
endfor
title('Packet data frequency corrected')
plot(real(long_preamble));
plot(imag(long_preamble),'r');

figure;
subplot(3,2,1:2);
hold on;
grid on;
plot(real(test_data));
plot(imag(test_data), 'r');
title('Time domain');
subplot(3,2,3);
plot(D(10:300),'k')
title('D')
subplot(3,2,4);
plot(abs(corr(1:300)));
title('Mag');
subplot(3,2,5)
plot(pow(1:300), 'r');
title('Power')
subplot(3,2,6)
plot(phase(1:300), 'b');
title('Angle')

##### Write to disk
# Convert to sc16
test_data_sc16 = zeros(1,2*length(test_data));
test_data_sc16(1:2:end-1) = int16((2^15).*real(test_data));
test_data_sc16(2:2:end) = int16((2^15).*imag(test_data));

# Complex float
test_data_cplx_float = zeros(1,2*length(test_data));
test_data_cplx_float(1:2:end-1) = real(test_data);
test_data_cplx_float(2:2:end) = imag(test_data); 

fileId = fopen('../test-sc16.bin', 'w');
fwrite(fileId, test_data_sc16, 'int16');
fclose(fileId);
fileId = fopen('test-float.bin', 'w');
fwrite(fileId, test_data_cplx_float, 'float');
fclose(fileId);
