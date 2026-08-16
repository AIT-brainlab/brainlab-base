FROM aitbrainlab/jupyter-base:12.1.1-cudnn8-devel-ubuntu22.04

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GNAME="students"
ARG NB_GID="10001"

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GNAME=${NB_GNAME} \
    NB_GID=${NB_GID} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

# Create NB_USER with name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
ENV PATH="$PATH:/usr/local/bin/"

# Add csim proxy to skel bash
RUN echo "export http_proxy=http://192.41.170.23:3128" >> /etc/skel/.bashrc  && \
   echo "export https_proxy=http://192.41.170.23:3128" >> /etc/skel/.bashrc

RUN addgroup --gid "${NB_GID}" "${NB_GNAME}"
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}" -g "${NB_GID}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    echo "${NB_USER} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/${NB_USER}" && \
    fix-permissions "${HOME}" 
    # fix-permissions "${CONDA_DIR}"

# Add csim proxy to root bash
RUN echo "export http_proxy=http://192.41.170.23:3128" >> /root/.bashrc  && \
   echo "export https_proxy=http://192.41.170.23:3128" >> /root/.bashrc 

USER ${NB_UID}
WORKDIR "/home/${NB_USER}"
# Setup work directory for backward-compatibility
RUN mkdir "/home/${NB_USER}/work"
RUN fix-permissions "${HOME}" && \
    fix-permissions "${HOME}/work" 

ARG PYTHON_VERSION=3.8.10
ENV PATH="$PATH:/home/${NB_USER}/.local/bin"

# Before you install anything, export proxy
ENV http_proxy http://192.41.170.23:3128
ENV https_proxy http://192.41.170.23:3128

USER root
# Any apt-get package here
RUN apt update && apt upgrade -y
RUN apt install -y openssh-server
RUN /bin/bash -c -l "service ssh start"
# Any pip3 here
RUN pip3 install tqdm
RUN pip3 install numpy
RUN pip3 install pandas
RUN pip3 install matplotlib
RUN pip3 install scipy
RUN pip3 install scikit-learn
RUN pip3 install seaborn
RUN pip3 install spacy
RUN pip3 install fastapi
RUN pip3 install gensim
RUN pip3 install huggingface_hub
RUN pip3 install transformers
RUN pip3 install datasets
RUN pip3 install evaluate
RUN pip3 install sentencepiece
RUN pip3 install torch
RUN pip3 install torchtext
RUN pip3 install torchvision
RUN pip3 install langchain
RUN pip3 install beautifulsoup4
RUN pip3 install sentence_transformers
RUN pip3 install chromadb
RUN pip3 install fschat
RUN pip3 install openai
RUN pip3 install plotly
RUN pip3 install streamlit

USER ${NB_UID}
CMD sudo service ssh start && start-singleuser.sh