`timescale 1ns/1ps

module memory_bank #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
    input  wire                  clk,
    input  wire                  en,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] wdata,
    output reg  [DATA_WIDTH-1:0] rdata
);

    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (en) begin
            if (we) begin
                mem[addr] <= wdata;
            end else begin
                rdata <= mem[addr];
            end
        end
    end

endmodule
