#!/bin/bash



if [[ $MAX_PASSIVE = "true" ]];
then
   echo "NOTIFY SCRIPT: Server is Passive, exiting"
   exit
fi

# Example output
#Script returned 127 on event 'master_down'. Script was: '/usr/local/bin/maxscale_notify.sh --initiator=[ukdc-kdr-galera-1.uk.svc.cluster.local]:3306 --parent= --children= --event=master_down --node_list=[ukdc-kdr-galera-0.uk.svc.cluster.local]:3306,[ukdc-kdr-galera-2.uk.svc.cluster.local]:3306 --list=[ukdc-kdr-galera-0.uk.svc.cluster.local]:3306,[ukdc-kdr-galera-1.uk.svc.cluster.local]:3306,[ukdc-kdr-galera-2.uk.svc.cluster.local]:3306 --master_list=[ukdc-kdr-galera-0.uk.svc.cluster.local]:3306 --slave_list=[ukdc-kdr-galera-2.uk.svc.cluster.local]:3306 --synced_list=[ukdc-kdr-galera-0.uk.svc.cluster.local]:3306,[ukdc-kdr-galera-2.uk.svc.cluster.local]:3306'

#Script returned 127 on event 'new_master'. Script was: '/usr/local/bin/maxscale_notify.sh --initiator=[ukdc-kdr-galera-1.uk.svc.cluster.local]:3306 --parent= --children= --event=new_master --node_list=[ukdc-kdr-galera-1.uk.svc.cluster.local]:3306,[ukdc-kdr-galera-2.uk.svc.cluster.local]:3306 --list=[ukdc-kdr-galera-0.uk.svc.cluster.local]:3306,[ukdc-kdr-galera-1.uk.svc.cluster.local]:3306,[ukdc-kdr-galera-2.uk.svc.cluster.local]:3306 --master_list=[ukdc-kdr-galera-1.uk.svc.cluster.local]:3306 --slave_list=[ukdc-kdr-galera-2.uk.svc.cluster.local]:3306 --synced_list=[ukdc-kdr-galera-1.uk.svc.cluster.local]:3306,[ukdc-kdr-galera-2.uk.svc.cluster.local]:3306

initiator=""
parent=""
children=""
event=""
node_list=""
list=""
master_list=""
slave_list=""
synced_list=""

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


process_arguments $@
read -r -d '' MESSAGE << EOM
A server has changed state. The following information was provided:

Initiator: $initiator
Parent: $parent
Children: $children
Event: $event
Node list: $node_list
List: $list
Master list: $master_list
Slave list: $slave_list
Synced list: $synced_list
EOM



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

      #Ensure all slaces are stopped first STOP ALL SLAVES;
      echo "STOP ALL SLAVES;" > /tmp/change_master.sql
      mariadb -u$MONITOR_USER -p$MONITOR_PWD -h$lv_master_host -P$lv_master_port < /tmp/change_master.sql || exit 1
      rm -rf /tmp/change_master.sql

      if [[ $CHANGE_MASTER_HOST_1 = "none" ]]
      then
         echo "No master host set for CHANGE_MASTER_HOST_1"
      else
         echo "Running change master on master server $lv_master_to_use to $CHANGE_MASTER_HOST_1"
         echo "CHANGE MASTER '${CHANGE_MASTER_NAME_1}' TO master_use_gtid = slave_pos, MASTER_HOST='$CHANGE_MASTER_HOST_1', MASTER_USER='mariadb', MASTER_PASSWORD='mariadb', MASTER_CONNECT_RETRY=10; START SLAVE '${CHANGE_MASTER_NAME_1}';" > /tmp/change_master.sql
         mariadb -u$MONITOR_USER -p$MONITOR_PWD -h$lv_master_host -P$lv_master_port < /tmp/change_master.sql || exit 1
         #rm -rf /tmp/change_master.sql
      fi

      if [[ $CHANGE_MASTER_HOST_2 = "none" ]]
      then
         echo "No master host set for CHANGE_MASTER_HOST_2"
      else
         echo "Running change master on master server $lv_master_to_use to $CHANGE_MASTER_HOST_2"
         echo "CHANGE MASTER '${CHANGE_MASTER_NAME_2}' TO master_use_gtid = slave_pos, MASTER_HOST='$CHANGE_MASTER_HOST_2', MASTER_USER='mariadb', MASTER_PASSWORD='mariadb', MASTER_CONNECT_RETRY=10; START SLAVE '${CHANGE_MASTER_NAME_2}';" > /tmp/change_master.sql
         mariadb -u$MONITOR_USER -p$MONITOR_PWD -h$lv_master_host -P$lv_master_port < /tmp/change_master.sql || exit 1
         #rm -rf /tmp/change_master.sql
      fi
    fi
  fi
fi



# print message to file
echo "$MESSAGE" > /tmp/maxscaleoutout.txt
# email the message
#echo "$MESSAGE" | mail -s "MaxScale received $event event for initiator $initiator." $NOTIFY_EMAIL
