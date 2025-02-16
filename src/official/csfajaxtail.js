//#############################################################################
//# Copyright 2006-2019, Way to the Web Limited
//# URL: http://www.configserver.com
//# Email: sales@waytotheweb.com
//#############################################################################

var CSFscript = '';
var CSFcountval = 6;
var CSFlineval = 100;
var CSFcounter;
var CSFcount = 1;
var CSFpause = 0;
var CSFfrombot = 120;
var CSFfromright = 10;
var CSFsettimer = 0;
var CSFheight = 0;
var CSFwidth = 0;
var CSFajaxHTTP = CSFcreateRequestObject();

function CSFcreateRequestObject() {
	var CSFajaxRequest;
	if (window.XMLHttpRequest) {
		CSFajaxRequest = new XMLHttpRequest();
	}
	else if (window.ActiveXObject) {
		CSFajaxRequest = new ActiveXObject("Microsoft.XMLHTTP");
	}
	else {
		alert('There was a problem creating the XMLHttpRequest object in your browser');
		CSFajaxRequest = '';
	}
	return CSFajaxRequest;
}

function CSFsendRequest(url) {
	var now = new Date();
	CSFajaxHTTP.open('get', url + '&nocache=' + now.getTime());
	CSFajaxHTTP.onreadystatechange = CSFhandleResponse;
	CSFajaxHTTP.send();
	document.getElementById("CSFrefreshing").style.display = "inline";
} 

function CSFhandleResponse() {
	if(CSFajaxHTTP.readyState == 4 && CSFajaxHTTP.status == 200){
		if(CSFajaxHTTP.responseText) {
			var CSFobj = document.getElementById("CSFajax");
			CSFobj.innerHTML = CSFajaxHTTP.responseText;
			waitForElement("CSFajax",function(){
				CSFobj.scrollTop = CSFobj.scrollHeight;
			});
			document.getElementById("CSFrefreshing").style.display = "none";
			if (CSFsettimer) {CSFcounter = setInterval(CSFtimer, 1000);}
		}
	}
}

function waitForElement(elementId, callBack){
	window.setTimeout(function(){
		var element = document.getElementById(elementId);
		if(element){
			callBack(elementId, element);
		}else{
			waitForElement(elementId, callBack);
		}
	},500)
}

function CSFgrep() {
	CSFsettimer = 0;
	var CSFlogobj = document.getElementById("CSFlognum");
	var CSFlognum;
	if (CSFlogobj) {CSFlognum = '&lognum=' + CSFlogobj.options[CSFlogobj.selectedIndex].value}
	else {CSFlognum = ""}
	if (document.getElementById("CSFgrep_i").checked) {CSFlognum = CSFlognum + "&grepi=1"}
	if (document.getElementById("CSFgrep_E").checked) {CSFlognum = CSFlognum + "&grepE=1"}
	if (document.getElementById("CSFgrep_Z").checked) {CSFlognum = CSFlognum + "&grepZ=1"}
	var CSFurl = CSFscript + '&grep=' + document.getElementById("CSFgrep").value + CSFlognum;
	CSFsendRequest(CSFurl);
}

function CSFtimer() {
	CSFsettimer = 1;
	if (CSFpause) {return}
	CSFcount = CSFcount - 1;
	document.getElementById("CSFtimer").innerHTML = CSFcount;
	if (CSFcount <= 0) {
		clearInterval(CSFcounter);
		var CSFlogobj = document.getElementById("CSFlognum");
		var CSFlognum;
		if (CSFlogobj) {CSFlognum = '&lognum=' + CSFlogobj.options[CSFlogobj.selectedIndex].value}
		else {CSFlognum = ""}
		CSFsendRequest(CSFscript + '&lines=' + document.getElementById("CSFlines").value + CSFlognum);
		CSFcount = CSFcountval;
		return;
	}
}

function CSFpausetimer() {
	if (CSFpause) {
		CSFpause = 0;
		document.getElementById("CSFpauseID").innerHTML = "Pause";
	}
	else {
		CSFpause = 1;
		document.getElementById("CSFpauseID").innerHTML = "Continue";
	}
}

function CSFrefreshtimer() {
	var pause = CSFpause;
	CSFcount = 1;
	CSFpause = 0;
	CSFtimer();
	CSFpause = pause;
	CSFcount = CSFcountval - 1;
	document.getElementById("CSFtimer").innerHTML = CSFcount;
}

function windowSize() {
	if( typeof( window.innerHeight ) == 'number' ) {
		CSFheight = window.innerHeight;
		CSFwidth = window.innerWidth;
	}
	else if (document.documentElement && (document.documentElement.clientHeight)) {
		CSFheight = document.documentElement.clientHeight;
		CSFwidth = document.documentElement.clientWidth;
	}
	else if (document.body && (document.body.clientHeight)) {
		CSFheight = document.body.clientHeight;
		CSFwidth = document.body.clientWidth;
	}
}
