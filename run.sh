#!/bin/bash

#------------------------------------------------------------------------------------------------
### USR ###
scenario="web_server_template"
flask_debug=1
public_port=8020
#dbg_cmd="/bin/sh"

### PATH ###
run_dir="$(pwd)"
app_dir="$run_dir/app1/flask"
db_dir="$run_dir/app1/mariadb"
wsgi_dir="$run_dir/app1/uwsgi"
web_dir="$run_dir/nginx"
docker_dir="$run_dir/docker"
jsonfile="$app_dir/conf/common.json"
uwsgi_file=$wsgi_dir/uwsgi.ini
nginx_file=$web_dir/default.conf

### SEVER ###
server_root="/var/www"
server_tmp="/tmp"
internal_port=8030

#------------------------------------------------------------------------------------------------
### LOG ###
LOG_DIR=$run_dir/log
LOG_OUT=$LOG_DIR/stdout_`date "+%Y%m%d_%H%M_%S"`.log
LOG_ERR=$LOG_DIR/stderr_`date "+%Y%m%d_%H%M_%S"`.log

mkdir -p $LOG_DIR
exec 1> >(tee -a $LOG_OUT)
exec 2> >(tee -a $LOG_ERR)

#------------------------------------------------------------------------------------------------
### SETUP ###
setup_dir="$LOG_DIR/setup"
mkdir -p $setup_dir
setup_file="$setup_dir/setup.sh"
echo "### SETUP COMMAND ###" > $setup_file

setup_cmd="/bin/sh $server_tmp/setup.sh"

#------------------------------------------------------------------------------------------------
### DB ###
cp -f $db_dir/init.sql $setup_dir
cp -f $db_dir/my.cnf $setup_dir
echo "cp -f $server_tmp/my.cnf /etc/my.cnf" >> $setup_file
echo "/etc/init.d/mariadb setup" >> $setup_file

echo "rc-status" >> $setup_file
echo "rc-service mariadb start" >> $setup_file
echo "cat $server_tmp/init.sql | mysql" >> $setup_file

#------------------------------------------------------------------------------------------------
### WEB ###
echo "rc-service nginx start" >> $setup_file
echo " -> replace nginx(default.conf)"
echo \
"
server {
	listen $internal_port default_server;
	listen [::]:$internal_port default_server;

  location / {
    include uwsgi_params;
    uwsgi_pass unix:$server_root/uwsgi.sock;
  }
}
" > $nginx_file

#------------------------------------------------------------------------------------------------
### APP ###
cat $app_dir/requirements.txt  >  $setup_dir/requirements.txt
#echo "pip install -r $server_tmp/requirements.txt" >> $setup_file
#echo "python app.py" >> $setup_file

#------------------------------------------------------------------------------------------------
### WSGI ###
cat $wsgi_dir/requirements.txt  >> $setup_dir/requirements.txt
echo "pip install -r $server_tmp/requirements.txt" >> $setup_file
#echo "uwsgi --json $server_root/uwsgi.json" >> $setup_file
echo "uwsgi --ini $server_root/uwsgi.ini" >> $setup_file

echo " -> replace uwsgi.ini"
echo \
"[uwsgi]
wsgi-file = $server_root/src/app.py
pidfile = $server_root/%n.pid
logto = $server_root/%n.log
#http = :$internal_port
socket = $server_root/%n.sock
chmod-socket = 666
callable = app
master = true
processes = 2
vacuum = true
die-on-term = true
py-autoreload = 1
" > $uwsgi_file

#------------------------------------------------------------------------------------------------
### JSON ###
echo " -> replace scenario_name_of_json"
cat $jsonfile | jq '.COMMON.SCENARIO|="'${scenario}'"' > tmp.json && mv tmp.json $jsonfile

cat $jsonfile | jq '.COMMON.DEBUG|='${flask_debug}'' > tmp.json && mv tmp.json $jsonfile

cat $jsonfile | jq '.FW.PORT|='${internal_port}'' > tmp.json && mv tmp.json $jsonfile

#tmp_jsonfile=$app_dir/conf/common.json
#
#cp -f $jsonfile $tmp_jsonfile
#------------------------------------------------------------------------------------------------
### DOCKER ###
#dockerfile="$docker_dir/flask.dockerfile"
#dockerfile="$docker_dir/uwsgi.dockerfile"
dockerfile="./docker/nginx.dockerfile"

tag_name=$scenario
container_name="${scenario}_con"
volume="\
  -v $web_dir:/etc/nginx/http.d \
  -v $wsgi_dir:$server_root \
  -v $app_dir:$server_root/src \
  -v $db_dir/volume:$server_root/src/database \
  -v $setup_dir:$server_tmp \
"

### MAKE ###
echo "** Start to make Docker_Image"

if docker images | grep -q "$tag_name "; then \
    echo " -> docker_image already exists"
else \
    docker build -f $dockerfile -t $tag_name .
    echo " -> Finished making Docker_Image"
fi

### RUN ###
echo "** Start to run Docker"

if docker ps -a | grep -q $container_name; then \
    echo " -> docker_container already exists"
    echo " -> stop docker"
    docker stop $container_name
    echo " -> remove  docker"
    docker rm $container_name
    echo "** Restart to run Docker"
fi

docker run -ti --name $container_name \
       -e TZ=Asia/Tokyo  \
       -e PYTHONDONTWRITEBYTECODE=1 \
       -p $public_port:$internal_port \
       -w $server_root \
       $volume \
       $tag_name \
       $setup_cmd

#------------------------------------------------------------------------------------------------
