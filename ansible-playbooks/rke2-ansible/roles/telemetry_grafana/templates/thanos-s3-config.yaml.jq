type: s3
config:
  bucket: {{ thanos_object_storage_bucket }}
  endpoint: {{ thanos_object_storage_endpoint }}
  region: {{ thanos_object_storage_region }}
  access_key: {{ thanos_access_key }}
  secret_key: {{ thanos_secret_key }}