DROP PACKAGE BODY BANINST1.PKG_REPORTES_PIPELINED;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_reportes_pipelined AS
--
--
  FUNCTION f_asignacion_materias(p_regla number) RETURN t_tab PIPELINED is
    l_row  t_prono;
    begin


        for c in (SELECT MATRICULA,
                           PERIODO,
                           PROGRAMA,
                           MATERIA_LEGAL,
                           SECUENCIA,
                           PARTE_PERIODO,
                           MATERIA_BANNER,
                           FECHA_INICIO,
                           REGLA,
                           JORNADA,
                           SP,
                           QA,
                           BIM,
                           TYPE_CODE,
                           CASE WHEN ptrm_pi ='A4B' THEN 'A0B'
                                WHEN ptrm_pi ='M4B' THEN 'M0B'
                                WHEN ptrm_pi ='A4D' THEN 'A1A'
                                WHEN ptrm_pi ='M4D' THEN 'M1A'
                                WHEN ptrm_pi ='A3C' THEN 'A0C'
                                WHEN ptrm_pi ='M3C' THEN 'M0C'
                                WHEN ptrm_pi ='A3A' THEN 'A0A'
                                WHEN ptrm_pi ='M3A' THEN 'M0A'
                                WHEN ptrm_pi ='A3B' THEN 'A0B'
                                WHEN ptrm_pi ='M3B' THEN 'M0B'
                                WHEN ptrm_pi ='A3D' THEN 'A1A'
                                WHEN ptrm_pi ='M3D' THEN 'M1A'
                           ELSE
                                 ptrm_pi
                           END ptrm_pi,
                           tipo_ini
                    FROM
                    (
                    select SZTPRONO_ID matricula,
                           SZTPRONO_TERM_CODE periodo,
                           SZTPRONO_PROGRAM programa,
                           SZTPRONO_MATERIA_LEGAL materia_legal,
                           SZTPRONO_SECUENCIA secuencia,
                           SZTPRONO_PTRM_CODE parte_periodo,
                           SZTPRONO_MATERIA_BANNER materia_banner,
                           SZTPRONO_FECHA_INICIO fecha_inicio,
                           SZTPRONO_NO_REGLA regla,
                           SZTPRONO_JORNADA jornada,
                           SZTPRONO_STUDY_PATH sp,
                           SZTPRONO_CUATRI qa,
                           SZTPRONO_PTRM_CODE_NW bim,
                           SZTPRONO_ESTATUS type_code,
                           NVL((
                            SELECT distinct min(SFRSTCR_PTRM_CODE) ptrm_pi
                            FROM SFRSTCR a
                            WHERE 1 = 1
                            AND a.sfrstcr_pidm = sztprono_pidm
                            AND a.sfrstcr_stsp_key_sequence =sztprono_study_path
                            AND SUBSTR(A.sfrstcr_term_code,5,1)NOT IN(8,9)
                            AND a.sfrstcr_rsts_code ='RE'
                            AND sfrstcr_term_code =(select min(b.sfrstcr_term_code)
                                                    from sfrstcr b
                                                    where 1 = 1
                                                    and a.sfrstcr_pidm = b.sfrstcr_pidm
                                                    and a.sfrstcr_stsp_key_sequence =b.sfrstcr_stsp_key_sequence
                                                    and a.sfrstcr_rsts_code = b.sfrstcr_rsts_code
                                                    )
                             AND a.sfrstcr_ptrm_code = (SELECT min (d1.sfrstcr_ptrm_code)
                                                        FROM sfrstcr D1
                                                        WHERE 1=1
                                                        AND a.sfrstcr_pidm = d1.sfrstcr_pidm
                                                        AND a.sfrstcr_term_code = d1.sfrstcr_term_code
                                                        AND a.sfrstcr_rsts_code = d1.sfrstcr_rsts_code
                                                        )
                                                 ),SZTPRONO_PTRM_CODE)ptrm_pi,
                    SZTPRONO_TIPO_INICIO tipo_ini
                    from sztprono
                    where 1 = 1
                    and sztprono_no_regla = p_regla
                    order by sztprono_id,
                             sztprono_secuencia
                    )a
                    where 1 = 1
                    order by matricula, secuencia
                )loop

                     l_row.MATRICULA := c.MATRICULA;
                     l_row.PERIODO := c.PERIODO;
                     l_row.PROGRAMA := c.PROGRAMA;
                     l_row.MATERIA_LEGAL := c.MATERIA_LEGAL;
                     l_row.SECUENCIA :=c.SECUENCIA;
                     l_row.PARTE_PERIODO := c.PARTE_PERIODO;
                     l_row.MATERIA_BANNER :=c.MATERIA_BANNER;
                     l_row.FECHA_INICIO := c.FECHA_INICIO;
                     l_row.REGLA := c.regla;
                     l_row.JORNADA := c.jornada;
                     l_row.SP :=c.sp;
                     l_row.QA :=c.qa;
                     l_row.BIM :=c.bim;
                     l_row.TYPE_CODE := c.TYPE_CODE;
                     l_row.PTRM_PI :=c.PTRM_PI;
                     l_row.tipo_ini := c.tipo_ini;
                     PIPE ROW (l_row);

                end loop;


    end;
--
--
    FUNCTION f_alumnos_sin_materias (p_regla number) return t_tab_fa PIPELINED
    is
    l_row  t_falta_alumno;
    begin

        for c in (select *
                    from
                    (
                    select distinct ID_ALUMNO matricula,
                                    REL_PROGRAMAXALUMNO_no_regla regla
                    from REL_PROGRAMAXALUMNO
                    where 1 = 1
                    and REL_PROGRAMAXALUMNO_no_regla = p_regla
                    minus
                    select distinct ID_ALUMNO matricula,
                                    REL_ALUMNOS_X_ASIGNAR_no_regla regla
                    from REL_ALUMNOS_X_ASIGNAR
                    where 1 = 1
                    and REL_ALUMNOS_X_ASIGNAR_no_regla = p_regla
                    )
                 )loop

                    l_row.MATRICULA := c.MATRICULA;
                    l_row.regla := c.regla;
                    l_row.usuario := user;
                    l_row.fecha_ejecucion:=sysdate;
                    PIPE ROW (l_row);

                 end loop;
    end;

FUNCTION F_ALUMNOS_ALIANZAS (p_regla number) return t_tab_ali PIPELINED
  is
    l_row  t_alianza;
BEGIN
  for c in (
                  select *
                    from
                    (
                        SELECT max(DISTINCT etiqueta)conteo,
                               matricula,
                               periodo,
                               programa,
                               materia_legal,
                               secuencia,
                               parte_periodo,
                               materia_banner,
                               fecha_inicio,
                               regla,
                               jornada,
                               sp,
                               qa,
                               bim,
                               type_code,
                               ptrm_pi,
                               tipo_inicio,
                               etiqueta
                        FROM
                        (
                            SELECT sztprono_id matricula,
                                   sztprono_term_code periodo,
                                   sztprono_program programa,
                                   sztprono_materia_legal materia_legal,
                                   sztprono_secuencia secuencia,
                                   sztprono_ptrm_code parte_periodo,
                                   sztprono_materia_banner materia_banner,
                                   sztprono_fecha_inicio fecha_inicio,
                                   sztprono_no_regla regla,
                                   sztprono_jornada jornada,
                                   sztprono_study_path sp,
                                   sztprono_cuatri qa,
                                   sztprono_ptrm_code_nw bim,
                                   sztprono_estatus type_code,
                                   NVL((
                                    SELECT distinct min(SFRSTCR_PTRM_CODE) ptrm_pi
                                    FROM SFRSTCR a
                                    WHERE 1 = 1
                                    AND a.sfrstcr_pidm = sztprono_pidm
                                    AND a.sfrstcr_stsp_key_sequence =sztprono_study_path
                                    AND SUBSTR(A.sfrstcr_term_code,5,1)NOT IN(8,9)
                                    AND a.sfrstcr_rsts_code ='RE'
                                    AND sfrstcr_term_code =(select min(b.sfrstcr_term_code)
                                                            from sfrstcr b
                                                            where 1 = 1
                                                            and a.sfrstcr_pidm = b.sfrstcr_pidm
                                                            and a.sfrstcr_stsp_key_sequence =b.sfrstcr_stsp_key_sequence
                                                            and a.sfrstcr_rsts_code = b.sfrstcr_rsts_code
                                                            )
--                                     AND a.sfrstcr_ptrm_code = (SELECT min (d1.sfrstcr_ptrm_code)
--                                                                FROM sfrstcr D1
--                                                                WHERE 1=1
--                                                                AND a.sfrstcr_pidm = d1.sfrstcr_pidm
--                                                                AND a.sfrstcr_term_code = d1.sfrstcr_term_code
--                                                                AND a.sfrstcr_rsts_code = d1.sfrstcr_rsts_code
--                                                                )
                                                         ),SZTPRONO_PTRM_CODE)ptrm_pi,
                              (SELECT ZSTPARA_PARAM_VALOR  FROM (
                                                   SELECT distinct NVL(min(SFRSTCR_PTRM_CODE),SZTPRONO_PTRM_CODE) ptrm_pi
                                                        FROM SFRSTCR a
                                                        WHERE 1 = 1
                                                        AND a.sfrstcr_pidm = sztprono_pidm
                            --                            sztprono_pidm
                                                        AND a.sfrstcr_stsp_key_sequence =sztprono_study_path
                            --                            sztprono_study_path
                                                        AND SUBSTR(A.sfrstcr_term_code,5,1)NOT IN(8,9)
                                                        AND a.sfrstcr_rsts_code ='RE'
                                                        AND sfrstcr_term_code =(select min(b.sfrstcr_term_code)
                                                                                from sfrstcr b
                                                                                where 1 = 1
                                                                                and a.sfrstcr_pidm = b.sfrstcr_pidm
                                                                                and a.sfrstcr_stsp_key_sequence =b.sfrstcr_stsp_key_sequence
                                                                                and a.sfrstcr_rsts_code = b.sfrstcr_rsts_code
                                                                                )
--                                                         AND a.sfrstcr_ptrm_code = (SELECT min (d1.sfrstcr_ptrm_code)
--                                                                                    FROM sfrstcr D1
--                                                                                    WHERE 1=1
--                                                                                    AND a.sfrstcr_pidm = d1.sfrstcr_pidm
--                                                                                    AND a.sfrstcr_term_code = d1.sfrstcr_term_code
--                                                                                    AND a.sfrstcr_rsts_code = d1.sfrstcr_rsts_code
--                                                                                    )
                                                                                     ),ZSTPARA
                                 WHERE 1=1
                                 AND ptrm_pi= ZSTPARA_PARAM_ID
                                 AND ZSTPARA_MAPA_ID='PARTES_ANT_NOR')TIPO_INICIO,
                            GORADID_ADID_CODE etiqueta
                            from sztprono
                            left join goradid on sztprono_pidm = GORADID_PIDM
                                        and GORADID_ADID_CODE in (select distinct  SZTALIA_CODE
                                                                  from SZTALIA
                                                                  where 1 = 1
                                                                  and sztalia_active ='S')
                            where 1 = 1
                            and sztprono_no_regla = p_regla
                    --        and sztprono_id ='010385783'
                            order by sztprono_id,
                                     sztprono_secuencia
                        )
                        group by matricula,
                                 periodo,
                                 programa,
                                 materia_legal,
                                 secuencia,
                                 parte_periodo,
                                 materia_banner,
                                 fecha_inicio,
                                 regla,
                                 jornada,
                                 sp,
                                 qa,
                                 bim,
                                 type_code,
                                 ptrm_pi,
                                 tipo_inicio,
                                 etiqueta
                    )X
                    PIVOT(max(conteo)
                          for etiqueta
                          in   ('MPOL'AS MBA_EUROPEO_EJECUTIVO,
                               'HOOT'AS CERTIFICACION_HOOTSUITE,
                               'TABL'AS CERTIFICACION_TABLEAU,
                               'SENI'AS SESIONES_SENIOR,
                               'COLL'AS EXPERIENCIA_COLLEGE,
                               'CLOU'AS CERTIFICACION_GOOGLE_CLOUD,
                               'COUR'AS CERTIFICACION_COURSERA,
                               'UNIC'AS CERTIFICACION_UNICEF,
                               'MICR'AS CERTIFICACION_MICROSOFT,
                               'GADS'AS CERTIFICACION_GOOGLE_ADS,
                               'MONU'AS CERTIFICACION_ONU,
                               'FCBK'AS CERTIFICACION_FACEBOOK,
                               'AMZN'AS CERTIFICACION_AMAZON,
                               'MUBA'AS CERTIFICACION_UBA,
                               'EJEC'AS SESIONES_EJECUTIVAS,
                               'CIFA'AS CERTIFICACION_CIFAL,
                               'IEBS'AS CERTIFICACION_IEBS,
                               'CESA'AS CURSO_CESA,
                               'LEGA'AS LEGALTECH,
                               'CTNU'AS SEMINARIO_TIENDA_NUBE,
                               'CAMB'AS CAMBRIDGE,
                               'DUOL'AS DUOLINGO ))
                  order by matricula,secuencia
                   )
                   loop
                              L_ROW.MATRICULA      :=C.MATRICULA      ;
                              L_ROW.PERIODO        :=C.PERIODO        ;
                              L_ROW.PROGRAMA       :=C.PROGRAMA       ;
                              L_ROW.MATERIA_LEGAL  :=C.MATERIA_LEGAL  ;
                              L_ROW.SECUENCIA      :=C.SECUENCIA      ;
                              L_ROW.PARTE_PERIODO  :=C.PARTE_PERIODO  ;
                              L_ROW.MATERIA_BANNER :=C.MATERIA_BANNER ;
                              L_ROW.FECHA_INICIO   :=C.FECHA_INICIO   ;
                              L_ROW.REGLA          :=C.REGLA          ;
                              L_ROW.JORNADA        :=C.JORNADA        ;
                              L_ROW.SP             :=C.SP             ;
                              L_ROW.QA             :=C.QA             ;
                              L_ROW.BIM            :=C.BIM            ;
                              L_ROW.TYPE_CODE      :=C.TYPE_CODE      ;
                              L_ROW.PTRM_PI        :=C.PTRM_PI        ;
                              L_ROW.TIPO_INICIO    :=C.TIPO_INICIO    ;
                              L_ROW.MBA_EUROPEO_EJECUTIVO      := C.MBA_EUROPEO_EJECUTIVO           ;
                              L_ROW.CERTIFICACION_HOOTSUITE    := C.CERTIFICACION_HOOTSUITE           ;
                              L_ROW.CERTIFICACION_TABLEAU      := C.CERTIFICACION_TABLEAU           ;
                              L_ROW.SESIONES_SENIOR            := C.SESIONES_SENIOR           ;
                              L_ROW.EXPERIENCIA_COLLEGE        := C.EXPERIENCIA_COLLEGE           ;
                              L_ROW.CERTIFICACION_GOOGLE_CLOUD := C.CERTIFICACION_GOOGLE_CLOUD           ;
                              L_ROW.CERTIFICACION_COURSERA     := C.CERTIFICACION_COURSERA           ;
                              L_ROW.CERTIFICACION_UNICEF       := C.CERTIFICACION_UNICEF           ;
                              L_ROW.CERTIFICACION_MICROSOFT    := C.CERTIFICACION_MICROSOFT           ;
                              L_ROW.CERTIFICACION_GOOGLE_ADS   := C.CERTIFICACION_GOOGLE_ADS           ;
                              L_ROW.CERTIFICACION_ONU          := C.CERTIFICACION_ONU           ;
                              L_ROW.CERTIFICACION_FACEBOOK     := C.CERTIFICACION_FACEBOOK           ;
                              L_ROW.CERTIFICACION_AMAZON       := C.CERTIFICACION_AMAZON           ;
                              L_ROW.CERTIFICACION_UBA          := C.CERTIFICACION_UBA           ;
                              L_ROW.SESIONES_EJECUTIVAS        := C.SESIONES_EJECUTIVAS           ;
                              L_ROW.CERTIFICACION_CIFAL        := C.CERTIFICACION_CIFAL           ;
                              L_ROW.CERTIFICACION_IEBS         := C.CERTIFICACION_IEBS           ;
                              L_ROW.CURSO_CESA                 := C.CURSO_CESA           ;
                              L_ROW.LEGALTECH                  := C.LEGALTECH;
                              L_ROW.SEMINARIO_TIENDA_NUBE      :=C.SEMINARIO_TIENDA_NUBE;
                              L_ROW.CAMBRIDGE                  :=C.CAMBRIDGE;
                              L_ROW.DUOLINGO                   :=C.DUOLINGO;
                              PIPE ROW (l_row);
                    end loop;


END;
-----
---
FUNCTION F_ALIANZA_ALUMNO  (p_regla varchar2) return t_tab_aliALU PIPELINED
  is
    l_row  t_alianzaALU;
BEGIN
--Cambios para reporte Alumnos_Alianzas 09/02/2023
--Se eliminó PIVOT
--Catalina Almeida Citalán
  for c in (
                  select *
                    from
                    (
                        SELECT DISTINCT (matricula),
                               max(DISTINCT etiqueta)conteo,
                               periodo,
                               programa,
                               parte_periodo,
                               fecha_inicio,
                               regla,
                               jornada,
                               sp,
                               qa,
                               bim,
                               type_code,
                               ptrm_pi,
                               tipo_inicio,
                               etiqueta
                        FROM
                        (
                            SELECT sztprono_id matricula,
                                   sztprono_term_code periodo,
                                   sztprono_program programa,
                                   sztprono_ptrm_code parte_periodo,
                                   sztprono_fecha_inicio fecha_inicio,
                                   sztprono_no_regla regla,
                                   sztprono_jornada jornada,
                                   sztprono_study_path sp,
                                   sztprono_cuatri qa,
                                   sztprono_ptrm_code_nw bim,
                                   sztprono_estatus type_code,
                                   NVL((
                                    SELECT distinct min(SFRSTCR_PTRM_CODE) ptrm_pi
                                    FROM SFRSTCR a
                                    WHERE 1 = 1
                                    AND a.sfrstcr_pidm = sztprono_pidm
                                    AND a.sfrstcr_stsp_key_sequence =sztprono_study_path
                                    AND SUBSTR(A.sfrstcr_term_code,5,1)NOT IN(8,9)
                                    AND a.sfrstcr_rsts_code ='RE'
                                    AND sfrstcr_term_code =(select min(b.sfrstcr_term_code)
                                                            from sfrstcr b
                                                            where 1 = 1
                                                            and a.sfrstcr_pidm = b.sfrstcr_pidm
                                                            and a.sfrstcr_stsp_key_sequence =b.sfrstcr_stsp_key_sequence
                                                            and a.sfrstcr_rsts_code = b.sfrstcr_rsts_code
                                                            )
--                                     AND a.sfrstcr_ptrm_code = (SELECT min (d1.sfrstcr_ptrm_code)
--                                                                FROM sfrstcr D1
--                                                                WHERE 1=1
--                                                                AND a.sfrstcr_pidm = d1.sfrstcr_pidm
--                                                                AND a.sfrstcr_term_code = d1.sfrstcr_term_code
--                                                                AND a.sfrstcr_rsts_code = d1.sfrstcr_rsts_code
--                                                                )
                                                         ),SZTPRONO_PTRM_CODE)ptrm_pi,
                                 (SELECT ZSTPARA_PARAM_VALOR  FROM (
                                                   SELECT distinct NVL(min(SFRSTCR_PTRM_CODE),SZTPRONO_PTRM_CODE) ptrm_pi
                                                        FROM SFRSTCR a
                                                        WHERE 1 = 1
                                                        AND a.sfrstcr_pidm = sztprono_pidm
                            --                            sztprono_pidm
                                                        AND a.sfrstcr_stsp_key_sequence =sztprono_study_path
                            --                            sztprono_study_path
                                                        AND SUBSTR(A.sfrstcr_term_code,5,1)NOT IN(8,9)
                                                        AND a.sfrstcr_rsts_code ='RE'
                                                        AND sfrstcr_term_code =(select min(b.sfrstcr_term_code)
                                                                                from sfrstcr b
                                                                                where 1 = 1
                                                                                and a.sfrstcr_pidm = b.sfrstcr_pidm
                                                                                and a.sfrstcr_stsp_key_sequence =b.sfrstcr_stsp_key_sequence
                                                                                and a.sfrstcr_rsts_code = b.sfrstcr_rsts_code
                                                                                )
--                                                         AND a.sfrstcr_ptrm_code = (SELECT min (d1.sfrstcr_ptrm_code)
--                                                                                    FROM sfrstcr D1
--                                                                                    WHERE 1=1
--                                                                                    AND a.sfrstcr_pidm = d1.sfrstcr_pidm
--                                                                                    AND a.sfrstcr_term_code = d1.sfrstcr_term_code
--                                                                                    AND a.sfrstcr_rsts_code = d1.sfrstcr_rsts_code
--                                                                                    )
                                                                                    ),ZSTPARA
                                 WHERE 1=1
                                 AND ptrm_pi= ZSTPARA_PARAM_ID
                                 AND ZSTPARA_MAPA_ID='PARTES_ANT_NOR')TIPO_INICIO,
                            GORADID_ADID_CODE etiqueta
                            from sztprono
                            left join goradid on sztprono_pidm = GORADID_PIDM
                                        and GORADID_ADID_CODE in (select distinct  SZTALIA_CODE
                                                                  from SZTALIA
                                                                  where 1 = 1
                                                                  and sztalia_active ='S')
                            where 1 = 1
                            and sztprono_no_regla IN (p_regla)
                    --        and sztprono_id ='010385783'
                            order by sztprono_id,
                                     sztprono_secuencia
                        )
                        group by matricula,
                                 periodo,
                                 programa,
                                 parte_periodo,
                                 fecha_inicio,
                                 regla,
                                 jornada,
                                 sp,
                                 qa,
                                 bim,
                                 type_code,
                                 ptrm_pi,
                                 tipo_inicio,
                                 etiqueta
                    )X
                  /*  PIVOT(max(conteo)
                          for etiqueta
                          in  ('MPOL'AS MBA_EUROPEO_EJECUTIVO,
                               'HOOT'AS CERTIFICACION_HOOTSUITE,
                               'TABL'AS CERTIFICACION_TABLEAU,
                               'SENI'AS SESIONES_SENIOR,
                               'COLL'AS EXPERIENCIA_COLLEGE,
                               'CLOU'AS CERTIFICACION_GOOGLE_CLOUD,
                               'COUR'AS CERTIFICACION_COURSERA,
                               'UNIC'AS CERTIFICACION_UNICEF,
                               'MICR'AS CERTIFICACION_MICROSOFT,
                               'GADS'AS CERTIFICACION_GOOGLE_ADS,
                               'MONU'AS CERTIFICACION_ONU,
                               'FCBK'AS CERTIFICACION_FACEBOOK,
                               'AMZN'AS CERTIFICACION_AMAZON,
                               'MUBA'AS CERTIFICACION_UBA,
                               'EJEC'AS SESIONES_EJECUTIVAS,
                               'CIFA'AS CERTIFICACION_CIFAL,
                               'IEBS'AS CERTIFICACION_IEBS,
                               'CESA'AS CURSO_CESA,
                               'LEGA'AS LEGALTECH,
                               'CTNU'AS SEMINARIO_TIENDA_NUBE,
                               'CAMB'AS CAMBRIDGE,
                               'DUOL'AS DUOLINGO )   )*/
order by matricula
                   )
                   loop
                              L_ROW.MATRICULA      :=C.MATRICULA      ;
                              L_ROW.PERIODO        :=C.PERIODO        ;
                              L_ROW.PROGRAMA       :=C.PROGRAMA       ;
                              L_ROW.PARTE_PERIODO  :=C.PARTE_PERIODO  ;
                              L_ROW.FECHA_INICIO   :=C.FECHA_INICIO   ;
                              L_ROW.REGLA          :=C.REGLA          ;
                              L_ROW.JORNADA        :=C.JORNADA        ;
                              L_ROW.SP             :=C.SP             ;
                              L_ROW.QA             :=C.QA             ;
                              L_ROW.BIM            :=C.BIM            ;
                              L_ROW.TYPE_CODE      :=C.TYPE_CODE      ;
                              L_ROW.PTRM_PI        :=C.PTRM_PI        ;
                              L_ROW.TIPO_INICIO    :=C.TIPO_INICIO    ;
                              L_ROW.CONTEO         :=C.CONTEO    ;
                            /* L_ROW.MBA_EUROPEO_EJECUTIVO      := C.MBA_EUROPEO_EJECUTIVO           ;
                              L_ROW.CERTIFICACION_HOOTSUITE    := C.CERTIFICACION_HOOTSUITE           ;
                              L_ROW.CERTIFICACION_TABLEAU      := C.CERTIFICACION_TABLEAU           ;
                              L_ROW.SESIONES_SENIOR            := C.SESIONES_SENIOR           ;
                              L_ROW.EXPERIENCIA_COLLEGE        := C.EXPERIENCIA_COLLEGE           ;
                              L_ROW.CERTIFICACION_GOOGLE_CLOUD := C.CERTIFICACION_GOOGLE_CLOUD           ;
                              L_ROW.CERTIFICACION_COURSERA     := C.CERTIFICACION_COURSERA           ;
                              L_ROW.CERTIFICACION_UNICEF       := C.CERTIFICACION_UNICEF           ;
                              L_ROW.CERTIFICACION_MICROSOFT    := C.CERTIFICACION_MICROSOFT           ;
                              L_ROW.CERTIFICACION_GOOGLE_ADS   := C.CERTIFICACION_GOOGLE_ADS           ;
                              L_ROW.CERTIFICACION_ONU          := C.CERTIFICACION_ONU           ;
                              L_ROW.CERTIFICACION_FACEBOOK     := C.CERTIFICACION_FACEBOOK           ;
                              L_ROW.CERTIFICACION_AMAZON       := C.CERTIFICACION_AMAZON           ;
                              L_ROW.CERTIFICACION_UBA          := C.CERTIFICACION_UBA           ;
                              L_ROW.SESIONES_EJECUTIVAS        := C.SESIONES_EJECUTIVAS           ;
                              L_ROW.CERTIFICACION_CIFAL        := C.CERTIFICACION_CIFAL           ;
                              L_ROW.CERTIFICACION_IEBS         := C.CERTIFICACION_IEBS           ;
                              L_ROW.CURSO_CESA                 := C.CURSO_CESA           ;
                              L_ROW.LEGALTECH                  := C.LEGALTECH;
                              L_ROW.SEMINARIO_TIENDA_NUBE      :=C.SEMINARIO_TIENDA_NUBE;
                              L_ROW.CAMBRIDGE                  :=C.CAMBRIDGE;
                              L_ROW.DUOLINGO                   :=C.DUOLINGO;*/
                              PIPE ROW (l_row);
                    end loop;


END;
---
---
END;
/
