#!/bin/bash

process_arguments()
{
   while [ "$1" != "" ]; do
      if [[ "$1" =~ ^--initiator=.* ]]; then
         initiator=${1#'--initiator='}
      elif [[ "$1" =~ ^--parent.* ]]; then
         parent=${1#'--parent='}
      elif [[ "$1" =~ ^--children.* ]]; then
         children=${1#'--children='}
      elif [[ "$1" =~ ^--event.* ]]; then
         event=${1#'--event='}
      elif [[ "$1" =~ ^--node_list.* ]]; then
         node_list=${1#'--node_list='}
      elif [[ "$1" =~ ^--list.* ]]; then
         list=${1#'--list='}
      elif [[ "$1" =~ ^--master_list.* ]]; then
         master_list=${1#'--master_list='}
      elif [[ "$1" =~ ^--slave_list.* ]]; then
         slave_list=${1#'--slave_list='}
      elif [[ "$1" =~ ^--synced_list.* ]]; then
         synced_list=${1#'--synced_list='}
      fi
      shift
   done
}

if [[ $MAX_PASSIVE = "true" ]];
then
   echo "NOTIFY SCRIPT: Server is Passive, exiting"
else

  initiator=""
  parent=""
  children=""
  event=""
  node_list=""
  list=""
  master_list=""
  slave_list=""
  synced_list=""

process_arguments $@

  if [[ $CHANGE_MASTER_HOST_1 = "none" ]] && [[ $CHANGE_MASTER_HOST_2 = "none" ]]
  then
     echo "No change master required"
  else
    if [[ -z $master_list ]]
    then
       echo "*** Master list is empty ***"
    else

      if [[ $event = "new_master" ]]
      then
        echo "Dectected master down, new master list = '$master_list'"
        if [[ $master_list =~ "," ]];
        then
           echo "... more than one master in list, using first one."
           lv_master_to_use=`echo $master_list | cut -f1 -d"," | sed 's/\[//g' | sed 's/\]//g'`
        else
           echo "... there is only one master in the list."
           lv_master_to_use=`echo $master_list | sed 's/\[//g' | sed 's/\]//g'`
        fi
        lv_master_host=`echo $lv_master_to_use | cut -f1 -d":"`
        lv_master_port=`echo $lv_master_to_use | cut -f2 -d":"`

        TMPFILE=`mktemp`
        
        #Ensure all slaves are stopped first
        echo "STOP ALL SLAVES;" > $TMPFILE
        mariadb -u$MAXSCALE_USER -p$MAXSCALE_USER_PASSWORD -h$lv_master_host -P$lv_master_port < $TMPFILE

        if [[ $CHANGE_MASTER_HOST_1 = "none" ]]
        then
           echo "No master host set for CHANGE_MASTER_HOST_1"
        else
           echo "Running change master on master server $lv_master_to_use to $CHANGE_MASTER_HOST_1"
           echo "CHANGE MASTER '${CHANGE_MASTER_NAME_1}' TO master_use_gtid = slave_pos, MASTER_HOST='$CHANGE_MASTER_HOST_1', MASTER_USER='$MAXSCALE_USER', MASTER_PASSWORD='$MAXSCALE_USER_PASSWORD', MASTER_CONNECT_RETRY=10; " > $TMPFILE
           mariadb -u$MAXSCALE_USER -p$MAXSCALE_USER_PASSWORD -h$lv_master_host -P$lv_master_port < $TMPFILE
           echo "START SLAVE '${CHANGE_MASTER_NAME_1}';" > $TMPFILE
           mariadb -u$MAXSCALE_USER -p$MAXSCALE_USER_PASSWORD -h$lv_master_host -P$lv_master_port < $TMPFILE
        fi

        if [[ $CHANGE_MASTER_HOST_2 = "none" ]]
        then
           echo "No master host set for CHANGE_MASTER_HOST_2"
        else
           echo "Running change master on master server $lv_master_to_use to $CHANGE_MASTER_HOST_2"
           echo "CHANGE MASTER '${CHANGE_MASTER_NAME_2}' TO master_use_gtid = slave_pos, MASTER_HOST='$CHANGE_MASTER_HOST_2', MASTER_USER='$MAXSCALE_USER', MASTER_PASSWORD='$MAXSCALE_USER_PASSWORD', MASTER_CONNECT_RETRY=10;" > $TMPFILE
           mariadb -u$MAXSCALE_USER -p$MAXSCALE_USER_PASSWORD -h$lv_master_host -P$lv_master_port < $TMPFILE
           echo "START SLAVE '${CHANGE_MASTER_NAME_2}';" > $TMPFILE
           mariadb -u$MAXSCALE_USER -p$MAXSCALE_USER_PASSWORD -h$lv_master_host -P$lv_master_port < $TMPFILE
        fi
        rm $TMPFILE
      fi
    fi
  fi
fi
