# Anne Nail Studio

Aplicación Flutter para Anne Nail Studio. Las citas se guardan en MySQL a través de una API Node.js; la app nunca se conecta directamente a MySQL.

## Iniciar la base de datos y la API

Se requiere Docker Desktop con Docker Compose. Desde la raíz del proyecto:

1. Copia `.env.example` a `.env` y cambia las dos contraseñas de ejemplo por valores distintos. Son solo credenciales locales de desarrollo.
2. Construye e inicia MySQL y la API:

   ```sh
   docker compose up --build -d
   ```

   MySQL crea la base `anne_nail_studio` y carga `backend/schema.sql` automáticamente al inicializar un volumen nuevo. Los datos se conservan en el volumen `mysql-data` al detener o recrear los contenedores.
3. Comprueba `http://localhost:3000/api/health`; debe responder `{"status":"ok","database":"connected"}`. Este chequeo también confirma que existe la tabla de citas.

Para ver el estado: `docker compose ps`. Para detener los servicios sin borrar datos: `docker compose down`. **No uses `docker compose down -v` si necesitas conservar las citas**, porque elimina el volumen de la base.

Para ejecutar Flutter:

```sh
flutter run
```

En Android Emulator la app usa `http://10.0.2.2:3000/api`; en Flutter Web usa `http://localhost:3000/api`. En un dispositivo físico, configura la IP local del equipo que ejecuta Docker:

```sh
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api
```

## Google Calendar y reservas

En `.env`, configura `GOOGLE_CALENDAR_ID`, `GOOGLE_OAUTH_CLIENT_ID`, la zona horaria y el horario del estudio. Para las credenciales de la cuenta de servicio, coloca el JSON en `backend/.credentials/service-account.json` (directorio ignorado por Git y Docker build) o proporciona `GOOGLE_SERVICE_ACCOUNT_JSON` en el entorno. Comparte el calendario del estudio con el correo de la cuenta de servicio.

El esquema de nuevas instalaciones incluye el servicio Signature actual. Si la base de datos ya existía, ejecuta una sola vez `backend/migrations/001_booking.sql`:

```sh
docker compose exec -T db mysql -u anne_nail_app -p"$DB_PASSWORD" anne_nail_studio < backend/migrations/001_booking.sql
```

Configura un OAuth Web Client ID válido igual a `GOOGLE_OAUTH_CLIENT_ID` y `AppConfig.googleServerClientId`; la API verifica el ID token de Google antes de aceptar una reserva. Los valores del archivo `.env.example` son marcadores y deben reemplazarse.

La configuración incluida es para desarrollo local. Para producción, usa HTTPS y protege las credenciales de la cuenta de servicio con el gestor de secretos del proveedor.
