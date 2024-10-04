#!/usr/bin/env bash
# modules/config.sh

# ============================================================
# Genome Polisher Pipeline Configuration Module
# ============================================================
#
# This module defines default configuration variables for the
# Genome Polisher Pipeline. Users can override these defaults
# via command-line arguments.
#
# Variables:
#   - WKDIR: Working directory
#   - OUTDIR: Output directory
#   - LOG_FILE: Log file path
#   - PREFIX: Prefix for output files
#   - LR: Long reads FASTQ file
#   - SR1: Short reads FASTQ file 1
#   - SR2: Short reads FASTQ file 2
#   - CTG: Contigs FASTA file
#   - THREADS: Number of threads
#   - MAXITER: Maximum number of Racon iterations
#   - RACON_MEM: Racon memory limit in GB
#   - JAVA_HEAP: Java heap size
#   - CONDA_ENV: Conda environment name
#   - VERBOSE: Verbose logging flag
#   - RESUME: Resume flag
#   - DRY_RUN: Dry run flag
#   - CLEAN_INTERMEDIATE: Cleanup intermediate files flag
#   - READ_TYPE: Read type for Minimap2 (ont or pacbio)
#   - REQUIRED_PACKAGES: Space-separated list of required packages
#
# ============================================================

# Default Configuration Variables

# Working Directory
DEFAULT_WKDIR="/root/pristina/hap1"

# Output Directory
DEFAULT_OUTDIR="polished_assemblies"

# Log File
DEFAULT_LOG_FILE="LOG.txt"

# Prefix for Output Files
DEFAULT_PREFIX="pristina_collapsed"

# Input Files
DEFAULT_LR="/root/pristina/reads/XDOVE_20220627_S64411e_PL100256426-1_A01.ccs.fastq"
DEFAULT_SR1=""
DEFAULT_SR2=""
DEFAULT_CTG="/root/pristina/ref/pristina_ccs.asm.hic.hap1.p_ctg.fasta"

# Resources
DEFAULT_THREADS=4
DEFAULT_MAXITER=3
DEFAULT_RACON_MEM=40  # in GB
DEFAULT_JAVA_HEAP="64G"

# Conda Environment
DEFAULT_CONDA_ENV="genome_correction"

# Logging and Execution Flags
DEFAULT_VERBOSE=false
DEFAULT_RESUME=false
DEFAULT_DRY_RUN=false
DEFAULT_CLEAN_INTERMEDIATE=false  # Set to 'true' to clean up intermediate FASTA files

# Read Type for Minimap2
DEFAULT_READ_TYPE="ont"

# Required Packages (Space-separated)
# Note: Pilon is included as a Conda package, eliminating the need for a separate JAR file
REQUIRED_PACKAGES="minimap2 racon medaka samtools pilon bwa openjdk"

# Short Reads Provided Flag
DEFAULT_SHORT_READS_PROVIDED=false

# Export Variables (Can be overridden by user inputs)
export WKDIR="${DEFAULT_WKDIR}"
export OUTDIR="${DEFAULT_OUTDIR}"
export LOG_FILE="${DEFAULT_LOG_FILE}"
export PREFIX="${DEFAULT_PREFIX}"

export LR="${DEFAULT_LR}"
export SR1="${DEFAULT_SR1}"
export SR2="${DEFAULT_SR2}"
export CTG="${DEFAULT_CTG}"

export THREADS="${DEFAULT_THREADS}"
export MAXITER="${DEFAULT_MAXITER}"
export RACON_MEM="${DEFAULT_RACON_MEM}"
export JAVA_HEAP="${DEFAULT_JAVA_HEAP}"

export CONDA_ENV="${DEFAULT_CONDA_ENV}"

export VERBOSE="${DEFAULT_VERBOSE}"
export RESUME="${DEFAULT_RESUME}"
export DRY_RUN="${DEFAULT_DRY_RUN}"

export CLEAN_INTERMEDIATE="${DEFAULT_CLEAN_INTERMEDIATE}"

export READ_TYPE="${DEFAULT_READ_TYPE}"

export REQUIRED_PACKAGES="${REQUIRED_PACKAGES}"

export SHORT_READS_PROVIDED="${DEFAULT_SHORT_READS_PROVIDED}"

# ============================================================
# Logging of Default Values (For Debugging and Reference)
# ============================================================

log_info() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${timestamp} [INFO]: ${message}"
}

log_info "Loaded Default Configuration:"
log_info "  Working Directory (WKDIR): ${WKDIR}"
log_info "  Output Directory (OUTDIR): ${OUTDIR}"
log_info "  Log File (LOG_FILE): ${LOG_FILE}"
log_info "  Prefix for Output Files (PREFIX): ${PREFIX}"
log_info "  Long Reads File (LR): ${LR}"
log_info "  Short Reads File 1 (SR1): ${SR1:-Not Provided}"
log_info "  Short Reads File 2 (SR2): ${SR2:-Not Provided}"
log_info "  Contigs File (CTG): ${CTG}"
log_info "  Threads (THREADS): ${THREADS}"
log_info "  Max Racon Iterations (MAXITER): ${MAXITER}"
log_info "  Racon Memory Limit (RACON_MEM): ${RACON_MEM} GB"
log_info "  Java Heap Size (JAVA_HEAP): ${JAVA_HEAP}"
log_info "  Conda Environment (CONDA_ENV): ${CONDA_ENV}"
log_info "  Verbose Logging (VERBOSE): ${VERBOSE}"
log_info "  Resume Pipeline (RESUME): ${RESUME}"
log_info "  Dry Run (DRY_RUN): ${DRY_RUN}"
log_info "  Cleanup Intermediate Files (CLEAN_INTERMEDIATE): ${CLEAN_INTERMEDIATE}"
log_info "  Read Type for Minimap2 (READ_TYPE): ${READ_TYPE}"
log_info "  Short Reads Provided (SHORT_READS_PROVIDED): ${SHORT_READS_PROVIDED}"
log_info "  Required Packages (REQUIRED_PACKAGES): ${REQUIRED_PACKAGES}"

# ============================================================
# Validation Functions
# ============================================================

# Function to validate if the input files and directories exist
validate_inputs() {
    log_info "Validating input files and directories..."

    # Check working directory
    if [ ! -d "$WKDIR" ]; then
        log_error "Working directory '${WKDIR}' does not exist."
        exit 1
    fi

    # Check long reads file
    if [ ! -f "$LR" ]; then
        log_error "Long reads file '${LR}' does not exist."
        exit 1
    fi

    # Check contigs file
    if [ ! -f "$CTG" ]; then
        log_error "Contigs file '${CTG}' does not exist."
        exit 1
    fi

    # If short reads are provided, validate them
    if [ "$SHORT_READS_PROVIDED" = true ]; then
        if [ -n "$SR1" ] && [ ! -f "$SR1" ]; then
            log_error "Short reads file 1 '${SR1}' does not exist."
            exit 1
        fi
        if [ -n "$SR2" ] && [ ! -f "$SR2" ]; then
            log_error "Short reads file 2 '${SR2}' does not exist."
            exit 1
        fi
    fi

    log_info "Input validation completed successfully."
}

# Export the validation function for use in other modules
export -f validate_inputs
