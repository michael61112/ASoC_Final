# ASoC Final Project
## Introdcution

For this final project, I'm working on improving the speed of a classic Convolutional Neural Network (CNN) model used for image recognition. The main challenge with neural networks is that they can be slow, especially when it comes to the convolution operations that process images.

To make our CNN run faster, we utilize specialized hardware called TPUs (Tensor Processing Units). The TPU is implemented using a systolic array and three global buffers. It is a data flow calculation architecture that can handle calculations much faster.

By leveraging these hardware accelerators, we can speed up the inference process of our CNN model. This means the model can recognize images much quicker without losing accuracy.

In this project, we will demonstrate how using hardware acceleration can make our CNN more efficient. This approach shows how the CNN runs on the Jupyter notebook, and the convolution layers utilize the matrix multiplication IP in user project1. The data is passed to the accelerator through FSIC in the FPGA PL side to FSIC in the Caravel SoC. The TPU is part of the user project1 in the FSIC within the Caravel SoC. This model inference with powerful hardware can significantly improve the performance of neural networks.



## Architecture
### System Architecture
![image](https://github.com/michael61112/ASoC_Final/blob/main/doc/picture/System_Architecture.png)

### UserProject IP Architecture
![image](https://github.com/michael61112/ASoC_Final/blob/main/doc/picture/UserProject_IP_Architecture.png)


### Testbench Code Block Diagram
![image](https://github.com/michael61112/ASoC_Final/blob/main/doc/picture/Testbench_Code_Block_Diagram.png)


# Folder Structure

|Folder Name | Description |
| ------ | ------ |
| rtl  | Include all the functon implement in rtl and simulation by testbench |
| dc  | Include the script of synthesis flow  |
| vivado | Include the system simulation and validation with vivado flow |
| doc | Include the simulation、validation report and the ppt of final report |
| pattern | Inculde pattern generating code and test pattern|
* **User Project Design Folder**
    * rtl/user/user_subsys/user_prj/user_prj1/rtl/
* **JupyterNotebook  Code Folder**
    * vivado/jupyter_notebook
* **Unit Test Code Folder**
    * vivado/jupyter_notebook/Unit_Test

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

* **Run simulation**
    ``` shell
    cd vivado
    ./run_vivado_fsic_sim
    ```

* **Waveform review**
    ``` shell
    ./open_wave
    ```

* **Open built Vivado Project by Vivado GUI**
    * File->Open->Project
    * Target Project file:
        * fsic_fpga/vivado/vvd_caravel_fpga_sim/vvd_caravel_fpga_sim.xpr

## Validation

* Build Bitstream
    ``` shell
    cd vivado
    ./run_vivado_fsic
    ```
* **Bitfile**:
    * vivado/jupyter_notebook/caravel_fpga.bit

* **Hwh**:
    * vivado/jupyter_notebook/caravel_fpga.hwh

## Synthesis

* **Run Synthesis**
    ``` shell
    cd dc/lab_synthesis/work
    make clean
    make all
    ```

* **dc script**:
    * dc/lab_synthesis/scripts/compile_for_timing.tcl
* **sdc file**:
    * dc/common/USER_PRJ1.sdc
