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

# Cài đặt dependencies Node và setuptools
RUN npm install -g sass postcss postcss-cli autoprefixer
RUN pip3 install --no-cache-dir --upgrade "setuptools==59.6.0" "wheel" "setuptools-scm<7.0.0"
RUN pip3 install --no-cache-dir --no-build-isolation -r requirements.txt mysqlclient dj-database-url gunicorn whitenoise dmoj

# Tạo file local_settings.py chuẩn
RUN python3 -c "open('dmoj/local_settings.py', 'w').write('import os, dj_database_url\nfrom dmoj.settings import MIDDLEWARE\nfrom django.db.models.signals import post_save\nfrom django.dispatch import receiver\n\nDEBUG = True\nCOMPRESS_ENABLED = False\nALLOWED_HOSTS = [\"*\"]\nDMOJ_SITE_NAME = \"Lớp Chuyên Tin Học\"\nCELERY_TASK_ALWAYS_EAGER = True\nCELERY_TASK_EAGER_PROPAGATES = True\nAUTHENTICATION_BACKENDS = (\"django.contrib.auth.backends.ModelBackend\",)\nSECURE_PROXY_SSL_HEADER = (\"HTTP_X_FORWARDED_PROTO\", \"https\")\nCSRF_TRUSTED_ORIGINS = [\"https://*.onrender.com\", \"https://achuntersoj.onrender.com\"]\nREQUIRE_EMAIL_CONFIRMATION = False\nCONFIRM_INITIAL_EMAIL = False\nREGISTRATION_OPEN = True\nSITE_ID = 1\nEMAIL_BACKEND = \"django.core.mail.backends.console.EmailBackend\"\n\nMIDDLEWARE = (\"whitenoise.middleware.WhiteNoiseMiddleware\",) + tuple(MIDDLEWARE)\nSTATIC_ROOT = \"/app/staticfiles\"\nSTATIC_URL = \"/static/\"\nCOMPRESS_ROOT = \"/app/staticfiles\"\nSECRET_KEY = \"dmoj-secret-key-12345\"\nCACHES = {\"default\": {\"BACKEND\": \"django.core.cache.backends.locmem.LocMemCache\"}}\n\ndb = os.environ.get(\"DATABASE_URL\", \"\")\nDATABASES = {\"default\": dj_database_url.parse(db) if db else {\"ENGINE\": \"django.db.backends.sqlite3\", \"NAME\": \"/app/db.sqlite3\"}}\nif \"mysql\" in DATABASES[\"default\"].get(\"ENGINE\", \"\"):\n    DATABASES[\"default\"][\"OPTIONS\"] = {\"charset\": \"utf8mb4\"}\n\n@receiver(post_save, sender=\"auth.User\")\ndef auto_activate(sender, instance, created, **kwargs):\n    if created:\n        from django.contrib.auth.models import User\n        User.objects.filter(pk=instance.pk).update(is_active=True)\n')"

# Biên dịch SCSS, thu gom static files và tạo cấu hình máy chấm
RUN ./make_style.sh || true
RUN mkdir -p static/jsi18n/vi static/jsi18n/en && touch static/jsi18n/vi/djangojs.js static/jsi18n/en/djangojs.js
RUN python3 manage.py compilejsi18n || true
RUN python3 manage.py collectstatic --noinput || true
RUN dmoj-autoconf > judge.yml

# Tạo user judge
RUN useradd -m -s /bin/bash judge && chown -R judge:judge /app

# Tạo file kịch bản entrypoint.sh khởi động với DJANGO_SETTINGS_MODULE
RUN echo '#!/bin/bash\nexport DJANGO_SETTINGS_MODULE=dmoj.settings\npython3 manage.py migrate --noinput || true\npython3 manage.py shell -c "from django.contrib.sites.models import Site; Site.objects.filter(id=1).update(domain=\x27achuntersoj.onrender.com\x27, name=\x27DMOJ\x27); from django.contrib.auth.models import User; User.objects.filter(username=\x27admin\x27).exists() or User.objects.create_superuser(\x27admin\x27, \x27admin@gmail.com\x27, \x27admin123\x27); User.objects.update(is_active=True); from judge.models import Judge; Judge.objects.update_or_create(name=\x27maycham01\x27, defaults={\x27auth_key\x27: \x27/8scDDobuNV+HrM5ox/wR3q1TtE1tbXYxJgw8YBpbAboAQQ0Mv1YVgP8gC3VS1K50rDubf11qVIdd4+C6wAGSp4dhaV7ZyNv5nVI\x27, \x27is_blocked\x27: False})"\npython3 manage.py runbridged &\npython3 -m dmoj.judge -c judge.yml 127.0.0.1 maycham01 "/8scDDobuNV+HrM5ox/wR3q1TtE1tbXYxJgw8YBpbAboAQQ0Mv1YVgP8gC3VS1K50rDubf11qVIdd4+C6wAGSp4dhaV7ZyNv5nVI" &\nexec gunicorn --bind 0.0.0.0:$PORT --workers 2 --timeout 120 dmoj.wsgi:application\n' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
