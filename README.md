# Software Carpentry Demonstration Sandbox

This repository contains code to set up a Bash terminal running inside a Linux
Container, so that it is in a more-or-less fresh installation of a recent
Ubuntu. The primary motivation is to allow an instructor to demonstrate setting
up Git configuration and SSH keys without clobbering their existing setup.

The terminal uses a fork of Raniere Silva's [swc-shell-split-window] script. One
major difference is that the history pane is shown at the bottom rather than the
top, so that the active prompt line is nearer the middle of the window.

[swc-shell-split-window]: https://github.com/rgaiacs/swc-shell-split-window

You must have LXD installed on your system before running the setup script.

## First time setup

```bash
./make-swc-lxc.sh
```

This creates a basic LXC image instance `swc` and installs a `usercmd` alias
for running commands as the `ubuntu` user in a given container.

## Additional setup steps before a given workshop

To erase any previous changes:

```bash
lxc restore swc clean
```

Additional setup for individual lessons:

  - Shell lesson

    ```bash
    lxc usercmd swc --env CMD=setup-shell.sh
    ```

    This installs the latest data files under `~/Desktop/shell-lesson-data`.

  - Git lesson (probably not necessary)

    ```bash
    lxc usercmd swc --env CMD=setup-git.sh
    ```

    This installs a couple of Mars pictures (source: NASA/JPL/Cornell) as
    `~/Pictures/sky/mars.jpg` and `~/Pictures/surface/mars.jpg` in case you
    would rather use these than random binary files.

## Using the image for teaching

To launch the demo terminal:

```bash
lxc usercmd swc --env CMD=demo-terminal.sh
```

To launch a second demo terminal:

```bash
lxc usercmd swc --env SESSION=swc2 --env CMD=demo-terminal.sh
```

## Tear down

If you want to remove/replace the container:

```bash
lxc stop swc
lxc delete swc
```

## Demo terminal options

The demo terminal can be customised with the following environment variables:

- `SESSION`: The identifier for the session (default: swc).

- `LOG_FILE`: The location where the log file will be stored (default:
  `/tmp/$SESSION-split-log-file`).

- `HISTORY_LINES`: How many lines of history to be shown (default: 5).

- `BGCOLOR`: Background colour of the session panes (0-255, default: transparent).
  Note that the panes do not necessarily reach the edges, so you will get a border
  consisting of the default terminal background.

- `PTCOLOR`: Colour of the prompt (0-255, default: 8).

You can pass these to the script using the `--env` option of `lxc exec` as in
the examples above.
