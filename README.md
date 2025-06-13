# Nix expressions for Firefox addons

There is no universal way (other than this flake) to get any Firefox addons from https://addons.mozilla.org/. Though there are some repositories containing a small fraction of Firefox addon expressions. But there is no go-to way of getting a nix expression for a such an addon.

This flake largely solves this issue by providing about **30,000 addons** from https://addons.mozilla.org/ as Nix packages.(with more to come!)

## Inspiration

- [rycee's NUR expressions](https://gitlab.com/rycee/nur-expressions) containing expressions for Firefox addons
- [montchr's firefox-addons](https://github.com/seadome/firefox-addons) also containing Nix expressions for Firefox addons
- [VSCode extensions Nix expressions by nix-community](https://github.com/nix-community/nix-vscode-extensions) as a rolemodel of scale
