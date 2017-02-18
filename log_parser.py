import sys

from datetime import datetime, timedelta
import requests


IN_FILE = 'element_log.log'
OUT_FILE = '/tmp/{0}_element.log'.format(datetime.now().strftime('%Y-%m-%d_%H:%M:%S'))
JIRA_URL = 'http://192.168.0.145:8080/rest/api/2/issue/'
JIRA_USR = 'admin'
JIRA_PWD = 'admin'
JIRA_PROJECT = '10000'
JIRA_ISSUE_TYPE = 'Bug'

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


JIRA_ISSUE = {'fields': {'project': {'id': JIRA_PROJECT }, 'summary': 'A failure occured at {0}'.format(FAIL_TIME), 'description': 'The log file within that timeframe has been attached to this issue.', 'issuetype': {'name': JIRA_ISSUE_TYPE}}}


def create_issue(url, user, passwd, data):
    resp = requests.post(url, auth=(user, passwd), json=data)
    try:
        issue_id = resp.json()['id']
        return issue_id
    except Exception as e:
        print('ERROR creating the issue\n', e)
        return None

def create_attachment(url, user, passwd, issue_id, files):
    url += issue_id + '/attachments/'
    with open(files, 'rb') as f:
        resp = requests.post(url, auth=(user, passwd), headers={'X-Atlassian-Token': 'no-check'}, files={'file': f})
    try:
        return resp.json()[0]['filename']
    except Exception as e:
        print('ERROR attaching the file\n', e)
        return None

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
    issue_id = create_issue(JIRA_URL, JIRA_USR, JIRA_PWD, JIRA_ISSUE)
    if issue_id:
        print('Issue {0} has bee created'.format(issue_id))
        filename = create_attachment(JIRA_URL, JIRA_USR, JIRA_PWD, issue_id, OUT_FILE)
        if filename:
            print('File: {0} has been attached to issue #{1}'.format(filename, issue_id))
        else:
            print('ERROR attaching {0} to issue #{1}'.format(OUT_FILE, issue_id))
    else:
        print('ERROR creating issue')    
else:
    print('No matches in this date range.')

