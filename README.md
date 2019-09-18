# Parallel-Ship-Detection-Edge-BNN-for-FPGA

--> Dataset is available at ----
--> Paths in all files are subject to change. The user must change them for its directory structure.

--> Formatted files from ships_dataset.m are used as inputs to code paper+code TODO reference.
--> Trained files are transformed from -1/1 to 0/1 using algorithms from paper+code(EV paper) TODO reference.

--> dump_xxx.txt are BNN parameters.

--> Main script is system_sim.m. It simulates pre- and post-processing algorithms and BNN inference as described in the paper. The inference with sliding window is tested on a sample image. Additionally it implementes the Neuron-Merger algorithm for the first layer and build its Verilog code (ship_merger). Next to that it outputs verliog files of combinational circuits for all BNN layer in a straight-forward implementation (standard_model). 
