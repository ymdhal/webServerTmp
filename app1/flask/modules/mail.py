#import flask_mail as fm

class Mail_Ctrl():
    def __init__(app):
        app.config['MAIL_SERVER'] = 'smtp.gmail.com'
        app.config['MAIL_PORT'] = 587  
        app.config['MAIL_USE_TLS'] = True  
        app.config['MAIL_USERNAME'] = os.environ.get('EMAIL_USER')  
        app.config['MAIL_PASSWORD'] = os.environ.get('EMAIL_PASS')  
        mail = Mail(app)  

    def send_regsave_url(self,email):
        pass
