# PPOL 6818 course image

The software environment for PPOL 6818 codespaces: R, RStudio Server, Quarto, Git, the GitHub CLI, the `ppol6818` package, Codex and Claude Code. A GitHub Action builds it into `ghcr.io/ppol-6818-2027/course-image` every week, and each course repository's `.devcontainer/devcontainer.json` starts from that image, so a new codespace downloads it instead of installing everything.

The image holds software only, never course data.
