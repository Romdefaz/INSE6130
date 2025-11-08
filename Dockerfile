FROM ubuntu:22.04

RUN apt-get update -y && apt-get install netcat -y

WORKDIR /proc/self/fd/8
