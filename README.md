# Parallel-Ship-Detection-Edge-BNN-for-FPGA
Dataset is available at https://www.kaggle.com/rhammell/ships-in-satellite-imagery. It is also uploaded at https://doi.org/10.5281/zenodo.3611230 for DOI and reproducibility.

Paths in all files are to be changed. The user must change them for its directory structure.

# Neural Network Training
1.) ships_dataset.m reads the dataset and formates them into the appropriate binary form (subsampling, resize) and separates them into training, testing, and validation sets. 

2.) Formatted files are used as inputs to the training algorithm explained in  I. Hubara, M. Courbariaux, D. Soudry, R. El-Yaniv, Y. Bengio, Binarizedneural networks, in:  D. D. Lee, M. Sugiyama, U. V. Luxburg, I. Guyon,R.  Garnett  (Eds.),  Advances  in  Neural  Information  Processing  Systems29, Curran Associates, Inc., 2016, pp. 4107–4115. URL: http://papers.nips.cc/paper/6573-binarized-neural-networks.pdf 

3.) The code for the training algorithm (from point 2.) is available at: https://github.com/MatthieuCourbariaux/BinaryNet.

4.) The resulting trained files (outputs of code from point 3.) are transformed from -1/1 to 0/1 using algorithms from "Y. Umuroglu, N. J. Fraser, G. Gambardella, M. Blott, P. H. W. Leong, M. Jahre, and K. A. Vissers, “Finn: A framework for fast, scalable binarized neural network inference,” in FPGA, 2017".

5.) The final trained and formatted (0/1/integer) neural network parameters are provided as: dump_w_(0-2).txt are network weights per layer and dump_t_(0-2).txt are thresholds per layer.

# System
The main script is system_sim.m. First part (lines 1-27) reads the ship detection network parameters. 

The second part (lines 28-210) runs the Neuron-Merger algorithm as described in the paper and creates the RTL Verilog file of the first layer in the BNN (50 neurons with 1200 inputs each). 

The third part (lines 211-216) builds the straight-forward Verilog implementation of all three layers. This includes the first one, but in actuallity, the one created through the Neuron-Merger algorithm is used. The straight-forward RTL code of the first layer is only used for comparison in the paper.

The fourth part (lines 217+) simulates the pre- and post-processing algorithms and BNN inference as described in the paper. The inference with sliding window is tested on a sample image.

