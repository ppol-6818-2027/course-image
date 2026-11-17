#!/bin/bash
# Runs as root while the image is built.
set -euo pipefail
export PATH="/usr/local/share/nvm/current/bin:$PATH"
Rscript -e 'options(repos = c(CRAN = "https://p3m.dev/cran/__linux__/noble/latest"))
install.packages(c("pak", "data.table"))
pak::pak("bbdaniels/ppol6818", ask = FALSE)'
npm install -g --allow-scripts=@anthropic-ai/claude-code @openai/codex @anthropic-ai/claude-code
