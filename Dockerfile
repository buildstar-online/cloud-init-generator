FROM ubuntu:latest

ENV NONINTERACTIVE=1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y cloud-init git whois gettext-base && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    git clone https://github.com/cloudymax/cloud-init-generator.git && \
    git config --global --add safe.directory /cloud-init-generator/cigen-community-templates

WORKDIR /cloud-init-generator

RUN mkdir -p /cloud-init-generator/output



