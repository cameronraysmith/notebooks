FROM archlinux/archlinux:latest
LABEL maintainer="Cameron Smith <cameron.ray.smith@gmail.com>"


# setup environment
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}
ENV PATH "${HOME}/.local/bin:${PATH}"
ENV JULIA_MAJOR_VERSION="1.7"
ENV CMD_STAN_VERSION="2.28.2"
ENV CUDA_PATH="/opt/cuda/"
ENV LD_LIBRARY_PATH="/usr/local/nvidia/lib64"
ENV DATA_DISK_DIR="/data-*/jovyan/projects/"

# install primary arch packages
RUN mkdir -p ${HOME}/etc
COPY --chown=${NB_UID}:${NB_GID} ./etc/pkglist-01.txt ${HOME}/etc/

## install primary Arch packages
RUN pacman -Syu --needed --noconfirm - < ${HOME}/etc/pkglist-01.txt
RUN pacman -Scc --noconfirm
RUN groupadd --gid=${NB_GID} ${NB_USER} && \
    useradd --create-home --shell=/bin/false --uid=${NB_UID} --gid=${NB_GID} ${NB_USER} && \
    echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook && \
    sudo -lU ${NB_USER}


## install yay AUR package manager
RUN sudo git clone https://aur.archlinux.org/yay.git /opt/yay-git
RUN sudo chown -R ${NB_UID}:${NB_GID} /opt/yay-git
RUN cd /opt/yay-git && \
    makepkg -si --noconfirm

RUN yay -S --needed --noconfirm "python39"

# install jupyter
# https://github.com/arbennett/jupyterlab-themes
RUN pip install wheel \
  jupyter \
  jupyterlab \
  git+https://github.com/jupyterlab/jupyterlab-git.git \
  nbresuse \
  jupyterlab-topbar \
  jupyterlab-system-monitor \
  jupytext \
  RISE \
  voila \
  jupyterlab-sos \
  aquirdturtle_collapsible_headings \
  jupyterlab-execute-time \
  jupyterlab-skip-traceback \
  nbgitpuller \
  jupyterhub && \
pip cache purge && \
jupyter lab build


RUN setcap 'CAP_NET_BIND_SERVICE=+eip' /usr/sbin/jupyter && \
    setcap 'CAP_NET_BIND_SERVICE=+eip' /usr/bin/jupyter

# install python libraries
COPY --chown=${NB_UID}:${NB_GID} ./etc/python-libraries.txt ${HOME}/etc/
RUN pip install --extra-index-url https://pypi.fury.io/arrow-nightlies/ --pre pyarrow && \
    pip install torch==1.10.0+cu113 torchvision==0.11.1+cu113 torchaudio==0.10.0+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html && \
    pip install -r ${HOME}/etc/python-libraries.txt && \
    pip cache purge && \
    install_cmdstan --version ${CMD_STAN_VERSION} --dir ${HOME}/.cmdstan

## install julia packages including jupyter kernel
ENV CMDSTAN_HOME "${HOME}/.cmdstan/cmdstan-${CMD_STAN_VERSION}/"
ENV JULIA_CMDSTAN_HOME "${HOME}/.cmdstan/cmdstan-${CMD_STAN_VERSION}/"

## install maxima jupyter kernel
RUN git clone https://github.com/robert-dodier/maxima-jupyter.git ${HOME}/maxima-jupyter
WORKDIR ${HOME}/maxima-jupyter

RUN export PYTHON_SITE=$(python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])') && \ 
	mkdir -p ${PYTHON_SITE}/notebook/static/components/codemirror/mode/maxima/ && \ 
	cp maxima.js ${PYTHON_SITE}/notebook/static/components/codemirror/mode/maxima/ && \ 
	patch ${PYTHON_SITE}/notebook/static/components/codemirror/mode/meta.js codemirror-mode-meta-patch
# && \
# cp maxima_lexer.py ${PYTHON_SITE}/pygments/lexers/ && \
# patch ${PYTHON_SITE}/pygments/lexers/_mapping.py pygments-mapping-patch
RUN curl -kLO https://beta.quicklisp.org/quicklisp.lisp && \
    sbcl --non-interactive --load quicklisp.lisp --load docker-install-quicklisp.lisp && \
    maxima --batch-string="load(\"load-maxima-jupyter.lisp\");jupyter_install();"

## install R jupyter kernel
RUN echo "install.packages('IRkernel', repos='http://cran.us.r-project.org')" | R --slave && \
    echo "IRkernel::installspec()" | R --slave && \
    python -m bash_kernel.install && \
    python -m sos_notebook.install && \
    jupyter kernelspec list


# install secondary Arch packages
COPY --chown=${NB_UID}:${NB_GID} ./etc/pkglist-02.txt ${HOME}/etc/
RUN pacman -Syu --needed --noconfirm - < ${HOME}/etc/pkglist-02.txt && pacman -Scc --noconfirm

# install R packages
RUN echo $'Sys.setenv(TZ = "GMT", DOWNLOAD_STATIC_LIBV8 = 1); \n\
    install.packages("rstan", repos = "https://cloud.r-project.org/", dependencies = TRUE,  Ncpus = 4)' | R --slave

COPY --chown=${NB_UID}:${NB_GID} ./etc/install.R ${HOME}/etc/
RUN Rscript ${HOME}/etc/install.R

# Copy startup scripts from jupyter-docker-stacks
COPY stacks/*.sh /usr/local/bin/
COPY stacks/jupyter_notebook_config.py /etc/jupyter/

# copy configuration and jupyter theme files 
COPY --chown=${NB_UID}:${NB_GID} ./scripts ${HOME}/scripts
COPY --chown=${NB_UID}:${NB_GID} ./Dockerfile ${HOME}/scripts/
COPY --chown=${NB_UID}:${NB_GID} ./etc/themes.jupyterlab-settings ${HOME}/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings
COPY --chown=${NB_UID}:${NB_GID} ./etc/plugin.jupyterlab-settings ${HOME}/.jupyter/lab/user-settings/@jupyterlab/terminal-extension/plugin.jupyterlab-settings
RUN mkdir -p ${HOME}/.jupyter/lab/user-settings/@jupyterlab/notebook-extension
COPY --chown=${NB_UID}:${NB_GID} ./etc/tracker.jupyterlab-settings ${HOME}/.jupyter/lab/user-settings/@jupyterlab/notebook-extension/tracker.jupyterlab-settings

# copy additional etc files
COPY --chown=${NB_UID}:${NB_GID} ./etc/pkglist-startup.txt ./etc/pkglist-yay.txt ./etc/themes.jupyterlab-settings /etc/plugin.jupyterlab-settings ./etc/zshrc.local ./etc/gitconfig.local ./etc/tracker.jupyterlab-settings ${HOME}/etc/

# reset home directory permissions
RUN chown -R ${NB_UID}:${NB_GID} ${HOME}

# switch to NB_USER
USER ${NB_UID}


## install julia packages
RUN yay -S --needed --noconfirm "julia-bin"
COPY --chown=${NB_UID}:${NB_GID} ./etc/Project.toml ${HOME}/.julia/environments/v${JULIA_MAJOR_VERSION}/
RUN julia -e 'using Pkg; Pkg.instantiate(); Pkg.API.precompile()'

# install dotfiles framework, oh-my-zsh, and powerlevel10k
WORKDIR ${HOME}
RUN sudo chown ${NB_UID}:${NB_GID} ${HOME} && \
    yay -S --needed --noconfirm "rcm>=1.3.3-1" && \
    git clone https://github.com/thoughtbot/dotfiles.git ~/dotfiles && \
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k && \
    git clone --depth 1 https://github.com/hlissner/doom-emacs ${HOME}/.emacs.d && \
    ${HOME}/.emacs.d/bin/doom -y install && \
    mkdir -p ${HOME}/dotfiles-local && \
    cp ${HOME}/etc/{zshrc.local,gitconfig.local} ${HOME}/dotfiles-local && \
    mv ${HOME}/.zshrc ${HOME}/.zshrc.oh-my-zsh.base && \
    env RCRC=$HOME/dotfiles/rcrc rcup -f && \
    sudo usermod -s /bin/zsh ${NB_USER}

COPY --chown=${NB_UID}:${NB_GID} ./etc/p10k.zsh ${HOME}/.p10k.zsh
COPY --chown=${NB_UID}:${NB_GID} ./etc/jupyter_notebook_config.py ${HOME}/.jupyter


# Metadata
# https://github.com/label-schema/label-schema.org
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
ARG BUILD_DATE
ARG VERSION
ARG VCS_URL
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="notebooks" \
      org.label-schema.description="This is a Docker container for running jupyter lab with kernels for python, julia, maxima, and R on Arch Linux" \
      org.label-schema.url="https://cameronraysmith.net" \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$VERSION \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.title="notebooks" \
      org.opencontainers.image.description="This is a Docker container for running jupyter lab with kernels for python, julia, maxima, and R on Arch Linux" \
      org.opencontainers.image.url="https://cameronraysmith.net" \
      org.opencontainers.image.source=$VCS_URL \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.licenses="MIT"

EXPOSE 8080
EXPOSE 443

# run jupyter lab on localhost:8080 by default
CMD jupyter lab --ip=0.0.0.0 --port=8080 > ${HOME}/jupyter-lab.log 2>&1
