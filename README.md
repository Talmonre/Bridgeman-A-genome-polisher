# Bridgeman (Genome Polisher Pipeline)

The Genome Polisher Pipeline is a comprehensive tool for genome assembly polishing using a combination of long and short reads. The pipeline utilizes various tools like Racon, Medaka, and Pilon for iterative polishing to generate high-quality genome assemblies.

## Index
- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Output](#output)
- [Resuming the Pipeline](#resuming-the-pipeline)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Overview

This pipeline is designed to perform sequential rounds of polishing on an input assembly using different tools optimized for specific polishing tasks. It supports the use of long reads (PacBio or ONT) for initial correction and short reads for final polishing, if available.

### Tools Used:
- **Minimap2**: Aligns reads to the genome for subsequent polishing.
- **Racon**: Corrects the assembly based on the long reads.
- **Medaka**: Further improves consensus sequence quality using long reads.
- **BWA** and **Samtools**: Aligns short reads to the assembly (for Pilon step).
- **Pilon**: Uses short reads to correct small errors in the genome.

## Features

- **Multiple Iterations**: Configurable number of polishing iterations for Racon and Pilon.
- **Resume Capability**: Resume the pipeline from the last completed iteration.
- **Logging and Debugging**: Detailed logs of all steps for easier troubleshooting.
- **Customizable Parameters**: Fully adjustable parameters via command line.

## Requirements

- **Linux** or **macOS**
- **Conda** for managing environments (Micromamba used for dependencies)

### Dependencies

- **Minimap2**
- **Racon**
- **Medaka**
- **BWA**
- **Samtools**
- **Pilon**
- **OpenJDK**

The dependencies will be automatically managed by Conda and Micromamba during setup.

## Installation

### 1. Clone the Repository
```bash
$ git clone https://github.com/username/repository-name.git
$ cd repository-name
```

### 2. Set Up Environment
The pipeline requires Conda and Micromamba for managing the environment and dependencies. The dependency list is stored in the config.sh. The script will automatically install Conda, create the environment and install dependencies. However, to create the environment, run:

```bash
./scripts/bridgeman_v3.5.1.sh --conda-env genome_correction
```

## Usage

To run the Genome Polisher Pipeline, use the following command:

```bash
./scripts/bridgeman_v3.5.1.sh \
    --prefix Pristina_hap1 \
    --long-reads /root/pristina/reads/XDOVE_20220627_S64411e_PL100256426-1_A01.ccs.fastq \
    --short-reads1 /root/pristina/reads/short_reads_1.fastq \
    --short-reads2 /root/pristina/reads/short_reads_2.fastq \
    --output polished_assemblies \
    --threads 4 \
    --max-iter 3 \
    --workdir /root/pristina/hap1/ \
    --contigs /root/pristina/ref/pristina_ccs.asm.hic.hap1.p_ctg.fasta \
    --read-type pacbio \
    --conda-env genome_correction \
    --java-heap 96G \
    --racon-mem 96 \
    --dry-run \
    --clean
```

### Command Line Arguments
- `--workdir DIR` : Set the working directory (default: `/root/pristina/hap1/`).
- `--output DIR` : Set the output directory (default: `polished_assemblies`).
- `--prefix PREFIX` : Set the prefix for output files.
- `--long-reads FILE` : Specify the long reads FASTQ file.
- `--short-reads1 FILE` : Specify the first short reads FASTQ file (optional).
- `--short-reads2 FILE` : Specify the second short reads FASTQ file (optional).
- `--contigs FILE` : Specify the contigs FASTA file.
- `--threads N` : Set the number of threads.
- `--max-iter N` : Set the maximum number of Racon iterations.
- `--racon-mem N` : Set Racon memory limit in GB.
- `--java-heap SIZE` : Set Java heap size.
- `--conda-env ENV` : Set the Conda environment name.
- `--read-type TYPE` : Specify the read type for Minimap2 (`ont` or `pacbio`).
- `--resume` : Resume the pipeline from the last completed step.
- `--dry-run` : Perform a dry run without executing commands.
- `--clean` : Clean up intermediate files after pipeline completion.
- `--verbose` : Enable verbose logging.

## Output
The pipeline will create polished assemblies in the specified output directory, with multiple intermediate iterations stored for review and troubleshooting. The final polished assembly is labeled with the given prefix and saved as a FASTA file.

## Resuming the Pipeline
If the pipeline fails or is stopped, it can be resumed from the last completed step by using the `--resume` flag. The pipeline will detect the latest successfully completed iteration and continue from there.

## Troubleshooting
- **Logs**: Check the log file (`LOG.txt` by default) for detailed information on each step.
- **Environment Issues**: Ensure that Conda is properly installed and that dependencies are managed using the provided setup.

## Contributing
If you'd like to contribute to the project, please create an issue or submit a pull request. We welcome bug reports, feature requests, and improvements.

## License
This project is licensed under the MIT License. See the `LICENSE` file for more information.

## Acknowledgements
This pipeline is made possible by the hard work of the developers and the open-source community that developed the tools integrated within the Genome Polisher Pipeline.
# Bridgeman-A-genome-polisher-
A long and short read genome polisher for ONT, PacBio, Illumina and reformatted MGI reads. 
