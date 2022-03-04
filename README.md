# Staytus

Staytus is a complete solution for publishing the latest information about
any issues with your web applications, networks or services. Along with
absolutely beautiful public & admin interfaces, Staytus is a powerful tool for
any organization with customers that rely on them to be online 24/7.

App: https://github.com/adamcooke/staytus <br>
Dockerfile: https://github.com/galexrt/container-staytus

## Docker installation

Before you start, you'll need a server running Docker.
Learn more on how to install Docker on their website: https://docs.docker.com/get-docker/

First pull the image of Staytus to your server using...
```text
docker pull hostingme/staytus:main
```

Next we'll need to create a network so Staytus and the database can communicate...
```text
docker network create staytus
```

Now we can create the database container. We're going to be using MariaDB for this...
```text
docker run \
    -d \
    --name=database \
    --net=staytus \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    -e MYSQL_DATABASE=staytus \
    -e MYSQL_USER=staytus \
    -e MYSQL_PASSWORD=staytus \
    mariadb:10.4.4-bionic
```

Lastly we can start the Staytus container with the following environments variables...
```text
docker run \
    -d \
    --name=staytus \
    --net=staytus \
    -p 0.0.0.0:80:8787 \
    -e 'DB_HOST=database' \
    -e 'DB_USER=staytus' \
    -e 'DB_PASSWORD=staytus' \
    hostingme/staytus:main
```

That's it. Now you can visit your Staytus page typing `YOUR_SERVER_IP` into a web browser.

## How to use a domain name instead of server IP
Create an `A Record` for the domain or sub-doamin and point it to the IP address of the server.

## How to add SSL
We're going to be using <a href="https://caddyserver.com">Caddy</a> to setup a basic web server which automatically adds HTTPS via <a href="https://letsencrypt.org">Let's Encrypt</a>.

In order to run our Staytus container over HTTPS we need to change the ports our Staytus container is listening on. To do this we'll need to stop and remove the excisting running container. To do this follow these steps...
```text
docker stop staytus
docker rm staytus
```

Now that we have stopped and removed the container we can rebuild it using the updated ports...
```text
docker run \
    -d \
    --name=staytus \
    --net=staytus \
    -p 8787:8787 \
    -e 'DB_HOST=database' \
    -e 'DB_USER=staytus' \
    -e 'DB_PASSWORD=staytus' \
    hostingme/staytus:main
```

Next we need to build the Caddy containter. This is done in a very similar way to how we build the Staytus container however we need to provide Caddy with some configuration files so it knows what to do.

First, create a `Caddyfile` at `/opt/staytus/Caddyfile` and copy the below into it. Make sure you change the domain (example.com) to your domain name.

```text
 example.com {
    reverse_proxy staytus:8787
}
```

Lets also create a directory where Caddy can store its data. We've called it `caddy-data` and it can be found at `/opt/staytus/caddy-data`

With the above config files created we can build our Caddy container.

```text
docker run -d --name caddy \
    -p 80:80 \
    -p 443:443 \
    -v /opt/staytus/Caddyfile:/etc/caddy/Caddyfile \
    -v /opt/staytus/caddy-data:/data \
    caddy
```

Finally we need to create a new Docker network and connect it to our Caddy and Staytus containers so they can communicate with eachother. Run the following command...
```text
docker network create caddy
docker network connect caddy staytus
docker network connect caddy caddy
```
## Starting containers automatically
You can use docker <a href="https://docs.docker.com/config/containers/start-containers-automatically/" target="_blank">restart policies</a> to control whether your containers start automatically when they exit, or when server restarts.
```text
docker run -d --restart unless-stopped database
docker run -d --restart unless-stopped caddy
docker run -d --restart unless-stopped staytus
```
