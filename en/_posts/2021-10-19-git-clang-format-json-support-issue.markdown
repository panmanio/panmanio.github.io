---
layout: post
title: "Git clang-format json support issue"
date: 2021-10-19 21:36:53 +0200
tags: git clang-format llvm json
i18n: 2021-10-19_git_clang_format_json_support_issue
---

With a recent update of my Slackware distro *llvm* package was updated to version *13.0*. I've noticed that when `git clang-format`, which I use to keep the code formatting clean in my projects, suddenly started to complain when I have modified a *json* file:

```
Configuration file(s) do(es) not support Json: /home/user/workspace/myproject/.clang-format, /home/user/workspace/.clang-format
error: `clang-format -lines=2:3 -lines=52:52 path/to/file.json` failed
```


That made me unable to commit (`git clang-format` is a required step in my *pre-commit hook*. I needed to get my work done so I've went for a quick fix (without disabling the pre-commit hook) which was to filter-out the files that are touched by `git clang-format`. By default the tool parses all modified files (those tracked by git). The help section (`git clang-format -h`) says it can be changed with *clangFormat.extensions* setting. Used that option to ignore the jsons (global `~/.gitconfig` or local `.git/config` in the project repository):

```
[clangFormat]
    extensions = "cpp,h,hpp,hxx"
```


Once I was done with my urgent task I've tried another way of fixing the issue. The clang-format 13.0 is able to format the json files but it has failed to do so because my `.clang-format` specified the settings for *C++* files only. Solution was to add a section for the json documents:

```
---
Language: Json
BasedOnStyle: llvm
```


That not only removes the error message but also lets *clang-format* to take care of my json files formatting. It's not a perfect solution though as I would like to make it work for any supported file type, but couldn't figure out how to achieve that.
