module compress_CSR#(
    parameter SIZE_OUT    =   10,
    parameter SIZE_COL    =  10,
    parameter H_OUT    =   3,
    parameter W_OUT    =   3,
    parameter SIZE_in_DATA    =   14,
    parameter SIZE_val_DATA    =   8,
    parameter SIZE_col_DATA    =   10,
    parameter SIZE_row_DATA    =   18
)(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire signed  [SIZE_in_DATA-1:0]input_array[H_OUT-1:0][W_OUT-1:0],
    output reg signed[SIZE_val_DATA-1:0] val[SIZE_OUT-1:0], // 8-bit val, max 81000 non-zero values
    output reg [SIZE_col_DATA-1:0] col[SIZE_OUT-1:0], // column index for each val, max 1024 cols
    output reg [SIZE_row_DATA-1:0] row[H_OUT:0], // start index for each row in val array
    output reg valid_output
);

reg [10:0] current_col;
reg [6:0] val_count;
reg [1:0] reset_step=2'b00; // New variable to handle reset in steps

wire [SIZE_val_DATA-1:0] ic_val [W_OUT-1:0];
wire [SIZE_col_DATA-1:0] ic_col [W_OUT-1:0];
wire [SIZE_col_DATA-1:0] ic_val_count;

// Instantiate icompress
icompress  #(
        .W_OUT(W_OUT),
        .SIZE_in_DATA(SIZE_in_DATA),
        .SIZE_val_DATA(SIZE_val_DATA),
        .SIZE_count(SIZE_col_DATA)
    ) ic(
    .column_data(input_array[current_col]),
    .val(ic_val),
    .col(ic_col),
    .enable(enable),
    .clk(clk),
    .val_count(ic_val_count)
);

integer i, j, index;
reg [17:0] row_array [0:H_OUT];

always @(posedge clk or posedge reset) begin
    if (reset) begin
        case (reset_step)
            2'b00: begin
                for (i = 0; i < SIZE_OUT/4; i = i + 1) begin
                    val[i] <= 0;
                    col[i] <= 0;
                end
                reset_step <= 2'b01;
            end
            2'b01: begin
                for (i = SIZE_OUT/4; i < SIZE_OUT/2; i = i + 1) begin
                    val[i] <= 0;
                    col[i] <= 0;
                end
                reset_step <= 2'b10;
            end
            2'b10: begin
                for (i = SIZE_OUT/2; i < SIZE_OUT/4*3; i = i + 1) begin
                    val[i] <= 0;
                    col[i] <= 0;
                end
                reset_step <= 2'b11;
            end
            2'b11: begin
                for (i =  SIZE_OUT/4*3; i <  SIZE_OUT; i = i + 1) begin
                    val[i] <= 0;
                    col[i] <= 0;
                end
                for (i = 0; i < W_OUT; i = i + 1) begin
                    row_array[i] <= 0;
                end
                index <= 0;
                current_col <= 0;
                valid_output <= 0;
                val_count<=0;
                reset_step <= 2'b00; // Reset step to initial state
            end
        endcase
    end else if (enable) begin
        if (current_col < H_OUT) begin
            // Process each column
            //if (val_count != ic_val_count) begin
            val_count <=  ic_val_count;
                for (j = 0; j < SIZE_OUT-1; j = j + 1) begin
                    if(j<ic_val_count)begin
                    val[index] = ic_val[j];
                    col[index] = ic_col[j];
                    index = index + 1;
                    end
                end
                row_array[current_col+1] = index;
                current_col = current_col + 1;
            //end
        end else begin
            valid_output <= 1;  // Compression is done
        end
    end
end

// Assign row start indices to output
always @(*) begin
    for (i = 0; i < H_OUT+1; i = i + 1) begin
        row[i] = row_array[i];
    end
end

endmodule

