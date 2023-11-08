CREATE PROCEDURE uspUploadData  --Nombre del SP
AS
BEGIN
	SET NOCOUNT ON; --No muestra las filas aceptadas	
	SET TRAN ISOLATION LEVEL SERIALIZABLE	--Nivel de aislamiento ?

	create table #tIngreso_Estudiantes(
	Codigo_Estudiante varchar(20) not null,
	Nombre varchar(20) not null,
	Apellido varchar(20) not null,
	Codigo_Seguridad varchar(20) not null,
	Codigo_Curso varchar(20) not null
)



END

