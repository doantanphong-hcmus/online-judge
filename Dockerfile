FROM ubuntu:22.04

# Bỏ qua bước chờ tương tác chọn múi giờ
ENV DEBIAN_FRONTEND=noninteractive

# Cài đặt trọn bộ Python, C++, Free Pascal, Java trên Ubuntu 22.04 chuẩn DMOJ
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

# Cài đặt dmoj máy chấm
RUN pip3 install --no-cache-dir dmoj

WORKDIR /app

# Tự động cấu hình các trình biên dịch
RUN dmoj-autoconf

# Chạy máy chấm kết nối về Web Render 24/7
CMD ["sh", "-c", "dmoj-judge -c judge.yml https://dmoj-phongdoanvadanem.onrender.com maycham01 '/8scDDobuNV+HrM5ox/wR3q1TtE1tbXYxJgw8YBpbAboAQQ0Mv1YVgP8gC3VS1K50rDubf11qVIdd4+C6wAGSp4dhaV7ZyNv5nVI' & python3 -m http.server $PORT"]
