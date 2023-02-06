#!/usr/bin/python
from configparser import ConfigParser
import os.path
import os
import sys
import cx_Oracle
from time import gmtime, strftime
import datetime
import json as simplejson

querytime = str(datetime.datetime.now())

parser = ConfigParser()

configFilename = 'oracle-perf-monitor.cfg'
if os.path.isfile(configFilename) == False:
	print('Please check configuration filename provided: ' + configFilename)
	sys.exit()

parser.read(configFilename)

oraUser = parser.get('dbLogin', 'oraUser')

flag = True
try:
	oraPassword = parser.get('dbLogin', 'oraPassword')
except:
	print('Error reading password from config file {}, so will be reading from environment variable DB_PASSWORD'.format(configFilename))
else:
    if(oraPassword is None or oraPassword.strip() == ""):
    	print('Password is empty in config file {}, so reading from environment variable DB_PASSWORD'.format(configFilename))
    else:
        flag = False

if flag:
    oraPassword = os.environ.get('DB_PASSWORD')
    if (oraPassword is None or oraPassword.strip() == ""): 
        print('Password not available in config file {} and also in environment variable DB_PASSWORD'.format(configFilename))
        exit()
 
oraHost = parser.get('dbLogin', 'oraHost')
oraPort = parser.get('dbLogin', 'oraPort')
oraInstance = parser.get('dbLogin', 'oraInstance')
dsnStr = cx_Oracle.makedsn(oraHost, oraPort, oraInstance)

try:
	con = cx_Oracle.connect(user=oraUser, password=oraPassword, dsn=dsnStr)

except cx_Oracle.DatabaseError as e:
	error, = e.args
	if error.code == 1017:
		print('Please check credentials provided in the configuration file.')
		raise
	elif error.code == 12170:
		print('Please check database host details provided in the configuration file.')
		raise
	elif error.code == 12541:
		print('Please check database host and port details provided in the configuration file.')
		raise
	elif error.code == 12505:
		print('Please check SID details provided in the configuration file.')
		raise
	else:
		print('Database connection error')
		raise

cur = con.cursor()

queryDict = dict(parser.items('queries'))

for key in queryDict:
	cur.execute(queryDict[key])
	columns = [i[0] for i in cur.description]
	for row in cur:
		resultDict = dict(zip(columns, row))
		jsonOUT = simplejson.dumps(resultDict)
		print (querytime + " queryoutput=" + jsonOUT)

cur.close()
con.close()     