#!/bin/bash
#
# Perform a `gcloud sql export` of a database instance to a Google Bucket.
#
# There is an optional `BACKUP_SCHEDULE` environment that can be used to
# validate.
# if the script has already been run, and a nightly or hourly backup has
# already been created.
#
# If this is the case, the script can exit(0) early.
set -o nounset -o errexit -o pipefail

# Enable tracing of the script
[[ -n "${TRACE:-}" ]] && set -x

# GCloud vars
GCLOUD_VERBOSITY=${GCLOUD_VERBOSITY:-"debug"}
GCLOUD_WAIT_TIMEOUT=${GCLOUD_WAIT_TIMEOUT:-"300"}

# Required by gsutil and maybe some other gcloud components 
# since this script doesn't run as root.
export HOME=/tmp

#
# Required variables
#

# GOOGLE_SQL_BACKUP_BUCKET=""
# GOOGLE_SQL_BACKUP_BUCKET_PATH=""
# GOOGLE_SQL_INSTANCE_NAME=""
# DATABASE=""

# BACKUP_SCHEDULE can be used to check if we have successfully performed a backup
# in the last hour or day. This is used to avoid performing multiple backups if we 
# have already run (i.e. if the script runs multiple times in succession).

# Valid options are none|hourly|nightly
BACKUP_SCHEDULE=${BACKUP_SCHEDULE:-"none"}

# Activate a gcloud service account with the location of the credentials file
# passed in as an argument.
function gcloud_activate_service_account() {
  local file="$1"

  gcloud auth activate-service-account --key-file="$file"
  gcloud config set project "$(jq -r .project_id "$file")"
}

# Run the `gcloud sql export` command prefixing the filename with the specified
# `backup_timestamp` argument.
function gcloud_sql_export() {
  local backup_timestamp="$1"
  gcs_backup_path="gs://${GOOGLE_SQL_BACKUP_BUCKET}/${GOOGLE_SQL_BACKUP_BUCKET_PATH}/${backup_timestamp}_${GOOGLE_SQL_INSTANCE_NAME}_${DATABASE}.gz"
  gcloud --verbosity="${GCLOUD_VERBOSITY}" sql export sql "${GOOGLE_SQL_INSTANCE_NAME}" --database "${DATABASE}" "${gcs_backup_path}" \
    || ( echo "Export taking longer than expected - waiting another 5 minutes." ; \
      gcloud --verbosity="${GCLOUD_VERBOSITY}" sql operations wait --timeout "${GCLOUD_WAIT_TIMEOUT}" --quiet $(gcloud sql operations list --instance="${GOOGLE_SQL_INSTANCE_NAME}" --filter='status=RUNNING' --format="value(NAME)") )
}

# Return a GCS filepath, determined by the supplied `backup_timestamp` prefix.
function get_gcs_path_from_timestamp {
  local backup_timestamp="$1"
  local gcs_backup_path="gs://${GOOGLE_SQL_BACKUP_BUCKET}/${GOOGLE_SQL_BACKUP_BUCKET_PATH}/${backup_timestamp}_${GOOGLE_SQL_INSTANCE_NAME}_${DATABASE}.gz"
  echo "${gcs_backup_path}"
}

# Activate service account
gcloud_activate_service_account "${GOOGLE_APPLICATION_CREDENTIALS}"

# Used to determine whether name of previous (or new) backup, based on 
# BACKUP_SCHEDULE setting.
current_day=$(date  '+%Y-%m-%dT00:00:00')
current_hour=$(date '+%Y-%m-%dT%H:00:00')

# Determine if we have already created a backup in the last hour or day.
# If BACKUP_SCHEDULE is NOT SET, we set the timestamp to the current time.
if [[ $BACKUP_SCHEDULE = "nightly" ]] ; then
  gcs_filepath=$(get_gcs_path_from_timestamp "${current_day}")
  if gsutil -q stat "${gcs_filepath}" ; then
    echo "Found existing backup the last 24h with timestamp '${current_day}' - skipping"
    exit 0
  else
    echo "No existing backup found with timestamp '${current_day}' - proceeding"
    backup_timestamp=$(date '+%Y-%m-%dT00:00:00')
  fi
elif [[ $BACKUP_SCHEDULE = "hourly" ]] ; then
  gcs_filepath=$(get_gcs_path_from_timestamp "${current_hour}")
  if gsutil -q stat "${gcs_filepath}" ; then
    echo "Found existing backup the last 1h with timestamp '${current_hour}' - skipping"
    exit 0
  else
    echo "No existing backup found with timestamp '${current_hour}' - proceeding"
    backup_timestamp=$(date '+%Y-%m-%dT%H:00:00')
  fi
else
  backup_timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
  echo "Backup schedule not set - creating backup with timestamp '${backup_timestamp}'"
fi

# Run backup
gcloud_sql_export "${backup_timestamp}"
