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

# Install Node.js 22.14.0 and npm 11.2.0
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@11.2.0

# Create workdir
WORKDIR /workspace

# Default command
CMD ["bash"]