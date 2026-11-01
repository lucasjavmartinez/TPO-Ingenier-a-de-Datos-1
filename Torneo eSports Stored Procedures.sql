USE torneoEsportsBD1;
GO

--Procedimiento 1: sirve para insertar ya sea Organizador, Manager o Arbitro los cuales comparten atributos al ser Persona

CREATE PROCEDURE sp_insertPersonal
    @dni VARCHAR(10),
    @nombre VARCHAR(60),
    @apellido VARCHAR(60),
    @mail VARCHAR(100),
    @fecha_nacimiento DATE,
    @rol VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY --iniciamos el manejo de errores
        BEGIN TRAN;
        INSERT INTO Persona(dni, nombre, apellido, mail, fecha_nacimiento)
        VALUES (@dni, @nombre, @apellido, @mail, @fecha_nacimiento);

        DECLARE @NuevoIdPersona INT = SCOPE_IDENTITY();

        IF @rol = 'Organizador'
            INSERT INTO Organizador(id_persona) VALUES(@NuevoIdPersona);
        ELSE IF @rol = 'Manager'
            INSERT INTO Manager(id_persona) VALUES(@NuevoIdPersona);
        ELSE IF @rol = 'Arbitro'
            INSERT INTO Arbitro(id_persona) VALUES(@NuevoIdPersona);
        ELSE
        BEGIN
            THROW 50017, 'El rol es invalido, debe de ser Organizador, Manager o Arbitro', 1;
        END

        COMMIT TRAN; --si todo esta bien se guarda en la bd
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 --esto es del motor de base de datos
            ROLLBACK TRAN; --si falló se hace rollback de la transaccion
        DECLARE @Error NVARCHAR(4000) = 'Fallo al registrar personal: ' + ERROR_MESSAGE();
        THROW 50018, @Error, 1;
    END CATCH
    END;
GO

-- Procedimiento 2: sirve para insertar unicamente jugadores ya que este a diferencia del resto tiene el atributo nick

CREATE PROCEDURE sp_insertarJugador
    @dni VARCHAR(10),
    @nombre varchar(60),
    @apellido VARCHAR(60),
    @mail VARCHAR(100),
    @fecha_nacimiento DATE,
    @nick VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;
        INSERT INTO Persona(dni, nombre, apellido, mail, fecha_nacimiento)
        VALUES (@dni, @nombre, @apellido, @mail, @fecha_nacimiento);

        DECLARE @NuevoIdPersona INT = SCOPE_IDENTITY();

        INSERT INTO Jugador(id_persona, nick)
        VALUES (@NuevoIdPersona, @nick);

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        DECLARE @Error NVARCHAR(4000) = 'Fallo al registrar el jugador: ' + ERROR_MESSAGE();
        THROW 50019, @Error, 1;
    END CATCH
END;
GO

-- Sp 3: sirve para cambiar el estado de la persona a la cual se da de baja

CREATE PROCEDURE sp_bajaPersona
    @id_persona INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;
        --comprobamos si el id existe en la base de datos, si no existe tira error
        IF NOT EXISTS (SELECT 1 FROM Persona WHERE id_persona = @id_persona)
        BEGIN
            THROW 50020, 'La persona no existe en el sistema', 1;
        END

        UPDATE Persona
        SET activo = 0
        WHERE id_persona = @id_persona;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
         ROLLBACK TRAN;
        DECLARE @Error NVARCHAR(4000) = 'Fallo al dar de baja a la persona: ' + ERROR_MESSAGE();
        THROW 50021, @Error, 1;
    END CATCH
END;
GO
