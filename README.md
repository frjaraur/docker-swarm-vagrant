# docker-swarm-vagrant

· Simple Docker Swarm Environment with Consul, automated install with Vagrant

Exposed Ports:
8501 -> Docker Swarm manager

With this port exposed we can easily talk to swarm cluster using for example:

docker -H tcp://localhost:8501 info

docker -H tcp://localhost:8501 ps

docker -H tcp://localhost:8501 run hello-world
