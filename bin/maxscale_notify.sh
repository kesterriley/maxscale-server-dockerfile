#!/bin/bash

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

# print message to file
echo "$MESSAGE" > /path/to/script_output.txt
# email the message
echo "$MESSAGE" | mail -s "MaxScale received $event event for initiator $initiator." $NOTIFY_EMAIL
