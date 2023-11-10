/*
	Función que retorna 1 si el estudiante cumple con prerrequisitos o 0 si el estudiante no los cumple
*/
CREATE FUNCTION fncEstudianteCumplePrerrequisitos (@id_seccion int, @id_estudiante int)
RETURNS BIT
AS
BEGIN

	--Obtener ID Curso
	--Con el ID Curso, obtener los prerrequisitos en una tabla y establecer un cursor par dicha tabla
	--En la tabla de Historial Cursos, buscar el curso y la nota por cada iteracion del cursor, tomando en cuenta que:
		--Si la nota es menor que 65, se retorna bit 0 (no cumple con algun prerrequisito
		--Puede haber mas de un resultado al realizar el select, ya que pudo haber repetido el curso, por lo que siempre elegir la fecha mayor
		--Si no se encuentra un resultado, retornar bit 0
	--Si finaliza el cursor y cumplió con las condiciones, retornar bit 1

	DECLARE @id_curso int

	SELECT @id_curso = ID_Curso
	FROM Seccion
	WHERE @id_seccion = ID_Seccion



END;