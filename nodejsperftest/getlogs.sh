docker exec --user node perftest "/bin/sh" -c "cat /home/node/app/*.log > /home/node/app/combined.log"
docker cp perftest:/home/node/app/combined.log .


