# pass-autotype

Bind this script to a keyboard shortcut to automatically type the username and
password into the current (browser) window, retrieved from
the [pass](https://www.passwordstore.org/) password store.

The functionality is inspired by [keepassx](https://www.keepassx.org/) and the
implementation is inspired by https://github.com/allo-/passautotype (however we
make assumptions about the `pass` entries themselves instead of requiring
separate data storage).

The design is somewhat idiosyncratic and tailored to fit _my_ brain. Maybe
someone else finds it useful, too. :)


## Requirements

* Your `pass` entries are named like the domain they belong to, e.g.
  `github.com`. (We support multiple accounts for the same domain, but you'll
  need to place them in separate directories or something.)
* You use the multiline format and store the username in each entry (we use the
  `login:myusername` format by default, since that's
  what [qtpass](https://qtpass.org/) suggests, you might customize the
  `USER_FIELD` constant if you wish).
* You are using Linux and have `zenity` and `xdotool` installed,
  or you are using macOS and have `hammerspoon` installed.
* Your browser includes the domain in its window title, for Firefox there are
  several plugins that do this, e.g. [keepass-helper](https://addons.mozilla.org/en-US/firefox/addon/keepass-helper/).
  (Actually, we just check if the filename is contained in the window title,
  but using the domain as described probably makes the most sense.)


## Usage

* Linux: Use your window manager or desktop environment to set up a keyboard shortcut
  that launches the `pass-autotype` script. Note: If you use a nonstandard location by setting
  the `PASSWORD_STORE_DIR` environment variable, take care that it's available
  in the environment for this script (personally I call it via `bash -ic` so my
  usual shell init files are sourced).
* macOS: Save the `hammerspoon.lua` as `~/.hammerspoon/Spoons/PassAutotype.spoon/init.lua`
  and add something like this to your `~/.hammerspoon/init.lua`:

```
hs.loadSpoon("PassAutotype"):bindHotKeys({
  autotype = {{"cmd", "alt"}, "a"}
})
```

* Open a website where you want to log in and have the credentials in your
  `pass` store. Place the cursor on the username field.
* Press the keyboard shortcut defined above
* The username and password are typed in automatically. If there is more than
  one account for this domain, you'll be presented with a dialog to choose one.


## Autotype sequences

The default sequence is `username TAB password RETURN`. You can customize this
by adding an `autotype:` line to the `pass` entry. We don't support as
many [variations as keepass](http://keepass.info/help/base/autotype.html), but
the basics are covered. The sequence consists of tokens separated by spaces. The
following tokens are supported:

* `:user` and `:password` type in the username and password, respectively.
* `|KEY` sends the keystroke as defined by `xdotool key`
  (e.g. `|Tab`, `|Return`)
* `!duration` pauses for the given amount of seconds, e.g. `!0.5`

In other words, the default sequence would be written as

```
autotype::user |Tab :password |Return
```

while e.g. Google needs something like

```
autotype::user |Return !0.5 :password |Return
```


## Changelog

### 1.4 (unreleased)

* Nothing changed yet.

### 1.3 (2023-04-09)

* Update to Python-3

### 1.2 (2020-01-29)

* Allow for whitespace around structured fields (e.g. `login: myuser`)
  because QTPass on macOS inserts a space there.

### 1.1 (2019-01-01)

* Add hammerspoon implementation

### 1.0 (2016-10-11)

* Initial release.
