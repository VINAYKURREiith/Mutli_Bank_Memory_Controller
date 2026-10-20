`timescale 1ns/1ps

module tb_RAM_Controller;

    reg clk = 0;
    reg rst_n = 0;

    reg req = 0;
    reg we = 0;
    reg [5:0] addr = 0;
    reg [31:0] wdata = 0;

    wire [31:0] rdata;
    wire ready;
    wire error;

    integer errors = 0;

    always #5 clk = ~clk;

    RAM_Controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .ready(ready),
        .error(error)
    );

    task write_word;
        input [5:0] address;
        input [31:0] data;
        begin
            @(negedge clk);
            req   = 1;
            we    = 1;
            addr  = address;
            wdata = data;

            @(negedge clk);
            req = 0;
            we  = 0;

            repeat (2) @(negedge clk);
        end
    endtask

    task read_word;
        input [5:0] address;
        input [31:0] expected;
        integer timeout;
        begin
            @(negedge clk);
            req  = 1;
            we   = 0;
            addr = address;

            @(negedge clk);
            req = 0;

            timeout = 0;
            while (ready !== 1'b1 && timeout < 10) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 10) begin
                $display("[FAIL] Read timeout at address %h", address);
                errors = errors + 1;
            end else if (error !== 1'b0) begin
                $display("[FAIL] Read error at address %h", address);
                errors = errors + 1;
            end else if (rdata !== expected) begin
                $display("[FAIL] Address=%h Expected=%h Received=%h",
                         address, expected, rdata);
                errors = errors + 1;
            end else begin
                $display("[PASS] Address=%h Data=%h",
                         address, rdata);
            end
        end
    endtask

    initial begin
        $dumpfile("memory_controller.vcd");
        $dumpvars(0, tb_RAM_Controller);

        repeat (3) @(negedge clk);
        rst_n = 1;

        // Bank 0
        write_word(6'h00, 32'h12345678);
        read_word(6'h00, 32'h12345678);

        // Bank 1
        write_word(6'h04, 32'hA5A5A5A5);
        read_word(6'h04, 32'hA5A5A5A5);

        // Bank 2
        write_word(6'h08, 32'hDEADBEEF);
        read_word(6'h08, 32'hDEADBEEF);

        // Bank 3
        write_word(6'h0C, 32'hCAFEBABE);
        read_word(6'h0C, 32'hCAFEBABE);

        $display("--------------------------------");
        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);
        $display("--------------------------------");

        $finish;
    end

endmodule
