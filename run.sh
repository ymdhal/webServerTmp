#!/bin/bash

#------------------------------------------------------------------------------------------------
### USR ###
public_port=80

#------------------------------------------------------------------------------------------------
### PATH ###

run_dir=`dirname $0`
compose_file="$run_dir/docker-compose.json"
docker_dir="$run_dir/docker"
web_dir="$run_dir/nginx"
nginx_file=$web_dir/default.conf

### SEVER ###
server_root="/var/www"
pj1_port=8030
pj2_port=8040

flask_debug=1
pj1_domain="project1"
pj2_domain="project2"
#### project1 ####
pj1_sv_root="$server_root/pj1"
pj1_dir="$run_dir/app1"

pj1_cnf_file="$pj1_dir/flask/conf/common.json"
pj1_wsgi_file="$pj1_dir/uwsgi/uwsgi.ini"
pj1_setup_file="$pj1_dir/setup/setup.sh"
pj1_setup_cmd="/bin/sh $pj1_sv_root/setup/setup.sh"

#### project2 ####
pj2_sv_root="$server_root/pj2"
pj2_dir="$run_dir/app2"

pj2_cnf_file="$pj2_dir/flask/conf/common.json"
pj2_wsgi_file="$pj2_dir/uwsgi/uwsgi.ini"
pj2_setup_file="$pj2_dir/setup/setup.sh"
pj2_setup_cmd="/bin/sh $pj2_sv_root/setup/setup.sh"

#------------------------------------------------------------------------------------------------
### LOG ###
LOG_DIR=$run_dir/log
LOG_OUT=$LOG_DIR/stdout_`date "+%Y%m%d_%H%M_%S"`.log
LOG_ERR=$LOG_DIR/stderr_`date "+%Y%m%d_%H%M_%S"`.log

mkdir -p $LOG_DIR
exec 1> >(tee -a $LOG_OUT)
exec 2> >(tee -a $LOG_ERR)


#------------------------------------------------------------------------------------------------
### WEB ###
echo " -> replace nginx(default.conf)"
echo \
"
upstream uwsgi_app1 {
    server unix:/var/www/pj1/socket/uwsgi.sock;
}
upstream uwsgi_app2 {
    server unix:/var/www/pj2/socket/uwsgi.sock;
}

server {
	listen $public_port;

  server_name $pj1_domain;

  location / {
    include uwsgi_params;
    uwsgi_pass uwsgi_app1;
  }
}
server {
	listen $public_port ;

  server_name $pj2_domain;

  location / {
    include uwsgi_params;
    uwsgi_pass uwsgi_app2;
  }
}
" > $nginx_file

#------------------------------------------------------------------------------------------------
### project1 ###

### SETUP ###
echo "### SETUP COMMAND ###" > $pj1_setup_file

### APP ###
cat $pj1_dir/flask/requirements.txt  >  $pj1_dir/setup/requirements.txt

cat $pj1_cnf_file | jq '.COMMON.DOMAIN|="'${pj1_domain}'"' > tmp.json && mv tmp.json $pj1_cnf_file

cat $pj1_cnf_file | jq '.COMMON.DEBUG|='${flask_debug}'' > tmp.json && mv tmp.json $pj1_cnf_file

cat $pj1_cnf_file | jq '.FW.PORT|='${pj1_port}'' > tmp.json && mv tmp.json $pj1_cnf_file

### DB ###
cp -f $pj1_dir/mariadb/init.sql $pj1_dir/setup
cp -f $pj1_dir/mariadb/my.cnf $pj1_dir/setup
echo "cp -f $pj1_sv_root/setup/my.cnf /etc/my.cnf" >> $pj1_setup_file
echo "/etc/init.d/mariadb setup" >> $pj1_setup_file

echo "rc-status" >> $pj1_setup_file
echo "rc-service mariadb start" >> $pj1_setup_file
echo "cat $pj1_sv_root/setup/init.sql | mysql" >> $pj1_setup_file

### WSGI ###
cat $pj1_dir/uwsgi/requirements.txt  >> $pj1_dir/setup/requirements.txt
echo "pip install -r $pj1_sv_root/setup/requirements.txt" >> $pj1_setup_file
echo "uwsgi --ini $pj1_sv_root/uwsgi.ini" >> $pj1_setup_file

echo " -> replace uwsgi.ini"
echo \
"[uwsgi]
wsgi-file = $pj1_sv_root/src/app.py
pidfile = $pj1_sv_root/%n.pid
logto = $pj1_sv_root/%n.log
socket = $pj1_sv_root/socket/uwsgi.sock
chmod-socket = 666
callable = app
master = true
processes = 2
vacuum = true
die-on-term = true
py-autoreload = 1
" > $pj1_wsgi_file

#------------------------------------------------------------------------------------------------
### project2 ###

### SETUP ###
echo "### SETUP COMMAND ###" > $pj2_setup_file

### APP ###
cat $pj2_dir/flask/requirements.txt  >  $pj2_dir/setup/requirements.txt

cat $pj2_cnf_file | jq '.COMMON.DOMAIN|="'${pj2_domain}'"' > tmp.json && mv tmp.json $pj2_cnf_file

cat $pj2_cnf_file | jq '.COMMON.DEBUG|='${flask_debug}'' > tmp.json && mv tmp.json $pj2_cnf_file

cat $pj2_cnf_file | jq '.FW.PORT|='${pj2_port}'' > tmp.json && mv tmp.json $pj2_cnf_file

### DB ###
cp -f $pj2_dir/mariadb/init.sql $pj2_dir/setup
cp -f $pj2_dir/mariadb/my.cnf $pj2_dir/setup
echo "cp -f $pj2_sv_root/setup/my.cnf /etc/my.cnf" >> $pj2_setup_file
echo "/etc/init.d/mariadb setup" >> $pj2_setup_file

echo "rc-status" >> $pj2_setup_file
echo "rc-service mariadb start" >> $pj2_setup_file
echo "cat $pj2_sv_root/setup/init.sql | mysql" >> $pj2_setup_file

### WSGI ###
cat $pj2_dir/uwsgi/requirements.txt  >> $pj2_dir/setup/requirements.txt
echo "pip install -r $pj2_sv_root/setup/requirements.txt" >> $pj2_setup_file
echo "uwsgi --ini $pj2_sv_root/uwsgi.ini" >> $pj2_setup_file

echo " -> replace uwsgi.ini"
echo \
"[uwsgi]
wsgi-file = $pj2_sv_root/src/app.py
pidfile = $pj2_sv_root/%n.pid
logto = $pj2_sv_root/%n.log
socket = $pj2_sv_root/socket/uwsgi.sock
chmod-socket = 666
callable = app
master = true
processes = 2
vacuum = true
die-on-term = true
py-autoreload = 1
" > $pj2_wsgi_file



#------------------------------------------------------------------------------------------------
### DOCKER ###
dockerfile="nginx.dockerfile"

# pj1
cat $compose_file | jq \
                        '.services.project1.container_name|="'${pj1_domain}'"' \
                        > tmp.json && mv tmp.json $compose_file

cat $compose_file | jq \
                        '.services.project1.build.context|="'${docker_dir}'"' \
                        > tmp.json && mv tmp.json $compose_file


cat $compose_file | jq \
                        '.services.project1.build.dockerfile|="'${dockerfile}'"' \
                        > tmp.json && mv tmp.json $compose_file

cat $compose_file | jq \
                        ".services.project1.command|=\"${pj1_setup_cmd}\"" \
                        > tmp.json && mv tmp.json $compose_file

cat $compose_file | jq \
                        '.services.project1.volumes|=[
"'${pj1_dir}'/uwsgi:'${pj1_sv_root}'",
"'${pj1_dir}'/socket:'${pj1_sv_root}'/socket",
"'${pj1_dir}'/setup:'${pj1_sv_root}'/setup",
"'${pj1_dir}'/flask:'${pj1_sv_root}'/src",
"'${pj1_dir}'/mariadb/volume:'${pj1_sv_root}'/src/database"
] ' \
                        > tmp.json && mv tmp.json $compose_file

cat $compose_file | jq \
                        '.services.project1.ports|=[
"'${pj1_port}':'${pj1_port}'"
] ' \
                        > tmp.json && mv tmp.json $compose_file


# pj2

 cat $compose_file | jq \
                         '.services.project2.container_name|="'${pj2_domain}'"' \
                         > tmp.json && mv tmp.json $compose_file

 cat $compose_file | jq \
                         '.services.project2.build.context|="'${docker_dir}'"' \
                         > tmp.json && mv tmp.json $compose_file


 cat $compose_file | jq \
                         '.services.project2.build.dockerfile|="'${dockerfile}'"' \
                         > tmp.json && mv tmp.json $compose_file

 cat $compose_file | jq \
                         ".services.project2.command|=\"${pj2_setup_cmd}\"" \
                         > tmp.json && mv tmp.json $compose_file

 cat $compose_file | jq \
                         '.services.project2.volumes|=[
 "'${pj2_dir}'/uwsgi:'${pj2_sv_root}'",
 "'${pj2_dir}'/socket:'${pj2_sv_root}'/socket",
 "'${pj2_dir}'/setup:'${pj2_sv_root}'/setup",
 "'${pj2_dir}'/flask:'${pj2_sv_root}'/src",
 "'${pj2_dir}'/mariadb/volume:'${pj2_sv_root}'/src/database"
 ] ' \
                         > tmp.json && mv tmp.json $compose_file

 cat $compose_file | jq \
                         '.services.project2.ports|=[
 "'${pj2_port}':'${pj2_port}'"
 ] ' \
                         > tmp.json && mv tmp.json $compose_file

#nginx
cat $compose_file | jq \
                        '.services.nginx.volumes|=[
"'${web_dir}'/default.conf:/etc/nginx/conf.d/default.conf",
"'${pj1_dir}'/socket:'${pj1_sv_root}'/socket",
"'${pj2_dir}'/socket:'${pj2_sv_root}'/socket"
] ' \
                        > tmp.json && mv tmp.json $compose_file

cat $compose_file | jq \
                        '.services.nginx.ports|=[
"'${public_port}':'${public_port}'"
] ' \
                        > tmp.json && mv tmp.json $compose_file

#tag_name=$scenario
#container_name="${scenario}_con"
#volume="\
#  -v $web_dir:/etc/nginx/http.d \
#  -v $pj1_wsgi_dir:$server_root \
#  -v $pj1_app_dir:$server_root/src \
#  -v $pj1_db_dir/volume:$server_root/src/database \
#  -v $setup_dir:$pj1_setup_dir \
#"

### MAKE ###
#echo "** Start to make Docker_Image"
#
#if docker images | grep -q "$tag_name "; then \
#    echo " -> docker_image already exists"
#else \
#    docker build -f $dockerfile -t $tag_name .
#    echo " -> Finished making Docker_Image"
#fi
#
#### RUN ###
#echo "** Start to run Docker"
#
#if docker ps -a | grep -q $container_name; then \
#    echo " -> docker_container already exists"
#    echo " -> stop docker"
#    docker stop $container_name
#    echo " -> remove  docker"
#    docker rm $container_name
#    echo "** Restart to run Docker"
#fi

docker-compose -f ./docker-compose.json up -d
# docker-compose build
# docker-compose up -d
#docker run -ti --name $container_name \
#       -e TZ=Asia/Tokyo  \
#       -e PYTHONDONTWRITEBYTECODE=1 \
#       -p $public_port:$internal_port \
#       -w $server_root \
#       $volume \
#       $tag_name \
#       $pj1_setup_cmd

#------------------------------------------------------------------------------------------------
