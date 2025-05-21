// Copyright AccurateRTL contributors.
// Licensed under the MIT License, see LICENSE for details.
// SPDX-License-Identifier: MIT

module lio_axi_mcdc #(
    parameter ADDR_WIDTH     = 32,
    parameter DATA_WIDTH     = 32,
    parameter ID_WIDTH       = 4,
    parameter STRB_WIDTH     = DATA_WIDTH/8
)
( 
  input                                axis_aclk,
  input                                axis_arstn,
  
  input                                axim_aclk,
  input                                axim_arstn,
   
//*********************************************************************
//*   AXI4 slave interface for first clock domain
//*********************************************************************

  input         [ID_WIDTH-1:0]         axis_awid,
  input         [ADDR_WIDTH-1:0]       axis_awaddr,
  input         [7:0]                  axis_awlen,
  input         [2:0]                  axis_awsize,
  input         [1:0]                  axis_awburst,
  input                                axis_awlock,
  input         [3:0]                  axis_awcache,
  input         [2:0]                  axis_awprot,
  input         [3:0]                  axis_awqos,
  input         [3:0]                  axis_awregion,
  input                                axis_awvalid,
  output logic                         axis_awready,
  input         [ID_WIDTH-1:0]         axis_wid,
  input         [DATA_WIDTH-1:0]       axis_wdata,
  input         [STRB_WIDTH-1:0]       axis_wstrb,
  input                                axis_wlast,
  input                                axis_wvalid,
  output logic                         axis_wready,
  output logic  [ID_WIDTH-1:0]         axis_bid,
  output logic  [1:0]                  axis_bresp,
  output logic                         axis_bvalid,
  input                                axis_bready,
  input         [ID_WIDTH-1:0]         axis_arid,
  input         [ADDR_WIDTH-1:0]       axis_araddr,
  input         [7:0]                  axis_arlen,
  input         [2:0]                  axis_arsize,
  input         [1:0]                  axis_arburst,
  input                                axis_arlock,
  input         [3:0]                  axis_arcache,
  input         [2:0]                  axis_arprot,
  input         [3:0]                  axis_arqos,
  input         [3:0]                  axis_arregion,
  input                                axis_arvalid,
  output logic                         axis_arready,
  output logic  [ID_WIDTH-1:0]         axis_rid,
  output logic  [DATA_WIDTH-1:0]       axis_rdata,
  output logic  [1:0]                  axis_rresp,
  output logic                         axis_rlast,
  output logic                         axis_rvalid,
  input                                axis_rready,

//*********************************************************************
//*   AXI4 slave interface other clock domain
//*********************************************************************

  output logic   [ ID_WIDTH-1:0]       axim_awid,
  output logic   [ ADDR_WIDTH-1:0]     axim_awaddr,
  output logic   [ 7:0]                axim_awlen,
  output logic   [ 2:0]                axim_awsize,
  output logic   [ 1:0]                axim_awburst,
  output logic                         axim_awlock,
  output logic   [ 3:0]                axim_awcache,
  output logic   [ 2:0]                axim_awprot,
  output logic   [ 3:0]                axim_awregion,
  output logic   [ 3:0]                axim_awqos,
  output logic                         axim_awvalid,
  input                                axim_awready,
  
  output logic   [ ID_WIDTH-1:0]       axim_wid,
  output logic   [    DATA_WIDTH-1:0]  axim_wdata,
  output logic   [(DATA_WIDTH/8)-1:0]  axim_wstrb,
  output logic                         axim_wlast,
  output logic                         axim_wvalid,
  input                                axim_wready,
                                      
  input          [ ID_WIDTH-1:0]       axim_bid,
  input          [ 1:0]                axim_bresp,
  input                                axim_bvalid,
  output logic                         axim_bready,
                                      
  output logic   [ ID_WIDTH-1:0]       axim_arid,
  output logic   [ ADDR_WIDTH-1:0]     axim_araddr,
  output logic   [ 7:0]                axim_arlen,
  output logic   [ 2:0]                axim_arsize,
  output logic   [ 1:0]                axim_arburst,
  output logic                         axim_arlock,
  output logic   [ 3:0]                axim_arcache,
  output logic   [ 2:0]                axim_arprot,
  output logic   [ 3:0]                axim_arregion,
  output logic   [ 3:0]                axim_arqos,
  output logic                         axim_arvalid,
  input                                axim_arready,   
  
  input          [ ID_WIDTH-1:0]       axim_rid,
  input          [ DATA_WIDTH-1:0]     axim_rdata,
  input          [ 1:0]                axim_rresp,
  input                                axim_rlast,
  input                                axim_rvalid,
  output logic                         axim_rready
);


// Calculate widths based on parameters
localparam AW_TOTAL_WIDTH = ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 + 4;
localparam W_TOTAL_WIDTH  = ID_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 1;
localparam B_TOTAL_WIDTH  = 2+ID_WIDTH;
localparam AR_TOTAL_WIDTH = ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 + 4;
localparam R_TOTAL_WIDTH  = ID_WIDTH + DATA_WIDTH + 2 + 1;

logic [AW_TOTAL_WIDTH-1:0]   aw_concat_di, aw_concat_do;
logic [W_TOTAL_WIDTH-1:0]    w_concat_di,  w_concat_do;
logic [B_TOTAL_WIDTH-1:0]    b_concat_di,  b_concat_do;
logic [AR_TOTAL_WIDTH-1:0]   ar_concat_di, ar_concat_do;
logic [R_TOTAL_WIDTH-1:0]    r_concat_di,  r_concat_do;

//*********************************************************************
//*             Write address channel
//*********************************************************************

assign aw_concat_di = {
    axis_awid,      // ID_WIDTH bits
    axis_awaddr,    // ADDR_WIDTH bits
    axis_awlen,     // 8 bits
    axis_awsize,    // 3 bits
    axis_awburst,   // 2 bits
    axis_awlock,    // 1 bit
    axis_awcache,   // 4 bits
    axis_awprot,    // 3 bits
    axis_awqos,     // 4 bits
    axis_awregion   // 4 bits
};

assign {
    axim_awid,      // ID_WIDTH bits
    axim_awaddr,    // ADDR_WIDTH bits
    axim_awlen,     // 8 bits
    axim_awsize,    // 3 bits
    axim_awburst,   // 2 bits
    axim_awlock,    // 1 bit
    axim_awcache,   // 4 bits
    axim_awprot,    // 3 bits
    axim_awqos,     // 4 bits
    axim_awregion   // 4 bits
} = aw_concat_do;



lio_mb_mcdc #(.DATA_WIDTH(AW_TOTAL_WIDTH)) aw_ch_mcdc
(
  .wr_clk(axis_aclk) ,
  .rd_clk(axim_aclk) ,
  .arstn_wr_clk(axis_arstn),
  .arstn_rd_clk(axim_arstn),
  
  .din(aw_concat_di)  ,
  .not_full(axis_awready) ,
  .wr_en(axis_awvalid),
 
  .dout(aw_concat_do) ,
  .not_empty(axim_awvalid),
  .rd_en(axim_awready)    
);


//*********************************************************************
//*             Write data channel
//*********************************************************************

assign w_concat_di = {
    axis_wid,       // ID_WIDTH bits
    axis_wdata,     // DATA_WIDTH bits
    axis_wstrb,     // DATA_WIDTH/8 bits
    axis_wlast      // 1 bit
};

assign {
    axim_wid,       // ID_WIDTH bits
    axim_wdata,     // DATA_WIDTH bits
    axim_wstrb,     // DATA_WIDTH/8 bits
    axim_wlast      // 1 bit
} = w_concat_do;

lio_mb_mcdc #(.DATA_WIDTH(W_TOTAL_WIDTH)) w_ch_mcdc
(
  .wr_clk(axis_aclk) ,
  .rd_clk(axim_aclk) ,
  
  .arstn_wr_clk(axis_arstn),
  .arstn_rd_clk(axim_arstn),
  
  .din(w_concat_di)  ,
  .not_full(axis_wready) ,
  .wr_en(axis_wvalid),
 
  .dout(w_concat_do) ,
  .not_empty(axim_wvalid),
  .rd_en(axim_wready)    
);

//*********************************************************************
//*             Write resp channel
//*********************************************************************

assign b_concat_di = {
    axim_bid,       // ID_WIDTH bits
    axim_bresp      // 2
};

assign {
    axis_bid,       // ID_WIDTH bits
    axis_bresp      // 2
} = b_concat_do;


lio_mb_mcdc #(.DATA_WIDTH(B_TOTAL_WIDTH)) b_ch_mcdc
(
  .wr_clk(axim_aclk) ,
  .rd_clk(axis_aclk) ,
  .arstn_wr_clk(axim_arstn),
  .arstn_rd_clk(axis_arstn),

  .din(b_concat_di)       ,
  .not_full(axim_bready)     ,
  .wr_en(axim_bvalid)    ,
 
  .dout(b_concat_do)  ,
  .not_empty(axis_bvalid)    ,
  .rd_en(axis_bready)    
);


//*********************************************************************
//*           Read address channel
//*********************************************************************

assign ar_concat_di = {
    axis_arid,      // ID_WIDTH bits
    axis_araddr,    // ADDR_WIDTH bits
    axis_arlen,     // 8 bits
    axis_arsize,    // 3 bits
    axis_arburst,   // 2 bits
    axis_arlock,    // 1 bit
    axis_arcache,   // 4 bits
    axis_arprot,    // 3 bits
    axis_arqos,     // 4 bits
    axis_arregion   // 4 bits
};

assign {
    axim_arid,      // ID_WIDTH bits
    axim_araddr,    // ADDR_WIDTH bits
    axim_arlen,     // 8 bits
    axim_arsize,    // 3 bits
    axim_arburst,   // 2 bits
    axim_arlock,    // 1 bit
    axim_arcache,   // 4 bits
    axim_arprot,    // 3 bits
    axim_arqos,     // 4 bits
    axim_arregion   // 4 bits
} = ar_concat_do;

lio_mb_mcdc #(.DATA_WIDTH(AR_TOTAL_WIDTH)) ar_ch_mcdc
(
  .wr_clk(axis_aclk) ,
  .rd_clk(axim_aclk) ,
  .arstn_wr_clk(axis_arstn),
  .arstn_rd_clk(axim_arstn),
  
  .din(ar_concat_di)  ,
  .not_full(axis_arready) ,
  .wr_en(axis_arvalid),
 
  .dout(ar_concat_do) ,
  .not_empty(axim_arvalid),
  .rd_en(axim_arready)    
);

//*********************************************************************
//*             Read data path
//*********************************************************************

assign r_concat_di = {
    axim_rid,     // ID_WIDTH bits
    axim_rdata,   // DATA_WIDTH bits
    axim_rresp,   // 2 bits
    axim_rlast    // 1 bits
};

assign {
    axis_rid,     // ID_WIDTH bits
    axis_rdata,   // DATA_WIDTH bits
    axis_rresp,   // 2 bits
    axis_rlast    // 1 bits
} = r_concat_do;

lio_mb_mcdc #(.DATA_WIDTH(R_TOTAL_WIDTH)) r_ch_mcdc
(
  .wr_clk(axim_aclk) ,
  .arstn_wr_clk(axim_arstn),
  
  .rd_clk(axis_aclk) ,
  .arstn_rd_clk(axis_arstn),

  .din(r_concat_di)       ,
  .not_full(axim_rready)     ,
  .wr_en(axim_rvalid)    ,
 
  .dout(r_concat_do)  ,
  .not_empty(axis_rvalid)    ,
  .rd_en(axis_rready)    
);

    
endmodule    
    
