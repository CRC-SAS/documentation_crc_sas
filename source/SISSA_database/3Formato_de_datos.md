# Formato de datos

El formato de los archivos es **NetCDF** (de sus siglas en inglés Network Common Data Form) en su 4° versión (NetCDF-4). Este es un formato destinado a almacenar datos científicos multidimensionales (variables) ampliamente utilizado en el ámbito de la meteorología. La convención utilizada para escribir el dato es la Climate and Forecast Metadata Conventions (<a href="http://cfconventions.org/" target="_blank">CF </a>). Para más información sobre el formato **NetCDF** visitar el siguiente <a href="https://docs.unidata.ucar.edu/netcdf-c/current/index.html" target="_blank">link </a>.

**Proyección de los datos** <br />
El tipo de proyección utilizada es una reticula regular de tipo lat/long con una resolución de 0.25° (~27km). El área que abarcan los datos es toda la zona del CRC-SAS.

**Dimensiones** <br />

Dado que son datos diarios para todos los archivos, la única diferencia que aparece es en la cantidad de días que incluye el archivo, dependiendo de si proviene de ERA5, GEFSv12 o CFS. Las dimensiones espaciales son las mismas para todos ellos.

| Dimensión | Valor   | Modelo  |
| ---------- | ------- | ------- |
| time       | 365/366 | ERA5    |
| time       | 34      | GEFSv12 |
| time       | 180/184 | CFS2    |
| y          | 187     | Todos   |
| x          | 189     | Todos   |

**Variables** <br />
Dada la cantidad de datos que se disponibilizan y puediendo haber problemas a la hora de descargarlo o trabajar en línea, se optó por que cada archivo contenga una de las variables de pronóstico o de reanálisis. Las variables que se pueden encontrar en todos los modelos son los siguientes:

| Variable | Descripción                                                                   | Unidad    | Precisión |
| -------- | ------------------------------------------------------------------------------ | --------- | ---------- |
| rain     | Precipitación acumulada en 1 día (12-12 UTC) (\*)                           | mm        | double     |
| tmean    | Temperatura media del día a 2 metros (0-23 UTC) (\*)                         | °C       | double     |
| tmax     | Temperatura máxima del día a 2 metros (0-23 UTC) (\*)                     | °C       | double     |
| tmin     | Temperatura mínima del día a 2 metros (0-23 UTC)(*)                          | °C       | double     |
| tdmean   | Temperatura media punto de rocío a 2 metros (0-23 UTC)                       | °C       | float32    |
| u10      | Magnitud promedio del viento a 10 metros (0-23 UTC) (*)                        | m/s       | float32    |
| u10mean  | Media diaria de componente zonal del viento a 10 metros (0-23 UTC) (\*)       | m/s       | float32    |
| v10mean  | Media diaria de componente meridional del viento a 10 metros (0-23 UTC) (\*) | m/s       | float32    |
| rh       | Media diaria de humedad relativa en 2 metros (0-23 UTC)                        | %         | float32    |
| pvmean   | Media diaria de presión de vapor (0-23 UTC)                                   | hPa       | float32    |
| spmean   | Media diaria de presión superficial (0-23 UTC)                                | Pa        | float32    |
| ROCsfc   | Radiación de solar o de onda corta entrante en superficie (0-23 UTC)          | J m-2 d-1 | float32    |
| ROLnet   | Radiación neta  de onda larga en superficie (0-23 UTC)                        | J m-2 d-1 | float32    |
| mslmean  | Media diaria de presión a nivel del mar (0-23 UTC)                            | Pa        | float32    |

(\*) Variables calibradas con datos ERA5.<br />

**Variables de coordenadas:**<br />

Las variables de coordenas presentes en los archivos son las siguientes:

| Variable | Descripción | Unidad                                         | Precisión |
| -------- | ------------ | ---------------------------------------------- | ---------- |
| time     | Tiempo       | Horas desde el inicio del ciclo de pronóstico | double     |
| lat      | Latitud      | ° (convención entre 90° y -90°)            | double     |
| lon      | Longitud     | Metros desde el centro de la retícula         | double     |
