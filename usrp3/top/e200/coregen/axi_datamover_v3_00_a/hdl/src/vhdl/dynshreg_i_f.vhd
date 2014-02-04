-------------------------------------------------------------------------------
-- $Id: dynshreg_i_f.vhd,v 1.1.4.1 2010/09/14 22:35:46 dougt Exp $
-------------------------------------------------------------------------------
-- dynshreg_i_f - entity / architecture pair
-------------------------------------------------------------------------------
--
-- *************************************************************************
-- **                                                                     **
-- ** DISCLAIMER OF LIABILITY                                             **
-- **                                                                     **
-- ** This text/file contains proprietary, confidential                   **
-- ** information of Xilinx, Inc., is distributed under                   **
-- ** license from Xilinx, Inc., and may be used, copied                  **
-- ** and/or disclosed only pursuant to the terms of a valid              **
-- ** license agreement with Xilinx, Inc. Xilinx hereby                   **
-- ** grants you a license to use this text/file solely for               **
-- ** design, simulation, implementation and creation of                  **
-- ** design files limited to Xilinx devices or technologies.             **
-- ** Use with non-Xilinx devices or technologies is expressly            **
-- ** prohibited and immediately terminates your license unless           **
-- ** covered by a separate agreement.                                    **
-- **                                                                     **
-- ** Xilinx is providing this design, code, or information               **
-- ** "as-is" solely for use in developing programs and                   **
-- ** solutions for Xilinx devices, with no obligation on the             **
-- ** part of Xilinx to provide support. By providing this design,        **
-- ** code, or information as one possible implementation of              **
-- ** this feature, application or standard, Xilinx is making no          **
-- ** representation that this implementation is free from any            **
-- ** claims of infringement. You are responsible for obtaining           **
-- ** any rights you may require for your implementation.                 **
-- ** Xilinx expressly disclaims any warranty whatsoever with             **
-- ** respect to the adequacy of the implementation, including            **
-- ** but not limited to any warranties or representations that this      **
-- ** implementation is free from claims of infringement, implied         **
-- ** warranties of merchantability or fitness for a particular           **
-- ** purpose.                                                            **
-- **                                                                     **
-- ** Xilinx products are not intended for use in life support            **
-- ** appliances, devices, or systems. Use in such applications is        **
-- ** expressly prohibited.                                               **
-- **                                                                     **
-- ** Any modifications that are made to the Source Code are              **
-- ** done at the user’s sole risk and will be unsupported.               **
-- ** The Xilinx Support Hotline does not have access to source           **
-- ** code and therefore cannot answer specific questions related         **
-- ** to source HDL. The Xilinx Hotline support of original source        **
-- ** code IP shall only address issues and questions related             **
-- ** to the standard Netlist version of the core (and thus               **
-- ** indirectly, the original core source).                              **
-- **                                                                     **
-- ** Copyright (c) 2007-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:      dynshreg_i_f.vhd
--
-- Description:   This module implements a dynamic shift register with clock
--                enable. (Think, for example, of the function of the SRL16E.)
--                The width and depth of the shift register are selectable
--                via generics C_WIDTH and C_DEPTH, respectively. The C_FAMILY
--                allows the implementation to be tailored to the target
--                FPGA family. An inferred implementation is used if C_FAMILY
--                is "nofamily" (the default) or if synthesis will not produce
--                an optimal implementation.  Otherwise, a structural
--                implementation will be generated.
--
--                There is no restriction on the values of C_WIDTH and
--                C_DEPTH and, in particular, the C_DEPTH does not have
--                to be a power of two.
--
--                This version allows the client to specify the initial value
--                of the contents of the shift register, as applied
--                during configuration.
--
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--
-------------------------------------------------------------------------------
-- Author:        FLO
--
-- History:
--   FLO   01/03/07   First Version. Derived from dynshreg_f.
--
-- ~~~~~~
--  FLO         12/20/07
-- ^^^^^^
--  -Now using clog2 instead of log2.
-- ~~~~~~
--
--     DET     1/17/2008     v3_00_a
-- ~~~~~~
--     - Changed proc_common library version to v3_00_a
--     - Incorporated new disclaimer header
-- ^^^^^^
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
--      predecessor value by # clks:            "*_p#"

---(
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.UNSIGNED;
use     ieee.numeric_std.TO_INTEGER;
--
library proc_common_v3_00_a;
use     proc_common_v3_00_a.proc_common_pkg.clog2;

--------------------------------------------------------------------------------
-- Explanations of generics and ports regarding aspects that may not be obvious.
--
-- C_DWIDTH
   --------
-- Theoretically, C_DWIDTH may be set to zero and this could be a more
-- natural or preferrable way of excluding a dynamic shift register
-- in a client than using a VHDL Generate statement. However, this usage is not
-- tested, and the user should expect that some VHDL tools will be deficient
-- with respect to handling this properly.
--
-- C_INIT_VALUE
   ---------------
-- C_INIT_VALUE can be used to specify the initial values of the elements
-- in the dynamic shift register, i.e. the values to be present after config-
-- uration. C_INIT_VALUE need not be the same size as the dynamic shift
-- register, i.e. C_DWIDTH*C_DEPTH. When smaller, C_INIT_VALUE
-- is replicated as many times as needed (possibly fractionally the last time)
-- to form a full initial value that is the size of the shift register.
-- So, if C_INIT_VALUE is left at its default value--an array of size one
-- whose value is '0'--the shift register will initialize with all bits at
-- all addresses set to '0'. This will also be the case if C_INIT_VALUE is a
-- null (size zero) array.
-- When determined according to the rules outlined above, the full
-- initial value is a std_logic_vector value from (0 to C_DWIDTH*C_DEPTH-1). It
-- is allocated to the addresses of the dynamic shift register in this
-- manner: The first C_DWIDTH values (i.e. 0 to C_CWIDTH-1) assigned to
-- the corresponding indices at address 0, the second C_DWIDTH values
-- assigned to address 1, and so forth.
-- Please note that the shift register is not resettable after configuration.
--
-- Addr
   ----
-- Addr addresses the elements of the dynamic shift register. Addr=0 causes
-- the most recently shifted-in element to appear at Dout, Addr=1
-- the second most recently shifted in element, etc. If C_DEPTH is not
-- a power of two, then not all of the values of Addr correspond to an
-- element in the shift register. When such an address is applied, the value
-- of Dout is undefined until a valid address is established.
--------------------------------------------------------------------------------
entity dynshreg_i_f is
  generic (
    C_DEPTH  : positive := 32;
    C_DWIDTH : natural := 1;
    C_INIT_VALUE : bit_vector := "0";
    C_FAMILY : string := "nofamily"
  );
  port (
    Clk   : in  std_logic;
    Clken : in  std_logic;
    Addr  : in  std_logic_vector(0 to clog2(C_DEPTH)-1);
    Din   : in  std_logic_vector(0 to C_DWIDTH-1);
    Dout  : out std_logic_vector(0 to C_DWIDTH-1)
  );
end dynshreg_i_f;


library proc_common_v3_00_a;
use     proc_common_v3_00_a.family_support.all;
library unisim;
use     unisim.all; -- Make unisim entities available for default binding.
architecture behavioral of dynshreg_i_f is


  type     bv2sl_type is array(bit) of std_logic;
  constant bv2sl      : bv2sl_type := ('0' => '0', '1' => '1');

  function min(a, b: natural) return natural is
  begin
      if a<b then return a; else return b; end if;
  end min;

  --
  ------------------------------------------------------------------------------
  -- Function used to establish the full initial value. (See the comments for
  -- C_INIT_VALUE, above.)
  ------------------------------------------------------------------------------
  function full_initial_value(w : natural; d : positive; v : bit_vector
                             ) return bit_vector is
    variable r : bit_vector(0 to w*d-1);
    variable i, j : natural;
             -- i - the index where filling of r continues
             -- j - the amount to fill on the cur. iteration of the while loop
  begin
    if w = 0 then null;  -- Handle the case where the shift reg width is zero
    elsif v'length = 0 then r := (others => '0');
    else
      i := 0;
      while i /= r'length loop
          j := min(v'length, r'length-i);
          r(i to i+j-1) := v(0 to j-1);
          i := i+j;
      end loop;
    end if;
    return r;
  end full_initial_value;

  constant FULL_INIT_VAL : bit_vector(0 to C_DWIDTH*C_DEPTH -1)
                         := full_initial_value(C_DWIDTH, C_DEPTH, C_INIT_VALUE);
  --
  constant K_FAMILY : families_type := str2fam(C_FAMILY);
  --
  constant W32 : boolean := supported(K_FAMILY, u_SRLC32E) and
                            (C_DEPTH > 16 or not supported(K_FAMILY, u_SRL16E));
  constant W16 : boolean := supported(K_FAMILY, u_SRLC16E) and not W32;
  -- XST faster if these two constants are declared here
  -- instead of in STRUCTURAL_A_GEN. (I.25)
  --
  function power_of_2(n: positive) return boolean is
      variable i: positive := 1;
  begin
      while n > i loop i := i*2; end loop;
      return n = i;
  end power_of_2;
  --
  constant USE_INFERRED     : boolean :=    (    power_of_2(C_DEPTH)
                                             and (   (W16 and C_DEPTH >= 16)
                                                  or (W32 and C_DEPTH >= 32)
                                                 )
                                            )
                                         or (not W32 and not W16);
  -- As of I.32, XST is not infering optimal dynamic shift registers for
  -- depths not a power of two (by not taking advantage of don't care
  -- at output when address not within the range of the depth)
  -- or a power of two less than the native SRL depth (by building shift
  -- register out of discrete FFs and LUTs instead of SRLs).
  constant USE_STRUCTURAL_A : boolean := not USE_INFERRED;

 ---------------------------------------------------------------------------- 
 -- Unisim components declared locally for maximum avoidance of default
 -- binding and vcomponents version issues.
 ---------------------------------------------------------------------------- 
  component SRLC16E
      generic
      (
          INIT : bit_vector := X"0000"
      );
      port
      (
          Q : out STD_ULOGIC;
          Q15 : out STD_ULOGIC;
          A0 : in STD_ULOGIC;
          A1 : in STD_ULOGIC;
          A2 : in STD_ULOGIC;
          A3 : in STD_ULOGIC;
          CE : in STD_ULOGIC;
          CLK : in STD_ULOGIC;
          D : in STD_ULOGIC
      );
  end component;

  component SRLC32E
      generic
      (
          INIT : bit_vector := X"00000000"
      );
      port
      (
          Q : out STD_ULOGIC;
          Q31 : out STD_ULOGIC;
          A : in STD_LOGIC_VECTOR (4 downto 0);
          CE : in STD_ULOGIC;
          CLK : in STD_ULOGIC;
          D : in STD_ULOGIC
      );
  end component;


begin

  ---(
  STRUCTURAL_A_GEN : if USE_STRUCTURAL_A = true generate

    type  bo2na_type is array(boolean) of natural;
    constant bo2na      :  bo2na_type := (false => 0, true => 1);
    constant BPSRL : natural := bo2na(W16)*16 + bo2na(W32)*32; -- Bits per SRL
        
    constant BTASRL : natural := clog2(BPSRL); -- Bits To Address SRL
    constant NUM_SRLS_DEEP : natural := (C_DEPTH + BPSRL-1)/BPSRL;
  
    constant ADDR_BITS : integer := Addr'length;
  
    signal dynshreg_addr     : std_logic_vector(ADDR_BITS-1 downto 0);
    signal cascade_sigs : std_logic_vector(0 to C_DWIDTH*(NUM_SRLS_DEEP+1) - 1);  
           -- The data signals at the inputs and daisy-chain outputs of SRLs.
           -- The last signal of each cascade is not used.
           --
    signal q_sigs       : std_logic_vector(0 to C_DWIDTH*NUM_SRLS_DEEP - 1);  
           -- The data signals at the addressble outputs of SRLs.

    function srl_init_string(i, j  : natural;
                             w     : natural;
                             d     : positive;
                             bpsrl : positive;
                             v     : bit_vector
                            ) return bit_vector is
        variable base : natural := j*bpsrl*w + i;
        variable r : bit_vector(bpsrl-1 downto 0) := (others => '0');
    begin
        for k in 0 to min(bpsrl, d-j*bpsrl)-1 loop
            r(k) := v(base+k*w);
        end loop;
        return r;
    end srl_init_string;

  ---)(

  begin

    DIN_TO_CASCADE_GEN : for i in 0 to C_DWIDTH-1 generate
        cascade_sigs(i*(NUM_SRLS_DEEP+1)) <= Din(i);
    end generate;
  
    dynshreg_addr(ADDR_BITS-1 downto 0) <= Addr(0 to ADDR_BITS-1);

    BIT_OF_WIDTH_GEN : for i in 0 to C_DWIDTH-1 generate
        CASCADES_GEN : for j in 0 to NUM_SRLS_DEEP-1 generate
            signal srl_addr: std_logic_vector(4 downto 0);
        begin
          -- Here we form the address for the SRL elements. This is just
          -- the corresponding low-order bits of dynshreg_addr but we
          -- also handle the case where we  have to zero-pad to the left
          -- a dynshreg_addr that is smaller than the SRL address port.
          SRL_ADDR_LO_GEN : for i in 0 to min(ADDR_BITS-1,4) generate
              srl_addr(i) <= dynshreg_addr(i);
          end generate;
          SRL_ADDR_HI_GEN : for i in min(ADDR_BITS-1,4)+1 to 4 generate
              srl_addr(i) <= '0';
          end generate;

          W16_GEN : if W16 generate
            SRLC16E_I : component SRLC16E
                generic map (
                    INIT => srl_init_string(i, j,
                                            C_DWIDTH,
                                            C_DEPTH,
                                            BPSRL,
                                            FULL_INIT_VAL)
                )
                port map
                (
                  Q   => q_sigs(j + i*NUM_SRLS_DEEP),
                  Q15 => cascade_sigs(j+1 + i*(NUM_SRLS_DEEP+1)),
                  A0  => srl_addr(0),
                  A1  => srl_addr(1),
                  A2  => srl_addr(2),
                  A3  => srl_addr(3),
                  CE  => Clken,
                  Clk => Clk,
                  D   => cascade_sigs(j + i*(NUM_SRLS_DEEP+1))
                )
            ;
          end generate;

          W32_GEN : if W32 generate
          begin
            SRLC32E_I : component SRLC32E
                generic map (
                    INIT => srl_init_string(i, j,
                                            C_DWIDTH,
                                            C_DEPTH,
                                            BPSRL,
                                            FULL_INIT_VAL)
                )
                port map
                (
                  Q   => q_sigs(j + i*NUM_SRLS_DEEP),
                  Q31 => cascade_sigs(j+1 + i*(NUM_SRLS_DEEP+1)),
                  A   => srl_addr(4 downto 0),
                  CE  => Clken,
                  Clk => Clk,
                  D   => cascade_sigs(j + i*(NUM_SRLS_DEEP+1))
                )
            ;
          end generate;

        end generate CASCADES_GEN;
    end generate BIT_OF_WIDTH_GEN;
    
    
    ----------------------------------------------------------------------------
    -- Generate a MUXFn structure to select the proper SRL
    -- as the output of each shift register.
    ----------------------------------------------------------------------------
    SINGLE_SRL_GEN : if NUM_SRLS_DEEP = 1 generate
        Dout <= q_sigs;
    end generate;
    --
    MULTI_SRL_GEN : if NUM_SRLS_DEEP > 1 generate
      PER_BIT_GEN : for i in 0 to C_DWIDTH-1 generate

      begin
          MUXF_STRUCT_I0 : entity proc_common_v3_00_a.muxf_struct_f
              generic map (
                  C_START_LEVEL  => native_lut_size(fam => K_FAMILY,
                                                    no_lut_return_val => 10000),
                   -- Artificially high value for C_START_LEVEL when no LUT is
                   -- supported will cause muxf_struct_f to default to inferred
                   -- multiplexers.
                  C_NUM_INPUTS   => NUM_SRLS_DEEP,
                  C_FAMILY       => C_FAMILY
              )
              port map (
                        O   => Dout(i),
                        Iv  => q_sigs(i     * (NUM_SRLS_DEEP)  to
                                      (i+1) * (NUM_SRLS_DEEP) - 1),
                        Sel => dynshreg_addr(ADDR_BITS-1 downto BTASRL)
                                                              --Bits To Addr SRL
              )
          ;
      end generate;
    end generate;

  end generate STRUCTURAL_A_GEN;
  ---)


  ---(
  INFERRED_GEN : if USE_INFERRED = true generate
    --
    type dataType is array (0 to C_DEPTH-1) of std_logic_vector(0 to C_DWIDTH-1);
    --
    function fill_data(w: natural; d: positive; v: bit_vector
                      ) return dataType is
        variable r : dataType;
    begin
        for i in 0 to d-1 loop
           for j in 0 to w-1 loop
               r(i)(j) := bv2sl(v(i*w+j)); 
           end loop;
        end loop;
        return r;
    end fill_data;

    signal data: dataType := fill_data(C_DWIDTH, C_DEPTH, FULL_INIT_VAL);
    --
  begin
    process(Clk)
    begin
      if Clk'event and Clk = '1' then
        if Clken = '1' then
          data <= Din & data(0 to C_DEPTH-2);
        end if;
      end if;
    end process;

    Dout <= data(TO_INTEGER(UNSIGNED(Addr)))
                when (TO_INTEGER(UNSIGNED(Addr)) < C_DEPTH)
                else
            (others => '-');
  end generate INFERRED_GEN;
  ---)

end behavioral;
---)
