FROM python:3.12-bookworm

# Create non-root user (expected by Codespaces)
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 -m vscode -s /bin/bash \
    && apt-get update \
    && apt-get install -y sudo \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode

# Install Node.js 20, Yarn, and PostgreSQL client
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs postgresql-client git \
    && npm install -g yarn \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
