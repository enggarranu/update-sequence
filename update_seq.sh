#!/bin/bash

dbname=$1
SCHEMA_NAME=$2
psql -d $dbname -t -c "SELECT table_name, column_name, column_default FROM information_schema.columns WHERE table_schema = '${SCHEMA_NAME}' AND column_default like 'nextval%' ORDER BY ordinal_position;" | awk -F"|" '{print $1$2$3}' | sed '$d' | awk -F " " '{print $1"|"$2"|"$3}'>/var/lib/postgresql/list_seq_${dbname}_${SCHEMA_NAME}
for i in `cat /var/lib/postgresql/list_seq_${dbname}_${SCHEMA_NAME}`
do
    table=`echo $i | awk -F "|" '{print $1}'`
    col=`echo $i | awk -F "|" '{print $2}'`
    seqs=`echo $i | awk -F "|" '{print $3}' | awk -F"'" '{print $2}'`
    table=${SCHEMA_NAME}.${table}
    
    max=`psql -q -t -d $dbname -c "select max($col) from $table" | awk -F" " '{print $1}'`
    echo "updating sequence for table $table with sequence $seqs ...."
    psql ${dbname} -c "select setval('$seqs', coalesce((select max($col) from $table), 1), false);"
    nextseq=`psql -q -t ${dbname} -c "select nextval('$seqs');"`
    nextseqreal=`expr $nextseq + 1`
    echo "max values on table: $max"
    echo "next sequence will be: $nextseqreal"
    echo "update sequence done for sequence $seqs"
    echo "--------------------------------------------"
done
