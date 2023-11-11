CREATE PROCEDURE uspUploadData  --Nombre del SP
AS
BEGIN
	SET NOCOUNT ON; --No muestra las filas aceptadas	
	SET TRAN ISOLATION LEVEL READ UNCOMMITTED	/*Nivel de aislamiento READ UNCOMMITED para realizar cambios en cupo mientras
	mientras se realiza la transaccion*/

	--Creacion tabla temporal para guardar contenido de CSV
	create table #tIngreso_Estudiantes(
	Codigo_Estudiante varchar(20) not null,
	Segundo_Apellido varchar(20) not null,
	Codigo_Seguridad varchar(20) not null,
	Curso_Asignar varchar(20) not null
)
begin try 
	--Insertar data de CSV a tabla
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
	
	--Recorrer tabla temporal con cursor
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
				ORDER BY s.ID_Seccion OFFSET 1 ROW	-- Tomar el segundo resultado con este comando
				FETCH NEXT 1 ROW ONLY;

				--Verificar que existan prerrequisitos en la tabla
				if ((select count(1) from Prerrequisito cp where cp.Curso = @vCursoAsignacion and cp.Estado = 1) > 0)
				BEGIN
					--Verificar que estudiante cumpla prerrequisitos
					if(dbo.fncEstudianteCumplePrerrequisitos(@vCursoAsignacion, @vID_Estudiante) = 1)
					begin
						-- Verificar que hay cupos disponibles en la primera sección
						if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec1) < @vCupoTec1)
						begin
							--set @SeccionTX = @vSeccionAdmin
							set @vSeccionTX = @vSeccionTec1
							set @vEstadoTx = 1
							set @vFecha_AsignacionTX = GETDATE()	--Se asignó, por lo que se inserta la fecha asignación
						end
						else
						--Si no hay cupos disponibles en la primera seccion
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

							--Tomar al estudiante con promedio menor de seccion 1
							SELECT TOP 1 @vPromedioMenor = p.PromedioNotas, @vEstudianteMenor = p.Estudiante
							FROM	PromedioNotasPorEstudiante p
							ORDER BY p.PromedioNotas ASC;

							--Calcular promedio actual del estudiante intentando asignarse
							SELECT @vPromedioActual = AVG(CAST(Nota AS FLOAT))
							FROM Historial_Cursos h
							join Prerrequisito p on h.Curso = p.Prerrequisito
							WHERE Estudiante = @vID_Estudiante and p.Curso = @vCursoAsignacion

							--Si promedio actual es menor a promedio menor, asignar a seccion 2
							if(@vPromedioActual <= @vPromedioMenor)
							begin
								if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec2) < @vCupoTec2)
								begin
									set @vSeccionTX = @vSeccionTec2
									set @vEstadoTx = 1
									set @vFecha_AsignacionTX = GETDATE()
								end
								else
								begin
									--Si no hay cupo en seccion 2, mandar a lista de espera (Estado 2)
									set @vSeccionTX = @vSeccionTec2
									set @vEstadoTx = 2
								end
							end
							else
							begin
							--Si promedio actual es mayor a promedio menor, realizar intercambio
								--Comprobar que exista cupo en seccion 2
								if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec2) < @vCupoTec2)
								begin
									update tx_Asignacion
											set Estado = 3,
											Seccion = @vSeccionTec2,
											Fecha_Asignacion = GETDATE()
										where Estudiante = @vEstudianteMenor

										set @vSeccionTX = @vSeccionTec1
										set @vEstadoTx = 1
										set @vFecha_AsignacionTX = GETDATE()
								end
								else
								begin
								--Si no hay cupo en seccion 2, mandar al de menor promedio a lista de espera y asignar al mayor a seccion 1
									update tx_Asignacion
									set Estado = 2,
										Seccion = @vSeccionTec2,
										Fecha_Asignacion = null
									where Estudiante = @vEstudianteMenor

									set @vSeccionTX = @vSeccionTec1
									set @vEstadoTx = 1
									set @vFecha_AsignacionTX = GETDATE()
								end
							end
						end
					end
					else
					begin
					--Si estudiante no cumple prerrequisitos, el estado asignacion sera rechazado
						set @vEstadoTx = 0
					end
				END
				--Si no existen prerrequisitos
				ELSE
				BEGIN
					--Verificar si hay cupo en la seccion 1
					if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec1) < @vCupoTec1)
					begin
						--Si hay cupo, asignar a seccion 1
						set @vSeccionTX = @vSeccionAdmin
						set @vEstadoTx = 1
						set @vFecha_AsignacionTX = GETDATE()	
					end
					--Si no hay cupo en la seccion 1, probar con la seccion 2
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

						--Seleccionar al estudiante en seccion 1 con el menor promedio
						SELECT TOP 1 @vPromedioMenor = p.PromedioNotas, @vEstudianteMenor = p.Estudiante
						FROM	PromedioNotasPorEstudiante p
						ORDER BY p.PromedioNotas ASC;

						--Obtener promedio actual de estudiante intentando asignarse
						SELECT @vPromedioActual = AVG(CAST(Nota AS FLOAT))
						FROM Historial_Cursos
						WHERE Estudiante = @vID_Estudiante;

						if(@vPromedioActual <= @vPromedioMenor)
						--Si promedio actual es menor o igual al promedio menor
						begin
							if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec2) < @vCupoTec2)
							begin
								--Si hay cupo en la seccion 2, asignarlo
								set @vSeccionTX = @vSeccionTec2
								set @vEstadoTx = 1
								set @vFecha_AsignacionTX = GETDATE()
							end
							else
							begin
								--Si no hay cupo, mandarlo a lista de espera
								set @vSeccionTX = @vSeccionTec2
								set @vEstadoTx = 2
							end
						end
						else
						--Si promedio actual es mayor al promedio menor
						begin
							if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionTec2) < @vCupoTec2)
							begin
							--Si hay cupo en seccion 2, realizar intercambio de seccion
								update tx_Asignacion
										set Estado = 3,
										Seccion = @vSeccionTec2,
										Fecha_Asignacion = GETDATE()
									where Estudiante = @vEstudianteMenor

									set @vSeccionTX = @vSeccionTec1
									set @vEstadoTx = 1
									set @vFecha_AsignacionTX = GETDATE()
							end
							else
							--Si no hay cupo en seccion 2, promedio menor a lista de espera y asignar al otro estudiante a sec 1
							begin
								update tx_Asignacion
								set Estado = 2,
									Seccion = @vSeccionTec2,
									Fecha_Asignacion = null
								where Estudiante = @vEstudianteMenor

								set @vSeccionTX = @vSeccionTec1
								set @vEstadoTx = 1
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

				--Verificar si existen prerrequisitos
				if ((select count(1) from Prerrequisito cp where cp.Curso = @vCursoAsignacion and cp.Estado = 1) > 0)
				begin
					--Verificar que estudiante cumpla con prerrequisitos
					if(dbo.fncEstudianteCumplePrerrequisitos(@vCursoAsignacion, @vID_Estudiante) = 1)
					begin
						--Verificar que exista cupo
						if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionAdmin) = @vCupoAdmin)
						begin
							--Si el cupo esta lleno, mandar a lista de espera
							set @vSeccionTX = @vSeccionAdmin
							set @vEstadoTx = 2
						end
						else
						begin
							--Si hay cupo, asignar
							set @vSeccionTX = @vSeccionAdmin
							set @vEstadoTx = 1
							set @vFecha_AsignacionTX = GETDATE()
						end
					end
					else
					begin
						--Si estudiante no cumple prerrequisito, rechazar
						set @vEstadoTx = 0
					end
				end
				else
				--Si no existen prerrequisitos
				begin
					--Comprobar que aun exista cupo
					if(dbo.fncObtenerCantidadEstudiantesSeccion(@vSeccionAdmin) = @vCupoAdmin)
					begin
						--Si ya no hay cupo, mandar a lista de espera
						set @vSeccionTX = @vSeccionAdmin
						set @vEstadoTx = 2
					end
					else
					begin
						--Si hay cupo, asignar
						set @vSeccionTX = @vSeccionAdmin
						set @vEstadoTx = 1
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
		VALUES (@vFecha_CreacionTX, @vFecha_AsignacionTX, @vID_Estudiante, @vSeccionTX, @vEstadoTX)

		END TRY

		BEGIN CATCH
			print('Ha ocurrido un error en el proceso')
		END CATCH
		
	fetch next from cDatosAsign into @CodigoEstudiante, @vSegundoApellido, @vCodigoSeguridad, @vCursoAsignacion
	end
	close cDatosAsign;
	deallocate cDatosAsign;

	if @@TRANCOUNT  > 0
		COMMIT TRAN;

	print 'Proceso finalizado exitosamente.'
END;