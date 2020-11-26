# notebooks

[![Binder][mybinder-badge]][mybinder] 
[![](https://images.microbadger.com/badges/image/cameronraysmith/notebooks.svg)](https://microbadger.com/images/cameronraysmith/notebooks)
[![](https://images.microbadger.com/badges/version/cameronraysmith/notebooks.svg)](https://microbadger.com/images/cameronraysmith/notebooks)
[![](https://images.microbadger.com/badges/commit/cameronraysmith/notebooks.svg)](https://microbadger.com/images/cameronraysmith/notebooks)
[![](https://images.microbadger.com/badges/license/cameronraysmith/notebooks.svg)](https://microbadger.com/images/cameronraysmith/notebooks)

## about
This is a [Docker][] configuration for running [jupyter][] || [lab][] with kernels for [python][], [julia][], [maxima][] ([robert-dodier/maxima-jupyter][]), and [R][] on [Arch Linux][]. The name and framework are based on [AustinRochford/notebooks][] and [microscaling/microbadger][].

See the Makefile for relevant commands.

## file listing

```bash
▶ tree -I 'maxima-jupyter'
.
├── Dockerfile
├── Dockerfile.dev
├── LICENSE
├── Makefile
├── README.md
├── VERSION
├── etc
│   ├── Project.toml
│   ├── certs
│   │   ├── cf-cert.pem
│   │   └── cf-key.pem
│   ├── gitconfig.local
│   ├── jupyter_notebook_config.py
│   ├── p10k.zsh
│   ├── pkglist-01.txt
│   ├── pkglist-02.txt
│   ├── pkglist-startup.txt
│   ├── pkglist-yay.txt
│   ├── plugin.jupyterlab-settings
│   ├── python-libraries.txt
│   ├── themes.jupyterlab-settings
│   ├── tracker.jupyterlab-settings
│   └── zshrc.local
├── notebooks
│   ├── ...
└── scripts
    └── startup.sh
```

## LICENSE

This code is distributed under the [MIT License](http://opensource.org/licenses/MIT).

<!--refs-->
[mybinder-badge]: https://mybinder.org/badge_logo.svg
[mybinder]: https://mybinder.org/v2/gh/cameronraysmith/notebooks/master?urlpath=lab

[Docker]: https://www.docker.com/
[jupyter]: https://jupyter.org/
[lab]: https://jupyterlab.readthedocs.io/
[python]: https://ipython.readthedocs.io/
[julia]: https://github.com/JuliaLang/IJulia.jl
[maxima]: http://maxima.sourceforge.net/
[robert-dodier/maxima-jupyter]: https://github.com/robert-dodier/maxima-jupyter
[R]: https://irkernel.github.io/
[Arch Linux]: https://www.archlinux.org/
[AustinRochford/notebooks]: https://github.com/AustinRochford/notebooks
[microscaling/microbadger]: https://github.com/microscaling/microbadger
