Aquí van los repos de código del equipo (plugin de Django, MFEs, etc.), idealmente como submódulos de Git:

    git submodule add https://github.com/TU_ORG/plugin-stripe.git src/plugin-stripe

Después agrega la ruta en `config/mounts.txt` para que Tutor la monte en modo dev.
