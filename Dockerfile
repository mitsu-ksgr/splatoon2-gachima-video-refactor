#------------------------------------------------------------------------------
#
# OpenCV & Python3
#
# cf.
# - https://github.com/janza/docker-python3-opencv
# - https://hub.docker.com/r/jjanzic/docker-python3-opencv
#
#------------------------------------------------------------------------------

FROM jjanzic/docker-python3-opencv

COPY ./src /src/

ENTRYPOINT ["/src/entrypoint.sh"]

