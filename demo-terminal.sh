#!/usr/bin/env bash
#
# Create Bash terminal for Software Carpentry lesson
# with the log of the commands at the bottom.

# Session name. Defaults to 'swc', but you can override from the
# calling process.
SESSION="${SESSION:-swc}"

# Where we'll store the executed history. Defaults to /tmp/log-file,
# but you can override from the calling process.
LOG_FILE="${LOG_FILE:-/tmp/$SESSION-split-log-file}"

# The number of lines of history to show. Defaults to 5, but you can
# override from the calling process.
HISTORY_LINES="${HISTORY_LINES:-0}"

# Colour of the prompt. Defaults to 8 (values 0-255 allowed), but you can
# override from the calling process.
PTCOLOR="${PTCOLOR:-8}"

# Style of prompt. Defaults to a simple number.
PROMPT_STYLE="${PROMPT_STYLE:-'n'}"

# If $LOG_FILE exists, truncate it, otherwise create it.
# Either way, this leaves us with an empty $LOG_FILE for tailing.
> "${LOG_FILE}"

# Create the session to be used
# * don't attach yet (-d)
# * name it $SESSION (-s "${SESSION}")
# * use `entr` to watch the log file for changes
#   (ls '${LOG_FILE}' | entr)
# * each time it does, completely clear the pane (-cc), and then
#   in an unmodified Bash subshell (bash --norc) run a command (-c):
#   - use `grep` to filter out lines starting with '#' (if present)
#     since they are the history file's internal timestamps
#   - use `awk` to add line numbers coloured $PTCOLOR
#   - reverse the lines with `tac`
#   - print the first screen of lines with `less` (quitting afterwards)
tmux new-session -d -s "${SESSION}" "ls '${LOG_FILE}' | entr -cc bash --norc -c \"\
  grep -v '^#' '${LOG_FILE}' | \
  awk -v ln=1 '{print \\\"\033[1;38;5;${PTCOLOR}m\\\" ln++ \\\" : \033[0m\\\" \\\$0 }' | \
  tac | \
  less -RX~ +1Gq \""

# Get the unique (and permanent) ID for the new window
WINDOW=$(tmux list-windows -F '#{window_id}' -t "${SESSION}")

# Get the unique (and permanent) ID for the log pane
LOG_PANE=$(tmux list-panes -F '#{pane_id}' -t "${WINDOW}")
LOG_PID=$(tmux list-panes -F '#{pane_pid}' -t "${WINDOW}")

# Split the log-pane (-t "${LOG_PANE}") vertically (-v)
# * put it above the log pane (-b)
# * make the new pane the current pane (no -d)
# * save history to the empty $LOG_FILE (HISTFILE='${LOG_FILE}')
# * lines which begin with a space character are not saved in the
#   history list (HISTCONTROL=ignorespace)
# * Run Bash, but don't apply user customizations (bash --norc)
# * when the Bash process exits, kill the log process
tmux split-window -v -b -t "${LOG_PANE}" \
	"HISTFILE='${LOG_FILE}' HISTCONTROL=ignorespace HOME=~ bash --norc; kill '${LOG_PID}'"

# Get the unique (and permanent) ID for the shell pane
SHELL_PANE=$(tmux list-panes -F '#{pane_id}' -t "${WINDOW}" |
	grep -v "^${LOG_PANE}\$")

tmux send-keys -t "${SHELL_PANE}" " cd ~" enter

# Unset all aliases to keep the environment from diverging from the
# learner's environment.
tmux send-keys -t "${SHELL_PANE}" " unalias -a" enter

# Append new history to $HISTFILE when each command is entered.
# Unlike (PROMPT_COMMAND='history -a'), this method does it before
# the command is run.
tmux send-keys -t "${SHELL_PANE}" " trap 'history -a' DEBUG" enter

# Set nice prompt using $PTCOLOR as a contrasting colour.
if [ "$PROMPT_STYLE" == 'uhp' ]; then
  # `user@host:path/to/cwd$ `
  SET_PS1="export PS1=\"\n\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[1;38;5;${PTCOLOR}m\]user@host\[\033[00m\]:\[\033[1;38;5;${PTCOLOR}m\]\w\[\033[00m\]$ \""
else
  if [ "$PROMPT_STYLE" == 'nuhp' ]; then
    # `1. user@host:path/to/cwd$ `
    SET_PS1="export PS1=\"\n\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[1;38;5;${PTCOLOR}m\]\!\[\033[00m\].\[\033[1;38;5;${PTCOLOR}m\] user@host\[\033[00m\]:\[\033[1;38;5;${PTCOLOR}m\]\w\[\033[00m\]$ \""
  else
    # `1 $ `
    SET_PS1="export PS1=\"\n\[\033[1;38;5;${PTCOLOR}m\]\! $\[\033[0m\] \""
  fi
fi

tmux send-keys -t "${SHELL_PANE}" " ${SET_PS1}" enter

# Set terminal colours
if [ ! -z "$BGCOLOR" ]; then
  tmux select-pane -t "${SHELL_PANE}" -P bg="colour$BGCOLOR"
  tmux select-pane -t "${LOG_PANE}"   -P bg="colour$BGCOLOR"
fi

sleep 0.1

# Clear the history so it starts over at number 1.
# The script shouldn't run any more non-shell commands in the shell
# pane after this.
tmux send-keys -t "${SHELL_PANE}" " history -c" enter

# Send Bash the clear-screen command (see clear-screen in bash(1))
tmux send-keys -t "${SHELL_PANE}" "C-l"

# Wait for Bash to act on the clear-screen.  We need to push the
# earlier commands into tmux's scrollback before we can ask tmux to
# clear them out.
sleep 0.1

# Clear tmux's scrollback buffer so it matches Bash's just-cleared
# history.
tmux clear-history -t "${SHELL_PANE}"

# Resize the log window to show the desired number of lines
if (( HISTORY_LINES > 0 )); then
  # Need account for blank line added to the end
  LOG_PANE_HEIGHT=$((${HISTORY_LINES} + 1))
  tmux resize-pane -t "${LOG_PANE}" -y "${LOG_PANE_HEIGHT}"
else
  # Use Golden Ratio (approx) instead.
  tmux resize-pane -t "${LOG_PANE}" -y 38%
fi

# Turn off tmux's status bar, because learners won't have one in their
# terminal.
# * don't print output to the terminal (-q)
# * set this option at the window level (-w).  I'd like new windows in
#   this session to get status bars, but it doesn't seem like there
#   are per-window settings for 'status'.  In any case, the -w doesn't
#   seem to cause any harm.
tmux set-option -t "${WINDOW}" -q -w status off

tmux attach-session -t "${SESSION}"

###############################################################################
#
# The MIT License (MIT)
# Copyright (c) 2015 Raniere Silva
# 
# Adaptations made 2022 (onwards) by Alex Ball.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.
