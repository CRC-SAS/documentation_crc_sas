# Estructura general de la base de datos pronosticados

La base de datos pronosticados se encuentra almacenada bajo el programa de datos abiertos de Amazon Web Services (AWS) y cada dato se almacena o accede a través de un estructura denominada "*bucket*", cuyo nombre para esta base de datos es "*sissa-forecast-database*" y se puede consultar desde un navegador web utilizando el siguiente link:

[https://s3-us-west-2.amazonaws.com/sissa-forecast-database/index.html](https://s3-us-west-2.amazonaws.com/sissa-forecast-database/index.html)

Dentro del bucket, se puede acceder a los datos a través del navegador, así como también a través de algún script. La base dentro de AWS tiene una estructura de carpetas que se describe a continuación.

## Estructura de la carpeta de los datos ERA5

La estructura para esta carpeta se puede resumir de la siguiente forma:

/ERA5/{variable}/{año}.nc

donde los campos entre llaves indican:  
{variable} = Alguna de las variables listadas en la sección anterior  
{año} = 4 dígitos para el año con valores entre 2000 y 2019  

Ejemplos:

* /ERA5/rain/2010.nc corresponde al dato diario de acumulado de lluvia en mm para el año 2010.
* /ERA5/ROCsfc/2015.nc corresponde al dato de radiación de onda corta diario en J m-2 d-1 para el año 2015. El dato diario se calculo tomando desde las 0UTC a las 23 UTC.

## Estructura de la carpeta de predicciones subestacionales (GEFSv12)

Los datos almacenados  de los pronósticos históricos de GEFSv12 l, son solo aquellos pronósticos de cada miércoles, donde se almacenan 11 miembros del conjunto y con una duración de 35 días, los cuales se reducen a un día menos (34), debido al cálculo diario que se hace en el post procesamiento. Por ende la estructura para esta carpeta llamada “subseasonal”, es un poco más compleja que aquella de ERA5 y se puede resumir de la siguiente forma para acceder a un archivo:

/subseasonal/{modelo}/{variable}/{año}/{año}{mes}{dia}/{variable}\_{año}{mes}{dia}\_{ens_mem}.nc

donde los campos entre llaves indican:  
{modelo} = Dato de pronóstico sin corregir (*GEFSv12*) o pronóstico corregido (*GEFSv12_corr*)  
{variable} = Alguna de las variables listadas en la sección inicial (**rain**, **pvmean**, **tdmean**, etc.)  
{año} = 4 dígitos para el año con valores entre 2000 y 2019 para *GEFSv12* y 2010 y 2019 para *GEFSv12_corr*  
{mes} = mes en formato con dos dígitos  
{dia} = día en formato con dos digitos. Sólo válido para dias miercoles.  
{ens_mem} = Miembro del ensamble, que para cada fecha puede tener hasta 11 miembros (c00 y p{xx} con xx entre 01 y 10)  

Ejemplos:

* subseasonal/GEFSv12/rain/2010/20100317/rain_20100317_c00.nc corresponde al pronóstico de lluvia acumulada diaria inicializada el miercoles 17 de marzo a las 00 UTC para el miembro de control del ensamble.  
* subseasonal/GEFSv12/rain/2010/20100317/rain_20100317_p08.nc corresponde al pronóstico de lluvia acumulada diaria inicializada el miercoles 17 de marzo del 2010 a las 00 UTC para el miembro 08 del ensamble.  
* subseasonal/GEFSv12_corr/pvmean/2017/20171122/pvmean_20171122_p03.nc corresponde al pronóstico corregido de promedio diario de presión de vapor inicializada el miercoles 22 de noviembre de 2017 a las 00 UTC para el miembro 03 del ensamble.  

## Estructura de la carpeta de datos de predicción estacional (CFSv2)

Los datos que se almacenan de los pronósticos históricos de CFSv2 corresponden a  aquellas predicciones retrospectivas que tienen una larga duración del plazo de pronóstico. La estructura de la carpeta “seasonal” es la siguiente:  

/seasonal/{modelo}/{variable}/{año}/{mes}/{variable}.01.{año}{mes}{dia}{hora}.nc  

donde los campos entre llaves indican:  
{modelo} = Dato de pronóstico sin corregir (CFSv2) o pronóstico corregido (CFSv2_corr).  
{variable} = Alguna de las variables listadas en la sección inicial (rain, pvmean, tdmean, etc.).
{año} = 4 dígitos para el año con valores entre 2000 y 2019 para CFSv2 y 2010 y 2019 para CFSv2_corr.  
{mes} = mes de inicio de pronóstico en formato con dos dígitos.  
{dia} = día de inicio de pronóstico en formato con dos dígitos. Corresponde a los días como en la tabla de ejemplo, pero para cada mes.  
{hora} = hora de inicio de pronóstico (00, 06, 12 y 18).  


Ejemplo:  

seasonal/CFSv2/tmax/2013/01/tmax.01.2012122706.nc  
Corresponde al pronóstico de temperatura máxima diaria inicializada el 27 de diciembre de 2011 a las 06 UTC  


