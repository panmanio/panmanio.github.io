---
layout: post
title:  "Setting up VIM for blogging"
date:   2021-04-23 23:37:01 +0200
tags:   vim writing
i18n:   2021-04-23_using_vim_for_blogging
---
VIM is the editor I use for programming. It is known for its power at writing code thanks to its built in features and numerous plugins, but how does it serve for blogging? Let's investigate on how to improve its default behavior.

## Spellcheck

Spell checking is built in feature of VIM, but it is disabled by default. I've enabled it with:

```vim
set spell spelllang=en_us
```

That made VIM highlight my spelling errors. I can jump between misspelled words with `]s` and `[s`. With the cursor located on a misspelled word I can type `z=` to get a list of possible fixes. When VIM is wrong I can tell it to accept a word with `zg` (undo with `zw`).

## Abbreviations

VIM supports expansion of user defined abbreviations. For instance, if you define "utl" as an abbreviation of "utility", VIM automatically replaces "utl" with "utility" when typing. This feature can be used for auto correction. Just define:

```vim
:iabbrev veiw view
```

to make VIM replace each "veiw" with "view" on the fly (in insert mode). [Vim-autocorrect](https://github.com/panozzaj/vim-autocorrect) is one of the plugins that come with a set of predefined useful abbreviations so you don't have to provide definitions of the most common ones.

## Dictionary

Next feature is auto completion. It is also supported by default but you may need to provide the dictionary and that was my case. Check if you have `/usr/share/dict/words`. I use Slackware and Ubuntu on daily basis; Slackware happened to have the dictionary installed, but on Ubuntu it was not there. Managed to provide the dict with `sudo apt install wamerican`. That tells VIM to use the dictionary file:

```vim
set dictionary=/usr/share/dict/words
```

Now that the dictionary is set up, it can be used with `<C-x><C-k>` in insert mode.

## Thesaurus

Looking for synonyms? VIM supports thesaurus, however it has to be configured. I was able to configure the built in feature but it needed a [hack](https://www.reddit.com/r/vim/comments/55y53e/allow_spaces_in_thesaurus_entries/) to handle multi word synonyms and I didn't like that. I've decided to install [vim-lexical](https://github.com/preservim/vim-lexical) plugin instead. Just as the built in feature, the plugin needs a synonyms file to work: grabbed one from [Project Gutenberg](https://www.gutenberg.org/ebooks/3200). Tell vim-lexical where the file is and initialize the plugin:


```vim
let g:lexical#thesaurus = ['~/.vim/mthesaur.txt']
call lexical#init()
```

This plugin also handles dictionary and spell check features, I gave it a try. Here are some settings to set it up:

```vim
let g:lexical#spelllang = ['en_us']
let g:lexical#dictionary = ['/usr/share/dict/words']
" normal mode key mappings:
let g:lexical#spell_key = '<leader>s'
let g:lexical#thesaurus_key = '<leader>th'
let g:lexical#dictionary_key = '<leader>k'
```

In insert mode, we can use `<C-x><C-t>` for thesaurus.

## Other plugins

There are more plugins that support the writers, I present some that I have found particularly useful.

# textobj-sentence

[This plugin](https://github.com/preservim/vim-textobj-sentence) provides motion commands based on full sentence detection. You can switch around sentences with `(` and `)` and use it just as any other motion commands. Depends on [vim-textobj-user](https://github.com/kana/vim-textobj-user) plugin.

# wordy

[Wordy](https://github.com/preservim/vim-wordy) lets you identify phrases that are overused, misused, abused, colloquial, idiomatic etc. It's a nice lightweight tool that operates on higher level than just single words. Definitely worth checking out.

# ditto

Struggling with word repetitions? [Ditto](https://github.com/dbmrq/vim-ditto) is there to localize & highlight them for you.

# LSP + proselint

[Proselint](http://proselint.com/) is not a VIM plugin. It is a separate tool described as a linter of English prose. Here are some of its features:

- Avoiding archaic forms
- Avoiding needless backformations
- Avoiding redundant currency symbols
- Avoiding false plurals
- Avoiding illogical forms
- Avoiding the word suddenly
- Avoiding oxymorons
- Calling jobs by the right name
- Not comparing uncomparables
- Using dïacríticâl marks
- Linking only to existing sites

[Full list here](https://github.com/amperser/proselint#checks). Since the tool is a linter, it sounds like it should work with [language servers](https://langserver.org/). I use [CoC.nvim](https://github.com/neoclide/coc.nvim) for LSP features. Thankfully some smart guys have figured out how to make proselint work with coc.nvim & [coc-diagnostic](https://github.com/iamcco/coc-diagnostic) ([see here](https://github.com/neoclide/coc.nvim/discussions/2028)). Now it works for my blog posts just like [clangd](https://clangd.llvm.org/) does for my C++ code.

## Let's see how it works

All these solutions look promising. I've already benefited from including them in my VIM configuration while writing this blog post. Will do further testing and investigation in next days. Didn't try plugins like [vim-pencil](https://github.com/preservim/vim-pencil) or [vim-abolish](https://github.com/tpope/vim-abolish) yet.

Further reading:
- [Using spell checking in VIM](https://www.linux.com/training-tutorials/using-spell-checking-vim/)
- [Using a Thesaurus File in VIM](https://thesynack.com/posts/vim-thesaurus/)
- [VIM Spell Check](https://linuxhint.com/vim_spell_check/)
- [VIM for writing](https://www.naperwrimo.org/wiki/index.php?title=Vim_for_Writers)
- [10 VIM plugins for writers](https://tomfern.com/posts/vim-for-writers)
- [Awesome vim plugins for writers](https://opensource.com/article/17/2/vim-plugins-writers)

Comments on [dev.to](https://dev.to/maniowy/setting-up-vim-for-blogging-37oa).
