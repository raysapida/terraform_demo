# Everything `make rails` needs from the host, in one image, so the only host
# requirement is Docker: Ruby and Bundler for Kamal, Terraform, make, the ssh tools,
# and the Docker CLI with Buildx and Compose (copied from the official CLI image).
#
# Used by `make rails-docker` (and by `make clean` when the host has no Bundler). The
# Makefile explains why the container runs with host networking and the repo mounted
# at its own path. Versions are pinned: Ruby to the app's .ruby-version, Terraform to
# the version the repo was tested with. `docker:29-cli` tracks the 29 line, which
# matches the Docker the demo was tested against.
FROM docker:29-cli AS docker

FROM docker.io/library/ruby:4.0.5-slim
ARG TERRAFORM_VERSION=1.5.7
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends make openssh-client openssl curl unzip git ca-certificates build-essential libyaml-dev libpq-dev \
 && rm -rf /var/lib/apt/lists/*
# Terraform, checked against HashiCorp's published checksums.
RUN set -e; cd /tmp; \
    arch=$(dpkg --print-architecture); z=terraform_${TERRAFORM_VERSION}_linux_${arch}.zip; \
    curl -fsSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/$z; \
    curl -fsSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS; \
    grep " $z\$" terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c -; \
    unzip -q $z terraform -d /usr/local/bin; rm -f $z terraform_*_SHA256SUMS
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins
