#!/bin/bash
# Runs as root while the image is built.
set -euo pipefail
export PATH="/usr/local/share/nvm/current/bin:$PATH"
Rscript -e 'options(repos = c(CRAN = "https://p3m.dev/cran/__linux__/noble/latest"))
install.packages(c("pak", "data.table", "fixest"))
pak::pak("bbdaniels/ppol6818", ask = FALSE)'
npm install -g --allow-scripts=@anthropic-ai/claude-code @openai/codex @anthropic-ai/claude-code
# The start script each course repository's devcontainer.json runs.
install -m 755 "$(dirname "$0")/ppol6818-rstudio" /usr/local/bin/ppol6818-rstudio
# RStudio suspends an R session left idle for 30 minutes (its default is two
# hours), which ends the start script's keep-awake lines; see ppol6818-rstudio.
conf=/etc/rstudio/rsession.conf
grep -v '^session-timeout-minutes=' "$conf" 2>/dev/null > /tmp/rsession.conf || true
echo "session-timeout-minutes=30" >> /tmp/rsession.conf
install -m 644 /tmp/rsession.conf "$conf" && rm /tmp/rsession.conf
