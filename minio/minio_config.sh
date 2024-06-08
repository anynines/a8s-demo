#!/bin/env sh

#TODO Read from ENV or use defaults
MINIO_HOST="http://minio.minio-dev.svc.cluster.local:9000" # http://localhost:9000
MINIO_ADMIN_ACCESS_KEY="minioadmin"
MINIO_ADMIN_SECRET_KEY="minioadmin"
MINIO_BACKUP_USER_ACCESS_KEY="a8s-user"
MINIO_BACKUP_USER_SECRET_KEY="a8s-password"
MINIO_ALIAS="minio"

MINIO_BACKUP_POLICY="readwrite"
MINIO_BACKUP_BUCKET_NAME="a8s-backups"

mc alias set $MINIO_ALIAS $MINIO_HOST $MINIO_ADMIN_ACCESS_KEY $MINIO_ADMIN_SECRET_KEY

mc admin user add $MINIO_ALIAS $MINIO_BACKUP_USER_ACCESS_KEY $MINIO_BACKUP_USER_SECRET_KEY
mc mb $MINIO_ALIAS/$MINIO_BACKUP_BUCKET_NAME
mc admin policy attach $MINIO_ALIAS $MINIO_BACKUP_POLICY --user=$MINIO_BACKUP_USER_ACCESS_KEY