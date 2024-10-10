# Descripción de los modelos utilizados para generar la base

La base fue generada a partir de los datos del modelo global GEFSv12 para escala subestacional (<a href="https://www.ncei.noaa.gov/products/weather-climate-models/global-ensemble-forecast" target="_blank">GEFSv12</a>) y modelo global CFSv2 para escala estacional  (<a href="https://www.ncei.noaa.gov/access/metadata/landing-page/bin/iso?id=gov.noaa.ncdc:C00878" target="_blank">CFSv2</a>) y para calibrar se utilizan los datos de (<a href="https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=overview" target="_blank">ERA5</a>). A continuación se da una caracterización de cada uno.


## GEFSv12

El modelo GEFSv12 es un modelo meteorológico desarrollado por National Centers for Environmental Prediction (NCEP) que genera 31 pronósticos separados (miembros del conjunto) para abordar incertidumbres subyacentes en los datos de entrada, como cobertura limitada, sesgos de instrumentos o sistemas de observación, y las limitaciones del modelo en sí. GEFSv12 es un modelo atmosférico, que utiliza pronósticos de otros modelos para representar la influencia del océano y hielo, aunque cuenta con un modelo de suelo y también para aerosoles de forma integrada. Cada miembro del ensamble se genera a partir de perturbaciones sobre la condición inicial. Dada la gran cantidad de datos generados de forma diaria (4 pronósticos por día, inicializados a 00, 06, 12 y 18 UTC de forma operativa), se hace complejo mantener una base retrospectiva asociada, por lo que NCEP opta por mantener una cantidad reducida de miembros del ensamble. En principio se almacenan pronósticos todos los días, pero sólo para cada miércoles se aumenta la cantidad a 11 miembros de ensamble con pronósticos hasta 35 días, mientras que en los otros días solo 6 miembros y en todos los casos inicializados a las 00 UTC de cada día.  

## CFSv2

El modelo climático CFSv2 (Saha et al., 2014) también fue desarrollado por NCEP y, a diferencia de GEFSv12, es un modelo totalmente acoplado que integra modelos de atmósfera, océano, superficie terrestre y hielo marino para proporcionar la mejor estimación de las variables climáticas. Para el caso de CFSv2, existen varios pronósticos retrospectivos que se almacenan, donde las diferencias radican en la fecha de inicio con un esquema definido a partir de la duración del pronóstico. Se encuentran disponibles valores pronosticados cada 6 horas hasta 45 días o hasta 6 meses (2000-abr 2011) y 9 meses (mayo 2011-2019) de plazo. Para esta base se optó por el segundo conjunto, dado que este modelo se utilizará para predicciones estacionales. Esto ocurre para algunas fechas de inicio del pronóstico y dado que los pronósticos se inician cada 6 horas, permite generar entonces un conjunto de 24 miembros considerando distintas fechas de inicio de pronóstico. A modo de ejemplo, los 24 miembros para un pronóstico que como referencia se inicia a mediados de enero, se deben considerar las siguientes fechas de inicio de pronóstico, de acuerdo al sitio web oficial de CFSv2 (tabla 1):  


_Tabla 1: Pronósticos históricos para mediados de enero (24 miembros)_  
| Mes | Día   | Horas         |
| --- | ----- | ------------- |
| 12  | 12    | 0, 6, 12, 18  |
| 12  | 17    | 0, 6, 12, 18  |
| 12  | 22    | 0, 6, 12, 18  |
| 12  | 27    | 0, 6, 12, 18  |
| 01  | 01    | 0, 6, 12, 18  |
| 01  | 06    | 0, 6, 12, 18  |


Los datos están disponibles cada 6 horas y se procesan para obtener valores diarios.

## ERA5

Para corregir los valores, se utilizaron los datos del reanálisis de ERA5 (Hersbach et al., 2023). ERA5 es el reanálisis atmosférico del clima global generado por el European Centre for Medium-Range Weather Forecasts (ECMWF) en su quinta generación y que tiene datos que abarcan el período comprendido entre enero de 1940 y el presente a partir de la combinación de datos de modelo y observaciones de todo el mundo de forma consistente. ERA5 es producido por el Servicio de Cambio Climático Copernicus (C3S) en ECMWF y proporciona estimaciones horarias de un gran número de variables climáticas atmosféricas, terrestres y oceánicas. Los datos cubren la Tierra en una cuadrícula de 31 kilómetros y resuelven la atmósfera utilizando 137 niveles desde la superficie hasta una altura de 80 kilómetros.  

## Variables incluidas en la base de datos

Para cada uno de los modelos descritos en las secciones 1.1.1 hasta 1.1.3, se considera un conjunto de variables, de todas las disponibles. Este subconjunto fue definido a partir de entrevistas con potenciales usuarios de la base de datos y que necesitan un conjunto de variables para modelos aplicados. A priori, temperatura (máxima, mínima y media) al igual que la precipitación son la base, pero dado que muchos de estos modelos necesitan alguna estimación de la evapotranspiración, lo que implica sumar variables como radiación y viento. En consecuencia, el listado completo de variables, que se utiliza para todos los modelos es el siguiente:  

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
* **mslmean:** Media diaria de presión a nivel del mar (Pa) [0-23 UTC] (*).

(*) Sólo se obtiene para ERA5.

Más detalles con respecto a los horarios y también las unidades que se consideran, se darán más adelante en conjunto con las especificaciones del archivo de salida.


