exec uspUploadData

select *
from tx_Asignacion

truncate table tx_Asignacion

--Vista 1: Estadísticas de Inscripción:
--Muestra la cantidad de estudiantes inscritos y en lista de espera por curso y sección.
SELECT cu.Nombre, se.Numero_Seccion,
    SUM(CASE WHEN ta.Estado = 1  OR ta.Estado = 3 THEN 1 ELSE 0 END) AS Estudiantes_Inscritos,
    SUM(CASE WHEN ta.Estado = 2 THEN 1 ELSE 0 END) AS Estudiantes_Lista_Espera
FROM tx_Asignacion ta
INNER JOIN Seccion se ON ta.Seccion = se.ID_Seccion
INNER JOIN Curso cu ON se.ID_Curso = cu.ID_Curso
WHERE ta.Estado IN (1, 2, 3)
GROUP BY cu.Nombre, se.Numero_Seccion
ORDER BY 1 ASC

--Vista 2: Promedio de Tiempo de Solicitud
--Calcula el promedio de tiempo que lleva procesar cada solicitud de asignación.
SELECT AVG(DATEDIFF(MICROSECOND, Fecha_Creacion, Fecha_Asignacion)) as 'Promedio Tiempo (Microsegundos)'
FROM tx_Asignacion
WHERE Fecha_Asignacion is not null

--Vista 3: Asignaciones No Realizadas
--Informa sobre la cantidad de asignaciones que no se llevaron a cabo y proporciona la razón de la no asignación.
SELECT ea.Descripcion, COUNT(*) as CantidadAsignaciones
FROM tx_Asignacion ta INNER JOIN Estado_Asignacion ea on ta.Estado = ea.ID_Estado_Asignacion
WHERE Estado = 0
GROUP BY ea.Descripcion

--Vista 4: Registro de Cambios de Seccion
--Muestra un listado de estudiantes que fueron movidos de una sección a otra.
SELECT distinct es.Nombre, es.Primer_Apellido, es.Codigo_Estudiante
FROM tx_Asignacion ta inner join Estudiante es on ta.Estudiante = es.ID_Estudiante
WHERE ta.Estado = 3

