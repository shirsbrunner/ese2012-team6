module Security
  class Mail_client
    def self.send_mail(to,contents)
      require 'rubygems'
      require 'tlsmail'

      from = 'awesome.trading.app@gmail.com'    #insert a gmail address
      pw = 'our_app_is_awesome'                 #and the password to the corresponding account

      content = <<EOF
From: #{from}
To: #{to}
subject: Password Reset


      Your Password has been reset on request to "#{contents}"
      Please change it directly after your next login.

Sincerely
Awesome Traiding App
EOF

      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      Net::SMTP.start('smtp.gmail.com', 587, 'gmail.com', from, pw, :login) do |smtp|
        smtp.send_message(content, from, to)
      end
    end
  end
end


