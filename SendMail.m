function SendMail(subject,content)
% subject='I am Matlab';
% content='ha~ha~';
MailAddress = '237756205@qq.com';
password = 'jegcpshiijgkbigg';  %����������д������������룬Ϊ�˸�����˽����������***����
setpref('Internet','E_mail',MailAddress);
setpref('Internet','SMTP_Server','smtp.qq.com');
setpref('Internet','SMTP_Username',MailAddress);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties; 
props.setProperty('mail.smtp.auth','true'); 
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory'); 
props.setProperty('mail.smtp.socketFactory.port','465');
sendmail('lushuai1004@outlook.com',subject,content);
end