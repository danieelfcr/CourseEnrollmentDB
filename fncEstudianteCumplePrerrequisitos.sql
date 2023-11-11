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
		--Si la nota es menor que 65, se retorna bit 0 (no cumple con algun prerrequisito)
		--Si no se encuentra un resultado, retornar bit 0
	--Si finaliza el cursor y cumplió con las condiciones, retornar bit 1

	--Obtener el id curso de la seccion
	DECLARE @id_curso int
	SELECT @id_curso = ID_Curso
	FROM Seccion
	WHERE @id_seccion = ID_Seccion

	--Cursor
	DECLARE @vID_Prerrequisito int

	DECLARE c_datos cursor for
	--Query base
		SELECT Prerrequisito
		FROM Prerrequisito
		WHERE @id_curso = Curso and Estado = 1

	open c_datos
	--Recorrer el cursor
		
		fetch c_datos into @vID_Prerrequisito
		while(@@FETCH_STATUS = 0)
		begin
			--Tomando el ID_Prerrequisito (Id de un curso) tomar tambien el ID_estudiante y buscar en el historial
			DECLARE @vNotaPrerrequisito int = -1
			SELECT @vNotaPrerrequisito = Nota
			FROM Historial_Cursos
			WHERE @vID_Prerrequisito = Curso and @id_estudiante = Estudiante and Nota >= 65

			IF(@vNotaPrerrequisito = -1)
			BEGIN
				RETURN 0	--Si es -1, significa que la nota es menor que 65 o no ha cursado prerrequisito, por lo que se devuelve 0
			END

			fetch c_datos into @vID_Prerrequisito
		end
	close c_datos
	deallocate c_datos

	RETURN 1 --Si todo salio bien, retornar 1

END;