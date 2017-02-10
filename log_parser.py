import sys

from datetime import datetime, timedelta


IN_FILE = 'element_log.log'
OUT_FILE = '/tmp/{0}_element.log'.format(datetime.now().strftime('%Y-%m-%d_%H:%M:%S'))

def usage():
    print('''
    Given a timestamp, extracts the contents of {0} from 2 minutes
    before to 2 minutes after and saves the results to {1}
    
    Usage: ./{2} timestamp
    
        timestamp: Timestamp in the format 'MM/DD/YYYY HH:mm:ss'
    '''.format(IN_FILE, OUT_FILE, sys.argv[0]))


if (len(sys.argv) != 2) or (sys.argv[1] in ['-h', '--help']):
    usage()
    sys.exit(1)

try:
    FAIL_TIME = datetime.strptime(sys.argv[1], '%m/%d/%Y %H:%M:%S')
except ValueError:
    print('ERROR: invalid timestamp format!')
    usage()
    sys.exit(1)


BEG_TIME = FAIL_TIME - timedelta(minutes=2)
END_TIME = FAIL_TIME + timedelta(minutes=2)

print('''
    Parsing {0}
        Starting at {1}
        Ending at {2}
    '''.format(IN_FILE, BEG_TIME, END_TIME))

in_range = 0
file_created = 0

with open(IN_FILE, 'r') as f, open(OUT_FILE, 'w') as out:
    for line in f:
        if '[' in line:
            try:
                line_time = line[:line.find('[')].strip()
                timestamp = datetime.strptime(line_time, '%a %b %d %H:%M:%S %Y')
            except ValueError:
                pass                 
            if BEG_TIME <= timestamp <= END_TIME:
                in_range = 1
                file_created = 1
            elif timestamp > END_TIME:
                in_range = 0
                break
            else:
                in_range = 0
        if in_range:
            out.write(line)
if file_created:
    print('See the results in ', OUT_FILE)
else:
    print('No matches in this date range.')
