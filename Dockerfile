FROM ubuntu:bionic

RUN apt -y update
RUN apt -y install vim
RUN apt -y install curl
RUN apt -y install httpie
RUN apt -y install dnsutils
RUN apt -y install iputils-ping
RUN apt -y install netcat
RUN apt -y install net-tools
RUN apt -y install iperf3

COPY node-shell-agent.sh /usr/local/bin/node-shell
COPY docker-logs.sh /usr/local/bin/docker-logs

RUN chmod a+x /usr/local/bin/node-shell
RUN ln -s /usr/local/bin/node-shell /usr/local/bin/ns
