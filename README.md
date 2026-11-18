# PPOL 6818 course image

The software environment for PPOL 6818 codespaces: R, RStudio Server, Quarto, Git, the GitHub CLI, the `ppol6818` package, Codex and Claude Code. A GitHub Action builds it into `ghcr.io/ppol-6818-2027/course-image` every week, and each course repository's `.devcontainer/devcontainer.json` starts from that image, so a new codespace downloads it instead of installing everything.

R is held at 4.6 and every R package at one dated snapshot of CRAN (`CRAN_DATE` in `.devcontainer/course-tools/install.sh`), so every codespace has the same versions all term, whenever it was made; the weekly build changes only the `ppol6818` package and the agents. The snapshot is moved once, to a final date in mid-January before the first lab, and then left alone. Each codespace also updates `ppol6818` itself, and nothing else, every time it starts (the start script `ppol6818-rstudio`), so a fix to the package reaches students without a new image.

The image holds software only, never course data.
