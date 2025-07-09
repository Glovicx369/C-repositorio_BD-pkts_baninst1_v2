DROP PACKAGE BODY BANINST1.PKG_PAQUETES_DINAMICOS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_PAQUETES_DINAMICOS IS
--
--N
    FUNCTION F_BAJA_DOMI(P_PIDM  NUMBER, P_BANDERA NUMBER ,p_user varchar2)  return varchar2 IS
    L_CONTAR NUMBER;
    L_SP     NUMBER;
    L_RETORNA VARCHAR2(100);


       BEGIN


               BEGIN
                      SELECT COUNT(*)
                      INTO L_CONTAR
                      FROM goradid
                      where 1=1
                      AND GORADID_PIDM=P_pidm
                      and GORADID_ADID_CODE IN (select ZSTPARA_PARAM_ID
                                                 FROM ZSTPARA
                                                 WHERE 1=1
                                                 AND ZSTPARA_MAPA_ID = 'PORCENTAJE_DOM');

               EXCEPTION WHEN OTHERS THEN

                NULL;

               END;

               IF L_CONTAR>0 THEN

                   BEGIN

                      SELECT DISTINCT
                           cur.sorlcur_key_seqno
                           into l_sp
                      FROM sorlcur cur
                      WHERE     1 = 1
                      AND cur.sorlcur_pidm = p_pidm
                      AND cur.sorlcur_lmod_code = 'LEARNER'
                      AND cur.sorlcur_roll_ind = 'Y'
                      AND cur.sorlcur_cact_code = 'ACTIVE'
                      AND cur.sorlcur_seqno =(SELECT MAX (aa1.sorlcur_seqno)
                                              FROM sorlcur aa1
                                              WHERE cur.sorlcur_pidm = aa1.sorlcur_pidm
                                              AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
                                              AND cur.sorlcur_roll_ind = aa1.sorlcur_roll_ind
                                              AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code);

                   EXCEPTION WHEN OTHERS THEN

                   L_SP := 1;

                   END;

                   L_RETORNA:=BANINST1.PKG_ABCC.F_BITACORA_ABCC ('BAJA_DOMI',L_SP,P_PIDM, NULL,p_user);

                   IF  L_RETORNA='EXITO'THEN

                       L_RETORNA:=NULL;

                       L_RETORNA:=BANINST1.PKG_DATOS_ACADEMICOS.F_BORRA_ETIQUETAS_DOM ( P_PIDM,p_bandera,p_user);

                   END IF;

               END IF;

          RETURN L_RETORNA;


       END F_BAJA_DOMI;

--
--
    PROCEDURE f_paquete_dinamico(p_regla  number, p_pidm number)
    is
        l_retorna varchar2(500):='EXITO';
        l_contar  number;
        l_avance_mayor    number;
        l_avance          number;
        l_pidm_mayor      number;
        l_materia_alianza varchar2(10):=NULL;
        l_cuenta_nivel_li     number;
        l_cuenta_nivel_ma     number;
        l_cuenta_nivel_do     number;
        l_nivel           varchar2(1);
        l_secuencia       number;
        l_contador        number:=0;
        l_contar_alumnos  number;
        l_materias_para   number;
        l_materias_alianza number;
        l_cuenta_materias number;
        l_si_unicef       number;
        l_peirod_uni      varchar2(2);
        l_cuenta_szstume  number;
        l_cuenta_almt     number;
        l_resulta_cancel  number;
    begin


       -- raise_application_error (-20002,' Uno ');
        begin

            select count(*)
            into l_cuenta_nivel_li
            from sztalgo
            where 1 = 1
            and sztalgo_no_regla = p_regla
            and SZTALGO_LEVL_CODE ='LI';


        exception when others then
            null;
        end;

        begin

            select count(*)
            into l_cuenta_nivel_ma
            from sztalgo
            where 1 = 1
            and sztalgo_no_regla = p_regla
            and SZTALGO_LEVL_CODE ='MA';


        exception when others then
            null;
        end;

        begin

            select count(*)
            into l_cuenta_nivel_do
            from sztalgo
            where 1 = 1
            and sztalgo_no_regla = p_regla
            and SZTALGO_LEVL_CODE ='DO';


        exception when others then
            null;
        end;

        IF l_cuenta_nivel_li > 0 and l_cuenta_nivel_ma = 0 and l_cuenta_nivel_do = 0 Then

            l_nivel :='L';

        elsif l_cuenta_nivel_li = 0 and l_cuenta_nivel_ma > 0 and l_cuenta_nivel_do = 0 Then

            l_nivel :='M';

        elsif l_cuenta_nivel_li = 0 and l_cuenta_nivel_ma = 0 and l_cuenta_nivel_do > 0 Then

            l_nivel :='D';

        end  if;


        delete sztalian
        where 1 = 1
        and sztalian_no_regla = p_regla
        and sztalian_pidm = p_pidm
        AND sztalian_FLEX ='PD';

        begin

            select count(*)
            into l_contar
            from tztpadi
            join sztprono on sztprono_pidm = TZTPADI_PIDM
                         and sztprono_no_regla = p_regla
            where 1 = 1
            and tztpadi_pidm = p_pidm
            AND  TZTPADI_FLAG ='0';

        exception when others then
            null;
        end;

        if l_contar > 0 then

            --cancelación en este punto para que no entre al cursor que asigne materias

            for d in (SELECT DISTINCT SZTPDMA_ALIANZA alianza,
                                      tztpadi_pidm pidm
                      FROM sztpdma
                      JOIN tztpadi on sztpdma_detail_coode = tztpadi_detail_code
                      AND tztpadi_pidm = p_pidm
                      AND  TZTPADI_FLAG ='0'
                      )loop


                          BEGIN

                              -- contamos la configuración de materias
                              SELECT COUNT(DISTINCT sztalmt_materia)
                              INTO l_cuenta_almt
                              FROM sztalmt
                              WHERE 1 = 1
                              and sztalmt_alianza = d.alianza;

                          exception when others then
                              null;
                          end;

                          --contamos el total de materias que se a cursado

                          BEGIN

                            SELECT COUNT(DISTINCT szstume_subj_code)
                            INTO l_cuenta_szstume
                            FROM szstume
                            WHERE 1 = 1
                            AND szstume_pidm = d.pidm
                            AND EXISTS(SELECT NULL
                                       FROM sztalmt
                                       WHERE 1 = 1
                                       AND sztalmt_alianza = d.alianza
                                       AND sztalmt_materia = szstume_subj_code);

                          EXCEPTION WHEN OTHERS THEN
                              NULL;
                          END;

                          -- verificamos la diferencia para ver si cancelamos

                          l_resulta_cancel:= l_cuenta_almt-l_cuenta_szstume;

                          -- Si ya no tiene materias se cancela el paquete dinamico

                          if l_resulta_cancel < 1 then


                              BEGIN

                                UPDATE tztpadi set   TZTPADI_FLAG ='1'
                                WHERE 1 = 1
                                AND EXISTS (SELECT NULL
                                            FROM sztpdma
                                            WHERE 1 = 1
                                            AND sztpdma_detail_coode = tztpadi_detail_code
                                            AND sztpdma_alianza = d.alianza)
                                AND  TZTPADI_FLAG ='0'
                                AND tztpadi_pidm = p_pidm;

                              EXCEPTION WHEN OTHERS THEN
                                 NULL;
                              END;

                          end if;

                      end loop;


            for c in (SELECT DISTINCT SZTPDMA_ALIANZA alianza,
                                      tztpadi_pidm pidm
                      FROM sztpdma
                      JOIN tztpadi on sztpdma_detail_coode = tztpadi_detail_code
                      AND tztpadi_pidm = p_pidm
                      AND  TZTPADI_FLAG ='0'
                      )loop



                        for d in (
                                  select *
                                    from (
                                    select distinct (select  SUBSTR(SMRPRLE_PROGRAM_DESC,1,1)||lower(SUBSTR(SMRPRLE_PROGRAM_DESC,1,100))
                                                    from SMRPRLE
                                                    where 1 = 1
                                                    and SMRPRLE_PROGRAM = SZTPRONO_PROGRAM) nombre,
                                                    SZTPRONO_PROGRAM programa,
                                                    sztprono_pidm pidm,
                                                    sztprono_id matricula,
                                                    SZTPRONO_CUATRI||','||SZTPRONO_PTRM_CODE_NW avance,
                                                    SZTPRONO_TIPO_INICIO tipo_inicio,
                                                    sztprono_no_regla regla
                                    from sztprono
                                    where 1 = 1
                                    and sztprono_no_regla = p_regla
                                    and sztprono_pidm = c.pidm
                                    )
                                    where 1 = 1
                                  )loop

                                        dbms_output.put_line('Alianza '||c.alianza);

--                                        raise_application_error (-20002,' Uno ');

                                        begin

                                          SELECT MAX(zstpara_param_id)
                                          INTO l_avance
                                          FROM ZSTPARA
                                          WHERE 1 = 1
                                          and zstpara_mapa_id ='INSCRIPCIONES'
                                          and zstpara_param_valor = d.avance
                                          and zstpara_param_desc = d.tipo_inicio;

                                        exception when others then
                                            null;
                                        end;

                                        BEGIN


                                           dbms_output.put_line (' PImd '||d.pidm||' Matricula '||d.matricula||'  Alianza '||c.alianza||' Avance '||l_avance||' Regla '||d.regla||' materias para '||l_materias_para||' matereias alianza '||l_materias_alianza||' Tipo Inicio '||d.tipo_inicio);

                                          INSERT INTO sztalian VALUES (d.pidm,
                                                                       d.matricula,
                                                                       d.programa,
                                                                       c.alianza,
                                                                       l_avance,
                                                                       d.regla,
                                                                       'N',
                                                                       nvl(l_materias_para,0),
                                                                       nvl(l_materias_alianza,0),
                                                                       d.tipo_inicio,
                                                                       'PD'
                                                                       );

                                        EXCEPTION WHEN OTHERS THEN
                                         NULL;
                                        END;

                                       COMMIT;

                                  END LOOP;

                      END LOOP;


                      FOR c IN (SELECT *
                               FROM sztalian
                               where 1 = 1
                               AND sztalian_flex ='PD'
                               AND sztalian_no_regla = p_regla
                               AND sztalian_pidm = p_pidm
                              )loop

                                  if c.SZTALIAN_ALIANZA ='UNIC' then

                                    begin

                                         pkg_alianzas.p_unic_pidm(p_regla,p_pidm);

                                    end;


                                  elsif c.SZTALIAN_ALIANZA ='MUBA' then

                                    begin

                                         pkg_alianzas.p_muba_pidm(p_regla,p_pidm);

                                    end;


                                  elsif c.SZTALIAN_ALIANZA ='IEBS' then

                                    begin

                                         pkg_alianzas.p_iebs_pidm(p_regla,p_pidm);

                                    end;


                                  elsif c.SZTALIAN_ALIANZA ='FCBK' then

                                    begin

                                         pkg_alianzas.p_fcbk_pidm(p_regla,p_pidm);

                                    end;

                                  elsif c.SZTALIAN_ALIANZA ='COLL' then

                                    begin

                                         pkg_alianzas.p_coll_pidm(p_regla,p_pidm);

                                    end;



                                  elsif c.SZTALIAN_ALIANZA ='SENI' then

                                     begin

                                         pkg_alianzas.p_ssen_pidm(p_regla,p_pidm);

                                    end;

                                  elsif c.SZTALIAN_ALIANZA ='CESA' then

                                    begin

                                         pkg_alianzas.p_cesa_pidm(p_regla,p_pidm);

                                    end;


                                  elsif c.SZTALIAN_ALIANZA ='COUR' then

                                    begin

                                         pkg_alianzas.p_cour_pidm(p_regla,p_pidm);

                                    end;

                                  end if;

                              end loop;


        end if;

    end f_paquete_dinamico;
--
--
    FUNCTION F_ELIMNINA_ETQ (P_PIDM NUMBER,p_detail_code varchar2 )
    return varchar2
    IS
        l_retorna varchar2(500):='EXITO';
        l_contar  number;
        L_ETIQUETA VARCHAR2(30);
    begin

        begin

               SELECT COUNT(*),
               GORADID_ADID_CODE
                   into l_contar,
                   L_ETIQUETA
                 FROM(
                       select *
                        from goradid
                        where 1 = 1
                        and goradid_pidm =p_pidm
                        and exists(select null
                                   from SZTPDMA
                                   where 1 = 1
                                   and  GORADID_ADID_CODE = SZTPDMA_ALIANZA
                                   and  SZTPDMA_DETAIL_COODE =p_detail_code)
                         UNION
                            select *
                        from goradid
                        where 1 = 1
                        and goradid_pidm =p_pidm
                        and exists( select null
                                   from ZSTPARA
                                    where 1=1
                                    AND GORADID_ADID_CODE=ZSTPARA_PARAM_VALOR
                                    AND ZSTPARA_PARAM_ID=substr(p_detail_code,3,2)))
                 GROUP BY GORADID_ADID_CODE;


        exception when others then
            null;
        end;

        if l_contar > 0 then

            begin

                delete
                from goradid
                where 1 = 1
                and goradid_pidm = p_pidm
                and GORADID_ADID_CODE=L_ETIQUETA;

            exception when others then
                l_retorna:='No se puede eliminar goradid del alumno pidm '||p_pidm;
            end;


        else

            l_retorna:='No hay alumnos para este codigo de detalle';


        end if;


        return l_retorna;
    end;
--
--
    function f_bitacora_abcc_pd ( p_evento varchar2,
                                 p_sp number,
                                 p_pidm number,
                                 p_estatus varchar2,
                                 p_user varchar2,
                                 p_detail_code varchar2 )
      return varchar2
      IS
      l_retorna varchar2(200):='EXITO';
      l_max_sgrscmt number;
      l_descripcion varchar2(2000);
      l_maximor_horarios varchar2(20);
      l_contador number:=0;
      l_cuenta_alianza number;
      l_codigo_alianza varchar2(500);
      l_desc_alianza   varchar2(500);

    BEGIN

        dbms_output.put_line('entra 1');

        Begin

          SELECT NVL(MAX(a.SGRSCMT_SEQ_NO),0)+1
          INTO l_max_sgrscmt
          FROM  SGRSCMT a
          WHERE a.SGRSCMT_PIDM  = p_pidm
          AND a.SGRSCMT_TERM_CODE = (SELECT MAX (a1.SGRSCMT_TERM_CODE)
                                     FROM SGRSCMT a1
                                     WHERE a1.SGRSCMT_PIDM = a.SGRSCMT_PIDM
                                     and a1.SGRSCMT_TERM_CODE  = a.SGRSCMT_TERM_CODE);

        Exception  When Others then
            l_max_sgrscmt :=1;
        End;

        l_contador:=0;

        dbms_output.put_line('entra 2 -->'||l_contador);

        for c in (SELECT DISTINCT cur.sorlcur_pidm pidm,
                                  cur.sorlcur_start_date fecha_inicio,
                                  cur.sorlcur_key_seqno sp,
                                  sorlcur_program programa,
                                  SORLCUR_TERM_CODE matriculacion
                    FROM sorlcur cur
                    WHERE     1 = 1
                    and cur.sorlcur_pidm = p_pidm
                    AND cur.sorlcur_lmod_code = 'LEARNER'
                    AND cur.sorlcur_roll_ind = 'Y'
                    AND cur.sorlcur_cact_code = 'ACTIVE'
                    AND cur.sorlcur_seqno =
                                           (SELECT MAX (aa1.sorlcur_seqno)
                                            FROM sorlcur aa1
                                            WHERE     cur.sorlcur_pidm = aa1.sorlcur_pidm
                                            AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
                                            AND cur.sorlcur_roll_ind = aa1.sorlcur_roll_ind
                                            AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code)
                   )loop

                      l_contador:=l_contador+1;

                    dbms_output.put_line('entra 3 for x--> '||l_contador);

                       begin
                           INSERT INTO SGBSTDB
                           SELECT N.*,c.FECHA_INICIO, l_max_sgrscmt, c.sp
                           FROM SGBSTDN N
                           where 1 = 1
                           AND n.sgbstdn_pidm=c.pidm
                           and n.sgbstdn_program_1=c.programa
                           AND n.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                           FROM sgbstdn a1
                                                           WHERE a1.sgbstdn_pidm = n.sgbstdn_pidm
                                                           and a1.sgbstdn_program_1  = n.sgbstdn_program_1
                                                                                            );
                       exception when others then
                            l_retorna:='No se puede insertar SGBSTDB '||sqlerrm;
                       end;

                       dbms_output.put_line('entra 4');

                       if l_retorna ='EXITO' then

                           dbms_output.put_line('entra 5');


                           if p_evento ='ELIMINA_ETIQUETA' then

                                begin

                                  SELECT COUNT(*)
                                         INTO l_cuenta_alianza
                                             FROM(
                                                   select *
                                                    from goradid
                                                    where 1 = 1
                                                    and goradid_pidm =p_pidm
                                                    and exists(select null
                                                               from SZTPDMA
                                                               where 1 = 1
                                                               and  GORADID_ADID_CODE = SZTPDMA_ALIANZA
                                                               and  SZTPDMA_DETAIL_COODE =p_detail_code)
                                                     UNION
                                                        select *
                                                    from goradid
                                                    where 1 = 1
                                                    and goradid_pidm =p_pidm
                                                    and exists( select null
                                                               from ZSTPARA
                                                                where 1=1
                                                                AND GORADID_ADID_CODE=ZSTPARA_PARAM_VALOR
                                                                AND ZSTPARA_PARAM_ID=substr(p_detail_code,3,2)))
                                                GROUP BY GORADID_ADID_CODE
                                ;




                                EXCEPTION WHEN OTHERS THEN
                                    NULL;
                                END;


                                l_descripcion:=UPPER('Cancelación de Alianza: '||l_desc_alianza||' Codigo de detalle '||p_detail_code||' Usuario '||p_user||' Fecha '||Sysdate);

                           end if;

                           dbms_output.put_line('entra 5 '||l_descripcion);

                           BEGIN
                                select max(SFRSTCR_TERM_CODE)
                                into l_maximor_horarios
                                from  SFRSTCR a
                                where 1 = 1
                                and A.SFRSTCR_PIDM = c.pidm
                                and A.SFRSTCR_STSP_KEY_SEQUENCE = p_sp
                                and substr (a.SFRSTCR_TERM_CODE,5,1)<>8
                                and A.SFRSTCR_TERM_CODE =(select max(a1.SFRSTCR_TERM_CODE)
                                                        from  SFRSTCR a1
                                                        where 1 = 1
                                                        AND A.SFRSTCR_PIDM = a1.SFRSTCR_PIDM
                                                        and A.SFRSTCR_STSP_KEY_SEQUENCE  = a1.SFRSTCR_STSP_KEY_SEQUENCE
                                                        and substr (a1.SFRSTCR_TERM_CODE,5,1)<>8
                                                        );
                           EXCEPTION WHEN OTHERS THEN
                            NULL;
                           END;

                           IF l_maximor_horarios IS NULL THEN

                              l_maximor_horarios:=c.matriculacion;

                           END IF;

                           dbms_output.put_line('entra descripcion '||l_descripcion||' for '||l_contador||' Cuenta alianza '||l_cuenta_alianza);


                           if l_cuenta_alianza > 0  then

                               BEgin

                                    INSERT INTO SGRSCMT (
                                       SGRSCMT_PIDM
                                   , SGRSCMT_SEQ_NO
                                   , SGRSCMT_TERM_CODE
                                   , SGRSCMT_COMMENT_TEXT
                                   , SGRSCMT_ACTIVITY_DATE
                                   , SGRSCMT_DATA_ORIGIN
                                   , SGRSCMT_USER_ID
                                   , SGRSCMT_VPDI_CODE
                                    )
                                    VALUES (
                                       c.pidm
                                     , l_max_sgrscmt
                                     , l_maximor_horarios
                                     , l_descripcion
                                     , SYSDATE
                                     , 'SZFABCC_V2'
                                     , user
                                     ,C.SP
                                    );
                               Exception when Others then
                                    l_retorna:= ('Error Bitacora3 '||sqlerrm);
                               End;

                           end if;


                       end if;

                        exit when l_contador = 1;

                   END LOOP;

                   return l_retorna;


    END;


   PROCEDURE f_VALIDA_DOMI (P_PIDM NUMBER  default null )
   
   as
   
   Begin
   
            For cx in (
            
                        select *
                        from Sztdomi a
                        where 1=1
                        And a.SZTDOMI_PIDM = nvl (P_PIDM , a.SZTDOMI_PIDM)
                        And a.SZTDOMI_PIDM in (select b.pidm
                                     from tztprog b
                                     where 1=1
                                     And b.estatus in ('EG', 'MA')
                                     And b.sp in (select max (b1.sp)
                                                    from tztprog b1
                                                    Where b.pidm = b1.pidm )
                                     )
   
            ) loop
            
            
                Begin
                    Delete Sztdomi
                    where SZTDOMI_PIDM = cx.SZTDOMI_PIDM;
                    Commit;
                Exception
                    When Others then 
                        null;
                End;
                
                Begin
                    Insert into goradid                 
                    SELECT GZTADID_GORA_PIDM, GZTADID_GORA_ADDIOTIONAL_ID, GZTADID_GORA_ADID_CODE, GZTADID_GORA_USER_ID, GZTADID_GORA_ACTIVITY_DATE, GZTADID_GORA_DATA_ORIGIN, null, GZTADID_GORA_VERSION, GZTADID_GORA_VPDI_CODE
                    FROM GZTADID
                    WHERE 1=1
                    AND GZTADID_GORA_PIDM = cx.SZTDOMI_PIDM
                    And GZTADID_ACCION = 'DELETE'
                    And GZTADID_GORA_ADDIOTIONAL_ID like 'DOMI%' 
                    UNION
                    SELECT GZTADID_GORA_PIDM, GZTADID_GORA_ADDIOTIONAL_ID, GZTADID_GORA_ADID_CODE, GZTADID_GORA_USER_ID, GZTADID_GORA_ACTIVITY_DATE, GZTADID_GORA_DATA_ORIGIN, null, GZTADID_GORA_VERSION, GZTADID_GORA_VPDI_CODE
                    FROM GZTADID
                    WHERE 1=1
                    AND GZTADID_GORA_PIDM = cx.SZTDOMI_PIDM
                    And GZTADID_ACCION = 'DELETE'
                    And GZTADID_GORA_ADDIOTIONAL_ID like 'DESC%' ;
                    Commit;
                Exception
                    When others then
                        null;
                End;
                
                
            
            End Loop;
            Commit;
   
   End f_VALIDA_DOMI;   
--
--
--
--
    FUNCTION F_ELIMNINA_ETQ_face (P_PIDM NUMBER,p_detail_code varchar2 )
    return varchar2
    IS
        l_retorna varchar2(500):='EXITO';
        l_contar  number;
        L_ETIQUETA VARCHAR2(30);
    begin

        begin

               SELECT COUNT(*),
               GORADID_ADID_CODE
                   into l_contar,
                   L_ETIQUETA
                 FROM(
                       select *
                        from goradid
                        where 1 = 1
                        and goradid_pidm =p_pidm
                        and exists(select null
                                   from SZTPDMA
                                   where 1 = 1
                                   and  GORADID_ADID_CODE = SZTPDMA_ALIANZA
                                   and  SZTPDMA_DETAIL_COODE =p_detail_code)
                         UNION
                            select *
                        from goradid
                        where 1 = 1
                        and goradid_pidm =p_pidm
                        and exists( select null
                                   from ZSTPARA
                                    where 1=1
                                    AND GORADID_ADID_CODE=ZSTPARA_PARAM_VALOR
                                    AND ZSTPARA_PARAM_ID=substr(p_detail_code,3,2)))
                 GROUP BY GORADID_ADID_CODE;


        exception when others then
            null;
        end;

        if l_contar > 0 then

            begin

                delete
                from goradid
                where 1 = 1
                and goradid_pidm = p_pidm
                and GORADID_ADID_CODE=L_ETIQUETA;

            exception when others then
                l_retorna:='No se puede eliminar goradid del alumno pidm '||p_pidm;
            end;


        else

            l_retorna:='No hay alumnos para este codigo de detalle';


        end if;


        return l_retorna;
    end F_ELIMNINA_ETQ_face;
--
--
    function f_bitacora_abcc_pd_face ( p_evento varchar2,
                                 p_sp number,
                                 p_pidm number,
                                 p_estatus varchar2,
                                 p_user varchar2,
                                 p_detail_code varchar2 )
      return varchar2
      IS
      l_retorna varchar2(200):='EXITO';
      l_max_sgrscmt number;
      l_descripcion varchar2(2000);
      l_maximor_horarios varchar2(20);
      l_contador number:=0;
      l_cuenta_alianza number;
      l_codigo_alianza varchar2(500);
      l_desc_alianza   varchar2(500);

    BEGIN

        dbms_output.put_line('entra 1');

        Begin

          SELECT NVL(MAX(a.SGRSCMT_SEQ_NO),0)+1
          INTO l_max_sgrscmt
          FROM  SGRSCMT a
          WHERE a.SGRSCMT_PIDM  = p_pidm
          AND a.SGRSCMT_TERM_CODE = (SELECT MAX (a1.SGRSCMT_TERM_CODE)
                                     FROM SGRSCMT a1
                                     WHERE a1.SGRSCMT_PIDM = a.SGRSCMT_PIDM
                                     and a1.SGRSCMT_TERM_CODE  = a.SGRSCMT_TERM_CODE);

        Exception  When Others then
            l_max_sgrscmt :=1;
        End;

        l_contador:=0;

        dbms_output.put_line('entra 2 -->'||l_contador);

        for c in (SELECT DISTINCT cur.sorlcur_pidm pidm,
                                  cur.sorlcur_start_date fecha_inicio,
                                  cur.sorlcur_key_seqno sp,
                                  sorlcur_program programa,
                                  SORLCUR_TERM_CODE matriculacion
                    FROM sorlcur cur
                    WHERE     1 = 1
                    and cur.sorlcur_pidm = p_pidm
                    AND cur.sorlcur_lmod_code = 'LEARNER'
                    AND cur.sorlcur_roll_ind = 'Y'
                    AND cur.sorlcur_cact_code = 'ACTIVE'
                    AND cur.sorlcur_seqno =
                                           (SELECT MAX (aa1.sorlcur_seqno)
                                            FROM sorlcur aa1
                                            WHERE     cur.sorlcur_pidm = aa1.sorlcur_pidm
                                            AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
                                            AND cur.sorlcur_roll_ind = aa1.sorlcur_roll_ind
                                            AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code)
                   )loop

                      l_contador:=l_contador+1;

                    dbms_output.put_line('entra 3 for x--> '||l_contador);

                       begin
                           INSERT INTO SGBSTDB
                           SELECT N.*,c.FECHA_INICIO, l_max_sgrscmt, c.sp
                           FROM SGBSTDN N
                           where 1 = 1
                           AND n.sgbstdn_pidm=c.pidm
                           and n.sgbstdn_program_1=c.programa
                           AND n.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                           FROM sgbstdn a1
                                                           WHERE a1.sgbstdn_pidm = n.sgbstdn_pidm
                                                           and a1.sgbstdn_program_1  = n.sgbstdn_program_1
                                                                                            );
                       exception when others then
                            l_retorna:='No se puede insertar SGBSTDB '||sqlerrm;
                       end;

                       dbms_output.put_line('entra 4');

                       if l_retorna ='EXITO' then

                           dbms_output.put_line('entra 5');


                           if p_evento ='ELIMINA_ETIQUETA' then

                                begin

                                  SELECT COUNT(*)
                                         INTO l_cuenta_alianza
                                             FROM(
                                                   select *
                                                    from goradid
                                                    where 1 = 1
                                                    and goradid_pidm =p_pidm
                                                    and exists(select null
                                                               from SZTPDMA
                                                               where 1 = 1
                                                               and  GORADID_ADID_CODE = SZTPDMA_ALIANZA
                                                               and  SZTPDMA_DETAIL_COODE =p_detail_code)
                                                     UNION
                                                        select *
                                                    from goradid
                                                    where 1 = 1
                                                    and goradid_pidm =p_pidm
                                                    and exists( select null
                                                               from ZSTPARA
                                                                where 1=1
                                                                AND GORADID_ADID_CODE=ZSTPARA_PARAM_VALOR
                                                                AND ZSTPARA_PARAM_ID=substr(p_detail_code,3,2)))
                                                GROUP BY GORADID_ADID_CODE
                                ;




                                EXCEPTION WHEN OTHERS THEN
                                    NULL;
                                END;


                                l_descripcion:=UPPER('Cancelación de Alianza: '||l_desc_alianza||' Codigo de detalle '||p_detail_code||' Usuario '||p_user||' Fecha '||Sysdate);

                           end if;

                           dbms_output.put_line('entra 5 '||l_descripcion);

                           BEGIN
                                select max(SFRSTCR_TERM_CODE)
                                into l_maximor_horarios
                                from  SFRSTCR a
                                where 1 = 1
                                and A.SFRSTCR_PIDM = c.pidm
                                and A.SFRSTCR_STSP_KEY_SEQUENCE = p_sp
                                and substr (a.SFRSTCR_TERM_CODE,5,1)<>8
                                and A.SFRSTCR_TERM_CODE =(select max(a1.SFRSTCR_TERM_CODE)
                                                        from  SFRSTCR a1
                                                        where 1 = 1
                                                        AND A.SFRSTCR_PIDM = a1.SFRSTCR_PIDM
                                                        and A.SFRSTCR_STSP_KEY_SEQUENCE  = a1.SFRSTCR_STSP_KEY_SEQUENCE
                                                        and substr (a1.SFRSTCR_TERM_CODE,5,1)<>8
                                                        );
                           EXCEPTION WHEN OTHERS THEN
                            NULL;
                           END;

                           IF l_maximor_horarios IS NULL THEN

                              l_maximor_horarios:=c.matriculacion;

                           END IF;

                           dbms_output.put_line('entra descripcion '||l_descripcion||' for '||l_contador||' Cuenta alianza '||l_cuenta_alianza);


                           if l_cuenta_alianza > 0  then

                               BEgin

                                    INSERT INTO SGRSCMT (
                                       SGRSCMT_PIDM
                                   , SGRSCMT_SEQ_NO
                                   , SGRSCMT_TERM_CODE
                                   , SGRSCMT_COMMENT_TEXT
                                   , SGRSCMT_ACTIVITY_DATE
                                   , SGRSCMT_DATA_ORIGIN
                                   , SGRSCMT_USER_ID
                                   , SGRSCMT_VPDI_CODE
                                    )
                                    VALUES (
                                       c.pidm
                                     , l_max_sgrscmt
                                     , l_maximor_horarios
                                     , l_descripcion
                                     , SYSDATE
                                     , 'SZFABCC_V2'
                                     , user
                                     ,C.SP
                                    );
                               Exception when Others then
                                    l_retorna:= ('Error Bitacora3 '||sqlerrm);
                               End;

                           end if;


                       end if;

                        exit when l_contador = 1;

                   END LOOP;

                   return l_retorna;


    END f_bitacora_abcc_pd_face;



END PKG_PAQUETES_DINAMICOS;
/

DROP PUBLIC SYNONYM PKG_PAQUETES_DINAMICOS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_PAQUETES_DINAMICOS FOR BANINST1.PKG_PAQUETES_DINAMICOS;
