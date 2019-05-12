#!/bin/bash
## Script to create mailserver

# remove native version postfix

#yum remove postfix

#cp post_repo.repo /etc/yum.repos.d/gf.repo

yum clean all ; yum update
