DROP PACKAGE BODY BANINST1.PKG_PRONO_PRONO_OPM;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_PRONO_PRONO_OPM AS
/******************************************************************************
  NAME: BANINST1.PKG_PRONO_PRONO_OPM
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        01/01/2023    flopezlo       1. Created this package.


******************************************************************************/
Procedure p_VALIDA_AVANCE (P_PIDM NUMBER ,P_REGLA NUMBER)IS
CONT_AVANCE NUMBER;
VALIDA_ASIG NUMBER;
VALIDA_ASIG_2 NUMBER;

BEGIN

FOR x IN
         ( SELECT  ZSTPARA_PARAM_VALOR num,CLAVE_MATERIA materia,SVRPROY_PIDM pidm,REL_ALUMNOS_X_ASIGNAR_NO_REGLA regla,ID_PROGRAMA programa
               FROM REL_ALUMNOS_X_ASIGNAR,ZSTPARA
               WHERE 1=1
               AND SUBSTR(ID_PROGRAMA,1,3) ='UNI'
               AND REL_ALUMNOS_X_ASIGNAR_NO_REGLA=P_REGLA
               and SVRPROY_PIDM=P_PIDM
               AND CLAVE_MATERIA in ZSTPARA_PARAM_ID
               AND ZSTPARA_MAPA_ID ='MAT_PROYEM'
               and ZSTPARA_PARAM_VALOR IN (1,2)
             )
     LOOP

           BEGIN
               PKG_VALIDA_PRONO.P_VALIDA_FALTA (x.PIDM,
                                                    x.PROGRAMA,
                                                    x.regla);
             END;

--        BEGIN
--                SELECT COUNT(*)
--                INTO CONT_AVANCE
--                FROM  SZTHITA
--                WHERE 1=1
--                and SZTHITA_CAMP = 'UNI'
--                AND SZTHITA_STATUS = 'MATRICULADO'
--                AND SZTHITA_REPROB=0
--                and SZTHITA_AVANCE>=83
--                and SZTHITA_PIDM=x.PIDM;
--
--               dbms_output.put_line('AVANCE ALUMNO '||CONT_AVANCE);
--        EXCEPTION WHEN OTHERS THEN
--          CONT_AVANCE:=0;
--          dbms_output.put_line('ERROR AVANCE ALUMNO '||CONT_AVANCE);
--
--        END;


            BEGIN

              select count(distinct(MATRICULA))
              INTO CONT_AVANCE
                 from tmp_valida_faltantes
                 where 1=1
                 and AVANCE_CURR>=83
                 and substr(PROGRAMA,1,3)='UNI'
                 and REGLA= x.regla
                 and PIDM=x.PIDM;

               dbms_output.put_line('AVANCE ALUMNO '||CONT_AVANCE);
        EXCEPTION WHEN OTHERS THEN
          CONT_AVANCE:=0;
          dbms_output.put_line('ERROR AVANCE ALUMNO '||CONT_AVANCE);

        END;--

        BEGIN
          SELECT COUNT(DISTINCT a.sfrstcr_pidm)
            INTO VALIDA_ASIG
               FROM ssbsect t ,
                    sfrstcr a
               WHERE 1 = 1
               AND t.ssbsect_term_code = a.sfrstcr_term_code
               AND t.ssbsect_crn = sfrstcr_crn
               and a.SFRSTCR_TERM_CODE=(select max (a1.SFRSTCR_TERM_CODE)
                                         from SFRSTCR a1
                                         where 1=1
                                         and a1.sfrstcr_pidm=a.sfrstcr_pidm
                                         and a1.SFRSTCR_RESERVED_KEY=a.SFRSTCR_RESERVED_KEY
                                         )
               and t.SSBSECT_SUBJ_CODE||t.SSBSECT_CRSE_NUMB=(SELECT ZSTPARA_PARAM_ID
                                                          FROM ZSTPARA
                                                          WHERE 1=1
                                                           AND ZSTPARA_MAPA_ID ='MAT_PROYEM'
                                                           and ZSTPARA_PARAM_VALOR IN (1) )
               AND a.sfrstcr_rsts_code ='RE'
               AND t.SSBSECT_CAMP_CODE='UNI'
               AND a.SFRSTCR_GRDE_CODE IS NOT NULL
               AND a.SFRSTCR_GRDE_CODE>=6
               AND a.sfrstcr_pidm =x.PIDM;
               dbms_output.put_line('VALIDA SI TIENE MATERIA '||VALIDA_ASIG);
          EXCEPTION WHEN OTHERS THEN
         VALIDA_ASIG:=0  ;
             dbms_output.put_line('ERROR VALIDA SI TIENE MATERIA '||VALIDA_ASIG);
        END;

        BEGIN
               SELECT COUNT(DISTINCT sfrstcr_pidm)
               INTO VALIDA_ASIG_2
               FROM ssbsect t ,
                    sfrstcr a
               WHERE 1 = 1
               AND t.ssbsect_term_code = a.sfrstcr_term_code
--               and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB=X.CLAVE_MATERIA
               AND t.ssbsect_crn = a.sfrstcr_crn
               AND a.sfrstcr_rsts_code ='RE'
               AND t.SSBSECT_CAMP_CODE='UNI'
               AND a.SFRSTCR_GRDE_CODE IS NOT NULL
               AND a.SFRSTCR_GRDE_CODE>=6
               AND a.sfrstcr_pidm =x.PIDM
               and a.SFRSTCR_TERM_CODE=(select max (a1.SFRSTCR_TERM_CODE)
                                         from SFRSTCR a1
                                         where 1=1
                                         and a1.sfrstcr_pidm=a.sfrstcr_pidm
                                         and a1.SFRSTCR_RESERVED_KEY=a.SFRSTCR_RESERVED_KEY
                                         )
               and t.SSBSECT_SUBJ_CODE||t.SSBSECT_CRSE_NUMB IN (SELECT ZSTPARA_PARAM_ID
                                             FROM ZSTPARA
                                             WHERE 1 = 1
                                             AND ZSTPARA_MAPA_ID ='MAT_PROYEM'
                                             and ZSTPARA_PARAM_VALOR=1
                                             ) ;
          EXCEPTION WHEN OTHERS THEN
         VALIDA_ASIG_2:=1  ;
            dbms_output.put_line('ERROR VALIDA SI TIENE MATERIA '||VALIDA_ASIG);
        END;

        IF x.num=1 then

            IF CONT_AVANCE=1 AND VALIDA_ASIG=0 THEN
                  dbms_output.put_line('SE SALE 1');
               exit;

            ELSIF CONT_AVANCE=0 AND VALIDA_ASIG=0 THEN

                    BEGIN

                       DELETE REL_ALUMNOS_X_ASIGNAR
                       WHERE 1=1
                       AND SVRPROY_PIDM=x.PIDM
                       AND REL_ALUMNOS_X_ASIGNAR_NO_REGLA=x.REGLA
                       AND CLAVE_MATERIA IN (SELECT ZSTPARA_PARAM_ID
                                                          FROM ZSTPARA
                                                          WHERE 1=1
                                                           AND ZSTPARA_MAPA_ID ='MAT_PROYEM'
                                                           );


                    EXCEPTION WHEN OTHERS THEN
                      NULL;
                    END;
                  dbms_output.put_line('BORRA 1');

            ELSIF CONT_AVANCE=1 AND VALIDA_ASIG=1 THEN

                      BEGIN

                       DELETE REL_ALUMNOS_X_ASIGNAR
                       WHERE 1=1
                       AND SVRPROY_PIDM=x.PIDM
                       AND REL_ALUMNOS_X_ASIGNAR_NO_REGLA=x.REGLA
                       AND CLAVE_MATERIA IN (SELECT ZSTPARA_PARAM_ID
                                                          FROM ZSTPARA
                                                          WHERE 1=1
                                                           AND ZSTPARA_MAPA_ID ='MAT_PROYEM'
                                                           );


                    EXCEPTION WHEN OTHERS THEN
                      NULL;
                    END;

            ELSIF CONT_AVANCE=0 AND VALIDA_ASIG=1 THEN

                    BEGIN

                       DELETE REL_ALUMNOS_X_ASIGNAR
                       WHERE 1=1
                       AND SVRPROY_PIDM=x.PIDM
                       AND REL_ALUMNOS_X_ASIGNAR_NO_REGLA=x.REGLA
                       AND CLAVE_MATERIA IN (SELECT ZSTPARA_PARAM_ID
                                                          FROM ZSTPARA
                                                          WHERE 1=1
                                                           AND ZSTPARA_MAPA_ID ='MAT_PROYEM'
                                                           );

                    EXCEPTION WHEN OTHERS THEN
                      NULL;
                    END;
                dbms_output.put_line('BORRA 3');
            END IF;

        elsif x.num=2 then

             if  CONT_AVANCE=0 and VALIDA_ASIG_2=1 THEN

                      BEGIN

                       DELETE REL_ALUMNOS_X_ASIGNAR
                       WHERE 1=1
                       AND SVRPROY_PIDM=x.PIDM
                       AND REL_ALUMNOS_X_ASIGNAR_NO_REGLA=x.REGLA
                       AND CLAVE_MATERIA IN (SELECT ZSTPARA_PARAM_ID
                                                          FROM ZSTPARA
                                                          WHERE 1=1
                                                           AND ZSTPARA_MAPA_ID ='MAT_PROYEM'
                                                           );


                    EXCEPTION WHEN OTHERS THEN
                      NULL;
                    END;

              ELSif CONT_AVANCE=0 and VALIDA_ASIG_2=0 THEN

                  BEGIN

                       DELETE REL_ALUMNOS_X_ASIGNAR
                       WHERE 1=1
                       AND SVRPROY_PIDM=x.PIDM
                       AND REL_ALUMNOS_X_ASIGNAR_NO_REGLA=x.REGLA
                       AND CLAVE_MATERIA IN (SELECT ZSTPARA_PARAM_ID
                                                          FROM ZSTPARA
                                                          WHERE 1=1
                                                           AND ZSTPARA_MAPA_ID ='MAT_PROYEM'
                                                           );


                    EXCEPTION WHEN OTHERS THEN
                      NULL;
                    END;

              ELSif CONT_AVANCE=1 and VALIDA_ASIG_2=0 THEN

                     BEGIN

                       DELETE REL_ALUMNOS_X_ASIGNAR
                       WHERE 1=1
                       AND SVRPROY_PIDM=x.PIDM
                       AND REL_ALUMNOS_X_ASIGNAR_NO_REGLA=x.REGLA
                       AND CLAVE_MATERIA IN (SELECT ZSTPARA_PARAM_ID
                                                          FROM ZSTPARA
                                                          WHERE 1=1
                                                           AND ZSTPARA_MAPA_ID ='MAT_PROYEM'
                                                           );


                    EXCEPTION WHEN OTHERS THEN
                      NULL;
                    END;

              ELSif CONT_AVANCE=1 and VALIDA_ASIG_2=1 THEN

              EXIT;

              END IF;

        END IF;

     END LOOP;
     commit;
END;
------
------
FUNCTION F_BAJA_MATERIAS_EMPRESARIAL (P_PIDM NUMBER)RETURN VARCHAR2 IS

l_califiacion number;
l_acredita varchar2(2);
l_materias_re NUMBER;
l_materias_dd NUMBER;
l_secuen_max number;
l_retorna varchar2(300):='EXITO';

BEGIN

    FOR a IN (

        SELECT *
        FROM szstume
        WHERE 1 = 1
        AND szstume_pidm = szstume_pidm
        and SZSTUME_SUBJ_CODE in  (SELECT ZSTPARA_PARAM_ID
                         FROM ZSTPARA
                         WHERE 1 = 1
                         AND ZSTPARA_MAPA_ID ='MAT_PROYEM'
                         and ZSTPARA_PARAM_VALOR=2)
               )
  loop

        BEGIN

            SELECT DISTINCT DECODE (szstume_grde_code_final,'0',null,szstume_grde_code_final) calif
            INTO l_califiacion
            FROM szstume
            WHERE 1 = 1
            AND szstume_no_regla = a.szstume_no_regla
            AND szstume_pidm = a.szstume_pidm
            and SZSTUME_SUBJ_CODE=a.SZSTUME_SUBJ_CODE;

        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

        BEGIN

            SELECT shrgrde_passed_ind
            INTO l_acredita
            FROM shrgrde
            WHERE 1 = 1
            AND shrgrde_levl_code= 'LI'
            AND shrgrde_code = l_califiacion;

        EXCEPTION WHEN OTHERS THEN
            NULL;
            l_acredita:=null;
        END;

     IF l_acredita IS NULL THEN

       NULL;

     ELSIF l_acredita ='Y'  THEN

       exit;

     ELSIF l_acredita ='N' THEN

        FOR d IN (
                        SELECT *
                        FROM szstume
                        WHERE 1 = 1
                        AND szstume_pidm = szstume_pidm
                        and SZSTUME_SUBJ_CODE in  (SELECT ZSTPARA_PARAM_ID
                                         FROM ZSTPARA
                                         WHERE 1 = 1
                                         AND ZSTPARA_MAPA_ID ='MAT_PROYEM' )
                     )
          LOOP

                  BEGIN

                     SELECT COUNT(*)
                     INTO l_materias_re
                     FROM szstume
                     WHERE 1 = 1
                     AND szstume_pidm = d.szstume_pidm
                     AND szstume_no_regla = d.szstume_no_regla
                     AND SZSTUME_SUBJ_CODE_COMP = SZSTUME_SUBJ_CODE_COMP
                     and SZSTUME_RSTS_CODE ='RE';

                   EXCEPTION WHEN OTHERS THEN
                         NULL;
                   END;

                   BEGIN

                     SELECT COUNT(*)
                     INTO l_materias_dd
                     FROM szstume
                     WHERE 1 = 1
                     AND szstume_pidm = d.szstume_pidm
                     AND szstume_no_regla = d.szstume_no_regla
                     AND SZSTUME_SUBJ_CODE_COMP =d.SZSTUME_SUBJ_CODE_COMP
                     and SZSTUME_RSTS_CODE ='DD';

                   EXCEPTION WHEN OTHERS THEN
                         NULL;
                   END;

                   IF L_MATERIAS_RE = 1 AND L_MATERIAS_DD = 0 THEN

                     BEGIN

                         SELECT MAX(NVL(szstume_seq_no,0))+1
                         INTO l_secuen_max
                         FROM szstume
                         WHERE 1 = 1
                         AND szstume_no_regla = d.szstume_no_regla
                         and szstume_pidm = d.szstume_pidm
                         AND szstume_subj_code_comp  = d.szstume_subj_code_comp
                         AND szstume_term_nrc =d.szstume_term_nrc ;

                     EXCEPTION WHEN OTHERS THEN
                         l_retorna:='No se encontro secuencia maxima '||sqlerrm;
                         null;
                     END;

                     BEGIN

                          INSERT INTO szstume VALUES(d.szstume_term_nrc,
                                                    d.szstume_pidm,
                                                    d.szstume_id,
                                                    SYSDATE,
                                                    USER,
                                                    0,
                                                    'BAJA_PROY_EMPRE',
                                                    d.SZSTUME_PWD,
                                                    NULL,
                                                    l_secuen_max,
                                                    'DD',
                                                    NULL,
                                                    d.szstume_subj_code_comp,
                                                    NULL,-- c.nivel,
                                                    NULL,
                                                    NULL,--  c.ptrm,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    d.szstume_subj_code_comp,
                                                    d.SZSTUME_START_DATE,--  c.inicio_clases,
                                                    d.szstume_no_regla,
                                                    NULL,
                                                    1,
                                                    1,
                                                    null
                                                    );
                     EXCEPTION WHEN OTHERS THEN
                        l_retorna:='No se pudo insertar en szstume '||sqlerrm;
                     END;

                     dbms_output.put_line('Inerto baja  ');

                     BEGIN

                          UPDATE sztprono SET sztprono_estatus_error ='S',
                                              sztprono_descripcion_error ='Baja proyecto empresarial'
                          WHERE 1 = 1
                          AND sztprono_no_regla = d.szstume_no_regla
                          AND sztprono_pidm =d.szstume_pidm
                          AND SZTPRONO_MATERIA_LEGAL=d.szstume_subj_code_comp;

                        EXCEPTION WHEN OTHERS THEN
                          NULL;
                        END;


                     BEGIN

                      FOR C IN (
                                SELECT ssbsect_crn crn,
                                         ssbsect_term_code term_code,
                                         sfrstcr_ptrm_code ptrm,
                                         sfrstcr_pidm pidm
                                  FROM ssbsect ,
                                       sfrstcr
                                  WHERE 1 = 1
                                  AND ssbsect_term_code = sfrstcr_term_code
                                  AND ssbsect_crn = sfrstcr_crn
                                  and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB=D.SZSTUME_SUBJ_CODE_COMP
                                  AND ssbsect_ptrm_start_date =d.SZSTUME_START_DATE
                                  AND sfrstcr_grde_code is  null
                                  AND substr(ssbsect_term_code,5,1) not in (8,9)
                                  AND sfrstcr_rsts_code ='RE'
                                  AND sfrstcr_pidm = p_pidm
                                  )
                             LOOP

                                BEGIN

                                  UPDATE SFRSTCR SET sfrstcr_rsts_code ='DD',
                                                     SFRSTCR_USER_ID = user,
                                                     SFRSTCR_DATA_ORIGIN ='Baja proyecto empresarial',
                                                     SFRSTCR_USER = user,
                                                     SFRSTCR_ACTIVITY_DATE=sysdate
                                  WHERE 1 = 1
                                  AND sfrstcr_pidm = c.pidm
                                  AND sfrstcr_term_code =c.term_code
                                  AND sfrstcr_ptrm_code = c.ptrm
                                  AND sfrstcr_crn  =c.crn;

                                EXCEPTION WHEN OTHERS THEN
                                    l_retorna:='No se pudo actualizar el registro sfctcr '||sqlerrm;
                                END;

                             END LOOP;

                     END;

                  END IF;

          END LOOP;

     END IF;

  END LOOP;

RETURN(l_retorna);

END;
-------
-------
END PKG_PRONO_PRONO_OPM;
/
