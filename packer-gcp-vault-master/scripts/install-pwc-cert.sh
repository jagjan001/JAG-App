#!/bin/sh -x

#==============================================================================
#title           : install_pwc_root_cert.sh
#description     : This script will install PwC Root 1 certificate
#author			 : Chris Albus
#date            : 01/20/2018
#version         : 0.1
#usage			 : ./install_pwc_root_cert.s
#notes           : Script requires Unix shell
#ref             :
#                   http://www.nethserver.org/go7/CentOS6_7/system/ca-certificates/solution.txt
#
#==============================================================================

echo "Executing [install_pwc_root_cert.sh]..."
set -e

# Add Certificate
cat <<EOF >/etc/pki/ca-trust/source/anchors/PwC_Root_1.pem
-----BEGIN CERTIFICATE-----
MIIDXDCCAkSgAwIBAgIQfnSwts7PF4hPXB6ION7gKDANBgkqhkiG9w0BAQsFADA/
MRMwEQYKCZImiZPyLGQBGRYDY29tMRMwEQYKCZImiZPyLGQBGRYDcHdjMRMwEQYD
VQQDEwpQd0MgUm9vdC0xMB4XDTE1MDYyMjE3NDEzMloXDTM1MDYyMjE3NDEzMlow
PzETMBEGCgmSJomT8ixkARkWA2NvbTETMBEGCgmSJomT8ixkARkWA3B3YzETMBEG
A1UEAxMKUHdDIFJvb3QtMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AOCHG+pTch5KhwyAJ5LB2zeCm0ktzqV32bCvts/DoIHXEs/Q6KuBGDKHtGnlYyok
lnfxHRR8EW8/8c1ZjfJNJxYzS4ZQLCaGb3I/bsCx4ksy8KCEffZsYyWlnaYQ4VOv
ldm1i5Bl4Hpjz37ZwyteiyUoOVTuJoZisze/oYWqdS6TBq97CkAy7WnE740XY3sw
OCdozF6m81HUN4NQQQzNkbWA+fTphG4dsQMm76QzOv2KRHo7NMuQuOqUXGosHVny
Y+VIsxvyvJUP52UHrEmx90qYkNbmwy+EYje3gjY9Q2ICEm9FFquwJ1OIkGJYLP2i
ljq+HBhFFJkrg3e/q76taE8CAwEAAaNUMFIwCwYDVR0PBAQDAgGGMBIGA1UdEwEB
/wQIMAYBAf8CAQIwHQYDVR0OBBYEFLzkzAi0h8dULnc0teBFAJS05xWOMBAGCSsG
AQQBgjcVAQQDAgEAMA0GCSqGSIb3DQEBCwUAA4IBAQDMPvo+IOmJg2BDllhPuaA8
dDcJXfs+ZV9J8pAcgUkVyJlJUZzJl+awva2Iy0aSIKtyO120DCi9ySMF3QJ2K/Xg
0ardtT0JJ8pVFC5YaAjMzLCRexaPI0Bw+ODNeAOysxhcPlt4fHn8yRBLd7vr0P1A
+gtDHxPAlS7EVD0577TfOvwSbvYItDrgk4E42aisQjoQCeINdo5bFBESm+75y4Ff
r+icQeO8tQL3rthOCm8Ofk9b71PiIxhs/IxvCCA5xzySgo+LnK9JXiAhTSh4kuA/
1cDZ2AUBWQ/hmkyFEa+3hmwVwMuIAFDVb97ymrUGhKGwhQDTo+LEWWCr+ZQW4pKT
-----END CERTIFICATE-----
EOF
update-ca-trust
