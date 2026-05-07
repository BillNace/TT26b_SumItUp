/*
 * Copyright (c) 2026 Bill Nace
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_BillNace_SumItUp (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // cloclock
    input  wire       rst_n     // reset_n - low to reset
);

  SumItUp siu(.clock(clk),
              .reset_l(rst_n),
              .go_l(uio_in[0]),
              .inA(ui_in),
              .done(uio_out[1]),
              .sum(uo_out)
             );
             
  assign uio_oe[0] = 1'b0; // go_l is an input
  assign uio_oe[1] = 1'b1; // done is an output

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_oe[7:2] = 6'b0; // All other bidirectional signals are inputs
  assign uio_out[0] = 1'b0;
  assign uio_out[7:1] = 7'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:1], 1'b0};

endmodule : tt_um_BillNace_SumItUp

/*
 * SumItUp is a simple example of a Hardware Thread from Don Thomas'
 * textbook _Logic Design and Verification Using SystemVerilog_.  This example
 * is heavily used in CMU's 18-341 course.
 *
 * The code for this module is a lightly edited version from that textbook.
 */
module SumItUp 
  (input  logic       clock, reset_l, go_l,
   input  logic [7:0] inA,
   output logic       done,
   output logic [7:0] sum);

  logic       ld_l, cl_l, in_A_eq;
  logic [7:0] addOut;
  
  enum bit {sA, sB} state, next_state;

  always_ff @(posedge clock, negedge reset_l) 
    begin: st_machine
    if (~reset_l) 
      state <= sA;
    else
      state <= next_state;
  end: st_machine
  
  always_comb // Next State Logic
    case (state)
      sA : next_state = (go_l) ? sA : sB;
      sB : next_state = (in_A_eq) ? sA : sB;
      default : next_state = sA;
    endcase
    
  always_comb 
    begin: output_logic
      {ld_l, cl_l, done} = 3'b0;
      case (state)
        sA : ld_l = go_l;
        sB : if (in_A_eq) begin
                cl_l = 1'b0;
                done = 1'b1;
             end else
                ld_l = 1'b0;
        default: {ld_l, cl_l, done} = 3'b0;
      endcase
    end: output_logic
    
  always_ff @(posedge clock, negedge reset_l) 
    begin: reg_sum
    if (~reset_l) sum <= '0;
    else if (~ld_l) sum <= addOut;
    else if (~cl_l) sum <= '0;
  end: reg_sum

  assign addOut = inA + sum;
  assign in_A_eq  = (inA == '0);
        
endmodule: SumItUp

