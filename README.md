# OpenFRET Utilities
This repository contains utilities for converting to and from the [OpenFRET format](https://github.com/simol-lab/OpenFRET) for single-molecule traces data.

## Installation
### Matlab
First download or clone the [OpenFRET repository](https://github.com/simol-lab/OpenFRET), and add it + all of its subfolders to your Matlab path.

Then, download or clone this repository, and add it + its subfolders to your matlab path.

Finally, open and run main.m after setting the metadata to your desired values.

## Content
### Matlab
**main.m**: Main script for adding user-defined metadata and options. Calls simreps2openfret.m to write 
**simreps2openfret.m**: Converts `m x n` single-channel traces files from Matlab SiMREPS analysis into the OpenFRET format.  Input files must be in .mat format with traces in rows and frames in columns.

**test_data**: Folder with data files for testing simreps2openfret.

## Contributions
Contributions to this project are welcome! Please open an issue or submit a pull request.
