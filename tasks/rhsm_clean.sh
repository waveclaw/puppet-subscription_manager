#!/bin/sh

# Puppet Task Name: rhsm_clean
#
#   Copyright 2018 WaveClaw <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#
# Completely wipe the configuration from a node
#
#
if [ -x '/usr/bin/subscription-manager' ]
then
  /usr/bin/subscription-manager clean
fi
