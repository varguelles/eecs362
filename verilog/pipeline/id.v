module id(
    instruction,
    aluCtrl, aluSrc, setInv,
    regDst, memRd, memWr, regWr,
    branch, jr, jump, link,
    dSize, imm32,
    rs1, rs2, rd, op0, fp, not_trap, zeroExt
);

    // Interface
    input [31:0] instruction;       //instruction from pipeline (IMEM in toplevel)
    
    output [31:0] imm32;            // sign extended immediate
    output [3:0] aluCtrl;           // outputs from control unit
    output [1:0] dSize;
    output aluSrc, setInv,          
            regDst, memRd, memWr, regWr,
            branch, jr, jump, link, op0, fp;
    output [4:0] rs1, rs2, rd;      // set by instruction, link, and regDst
    output not_trap;
    output zeroExt;
    
    // Internal Signals
    wire [4:0] rs2, rs2_link, rd_rt;
    wire link, regDst, signExt, zeroExt, jump;
    wire [31:0] signExt32;
    wire [31:0] zeroExt32;
    


// Control Unit

    control control(
        .instruction(instruction),
        .aluCtrl(aluCtrl),
        .aluSrc(aluSrc),
        .setInv(setInv),
        .regDst(regDst),
        .memRd(memRd),
        .memWr(memWr),
        .regWr(regWr),
        .branch(branch),
        .jr(jr),
        .jump(jump),
        .link(link),
        .dSize(dSize),
        .signExt(signExt),
        .zeroExt(zeroExt),
        .fp(fp),
        .not_trap(not_trap)
        );



    // If jal/jalr, set rs2 to reg31
    mux2to1 #(5) muxReg31 (.src0(instruction[20:16]), .src1(5'b11111), .sel(link), .z(rs2));
    
    // If immediate, default rs2 = 0 for hazard detection
    // mux2to1 #(5) muxImm(.src0(rs2_link), .src1(5'b0), .sel(aluSrc), .z(rs2));
    
    // Either rs2 or instruction[15:11] will be the destination register (rd)
    mux2to1 #(5) mux2to1(.src0(rs2), .src1(instruction[15:11]), .sel(regDst), .z(rd_rt));
    
    // If store word, default rd = 0 for hazard detection
    mux2to1 #(5) muxStore(.src0(rd_rt), .src1(5'b0), .sel(memWr), .z(rd));
  
    // assign rs1
    assign rs1 = instruction[25:21]; // if fp = 1, this is referencing a fp register
    
    // Sign-extension
    sign_extender sign_extender(.imm(instruction[25:0]), .signExt(signExt), .res(signExt32), .jump(jump));
    assign zeroExt32 = {instruction[15:0], 16'b0};
    mux2to1 #(32) muxImmExt(.src0(signExt32), .src1(zeroExt32), .sel(zeroExt), .z(imm32));
    
    // assign op0 for branch stuff in MEM
    assign op0 = instruction[26];


endmodule // id