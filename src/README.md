Aquí van los repos de código del equipo, como submódulos de Git:

| Carpeta | Qué es |
| --- | --- |
| `campus-cms` | CMS del contador (Django + DRF): cursos, precios, ventas y pagos con Stripe |
| `front-campus` | Sitio público Campus y su administración (Nuxt) |
| `openedx-course-payments` | Plugin del LMS: solo entran quienes pagaron; páginas de curso en Campus |

Para agregar otro: `git submodule add <url> src/<nombre>` y, si debe montarse dentro de Open edX, su ruta en `config/mounts.txt` (ver la sección 6 del README principal).

Las carpetas `frontend-app-*` que clones aquí para probar MFEs de Open edX son solo locales: Git las ignora.
