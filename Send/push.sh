#!/bin/bash

path="../Payloads/"

name=$1

if [ $# -eq 0 ]
then
    name="default"
fi

<<<<<<< HEAD
./thunderstorm push -c ../fastlane/certificates/production_it.macteo.push-catalog.p12 -f "$path""$name".json -t "$path""devices.json"
=======
./thunderstorm push -c ../fastlane/it.macteo.notificationcatalog.p12 -f "$path""$name".json -t "$path""devices.json"
>>>>>>> swift3
#;;
#
#case "$2" in
#  p)
#    thunderstorm push -c ../fastlane/certificates/production_it.macteo.push-catalog.p12 -f $message -t "$path""devices.json"
#    ;;
#  *)
#    thunderstorm push -c ../fastlane/certificates/production_it.macteo.push-catalog.p12 -f $message -t "$path""devices.json"
#    ;;
#esac
