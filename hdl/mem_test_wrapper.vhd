------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

library work;
	use work.mem_test_pkg.all;

entity mem_test_wrapper is 
	generic (
		-- Parameters of Axi Slave Bus Interface
		-- AXI Parameters
		C_S00_AXI_ID_WIDTH          : integer := 1;
		-- DDR Parameters
		C_M00_AXI_DATA_WIDTH		: integer := 64;			
		C_M00_AXI_ADDR_WIDTH		: integer := 32;			
		C_M00_AXI_MAX_BURST_SIZE	: integer := 16;		
		C_M00_AXI_MAX_OPEN_TRANS	: integer  := 2			
	);
	port (
		-----------------------------------------------------------------------------
		-- Shared signals
		-----------------------------------------------------------------------------	
		axi_aclk                	: in    std_logic;                                            
		axi_aresetn             	: in    std_logic;                                             
		
		-----------------------------------------------------------------------------
		-- Axi Slave Bus Interface
		-----------------------------------------------------------------------------

		-- Read address channel
		s00_axi_arid                : in    std_logic_vector(C_S00_AXI_ID_WIDTH-1   downto 0);     
		s00_axi_araddr              : in    std_logic_vector(7 downto 0);     
		s00_axi_arlen               : in    std_logic_vector(7 downto 0);                          
		s00_axi_arsize              : in    std_logic_vector(2 downto 0);                          
		s00_axi_arburst             : in    std_logic_vector(1 downto 0);                          
		s00_axi_arlock              : in    std_logic;                                             
		s00_axi_arcache             : in    std_logic_vector(3 downto 0);                          
		s00_axi_arprot              : in    std_logic_vector(2 downto 0);                          
		s00_axi_arvalid             : in    std_logic;                                             
		s00_axi_arready             : out   std_logic;                                             
		-- Read data channel
		s00_axi_rid                 : out   std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);       
		s00_axi_rdata               : out   std_logic_vector(31 downto 0);     
		s00_axi_rresp               : out   std_logic_vector(1 downto 0);                          
		s00_axi_rlast               : out   std_logic;                                             
		s00_axi_rvalid              : out   std_logic;                                             
		s00_axi_rready              : in    std_logic;                                             
		-- Write address channel
		s00_axi_awid                : in    std_logic_vector(C_S00_AXI_ID_WIDTH-1   downto 0);     
		s00_axi_awaddr              : in    std_logic_vector(7 downto 0);     
		s00_axi_awlen               : in    std_logic_vector(7 downto 0);                          
		s00_axi_awsize              : in    std_logic_vector(2 downto 0);                          
		s00_axi_awburst             : in    std_logic_vector(1 downto 0);                          
		s00_axi_awlock              : in    std_logic;                                             
		s00_axi_awcache             : in    std_logic_vector(3 downto 0);                          
		s00_axi_awprot              : in    std_logic_vector(2 downto 0);                          
		s00_axi_awvalid             : in    std_logic;                                             
		s00_axi_awready             : out   std_logic;                                             
		-- Write data channel
		s00_axi_wdata               : in    std_logic_vector(31    downto 0); 
		s00_axi_wstrb               : in    std_logic_vector(3 downto 0); 
		s00_axi_wlast               : in    std_logic;                                             
		s00_axi_wvalid              : in    std_logic;                                             
		s00_axi_wready              : out   std_logic;                                             
		-- Write response channel
		s00_axi_bid                 : out   std_logic_vector(C_S00_AXI_ID_WIDTH-1 downto 0);       
		s00_axi_bresp               : out   std_logic_vector(1 downto 0);                          
		s00_axi_bvalid              : out   std_logic;                                             
		s00_axi_bready              : in    std_logic;                                             
		
		-----------------------------------------------------------------------------
		-- Axi Master Bus Interface
		-----------------------------------------------------------------------------				
		-- AXI Address Write Channel
		m00_axi_awaddr				: out	std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);		
		m00_axi_awlen				: out	std_logic_vector(7 downto 0);							
		m00_axi_awsize				: out	std_logic_vector(2 downto 0);							
		m00_axi_awburst				: out	std_logic_vector(1 downto 0);							
		m00_axi_awlock				: out	std_logic;												
		m00_axi_awcache				: out	std_logic_vector(3 downto 0);							
		m00_axi_awprot				: out	std_logic_vector(2 downto 0);							
		m00_axi_awvalid				: out	std_logic;                                             
		m00_axi_awready				: in	std_logic;                                             
		-- AXI Write Data Channel                                                         
		m00_axi_wdata				: out	std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);     
		m00_axi_wstrb				: out	std_logic_vector(C_M00_AXI_DATA_WIDTH/8-1 downto 0);   
		m00_axi_wlast				: out	std_logic;                                             
		m00_axi_wvalid				: out	std_logic;                                             
		m00_axi_wready				: in	std_logic;                                     
		-- AXI Write Response Channel                                                     
		m00_axi_bresp				: in	std_logic_vector(1 downto 0);                          
		m00_axi_bvalid				: in	std_logic;                                             
		m00_axi_bready				: out	std_logic;                                            
		-- AXI Read Address Channel                                                       
		m00_axi_araddr				: out	std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);     
		m00_axi_arlen				: out	std_logic_vector(7 downto 0);                          
		m00_axi_arsize				: out	std_logic_vector(2 downto 0);                          
		m00_axi_arburst				: out	std_logic_vector(1 downto 0);                          
		m00_axi_arlock				: out	std_logic;                                                
		m00_axi_arcache				: out	std_logic_vector(3 downto 0);                             
		m00_axi_arprot				: out	std_logic_vector(2 downto 0);                             
		m00_axi_arvalid				: out	std_logic;                                                
		m00_axi_arready				: in	std_logic;                                                
		-- AXI Read Data Channel                                                          
		m00_axi_rdata				: in	std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);              
		m00_axi_rresp				: in	std_logic_vector(1 downto 0);                             
		m00_axi_rlast				: in	std_logic;                                                
		m00_axi_rvalid				: in	std_logic;                                                
		m00_axi_rready				: out	std_logic		                                          
    );
                                                                                          
end mem_test_wrapper;

architecture rtl of mem_test_wrapper is

	-----------------------------------------------------------------------------
	-- Register Interface
	-----------------------------------------------------------------------------
	signal   reg_rd                : rd_t;
	signal   reg_rdata             : rdata_t;
	signal   reg_wr                : wr_t;
	signal   reg_wdata             : wdata_t;
	
	-----------------------------------------------------------------------------
	-- Axi Master
	-----------------------------------------------------------------------------   
   	signal CmdWr_Addr		: std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0)			:= (others => '0');
	signal CmdWr_Size		: std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0)			:= (others => '0');  
	signal CmdWr_LowLat		: std_logic													:= '0';	
	signal CmdWr_Vld		: std_logic													:= '0';	
	signal CmdWr_Rdy		: std_logic													:= '0';			
	signal CmdRd_Addr		: std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0)			:= (others => '0');	
	signal CmdRd_Size		: std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0)			:= (others => '0'); 
	signal CmdRd_LowLat		: std_logic													:= '0';				
	signal CmdRd_Vld		: std_logic													:= '0';				
	signal CmdRd_Rdy		: std_logic													:= '0';
	signal WrDat_Data		: std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0)			:= (others => '0');	
	signal WrDat_Be			: std_logic_vector(C_M00_AXI_DATA_WIDTH/8-1 downto 0)		:= (others => '0');	
	signal WrDat_Vld		: std_logic													:= '0';
	signal WrDat_Rdy		: std_logic													:= '0';	
	signal RdDat_Data		: std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0)			:= (others => '0');	
	signal RdDat_Vld		: std_logic													:= '0';	
	signal RdDat_Rdy		: std_logic													:= '0';	
	signal Wr_Done			: std_logic													:= '0';	
	signal Wr_Error			: std_logic													:= '0';	
	signal Rd_Done			: std_logic													:= '0';	
	signal Rd_Error			: std_logic													:= '0';	

begin
	-----------------------------------------------------------------------------
	-- AXI decode instance
	-----------------------------------------------------------------------------
	i_slave : entity work.psi_common_axi_slave_ipif
	generic map
	(
		-- Users parameters
		NumReg_g			=> USER_SLV_NUM_REG,
		UseMem_g			=> false,
		-- Parameters of Axi Slave Bus Interface
		AxiIdWidth_g			=> C_S00_AXI_ID_WIDTH,
		AxiAddrWidth_g			=> 8
	)
	port map
	(
		--------------------------------------------------------------------------
		-- Axi Slave Bus Interface
		--------------------------------------------------------------------------
		-- System
		s_axi_aclk                  => axi_aclk,
		s_axi_aresetn               => axi_aresetn,
		-- Read address channel
		s_axi_arid                  => s00_axi_arid,
		s_axi_araddr                => s00_axi_araddr,
		s_axi_arlen                 => s00_axi_arlen,
		s_axi_arsize                => s00_axi_arsize,
		s_axi_arburst               => s00_axi_arburst,
		s_axi_arlock                => s00_axi_arlock,
		s_axi_arcache               => s00_axi_arcache,
		s_axi_arprot                => s00_axi_arprot,
		s_axi_arvalid               => s00_axi_arvalid,
		s_axi_arready               => s00_axi_arready,
		-- Read data channel
		s_axi_rid                   => s00_axi_rid,
		s_axi_rdata                 => s00_axi_rdata,
		s_axi_rresp                 => s00_axi_rresp,
		s_axi_rlast                 => s00_axi_rlast,
		s_axi_rvalid                => s00_axi_rvalid,
		s_axi_rready                => s00_axi_rready,
		-- Write address channel
		s_axi_awid                  => s00_axi_awid,
		s_axi_awaddr                => s00_axi_awaddr,
		s_axi_awlen                 => s00_axi_awlen,
		s_axi_awsize                => s00_axi_awsize,
		s_axi_awburst               => s00_axi_awburst,
		s_axi_awlock                => s00_axi_awlock,
		s_axi_awcache               => s00_axi_awcache,
		s_axi_awprot                => s00_axi_awprot,
		s_axi_awvalid               => s00_axi_awvalid,
		s_axi_awready               => s00_axi_awready,
		-- Write data channel
		s_axi_wdata                 => s00_axi_wdata,
		s_axi_wstrb                 => s00_axi_wstrb,
		s_axi_wlast                 => s00_axi_wlast,
		s_axi_wvalid                => s00_axi_wvalid,
		s_axi_wready                => s00_axi_wready,
		-- Write response channel
		s_axi_bid                   => s00_axi_bid,
		s_axi_bresp                 => s00_axi_bresp,
		s_axi_bvalid                => s00_axi_bvalid,
		s_axi_bready                => s00_axi_bready,
		--------------------------------------------------------------------------
		-- Register Interface
		--------------------------------------------------------------------------
		o_reg_rd                    => reg_rd,
		i_reg_rdata                 => reg_rdata,
		o_reg_wr                    => reg_wr,
		o_reg_wdata                 => reg_wdata
   );
   
	i_master : entity work.psi_common_axi_master_simple
		generic map (
			AxiAddrWidth_g				=> C_M00_AXI_ADDR_WIDTH,
			AxiDataWidth_g				=> C_M00_AXI_DATA_WIDTH,
			AxiMaxBeats_g				=> C_M00_AXI_MAX_BURST_SIZE,
			AxiMaxOpenTrasactions_g		=> C_M00_AXI_MAX_OPEN_TRANS,
			UserTransactionSizeBits_g	=> C_M00_AXI_ADDR_WIDTH,
			DataFifoDepth_g				=> 1024,
			ImplRead_g					=> true,
			ImplWrite_g					=> true,
			RamBehavior_g				=> "RBW"
		)
		port map (
			-- Control Signals
			M_Axi_Aclk		=> axi_aclk,
			M_Axi_Aresetn	=> axi_aresetn,			
			-- User Command Interface
			CmdWr_Addr		=> CmdWr_Addr,	
			CmdWr_Size		=> CmdWr_Size,
			CmdWr_LowLat	=> CmdWr_LowLat,
			CmdWr_Vld		=> CmdWr_Vld,
			CmdWr_Rdy		=> CmdWr_Rdy,	
			-- User Command Interface
			CmdRd_Addr		=> CmdRd_Addr,
			CmdRd_Size		=> CmdRd_Size,	
			CmdRd_LowLat	=> CmdRd_LowLat,	
			CmdRd_Vld		=> CmdRd_Vld,	
			CmdRd_Rdy		=> CmdRd_Rdy,			
			-- Write Data
			WrDat_Data		=> WrDat_Data,	
			WrDat_Be		=> WrDat_Be,		
			WrDat_Vld		=> WrDat_Vld,	
			WrDat_Rdy		=> WrDat_Rdy,		
			-- Read Data
			RdDat_Data		=> RdDat_Data,	
			RdDat_Vld		=> RdDat_Vld,	
			RdDat_Rdy		=> RdDat_Rdy,			
			-- Response
			Wr_Done			=> Wr_Done,	
			Wr_Error		=> Wr_Error,
			Rd_Done			=> Rd_Done,	
			Rd_Error		=> Rd_Error,
			-- AXI Address Write Channel
			M_Axi_AwAddr	=> m00_axi_awaddr,
			M_Axi_AwLen		=> m00_axi_awlen,
			M_Axi_AwSize	=> m00_axi_awsize,
			M_Axi_AwBurst	=> m00_axi_awburst,
			M_Axi_AwLock	=> m00_axi_awlock,
			M_Axi_AwCache	=> m00_axi_awcache,
			M_Axi_AwProt	=> m00_axi_awprot,
			M_Axi_AwValid	=> m00_axi_awvalid,
			M_Axi_AwReady	=> m00_axi_awready,
			-- AXI Write Data Channel                                                           
			M_Axi_WData		=> m00_axi_wdata,
			M_Axi_WStrb		=> m00_axi_wstrb,
			M_Axi_WLast		=> m00_axi_wlast,
			M_Axi_WValid	=> m00_axi_wvalid,
			M_Axi_WReady	=> m00_axi_wready,
			-- AXI Write Response Channel
			M_Axi_BResp		=> m00_axi_bresp,
			M_Axi_BValid	=> m00_axi_bvalid,
			M_Axi_BReady	=> m00_axi_bready,
			-- AXI Read Address Channel                                                         
			M_Axi_ArAddr	=> m00_axi_araddr,
			M_Axi_ArLen		=> m00_axi_arlen,
			M_Axi_ArSize	=> m00_axi_arsize,
			M_Axi_ArBurst	=> m00_axi_arburst,
			M_Axi_ArLock	=> m00_axi_arlock,
			M_Axi_ArCache	=> m00_axi_arcache,
			M_Axi_ArProt	=> m00_axi_arprot,
			M_Axi_ArValid	=> m00_axi_arvalid,
			M_Axi_ArReady	=> m00_axi_arready,
			-- AXI Read Data Channel                                                     
			M_Axi_RData		=> m00_axi_rdata,
			M_Axi_RResp		=> m00_axi_rresp,
			M_Axi_RLast		=> m00_axi_rlast,
			M_Axi_RValid	=> m00_axi_rvalid,
			M_Axi_RReady	=> m00_axi_rready
		);
		
	i_logic : entity work.mem_test
		generic map (
			AxiAddrWidth_g		=> C_M00_AXI_ADDR_WIDTH,
			AxiDataWidth_g		=> C_M00_AXI_DATA_WIDTH
		)
		port  map (
			-- Control Signals
			Clk				=> axi_aclk,
			Rst_n			=> axi_aresetn,			
			-- Register bank interface
			Reg_Rd			=> Reg_Rd,
			Reg_RData		=> Reg_RData,
			Reg_Wr			=> Reg_Wr,
			Reg_WData		=> Reg_WData,
			-- AXI Master IF
			CmdWr_Addr		=> CmdWr_Addr,
			CmdWr_Size		=> CmdWr_Size,	
			CmdWr_LowLat	=> CmdWr_LowLat,
			CmdWr_Vld		=> CmdWr_Vld,	
			CmdWr_Rdy		=> CmdWr_Rdy,	
			CmdRd_Addr		=> CmdRd_Addr,	
			CmdRd_Size		=> CmdRd_Size,	
			CmdRd_LowLat	=> CmdRd_LowLat,
			CmdRd_Vld		=> CmdRd_Vld,	
			CmdRd_Rdy		=> CmdRd_Rdy,	
			WrDat_Data		=> WrDat_Data,	
			WrDat_Be		=> WrDat_Be,	
			WrDat_Vld		=> WrDat_Vld,	
			WrDat_Rdy		=> WrDat_Rdy,	
			RdDat_Data		=> RdDat_Data,	
			RdDat_Vld		=> RdDat_Vld,	
			RdDat_Rdy		=> RdDat_Rdy,	
			Wr_Done			=> Wr_Done,		
			Wr_Error		=> Wr_Error,	
			Rd_Done			=> Rd_Done,		
			Rd_Error		=> Rd_Error
		);
 
end rtl; 
