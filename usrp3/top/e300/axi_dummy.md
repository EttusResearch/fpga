# AXI Dummy

## Theory of operation

The AXI dummy was put in place to deal with cases where for whatever reason,
one needs to be able to rely on certain registers to 'be there', without
actually doing anything (i.e. without locking up your system).

The 'DEC_ERR' parameter will define whether the slave just silently eats,
whatever transaction is thrown at it, or whether it will report a slave
address decode error.

## Interfaces

### AXI4lite Slave Port

#### Register MAP

##### Any (Offset any)

Writing anything, will do either:
- Nothing (DEC_ERR = 1'b0), readback 0xdeadba5e (dead base)
- Report a slave address decode error (DEC_ERR = 1'b1)

Reading anything, will do either:
- Read 0xdeadba5e (dead base)
- Report a slave address decode error (DEC_ERR = 1'b1)
