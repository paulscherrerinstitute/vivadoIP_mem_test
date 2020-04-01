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
	use work.mem_test_pkg.all;
	use work.psi_common_math_pkg.all;
	
------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
-- $$ testcases=simple_tf,max_transact,axi_hs,split,internals,highlat$$
-- $$ processes=user_cmd,user_data,user_resp,axi $$
-- $$ tbpkg=work.psi_tb_txt_util,work.psi_tb_compare_pkg,work.psi_tb_activity_pkg $$
entity mem_test is
	generic (
		AxiAddrWidth_g				: natural range 12 to 64	:= 32;						-- $$ constant=32 $$
		AxiDataWidth_g				: natural range 16 to 1024	:= 32						-- $$ constant=16 $$
	);
	port  (
		-- Control Signals
		Clk				: in 	std_logic;													-- $$ type=clk; freq=100e6 $$
		Rst_n			: in 	std_logic;													-- $$ type=rst; clk=Clk; lowactive=true $$
		
		-- Register bank interface
		Reg_Rd			: in	rd_t;
		Reg_RData		: out	rdata_t;
		Reg_Wr			: in	wr_t;
		Reg_WData		: in	wdata_t;
		
		-- AXI Master Interface
		CmdWr_Addr		: out 	std_logic_vector(AxiAddrWidth_g-1 downto 0);
		CmdWr_Size		: out 	std_logic_vector(AxiAddrWidth_g-1 downto 0);  
		CmdWr_LowLat	: out 	std_logic;	
		CmdWr_Vld		: out 	std_logic;	
		CmdWr_Rdy		: in 	std_logic;			
		CmdRd_Addr		: out 	std_logic_vector(AxiAddrWidth_g-1 downto 0);	
		CmdRd_Size		: out 	std_logic_vector(AxiAddrWidth_g-1 downto 0); 
		CmdRd_LowLat	: out 	std_logic;				
		CmdRd_Vld		: out 	std_logic;				
		CmdRd_Rdy		: in 	std_logic;							
		WrDat_Data		: out 	std_logic_vector(AxiDataWidth_g-1 downto 0);
		WrDat_Be		: out 	std_logic_vector(AxiDataWidth_g/8-1 downto 0);
		WrDat_Vld		: out 	std_logic;												
		WrDat_Rdy		: in 	std_logic;												
		RdDat_Data		: in 	std_logic_vector(AxiDataWidth_g-1 downto 0);		
		RdDat_Vld		: in 	std_logic;												
		RdDat_Rdy		: out 	std_logic;												
		Wr_Done			: in 	std_logic;												
		Wr_Error		: in 	std_logic;												
		Rd_Done			: in 	std_logic;												
		Rd_Error		: in 	std_logic				
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------
architecture rtl of mem_test is 
	------------------------------------------------------------------------------
	-- Types
	------------------------------------------------------------------------------	
	type Fsm_t is (Idle_s, WrCmd_s, Write_s, RdCmd_s, Read_s, AxiError_s, IntError_s);
	
	------------------------------------------------------------------------------
	-- Functions
	------------------------------------------------------------------------------
	function FsmToInt(	fsm : in Fsm_t) return integer is
	begin
		case fsm is
			when Idle_s  	=> return C_STATUS_IDLE;
			when Write_s |
				 WrCmd_s 	=> return C_STATUS_WRITING;
			when Read_s |
				 RdCmd_s	=> return C_STATUS_READING;
			when AxiError_s	=> return C_STATUS_AXIERR;
			when IntError_s	=> return C_STATUS_INTERR;
			when others		=> return C_STATUS_UNKNOWN;
		end case;
	end function;
	
	------------------------------------------------------------------------------
	-- Two Process Record
	------------------------------------------------------------------------------		
	type two_process_r is record	
		Fsm 			: Fsm_t;
		Errors			: unsigned(31 downto 0);
		FirstErrAddr	: unsigned(AxiAddrWidth_g-1 downto 0);
		Pattern			: std_logic_vector(AxiDataWidth_g-1 downto 0);
		LastPattern	: std_logic_vector(AxiDataWidth_g-1 downto 0);
		RdDat_Data	: std_logic_vector(AxiDataWidth_g-1 downto 0);
		CheckPattern : std_logic;
		PatternCnt		: unsigned(AxiAddrWidth_g-1 downto 0);
		CmdWr_Addr		: unsigned(AxiAddrWidth_g-1 downto 0);
		CmdWr_Vld		: std_logic;
		CmdWr_Size		: unsigned(AxiAddrWidth_g-1 downto 0);
		WrDat_Vld		: std_logic;
		CmdRd_Addr		: unsigned(AxiAddrWidth_g-1 downto 0);
		CmdRd_Vld		: std_logic;
		CmdRd_Size		: unsigned(AxiAddrWidth_g-1 downto 0);
		RdDat_Rdy		: std_logic;
		ContRunning		: std_logic;
		FirstErrFound	: std_logic;
		ContIter		: unsigned(31 downto 0);
	end record;
	signal r, r_next : two_process_r;
	
	------------------------------------------------------------------------------
	-- Other Signals
	------------------------------------------------------------------------------
	signal Rst 		: std_logic;
begin
	------------------------------------------------------------------------------
	-- Constant Assignments
	------------------------------------------------------------------------------	
	Rst <= not Rst_n;

	------------------------------------------------------------------------------
	-- Combinatorial Process
	------------------------------------------------------------------------------	
	p_comb : process(	r, Reg_Rd, Reg_Wr, Reg_WData, Wr_Error, Rd_Error,
						CmdWr_Rdy, WrDat_Rdy, CmdRd_Rdy, RdDat_Vld, RdDat_Data)
		variable v 					: two_process_r;
		variable RegStart_v			: std_logic;
		variable RegStop_v			: std_logic;
		variable RegReset_v			: std_logic;
		variable RegSize_v			: unsigned(63 downto 0);
		variable RegAddr_v			: unsigned(63 downto 0);
		variable RegMode_v			: unsigned(RNG_MODE);
		variable RegPatternSel_v	: unsigned(RNG_PATTERN_SEL);
		variable FirstErrAddr64_v	: unsigned(63 downto 0);
		variable InitPattern_v		: boolean;
		variable UpdatePattern_v	: boolean;
		variable AddrBeats_v		: unsigned(AxiAddrWidth_g-1-log2(AxiDataWidth_g/8) downto 0);
	begin
		-- *** Keep two process variables stable ***
		v := r;
		
		-- *** Registers ***
		-- START
		RegStart_v 	:= Reg_WData(REG_START)(C_START_START) and Reg_Wr(REG_START);
		
		-- STOP
		RegStop_v 	:= Reg_WData(REG_STOP)(C_STOP_STOP) and Reg_Wr(REG_STOP);
		
		-- SIZE
		RegSize_v 	:= unsigned(Reg_WData(REG_SIZE_HI)) & unsigned(Reg_WData(REG_SIZE_LO));
		Reg_RData(REG_SIZE_LO) <= std_logic_vector(RegSize_v(31 downto 0));
		Reg_RData(REG_SIZE_HI) <= std_logic_vector(RegSize_v(63 downto 32));
		
		-- ADDR
		RegAddr_v 	:= unsigned(Reg_WData(REG_ADDR_HI)) & unsigned(Reg_WData(REG_ADDR_LO));
		Reg_RData(REG_ADDR_LO) <= std_logic_vector(RegAddr_v(31 downto 0));
		Reg_RData(REG_ADDR_HI) <= std_logic_vector(RegAddr_v(63 downto 32));		
		
		-- MODE
		RegMode_v	:= unsigned(Reg_WData(REG_MODE)(RNG_MODE));
		Reg_RData(REG_MODE) <= (others => '0');
		Reg_RData(REG_MODE)(RNG_MODE) <= std_logic_vector(RegMode_v);
		
		-- PATTERN SEL
		RegPatternSel_v	:= unsigned(Reg_WData(REG_PATTERN_SEL)(RNG_PATTERN_SEL));
		Reg_RData(REG_PATTERN_SEL) <= (others => '0');
		Reg_RData(REG_PATTERN_SEL)(RNG_PATTERN_SEL) <= std_logic_vector(RegPatternSel_v);		
		
		-- STATUS
		Reg_RData(REG_STATUS) <= (others => '0');
		Reg_RData(REG_STATUS)(RNG_STATUS) <= std_logic_vector(to_unsigned(FsmToInt(r.Fsm), RNG_STATUS'high+1));
		
		-- ERRORS
		Reg_RData(REG_ERRORS) <= std_logic_vector(r.Errors);
		
		-- FIRST ERROR ADDR
		FirstErrAddr64_v := resize(r.FirstErrAddr, 64);
		Reg_RData(REG_FERR_ADDR_LO) <= std_logic_vector(FirstErrAddr64_v(31 downto 0));
		Reg_RData(REG_FERR_ADDR_HI) <= std_logic_vector(FirstErrAddr64_v(63 downto 32));
		
		-- ITERATIONS
		Reg_RData(REG_ITER)	<= std_logic_vector(r.ContIter);
		
		-- *** Detect continuous running ***
		if RegStart_v = '1' then
			if RegMode_v = C_MODE_CONTINUOUS then
				v.ContRunning := '1';
			else
				v.ContRunning := '0';
			end if;
		end if;
		if RegStop_v = '1' then
			v.ContRunning := '0';
		end if;

		-- *** Check Pattern ***
		v.LastPattern := r.Pattern;
		v.CheckPattern := '0';
		v.RdDat_Data := RdDat_Data;
		if (r.CheckPattern = '1') then
					if r.RdDat_Data /= r.LastPattern then
						v.Errors := r.Errors + 1;
						v.FirstErrFound := '1';
						if r.FirstErrFound = '0' then
							AddrBeats_v := resize(r.PatternCnt, AddrBeats_v'length) + RegAddr_v(AxiAddrWidth_g-1 downto log2(AxiDataWidth_g/8)) - 1;
							v.FirstErrAddr	:= shift_left(to_unsigned(0, log2(AxiDataWidth_g/8)) & AddrBeats_v, log2(AxiDataWidth_g/8));
						end if;
					end if;	
    end if;
		
		-- *** Main Fsm ***
		v.CmdWr_Vld := '0';
		v.WrDat_Vld := '0';
		v.CmdRd_Vld := '0';
		v.RdDat_Rdy	:= '0';
		InitPattern_v := false;
		UpdatePattern_v := false;
		case r.Fsm is
			
			-- Idle
			when Idle_s =>
				-- Start run and clear statistics
				if RegStart_v = '1' then
					if RegMode_v = C_MODE_READONLY then
						v.Fsm			:= RdCmd_s;
					else
						v.Fsm			:= WrCmd_s;
					end if;
					v.FirstErrAddr 	:= (others => '0');
					v.Errors		:= (others => '0');
					v.FirstErrFound := '0';
					v.ContIter		:= (others => '0');
				end if;
				
			-- Write command
			when WrCmd_s =>
				v.CmdWr_Addr 	:= RegAddr_v(v.CmdWr_Addr'range);
				v.CmdWr_Addr(log2(AxiDataWidth_g/8)-1 downto 0)	:= (others => '0');	-- Do not write unused bits
				v.CmdWr_Size	:= shift_right(RegSize_v(v.CmdRd_Size'left downto 0), log2(AxiDataWidth_g/8));
				v.CmdWr_Vld		:= '1';
				v.PatternCnt	:= (others => '0');
				InitPattern_v	:= true;
				if (r.CmdWr_Vld = '1') and (CmdWr_Rdy = '1') then
					v.Fsm 			:= Write_s;
					v.CmdWr_Vld		:= '0';
				end if;			
			
			-- Write Date
			when Write_s =>
				v.WrDat_Vld	:= '1';
				if (r.WrDat_Vld = '1' ) and (WrDat_Rdy = '1') then
					-- Last word sent
					if r.PatternCnt = r.CmdWr_Size-1 then
						if RegMode_v = C_MODE_WRITEONLY then
							v.Fsm		:= Idle_s;
						else
							v.Fsm		:= RdCmd_s;
						end if;
						v.WrDat_Vld	:= '0';					
					-- Otherwise
					else
						v.PatternCnt	:= r.PatternCnt+1;
						UpdatePattern_v := true;
					end if;
				end if;
					
			-- Read command
			when RdCmd_s =>
				v.CmdRd_Addr 	:= RegAddr_v(v.CmdRd_Addr'range);
				v.CmdRd_Addr(log2(AxiDataWidth_g/8)-1 downto 0)	:= (others => '0');	-- Do not write unused bits
				v.CmdRd_Size	:= shift_right(RegSize_v(v.CmdRd_Size'left downto 0), log2(AxiDataWidth_g/8));
				v.CmdRd_Vld		:= '1';
				v.PatternCnt	:= (others => '0');
				InitPattern_v	:= true;
				if (r.CmdRd_Vld = '1') and (CmdRd_Rdy = '1') then
					v.Fsm 			:= Read_s;
					v.CmdRd_Vld		:= '0';
				end if;			

			-- Read Data
			when Read_s =>
				v.RdDat_Rdy	:= '1';
				if (r.RdDat_Rdy = '1') and (RdDat_Vld = '1') then
					-- Last word read
					if r.PatternCnt = r.CmdRd_Size-1 then
						v.ContIter	:= r.ContIter+1;
						if r.ContRunning = '1' then	
							v.Fsm 		:= WrCmd_s;
						else
							v.Fsm := Idle_s;
						end if;
						v.RdDat_Rdy	:= '0';					
					-- otherwise
					else
						UpdatePattern_v := true;
					end if;
					v.PatternCnt	:= r.PatternCnt+1;

					-- check pattern one clock delayed while FSM continues:
					v.CheckPattern := '1';
				end if;


			-- AXI ERROR
			when AxiError_s =>
				-- Non recoverable!
				null;
				
			-- Internal ERROR
			when IntError_s =>
				-- Non recoverable!
				null;
					
		end case;
		
		-- *** Shared Code ***
		-- Initialize Pattern
		if InitPattern_v then
			case to_integer(RegPatternSel_v) is
				when C_PATTERN_SEL_COUNT =>	
					v.Pattern		:= (others => '0');
				when C_PATTERN_SEL_WALK1 => 
					v.Pattern 		:= (others => '0');
					v.Pattern(0)	:= '1';
				when C_PATTERN_SEL_OWNADD =>
					v.Pattern		:= std_logic_vector(resize(RegAddr_v, v.Pattern'length));
				when C_PATTERN_SEL_PRBN =>
					v.Pattern 				:= (others => '0');
					v.Pattern(15 downto 0)	:= X"6D3F";
				when others =>
					v.Fsm := IntError_s;
			end case;
		end if;
		
		-- Update Pattern
		if UpdatePattern_v then
			case to_integer(RegPatternSel_v) is
				when C_PATTERN_SEL_COUNT =>	
					v.Pattern		:= std_logic_vector(unsigned(r.Pattern) + 1);
				when C_PATTERN_SEL_WALK1 => 
					v.Pattern(0)	:= r.Pattern(r.Pattern'high);
					v.Pattern(v.Pattern'high downto 1) := r.Pattern(r.Pattern'high-1 downto 0);
				when C_PATTERN_SEL_OWNADD =>
					v.Pattern		:= std_logic_vector(unsigned(r.Pattern) + AxiDataWidth_g/8);
				when C_PATTERN_SEL_PRBN =>
					v.Pattern(0)	:= r.Pattern(15) xor r.Pattern(13) xor r.Pattern(12) xor r.Pattern(10);
					v.Pattern(v.Pattern'high downto 1) := r.Pattern(r.Pattern'high-1 downto 0);
				when others =>
					v.Fsm := IntError_s;
			end case;
		end if;
			
			
			
		-- *** Error States cannot be left!
		if r.Fsm = IntError_s then	
			v.Fsm	:= IntError_s;
		end if;
		if r.Fsm = AxiError_s then
			v.Fsm 	:= AxiError_s;
		end if;
		if (Wr_Error = '1') or (Rd_Error = '1') then
			v.Fsm 	:= AxiError_s;
		end if;	
		
		-- *** Update Signal ***
		r_next <= v;
	end process;
	
	CmdWr_Addr 		<= std_logic_vector(r.CmdWr_Addr);
	CmdWr_Vld		<= r.CmdWr_Vld;
	CmdWr_Size		<= std_logic_vector(r.CmdWr_Size);	
	WrDat_Data		<= std_logic_vector(r.Pattern);
	WrDat_Be		<= (others => '1');
	WrDat_Vld		<= r.WrDat_Vld;
	CmdRd_Addr 		<= std_logic_vector(r.CmdRd_Addr);
	CmdRd_Vld		<= r.CmdRd_Vld;
	CmdRd_Size		<= std_logic_vector(r.CmdRd_Size);	
	RdDat_Rdy		<= r.RdDat_Rdy;
	CmdWr_LowLat	<= '0';
	CmdRd_LowLat	<= '0';

	------------------------------------------------------------------------------
	-- Registered Process
	------------------------------------------------------------------------------
	p_reg : process(clk)
	begin
		if rising_edge(Clk) then
			r <= r_next;
			if Rst = '1' then
				r.Fsm			<= Idle_s;
				r.CmdWr_Vld		<= '0';
				r.WrDat_Vld		<= '0';
				r.CmdRd_Vld		<= '0';
				r.RdDat_Rdy		<= '0';
				r.ContRunning	<= '0';
				r.CheckPattern	<= '0';
			end if;
		end if;
	end process;	
end architecture;

