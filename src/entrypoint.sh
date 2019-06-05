#!/bin/bash

#------------------------------------------------------------------------------
#
# entrypoint.sh
#
# this script takes agrs from `docker run` command and
# passes them to get_cut_cmd.py
#
#------------------------------------------------------------------------------

python /src/analyze-splatoon2/get_cut_cmd.py $@

exit 0
