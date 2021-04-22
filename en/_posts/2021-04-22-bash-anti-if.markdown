---
layout: post
title:  "Bash anti-if"
date:   2021-04-22 19:37:01 +0200
tags:   bash shell
i18n:   2021-04-22_bash_anti_if
---
Bash if-statements often look bloated to me, especially when the script aims to accomplish quite simple goal but needs to perform plenty of sanity checks before proceeding with the actual task. Let's take advantage of shell builtin capabilities to write simpler code.

## The `test` command and logical operators
Instead of writing:
```bash
if [ $# -eq 0 ]; then
  echo Params missing;
  exit 1;
fi
```

we can use the `test` (or `[`) builtin command [^1]:

```bash
test $# -eq 0 && { echo >&2 Params missing; exit 1; }
# or:
[ $# -eq 0 ] && { echo >&2 Params missing; exit 1; }
```

In the latter, `]` is simply the last argument to `[`. Putting `]` is required. I prefer `test` over `[` as it looks less confusing for someone who sees it for first time. Also, with `test` we can take advantage of `_` variable, which is the last argument of previous command:

```bash
test -f ~/.bash_aliases && . "$_" || { echo >&2 "$_ is missing"; exit 1; }
```

I often define `die` function so the code becomes:

```bash
die() {
  echo >&2 "$@"
  exit 1
}
test -f ~/.bash_aliases && . "$_" || die "$_ is missing"
```

Remember to group the commands in curly brackets when you expect they can fail or when not sure; or go with a separate function.

The commands can be chained like this:

```bash
test -x ./configure &&
  ./configure &&
  make &&
  make install ||
  die "Failed to build & install"
```

Many people find such concise constructs undesired as these statements may make one stop and think on the purpose of what is happening there, so they prefer to go with standard if-statements as being more expressive. This argument is perfectly fine and should be definitely considered when working in a team. But it's good to know what are the possibilities.

After all, I am not trying to fight the if-statements (pardon the click-bait 😅). Personally I use these "tricks" only for simple cases. Let's have a look at other shell capabilities we can use no matter if we go with if-statement or `test`.

## Use default values

Let's take a look at parameter expansion and default variable values. That can also help to reduce the number of if-statements.

```bash
target=${1:-${PWD}}
```

If there is an argument provided, use that as the `target`. Otherwise choose current directory.

```bash
echo ${target:=${PWD}}
```

Prints `target` if it is set, otherwise prints `${PWD}` and assigns that value to `target`.

```bash
echo ${target:?"Okay, Houston, we've had a problem here"}
```

When target is not set (or null), prints an error with the message provided and quits (when used non-interactively, like in a script).

```bash
find . -name _config.yml ${name:+-o -name $name}
```

Use alternate value. When `$name` is not set or null, leave it as it is. Otherwise, replace with the alternate value. Results with:

```
find . -name _config.yml
```

or, when `$name` is set and not null:

```
find . -name _config.yml -o -name $name
```

In case the colon is omitted in the examples above the null check is ignored (only unset is verified).

## Reject unset variables by default

You can go one step further and reject any unset variable expansion by default. Just do this:

```bash
set -u
```

Now when you try to expand an unset variable, the shell will print an error and quit.

## Traps

Traps let you register some action to be executed when the script receives a signal. That can be a standard signal (see `kill -l` or `man 7 signal`), but it can also be EXIT [^2]:

```bash
cleanup() {
  rv=$?
  test $rv -ne 0 && rm /tmp/mycache/* -rf
}

trap cleanup EXIT
```

The `cleanup` function will be executed when the script exits (even when the script ends it's life naturally, without explicit `exit` call). Once the trap is registered, you don't have to worry about the cleanup. Traps not only let you write less ifs, they are much more powerful tool (consider `trap cleanup SIGABRT SIGKILL`).

## The null command

There is a special builtin `:` command that is always successful (just like `true`) and does nothing but expands its parameters (and performs redirections if specified). Example:

```bash
: ${target=${PWD}}
```

Here I've reused one of previous examples. The command above sets `target` to current directory when `target` is not set (but leaves `null` untouched as I have used `=` instead of `:=` this time).

## Final words

Bash (and other shells) is really powerful and complex language. I keep learning it and there is always much more to learn, which I find fascinating. If you have enjoyed this post I advice you to read more on the topic. I am not the first one to explore these areas, please check out [Elegant bash conditionals](https://timvisee.com/blog/elegant-bash-conditionals/) by Tim Visée and [Anybody can write good bash (with a little effort)](https://blog.yossarian.net/2020/01/23/Anybody-can-write-good-bash-with-a-little-effort) by William Woodruff, among others.


[^1]: Most often there is also a usual `test`/`[` command on the system, compare the output of `which test` with `type test`.
[^2]: The bash manual specifies more signals supported by `trap`, like RETURN or DEBUG.
