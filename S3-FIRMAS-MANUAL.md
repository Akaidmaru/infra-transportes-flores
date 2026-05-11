# Manual S3 para Firmas

Este documento explica como guardar y leer firmas en S3 de forma segura para el proyecto.
Esta guia esta pensada para desarrollo de aplicacion (backend/frontend), sin detalles internos de infraestructura.

> Importante: valores como bucket, region, rutas y codigo son ejemplos de referencia.
> Adapta los nombres segun el entorno real.

## Datos de referencia (ejemplo del entorno actual)

- **Bucket**: `transportes-flores-vargas-720951496462-app`
- **Region**: `us-east-1`
- **Usuario DB actual**: `tfvadmin` (solo referencia)

## Variables de entorno requeridas (backend)

```env
AWS_REGION=us-east-1
AWS_S3_BUCKET_NAME=transportes-flores-vargas-720951496462-app
```

Si el backend corre en AWS con rol asignado, normalmente no necesitas `AWS_ACCESS_KEY_ID` ni `AWS_SECRET_ACCESS_KEY`.

## Uso de llaves de acceso (AWS Access Key / Secret)

### Recomendacion principal

- En produccion, evita llaves estaticas.
- Usa rol/identidad administrada del entorno (por ejemplo, rol de instancia en AWS).

### Cuando SI usar llaves (temporal/dev local)

Solo para desarrollo local o pruebas controladas:

```env
AWS_ACCESS_KEY_ID=TU_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=TU_SECRET_ACCESS_KEY
AWS_REGION=us-east-1
AWS_S3_BUCKET_NAME=transportes-flores-vargas-720951496462-app
```

### Buenas practicas si usas llaves

- No usar llaves personales del administrador para desarrollo del equipo.
- Crear un usuario tecnico con permisos minimos.
- Guardarlas en secrets (no commitear en repo).
- Rotarlas periodicamente.
- Revocarlas cuando dejen de usarse.

## Flujo recomendado (presigned URL)

1. Frontend pide al backend una URL firmada para subida.
2. Backend genera URL firmada (expira en pocos minutos).
3. Frontend sube directo a S3 con `PUT`.
4. Frontend/backend guarda en DB la `key` del archivo.
5. Para leer, usar URL firmada de lectura (si bucket privado).

## Estructura de keys recomendada

Usar prefijo por usuario para orden y permisos:

`signatures/<userId>/<timestamp>.png`

Ejemplo:

`signatures/123/1711739200000.png`

## Ejemplo backend (NestJS, AWS SDK v3)

```ts
import { S3Client, PutObjectCommand, GetObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3 = new S3Client({ region: process.env.AWS_REGION });
const bucket = process.env.AWS_S3_BUCKET_NAME!;

export async function createUploadUrl(userId: string, mimeType: string) {
  const ext = mimeType === "image/png" ? "png" : "jpg";
  const key = `signatures/${userId}/${Date.now()}.${ext}`;

  const cmd = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    ContentType: mimeType,
  });

  const uploadUrl = await getSignedUrl(s3, cmd, { expiresIn: 300 }); // 5 min
  return { uploadUrl, key };
}

export async function createReadUrl(key: string) {
  const cmd = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  });

  const readUrl = await getSignedUrl(s3, cmd, { expiresIn: 300 }); // 5 min
  return { readUrl };
}
```

## Ejemplo frontend (subida)

```ts
await fetch(uploadUrl, {
  method: "PUT",
  headers: { "Content-Type": file.type },
  body: file,
});
```

Luego guardar la `key` en tu API (por ejemplo: `signatures/123/1711739200000.png`).

## Politica IAM minima recomendada

Permisos para el rol/identidad que use el backend:

- `s3:PutObject`
- `s3:GetObject`
- (opcional) `s3:DeleteObject`

Sobre este prefijo:

- `arn:aws:s3:::transportes-flores-vargas-720951496462-app/signatures/*`

## Seguridad recomendada

- Bucket privado (no publico).
- Validar tipo de archivo (`image/png`, `image/jpeg`).
- Limitar tamano (ej. max 2 MB).
- Usar expiracion corta en URLs firmadas (5 min).
- Guardar solo `key` en DB, no URL permanente.

## Pruebas rapidas

1. Crear URL firmada desde backend.
2. Subir archivo desde frontend con esa URL.
3. Verificar en S3 que el objeto existe.
4. Generar URL firmada de lectura y abrirla en navegador.

## Errores comunes

- **AccessDenied**: faltan permisos IAM en role/usuario.
- **SignatureDoesNotMatch**: region incorrecta o headers distintos.
- **NoSuchBucket**: nombre de bucket mal escrito.
- **ExpiredToken/Request has expired**: URL firmada vencida.

