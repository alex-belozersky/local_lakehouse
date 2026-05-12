import os
from jupyterhub.auth import DummyAuthenticator
from jupyterhub.spawner import LocalProcessSpawner


jupyterhub_user = os.environ.get("JUPYTERHUB_USER", "jovyan")
jupyterhub_password = os.environ.get("JUPYTERHUB_PASSWORD", "jupyter")
notebook_dir = os.environ.get("JUPYTERHUB_NOTEBOOK_DIR", "/home/jovyan/work")


c.JupyterHub.bind_url = "http://0.0.0.0:8000"

c.JupyterHub.cookie_secret_file = "/srv/jupyterhub/runtime/jupyterhub_cookie_secret"
c.JupyterHub.db_url = "sqlite:////srv/jupyterhub/runtime/jupyterhub.sqlite"

c.JupyterHub.authenticator_class = DummyAuthenticator
c.DummyAuthenticator.password = jupyterhub_password

c.Authenticator.allowed_users = {jupyterhub_user}
c.Authenticator.admin_users = {jupyterhub_user}

c.JupyterHub.spawner_class = LocalProcessSpawner

c.Spawner.default_url = "/lab"
c.Spawner.notebook_dir = notebook_dir
c.Spawner.args = []

c.Spawner.environment = {
    # Trino
    "TRINO_HOST": os.environ.get("TRINO_HOST", "trino-coordinator"),
    "TRINO_PORT": os.environ.get("TRINO_PORT", "8080"),
    "TRINO_USER": os.environ.get("TRINO_USER", "admin"),
    "TRINO_PASSWORD": os.environ.get("TRINO_PASSWORD", ""),
    "TRINO_CATALOG": os.environ.get("TRINO_CATALOG", "rest"),
    "TRINO_SCHEMA": os.environ.get("TRINO_SCHEMA", "default"),

    # Polaris
    "POLARIS_CATALOG_NAME": os.environ.get("POLARIS_CATALOG_NAME", "polaris"),
    "POLARIS_CATALOG_URI": os.environ.get("POLARIS_CATALOG_URI", "http://polaris:8181/api/catalog"),
    "POLARIS_WAREHOUSE_NAME": os.environ.get("POLARIS_WAREHOUSE_NAME", "default"),
    "POLARIS_REALM": os.environ.get("POLARIS_REALM", "default-realm"),
    "POLARIS_CLIENT_ID": os.environ.get("POLARIS_CLIENT_ID", ""),
    "POLARIS_CLIENT_SECRET": os.environ.get("POLARIS_CLIENT_SECRET", ""),
    "POLARIS_SCOPE": os.environ.get("POLARIS_SCOPE", "PRINCIPAL_ROLE:ALL"),

    # S3 / MinIO
    "AWS_REGION": os.environ.get("AWS_REGION", "us-east-1"),
    "AWS_DEFAULT_REGION": os.environ.get("AWS_DEFAULT_REGION", "us-east-1"),
    "AWS_ACCESS_KEY_ID": os.environ.get("AWS_ACCESS_KEY_ID", ""),
    "AWS_SECRET_ACCESS_KEY": os.environ.get("AWS_SECRET_ACCESS_KEY", ""),
    "AWS_ENDPOINT_URL": os.environ.get("AWS_ENDPOINT_URL", "http://minio:9000"),
    "AWS_ENDPOINT_URL_S3": os.environ.get("AWS_ENDPOINT_URL_S3", "http://minio:9000"),
    "S3_ENDPOINT": os.environ.get("S3_ENDPOINT", "http://minio:9000"),
    "S3_PATH_STYLE_ACCESS": os.environ.get("S3_PATH_STYLE_ACCESS", "true"),

    # Python
    "PYTHONUNBUFFERED": "1",
}