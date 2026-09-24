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
  | (fijo) | &rolID = 1 (Despachante en GAM) |

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

```powershell
# 1) Ver las URLs que se generarian, sin ejecutar nada
.\Alta_Usuarios_GAM_Despachante.ps1 -WhatIf

# 2) Ejecutar contra desa02
.\Alta_Usuarios_GAM_Despachante.ps1 -BaseUrl "https://desa02.rendelit.ar/RendelMoveDFWeb17_VDesarrollo.NetEnvironment"

# 3) Ejecutar contra un ambiente local
.\Alta_Usuarios_GAM_Despachante.ps1 -BaseUrl "http://localhost/RendelMoveDFWeb17_VDesarrollo.NetEnvironment"
```

El resultado de cada llamada (OK/FAIL + status HTTP) se muestra en pantalla y se
guarda en `alta_usuarios_despachante.log`.

## A verificar antes de correrlo contra un ambiente real

- **Formato de invocacion HTTP**: se asumio la convencion clasica de GeneXus
  (parametros posicionales separados por coma en el query string). Si el
  procedimiento esta expuesto con otro ruteo (por ejemplo REST/segmentos
  `/Value1/Value2/...`), hay que ajustar la construccion de `$url` en el script.
- **Password compartida**: las 16 filas del Excel tienen la misma password
  (`K7m%P4xL`). Si el procedimiento no fuerza cambio de password en el primer
  login, conviene evaluar generar una password distinta por usuario.
- **rolID**: se uso `1` para Despachante en GAM, segun lo confirmado. (En un
  mensaje anterior se habia mencionado 11; si hay dudas, confirmar el ID real
  en la tabla de roles de GAM antes de correr el alta masiva.)
- Probar primero con `-WhatIf` y, si es posible, contra el ambiente de
  desarrollo antes de correr contra un ambiente productivo.
