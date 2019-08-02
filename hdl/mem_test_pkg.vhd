------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_common_array_pkg.all;	
	
------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package mem_test_pkg is

	-- Register General
	constant USER_SLV_NUM_REG      : integer := 32; -- only powers of 2 are allowed
	subtype rd_t 	is	std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
	subtype rdata_t	is	t_aslv32(0 to USER_SLV_NUM_REG-1);
	subtype wr_t	is	std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
	subtype wdata_t	is 	t_aslv32(0 to USER_SLV_NUM_REG-1);
	
	-- Register Definition
	constant REG_START				: integer	:= 0;				-- 0x00
	constant C_START_START			: natural	:= 0;
	
	constant REG_STOP				: integer	:= 1;				-- 0x04
	constant C_STOP_STOP			: natural	:= 0;	
	
	constant REG_MODE				: integer	:= 3;				-- 0x0C
	subtype RNG_MODE				is natural range 2 downto 0;
	constant C_MODE_SINGLE			: integer := 0;
	constant C_MODE_CONTINUOUS		: integer := 1;
	constant C_MODE_WRITEONLY		: integer := 2;
	constant C_MODE_READONLY		: integer := 3;
	
	constant REG_SIZE_LO			: integer	:= 4;				-- 0x10
	constant REG_SIZE_HI			: integer	:= 5;				-- 0x14
	
	constant REG_ADDR_LO			: integer	:= 6;				-- 0x18
	constant REG_ADDR_HI			: integer	:= 7;				-- 0x1C
	
	constant REG_PATTERN_SEL		: integer	:= 8;				-- 0x20
	subtype RNG_PATTERN_SEL			is natural range 2 downto 0;	
	constant C_PATTERN_SEL_COUNT	: integer := 0;
	constant C_PATTERN_SEL_WALK1	: integer := 1;
	constant C_PATTERN_SEL_OWNADD	: integer := 2;
	constant C_PATTERN_SEL_PRBN		: integer := 3;
	
	constant REG_STATUS				: integer	:= 9;				-- 0x24
	subtype RNG_STATUS				is natural range 2 downto 0;
	constant C_STATUS_IDLE			: integer := 0;
	constant C_STATUS_WRITING		: integer := 1;
	constant C_STATUS_READING		: integer := 2;
	constant C_STATUS_AXIERR		: integer := 3;		
	constant C_STATUS_INTERR		: integer := 6;
	constant C_STATUS_UNKNOWN		: integer := 7;
	
	constant REG_ERRORS				: integer := 10;				-- 0x28
	
	constant REG_FERR_ADDR_LO		: integer := 11;				-- 0x2C
	constant REG_FERR_ADDR_HI		: integer := 12;				-- 0x30
	constant REG_ITER				: integer := 13;				-- 0x34

	
	
	
end package;