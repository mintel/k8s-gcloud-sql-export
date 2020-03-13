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

| Variable Name                 | Description                                               | Default |
|-------------------------------|-----------------------------------------------------------|---------|
| TRACE                         | Enable script tracing                                     | ""      |
| GOOGLE_SQL_INSTANCE_NAME      | Name of SQL instance                                      | N/A     |
| GOOGLE_SQL_BACKUP_BUCKET_PATH | Name of GCS bucket sub-path to export file into           | N/A     |
| GOOGLE_SQL_BACKUP_BUCKET      | Name of GCS bucket to export to                           | N/A     |
| DATABASE                      | Name of SQL database to export                            | N/A     |
| BACKUP_FILENAME               | Backup filename to use, otherwise determined by timestamp | ""      |

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

Create a service-account for the databace instance with the role `roles/cloudsql-viewer` and place
into `/tmp/sa/creds.json`

```sh
docker build -t k8s-gcloud-export .
docker run -it --env-file .env -v /tmp/sa:/tmp/sa k8s-gcloud-export 
```
