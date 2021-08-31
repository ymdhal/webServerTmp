### SETUP COMMAND ###
cp -f /var/www/pj2/setup/my.cnf /etc/my.cnf
/etc/init.d/mariadb setup
rc-status
rc-service mariadb start
cat /var/www/pj2/setup/init.sql | mysql
pip install -r /var/www/pj2/setup/requirements.txt
uwsgi --ini /var/www/pj2/uwsgi.ini
