#!/usr/bin/bash
echo "Hi, I am postscript from '$(realpath "${0}")'";
echo success > "/return/$(hostname -s).post";
