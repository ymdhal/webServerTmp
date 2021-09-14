# -*- coding: utf-8 -*-
import pymysql as pm
import operator
import flask as fl
import sys
import os
#from flaskext.mysql import MySQL
sys.path.append(os.path.join(os.path.dirname(__file__), '.'))
## user imports
import modules.misc as mi

class WrapDB:
    def __init__(self, app, dict_conf):
        #print("DataBase is " + dict_conf["DB"]["DBMS_NAME"])
        if (dict_conf["DB"]["DBMS_NAME"] == "MySQL"):
            #self.mysql = fm.MySQL()
            # Config MySQL
            #app.config["MYSQL_DATABASE_USER"] = "vymd"
            #app.config["MYSQL_DATABASE_HOST"] = "localhost"
            #app.config["MYSQL_DATABASE_PASSWORD"] = "guitar"
            #app.config["MYSQL_DATABASE_DB"] = "hoge"
            #app.config["MYSQL_DATABASE_PORT"] = 3306
            self.db = pm.connect(host=dict_conf["DB"]["HOST"],
                                 user='root',
                                 db='users',
                                 port=dict_conf["DB"]["PORT"],
                                 charset='utf8',
                                 passwd='guitar',
                                 cursorclass=pm.cursors.DictCursor)
            # init MySQL
            cursor = self.db.cursor()
            sql_cmd = \
            "CREATE TABLE IF NOT EXISTS `usrs` ( \
            `id` int(11) NOT NULL AUTO_INCREMENT,\
            `usrname` varchar(50) NOT NULL,\
            `email` varchar(100) NOT NULL,\
            `password` varchar(255) NOT NULL,\
            `register_date` datetime NOT NULL DEFAULT current_timestamp(),\
            `update_date` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),\
            PRIMARY KEY (`id`)\
            ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4;"
            cursor.execute(sql_cmd)

    def get_colums(self, table_name):
        cursor = self.db.cursor()
        try:
            sql_cmd = 'select * from ' + table_name
            cursor.execute(sql_cmd)
            tup_results = cursor.description
            colums = []
            # カラム名
            for tup_elements in tup_results:
                colums.append(tup_elements[0])

            #print(colums)
        except Exception as e:
            colums = []

        finally:
            cursor.close()
        return colums

    def reg_usr(self, usrname,email,password_candidate):
        salt = usrname + fl.current_app.config["SECRET_KEY"]
        # ハッシュ化
        hash_pass = mi.generate_hash(password_candidate, salt)
        cursor = self.db.cursor()
        result = "ok"
        try:
            sql = "INSERT INTO `usrs` (`usrname`,`email` ,`password`) VALUES (%s, %s,%s)"
            cursor.execute(sql, (usrname, email,hash_pass))
            #cursor.execute('insert into usrs (usrname,email,password) values (%s,%s,%s)',
            #               usrname,
            #               email,
            #               password
            #               )
            self.db.commit()
        except Exception as e:
            result = e
        finally:
            cursor.close()
        return result


    def fetch_all(self, table_name):
        cursor = self.db.cursor()
        try:
            sql_cmd = 'select * from ' + table_name
            cursor.execute(sql_cmd)
            dict_results = cursor.fetchall()
            # 格納データ
            #print(dict_results)

        finally:
            cursor.close()
        return dict_results

    def get_data(self, table_name, key_name, value_name):
        cursor = self.db.cursor()
        try:
            sql_cmd = "select * from {} where {} = '{}'".format(table_name,key_name,value_name)
            print(sql_cmd)
            result = cursor.execute(sql_cmd)
            if result > 0 :
                #data = cursor.fetchall()
                data = cursor.fetchone()
                pass
            else :
                print(result)
                data = None
                pass
        finally:
            cursor.close()
        return data
