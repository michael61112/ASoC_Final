import numpy as np
import matplotlib.pyplot as plt

def apply_convolution(matrixA, matrixB):
    """Apply a convolution operation on matrixA using matrixB."""
    kernel_height, kernel_width = matrixB.shape
    image_height, image_width = matrixA.shape

    # Calculate the dimensions of the output matrix
    output_height = image_height - kernel_height + 1
    output_width = image_width - kernel_width + 1

    # Initialize the output matrix
    output_matrix = np.zeros((output_height, output_width), dtype=np.int8)

    # Apply the convolution operation
    for i in range(output_height):
        for j in range(output_width):
            region = matrixA[i:i + kernel_height, j:j + kernel_width]
            output_matrix[i, j] = np.sum(region * matrixB)

    # Clip values to int8 range
    output_matrix = np.clip(output_matrix, -128, 127)
    
    return output_matrix

def generate_pattern(image_height, image_width, kernel_height, kernel_width):
    """Generate a pattern on a matrix of given size using a convolution kernel."""
    # Create an initial random matrix with int8 values
    matrixA = np.random.randint(-128, 128, (image_height, image_width), dtype=np.int8)

    # Create a random convolution kernel with int8 values
    matrixB = np.random.randint(-128, 128, (kernel_height, kernel_width), dtype=np.int8)

    # Apply the convolution
    pattern = apply_convolution(matrixA, matrixB)

    return matrixA, matrixB, pattern

def plot_images(matrixA, matrixB, pattern):
    """Plot the original matrix, kernel, and the generated pattern."""
    plt.figure(figsize=(18, 6))
    
    plt.subplot(1, 3, 1)
    plt.title('Original Random Matrix (matrixA)')
    plt.imshow(matrixA, cmap='gray', vmin=-128, vmax=127)
    plt.colorbar()

    plt.subplot(1, 3, 2)
    plt.title('Convolution Kernel (matrixB)')
    plt.imshow(matrixB, cmap='gray', vmin=-128, vmax=127)
    plt.colorbar()

    plt.subplot(1, 3, 3)
    plt.title('Generated Pattern')
    plt.imshow(pattern, cmap='gray', vmin=-128, vmax=127)
    plt.colorbar()

    plt.show()

# Set the dimensions for matrixA and matrixB (parameters)
image_height = 8  # Height of the matrixA
image_width = 10  # Width of the matrixA
kernel_height = 5  # Height of the matrixB
kernel_width = 3  # Width of the matrixB

# Generate the pattern
matrixA, matrixB, pattern = generate_pattern(image_height, image_width, kernel_height, kernel_width)

# Plot the original matrix, kernel, and generated pattern
plot_images(matrixA, matrixB, pattern)

# Save the matrixA, matrixB, and pattern to files
np.savetxt("matrixA.txt", matrixA, fmt='%d')
np.savetxt("matrixB.txt", matrixB, fmt='%d')
np.savetxt("golden.txt", pattern, fmt='%d')
