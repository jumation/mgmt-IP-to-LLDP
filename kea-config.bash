#!/usr/bin/env bash

# Title               : kea-config
# Last modified date  : 27.11.2019
# Author              : jumation.com
# Description         : Used for testing mgmt-IP-to-LLDP.slax script.
#                       Configures ISC Kea DHCP server to provide
#                       generated IPv4 or IPv6 address and checks that the
#                       same address is seen by LLDP daemon running in the
#                       same machine.
#                       Kea is configured using Kea Control Agent RESTful API.
# Options             :
# Notes               : Test-setup network topology:
#                       vqfx-10000[xe-0/0/0] <-> [vnet19]host-svr
#
#                       In vQFX there was an IRB interface associated
#                       with the VLAN which the xe-0/0/0 was a member of.
#                       On that IRB interface the DHCP and DHCPv6 clients
#                       were running.

int="vnet19"

shopt -s extglob

while true; do

	if (( $RANDOM % 2 )); then

		curl >/dev/null -s -X POST http://127.0.0.1:8080/ \
		-H "Content-Type: application/json" \
		--data-binary @- <<-EOF
		{
			"command": "dhcp-enable",
			"service": [ "dhcp4" ]
		}
		EOF

		# $int has 10.1.255.254/16 configured.
		ip="10.1.$((RANDOM % 256)).$((RANDOM % 253 + 1))"
		sm="16"
		ver="4"

	else

		curl >/dev/null -s -X POST http://127.0.0.1:8080/ \
		-H "Content-Type: application/json" \
		--data-binary @- <<-EOF
		{
			"command": "dhcp-disable",
			"service": [ "dhcp4" ]
		}
		EOF

		hex=( {0..9} {a..f} )
		h=
		for _ in {0..3}; do
			h="$h${hex[$RANDOM % ${#hex[@]}]}"
		done

		# $int has only link-local address.
		ip="2001:db8:1::${h##+(0)}"
		sm="64"
		ver="6"

	fi

	curl >/dev/null -s -X POST http://127.0.0.1:8080/ \
	-H "Content-Type: application/json" \
	--data-binary @- <<-EOF
	{
		"command": "config-set",
		"arguments": {
			"Dhcp$ver": {
				"renew-timer": 30,
				"control-socket": {
					"socket-type": "unix",
					"socket-name": "/tmp/kea$ver-ctrl-socket"
				},
				"subnet$ver": [{
					"interface": "$int",
					"pools": [ { "pool": "$ip-$ip" } ],
					"subnet": "$ip/$sm",
					"valid-lifetime": 60
				}],
				"lease-database": {
					"type": "mysql",
					"name": "keadb",
					"host": "127.0.0.1",
					"user": "kea",
					"password": "kea"
				},
				"interfaces-config": {
					"interfaces": [ "$int" ]
				},
				"loggers": [{
					"name": "*",
					"severity": "DEBUG"
				}]
			}
		},
		"service": [ "dhcp$ver" ]
	}
	EOF

	sleep 180

	lldp_mgmt_ip=$(lldpcli -f json show neighbors port "$int" | \
										jq -r '.. | ."mgmt-ip"? | strings')

	[[ "$ip" == "$lldp_mgmt_ip" ]] || printf '%s: ip: %s lldp_mgmt_ip: %s\n' \
										"$(date -u "+%F %T UTC")" \
										"$ip" \
										"$lldp_mgmt_ip"

done
