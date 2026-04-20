# Software Carpentry Demonstration Sandbox

This repository contains code to set up a Bash terminal running inside a Linux
Container, so that it is in a more-or-less fresh installation of a recent
Ubuntu. The primary motivation is to allow an instructor to demonstrate setting
up Git configuration and SSH keys without clobbering their existing setup.

The terminal uses `demo-terminal.sh`, a fork of Raniere Silva's
[swc-shell-split-window] script. There are several differences, these being the
main two:

- The coding pane is at the top (not the bottom) of the window.

- The history pane in the lower half of the screen shows the command history in
  reverse order. This bit of trickery is achieved with `tac` with assistance
  from `entr` (watching for changes), `awk` (pretty line numbering), and `less`
  (truncating output).

The net effect of this is that the most recent activity is concentrated in the
middle of the screen, with older activity disappearing off the top and bottom.
This makes it a less critical issue if the bottom of the window is being
obscured for some users, and that means the terminal can run full screen.

It is possible to use `demo-terminal.sh` on any platform where `bash`, `grep`,
and the other four tools mentioned above are available, independently of the
Linux Container gubbins described below.

[swc-shell-split-window]: https://github.com/UCL-ARC/swc-shell-split-window

## First time setup

You must have LXC and either LXD or Incus installed on your system before
running the following setup script.

```bash
./make-swc-lxc.sh
```

This creates a basic LXC image instance `swc` and installs a `usercmd` alias
for running simple commands as the `ubuntu` user (i.e. not root) in a given
container.

If the `usercmd` alias already exists, the existing definition will be printed
to the screen before it is clobbered, so you have a chance to save it under a
different name or restore it after finishing with this code.

## Additional setup steps before a given workshop

To erase any previous changes:

```bash
lxc restore swc clean
```

```bash
incus snapshot restore swc clean
```

In all the remaining examples below, the `incus` and `lxc` versions of the
various commands are the same.

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
./make-swc-lxc.sh
```

## Demo terminal options

The demo terminal can be customised with the following environment variables:

- `SESSION`: The identifier for the session (default: swc).

- `LOG_FILE`: The location where the log file will be stored (default:
  `/tmp/$SESSION-split-log-file`).

- `HISTORY_LINES`: How many lines of history to be shown (any sensible integer,
  default: Golden Ratio, i.e. approximately 38% of the window height).

- `BGCOLOR`: Background colour of the session panes (0-255, default: transparent).
  Note that the panes do not necessarily reach the edges, so you will get a border
  consisting of the default terminal background.

- `PTCOLOR`: Colour of the prompt (0-255, default: 8).

- `PROMPT_STYLE`: Style of prompt. Options available:

    - `n`: Number `1 $` (default)
    - `uhp`: Username, host, path `user@host:path$` resembling default Debian
      prompt. Note that `user@host` is literally what it says, for educational
      purposes; it does not use the real values.
    - `nuhp`: Combination of the above `1. user@host:path$`

You can pass these to the script using the `--env` option of `lxc usercmd` as in
the examples above.

To see what the numeric colours look like on your terminal, run this:

```bash
for i in {0..255} ; do echo -en "\e[1;38;5;${i}m#\e[0m $i\n" ; done
```
