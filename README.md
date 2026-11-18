# Musubi Tuner GUI

This is the workspace repository. The backend
(https://github.com/vjumpkung/musubi-tuner-gui-backend) and the frontend
(https://github.com/vjumpkung/musubi-tuner-gui-frontend) are separate repositories, and
`install.bat` clones them (and the musubi-tuner trainer) into this folder.

## Install on Windows

Requirements:

- An NVIDIA GPU with a recent driver.
- Git.
- Node.js 20.19 or newer, for the web UI build.
- uv and Python 3.12 are installed automatically.

Use a short ASCII path such as `C:\musubi`:

```bat
git clone https://github.com/vjumpkung/musubi-tuner-gui.git C:\musubi
cd C:\musubi
install.bat
```

In PowerShell, type `.\install.bat` (and `.\start.bat`, `.\update.bat`).

Later, start the GUI with `start.bat` (add `--browser` to use your web browser).

For options, environment variables and details, see
https://github.com/vjumpkung/musubi-tuner-gui-backend#run-locally-on-windows.

## Update

Close the GUI, then run `update.bat`. It fast-forwards this workspace repository, the
backend, the frontend and the trainer (`musubi-tuner`) repositories, updates the trainer's
packages, runs `install.bat --rebuild-frontend` and starts the GUI. If local changes or
commits are in the way of a repository, it stops with an error and discards nothing.

| Option           | Effect                                           |
| ---------------- | ------------------------------------------------ |
| `--skip-trainer` | Do not update `musubi-tuner` or its environment. |
| `--no-start`     | Do not run `start.bat` when the update finishes. |

Node.js 20.19 or newer is needed, because the web UI is rebuilt. `update.bat` never
installs the trainer; use `install.bat` for that.
