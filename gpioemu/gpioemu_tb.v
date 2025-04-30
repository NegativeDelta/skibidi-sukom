module gpioemu_tb;

reg n_reset;
reg [15:0] saddress;
reg srd;
reg swr;
reg [31:0] sdata_in;
wire [31:0] sdata_out;
reg [31:0] gpio_in;
reg gpio_latch;
wire [31:0] gpio_out;
reg clk;
wire [31:0] gpio_in_s_insp;

gpioemu test(
        .n_reset(n_reset),
        .saddress(saddress),
        .srd(srd),
        .swr(swr),
        .sdata_in(sdata_in),
        .sdata_out(sdata_out),
        .gpio_in(gpio_in),
        .gpio_latch(gpio_latch),
        .gpio_out(gpio_out),
        .clk(clk),
        .gpio_in_s_insp(gpio_in_s_insp)
);
initial begin
    $dumpfile("gpioemu.vcd");
    $dumpvars(0, gpioemu_tb);
end

initial begin
    clk <= 0;
    forever #5 clk <= ~clk;
end

task PUT();begin
    #5 saddress <= 16'h0658;
    #5 sdata_in <= 2'b01;
    #5 swr <= 1'b1;
    #5 swr <= 1'b0;
    end 
endtask

task GET();begin
    #5 saddress <= 16'h0658;
    #5 sdata_in <= 2'b10;
    #5 swr <= 1'b1;
    #5 swr <= 1'b0;
    end 
endtask

task CLR();begin
    #5 saddress <= 16'h0658;
    #5 sdata_in <= 2'b11;
    #5 swr <= 1'b1;
    #5 swr <= 1'b0;
    end 
endtask

task wpisz_do_pamieci(input [7:0] val);begin

    // wpisz do pamięci
    #5 saddress <= 16'h0640;
    #5 sdata_in <= val;
    #5 swr <= 1'b1;
    #5 swr <= 1'b0;

    PUT();
    end
endtask

task wait_for_RDY();begin
    #5 saddress <= 16'h0648;
    while(sdata_out != 32'h00000003)begin
        #5 srd <= 1'b1;
        #5 srd <= 1'b0;
    end
    end
endtask

initial begin
srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;


// test obliczania crc ciągu 0x12345678
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h34);
    #5 wpisz_do_pamieci(8'h56);
    #5 wpisz_do_pamieci(8'h78);
    GET();
    wait_for_RDY();
    #5 saddress <= 16'h0650;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("CRC32C ciagu 0x12345678: %0h (poprawna 4300918a)", sdata_out);

// test obliczania crc ciągu bez CLR
    #5 wpisz_do_pamieci(8'h22);
    #5 wpisz_do_pamieci(8'h34);
    #5 wpisz_do_pamieci(8'h56);
    #5 wpisz_do_pamieci(8'h78);
    GET();
    wait_for_RDY();
    #5 saddress <= 16'h0650;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("CRC32C ciagu 0x22345678 bez resetu: %0h (poprawna 7d41343c)", sdata_out);

// test CLR
    CLR();
    #5 saddress <= 16'h0650;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("rejestr RESULT po resecie: %0h", sdata_out);
    #5 saddress <= 16'h0648;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("STATE po resecie: %0h", sdata_out);

// test obliczania crc ciągu 0x34345678 po CLR
    #5 wpisz_do_pamieci(8'h34);
    #5 wpisz_do_pamieci(8'h34);
    #5 wpisz_do_pamieci(8'h56);
    #5 wpisz_do_pamieci(8'h78);
    GET();
    wait_for_RDY();
    #5 saddress <= 16'h0650;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("CRC32C ciagu 0x34345678 po resecie: %0h (poprawna 50609773)", sdata_out);

// test czyszczenia bufora inputu
    #5 wpisz_do_pamieci(8'hAA);
    #5 wpisz_do_pamieci(8'hAA);
    #5 wpisz_do_pamieci(8'hAA);
    CLR();
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h34);
    #5 wpisz_do_pamieci(8'h56);
    #5 wpisz_do_pamieci(8'h78);
    GET();
    wait_for_RDY();
    #5 saddress <= 16'h0650;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("CRC32C ciagu 0x12345678 po wyczyszczeniu inputu: %0h (poprawna 4300918a)", sdata_out);

// test sprawdzania zajętości bufora
    for (integer i = 0; i < 249; i = i + 1) begin
    			#5 wpisz_do_pamieci(8'h66);     
    end
    #5 saddress <= 16'h0648;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("STATE po wprowadzeniu 249 bajtow: %0h", sdata_out);
    #5 wpisz_do_pamieci(8'h66);
    #5 saddress <= 16'h0648;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("STATE po wprowadzeniu 250 bajtow: %0h", sdata_out);

    #5 GET();
    wait_for_RDY();
    #5 saddress <= 16'h0650;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    #100 $display("CRC32C ciagu 250 bajtow 0x66: %0h (poprawna fe2a715f)" , sdata_out);

// test sprawdzania zabezpieczenia przed przepełnieniem bufora
    for (integer i = 0; i < 250; i = i + 1) begin
    			#5 wpisz_do_pamieci(8'h66);     
    end
    #5 wpisz_do_pamieci(8'h23);
    #5 wpisz_do_pamieci(8'h23);
    #5 wpisz_do_pamieci(8'h53);
    #5 wpisz_do_pamieci(8'h87);
    #5 wpisz_do_pamieci(8'h19);
    #5 saddress <= 16'h0648;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("STATE po wprowadzeniu ponad 250 bajtow: %0h", sdata_out);

    #5 GET();
    wait_for_RDY();
    #5 saddress <= 16'h0650;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    #100 $display("CRC32C ciagu 250 bajtow 0x66: %0h  (poprawna fe2a715f)", sdata_out);

// test crc pustego bufora po CLR
    CLR();
    GET();
    #5 saddress <= 16'h0650;
        #5 srd <= 1'b1;
        #5 srd <= 1'b0;
        #100 $display("CRC32C pustego rejestru po CLR: %0h (poprawna 0)" , sdata_out);

// test crc pustego bufora po resecie
    n_reset <= 0;
    #5 n_reset <= 1;
    #10 GET();
    #5 saddress <= 16'h0650;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    #100 $display("CRC32C pustego rejestru po resecie: %0h (poprawna 0)" , sdata_out);





// // podaj na pamięć
// #5 saddress <= 16'h0640;
// #5 sdata_in <= 8'hAB;
// #5 swr <= 1'b1;
// #5 swr <= 1'b0;
// 
// // instrukcja PUT
// #5 saddress <= 16'h0658;
// #5 sdata_in <= 2'b01;
// #5 swr <= 1'b1;
// #5 swr <= 1'b0;


#100 $finish;






end
endmodule 