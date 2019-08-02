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
	
library std;
	use std.textio.all;

library work;
	use work.psi_tb_txt_util.all;
	use work.psi_tb_axi_pkg.all;
	use work.psi_tb_compare_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.mem_test_pkg.all;

entity top_tb is
end entity top_tb;

architecture sim of top_tb is

	-------------------------------------------------------------------------
	-- AXI Definition
	-------------------------------------------------------------------------
	constant ID_WIDTH 		: integer 	:= 1;
	constant ADDR_WIDTH 	: integer	:= 8;
	constant USER_WIDTH		: integer	:= 1;
	constant DATA_WIDTH		: integer	:= 32;
	constant BYTE_WIDTH		: integer	:= DATA_WIDTH/8;
	
	subtype ID_RANGE is natural range ID_WIDTH-1 downto 0;
	subtype ADDR_RANGE is natural range ADDR_WIDTH-1 downto 0;
	subtype USER_RANGE is natural range USER_WIDTH-1 downto 0;
	subtype DATA_RANGE is natural range DATA_WIDTH-1 downto 0;
	subtype BYTE_RANGE is natural range BYTE_WIDTH-1 downto 0;
	
	signal s_axi_ms : axi_ms_r (	arid(ID_RANGE), awid(ID_RANGE),
									araddr(ADDR_RANGE), awaddr(ADDR_RANGE),
									aruser(USER_RANGE), awuser(USER_RANGE), wuser(USER_RANGE),
									wdata(DATA_RANGE),
									wstrb(BYTE_RANGE));
	
	signal s_axi_sm : axi_sm_r (	rid(ID_RANGE), bid(ID_RANGE),
									ruser(USER_RANGE), buser(USER_RANGE),
									rdata(DATA_RANGE));
	
	constant M_DATA_WIDTH		: integer	:= 32;
	constant M_ADDR_WIDTH 		: integer	:= 16;
	constant M_BYTE_WIDTH		: integer	:= M_DATA_WIDTH/8;
	
	subtype M_DATA_RANGE is natural range M_DATA_WIDTH-1 downto 0;
	subtype M_BYTE_RANGE is natural range M_BYTE_WIDTH-1 downto 0;
	subtype M_ADDR_RANGE is natural range M_ADDR_WIDTH-1 downto 0;

	signal m_axi_ms : axi_ms_r (	arid(ID_RANGE), awid(ID_RANGE),
									araddr(M_ADDR_RANGE), awaddr(M_ADDR_RANGE),
									aruser(USER_RANGE), awuser(USER_RANGE), wuser(USER_RANGE),
									wdata(M_DATA_RANGE),
									wstrb(M_BYTE_RANGE));
	
	signal m_axi_sm : axi_sm_r (	rid(ID_RANGE), bid(ID_RANGE),
									ruser(USER_RANGE), buser(USER_RANGE),
									rdata(M_DATA_RANGE));									
									

	-------------------------------------------------------------------------
	-- TB Defnitions
	-------------------------------------------------------------------------
	constant	ClockFrequencyAxi_c	: real		:= 125.0e6;							-- Use slow clocks to speed up simulation
	constant	ClockPeriodAxi_c	: time		:= (1 sec)/ClockFrequencyAxi_c;
	signal 		TbRunning			: boolean 	:= True;
	signal 		SetupDone			: integer	:= -1;
	signal		AxiDone				: integer	:= -1;

	
	-------------------------------------------------------------------------
	-- Interface Signals
	-------------------------------------------------------------------------
	signal aclk			: std_logic							:= '0';
	signal aresetn		: std_logic							:= '0';

	-------------------------------------------------------------------------
	-- Procedures
	-------------------------------------------------------------------------	
	procedure axi_expect_wd_walk1(	Beats		: in 	natural;
									DataStart	: in	natural;
									variable DataEnd		: out	natural;
									signal ms	: in	axi_ms_r;
									signal sm	: out	axi_sm_r;
									signal aclk	: in	std_logic) is
		variable DataStdlv_v	: std_logic_vector(ms.wdata'range);									
	begin
		sm.wready <= '1';
		DataStdlv_v := std_logic_vector(to_unsigned(DataStart, DataStdlv_v'length));
		for beat in 1 to Beats loop	
			wait until rising_edge(aclk) and ms.wvalid = '1';
			-- last transfer
			assert signed(ms.wstrb) = -1 report "###ERROR###: wrong WSTRB" severity error;
			if beat = Beats then
				assert ms.wlast = '1' report "###ERROR###: WLAST not asserted at end of burst transfer" severity error;
			elsif beat = 1 then
				assert ms.wlast = '0' report "###ERROR###: WLAST asserted at beginning of burst transfer" severity error;
			else
				assert ms.wlast = '0' report "###ERROR###: WLAST asserted in the middle of burst transfer" severity error;
			end if;
			-- Apply Data
			assert ms.wdata = DataStdlv_v report "###ERROR###: wrong WDATA during butst transfer" severity error;
			DataStdlv_v := DataStdlv_v(DataStdlv_v'high-1 downto 0) & DataStdlv_v(DataStdlv_v'high);	
			-- Low cycles if required
			if not (beat = Beats) then
				sm.wready <= '1';
			end if;			
		end loop;
		sm.wready <= '0';
		DataEnd := to_integer(signed(DataStdlv_v));
	end procedure;	
	
	procedure axi_apply_rresp_walk1 (	Beats		: in 	natural;
										DataStart	: in	natural;
										variable DataEnd		: out	natural;
										Response	: in 	std_logic_vector(1 downto 0);
										signal ms	: in	axi_ms_r;
										signal sm	: out	axi_sm_r;
										signal aclk	: in	std_logic) is
		variable DataStdlv_v	: std_logic_vector(ms.wdata'range);
	begin		
		sm.rvalid 	<= '1';	
		sm.rlast 	<= '0';
		DataStdlv_v := std_logic_vector(to_unsigned(DataStart, DataStdlv_v'length));
		sm.rresp <= Response;
		for beat in 1 to Beats loop	
			-- last transfer
			if beat = Beats then
				sm.rlast <= '1';
			end if;
			-- Apply Data
			sm.rdata <= DataStdlv_v;			
			wait until rising_edge(aclk) and ms.rready = '1';
			DataStdlv_v := DataStdlv_v(DataStdlv_v'high-1 downto 0) & DataStdlv_v(DataStdlv_v'high);
			-- Low cycles if required
			if not (beat = Beats) then
				sm.rvalid <= '1';
			end if;
		end loop;
		axi_slave_init(sm);
		DataEnd := to_integer(signed(DataStdlv_v));
	end procedure;		

begin

	-------------------------------------------------------------------------
	-- DUT
	-------------------------------------------------------------------------
	i_dut : entity work.mem_test_wrapper
		generic map
		(
			-- AXI Slave
			C_S00_AXI_ID_WIDTH     	 	=> ID_WIDTH,
			-- AXI Master
			C_M00_AXI_DATA_WIDTH		=> M_DATA_WIDTH,		
			C_M00_AXI_ADDR_WIDTH		=> M_ADDR_WIDTH,		
			C_M00_AXI_MAX_BURST_SIZE	=> 16,	
			C_M00_AXI_MAX_OPEN_TRANS	=> 2			
		)
		port map
		(
			-- Control Interface		
			axi_aclk            =>  aclk,                                        
			axi_aresetn         => aresetn,		
			-- Axi Slave Bus Interface
			s00_axi_arid        => s_axi_ms.arid,
			s00_axi_araddr      => s_axi_ms.araddr,
			s00_axi_arlen       => s_axi_ms.arlen,
			s00_axi_arsize      => s_axi_ms.arsize,
			s00_axi_arburst     => s_axi_ms.arburst,
			s00_axi_arlock      => s_axi_ms.arlock,
			s00_axi_arcache     => s_axi_ms.arcache,
			s00_axi_arprot      => s_axi_ms.arprot,
			s00_axi_arvalid     => s_axi_ms.arvalid,
			s00_axi_arready     => s_axi_sm.arready,
			s00_axi_rid         => s_axi_sm.rid,
			s00_axi_rdata       => s_axi_sm.rdata,
			s00_axi_rresp       => s_axi_sm.rresp,
			s00_axi_rlast       => s_axi_sm.rlast,
			s00_axi_rvalid      => s_axi_sm.rvalid,
			s00_axi_rready      => s_axi_ms.rready,
			s00_axi_awid    	=> s_axi_ms.awid,    
			s00_axi_awaddr      => s_axi_ms.awaddr,
			s00_axi_awlen       => s_axi_ms.awlen,
			s00_axi_awsize      => s_axi_ms.awsize,
			s00_axi_awburst     => s_axi_ms.awburst,
			s00_axi_awlock      => s_axi_ms.awlock,
			s00_axi_awcache     => s_axi_ms.awcache,
			s00_axi_awprot      => s_axi_ms.awprot,
			s00_axi_awvalid     => s_axi_ms.awvalid,
			s00_axi_awready     => s_axi_sm.awready,
			s00_axi_wdata       => s_axi_ms.wdata,
			s00_axi_wstrb       => s_axi_ms.wstrb,
			s00_axi_wlast       => s_axi_ms.wlast,
			s00_axi_wvalid      => s_axi_ms.wvalid,
			s00_axi_wready      => s_axi_sm.wready,
			s00_axi_bid         => s_axi_sm.bid,
			s00_axi_bresp       => s_axi_sm.bresp,
			s00_axi_bvalid      => s_axi_sm.bvalid,
			s00_axi_bready      => s_axi_ms.bready,
			-- Axi Master Bus Interface
			m00_axi_awaddr		=> m_axi_ms.awaddr,	
			m00_axi_awlen		=> m_axi_ms.awlen,						
			m00_axi_awsize		=> m_axi_ms.awsize,						
			m00_axi_awburst		=> m_axi_ms.awburst,							
			m00_axi_awlock		=> m_axi_ms.awlock,										
			m00_axi_awcache		=> m_axi_ms.awcache,					
			m00_axi_awprot		=> m_axi_ms.awprot,						
			m00_axi_awvalid		=> m_axi_ms.awvalid,                                           
			m00_axi_awready		=> m_axi_sm.awready,                                                                                                   
			m00_axi_wdata		=> m_axi_ms.wdata,
			m00_axi_wstrb		=> m_axi_ms.wstrb, 
			m00_axi_wlast		=> m_axi_ms.wlast,                                            
			m00_axi_wvalid		=> m_axi_ms.wvalid,                                         
			m00_axi_wready		=> m_axi_sm.wready,                                                                                      
			m00_axi_bresp		=> m_axi_sm.bresp,                         
			m00_axi_bvalid		=> m_axi_sm.bvalid,                                           
			m00_axi_bready		=> m_axi_ms.bready,                                                                                              
			m00_axi_araddr		=> m_axi_ms.araddr,   
			m00_axi_arlen		=> m_axi_ms.arlen,                        
			m00_axi_arsize		=> m_axi_ms.arsize,                         
			m00_axi_arburst		=> m_axi_ms.arburst,                        
			m00_axi_arlock		=> m_axi_ms.arlock,                                              
			m00_axi_arcache		=> m_axi_ms.arcache,                           
			m00_axi_arprot		=> m_axi_ms.arprot,                           
			m00_axi_arvalid		=> m_axi_ms.arvalid,                                              
			m00_axi_arready		=> m_axi_sm.arready,                                                                                                      
			m00_axi_rdata		=> m_axi_sm.rdata,           
			m00_axi_rresp		=> m_axi_sm.rresp,                       
			m00_axi_rlast		=> m_axi_sm.rlast,                                              
			m00_axi_rvalid		=> m_axi_sm.rvalid,                                            
			m00_axi_rready		=> m_axi_ms.rready	
		);
	
	-------------------------------------------------------------------------
	-- Clock
	-------------------------------------------------------------------------
	p_aclk : process
	begin
		aclk <= '0';
		while TbRunning loop
			wait for 0.5*ClockPeriodAxi_c;
			aclk <= '1';
			wait for 0.5*ClockPeriodAxi_c;
			aclk <= '0';
		end loop;
		wait;
	end process;
	
	-------------------------------------------------------------------------
	-- TB Control
	-------------------------------------------------------------------------
	p_control : process
		variable Readback_v	: integer;
		variable ReadbackSlv_v : std_logic_vector(31 downto 0);
	begin
		-- Reset
		aresetn <= '0';
		wait for 1 us;
		wait until rising_edge(aclk);
		aresetn <= '1';
		wait for 1 us;
		wait until rising_edge(aclk);
		
		-- *** Start Own Address Pattern from 0xA8 to 0x1A7, success ***
		print(">> Start Own Address Pattern from 0xA8 to 0x1A7, success");
		axi_single_write(REG_MODE*4, 		C_MODE_SINGLE, 				s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_SIZE_LO*4, 	16#100#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_PATTERN_SEL*4, C_PATTERN_SEL_OWNADD, 		s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_ADDR_LO*4, 	16#A8#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_START*4, 		1, 							s_axi_ms, s_axi_sm, aclk);
		SetupDone <= 0;
		wait until AxiDone = 0;
		wait until rising_edge(aclk);
		axi_single_expect(REG_STATUS*4,		 C_STATUS_IDLE, 		s_axi_ms, s_axi_sm, aclk, "Status not idle 0"); 	
		axi_single_expect(REG_ERRORS*4,		 0, 					s_axi_ms, s_axi_sm, aclk, "Unexpected Errors 0");

		-- *** Start Own Address Pattern from 0xA8 to 0x1A7, errors ***		
		print(">> Start Own Address Pattern from 0xA8 to 0x1A7, errors");
		axi_single_write(REG_MODE*4, 		C_MODE_SINGLE, 				s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_SIZE_LO*4, 	16#100#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_PATTERN_SEL*4, C_PATTERN_SEL_OWNADD, 		s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_ADDR_LO*4, 	16#A8#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_START*4, 		1, 							s_axi_ms, s_axi_sm, aclk);
		SetupDone <= 1;
		-- Check if status is updated
		Readback_v := 0;
		while Readback_v /= C_STATUS_WRITING loop
			axi_single_read(REG_STATUS*4, Readback_v, s_axi_ms, s_axi_sm, aclk);
		end loop;
		Readback_v := 0;
		while Readback_v /= C_STATUS_READING loop
			axi_single_read(REG_STATUS*4, Readback_v, s_axi_ms, s_axi_sm, aclk);
		end loop;	
		-- Check result
		wait until AxiDone = 1;
		wait until rising_edge(aclk);
		axi_single_expect(REG_STATUS*4,		 C_STATUS_IDLE, 		s_axi_ms, s_axi_sm, aclk, "Status not idle 1"); 	
		axi_single_expect(REG_ERRORS*4,		 15, 					s_axi_ms, s_axi_sm, aclk, "Errors not found 1");
		axi_single_expect(REG_FERR_ADDR_LO*4,16#EC#, 				s_axi_ms, s_axi_sm, aclk, "Error addr lo wrong 1");
		axi_single_expect(REG_FERR_ADDR_HI*4,0, 					s_axi_ms, s_axi_sm, aclk, "Error addr hi wrong 1");

		-- *** Continuous ***
		print(">> Continuous");
		axi_single_write(REG_MODE*4, 		C_MODE_CONTINUOUS, 			s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_SIZE_LO*4, 	16#100#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_PATTERN_SEL*4, C_PATTERN_SEL_OWNADD, 		s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_ADDR_LO*4, 	16#A8#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_START*4, 		1, 							s_axi_ms, s_axi_sm, aclk);
		SetupDone <= 2;
		-- Check if iteration counter
		Readback_v := 0;
		while Readback_v /= 2 loop
			axi_single_read(REG_ITER*4, Readback_v, s_axi_ms, s_axi_sm, aclk);
		end loop;
		-- Stop continuous running during 3rd iteration
		axi_single_write(REG_STOP*4, 		1, 							s_axi_ms, s_axi_sm, aclk);
		wait until AxiDone = 2;
		wait until rising_edge(aclk);
		axi_single_expect(REG_STATUS*4,		 C_STATUS_IDLE, 		s_axi_ms, s_axi_sm, aclk, "Status not idle 2"); 	
		axi_single_expect(REG_ERRORS*4,		 15*3, 					s_axi_ms, s_axi_sm, aclk, "Errors not found 2");
		axi_single_expect(REG_ITER*4,		 3, 					s_axi_ms, s_axi_sm, aclk, "Wrong Iteration counter 2");
		
		-- *** Start Counter Pattern from 0xA8 to 0x1A7, success ***
		print(">> Start Counter Pattern from 0xA8 to 0x1A7, success");
		axi_single_write(REG_MODE*4, 		C_MODE_SINGLE, 				s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_SIZE_LO*4, 	16#100#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_PATTERN_SEL*4, C_PATTERN_SEL_COUNT, 		s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_ADDR_LO*4, 	16#A8#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_START*4, 		1, 							s_axi_ms, s_axi_sm, aclk);
		SetupDone <= 3;
		wait until AxiDone = 3;
		wait until rising_edge(aclk);
		axi_single_expect(REG_STATUS*4,		 C_STATUS_IDLE, 		s_axi_ms, s_axi_sm, aclk, "Status not idle 3"); 	
		axi_single_expect(REG_ERRORS*4,		 0, 					s_axi_ms, s_axi_sm, aclk, "Unexpected Errors 3");
		
		-- *** Walking 1 Pattern from 0x000 to 0x200, errors ***		
		print(">> Walking 1 Pattern from 0x000 to 0x200, errors");
		axi_single_write(REG_MODE*4, 		C_MODE_SINGLE, 				s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_SIZE_LO*4, 	16#200#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_PATTERN_SEL*4, C_PATTERN_SEL_WALK1, 		s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_ADDR_LO*4, 	16#000#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_START*4, 		1, 							s_axi_ms, s_axi_sm, aclk);
		SetupDone <= 4;
		-- Check result
		wait until AxiDone = 4;
		wait until rising_edge(aclk);
		axi_single_expect(REG_STATUS*4,		 C_STATUS_IDLE, 		s_axi_ms, s_axi_sm, aclk, "Status not idle 4"); 	
		axi_single_expect(REG_ERRORS*4,		 16, 					s_axi_ms, s_axi_sm, aclk, "Errors not found 4");
		axi_single_expect(REG_FERR_ADDR_LO*4,16#1C0#, 				s_axi_ms, s_axi_sm, aclk, "Error addr lo wrong 4");
		axi_single_expect(REG_FERR_ADDR_HI*4, 0, 					s_axi_ms, s_axi_sm, aclk, "Error addr hi wrong 4");		
		
		-- *** Write Only ***
		print(">> Write Only");
		axi_single_write(REG_MODE*4, 		C_MODE_WRITEONLY, 			s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_SIZE_LO*4, 	16#100#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_PATTERN_SEL*4, C_PATTERN_SEL_OWNADD, 		s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_ADDR_LO*4, 	16#A8#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_START*4, 		1, 							s_axi_ms, s_axi_sm, aclk);
		SetupDone <= 5;
		Readback_v := -1;
		while Readback_v /= C_STATUS_IDLE loop
			axi_single_read(REG_STATUS*4, Readback_v, s_axi_ms, s_axi_sm, aclk);
			assert Readback_v /= C_STATUS_READING report "###ERROR###: read operation during write-only" severity error;
		end loop;	
		wait until rising_edge(aclk);
		axi_single_expect(REG_STATUS*4,		 C_STATUS_IDLE, 		s_axi_ms, s_axi_sm, aclk, "Status not idle 5"); 	
		axi_single_expect(REG_ERRORS*4,		 0, 					s_axi_ms, s_axi_sm, aclk, "Unexpected Errors 5");		
		
		-- *** Read Only ***
		print(">> Read Only");
		axi_single_write(REG_MODE*4, 		C_MODE_READONLY, 			s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_SIZE_LO*4, 	16#100#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_PATTERN_SEL*4, C_PATTERN_SEL_OWNADD, 		s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_ADDR_LO*4, 	16#A8#, 					s_axi_ms, s_axi_sm, aclk);
		axi_single_write(REG_START*4, 		1, 							s_axi_ms, s_axi_sm, aclk);
		SetupDone <= 6;
		Readback_v := -1;
		while Readback_v /= C_STATUS_IDLE loop
			axi_single_read(REG_STATUS*4, Readback_v, s_axi_ms, s_axi_sm, aclk);
			assert Readback_v /= C_STATUS_WRITING report "###ERROR###: write operation during read-only" severity error;
		end loop;	
		wait until rising_edge(aclk);
		axi_single_expect(REG_STATUS*4,		 C_STATUS_IDLE, 		s_axi_ms, s_axi_sm, aclk, "Status not idle 6"); 	
		axi_single_expect(REG_ERRORS*4,		 0, 					s_axi_ms, s_axi_sm, aclk, "Unexpected Errors 6");			
		
		-- TB done
		TbRunning <= false;
		wait;
	end process;
	
	-------------------------------------------------------------------------
	-- AXI Emulation
	-------------------------------------------------------------------------
	p_axi : process
		variable Addr_v : integer	:= 0;
		variable Cnt_v : integer  := 0;
		variable Incr_v : integer;
	begin	
		-- *** Start Own Address Pattern from 0xA8 to 0x1A7, success ***		
		wait until SetupDone = 0;
		wait until rising_edge(aclk);
		Addr_v := 16#A8#;
		while Addr_v < 16#1A8# loop
			axi_expect_aw(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
			axi_expect_wd_burst(16, Addr_v, 4, "1111", "1111", m_axi_ms, m_axi_sm, aclk);
			axi_apply_bresp(xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
			Addr_v := Addr_v + 16*4;
		end loop;
		Addr_v := 16#A8#;
		while Addr_v < 16#1A8# loop
			axi_expect_ar(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
			axi_apply_rresp_burst(	16, Addr_v, 4, xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
			Addr_v := Addr_v + 16*4;
		end loop;	
		AxiDone <= 0;		
		
		-- *** Start Own Address Pattern from 0xA8 to 0x1A7, errors ***
		wait until SetupDone = 1;
		wait until rising_edge(aclk);
		Addr_v := 16#A8#;
		while Addr_v < 16#1A8# loop
			axi_expect_aw(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
			axi_expect_wd_burst(16, Addr_v, 4, "1111", "1111", m_axi_ms, m_axi_sm, aclk);
			axi_apply_bresp(xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
			Addr_v := Addr_v + 16*4;
		end loop;
		Addr_v := 16#A8#;
		while Addr_v < 16#1A8# loop
			-- For the address block starting at 16#A8#+16*4 , use a wrong increment to produce 15 errors (first error at 0xEC)
			if Addr_v = 16#E8# then
				Incr_v := 1;
			else
				Incr_v := 4;
			end if;
			axi_expect_ar(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
			axi_apply_rresp_burst(	16, Addr_v, Incr_v, xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
			Addr_v := Addr_v + 16*4;
		end loop;	
		AxiDone <= 1;	

		-- *** Continuous *** (same as above but 3 times)
		wait until SetupDone = 2;
		wait until rising_edge(aclk);
		for i in 0 to 2 loop
			Addr_v := 16#A8#;
			while Addr_v < 16#1A8# loop
				axi_expect_aw(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
				axi_expect_wd_burst(16, Addr_v, 4, "1111", "1111", m_axi_ms, m_axi_sm, aclk);
				axi_apply_bresp(xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
				Addr_v := Addr_v + 16*4;
			end loop;
			Addr_v := 16#A8#;
			while Addr_v < 16#1A8# loop
				-- For the address block starting at 16#A8#+16*4 , use a wrong increment to produce 15 errors (first error at 0xEC)
				if Addr_v = 16#E8# then
					Incr_v := 1;
				else
					Incr_v := 4;
				end if;
				axi_expect_ar(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
				axi_apply_rresp_burst(	16, Addr_v, Incr_v, xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
				Addr_v := Addr_v + 16*4;
			end loop;	
		end loop;
		AxiDone <= 2;	
		
		-- *** Start Counter Pattern from 0xA8 to 0x1A7, success ***
		wait until SetupDone = 3;
		wait until rising_edge(aclk);
		Addr_v := 16#A8#;
		Cnt_v := 0;
		while Addr_v < 16#1A8# loop
			axi_expect_aw(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
			axi_expect_wd_burst(16, Cnt_v, 1, "1111", "1111", m_axi_ms, m_axi_sm, aclk);
			axi_apply_bresp(xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
			Addr_v := Addr_v + 16*4;
			Cnt_v := Cnt_v + 16;
		end loop;
		Addr_v := 16#A8#;
		Cnt_v := 0;
		while Addr_v < 16#1A8# loop
			axi_expect_ar(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
			axi_apply_rresp_burst(	16, Cnt_v, 1, xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
			Addr_v := Addr_v + 16*4;
			Cnt_v := Cnt_v + 16;
		end loop;	
		AxiDone <= 3;			
	
		-- *** Walking 1 Pattern from 0x000 to 0x200, errors ***
		wait until SetupDone = 4;
		wait until rising_edge(aclk);
		Addr_v := 16#000#;
		Cnt_v := 1;
		while Addr_v < 16#1FC# loop
			axi_expect_aw(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
			axi_expect_wd_walk1(16, Cnt_v, Cnt_v, m_axi_ms, m_axi_sm, aclk);
			axi_apply_bresp(xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
			Addr_v := Addr_v + 16*4;
		end loop;
		Addr_v := 16#000#;
		Cnt_v := 1;
		while Addr_v < 16#1FC# loop
			if Addr_v = 16#1C0# then
				Cnt_v := Cnt_v + 1;
			end if;
			axi_expect_ar(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
			axi_apply_rresp_walk1(	16, Cnt_v, Cnt_v, xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
			Addr_v := Addr_v + 16*4;
		end loop;	
		AxiDone <= 4;	
		
		-- *** Write Only ***		
		wait until SetupDone = 5;
		wait until rising_edge(aclk);
		Addr_v := 16#A8#;
		while Addr_v < 16#1A8# loop
			axi_expect_aw(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
			axi_expect_wd_burst(16, Addr_v, 4, "1111", "1111", m_axi_ms, m_axi_sm, aclk);
			axi_apply_bresp(xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
			Addr_v := Addr_v + 16*4;
		end loop;	
		AxiDone <= 5;	
		
		-- *** Read Only  ***		
		wait until SetupDone = 6;
		wait until rising_edge(aclk);
		Addr_v := 16#A8#;
		while Addr_v < 16#1A8# loop
			axi_expect_ar(	Addr_v, AxSIZE_4_c, 16-1, xBURST_INCR_c, m_axi_ms, m_axi_sm, aclk);
			axi_apply_rresp_burst(	16, Addr_v, 4, xRESP_OKAY_c, m_axi_ms, m_axi_sm, aclk);
			Addr_v := Addr_v + 16*4;
		end loop;	
		AxiDone <= 6;			
		
		wait;
	end process;	
	

end sim;
