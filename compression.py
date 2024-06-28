import os
import numpy as np
from scipy.sparse import csr_matrix, csc_matrix

def CSC_or_CSR(name, mode, road='data', relu=[0, 0], base='b', if_T='0', max_bit=[8, 8, 8, 8], abs=0):
    # 确定文件路径
    if abs:
        input_path = os.path.abspath(f'{road}/{name}.txt')
        output_road = os.path.abspath(road)
    else:
        input_path = f'{road}/{name}.txt'
        output_road = road
    
    # 检查并创建data文件夹
    if not os.path.exists(output_road):
        os.makedirs(output_road)
    
    # 读取文件内容并解析成矩阵
    with open(input_path, 'r') as file:
        data = file.readlines()
    
    # 将数据转换成二维数组
    matrix = []
    for line in data:
        row = list(map(int, line.split()))
        matrix.append(row)
    if if_T == '1':
        matrix = np.array(matrix).T
    else:
        matrix = np.array(matrix)
    
    # 如果 relu 参数为 1，将矩阵中小于 0 的元素赋值为 0，大于 0 的元素右移 8 位
    if relu[0] == 1:
        matrix[matrix < 0] = 0
    if relu[1] == 1:
        matrix[matrix > 0] = matrix[matrix > 0] >> 8

    
    if mode == 'CSC':
        sparse_matrix = csc_matrix(matrix)
    elif mode == 'CSR':
        sparse_matrix = csr_matrix(matrix)
    else:
        raise ValueError("mode must be 'CSC' or 'CSR'")
    
    val = sparse_matrix.data
    row = sparse_matrix.indices
    col = sparse_matrix.indptr

    # 根据进制选择格式化方法
    def format_value(x, base, bit_length):
        if base == 'b':
            # 用有符号的二进制表示负数
            if x >= 0:
                return '{:0{}b}'.format(x, bit_length)
            else:
        # Calculate two's complement
                x = (1 << bit_length) + x  # this effectively does (2^bit_length) + x for negative x
            return '{:0{}b}'.format(x, bit_length)
        elif base == 'o':
            return '{:o}'.format(x)
        else:
            return '{}'.format(x)
    
    output_dir = os.path.join(output_road, 'OUT')
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # 保存原始矩阵以指定进制形式到txt文件
    with open(f'{output_dir}/{name}_{base}.txt', 'w') as file:
        for row1 in matrix:
            formatted_row = ' '.join(format_value(x, base, max_bit[0]) for x in row1)
            file.write(formatted_row + '\n')

    # 将稀疏矩阵的数据以指定进制形式写入txt文件
    with open(f'{output_dir}/{name}_val_{base}.txt', 'w') as file:
        file.write(' '.join(format_value(x, base, max_bit[1]) for x in val) + '\n')
        
    with open(f'{output_dir}/{name}_row_{base}.txt', 'w') as file:
        file.write(' '.join(format_value(x, base, max_bit[2]) for x in row) + '\n')
        
    with open(f'{output_dir}/{name}_col_{base}.txt', 'w') as file:
        file.write(' '.join(format_value(x, base, max_bit[3]) for x in col) + '\n')
    if len(val)!=0:
        print(f"Max value in {name} val:", max(val))
        print(f"Min value in {name} val:", min(val))
    return val, row, col

# 生成矩阵并保存
import os
import numpy as np

import os
import numpy as np

def generate_matrix_and_save(N1, M, N2, road, activation_file, weight_file, output_file, non_zero_ratio=0.3, value_range=(-15, 16)):
    np.random.seed(42)  # for reproducibility
    
    def generate_sparse_matrix(rows, cols, non_zero_ratio, value_range):
        matrix = np.zeros((rows, cols), dtype=int)
        non_zero_elements = int(rows * cols * non_zero_ratio)
        indices = np.random.choice(rows * cols, non_zero_elements, replace=False)
        values = np.random.randint(value_range[0], value_range[1], non_zero_elements)
        np.put(matrix, indices, values)
        return matrix
    
    activation_matrix = generate_sparse_matrix(N1, M, non_zero_ratio, value_range)
    weight_matrix = generate_sparse_matrix(M, N2, non_zero_ratio, value_range)

    # Ensure output directory exists
    if not os.path.exists(road):
        os.makedirs(road)

    # Save matrices to files in the same format as CSC_or_CSR
    def save_matrix(matrix, filename):
        with open(filename, 'w') as file:
            for row in matrix:
                file.write(' '.join(map(str, row)) + '\n')

    save_matrix(activation_matrix, os.path.join(road, activation_file))
    save_matrix(weight_matrix, os.path.join(road, weight_file))

    # Multiply matrices and save the result
    output_matrix = np.dot(activation_matrix, weight_matrix)
    save_matrix(output_matrix, os.path.join(road, output_file))
    print(activation_matrix)
    print(weight_matrix)
    print(output_matrix)
    return activation_file[:-4], weight_file[:-4], output_file[:-4]

# 示例用法
road = "E://vivado//Data_hw//CSCandCSR//easy"
N1, M, N2 = 8,10,7
activation_file = 'activation_easy10.txt'
weight_file = 'weight_easy10.txt'
output_file = 'output_easy10.txt'

non_zero_ratio = 0.3
value_range = (-31, 32)

activation_name, weight_name, output_name = generate_matrix_and_save(N1, M, N2, road, activation_file, weight_file, output_file, non_zero_ratio, value_range)

# 分别调用CSC_or_CSR函数
relu = [0, 0]
relu2=[1,1]
base = 'b'
max_bit = [14, 8, 10, 19]
abs = 1
val_act, row_act, col_act = CSC_or_CSR(activation_name, 'CSC', road, relu=relu, base=base, max_bit=max_bit, abs=abs)
val_weight, row_weight, col_weight = CSC_or_CSR(weight_name, 'CSR', road, relu=relu, base=base, max_bit=max_bit, abs=abs)
val_output, row_output, col_output = CSC_or_CSR(output_name, 'CSC', road, relu=relu2, base=base, max_bit=max_bit, abs=abs)

print("activation val:", val_act)
print("activation row:", row_act)
print("activation col:", col_act)

print("weight val:", val_weight)
print("weight row:", row_weight)
print("weight col:", col_weight)

print("output val:", val_output)
print("output row:", row_output)
print("output col:", col_output)


