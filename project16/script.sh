// this is used to export AMI name variable to enveronment variable.

#!/bin/sh
URL=https://github.com/thummalaravi/website.git
FIRSTNAME=ansible-
LASTNAME=$(git ls-remote $URL HEAD|cut -c 1-40)
FULLNAME="$FIRSTNAME$LASTNAME"
cd ~
export AMINAME=$FULLNAME
echo $FULLNAME



cd /etc/ansible/playbooks
ansible-playbook clone.yml
