Version 4
SymbolType BLOCK
TEXT 32 32 LEFT 4 simple_fft
RECTANGLE Normal 32 32 896 640
LINE Wide 0 80 32 80
PIN 0 80 LEFT 36
PINATTR PinName s_axis_config_tdata[23:0]
PINATTR Polarity IN
LINE Normal 0 112 32 112
PIN 0 112 LEFT 36
PINATTR PinName s_axis_config_tvalid
PINATTR Polarity IN
LINE Normal 0 144 32 144
PIN 0 144 LEFT 36
PINATTR PinName s_axis_config_tready
PINATTR Polarity OUT
LINE Wide 0 208 32 208
PIN 0 208 LEFT 36
PINATTR PinName s_axis_data_tdata[31:0]
PINATTR Polarity IN
LINE Normal 0 240 32 240
PIN 0 240 LEFT 36
PINATTR PinName s_axis_data_tvalid
PINATTR Polarity IN
LINE Normal 0 272 32 272
PIN 0 272 LEFT 36
PINATTR PinName s_axis_data_tlast
PINATTR Polarity IN
LINE Normal 0 304 32 304
PIN 0 304 LEFT 36
PINATTR PinName s_axis_data_tready
PINATTR Polarity OUT
LINE Normal 0 400 32 400
PIN 0 400 LEFT 36
PINATTR PinName aclk
PINATTR Polarity IN
LINE Normal 0 432 32 432
PIN 0 432 LEFT 36
PINATTR PinName aresetn
PINATTR Polarity IN
LINE Wide 928 208 896 208
PIN 928 208 RIGHT 36
PINATTR PinName m_axis_data_tdata[31:0]
PINATTR Polarity OUT
LINE Normal 928 272 896 272
PIN 928 272 RIGHT 36
PINATTR PinName m_axis_data_tvalid
PINATTR Polarity OUT
LINE Normal 928 304 896 304
PIN 928 304 RIGHT 36
PINATTR PinName m_axis_data_tlast
PINATTR Polarity OUT
LINE Normal 928 336 896 336
PIN 928 336 RIGHT 36
PINATTR PinName m_axis_data_tready
PINATTR Polarity IN
LINE Normal 928 400 896 400
PIN 928 400 RIGHT 36
PINATTR PinName event_frame_started
PINATTR Polarity OUT
LINE Normal 928 432 896 432
PIN 928 432 RIGHT 36
PINATTR PinName event_tlast_unexpected
PINATTR Polarity OUT
LINE Normal 928 464 896 464
PIN 928 464 RIGHT 36
PINATTR PinName event_tlast_missing
PINATTR Polarity OUT
LINE Normal 928 528 896 528
PIN 928 528 RIGHT 36
PINATTR PinName event_data_in_channel_halt
PINATTR Polarity OUT
LINE Normal 928 560 896 560
PIN 928 560 RIGHT 36
PINATTR PinName event_status_channel_halt
PINATTR Polarity OUT
LINE Normal 928 592 896 592
PIN 928 592 RIGHT 36
PINATTR PinName event_data_out_channel_halt
PINATTR Polarity OUT

