create database Asignaciones_Universidad
go
use Asignaciones_Universidad
go
--Conectada a tx_Asignacion e Historial_Cursos
create table Estudiante(
ID_Estudiante int IDENTITY(1,1) not null,
Codigo_Seguridad int not null,
Nombre varchar(40) not null,
Codigo_Estudiante int not null,
Primer_Apellido varchar(40) not null,
Segundo_Apelldo varchar(40) not null,
primary key (ID_Estudiante)
);
--
create table Historial_Cursos(
ID_HistorialCurso int IDENTITY
);