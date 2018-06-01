#!/usr/bin/env bash

EDITOR_PATH='/bin/nano' # Editor for new/edit Replace with env variable
NOTE_VIEWER_PATH='/bin/cat' # App to view notes
CONFIG_PATH="./notable.conf"
TEMPLATE_PATH="./templates"
WORK_DIR="./index"

NOTE_TYPE='note'

# parse arguments
function parse_args () {
  #echo "arguments:  $@"
  while [[ $# -gt 0 ]]
  do
    key="$1"
    #echo "parsing $1"
    case $key in
      -c|--config)
      CONFIG_PATH="$2"
      shift #remove key
      shift # remove value
      ;;
      -t|--type)
      NOTE_TYPE=$2
      shift
      shift
      ;;
      a|add)
      NOTE_NAME=$2
      if [ -z $NOTE_NAME ]; then
        NOTE_NAME=$(date -Iseconds)
      fi
      COMMAND='CREATE'
      shift
      shift
      ;;
      e|edit)
      NOTE_NAME=$2
      COMMAND='EDIT'
      shift
      shift
      ;;
      v|view)
      NOTE_NAME=$2
      COMMAND='SHOW'
      shift
      shift
      ;;
      r|remove)
      NOTE_NAME=$2
      COMMAND='REMOVE'
      shift
      shift
      ;;
      --tags)
      TAGS=$2
      shift
      shift
      ;;
      *)
      echo "Unrecognized Command $1"
      shift
      ;;
    esac
  done
}

function confirm (){
  read -p "Are you sure? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}

function watch_file (){
  inotifywait -d -o log.txt -e close_write $1 ; echo "file closed" ; #git add $1
}

function get_path () {
  NOTE_PATH="$WORK_DIR/$NOTE_TYPE/$NOTE_NAME"
  if [ ! -d "$WORK_DIR/$NOTE_TYPE" ]; then
    mkdir -p "$WORK_DIR/$NOTE_TYPE"
  fi
}

function create_note (){
  if [ -f $NOTE_PATH ]; then
    echo "$NOTE_TYPE $NOTE_PATH already exists!"
    exit 1
  fi
  echo "Creating a new Note $NOTE_PATH"
  watch_file $NOTE_PATH
  if [ ! -f "$TEMPLATE_PATH/$NOTE_TYPE" ]; then
    echo "template $NOTE_TYPE not found, using default template $TEMPLATE_PATH/default"
    cp "$TEMPLATE_PATH/default" "$TEMPLATE_PATH/$NOTE_TYPE"
  fi
  cp "$TEMPLATE_PATH/$NOTE_TYPE" $NOTE_PATH
  sed -i "s/TITLE/$NOTE_NAME/" $NOTE_PATH
  sed -i "s/TYPE/$NOTE_TYPE/" $NOTE_PATH
  sed -i "s/TAGS/$TAGS/" $NOTE_PATH
  $EDITOR_PATH $NOTE_PATH
}

# modify_note EDITOR_PATH FILEPATH
function modify_note (){
  if [ ! -f $NOTE_PATH ]; then
    echo "$NOTE_TYPE $NOTE_PATH does not exist!"
    exit 1 # TODO: ask for create
  fi
  watch_file $NOTE_PATH
  $EDITOR_PATH $NOTE_PATH
}

function show_note () {
  $NOTE_VIEWER_PATH $NOTE_PATH
}

parse_args $@
#echo "CONFIG = $CONFIG_PATH"
#echo "COMMAND  = $COMMAND"

if [ -f $CONFIG_PATH ]; then
  source $CONFIG_PATH
else
  echo "No config file found in $CONFIG_PATH"
fi

case $COMMAND in
  CREATE)
  get_path
  create_note
  ;;
  EDIT)
  get_path
  modify_note
  ;;
  SHOW)
  get_path
  show_note
  ;;
  REMOVE)
  get_path
  echo "Will remove $NOTE_TYPE $NOTE_PATH"
  confirm
  sure="$?"
  if [ "$sure" == 0 ]; then
    echo "ok"
    rm $NOTE_PATH
  fi
  ;;
esac

echo $filepath
