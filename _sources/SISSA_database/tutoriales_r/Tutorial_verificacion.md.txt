---
title: "¿Cómo verificamos los pronósticos de las primeras semanas?"
output: "html_notebook" 
---

En este tutorial vamos a realizar una verificación temporal y espacial del pronóstico corregido y sin corregir de las primeras semanas del mes de marzo. Vamos a utilizar la metodología que utiliza el SMN para la verificación, pero para el dominio del sudeste de Sudamérica. Para ello, vamos a:

- Elegir el dominio reducido.
- Tomar los datos diarios de precipitación correspondientes a las semanas 1 de pronóstico del mes de marzo y calcular el acumulado.
- Tomar los datos diarios del ERA5 para las mismas semanas y calcular el acumulado.
- Elegir dos umbrales de precipitación (5 y 30 mm, usados por el SMN) y calcular los elementos de una tabla de contingencia y los ínidices Bias frec (Bias en la frecuencia), POD (Probabilidad de detección) y ETS (Equitable Threat Score):
- Graficar los resultados de una verificación temporal y espacial.

Vamos a estudiar este comportamiento para el mes de diciembre. Entonces, vamos a tomar *todos* los pronósticos inicializados en ese mes. 

Además de la librería para conectar con AWS, vamos a necesitar para este tutorial tener instalado las siguientes librerías:

- [**ncdf4**](https://cran.r-project.org/web/packages/ncdf4/ncdf4.pdf)
- [**raster**](https://cran.r-project.org/web/packages/raster/raster.pdf)
- [**maps**](https://cran.r-project.org/web/packages/maps/maps.pdf)
- [**colorRamps**](https://cran.r-project.org/web/packages/colorRamps/colorRamps.pdf)
- [**dplyr**](https://cran.r-project.org/web/packages/dplyr/dplyr.pdf)
- [**lubridate**](https://cran.r-project.org/web/packages/lubridate/lubridate.pdf)

Recordar que la estructura de datos del siguiente [link](https://fmcarrasco.github.io/documentation_crc_sas/SISSA_database/2Estructura_de_datos/).

```r
# Comenzamos instalando las librerías necesarias, en caso de que no lo estén: 
if (!requireNamespace("aws.s3", quietly = TRUE)) {install.packages("aws.s3")}
if (!requireNamespace("ncdf4", quietly = TRUE)) {install.packages("ncdf4")}
if (!requireNamespace("raster", quietly = TRUE)) {install.packages("raster")}
if (!requireNamespace("maps", quietly = TRUE)) {install.packages("maps")}
if (!requireNamespace("colorRamps", quietly = TRUE)) {install.packages("colorRamps")}
if (!requireNamespace("dplyr", quietly = TRUE)) {install.packages("dplyr")}
if (!requireNamespace("lubridate", quietly = TRUE)) {install.packages("lubridate")}

# Cargamos las librerías: 
library(aws.s3)  
library(ncdf4)
library(raster)
library(maps)
library(colorRamps)
library(lubridate)
library(dplyr)
require(here)
```

```r
# Definimos algunos parámetros: 
variable <- "rain"
mes <- 3
lat_n <- -20
lat_s <- -30
lon_w <- -65
lon_e <- -55

BUCKET_NAME <- "sissa-forecast-database"
```

## **Pronósticos**

Como la estructura de los datos de los modelos de pronóstico (corregido y sin corregir) es igual, vamos a usar un "for" para cargarlos, sin necesidad de descargar los archivos del AWS. Vamos a generar 2 archivos ".csv" con la información de las primeras semanas de pronóstico, sólo si estos no fueron generados previamente.

```r
tforecast <- "subseasonal"
modelos_gefs <- c("GEFSv12_corr", "GEFSv12")

# Como el "GEFSv12_corr" y el "GEFSv12" tienen la misma estructura de datos, vamos a utilizar un ciclo "for":
for (i in seq_along(modelos_gefs)) {
  
  archivo_gefs <- paste0(modelos_gefs[i], "_", variable, "_", 2010, "_", 2019, "_", "mes", mes, "_", "dom", "_", lon_e, "_", lon_w, "_", lat_n, "_", lat_s, ".csv")
  
  # Se corre esta parte del código sólo si el archivo no fue generado previamente: 
  if (!file.exists(archivo_gefs)) {
    
    df_total <- data.frame()
    
    for (j in 2010:2019) { # Loop sobre los años.
      
      # Definimos el path:
      PATH0 <- paste0(tforecast, "/", modelos_gefs[i], "/", variable, "/", j, "/")
          
      # Listamos todass las carpetas del año y mes del bucket:
      awsfolders <- get_bucket_df(
        bucket = BUCKET_NAME,
        prefix = paste0(PATH0, j, sprintf("%02d", mes)),
        max = Inf,
        region = "us-west-2")
      awsfolders <- awsfolders$Key
          
      # Separamos a "awsfolder" en función de las fechas de inicializaciones: 
      awsfolders_inic <- unique(dirname(awsfolders))
      fechas_inic <- basename(awsfolders_inic) # Fechas de inicializaciones.
    
      for (k in seq_along(awsfolders_inic)) {
            
        fecha_inic <- fechas_inic[k]
            
        print("Extrayendo datos de los archivos inicializados en:")
        print(fecha_inic)
              
        # Nos quedamos sólo con los archivos correspondientes a esa fecha de inicialización: 
        awsfiles <- grep(fecha_inic, awsfolders, value = TRUE)
        # Nos quedamos solo con la corrida control (por cuestiones de tiempo). 
        awsfiles <- grep("c00", awsfiles, value = TRUE) # Comentarear esta línea en caso de querer hacerlo para todos los miembros del ensamble. 
    
        for (l in seq_along(awsfiles)) {
          
          print("Extrayendo datos del archivo:")
          print(awsfiles[l])
              
          gefs <- s3read_using(FUN = ncdf4::nc_open,
                               object = awsfiles[l], 
                               bucket = BUCKET_NAME,
                               opts = list(region = "us-west-2"))
          
          # Leemos  las coordenadas:
          # var <- ncvar_get(gefs, varid = variable)
          lon <- ncvar_get(gefs, varid = "lon") 
          lat <- ncvar_get(gefs, varid = "lat")
          time <- ncvar_get(gefs, "time")
          time_units <- ncatt_get(gefs, "time", "units")[["value"]]
          fecha_referencia <- as.Date(gsub("days since ", "", time_units))
          # Convertimos el tiempo a formato de días desde la fecha de referencia:
          fechas <- fecha_referencia + as.numeric(time)
              
          # Vemos la posición del dominio en las longitudes y latitudes de los datos:
          lon_idx <- which(lon >= lon_w & lon <= lon_e)
          lat_idx <- which(lat >= lat_s & lat <= lat_n)
          lon_rec <- lon[lon_idx]
          lat_rec <- lat[lat_idx]
          
          # Hacemos una selección de los datos en el dominio de interés y en la primer semana, y ahí extraemos los datos. Esta es la forma más eficiente de hacerlo:  
          var_rec <- ncvar_get(gefs, varid = variable, 
                               start = c(lon_idx[1], lat_idx[1], 1), 
                               count = c(length(lon_idx), length(lat_idx), 7))
          dim(var_rec) # Dimensiones: lon, lat, time.
      
          # Calculamos el acumulado pronósticado de la primer semana: 
          suma <- apply(var_rec[,,1:7], MARGIN = c(1, 2), FUN = sum)
          dim(suma)
            
          if (l == 1) {
            # Creamos una matriz con NA para guardar la info de todos los archivos (todos los miembros del ensamble):
            gvar <- array(NA, dim = c(length(lon_rec), length(lat_rec), length(awsfiles)))
          }
      
          # Guardamos el valor de la variable:
          gvar[,,l] <- suma
        }
        
        # Calculamos la media del ensamble: 
        media <- apply(gvar, MARGIN = c(1, 2), FUN = mean)
        dim(media)
        
        # Convertimos la matriz en un data.frame: 
        df <- data.frame(lon = rep(lon_rec, times = length(lat_rec)),
                         lat = rep(lat_rec, each = length(lon_rec)),
                         acum = array(media, length(lon_rec)*length(lat_rec)))
        df$fecha_inic <- as.Date(fecha_inic, format = "%Y%m%d")
        
        df_total <- bind_rows(df_total, df)
      }
    }
    # Guardamos la información en un archivo ".csv":
    write.table(df_total, file = archivo_gefs, sep = ";", quote = FALSE,
                col.names = TRUE, row.names = FALSE)  
  }
  rm(df_total)
  rm(archivo_gefs)
}
```

Cargamos los archivos ".csv" generados.

```r
df_total_corr <- read.table(paste0("GEFSv12_corr", "_", variable, "_", 2010, "_", 2019, "_", "mes", mes, "_", "dom", "_", lon_e, "_", lon_w, "_", lat_n, "_", lat_s, ".csv"), sep = ";", header = TRUE)
df_total_corr$fecha_inic <- as.Date(df_total_corr$fecha_inic)
df_total_sincorr <- read.table(paste0("GEFSv12", "_", variable, "_", 2010, "_", 2019, "_", "mes", mes, "_", "dom", "_", lon_e, "_", lon_w, "_", lat_n, "_", lat_s, ".csv"),  sep = ";", header = TRUE)
df_total_sincorr$fecha_inic <- as.Date(df_total_sincorr$fecha_inic)
```

## **ERA5**

Vamos a hacer un procedimiento análogo para los datos de ERA5. Vamos a generar un archivo ".csv" con la información de las mismas semanas, sólo si este no fue generado previamente.

```r
modelo <-  "ERA5"

archivo_obs <- paste0(modelo, "_", variable, "_", 2010, "_", 2019, "_", "mes", mes, "_", "dom", "_", lon_e, "_", lon_w, "_", lat_n, "_", lat_s, ".csv")

# Me fijo si el archivo ya fue generado, para no tener que descargar los datos nuevamente. 
if (!file.exists(archivo_obs)) {
  
  df_total <- data.frame()

  for (i in 2010:2019) { # Loop sobre los años.
    
    # Definimos el path: 
    PATH0 <-  paste0(modelo, "/", variable, "/") 
    awsfile <- paste0(PATH0, i, ".nc")
    
    print("Extrayendo datos del archivo:")
    print(awsfile)
            
    era5 <- s3read_using(FUN = ncdf4::nc_open,
                         object = awsfile, 
                         bucket = BUCKET_NAME,
                         opts = list(region = "us-west-2"))
    
    # Leemos  las coordenadas:
    # var <- ncvar_get(era5, varid = variable)
    lon <- ncvar_get(era5, varid = "longitude") 
    lat <- ncvar_get(era5, varid = "latitude")
    time <- ncvar_get(era5, "time")
    time_units <- ncatt_get(era5, "time", "units")[["value"]]
    fecha_referencia <- as.Date(gsub("days since ", "", time_units))
    # Convertimos el tiempo a formato de días desde la fecha de referencia:
    fechas <- fecha_referencia + as.numeric(time)
            
    # Vemos la posición del dominio en las longitudes y latitudes de los datos:
    lon_idx <- which(lon >= lon_w & lon <= lon_e)
    lat_idx <- which(lat >= lat_s & lat <= lat_n)
    lon_rec <- lon[lon_idx]
    lat_rec <- lat[lat_idx]
  
    # Hacemos una selección de los datos en el dominio de interés, y ahí extraemos los datos:  
    var_rec <- ncvar_get(era5, varid = variable, 
                         start = c(lon_idx[1], lat_idx[1], 1), 
                         count = c(length(lon_idx), length(lat_idx), -1))
    dim(var_rec) # Dimensiones: lon, lat, time.
    
    # Vemos las fechas de inicializacion de "df_total_corr" para ese año: 
    fechas_inic <- unique(df_total_corr$fecha_inic[which(year(df_total_corr$fecha_inic) == i)])
  
    for (j in seq_along(fechas_inic)) {
      
      aux_inic <- which(fechas == fechas_inic[j])
      
      # Hacemos el recorte desde la fecha de inicialización hasta la primer semana, sólo si el día final de la primer semana está incluido en el archivo (esto puede no pasar para el mes de diciembre):
      # Por ejemplo, puede pasar que la fecha de inicialización del pronóstico sea el 31-12-2010, por lo que no se va a poder calcular el acumulado semanal de la primer semana asociada a dicha fecha de inicialización.
      
      if ((aux_inic+6) > dim(var_rec)[3]) {next()}
      
      var_rec2 <- var_rec[,,aux_inic:(aux_inic+6)]
      
      # Calculamos el acumulado observado de la primer semana: 
      suma <- apply(var_rec2[,,1:7], MARGIN = c(1, 2), FUN = sum)
      dim(suma)
      
      # Convertimos la matriz en un df: 
      df <- data.frame(lon = rep(lon_rec, times = length(lat_rec)),
                       lat = rep(lat_rec, each = length(lon_rec)),
                       acum = array(suma, length(lon_rec)*length(lat_rec)))
      df$fecha_inic <- fechas_inic[j]
      
      df_total <- bind_rows(df_total, df)
    }
  }
  # Guardamos la información en un archivo ".csv":
  write.table(df_total, file = archivo_obs, sep = ";", quote = FALSE,
              col.names = TRUE, row.names = FALSE)  
}
rm(df_total)
rm(archivo_obs)
```

Cargamos  el archivo ".csv" generado:

```r
df_total_obs <- read.table(paste0(modelo, "_", variable, "_", 2010, "_", 2019, "_", "mes", mes, "_", "dom", "_", lon_e, "_", lon_w, "_", lat_n, "_", lat_s, ".csv"), sep = ";", header = TRUE)
df_total_obs$fecha_inic <- as.Date(df_total_obs$fecha_inic)
```

Juntamos en un único DataFrame la información pronosticada y del ERA5.

```{r}
df_total <- merge(df_total_corr, df_total_sincorr, 
                  by = c("lon", "lat", "fecha_inic"),
                  suffixes = c("_corr", "_sincorr"))

df_total <- merge(df_total_obs, df_total, 
                  by = c("lon", "lat", "fecha_inic"))

rm(df_total_obs, df_total_corr, df_total_sincorr)

# Eliminamos las filas con valores faltantes:
# Esto va a eliminar la fila con fecha de inicialización cuya primer semana no estuvo contemplada.
df_total <- na.omit(df_total)
```

Definimos una función para calcular los elementos de una tabla de contingencia:

- *Hits*: Cantidad de casos en los cuales la observación y el pronóstico superaron el umbral.  
- *False Alarms*: Cantidad de casos en los cuales el pronóstico superó el umbral pero la observación no.
- *Missed events*: Cantidad de casos en los cuales la observación superó el umbral pero el pronóstico no. 
- *Correct negatives*: Cantidad de casos en los cuales la observción ni el pronóstico superaron en umbral.

También la función calcula los siguientes índices de verificación, a partir de estos elementos:

- **Bias en la frecuencia**: Compara las frecuencias pronosticadas con las observadas.
- **Probabilidad de detección (POD)**: Indica la proporción de casos observados que sí fueron pronosticados. 
- **ETS o Equitable Threat Score**: Mide la proporción de aciertos pero ajustado por la cantidad de aciertos que fueron aleatorios. 

```r
funcion_tabla_cont <- function (observacion, pronostico, umbral) {
  # Creamos vectores lógicos para los valores que superan el umbral:
  obs_sup_umbral <- observacion > umbral
  prono_sup_umbral <- pronostico > umbral
  
  hits <- sum(obs_sup_umbral & prono_sup_umbral)
  false_alarms <- sum(!obs_sup_umbral & prono_sup_umbral)
  missed_events <- sum(obs_sup_umbral & !prono_sup_umbral)
  correct_negatives <- sum(!obs_sup_umbral & !prono_sup_umbral)
  
  total_events_observed <- hits + missed_events
  total_non_events_observed <- false_alarms + correct_negatives
  total_events_forecast <- hits + false_alarms
  total_non_events_forecast <- missed_events + correct_negatives
  total <- hits + false_alarms + missed_events + correct_negatives
  
  bias_frec <- total_events_forecast/total_events_observed
  pod <- hits/total_events_observed
  far <- false_alarms/total_events_forecast
  
  random_hits <- (as.numeric(total_events_forecast)*total_events_observed)/total
  ets <- (hits - random_hits)/(hits + false_alarms + missed_events - random_hits) 
  
  return(c(hits = hits, false_alarm = false_alarms, 
           missed_events = missed_events, correct_negatives = correct_negatives, 
           bias_frec = bias_frec, pod = pod, far = far, ets = ets))
}
```

# **Verificación temporal**

Calculamos los índices por año, considerando todo el dominio.

```r
# Definimos umbrales:
umbrales <- c(5, 30)

tabla_total_corr <- data.frame()
tabla_total_sincorr <- data.frame()

# Iteramos sobre cada umbral y año:
for (i in seq_along(umbrales)) {
  
  for (j in 2010:2019) {
    
    df_anio <- df_total[year(df_total$fecha_inic) == j,]
    
    # Calculamos la tabla de contingencia para el pronóstico corregido y sin corregir:
    tabla_corr <- funcion_tabla_cont(observacion = df_anio$acum, pronostico = df_anio$acum_corr,
                                     umbral = umbrales[i])
    tabla_corr <- cbind.data.frame(umbral = umbrales[i], anio = j, t(tabla_corr))
    tabla_total_corr <- bind_rows(tabla_total_corr, tabla_corr)
    
    tabla_sincorr <- funcion_tabla_cont(observacion = df_anio$acum, pronostico = df_anio$acum_sincorr, umbral = umbrales[i])
    tabla_sincorr <- cbind.data.frame(umbral = umbrales[i], anio = j, t(tabla_sincorr))
    tabla_total_sincorr <- bind_rows(tabla_total_sincorr, tabla_sincorr)
  }
}
```

Graficamos las series temporales, sólo para el umbral de 30 mm.

```r
# Elegimos un umbral:
umbral <- 30
tabla_corr <- tabla_total_corr[tabla_total_corr$umbral == umbral,]
tabla_sincorr <- tabla_total_sincorr[tabla_total_sincorr$umbral == umbral,]

jpeg(paste0("serie_temporal_verif", "_", variable, "_", 2010, "_", 2019, "_", "mes", mes, "_", "dom", "_", lon_e, "_", lon_w, "_", lat_n, "_", lat_s, ".jpg"), width = 1300, height = 800, units = "px", res = 130)

{# Bias_frec prono corregido: 
plot(x = tabla_corr$anio, y = tabla_corr$bias_frec, col = "red", pch = 19, 
     xlim = c(2010, 2019), ylim = c(-1,3), 
     xlab = "Anio", "ylab" = "Valores de índice", 
     main = paste("Pronóstico de precipitación semanal >", umbral, "mm","\n", "mes", mes,"\n", "Semana 1.", "Desde 2010 hasta 2019."))
lines(x = tabla_corr$anio, y = tabla_corr$bias_frec, col = "red", lwd = 1.5) 
# Bias_frec prono sin corregir: 
points(x = tabla_sincorr$anio, y = tabla_sincorr$bias_frec, col = "red", pch = 19)
lines(x = tabla_corr$anio, y = tabla_sincorr$bias_frec, col = "red", lwd = 1.5, lty = 2) 
# POD prono corregido: 
points(x = tabla_corr$anio, y = tabla_corr$pod, col = "blue", pch = 19) 
lines(x = tabla_corr$anio, y = tabla_corr$pod, col = "blue", lwd = 1.5)
# POD prono sin corregir: 
points(x = tabla_sincorr$anio, y = tabla_sincorr$pod, col = "blue", pch = 19) 
lines(x = tabla_sincorr$anio, y = tabla_sincorr$pod, col = "blue", lwd = 1.5, lty = 2)
# ETS prono corregido: 
points(x = tabla_corr$anio, y = tabla_corr$ets, col = "green", pch = 19) 
lines(x = tabla_corr$anio, y = tabla_corr$ets, col = "green", lwd = 1.5)
# ETS prono sin corregir: 
points(x = tabla_sincorr$anio, y = tabla_sincorr$ets, col = "green", pch = 19) 
lines(x = tabla_sincorr$anio, y = tabla_sincorr$ets, col = "green", lwd = 1.5, lty = 2)
legend("topright", legend = c("BIAS FREC", "POD", "ETS"), 
       title = "Índices",
       col = c("red", "blue", "green"), 
       pch = 19, lwd = 1.5, 
       cex = 0.8,
       inset = c(0.01, 0.01))
legend("topleft", legend = c("Corregido", "Sin corregir"), 
       title = "Pronósticos",
       col = "black", 
       pch = 19, lwd = 1.5, lty = c(1, 2),
       cex = 0.8,
       inset = c(0.01, 0.01))}

graphics.off()

knitr::include_graphics(paste0("serie_temporal_verif", "_", variable, "_", 2010, "_", 2019, "_", "mes", mes, "_", "dom", "_", lon_e, "_", lon_w, "_", lat_n, "_", lat_s, ".jpg"))
```

# **Verificación espacial**

Calculamos los índices por punto de retícula, considerando todos los años.

```r
umbrales <- c(5, 30)

tabla_total_corr <- data.frame()
tabla_total_sincorr <- data.frame()

# Iteramos sobre cada umbral y punto de retícula:
for (i in seq_along(umbrales)) {
  
  ptos_reticula <- unique(df_total[, c("lon", "lat")])
  
  for (j in 1:nrow(ptos_reticula)) {
    
    df_pto_reticula <- df_total[df_total$lon == ptos_reticula$lon[j] & df_total$lat == ptos_reticula$lat[j],]
    
    tabla_corr <- funcion_tabla_cont(observacion = df_pto_reticula$acum, pronostico = df_pto_reticula$acum_corr, umbral = umbrales[i])
    tabla_corr <- cbind.data.frame(umbral = umbrales[i], lon = ptos_reticula$lon[j],
                                   lat = ptos_reticula$lat[j], t(tabla_corr))
    tabla_total_corr <- bind_rows(tabla_total_corr, tabla_corr)
    
    tabla_sincorr <- funcion_tabla_cont(observacion = df_pto_reticula$acum, pronostico = df_pto_reticula$acum_sincorr, umbral = umbrales[i])
    tabla_sincorr <- cbind.data.frame(umbral = umbrales[i], lon = ptos_reticula$lon[j],
                                      lat = ptos_reticula$lat[j], t(tabla_sincorr))
    tabla_total_sincorr <- bind_rows(tabla_total_sincorr, tabla_sincorr)
  }
}
```

Graficamos los campos espaciales, sólo para el umbral de 30 mm.

```r
# Elegimos un umbral:
umbral <- 30
tabla_corr <- tabla_total_corr[tabla_total_corr$umbral == umbral,]
tabla_sincorr <- tabla_total_sincorr[tabla_total_sincorr$umbral == umbral,]

rast_tabla_corr <- rasterFromXYZ(tabla_corr[,c("lon", "lat", "pod")], crs = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
rast_tabla_sincorr <- rasterFromXYZ(tabla_sincorr[,c("lon", "lat", "pod")], crs = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))

# Creamos una escala y leyenda de colores: 
rango <- c(min(c(tabla_corr$pod, tabla_sincorr$pod), na.rm = TRUE), max(c(tabla_corr$pod, tabla_sincorr$pod), na.rm = TRUE))

jpeg(paste0("pod", "_", variable, "_", 2010, "_", 2019, "_", "mes", mes, "_", "dom", "_", lon_e, "_", lon_w, "_", lat_n, "_", lat_s, ".jpg"), width = 1700, height = 850, units = "px", res = 130)

par(mfrow = c(1, 2), mai = c(1, 1, 1, 1))
{plot(rast_tabla_corr, col = rev(green2red(99)), 
      breaks = seq(rango[1], rango[2], length.out = 100),
      xlim =  c(lon_w, lon_e), 
      ylim =  c(lat_s, lat_n),
      main = paste("Pronóstico corregido de precipitación semanal >", umbral, "mm", "\n", "mes", mes,"\n", "Semana 1.", "Desde 2010 hasta 2019."),
      xlab = "Longitud", ylab = "Latitud", 
      asp = 0, 
      legend = FALSE)
maps::map("world",
          lwd = 0.5, col = "black",
          xlim = c(lon_w, lon_e), 
          ylim = c(lat_s, lat_n), 
          add = TRUE)
plot(rast_tabla_sincorr, col = rev(green2red(99)), 
      breaks = seq(rango[1], rango[2], length.out = 100),
     xlim =  c(lon_w, lon_e), 
     ylim =  c(lat_s, lat_n),
     main = paste("Pronóstico sin corregir de precipitación semanal >", umbral, "mm", "\n", "mes", mes,"\n", "Semana 1.", "Desde 2010 hasta 2019."),
     xlab = "Longitud", ylab = "Latitud", 
     asp = 0, 
     axis.args = list(at = seq(rango[1], rango[2], abs(rango[1]-rango[2])/4),
                      labels = round(seq(rango[1], rango[2], abs(rango[1]-rango[2])/4), 2), cex.axis = 1),
     legend.args = list(text = "POD"))
maps::map("world",
          lwd = 0.5, col = "black",
          xlim = c(lon_w, lon_e), 
          ylim = c(lat_s, lat_n), 
          add = TRUE)}
graphics.off()

knitr::include_graphics(paste0("pod", "_", variable, "_", 2010, "_", 2019, "_", "mes", mes, "_", "dom", "_", lon_e, "_", lon_w, "_", lat_n, "_", lat_s, ".jpg"))
```

```