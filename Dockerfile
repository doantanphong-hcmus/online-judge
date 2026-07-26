FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Cài đặt trọn bộ Node20, Python3, C++, Free Pascal, Java, libseccomp
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    libseccomp-dev \
    gcc \
    g++ \
    fpc \
    openjdk-17-jdk \
    git \
    nodejs \
    pkg-config \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy toàn bộ mã nguồn
COPY . .

# Cài đặt dependencies Node và ghim setuptools==59.6.0 để cài DMOJ mượt mà
RUN npm install -g sass postcss postcss-cli autoprefixer
RUN pip3 install --no-cache-dir --upgrade "setuptools==59.6.0" "wheel" "setuptools-scm<7.0.0"
RUN pip3 install --no-cache-dir --no-build-isolation -r requirements.txt mysqlclient dj-database-url gunicorn whitenoise dmoj

# Biên dịch SCSS và cấu hình máy chấm
RUN ./make_style.sh || true
RUN mkdir -p static/jsi18n/vi static/jsi18n/en && touch static/jsi18n/vi/djangojs.js static/jsi18n/en/djangojs.js
RUN dmoj-autoconf > judge.yml

# Tạo user judge
RUN useradd -m -s /bin/bash judge && chown -R judge:judge /app

# Khởi chạy đồng thời cả Web chính, Bộ kết nối ngầm và Máy chấm bài 127.0.0.1
CMD ["sh", "-c", "python3 manage.py runbridged & python3 -m dmoj.judge -c judge.yml 127.0.0.1 maycham01 '/8scDDobuNV+HrM5ox/wR3q1TtE1tbXYxJgw8YBpbAboAQQ0Mv1YVgP8gC3VS1K50rDubf11qVIdd4+C6wAGSp4dhaV7ZyNv5nVI' & gunicorn --bind 0.0.0.0:$PORT --workers 2 --timeout 120 --env DJANGO_SETTINGS_MODULE=dmoj.settings dmoj.wsgi:application"]
