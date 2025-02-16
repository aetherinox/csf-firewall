#!/bin/bash

CSFPRED_PATH="/usr/local/include/csf/pre.d"

if [ -d ${CSFPRED_PATH} ]; then
	for i in ${CSFPRED_PATH}/*.sh; do
		if [ -r $i ]; then
			. $i
		fi
	done

	unset i
fi

