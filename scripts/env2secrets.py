#!/usr/bin/env python3

#
# Translate an env file to k8s secrets
#

import sys
from base64 import b64encode as b64

# Secret definition and metadata
print("apiVersion: v1"                 )
print("kind: Secret:"                  )
print("metadata:"                      )
print("    name: qareports-environment")
print("type: Opaque"                   )
print("data:"                          )

for line in sys.stdin:
    line = line.strip()
    if len(line) == 0 or line[0] == '#':
        continue
    name, value = line.split('=', 1)
    value = b64(str.encode(value))
    print("    %s: %s" % (name, value.decode()))
