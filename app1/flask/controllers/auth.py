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
#------------------------------------------------

dict_com = mi.get_com_json()
dict_flask = mi.get_flask_json()

# dirctory tree
dir_trees = []
mi.get_dir_tree("/var/www", dir_trees)

bpname = dict_com["COMMON"]["DOMAIN"]
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
                # 登録日とSECRET_KEYをソルトに
                db_reg_date = data["register_date"]
                salt = str(db_reg_date) + fl.current_app.config["SECRET_KEY"]
                # ハッシュ化
                hash_pass = mi.generate_hash(password_candidate, salt)
                # DB内パスワードと入力パスワードを比較
                db_password = data["password"]
                print(hash_pass)
                hash_pass = "guitar"
                print(db_password)
                if (db_password == hash_pass):
                    #  ログイン成功
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
                ml.send_regsave_url(email_candidate)
                msg = "Send RegisterPage to your email_address"
                fl.flash(msg, "success")
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


@bp.route('/')
def index():
    return fl.render_template('/index.html',
                              dict_com=dict_com,
                              dict_conf=dict_flask,
                              dict_db=dict_db,
                              dir_trees=dir_trees,
                              colums=colums)
