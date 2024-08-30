#!/usr/bin/env bash

###
### This job aims to stop active workbenches running for more than x seconds (300 in this case, 5 minutes)
### This is achieved by checking the "notebooks.kubeflow.org/last-activity" annotation on the Notebook object,
### once gathered, we calculate the delta between that timestamp and now
### To stop the workbench, we annotate it with "kubeflow-resource-stopped="true""
###

for notebook in `oc get notebooks.kubeflow.org --no-headers | awk '{ print $1 }'`; do
	echo "[`date -u "+%F %T UTC"`] Checking notebook $notebook"
	LAST_ACTIVITY=`date -d $(oc get notebooks.kubeflow.org $notebook -o jsonpath='{.metadata.annotations.notebooks\.kubeflow\.org/last-activity}') +%s`
	NOW=`date +%s`
	DELTA=$((NOW - LAST_ACTIVITY))
	if [[ $DELTA -ge 300 ]]; then
		echo "$notebook arond for more than 300s, stopping"
		oc annotate notebooks.kubeflow.org $notebook kubeflow-resource-stopped="true"
	else
		echo "All good"
	fi
done
