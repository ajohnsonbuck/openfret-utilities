# OpenFRET Utilities
This repository contains utilities for converting to and from the [OpenFRET format](https://github.com/simol-lab/OpenFRET) for single-molecule traces data.

## Installation
### Matlab
1. Download or clone the [OpenFRET repository](https://github.com/simol-lab/OpenFRET), and add it + its subfolders to your Matlab path.
2. Download or clone this repository, and add it + its subfolders to your Matlab path.
3. Open main.m, add your desired metadata + settings, and run.
4. (Optional) Upload resulting .json or .zip files to the [META-SiM Projector](https://www.simol-projector.org/) for visualization and analysis.

## Content
### Matlab
**main.m**: Main script for adding user-defined metadata and options. Calls simreps2openfret.m to write OpenFRET file.
**simreps2openfret.m**: Converts `m x n` single-channel traces files from Matlab SiMREPS analysis into the OpenFRET format.  Input files must be in .mat format with traces in rows and frames in columns.

**test_data**: Folder with data files for testing simreps2openfret.

## Contributions
Contributions to this project are welcome! Please open an issue or submit a pull request.
