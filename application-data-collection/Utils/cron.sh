#!/bin/bash
#
SCRIPT_PATH=$1
PIDFILE=$SCRIPT_PATH/job.pid
jobLocation=$2
timeout=$3
outputLocation=$4
if [ -f $PIDFILE ]
then
  PID=$(cat $PIDFILE)
  ps -p $PID > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo "Process already running"
    exit 1
  else
    ## Process not found assume not running
    echo $$ > $PIDFILE
    python3 $SCRIPT_PATH $jobLocation $timeout $outputLocation
    if [ $? -ne 0 ]
    then
      echo "Could not create PID file"
      exit 1
    fi
  fi
else
  echo $$ > $PIDFILE
    python3 $SCRIPT_PATH $jobLocation $timeout $outputLocation
  if [ $? -ne 0 ]
  then
    echo "Could not create PID file"
    exit 1
  fi
fi

rm $PIDFILE