Aws.config.update({
  credentials: Aws::Credentials.new("Key", "Secret")
})

s3 = Aws::S3::Resource.new(region: 'region')
S3_BUCKET = s3.bucket('bucket_name')
