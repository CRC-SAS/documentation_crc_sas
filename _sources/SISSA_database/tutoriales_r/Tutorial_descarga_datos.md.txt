---
title: "¿Cómo descargar datos desde la base usando R?"
output: "html_notebook" 
---

# ¿Cómo descargar datos desde la base usando R?

Existen tres subconjuntos de datos dentro de la base: ERA5, GEFSv2 sin corrergir y GEFSv2 corregido. En R, existe la librería [**aws.s3**](https://cran.r-project.org/web/packages/aws.s3/aws.s3.pdf), que permite hacer una conexión para descargar los datos. Para descargar un archivo, necesitamos el link al archivo, que se genera tal como se muestra en este [link](https://fmcarrasco.github.io/documentation_crc_sas/SISSA_database/2Estructura_de_datos/). 


```r
# Comenzamos instalando las librerías necesarias, en caso de que no lo estén: 
if (!requireNamespace("aws.s3", quietly = TRUE)) {install.packages("aws.s3")}

# Cargamos las librerías:
library(aws.s3)
require(here)

# Creamos una función para guardar un archivo con manejo de errores:
save_object_with_error_handling <- function(object, bucket, region, file, overwrite) {
  tryCatch({
    aws.s3::save_object(object = object,
                bucket = bucket,
                region = region,
                file = file,
                overwrite = overwrite)
    print(paste("Descargando y guardando:", object))
  }, error = function(e) {
    stop(paste("Error al descargar y guardar el objeto:", e$message))
  })
}
```

**ERA5**
Nombre del objeto del tipo *s3://sissa-forecast-database/ERA5/tmax/2010.nc*.

```r
# Temperatura máxima del 2010 de ERA5:

# Datos necesarios para la descarga:
BUCKET_NAME <- "sissa-forecast-database" # Nombre del bucket (va a ser el mismo para los tres subconjuntos de datos).
modelo0 <-  "ERA5"
variable <- "tmax"
year <- "2010"
PATH0 <-  paste0(modelo0, "/", variable, "/") 
narchivo0 <- paste0(year, ".nc")

# Podemos usar la función "get_bucket_df" si no sabemos el nombre final del objeto a descargar: 
get_bucket_df(
  bucket = BUCKET_NAME,
  prefix = PATH0,
  max = Inf,
  region = "us-west-2")

save_object_with_error_handling(
  object = paste0(PATH0, narchivo0), # Nombre del objeto a descargar.
  bucket = BUCKET_NAME,
  region = "us-west-2",
  file = narchivo0, # Archivo de descarga.
  overwrite = TRUE)
```

**GEFSv2 sin corregir o corregido**
Nombre del objeto del tipo *s3://sissa-forecast-database/subseasonal/GEFSv12/tmax/2010/20100331/tmax_20100331_p03.nc* para el caso sin corregir. 

Nombre del objeto del tipo *s3://sissa-forecast-database/subseasonal/GEFSv12_corr/tmax/2010/20100331/tmax_20100331_p03.nc* para el caso corregido. 

Usando la misma librería, ahora vamos a descargar un dato de GEFSv12 corregido o sin corregir, para una fecha en particular. Hay que recordar que los datos de GEFSv12 históricos solo existen para los días miércoles de cada semana. En este caso, vamos a descargar para el miércoles 31 de marzo de 2010 y solo vamos a descargar el miembro 3 del ensamble. 

```r
# Temperatura máxima del 31/03/2010 (día miércoles) para el miembro 3 del ensamble. 

# Datos necesarios para la descarga:
BUCKET_NAME <- BUCKET_NAME
tforecast <- "subseasonal"
modelo1 <- "GEFSv12_corr" # "GEFSv12" para datos sin corregir. 
variable <- "tmax"
year <- "2010"
ymd <- "20100331"
nens <- "p03" # Miembro 03 del ensamble.
PATH1 <- paste0(tforecast, "/", modelo1, "/", variable, "/", year, "/", ymd, "/") 
narchivo1 <- paste0(variable, "_", ymd, "_", nens, ".nc")

save_object_with_error_handling(
  object = paste0(PATH1, narchivo1), # Nombre del objeto a descargar.
  bucket = BUCKET_NAME,
  region = "us-west-2",
  file = narchivo1, # Archivo de descarga.
  overwrite = TRUE)
```

