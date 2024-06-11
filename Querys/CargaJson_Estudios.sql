USE Com2900G03
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'clinicaImportar')
    EXEC('CREATE SCHEMA clinicaImportar')
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
        Autorizacion VARCHAR(50),
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
        Autorizacion VARCHAR(50) ''$."Requiere Autorizacion"''
    )'

--Limpio datos(TAN DIFICIL IBA A SER ESTO?,):
--Quitamos Tildes
    EXEC sp_executesql @sql

UPDATE clinica.tempEstudio
SET Nombre_Estudio = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Nombre_Estudio, 'Ã¡', 'á'), 'Ã©', 'é'), 'Ã­', 'í'), 'Ã³', 'ó'), 'Ãº', 'ú'), 'Ã±', 'ñ'),
    Plan_ = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Plan_, 'Ã¡', 'á'), 'Ã©', 'é'), 'Ã­', 'í'), 'Ã³', 'ó'), 'Ãº', 'ú'), 'Ã±', 'ñ');
END
GO

-- Test

EXEC Clinica.ImportarEstudios 'C:\Users\ic255011\OneDrive - Teradata\Escritorio\Nacho\Unlam\GitHub\Tp-BDDA\Dataset\Centro_Autorizaciones.Estudios clinicos.json'
