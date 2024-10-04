#!/usr/bin/env bash
# modules/utils.sh

# Utility Functions for Genome Polisher Pipeline

# Enable strict error handling
set -euo pipefail
IFS=$'\n\t'

# Function to set up directories
# Creates:
#   - Working directory (WKDIR)
#   - Output directory (OUTDIR)
#   - Assemblies directory within WKDIR
#   - Temporary directory within WKDIR
#
# Exports:
#   - ASSEMBLIES_DIR: Path to the assemblies directory
#   - TMP_DIR: Path to the temporary directory
setup_directories() {
    log_info "Setting up directories..."

    # Create working directory if it doesn't exist
    if [ ! -d "$WKDIR" ]; then
        if run_and_log mkdir -p "$WKDIR"; then
            log_info "Working directory created at: $WKDIR"
        else
            log_error "Failed to create working directory: $WKDIR"
            exit 1
        fi
    else
        log_info "Working directory already exists at: $WKDIR"
    fi

    # Create output directory if it doesn't exist
    if [ ! -d "$OUTDIR" ]; then
        if run_and_log mkdir -p "$OUTDIR"; then
            log_info "Output directory created at: $OUTDIR"
        else
            log_error "Failed to create output directory: $OUTDIR"
            exit 1
        fi
    else
        log_info "Output directory already exists at: $OUTDIR"
    fi

    # Define and create assemblies directory if not already defined
    if [ -z "${ASSEMBLIES_DIR:-}" ]; then
        ASSEMBLIES_DIR="${WKDIR}/assemblies"
        export ASSEMBLIES_DIR
        log_info "Assemblies directory set to: $ASSEMBLIES_DIR"
    fi

    if [ ! -d "$ASSEMBLIES_DIR" ]; then
        if run_and_log mkdir -p "$ASSEMBLIES_DIR"; then
            log_info "Assemblies directory created at: $ASSEMBLIES_DIR"
        else
            log_error "Failed to create assemblies directory: $ASSEMBLIES_DIR"
            exit 1
        fi
    else
        log_info "Assemblies directory already exists at: $ASSEMBLIES_DIR"
    fi

    # Create temporary directory within the working directory
    if [ -z "${TMP_DIR:-}" ]; then
        # Use a unique prefix incorporating the script name to avoid collisions
        local SCRIPT_NAME
        SCRIPT_NAME=$(basename "$0")
        TMP_DIR=$(mktemp -d "${WKDIR}/tmp.${SCRIPT_NAME}_XXXXXXXXXX") || { log_error "Failed to create temporary directory."; exit 1; }
        export TMP_DIR
        log_info "Temporary directory created at: $TMP_DIR"

        # Set up a trap to clean up the temporary directory upon script exit
        trap 'cleanup_temp_dir' EXIT
    else
        log_info "Temporary directory already set at: $TMP_DIR"
    fi
}

# Function to clean up the temporary directory
cleanup_temp_dir() {
    if [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
        log_info "Temporary directory $TMP_DIR removed."
    fi
}
