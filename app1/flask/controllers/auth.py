import flask as fl
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '.'))
## user imports
import database.db_wrap as db
import modules.misc as mi
import modules.mail as ml
import modules.form as fm

import passlib.hash as pl
import functools as ftl
#------------------------------------------------

dict_com = mi.get_com_json()
dict_flask = mi.get_flask_json()

# dirctory tree
dir_trees = []
mi.get_dir_tree("/var/www", dir_trees)

bpname = "auth"
#bpname = dict_com["COMMON"]["DOMAIN"]
bppath = "/" + bpname 

#------------------------------------------------

# init blueprint
bp = fl.Blueprint(bpname, __name__,url_prefix=bppath)

# init database
db = db.WrapDB("/*NOP*/", dict_com)

# usr table from db
colums = db.get_colums("usrs")
dict_db = db.fetch_all("usrs")


# ルーティング処理
# check login
def is_logged_in(f):
  @ftl.wraps(f)
  def wrap(*args, **kwargs):
    if "logged_in" in fl.session :
      return f(*args,**kwargs)
    else:
      fl.flash("Unauthorized , Please login ","failed")
      return fl.redirect(fl.url_for("auth.login"))
  return(wrap)


#------------------------------------------------
# ログイン
#------------------------------------------------
@bp.route("/login", methods=["GET", "POST"])
def login():
    """
    ログインフォームからデータ取得
    エラーの場合エラーメッセージと共に差し戻す
    """
    # POST
    if fl.request.method == "POST":
        form = fm.loginForm(fl.request.form)
        if form.validate():
            # フォームから入力データ取得
            email_candidate = form.email.data
            password_candidate = form.password.data
            # DBで一致検索
            data = db.get_data("usrs", "email", email_candidate)
            print(email_candidate)
            if data is None:
                err_msg = "Account not Found"
                fl.flash(err_msg, "failed")
            else:
                # ユーザ名とSECRET_KEYをソルトに
                db_reg_usrname = data["usrname"]
                print(db_reg_usrname)
                salt = str(db_reg_usrname) + fl.current_app.config["SECRET_KEY"]
                # ハッシュ化
                hash_pass = mi.generate_hash(password_candidate, salt)
                # DB内パスワードと入力パスワードを比較
                db_password = data["password"]
                print(hash_pass)
                #hash_pass = "guitar"
                print(db_password)
                if (db_password == hash_pass):
                    #  ログイン成功
                    fl.session["logged_in"] = email_candidate
                    resp = fl.make_response(fl.redirect(fl.url_for("auth.index")))
                    #resp = fl.make_response(fl.render_template("/index.html"))
                    resp.set_cookie("session_id", "test",secure=True,httponly=True)
                    return resp
                    #return fl.render_template(bppath + "/index.html")
                else: #password mismatch
                    err_msg = "Invalid Password"
                    fl.flash(err_msg, "failed")
                    pass
                pass
            pass
        else: #validation error
            for field_errors in form.errors.values():
                for error in field_errors:
                    fl.flash(error, "failed")
        pass
    # GET
    else:
        pass
    return fl.render_template(bppath + "/login.html")


@bp.route("/logout")
def logout():
    fl.session.clear()
    return fl.render_template(bppath + "/logout.html")

#------------------------------------------------
# 登録
#------------------------------------------------
@bp.route("/register", methods=["GET", "POST"])
def register():
    """
    フォームからデータ取得
    フロント側validate: form.py[regForm]
    DB側validate: email有無のみ
    """
    # POST
    if fl.request.method == "POST":
        # フォームから入力データ取得
        # validation check
        form = fm.regForm(fl.request.form)
        if form.validate():
            username_candidate = form.username.data
            email_candidate    = form.email.data
            password_candidate = form.password.data
            # emailでdb内検索
            data = db.get_data("usrs", "email", email_candidate)
            if data is None:
                # 本登録フォームアドレス送信
                #ml.send_regsave_url(email_candidate)
                # 本登録画面で本来登録だが、暫定ですぐ登録処理
                result = db.reg_usr(username_candidate,email_candidate,password_candidate)
                if result == "ok" :
                    msg = "Send RegisterPage to your email_address"
                    fl.flash(msg, "success")
                else:
                    err_msg = result
                    fl.flash(err_msg, "failed")
            else:  # data exists
                err_msg = "Account already exist"
                fl.flash(err_msg, "failed")
        else:  #validation error
            for field_errors in form.errors.values():
                for error in field_errors:
                    fl.flash(error, "failed")

    else:  # GET
        pass

    return fl.render_template(bppath + "/register.html")

#------------------------------------------------
# 更新
#------------------------------------------------
@bp.route("/update", methods=["GET", "POST"])
@is_logged_in
def update():
    """
    フォームからデータ取得
    フロント側validate: form.py[regForm]
    DB側validate: email有無のみ
    """
    # POST
    if fl.request.method == "POST":
        # フォームから入力データ取得
        # validation check
        form = fm.regForm(fl.request.form )
        if form.validate():
            username_candidate = form.username.data
            email_candidate    = form.email.data
            password_candidate = form.password.data
            # emailでdb内検索
            data = db.get_data("usrs", "email", email_candidate)
            if data is None:
                err_msg = "USER NOT FOUND"
                fl.flash(err_msg, "failed")
            else:  # data exists
                msg = "Update User Info"
                salt = str(username_candidate) + fl.current_app.config["SECRET_KEY"]
                # ハッシュ化
                hash_pass = mi.generate_hash(password_candidate, salt)
                db.put_data("usrs", "email", email_candidate,data["id"])
                db.put_data("usrs", "usrname", username_candidate,data["id"])
                db.put_data("usrs", "password", hash_pass,data["id"])
                fl.flash(msg, "success")
        else:  #validation error
            for field_errors in form.errors.values():
                for error in field_errors:
                    fl.flash(error, "failed")

    else:  # GET
        pass

    return fl.render_template(bppath + "/update.html")


#------------------------------------------------
# 削除
#------------------------------------------------
@bp.route("/delete", methods=["GET", "POST"])
@is_logged_in
def delete():
    """
    フォームからデータ取得
    フロント側validate: form.py[regForm]
    DB側validate: email有無のみ
    """
    # POST
    if fl.request.method == "POST":
        # フォームから入力データ取得
        # validation check
        form = fm.passForm(fl.request.form)
        if form.validate():
            email_candidate    = fl.session["logged_in"]
            password_candidate = form.password.data
            # emailでdb内検索
            data = db.get_data("usrs", "email", email_candidate)
            print(email_candidate)
            if data is None:
                err_msg = "USER NOT FOUND"
                fl.flash(err_msg, "failed")
            else:  # data exists
                username_candidate = data["usrname"]
                print(data)
                msg = "Delete User Info"
                salt = str(username_candidate) + fl.current_app.config["SECRET_KEY"]
                # ハッシュ化
                hash_pass = mi.generate_hash(password_candidate, salt)
                if hash_pass == data["password"]:
                    db.del_usr("usrs", "email", email_candidate)
                    fl.flash(msg, "success")
                    fl.session.clear()
                    return fl.redirect(fl.url_for("auth.logout"))
                else :
                    err_msg = "password is incorrect"
                    fl.flash(err_msg, "failed")
        else:  #validation error
            for field_errors in form.errors.values():
                for error in field_errors:
                    fl.flash(error, "failed")

    else:  # GET
        pass

    return fl.render_template(bppath + "/delete.html")


@bp.route('/')
@is_logged_in
def index():
    colums = db.get_colums("usrs")
    dict_db = db.fetch_all("usrs")
    for ele_dict_db in dict_db:
        ele_dict_db["password"] = ele_dict_db["password"][:8]
    return fl.render_template('/index.html',
                              dict_com=dict_com,
                              dict_conf=dict_flask,
                              dict_db=dict_db,
                              dir_trees=dir_trees,
                              colums=colums)
