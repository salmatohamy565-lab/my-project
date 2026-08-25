import shutil
import sys

sys.stdout.reconfigure(encoding='utf-8')
shutil.copyfile('backend_web/bola_main.py', 'backend_web/بولا.py')
print("Successfully copied bola_main.py to بولا.py")
