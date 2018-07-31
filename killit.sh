docker ps -a | grep ky-rpz | awk '{print $1}' | xargs -n 1 docker kill
