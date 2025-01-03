# example build command:
# DOCKER_BUILDKIT=1 docker build --build-arg _VERSION=$(git describe --tags --always) --rm -t gulp .

FROM python:3.12.3-bullseye

# Add build argument for pip cache
ARG _VERSION
ENV _VERSION=${_VERSION}

# install dependencies
RUN apt-get -qq update
RUN apt-get install -y -q \
    libsystemd-dev \
    vim \
    sed \
    git \
    curl

WORKDIR /app

# copy template and requirements over.
COPY ./src /app/src
COPY ./docs /app/docs
COPY ./gulp_cfg_template.json /app
COPY ./pyproject.toml /app
COPY ./MANIFEST.in /app
COPY ./LICENSE.GULP.md /app
COPY ./LICENSE.AGPL-3.0.md /app
COPY ./LICENSE.md /app
COPY ./CONTRIBUTING.md /app
COPY ./README.md /app

# copy requirements file if exists
COPY ./requirements.txt* /app/requirements.txt

# set version passed as build argument
RUN echo "[.] GULP version: ${_VERSION}" && sed -i "s/version = .*/version = \"$(date +'%Y%m%d')+${_VERSION}\"/" /app/pyproject.toml

RUN if [ -s /app/pyproject.toml]; then \
        # install from project
        echo "[.] Patching pyproject.toml to remove dependencies" && \
        pip3 install --no-cache-dir -e . ; \       
    else \
        echo "[.] No project found installing requirements" && \   
        pip3 install --no-cache-dir -r requirements.txt ; \       
    fi

# show python info and installed package list
RUN echo "[.] Python version: " && python3 --version
RUN echo "[.] Python sys.path: " && python3 -c "import sys; print('\n'.join(sys.path))"    
RUN echo "[.] Installed packages:" && pip3 list -v

# test run
RUN set -e && python3 -m gulp --version

# expose port 8080
EXPOSE 8080
