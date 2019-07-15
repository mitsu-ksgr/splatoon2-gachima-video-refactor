#!/bin/bash +x

#
# Constants
#
readonly SCRIPT_NAME=$(basename $0)
readonly DEFAULT_DOCKER_IMG_NAME='gachima-video-refactor'
readonly DEFAULT_DOCKER_IMG_TAG='latest'

DOCKER_IMG_NAME="${DEFAULT_DOCKER_IMG_NAME}"
DOCKER_IMG_TAG="${DEFAULT_DOCKER_IMG_TAG}"
DOCKER_BUILD_FLAG=false
RUNNING_DOCKER_TAG=

OPT_NUM_OF_PROCESS=5
OPT_FRAME_INTERVAL=10

#
# Prepare temp dir
#
unset TMP_DIR
on_exit() {
    [[ -n "${TMP_DIR}" ]] && rm -rf "${TMP_DIR}";

    # Stop running container
    container_id=$(
        docker ps -aq \
            --filter ancestor=${DOCKER_IMG_NAME}:${DOCKER_IMG_TAG} \
            --filter status=running
    )
    [[ -n "${container_id}" ]] && docker container stop ${container_id}
}
trap on_exit EXIT
trap 'trap - EXIT; on_exit; exit -1' INT PIPE TERM
readonly TMP_DIR=$(mktemp -d "/tmp/${SCRIPT_NAME}.tmp.XXXXXX")


#
# Usage
#
usage () {
    cat << __EOS__
Usage:
    ${SCRIPT_NAME} [-h] [-b] [-t DOCKER_IMAGE:DOCKER_TAG]
        RANKED_MATCH_VIDEO_FILE_PATH OUTPUT_FILE_PATH

Description:
    this script execute get_cut_cmd.py on docker container.

RANKED_MATCH_VIDEO_FILE_PATH:
    path to a ranked match video file.

OUTPUT_FILE_PATH:
    output file path.

Options:
    -h  show usage.
    -b  build the image first.
    -p  number of processes for multi processing.
        default: ${OPT_NUM_OF_PROCESS}
    -i  frame interval to analyze.
        default: ${OPT_FRAME_INTERVAL}
    -t  docker image name:tag, like 'splatoon2analyzer:latest'
        default: ${DEFAULT_DOCKER_IMG_NAME}:${DEFAULT_DOCKER_IMG_TAG}

__EOS__
}

parse_args() {
    while getopts hbt:p:i: flag; do
        case "${flag}" in
            h )
                usage
                exit 0
                ;;
            b )
                DOCKER_BUILD_FLAG=true
                ;;
            t )
                DOCKER_IMG_NAME=${OPTARG%:*}
                DOCKER_IMG_TAG=${OPTARG##*:}
                ;;
            p )
                OPT_NUM_OF_PROCESS=${OPTARG}
                ;;
            i )
                OPT_FRAME_INTERVAL=${OPTARG}
                ;;
            * )
                usage
                exit 0
                ;;
        esac
    done
}

err() {
    echo "Error: $@" 1>&2
    usage
    exit 1
}


#
# Divide the video according to the analyssis results.
#
# Params:
# $1 - input video file path.
# $2 - analysis result file path.
#
# Outputs:
# - Divided videos
# - index file path
#
divide_video() {
    local input_file_path=$1
    local input_file_name=$(basename $1)
    local csv_file_path=$2

    local file_name_base=${input_file_name%.*}
    local file_ext=${input_file_path##*.}

    local index_file_path=${TMP_DIR}/video_index.txt
    touch ${index_file_path}

    # Divide the video every battles.
    local game_count=1
    for line in `cat ${csv_file_path}`; do
        local dat=$(echo ${line} | sed -e "s/[\r\n]\+//g") # remove newline code
        local ss=${dat%,*}
        local duration=${dat##*,}
        local video_file_path="${TMP_DIR}/${file_name_base}_${game_count}.${file_ext}"

        ffmpeg \
            -loglevel panic \
            -ss ${ss} \
            -i ${input_file_path} \
            -t ${duration} \
            -vcodec copy -acodec copy \
            ${video_file_path}
        echo "file '${video_file_path}'" >> ${index_file_path}

        game_count=$((game_count + 1))
    done

    # Returns path of index file.
    echo ${index_file_path}
}


#
# Divide the video according to the analyssis results.
# Merge all videos.
#
# Params:
# $1 - index file path.
# $2 - output file name (not path).
#
# Outputs:
# - path to integrated video file.
#
integrate_videos() {
    local index_file_path=$1
    local output_file_name=$2
    local output_path=${TMP_DIR}/${output_file_name}

    ffmpeg \
        -loglevel panic \
        -safe 0 \
        -f concat \
        -i ${index_file_path} \
        -c copy \
        ${output_path}

    echo ${output_path}
}


#
# main method
#
main() {
    local input_file_path=
    local input_file_name=
    local output_file_path=
    local -r analysis_result_file_path=${TMP_DIR}/analysis_result.csv

    parse_args $@
    shift `expr $OPTIND - 1`

    if $DOCKER_BUILD_FLAG ; then
        docker build -t ${DOCKER_IMG_NAME}:${DOCKER_IMG_TAG} .
    fi

    # Copy video file to tmp_dir
    if [ ! -f "$1" ]; then
        err "file not found! PATH='$1'"
    fi
    input_file_name=$(basename $1)
    input_file_path=${TMP_DIR}/${input_file_name}
    cp $1 ${input_file_path}

    # set output file path.
    if [ -z "$2" ]; then
        output_file_path="./${input_file_name%.*}_mod.${input_file_name##*.}"
    else
        output_file_path=$2
    fi

    # run an analysis and write the results to a tmp file.
    echo -n 'analysing.....'

    # analyze-splatoon2
    #docker run --rm \
    #    -v ${TMP_DIR}:/work \
    #    -t ${DOCKER_IMG_NAME}:${DOCKER_IMG_TAG} \
    #    "/work/${input_file_name}" "/work/" \
    #    >> ${analysis_result_file_path}

    # splatoon2-gachianalyzer
    docker run --rm \
        -v ${TMP_DIR}:/work \
        -t ${DOCKER_IMG_NAME}:${DOCKER_IMG_TAG} \
        "/work/${input_file_name}" \
        -p ${OPT_NUM_OF_PROCESS} -i ${OPT_FRAME_INTERVAL} \
        >> ${analysis_result_file_path}

    echo 'ok!'

    # divide the video according to the analyssis results.
    echo -n 'video editting.....'
    local index_file_path=$(
        divide_video ${input_file_path} ${analysis_result_file_path}
    )
    local integrated_file_name="integrated_file.${input_file_name##*.}"
    local integrated_file_path=$(
        integrate_videos ${index_file_path} ${integrated_file_name}
    )
    echo 'ok!'

    # generate file
    cp ${integrated_file_path} ${output_file_path}
    echo "Succeeded! ${output_file_path}"
}


#
# Entry Point
#
main $@
exit 0

