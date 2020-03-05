
cd /Users/kester/dockercontainers/kdr-mdb-10-4-maxscale
docker build --rm -t mdb-test-10-4-maxscale .
docker tag <BUILDHASHID> kesterriley/mdb-test-10-4-maxscale:latest
docker push kesterriley/mdb-test-10-4-maxscale:latest
