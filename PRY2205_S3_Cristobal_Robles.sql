/* =====================================================================
   PRY2205 - CONSULTA DE BASES DE DATOS
   SEMANA 3 - ACTIVIDAD SUMATIVA: "APLICANDO FUNCIONES DE AGRUPACION"
   Caso: Empresa ASOCIADOS (corredora de propiedades)
   Alumno: Cristobal Robles
   Usuario BD: PRY2205_S3 / Conexion: PRY2205_ACTIVIDAD_S3
   ---------------------------------------------------------------------
   PASOS PREVIOS (ya ejecutados):
     1. Conectado como SYS/SYSTEM (o ADMIN en Oracle Cloud) se ejecuto
        el script script_crea_usuario.sql, que crea al usuario PRY2205_S3.
     2. Se creo la conexion PRY2205_ACTIVIDAD_S3 con ese usuario.
     3. Conectado con PRY2205_S3 se ejecuto el script
        PRY2205_Exp1_S3_CreaEsquemaPoblado.sql, que crea y pobla las tablas.
   ===================================================================== */

-- Formato numerico chileno: punto como separador de miles.
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ',.';


/* =====================================================================
   CASO 1: ANALISIS DE PROPIEDADES
   ---------------------------------------------------------------------
   Informe comercial resumido por tipo de propiedad, que muestra la
   cantidad de propiedades, el arriendo maximo, minimo y promedio, la
   clasificacion segun el arriendo maximo (ESTANDAR / PREMIUM) y el total
   de gastos comunes. Solo se muestran los tipos cuyo total de gastos
   comunes supera el monto ingresado por el operador.
   Ordenado por total de gasto comun en forma descendente.
   ===================================================================== */
SELECT UPPER(p.id_tipo_propiedad)                               AS "TIPO",
       COUNT(p.nro_propiedad)                                   AS "TOTAL_PROPIEDADES",
       TO_CHAR(MAX(p.valor_arriendo), '$9G999G999')             AS "MAX_ARRIENDO",
       TO_CHAR(ROUND(AVG(p.valor_arriendo)), '$9G999G999')      AS "PROMEDIO_ARRIENDO",
       TO_CHAR(MIN(p.valor_arriendo), '$9G999G999')             AS "MIN_ARRIENDO",
       CASE
            WHEN MAX(p.valor_arriendo) <= 1000000 THEN 'ESTÁNDAR'
            ELSE 'PREMIUM'
       END                                                      AS "CLASIFICACION",
       TO_CHAR(SUM(NVL(p.valor_gasto_comun, 0)), '$9G999G999')  AS "TOTAL_GASTOS_COMUNES"
FROM   propiedad p
GROUP  BY p.id_tipo_propiedad
HAVING SUM(NVL(p.valor_gasto_comun, 0)) > &VALOR_TOTAL_GASTO_COMUN
ORDER  BY SUM(NVL(p.valor_gasto_comun, 0)) DESC;


/* =====================================================================
   CASO 2: ANALISIS DE ANTIGUEDAD DE EMPLEADOS
   ---------------------------------------------------------------------
   Empleados de la categoria "Ejecutivo de Arriendo" (id_categoria_emp = 3)
   con mas de 5 anios de antiguedad y que NO pertenecen a la sucursal
   ingresada por el operador.
   Clasificacion de sueldo:  > $2.000.000 = ALTO   /   <= $2.000.000 = MEDIO
   Bono de antiguedad:  5 a 10 anios = 5%  |  11 a 20 anios = 10%
                        mas de 20 anios = 15%
   La antiguedad se calcula con SYSDATE (sin fechas fijas).
   Ordenado por sueldo del empleado en forma descendente.
   ===================================================================== */
SELECT UPPER(e.nombre_emp || ' ' || e.appaterno_emp)                   AS "Nombre Empleado",
       TO_CHAR(NVL(e.sueldo_emp, 0), '$9G999G999')                     AS "Sueldo con Formato",
       CASE
            WHEN NVL(e.sueldo_emp, 0) > 2000000 THEN 'ALTO'
            ELSE 'MEDIO'
       END                                                             AS "Clasificación Sueldo",
       TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecing_emp) / 12)               AS "Años Antigüedad",
       'Corresponde bono ' ||
       LPAD(TO_CHAR(CASE
                         WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecing_emp) / 12) <= 10 THEN 5
                         WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecing_emp) / 12) <= 20 THEN 10
                         ELSE 15
                    END), 2) || '%: ' ||
       TO_CHAR(ROUND(NVL(e.sueldo_emp, 0) *
                     CASE
                         WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecing_emp) / 12) <= 10 THEN 5
                         WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecing_emp) / 12) <= 20 THEN 10
                         ELSE 15
                     END / 100), '$9G999G999')                         AS "BONO"
FROM   empleado e
WHERE  e.id_categoria_emp = 3
AND    e.id_sucursal <> &CODIGO_SUCURSAL
AND    TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecing_emp) / 12) > 5
ORDER  BY e.sueldo_emp DESC;


/* =====================================================================
   CASO 3: LISTA DE CLIENTES
   ---------------------------------------------------------------------
   Clasificacion de clientes segun su renta:
        PREMIUM -> renta >= $1.000.000
        ALTA    -> renta entre $600.000 y $999.999
        MEDIA   -> renta entre $300.000 y $599.999
        BAJA    -> renta inferior a $300.000
   Muestra la cantidad de clientes y la renta promedio de cada grupo, e
   indica si el grupo tiene o no telefono registrado:
        "Clientes Sin Teléfono" -> ningun cliente del grupo tiene telefono
        "Clientes con Teléfono" -> al menos 1 cliente tiene telefono
   Solo se consideran los grupos con renta promedio superior a $200.000.
   ===================================================================== */
SELECT CASE
            WHEN NVL(c.renta_cli, 0) >= 1000000 THEN 'PREMIUM'
            WHEN NVL(c.renta_cli, 0) >= 600000  THEN 'ALTA'
            WHEN NVL(c.renta_cli, 0) >= 300000  THEN 'MEDIA'
            ELSE 'BAJA'
       END                                                        AS "CLASIFICACION_RENTA",
       COUNT(c.numrut_cli)                                        AS "CANTIDAD_CLIENTES",
       TO_CHAR(ROUND(AVG(NVL(c.renta_cli, 0))), '$9G999G999')     AS "RENTA_PROMEDIO",
       'Clientes ' ||
       CASE
            WHEN COUNT(c.fonofijo_cli) = 0 THEN 'Sin'
            ELSE 'con'
       END || ' Teléfono'                                         AS "ESTADO_TELEFONO"
FROM   cliente c
GROUP  BY CASE
               WHEN NVL(c.renta_cli, 0) >= 1000000 THEN 'PREMIUM'
               WHEN NVL(c.renta_cli, 0) >= 600000  THEN 'ALTA'
               WHEN NVL(c.renta_cli, 0) >= 300000  THEN 'MEDIA'
               ELSE 'BAJA'
          END
HAVING ROUND(AVG(NVL(c.renta_cli, 0))) > 200000;
