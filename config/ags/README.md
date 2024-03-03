If you want to quickly iterate on this config, you may want to set `copper.feature.nixos.ags.develop.enable = true`, `copper.file.symlink.enable = true` and `copper.file.symlink.base` to the folder that your config is checked out in.
This will cause this folder to get symlinked directly to your config directory so you don't need to switch your HM generation to try any changes.

However, this way any TypeScript will not be automatically compiled.
To remedy this, you can run `fd --glob '*.ts' | xargs esbuild --outdir=. --watch=forever` while working.
You need to manually restart this if you add a new file.

Or simply configurey our editor to compile TypeScript on every save.
