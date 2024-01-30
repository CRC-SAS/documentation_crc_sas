# Acceso a los datos

Los datos se encuentran disponibles en el **portal de AWS**: <a href="https://registry.opendata.aws/sissa-forecast-database-dataset/" target="_blank">https://registry.opendata.aws/sissa-forecast-database-dataset/</a>.

La descarga de los datos se puede realizar de las siguientes maneras:

**Vía URL** <br />
Los archivos pueden ser descargados directamente accediendo al siguiente link: <a href="https://s3-us-west-2.amazonaws.com/sissa-forecast-database/index.html" target="_blank">https://s3-us-west-2.amazonaws.com/sissa-forecast-database/index.html </a>.<br />
Los datos se almacenan utilizando el Amazon Simple Storage Service (S3). Para más información sobre esta herramienta visitar <a href="https://docs.aws.amazon.com/es_es/AmazonS3/latest/userguide/Welcome.html" target="_blank">https://docs.aws.amazon.com/es_es/AmazonS3/latest/userguide/Welcome.html </a>.

**AWS CLI** <br />
Los datos se pueden descargar utilizando la herramienta AWS Command Line Interface (CLI). Para más información sobre su instalación visitar el siguiente
<a href="https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" target="_blank">link </a>.<br />
A continuación se muestra, a modo de ejemplo, se muestran los comandos para hacer la descarga de un archivo individual y también para descargar todo un directorio (con nombre en el ejemplo: *directorio_salida*):

```bash
#!/usr/bin/env bash

# Se descarga el archivo del miembro control de lluvia pronosticada y corregido que inicializa el 27 de abril de 2011 al directorio_salida:
aws s3 cp --no-sign-request s3://sissa-forecast-database/subseasonal/GEFSv12_corr/rain/2011/20110427/rain_20110427_c00.nc directorio_salida

# Se descarga todos miembros del ensamble de pronósticos para la variable lluvia el 27 de abril de 2011 al directorio: directorio_salida:
aws s3 cp --no-sign-request --recursive s3://sissa-forecast-database/subseasonal/GEFSv12_corr/rain/2011/20110427/ directorio_salida
```

**Python**<br />
Para descargar los archivos se utiliza la librería <a href="https://pypi.org/project/s3fs/" target="_blank">s3fs</a>. <br />
A continuación se muestra, a modo de ejemplo, la descarga del archivo de un día:

```python
import s3fs
# Se descarga el archivo de pronóstico corregido de lluvia para el 27 de abril de 2011
s3_file = 's3://sissa-forecast-database/subseasonal/GEFSv12_corr/rain/2011/20110427/rain_20110427_c00.nc' 
fs = s3fs.S3FileSystem(anon=True)
data = fs.get(s3_file)
```

**R**<br />
Para descargar los archivos se utiliza la librería <a href="https://cran.r-project.org/web/packages/aws.s3/index.html" target="_blank">aws.s3</a>. <br />
A continuación se muestra, a modo de ejemplo, la descarga de todos los archivos de un día:

```R
library("aws.s3")
 
# Se define la función sissa.download para descarga de archivos
sissa.download <- function(sissa.name = sissa.name){
      save_object(
      object = paste0(sissa.name),
      bucket = "s3://sissa-forecast-database/",
      region = "us-west-2",
      file = substring(sissa.name, 28),
      overwrite = TRUE)}

# Se define la fecha de los datos a descargar
anual = 2011
mes = 4
dia = 27

# Se convierten en formato character de año, mes, día y ciclo
anual <- sprintf("%04d", anual)
mes <- sprintf("%02d", mes)
dia <- sprintf("%02d", dia)
 
# Se definen los nombres de los archivos del Bucket a descargar
sissa.names <- get_bucket_df(
    bucket = "s3://sissa-forecast-database/",
    prefix = paste0("subseasonal/GEFSv12_corr/rain/", anual, "/", anual, mes, dia, "/"),
    max = Inf,
    region = "us-west-2")
 
sissa.names.rows <- which(grepl(time, sissa.names$Key, fixed = TRUE) == TRUE)
sissa.names <- sissa.names[sissa.names.rows, ]
 
# Se ejecuta la función wrf.download 
lapply(sissa.names$Key, FUN = sissa.download)

```
