#!/usr/bin/env bash
# bridgeman_v3.5.1.sh

# Main Pipeline Script for Genome Polisher Pipeline

# Exit immediately if a command exits with a non-zero status
set -euo pipefail
IFS=$'\n\t'

# Trap to catch errors and log them
trap 'log_error "Script exited with status $? due to an error."; exit' ERR

# ============================
# Define and Export MODULES_DIR
# ============================

# Determine the directory where the script resides
MODULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../modules" && pwd)"
export MODULES_DIR

# Verify that the modules directory exists
if [ ! -d "$MODULES_DIR" ]; then
    echo "Error: Modules directory '$MODULES_DIR' does not exist." >&2
    exit 1
fi

# ============================
# Source Configuration and Logging Modules
# ============================

source "${MODULES_DIR}/config.sh"
source "${MODULES_DIR}/logging.sh"

# ============================
# Initialize Logging Before Parsing Arguments
# ============================

# Use a default value for LOG_FILE if it is not provided by the user
: "${LOG_FILE:=LOG.txt}"
initialize_logging

# ============================
# Parse Command-Line Arguments
# ============================

source "${MODULES_DIR}/arg_parsing.sh"
parse_args "$@"

# ============================
# Log Initial Configuration
# ============================

log_separator
log_info "Genome Polisher Pipeline Started"
log_info "Working Directory: ${WKDIR}"
log_info "Output Directory: ${OUTDIR}"
log_info "Log File: ${LOG_FILE}"
log_info "Program Output File: ${PROGRAM_OUTPUT_FILE:-N/A}"
log_info "Long Reads File (LR): ${LR}"
log_info "Short Reads File SR1: ${SR1:-Not Provided}"
log_info "Short Reads File SR2: ${SR2:-Not Provided}"
log_info "Contigs File (CTG): ${CTG}"
log_info "Prefix: ${PREFIX}"
log_info "Threads: ${THREADS}"
log_info "Max Racon Iterations: ${MAXITER}"
log_info "Racon Memory Limit: ${RACON_MEM}G"
log_info "Java Heap Size: ${JAVA_HEAP}"
log_info "Pilon JAR Path: ${PILON_JAR:-Not Provided}"
log_info "Short Reads Provided: ${SHORT_READS_PROVIDED}"
log_info "Cleanup Intermediate Files: ${CLEAN_INTERMEDIATE}"
log_info "Resume Pipeline: ${RESUME}"
log_info "Dry Run: ${DRY_RUN}"
log_separator

# ============================
# Handle Dry Run
# ============================

if [ "${DRY_RUN}" = true ]; then
    log_info "Performing dry run..."
    log_info "Dry run completed successfully."
    exit 0
fi

# ============================
# Source Remaining Modules
# ============================

source "${MODULES_DIR}/utils.sh"
source "${MODULES_DIR}/env_check.sh"
source "${MODULES_DIR}/polishing.sh"

# ============================
# Setup Directories
# ============================

setup_directories

# ============================
# Validate Input Files
# ============================

# Add a simple validate_inputs function to check essential files
validate_inputs() {
    if [ ! -f "${LR}" ]; then
        log_error "Long reads file '${LR}' not found. Please check the file path."
        exit 1
    fi

    if [ ! -f "${CTG}" ]; then
        log_error "Contigs file '${CTG}' not found. Please check the file path."
        exit 1
    fi

    if [ -n "${SR1}" ] && [ ! -f "${SR1}" ]; then
        log_warning "Short reads file SR1 '${SR1}' not found. Pilon polishing will be skipped."
    fi

    if [ -n "${SR2}" ] && [ ! -f "${SR2}" ]; then
        log_warning "Short reads file SR2 '${SR2}' not found. Pilon polishing will be skipped."
    fi

    # Ensure PILON_JAR is defined if short reads are provided
    if [ "${SHORT_READS_PROVIDED}" = true ] && [ -z "${PILON_JAR:-}" ]; then
        log_warning "Pilon JAR path (--pilon-jar) is not provided. Please provide the Pilon JAR path and use the resume function for Pilon polishing."
    fi
}

validate_inputs

# ============================
# Manage Conda Environment
# ============================

manage_conda_environment

# ============================
# Run the Polishing Pipeline
# ============================

run_pipeline

# ============================
# Log Pipeline Completion
# ============================

log_info "Genome Polisher Pipeline completed successfully."
log_separator

# ============================
# Close Logging File Descriptor
# ============================

exec 3>&-

exit 0
