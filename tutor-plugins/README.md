Aquí van los plugins de Tutor del equipo (archivos `.py` o `.yml`).
Cada archivo se activa automáticamente con `make setup` o `make update`.

Si un plugin monta código de `src/`, debe declarar el nombre de la carpeta para que Tutor lo instale
dentro de la imagen, por ejemplo:

    from tutor import hooks
    hooks.Filters.MOUNTED_DIRECTORIES.add_item(("openedx", "plugin-stripe"))
