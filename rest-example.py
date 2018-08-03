#!/usr/bin/env python

####
# Robby Stahl - r.stahl@f5.com
#
# This is a simple example script. I assert no license; do as you wish.
####

import requests
import json

# constants
HOST = "bigip-ve-01"
URI_VS_LIST = "/mgmt/tm/ltm/virtual/"
STATS_LOC = "/stats/"
USERNAME = "admin"
PASSWORD = "admin"
INSECURE = "yes" # ignores certificate checks during REST transactions
# INSECURE = "no"


def get_rest_data(host, uri):
	full_path = "https://" + host + "/" + uri
	
	if INSECURE is "yes":
		# http://urllib3.readthedocs.io/en/latest/advanced-usage.html
		requests.packages.urllib3.disable_warnings()
		return requests.get(full_path, auth=(USERNAME, PASSWORD), verify=False)
	return requests.get(full_path, auth=(USERNAME, PASSWORD))


def get_stats(d):
	# we want the nested dict at key 'entries'
	entries = d['entries']
	
	# We want the nested dict of "nestedStats", which has the REST URL as the key.
	# We could pass that in as a functional argument. Instead, since we know the
	# REST API response has only one key at this level, we'll just iterate.
	for v in entries.values():
		nested_stats = v["nestedStats"]

	# this is the full URL to reach this data, with an optional version parameter
	v_self_link = nested_stats['selfLink']
	
	# The variable 'stats' will contain the nested dict of metrics.
	# Each key maps to a value that contains a dict with one key-value pair.
	# Unfortunately, the key changes for each type of metric. The last value
	# in each nested dict is the one we want.
	#
	# Visually:
	# d['someField']: {"something": 42} }
	# 
	# we want 42, so...
	# blah = d['someField'].values().pop()
	# blah now contains '42'
	stats = nested_stats['entries']
	v_state = stats['status.enabledState'].values().pop()
	v_reason = stats['status.statusReason'].values().pop()
	v_c_bits_in = stats['clientside.bitsIn'].values().pop()
	v_c_bits_out = stats['clientside.bitsOut'].values().pop()
	v_c_pkts_in = stats['clientside.pktsIn'].values().pop()
	v_c_pkts_out = stats['clientside.pktsOut'].values().pop()
	v_c_conn_cur = stats['clientside.curConns'].values().pop()
	v_c_conn_max = stats['clientside.maxConns'].values().pop()
	
	print "From:           ", v_self_link
	print "Enabled state:  ", v_state
	print "Why:            ", v_reason
	
	print "Bits in:        ", v_c_bits_in
	print "Bits out:       ", v_c_bits_out

	print "Packets in:     ", v_c_pkts_in
	print "Packets out:    ", v_c_pkts_out
	
	print "Packet size in: ", round((v_c_bits_in / 8.0) / v_c_pkts_in, 2), "bytes"
	print "Packet size out:", round((v_c_bits_in / 8.0) / v_c_pkts_out, 2), "bytes"

	print "Current conns:  ", v_c_conn_cur
	print "Max conns:      ", v_c_conn_max


def main():
	# query for all configured virtual servers
	resp = get_rest_data(HOST, URI_VS_LIST)
	j = resp.json()

	# acquire virtual server names
	vs_names = []
	for k in j['items']:
		for ksub in k:
			if ksub == 'name':
				vs_names.append(k['name'])
				#print k['name']

	# print statistics for each virtual server
	# note: each VS will be a separate REST API query. rate limit at scale, as needed.
	for item in vs_names:
		uri_query = URI_VS_LIST + item + STATS_LOC
		resp = get_rest_data(HOST, uri_query)
		r = resp.json()

		# walk_dict(r)
		print "virtual server: ", item # vs name
		get_stats(r)
		print # trailing newline


if __name__ == "__main__":
	main()

