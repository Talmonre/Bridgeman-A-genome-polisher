#!/usr/bin/env bash
# modules/arg_parsing.sh

# ============================================================
# Genome Polisher Pipeline Argument Parsing Module
# ============================================================
#
# This module parses command-line arguments provided by the
# user, validates them, and sets the corresponding configuration
# variables. It allows users to override default settings
# defined in config.sh.
#
# Supported Options:
#   --workdir DIR             Set the working directory
#   --output DIR              Set the output directory
#   --prefix PREFIX           Set the prefix for output files
#   --long-reads FILE         Specify the long reads FASTQ file
#   --short-reads1 FILE       Specify the first short reads FASTQ file (optional)
#   --short-reads2 FILE       Specify the second short reads FASTQ file (optional)
#   --contigs FILE            Specify the contigs FASTA file
#   --threads N               Set the number of threads
#   --max-iter N              Set the maximum number of Racon iterations
#   --racon-mem N             Set Racon memory limit in GB
#   --java-heap SIZE          Set Java heap size
#   --conda-env ENV           Set the Conda environment name
#   --read-type TYPE          Specify the read type for Minimap2 (ont or pacbio, default: ont)
#   --verbose                 Enable verbose logging
#   --resume                  Resume the pipeline from the last completed step
#   --dry-run                 Perform a dry run without executing commands
#   --clean                   Clean up intermediate files after pipeline completion
#   --help                    Display this help message and exit
#
# ============================================================

# Default values before argument parsing
VERBOSE=false
RESUME=false
DRY_RUN=false
CLEAN_INTERMEDIATE=false
SHORT_READS_PROVIDED=false
READ_TYPE="ont"  # Default read type for minimap2

# Function to display usage information
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Genome Polisher Pipeline Argument Options:

  --workdir DIR             Set the working directory (default: ${DEFAULT_WKDIR})
  --output DIR              Set the output directory (default: ${DEFAULT_OUTDIR})
  --prefix PREFIX           Set the prefix for output files (default: ${DEFAULT_PREFIX})
  --long-reads FILE         Specify the long reads FASTQ file (default: ${DEFAULT_LR})
  --short-reads1 FILE       Specify the first short reads FASTQ file (optional)
  --short-reads2 FILE       Specify the second short reads FASTQ file (optional)
  --contigs FILE            Specify the contigs FASTA file (default: ${DEFAULT_CTG})
  --threads N               Set the number of threads (default: ${DEFAULT_THREADS})
  --max-iter N              Set the maximum number of Racon iterations (default: ${DEFAULT_MAXITER})
  --racon-mem N             Set Racon memory limit in GB (default: ${DEFAULT_RACON_MEM})
  --java-heap SIZE          Set Java heap size (default: ${DEFAULT_JAVA_HEAP})
  --conda-env ENV           Set the Conda environment name (default: ${DEFAULT_CONDA_ENV})
  --read-type TYPE          Specify the read type for Minimap2 (ont or pacbio, default: ${READ_TYPE})
  --verbose                 Enable verbose logging
  --resume                  Resume the pipeline from the last completed step
  --dry-run                 Perform a dry run without executing commands
  --clean                   Clean up intermediate files after pipeline completion
  --help                    Display this help message and exit

EOF
}

# Function to parse and set arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --workdir)
                WKDIR="$2"
                shift 2
                ;;
            --output)
                OUTDIR="$2"
                shift 2
                ;;
            --prefix)
                PREFIX="$2"
                shift 2
                ;;
            --long-reads)
                LR="$2"
                shift 2
                ;;
            --short-reads1)
                SR1="$2"
                SHORT_READS_PROVIDED=true
                shift 2
                ;;
            --short-reads2)
                SR2="$2"
                SHORT_READS_PROVIDED=true
                shift 2
                ;;
            --contigs)
                CTG="$2"
                shift 2
                ;;
            --threads)
                THREADS="$2"
                shift 2
                ;;
            --max-iter)
                MAXITER="$2"
                shift 2
                ;;
            --racon-mem)
                RACON_MEM="$2"
                shift 2
                ;;
            --java-heap)
                JAVA_HEAP="$2"
                shift 2
                ;;
            --conda-env)
                CONDA_ENV="$2"
                shift 2
                ;;
            --read-type)
                READ_TYPE_INPUT="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --resume)
                RESUME=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --clean)
                CLEAN_INTERMEDIATE=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate READ_TYPE if provided
    if [ -n "${READ_TYPE_INPUT:-}" ]; then
        case "${READ_TYPE_INPUT,,}" in  # Convert to lowercase
            ont|pacbio)
                READ_TYPE="${READ_TYPE_INPUT,,}"
                ;;
            *)
                log_error "Invalid read type: ${READ_TYPE_INPUT}. Supported types are 'ont' or 'pacbio'."
                usage
                exit 1
                ;;
        esac
    fi

    # Export variables for use in the pipeline
    export WKDIR OUTDIR PREFIX LR SR1 SR2 CTG THREADS MAXITER RACON_MEM JAVA_HEAP CONDA_ENV VERBOSE RESUME DRY_RUN CLEAN_INTERMEDIATE SHORT_READS_PROVIDED READ_TYPE

    # Validate Numeric Arguments
    if ! [[ "$THREADS" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Invalid number of threads: $THREADS. Must be a positive integer."
        exit 1
    fi

    if ! [[ "$MAXITER" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Invalid number of Racon iterations: $MAXITER. Must be a positive integer."
        exit 1
    fi

    if ! [[ "$RACON_MEM" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Invalid Racon memory limit: $RACON_MEM. Must be a positive integer representing GB."
        exit 1
    fi

    # Logging Usage of Configured Variables
    log_info "Configuration Summary:"
    log_info "  Working Directory: $WKDIR"
    log_info "  Output Directory: $OUTDIR"
    log_info "  Prefix: $PREFIX"
    log_info "  Long Reads File (LR): $LR"
    log_info "  Short Reads File 1 (SR1): ${SR1:-Not Provided}"
    log_info "  Short Reads File 2 (SR2): ${SR2:-Not Provided}"
    log_info "  Contigs File (CTG): $CTG"
    log_info "  Threads: $THREADS"
    log_info "  Max Racon Iterations: $MAXITER"
    log_info "  Racon Memory Limit: ${RACON_MEM}G"
    log_info "  Java Heap Size: $JAVA_HEAP"
    log_info "  Conda Environment: $CONDA_ENV"
    log_info "  Cleanup Intermediate Files: $CLEAN_INTERMEDIATE"
    log_info "  Resume Pipeline: $RESUME"
    log_info "  Dry Run: $DRY_RUN"
    log_info "  Verbose Logging: $VERBOSE"
    log_info "  Read Type for Minimap2: $READ_TYPE"
    log_info "  Short Reads Provided: $SHORT_READS_PROVIDED"



}


