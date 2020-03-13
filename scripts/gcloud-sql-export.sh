#!/bin/bash
set -o nounset -o errexit -o pipefail
[[ -n "${TRACE:-}" ]] && set -x

function gcloud_activate_service_account() {
  local file="$1"

  gcloud auth activate-service-account --key-file="$file"
  gcloud config set project "$(jq -r .project_id "$file")"
}


DATESTAMP=$(date -Iseconds) 
GCS_BACKUP_PATH="gs://${GOOGLE_SQL_BACKUP_BUCKET}/${GOOGLE_SQL_BACKUP_BUCKET_PATH}/${DATESTAMP}_${GOOGLE_SQL_INSTANCE_NAME}_${DATABASE}.gz"

gcloud_activate_service_account "${GOOGLE_APPLICATION_CREDENTIALS}"

gcloud --verbosity=debug sql export sql "${GOOGLE_SQL_INSTANCE_NAME}" "${GCS_BACKUP_PATH}" --database "${DATABASE}"
