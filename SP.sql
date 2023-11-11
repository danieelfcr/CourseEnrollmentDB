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
	declare @vCodigoEstudiante varchar(20),
			@vSegundoApellido varchar(20),
			@vCodigoSeguridad varchar(20),
			@vCursoAsignacion varchar(20),
			@vID_Estudiante int,
			@vFecha_CreacionTX datetime,
			@vFecha_AsignacionTX datetime,
			@vSeccionTX int,
			@vEstadoTX int,
			@vSeccionTec1 int,
			@vSeccionTec2 int,
			@vSeccionAdmin int,
			@vCupoAdmin int,
			@vCupoTec1 int,
			@vCupoTec2 int,
			@vPromedioMenor float,
			@vPromedioActual float,
			@vEstudianteMenor int

	Declare cDatosAsign cursor for
	select Codigo_Estudiante, Segundo_Apellido, Codigo_Seguridad, Curso_Asignar
	from #tIngreso_Estudiantes

	open cDatosAsign;
	fetch next from cDatosAsign into @vCodigoEstudiante, @vSegundoApellido, @vCodigoSeguridad, @vCursoAsignacion
	
	WHILE @@FETCH_STATUS = 0
    BEGIN
		BEGIN TRY
		--Obtener fecha-tiempo actual para Fecha_Creacion
		set @vFecha_CreacionTX = GETDATE()

		-- 1. Comprobacion de datos: codigo estudiante, apellido y codigo de seguridad encriptado
		SET @vID_Estudiante = 0
		SELECT @vID_Estudiante = e.ID_Estudiante
		FROM Estudiante e
		WHERE @vCodigoEstudiante = e.Codigo_Estudiante and @vSegundoApellido = e.Segundo_Apelldo and @vCodigoSeguridad = e.Codigo_Seguridad

		-- 2. selección del curso
		IF(@vID_Estudiante > 0)
		BEGIN		
			IF ((SELECT COUNT(*) FROM Seccion s inner join Curso c on (c.ID_Curso = s.ID_Curso)) >= 2)
			BEGIN
				-- curso es de tipo tecnico
				-- Se toma la información de la primera sección del curso
				select TOP 1 @vSeccionTec1 = s.ID_Seccion, @vCupoTec1 = s.Cupo
				from Seccion s
				where s.ID_Curso = @vCursoAsignacion

				-- Se toma la información de la segunda sección del curso
				select TOP 1 @vSeccionTec2 = s.ID_Seccion, @vCupoTec2 = s.Cupo 
				from Seccion s
				where s.ID_Curso = @vCursoAsignacion
				ORDER BY s.ID_Seccion OFFSET 1 ROW
				FETCH NEXT 1 ROW ONLY;

				if ((select count(1) from Prerrequisito cp where cp.Curso = @vCursoAsignacion and cp.Estado = 1) > 0)
				BEGIN
					if(dbo.fncEstudianteCumplePrerrequisitos = 1)
					begin
						-- Verificar que hay cupos disponibles en la primera sección
						if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec1) < @vCupoTec1)
						begin
							--set @SeccionTX = @vSeccionAdmin
							set @SeccionTX = @vSeccionTec1
							set @EstadoTx = 1
							set @vFecha_AsignacionTX = GETDATE()	
						end
						else
						begin
							WITH PromedioNotasPorEstudiante AS (
							SELECT h.Estudiante, AVG(CAST(h.Nota AS FLOAT)) AS PromedioNotas
							FROM Historial_Cursos h
							join Prerrequisito p on h.Curso = p.Prerrequisito
							WHERE EXISTS (
								SELECT 1
								FROM tx_Asignacion a
								JOIN Seccion s ON a.Seccion = s.ID_Seccion
								WHERE	a.Estudiante = h.Estudiante	AND s.ID_Curso = @vCursoAsignacion
								)
							and p.Curso = @vCursoAsignacion
							GROUP BY h.Estudiante
							)

							SELECT TOP 1 @vPromedioMenor = p.PromedioNotas, @vEstudianteMenor = p.Estudiante
							FROM	PromedioNotasPorEstudiante p
							ORDER BY p.PromedioNotas ASC;

							SELECT @PromedioActual = AVG(CAST(Nota AS FLOAT))
							FROM Historial_Cursos h
							join Prerrequisito p on h.Curso = p.Prerrequisito
							WHERE Estudiante = @ID_Estudiante and p.Curso = @vCursoAsignacion

							if(@PromedioActual <= @PromedioMenor)
							begin
								if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec2) < @vCupoTec2)
								begin
									set @SeccionTX = @vSeccionTec2
									set @EstadoTx = 1
									set @vFecha_AsignacionTX = GETDATE()
								end
								else
								begin
									set @SeccionTX = @vSeccionTec2
									set @EstadoTx = 2
								end
							end
							else
							begin
								if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec2) < @vCupoTec2)
								begin
									update tx_Asignacion
											set Estado = 3
											Seccion = @vSeccionTec2
											Fecha_Asignacion = GETDATE()
										where Estudiante = @vEstudianteMenor

										set @SeccionTX = @vSeccionTec1
										set @EstadoTx = 1
										set @vFecha_AsignacionTX = GETDATE()
								end
								else
								begin
									update tx_Asignacion
									set Estado = 2
										Seccion = @vSeccionTec2
										Fecha_Asignacion = null
									where Estudiante = @vEstudianteMenor

									set @SeccionTX = @vSeccionTec1
									set @EstadoTx = 1
									set @vFecha_AsignacionTX = GETDATE()
								end
							end



						end
					end
					else
					begin
						set @vEstadoTx = 0
					end
				END
				ELSE
				BEGIN
					if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec1) < @vCupoTec1)
					begin
						set @SeccionTX = @vSeccionAdmin
						set @EstadoTx = 1
						set @vFecha_AsignacionTX = GETDATE()	
					end
					else
					begin
						WITH PromedioNotasPorEstudiante AS (
						SELECT h.Estudiante, AVG(CAST(h.Nota AS FLOAT)) AS PromedioNotas
						FROM Historial_Cursos h
						WHERE EXISTS (
							SELECT 1
							FROM tx_Asignacion a
							JOIN Seccion s ON a.Seccion = s.ID_Seccion
							WHERE	a.Estudiante = h.Estudiante	AND s.ID_Curso = @vCursoAsignacion
							)
						GROUP BY h.Estudiante
						)

						SELECT TOP 1 @vPromedioMenor = p.PromedioNotas, @vEstudianteMenor = p.Estudiante
						FROM	PromedioNotasPorEstudiante p
						ORDER BY p.PromedioNotas ASC;

						SELECT @PromedioActual = AVG(CAST(Nota AS FLOAT))
						FROM Historial_Cursos
						WHERE Estudiante = @ID_Estudiante;

						if(@PromedioActual <= @PromedioMenor)
						begin
							if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec2) < @vCupoTec2)
							begin
								set @SeccionTX = @vSeccionTec2
								set @EstadoTx = 1
								set @vFecha_AsignacionTX = GETDATE()
							end
							else
							begin
								set @SeccionTX = @vSeccionTec2
								set @EstadoTx = 2
							end
						end
						else
						begin
							if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec2) < @vCupoTec2)
							begin
								update tx_Asignacion
										set Estado = 3
										Seccion = @vSeccionTec2
										Fecha_Asignacion = GETDATE()
									where Estudiante = @vEstudianteMenor

									set @SeccionTX = @vSeccionTec1
									set @EstadoTx = 1
									set @vFecha_AsignacionTX = GETDATE()
							end
							else
							begin
								update tx_Asignacion
								set Estado = 2
									Seccion = @vSeccionTec2
									Fecha_Asignacion = null
								where Estudiante = @vEstudianteMenor

								set @SeccionTX = @vSeccionTec1
								set @EstadoTx = 1
								set @vFecha_AsignacionTX = GETDATE()
							end
						end
					end
				end
			END
			ELSE
			BEGIN 
			-- curso es de tipo administrativo
				select @vSeccionAdmin = s.ID_Seccion, @vCupoAdmin = s.Cupo  
				from Seccion s
				where s.ID_Curso = @vCursoAsignacion

				if ((select count(1) from Prerrequisito cp where cp.Curso = @vCursoAsignacion and cp.Estado = 1) > 0)
				begin
					if(dbo.fncEstudianteCumplePrerrequisitos = 1)
					begin
						if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionAdmin) = @vCupoAdmin)
						begin
							set @SeccionTX = @vSeccionAdmin
							set @EstadoTx = 2
						end
						else
						begin
							set @SeccionTX = @vSeccionAdmin
							set @EstadoTx = 1
							set @vFecha_AsignacionTX = GETDATE()
						end
					end
					else
					begin
						set @EstadoTx = 0
					end
				end
				else
				begin
					if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionAdmin) = @vCupoAdmin)
					begin
						set @SeccionTX = @vSeccionAdmin
						set @EstadoTx = 2
					end
					else
					begin
						set @SeccionTX = @vSeccionAdmin
						set @EstadoTx = 1
						set @vFecha_AsignacionTX = GETDATE()
					end
				end
			END

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
		
	fetch next from cDatosAsign into @CodigoEstudiante, @vSegundoApellido, @vCodigoSeguridad, @vCursoAsignacion
	end
	close cDatosAsign;
	deallocate cDatosAsign;

	if @@TRANCOUNT  > 0
		COMMIT TRAN;

	print 'Proceso finalizado exitosamente.'
END;