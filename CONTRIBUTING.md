# Contributing

Contributions are welcome!
You may raise an issue if you notice a bug or - even better - send a Pull Request fixing it.
I'm also open to adding new features, in particular improvements to the documentation, templating, deployment or other 'meta' systems.
However, much of this repository is still my personal Flake that I'm maintaining primarily for my own use.
If you add a feature that I have no use for and don't believe is worth the maintenance burden to me, I might not accept your PR.
So please, do open an issue to discuss or post in the discussions section before you invest significant amounts of work.

Even if you can't contribute any fixes or features, I'd still greatly appreciate if you'd leave a star on the repository.

By contributing, you agree to license your work under the terms laid out in the [License](./LICENSE.md) file.

## Reporting an issue

I appreciate you catching any bugs and reporting them!
When you do so, please include a complete reproduction for your issue.
In particular, include your entire configuration and a set of steps to take to reproduce the issue.

If at all possible, please try to narrow down the caues to a small example.

## Commit Style

All changes should, ideally, be split into atomic commits, i.e., the smallest commits such that each commit makes sense on its own.
Additionally, commit messages should observe the Conventional Commit style:

```
$type($area): $short

$body

$footer
```

* `$type` classifies the changes made. Possible values are `feat` for a new feature, `fix` for a bugfix, `chore` for changes such as dependency upgrades or refactorings and `docs` for purely documentation updates.
* `$area` describes the subsystem of the Flake that is affected. Possible values are `home` for home-manager configs, `darwin` for macOS, `nixos` for NixOS config, `flake` for any Flake modules, `infra` for templating, deployment and such, as well as `pkgs` for new packages. Some siginifacant parts of cofnig may also have their own area, for example, `ags`. If nothing else applies or the changes span multiple subsystems, `*` should be used.
* `$short` roughly describes the changes made. It should be implicitly read as "When applied, this commit will `$short`."
* `$body` is a much more detailed description of the changes, including why they were mande and what other affects they may have. It is almost always recommemd, but optional.
* `$footer` contains messages such as `Reverts commit xyz` or `Fixes #123`. It may be empty.

## Code Style

At this time, there is no grand unifying code style for everything in this repo.
If you change any part, please make sure that your changes fit in with the surrounding code.