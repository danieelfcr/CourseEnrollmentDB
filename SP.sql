CREATE PROCEDURE uspUploadData  --Nombre del SP
AS
BEGIN
	SET NOCOUNT ON; --No muestra las filas aceptadas	
	SET TRAN ISOLATION LEVEL SERIALIZABLE	--Nivel de aislamiento ?

	create table #tIngreso_Estudiantes(
	Codigo_Estudiante varchar(20) not null,
	Segundo_Apellido varchar(20) not null,
	Codigo_Seguridad varchar(20) not null,
	Curso_Asignar varchar(20) not null
)
begin try 
    BULK INSERT #tIngreso_Estudiantes
    FROM '‪C:\Input.csv'
    WITH ( FORMAT = 'CSV',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIRSTROW = 1 
    );
	end try
	begin catch
		print 'Ha ocurrido un error al cargar el archivo :/'
	end catch

	begin tran
	declare @CodigoEstudiante varchar(20),
			@ApellidosSegun varchar(20),
			@CodigoSegur varchar(20),
			@CursoAsign varchar(20),
			@ID_Estudiante int,
			@Fecha_CreacionTX datetime,
			@Fecha_AsignacionTX datetime,
			@SeccionTX int,
			@EstadoTX int

	Declare cDatosAsign cursor for
	select Codigo_Estudiante, Segundo_Apellido, Codigo_Seguridad, Curso_Asignar
	from #tIngreso_Estudiantes

	open cDatosAsign;
	fetch next from cDatosAsign into @CodigoEstudiante, @ApellidosSegun, @CodigoSegur, @CursoAsign
	
	WHILE @@FETCH_STATUS = 0
    BEGIN
		BEGIN TRY
		--Obtener fecha-tiempo actual para Fecha_Creacion
		set @Fecha_CreacionTX = GETDATE()

		--Comprobacion de datos: codigo estudiante, apellido y codigo de seguridad encriptado
		SET @ID_Estudiante = 0
		SELECT @ID_Estudiante = ID_Estudiante
		FROM Estudiante
		WHERE @CodigoEstudiante = Codigo_Estudiante and @ApellidosSegun = Segundo_Apelldo and @CodigoSegur = Codigo_Seguridad

		IF(@ID_Estudiante > 0)
		BEGIN			
			--Logica de asignacion
			/* 1. A partir del CSV obtenemos el curso, con el curso, obtenemos el ID del tipo que pertence (Tecnico o Admin)
			   2. Con ese ID comparamos si es tecnico o admin
			   3. Ya comparado, realizamos un inner join entre seccion y curso para ver las secciones del curso seleccionado.
			   4. (Para tecnico) El primer if devuelve dos registros, esos 2 registros son las secciones, tomamos el primer registro (seccion 1)
			   y se toma el cupo, se hace un COUNT de tx_Asignacion en donde como condicion los registros tengan estado completado y contengan el
			   ID de la seecion
			   5. verificar que el cupo sea mayor que el resultado del count, si es mayor se inserta (hasta abajo) en tx_Asignacion, si el cupo no es mayor
			   al count, se verifica el cupo de la segunda seccion. 
			   6. Crear dos funciones (1 para el promedio) si el curso no tiene prerrequisito, se manda a llamar a la funcion que recibe como parametro
			   el ID de la seccion y el ID del curso (dentro de la funcion se debe crear una variable decimal llamada promedio y una variable entera
			   que se llame contador)
			   7. Dentro de esa funcion crear un cursor que recorra tx_Asignacion, para todos los registros que pertenecen a esa seccion y que tiene
			   estado aprobado.
			   8. Por cada registro encontrado de tx_Asognacion hacer un inner join con la tabla estudiante para obtener la info del estudiante
			   9. con el registro encontrado en la tabla estudiante hacer un inner join con la tabla historial cursos donde el ID_Curso sea igual
			   al curso que se envio como parametro
			   10. el registro encontrado tomar el atributo nota y sumarselo a promedio
			   11. Incrementar contador
			   12. al finalizar el cursor retornar promedio/contador
			   13. Al obtener el promedio comparado su valor con 
			   
			*/



		END
		ELSE
		BEGIN
			print('Datos incorrectos o estudiante no encontrado.')
		END

		--Insertar valores a tabla tx_asignacion
		INSERT INTO tx_Asignacion (Fecha_Creacion, Fecha_Asignacion, Estudiante, Seccion, Estado)
		VALUES (@Fecha_CreacionTX, @Fecha_AsignacionTX, @ID_Estudiante, @SeccionTX, @EstadoTX)

		END TRY

		BEGIN CATCH

		END CATCH
		
	fetch next from cDatosAsign into @CodigoEstudiante, @ApellidosSegun, @CodigoSegur, @CursoAsign
	end
	close cDatosAsign;
	deallocate cDatosAsign;

	if @@TRANCOUNT  > 0
		COMMIT TRAN;

	print 'Proceso finalizado exitosamente.'
END;