/*
PRUEBAS RAPIDAS
Cada bloque DEBE terminar en el CATCH mostrando el mensaje.
Si algun bloque no muestra error, el trigger no esta funcionando.
*/

-- Prueba 1: Team Liquid (equipo 5) no tiene integrantes -> no puede inscribirse
BEGIN TRY
    INSERT INTO Inscripcion (id_torneo, id_equipo) VALUES (3, 5);
    PRINT 'PRUEBA 1 FALLO: no se rechazo la inscripcion.';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1 OK: ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 2: el jugador 14 (Gen.G) no juega en el partido 5 (equipo 4 vs ?)
BEGIN TRY
    INSERT INTO Alineacion_Partido (id_partido, id_jugador, id_equipo) VALUES (5, 14, 2);
    PRINT 'PRUEBA 2 FALLO: no se rechazo la alineacion.';
END TRY
BEGIN CATCH
    PRINT 'Prueba 2 OK: ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 3: el torneo 3 tiene 3 equipos inscriptos de 8 -> no puede iniciar
BEGIN TRY
    UPDATE Torneo SET estado = 'En curso' WHERE id_torneo = 3;
    PRINT 'PRUEBA 3 FALLO: el torneo inicio sin cupo completo.';
END TRY
BEGIN CATCH
    PRINT 'Prueba 3 OK: ' + ERROR_MESSAGE();
END CATCH
GO