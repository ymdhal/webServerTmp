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

flask_debug=0
pj1_subdomain="project1"
pj2_subdomain="project2"
#### project1 ####
pj1_sv_root="$server_root/pj1"
pj1_dir="$run_dir/app1"

pj1_cnf_file="$pj1_dir/flask/conf/common.json"
pj1_wsgi_file="$pj1_dir/uwsgi/uwsgi.ini"
pj1_uwsgi_file="$pj1_dir/uwsgi/uwsgi.json"
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
### FUNC ###
repComJson () {
    cat $compose_file | jq "$1|=$2" \
                           > tmp.json && mv tmp.json $compose_file
}

repJson () {
    cat $1 | jq "$2|=$3" \
                           > tmp.json && mv tmp.json $1
}

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
    server unix:$pj1_sv_root/socket/uwsgi.sock;
}
upstream uwsgi_app2 {
    server unix:$pj2_sv_root/socket/uwsgi.sock;
}

server {
  listen $public_port;
  server_name _;
  location / {
    include uwsgi_params;
    uwsgi_pass uwsgi_app1;
  }
}

server {
  listen $public_port;
  server_name $pj1_subdomain;
  location / {
    include uwsgi_params;
    uwsgi_pass uwsgi_app1;
  }
}
server {
  listen $public_port ;
  server_name $pj2_subdomain;
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

repJson $pj1_cnf_file ".COMMON.DOMAIN"  "\"$pj1_subdomain\""
repJson $pj1_cnf_file ".COMMON.DEBUG"   "$flask_debug"
repJson $pj1_cnf_file ".FW.PORT"        "$public_port"

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

repJson $pj2_cnf_file ".COMMON.DOMAIN"  "\"$pj2_subdomain\""
repJson $pj2_cnf_file ".COMMON.DEBUG"   "$flask_debug"
repJson $pj2_cnf_file ".FW.PORT"        "$public_port"

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
repComJson ".version" '"3.3"'

# pj1
v1="/sys/fs/cgroup"
v2="${pj1_dir}/uwsgi:${pj1_sv_root}"
v3="${pj1_dir}/socket:${pj1_sv_root}/socket"
v4="${pj1_dir}/setup:${pj1_sv_root}/setup"
v5="${pj1_dir}/flask:${pj1_sv_root}/src"
v6="${pj1_dir}/mariadb/volume:${pj1_sv_root}/src/database"

repComJson ".services.project1.volumes"     '["'$v1'","'$v2'","'$v3'","'$v4'","'$v5'","'$v6'"]'
repComJson ".services.project1.environment" '["TZ:Asia/Tokyo"]'
repComJson ".services.project1.command"          "\"$pj1_setup_cmd\""
repComJson ".services.project1.container_name"   "\"$pj1_subdomain\""
repComJson ".services.project1.build.context"    "\"$docker_dir\""
repComJson ".services.project1.build.dockerfile" "\"$dockerfile\""

# pj2
v1="/sys/fs/cgroup"
v2="${pj2_dir}/uwsgi:${pj2_sv_root}"
v3="${pj2_dir}/socket:${pj2_sv_root}/socket"
v4="${pj2_dir}/setup:${pj2_sv_root}/setup"
v5="${pj2_dir}/flask:${pj2_sv_root}/src"
v6="${pj2_dir}/mariadb/volume:${pj2_sv_root}/src/database"

repComJson ".services.project2.volumes"     '["'$v1'","'$v2'","'$v3'","'$v4'","'$v5'","'$v6'"]'
repComJson ".services.project2.environment" '["TZ:Asia/Tokyo"]'
repComJson ".services.project2.command"          "\"$pj2_setup_cmd\""
repComJson ".services.project2.container_name"   "\"$pj2_subdomain\""
repComJson ".services.project2.build.context"    "\"$docker_dir\""
repComJson ".services.project2.build.dockerfile" "\"$dockerfile\""

#nginx
v1="${web_dir}/default.conf:/etc/nginx/conf.d/default.conf"
v2="${pj1_dir}/socket:${pj1_sv_root}/socket"
v3="${pj2_dir}/socket:${pj2_sv_root}/socket"

repComJson ".services.nginx.image"           '"nginx"'
repComJson ".services.nginx.container_name"  '"nginx"'
repComJson ".services.nginx.volumes"         '["'$v1'","'$v2'","'$v3'"]'
repComJson ".services.nginx.ports"           '["'$public_port':'$public_port'"]'
repComJson ".services.nginx.links"           '["'$pj1_subdomain'","'$pj2_subdomain'"]'
repComJson ".services.nginx.environment"     '["TZ:Asia/Tokyo"]'

docker-compose -f ./docker-compose.json up
#------------------------------------------------------------------------------------------------
