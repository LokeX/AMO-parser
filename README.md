# sstAnoms
Fetches undetrended AMO and Nino3.4 data from the web, calculates and outputs formatted anomalies to file.

Usage:

At the CLI type: sstanom
The script will build 2 files: a column and matrix file for each dataset
and outputs the file.names
If no config file is found one will be build from default settings:
You can edit that config file to customize your own datasets
An sstAnoms dataset is defined as:
- an id: is the first word following the datamatrix and defines the end of data
- a url to the dataset

Valid Parameters:
[file.name] - custom config file
-norm:startYear-endYear - Defines the normalization period
-skip:nr - of initial words to skip after splitWhiteSpace; defines start of data
