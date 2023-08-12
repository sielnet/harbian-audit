#!/bin/bash

#
# harbian-audit for Debian GNU/Linux 7/8/9/10/11/12 or CentOS Hardening
#

#
# 7.7.1 Ensure Firewall is active (Scored)
# Corresponds to the original 7.7 
# Modify Author : Samson wen, Samson <sccxboy@gmail.com>
#

set -e # One error, it's over
set -u # One variable unset, it's over

HARDENING_LEVEL=2

# Quick note here : CIS recommends your iptables rules to be persistent. 
# Do as you want, but this script does not handle this

PACKAGES='iptables iptables-persistent'
PACKAGES_CENTOS='iptables iptables-services nftables firewalld'
SERVICENAME='netfilter-persistent'
SERVICENAME_CENTOS='iptables ip6tables'
PACKAGE_NFT='nftables'
SERVICENAME_NFT='nftables.service'

audit_debian () {
	is_pkg_installed $PACKAGE_NFT
    if [ $FNRET != 0 ]; then
    	for PACKAGE in $PACKAGES
    	do
        	is_pkg_installed $PACKAGE
        	if [ $FNRET != 0 ]; then
            	crit "$PACKAGE is not installed!"
            	FNRET=1
            	break 
        	else
            	ok "$PACKAGE is installed"
            	FNRET=0
        	fi	
    	done
    	if [ $FNRET = 0 ]; then
	    	if [ $(systemctl status ${SERVICENAME}  | grep -c "Active:.active") -ne 1 ]; then
            	crit "${SERVICENAME} service is not actived"
            	FNRET=2
        	else
            	ok "${SERVICENAME} service is actived"
            	FNRET=0
        	fi
		fi
	# check nftables
	else
        is_pkg_installed $PACKAGE_NFT
        if [ $FNRET != 0 ]; then
        	crit "$PACKAGE_NFT is not installed!"
        	FNRET=3
        else
            ok "$PACKAGE_NFT is installed"
            FNRET=0
        fi
    	if [ $FNRET = 0 ]; then
	    	if [ $(systemctl status ${SERVICENAME_NFT}  | grep -c "Active:.active") -ne 1 ]; then
            	crit "${SERVICENAME_NFT} service is not actived"
            	FNRET=4
        	else
            	ok "${SERVICENAME_NFT} service is actived"
            	FNRET=0
        	fi
	fi
    fi
}

audit_centos () {
    for PACKAGE in $PACKAGES_CENTOS
    do
        is_pkg_installed $PACKAGE
        if [ $FNRET != 0 ]; then
            crit "$PACKAGE is not installed!"
            FNRET=1
            break 
        else
            ok "$PACKAGE is installed"
            FNRET=0
        fi
    done
    if [ $FNRET = 0 ]; then
		for SERVICENAME in $SERVICENAME_CENTOS
		do
	    	if [ $(systemctl status ${SERVICENAME}  | grep -c "Active:.active") -ne 1 ]; then
            	crit "${SERVICENAME} service is not actived"
            	FNRET=2
        	else
            	ok "${SERVICENAME} service is actived"
            	FNRET=0
        	fi
		done
    fi
}

# This function will be called if the script status is on enabled / audit mode
audit () {
	if [ $OS_RELEASE -eq 2 ]; then
		audit_centos
	else
		audit_debian
	fi
}

apply_debian () {
        if [ $FNRET = 0 ]; then
            ok "Firewall is enabled"
        elif [ $FNRET = 1 ]; then
            for PACKAGE in $PACKAGES
            do
                warn "$PACKAGE is absent, installing it"
                apt_install $PACKAGE
            done
        elif [ $FNRET = 3 ]; then
			warn "$PACKAGE_NFT is absent, installing it"
			apt_install $PACKAGE_NFT
        elif [ $FNRET = 2 ]; then
            warn "Enable ${SERVICENAME} service to actived"
			is_service_enabled ${SERVICENAME}
			if [ $FNRET = 1 ]; then
				systemctl enable ${SERVICENAME}
				systemctl daemon-reload
			fi
            systemctl start ${SERVICENAME}
        elif [ $FNRET = 4 ]; then
            warn "Enable ${SERVICENAME_NFT} service to actived"
			is_service_enabled ${SERVICENAME_NFT}
			if [ $FNRET = 1 ]; then
				systemctl enable ${SERVICENAME_NFT}
				systemctl daemon-reload
			fi
            systemctl start ${SERVICENAME_NFT}
		else
			:
        fi
}

apply_centos () {
        if [ $FNRET = 0 ]; then
            ok "$PACKAGES_CENTOS is installed"
        elif [ $FNRET = 1 ]; then
            for PACKAGE in $PACKAGES_CENTOS
            do
                warn "$PACKAGE is absent, installing it"
                yum_install $PACKAGE
            done
        elif [ $FNRET = 2 ]; then
            warn "Enable ${SERVICENAME_CENTOS} service to actived"
			for SERVICENAME in ${SERVICENAME_CENTOS}
			do 
				is_service_enabled ${SERVICENAME}
				if [ $FNRET = 1 ]; then
					systemctl enable ${SERVICENAME}
					systemctl daemon-reload
				else
					:
				fi
            	systemctl start ${SERVICENAME}
			done
        fi
}

# This function will be called if the script status is on enabled mode
apply () {
	if [ $OS_RELEASE -eq 2 ]; then
		apply_centos
	else
		apply_debian
	fi
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ -r /etc/default/cis-hardening ]; then
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
     echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
     echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi
