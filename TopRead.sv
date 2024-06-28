`timescale 1ns / 1ps
`define CLK_PERIOD 10 // Clock period of 100MHz

module TopRead;
    //正式测试
    /*parameter N    =   64;
    parameter SIZE_IN    =   270000;
    parameter SIZE_WEI    =  21000;
    parameter SIZE_OUT    =   81000;
    parameter SIZE_COL    =  576;
    parameter H_OUT    =   128;
    parameter W_OUT    =   1024;
    parameter SIZE_in_DATA    =   18;
    parameter SIZE_val_DATA    =   8;
    parameter SIZE_col_DATA    =   10;
    parameter SIZE_row_DATA    =   18;*/
    //简单测试
   parameter N    =   2;
    parameter W_OUT    =  8 ;
    parameter SIZE_COL    =  10;
    parameter H_OUT    =   7;
   parameter SIZE_IN    =   SIZE_COL*H_OUT;
    parameter SIZE_WEI    =  SIZE_COL*W_OUT;
    parameter SIZE_OUT    =   SIZE_COL*W_OUT;
    parameter SIZE_in_DATA    =   14;
    parameter SIZE_val_DATA    =   8;
    parameter SIZE_col_DATA    =   10;
    parameter SIZE_row_DATA    =   18;
    // Declaration of signals
    reg clk;
    reg reset;
    reg enable;
    reg signed [7:0] val_Wei[SIZE_WEI-1:0];
    reg [7:0] row_Wei[SIZE_WEI-1:0];
    reg [14:0] col_Wei[SIZE_COL:0];
    reg [25:0]time_count_1=0;
    reg [25:0]time_count_2=0;
    reg signed[7:0] val_In[SIZE_IN-1:0];
    reg [9:0] row_In[SIZE_IN-1:0];
    reg [18:0] col_In[SIZE_COL:0];
    
    reg  signed[SIZE_in_DATA-1:0] array_out[H_OUT-1:0][W_OUT-1:0];  // 输出矩阵的值，横坐标，纵坐标
    reg  signed[SIZE_in_DATA-1:0] array_out_N[N-1:0][N-1:0][3:0];  // 输出矩阵的值，横坐标，纵坐标
    wire signed[SIZE_val_DATA-1:0] val_out[SIZE_OUT-1:0];
    wire [SIZE_col_DATA-1:0] row_out[SIZE_OUT-1:0];
    wire [SIZE_row_DATA-1:0] col_out[H_OUT:0];
    reg [SIZE_row_DATA-1:0] col_out_ref[H_OUT:0];
    reg compress_begin;
    reg compress_end;
    
    reg[7:0] in_val_Wei[N-1:0];
    reg [7:0] in_row_Wei[N-1:0];
    
    reg[7:0] in_val_In[N-1:0];
    reg[7:0] in_row_In[N-1:0];
    
   reg [18:0] count_In;  // 10-bit counter for In_num
   reg [18:0] count_Wei; // 10-bit counter for wei_num
   reg [18:0] count_col; // 10-bit counter for wei_num
   reg finish=0;
   reg write=0;

    
    /*ComputeArray #(
    .N(N)
    ) computeArray_inst (
    .val_Wei(in_val_Wei),  // 这里假设 val_Wei 传递正确
    .row_Wei(in_row_Wei),  // 同上
    .val_In(in_val_In),    // 同上
    .row_In(in_row_In),    // 同上
    .reset(reset),
    .enable(enable),
    .val_out(compArray_val_out)  // 连接到定义的输出数组
);*/

   //Instantiate the compress_CSR module
    compress_CSR #(
    .SIZE_OUT(SIZE_OUT),
    .SIZE_COL(SIZE_COL),
    .H_OUT(H_OUT),//被压缩的方向
    .W_OUT(W_OUT),
    .SIZE_in_DATA(SIZE_in_DATA),
    .SIZE_val_DATA(SIZE_val_DATA),
    .SIZE_col_DATA(SIZE_col_DATA),
    .SIZE_row_DATA(SIZE_row_DATA)
    )csr (
        .clk(clk),
        .reset(reset),
        .enable(compress_begin),
        .input_array(array_out),
       .val(val_out),
        .col(row_out),
        .row(col_out),
        .valid_output(compress_end)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(`CLK_PERIOD/2) clk = ~clk;
    end

    // Stimulus
    integer wrong_num=0;
    initial begin
        reset = 1;
        enable = 0;
        #(`CLK_PERIOD * 10);
        reset = 0;
        enable = 1;
          // 初始化 in_val_Wei, in_row_Wei, in_val_In, in_row_In
        for (integer idx = 0; idx < N; idx++) begin
            in_val_Wei[idx] = 0;
            in_row_Wei[idx] = 0;
            in_val_In[idx] = 0;
            in_row_In[idx] = 0;
            count_In=0;
            count_Wei=0;
            count_col=0;
            compress_begin=0;
        end
         //Load the input array from a file
        /*$readmemb("E://vivado//Data_hw//CSCandCSR//activation_2_val_b.txt", val_In);   
        $readmemb("E://vivado//Data_hw//CSCandCSR//activation_2_row_b.txt", row_In);  
        $readmemb("E://vivado//Data_hw//CSCandCSR//activation_2_col_b.txt", col_In);  
        $readmemb("E://vivado//Data_hw//CSCandCSR//weight_val_b.txt", val_Wei);   
        $readmemb("E://vivado//Data_hw//CSCandCSR//weight_row_b.txt", row_Wei);  
        $readmemb("E://vivado//Data_hw//CSCandCSR//weight_col_b.txt", col_Wei);
        $readmemb("E://vivado//Data_hw//CSCandCSR//OUT//output_2_col_b.txt",col_out_ref);*/
         
        //$readmemb("E://vivado//Data_hw//CSCandCSR//OUT//output_2_b.txt",array_out);
        
        $readmemb("E://vivado//Data_hw//CSCandCSR//easy//OUT//activation_easy10_val_b.txt", val_In);   
        $readmemb("E://vivado//Data_hw//CSCandCSR//easy//OUT//activation_easy10_row_b.txt", row_In);  
        $readmemb("E://vivado//Data_hw//CSCandCSR//easy//OUT//activation_easy10_col_b.txt", col_In);  
        $readmemb("E://vivado//Data_hw//CSCandCSR//easy//OUT//weight_easy10_val_b.txt", val_Wei);   
        $readmemb("E://vivado//Data_hw//CSCandCSR//easy//OUT//weight_easy10_row_b.txt", row_Wei);  
        $readmemb("E://vivado//Data_hw//CSCandCSR//easy//OUT//weight_easy10_col_b.txt", col_Wei);
        $readmemb("E://vivado//Data_hw//CSCandCSR//easy//OUT//output_easy10_col_b.txt",col_out_ref);
        wait (finish == 1'b1);
        compress_begin<=1;
        enable <= 0;
        wait (compress_end== 1'b1);
        $display("Compression complete, output valid.");

            for(integer p=0;p<H_OUT ;p=p+1) begin   
                if(col_out_ref[p]!=col_out[p]) begin
                     $display("wrong at (%d), output %d, reference %d",p, col_out[p], col_out_ref[p]);
                     wrong_num = wrong_num + 1;
                 end
            end
        $display("wrong num: %d",wrong_num);
        $display("computer time: %d",time_count_1);
        $display("compress time: %d",time_count_2);

        $display("val:%d %d %d %d %d %d",val_out[0],val_out[1],val_out[2],val_out[3],val_out[4],val_out[5],val_out[6],,val_out[7],,val_out[8],val_out[9],val_out[10],val_out[11],val_out[12],val_out[13],val_out[14]);
        $display("row:%d %d %d %d %d %d",row_out[0],row_out[1],row_out[2],row_out[3],row_out[4],row_out[5],row_out[6],row_out[7],row_out[8],row_out[9],row_out[10],row_out[11],,row_out[12],row_out[13],row_out[14]);
         $display("col:%d %d %d %d %d %d",col_out[0],col_out[1],col_out[2],col_out[3],col_out[4],col_out[5],col_out[6],col_out[7],col_out[8]);
        $finish;  // End simulation
    end
    
   Computer #(
        .N(N),
        .SIZE_COL(SIZE_COL),
        .H_OUT(H_OUT),
        .W_OUT(W_OUT),
        .SIZE_WEI(SIZE_WEI),
        .SIZE_IN(SIZE_IN),
        .SIZE_in_DATA(SIZE_in_DATA)
    ) compute_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .val_Wei(val_Wei),
        .row_Wei(row_Wei),
        .col_Wei(col_Wei),
        .val_In(val_In),
        .row_In(row_In),
        .col_In(col_In),
        .finish(finish),
        .array_out(array_out_N),
        .out_write(out_write)
    );


 always @(posedge clk) begin
    if(finish==1&&compress_end==0)begin
        time_count_2=time_count_2+1;
    end
    if(reset)begin
        for (int x = 0; x < H_OUT ; x++) begin
                for (int y = 0; y < W_OUT ; y++) begin        
                        array_out[x][y] <= 0;  // Reset all elements to zero
                end
            end
    end else if(enable&&finish==0)begin
            time_count_1=time_count_1+1;
            for (int i = 0; i < N ; i++) begin
                for (int j = 0; j < N ; j++) begin 
                    if(array_out_N[i][j][3]==1)begin    
                        array_out[array_out_N[i][j][1]][array_out_N[i][j][2]]=array_out_N[i][j][0]+ array_out[array_out_N[i][j][1]][array_out_N[i][j][2]];
                        array_out_N[i][j][3]=0;
                    end
                end
            end
     end
 end




endmodule

