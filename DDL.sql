create database Asignaciones_Universidad
go
use Asignaciones_Universidad
go
--Conectada a tx_Asignacion e Historial_Cursos
create table Estudiante(
ID_Estudiante int PRIMARY KEY IDENTITY(1,1) not null,
Codigo_Seguridad varchar(20) not null,
Nombre varchar(20) not null,
Codigo_Estudiante varchar(8) not null,
Primer_Apellido varchar(20) not null,
Segundo_Apelldo varchar(20) not null
);
--Conectada a Estudiate y Curso
create Table Historial_Cursos(
ID_HistorialCurso int PRIMARY KEY IDENTITY(1,1) not null,
Nota int not null
);
--Conectada a Estudiante, Estado_Asignacion y Seccion 
create Table tx_Asignacion(
ID_Asignacion int PRIMARY KEY IDENTITY(1,1) not null,
Fecha_Creacion datetime not null,
Fecha_Asignacion datetime not null
);
--Conectado a tx_Asignacion
create Table Estado_Asignacion(
ID_Estado_Asignacion int PRIMARY KEY IDENTITY(1,1) not null,
Descripcion  varchar(100) not null,
Nombre varchar(20) not null
);
--Conectada a tx_Asignacion y Curso
Create Table Seccion(
ID_Seccion int PRIMARY KEY IDENTITY(1,1) not null,
Cupo varchar(20) not null
);
--Conectada a Seccion, Prerrequisito, Tipo e Historial_Curso
Create Table Curso(
ID_Curso int PRIMARY KEY IDENTITY(1,1) not null,
Nombre varchar(20) not null
);
--Conectada a Curso
create Table Tipo(
ID_Tipo int PRIMARY KEY IDENTITY(1,1) not null,
Cantidad_Seccion int not null,
Nombre varchar(20) not null
);
--(Pendiente) Conectada a Curso y Prerrequisito
create Table Curso_Prerrequisito(
ID_Curso_Prerrequisito int PRIMARY KEY IDENTITY(1,1) not null
);
--(Pendiente) Conectada a Curso
create Table Prerrequisito(
ID_Prerrequisito int PRIMARY KEY IDENTITY(1,1) not null
);
