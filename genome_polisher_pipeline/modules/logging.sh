#!/usr/bin/env bash
# modules/logging.sh

# Logging Module for Genome Polisher Pipeline

# Initialize logging by setting up file descriptors and ensuring log files are ready
initialize_logging() {
    # Ensure LOG_FILE is set, with a default value if not provided
    if [ -z "${LOG_FILE:-}" ]; then
        LOG_FILE="LOG.txt"
        log_warning "LOG_FILE is not set. Using default: $LOG_FILE"
    fi

    PROGRAM_OUTPUT_FILE="${LOG_FILE%.txt}_output.txt"

    # Create directories for log files if they do not exist
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$(dirname "$PROGRAM_OUTPUT_FILE")"

    # Create or clear the log files
    : > "$LOG_FILE"
    : > "$PROGRAM_OUTPUT_FILE"

    # Open file descriptor 3 for logging
    exec 3>>"$LOG_FILE"

    # Indicate that logging has been initialized
    LOGGING_INITIALIZED=true

    log_info "Logging initialized. Log file: $LOG_FILE"
}

# Generic log function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    if [ "${LOGGING_INITIALIZED:-}" = true ]; then
        echo "${timestamp} [${level}] : ${message}" >&3
    else
        echo "${timestamp} [${level}] : ${message}" >&2
    fi
}

# Log functions for different levels
log_info() {
    log "INFO" "$@"
}

log_warning() {
    log "WARNING" "$@"
}

log_error() {
    log "ERROR" "$@"
    # Flush logs before exiting
    sync
}

# Function to log a separator
log_separator() {
    log_info "------------------------------------------------------------"
}

# Function to log skipped steps
log_skip() {
    local step="$1"
    log_info "Skipping step: ${step} (already completed)"
}

# Function to execute a command and log its output
run_and_log() {
    local cmd=("$@")
    log_info "Executing command: ${cmd[*]}"
    {
        "${cmd[@]}"
    } >>"$PROGRAM_OUTPUT_FILE" 2>&1
    local exit_status=$?
    if [ $exit_status -ne 0 ]; then
        log_error "Command failed with exit status $exit_status: ${cmd[*]}"
        exit $exit_status
    else
        log_info "Command completed successfully: ${cmd[*]}"
    fi
}

# Function to execute a command within the Conda environment and log its output
run_and_log_conda() {
    if [ -z "${CONDA_ENV:-}" ]; then
        log_error "Conda environment is not set. Cannot run command within the environment."
        exit 1
    fi

    local cmd=("$@")
    log_info "Executing command in Conda environment '${CONDA_ENV}': ${cmd[*]}"
    {
        conda run -n "${CONDA_ENV}" "${cmd[@]}"
    } >>"$PROGRAM_OUTPUT_FILE" 2>&1
    local exit_status=$?
    if [ $exit_status -ne 0 ]; then
        log_error "Command failed with exit status $exit_status in Conda environment '${CONDA_ENV}': ${cmd[*]}"
        exit $exit_status
    else
        log_info "Command completed successfully in Conda environment '${CONDA_ENV}': ${cmd[*]}"
    fi
}

# Function to execute a command within the Conda environment using Micromamba and log its output
run_and_log_micromamba() {
    if [ -z "${CONDA_PREFIX:-}" ]; then
        log_error "CONDA_PREFIX is not set. Cannot run command using Micromamba."
        exit 1
    fi

    local cmd=("$@")
    log_info "Executing command in Conda environment '${CONDA_ENV}' using Micromamba: ${cmd[*]}"
    {
        micromamba run -p "$CONDA_PREFIX" "${cmd[@]}"
    } >>"$PROGRAM_OUTPUT_FILE" 2>&1
    local exit_status=$?
    if [ $exit_status -ne 0 ]; then
        log_error "Command failed with exit status $exit_status in Conda environment '${CONDA_ENV}' using Micromamba: ${cmd[*]}"
        exit $exit_status
    else
        log_info "Command completed successfully in Conda environment '${CONDA_ENV}' using Micromamba: ${cmd[*]}"
    fi
}
