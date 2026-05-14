# Bitácora: fix RDS + CORS falso (2026-05-14)

## Contexto

- Front en `https://tfv.vectiaq.cl` fallaba login con error de CORS.
- API en `https://api.vectiaq.cl` respondía `502`.
- `app-backend` entraba en bucle `Restarting`.

## Causa raíz real

- Prisma iniciaba con host viejo:
  - `tfv-produccion.c6zwy2260qhw.us-east-1.rds.amazonaws.com`
- Host correcto actual:
  - `tfv-production.c6zwy2260qhw.us-east-1.rds.amazonaws.com`
- El error de navegador "No 'Access-Control-Allow-Origin'" era efecto secundario: backend caído, no CORS de app.

## Hallazgo clave de despliegue

- Editar `/opt/app/.env` no bastaba.
- `docker-compose.yml` generado por workflow tenía `DATABASE_URL` hardcodeado.
- En cada deploy, el workflow sobreescribe `/opt/app/docker-compose.yml`.

## Qué se hizo

1. Verificación en EC2:
   - `docker ps` mostró `app-backend` en `Restarting`.
   - `docker logs app-backend` mostró `P1001` con `tfv-produccion`.
2. Se corrigió host en compose generado:
   - `tfv-produccion` -> `tfv-production`.
3. Se validó conectividad real al RDS nuevo:
   - DNS resuelve (`getent hosts`).
   - Puerto abierto (`nc -vz ... 5432` succeeded).
4. Se detectó que `app-backend` era `container_name`, no nombre de servicio:
   - `docker compose up -d --force-recreate app-backend` falló (`no such service`).
   - Debe usarse el nombre real del servicio (`backend`) o recrear stack completo.

## Lecciones para no repetir

- Siempre validar qué env usa el contenedor:
  - `docker inspect app-backend --format '{{range .Config.Env}}{{println .}}{{end}}' | grep DATABASE_URL`
- Si el workflow genera compose, los cambios manuales son temporales.
- Cambios permanentes deben ir a:
  - Secrets GitHub (`RDS_HOST_*`, `CORS_ORIGIN_*`, etc.).
  - Workflow que renderiza `docker-compose.yml`.

## Estado de compatibilidad "old_origin" (dev)

- Se agregó compatibilidad en código para no romper transición de variables:
  - **Backend (`Muni-backend`)**: combina `CORS_ORIGIN` + `OLD_ORIGIN`/`old_origin`/`CORS_OLD_ORIGIN`.
  - **Frontend (`Muni-front`)**: `axios` usa fallback `VITE_OLD_ORIGIN` si falta `VITE_API_BASE_URL`.
- Esto reduce fallas si un deploy pisa variables nuevas con legadas.

## Checklist post-deploy

- [ ] `docker compose config --services` y recrear servicio correcto.
- [ ] `docker logs app-backend` sin `P1001`.
- [ ] `curl -i http://127.0.0.1:3000/` responde.
- [ ] `OPTIONS https://api.vectiaq.cl/auth/login` devuelve `200/204` con CORS.
- [ ] Login web en `https://tfv.vectiaq.cl` funciona.
