# harbian-audit Hardening

## Introduction 

```console
# bash bin/hardening.sh --audit-all
[...]
################### SUMMARY ###################
      Total Available Checks : 272
         Total Runned Checks : 272
         Total Passed Checks : [ 240/272 ]
         Total Failed Checks : [  32/272 ]
   Enabled Checks Percentage : 100.00 %
       Conformity Percentage : 88.24 %
```
## Quickstart

```console
$ git clone https://github.com/sielnet/harbian-audit.git && cd harbian-audit
# cp etc/default.cfg /etc/default/cis-hardening
# sed -i "s#CIS_ROOT_DIR=.*#CIS_ROOT_DIR='$(pwd)'#" /etc/default/cis-hardening
# bin/hardening.sh --init
# bin/hardening.sh --audit-all
[...]
################### SUMMARY ###################
      Total Available Checks : 272
         Total Runned Checks : 272
         Total Passed Checks : [ 240/272 ]
         Total Failed Checks : [  32/272 ]
   Enabled Checks Percentage : 100.00 %
       Conformity Percentage : 88.24 %
# bin/hardening.sh --set-hardening-level 5
# bin/hardening.sh --apply 
[...]
```

## Usage

### Pre-Install 

If use Network install from a minimal CD to installed Debian GNU/Linux, need install packages before use the hardening tool. 
```
# apt-get install -y bc net-tools pciutils
```

Redhat/CentOS need install packages before use the hardening tool:
```
# yum install -y bc net-tools pciutils epel-release 
```

### Pre-Set 
You must set a password for all users before hardening. Otherwise, you will not be able to log in after the hardening is completed. Example(OS user: root and test): 
```
 
# passwd 
# passwd test 
```

### Configuration

Hardening scripts are in ``bin/hardening``. Each script has a corresponding
configuration file in ``etc/conf.d/[script_name].cfg``.

Each hardening script can be individually enabled from its configuration file.
For example, this is the default configuration file for ``disable_system_accounts``:

```
# Configuration for script of same name
status=disabled
# Put here your exceptions concerning admin accounts shells separated by spaces
EXCEPTIONS=""
```

``status`` parameter may take 3 values:
- ``disabled`` (do nothing): The script will not run.
- ``audit`` (RO): The script will check if any change *should* be applied.
- ``enabled`` (RW): The script will check if any change should be done and automatically apply what it can.

You can also set the configuration item to enable by modifying the level, following command: 
1) Generate etc/conf.d/[script_name].cfg by audit-all when first use 
```
# bash bin/hardening.sh --audit-all
```
2) Enable [script_name].cfg by set-hardening-level 
Use the command to set the hardening level to make the corresponding level audit entry take effect. 
```
# bash bin/hardening.sh --set-hardening-level <level>
```
Global configuration is in ``etc/hardening.cfg``. This file controls the log level
as well as the backup directory. Whenever a script is instructed to edit a file, it
will create a timestamped backup in this directory.

### Run aka "Harden your distro (After the hardened, you must perform the "After remediation" section)

To run the checks and apply the fixes, run ``bin/hardening.sh``.

This command has 2 main operation modes:    
- ``--audit``: Audit your system with all enabled and audit mode scripts    
- ``--apply``: Audit your system with all enabled and audit mode scripts and apply changes for enabled scripts    

Additionally, ``--audit-all`` can be used to force running all auditing scripts, including disabled ones. this will *not* change the system.  

``--audit-all-enable-passed`` can be used as a quick way to kickstart your configuration. It will run all scripts in audit mode. If a script passes, it will automatically be enabled for future runs. Do NOT use this option if you have already started to customize your configuration.

Use the command to harden your OS:
```
# bash bin/hardening.sh --apply 
```

### rsyslog config   
If rsyslog is used, and you want to print the harbian-audit log to a separate log file, the configuration is as follows:  
```
user.info			/var/log/harbian-audit.log
user.*				-/var/log/user.log
```
The log will be output to the file /var/log/harbian-audit.log.

If you apply docs/configurations/etc.iptables.rules.v4.sh to your firewall rules, and want to print the iptables log to a separate log file, insert the following lines to rsyslog.conf:  
```
:msg,contains,"FW-"                     -/var/log/firewalllog.log
&                                       stop
```

## After remediation (Very important)
When exec --apply and set-hardening-level are set to 5 (the highest level), you need to do the following:

1) When applying 9.4(Restrict Access to the su Command), you must use the root account to log in to the OS because ordinary users cannot perform subsequent operations. 
If you can only use ssh for remote login, you must use the su command when the normal user logs in. Then do the following:
```
# sed -i '/^[^#].*pam_wheel.so.*/s/^/# &/' /etc/pam.d/su 
```
Temporarily comment out the line containing pam_wheel.so. After you have finished using the su command, please uncomment the line.

2) When applying 7.4.4_hosts_deny.sh, the OS cannot be connected through the ssh service, so you need to set allow access host list on /etc/hosts.allow, example:
```
# echo "ALL: 192.168.1. 192.168.5." >> /etc/hosts.allow
```
This example only allows 192.168.1.[1-255] 192.168.5.[1-255] to access this system. Need to be configured according to your situation. 

3) Set capabilities for usual user, example(user name is test):
```
# sed -i "/^root/a\test    ALL=(ALL:ALL) ALL" /etc/sudoers 
```

4) Set basic firewall rules 
Set the corresponding firewall rules according to the applications used. HardenedLinux community for Debian GNU/Linux basic firewall rules: 

### Iptabels format rules:
[etc.iptables.rules.v4.sh](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/etc.iptables.rules.v4.sh)
to do the following:
```
$ INTERFACENAME="your network interfacename(Example eth0)"
# bash docs/configurations/etc.iptables.rules.v4.sh $INTERFACENAME

# iptables-save > /etc/iptables/rules.v4 
# ip6tables-save > /etc/iptables/rules.v6 
```

### nft format rules:
[nftables.conf](https://github.com/hardenedlinux/harbian-audit/blob/master/docs/configurations/etc.nftables.conf)
to do the following(your network interfacename(Example eth0)):
```
$ sed -i 's/^define int_if = ens33/define int_if = eth0/g' etc.nftables.conf 
# nft -f ./etc.nftables.conf 
```
5) When all repairs are completed. --final method will:
   1. Use passwd command to change the password of the regular and root user to apply the password complexity and robustness of the pam_cracklib module configuration.
   2. Aide reinitializes.
```
# bin/hardening.sh --final
```


## Hacking

**Adding a custom hardening script**

```console
$ cp src/skel bin/hardening/99.99_custom_script.sh
$ chmod +x bin/hardening/99.99_custom_script.sh
$ cp src/skel.cfg etc/conf.d/99.99_custom_script.cfg
```

Code your check explaining what it does then if you want to test

```console
$ sed -i "s/status=.+/status=enabled/" etc/conf.d/99.99_custom_script.cfg
$ bash bin/hardening.sh --audit --only 99.99
$ bash bin/hardening.sh --apply --only 99.99
```
