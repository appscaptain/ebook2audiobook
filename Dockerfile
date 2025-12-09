ARG BASE=python:3.12-slim
FROM ${BASE}

# ---------------------------------------------------------
# CONFIGURATION: CPU MODE
# ---------------------------------------------------------
ARG DOCKER_DEVICE_STR="cpu"
ARG CALIBRE_INSTALLER_URL="https://download.calibre-ebook.com/linux-installer.sh"
ARG ISO3_LANG="eng"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:$PATH"
ENV CALIBRE_DISABLE_CHECKS=1
ENV CALIBRE_DISABLE_GUI=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /app

# 1. Install System Dependencies
RUN set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc g++ make build-essential python3-dev pkg-config curl \
    wget xz-utils bash git libegl1 libopengl0 \
    libx11-6 libglib2.0-0 libnss3 libdbus-1-3 \
    libatk1.0-0 libgdk-pixbuf-2.0-0 \
    libxcb-cursor0 \
    tesseract-ocr tesseract-ocr-eng && \
    # Install Rust (Required for some python tools)
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    # Install Calibre
    wget -nv -O- "$CALIBRE_INSTALLER_URL" | sh /dev/stdin

# 2. Copy source files
COPY . /app
RUN chmod +x /app/ebook2audiobook.sh

# 3. CRITICAL: Install CPU-ONLY Torch first (Saves ~2.5GB space)
# We do this BEFORE the main install script so it doesn't download the GPU version
RUN pip install torch torchaudio --index-url https://download.pytorch.org/whl/cpu

# 4. Run the App's Install Script
RUN set -ex && \
    . "$HOME/.cargo/env" && \
    echo "Building image for Ebook2Audiobook (CPU MODE)" && \
    PATH="$HOME/.cargo/bin:$PATH" /app/ebook2audiobook.sh --script_mode build_docker --docker_device "cpu" && \
    # Cleanup to save space
    apt-get purge -y gcc g++ make build-essential python3-dev pkg-config curl && \
    apt-get autoremove -y --purge && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 7860
ENTRYPOINT ["python3", "app.py", "--script_mode", "full_docker"]
