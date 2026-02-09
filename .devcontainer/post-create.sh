#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Python dependencies..."
pip install -r requirements.txt

echo "==> Installing frontend dependencies..."
yarn --cwd netbox/project-static

echo "==> Creating devcontainer configuration..."
cat > netbox/netbox/configuration_devcontainer.py << 'PYEOF'
ALLOWED_HOSTS = ['*']

DATABASES = {
    'default': {
        'NAME': 'netbox',
        'USER': 'netbox',
        'PASSWORD': 'netbox',
        'HOST': 'postgres',
        'PORT': '',
        'CONN_MAX_AGE': 300,
    }
}

REDIS = {
    'tasks': {
        'HOST': 'redis',
        'PORT': 6379,
        'USERNAME': '',
        'PASSWORD': '',
        'DATABASE': 0,
        'SSL': False,
    },
    'caching': {
        'HOST': 'redis',
        'PORT': 6379,
        'USERNAME': '',
        'PASSWORD': '',
        'DATABASE': 1,
        'SSL': False,
    }
}

SECRET_KEY = 'devcontainer-secret-key-not-for-production-use-change-me-1234567890'

API_TOKEN_PEPPERS = {
    1: 'devcontainer-pepper-not-for-production-use-change-me-12345678',
}

DEBUG = True
DEVELOPER = True

DEFAULT_PERMISSIONS = {}

# Codespaces proxy terminates SSL and forwards HTTP
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
CSRF_TRUSTED_ORIGINS = ['https://*.app.github.dev', 'http://localhost:8000']
PYEOF

echo "==> Running database migrations..."
python netbox/manage.py migrate

echo "==> Creating superuser (admin / admin)..."
python netbox/manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
    print('Superuser created: admin / admin')
else:
    print('Superuser already exists')
"

echo "==> Collecting static files..."
python netbox/manage.py collectstatic --no-input

echo ""
echo "============================================"
echo "  NetBox is ready!"
echo "  Run:  python netbox/manage.py runserver 0.0.0.0:8000"
echo "  Login: admin / admin"
echo "============================================"
