[ToC]
# ASoC Final Project
## Introdcution

For this final project, I'm working on improving the speed of a classic neural network model called LeNet-5, which is used for recognizing handwritten digits. The main challenge with neural networks is that they can be slow, especially when it comes to the convolution operations that process images.

To make LeNet-5 run faster, we use a algorithm called im2col. This method transforms the convolution process into a simpler matrix multiplication problem. Matrix multiplication is something that specialized hardware, we call it TPU. The TPU is implement by systolic array and three golbal buffers. It is data flow calculation which can handle the calculation faster.

By converting convolutions into matrix multiplications with im2col, we can take advantage of these hardware accelerators to speed up the inference process. This means the model can recognize digits much quicker without losing accuracy.

In this project, we will show how using im2col and hardware acceleration can make LeNet-5 more efficient when recognizing digits from the MNIST dataset. This approach demonstrates how LeNet-5 run on the jupyter notebook and covolution layer call the matrix multiplication IP in the user project1. It will pass the data in the accelarater through FSIC in FPGA PL side to FSIC in the caravel SoC. The TPU is in the user project1 of FSIC in the caravel SoC. This model inference with powerful hardware can significantly improve the performance of neural networks.



## Architecture
### System Architecture
![image](https://hackmd.io/_uploads/BJi3yfsBC.png)

### UserProject IP Architecture

![image](https://hackmd.io/_uploads/B1GlgMsHA.png)


# Folder Structure

|Folder Name | Description |
| ------ | ------ |
| rtl  | Include all the functon implement in rtl and simulation by testbench |
| dc  | Include the script of synthesis flow  |
| vivado | Include the system simulation and validation with vivado flow |
* **User Project Design Folder**
    * rtl/user/user_subsys/user_prj/user_prj1/rtl/
* **JupyterNotebook  Code Folder**
    * vivado/jupyter_notebook

# Build Setup
Ubuntu 20.04 with Vivado 2022.1

## Simulation Building Steps
```
git clone https://github.com/michael61112/ASoC_Final
cd ASoC_Final
```



# Run Test

## Simulation

### User Project Level simulation
``` shell
cd final_project/rtl/user/testbench/tc/
./run_xsim
```

### System Level simulation
Integrate AP into Caravel-FSIC FPGA. The simulation

* Run simulation
``` shell
cd vivado
./run_vivado_fsic_sim
```

* Waveform review
``` shell
./open_wave
```

* Open built Vivado Project by Vivado GUI
    * File->Open->Project
    * Target Project file:
        * fsic_fpga/vivado/vvd_caravel_fpga_sim/vvd_caravel_fpga_sim.xpr

## Validation

``` shell
cd vivado
./run_vivado_fsic
```
* **Bitfile**:
    * vivado/jupyter_notebook/caravel_fpga.bit

* **Hwh**:
    * vivado/jupyter_notebook/caravel_fpga.hwh

