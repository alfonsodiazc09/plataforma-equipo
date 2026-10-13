# Plataforma del equipo (Open edX + Tutor)

Un solo repo que define **toda** la plataforma: versión de Tutor, plugins, configuración y código propio. Cada persona clona el repo y corre un comando; nadie configura nada a mano, así todas las máquinas quedan iguales.

## Primera vez

Requisitos según tu sistema:

| Sistema | Qué instalar |
| --- | --- |
| Windows | WSL2 con Ubuntu, Docker Desktop con integración WSL activa, y en Ubuntu `sudo apt install git make python3-venv`. Trabaja dentro de Ubuntu (`~/...`), no en `/mnt/c`. |
| macOS (Intel o Apple Silicon) | Docker Desktop para Mac, y en la terminal `xcode-select --install` (trae `git` y `make`) y Python 3 (`brew install python`). |
| Linux | Docker Engine, `git`, `make` y `python3-venv`. |

En Docker Desktop (Windows o Mac) asigna al menos **8 GB de RAM** (mejor 12) y **80 GB de disco** en *Settings → Resources*. En Windows la RAM se configura en `.wslconfig`.

```bash
git clone --recurse-submodules https://github.com/TU_ORG/plataforma.git ~/plataforma
cd ~/plataforma
cp .env.example .env   # llena tus llaves (Stripe, etc.)
make setup
make admin USER_NAME=admin EMAIL=tu@correo.com
```

LMS: http://local.openedx.io:8000 · Studio: http://studio.local.openedx.io:8001

No hace falta activar ningún venv: los comandos `make` ya usan el Tutor de este repo.

## Día a día

| Quiero... | Comando |
| --- | --- |
| Ver todos los comandos | `make` |
| Traer lo que subió el equipo | `make update` |
| Encender / apagar | `make start` / `make stop` |
| Ver cambios de mi código montado | `make restart` |
| Ver errores | `make logs` |
| Respaldar mis usuarios y cursos | `make backup` |
| Restaurar un respaldo | `make restore BACKUP=backups/2026-10-13_1500` |
| Comparar mi máquina con la de otro | `make doctor` |
| Cualquier otro comando de Tutor | `make tutor ARGS="config printvalue LMS_HOST"` |

## Cómo se cambia algo para todo el equipo

Todo cambio es un commit; los demás lo reciben con `make update`.

| Cambio | Archivo |
| --- | --- |
| Subir de versión Tutor / Open edX | `requirements.txt` |
| Activar o quitar un plugin de la comunidad | `config/plugins.txt` |
| Agregar un plugin propio de Tutor | un archivo en `tutor-plugins/` |
| Nombre, idioma, colores y otra configuración sin secretos | `config/tutor.env` |
| Código propio (plugin de Django, MFE) | submódulo en `src/` + su ruta en `config/mounts.txt` |
| Llaves y contraseñas | **solo** en tu `.env` local (nunca en Git) |

`make update` deja la máquina **exactamente** como dice el repo: si alguien quita un plugin de la lista, se desactiva en todas las máquinas.

## Por qué ya no se mezclan proyectos

Cada repo guarda su propio Tutor en la carpeta `.tutor/` (configuración, bases de datos y archivos generados), en lugar de usar `~/.local/share/tutor` para todo. Cambiar de proyecto es cambiar de carpeta:

```bash
cd ~/proyecto-a && make stop
cd ~/proyecto-b && make start
```

Enciende solo un proyecto a la vez, porque todos usan los mismos puertos (8000, 8001...).

## Pasar datos entre personas

- **Un curso:** Studio → Herramientas → Exportar (`.tar.gz`), y el otro hace Importar.
- **Todo (usuarios, cursos, progreso):** `make backup` y comparte la carpeta de `backups/`; el otro corre `make restore BACKUP=...`.
- Más adelante, un servidor de staging compartido evita pasarse respaldos.

## Traer tu instalación anterior (la de `~/openedx`)

Tus datos actuales están en `~/.local/share/tutor`. Para pasarlos a este repo:

```bash
cd ~/plataforma
TUTOR_ROOT_OVERRIDE=~/.local/share/tutor make backup   # respalda la instalación vieja
TUTOR_ROOT_OVERRIDE=~/.local/share/tutor make stop     # la apaga
make setup                                            # crea la nueva
make restore BACKUP=backups/<la carpeta que se creó>  # carga tus usuarios y cursos
```

Cuando confirmes que todo está bien en la nueva, puedes borrar la vieja con `rm -rf ~/.local/share/tutor ~/openedx` para liberar espacio. Las imágenes de Docker se comparten, así que no se descargan de nuevo.
