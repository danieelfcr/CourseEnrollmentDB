CREATE PROCEDURE uspCambioCupos
	@vID_Seccion int,
	@vNuevoCupo int
AS
BEGIN
	BEGIN TRAN
	BEGIN TRY
		update Seccion
		set Cupo = @vNuevoCupo
		where ID_Seccion = @vID_Seccion and Cupo < @vNuevoCupo
		COMMIT TRAN 
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
	END CATCH
END;