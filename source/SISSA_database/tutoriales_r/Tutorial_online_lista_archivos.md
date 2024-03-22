---
title: "¿Cómo trabajar con multiples archivos en línea usando R?"
output: "html_notebook" 
---

En este tutorial vamos a continuar trabajando con la librería [**aws.s3**](https://cran.r-project.org/web/packages/aws.s3/aws.s3.pdf) con la que hicimos la descarga de datos. A diferencia del anterior ejemplo, en este vamos a trabajar con todos los miembros del ensamble y vamos a calcular una media del ensamble y también la desviación estándar de dicho ensamble para un plazo de pronóstico.

Además de la librería para conectar con AWS, vamos a necesitar para este tutorial tener instalado las siguientes librerías:

- [**ncdf4**](https://cran.r-project.org/web/packages/ncdf4/ncdf4.pdf)
- [**raster**](https://cran.r-project.org/web/packages/raster/raster.pdf)
- [**maps**](https://cran.r-project.org/web/packages/maps/maps.pdf)
- [**colorRamps**](https://cran.r-project.org/web/packages/colorRamps/colorRamps.pdf)

Recordar que la estructura de datos del siguiente [link](https://fmcarrasco.github.io/documentation_crc_sas/SISSA_database/2Estructura_de_datos/).

```r
# Comenzamos instalando las librerías necesarias, en caso de que no lo estén: 
if (!requireNamespace("aws.s3", quietly = TRUE)) {install.packages("aws.s3")}
if (!requireNamespace("ncdf4", quietly = TRUE)) {install.packages("ncdf4")}
if (!requireNamespace("raster", quietly = TRUE)) {install.packages("raster")}
if (!requireNamespace("maps", quietly = TRUE)) {install.packages("maps")}
if (!requireNamespace("colorRamps", quietly = TRUE)) {install.packages("colorRamps")}

# Cargamos las librerías:
library(aws.s3)
library(ncdf4)
library(raster)
library(maps)
library(colorRamps)
require(here)

BUCKET_NAME <- "sissa-forecast-database"
tforecast <- "subseasonal"
modelo <- "GEFSv12_corr"
variable <- "tmean"
year <- "2010"
ymd <- "20100331"
PATH <- paste0(tforecast, "/", modelo, "/", variable, "/", year, "/", ymd, "/")
```

```r
# Listamos todos los archivos dentro del bucket + PATH:
awsfiles <- get_bucket_df(
  bucket = BUCKET_NAME,
  prefix = PATH,
  max = Inf,
  region = "us-west-2")
awsfiles <- awsfiles$Key # Nos quedamos sólo con la información de los nombres de los archivos.  

nfiles <- length(awsfiles)
print("Trabajamos con los archivos:")
print(paste(awsfiles, collapse = ","))
print(paste("Cantidad de archivos =", nfiles))
```

En el siguiente recuadro, vamos a ir trabajando en cada archivo, extrayendo el plazo asignado y finalmente calculamos las variables que necesitamos: media y desviación estándar.

```r

# Vamos a trabajar con el plazo de pronóstico al día 10:
plazo_pron = 10

for (i in seq_along(awsfiles)) {
  print("Extrayendo datos del archivo:")
  print(awsfiles[i])
  
  gefs <- s3read_using(FUN = ncdf4::nc_open,
                       object = awsfiles[i], 
                       bucket = BUCKET_NAME,
                       opts = list(region = "us-west-2"))
  
  # Descomentarear si se quiere descargar el archivo: 
  # save_object(object = awsfiles[i],
  #             bucket = BUCKET_NAME,
  #             region = "us-west-2",
  #             file = basename(awsfiles[i]),
  #             overwrite = TRUE)
  
  # Abrimos el archivo NetCDF:
  # gefs <- nc_open(basename(awsfiles[i]))
  
  # Leemos la variable y las coordenadas:
  var <- ncvar_get(gefs, varid = variable)
  lon <- ncvar_get(gefs, varid = "lon") 
  lat <- ncvar_get(gefs, varid = "lat")

  dim(var) # dimensiones: lon, lat, time. 

  if (i == 1) {
    # Creamos una matriz con NA para guardar la info de todos los archivos:
    gvar <- array(NA, dim = c(length(lon), length(lat), length(awsfiles)))
  }
  
  # Guardamos el valor de la variable para el día 10 de pronóstico:
  gvar[,,i] <- var[,,plazo_pron]
  
  # Cerramos el archivo NetCDF:
  nc_close(gefs)
}

# Calculamos la media y la desviación estándar: 
media <- apply(gvar, MARGIN = c(1, 2), FUN = mean)
desv_std <- apply(gvar, MARGIN = c(1, 2), FUN = sd)

print("Imprimimos en pantalla el shape de cada matriz\n")
print(dim(media))
print(dim(desv_std))
# en la dim x están las longitudes.
# en la dim y están las latitudes.

```
```r
rast_media <- raster(t(media), xmn = min(lon), xmx = max(lon), ymn = min(lat), ymx = max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
rast_desvio_std <- raster(t(desv_std), xmn = min(lon), xmx = max(lon), ymn = min(lat), ymx = max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))

jpeg("test_media_ensamble.jpg", width = 1300, height = 800, units = "px", res = 130)

par(mfrow = c(1, 2))
{plot(rast_media, col = matlab.like(25),
      xlim =  c(min(lon), max(lon)), 
      ylim =  c(min(lat), max(lat)),
      main = paste("Promedio ensamble\n tmean para el dia", plazo_pron),
      xlab = "Longitud", ylab = "Latitud", 
      asp = 0)
maps::map("world",
          lwd = 0.5, col = "black",
          xlim = c(min(lon), max(lon)), 
          ylim = c(min(lat), max(lat)), 
          add = TRUE)
plot(rast_desvio_std, col = blue2yellow(25), 
     xlim = c(min(lon), max(lon)), 
     ylim = c(min(lat), max(lat)),
     main = paste("Desviación standard ensamble\n tmean para el dia", plazo_pron),
     xlab = "Longitud", ylab = "Latitud",
     asp = 0)
maps::map("world",
          lwd = 0.5, col = "black",
          xlim = c(min(lon), max(lon)), 
          ylim = c(min(lat), max(lat)), 
          add = TRUE)
}

graphics.off()

knitr::include_graphics("test_media_ensamble.jpg")
```







