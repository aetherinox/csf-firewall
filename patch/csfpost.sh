#!/bin/bash

CSFPOSTD_PATH="/usr/local/include/csf/post.d"

if [ -d ${CSFPOSTD_PATH} ]; then
	for i in ${CSFPOSTD_PATH}/*.sh; do
		if [ -r $i ]; then
			. $i
		fi
	done

	unset i
fi

