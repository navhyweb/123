# Alta masiva de usuarios GAM - Rol Despachante

Scripts para dar de alta en GAM, via el procedimiento GeneXus `Alta_Usuarios_GAM_Excel`
(Main program, Call Protocol = HTTP), a los usuarios de la pestaña
**"DESPACHANTE (Rol Despachante)"** del Excel `ListadoUsuariosActivosADF.V.1.1.xlsx`.

> **El CSV con los usuarios NO se sube a este repositorio.** Contiene las
> passwords en texto plano (columna `password`), asi que se entrega por
> separado (fuera de git) y queda ignorado via `.gitignore`. Copialo junto
> a `Alta_Usuarios_GAM_Despachante.ps1` antes de ejecutar el script, y
> borralo/guardalo en un lugar seguro una vez usado.

## Archivos

- `usuarios_despachante.csv` (no versionado, entregado aparte): datos
  extraidos de la pestaña, ya mapeados al orden de parametros del
  procedimiento:

  | Columna Excel | Parametro GeneXus |
  |---|---|
  | UserName | &Name |
  | Email | &UserEmail |
  | Name | &FirstName |
  | Surname | &LastName |
  | PASSWORD | &password |
  | (fijo) | &rolID = 11 (Despachante en GAM) |

  Son 16 usuarios, sin emails ni usernames duplicados.

- `Alta_Usuarios_GAM_Despachante.ps1`: recorre el CSV e invoca el procedimiento por
  HTTP GET para cada usuario, pasando los 6 parametros posicionales separados por
  coma en el query string (convencion estandar de GeneXus para Main programs HTTP
  con `parm()`):

  ```
  http://<server>/<app>/Alta_Usuarios_GAM_Excel.aspx?Name,UserEmail,FirstName,LastName,password,rolID
  ```

  Cada valor se url-encodea individualmente.

## Uso

El script apunta por defecto a `http://localhost/RendelMoveDFWeb17_VDesarrollo.NetEnvironment`,
asi que hay que ejecutarlo **en la misma maquina donde esta publicada la app**
(el IIS que sirve `login.aspx`), para que `localhost` resuelva ahi.

```powershell
# 1) Ver las URLs que se generarian, sin ejecutar nada
.\Alta_Usuarios_GAM_Despachante.ps1 -WhatIf

# 2) Ejecucion real
.\Alta_Usuarios_GAM_Despachante.ps1

# 3) Si hace falta apuntar a otra URL base
.\Alta_Usuarios_GAM_Despachante.ps1 -BaseUrl "http://otro-host/RendelMoveDFWeb17_VDesarrollo.NetEnvironment"
```

El resultado de cada llamada (OK/FAIL + status HTTP) se muestra en pantalla y se
guarda en `alta_usuarios_despachante.log`.

## A verificar antes de correrlo contra un ambiente real

- **Formato de invocacion HTTP**: se asumio la convencion clasica de GeneXus
  (parametros posicionales separados por coma en el query string). Si el
  procedimiento esta expuesto con otro ruteo (por ejemplo REST/segmentos
  `/Value1/Value2/...`), hay que ajustar la construccion de `$url` en el script.
- **Password compartida**: las 16 filas del Excel tienen la misma password
  (`K7m%P4xL`), pero el procedimiento setea `&User.MustChangePassword = true`,
  asi que GAM va a forzar el cambio en el primer login de cada usuario. No
  hace falta generar una password distinta por fila.
- **rolID**: se uso `11` para Despachante en GAM, confirmado por el usuario.
- Probar primero con `-WhatIf` antes de correr el alta real.
- **No se pudo probar la llamada HTTP real** desde este entorno: es un sandbox
  en la nube sin la app de GeneXus corriendo, y `localhost` ahi no apunta a
  ningun servidor. El script tiene que correrse en la maquina donde esta
  publicado `RendelMoveDFWeb17_VDesarrollo.NetEnvironment` (o contra un host
  con acceso real, via `-BaseUrl`).
