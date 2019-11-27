# Advertise IP address on IRB IFL in LLDP

[Mgmt-IP-to-LLDP.slax](https://github.com/tonusoo/mgmt-IP-to-LLDP/blob/master/mgmt-IP-to-LLDP.slax) advertises IPv4 or IPv6 address on in-band management IRB interface in LLDP(TLV 8).

## Overview

Script periodically reads the `management-address` under `[edit protocols lldp]` and compares this with the first IPv4/IPv6 address found on IRB logical-interface.
If those two are not equal, then `management-address` is configured accordingly.

*Example of a script-configured `management-address`:*

![LLDP management-address config example](https://github.com/jumation/mgmt-IP-to-LLDP/blob/master/lldp_config_example.png)


## License

[GNU General Public License v3.0](https://github.com/tonusoo/mgmt-IP-to-LLDP/blob/master/LICENSE)
