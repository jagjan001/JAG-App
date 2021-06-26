#!/bin/sh

#==============================================================================
#title            : install_inspect.sh
#description      : This script will install/configure Ruby and Inspect
#author   			  : Gonzalo Foligna
#date             : 10/24/2019
#version          : 0.1
#usage            : ./install_inspect.sh
#notes            : Script requires Unix shell
#ref              :
#                 https://github.pwc.com/NIS-AppSec/vault-tests#installation
#==============================================================================

echo "Executing [$0]..."

# Stop script on any error
set -e

#################################################################
# Check if run as root
#################################################################
if [ ! $(id -u) -eq 0 ]; then
	echo "ERROR: Script [$0] must be run as root, Script terminating"
	exit 7
fi
#################################################################

# Installing Ruby
yum install -y yum-utils
yum install -y centos-release-scl
yum-config-manager --enable rhel-server-rhscl-7-rpms
yum install -y rh-ruby25 rh-ruby25-ruby-devel
source /opt/rh/rh-ruby25/enable
echo -e "#!/bin/bash\nsource scl_source enable rh-ruby25" > /etc/profile.d/scl_enable.sh
yum install -y gcc gcc-c++ glibc-devel make libffi libffi-devel 
ruby --version

# Installing inspect gem
gem install inspec-bin ed25519 bcrypt_pbkdf --no-rdoc --no-ri inspec-bin

echo Done!

echo "Executing [$0] complete"
