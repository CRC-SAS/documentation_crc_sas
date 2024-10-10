# Metodología de corrección

La predicción confiable de variables meteorológicas es fundamental a la hora de alimentar los  modelos aplicados. Pero es sabido que las predicciones tienen incertidumbres y errores que pueden en parte ser corregidos. Es por ello que se implementa una metodología para calibrar o corregir la base de pronósticos retrospectivos de los modelos GEFSv12 (subestacional) y CFSv2 (estacional), utilizando la metodología Quantile-Quantile mapping (Q-Q) según Boe et al. (2007) para todas las variables exceptuando la precipitación, para la que se utiliza la metodología a dos pasos propuesta por Iness y Hansen (2005). La calibración de los pronósticos se realiza para cada punto de retícula, utilizando los datos históricos de la correspondiente retícula de ERA5. Ambas metodologías necesitan un periodo histórico que se utiliza como base para estimar las distribuciones estadísticas tanto del pronóstico, como de los datos utilizados para corregir. Dicho período histórico corresponde al 2000-2009 (10 años) y luego se corrigen los datos entre 2010 a 2019. 

Se aplica la misma estrategia de corrección para ambos conjuntos de pronósticos, excepto que las predicciones subestacionales (GEFSv12) se corrigen utilizando la distribución estadística en cada plazo de pronóstico (34 distribuciones). Asimismo, la corrección de las predicciones estacionales (CFSv2) se realiza en el primer mes en cada plazo de pronóstico y luego se va subdividiendo en los próximos dos meses y luego para los 6 meses que restan. Esto se debe por un lado al tiempo de procesamiento y por el otro a que  para plazos superiores de pronóstico, no existen muchas diferencias entre sí como para seguir corrigiendo cada  plazo de manera individual.

Esto se puede ver en la Figura 2 que muestra para el caso de pronóstico subestacional cómo varía la función de distribución acumulada de la variable temperatura media dependiendo del plazo del pronóstico.

![jpg](./figuras/distrib_tmean_pergamino01.jpg#center)   _Figura 2: La distribución acumulada de enero para 4 plazos de pronóstico de GEFSv12 (panel izquierdo) y la distribución de ERA5 (panel derecho) para la Temperatura media. Datos entre 2000-2009._


Las distribuciones se calculan para el período histórico utilizando la distribución empírica, para no determinar ninguna distribución a priori a cada variable. Además, las distribuciones se generan utilizando trimestres solapados, es decir los pronósticos con fecha de enero, se corrigen con la distribución de datos entre diciembre-enero-febrero y así con cada mes. De esta forma es posible asegurar una cantidad de datos significativa para estimar la distribución. Una vez que ya se tienen los datos de la distribución, para cada pronóstico y su plazo, se estima la probabilidad correspondiente en la distribución del pronóstico y luego se iguala en aquella correspondiente a la de ERA5, por lo que se genera un nuevo valor, que corresponde al valor corregido. La Figura 3 muestra un esquema de esta metodología (Boé et al., 2007), con las distribuciones del pronóstico (panel de la izquierda) y de la observación (panel de la derecha) y donde el valor correspondiente al pronóstico se proyecta desde la distribución del pronóstico sobre la distribución observada, que en nuestro caso corresponde a la de ERA5.  


![jpg](./figuras/Boe2007.jpg#center) 
_Figura 3: Esquema de corrección para un valor del pronóstico de acuerdo al método Q-Q. La distribución del pronóstico (panel izquierdo) y la de las observaciones (panel derecho). Figura de Boé et al (2007)._



Para la precipitación, se realiza una calibración a dos pasos utilizando el mismo periodo histórico de 2000-2009. El primer paso es estimar el mínimo de precipitación de modo que la frecuencia de días de lluvia del modelo sea igual a la de ERA5. Esto debe hacerse, ya que un problema típico en los pronósticos es que la frecuencia de días sin precipitación suele estar subestimada. Como ejemplo, la Figura 4 muestra el valor mínimo de precipitación por plazo de pronóstico para GEFSv12 (hasta 34 días de plazo de pronóstico):  



![jpg](./figuras/minimo_pp.jpg#center)   _Figura 4: Valor mínimo de precipitación, según plazo de pronóstico para el modelo GEFSv12._


Una vez calculado este valor mínimo, cada pronóstico de precipitación menor que este valor, se considera que su valor calibrado es igual a 0.

El segundo paso de calibración para la precipitación corresponde a estimar la distribución de los días con precipitación (sobre el umbral mínimo). En este caso para ajustar los pronósticos (tanto para GEFSv12 o CFSv2) a los datos históricos la distribución seleccionada es la Gamma. A modo de ejemplo para el trimestre diciembre-enero-febrero, se muestra la distribución por plazo (para GEFSv12) y para ERA5 en la Figura 5. 

![jpg](./figuras/distrib_rain_pergamino01.jpg#center)   _Figura 5: Distribución para cuatro plazos de pronóstico de GEFSv12 en el trimestre diciembre-enero-febrero (panel izquierdo) y la distribución de ERA5 (panel derecho)._

Una vez calculados dicho valor y considerando el valor mínimo, se calibra la precipitación de la siguiente forma:

$x_i^{\prime} = \begin{cases} F_{I,\ obs}^{-1}(F_{I,\ GCM}(x_i)), & x_i\geq\tilde{x}\\ 0 & x_i< \tilde{x}\\ \end{cases}$

Donde $F$ corresponde a la distribución (obs es de ERA5 y GCM es el de pronóstico), $\tilde{x}$ corresponde al mínimo y $xi$ al valor de precipitación por calibrar. Dada la extensión del dominio y los distintos regímenes de precipitación, existen lugares que dependiendo del trimestre considerado cuentan con datos históricos insuficientes para estimar una distribución. En dicho caso se opta por no calibrar y dejar el mismo valor del pronóstico. Algunos sectores de ejemplo son el norte de Chile o algunos sectores de la Patagonia Argentina para los cuales existe una máscara que muestra para cada plazo de pronóstico donde se realizó la corrección.  

