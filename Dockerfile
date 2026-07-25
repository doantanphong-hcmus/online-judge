FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/bin:${PATH}"

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    libseccomp-dev \
    gcc \
    g++ \
    fpc \
    openjdk-17-jdk \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir dmoj

WORKDIR /app

RUN /usr/local/bin/dmoj-autoconf || dmoj-autoconf

CMD ["sh", "-c", "/usr/local/bin/dmoj-judge -s --no-cert-check -c judge.yml dmoj-phongdoanvadanem.onrender.com maycham01 '/8scDDobuNV+HrM5ox/wR3q1TtE1tbXYxJgw8YBpbAboAQQ0Mv1YVgP8gC3VS1K50rDubf11qVIdd4+C6wAGSp4dhaV7ZyNv5nVI' & python3 -m http.server $PORT"]
