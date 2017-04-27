Aws.config.update({
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_ACCESS_SECRET'])
})

s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
S3_BUCKET = s3.bucket(ENV['S3_BUCKET'])
