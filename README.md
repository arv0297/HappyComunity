# HappyProyect

Una aplicación Ruby on Rails ejecutándose dentro de Docker Compose con PostgreSQL.

## Prerrequisitos

- Docker y Docker Compose
- WSL (Windows Subsystem for Linux) en Windows

## Instalación de Docker

### 1. Desinstalar versiones conflictivas antiguas (por si acaso)

```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc | cut -f1)
```

### 2. Agregar la llave GPG oficial de Docker

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### 3. Agregar el repositorio a las fuentes de Apt

```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

### 4. Instalar Docker Engine, CLI, containerd y el plugin de Compose

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 5. Verificar que funciona

```bash
sudo docker run hello-world
```

### 6. (Opcional, recomendado) Usar Docker sin sudo

```bash
sudo usermod -aG docker $USER
```

Luego cerrar y abrir una terminal, o reiniciar WSL:

```bash
wsl --shutdown
```

## Configuración del Proyecto

### 1. Crear archivo `.env`

Crear un archivo `.env` en la raíz del proyecto con el siguiente contenido:

```env
POSTGRES_USER=tu_usuario
POSTGRES_PASSWORD=tu_password
POSTGRES_DB=tu_base_de_datos
SECRET_TOKEN=token_secreto
```

### 2. Construir e iniciar el proyecto

```bash
docker compose up --build
```

Para mantener los contenedores ejecutándose en segundo plano:

```bash
docker compose up -d
```

### 3. Actualizar las migraciones de la base de datos

```bash
docker compose exec web rails db:migrate
```

### 4. Correr archivo semilla

```bash
docker compose exec web rails runner db/seeds_performance.rb
```

### 5. Instalar librerías para React

```bash
docker compose exec web npm run build
```

## Comandos de Desarrollo

### Abrir la consola del proyecto

```bash
docker compose exec web bundle exec rails console
```


### Crear BDD de test para testing

```bash
docker compose run --rm -e RAILS_ENV=test web bin/rails db:create
```

### Examinar RSpec

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec```

### Ejecutar RuboCop

```bash
docker compose exec web bundle exec rubocop
```

## Estructura del Proyecto

- `web`: Servicio de aplicación Rails
- `db`: Servicio de base de datos PostgreSQL 16

La aplicación es accesible en `http://localhost:3000`

## Licencia

Copyright (C) 2026 Alexander Rogers Valdés

Este programa es software libre: puedes redistribuirlo y/o modificarlo
bajo los términos de la GNU Affero General Public License publicada
por la Free Software Foundation, ya sea la versión 3 de la Licencia, o
(a su elección) cualquier versión posterior.