---
title: "¿Cómo trabajar con el archivo en línea?"
output: "html_notebook" 
---

En este tutorial vamos a continuar trabajando con la librería [**aws.s3**](https://cran.r-project.org/web/packages/aws.s3/aws.s3.pdf) con la que hicimos la descarga de datos, pero esta vez para hacer una figura, sin necesidad de hacer la descarga del dato. Esta puede ser una opción viable en caso de no tener espacio o revisar solo una fecha.

Además de la librería para conectar con AWS, vamos a necesitar para este tutorial tener instalado las siguientes librerías:

- [**ncdf4**](https://cran.r-project.org/web/packages/ncdf4/ncdf4.pdf)
- [**raster**](https://cran.r-project.org/web/packages/raster/raster.pdf)
- [**maps**](https://cran.r-project.org/web/packages/maps/maps.pdf)
- [**colorRamps**](https://cran.r-project.org/web/packages/colorRamps/colorRamps.pdf)

Recordar que la estructura de datos del siguiente [link](https://fmcarrasco.github.io/documentation_crc_sas/SISSA_database/2Estructura_de_datos/). 

```{r}
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
library(rasterVis)
library(maps)
library(colorRamps)
require(here)

# Colocamos los DATOS necesarios para trabajar con un archivo. 
# En este caso, decidimos trabajar con la temperatura media 
# del miércoles 31 de marzo de 2010 (pronóstico corregido):
BUCKET_NAME <- "sissa-forecast-database"
tforecast <- "subseasonal"
modelo <- "GEFSv12_corr"
variable <- "tmean"
year <- "2010"
ymd <- "20100331"
nens <- "p03"
narchivo <- paste0(variable, "_", ymd, "_", nens, ".nc")
PATH <- paste0(tforecast, "/", modelo, "/", variable, "/", year, "/", ymd, "/")

print(paste0(PATH, narchivo))
```


```{r}

# Comenzamos la conexión al archivo:
awsfile <- paste0(PATH, narchivo)
print("Trabajamos con el archivo:")
print(awsfile)

gefs <- s3read_using(FUN = ncdf4::nc_open, 
                     object = awsfile,
                     bucket = BUCKET_NAME,
                     opts = list(region = "us-west-2"))
  
# Descomentarear si se quiere descargar el archivo: 
# save_object(object = awsfile,
#             bucket = BUCKET_NAME,
#             region = "us-west-2",
#             file = basename(awsfile),
#             overwrite = TRUE)

# Abrimos el archivo NetCDF:
# gefs <- nc_open(basename(awsfile))
  
# Leemos la variable y las coordenadas:
var <- ncvar_get(gefs, varid = variable)
lon <- ncvar_get(gefs, varid = "lon") 
lat <- ncvar_get(gefs, varid = "lat")

dim(var) # dimensiones: lon, lat, time.

# Calculamos la media de la primera semana: 
media <- apply(var[,,1:7], MARGIN = c(1, 2), FUN = mean)
  
nc_close(gefs)
```
```{r}
# Comenzamos con la figura:
rast_media <- raster(t(media), xmn = min(lon), xmx = max(lon), ymn = min(lat), ymx = max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))

jpeg("test_promedio.jpg", width = 800, height = 800, units = "px", res = 130)

{plot(rast_media, 
      col = matlab.like(50),
      xlim =  c(min(lon), max(lon)), 
      ylim =  c(min(lat), max(lat)),
      main = paste("Temperatura media de la primera semana"),
      xlab = "Longitud", ylab = "Latitud",
      asp = 0)
maps::map("world",
          lwd = 0.5, col = "black",
          xlim = c(min(lon), max(lon)), 
          ylim = c(min(lat), max(lat)), 
          add = TRUE)
}

graphics.off()

knitr::include_graphics("test_promedio.jpg")
```







