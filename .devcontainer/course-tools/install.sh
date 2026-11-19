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
# The R console (ppol6818-console) updates the ppol6818 package, and only
# it, each time a codespace starts, as the student: give the student its
# folder, and drop the installer's root-owned lock files, which would refuse
# that update.
rm -rf /usr/local/lib/R/site-library/_cache
chown -R rstudio:staff /usr/local/lib/R/site-library/ppol6818
npm install -g --allow-scripts=@anthropic-ai/claude-code @openai/codex @anthropic-ai/claude-code
here=$(cd "$(dirname "$0")" && pwd)
# The codespace in VS Code: the R console (the default terminal), the steps
# run when a codespace is made and each time VS Code connects (this
# feature's onCreateCommand and postAttachCommand), and the course's own VS
# Code extensions, which ppol6818-start installs: the course extension and
# the course build of the PDF viewer (see make-vsix.py).
for f in ppol6818-console ppol6818-create ppol6818-start; do
  install -m 755 "$here/$f" /usr/local/bin/$f
done
mkdir -p /usr/local/share/ppol6818
ver=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$here/extension/package.json")
python3 "$here/make-vsix.py" pack "$here/extension" "/usr/local/share/ppol6818/ppol6818.course-$ver.vsix"
pdf_version=0.2.7
pdf_sha256=0317ba7b0e93c0fae71657f1c9a45677cac27c469049b98f7bf16050c63cba93
curl -fsSL -o /tmp/vscode-pdf.vsix \
  "https://open-vsx.org/api/mathematic/vscode-pdf/$pdf_version/file/mathematic.vscode-pdf-$pdf_version.vsix"
echo "$pdf_sha256  /tmp/vscode-pdf.vsix" | sha256sum -c -
python3 "$here/make-vsix.py" pdf /tmp/vscode-pdf.vsix "/usr/local/share/ppol6818/ppol6818.vscode-pdf-$pdf_version.vsix"
rm /tmp/vscode-pdf.vsix
# RStudio, kept until the VS Code codespace has passed its end-to-end test:
# the start script the RStudio templates' devcontainer.json runs.
install -m 755 "$here/ppol6818-rstudio" /usr/local/bin/ppol6818-rstudio
# RStudio suspends an R session left idle for 30 minutes (its default is two
# hours), which ends the start script's keep-awake lines; see ppol6818-rstudio.
conf=/etc/rstudio/rsession.conf
grep -v '^session-timeout-minutes=' "$conf" 2>/dev/null > /tmp/rsession.conf || true
echo "session-timeout-minutes=30" >> /tmp/rsession.conf
install -m 644 /tmp/rsession.conf "$conf" && rm /tmp/rsession.conf
