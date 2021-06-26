
gsutil cp gs://${puppet_bucket}/puppet_${puppet_branch}.sh /opt/hashicorp/bin/puppet_install.sh
chmod 755 /opt/hashicorp/bin/puppet_install.sh
/opt/hashicorp/bin/puppet_install.sh
puppet agent -t
