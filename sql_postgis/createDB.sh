#!/bin/bash

# Default value
DBNAME=gracethd
DBPORT=5432
DBUSER=
DBHOST=

createDb=false
dropSchema=false
createSchema=false

while test $# -gt 0; do
  case "$1" in
    --help)
      echo "$0 - import schema into db"
      echo " "
      echo "$0 [options]"
      echo " "
      echo "options:"
      echo "-h, --help    Show brief help"
      echo "-d DBNAME     Define DB name, default to ${DBNAME}"
      echo "-p 5432       Define port, default to ${DBPORT}"
      echo "-U postgres   Define user to connect, default to ${DBUSER}"
      echo "-h host       Define hostname, default to ${DBHOST}"
      echo "-D      Drop then create DB, default name is '${DBNAME}'"
      echo "-C      Only create DB, default name is '${DBNAME}'"
      echo "-S      Drop then create Schema 'gracethd'"
      echo "-s      Create Schema 'gracethd'"
      exit 0
      ;;
    -d)
      shift
      if test $# -gt 0; then
        DBNAME=$1
      else
        echo "no DBNAME specified"
        exit 1
      fi
      shift
      ;;
    -p)
      shift
      if test $# -gt 0; then
        DBPORT=$1
      else
        echo "no Port specified"
        exit 1
      fi
      shift
      ;;
    -U)
      shift
      if test $# -gt 0; then
        DBUSER=$1
      else
        echo "no login specified"
        exit 1
      fi
      shift
      ;;
    -h)
      shift
      if test $# -gt 0; then
        DBHOST=$1
      else
        echo "no Hostname specified"
        exit 1
      fi
      shift
      ;;
    -D)
      shift
      createDb=true
      ;;
    -S)
      shift
      dropSchema=true
      createSchema=true
      SCHEMAFLAG=true
      ;;
    -s)
      shift
      if [ !${SCHEMAFLAG} ]
      then
          createSchema=true
      else
        echo "You can have -S and -s flags in the same conmmand line!"
        exit 1
      fi
      
      ;;
    *)
      break
      ;;
  esac
done

DBOPTIONS="-p "${DBPORT}
if [ ! ${DBUSER} == "" ]
then
    DBOPTIONS=${DBOPTIONS}" -U ${DBUSER}"
fi
if [ ! ${DBHOST} == "" ]
then
    DBOPTIONS=${DBOPTIONS}" -h ${DBHOST}"
fi

echo "Use options: "${DBOPTIONS}

if $createDb
then
  echo "Create DB "${DBNAME}" with PostGIS extension"
  createdb -E UTF8 ${DBOPTIONS} ${DBNAME}
  psql -d ${DBNAME} ${DBOPTIONS} -c "CREATE EXTENSION postgis;"
fi

if $dropSchema
then
   echo "Drop schema gracethd"
   psql -d ${DBNAME} ${DBOPTIONS} -c "DROP SCHEMA gracethd CASCADE;"
fi

if $createSchema
then
  echo "Create schema gracethd"
  psql -d ${DBNAME} ${DBOPTIONS} -c "CREATE SCHEMA gracethd;"
fi

echo "Creating list ..."
psql ${DBOPTIONS} -d ${DBNAME} -f gracethd_10_lists.sql
echo "Insert data ..."
psql ${DBOPTIONS} -d ${DBNAME} -f gracethd_20_insert.sql
echo "Creating table ..."
psql ${DBOPTIONS} -d ${DBNAME} -f gracethd_30_tables.sql
echo "Creating something ..."
psql ${DBOPTIONS} -d ${DBNAME} -f gracethd_40_postgis.sql
echo "Creating index ..."
psql ${DBOPTIONS} -d ${DBNAME} -f gracethd_50_index.sql
#psql ${DBOPTIONS} -f gracethd_90_labo.sql

echo "Done!"

