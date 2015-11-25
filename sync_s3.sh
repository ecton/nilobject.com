rm -rf public
hugo
aws s3 sync --region us-west-2 public/ s3://nilobject-www/
