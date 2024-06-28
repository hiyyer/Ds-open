module icompress#(
    parameter W_OUT    =   128,
    parameter SIZE_in_DATA    =   14,
    parameter SIZE_val_DATA    =   8,
    parameter SIZE_count    =   6,
    parameter LEFT_NUM    =   8,
    parameter BEGIN_NUM    =  1<<<LEFT_NUM
    
)(
    input wire signed[SIZE_in_DATA-1:0] column_data[W_OUT-1:0],  // 1024-bit wide input
    input wire enable,
    input clk,
    output reg [SIZE_val_DATA-1:0] val[W_OUT-1:0],      // 8-bit val array
    output reg [SIZE_count-1:0] col[W_OUT-1:0],      // column index array
    output reg [SIZE_count-1:0] val_count        // number of non-zero values
);

integer i,i2, index;

always @(*) begin
    // Reorganize input data into an 8-bit wide, 128 elements array
    if(enable==1)begin
        index = 0;
        for (i = 0; i < W_OUT ; i = i + 1) begin
            if (i==0)begin
            for (i2 = 0; i2 < W_OUT; i2 = i2 + 1) begin
                val[i2] = 0;
                col[i2] = 0;
        end
            end
            if (column_data[i] >=BEGIN_NUM ) begin
                val[index] = column_data[i]>>>LEFT_NUM;
                col[index] = i;
                index = index + 1;
            end
        end
        val_count = index;
    end
end

endmodule
