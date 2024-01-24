# Estructura de datos

La base de datos se encuentra bajo el programa de datos abiertos de Amazon Web Services (AWS) y cada dato se guarda o accede a través de un estructura denominada "*bucket*", cuyo nombre para esta base de datos es "*sissa-forecast-database*" y se puede consultar desde un navegador web utilizando el siguiente link:<br />
[https://s3-us-west-2.amazonaws.com/sissa-forecast-database/index.html](https://s3-us-west-2.amazonaws.com/sissa-forecast-database/index.html)

Los datos se encuentran a escala diaria para ERA5, GEFSv12 y CFSv2. El listado completo de variables, que se utiliza para todos los modelos es el siguiente:

* **pvmean:** Media diaria de presión de vapor (hPa) [0-23 UTC].
* **rain:** Acumulado diario de lluvia (mm) [0-23 UTC].
* **rh:** Media de humedad relativa (%) [0-23 UTC].
* **ROCsfc:** Radiación de solar o de onda corta entrante (J m-2 d-1) [0-23 UTC].
* **ROLnet:** Radiación neta  de onda larga (J m-2 d-1) [0-23 UTC].
* **spmean:** Media diaria de presión superficial (Pa) [0-23 UTC].
* **tdmean:** Media diaria de temperatura de punto de rocío 2m (Celsius) [0-23 UTC].
* **tmax:** Máxima diaria de temperatura a 2m (Celsius) [0-23 UTC].
* **tmean:** Media diaria de temperatura a 2m (Celsius) [0-23 UTC].
* **tmin:** Mínima diaria de temperatura a 2m (Celsius) [0-23 UTC].
* **u10:** Media de velocidad del viento a 10m (m s-1) [0-23 UTC].
* **u10mean:** Media componente zonal del viento a 10m (m s-1) [0-23 UTC].
* **v10mean:** Media componente meridional del viento a 10m (m s-1) [0-23 UTC].
* **mslmean:** Media diaria de presión a nivel del mar (Pa) [0-23 UTC] -> Solo en ERA5.

Dentro del bucket, para acceder a los datos a través del navegador, asi como también a través de algun script, existe una estructura de las carpetas que vamos a describir a continuación.

## Estructura datos carpeta ERA5

La estructura para esta carpeta se puede resumir de la siguiente forma:

/ERA5/{variable}/{año}.nc

donde los campos entre llaves indican: <br />
{variable} = Alguna de las variables listadas en la sección anterior <br />
{año} = 4 dígitos para el año con valores entre 2000 y 2019 <br />

Ejemplos:

* /ERA5/rain/2010.nc corresponde al dato diario de acumulado de lluvia en mm para el año 2010.
* /ERA5/ROCsfc/2015.nc corresponde al dato de radiación de onda corta diario en J m-2 d-1 para el año 2015. El dato diario se calculo tomando desde las 0UTC a las 23 UTC.

## Estructura de datos subseasonal (GEFv12)

Los datos que se guardan de pronósticos histórcios de GEFSv12 de acuerdo al sitio oficial, son solo aquellos pronósticos de cada miercoles, donde se guardan 11 miembros de ensamble y con una duración de 35 días, los cuales se reducen a un día menos (34), debido al calculo diario que se hace en el postprocesamiento. Por ende la estructura para esta carpeta, es un poco más compleja que aquella de ERA5 y se puede resumir de la siguiente forma:

/subseasonal/{modelo}/{variable}/{año}/{año}{mes}{dia}/{variable}\_{año}{mes}{dia}\_{ens_mem}.nc

donde los campos entre llaves indican: <br />
{modelo} = Valor sin corregir de pronóstico (GEFSv12) o pronóstico corregido (GEFSv12_corr) <br />
{variable} = Alguna de las variables listadas en la sección inicial (rain, pvmean, tdmean, etc.) <br />
{año} = 4 dígitos para el año con valores entre 2000 y 2019 para GEFSv12 y 2010 y 2019 para GEFSv12_corr <br />
{mes} = mes en formato con dos dígitos <br />
{dia} = día en formato con dos digitos. Sólo válido para dias miercoles. <br />
{ens_mem} = Miembro del ensamble, que para cada fecha puede tener hasta 11 miembros (c00 y p{xx} con xx entre 01 y 10) <br />

Ejemplos:

* subseasonal/GEFSv12/rain/2010/20100317/rain_20100317_c00.nc corresponde al pronóstico de lluvia acumulada diaria inicializada el miercoles 17 de marzo a las 00 UTC para el miembro de control del ensamble.
* subseasonal/GEFSv12/rain/2010/20100317/rain_20100317_p08.nc corresponde al pronóstico de lluvia acumulada diaria inicializada el miercoles 17 de marzo del 2010 a las 00 UTC para el miembro 08 del ensamble.
* subseasonal/GEFSv12_corr/pvmean/2017/20171122/pvmean_20171122_p03.nc corresponde al pronóstico corregido de promedio diario de presión de vapor inicializada el miercoles 22 de noviembre de 2017 a las 00 UTC para el miembro 03 del ensamble
