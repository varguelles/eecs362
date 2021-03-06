module ex(
    aluSrc, aluCtrl, setInv, zeroExt,
    busA, busB, imm32,
    aluRes, isZero, fp, multCtrl, product_in
    );
    
    // Interface
    input [3:0] aluCtrl;        // input into ALU, from ID
    input [31:0] busA, busB;    // from pipeline (from toplevel)
    input [31:0] imm32;         // sign extended immediate from sign extender in ID
    input aluSrc, setInv, fp, zeroExt;     // control signals from ID 
    input [1:0] multCtrl;
    input [31:0] product_in;
    
    output [31:0] aluRes;       // alu result
    output isZero;               // used for branch logic in MEM stage
    
    
    
    // Internal Signals
    wire [31:0] srcB;           // second input to ALU
    wire [31:0] aluRes_int, aluRes_int2; 
    wire [31:0] mulRes;         // result of multiplier
    wire [31:0] srcA;           // LHI stuff
    wire mulSel;                // selects if we take mulRes
    wire andTmp0, andTmp1;      // signals used for setting multiplier selector
    
    // choose between busB or imm32 as srcB for ALU
    mux2to1 #(32) Ms3B(.src0(busB), .src1(imm32), .sel(aluSrc), .z(srcB));
    
    // LHI
    mux2to1 #(32) lhi (.src0(busA), .src1(32'd0), .sel(zeroExt), .z(srcA));
  
    
    // ALU -- might need to explicity say that flag outputs are open
    alu alu(.a(srcA), .b(srcB), .alu_ctrl(aluCtrl), .inverse_set(setInv), .res(aluRes_int));
    
    // Multiplier -- TODO, need to replace with WallaceTreeBooth multiplier
    multiplier multing(.a(srcA), .b(srcB), .control(multCtrl), .product_in(product_in), .product_out(mulRes));
    and_gate and_gate1 (aluCtrl[0], aluCtrl[1], andTmp0);
    and_gate and_gate2 (aluCtrl[2], aluCtrl[3], andTmp1);
    and_gate and_gate3 (andTmp0, andTmp1, mulSel); 
    
    // select between aluRes and multRes as final result
    mux2to1 #(32) MultMux(.src0(aluRes_int), .src1(mulRes), .sel(mulSel), .z(aluRes_int2));
    
    // if fp = 1, aluRes = busA
    mux2to1 #(32) idontknow(.src0(aluRes_int2), .src1(srcA), .sel(fp), .z(aluRes));
    
    // check if busA is zero for branching, set isZero                         
    nor32to1 checkisZero(.a(srcA), .z(isZero));

    
endmodule