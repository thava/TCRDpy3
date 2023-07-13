#!/bin/bash

#
# Load preparation steps.
# These util functions are based on the TCRDpy3/doc/README_v7.txt file.
# Please refer to README_v7.txt file for more information.
#


#
# Create empty schema.
# The connection parameters can be specified in a my.cnf file.
# See tcrd.my.cnf file for example format.
#

create_schema_only(){
mysqldump --defaults-file=./tcrd.my.cnf --single-transaction --no-data tcrd | sed 's/ AUTO_INCREMENT=[0-9]*\b//g' > create-TCRDEV.sql
}

#
# Save TCRD core tables with type definitions.
#

save_types_tables(){
mysqldump --defaults-file=./tcrd.my.cnf --single-transaction --no-create-db --no-create-info tcrd cmpd_activity_type compartment_type data_type disease_type expression_type info_type pathway_type phenotype_type ppi_type xref_type > types_tcrdev.sql
}

#
#  Create tcrdev database with all table definitions and load type tables.
#  Take a snapshot of this initial database.
#
init_save_tcrdev_db(){

  mysql --defaults-file=./tcrd.my.cnf  <<EOF

  create database tcrdev;
  use tcrdev
  source create-TCRDev.sql
  source types_tcrdev.sql
  -- SHOW TABLE STATUS FROM `tcrdev`;
  INSERT INTO dbinfo (dbname, schema_ver, data_ver, owner) VALUES ('tcrdev', '7.0.0', '0.0.0', 'iiserb');

EOF

mysqldump --defaults-file=./tcrd.my.cnf --single-transaction tcrdev > create-TCRDev-base.sql

}

#
# Reload the basic minimal TCRD database without data.
#
reload_tcrdev_db(){

  mysql --defaults-file=./tcrd.my.cnf  <<EOF
    drop database tcrdev;
    create database tcrdev;
    use tcrdev;
    source create-TCRDev-base.sql
EOF

}

tcrd_prepare(){
create_schema_only
save_types_tables
init_save_tcrdev_db
}

load_uniprot(){

  # export TCRD_HOST=<hostname_or_ip>
  # export TCRD_USER=root    # Specify mysql user name
  # export TCRD_PASSWORD=my_password

  [ -z "$TCRD_HOST" ] && echo Set TCRD_HOST env variable && return
  [ -z "$TCRD_USER" ] && echo Set TCRD_USER env variable && return
  [ -z "$TCRD_PASSWORD" ] && echo Set TCRD_PASSWORD env variable && return

  echo $TCRD_PASSWORD > ./tcrd_pass

  mkdir -p ../data/EvidenceOntology/
  mkdir -p ../data/UniProt/

  python ./load-UniProt.py --dbhost=$TCRD_HOST --dbname tcrdev --pwfile=./tcrd_pass --dbuser=$TCRD_USER  --loglevel 20 --skip_download 1

}

# tcrd_prepare
# load_uniprot

