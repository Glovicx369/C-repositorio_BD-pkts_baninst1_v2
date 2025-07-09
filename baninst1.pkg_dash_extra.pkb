DROP PACKAGE BODY BANINST1.PKG_DASH_EXTRA;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_dash_extra as

 FUNCTION  f_agrupado_alumno (p_pidm number) RETURN pkg_dash_extra.cursor_out_agrupa
           AS
                c_out_agrupa pkg_dash_extra.cursor_out_agrupa;

  BEGIN
       open c_out_agrupa
                FOR  SELECT nombre,
                           matricula,
                           programa,
                           Descripcion_programa,
                           estado,
                           alianza,
                           NVL(AC,0)AC,
                           NVL(EC,0)EC,
                           NVL(NA,0)NA,
                           num_materias TOTALMAT,
                           NVL(ROUND(AC*100/ num_materias),0) PROMEDIO,
                           Descripcion_ali
                    FROM
                    (
                        select nombre,
                               matricula,
                               programa,
                               Descripcion_programa,
                               estado,
                               alianza,
                               COUNT(mat_acre)conteo,
                               num_materias,
                               MAT_ACRE,
                               Descripcion_ali
                        from
                        (
                        select REPLACE((select distinct SPRIDEN_FIRST_NAME||' '||SPRIDEN_LAST_NAME
                                from spriden
                                where 1 = 1
                                and spriden_change_ind is null
                                and spriden_pidm = a.szstume_pidm),'/',' ') nombre,
                                (select distinct spriden_id
                                from spriden
                                where 1 = 1
                                and spriden_change_ind is null
                                and spriden_pidm = a.szstume_pidm)
                                matricula,
                                c.programa  programa,
                                (select distinct SZTDTEC_PROGRAMA_COMP
                                        from SZTDTEC
                                        where 1=1
                                        and SZTDTEC_PROGRAM=c.programa
                                        and rownum =1  )Descripcion_programa,
                                ESTATUS_D estado,
                                SZTALIA_CODE alianza,
                                C.NIVEL NIVELA,
                                SZTALIA_TEXT Descripcion_ali,
                                szstume_subj_code materia,
                                SZSTUME_GRDE_CODE_FINAL califica,
                                SZTALIA_NUM_MATERIAS num_materias,
                                DECODE((select SHRGRDE_PASSED_IND
                                        from SHRGRDE
                                        where 1 = 1
                                        and SHRGRDE_CODE = a.SZSTUME_GRDE_CODE_FINAL
                                        AND SHRGRDE_CODE <>'0'
                                        and SHRGRDE_LEVL_CODE=c.NIVEL
                                         and rownum =1),'Y','AC','N','NA',NULL,'EC')mat_acre
                        from szstume a
                        join SZTALMT b on b.SZTALMT_MATERIA= a.szstume_subj_code
                        join SZTALIA l on l.SZTALIA_CODE=b.SZTALMT_ALIANZA
                        join tztprog c on c.pidm = a.szstume_pidm
--                                       and SP=(select max(s.SP)
--                                               from TZTPROG s
--                                               where 1=1
--                                               and C.PIDM=s.PIDM
--                                               and c.programa=s.programa)
                        where 1 = 1
                        And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                               from SZSTUME a1
                                               Where a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                               And a.SZSTUME_STAT_IND = a1.SZSTUME_STAT_IND
                                               and A.SZSTUME_SUBJ_CODE=A1.SZSTUME_SUBJ_CODE
                                               And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA)
                        and l.SZTALIA_LVEL=b.SZTALMT_NIVEL
                        AND L.SZTALIA_CODE NOT IN( select ZSTPARA_PARAM_VALOR
                                                                     FROM ZSTPARA
                                                                     WHERE 1=1
                                                                     AND ZSTPARA_MAPA_ID='EXCLUIR_AVEXTRA'
                                                                     and ZSTPARA_PARAM_ID= DECODE(c.NIVEL,'MS','MA',
                                                                                                              'MA','MA',
                                                                                                              'LI','LI',
                                                                                                              'DO','DO'))
                        and SZSTUME_PIDM =p_pidm
                        AND SZSTUME_RSTS_CODE='RE'
                        AND DECODE(c.NIVEL,'MS','MA',
                                          'MA','MA',
                                          'LI','LI',
                                          'DO','DO')=SZTALMT_NIVEL
                        )
                        group by MAT_ACRE,
                                 nombre,
                                 matricula,
                                 programa,
                                 Descripcion_programa,
                                 alianza,
                                 num_materias,
                                 estado,
                                 Descripcion_ali
                    )
                    PIVOT(MAX(conteo)
                            for MAT_ACRE
                            in ('AC' AS  AC, 'EC' AS EC,'NA' AS NA)
                    )
                    GROUP BY nombre,
                           matricula,
                           programa,
                           Descripcion_programa,
                           estado,
                           alianza,
                           num_materias,
                           Descripcion_ali,
                           AC,
                           EC,
                           NA
                           ;

       RETURN (c_out_agrupa);

  END;

---
---

   FUNCTION  f_alumno_detalle (p_pidm number) RETURN pkg_dash_extra.cursor_out_agrupados
           AS
                c_out_agrupados pkg_dash_extra.cursor_out_agrupados;

  BEGIN
       open c_out_agrupados
                 FOR  SELECT
                       SCRSYLN_LONG_COURSE_TITLE ASIGNATURA,
                       SZSTUME_START_DATE FECHA,
                       SZTALMT_ALIANZA alianza,
                       SZSTUME_SUBJ_CODE CLAVE,
--                       DECODE(A.SZSTUME_GRDE_CODE_FINAL, NULL,'EC',
--                                      '0','EC',
--                                      'NP','NA',
--                                      A.SZSTUME_GRDE_CODE_FINAL
--                                      ) AS CALIFICA,
                       DECODE((SELECT SHRGRDE_PASSED_IND
                                FROM SHRGRDE
                                WHERE 1 = 1
                                AND SHRGRDE_CODE = A.SZSTUME_GRDE_CODE_FINAL
                                AND SHRGRDE_CODE <>'0'
                                and SZSTUME_RSTS_CODE='RE'
                                AND SHRGRDE_LEVL_CODE=C.NIVEL
                                 and rownum =1 ),'Y','AC','N','NA',NULL,'EC')MAT_ACRE,
                       PROGRAMA PROGRAMA
               FROM SZSTUME A
               JOIN TZTPROG C ON C.PIDM = A.SZSTUME_PIDM
--                              and SP=(select max(s.SP)
--                                       from TZTPROG s
--                                       where 1=1
--                                       and C.PIDM=s.PIDM)
               join SZTALMT b on b.SZTALMT_MATERIA= a.szstume_subj_code
               JOIN scrsyln E ON SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB = SZSTUME_SUBJ_CODE
               WHERE 1 = 1
               AND A.SZSTUME_SEQ_NO = (SELECT MAX (A1.SZSTUME_SEQ_NO)
                                      FROM SZSTUME A1
                                      WHERE A.SZSTUME_PIDM = A1.SZSTUME_PIDM
                                      and A.SZSTUME_SUBJ_CODE=A1.SZSTUME_SUBJ_CODE
                                      AND A.SZSTUME_STAT_IND = A1.SZSTUME_STAT_IND
                                      AND A.SZSTUME_NO_REGLA = A1.SZSTUME_NO_REGLA)
               AND SZTALMT_ALIANZA NOT IN( select ZSTPARA_PARAM_VALOR
                                                                     FROM ZSTPARA
                                                                     WHERE 1=1
                                                                     AND ZSTPARA_MAPA_ID='EXCLUIR_AVEXTRA'
                                                                     and ZSTPARA_PARAM_ID=DECODE(c.NIVEL,'MS','MA',
                                                                                                      'MA','MA',
                                                                                                      'LI','LI',
                                                                                                      'DO','DO'))
               AND SZSTUME_PIDM = p_pidm
               AND SZSTUME_RSTS_CODE='RE'
               AND DECODE(c.NIVEL,'MS','MA',
                                          'MA','MA',
                                          'LI','LI',
                                          'DO','DO')=SZTALMT_NIVEL
               ORDER BY A.SZSTUME_START_DATE,SZTALMT_ALIANZA ASC;

             RETURN (c_out_agrupados);

  END;

----
----
PROCEDURE P_JOB_INSERT_AVANCE_EXTRA IS

   BEGIN

       DELETE SATURN.SZTHITE;

       COMMIT;


                  FOR X IN
                         (SELECT PIDM,
                           matricula,
                           nombre,
                           campus,
                           nivel,
                           programa,
                           Descripcion_programa,
                           estado,
                           alianza,
                           Descripcion_ali,
                           NVL(AC,0)AC,
                           NVL(EC,0)EC,
                           NVL(NA,0)NA,
                           NUM_MATERIAS-(NVL(AC,0)+NVL(EC,0)+NVL(NA,0))POR_CURSAR,
                           num_materias TOTALMAT,
                           NVL(ROUND(AC*100/ num_materias),0) AVANCE_EXTRACURRICULAR,
                           study_p ,
                           per_catalogo,
                           tipo_ingreso,
                           desc_tipo_ingreso
                    FROM
                    (
                        select PIDM,
                               matricula,
                               nombre,
                               campus,
                               nivel,
                               programa,
                               Descripcion_programa,
                               estado,
                               alianza,
                               COUNT(mat_acre)conteo,
                               num_materias,
                               MAT_ACRE,
                               Descripcion_ali,
                               study_p,
                               per_catalogo,
                               tipo_ingreso,
                               desc_tipo_ingreso
                        from
                        (
                        select REPLACE((select distinct SPRIDEN_FIRST_NAME||' '||SPRIDEN_LAST_NAME
                                from spriden
                                where 1 = 1
                                and spriden_change_ind is null
                                and spriden_pidm = a.szstume_pidm),'/',' ') nombre,
                                (select distinct spriden_id
                                from spriden
                                where 1 = 1
                                and spriden_change_ind is null
                                and spriden_pidm = a.szstume_pidm) matricula,
                                SUBSTR(c.programa,1,3)campus,
                                SUBSTR(c.programa,4,2)nivel,
                                c.programa  programa,
                                c.pidm PIDM,
                                c.sp study_p,
                                c.CTLG per_catalogo,
                                c.TIPO_INGRESO tipo_ingreso,
                                c.TIPO_INGRESO_DESC desc_tipo_ingreso,
                                (select distinct SZTDTEC_PROGRAMA_COMP
                                        from SZTDTEC
                                        where 1=1
                                        and SZTDTEC_PROGRAM=c.programa
                                        and rownum =1  )Descripcion_programa,
                                ESTATUS_D estado,
                                SZTALIA_CODE alianza,
                                SZTALIA_LVEL NIVELA,
                                SZTALIA_TEXT Descripcion_ali,
                                szstume_subj_code materia,
                                SZSTUME_GRDE_CODE_FINAL califica,
                                SZTALIA_NUM_MATERIAS num_materias,
                                DECODE((select SHRGRDE_PASSED_IND
                                        from SHRGRDE
                                        where 1 = 1
                                        and SHRGRDE_CODE = a.SZSTUME_GRDE_CODE_FINAL
                                        AND SHRGRDE_CODE <>'0'
                                        and SHRGRDE_LEVL_CODE=c.NIVEL
                                         and rownum =1),'Y','AC','N','NA',NULL,'EC')mat_acre
                        from szstume a
                        join SZTALMT b on b.SZTALMT_MATERIA= a.szstume_subj_code
                        join SZTALIA l on l.SZTALIA_CODE=b.SZTALMT_ALIANZA
                                        and l.SZTALIA_LVEL=b.SZTALMT_NIVEL
                        join tztprog c on c.pidm = a.szstume_pidm
                                       and SP=(select max(s.SP)
                                               from TZTPROG s
                                               where 1=1
                                               and C.PIDM=s.PIDM
                                               and c.programa=s.programa)
                        where 1 = 1
                        And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                               from SZSTUME a1
                                               Where a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                               And a.SZSTUME_STAT_IND = a1.SZSTUME_STAT_IND
                                               and A.SZSTUME_SUBJ_CODE=A1.SZSTUME_SUBJ_CODE
                                               And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA)
--                        and SZSTUME_PIDM =42050
                        and l.SZTALIA_LVEL=b.SZTALMT_NIVEL
                        AND L.SZTALIA_CODE NOT IN( select ZSTPARA_PARAM_VALOR
                                                                     FROM ZSTPARA
                                                                     WHERE 1=1
                                                                     AND ZSTPARA_MAPA_ID='EXCLUIR_AVEXTRA'
                                                                     and ZSTPARA_PARAM_ID=DECODE(c.NIVEL,'MS','MA',
                                                                                                  'MA','MA',
                                                                                                  'LI','LI',
                                                                                                  'DO','DO'))
                        AND SZSTUME_RSTS_CODE='RE'
                        AND DECODE(c.NIVEL,'MS','MA',
                                          'MA','MA',
                                          'LI','LI',
                                          'DO','DO')=SZTALMT_NIVEL
                        )
                        group by pidm,
                                 MAT_ACRE,
                                 matricula,
                                 nombre,
                                 campus,
                                 nivel,
                                 programa,
                                 Descripcion_programa,
                                 alianza,
                                 num_materias,
                                 estado,
                                 Descripcion_ali,
                                 study_p,
                                 per_catalogo,
                                 tipo_ingreso,
                                 desc_tipo_ingreso
                    )
                    PIVOT(MAX(conteo)
                            for MAT_ACRE
                            in ('AC' AS  AC, 'EC' AS EC,'NA' AS NA)
                    )
                    GROUP BY pidm,
                           nombre,
                           matricula,
                           campus,
                            nivel,
                           programa,
                           Descripcion_programa,
                           estado,
                           alianza,
                           num_materias,
                           Descripcion_ali,
                           AC,
                           EC,
                           NA,
                           study_p,
                           per_catalogo,
                           tipo_ingreso,
                           desc_tipo_ingreso
     )
     LOOP

         BEGIN
          INSERT INTO SATURN.SZTHITE VALUES(
                                       X.PIDM,
                                       X.matricula,
                                       X.nombre,
                                       X.campus,
                                       X.nivel,
                                       X.programa,
                                       X.Descripcion_programa,
                                       X.estado,
                                       X.alianza,
                                       X.Descripcion_ali,
                                       X.AC,
                                       X.EC,
                                       X.NA,
                                       X.POR_CURSAR,
                                       X.TOTALMAT,
                                       X.AVANCE_EXTRACURRICULAR,
                                       X.study_p ,
                                       X.per_catalogo,
                                       X.tipo_ingreso,
                                       X.desc_tipo_ingreso
                                     );
            exception WHEN others THEN
              DBMS_OUTPUT.put_line ('Error al INSERTAR ' || SQLERRM);
          END;

     END LOOP;

    COMMIT;

   END;

 FUNCTION f_consulta_extra_activos(p_no_regla  number, p_pidm number)return number is
 l_retorna  number;

BEGIN

    begin

       Select count(1) activos
        into l_retorna
            from szstume ume
            where 1 =1
            and ume.SZSTUME_no_regla = p_no_regla
            and ume.szstume_pidm = p_pidm
            AND UME.SZSTUME_SUBJ_CODE  in (select SZTALMT_MATERIA
                                                from SZTALMT
                                                where 1=1
                                                )
            AND ume.SZSTUME_RSTS_CODE='RE'
            and ume.SZSTUME_SEQ_NO =(select max(ume1.SZSTUME_SEQ_NO)
                                     from szstume ume1
                                     where 1 = 1
                                     and ume1.SZSTUME_SUBJ_CODE = ume.SZSTUME_SUBJ_CODE
                                     and ume1.szstume_no_regla = ume.szstume_no_regla
                                     and ume1.szstume_pidm = ume.szstume_pidm
                                    );
    exception when others then
           l_retorna:=0;
    end;

  return l_retorna;
 end;
-----
-----
function f_cambia_calif_extra(p_pidm number,p_cali_nueva varchar2,p_materia varchar2,p_regla number)
return varchar2
as
    l_retorna varchar2(200):='Exito';
    l_contar  number;
BEGIN

    BEGIN

         FOR c in (
               Select Ume.szstume_pidm pidm,
                       UME.szstume_subj_code materia,
                      Ume.SZSTUME_NO_REGLA regla
            from szstume ume
            where 1 =1
            and ume.SZSTUME_no_regla = p_regla
            and ume.szstume_pidm = p_pidm
            AND UME.SZSTUME_SUBJ_CODE=p_materia
            AND UME.SZSTUME_SUBJ_CODE  in (select SZTALMT_MATERIA
                                                from SZTALMT
                                                where 1=1
                                                )
            AND ume.SZSTUME_RSTS_CODE='RE'
            and ume.SZSTUME_SEQ_NO =(select max(ume1.SZSTUME_SEQ_NO)
                                     from szstume ume1
                                     where 1 = 1
                                     and ume1.SZSTUME_SUBJ_CODE = ume.SZSTUME_SUBJ_CODE
                                     and ume1.szstume_no_regla = ume.szstume_no_regla
                                     and ume1.szstume_pidm = ume.szstume_pidm
                                    )
       )

      LOOP
       -- dbms_output.put_line(' Contar '||l_contar);

              begin

                        SELECT count(me.szstume_pidm)
                        into l_contar
                        FROM szstume me
                         WHERE     1 = 1
                         And me.szstume_pidm = c.pidm
                         and me.szstume_subj_code= c.materia
                         and me.SZSTUME_NO_REGLA= c.regla
                         AND ME.SZSTUME_SUBJ_CODE IN (SELECT SZTALMT_MATERIA
                                                             FROM SZTALMT
                                                             WHERE     1 = 1
                                                             AND SZTALMT_ALIANZA NOT IN 'TAEX')
                   group by me.szstume_pidm  ;
                exception when others then
                    l_contar:=0;
              end;

          if l_contar >= 1 then

               begin

                   update szstume
                   set SZSTUME_GRDE_CODE_FINAL =p_cali_nueva,
                       SZSTUME_ACTIVITY_DATE=sysdate,
                       SZSTUME_USER_ID=user,
                       SZSTUME_OBS='Actualización de calificación'
                   where 1 = 1
                   and szstume_pidm =C.pidm
                   and szstume_no_regla = C.regla
                   and SZSTUME_SUBJ_CODE = C.materia
                   and SZSTUME_RSTS_CODE='RE';

               exception when others then

                   l_retorna:=' Verifique en szstume '||sqlerrm;

               end;

                if l_retorna ='Exito' then

                     -- dbms_output.put_line(' entra 3 '||l_retorna);
                      commit;
                      return(l_retorna);
                else

                      return(l_retorna);
                      rollback;

                end if;

          else

            l_retorna:='No hay registros en la consulta';

          end if;

      END LOOP;

    end;

 return l_retorna;

END;

procedure bitacora (pidm in number, vl_periodo in varchar2, sp in number, vl_programa in varchar2)
as

  vn_sec_SGRSCMT number:=0;
  l_descripcion varchar2(2000):= null;

Begin

    Begin
          SELECT NVL(MAX(SGRSCMT_SEQ_NO),0)+1
        INTO vn_sec_SGRSCMT
      FROM SGRSCMT
      WHERE SGRSCMT_PIDM  = pidm
      AND SGRSCMT_TERM_CODE = vl_periodo;

    Exception
            When Others then
              vn_sec_SGRSCMT :=1;
    End;

     l_descripcion:=    'CONVALIDACION: '||vl_periodo ||' '||vl_programa;



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
            pidm
          , vn_sec_SGRSCMT
          , vl_periodo
          , l_descripcion
          , SYSDATE
          , 'SZFCONV'
          , user
          , sp
         );
    Exception
             WHEN DUP_VAL_ON_INDEX THEN
                    NULL;
            When Others then
            null;
    End;


Exception
    when others then
        null;
End bitacora;

Function   inscripcion_conv(MATRI in varchar2, FECHA_INI varchar2,  subj in varchar2,REGLA NUMBER, n_prog varchar2, title in varchar2, calif in varchar2, MATRI2 varchar2, fecha_inicial varchar2) Return varchar2
AS
VL_pidm number;
n_nivel varchar2(2):= null;
vl_exito VARCHAR2(30):='EXITO';
VL_REGLA NUMBER;
 BEGIN

    FOR C IN (
               SELECT *
                from szstume ume
                where 1 =1
                and ume.szstume_id =MATRI
                AND ume.SZSTUME_NO_REGLA=REGLA
                AND ume.SZSTUME_RSTS_CODE='RE'
                AND UME.SZSTUME_SUBJ_CODE=subj
                AND UME.SZSTUME_START_DATE=FECHA_INI
               )
   LOOP

     Begin
         select spriden_pidm
             into VL_pidm
          from spriden
         where spriden_id=MATRI2
         and spriden_change_ind is null;

        dbms_output.put_line('ENTRA 1'||VL_pidm);
     Exception
     When Others then
        vl_exito:='Error al buscar Persona: '||sqlerrm;
        dbms_output.put_line('ENTRA 1'||VL_pidm);
     End;

     Begin

        SELECT DISTINCT ume.SZSTUME_NO_REGLA
         INTO VL_REGLA
                from szstume ume
                where 1 =1
                and ume.szstume_id =MATRI
--                AND ume.SZSTUME_NO_REGLA=REGLA
                AND ume.SZSTUME_RSTS_CODE='RE'
                AND UME.SZSTUME_SUBJ_CODE=subj
                AND UME.SZSTUME_START_DATE=FECHA_INI;
           dbms_output.put_line('ENTRA 2'||VL_REGLA);
      Exception
     When Others then
        VL_REGLA:=REGLA;
        dbms_output.put_line('ENTRA 2'||VL_REGLA||' '||REGLA);
     End;

    Begin
            select distinct SOBCURR_LEVL_CODE
            Into n_nivel
            from SOBCURR
            where SOBCURR_PROGRAM = n_prog;
            dbms_output.put_line('ENTRA 3'||n_nivel);
    Exception
        When Others then
            n_nivel := null;
           dbms_output.put_line('ENTRA 3'||n_nivel);
    End;

    BEGIN

      INSERT INTO SZSTUME VALUES (
          C.SZSTUME_TERM_NRC         ,
          VL_pidm             ,
          MATRI2,
          SYSDATE    ,
          USER          ,
          C.SZSTUME_STAT_IND         ,
          C.SZSTUME_OBS              ,
          C.SZSTUME_PWD              ,
          C.SZSTUME_MDLE_ID          ,
          C.SZSTUME_SEQ_NO           ,
          C.SZSTUME_RSTS_CODE        ,
          calif,-- C.SZSTUME_GRDE_CODE_FINAL  ,
          C.SZSTUME_SUBJ_CODE        ,
          n_nivel        ,
          NULL,--SZSTUME_POBI_SEQ_NO      ,
          NULL,--SZSTUME_PTRM             ,
          NULL,--SZSTUME_CAMP_CODE        ,
          NULL,--SZSTUME_CAMP_CODE_COMP   ,
          NULL,--SZSTUME_LEVL_CODE_COMP   ,
          calif,-- C.SZSTUME_TERM_NRC_COMP    ,
          C.SZSTUME_SUBJ_CODE_COMP   ,
          FECHA_INI       ,
          REGLA         ,
          C.SZSTUME_SECUENCIA        ,
          C.SZSTUME_NIVE_SEQNO       ,
          C.SZSTUME_SINCRO           ,
          C.SZSTUME_SINCRO_OBS       )
       ;
       dbms_output.put_line('INSERTA SZSTUME');
       COMMIT;
    Exception When Others then

       vl_exito:='NO INSERTO';

       dbms_output.put_line('NO INSERTA SZSTUME');

    End;

    Begin

         UPDATE szstume
         SET SZSTUME_GRDE_CODE_FINAL=calif
         WHERE 1=1
                and szstume_id =MATRI2
                AND SZSTUME_NO_REGLA=REGLA
                AND SZSTUME_RSTS_CODE='RE'
                AND SZSTUME_SUBJ_CODE=subj
                AND SZSTUME_START_DATE=FECHA_INI;

         dbms_output.put_line('ACTUALIZA SZSTUME');

          COMMIT;
      Exception
     When Others then
        VL_REGLA:=REGLA;

         dbms_output.put_line('ACTUALIZA SZSTUME'||REGLA);

     End;

   END LOOP;

   COMMIT;

   Return vl_exito;

 END inscripcion_conv;

end;
/

DROP PUBLIC SYNONYM PKG_DASH_EXTRA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_DASH_EXTRA FOR BANINST1.PKG_DASH_EXTRA;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_DASH_EXTRA TO PUBLIC;
