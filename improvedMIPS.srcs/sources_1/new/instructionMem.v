`timescale 1ns / 1ps
module instructionMem #(parameter instructionMemSizeInBytes = 4096)
(
    input             reset,
    input      [31:0] pcVal,
    output     [31:0] instruction
);
    reg [7:0] mem [instructionMemSizeInBytes-1 : 0];
    assign instruction = {mem[pcVal], mem[pcVal+1], mem[pcVal+2], mem[pcVal+3]};
    task load_program;
        integer i;
        begin
            for (i = 0; i < instructionMemSizeInBytes; i = i + 1) begin
                mem[i] = 8'h00;
            end

//addi $1,  $0,  0
mem[    0]=8'h20; mem[    1]=8'h01; mem[    2]=8'h00; mem[    3]=8'h00;
//addi $2,  $0, -128
mem[    4]=8'h20; mem[    5]=8'h02; mem[    6]=8'hFF; mem[    7]=8'h80;
//lui $3,  0x0001
mem[    8]=8'h3C; mem[    9]=8'h03; mem[   10]=8'h00; mem[   11]=8'h01;
//ori $3,  $3,  0x0E00
mem[   12]=8'h34; mem[   13]=8'h63; mem[   14]=8'h0E; mem[   15]=8'h00;
//addi $10, $0,  26
mem[   16]=8'h20; mem[   17]=8'h0A; mem[   18]=8'h00; mem[   19]=8'h1A;
//addi $11, $0,  256
mem[   20]=8'h20; mem[   21]=8'h0B; mem[   22]=8'h01; mem[   23]=8'h00;
//addi $12, $0,  1280
mem[   24]=8'h20; mem[   25]=8'h0C; mem[   26]=8'h05; mem[   27]=8'h00;
//sub $13, $0,  $12
mem[   28]=8'h00; mem[   29]=8'h0C; mem[   30]=8'h68; mem[   31]=8'h22;
//lui $30, 0xFFFF
mem[   32]=8'h3C; mem[   33]=8'h1E; mem[   34]=8'hFF; mem[   35]=8'hFF;
//ori $30, $30, 0xFF00
mem[   36]=8'h37; mem[   37]=8'hDE; mem[   38]=8'hFF; mem[   39]=8'h00;
//lw $4,  0($30)
mem[   40]=8'h8F; mem[   41]=8'hC4; mem[   42]=8'h00; mem[   43]=8'h00;
//lw $5,  1($30)
mem[   44]=8'h8F; mem[   45]=8'hC5; mem[   46]=8'h00; mem[   47]=8'h01;
//lw $6,  2($30)
mem[   48]=8'h8F; mem[   49]=8'hC6; mem[   50]=8'h00; mem[   51]=8'h02;
//lw $7,  3($30)
mem[   52]=8'h8F; mem[   53]=8'hC7; mem[   54]=8'h00; mem[   55]=8'h03;
//lw $8,  4($30)
mem[   56]=8'h8F; mem[   57]=8'hC8; mem[   58]=8'h00; mem[   59]=8'h04;
//lw $9,  5($30)
mem[   60]=8'h8F; mem[   61]=8'hC9; mem[   62]=8'h00; mem[   63]=8'h05;
//add $29, $0, $3
mem[   64]=8'h00; mem[   65]=8'h03; mem[   66]=8'hE8; mem[   67]=8'h20;
//jal cos
mem[   68]=8'h0C; mem[   69]=8'h00; mem[   70]=8'h00; mem[   71]=8'h4F;
//mul $28, $29, $10
mem[   72]=8'h03; mem[   73]=8'hAA; mem[   74]=8'hE0; mem[   75]=8'h18;
//slt $29, $1, $12
mem[   76]=8'h00; mem[   77]=8'h2C; mem[   78]=8'hE8; mem[   79]=8'h2A;
//nop
mem[   80]=8'h00; mem[   81]=8'h00; mem[   82]=8'h00; mem[   83]=8'h00;
//nop
mem[   84]=8'h00; mem[   85]=8'h00; mem[   86]=8'h00; mem[   87]=8'h00;
//nop
mem[   88]=8'h00; mem[   89]=8'h00; mem[   90]=8'h00; mem[   91]=8'h00;
//beq $29, $0, skipXInc
mem[   92]=8'h13; mem[   93]=8'hA0; mem[   94]=8'h00; mem[   95]=8'h02;
//beq $4,  $0, skipXInc
mem[   96]=8'h10; mem[   97]=8'h80; mem[   98]=8'h00; mem[   99]=8'h01;
//add $1,  $1,  $28
mem[  100]=8'h00; mem[  101]=8'h3C; mem[  102]=8'h08; mem[  103]=8'h20;
//slt $29, $1, $13
mem[  104]=8'h00; mem[  105]=8'h2D; mem[  106]=8'hE8; mem[  107]=8'h2A;
//nop
mem[  108]=8'h00; mem[  109]=8'h00; mem[  110]=8'h00; mem[  111]=8'h00;
//nop
mem[  112]=8'h00; mem[  113]=8'h00; mem[  114]=8'h00; mem[  115]=8'h00;
//nop
mem[  116]=8'h00; mem[  117]=8'h00; mem[  118]=8'h00; mem[  119]=8'h00;
//bne $29, $0, skipXDec
mem[  120]=8'h17; mem[  121]=8'hA0; mem[  122]=8'h00; mem[  123]=8'h02;
//beq $5,  $0, skipXDec
mem[  124]=8'h10; mem[  125]=8'hA0; mem[  126]=8'h00; mem[  127]=8'h01;
//sub $1,  $1,  $28
mem[  128]=8'h00; mem[  129]=8'h3C; mem[  130]=8'h08; mem[  131]=8'h22;
//add $29, $0, $3
mem[  132]=8'h00; mem[  133]=8'h03; mem[  134]=8'hE8; mem[  135]=8'h20;
//jal sin
mem[  136]=8'h0C; mem[  137]=8'h00; mem[  138]=8'h00; mem[  139]=8'h46;
//mul $28, $29, $10
mem[  140]=8'h03; mem[  141]=8'hAA; mem[  142]=8'hE0; mem[  143]=8'h18;
//slt $29, $2, $12
mem[  144]=8'h00; mem[  145]=8'h4C; mem[  146]=8'hE8; mem[  147]=8'h2A;
//nop
mem[  148]=8'h00; mem[  149]=8'h00; mem[  150]=8'h00; mem[  151]=8'h00;
//nop
mem[  152]=8'h00; mem[  153]=8'h00; mem[  154]=8'h00; mem[  155]=8'h00;
//nop
mem[  156]=8'h00; mem[  157]=8'h00; mem[  158]=8'h00; mem[  159]=8'h00;
//beq $29, $0, skipYInc
mem[  160]=8'h13; mem[  161]=8'hA0; mem[  162]=8'h00; mem[  163]=8'h02;
//beq $6,  $0, skipYInc
mem[  164]=8'h10; mem[  165]=8'hC0; mem[  166]=8'h00; mem[  167]=8'h01;
//add $2,  $2,  $28
mem[  168]=8'h00; mem[  169]=8'h5C; mem[  170]=8'h10; mem[  171]=8'h20;
//slt $29, $2, $13
mem[  172]=8'h00; mem[  173]=8'h4D; mem[  174]=8'hE8; mem[  175]=8'h2A;
//nop
mem[  176]=8'h00; mem[  177]=8'h00; mem[  178]=8'h00; mem[  179]=8'h00;
//nop
mem[  180]=8'h00; mem[  181]=8'h00; mem[  182]=8'h00; mem[  183]=8'h00;
//nop
mem[  184]=8'h00; mem[  185]=8'h00; mem[  186]=8'h00; mem[  187]=8'h00;
//bne $29, $0, skipYDec
mem[  188]=8'h17; mem[  189]=8'hA0; mem[  190]=8'h00; mem[  191]=8'h02;
//beq $7,  $0, skipYDec
mem[  192]=8'h10; mem[  193]=8'hE0; mem[  194]=8'h00; mem[  195]=8'h01;
//sub $2,  $2,  $28
mem[  196]=8'h00; mem[  197]=8'h5C; mem[  198]=8'h10; mem[  199]=8'h22;
//beq $8,  $0, skipThetaInc
mem[  200]=8'h11; mem[  201]=8'h00; mem[  202]=8'h00; mem[  203]=8'h01;
//add $3,  $3,  $11
mem[  204]=8'h00; mem[  205]=8'h6B; mem[  206]=8'h18; mem[  207]=8'h20;
//beq $9,  $0, skipThetaDec
mem[  208]=8'h11; mem[  209]=8'h20; mem[  210]=8'h00; mem[  211]=8'h01;
//sub $3,  $3,  $11
mem[  212]=8'h00; mem[  213]=8'h6B; mem[  214]=8'h18; mem[  215]=8'h22;
//lui $29, 0x0001
mem[  216]=8'h3C; mem[  217]=8'h1D; mem[  218]=8'h00; mem[  219]=8'h01;
//ori $29, $29, 0x6800
mem[  220]=8'h37; mem[  221]=8'hBD; mem[  222]=8'h68; mem[  223]=8'h00;
//slt $28, $3, $0
mem[  224]=8'h00; mem[  225]=8'h60; mem[  226]=8'hE0; mem[  227]=8'h2A;
//nop
mem[  228]=8'h00; mem[  229]=8'h00; mem[  230]=8'h00; mem[  231]=8'h00;
//nop
mem[  232]=8'h00; mem[  233]=8'h00; mem[  234]=8'h00; mem[  235]=8'h00;
//nop
mem[  236]=8'h00; mem[  237]=8'h00; mem[  238]=8'h00; mem[  239]=8'h00;
//beq $28, $0, skipNegWrap
mem[  240]=8'h13; mem[  241]=8'h80; mem[  242]=8'h00; mem[  243]=8'h01;
//sub $3,  $29, $11
mem[  244]=8'h03; mem[  245]=8'hAB; mem[  246]=8'h18; mem[  247]=8'h22;
//slt $28, $3, $29
mem[  248]=8'h00; mem[  249]=8'h7D; mem[  250]=8'hE0; mem[  251]=8'h2A;
//nop
mem[  252]=8'h00; mem[  253]=8'h00; mem[  254]=8'h00; mem[  255]=8'h00;
//nop
mem[  256]=8'h00; mem[  257]=8'h00; mem[  258]=8'h00; mem[  259]=8'h00;
//nop
mem[  260]=8'h00; mem[  261]=8'h00; mem[  262]=8'h00; mem[  263]=8'h00;
//bne $28, $0, skipPosWrap
mem[  264]=8'h17; mem[  265]=8'h80; mem[  266]=8'h00; mem[  267]=8'h01;
//addi $3,  $0, 0
mem[  268]=8'h20; mem[  269]=8'h03; mem[  270]=8'h00; mem[  271]=8'h00;
//jal raycaster
mem[  272]=8'h0C; mem[  273]=8'h00; mem[  274]=8'h00; mem[  275]=8'h60;
//j start
mem[  276]=8'h08; mem[  277]=8'h00; mem[  278]=8'h00; mem[  279]=8'h0A;
//addi $28, $0, 8
mem[  280]=8'h20; mem[  281]=8'h1C; mem[  282]=8'h00; mem[  283]=8'h08;
//srlv $29, $29, $28
mem[  284]=8'h03; mem[  285]=8'h9D; mem[  286]=8'hE8; mem[  287]=8'h06;
//addi $28, $0, 2
mem[  288]=8'h20; mem[  289]=8'h1C; mem[  290]=8'h00; mem[  291]=8'h02;
//sllv $29, $29, $28
mem[  292]=8'h03; mem[  293]=8'h9D; mem[  294]=8'hE8; mem[  295]=8'h04;
//lw $29, 0($29)
mem[  296]=8'h8F; mem[  297]=8'hBD; mem[  298]=8'h00; mem[  299]=8'h00;
//nop
mem[  300]=8'h00; mem[  301]=8'h00; mem[  302]=8'h00; mem[  303]=8'h00;
//nop
mem[  304]=8'h00; mem[  305]=8'h00; mem[  306]=8'h00; mem[  307]=8'h00;
//nop
mem[  308]=8'h00; mem[  309]=8'h00; mem[  310]=8'h00; mem[  311]=8'h00;
//jr $31
mem[  312]=8'h03; mem[  313]=8'hE0; mem[  314]=8'h00; mem[  315]=8'h08;
//addi $28, $0, 8
mem[  316]=8'h20; mem[  317]=8'h1C; mem[  318]=8'h00; mem[  319]=8'h08;
//srlv $29, $29, $28
mem[  320]=8'h03; mem[  321]=8'h9D; mem[  322]=8'hE8; mem[  323]=8'h06;
//addi $29, $29, 90
mem[  324]=8'h23; mem[  325]=8'hBD; mem[  326]=8'h00; mem[  327]=8'h5A;
//addi $28, $0, 360
mem[  328]=8'h20; mem[  329]=8'h1C; mem[  330]=8'h01; mem[  331]=8'h68;
//slt $28, $29, $28
mem[  332]=8'h03; mem[  333]=8'hBC; mem[  334]=8'hE0; mem[  335]=8'h2A;
//nop
mem[  336]=8'h00; mem[  337]=8'h00; mem[  338]=8'h00; mem[  339]=8'h00;
//nop
mem[  340]=8'h00; mem[  341]=8'h00; mem[  342]=8'h00; mem[  343]=8'h00;
//nop
mem[  344]=8'h00; mem[  345]=8'h00; mem[  346]=8'h00; mem[  347]=8'h00;
//bne $28, $0, skipCosWrap
mem[  348]=8'h17; mem[  349]=8'h80; mem[  350]=8'h00; mem[  351]=8'h01;
//addi $29, $29, -360
mem[  352]=8'h23; mem[  353]=8'hBD; mem[  354]=8'hFE; mem[  355]=8'h98;
//addi $28, $0, 2
mem[  356]=8'h20; mem[  357]=8'h1C; mem[  358]=8'h00; mem[  359]=8'h02;
//sllv $29, $29, $28
mem[  360]=8'h03; mem[  361]=8'h9D; mem[  362]=8'hE8; mem[  363]=8'h04;
//lw $29, 0($29)
mem[  364]=8'h8F; mem[  365]=8'hBD; mem[  366]=8'h00; mem[  367]=8'h00;
//nop
mem[  368]=8'h00; mem[  369]=8'h00; mem[  370]=8'h00; mem[  371]=8'h00;
//nop
mem[  372]=8'h00; mem[  373]=8'h00; mem[  374]=8'h00; mem[  375]=8'h00;
//nop
mem[  376]=8'h00; mem[  377]=8'h00; mem[  378]=8'h00; mem[  379]=8'h00;
//jr $31
mem[  380]=8'h03; mem[  381]=8'hE0; mem[  382]=8'h00; mem[  383]=8'h08;
//sw $31, 0x0944($0)
mem[  384]=8'hAC; mem[  385]=8'h1F; mem[  386]=8'h09; mem[  387]=8'h44;
//lui $14, 0x0000
mem[  388]=8'h3C; mem[  389]=8'h0E; mem[  390]=8'h00; mem[  391]=8'h00;
//ori $14, $14, 0x05A4
mem[  392]=8'h35; mem[  393]=8'hCE; mem[  394]=8'h05; mem[  395]=8'hA4;
//lui $16, 0x0000
mem[  396]=8'h3C; mem[  397]=8'h10; mem[  398]=8'h00; mem[  399]=8'h00;
//ori $16, $16, 0x0734
mem[  400]=8'h36; mem[  401]=8'h10; mem[  402]=8'h07; mem[  403]=8'h34;
//addi $17, $0, 32
mem[  404]=8'h20; mem[  405]=8'h11; mem[  406]=8'h00; mem[  407]=8'h20;
//addi $18, $3, -16384
mem[  408]=8'h20; mem[  409]=8'h72; mem[  410]=8'hC0; mem[  411]=8'h00;
//lui $28, 0x0001
mem[  412]=8'h3C; mem[  413]=8'h1C; mem[  414]=8'h00; mem[  415]=8'h01;
//ori $28, $28, 0x6800
mem[  416]=8'h37; mem[  417]=8'h9C; mem[  418]=8'h68; mem[  419]=8'h00;
//slt $29, $18, $0
mem[  420]=8'h02; mem[  421]=8'h40; mem[  422]=8'hE8; mem[  423]=8'h2A;
//nop
mem[  424]=8'h00; mem[  425]=8'h00; mem[  426]=8'h00; mem[  427]=8'h00;
//nop
mem[  428]=8'h00; mem[  429]=8'h00; mem[  430]=8'h00; mem[  431]=8'h00;
//nop
mem[  432]=8'h00; mem[  433]=8'h00; mem[  434]=8'h00; mem[  435]=8'h00;
//beq $29, $0, noWrapStart
mem[  436]=8'h13; mem[  437]=8'hA0; mem[  438]=8'h00; mem[  439]=8'h01;
//add $18, $18, $28
mem[  440]=8'h02; mem[  441]=8'h5C; mem[  442]=8'h90; mem[  443]=8'h20;
//slt $29, $18, $28
mem[  444]=8'h02; mem[  445]=8'h5C; mem[  446]=8'hE8; mem[  447]=8'h2A;
//nop
mem[  448]=8'h00; mem[  449]=8'h00; mem[  450]=8'h00; mem[  451]=8'h00;
//nop
mem[  452]=8'h00; mem[  453]=8'h00; mem[  454]=8'h00; mem[  455]=8'h00;
//nop
mem[  456]=8'h00; mem[  457]=8'h00; mem[  458]=8'h00; mem[  459]=8'h00;
//bne $29, $0, startAngleOk
mem[  460]=8'h17; mem[  461]=8'hA0; mem[  462]=8'h00; mem[  463]=8'h01;
//sub $18, $18, $28
mem[  464]=8'h02; mem[  465]=8'h5C; mem[  466]=8'h90; mem[  467]=8'h22;
//addi $19, $0, 128
mem[  468]=8'h20; mem[  469]=8'h13; mem[  470]=8'h00; mem[  471]=8'h80;
//addi $21, $0, 0
mem[  472]=8'h20; mem[  473]=8'h15; mem[  474]=8'h00; mem[  475]=8'h00;
//add $29, $0, $18
mem[  476]=8'h00; mem[  477]=8'h12; mem[  478]=8'hE8; mem[  479]=8'h20;
//jal cos
mem[  480]=8'h0C; mem[  481]=8'h00; mem[  482]=8'h00; mem[  483]=8'h4F;
//add $22, $29, $0
mem[  484]=8'h03; mem[  485]=8'hA0; mem[  486]=8'hB0; mem[  487]=8'h20;
//add $29, $0, $18
mem[  488]=8'h00; mem[  489]=8'h12; mem[  490]=8'hE8; mem[  491]=8'h20;
//jal sin
mem[  492]=8'h0C; mem[  493]=8'h00; mem[  494]=8'h00; mem[  495]=8'h46;
//add $23, $29, $0
mem[  496]=8'h03; mem[  497]=8'hA0; mem[  498]=8'hB8; mem[  499]=8'h20;
//addi $28, $1, 1280
mem[  500]=8'h20; mem[  501]=8'h3C; mem[  502]=8'h05; mem[  503]=8'h00;
//addi $29, $0, 8
mem[  504]=8'h20; mem[  505]=8'h1D; mem[  506]=8'h00; mem[  507]=8'h08;
//srlv $24, $28, $29
mem[  508]=8'h03; mem[  509]=8'hBC; mem[  510]=8'hC0; mem[  511]=8'h06;
//addi $28, $2, 1280
mem[  512]=8'h20; mem[  513]=8'h5C; mem[  514]=8'h05; mem[  515]=8'h00;
//srlv $25, $28, $29
mem[  516]=8'h03; mem[  517]=8'hBC; mem[  518]=8'hC8; mem[  519]=8'h06;
//slt $28, $22, $0
mem[  520]=8'h02; mem[  521]=8'hC0; mem[  522]=8'hE0; mem[  523]=8'h2A;
//nop
mem[  524]=8'h00; mem[  525]=8'h00; mem[  526]=8'h00; mem[  527]=8'h00;
//nop
mem[  528]=8'h00; mem[  529]=8'h00; mem[  530]=8'h00; mem[  531]=8'h00;
//nop
mem[  532]=8'h00; mem[  533]=8'h00; mem[  534]=8'h00; mem[  535]=8'h00;
//bne $28, $0, xDirNeg
mem[  536]=8'h17; mem[  537]=8'h80; mem[  538]=8'h00; mem[  539]=8'h06;
//addi $29, $0, 1
mem[  540]=8'h20; mem[  541]=8'h1D; mem[  542]=8'h00; mem[  543]=8'h01;
//sw $29, 0x093C($0)
mem[  544]=8'hAC; mem[  545]=8'h1D; mem[  546]=8'h09; mem[  547]=8'h3C;
//addi $28, $1, 1280
mem[  548]=8'h20; mem[  549]=8'h3C; mem[  550]=8'h05; mem[  551]=8'h00;
//andi $28, $28, 0x00FF
mem[  552]=8'h33; mem[  553]=8'h9C; mem[  554]=8'h00; mem[  555]=8'hFF;
//sub $28, $11, $28
mem[  556]=8'h01; mem[  557]=8'h7C; mem[  558]=8'hE0; mem[  559]=8'h22;
//j doneStepX
mem[  560]=8'h08; mem[  561]=8'h00; mem[  562]=8'h00; mem[  563]=8'h92;
//addi $29, $0, -1
mem[  564]=8'h20; mem[  565]=8'h1D; mem[  566]=8'hFF; mem[  567]=8'hFF;
//sw $29, 0x093C($0)
mem[  568]=8'hAC; mem[  569]=8'h1D; mem[  570]=8'h09; mem[  571]=8'h3C;
//addi $29, $1, 1280
mem[  572]=8'h20; mem[  573]=8'h3D; mem[  574]=8'h05; mem[  575]=8'h00;
//andi $28, $29, 0x00FF
mem[  576]=8'h33; mem[  577]=8'hBC; mem[  578]=8'h00; mem[  579]=8'hFF;
//sub $22, $0, $22
mem[  580]=8'h00; mem[  581]=8'h16; mem[  582]=8'hB0; mem[  583]=8'h22;
//nop
mem[  584]=8'h00; mem[  585]=8'h00; mem[  586]=8'h00; mem[  587]=8'h00;
//nop
mem[  588]=8'h00; mem[  589]=8'h00; mem[  590]=8'h00; mem[  591]=8'h00;
//nop
mem[  592]=8'h00; mem[  593]=8'h00; mem[  594]=8'h00; mem[  595]=8'h00;
//bne $22, $0, xDirNzOk
mem[  596]=8'h16; mem[  597]=8'hC0; mem[  598]=8'h00; mem[  599]=8'h01;
//addi $22, $0, 1
mem[  600]=8'h20; mem[  601]=8'h16; mem[  602]=8'h00; mem[  603]=8'h01;
//div $26, $28, $22
mem[  604]=8'h03; mem[  605]=8'h96; mem[  606]=8'hD0; mem[  607]=8'h1A;
//div $28, $11, $22
mem[  608]=8'h01; mem[  609]=8'h76; mem[  610]=8'hE0; mem[  611]=8'h1A;
//sw $28, 0x0934($0)
mem[  612]=8'hAC; mem[  613]=8'h1C; mem[  614]=8'h09; mem[  615]=8'h34;
//slt $28, $23, $0
mem[  616]=8'h02; mem[  617]=8'hE0; mem[  618]=8'hE0; mem[  619]=8'h2A;
//nop
mem[  620]=8'h00; mem[  621]=8'h00; mem[  622]=8'h00; mem[  623]=8'h00;
//nop
mem[  624]=8'h00; mem[  625]=8'h00; mem[  626]=8'h00; mem[  627]=8'h00;
//nop
mem[  628]=8'h00; mem[  629]=8'h00; mem[  630]=8'h00; mem[  631]=8'h00;
//bne $28, $0, yDirNeg
mem[  632]=8'h17; mem[  633]=8'h80; mem[  634]=8'h00; mem[  635]=8'h06;
//addi $29, $0, 1
mem[  636]=8'h20; mem[  637]=8'h1D; mem[  638]=8'h00; mem[  639]=8'h01;
//sw $29, 0x0940($0)
mem[  640]=8'hAC; mem[  641]=8'h1D; mem[  642]=8'h09; mem[  643]=8'h40;
//addi $28, $2, 1280
mem[  644]=8'h20; mem[  645]=8'h5C; mem[  646]=8'h05; mem[  647]=8'h00;
//andi $28, $28, 0x00FF
mem[  648]=8'h33; mem[  649]=8'h9C; mem[  650]=8'h00; mem[  651]=8'hFF;
//sub $28, $11, $28
mem[  652]=8'h01; mem[  653]=8'h7C; mem[  654]=8'hE0; mem[  655]=8'h22;
//j doneStepY
mem[  656]=8'h08; mem[  657]=8'h00; mem[  658]=8'h00; mem[  659]=8'hAA;
//addi $29, $0, -1
mem[  660]=8'h20; mem[  661]=8'h1D; mem[  662]=8'hFF; mem[  663]=8'hFF;
//sw $29, 0x0940($0)
mem[  664]=8'hAC; mem[  665]=8'h1D; mem[  666]=8'h09; mem[  667]=8'h40;
//addi $29, $2, 1280
mem[  668]=8'h20; mem[  669]=8'h5D; mem[  670]=8'h05; mem[  671]=8'h00;
//andi $28, $29, 0x00FF
mem[  672]=8'h33; mem[  673]=8'hBC; mem[  674]=8'h00; mem[  675]=8'hFF;
//sub $23, $0, $23
mem[  676]=8'h00; mem[  677]=8'h17; mem[  678]=8'hB8; mem[  679]=8'h22;
//nop
mem[  680]=8'h00; mem[  681]=8'h00; mem[  682]=8'h00; mem[  683]=8'h00;
//nop
mem[  684]=8'h00; mem[  685]=8'h00; mem[  686]=8'h00; mem[  687]=8'h00;
//nop
mem[  688]=8'h00; mem[  689]=8'h00; mem[  690]=8'h00; mem[  691]=8'h00;
//bne $23, $0, yDirNzOk
mem[  692]=8'h16; mem[  693]=8'hE0; mem[  694]=8'h00; mem[  695]=8'h01;
//addi $23, $0, 1
mem[  696]=8'h20; mem[  697]=8'h17; mem[  698]=8'h00; mem[  699]=8'h01;
//div $27, $28, $23
mem[  700]=8'h03; mem[  701]=8'h97; mem[  702]=8'hD8; mem[  703]=8'h1A;
//div $28, $11, $23
mem[  704]=8'h01; mem[  705]=8'h77; mem[  706]=8'hE0; mem[  707]=8'h1A;
//sw $28, 0x0938($0)
mem[  708]=8'hAC; mem[  709]=8'h1C; mem[  710]=8'h09; mem[  711]=8'h38;
//slt $28, $26, $27
mem[  712]=8'h03; mem[  713]=8'h5B; mem[  714]=8'hE0; mem[  715]=8'h2A;
//nop
mem[  716]=8'h00; mem[  717]=8'h00; mem[  718]=8'h00; mem[  719]=8'h00;
//nop
mem[  720]=8'h00; mem[  721]=8'h00; mem[  722]=8'h00; mem[  723]=8'h00;
//nop
mem[  724]=8'h00; mem[  725]=8'h00; mem[  726]=8'h00; mem[  727]=8'h00;
//beq $28, $0, ddaStepY
mem[  728]=8'h13; mem[  729]=8'h80; mem[  730]=8'h00; mem[  731]=8'h0B;
//lw $28, 0x0934($0)
mem[  732]=8'h8C; mem[  733]=8'h1C; mem[  734]=8'h09; mem[  735]=8'h34;
//nop
mem[  736]=8'h00; mem[  737]=8'h00; mem[  738]=8'h00; mem[  739]=8'h00;
//nop
mem[  740]=8'h00; mem[  741]=8'h00; mem[  742]=8'h00; mem[  743]=8'h00;
//nop
mem[  744]=8'h00; mem[  745]=8'h00; mem[  746]=8'h00; mem[  747]=8'h00;
//add $26, $26, $28
mem[  748]=8'h03; mem[  749]=8'h5C; mem[  750]=8'hD0; mem[  751]=8'h20;
//lw $29, 0x093C($0)
mem[  752]=8'h8C; mem[  753]=8'h1D; mem[  754]=8'h09; mem[  755]=8'h3C;
//nop
mem[  756]=8'h00; mem[  757]=8'h00; mem[  758]=8'h00; mem[  759]=8'h00;
//nop
mem[  760]=8'h00; mem[  761]=8'h00; mem[  762]=8'h00; mem[  763]=8'h00;
//nop
mem[  764]=8'h00; mem[  765]=8'h00; mem[  766]=8'h00; mem[  767]=8'h00;
//add $24, $24, $29
mem[  768]=8'h03; mem[  769]=8'h1D; mem[  770]=8'hC0; mem[  771]=8'h20;
//j ddaCheckHit
mem[  772]=8'h08; mem[  773]=8'h00; mem[  774]=8'h00; mem[  775]=8'hCC;
//lw $28, 0x0938($0)
mem[  776]=8'h8C; mem[  777]=8'h1C; mem[  778]=8'h09; mem[  779]=8'h38;
//nop
mem[  780]=8'h00; mem[  781]=8'h00; mem[  782]=8'h00; mem[  783]=8'h00;
//nop
mem[  784]=8'h00; mem[  785]=8'h00; mem[  786]=8'h00; mem[  787]=8'h00;
//nop
mem[  788]=8'h00; mem[  789]=8'h00; mem[  790]=8'h00; mem[  791]=8'h00;
//add $27, $27, $28
mem[  792]=8'h03; mem[  793]=8'h7C; mem[  794]=8'hD8; mem[  795]=8'h20;
//lw $29, 0x0940($0)
mem[  796]=8'h8C; mem[  797]=8'h1D; mem[  798]=8'h09; mem[  799]=8'h40;
//nop
mem[  800]=8'h00; mem[  801]=8'h00; mem[  802]=8'h00; mem[  803]=8'h00;
//nop
mem[  804]=8'h00; mem[  805]=8'h00; mem[  806]=8'h00; mem[  807]=8'h00;
//nop
mem[  808]=8'h00; mem[  809]=8'h00; mem[  810]=8'h00; mem[  811]=8'h00;
//add $25, $25, $29
mem[  812]=8'h03; mem[  813]=8'h3D; mem[  814]=8'hC8; mem[  815]=8'h20;
//addi $20, $0, 9
mem[  816]=8'h20; mem[  817]=8'h14; mem[  818]=8'h00; mem[  819]=8'h09;
//sub $20, $20, $25
mem[  820]=8'h02; mem[  821]=8'h99; mem[  822]=8'hA0; mem[  823]=8'h22;
//addi $29, $0, 3
mem[  824]=8'h20; mem[  825]=8'h1D; mem[  826]=8'h00; mem[  827]=8'h03;
//sllv $28, $20, $29
mem[  828]=8'h03; mem[  829]=8'hB4; mem[  830]=8'hE0; mem[  831]=8'h04;
//addi $29, $0, 1
mem[  832]=8'h20; mem[  833]=8'h1D; mem[  834]=8'h00; mem[  835]=8'h01;
//sllv $29, $20, $29
mem[  836]=8'h03; mem[  837]=8'hB4; mem[  838]=8'hE8; mem[  839]=8'h04;
//add $28, $28, $29
mem[  840]=8'h03; mem[  841]=8'h9D; mem[  842]=8'hE0; mem[  843]=8'h20;
//add $28, $28, $24
mem[  844]=8'h03; mem[  845]=8'h98; mem[  846]=8'hE0; mem[  847]=8'h20;
//addi $29, $0, 2
mem[  848]=8'h20; mem[  849]=8'h1D; mem[  850]=8'h00; mem[  851]=8'h02;
//sllv $28, $28, $29
mem[  852]=8'h03; mem[  853]=8'hBC; mem[  854]=8'hE0; mem[  855]=8'h04;
//add $29, $14, $28
mem[  856]=8'h01; mem[  857]=8'hDC; mem[  858]=8'hE8; mem[  859]=8'h20;
//lw $28, 0($29)
mem[  860]=8'h8F; mem[  861]=8'hBC; mem[  862]=8'h00; mem[  863]=8'h00;
//nop
mem[  864]=8'h00; mem[  865]=8'h00; mem[  866]=8'h00; mem[  867]=8'h00;
//nop
mem[  868]=8'h00; mem[  869]=8'h00; mem[  870]=8'h00; mem[  871]=8'h00;
//nop
mem[  872]=8'h00; mem[  873]=8'h00; mem[  874]=8'h00; mem[  875]=8'h00;
//beq $28, $0, ddaLoop
mem[  876]=8'h13; mem[  877]=8'h80; mem[  878]=8'hFF; mem[  879]=8'hD6;
//slt $28, $27, $26
mem[  880]=8'h03; mem[  881]=8'h7A; mem[  882]=8'hE0; mem[  883]=8'h2A;
//nop
mem[  884]=8'h00; mem[  885]=8'h00; mem[  886]=8'h00; mem[  887]=8'h00;
//nop
mem[  888]=8'h00; mem[  889]=8'h00; mem[  890]=8'h00; mem[  891]=8'h00;
//nop
mem[  892]=8'h00; mem[  893]=8'h00; mem[  894]=8'h00; mem[  895]=8'h00;
//bne $28, $0, hitYSide
mem[  896]=8'h17; mem[  897]=8'h80; mem[  898]=8'h00; mem[  899]=8'h06;
//lw $29, 0x0934($0)
mem[  900]=8'h8C; mem[  901]=8'h1D; mem[  902]=8'h09; mem[  903]=8'h34;
//nop
mem[  904]=8'h00; mem[  905]=8'h00; mem[  906]=8'h00; mem[  907]=8'h00;
//nop
mem[  908]=8'h00; mem[  909]=8'h00; mem[  910]=8'h00; mem[  911]=8'h00;
//nop
mem[  912]=8'h00; mem[  913]=8'h00; mem[  914]=8'h00; mem[  915]=8'h00;
//sub $28, $26, $29
mem[  916]=8'h03; mem[  917]=8'h5D; mem[  918]=8'hE0; mem[  919]=8'h22;
//j storeLen
mem[  920]=8'h08; mem[  921]=8'h00; mem[  922]=8'h00; mem[  923]=8'hEC;
//lw $29, 0x0938($0)
mem[  924]=8'h8C; mem[  925]=8'h1D; mem[  926]=8'h09; mem[  927]=8'h38;
//nop
mem[  928]=8'h00; mem[  929]=8'h00; mem[  930]=8'h00; mem[  931]=8'h00;
//nop
mem[  932]=8'h00; mem[  933]=8'h00; mem[  934]=8'h00; mem[  935]=8'h00;
//nop
mem[  936]=8'h00; mem[  937]=8'h00; mem[  938]=8'h00; mem[  939]=8'h00;
//sub $28, $27, $29
mem[  940]=8'h03; mem[  941]=8'h7D; mem[  942]=8'hE0; mem[  943]=8'h22;
//slt $29, $28, $11
mem[  944]=8'h03; mem[  945]=8'h8B; mem[  946]=8'hE8; mem[  947]=8'h2A;
//nop
mem[  948]=8'h00; mem[  949]=8'h00; mem[  950]=8'h00; mem[  951]=8'h00;
//nop
mem[  952]=8'h00; mem[  953]=8'h00; mem[  954]=8'h00; mem[  955]=8'h00;
//nop
mem[  956]=8'h00; mem[  957]=8'h00; mem[  958]=8'h00; mem[  959]=8'h00;
//beq $29, $0, noClampLen
mem[  960]=8'h13; mem[  961]=8'hA0; mem[  962]=8'h00; mem[  963]=8'h01;
//addi $28, $11, 0
mem[  964]=8'h21; mem[  965]=8'h7C; mem[  966]=8'h00; mem[  967]=8'h00;
//div $29, $17, $28
mem[  968]=8'h02; mem[  969]=8'h3C; mem[  970]=8'hE8; mem[  971]=8'h1A;
//addi $28, $0, 64
mem[  972]=8'h20; mem[  973]=8'h1C; mem[  974]=8'h00; mem[  975]=8'h40;
//slt $28, $28, $29
mem[  976]=8'h03; mem[  977]=8'h9D; mem[  978]=8'hE0; mem[  979]=8'h2A;
//nop
mem[  980]=8'h00; mem[  981]=8'h00; mem[  982]=8'h00; mem[  983]=8'h00;
//nop
mem[  984]=8'h00; mem[  985]=8'h00; mem[  986]=8'h00; mem[  987]=8'h00;
//nop
mem[  988]=8'h00; mem[  989]=8'h00; mem[  990]=8'h00; mem[  991]=8'h00;
//beq $28, $0, noClampH
mem[  992]=8'h13; mem[  993]=8'h80; mem[  994]=8'h00; mem[  995]=8'h01;
//addi $29, $0, 64
mem[  996]=8'h20; mem[  997]=8'h1D; mem[  998]=8'h00; mem[  999]=8'h40;
//add $28, $16, $21
mem[ 1000]=8'h02; mem[ 1001]=8'h15; mem[ 1002]=8'hE0; mem[ 1003]=8'h20;
//sw $29, 0($28)
mem[ 1004]=8'hAF; mem[ 1005]=8'h9D; mem[ 1006]=8'h00; mem[ 1007]=8'h00;
//add $18, $18, $11
mem[ 1008]=8'h02; mem[ 1009]=8'h4B; mem[ 1010]=8'h90; mem[ 1011]=8'h20;
//lui $28, 0x0001
mem[ 1012]=8'h3C; mem[ 1013]=8'h1C; mem[ 1014]=8'h00; mem[ 1015]=8'h01;
//ori $28, $28, 0x6800
mem[ 1016]=8'h37; mem[ 1017]=8'h9C; mem[ 1018]=8'h68; mem[ 1019]=8'h00;
//slt $29, $18, $28
mem[ 1020]=8'h02; mem[ 1021]=8'h5C; mem[ 1022]=8'hE8; mem[ 1023]=8'h2A;
//nop
mem[ 1024]=8'h00; mem[ 1025]=8'h00; mem[ 1026]=8'h00; mem[ 1027]=8'h00;
//nop
mem[ 1028]=8'h00; mem[ 1029]=8'h00; mem[ 1030]=8'h00; mem[ 1031]=8'h00;
//nop
mem[ 1032]=8'h00; mem[ 1033]=8'h00; mem[ 1034]=8'h00; mem[ 1035]=8'h00;
//bne $29, $0, noWrapRay
mem[ 1036]=8'h17; mem[ 1037]=8'hA0; mem[ 1038]=8'h00; mem[ 1039]=8'h01;
//sub $18, $18, $28
mem[ 1040]=8'h02; mem[ 1041]=8'h5C; mem[ 1042]=8'h90; mem[ 1043]=8'h22;
//addi $21, $21, 4
mem[ 1044]=8'h22; mem[ 1045]=8'hB5; mem[ 1046]=8'h00; mem[ 1047]=8'h04;
//addi $19, $19, -1
mem[ 1048]=8'h22; mem[ 1049]=8'h73; mem[ 1050]=8'hFF; mem[ 1051]=8'hFF;
//nop
mem[ 1052]=8'h00; mem[ 1053]=8'h00; mem[ 1054]=8'h00; mem[ 1055]=8'h00;
//nop
mem[ 1056]=8'h00; mem[ 1057]=8'h00; mem[ 1058]=8'h00; mem[ 1059]=8'h00;
//nop
mem[ 1060]=8'h00; mem[ 1061]=8'h00; mem[ 1062]=8'h00; mem[ 1063]=8'h00;
//bne $19, $0, rayLoop
mem[ 1064]=8'h16; mem[ 1065]=8'h60; mem[ 1066]=8'hFF; mem[ 1067]=8'h6C;
//lw $31, 0x0944($0)
mem[ 1068]=8'h8C; mem[ 1069]=8'h1F; mem[ 1070]=8'h09; mem[ 1071]=8'h44;
//nop
mem[ 1072]=8'h00; mem[ 1073]=8'h00; mem[ 1074]=8'h00; mem[ 1075]=8'h00;
//nop
mem[ 1076]=8'h00; mem[ 1077]=8'h00; mem[ 1078]=8'h00; mem[ 1079]=8'h00;
//nop
mem[ 1080]=8'h00; mem[ 1081]=8'h00; mem[ 1082]=8'h00; mem[ 1083]=8'h00;
//jr $31
mem[ 1084]=8'h03; mem[ 1085]=8'hE0; mem[ 1086]=8'h00; mem[ 1087]=8'h08;

        end
    endtask
    initial load_program;
    always @(posedge reset) load_program;
endmodule
