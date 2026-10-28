--Consultas SQL

--1. Consultamos el jugador con mas cantidad de kills de un determinado equipo y los ordenamos de mayor a menor
SELECT
    J.nick AS Nickname,
    P.nombre AS Nombre,
    P.apellido AS Apellido,
    E.nombre AS Equipo_actual,
    SUM(AP.kills) AS Total_kills,
    SUM(AP.deaths) AS Total_deaths,
    SUM(AP.assists) AS Total_assits
FROM Persona P
INNER JOIN Jugador J ON P.id_persona = J.id_persona
INNER JOIN Integrante_Equipo IE ON J.id_persona = IE.id_jugador
INNER JOIN Equipo E ON IE.id_equipo = E.id_equipo
INNER JOIN Alineacion_Partido AP ON J.id_persona = AP.id_jugador
WHERE
    E.nombre = 'T1'
    AND IE.fecha_egreso IS NULL
GROUP BY
    J.nick, P.nombre, P.apellido, E.nombre
HAVING
    SUM(AP.kills) > 0
ORDER BY
    Total_kills DESC
GO

--2. Consultamos el mvp del torneo, esto se calcula de la sig manera: el jugador con mayor mvps acumulados en todos los partidos
--es quien ganará el premio mvp del torneo

SELECT TOP 1
    T.nombre AS Torneo,
    J.nick AS Nickname,
    CONCAT(P.nombre,' ', P.apellido) AS Nombre_completo,
    COUNT(Pa.id_partido) AS Cantidad_MVP
FROM Partido Pa
INNER JOIN Torneo T ON Pa.id_torneo = T.id_torneo
INNER JOIN Jugador J ON Pa.id_mvp_jugador = J.id_persona
INNER JOIN Persona P ON J.id_persona = P.id_persona
WHERE
    T.estado = 'Finalizado'
    AND Pa.id_mvp_jugador IS NOT NULL
GROUP BY
    T.nombre, J.nick, P.nombre, P.apellido
ORDER BY
    Cantidad_MVP DESC;
GO


--Consultas con subconsultas

/*1. Consultamos los jugadores inscriptos en el torneo que cuenten con alguna sancion
esto con la finalidad de que el organizador del evento pueda auditar y comprobar que
los equipos que van a disputar la siguiente partida no posea ninguna sancion vigente*/

--la logica para que esto nunca pase se hará en sp o triggers

SELECT
    T.nombre AS Torneo_activo,
    E.nombre AS Equipo_que_infringe,
    J.nick AS Jugador_con_sancion,
    CONCAT(P.nombre, ' ', P.apellido) AS Nombre_Jugador_Con_Sancion
FROM Torneo T
INNER JOIN Inscripcion I ON T.id_torneo = I.id_torneo
Inner Join Equipo E ON I.id_equipo = E.id_equipo
INNER JOIN Integrante_Equipo IE ON E.id_equipo = IE.id_equipo
INNER JOIN Jugador J ON IE.id_jugador = J.id_persona
INNER JOIN Persona P ON J.id_persona = P.id_persona
WHERE
    T.estado IN ('Inscripcion', 'En curso')
    AND IE.fecha_egreso IS NULL
    AND J.id_persona IN(
        --en esta subconsulta buscamos si el jugador tiene alguna sancion al momento
        SELECT id_jugador
        FROM Sancion
        WHERE CAST(GETDATE() AS DATE) BETWEEN fecha_inicio AND fecha_fin
    );
GO

/*2. Consultamos los equipos que llevan al menos 60 dias inactivos con la idea de borrarlos de la bd, 
esto para asegurarnos de que la base de datos no acumule equipos 
El equipo que tenga mas de 60 dias de participar de algun torneo es considerado equipo fantasma y deberia borrarse*/

SELECT
    E.nombre AS Equipo_inactivo,
    E.fecha_alta,
    CONCAT(P.nombre, ' ', P.apellido) AS Nombre_Manager,
    P.mail AS Mail_manager
FROM Equipo E
INNER JOIN Manager M ON E.id_manager = M.id_persona
INNER JOIN Persona P ON M.id_persona = P.id_persona
WHERE
    E.id_equipo NOT IN(
        SELECT DISTINCT id_equipo
        FROM Inscripcion
    )
    AND DATEDIFF(DAY, E.fecha_alta, GETDATE()) > 60;
GO