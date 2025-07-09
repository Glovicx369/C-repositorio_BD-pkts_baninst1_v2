DROP PACKAGE BODY BANINST1.PKG_CAMBIO_GRUPO;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_cambio_grupo
AS
    function f_carga_masivo(p_regla number)
    return varchar2
    is
        l_contar_pidm number;
        l_pidm        number;
        l_retorna     varchar2(500):='EXITO';
        l_regla       varchar2(20);
        l_contar_grupo number;
    begin

        delete sztcgru
        where 1 = 1
        and sztcgru_no_regla = p_regla;

        l_regla:=to_char(p_regla);

        commit;

        for c in (select distinct sztcgru_id matricula,
                                  SZTCGRU_MATERIA_LEGAL materia,
                                  SZTCGRU_GRUPO_ORIGEN origen,
                                  SZTCGRU_GRUPO_DESTINO destino
                  from sztcgru_paso
                  where 1 = 1
                  and tO_NUMBER(TRIM(REPLACE (REPLACE (REPLACE (sztcgru_no_regla, CHR (10), ' '), CHR (13), ' '),' ',' '))) = l_regla
                 )loop

                    begin

                        select count(*)
                        into l_contar_pidm
                        from spriden
                        where 1 = 1
                        and spriden_change_ind is null
                        and spriden_id = c.matricula;

                    exception when others then
                        null;
                    end;

                    --dbms_output.put_line('Contar '||l_contar_pidm);

                    if l_contar_pidm > 0 then

                        BEGIN

                            SELECT spriden_pidm
                            INTO l_pidm
                            FROM spriden
                            WHERE 1 = 1
                            AND spriden_change_ind IS NULL
                            AND spriden_id = c.matricula;


                        EXCEPTION WHEN OTHERS THEN
                            NULL;
                        END;

                        begin

                            select count(*)
                            into l_contar_grupo
                            from sztgpme
                            where 1 = 1
                            and sztgpme_no_regla = p_regla
                            and SZTGPME_TERM_NRC = c.materia||c.destino;

                        exception when others then
                            null;
                        end;

                        if l_contar_grupo > 0 then

                            begin

                                insert into SZTCGRU values(
                                                           l_pidm,
                                                           c.matricula,
                                                           c.materia,
                                                           c.origen,
                                                           c.destino,
                                                           'N',
                                                           null,
                                                           null,
                                                           p_regla,
                                                           'S'
                                                          );


                            exception when others then
                                l_retorna:='No se puede insertar enn la tabla de cambio de grupo '||sqlerrm;
                            end;

                        else

                             l_retorna:='El grupo no existe verifica';

                            begin

                                insert into SZTCGRU values(
                                                           null,
                                                           c.matricula,
                                                           c.materia,
                                                           c.origen,
                                                           c.destino,
                                                           'N',
                                                           'S',
                                                           l_retorna,
                                                           p_regla,
                                                           'S'
                                                          );

                            exception when others then
                                l_retorna:='No se puede insertar enn la tabla de cambio de grupo '||sqlerrm;
                            end;

                        end if;


                    ELSE

                        l_retorna:='El pidm no existe verifica';

                        --dbms_output.put_line(l_retorna);

                        begin

                            insert into SZTCGRU values(
                                                       null,
                                                       c.matricula,
                                                       c.materia,
                                                       c.origen,
                                                       c.destino,
                                                       'N',
                                                       'S',
                                                       l_retorna,
                                                       p_regla,
                                                       'S'
                                                      );

                        exception when others then
                            l_retorna:='No se puede insertar enn la tabla de cambio de grupo '||sqlerrm;
                        end;

                        --dbms_output.put_line(l_retorna);

                    END IF;
                    
                    
                          begin
                                DECLARE 
                                  RetVal VARCHAR2(32767);
                                  P_REGLA NUMBER;
                                  P_MATRICULA VARCHAR2(32767);
                                  P_MATERIA_LEGAL VARCHAR2(32767);

                                BEGIN 
                                  P_REGLA := p_regla;
                                  P_MATRICULA := c.matricula;
                                  P_MATERIA_LEGAL := c.materia;

                                  RetVal := BANINST1.PKG_CAMBIO_GRUPO.F_CAMBIO_GRUPO ( P_REGLA, P_MATRICULA, P_MATERIA_LEGAL );
                                  COMMIT; 
                                END; 

                         end;
                    

                 end loop;

                 commit;

                return(l_retorna);

    end;
--
--
    function f_cambio_grupo(p_regla number,
                            p_matricula varchar2,
                            p_materia_legal varchar2)
    return varchar2
    is
        l_pidm        number;
        l_retorna     varchar2(500):='EXITO';
        l_contar_pidm number;
        l_maximo      number;
        l_pwd         varchar2(100);
        l_contar_grupo number;

    begin

    /************************************************
    +                                               +
    +   creado por Juan Jesús Corona Miranda        +
    +   fecha: 6 de Octubre del 2020                +
    +                                               +
    +                                               +
    ************************************************/

        if l_retorna ='EXITO' then


          for c in (select gru.*,
                           get_crn_regla(gru.sztcgru_pidm,
                                         null,
                                         gru.SZTCGRU_MATERIA_LEGAL,
                                         gru.SZTCGRU_NO_REGLA
                                         )crn,
                           ono.sztprono_term_code periodo,
                           ono.sztprono_fecha_inicio fecha_inicio
                    from sztcgru gru
                    join  sztprono ono on ono.sztprono_pidm = gru.sztcgru_pidm
                                      and ono.sztprono_materia_legal = gru.SZTCGRU_MATERIA_LEGAL
                                      and ono.sztprono_no_regla  = gru.SZTCGRU_NO_REGLA
                    where 1 = 1
                    and sztcgru_no_regla = p_regla
                    and sztcgru_id = p_matricula
                    and sztprono_materia_legal = p_materia_legal
                    and SZTCGRU_pidm is not null
                     )loop


                      -- dbms_output.put_line('Matricula '||c.SZTCGRU_ID||' Crn '||c.crn||' Periodo '||c.periodo);


                         --if c.crn<>'00' then

                            begin

                                 update sfrstcr set SFRSTCR_RSTS_CODE ='DD',
                                                    SFRSTCR_DATA_ORIGIN ='CAMBIO_GRUPO',
                                                    SFRSTCR_USER = USER,
                                                    SFRSTCR_ACTIVITY_DATE = SYSDATE
                                 where 1 = 1
                                 and SFRSTCR_pidm = c.sztcgru_pidm
                                 and SFRSTCR_term_code = c.periodo
                                 and SFRSTCR_crn = c.crn;

                            exception when others then
                               l_retorna:='No se puede actualizar sfrtcr '||sqlerrm;
                            end;

                            IF l_retorna='EXITO' then

                               BEGIN

                                 SELECT max(nvl(SZSTUME_SEQ_NO,0))+1
                                 INTO l_maximo
                                 FROM SZSTUME
                                 WHERE SZSTUME_SUBJ_CODE = c.SZTCGRU_MATERIA_LEGAL
                                 AND  SZSTUME_PIDM = c.sztcgru_pidm
                                 and szstume_no_regla =p_regla;

                                 dbms_output.put_line('Entra 18');

                               EXCEPTION WHEN OTHERS THEN
                                   l_maximo := 0;
                               END;

                               begin
                                   select GOZTPAC_PIN
                                   into l_pwd
                                   from GOZTPAC pac
                                   where 1 = 1
                                   and pac.GOZTPAC_pidm =c.sztcgru_pidm;
                               exception when others then
                                   l_pwd:='xxxxx';
                               end;

                               dbms_output.put_line('Matricula '||c.SZTCGRU_ID||' Crn '||c.crn||' Periodo '||c.periodo||' Maximo '||l_maximo);

                               begin

                                    insert into SZSTUME values(c.SZTCGRU_MATERIA_LEGAL||c.SZTCGRU_GRUPO_ORIGEN,
                                                               c.sztcgru_pidm,
                                                               c.sztcgru_id,
                                                               sysdate,
                                                               user,
                                                               0,
                                                               null,
                                                               l_pwd,
                                                               null,
                                                               l_maximo,
                                                               'DD',
                                                               null,
                                                               c.SZTCGRU_MATERIA_LEGAL,
                                                               null,-- c.nivel,
                                                               null,
                                                               null,--  c.ptrm,
                                                               null,
                                                               null,
                                                               null,
                                                               null,
                                                               c.SZTCGRU_MATERIA_LEGAL,
                                                               c.fecha_inicio,--  c.inicio_clases,
                                                               p_regla,
                                                               l_maximo,
                                                               1,
                                                               0,
                                                               null
                                                               );


                               exception when others then
                                   l_retorna:='No se puede insertar en szstume baja '||sqlerrm;
                               end;

                               BEGIN

                                 SELECT max(nvl(SZSTUME_SEQ_NO,0))+1
                                 INTO l_maximo
                                 FROM SZSTUME
                                 WHERE SZSTUME_SUBJ_CODE = c.SZTCGRU_MATERIA_LEGAL
                                 AND  SZSTUME_PIDM = c.sztcgru_pidm
                                 and szstume_no_regla =p_regla;

                                 dbms_output.put_line('Entra 18');

                               EXCEPTION WHEN OTHERS THEN
                                   l_maximo := 0;
                               END;

                               begin

                                    insert into SZSTUME values(c.SZTCGRU_MATERIA_LEGAL||c.SZTCGRU_GRUPO_DESTINO,
                                                               c.sztcgru_pidm,
                                                               c.sztcgru_id,
                                                               sysdate,
                                                               user,
                                                               0,
                                                               null,
                                                               l_pwd,
                                                               null,
                                                               l_maximo,
                                                               'RE',
                                                               null,
                                                               c.SZTCGRU_MATERIA_LEGAL,
                                                               null,-- c.nivel,
                                                               null,
                                                               null,--  c.ptrm,
                                                               null,
                                                               null,
                                                               null,
                                                               null,
                                                               c.SZTCGRU_MATERIA_LEGAL,
                                                               c.fecha_inicio,--  c.inicio_clases,
                                                               p_regla,
                                                               l_maximo,
                                                               1,
                                                               0,
                                                               null
                                                               );

                               exception when others then
                                   l_retorna:='No se puede insertar en szstume alta '||sqlerrm;
                               end;

                               IF l_retorna='EXITO' then


                                   begin


                                         update sztprono set SZTPRONO_ENVIO_HORARIOS ='N',
                                                             SZTPRONO_ENVIO_MOODL ='S',
                                                             SZTPRONO_DESCRIPCION_ERROR = null,
                                                             SZTPRONO_ESTATUS_ERROR ='N'
                                         where 1 = 1
                                         and  sztprono_no_regla = p_regla
                                         and sztprono_materia_legal =  c.SZTCGRU_MATERIA_LEGAL
                                         and sztprono_pidm = c.sztcgru_pidm;

                                   exception when others then
                                      l_retorna:='No se puede actualizar sztprono '||sqlerrm;
                                   end;

                                    IF l_retorna='EXITO' then

                                       update sztcgru set SZTCGRU_PROCESADO='S',
                                                          SZTCGRU_ERROR ='N',
                                                          SZTCGRU_DETALLE =l_retorna
                                       where 1 = 1
                                       and sztcgru_pidm = c.sztcgru_pidm
                                       and sztcgru_materia_legal = c.sztcgru_materia_legal
                                       and SZTCGRU_NO_REGLA = p_regla;



                                    end if;

                               end if;


                            end if;

                         --end if;

                     end loop;
        end if;

        if l_retorna ='EXITO'then

            commit;

        else

            rollback;


        end if;

        return(l_retorna);

    end;


function f_carga_masivo_profe(p_regla number)
    return varchar2
    is
        l_contar_pidm number;
        l_pidm        number;
        l_retorna     varchar2(500):='EXITO';
        l_regla       varchar2(20);
        l_contar_profe number;
    begin

        delete SZTCGDO
        where 1 = 1
        and SZTCGDO_NO_REGLA = p_regla;

        l_regla:=to_char(p_regla);

        commit;

        for c in (select distinct    SZTCADO_ID matricula,
                                     SZTCADO_TERM_NRC term_nrc,
                                     SZTCADO_DOC_ORIGEN prof_origen,
                                     SZTCADO_DOC_DESTINO prof_destino
                  from  SZTCADO
                  where 1 = 1
                  and tO_NUMBER(TRIM(REPLACE (REPLACE (REPLACE (SZTCADO_NO_REGLA , CHR (10), ' '), CHR (13), ' '),' ',' '))) = l_regla

                 )loop

                    begin

                        select count(*)
                        into l_contar_pidm
                        from spriden
                        where 1 = 1
                        and spriden_change_ind is null
                        and spriden_id = c.matricula;

                    exception when others then
                        null;
                    end;

                    dbms_output.put_line('Contar '||l_contar_pidm);

                    if l_contar_pidm > 0 then

                        BEGIN

                            SELECT spriden_pidm
                            INTO l_pidm
                            FROM spriden
                            WHERE 1 = 1
                            AND spriden_change_ind IS NULL
                            AND spriden_id = c.prof_destino;


                        EXCEPTION WHEN OTHERS THEN
                            NULL;
                        END;

                        begin

                            select count(*)
                            into l_contar_profe
                            from sztgpme
                            where 1 = 1
                            and sztgpme_no_regla = p_regla
                            and SZTGPME_TERM_NRC = c.term_nrc;

                        exception when others then
                            null;
                        end;

                        dbms_output.put_line('Contar profe '||l_contar_profe);

                        if l_contar_profe > 0 then

                            begin

                                insert into SZTCGDO values(
                                                           l_pidm,
                                                           c.matricula,
                                                           c.TERM_NRC,
                                                           c.prof_origen,
                                                           c.prof_destino,
                                                           p_regla,
                                                           'N',
                                                           NULL,
                                                           null,
                                                           sysdate,
                                                           user
                                                          );

                            exception when others then
                                l_retorna:='No se puede insertar enn la tabla de cambio de profesor '||sqlerrm;
                            end;

                        else

                             l_retorna:='El profesor no existe verifica';

                              dbms_output.put_line('Entra a error ');

                            begin

                                 insert into SZTCGDO values(
                                                           l_pidm,
                                                           c.matricula,
                                                           c.TERM_NRC,
                                                           c.prof_origen,
                                                           c.prof_destino,
                                                           p_regla,
                                                           'N',
                                                           l_retorna,
                                                           null,
                                                           sysdate,
                                                           user
                                                          );

                            exception when others then
                                l_retorna:='No se puede insertar en la tabla de cambio de profesor '||sqlerrm;
                            end;

                        end if;


                    ELSE

                        l_retorna:='El pidm no existe verifica';

                        --dbms_output.put_line(l_retorna);

                        begin

                               insert into SZTCGDO values(
                                                           l_pidm,
                                                           c.matricula,
                                                           c.TERM_NRC,
                                                           c.prof_origen,
                                                           c.prof_destino,
                                                           p_regla,
                                                           'S',
                                                           null,
                                                           null,
                                                           sysdate,
                                                           user
                                                          );

                        exception when others then
                            l_retorna:='No se puede insertar en la tabla de cambio de profesor '||sqlerrm;
                        end;

                        --dbms_output.put_line(l_retorna);

                    END IF;

                 end loop;

                 commit;

                return(l_retorna);

    end;

--
--

    function f_cambio_prof(p_regla number)
    return varchar2
    is
        l_retorna varchar2(200):='EXITO';
        l_pwd  varchar2(100);
        l_secuencia number;
        l_contar    number;
        l_cont    NUMBER;
        l_matricula VARCHAR(9);

    BEGIN

            FOR C IN (SELECT *
                      FROM SZTCGDO
                      WHERE 1 = 1
                      AND SZTCGDO_no_regla = P_REGLA
                      AND SZTCGDO_PROCESADO = 'N'

                       )LOOP

                            begin

                                SELECT count(*)
                                into l_contar
                                FROM SZSGNME
                                WHERE 1 = 1
                                AND SZSGNME_NO_REGLA =P_REGLA
                                AND SZSGNME_PIDM=FGET_PIDM (C.SZTCGDO_ID)
                                and SZSGNME_TERM_NRC=c.SZTCGDO_TERM_NRC;

                            exception when others then
                                null;
                            end;


                            dbms_output.put_line('Grupo '||c.SZTCGDO_TERM_NRC||' Contar '||l_contar);

                            if l_contar > 0 then

                                FOR D IN (SELECT *
                                          FROM SZSGNME
                                          WHERE 1 = 1
                                          AND SZSGNME_NO_REGLA =P_REGLA
                                          AND SZSGNME_PIDM=FGET_PIDM (C.SZTCGDO_ID)
                                          and SZSGNME_TERM_NRC=c.SZTCGDO_TERM_NRC

                                          )loop

                                                 begin

                                                   select count(GOZTPAC_PIN),GOZTPAC_ID
                                                   into l_cont,l_matricula
                                                   from GOZTPAC
                                                   where 1 = 1
                                                   and GOZTPAC_PIDM  =c.SZTCGDO_PIDM
                                                   and GOZTPAC_STAT_IND='1'
                                                   GROUP BY GOZTPAC_ID
                                                    ;

                                                exception when others then
                                                  l_retorna:='No se encontro matricula en GOZTPAC  '||sqlerrm;
                                                end;
                                                  dbms_output.put_line('Grupo '||d.SZSGNME_TERM_NRC);

                                             if  l_cont>= 1 then

                                                begin

                                                   select GOZTPAC_PIN
                                                    into l_pwd
                                                   from GOZTPAC pac
                                                   where 1 = 1
                                                   and pac.GOZTPAC_PIDM  =c.SZTCGDO_PIDM
                                                   and GOZTPAC_PIN is not null
                                                   and rownum = 1;

                                                exception when others then
                                                  l_retorna:='No se encontro la contraseña '||sqlerrm;
                                                end;

                                                begin

                                                    select max(SZSGNME_SEQ_NO)+1
                                                    into l_secuencia
                                                    from SZSGNME
                                                    where 1 = 1
                                                    and SZSGNME_TERM_NRC=c.SZTCGDO_TERM_NRC;
--                                                    and SZSGNME_no_regla = c.SZTCGDO_NO_REGLA
--                                                    AND SZSGNME_PIDM=c.SZTCGDO_PIDM;

                                                exception when others then
                                                    null;
                                                end;



                                                begin

                                                    update SZSGNME
                                                    set SZSGNME_FCST_CODE='IN'
                                                    where 1=1
                                                    AND SZSGNME_NO_REGLA=P_REGLA
                                                    and SZSGNME_PIDM=FGET_PIDM(C.SZTCGDO_ID)
                                                    and SZSGNME_TERM_NRC=c.SZTCGDO_TERM_NRC;

                                                    INSERT INTO SZSGNME VALUES(d.SZSGNME_TERM_NRC,
                                                                               c.SZTCGDO_PIDM,
                                                                               sysdate,
                                                                               user,
                                                                               '0',
                                                                               null,
                                                                               l_pwd,
                                                                               null,
                                                                               'AC',
                                                                               l_secuencia,
                                                                               null,
                                                                               d.SZSGNME_PTRM,
                                                                               d.SZSGNME_START_DATE,
                                                                               d.SZSGNME_no_regla,
                                                                               l_secuencia,
                                                                               1, d.szsgnme_idioma
                                                                               );



                                                exception when others then
                                                    l_retorna:='No se puede insertar  '||sqlerrm;
                                                end;

                                                IF l_retorna ='EXITO' then

                                                    begin

                                                        update SZTCGDO set SZTCGDO_PROCESADO='S'
                                                        where 1 = 1
                                                        and SZTCGDO_no_regla = c.SZTCGDO_NO_REGLA
                                                        and SZTCGDO_TERM_NRC = c.SZTCGDO_TERM_NRC;

                                                    exception when others then
                                                        null;
                                                    end;

                                                else

                                                    begin

                                                        update SZTCGDO set SZTCGDO_ERROR= l_retorna
                                                        where 1 = 1
                                                        and SZTCGDO_no_regla = c.SZTCGDO_NO_REGLA
                                                        and SZTCGDO_TERM_NRC = c.SZTCGDO_TERM_NRC;

                                                    exception when others then
                                                        null;
                                                    end;


                                                end if;

                                             else

                                             l_retorna:='NINGUNA CONTRASEÑA ENCONTRADA PARA ESTE DOCENTE'||' '||l_matricula;

                                             end if;

                                          end loop;
                            else

                                begin

                                    update SZTCGDO set SZTCGDO_ERROR= 'No existe docente para cambiar'
                                    where 1 = 1
                                    and SZTCGDO_no_regla = c.SZTCGDO_NO_REGLA
                                    and SZTCGDO_TERM_NRC = c.SZTCGDO_TERM_NRC;

                                exception when others then
                                    null;
                                end;
                            end if;

                       END LOOP;
            commit;

             return(l_retorna);

    end;

end;
/

DROP PUBLIC SYNONYM PKG_CAMBIO_GRUPO;

CREATE OR REPLACE PUBLIC SYNONYM PKG_CAMBIO_GRUPO FOR BANINST1.PKG_CAMBIO_GRUPO;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_CAMBIO_GRUPO TO PUBLIC;
