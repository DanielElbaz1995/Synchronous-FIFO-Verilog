`timescale 1us/1ns
module tb_fifo_sync();
	parameter FIFO_DEPTH = 8;
	parameter DATA_WIDTH = 32;
	reg clk = 0;
	reg rst_n;
	reg cs;
	reg wr_en;
	reg rd_en;
	reg [DATA_WIDTH-1:0] data_in;
	wire [DATA_WIDTH-1:0] data_out;
	wire empty;
	wire full;
	
	integer i;
	integer errors = 0;
	
	fifo_sync
		#(.FIFO_DEPTH(FIFO_DEPTH),
		  .DATA_WIDTH(DATA_WIDTH))
		FIFO0
		(.clk     (clk     ),
		 .rst_n   (rst_n   ),
		 .cs      (cs      ),
		 .wr_en   (wr_en   ),
		 .rd_en   (rd_en   ),
		 .data_in (data_in ),
		 .data_out(data_out),
		 .empty   (empty   ),
		 .full    (full    ));
		 
	task write_data(input [DATA_WIDTH-1:0] d_in);
		begin
			@(posedge clk);
			cs = 1; wr_en = 1;
			data_in = d_in;
			$display($time, " write_data data_in = %0d", data_in);
			@(posedge clk);
			cs = 1; wr_en = 0;
		end
	endtask
	
	task read_and_check(input [DATA_WIDTH-1:0] expected_data);
        begin
            @(posedge clk);
            cs = 1; rd_en = 1;
            @(posedge clk);
			@(posedge clk);
            if (data_out !== expected_data) begin
                $display("TIME: %t | ERROR: Got %h, Expected %h", $time, data_out, expected_data);
                errors = errors + 1;
            end else begin
                $display("TIME: %t | SUCCESS: Read %h", $time, data_out);
            end
            rd_en = 0;
        end
    endtask
	
	always begin #0.5 clk = ~clk; end // Clock Signal
	
	initial begin	
		rst_n = 0; cs = 0; rd_en = 0; wr_en = 0; data_in = 0;
		#2;
		rst_n = 1; cs = 1;
		$display("\n--- SCENARIO 1: Basic Write/Read ---");
        write_data(32'hAAAA);
        write_data(32'hBBBB);
        read_and_check(32'hAAAA);
        read_and_check(32'hBBBB);
        
        $display("\n--- SCENARIO 2: Fill to Full and Overflow Protection ---");
        for (i=0; i<FIFO_DEPTH; i=i+1) begin
            write_data(i + 1);
        end
        
        if (full) $display("Status: FIFO is FULL as expected.");
        
        // Write to full FIFO
        write_data(32'hFFFF); 
        
        $display("\n--- SCENARIO 3: Emptying and Self-Checking ---");
        for (i=0; i<FIFO_DEPTH; i=i+1) begin
            read_and_check(i + 1);
        end
        
        if (empty) $display("Status: FIFO is EMPTY as expected.");

        // Summary
        $display("\n--- TEST SUMMARY ---");
        if (errors == 0)
            $display("RESULT: ALL TESTS PASSED!");
        else
            $display("RESULT: TEST FAILED WITH %0d ERRORS.", errors);
     
        #10;
	end
endmodule