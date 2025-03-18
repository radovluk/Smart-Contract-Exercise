FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    build-essential \
    git \
    libssl-dev \
    pkg-config \
    python3 \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Foundry - specify v1.0.0 version here
RUN curl -L https://foundry.paradigm.xyz | bash && \
    . /root/.bashrc && \
    foundryup --install v1.0.0

# Add Foundry to PATH
ENV PATH="/root/.foundry/bin:${PATH}"

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v1.2.5"

# Add Bun to PATH
ENV PATH="/root/.bun/bin:${PATH}"

# Create workdir
WORKDIR /workspace

# Default command
CMD ["bash"]

