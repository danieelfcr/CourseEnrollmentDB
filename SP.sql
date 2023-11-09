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