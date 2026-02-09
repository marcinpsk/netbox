FROM mcr.microsoft.com/devcontainers/python:3.12

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PostgreSQL client (for psql debugging)
RUN apt-get update && apt-get install -y postgresql-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
