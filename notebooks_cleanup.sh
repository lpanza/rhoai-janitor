#!/usr/bin/env bash

###
### This job aims to stop active workbenches running for more than x seconds (300 in this case, 5 minutes)
### This is achieved by checking the "notebooks.kubeflow.org/last-activity" annotation on the Notebook object,
### once gathered, we calculate the delta between that timestamp and now
### To stop the workbench, we annotate it with "kubeflow-resource-stopped="true""
### 
### If you want to issue a dry-run, execute the script with the "dry-run" parameter
### (e.g. ./notebooks_cleanup.sh dry-run)
###

THRESHOLD=300

for notebook in `oc get notebooks.kubeflow.org --no-headers | awk '{ print $1 }'`; do
	echo "[`date -u "+%F %T UTC"`] Checking notebook $notebook"
	LAST_ACTIVITY=`date -d $(oc get notebooks.kubeflow.org $notebook -o jsonpath='{.metadata.annotations.notebooks\.kubeflow\.org/last-activity}') +%s`
	NOW=`date +%s`
	DELTA=$((NOW - LAST_ACTIVITY))
	if [[ $DELTA -ge $THRESHOLD ]]; then
		echo "$notebook arond for more than ${THRESHOLD}, stopping"
		if [[ "$1" == "dry-run" ]]; then
			echo "This is a dry-run, not stopping $notebook"
		else
			oc annotate notebooks.kubeflow.org $notebook kubeflow-resource-stopped="true"
		fi
	else
		echo "All good, $notebook running for $DELTA seconds."
	fi
	echo
done
