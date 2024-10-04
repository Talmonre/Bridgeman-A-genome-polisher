#!/usr/bin/env bash
# modules/polishing.sh

# Polishing Module for Genome Polisher Pipeline

# ============================================================
# Genome Polisher Pipeline Polishing Module
# ============================================================
#
# This module contains functions to perform polishing steps
# using Racon, Medaka, and Pilon. It manages iterations,
# handles resume capabilities, and ensures organized output
# management.
#
# Functions:
#   - run_racon_iteration: Performs a single Racon iteration
#   - run_medaka: Performs Medaka polishing
#   - run_pilon_iteration: Performs a single Pilon iteration
#   - run_pilon: Manages Pilon polishing iterations
#   - run_pipeline: Orchestrates the entire polishing pipeline
#
# Dependencies:
#   - External tools: minimap2, racon, medaka, samtools, pilon, bwa
#   - Modules: logging.sh, utils.sh
#
# ============================================================

# Function to perform a single Racon iteration
run_racon_iteration() {
    local iteration="$1"
    local assembly="$2"
    local reads="$3"

    local racon_dir="${ASSEMBLIES_DIR}/racon_iter${iteration}"
    local alignment_paf="${racon_dir}/alignment_iter${iteration}.paf"
    local racon_output="${racon_dir}/${PREFIX}_racon_iter${iteration}.fasta"

    # Create the Racon iteration directory if it doesn't exist
    mkdir -p "$racon_dir" || { log_error "Failed to create Racon directory: $racon_dir"; exit 1; }
    log_info "Racon Iteration $iteration: Directory created at $racon_dir"

    # Check if Racon output already exists for resume capability
    if [ -f "$racon_output" ]; then
        log_skip "Racon Iteration $iteration: Output already exists at $racon_output"
        ASSEMBLY="$racon_output"  # Update assembly for the next iteration
        return
    fi

    log_info "Racon Iteration $iteration: Started polishing..."

    # Determine the minimap2 preset based on read type
    case "${READ_TYPE}" in
        ont)
            MINIMAP2_PRESET="map-ont"
            ;;
        pacbio)
            MINIMAP2_PRESET="map-pb"
            ;;
        *)
            log_error "Unsupported read type: ${READ_TYPE}. Supported types are 'ont' or 'pacbio'."
            exit 1
            ;;
    esac

    # Step 1: Minimap2 alignment of long reads to current assembly
    run_and_log minimap2 -x "${MINIMAP2_PRESET}" -t "$THREADS" "$assembly" "$reads" > "$alignment_paf"
    log_info "Racon Iteration $iteration: Minimap2 alignment completed. Output PAF: $alignment_paf"

    # Step 2: Run Racon polishing
    run_and_log racon -t "$THREADS" "$reads" "$alignment_paf" "$assembly" > "$racon_output"
    log_info "Racon Iteration $iteration: Racon polishing completed. Output FASTA: $racon_output"

    # Update assembly for the next iteration
    ASSEMBLY="$racon_output"

    # Optional cleanup of intermediate PAF file
    if [ "$CLEAN_INTERMEDIATE" = true ]; then
        run_and_log rm -f "$alignment_paf" || { log_warning "Failed to remove intermediate PAF file: $alignment_paf"; }
        log_info "Racon Iteration $iteration: Removed intermediate PAF file: $alignment_paf"
    fi
}

# Function to perform Medaka polishing
run_medaka() {
    local assembly="$1"

    local medaka_dir="${ASSEMBLIES_DIR}/medaka"
    local medaka_output="${medaka_dir}/${PREFIX}_medaka_consensus.fasta"

    # Create the Medaka directory if it doesn't exist
    mkdir -p "$medaka_dir" || { log_error "Failed to create Medaka directory: $medaka_dir"; exit 1; }
    log_info "Medaka: Directory ensured at $medaka_dir"

    # Check if Medaka output already exists for resume capability
    if [ -f "$medaka_output" ]; then
        log_skip "Medaka Polishing: Output already exists at $medaka_output"
        FINAL_ASSEMBLY="$medaka_output"
        return
    fi

    log_info "Medaka: Started polishing..."

    # Run Medaka consensus
    run_and_log medaka_consensus -i "$LR" -d "$assembly" -o "${medaka_dir}/medaka_output" -t "$THREADS"
    FINAL_ASSEMBLY="${medaka_dir}/medaka_output/consensus.fasta"
    run_and_log cp "$FINAL_ASSEMBLY" "$medaka_output"
    log_info "Medaka: Consensus assembly saved to $medaka_output"

    # Optional cleanup of Medaka output directory
    if [ "$CLEAN_INTERMEDIATE" = true ]; then
        run_and_log rm -rf "${medaka_dir}/medaka_output" || { log_warning "Failed to remove Medaka output directory: ${medaka_dir}/medaka_output"; }
        log_info "Medaka: Removed Medaka output directory: ${medaka_dir}/medaka_output"
    fi
}

# Function to perform a single Pilon iteration
run_pilon_iteration() {
    local iteration="$1"
    local assembly="$2"

    local pilon_dir="${ASSEMBLIES_DIR}/pilon_iter${iteration}"
    local pilon_output="${pilon_dir}/${PREFIX}_pilon_iter${iteration}.fasta"
    local pilon_bam="${pilon_dir}/pilon_aligned_iter${iteration}.bam"

    # Check if Pilon JAR is available
    if [ -z "${PILON_JAR:-}" ]; then
        log_warning "Pilon JAR path is not set. Skipping Pilon polishing."
        return
    fi

    # Create the Pilon iteration directory if it doesn't exist
    mkdir -p "$pilon_dir" || { log_error "Failed to create Pilon directory: $pilon_dir"; exit 1; }
    log_info "Pilon Iteration $iteration: Directory created at $pilon_dir"

    # Check if Pilon output already exists for resume capability
    if [ -f "$pilon_output" ]; then
        log_skip "Pilon Iteration $iteration: Output already exists at $pilon_output"
        ASSEMBLY="$pilon_output"  # Update assembly for the next iteration
        return
    fi

    log_info "Pilon Iteration $iteration: Started polishing..."

    # Step 1: Align short reads using BWA
    run_and_log bwa index "$assembly"
    run_and_log bwa mem -t "$THREADS" "$assembly" "$SR1" "$SR2" | samtools sort -@ "$THREADS" -o "$pilon_bam"
    run_and_log samtools index "$pilon_bam"
    log_info "Pilon Iteration $iteration: BWA alignment completed. Output BAM: $pilon_bam"

    # Step 2: Run Pilon polishing
    run_and_log java -Xmx"${JAVA_HEAP}" -jar "$PILON_JAR" --genome "$assembly" --frags "$pilon_bam" --output "${PREFIX}_pilon_iter${iteration}" --outdir "$pilon_dir"
    log_info "Pilon Iteration $iteration: Pilon polishing completed. Output FASTA: $pilon_output"

    # Update assembly for the next iteration
    ASSEMBLY="$pilon_output"

    # Optional cleanup of intermediate BAM files
    if [ "$CLEAN_INTERMEDIATE" = true ]; then
        run_and_log rm -f "$pilon_bam" "${pilon_bam}.bai" || { log_warning "Failed to remove Pilon BAM files: $pilon_bam and ${pilon_bam}.bai"; }
        log_info "Pilon Iteration $iteration: Removed Pilon BAM files: $pilon_bam and ${pilon_bam}.bai"
    fi
}

# Function to perform Pilon polishing with multiple iterations
run_pilon() {
    local assembly="$1"

    local pilon_iterations="${MAXITER}"  # Using the same MAXITER for Pilon

    for ((i=1; i<=pilon_iterations; i++)); do
        run_pilon_iteration "$i" "$assembly"
    done

    FINAL_ASSEMBLY="$assembly"
}

# Function to perform the entire polishing pipeline
run_pipeline() {
    log_separator
    log_info "Polishing Pipeline: Starting..."
    log_separator

    # Ensure ASSEMBLIES_DIR is set
    if [ -z "${ASSEMBLIES_DIR:-}" ]; then
        ASSEMBLIES_DIR="${WKDIR}/assemblies"
        export ASSEMBLIES_DIR
        log_info "Polishing Pipeline: Assemblies directory set to $ASSEMBLIES_DIR"
    fi

    # Create assemblies directory if it doesn't exist
    mkdir -p "$ASSEMBLIES_DIR" || { log_error "Failed to create assemblies directory: $ASSEMBLIES_DIR"; exit 1; }
    log_info "Polishing Pipeline: Ensured assemblies directory at $ASSEMBLIES_DIR"

    # Set initial assembly to contigs file
    ASSEMBLY="$CTG"

    # Resume mechanism: Check for the highest completed step
    if [ "$RESUME" = true ]; then
        log_info "Polishing Pipeline: Resuming from the last completed step..."

        # Check for the highest completed Racon iteration
        for ((i=MAXITER; i>=1; i--)); do
            local racon_output="${ASSEMBLIES_DIR}/racon_iter${i}/${PREFIX}_racon_iter${i}.fasta"
            if [ -f "$racon_output" ]; then
                ASSEMBLY="$racon_output"
                log_info "Polishing Pipeline: Found completed Racon iteration $i. Current assembly: $ASSEMBLY"
                break
            fi
        done

        # Check for Medaka polishing
        local medaka_output="${ASSEMBLIES_DIR}/medaka/${PREFIX}_medaka_consensus.fasta"
        if [ -f "$medaka_output" ]; then
            ASSEMBLY="$medaka_output"
            log_info "Polishing Pipeline: Found completed Medaka polishing. Current assembly: $ASSEMBLY"
        fi

        # Check for the highest completed Pilon iteration
        if [ "$SHORT_READS_PROVIDED" = true ]; then
            for ((i=MAXITER; i>=1; i--)); do
                local pilon_output="${ASSEMBLIES_DIR}/pilon_iter${i}/${PREFIX}_pilon_iter${i}.fasta"
                if [ -f "$pilon_output" ]; then
                    ASSEMBLY="$pilon_output"
                    log_info "Polishing Pipeline: Found completed Pilon iteration $i. Current assembly: $ASSEMBLY"
                    break
                fi
            done
        fi
    fi

    # =============================
    # Step 1: Racon Polishing Iterations
    # =============================

    log_info "Polishing Pipeline: Starting Racon polishing iterations..."
    for ((i=1; i<=MAXITER; i++)); do
        run_racon_iteration "$i" "$ASSEMBLY" "$LR"
    done
    log_info "Polishing Pipeline: Racon polishing iterations completed."

    # =============================
    # Step 2: Medaka Polishing
    # =============================

    log_info "Polishing Pipeline: Starting Medaka polishing..."
    run_medaka "$ASSEMBLY"
    log_info "Polishing Pipeline: Medaka polishing completed."

    # =============================
    # Step 3: Conditional Pilon Polishing
    # =============================

    if [ "$SHORT_READS_PROVIDED" = true ]; then
        log_info "Polishing Pipeline: Starting Pilon polishing..."
        run_pilon "$FINAL_ASSEMBLY"
        log_info "Polishing Pipeline: Pilon polishing completed."
    else
        log_info "Polishing Pipeline: Short reads not provided. Skipping Pilon polishing."
        FINAL_ASSEMBLY="$ASSEMBLY"  # Medaka output is the final assembly
    fi

    # =============================
    # Step 4: Final Assembly Output
    # =============================

    local final_output="${OUTDIR}/${PREFIX}_final_assembly.fasta"

    # Check if final output already exists
    if [ -f "$final_output" ]; then
        log_skip "Final Assembly Output: $final_output already exists."
    else
        run_and_log cp "$FINAL_ASSEMBLY" "$final_output" || { log_error "Failed to copy final assembly to $final_output"; exit 1; }
        log_info "Polishing Pipeline: Final assembly saved to $final_output"
    fi

    # =============================
    # Step 5: Cleanup Intermediate Files
    # =============================

    log_info "Polishing Pipeline: Initiating cleanup of intermediate files..."

    if [ "$CLEAN_INTERMEDIATE" = true ]; then
        # Remove all intermediate directories except for essential files
        run_and_log rm -rf "${ASSEMBLIES_DIR}/racon_iter*" "${ASSEMBLIES_DIR}/medaka" "${ASSEMBLIES_DIR}/pilon_iter*" || { log_warning "Failed to clean some intermediate files."; }
        log_info "Polishing Pipeline: Removed intermediate files as per '--clean' flag."
    else
        log_info "Polishing Pipeline: Retaining all intermediate files."
    fi

    log_info "Polishing Pipeline: Cleanup completed."

    log_separator
    log_info "Polishing Pipeline: Completed successfully."
    log_separator
}
