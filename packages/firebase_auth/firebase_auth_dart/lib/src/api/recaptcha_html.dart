String recaptchaHTML(String? siteKey, String? token) {
  return '''
    <html>
      <head>
        <title>reCAPTCHA check</title>
        <script type="text/javascript">
          var verifyCallback = function(token) {
            var url = window.location.href += ('?response=' + token)            
            window.location = url
            console.log(token);
            console.log(window.location);
          };
          var onloadCallback = function() {
            grecaptcha.render('recaptcha_element', {
              'sitekey' : '$siteKey',
              'callback' : verifyCallback,
            });
          };
        </script>
      </head>
      <body>
        <form action="?" method="POST">
          <div id="recaptcha_element"></div>
        </form>
        <script src="https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit"
            async defer>
        </script>
      </body>
    </html>''';
}

String successHTML() {
  return '''
    <html>
      <head>
        <title>Success</title>
      </head>
      <body>
        <p>Successful check! you may close this window now.</p>
      </body>
    </html>''';
}
