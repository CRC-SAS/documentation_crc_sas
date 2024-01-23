# Estructura de datos

La base de datos se encuentra bajo el programa de datos abiertos de Amazon Web Services (AWS) y cada dato se guarda o accede a través de un estructura denominada "*bucket*", cuyo nombre para esta base de datos es "*sissa-forecast-database*" y se puede consultar desde un navegador web utilizando el siguiente link: [https://s3-us-west-2.amazonaws.com/sissa-forecast-database/index.html]()

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

donde los campos entre llaves indican: `<br />`
{variable} = Alguna de las variables listadas en la sección anterior `<br />`
{año} = 4 dígitos para el año con valores entre 2000 y 2019 `<br />`

Ejemplos:

* /ERA5/rain/2010.nc corresponde al dato diario de acumulado de lluvia en mm para el año 2010.
* /ERA5/ROCsfc/2015.nc corresponde al dato de radiación de onda corta diario en J m-2 d-1 para el año 2015. El dato diario se calculo tomando desde las 0UTC a las 23 UTC.
