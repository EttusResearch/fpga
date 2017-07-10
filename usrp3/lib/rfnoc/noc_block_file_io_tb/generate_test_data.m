close all;
clear all;

long_preamble = [0 0 0 0 0 0 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 0 1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1 0 0 0 0 0];

rand_data_re = floor(rand(1, 128) * 2) * 2 - 1;
rand_data_im = (floor(rand(1, 128) * 2) * 2 - 1) * i;
rand_data = rand_data_re + rand_data_im;

test_data = [long_preamble rand_data];
test_data = test_data * 2^14-1;

subplot(2, 1, 1);
plot(test_data);

interleave = [];
index = 1;
for i=1:(length(test_data))
  interleave(index) = real(test_data(i));
  interleave(index+1) = imag(test_data(i)); 
  index = index + 2; 
endfor

fileId = fopen('comp-int16.bin', 'w');
fwrite(fileId, interleave, 'int16');
fclose(fileId);

%---

test_data = test_data * exp(j*2*pi*0.53);

subplot(2, 1, 2);
plot(test_data, 'o')

interleave = [];
index = 1;
for i=1:(length(test_data))
  interleave(index) = real(test_data(i));
  interleave(index+1) = imag(test_data(i)); 
  index = index + 2; 
endfor

fileId = fopen('test-int16.bin', 'w');
fwrite(fileId, interleave, 'int16');
fclose(fileId);