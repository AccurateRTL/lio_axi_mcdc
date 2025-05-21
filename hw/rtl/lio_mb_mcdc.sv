// Copyright AccurateRTL contributors.
// Licensed under the MIT License, see LICENSE for details.
// SPDX-License-Identifier: MIT

module lio_mb_mcdc #(
  parameter DATA_WIDTH = 32
)
(
  input                   wr_clk      ,
  input                   rd_clk      ,
  input                   arstn_wr_clk,
  input                   arstn_rd_clk,

  input  [DATA_WIDTH-1:0] din      ,
  output logic            not_full ,
  input                   wr_en    ,
  
  output [DATA_WIDTH-1:0] dout     ,
  output logic            not_empty,
  input                   rd_en    
);

logic                  wr_a, rd_a, wr_a_rclk, rd_a_wclk;
logic [DATA_WIDTH-1:0] data_reg;
logic wr_en_i, rd_en_i;

logic full, empty;

assign not_full   = ~full;
assign not_empty  = ~empty;

assign empty = (wr_a_rclk == rd_a); 
assign full  = (wr_a != rd_a_wclk);

assign wr_en_i = wr_en & (~full);
assign rd_en_i = rd_en & (~empty);

always_ff @(posedge wr_clk or negedge arstn_wr_clk) begin
  if (!arstn_wr_clk) 
     wr_a <= 1'b0;      
  else 
    if (wr_en_i)
      wr_a <= ~wr_a;
end

always_ff @(posedge rd_clk or negedge arstn_rd_clk) begin
  if (!arstn_rd_clk) 
     rd_a <= 1'b0;      
  else begin
    if (rd_en_i)
      rd_a <= ~rd_a;
  end    
end

always_ff @(posedge rd_clk or negedge arstn_rd_clk) begin
  if (!arstn_rd_clk) 
    wr_a_rclk <= 1'b0;      
  else 
    wr_a_rclk <= wr_a;
end

always_ff @(posedge wr_clk or negedge arstn_wr_clk) begin
  if (!arstn_wr_clk) 
    rd_a_wclk <= 1'b0;      
  else 
    rd_a_wclk <= rd_a;
end

always_ff @(posedge wr_clk) begin
  if (wr_en_i)
    data_reg <= din;
end




assign dout = data_reg;



endmodule
