//-----------------------------------------------------------------------------
//
// FPGA Colecovision
//
// $Id: cv_addr_dec.vhd,v 1.3 2006/01/05 22:22:29 arnim Exp $
//
// Address Decoder
//
//-----------------------------------------------------------------------------
//
// Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
// SystemVerilog conversion (c) 2022 Frank Bruno (fbruno@asicsolutions.com)
//
//-----------------------------------------------------------------------------

module cv_addr_dec
  (
   input              clk_i,
   input              reset_n_i,
   input              sg1000,
   input              dahjeeA_i,
   input [15:0]       a_i,
   input [7:0]        d_i,
   input [5:0]        cart_pages_i,
   output logic [5:0] cart_page_o,
   input              iorq_n_i,
   input              rd_n_i,
   input              wr_n_i,
   input              mreq_n_i,
   input              rfsh_n_i,
   output logic       bios_rom_ce_n_o,
   output logic       eos_rom_ce_n_o,
   output logic       writer_rom_ce_n_o,
   output logic       ram_ce_n_o,
   output logic       upper_ram_ce_n_o,
   output logic       expansion_ram_ce_n_o,
   output logic       expansion_rom_ce_n_o, 
   output logic       vdp_r_n_o,
   output logic       vdp_w_n_o,
   output logic       psg_we_n_o,
   output logic       ay_addr_we_n_o,
   output logic       ay_data_we_n_o,
   output logic       ay_data_rd_n_o,
   output logic       ctrl_r_n_o,
   output logic       ctrl_en_key_n_o,
   output logic       ctrl_en_joy_n_o,
   output logic       cart_en_80_n_o,
   output logic       cart_en_a0_n_o,
   output logic       cart_en_c0_n_o,
   output logic       cart_en_e0_n_o,
   output logic       cart_en_sg1000_n_o
   );

  logic               megacart_en;
  logic [5:0]         megacart_page;
  logic               bios_en;
  logic               eos_en;
  logic [1:0]         lower_mem;
  logic [1:0]         upper_mem;
/*
always @(posedge clk_i)
begin
    if (mreq_n_i && rfsh_n_i && ~iorq_n_i && (~rd_n_i | ~wr_n_i)) begin
      //$display("writer_rom_ce_n_o %x rd_n_i %x wr_n_i", writer_rom_ce_n_o,rd_n_i,wr_n_i);
      if (~wr_n_i) $display("OutZ80(%x,%x)",a_i[7:0],d_i);
      if (~rd_n_i) $display("InZ80(%x)",a_i[7:0]);
	$display("upper mem %x lower mem %x",upper_mem,lower_mem);
    end
//$display(" addr(%x) bios_rom_ce_n_o  %x eos_rom_ce_n_o  %x writer_rom_ce_n_o %x ram_ce_n_o  %x upper_ram_ce_n_o  %x ",a_i, bios_rom_ce_n_o    , eos_rom_ce_n_o    , writer_rom_ce_n_o, ram_ce_n_o      , upper_ram_ce_n_o   );


end
*/

  //---------------------------------------------------------------------------
  // Process dec
  //
  // Purpose:
  //   Implements the address decoding logic.
  //
  always_comb begin : dec
    // default assignments
    bios_rom_ce_n_o    = '1;
    eos_rom_ce_n_o     = '1;
    writer_rom_ce_n_o  = '1;
    eos_rom_ce_n_o  = '1;
    ram_ce_n_o         = '1;
    upper_ram_ce_n_o   = '1;
    expansion_ram_ce_n_o='1;
    expansion_rom_ce_n_o='1;
    vdp_r_n_o          = '1;
    vdp_w_n_o          = '1;
    psg_we_n_o         = '1;
    ay_addr_we_n_o     = '1;
    ay_data_we_n_o     = '1;
    ay_data_rd_n_o     = '1;
    ctrl_r_n_o         = '1;
    ctrl_en_key_n_o    = '1;
    ctrl_en_joy_n_o    = '1;
    cart_en_80_n_o     = '1;
    cart_en_a0_n_o     = '1;
    cart_en_c0_n_o     = '1;
    cart_en_e0_n_o     = '1;
    cart_en_sg1000_n_o = '1;

    //  64k
    // 128k
    // 256k
    // 512k
    megacart_en = ~sg1000 &
                  (cart_pages_i == 6'b000011 |
                   cart_pages_i == 6'b000111 |
                   cart_pages_i == 6'b001111 |
                   cart_pages_i == 6'b011111 |
                   cart_pages_i == 6'b111111);		// 1M

    // Paging
    case (a_i[15:14])
      2'b10: begin
        if (megacart_en == 1'b1) cart_page_o = cart_pages_i;
        else                     cart_page_o = '0;
      end
      2'b11: begin
        if (megacart_en)         cart_page_o = megacart_page;
        else                     cart_page_o = 6'b000001;
      end
      default:                   cart_page_o = 6'b000000;
    endcase

    // Memory access ----------------------------------------------------------
    if (~mreq_n_i && rfsh_n_i) begin
      if (sg1000) begin
        if (a_i[15:14] == 2'b11) begin                          // c000 - ffff
          ram_ce_n_o = '0;
        end else if ((a_i[15:13] == 3'b001) && (dahjeeA_i == 1'b1)) begin // 2000 - 3fff
          ram_ce_n_o = '0;
        end else begin
          cart_en_sg1000_n_o = '0;
        end
      end else begin
        if (~a_i[15])
        begin
        if (lower_mem == 2'b11) begin  // OS7 / 24k RAM
          case (a_i[15:13])
          3'b000: bios_rom_ce_n_o = '0;
          3'b001, 3'b010, 3'b011: ram_ce_n_o     = '0;	// 2000 - 7fff = 24k
          endcase
        end
        else if (lower_mem == 2'b10) begin // RAM expansion
        end
        else if (lower_mem == 2'b01) begin // 32K of RAM
          ram_ce_n_o     = '0;	// 2000 - 7fff = 24k
        end
        else if (lower_mem == 2'b00) begin // WRITER ROM (when do we use EOS?)
          if (eos_en) 
             eos_rom_ce_n_o ='0;
          else
             writer_rom_ce_n_o ='0;
        end
        end
	if (a_i[15])
        begin
        if (upper_mem == 2'b11) begin  // cartridge ROM
          case (a_i[15:13])
          3'b100:                 cart_en_80_n_o = '0;
          3'b101:                 cart_en_a0_n_o = '0;
          3'b110:                 cart_en_c0_n_o = '0;
          3'b111:                 cart_en_e0_n_o = '0;
          endcase
        end
        else if (upper_mem == 2'b10) begin // RAM expansion
            expansion_ram_ce_n_o='0;
        end
        else if (upper_mem == 2'b01) begin // ROM expansion
            expansion_rom_ce_n_o='0;
        end
        else if (upper_mem == 2'b00) begin // 32k RAM
              upper_ram_ce_n_o ='0;
        end
        end
      end // else: !if(sg1000)
    end

    // I/O access -------------------------------------------------------------
    if (~iorq_n_i) begin
      if (~sg1000 && a_i[7]) begin
        case ({a_i[6], a_i[5], wr_n_i})
          3'b000: ctrl_en_key_n_o = '0;
          3'b010: vdp_w_n_o = '0;
          3'b011: if (~rd_n_i) vdp_r_n_o = '0;
          3'b100: ctrl_en_joy_n_o = '0;
          3'b110: psg_we_n_o = '0;
          3'b111: if (~rd_n_i) ctrl_r_n_o = '0;
        endcase
      end

      if (sg1000) begin
        case ({a_i[7], a_i[6], wr_n_i})
          3'b010: psg_we_n_o = '0;
          3'b100: vdp_w_n_o = '0;
          3'b101: if (~rd_n_i) vdp_r_n_o = '0;
          3'b111: if (~rd_n_i) ctrl_r_n_o = '0;
        endcase
      end

      if      (a_i[7:0] == 8'h50 && ~wr_n_i) ay_addr_we_n_o = '0;
      else if (a_i[7:0] == 8'h51 && ~wr_n_i) ay_data_we_n_o = '0;
      else if (a_i[7:0] == 8'h52 && ~rd_n_i) ay_data_rd_n_o = '0;
    end
  end

  //
  //---------------------------------------------------------------------------
  always @(negedge reset_n_i, posedge clk_i) begin : megacart
    if (~reset_n_i) begin
      megacart_page <= '0;
      bios_en       <= '1;
      eos_en       <= '0;
      lower_mem     <= 2'b00;  // computer mode
      upper_mem     <= 2'b00;
      //lower_mem     <= 2'b11;
      //upper_mem     <= 2'b11;
    end else begin
      // MegaCart paging
      if (megacart_en && rfsh_n_i && ~mreq_n_i && ~rd_n_i && (a_i[15:6] == {8'hFF, 2'b11}))
        megacart_page <= a_i[5:0] & cart_pages_i;

      // SGM BIOS enable/disable
      if (sg1000)
        bios_en <= '0;
      else if (~iorq_n_i && mreq_n_i && rfsh_n_i && ~wr_n_i && (a_i[7:0] == 8'h7f))
        bios_en <= d_i[1];

	// just 7F or all addresses?
      if (~iorq_n_i && mreq_n_i && rfsh_n_i && ~wr_n_i && (a_i[7:0] == 8'h3f))
	eos_en <= d_i[1];
      if (~iorq_n_i && mreq_n_i && rfsh_n_i && ~wr_n_i && (a_i[7:0] == 8'h7f))
      begin
		//$display("CHANGING MEM 7f");
	      lower_mem <= d_i[1:0];
	      upper_mem <= d_i[3:2];
      end
    end
  end

endmodule
