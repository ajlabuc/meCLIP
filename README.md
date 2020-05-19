## Overview of meCLIP 

meCLIP is method to identify m<sup>6</sup>As residues at single-nucleotide resolution using eCLIP. It uses the Snakemake workflow management system to handle analysis of the resulting sequencing reads. The meCLIP analysis pipeline requires minimal input from the user once executed and automatically generates a list of identified m<sup>6</sup>As along with a report summarizing the analysis. The following steps outline installation of Snakemake and execution of the meCLIP workflow. 

### Requirements

If installed as recommended, the pipeline automatically handles the installation of required software. For reference, the following programs are used by meCLIP:

    Snakemake (v5.14.0)
    FastQC (v0.11.7)
    UMI-tools (v1.0.0)
    cutadapt (v2.8)
    STAR (v2.7.1a)
    samtools (v1.9)
    Java (OpenJDK v11.0.6)
    Perl (tested with v5.26.2)
    bedtools (tested with v2.26.0)
    R (tested with v3.6.2) 
      "scales" and "ggplot2" packages
    
The meCLIP pipeline should work on all modern operating systems and has been specifically tested on Ubuntu 18.04.4, OS X 10.15, and Windows 10 (using Windows Subsystem for Linux*).

*For a great guide on installing WSL in Windows and setting up conda, see https://github.com/kapsakcj/win10-linux-conda-how-to

### Conda Installation

The recommended way to setup the meCLIP pipeline is via **conda** because it also enables any software dependencies to be easily installed.

First, install the Miniconda Python3 distribution (download the latest version [here][id], making sure to download the Python3 version):  
\
`bash Miniconda3-latest-Linux-x86_64.sh`  
\
Answer 'yes' to the question about whether conda shall be put into your PATH. You can check that the installation was succesful by running:
\
  `conda list
\
For a successful installation, a list of installed packages appears.

### Prepare a Working Directory

The meCLIP pipeline creates a number of intermediate and temporary files as different underlying tools are executed. In order to keep these files organized and separated from other meCLIP instances, we recommend creating **an indepedent working directory for each meCLIP experiment** (where a single meCLIP experiment would consist of an 'IP' sample with a corresponding 'Input' sample). While there are several ways to accomplish this, the easiest is to simply clone the meCLIP files from GitHub into a new directory for each independent meCLIP experiment.

First, create a new directory in a reasonable place and change into that directory in your terminal:  
\
`mkdir experiment-name`

`cd experiment-name`  
\
Next, clone the meCLIP files from GitHub into that directory:  
\
`git clone https://github.com/ajlabuc/meCLIP.git`  
\
After the pipeline finishes running the meCLIP files themselves can be safely deleted, leaving an independent directory containing all the relevant files from the analysis of that particular experiment.

### Create Conda Environment with Required Software

The **environment.yaml** file that was downloaded from GitHub can be used to install all the software required by meCLIP into an isolated Conda environment. This ensures that the correct version of the software is utilized and any other dependencies are reconciled. To create an environment with the required software:  
\
`conda env create --name meCLIP --file environment.yaml`  
\
To activate the meCLIP environment, execute:  
\
`conda activate meCLIP`  
\
To exit the environment once the analysis is complete, you can execute:  
\
`conda deactivate`  

### Customizing Configuration File

One of the few steps in the meCLIP analysis pipeline that actually requires opening a file is customizing the configuration file. This is where you inform the pipeline where relevant files are on your system, namely the sequencing reads and reference genomes. A sample configuration file is included in the downloaded files and detailed below. 

```
threads: 3

sample_name: experiment_name

reads:
  ip:
    ip_read1: ip_read1
    ip_read2: ip_read2
  input:
    input_read1: input_read1
    input_read2: input_read2

adapters: config/adapterList.txt

motif: RAC

STAR:
  repbase: STAR/repbase_human
  genome: STAR/hg19

genome:
  fasta: genome/GRCh37.p13.genome.fa
  twoBit: genome/GRCh37.p13.genome.2bit
  
metaplotr:
  region_sizes: metaplotr/region_sizes.txt
  hg19_annotation: metaplotr/hg19_annot.sorted.bed
```

* **threads:** defines the number of threads available to the pipeline  

* **sample_name:** easily identifiable name of the experiment (this will be included in most of the file names and titles)  

* **reads:** specifies the location of the paired sequencing read files for the IP and INPUT samples (omit the extension suffix, i.e. 'fastq.gz', as this is assumed and needs to be omitted for proper naming) 

* **adapters:** location of the list of adapters used by FastQC to identify contamination (tab-delinted file containing name and sequence, example included)  

* **motif:** IUPAC definition of the motif that is used to filter m^6^As    

* **STAR:** location of the directories containing the respective STAR indexes for the reference genome and relevant RepBase  

* **genome:** location of the FASTA file and corresponding 2bit file for the reference genome

* **metaplotr:** location of the annotation file used to generate the metagene plot

Note - The aligner indicies, genomes, and corresponding annotations are quite large (45Gb for GRCh37/hg19 genome). Please ensure you have sufficient disk space to store the files before executing the pipeline.

### Execute the Analysis Pipeline

Once the location of the reads and genomes are saved into the configuration file, the analysis pipeline can then be executed simply by executing the following command within the working directory: 

`snakemake`

This will identify m6As in the IP and INPUT samples, cross-reference the two sets to remove any overlaps (to account for mutations not induced by the m<sup>6</sup>As-antibody), and then annotate the resulting m<sup>6</sup>As and generate a report summarizing the analysis.

### Final Remarks

The goal of the meCLIP analysis pipeline is to simplify the identification of m<sup>6</sup>As from sequencing reads by streamlining the workflow so that the vast majority of steps are automatically executed and relevant output files are automatically generated. We hope this pipeline will become a valuable tool for researchers interesting in identifying m<sup>6</sup>As.

[id]: https://conda.io/en/latest/miniconda.html