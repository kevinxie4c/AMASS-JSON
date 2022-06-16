## Introduction

Tools for generating character skeleton definition from [AMASS data](https://amass.is.tue.mpg.de).

## Usage
The perl script `make-json.pl` is the main program to generate the JSON file defining the character skeleton:
```
usage: ./make-json.pl [options] spec_file

options:
    -o, --outdir=string	    output directory
    -z, --npz               indicate spec_file is a npz file containing AMASS motion data
```
If `-z` flag is set, `spec_file` should be a npz file containing AMASS motion data. Otherwise, `spec_file` should be a plain text file, whose first line should be the gender `male`, `female` or `neutral`. And the second line should be the `beta` parameters: an array of number seperated by spaces.

For example,
```
perl make-json.pl -z -o output data/0005_Walking001_poses.npz
```
will generate a JSON file `output/character.json` using the gender and beta defined in `data/0005_Walking001_poses.npz`.
