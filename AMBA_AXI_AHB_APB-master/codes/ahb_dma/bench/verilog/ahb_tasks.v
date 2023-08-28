//`ifndef AHB_TASKS_V
//`define AHB_TASKS_V
/*********************************************************
 * Copyright (c) 2010 by Ando Ki.
 * All right reserved.
 *
 * http://www.dynalith.com
 * adki@dynalith.com
 *********************************************************
 */

   /*********************************************************/
   task ahb_read;
        input  [31:0] address;
        input  [2:0]  size;
        output [31:0] data;
        begin
            @ (posedge HCLK);
            HBUSREQ <= #1 1;
            @ (negedge HCLK);
            while (HREADY==1'b0 || HGRANT==1'b0) @ (posedge HCLK);
            HBUSREQ <= #1 0;

            HADDR  <= #1 address;
            HTRANS <= #1 2'b10; // `HTRANS_NONSEQ
            HBURST <= #1 3'b000; // `HBURST_SINGLE;
            HWRITE <= #1 1'b0; // `HWRITE_READ
            case (size)
            1:  HSIZE <= #1 3'b000;// `HSIZE_BYTE;
            2:  HSIZE <= #1 3'b001;// `HSIZE_HWORD;
            4:  HSIZE <= #1 3'b010;// `HSIZE_WORD;
            default: begin
$display($time,, "ERROR: unsupported transfer size: %d-byte", size);
                     end
            endcase
            @ (posedge HCLK);
            while (HREADY==1'b0) @ (posedge HCLK);
            HADDR  <= #1 ~0;
            HTRANS <= #1 0;
            HBURST <= #1 0;
            HWRITE <= #1 0;
            HSIZE  <= #1 0;
            @ (posedge HCLK);
            while (HREADY==0) @ (posedge HCLK);
            data = HRDATA; // must be blocking
            if (HRESP!=2'b00) begin //`HRESP_OKAY
$display($time,, "ERROR: non OK response for ahb_read");
            end
`ifdef DEBUG
$display($time,, "INFO: ahb_read(%x, %d, %x)", address, size, data);
`endif
            @ (posedge HCLK);
        end
   endtask

   /*********************************************************/
   task ahb_write;
        input  [31:0] address;
        input  [2:0]  size;
        input  [31:0] data;
        begin
            @ (posedge HCLK);
            HBUSREQ <= #1 1;
            @ (negedge HCLK);
            while (HREADY==1'b0 || HGRANT==1'b0) @ (posedge HCLK);
            HBUSREQ <= #1 0;

            HADDR  <= #1 address;
            HTRANS <= #1 2'b10; // `HTRANS_NONSEQ
            HBURST <= #1 3'b000; // `HBURST_SINGLE;
            HWRITE <= #1 1'b1; //`HWRITE_WRITE;
            case (size)
            1:  HSIZE <= #1 3'b000;//`HSIZE_BYTE;
            2:  HSIZE <= #1 3'b001;//`HSIZE_HWORD;
            4:  HSIZE <= #1 3'b010;//`HSIZE_WORD;
            default: begin
$display($time,, "ERROR: unsupported transfer size: %d-byte", size);
                     end
            endcase
            @ (posedge HCLK);
            while (HREADY==1'b0) @ (posedge HCLK);
            HADDR  <= #1 ~0;
            HTRANS <= #1 0;
            HBURST <= #1 0;
            HWRITE <= #1 0;
            HSIZE  <= #1 0;
            HWDATA <= #1 data;
            @ (posedge HCLK);
            while (HREADY==0) @ (posedge HCLK);
            if (HRESP!=2'b00) begin //`HRESP_OKAY
$display($time,, "ERROR: non OK response ahb_write");
            end
`ifdef DEBUG
$display($time,, "INFO: ahb_write(%x, %d, %x)", address, size, data);
`endif
            HWDATA <= #1 0;
            @ (posedge HCLK);
        end
   endtask
   /*********************************************************/
   task ahb_read_burst;
        input  [31:0] addr;
        input  [31:0] leng;
        integer       i;
        begin
            @ (posedge HCLK);
            HBUSREQ <= #1 1;
            @ (negedge HCLK);
            while (HREADY==1'b0 || HGRANT==1'b0) @ (posedge HCLK);

            HADDR  <= #1 addr;
            HTRANS <= #1 2'b10; // `HTRANS_NONSEQ
            if (leng==4)       HBURST <= #1 3'b011;// `HBURST_INCR4;
            else if (leng==8)  HBURST <= #1 3'b101;// `HBURST_INCR8;
            else if (leng==16) HBURST <= #1 3'b110;// `HBURST_INCR16;
            else               HBURST <= #1 3'b001;// `HBURST_INCR;
            HWRITE <= #1 1'b0; // `HWRITE_READ
            HSIZE  <= #1 3'b010; //`HSIZE_WORD;
            @ (posedge HCLK);
            while (HREADY==1'b0) @ (posedge HCLK);
            for (i=0; i<leng-1; i=i+1) begin
                HADDR  <= #1 addr+(i+1)*4;
                HTRANS <= #1 2'b11; //`HTRANS_SEQ;
                @ (posedge HCLK);
                while (HREADY==1'b0) @ (posedge HCLK);
                data_burst_rd[i%1024] = HRDATA; // must be blocking
            end
            HBUSREQ <= #1 0;
            HADDR  <= #1 ~0;
            HTRANS <= #1 0;
            HBURST <= #1 0;
            HWRITE <= #1 0;
            HSIZE  <= #1 0;
            @ (posedge HCLK);
            while (HREADY==0) @ (posedge HCLK);
            data_burst_rd[i%1024] = HRDATA; // must be blocking
            if (HRESP!=2'b00) begin //`HRESP_OKAY
$display($time,, "ERROR: non OK response for ahb_read_burst");
            end
`ifdef DEBUG
$display($time,, "INFO: ahb_read_burst(%x)", addr);
`endif
            @ (posedge HCLK);
        end
   endtask
   /*********************************************************/
   task ahb_write_burst;
        input  [31:0] addr;
        input  [31:0] leng;
        integer       i;
        begin
            @ (posedge HCLK);
            HBUSREQ <= #1 1;
            @ (negedge HCLK);
            while (HREADY==1'b0 || HGRANT==1'b0) @ (posedge HCLK);

            HADDR  <= #1 addr;
            HTRANS <= #1 2'b10; // `HTRANS_NONSEQ
            if (leng==4)       HBURST <= #1 3'b011;//`HBURST_INCR4;
            else if (leng==8)  HBURST <= #1 3'b101;//`HBURST_INCR8;
            else if (leng==16) HBURST <= #1 3'b110;//`HBURST_INCR16;
            else               HBURST <= #1 3'b001;//`HBURST_INCR;
            HWRITE <= #1 1'b1; //`HWRITE_WRITE;
            HSIZE  <= #1 3'b010; //`HSIZE_WORD;
            for (i=0; i<leng-1; i=i+1) begin
                @ (posedge HCLK);
                while (HREADY==1'b0) @ (posedge HCLK);
                HWDATA <= #1 data_burst_wr[i%1024];
                HADDR  <= #1 addr+(i+1)*4;
                HTRANS <= #1 2'b11; //`HTRANS_SEQ;
                while (HREADY==1'b0) @ (posedge HCLK);
            end
            @ (posedge HCLK);
            while (HREADY==0) @ (posedge HCLK);
            HWDATA <= #1 data_burst_wr[i%1024];
            HBUSREQ <= #1 0;
            HADDR  <= #1 ~0;
            HTRANS <= #1 0;
            HBURST <= #1 0;
            HWRITE <= #1 0;
            HSIZE  <= #1 0;
            @ (posedge HCLK);
            while (HREADY==0) @ (posedge HCLK);
            if (HRESP!=2'b00) begin //`HRESP_OKAY
$display($time,, "ERROR: non OK response ahb_write_burst");
            end
`ifdef DEBUG
$display($time,, "INFO: ahb_write_burst(%x)", addr);
`endif
            HWDATA <= #1 0;
            @ (posedge HCLK);
        end
   endtask

//---------------------------------------------------
// 2010.07.24.: HBUSREQ/HGRANT added.
//              HSEL removed.
//---------------------------------------------------
//`endif
