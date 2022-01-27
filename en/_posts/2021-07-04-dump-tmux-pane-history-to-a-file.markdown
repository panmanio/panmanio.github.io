---
layout: post
title: "Dump tmux pane history to a file"
date: 2021-07-04 18:43:20 +0200
tags: shell tmux bash
i18n: 2021-07-04_dump_tmux_pane_history_to_a_file
---
Consider you have executed a long lasting command that produced many lines of output; or that you were trying to reproduce a non-deterministic issue with your software that has finally reproduced, and you have hundreds of log lines to analyze. The problem is you forgot to redirect the output to a file 😒.


Your terminal can help to dump its buffer to a file. Alternatively you can select and copy all the lines manually but that is inconvenient and error prone. Another option is to take advantage of terminal multiplexer capabilities, in case you are using one.


With `tmux` you can save last `N` lines of current pane to a file with two consecutive commands:


```tmux
:capture-pane -S -N
:save-buffer ~/filename
```


Replace `N` with desired number, or capture whole pane history with `:capture-pane -S -`.
That can be reduced to a single command when you invoke the `capture-pane` from the command line, like this:


```bash
tmux capture-pane -pS -10000 > ./last-10000-lines.out
```


Or this:


```bash
tmux capture-pane -pS - > ./pane-history
```


Another advantage of using command-line version is that you can store it as a function or alias in your shell, like in bash:


```bash
alias tmux-save-pane='tmux capture-pane -pS -'
```


Now the use is really simple:


```bash
tmux-save-pane > ~/tmux-pane-history
```


That command has helped me in trouble many times, I hope you also find it useful. If you are not using a terminal multiplexer, I really advise to start using one. `tmux` is the multiplexer I use, but as a `vim` addict I can't live with the default `C-b` prefix. First thing to do in my [.tmux.conf](https://github.com/maniowy/dotfiles/blob/master/.tmux.conf) is to change the binding to `C-a` 😉.
