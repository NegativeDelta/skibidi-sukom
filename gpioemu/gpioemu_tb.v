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

task wpisz_do_pamieci(input [31:0] val);begin

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
    while(sdata_out != 32'h00000003 && sdata_out != 32'h00000004)begin
        #5 srd <= 1'b1;
        #5 srd <= 1'b0;
    end
    end
endtask

task print_state();begin
    #5 saddress <= 16'h0648;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("STATE: %0h", sdata_out);
end
endtask

task print_result();begin
    #5 saddress <= 16'h0650;
    #5 srd <= 1'b1;
    #5 srd <= 1'b0;
    $display("Wynik: %0h", sdata_out);
end
endtask

initial begin
srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

// TEST 1a
    $display("\nTest 1. a)");
    #5 wpisz_do_pamieci(8'h11);

    #100

srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

// TEST 1b
    $display("\nTest 1. b)");
    #5 wpisz_do_pamieci(8'h11);
    #5 wpisz_do_pamieci(8'h22);
    #100

srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

// TEST 1c
    $display("\nTest 1. c)");
    for (integer i = 0; i < 249; i = i + 1) begin
    			#5 wpisz_do_pamieci(8'h11);
    end
    print_state();
    $display("Oczekiwany: 1");
    #100

// TEST 1d
    $display("\nTest 1. d)");
    #5 wpisz_do_pamieci(8'h11);
    print_state();
    $display("Oczekiwany: 2");

// TEST 1e
    $display("\nTest 1. e)");
    #5 wpisz_do_pamieci(8'h11);
    print_state();
    $display("Oczekiwany: 4");

srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

// TEST 1f
    $display("\nTest 1. f)");
    #5 wpisz_do_pamieci(9'h100);
    print_state();
    $display("Oczekiwany: 4");

srd <= 0;
swr <= 0;
CLR();


// TEST 2a
    $display("\nTest 2. a)");
    #5 wpisz_do_pamieci(8'h11);

    #100

srd <= 0;
swr <= 0;
CLR();

// TEST 2b
    $display("\nTest 2. b)");
    #5 wpisz_do_pamieci(8'h11);
    #5 wpisz_do_pamieci(8'h22);
    #100

srd <= 0;
swr <= 0;
CLR();

// TEST 2c
    $display("\nTest 2. c)");
    for (integer i = 0; i < 249; i = i + 1) begin
    			#5 wpisz_do_pamieci(8'h11);
    end
    print_state();
    $display("Oczekiwany: 1");
    #100

// TEST 2d
    $display("\nTest 2. d)");
    #5 wpisz_do_pamieci(8'h11);
    print_state();
    $display("Oczekiwany: 2");

// TEST 2e
    $display("\nTest 2. e)");
    #5 wpisz_do_pamieci(8'h11);
    print_state();
    $display("Oczekiwany: 4");

srd <= 0;
swr <= 0;
CLR();

// TEST 2f
    $display("\nTest 2. f)");
    #5 wpisz_do_pamieci(9'h100);
    print_state();
    $display("Oczekiwany: 4");

srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

// TEST 3a
    $display("\nTest 3. a)");
    #5 wpisz_do_pamieci(8'hac);
    #5 wpisz_do_pamieci(8'hdc);
    GET();
    wait_for_RDY();
    print_result();
    $display("Oczekiwane 3827e236");
    #100

CLR();

// TEST 3b
    $display("\nTest 3. b)");
    #5 wpisz_do_pamieci(8'h53);
    #5 wpisz_do_pamieci(8'h18);
    #5 wpisz_do_pamieci(8'h00);
    #5 wpisz_do_pamieci(8'h80);
    GET();
    wait_for_RDY();
    print_result();
    $display("Oczekiwane a2825413");
    #100

CLR();


// TEST 3c
    $display("\nTest 3. c)");
    #5 wpisz_do_pamieci(8'h00);
    GET();
    wait_for_RDY();
    print_result();
    $display("Oczekiwane 527d5351");
    #100

CLR();


// TEST 3d
    $display("\nTest 3. d)");
    #5 wpisz_do_pamieci(8'h00);
    #5 wpisz_do_pamieci(8'h00);
    #5 wpisz_do_pamieci(8'h00);
    #5 wpisz_do_pamieci(8'h00);
    GET();
    wait_for_RDY();
    print_result();
    $display("Oczekiwane 48674bc7");
    #100

CLR();

// TEST 3e
    $display("\nTest 3. e)");
    GET();
    wait_for_RDY();
    print_result();
    $display("Oczekiwane 00000000");
    #100

CLR();



// TEST 3f
    $display("\nTest 3. f)");
    for (integer i = 0; i < 250; i = i + 1) begin
    			#5 wpisz_do_pamieci(8'h11);
    end
    GET();
    wait_for_RDY();
    print_result();
    $display("Oczekiwane 3c96196e");
    #100

    CLR();



// TEST 3g
    $display("\nTest 3. g)");
    for (integer i = 0; i < 250; i = i + 1) begin
    			#5 wpisz_do_pamieci(8'h00);
    end
    GET();
    wait_for_RDY();
    print_result();
    $display("Oczekiwane a51552b8");
    #100
 CLR();

srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

 // TEST 4a
    $display("\nTest 4. a)");
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    CLR();
    #100

srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

// TEST 4b
    $display("\nTest 4. b)");
    CLR();
    #100

srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

// TEST 4c
    $display("\nTest 4. c)");
    for (integer i = 0; i < 250; i = i + 1) begin
    			#5 wpisz_do_pamieci(8'h11);
    end
    CLR();
    #100

// TEST 4d
    $display("\nTest 4. d)");
    for (integer i = 0; i < 251; i = i + 1) begin
    			#5 wpisz_do_pamieci(8'h11);
    end
    CLR();
    #100
    
srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

// TEST 4e
    $display("\nTest 4. e)");
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    GET();
    #10 
    CLR();
    #10 
    CLR();
    wait_for_RDY();
    print_result();
    $display("Oczekiwane b2d007fc");
    #100

// TEST 4f
    $display("\nTest 4. f)");
    CLR();
    print_result();
    $display("Oczekiwane 00000000");
    #100




// TEST 5a
    $display("\nTest 5. a)");
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    srd <= 0;
    swr <= 0;
    #5 n_reset <= 0;
    #5 n_reset <= 1;
    #100

    
// TEST 5b
    $display("\nTest 5. b)");
    srd <= 0;
    swr <= 0;
    #5 n_reset <= 0;
    #5 n_reset <= 1;
    #100

// TEST 5c
    $display("\nTest 5. c)");
    for (integer i = 0; i < 250; i = i + 1) begin
    			#5 wpisz_do_pamieci(8'h11);
    end
    srd <= 0;
    swr <= 0;
    #5 n_reset <= 0;
    #5 n_reset <= 1;
    #100

// TEST 5d
    $display("\nTest 5. d)");
    for (integer i = 0; i < 251; i = i + 1) begin
    			#5 wpisz_do_pamieci(8'h11);
    end
    srd <= 0;
    swr <= 0;
    #5 n_reset <= 0;
    #5 n_reset <= 1;
    #100



// TEST 5e
    $display("\nTest 5. e)");
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    GET();
    #10 
    srd <= 0;
    swr <= 0;
    #5 n_reset <= 0;
    #5 n_reset <= 1;
    print_state();
    $display("Oczekiwany: 1");
    #100

srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

// TEST 5f
    $display("\nTest 5. f)");
    srd <= 0;
    swr <= 0;
    #5 n_reset <= 0;
    #5 n_reset <= 1;
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    #5 wpisz_do_pamieci(8'h12);
    GET();
    wait_for_RDY();
    #50
    srd <= 0;
    swr <= 0;
    #5 n_reset <= 0;
    #5 n_reset <= 1;

srd <= 0;
swr <= 0;
#5 n_reset <= 0;
#5 n_reset <= 1;

// TEST 6a
$display("\nTest 6. a)");
    #5 wpisz_do_pamieci(8'hac);
    #5 wpisz_do_pamieci(8'hdc);
    GET();
    wait_for_RDY();
    print_result();
    $display("Oczekiwane 3827e236");
    GET();
    wait_for_RDY();
    print_result();
    $display("Oczekiwane 3827e236");
    #100

#100 $finish;
end
endmodule