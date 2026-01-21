# litedit.vim -- Literate Editing Operations

`litedit.vim` brings your Vim/Neovim to power of declarative editing.
This plugin provides features of easier to use `:normal` command and declarative execution of macros.

## Features

This plugin provides two commands: `:Normal` command that is

- the `<XXX>` key notation aware `:normal` command,
- and opt-in dot-repeatable `:normal` command

and `:Macro` command that can

- set/run macros
- and automatically convert it into a self-recursive macro.

### The `:Normal` command

The `:Normal` command is an easier to use version of the built-in `:normal` command, which emulates key types in Normal mode.
While the `:normal` command is useful to write down how you'll edit text, there's one difficulty to use: you have to input raw keycode or write backslash-escaped key notation such as the follows.

- `:normal ixyz^[` (`^[` is the raw keycode of `<ESC>`)
- `:execute "normal ixyz\<ESC>"`

This is troublesome and is what the `:Normal` command solves.
With the `:Normal` command, you can write `<XXX>` key notation directly within key sequence:

- `:Normal ixyz<ESC>`

The `:Normal` command automatically escapes the `<XXX>` key notation before a key type execution so that
this is equivalent to `:normal ixyz^[` as shown above.


Plus, the `:Normal` command can make the command execution dot-repeatable if you want.
In this case, the key sequence passed to the `:Normal` command will be reproduced by dot:

1. Run `:Normal xxx`: Delete three characters.
2. Then press `.`: Three characters are deleted again!

### The `:Macro` command

The `:Macro` command is an utility command to record and execute a macro from command line.
As you know, you can record a macro using `q` and then type some keys, but it's a bit unuseful (at least for me) because it's sometimes difficult to recover a typo.
In this case, you can set/fix a register content using `:let` command, but this is also troublesome since you have to use escaped `<XXX>` key notation to include special keys in a macro:

- `:let @q = "ixyz\<ESC>"`

On the other hand, with the `:Macro` command, you can achive the same thing in simpler manner:

- `:Macro ixyz<ESC>` or `:Macro --reg q ixyz<ESC>`

In addition, if you want, the `:Macro` command make the macro self-recursive, i.e. re-invoke the macro itself at the end: `@q == '{key-sequence}@q'`.

This self-recursiveness is useful to apply macros for all list of items without manually counting the number of them.  Thus it's worth of automatic macro conversion into self-recursive macros.

---

See [doc/litedit.txt](doc/litedit.txt) for the details of the options or interfaces.
