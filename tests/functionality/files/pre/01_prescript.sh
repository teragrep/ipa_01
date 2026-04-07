#!/usr/bin/bash
echo "Hi, I am prescript from '$(realpath "${0}")'";
echo success > "/return/$(hostname -s).pre";
