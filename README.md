# OpenFRET Utilities
This repository contains utilities for converting to and from the [OpenFRET format](https://github.com/simol-lab/OpenFRET) for single-molecule traces data.

## Installation and running OpenFRET conversion
### Matlab
1. Download or clone the [OpenFRET repository](https://github.com/simol-lab/OpenFRET), and add it + its subfolders to your Matlab path.
2. Download or clone this repository, and add it + its subfolders to your Matlab path.
3. Open traces2openfret.m, add your desired metadata + options, and run.
4. (Optional) Upload resulting .json or .zip files to the [META-SiM Projector](https://www.simol-projector.org/) for visualization and analysis.

## Content
### Matlab
**traces2openfret.m**: Converts single-channel *_traces.dat files OR two-channel *.traces files into the OpenFRET format.  Input file formats:
* *_traces.dat or *_traces.mat: .mat format with traces in rows and frames in columns
* *.traces: ieee-le binary format containing donor and acceptor traces

**test_data**: Folder with data files for testing traces2openfret. Run testAll.m to confirm the conversion is working properly on all test_data types.

## Contributions
Contributions to this project are welcome! Please open an issue or submit a pull request.
