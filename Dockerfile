# ── Stage 1: Build Demoni Bridge ─────────────────────────────────────
FROM node:22-bookworm-slim AS bridge-builder
WORKDIR /app
COPY bridge/package*.json ./
RUN npm install --no-audit --no-fund
COPY bridge/tsconfig.json ./
COPY bridge/src ./src
RUN npx tsc

# ── Stage 2: Build Demoni CLI ───────────────────────────────────────
FROM node:22-bookworm-slim AS cli-builder
WORKDIR /app
COPY package*.json ./
RUN npm install --no-audit --no-fund
COPY tsconfig.json ./
COPY src ./src
RUN npx tsc

# ── Stage 3: Final Image ────────────────────────────────────────────
FROM node:22-bookworm-slim

# Install runtime deps only — keep it minimal
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*

# Directories
WORKDIR /opt/demoni
RUN mkdir -p bin bridge config /workspace /home/demoni/.demoni

# Install official Gemini CLI (global npm)
ARG GEMINI_CLI_NPM_VERSION=0.42.0
RUN npm install -g @google/gemini-cli@${GEMINI_CLI_NPM_VERSION}

# Copy Demoni CLI
COPY --from=cli-builder /app/dist /opt/demoni/dist
COPY --from=cli-builder /app/node_modules /opt/demoni/node_modules
COPY --from=cli-builder /app/package.json /opt/demoni/package.json

# Copy Demoni Bridge
COPY --from=bridge-builder /app/dist /opt/demoni/bridge/dist
COPY --from=bridge-builder /app/package.json /opt/demoni/bridge/package.json
COPY --from=bridge-builder /app/node_modules /opt/demoni/bridge/node_modules

# Copy shell wrappers and config
COPY bin/ /opt/demoni/bin/
COPY config/ /opt/demoni/config/
RUN chmod +x /opt/demoni/bin/*

# Set up non-root demoni user
RUN groupadd -g 10001 demoni \
    && useradd -u 10001 --gid demoni --create-home --shell /bin/bash demoni \
    && chown -R demoni:demoni /workspace /home/demoni /opt/demoni

# Environment — bridge will pick an ephemeral port, DEMONI_BRIDGE_PORT only as fallback
ENV PATH="/opt/demoni/bin:${PATH}" \
    TERM="xterm-256color" \
    COLORTERM="truecolor" \
    HOME="/home/demoni" \
    DEMONI_HOME="/home/demoni/.demoni" \
    DEMONI_BRIDGE_MODE="process" \
    DEMONI_TRANSLATOR_MODE="custom" \
    DEMONI_BRIDGE_HOST="127.0.0.1" \
    DEMONI_GEMINI_HOME="/home/demoni/.demoni/gemini-cli-home" \
    DEMONI_WORKDIR="/workspace" \
    DEMONI_MODEL="v4-flash-thinking" \
    DEMONI_REASONING_EFFORT="high"

USER demoni
WORKDIR /workspace

ENTRYPOINT ["node", "/opt/demoni/dist/cli.js"]
CMD []
