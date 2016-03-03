haproxy Cookbook
================
HAProxy for loadbalacing 2 apps.


Requirements
------------
- 2 nodes setup with ip 192.168.56.6/7
- 2 apps setup like: http://192.168.56.x/<appName>
- Allow port 82 for stats
- Allow port 8282 for accessing the LB

#### packages
- No other package requirements

Usage
-----
Just include `haproxy` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[haproxy]"
  ]
}
```
