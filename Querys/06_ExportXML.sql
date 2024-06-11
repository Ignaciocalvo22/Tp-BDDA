CREATE OR ALTER FUNCTION clinica.Turnos_atendidos
@Nombre_Obra_Social VARCHAR(50),
@Fecha_Desde DATE,
@Fecha_Hasta DATE
AS
BEGIN

SET @XML = 
(
SELECT 
    P.Apellido,
    P.Nombre,
    P.DNI,
    M.Nombre AS Nombre_Medico,
    M.Matricula,
    T.Fecha,
    T.Hora,
    E.Descripcion AS Especialidad
FROM clinica.Reserva_Turno_Medico T
LEFT JOIN clinica.Paciente P 
ON T.Id_Paciente = P.Id_Paciente
LEFT JOIN clinica.Medico M 
ON T.Id_Medico = M.Id_Medico
LEFT JOIN clinica.Especialidad E 
ON M.Id_Especialidad = E.Id_Especialidad
WHERE P.Id_Cobertura = (SELECT Id_Cobertura FROM clinica.Prestador WHERE Nombre = @Nombre_Obra_Social)
AND T.Fecha BETWEEN @Fecha_Desde AND @Fecha_Hasta
)
RETURN @XML

END

