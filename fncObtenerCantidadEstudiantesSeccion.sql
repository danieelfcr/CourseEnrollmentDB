/*
	Función que mediante el id de una sección devuelve el conteo de todos los estudiantes que tengan un estado de asignación "Aprobado" 
	y pertenezcan a la sección enviada como parámetro
*/
CREATE FUNCTION fncObtenerCantidadEstudiantesSeccion (@seccion int)
RETURNS int
AS
BEGIN
	DECLARE @resultado int;
	SET @resultado = (
		SELECT COUNT(*) 
		FROM tx_Asignacion a 
			inner join Estado_Asignacion e on (a.Estado = e.ID_Estado_Asignacion) 
		WHERE a.Seccion = @seccion AND e.ID_Estado_Asignacion = 1); -- Estado 1 = Aprobado 
	RETURN @resultado;
END;