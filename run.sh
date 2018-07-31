docker run --name ky-rpz -p 53:53 -p 53:53/udp  -d yaleman/ky-rpz

sleep 2

docker ps -a
