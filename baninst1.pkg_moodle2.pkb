DROP PACKAGE BODY BANINST1.PKG_MOODLE2;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_MOODLE2
IS

--FUNCION PARA DETONAR el demonio sync_courses RECUPERA LOS ID DE LOS CURSOS EN AV--
    FUNCTION f_moodle_ind (p_stat in varchar2)return Varchar2
    as

    vl_return Varchar2(250);

   begin

          if p_stat = '0' then

                vl_return:=0;

                begin
                 update SZTMDIN set SZTMDIN_STAT_IND = p_stat,SZTMDIN_USER = 'sync-'||user, SZTMDIN_ACTIVITY_DATE = sysdate;
                 --dbms_output.put_line(vl_return);
                 return(vl_return);
                 end;
                 commit;

          elsif  p_stat = 1 then

                -- begin
                  --  update SZTMDIN set SZTMDIN_STAT_IND = p_stat,SZTMDIN_USER = 'ord-'||user, SZTMDIN_ACTIVITY_DATE = sysdate;
                 --end;
                 --commit;

                 begin
                 SELECT SZTMDIN_STAT_IND
                 INTO vl_return
                 FROM SZTMDIN;
                 end;
          end if;
        return (vl_return);
   end f_moodle_ind ;


      FUNCTION f_moodle_ind_niv (p_stat in varchar2)return Varchar2
    AS

    vl_return Varchar2(250);

    BEGIN
        vl_return:= NULL;

        BEGIN


            IF p_stat = '0' THEN

             vl_return:=0;

             BEGIN
             UPDATE SZTMNIV SET SZTMNIV_STAT_IND = vl_return, SZTMNIV_USER = user, SZTMNIV_ACTIVITY_DATE = SYSDATE;
             END;

             --dbms_output.put_line(vl_return);

             -- ELSIF p_stat = 1 THEN

               --vl_return:=1;

             --dbms_output.put_line(vl_return);

           END IF;
           COMMIT;

           BEGIN
            SELECT SZTMNIV_STAT_IND
            INTO vl_return
            FROM SZTMNIV
            WHERE 1=1;
           END;

         return(vl_return);
         --dbms_output.put_line(vl_return);

        END;

    END f_moodle_ind_niv;


   --FUNCI”N  QUE ASIGNA EL ID  MOODLE DE LOS CURSOSO RECUPERADOS--
     FUNCTION f_moodle_ini (p_crse_id IN NUMBER, p_short_name IN VARCHAR2, p_servidor in varchar2)
      RETURN VARCHAR2
   AS
    --p_short_name Varchar2 (100):='MB019_0_0312_M1DJO114';
    --p_servidor varchar2(10):= '12';
    --p_crse_id number:= 2345;
    servidor_param varchar2(10);
    fecha_ini date;
    fecha_param date;
    vl_servidor varchar2(10);
    vl_msje Varchar2(200);
    vl_subj_maur   VARCHAR2 (100);
    vl_no_regla number:= 0;
    row_count number := 0;
    vl_idioma VARCHAR2 (1);

    BEGIN

      IF p_servidor = '12' THEN

           BEGIN
            SELECT DISTINCT SZTGPME_START_DATE
            INTO  fecha_ini
            FROM SZTGPME
            WHERE 1=1
            AND SZTGPME_CAMP_CODE NOT IN('EAF', 'FIL')
            AND SZTGPME_CRSE_MDLE_CODE = p_short_name;
            EXCEPTION WHEN OTHERS THEN
            vl_msje:='Error al obtener fecha_in -line:66:- '||sqlerrm;
           END;

           dbms_output.put_line(vl_msje);

          BEGIN

            SELECT  ZSTPARA_PARAM_ID, ZSTPARA_PARAM_VALOR
            INTO servidor_param, fecha_param
            FROM ZSTPARA
            WHERE 1=1
            AND ZSTPARA_PARAM_ID = p_servidor
            AND ZSTPARA_MAPA_ID = 'AV35';
            EXCEPTION WHEN OTHERS THEN
            vl_msje:='Error al obtener servidor_param y fecha_param -line:78:- '||sqlerrm;

          END;

          dbms_output.put_line(vl_msje);

           BEGIN

            SELECT DISTINCT SZTGPME_NO_REGLA
            INTO vl_no_regla
            FROM SZTGPME
            WHERE 1=1
            AND SZTGPME_CAMP_CODE NOT IN('EAF', 'FIL')
            AND SZTGPME_CRSE_MDLE_CODE = p_short_name;
            EXCEPTION WHEN OTHERS THEN
            vl_msje:='Error al obtener regla93 -line::- '||sqlerrm;

          END;
          
            begin
            SELECT DISTINCT SZTMAUR_ORIGEN
                    INTO vl_idioma
                    FROM SZTMAUR
                    WHERE 1= 1
                    And SZTMAUR_MACO_PADRE = (SELECT DISTINCT (SZTGPME_SUBJ_CRSE_COMP)
                                                FROM SZTGPME
                                                WHERE     SZTGPME_CRSE_MDLE_CODE = p_short_name
                                                AND SZTGPME_STAT_IND IS NOT NULL
                                                AND SZTGPME_NO_REGLA != 0
                                                AND SZTGPME_NO_REGLA = vl_no_regla)
                    AND SZTMAUR_ACTIVO ='S'
                    AND SZTMAUR_SZTURMD_ID = servidor_param;
               EXCEPTION WHEN OTHERS THEN
            vl_msje:='Error al obtener regla93 -line::- '||sqlerrm;

            END;

            --DBMS_OUTPUT.PUT_LINE('Recupera variables y compara variables con parametros');

            IF p_servidor = servidor_param and fecha_ini >= fecha_param then

               BEGIN
                    SELECT DISTINCT SZTMAUR_SZTURMD_ID, SZTMAUR_MACO_PADRE
                    INTO vl_servidor, vl_subj_maur
                    FROM SZTMAUR
                    WHERE 1= 1
                    And SZTMAUR_MACO_PADRE = (SELECT DISTINCT (SZTGPME_SUBJ_CRSE_COMP)
                                                FROM SZTGPME
                                                WHERE     SZTGPME_CRSE_MDLE_CODE = p_short_name
                                                AND SZTGPME_STAT_IND IS NOT NULL
                                                AND SZTGPME_NO_REGLA != 0
                                                AND SZTGPME_NO_REGLA = vl_no_regla)
                    AND SZTMAUR_ACTIVO ='S'
                    AND SZTMAUR_SZTURMD_ID = servidor_param;
               EXCEPTION WHEN OTHERS THEN
               vl_servidor:= Null ;
               END;

                --DBMS_OUTPUT.PUT_LINE('llega a Validar variables no nulas');

                   IF vl_servidor IS NOT NULL AND vl_subj_maur IS NOT NULL THEN
                   
                    
                     BEGIN

                        UPDATE SZTGPME
                        SET SZTGPME_CRSE_MDLE_ID = p_crse_id, SZTGPME_PTRM_CODE_COMP = vl_servidor, SZTGPME_ACTIVITY_DATE = SYSDATE
                        WHERE SZTGPME_CRSE_MDLE_CODE = p_short_name
                        AND SZTGPME_SUBJ_CRSE = vl_subj_maur
                        AND SZTGPME_STAT_IND IS NOT NULL
                        AND SZTGPME_GPMDLE_ID IS NULL
                        AND SZTGPME_CRSE_MDLE_ID IS NULL
                        AND DECODE (SZTGPME_IDIOMA,NULL,'N','I','I','E','E')= DECODE(vl_idioma,'N','E','I','I','E','E')
                        AND SZTGPME_CAMP_CODE NOT IN('EAF', 'FIL');

                        row_count := SQL%ROWCOUNT;

                        DBMS_OUTPUT.PUT_LINE('CUENTA REG: '|| SQL%ROWCOUNT);

                            IF row_count > 0 THEN
                              vl_msje := ('Registros afectados: '|| row_count||' '||'Para servidor:'|| vl_servidor);
                              --DBMS_OUTPUT.put_line (vl_msje);
                            ELSE
                                vl_msje := ('Registros afectados: '|| row_count);
                                --DBMS_OUTPUT.put_line (vl_msje);
                            END IF;


                       EXCEPTION
                       WHEN OTHERS
                       THEN
                       vl_msje := 'Error' || SQLERRM;
                     END;

                   END IF;
                   COMMIT;
                    DBMS_OUTPUT.PUT_LINE('RealizÛ el update');

           END IF;


      ELSIF p_servidor NOT IN ('22', '24', '49', '50') THEN

         BEGIN

                FOR c IN(

                        SELECT  distinct a.SZTGPME_NO_REGLA regla,DECODE (SZTGPME_IDIOMA,NULL,'N','I','I','E','N') idioma
--                        INTO vl_no_regla
                        FROM SZTGPME a
                        WHERE 1=1
                        AND a.SZTGPME_CRSE_MDLE_CODE = p_short_name
                        and a.SZTGPME_IDIOMA in(null,'E')
                        AND a.SZTGPME_CAMP_CODE NOT IN(SELECT SZVCAMP_CAMP_CODE
                                                       FROM SZVCAMP
                                                       WHERE 1=1
                                                       AND SZVCAMP_TRANS_CODE  ='EN')
                        AND a.SZTGPME_GRUPO = (SELECT MAX(a1.SZTGPME_GRUPO) FROM SZTGPME a1
                                               WHERE 1=1
                                               AND a1.SZTGPME_SUBJ_CRSE= a.SZTGPME_SUBJ_CRSE
                                               AND a1.SZTGPME_NO_REGLA = a.SZTGPME_NO_REGLA
                                               and a1.SZTGPME_IDIOMA in(null,'E')
                                               AND a1.SZTGPME_CRSE_MDLE_CODE = a.SZTGPME_CRSE_MDLE_CODE)
                )

                LOOP


                      dbms_output.put_line(vl_msje);

                       vl_servidor := Null;
                       vl_subj_maur := Null;

                       if C.regla=99 then
                       c.idioma:='E';
                       ELSE
                       c.idioma:=c.idioma;
                       END IF;
                       
                       BEGIN
                        SELECT DISTINCT SZTMAUR_SZTURMD_ID, SZTMAUR_MACO_PADRE,SZTMAUR_ORIGEN
                        INTO vl_servidor, vl_subj_maur,vl_idioma
                        FROM SZTMAUR
                        WHERE 1= 1
                        And SZTMAUR_MACO_PADRE = (SELECT DISTINCT (SZTGPME_SUBJ_CRSE_COMP)
                                                    FROM SZTGPME
                                                    WHERE SZTGPME_CRSE_MDLE_CODE = p_short_name
                                                    AND SZTGPME_STAT_IND IS NOT NULL
                                                    AND SZTGPME_NO_REGLA != 0
                                                    AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZTGPME_IDIOMA
                                                    AND SZTGPME_CAMP_CODE NOT IN(SELECT SZVCAMP_CAMP_CODE
                                                                               FROM SZVCAMP
                                                                               WHERE 1=1
                                                                               AND SZVCAMP_TRANS_CODE  ='EN')
                                                    AND SZTGPME_NO_REGLA = c.regla) -- vl_no_regla)
                        AND SZTMAUR_ACTIVO ='S'
                       AND SZTMAUR_ORIGEN=c.idioma
                        AND SZTMAUR_SZTURMD_ID = p_servidor;
                        EXCEPTION WHEN NO_DATA_FOUND THEN
                        vl_msje:='Error al obtener vl_servidor != 12 -line:260:- '||c.regla|| c.idioma||sqlerrm;
                       END;

                       dbms_output.put_line(vl_msje);
                       
                       

                         IF vl_servidor IS NOT NULL AND vl_subj_maur IS NOT NULL THEN

                             BEGIN

                                UPDATE SZTGPME
                                SET SZTGPME_CRSE_MDLE_ID = p_crse_id, SZTGPME_PTRM_CODE_COMP = vl_servidor,  SZTGPME_ACTIVITY_DATE = SYSDATE
                                WHERE SZTGPME_CRSE_MDLE_CODE = p_short_name
                                AND SZTGPME_SUBJ_CRSE = vl_subj_maur
                                AND SZTGPME_STAT_IND IS NOT NULL
                                AND SZTGPME_GPMDLE_ID IS NULL
                                AND SZTGPME_CRSE_MDLE_ID IS NULL
                                AND SZTGPME_NO_REGLA = c.regla
                                AND DECODE (SZTGPME_IDIOMA,NULL,'N','I','I','E','E')= DECODE(c.idioma,'N','E','I','I','E','E')
                                AND SZTGPME_CAMP_CODE NOT IN(SELECT SZVCAMP_CAMP_CODE
                                                             FROM SZVCAMP
                                                             WHERE 1=1
                                                             AND SZVCAMP_TRANS_CODE  ='EN');
                                row_count := SQL%ROWCOUNT;

                               --DBMS_OUTPUT.PUT_LINE('CUENTA REG: '|| row_count);

                                        IF SQL%ROWCOUNT > 0 THEN
                                          vl_msje := ('Registros afectados: '|| row_count||' '||'Para servidor:'|| vl_servidor);
                                          DBMS_OUTPUT.put_line (vl_msje);
                                        ELSE
                                            vl_msje := ('Registros afectados: '|| row_count);
                                            DBMS_OUTPUT.put_line (vl_msje);
                                        END IF;

                             EXCEPTION
                             WHEN OTHERS
                             THEN
                             vl_msje := 'Error' || SQLERRM;
                             END;

                         END IF;

                END LOOP;
                COMMIT;
         END;

      ELSIF p_servidor IN ('22', '24','49', '50') THEN

         BEGIN

                FOR c IN(

                        SELECT  distinct a.SZTGPME_NO_REGLA regla,DECODE (SZTGPME_IDIOMA,NULL,'N','I','I','E','E') idioma
                        --INTO vl_no_regla
                        FROM SZTGPME a
                        WHERE 1=1
                        AND a.SZTGPME_CRSE_MDLE_CODE = p_short_name
                        and a.SZTGPME_IDIOMA in('I')
                        AND a.SZTGPME_CAMP_CODE NOT IN(SELECT SZVCAMP_CAMP_CODE
                                                       FROM SZVCAMP
                                                       WHERE 1=1
                                                       AND SZVCAMP_TRANS_CODE  ='EN')
                        AND a.SZTGPME_GRUPO = (SELECT MAX(a1.SZTGPME_GRUPO) FROM SZTGPME a1
                                               WHERE 1=1
                                               AND a1.SZTGPME_SUBJ_CRSE= a.SZTGPME_SUBJ_CRSE
                                               AND a1.SZTGPME_NO_REGLA = a.SZTGPME_NO_REGLA
                                               and a1.SZTGPME_IDIOMA in('I')
                                               AND a1.SZTGPME_CRSE_MDLE_CODE = a.SZTGPME_CRSE_MDLE_CODE)
                )

                LOOP


                      dbms_output.put_line(vl_msje);

                       vl_servidor := Null;
                       vl_subj_maur := Null;

                       BEGIN
                        SELECT DISTINCT SZTMAUR_SZTURMD_ID, SZTMAUR_MACO_PADRE
                        INTO vl_servidor, vl_subj_maur
                        FROM SZTMAUR
                        WHERE 1= 1
                        And SZTMAUR_MACO_PADRE = (SELECT DISTINCT (SZTGPME_SUBJ_CRSE_COMP)
                                                    FROM SZTGPME
                                                    WHERE SZTGPME_CRSE_MDLE_CODE = p_short_name
                                                    AND SZTGPME_STAT_IND IS NOT NULL
                                                    AND SZTGPME_NO_REGLA != 0
                                                     AND SZTGPME_IDIOMA=c.idioma
                                                    AND SZTGPME_CAMP_CODE IN(SELECT SZVCAMP_CAMP_CODE
                                                                             FROM SZVCAMP
                                                                             WHERE 1=1
                                                                             AND SZVCAMP_TRANS_CODE ! ='EN')
                                                    AND SZTGPME_NO_REGLA = c.regla) -- vl_no_regla)
                        AND SZTMAUR_ACTIVO ='S'
                        AND SZTMAUR_SZTURMD_ID = p_servidor;
                        EXCEPTION WHEN NO_DATA_FOUND THEN
                        vl_msje:='Error al obtener vl_servidor != 12 -line:186:- '||sqlerrm;
                       END;

                       dbms_output.put_line(vl_msje);

                         IF vl_servidor IS NOT NULL AND vl_subj_maur IS NOT NULL THEN

                             BEGIN

                                UPDATE SZTGPME
                                SET SZTGPME_CRSE_MDLE_ID = p_crse_id, SZTGPME_PTRM_CODE_COMP = vl_servidor,  SZTGPME_ACTIVITY_DATE = SYSDATE
                                WHERE SZTGPME_CRSE_MDLE_CODE = p_short_name
                                AND SZTGPME_SUBJ_CRSE = vl_subj_maur
                                AND SZTGPME_STAT_IND IS NOT NULL
                                AND SZTGPME_GPMDLE_ID IS NULL
                                AND SZTGPME_CRSE_MDLE_ID IS NULL
                                AND SZTGPME_IDIOMA=C.idioma
                                AND SZTGPME_CAMP_CODE not IN(SELECT SZVCAMP_CAMP_CODE
                                                       FROM SZVCAMP
                                                       WHERE 1=1
                                                       AND SZVCAMP_TRANS_CODE  ='EN')
                                AND SZTGPME_NO_REGLA = c.regla;
                                row_count := SQL%ROWCOUNT;

                               --DBMS_OUTPUT.PUT_LINE('CUENTA REG: '|| row_count);

                                        IF SQL%ROWCOUNT > 0 THEN
                                          vl_msje := ('Registros afectados: '|| row_count||' '||'Para servidor:'|| vl_servidor);
                                          --DBMS_OUTPUT.put_line (vl_msje);
                                        ELSE
                                            vl_msje := ('Registros afectados: '|| row_count);
                                            --DBMS_OUTPUT.put_line (vl_msje);
                                        END IF;

                             EXCEPTION
                             WHEN OTHERS
                             THEN
                             vl_msje := 'Error' || SQLERRM;
                             END;

                         END IF;

                END LOOP;
                COMMIT;
         END;
       ------------------------------------------------------------------------------------------
        /*
          BEGIN

            SELECT a.SZTGPME_NO_REGLA
            INTO vl_no_regla
            FROM SZTGPME a
            WHERE 1=1
            AND a.SZTGPME_CRSE_MDLE_CODE = p_short_name
            AND a.SZTGPME_CAMP_CODE != 'EAF'
            AND a.SZTGPME_GRUPO = (SELECT MAX(a1.SZTGPME_GRUPO) FROM SZTGPME a1
                                   WHERE 1=1
                                   AND a1.SZTGPME_SUBJ_CRSE= a.SZTGPME_SUBJ_CRSE
                                   AND a1.SZTGPME_NO_REGLA =a.SZTGPME_NO_REGLA
                                   AND a1.SZTGPME_CRSE_MDLE_CODE = a.SZTGPME_CRSE_MDLE_CODE);
          EXCEPTION WHEN OTHERS THEN
          vl_msje:='Error al obtener regla -line:169:- '||sqlerrm;
          END;

          dbms_output.put_line(vl_msje);

           BEGIN
            SELECT DISTINCT SZTMAUR_SZTURMD_ID, SZTMAUR_MACO_PADRE
            INTO vl_servidor, vl_subj_maur
            FROM SZTMAUR
            WHERE 1= 1
            And SZTMAUR_MACO_PADRE = (SELECT DISTINCT (SZTGPME_SUBJ_CRSE_COMP)
                                        FROM SZTGPME
                                        WHERE SZTGPME_CRSE_MDLE_CODE = p_short_name
                                        AND SZTGPME_STAT_IND IS NOT NULL
                                        AND SZTGPME_NO_REGLA != 0
                                        AND SZTGPME_NO_REGLA = vl_no_regla)
            AND SZTMAUR_ACTIVO ='S'
            AND SZTMAUR_SZTURMD_ID = p_servidor;
            EXCEPTION WHEN NO_DATA_FOUND THEN
            vl_msje:='Error al obtener vl_servidor != 12 -line:186:- '||sqlerrm;
           END;

           dbms_output.put_line(vl_msje);

             IF vl_servidor IS NOT NULL AND vl_subj_maur IS NOT NULL THEN

                 BEGIN

                    UPDATE SZTGPME
                    SET SZTGPME_CRSE_MDLE_ID = p_crse_id, SZTGPME_PTRM_CODE_COMP = vl_servidor
                    WHERE SZTGPME_CRSE_MDLE_CODE = p_short_name
                    AND SZTGPME_SUBJ_CRSE = vl_subj_maur
                    AND SZTGPME_STAT_IND IS NOT NULL;
                    row_count := SQL%ROWCOUNT;

                   --DBMS_OUTPUT.PUT_LINE('CUENTA REG: '|| row_count);

                            IF SQL%ROWCOUNT > 0 THEN
                              vl_msje := ('Registros afectados: '|| row_count||' '||'Para servidor:'|| vl_servidor);
                              --DBMS_OUTPUT.put_line (vl_msje);
                            ELSE
                                vl_msje := ('Registros afectados: '|| row_count);
                                --DBMS_OUTPUT.put_line (vl_msje);
                            END IF;

                   EXCEPTION
                   WHEN OTHERS
                   THEN
                   vl_msje := 'Error' || SQLERRM;
                   END;

               END IF;
            COMMIT;
          */
        -------------------------------------------------------------------------------------------------------------------
      END IF;

    RETURN(vl_msje);

    END f_moodle_ini;



    FUNCTION f_grupo_moodl(p_inicio_clase in varchar2,  p_regla in number) return varchar2
    as
        l_retorna         varchar2(1000);
        l_contar          NUMBER;
        l_conse           NUMBER;
        l_materia         VARCHAR2(15);
        l_desripcion_mat  VARCHAR2(500);
        l_campus          VARCHAR2(15);
        l_nivel           VARCHAR2(15);
        l_parte_perido    VARCHAR2(15);
        l_term_code       VARCHAR2(15);
        l_regla_cerrada   VARCHAR2(1);
        l_short_name      VARCHAR2(250);
        l_grupo_moodl     VARCHAR2(15);
        l_grupo           VARCHAR2(5);
        l_secuencia       NUMBER:=null;
        vl_materia       VARCHAR2(15);
        vl_cont_reza number:= 0;


    BEGIN

        dbms_output.put_line(' entramos ');

        begin

            SELECT DISTINCT sztalgo_estatus_cerrado
            INTO  l_regla_cerrada
            FROM sztalgo
            WHERE 1 = 1
            AND sztalgo_no_regla = p_regla;

        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

        IF l_regla_cerrada = 'S' THEN

                        FOR c IN (
                                    select materia,
                                   pidm,
                                   matricula,
                                   maximo,
                                   CASE WHEN length(grupo)=2 THEN
                                    grupo
                                        WHEN length(grupo)=1 THEN
                                    to_char('0'||grupo)
                                   END GRUPO,
                                   secuencia,
                                   grupo grupo2,
                                   estatus,
                                   mat_conv,
                                   idioma
                            from
                            (
                            SELECT sztconf_subj_code materia,
                                   sztconf_pidm pidm,
                                   sztconf_id matricula,
                                   70 maximo,
--                                   TO_CHAR(ROW_NUMBER() OVER (PARTITION BY sztconf_subj_code ORDER BY sztconf_group)) grupo,
                                   to_char(SZTCONF_GROUP) grupo,
                                   SZTCONF_SECUENCIA secuencia,
                                   sztconf_estatus_cerrado estatus,
                                   (SELECT SZTCOMA_SUBJ_CODE_ADM||SZTCOMA_CRSE_NUMB_ADM
                                    FROM SZTCOMA
                                    WHERE SZTCOMA_SUBJ_CODE_BAN||SZTCOMA_CRSE_NUMB_BAN = a.sztconf_subj_code) mat_conv
                                    ,sztconf_idioma idioma
                                FROM sztconf a
                                WHERE 1 = 1
                                AND sztconf_no_regla = p_regla
                                and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY') = p_inicio_clase
--                                and sztconf_subj_code='L2DE135.'
                            )x
                            where 1 = 1
                            and (grupo) not in (select
                                                       SZTGPME_GRUPO
                                                from SZTGPME
                                                where 1 = 1
                                                and SZTGPME_no_regla = p_regla
                                                and SZTGPME_SUBJ_CRSE= x.materia
                                                AND SZTGPME_START_DATE = p_inicio_clase
                                                )

                                 )
             LOOP

                 vl_cont_reza:= vl_cont_reza+1;

                 vl_materia:= null;

                 IF c.mat_conv IS NULL THEN

                 vl_materia := c.materia;

                 else

                 vl_materia := c.mat_conv;

                 end if;

                dbms_output.put_line('entra 1');

                BEGIN
                    SELECT UPPER(scrsyln_long_course_title)
                    INTO l_desripcion_mat
                    FROM scrsyln
                    WHERE 1 = 1
                    AND scrsyln_subj_code||scrsyln_crse_numb =c.materia;

                EXCEPTION WHEN OTHERS THEN
                    dbms_output.put_line(' Error en SCRSYLN '||SQLERRM);
                    l_retorna:=' No se econtro descripcion para materia  '||c.materia||' '||sqlerrm;

                END;

                BEGIN

                   SELECT DISTINCT sztalgo_camp_code,
                                    sztalgo_levl_code
                    INTO l_campus,
                         l_nivel
                    FROM sztalgo
                    WHERE 1 = 1
                    AND sztalgo_no_regla  = p_regla
                    AND ROWNUM = 1;

                    IF l_campus ='UTS' THEN

                        l_campus:='UTL';

                    END IF;

                    IF l_nivel ='MS' THEN

                        l_nivel:='MA';

                    END IF;

                    IF l_nivel ='LI' THEN

                        l_nivel:='LI';

                    END IF;

                EXCEPTION WHEN OTHERS THEN
                     NULL;
                END;

                BEGIN




                    select CASE WHEN length( grupo)=2 THEN
                                grupo
                                WHEN length(grupo )=1 THEN
                                '0'||to_char(grupo)
                            END GRUPO
                    into l_grupo
                    from
                    (
                        SELECT to_char(nvl(count(*),0)+1) grupo
                        from szstume
                        where 1 = 1
                        and szstume_no_regla = p_regla
                        and SZSTUME_SUBJ_CODE =c.materia
                    );


                EXCEPTION WHEN OTHERS THEN
                    l_grupo:=0;
                END;




                BEGIN

                       SELECT DISTINCT sztalgo_ptrm_code_new,
                                       sztalgo_term_code_new
                       INTO l_parte_perido,
                            l_term_code
                       FROM sztalgo
                       WHERE 1 = 1
                       AND sztalgo_no_regla = p_regla
                       AND sztalgo_camp_code = l_campus
                       AND sztalgo_levl_code = l_nivel;

                EXCEPTION WHEN OTHERS THEN
                   DBMS_OUTPUT.PUT_LINE(' Error en sztgpme '||SQLERRM);
                   l_retorna:=' Error en obtener parte de periodo en  sztgpme '||sqlerrm;
                END;



                begin
                        select     concat(concat(concat(
                                      case
                                      when substr (l_parte_perido,1,2) IN ('M0', 'M1', 'M2','A0','A1','A2', 'A4','M4') then 'S'
                                      when substr (l_parte_perido,1,2) IN('M3', 'A3') then 'M'
                                      when substr  (l_parte_perido, 1,2) in ('L2', 'L1', 'L0') then 'A'
                                      when substr  (l_parte_perido, 1,2) not in ('M0', 'M1','M2', 'M3','A0','A1','A2','A3','L0', 'L1', 'L2')  then 'B'
                                      end,
                                      case
                                          when substr ('011943', 5,2) = '41' then  'A'
                                          when substr ('011943', 5,2) = '42' then 'B'
                                          when substr ('011943', 5,2) = '43' then 'C'
                                      end ||'0'||substr('011943',3,2) ||'_'),
                                      case
                                          when substr (l_parte_perido,2,2) IN ('3A', '3B', '3C','0A','0B','0C','0D','4A','4B','4C') then '0'
                                          when substr (l_parte_perido,2,2) IN ( '1A', '1B', '1C','1D', '1E', '3D', '4D')  then '1'
                                          when substr (l_parte_perido,2,2) IN ('2A') then '2'
                                          end ||'_'), TO_CHAR(to_DATE('04/03/2019','dd/mm/YYYY'),'DDMM')||'_' || vl_materia
                                  )  short_name
                        into l_short_name
                        from dual;

                 EXCEPTION WHEN OTHERS THEN
                    dbms_output.put_line(' Error en sztgpme '||SQLERRM);
                    l_retorna:=' Error en sztgpme '||sqlerrm;
                END;



                   begin

                    SELECT SZTCONF_SECUENCIA
                    into l_secuencia
                    FROM SZTCONF
                    WHERE 1 = 1
                    AND SZTCONF_NO_REGLA = p_regla
                    and sztconf_subj_code = c.materia
                    and SZTCONF_ESTATUS_CERRADO ='N'
                    and rownum = 1;
                  exception when others then
                    dbms_output.put_line('error '||sqlerrm);
                  end;

                    ---dbms_output.put_line(' Secuencia  '||l_secuencia||' materia '||c.materia);


               -- end if;


                BEGIN
                       INSERT INTO sztgpme VALUES(
                                                      c.materia||c.grupo,
                                                      c.materia,
                                                      l_desripcion_mat,
                                                      5,
                                                      NULL,
                                                      USER,
                                                      SYSDATE,
                                                      l_parte_perido,
                                                      p_inicio_clase,
                                                      NULL,
                                                      c.maximo,
                                                      l_nivel ,
                                                      l_campus,
                                                      NULL,
                                                      c.materia,
                                                      NULL,
                                                      l_term_code ,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      l_short_name,
                                                      p_regla,
                                                      l_secuencia,
                                                      c.grupo2,
                                                      'S',
                                                      1, 
                                                      c.idioma
                                                      );

                    l_retorna:='EXITO';

                EXCEPTION WHEN OTHERS THEN
                    dbms_output.put_line(' Error en al insertar gpme '||SQLERRM);
                    l_retorna:=' Error en al insertar gpme  '||sqlerrm;
                END;

               -- raise_application_error (-20002,'Secuencia tabla '||c.secuencia||' Secuecia variable '||l_secuencia);

                BEGIN

                    UPDATE SZTCONF SET SZTCONF_ESTATUS_CERRADO='S'
                    WHERE 1 = 1
                    AND SZTCONF_SUBJ_CODE  =c.materia
                    and sztconf_no_regla =p_regla
                    and SZTCONF_GROUP = c.grupo
                    and SZTCONF_FECHA_INICIO =p_inicio_clase;

                EXCEPTION WHEN OTHERS THEN
                    dbms_output.put_line(' Error al actualizar grupos pronostico '||SQLERRM);
                    l_retorna:=' Error al actualizar grupos pronostico '||sqlerrm;

                    raise_application_error (-20002,'Secuencia  '||c.secuencia||sqlerrm);

                END;


             END LOOP;


             COMMIT;
        ELSE
            dbms_output.put_line(' Esta regla no esta cerrada '||p_regla);
            l_retorna:='Esta regla no esta cerrada '||l_regla_cerrada;

        END IF;

        return(l_retorna);
    end;


   --FUNCI”N TIPO CURSOR QUE LEE EL DEMONIO sync_groups PARA SINCRONIZAR GRUPOS EN AV--
   FUNCTION f_grupos_moodle_out
      RETURN PKG_MOODLE2.cursor_out
   AS
      c_out   PKG_MOODLE2.cursor_out;
   BEGIN
      BEGIN
         OPEN c_out FOR
             SELECT SZTGPME_CRSE_MDLE_CODE short_name,
                     SZTGPME_CRSE_MDLE_ID crs_mdle_id,
                     SZTGPME_START_DATE Fecha,
                     Case when substr (SZTGPME_TERM_NRC, length (SZTGPME_TERM_NRC), 2) ='X' then
                        CONCAT ('Grupo_',substr (SZTGPME_TERM_NRC, length (SZTGPME_TERM_NRC)-2, 3))
                        when substr (SZTGPME_TERM_NRC, length (SZTGPME_TERM_NRC), 1) !='X' then
                        CONCAT ('Grupo_',SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,99))
                     end grupo ,
                     SZSGNME_PIDM Docente,
                     SZTGPME_STAT_IND Indicador,
                     SZTGPME_MAX_ENRL SOBRECUPO,
                     SZTGPME_MAX_ENRL CupoMaximo,
                     SZTGPME_PTRM_CODE_COMP servidor,
                     SZTGPME_NO_REGLA no_regla,
                     SZTMAUR_ORIGEN tipo_curso
                FROM SZTGPME,
                     ZSTPARA a,
                     SZTMDIN,
                     SZSGNME,
                     SZTMAUR,
                     SZTURMD
               WHERE     SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_START_DATE = SZSGNME_START_DATE
                     AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                     AND SZTGPME_STAT_IND = '0'
                     AND a.ZSTPARA_MAPA_ID = 'MOODLE_ID'
                     AND a.ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2)
                     AND a.ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                     AND SZTMDIN_STAT_IND = 0
                     AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                     AND SZTMAUR_ACTIVO = 'S'
                     AND SZTGPME_CRSE_MDLE_ID IS NOT NULL
                     AND SZTGPME_PTRM_CODE_COMP = SZTURMD_ID
                     AND SZTURMD_ACTIVO ='S'
                     AND SZTGPME_NO_REGLA <> 99
                     AND SZTMAUR_ORIGEN <> 'E'
                     AND SZTGPME_CAMP_CODE != 'EAF'
                     --AND SZTGPME_CAMP_CODE <>'UVE'
                     --AND SZSGNME_NO_REGLA IN (164, 149)
					 AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                  UNION
                     SELECT SZTGPME_CRSE_MDLE_CODE short_name,
                     SZTGPME_CRSE_MDLE_ID crs_mdle_id,
                     SZTGPME_START_DATE Fecha,
                     case when substr (SZTGPME_TERM_NRC, length (SZTGPME_TERM_NRC), 2) ='X' then
                                CONCAT ('Grupo_',substr (SZTGPME_TERM_NRC, length (SZTGPME_TERM_NRC)-2, 3))
                            when substr (SZTGPME_TERM_NRC, length (SZTGPME_TERM_NRC), 1) !='X' then
                                CONCAT ('Grupo_',SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,99))
                     end grupo ,
                     SZSGNME_PIDM Docente,
                     SZTGPME_STAT_IND Indicador,
                     SZTGPME_MAX_ENRL SOBRECUPO,
                     SZTGPME_MAX_ENRL CupoMaximo,
                     SZTGPME_PTRM_CODE_COMP servidor,
                     SZTGPME_NO_REGLA no_regla,
                     SZTMAUR_ORIGEN tipo_curso
                FROM SZTGPME,
                     ZSTPARA a,
                     SZTMDIN,
                     SZSGNME,
                     SZTMAUR,
                     SZTURMD
               WHERE     SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_START_DATE = SZSGNME_START_DATE
                     AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                     AND SZTGPME_STAT_IND = '0'
                     AND a.ZSTPARA_MAPA_ID = 'MOODLE_ID'
                     AND a.ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2)
                     AND a.ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                     AND SZTMDIN_STAT_IND = 0
                     AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                     AND SZTMAUR_ACTIVO = 'S'
                     AND SZTGPME_CRSE_MDLE_ID IS NOT NULL
                     AND SZTGPME_PTRM_CODE_COMP = SZTURMD_ID
                     AND SZTURMD_ACTIVO ='S'
                     AND SZTGPME_NO_REGLA <> 99
                     AND SZTMAUR_ORIGEN <> 'E'
                     AND SZTGPME_CAMP_CODE != 'EAF'
                     AND SZTMAUR_ORIGEN = 'I'
					 AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                  UNION
                     SELECT SZTGPME_CRSE_MDLE_CODE short_name,
                     SZTGPME_CRSE_MDLE_ID crs_mdle_id,
                     SZTGPME_START_DATE Fecha,
                     CONCAT ('Grupo_',SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,99))grupo,
                     SZSGNME_PIDM Docente,
                     SZTGPME_STAT_IND Indicador,
                     SZTGPME_MAX_ENRL SOBRECUPO,
                     SZTGPME_MAX_ENRL CupoMaximo,
                     SZTGPME_PTRM_CODE_COMP servidor,
                     SZTGPME_NO_REGLA no_regla,
                     SZTMAUR_ORIGEN tipo_curso
                FROM SZTGPME,
                     ZSTPARA a,
                     SZTMNIV,
                     SZSGNME,
                     SZTMAUR,
                     SZTURMD
               WHERE     SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_START_DATE = SZSGNME_START_DATE
                     AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                     AND SZTGPME_STAT_IND = '0'
                     AND a.ZSTPARA_MAPA_ID = 'MOODLE_ID'
                     AND a.ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2)
                     AND a.ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                     --AND SZTMNIV_STAT_IND = 0
                     AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                     AND SZTMAUR_ACTIVO = 'S'
                     AND SZTGPME_CRSE_MDLE_ID IS NOT NULL
                     AND SZTGPME_PTRM_CODE_COMP = SZTURMD_ID
                     AND SZTURMD_ACTIVO ='S'
                     AND SZTGPME_NO_REGLA = 99
                     AND SZTMAUR_ORIGEN = 'E'
                     AND SZTGPME_CAMP_CODE != 'EAF'
--					 AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                     union
                     SELECT SZTGPME_CRSE_MDLE_CODE short_name,
                     SZTGPME_CRSE_MDLE_ID crs_mdle_id,
                     SZTGPME_START_DATE Fecha,
                     CONCAT ('Grupo_',SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,99))grupo,
                     SZSGNME_PIDM Docente,
                     SZTGPME_STAT_IND Indicador,
                     50 SOBRECUPO,
                     50 CupoMaximo,
                     SZTGPME_PTRM_CODE_COMP servidor,
                     SZTGPME_NO_REGLA no_regla,
                     SZTMAUR_ORIGEN tipo_curso
                FROM SZTGPME,
                     ZSTPARA a,
                     SZTMNIV,
                     SZSGNME,
                     SZTMAUR,
                     SZTURMD
               WHERE     SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_START_DATE = SZSGNME_START_DATE
                     AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                     AND SZTGPME_STAT_IND = '0'
                     AND a.ZSTPARA_MAPA_ID = 'MOODLE_ID'
                    -- AND a.ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP,1, 2)
                     AND a.ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                     AND SZTMNIV_STAT_IND = 0
                     AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                     AND SZTMAUR_ACTIVO = 'S'
                     AND SZTGPME_CRSE_MDLE_ID IS NOT NULL
                     AND SZTGPME_PTRM_CODE_COMP = SZTURMD_ID
                     AND SZTURMD_ACTIVO ='S'
                     AND SZTGPME_NO_REGLA = 1
                     AND SZTMAUR_ORIGEN = 'N'
--                     AND SZTGPME_CAMP_CODE != 'EAF'
                     AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
            ORDER BY 1,
                     2,
                     3,
                     4;
         RETURN (c_out);
      END;
   END f_grupos_moodle_out;

     --FUNCION QUE ACTUALIZA LOS GRUPOS SINCRONIZADOS CON AV--
   FUNCTION f_update_sztgpme (p_materia          IN VARCHAR2,
                              p_fecha_ini        IN VARCHAR2,
                              p_stat_upte_ind    IN VARCHAR2,
                              p_crse_mdle_code   IN NUMBER DEFAULT NULL,
                              p_obs              IN VARCHAR2,
                              p_error_code       IN NUMBER DEFAULT NULL,
                              p_error_desc       IN VARCHAR2,
                              p_gpmdle_code      IN NUMBER DEFAULT NULL,
                              p_pidm             IN NUMBER DEFAULT NULL,
                              p_no_regla         IN NUMBER)
      RETURN VARCHAR
   AS
      vl_maximo   NUMBER := 0;
      vl_error    VARCHAR2 (5000) := 'Termino';
      vl_nrc      VARCHAR2 (100);
      row_count   NUMBER := 0;
   BEGIN
      FOR c
         IN (SELECT SZTGPME_TERM_NRC,
                    SZTGPME_STAT_IND,
                    SZTGPME_OBS,
                    SZTGPME_GPMDLE_ID,
                    SZTGPME_START_DATE
               FROM SZTGPME
              WHERE SZTGPME_TERM_NRC = p_materia
                    AND SZTGPME_START_DATE = TO_DATE (p_fecha_ini, 'dd/mm/yyyy')
                    AND SZTGPME_NO_REGLA = p_no_regla
                    AND SZTGPME_CAMP_CODE != 'EAF')
      LOOP
         -- CÛdigo 2 para identidficar a los errores de sinconizaciÛn con Moodle Trae el registro m·ximo del grupo de la tabla de bitacora--

         IF p_stat_upte_ind = 2
         THEN
            BEGIN
               SELECT NVL (MAX (SZTMEBI_SEQ_NO), 0) + 1
                 INTO vl_maximo
                 FROM SZTMEBI
                WHERE SZTMEBI_TERM_NRC = c.SZTGPME_TERM_NRC
                      AND SZTMEBI_CTGY_ID = 'Curso-Grupo';
            EXCEPTION
            WHEN OTHERS THEN
            vl_maximo := 1;
            END;

            BEGIN
               INSERT INTO SZTMEBI
                    VALUES (c.SZTGPME_TERM_NRC,
                            p_stat_upte_ind,
                            p_error_code,
                            p_error_desc,
                            1,
                            SYSDATE,
                            USER,
                            'Curso-Grupo',
                            p_pidm);

               row_count := SQL%ROWCOUNT;
               DBMS_OUTPUT.put_line (
                  'Registros insertados en bitacora '|| row_count);

               vl_error :=
                  'Registros insertados en bitacora '|| row_count;
            EXCEPTION
            WHEN OTHERS THEN
            vl_error := 'Error al insertar Curso-Grupo en la Bitacora: '|| SQLERRM;
            END;

            --Actualiza el status indicator a 2 e inserta las observaciones de error--

            BEGIN
               UPDATE SZTGPME
                  SET SZTGPME_STAT_IND = p_stat_upte_ind,
                      SZTGPME_OBS = p_obs, -- 'Error de sincronia ver SZTMEBI',
                      SZTGPME_ACTIVITY_DATE = SYSDATE
                WHERE SZTGPME_TERM_NRC = c.SZTGPME_TERM_NRC
                      AND SZTGPME_NO_REGLA = p_no_regla
                      AND SZTGPME_START_DATE = c.SZTGPME_START_DATE;

               row_count := SQL%ROWCOUNT;
               DBMS_OUTPUT.put_line (
                  'Registros acualizados con error: '|| row_count);
               vl_error :=
                  'Registros acualizados con error: '|| row_count;
            END;
         ELSE
            -- CÛdigo 1 Èxito de inconizaciÛn con Moodle--
            --Actualiza el status indicator a 1 e inserta las observaciones de exito--
            BEGIN
               UPDATE SZTGPME
                  SET SZTGPME_STAT_IND = p_stat_upte_ind,
                      SZTGPME_OBS = p_obs || p_gpmdle_code,
                      SZTGPME_GPMDLE_ID = p_gpmdle_code,
                      SZTGPME_ACTIVITY_DATE = SYSDATE
                WHERE     SZTGPME_TERM_NRC = c.SZTGPME_TERM_NRC
                      AND SZTGPME_NO_REGLA = p_no_regla
                      AND SZTGPME_START_DATE = c.SZTGPME_START_DATE;

               --AND SZTGPME_GPMDLE_ID IS NULL;
               row_count := SQL%ROWCOUNT;
               DBMS_OUTPUT.put_line (
                  'Registros acualizados con exito:' || ' ' || row_count);
               vl_error :=
                  'Registros acualizados con exitor:' || ' ' || row_count;
            EXCEPTION
               WHEN OTHERS
               THEN
                  vl_error :=
                     'Error al actualizar tabla intermedia' || SQLERRM;
            END;

         END IF;
      END LOOP;

      COMMIT;
      RETURN (vl_error||'-'||row_count||'-'||p_stat_upte_ind||'-'||p_error_code||'-'|| p_error_desc);
   EXCEPTION
      WHEN OTHERS
      THEN
         vl_error := 'Error General f_update_sztgpme' || SQLERRM;
         RETURN vl_error;
   END;

-- FUNCI”N PARA INSERTAR INFORMACI”N DE DOCEMTES EN SZSGNME--
    FUNCTION f_prof_moodl(p_inicio_clase in varchar, p_regla in number)return varchar2
    as
        l_retorna  varchar2(1000):='EXITO';
        l_regla_cerrada varchar2(1);
        l_pwd           varchar2(100);
        l_id            varchar(20);
        l_pidm          number;
   begin

        dbms_output.put_line(' Esta regla no esta cerrada '||p_regla);

        BEGIN

            SELECT DISTINCT sztalgo_estatus_cerrado
            INTO  l_regla_cerrada
            FROM sztalgo
            WHERE 1 = 1
            AND sztalgo_no_regla = p_regla;

        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

        IF l_regla_cerrada = 'S' THEN

           for c in (
                       select padre,
                               regla,
                               ptrm,
                               subt,
                               largo,
                               to_number(substr(padre,subt,2)) grupo,
                               secuencia,
                               materia
                                ,idioma
                        from
                            (
                            select padre,
                                   regla,
                                   ptrm,
                                   secuencia,
                                   largo -1 subt,
                                   largo,
                                   materia,
                                   idioma
                            from
                            (
                                select SZTGPME_TERM_NRC padre,
                                       sztgpme_no_regla regla,
                                       SZTGPME_PTRM_CODE ptrm,
                                       SZTGPME_SECUENCIA secuencia,
                                       length (SZTGPME_TERM_NRC) largo,
                                       SZTGPME_SUBJ_CRSE materia
                                       ,sztgpme_idioma idioma
                                from sztgpme me
                                where 1 = 1
                                and sztgpme_no_regla = p_regla
                                and SZTGPME_START_DATE = p_inicio_clase
                            )
                        )a
                        where 1 = 1
                         and (padre,to_number(substr(padre,subt,2))) not in (select substr(padre,subt,2),padre grupo
                                                                            from
                                                                            (
                                                                                select largo-1 subt,
                                                                                       padre
                                                                                from
                                                                                (
                                                                                    select length(SZSGNME_TERM_NRC) largo,
                                                                                           SZSGNME_TERM_NRC padre
                                                                                    from SZSGNME
                                                                                    where 1 = 1
                                                                                    and SZSGNME_no_regla = p_regla
        --                                                                            and SZSGNME_START_DATE ='04/03/2019'
                                                                                )
                                                                            ) )

                     )

                    loop


                        begin

                            select sztconf_id,
                                   sztconf_pidm
                            into l_id,
                                 l_pidm
                            from sztconf
                            where 1 = 1
                            and sztconf_no_regla = p_regla
                            and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')     = p_inicio_clase
                            and SZTCONF_GROUP = c.grupo
                            and SZTCONF_SUBJ_CODE = c.materia;
                        exception when others then
                            dbms_output.put_line(' Error al obtener pidm '||sqlerrm);
                            null;
                        end;


                        begin

                           select GOZTPAC_PIN
                           into l_pwd
                           from GOZTPAC pac
                           where 1 = 1
                           and pac.GOZTPAC_pidm =l_pidm
                           and rownum = 1;

                        exception when others then
                            dbms_output.put_line(' Error al obtener pwd '||sqlerrm||' pidm '||l_pidm);
                            l_retorna:=' Error al obtener pwd '||sqlerrm||' regla  '||p_regla ||' grupo '||c.grupo||' materia '||c.materia;
                        end;


                       --IF l_pwd IS NOT NULL THEN

                            begin

                                INSERT INTO SZSGNME VALUES(c.padre,
                                                           l_pidm,
                                                           sysdate,
                                                           user,
                                                           '5',
                                                           null,
                                                           l_pwd,
                                                           null,
                                                           'AC',
                                                           c.secuencia,
                                                           null,
                                                           c.ptrm,
                                                           p_inicio_clase,
                                                           c.regla,
                                                           c.secuencia,
                                                           1, 
                                                           c.idioma
                                                           );
                                l_retorna:='EXITO';

                            exception when others then
                                dbms_output.put_line(' Error al insertar tabla de profesores moodl '||sqlerrm);
                                l_retorna:= ' Error al insertar tabla de profesores moodl '||sqlerrm;
                            end;

                      -- END IF;

                    end loop;

                    commit;

        else

           dbms_output.put_line(' Esta regla no esta cerrada '||p_regla);
           l_retorna:='Esta regla no esta cerrada ';

        end if;

        return(l_retorna);
    end;


--   function f_alumnos_moodl(p_inicio_clase in VARCHAR2, p_regla in NUMBER)return varchar2
--    as
--    l_retorna            varchar2(1000);
--    l_regla_cerrada      varchar2(1);
--    l_contar             number;
--    l_numero_grupos      number;
--    vl_alumnos           number :=0;
--    l_cuenta_alumnos     number;
--    l_numero_alumnos     number;
--    l_total              number;
--    l_grupo_disponible   varchar2(100);
--    l_numero_alumnos2    number;
--    l_tope_grupos        number;
--    l_total_alumnos      number;
--    l_sobrecupo          number;
--    l_cuenta_grupo       number;
--    l_estatus_gaston     varchar2(10);
--    l_descripcion_error  varchar2(500);
--
--
--    begin
--
--
--
--        BEGIN
--
--            SELECT DISTINCT trim(SZTALGO_ESTATUS_CERRADO),SZTALGO_TOPE_ALUMNOS,SZTALGO_SOBRECUPO_ALUMNOS
--            INTO  l_regla_cerrada,l_tope_grupos,l_sobrecupo
--            FROM sztalgo
--            WHERE 1 = 1
--            AND sztalgo_no_regla = p_regla;
--
--        EXCEPTION WHEN OTHERS THEN
--            raise_application_error (-20002,'Error al   '||sqlerrm);
--        END;
--
--        IF l_regla_cerrada = 'S' THEN
--
--            l_contar:=0;
--            l_numero_alumnos2:=0;
--            l_numero_alumnos:=0;
--
--
--            for c in (
--
--                        SELECT *
--                            FROM
--                            (
--                            select (select SZTGPME_TERM_NRC
--                                                                    from SZTGPME
--                                                                    where 1 = 1
--                                                                    and SZTGPME_NO_REGLA = onf.sztconf_no_regla
--                                                                    and SZTGPME_START_DATE = to_char(to_date(onf.SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')
--                                                                    and SZTGPME_SUBJ_CRSE =onf.sztconf_subj_code
--                                                                    and to_number(f_get_group(23,'04/03/2019',SZTGPME_TERM_NRC)) = to_number(onf.SZTCONF_GROUP)
--                                                                    ) padre,
--                                                                    sztconf_no_regla regla,
--                                                                    SZTCONF_SUBJ_CODE materia,
--                                                                    to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')inicio_clases,
--                                                                    to_number(SZTCONF_GROUP) grupo,
--                                                                    SZTCONF_SECUENCIA secuencia
--                                                            from sztconf onf
--                                                            where 1 = 1
--                                                            AND SZTCONF_SUBJ_CODE='M2AN102'
--                                                            AND SZTCONF_GROUP = 2
--                                                            and sztconf_no_regla = 23
--                                                            and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY') ='04/03/2019'
--                                                            and sztconf_subj_code in (select (select SZTMACO_MATPADRE
--                                                                                                from sztmaco
--                                                                                                where 1 = 1
--                                                                                                and SZTNINC_SUBJ_CODE||SZTNINC_CRSE_NUMB = SZTMACO_MATHIJO ) materia_padre
--                                                                                        from sztninc inc
--                                                                                        where 1 = 1
--                                                                                        and sztninc_no_regla = 23
--                                                                                        and exists (select null
--                                                                                                    from sztprono
--                                                                                                    where 1 = 1
--                                                                                                    and sztprono_no_regla = 23
--                                                                                                    and to_char(to_date(SZTPRONO_FECHA_INICIO_NW,'DD/MM/YYYY'),'DD/MM/YYYY') ='04/03/2019'
--                                                                                                    and sztprono_no_regla = sztninc_no_regla
--                                                                                                    and sztprono_pidm = sztninc_pidm
--                                                                                                    and SZTPRONO_ENVIO_MOODL ='N'
--                                                                                                    and SZTPRONO_ESTATUS_ERROR ='N'))
--                            )
--                            WHERE PADRE IS NOT NULL
--                                                           )
--
--                          select SZTGPME_TERM_NRC padre,
--                               sztgpme_no_regla regla,
--                               sztgpme_subj_crse materia,
--                              to_char(SZTGPME_START_DATE,'DD/MM/YYYY') inicio_clases,
--                              to_number(f_get_group(p_regla,'04/03/2019',SZTGPME_TERM_NRC)) grupo,
--                               SZTGPME_SECUENCIA secuencia
--                        from sztgpme grp
--                        where 1 = 1
--                        and sztgpme_no_regla = p_regla
--                        --and SZTGPME_START_DATE = p_inicio_clase
--                        and to_number(f_get_group(p_regla,'04/03/2019',SZTGPME_TERM_NRC)) not in (select to_number(f_get_group(p_regla,'04/03/2019',SZSTUME_TERM_NRC))
--                                                                                              from szstume
--                                                                                              where 1 = 1
--                                                                                              and szstume_no_regla =grp.sztgpme_no_regla
--                                                                                              and SZSTUME_START_DATE =to_char(grp.SZTGPME_START_DATE,'DD/MM/YYYY')
--                                                                                              and SZSTUME_SUBJ_CODE = grp.sztgpme_subj_crse
--                                                                                              )
--                        union -- cuando los alumnos no crean nuevos grupos
--                        select (select SZTGPME_TERM_NRC
--                                from SZTGPME
--                                where 1 = 1
--                                and SZTGPME_NO_REGLA = onf.sztconf_no_regla
--                                and SZTGPME_START_DATE = to_char(to_date(onf.SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')
--                                and SZTGPME_SUBJ_CRSE =onf.sztconf_subj_code
--                                and to_number(f_get_group(p_regla,p_inicio_clase,SZTGPME_TERM_NRC)) = to_number(onf.SZTCONF_GROUP)
--                                ) padre,
--                                sztconf_no_regla regla,
--                                SZTCONF_SUBJ_CODE materia,
--                                to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')inicio_clases,
--                                to_number(SZTCONF_GROUP) grupo,
--                                SZTCONF_SECUENCIA secuencia
--                        from sztconf onf
--                        where 1 = 1
--                        and sztconf_no_regla = p_regla
--                        --and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY') =p_inicio_clase
--                        and sztconf_subj_code in (select (select SZTMACO_MATPADRE
--                                                            from sztmaco
--                                                            where 1 = 1
--                                                            and SZTNINC_SUBJ_CODE||SZTNINC_CRSE_NUMB = SZTMACO_MATHIJO ) materia_padre
--                                                    from sztninc inc
--                                                    where 1 = 1
--                                                    and sztninc_no_regla = p_regla
--                                                    and exists (select null
--                                                                from sztprono
--                                                                where 1 = 1
--                                                                and sztprono_no_regla = p_regla
--                                                                --and to_char(to_date(SZTPRONO_FECHA_INICIO_NW,'DD/MM/YYYY'),'DD/MM/YYYY') =p_inicio_clase
--                                                                and sztprono_no_regla = sztninc_no_regla
--                                                                and sztprono_pidm = sztninc_pidm
--                                                                and SZTPRONO_ENVIO_MOODL ='N'
--                                                                and SZTPRONO_ESTATUS_ERROR ='N')
--                                                       )
--
--
--                    loop
--
--                                dbms_output.put_line(' Entra agrupos ');
--
--                                 for e in(select count(*) vueltas
--                                             from sztconf onf
--                                             where 1 = 1
--                                             and onf.sztconf_no_regla = c.regla
--                                             and onf.SZTCONF_FECHA_INICIO =c.inicio_clases
--                                             and SZTCONF_SUBJ_CODE=c.materia
--                                             AND SZTCONF_GROUP = c.grupo
--                                 )
--                                 loop
--
--                                     dbms_output.put_line(' Entra alumno no alumnos  '||l_cuenta_alumnos);
--
--                                      l_contar:=l_contar+1;
--
--                                      select count(*)
--                                      into l_cuenta_alumnos
--                                      from szstume
--                                      where 1 = 1
--                                      and szstume_no_regla = c.regla
--                                      and SZSTUME_SUBJ_CODE = c.materia
--                                      and SZSTUME_TERM_NRC = c.padre;
--
--                                     dbms_output.put_line(' Entra alumno no alumnos  '||l_cuenta_alumnos);
--
--                                     if l_cuenta_alumnos = 0 then
--
--
--
--                                        begin
--
--                                            select SZTCONF_STUDENT_NUMB
--                                            into l_numero_alumnos2
--                                            from sztconf
--                                            where 1 = 1
--                                            and sztconf_no_regla  = c.regla
--                                            and sztconf_subj_code = c.materia
--                                            and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')=c.inicio_clases
--                                            and to_number(SZTCONF_GROUP)= c.grupo;
--                                            and sztconf_secuencia = c.secuencia;
--                                        exception when others then
--                                            null;
--                                        end;
--
--
--                                         dbms_output.put_line(' Materia  '||c.materia||' Padre '||c.padre||' alumnos '||l_cuenta_alumnos||'ALUMNOS 2'||l_numero_alumnos2);
--
--                                         for d in (
--                                                     select sztprono_id matricula,
--                                                            SZTPRONO_PIDM pidm,
--                                                             'RE'  estatus_alumno,
--                                                             (select GOZTPAC_PIN
--                                                               from GOZTPAC pac
--                                                               where 1 = 1
--                                                               and pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM ) pwd,
--                                                               SZTPRONO_COMENTARIO comentario,
--                                                               65 tope,
--                                                               SZTPRONO_PROGRAM programa,
--                                                               sztprono_materia_legal materia
--                                                      from sztprono ono
--                                                      where 1 = 1
--                                                      and sztprono_no_regla  = c.regla
--                                                      and sztprono_materia_legal = c.materia
--                                                      and rownum <= l_numero_alumnos2
--                                                      and SZTPRONO_FECHA_INICIO = c.inicio_clases
--                                                      And SZTPRONO_ENVIO_MOODL = 'N'
--                                                  )
--                                              loop
--
--
--
--
--                                                   begin
--
--                                                       select SGBSTDN_STST_CODE
--                                                       into l_estatus_gaston
--                                                       from sgbstdn a
--                                                       where 1 = 1
--                                                       and SGBSTDN_pidm = d.pidm
--                                                       and sgbstdn_program_1  = d.programa
--                                                       And a.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
--                                                                                      from sgbstdn b1
--                                                                                      Where a.sgbstdn_pidm = b1.sgbstdn_pidm
--                                                                                      And a.sgbstdn_program_1 = b1.sgbstdn_program_1);
--
--
--                                                   exception when others then
--                                                       l_estatus_gaston:='MA';
--                                                   end;
--
--                                                   dbms_output.put_line(' Materia  '||c.materia||' Padre '||c.padre||' alumnos '||l_cuenta_alumnos||' mATRICULA '||D.matricula||' ESTATUS '||l_estatus_gaston);
--
--                                                   --dbms_output.put_line(' Materia  '||c.materia||' Padre '||c.padre||' alumnos '||' pidm' ||d.pidm||' Matriucla '||d.matricula||' Gaston '||l_estatus_gaston);
--
--                                                   if l_estatus_gaston in  ('AS','PR','MA',NULL) then
--
--
--                                                        begin
--
--                                                            dbms_output.put_line(' Materia  '||c.materia||' Padre '||c.padre||' alumnos '||' pidm' ||d.pidm||' Matriucla '||d.matricula||' Gaston '||l_estatus_gaston);
--
--                                                            insert into SZSTUME values(c.padre,
--                                                                                       d.pidm,
--                                                                                       d.matricula,
--                                                                                       sysdate,
--                                                                                       user,
--                                                                                       5,
--                                                                                       null,
--                                                                                       d.pwd,
--                                                                                       null,
--                                                                                       1,
--                                                                                       d.estatus_alumno,
--                                                                                       null,
--                                                                                       c.materia,
--                                                                                       null, c.nivel,
--                                                                                       null,
--                                                                                       null,  c.ptrm,
--                                                                                       null,
--                                                                                       null,
--                                                                                       null,
--                                                                                       null,
--                                                                                       c.materia,
--                                                                                       p_inicio_clase,  c.inicio_clases,
--                                                                                       c.regla,
--                                                                                       c.secuencia
--                                                                                       );
--
--                                                            l_retorna:='EXITO';
--                                                            dbms_output.put_line(' Exito Insert ');
--
--
--                                                        exception when others then
--
--                                                            dbms_output.put_line(' Error al insertar '||sqlerrm);
--
--
--
--                                                        end;
--
--                                                        BEGIN
--                                                            UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='S'
--                                                            WHERE 1 = 1
--                                                            and SZTPRONO_MATERIA_LEGAL = c.materia
--                                                            and SZTPRONO_PIDM =d.pidm
--                                                            and SZTPRONO_NO_REGLA = c.regla
--                                                            and SZTPRONO_FECHA_INICIO =c.inicio_clases
--                                                            and SZTPRONO_ENVIO_MOODL ='N';
--
--                                                            l_retorna:='EXITO';
--
--                                                        EXCEPTION WHEN OTHERS THEN
--                                                            dbms_output.put_line(' Error al actualizar '||sqlerrm);
--
--                                                            raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);
--                                                        END;
--
--                                                        commit;
--
--                                                   ELSE
----
----
--                                                       begin
--
--                                                           SELECT DECODE(l_estatus_gaston,'BT','BAJA TEMPORAL','BD','BAJA TEMPORAL','BI', 'BAJA POR INACTIVIDAD','CV', 'CANCELACI”N DE VENTA','CM','CANCELACI”N DE MATRÕCULA','CC', 'CAMBIO DE CILO','CF','CAMBIO DE FECHA','CP','CAMBIO DE PROGRAMA','EG','EGRESADO')
--                                                           INTO L_DESCRIPCION_ERROR
--                                                           FROM DUAL;
--
--                                                       exception when others then
--                                                           l_estatus_gaston:='SD';
--                                                           l_descripcion_error:='Sin descripcion';
--                                                       end;
--
--
--                                                       Begin
--
--                                                            UPDATE sztprono SET SZTPRONO_ESTATUS_ERROR ='S',
--                                                                                SZTPRONO_DESCRIPCION_ERROR=L_DESCRIPCION_ERROR
--
--                                                            WHERE 1 = 1
--                                                            AND SZTPRONO_MATERIA_LEGAL = d.materia
--                                                            AND TRUNC (SZTPRONO_FECHA_INICIO) = p_inicio_clase
--                                                            AND SZTPRONO_NO_REGLA=P_REGLA
--                                                            AND SZTPRONO_PIDM=d.PIDM;
--
--                                                       EXCEPTION WHEN OTHERS THEN
--                                                          dbms_output.put_line(' Error al actualizar '||sqlerrm);
--                                                       END;
--
--                                                   end if;
--
--                                              end loop;
--
--                                              commit;
--
--                                     elsif l_cuenta_alumnos >0 then
--
--                                        dbms_output.put_line('Entra 2da parte ');
--
--
--                                        for x in (select distinct sztprono_materia_legal materia
--                                                  from sztprono
--                                                  where 1 = 1
--                                                  and sztprono_no_regla = c.regla
--                                                  and sztprono_envio_moodl ='N'
--                                                  and SZTPRONO_ESTATUS_ERROR='N')
--
--                                                 loop
--
--                                                    dbms_output.put_line('Error al obtener numero de alumnos  '||l_numero_alumnos||' Materia '||c.materia);
--
--                                                     BEGIN
--
--                                                         select COUNT(DISTINCT SZTPRONO_ID)
--                                                         into l_numero_alumnos
--                                                         from sztprono
--                                                         where 1 = 1
--                                                         and sztprono_no_regla = p_regla
--                                                         and SZTPRONO_ENVIO_MOODL ='N'
--                                                         and sztprono_materia_legal =x.materia;
--
--                                                         l_retorna:='EXITO';
--
--                                                     EXCEPTION WHEN OTHERS THEN
--                                                        dbms_output.put_line('Error al obtener numero de alumnos  '||l_numero_alumnos||' Materia '||c.materia);
--
--
--                                                     END;
--
--                                                 end loop;
--
--                                        dbms_output.put_line('no alumnos  '||l_numero_alumnos);
--
--                                        l_numero_alumnos:=1;
--
--                                         if l_numero_alumnos> 0 then
--
--
--
--                                             begin
--
--                                                  select total, grupo
--                                                  into l_total,l_grupo_disponible
--                                                  from
--                                                  (
--                                                  select count(SZSTUME_ID) total,SZSTUME_TERM_NRC grupo,SZSTUME_USER_ID
--                                                  from szstume
--                                                  where 1 = 1
--                                                  and szstume_no_regla = c.regla
--                                                  AND SZSTUME_USER_ID ='LILIA.RAMIREZ'
--                                                  and SZSTUME_TERM_NRC in ( select distinct SZTGPME_TERM_NRC
--                                                                           from sztgpme
--                                                                           where 1 = 1
--                                                                           and sztgpme_no_regla = c.regla
--                                                                           and SZTGPME_SUBJ_CRSE = c.materia
--                                                                           order by 1
--                                                                           )
--                                                  group by SZSTUME_TERM_NRC,SZSTUME_USER_ID
--                                                  )x
--                                                  where 1 = 1
--                                                  AND rownum = 1
--                                                  and total = ( select min(total)
--                                                               from
--                                                               (
--                                                               select count(SZSTUME_ID) total,SZSTUME_TERM_NRC grupo,SZSTUME_USER_ID
--                                                               from szstume
--                                                               where 1 = 1
--                                                               and szstume_no_regla = c.regla
--                                                               AND SZSTUME_USER_ID ='LILIA.RAMIREZ'
--                                                               and SZSTUME_TERM_NRC in ( select distinct SZTGPME_TERM_NRC
--                                                                                        from sztgpme
--                                                                                        where 1 = 1
--                                                                                        and sztgpme_no_regla =c.regla
--                                                                                        and SZTGPME_SUBJ_CRSE =c.materia
--                                                                                        order by 1
--                                                                                        )
--                                                               group by SZSTUME_TERM_NRC,SZSTUME_USER_ID
--                                                                   ));
--                                             EXCEPTION WHEN OTHERS THEN
--                                              dbms_output.put_line('Error al obtener total de alumnos '||l_total||' materia '||l_grupo_disponible);
--
--                                             END;
--
--                                             dbms_output.put_line('padre '||c.padre||' grupo disponible '||l_grupo_disponible);
--
--                                             if c.padre =l_grupo_disponible then
--
--                                                dbms_output.put_line('entra 1');
--
--                                                l_total_alumnos:=l_numero_alumnos+l_total;
--
--                                                l_sobrecupo:= l_tope_grupos+l_sobrecupo;
--
--                                                if l_total_alumnos > l_tope_grupos  then
--
--                                                    dbms_output.put_line('entra 2');
--
--                                                   if l_total_alumnos<= l_sobrecupo then
--
--
--                                                    dbms_output.put_line('entra 3');
--
--                                                    dbms_output.put_line('Numero de alumnos '||l_numero_alumnos||' grupo '||l_grupo_disponible||' Materia '||c.materia||' Secuencia '||c.secuencia||' alumnos en grupo '||l_total||' como queda el grupo '||l_total_alumnos||' Sobrecupo '||l_sobrecupo);
--
--                                                         for d in (
--                                                         select sztprono_id matricula,
--                                                                SZTPRONO_PIDM pidm,
--                                                                 'RE'  estatus_alumno,
--                                                                 (select GOZTPAC_PIN
--                                                                   from GOZTPAC pac
--                                                                   where 1 = 1
--                                                                   and pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM ) pwd,
--                                                                   SZTPRONO_COMENTARIO comentario,
--                                                                   65 tope,
--                                                                   SZTPRONO_PROGRAM programa,
--                                                                   sztprono_materia_legal materia
--                                                          from sztprono ono
--                                                          where 1 = 1
--                                                          and sztprono_no_regla  = c.regla
--                                                          and sztprono_materia_legal = c.materia
--                                                          and rownum <= l_numero_alumnos
--                                                          and SZTPRONO_FECHA_INICIO = c.inicio_clases
--                                                          And SZTPRONO_ENVIO_MOODL = 'N'
--                                                      )
--                                                      loop
--
--
--                                                             begin
--
--
--                                                                         insert into SZSTUME values(l_grupo_disponible,
--                                                                                                    d.pidm,
--                                                                                                    d.matricula,
--                                                                                                    sysdate,
--                                                                                                    user,
--                                                                                                    5,
--                                                                                                    null,
--                                                                                                    d.pwd,
--                                                                                                    null,
--                                                                                                    1,
--                                                                                                    d.estatus_alumno,
--                                                                                                    null,
--                                                                                                    c.materia,
--                                                                                                    null, c.nivel,
--                                                                                                    null,
--                                                                                                    null,  c.ptrm,
--                                                                                                    null,
--                                                                                                    null,
--                                                                                                    null,
--                                                                                                    null,
--                                                                                                    c.materia,
--                                                                                                    p_inicio_clase,  c.inicio_clases,
--                                                                                                    c.regla,
--                                                                                                    c.secuencia
--                                                                                                    );
--
--                                                                         l_retorna:='EXITO';
--                                                                         dbms_output.put_line(' Exito Insert ');
--
--
--                                                             exception when others then
--                                                               dbms_output.put_line(' error al  Insert '||sqlerrm);
--                                                             end;
--
--                                                             BEGIN
--                                                                 UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='S'
--                                                                 WHERE 1 = 1
--                                                                 and SZTPRONO_MATERIA_LEGAL = c.materia
--                                                                 and SZTPRONO_PIDM =d.pidm
--                                                                 and SZTPRONO_NO_REGLA = c.regla
--                                                                 and SZTPRONO_FECHA_INICIO =c.inicio_clases
--                                                                 and SZTPRONO_ENVIO_MOODL ='N';
--
--                                                             EXCEPTION WHEN OTHERS THEN
--                                                                 dbms_output.put_line(' Error al actualizar '||sqlerrm);
--
--                                                                 raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);
--                                                             END;
--
--
--                                                      end loop;
--
--                                                   elsif  l_total_alumnos> l_sobrecupo then
--
--                                                    null;
--
--                                                   end if;
--
--
--                                                elsif  l_total_alumnos <= l_tope_grupos then
--
--
--                                                     dbms_output.put_line('Numero de alumnos '||l_numero_alumnos||' grupo '||l_grupo_disponible||' Materia '||c.materia||' Secuencia '||c.secuencia||' alumnos en grupo '||l_total||' como queda el grupo '||l_total_alumnos);
--
--                                                      for d in (
--                                                     select sztprono_id matricula,
--                                                            SZTPRONO_PIDM pidm,
--                                                             'RE'  estatus_alumno,
--                                                             (select GOZTPAC_PIN
--                                                               from GOZTPAC pac
--                                                               where 1 = 1
--                                                               and pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM ) pwd,
--                                                               SZTPRONO_COMENTARIO comentario,
--                                                               65 tope,
--                                                               sztprono_program programa,
--                                                               sztprono_materia_legal materia
--                                                      from sztprono ono
--                                                      where 1 = 1
--                                                      and sztprono_no_regla  = c.regla
--                                                      and sztprono_materia_legal = c.materia
--                                                      and rownum <= l_numero_alumnos
--                                                      and SZTPRONO_FECHA_INICIO = c.inicio_clases
--                                                      And SZTPRONO_ENVIO_MOODL = 'N'
--                                                  )
--                                                      loop
--
--                                                            begin
--
--                                                                 select SGBSTDN_STST_CODE
--                                                                 into l_estatus_gaston
--                                                                 from sgbstdn a
--                                                                 where 1 = 1
--                                                                 and SGBSTDN_pidm = d.pidm
--                                                                 and sgbstdn_program_1  = d.programa
--                                                                 And a.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
--                                                                                                from sgbstdn b1
--                                                                                                Where a.sgbstdn_pidm = b1.sgbstdn_pidm
--                                                                                                And a.sgbstdn_program_1 = b1.sgbstdn_program_1);
--
--
--                                                            exception when others then
--                                                                null;
--                                                            end;
--
--                                                            if l_estatus_gaston in  ('AS','PR','MA') then
--
--                                                                 begin
--
--                                                                         insert into SZSTUME values(l_grupo_disponible,
--                                                                                                    d.pidm,
--                                                                                                    d.matricula,
--                                                                                                    sysdate,
--                                                                                                    user,
--                                                                                                    5,
--                                                                                                    null,
--                                                                                                    d.pwd,
--                                                                                                    null,
--                                                                                                    1,
--                                                                                                    d.estatus_alumno,
--                                                                                                    null,
--                                                                                                    c.materia,
--                                                                                                    null, c.nivel,
--                                                                                                    null,
--                                                                                                    null,  c.ptrm,
--                                                                                                    null,
--                                                                                                    null,
--                                                                                                    null,
--                                                                                                    null,
--                                                                                                    c.materia,
--                                                                                                    p_inicio_clase,  c.inicio_clases,
--                                                                                                    c.regla,
--                                                                                                    c.secuencia
--                                                                                                    );
--
--                                                                         l_retorna:='EXITO';
--                                                                         dbms_output.put_line(' Exito Insert ');
--
--
--                                                                 exception when others then
--                                                                    null;
--                                                                 end;
--
--                                                                 BEGIN
--                                                                     UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='S'
--                                                                     WHERE 1 = 1
--                                                                     and (SZTPRONO_MATERIA_LEGAL = c.materia
--                                                                          OR
--                                                                          SZTPRONO_MATERIA_LEGAL = (SELECT SZTCOMA_SUBJ_CODE_BAN||SZTCOMA_CRSE_NUMB_BAN
--                                                                                                    FROM SZTCOMA
--                                                                                                    WHERE SZTCOMA_SUBJ_CODE_ADM||SZTCOMA_CRSE_NUMB_ADM = c.materia))
--                                                                     and SZTPRONO_PIDM =d.pidm
--                                                                     and SZTPRONO_NO_REGLA = c.regla
--                                                                     and SZTPRONO_FECHA_INICIO =c.inicio_clases
--                                                                     and SZTPRONO_ENVIO_MOODL ='N';
--
--                                                                 EXCEPTION WHEN OTHERS THEN
--                                                                     dbms_output.put_line(' Error al actualizar '||sqlerrm);
--
--                                                                     raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);
--                                                                 END;
--
--                                                            ELSIF l_estatus_gaston IN  ('BT','BD','CV','CM','BI','CC','CF') then
--
--                                                                 begin
--
--                                                                     SELECT DECODE(l_estatus_gaston,'BT','BAJA TEMPORAL','BD','BAJA TEMPORAL','BI', 'BAJA POR INACTIVIDAD','CV', 'CANCELACI”N DE VENTA','CM','CANCELACI”N DE MATRÕCULA','CC', 'CAMBIO DE CILO','CF','CAMBIO DE FECHA')
--                                                                     INTO l_descripcion_error
--                                                                     FROM DUAL;
--
--                                                                 exception when others then
--                                                                     l_descripcion_error:='Sin descripcion';
--                                                                 end;
--
--                                                                 Begin
--
--                                                                      UPDATE sztprono SET SZTPRONO_ESTATUS_ERROR ='S',
--                                                                                          SZTPRONO_DESCRIPCION_ERROR=l_descripcion_error
--
--                                                                      WHERE 1 = 1
--                                                                      AND SZTPRONO_MATERIA_LEGAL = d.materia
--                                                                      AND TRUNC (SZTPRONO_FECHA_INICIO) = p_inicio_clase
--                                                                      AND SZTPRONO_NO_REGLA=P_REGLA
--                                                                      AND SZTPRONO_PIDM=d.PIDM;
--
--                                                                 EXCEPTION WHEN OTHERS THEN
--                                                                   null;
--                                                                 END;
--
--                                                            end if;
--
--                                                      end loop;
--
--                                                end if;
--
--
--                                             end if;
--
--                                         else
--
--                                            return('EXITO');
--
--                                         end if;
--
--                                     end if;
--
--                                     EXIT WHEN L_CONTAR = e.vueltas;
--
--                                 end loop;
--
--                    end loop;
--
--                    commit;
--
--        else
--            dbms_output.put_line(' Esta regla no esta cerrada '||p_regla);
--           l_retorna:='Esta regla no esta cerrada regla = '||l_regla_cerrada;
--
--        end if;
--
--        RETURN(l_retorna);
--
--    end;

function f_alumnos_moodl(p_inicio_clase in VARCHAR2, p_regla in NUMBER)return varchar2
    as
    l_retorna            varchar2(1000);
    l_regla_cerrada      varchar2(1);
    l_contar             number;
    l_numero_grupos      number;
    vl_alumnos           number :=0;
    l_cuenta_alumnos     number;
    l_numero_alumnos     number;
    l_total              number;
    l_grupo_disponible   varchar2(100);
    l_numero_alumnos2    number;
    l_tope_grupos        number;
    l_total_alumnos      number;
    l_sobrecupo          number;
    l_cuenta_grupo       number;
    l_estatus_gaston     varchar2(10);
    l_descripcion_error  varchar2(500);



    begin



        BEGIN

            SELECT DISTINCT trim(SZTALGO_ESTATUS_CERRADO),SZTALGO_TOPE_ALUMNOS,SZTALGO_SOBRECUPO_ALUMNOS
            INTO  l_regla_cerrada,l_tope_grupos,l_sobrecupo
            FROM sztalgo
            WHERE 1 = 1
            AND sztalgo_no_regla = p_regla;

        EXCEPTION WHEN OTHERS THEN
            raise_application_error (-20002,'Error al   '||sqlerrm);
        END;

        IF l_regla_cerrada = 'S' THEN

            l_contar:=0;
            l_numero_alumnos2:=0;
            l_numero_alumnos:=0;


            for c in (
                          select SZTGPME_TERM_NRC padre,
                               sztgpme_no_regla regla,
                               sztgpme_subj_crse materia,
                              to_char(SZTGPME_START_DATE,'DD/MM/YYYY') inicio_clases,
                              to_number(f_get_group(p_regla,'04/03/2019',SZTGPME_TERM_NRC)) grupo,
                               SZTGPME_SECUENCIA secuencia
                        from sztgpme grp
                        where 1 = 1
                        and sztgpme_no_regla = p_regla
                        --and SZTGPME_START_DATE = p_inicio_clase
                        and to_number(f_get_group(p_regla,'04/03/2019',SZTGPME_TERM_NRC)) not in (select to_number(f_get_group(p_regla,'04/03/2019',SZSTUME_TERM_NRC))
                                                                                              from szstume
                                                                                              where 1 = 1
                                                                                              and szstume_no_regla =grp.sztgpme_no_regla
                                                                                              and SZSTUME_START_DATE =to_char(grp.SZTGPME_START_DATE,'DD/MM/YYYY')
                                                                                              and SZSTUME_SUBJ_CODE = grp.sztgpme_subj_crse
                                                                                              )
                        union -- cuando los alumnos no crean nuevos grupos
                        select (select SZTGPME_TERM_NRC
                                from SZTGPME
                                where 1 = 1
                                and SZTGPME_NO_REGLA = onf.sztconf_no_regla
                                and SZTGPME_START_DATE = to_char(to_date(onf.SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')
                                and SZTGPME_SUBJ_CRSE =onf.sztconf_subj_code
                                and to_number(f_get_group(p_regla,p_inicio_clase,SZTGPME_TERM_NRC)) = to_number(onf.SZTCONF_GROUP)
                                ) padre,
                                sztconf_no_regla regla,
                                SZTCONF_SUBJ_CODE materia,
                                to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')inicio_clases,
                                to_number(SZTCONF_GROUP) grupo,
                                SZTCONF_SECUENCIA secuencia
                        from sztconf onf
                        where 1 = 1
                        and sztconf_no_regla = p_regla
                        --and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY') =p_inicio_clase
                        and sztconf_subj_code in (select (select SZTMACO_MATPADRE
                                                            from sztmaco
                                                            where 1 = 1
                                                            and SZTNINC_SUBJ_CODE||SZTNINC_CRSE_NUMB = SZTMACO_MATHIJO ) materia_padre
                                                    from sztninc inc
                                                    where 1 = 1
                                                    and sztninc_no_regla = p_regla
                                                    and exists (select null
                                                                from sztprono
                                                                where 1 = 1
                                                                and sztprono_no_regla = p_regla
                                                                --and to_char(to_date(SZTPRONO_FECHA_INICIO_NW,'DD/MM/YYYY'),'DD/MM/YYYY') =p_inicio_clase
                                                                and sztprono_no_regla = sztninc_no_regla
                                                                and sztprono_pidm = sztninc_pidm
                                                                and SZTPRONO_ENVIO_MOODL ='N'
                                                                and SZTPRONO_ESTATUS_ERROR ='N')
                                                       )

--                         select SZTGPME_TERM_NRC padre,
--                               sztgpme_no_regla regla,
--                               sztgpme_subj_crse materia,
--                               SZTGPME_SECUENCIA secuencia,
--                              to_char(SZTGPME_START_DATE,'DD/MM/YYYY') inicio_clases
--                        from sztgpme
--                        where 1 = 1
--                        and sztgpme_no_regla = p_regla
--                        and SZTGPME_START_DATE = p_inicio_clase
--                        and SZTGPME_SECUENCIA not in (select szstume_secuencia
--                                                      from szstume
--                                                      where 1 = 1
--                                                      and szstume_no_regla = p_regla
--                                                      and szstume_secuencia is not null)
--                        union -- cuando los alumnos no crean nuevos grupos
--                        select (select SZTGPME_TERM_NRC
--                                from SZTGPME
--                                where 1 = 1
--                                and SZTGPME_secuencia = SZTCONF_SECUENCIA) padre,
--                                sztconf_no_regla regla,
--                                SZTCONF_SUBJ_CODE materia,
--                                SZTCONF_SECUENCIA secuencia,
--                                to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')inicio_clases
--                        from sztconf
--                        where 1 = 1
--                        and sztconf_no_regla = p_regla
--                        and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY') =p_inicio_clase
--                        and sztconf_subj_code in (select (select SZTMACO_MATPADRE
--                                                            from sztmaco
--                                                            where 1 = 1
--                                                            and SZTNINC_SUBJ_CODE||SZTNINC_CRSE_NUMB = SZTMACO_MATHIJO ) materia_padre
--                                                    from sztninc inc
--                                                    where 1 = 1
--                                                    and sztninc_no_regla = p_regla
--                                                    and exists (select null
--                                                                from sztprono
--                                                                where 1 = 1
--                                                                and sztprono_no_regla = p_regla
--                                                                and to_char(to_date(SZTPRONO_FECHA_INICIO_NW,'DD/MM/YYYY'),'DD/MM/YYYY') =p_inicio_clase
--                                                                and sztprono_no_regla = sztninc_no_regla
--                                                                and sztprono_pidm = sztninc_pidm
--                                                                and SZTPRONO_ENVIO_MOODL ='N'
--                                                                and SZTPRONO_ESTATUS_ERROR ='N')
--                                                       )

                    )
                    loop

                               -- dbms_output.put_line(' Entra agrupos ');

                                 for e in(select count(*) vueltas
                                             from sztconf onf
                                             where 1 = 1
                                             and onf.sztconf_no_regla = c.regla
                                             and onf.SZTCONF_FECHA_INICIO =c.inicio_clases
                                             and SZTCONF_SUBJ_CODE=c.materia
                                             AND SZTCONF_GROUP = c.grupo
                                 )
                                 loop

                                     --dbms_output.put_line(' Entra alumno no alumnos  '||l_cuenta_alumnos);

                                      l_contar:=l_contar+1;

                                      select count(*)
                                      into l_cuenta_alumnos
                                      from szstume
                                      where 1 = 1
                                      and szstume_no_regla = c.regla
                                      and SZSTUME_SUBJ_CODE = c.materia
                                      and SZSTUME_TERM_NRC = c.padre;

                                     dbms_output.put_line(' Entra alumno no alumnos  '||l_cuenta_alumnos);

                                     if l_cuenta_alumnos = 0 then



                                        begin

                                            select SZTCONF_STUDENT_NUMB
                                            into l_numero_alumnos2
                                            from sztconf
                                            where 1 = 1
                                            and sztconf_no_regla  = c.regla
                                            and sztconf_subj_code = c.materia
                                            and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')=c.inicio_clases
                                            and to_number(SZTCONF_GROUP)= c.grupo;
--                                            and sztconf_secuencia = c.secuencia;
                                        exception when others then
                                            null;
                                        end;


                                         --dbms_output.put_line(' Materia  '||c.materia||' Padre '||c.padre||' alumnos '||l_cuenta_alumnos||'ALUMNOS 2'||l_numero_alumnos2);

                                         for d in (
                                                     select sztprono_id matricula,
                                                            SZTPRONO_PIDM pidm,
                                                             'RE'  estatus_alumno,
                                                             (select GOZTPAC_PIN
                                                               from GOZTPAC pac
                                                               where 1 = 1
                                                               and pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM ) pwd,
                                                               SZTPRONO_COMENTARIO comentario,
                                                               65 tope,
                                                               SZTPRONO_PROGRAM programa,
                                                               sztprono_materia_legal materia
                                                      from sztprono ono
                                                      where 1 = 1
                                                      and sztprono_no_regla  = c.regla
                                                      and sztprono_materia_legal = c.materia
                                                      and rownum <= l_numero_alumnos2
                                                      and SZTPRONO_FECHA_INICIO = c.inicio_clases
                                                      And SZTPRONO_ENVIO_MOODL = 'N'
                                                  )
                                              loop



--
--                                                   begin
--
--                                                       select SGBSTDN_STST_CODE
--                                                       into l_estatus_gaston
--                                                       from sgbstdn a
--                                                       where 1 = 1
--                                                       and SGBSTDN_pidm = d.pidm
--                                                       and sgbstdn_program_1  = d.programa
--                                                       And a.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
--                                                                                      from sgbstdn b1
--                                                                                      Where a.sgbstdn_pidm = b1.sgbstdn_pidm
--                                                                                      And a.sgbstdn_program_1 = b1.sgbstdn_program_1);
--
--
--                                                   exception when others then
--                                                       l_estatus_gaston:='MA';
--                                                   end;
--
--                                                   dbms_output.put_line(' Materia  '||c.materia||' Padre '||c.padre||' alumnos '||l_cuenta_alumnos||' mATRICULA '||D.matricula||' ESTATUS '||l_estatus_gaston);
--
--                                                   --dbms_output.put_line(' Materia  '||c.materia||' Padre '||c.padre||' alumnos '||' pidm' ||d.pidm||' Matriucla '||d.matricula||' Gaston '||l_estatus_gaston);
--
--                                                   if l_estatus_gaston in  ('AS','PR','MA',NULL) then


                                                        begin

                                                            --dbms_output.put_line(' Materia  '||c.materia||' Padre '||c.padre||' alumnos '||' pidm' ||d.pidm||' Matriucla '||d.matricula||' Gaston '||l_estatus_gaston);

                                                            insert into SZSTUME values(c.padre,
                                                                                       d.pidm,
                                                                                       d.matricula,
                                                                                       sysdate,
                                                                                       user,
                                                                                       5,
                                                                                       null,
                                                                                       d.pwd,
                                                                                       null,
                                                                                       1,
                                                                                       d.estatus_alumno,
                                                                                       null,
                                                                                       c.materia,
                                                                                       null,-- c.nivel,
                                                                                       null,
                                                                                       null,--  c.ptrm,
                                                                                       null,
                                                                                       null,
                                                                                       null,
                                                                                       null,
                                                                                       c.materia,
                                                                                       p_inicio_clase,--  c.inicio_clases,
                                                                                       c.regla,
                                                                                       c.secuencia,
                                                                                       1,
                                                                                       0,
                                                                                       NULL
                                                                                       );

                                                            l_retorna:='EXITO';
                                                           -- dbms_output.put_line(' Exito Insert ');


                                                        exception when others then

                                                            dbms_output.put_line(' Error al insertar '||sqlerrm);



                                                        end;

                                                        BEGIN
                                                            UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='S'
                                                            WHERE 1 = 1
                                                            and SZTPRONO_MATERIA_LEGAL = c.materia
                                                            and SZTPRONO_PIDM =d.pidm
                                                            and SZTPRONO_NO_REGLA = c.regla
                                                            and SZTPRONO_FECHA_INICIO =c.inicio_clases
                                                            and SZTPRONO_ENVIO_MOODL ='N';

                                                            l_retorna:='EXITO';

                                                        EXCEPTION WHEN OTHERS THEN
                                                            --dbms_output.put_line(' Error al actualizar '||sqlerrm);

                                                            raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);
                                                        END;

                                                        commit;

--                                                   ELSE
----
----
--                                                       begin
--
--                                                           SELECT DECODE(l_estatus_gaston,'BT','BAJA TEMPORAL','BD','BAJA TEMPORAL','BI', 'BAJA POR INACTIVIDAD','CV', 'CANCELACI”N DE VENTA','CM','CANCELACI”N DE MATRÕCULA','CC', 'CAMBIO DE CILO','CF','CAMBIO DE FECHA','CP','CAMBIO DE PROGRAMA','EG','EGRESADO')
--                                                           INTO L_DESCRIPCION_ERROR
--                                                           FROM DUAL;
--
--                                                       exception when others then
--                                                           l_estatus_gaston:='SD';
--                                                           l_descripcion_error:='Sin descripcion';
--                                                       end;
--
--
--                                                       Begin
--
--                                                            UPDATE sztprono SET SZTPRONO_ESTATUS_ERROR ='S',
--                                                                                SZTPRONO_DESCRIPCION_ERROR=L_DESCRIPCION_ERROR
--
--                                                            WHERE 1 = 1
--                                                            AND SZTPRONO_MATERIA_LEGAL = d.materia
--                                                            AND TRUNC (SZTPRONO_FECHA_INICIO) = p_inicio_clase
--                                                            AND SZTPRONO_NO_REGLA=P_REGLA
--                                                            AND SZTPRONO_PIDM=d.PIDM;
--
--                                                       EXCEPTION WHEN OTHERS THEN
--                                                          dbms_output.put_line(' Error al actualizar '||sqlerrm);
--                                                       END;

                                                --   end if;

                                              end loop;

                                              commit;

                                     elsif l_cuenta_alumnos >0 then

                                        dbms_output.put_line('Entra 2da parte ');


                                        for x in (select distinct sztprono_materia_legal materia
                                                  from sztprono
                                                  where 1 = 1
                                                  and sztprono_no_regla = c.regla
                                                  and sztprono_envio_moodl ='N'
                                                  and SZTPRONO_ESTATUS_ERROR='N')

                                                 loop

                                                    --dbms_output.put_line('Error al obtener numero de alumnos  '||l_numero_alumnos||' Materia '||c.materia);

                                                     BEGIN

                                                         select COUNT(DISTINCT SZTPRONO_ID)
                                                         into l_numero_alumnos
                                                         from sztprono
                                                         where 1 = 1
                                                         and sztprono_no_regla = p_regla
                                                         and SZTPRONO_ENVIO_MOODL ='N'
                                                         and sztprono_materia_legal =x.materia;

                                                         l_retorna:='EXITO';

                                                     EXCEPTION WHEN OTHERS THEN
                                                        dbms_output.put_line('Error al obtener numero de alumnos  '||l_numero_alumnos||' Materia '||c.materia);


                                                     END;

                                                 end loop;


                                         if l_numero_alumnos> 0 then

                                             begin

                                                  select total, grupo
                                                  into l_total,l_grupo_disponible
                                                  from
                                                  (
                                                  select count(SZSTUME_ID) total,SZSTUME_TERM_NRC grupo,SZSTUME_USER_ID
                                                  from szstume
                                                  where 1 = 1
                                                  and szstume_no_regla = c.regla
                                                  --AND SZSTUME_USER_ID ='LILIA.RAMIREZ'
                                                  and SZSTUME_TERM_NRC in ( select distinct SZTGPME_TERM_NRC
                                                                           from sztgpme
                                                                           where 1 = 1
                                                                           and sztgpme_no_regla = c.regla
                                                                           and SZTGPME_SUBJ_CRSE = c.materia
                                                  --                         order by 1
                                                                           )
                                                  group by SZSTUME_TERM_NRC,SZSTUME_USER_ID
                                                  )x
                                                  where 1 = 1
                                                  AND rownum = 1
                                                  and total = ( select min(total)
                                                               from
                                                               (
                                                               select count(SZSTUME_ID) total,SZSTUME_TERM_NRC grupo,SZSTUME_USER_ID
                                                               from szstume
                                                               where 1 = 1
                                                               and szstume_no_regla = c.regla
                                                               --AND SZSTUME_USER_ID ='LILIA.RAMIREZ'
                                                               and SZSTUME_TERM_NRC in ( select distinct SZTGPME_TERM_NRC
                                                                                        from sztgpme
                                                                                        where 1 = 1
                                                                                        and sztgpme_no_regla =c.regla
                                                                                        and SZTGPME_SUBJ_CRSE =c.materia
                                                               --                         order by 1
                                                                                        )
                                                               group by SZSTUME_TERM_NRC,SZSTUME_USER_ID
                                                                   ));
                                             EXCEPTION WHEN OTHERS THEN
                                              dbms_output.put_line('Error al obtener total de alumnos '||l_total||' materia '||l_grupo_disponible);

                                             END;

                                             if c.padre =l_grupo_disponible then

                                                l_total_alumnos:=l_numero_alumnos+l_total;

                                                l_sobrecupo:= l_tope_grupos+l_sobrecupo;

                                                if l_total_alumnos > l_tope_grupos  then

                                                   if l_total_alumnos<= l_sobrecupo then


                                                    dbms_output.put_line('Numero de alumnos '||l_numero_alumnos||' grupo '||l_grupo_disponible||' Materia '||c.materia||' Secuencia '||c.secuencia||' alumnos en grupo '||l_total||' como queda el grupo '||l_total_alumnos||' Sobrecupo '||l_sobrecupo);

                                                         for d in (
                                                         select sztprono_id matricula,
                                                                SZTPRONO_PIDM pidm,
                                                                 'RE'  estatus_alumno,
                                                                 (select GOZTPAC_PIN
                                                                   from GOZTPAC pac
                                                                   where 1 = 1
                                                                   and pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM ) pwd,
                                                                   SZTPRONO_COMENTARIO comentario,
                                                                   65 tope,
                                                                   SZTPRONO_PROGRAM programa,
                                                                   sztprono_materia_legal materia
                                                          from sztprono ono
                                                          where 1 = 1
                                                          and sztprono_no_regla  = c.regla
                                                          and sztprono_materia_legal = c.materia
                                                          and rownum <= l_numero_alumnos
                                                          and SZTPRONO_FECHA_INICIO = c.inicio_clases
                                                          And SZTPRONO_ENVIO_MOODL = 'N'
                                                      )
                                                      loop


                                                             begin


                                                                         insert into SZSTUME values(l_grupo_disponible,
                                                                                                    d.pidm,
                                                                                                    d.matricula,
                                                                                                    sysdate,
                                                                                                    user,
                                                                                                    5,
                                                                                                    null,
                                                                                                    d.pwd,
                                                                                                    null,
                                                                                                    1,
                                                                                                    d.estatus_alumno,
                                                                                                    null,
                                                                                                    c.materia,
                                                                                                    null,-- c.nivel,
                                                                                                    null,
                                                                                                    null,--  c.ptrm,
                                                                                                    null,
                                                                                                    null,
                                                                                                    null,
                                                                                                    null,
                                                                                                    c.materia,
                                                                                                    p_inicio_clase,--  c.inicio_clases,
                                                                                                    c.regla,
                                                                                                    c.secuencia,
                                                                                                    1,
                                                                                                    0,
                                                                                                    null
                                                                                                    );

                                                                         l_retorna:='EXITO';
                                                                         dbms_output.put_line(' Exito Insert ');


                                                             exception when others then
                                                               dbms_output.put_line(' error al  Insert '||sqlerrm);
                                                             end;

                                                             BEGIN
                                                                 UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='S'
                                                                 WHERE 1 = 1
                                                                 and SZTPRONO_MATERIA_LEGAL = c.materia
                                                                 and SZTPRONO_PIDM =d.pidm
                                                                 and SZTPRONO_NO_REGLA = c.regla
                                                                 and SZTPRONO_FECHA_INICIO =c.inicio_clases
                                                                 and SZTPRONO_ENVIO_MOODL ='N';

                                                             EXCEPTION WHEN OTHERS THEN
                                                                 dbms_output.put_line(' Error al actualizar '||sqlerrm);

                                                                 raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);
                                                             END;
--

                                                      end loop;

                                                   elsif  l_total_alumnos> l_sobrecupo then

                                                    null;

                                                   end if;


                                                elsif  l_total_alumnos <= l_tope_grupos then


                                                     dbms_output.put_line('Numero de alumnos '||l_numero_alumnos||' grupo '||l_grupo_disponible||' Materia '||c.materia||' Secuencia '||c.secuencia||' alumnos en grupo '||l_total||' como queda el grupo '||l_total_alumnos);

                                                      for d in (
                                                     select sztprono_id matricula,
                                                            SZTPRONO_PIDM pidm,
                                                             'RE'  estatus_alumno,
                                                             (select GOZTPAC_PIN
                                                               from GOZTPAC pac
                                                               where 1 = 1
                                                               and pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM ) pwd,
                                                               SZTPRONO_COMENTARIO comentario,
                                                               65 tope,
                                                               sztprono_program programa,
                                                               sztprono_materia_legal materia
                                                      from sztprono ono
                                                      where 1 = 1
                                                      and sztprono_no_regla  = c.regla
                                                      and sztprono_materia_legal = c.materia
                                                      and rownum <= l_numero_alumnos
                                                      and SZTPRONO_FECHA_INICIO = c.inicio_clases
                                                      And SZTPRONO_ENVIO_MOODL = 'N'
                                                  )
                                                      loop

--                                                            begin
--
--                                                                 select SGBSTDN_STST_CODE
--                                                                 into l_estatus_gaston
--                                                                 from sgbstdn a
--                                                                 where 1 = 1
--                                                                 and SGBSTDN_pidm = d.pidm
--                                                                 and sgbstdn_program_1  = d.programa
--                                                                 And a.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
--                                                                                                from sgbstdn b1
--                                                                                                Where a.sgbstdn_pidm = b1.sgbstdn_pidm
--                                                                                                And a.sgbstdn_program_1 = b1.sgbstdn_program_1);
--
--
--                                                            exception when others then
--                                                                null;
--                                                            end;

--                                                            if l_estatus_gaston in  ('AS','PR','MA') then

                                                                 begin

                                                                         insert into SZSTUME values(l_grupo_disponible,
                                                                                                    d.pidm,
                                                                                                    d.matricula,
                                                                                                    sysdate,
                                                                                                    user,
                                                                                                    5,
                                                                                                    null,
                                                                                                    d.pwd,
                                                                                                    null,
                                                                                                    1,
                                                                                                    d.estatus_alumno,
                                                                                                    null,
                                                                                                    c.materia,
                                                                                                    null,-- c.nivel,
                                                                                                    null,
                                                                                                    null,--  c.ptrm,
                                                                                                    null,
                                                                                                    null,
                                                                                                    null,
                                                                                                    null,
                                                                                                    c.materia,
                                                                                                    p_inicio_clase,--  c.inicio_clases,
                                                                                                    c.regla,
                                                                                                    c.secuencia,
                                                                                                    1,
                                                                                                    0,
                                                                                                    NULL
                                                                                                    );

                                                                         l_retorna:='EXITO';
                                                                        -- dbms_output.put_line(' Exito Insert ');


                                                                 exception when others then
                                                                    null;
                                                                 end;

                                                                 BEGIN
                                                                     UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='S'
                                                                     WHERE 1 = 1
                                                                     and (SZTPRONO_MATERIA_LEGAL = c.materia
                                                                          OR
                                                                          SZTPRONO_MATERIA_LEGAL = (SELECT SZTCOMA_SUBJ_CODE_BAN||SZTCOMA_CRSE_NUMB_BAN
                                                                                                    FROM SZTCOMA
                                                                                                    WHERE SZTCOMA_SUBJ_CODE_ADM||SZTCOMA_CRSE_NUMB_ADM = c.materia))
                                                                     and SZTPRONO_PIDM =d.pidm
                                                                     and SZTPRONO_NO_REGLA = c.regla
                                                                     and SZTPRONO_FECHA_INICIO =c.inicio_clases
                                                                     and SZTPRONO_ENVIO_MOODL ='N';

                                                                 EXCEPTION WHEN OTHERS THEN
                                                                     dbms_output.put_line(' Error al actualizar '||sqlerrm);

                                                                     raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);
                                                                 END;

--                                                            ELSIF l_estatus_gaston IN  ('BT','BD','CV','CM','BI','CC','CF') then
--
--                                                                 begin
--
--                                                                     SELECT DECODE(l_estatus_gaston,'BT','BAJA TEMPORAL','BD','BAJA TEMPORAL','BI', 'BAJA POR INACTIVIDAD','CV', 'CANCELACI”N DE VENTA','CM','CANCELACI”N DE MATRÕCULA','CC', 'CAMBIO DE CILO','CF','CAMBIO DE FECHA')
--                                                                     INTO l_descripcion_error
--                                                                     FROM DUAL;
--
--                                                                 exception when others then
--                                                                     l_descripcion_error:='Sin descripcion';
--                                                                 end;
--
--                                                                 Begin
--
--                                                                      UPDATE sztprono SET SZTPRONO_ESTATUS_ERROR ='S',
--                                                                                          SZTPRONO_DESCRIPCION_ERROR=l_descripcion_error
--
--                                                                      WHERE 1 = 1
--                                                                      AND SZTPRONO_MATERIA_LEGAL = d.materia
--                                                                      AND TRUNC (SZTPRONO_FECHA_INICIO) = p_inicio_clase
--                                                                      AND SZTPRONO_NO_REGLA=P_REGLA
--                                                                      AND SZTPRONO_PIDM=d.PIDM;
--
--                                                                 EXCEPTION WHEN OTHERS THEN
--                                                                   null;
--                                                                 END;

--                                                            end if;

                                                      end loop;

                                                end if;


                                             end if;

                                         else

                                            return('EXITO');

                                         end if;

                                     end if;

                                     EXIT WHEN L_CONTAR = e.vueltas;

                                 end loop;

                    end loop;

                    commit;

        else
            dbms_output.put_line(' Esta regla no esta cerrada '||p_regla);
           l_retorna:='Esta regla no esta cerrada regla = '||l_regla_cerrada;

        end if;

        RETURN(l_retorna);

    end;

     FUNCTION f_docentes_moodle_out
      RETURN PKG_MOODLE2.cursor_dctes_out
   AS
      dctes_out   PKG_MOODLE2.cursor_dctes_out;
   --- Esta Funcion realiza el envio de la informacion de los docentes hacia Moodle
   ----- Se realiza modificacion para version final 02-Jun- 2017   ------
   ----- Preguntar antes de modificar -----
   -----    vmrl   -----


   BEGIN
      BEGIN
         OPEN dctes_out FOR
              SELECT SZTGPME_TERM_NRC,
                     SZTGPME_CRSE_MDLE_CODE short_name,
                     SZTGPME_START_DATE Fecha_inicio,
                     SZTGPME_SUBJ_CRSE_COMP SZTGPME_SUBJ_CRSE,
                     SZTGPME_GPMDLE_ID,
                     SZTGPME_CRSE_MDLE_ID,
                     SZSGNME_PIDM,
                     SPRIDEN_ID,
                     SZSGNME_STAT_IND,
                     REPLACE (TRANSLATE (SPRIDEN.SPRIDEN_LAST_NAME,'·ÈÌÛ˙¡…Õ”⁄','aeiouAEIOU'),'/',' ') LAST_NAME,
                     SPRIDEN_FIRST_NAME,
                     SZSGNME_PWD,
                     CASE
                     WHEN GOREMAL_EMAIL_ADDRESS IS NULL THEN
                     SPRIDEN_ID || '@utel.edu.mx'
                     ELSE
                     GOREMAL_EMAIL_ADDRESS
                     END CORREO,
                     SZTGPME_PTRM_CODE_COMP servidor,
                     SZSGNME_NO_REGLA no_regla,
                     SZTGPME_CAMP_CODE campus,
                     SZTGPME_LEVL_CODE Nivel,
                     SZTMAUR_ORIGEN tipo_curso
                FROM SZTGPME,
                     SZSGNME,
                     SPRIDEN,
                     GOREMAL,
                     ZSTPARA,
                     SZTMAUR
               WHERE SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_START_DATE = SZSGNME_START_DATE
                     AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                     AND SZSGNME_PIDM = SPRIDEN_PIDM
                     AND SZSGNME_PIDM = GOREMAL_PIDM(+)
                     AND GOREMAL_EMAL_CODE = NVL ('PRIN', GOREMAL_EMAL_CODE)
                     AND SZTGPME_STAT_IND = '1'
                     AND SZTGPME_CRSE_MDLE_ID != 0
                     AND SZSGNME_STAT_IND IN ('0')
                     AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                     AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2)
                     AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                     AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                     AND SZTMAUR_ACTIVO = 'S'
                     AND SZTMAUR_ORIGEN <> 'E'
                     AND SZSGNME_NO_REGLA <> 99
                     AND SPRIDEN_CHANGE_IND IS NULL
                     AND SZTGPME_CAMP_CODE != 'EAF'
                      --AND SZSGNME_NO_REGLA = 192--IN (164, 149)
                     --AND SZTGPME_CAMP_CODE <>'UVE'
					 AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                 UNION
                     SELECT SZTGPME_TERM_NRC,
                     SZTGPME_CRSE_MDLE_CODE short_name,
                     SZTGPME_START_DATE Fecha_inicio,
                     SZTGPME_SUBJ_CRSE_COMP SZTGPME_SUBJ_CRSE,
                     SZTGPME_GPMDLE_ID,
                     SZTGPME_CRSE_MDLE_ID,
                     SZSGNME_PIDM,
                     SPRIDEN_ID,
                     SZSGNME_STAT_IND,
                     REPLACE (TRANSLATE (SPRIDEN.SPRIDEN_LAST_NAME,'·ÈÌÛ˙¡…Õ”⁄','aeiouAEIOU'),'/',' ') LAST_NAME,
                     SPRIDEN_FIRST_NAME,
                     SZSGNME_PWD,
                     CASE
                     WHEN GOREMAL_EMAIL_ADDRESS IS NULL THEN
                     SPRIDEN_ID || '@utel.edu.mx'
                     ELSE
                     GOREMAL_EMAIL_ADDRESS
                     END CORREO,
                     SZTGPME_PTRM_CODE_COMP servidor,
                     SZSGNME_NO_REGLA no_regla,
                     SZTGPME_CAMP_CODE campus,
                     SZTGPME_LEVL_CODE Nivel,
                     SZTMAUR_ORIGEN tipo_curso
                FROM SZTGPME,
                     SZSGNME,
                     SPRIDEN,
                     GOREMAL,
                     ZSTPARA,
                     SZTMAUR
               WHERE SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_START_DATE = SZSGNME_START_DATE
                     AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                     AND SZSGNME_PIDM = SPRIDEN_PIDM
                     AND SZSGNME_PIDM = GOREMAL_PIDM(+)
                     AND GOREMAL_EMAL_CODE = NVL ('PRIN', GOREMAL_EMAL_CODE)
                     AND SZTGPME_STAT_IND = '1'
                     AND SZTGPME_CRSE_MDLE_ID != 0
                     AND SZSGNME_STAT_IND IN ('0')
                     AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                     AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2)
                     AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                     AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                     AND SZTMAUR_ACTIVO = 'S'
                     AND SZTMAUR_ORIGEN <> 'E'
                     AND SZSGNME_NO_REGLA <> 99
                     AND SPRIDEN_CHANGE_IND IS NULL
                     AND SZTGPME_CAMP_CODE != 'EAF'
                     AND SZTMAUR_ORIGEN = 'I'
					 AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                 UNION
                     SELECT SZTGPME_TERM_NRC,
                     SZTGPME_CRSE_MDLE_CODE short_name,
                     SZTGPME_START_DATE Fecha_inicio,
                     SZTGPME_SUBJ_CRSE_COMP SZTGPME_SUBJ_CRSE,
                     SZTGPME_GPMDLE_ID,
                     SZTGPME_CRSE_MDLE_ID,
                     SZSGNME_PIDM,
                     SPRIDEN_ID,
                     SZSGNME_STAT_IND,
                     REPLACE (TRANSLATE (SPRIDEN.SPRIDEN_LAST_NAME,'·ÈÌÛ˙¡…Õ”⁄','aeiouAEIOU'),'/',' ') LAST_NAME,
                     SPRIDEN_FIRST_NAME,
                     SZSGNME_PWD,
                     CASE
                     WHEN GOREMAL_EMAIL_ADDRESS IS NULL THEN
                     SPRIDEN_ID || '@utel.edu.mx'
                     ELSE
                     GOREMAL_EMAIL_ADDRESS
                     END
                     CORREO,
                     SZTGPME_PTRM_CODE_COMP servidor,
                     SZSGNME_NO_REGLA no_regla,
                     SZTGPME_CAMP_CODE campus,
                     SZTGPME_LEVL_CODE Nivel,
                     SZTMAUR_ORIGEN tipo_curso
                FROM SZTGPME,
                     SZSGNME,
                     SPRIDEN,
                     GOREMAL,
                     ZSTPARA,
                     SZTMAUR
               WHERE SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_START_DATE= SZSGNME_START_DATE
                     AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                     AND SZSGNME_PIDM = SPRIDEN_PIDM
                     AND SZSGNME_PIDM = GOREMAL_PIDM(+)
                     AND GOREMAL_EMAL_CODE = NVL ('PRIN', GOREMAL_EMAL_CODE)
                     AND SZTGPME_STAT_IND = '1'
                     AND SZTGPME_CRSE_MDLE_ID != 0
                     AND SZSGNME_STAT_IND = '0'
                     AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                     AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2)
                     AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                     AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                     AND SZTMAUR_ACTIVO = 'S'
                     AND SZTMAUR_ORIGEN = 'E'
                     AND SZSGNME_NO_REGLA = 99
                     AND SPRIDEN_CHANGE_IND IS NULL
                     AND SZTGPME_CAMP_CODE != 'EAF'
--					 AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                      UNION
                     SELECT SZTGPME_TERM_NRC,
                     SZTGPME_CRSE_MDLE_CODE short_name,
                     SZTGPME_START_DATE Fecha_inicio,
                     SZTGPME_SUBJ_CRSE_COMP SZTGPME_SUBJ_CRSE,
                     SZTGPME_GPMDLE_ID,
                     SZTGPME_CRSE_MDLE_ID,
                     SZSGNME_PIDM,
                     SPRIDEN_ID,
                     SZSGNME_STAT_IND,
                     REPLACE (TRANSLATE (SPRIDEN.SPRIDEN_LAST_NAME,'·ÈÌÛ˙¡…Õ”⁄','aeiouAEIOU'),'/',' ') LAST_NAME,
                     SPRIDEN_FIRST_NAME,
                     SZSGNME_PWD,
                     CASE
                     WHEN GOREMAL_EMAIL_ADDRESS IS NULL THEN
                     SPRIDEN_ID || '@utel.edu.mx'
                     ELSE
                     GOREMAL_EMAIL_ADDRESS
                     END
                     CORREO,
                     SZTGPME_PTRM_CODE_COMP servidor,
                     SZSGNME_NO_REGLA no_regla,
                     SZTGPME_CAMP_CODE campus,
                     SZTGPME_LEVL_CODE Nivel,
                     SZTMAUR_ORIGEN tipo_curso
                FROM SZTGPME,
                     SZSGNME,
                     SPRIDEN,
                     GOREMAL,
                     ZSTPARA,
                     SZTMAUR
               WHERE SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_START_DATE= SZSGNME_START_DATE
                     AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                     AND SZSGNME_PIDM = SPRIDEN_PIDM
                     AND SZSGNME_PIDM = GOREMAL_PIDM(+)
                     AND GOREMAL_EMAL_CODE = NVL ('PRIN', GOREMAL_EMAL_CODE)
                     AND SZTGPME_STAT_IND = '1'
                     AND SZTGPME_CRSE_MDLE_ID != 0
                     AND SZSGNME_STAT_IND = '0'
                     AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
--                     AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2)
                     AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                     AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                     AND SZTMAUR_ACTIVO = 'S'
                     AND SZTMAUR_ORIGEN = 'N'
                     AND SZSGNME_NO_REGLA = 1
                     AND SPRIDEN_CHANGE_IND IS NULL
                     AND SZTGPME_CAMP_CODE != 'EAF'
                     AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                     ORDER BY 2;
         RETURN (dctes_out);
      END;
   END f_docentes_moodle_out;

FUNCTION f_updte_docentes_moodle_out (p_crsemdle_id in number, p_pidm in number, p_stat_upte_ind in Varchar2, p_obs in Varchar2, p_asgn_mdle in Varchar2,p_error_code in Number,  p_error_desc in Varchar2,  p_pidm_ant in number, p_no_regla in number, p_term_nrc in varchar2, p_fecha_ini in varchar2) Return Varchar2
    AS
        vl_maximo number:=0;
        vl_error  varchar2(250) := 'Proceso exitoso';
               --- Esta Funcion realiza la actualizacion del envio de los docentes y actualiza los estatus de envio y error de cada registro de docente
              ----- Se realiza modificacion para version final 02-Jun- 2017   ------
              ----- Preguntar antes de modificar -----
              -----    vmrl   -----



            BEGIN

                  for c in (  SELECT SZSGNME_STAT_IND, SZSGNME_OBS, SZSGNME_ASGNMDLE_ID, SZSGNME_TERM_NRC, SZSGNME_START_DATE
                                FROM SZSGNME, SZTGPME
                                WHERE  SZTGPME_TERM_NRC=SZSGNME_TERM_NRC
                                AND SZTGPME_CRSE_MDLE_ID= p_crsemdle_id
                                AND SZSGNME_PIDM = p_pidm
                                AND SZSGNME_NO_REGLA = p_no_regla
                                AND SZSGNME_TERM_NRC = p_term_nrc
                                AND SZSGNME_START_DATE = p_fecha_ini
                                AND SZTGPME_CAMP_CODE != 'EAF'
                                )

                 loop



                             IF  p_stat_upte_ind = 2 THEN

                                 Begin
                                      Select nvl (max (SZTMEBI_SEQ_NO), 0 ) +1
                                      Into vl_maximo
                                      from SZTMEBI
                                      Where SZTMEBI_TERM_NRC = c.SZSGNME_TERM_NRC
                                      and SZTMEBI_CTGY_ID = 'Docentes';
                                Exception
                                When Others then
                                vl_maximo :=1;
                                END;


                                begin
                                   INSERT INTO SZTMEBI
                                   VALUES(c.SZSGNME_TERM_NRC, p_stat_upte_ind, p_error_code, p_error_desc,vl_maximo, sysdate,USER, 'Docentes',p_pidm );
                                Exception
                                When others then
                                vl_error := 'Error al insertar Docentes en la Bitacora'||sqlerrm;
                                End;


                                begin
                                     UPDATE SZSGNME
                                     SET SZSGNME_STAT_IND = p_stat_upte_ind,
                                     SZSGNME_OBS = 'Error de sincronia ver SZTMEBI',
                                     SZSGNME_ACTIVITY_DATE = sysdate
                                     WHERE SZSGNME_TERM_NRC = c.SZSGNME_TERM_NRC
                                     AND SZSGNME_PIDM = p_pidm
                                     AND SZSGNME_NO_REGLA = p_no_regla
                                     AND SZSGNME_START_DATE = c.SZSGNME_START_DATE;
                                Exception
                                When others then
                                  vl_error := 'Error al actualizar Docentes'||sqlerrm;
                                end;


                             ELSIF p_stat_upte_ind =5 THEN

                               begin
                                   UPDATE SZSGNME
                                   SET SZSGNME_FCST_CODE = 'IN',
                                   SZSGNME_OBS = p_obs,
                                   SZSGNME_ACTIVITY_DATE = sysdate
                                   WHERE SZSGNME_TERM_NRC = c.SZSGNME_TERM_NRC
                                  AND SZSGNME_ASGNMDLE_ID = p_pidm_ant
                                  AND SZSGNME_NO_REGLA = p_no_regla
                                  AND SZSGNME_START_DATE = c.SZSGNME_START_DATE;
                                Exception
                                When others then
                                vl_error := 'Error al actualizar Docentes'||sqlerrm;
                             end;

                             ELSIF   p_stat_upte_ind =1 then
                                 Begin
                                  UPDATE SZSGNME
                                  SET SZSGNME_STAT_IND = p_stat_upte_ind,
                                  SZSGNME_OBS = p_obs,
                                  SZSGNME_ASGNMDLE_ID = p_asgn_mdle,
                                  SZSGNME_ACTIVITY_DATE = sysdate
                                  WHERE SZSGNME_TERM_NRC = c.SZSGNME_TERM_NRC
                                  AND SZSGNME_PIDM = p_pidm
                                  AND SZSGNME_NO_REGLA = p_no_regla
                                  AND SZSGNME_START_DATE = c.SZSGNME_START_DATE;
                                Exception
                                When others then
                                  vl_error := 'Error al actualizar Docentes 2'||sqlerrm;
                                End;
                             end if;

                 End Loop;


                COMMIT;
                Return vl_error;


            END;

 FUNCTION f_alumnos_moodle_out (p_aula in varchar2)
      RETURN PKG_MOODLE2.cursor_alumnos_out
   AS
      alumnos_out   PKG_MOODLE2.cursor_alumnos_out;
   ----- Esta Funcion realiza el envio de los alumnos con materias registradas hacia Moodle
   ----- Se realiza modificacion para version final 02-Jun- 2017   ------
   ----- Preguntar antes de modificar -----
   -----    vmrl   -----


   BEGIN
      BEGIN
         OPEN alumnos_out FOR
            SELECT DISTINCT alumnos.PIDM PIDM, alumnos.MATRICULA, alumnos.LAST_NAME, alumnos.FIRST_NAME ,alumnos.EMAIL ,alumnos.ESTATUS , alumnos.TERM_NRC,
                            alumnos.pwd , alumnos.servidor , alumnos.id_curso , alumnos.id_grupo , alumnos.secuencia ,
                            alumnos.no_regla , alumnos.campus , alumnos.Nivel , alumnos.tipo_curso,
            CASE WHEN tipo_curso = 'H' THEN
                   (SELECT SZTDTEC_MOD_TYPE
                    FROM SZTDTEC
                    WHERE 1=1
                    AND programa = SZTDTEC_PROGRAM
                    AND periodo_catalogo = SZTDTEC_TERM_CODE
                    AND campus = SZTDTEC_CAMP_CODE --cambio colocado 04/12/2020--
                     )
            END AS MODA,
            alumnos.fecha_inicio
            --'BLOQUE1'
            from (
            SELECT SPRIDEN_PIDM PIDM,
                   SPRIDEN_ID MATRICULA,
                   REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                   SPRIDEN_FIRST_NAME FIRST_NAME,
                   a.GOREMAL_EMAIL_ADDRESS EMAIL,
                   SZSTUME_RSTS_CODE ESTATUS,
                   SZSTUME_TERM_NRC TERM_NRC,
                   GOZTPAC_PIN pwd,
                   SZTGPME_PTRM_CODE_COMP servidor,
                   SZTGPME_CRSE_MDLE_ID id_curso,
                   SZTGPME_GPMDLE_ID id_grupo,
                   SZSTUME_SEQ_NO secuencia,
                   SZSTUME_NO_REGLA no_regla,
                   SORLCUR_CAMP_CODE campus,
                   SORLCUR_LEVL_CODE Nivel,
                   SORLCUR_PROGRAM programa,
                   SORLCUR_TERM_CODE_CTLG periodo_catalogo,
                   SZTMAUR_ORIGEN tipo_curso,
                   SGBSTDN_TERM_CODE_EFF periodo,
                   SZSTUME_START_DATE Fecha_inicio
              FROM SPRIDEN,
                   STVRSTS,
                   GOREMAL a,
                   SZSTUME,
                   GOZTPAC,
                   ZSTPARA,
                   SZTGPME,
                   SGBSTDN A,
                   SORLCUR B,
                   SZTMAUR,
                   SZSGNME
             WHERE SPRIDEN_CHANGE_IND IS NULL
                   AND SPRIDEN_PIDM = SZSTUME_PIDM
                   AND SPRIDEN_PIDM = GOZTPAC_PIDM
                   AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                   AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                   AND SZSTUME_STAT_IND = '0'
                   AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                   AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
                   AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                   AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                   AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                   AND SZSTUME_START_DATE = SZTGPME_START_DATE
                   AND SZTGPME_STAT_IND = '1'
                   AND SZTGPME_CRSE_MDLE_ID != 0
                   AND SZSTUME_RSTS_CODE = 'RE'
                   and SZSTUME_CAMP_CODE_COMP is null
                   AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                   AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                 FROM GOREMAL a1
                                                 WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                 AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                   AND SPRIDEN_PIDM = A.SGBSTDN_PIDM
                   AND A.SGBSTDN_STST_CODE  IN ('MA', 'PR', 'AS')
                   AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                  FROM SGBSTDN A1
                                                  WHERE A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                  AND A.SGBSTDN_TERM_CODE_EFF = A1.SGBSTDN_TERM_CODE_EFF
                                                  AND A.SGBSTDN_LEVL_CODE = A1.SGBSTDN_LEVL_CODE
                                                  AND A.SGBSTDN_CAMP_CODE = A1.SGBSTDN_CAMP_CODE
                                                  AND A.SGBSTDN_STST_CODE = A1.SGBSTDN_STST_CODE )
                    AND B.SORLCUR_PIDM = SZSTUME_PIDM
                    And  b.SORLCUR_LMOD_CODE = 'LEARNER'
                    And b.SORLCUR_CACT_CODE = 'ACTIVE'
                    and b.sorlcur_camp_code = SGBSTDN_CAMP_CODE
                    And b.sorlcur_levl_code = SGBSTDN_LEVL_CODE
                    And b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                            from SORLCUR b1
                                                            where b.SORLCUR_PIDM = b1.SORLCUR_PIDM
                                                            And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                            And b.SORLCUR_CACT_CODE = b1.SORLCUR_CACT_CODE
                                                            And b.sorlcur_camp_code = b1.sorlcur_camp_code
                                                            And b.sorlcur_levl_code = b1.sorlcur_levl_code
                                                            and b.SORLCUR_ADMT_CODE = b1.SORLCUR_ADMT_CODE)
                    AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                    AND SZTMAUR_ACTIVO = 'S'
                    AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                    AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                    AND SZSTUME_START_DATE = SZSGNME_START_DATE
                    AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                    AND SZTGPME_NO_REGLA <> 99
                    AND SZTMAUR_ORIGEN <> 'E'
                    --AND SZSGNME_STAT_IND ='1'
                    AND SZTGPME_CAMP_CODE != 'EAF'
                    AND SZTGPME_PTRM_CODE_COMP = p_aula
                    --AND SZTGPME_PTRM_CODE_COMP IN (12,5,1,2,4) -- PARA PRUEBA DE SEGMENTACI”N DE CURSORES--
                    --AND SZSGNME_NO_REGLA IN (164, 149)
                     --AND SZTGPME_CAMP_CODE <>'UVE'
                     AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                    )alumnos
                    WHERE 1=1
                    AND alumnos.periodo = (SELECT MAX (d.SGBSTDN_TERM_CODE_EFF)
                                           FROM SGBSTDN d
                                           WHERE 1=1
                                           AND d.SGBSTDN_PIDM = alumnos.PIDM
                                           AND d.SGBSTDN_LEVL_CODE = alumnos.nivel)
                   --AND alumnos.no_regla = 207
                   --AND ROWNUM <= 1000
                   --AND alumnos.PIDM = 296092
                   UNION
                    SELECT DISTINCT alumnos.PIDM PIDM, alumnos.MATRICULA, alumnos.LAST_NAME, alumnos.FIRST_NAME ,alumnos.EMAIL ,alumnos.ESTATUS , alumnos.TERM_NRC,
                            alumnos.pwd , alumnos.servidor , alumnos.id_curso , alumnos.id_grupo , alumnos.secuencia ,
                            alumnos.no_regla , alumnos.campus , alumnos.Nivel , alumnos.tipo_curso,
            CASE WHEN tipo_curso = 'H' THEN
                   (SELECT SZTDTEC_MOD_TYPE
                    FROM SZTDTEC
                    WHERE 1=1
                    AND programa = SZTDTEC_PROGRAM
                    AND periodo_catalogo = SZTDTEC_TERM_CODE
                    AND campus = SZTDTEC_CAMP_CODE --cambio colocado 04/12/2020--
                     )
            END AS MODA,
            alumnos.fecha_inicio
            --'BLOQUE1'
            from (
            SELECT SPRIDEN_PIDM PIDM,
                   SPRIDEN_ID MATRICULA,
                   REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                   SPRIDEN_FIRST_NAME FIRST_NAME,
                   a.GOREMAL_EMAIL_ADDRESS EMAIL,
                   SZSTUME_RSTS_CODE ESTATUS,
                   SZSTUME_TERM_NRC TERM_NRC,
                   GOZTPAC_PIN pwd,
                   SZTGPME_PTRM_CODE_COMP servidor,
                   SZTGPME_CRSE_MDLE_ID id_curso,
                   SZTGPME_GPMDLE_ID id_grupo,
                   SZSTUME_SEQ_NO secuencia,
                   SZSTUME_NO_REGLA no_regla,
                   SORLCUR_CAMP_CODE campus,
                   SORLCUR_LEVL_CODE Nivel,
                   SORLCUR_PROGRAM programa,
                   SORLCUR_TERM_CODE_CTLG periodo_catalogo,
                   SZTMAUR_ORIGEN tipo_curso,
                   SGBSTDN_TERM_CODE_EFF periodo,
                   SZSTUME_START_DATE Fecha_inicio
              FROM SPRIDEN,
                   STVRSTS,
                   GOREMAL a,
                   SZSTUME,
                   GOZTPAC,
                   ZSTPARA,
                   SZTGPME,
                   SGBSTDN A,
                   SORLCUR B,
                   SZTMAUR,
                   SZSGNME
             WHERE SPRIDEN_CHANGE_IND IS NULL
                   AND SPRIDEN_PIDM = SZSTUME_PIDM
                   AND SPRIDEN_PIDM = GOZTPAC_PIDM
                   AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                   AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                   AND SZSTUME_STAT_IND = '0'
                   AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                   AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
                   AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                   AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                   AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                   AND SZSTUME_START_DATE = SZTGPME_START_DATE
                   AND SZTGPME_STAT_IND = '1'
                   AND SZTGPME_CRSE_MDLE_ID != 0
                   AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                   AND SZSTUME_RSTS_CODE = 'RE'
                   and SZSTUME_CAMP_CODE_COMP is null
                   AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                   AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                 FROM GOREMAL a1
                                                 WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                 AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                   AND SPRIDEN_PIDM = A.SGBSTDN_PIDM
                   AND A.SGBSTDN_STST_CODE  IN ('MA', 'PR', 'AS')
                   AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                  FROM SGBSTDN A1
                                                  WHERE A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                  AND A.SGBSTDN_TERM_CODE_EFF = A1.SGBSTDN_TERM_CODE_EFF
                                                  AND A.SGBSTDN_LEVL_CODE = A1.SGBSTDN_LEVL_CODE
                                                  AND A.SGBSTDN_CAMP_CODE = A1.SGBSTDN_CAMP_CODE
                                                  AND A.SGBSTDN_STST_CODE = A1.SGBSTDN_STST_CODE )
                    AND B.SORLCUR_PIDM = SZSTUME_PIDM
                    And  b.SORLCUR_LMOD_CODE = 'LEARNER'
                    And b.SORLCUR_CACT_CODE = 'ACTIVE'
                    and b.sorlcur_camp_code = SGBSTDN_CAMP_CODE
                    And b.sorlcur_levl_code = SGBSTDN_LEVL_CODE
                    And b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                            from SORLCUR b1
                                                            where b.SORLCUR_PIDM = b1.SORLCUR_PIDM
                                                            And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                            And b.SORLCUR_CACT_CODE = b1.SORLCUR_CACT_CODE
                                                            And b.sorlcur_camp_code = b1.sorlcur_camp_code
                                                            And b.sorlcur_levl_code = b1.sorlcur_levl_code
                                                            and b.SORLCUR_ADMT_CODE = b1.SORLCUR_ADMT_CODE)
                    AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                    AND SZTMAUR_ACTIVO = 'S'
                    AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                    AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                    AND SZSTUME_START_DATE = SZSGNME_START_DATE
                    AND SZTGPME_NO_REGLA != 99
                    AND SZTMAUR_ORIGEN != 'E'
                    --AND SZSGNME_STAT_IND ='1'
                    AND SZTGPME_CAMP_CODE != 'EAF'
                    AND SZTMAUR_ORIGEN = 'I'
                    AND SZTGPME_PTRM_CODE_COMP = p_aula
                    AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                    --AND SZTGPME_PTRM_CODE_COMP IN (12,5,1,2,4) -- PARA PRUEBA DE SEGMENTACI”N DE CURSORES--
                    --AND SZSGNME_NO_REGLA IN (164, 149)
                     --AND SZTGPME_CAMP_CODE <>'UVE'
                    )alumnos
                    WHERE 1=1
                    AND alumnos.periodo = (SELECT MAX (d.SGBSTDN_TERM_CODE_EFF)
                                           FROM SGBSTDN d
                                           WHERE 1=1
                                           AND d.SGBSTDN_PIDM = alumnos.PIDM
                                          AND d.SGBSTDN_LEVL_CODE = alumnos.nivel)
                   UNION
                      SELECT DISTINCT
                           SPRIDEN_PIDM PIDM,
                           SPRIDEN_ID MATRICULA,
                           REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                           SPRIDEN_FIRST_NAME FIRST_NAME,
                           a.GOREMAL_EMAIL_ADDRESS EMAIL,
                           SZSTUME_RSTS_CODE ESTATUS,
                           SZSTUME_TERM_NRC TERM_NRC,
                           GOZTPAC_PIN pwd,
                           SZTGPME_PTRM_CODE_COMP servidor,
                           SZTGPME_CRSE_MDLE_ID id_curso,
                           SZTGPME_GPMDLE_ID id_grupo,
                           SZSTUME_SEQ_NO secuencia,
                           SZSTUME_NO_REGLA no_regla,
                           SZTGPME_CAMP_CODE campus,
                           SORLCUR_LEVL_CODE Nivel,
                           SZTMAUR_ORIGEN tipo_curso,
                           Null MODA,
                           SZSTUME_START_DATE Fecha_inicio
                           --'BLOQUE2'
                      FROM SPRIDEN,
                           STVRSTS,
                           GOREMAL a,
                           SZSTUME,
                           GOZTPAC,
                           ZSTPARA,
                           SZTGPME,
                           SGBSTDN A,
                           SORLCUR B,
                           SZTMAUR,
                           SZSGNME
                     WHERE SPRIDEN_CHANGE_IND IS NULL
                           AND SPRIDEN_PIDM = SZSTUME_PIDM
                           AND SPRIDEN_PIDM = GOZTPAC_PIDM
                           AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                           AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                           AND SZSTUME_STAT_IND = '0'
                           AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                           AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
                           AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                           AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                           AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                           AND SZTGPME_START_DATE = SZSTUME_START_DATE
                           AND SZTGPME_STAT_IND = '1'
                           AND SZTGPME_CRSE_MDLE_ID != 0
                           AND SZSTUME_RSTS_CODE = 'RE'
                           and SZSTUME_CAMP_CODE_COMP is null
                           AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                           AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                         FROM GOREMAL a1
                                                         WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                         AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                           AND SPRIDEN_PIDM = A.SGBSTDN_PIDM
                           --AND A.SGBSTDN_STST_CODE  NOT IN ('MA', 'PR', 'AS')
                           AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                          FROM SGBSTDN A1
                                                          WHERE A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                          AND A.SGBSTDN_TERM_CODE_EFF = A1.SGBSTDN_TERM_CODE_EFF
                                                          AND A.SGBSTDN_LEVL_CODE = A1.SGBSTDN_LEVL_CODE
                                                          AND A.SGBSTDN_CAMP_CODE = A1.SGBSTDN_CAMP_CODE
                                                          AND A.SGBSTDN_STST_CODE = A1.SGBSTDN_STST_CODE )
                            AND B.SORLCUR_PIDM = SZSTUME_PIDM
                            And  b.SORLCUR_LMOD_CODE = 'LEARNER'
                            --And b.SORLCUR_CACT_CODE = 'ACTIVE'
                            and b.sorlcur_camp_code = SGBSTDN_CAMP_CODE
                            And b.sorlcur_levl_code = SGBSTDN_LEVL_CODE
                            And b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                                    from SORLCUR b1
                                                                    where b.SORLCUR_PIDM = b1.SORLCUR_PIDM
                                                                    And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                                    And b.SORLCUR_CACT_CODE = b1.SORLCUR_CACT_CODE
                                                                    And b.sorlcur_camp_code = b1.sorlcur_camp_code
                                                                    And b.sorlcur_levl_code = b1.sorlcur_levl_code
                                                                    and b.SORLCUR_ADMT_CODE = b1.SORLCUR_ADMT_CODE)
                            AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                            AND SZTMAUR_ACTIVO = 'S'
                            AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                            AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                            AND SZSGNME_START_DATE = SZSTUME_START_DATE
                            AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                            AND SZTGPME_NO_REGLA = 99
                            AND SZTMAUR_ORIGEN = 'E'
                            AND SZSGNME_STAT_IND ='1'
                            AND SZTGPME_CAMP_CODE != 'EAF'
                            AND SZTGPME_LEVL_CODE = b.sorlcur_levl_code
                            AND substr(SZTGPME_TERM_NRC_COMP,5,1)='7'
                            AND SZTGPME_PTRM_CODE_COMP = p_aula
                   UNION
                         SELECT distinct
                               SPRIDEN_PIDM PIDM,
                               SPRIDEN_ID MATRICULA,
                               REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                               SPRIDEN_FIRST_NAME FIRST_NAME,
                               a.GOREMAL_EMAIL_ADDRESS EMAIL,
                               SZSTUME_RSTS_CODE ESTATUS,
                               SZSTUME_TERM_NRC TERM_NRC,
                               GOZTPAC_PIN pwd,
                               SZTGPME_PTRM_CODE_COMP servidor,
                               SZTGPME_CRSE_MDLE_ID id_curso,
                               SZTGPME_GPMDLE_ID id_grupo,
                               SZSTUME_SEQ_NO secuencia,
                               SZSTUME_NO_REGLA no_regla,
                               SZTGPME_CAMP_CODE campus,
                               SORLCUR_LEVL_CODE Nivel,
                               SZTMAUR_ORIGEN tipo_curso,
                               Null MODA,
                               SZSTUME_START_DATE Fecha_inicio
                               --'BLOQUE2'
                          FROM SPRIDEN,
                               STVRSTS,
                               GOREMAL a,
                               SZSTUME,
                               GOZTPAC,
                               ZSTPARA,
                               SZTGPME,
                               SGBSTDN A,
                               SORLCUR B,
                               SZTMAUR,
                               SZSGNME
                         WHERE SPRIDEN_CHANGE_IND IS NULL
                               AND SPRIDEN_PIDM = SZSTUME_PIDM
                               AND SPRIDEN_PIDM = GOZTPAC_PIDM
                               AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                               AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                               AND SZSTUME_STAT_IND = '0'
                               AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                               AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
                               AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                               AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                               AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                               AND SZTGPME_START_DATE = SZSTUME_START_DATE
                               AND SZTGPME_STAT_IND = '1'
                               AND SZTGPME_CRSE_MDLE_ID != 0
                               AND SZSTUME_RSTS_CODE = 'RE'
                               and SZSTUME_CAMP_CODE_COMP is null
                               AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                               AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                             FROM GOREMAL a1
                                                             WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                             AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                               AND SPRIDEN_PIDM = A.SGBSTDN_PIDM
                            --   AND A.SGBSTDN_STST_CODE  NOT IN ('MA', 'PR', 'AS')
                               AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                              FROM SGBSTDN A1
                                                              WHERE A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                              AND A.SGBSTDN_TERM_CODE_EFF = A1.SGBSTDN_TERM_CODE_EFF
                                                              AND A.SGBSTDN_LEVL_CODE = A1.SGBSTDN_LEVL_CODE
                                                              AND A.SGBSTDN_CAMP_CODE = A1.SGBSTDN_CAMP_CODE
                                                              AND A.SGBSTDN_STST_CODE = A1.SGBSTDN_STST_CODE )
                                AND B.SORLCUR_PIDM = SZSTUME_PIDM
                                And  b.SORLCUR_LMOD_CODE = 'LEARNER'
                              -- And b.SORLCUR_CACT_CODE = 'ACTIVE'
                                and b.sorlcur_camp_code = SGBSTDN_CAMP_CODE
                                And b.sorlcur_levl_code = SGBSTDN_LEVL_CODE
                                And b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                                        from SORLCUR b1
                                                                        where b.SORLCUR_PIDM = b1.SORLCUR_PIDM
                                                                        And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                                        And b.SORLCUR_CACT_CODE = b1.SORLCUR_CACT_CODE
                                                                        And b.sorlcur_camp_code = b1.sorlcur_camp_code
                                                                   --    And b.sorlcur_levl_code = b1.sorlcur_levl_code --Apague condiciÛn para los caso con dos o m·s niveles
                                                                        and b.SORLCUR_ADMT_CODE = b1.SORLCUR_ADMT_CODE)
                               and szstume_seq_no in (select max(s1.szstume_seq_no)
                                                        from szstume s1
                                                        where 
                                                            s1.szstume_pidm = spriden_pidm
                                                        AND s1.SZSTUME_RSTS_CODE = 'RE'
                                                        and s1.SZSTUME_CAMP_CODE_COMP is null
                                                        and s1.SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                                                        and RTRIM (s1.SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC))                                        
                                AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                                AND SZTMAUR_ACTIVO = 'S'
                                AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                                AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                                AND SZSGNME_START_DATE = SZSTUME_START_DATE
                                AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                                AND SZTGPME_NO_REGLA = 99
                                AND SZTMAUR_ORIGEN = 'E'
                                AND SZSGNME_STAT_IND ='1'
                                AND SZTGPME_CAMP_CODE != 'EAF'
                                AND substr(SZTGPME_TERM_NRC_COMP,5,1)='8'
                             --   AND SZTGPME_LEVL_CODE = b.sorlcur_levl_code
                                AND SZTGPME_PTRM_CODE_COMP = p_aula   
                   UNION
                       SELECT
                           SPRIDEN_PIDM PIDM,
                           SPRIDEN_ID MATRICULA,
                           REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                           SPRIDEN_FIRST_NAME FIRST_NAME,
                           a.GOREMAL_EMAIL_ADDRESS EMAIL,
                           SZSTUME_RSTS_CODE ESTATUS,
                           SZSTUME_TERM_NRC TERM_NRC,
                           GOZTPAC_PIN pwd,
                           SZTGPME_PTRM_CODE_COMP servidor,
                           SZTGPME_CRSE_MDLE_ID id_curso,
                           SZTGPME_GPMDLE_ID id_grupo,
                           SZSTUME_SEQ_NO secuencia,
                           SZSTUME_NO_REGLA no_regla,
                           SZTGPME_CAMP_CODE campus,
                           SZTGPME_LEVL_CODE Nivel,
                           SZTMAUR_ORIGEN tipo_curso,
                           Null MODA,
                           SZSTUME_START_DATE Fecha_inicio
                           --'BLOQUE2'
                      FROM SPRIDEN,
                           STVRSTS,
                           GOREMAL a,
                           SZSTUME,
                           GOZTPAC,
                           ZSTPARA,
                           SZTGPME,
                           SZTMAUR,
                           SZSGNME,
                           SIRCMNT,
                           SIBINST ,
                           SZTMACF
                     WHERE SPRIDEN_CHANGE_IND IS NULL
                           AND SPRIDEN_PIDM = SZSTUME_PIDM
                           AND SPRIDEN_PIDM = GOZTPAC_PIDM
                           AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                           AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                           AND SPRIDEN_pidm=SIRCMNT_PIDM 
                           AND SIBINST_pidm = SPRIDEN_pidm and SIBINST_FCST_CODE not in ('BA', 'IN')
                           AND SZSTUME_STAT_IND = '0'
                           AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                           AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                           AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                           AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                           AND SZTGPME_START_DATE = SZSTUME_START_DATE
                           AND SZTGPME_STAT_IND = '1'
                           AND SZTGPME_CRSE_MDLE_ID != 0
                           AND SZSTUME_RSTS_CODE = 'RE'
                           and SZSTUME_CAMP_CODE_COMP is null
                           AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                           AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                         FROM GOREMAL a1
                                                         WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                         AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                            AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                            AND SZTMAUR_ACTIVO = 'S'
                            AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                            AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                            AND SZSGNME_START_DATE = SZSTUME_START_DATE
                            AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                            AND SZTGPME_NO_REGLA = 1
                            AND SZTGPME_SUBJ_CRSE=SZTMACF_SUBJ
                            AND SZTMAUR_ORIGEN = 'N'
                            AND SIRCMNT_TEXT=SZTMACF_CAMP
                            AND SZTGPME_CAMP_CODE =SZTMACF_CAMP
                            AND SZSGNME_STAT_IND ='1'
                            AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                            AND SZTGPME_PTRM_CODE_COMP = p_aula
                            ;
--                    AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA;
                    --AND SZTGPME_PTRM_CODE_COMP IN (12,5,1,2,4) -- PARA PRUEBA DE SEGMENTACI”N DE CURSORES--


      RETURN (alumnos_out);
    END;
   END f_alumnos_moodle_out;



  FUNCTION f_alumnos_moodle_out1 (p_aula in varchar2)
  RETURN PKG_MOODLE2.cursor_alumnos_out1
   AS
      alumnos_out1   PKG_MOODLE2.cursor_alumnos_out1;
   ----- Esta Funcion realiza el envio de los alumnos con materias registradas hacia Moodle
   ----- Se realiza modificacion para version final 02-Jun- 2017   ------
   ----- Preguntar antes de modificar -----
   -----    vmrl   -----


   BEGIN
      BEGIN
         OPEN alumnos_out1 FOR
            SELECT DISTINCT alumnos.PIDM PIDM, alumnos.MATRICULA, alumnos.LAST_NAME, alumnos.FIRST_NAME ,alumnos.EMAIL ,alumnos.ESTATUS , alumnos.TERM_NRC,
                            alumnos.pwd , alumnos.servidor , alumnos.id_curso , alumnos.id_grupo , alumnos.secuencia ,
                            alumnos.no_regla , alumnos.campus , alumnos.Nivel , alumnos.tipo_curso,
            CASE WHEN tipo_curso = 'H' THEN
                   (SELECT SZTDTEC_MOD_TYPE
                    FROM SZTDTEC
                    WHERE 1=1
                    AND programa = SZTDTEC_PROGRAM
                    AND periodo_catalogo = SZTDTEC_TERM_CODE
                    AND campus = SZTDTEC_CAMP_CODE --cambio colocado 04/12/2020--
                     )
            END AS MODA,
            alumnos.fecha_inicio
            --'BLOQUE1'
            from (
            SELECT SPRIDEN_PIDM PIDM,
                   SPRIDEN_ID MATRICULA,
                   REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                   SPRIDEN_FIRST_NAME FIRST_NAME,
                   a.GOREMAL_EMAIL_ADDRESS EMAIL,
                   SZSTUME_RSTS_CODE ESTATUS,
                   SZSTUME_TERM_NRC TERM_NRC,
                   GOZTPAC_PIN pwd,
                   SZTGPME_PTRM_CODE_COMP servidor,
                   SZTGPME_CRSE_MDLE_ID id_curso,
                   SZTGPME_GPMDLE_ID id_grupo,
                   SZSTUME_SEQ_NO secuencia,
                   SZSTUME_NO_REGLA no_regla,
                   SORLCUR_CAMP_CODE campus,
                   SORLCUR_LEVL_CODE Nivel,
                   SORLCUR_PROGRAM programa,
                   SORLCUR_TERM_CODE_CTLG periodo_catalogo,
                   SZTMAUR_ORIGEN tipo_curso,
                   SGBSTDN_TERM_CODE_EFF periodo,
                   SZSTUME_START_DATE Fecha_inicio
              FROM SPRIDEN,
                   STVRSTS,
                   GOREMAL a,
                   SZSTUME,
                   GOZTPAC,
                   ZSTPARA,
                   SZTGPME,
                   SGBSTDN A,
                   SORLCUR B,
                   SZTMAUR,
                   SZSGNME
             WHERE SPRIDEN_CHANGE_IND IS NULL
                   AND SPRIDEN_PIDM = SZSTUME_PIDM
                   AND SPRIDEN_PIDM = GOZTPAC_PIDM
                   AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                   AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                   AND SZSTUME_STAT_IND = '0'
                   AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                   AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
                   AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                   AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                   AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                   AND SZSTUME_START_DATE = SZTGPME_START_DATE
                   AND SZTGPME_STAT_IND = '1'
                   AND SZTGPME_CRSE_MDLE_ID != 0
                   AND SZSTUME_RSTS_CODE = 'RE'
                   and SZSTUME_CAMP_CODE_COMP is null
                   AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                   AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                 FROM GOREMAL a1
                                                 WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                 AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                   AND SPRIDEN_PIDM = A.SGBSTDN_PIDM
                   AND A.SGBSTDN_STST_CODE  IN ('MA', 'PR', 'AS')
                   AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                  FROM SGBSTDN A1
                                                  WHERE A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                  AND A.SGBSTDN_TERM_CODE_EFF = A1.SGBSTDN_TERM_CODE_EFF
                                                  AND A.SGBSTDN_LEVL_CODE = A1.SGBSTDN_LEVL_CODE
                                                  AND A.SGBSTDN_CAMP_CODE = A1.SGBSTDN_CAMP_CODE
                                                  AND A.SGBSTDN_STST_CODE = A1.SGBSTDN_STST_CODE )
                    AND B.SORLCUR_PIDM = SZSTUME_PIDM
                    And  b.SORLCUR_LMOD_CODE = 'LEARNER'
                    And b.SORLCUR_CACT_CODE = 'ACTIVE'
                    and b.sorlcur_camp_code = SGBSTDN_CAMP_CODE
                    And b.sorlcur_levl_code = SGBSTDN_LEVL_CODE
                    And b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                            from SORLCUR b1
                                                            where b.SORLCUR_PIDM = b1.SORLCUR_PIDM
                                                            And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                            And b.SORLCUR_CACT_CODE = b1.SORLCUR_CACT_CODE
                                                            And b.sorlcur_camp_code = b1.sorlcur_camp_code
                                                            And b.sorlcur_levl_code = b1.sorlcur_levl_code
                                                            and b.SORLCUR_ADMT_CODE = b1.SORLCUR_ADMT_CODE)
                    AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                    AND SZTMAUR_ACTIVO = 'S'
                    AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                    AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                    AND SZSTUME_START_DATE = SZSGNME_START_DATE
                    AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                    AND SZTGPME_NO_REGLA <> 99
                    AND SZTMAUR_ORIGEN <> 'E'
                    --AND SZSGNME_STAT_IND ='1'
                    AND SZTGPME_CAMP_CODE != 'EAF'
                    AND SZTGPME_PTRM_CODE_COMP = p_aula
                    AND SZTGPME_PTRM_CODE_COMP IN (3,6,9,7,8,10,14,18,11,15,13,17,16,22)
                    --AND SZSGNME_NO_REGLA IN (164, 149)
                     --AND SZTGPME_CAMP_CODE <>'UVE'
                    )alumnos
                    WHERE 1=1
                    AND alumnos.periodo = (SELECT MAX (d.SGBSTDN_TERM_CODE_EFF)
                                           FROM SGBSTDN d
                                           WHERE 1=1
                                           AND d.SGBSTDN_PIDM = alumnos.PIDM
                                           AND d.SGBSTDN_LEVL_CODE = alumnos.nivel)
                   --AND alumnos.no_regla = 207
                   --AND ROWNUM <= 1000
                   --AND alumnos.PIDM = 296092
                   UNION
                    SELECT DISTINCT alumnos.PIDM PIDM, alumnos.MATRICULA, alumnos.LAST_NAME, alumnos.FIRST_NAME ,alumnos.EMAIL ,alumnos.ESTATUS , alumnos.TERM_NRC,
                            alumnos.pwd , alumnos.servidor , alumnos.id_curso , alumnos.id_grupo , alumnos.secuencia ,
                            alumnos.no_regla , alumnos.campus , alumnos.Nivel , alumnos.tipo_curso,
            CASE WHEN tipo_curso = 'H' THEN
                   (SELECT SZTDTEC_MOD_TYPE
                    FROM SZTDTEC
                    WHERE 1=1
                    AND programa = SZTDTEC_PROGRAM
                    AND periodo_catalogo = SZTDTEC_TERM_CODE
                    AND campus = SZTDTEC_CAMP_CODE --cambio colocado 04/12/2020--
                     )
            END AS MODA,
            alumnos.fecha_inicio
            --'BLOQUE1'
            from (
            SELECT SPRIDEN_PIDM PIDM,
                   SPRIDEN_ID MATRICULA,
                   REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                   SPRIDEN_FIRST_NAME FIRST_NAME,
                   a.GOREMAL_EMAIL_ADDRESS EMAIL,
                   SZSTUME_RSTS_CODE ESTATUS,
                   SZSTUME_TERM_NRC TERM_NRC,
                   GOZTPAC_PIN pwd,
                   SZTGPME_PTRM_CODE_COMP servidor,
                   SZTGPME_CRSE_MDLE_ID id_curso,
                   SZTGPME_GPMDLE_ID id_grupo,
                   SZSTUME_SEQ_NO secuencia,
                   SZSTUME_NO_REGLA no_regla,
                   SORLCUR_CAMP_CODE campus,
                   SORLCUR_LEVL_CODE Nivel,
                   SORLCUR_PROGRAM programa,
                   SORLCUR_TERM_CODE_CTLG periodo_catalogo,
                   SZTMAUR_ORIGEN tipo_curso,
                   SGBSTDN_TERM_CODE_EFF periodo,
                   SZSTUME_START_DATE Fecha_inicio
              FROM SPRIDEN,
                   STVRSTS,
                   GOREMAL a,
                   SZSTUME,
                   GOZTPAC,
                   ZSTPARA,
                   SZTGPME,
                   SGBSTDN A,
                   SORLCUR B,
                   SZTMAUR,
                   SZSGNME
             WHERE SPRIDEN_CHANGE_IND IS NULL
                   AND SPRIDEN_PIDM = SZSTUME_PIDM
                   AND SPRIDEN_PIDM = GOZTPAC_PIDM
                   AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                   AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                   AND SZSTUME_STAT_IND = '0'
                   AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                   AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
                   AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                   AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                   AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                   AND SZSTUME_START_DATE = SZTGPME_START_DATE
                   AND SZTGPME_STAT_IND = '1'
                   AND SZTGPME_CRSE_MDLE_ID != 0
                   AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                   AND SZSTUME_RSTS_CODE = 'RE'
                   and SZSTUME_CAMP_CODE_COMP is null
                   AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                   AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                 FROM GOREMAL a1
                                                 WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                 AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                   AND SPRIDEN_PIDM = A.SGBSTDN_PIDM
                   AND A.SGBSTDN_STST_CODE  IN ('MA', 'PR', 'AS')
                   AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                  FROM SGBSTDN A1
                                                  WHERE A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                  AND A.SGBSTDN_TERM_CODE_EFF = A1.SGBSTDN_TERM_CODE_EFF
                                                  AND A.SGBSTDN_LEVL_CODE = A1.SGBSTDN_LEVL_CODE
                                                  AND A.SGBSTDN_CAMP_CODE = A1.SGBSTDN_CAMP_CODE
                                                  AND A.SGBSTDN_STST_CODE = A1.SGBSTDN_STST_CODE )
                    AND B.SORLCUR_PIDM = SZSTUME_PIDM
                    And  b.SORLCUR_LMOD_CODE = 'LEARNER'
                    And b.SORLCUR_CACT_CODE = 'ACTIVE'
                    and b.sorlcur_camp_code = SGBSTDN_CAMP_CODE
                    And b.sorlcur_levl_code = SGBSTDN_LEVL_CODE
                    And b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                            from SORLCUR b1
                                                            where b.SORLCUR_PIDM = b1.SORLCUR_PIDM
                                                            And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                            And b.SORLCUR_CACT_CODE = b1.SORLCUR_CACT_CODE
                                                            And b.sorlcur_camp_code = b1.sorlcur_camp_code
                                                            And b.sorlcur_levl_code = b1.sorlcur_levl_code
                                                            and b.SORLCUR_ADMT_CODE = b1.SORLCUR_ADMT_CODE)
                    AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                    AND SZTMAUR_ACTIVO = 'S'
                    AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                    AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                    AND SZSTUME_START_DATE = SZSGNME_START_DATE
                    AND SZTGPME_NO_REGLA != 99
                    AND SZTMAUR_ORIGEN != 'E'
                    --AND SZSGNME_STAT_IND ='1'
                    AND SZTGPME_CAMP_CODE != 'EAF'
                    AND SZTMAUR_ORIGEN = 'I'
                    AND SZTGPME_PTRM_CODE_COMP = p_aula
                    AND SZTGPME_PTRM_CODE_COMP IN (3,6,9,7,8,10,14,18,11,15,13,17,16,22)
                    --AND SZSGNME_NO_REGLA IN (164, 149)
                     --AND SZTGPME_CAMP_CODE <>'UVE'
                    )alumnos
                    WHERE 1=1
                    AND alumnos.periodo = (SELECT MAX (d.SGBSTDN_TERM_CODE_EFF)
                                           FROM SGBSTDN d
                                           WHERE 1=1
                                           AND d.SGBSTDN_PIDM = alumnos.PIDM
                                          AND d.SGBSTDN_LEVL_CODE = alumnos.nivel)
                   UNION
                   SELECT
                   SPRIDEN_PIDM PIDM,
                   SPRIDEN_ID MATRICULA,
                   REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                   SPRIDEN_FIRST_NAME FIRST_NAME,
                   a.GOREMAL_EMAIL_ADDRESS EMAIL,
                   SZSTUME_RSTS_CODE ESTATUS,
                   SZSTUME_TERM_NRC TERM_NRC,
                   GOZTPAC_PIN pwd,
                   SZTGPME_PTRM_CODE_COMP servidor,
                   SZTGPME_CRSE_MDLE_ID id_curso,
                   SZTGPME_GPMDLE_ID id_grupo,
                   SZSTUME_SEQ_NO secuencia,
                   SZSTUME_NO_REGLA no_regla,
                   SZTGPME_CAMP_CODE campus,
                   SORLCUR_LEVL_CODE Nivel,
                   SZTMAUR_ORIGEN tipo_curso,
                   Null MODA,
                   SZSTUME_START_DATE Fecha_inicio
                   --'BLOQUE2'
              FROM SPRIDEN,
                   STVRSTS,
                   GOREMAL a,
                   SZSTUME,
                   GOZTPAC,
                   ZSTPARA,
                   SZTGPME,
                   SGBSTDN A,
                   SORLCUR B,
                   SZTMAUR,
                   SZSGNME
             WHERE SPRIDEN_CHANGE_IND IS NULL
                   AND SPRIDEN_PIDM = SZSTUME_PIDM
                   AND SPRIDEN_PIDM = GOZTPAC_PIDM
                   AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                   AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                   AND SZSTUME_STAT_IND = '0'
                   AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                   AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
                   AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                   AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                   AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                   AND SZTGPME_START_DATE = SZSTUME_START_DATE
                   AND SZTGPME_STAT_IND = '1'
                   AND SZTGPME_CRSE_MDLE_ID != 0
                   AND SZSTUME_RSTS_CODE = 'RE'
                   and SZSTUME_CAMP_CODE_COMP is null
                   AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                   AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                 FROM GOREMAL a1
                                                 WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                 AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                   AND SPRIDEN_PIDM = A.SGBSTDN_PIDM
                   --AND A.SGBSTDN_STST_CODE  NOT IN ('MA', 'PR', 'AS')
                   AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                  FROM SGBSTDN A1
                                                  WHERE A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                  AND A.SGBSTDN_TERM_CODE_EFF = A1.SGBSTDN_TERM_CODE_EFF
                                                  AND A.SGBSTDN_LEVL_CODE = A1.SGBSTDN_LEVL_CODE
                                                  AND A.SGBSTDN_CAMP_CODE = A1.SGBSTDN_CAMP_CODE
                                                  AND A.SGBSTDN_STST_CODE = A1.SGBSTDN_STST_CODE )
                    AND B.SORLCUR_PIDM = SZSTUME_PIDM
                    And  b.SORLCUR_LMOD_CODE = 'LEARNER'
                    --And b.SORLCUR_CACT_CODE = 'ACTIVE'
                    and b.sorlcur_camp_code = SGBSTDN_CAMP_CODE
                    And b.sorlcur_levl_code = SGBSTDN_LEVL_CODE
                    And b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                            from SORLCUR b1
                                                            where b.SORLCUR_PIDM = b1.SORLCUR_PIDM
                                                            And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                            And b.SORLCUR_CACT_CODE = b1.SORLCUR_CACT_CODE
                                                            And b.sorlcur_camp_code = b1.sorlcur_camp_code
                                                            And b.sorlcur_levl_code = b1.sorlcur_levl_code
                                                            and b.SORLCUR_ADMT_CODE = b1.SORLCUR_ADMT_CODE)
                    AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                    AND SZTMAUR_ACTIVO = 'S'
                    AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                    AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                    AND SZSGNME_START_DATE = SZSTUME_START_DATE
                    AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                    AND SZTGPME_NO_REGLA = 99
                    AND SZTMAUR_ORIGEN = 'E'
                    AND SZSGNME_STAT_IND ='1'
                    AND SZTGPME_CAMP_CODE != 'EAF'
                    AND SZTGPME_PTRM_CODE_COMP = p_aula
                    AND SZTGPME_PTRM_CODE_COMP IN (3,6,9,7,8,10,14,18,11,15,13,17,16,22)
                   UNION
                   SELECT
                   SPRIDEN_PIDM PIDM,
                   SPRIDEN_ID MATRICULA,
                   REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                   SPRIDEN_FIRST_NAME FIRST_NAME,
                   a.GOREMAL_EMAIL_ADDRESS EMAIL,
                   SZSTUME_RSTS_CODE ESTATUS,
                   SZSTUME_TERM_NRC TERM_NRC,
                   GOZTPAC_PIN pwd,
                   SZTGPME_PTRM_CODE_COMP servidor,
                   SZTGPME_CRSE_MDLE_ID id_curso,
                   SZTGPME_GPMDLE_ID id_grupo,
                   SZSTUME_SEQ_NO secuencia,
                   SZSTUME_NO_REGLA no_regla,
                   SZTGPME_CAMP_CODE campus,
                   SZTGPME_LEVL_CODE Nivel,
                   SZTMAUR_ORIGEN tipo_curso,
                   Null MODA,
                   SZSTUME_START_DATE Fecha_inicio
                   --'BLOQUE2'
              FROM SPRIDEN,
                   STVRSTS,
                   GOREMAL a,
                   SZSTUME,
                   GOZTPAC,
                   ZSTPARA,
                   SZTGPME,
                   SZTMAUR,
                   SZSGNME,
                   SIRCMNT,
                   SIBINST ,
                   SZTMACF
             WHERE SPRIDEN_CHANGE_IND IS NULL
                   AND SPRIDEN_PIDM = SZSTUME_PIDM
                   AND SPRIDEN_PIDM = GOZTPAC_PIDM
                   AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                   AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                   AND SPRIDEN_pidm=SIRCMNT_PIDM 
                   AND SIBINST_pidm = SPRIDEN_pidm and SIBINST_FCST_CODE not in ('BA', 'IN')
                   AND SZSTUME_STAT_IND = '0'
                   AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                   AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                   AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                   AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                   AND SZTGPME_START_DATE = SZSTUME_START_DATE
                   AND SZTGPME_STAT_IND = '1'
                   AND SZTGPME_CRSE_MDLE_ID != 0
                   AND SZSTUME_RSTS_CODE = 'RE'
                   and SZSTUME_CAMP_CODE_COMP is null
                   AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                   AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                 FROM GOREMAL a1
                                                 WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                 AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                    AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                    AND SZTMAUR_ACTIVO = 'S'
                    AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                    AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                    AND SZSGNME_START_DATE = SZSTUME_START_DATE
                    AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                    AND SZTGPME_NO_REGLA = 1
                    AND SZTGPME_SUBJ_CRSE=SZTMACF_SUBJ
                    AND SZTMAUR_ORIGEN = 'N'
                    AND SIRCMNT_TEXT=SZTMACF_CAMP
                    AND SZTGPME_CAMP_CODE =SZTMACF_CAMP
                    AND SZSGNME_STAT_IND ='1'
                    AND decode (SZTMAUR_ORIGEN,'N','E',SZTMAUR_ORIGEN) =SZSGNME_IDIOMA
                    AND SZTGPME_PTRM_CODE_COMP = p_aula;


      RETURN (alumnos_out1);
    END;
   END f_alumnos_moodle_out1;


       FUNCTION f_baja_alumnos_moodle_out
      RETURN PKG_MOODLE2.cursor_baja_alumnos_out
   AS
      baja_alumnos_out   PKG_MOODLE2.cursor_baja_alumnos_out;
   ---- Esta Funcion realiza el envio de los alumnos a dar de  baja y con materias registradas hacia Moodle ---
   BEGIN

      BEGIN
      OPEN baja_alumnos_out FOR
      SELECT SPRIDEN_PIDM PIDM,
       SPRIDEN_ID MATRICULA,
       REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
       SPRIDEN_FIRST_NAME FIRST_NAME,
       a.GOREMAL_EMAIL_ADDRESS EMAIL,
       SZSTUME_RSTS_CODE ESTATUS,
       SZSTUME_TERM_NRC TERM_NRC,
       GOZTPAC_PIN pwd,
       SZTGPME_PTRM_CODE_COMP servidor,
       SZTGPME_CRSE_MDLE_ID id_curso,
       SZTGPME_GPMDLE_ID id_grupo,
       SZSTUME_SEQ_NO secuencia,
       SZSTUME_NO_REGLA no_regla,
       SZTGPME_CAMP_CODE campus,
       SZTGPME_LEVL_CODE Nivel,
       SZSTUME_START_DATE Fecha_inicio
       FROM SPRIDEN,
       STVRSTS,
       GOREMAL a,
       SZSTUME,
       GOZTPAC,
       ZSTPARA,
       SZTGPME,
       SORLCUR c
       WHERE SPRIDEN_CHANGE_IND IS NULL
       AND SPRIDEN_PIDM = SZSTUME_PIDM
       AND SPRIDEN_PIDM = GOZTPAC_PIDM
       AND SZSTUME_RSTS_CODE = STVRSTS_CODE
       AND SPRIDEN_PIDM = a.GOREMAL_PIDM
       AND SZSTUME_STAT_IND = '0'
       AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
       AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
       AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
       AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
       AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
       AND SZSTUME_START_DATE = SZTGPME_START_DATE
       AND SZTGPME_STAT_IND = '1'
       AND SZTGPME_CRSE_MDLE_ID != 0
       AND SZSTUME_RSTS_CODE != 'RE'
       and SZSTUME_CAMP_CODE_COMP is null
       AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
       AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                     FROM GOREMAL a1
                                     WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                     AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
        AND c.SORLCUR_PIDM = SZSTUME_PIDM
        AND c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
                              from SORLCUR c1
                              where c.SORLCUR_PIDM = c1.SORLCUR_PIDM)
        AND SZTGPME_CAMP_CODE != 'EAF';

        RETURN (baja_alumnos_out);
      END;
   END f_baja_alumnos_moodle_out;





      FUNCTION f_updte_alumnos_moodle(p_trem_nrc in Varchar2, p_pidm in number, p_stat_upte_ind in Varchar2, p_obs in Varchar2,
                                                            p_asgn_mdle in Varchar2,p_error_code in Number,  p_error_desc in Varchar2, p_grade_final in Varchar2,
                                                            p_enrl_id_grpmoodle in varchar2, p_seq_no in number, p_no_regla in number, p_fecha_ini in varchar2) Return Varchar2
    AS
        vl_maximo number:=0;
        grade_min  Varchar2(10);
        grade_max  Varchar2(10);
        vl_grade_final Varchar2(10);
        vl_szstume_camp_code Varchar2(6);
        vl_szstume_level_code Varchar2(6);
        vl_error  varchar2(250) := 'EXITO';
        p_materia varchar2(50):= null;
       vl_salida  varchar2(250) := null;


      ----- Esta Funcion actualiza los estatus del envio de los alumnos  y regresa con los errores o exito
      ----- Se realiza modificacion para version final 02-Jun- 2017   ------
      ----- Preguntar antes de modificar -----
      -----    vmrl   -----


            BEGIN

                  IF  p_stat_upte_ind = 2 THEN

                         begin

                                 Begin

                                      Select nvl (max (SZTMEBI_SEQ_NO), 0 ) +1
                                      Into vl_maximo
                                      from SZTMEBI
                                      Where SZTMEBI_TERM_NRC = p_trem_nrc
                                      and SZTMEBI_CTGY_ID = 'Alumnos';
                                      Exception
                                      When Others then
                                      vl_maximo :=1;

                                END;

                                begin

                                    INSERT INTO SZTMEBI
                                    VALUES(p_trem_nrc, p_stat_upte_ind, p_error_code, p_error_desc, vl_maximo, sysdate,user, 'Alumnos', p_pidm);
                                    Exception
                                    When others then
                                    vl_error := 'Error al insertar Alumnos en la Bitacora'||sqlerrm;

                                End;

                                begin

                                    UPDATE SZSTUME
                                    SET SZSTUME_STAT_IND = p_stat_upte_ind,
                                        SZSTUME_OBS = p_obs,
                                        SZSTUME_ACTIVITY_DATE = sysdate
                                    WHERE SZSTUME_TERM_NRC = p_trem_nrc
                                    AND SZSTUME_PIDM = p_pidm
                                    AND SZSTUME_SEQ_NO = p_seq_no
                                    AND SZSTUME_NO_REGLA = p_no_regla
                                    AND SZSTUME_START_DATE = p_fecha_ini;

                                end;
                         Exception when others then
                         vl_error:= 'Error al trartar el szstume.stat_ind 2'||sqlerrm;
                         end;

                  ELSE
--                                          Insert into sztmebi (SZTMEBI_ERROR_DESC, SZTMEBI_ERROR_CODE)  values (p_trem_nrc||'*'|| p_stat_upte_ind||'*'||p_pidm||'*'||p_no_regla||'*'||p_seq_no||'*'||'ENTRA-ELSE',  666);
--                                               Commit;

                       begin
                            UPDATE SZSTUME a
                            SET a.SZSTUME_STAT_IND = p_stat_upte_ind,
                            a.SZSTUME_OBS = p_obs,
                            a.SZSTUME_MDLE_ID = p_asgn_mdle,
                            a.SZSTUME_ACTIVITY_DATE = sysdate
                            WHERE a.SZSTUME_TERM_NRC = p_trem_nrc
                            AND a.SZSTUME_PIDM = p_pidm
                            AND a.SZSTUME_SEQ_NO = p_seq_no
                            AND a.SZSTUME_NO_REGLA = p_no_regla
                            AND a.SZSTUME_START_DATE = p_fecha_ini;


                       Exception
                        When Others then
                          vl_error := 'Error al actualizar el alumno * '||p_trem_nrc ||'*'||p_pidm ||'*'||p_seq_no ||'*'||p_no_regla||' *'||sqlerrm;
                        end;

                  END IF;

              COMMIT;

                Return vl_error;

            END;


    FUNCTION f_goztpac_out RETURN PKG_MOODLE2.cursor_goztpac_out
        AS
        goztpac_out PKG_MOODLE2.cursor_goztpac_out;

              -----  Este procedimiento realiza la actualizcion de las contraseÒas y se realiza la union para actualizar tambien los registros de bienvenida.
              ----- Se realiza modificacion para version final 30-May- 2017   ------
              ----- Preguntar antes de modificar -----
              -----    vmrl   -----


        BEGIN
            begin
               open goztpac_out FOR               

 SELECT DISTINCT GOZTPAC_PIDM,
                        GOZTPAC_ID,
                        GOZTPAC_PIN,
                        GOZTPAC_PIN_DISABLED_IND,
                        GOZTPAC_STAT_IND,
                        ZSTPARA_PARAM_VALOR servidor,
                        A.GOREMAL_EMAIL_ADDRESS,
                        REPLACE(SPRIDEN_LAST_NAME,'/',' ') Apellido,
                        SPRIDEN_FIRST_NAME Nombre,
                        GZTPASS_DATE_UPDATE fecha
                    FROM GOZTPAC, SZSTUME, ZSTPARA, SGBSTDN, GOREMAL A, SPRIDEN, SZTCOMD, gztpass
                    WHERE GOZTPAC_PIDM = SZSTUME_PIDM
                    AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                    AND ZSTPARA_PARAM_ID = SUBSTR (GOZTPAC_ID, 1, 2)
                    AND ZSTPARA_PARAM_DESC = SZSTUME_LEVL_CODE
                    AND GOZTPAC_STAT_IND IN ('1', '3')
                    AND GOZTPAC_PIDM = SGBSTDN_PIDM
                    AND SGBSTDN_LEVL_CODE = SZTCOMD_LEVL_CODE
                    AND SGBSTDN_CAMP_CODE = SZTCOMD_CAMP_CODE
                    AND GOZTPAC_PIDM = GOREMAL_PIDM
                    AND GOZTPAC_PIDM = SPRIDEN_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                    AND A.GOREMAL_EMAL_CODE = NVL ('PRIN', A.GOREMAL_EMAL_CODE)
                    AND A.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                    FROM GOREMAL A1
                                                    WHERE A.GOREMAL_pidm = A1.GOREMAL_pidm
                                                    AND A.GOREMAL_EMAL_CODE = A1.GOREMAL_EMAL_CODE)
                    And GZTPASS_PIDM = GOZTPAC_PIDM
                    UNION
                    SELECT DISTINCT GOZTPAC_PIDM,
                        GOZTPAC_ID,
                        GOZTPAC_PIN,
                        GOZTPAC_PIN_DISABLED_IND,
                        GOZTPAC_STAT_IND,
                        ZSTPARA_PARAM_VALOR servidor,
                        A.GOREMAL_EMAIL_ADDRESS,
                        REPLACE(SPRIDEN_LAST_NAME,'/',' ') Apellido,
                        SPRIDEN_FIRST_NAME Nombre,
                        GZTPASS_DATE_UPDATE fecha
                    FROM GOZTPAC, ZSTPARA, GOREMAL A, SPRIDEN, gztpass
                    WHERE     1 = 1
                    AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                    AND ZSTPARA_PARAM_ID = SUBSTR (GOZTPAC_ID, 1, 2)
                    AND GOZTPAC_STAT_IND IN ('1', '3')
                    AND GOZTPAC_ID LIKE '0198%'
                    AND GOZTPAC_PIDM = GOREMAL_PIDM
                    AND GOZTPAC_PIDM = SPRIDEN_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                    AND GOREMAL_EMAL_CODE = NVL ('PRIN', A.GOREMAL_EMAL_CODE)
                    AND A.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                    FROM GOREMAL A1
                                                    WHERE A.GOREMAL_pidm = A1.GOREMAL_pidm
                                                    AND A.GOREMAL_EMAL_CODE = A1.GOREMAL_EMAL_CODE)
                    And GZTPASS_PIDM = GOZTPAC_PIDM
                    UNION
                    SELECT DISTINCT GOZTPAC_PIDM,
                        GOZTPAC_ID,
                        GOZTPAC_PIN,
                        GOZTPAC_PIN_DISABLED_IND,
                        GOZTPAC_STAT_IND,
                        ZSTPARA_PARAM_VALOR servidor,
                        A.GOREMAL_EMAIL_ADDRESS,
                        REPLACE(SPRIDEN_LAST_NAME,'/',' ') Apellido,
                        SPRIDEN_FIRST_NAME Nombre,
                        GZTPASS_DATE_UPDATE fecha
                    FROM GOZTPAC, SZTBNDA, ZSTPARA, SGBSTDN, GOREMAL A, SPRIDEN, SZTCOMD, gztpass
                    WHERE GOZTPAC_PIDM = SZTBNDA_PIDM
                    AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                    AND ZSTPARA_PARAM_ID = SUBSTR (GOZTPAC_ID, 1, 2)
                    AND ZSTPARA_PARAM_DESC = SZTBNDA_LEVL_CODE
                    AND GOZTPAC_STAT_IND IN ('1', '3')
                    AND GOZTPAC_PIDM = SGBSTDN_PIDM
                    AND SGBSTDN_LEVL_CODE = SZTCOMD_LEVL_CODE
                    AND SGBSTDN_CAMP_CODE = SZTCOMD_CAMP_CODE
                    AND SZTBNDA_STAT_IND = 1
                    AND GOZTPAC_PIDM = GOREMAL_PIDM
                    AND GOZTPAC_PIDM = SPRIDEN_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                    AND A.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                    AND A.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                    FROM GOREMAL A1
                                                    WHERE A.GOREMAL_pidm = A1.GOREMAL_pidm
                                                    AND A.GOREMAL_EMAL_CODE = A1.GOREMAL_EMAL_CODE)
                    And GZTPASS_PIDM = GOZTPAC_PIDM
                    UNION
                    SELECT DISTINCT GOZTPAC_PIDM,
                        GOZTPAC_ID,
                        GOZTPAC_PIN,
                        GOZTPAC_PIN_DISABLED_IND,
                        GOZTPAC_STAT_IND,
                        ZSTPARA_PARAM_VALOR servidor,
                        A.GOREMAL_EMAIL_ADDRESS,
                        REPLACE(SPRIDEN_LAST_NAME,'/',' ') Apellido,
                        SPRIDEN_FIRST_NAME Nombre,
                        GZTPASS_DATE_UPDATE fecha
                    FROM GOZTPAC, ZSTPARA, SGBSTDN, GOREMAL A, SPRIDEN, SZTCOMD, gztpass
                    WHERE ZSTPARA_MAPA_ID = 'MOODLE_ID'
                    AND ZSTPARA_PARAM_ID = SUBSTR (GOZTPAC_ID, 1, 2)
                    AND GOZTPAC_STAT_IND IN ('1', '3')
                    AND GOZTPAC_PIDM = SGBSTDN_PIDM
                    AND SGBSTDN_LEVL_CODE = SZTCOMD_LEVL_CODE
                    AND SGBSTDN_CAMP_CODE = SZTCOMD_CAMP_CODE
                    AND GOZTPAC_PIDM = GOREMAL_PIDM
                    AND GOZTPAC_PIDM = SPRIDEN_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                    AND A.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                    AND A.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                    FROM GOREMAL A1
                                                    WHERE A.GOREMAL_pidm = A1.GOREMAL_pidm
                                                    AND A.GOREMAL_EMAL_CODE = A1.GOREMAL_EMAL_CODE)
                    And GZTPASS_PIDM = GOZTPAC_PIDM
                    order by fecha asc;
              RETURN (goztpac_out);
              end;
        END f_goztpac_out ;





    FUNCTION  f_goztpac_update(p_pidm in number, p_stat_ind in varchar2, p_error_desc in Varchar2, p_error_code in Varchar2) Return Varchar2
    AS
        vl_error varchar2(250):='EXITO';
        vl_aux varchar2(1);
        vl_maximo number;

              -----  Este procedimiento realiza la actualizcion de los estatus en la tabla de Banner y MySql
              ----- Se realiza modificacion para version final 30-May- 2017   ------
              ----- Preguntar antes de modificar -----
      BEGIN        -----    vmrl   -----

          IF p_stat_ind ='2'  THEN

                    begin
                      Select nvl (max (SZTMEBI_SEQ_NO), 0 ) +1
                      Into vl_maximo
                      from SZTMEBI
                      Where SZTMEBI_PIDM = p_pidm
                      AND SZTMEBI_CTGY_ID = 'User_pass';
                    Exception
                    When Others then
                    vl_maximo :=1;
                   End;

                   dbms_output.put_line('trae el m·ximo seqno '||vl_maximo||'pidm '||p_pidm);

                    begin

                        insert into sztmebi
                                    values('00000',
                                    p_stat_ind,
                                    p_error_code,
                                    p_error_desc,
                                    vl_maximo,
                                    sysdate,
                                    user,
                                    'User_pass',
                                    p_pidm);

                      Exception when others then
                      vl_error := 'Error al insertar en SZTMEBI '||sqlerrm;
                     end;

                   --dbms_output.put_line('salida en sztmebi a='||vl_error);

                       begin

                       update goztpac set goztpac_stat_ind = p_stat_ind
                       where goztpac_pidm= p_pidm;


                      Exception when others then
                      vl_error := 'Error al actualizar goztpac con stat_ind = 2 '||sqlerrm;
                     end;

              --    dbms_output.put_line('actualiza estatus 6= ' ||vl_error);


          ELSIF  p_stat_ind ='1' THEN

                    begin
                     update goztpac set goztpac_stat_ind= '0'
                     where goztpac_pidm = p_pidm;
                     exception when others then
                     vl_error:=  'Error al actualizar goztpac con stat_ind 0 '||sqlerrm;
                    end;

                --dbms_output.put_line('actualizÛ a:'|| p_pidm||'con: '||p_stat_ind);

          ELSIF p_stat_ind  = '3'  THEN

                    begin

                     update  goztpac set  goztpac_pin_disabled_ind = Null, goztpac_stat_ind = 0
                     where goztpac_pidm = p_pidm;
                     exception when others then
                     vl_error:=  'Error al actualizar goztpac con stat_ind 3 '||sqlerrm;

                    end;
                    --dbms_output.put_line('actualizÛ a:'|| p_pidm||'con: '||p_stat_ind);
          END IF;

          If vl_error = 'EXITO' then
              commit;
           Else
              rollback;
          End if;
          Return vl_error;
        END;



            FUNCTION f_szbamdl_out RETURN PKG_MOODLE2.cursor_bajas_out
            AS
            bajas_out PKG_MOODLE2.cursor_bajas_out;

              -----  Este procedimiento envia la informacion para bloquear o desbloquear a los alumnos de Moodle cuando su estatus general cambioa en sgastdn
              ----- Se realiza modificacion para version final 31-May- 2017   ------
              ----- Preguntar antes de modificar -----
              -----    vmrl   -----




            BEGIN
                begin
                    OPEN bajas_out
                    FOR SELECT
                    SZBAMDL_PIDM  PIDM,
                    SZBAMDL_ID  MATRICULA,
                    SZBAMDL_STAT_IND STAT_IND,
                    ZSTPARA_PARAM_VALOR servidor
                    FROM SZBAMDL , ZSTPARA
                    WHERE
                    SZBAMDL_STAT_IND IN ('1','2')
                     AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                     AND ZSTPARA_PARAM_ID = substr (SZBAMDL_ID, 1, 2)
                    AND ZSTPARA_PARAM_DESC = SZBAMDL_LEVL_CODE;
                    RETURN(bajas_out);
                end;
           END f_szbamdl_out;


    FUNCTION  f_szbamdl_update(p_pidm in number, p_stat_ind in varchar2, p_szbamdl_id in number) Return Varchar2
    AS
        vl_error varchar2(250):='FunciÛn f_szbamdl_update: Exitosa';
        vl_aux varchar2(1);

              -----  Este procedimiento actualiza los estatus de los alumnos  de bajas o matriculados
              ----- Se realiza modificacion para version final 31-May- 2017   ------
              ----- Preguntar antes de modificar -----
              -----    vmrl   -----



            BEGIN
                DECLARE CURSOR o IS
                SELECT SZBAMDL_PIDM PIDM,
                SZBAMDL_ID,
                SZBAMDL_STAT_IND STAT_IND,
                SZBAMDL_DISABLED_IND
                FROM SZBAMDL where SZBAMDL_PIDM = p_pidm
                FOR UPDATE OF SZBAMDL_STAT_IND, SZBAMDL_MDLE_ID;

                 BEGIN

                   for upte in o LOOP
                        if  p_stat_ind = 1 then
                            UPDATE SZBAMDL
                            SET  SZBAMDL_STAT_IND = '0', SZBAMDL_MDLE_ID = p_szbamdl_id
                            WHERE CURRENT OF o;
                        else
                        if p_stat_ind  = 2  THEN
                            update  SZBAMDL
                            SET SZBAMDL_DISABLED_IND = Null, SZBAMDL_STAT_IND = 0
                            where current of o;
                        else
                            DBMS_OUTPUT.PUT_LINE(p_stat_ind);
                        end if;
                    end if;
                   END LOOP;
                    COMMIT;
                   END;
                   return vl_error;
                    exception  when others then
                    vl_error:='Erroro en f_szbamdl_update'||SQLERRM;
                    RETURN  vl_error;
                    END;

   FUNCTION f_sztbnda_out
      RETURN PKG_MOODLE2.cursor_bnda_out
   AS
      bnda_out   PKG_MOODLE2.cursor_bnda_out;
   ---- Este procedimiento realiza el envio de la informacion hacia Moodle  de los cursos de Bienvenida ------
   --- Unicamente para los estatus 0 ----
   ----- Se realiza modificacion para version final 29-May- 2017   ------
   ----- Preguntar antes de modificar -----
   -----    vmrl   -----


    BEGIN
      BEGIN
         OPEN bnda_out FOR
            SELECT DISTINCT
                     SZTBNDA_PIDM PIDM,
                     SZTBNDA_ID MATRICULA,
                     REPLACE (
                        TRANSLATE (SPRIDEN.SPRIDEN_LAST_NAME,
                                   '·ÈÌÛ˙¡…Õ”⁄',
                                   'aeiouAEIOU'),
                        '/',
                        ' ')
                        LAST_NAME,
                     SPRIDEN_FIRST_NAME FIRST_NAME,
                     GOREMAL_EMAIL_ADDRESS EMAIL,
                     SZTCOMD_SERVIDOR SERVIDOR,
                     SZTBNDA_TERM_NRC TERM,
                     SZTBNDA_PWD PWD,
                     SZTBNDA_CRSE_SUBJ CRS_MOODLE,
                     SZTCOMD_GRP_MDL_ID id_grupo,
                     SZTCOMD_CRSE_MDL_ID id_curso,
                     SZTCOMD_CAMP_CODE campus
                FROM SZTBNDA,
                     SPRIDEN,
                     GOREMAL,
                     SZTCOMD
               WHERE SZTBNDA_STAT_IND = '0'
                     AND SZTBNDA_PIDM = SPRIDEN_PIDM
                     AND GOREMAL_PIDM = SZTBNDA_PIDM(+)
                     AND GOREMAL_EMAL_CODE = NVL ('PRIN', GOREMAL_EMAL_CODE)
                     AND SZTBNDA_CAMP_CODE = SZTCOMD_CAMP_CODE
                     AND SZTBNDA_LEVL_CODE = SZTCOMD_LEVL_CODE
                     AND SZTBNDA_CRSE_SUBJ = SZTCOMD_GRP_CODE
                     AND SZTCOMD_ENABLE_IND = 'Y'
                     AND SZTBNDA_CAMP_CODE NOT IN(SELECT ZSTPARA_PARAM_ID
                                                FROM ZSTPARA
                                                WHERE 1=1
                                                AND ZSTPARA_MAPA_ID = 'CAMPUS_UNIVERSI')
                     AND SPRIDEN_CHANGE_IND IS NULL
                     AND SZTBNDA_MDLE_STAT IS NULL
                     --AND SZTBNDA_ID = '010007241'
            ORDER BY CRS_MOODLE DESC;

         RETURN (bnda_out);
      END;
   END f_sztbnda_out;


     FUNCTION f_sztbnda_update (p_pidm        IN NUMBER,
                              p_term        IN VARCHAR2,
                              p_stat_ind    IN VARCHAR2,
                              p_obs         IN VARCHAR2,
                              p_grp_id      IN NUMBER,
                              p_shrt_name   IN VARCHAR2)
      RETURN VARCHAR2
   AS
      vl_error   VARCHAR2 (250) := 'FunciÛn f_sztbnda_update: Exitosa';
      vl_aux     VARCHAR2 (1);
   -----  Este procedimiento realiza la actualizacion de la tabla de bienvenida, cuando regresa la informacion que se intento integrar a Moodle
   ----- Se realiza modificacion para version final 29-May- 2017   ------
   ----- Preguntar antes de modificar -----
   -----    vmrl   -----

   BEGIN

    FOR c IN (SELECT a.SZTBNDA_PIDM pidm,
               a.SZTBNDA_ID matricula,
               a.SZTBNDA_TERM_NRC perido,
               a.SZTBNDA_GRP_MDL_ID id_grupo,
               a.SZTBNDA_CRSE_SUBJ short_name,
               a.SZTBNDA_CAMP_CODE campus,
               a.SZTBNDA_LEVL_CODE nivel,
               a.SZTBNDA_SEQ_NO consecutivo
            FROM SZTBNDA a
            WHERE 1=1
            --AND a.SZTBNDA_MDLE_STAT = 'DD'
            --AND a.SZTBNDA_STAT_IND = 1
            AND a.SZTBNDA_SEQ_NO IN (SELECT MAX(SZTBNDA_SEQ_NO)
                                   FROM SZTBNDA b
                                   WHERE 1=1
                                   AND b.SZTBNDA_PIDM = a.SZTBNDA_PIDM
                                   AND b.SZTBNDA_TERM_NRC = a.SZTBNDA_TERM_NRC
                                   AND b.SZTBNDA_CRSE_SUBJ = a.SZTBNDA_CRSE_SUBJ)
            AND SZTBNDA_TERM_NRC = p_term --'012041'
            AND SZTBNDA_PIDM = p_pidm --219077
            AND SZTBNDA_CRSE_SUBJ = p_shrt_name
     )loop


      BEGIN
         UPDATE SZTBNDA
            SET SZTBNDA_STAT_IND = p_stat_ind,
                SZTBNDA_OBS = SUBSTR(p_obs,1,250),
                SZTBNDA_GRP_MDL_ID = p_grp_id,
                SZTBNDA_ACTIVITY_DATE = sysdate
          WHERE     SZTBNDA_PIDM = p_pidm
                AND SZTBNDA_TERM_NRC = c.perido
                AND SZTBNDA_CRSE_SUBJ = c.short_name
                AND SZTBNDA_SEQ_NO = c.consecutivo;
      END;
    end loop;
    COMMIT;
    RETURN vl_error;
    EXCEPTION
    WHEN OTHERS
    THEN
    vl_error := 'Error en f_sztbnda_update' || SQLERRM;
    RETURN vl_error;
   END f_sztbnda_update;


  FUNCTION f_update_stat_sinc (p_term_code in VARCHAR2, p_camp_code in VARCHAR2, p_levl_code  in VARCHAR2, p_ptrm in varchar2, p_updte_sinc  in VARCHAR2) return varchar2
   AS
     vl_error varchar2(250) := 'Exito';
    BEGIN

              -----  Este procedimiento realiza la actualizacion de la tabla de Control, cuando regresa la informacion que se intento integrar a Moodle
              ----- Se realiza modificacion para version final 29-May- 2017   ------
              ----- Preguntar antes de modificar -----
              -----    vmrl   -----


        IF p_updte_sinc ='SZTGPME' THEN

            BEGIN
                    update sztpobi
                    set SZTPOBI_SZTGPME_SINC_IND = 1
                    where
                    SZTPOBI_TERM_CODE = p_term_code
                    and SZTPOBI_CAMP_CODE = p_camp_code
                    and SZTPOBI_STVLEVL_CODE = p_levl_code
                    and SZTPOBI_PTRM =p_ptrm;
            COMMIT;
            return vl_error;
            EXCEPTION
            WHEN OTHERS THEN
            vl_error:= 'Error'||sqlerrm;
            return vl_error;
            END;


           ELSIF  p_updte_sinc = 'SZSGNME' THEN

                 BEGIN
                    update sztpobi
                    set SZTPOBI_SZSGNME_SINC_IND = 1
                    where
                    SZTPOBI_TERM_CODE = p_term_code
                    and SZTPOBI_CAMP_CODE = p_camp_code
                    and SZTPOBI_STVLEVL_CODE = p_levl_code
                    and SZTPOBI_PTRM =p_ptrm;
              COMMIT;
              return vl_error;
              EXCEPTION
              WHEN OTHERS THEN
              vl_error:= 'Error'||sqlerrm;
              return vl_error;
              END;


        ELSIF  p_updte_sinc = 'SZSTUME' THEN

            BEGIN

                update sztpobi
                set SZTPOBI_SZSTUME_SINC_IND = 1
                where
                SZTPOBI_TERM_CODE = p_term_code
                and SZTPOBI_CAMP_CODE = p_camp_code
                and SZTPOBI_STVLEVL_CODE = p_levl_code
                and SZTPOBI_PTRM =p_ptrm;
            COMMIT;
            return vl_error;
            EXCEPTION
            WHEN OTHERS THEN
            vl_error:= 'Error'||sqlerrm;
            return vl_error;
            END;

       END IF;
     return vl_error;
END f_update_stat_sinc;


  FUNCTION f_bienvenida_correos_out(p_pidm in number) RETURN PKG_MOODLE2.cursor_correos_bnda_out
        AS
        correos_bnda_out PKG_MOODLE2.cursor_correos_bnda_out;

         begin
                       OPEN correos_bnda_out
                        FOR
                        SELECT SPRIDEN_ID matricula,
                        replace(translate (SPRIDEN.SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'), '/',' ')||' '||SPRIDEN_FIRST_NAME Nombre,
                        GOREMAL_EMAIL_ADDRESS Correo,
                        SORLCUR_CAMP_CODE Campus,
                        SZTDTEC_PROGRAMA_COMP Programa,
                        STVLEVL_DESC Modalidad,
                        to_char(a.SORLCUR_START_DATE, 'dd-mm-yyyy') Inicio_clases,
                        DECODE(SZTDTEC_MOD_TYPE,'OL','ES','I','IN','S','ES') USRLANG
                        FROM SPRIDEN, GOREMAL, SORLCUR a, SZTDTEC, STVLEVL
                        WHERE
                        SPRIDEN_PIDM = GOREMAL_PIDM
                        AND SPRIDEN_CHANGE_IND IS NULL
                        AND GOREMAL_EMAL_CODE  = NVL ( 'PRIN',  GOREMAL_EMAL_CODE)
                        AND SPRIDEN_PIDM = SORLCUR_PIDM
                        AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                        AND a.SORLCUR_ROLL_IND = 'Y'
                        AND a.SORLCUR_LMOD_CODE = 'LEARNER'
                        AND a.SORLCUR_KEY_SEQNO = (SELECT MAX(SORLCUR_KEY_SEQNO)
                                                                        FROM SORLCUR b
                                                                        WHERE a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                                                        AND a.SORLCUR_SEQNO = b.SORLCUR_SEQNO
                                                                        AND a.SORLCUR_LMOD_CODE = b.SORLCUR_LMOD_CODE )
                        AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                        AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                        AND SORLCUR_LEVL_CODE = STVLEVL_CODE
                        AND SZTDTEC_ACTIVITE_DATE = (SELECT MAX(SZTDTEC_ACTIVITE_DATE)
                                                    FROM
                                                    SZTDTEC
                                                    WHERE
                                                    a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                                    AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                                    )
                        AND SPRIDEN_PIDM = p_pidm;
                        return(correos_bnda_out);
         end;

FUNCTION f_insert_sztlogs (p_daemon in varchar2, p_error in varchar2, p_data in varchar2) return varchar2

     as
       vl_error varchar2(250) := 'Exito';
    BEGIN
                begin
                 insert into sztlogs values(p_daemon, p_error, p_data);
                 commit;
                Exception
                    When Others then
                            vl_error:= 'Error'||sqlerrm;
                end;

      Return vl_error;
     exception
        when others  then
            vl_error:= 'Error'||sqlerrm;
        return vl_error;
    END;


  FUNCTION f_delete_grp_sync RETURN PKG_MOODLE2.cursor_delete_grp_sync_out
  as
    delete_grp_sync_out PKG_MOODLE2.cursor_delete_grp_sync_out;

    BEGIN

        begin
            OPEN delete_grp_sync_out
            FOR SELECT DISTINCT SZTGPME_CRSE_MDLE_ID id_moodle_crse,
            SZTGPME_GPMDLE_ID id_grp_crse
            FROM SZTGPME
            WHERE SZTGPME_STAT_IND =1
            AND SZTGPME_CRSE_MDLE_ID !=0
            AND SUBSTR (SZTGPME_OBS,0,28) = 'Sincronizado || grupo creado';
            return(delete_grp_sync_out);
        end;

    END f_delete_grp_sync;



FUNCTION f_grupos_docentes_out RETURN PKG_MOODLE2.cursor_grupos_docentes_out
AS
   c_out1 PKG_MOODLE2.cursor_grupos_docentes_out;

    BEGIN

        BEGIN
         open c_out1 FOR
          SELECT  DISTINCT SZSGNME_PIDM PIDM,
               SPRIDEN_ID matricula,
               replace(translate (SPRIDEN.SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'), '/',' ' ) Nombre,
               GOREMAL_EMAIL_ADDRESS email,
               SZTGPME_CRSE_MDLE_CODE Short_name,
               SZTGPME_CRSE_MDLE_ID id_crse
            FROM SZTGPME, SZSGNME, SPRIDEN, GOREMAL a
            WHERE  SZSGNME_PIDM = SPRIDEN_PIDM
            AND SPRIDEN_CHANGE_IND IS NULL
            AND SPRIDEN_PIDM = GOREMAL_PIDM
            AND a.GOREMAL_EMAL_CODE  = NVL ( 'PRIN',  a.GOREMAL_EMAL_CODE)
            AND a.GOREMAL_SURROGATE_ID = (SELECT MAX ( a1.GOREMAL_SURROGATE_ID)
                                                                  from GOREMAL a1
                                                                  where a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                                  and a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
            AND SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
            AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
            --AND SPRIDEN_ID != '019814933'
            AND SZTGPME_CRSE_MDLE_ID != 0
            ORDER BY 1 ASC;
        RETURN(c_out1);
        END;


    END f_grupos_docentes_out;



FUNCTION f_grupos_docentes_insert (p_pidm in number, p_id in varchar2, p_name in varchar2, p_shrt_name in varchar2, p_id_crse in number, p_id_grp in number, p_obs varchar2) return varchar2

    as
    vl_error varchar2(250) := 'Exito';

--     delete SZGPNTE;
--     commit;

    BEGIN


       begin
        insert into  SZGPNTE values (p_pidm, p_id, p_name, p_shrt_name, p_id_crse, p_id_grp, p_obs, sysdate);
       commit;
      exception when others
      then vl_error:= 'Error'||sqlerrm;
      end;


      begin

      for c in (
        SELECT SZSGNME_STAT_IND, SZSGNME_OBS, SZSGNME_ASGNMDLE_ID, SZSGNME_TERM_NRC
                                FROM SZSGNME, SZTGPME
                                WHERE  SZTGPME_TERM_NRC=SZSGNME_TERM_NRC
                                AND SZTGPME_CRSE_MDLE_ID= p_id_crse
                                AND SZSGNME_PIDM = p_pidm
                   )
                   loop
                   update SZTGPME set SZTGPME_GPMDLE_ID = p_id_grp
                   where SZTGPME_TERM_NRC = c.SZSGNME_TERM_NRC;

                   update SZSGNME set SZSGNME_STAT_IND = 1, SZSGNME_OBS='SYNC_INI'
                   where SZSGNME_TERM_NRC = c.SZSGNME_TERM_NRC;
                   end loop;
                   commit;
      end;
      return vl_error;

    END;

FUNCTION F_MATERIAS_RE_DD(P_PIDM IN NUMBER) RETURN PKG_MOODLE2.CURSOR_F_MATERIAS_RE_DD
        AS
        MATERIAS_RE_DD PKG_MOODLE2.CURSOR_F_MATERIAS_RE_DD;


 BEGIN

        OPEN MATERIAS_RE_DD
        FOR
        SELECT SFRSTCR_PIDM,
               SFRSTCR_RSTS_CODE,
               SFRSTCR_GRDE_CODE,
               (SELECT SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB
               FROM SSBSECT
               WHERE SSBSECT_CRN = A.SFRSTCR_CRN
               AND  SSBSECT_TERM_CODE = A.SFRSTCR_TERM_CODE)CLAVE_MAT
            FROM SFRSTCR A
            WHERE 1=1
            AND SFRSTCR_RSTS_CODE = 'RE'
            AND A.SFRSTCR_PIDM = P_PIDM;
        RETURN (MATERIAS_RE_DD);


 END F_MATERIAS_RE_DD;

 PROCEDURE p_detona_pass IS

     BEGIN

        FOR c in  (
                    SELECT SZTBNDA_PIDM,
                    SZTBNDA_ID,
                    SZTBNDA_STAT_IND,
                    GOZTPAC_STAT_IND
                    FROM SZTBNDA , GOZTPAC
                    WHERE SZTBNDA_PIDM = GOZTPAC_PIDM
                    AND SZTBNDA_STAT_IND = 1
                    AND GOZTPAC_STAT_IND = 6
                    AND GOZTPAC_PIN_DISABLED_IND ='N'
                    AND GOZTPAC_USAGE_ACCEPT_IND ='N'
                    UNION
                    SELECT SZSTUME_PIDM,
                    SZSTUME_ID,
                    SZSTUME_STAT_IND,
                    GOZTPAC_STAT_IND
                    FROM SZSTUME , GOZTPAC
                    WHERE SZSTUME_PIDM = GOZTPAC_PIDM
                    AND SZSTUME_STAT_IND = '1'
                    AND GOZTPAC_STAT_IND = '6'
                    AND GOZTPAC_PIN_DISABLED_IND ='N'
                    AND GOZTPAC_USAGE_ACCEPT_IND ='N'

                 )loop
                    UPDATE  GOZTPAC SET GOZTPAC_STAT_IND = '1'
                    WHERE GOZTPAC_PIDM = c.SZTBNDA_PIDM;
                end loop;
        commit;
  end p_detona_pass;

 Procedure  p_inserta_sztbnda (p_pidm in number, p_term_code in varchar2, p_appl_no in number)
    as

     vl_nivel varchar2(4);
        vl_campus varchar2(4);
        vl_maximo number;
        vl_cuenta varchar2(9);
        vl_password varchar2(250);
        vl_password_1 varchar2(250);
        vl_materia_ins varchar2(20);
        vl_contador number;
        vl_maximo_ins number;
        vl_periodicidad number;
        vl_type varchar2(2) := null;
        vl_msje varchar2 (250):= 'Exito';
        vl_bandera number;
        vl_bandera_1 number;
        vl_fecha_ini  varchar2(12):= null;
        vl_utlx number;
        vl_utlx_seqno number;
        vl_valida_costo number;
        vl_freemium number:=0;
        vl_ETIQ_EXPERIENCI number:=0;
        vl_campuve number;
        vl_niuve  VARCHAR2(3);
    
   BEGIN

         --Se realiza el procedimiento para la carga de la materia de Bienvenida para nuevos ingresos en Moodle
         --obteniemdo el nivel, campus,  el short_name del curso activo en moodle, por pidm -periodo--


       BEGIN

           BEGIN
            SELECT GOZTPAC_PIN
            INTO vl_password
            FROM GOZTPAC
            WHERE GOZTPAC_PIDM =p_pidm;
           Exception
           when no_data_found then
           vl_password:=null;
           END;

           BEGIN
            SELECT  count(GOZTPAC_PIN)
            INTO vl_bandera
            FROM GOZTPAC
            WHERE GOZTPAC_PIDM =p_pidm;
           Exception
           when no_data_found then
           vl_bandera:=0;
           END;

           BEGIN
            SELECT SPRIDEN_ID
            INTO vl_cuenta
            FROM SPRIDEN
            WHERE 1=1
            AND SPRIDEN_PIDM = p_pidm
            AND SPRIDEN_CHANGE_IND IS NULL;
           END;

          IF vl_bandera = 0 THEN

           BEGIN
            SELECT SPRIDEN_ID
            INTO vl_cuenta
            FROM SPRIDEN
            WHERE 1=1
            AND SPRIDEN_PIDM = p_pidm
            AND SPRIDEN_CHANGE_IND IS NULL;
           END;


           BEGIN
            select BANINST1.sha1(gztpass_pin)
            into vl_password
            from GZTPASS where gztpass_pidm = p_pidm;
           Exception
           when no_data_found then
           vl_bandera_1:= BANINST1.sha1(vl_cuenta);
           END;


           begin
             insert into  goztpac values (p_pidm, vl_cuenta,vl_password,'N', 'N','1');
           end;

           BEGIN
              select gztpass_pin
              into vl_password_1
              from GZTPASS where gztpass_pidm = p_pidm;
           Exception
           when no_data_found then
           vl_bandera_1:=0;
           END;

               if vl_bandera_1 = 0 then

                begin
                insert into  gztpass values (p_pidm, vl_cuenta,vl_cuenta,'0',user, sysdate, user, sysdate);
                end;

               else
                update gztpass set gztpass_pin = vl_password_1
                where 1=1
                and gztpass_pidm = p_pidm;
               end if;

         END IF;
       END;

     COMMIT;
            dbms_output.put_line('Validando GOZTPAC Y GZTPASS '||vl_bandera||' '||vl_bandera_1||' '||vl_password||vl_cuenta);

          BEGIN
           SELECT COUNT(TZFACCE_PIDM)
           INTO vl_valida_costo
           FROM TZFACCE
           WHERE 1=1
           AND TZFACCE_PIDM = p_pidm;
           exception when no_data_found then
           vl_valida_costo:=0;
          END;

          BEGIN
           SELECT COUNT(DISTINCT(GORADID_PIDM))
           INTO vl_utlx
           FROM GORADID
           WHERE 1=1
           AND GORADID_PIDM = p_pidm
           AND GORADID_ADID_CODE = 'UTLX';
           EXCEPTION
           WHEN OTHERS THEN
           vl_utlx := 0;
          END;

          Begin
            select count(1)
                Into vl_freemium
            from goradid
            where 1= 1
            And  GORADID_PIDM = p_pidm
            And  GORADID_ADID_CODE in (  Select ZSTPARA_PARAM_VALOR
                                                        from ZSTPARA
                                                        where ZSTPARA_MAPA_ID = 'FREEMIUM_ADID'
                                                    );
          Exception
            When OThers then
                vl_freemium:=0;
          End;


         BEGIN
          SELECT a.SORLCUR_LEVL_CODE
          INTO vl_nivel
            FROM SORLCUR a
            where 1=1
            AND A.SORLCUR_PIDM = p_pidm
            AND A.SORLCUR_TERM_CODE = p_term_code
            AND A.SORLCUR_LMOD_CODE = 'LEARNER'
            AND A.SORLCUR_ROLL_IND = 'Y'
            AND A.SORLCUR_CACT_CODE ='ACTIVE'
            AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                      where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                      and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                      and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                      and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE);
         END;
         
         BEGIN
          SELECT COUNT(DISTINCT(c.SARADAP_PIDM))
             INTO VL_ETIQ_EXPERIENCI
            FROM SARADAP C
            JOIN GORADID B ON C.SARADAP_PIDM = B.GORADID_PIDM
            RIGHT JOIN TZTPADI D ON B.GORADID_PIDM=D.TZTPADI_PIDM
            RIGHT JOIN TZFACCE E ON B.GORADID_PIDM=E.TZFACCE_PIDM
            WHERE 1= 1
            AND B.GORADID_ADID_CODE IN (SELECT a.ZSTPARA_PARAM_ID
                                                        FROM ZSTPARA a
                                                        WHERE a.ZSTPARA_MAPA_ID IN ('ETIQ_EXPERIENCI')
                                                        and SUBSTR(a.ZSTPARA_PARAM_DESC,4,2)=c.SARADAP_LEVL_CODE)
            AND D.TZTPADI_FLAG=0   
            AND E.TZFACCE_FLAG=0
            AND C.SARADAP_APPL_NO =(SELECT MAX (C1.SARADAP_APPL_NO)
                                     FROM SARADAP C1
                                     WHERE 1=1
                                     AND C1.SARADAP_PIDM=C.SARADAP_PIDM)                                       
            AND C.SARADAP_PIDM =P_PIDM;
                 
          EXCEPTION
            WHEN OTHERS THEN
                VL_ETIQ_EXPERIENCI:=0;
          END;
          
          BEGIN
                    SELECT count(SARADAP_CAMP_CODE),SARADAP_LEVL_CODE
                          INTO vl_campuve,vl_niuve
                          FROM SARADAP C
                          WHERE 1= 1                                    
                          AND C.SARADAP_PIDM =p_pidm
                          and c.SARADAP_CAMP_CODE='UVE'
                          group by SARADAP_LEVL_CODE;
          EXCEPTION WHEN OTHERS THEN
                       vl_campuve := 0;
          END;

      BEGIN

         IF vl_utlx = 1 And vl_freemium = 0 THEN --vl_valida_costo >0

              BEGIN
                  SELECT NVL(MAX(SZTUTLX_SEQ_NO),0)+1
                  into vl_utlx_seqno
                  FROM SZTUTLX
                  WHERE 1=1
                  AND SZTUTLX_PIDM = p_pidm;
              EXCEPTION
              WHEN OTHERS THEN
              vl_utlx_seqno:=1;
              END;

             BEGIN
               FOR i IN (

                        SELECT SPRIDEN_ID cuenta, SORLCUR_CAMP_CODE campus, SORLCUR_LEVL_CODE nivel,GOZTPAC_PIN pass
                        FROM SORLCUR a, SPRIDEN, GOZTPAC
                        WHERE 1=1
                        AND a.SORLCUR_PIDM = spriden_pidm
                        AND a.SORLCUR_PIDM = goztpac_pidm
                        AND SPRIDEN_CHANGE_IND is null
                        AND a.SORLCUR_PIDM =  p_pidm --fget_pidm('010243783')
                        AND a.SORLCUR_TERM_CODE = p_term_code
                        AND a.SORLCUR_LMOD_CODE = 'LEARNER'
                        AND a.SORLCUR_ROLL_IND = 'Y'
                        AND a.SORLCUR_CACT_CODE ='ACTIVE'
                        AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                              where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                              and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                              and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                              and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)

                  )loop
                        INSERT INTO SZTUTLX VALUES(P_PIDM,--SZTUTLX_PIDM
                                           i.cuenta, --SZTUTLX_ID
                                           p_term_code,--SZTUTLX_TERM_CODE
                                           i.campus,--SZTUTLX_CAMP_CODE
                                           i.nivel,--SZTUTLX_LEVL_UPDATE
                                           vl_utlx_seqno,--SZTUTLX_SEQ_NO
                                           0,--SZTUTLX_STAT_IND
                                           Null,--SZTUTLX_OBS
                                           'A',--SZTUTLX_DISABLE_IND
                                           i.pass,--SZTUTLX_PWD
                                           Null,--SZTUTLX_MDL_ID
                                           USER,--SZTUTLX_USER_INSERT
                                           SYSDATE,--SZTUTLX_ACTIVITY_DATE
                                           Null,--SZTUTLX_DATE_UPDATE
                                           Null,--SZTUTLX_USER_UPDATE
                                           Null,--SZTUTLX_ROW1
                                           Null,--SZTUTLX_ROW2
                                           Null,--SZTUTLX_ROW3
                                           Null,--SZTUTLX_ROW4
                                           Null,--SZTUTLX_ROW5
                                           Null,
                                           Null,
                                           null,
                                           null,
                                           null,
                                           NULL,
                                            NULL,
                                            NULL
                                           );
                END LOOP;
               commit;
              END;

             BEGIN

                FOR c IN(
                      SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                      FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC
                      WHERE a.SORLCUR_PIDM = p_pidm
                      AND a.SORLCUR_TERM_CODE = p_term_code
                      --AND a.SORLCUR_LMOD_CODE='ADMISSIONS'
                      --AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                      AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                      AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                      AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                      AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                      AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                      AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                      AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                      AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                      AND SZTCOMD_ENABLE_IND ='Y'
                      AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                      AND SPRIDEN_CHANGE_IND IS NULL
                      AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                          where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                          and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE)
                                          --and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                          --and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)

                /*
                UNION
                    SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                                  FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC
                                  WHERE a.SORLCUR_PIDM =p_pidm -- 29161
                                  AND a.SORLCUR_TERM_CODE =p_term_code
                                  AND a.SORLCUR_LMOD_CODE='ADMISSIONS'
                                  AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                  AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                  AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                  AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                                  AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                                  AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                  AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                                  AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                  AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                                  AND SZTCOMD_ENABLE_IND ='Y'
                                  AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                                  AND SPRIDEN_CHANGE_IND IS NULL
                                  AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                                      where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                                      and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                                      and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                                      and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                UNION
                    SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                                      FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC
                                      WHERE a.SORLCUR_PIDM =p_pidm -- 29161
                                      AND a.SORLCUR_TERM_CODE =p_term_code
                                      AND a.SORLCUR_LMOD_CODE=  'LEARNER'
                                      AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                      AND a.SORLCUR_ROLL_IND ='Y'
                                      AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                      AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                      AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                                      AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                                      AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                      AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                                      AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                      AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                                      AND SZTCOMD_ENABLE_IND ='Y'
                                      AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                                      AND SPRIDEN_CHANGE_IND IS NULL
                                  AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                                      where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                                      and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                                      and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                                      and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                UNION
                    SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                                      FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC
                                      WHERE a.SORLCUR_PIDM =p_pidm -- 29161
                                      AND a.SORLCUR_TERM_CODE =p_term_code
                                      AND a.SORLCUR_LMOD_CODE=  'LEARNER'
                                      AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                      AND a.SORLCUR_ROLL_IND ='Y'
                                      AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                                      AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                      AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                      AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                                      AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                                      AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                      AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                                      AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                      AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                                      AND SZTCOMD_ENABLE_IND ='Y'
                                      AND SPRIDEN_CHANGE_IND IS NULL
                                      AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                                          where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                                          and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                                          and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                                          and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
              */
                 )LOOP

                        dbms_output.put_line( 'Recupera :'||c.cuenta||'-'||c.pass||'-'||c.nivel||'-'||c.campus||'-'||c.materia_ins||'-'||c.maximo||'-'||c.fecha_ini);

                        --conteo de alumnos inscritos por curso de bienvenida--

                        begin
                           select count(*)
                           into vl_maximo_ins
                           from  sztbnda
                           where SZTBNDA_TERM_NRC = p_term_code
                           and SZTBNDA_CRSE_SUBJ = c.materia_ins;
                        exception
                        when others then
                        vl_maximo_ins:=null;
                        dbms_output.put_line('Error MAximo Inscrito  :'||vl_maximo_ins);
                        end;

                       dbms_output.put_line('MAximo Inscrito  :'||vl_maximo_ins);


                       --cupo m·ximo por curso--

                       begin
                        select SZTCOMD_LIMMIT
                        into vl_maximo
                        from sztcomd
                        where SZTCOMD_GRP_CODE = c.materia_ins
                        and SZTCOMD_LEVL_CODE = c.nivel
                        AND SZTCOMD_CAMP_CODE=c.campus;
                       exception
                        when others then
                        vl_maximo:=null;
                       dbms_output.put_line('materia '|| c.materia_ins||'  nivel  '|| c.nivel||' Error MAximo cupo  :'||vl_maximo);
                       end;

                       dbms_output.put_line('MAximo cupo  :'||vl_maximo);

                       if vl_maximo_ins < vl_maximo then

                       dbms_output.put_line('Tiene cupo el grupo');

                            Begin
                              Select nvl (max (SZTBNDA_SEQ_NO),0)+1
                                Into vl_contador
                                from SZTBNDA
                                where SZTBNDA_TERM_NRC = p_term_code
                                and SZTBNDA_PIDM = p_pidm;
                            Exception
                            When Others then
                            vl_contador :=1;
                            dbms_output.put_line('Error9:'||vl_contador ||' *'||sqlerrm);
                            End;



                            begin
                            Insert into SZTBNDA values (
                                                     p_term_code    --SZTBNDA_TERM_NRC
                                                    ,p_pidm      --SZTBNDA_PIDM
                                                    ,vl_contador     --SZTBNDA_SEQ_NO
                                                    ,c.cuenta      --SZTBNDA_ID
                                                    ,sysdate      --SZTBNDA_ACTIVITY_DATE
                                                    ,user      --SZTBNDA_USER_ID
                                                    ,0      --SZTBNDA_STAT_IND
                                                    ,null      --SZTBNDA_OBS
                                                    ,c.pass      --SZTBNDA_PWD
                                                    ,null      --SZTBNDA_GRP_MDL_ID
                                                    ,c.materia_ins      --SZTBNDA_CRSE_SUBJ
                                                    ,c.nivel --SZTBNDA_LEVL_CODE
                                                    ,c.campus  --SZTBNDA_CAMP_CODE
                                                    ,c.fecha_ini --SZTBNDA_SUBJ_CODE
                                                    ,null --SZTBNDA_MDLE_ID
                                                    );
                            vl_msje :='Exito' ;
                            Exception
                            When Others then
                            vl_msje := 'Error al insertar sztbnda'||sqlerrm;
                            dbms_output.put_line('Error al insertar 1:  '||sqlerrm);
                            end;

                       Elsif  vl_maximo_ins is null  or vl_maximo is null  then

                             Begin
                              Select nvl (max (SZTBNDA_SEQ_NO),0)+1
                                Into vl_contador
                                from SZTBNDA
                                where SZTBNDA_TERM_NRC = p_term_code
                                and SZTBNDA_PIDM = p_pidm;
                            dbms_output.put_line('salida:'||vl_contador);
                            Exception
                                When Others then
                                  vl_contador :=1;
                            dbms_output.put_line('Error91:'||vl_contador ||' *'||sqlerrm);
                            End;

                            begin
                            Insert into SZTBNDA values (
                                                     p_term_code    --SZTBNDA_TERM_NRC
                                                    ,p_pidm      --SZTBNDA_PIDM
                                                    ,vl_contador     --SZTBNDA_SEQ_NO
                                                    ,c.cuenta      --SZTBNDA_ID
                                                    ,sysdate      --SZTBNDA_ACTIVITY_DATE
                                                    ,user      --SZTBNDA_USER_ID
                                                    ,0      --SZTBNDA_STAT_IND
                                                    ,null      --SZTBNDA_OBS
                                                    ,c.pass      --SZTBNDA_PWD
                                                    ,null      --SZTBNDA_GRP_MDL_ID
                                                    ,c.materia_ins      --SZTBNDA_CRSE_SUBJ
                                                    ,c.nivel --SZTBNDA_LEVL_CODE
                                                    ,c.campus  --SZTBNDA_CAMP_CODE
                                                    ,c.fecha_ini --SZTBNDA_SUBJ_CODE
                                                    ,null --SZTBNDA_MDLE_ID
                                                    );
                            vl_msje :='Exito' ;
                            Exception
                            When Others then
                            vl_msje := 'Error al insertar sztbnda'||sqlerrm;
                            dbms_output.put_line('Error al insertar 21:  '||sqlerrm);
                            end;

                       end if;
                  END LOOP;
                commit;

            END;


         ELSIF vl_utlx = 0 and VL_ETIQ_EXPERIENCI= 0 and vl_campuve=0 THEN  --vl_valida_costo > 0

            BEGIN

                FOR c IN(
                      SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                      FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC
                      WHERE a.SORLCUR_PIDM = p_pidm
                      AND a.SORLCUR_TERM_CODE = p_term_code
                      AND a.SORLCUR_LMOD_CODE='ADMISSIONS'
                      AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                      AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                      AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                      AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                      AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                      AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                      AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                      AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                      AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                      AND SZTCOMD_ENABLE_IND ='Y'
                      AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                      AND SPRIDEN_CHANGE_IND IS NULL
                      AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                          where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                          and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                          and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                          and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                UNION
                    SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                                  FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC
                                  WHERE a.SORLCUR_PIDM =p_pidm -- 29161
                                  AND a.SORLCUR_TERM_CODE =p_term_code
                                  AND a.SORLCUR_LMOD_CODE='ADMISSIONS'
                                  AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                  AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                  AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                  AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                                  AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                                  AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                  AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                                  AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                  AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                                  AND SZTCOMD_ENABLE_IND ='Y'
                                  AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                                  AND SPRIDEN_CHANGE_IND IS NULL
                                  AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                                      where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                                      and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                                      and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                                      and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                UNION
                    SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                                      FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC
                                      WHERE a.SORLCUR_PIDM =p_pidm -- 29161
                                      AND a.SORLCUR_TERM_CODE =p_term_code
                                      AND a.SORLCUR_LMOD_CODE=  'LEARNER'
                                      AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                      AND a.SORLCUR_ROLL_IND ='Y'
                                      AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                      AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                      AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                                      AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                                      AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                      AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                                      AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                      AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                                      AND SZTCOMD_ENABLE_IND ='Y'
                                      AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                                      AND SPRIDEN_CHANGE_IND IS NULL
                                  AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                                      where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                                      and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                                      and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                                      and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                UNION
                    SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                                      FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC
                                      WHERE a.SORLCUR_PIDM =p_pidm -- 29161
                                      AND a.SORLCUR_TERM_CODE =p_term_code
                                      AND a.SORLCUR_LMOD_CODE=  'LEARNER'
                                      AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                      AND a.SORLCUR_ROLL_IND ='Y'
                                      AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                                      AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                      AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                      AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                                      AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                                      AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                      AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                                      AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                      AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                                      AND SZTCOMD_ENABLE_IND ='Y'
                                      AND SPRIDEN_CHANGE_IND IS NULL
                                      AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                                          where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                                          and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                                          and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                                          and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                 )LOOP

                        dbms_output.put_line( 'Recupera :'||c.cuenta||'-'||c.pass||'-'||c.nivel||'-'||c.campus||'-'||c.materia_ins||'-'||c.maximo||'-'||c.fecha_ini);

                        --conteo de alumnos inscritos por curso de bienvenida--

                        begin
                           select count(*)
                           into vl_maximo_ins
                           from  sztbnda
                           where SZTBNDA_TERM_NRC = p_term_code
                           and SZTBNDA_CRSE_SUBJ = c.materia_ins;
                            dbms_output.put_line('MAximo Inscrito  :'||vl_maximo_ins);
                        exception
                        when others then
                        vl_maximo_ins:=null;
                        dbms_output.put_line('Error MAximo Inscrito  :'||vl_maximo_ins);
                        end;

                       dbms_output.put_line('MAximo Inscrito  :'||vl_maximo_ins);


                       --cupo m·ximo por curso--

                       begin
                        select SZTCOMD_LIMMIT
                        into vl_maximo
                        from sztcomd
                        where SZTCOMD_GRP_CODE = c.materia_ins
                        and SZTCOMD_LEVL_CODE = c.nivel
                        AND SZTCOMD_CAMP_CODE=c.campus ;
                        dbms_output.put_line('MAximo cupo  :'||vl_maximo);
                       exception
                        when others then
                        vl_maximo:=null;
                        dbms_output.put_line('materia '|| c.materia_ins||'  nivel  '|| c.nivel||' Error MAximo cupo  :'||vl_maximo);
                       end;

                       dbms_output.put_line('MAximo cupo  :'||vl_maximo);

                       if vl_maximo_ins < vl_maximo then

                       dbms_output.put_line('Tiene cupo el grupo');

                            Begin
                              Select nvl (max (SZTBNDA_SEQ_NO),0)+1
                                Into vl_contador
                                from SZTBNDA
                                where SZTBNDA_TERM_NRC = p_term_code
                                and SZTBNDA_PIDM = p_pidm;
                            Exception
                            When Others then
                            vl_contador :=1;
                            dbms_output.put_line('Error9:'||vl_contador ||' *'||sqlerrm);
                            End;



                            begin
                            Insert into SZTBNDA values (
                                                     p_term_code    --SZTBNDA_TERM_NRC
                                                    ,p_pidm      --SZTBNDA_PIDM
                                                    ,vl_contador     --SZTBNDA_SEQ_NO
                                                    ,c.cuenta      --SZTBNDA_ID
                                                    ,sysdate      --SZTBNDA_ACTIVITY_DATE
                                                    ,user      --SZTBNDA_USER_ID
                                                    ,0      --SZTBNDA_STAT_IND
                                                    ,null      --SZTBNDA_OBS
                                                    ,c.pass      --SZTBNDA_PWD
                                                    ,null      --SZTBNDA_GRP_MDL_ID
                                                    ,c.materia_ins      --SZTBNDA_CRSE_SUBJ
                                                    ,c.nivel --SZTBNDA_LEVL_CODE
                                                    ,c.campus  --SZTBNDA_CAMP_CODE
                                                    ,c.fecha_ini --SZTBNDA_SUBJ_CODE
                                                    ,null --SZTBNDA_MDLE_ID
                                                    );
                            vl_msje :='Exito' ;
                            Exception
                            When Others then
                            vl_msje := 'Error al insertar sztbnda'||sqlerrm;
                            dbms_output.put_line('Error al insertar 1:  '||sqlerrm);
                            end;

                       Elsif  vl_maximo_ins is null  or vl_maximo is null  then

                             Begin
                              Select nvl (max (SZTBNDA_SEQ_NO),0)+1
                                Into vl_contador
                                from SZTBNDA
                                where SZTBNDA_TERM_NRC = p_term_code
                                and SZTBNDA_PIDM = p_pidm;
                            dbms_output.put_line('salida:'||vl_contador);
                            Exception
                                When Others then
                                  vl_contador :=1;
                            dbms_output.put_line('Error91:'||vl_contador ||' *'||sqlerrm);
                            End;

                            begin
                            Insert into SZTBNDA values (
                                                     p_term_code    --SZTBNDA_TERM_NRC
                                                    ,p_pidm      --SZTBNDA_PIDM
                                                    ,vl_contador     --SZTBNDA_SEQ_NO
                                                    ,c.cuenta      --SZTBNDA_ID
                                                    ,sysdate      --SZTBNDA_ACTIVITY_DATE
                                                    ,user      --SZTBNDA_USER_ID
                                                    ,0      --SZTBNDA_STAT_IND
                                                    ,null      --SZTBNDA_OBS
                                                    ,c.pass      --SZTBNDA_PWD
                                                    ,null      --SZTBNDA_GRP_MDL_ID
                                                    ,c.materia_ins      --SZTBNDA_CRSE_SUBJ
                                                    ,c.nivel --SZTBNDA_LEVL_CODE
                                                    ,c.campus  --SZTBNDA_CAMP_CODE
                                                    ,c.fecha_ini --SZTBNDA_SUBJ_CODE
                                                    ,null --SZTBNDA_MDLE_ID
                                                    );
                            vl_msje :='Exito' ;
                            Exception
                            When Others then
                            vl_msje := 'Error al insertar sztbnda'||sqlerrm;
                            dbms_output.put_line('Error al insertar 21:  '||sqlerrm);
                            end;

                       end if;
                  END LOOP;
                commit;

            END;

         ELSIF VL_ETIQ_EXPERIENCI= 1 THEN 
         
               BEGIN

                FOR c IN(
                      SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins,SZTCOMD_GRP_MDL_ID GRUPO_ID,SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                      FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC,GORADID b,ZSTPARA
                      WHERE a.SORLCUR_PIDM =p_pidm
                      AND a.SORLCUR_TERM_CODE= p_term_code
                      AND a.SORLCUR_LMOD_CODE='ADMISSIONS'
                      AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                      AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                      AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                      AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                      AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                      and a.SORLCUR_PIDM = GORADID_PIDM (+)
                      AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                      AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                      AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                      AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                      AND SZTCOMD_ENABLE_IND ='Y'
--                      AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                      AND SPRIDEN_CHANGE_IND IS NULL
                      AND b.GORADID_ADID_CODE = ZSTPARA_PARAM_ID
                      AND ZSTPARA_MAPA_ID in ('ETIQ_EXPERIENCI')
                      AND substr(SZTCOMD_CAMP_CODE,1,3)||SZTCOMD_LEVL_CODE=ZSTPARA_PARAM_DESC
                      AND SZTCOMD_GRP_CODE=ZSTPARA_PARAM_VALOR
                      AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                          where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                          and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                          and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                          and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                UNION
                    SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins,SZTCOMD_GRP_MDL_ID GRUPO_ID, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                                  FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC,GORADID b,ZSTPARA
                                  WHERE a.SORLCUR_PIDM =p_pidm 
                                  AND a.SORLCUR_TERM_CODE =p_term_code
                                  AND a.SORLCUR_LMOD_CODE='ADMISSIONS'
                                  AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                  AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                  AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                  AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                                  AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                                  and a.SORLCUR_PIDM = GORADID_PIDM
                                  AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                  AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                                  AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                  AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                                  AND SZTCOMD_ENABLE_IND ='Y'
--                                  AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                                  AND SPRIDEN_CHANGE_IND IS NULL
                                 AND b.GORADID_ADID_CODE = ZSTPARA_PARAM_ID
                                 AND ZSTPARA_MAPA_ID in ('ETIQ_EXPERIENCI')
                                 AND substr(SZTCOMD_CAMP_CODE,1,3)||SZTCOMD_LEVL_CODE=ZSTPARA_PARAM_DESC
                                 AND SZTCOMD_GRP_CODE=ZSTPARA_PARAM_VALOR
                                 AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                                      where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                                      and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                                      and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                                      and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                UNION
                    SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins,SZTCOMD_GRP_MDL_ID GRUPO_ID, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                                      FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC,GORADID b,ZSTPARA
                                      WHERE a.SORLCUR_PIDM =p_pidm
                                      AND a.SORLCUR_TERM_CODE =p_term_code
                                      AND a.SORLCUR_LMOD_CODE=  'LEARNER'
                                      AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                      AND a.SORLCUR_ROLL_IND ='Y'
                                      AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                      AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                      AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                                      AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                                      and a.SORLCUR_PIDM = GORADID_PIDM
                                      AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                      AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                                      AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                      AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                                      AND SZTCOMD_ENABLE_IND ='Y'
--                                      AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                                      AND SPRIDEN_CHANGE_IND IS NULL
                                      AND b.GORADID_ADID_CODE = ZSTPARA_PARAM_ID
                                      AND ZSTPARA_MAPA_ID in ('ETIQ_EXPERIENCI')
                                      AND substr(SZTCOMD_CAMP_CODE,1,3)||SZTCOMD_LEVL_CODE=ZSTPARA_PARAM_DESC
                                      AND SZTCOMD_GRP_CODE=ZSTPARA_PARAM_VALOR
                                      AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                                      where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                                      and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                                      and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                                      and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                UNION
                    SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,  SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins,SZTCOMD_GRP_MDL_ID GRUPO_ID, SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                                      FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC,GORADID b,ZSTPARA
                                      WHERE a.SORLCUR_PIDM =p_pidm 
                                      AND a.SORLCUR_TERM_CODE =p_term_code
                                      AND a.SORLCUR_LMOD_CODE=  'LEARNER'
                                      AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                      AND a.SORLCUR_ROLL_IND ='Y'
--                                      AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
                                      AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                      AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                      AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                                      AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                                      and a.SORLCUR_PIDM = GORADID_PIDM
                                      AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                      AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                                      AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                      AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                                      AND SZTCOMD_ENABLE_IND ='Y'
                                      AND SPRIDEN_CHANGE_IND IS NULL
                                      AND b.GORADID_ADID_CODE = ZSTPARA_PARAM_ID
                                      AND ZSTPARA_MAPA_ID in ('ETIQ_EXPERIENCI')
                                      AND substr(SZTCOMD_CAMP_CODE,1,3)||SZTCOMD_LEVL_CODE=ZSTPARA_PARAM_DESC
                                      AND SZTCOMD_GRP_CODE=ZSTPARA_PARAM_VALOR
                                      AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                                          where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                                          and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                                          and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                                          and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                 )LOOP

                        dbms_output.put_line( 'Recupera :'||c.cuenta||'-'||c.pass||'-'||c.nivel||'-'||c.campus||'-'||c.materia_ins||'-'||c.maximo||'-'||c.fecha_ini);

                        --conteo de alumnos inscritos por curso de bienvenida--

                        begin
                           select count(*)
                           into vl_maximo_ins
                           from  sztbnda
                           where SZTBNDA_TERM_NRC = p_term_code
                           and SZTBNDA_CRSE_SUBJ = c.materia_ins;
                            dbms_output.put_line('MAximo Inscrito  :'||vl_maximo_ins);
                        exception
                        when others then
                        vl_maximo_ins:=null;
                        dbms_output.put_line('Error MAximo Inscrito  :'||vl_maximo_ins);
                        end;

                       dbms_output.put_line('MAximo Inscrito  :'||vl_maximo_ins);


                       --cupo m·ximo por curso--

                       begin
                        select SZTCOMD_LIMMIT
                        into vl_maximo
                        from sztcomd
                        where SZTCOMD_GRP_CODE = c.materia_ins
                        and SZTCOMD_LEVL_CODE = c.nivel
                        AND SZTCOMD_CAMP_CODE=c.campus ;
                        dbms_output.put_line('MAximo cupo  :'||vl_maximo);
                       exception
                        when others then
                        vl_maximo:=null;
                        dbms_output.put_line('materia '|| c.materia_ins||'  nivel  '|| c.nivel||' Error MAximo cupo  :'||vl_maximo);
                       end;

                       dbms_output.put_line('MAximo cupo  :'||vl_maximo);

                       if vl_maximo_ins < vl_maximo then

                       dbms_output.put_line('Tiene cupo el grupo');

                            Begin
                              Select nvl (max (SZTBNDA_SEQ_NO),0)+1
                                Into vl_contador
                                from SZTBNDA
                                where SZTBNDA_TERM_NRC = p_term_code
                                and SZTBNDA_PIDM = p_pidm;
                            Exception
                            When Others then
                            vl_contador :=1;
                            dbms_output.put_line('Error9:'||vl_contador ||' *'||sqlerrm);
                            End;



                            begin
                            Insert into SZTBNDA values (
                                                     p_term_code    --SZTBNDA_TERM_NRC
                                                    ,p_pidm      --SZTBNDA_PIDM
                                                    ,vl_contador     --SZTBNDA_SEQ_NO
                                                    ,c.cuenta      --SZTBNDA_ID
                                                    ,sysdate      --SZTBNDA_ACTIVITY_DATE
                                                    ,user      --SZTBNDA_USER_ID
                                                    ,0      --SZTBNDA_STAT_IND
                                                    ,null      --SZTBNDA_OBS
                                                    ,c.pass      --SZTBNDA_PWD
                                                    ,C.GRUPO_ID      --SZTBNDA_GRP_MDL_ID
                                                    ,c.materia_ins      --SZTBNDA_CRSE_SUBJ
                                                    ,c.nivel --SZTBNDA_LEVL_CODE
                                                    ,c.campus  --SZTBNDA_CAMP_CODE
                                                    ,c.fecha_ini --SZTBNDA_SUBJ_CODE
                                                    ,null --SZTBNDA_MDLE_ID
                                                    );
                            vl_msje :='Exito' ;
                            Exception
                            When Others then
                            vl_msje := 'Error al insertar sztbnda'||sqlerrm;
                            dbms_output.put_line('Error al insertar 1:  '||sqlerrm);
                            end;

                       Elsif  vl_maximo_ins is null  or vl_maximo is null  then

                             Begin
                              Select nvl (max (SZTBNDA_SEQ_NO),0)+1
                                Into vl_contador
                                from SZTBNDA
                                where SZTBNDA_TERM_NRC = p_term_code
                                and SZTBNDA_PIDM = p_pidm;
                            dbms_output.put_line('salida:'||vl_contador);
                            Exception
                                When Others then
                                  vl_contador :=1;
                            dbms_output.put_line('Error91:'||vl_contador ||' *'||sqlerrm);
                            End;

                            begin
                            Insert into SZTBNDA values (
                                                     p_term_code    --SZTBNDA_TERM_NRC
                                                    ,p_pidm      --SZTBNDA_PIDM
                                                    ,vl_contador     --SZTBNDA_SEQ_NO
                                                    ,c.cuenta      --SZTBNDA_ID
                                                    ,sysdate      --SZTBNDA_ACTIVITY_DATE
                                                    ,user      --SZTBNDA_USER_ID
                                                    ,0      --SZTBNDA_STAT_IND
                                                    ,null      --SZTBNDA_OBS
                                                    ,c.pass      --SZTBNDA_PWD
                                                    ,C.GRUPO_ID     --SZTBNDA_GRP_MDL_ID
                                                    ,c.materia_ins      --SZTBNDA_CRSE_SUBJ
                                                    ,c.nivel --SZTBNDA_LEVL_CODE
                                                    ,c.campus  --SZTBNDA_CAMP_CODE
                                                    ,c.fecha_ini --SZTBNDA_SUBJ_CODE
                                                    ,null --SZTBNDA_MDLE_ID
                                                    );
                            vl_msje :='Exito' ;
                            Exception
                            When Others then
                            vl_msje := 'Error al insertar sztbnda'||sqlerrm;
                            dbms_output.put_line('Error al insertar 21:  '||sqlerrm);
                            end;

                       end if;
                  END LOOP;
                commit;

            END;
            
         ELSIF vl_campuve>=1 then
         
            BEGIN

                FOR c IN(
                        SELECT DISTINCT SPRIDEN_ID cuenta, GOZTPAC_PIN pass, SORLCUR_LEVL_CODE nivel,SORLCUR_CAMP_CODE campus, SZTCOMD_GRP_CODE materia_ins,SZTCOMD_GRP_MDL_ID GRUPO_ID,SZTCOMD_LIMMIT maximo, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_ini
                      FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC
                      WHERE  1=1
                      and a.SORLCUR_PIDM =p_pidm--620923
                      AND a.SORLCUR_TERM_CODE=p_term_code --'102342'
                      AND a.SORLCUR_LMOD_CODE='ADMISSIONS'
                      AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                      AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                      AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                      AND a.SORLCUR_PIDM = SPRIDEN_PIDM
                      AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
                      AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                      AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
                      AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
                      AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
                      AND SZTCOMD_ENABLE_IND ='Y'
                      AND SPRIDEN_CHANGE_IND IS NULL
                      AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO) FROM SORLCUR b
                                          where  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                                          and a.SORLCUR_TERM_CODE= b.SORLCUR_TERM_CODE
                                          and a.SORLCUR_LMOD_CODE= b.SORLCUR_LMOD_CODE
                                          and a.SORLCUR_CACT_CODE= b.SORLCUR_CACT_CODE)
                 )LOOP

                        dbms_output.put_line( 'Recupera :'||c.cuenta||'-'||c.pass||'-'||c.nivel||'-'||c.campus||'-'||c.materia_ins||'-'||c.maximo||'-'||c.fecha_ini);

                        --conteo de alumnos inscritos por curso de bienvenida--

                        begin
                           select count(*)
                           into vl_maximo_ins
                           from  sztbnda
                           where SZTBNDA_TERM_NRC = p_term_code
                           and SZTBNDA_CRSE_SUBJ = c.materia_ins;
                            dbms_output.put_line('MAximo Inscrito  :'||vl_maximo_ins);
                        exception
                        when others then
                        vl_maximo_ins:=null;
                        dbms_output.put_line('Error MAximo Inscrito  :'||vl_maximo_ins);
                        end;

                       dbms_output.put_line('MAximo Inscrito  :'||vl_maximo_ins);


                       --cupo m·ximo por curso--

                       begin
                        select SZTCOMD_LIMMIT
                        into vl_maximo
                        from sztcomd
                        where SZTCOMD_GRP_CODE = c.materia_ins
                        and SZTCOMD_LEVL_CODE = c.nivel
                        AND SZTCOMD_CAMP_CODE=c.campus ;
                        dbms_output.put_line('MAximo cupo  :'||vl_maximo);
                       exception
                        when others then
                        vl_maximo:=null;
                        dbms_output.put_line('materia '|| c.materia_ins||'  nivel  '|| c.nivel||' Error MAximo cupo  :'||vl_maximo);
                       end;

                       dbms_output.put_line('MAximo cupo  :'||vl_maximo);

                       if vl_maximo_ins < vl_maximo then

                       dbms_output.put_line('Tiene cupo el grupo');

                            Begin
                              Select nvl (max (SZTBNDA_SEQ_NO),0)+1
                                Into vl_contador
                                from SZTBNDA
                                where SZTBNDA_TERM_NRC = p_term_code
                                and SZTBNDA_PIDM = p_pidm;
                            Exception
                            When Others then
                            vl_contador :=1;
                            dbms_output.put_line('Error9:'||vl_contador ||' *'||sqlerrm);
                            End;



                            begin
                            Insert into SZTBNDA values (
                                                     p_term_code    --SZTBNDA_TERM_NRC
                                                    ,p_pidm      --SZTBNDA_PIDM
                                                    ,vl_contador     --SZTBNDA_SEQ_NO
                                                    ,c.cuenta      --SZTBNDA_ID
                                                    ,sysdate      --SZTBNDA_ACTIVITY_DATE
                                                    ,user      --SZTBNDA_USER_ID
                                                    ,0      --SZTBNDA_STAT_IND
                                                    ,null      --SZTBNDA_OBS
                                                    ,c.pass      --SZTBNDA_PWD
                                                    ,C.GRUPO_ID      --SZTBNDA_GRP_MDL_ID
                                                    ,c.materia_ins      --SZTBNDA_CRSE_SUBJ
                                                    ,c.nivel --SZTBNDA_LEVL_CODE
                                                    ,c.campus  --SZTBNDA_CAMP_CODE
                                                    ,c.fecha_ini --SZTBNDA_SUBJ_CODE
                                                    ,null --SZTBNDA_MDLE_ID
                                                    );
                            vl_msje :='Exito' ;
                            Exception
                            When Others then
                            vl_msje := 'Error al insertar sztbnda'||sqlerrm;
                            dbms_output.put_line('Error al insertar 1:  '||sqlerrm);
                            end;

                       Elsif  vl_maximo_ins is null  or vl_maximo is null  then

                             Begin
                              Select nvl (max (SZTBNDA_SEQ_NO),0)+1
                                Into vl_contador
                                from SZTBNDA
                                where SZTBNDA_TERM_NRC = p_term_code
                                and SZTBNDA_PIDM = p_pidm;
                            dbms_output.put_line('salida:'||vl_contador);
                            Exception
                                When Others then
                                  vl_contador :=1;
                            dbms_output.put_line('Error91:'||vl_contador ||' *'||sqlerrm);
                            End;

                            begin
                            Insert into SZTBNDA values (
                                                     p_term_code    --SZTBNDA_TERM_NRC
                                                    ,p_pidm      --SZTBNDA_PIDM
                                                    ,vl_contador     --SZTBNDA_SEQ_NO
                                                    ,c.cuenta      --SZTBNDA_ID
                                                    ,sysdate      --SZTBNDA_ACTIVITY_DATE
                                                    ,user      --SZTBNDA_USER_ID
                                                    ,0      --SZTBNDA_STAT_IND
                                                    ,null      --SZTBNDA_OBS
                                                    ,c.pass      --SZTBNDA_PWD
                                                    ,C.GRUPO_ID     --SZTBNDA_GRP_MDL_ID
                                                    ,c.materia_ins      --SZTBNDA_CRSE_SUBJ
                                                    ,c.nivel --SZTBNDA_LEVL_CODE
                                                    ,c.campus  --SZTBNDA_CAMP_CODE
                                                    ,c.fecha_ini --SZTBNDA_SUBJ_CODE
                                                    ,null --SZTBNDA_MDLE_ID
                                                    );
                            vl_msje :='Exito' ;
                            Exception
                            When Others then
                            vl_msje := 'Error al insertar sztbnda'||sqlerrm;
                            dbms_output.put_line('Error al insertar 21:  '||sqlerrm);
                            end;

                       end if;
                  END LOOP;
                commit;

            END;
            
                   
         END IF;
       
       END;

        BEGIN
           --------------------------------------------------------------------------------------------------
           --- Proceso para poblar tabla intermedia para los nuevos estatus y tipo de alumno ---
           --------------------------------------------------------------------------------------------------
            for c in (Select SORLCUR_PIDM pidm, SORLCUR_TERM_CODE periodo, SORLCUR_PROGRAM programa,
                        trunc (SORLCUR_START_DATE) fecha_ini,
                        last_Day(TO_DATE(SYSDATE,'DD/MM/RRRR')) Fec_mes
                        from sorlcur a
                        where a.SORLCUR_PIDM = p_pidm
                        and  a.SORLCUR_TERM_CODE = p_term_code
                    --    and a.SORLCUR_KEY_SEQNO = p_appl_no
                        And a.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                        and a.SORLCUR_CACT_CODE = 'ACTIVE'
                        and a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
                                                        from SORLCUR a1
                                                        where a.SORLCUR_PIDM = a1.SORLCUR_PIDM
                                                        and a.SORLCUR_TERM_CODE = a1.SORLCUR_TERM_CODE
                                                        and a.SORLCUR_KEY_SEQNO = a1.SORLCUR_KEY_SEQNO
                                                        and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE
                                                        and a.SORLCUR_CACT_CODE = a1.SORLCUR_CACT_CODE)
                    ) loop

                             Begin
                                Select a.SARADAP_STYP_CODE
                                Into vl_type
                                from saradap a
                                Where a.SARADAP_PIDM = p_pidm
                                And a.SARADAP_TERM_CODE_ENTRY = p_term_code
                                ANd a.SARADAP_APPL_NO = (Select max (a1.SARADAP_APPL_NO)
                                                                            from SARADAP a1
                                                                            Where a.SARADAP_PIDM = a1.SARADAP_PIDM
                                                                            And a.SARADAP_TERM_CODE_ENTRY = a1.SARADAP_TERM_CODE_ENTRY
                                                                            );
                             Exception
                                When  Others then
                                 vl_type := null;
                             End;



                             If  c.fecha_ini <=  c.Fec_mes and vl_type = 'N' then

                                    Begin
                                        Update sgbstdn
                                        set SGBSTDN_STST_CODE = 'MA',SGBSTDN_STYP_CODE = 'N'
                                        Where sgbstdn_pidm = c.pidm
                                        And sgbstdn_term_code_eff = c.periodo
                                        and sgbstdn_program_1 = c.programa;
                                    Exception
                                        When others then
                                        null;
                                    End;
                             Elsif vl_type = 'R' then
                                    Begin
                                        Update sgbstdn
                                        set SGBSTDN_STST_CODE = 'MA',SGBSTDN_STYP_CODE = 'R'
                                        Where sgbstdn_pidm = c.pidm
                                        And sgbstdn_term_code_eff = c.periodo
                                        and sgbstdn_program_1 = c.programa;
                                    Exception
                                        When others then
                                        null;
                                    End;
                             ElsIf  c.fecha_ini >  c.Fec_mes and vl_type = 'N' then

                                    Begin
                                        Update sgbstdn
                                        set SGBSTDN_STST_CODE = 'MA', SGBSTDN_STYP_CODE = 'F'
                                        Where sgbstdn_pidm = c.pidm
                                        And sgbstdn_term_code_eff = c.periodo
                                        and sgbstdn_program_1 = c.programa;
                                    Exception
                                        When others then
                                        null;
                                    End;

                             Else
                                    Begin
                                        Update sgbstdn
                                        set SGBSTDN_STST_CODE = 'MA', SGBSTDN_STYP_CODE = 'N'
                                        Where sgbstdn_pidm = c.pidm
                                        And sgbstdn_term_code_eff = c.periodo
                                        and sgbstdn_program_1 = c.programa;
                                    Exception
                                        When others then
                                        null;
                                    End;
                             End if;

                    End loop;
                    Commit;
        Exception when others then
        vl_msje := 'Error general'||sqlerrm;
        END;
   END p_inserta_sztbnda;
--

 FUNCTION f_grupos_ni (p_inicio_clase in varchar2,  p_regla in number) return varchar2
    as

        l_retorna        varchar2(1000);
        l_contar         NUMBER;
        l_conse          NUMBER;
        l_materia        VARCHAR2(15);
        l_desripcion_mat VARCHAR2(500);
        l_campus         VARCHAR2(15);
        l_nivel          VARCHAR2(15);
        l_parte_perido   VARCHAR2(15);
        l_term_code      VARCHAR2(15);
        l_regla_cerrada  VARCHAR2(1);
        l_short_name     VARCHAR2(250);
        l_grupo_moodl    VARCHAR2(15);
        l_maximo         VARCHAR2(15);
        l_pwd            VARCHAR2(100);

    BEGIN

        FOR C IN
            (
            select materia,
                   pidm,
                   matricula,
                   maximo,
                   CASE WHEN length(grupo)=2 THEN
                    grupo
                        WHEN length(grupo)=1 THEN
                    to_char('0'||grupo)
                   END GRUPO,
                   regla,
                   secuencia
            from
            (
                SELECT sztconf_subj_code materia,
                       sztconf_pidm pidm,
                       sztconf_id matricula,
                       70 maximo,
                       to_char(SZTCONF_GROUP) grupo,
                       sztconf_no_regla  regla,
                       SZTCONF_SECUENCIA secuencia
                FROM sztconf
                WHERE 1 = 1
                AND sztconf_no_regla = p_regla
                AND SZTCONF_ESTATUS_CERRADO ='N'
                ORDER BY 1,4 DESC
                )
            WHERE 1 = 1
            )
            LOOP

                BEGIN
                    SELECT UPPER(scrsyln_long_course_title)
                    INTO l_desripcion_mat
                    FROM scrsyln
                    WHERE 1 = 1
                    AND scrsyln_subj_code||scrsyln_crse_numb =c.materia;

                EXCEPTION WHEN OTHERS THEN
                    --dbms_output.put_line(' Error en SCRSYLN '||SQLERRM);
                    l_retorna:=' No se econtro descripcion para materia  '||c.materia||' '||sqlerrm;

                END;


                SELECT COUNT(*)
                INTO l_maximo
                FROM sztgpme
                WHERE 1 = 1
                AND SZTGPME_SUBJ_CRSE = c.materia
                and SZTGPME_NO_REGLA =c.regla;

                SELECT CASE WHEN length(l_maximo)=2 THEN
                        l_maximo
                            WHEN length(l_maximo)=1 THEN
                        to_char('0'||l_maximo)
                        END GRUPO
                INTO l_grupo_moodl
                FROM DUAL;

                BEGIN

                   SELECT DISTINCT sztalgo_camp_code,
                                    sztalgo_levl_code
                    INTO l_campus,
                         l_nivel
                    FROM sztalgo
                    WHERE 1 = 1
                    AND sztalgo_no_regla  = p_regla
                    AND ROWNUM = 1;

                    IF l_campus ='UTS' THEN

                        l_campus:='UTL';

                    END IF;

                    IF l_nivel ='MS' THEN

                        l_nivel:='MA';

                    END IF;

                    IF l_nivel ='LI' THEN

                        l_nivel:='LI';

                    END IF;

                EXCEPTION WHEN OTHERS THEN
                     NULL;
                END;

                BEGIN

                       SELECT DISTINCT sztalgo_ptrm_code_new,
                                       sztalgo_term_code_new
                       INTO l_parte_perido,
                            l_term_code
                       FROM sztalgo
                       WHERE 1 = 1
                       AND sztalgo_no_regla = p_regla
                       AND sztalgo_camp_code = l_campus
                       AND sztalgo_levl_code = l_nivel;

                EXCEPTION WHEN OTHERS THEN
                   --DBMS_OUTPUT.PUT_LINE(' Error en sztgpme '||SQLERRM);
                   l_retorna:=' Error en obtener parte de periodo en  sztgpme '||sqlerrm;
                END;

                begin
                        select     concat(concat(concat(
                                      case
                                      when substr (l_parte_perido,1,2) IN ('M0', 'M1', 'M2','A0','A1','A2') then 'S'
                                      when substr (l_parte_perido,1,2) IN('M3', 'A3') then 'M'
                                      when substr  (l_parte_perido, 1,2) in ('L1', 'L0') then 'A'
                                      when substr  (l_parte_perido, 1,2) = 'L2' then 'B'
                                      when substr  (l_parte_perido, 1,2) not in ('M0', 'M1','M2', 'M3','A0','A1','A2','A3','L0', 'L1', 'L2')  then 'B'
                                      end,
                                      case
                                          when substr (l_term_code, 5,2) = '41' then  'A'
                                          when substr (l_term_code, 5,2) = '42' then 'B'
                                          when substr (l_term_code, 5,2) = '43' then 'C'
                                      end ||'0'||substr(l_term_code,3,2) ||'_'),
                                      case
                                          when substr (l_parte_perido,2,2) IN ('3A', '3B', '3C','0A','0B','0C','0D') then '0'
                                          when substr (l_parte_perido,2,2) IN ( '1A', '2A', '1B', '1C','1D', '1E', '3D')  then '1'
                                          end ||'_'), TO_CHAR(to_DATE(p_inicio_clase,'dd/mm/YYYY'),'DDMM')||'_' || c.materia
                                  )  short_name
                        into l_short_name
                        from dual;
                 EXCEPTION WHEN OTHERS THEN
                    --dbms_output.put_line(' Error en sztgpme '||SQLERRM);
                    l_retorna:=' Error en sztgpme '||sqlerrm;
                END;

                BEGIN
                       INSERT INTO sztgpme VALUES(
                                                      c.materia||l_grupo_moodl,
                                                      c.materia,
                                                      l_desripcion_mat,
                                                      5,
                                                      NULL,
                                                      USER,
                                                      SYSDATE,
                                                      l_parte_perido,
                                                      p_inicio_clase,
                                                      NULL,
                                                      c.maximo,
                                                      l_nivel ,
                                                      l_campus,
                                                      NULL,
                                                      c.materia,
                                                      NULL,
                                                      l_term_code ,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      l_short_name,
                                                      p_regla,
                                                      c.secuencia,
                                                      null,
                                                      'S',
                                                      1, null
                                                      );

                    l_retorna:='EXITO';

                EXCEPTION WHEN OTHERS THEN
                   -- dbms_output.put_line(' Error en sztgpme '||SQLERRM);
                    l_retorna:=' Error en sztgpme '||sqlerrm;
                END;

                BEGIN

                    select GOZTPAC_PIN
                    into l_pwd
                    from GOZTPAC pac
                    where 1 = 1
                    and pac.GOZTPAC_pidm =c.pidm;

                EXCEPTION WHEN OTHERS THEN
                    NULL;
                END;

                BEGIN
                       INSERT INTO SZSGNME VALUES(
                                                      c.materia||l_grupo_moodl,
                                                      c.pidm,
                                                      SYSDATE,
                                                      USER,
                                                      5,
                                                      NULL,
                                                      l_pwd,
                                                      null,
                                                      'ACT',
                                                      l_grupo_moodl,
                                                      null,
                                                      l_parte_perido,
                                                      p_inicio_clase,
                                                      c.regla,
                                                      c.secuencia,
                                                      1, null
                                                      );

                    l_retorna:='EXITO';

                EXCEPTION WHEN OTHERS THEN
                    --dbms_output.put_line(' Error en sztgpme '||SQLERRM);
                    l_retorna:=' Error en sztgpme '||sqlerrm;
                END;



                IF l_retorna ='EXITO' then

                    BEGIN

                        UPDATE SZTCONF  SET SZTCONF_ESTATUS_CERRADO ='S'
                        WHERE 1 = 1
                        AND SZTCONF_SUBJ_CODE =c.materia
                        AND SZTCONF_NO_REGLA = c.regla
                        AND SZTCONF_GROUP = l_maximo;


                         l_retorna:='EXITO';

                    EXCEPTION WHEN OTHERS THEN
                        --dbms_output.put_line(' Erroral actualizar  sztgpme '||SQLERRM);
                        l_retorna:=' Error en sztgpme '||sqlerrm;
                    END;

                end if;


            END LOOP;

            IF l_retorna ='EXITO' then

                COMMIT;
            else
                rollback;

            end if;
    EXCEPTION WHEN OTHERS THEN
    l_retorna := 'Error general f_grupos_ni'||sqlerrm;

    return l_retorna;
    END;


 Procedure bienvenida_barrida as



Begin

            for c in (

            select distinct a.SARAPPD_PIDM pidm , a.SARAPPD_TERM_CODE_ENTRY term , a.SARAPPD_APPL_NO ppl, b.spriden_id, a.SARAPPD_APDC_DATE
            from sarappd a, spriden b
            where 1 = 1
            and a.sarappd_pidm = b.spriden_pidm
            and b.spriden_change_ind is null
            and trunc (a.SARAPPD_ACTIVITY_DATE) >= trunc (sysdate) -4
            and a.SARAPPD_APDC_CODE = '35'
            and a.SARAPPD_USER != 'MIGRA_D'
            And a.SARAPPD_SEQ_NO = (select max (a1.SARAPPD_SEQ_NO)
                                                                         from sarappd a1
                                                                         Where a.SARAPPD_PIDM = a1.SARAPPD_PIDM
                                                                         And a.SARAPPD_TERM_CODE_ENTRY = a1.SARAPPD_TERM_CODE_ENTRY
                                                                         And a.SARAPPD_APPL_NO = a1.SARAPPD_APPL_NO)
            --and SARAPPD_PIDM = 38768
            and a.sarappd_pidm not in (select   SZTBNDA_PIDM      from   sztbnda)

            ) loop


            PKG_MOODLE2.p_inserta_sztbnda (c.pidm, c.term, c.ppl);
            commit;


            End loop;
commit;
End bienvenida_barrida;



procedure p_insert_alumnos_barrida (p_term_nrc in varchar2, p_pidm in number, p_id in varchar2,  p_pass in varchar2, p_rsts in varchar2, p_mat_padre in varchar2,  p_levl_code in varchar2, p_ptrm in varchar2, p_camp_code in varchar2,
                                                       p_fecha_inicio in date, p_no_regla in number )


    AS
--     --p_periodo varchar2(250);
--     vl_fecha date;
--     vl_password varchar2(250);
--     vl_matricula varchar2(9);
    vl_secuencia number;
--     vl_seq_pobi number :=0;j
--     vl_nivel varchar(4);
--     vl_campus varchar(3);
--     vl_ptrm varchar(3);
--     vl_error varchar2(250) := 'Exito';
--     vl_maximo number:=0;
--     vl_existe number:=0;
--     vl_crn varchar2 (5);
--     vl_mat_comun varchar2 (15);
--     vl_materia varchar2 (15);
--     vl_materia_comp varchar2(15);
     --p_valor_paso varchar2(25);
--     p_materia    varchar2(12);
--     vmensaje     varchar2(2000);
--     vmin_grupo   varchar2(14);
--    vmax_enroll   number:=0;
--    vmin_enroll   number:=0;
--    vcupo_enroll  number:=0;
--    vterm_cnr     varchar2(14);
--    NO_REGS       NUMBER:=0;
--    vl_MDL_ID     NUMBER;
--    VSTAR_DATE    VARCHAR2(14);
--    VNUM_REGLA    NUMBER;
--    V_RSTS        VARCHAR2(3);
--    vmate_padre   varchar2(14);
--    V_SEQ_NUM     VARCHAR2(3);
--    TAM_SEQ_NUM   NUMBER;
--    vl_fecha_inicio  date;
--    vl_sfrstcr varchar2(2);


    BEGIN


            IF  p_mat_padre IS NOT NULL AND p_no_regla IS NOT NULL THEN


                          Begin
                            Select nvl (max(SZSTUME_SEQ_NO), 0)+1 secuencia
                            Into vl_secuencia
                            from SZSTUME
                            Where SZSTUME_PIDM = p_pidm
                            AND SZSTUME_SUBJ_CODE = p_mat_padre
                            AND SZSTUME_NO_REGLA = p_no_regla;
                          Exception
                          When Others then
                          vl_secuencia :=1;
                          End;


                         BEGIN
                          INSERT INTO SZSTUME  ( SZSTUME_TERM_NRC,
                            SZSTUME_PIDM,
                            SZSTUME_ID,
                            SZSTUME_ACTIVITY_DATE,
                            SZSTUME_USER_ID,
                            SZSTUME_STAT_IND,
                            SZSTUME_OBS,
                            SZSTUME_PWD,
                            SZSTUME_MDLE_ID,
                            SZSTUME_SEQ_NO,
                            SZSTUME_RSTS_CODE,
                            SZSTUME_SUBJ_CODE,
                            SZSTUME_SUBJ_CODE_COMP,
                            SZSTUME_START_DATE,
                            SZSTUME_NO_REGLA)
                            VALUES (
                            p_term_nrc, ---SZSTUME_TERM_NRC,
                            p_pidm,
                            p_id, --SZSTUME_ID,
                            SYSDATE, --SZSTUME_ACTIVITY_DATE,
                            USER, --SZSTUME_USER_ID,
                            5, --SZSTUME_STAT_IND, --SE SIEMBRA EL VALOR CERO POR DEFAULT
                            NULL, --SZSTUME_OBS,
                            p_pass, --SZSTUME_PWD,
                            Null, --SZSTUME_MDLE_ID,
                            vl_secuencia,    ---secuencia
                            p_rsts,---- ESTSTUS DE ALTA
                            p_mat_padre,--p_materia, --SZSTUME_SUBJ_CODE,
                            p_mat_padre, --p_materia, --SZSTUME_SUBJ_CODE_COMP,
                            p_fecha_inicio, --SZSTUME_START_DATE,
                            p_no_regla --SZSTUME_NO_REGLA
                            );
                              --dbms_output.put_line('nO reGS INSERTADOS:: '||NO_REGS ) ;
                           --dbms_output.put_line(vmensaje);
                           -- raise_application_error (-20002,'ERror en el insert szstume INSERTING  '||vmate_padre||'--'||vl_crn||'--'||p_periodo||'--'|| sqlerrm);
                           END;

             END IF;
END p_insert_alumnos_barrida;



procedure p_update_alumnos_barrida (p_term_nrc in varchar2, p_pidm in number, p_id in varchar2,  p_pass in varchar2, p_rsts in varchar2, p_mat_padre in varchar2,  p_levl_code in varchar2, p_ptrm in varchar2, p_camp_code in varchar2,
                                                       p_fecha_inicio in date, p_no_regla in number )
   as
   vl_max number:=0;
   vl_secuencia number;
   vl_rsts_code varchar2 (2);
   vl_id_moodle varchar2(20);

    BEGIN


         BEGIN
            Select nvl (max(a.SZSTUME_SEQ_NO), a.SZSTUME_SEQ_NO) secuencia, a.SZSTUME_RSTS_CODE, a.SZSTUME_MDLE_ID
            Into vl_max, vl_rsts_code, vl_id_moodle
            from SZSTUME a
            Where a.SZSTUME_PIDM = p_pidm
            AND a.SZSTUME_SUBJ_CODE = p_mat_padre
            AND a.SZSTUME_NO_REGLA = p_no_regla
            AND a.SZSTUME_SEQ_NO = (select max(b.SZSTUME_SEQ_NO) from SZSTUME b
                                                    where a.szstume_pidm = b.szstume_pidm
                                                    and A.SZSTUME_NO_REGLA = b.SZSTUME_NO_REGLA)
            group by SZSTUME_SEQ_NO, SZSTUME_RSTS_CODE, SZSTUME_MDLE_ID;
         END;


        Begin
            Select nvl (max(SZSTUME_SEQ_NO), 0)+1 secuencia
            Into vl_secuencia
            from SZSTUME
            Where SZSTUME_PIDM = p_pidm
            AND SZSTUME_SUBJ_CODE = p_mat_padre
            AND SZSTUME_NO_REGLA = p_no_regla;
        Exception
        When Others then
        vl_secuencia :=1;
        End;

          If vl_rsts_code = 'RE'  AND p_rsts = 'DD' then

                --                BEGIN
                --                    update SZSTUME SET SZSTUME_STAT_IND = 0
                --                    WHERE SZSTUME_PIDM = p_pidm
                --                    and SZSTUME_SUBJ_CODE = p_mat_padre
                --                    and SZSTUME_SEQ_NO = vl_max
                --                    and SZSTUME_NO_REGLA = p_no_regla;
                --                END;


                 BEGIN
                   INSERT INTO SZSTUME  ( SZSTUME_TERM_NRC,
                                SZSTUME_PIDM,
                                SZSTUME_ID,
                                SZSTUME_ACTIVITY_DATE,
                                SZSTUME_USER_ID,
                                SZSTUME_STAT_IND,
                                SZSTUME_OBS,
                                SZSTUME_PWD,
                                SZSTUME_MDLE_ID,
                                SZSTUME_SEQ_NO,
                                SZSTUME_RSTS_CODE,
                                SZSTUME_SUBJ_CODE,
                                SZSTUME_SUBJ_CODE_COMP,
                                SZSTUME_START_DATE,
                                SZSTUME_NO_REGLA)
                                VALUES (
                                p_term_nrc, ---SZSTUME_TERM_NRC,
                                p_pidm,
                                p_id, --SZSTUME_ID,
                                SYSDATE, --SZSTUME_ACTIVITY_DATE,
                                USER, --SZSTUME_USER_ID,
                                5, --SZSTUME_STAT_IND, --SE SIEMBRA EL VALOR CERO POR DEFAULT
                                NULL, --SZSTUME_OBS,
                                p_pass, --SZSTUME_PWD,
                                vl_id_moodle, --SZSTUME_MDLE_ID,
                                vl_secuencia,    ---secuencia
                                p_rsts,---- ESTSTUS DE ALTA
                                p_mat_padre,--p_materia, --SZSTUME_SUBJ_CODE,
                                p_mat_padre, --p_materia, --SZSTUME_SUBJ_CODE_COMP,
                                p_fecha_inicio, --SZSTUME_START_DATE,
                                p_no_regla --SZSTUME_NO_REGLA
                                );
                    END;
                    commit;

          ELSIF vl_rsts_code = 'DD'  AND p_rsts = 'RE' then

            --                 BEGIN
            --
            --                                update SZSTUME SET SZSTUME_RSTS_CODE = p_rsts
            --                                WHERE SZSTUME_PIDM = p_pidm
            --                                and SZSTUME_SUBJ_CODE = p_mat_padre
            --                                and SZSTUME_SEQ_NO = vl_max
            --                                and SZSTUME_NO_REGLA = p_no_regla;
            --
            --                END;

                BEGIN
                    INSERT INTO SZSTUME  ( SZSTUME_TERM_NRC,
                                SZSTUME_PIDM,
                                SZSTUME_ID,
                                SZSTUME_ACTIVITY_DATE,
                                SZSTUME_USER_ID,
                                SZSTUME_STAT_IND,
                                SZSTUME_OBS,
                                SZSTUME_PWD,
                                SZSTUME_MDLE_ID,
                                SZSTUME_SEQ_NO,
                                SZSTUME_RSTS_CODE,
                                SZSTUME_SUBJ_CODE,
                                SZSTUME_SUBJ_CODE_COMP,
                                SZSTUME_START_DATE,
                                SZSTUME_NO_REGLA)
                                VALUES (
                                p_term_nrc, ---SZSTUME_TERM_NRC,
                                p_pidm,
                                p_id, --SZSTUME_ID,
                                SYSDATE, --SZSTUME_ACTIVITY_DATE,
                                USER, --SZSTUME_USER_ID,
                                5, --SZSTUME_STAT_IND, --SE SIEMBRA EL VALOR CERO POR DEFAULT
                                NULL, --SZSTUME_OBS,
                                p_pass, --SZSTUME_PWD,
                                vl_id_moodle, --SZSTUME_MDLE_ID,
                                vl_secuencia,    ---secuencia
                                p_rsts,---- ESTSTUS DE ALTA
                                p_mat_padre,--p_materia, --SZSTUME_SUBJ_CODE,
                                p_mat_padre, --p_materia, --SZSTUME_SUBJ_CODE_COMP,
                                p_fecha_inicio, --SZSTUME_START_DATE,
                                p_no_regla --SZSTUME_NO_REGLA
                                );
                END;
             commit;
           END IF;
     COMMIT;



  END p_update_alumnos_barrida;

  FUNCTION f_grade_out
      RETURN PKG_MOODLE2.cursor_grade_out
   AS
      grade_out   PKG_MOODLE2.cursor_grade_out;
   BEGIN
      OPEN grade_out FOR
           SELECT SZSTUME_TERM_NRC term_nrc,
                  SZSTUME_PIDM pidm,
                  SZSTUME_SEQ_NO secuencia,
                  SZSTUME_NO_REGLA regla,
                  SZSTUME_ID matricula,
                  SZSTUME_MDLE_ID usr_modle_id,
                  SZTGPME_CRSE_MDLE_CODE shrt_name,
                  SZTGPME_CRSE_MDLE_ID crse_moodle_id,
                  SZTGPME_PTRM_CODE_COMP servidor
             FROM SZSTUME,
                  SZTGPME
            WHERE     SZSTUME_TERM_NRC = SZTGPME_TERM_NRC
                  AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                  AND SZSTUME_START_DATE = SZTGPME_START_DATE
                  AND SZSTUME_POBI_SEQ_NO = 1
         ORDER BY 5 ASC;

      RETURN (grade_out);
   END f_grade_out;



 FUNCTION f_alumnos_alula10 RETURN PKG_MOODLE2.cursor_alumnos_out10

    AS
        alumnos_out10 PKG_MOODLE2.cursor_alumnos_out10;

    BEGIN

    OPEN alumnos_out10 FOR

       SELECT  SPRIDEN_PIDM  PIDM,
        SPRIDEN_ID  MATRICULA,
        REPLACE(TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'), '/',' ' ) LAST_NAME,
        SPRIDEN_FIRST_NAME  FIRST_NAME,
        A.GOREMAL_EMAIL_ADDRESS EMAIL,
        GOZTPAC_PIN PWD
       FROM SPRIDEN, GOREMAL A, GOZTPAC, SORLCUR B
        WHERE SPRIDEN_CHANGE_IND IS NULL
        AND SPRIDEN_PIDM = GOZTPAC_PIDM
        AND SPRIDEN_PIDM = A.GOREMAL_PIDM
        AND SPRIDEN_PIDM  = B.SORLCUR_PIDM
        AND B.SORLCUR_LMOD_CODE ='LEARNER'
        AND B.SORLCUR_CACT_CODE ='ACTIVE'
        AND B.SORLCUR_LEVL_CODE IN ('MA','MS')
        AND B.SORLCUR_CAMP_CODE IN ('UTS','UTL')
        AND B.SORLCUR_SEQNO = (SELECT MAX(B1.SORLCUR_SEQNO)
                                FROM SORLCUR B1
                                WHERE B.SORLCUR_PIDM = B1.SORLCUR_PIDM
                                AND B.SORLCUR_LMOD_CODE = B1.SORLCUR_LMOD_CODE
                                AND B.SORLCUR_CACT_CODE = B1.SORLCUR_CACT_CODE
                                AND B.SORLCUR_LEVL_CODE = B1.SORLCUR_LEVL_CODE)
        AND A.GOREMAL_EMAL_CODE  = NVL ( 'PRIN',  A.GOREMAL_EMAL_CODE)
        AND A.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                        FROM GOREMAL A1
                                        WHERE A.GOREMAL_PIDM = A1.GOREMAL_PIDM
                                        AND A.GOREMAL_EMAL_CODE = A1.GOREMAL_EMAL_CODE)
        ORDER BY 1 DESC;
     RETURN(alumnos_out10);


    END f_alumnos_alula10;


 FUNCTION f_materias_enroladas_moodle(p_pidm in number default null) RETURN PKG_MOODLE2.cursor_materias_enroladas_out
 AS

  materias_enroladas_out PKG_MOODLE2.cursor_materias_enroladas_out;

    vl_msje Varchar2(200);


    BEGIN

      OPEN materias_enroladas_out FOR

        SELECT SZSTUME_PIDM PIDM, SZSTUME_ID MATRICULA, SZTGPME_CRSE_MDLE_ID ID_CURSO_MDL,
        SZTGPME_GPMDLE_ID ID_GRUPO_MDL, SZTGPME_SUBJ_CRSE CLAVE_MATERIA, SZTGPME_TITLE TILTE, SZTGPME_PTRM_CODE_COMP ID_AULA
        FROM
        SZSTUME, SZTGPME
        WHERE SZSTUME_TERM_NRC = SZTGPME_TERM_NRC
        AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
        AND SZTGPME_CRSE_MDLE_ID IS NOT NULL
        AND SZSTUME_PIDM = p_pidm
      ORDER BY 1 ASC;
  RETURN(materias_enroladas_out);

  END f_materias_enroladas_moodle;


--
--
     procedure p_grupo_moodl(p_inicio_clase in varchar2,  p_regla in number)
    as
        l_retorna         varchar2(1000);
        l_contar          NUMBER;
        l_conse           NUMBER;
        l_materia         VARCHAR2(15);
        l_desripcion_mat  VARCHAR2(500);
        l_campus          VARCHAR2(15);
        l_nivel           VARCHAR2(15);
        l_parte_perido    VARCHAR2(15);
        l_term_code       VARCHAR2(15);
        l_regla_cerrada   VARCHAR2(1);
        l_short_name      VARCHAR2(250);
        l_grupo_moodl     VARCHAR2(15);
        l_grupo           VARCHAR2(5);
        l_secuencia       NUMBER:=null;
        vl_materia       VARCHAR2(15);
        vl_cont_reza number:= 0;



    BEGIN

        dbms_output.put_line(' entramos ');

        begin

            SELECT DISTINCT sztalgo_estatus_cerrado
            INTO  l_regla_cerrada
            FROM sztalgo
            WHERE 1 = 1
            AND sztalgo_no_regla = p_regla;

        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

        IF l_regla_cerrada = 'S' THEN

                        FOR c IN (
                                    select materia,
                                   pidm,
                                   matricula,
                                   maximo,
                                   CASE WHEN length(grupo)=2 THEN
                                    grupo
                                        WHEN length(grupo)=1 THEN
                                    to_char('0'||grupo)
                                   END GRUPO,
                                   secuencia,
                                   grupo grupo2,
                                   estatus,
                                   mat_conv
                            from
                            (
                            SELECT sztconf_subj_code materia,
                                   sztconf_pidm pidm,
                                   sztconf_id matricula,
                                   70 maximo,
--                                   TO_CHAR(ROW_NUMBER() OVER (PARTITION BY sztconf_subj_code ORDER BY sztconf_group)) grupo,
                                   to_char(SZTCONF_GROUP) grupo,
                                   SZTCONF_SECUENCIA secuencia,
                                   sztconf_estatus_cerrado estatus,
                                   (SELECT SZTCOMA_SUBJ_CODE_ADM||SZTCOMA_CRSE_NUMB_ADM
                                    FROM SZTCOMA
                                    WHERE SZTCOMA_SUBJ_CODE_BAN||SZTCOMA_CRSE_NUMB_BAN = a.sztconf_subj_code) mat_conv
                                FROM sztconf a
                                WHERE 1 = 1
                                AND sztconf_no_regla = p_regla
                                and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY') = p_inicio_clase
--                                and sztconf_subj_code='L2DE135.'
                            )x
                            where 1 = 1
                            and (grupo) not in (select
                                                       SZTGPME_GRUPO
                                                from SZTGPME
                                                where 1 = 1
                                                and SZTGPME_no_regla = p_regla
                                                and SZTGPME_SUBJ_CRSE= x.materia
                                                AND SZTGPME_START_DATE = p_inicio_clase
                                                )

                                 )
             LOOP

                 vl_cont_reza:= vl_cont_reza+1;

                 vl_materia:= null;

                 IF c.mat_conv IS NULL THEN

                 vl_materia := c.materia;

                 else

                 vl_materia := c.mat_conv;

                 end if;

                dbms_output.put_line('entra 1');

                BEGIN
                    SELECT UPPER(scrsyln_long_course_title)
                    INTO l_desripcion_mat
                    FROM scrsyln
                    WHERE 1 = 1
                    AND scrsyln_subj_code||scrsyln_crse_numb =c.materia;

                EXCEPTION WHEN OTHERS THEN
                    dbms_output.put_line(' Error en SCRSYLN '||SQLERRM);
                    --l_retorna:=' No se econtro descripcion para materia  '||c.materia||' '||sqlerrm;

                END;

                BEGIN

                   SELECT DISTINCT sztalgo_camp_code,
                                    sztalgo_levl_code
                    INTO l_campus,
                         l_nivel
                    FROM sztalgo
                    WHERE 1 = 1
                    AND sztalgo_no_regla  = p_regla
                    AND ROWNUM = 1;

                    IF l_campus ='UTS' THEN

                        l_campus:='UTL';

                    END IF;

                    IF l_nivel ='MS' THEN

                        l_nivel:='MA';

                    END IF;

                    IF l_nivel ='LI' THEN

                        l_nivel:='LI';

                    END IF;

                EXCEPTION WHEN OTHERS THEN
                     NULL;
                END;

                BEGIN




                    select CASE WHEN length( grupo)=2 THEN
                                grupo
                                WHEN length(grupo )=1 THEN
                                '0'||to_char(grupo)
                            END GRUPO
                    into l_grupo
                    from
                    (
                        SELECT to_char(nvl(count(*),0)+1) grupo
                        from szstume
                        where 1 = 1
                        and szstume_no_regla = p_regla
                        and SZSTUME_SUBJ_CODE =c.materia
                    );


                EXCEPTION WHEN OTHERS THEN
                    l_grupo:=0;
                END;




                BEGIN

                       SELECT DISTINCT sztalgo_ptrm_code_new,
                                       sztalgo_term_code_new
                       INTO l_parte_perido,
                            l_term_code
                       FROM sztalgo
                       WHERE 1 = 1
                       AND sztalgo_no_regla = p_regla
                       AND sztalgo_camp_code = l_campus
                       AND sztalgo_levl_code = l_nivel;

                EXCEPTION WHEN OTHERS THEN
                   DBMS_OUTPUT.PUT_LINE(' Error en sztgpme '||SQLERRM);
                   --l_retorna:=' Error en obtener parte de periodo en  sztgpme '||sqlerrm;
                END;



                begin
                         select     concat(concat(concat(
                                      case
                                      when substr (l_parte_perido,1,2) IN ('M0', 'M1', 'M2','A0','A1','A2', 'A4','M4') then 'S'
                                      when substr (l_parte_perido,1,2) IN('M3', 'A3') then 'M'
                                      when substr  (l_parte_perido, 1,2) in ('L2', 'L1', 'L0') then 'A'
                                      when substr  (l_parte_perido, 1,2) not in ('M0', 'M1','M2', 'M3','A0','A1','A2','A3','L0', 'L1', 'L2')  then 'B'
                                      end,
                                      case
                                          when substr (l_term_code, 5,2) = '41' then  'A'
                                          when substr (l_term_code, 5,2) = '42' then 'B'
                                          when substr (l_term_code, 5,2) = '43' then 'C'
                                      end ||'0'||substr(l_term_code,3,2) ||'_'),
                                      case
                                          when substr (l_parte_perido,2,2) IN ('3A', '3B', '3C','0A','0B','0C','0D','4A','4B','4C') then '0'
                                          when substr (l_parte_perido,2,2) IN ( '1A', '1B', '1C','1D', '1E', '3D', '4D')  then '1'
                                          when substr (l_parte_perido,2,2) IN ('2A') then '2'
                                          end ||'_'), TO_CHAR(to_DATE('04/03/2019','dd/mm/YYYY'),'DDMM')||'_' || vl_materia
                                  )  short_name
                        into l_short_name
                        from dual;
                 EXCEPTION WHEN OTHERS THEN
                    dbms_output.put_line(' Error en sztgpme '||SQLERRM);
                    --l_retorna:=' Error en sztgpme '||sqlerrm;
                END;



                   begin

                    SELECT SZTCONF_SECUENCIA
                    into l_secuencia
                    FROM SZTCONF
                    WHERE 1 = 1
                    AND SZTCONF_NO_REGLA = p_regla
                    and sztconf_subj_code = c.materia
                    and SZTCONF_ESTATUS_CERRADO ='N'
                    and rownum = 1;
                  exception when others then
                    dbms_output.put_line('error '||sqlerrm);
                  end;

                    dbms_output.put_line(' Secuencia  '||l_secuencia||' materia '||c.materia);


               -- end if;


                BEGIN
                       INSERT INTO sztgpme VALUES(
                                                      c.materia||c.grupo,
                                                      c.materia,
                                                      l_desripcion_mat,
                                                      5,
                                                      NULL,
                                                      USER,
                                                      SYSDATE,
                                                      l_parte_perido,
                                                      p_inicio_clase,
                                                      NULL,
                                                      c.maximo,
                                                      l_nivel ,
                                                      l_campus,
                                                      NULL,
                                                      c.materia,
                                                      NULL,
                                                      l_term_code ,
                                                      NULL,
                                                      NULL,
                                                      NULL,
                                                      l_short_name,
                                                      p_regla,
                                                      l_secuencia,
                                                      c.grupo2,
                                                      'S',
                                                      1, null
                                                      );

                    l_retorna:='EXITO';

                EXCEPTION WHEN OTHERS THEN
                    dbms_output.put_line(' Error en al insertar gpme '||SQLERRM);
                    --l_retorna:=' Error en al insertar gpme  '||sqlerrm;
                END;

               -- raise_application_error (-20002,'Secuencia tabla '||c.secuencia||' Secuecia variable '||l_secuencia);

                BEGIN

                    UPDATE SZTCONF SET SZTCONF_ESTATUS_CERRADO='S'
                    WHERE 1 = 1
                    AND SZTCONF_SUBJ_CODE  =c.materia
                    and sztconf_no_regla =p_regla
                    and SZTCONF_GROUP = c.grupo
                    and SZTCONF_FECHA_INICIO =p_inicio_clase;

                EXCEPTION WHEN OTHERS THEN
                    dbms_output.put_line(' Error al actualizar grupos pronostico '||SQLERRM);
                    l_retorna:=' Error al actualizar grupos pronostico '||sqlerrm;

                    --raise_application_error (-20002,'Secuencia  '||c.secuencia||sqlerrm);

                END;


             END LOOP;


             COMMIT;
        ELSE
            dbms_output.put_line(' Esta regla no esta cerrada '||p_regla);
            --l_retorna:='Esta regla no esta cerrada '||l_regla_cerrada;

        END IF;

        --return(l_retorna);
    end;


 --  SE DESACTIVA FUNCI”N YA QUE OCASIONA LENTITUD EN SIU--
  /*
  FUNCTION f_califica_moodle_out
      RETURN PKG_MOODLE2.cursor_out_calif
   AS
      c_out_calif   PKG_MOODLE2.cursor_out_calif;
   BEGIN
      BEGIN
         OPEN c_out_calif FOR
           select distinct b.SZTGPME_CAMP_CODE campus,
                                b.SZTGPME_LEVL_CODE nivel,
                                substr (SZTGPME_TERM_NRC,
                                length(SZTGPME_TERM_NRC)-1 , 2) grupo,
                                SZTGPME_TERM_NRC termnrc,
                                b.SZTGPME_CRSE_MDLE_ID id_curso,
                                b.SZTGPME_GPMDLE_ID id_grupo,
                                b.SZTGPME_CRSE_MDLE_CODE  shortname,
                                b.SZTGPME_SUBJ_CRSE materia ,
                                c.SZTMAUR_SZTURMD_ID  aula,
                                a.SZSTUME_NO_REGLA regla,
                                a.SZSTUME_SEQ_NO secuencia,
                                a.SZSTUME_ID matricula,
                                a.SZSTUME_PIDM pidm,
                                nvl ( a.SZSTUME_MDLE_ID,1) id_alumno,
                                a.SZSTUME_GRDE_CODE_FINAL calif
            from SZSTUME a
            join SZTGPME b on b.SZTGPME_TERM_NRC = a.SZSTUME_TERM_NRC
                    And b.SZTGPME_NO_REGLA = a.SZSTUME_NO_REGLA
                    And b.SZTGPME_STAT_IND = '1'
            join sztmaur c on c.SZTMAUR_MACO_PADRE = b.SZTGPME_SUBJ_CRSE and c.SZTMAUR_ACTIVO = 'S'
            And a.SZSTUME_STAT_IND = '1'
            And a.SZSTUME_RSTS_CODE = 'RE'
            And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                        from SZSTUME a1
                                                        Where 1=1
                                                        And a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                        And a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                        And a.SZSTUME_STAT_IND =  a1.SZSTUME_STAT_IND
                                                        And a.SZSTUME_RSTS_CODE = a1.SZSTUME_RSTS_CODE
                                                        And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                        )
            And a.SZSTUME_POBI_SEQ_NO = 0
         -- and a.SZSTUME_NO_REGLA = 37
           Join tztprog d on d.pidm = SZSTUME_PIDM  and d.estatus in ('MA', 'TR', 'PR', 'EG', 'SG')
            order by 4,11;
        RETURN (c_out_calif);

    End;

End f_califica_moodle_out;

*/


    FUNCTION f_updte_alumnos_califica(p_campus in varchar2,
                                                           p_nivel in varchar2,
                                                           p_term_nrc in Varchar2,
                                                           p_matricula in varchar2,
                                                            p_pidm in number,
                                                           p_secuencia in number,
                                                           p_idcurso in number,
                                                           p_idgrupo in number,
                                                           p_idalumno in number,
                                                           p_grade_final in number,
                                                           p_no_regla in number,
                                                           p_observaciones in varchar2
                                                           ) Return Varchar2
    AS
        vl_maximo number:=0;
        vl_grade_final Varchar2(10);
        vl_error  varchar2(250) := 'EXITO';
        vl_fecha_ini date := null;
        vl_mat_padre varchar2(25):= null;
        vl_periodo varchar2(6) := null;
        vl_crn      varchar2(5):= null;
           v_sal Varchar2(2500):= null;


            BEGIN

                        vl_grade_final := null;
                        vl_mat_padre := null;
                        vl_periodo := null;
                        vl_crn := null;

                        begin
                            SELECT distinct SZTRNDO_GRDE
                            Into   vl_grade_final
                            FROM SZTRNDO
                            WHERE SZTRNDO_CAMP_CODE = p_campus
                            AND SZTRNDO_LEVL_CODE = p_nivel
                            And  ROUND(p_grade_final,1) between SZTRNDO_MIN_GRDE and SZTRNDO_MAX_GRDE;
                        Exception
                            When Others then
                                vl_grade_final := null;
                                vl_error := 'No existe conversion calificacion '||p_grade_final;
                        end;

                  --      dbms_output.put_line  ('entra al update con: '||vl_grade_final );


                        if  vl_grade_final is not null then


                                Begin
                                        Select distinct a.SZSTUME_START_DATE, a.SZSTUME_SUBJ_CODE
                                            Into vl_fecha_ini, vl_mat_padre
                                        from SZSTUME a
                                        WHERE a.SZSTUME_TERM_NRC = p_term_nrc
                                         AND a.SZSTUME_PIDM = p_pidm
                                        AND a.SZSTUME_SEQ_NO = p_secuencia
                                        AND a.SZSTUME_NO_REGLA = p_no_regla
                                        And a.SZSTUME_STAT_IND = '1'
                                        And a.SZSTUME_POBI_SEQ_NO = 0 ;
                                Exception
                                    when Others then
                                    vl_fecha_ini := null;
                                    vl_mat_padre := null;
                                     vl_error := 'No existe conversion Materia PADRE '||p_term_nrc;
                                End;

                                If vl_fecha_ini is not null and vl_mat_padre is not null then
                                    Begin
                                        UPDATE SZSTUME a
                                        SET a.SZSTUME_GRDE_CODE_FINAL= vl_grade_final,
                                        a.SZSTUME_ACTIVITY_DATE = sysdate,
                                        a.SZSTUME_OBS =p_observaciones,
                                        a.SZSTUME_POBI_SEQ_NO = '1' ,
                                        a.SZSTUME_TERM_NRC_COMP = p_grade_final
                                        WHERE a.SZSTUME_TERM_NRC = p_term_nrc
                                        AND a.SZSTUME_PIDM = p_pidm
                                        AND a.SZSTUME_SEQ_NO = p_secuencia
                                        AND a.SZSTUME_NO_REGLA = p_no_regla
                                        And a.SZSTUME_STAT_IND = '1'
                                        And a.SZSTUME_POBI_SEQ_NO = 0;
                                    Exception
                                        When Others then
                                         -- dbms_output.put_line  ('Error al actualizar 1'||' '|| p_term_nrc||' '||p_matricula||' '||p_secuencia||' '|| p_no_regla);
                                          vl_error := 'Error al actualizar 1'||' '|| p_term_nrc||' '||p_matricula||' '||p_secuencia||' '|| p_no_regla ||'*'||sqlerrm;
                                    End;

                                    Begin
                                            select distinct a.SFRSTCR_TERM_CODE, a.SFRSTCR_CRN
                                                Into vl_periodo, vl_crn
                                            from sfrstcr a
                                            join ssbsect b on b.SSBSECT_TERM_CODE = a.SFRSTCR_TERM_CODE and b.SSBSECT_CRN = a.SFRSTCR_CRN
                                            join sztmaco on SZTMACO_MATPADRE  =  vl_mat_padre and SZTMACO_MATHIJO = SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB
                                            where 1= 1
                                            And a.SFRSTCR_CAMP_CODE = p_campus
                                            And a.SFRSTCR_LEVL_CODE = p_nivel
                                            And a.SFRSTCR_RSTS_CODE = 'RE'
                                            And  trunc (b.SSBSECT_PTRM_START_DATE) = trunc (vl_fecha_ini)
                                            And a.sfrstcr_pidm = p_pidm;
                                    Exception
                                        When Others then
                                            vl_periodo:= null;
                                            vl_crn := null;
                                    End;

                                    If vl_periodo is not null and vl_crn is not null then

                                        Begin
                                            Update sfrstcr
                                              set  SFRSTCR_GRDE_CODE  = vl_grade_final
                                            Where SFRSTCR_TERM_CODE = vl_periodo
                                            And  SFRSTCR_CRN = vl_crn
                                            And SFRSTCR_PIDM = p_pidm;
                                            Commit;
                                            v_sal := PKG_MOODLE2.F_PASE_HISTORIA_CALIFICA ( P_CAMPUS, P_NIVEL, vl_periodo, vl_crn, p_pidm );  --- Envia a Historia Academica

                                        Exception
                                            When Others then
                                                 vl_error := 'Error al actualizar Calificacion Horario'||' '|| p_term_nrc||' '||p_matricula||' '||p_secuencia||' '|| p_no_regla;
                                        End;
                                    End if;

                                End if;

                       Else
                                Begin
                                        UPDATE SZSTUME a
                                        SET a.SZSTUME_ACTIVITY_DATE = sysdate,
                                               a.SZSTUME_OBS = p_observaciones,
                                               a.SZSTUME_POBI_SEQ_NO = null
                                        WHERE a.SZSTUME_TERM_NRC = p_term_nrc
                                        AND a.SZSTUME_PIDM = p_pidm
                                        AND a.SZSTUME_SEQ_NO = p_secuencia
                                        AND a.SZSTUME_NO_REGLA = p_no_regla
                                        And a.SZSTUME_STAT_IND = '1';



                                Exception
                                    When Others then
                                        null;
                                    --  dbms_output.put_line  ('Error al actualizar 2'||' '|| p_term_nrc||' '||p_matricula||' '||p_secuencia||' '|| p_no_regla);
                                End;

                        end if;


                Return vl_error;

            END f_updte_alumnos_califica;

FUNCTION f_pase_historia_califica(p_campus in varchar2,
                                                           p_nivel in varchar2,
                                                           p_term in Varchar2,
                                                           p_crn in varchar2,
                                                            p_pidm in number
                                                           ) Return Varchar2
    AS



conta_shrttrm number;
pidm number;
periodo varchar2(6);
sb varchar2(4);
cr varchar2(5);
coll varchar2(2);
dept varchar2(4);
schd varchar2(4);
cuenta varchar2(9);
seq number;
orig_seq number;
cred decimal(7,3);
gmod varchar2(10);
prog varchar2(10);
nivel varchar2(2);
camp varchar2(3);
gchg_code varchar2(3);
conta_origen number;

conta_origen_shrttrm number;
conta_destino number;
sp integer;
tckn_crn varchar2(5);
mensaje varchar2(200);
long_course varchar2(100);
short_course varchar2(100);

conta_materia number :=0;
conta_seq number :=0;
vl_exito varchar2(250):=0;



Begin

For alumno in (


        select distinct sfrstcr_pidm pidm, SFRSTCR_CAMP_CODE Campus, a.SFRSTCR_LEVL_CODE Nivel, spriden_id matricula, SFRSTCR_CRN
         from sfrstcr a
         join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('SESO1001')
         join spriden on spriden_pidm = sfrstcr_pidm and spriden_change_ind is null
         join shrgrde on  SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE  and  SHRGRDE_CODE =SFRSTCR_GRDE_CODE and shrgrde_passed_ind = 'Y'
         where   1=1
         and a.SFRSTCR_GRDE_CODE is not null
         And a.SFRSTCR_GRDE_DATE is not null
         And a.SFRSTCR_RSTS_CODE = 'RE'
         And a.SFRSTCR_TERM_CODE = p_term
         And  a.SFRSTCR_CRN = p_crn
         And  a.sfrstcr_pidm = p_pidm
         And a.SFRSTCR_CAMP_CODE = p_campus
         And a.SFRSTCR_LEVL_CODE = p_nivel
         order by 2, 3, 4


         ) loop


         --dbms_output.put_line('Alumnos:'||alumno.pidm||'*'||alumno.Campus||'*'||alumno.nivel);

    For c1 in (


                 select x.pidm pidm, x.matricula matricula,  x.SSBSECT_SUBJ_CODE ,  x.SSBSECT_CRSE_NUMB, x.Calificacion, x.Campus, x.Nivel, x.SP, x.parte, max (x.fecha) fecha, x.crn
                 from (
                         select distinct
                         a.sfrstcr_pidm pidm,
                         c.spriden_id matricula,
                         b.SSBSECT_SUBJ_CODE,
                         b.SSBSECT_CRSE_NUMB,
                         a.SFRSTCR_GRDE_CODE Calificacion,
                         a.SFRSTCR_CAMP_CODE Campus,
                         a.SFRSTCR_LEVL_CODE Nivel,
                         nvl (a.SFRSTCR_STSP_KEY_SEQUENCE,1) SP,
                         a.SFRSTCR_PTRM_CODE parte,
                         b.SSBSECT_PTRM_START_DATE fecha,
                         a.SFRSTCR_GRDE_DATE,
                         a.SFRSTCR_CRN crn
                 from sfrstcr a, ssbsect b, spriden c
                 where b.ssbsect_term_code = a.sfrstcr_term_code
                     and a.sfrstcr_crn = b.ssbsect_crn
                     and a.sfrstcr_pidm = spriden_pidm
                     and c.spriden_change_ind is null
                     and a.SFRSTCR_GRDE_CODE is not null
                     and a.SFRSTCR_GRDE_DATE is not null
                     And a.SFRSTCR_RSTS_CODE = 'RE'
                     and c.spriden_pidm = alumno.pidm
                     and a.SFRSTCR_CAMP_CODE = alumno.campus
                     and a.SFRSTCR_LEVL_CODE = alumno.nivel
                     and a.SFRSTCR_CRN = alumno.SFRSTCR_CRN
                     and TO_NUMBER (decode (a.SFRSTCR_GRDE_CODE,  'AC',1,'NA',1,'NP',1
                                                                                                  ,'10',10,'10.0',10,'100',10
                                                                                                  ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                                                                  ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                                                                  ,'6.0',6,'6',6,'6.1',6,'61',6,'6.2',6,'6.3',6,'63',6,'6.5',6,'65',6,'6.6',6,'6.7',6,'6.8',6,'6.9',6
                                                                                                  ,'7.0',7,'7',7,'7.1',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'7.7',7,'77',7,'7.8',7,'7.9',7
                                                                                                  ,'8.0',8,'8',8,'80',8,'8.1',8,'8.2',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                                                                 ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9 )) =
                                                                                                    (select max (TO_NUMBER (decode (xx1.SFRSTCR_GRDE_CODE,  'AC',1,'NA',1,'NP',1
                                                                                                  ,'10',10,'10.0',10,'100',10
                                                                                                  ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                                                                  ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                                                                  ,'6.0',6,'6',6,'6.1',6,'61',6,'6.2',6,'6.3',6,'63',6,'6.5',6,'65',6,'6.6',6,'6.7',6,'6.8',6,'6.9',6
                                                                                                  ,'7.0',7,'7',7,'7.1',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'7.7',7,'77',7,'7.8',7,'7.9',7
                                                                                                  ,'8.0',8,'8',8,'80',8,'8.1',8,'8.2',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                                                                 ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9)))
                                                        from SFRSTCR xx1, ssbsect xx2
                                                         where 1=1
                                                         And  xx1.SFRSTCR_TERM_CODE = xx2.SSBSECT_TERM_CODE
                                                        And xx1.SFRSTCR_CRN = xx2.SSBSECT_CRN
                                                         And xx1.SFRSTCR_PIDM = a.sfrstcr_pidm
                                                        And xx2.SSBSECT_SUBJ_CODE||xx2.SSBSECT_CRSE_NUMB  = b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB
                                                          )
                 order by 1, 2,3, 4
                 ) x
                 group by x.pidm , x.matricula ,  x.SSBSECT_SUBJ_CODE ,  x.SSBSECT_CRSE_NUMB, x.Calificacion, x.Campus, x.Nivel, x.SP, x.parte, fecha,x.crn
                 order by 1, 2, 3, 4,10



     ) loop
               --dbms_output.put_line('MAteria:'||c1.matricula||'*'||c1.SSBSECT_SUBJ_CODE||'*'||c1.SSBSECT_CRSE_NUMB||'*'||c1.Calificacion);
               conta_materia :=0;
               conta_seq :=0;
               vl_exito := null;
               coll:= null;
               dept:= null;
               cred:= null;
               schd:= null;
               long_course:= null;
               short_course:= null;

             For c in (


                         select distinct a.sfrstcr_pidm pidm,
                         c.spriden_id matricula,
                         a.sfrstcr_term_code periodo,
                         b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB id_materia,
                         b.SSBSECT_SUBJ_CODE,
                         b.SSBSECT_CRSE_NUMB,
                         a.sfrstcr_crn crn,
                         b.SSBSECT_SEQ_NUMB grupo,
                         a.SFRSTCR_GRDE_CODE Calificacion,
                         a.SFRSTCR_GRDE_DATE fecha_rolado,
                         a.SFRSTCR_CAMP_CODE Campus,
                         a.SFRSTCR_LEVL_CODE Nivel,
                         b.SSBSECT_PTRM_START_DATE fecha,
                         a.SFRSTCR_STSP_KEY_SEQUENCE SP,
                         row_number() over(partition by a.sfrstcr_pidm, a.sfrstcr_term_code order by a.sfrstcr_pidm) numero,
                         a.SFRSTCR_PTRM_CODE parte
                         from sfrstcr a, ssbsect b, spriden c
                         where b.ssbsect_term_code = a.sfrstcr_term_code
                         and a.sfrstcr_crn = b.ssbsect_crn
                         and a.SFRSTCR_CAMP_CODE = c1.campus
                         and a.SFRSTCR_LEVL_CODE = c1.nivel
                         and a.sfrstcr_pidm = spriden_pidm
                         and a.SFRSTCR_CRN = c1.crn
                         and c.spriden_change_ind is null
                         and a.SFRSTCR_GRDE_CODE is not null
                         and a.SFRSTCR_GRDE_DATE is not null
                         And a.SFRSTCR_RSTS_CODE = 'RE'
                          and c.spriden_pidm = c1.pidm
                          and b.SSBSECT_SUBJ_CODE = c1.SSBSECT_SUBJ_CODE
                          and b.SSBSECT_CRSE_NUMB = c1.SSBSECT_CRSE_NUMB
                          and  a.SFRSTCR_GRDE_CODE = c1.calificacion
                          and trunc (b.SSBSECT_PTRM_START_DATE)  =  trunc (c1.fecha)
                         order by 1, 2,3, 15



             ) loop

                conta_shrttrm :=0;
                conta_materia :=0;
               conta_seq :=0;
               vl_exito := null;
               coll:= null;
               dept:= null;
               cred:= null;
               schd:= null;
               long_course:= null;
               short_course:= null;
                --dbms_output.put_line('Secuencia:'||c.matricula||'*'||c.periodo||'*'||c.id_materia||'*'||c.Calificacion||'*'||c.numero||'*'||c.crn);

                 Begin
                         select count(*)
                         into conta_shrttrm
                         from shrttrm
                         where shrttrm_pidm=c.pidm
                         and shrttrm_term_code=c.periodo;
                 Exception
                 when Others then
                         conta_shrttrm :=0;
                 End;

                 if conta_shrttrm = 0 then
                     conta_origen_shrttrm:=conta_origen_shrttrm+1;
                 --dbms_output.put_line('periodo:'||periodo);
                     begin
                                 insert into shrttrm ( shrttrm_pidm, shrttrm_term_code, shrttrm_update_source_ind, shrttrm_pre_catalog_ind, shrttrm_record_status_ind, shrttrm_record_status_date,
                                                              shrttrm_activity_date, shrttrm_user_id, shrttrm_data_origin)
                                 values(c.pidm, c.periodo,'S', 'N', 'G', c.fecha, c.fecha, user, 'CARG_HHH');

                                  dbms_output.put_line('Inserta en shrttrm ');
                                  vl_exito := 'Exito';
                        exception
                         when DUP_VAL_ON_INDEX then
                         dbms_output.put_line('Error duplicidad shrttrm '||sqlerrm);
                         vl_exito := sqlerrm;
                         when others then
                          dbms_output.put_line('Error Othrs shrttrm '||sqlerrm);
                          vl_exito := sqlerrm;
                     end;


                     Begin
                                Insert into SHRCHRT values (c.pidm, c.periodo, c.periodo, null, null, sysdate, null, null, user, 'MASIVO', null);
                                dbms_output.put_line('Inserta en SHRCHRT ');
                                  vl_exito := 'Exito';
                        exception
                         when DUP_VAL_ON_INDEX then
                         dbms_output.put_line('Error duplicidad SHRCHRT '||sqlerrm);
                         vl_exito := 'Exito';
                         when others then
                          dbms_output.put_line('Error Othrs SHRCHRT '||sqlerrm);
                          vl_exito := sqlerrm;
                     end;

                 end if;



                 begin
                         select distinct scbcrse_coll_code, scbcrse_dept_code, scbcrse_credit_hr_low , scrschd_schd_code , scrsyln_long_course_title, SCBCRSE_TITLE
                                into coll,dept, cred , schd , long_course, short_course
                         from scbcrse , scrschd, scrsyln
                         where scbcrse_subj_code= c.SSBSECT_SUBJ_CODE
                         and scbcrse_crse_numb= c.SSBSECT_CRSE_NUMB
                         and scbcrse_eff_term='000000'
                         and scrschd_subj_code=scbcrse_subj_code
                         and scrschd_crse_numb=scbcrse_crse_numb
                         and scrsyln_subj_code=scbcrse_subj_code
                         and scrsyln_crse_numb=scbcrse_crse_numb;
                 Exception when others then
                          dbms_output.put_line(' Materia NO cargada en SCBCRSE');
                         cuenta:=c.matricula;
                 end;


                 Begin
                         select nvl (max (shrtckn_seq_no), 0) +1
                         into conta_materia
                         from shrtckn
                         where shrtckn_pidm = c.pidm
                         And shrtckn_term_code = c.periodo;
                 Exception
                    when Others then
                     conta_materia :=1;
                 End;


                 begin
                         insert into shrtckn ( shrtckn_pidm, shrtckn_term_code, shrtckn_seq_no, shrtckn_crn, shrtckn_subj_code, shrtckn_crse_numb,
                                                     shrtckn_coll_code, shrtckn_camp_code, shrtckn_dept_code, shrtckn_crse_title,
                                                     shrtckn_course_comment, shrtckn_activity_date, shrtckn_seq_numb, shrtckn_schd_code,
                                                     shrtckn_user_id, shrtckn_data_origin,shrtckn_stsp_key_sequence,shrtckn_long_course_title, shrtckn_ptrm_code)
                                                     values (c.pidm, c.periodo, conta_materia, c.crn, c.SSBSECT_SUBJ_CODE, c.SSBSECT_CRSE_NUMB,
                                                     coll, c.campus, dept, short_course,
                                                     null, sysdate, conta_materia, schd,
                                                     user, 'MOODLE',c.sp, long_course,c.parte);

                         vl_exito :='Exito';
                         dbms_output.put_line('Inserta en shrtckn ' ||vl_exito);

                 exception
                     when DUP_VAL_ON_INDEX then
                     vl_exito := 'Exito';
                     dbms_output.put_line('Error duplicidad shrtckn '||sqlerrm);
                     when others then
                     dbms_output.put_line('Error duplicidad shrtckn '||sqlerrm);
                     vl_exito := sqlerrm;
                 end;

                If vl_exito = 'Exito' then

                         begin
                         select scrgmod_gmod_code
                                 into gmod
                         from scrgmod
                         where scrgmod_subj_code=c.ssbsect_subj_code
                         and scrgmod_crse_numb=c.ssbsect_crse_numb
                         And SCRGMOD_DEFAULT_IND ='D';
                         exception
                            when others then
                            gmod:=null;
                         end;

                        gchg_code:='OE';

                         Begin
                         select nvl (max (shrtckg_seq_no), 0) +1
                               Into conta_seq
                         from shrtckg
                         Where shrtckg_pidm = c.pidm
                         And shrtckg_term_code = c.periodo
                         And shrtckg_tckn_seq_no = conta_materia;
                          Exception
                         when Others then
                          conta_seq:=1;
                         End;



                         begin

                             insert into shrtckg(shrtckg_pidm,
                                                     shrtckg_term_code,
                                                     shrtckg_tckn_seq_no,
                                                     shrtckg_seq_no,
                                                     shrtckg_grde_code_final,
                                                     shrtckg_gmod_code,
                                                     shrtckg_credit_hours,
                                                     shrtckg_activity_date,
                                                     shrtckg_data_origin,
                                                     shrtckg_user_id,
                                                     shrtckg_gchg_code,
                                                     shrtckg_final_grde_chg_date,
                                                     shrtckg_final_grde_chg_user,
                                                     shrtckg_gcmt_code,
                                                     shrtckg_term_code_grade,
                                                     SHRTCKG_HOURS_ATTEMPTED)
                                         values(c.pidm, c.periodo, conta_materia, conta_seq, c.calificacion, gmod, cred, sysdate, 'MOODLE', sysdate,gchg_code, c.fecha, user,'INTMOO', c.periodo,cred );
                                         vl_exito := 'Exito';
                                         dbms_output.put_line('LLEGA A CKG ');
                         Exception
                            when DUP_VAL_ON_INDEX then
                                vl_exito := 'Exito';
                            When Others then
                                vl_exito := sqlerrm;
                                dbms_output.put_line('Error  SHRTCKG '||vl_exito);
                         End;



                    If vl_exito = 'Exito' then

                             begin
                                     insert into shrtckl(shrtckl_pidm, shrtckl_term_code, shrtckl_tckn_seq_no, shrtckl_levl_code, shrtckl_activity_date, shrtckl_user_id, shrtckl_data_origin, shrtckl_primary_levl_ind)
                                     values( c.pidm, c.periodo, conta_materia, c.nivel, c.fecha, user, 'MOODLE','Y');
                                      vl_exito := 'Exito';
                                       dbms_output.put_line('LLEGA A CKL ');
                             exception
                             when DUP_VAL_ON_INDEX then
                                 vl_exito := 'Exito';
                                 dbms_output.put_line('Error  shrtckl '||vl_exito);
                             when others then
                                vl_exito := sqlerrm;
                                dbms_output.put_line('Error  shrtckl '||vl_exito);
                             end;

                        If vl_exito = 'Exito' then
                             Begin
                                 Update SFRSTCR
                                 set SFRSTCR_GRDE_DATE = sysdate
                                 where SFRSTCR_TERM_CODE = c.periodo
                                 And SFRSTCR_PIDM = c.pidm
                                 And SFRSTCR_CRN = c.crn;
                                  dbms_output.put_line('UPDATE A SFRSTCR ');
                             Exception
                             when Others then
                              vl_exito := sqlerrm;
                                dbms_output.put_line('Error  SFRSTCR '||vl_exito);
                             End;

                        End if;

                        If vl_exito = 'Exito' then

                                Begin
                                    insert into shrtgpa
                                    select shrttrm_pidm, shrttrm_term_code, sgbstdn_levl_code, 'I', null,null, 0,0,0,0,0,sysdate,0,null,null,user,null,null
                                    from shrttrm, sgbstdn a
                                    where shrttrm_pidm=sgbstdn_pidm
                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn b
                                    where a.sgbstdn_pidm=b.sgbstdn_pidm
                                    and   b.sgbstdn_term_code_eff <= shrttrm_term_code)
                                    and  shrttrm_term_code= p_term
                                    And  a.sgbstdn_pidm = c.pidm;
                                      dbms_output.put_line('Inserta en shrtgpa ');
                                Exception
                                 when Others then
                                 -- vl_exito := sqlerrm;
                                    dbms_output.put_line('Error  shrtgpa '||vl_exito);
                                End;

                        End if;


                    End if;

                End if;

            End loop;

     End loop;

       Commit;
    -- ROLLBACK;

 End loop;

          Return vl_exito;

End f_pase_historia_califica;


FUNCTION f_bajas_crse_bienvenida_abcc (p_matricula IN VARCHAR2) RETURN VARCHAR2
AS

    vl_pidm NUMBER:=0;
    vl_msje VARCHAR2(200);

  BEGIN

       vl_pidm:=FGET_PIDM(p_matricula);

      -- CURSOR PARA DAR DE  BAJA EL CURSO DE BIENVENIDA --
        BEGIN

           FOR c IN (
            SELECT SZTBNDA_PIDM pidm,
                   SZTBNDA_ID matricula,
                   SZTBNDA_TERM_NRC perido,
                   SZTBNDA_GRP_MDL_ID id_grupo,
                   SZTBNDA_CRSE_SUBJ short_name,
                   SZTBNDA_CAMP_CODE campus,
                   SZTBNDA_LEVL_CODE nivel
            FROM SZTBNDA a
            WHERE a.SZTBNDA_PIDM = vl_pidm--FGET_PIDM('010198762')
            AND a.SZTBNDA_SEQ_NO = (SELECT MAX (b.SZTBNDA_SEQ_NO)
                              FROM SZTBNDA b
                              WHERE 1=1
                              AND b.SZTBNDA_PIDM = a.SZTBNDA_PIDM)
            AND a.SZTBNDA_STAT_IND = 1
           )

           LOOP
            UPDATE SZTBNDA SET SZTBNDA_MDLE_STAT = 'DD', SZTBNDA_STAT_IND = '0', SZTBNDA_USER_ID = USER, SZTBNDA_ACTIVITY_DATE = SYSDATE
            WHERE 1=1
            AND SZTBNDA_PIDM = c.pidm
            AND SZTBNDA_TERM_NRC = c.perido
            AND SZTBNDA_GRP_MDL_ID = c.id_grupo
            AND SZTBNDA_CRSE_SUBJ = c.short_name
            AND SZTBNDA_LEVL_CODE = c.nivel;
           -- AND SZTBNDA_MDLE_STAT != 'DD';

            vl_msje:= SQL%ROWCOUNT;

                 IF vl_msje !='0' THEN
                    vl_msje := p_matricula||'|Cambio realizado';
                 ELSE
                    vl_msje := p_matricula||'|Ningun Cambio realizado';
                 END IF;

           END LOOP;


        RETURN vl_msje;
        EXCEPTION
        WHEN OTHERS THEN
        vl_msje:='Error al recuprar curso inscrito'||sqlerrm;
        END;
       COMMIT;

 END f_bajas_crse_bienvenida_abcc;


 FUNCTION f_cambio_crse_bienvenida(p_matricula IN VARCHAR2, p_term_code IN VARCHAR2)RETURN VARCHAR2
 AS
    --p_matricula VARCHAR(9):='010198762';
    --p_term_code VARCHAR2(10):='012041';
    vl_pidm number:=0;
    vl_seq_no number:=0;
    vl_msje varchar2(200);

    vl_cuenta varchar2(9);
    vl_password varchar2(250);
    vl_nivel varchar2(4);
    vl_campus varchar2(4);
    vl_materia_ins varchar2(20);
    vl_maximo number;
    vl_fecha_ini  varchar2(12):= null;

 BEGIN

       vl_pidm:=FGET_PIDM(p_matricula);

      -- CURSOR PARA DAR DE  BAJA EL CURSO DE BIENVENIDA --
        BEGIN

           FOR c IN (
            SELECT SZTBNDA_PIDM pidm,
                   SZTBNDA_ID matricula,
                   SZTBNDA_TERM_NRC periodo,
                   SZTBNDA_GRP_MDL_ID id_grupo,
                   SZTBNDA_CRSE_SUBJ short_name,
                   SZTBNDA_CAMP_CODE campus,
                   SZTBNDA_LEVL_CODE nivel
            FROM SZTBNDA a
            WHERE a.SZTBNDA_PIDM = vl_pidm--FGET_PIDM('010198762')
            AND a.SZTBNDA_SEQ_NO = (SELECT MAX (b.SZTBNDA_SEQ_NO)
                              FROM SZTBNDA b
                              WHERE 1=1
                              AND b.SZTBNDA_PIDM = a.SZTBNDA_PIDM)
            AND a.SZTBNDA_STAT_IND = 1

           )



           LOOP
           --DBMS_OUTPUT.PUT_LINE('Criterios para el update: '||c.pidm||'-'||c.matricula||'-'||c.periodo||'-'||c.short_name);
            UPDATE SZTBNDA SET SZTBNDA_MDLE_STAT = 'DD', SZTBNDA_STAT_IND = '0'
            WHERE 1=1
            AND SZTBNDA_PIDM = c.pidm
            AND SZTBNDA_TERM_NRC = c.periodo
            AND SZTBNDA_GRP_MDL_ID = c.id_grupo
            AND SZTBNDA_CRSE_SUBJ = c.short_name
            AND SZTBNDA_MDLE_STAT IS NULL;
            vl_msje:='Registro actualizado'||c.matricula||'-'||c.short_name;
           END LOOP;
           EXCEPTION WHEN OTHERS THEN
           vl_msje:='Error al actualizar la baja en SZTBNDA';
           return vl_msje;
        END;
        --return vl_msje;
       COMMIT;
       --DBMS_OUTPUT.PUT_LINE(vl_msje);


        -- SE BUSCA EL CONSECUTIVO PARA EL NUEVO CURSO --
        BEGIN
         SELECT   NVL (MAX (SZTBNDA_SEQ_NO),0)+1
         INTO vl_seq_no
         FROM SZTBNDA
         WHERE SZTBNDA_PIDM = vl_pidm
         AND SZTBNDA_TERM_NRC = p_term_code;
        --DBMS_OUTPUT.PUT_LINE('Primer salida:'||vl_seq_no);
        EXCEPTION
        WHEN OTHERS THEN
        vl_seq_no :=1;
        --DBMS_OUTPUT.PUT_LINE('Error9:'||vl_seq_no ||' *'||SQLERRM);
        END;
       --DBMS_OUTPUT.PUT_LINE(vl_seq_no);

        -- SE CALCULA EL NUEVO CURSO DE BIENVENIDA --
        BEGIN
         SELECT DISTINCT SPRIDEN_ID, GOZTPAC_PIN, SORLCUR_LEVL_CODE,  SORLCUR_CAMP_CODE, SZTCOMD_GRP_CODE, SZTCOMD_LIMMIT, to_char(SORLCUR_START_DATE, 'DD/MM/YYYY') fecha_inicio
         INTO vl_cuenta, vl_password, vl_nivel, vl_campus, vl_materia_ins, vl_maximo, vl_fecha_ini
          FROM SORLCUR a, SZTDTEC, SZTCOMD, SPRIDEN, GOZTPAC
          WHERE a.SORLCUR_PIDM = vl_pidm
          AND a.SORLCUR_TERM_CODE = p_term_code
          AND a.SORLCUR_LMOD_CODE=  'LEARNER'
          AND a.SORLCUR_CACT_CODE = 'ACTIVE'
          AND a.SORLCUR_ROLL_IND = 'Y'
          AND a.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
          AND a.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
          AND a.SORLCUR_PIDM = SPRIDEN_PIDM
          AND a.SORLCUR_PIDM = GOZTPAC_PIDM (+)
          AND a.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
          AND SZTDTEC_PERIODICIDAD = SZTCOMD_PERIODICIDAD
          AND SZTCOMD_CAMP_CODE = a.SORLCUR_CAMP_CODE
          AND SZTCOMD_LEVL_CODE = a.SORLCUR_LEVL_CODE
          AND SZTCOMD_ENABLE_IND ='Y'
          AND SZTCOMD_MOD_TYPE  = SZTDTEC_MOD_TYPE
          AND SPRIDEN_CHANGE_IND IS NULL
          AND a.SORLCUR_SEQNO = (SELECT MAX (b.SORLCUR_SEQNO)
                          FROM SORLCUR b
                          WHERE  a.SORLCUR_PIDM = b.SORLCUR_PIDM
                          AND a.SORLCUR_TERM_CODE =b.SORLCUR_TERM_CODE
                          AND a.SORLCUR_LMOD_CODE = b.SORLCUR_LMOD_CODE
                          AND a.SORLCUR_CACT_CODE =b.SORLCUR_CACT_CODE);
        vl_msje:='Inserta nuevo curso'||vl_cuenta||' '||vl_materia_ins;
        EXCEPTION
        WHEN OTHERS THEN
        vl_msje:='Error al recuperar nuevo curso'||sqlerrm;
        return vl_msje;
        END;

        --DBMS_OUTPUT.PUT_LINE(vl_msje);
        --DBMS_OUTPUT.PUT_LINE('Datos del nuevo curso'||vl_password||'-'||vl_nivel||'-'||vl_campus||'-'||vl_materia_ins||'-'||vl_maximo||'-'||vl_fecha_ini);
        BEGIN
            INSERT INTO SZTBNDA VALUES (
             p_term_code    --SZTBNDA_TERM_NRC
            ,vl_pidm      --SZTBNDA_PIDM
            ,vl_seq_no     --SZTBNDA_SEQ_NO
            ,vl_cuenta      --SZTBNDA_ID
            ,sysdate      --SZTBNDA_ACTIVITY_DATE
            ,user      --SZTBNDA_USER_ID
            ,0      --SZTBNDA_STAT_IND
            ,null      --SZTBNDA_OBS
            ,vl_password      --SZTBNDA_PWD
            ,null      --SZTBNDA_GRP_MDL_ID
            ,vl_materia_ins      --SZTBNDA_CRSE_SUBJ
            ,vl_nivel --SZTBNDA_LEVL_CODE
            ,vl_campus  --SZTBNDA_CAMP_CODE
            ,vl_fecha_ini --SZTBNDA_SUBJ_CODE
            ,null --SZTBNDA_MDLE_STAT
            );
            vl_msje :='Registros Insertados'||vl_cuenta||' '||vl_materia_ins;
        EXCEPTION
        WHEN OTHERS THEN
        vl_msje := 'Error al insertar sztbnda'||sqlerrm;
        --dbms_output.put_line('Error al insertar 1:  '||sqlerrm);
        END;
                return vl_msje;
        COMMIT;
  --DBMS_OUTPUT.PUT_LINE(vl_msje);
 vl_msje:= 'Proceso exitoso';
 EXCEPTION
 WHEN OTHERS THEN
 vl_msje:='ERROR GENERAL';
 return(vl_msje) ;
  --DBMS_OUTPUT.PUT_LINE(vl_msje);
 END f_cambio_crse_bienvenida;

     --CURSOR SALIDA PARA BAJAS DEL CURSO DE BIENVENIDA--

FUNCTION f_bajas_crse_bienvenida RETURN PKG_MOODLE2.cursor_bajas_bienvenida_out
AS
    bajas_bienvenida_out PKG_MOODLE2.cursor_bajas_bienvenida_out;


  BEGIN

    BEGIN
    OPEN bajas_bienvenida_out FOR
           SELECT DISTINCT
            SZTBNDA_PIDM PIDM,
            SZTBNDA_ID MATRICULA,
            REPLACE (
            TRANSLATE (SPRIDEN.SPRIDEN_LAST_NAME,
            '·ÈÌÛ˙¡…Õ”⁄',
            'aeiouAEIOU'),
            '/',
            ' ')
            LAST_NAME,
            SPRIDEN_FIRST_NAME FIRST_NAME,
            GOREMAL_EMAIL_ADDRESS EMAIL,
            SZTCOMD_SERVIDOR SERVIDOR,
            SZTBNDA_TERM_NRC TERM,
            SZTBNDA_PWD PWD,
            SZTBNDA_CRSE_SUBJ CRS_MOODLE,
            SZTCOMD_GRP_MDL_ID id_grupo,
            SZTCOMD_CRSE_MDL_ID id_curso,
            SZTBNDA_CAMP_CODE campus
            FROM SZTBNDA a,
            SPRIDEN,
            GOREMAL,
            SZTCOMD
            WHERE 1=1
            AND SZTBNDA_PIDM = SPRIDEN_PIDM
            AND GOREMAL_PIDM = SZTBNDA_PIDM(+)
            AND GOREMAL_EMAL_CODE = NVL ('PRIN', GOREMAL_EMAL_CODE)
            AND SPRIDEN_CHANGE_IND IS NULL
            AND a.SZTBNDA_STAT_IND = '0'
            AND a.SZTBNDA_SEQ_NO = (SELECT MAX (b.SZTBNDA_SEQ_NO)
                                    FROM SZTBNDA b
                                    WHERE 1=1
                                    AND b.SZTBNDA_PIDM = a.SZTBNDA_PIDM
                                    AND b.SZTBNDA_MDLE_STAT = a.SZTBNDA_MDLE_STAT)
            AND a.SZTBNDA_MDLE_STAT = 'DD'
            AND a. SZTBNDA_CRSE_SUBJ = SZTCOMD_GRP_CODE
            AND a.SZTBNDA_GRP_MDL_ID = SZTCOMD_GRP_MDL_ID
            ORDER BY CRS_MOODLE DESC;
    RETURN(bajas_bienvenida_out);
    END;
  END f_bajas_crse_bienvenida;

 FUNCTION f_update_bajas_crse_bienvenida (p_pidm in number, p_periodo in VARCHAR2, p_id_grupo in VARCHAR2, p_short_name in VARCHAR2) RETURN VARCHAR2
 IS

  BEGIN

   BEGIN
    FOR C in (
        SELECT SZTBNDA_PIDM pidm,
               SZTBNDA_ID matricula,
               SZTBNDA_TERM_NRC perido,
               SZTBNDA_GRP_MDL_ID id_grupo,
               SZTBNDA_CRSE_SUBJ short_name,
               SZTBNDA_CAMP_CODE campus,
               SZTBNDA_LEVL_CODE nivel
            FROM SZTBNDA
            WHERE SZTBNDA_MDLE_STAT = 'DD'
            AND SZTBNDA_STAT_IND = 1
            AND SZTBNDA_TERM_NRC = p_periodo --'012041'
            AND SZTBNDA_PIDM = p_pidm --219077
            AND SZTBNDA_GRP_MDL_ID = p_id_grupo --'143'
            AND SZTBNDA_CRSE_SUBJ = p_short_name --'utel_cuatri_I'
          )

          LOOP

           BEGIN
            UPDATE SZTBNDA SET SZTBNDA_MDLE_STAT = 'CGPO'
            WHERE 1=1
            AND SZTBNDA_PIDM = c.pidm
            AND SZTBNDA_TERM_NRC = c.perido
            AND SZTBNDA_GRP_MDL_ID = c.id_grupo
            AND SZTBNDA_CRSE_SUBJ = c.short_name;
           END;

          END LOOP;
         COMMIT;
  END;


  END f_update_bajas_crse_bienvenida;


Function f_periodo_adm (p_pperiodo in varchar2, p_fecha in varchar2)Return varchar2 is

vl_periodo varchar2(6):= null;


 Begin

        select substr (short_name, 1, 5) periodo
        Into vl_periodo
        from (
        select     concat(concat(concat(
                                              case
                                              when substr (p_pperiodo,1,2) IN ('M0', 'M1', 'M2','A0','A1','A2', 'A4','M4') then 'S'
                                              when substr (p_pperiodo,1,2) IN('M3', 'A3') then 'M'
                                              when substr  (p_pperiodo, 1,2) in ('L2', 'L1', 'L0') then 'A'
                                              when substr  (p_pperiodo, 1,2) not in ('M0', 'M1','M2', 'M3','A0','A1','A2','A3','L0', 'L1', 'L2')  then 'B'
                                              end,
                                              case
                                                  when substr ('011943', 5,2) = '41' then  'A'
                                                  when substr ('011943', 5,2) = '42' then 'B'
                                                  when substr ('011943', 5,2) = '43' then 'C'
                                              end ||'0'||substr('011943',3,2) ||'_'),
                                              case
                                                  when substr (p_pperiodo,2,2) IN ('3A', '3B', '3C','0A','0B','0C','0D','4A','4B','4C') then '0'
                                                  when substr (p_pperiodo,2,2) IN ( '1A', '1B', '1C','1D', '1E', '3D', '4D')  then '1'
                                                  when substr (p_pperiodo,2,2) IN ('2A') then '2'
                                                  end ||'_')
                                                  , TO_CHAR(to_DATE(p_fecha,'dd/mm/YYYY'),'DDMM' )
                                          )  short_name
                                --into l_short_name
                                from dual
                                ) x;
       return vl_periodo;

 End f_periodo_adm;

 FUNCTION f_califica_moodle_periodo_out
      RETURN PKG_MOODLE2.cursor_out_calif_periodo
   AS
      c_out_calif_periodo   PKG_MOODLE2.cursor_out_calif_periodo;
   BEGIN
      BEGIN
         OPEN c_out_calif_periodo FOR
           select distinct PKG_MOODLE2.f_periodo_adm(B.SZTGPME_PTRM_CODE, to_Char (B.SZTGPME_START_DATE)) periodo
            from SZSTUME a
            join SZTGPME b on b.SZTGPME_TERM_NRC = a.SZSTUME_TERM_NRC
                    And b.SZTGPME_NO_REGLA = a.SZSTUME_NO_REGLA
                    And b.SZTGPME_START_DATE = a.SZSTUME_START_DATE
                    And b.SZTGPME_STAT_IND = '1'
            join sztmaur c on c.SZTMAUR_MACO_PADRE = b.SZTGPME_SUBJ_CRSE and c.SZTMAUR_ACTIVO = 'S'
            And a.SZSTUME_STAT_IND = '1'
            And a.SZSTUME_RSTS_CODE = 'RE'
            And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                        from SZSTUME a1
                                                        Where 1=1
                                                        And a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                        And a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                        And a.SZSTUME_STAT_IND =  a1.SZSTUME_STAT_IND
                                                        And a.SZSTUME_RSTS_CODE = a1.SZSTUME_RSTS_CODE
                                                        And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                        )
            And a.SZSTUME_POBI_SEQ_NO = 0
         -- and a.SZSTUME_NO_REGLA = 37
           Join tztprog d on d.pidm = SZSTUME_PIDM  and d.estatus in ('MA', 'TR', 'PR', 'EG', 'SG')
            order by 1;
        RETURN (c_out_calif_periodo);

    End;

End f_califica_moodle_periodo_out;



-- FUNCIONONES ACTUAL UTILIZADO PARA SINCRONIZAR CALIFICACIONES CON MOODLE--

 FUNCTION f_prepara_sync_grades(p_no_regla in number, p_start_date in varchar2) Return varchar2
  IS
 vl_msje varchar2(200) := Null;
 vl_valida number:=NULL;
 vl_process varchar2(30);

    BEGIN


     vl_valida:= NULL;

       BEGIN
        SELECT STAT_IND, PROCESS
        INTO vl_valida, vl_process
        FROM TMP_SYNC_STATUS
        WHERE 1=1
        AND REGLA = p_no_regla
        AND START_DATE = p_start_date
        GROUP BY STAT_IND, PROCESS;
       EXCEPTION
       WHEN OTHERS THEN
       vl_valida := NULL;
       vl_process := Null;
       END;

       IF vl_valida IS NULL AND vl_process IS NULL THEN

          BEGIN
            UPDATE SZSTUME SET SZSTUME_PTRM = '0', SZSTUME_ACTIVITY_DATE = SYSDATE, SZSTUME_USER_ID = USER, SZSTUME_OBS = 'Esperando||desgarga calificaciones'
            WHERE 1=1
            AND SZSTUME_NO_REGLA = p_no_regla
            AND SZSTUME_START_DATE = p_start_date
            AND SZSTUME_MDLE_ID IS NOT NULL
            AND SZSTUME_PTRM IS NULL;
        vl_msje:='Exito';
         EXCEPTION
         WHEN OTHERS THEN
         vl_msje:= 'Error en la peticiÛn de calificaciones '||sqlerrm||' Near of Line...6475';
        END;
       COMMIT;

      END IF;


       BEGIN
        INSERT INTO TMP_SYNC_STATUS
        (STAT_IND,
            REGLA,
            START_DATE,
            PROCESS,
            USER_UPDATE,
            COL1,
            COL2
          )
          VALUES
          (0,
           p_no_regla,
           p_start_date,
           'sync_grades',
           USER,
           Null,
           Null
          );
       EXCEPTION
       WHEN OTHERS THEN
           BEGIN

            SELECT STAT_IND, PROCESS
            INTO vl_valida, vl_process
            FROM TMP_SYNC_STATUS
            WHERE 1=1
            AND REGLA = p_no_regla
            AND START_DATE = p_start_date
            GROUP BY STAT_IND, PROCESS;

            IF

            vl_valida = 0 AND vl_process = 'sync_grades' THEN
               vl_msje:='SincronizaciÛn de calificaciones iniciada para esta regla: '||p_no_regla||' y fecha de inicio: '||p_start_date;

            ELSIF vl_valida = 1 AND vl_process = 'sync_grades' THEN
               vl_msje:='Las calificaciones ya fueron sincronizadas para esta regla: '||p_no_regla||' y fecha de inicio: '||p_start_date;

            ELSIF vl_valida = 2 AND vl_process = 'rolado_grades' THEN
               vl_msje:='Calificaciones en proceso de rolado';

            ELSIF vl_valida = 3 AND vl_process = 'historias_grades' THEN
               vl_msje:='Solicitud de calificaciones invalida, generando historias acadÈmicas';
              END IF;
           END;
       END;
       COMMIT;

        BEGIN
           DELETE TMP_SYNC_STATUS
            WHERE 1=1
            AND STAT_IND = 4
            AND PROCESS = 'fin_grades';
        END;
        COMMIT;

      RETURN(vl_msje);
      DBMS_OUTPUT.PUT_LINE(vl_msje);

    END f_prepara_sync_grades;


FUNCTION f_sync_grades_moodle
      RETURN PKG_MOODLE2.cursor_gout
   AS
      c_out_grades  PKG_MOODLE2.cursor_gout;
   BEGIN
      BEGIN
       OPEN c_out_grades FOR
        SELECT
        SZSTUME_PIDM pidm,
        SZSTUME_ID matricula,
        SZSTUME_MDLE_ID user_moodle_id,
        to_number(SZTGPME_PTRM_CODE_COMP) aula,
        SZTGPME_CRSE_MDLE_ID id_crse_moodle,
        SZTGPME_NO_REGLA regla,
        SZSTUME_START_DATE fecha_inicio
        FROM SZSTUME a, SZTGPME
        WHERE 1=1
        AND SZTGPME_NO_REGLA = a.SZSTUME_NO_REGLA
        AND SZTGPME_TERM_NRC = a.SZSTUME_TERM_NRC
        AND SZTGPME_START_DATE = a.SZSTUME_START_DATE
        AND SZSTUME_PTRM = '0'
        AND SZSTUME_MDLE_ID IS NOT NULL
        GROUP BY SZSTUME_PIDM,SZSTUME_ID, SZSTUME_MDLE_ID, SZTGPME_PTRM_CODE_COMP, SZTGPME_CRSE_MDLE_ID, SZTGPME_NO_REGLA, SZSTUME_START_DATE--, COL3
        ORDER BY 7 ASC;

         RETURN (c_out_grades);
      END;
   END f_sync_grades_moodle;


       FUNCTION f_update_sync_grades_moodle (p_pidm in number, p_no_regla in number, p_crse_moodle in number, p_aula in varchar2, p_grade in varchar2, p_obs in varchar2) Return Varchar2
       IS

       vl_grade Varchar2(10);
       vl_grade_final Varchar2(10);
       vl_error Varchar2(200):= Null;
       vl_type Varchar2(6);
       vl_obs Varchar2(500);
       vl_date_actual date;
       vl_ind number:=0;
       vl_st_doc varchar2(2):=null;
       --vl_rsts Varchar2(2);
-- SIBINST_FCST_CODE = AC --docente activo(MA)
     BEGIN

       BEGIN

        FOR c IN (SELECT
                SZSTUME_PIDM pidm,
                SZSTUME_MDLE_ID user_moodle_id,
                CASE WHEN SZTGPME_CAMP_CODE = 'UTS'
                THEN 'UTL'
                WHEN SZTGPME_CAMP_CODE IN (SELECT ZSTPARA_PARAM_VALOR
                                FROM ZSTPARA
                                WHERE 1=1
                                AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                THEN 'UTL'
                WHEN SZTGPME_CAMP_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                FROM ZSTPARA
                                WHERE 1=1
                                AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                THEN SZTGPME_CAMP_CODE
                END camp_code,
                CASE WHEN SZTGPME_LEVL_CODE = 'MS'
                THEN 'MA'
                WHEN SZTGPME_LEVL_CODE <> 'MS'
                THEN SZTGPME_LEVL_CODE
                END levl_code,
                SZTGPME_TERM_NRC term_nrc,
                SUBSTR(SZTGPME_SUBJ_CRSE,0,3)vtype,
                SZTGPME_NO_REGLA regla,
                SZSTUME_START_DATE start_date,
                nvl(ESTATUS,'MA') stst
                FROM SZTGPME  left join SZSTUME c on  SZTGPME_TERM_NRC = c.SZSTUME_TERM_NRC
                left join TZTPROG a on c.SZSTUME_PIDM = a.PIDM and   a.SP = (SELECT MAX(b.SP)
                            FROM TZTPROG b
                            WHERE 1=1
                            AND a.PIDM = b.PIDM)
                WHERE 1=1
                AND SZTGPME_NO_REGLA = c.SZSTUME_NO_REGLA                
                AND SZTGPME_START_DATE = c.SZSTUME_START_DATE
                AND c.SZSTUME_PIDM = p_pidm
                AND SZTGPME_NO_REGLA = p_no_regla
                AND SZTGPME_CRSE_MDLE_ID = p_crse_moodle
                AND SZTGPME_PTRM_CODE_COMP = p_aula
                AND c.SZSTUME_PTRM = '0'

              )

            LOOP

                vl_grade_final := null;
                vl_type:= NULL;
                vl_obs:= NULL;

                if c.regla = '1' then --docentes cursando diplomados
                    begin
                     select SIBINST_FCST_CODE
                     into vl_st_doc
                     from SIBINST
                     where SIBINST_FCST_CODE = 'IN'
                       and SIBINST_PIDM = p_pidm;
                      Exception
                         When Others then
                         vl_st_doc := '';    
                    end;
                end if;

                 IF p_grade IS NULL AND c.stst NOT IN ('MA', 'TR', 'PR', 'EG', 'SG')THEN
                      vl_grade :=  '0.00';    
                      vl_obs:= p_obs;
                  ELSIF p_grade IS NULL THEN
                      vl_grade :=  '0.00';
                      vl_obs:= p_obs;               
                  ELSIF vl_st_doc = 'IN' and c.regla = '1' THEN --   ELSIF vl_st_doc != 'AC' THEN
                      vl_grade :=  '0.00';
                      vl_obs:= p_obs;
                  ELSE
                      vl_grade := p_grade;
                      vl_obs:= p_obs;
                 END IF;


             /*   IF c.regla <> '99' THEN

                    vl_type := 'OR';

                ELSIF c.regla = '99' THEN

                    vl_type := 'NIV';

                END IF;*/

/*
                IF c.vtype IN ('SEL','IEB','MOD') THEN

                    vl_type := c.vtype;

                ELSE
                    vl_type:= vl_type;

                END IF;

*/
                begin  --Obtiene el type de las excepciones
                    select ZSTPARA_PARAM_ID
                    into vl_type
                    from zstpara
                    where
                        ZSTPARA_MAPA_ID = 'CALIF_MATERIA' AND
                        ZSTPARA_PARAM_ID = c.vtype;
                   Exception
                     When Others then
                     vl_type := '';     
                      
                end;
                
                if vl_type is null then --Regla 1 y 99
                    begin
                           select ZSTPARA_PARAM_VALOR
                                into vl_type
                            from zstpara
                            where
                                ZSTPARA_MAPA_ID = 'EXC_CALIF' AND
                                ZSTPARA_PARAM_ID = to_char(c.regla);
                         
                        Exception
                         When Others then
                         vl_type := '';
                         vl_error := 'No existe datos '||vl_type||'Near of Line...8170';
                    end;                 
                 end if;   
                 if vl_type is null then
                    vl_type := 'OR';
                 end if;

 --DBMS_OUTPUT.PUT_LINE('p_ grade  '||vl_grade || vl_grade_final ||' vl_type ' ||vl_type ||' regla ' ||c.regla ||' vl_st_doc '|| vl_st_doc);

                vl_ind:= null;
                vl_date_actual:= null;

                BEGIN
                SELECT TRUNC(SYSDATE)
                INTO vl_date_actual
                FROM DUAL;
                END;
                
                 --     DBMS_OUTPUT.PUT_LINE('Entara a validaciÛn la calificaciÛn prueba'|| vl_grade);

                 IF p_grade = '0.00'  AND c.regla = '99' AND vl_date_actual >=  c.start_date THEN
                  vl_ind:=1;
                 ELSIF p_grade != '0.00' OR c.regla != '99' THEN
                    vl_ind:=1;                 
                 ELSE
                    vl_ind:=0;
                 END IF;
                 
                 IF vl_st_doc = 'IN' and c.regla = '1' THEN --Para grupos de docentes, cuando son inactivos no debe asignar calificaciÛn
                    vl_ind:=0;
                 end if;   


                 IF vl_ind = 1 THEN

                     BEGIN
                        SELECT distinct SZTRNDO_GRDE
                        Into   vl_grade_final
                        FROM SZTRNDO
                        WHERE SZTRNDO_CAMP_CODE = c.camp_code
                        AND SZTRNDO_LEVL_CODE = c.levl_code
                        AND SZTRNDO_CTGRY = c.camp_code||c.levl_code||vl_type                       
                        AND ROUND(vl_grade,2) BETWEEN SZTRNDO_MIN_GRDE AND SZTRNDO_MAX_GRDE ;
                     Exception
                     When Others then
                     vl_grade_final := 'ERCONV';
                     vl_error := 'No existe calificaciÛn o conversion de calificacion '||vl_grade||'Near of Line...6571';
                     END;


                     BEGIN
                        UPDATE SZSTUME SET SZSTUME_TERM_NRC_COMP = vl_grade, SZSTUME_GRDE_CODE_FINAL = vl_grade_final,
                        SZSTUME_PTRM = '1', SZSTUME_ACTIVITY_DATE = SYSDATE, SZSTUME_OBS = vl_obs||' '||USER||'|| sync_grades'
                        WHERE 1=1
                        AND SZSTUME_PIDM = c.pidm  --'010007241'--'010302086'--'010007241'
                        AND SZSTUME_MDLE_ID = c.user_moodle_id
                        AND SZSTUME_TERM_NRC = c.term_nrc
                        AND SZSTUME_NO_REGLA = c.regla
                        AND SZSTUME_START_DATE = c.start_date;
                     vl_error :='Registro actualizado';
                     Exception
                     When others then
                     vl_error := 'Error al actualizar grade SZSTUME '||sqlerrm||' Near of Line...6591';
                     END;
                  COMMIT;

                 ELSIF vl_ind = 0 THEN

                 Null;

                 END IF;



            END LOOP;
       EXCEPTION
       WHEN OTHERS THEN
       vl_error := sqlerrm||': Error general Near of Line...6598';
       END;
       Return(vl_error);
     END f_update_sync_grades_moodle;


     FUNCTION f_update_tmp_sync (p_stat in number, p_no_regla in number,  p_start_date in varchar2, p_process in varchar2) Return Varchar2
     IS

   vl_return varchar(50);

    BEGIN


        IF  p_stat IN (1, 2,3) and p_no_regla IS NOT NULL AND p_start_date IS NOT NULL THEN

          vl_return:= p_stat;

           BEGIN
            UPDATE TMP_SYNC_STATUS SET  STAT_IND = p_stat, PROCESS = p_process
            WHERE 1=1
            AND REGLA = p_no_regla
            AND START_DATE = p_start_date;
           EXCEPTION
           WHEN OTHERS THEN
           vl_return:=0;
           return(vl_return);
           END;
           COMMIT;

        ELSIF p_stat = 4 and p_no_regla IS NOT NULL AND p_start_date IS NOT NULL THEN

          vl_return:= p_stat;

           BEGIN
            UPDATE TMP_SYNC_STATUS SET  STAT_IND = p_stat, PROCESS = p_process
            WHERE 1=1
            AND REGLA = p_no_regla
            AND START_DATE = p_start_date;
           EXCEPTION
           WHEN OTHERS THEN
           vl_return:=0;
           return(vl_return);
           END;
           COMMIT;

        ELSIF p_stat = 0 THEN

            vl_return:= p_stat;

        END IF;
       return(vl_return);

     END f_update_tmp_sync;



   FUNCTION f_update_intermedia (p_pidm in number, p_no_regla in number, p_fecha_inicio in date, p_grupo in varchar2, p_secuencia in number) Return Varchar2
   IS

      vl_error Varchar2(200):= 'Exito';

   Begin
                 BEGIN

                       Update SZSTUME
                       set SZSTUME_PTRM = '2'
                       Where SZSTUME_PIDM = p_pidm
                       And SZSTUME_TERM_NRC = p_grupo
                       And SZSTUME_SEQ_NO = p_secuencia
                       And SZSTUME_NO_REGLA  = p_no_regla
                       And  trunc (SZSTUME_START_DATE) = p_fecha_inicio;

                      Return(vl_error);
                      Commit;
                 EXCEPTION
                    WHEN OTHERS THEN  vl_error := sqlerrm||': Error al actualizar el estatus de la calificacion xxx';
                    Return(vl_error);
                 END;

   END f_update_intermedia;

-- FIN FUNCIONONES ACTUAL UTILIZADO PARA SINCRONIZAR CALIFICACIONES CON MOODLE--



   FUNCTION f_update_horario (p_no_regla in number, p_fecha_inicio in date) Return Varchar2
   IS

          v_sal     VARCHAR2(2500) := 'Exito';
         v_salida     VARCHAR2(2500) := 'Exito';
         vl_existe NUMBER := 0;
          v_proc     VARCHAR2(2500) := null;
          v_fecha_inicio VARCHAR2(12) := null;


   Begin

            --v_fecha_inicio := trunc (p_fecha_inicio,'dd/mm/rrrr');


            If trim (p_no_regla) not in (99)  then


                        Begin

                                       For cx in (


                                                    select distinct a.SZSTUME_PIDM Pidm,
                                                                            a.SZSTUME_ID Matricula,
                                                                            a.SZSTUME_GRDE_CODE_FINAL Calificacion,
                                                                            a.SZSTUME_START_DATE Fecha_Inicio,
                                                                            b.SFRSTCR_TERM_CODE Periodo,
                                                                            b.SFRSTCR_CRN CRN ,
                                                                            b.sfrstcr_CAMP_CODE Campus,
                                                                            b.sfrstcr_LEVL_CODE Nivel,
                                                                            a.SZSTUME_SEQ_NO Secuencia,
                                                                            a.SZSTUME_NO_REGLA Regla,
                                                                            a.SZSTUME_TERM_NRC grupo
                                                        from SZSTUME a
                                                        join sfrstcr b on b.sfrstcr_pidm = a.SZSTUME_PIDM and b.SFRSTCR_RSTS_CODE = a.SZSTUME_RSTS_CODE --and b.SFRSTCR_GRDE_CODE is null
                                                        join ssbsect c  on c. SSBSECT_TERM_CODE = b.SFRSTCR_TERM_CODE
                                                                        and c.SSBSECT_CRN = b.SFRSTCR_CRN
                                                                        and trunc (c.SSBSECT_PTRM_START_DATE)  = trunc (a.SZSTUME_START_DATE)
                                                                      --  And c.SSBSECT_SEQ_NUMB ='01'
                                                         join sztprono d on d.SZTPRONO_PIDM = a.SZSTUME_PIDM
                                                                        and trunc (d.SZTPRONO_FECHA_INICIO) =  trunc (a.SZSTUME_START_DATE)
                                                                    --    and SZTPRONO_ENVIO_HORARIOS ='S'
                                                                       and d.sztprono_materia_banner =  c.SSBSECT_SUBJ_CODE||c.SSBSECT_CRSE_NUMB
                                                                       and d.SZTPRONO_MATERIA_LEGAL = a.SZSTUME_SUBJ_CODE
                                                        where 1= 1
                                                        And a.SZSTUME_NO_REGLA = trim (p_no_regla)
                                                       And  trunc (a.SZSTUME_START_DATE) = p_fecha_inicio
                                                        And a.SZSTUME_STAT_IND = '1'
                                                        And a.SZSTUME_PTRM = '1'
                                                       And a.SZSTUME_RSTS_CODE ='RE'
                                                    --    And  a.SZSTUME_ID= p_matricula
                                                        And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                                    from SZSTUME a1
                                                                                                    Where a.SZSTUME_PIDM  = a1.SZSTUME_PIDM
                                                                                                    and a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                                                                    And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                                                                    )
                                                        order by 1, 11




                                        ) loop



                                                  BEGIN
                                                      UPDATE sfrstcr
                                                      SET  sfrstcr_grde_code = cx.calificacion,
                                                             sfrstcr_data_origin = 'CALIFICA_MOODLE',
                                                             sfrstcr_activity_date = SYSDATE,
                                                             sfrstcr_grde_date = SYSDATE,
                                                             sfrstcr_rsts_code = 'RE'
                                                      WHERE  sfrstcr_term_code = cx.periodo
                                                             AND sfrstcr_crn = cx.crn
                                                             AND sfrstcr_pidm = cx.pidm;

                                                      COMMIT;

                                                  EXCEPTION
                                                      WHEN OTHERS THEN
                                                        dbms_output.Put_line('Error al actulizar Calficacion '
                                                                             ||SQLERRM);
                                                  END;


                                                   ------------------- Valido que exista el registro en las historias Academicas -----------------------
                                                  vl_existe := 0;

                                                  BEGIN
                                                      SELECT Count(1)
                                                      INTO   vl_existe
                                                      FROM   shrtckn
                                                      WHERE  shrtckn_pidm = cx.pidm
                                                             AND shrtckn_term_code = cx.periodo
                                                             AND shrtckn_crn = cx.crn;
                                                  EXCEPTION
                                                      WHEN OTHERS THEN
                                                        vl_existe := 0;
                                                  END;


                                -------------------------------------------------------------------
                                                IF vl_existe >= 1 THEN

                                                                    BEGIN
                                                                        UPDATE shrtckg
                                                                        SET    shrtckg_grde_code_final = cx.calificacion
                                                                        WHERE  ( shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no ) IN ( SELECT shrtckn_pidm,  shrtckn_term_code,  shrtckn_seq_no
                                                                                                                                                                                FROM shrtckn
                                                                                                                                                                                 WHERE shrtckn_pidm = cx.pidm
                                                                                                                                                                                  AND shrtckn_term_code = cx.periodo
                                                                                                                                                                                  AND shrtckn_crn = cx.crn);
                                                                        Commit;
                                                                         v_sal:=PKG_MOODLE2.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                                      --   dbms_output.Put_line('SALIDA 1' || v_sal);

                                                                    EXCEPTION
                                                                        WHEN OTHERS THEN
                                                                          dbms_output.Put_line('Error al actulizar historia ' ||cx.periodo ||'*'|| cx.crn ||'*'|| cx.pidm  ||'*' ||v_sal ||'*'||SQLERRM);
                                                                    END;
                                                ELSE
                                                                    v_sal := pkg_moodle2.F_pase_historia_califica (cx.campus, cx.nivel, cx.periodo, cx.crn, cx.pidm); --- Envia a Historia Academica
                                                                 --    dbms_output.Put_line('SALIDA 2' || v_sal);
                                                                     v_sal:=PKG_MOODLE2.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                END IF;

                                End Loop;


                                 v_proc:=PKG_MOODLE2.F_UPDATE_TMP_SYNC ( 2, trim (p_no_regla), trunc (p_fecha_inicio), 'rolado_calificaciones' );
                              --   dbms_output.Put_line('SALIDA 4' || v_proc);

                                  Return(v_salida);
                                  Commit;
                        EXCEPTION
                                WHEN OTHERS THEN  v_sal := sqlerrm||': Error al actualizar el estatus de la calificacion yyy';
                                Return(v_sal);
                        END;

            Elsif trim (p_no_regla) = 99 then

                        Begin
                                       For cx in (

                                                        select distinct a.SZSTUME_PIDM Pidm,
                                                        a.SZSTUME_ID Matricula,
                                                        a.SZSTUME_GRDE_CODE_FINAL Calificacion,
                                                        a.SZSTUME_SUBJ_CODE Materia_Padre,
                                                        --        d.sztprono_materia_banner Materia_Hijo,
                                                        a.SZSTUME_START_DATE Fecha_Inicio,
--                                                        substr (SVRSVAD_ADDL_DATA_DESC, 1, 10) Fecha_examen,
                                                        c.SSBSECT_PTRM_START_DATE fecha_inicio_1,
                                                        b.SFRSTCR_TERM_CODE Periodo,
                                                        b.SFRSTCR_CRN CRN ,
                                                        b.sfrstcr_CAMP_CODE Campus,
                                                        b.sfrstcr_LEVL_CODE Nivel,
                                                        substr (a.SZSTUME_TERM_NRC, length (a.SZSTUME_TERM_NRC) -1,length (a.SZSTUME_TERM_NRC))  Grupo_1,
                                                        a.SZSTUME_TERM_NRC grupo,
                                                        a.SZSTUME_SEQ_NO Secuencia,
                                                        a.SZSTUME_NO_REGLA Regla,
                                                        SZSTUME_POBI_SEQ_NO
                                                        from SZSTUME a
                                                        join sfrstcr b on b.sfrstcr_pidm = a.SZSTUME_PIDM and b.SFRSTCR_RSTS_CODE = a.SZSTUME_RSTS_CODE and substr (SFRSTCR_TERM_CODE, 5,1) ='8'
                                                        join ssbsect c  on c. SSBSECT_TERM_CODE = b.SFRSTCR_TERM_CODE and c.SSBSECT_CRN = b.SFRSTCR_CRN
                                                        join SVRSVPR on SVRSVPR_pidm = a.SZSTUME_PIDM  and SVRSVPR_SRVC_CODE in ('NIVE','NIVG')
--                                                        join SVRSVAD on SVRSVAD_PROTOCOL_SEQ_NO = SVRSVPR_PROTOCOL_SEQ_NO ANd SVRSVAD_ADDL_DATA_SEQ ='7'  And SVRSVAD_PROTOCOL_SEQ_NO = SZSTUME_POBI_SEQ_NO
                                                        where a.SZSTUME_NO_REGLA = trim (p_no_regla)
                                                       And  trunc (a.SZSTUME_START_DATE) = p_fecha_inicio
--                                                        and trunc (c.SSBSECT_PTRM_START_DATE)  =substr (SVRSVAD_ADDL_DATA_DESC, 1, 10)
                                                        And a.SZSTUME_STAT_IND = '1'
                                                        And a.SZSTUME_PTRM = '1'
                                                        And a.SZSTUME_RSTS_CODE ='RE'
                                                       -- And  a.SZSTUME_ID='010003336'
                                                        And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                                    from SZSTUME a1
                                                                                                    Where a.SZSTUME_PIDM  = a1.SZSTUME_PIDM
                                                                                                    And a.SZSTUME_STAT_IND = a1.SZSTUME_STAT_IND
                                                                                                    And a.SZSTUME_PTRM = a1.SZSTUME_PTRM
                                                                                                    And a.SZSTUME_RSTS_CODE = a1.SZSTUME_RSTS_CODE
                                                                                                    And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                                                                    And trunc (a.SZSTUME_START_DATE) = trunc (a1.SZSTUME_START_DATE)
                                                                                                    )
                                                        order by 2
                                ) loop


                                                  BEGIN
                                                      UPDATE sfrstcr
                                                      SET  sfrstcr_grde_code = cx.calificacion,
                                                             sfrstcr_data_origin = 'CALIFICA_MOODLE',
                                                             sfrstcr_activity_date = SYSDATE,
                                                             sfrstcr_grde_date = SYSDATE,
                                                             sfrstcr_rsts_code = 'RE'
                                                      WHERE  sfrstcr_term_code = cx.periodo
                                                             AND sfrstcr_crn = cx.crn
                                                             AND sfrstcr_pidm = cx.pidm;

                                                      COMMIT;

                                                  EXCEPTION
                                                      WHEN OTHERS THEN
                                                        dbms_output.Put_line('Error al actulizar Calficacion11'
                                                                             ||SQLERRM);
                                                  END;


                                                   ------------------- Valido que exista el registro en las historias Academicas -----------------------
                                                  vl_existe := 0;

                                                  BEGIN
                                                      SELECT Count(1)
                                                      INTO   vl_existe
                                                      FROM   shrtckn
                                                      WHERE  shrtckn_pidm = cx.pidm
                                                             AND shrtckn_term_code = cx.periodo
                                                             AND shrtckn_crn = cx.crn;
                                                  EXCEPTION
                                                      WHEN OTHERS THEN
                                                        vl_existe := 0;
                                                  END;


                                -------------------------------------------------------------------
                                                IF vl_existe >= 1 THEN

                                                                    BEGIN
                                                                        UPDATE shrtckg
                                                                        SET    shrtckg_grde_code_final = cx.calificacion
                                                                        WHERE  ( shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no ) IN ( SELECT shrtckn_pidm,  shrtckn_term_code,  shrtckn_seq_no
                                                                                                                                                                                FROM shrtckn
                                                                                                                                                                                 WHERE shrtckn_pidm = cx.pidm
                                                                                                                                                                                  AND shrtckn_term_code = cx.periodo
                                                                                                                                                                                  AND shrtckn_crn = cx.crn);
                                                                        Commit;
                                                                         v_sal:=PKG_MOODLE2.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                                      --   dbms_output.Put_line('SALIDA 1' || v_sal);

                                                                    EXCEPTION
                                                                        WHEN OTHERS THEN
                                                                                dbms_output.Put_line('Error al actulizar Calficacion22'
                                                                             ||SQLERRM);
                                                                    END;
                                                ELSE
                                                                    v_sal := pkg_moodle2.F_pase_historia_califica (cx.campus, cx.nivel, cx.periodo, cx.crn, cx.pidm); --- Envia a Historia Academica
                                                                 --    dbms_output.Put_line('SALIDA 2' || v_sal);
                                                                     v_sal:=PKG_MOODLE2.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                END IF;

                                End Loop;

                                 v_proc:=PKG_MOODLE2.F_UPDATE_TMP_SYNC ( 2, trim (p_no_regla), trunc (p_fecha_inicio), 'rolado_calificaciones' );
                              --   dbms_output.Put_line('SALIDA 4' || v_proc);
                                  Return(v_salida);
                                  Commit;
                        EXCEPTION
                                WHEN OTHERS THEN  v_sal := sqlerrm||': Error al actualizar el estatus de la calificacion 333' || v_fecha_inicio;
                                Return(v_salida);
                        END;



            End if;



   End f_update_horario;


PROCEDURE SP_SYNC_MOOLDE_ERR2 IS

  BEGIN

  FOR a IN (
   SELECT a.SZSTUME_NO_REGLA regla
    FROM SZSTUME a
    WHERE 1=1
    AND TO_CHAR(SZSTUME_ACTIVITY_DATE,'dd/mm/yyyy') >= TRUNC(SYSDATE)
    GROUP BY a.SZSTUME_NO_REGLA
    ORDER BY SZSTUME_NO_REGLA ASC
    )
     LOOP
       FOR c in (
            SELECT a.SZSTUME_PIDM pidm, a.SZSTUME_ID matricula, a.SZSTUME_STAT_IND stat_ind, a.SZSTUME_TERM_NRC term_nrc, a.SZSTUME_NO_REGLA regla, a.SZSTUME_START_DATE start_date, a.SZSTUME_SEQ_NO seqno
            FROM SZSTUME a
            WHERE 1=1
            AND a.SZSTUME_STAT_IND = '2'
            AND SZSTUME_OBS LIKE ('%al escribir a la base de datos%') OR SZSTUME_OBS like ('%en el WS al intentar Crear Alumno%')
            AND a.SZSTUME_NO_REGLA = a.regla
            ORDER BY 4 ASC
            )

            loop

                    BEGIN
                        --dbms_output.put_line('hi '||c.term_nrc);
                        --/*
                        UPDATE SZSTUME SET SZSTUME_STAT_IND ='0', SZSTUME_ACTIVITY_DATE = SYSDATE, SZSTUME_USER_ID = USER
                        WHERE 1=1
                        AND SZSTUME_PIDM = c.pidm
                        --AND SZSTUME_ID = c.matricula --p_matricula
                        AND SZSTUME_NO_REGLA = c.regla
                        AND SZSTUME_TERM_NRC = c.term_nrc
                        AND SZSTUME_START_DATE = c.start_date
                        AND SZSTUME_SEQ_NO = c.seqno;
                   EXCEPTION
                   WHEN OTHERS THEN ROLLBACK;
                   END;

                   BEGIN

                    UPDATE GOZTPAC SET GOZTPAC_STAT_IND = '1'
                    WHERE 1 = 1
                    AND GOZTPAC_PIDM = c.pidm
                    AND GOZTPAC_STAT_IND ='2';
                   EXCEPTION
                   WHEN OTHERS THEN ROLLBACK;
                   END;

            END LOOP;
           COMMIT;
     END LOOP;

  END;

 FUNCTION f_valida_contraseÒa_docentes(p_regla in number)return  varchar
 is
    VL_CONT2 NUMBER;
    VL_PASS2 VARCHAR(600);

        BEGIN
            FOR C IN
                    ( SELECT SZTCONF_PIDM PIDM,SZTCONF_ID MATRICULA
                       FROM SZTCONF
                       WHERE 1=1
                       AND SZTCONF_NO_REGLA=P_REGLA
                       )

              LOOP
                   VL_CONT2:=null;
                   BEGIN

                     SELECT COUNT (GOZTPAC_PIDM)
                             INTO VL_CONT2
                             FROM GOZTPAC
                             WHERE 1=1
                             AND GOZTPAC_PIDM=C.PIDM
                             and GOZTPAC_PIN is null;
                     EXCEPTION WHEN OTHERS THEN
                         VL_CONT2:=0;
                   END;

                    IF VL_CONT2=1 THEN
                           BEGIN
                                UPDATE GOZTPAC
                                SET  GOZTPAC_PIN=BANINST1.SHA1(c.matricula)
                                WHERE 1=1
                                AND  GOZTPAC_PIDM=C.PIDM ;
                           EXCEPTION WHEN OTHERS THEN
                                 NULL;
                           END;

                    ELSIF VL_CONT2=0 THEN
                    VL_PASS2:=null;

                           BEGIN

                            VL_PASS2:= BANINST1.SHA1(c.matricula);

                             EXCEPTION WHEN OTHERS THEN
                             NULL;

                           END;

                           BEGIN
                                     INSERT INTO GOZTPAC VALUES
                                                     (
                                                     C.PIDM,
                                                     C.MATRICULA,
                                                     VL_PASS2,
                                                     'N',
                                                     'N',
                                                     '1'
                                                     );
                            --DBMS_OUTPUT.PUT_LINE('INSERTA GOZTPAC'||' '||VL_PASS2);
                           EXCEPTION WHEN OTHERS THEN
                             NULL;
                           END;
                    END IF;
              END LOOP;
           COMMIT;
           RETURN 'exito';
        END f_valida_contraseÒa_docentes;


         FUNCTION f_email_update_docentes RETURN PKG_MOODLE2.cursor_eud_out
        AS email_out PKG_MOODLE2.cursor_eud_out;

     BEGIN

        BEGIN

            OPEN email_out FOR
             SELECT C.SZTBIMA_PIDM pidm,
                    C.SZTBIMA_ID matricula,
                    C.SZTBIMA_FIRST_NAME nombre,
                    REPLACE(C.SZTBIMA_LAST_NAME,'/', ' ') apellido,
                    C.SZTBIMA_EMAIL_ADDRESS EMAIL,
                    CASE WHEN
                     C.SZTBIMA_PROCESO = 'SPRIDEN'THEN
                       'name'
                     WHEN
                     C.SZTBIMA_PROCESO = 'GOREMAL' THEN
                        'mail'
                     END dato
               FROM SZTBIMA C
            WHERE 1=1
            AND C.SZTBIMA_PROCESO IN ('GOREMAL', 'SPRIDEN')
            AND C.SZTBIMA_STATUS_IND ='7'
            --AND C.SZTBIMA_ID LIKE '0198%'
            AND C.SZTBIMA_FECHA_ACTUALIZA = (SELECT MAX(D.SZTBIMA_FECHA_ACTUALIZA)
                                           FROM SZTBIMA D
                                           WHERE 1=1
                                           AND C.SZTBIMA_PIDM = D.SZTBIMA_PIDM
                                           AND C.SZTBIMA_PROCESO = D.SZTBIMA_PROCESO);
        END;
        RETURN(email_out);

      END f_email_update_docentes;



FUNCTION f_email_update_bima (P_PIDM NUMBER, P_OBS VARCHAR2,P_DATO in VARCHAR2, P_ESTATUS VARCHAR2)RETURN VARCHAR2
    AS
    vl_error VARCHAR2(500):='EXITO';
    vl_dato Varchar2(30);
    vl_estatus Varchar2(1);

      BEGIN


          IF p_dato = 'name'THEN
               vl_dato:= 'SPRIDEN';
            ELSIF p_dato ='mail' THEN
               vl_dato:= 'GOREMAL';
           END IF;

            vl_estatus := NULL;
            vl_estatus:= P_ESTATUS;

             IF vl_estatus = '7'

             THEN vl_estatus :='0';

             ELSE

             vl_estatus := vl_estatus;

             END IF;


            BEGIN
              UPDATE SZTBIMA
              SET SZTBIMA_STATUS_IND = P_ESTATUS,
               SZTBIMA_OBSERVACIONES = P_OBS,
               SZTBIMA_FECHA_ACTUALIZA = SYSDATE,
               SZTBIMA_USUARIO_ACTUALIZA = USER
              WHERE 1=1
              AND SZTBIMA_PIDM=P_PIDM
              AND SZTBIMA_PROCESO = vl_dato
--              AND SZTBIMA_OBSERVACIONES='REG_ACT'
              ;

                EXCEPTION
                    WHEN OTHERS THEN
                    vl_error:= 'Error'||sqlerrm;
                    rollback;
             END;

       commit;
       return(vl_error);

     END f_email_update_bima;


 FUNCTION f_update_horario_matricula (p_no_regla in number, p_fecha_inicio in date, p_matricula in varchar2) Return Varchar2
   IS

          v_sal     VARCHAR2(2500) := 'Exito';
         v_salida     VARCHAR2(2500) := 'Exito';
         vl_existe NUMBER := 0;
          v_proc     VARCHAR2(2500) := null;
          v_fecha_inicio VARCHAR2(12) := null;


   Begin

            --v_fecha_inicio := trunc (p_fecha_inicio,'dd/mm/rrrr');


            If trim (p_no_regla) not in (99)  then


                        Begin

                                       For cx in (

                                                                        select distinct a.SZSTUME_PIDM Pidm,
                                                                            a.SZSTUME_ID Matricula,
                                                                            a.SZSTUME_GRDE_CODE_FINAL Calificacion,
                                                                            a.SZSTUME_START_DATE Fecha_Inicio,
                                                                            b.SFRSTCR_TERM_CODE Periodo,
                                                                            b.SFRSTCR_CRN CRN ,
                                                                            b.sfrstcr_CAMP_CODE Campus,
                                                                            b.sfrstcr_LEVL_CODE Nivel,
                                                                            a.SZSTUME_SEQ_NO Secuencia,
                                                                            a.SZSTUME_NO_REGLA Regla,
                                                                            a.SZSTUME_TERM_NRC grupo
                                                        from SZSTUME a
                                                        join sfrstcr b on b.sfrstcr_pidm = a.SZSTUME_PIDM and b.SFRSTCR_RSTS_CODE = a.SZSTUME_RSTS_CODE --and b.SFRSTCR_GRDE_CODE is null
                                                        join ssbsect c  on c. SSBSECT_TERM_CODE = b.SFRSTCR_TERM_CODE
                                                                        and c.SSBSECT_CRN = b.SFRSTCR_CRN
                                                                        and trunc (c.SSBSECT_PTRM_START_DATE)  = trunc (a.SZSTUME_START_DATE)
                                                                      --  And c.SSBSECT_SEQ_NUMB ='01'
                                                         join sztprono d on d.SZTPRONO_PIDM = a.SZSTUME_PIDM
                                                                        and trunc (d.SZTPRONO_FECHA_INICIO) =  trunc (a.SZSTUME_START_DATE)
                                                                       -- and SZTPRONO_ENVIO_HORARIOS ='S'
                                                                       and d.sztprono_materia_banner =  c.SSBSECT_SUBJ_CODE||c.SSBSECT_CRSE_NUMB
                                                                       and d.SZTPRONO_MATERIA_LEGAL = a.SZSTUME_SUBJ_CODE
                                                        where 1= 1
                                                        And a.SZSTUME_NO_REGLA = trim (p_no_regla)
                                                       And  trunc (a.SZSTUME_START_DATE) = p_fecha_inicio
                                                        And a.SZSTUME_STAT_IND = '1'
                                                        And a.SZSTUME_PTRM = '1'
                                                       And a.SZSTUME_RSTS_CODE ='RE'
                                                        And  a.SZSTUME_ID= p_matricula
                                                        And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                                    from SZSTUME a1
                                                                                                    Where a.SZSTUME_PIDM  = a1.SZSTUME_PIDM
                                                                                                    and a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                                                                    And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                                                                    )
                                                        order by 1, 11



                                        ) loop



                                                  BEGIN
                                                      UPDATE sfrstcr
                                                      SET  sfrstcr_grde_code = cx.calificacion,
                                                             sfrstcr_data_origin = 'CALIFICA_MOODLE',
                                                             sfrstcr_activity_date = SYSDATE,
                                                             sfrstcr_grde_date = SYSDATE,
                                                             sfrstcr_rsts_code = 'RE'
                                                      WHERE  sfrstcr_term_code = cx.periodo
                                                             AND sfrstcr_crn = cx.crn
                                                             AND sfrstcr_pidm = cx.pidm;

                                                      COMMIT;

                                                  EXCEPTION
                                                      WHEN OTHERS THEN
                                                        dbms_output.Put_line('Error al actulizar Calficacion '
                                                                             ||SQLERRM);
                                                  END;


                                                   ------------------- Valido que exista el registro en las historias Academicas -----------------------
                                                  vl_existe := 0;

                                                  BEGIN
                                                      SELECT Count(1)
                                                      INTO   vl_existe
                                                      FROM   shrtckn
                                                      WHERE  shrtckn_pidm = cx.pidm
                                                             AND shrtckn_term_code = cx.periodo
                                                             AND shrtckn_crn = cx.crn;
                                                  EXCEPTION
                                                      WHEN OTHERS THEN
                                                        vl_existe := 0;
                                                  END;


                                -------------------------------------------------------------------
                                                IF vl_existe >= 1 THEN

                                                                    BEGIN
                                                                        UPDATE shrtckg
                                                                        SET    shrtckg_grde_code_final = cx.calificacion
                                                                        WHERE  ( shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no ) IN ( SELECT shrtckn_pidm,  shrtckn_term_code,  shrtckn_seq_no
                                                                                                                                                                                FROM shrtckn
                                                                                                                                                                                 WHERE shrtckn_pidm = cx.pidm
                                                                                                                                                                                  AND shrtckn_term_code = cx.periodo
                                                                                                                                                                                  AND shrtckn_crn = cx.crn);
                                                                        Commit;
                                                                         v_sal:=PKG_MOODLE2.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                                      --   dbms_output.Put_line('SALIDA 1' || v_sal);

                                                                    EXCEPTION
                                                                        WHEN OTHERS THEN
                                                                          dbms_output.Put_line('Error al actulizar historia ' ||cx.periodo ||'*'|| cx.crn ||'*'|| cx.pidm  ||'*' ||v_sal ||'*'||SQLERRM);
                                                                    END;
                                                ELSE
                                                                    v_sal := pkg_moodle2.F_pase_historia_califica (cx.campus, cx.nivel, cx.periodo, cx.crn, cx.pidm); --- Envia a Historia Academica
                                                                 --    dbms_output.Put_line('SALIDA 2' || v_sal);
                                                                     v_sal:=PKG_MOODLE2.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                END IF;

                                End Loop;


                                 v_proc:=PKG_MOODLE2.F_UPDATE_TMP_SYNC ( 2, trim (p_no_regla), trunc (p_fecha_inicio), 'rolado_calificaciones' );
                              --   dbms_output.Put_line('SALIDA 4' || v_proc);

                                  Return(v_salida);
                                  Commit;
                        EXCEPTION
                                WHEN OTHERS THEN  v_sal := sqlerrm||': Error al actualizar el estatus de la calificacion yyy';
                                Return(v_sal);
                        END;

            Elsif trim (p_no_regla) = 99 then

                        Begin



                                       For cx in (

                                                        select distinct a.SZSTUME_PIDM Pidm,
                                                        a.SZSTUME_ID Matricula,
                                                        a.SZSTUME_GRDE_CODE_FINAL Calificacion,
                                                        a.SZSTUME_SUBJ_CODE Materia_Padre,
                                                        --        d.sztprono_materia_banner Materia_Hijo,
                                                        a.SZSTUME_START_DATE Fecha_Inicio,
                                                        substr (SVRSVAD_ADDL_DATA_DESC, 1, 10) Fecha_examen,
                                                        c.SSBSECT_PTRM_START_DATE fecha_inicio_1,
                                                        b.SFRSTCR_TERM_CODE Periodo,
                                                        b.SFRSTCR_CRN CRN ,
                                                        b.sfrstcr_CAMP_CODE Campus,
                                                        b.sfrstcr_LEVL_CODE Nivel,
                                                        substr (a.SZSTUME_TERM_NRC, length (a.SZSTUME_TERM_NRC) -1,length (a.SZSTUME_TERM_NRC))  Grupo_1,
                                                        a.SZSTUME_TERM_NRC grupo,
                                                        a.SZSTUME_SEQ_NO Secuencia,
                                                        a.SZSTUME_NO_REGLA Regla,
                                                        SZSTUME_POBI_SEQ_NO
                                                        from SZSTUME a
                                                        join sfrstcr b on b.sfrstcr_pidm = a.SZSTUME_PIDM and b.SFRSTCR_RSTS_CODE = a.SZSTUME_RSTS_CODE and substr (SFRSTCR_TERM_CODE, 5,1) ='8'
                                                        join ssbsect c  on c. SSBSECT_TERM_CODE = b.SFRSTCR_TERM_CODE and c.SSBSECT_CRN = b.SFRSTCR_CRN
                                                        join SVRSVPR on SVRSVPR_pidm = a.SZSTUME_PIDM  and SVRSVPR_SRVC_CODE = 'NIVE'
                                                        join SVRSVAD on SVRSVAD_PROTOCOL_SEQ_NO = SVRSVPR_PROTOCOL_SEQ_NO ANd SVRSVAD_ADDL_DATA_SEQ ='7'  And SVRSVAD_PROTOCOL_SEQ_NO = SZSTUME_POBI_SEQ_NO
                                                        where a.SZSTUME_NO_REGLA = trim (p_no_regla)
                                                       And  trunc (a.SZSTUME_START_DATE) = p_fecha_inicio
                                                        and trunc (c.SSBSECT_PTRM_START_DATE)  =substr (SVRSVAD_ADDL_DATA_DESC, 1, 10)
                                                        And a.SZSTUME_STAT_IND = '1'
                                                        And a.SZSTUME_PTRM = '1'
                                                        And a.SZSTUME_RSTS_CODE ='RE'
                                                       -- And  a.SZSTUME_ID='010003336'
                                                        And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                                    from SZSTUME a1
                                                                                                    Where a.SZSTUME_PIDM  = a1.SZSTUME_PIDM
                                                                                                    And a.SZSTUME_STAT_IND = a1.SZSTUME_STAT_IND
                                                                                                    And a.SZSTUME_PTRM = a1.SZSTUME_PTRM
                                                                                                    And a.SZSTUME_RSTS_CODE = a1.SZSTUME_RSTS_CODE
                                                                                                    And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                                                                    And trunc (a.SZSTUME_START_DATE) = trunc (a1.SZSTUME_START_DATE)
                                                                                                    )
                                                        order by 2


                                ) loop


                                                  BEGIN
                                                      UPDATE sfrstcr
                                                      SET  sfrstcr_grde_code = cx.calificacion,
                                                             sfrstcr_data_origin = 'CALIFICA_MOODLE',
                                                             sfrstcr_activity_date = SYSDATE,
                                                             sfrstcr_grde_date = SYSDATE,
                                                             sfrstcr_rsts_code = 'RE'
                                                      WHERE  sfrstcr_term_code = cx.periodo
                                                             AND sfrstcr_crn = cx.crn
                                                             AND sfrstcr_pidm = cx.pidm;

                                                      COMMIT;

                                                  EXCEPTION
                                                      WHEN OTHERS THEN
                                                        dbms_output.Put_line('Error al actulizar Calficacion11'
                                                                             ||SQLERRM);
                                                  END;


                                                   ------------------- Valido que exista el registro en las historias Academicas -----------------------
                                                  vl_existe := 0;

                                                  BEGIN
                                                      SELECT Count(1)
                                                      INTO   vl_existe
                                                      FROM   shrtckn
                                                      WHERE  shrtckn_pidm = cx.pidm
                                                             AND shrtckn_term_code = cx.periodo
                                                             AND shrtckn_crn = cx.crn;
                                                  EXCEPTION
                                                      WHEN OTHERS THEN
                                                        vl_existe := 0;
                                                  END;


                                -------------------------------------------------------------------
                                                IF vl_existe >= 1 THEN

                                                                    BEGIN
                                                                        UPDATE shrtckg
                                                                        SET    shrtckg_grde_code_final = cx.calificacion
                                                                        WHERE  ( shrtckg_pidm, shrtckg_term_code, shrtckg_tckn_seq_no ) IN ( SELECT shrtckn_pidm,  shrtckn_term_code,  shrtckn_seq_no
                                                                                                                                                                                FROM shrtckn
                                                                                                                                                                                 WHERE shrtckn_pidm = cx.pidm
                                                                                                                                                                                  AND shrtckn_term_code = cx.periodo
                                                                                                                                                                                  AND shrtckn_crn = cx.crn);
                                                                        Commit;
                                                                         v_sal:=PKG_MOODLE2.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                                      --   dbms_output.Put_line('SALIDA 1' || v_sal);

                                                                    EXCEPTION
                                                                        WHEN OTHERS THEN
                                                                                dbms_output.Put_line('Error al actulizar Calficacion22'
                                                                             ||SQLERRM);
                                                                    END;
                                                ELSE
                                                                    v_sal := pkg_moodle2.F_pase_historia_califica (cx.campus, cx.nivel, cx.periodo, cx.crn, cx.pidm); --- Envia a Historia Academica
                                                                 --    dbms_output.Put_line('SALIDA 2' || v_sal);
                                                                     v_sal:=PKG_MOODLE2.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                END IF;

                                End Loop;

                                 v_proc:=PKG_MOODLE2.F_UPDATE_TMP_SYNC ( 2, trim (p_no_regla), trunc (p_fecha_inicio), 'rolado_calificaciones' );
                              --   dbms_output.Put_line('SALIDA 4' || v_proc);
                                  Return(v_salida);
                                  Commit;
                        EXCEPTION
                                WHEN OTHERS THEN  v_sal := sqlerrm||': Error al actualizar el estatus de la calificacion 333' || v_fecha_inicio;
                                Return(v_salida);
                        END;



            End if;



   End f_update_horario_matricula;

FUNCTION f_alumnos_moodle_aula10_out (p_aula in varchar2)
      RETURN PKG_MOODLE2.cursor_alumnos_aula10_out
   AS
      alumnos_out   PKG_MOODLE2.cursor_alumnos_aula10_out;

   BEGIN
      BEGIN
         OPEN alumnos_out FOR
            SELECT DISTINCT alumnos.PIDM PIDM, alumnos.MATRICULA, alumnos.LAST_NAME, alumnos.FIRST_NAME ,alumnos.EMAIL ,alumnos.ESTATUS , alumnos.TERM_NRC,
                            alumnos.pwd , alumnos.servidor , alumnos.id_curso , alumnos.id_grupo , alumnos.secuencia ,
                            alumnos.no_regla , alumnos.campus , alumnos.Nivel , alumnos.tipo_curso,
            CASE WHEN tipo_curso = 'H' THEN
                   (SELECT SZTDTEC_MOD_TYPE
                    FROM SZTDTEC
                    WHERE 1=1
                    AND programa = SZTDTEC_PROGRAM
                    AND periodo_catalogo = SZTDTEC_TERM_CODE
                    AND campus = SZTDTEC_CAMP_CODE --cambio colocado 04/12/2020--
                     )
            END AS MODA,
            alumnos.fecha_inicio
            --'BLOQUE1'
            from (
            SELECT SPRIDEN_PIDM PIDM,
                   SPRIDEN_ID MATRICULA,
                   REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                   SPRIDEN_FIRST_NAME FIRST_NAME,
                   a.GOREMAL_EMAIL_ADDRESS EMAIL,
                   SZSTUME_RSTS_CODE ESTATUS,
                   SZSTUME_TERM_NRC TERM_NRC,
                   GOZTPAC_PIN pwd,
                   SZTGPME_PTRM_CODE_COMP servidor,
                   SZTGPME_CRSE_MDLE_ID id_curso,
                   SZTGPME_GPMDLE_ID id_grupo,
                   SZSTUME_SEQ_NO secuencia,
                   SZSTUME_NO_REGLA no_regla,
                   SORLCUR_CAMP_CODE campus,
                   SORLCUR_LEVL_CODE Nivel,
                   SORLCUR_PROGRAM programa,
                   SORLCUR_TERM_CODE_CTLG periodo_catalogo,
                   SZTMAUR_ORIGEN tipo_curso,
                   SGBSTDN_TERM_CODE_EFF periodo,
                   SZSTUME_START_DATE Fecha_inicio
              FROM SPRIDEN,
                   STVRSTS,
                   GOREMAL a,
                   SZSTUME,
                   GOZTPAC,
                   ZSTPARA,
                   SZTGPME,
                   SGBSTDN A,
                   SORLCUR B,
                   SZTMAUR,
                   SZSGNME
             WHERE SPRIDEN_CHANGE_IND IS NULL
                   AND SPRIDEN_PIDM = SZSTUME_PIDM
                   AND SPRIDEN_PIDM = GOZTPAC_PIDM
                   AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                   AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                   AND SZSTUME_SINCRO = '0'
                   AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                   AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
                   AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                   AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                   AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                   AND SZSTUME_START_DATE = SZTGPME_START_DATE
--                   AND SZTGPME_STAT_IND = '1'
                   AND SZTGPME_CRSE_MDLE_ID != 0
                   AND SZSTUME_RSTS_CODE = 'RE'
                   and SZSTUME_CAMP_CODE_COMP is null
                   AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                   AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                 FROM GOREMAL a1
                                                 WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                 AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                   AND SPRIDEN_PIDM = A.SGBSTDN_PIDM
                   AND A.SGBSTDN_STST_CODE  IN ('MA', 'PR', 'AS')
                   AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                  FROM SGBSTDN A1
                                                  WHERE A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                  AND A.SGBSTDN_TERM_CODE_EFF = A1.SGBSTDN_TERM_CODE_EFF
                                                  AND A.SGBSTDN_LEVL_CODE = A1.SGBSTDN_LEVL_CODE
                                                  AND A.SGBSTDN_CAMP_CODE = A1.SGBSTDN_CAMP_CODE
                                                  AND A.SGBSTDN_STST_CODE = A1.SGBSTDN_STST_CODE )
                    AND B.SORLCUR_PIDM = SZSTUME_PIDM
                    And  b.SORLCUR_LMOD_CODE = 'LEARNER'
                    And b.SORLCUR_CACT_CODE = 'ACTIVE'
                    and b.sorlcur_camp_code = SGBSTDN_CAMP_CODE
                    And b.sorlcur_levl_code = SGBSTDN_LEVL_CODE
                    And b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                            from SORLCUR b1
                                                            where b.SORLCUR_PIDM = b1.SORLCUR_PIDM
                                                            And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                            And b.SORLCUR_CACT_CODE = b1.SORLCUR_CACT_CODE
                                                            And b.sorlcur_camp_code = b1.sorlcur_camp_code
                                                            And b.sorlcur_levl_code = b1.sorlcur_levl_code
                                                            and b.SORLCUR_ADMT_CODE = b1.SORLCUR_ADMT_CODE)
                    AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                    AND SZTMAUR_ACTIVO = 'S'
                    AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                    AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                    AND SZSTUME_START_DATE = SZSGNME_START_DATE
                    AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                    AND SZTGPME_NO_REGLA <> 99
                    AND SZTMAUR_ORIGEN <> 'E'
                    --AND SZSGNME_STAT_IND ='1'
                    AND SZTGPME_CAMP_CODE != 'EAF'
                    AND SZTGPME_PTRM_CODE_COMP = p_aula
                    --AND SZTGPME_PTRM_CODE_COMP IN (10) -- PARA PRUEBA DE SEGMENTACI”N DE CURSORES--
                    --AND SZSGNME_NO_REGLA IN (164, 149)
                     --AND SZTGPME_CAMP_CODE <>'UVE'
                    )alumnos
                    WHERE 1=1
                    AND alumnos.periodo = (SELECT MAX (d.SGBSTDN_TERM_CODE_EFF)
                                           FROM SGBSTDN d
                                           WHERE 1=1
                                           AND d.SGBSTDN_PIDM = alumnos.PIDM
                                           AND d.SGBSTDN_LEVL_CODE = alumnos.nivel)
                   --AND alumnos.no_regla = 207
                   --AND ROWNUM <= 1000
                   --AND alumnos.PIDM = 296092
                   UNION
                    SELECT DISTINCT alumnos.PIDM PIDM, alumnos.MATRICULA, alumnos.LAST_NAME, alumnos.FIRST_NAME ,alumnos.EMAIL ,alumnos.ESTATUS , alumnos.TERM_NRC,
                            alumnos.pwd , alumnos.servidor , alumnos.id_curso , alumnos.id_grupo , alumnos.secuencia ,
                            alumnos.no_regla , alumnos.campus , alumnos.Nivel , alumnos.tipo_curso,
            CASE WHEN tipo_curso = 'H' THEN
                   (SELECT SZTDTEC_MOD_TYPE
                    FROM SZTDTEC
                    WHERE 1=1
                    AND programa = SZTDTEC_PROGRAM
                    AND periodo_catalogo = SZTDTEC_TERM_CODE
                    AND campus = SZTDTEC_CAMP_CODE --cambio colocado 04/12/2020--
                     )
            END AS MODA,
            alumnos.fecha_inicio
            --'BLOQUE1'
            from (
            SELECT SPRIDEN_PIDM PIDM,
                   SPRIDEN_ID MATRICULA,
                   REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                   SPRIDEN_FIRST_NAME FIRST_NAME,
                   a.GOREMAL_EMAIL_ADDRESS EMAIL,
                   SZSTUME_RSTS_CODE ESTATUS,
                   SZSTUME_TERM_NRC TERM_NRC,
                   GOZTPAC_PIN pwd,
                   SZTGPME_PTRM_CODE_COMP servidor,
                   SZTGPME_CRSE_MDLE_ID id_curso,
                   SZTGPME_GPMDLE_ID id_grupo,
                   SZSTUME_SEQ_NO secuencia,
                   SZSTUME_NO_REGLA no_regla,
                   SORLCUR_CAMP_CODE campus,
                   SORLCUR_LEVL_CODE Nivel,
                   SORLCUR_PROGRAM programa,
                   SORLCUR_TERM_CODE_CTLG periodo_catalogo,
                   SZTMAUR_ORIGEN tipo_curso,
                   SGBSTDN_TERM_CODE_EFF periodo,
                   SZSTUME_START_DATE Fecha_inicio
              FROM SPRIDEN,
                   STVRSTS,
                   GOREMAL a,
                   SZSTUME,
                   GOZTPAC,
                   ZSTPARA,
                   SZTGPME,
                   SGBSTDN A,
                   SORLCUR B,
                   SZTMAUR,
                   SZSGNME
             WHERE SPRIDEN_CHANGE_IND IS NULL
                   AND SPRIDEN_PIDM = SZSTUME_PIDM
                   AND SPRIDEN_PIDM = GOZTPAC_PIDM
                   AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                   AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                   AND SZSTUME_SINCRO = '0'
                   AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                   AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
                   AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                   AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                   AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                   AND SZSTUME_START_DATE = SZTGPME_START_DATE
--                   AND SZTGPME_STAT_IND = '1'
                   AND SZTGPME_CRSE_MDLE_ID != 0
                   AND SZTGPME_PTRM_CODE_COMP = SZTMAUR_SZTURMD_ID
                   AND SZSTUME_RSTS_CODE = 'RE'
                   and SZSTUME_CAMP_CODE_COMP is null
                   AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                   AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                 FROM GOREMAL a1
                                                 WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                 AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                   AND SPRIDEN_PIDM = A.SGBSTDN_PIDM
                   AND A.SGBSTDN_STST_CODE  IN ('MA', 'PR', 'AS')
                   AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                  FROM SGBSTDN A1
                                                  WHERE A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                  AND A.SGBSTDN_TERM_CODE_EFF = A1.SGBSTDN_TERM_CODE_EFF
                                                  AND A.SGBSTDN_LEVL_CODE = A1.SGBSTDN_LEVL_CODE
                                                  AND A.SGBSTDN_CAMP_CODE = A1.SGBSTDN_CAMP_CODE
                                                  AND A.SGBSTDN_STST_CODE = A1.SGBSTDN_STST_CODE )
                    AND B.SORLCUR_PIDM = SZSTUME_PIDM
                    And  b.SORLCUR_LMOD_CODE = 'LEARNER'
                    And b.SORLCUR_CACT_CODE = 'ACTIVE'
                    and b.sorlcur_camp_code = SGBSTDN_CAMP_CODE
                    And b.sorlcur_levl_code = SGBSTDN_LEVL_CODE
                    And b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                            from SORLCUR b1
                                                            where b.SORLCUR_PIDM = b1.SORLCUR_PIDM
                                                            And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                            And b.SORLCUR_CACT_CODE = b1.SORLCUR_CACT_CODE
                                                            And b.sorlcur_camp_code = b1.sorlcur_camp_code
                                                            And b.sorlcur_levl_code = b1.sorlcur_levl_code
                                                            and b.SORLCUR_ADMT_CODE = b1.SORLCUR_ADMT_CODE)
                    AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                    AND SZTMAUR_ACTIVO = 'S'
                    AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                    AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                    AND SZSTUME_START_DATE = SZSGNME_START_DATE
                    AND SZTGPME_NO_REGLA != 99
                    AND SZTMAUR_ORIGEN != 'E'
                    --AND SZSGNME_STAT_IND ='1'
                    AND SZTGPME_CAMP_CODE != 'EAF'
                    AND SZTMAUR_ORIGEN = 'I'
                    AND SZTGPME_PTRM_CODE_COMP = p_aula
                    --AND SZTGPME_PTRM_CODE_COMP IN (10) -- PARA PRUEBA DE SEGMENTACI”N DE CURSORES--
                    --AND SZSGNME_NO_REGLA IN (164, 149)
                     --AND SZTGPME_CAMP_CODE <>'UVE'
                    )alumnos
                    WHERE 1=1
                    AND alumnos.periodo = (SELECT MAX (d.SGBSTDN_TERM_CODE_EFF)
                                           FROM SGBSTDN d
                                           WHERE 1=1
                                           AND d.SGBSTDN_PIDM = alumnos.PIDM
                                          AND d.SGBSTDN_LEVL_CODE = alumnos.nivel);

      RETURN (alumnos_out);
     END;
   END f_alumnos_moodle_aula10_out;
FUNCTION f_updte_alumnos_moodle_aula10(p_trem_nrc in Varchar2, p_pidm in number, p_stat_upte_ind in Varchar2, p_obs in Varchar2,
                                                            p_asgn_mdle in Varchar2,p_error_code in Number,  p_error_desc in Varchar2, p_grade_final in Varchar2,
                                                            p_enrl_id_grpmoodle in varchar2, p_seq_no in number, p_no_regla in number, p_fecha_ini in varchar2) Return Varchar2
    AS
        vl_maximo number:=0;
        grade_min  Varchar2(10);
        grade_max  Varchar2(10);
        vl_grade_final Varchar2(10);
        vl_szstume_camp_code Varchar2(6);
        vl_szstume_level_code Varchar2(6);
        vl_error  varchar2(250) := 'EXITO';
        p_materia varchar2(50):= null;
       vl_salida  varchar2(250) := null;




            BEGIN

                  IF  p_stat_upte_ind = 2 THEN

                         begin

                                 Begin

                                      Select nvl (max (SZTMEBI_SEQ_NO), 0 ) +1
                                      Into vl_maximo
                                      from SZTMEBI
                                      Where SZTMEBI_TERM_NRC = p_trem_nrc
                                      and SZTMEBI_CTGY_ID = 'Alumnos';
                                      Exception
                                      When Others then
                                      vl_maximo :=1;

                                END;

                                begin

                                    INSERT INTO SZTMEBI
                                    VALUES(p_trem_nrc, p_stat_upte_ind, p_error_code, p_error_desc, vl_maximo, sysdate,user, 'Alumnos', p_pidm);
                                    Exception
                                    When others then
                                    vl_error := 'Error al insertar Alumnos en la Bitacora'||sqlerrm;

                                End;

                                begin

                                    UPDATE SZSTUME
                                    SET SZSTUME_SINCRO = p_stat_upte_ind,
                                        SZSTUME_SINCRO_OBS = p_obs
--                                        SZSTUME_ACTIVITY_DATE = sysdate
                                    WHERE SZSTUME_TERM_NRC = p_trem_nrc
                                    AND SZSTUME_PIDM = p_pidm
                                    AND SZSTUME_SEQ_NO = p_seq_no
                                    AND SZSTUME_NO_REGLA = p_no_regla
                                    AND SZSTUME_START_DATE = p_fecha_ini;

                                end;
                         Exception when others then
                         vl_error:= 'Error al trartar el szstume.stat_ind 2'||sqlerrm;
                         end;

                  ELSE
--                                          Insert into sztmebi (SZTMEBI_ERROR_DESC, SZTMEBI_ERROR_CODE)  values (p_trem_nrc||'*'|| p_stat_upte_ind||'*'||p_pidm||'*'||p_no_regla||'*'||p_seq_no||'*'||'ENTRA-ELSE',  666);
--                                               Commit;

                       begin
                            UPDATE SZSTUME a
                            SET a.SZSTUME_SINCRO = p_stat_upte_ind,
                            a.SZSTUME_SINCRO_OBS = p_obs
--                            a.SZSTUME_MDLE_ID = p_asgn_mdle,
--                            a.SZSTUME_ACTIVITY_DATE = sysdate
                            WHERE a.SZSTUME_TERM_NRC = p_trem_nrc
                            AND a.SZSTUME_PIDM = p_pidm
                            AND a.SZSTUME_SEQ_NO = p_seq_no
                            AND a.SZSTUME_NO_REGLA = p_no_regla
                            AND a.SZSTUME_START_DATE = p_fecha_ini;


                       Exception
                        When Others then
                          vl_error := 'Error al actualizar el alumno * '||p_trem_nrc ||'*'||p_pidm ||'*'||p_seq_no ||'*'||p_no_regla||' *'||sqlerrm;
                        end;

                  END IF;

              COMMIT;

                Return vl_error;

            END;
----
----
FUNCTION f_prepara_sync_grades_niv(p_no_regla in number,p_fecha in varchar2, p_PERIODO in varchar2,p_pperiodo in varchar2) Return varchar2
  IS
 vl_msje varchar2(200) := Null;
 vl_valida number:=NULL;
 vl_process varchar2(30):=NULL;


    BEGIN


     vl_valida:= NULL;
       BEGIN
        SELECT STAT_IND, PROCESS
        INTO vl_valida, vl_process
        FROM TMP_SYNC_STATUS
        WHERE 1=1
        AND REGLA =99
        AND trunc(START_DATE)= p_fecha
        and COL2=p_pperiodo
        GROUP BY STAT_IND, PROCESS;
        DBMS_OUTPUT.PUT_LINE('ENTRA 1'||vl_valida||vl_process);
       EXCEPTION
       WHEN OTHERS THEN
       vl_valida := NULL;
       vl_process := Null;
           DBMS_OUTPUT.PUT_LINE('ENTRA 1 EEROR'||vl_valida||vl_process);
       END;
     
     
       IF vl_valida IS NULL AND vl_process IS NULL THEN
         
             DBMS_OUTPUT.PUT_LINE('ENTRA 2 NULO'||vl_valida||vl_process);
        BEGIN
          FOR C IN( 
                 select  distinct E.SZSTUME_PIDM PIDM,
                E.SZSTUME_TERM_NRC MATE
                    from svrsvpr v
                    INNER JOIN SVRSVAD VA ON VA.SVRSVAD_PROTOCOL_SEQ_NO=V.SVRSVPR_PROTOCOL_SEQ_NO 
                          and va.SVRSVAD_ADDL_DATA_SEQ = '7'
                    INNER JOIN SOBPTRM PT ON pt.SOBPTRM_PTRM_CODE=va.SVRSVAD_ADDL_DATA_CDE
                        AND to_char(PT.SOBPTRM_START_DATE,'DD/MM/YYYY')=substr(SVRSVAD_ADDL_DATA_DESC,1,10)
                    and PT.SOBPTRM_PTRM_CODE =p_pperiodo
                    and SUBSTR(SOBPTRM_TERM_CODE,1,2)IN (SELECT ZSTPARA_PARAM_ID
                                                                    FROM ZSTPARA
                                                                    WHERE 1=1
                                                                    AND ZSTPARA_MAPA_ID='DESC_CALIF') 
                    INNER JOIN SZSTUME E ON E.SZSTUME_PIDM= v.SVRSVPR_PIDM
                      and E.SZSTUME_NO_REGLA=99                                                
                    INNER JOIN SZTGPME gp ON gp.SZTGPME_TERM_NRC=e.SZSTUME_TERM_NRC
                    AND GP.SZTGPME_NO_REGLA =E.SZSTUME_NO_REGLA
                    and GP.SZTGPME_NO_REGLA = 99
                    and GP.SZTGPME_START_DATE=E.SZSTUME_START_DATE
                    and GP.SZTGPME_START_DATE=p_fecha
                    where 1=1
                    ANd v.SVRSVPR_SRVC_CODE IN  ('NIVE','EXTR')
                    and e.SZSTUME_SUBJ_CODE=(select A.SZTMACO_MATPADRE
                                               from SVRSVAD VA1, SZTMACO A
                                               WHERE 1=1
                                               AND VA1.SVRSVAD_ADDL_DATA_SEQ=2
                                               AND VA1.SVRSVAD_ADDL_DATA_CDE=A.SZTMACO_MATHIJO
                                               AND VA1.SVRSVAD_PROTOCOL_SEQ_NO=V.SVRSVPR_PROTOCOL_SEQ_NO)
                    order by 1 desc,2 desc   
        )
           LOOP
                 DBMS_OUTPUT.PUT_LINE('ENTRA 3 UPDATE '||vl_valida||vl_process);
            BEGIN
                    UPDATE SZSTUME SET SZSTUME_PTRM = '0', SZSTUME_ACTIVITY_DATE = SYSDATE, SZSTUME_USER_ID = USER, SZSTUME_OBS = 'Esperando||descarga calificaciones'
                    WHERE 1=1
                    AND SZSTUME_NO_REGLA =99
        --            AND SZSTUME_START_DATE =p_fecha
        --            AND SZSTUME_MDLE_ID IS NOT NULL
        --            AND SZSTUME_PTRM IS NULL
                    and SZSTUME_PIDM=C.PIDM
                    and SZSTUME_TERM_NRC=C.mate;
                    COMMIT;    
                    vl_msje:='Exito';  
                 DBMS_OUTPUT.PUT_LINE('ENTRA 4 ACTUALIZO '||C.PIDM||C.mate);   
                 EXCEPTION
                 WHEN OTHERS THEN
                 vl_msje:= 'Error en la peticiÛn de calificaciones '||sqlerrm;
                 DBMS_OUTPUT.PUT_LINE('ENTRA 4  NO ACTUALIZO '||vl_msje);
                END;
                    
           END LOOP;
             
          EXCEPTION
         WHEN OTHERS THEN
         vl_msje:= 'Error en la peticiÛn de calificaciones '||sqlerrm||' Near of Line...6475';
         DBMS_OUTPUT.PUT_LINE('ENTRA 4  NO ENTRO '||vl_msje);
        END; 
         DBMS_OUTPUT.PUT_LINE('ENTRA   NO ENTRO '||vl_msje);     
      END IF;


       BEGIN
        INSERT INTO TMP_SYNC_STATUS
        (STAT_IND,
            REGLA,
            START_DATE,
            PROCESS,
            USER_UPDATE,
            COL1,
            COL2
          )
          VALUES
          (0,
           p_no_regla,
           p_fecha,
           'sync_grades_niv',
           USER,
           Null,
           p_pperiodo
          );
       EXCEPTION
       WHEN OTHERS THEN
           BEGIN

            SELECT STAT_IND, PROCESS
            INTO vl_valida, vl_process
            FROM TMP_SYNC_STATUS
            WHERE 1=1
            AND REGLA = p_no_regla
            AND START_DATE = p_fecha
            and COL2=p_pperiodo
            GROUP BY STAT_IND, PROCESS;

            IF

            vl_valida = 0 AND vl_process = 'sync_grades_niv' THEN
               vl_msje:='SincronizaciÛn de calificaciones iniciada para esta regla: '||p_no_regla||'fecha de inicio: '||p_fecha||' y parte de periodo: '||p_pperiodo;

            ELSIF vl_valida = 1 AND vl_process = 'sync_grades_niv' THEN
               vl_msje:='Las calificaciones ya fueron sincronizadas para esta regla: '||p_no_regla||' y fecha de inicio: '||p_fecha||' y parte de periodo: '||p_pperiodo;

            ELSIF vl_valida = 2 AND vl_process = 'rolado_grades' THEN
               vl_msje:='Calificaciones en proceso de rolado';

            ELSIF vl_valida = 3 AND vl_process = 'historias_grades' THEN
               vl_msje:='Solicitud de calificaciones invalida, generando historias acadÈmicas';
              END IF;
           END;
       END;
       COMMIT;

        BEGIN
           DELETE TMP_SYNC_STATUS
            WHERE 1=1
            AND STAT_IND = 4
            AND PROCESS = 'fin_grades';
        END;
        COMMIT;
    
    
      RETURN(vl_msje);
      DBMS_OUTPUT.PUT_LINE(vl_msje);

    END f_prepara_sync_grades_niv;
--------
  FUNCTION f_sync_grades_moodln
      RETURN PKG_MOODLE2.cursor_goutn
   AS
      c_out_gradesn  PKG_MOODLE2.cursor_goutn;
   BEGIN
      BEGIN
       OPEN c_out_gradesn FOR
           SELECT   DISTINCT SZSTUME_PIDM pidm,
            SZSTUME_ID matricula,
            SZSTUME_MDLE_ID user_moodle_id,
            to_number(SZTGPME_PTRM_CODE_COMP) aula,
            SZTGPME_CRSE_MDLE_ID id_crse_moodle,
            SZTGPME_NO_REGLA regla,
            SZSTUME_START_DATE fecha_inicio,
            COL2 pperiodo
            from svrsvpr v
            INNER JOIN SVRSVAD VA ON VA.SVRSVAD_PROTOCOL_SEQ_NO=V.SVRSVPR_PROTOCOL_SEQ_NO 
                  and va.SVRSVAD_ADDL_DATA_SEQ = '7'
            INNER JOIN SOBPTRM PT ON pt.SOBPTRM_PTRM_CODE=va.SVRSVAD_ADDL_DATA_CDE
                AND to_char(PT.SOBPTRM_START_DATE,'DD/MM/YYYY')=substr(SVRSVAD_ADDL_DATA_DESC,1,10)
--            and PT.SOBPTRM_PTRM_CODE = 'N00'--p_pperiodo
            and SUBSTR(SOBPTRM_TERM_CODE,1,2)IN (SELECT ZSTPARA_PARAM_ID
                                                FROM ZSTPARA
                                                WHERE 1=1
                                                AND ZSTPARA_MAPA_ID='DESC_CALIF') 
            INNER JOIN SZSTUME E ON E.SZSTUME_PIDM= v.SVRSVPR_PIDM
              and E.SZSTUME_NO_REGLA=99                                                
            INNER JOIN SZTGPME gp ON gp.SZTGPME_TERM_NRC=e.SZSTUME_TERM_NRC
            AND GP.SZTGPME_NO_REGLA =E.SZSTUME_NO_REGLA
            and GP.SZTGPME_NO_REGLA = 99
            and GP.SZTGPME_START_DATE=E.SZSTUME_START_DATE
--            and GP.SZTGPME_START_DATE='02/01/2024'--p_fecha
            JOIN TMP_SYNC_STATUS B ON B.REGLA=E.SZSTUME_NO_REGLA
            AND B.COL2=PT.SOBPTRM_PTRM_CODE
            AND START_DATE=E.SZSTUME_START_DATE
            AND B.STAT_IND=0
            AND E.SZSTUME_PTRM=0
            where 1=1
            ANd v.SVRSVPR_SRVC_CODE IN  ('NIVE','EXTR')
            and e.SZSTUME_SUBJ_CODE=(select A.SZTMACO_MATPADRE
                                       from SVRSVAD VA1, SZTMACO A
                                       WHERE 1=1
                                       AND VA1.SVRSVAD_ADDL_DATA_SEQ=2
                                       AND VA1.SVRSVAD_ADDL_DATA_CDE=A.SZTMACO_MATHIJO
                                       AND VA1.SVRSVAD_PROTOCOL_SEQ_NO=V.SVRSVPR_PROTOCOL_SEQ_NO);
         RETURN (c_out_gradesn);
      END;
   END f_sync_grades_moodln;
--------
 FUNCTION f_update_sync_grades_moodle_niv (p_pidm in number, p_no_regla in number, p_crse_moodle in number, p_aula in varchar2, p_grade in varchar2, p_obs in varchar2) Return Varchar2
   IS

   vl_grade Varchar2(10);
   vl_grade_final Varchar2(10);
   vl_error Varchar2(200):= null;
   vl_type Varchar2(6);
   vl_obs Varchar2(500);
   vl_date_actual date;
   vl_ind number:=0;
   --vl_rsts Varchar2(2);

 BEGIN

   BEGIN

    FOR c IN (SELECT
            SZSTUME_PIDM pidm,
            SZSTUME_MDLE_ID user_moodle_id,
            CASE WHEN CAMPUS = 'UTS'
            THEN 'UTL'
            WHEN CAMPUS IN (SELECT ZSTPARA_PARAM_VALOR
                            FROM ZSTPARA
                            WHERE 1=1
                            AND ZSTPARA_MAPA_ID = 'FA_GENEX')
            THEN 'UTL'
            WHEN CAMPUS NOT IN (SELECT ZSTPARA_PARAM_VALOR
                            FROM ZSTPARA
                            WHERE 1=1
                            AND ZSTPARA_MAPA_ID = 'FA_GENEX')
            THEN CAMPUS
            END camp_code,
            CASE WHEN SZTGPME_LEVL_CODE = 'MS'
            THEN 'MA'
            WHEN SZTGPME_LEVL_CODE <> 'MS'
            THEN SZTGPME_LEVL_CODE
            END levl_code,
            SZTGPME_TERM_NRC term_nrc,
            SUBSTR(SZTGPME_SUBJ_CRSE,0,3)vtype,
            SZTGPME_NO_REGLA regla,
            SZSTUME_START_DATE start_date,
            ESTATUS stst
            FROM SZTGPME , SZSTUME c, TZTPROG a
            WHERE 1=1
            AND SZTGPME_NO_REGLA = c.SZSTUME_NO_REGLA
            AND SZTGPME_TERM_NRC = c.SZSTUME_TERM_NRC
            AND SZTGPME_START_DATE = c.SZSTUME_START_DATE
            AND c.SZSTUME_PIDM = a.PIDM
            AND a.NIVEL NOT IN('ID')
            AND a.SP = (SELECT MAX(b.SP)
                        FROM TZTPROG b
                        WHERE 1=1
                        AND a.PIDM = b.PIDM)
            AND c.SZSTUME_PIDM = p_pidm
            AND SZTGPME_NO_REGLA = p_no_regla
            AND SZTGPME_CRSE_MDLE_ID = p_crse_moodle
            AND SZTGPME_PTRM_CODE_COMP = p_aula
            AND c.SZSTUME_PTRM = '0'

          )

        LOOP

            vl_grade_final := null;


            vl_type:= NULL;

            vl_obs:= NULL;


            IF p_grade IS NULL AND c.stst NOT IN ('MA', 'TR', 'PR', 'EG', 'SG')THEN

              vl_grade :=  '0.00';

              vl_obs:= p_obs;

              ELSIF p_grade IS NULL THEN

              vl_grade :=  '0.00';
              vl_obs:= p_obs;

              ELSE

              vl_grade := p_grade;
              vl_obs:= p_obs;

            END IF;


            DBMS_OUTPUT.PUT_LINE('Entara a validaciÛn la calificaciÛn'|| vl_grade);

            IF c.regla <> '99' THEN

                vl_type := 'OR';

            ELSIF c.regla = '99' THEN

                vl_type := 'NIV';

            END IF;

            IF c.vtype IN ('SEL','IEB','MOD') THEN

                vl_type := c.vtype;

            ELSE
                vl_type:= vl_type;

            END IF;


            vl_ind:= null;
            vl_date_actual:= null;

            BEGIN
            SELECT TRUNC(SYSDATE)
            INTO vl_date_actual
            FROM DUAL;
            END;


             IF p_grade = '0.00'  AND c.regla = '99' AND vl_date_actual >=  c.start_date THEN

              vl_ind:=1;

             ELSIF p_grade != '0.00' OR c.regla != '99' THEN

               vl_ind:=1;

             ELSE

              vl_ind:=0;

             END IF;


             IF vl_ind = 1 THEN

                 BEGIN
                    SELECT distinct SZTRNDO_GRDE
                    Into   vl_grade_final
                    FROM SZTRNDO
                    WHERE SZTRNDO_CAMP_CODE = c.camp_code
                    AND SZTRNDO_LEVL_CODE = c.levl_code
                    AND SZTRNDO_CTGRY = c.camp_code||c.levl_code||vl_type
                    AND ROUND(vl_grade,2) BETWEEN SZTRNDO_MIN_GRDE AND SZTRNDO_MAX_GRDE ;
                 Exception
                 When Others then
                 vl_grade_final := 'ERCONV';
                 vl_error := 'No existe calificaciÛn o conversion de calificacion '||vl_grade||'Near of Line...6571';
                 END;


                 --DBMS_OUTPUT.PUT_LINE(vl_grade_final);


                 BEGIN
                    UPDATE SZSTUME SET SZSTUME_TERM_NRC_COMP = vl_grade, SZSTUME_GRDE_CODE_FINAL = vl_grade_final,
                    SZSTUME_PTRM = '1', SZSTUME_ACTIVITY_DATE = SYSDATE, SZSTUME_OBS = vl_obs||' '||USER||'|| sync_grades'
                    WHERE 1=1
                    AND SZSTUME_PIDM = c.pidm  --'010007241'--'010302086'--'010007241'
                    AND SZSTUME_MDLE_ID = c.user_moodle_id
                    AND SZSTUME_TERM_NRC = c.term_nrc
                    AND SZSTUME_NO_REGLA = c.regla
                    AND SZSTUME_START_DATE = c.start_date;
                 vl_error :='Registro actualizado';
                 Exception
                 When others then
                 vl_error := 'Error al actualizar grade SZSTUME '||sqlerrm||' Near of Line...6591';
                 END;
              COMMIT;

             ELSIF vl_ind = 0 THEN

             Null;

             END IF;



        END LOOP;
   EXCEPTION
   WHEN OTHERS THEN
   vl_error := sqlerrm||': Error general Near of Line...6598';
   END;
   Return(vl_error);
 END f_update_sync_grades_moodle_niv;
-----
FUNCTION f_update_tmp_sync_niv (p_stat in number, p_no_regla in number,  p_start_date in varchar2, p_process in varchar2,p_pperiodo in varchar2) Return Varchar2
     IS

   vl_return varchar(50);

    BEGIN


        IF  p_stat IN (1, 2,3) and p_no_regla IS NOT NULL AND p_start_date IS NOT NULL and p_pperiodo IS NOT NULL THEN

          vl_return:= p_stat;

           BEGIN
            UPDATE TMP_SYNC_STATUS SET  STAT_IND = p_stat, PROCESS = p_process
            WHERE 1=1
            AND REGLA = p_no_regla
            AND START_DATE = p_start_date
            and COL2=p_pperiodo;
           EXCEPTION
           WHEN OTHERS THEN
           vl_return:=0;
           return(vl_return);
           END;
           COMMIT;

        ELSIF p_stat = 4 and p_no_regla IS NOT NULL AND p_start_date IS NOT NULL and p_pperiodo IS NOT NULL THEN

          vl_return:= p_stat;

           BEGIN
            UPDATE TMP_SYNC_STATUS SET  STAT_IND = p_stat, PROCESS = p_process
            WHERE 1=1
            AND REGLA = p_no_regla
            AND START_DATE = p_start_date
            and COL2=p_pperiodo;
           EXCEPTION
           WHEN OTHERS THEN
           vl_return:=0;
           return(vl_return);
           END;
           COMMIT;

        ELSIF p_stat = 0 THEN

            vl_return:= p_stat;

        END IF;
       return(vl_return);

     END f_update_tmp_sync_niv;
-----    


End;
/

DROP PUBLIC SYNONYM PKG_MOODLE2;

CREATE OR REPLACE PUBLIC SYNONYM PKG_MOODLE2 FOR BANINST1.PKG_MOODLE2;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_MOODLE2 TO PUBLIC;
