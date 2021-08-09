# ベースイメージ
FROM alpine:latest

RUN echo "**** install Python ****" && \
    apk add --no-cache python3 \
      openrc \
      mariadb mariadb-common mariadb-dev mariadb-client \
      python3-dev gcc build-base linux-headers pcre-dev \
      nginx && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    \
    echo "**** install pip ****" && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools wheel && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi

#RUN mkdir /var/www
# workdirの指定
#WORKDIR /var/www
RUN mkdir /run/openrc &&\
  # Tell openrc its running inside a container, till now that has meant LXC
  sed -i 's/#rc_sys=""/rc_sys="lxc"/g' /etc/rc.conf &&\
  # Tell openrc loopback and net are already there, since docker handles the networking
  echo 'rc_provide="loopback net"' >> /etc/rc.conf &&\
  # no need for loggers
  sed -i 's/^#\(rc_logger="YES"\)$/\1/' /etc/rc.conf &&\
  # can't get ttys unless you run the container in privileged mode
  sed -i '/tty/d' /etc/inittab &&\
  # can't set hostname since docker sets it
  sed -i 's/hostname $opts/# hostname $opts/g' /etc/init.d/hostname &&\
  # can't mount tmpfs since not privileged
  sed -i 's/mount -t tmpfs/# mount -t tmpfs/g' /lib/rc/sh/init.sh &&\
  # can't do cgroups
  sed -i 's/cgroup_add_service /# cgroup_add_service /g' /lib/rc/sh/openrc-run.sh &&\
  touch /run/openrc/softlevel

# 依存Pythonライブラリ一覧コピー
COPY ./requirements.txt ./

# 依存Pythonライブラリインストール
RUN pip install --no-cache-dir -r requirements.txt && \
  rm -f requirements.txt

#WORKDIR /home
#WORKDIR /var/www/src
