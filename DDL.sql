create database Asignaciones_Universidad
go
use Asignaciones_Universidad
go
--Conectada a tx_Asignacion e Historial_Cursos
create table Estudiante(
ID_Estudiante int PRIMARY KEY IDENTITY(1,1) not null,
Codigo_Seguridad varchar(70) not null,
Nombre varchar(70) not null,
Codigo_Estudiante varchar(8) not null,
Primer_Apellido varchar(70) not null,
Segundo_Apellido varchar(70) not null
);

--Conectada a Curso
create Table Tipo(
ID_Tipo int PRIMARY KEY IDENTITY(1,1) not null,
Cantidad_Seccion int not null,
Nombre varchar(20) not null
);

--Conectada a Seccion, Prerrequisito, Tipo e Historial_Curso
Create Table Curso(
ID_Curso int PRIMARY KEY IDENTITY(1,1) not null,
Nombre varchar(70) not null,
Tipo int not null
constraint pk_tipo foreign key (Tipo) references Tipo (ID_Tipo)
);

--Conectada a Estudiate y Curso
create Table Historial_Cursos(
ID_HistorialCurso int PRIMARY KEY IDENTITY(1,1) not null,
Nota int not null,
Estudiante int not null,
Curso int not null
constraint pk_estudiante foreign key (Estudiante) references Estudiante (ID_Estudiante),
constraint pk_curso foreign key (Curso) references Curso(ID_Curso)
);
--Conectada a tx_Asignacion y Curso
Create Table Seccion(
ID_Seccion int PRIMARY KEY IDENTITY(1,1) not null,
ID_Curso int,
Cupo int not null,
Numero_Seccion int not null
constraint pk_curso_s foreign key (ID_Curso) references Curso(ID_Curso)
);

--Conectado a tx_Asignacion
-- 0 = Rechazado, 1 = Aprobado, 2 = Lista de espera, 3 = Cambio de seccion, 4 = No se encontraron los datos el estudiante
create Table Estado_Asignacion(
ID_Estado_Asignacion int PRIMARY KEY IDENTITY(0,1) not null,
Descripcion  varchar(100) not null,
Nombre varchar(70) not null
);

--Conectada a Estudiante, Estado_Asignacion y Seccion 
create Table tx_Asignacion(
ID_Asignacion int PRIMARY KEY IDENTITY(1,1) not null,
Fecha_Creacion datetime not null,
Fecha_Asignacion datetime,
Estudiante int not null,
Seccion int not null,
Estado int not null
constraint pk_estudiante_a foreign key (Estudiante) references Estudiante (ID_Estudiante),
constraint pk_seccion_a foreign key (Seccion) references Seccion (ID_Seccion),
constraint pk_tipo_a foreign key (Estado) references Estado_Asignacion(ID_Estado_Asignacion)
);

create Table Prerrequisito(
ID_Prerrequisito int PRIMARY KEY IDENTITY(1,1) not null,
Curso int not null,
Prerrequisito int not null,
Estado bit not null
constraint pk_curso_pp foreign key (Curso) references Curso (ID_Curso),
constraint pk_curso_prerequisto foreign key (Prerrequisito) references Curso (ID_Curso)
);

