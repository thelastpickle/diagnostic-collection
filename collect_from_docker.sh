#!/bin/bash
#
# File: collect_from_docker.sh
#
# Created: Friday, June 21 2019
#

DEST_DIR=/tmp/
for host in `docker ps|grep -e dse-server|cut -f 1 -d ' '`; do
    COLLECT_OPTS="-i"
    docker cp collect_node_diag.sh ${host}:/var/tmp/
    LFILE=/var/tmp/${host}.log
    docker exec -ti $host /var/tmp/collect_node_diag.sh $COLLECT_OPTS -P /opt/dse 2>&1 > $LFILE
    IFILE=`cat $LFILE|tr -d '\r'|grep 'Creating archive file'|sed -e 's|^Creating archive file \(.*\)$|\1|'`
    if [ -n "$IFILE" ]; then
        docker cp ${host}:${IFILE} $DEST_DIR
        docker exec $host rm ${IFILE}
    else
        echo "Can't generate diagnostic file"
        cat $LFILE
    fi
    rm -f $LFILE
done
for host in `docker ps|grep -e cassandra|cut -f 1 -d ' '`; do
    set -x
    docker cp collect_node_diag.sh ${host}:/var/tmp/
    docker cp libs/sjk-plus.jar ${host}:/root/
    LFILE=/var/tmp/${host}.log
    docker exec -ti $host /var/tmp/collect_node_diag.sh -t coss $COLLECT_OPTS 2>&1 > $LFILE
    IFILE=`cat $LFILE|tr -d '\r'|grep 'Creating archive file'|sed -e 's|^Creating archive file \(.*\)$|\1|'`
    if [ -n "$IFILE" ]; then
        docker cp ${host}:${IFILE} $DEST_DIR
        docker exec $host rm ${IFILE}
    else
        echo "Can't generate diagnostic file"
        cat $LFILE
    fi
    #rm -f $LFILE
done
./generate_diag.sh $COLLECT_OPTS -r $DEST_DIR
