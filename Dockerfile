FROM registry.gitlab.com/tvaughan/docker-unit:latest
MAINTAINER "Tom Vaughan <tvaughan@tocino.cl>"

RUN apt-get -q update                                                           \
    && DEBIAN_FRONTEND=noninteractive                                           \
    apt-get -q -y install                                                       \
        nodejs=*                                                                \
        npm=*                                                                   \
        postgresql-client=*                                                     \
    && apt-get -q clean                                                         \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g uglify-js uglifycss

COPY ./flask-app /opt/flask-app
WORKDIR /opt/flask-app

RUN pip3 install -r requirements.txt
RUN pip3 install -e .

CMD ["make", "serve"]
