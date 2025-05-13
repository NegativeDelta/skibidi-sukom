/* verilator lint_off UNUSED */
/* verilator lint_off MULTIDRIVEN */
module gpioemu(
    input n_reset,
    input [15:0] saddress,
    input srd,
    input swr,
    input [31:0] sdata_in, // zmienić na 32 bity
    output reg[31:0] sdata_out,
    input [31:0] gpio_in,
    input gpio_latch,
    output reg[31:0] gpio_out,
    input clk,
    output [31:0] gpio_in_s_insp);


reg [31:0] gpio_out_s;
reg [31:0] gpio_in_s;



localparam STATE_BUSY = 0,
           STATE_READ = 1,
           STATE_FULL = 2,
           STATE_READY = 3,
           STATE_ERROR = 4;


localparam brak_instrukcji = 0,
           PUT = 1,
           GET = 2,
           CLR = 3;

localparam POLYNOMIAL = {1'b1, 32'h1EDC6F41};



reg [7:0] IN;
reg [1:0] CTRL;
reg [2:0] STATE;
reg [31:0] result_pom;
wire [31:0] RESULT;

genvar i;
generate for(i=0; i<32; i=i+1) begin 
    assign RESULT[i] = result_pom[32-i-1]; 
end endgenerate

assign gpio_in_s_insp = gpio_in_s;

reg [2031:0] crc_reg; 
reg [7:0] wskaznik_odczyt;
reg [10:0] wskaznik_liczenie; 


always @(posedge swr)begin
    case (saddress)
        16'h0640: begin
            if(sdata_in[31:8] != 24'b0)begin
                STATE <= STATE_ERROR;
            end
            IN[0] <= sdata_in[7];
            IN[1] <= sdata_in[6];
            IN[2] <= sdata_in[5];
            IN[3] <= sdata_in[4];
            IN[4] <= sdata_in[3];
            IN[5] <= sdata_in[2];
            IN[6] <= sdata_in[1];
            IN[7] <= sdata_in[0];
            
        end
        16'h0658: begin
            if(CTRL == brak_instrukcji && (sdata_in >> 2)==0)begin
                CTRL <= sdata_in[1:0];
            end
        end
        default: ;
    endcase
end

always @(posedge srd)begin
    case (saddress)
        16'h0648: begin
            sdata_out <= {29'b0, STATE};
        end
        16'h0650: begin
            if(STATE == STATE_READY)begin
            sdata_out <= RESULT;
            end else begin
            sdata_out <= 32'b0;
            end
        end
        default: sdata_out <= 32'b0;
    endcase
end

always @(negedge n_reset)begin
    IN <= 8'b0;
    CTRL <= 2'b0;
    STATE <= STATE_READ;
    result_pom <= 32'b0;
    crc_reg <= 2032'b0;
    wskaznik_odczyt <= 8'b0;
    wskaznik_liczenie <= 11'b0;
    sdata_out <= 32'b0;
    gpio_in_s <= 0;
    gpio_out <= 0;
end


always @(posedge clk)begin
    case(CTRL)
        PUT:begin
            case(STATE)
                STATE_ERROR:begin
                    CTRL <= 2'b0;
                end
                STATE_READY:begin
                    crc_reg <= {IN, 2024'b0};
                    wskaznik_odczyt <= 1;
                    STATE <= STATE_READ;
                end
                STATE_READ:begin
                    if(wskaznik_odczyt >= 249)begin
                        STATE <= STATE_FULL;
                    end 
                    crc_reg[2031-({wskaznik_odczyt, 3'b0}) -: 8] <= IN;
                    wskaznik_odczyt <= wskaznik_odczyt + 1;
                end
                STATE_FULL:begin
                    STATE <= STATE_ERROR;
                end
                default :;
            endcase
            CTRL <= 2'b0;
        end
        GET:begin
            case(STATE)
                STATE_ERROR:begin
                    CTRL <= 2'b0;
                end
                STATE_READ, STATE_FULL:begin
                    STATE <= STATE_BUSY;
                    wskaznik_liczenie <= 11'b0;
                    crc_reg[2031 -: 32] <= crc_reg[2031 -: 32] ^ 32'hffffffff;
                end
                STATE_FULL,
                STATE_BUSY:begin
                    if (crc_reg[2031-wskaznik_liczenie] && wskaznik_liczenie < {wskaznik_odczyt, 3'b0}) begin
                        crc_reg[2031-wskaznik_liczenie -: 33] <= crc_reg[2031-wskaznik_liczenie -: 33] ^ POLYNOMIAL;
                    end

                    // koniec liczenia
                    if(wskaznik_liczenie == {wskaznik_odczyt, 3'b0})begin
                        result_pom <= ((crc_reg[2031-wskaznik_liczenie -: 32]) ^ 32'hffffffff);
                    end
                    if(wskaznik_liczenie-1 == {wskaznik_odczyt, 3'b0})begin
                        STATE <= STATE_READY;
                        CTRL <= 2'b0;
                        wskaznik_liczenie <= 11'b0;
                    end
                    wskaznik_liczenie <= wskaznik_liczenie + 1;
                end
                default :;
            endcase
        end
        CLR:begin
            IN <= 8'b0;
            CTRL <= 2'b0;
            result_pom <= 32'b0;
            crc_reg <= 2032'b0;
            wskaznik_odczyt <= 8'b0;
            wskaznik_liczenie <= 11'b0;
            sdata_out <= 32'b0;
            STATE <= STATE_READ;
            CTRL <= 2'b0;
        end
    endcase
end
endmodule 