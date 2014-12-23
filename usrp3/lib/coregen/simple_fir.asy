Version 4
SymbolType BLOCK
TEXT 32 32 LEFT 4 simple_fir
RECTANGLE Normal 32 32 1024 608
LINE Normal 0 80 32 80
PIN 0 80 LEFT 36
PINATTR PinName s_axis_data_tvalid
PINATTR Polarity IN
LINE Normal 0 112 32 112
PIN 0 112 LEFT 36
PINATTR PinName s_axis_data_tready
PINATTR Polarity OUT
LINE Normal 0 144 32 144
PIN 0 144 LEFT 36
PINATTR PinName s_axis_data_tlast
PINATTR Polarity IN
LINE Wide 0 208 32 208
PIN 0 208 LEFT 36
PINATTR PinName s_axis_data_tdata[31:0]
PINATTR Polarity IN
LINE Normal 0 240 32 240
PIN 0 240 LEFT 36
PINATTR PinName s_axis_config_tvalid
PINATTR Polarity IN
LINE Normal 0 272 32 272
PIN 0 272 LEFT 36
PINATTR PinName s_axis_config_tready
PINATTR Polarity OUT
LINE Wide 0 336 32 336
PIN 0 336 LEFT 36
PINATTR PinName s_axis_config_tdata[7:0]
PINATTR Polarity IN
LINE Normal 0 368 32 368
PIN 0 368 LEFT 36
PINATTR PinName s_axis_reload_tvalid
PINATTR Polarity IN
LINE Normal 0 400 32 400
PIN 0 400 LEFT 36
PINATTR PinName s_axis_reload_tready
PINATTR Polarity OUT
LINE Normal 0 432 32 432
PIN 0 432 LEFT 36
PINATTR PinName s_axis_reload_tlast
PINATTR Polarity IN
LINE Wide 0 464 32 464
PIN 0 464 LEFT 36
PINATTR PinName s_axis_reload_tdata[31:0]
PINATTR Polarity IN
LINE Normal 0 496 32 496
PIN 0 496 LEFT 36
PINATTR PinName aclk
PINATTR Polarity IN
LINE Normal 0 560 32 560
PIN 0 560 LEFT 36
PINATTR PinName aresetn
PINATTR Polarity IN
LINE Normal 1056 80 1024 80
PIN 1056 80 RIGHT 36
PINATTR PinName m_axis_data_tvalid
PINATTR Polarity OUT
LINE Normal 1056 112 1024 112
PIN 1056 112 RIGHT 36
PINATTR PinName m_axis_data_tready
PINATTR Polarity IN
LINE Normal 1056 144 1024 144
PIN 1056 144 RIGHT 36
PINATTR PinName m_axis_data_tlast
PINATTR Polarity OUT
LINE Wide 1056 176 1024 176
PIN 1056 176 RIGHT 36
PINATTR PinName m_axis_data_tuser[0:0]
PINATTR Polarity OUT
LINE Wide 1056 208 1024 208
PIN 1056 208 RIGHT 36
PINATTR PinName m_axis_data_tdata[95:0]
PINATTR Polarity OUT
LINE Normal 1056 400 1024 400
PIN 1056 400 RIGHT 36
PINATTR PinName event_s_reload_tlast_missing
PINATTR Polarity OUT
LINE Normal 1056 432 1024 432
PIN 1056 432 RIGHT 36
PINATTR PinName event_s_reload_tlast_unexpected
PINATTR Polarity OUT

