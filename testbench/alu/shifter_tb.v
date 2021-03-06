module testbench;
    reg [31:0] A, B;
    reg [1:0] ctrl;
    wire [31:0] Z;
    wire cout;

    shifter shifter(.a(A), .shamt(B), .ctrl(ctrl), .res(Z), .cout(cout));

    initial begin

        $monitoro("@%0dns A=%h shamt=%d res=%b",
                    $time, A, B, Z);
        // sll
        $display("---SHIFT LEFT LOGICAL--");
        #0 A = 32'hFFFFFFFF; B = 32'd1; ctrl = 2'b10;
        #10 A = 32'hFFFFFFFF; B = 32'd2;
        #10 A = 32'hFFFFFFFF; B = 32'd3;
        #10 A = 32'hFFFFFFFF; B = 32'd7;
        #10 A = 32'hFFFFFFFF; B = 32'd15;
        #10 A = 32'hFFFFFFFF; B = 32'd16;
        #10 A = 32'h0FFFFFFF; B = 32'd31;
        #10 A = 32'h00000000; B = 32'd32;
        #10 A = 32'h00000000; B = 32'd33;

        // srl
        #10 $display("---SHIFT RIGHT LOGICAL--");
        #10 A = 32'hFFFFFFFF; B = 32'd1; ctrl = 2'b00;
        #10 A = 32'hFFFFFFFF; B = 32'd5;
        #10 A = 32'hFFFFFFFF; B = 32'd10;
        #10 A = 32'hFFFFFFFF; B = 32'd40;
        #10 A = 32'h00000000; B = 32'd32;

        // sra
        #10 $display("---SHIFT RIGHT ARITHMETIC--");
        #10 A = 32'h0FFFFFFF; B = 32'd1; ctrl = 2'b01;
        #10 A = 32'h0FFFFFFF; B = 32'd5;
        #10 A = 32'hFFFFFFFF; B = 32'd10;
        #10 A = 32'h0FFFFFFF; B = 32'd40;
    end
endmodule