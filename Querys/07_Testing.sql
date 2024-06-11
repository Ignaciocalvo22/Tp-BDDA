-------------------------INSERTAR:-----------------------------

--Insertar Paciente:
EXEC Clinica.Insertar_Paciente 'Juan', 'Perez', 'Gomez', '1990-01-01', 'DNI', '12345678', 'M', 'Masculino', 'Argentino', 'foto.jpg', 'nacho@nacho', '123456789', '123456789', '123456789', '2021-06-01', 'nacho'



EXEC Clinica.Insertar_Usuario 1, '1234';


--Insertar Estudio
EXEC Clinica.Insertar_Estudio 1, '2021-06-01', 'Estudio1', 1, 'doc.pdf', 'img.jpg';

--Insertar Cobertura:
EXEC Clinica.Insertar_Cobertura 'img.jpg', '123456', '2021-06-01';

--Insertar Prestador:

EXEC Clinica.Insertar_Prestador 'OSDE','Osde 660';

--Insertar Direccion:

EXEC Clinica.Insertar_Domicilio 'Rivadavia','12500',NULL,null,'1684','Argentina','Buenos Aires','Haedo',;

--Insertar Reserva Turno Medico:
EXEC Reserva_Turno_Medico '2021-06-01','10:00';

--Insertar Estado Turno:

EXEC Clinica.Insertar_Estado_Turno 'Atendido';
EXEC Clinica.Insertar_Estado_Turno 'Ausente';
EXEC Clinica.Insertar_Estado_Turno 'Cancelado';

--Insertar Tipo Turno:

EXEC Clinica.Insertar_Tipo_Turno 'Presencial';
EXEC Clinica.Insertar_Tipo_Turno 'Virtual';

--Insertar_Dias_Por_Sede:

EXEC Clinica.Insertar_Dias_Por_Sede 'Lunes','10:00';

--Insertar Medico:

EXEC Clinica.Insertar_Medico 'Ignacio','Calvo','112233'


--Insertar Especialidad:
EXEC Clinica.Insertar_Especialidad 'Otorrinolaringologia';

--Insertar Sede:
EXEC Clinica.Insertar_Sede_De_Atencion 'Haedo','Rivadavia 12500'


-------------------------ELIMINAR:-----------------------------

--Crea para testear todos los SP de los de eliminar:
--Eliminar Paciente

USE Com2900G03;

EXEC clinicaEliminar.Eliminar_Paciente 1;

Select * FROM
clinica.Paciente; --No existe mas el paciente con Id_Historia_Clinica = 1

--Eliminar Usuario
EXEC clinicaEliminar.Eliminar_Usuario 1;

SELECT * FROM
clinica.Usuario; --No existe mas el usuario con Id_Usuario = 1

--Eliminar Estudio
EXEC clinicaEliminar.Eliminar_Estudio '64d3c5eb9d266b60542baeb0'

SELECT * FROM
clinica.Tipo_Estudio; --No existe mas el estudio con Id_Estudio = 1

--Eliminar Turno:

EXEC clinicaEliminar.Eliminar_Reserva_Turno_Medico 1;

SELECT * FROM
clinica.Reserva_Turno_Medico; --No existe mas el turno con Id_Turno = 1

--Eliminar Medico:
EXEC clinicaEliminar.Eliminar_Medico 1;

SELECT * FROM
clinica.Medico; --No existe mas el medico con Id_Medico = 1

--Eliminar Especialidad:
EXEC clinicaEliminar.Eliminar_Especialidad 1;

SELECT * FROM
clinica.Especialidad; --No existe mas la especialidad con Id_Especialidad = 1

--Eliminar Sede:
EXEC clinicaEliminar.Eliminar_Sede_De_Atencion 1;

SELECT * FROM
clinica.Sede_De_Atencion; --No existe mas la sede con Id_Sede = 1

--Eliminar Tipo Turno:
EXEC clinicaEliminar.Eliminar_Tipo_Turno 1;

SELECT * FROM
clinica.Tipo_Turno; --No existe mas el tipo de turno con Id_Tipo_Turno = 1

--Eliminar Dias Por Sede:
EXEC clinicaEliminar.Eliminar_Dias_Por_Sede 1;

SELECT * FROM
clinica.Dias_Por_Sede; --No existe mas los dias por sede con Id_Sede = 1

--Eliminar Historia Clinica:
EXEC clinicaEliminar.Eliminar_Historia_Clinica 1;




