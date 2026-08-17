# Bibliotk — Sistema de reseñas de libros

Aplicación Ruby on Rails con PostgreSQL y GraphQL para gestionar libros, usuarios y reseñas. El proyecto está diseñado para mantener los promedios de calificación precalculados, excluir automáticamente las reseñas de usuarios baneados y mantener la consistencia de los promedios bajo operaciones concurrentes.

## Características

* **Gestión de reseñas:** creación, edición y eliminación de reseñas con calificaciones de 1 a 5 estrellas.
* **Promedios cacheados:** los libros almacenan `average_rating` y `reviews_count`, evitando recalcular el promedio de todas las reseñas en cada consulta.
* **Redondeo half-up:** por ejemplo, `3.25 → 3.3`.
* **Mínimo de reseñas:** los libros con menos de 3 reseñas muestran `Reseñas Insuficientes`.
* **Usuarios baneados:** las reseñas de usuarios baneados se excluyen de los promedios y consultas.
* **Recalculo automático:** banear o desbanear un usuario actualiza los promedios de los libros afectados.
* **Seguridad ante concurrencia:** se utiliza locking pesimista mediante `with_lock` para evitar condiciones de carrera al actualizar los promedios.
* **Restricción de unicidad:** la base de datos evita que un usuario cree más de una reseña para el mismo libro.
* **GraphQL API:** queries y mutations para interactuar con libros, reseñas y usuarios.
* **RSpec:** tests de modelos, requests y GraphQL.

## Stack

* Ruby on Rails
* Ruby 3.4
* PostgreSQL 16
* GraphQL-Ruby
* RSpec
* RuboCop
* Docker Compose
* Node.js / npm
* GitHub Actions

## Prerrequisitos

* Docker
* Docker Compose
* WSL si se ejecuta en Windows

## Instalación de Docker

Si aún no tienes Docker Engine instalado (guía oficial: [docs.docker.com/engine/install/ubuntu](https://docs.docker.com/engine/install/ubuntu/)), sigue estos pasos en tu terminal de Ubuntu/WSL:

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

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/arv0297/HappyComunity.git
cd HappyComunity
```

### 2. Configurar variables de entorno

Crear un archivo `.env` en la raíz del proyecto:

```env
POSTGRES_USER=tu_usuario
POSTGRES_PASSWORD=tu_password
POSTGRES_DB=tu_base_de_datos
SECRET_TOKEN=token_secreto
```

### 3. Construir e iniciar los contenedores

```bash
docker compose up --build
```

Para ejecutarlos en segundo plano:

```bash
docker compose up -d
```

### 4. Ejecutar las migraciones

```bash
docker compose exec web bundle exec rails db:migrate
```

### 5. Compilar los assets de JavaScript

```bash
docker compose exec web npm run build
```

La aplicación estará disponible en:

* Aplicación: `http://localhost:3000`
* GraphiQL: `http://localhost:3000/graphiql`

## Desarrollo

### Consola Rails

```bash
docker compose exec web bundle exec rails console
```

### Ejecutar toda la suite RSpec

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
```

### Ejecutar tests de modelos

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec spec/models
```

### Ejecutar tests de requests / GraphQL

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec spec/requests
```

### Ejecutar system tests

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec spec/system
```

### Ejecutar RuboCop

```bash
docker compose exec web bundle exec rubocop
```

Para autocorrección:

```bash
docker compose exec web bundle exec rubocop -a
```

## API GraphQL

GraphiQL está disponible en:

```text
http://localhost:3000/graphiql
```

### Consultar libros

```graphql
query {
  topBooks(limit: 50) {
    id
    title
    author
    averageRating
    reviewsCount
    averageRatingDisplay
  }
}
```

### Obtener un libro

```graphql
query {
  book(id: "1") {
    id
    title
    author
    averageRating
    reviewsCount
  }
}
```

### Obtener reseñas de un libro

Las reseñas de usuarios baneados son excluidas:

```graphql
query {
  reviews(bookId: "1") {
    id
    rating
    content
    user {
      id
      name
      banned
    }
  }
}
```

### Crear una reseña

```graphql
mutation {
  createReview(
    input: {
      bookId: "1"
      email: "usuario@example.com"
      password: "password"
      rating: 5
      content: "Excelente libro"
    }
  ) {
    review {
      id
      rating
      content
    }
    errors
  }
}
```

### Actualizar una reseña

```graphql
mutation {
  updateReview(
    input: {
      id: "1"
      email: "usuario@example.com"
      password: "password"
      rating: 4
      content: "Actualicé mi reseña"
    }
  ) {
    review {
      id
      rating
      content
    }
    errors
  }
}
```

### Eliminar una reseña

```graphql
mutation {
  deleteReview(
    input: {
      id: "1"
      email: "usuario@example.com"
      password: "password"
    }
  ) {
    success
    errors
  }
}
```

### Banear un usuario

```graphql
mutation {
  banUser(input: { userId: "1" }) {
    user {
      id
      banned
    }
    errors
  }
}
```

### Desbanear un usuario

```graphql
mutation {
  unbanUser(input: { userId: "1" }) {
    user {
      id
      banned
    }
    errors
  }
}
```

## Cálculo de promedios

Los libros mantienen dos valores precalculados:

```text
average_rating
reviews_count
```

En lugar de calcular el promedio de las reseñas cada vez que se consulta el home, el sistema utiliza estos valores almacenados.

El promedio se actualiza cuando:

* se crea una reseña;
* se modifica una reseña;
* se elimina una reseña;
* un usuario es baneado;
* un usuario es desbaneado.

Las reseñas pertenecientes a usuarios baneados no participan en el cálculo.

Esto permite que obtener el promedio de un libro sea independiente de la cantidad de reseñas asociadas al libro.

## Concurrencia

Las actualizaciones del promedio utilizan locking pesimista mediante `with_lock` sobre el registro de `Book`.

Esto evita que dos operaciones concurrentes lean el mismo estado anterior y sobrescriban los resultados entre sí.

Además, la base de datos mantiene una restricción de unicidad para impedir reseñas duplicadas del mismo usuario sobre el mismo libro.

La combinación de:

* validaciones a nivel de aplicación;
* restricciones de base de datos;
* locking pesimista;

permite mantener la consistencia incluso bajo operaciones concurrentes.

## Performance

El proyecto incluye scripts para generar datos de prueba y comparar el acceso a promedios cacheados con el cálculo del promedio directamente desde las reseñas.

### Generar datos de prueba

```bash
docker compose exec web bundle exec rails runner db/seeds_performance.rb
```

### Ejecutar benchmark

```bash
docker compose exec web bundle exec rails runner scripts/measure_performance.rb
```

El benchmark compara:

1. Obtener 50 libros utilizando `average_rating` y `reviews_count`.
2. Obtener 50 libros y calcular el promedio recorriendo sus reseñas.
3. Obtener el promedio de un libro individual mediante el valor cacheado.
4. Calcular el promedio del mismo libro directamente desde sus reseñas.

El objetivo es demostrar que el acceso al promedio cacheado no depende de la cantidad de reseñas asociadas al libro.

## Testing

La suite incluye pruebas para:

* cálculo de promedios;
* redondeo half-up;
* mínimo de 3 reseñas;
* creación, modificación y eliminación de reseñas;
* exclusión de usuarios baneados;
* recálculo después de banear/desbanear usuarios;
* unicidad de reseñas;
* operaciones concurrentes;
* queries GraphQL;
* mutations GraphQL;
* system tests.

Ejecutar toda la suite:

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
```

## CI

El proyecto utiliza GitHub Actions para ejecutar automáticamente:

* análisis de seguridad de Rails con Brakeman;
* auditoría de dependencias Ruby con Bundler Audit;
* auditoría de dependencias JavaScript;
* RuboCop;
* RSpec;
* system tests.

## Decisiones de arquitectura

Las principales decisiones y trade-offs del proyecto están documentados en [`DECISIONES.md`](DECISIONES.md).

El documento incluye:

* interpretación de requisitos ambiguos;
* decisiones de diseño;
* trade-offs;
* consideraciones de concurrencia;
* aspectos pendientes antes de producción;
* mejoras que podrían realizarse con más tiempo.

## Licencia

Copyright (C) 2026 Alexander Rogers Valdés

Este programa es software libre: puedes redistribuirlo y/o modificarlo bajo los términos de la GNU Affero General Public License publicada por la Free Software Foundation, ya sea la versión 3 de la Licencia o, a su elección, cualquier versión posterior.