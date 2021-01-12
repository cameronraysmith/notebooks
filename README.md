# notebooks

[![Binder][mybinder-badge]][mybinder] 
[![](https://images.microbadger.com/badges/license/cameronraysmith/notebooks.svg)](https://microbadger.com/images/cameronraysmith/notebooks)

## about
This is a [Docker][] configuration for running [jupyter][] || [lab][] with kernels for [Haskell][], [julia][], [maxima][] ([robert-dodier/maxima-jupyter][]), [python][], and [R][] with support for multi-kernel notebooks via [sos-notebook](https://github.com/vatlab/sos-notebook) on [Arch Linux][]. The name and framework are based on [AustinRochford/notebooks][].

See the [Makefile](Makefile) for relevant commands.

## container images
Images are available from [Docker hub](https://hub.docker.com/r/cameronraysmith/notebooks) and [GitHub Container Registry](https://ghcr.io/cameronraysmith/notebooks).

## setup

### local
This section is deprecated. I use the containers generated by this project exclusively in a cloud computing environment. I currently only support GCP.

### cloud
Interest in supporting cloud services other than GCP are welcome.

#### Google Cloud Platform (GCP)

##### setup

You will need to install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install). Ensure that you are logged in to an account associated with GCP.

``` bash
$ gcloud auth list 
  Credentialed Accounts
ACTIVE  ACCOUNT
*      <username of active account> 

To set the active account, run:
    $ gcloud config set account `ACCOUNT`
```

You will of course require an active configuration and project.

``` bash
$ gcloud config configurations describe <configuration>
is_active: true
name: <configuration>
properties:
  compute:
    region: us-central1
    zone: us-central1-f
  core:
    account: <username of active account>
    project: <project>

$ gcloud projects describe <project>
createTime: '2020-07-20T11:36:22.364Z'
lifecycleState: ACTIVE
name: notebooks
projectId: <project ID>
projectNumber: '<project number>'
```

Once the Google Cloud SDK is configured, follow the list of Make targets that proceed from `setup_gcp` in the [Makefile](Makefile).

##### data

It is assumed that data will be managed via a persistent disk named `$DATA_DISK` that will be attached in read-write mode to one running instance at a time. If you would like to run multiple instances of this container at the same time, you will need to account for the need to create multiple persistent disks.

#### Cloudflare
This section is only relevant if you would like to access the jupyter notebook server at a custom domain via SSL. Cloudflare is used for [managing CA certificates](https://support.cloudflare.com/hc/en-us/articles/115000479507). See the variables required by [scripts/cloudflare-update.sh](scripts/cloudflare-update.sh) and checked by the Make target `check_cf_env_set` to setup the environment as necessary.

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
    ├── cloudflare-update.sh
    ├── install-cos-gpu.sh
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
[Haskell]: https://github.com/gibiansky/IHaskell
[python]: https://ipython.readthedocs.io/
[julia]: https://github.com/JuliaLang/IJulia.jl
[maxima]: http://maxima.sourceforge.net/
[robert-dodier/maxima-jupyter]: https://github.com/robert-dodier/maxima-jupyter
[R]: https://irkernel.github.io/
[Arch Linux]: https://www.archlinux.org/
[AustinRochford/notebooks]: https://github.com/AustinRochford/notebooks
[microscaling/microbadger]: https://github.com/microscaling/microbadger
