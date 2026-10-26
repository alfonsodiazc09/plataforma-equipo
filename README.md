# Plataforma del equipo (Open edX + Tutor)

Este repo define toda la plataforma: la versión de Tutor, los plugins, la configuración y el código propio. Clonas, corres `make setup` y tu máquina queda igual que la de los demás.

| Carpeta | Qué es | Repo |
| --- | --- | --- |
| `src/openedx-course-payments` | Plugin del LMS: solo entran quienes pagaron y las páginas de curso van a Campus (Django) | `openedx-course-payments` (submódulo) |
| `src/front-campus` | Sitio público Campus (Nuxt) | `front-campus` (submódulo) |
| `src/campus-cms` | CMS del contador: cursos, precios y ventas; cobra con Stripe y da el acceso en Open edX (Django + DRF, corre en su propio contenedor) | `campus-cms` (submódulo) |
| `tutor-plugins/` | Plugins de Tutor del equipo | este repo |
| `config/` | Plugins activos, montajes y configuración sin secretos | este repo |
| `.env` | Tus llaves (Stripe). **Nunca se sube a Git** | solo en tu máquina |

Direcciones:

- LMS: http://local.openedx.io:8000
- Studio: http://studio.local.openedx.io:8001
- Campus: http://www.local.openedx.io:3000
- Administración de Campus (contadores): http://www.local.openedx.io:3000/admin
- CMS (API): http://campus-cms.local.openedx.io:8010/api/health/

Cómo se conectan: Campus muestra los cursos que el CMS tiene a la venta y manda el botón *Comprar* al CMS, que cobra con Stripe e inscribe al alumno en Open edX. El plugin del LMS solo deja entrar a quien pagó. Los contadores crean cursos, ponen precios y ven las ventas en `/admin` de Campus, que habla con el CMS.

---

## 1. Primera vez (solo una vez por máquina)

### 1.1 Instala lo necesario

| Sistema | Qué instalar |
| --- | --- |
| Windows | WSL2 con Ubuntu y Docker Desktop con la integración WSL activa. Todo se hace **dentro de Ubuntu** (`~/...`), nunca en `/mnt/c`. |
| macOS | Docker Desktop, `xcode-select --install` y `brew install python` |
| Linux | Docker Engine |

En Ubuntu (o Linux):

```bash
sudo apt update
sudo apt install -y git make python3 python3-venv python3-pip curl unzip
```

Node 22.5 o más nuevo (para Campus):

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 22
```

Stripe CLI (para recibir los pagos de prueba): https://docs.stripe.com/stripe-cli

**Memoria en Windows:** crea `C:\Users\<tu usuario>\.wslconfig` con esto y luego corre `wsl --shutdown` en PowerShell:

```ini
[wsl2]
memory=10GB
swap=8GB
```

### 1.2 Clona el repo con sus submódulos

```bash
git clone --recurse-submodules https://github.com/TU_ORG/plataforma-equipo.git ~/plataforma-equipo
cd ~/plataforma-equipo
```

Revisa que las tres carpetas tengan archivos: `ls src/openedx-course-payments src/front-campus src/campus-cms`. Si salen vacías, corre `git submodule update --init --recursive`.

### 1.3 Pon tus llaves

Copia la plantilla y llénala (`cp .env.example .env && nano .env`). Debe quedar así:

```bash
CAMPUS_CMS_STRIPE_SECRET_KEY=sk_test_...    # solo llaves de prueba (sk_test_), nunca sk_live_
CAMPUS_CMS_STRIPE_WEBHOOK_SECRET=whsec_...  # lo obtienes en el paso 1.6
```

### 1.4 Instala la plataforma

Abre Docker Desktop y espera a que diga *Running*. Luego:

```bash
make setup
make admin USER_NAME=admin EMAIL=tu@correo.com
make contador USER_NAME=admin
```

`make setup` tarda bastante la primera vez porque descarga y construye las imágenes (incluida la del CMS) y prepara su base de datos y su cuenta de servicio en Open edX. `make admin` te pide la contraseña del administrador. `make contador` le da el rol Contador para entrar a `/admin` de Campus.

Revisa que el CMS quedó conectado con Open edX:

```bash
make doctor   # al final debe decir == CMS {"status":"ok"}
make tutor ARGS="dev exec campus-cms python manage.py check_openedx"   # debe decir Open edX connection OK
```

### 1.5 Levanta Campus (en otra terminal)

```bash
cd ~/plataforma-equipo
make front
```

### 1.6 Conecta Stripe (en una tercera terminal)

```bash
cd ~/plataforma-equipo
make stripe
```

Copia el `whsec_...` que aparece, pégalo en `CAMPUS_CMS_STRIPE_WEBHOOK_SECRET` dentro de `.env` y corre `make config`. Solo se repite si el `whsec_` cambia. Los pagos los recibe el CMS (`campus-cms`).

Listo: abre http://www.local.openedx.io:3000. Para vender un curso entra a http://www.local.openedx.io:3000/admin con tu usuario contador: crea el curso, ponle precio e imagen, créalo en Open edX y ponlo a la venta. Aparece en el catálogo y se compra con la tarjeta de prueba `4242 4242 4242 4242`.

### 1.7 Ya tenía la plataforma instalada antes del CMS

Corre `make update` (construye el CMS, crea su base y su cuenta de servicio). En tu `.env`, las llaves de Stripe ahora se llaman `CAMPUS_CMS_STRIPE_SECRET_KEY` y `CAMPUS_CMS_STRIPE_WEBHOOK_SECRET` (antes `COURSE_PAYMENTS_STRIPE_...`): cámbiales el nombre, corre `make config` y luego `make contador USER_NAME=<tu usuario>`.

---

## 2. Cada vez que vas a trabajar

1. Abre Docker Desktop y espera a *Running*.
2. Enciende la plataforma:

   ```bash
   cd ~/plataforma-equipo
   make update   # solo si el equipo subió cambios (sección 3)
   make start
   ```

3. En otra terminal: `make front`.
4. Si vas a probar pagos, en otra terminal: `make stripe`.

Al terminar: `Ctrl+C` en las terminales de `make front` y `make stripe`, y luego `make stop`.

---

## 3. El equipo subió cambios: ¿qué corro?

| Qué cambió | Qué corres |
| --- | --- |
| Cualquier cosa de `plataforma-equipo` (config, plugins, versión de Tutor, scripts) | `make update` |
| El plugin del LMS (`openedx-course-payments`) o el CMS (`campus-cms`), ya registrados en `plataforma-equipo` | `make update` |
| Solo Campus (`front-campus`), ya registrado en `plataforma-equipo` | `git pull && git submodule update --init --recursive`, y reinicia `make front` |
| Alguien subió directo al repo `front-campus`, `campus-cms` u `openedx-course-payments` | Ver la sección siguiente: `make update` no lo trae solo |
| No sé qué cambió | `make update` (siempre es seguro, solo tarda más) |

`make update` hace todo en orden: `git pull`, actualiza los submódulos, aplica configuración y plugins, reconstruye la imagen y reinicia. Apaga la plataforma mientras construye, así que tarda unos minutos.

**Antes de `make update`**, sube lo que tengas a medias dentro de `src/`: actualizar los submódulos los regresa al commit que marca este repo.

### Alguien subió cambios directo a un submódulo (`front-campus`, `campus-cms` o el plugin)

**`make update` NO trae esos cambios por sí solo.** Este repo guarda en qué commit está cada submódulo, y `make update` deja cada uno en ese commit guardado. Si alguien abre solo el repo `front-campus`, `campus-cms` u `openedx-course-payments` y hace push ahí, `plataforma-equipo` sigue apuntando al commit anterior.

Los tres submódulos siguen la rama `dev` de su repo (`branch = dev` en `.gitmodules`).

Para que el equipo reciba el cambio, **quien lo subió** (o cualquiera) actualiza el commit guardado en `plataforma-equipo`:

```bash
cd ~/plataforma-equipo
git submodule update --remote src/front-campus   # o src/campus-cms, src/openedx-course-payments: trae lo último de su rama dev
git add src/front-campus
git commit -m "Actualiza front-campus"
git push
```

Después de ese push, los demás ya lo reciben con `make update`.

Para probar en tu máquina lo último de un submódulo sin subir nada: `git submodule update --remote` y luego, según qué cambió, `make restart`, reinicia `make front` o `make update`. El siguiente `make update` lo regresa al commit guardado mientras nadie actualice `plataforma-equipo`.

---

## 4. Modifiqué algo con todo encendido: ¿hay que reiniciar?

Con la plataforma encendida (`make start`) y Campus corriendo (`make front`):

| Modifiqué | Qué hago |
| --- | --- |
| Páginas, componentes o estilos de Campus | Nada, el navegador se actualiza solo |
| `nuxt.config.ts` o variables de entorno de Campus | `Ctrl+C` y `make front` |
| `package.json` de Campus (nueva dependencia) | `Ctrl+C` y `make front` (instala solo) |
| Código Python del plugin del LMS | Nada, el LMS se recarga solo en unos segundos. Si no ves el cambio: `make restart` |
| Modelos del plugin (hay una migración nueva) | `make tutor ARGS="dev exec lms ./manage.py lms migrate"` |
| Dependencias del plugin (`setup.py` o `pyproject.toml`) | `make update` |
| El archivo de Tutor del plugin (`tutor/coursepayments.py`) | `make config` y luego `make restart` |
| Código Python del CMS (`campus-cms`) | Nada, se recarga solo |
| Modelos del CMS (hay una migración nueva) | `make tutor ARGS="dev exec campus-cms python manage.py migrate"` |
| Dependencias del CMS (`requirements.txt` o `Dockerfile` de `campus-cms`) | `make update` |
| El archivo de Tutor del CMS (`tutor/campuscms.py`) | `make config`; si agrega tareas de inicio (`CLI_DO_INIT_TASKS`), `make update` |
| `config/tutor.env` o `.env` | `make config` |
| `config/plugins.txt`, `config/mounts.txt`, `tutor-plugins/` o `requirements.txt` | `make update` |

Regla corta: el **código** se recarga solo, la **configuración** es `make config`, y los **plugins o dependencias** son `make update`.

---

## 5. Trabajar dentro de un submódulo

Después de clonar, los submódulos quedan sin rama. Antes de editar, ponte en la rama:

```bash
cd ~/plataforma-equipo/src/openedx-course-payments   # o src/front-campus, src/campus-cms
git checkout dev
git pull
# ... editas y pruebas ...
git add -A && git commit -m "Describe el cambio"
git push
```

Después actualiza el commit del submódulo en este repo (sección 3) para que el equipo lo reciba.

---

## 6. Agregar o quitar plugins

Todo cambio de plugins es un commit en este repo seguido de `make update`. Al hacer `git push`, los demás lo reciben con su propio `make update`.

### Plugin de la comunidad (por ejemplo `notes` o `forum`)

1. Si no viene incluido en `tutor[full]`, agrega su paquete a `requirements.txt` (por ejemplo `tutor-xyz==21.0.*`).
2. Agrega su nombre en una línea de `config/plugins.txt`.
3. `make update`.

### Plugin propio de Tutor

1. Pon el archivo `.py` o `.yml` en `tutor-plugins/`, o un enlace al que viene dentro de un submódulo:

   ```bash
   ln -s ../src/openedx-course-payments/tutor/coursepayments.py tutor-plugins/coursepayments.py
   ```

2. `make update`. Todo lo que está en `tutor-plugins/` se activa solo.

### Código propio que corre dentro de Open edX (app de Django)

Así se agregó `openedx-course-payments`; para otro son los mismos pasos. Conviene nombrar la carpeta con `openedx-` al inicio (por ejemplo `openedx-mi-plugin`), porque así te ahorras el paso 3.

1. **El código.** Agrega el repo como submódulo:

   ```bash
   git submodule add https://github.com/TU_ORG/openedx-mi-plugin.git src/openedx-mi-plugin
   ```

2. **El montaje.** Escribe a mano `src/openedx-mi-plugin` en una línea nueva de `config/mounts.txt` (no se agrega solo). Así Tutor pone esa carpeta dentro del LMS y tus cambios se ven sin reconstruir.

3. **Que Tutor la instale.** Montar la carpeta no basta: Tutor solo instala la carpeta como app de Django si su nombre está en su lista. Tutor 21 ya acepta solo los nombres que empiezan con `openedx-` (por eso `openedx-course-payments` funciona sin nada extra), los que empiezan con `platform-plugin-` y los que contienen `xblock`.

   - **Si tu carpeta se llama así** (por ejemplo `src/openedx-mi-plugin`), no haces nada en este paso.
   - **Si se llama de otra forma**, agrega esta línea a un plugin de Tutor en `tutor-plugins/` (puede ser un archivo nuevo, `tutor-plugins/miplugin.py`):

     ```python
     from tutor import hooks
     hooks.Filters.MOUNTED_DIRECTORIES.add_item(("openedx", "mi-plugin"))
     ```

   Si el plugin trae además su propio archivo de Tutor con ajustes (como `tutor/coursepayments.py` en `openedx-course-payments`), enlázalo en `tutor-plugins/` para que se active:

   ```bash
   ln -s ../src/openedx-mi-plugin/tutor/miplugin.py tutor-plugins/miplugin.py
   ```

4. **Aplica y comparte.** Corre `make update` (reconstruye la imagen con el plugin instalado) y sube todo:

   ```bash
   git add .gitmodules src/openedx-mi-plugin config/mounts.txt tutor-plugins/
   git commit -m "Agrega mi-plugin"
   git push
   ```

### Servicio propio en su propio contenedor (Django aparte, como `campus-cms`)

Así se agregó `campus-cms`. A diferencia del plugin del LMS, no se monta dentro de Open edX: es otro contenedor de `tutor dev` con su propia base en el MySQL de Tutor. Todo lo define el archivo de Tutor que vive en su repo (`tutor/campuscms.py`).

1. **El código.** Agrega el repo como submódulo y que siga la rama del equipo:

   ```bash
   git submodule add -b dev https://github.com/TU_ORG/mi-servicio.git src/mi-servicio
   ```

2. **El archivo de Tutor.** El repo trae un `Dockerfile` y un plugin de Tutor que define:
   - el contenedor en `local-docker-compose-dev-services` (con `build` apuntando al repo y el repo montado, así el código se recarga solo) y su copia para tareas en `dev-docker-compose-jobs-services`;
   - su configuración en `CONFIG_DEFAULTS` (y los secretos generados una vez por máquina en `CONFIG_UNIQUE`);
   - sus tareas de `tutor dev do init` en `CLI_DO_INIT_TASKS`: crear la base de MySQL, la cuenta de servicio en el LMS y correr `migrate`.

   Enlázalo en `tutor-plugins/` para que se active:

   ```bash
   ln -s ../src/mi-servicio/tutor/miservicio.py tutor-plugins/miservicio.py
   ```

   **No** va en `config/mounts.txt`: ese archivo es solo para código que corre dentro del LMS.

3. **Los scripts de este repo.** Si el servicio tiene que reconstruirse o recrearse, agrégalo como se hizo con `campus-cms`:
   - `scripts/update.sh`: `"$TUTOR" dev dc build mi-servicio` (instala sus dependencias nuevas);
   - `scripts/config.sh`: `"$TUTOR" dev start -d mi-servicio` (recibe la configuración como variables del contenedor, así que hay que recrearlo);
   - `scripts/backup.sh` y `scripts/restore.sh`: su base de MySQL;
   - `Makefile`: `restart` y, si sirve, atajos como `make cms-logs`.

   Sus llaves (Stripe, etc.) van en `.env` con el nombre de su configuración (`CAMPUS_CMS_STRIPE_SECRET_KEY`), y lo que no es secreto en `config/tutor.env`.

4. **Aplica y comparte.** `make update` y sube todo:

   ```bash
   git add .gitmodules src/mi-servicio tutor-plugins/ scripts/ Makefile README.md
   git commit -m "Agrega mi-servicio"
   git push
   ```

### Quitar un plugin

1. Borra su línea de `config/plugins.txt`, su archivo de `tutor-plugins/` o su línea de `config/mounts.txt`.
2. `make update`. Se desactiva en todas las máquinas.

Si además era un submódulo que ya no se usa: `git rm src/mi-plugin` y commit.

---

## 7. El CMS y el área de administración

| Para qué | Comando |
| --- | --- |
| Dar o quitar el rol Contador (entra a `/admin` de Campus) | `make contador USER_NAME=usuario` / `make contador USER_NAME=usuario REMOVE=1` |
| Ver los errores del CMS | `make cms-logs` |
| Revisar la conexión del CMS con Open edX | `make tutor ARGS="dev exec campus-cms python manage.py check_openedx"` |
| Reintentar accesos que fallaron y cerrar pagos sin webhook | `make tutor ARGS="dev exec campus-cms python manage.py reconcile_orders"` (o el botón *Reintentar* en `/admin/ventas`) |
| Correr las pruebas del CMS | `make tutor ARGS="dev exec campus-cms python manage.py test"` |
| Admin de Django del CMS (para revisar datos) | `make tutor ARGS="dev exec campus-cms python manage.py createsuperuser"` y http://campus-cms.local.openedx.io:8010/admin/ |

Nadie tiene contraseña en el CMS: se entra con el usuario de Open edX. El usuario contador inicia sesión en el LMS y Campus llama al CMS con ese login. El rol se puede dar antes de que la persona entre por primera vez.

El CMS habla con Open edX con una cuenta de servicio (`campus_cms_worker`) que crea `make setup` / `make update`. Si la borras o cambias el `CAMPUS_CMS_OAUTH2_CLIENT_SECRET`, corre `make update` para volver a crearla.

---

## 8. Todos los comandos

| Comando | Para qué |
| --- | --- |
| `make` | Ver esta lista |
| `make setup` | Instalar desde cero (primera vez) |
| `make update` | Traer y aplicar los cambios del equipo |
| `make start` / `make stop` | Encender / apagar la plataforma |
| `make restart` | Reiniciar LMS, Studio y el CMS |
| `make config` | Aplicar cambios de `config/tutor.env` o `.env` |
| `make front` | Levantar Campus |
| `make stripe` | Recibir en el CMS los webhooks de prueba de Stripe |
| `make logs` | Ver los errores del LMS (`Ctrl+C` para salir) |
| `make cms-logs` | Ver los errores del CMS (`Ctrl+C` para salir) |
| `make contador USER_NAME=...` | Dar el rol Contador (`REMOVE=1` para quitarlo) |
| `make shell` | Consola de Django del LMS |
| `make admin USER_NAME=... EMAIL=...` | Crear un superusuario |
| `make backup` / `make restore BACKUP=backups/...` | Respaldar / restaurar usuarios, cursos y el CMS (cursos a la venta y ventas) |
| `make doctor` | Ver versiones y estado para comparar con otra máquina |
| `make tutor ARGS="..."` | Cualquier comando de Tutor de este proyecto |

No hace falta activar ningún venv: `make` ya usa el Tutor de este repo.

---

## 9. Problemas comunes

| Síntoma | Solución |
| --- | --- |
| `make: not found` | `sudo apt install -y make` |
| `scripts/...sh: Permission denied` | `chmod +x scripts/*.sh` |
| `docker: not found` o falta `docker.sock` | Docker Desktop no está abierto. Ábrelo; si sigue igual, `wsl --shutdown` en PowerShell y ábrelo de nuevo |
| La construcción se corta con `EOF` | Falta memoria: revisa `.wslconfig`, cierra programas y repite el comando |
| Error de montaje con `redis.conf` | Quedaron contenedores viejos: `docker rm -f $(docker ps -aq --filter name=tutor_)` y repite |
| No llega el correo de activación | En dev no se envían correos. Activa al usuario en http://local.openedx.io:8000/admin/auth/user/ (casilla *Active*) o créalo con `make tutor ARGS="dev do createuser alumno1 alumno1@ejemplo.com"` |
| No abre http://www.local.openedx.io:3000 | Revisa que `make front` siga corriendo; `ss -ltnp \| grep 3000` debe mostrar `0.0.0.0:3000` |
| `make stripe` muestra `[400]` | El `whsec_` de `.env` no coincide: cópialo de nuevo y corre `make config` |
| `make stripe` dice `Falta CAMPUS_CMS_STRIPE_SECRET_KEY` | Tu `.env` tiene los nombres viejos (`COURSE_PAYMENTS_STRIPE_...`): renómbralos (sección 1.7) y corre `make config` |
| `make doctor` dice que el CMS no responde | `make cms-logs`. Si se queda en `Esperando a MySQL...`, espera o corre `make start`; si falla una migración, `make update` |
| `/admin` de Campus dice 403 o no muestra *Administración* | Tu usuario no es contador: `make contador USER_NAME=tu_usuario` |
| `/admin` no carga o dice que el CMS no responde | El contenedor del CMS está apagado: `make start` y revisa `make cms-logs` |
| `check_openedx` falla con `401` o `invalid_client` | La cuenta de servicio no existe o cambió su secreto: `make update` |
| Pagué pero no tengo acceso al curso | `make stripe` no estaba corriendo (no llegó el webhook) o Open edX falló: en `/admin/ventas` usa *Reintentar*, o corre `reconcile_orders` (sección 7) |

---

## 10. Otros temas

**Un proyecto a la vez.** Cada repo guarda su Tutor en `.tutor/`, así que los proyectos no se mezclan, pero usan los mismos puertos. Para cambiar: `make stop` en uno y `make start` en el otro.

**Pasar datos a otra persona.** Un curso: Studio → Herramientas → Exportar, y el otro lo importa (pero no queda a la venta: eso vive en el CMS). Todo (usuarios, cursos, progreso, y del CMS los cursos a la venta, precios y ventas): `make backup`, comparte la carpeta de `backups/` y el otro corre `make restore BACKUP=backups/...`.

**Traer una instalación vieja de `~/.local/share/tutor`:**

```bash
cd ~/plataforma-equipo
TUTOR_ROOT_OVERRIDE=~/.local/share/tutor make backup
TUTOR_ROOT_OVERRIDE=~/.local/share/tutor make stop
make setup
make restore BACKUP=backups/<la carpeta que se creó>
```