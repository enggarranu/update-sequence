#!/bin/bash

DB_NAME=$1
SCHEMA_NAME=$2

psql -d ${DB_NAME} -t -Atc "select 'select last_value from ${SCHEMA_NAME}.'|| sequence_name ||' ;' from information_schema.sequences where sequence_schema = '"${SCHEMA_NAME}"';" > /var/lib/postgresql/list_query_get_last_seq_number_${DB_NAME}_${SCHEMA_NAME}

echo "Print list of query:"
cat /var/lib/postgresql/list_query_get_last_seq_number_${DB_NAME}_${SCHEMA_NAME}
echo "----------------------"
echo ""

# empty the alter sequence file
echo "" > /var/lib/postgresql/alter_sequence_query_for_${DB_NAME}_${SCHEMA_NAME}
while read i; do 
    echo "processing-> ${i}"
    sequence_name=`echo $i | awk -F " " '{print $4}'`
    last_value=`psql -d ${DB_NAME} -Atc "${i}" | awk -F" " '{print $1}'`

    alter_query="select setval('${sequence_name}', ${last_value}, false);"
    echo ${alter_query} >> /var/lib/postgresql/alter_sequence_query_for_${DB_NAME}_${SCHEMA_NAME}
done < /var/lib/postgresql/list_query_get_last_seq_number_${DB_NAME}_${SCHEMA_NAME}

echo ""
echo "[Result] ------------------"
echo " Finished, you can find the result on /var/lib/postgresql/alter_sequence_query_for_${DB_NAME}_${SCHEMA_NAME}"
echo "Or Copy-paste the query to new instance:"
cat /var/lib/postgresql/alter_sequence_query_for_${DB_NAME}_${SCHEMA_NAME}
