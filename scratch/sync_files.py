import os
import shutil

p1 = os.path.join('backend_web', 'bola_main.py')
p2 = os.path.join('backend_web', 'بولا.py')
shutil.copyfile(p1, p2)
print("Successfully synced files!")
