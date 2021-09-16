import wtforms as wf

class passForm(wf.Form):
    """
    pass_form
    """
    password = wf.PasswordField("password")
    confirm = wf.PasswordField("confirm",
        [wf.validators.EqualTo("password",
                               message="パスワードが一致していません")
        ])
    def validate_password(self, password):
        """
        パスワード バリデーション:
        - 未入力は禁止
        - 文字数が10文字以上は禁止
        """
        if password.data == "":
            raise wf.ValidationError("パスワードを入力してください")


class loginForm(wf.Form):
    """
    login_form
    """
    password = wf.PasswordField("password")
    email = wf.StringField("email",[
        wf.validators.Email(
            message="無効なメールアドレスです"
        )
    ])

    def validate_password(self, password):
        """
        パスワード バリデーション:
        - 未入力は禁止
        - 文字数が10文字以上は禁止
        """
        if password.data == "":
            raise wf.ValidationError("パスワードを入力してください")

class regForm(loginForm):
    """
    register_form
    """
    username = wf.StringField("username")
    confirm = wf.PasswordField("confirm",
        [wf.validators.EqualTo("password",
                               message="パスワードが一致していません")
        ])

    def validate_username(self, username):
        """
        ユーザ名 バリデーション:
        - 未入力は禁止
        - 文字数が10文字以上は禁止
        """
        if username.data == "":
            raise wf.ValidationError("ユーザ名を入力してください")

        if len(username.data) > 10 or len(username.data) < 2:
            raise wf.ValidationError(
                "ユーザ名は2〜10文字以内にしてください"
            )

