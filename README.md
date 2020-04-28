# k8s-gcloud-sql-export

An image for exporting mysql databases using `gcloud sql export`, and pushing them to a Google bucket.

## Prerequisites

### Google Resources

- A Google bucket into which dumps will be copied.
- A service-account to peform the backup 
    - Requires `roles/cloudsql.viewer`
* Permissions to enable the DB instance to write (and read) to/from the bucket
    - Requires
        - `roles/storage.legacyBucketWriter`
        - `roles/storage.legacyBucketReader`
        - `roles/storage.objectViewer`

### Environment Variables

| Variable Name                 | Description                                                         | Default |
|-------------------------------|---------------------------------------------------------------------|---------|
| TRACE                         | Enable script tracing                                               | ""      |
| GCLOUD_VERBOSITY              | Verbosity option passed through to `gcloud`                         | debug   |
| GCLOUD_WAIT_TIMEOUT           | Timeout (s) passed through to `gcloud sql operations wait`          | 600     |
| GOOGLE_SQL_INSTANCE_NAME      | Name of SQL instance                                                | N/A     |
| GOOGLE_SQL_BACKUP_BUCKET_PATH | Name of GCS bucket sub-path to export file into                     | N/A     |
| GOOGLE_SQL_BACKUP_BUCKET      | Name of GCS bucket to export to                                     | N/A     |
| DATABASE                      | Name of SQL database to export                                      | N/A     |
| BACKUP_FILENAME               | Backup filename to use, otherwise determined by timestamp           | ""      |
| BACKUP_SCHEDULE               | Create `hourly` or `nightly` backups (forces the creation timestamp)| none    |

## Usage

### Kubernetes

See [cronjob-example.yaml](./hack/cronjob-example.yaml) in the `hack` directory.

### Docker

Create a `.env` file similar to:

```
GOOGLE_SQL_BACKUP_BUCKET=my-bucket-name
GOOGLE_SQL_BACKUP_BUCKET_PATH=some-folder/some-sub-folder
GOOGLE_SQL_INSTANCE_NAME=my-database-instance-name
GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa/creds.json
DATABASE=my-database-name
```

Create a service-account for the database instance with the role `roles/cloudsql-viewer` and place
into `/tmp/sa/creds.json`

```sh
docker build -t k8s-gcloud-export .
docker run -it --env-file .env -v /tmp/sa:/tmp/sa k8s-gcloud-export 
```

## `BACKUP_SCHEDULE`

In the default case (`none`), backup files are generated with a timestamp of `now`.

A filename in GCS will look something like:

```
gs://bucket/bucket-path/2020-03-13T12:36:14+0000_instance-name_db-name.gz
```

Setting `BACKUP_SCHEDULE` to `hourly` would generate:

```
gs://bucket/bucket-path/2020-03-13T12:00:00_instance-name_db-name.gz
```

Setting `BACKUP_SCHEDULE` to `nighly` would generate:


```
gs://bucket/bucket-path/2020-03-13T00:00:00_instance-name_db-name.gz
```

In addition to forcing a timestamp, enabling this feature also checks for the existence of the file in the bucket. 

If the file exists, the script exits (0) without performing the backup.

The use-case for this is to catch issues where multiple runs of the script can queue up (common in k8s if you shutdown
instances).
