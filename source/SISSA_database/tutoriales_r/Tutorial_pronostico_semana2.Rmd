---
title: "¿Como generar un pronóstico probabilistico para la semana 2 con R?"
output: "html_notebook" 
---

En este tutorial y partir de la latitud y longitud de un lugar, la idea es:

- Encontrar el punto más cercano en el dominio SISSA de los pronósticos.
- Extraer el dato de precipitación de dicho lugar para todos los miembros del ensamble.
- Calcular la probabilidad de lluvia a partir de dichos datos para la semana 2 para algunos umbrales caracteristicos.

Para ello, vamos a trabajar con el dato en línea, tal como vimos [acá](https://fmcarrasco.github.io/documentation_crc_sas/SISSA_database/Tutorial_online_lista_archivos/). 

Además, vamos a necesitar las siguientes librerías:

- [**readxl**](https://cran.r-project.org/web/packages/readxl/readxl.pdf)
- [**dplyr**](https://cran.r-project.org/web/packages/dplyr/dplyr.pdf)

En este caso, en el próximo bloque vamos a colocar todos los datos necesarios para extraer los datos, latitud y longitud y también los umbrales para los cuales vamos a calcular la probabilidad.

**Algunos detalles** 

Para esta sección vamos a trabajar con el 02 de mayo de 2018 y la variable lluvia.

La latitud/longitud corresponde a la localidad de Mercedes, en la provincia de Corrientes, Argentina.

La idea es comparar los pronósticos de lluvias corregidos y sin corregir en términos de sus valores diarios y también al calcular la probabilidad para la segunda semana. Se utilizan datos del SMN de la estación correspondiente para dicho período.

```{r}
# Comenzamos instalando las librerías necesarias, en caso de que no lo estén: 
if (!requireNamespace("aws.s3", quietly = TRUE)) {install.packages("aws.s3")}
if (!requireNamespace("ncdf4", quietly = TRUE)) {install.packages("ncdf4")}
if (!requireNamespace("readxl", quietly = TRUE)) {install.packages("raster")}
if (!requireNamespace("dplyr", quietly = TRUE)) {install.packages("maps")}

# Cargamos las librerías:
library(aws.s3)
library(ncdf4)
library(readxl)
library(dplyr)
require(here)

BUCKET_NAME <- "sissa-forecast-database"
tforecast <- "subseasonal"
modelo_corr <- "GEFSv12_corr"
modelo <- "GEFSv12"
variable <- "rain"
year <- "2018"
ymd <- "20180502"

PATH_corr = paste0(tforecast, "/", modelo_corr, "/", variable, "/", year, "/", ymd, "/")
PATH = paste0(tforecast, "/", modelo, "/", variable, "/", year, "/", ymd, "/")

# Colocamos como dato la latitud y longitud de la localidad:
# En este caso es Mercedes, Corrientes en Argentina.
# En la fecha que vamos a analizar ocurrió en algún momento del pronóstico un evento de lluvia importante.
lat_e <- -29.18
lon_e <- -58.07

# Umbrales a considerar para calcular probabilidad:
umbrales <- c(1, 30, 50, 100)

# Imprimimos las carpetas con los datos corregidos y sin corregir:
print(paste("Carpeta con datos corregidos:", BUCKET_NAME, "/", PATH_corr, sep = ""))
print(paste("Carpeta con datos sin corregir:", BUCKET_NAME, "/", PATH, sep = ""))
```

```{r}
# Vamos a hacer como el caso anterior. Para la fecha dada, vamos a LISTAR los archivos CORREGIDOS y, de a uno, vamos a ir extrayendo el dato de pronóstico de cada ensamble.

# Listamos todos los archivos dentro del bucket + PATH_corr:
awsfiles_corr <- get_bucket_df(
  bucket = BUCKET_NAME,
  prefix = PATH_corr,
  max = Inf,
  region = "us-west-2")
awsfiles_corr <- awsfiles_corr$Key # Nos quedamos sólo con la información de los nombres de los archivos.  

nfiles <- length(awsfiles_corr)
print(paste("Cantidad de archivos corregidos =", nfiles))
```

```{r}
# Creamos una lista para almacenar los datos:
list_df <- list()

for (i in seq_along(awsfiles_corr)) {
    print("Extrayendo datos del archivo:")
    print(awsfiles_corr[i])
    
    # Abrimos el archivo:
    gefs <- s3read_using(FUN = ncdf4::nc_open,
                         object = awsfiles_corr[i], 
                         bucket = BUCKET_NAME,
                         opts = list(region = "us-west-2"))
    
    # Leemos la variable y las coordenadas:
    var <- ncvar_get(gefs, varid = variable)
    lon <- ncvar_get(gefs, varid = "lon") 
    lat <- ncvar_get(gefs, varid = "lat")
    
    dim(var) # dimensiones: lon, lat, time. 

    # Tiempo:
    time <- ncvar_get(gefs, "time")
    time_units <- ncatt_get(gefs, "time", "units")[["value"]]
    fecha_referencia <- as.Date(gsub("days since ", "", time_units))
    # Convertir el tiempo a formato de días desde la fecha de referencia:
    fechas_corr <- fecha_referencia + as.numeric(time)

    # Seleccionamos el punto de retícula más cercano:
    df0 <- var[which.min(abs(lon - lon_e)), which.min(abs(lat - lat_e)), ]
    
    df <- as.data.frame(df0)

    # Lo guardamos en lista generada:
    list_df[[i]] <- df
}

# Concatenamos los data frames por columnas:
result_corr <- do.call(cbind, list_df)
print(fechas_corr)
print(head(result_corr))
```

Algunos apuntes antes de seguir:

Vamos a realizar una figura mostrando la pluma de precipitación acumulada a lo largo de los plazos de pronóstico.

Para ello utilizamos la función cumsum, que está cargada por defecto.

En la figura vamos a remarcar en el eje X cuando hay 7 dias, de manera de tener las semanas.

Las lineas de colores corresponden a UN miembro de ensamble y la línea negra gruesa, al acumulado observado.

Las observaciones proviene del archivo datos_mercedes.xlsx para trabajar con los datos de la estación del SMN en Mercedes, Corrientes.

```{r}
# Leemos el archivo de Excel:
obs <- read_excel("datos_mercedes.xlsx")

# Convertimos la columna "Fecha" en el índice y rellenamos los valores nulos con 0:
obs <- obs %>% 
  mutate(Fecha = as.Date(Fecha)) %>%
  arrange(Fecha) %>%
  mutate(Precipitacion = ifelse(is.na(Precipitacion), 0, Precipitacion)) %>%
  mutate(acumulado = cumsum(Precipitacion))

# Calculamos los acumulados para la observación y el pronóstico corregido:
accobs <- obs$acumulado
accpp_corr <- apply(result_corr, 2, cumsum)

# Asignamos nombres a las columnas de accpp y colores:
colnames(accpp_corr) <- c("c00", "p01", "p02", "p03", "p04", "p05", "p06", "p07", "p08", "p09", "p10")
colores <- c("blue", "red", "green", "orange", "purple", "cyan", "magenta", "brown", "pink", "gray", "darkgreen")

# Creamos el gráfico:
{plot(obs$Fecha, accobs, col = "black", type = "l", lwd = 3, 
     xlab = "Fecha", ylab = "Acumulado", ylim = c(-50, 1000), xaxt = "n")
axis(1, at = obs$Fecha[seq(1, length(obs$Fecha), by = 7)], 
     labels = format(obs$Fecha[seq(1, length(obs$Fecha), by = 7)], "%Y-%m-%d"))
axis(2, at = c(0, 30, 50, 100, 200, 400, 600, 800, 1000), 
     labels = c("0", "30", "50", "100", "200", "400", "600", "800", "1000"))
grid()
  for (i in 1:11) {
    lines(fechas_corr, accpp_corr[,i], col = colores[i], lwd = 0.8)
  }
# legend("right", legend = colnames(accpp_corr), col = colores, lwd = 0.8)
}
```
**Apuntes**

En la figura podemos ver que hay miembros del ensamble que muestran un acumulado mucho más alto que cualquiera de los otros miembros durante todo el período de pronóstico (34 días).

En base a estos miembros vamos a calcular la proporción en cada semana que se supere algún umbral de acumulado. Vamos a utilizar 1mm y también 30mm como para tener dos estimaciones de probabilidad.

Antes tambien vamos a hacer la misma extraccion de datos, pero para los datos **SIN** corrección en la misma fecha:

```{r}
# Ahora, para la fecha dada, vamos a LISTAR los archivos SIN CORREGIR 
# y, de a uno, vamos a ir extrayendo el dato de pronóstico de cada ensamble.

# Listamos todos los archivos dentro del bucket + PATH_corr:
awsfiles_sincorr <- get_bucket_df(
  bucket = BUCKET_NAME,
  prefix = PATH,
  max = Inf,
  region = "us-west-2")
awsfiles_sincorr <- awsfiles_sincorr$Key # Nos quedamos sólo con la información de los nombres de los archivos.  

nfiles <- length(awsfiles_sincorr)
print(paste("Cantidad de archivos sin corregir =", nfiles))
```

```{r}
# Creamos una lista para almacenar los datos:
list_df <- list()

for (i in seq_along(awsfiles_sincorr)) {
    print("Extrayendo datos del archivo:")
    print(awsfiles_sincorr[i])
    
    # Abrimos el archivo
    gefs <- s3read_using(FUN = ncdf4::nc_open,
                         object = awsfiles_sincorr[i], 
                         bucket = BUCKET_NAME,
                         opts = list(region = "us-west-2"))
    
    # Leemos la variable y las coordenadas:
    var <- ncvar_get(gefs, varid = variable)
    lon <- ncvar_get(gefs, varid = "lon") 
    lat <- ncvar_get(gefs, varid = "lat")
    
    dim(var) # dimensiones: lon, lat, time. 

    # Tiempo:
    time <- ncvar_get(gefs, "time")
    time_units <- ncatt_get(gefs, "time", "units")[["value"]]
    fecha_referencia <- as.Date(gsub("days since ", "", time_units))
    # Convertir el tiempo a formato de días desde la fecha de referencia:
    fechas_sincorr <- fecha_referencia + as.numeric(time)

    # Seleccionamos el punto de retícula más cercano:
    df0 <- var[which.min(abs(lon - lon_e)), which.min(abs(lat - lat_e)), ]
    
    df <- as.data.frame(df0)

    # Lo guardamos en lista generada:
    list_df[[i]] <- df
}

# Concatenar los data frames por columnas:
result_sincorr <- do.call(cbind, list_df)
print(fechas_sincorr)
print(head(result_sincorr))
```

```{r}
# Calculamos los acumulados para el pronóstico sin corregir:
accpp_sincorr <- apply(result_sincorr, 2, cumsum)

# Asignamos nombres a las columnas de accpp y colores:
colnames(accpp_sincorr) <- c("c00", "p01", "p02", "p03", "p04", "p05", "p06", "p07", "p08", "p09", "p10")
colores <- c("blue", "red", "green", "orange", "purple", "cyan", "magenta", "brown", "pink", "gray", "darkgreen")

# Creamos el gráfico:
{plot(obs$Fecha, accobs, col = "black", type = "l", lwd = 3, 
      xlab = "Fecha", ylab = "Acumulado", ylim = c(-50, 1000), xaxt = "n")
axis(1, at = obs$Fecha[seq(1, length(obs$Fecha), by = 7)], 
     labels = format(obs$Fecha[seq(1, length(obs$Fecha), by = 7)], "%Y-%m-%d"))
axis(2, at = c(0, 30, 50, 100, 200, 400, 600, 800, 1000), 
     labels = c("0", "30", "50", "100", "200", "400", "600", "800", "1000"))
grid()
  for (i in 1:11) {
    lines(fechas_sincorr, accpp_sincorr[,i], col = colores[i], lwd = 0.8)
  }
# legend("right", legend = colnames(accpp_sincorr), col = colores, lwd = 0.8)
}
```

**Cálculo de probabilidad semanal por umbral**

Ahora vamos a calcular la probabilidad en distintos umbrales.

Creamos una lista colocando el numero correspondiente a la semana para agrupar.

```{r}
# Definimos la variable de semana:
lsemana <- rep(0, nrow(accpp_corr))
lsemana[1:7] <- 1
lsemana[8:14] <- 2
lsemana[15:21] <- 3
lsemana[22:nrow(accpp_corr)] <- 4

# Agrega la nueva columna:
obs$i_semana <- lsemana
result_corr$i_semana <- lsemana
result_sincorr$i_semana <- lsemana

# Agrupamos por semana y sumamos (calculamos el acumulado semanal de cada miembro del ensamble):
acc_obs <- aggregate(obs[, colnames(obs) == "Precipitacion"], by = list(semana = obs$i_semana), sum)
acc_sem_corr <- aggregate(result_corr[,-ncol(result_corr)], by = list(semana = result_corr$i_semana), sum)
acc_sem_sincorr <- aggregate(result_sincorr[,-ncol(result_sincorr)], by = list(semana = result_sincorr$i_semana), sum)

print(acc_obs)
print(acc_sem_corr)
print(acc_sem_sincorr)

for (semana in 1:4) {
  print(paste(' ############ Pronóstico para la semana:', semana, ' ############ '))
  print(paste(' #### Lluvia observada: ', round(acc_obs$Precipitacion[semana], 2), "mm"))
  for (umbral in umbrales) {
    print(paste("** Calculando probabilidad semana", semana, " para umbral:", umbral, "mm  **"))
    c0 <- sum((acc_sem_corr > umbral)[semana, ])/11
    c1 <- sum((acc_sem_sincorr > umbral)[semana, ])/11
    print(paste('Probabilidad semana', semana, " sin corregir:", round(c1, 2)))
    print(paste('Probabilidad semana', semana, " corregida", round(c0, 2)))
  }
}
```