# Plataforma del equipo (Open edX + Tutor)

Este repo define toda la plataforma: la versión de Tutor, los plugins, la configuración y el código propio. Clonas, corres `make setup` y tu máquina queda igual que la de los demás.

| Carpeta | Qué es | Repo |
| --- | --- | --- |
| `src/openedx-course-payments` | Plugin de pagos con Stripe (Django) | `openedx-course-payments` (submódulo) |
| `src/front-campus` | Sitio público Campus (Nuxt) | `front-campus` (submódulo) |
| `tutor-plugins/` | Plugins de Tutor del equipo | este repo |
| `config/` | Plugins activos, montajes y configuración sin secretos | este repo |
| `.env` | Tus llaves (Stripe). **Nunca se sube a Git** | solo en tu máquina |

Direcciones:

- LMS: http://local.openedx.io:8000
- Studio: http://studio.local.openedx.io:8001
- Campus: http://www.local.openedx.io:3000

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

Revisa que las dos carpetas tengan archivos: `ls src/openedx-course-payments src/front-campus`. Si salen vacías, corre `git submodule update --init --recursive`.

### 1.3 Pon tus llaves

Crea el archivo `.env` en la raíz del repo (`nano .env`) con este contenido:

```bash
COURSE_PAYMENTS_STRIPE_SECRET_KEY=sk_test_...    # solo llaves de prueba (sk_test_), nunca sk_live_
COURSE_PAYMENTS_STRIPE_WEBHOOK_SECRET=whsec_...  # lo obtienes en el paso 1.6
```

### 1.4 Instala la plataforma

Abre Docker Desktop y espera a que diga *Running*. Luego:

```bash
make setup
make admin USER_NAME=admin EMAIL=tu@correo.com
```

`make setup` tarda bastante la primera vez porque descarga y construye las imágenes. `make admin` te pide la contraseña del administrador.

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

Copia el `whsec_...` que aparece, pégalo en `COURSE_PAYMENTS_STRIPE_WEBHOOK_SECRET` dentro de `.env` y corre `make config`. Solo se repite si el `whsec_` cambia.

Listo: abre http://www.local.openedx.io:3000.

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
| El plugin de Stripe (`openedx-course-payments`), ya registrado en `plataforma-equipo` | `make update` |
| Solo Campus (`front-campus`), ya registrado en `plataforma-equipo` | `git pull && git submodule update --init --recursive`, y reinicia `make front` |
| Alguien subió directo al repo `front-campus` o `openedx-course-payments` | Ver la sección siguiente: `make update` no lo trae solo |
| No sé qué cambió | `make update` (siempre es seguro, solo tarda más) |

`make update` hace todo en orden: `git pull`, actualiza los submódulos, aplica configuración y plugins, reconstruye la imagen y reinicia. Apaga la plataforma mientras construye, así que tarda unos minutos.

**Antes de `make update`**, sube lo que tengas a medias dentro de `src/`: actualizar los submódulos los regresa al commit que marca este repo.

### Alguien subió cambios directo a `front-campus` o al plugin de Stripe

**`make update` NO trae esos cambios por sí solo.** Este repo guarda en qué commit está cada submódulo, y `make update` deja cada uno en ese commit guardado. Si alguien abre solo el repo `front-campus` u `openedx-course-payments` y hace push ahí, `plataforma-equipo` sigue apuntando al commit anterior.

Para que el equipo reciba el cambio, **quien lo subió** (o cualquiera) actualiza el commit guardado en `plataforma-equipo`:

```bash
cd ~/plataforma-equipo
git submodule update --remote src/front-campus   # o src/openedx-course-payments: trae lo último de su rama principal
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
| Código Python del plugin de Stripe (vistas, lógica, plantillas) | Nada, el LMS se recarga solo en unos segundos. Si no ves el cambio: `make restart` |
| Modelos del plugin (hay una migración nueva) | `make tutor ARGS="dev exec lms ./manage.py lms migrate"` |
| Dependencias del plugin (`setup.py` o `pyproject.toml`) | `make update` |
| El archivo de Tutor del plugin (`tutor/coursepayments.py`) | `make config` y luego `make restart` |
| `config/tutor.env` o `.env` | `make config` |
| `config/plugins.txt`, `config/mounts.txt`, `tutor-plugins/` o `requirements.txt` | `make update` |

Regla corta: el **código** se recarga solo, la **configuración** es `make config`, y los **plugins o dependencias** son `make update`.

---

## 5. Trabajar dentro de un submódulo

Después de clonar, los submódulos quedan sin rama. Antes de editar, ponte en la rama:

```bash
cd ~/plataforma-equipo/src/openedx-course-payments   # o src/front-campus
git checkout main
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

Así se agregó el plugin de Stripe; para otro son los mismos pasos. Conviene nombrar la carpeta con `openedx-` al inicio (por ejemplo `openedx-mi-plugin`), porque así te ahorras el paso 3.

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

   Si el plugin trae además su propio archivo de Tutor con ajustes (como `tutor/coursepayments.py` en el de Stripe), enlázalo en `tutor-plugins/` para que se active:

   ```bash
   ln -s ../src/openedx-mi-plugin/tutor/miplugin.py tutor-plugins/miplugin.py
   ```

4. **Aplica y comparte.** Corre `make update` (reconstruye la imagen con el plugin instalado) y sube todo:

   ```bash
   git add .gitmodules src/openedx-mi-plugin config/mounts.txt tutor-plugins/
   git commit -m "Agrega mi-plugin"
   git push
   ```

### Quitar un plugin

1. Borra su línea de `config/plugins.txt`, su archivo de `tutor-plugins/` o su línea de `config/mounts.txt`.
2. `make update`. Se desactiva en todas las máquinas.

Si además era un submódulo que ya no se usa: `git rm src/mi-plugin` y commit.

---

## 7. Todos los comandos

| Comando | Para qué |
| --- | --- |
| `make` | Ver esta lista |
| `make setup` | Instalar desde cero (primera vez) |
| `make update` | Traer y aplicar los cambios del equipo |
| `make start` / `make stop` | Encender / apagar la plataforma |
| `make restart` | Reiniciar LMS y Studio |
| `make config` | Aplicar cambios de `config/tutor.env` o `.env` |
| `make front` | Levantar Campus |
| `make stripe` | Recibir los webhooks de prueba de Stripe |
| `make logs` | Ver los errores del LMS (`Ctrl+C` para salir) |
| `make shell` | Consola de Django del LMS |
| `make admin USER_NAME=... EMAIL=...` | Crear un superusuario |
| `make backup` / `make restore BACKUP=backups/...` | Respaldar / restaurar usuarios y cursos |
| `make doctor` | Ver versiones y estado para comparar con otra máquina |
| `make tutor ARGS="..."` | Cualquier comando de Tutor de este proyecto |

No hace falta activar ningún venv: `make` ya usa el Tutor de este repo.

---

## 8. Problemas comunes

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

---

## 9. Otros temas

**Un proyecto a la vez.** Cada repo guarda su Tutor en `.tutor/`, así que los proyectos no se mezclan, pero usan los mismos puertos. Para cambiar: `make stop` en uno y `make start` en el otro.

**Pasar datos a otra persona.** Un curso: Studio → Herramientas → Exportar, y el otro lo importa. Todo (usuarios, cursos, progreso): `make backup`, comparte la carpeta de `backups/` y el otro corre `make restore BACKUP=backups/...`.

**Traer una instalación vieja de `~/.local/share/tutor`:**

```bash
cd ~/plataforma-equipo
TUTOR_ROOT_OVERRIDE=~/.local/share/tutor make backup
TUTOR_ROOT_OVERRIDE=~/.local/share/tutor make stop
make setup
make restore BACKUP=backups/<la carpeta que se creó>
```