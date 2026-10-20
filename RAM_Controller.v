`timescale 1ns/1ps

module RAM_Controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 6,
    parameter NUM_BANKS  = 4
)(
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  req,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] wdata,

    output reg  [DATA_WIDTH-1:0] rdata,
    output reg                   ready,
    output reg                   error
);

    localparam BANK_BITS = $clog2(NUM_BANKS);
    localparam WORD_ADDR_WIDTH = ADDR_WIDTH - 2;
    localparam BANK_ADDR_WIDTH =
        WORD_ADDR_WIDTH - BANK_BITS;

    localparam IDLE = 1'b0;
    localparam WAIT_READ = 1'b1;

    reg state;

    reg [DATA_WIDTH-1:0] bank_rdata [0:NUM_BANKS-1];

    reg [NUM_BANKS-1:0] bank_en;
    reg [NUM_BANKS-1:0] bank_we;

    reg [BANK_BITS-1:0] selected_bank;
    reg [BANK_ADDR_WIDTH-1:0] selected_addr;

    wire [BANK_BITS-1:0] decoded_bank;
    wire [BANK_ADDR_WIDTH-1:0] decoded_addr;

    integer i;

    // Byte address -> word address -> bank and local address.
    assign decoded_bank =
        addr[2 +: BANK_BITS];

    assign decoded_addr =
        addr[ADDR_WIDTH-1:2+ BANK_BITS];

    // The address configuration assumes:
    // NUM_BANKS is a power of two and
    // ADDR_WIDTH > BANK_BITS + 2.

    always @(*) begin
        bank_en = {NUM_BANKS{1'b0}};
        bank_we = {NUM_BANKS{1'b0}};

        if (req && state == IDLE &&
            decoded_bank < NUM_BANKS) begin
            bank_en[decoded_bank] = 1'b1;
            bank_we[decoded_bank] = we;
        end
    end

    genvar b;
    generate
        for (b = 0; b < NUM_BANKS; b = b + 1) begin : BANKS
            memory_bank #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(BANK_ADDR_WIDTH)
            ) bank_inst (
                .clk(clk),
                .en(bank_en[b]),
                .we(bank_we[b]),
                .addr(decoded_addr),
                .wdata(wdata),
                .rdata(bank_rdata[b])
            );
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= IDLE;
            ready          <= 1'b0;
            error          <= 1'b0;
            rdata          <= {DATA_WIDTH{1'b0}};
            selected_bank  <= {BANK_BITS{1'b0}};
            selected_addr  <= {BANK_ADDR_WIDTH{1'b0}};
        end else begin
            ready <= 1'b0;
            error <= 1'b0;

            case (state)
                IDLE: begin
                    if (req) begin
                        if (decoded_bank < NUM_BANKS) begin
                            selected_bank <= decoded_bank;
                            selected_addr <= decoded_addr;

                            if (we) begin
                                ready <= 1'b1;
                            end else begin
                                state <= WAIT_READ;
                            end
                        end else begin
                            error <= 1'b1;
                            ready <= 1'b1;
                        end
                    end
                end

                WAIT_READ: begin
                    rdata <= bank_rdata[selected_bank];
                    ready <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    error <= 1'b1;
                end
            endcase
        end
    end

endmodule
