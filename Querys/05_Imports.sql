--Importa CSV Medico:

CREATE OR ALTER PROCEDURE Clinica.importarMedicos
@rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX)

    --Chequeamos si la tabla temporal existe, si existe la borramos
    DROP TABLE IF EXISTS clinica.#tempMedico
    CREATE TABLE clinica.#tempMedico
    (
        apellido VARCHAR(30),
        nombre VARCHAR(30),
        especialidad VARCHAR(30),
        colegiado INT NOT NULL
    )
	--Corro el BULK del import
	DECLARE @ImportMedicos NVARCHAR(MAX)
	SET @ImportMedicos = 
    'BULK INSERT clinica.#tempMedico ' +
    'FROM ''' + @rutaArchivo + ''' ' +
    'WITH ( ' +
    '    FIELDTERMINATOR = '';'', ' +
    '    ROWTERMINATOR = ''\n'', ' +
    '    FIRSTROW = 2, ' +
    '    CODEPAGE = ''65001''' +
    ')'

   EXEC sp_executesql @ImportMedicos

-- Limpio los datos:

--Quito el Dr. y Dra. de los nombres:
    UPDATE clinica.#tempMedico
    SET apellido = REPLACE(apellido, 'Dra. ', '')

    UPDATE clinica.#tempMedico
    SET apellido = REPLACE(apellido, 'Dr. ', '')


--Cargo la tabla especialidad:

INSERT INTO clinica.Especialidad
(
    Nombre_Especialidad
)
SELECT distinct
    especialidad
FROM clinica.#tempMedico
WHERE especialidad NOT IN (SELECT Nombre_Especialidad FROM clinica.Especialidad)


--Updateo tabla clinica medico en caso de que el registro ya exista:
UPDATE clinica.Medico 
SET
    Nombre = a.Nombre,
    Apellido = a.Apellido,
    Id_Especialidad = e.Id_Especialidad
FROM clinica.#tempMedico a
LEFT JOIN clinica.Especialidad e ON a.especialidad = e.Nombre_Especialidad
WHERE clinica.Medico.Nro_Matricula = a.colegiado
--Quiero que updatee si hay algo diferente solamente
AND
(
    clinica.Medico.Nombre != a.Nombre
    OR clinica.Medico.Apellido != a.Apellido
    OR clinica.Medico.Id_Especialidad != e.Id_Especialidad

)

--Inserto los datos en la tabla final:
INSERT INTO clinica.Medico
(
    Nombre,
    Apellido,
    Nro_Matricula,
    Id_Especialidad
)
SELECT
     A.Nombre
    ,A.Apellido
    ,A.colegiado
    ,E.Id_Especialidad
FROM clinica.#tempMedico A
LEFT JOIN Clinica.Especialidad e ON a.especialidad = e.Nombre_Especialidad
WHERE colegiado NOT IN (SELECT Nro_Matricula FROM clinica.Medico)


--Limpio la tabla temporal
DROP TABLE clinica.#tempMedico

END

--Importa CSV Pacientes:


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'clinicaImportar')
    EXEC('CREATE SCHEMA clinicaImportar')
GO

DROP PROCEDURE IF EXISTS clinicaImportar.ImportarPacientes;
GO

--Funcion para capitalizar strings
DROP FUNCTION IF EXISTS [Clinica].[InitCap] 
GO

CREATE FUNCTION [Clinica].[InitCap] 
( 
    @InputString varchar(4000)
) 
RETURNS VARCHAR(4000)
AS
BEGIN

    DECLARE @Index          INT
    DECLARE @Char           CHAR(1)
    DECLARE @PrevChar       CHAR(1)
    DECLARE @OutputString   VARCHAR(255)

    SET @OutputString = LOWER(@InputString)
    SET @Index = 1

    WHILE @Index <= LEN(@InputString)
    BEGIN
        SET @Char     = SUBSTRING(@InputString, @Index, 1)
        SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
        ELSE SUBSTRING(@InputString, @Index - 1, 1)
    END

    IF @PrevChar IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
    BEGIN
        IF @PrevChar != '''' OR UPPER(@Char) != 'S'
        SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char))
    END
        SET @Index = @Index + 1
    END

    RETURN @OutputString
END
GO

DROP FUNCTION IF EXISTS [Clinica].[getFinalNumber]
GO

CREATE FUNCTION [Clinica].[getFinalNumber] 
( 
    @str varchar(100)
)
RETURNS varchar(100)
AS
BEGIN
    DECLARE @result varchar(100)
	SET @str = TRIM(@str)
    SET @result = RIGHT(@str, patindex('%[^0-9]%', REVERSE(@str))-1)
    RETURN @result
END
GO

DROP FUNCTION IF EXISTS [Clinica].[getFirstString]
GO

CREATE FUNCTION [Clinica].[getFirstString] 
( 
    @str varchar(100)
)
RETURNS varchar(100)
AS
BEGIN
    DECLARE @result varchar(100)
	DECLARE @index int
	SET @index = patindex('%[0-9]%', @str)
	SET @str = TRIM(@str)
	IF @index < 1
	BEGIN
		set @index = 1
	END
    SET @result = left(@str, @index -1)
    RETURN @result
END
GO

-- Importar los pacientes desde un archivo CSV

DROP PROCEDURE IF EXISTS Clinica.ImportarPacientes
GO

CREATE PROCEDURE Clinica.ImportarPacientes
   @rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    --DECLARE @rutaArchivo NVARCHAR(MAX)
    --SET @rutaArchivo = 'C:\Users\fede0\Desktop\BDDA\Tp-BDDA\Tp-BDDA\Dataset\Pacientes.csv'
    DECLARE @sql NVARCHAR(MAX)

    -- 1. Crear la tabla temporal
    DROP TABLE IF EXISTS Clinica.PacienteTemporal
    CREATE TABLE Clinica.PacienteTemporal
    (
        Nombre VARCHAR(50),
        Apellido VARCHAR(50),
        Fecha_Nacimiento VARCHAR(15) NOT NULL,
        Tipo_Documento VARCHAR(10) NOT NULL,
        DNI INT NOT NULL,
        Sexo VARCHAR(9) NOT NULL CHECK (Sexo IN ('Masculino', 'Femenino')),
        Genero VARCHAR(10) NOT NULL,
        Telefono VARCHAR(20) NOT NULL,
        Nacionalidad VARCHAR(50) NOT NULL,
        Email VARCHAR(50)  NOT NULL,
        Direccion VARCHAR(100),
        Localidad VARCHAR(75),
        Provincia VARCHAR(57),
    );

	DROP TABLE IF EXISTS Clinica.DomicilioTemporal
    CREATE TABLE Clinica.DomicilioTemporal
    (
        Id_Domicilio INT IDENTITY(1,1) PRIMARY KEY,
        Direccion VARCHAR(100),
        Calle VARCHAR(50),
        Numero VARCHAR(50),
        Piso VARCHAR(50),
        Departamento VARCHAR(50),
        Codigo_Postal VARCHAR(50),
        Pais VARCHAR(50),
        Provincia VARCHAR(50),
        Localidad VARCHAR(50),
    );

    -- 2. Importar los datos del archivo CSV

    DECLARE @ImportPacientes NVARCHAR(MAX)
    SET @ImportPacientes =
    'BULK INSERT clinica.PacienteTemporal ' +
    'FROM ''' + @rutaArchivo + ''' ' +
    'WITH ( ' +
    '    FIELDTERMINATOR = '';'', ' +
    '    ROWTERMINATOR = ''\n'', ' +
    '    FIRSTROW = 2, ' +
    '    CODEPAGE = ''65001''' +
    ')'

    EXEC sp_executesql @ImportPacientes
    
    -- Limpiar los datos:
    UPDATE Clinica.PacienteTemporal
    SET Nombre = Nombre,
        Apellido = Apellido,
        Fecha_Nacimiento = CONVERT(DATE, Fecha_Nacimiento, 103),
        Tipo_Documento = REPLACE(Tipo_Documento, Tipo_Documento, UPPER(Tipo_Documento)),
        Sexo = REPLACE(Sexo, Sexo, UPPER(LEFT(Sexo, 1)) + LOWER(SUBSTRING(Sexo, 2, LEN(Sexo)-1))),
        Genero = REPLACE(Genero, Genero, UPPER(LEFT(Genero, 1)) + LOWER(SUBSTRING(Genero, 2, LEN(Genero)-1))),
        Telefono = Telefono,
        Nacionalidad = REPLACE(Nacionalidad, Nacionalidad, UPPER(LEFT(Nacionalidad, 1)) + LOWER(SUBSTRING(Nacionalidad, 2, LEN(Nacionalidad)-1))),
        Email = REPLACE(Email, Email, LOWER(Email)),
        Direccion = REPLACE(Direccion, Direccion, [Clinica].[InitCap](Direccion)),
        Localidad = REPLACE(Localidad, Localidad, [Clinica].[InitCap](Localidad)),
        Provincia = REPLACE(Provincia, Provincia, [Clinica].[InitCap](Provincia));
    
    -- 3. Insertar los datos en la tabla domicilio temporal

    INSERT INTO Clinica.DomicilioTemporal
    (
        Direccion,
        Pais,
        Provincia,
        Localidad
    )
    SELECT DISTINCT
        Direccion,
        Nacionalidad,
        Provincia,
        Localidad
    FROM Clinica.PacienteTemporal
	WHERE Direccion NOT IN (SELECT Direccion FROM Clinica.DomicilioTemporal);

    UPDATE Clinica.DomicilioTemporal
    SET Calle = [Clinica].[getFirstString](Direccion),
        Numero = [Clinica].[getFinalNumber](Direccion);

    -- 4. Insertar los datos en la tabla domicilio

    INSERT INTO Clinica.Domicilio
    (
        Calle,
        Numero,
        Piso,
        Departamento,
        Codigo_Postal,
        Pais,
        Provincia,
        Localidad
    )
    SELECT
        Calle,
        Numero,
        Piso,
        Departamento,
        Codigo_Postal,
        Pais,
        Provincia,
        Localidad
    FROM Clinica.DomicilioTemporal
    WHERE Calle NOT IN (SELECT Calle FROM Clinica.Domicilio);

    -- 4. Insertar los datos en la tabla paciente
    INSERT INTO Clinica.Paciente
    (
        Nombre,
        Apellido,
        Fecha_Nacimiento,
        Tipo_Documento,
        Numero_Documento,
        Sexo_Biologico,
        Genero,
        Telefono_Fijo,
        Nacionalidad,
        Mail,
        Id_Domicilio
    )
    SELECT
        Nombre,
        Apellido,
        Fecha_Nacimiento,
        Tipo_Documento,
        DNI,
        Sexo,
        Genero,
        Telefono,
        Nacionalidad,
        Email,
        Id_Domicilio
    FROM Clinica.PacienteTemporal JOIN Clinica.DomicilioTemporal ON Clinica.PacienteTemporal.Direccion = Clinica.DomicilioTemporal.Direccion
    WHERE DNI NOT IN (SELECT Numero_Documento FROM Clinica.Paciente);

	--SELECT * FROM Clinica.PacienteTemporal INNER JOIN Clinica.DomicilioTemporal 
	--ON Clinica.PacienteTemporal.Direccion = Clinica.DomicilioTemporal.Direccion

    -- 5. Limpiar la tabla temporal
    DROP TABLE Clinica.PacienteTemporal;
    DROP TABLE Clinica.DomicilioTemporal;

END
GO



--Importar CSV Prestadores:

CREATE OR ALTER PROCEDURE Clinica.importarPrestadores
@rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX)

    --Chequeamos si la tabla temporal existe, si existe la borramos
    DROP TABLE IF EXISTS clinica.tempPrestador
    CREATE TABLE clinica.tempPrestador
    (
        Nombre_Prestador VARCHAR(50)
        ,Plan_prestador VARCHAR(50)
    )
    --Corro el BULK del import
    DECLARE @ImportPrestadores NVARCHAR(MAX)
    SET @ImportPrestadores = 
    'BULK INSERT clinica.tempPrestador ' +
    'FROM ''' + @rutaArchivo + ''' ' +
    'WITH ( ' +
    '    FIELDTERMINATOR = '';'', ' +
    '    ROWTERMINATOR = ''\n'', ' +
    '    FIRSTROW = 2, ' +
    '    CODEPAGE = ''65001''' +
    ')'

   EXEC sp_executesql @ImportPrestadores



   --Limpio los datos de la tabla STG quitando los ";;" del final de la linea
    UPDATE clinica.tempPrestador
    SET Plan_prestador = LEFT(Plan_prestador, LEN(Plan_prestador) - 2)
    WHERE Plan_prestador LIKE '%;;'



	--Inserto los datos nuevos en la tabla final:

	--Inserto los datos nuevos en la tabla final, evitando duplicados:
	INSERT INTO clinica.Prestador
	(
		Nombre_Prestador,
		Plan_prestador
	)
	SELECT Nombre_Prestador, Plan_prestador
	FROM clinica.tempPrestador A
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM clinica.Prestador B
        WHERE A.Nombre_Prestador = B.Nombre_Prestador
        AND A.Plan_prestador = B.Plan_prestador
    )
END



--Importar CSV Sedes:

CREATE OR ALTER PROCEDURE Clinica.importarSedes
@rutaArchivo NVARCHAR(MAX)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX)

    --Chequeamos si la tabla temporal existe, si existe la borramos
    DROP TABLE IF EXISTS clinica.#tempSede
    CREATE TABLE clinica.#tempSede
    (
        Nombre_Sede VARCHAR(50)
        ,Direccion VARCHAR(100)
        ,Localidad VARCHAR(50)
        ,Provincia VARCHAR(50)
    )
    --Corro el BULK del import
    DECLARE @ImportSedes NVARCHAR(MAX)
    SET @ImportSedes = 
    'BULK INSERT clinica.#tempSede ' +
    'FROM ''' + @rutaArchivo + ''' ' +
    'WITH ( ' +
    '    FIELDTERMINATOR = '';'', ' +
    '    ROWTERMINATOR = ''\n'', ' +
    '    FIRSTROW = 2, ' +
    '    CODEPAGE = ''65001''' +
    ')'

   EXEC sp_executesql @ImportSedes

--Updateo tabla clinica sede en caso de que el registro ya exista(Chequemos con direccion ante la falta de un id):
UPDATE clinica.Sede_De_Atencion
SET
    Direccion = a.Direccion
FROM clinica.#tempSede a
WHERE clinica.Sede_De_Atencion.Nombre_Sede = a.Nombre_Sede

--Inserto los datos nuevos en la tabla final:

INSERT INTO clinica.Sede_De_Atencion
(
    Nombre_Sede
    ,Direccion

)
SELECT
    Nombre_Sede
    ,Direccion

FROM clinica.#tempSede A
WHERE a.Nombre_Sede NOT IN (SELECT Nombre_Sede FROM clinica.Sede_De_Atencion )

--Drop la tabla temporal
DROP TABLE clinica.#tempSede

END



--Import JSON Tipo_Estudios:

DROP PROCEDURE IF EXISTS clinica.ImportarEstudios;
GO

CREATE OR ALTER PROCEDURE Clinica.ImportarEstudios
    @rutaArchivo NVARCHAR(MAX)
AS
BEGIN

    DROP TABLE IF EXISTS clinica.tempEstudio
    CREATE TABLE clinica.tempEstudio
    (
        Id_Estudio VARCHAR(50) PRIMARY KEY,
        Area VARCHAR(50),
        Nombre_Estudio VARCHAR(50),
        Prestador VARCHAR(50),
        Plan_ VARCHAR(50),
        Cobertura INT,
        Costo INT,
        Autorizacion BIT
    )

    DECLARE @sql NVARCHAR(MAX) = 

    
    'INSERT INTO clinica.tempEstudio
    (
        Id_Estudio,
        Area,
        Nombre_Estudio,
        Prestador,
        Plan_,
        Cobertura,
        Costo,
        Autorizacion
    )
    
    SELECT
        Id_Estudio,
        Area,
        Nombre_Estudio,
        Prestador,
        Plan_,
        Cobertura,
        Costo,
        Autorizacion
    
    FROM OPENROWSET
    (
        BULK''' + @rutaArchivo + ''',
        Single_Clob
    )
    AS Estudios
    CROSS APPLY OPENJSON(BulkColumn)
    WITH
    (
        Id_Estudio VARCHAR(50) ''$._id."$oid"'',
        Area VARCHAR(50) ''$.Area'',
        Nombre_Estudio VARCHAR(50) ''$.Estudio'',
        Prestador VARCHAR(50) ''$.Prestador'',
        Plan_ VARCHAR(50) ''$.Plan'',
        Cobertura INT ''$."Porcentaje Cobertura"'',
        Costo INT ''$.Costo'',
        Autorizacion BIT ''$."Requiere autorizacion"''
    )'

    --Limpio datos:
    --Quitamos Tildes
    EXEC sp_executesql @sql

    UPDATE clinica.tempEstudio
    SET Nombre_Estudio = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Nombre_Estudio, 'Ã¡', 'á'), 'Ã©', 'é'), 'Ã­', 'í'), 'Ã³', 'ó'), 'Ãº', 'ú'), 'Ã±', 'ñ'),
        Plan_ = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Plan_, 'Ã¡', 'á'), 'Ã©', 'é'), 'Ã­', 'í'), 'Ã³', 'ó'), 'Ãº', 'ú'), 'Ã±', 'ñ');


--Updateo la tabla Clinica.Tipo_Estudio en caso de que el registro ya exista y cambie algun otro campo
    UPDATE clinica.Tipo_Estudio
    SET
        Area = a.Area,
        Nombre_Estudio = a.Nombre_Estudio,
        Prestador = a.Prestador,
        Plan_ = a.Plan_,
        Cobertura = a.Cobertura,
        Costo = a.Costo,
        Autorizacion = a.Autorizacion
    FROM clinica.tempEstudio a
    WHERE clinica.Tipo_Estudio.Id_Estudio = a.Id_Estudio
    AND
    (
        clinica.Tipo_Estudio.Area != a.Area
        OR clinica.Tipo_Estudio.Nombre_Estudio != a.Nombre_Estudio
        OR clinica.Tipo_Estudio.Prestador != a.Prestador
        OR clinica.Tipo_Estudio.Plan_ != a.Plan_
        OR clinica.Tipo_Estudio.Cobertura != a.Cobertura
        OR clinica.Tipo_Estudio.Costo != a.Costo
        OR clinica.Tipo_Estudio.Autorizacion != a.Autorizacion
    )

    --Inserto datos en la Tabla Tipo_Estudio (evita repetidos)
    INSERT INTO clinica.Tipo_Estudio
    (
        Id_Estudio,
        Area,
        Nombre_Estudio,
        Prestador,
        Plan_,
        Cobertura,
        Costo,
        Autorizacion
    )
    SELECT
        Id_Estudio,
        Area,
        Nombre_Estudio,
        Prestador,
        Plan_,
        Cobertura,
        Costo,
        Autorizacion
    FROM clinica.tempEstudio
    WHERE Id_Estudio NOT IN (SELECT Id_Estudio FROM clinica.Tipo_Estudio)

--Inserto los valores posibles en Estudio:
    INSERT INTO clinica.Estudio
    (
        Id_Estudio,
        Nombre_Estudio,
        Autorizado
    )
    SELECT
        Id_Estudio,
        Nombre_Estudio,
        CASE 
            WHEN Autorizacion = 1 THEN 'Autorizado' 
            ELSE 'No Autorizado' 
        END AS Autorizacion
    FROM clinica.Tipo_Estudio
    WHERE Id_Estudio NOT IN (SELECT Id_Estudio FROM clinica.Estudio)
    AND Nombre_Estudio IS NOT NULL

END
GO
