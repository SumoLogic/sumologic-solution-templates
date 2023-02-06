#script location - this could be a shell script or py script
#timeout of a particular iteration
#output log file location where we need to put dump the script logs

import sys
import os
import subprocess
import time
from subprocess import STDOUT, check_output
from datetime import datetime

def execute(filename,timeout,outputLocation):
    arr = filename.split(".")
    fileExtention=arr[len(arr)-1]
    if fileExtention=="py":
        print("executing py job")
        cmd="python " + filename   #might need correction python instead of python3
        
        
    elif fileExtention=="sh":
        print("executing sh job")
        cmd="./" + filename
    else:
        print("Unsupported file for the script:" + filename)
    
    launchSubProcess(cmd,timeout,outputLocation)
        

def launchSubProcess(cmd,timeout,outputLocation):
    try:
        p = check_output(cmd, shell=True, timeout=int(timeout))
    except Exception as e:
        print("Error occured in launched process")
        print(repr(e))
    result = p.decode()
    file1 = open(outputLocation, "a")  # append mode
    file1.write(result)
    file1.close()

            
scriptLocation=sys.argv[1]
timeout=sys.argv[2]
outputLocation=sys.argv[3]

head_tail = os.path.split(scriptLocation)
scriptDir= head_tail[0]
fileName= head_tail[1]
os.chdir(scriptDir)
execute(fileName,timeout,outputLocation)
