# -*- coding: utf-8 -*-
import flask as fl
import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), '.'))
import modules.misc as mi
import controllers.auth as auth #auth.py

# common json
dict_com = mi.get_com_json()

# init flask
app = fl.Flask(__name__)
key = "1234"
app.secret_key = key 

# register blueprint
app.register_blueprint(auth.bp)

@app.route('/')
def index():
    return "project1"

#------------------------------------------------
# MAIN.
#------------------------------------------------
if __name__ == '__main__':
    #key = os.urandom(24)
    #print(key)
    #print(int.from_bytes(key,"little"))
    app.run(host=dict_com["FW"]["HOST"],
            port=dict_com["FW"]["PORT"],
            debug=dict_com["COMMON"]["DEBUG"])
