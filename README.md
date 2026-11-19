# PPOL 6818 course image

The software environment for PPOL 6818 codespaces: R, Quarto, Git, the GitHub CLI, the `ppol6818` package, Claude Code and Codex, and the course's VS Code setup. A GitHub Action builds it into `ghcr.io/ppol-6818-2027/course-image` every week, and each course repository's `.devcontainer/devcontainer.json` starts from that image, so a new codespace downloads it instead of installing everything.

Students work in desktop VS Code connected to their codespace (the browser is the fallback). The course feature, `.devcontainer/course-tools`, carries the whole VS Code setup in the image's metadata, so a course repository's `devcontainer.json` needs only the image, the machine size, the repository permissions and `"workspaceFolder": "/workspaces"`:

- **Settings and extensions** (`devcontainer-feature.json`, `customizations.vscode`): R, Quarto, Claude Code and Codex; the course colors; the clutter hidden; autosave a second after typing stops; PDFs open in the PDF viewer.
- **The R console** (`ppol6818-console`) is the default terminal: R in the codespace's own repository, whose `.Rprofile` connects it to the agents. Once per codespace start it first updates the `ppol6818` package, and only it, so a fix reaches students without a new image, and registers the R console connector with both agents.
- **When a codespace is made** (`ppol6818-create`): both agents trust the course folders, so neither asks on every window load, and the course's own VS Code extensions are unpacked from `/usr/local/share/ppol6818` into the VS Code server's extension folder, where the server finds them when it first starts. The course extension (`extension/`) sets the layout at startup (files left, `run.R` over the R console, Claude Code right) and gives the course commands a panel; the PDF viewer is a course build of `mathematic.vscode-pdf` without its support notice (`make-vsix.py`). A `postAttachCommand` that installed them never ran in a codespace (tested 2026-11-18), so the image sets none.
- **VS Code's own trust prompt**: on the first open of each codespace VS Code asks "Do you trust the authors of the files in this folder?"; the student clicks **Trust Folder & Continue** once. The setting that turns the prompt off is read only from the student's own VS Code, never from the codespace.

R is held at 4.6 and every R package at one dated snapshot of CRAN (`CRAN_DATE` in `.devcontainer/course-tools/install.sh`), so every codespace has the same versions all term, whenever it was made; the weekly build changes only the `ppol6818` package and the agents. The snapshot is moved once, to a final date in mid-January before the first lab, and then left alone.

RStudio Server and its start script (`ppol6818-rstudio`) stay in the image until the VS Code codespace passes its end-to-end test, then come out.

The image holds software only, never course data.
