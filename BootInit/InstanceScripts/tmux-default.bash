#!/usr/bin/env bash
if [ ! -d "${HOME}/tmp" ]; then
  mkdir "${HOME}/tmp"
fi
cd "${HOME}/tmp"
tmux has-session -t "$(hostname)" && tmux attach-session -t "$(hostname)" || tmux new-session -s "$(hostname)"\; \
     split-window -h \; \
     send-keys 'htop' C-m\; \
     split-window -v\; \
     select-pane -t 1\;
