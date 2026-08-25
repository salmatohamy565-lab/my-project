import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_send_otp(target_email, code="123456"):
    sender_email = os.environ.get('SMTP_EMAIL') or 'boladesigns111@gmail.com'
    sender_pass = os.environ.get('SMTP_PASSWORD') or 'scbo gjrv pxil fhup'
    
    clean_pass = sender_pass.replace(' ', '').strip()
    print(f"Testing SMTP with sender: {sender_email}")
    print(f"Clean pass length: {len(clean_pass)}")
    
    msg = MIMEMultipart('alternative')
    msg['From'] = f"Bola Designs <{sender_email}>"
    msg['To'] = target_email
    msg['Subject'] = f"كود تجريبي: {code}"
    
    body = f"اختبار إرسال OTP لكود {code}"
    msg.attach(MIMEText(body, 'plain', 'utf-8'))
    
    # Try Port 587
    try:
        print("Attempting Port 587 TLS...")
        server = smtplib.SMTP('smtp.gmail.com', 587, timeout=10)
        server.starttls()
        server.login(sender_email, clean_pass)
        server.send_message(msg)
        server.quit()
        print("SUCCESS on Port 587 TLS!")
        return True
    except Exception as e587:
        print(f"Port 587 failed: {e587}")
        
    # Try Port 465 SSL
    try:
        print("Attempting Port 465 SSL...")
        server = smtplib.SMTP_SSL('smtp.gmail.com', 465, timeout=10)
        server.login(sender_email, clean_pass)
        server.send_message(msg)
        server.quit()
        print("SUCCESS on Port 465 SSL!")
        return True
    except Exception as e465:
        print(f"Port 465 failed: {e465}")
        return False

if __name__ == "__main__":
    test_send_otp("boladesigns111@gmail.com")
