#!/usr/bin/python

import hmac
import hashlib
import base64
import json
import urllib
import requests
import binascii
import time

# SSL InsecurePlatform error when using Requests package
# Refer to: http://stackoverflow.com/questions/29099404/ssl-insecureplatform-error-when-using-requests-package
requests.packages.urllib3.disable_warnings();

IP        = "192.168.0.5";
LOGIN     = "admin"; # "admin";
SECRET    = base64.b64decode("aTcjMU5rNDNpVzRzOGU3VDNyN0g0bilNeDROKW0wb0Q=");
TIMESTAMP = "20160106T144950Z";
#TIMESTAMP = time.strftime("%Y%m%dT%H%M%SZ");
SESSIONID = "";

#  1. Prepare the data required for token calculation:
#      a. xHttpMethod = <HTTP method that the request was sent with, allowed values are ex GET, PUT, POST, DELETE according to the specific API>
#      b. xHost = <trimmed value of the Host header from the request>
#      c. xAuthDate = <trimmed value of the X-AUTH-Date header from the request>
#      e. xSecretKey = <constant secret key>
#      f. xSessionId = <used only for request which includes sessionId>
#      g. xUrl = <request Url>
#      h. xPayloadCheckSum = <crc32 chekcsum of the request payload>
#  2. Prepare string to sign:
#     POST requests with payload:
#      zStringToSign = xHttpMethod + "\n" + xHost + "\n" + xUrl + "\n" + xAuthDate + "\n" + xPayloadCheckSum + "\n" + xSessionId
#
#     GET requests or POST requests without payload
#      zStringToSign = xHttpMethod + "\n" + xHost + "\n" + xUrl + "\n" + xAuthDate + "\n" + xSessionId

def send(method, url, parameters):
	global SESSIONID;

	dataToSign = "";
	token      = "";
	data       = urllib.urlencode(parameters);

	# Preapare token calculation source string
	# xHttpMethod
	dataToSign  = method;

	# xHost
	dataToSign += ("\n" + IP);

	# xUrl
	if (method == "GET" and len(data) > 0):
		dataToSign += ("\n" + url + "?" + data);
	else:
		dataToSign += ("\n" + url);

	# xAuthDate
	dataToSign += ("\n" + TIMESTAMP);

	# xPayloadCheckSum
	if (method == "POST" and len(data) > 0):
		dataToSign += ("\n" + str(binascii.crc32(data) & 0xffffffff));

	# xSessionId
	if (url != "/login"):
		dataToSign += ("\n" + SESSIONID);

	# Calculate token
	mac = hmac.new(SECRET, '', hashlib.sha256);
	mac.update(dataToSign);
	token = base64.encodestring(mac.digest()).replace('\n', '');
        print "Token: " + token

	# Prepare request
	httpRequest = {};
	httpCookies = {};
	httpHeaders = {
		"Content-Type"  : "application/x-www-form-urlencoded",
		"Accept"        : "application/json",
		"X-AUTH-Date"   : TIMESTAMP,
		"Authorization" : "HMAC-SHA256 token=" + token
	};

	# Add sessionId cookie
	if (url != "/login"):
		httpCookies["sessionId"] = SESSIONID;

	# Disable SSL cert verification - Profusion device has self-signed cert
	if (method == "POST"):
		httpRequest = requests.post("https://" + IP + url, data = data,         headers = httpHeaders, verify = False, cookies = httpCookies);
	else:
		httpRequest = requests.get( "https://" + IP + url, params = parameters, headers = httpHeaders, verify = False, cookies = httpCookies);
	
	if (httpRequest.status_code == 200):
		# login methods returns cookie containing sessionID - save it globally
		if (url == "/login"):
			try:
				SESSIONID = httpRequest.cookies["sessionId"];
			except:
				print "No session ID in cookie!" + url

		return httpRequest.text;

	else:
		print "Request to " + url + " has failed! HTTP response code: " + str(httpRequest.status_code);

		return "";

############ Dump methods ##############

def dumpResponse(jsonString, header, detailsCallback):
	if (len(jsonString) == 0):
		return;

	jsonObj = json.loads(jsonString);

	print ""
	print "----- " + header + " -----"
	print "-- STATUS --"
	print "Code:         " + jsonObj["status"]["code"];
	print "Operation ID: " + str(jsonObj["status"]["operationId"]);
	if (jsonObj["status"]["code"] == "OK"):
		if (detailsCallback != None):
			print "-- DATA --"
			detailsCallback(jsonObj["data"]);
	else:
		print "Request failed!"

	print ""

def dumpConfigGetInfo(jsonObj):
	print "Config version:     " + str(jsonObj["configVersion"]);
	print "Device description: " + jsonObj["deviceDescription"];
	print "Device ID:          " + str(jsonObj["deviceId"]);
	print "Software version:   " + jsonObj["softwareVersion"];
	

def dumpNetworkConfig(jsonObj):
	eth = jsonObj["eth0"];

	print "-- ETH0 --"
	print "Enabled:       " + str(eth["enabled"]);
	print "MAC:           " + eth["mac"];
	print "Type:          " + eth["ip"]["type"];
	print "IP:            " + eth["ip"]["address"];
	print "MASK:          " + eth["ip"]["netMask"];
	print "DNS primary:   " + eth["ip"]["dns"]["primary"];
	print "DNS secondary: " + eth["ip"]["dns"]["secondary"];
	print "GW:            " + eth["ip"]["gateway"];

	print "-- RA0 --"
	try:
		ra0 = jsonObj["ra0"];
		print "Enabled:       " + str(ra0["enabled"]);
		print "MAC:           " + eth["mac"];
		print "Type:          " + ra0["ip"]["type"];
		print "IP:            " + ra0["ip"]["address"];
		print "MASK:          " + ra0["ip"]["netMask"];
		print "DNS primary:   " + ra0["ip"]["dns"]["primary"];
		print "DNS secondary: " + ra0["ip"]["dns"]["secondary"];
		print "GW:            " + ra0["ip"]["gateway"];
		print "ESSID:         " + ra0["wireless"]["essid"];
		print "Security:      " + ra0["wireless"]["security"];
	except:
		print "Not detected"


def dumpNetworkScan(jsonObj):
	for network in jsonObj["networks"]:
		print "-- NETWORK --"
		print "ESSID:    " + network["essid"];
		print "SECURITY: " + network["security"];

def dumpNetworkScan(jsonObj):
	for network in jsonObj["networks"]:
		print "-- NETWORK --"
		print "ESSID:    " + network["essid"];
		print "SECURITY: " + network["security"];



############ API ###############

def login():
	api  = "/login";
	data = {};

	if (len(LOGIN) > 0):
		data = { "user" : LOGIN };

	response = send("POST", "/login", data);

	dumpResponse(response, api, None);

def configGetInfo():
	api      = "/api/v1/config/getInfo"
	data     = {}
	response = send("GET", api, data);

	dumpResponse(response, api, dumpConfigGetInfo);

# This method gets write-lock for network configration (switches to the editing mode). If another client currently 
# has a write-lock, a LOCKED will be returned and the following information will be passed in the data:
# * IP of client with write-lock
# * Used account name
# * For how long the edition is locked
#
# Client can forcibly get write-lock, even though another user is currently in edition mode, by passing force = true request parameter.
# As a result of successful call, this method returns network configuration.
def configNetworkEdit(force):
	api      = "/api/v1/config/network/edit";	
	data     = { "force" : "true" if force else "false" };
	response = send("GET", api, data);

	dumpResponse(response, api, dumpNetworkConfig);

# Exits from network configuration edition mode without introducing any changes. As a result this method returns network status.
def configNetworkCancel():
	api      = "/api/v1/config/network/cancel";
	data     = {}
	response = send("GET", api, data);

	dumpResponse(response, api, dumpNetworkConfig);

# Performs scan on wireless interface, to search for available networks. Write-lock must be obtained before call to this method, see /config/network/edit method.
def configNetworkScan():
	api      = "/api/v1/config/network/scan";
	data     = { "device" : "ra0" };
	response = send("POST", api, data);

	dumpResponse(response, api, dumpNetworkScan);

def configNetworkSave():
	api      = "/api/v1/config/network/save";
	data     = { "ra0Enabled" : "true", "ra0IpType" : "DHCP", "ra0WirelessEssid" : "dlink", "ra0WirelessSecurity" : "WPA2", "ra0WirelessPassword" : "123qwe" };
	response = send("POST", api, data);

	dumpResponse(response, api, dumpNetworkConfig);

def configNetworkGetStatus():
	api      = "/api/v1/config/network/getStatus";
	data     = {}
	response = send("GET", api, data);

	dumpResponse(response, api, dumpNetworkConfig);

def zoneDeviceIsActive():
        api      = "/api/v1/zone/device/isActive";
        data     = {}
        response = send("GET", api, data);

        dumpResponse(response, api, None);

def deviceIsmStop():
        api      = "/api/v1/device/ism/stop";
        data     = {}
        response = send("GET", api, data);

        dumpResponse(response, api, None);

def deviceIsmStart():
        api      = "/api/v1/device/ism/start";
        data     = {}
        response = send("GET", api, data);

        dumpResponse(response, api, None);


################################

def main():
	print "START, key length: " + str(len(SECRET)) + ", login: \"" + LOGIN + "\""

	login();
	configGetInfo();

	configNetworkEdit(True);
	configNetworkScan();
	configNetworkSave();
	configNetworkGetStatus();
	zoneDeviceIsActive();

	deviceIsmStart();
	print "ISM started waiting 10s."
	time.sleep(10);
	deviceIsmStop();

if __name__ == "__main__":
	main()
