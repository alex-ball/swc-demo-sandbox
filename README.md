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
for running simple commands as the `ubuntu` user in a given container.

If the `usercmd` alias already exists, the existing definition will be printed
to the screen before it is clobbered, so you have a chance to save it under a
different name or restore it after finishing with this code.

## Additional setup steps before a given workshop

To erase any previous changes:

```bash
lxc restore swc clean
```

Additional setup for individual lessons:

  - SWC Shell lesson

    ```bash
    lxc usercmd swc --env CMD=setup-shell.sh
    ```

    This installs the latest data files under `~/Desktop/shell-lesson-data`.

  - LC Shell lesson

    ```bash
    lxc usercmd swc --env CMD=setup-lcshell.sh
    ```

    This installs the latest data files under `~/Desktop/shell-lesson`.

  - SWC Git lesson (probably not necessary)

    ```bash
    lxc usercmd swc --env CMD=setup-git.sh
    ```

    This installs a couple of Mars pictures (source: NASA/JPL/Cornell) as
    `~/Pictures/sky/mars.jpg` and `~/Pictures/surface/mars.jpg` in case you
    would rather use these than random binary files.

The technical difficulties associated with accessing Jupyter Lab or RStudio
inside a Linux Container means this is more trouble than it is worth: run
these lessons directly on your computer.

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

I recommend stopping the container if you don't need it, so it doesn't take up
system resources:

```bash
lxc stop swc
```

Once it is stopped, you can update your container to the latest code:

```bash
lxc delete swc
./make-swc-lxc.sh
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

To see what the numeric colours look like on your terminal, run this:

```bash
for i in {0..255} ; do echo -en "\e[1;38;5;${i}m#\e[0m $i\n" ; done
```
