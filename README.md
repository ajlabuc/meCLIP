Overview of meCLIP
======

meCLIP is method to identify m<sup>6</sup>As residues at single-nucleotide resolution using eCLIP. It uses the Snakemake workflow management system to handle analysis of the resulting sequencing reads. The meCLIP analysis pipeline requires minimal input from the user once executed and automatically generates a list of identified m<sup>6</sup>As along with a report summarizing the analysis. The following steps outline installation of Snakemake and execution of the meCLIP workflow.

Requirements
------

If installed as recommended, the pipeline automatically handles the installation of required software. For reference, the following programs are used by meCLIP:

    Snakemake (v7.24.2)
    STAR (v2.7.10b)
    SeqKit (v2.3.0)
    BEDOPS (v2.4.41)
    Perl (v5.32.1)
    FastQC (v0.11.7)
    UMI-tools (v1.1.4)
    cutadapt (v4.2)
    samtools (v1.16.1)
    Java (OpenJDK v11.0.15)
    bedtools (v2.30.0)
    R (v4.2.2)
      "scales" and "ggplot2" packages
    MultiQC (v1.14)

The meCLIP pipeline should work on all modern operating systems and has been specifically tested on Ubuntu (Bionic, Focal, Jammy), OS X (10.15), and Windows 10/11 using WSL (for a great guide on installing WSL in Windows, see [here][id2]).

The pipeline itself is not very resource intensive, although providing more cores / threads does speed up execution (for reference, running on a human sample with 11 threads takes ~6-8 hours). The biggest bottleneck is the genome indexing step, which requires at least 16Gb of memory (see [Reference Genome](#reference-genome) section below if this is an issue). The aligner indices, genomes, and corresponding annotations can also be quite large (45Gb for human genome), so please ensure you have sufficient disk space to store the files before executing the pipeline.

Conda Installation
------

The recommended way to setup the meCLIP pipeline is via **conda** because it also enables any software dependencies to be easily installed.

First, download the latest version [here][id] (making sure to download the Python3 version) and then execute the following command:  
\
`bash Miniconda3-latest-Linux-x86_64.sh`  
\
Answer 'yes' to the question about whether conda shall be put into your PATH. You can check that the installation was successful by running:  
\
`conda list`  
\
For a successful installation, a list of installed packages appears.

Prepare Working Directory
------

The meCLIP pipeline creates a number of intermediate and temporary files as different underlying tools are executed. In order to keep these files organized and separated from other meCLIP instances, we recommend creating **an independent working directory for each meCLIP experiment** (where a single meCLIP experiment would consist of an 'IP' sample with a corresponding 'Input' sample). While there are several ways to accomplish this, the easiest is to simply clone the meCLIP files from GitHub into a new directory for each independent meCLIP experiment.

First, create a new directory in a reasonable place to use as your working directory.  
\
`mkdir experiment-name`  
\
Next, clone the meCLIP files from GitHub into that directory:  
\
`git clone https://github.com/ajlabuc/meCLIP.git`  
\
After the pipeline finishes running the meCLIP files themselves can be safely deleted, leaving an independent directory containing all the relevant files from the analysis of that particular experiment.

Create Conda Environment
------

The **environment.yaml** file that was downloaded from GitHub can be used to install all the software required by meCLIP into an isolated Conda environment. This ensures that the correct version of the software is utilized and any other dependencies are reconciled.

The default Conda solver is a bit slow and sometimes has issues with selecting the latest package releases. Therefore, we recommend to install Mamba as a drop-in replacement via:  
\
`conda install -c conda-forge mamba`  
\
Then, to create an environment with the required software:  
\
`mamba env create --name meCLIP --file workflow/envs/environment.yaml`  
\
Finally, to activate the meCLIP environment, execute:  
\
`conda activate meCLIP`  
\
Be sure to exit the environment once the analysis is complete.  

Customize Configuration File
------

One of the few steps in the meCLIP analysis pipeline that actually requires opening a file is customizing the configuration. This is where you inform the pipeline where relevant files are on your system, namely the sequencing reads and reference genomes. A sample configuration file is included in the downloaded files and detailed below.

```
sample_name: meCLIP

resources:
  threads: 11
  ram: 29

reads:
  ip:
    ip_read1: reads/ip_read_1.fq
    ip_read2: reads/ip_read_2.fq
  input:
    input_read1: reads/input_read_1.fq
    input_read2: reads/input_read_2.fq
    
species:
  name: homo_sapiens
  assembly: GRCh38
  release: 109

adapters:
  dna: 
    randomer_size: 10
  rna: 
    name: X1A
    sequence: AUAUAGGNNNNNAGAUCGGAAGAGCGUCGUGUAG
```
* **sample_name:** easily identifiable name of the experiment (this will be included in most of the file names and plot titles)  

* **threads:** defines the number of threads available to the pipeline (we recommend one less than the total number of usable CPU cores)

* **ram:** defines the amount of RAM available to the pipeline (mainly used for genome indexing)

* **reads:** specifies the locations / filenames of the paired sequencing read files for the IP and INPUT samples (relative to working directory)

* **species:** describes the reference species to identify m6A residues in (see 'Reference Genome' below for details)

* **adapters:** details the specific adapters used in the experiment (see 'Adapters' below for details)  

<a id="reference-genome"></a>
### <ins>Reference Genome</ins>
The pipeline will attempt to download the appropriate reference genome automatically based on the information provided in the **species** section of the configuration file. The script attempts to download the 'primary assembly' reference and reverts to the 'top level' reference if there is no primary assembly for that species. Automatic downloading is currently only supported for vertebrates listed in the Ensembl database (see [here][id3]).

* The **name** should be all lowercase with underscores for spaces (see Ensembl link above for proper formatting)

* The **assembly** should be the appropriate reference genome assembly for the indicated species (i.e., GRCh38 for humans)

* The **release** should be the desired Ensembl release number (new releases occur every few months, see [here][id4] for info)

The pipeline will parse the Ensembl FTP site to obtain the reference genome FASTA file and associated GTF annotation. As previously mentioned, automatic downloading is currently only available for vertebrate species. To utilize other organisms (i.e., bacteria, fungi, plants, etc.), reference genomes and annotations can be manually provided using the 'manual-reference-genome.yaml' configuration file located in the 'config' directory.

```
resources:
  threads: 11
  ram: 29

genome:
  fasta: <url-to-fasta-file>
  gtf: <url-to-gtf-file>
```
* **resources:** same as main configuration file, specify available memory and threads for genome indexing / annotation  

* **genome:** URL links (i.e., from FTP site) where the FASTA and GTF files can be downloaded (see sample config file for example)

Once the configuration file has been updated with the desired genome information, the files can be downloaded and annotated with the following command:  
\
`snakemake --snakefile workflow/rules/genome-download.smk --cores N`  
\
The script will download the defined reference files and index / annotate them so that they can be used in the main pipeline. 
### <ins>Adapters</ins>

The meCLIP library preparation consists of adding two separate adapters to the m<sup>6</sup>A containing fragment. The first is a (possibly indexed) RNA adapter that is ligated while the transcript is still on the immunoprecipitation beads, and the second is a ssDNA adapter ssDNA adapter that is ligated to the cDNA following reverse transcription. The ssDNA adapter contains a randomized UMI (either N5 or N10) to determine whether  identical reads are unique transcripts or PCR duplicates of the same RNA fragment. Therefore, the following information should be provided in the **adapter** section of the configuration file:

* The **randomer** should indicate the length of the random UMI sequence of the ssDNA adapter (either 5 or 10)

* The **name** should be the given name of the RNA adapter used in the library prep (see meCLIP / eCLIP paper)

* The **sequence** should be the complete sequence of the RNA adapter used in the library prep

The strategy outlined in the original meCLIP paper was based on the eCLIP protocol which recommend using two different RNA adapters to ensure proper balancing as on the Illumina HiSeq sequencer. Given load balancing is not as much of an issue on more recent instruments, we find it is sufficient to only use a single adapter which is what is assumed by the current version of this pipeline.  

The ends of each adapter are complimentary to the Illumina TruSeq adapters and therefore the resulting reads generally have the following structure where 'Read 1' begins with the RNA adapter and 'Read 2' (corresponding to the sense strand) begins with the UMI followed by a sequence corresponding to the 5′ end of the original RNA fragment.

><ins>Read 1</ins>  
> <mark style="background-color: lightblue">[RNA Adapter (Reverse)]</mark> [Sequenced Fragment (Reverse)] <mark style="background-color: lightgreen">[DNA Adapter]</mark>  
>  
><ins>Read 2</ins>   
> <mark style="background-color: lightgreen">[DNA Adapter (Reverse)]</mark> [Sequenced Fragment] <mark style="background-color: lightblue">[RNA Adapter]</mark> 

Execute the Analysis Pipeline
------

Once the location of the reads and genomes are saved into the configuration file, the analysis pipeline can then be executed simply by executing the following command within the working directory (where 'N' is the number of CPU cores available to the pipeline):  
\
`snakemake --use-conda --cores N`  
\
This will identify m6As in the IP and INPUT samples, cross-reference the two sets to remove any overlaps (to account for mutations not induced by the m<sup>6</sup>A antibody), and then annotate the resulting m<sup>6</sup>As and generate a report summarizing the analysis.

Final Remarks
------

The goal of the meCLIP analysis pipeline is to simplify the identification of m<sup>6</sup>As from sequencing reads by streamlining the workflow so that the vast majority of steps are automatically executed and relevant output files are automatically generated. We hope this pipeline will become a valuable tool for researchers interesting in identifying m<sup>6</sup>As.

Citation
------

If you use this pipeline to identify m6A sites, please cite the following manuscript:

> “Identification of m6A residues at single-nucleotide resolution using eCLIP and an accessible custom analysis pipeline.”  
> *Justin T. Roberts, Allison M. Porman, Aaron M. Johnson.*   
> RNA. 2020 Dec 29;27(4):527-541. [doi:10.1261/rna.078543.120](#id5)

[id]: https://conda.io/en/latest/miniconda.html
[id2]: https://learn.microsoft.com/en-us/windows/wsl/install
[id3]: https://ftp.ensembl.org/pub/current_fasta/
[id4]: https://www.ensembl.info/category/01-release/
[id5]: https://doi.org/10.1261/rna.078543.120