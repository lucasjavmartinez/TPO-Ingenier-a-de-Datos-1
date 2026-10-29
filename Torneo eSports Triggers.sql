/* 
TRIGGERS - Torneo eSports
Ejecutar DESPUES de Creacion_Tablas e Insert_datos.
*/

USE torneoEsportsBD1;
GO

/* ------------------------------------------------------------
   1. Inscripcion (INSERT)
   Reglas: el torneo debe estar en 'Inscripcion', no se supera el cupo y el equipo debe tener al menos 5 integrantes activos.
   Por que trigger: cruza datos de Torneo, Inscripcion e Integrante_Equipo (un CHECK solo ve la fila propia).
   ------------------------------------------------------------ */
CREATE OR ALTER TRIGGER trg_Inscripcion_Validar
ON Inscripcion
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN Torneo t ON t.id_torneo = i.id_torneo
               WHERE t.estado <> 'Inscripcion')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'Solo se pueden inscribir equipos en torneos en estado Inscripcion.', 1;
    END

    IF EXISTS (SELECT 1
               FROM Torneo t
               WHERE t.id_torneo IN (SELECT id_torneo FROM inserted)
                 AND (SELECT COUNT(*) FROM Inscripcion x WHERE x.id_torneo = t.id_torneo) > t.cantidad_equipos)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50002, 'El torneo ya alcanzo su cupo de equipos.', 1;
    END

    -- RN01: minimo 5 integrantes (cambiar "< 5" por "<> 5" si se exige exactamente 5)
    IF EXISTS (SELECT 1
               FROM inserted i
               WHERE (SELECT COUNT(*)
                      FROM Integrante_Equipo ie
                      WHERE ie.id_equipo = i.id_equipo
                        AND ie.fecha_egreso IS NULL) < 5)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50003, 'El equipo debe tener al menos 5 integrantes activos para inscribirse.', 1;
    END
END
GO

/* ------------------------------------------------------------
   2. Inscripcion (UPDATE de estado)
   Regla: no se puede descalificar a un equipo que ya jugo un partido.
   ------------------------------------------------------------ */
CREATE OR ALTER TRIGGER trg_Inscripcion_Descalificacion
ON Inscripcion
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(estado)
       AND EXISTS (SELECT 1
                   FROM inserted i
                   INNER JOIN deleted d ON d.id_inscripcion = i.id_inscripcion
                   WHERE i.estado = 'Descalificado'
                     AND d.estado <> 'Descalificado'
                     AND EXISTS (SELECT 1
                                 FROM Partido p
                                 WHERE p.id_torneo = i.id_torneo
                                   AND p.estado = 'Jugado'
                                   AND (p.id_equipo_a = i.id_equipo OR p.id_equipo_b = i.id_equipo)))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50004, 'No se puede descalificar a un equipo que ya jugo un partido.', 1;
    END
END
GO

/* ------------------------------------------------------------
   3. Torneo (UPDATE de estado)
   Regla: un torneo solo pasa a 'En curso' con el cupo completo.
   ------------------------------------------------------------ */
CREATE OR ALTER TRIGGER trg_Torneo_Estado
ON Torneo
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(estado)
       AND EXISTS (SELECT 1
                   FROM inserted i
                   INNER JOIN deleted d ON d.id_torneo = i.id_torneo
                   WHERE i.estado = 'En curso'
                     AND d.estado <> 'En curso'
                     AND (SELECT COUNT(*) FROM Inscripcion x WHERE x.id_torneo = i.id_torneo) <> i.cantidad_equipos)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50005, 'El torneo no puede iniciar: la cantidad de equipos inscriptos no coincide con el cupo.', 1;
    END
END
GO

/* ------------------------------------------------------------
   4. Partido (INSERT / UPDATE)
   Reglas: los equipos deben estar inscriptos en ese torneo; el partido siguiente debe ser del mismo torneo y de la fase 
   inmediata; un partido 'Jugado' tiene 5 jugadores por equipo y su MVP debe ser uno de los que jugaron.
   (Que un partido jugado tenga MVP y que uno no jugado no lo tenga se controla con el CHECK CK_Partido_mvp.)
   ------------------------------------------------------------ */
CREATE OR ALTER TRIGGER trg_Partido_Validar
ON Partido
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               WHERE (i.id_equipo_a IS NOT NULL
                      AND NOT EXISTS (SELECT 1 FROM Inscripcion x
                                      WHERE x.id_torneo = i.id_torneo AND x.id_equipo = i.id_equipo_a))
                  OR (i.id_equipo_b IS NOT NULL
                      AND NOT EXISTS (SELECT 1 FROM Inscripcion x
                                      WHERE x.id_torneo = i.id_torneo AND x.id_equipo = i.id_equipo_b)))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50006, 'Los equipos del partido deben estar inscriptos en el torneo.', 1;
    END

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN Partido s ON s.id_partido = i.id_partido_siguiente
               WHERE s.id_torneo <> i.id_torneo
                  OR s.nro_fase <> i.nro_fase + 1)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50007, 'El partido siguiente debe ser del mismo torneo y de la fase inmediata.', 1;
    END

    IF EXISTS (SELECT 1
               FROM inserted i
               WHERE i.estado = 'Jugado'
                 AND (   NOT EXISTS (SELECT 1 FROM Alineacion_Partido a
                                     WHERE a.id_partido = i.id_partido
                                       AND a.id_jugador = i.id_mvp_jugador)
                      OR (SELECT COUNT(*) FROM Alineacion_Partido a
                          WHERE a.id_partido = i.id_partido AND a.id_equipo = i.id_equipo_a) <> 5
                      OR (SELECT COUNT(*) FROM Alineacion_Partido a
                          WHERE a.id_partido = i.id_partido AND a.id_equipo = i.id_equipo_b) <> 5))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50008, 'Para cerrar el partido deben estar cargados los 5 jugadores de cada equipo y el MVP debe ser uno de ellos.', 1;
    END
END
GO

/* ------------------------------------------------------------
   5. Partido (UPDATE) - resultado inmutable
   Regla: una vez cargado el resultado, no se modifica salvo que lo haga un administrador 
   (db_owner o el rol rol_administrador, que se creara en el script de seguridad).
   ------------------------------------------------------------ */
CREATE OR ALTER TRIGGER trg_Partido_Resultado_Inmutable
ON Partido
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN deleted d ON d.id_partido = i.id_partido
               WHERE d.estado = 'Jugado'
                 AND (   i.estado <> d.estado
                      OR ISNULL(i.puntaje_a, -1) <> ISNULL(d.puntaje_a, -1)
                      OR ISNULL(i.puntaje_b, -1) <> ISNULL(d.puntaje_b, -1)
                      OR ISNULL(i.id_mvp_jugador, -1) <> ISNULL(d.id_mvp_jugador, -1)))
       AND IS_MEMBER('db_owner') = 0
       AND ISNULL(IS_MEMBER('rol_administrador'), 0) = 0
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50009, 'El resultado de un partido jugado solo puede ser modificado por un administrador.', 1;
    END
END
GO

/* ------------------------------------------------------------
   6. Alineacion_Partido (INSERT)
   Reglas: el equipo juega ese partido, el partido no esta cancelado, el jugador es integrante activo de ese equipo, 
   no hay mas de 5 por equipo y el jugador no tiene una sancion vigente.
   ------------------------------------------------------------ */
CREATE OR ALTER TRIGGER trg_Alineacion_Validar
ON Alineacion_Partido
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN Partido p ON p.id_partido = i.id_partido
               WHERE i.id_equipo NOT IN (ISNULL(p.id_equipo_a, 0), ISNULL(p.id_equipo_b, 0)))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50010, 'El equipo indicado no participa en este partido.', 1;
    END

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN Partido p ON p.id_partido = i.id_partido
               WHERE p.estado = 'Cancelado')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50011, 'No se puede cargar alineacion en un partido cancelado.', 1;
    END

    IF EXISTS (SELECT 1
               FROM inserted i
               WHERE NOT EXISTS (SELECT 1 FROM Integrante_Equipo ie
                                 WHERE ie.id_equipo = i.id_equipo
                                   AND ie.id_jugador = i.id_jugador
                                   AND ie.fecha_egreso IS NULL))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50012, 'El jugador no es integrante activo del equipo indicado.', 1;
    END

    IF EXISTS (SELECT 1
               FROM Alineacion_Partido a
               WHERE a.id_partido IN (SELECT id_partido FROM inserted)
               GROUP BY a.id_partido, a.id_equipo
               HAVING COUNT(*) > 5)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50013, 'Un equipo no puede tener mas de 5 jugadores en un partido.', 1;
    END

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN Partido p ON p.id_partido = i.id_partido
               INNER JOIN Sancion s ON s.id_jugador = i.id_jugador
               WHERE COALESCE(CAST(p.fecha_hora AS DATE), CAST(GETDATE() AS DATE))
                     BETWEEN s.fecha_inicio AND s.fecha_fin)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50014, 'El jugador tiene una sancion vigente y no puede jugar.', 1;
    END
END
GO

/* ------------------------------------------------------------
   7. Jugador (INSERT)
   Regla: edad minima para registrarse como jugador.
   PENDIENTE: confirmar la edad minima (aca 16 anios).
   ------------------------------------------------------------ */
CREATE OR ALTER TRIGGER trg_Jugador_Edad
ON Jugador
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN Persona p ON p.id_persona = i.id_persona
               WHERE p.fecha_nacimiento > DATEADD(YEAR, -16, CAST(GETDATE() AS DATE)))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50015, 'El jugador no cumple la edad minima para registrarse.', 1;
    END
END
GO

/* ------------------------------------------------------------
   8. Pago_Premio (INSERT)
   Regla: solo se pagan premios de torneos finalizados.
   ------------------------------------------------------------ */
CREATE OR ALTER TRIGGER trg_PagoPremio_Validar
ON Pago_Premio
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN Torneo t ON t.id_torneo = i.id_torneo
               WHERE t.estado <> 'Finalizado')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50016, 'Solo se pueden pagar premios de torneos finalizados.', 1;
    END
END
GO