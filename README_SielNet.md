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
# bin/hardening.sh --set-hardening-level 2
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
# passwd USER 
```
