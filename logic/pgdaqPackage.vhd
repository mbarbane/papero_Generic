--!@file pgdaqPackage.vhd
--!@brief Constants, components declarations, and functions
--!@author Matteo D'Antonio, matteo.dantonio@studenti.unipg.it
--!@author Mattia Barbanera, mattia.barbanera@infn.it

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.basic_package.all;

--!@copydoc pgdaqPackage.vhd
package pgdaqPackage is
  -- Constants -----------------------------------------------------------------
  constant cREGISTERS : natural        := 32;	--!Total number of registers
  constant cREG_ADDR  : natural        := ceil_log2(cREGISTERS); --!Register address width
  constant cREG_WIDTH : natural        := 32; --!Register width

  --Housekeeping reader
  constant cF2H_HK_SOP : std_logic_vector(31 downto 0) := x"55AADEAD"; --!Start of Packet for the FPGA-2-HPS FSM
  constant cF2H_HK_HDR : std_logic_vector(31 downto 0) := x"4EADE500"; --!Fixed Header for the FPGA-2-HPS FSM
  constant cF2H_HK_EOP : std_logic_vector(31 downto 0) := x"600DF00D"; --!End of Packet for the FPGA-2-HPS FSM
  constant cF2H_HK_PERIOD : natural := 50000000; --!Period for internal counter to read HKs; max: 2^32 (85 s)


  -- Types ---------------------------------------------------------------------
  --!Register array; all registers are r/w for HPS and FPGA
  type tRegisterArray is array (0 to cREGISTERS-1) of
    std_logic_vector(cREG_WIDTH-1 downto 0);
  constant cREG_NULL  : tRegisterArray := (others => (others => '0')); --!Null vector for register array

  --!Control interface for a generic block: input signals
  type tControlIn is record
    en    : std_logic;                  --!Enable
    start : std_logic;                  --!Start
  end record tControlIn;

  --!Control interface for a generic block: output signals
  type tControlOut is record
    busy  : std_logic;                  --!Busy flag
    error : std_logic;                  --!Error flag
    reset : std_logic;                  --!Resetting flag
    compl : std_logic;                  --!completion of task
  end record tControlOut;

  --!Registers interface
  type tRegIntf is record
    reg  : std_logic_vector(cREG_WIDTH-1 downto 0);  --!Content to be written
    addr : std_logic_vector(cREG_ADDR-1 downto 0);   --!Address to be updated
    we   : std_logic;                                --!Write enable
  end record tRegIntf;

  -- Components ----------------------------------------------------------------
  --!Detects rising and falling edges of the input
  component edge_detector_md is
    generic(
      channels : integer   := 1;
      R_vs_F   : std_logic := '0'
      );
    port(
      iCLK  : in  std_logic;
      iRST  : in  std_logic;
      iD    : in  std_logic_vector(channels - 1 downto 0);
      oEDGE : out std_logic_vector(channels - 1 downto 0)
      );
  end component;

  --!Generates a single clock pulse when a button is pressed
  component Key_Pulse_Gen is
    port(
      KPG_CLK_in   : in  std_logic;
      KPG_DATA_in  : in  std_logic_vector(1 downto 0);
      KPG_DATA_out : out std_logic_vector(1 downto 0)
      );
  end component;

  --! Allunga di un ciclo di clock lo stato "alto" del segnale di "Wait_Request".
	component HighHold is
	generic(
			  channels : integer := 1;
			  BAS_vs_BSS : std_logic := '0'
			 );
	port(
		  CLK_in				: in std_logic;
		  DATA_in			: in std_logic_vector(channels - 1 downto 0);
		  DELAY_1_out		: out std_logic_vector(channels - 1 downto 0);
		  DELAY_2_out 		: out std_logic_vector(channels - 1 downto 0);
		  DELAY_3_out		: out std_logic_vector(channels - 1 downto 0);
		  DELAY_4_out		: out std_logic_vector(channels - 1 downto 0)
		 );
	end component;

	--! Temporizza l'invio di impulsi sul read_enable della FIFO.
	component WR_Timer is
	port(
		  WRT_CLK_in					: in std_logic;
		  WRT_RST_in					: in std_logic;
		  WRT_START_in					: in std_logic;
		  WRT_STANDBY_in				: in std_logic;
		  WRT_STOP_COUNT_VALUE_in		: in std_logic_vector(31 downto 0);
		  WRT_out						: out std_logic;
		  WRT_DECLINE_out				: out std_logic;
		  WRT_END_COUNT_out				: out std_logic
		 );
end component;

  component hkReader is
  generic(
    pFIFO_WIDTH : natural := 32
    );
  port (
    iCLK        : in  std_logic;        --!Main clock
    iRST        : in  std_logic;        --!Main reset
    iCNT        : in  tControlIn;       --!Control input signals
    oCNT        : out tControlOut;      --!Control output flags
    iINT_START  : in  std_logic;        --!Enable for the internal start
    --Register array
    iFW_VER     : in  std_logic_vector(31 downto 0);  --!Firmware version from HoG
    iREG_ARRAY  : in  tRegisterArray;   --!Register array input
    --Output FIFO interface
    oFIFO_DATA  : out std_logic_vector(pFIFO_WIDTH-1 downto 0);  --!Fifo Data in
    oFIFO_WR    : out std_logic;        --!Fifo write-request in
    iFIFO_AFULL : in  std_logic         --!Fifo almost-full flag
    );
  end component;

end pgdaqPackage;
