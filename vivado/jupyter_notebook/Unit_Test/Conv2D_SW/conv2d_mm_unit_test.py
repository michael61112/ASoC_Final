import numpy as np

def matrix_mul(matA, matB, k, m, n):
    """
    Perform matrix multiplication on matrices A and B.
    
    Args:
    matA (list of lists or 2D numpy array): Matrix A with dimensions m x k.
    matB (list of lists or 2D numpy array): Matrix B with dimensions k x n.
    k (int): The number of columns in matA and rows in matB.
    m (int): The number of rows in matA.
    n (int): The number of columns in matB.
    
    Returns:
    np.ndarray: The result matrix with dimensions m x n.
    """
    
    # Convert matA and matB to numpy arrays if they are not already
    matA = np.array(matA, dtype=np.int32)  # Use int32 to prevent overflow
    matB = np.array(matB, dtype=np.int32)  # Use int32 to prevent overflow
    
    # Initialize the result matrix with zeros
    matC = np.zeros((m, n), dtype=np.int32)  # Use int32 to prevent overflow
    
    # Perform matrix multiplication
    for i in range(m):
        for j in range(n):
            for l in range(k):
                matC[i, j] += matA[i, l] * matB[l, j]
    
    return matC.astype(np.int8)  # Convert the result back to int8

def conv2D(img, kernel, stride=1):
    """
    Perform a 2D convolution operation on an image using a kernel.
    
    Args:
    img (2D numpy array): The input image matrix.
    kernel (2D numpy array): The convolution kernel matrix.
    stride (int): The stride of the convolution.
    
    Returns:
    np.ndarray: The result matrix after applying the convolution.
    """
    
    img_height, img_width = img.shape
    kernel_height, kernel_width = kernel.shape
    out_height = img_height - kernel_height + 1
    out_width = img_width - kernel_width + 1
    
    cmatrix = np.lib.stride_tricks.as_strided(
        img,
        shape=(out_height, out_width, kernel_height, kernel_width),
        strides=(stride * img.strides[0], stride * img.strides[1], img.strides[0], img.strides[1])
    )
    
    k = kernel_height * kernel_width
    cmatrix = cmatrix.reshape(-1, k)
    
    kernel_flat = kernel.ravel().reshape(k, 1)
    out = matrix_mul(cmatrix, kernel_flat, k, cmatrix.shape[0], 1)
    
    return out.reshape(out_height, out_width)

# Load the saved matrices
matrixA = np.loadtxt("matrixA.txt", dtype=np.int8)
matrixB = np.loadtxt("matrixB.txt", dtype=np.int8)
golden_pattern = np.loadtxt("golden.txt", dtype=np.int8)

# Perform the convolution using conv2D
pattern = conv2D(matrixA, matrixB, stride=1)

# Print the output pattern
print("Generated Pattern from Convolution:")
print(pattern)

# Compare with the golden pattern
difference = pattern - golden_pattern
print("Difference between generated pattern and golden pattern:")
print(difference)

# Check if the generated pattern matches the golden pattern
if np.array_equal(pattern, golden_pattern):
    print("The generated pattern matches the golden pattern.")
else:
    print("The generated pattern does not match the golden pattern.")
