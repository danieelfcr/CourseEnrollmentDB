--Vista 1: Estadísticas de Inscripción:
--Muestra la cantidad de estudiantes inscritos y en lista de espera por curso y sección.
CREATE VIEW Vista_EstadisticasInscripcion AS
SELECT cu.Nombre, se.Numero_Seccion,
    SUM(CASE WHEN ta.Estado = 1  OR ta.Estado = 3 THEN 1 ELSE 0 END) AS Estudiantes_Inscritos,
    SUM(CASE WHEN ta.Estado = 2 THEN 1 ELSE 0 END) AS Estudiantes_Lista_Espera
FROM tx_Asignacion ta
INNER JOIN Seccion se ON ta.Seccion = se.ID_Seccion
INNER JOIN Curso cu ON se.ID_Curso = cu.ID_Curso
WHERE ta.Estado IN (1, 2, 3)
GROUP BY cu.Nombre, se.Numero_Seccion

/*select 
	cu.Nombre, se.Numero_Seccion,
    case 
        when a.Estado = 1 or a.Estado = 3 then 'Asignados'
        when a.Estado = 2 then 'Lista de Espera'
    end as Estado,
    COUNT(*) as cantidad
FROM 
    tx_Asignacion a
    join Seccion se on a.Seccion = se.ID_Seccion
    join Curso cu on cu.ID_Curso = se.ID_Curso
where a.Estado in (1,2,3)
group by 
cu.Nombre,
    case 
        when a.Estado = 1 or a.Estado = 3 then 'Asignados'
        when a.Estado = 2 then 'Lista de Espera'
    end
order by cu.Nombre, se.Numero_Seccion*/


--Vista 2: Promedio de Tiempo de Solicitud
--Calcula el promedio de tiempo que lleva procesar cada solicitud de asignación.
CREATE VIEW Vista_TiempoPromedioSolicitud AS
SELECT AVG(DATEDIFF(hour, Fecha_Creacion, Fecha_Asignacion)) as PromedioTiempo
FROM tx_Asignacion
WHERE Fecha_Asignacion is not null


--Vista 3: Asignaciones No Realizadas
--Informa sobre la cantidad de asignaciones que no se llevaron a cabo y proporciona la razón de la no asignación.
CREATE VIEW Vista_AsignacionesNoRealizadas AS
SELECT ea.Descripcion, COUNT(*)
FROM tx_Asignacion ta INNER JOIN Estado_Asignacion ea on ta.Estado = ea.ID_Estado_Asignacion
WHERE Estado = 0 or Estado = 4
GROUP BY ea.Descripcion

--Vista 4: Registro de Cambios de Seccion
--Muestra un listado de estudiantes que fueron movidos de una sección a otra.
CREATE VIEW Vista_CambiosSeccion AS
SELECT es.Nombre, es.Primer_Apellido, es.Codigo_Estudiante
FROM tx_Asignacion ta inner join Estudiante es on ta.Estudiante = es.ID_Estudiante
WHERE ta.Estado = 2