# wgadmin
Wireguard tool for OpenBSD

Crear una herramienta para administrar Interfaces y Usuarios.

wgadmin
  |_initenv (ip forwarding, instala programas, crea la db usuarios)
  |_wgcreate (crea la interfaz y el archivo de config)
    |_server.conf (archivo a ser reemplazado por db?)
  |_adduser (crea el archivo de configuracion para el usuario/cliente
    |_user.conf (archivarchivo a ser reemplazado por db?)
    
----------------------------------------------------------------------
    
    Create a tool to manage Interfaces and Users.

wgadmin
    | _initenv (ip forwarding, install programs, create users db)
    | _wgcreate (creates the interface and configuration file)
      | _server.conf (file to be replaced by db?)
    | _adduser (creates configuration file for user / client
      | _user.conf (filefile to be replaced by db?) 
