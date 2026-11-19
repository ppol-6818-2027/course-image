#!/bin/bash
# Runs as root while the image is built.
set -euo pipefail
export PATH="/usr/local/share/nvm/current/bin:$PATH"
# Every R package comes from one dated snapshot of CRAN (Posit Package
# Manager's binaries for this Ubuntu), not from the newest CRAN, so every
# codespace, whenever it is made, and the iMac's extract job (course-admin
# prepare.R) have the same versions all term (Ben, 2026-11-18). The weekly
# rebuild then changes only the ppol6818 package and the agents. The date is
# moved by hand, once, before the term starts; it is also where students'
# own install.packages() calls install from.
CRAN_DATE=2026-11-18
. /etc/os-release
repo="https://p3m.dev/cran/__linux__/${VERSION_CODENAME}/${CRAN_DATE}"
site=/usr/local/lib/R/etc/Rprofile.site
grep -v '^options(repos' "$site" 2>/dev/null > /tmp/Rprofile.site || true
echo "options(repos = c(CRAN = '${repo}'), download.file.method = 'libcurl')" >> /tmp/Rprofile.site
install -m 644 /tmp/Rprofile.site "$site" && rm /tmp/Rprofile.site
Rscript -e 'install.packages(c("pak", "data.table", "fixest", "ggplot2", "modelsummary", "tinytable"))
pak::pak("bbdaniels/ppol6818", ask = FALSE)'
# The start script (ppol6818-rstudio) updates the ppol6818 package, and only
# it, each time a codespace starts, as the student: give the student its
# folder, and drop the installer's root-owned lock files, which would refuse
# that update.
rm -rf /usr/local/lib/R/site-library/_cache
chown -R rstudio:staff /usr/local/lib/R/site-library/ppol6818
npm install -g --allow-scripts=@anthropic-ai/claude-code @openai/codex @anthropic-ai/claude-code
# The start script each course repository's devcontainer.json runs.
install -m 755 "$(dirname "$0")/ppol6818-rstudio" /usr/local/bin/ppol6818-rstudio
# RStudio suspends an R session left idle for 30 minutes (its default is two
# hours), which ends the start script's keep-awake lines; see ppol6818-rstudio.
conf=/etc/rstudio/rsession.conf
grep -v '^session-timeout-minutes=' "$conf" 2>/dev/null > /tmp/rsession.conf || true
echo "session-timeout-minutes=30" >> /tmp/rsession.conf
install -m 644 /tmp/rsession.conf "$conf" && rm /tmp/rsession.conf
