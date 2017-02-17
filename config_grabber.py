import sys, pwd, os, shutil

from datetime import datetime


OUT_DIR = '/tmp'
WORKDIR = os.path.join(OUT_DIR, 'apache_config_{0}/'.format(os.getpid()))
OUT_FILE = os.path.join(OUT_DIR, 'apache_config_{1}'.format(OUT_DIR, datetime.now().strftime('%Y-%m-%d_%H:%M:%S')))
LOGS_DIR = '/var/log/httpd/'
VAR_DIR = '/var/www/html/'
USR = 'apache'
UID = pwd.getpwnam(USR).pw_uid
GID = pwd.getpwnam(USR).pw_gid
NOEXIST = 'No such file or directory'

os.setgid(GID)
os.setuid(UID)

def usage():
    print('''
    Copy file(s) from {0} and/or {1}
    to {2}. If multiple files, a .zip archive will be created.

    Usage: ./{3} arg1 [arg2 ...]
    
        arg1, arg2, ...:  File(s) or Dir(s) path(s)
    '''.format(LOGS_DIR, VAR_DIR, OUT_DIR, sys.argv[0]))

if (len(sys.argv) < 2) or (sys.argv[1] in ['-h', '--help']):
    usage()
    sys.exit(1)

def check_path(path):
    return True if (path[:len(LOGS_DIR)] == LOGS_DIR or path[:len(VAR_DIR)] == VAR_DIR) else False

def copy_dir(src, dst):
    for fname in os.listdir(src):
        s = os.path.join(src, fname)
        d = os.path.join(dst, fname)
        if os.path.isdir(s):
            copy_dir(s, d)
        else:
            shutil.copy2(s, d)

if len(sys.argv) == 2:
    in_file = sys.argv[1]
    if not check_path(in_file):
        print('ERROR: You have no permission to copy {0}'.format(in_file))
        sys.exit(1)
    elif not os.path.exists(in_file):
        print('ERROR: {0} {1}'.format(in_file, NOEXIST))
        sys.exit(1)
    elif os.path.isfile(in_file):
        shutil.copy2(in_file, OUT_DIR)
        print('{0} copied to {1}'.format(in_file, OUT_DIR))
        sys.exit(0)

try:
    os.mkdir(WORKDIR)
except Exception as e:
    print('ERROR: Unable to create {0}\n {1}'.format(WORKDIR, e))

created = 0

for f in sys.argv[1:]:
    if not check_path(f):
        print('ERROR: You have no permission to copy {0}'.format(f))
    elif os.path.isfile(f):
        try:
            shutil.copy2(f, WORKDIR)
            created = 1
        except Exception as e:
            print('ERROR: Unable to copy {0} to {1}\n {2}'.format(f, WORKDIR, e))
    elif os.path.isdir(f):
        try:
            copy_dir(f, WORKDIR)
            created = 1
        except Exception as e:
            print('ERROR: Unable to copy {0} to {1}\n {2}'.format(f, WORKDIR, e))

if created:
    try:
        shutil.make_archive(OUT_FILE, 'zip', WORKDIR)
        print('Files were copied to {0}'.format(OUT_FILE))
        shutil.rmtree(WORKDIR)
    except Exception as e:
        print('ERROR: Unable to create archive {0}\n {1}'.format(OUT_FILE, e))
else:
    print('No files were copied')


