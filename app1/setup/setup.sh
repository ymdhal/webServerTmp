### SETUP COMMAND ###
cp -f /var/www/pj1/setup/my.cnf /etc/my.cnf
/etc/init.d/mariadb setup
rc-status
rc-service mariadb start
cat /var/www/pj1/setup/init.sql | mysql
pip install -r /var/www/pj1/setup/requirements.txt
uwsgi --ini /var/www/pj1/uwsgi.ini
