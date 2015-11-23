pushd
cd %~dp0
hugo
aws s3 sync public\ s3://nilobject-www/
popd
