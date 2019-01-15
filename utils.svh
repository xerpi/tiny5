`ifndef __UTILS__
`define __UTILS__

`define FF_RESET(CLK, RESET, DATA_I, DATA_O, DEFAULT) \
        always_ff @ (posedge CLK) \
                if (RESET) DATA_O <= DEFAULT; \
                else       DATA_O <= DATA_I;

`define FF_RESET_EN(CLK, RESET, DATA_I, DATA_O, EN, DEFAULT) \
        always_ff @ (posedge CLK) \
                if (RESET) DATA_O <= DEFAULT; \
                else       DATA_O <= EN ? DATA_I : DATA_O;

`endif
