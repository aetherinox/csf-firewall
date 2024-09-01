# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import os
import os.path
import sys
import django
sys.path.append('/usr/local/CyberCP')
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "CyberCP.settings")
django.setup()
import json
from plogical.acl import ACLManager
import plogical.CyberCPLogFileWriter as logging
import subprocess
from django.shortcuts import HttpResponse, render
from plogical.processUtilities import ProcessUtilities
from django.views.decorators.csrf import csrf_exempt
import tempfile
from django.http import HttpResponse
from django.views.decorators.clickjacking import xframe_options_exempt

def configservercsf(request):
    userID = request.session['userID']
    currentACL = ACLManager.loadedACL(userID)

    if currentACL['admin'] == 1:
        pass
    else:
        return ACLManager.loadError()

    return render(request,'configservercsf/index.html')

@csrf_exempt
@xframe_options_exempt
def configservercsfiframe(request):
    userID = request.session['userID']
    currentACL = ACLManager.loadedACL(userID)

    if currentACL['admin'] == 1:
        pass
    else:
        return ACLManager.loadError()

    if request.method == 'GET':
        qs = request.GET.urlencode()
    elif request.method == 'POST':
        qs = request.POST.urlencode()

    try:
        tmp = tempfile.NamedTemporaryFile(mode = "w", delete=False)
        tmp.write(qs)
        tmp.close()
        command = "/usr/local/csf/bin/cyberpanel.pl '" + tmp.name + "'"

        try:
            output = ProcessUtilities.outputExecutioner(command)
        except:
            output = "Output Error from csf UI script"

        os.unlink(tmp.name)
    except:
        output = "Unable to create csf UI temp file"

    return HttpResponse(output)
