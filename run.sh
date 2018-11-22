#!/bin/bash

freshclam

service clamav-daemon start
service clamav-freshclam start

bundle exec ruby moj-s3-virus-scan.rb
