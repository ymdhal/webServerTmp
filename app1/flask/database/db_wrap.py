# -*- coding: utf-8 -*-
import pymysql as pm
import operator
#from flaskext.mysql import MySQL


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
                                 user='vymd',
                                 db='hoge',
                                 port=dict_conf["DB"]["PORT"],
                                 charset='utf8',
                                 passwd='guitar',
                                 cursorclass=pm.cursors.DictCursor)
            # init MySQL
            #self.mysql.init_app(app)

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

        finally:
            cursor.close()
        return colums

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
