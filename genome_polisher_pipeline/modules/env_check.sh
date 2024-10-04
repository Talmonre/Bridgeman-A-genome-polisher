#!/usr/bin/env bash
# modules/env_check.sh

# Function to manage the environment and dependencies
manage_conda_environment() {
    log_info "Starting Conda environment setup..."

    # =============================
    # Step 1: Check and Install Conda
    # =============================

    # Check if Conda is installed
    if ! command -v conda &> /dev/null; then
        log_warning "Conda is not installed. Installing Miniconda..."

        # Download and install Miniconda
        wget -O miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
        if [[ $? -ne 0 ]]; then
            log_error "Failed to download Miniconda."
            exit 1
        fi

        bash miniconda.sh -b -p "$HOME/miniconda"
        if [[ $? -ne 0 ]]; then
            log_error "Failed to install Miniconda."
            exit 1
        fi

        export PATH="$HOME/miniconda/bin:$PATH"
        log_info "Miniconda installed successfully."

        # Initialize Conda
        source "$HOME/miniconda/etc/profile.d/conda.sh"
    else
        log_info "Conda is already installed."

        # Initialize Conda
        source "$(conda info --base)/etc/profile.d/conda.sh"
    fi

    # Update Conda
    run_and_log conda update -y conda

    # =============================
    # Step 2: Create Conda Environment with Micromamba
    # =============================

    # Check if the specified Conda environment exists
    if ! conda env list | grep -qw "${CONDA_ENV}"; then
        log_info "Creating Conda environment '${CONDA_ENV}' with Micromamba..."
        run_and_log conda create -y -n "${CONDA_ENV}" micromamba
        if [[ $? -ne 0 ]]; then
            log_error "Failed to create Conda environment '${CONDA_ENV}'."
            exit 1
        fi
        log_info "Conda environment '${CONDA_ENV}' created with Micromamba."
    else
        log_info "Conda environment '${CONDA_ENV}' already exists."
    fi

    # Activate the Conda environment
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate "${CONDA_ENV}"

    # =============================
    # Step 3: Configure Micromamba
    # =============================

    # Ensure MAMBA_ROOT_PREFIX is set to Conda base
    export MAMBA_ROOT_PREFIX=$(conda info --base)
    log_info "Set MAMBA_ROOT_PREFIX to ${MAMBA_ROOT_PREFIX}"

    # =============================
    # Step 4: Install Required Packages with Micromamba
    # =============================

    # Use the REQUIRED_PACKAGES string from config.sh
    if [ -z "${REQUIRED_PACKAGES:-}" ]; then
        log_error "REQUIRED_PACKAGES is not defined. Please check your config.sh file."
        exit 1
    fi

    log_info "Installing required packages into Conda environment '${CONDA_ENV}' using Micromamba..."

    # Clean up the package list to remove any extra whitespace or newlines
    packages=$(echo "${REQUIRED_PACKAGES}" | tr -s '[:space:]' ' ' | tr -d '\n\r')

    # Convert the package list into an array
    IFS=' ' read -r -a package_array <<< "$packages"

    # Validate package names for unexpected whitespace
    for pkg in "${package_array[@]}"; do
        if [[ "$pkg" =~ [[:space:]] ]]; then
            log_warning "Package name '$pkg' contains unexpected whitespace. Please check the REQUIRED_PACKAGES in config.sh."
        fi
    done

    # Install packages using Micromamba, specifying root prefix and environment prefix
    run_and_log micromamba install -y -r "$MAMBA_ROOT_PREFIX" -p "$CONDA_PREFIX" -c conda-forge -c bioconda "${package_array[@]}"
    if [[ $? -ne 0 ]]; then
        log_error "Failed to install required packages using Micromamba."
        exit 1
    fi

    log_info "All required packages installed using Micromamba."

    # =============================
    # Step 5: Set PILON_JAR Path
    # =============================

    # Find the Pilon JAR file
    PILON_JAR_PATH=$(find "$CONDA_PREFIX/share" -name 'pilon*.jar' 2>/dev/null | head -n 1)

    if [ -z "${PILON_JAR_PATH}" ]; then
        log_warning "Pilon JAR file not found in the environment '${CONDA_ENV}'. Pilon-based polishing will be skipped."
    else
        export PILON_JAR="${PILON_JAR_PATH}"
        log_info "Pilon JAR path set to: ${PILON_JAR}"
    fi

    # =============================
    # Step 6: Log Installed Package Versions
    # =============================

    log_info "Logging versions of installed packages..."
    {
        echo "minimap2 version: $(micromamba run -p "$CONDA_PREFIX" minimap2 --version)"
        echo "racon version: $(micromamba run -p "$CONDA_PREFIX" racon --version 2>&1)"
        echo "medaka version: $(micromamba run -p "$CONDA_PREFIX" medaka --version)"
        echo "samtools version: $(micromamba run -p "$CONDA_PREFIX" samtools --version | head -n1)"
        echo "pilon version: $(micromamba run -p "$CONDA_PREFIX" java -jar \"$PILON_JAR\" --version 2>&1 | head -n1)"
        echo "bwa version: $(micromamba run -p "$CONDA_PREFIX" bwa 2>&1 | grep -m1 'Version')"
        echo "OpenJDK version: $(micromamba run -p "$CONDA_PREFIX" java -version 2>&1 | head -n1)"
    } | while read -r line; do
        log_info "$line"
    done

    log_info "Conda environment setup complete."
}
