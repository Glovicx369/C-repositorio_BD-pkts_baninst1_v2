DROP PACKAGE BODY BANINST1.PKG_JORNADAS_ABCC;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_jornadas_abcc
is
-- CREADO POR JUAN JESÚS CORONA MIRANDA
--PARA BAJAS DESDE ABCC Y ALTAS
--17052019

    --v2 07052020
    --Juan Jesús Corona Miranda
    --Altas desde Abcc
    function f_materias_pendientes (p_regla number,
                                    p_pidm number,
                                    p_programa varchar2,
                                    p_nivel  varchar2)
    return varchar
    is

        l_retorna varchar2(100):='EXITO';
    begin

        delete MATERIA_FALTANTE_LIC;

        commit;

        BEGIN

            Insert into MATERIA_FALTANTE_LIC (PER,
                                              AREA,
                                              MATERIA,
                                              NOMBRE_MAT,
                                              CALIF,
                                              TIPO,
                                              PIDM,
                                              MATRICULA,
                                              SECUENCIA,
                                              MATERIA_PADRE,
                                              SMRARUL_SUBJ_CODE,
                                              SMRARUL_CRSE_NUMB_LOW,
                                              CAMPUS,
                                              NIVEL,
                                              REGLA,
                                              SP)

                      select *
                        from
                        (
                        WITH programa
                               AS (SELECT DISTINCT c.SORLCUR_PIDM pidm,
                                                   c.sorlcur_program programa,
                                                   c.SORLCUR_KEY_SEQNO sp,
                                                   c.SORLCUR_TERM_CODE_CTLG catalogo,
                                                   c.sorlcur_camp_code campus,
                                                   c.sorlcur_levl_code nivel
                                     FROM sorlcur c
                                    WHERE     1 = 1
                                             AND c.sorlcur_pidm =  p_pidm
                                          AND c.SORLCUR_LMOD_CODE = 'LEARNER'
                                          AND c.SORLCUR_ROLL_IND = 'Y'
                                          AND c.SORLCUR_CACT_CODE = 'ACTIVE'
                                          AND c.SORLCUR_SEQNO =
                                                 (SELECT MAX (c1x.SORLCUR_SEQNO)
                                                    FROM SORLCUR c1x
                                                   WHERE c.sorlcur_pidm = c1x.sorlcur_pidm
                                                         AND c.SORLCUR_LMOD_CODE =
                                                                c1x.SORLCUR_LMOD_CODE
                                                         AND c.SORLCUR_ROLL_IND =
                                                                c1x.SORLCUR_ROLL_IND
                                                         AND c.SORLCUR_CACT_CODE =
                                                                c1x.SORLCUR_CACT_CODE
                                                         AND c.SORLCUR_PROGRAM =
                                                                c1x.SORLCUR_PROGRAM)),
                            secuencia AS (
                             SELECT DISTINCT SMRPCMT_PROGRAM AS Programa,
                                                            SMRPCMT_TERM_CODE_EFF periodo,
                                                            REGEXP_SUBSTR (SMRPCMT_TEXT,
                                                                           '[^|"]+',
                                                                           1,
                                                                           1)
                                                               AS Id_Materia,
                                                            to_number(SMRPCMT_TEXT_SEQNO)
                                                               AS Id_Secuencia,
                                                            NVL (SZTMACO_MATPADRE,
                                                                 REGEXP_SUBSTR (SMRPCMT_TEXT,
                                                                                '[^|"]+',
                                                                                1,
                                                                                1))
                                                               ID_MATERIA_GPO
                                              FROM smrpcmt, sztmaco
                                             WHERE     1 = 1
                                                   AND SMRPCMT_TEXT IS NOT NULL
                                                   AND REGEXP_SUBSTR (SMRPCMT_TEXT,
                                                                      '[^|"]+',
                                                                      1,
                                                                      1) = SZTMACO_MATHIJO(+)
                                             AND SMRPCMT_PROGRAM = p_programa
                                             order by 4
                                       )
                         SELECT z.per per,
                                z.area area,
                                z.materia materia,
                                z.nombre_mat nombre_mat,
                                z.calif calif,
                                z.tipo tipo,
                                z.pidm pidm,
                                z.matricula matricula,
                                MIN (to_number(z.secuencia)) secuencia,
                                z.materia_padre materia_padre,
                                z.SMRARUL_SUBJ_CODE SMRARUL_SUBJ_CODE,
                                z.SMRARUL_CRSE_NUMB_LOW SMRARUL_CRSE_NUMB_LOW,
                                z.campus campus,
                                z.nivel nivel,
                                p_regla,
                                 z.sp
                           FROM (SELECT DISTINCT                     /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                        CASE
                                           WHEN smralib_area_desc LIKE 'Servicio%'
                                           THEN
                                              TO_NUMBER (SUBSTR (smralib_area, 9, 2)) + 1
                                           WHEN smralib_area_desc LIKE 'Taller%'
                                           THEN
                                              TO_NUMBER (SUBSTR (smralib_area, 9, 2)) + 1
                                           ELSE
                                              TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                                        END
                                           per,
                                        smrpaap_area area,
                                        smrarul_subj_code || smrarul_crse_numb_low materia,
                                        scrsyln_long_course_title nombre_mat,
                                        CASE
                                           WHEN k.calif IN ('NA', 'NP', 'AC') THEN '1'
                                           WHEN k.st_mat = 'EC' THEN '101'
                                           ELSE k.calif
                                        END
                                           calif,
                                        NVL (k.st_mat, 'PC') Tipo,
                                        spriden_pidm pidm,
                                        spriden_id matricula,
                                        to_number(e.id_secuencia) Secuencia,
                                        e.ID_MATERIA_GPO Materia_Padre,
                                        SMRARUL_SUBJ_CODE,
                                        SMRARUL_CRSE_NUMB_LOW,
                                        xx.campus campus,
                                        xx.nivel nivel,
                                        xx.sp
                                   FROM smrpaap s,
                                        smrarul,
                                        sgbstdn y,
                                        spriden,
                                        sztdtec,
                                        stvstst,
                                        smralib,
                                        smracaa,
                                        scrsyln,
                                        zstpara,
                                        programa xx,
                                        secuencia e,
                                        (
                                    SELECT  distinct /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                   a.shrtckn_subj_code subj,
                                                    a.shrtckn_crse_numb code,
                                                  b.shrtckg_grde_code_final  CALIF,
                                                    DECODE (c.shrgrde_passed_ind,  'Y', 'AP',  'N', 'NA')
                                                       ST_MAT,
                                                    b.shrtckg_final_grde_chg_date fecha,
                                                    d.smrprle_program programa,
                                                    a.shrtckn_pidm pidm
                                               FROM shrtckn a,
                                                    shrtckg b ,
                                                    shrgrde c ,
                                                    smrprle d
                                              WHERE     1 = 1
                                                    And SHRGRDE_LEVL_CODE = p_nivel
                                                    AND b.shrtckg_pidm = a.shrtckn_pidm
                                                    and b.shrtckg_pidm =  p_pidm
                                                   And d.smrprle_program = p_programa
                                                    And TO_NUMBER (decode (trim (b.shrtckg_grde_code_final)
                                                       , 'AC',1,'NA',1,'NP',1
                                                      ,'10',10,'10.0',10,'100',10
                                                      ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                      ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                      ,'6.0',6,'6',6,'6.1',6,'61',6,'6.2',6,'6.3',6,'63',6,'6.5',6,'65',6,'6.6',6,'6.7',6,'6.8',6,'6.9',6
                                                      ,'7.0',7,'7',7,'7.1',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'7.7',7,'77',7,'7.8',7,'7.9',7
                                                      ,'8.0',8,'8',8,'80',8,'8.1',8,'8.2',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                     ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9
                                                    )) =
                                                    (select max (TO_NUMBER (decode (trim(yy1.shrtckg_grde_code_final)
                                                      ,'AC',1,'NA',1,'NP',1
                                                    ,'10',10,'10.0',10,'100',10
                                                    ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                   ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                    ,'6.0',6,'6',6,'6.1',6,'61',6,'6.2',6,'6.3',6,'63',6,'6.5',6,'65',6,'6.6',6,'6.7',6,'6.8',6,'6.9',6
                                                    ,'7.0',7,'7',7,'7.1',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'7.7',7,'77',7,'7.8',7,'7.9',7
                                                    ,'8.0',8,'8',8,'80',8,'8.1',8,'8.2',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                   ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9
                                                    ))) calif
                                                               from shrtckg yy1, shrtckn xx1
                                                               Where 1= 1
                                                               And yy1.SHRTCKG_PIDM = b.SHRTCKG_PIDM
                                                               And yy1.SHRTCKG_PIDM = xx1.SHRTCKN_PIDM
                                                                And xx1.shrtckn_subj_code  =   a.shrtckn_subj_code
                                                                and xx1.shrtckn_crse_numb  = a.shrtckn_crse_numb
                                                                AND yy1.shrtckg_tckn_seq_no = xx1.shrtckn_seq_no
                                                                AND yy1.shrtckg_term_code = xx1.shrtckn_term_code
                                                               )
                                                    AND b.shrtckg_tckn_seq_no = a.shrtckn_seq_no
                                                    AND b.shrtckg_term_code = a.shrtckn_term_code
                                                    AND c.shrgrde_levl_code = d.smrprle_levl_code
                                                    AND c.shrgrde_code = b.shrtckg_grde_code_final
                                                    And a.SHRTCKN_SUBJ_CODE ||a.SHRTCKN_CRSE_NUMB  not in ('SESO1001')
                                                    and ( a.SHRTCKN_PIDM, a.SHRTCKN_SUBJ_CODE ||a.SHRTCKN_CRSE_NUMB) not in ( select sfrstcr_pidm, ssbsect_subj_code||ssbsect_crse_numb
                                                                                                                                                                                  from ssbsect, sfrstcr
                                                                                                                                                                                  Where   ssbsect_term_code = sfrstcr_term_code
                                                                                                                                                                                  AND ssbsect_crn = sfrstcr_crn
                                                                                                                                                                                  and SFRSTCR_RSTS_CODE ='RE'
                                                                                                                                                                                  and sfrstcr_pidm  = b.shrtckg_pidm
                                                                                                                                                                                --  And SFRSTCR_GRDE_CODE is null
                                                                                                                                                                                  )
                                         UNION
                                                            Select xx4.subj, xx4.code, to_char (xx4.CALIF) CALIF,
                                                                case
                                                                        when xx4.CALIF between 1 and 5 then 'NA'
                                                                        When xx4.CALIF between 6 and 10 then 'AP'
                                                                End ST_MAT,
                                                                sysdate fecha,
                                                                 xx4.programa programa,
                                                                      xx4.pidm pidm from (
                                                             Select  xx3.subj, xx3.code, max (to_number(xx3.macana)) CALIF,
                                                            null ST_MAT,
                                                             --xx3.ST_MAT ST_MAT ,
                                                             xx3.programa programa,
                                                                      xx3.pidm pidm from (
                                                                     SELECT                      /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                                           ssbsect_subj_code subj,
                                                                            ssbsect_crse_numb code,
                                                                            sfrstcr_grde_code CALIF,
                                                                            DECODE (shrgrde_passed_ind,  'Y', 'AP',  'N', 'NA')
                                                                               ST_MAT,
                                                                          --  TRUNC (sfrstcr_rsts_date) + 120 fecha,
                                                                            smrprle_program programa,
                                                                            sfrstcr_pidm pidm,
                                                                            TO_NUMBER (decode (trim (sfrstcr_grde_code)
                                                                       , 'AC',1,'NA',1,'NP',1
                                                                      ,'10',10,'10.0',10,'100',10
                                                                      ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                                      ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                                      ,'6.0',6,'6',6,'6.1',6,'61',6,'6.2',6,'6.3',6,'63',6,'6.5',6,'65',6,'6.6',6,'6.7',6,'6.8',6,'6.9',6
                                                                      ,'7.0',7,'7',7,'7.1',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'7.7',7,'77',7,'7.8',7,'7.9',7
                                                                      ,'8.0',8,'8',8,'80',8,'8.1',8,'8.2',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                                     ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9)) macana
                                                                       FROM sfrstcr,
                                                                            smrprle,
                                                                            ssbsect,
                                                                            spriden,
                                                                            shrgrde
                                                                      WHERE 1 = 1
                                                                      And smrprle_program = p_programa
                                                                      And  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in   ('SESO1001')
                                                                           -- AND sfrstcr_grde_code IS NOT NULL
                                                                            AND sfrstcr_pidm NOT IN
                                                                                   (SELECT shrtckn_pidm
                                                                                      FROM shrtckn
                                                                                     WHERE SHRTCKN_SUBJ_CODE || SHRTCKN_CRSE_NUMB=SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB
                                                                                     And (SHRTCKN_PIDM, SHRTCKN_TERM_CODE, SHRTCKN_SEQ_NO) in (select SHRTCKG_PIDM,SHRTCKG_TERM_CODE, SHRTCKG_TCKN_SEQ_NO
                                                                                                                                                                                            from shrtckg, shrgrde
                                                                                                                                                                                            Where SHRTCKG_GRDE_CODE_FINAL = SHRGRDE_CODE
                                                                                                                                                                                            ANd shrgrde_passed_ind = 'Y')
                                                                                     )
                                                                            AND spriden_pidm = sfrstcr_pidm
                                                                            And spriden_pidm =  p_pidm
                                                                            AND spriden_change_ind IS NULL
                                                                            AND ssbsect_term_code = sfrstcr_term_code
                                                                            AND ssbsect_crn = sfrstcr_crn
                                                                            AND shrgrde_levl_code = smrprle_levl_code
                                                                            AND shrgrde_code = sfrstcr_grde_code
                                                                            ) xx3
                                                                            group by xx3.subj, xx3.code
                                                                            --xx3.ST_MAT  ,
                                                                           , xx3.programa ,xx3.pidm
                                                                            order by 1,2,3
                                                                          ) xx4
                                                ) k
                                  WHERE     1 = 1
                                        AND spriden_pidm = xx.pidm
                                        And spriden_pidm =  p_pidm
                                       AND spriden_change_ind IS NULL
                                        AND k.st_mat = 'NA'
                                        AND smrpaap_program = xx.programa
                                        AND smrpaap_area NOT IN
                                               ('UTLLTI0101',
                                                'UTLMTI0101',
                                                'UTLLTE0101',
                                                'UTLLTI0101',
                                                'UTLLTS0101',
                                                'UOCATN0101',
                                                'UTLMTI0101',
                                                'UTSMTI0101',
                                                'UTLTSS0110')
                                        AND smrpaap_term_code_eff = xx.catalogo
                                        AND smrpaap_area = smrarul_area
                                        AND y.sgbstdn_pidm = spriden_pidm
                                        AND y.sgbstdn_program_1 = smrpaap_program
                                        AND smrpaap_program = xx.programa
                                        AND y.sgbstdn_term_code_eff IN
                                               (SELECT MAX (x.sgbstdn_term_code_eff)
                                                  FROM sgbstdn x
                                                 WHERE x.sgbstdn_pidm = y.sgbstdn_pidm
                                                       AND x.sgbstdn_program_1 =
                                                              y.sgbstdn_program_1)
                                        AND sztdtec_program = sgbstdn_program_1
                                        AND sztdtec_status = 'ACTIVO'
                                        AND SZTDTEC_TERM_CODE = xx.catalogo
                                        AND stvstst_code = sgbstdn_stst_code
                                        AND smralib_area = smrpaap_area
                                        AND smracaa_area = smrarul_area
                                        AND smracaa_rule = smrarul_key_rule
                                        AND ( (smrarul_area NOT IN
                                                  (SELECT smriecc_area FROM smriecc)
                                               AND smrarul_area NOT IN
                                                      (SELECT smriemj_area FROM smriemj))
                                             OR (smrarul_area IN
                                                    (SELECT smriemj_area
                                                       FROM smriemj
                                                      WHERE smriemj_majr_code =
                                                               (SELECT DISTINCT SORLFOS_MAJR_CODE
                                                                  FROM sorlcur cu, sorlfos ss
                                                                 WHERE cu.sorlcur_pidm =
                                                                          Ss.SORLfos_PIDM
                                                                       AND cu.SORLCUR_SEQNO =
                                                                              ss.SORLFOS_LCUR_SEQNO
                                                                       AND cu.sorlcur_pidm =
                                                                              xx.pidm
                                                                       AND SORLCUR_LMOD_CODE =
                                                                              'LEARNER'
                                                                       AND SORLFOS_LFST_CODE =
                                                                              'MAJOR'
                                                                       AND SORLCUR_CACT_CODE =
                                                                              SORLFOS_CACT_CODE
                                                                       AND sorlcur_program =
                                                                              xx.programa))
                                                 AND smrarul_area NOT IN
                                                        (SELECT smriecc_area FROM smriecc))
                                             OR (smrarul_area IN
                                                    (SELECT smriecc_area
                                                       FROM smriecc
                                                      WHERE smriecc_majr_code_conc IN
                                                               (SELECT DISTINCT SORLFOS_MAJR_CODE
                                                                  FROM sorlcur cu, sorlfos ss
                                                                 WHERE cu.sorlcur_pidm =
                                                                          Ss.SORLfos_PIDM
                                                                       AND cu.SORLCUR_SEQNO =
                                                                              ss.SORLFOS_LCUR_SEQNO
                                                                       AND cu.sorlcur_pidm =
                                                                              xx.pidm
                                                                       AND SORLCUR_LMOD_CODE =
                                                                              'LEARNER'
                                                                       AND SORLFOS_LFST_CODE =
                                                                              'CONCENTRATION'
                                                                       AND SORLCUR_CACT_CODE =
                                                                              SORLFOS_CACT_CODE
                                                                       AND sorlcur_program =
                                                                              xx.programa))))
                                        AND k.pidm = xx.pidm
                                        AND k.programa = xx.programa
                                        AND k.subj = smrarul_subj_code
                                        AND k.code = smrarul_crse_numb_low
                                        AND scrsyln_subj_code = smrarul_subj_code
                                        AND scrsyln_crse_numb = smrarul_crse_numb_low
                                        AND zstpara_mapa_id(+) = 'MAESTRIAS_BIM'
                                        AND zstpara_param_id(+) = sgbstdn_program_1
                                        AND zstpara_param_desc(+) = xx.catalogo
                                        AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW =    e.Id_Materia
                                        AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW    not in   ('SESO1001')
                                        AND xx.catalogo = e.periodo
                                        ) z
                       GROUP BY z.per,
                                z.area,
                                z.materia,
                                z.nombre_mat,
                                z.calif,
                                z.tipo,
                                z.pidm,
                                z.matricula,
                                z.materia_padre,
                                z.SMRARUL_SUBJ_CODE,
                                z.SMRARUL_CRSE_NUMB_LOW,
                                z.campus,
                                z.nivel,
                                z.sp
                       UNION
                         SELECT z.per per,
                                z.area area,
                                z.materia materia,
                                z.nombre_mat nombre_mat,
                                z.calif calif,
                                z.tipo tipo,
                                z.pidm pidm,
                                z.matricula matricula,
                                MIN (to_number(z.secuencia)) secuencia,
                                z.materia_padre materia_padre,
                                z.SMRARUL_SUBJ_CODE SMRARUL_SUBJ_CODE,
                                z.SMRARUL_CRSE_NUMB_LOW SMRARUL_CRSE_NUMB_LOW,
                                z.campus campus,
                                z.nivel nivel,
                                p_regla,
                                 z.sp
                           FROM (SELECT DISTINCT                     /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                        CASE
                                           WHEN smralib_area_desc LIKE 'Servicio%'
                                           THEN
                                              TO_NUMBER (SUBSTR (smralib_area, 9, 2)) + 1
                                           WHEN smralib_area_desc LIKE 'Taller%'
                                           THEN
                                              TO_NUMBER (SUBSTR (smralib_area, 9, 2)) + 1
                                           ELSE
                                              TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                                        END
                                           per,
                                        smrpaap_area area,
                                        smrarul_subj_code || smrarul_crse_numb_low materia,
                                        scrsyln_long_course_title nombre_mat,
                                        NULL Calif,
                                        'PC' Tipo,
                                        spriden_pidm pidm,
                                        spriden_id matricula,
                                        to_number(e.id_secuencia) Secuencia,
                                        e.ID_MATERIA_GPO Materia_Padre,
                                        SMRARUL_SUBJ_CODE,
                                        SMRARUL_CRSE_NUMB_LOW,
                                        xx.campus campus,
                                        xx.nivel nivel,
                                        xx.sp
                                   FROM spriden,
                                        smrpaap,
                                        sgbstdn y,
                                        SZTDTEC,
                                        smrarul,
                                        smracaa,
                                        smralib,
                                        stvstst,
                                        scrsyln,
                                        zstpara,
                                        programa xx,
                                        secuencia e
                                  WHERE     1= 1
                                        And spriden_pidm = xx.pidm
                                        And  spriden_pidm =  p_pidm
                                        AND spriden_change_ind IS NULL
                                        AND smrpaap_program = xx.programa
                                        AND smrpaap_term_code_eff = xx.catalogo
                                        AND smrpaap_area = smrarul_area
                                        AND y.sgbstdn_pidm = spriden_pidm
                                        AND sgbstdn_program_1 = smrpaap_program
                                        AND y.sgbstdn_term_code_eff IN
                                               (SELECT MAX (x.sgbstdn_term_code_eff)
                                                  FROM sgbstdn x
                                                 WHERE x.sgbstdn_pidm = y.sgbstdn_pidm
                                                       AND x.sgbstdn_program_1 =
                                                              y.sgbstdn_program_1)
                                        AND sztdtec_program = xx.programa
                                        AND sztdtec_status = 'ACTIVO'
                                        AND SZTDTEC_TERM_CODE = xx.catalogo
                                        AND stvstst_code = sgbstdn_stst_code
                                        AND smralib_area = smrpaap_area
                                        AND smracaa_area = smrarul_area
                                        AND smracaa_rule = smrarul_key_rule
                                        AND SMRARUL_TERM_CODE_EFF = xx.catalogo
                                        AND smrpaap_area NOT IN
                                               ('UTLLTI0101',
                                                'UTLMTI0101',
                                                'UTLLTE0101',
                                                'UTLLTI0101',
                                                'UTLLTS0101',
                                                'UOCATN0101',
                                                'UTLMTI0101',
                                                'UTSMTI0101',
                                                'UTLTSS0110')
                                        AND ( (smrarul_area NOT IN
                                                  (SELECT smriecc_area FROM smriecc)
                                               AND smrarul_area NOT IN
                                                      (SELECT smriemj_area FROM smriemj))
                                             OR (smrarul_area IN
                                                    (SELECT smriemj_area
                                                       FROM smriemj
                                                      WHERE smriemj_majr_code =
                                                               (SELECT DISTINCT SORLFOS_MAJR_CODE
                                                                  FROM sorlcur cu, sorlfos ss
                                                                 WHERE cu.sorlcur_pidm =
                                                                          Ss.SORLfos_PIDM
                                                                       AND cu.SORLCUR_SEQNO =
                                                                              ss.SORLFOS_LCUR_SEQNO
                                                                       AND cu.sorlcur_pidm =
                                                                              xx.pidm
                                                                       AND SORLCUR_LMOD_CODE =
                                                                              'LEARNER'
                                                                       AND SORLFOS_LFST_CODE =
                                                                              'MAJOR' --CONCENTRATION
                                                                       AND SORLCUR_CACT_CODE =
                                                                              SORLFOS_CACT_CODE
                                                                       AND sorlcur_program =  xx.programa --prog
                                                                                          ))
                                                 AND smrarul_area NOT IN
                                                        (SELECT smriecc_area FROM smriecc))
                                             OR (smrarul_area IN
                                                    (SELECT smriecc_area
                                                       FROM smriecc
                                                      WHERE smriecc_majr_code_conc IN
                                                               (SELECT DISTINCT SORLFOS_MAJR_CODE
                                                                  FROM sorlcur cu, sorlfos ss
                                                                 WHERE cu.sorlcur_pidm =
                                                                          Ss.SORLfos_PIDM
                                                                       AND cu.SORLCUR_SEQNO =
                                                                              ss.SORLFOS_LCUR_SEQNO
                                                                       AND cu.sorlcur_pidm =
                                                                              xx.pidm       --pidm
                                                                       AND SORLCUR_LMOD_CODE =
                                                                              'LEARNER'
                                                                       AND SORLFOS_LFST_CODE =
                                                                              'CONCENTRATION'
                                                                       AND SORLCUR_CACT_CODE =
                                                                              SORLFOS_CACT_CODE
                                                                       AND sorlcur_program =
                                                                              xx.programa   --prog
                                                                                         ))))
                                        AND scrsyln_subj_code = smrarul_subj_code
                                        AND scrsyln_crse_numb = smrarul_crse_numb_low
                                        AND (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) NOT IN
                                               (SELECT SHRTCKN_SUBJ_CODE, SHRTCKN_CRSE_NUMB
                                                  FROM shrtckn
                                                 WHERE shrtckn_pidm = xx.pidm)
                                        AND (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) NOT IN
                                               (SELECT SHRTRCE_SUBJ_CODE, SHRTRCE_CRSE_NUMB
                                                  FROM SHRTRCE
                                                 WHERE SHRTRCE_pidm = xx.pidm)          --agregado
                                        AND (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) NOT IN
                                               (SELECT SHRTRTK_SUBJ_CODE_INST,
                                                       SHRTRTK_CRSE_NUMB_INST
                                                  FROM SHRTRTK
                                                 WHERE SHRTRTK_pidm = xx.pidm)          --agregado
                                        AND (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) NOT IN
                                               (SELECT ssbsect_subj_code subj,
                                                       ssbsect_crse_numb code
                                                  FROM sfrstcr,
                                                       smrprle,
                                                       ssbsect,
                                                       spriden --agregado para materias EC y aprobadas sin rolar
                                                 WHERE smrprle_program = xx.programa
                                                       AND sfrstcr_pidm = xx.pidm           --pidm
                                                       AND (sfrstcr_grde_code IS NULL
                                                            OR sfrstcr_grde_code IS NOT NULL)
                                                       AND sfrstcr_rsts_code = 'RE'
                                                       AND spriden_pidm = sfrstcr_pidm
                                                       AND spriden_change_ind IS NULL
                                                       AND ssbsect_term_code = sfrstcr_term_code
                                                       AND ssbsect_crn = sfrstcr_crn)
                                        AND zstpara_mapa_id(+) = 'MAESTRIAS_BIM'
                                        AND zstpara_param_id(+) = sgbstdn_program_1
                                        AND zstpara_param_desc(+) = xx.catalogo
                                        AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW =  e.Id_Materia
                                         AND SMRARUL_SUBJ_CODE || SMRARUL_CRSE_NUMB_LOW    not in   ('SESO1001')
                                        AND xx.catalogo = e.periodo) z
                       GROUP BY z.per,
                                z.area,
                                z.materia,
                                z.nombre_mat,
                                z.calif,
                                z.tipo,
                                z.pidm,
                                z.matricula,
                                z.materia_padre,
                                z.SMRARUL_SUBJ_CODE,
                                z.SMRARUL_CRSE_NUMB_LOW,
                                z.campus,
                                z.nivel,
                                z.sp
                                )
                                where 1 = 1
        --                        AND materia_padre ='L1C110'
                                order by to_number(9);
        EXCEPTION WHEN OTHERS THEN
            l_retorna:='Error al insertar a la mal llamada vista';
        END;

        commit;

        return(l_retorna);
    end;
--
--
       function  f_abcc_modaula (p_jorna_new NUMBER,
                                 p_jorna_old NUMBER,
                                 p_pidm      NUMBER,
                                 p_programa  VARCHAR2,
                                 p_nivel     VARCHAR2
                                ) RETURN varchar2
        is
        l_regla                NUMBER;
        l_maximo_periodo       VARCHAR2(1000);
        l_fecha_ssbsect        VARCHAR2(1000);
        l_matria               VARCHAR2(1000);
        tot_mat_act    NUMBER:=0;
        l_numero_materias      NUMBER;
        l_materias_activas     NUMBER;
        l_maximo_pperiodo      VARCHAR2(1000);
        l_ejecuta_vista        VARCHAR2(100);
        l_contar_regla         NUMBER;
        l_valor_falta          VARCHAR2(1000);
        l_contador             NUMBER:=0;
        l_crn                  VARCHAR2(1000);
        l_szstume_term_nrc     VARCHAR2(100);
        l_pwd                  VARCHAR2(100);
        l_moodle_id            VARCHAR2(100);
        l_secuencia_conf       NUMBER;
        l_secuen_max           NUMBER;
        l_contar_tume          NUMBER;
        l_inicio_clases        VARCHAR2(100);
        l_avance               NUMBER;
        l_sp                   NUMBER;
        l_rate                 VARCHAR2(1000);
        l_jornada              VARCHAR2(1000);
        l_tipo_ini             VARCHAR2(1000);
        l_qa                   VARCHAR2(1000);
        l_max                  NUMBER;
        l_matricula            VARCHAR2(1000);
        l_retorna              VARCHAR2(1000):='EXITO';
        l_cuenta_sfr           NUMBER;
        l_maxima_regla         NUMBER;
        l_maximo_periodo_v     varchar2(20);
        l_maximo_pperiodo_v    varchar2(20);
        l_materias_activas_aula     number;
        l_sztprono_jornada       varchar2(6);

    BEGIN

        begin

            select max(nvl(sztprono_no_regla,0))
            into l_maxima_regla
            from sztprono,
                 sztalgo
            where 1 = 1
            and sztprono_no_regla = sztalgo_no_regla
            and sztalgo_estatus_cerrado='S'
            and sztprono_pidm= p_pidm
            AND exists (SELECT NULL
                        from szstume
                        where 1 = 1
                        and szstume_pidm = sztprono_pidm
                        and szstume_subj_code = sztprono_materia_legal
                        and szstume_no_regla = sztprono_no_regla
                        );

        exception when others then
            null;
        end;

        dbms_output.put_line('maxima regla  '||l_maxima_regla);

        if l_maxima_regla <> 0 then

            select distinct (SZTPRONO_TERM_CODE),SZTPRONO_PTRM_CODE
            into l_maximo_periodo_v,l_maximo_pperiodo_v
            from sztprono,
                 sztalgo
            where 1 = 1
            and sztprono_no_regla = sztalgo_no_regla
            and sztalgo_estatus_cerrado='S'
            and sztprono_no_regla = l_maxima_regla
            and sztprono_pidm = p_pidm;

        end if;

       begin

            SELECT count(*)
            INTO l_cuenta_sfr
            FROM sfrstcr
            WHERE 1 = 1
            and sfrstcr_pidm = p_pidm
            AND sfrstcr_term_code =l_maximo_periodo_v
            AND sfrstcr_ptrm_code = l_maximo_pperiodo_v
            AND sfrstcr_rsts_code ='RE';

       exception when others then
            null;
       end;



            IF p_jorna_new > p_jorna_old THEN

                dbms_output.put_line('alta');
                l_numero_materias:= p_jorna_new-p_jorna_old;


                BEGIN

                    SELECT MAX(sfrstcr_term_code)
                    INTO l_maximo_periodo
                    FROM sfrstcr
                    WHERE 1 = 1
                    AND sfrstcr_pidm = p_pidm
                    AND sfrstcr_rsts_code ='RE'
                    and substr(sfrstcr_term_code,5,1)NOT IN ('8','9');

                EXCEPTION WHEN OTHERS THEN
                    NULL;
                END;

                FOR c IN (SELECT *
                          FROM ssbsect
                          WHERE 1 = 1
                          AND ssbsect_term_code = l_maximo_periodo_v
                          and ssbsect_ptrm_code = l_maximo_pperiodo_v
                          AND (SUBSTR(ssbsect_crn,2,20))  IN (SELECT TO_NUMBER(MAX(SUBSTR(SFRSTCR_crn,2,20)))
                                                              FROM sfrstcr
                                                              WHERE 1 = 1
                                                              AND sfrstcr_pidm = p_pidm
                                                              AND sfrstcr_term_code =l_maximo_periodo_v
                                                              and sfrstcr_ptrm_code = l_maximo_pperiodo_v
                                                              )
                          )
                          LOOP


                              dbms_output.put_line('entra a periodo '||l_maximo_periodo);

                              l_fecha_ssbsect:=c.ssbsect_ptrm_start_date;

                              BEGIN

                                  SELECT  ssbsect_ptrm_code
                                  INTO l_maximo_pperiodo
                                  FROM ssbsect
                                  WHERE 1 = 1
                                  AND ssbsect_crn = c.ssbsect_crn
                                  AND ssbsect_term_code = l_maximo_periodo
                                  AND ssbsect_ptrm_start_date =c.ssbsect_ptrm_start_date
                                  and substr(SSBSECT_PTRM_CODE,1,1)= substr(p_nivel,1,1);

                              EXCEPTION WHEN OTHERS THEN
                                  NULL;
                              END;


                              dbms_output.put_line('entra a periodo '||l_maximo_periodo||' ptrm '||l_maximo_pperiodo||' Fecha inicio '||c.ssbsect_ptrm_start_date);


                          END LOOP;

                          BEGIN

                            SELECT COUNT(*)
                            INTO l_materias_activas
                            FROM SFRSTCR
                            WHERE 1 = 1
                            AND sfrstcr_pidm = p_pidm
                            AND sfrstcr_term_code =l_maximo_periodo
                            AND sfrstcr_ptrm_code = l_maximo_pperiodo
                            AND sfrstcr_rsts_code ='RE';

                          EXCEPTION WHEN OTHERS THEN
                                NULL;
                          END;


--                          IF l_materias_activas <> p_jorna_old THEN
--
--                              l_retorna:=('El alumno no tiene la jornada de acuerdo a a su configuración en SGRASAT verifique en Servicios Escolares');
--
--                          END IF;

                          BEGIN

                              SELECT COUNT(*)
                              INTO l_contar_regla
                              FROM sztprono
                              WHERE 1 = 1
                              AND sztprono_pidm = p_pidm;

                          EXCEPTION WHEN OTHERS THEN
                            NULL;
                          END;

                          IF l_contar_regla > 0 THEN

                             dbms_output.put_line('entra a regla ');


                              BEGIN

                                SELECT MAX(sztprono_no_regla)
                                INTO l_regla
                                FROM sztprono,
                                     sztalgo
                                WHERE 1 = 1
                                and sztalgo_no_regla = sztprono_no_regla
                                and sztalgo_estatus_cerrado='S'
                                AND sztprono_pidm = p_pidm
                                AND sztprono_term_code = l_maximo_periodo
                                and sztprono_fecha_inicio=l_fecha_ssbsect;

                              EXCEPTION WHEN OTHERS THEN
                                NULL;
                              END;

                              dbms_output.put_line('entra a regla  '||l_regla);

                              dbms_output.put_line('activas  '||l_materias_activas||' Old '||p_jorna_old);

                              IF l_materias_activas = p_jorna_old THEN

                               -- dbms_output.put_line('activas  '||l_materias_activas||' Old '||p_jorna_old);

                                l_ejecuta_vista:=f_materias_pendientes(l_maxima_regla,p_pidm,p_programa,p_nivel);

                                FOR c IN (
                                              SELECT *
                                              FROM materia_faltante_lic
                                              WHERE 1 = 1
                                              AND regla = l_maxima_regla
                                              AND pidm = p_pidm
                                              AND MATERIA_PADRE not in (select distinct sztprono_materia_legal
                                                                        from sztprono
                                                                        where 1 = 1
                                                                        and sztprono_no_regla = l_maxima_regla
                                                                        and sztprono_pidm = p_pidm
                                                                        AND SZTPRONO_ESTATUS_ERROR ='N'
                                                                        )
                                              ORDER BY TO_NUMBER(secuencia)
                                          )LOOP

                                               dbms_output.put_line('Materia '||c.materia||' Valor vista '||l_ejecuta_vista);

                                               l_contador:=l_contador+1;

                                               SELECT COUNT(sztprono_pidm)+1
                                               INTO l_max
                                               FROM sztprono
                                               WHERE 1 = 1
                                               AND sztprono_no_regla = l_maxima_regla
                                               AND sztprono_pidm =p_pidm;

                                                BEGIN

                                                    SELECT sztprono_avance,
                                                           sztprono_study_path,
                                                           sztprono_rate,
                                                           sztprono_jornada,
                                                           sztprono_tipo_inicio,
                                                           sztprono_cuatri,
                                                           sztprono_id
                                                    INTO l_avance,
                                                         l_sp,
                                                         l_rate,
                                                         l_jornada,
                                                         l_tipo_ini,
                                                         l_qa,
                                                         l_matricula
                                                    FROM sztprono
                                                    WHERE 1 = 1
                                                    AND sztprono_no_regla = l_maxima_regla
                                                    AND sztprono_pidm =p_pidm
                                                    AND ROWNUM = 1;

                                                EXCEPTION WHEN OTHERS THEN
                                                    NULL;
                                                END;

                                                BEGIN

                                                    INSERT INTO sztprono VALUES (c.pidm,
                                                                                 l_matricula,
                                                                                 l_maximo_periodo,
                                                                                 p_programa,
                                                                                 c.MATERIA_PADRE,
                                                                                 l_max,
                                                                                 l_maximo_pperiodo,
                                                                                 c.smrarul_subj_code||c.smrarul_crse_numb_low,
                                                                                 NULL,
                                                                                 l_fecha_ssbsect,
                                                                                 l_maximo_pperiodo_v,
                                                                                 l_fecha_ssbsect,
                                                                                 l_avance,
                                                                                 l_maxima_regla,
                                                                                 USER,
                                                                                 l_sp,
                                                                                 l_rate,
                                                                                 l_jornada,
                                                                                 SYSDATE,
                                                                                 l_qa,
                                                                                 l_tipo_ini,
                                                                                 'XX',
                                                                                 'N',
                                                                                 'N',
                                                                                 'C',
                                                                                 'N',
                                                                                 NULL,
                                                                                 NULL
                                                                                 );

                                                EXCEPTION WHEN DUP_VAL_ON_INDEX THEN



                                                    l_crn:=get_crn_regla(c.pidm,null,c.materia,l_regla);

                                                    dbms_output.put_line('Materia cursor tume '||c.materia||' crn '||l_crn);

                                                      BEGIN

                                                          UPDATE SFRSTCR SET sfrstcr_rsts_code ='RE'
                                                          WHERE 1 = 1
                                                          AND sfrstcr_pidm =c.pidm
                                                          AND sfrstcr_term_code = l_maximo_periodo
                                                          AND sfrstcr_ptrm_code = l_maximo_pperiodo_v
--                                                          and sfrstcr_rsts_code ='DD'
                                                          AND sfrstcr_crn  =l_crn;

                                                      EXCEPTION WHEN OTHERS THEN
                                                          l_retorna:='No se puede actualizar en SFRSTCR ' ||SQLERRM;
                                                      END;

                                                      BEGIN

                                                           UPDATE sztprono SET SZTPRONO_ENVIO_HORARIOS ='S',
                                                                               SZTPRONO_DESCRIPCION_ERROR =SZTPRONO_DESCRIPCION_ERROR||' Actualiza desde ABCC',
                                                                               SZTPRONO_ESTATUS_ERROR ='N'

                                                           WHERE 1 = 1
                                                           AND sztprono_no_regla = l_maxima_regla
                                                           AND sztprono_pidm = c.pidm
                                                           AND sztprono_materia_legal = c.materia;

                                                      EXCEPTION WHEN OTHERS THEN
                                                           l_retorna:='Error al actualizar prono '||SQLERRM;
                                                      END;


                                                      commit;

                                                      FOR d IN (
                                                                SELECT *
                                                                FROM sztprono
                                                                JOIN goztpac ON   goztpac_pidm = sztprono_pidm
                                                                WHERE 1 = 1
                                                                AND sztprono_pidm = p_pidm
                                                                AND sztprono_no_regla = l_maxima_regla
                                                                AND sztprono_materia_legal = c.materia
--                                                                AND sztprono_envio_horarios ='S'
                                                   )
                                                   LOOP

                                                            dbms_output.put_line('Materia cursor tume '||d.sztprono_materia_legal);


                                                            FOR d1 IN (
                                                                         SELECT no_alumnos cupo,
                                                                                term_nrc,
                                                                                materia
                                                                         FROM
                                                                         (
                                                                             SELECT (SELECT SUM(DISTINCT(sztalgo_tope_alumnos+sztalgo_sobrecupo_alumnos)) tope
                                                                                     FROM sztalgo
                                                                                     WHERE 1 = 1
                                                                                     AND sztalgo_no_regla = l_maxima_regla ) - COUNT(szstume_id)  no_alumnos,
                                                                                     szstume_term_nrc term_nrc,
                                                                                     szstume_subj_code_comp materia
                                                                             FROM szstume
                                                                             WHERE 1 = 1
                                                                             AND szstume_subj_code_comp = d.sztprono_materia_legal
                                                                             AND szstume_no_regla = l_maxima_regla
                                                                             AND szstume_rsts_code ='RE'
                                                                             AND (szstume_subj_code_comp) in (SELECT
                                                                                                                 sztprono_materia_legal
                                                                                                              FROM sztprono
                                                                                                              WHERE 1 = 1
                                                                                                              AND sztprono_pidm = p_pidm
                                                                                                              AND sztprono_no_regla = l_maxima_regla
                                                                                                              AND sztprono_no_regla = l_maxima_regla
                                                                                                              AND sztprono_materia_legal = c.materia
                                                                                                              AND sztprono_envio_horarios ='S'
                                                                                                                      )
                                                                             GROUP BY szstume_term_nrc,
                                                                                      szstume_subj_code_comp
                                                                             ORDER BY 1
                                                                         )
                                                                         WHERE 1 = 1
                                                                         AND no_alumnos > 0 AND no_alumnos <(SELECT SUM(DISTINCT(sztalgo_tope_alumnos+sztalgo_sobrecupo_alumnos)) tope
                                                                                                             FROM sztalgo
                                                                                                             WHERE 1 = 1
                                                                                                             AND sztalgo_no_regla = l_maxima_regla )
                                                                         AND ROWNUM = 1
                                                                         AND materia =d.sztprono_materia_legal
                                                                         ORDER BY 2
                                                              ) LOOP

                                                                   BEGIN

                                                                       SELECT MAX(NVL(szstume_seq_no,0))+1
                                                                       INTO l_secuen_max
                                                                       FROM szstume
                                                                       WHERE 1 = 1
                                                                       AND szstume_no_regla = d.sztprono_no_regla
                                                                       AND szstume_pidm =d.sztprono_pidm;

                                                                   EXCEPTION WHEN OTHERS THEN
                                                                       dbms_output.put_line('No se encontro secuencia maxima '||sqlerrm);
                                                                   END;

                                                                    BEGIN

                                                                         INSERT INTO szstume VALUES(d1.term_nrc,
                                                                                                    d.sztprono_pidm,
                                                                                                    d.sztprono_id,
                                                                                                    SYSDATE,
                                                                                                    USER,
                                                                                                    0,
                                                                                                    'ALTA',
                                                                                                    d.goztpac_pin,
                                                                                                    NULL,
                                                                                                    l_secuen_max,
                                                                                                    'RE',
                                                                                                    null,
                                                                                                    d1.materia,
                                                                                                    NULL,-- C.nivel,
                                                                                                    NULL,
                                                                                                    NULL,--  c.ptrm,
                                                                                                    NULL,
                                                                                                    NULL,
                                                                                                    NULL,
                                                                                                    NULL,
                                                                                                    d1.materia,
                                                                                                    l_fecha_ssbsect,--  c.inicio_clases,
                                                                                                    l_maxima_regla,
                                                                                                    NULL,
                                                                                                    1,
                                                                                                    0,
                                                                                                    null
                                                                                                 );
                                                                    EXCEPTION WHEN OTHERS THEN
                                                                       l_retorna:='Error al insertar tume ';
                                                                    END;

                                                                    BEGIN

                                                                         UPDATE sztprono SET sztprono_envio_moodl ='S',
                                                                                             SZTPRONO_ENVIO_HORARIOS ='S',
                                                                                             SZTPRONO_DESCRIPCION_ERROR ='Actualizacion de Abcc'
                                                                         WHERE 1 = 1
                                                                         AND sztprono_no_regla = l_maxima_regla
                                                                         AND sztprono_pidm = d.sztprono_pidm
                                                                         AND sztprono_materia_legal = d1.materia;

                                                                    EXCEPTION WHEN OTHERS THEN
                                                                         l_retorna:='Error al actualizar prono '||SQLERRM;
                                                                    END;

                                                                    begin
                                                                        p_inscr_individual(l_fecha_ssbsect,l_regla,d1.materia,d.sztprono_pidm);

                                                                    exception when others then
                                                                        null;
                                                                    end;

                                                              END LOOP;

                                                              COMMIT;

                                                   END LOOP;
    --


                                                END;

                                                EXIT WHEN l_contador = l_numero_materias;


                                          END LOOP;



                                          COMMIT;

                                          FOR d IN (
                                                    SELECT *
                                                    FROM sztprono
                                                    JOIN goztpac ON   goztpac_pidm = sztprono_pidm
                                                    WHERE 1 = 1
                                                    AND sztprono_pidm = p_pidm
                                                    AND sztprono_no_regla = l_maxima_regla
                                                    AND sztprono_envio_moodl ='N'
                                                    AND sztprono_envio_horarios ='N'
                                                    AND sztprono_estatus_error ='N'
                                                   )
                                                   LOOP

                                                            dbms_output.put_line('Materia cursor tume '||d.sztprono_materia_legal);


                                                            FOR d1 IN (
                                                                         SELECT no_alumnos cupo,
                                                                                term_nrc,
                                                                                materia
                                                                         FROM
                                                                         (
                                                                             SELECT (SELECT SUM(DISTINCT(sztalgo_tope_alumnos+sztalgo_sobrecupo_alumnos)) tope
                                                                                     FROM sztalgo
                                                                                     WHERE 1 = 1
                                                                                     AND sztalgo_no_regla = l_maxima_regla ) - COUNT(szstume_id)  no_alumnos,
                                                                                     szstume_term_nrc term_nrc,
                                                                                     szstume_subj_code_comp materia
                                                                             FROM szstume
                                                                             WHERE 1 = 1
                                                                             AND szstume_subj_code_comp = d.sztprono_materia_legal
                                                                             AND szstume_no_regla = l_maxima_regla
                                                                             AND szstume_rsts_code ='RE'
                                                                             AND (szstume_subj_code_comp) in (SELECT
                                                                                                                 sztprono_materia_legal
                                                                                                              FROM sztprono
                                                                                                              WHERE 1 = 1
                                                                                                              AND sztprono_pidm = p_pidm
                                                                                                              AND sztprono_no_regla = l_maxima_regla
                                                                                                              AND SZTPRONO_ENVIO_MOODL ='N'
                                                                                                              AND SZTPRONO_ENVIO_HORARIOS ='N'
                                                                                                              AND SZTPRONO_ESTATUS_ERROR ='N'
                                                                                                                      )
                                                                             GROUP BY szstume_term_nrc,
                                                                                      szstume_subj_code_comp
                                                                             ORDER BY 1
                                                                         )
                                                                         WHERE 1 = 1
--                                                                         AND no_alumnos > 0 AND no_alumnos <(SELECT SUM(DISTINCT(sztalgo_tope_alumnos+sztalgo_sobrecupo_alumnos)) tope
--                                                                                                             FROM sztalgo
--                                                                                                             WHERE 1 = 1
--                                                                                                             AND sztalgo_no_regla = l_maxima_regla )
                                                                         AND ROWNUM = 1
                                                                         AND materia =d.sztprono_materia_legal
                                                                         ORDER BY 2
                                                              ) LOOP

                                                                   dbms_output.put_line('Entra a szstume');

                                                                     BEGIN

                                                                        SELECT MAX(NVL(szstume_seq_no,0))+1
                                                                        INTO l_secuen_max
                                                                        FROM szstume
                                                                        WHERE 1 = 1
                                                                        AND szstume_no_regla = d.sztprono_no_regla
                                                                        AND szstume_pidm =d.sztprono_pidm;

                                                                    EXCEPTION WHEN OTHERS THEN
                                                                        dbms_output.put_line('No se encontro secuencia maxima '||sqlerrm);
                                                                    END;


                                                                    BEGIN

                                                                         INSERT INTO szstume VALUES(d1.term_nrc,
                                                                                                    d.sztprono_pidm,
                                                                                                    d.sztprono_id,
                                                                                                    SYSDATE,
                                                                                                    USER,
                                                                                                    0,
                                                                                                    'ALTA',
                                                                                                    d.goztpac_pin,
                                                                                                    NULL,
                                                                                                    l_secuen_max,
                                                                                                    'RE',
                                                                                                    null,
                                                                                                    d1.materia,
                                                                                                    NULL,-- C.nivel,
                                                                                                    NULL,
                                                                                                    NULL,--  c.ptrm,
                                                                                                    NULL,
                                                                                                    NULL,
                                                                                                    NULL,
                                                                                                    NULL,
                                                                                                    d1.materia,
                                                                                                    l_fecha_ssbsect,--  c.inicio_clases,
                                                                                                    l_maxima_regla,
                                                                                                    NULL,
                                                                                                    1,
                                                                                                    0,
                                                                                                    null
                                                                                                 );


                                                                    EXCEPTION WHEN OTHERS THEN
                                                                       l_retorna:='Error al insertar tume '||SQLERRM;
                                                                    END;

                                                                    BEGIN

                                                                         UPDATE sztprono SET sztprono_envio_moodl ='S'
                                                                         WHERE 1 = 1
                                                                         AND sztprono_no_regla = l_maxima_regla
                                                                         AND sztprono_pidm = d.sztprono_pidm
                                                                         AND sztprono_materia_legal = d1.materia;

                                                                    EXCEPTION WHEN OTHERS THEN
                                                                         l_retorna:='Error al actualizar prono '||SQLERRM;
                                                                    END;

                                                                    begin
                                                                        p_inscr_individual(l_fecha_ssbsect,l_maxima_regla,d1.materia,d.sztprono_pidm);

                                                                    exception when others then
                                                                        null;
                                                                    end;

                                                              END LOOP;

                                                              COMMIT;

                                                   END LOOP;

                              END IF;

                          ELSE

                            l_retorna:=('El alumno no se encuentra en la sincronización');

                          END IF;


            END IF;

                    BEGIN
                          SELECT MAX (T.SGRSATT_ATTS_CODE)
                          INTO l_sztprono_jornada
                          FROM SGRSATT T
                          WHERE 1 = 1
                          and T.SGRSATT_PIDM =  p_pidm
                          AND T.SGRSATT_STSP_KEY_SEQUENCE =l_sp
                          AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
                          AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83)
                          AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                                             FROM SGRSATT TT
                                                             WHERE  TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                             AND  TT.SGRSATT_STSP_KEY_SEQUENCE= T.SGRSATT_STSP_KEY_SEQUENCE
                                                             AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83)
                                                             AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]'))
                          AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                                         FROM SGRSATT T1
                                                         WHERE T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                                         AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                                         AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                                         AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83)
                                                         AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]'));
                    EXCEPTION WHEN OTHERS THEN
                               NULL;
                    END;

            IF   p_jorna_new < p_jorna_old THEN

                dbms_output.put_line('entra baja l_sztprono_jornada:'||l_sztprono_jornada);

                --BAJA
                  l_numero_materias:=p_jorna_old-p_jorna_new; --NUMERO DE MATERIAS A BUSCAR

                  BEGIN

                    SELECT COUNT(*)
                    INTO l_contar_regla
                    FROM sztprono
                    WHERE 1 = 1
                    AND sztprono_pidm = p_pidm;

                    -- BUSCAMOS SI EXISTE EN ALGUNA REGLA

                  EXCEPTION WHEN OTHERS THEN
                    NULL;
                  END;

                  if l_contar_regla > 0 THEN

                      BEGIN

                        SELECT MAX(sztprono_no_regla)
                        INTO l_regla
                        FROM sztprono,
                             SZTALGO
                        where 1 = 1
                        and sztprono_no_regla = sztalgo_no_regla
                        and sztalgo_estatus_cerrado='S'
                        and sztprono_pidm= p_pidm
                        AND exists (SELECT NULL
                                    from szstume
                                    where 1 = 1
                                    and szstume_pidm = sztprono_pidm
                                    and szstume_subj_code = sztprono_materia_legal
                                    and szstume_no_regla = sztprono_no_regla
                                    );                        

                      EXCEPTION WHEN OTHERS THEN
                        NULL;
                      END;
                dbms_output.put_line('max regla:'||l_regla);

                      --BUSCAMOS LA MAXIMA REGLA

                      DELETE sztabba;

                      COMMIT;
                      
                      SELECT count(1) into tot_mat_act  --Frank@May24: Total materias activas en prono 
                        FROM sztprono
                        WHERE 1 = 1
                        AND sztprono_no_regla = l_regla
                        AND sztprono_pidm = p_pidm
                        AND sztprono_envio_moodl ='S'
                        AND sztprono_envio_horarios ='S';                                

                      FOR c in (SELECT *
                                FROM sztprono
                                WHERE 1 = 1
                                AND sztprono_no_regla = l_regla
                                AND sztprono_pidm = p_pidm
                                AND sztprono_envio_moodl ='S'
                                AND sztprono_envio_horarios ='S'
                                and tot_mat_act >=  l_numero_materias  --Frank@May24 
                                ORDER BY sztprono_secuencia DESC
                                )
                                loop
                dbms_output.put_line('procesando materia:'||c.sztprono_materia_legal);

                                    -- LLENAMOS TABLA DE PASO PARA BAJAR MATERIAS EN SFCTCR EN AULA

                                    l_crn:=get_crn_regla(p_pidm,null,c.sztprono_materia_legal,l_regla);

                                    l_contador:=l_contador+1;

                                    BEGIN

                                        INSERT INTO sztabba VALUES(
                                                                   p_pidm,
                                                                   p_programa,
                                                                   l_regla,
                                                                   c.sztprono_materia_legal,
                                                                   p_nivel,
                                                                   l_crn,
                                                                   c.sztprono_ptrm_code,
                                                                   c.sztprono_term_code
                                                                   );

                                    EXCEPTION WHEN OTHERS THEN
                                        l_retorna:='No se pude insertar en tabla de paso sztabba';
                                    END;

                                    COMMIT;

                                    EXIT WHEN l_contador = l_numero_materias;

                                END LOOP;

                        FOR C IN (SELECT crn,
                                         pidm,
                                         pperiodo,
                                         periodo,
                                         regla,
                                         materia_legal
                                  FROM sztabba
                                  WHERE 1 = 1
                                  AND regla = l_regla
                                  AND pidm = p_pidm
                                  )
                                  loop

                                    -- damos de baja en banner

                                      dbms_output.put_line('Baja Banner');

                                      BEGIN

                                          UPDATE SFRSTCR SET sfrstcr_rsts_code ='DD'
                                          WHERE 1 = 1
                                          AND sfrstcr_pidm =c.pidm
                                          AND sfrstcr_term_code = c.periodo
                                          AND sfrstcr_ptrm_code = c.pperiodo
                                          AND sfrstcr_crn  =c.crn;

                                      EXCEPTION WHEN OTHERS THEN
                                          l_retorna:='No se puede actualizar en SFRSTCR ' ||SQLERRM;
                                      END;

                                      -- damos de baja en aula

                                        SELECT COUNT(*)
                                        INTO l_contar_tume
                                        FROM szstume
                                        WHERE 1 = 1
                                        AND szstume_no_regla = c.regla
                                        AND szstume_pidm = c.pidm
                                        AND szstume_subj_code_comp = c.materia_legal
                                        AND szstume_rsts_code ='RE';

                                        dbms_output.put_line('Contar tume');

                                        IF l_contar_tume >0  THEN


                                            --recuperamos valors de sztgmpe

                                            BEGIN

                                                SELECT szstume_term_nrc,
                                                       szstume_pwd,
                                                       szstume_mdle_id,
                                                       szstume_secuencia,
                                                       szstume_id,
                                                       szstume_start_date
                                                INTO l_szstume_term_nrc,
                                                     l_pwd,
                                                     l_moodle_id,
                                                     l_secuencia_conf,
                                                     l_matricula,
                                                     l_inicio_clases
                                                FROM szstume
                                                WHERE 1 = 1
                                                AND szstume_no_regla = c.regla
                                                AND szstume_pidm = c.pidm
                                                AND szstume_subj_code_comp = c.materia_legal
                                                AND szstume_rsts_code ='RE'
                                                AND ROWNUM = 1;

                                            EXCEPTION WHEN OTHERS THEN
                                                l_retorna:='No se encontro configuracion para szstume '||sqlerrm;
                                            END;

                                            BEGIN

                                                SELECT MAX(NVL(szstume_seq_no,0))+1
                                                INTO l_secuen_max
                                                FROM szstume
                                                WHERE 1 = 1
                                                AND szstume_no_regla = c.regla
                                                AND szstume_subj_code_comp  = c.materia_legal
                                                AND szstume_term_nrc =l_szstume_term_nrc ;

                                            EXCEPTION WHEN OTHERS THEN
                                                l_retorna:='No se encontro secuencia maxima '||sqlerrm;
                                            END;

                                            begin

                                                select f_consulta_activos(c.regla,c.pidm)
                                                into l_materias_activas_aula
                                                from dual;

                                            exception when others then
                                                    l_retorna:='No se obtuvo el valor de funcion de busca materias activas';
                                            end;

                                            dbms_output.put_line('Materias Activas '||l_materias_activas_aula||' aqui ');


                                            if l_materias_activas_aula > 1 then

                                                BEGIN

                                                   INSERT INTO szstume VALUES(l_szstume_term_nrc,
                                                                               c.pidm,
                                                                               l_matricula,
                                                                               SYSDATE,
                                                                               USER,
                                                                               0,
                                                                               'BAJAS',
                                                                               l_pwd,
                                                                               NULL,
                                                                               l_secuen_max,
                                                                               'DD',
                                                                               NULL,
                                                                               c.materia_legal,
                                                                               NULL,-- c.nivel,
                                                                               NULL,
                                                                               NULL,--  c.ptrm,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               c.materia_legal,
                                                                               l_inicio_clases,--  c.inicio_clases,
                                                                               c.regla,
                                                                               l_secuencia_conf,
                                                                               1,
                                                                               0,
                                                                               null
                                                                               );
                                                EXCEPTION WHEN OTHERS THEN
                                                   l_retorna:='No se pudo insertar en szstume '||sqlerrm;
                                                END;

                                                BEGIN

                                                    UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                        sztprono_envio_horarios ='N',
                                                                        sztprono_descripcion_error =' Baja de alumno desde Abcc'
                                                    WHERE 1 = 1
                                                    AND sztprono_materia_legal = c.materia_legal
                                                    AND sztprono_pidm =c.pidm
                                                    AND sztprono_no_regla = c.regla
                                                    AND sztprono_fecha_inicio =l_inicio_clases
                                                    AND sztprono_envio_horarios ='S';



                                                EXCEPTION WHEN OTHERS THEN
                                                    NULL;
                                                END;

                                            else

                                                l_retorna:='Tiene que existir al menos una materia activa por favor valida en SFARHST para alinearla matricula';
                                               -- raise_application_error (-20002,'' );

                                            end if;

                                        END IF;

                                  END LOOP;


                  ELSE
                      l_retorna:='El alumno no se encuentra en la sincronización';

                  END IF;

                  BEGIN
                        UPDATE sztprono set SZTPRONO_JORNADA =l_sztprono_jornada
                        where 1 = 1
                        and  sztprono_no_regla = l_maxima_regla
                        and sztprono_pidm = p_pidm;
dbms_output.put_line('l_sztprono_jornada actualizando'||l_sztprono_jornada ||' total registros: '||SQL%ROWCOUNT );
                  EXCEPTION WHEN OTHERS THEN
                          NULL;
                  END;

            END IF;

            COMMIT;

--        end if;

        RETURN(l_retorna);

    END;
--
--
     PROCEDURE p_inscr_individual  (
                                 pn_fecha  VARCHAR2 ,
                                 p_regla   NUMBER,
                                 p_materia_legal  varchar2,
                                 p_pidm    number
                                 )
    IS
       crn                      varchar2(20);
       gpo                      NUMBER;
       mate                     VARCHAR2(20);
       ciclo                    VARCHAR2(6);
       subj                     VARCHAR2(4);
       crse                     VARCHAR2(5);
       sb                       VARCHAR2(4);
       cr                       VARCHAR2(5);
       schd                     VARCHAR2(3);
       title                    VARCHAR2(30);
       credit                   DECIMAL(7,3);
       credit_bill              DECIMAL(7,3);
       gmod                     VARCHAR2(1);
       f_inicio                 DATE;
       f_fin                    DATE;
       sem                      NUMBER;
       conta_ptrm               NUMBER;
       conta_blck               NUMBER;
       pidm                     NUMBER;
       pidm_doc                 NUMBER;
       pidm_doc2                NUMBER;
       ests                     VARCHAR2(2);
       levl                     VARCHAR2(2);
       camp                     VARCHAR2(3);
       rsts                     VARCHAR2(3);
       conta_origen             NUMBER:=0;
       conta_destino            NUMBER :=0;
       conta_origen_ssbsect     NUMBER:=0;
       conta_origen_ssrblck     NUMBER:=0;
       conta_origen_sobptrm     NUMBER:=0;
       sp                       INTEGER;
       ciclo_ext                VARCHAR2(6);
       mensaje                  VARCHAR2(200);
       parte                    VARCHAR2(3);
       pidm_prof                NUMBER;
       per                      VARCHAR2(6);
       grupo                    VARCHAR2(4);
       conta_sirasgn            NUMBER;
       fecha_ini                DATE;
       vl_existe                NUMBER :=0;

       vn_lugares               NUMBER:=0;
       vn_cupo_max              NUMBER:=0;
       vn_cupo_act              NUMBER:=0;
       vl_error                 VARCHAR2 (2500):= 'EXITO';

       parteper_cur             VARCHAR2(3);
       period_cur               VARCHAR2(10);
       vl_jornada               VARCHAR2(250):=NULL;
       vl_exite_prof            NUMBER :=0;
       l_contar                 NUMBER:=0;
       l_maximo_alumnos         NUMBER;
       l_numero_contador        number;
       l_valida_order           number;
       L_DESCRIPCION_ERROR      VARCHAR2(250):=NULL;
       l_valida                 number;
       l_cuneta_prono           number;
       l_term_code              VARCHAR2(10);
       l_ptrm                   VARCHAR2(10);
       vl_orden                 VARCHAR2(10);
       l_cambio_estatus         number;



            CURSOR c_no_proce IS
            SELECT *
            FROM szcarga carg
            WHERE  1=1
            and szcarga_no_regla = p_regla
            --and carg.SZCARGA_ID='010078157'
            AND NOT EXISTS (SELECT 1
                           FROM szcarga
                           JOIN spriden ON spriden_id=szcarga_id AND spriden_change_ind IS NULL
                           JOIN sgbstdn d ON  d.sgbstdn_pidm=spriden_pidm
                           AND  d.sgbstdn_term_code_eff = (SELECT MAX (b1.sgbstdn_term_code_eff)
                                                           FROM sgbstdn b1
                                                           WHERE 1 = 1
                                                           AND d.sgbstdn_pidm = b1.sgbstdn_pidm
                                                           AND d.sgbstdn_program_1 = b1.sgbstdn_program_1
                                                          )
                           JOIN sorlcur s ON sorlcur_pidm=spriden_pidm
                           AND s.sorlcur_program=szcarga_program
                           AND s.sorlcur_lmod_code='LEARNER'
                           AND s.sorlcur_seqno in (SELECT MAX(ss.sorlcur_seqno)
                                                   FROM sorlcur ss
                                                   WHERE 1 = 1
                                                   AND s.sorlcur_pidm=ss.sorlcur_pidm
                                                   AND s.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                   AND s.sorlcur_program=ss.sorlcur_program
                                                   )
                           JOIN smrpaap ON smrpaap_program=sorlcur_program
                           AND smrpaap_term_code_eff=sorlcur_term_code_ctlg
                           JOIN scrtext ON scrtext_text =szcarga_materia
                           JOIN smrarul ON smrarul_area=smrpaap_area
                           AND smrarul_term_code_eff=smrpaap_term_code_eff
                           LEFT OUTER JOIN sztdtec ON sztdtec_program=sorlcur_program
                           AND sztdtec_term_code=sorlcur_term_code_ctlg
                           WHERE  smrarul_subj_code=scrtext_subj_code
                           AND smrarul_crse_numb_low=scrtext_crse_numb
                           AND carg.szcarga_id=spriden_id
                           AND carg.szcarga_materia = szcarga_materia
                           AND carg.szcarga_program=szcarga_program
                           AND carg.szcarga_fecha_ini=szcarga_fecha_ini
                           AND szcarga_no_regla = p_regla
                           and sorlcur_pidm = p_pidm
                                          --      and szcarga_materia = 'M1ED116'
                            ) ;


   BEGIN
        PKG_ALGORITMO.P_ENA_DIS_TRG('D','SATURN.SZT_SSBSECT_POSTINSERT_ROW');
        PKG_ALGORITMO.P_ENA_DIS_TRG('D','SATURN.SZT_SIRASGN_POSTINSERT_ROW');
        PKG_ALGORITMO.P_ENA_DIS_TRG('D','SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');



        begin
           pkg_jornadas_abcc.P_INSERTA_CARGA(p_regla,pn_fecha);
        exception when others then
            raise_application_error (-20002,'ERROR al insertar en carga '||sqlerrm);
        end;

        BEGIN

              SELECT COUNT(*)
              INTO l_contar
              from SZCARGA
              WHERE 1 = 1
              AND SZCARGA_NO_REGLA =p_regla;

        EXCEPTION WHEN OTHERS THEN
          NULL;
        END;

        IF l_contar > 0 then

            fecha_ini:=TO_DATE(pn_fecha,'DD/MM/RRRR');

            begin

                update sztprono set SZTPRONO_ENVIO_HORARIOS ='N',
                                    SZTPRONO_ESTATUS_ERROR ='N'
                where 1 = 1
                and sztprono_no_regla = p_regla
                and SZTPRONO_FECHA_INICIO = pn_fecha
                and sztprono_materia_legal = p_materia_legal
                and sztprono_pidm = p_pidm;

            exception when others then
                null;
            end;

            commit;


             FOR c IN (
                       SELECT DISTINCT spriden_pidm pidm,
                                       szcarga_id iden  ,
                                       szcarga_program prog,
                                       sorlcur_camp_code campus,
                                       sorlcur_levl_code nivel,
                                       sorlcur_term_code_ctlg ctlg ,
                                       szcarga_materia  materia ,
                                       smrarul_subj_code subj,
                                       smrarul_crse_numb_low crse ,
                                       szcarga_term_code periodo ,
                                       szcarga_ptrm_code parte,
                                       DECODE(sztdtec_periodicidad,1,'BIMESTRAL',2,'CUATRIMESTRAL') periodicidad,
                                       nvl(szcarga_grupo,'01') grupo,
                                       --szcarga_grupo grupo,
                                       szcarga_calif calif,
                                       szcarga_id_prof prof,
                                       szcarga_fecha_ini fecha_inicio,
                                       sorlcur_key_seqno study,
                                       d.sgbstdn_stst_code,
                                       d.sgbstdn_styp_code
                       FROM szcarga a
                       JOIN spriden ON spriden_id=szcarga_id AND spriden_change_ind IS NULL
                       JOIN sgbstdn d ON  d.sgbstdn_pidm=spriden_pidm
                       AND  d.sgbstdn_term_code_eff = (SELECT MAX (b1.sgbstdn_term_code_eff)
                                                       FROM sgbstdn b1
                                                       WHERE 1 = 1
                                                       AND d.sgbstdn_pidm = b1.sgbstdn_pidm
                                                       AND d.sgbstdn_program_1 = b1.sgbstdn_program_1
                                                                              )
                       JOIN sorlcur s ON sorlcur_pidm=spriden_pidm
                       AND s.sorlcur_pidm = d.sgbstdn_pidm
                       AND s.sorlcur_program = d.sgbstdn_program_1
                       AND sorlcur_program=szcarga_program
                       AND sorlcur_lmod_code='LEARNER'
                       AND sorlcur_seqno IN (SELECT MAX(sorlcur_seqno)
                                             FROM sorlcur ss
                                             WHERE 1 = 1
                                             AND s.sorlcur_pidm=ss.sorlcur_pidm
                                             AND s.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                             AND s.sorlcur_program=ss.sorlcur_program
                                             )
                       LEFT OUTER JOIN sztdtec ON sztdtec_program=sorlcur_program AND sztdtec_term_code=sorlcur_term_code_ctlg
                       JOIN smrpaap ON smrpaap_program=sorlcur_program AND smrpaap_term_code_eff=sorlcur_term_code_ctlg
                       JOIN sztmaco ON SZTMACO_MATPADRE=szcarga_materia
                       JOIN smrarul ON smrarul_area=smrpaap_area  AND smrarul_term_code_eff=smrpaap_term_code_eff
                       WHERE  1 = 1
                       AND smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
                       AND szcarga_no_regla = p_regla
                       AND sorlcur_pidm = p_pidm
                       and SZCARGA_MATERIA = p_materia_legal
                       ORDER BY  iden, 10

            ) LOOP

                      --------------- Limpia Variables  --------------------
                                    --niv :=  null;
                        parte         := NULL;
                        crn           := NULL;
                        pidm_doc2     := NULL;
                        conta_sirasgn := NULL;
                        pidm_doc      := NULL;
                        f_inicio      := NULL;
                        f_fin         := NULL;
                        sem           := NULL;
                        schd          := NULL;
                        title         := NULL;
                        credit        := NULL;
                        credit_bill   :=NULL;
                        levl          := NULL;
                        camp          := NULL;
                        mate          := NULL;
                        parte         := NULL;
                        per           := NULL;
                       -- grupo         := NULL;
                        vl_existe     :=0;
                        vl_error      := 'EXITO';
                        vn_lugares    :=0;
                        vn_cupo_max   :=0;
                        vn_cupo_act   :=0;

                        parteper_cur  :=null;
                        period_cur    :=null;
                        vl_exite_prof :=0;

                       BEGIN

                           SELECT MAX (DISTINCT SFRSTCR_VPDI_CODE)
                           INTO VL_ORDEN
                           FROM SFRSTCR
                           WHERE SFRSTCR_PIDM = C.PIDM
                           AND SFRSTCR_TERM_CODE = C.PERIODO
                           AND SFRSTCR_PTRM_CODE = C.PARTE
                           AND SFRSTCR_RSTS_CODE = 'RE'
                           AND SFRSTCR_VPDI_CODE IS NOT NULL;

                       EXCEPTION
                       WHEN NO_DATA_FOUND THEN

                           BEGIN

                               SELECT TBRACCD_RECEIPT_NUMBER
                               INTO VL_ORDEN
                               FROM TBRACCD A
                               WHERE A.TBRACCD_PIDM = C.PIDM
                               AND A.TBRACCD_TERM_CODE = C.PERIODO
                               AND A.TBRACCD_PERIOD = C.PARTE
                               AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                           FROM TBBDETC
                                                           WHERE TBBDETC_DCAT_CODE = 'COL')
                               AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                               AND A.TBRACCD_TRAN_NUMBER = (SELECT MAX(TBRACCD_TRAN_NUMBER)
                                                            FROM TBRACCD A1
                                                            WHERE A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                                                            AND A1.TBRACCD_TERM_CODE = A.TBRACCD_TERM_CODE
                                                            AND A1.TBRACCD_PERIOD = A.TBRACCD_PERIOD
                                                            AND A1.TBRACCD_DETAIL_CODE = A.TBRACCD_DETAIL_CODE
                                                            AND A1.TBRACCD_DOCUMENT_NUMBER IS NULL)
                               ;

                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_ORDEN := NULL;
                           END;

                       END;


                        IF c.sgbstdn_stst_code IN  ('AS','PR','MA') then
                        ----------------- Se valida que el alumno no tenga la materia sembrada en el horario como Activa ---------------------------------------

                            DBMS_OUTPUT.PUT_LINE('Entra a cursor normal ');

                            BEGIN
                                    --existe y es aprobatoria
                                SELECT COUNT (1), sfrstcr_term_code, sfrstcr_ptrm_code
                                    into vl_existe, period_cur, parteper_cur
                                FROM ssbsect, sfrstcr, shrgrde
                                WHERE 1 = 1
                                AND sfrstcr_pidm=c.pidm
                                AND ssbsect_term_code = sfrstcr_term_code
                                AND sfrstcr_ptrm_code = ssbsect_ptrm_code
                                AND ssbsect_crn= sfrstcr_crn
                                AND ssbsect_subj_code =c.subj
                                AND ssbsect_crse_numb =c.crse
                                AND sfrstcr_rsts_code  = 'RE'
                                AND (sfrstcr_grde_code = shrgrde_code
                                                         OR sfrstcr_grde_code IS NULL)
                                And substr (sfrstcr_term_code,5,1) != '8'
                                AND shrgrde_passed_ind = 'Y'
                                AND shrgrde_levl_code  = c.nivel
                                GROUP BY sfrstcr_term_code, sfrstcr_ptrm_code;

                                DBMS_OUTPUT.PUT_LINE('Entrando  aqui '||vl_existe);

                            EXCEPTION
                             WHEN OTHERS THEN
                                 vl_existe:=0;
                                 DBMS_OUTPUT.PUT_LINE('Error '||sqlerrm);

                            END;

                            DBMS_OUTPUT.PUT_LINE('Entra a existe '||vl_existe);

                            IF vl_existe = 0 THEN

                                    dbms_output.put_line ('sin profesor '||vl_existe);

                                    BEGIN

                                            SELECT ct.ssbsect_crn ,
                                                        ct.ssbsect_seats_avail lugares,
                                                        ct.ssbsect_max_enrl cupo_max,
                                                        ct.ssbsect_ptrm_code,
                                                        ct.ssbsect_enrl cupo_act,
                                                        ct.ssbsect_ptrm_start_date,
                                                        ct.ssbsect_ptrm_end_date,
                                                        ct.ssbsect_ptrm_weeks,
                                                        ct.ssbsect_credit_hrs,
                                                        ct.ssbsect_bill_hrs,
                                                        ct.ssbsect_gmod_code
                                            INTO crn ,
                                                      vn_lugares,
                                                      vn_cupo_max,
                                                      parte,
                                                      vn_cupo_act,
                                                      f_inicio,
                                                      f_fin,
                                                      sem,
                                                      credit,
                                                      credit_bill,
                                                      gmod
                                              FROM ssbsect ct
                                             WHERE     1 = 1
                                                     AND   ct.ssbsect_term_code= c.periodo
                                                     AND   ct.ssbsect_subj_code= c.subj
                                                     AND   ct.ssbsect_crse_numb=c.crse
                                                     AND   ct.ssbsect_seq_numb = c.grupo
                                                     AND   ct.ssbsect_ptrm_code = c.parte
                                                     AND   trunc (ct.ssbsect_ptrm_start_date) = c.Fecha_Inicio
                                                   AND ct.ssbsect_seats_avail > 0
                                                   AND ct.ssbsect_seats_avail IN  (
                                                                                              SELECT MAX (a1.ssbsect_seats_avail)
                                                                                                 FROM ssbsect a1
                                                                                                WHERE     a1.ssbsect_term_code = ct.ssbsect_term_code
                                                                                                      AND a1.ssbsect_seq_numb = ct.ssbsect_seq_numb
                                                                                                      AND a1.ssbsect_subj_code = ct.ssbsect_subj_code
                                                                                                      AND a1.ssbsect_crse_numb = ct.ssbsect_crse_numb
                                                                                                      And trunc (a1.ssbsect_ptrm_start_date) = trunc(ct.ssbsect_ptrm_start_date)
                                                                                              );

                                              --  DBMS_OUTPUT.PUT_LINE('Entra 4');

                                    EXCEPTION WHEN OTHERS THEN
                                        crn:=null;
                                        vn_lugares  :=0;
                                        vn_cupo_max :=0;
                                        vn_cupo_act :=0;
                                        f_inicio    := NULL;
                                        f_fin       := NULL;
                                        sem         := NULL;
                                        credit      := NULL;
                                        credit_bill := NULL;
                                        gmod        := NULL;
                                    END;



                                IF crn IS NOT NULL THEN

                                  dbms_output.put_line ('CRN no es null '||crn);

                                    IF vn_cupo_act >0  THEN

                                        IF credit IS NULL THEN

                                            BEGIN

                                                SELECT ssrmeet_credit_hr_sess
                                                INTO credit
                                                FROM ssrmeet
                                                WHERE 1 = 1
                                                AND ssrmeet_term_code = c.periodo
                                                AND ssrmeet_crn = crn;

                                            EXCEPTION  WHEN OTHERS THEN
                                                credit :=NULL;
                                            END;

                                            IF credit IS NOT NULL THEN

                                                BEGIN

                                                    UPDATE ssbsect SET ssbsect_credit_hrs = credit
                                                    WHERE 1 = 1
                                                    AND ssbsect_term_code = c.periodo
                                                    AND ssbsect_crn = crn;

                                                EXCEPTION WHEN OTHERS THEN
                                                     NULL;
                                                END;

                                            END IF;

                                        END IF;

                                        IF credit_bill IS NULL THEN

                                            credit_bill := 1;

                                            IF credit IS NOT NULL THEN

                                                BEGIN

                                                    UPDATE ssbsect SET  ssbsect_bill_hrs = credit_bill
                                                    WHERE 1 = 1
                                                    AND ssbsect_term_code = c.periodo
                                                    AND ssbsect_crn = crn;

                                                EXCEPTION WHEN OTHERS THEN
                                                     NULL;
                                                END;

                                            END IF;

                                        END IF;

                                        IF gmod IS NULL THEN

                                            BEGIN

                                                SELECT scrgmod_gmod_code
                                                INTO gmod
                                                FROM scrgmod
                                                where 1 = 1
                                                AND scrgmod_subj_code=c.subj
                                                AND scrgmod_crse_numb=c.crse
                                                AND scrgmod_default_ind='D';

                                            EXCEPTION WHEN OTHERS THEN
                                                gmod:='1';
                                            END;

                                            IF gmod IS NOT NULL THEN

                                                BEGIN

                                                    UPDATE ssbsect SET ssbsect_gmod_code = gmod
                                                    WHERE 1 = 1
                                                    AND ssbsect_term_code = c.periodo
                                                    AND ssbsect_crn = crn;

                                                EXCEPTION WHEN OTHERS THEN
                                                     NULL;
                                                END;

                                            END IF;

                                        END IF;

                                        BEGIN

                                            SELECT spriden_pidm
                                            INTO pidm_prof
                                            FROM  spriden
                                            WHERE 1 = 1
                                            AND spriden_id=c.prof
                                            AND spriden_change_ind IS NULL;

                                        EXCEPTION WHEN OTHERS THEN
                                            pidm_prof:=NULL;
                                        END;

                                        conta_ptrm :=0;

                                        BEGIN

                                            SELECT COUNT (1)
                                            INTO conta_ptrm
                                            from sirasgn
                                            Where SIRASGN_TERM_CODE = c.periodo
                                            And SIRASGN_CRN = crn
                                            and  SIRASGN_PIDM = pidm_prof
                                            And SIRASGN_PRIMARY_IND = 'Y';

                                        EXCEPTION WHEN OTHERS THEN
                                            conta_ptrm :=0;
                                        END;

                                        IF pidm_prof IS NOT NULL AND conta_ptrm = 0 THEN

                                            BEGIN
                                                    INSERT INTO sirasgn values(c.periodo,
                                                                                crn, pidm_prof,
                                                                                '01',
                                                                                100,
                                                                                NULL,
                                                                                100,
                                                                                'Y',
                                                                                NULL,
                                                                                NULL,
                                                                                SYSDATE -5,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                'PRONOSTICO',
                                                                                USER,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL
                                                                                );
                                            EXCEPTION WHEN OTHERS THEN
                                                null;
                                            END;

                                        END IF;

                                        conta_ptrm :=0;

                                        BEGIN

                                            SELECT COUNT(*)
                                            INTO conta_ptrm
                                            FROM sfbetrm
                                            WHERE 1 = 1
                                            AND sfbetrm_term_code=c.periodo
                                            AND sfbetrm_pidm=c.pidm;

                                        EXCEPTION WHEN OTHERS THEN
                                              conta_ptrm := 0;
                                        END;


                                        IF conta_ptrm =0 THEN

                                            BEGIN
                                                    INSERT INTO sfbetrm VALUES(c.periodo,
                                                                               c.pidm,
                                                                               'EL',
                                                                               SYSDATE,
                                                                               99.99,
                                                                               'Y',
                                                                               NULL,
                                                                               SYSDATE,
                                                                               SYSDATE,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               USER,
                                                                               NULL,
                                                                               'PRONOSTICO',
                                                                               NULL,
                                                                               0,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               USER,
                                                                               NULL
                                                                               );
                                            EXCEPTION WHEN OTHERS THEN
                                                vl_error := ('Se presento un error al insertar en la tabla sfbetrm ' || SQLERRM);
                                            END;

                                        END IF;

                                        BEGIN


                                            BEGIN

                                                INSERT INTO sfrstcr VALUES(
                                                                            c.periodo,     --SFRSTCR_TERM_CODE
                                                                            c.pidm,     --SFRSTCR_PIDM
                                                                            crn,     --SFRSTCR_CRN
                                                                            1,     --SFRSTCR_CLASS_SORT_KEY
                                                                            c.grupo,    --SFRSTCR_REG_SEQ
                                                                            parte,    --SFRSTCR_PTRM_CODE
                                                                            'RE',     --SFRSTCR_RSTS_CODE
                                                                            SYSDATE -5,    --SFRSTCR_RSTS_DATE
                                                                            NULL,    --SFRSTCR_ERROR_FLAG
                                                                            NULL,    --SFRSTCR_MESSAGE
                                                                            credit_bill,    --SFRSTCR_BILL_HR
                                                                            3, --SFRSTCR_WAIV_HR
                                                                            credit,     --SFRSTCR_CREDIT_HR
                                                                            credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                                                            credit,     --SFRSTCR_CREDIT_HR_HOLD
                                                                            gmod,     --SFRSTCR_GMOD_CODE
                                                                            NULL,    --SFRSTCR_GRDE_CODE
                                                                            NULL,    --SFRSTCR_GRDE_CODE_MID
                                                                            NULL,    --SFRSTCR_GRDE_DATE
                                                                            'N',    --SFRSTCR_DUPL_OVER
                                                                            'N',    --SFRSTCR_LINK_OVER
                                                                            'N',    --SFRSTCR_CORQ_OVER
                                                                            'N',    --SFRSTCR_PREQ_OVER
                                                                            'N',     --SFRSTCR_TIME_OVER
                                                                            'N',     --SFRSTCR_CAPC_OVER
                                                                            'N',     --SFRSTCR_LEVL_OVER
                                                                            'N',     --SFRSTCR_COLL_OVER
                                                                            'N',     --SFRSTCR_MAJR_OVER
                                                                            'N',     --SFRSTCR_CLAS_OVER
                                                                            'N',     --SFRSTCR_APPR_OVER
                                                                            'N',     --SFRSTCR_APPR_RECEIVED_IND
                                                                            SYSDATE -5,      --SFRSTCR_ADD_DATE
                                                                            Sysdate-5,     --SFRSTCR_ACTIVITY_DATE
                                                                            c.nivel,     --SFRSTCR_LEVL_CODE
                                                                            c.campus,     --SFRSTCR_CAMP_CODE
                                                                            c.materia,     --SFRSTCR_RESERVED_KEY
                                                                            NULL,     --SFRSTCR_ATTEND_HR
                                                                            'Y',     --SFRSTCR_REPT_OVER
                                                                            'N' ,    --SFRSTCR_RPTH_OVER
                                                                            NULL,    --SFRSTCR_TEST_OVER
                                                                            'N',    --SFRSTCR_CAMP_OVER
                                                                            USER,    --SFRSTCR_USER
                                                                            'N',    --SFRSTCR_DEGC_OVER
                                                                            'N',    --SFRSTCR_PROG_OVER
                                                                            NULL,    --SFRSTCR_LAST_ATTEND
                                                                            NULL,    --SFRSTCR_GCMT_CODE
                                                                            'PRONOSTICO',    --SFRSTCR_DATA_ORIGIN
                                                                            SYSDATE,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                                            'N',  --SFRSTCR_DEPT_OVER
                                                                            'N',  --SFRSTCR_ATTS_OVER
                                                                            'N', --SFRSTCR_CHRT_OVER
                                                                            c.grupo , --SFRSTCR_RMSG_CDE
                                                                            NULL,  --SFRSTCR_WL_PRIORITY
                                                                            NULL,  --SFRSTCR_WL_PRIORITY_ORIG
                                                                            NULL,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                                            NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                                            'N', --SFRSTCR_MEXC_OVER
                                                                            c.study,--SFRSTCR_STSP_KEY_SEQUENCE
                                                                            NULL,--SFRSTCR_BRDH_SEQ_NUM
                                                                            '01',--SFRSTCR_BLCK_CODE
                                                                            NULL,--SFRSTCR_STRH_SEQNO
                                                                            NULL, --SFRSTCR_STRD_SEQNO
                                                                            NULL,  --SFRSTCR_SURROGATE_ID
                                                                            NULL, --SFRSTCR_VERSION
                                                                            USER,--SFRSTCR_USER_ID
                                                                            vl_orden --SFRSTCR_VPDI_CODE
                                                                          );

                                            EXCEPTION WHEN OTHERS THEN
                                                dbms_output.put_line('Error al insertar  SFRSTCR '||sqlerrm);
                                            END;


                                            BEGIN

                                                 UPDATE ssbsect
                                                        set ssbsect_enrl = ssbsect_enrl + 1
                                                  WHERE 1 = 1
                                                  AND ssbsect_term_code = c.periodo
                                                  AND ssbsect_crn  = crn;

                                            EXCEPTION WHEN OTHERS THEN
                                               vl_error := 'Se presento un error al actualizar el enrolamiento ' ||SQLERRM;
                                            END;

                                           BEGIN
                                                UPDATE SZTPRONO SET SZTPRONO_ESTATUS_ERROR='N'
                                                WHERE 1 = 1
                                                AND SZTPRONO_NO_REGLA = p_regla
                                                and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                AND SZTPRONO_PIDM = c.pidm
                                                and SZTPRONO_ENVIO_HORARIOS='N'
                                                 and sztprono_materia_legal = c.materia
                                                 AND SZTPRONO_PTRM_CODE =parte;


                                           EXCEPTION WHEN OTHERS THEN
                                              NULL;
                                            END;

                                            BEGIN

                                                UPDATE ssbsect SET ssbsect_seats_avail=ssbsect_seats_avail -1
                                                WHERE 1 = 1
                                                AND ssbsect_term_code = c.periodo
                                                AND ssbsect_crn  = crn;

                                            EXCEPTION WHEN OTHERS THEN
                                                vl_error := 'Se presento un error al actualizar la disponibilidad del grupo ' ||SQLERRM;
                                            END;

                                            BEGIN

                                                UPDATE ssbsect SET ssbsect_census_enrl=ssbsect_enrl
                                                WHERE 1 = 1
                                                AND ssbsect_term_code = c.periodo
                                                AND ssbsect_crn  = crn;

                                            EXCEPTION WHEN OTHERS THEN
                                                vl_error := 'Se presento un error al actualizar el Censo del grupo ' ||SQLERRM;
                                            END;


                                            IF C.SGBSTDN_STYP_CODE = 'F' THEN

                                                BEGIN

                                                    UPDATE sgbstdn a SET a.sgbstdn_styp_code ='N',
                                                                         a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                                         A.SGBSTDN_USER_ID =USER
                                                    WHERE 1 = 1
                                                    AND a.sgbstdn_pidm = c.pidm
                                                    AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                                   FROM sgbstdn a1
                                                                                   WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                                   AND a1.sgbstdn_program_1 = a.sgbstdn_program_1
                                                                                   )
                                                    AND a.sgbstdn_program_1 = c.prog;

                                                EXCEPTION WHEN OTHERS THEN
                                                    vl_error := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
                                                END;

                                            END IF;

                                            BEGIN

                                                SELECT COUNT(*)
                                                INTO l_cambio_estatus
                                                FROM sfrstcr
                                                WHERE 1 = 1
                                                AND SFRSTCR_TERM_CODE||SFRSTCR_PTRM_CODE = c.periodo||c.parte
                                                AND sfrstcr_pidm = c.pidm;

                                            EXCEPTION WHEN OTHERS THEN
                                                l_cambio_estatus:=0;
                                            END;


                                            IF l_cambio_estatus > 0 THEN

                                                IF C.SGBSTDN_STYP_CODE = 'N' THEN

                                                    BEGIN

                                                        UPDATE sgbstdn a SET a.sgbstdn_styp_code ='C',
                                                                             a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                                             A.SGBSTDN_USER_ID =USER
                                                        WHERE 1 = 1
                                                        AND a.sgbstdn_pidm = c.pidm
                                                        AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                                       FROM sgbstdn a1
                                                                                       WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                                       AND a1.sgbstdn_program_1 = a.sgbstdn_program_1
                                                                                       )
                                                        AND a.sgbstdn_program_1 = c.prog;

                                                    EXCEPTION WHEN OTHERS THEN
                                                        vl_error := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
                                                    END;

                                                 END IF;

                                            end if;

                                            IF c.fecha_inicio IS NOT NULL THEN

                                                BEGIN

                                                    UPDATE sorlcur SET sorlcur_start_date  = TRUNC (c.fecha_inicio),
                                                                       sorlcur_data_origin = 'PRONOSTICO',
                                                                       sorlcur_user_id = USER
                                                    WHERE 1 = 1
                                                    AND sorlcur_pidm = c.pidm
                                                    AND sorlcur_program = c.prog
                                                    AND sorlcur_lmod_code = 'LEARNER'
                                                    AND sorlcur_key_seqno = c.study;

                                                EXCEPTION WHEN OTHERS THEN
                                                       vl_error := 'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur ' ||SQLERRM;
                                                END;

                                            END IF;

                                            conta_ptrm:=0;

                                            BEGIN

                                                SELECT COUNT (*)
                                                INTO conta_ptrm
                                                FROM sfrareg
                                                WHERE 1 = 1
                                                AND sfrareg_pidm = c.pidm
                                                AND sfrareg_term_code = c.periodo
                                                AND sfrareg_crn = crn
                                                AND sfrareg_extension_number = 0
                                                AND sfrareg_rsts_code = 'RE';

                                            EXCEPTION WHEN OTHERS THEN
                                               conta_ptrm :=0;
                                            END;

                                            IF conta_ptrm = 0 THEN

                                                BEGIN
                                                        INSERT INTO sfrareg VALUES(c.pidm,
                                                                                   c.periodo,
                                                                                   crn ,
                                                                                   0,
                                                                                   'RE',
                                                                                   nvl(c.fecha_inicio,pn_fecha),
                                                                                   nvl(f_fin,sysdate),
                                                                                   'N',
                                                                                   'N',
                                                                                   SYSDATE,
                                                                                   USER,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   'PRONOSTICO',
                                                                                   SYSDATE,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL
                                                                                   );
                                                EXCEPTION WHEN OTHERS THEN
                                                     vl_error := 'Se presento un error al insertar el registro de la materia para el alumno ' ||sqlerrm;
                                                END;

                                            END IF;


                                            BEGIN

                                                SELECT COUNT(1)
                                                INTO vl_existe
                                                FROM SHRINST
                                                WHERE 1 = 1
                                                AND shrinst_term_code = c.periodo
                                                AND shrinst_crn = crn
                                                AND shrinst_pidm = c.pidm;

                                            EXCEPTION WHEN OTHERS THEN
                                                vl_existe :=0;
                                            END;

                                            IF vl_existe = 0 THEN

                                                Begin
                                                    Insert into SHRINST values (c.periodo,        --SHRINST_TERM_CODE
                                                                                crn,       --SHRINST_CRN
                                                                                c.pidm,       --SHRINST_PIDM
                                                                                sysdate,       --SHRINST_ACTIVITY_DATE
                                                                                'Y',       --SHRINST_PRIMARY_IND
                                                                                null,      --SHRINST_SURROGATE_ID
                                                                                null,      --SHRINST_VERSION
                                                                                user,       --SHRINST_USER_ID
                                                                                'PRONOSTICO',       --SHRINST_DATA_ORIGIN
                                                                                null
                                                                                );      --SHRINST_VPDI_CODE

                                                EXCEPTION WHEN OTHERS THEN
                                                     vl_error := 'Se presento un error al insertar al alumno en SHRINST ' ||sqlerrm;
                                                END;

                                            END IF;

                                           BEGIN

                                                UPDATE SZTPRONO SET SZTPRONO_ENVIO_HORARIOS='S'
                                                WHERE 1 = 1
                                                AND SZTPRONO_NO_REGLA = p_regla
                                                and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                and SZTPRONO_ENVIO_HORARIOS='N'
                                                AND SZTPRONO_PIDM = c.pidm
                                                and sztprono_materia_legal = c.materia
                                                AND SZTPRONO_PTRM_CODE =parte;

                                           EXCEPTION WHEN OTHERS THEN
                                              NULL;
                                           END;

                                        EXCEPTION WHEN OTHERS THEN
                                            vl_error := 'Se presento un error al insertar al alumno en el grupo ' ||SQLERRM;
                                        END;

                                    ELSE

                                        dbms_output.put_line('mensaje:'|| 'No hay cupo en el grupo creado');
                                        schd      :=NULL;
                                        title     :=NULL;
                                        credit    :=NULL;
                                        gmod      :=NULL;
                                        f_inicio  :=NULL;
                                        f_fin     :=NULL;
                                        sem       :=NULL;
                                        credit_bill := NULL;

                                        BEGIN

                                            SELECT scrschd_schd_code,
                                                   scbcrse_title,
                                                   scbcrse_credit_hr_low,
                                                   scbcrse_bill_hr_low
                                            INTO schd,
                                                 title,
                                                 credit,
                                                 credit_bill
                                            FROM scbcrse,
                                                 scrschd
                                            WHERE 1 = 1
                                            AND scbcrse_subj_code=c.subj
                                            AND scbcrse_crse_numb=c.crse
                                            AND scbcrse_eff_term='000000'
                                            AND scrschd_subj_code=scbcrse_subj_code
                                            AND scrschd_crse_numb=scbcrse_crse_numb
                                            AND scrschd_eff_term=scbcrse_eff_term;

                                        EXCEPTION WHEN OTHERS THEN
                                            schd     := null;
                                            title    := null;
                                            credit   := null;
                                            credit_bill := null;
                                        END;


                                        begin
                                            select scrgmod_gmod_code
                                                  into gmod
                                            from scrgmod
                                            where scrgmod_subj_code=c.subj
                                            and     scrgmod_crse_numb=c.crse
                                            and     scrgmod_default_ind='D';
                                        exception when others then
                                            gmod:='1';
                                        end;

                                        --aqui se agrego para no gnerera mas grupos



                                        if c.prof is null then


                                            crn:=crn;

                                        else

                                            BEGIN

                                                select sztcrnv_crn
                                                into crn
                                                from SZTCRNV
                                                where 1 = 1
                                                and rownum = 1
                                                and SZTCRNV_crn not in (select to_number(crn)
                                                                        from
                                                                        (
                                                                        select case when
                                                                                                substr(SSBSECT_CRN,1,1) in('L','M') then to_number(substr(SSBSECT_CRN,2,10))
                                                                                      else
                                                                                            to_number(SSBSECT_CRN)
                                                                                      end crn,
                                                                                      SSBSECT_CRN
                                                                            from ssbsect
                                                                            where 1 = 1
                                                                            and ssbsect_term_code= c.periodo
                                                                        )
                                                                        where 1 = 1)
                                                order by 1;

                                             EXCEPTION WHEN OTHERS THEN
                                                raise_application_error (-20002,'Error al 2  '|| SQLCODE||' Error: '||SQLERRM);
                                                dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                                crn := NULL;
                                             END;


                                            if c.nivel ='LI' then

                                                crn:='L'||crn;

                                            else

                                                crn:='M'||crn;

                                            end if;



                                        end if;

                                        BEGIN
                                           SELECT DISTINCT sobptrm_start_date,
                                                            sobptrm_end_date ,
                                                            sobptrm_weeks
                                           INTO f_inicio,
                                                f_fin,
                                                sem
                                           FROM sobptrm
                                           WHERE 1 = 1
                                           AND sobptrm_term_code=c.periodo
                                           and sobptrm_ptrm_code=c.parte;

                                        EXCEPTION WHEN OTHERS THEN
                                            NULL;
                                        END;

                                        IF crn IS NOT NULL THEN

                                            BEGIN

                                               SELECT SZTPROF_CUPO
                                               INTO l_maximo_alumnos
                                               FROM SZTPROF
                                               WHERE 1 = 1
                                               AND SZTPROF_no_regla= p_regla
                                               AND SZTPROF_ID =c.prof
                                               AND SZTPROF_MATERIA =c.materia;

                                            EXCEPTION WHEN OTHERS THEN

                                               l_maximo_alumnos:=50;

                                            END;


                                             --raise_application_error (-20002,'Buscamos SSBSECT_CENSUS_ENRL_DATE  '||f_inicio);

                                            BEGIN

                                                INSERT INTO ssbsect VALUES (
                                                                            c.periodo,     --SSBSECT_TERM_CODE
                                                                            crn,     --SSBSECT_CRN
                                                                            c.parte,     --SSBSECT_PTRM_CODE
                                                                            c.subj,     --SSBSECT_SUBJ_CODE
                                                                            c.crse,     --SSBSECT_CRSE_NUMB
                                                                            c.grupo,     --SSBSECT_SEQ_NUMB
                                                                            'A',    --SSBSECT_SSTS_CODE
                                                                            schd,    --SSBSECT_SCHD_CODE
                                                                            c.campus,    --SSBSECT_CAMP_CODE
                                                                            title,   --SSBSECT_CRSE_TITLE
                                                                            credit,   --SSBSECT_CREDIT_HRS
                                                                            credit_bill,   --SSBSECT_BILL_HRS
                                                                            gmod,   --SSBSECT_GMOD_CODE
                                                                            NULL,  --SSBSECT_SAPR_CODE
                                                                            NULL, --SSBSECT_SESS_CODE
                                                                            NULL,  --SSBSECT_LINK_IDENT
                                                                            NULL,  --SSBSECT_PRNT_IND
                                                                            'Y',  --SSBSECT_GRADABLE_IND
                                                                            NULL,  --SSBSECT_TUIW_IND
                                                                            0, --SSBSECT_REG_ONEUP
                                                                            0, --SSBSECT_PRIOR_ENRL
                                                                            0, --SSBSECT_PROJ_ENRL
                                                                            l_maximo_alumnos, --SSBSECT_MAX_ENRL
                                                                            0,--SSBSECT_ENRL
                                                                            l_maximo_alumnos,--SSBSECT_SEATS_AVAIL
                                                                            NULL,--SSBSECT_TOT_CREDIT_HRS
                                                                            '0',--SSBSECT_CENSUS_ENRL
                                                                            f_inicio,--SSBSECT_CENSUS_ENRL_DATE
                                                                            SYSDATE -5,--SSBSECT_ACTIVITY_DATE
                                                                            f_inicio,--SSBSECT_PTRM_START_DATE
                                                                            f_fin,--SSBSECT_PTRM_END_DATE
                                                                            sem,--SSBSECT_PTRM_WEEKS
                                                                            NULL,--SSBSECT_RESERVED_IND
                                                                            NULL, --SSBSECT_WAIT_CAPACITY
                                                                            NULL,--SSBSECT_WAIT_COUNT
                                                                            NULL,--SSBSECT_WAIT_AVAIL
                                                                            NULL,--SSBSECT_LEC_HR
                                                                            NULL,--SSBSECT_LAB_HR
                                                                            NULL,--SSBSECT_OTH_HR
                                                                            NULL,--SSBSECT_CONT_HR
                                                                            NULL,--SSBSECT_ACCT_CODE
                                                                            NULL,--SSBSECT_ACCL_CODE
                                                                            NULL,--SSBSECT_CENSUS_2_DATE
                                                                            NULL,--SSBSECT_ENRL_CUT_OFF_DATE
                                                                            NULL,--SSBSECT_ACAD_CUT_OFF_DATE
                                                                            NULL,--SSBSECT_DROP_CUT_OFF_DATE
                                                                            NULL,--SSBSECT_CENSUS_2_ENRL
                                                                            'Y',--SSBSECT_VOICE_AVAIL
                                                                            'N',--SSBSECT_CAPP_PREREQ_TEST_IND
                                                                            NULL,--SSBSECT_GSCH_NAME
                                                                            NULL,--SSBSECT_BEST_OF_COMP
                                                                            NULL,--SSBSECT_SUBSET_OF_COMP
                                                                            'NOP',--SSBSECT_INSM_CODE
                                                                            NULL,--SSBSECT_REG_FROM_DATE
                                                                            NULL,--SSBSECT_REG_TO_DATE
                                                                            NULL,--SSBSECT_LEARNER_REGSTART_FDATE
                                                                            NULL,--SSBSECT_LEARNER_REGSTART_TDATE
                                                                            NULL,--SSBSECT_DUNT_CODE
                                                                            NULL,--SSBSECT_NUMBER_OF_UNITS
                                                                            0,--SSBSECT_NUMBER_OF_EXTENSIONS
                                                                            'PRONOSTICO',--SSBSECT_DATA_ORIGIN
                                                                            USER,--SSBSECT_USER_ID
                                                                            'MOOD',--SSBSECT_INTG_CDE
                                                                            'B',--SSBSECT_PREREQ_CHK_METHOD_CDE
                                                                            USER,--SSBSECT_KEYWORD_INDEX_ID
                                                                            NULL,--SSBSECT_SCORE_OPEN_DATE
                                                                            NULL,--SSBSECT_SCORE_CUTOFF_DATE
                                                                            NULL,--SSBSECT_REAS_SCORE_OPEN_DATE
                                                                            NULL,--SSBSECT_REAS_SCORE_CTOF_DATE
                                                                            NULL,--SSBSECT_SURROGATE_ID
                                                                            NULL,--SSBSECT_VERSION
                                                                            NULL
                                                                            );--SSBSECT_VPDI_CODE


                                                BEGIN

                                                    UPDATE sobterm SET sobterm_crn_oneup = crn
                                                    WHERE 1 = 1
                                                    AND sobterm_term_code = c.periodo;

                                                EXCEPTION WHEN OTHERS THEN
                                                  NULL;
                                                END;



                                                BEGIN

                                                     INSERT INTO ssrmeet VALUES(C.periodo,
                                                                                crn,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                SYSDATE,
                                                                                f_inicio,
                                                                                f_fin,
                                                                                '01',
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                'ENL',
                                                                                NULL,
                                                                                credit,
                                                                                NULL,
                                                                                0,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                'CLVI',
                                                                                'PRONOSTICO',
                                                                                USER,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL
                                                                                );

                                                EXCEPTION WHEN OTHERS THEN
                                                    vl_error := 'Se presento un Error al insertar en ssrmeet ' ||SQLERRM;
                                                END;

                                                BEGIN

                                                    SELECT spriden_pidm
                                                    INTO  pidm_prof
                                                    FROM  spriden
                                                    WHERE 1 = 1
                                                    AND spriden_id=c.prof
                                                    AND spriden_change_ind IS NULL;

                                                EXCEPTION WHEN OTHERS THEN
                                                    pidm_prof:=NULL;
                                                END;

                                                IF pidm_prof IS NOT NULL THEN

                                                   dbms_output.put_line('Crea el CRN para el docente:'|| pidm_prof  ||'*'||crn);

                                                   BEGIN

                                                       SELECT COUNT (1)
                                                       INTO vl_exite_prof
                                                       FROM sirasgn
                                                       WHERE 1 = 1
                                                       AND sirasgn_term_code = c.periodo
                                                       AND sirasgn_crn = crn;
                                                   -- And SIRASGN_PIDM = pidm_prof;
                                                   EXCEPTION WHEN OTHERS THEN
                                                      vl_exite_prof := 0;
                                                   END;

                                                   IF vl_exite_prof = 0 THEN

                                                       BEGIN
                                                               INSERT INTO sirasgn VALUES(c.periodo,
                                                                                          crn,
                                                                                          pidm_prof,
                                                                                          '01',
                                                                                          100,
                                                                                          null,
                                                                                          100,
                                                                                          'Y',
                                                                                          null,
                                                                                          null,
                                                                                          sysdate -5,
                                                                                          null,
                                                                                          null,
                                                                                          null,
                                                                                          null,
                                                                                          'PRONOSTICO',
                                                                                          'SZFALGO 2',
                                                                                          null,
                                                                                          null,
                                                                                          null,
                                                                                          null,
                                                                                          null,
                                                                                          null
                                                                                          );
                                                       EXCEPTION WHEN OTHERS THEN
                                                            NULL;
                                                       END;

                                                   ELSE

                                                       BEGIN

                                                            UPDATE sirasgn SET sirasgn_primary_ind = NULL
                                                            Where 1 = 1
                                                            AND sirasgn_term_code = c.periodo
                                                            AND sirasgn_crn = crn;

                                                       EXCEPTION WHEN OTHERS THEN
                                                            NULL;
                                                       END;

                                                       BEGIN
                                                               INSERT INTO sirasgn VALUES(c.periodo,
                                                                                          crn,
                                                                                          pidm_prof,
                                                                                          '01',
                                                                                          100,
                                                                                          NULL,
                                                                                          100,
                                                                                          'Y',
                                                                                          NULL,
                                                                                          NULL,
                                                                                          SYSDATE,
                                                                                          NULL,
                                                                                          NULL,
                                                                                          NULL,
                                                                                          NULL,
                                                                                          'PRONOSTICO',
                                                                                          'SZFALGO 3',
                                                                                          NULL,
                                                                                          NULL,
                                                                                          NULL,
                                                                                          NULL,
                                                                                          NULL,
                                                                                          NULL
                                                                                          );
                                                       EXCEPTION WHEN OTHERS THEN
                                                            NULL;
                                                       END;

                                                   END IF;

                                                END IF;

                                                conta_ptrm :=0;

                                                BEGIN

                                                     SELECT COUNT(*)
                                                     INTO conta_ptrm
                                                     FROM sfbetrm
                                                     WHERE 1 = 1
                                                     AND sfbetrm_term_code=c.periodo
                                                     AND sfbetrm_pidm=c.pidm;

                                                EXCEPTION WHEN OTHERS THEN
                                                    conta_ptrm := 0;
                                                END;


                                                IF conta_ptrm =0 THEN

                                                    BEGIN
                                                            INSERT INTO sfbetrm VALUES(c.periodo,
                                                                                       c.pidm,
                                                                                       'EL',
                                                                                       SYSDATE,
                                                                                       99.99,
                                                                                       'Y',
                                                                                       NULL,
                                                                                       SYSDATE,
                                                                                       SYSDATE,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       USER,
                                                                                       NULL,
                                                                                       'PRONOSTICO',
                                                                                       NULL,
                                                                                       0,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       USER,
                                                                                       NULL
                                                                                       );
                                                    EXCEPTION WHEN OTHERS THEN
                                                        vl_error := ('Se presento un error al insertar en la tabla sfbetrm ' || sqlerrm);
                                                    END;

                                                END IF;

                                                BEGIN


                                                    begin
                                                            INSERT INTO sfrstcr VALUES(
                                                                                   c.periodo,     --SFRSTCR_TERM_CODE
                                                                                   c.pidm,     --SFRSTCR_PIDM
                                                                                   crn,     --SFRSTCR_CRN
                                                                                   1,     --SFRSTCR_CLASS_SORT_KEY
                                                                                   c.grupo,    --SFRSTCR_REG_SEQ
                                                                                   c.parte,    --SFRSTCR_PTRM_CODE
                                                                                   'RE',     --SFRSTCR_RSTS_CODE
                                                                                   SYSDATE -5,    --SFRSTCR_RSTS_DATE
                                                                                   NULL,    --SFRSTCR_ERROR_FLAG
                                                                                   NULL,    --SFRSTCR_MESSAGE
                                                                                   credit_bill,    --SFRSTCR_BILL_HR
                                                                                   3, --SFRSTCR_WAIV_HR
                                                                                   credit,     --SFRSTCR_CREDIT_HR
                                                                                   credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                                                                   credit,     --SFRSTCR_CREDIT_HR_HOLD
                                                                                   gmod,     --SFRSTCR_GMOD_CODE
                                                                                   NULL,    --SFRSTCR_GRDE_CODE
                                                                                   NULL,    --SFRSTCR_GRDE_CODE_MID
                                                                                   NULL,    --SFRSTCR_GRDE_DATE
                                                                                   'N',    --SFRSTCR_DUPL_OVER
                                                                                   'N',    --SFRSTCR_LINK_OVER
                                                                                   'N',    --SFRSTCR_CORQ_OVER
                                                                                   'N',    --SFRSTCR_PREQ_OVER
                                                                                   'N',     --SFRSTCR_TIME_OVER
                                                                                   'N',     --SFRSTCR_CAPC_OVER
                                                                                   'N',     --SFRSTCR_LEVL_OVER
                                                                                   'N',     --SFRSTCR_COLL_OVER
                                                                                   'N',     --SFRSTCR_MAJR_OVER
                                                                                   'N',     --SFRSTCR_CLAS_OVER
                                                                                   'N',     --SFRSTCR_APPR_OVER
                                                                                   'N',     --SFRSTCR_APPR_RECEIVED_IND
                                                                                   SYSDATE -5,      --SFRSTCR_ADD_DATE
                                                                                   SYSDATE -5,     --SFRSTCR_ACTIVITY_DATE
                                                                                   c.nivel,     --SFRSTCR_LEVL_CODE
                                                                                   c.campus,     --SFRSTCR_CAMP_CODE
                                                                                   c.materia,     --SFRSTCR_RESERVED_KEY
                                                                                   NULL,     --SFRSTCR_ATTEND_HR
                                                                                   'Y',     --SFRSTCR_REPT_OVER
                                                                                   'N' ,    --SFRSTCR_RPTH_OVER
                                                                                   NULL,    --SFRSTCR_TEST_OVER
                                                                                   'N',    --SFRSTCR_CAMP_OVER
                                                                                   USER,    --SFRSTCR_USER
                                                                                   'N',    --SFRSTCR_DEGC_OVER
                                                                                   'N',    --SFRSTCR_PROG_OVER
                                                                                   NULL,    --SFRSTCR_LAST_ATTEND
                                                                                   NULL,    --SFRSTCR_GCMT_CODE
                                                                                   'PRONOSTICO',    --SFRSTCR_DATA_ORIGIN
                                                                                   SYSDATE,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                                                   'N',  --SFRSTCR_DEPT_OVER
                                                                                   'N',  --SFRSTCR_ATTS_OVER
                                                                                   'N', --SFRSTCR_CHRT_OVER
                                                                                   c.grupo , --SFRSTCR_RMSG_CDE
                                                                                   NULL,  --SFRSTCR_WL_PRIORITY
                                                                                   NULL,  --SFRSTCR_WL_PRIORITY_ORIG
                                                                                   NULL,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                                                   NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                                                   'N', --SFRSTCR_MEXC_OVER
                                                                                   c.study,--SFRSTCR_STSP_KEY_SEQUENCE
                                                                                   NULL,--SFRSTCR_BRDH_SEQ_NUM
                                                                                   '01',--SFRSTCR_BLCK_CODE
                                                                                   NULL,--SFRSTCR_STRH_SEQNO
                                                                                   NULL, --SFRSTCR_STRD_SEQNO
                                                                                   NULL,  --SFRSTCR_SURROGATE_ID
                                                                                   NULL, --SFRSTCR_VERSION
                                                                                   USER,--SFRSTCR_USER_ID
                                                                                   vl_orden--SFRSTCR_VPDI_CODE
                                                                                    );
                                                    exception when others then

                                                        dbms_output.put_line('Error al insertar  SFRSTCR 2 '||sqlerrm);
                                                    end;


                                                    BEGIN

                                                        UPDATE SZTPRONO SET SZTPRONO_ENVIO_HORARIOS='S'
                                                        WHERE 1 = 1
                                                        AND SZTPRONO_NO_REGLA = p_regla
                                                        and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                        AND SZTPRONO_PIDM = c.pidm
                                                        and SZTPRONO_ENVIO_HORARIOS='N'
                                                        and sztprono_materia_legal = c.materia
                                                        AND SZTPRONO_PTRM_CODE =parte;


                                                    EXCEPTION WHEN OTHERS THEN
                                                      NULL;
                                                    END;


                                                    BEGIN

                                                         UPDATE ssbsect SET ssbsect_enrl = ssbsect_enrl + 1
                                                         WHERE 1 = 1
                                                         AND ssbsect_term_code = c.periodo
                                                         AND SSBSECT_CRN  = crn;

                                                    EXCEPTION WHEN OTHERS THEN
                                                        vl_error := 'Se presento un error al actualizar el enrolamiento ' ||SQLERRM;
                                                    END;

                                                    BEGIN

                                                        UPDATE ssbsect SET ssbsect_seats_avail=ssbsect_seats_avail -1
                                                        WHERE 1 = 1
                                                        AND ssbsect_term_code = c.periodo
                                                        AND ssbsect_crn  = crn;

                                                    EXCEPTION WHEN OTHERS THEN
                                                        vl_error := 'Se presento un error al actualizar la disponibilidad del grupo ' ||SQLERRM;
                                                    END;

                                                    Begin
                                                             update ssbsect
                                                                    set ssbsect_census_enrl=ssbsect_enrl
                                                             Where SSBSECT_TERM_CODE = c.periodo
                                                             And SSBSECT_CRN  = crn;
                                                    Exception
                                                    When Others then
                                                        vl_error := 'Se presento un error al actualizar el Censo del grupo ' ||sqlerrm;
                                                    End;

                                                    IF C.SGBSTDN_STYP_CODE = 'F' THEN

                                                        BEGIN

                                                            UPDATE sgbstdn a SET a.sgbstdn_styp_code ='N',
                                                                                 a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                                                 A.SGBSTDN_USER_ID =USER
                                                            WHERE 1 = 1
                                                            AND a.sgbstdn_pidm = c.pidm
                                                            AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                                           FROM sgbstdn a1
                                                                                           WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                                           AND a1.sgbstdn_program_1 = a.sgbstdn_program_1
                                                                                           )
                                                            AND a.sgbstdn_program_1 = c.prog;

                                                        EXCEPTION WHEN OTHERS THEN
                                                            vl_error := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
                                                        END;

                                                    END IF;

                                                    BEGIN

                                                        SELECT COUNT(*)
                                                        INTO l_cambio_estatus
                                                        FROM sfrstcr
                                                        WHERE 1 = 1
                                                        AND SFRSTCR_TERM_CODE||SFRSTCR_PTRM_CODE = c.periodo||c.parte
                                                        AND sfrstcr_pidm = c.pidm;

                                                    EXCEPTION WHEN OTHERS THEN
                                                        l_cambio_estatus:=0;
                                                    END;


                                                    IF l_cambio_estatus > 0 THEN

                                                        IF C.SGBSTDN_STYP_CODE = 'N' THEN

                                                            BEGIN

                                                                UPDATE sgbstdn a SET a.sgbstdn_styp_code ='C',
                                                                                     a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                                                     A.SGBSTDN_USER_ID =USER
                                                                WHERE 1 = 1
                                                                AND a.sgbstdn_pidm = c.pidm
                                                                AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                                               FROM sgbstdn a1
                                                                                               WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                                               AND a1.sgbstdn_program_1 = a.sgbstdn_program_1
                                                                                               )
                                                                AND a.sgbstdn_program_1 = c.prog;

                                                            EXCEPTION WHEN OTHERS THEN
                                                                vl_error := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
                                                            END;

                                                         END IF;

                                                    end if;

                                                    f_inicio := null;

                                                    BEGIN

                                                        SELECT DISTINCT sobptrm_start_date
                                                        INTO f_inicio
                                                        FROM sobptrm
                                                        WHERE sobptrm_term_code=c.periodo
                                                        AND   sobptrm_ptrm_code=c.parte;

                                                    EXCEPTION WHEN OTHERS THEN
                                                        f_inicio := null;
                                                        vl_error := 'Se presento un error al Obtener la fecha de inicio de Clases  periodo '||c.periodo||' parte '||c.parte||' '||SQLERRM||' poe';
                                                    END;

                                                    IF f_inicio is NOT NULL THEN

                                                        BEGIN
                                                                Update sorlcur
                                                                set sorlcur_start_date  = trunc (f_inicio)
                                                                Where SORLCUR_PIDM = c.pidm
                                                                And SORLCUR_PROGRAM = c.prog
                                                                And SORLCUR_LMOD_CODE = 'LEARNER'
                                                                And SORLCUR_KEY_SEQNO = c.study;
                                                        EXCEPTION WHEN OTHERS THEN
                                                               vl_error := 'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur ' ||SQLERRM;
                                                        END;

                                                    END IF;

                                                    conta_ptrm:=0;

                                                    BEGIN

                                                        SELECT COUNT (*)
                                                        INTO conta_ptrm
                                                        FROM sfrareg
                                                        WHERE 1 = 1
                                                        AND sfrareg_pidm = c.pidm
                                                        And sfrareg_term_code = c.periodo
                                                        And sfrareg_crn = crn
                                                        And sfrareg_extension_number = 0
                                                        And sfrareg_rsts_code = 'RE';

                                                    EXCEPTION WHEN OTHERS THEN
                                                       conta_ptrm :=0;
                                                    END;

                                                    IF conta_ptrm = 0 THEN

                                                         BEGIN
                                                                 INSERT INTO sfrareg VALUES(c.pidm,
                                                                                            c.periodo,
                                                                                            crn ,
                                                                                            0,
                                                                                            'RE',
                                                                                            nvl(f_inicio,pn_fecha),
                                                                                            nvl(f_fin,sysdate),
                                                                                            'N',
                                                                                            'N',
                                                                                            SYSDATE,
                                                                                            USER,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            'PRONOSTICO',
                                                                                            SYSDATE,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL
                                                                                            );
                                                         EXCEPTION WHEN OTHERS THEN
                                                              vl_error := 'Se presento un error al insertar el registro de la materia para el alumno ' ||SQLERRM;
                                                         END;

                                                    END IF;

                                                    BEGIN
                                                        UPDATE SZTPRONO SET SZTPRONO_ENVIO_HORARIOS='S'
                                                        WHERE 1 = 1
                                                        AND SZTPRONO_NO_REGLA = p_regla
                                                        and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                        and SZTPRONO_ENVIO_HORARIOS='N'
                                                        AND SZTPRONO_PIDM = c.pidm
                                                        and sztprono_materia_legal = c.materia
                                                        AND SZTPRONO_PTRM_CODE =parte;

                                                   EXCEPTION WHEN OTHERS THEN
                                                      NULL;
                                                   END;

                                                EXCEPTION WHEN OTHERS THEN
                                                    vl_error := 'Se presento un error al insertar al alumno en el grupo2 ' ||SQLERRM;
                                                END;


                                            EXCEPTION WHEN OTHERS THEN
                                                vl_error := 'Se presento un Error al insertar el nuevo grupo en la tabla SSBSECT ' ||SQLERRM;
                                            END;

                                        END IF;

                                    END IF;  -------- > No hay cupo en el grupo

                                ELSE

                                    dbms_output.put_line('mensaje:'|| 'No hay grupo creado Con docente');

                                    schd      := NULL;
                                    title     := NULL;
                                    credit    := NULL;
                                    gmod      := NULL;
                                    f_inicio  := NULL;
                                    f_fin     := NULL;
                                    sem       := NULL;
                                    crn       := NULL;
                                    pidm_prof := NULL;
                                    vl_exite_prof :=0;

                                    BEGIN

                                         SELECT scrschd_schd_code,
                                                scbcrse_title,
                                                scbcrse_credit_hr_low,
                                                scbcrse_bill_hr_low
                                         INTO schd,
                                              title,
                                              credit,
                                              credit_bill
                                         FROM scbcrse,
                                              scrschd
                                         WHERE 1 = 1
                                         AND scbcrse_subj_code=c.subj
                                         AND scbcrse_crse_numb=c.crse
                                         AND scbcrse_eff_term='000000'
                                         AND scrschd_subj_code=scbcrse_subj_code
                                         AND scrschd_crse_numb=scbcrse_crse_numb
                                         AND scrschd_eff_term=scbcrse_eff_term;

                                    EXCEPTION WHEN OTHERS THEN
                                        schd         := NULL;
                                        title        := NULL;
                                        credit       := NULL;
                                        credit_bill  := NULL;
                                    END;

                                    BEGIN

                                        SELECT scrgmod_gmod_code
                                        INTO gmod
                                        FROM scrgmod
                                        WHERE 1 = 1
                                        AND scrgmod_subj_code=c.subj
                                        AND scrgmod_crse_numb=c.crse
                                        AND scrgmod_default_ind='D';

                                    EXCEPTION WHEN OTHERS THEN
                                        gmod:='1';
                                    END;

                                    BEGIN

                                       select sztcrnv_crn
                                       into crn
                                       from SZTCRNV
                                       where 1 = 1
                                       and rownum = 1
                                       and SZTCRNV_crn not in (select to_number(crn)
                                                               from
                                                               (
                                                               select case when
                                                                                       substr(SSBSECT_CRN,1,1) in('L','M') then to_number(substr(SSBSECT_CRN,2,10))
                                                                             else
                                                                                   to_number(SSBSECT_CRN)
                                                                             end crn,
                                                                             SSBSECT_CRN
                                                                   from ssbsect
                                                                   where 1 = 1
                                                                   and ssbsect_term_code= c.periodo
                                                               )
                                                               where 1 = 1)
                                       order by 1;

                                    EXCEPTION WHEN OTHERS THEN
                                       raise_application_error (-20002,'Error al 2  '|| SQLCODE||' Error: '||SQLERRM);
                                       dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                       crn := NULL;
                                    END;


                                    if c.nivel ='LI' then

                                        crn:='L'||crn;

                                    else

                                        crn:='M'||crn;

                                    end if;

                                    BEGIN

                                       SELECT DISTINCT sobptrm_start_date,
                                                       sobptrm_end_date,
                                                       sobptrm_weeks
                                       INTO f_inicio,
                                            f_fin,
                                            sem
                                       FROM sobptrm
                                       WHERE 1  = 1
                                       AND sobptrm_term_code=c.periodo
                                       AND sobptrm_ptrm_code=c.parte;

                                    EXCEPTION WHEN OTHERS THEN
                                        vl_error := 'No se Encontro configuracion para el Periodo= ' ||c.periodo ||' y Parte de Periodo= '||c.parte ||SQLERRM;
                                    END;


                                    IF crn IS NOT NULL THEN

                                    -- le movemos extraemos el numero de alumonos de la tabla de profesores

                                        BEGIN

                                            SELECT SZTPROF_CUPO
                                            INTO l_maximo_alumnos
                                            FROM SZTPROF
                                            WHERE 1 = 1
                                            AND SZTPROF_no_regla= p_regla
                                            AND SZTPROF_ID =c.prof
                                            AND SZTPROF_MATERIA =c.materia;

                                        EXCEPTION WHEN OTHERS THEN
                                            l_maximo_alumnos:=50;
                                        END;

                                        BEGIN

                                            INSERT INTO ssbsect VALUES (
                                                                        c.periodo,     --SSBSECT_TERM_CODE
                                                                        crn,     --SSBSECT_CRN
                                                                        c.parte,     --SSBSECT_PTRM_CODE
                                                                        c.subj,     --SSBSECT_SUBJ_CODE
                                                                        c.crse,     --SSBSECT_CRSE_NUMB
                                                                        c.grupo,     --SSBSECT_SEQ_NUMB
                                                                        'A',    --SSBSECT_SSTS_CODE
                                                                        schd,    --SSBSECT_SCHD_CODE
                                                                        c.campus,    --SSBSECT_CAMP_CODE
                                                                        title,   --SSBSECT_CRSE_TITLE
                                                                        credit,   --SSBSECT_CREDIT_HRS
                                                                        credit_bill,   --SSBSECT_BILL_HRS
                                                                        gmod,   --SSBSECT_GMOD_CODE
                                                                        NULL,  --SSBSECT_SAPR_CODE
                                                                        NULL, --SSBSECT_SESS_CODE
                                                                        NULL,  --SSBSECT_LINK_IDENT
                                                                        NULL,  --SSBSECT_PRNT_IND
                                                                        'Y',  --SSBSECT_GRADABLE_IND
                                                                        NULL,  --SSBSECT_TUIW_IND
                                                                        0, --SSBSECT_REG_ONEUP
                                                                        0, --SSBSECT_PRIOR_ENRL
                                                                        0, --SSBSECT_PROJ_ENRL
                                                                        l_maximo_alumnos, --SSBSECT_MAX_ENRL
                                                                        0,--SSBSECT_ENRL
                                                                        l_maximo_alumnos,--SSBSECT_SEATS_AVAIL
                                                                        NULL,--SSBSECT_TOT_CREDIT_HRS
                                                                        '0',--SSBSECT_CENSUS_ENRL
                                                                        NVL(f_inicio,SYSDATE),--SSBSECT_CENSUS_ENRL_DATE
                                                                        SYSDATE,--SSBSECT_ACTIVITY_DATE
                                                                        NVL(f_inicio,SYSDATE),--SSBSECT_PTRM_START_DATE
                                                                        NVL(f_FIN,SYSDATE),--SSBSECT_PTRM_END_DATE
                                                                        sem,--SSBSECT_PTRM_WEEKS
                                                                        NULL,--SSBSECT_RESERVED_IND
                                                                        NULL, --SSBSECT_WAIT_CAPACITY
                                                                        NULL,--SSBSECT_WAIT_COUNT
                                                                        NULL,--SSBSECT_WAIT_AVAIL
                                                                        NULL,--SSBSECT_LEC_HR
                                                                        NULL,--SSBSECT_LAB_HR
                                                                        NULL,--SSBSECT_OTH_HR
                                                                        NULL,--SSBSECT_CONT_HR
                                                                        NULL,--SSBSECT_ACCT_CODE
                                                                        NULL,--SSBSECT_ACCL_CODE
                                                                        NULL,--SSBSECT_CENSUS_2_DATE
                                                                        NULL,--SSBSECT_ENRL_CUT_OFF_DATE
                                                                        NULL,--SSBSECT_ACAD_CUT_OFF_DATE
                                                                        NULL,--SSBSECT_DROP_CUT_OFF_DATE
                                                                        NULL,--SSBSECT_CENSUS_ENRL
                                                                        'Y',--SSBSECT_VOICE_AVAIL
                                                                        'N',--SSBSECT_CAPP_PREREQ_TEST_IND
                                                                        NULL,--SSBSECT_GSCH_NAME
                                                                        NULL,--SSBSECT_BEST_OF_COMP
                                                                        NULL,--SSBSECT_SUBSET_OF_COMP
                                                                        'NOP',--SSBSECT_INSM_CODE
                                                                        NULL,--SSBSECT_REG_FROM_DATE
                                                                        NULL,--SSBSECT_REG_TO_DATE
                                                                        NULL,--SSBSECT_LEARNER_REGSTART_FDATE
                                                                        NULL,--SSBSECT_LEARNER_REGSTART_TDATE
                                                                        NULL,--SSBSECT_DUNT_CODE
                                                                        NULL,--SSBSECT_NUMBER_OF_UNITS
                                                                        0,--SSBSECT_NUMBER_OF_EXTENSIONS
                                                                        'PRONOSTICO',--SSBSECT_DATA_ORIGIN
                                                                        USER,--SSBSECT_USER_ID
                                                                        'MOOD',--SSBSECT_INTG_CDE
                                                                        'B',--SSBSECT_PREREQ_CHK_METHOD_CDE
                                                                        USER,--SSBSECT_KEYWORD_INDEX_ID
                                                                        NULL,--SSBSECT_SCORE_OPEN_DATE
                                                                        NULL,--SSBSECT_SCORE_CUTOFF_DATE
                                                                        NULL,--SSBSECT_REAS_SCORE_OPEN_DATE
                                                                        NULL,--SSBSECT_REAS_SCORE_CTOF_DATE
                                                                        NULL,--SSBSECT_SURROGATE_ID
                                                                        NULL,--SSBSECT_VERSION
                                                                        NULL--SSBSECT_VPDI_CODE
                                                                        );


                                            BEGIN

                                                UPDATE SOBTERM set sobterm_crn_oneup = crn
                                                where 1 = 1
                                                AND sobterm_term_code = c.periodo;

                                            EXCEPTION WHEN OTHERS THEN
                                                NULL;
                                            END;

                                            BEGIN

                                                 INSERT INTO ssrmeet VALUES(C.periodo,
                                                                            crn,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            SYSDATE,
                                                                            f_inicio,
                                                                            f_fin,
                                                                            '01',
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            'ENL',
                                                                            NULL,
                                                                            credit,
                                                                            NULL,
                                                                            0,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            'CLVI',
                                                                            'PRONOSTICO',
                                                                            USER,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL
                                                                            );
                                            EXCEPTION WHEN OTHERS THEN
                                                vl_error := 'Se presento un Error al insertar en ssrmeet ' ||SQLERRM;
                                            END;

                                            BEGIN

                                                SELECT spriden_pidm
                                                INTO pidm_prof
                                                FROM  spriden
                                                WHERE 1 = 1
                                                AND spriden_id=c.prof
                                                AND spriden_change_ind IS NULL;

                                            EXCEPTION WHEN OTHERS THEN
                                                pidm_prof:=NULL;
                                            END;

                                            IF pidm_prof IS NOT NULL THEN

                                                dbms_output.put_line('Crea el CRN para el docente:'|| pidm_prof  ||'*'||crn);

                                                BEGIN
                                                      SELECT COUNT (1)
                                                      INTO vl_exite_prof
                                                      FROM sirasgn
                                                      Where 1 = 1
                                                      AND sirasgn_term_code = c.periodo
                                                      AND sirasgn_crn = crn;

                                                EXCEPTION WHEN OTHERS THEN
                                                    vl_exite_prof := 0;
                                                END;

                                                IF vl_exite_prof = 0 THEN

                                                    BEGIN
                                                             INSERT INTO sirasgn VALUES(
                                                                                        c.periodo,
                                                                                        crn,
                                                                                        pidm_prof,
                                                                                        '01',
                                                                                        100,
                                                                                        NULL,
                                                                                        100,
                                                                                        'Y',
                                                                                        NULL,
                                                                                        NULL,
                                                                                        SYSDATE,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        'PRONOSTICO',
                                                                                        'SZFALGO 4',
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL,
                                                                                        NULL
                                                                                        );
                                                    EXCEPTION WHEN OTHERS THEN
                                                        NULL;
                                                    END;

                                                ELSE

                                                    BEGIN

                                                        UPDATE sirasgn SET sirasgn_primary_ind = NULL
                                                        Where 1 = 1
                                                        AND sirasgn_term_code = c.periodo
                                                        And sirasgn_crn = crn;

                                                    EXCEPTION WHEN OTHERS THEN
                                                        NULL;
                                                    END;

                                                    BEGIN
                                                            INSERT INTO sirasgn VALUES(c.periodo,
                                                                                       crn,
                                                                                       pidm_prof,
                                                                                       '01',
                                                                                       100,
                                                                                       NULL,
                                                                                       100,
                                                                                       'Y',
                                                                                       NULL,
                                                                                       NULL,
                                                                                       SYSDATE,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       'PRONOSTICO',
                                                                                       'SZFALGO 5',
                                                                                       NULL,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       NULL,
                                                                                       NULL
                                                                                       );
                                                    EXCEPTION WHEN OTHERS THEN
                                                        NULL;
                                                    END;

                                                END IF;

                                            END IF;

                                            conta_ptrm :=0;

                                            BEGIN
                                                 SELECT COUNT(*)
                                                 INTO conta_ptrm
                                                 FROM sfbetrm
                                                 WHERE 1 = 1
                                                 AND sfbetrm_term_code=c.periodo
                                                 AND sfbetrm_pidm=c.pidm;
                                            Exception
                                                When Others then
                                                  conta_ptrm := 0;
                                            End;


                                            IF conta_ptrm =0 THEN

                                                BEGIN

                                                    INSERT INTO sfbetrm VALUES(
                                                                               c.periodo,
                                                                               c.pidm,
                                                                               'EL',
                                                                               SYSDATE,
                                                                               99.99,
                                                                               'Y',
                                                                               NULL,
                                                                               SYSDATE,
                                                                               SYSDATE,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               USER,
                                                                               NULL,
                                                                               'PRONOSTICO',
                                                                               NULL,
                                                                               0,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               USER,
                                                                               NULL
                                                                               );
                                                EXCEPTION WHEN OTHERS THEN
                                                    vl_error := ('Se presento un error al insertar en la tabla sfbetrm ' || SQLERRM);
                                                END;

                                            END IF;

                                            BEGIN

                                                BEGIN



                                                    INSERT INTO sfrstcr VALUES(
                                                                               c.periodo,     --SFRSTCR_TERM_CODE
                                                                               c.pidm,     --SFRSTCR_PIDM
                                                                               crn,     --SFRSTCR_CRN
                                                                               1,     --SFRSTCR_CLASS_SORT_KEY
                                                                               c.grupo,    --SFRSTCR_REG_SEQ
                                                                               c.parte,    --SFRSTCR_PTRM_CODE
                                                                               'RE',     --SFRSTCR_RSTS_CODE
                                                                               sysdate -5,    --SFRSTCR_RSTS_DATE
                                                                               null,    --SFRSTCR_ERROR_FLAG
                                                                               null,    --SFRSTCR_MESSAGE
                                                                               credit_bill,    --SFRSTCR_BILL_HR
                                                                               3, --SFRSTCR_WAIV_HR
                                                                               credit,     --SFRSTCR_CREDIT_HR
                                                                               credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                                                               credit,     --SFRSTCR_CREDIT_HR_HOLD
                                                                               gmod,     --SFRSTCR_GMOD_CODE
                                                                               null,    --SFRSTCR_GRDE_CODE
                                                                               null,    --SFRSTCR_GRDE_CODE_MID
                                                                               null,    --SFRSTCR_GRDE_DATE
                                                                               'N',    --SFRSTCR_DUPL_OVER
                                                                               'N',    --SFRSTCR_LINK_OVER
                                                                               'N',    --SFRSTCR_CORQ_OVER
                                                                               'N',    --SFRSTCR_PREQ_OVER
                                                                               'N',     --SFRSTCR_TIME_OVER
                                                                               'N',     --SFRSTCR_CAPC_OVER
                                                                               'N',     --SFRSTCR_LEVL_OVER
                                                                               'N',     --SFRSTCR_COLL_OVER
                                                                               'N',     --SFRSTCR_MAJR_OVER
                                                                               'N',     --SFRSTCR_CLAS_OVER
                                                                               'N',     --SFRSTCR_APPR_OVER
                                                                               'N',     --SFRSTCR_APPR_RECEIVED_IND
                                                                               sysdate -5,      --SFRSTCR_ADD_DATE
                                                                               sysdate -5,     --SFRSTCR_ACTIVITY_DATE
                                                                               c.nivel,     --SFRSTCR_LEVL_CODE
                                                                               c.campus,     --SFRSTCR_CAMP_CODE
                                                                               c.materia,     --SFRSTCR_RESERVED_KEY
                                                                               null,     --SFRSTCR_ATTEND_HR
                                                                               'Y',     --SFRSTCR_REPT_OVER
                                                                               'N' ,    --SFRSTCR_RPTH_OVER
                                                                               null,    --SFRSTCR_TEST_OVER
                                                                               'N',    --SFRSTCR_CAMP_OVER
                                                                               user,    --SFRSTCR_USER
                                                                               'N',    --SFRSTCR_DEGC_OVER
                                                                               'N',    --SFRSTCR_PROG_OVER
                                                                               null,    --SFRSTCR_LAST_ATTEND
                                                                               null,    --SFRSTCR_GCMT_CODE
                                                                               'PRONOSTICO',    --SFRSTCR_DATA_ORIGIN
                                                                               sysdate,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                                               'N',  --SFRSTCR_DEPT_OVER
                                                                               'N',  --SFRSTCR_ATTS_OVER
                                                                               'N', --SFRSTCR_CHRT_OVER
                                                                               c.grupo , --SFRSTCR_RMSG_CDE
                                                                               null,  --SFRSTCR_WL_PRIORITY
                                                                               null,  --SFRSTCR_WL_PRIORITY_ORIG
                                                                               null,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                                               null, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                                               'N', --SFRSTCR_MEXC_OVER
                                                                               c.study,--SFRSTCR_STSP_KEY_SEQUENCE
                                                                               null,--SFRSTCR_BRDH_SEQ_NUM
                                                                               '01',--SFRSTCR_BLCK_CODE
                                                                               null,--SFRSTCR_STRH_SEQNO
                                                                               null, --SFRSTCR_STRD_SEQNO
                                                                               null,  --SFRSTCR_SURROGATE_ID
                                                                               null, --SFRSTCR_VERSION
                                                                               user,--SFRSTCR_USER_ID
                                                                               vl_orden--SFRSTCR_VPDI_CODE
                                                                               );
                                                EXCEPTION WHEN OTHERS THEN
                                                    dbms_output.put_line('Error al insertar  SFRSTCR xxx '||sqlerrm);
                                                END;


                                                BEGIN
                                                    UPDATE SZTPRONO SET SZTPRONO_ENVIO_HORARIOS='S'
                                                    WHERE 1 = 1
                                                    AND SZTPRONO_NO_REGLA = p_regla
                                                    and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                    AND SZTPRONO_PIDM = c.pidm
                                                    and SZTPRONO_ENVIO_HORARIOS='N'
                                                    and sztprono_materia_legal = c.materia
                                                    AND SZTPRONO_PTRM_CODE =parte;


                                                EXCEPTION WHEN OTHERS THEN
                                                  NULL;
                                                END;


                                                BEGIN

                                                     UPDATE ssbsect SET ssbsect_enrl = ssbsect_enrl + 1
                                                     WHERE 1 = 1
                                                     AND ssbsect_term_code = c.periodo
                                                     AND SSBSECT_CRN  = crn;

                                                EXCEPTION WHEN OTHERS THEN
                                                    vl_error := 'Se presento un error al actualizar el enrolamiento ' ||SQLERRM;
                                                END;

                                                BEGIN

                                                    UPDATE ssbsect SET ssbsect_seats_avail=ssbsect_seats_avail -1
                                                    WHERE 1 = 1
                                                    AND ssbsect_term_code = c.periodo
                                                    AND ssbsect_crn  = crn;

                                                EXCEPTION WHEN OTHERS THEN
                                                    vl_error := 'Se presento un error al actualizar la disponibilidad del grupo ' ||SQLERRM;
                                                END;

                                                BEGIN

                                                    UPDATE ssbsect SET ssbsect_census_enrl=ssbsect_enrl
                                                    WHERE 1 =  1
                                                    AND ssbsect_term_code = c.periodo
                                                    AND ssbsect_crn  = crn;

                                                EXCEPTION WHEN OTHERS THEN
                                                    vl_error := 'Se presento un error al actualizar el Censo del grupo ' ||SQLERRM;
                                                END;

                                                IF C.SGBSTDN_STYP_CODE = 'F' THEN

                                                    BEGIN

                                                        UPDATE sgbstdn a SET a.sgbstdn_styp_code ='N',
                                                                             a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                                             A.SGBSTDN_USER_ID =USER
                                                        WHERE 1 = 1
                                                        AND a.sgbstdn_pidm = c.pidm
                                                        AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                                       FROM sgbstdn a1
                                                                                       WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                                       AND a1.sgbstdn_program_1 = a.sgbstdn_program_1
                                                                                       )
                                                        AND a.sgbstdn_program_1 = c.prog;

                                                    EXCEPTION WHEN OTHERS THEN
                                                        vl_error := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
                                                    END;

                                                END IF;

                                               BEGIN

                                                   SELECT COUNT(*)
                                                   INTO l_cambio_estatus
                                                   FROM sfrstcr
                                                   WHERE 1 = 1
                                                   AND SFRSTCR_TERM_CODE||SFRSTCR_PTRM_CODE = c.periodo||c.parte
                                                   AND sfrstcr_pidm = c.pidm;

                                               EXCEPTION WHEN OTHERS THEN
                                                   l_cambio_estatus:=0;
                                               END;


                                               IF l_cambio_estatus > 0 THEN

                                                   IF C.SGBSTDN_STYP_CODE = 'N' THEN

                                                       BEGIN

                                                           UPDATE sgbstdn a SET a.sgbstdn_styp_code ='C',
                                                                                a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                                                A.SGBSTDN_USER_ID =USER
                                                           WHERE 1 = 1
                                                           AND a.sgbstdn_pidm = c.pidm
                                                           AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                                          FROM sgbstdn a1
                                                                                          WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                                          AND a1.sgbstdn_program_1 = a.sgbstdn_program_1
                                                                                          )
                                                           AND a.sgbstdn_program_1 = c.prog;

                                                       EXCEPTION WHEN OTHERS THEN
                                                           vl_error := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
                                                       END;

                                                    END IF;

                                               end if;

                                                f_inicio := NULL;

                                                BEGIN
                                                       SELECT DISTINCT sobptrm_start_date
                                                       INTO f_inicio
                                                       FROM sobptrm
                                                       WHERE sobptrm_term_code=c.periodo
                                                       AND  sobptrm_ptrm_code=c.parte;
                                                EXCEPTION WHEN OTHERS THEN
                                                   f_inicio := NULL;
                                                    vl_error := 'Se presento un error al Obtener la fecha de inicio de Clases  periodo '||c.periodo||' parte '||c.parte||' '||SQLERRM||' poe';
                                                    raise_application_error (-20002,vl_error);

                                                END;

                                                IF f_inicio IS NOT NULL THEN

                                                    BEGIN

                                                        UPDATE sorlcur SET sorlcur_start_date  = TRUNC(f_inicio)
                                                        WHERE 1 = 1
                                                        AND sorlcur_pidm = c.pidm
                                                        AND sorlcur_program = c.prog
                                                        AND sorlcur_lmod_code = 'LEARNER'
                                                        AND sorlcur_key_seqno = c.study;

                                                    EXCEPTION WHEN OTHERS THEN
                                                        vl_error := 'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur ' ||SQLERRM;
                                                    END;

                                                END IF;

                                                conta_ptrm:=0;

                                                BEGIN

                                                    SELECT COUNT (*)
                                                    INTO conta_ptrm
                                                    FROM sfrareg
                                                    WHERE 1 = 1
                                                    AND sfrareg_pidm = c.pidm
                                                    AND sfrareg_term_code = c.periodo
                                                    AND sfrareg_crn = crn
                                                    AND sfrareg_extension_number = 0
                                                    AND sfrareg_rsts_code = 'RE';

                                                EXCEPTION WHEN OTHERS THEN
                                                   conta_ptrm :=0;

                                                END;

                                                IF conta_ptrm = 0 THEN

                                                    BEGIN

                                                        INSERT INTO sfrareg VALUES(
                                                                                   c.pidm,
                                                                                   c.periodo,
                                                                                   crn ,
                                                                                   0,
                                                                                   'RE',
                                                                                   nvl(f_inicio,pn_fecha),
                                                                                   nvl(f_fin,sysdate),
                                                                                   'N',
                                                                                   'N',
                                                                                   SYSDATE,
                                                                                   USER,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   'PRONOSTICO',
                                                                                   SYSDATE,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL
                                                                                   );
                                                    EXCEPTION WHEN OTHERS THEN
                                                         vl_error := 'Se presento un error al insertar el registro de la materia para el alumno ' ||SQLERRM;
                                                    END;

                                                END IF;

                                                BEGIN
                                                    UPDATE SZTPRONO SET SZTPRONO_ENVIO_HORARIOS='S'
                                                    WHERE 1 = 1
                                                    AND SZTPRONO_NO_REGLA = p_regla
                                                    and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                    and SZTPRONO_ENVIO_HORARIOS='N'
                                                    AND SZTPRONO_PIDM = c.pidm
                                                    and sztprono_materia_legal = c.materia
                                                    AND SZTPRONO_PTRM_CODE =parte;


                                               EXCEPTION WHEN OTHERS THEN
                                                  NULL;
                                               END;

                                            EXCEPTION WHEN OTHERS THEN
                                                vl_error := 'Se presento un error al insertar al alumno en el grupo3 ' ||SQLERRM;
                                            END;

                                            dbms_output.put_line('mensaje1:'|| 'SE creo el grupo :=' ||crn);

                                        EXCEPTION WHEN OTHERS THEN
                                            vl_error := 'Se presento un Error al insertar el nuevo grupo 3 ' ||SQLERRM;
                                        END;

                                    END IF;

                                END IF;  ------ No hay  CRN Creado

                                IF vl_error = 'EXITO' THEN

                                    COMMIT; --Commit;
                                    --dbms_output.put_line('mensaje:'||vl_error);
                                    BEGIN

                                        INSERT INTO sztcarga VALUES (
                                                                     c.iden, --SZCARGA_ID
                                                                     c.materia, --SZCARGA_MATERIA
                                                                     c.prog,         --SZCARGA_PROGRAM
                                                                     c.periodo,         --SZCARGA_TERM_CODE
                                                                     c.parte,         --SZCARGA_PTRM_CODE
                                                                     c.grupo,         --SZCARGA_GRUPO
                                                                     NULL,         --SZCARGA_CALIF
                                                                     c.prof,         --SZCARGA_ID_PROF
                                                                     USER,         --SZCARGA_USER_ID
                                                                     SYSDATE,         --SZCARGA_ACTIVITY_DATE
                                                                     c.fecha_inicio,         --SZCARGA_FECHA_INI
                                                                     'P',          --SZCARGA_ESTATUS
                                                                     'Horario Generado' ,  --SZCARGA_OBSERVACIONES
                                                                     'PRONOSTICO',
                                                                     p_regla
                                                                     );
                                    EXCEPTION WHEN DUP_VAL_ON_INDEX THEN

                                        BEGIN

                                            UPDATE sztcarga set szcarga_estatus = 'P' ,
                                                                szcarga_observaciones =  'Horario Generado',
                                                                szcarga_activity_date = sysdate
                                            Where 1 = 1
                                            AND SZCARGA_ID = c.iden
                                            and SZCARGA_MATERIA = c.materia
                                            AND SZTCARGA_TIPO_PROC = 'MATE'
                                            and trunc (SZCARGA_FECHA_INI) = c.fecha_inicio;

                                        EXCEPTION WHEN OTHERS THEN
                                          VL_ERROR := 'Se presento un Error al Actualizar la bitacora '||SQLERRM;
                                        END;

                                    WHEN OTHERS THEN

                                        vl_error := 'Se presento un Error al insertar la bitacora '||SQLERRM;

                                    END;

                                ELSE

                                    dbms_output.put_line('mensaje:'||vl_error);

                                    ROLLBACK;

                                    Begin

                                        INSERT INTO sztcarga VALUES (c.iden, --SZCARGA_ID
                                                                     c.materia, --SZCARGA_MATERIA
                                                                     c.prog,         --SZCARGA_PROGRAM
                                                                     c.periodo,         --SZCARGA_TERM_CODE
                                                                     c.parte,         --SZCARGA_PTRM_CODE
                                                                     c.grupo,         --SZCARGA_GRUPO
                                                                     null,         --SZCARGA_CALIF
                                                                     c.prof,         --SZCARGA_ID_PROF
                                                                     user,         --SZCARGA_USER_ID
                                                                     sysdate,         --SZCARGA_ACTIVITY_DATE
                                                                     c.fecha_inicio,         --SZCARGA_FECHA_INI
                                                                     'E',          --SZCARGA_ESTATUS
                                                                     vl_error,  --SZCARGA_OBSERVACIONES
                                                                     'PRONOSTICO',
                                                                     p_regla
                                                                     );
                                        commit;

                                    EXCEPTION  WHEN DUP_VAL_ON_INDEX THEN

                                        BEGIN
                                          UPDATE sztcarga SET szcarga_estatus = 'E' ,
                                                              szcarga_observaciones = vl_error,
                                                              szcarga_activity_date = SYSDATE
                                          WHERE 1 = 1
                                          AND szcarga_id = c.iden
                                          AND szcarga_materia = c.materia
                                          AND sztcarga_tipo_proc = 'MATE'
                                          AND trunc (szcarga_fecha_ini) = c.fecha_inicio;

                                        EXCEPTION WHEN OTHERS THEN
                                          vl_error := 'Se presento un Error al Actualizar la bitacora de Error '||SQLERRM;
                                        END;
                                    WHEN OTHERS THEN
                                        vl_error := 'Se presento un Error al insertar la bitacora de Error '||SQLERRM;
                                    END;


                                End if;

                            Else



                               vl_error := 'El alumno ya tiene la materia Inscritas en el Periodo:'||period_cur||'. Parte-periodo:'||parteper_cur;

                               Begin

                                     UPDATE sztprono SET
                                                         --SZTPRONO_ESTATUS_ERROR ='S',
                                                         SZTPRONO_DESCRIPCION_ERROR=vl_error
                                                         --SZTPRONO_ENVIO_HORARIOS ='S'

                                     WHERE 1 = 1
                                     AND SZTPRONO_MATERIA_LEGAL = c.materia
                                     AND TRUNC (SZTPRONO_FECHA_INICIO) = c.fecha_inicio
                                     AND SZTPRONO_NO_REGLA=P_REGLA
                                     AND SZTPRONO_pIDm=c.pidm;

                                EXCEPTION WHEN OTHERS THEN
                                   dbms_output.put_line(' Error al actualizar '||sqlerrm);
                                END;

                               commit;

                               raise_application_error (-20002,vl_error);

                                BEGIN

                                    INSERT INTO sztcarga VALUES (c.iden, --SZCARGA_ID
                                                                 c.materia, --SZCARGA_MATERIA
                                                                 c.prog,         --SZCARGA_PROGRAM
                                                                 c.periodo,         --SZCARGA_TERM_CODE
                                                                 c.parte,         --SZCARGA_PTRM_CODE
                                                                 c.grupo,         --SZCARGA_GRUPO
                                                                 null,         --SZCARGA_CALIF
                                                                 c.prof,         --SZCARGA_ID_PROF
                                                                 user,         --SZCARGA_USER_ID
                                                                 sysdate,         --SZCARGA_ACTIVITY_DATE
                                                                 c.fecha_inicio,         --SZCARGA_FECHA_INI
                                                                 'A',--'P',          --SZCARGA_ESTATUS
                                                                 vl_error,  --SZCARGA_OBSERVACIONES
                                                                 'PRONOSTICO',
                                                                 p_regla
                                                                 );
                                    COMMIT;

                                EXCEPTION WHEN DUP_VAL_ON_INDEX THEN

                                    BEGIN

                                      UPDATE sztcarga SET szcarga_estatus = 'A',--'P' ,
                                                          szcarga_observaciones =  vl_error,
                                                          szcarga_activity_date = SYSDATE
                                      WHERE 1 = 1
                                      AND szcarga_id = c.iden
                                      AND szcarga_materia = c.materia
                                      AND sztcarga_tipo_proc = 'MATE'
                                      AND TRUNC(szcarga_fecha_ini) = c.fecha_inicio;

                                    EXCEPTION WHEN OTHERS THEN
                                      vl_error := 'Se presento un Error al Actualizar la bitacora de Error '||SQLERRM;
                                    END;

                                WHEN OTHERS THEN
                                    vl_error := 'Se presento un Error al insertar la bitacora de Error '||SQLERRM;
                                END;

                            END IF; ----> El alumno ya tiene inscrita la materia

                        ELSE

                              begin

                                  SELECT DECODE(c.sgbstdn_stst_code,'BT','BAJA TEMPORAL','BD','BAJA TEMPORAL','BI', 'BAJA POR INACTIVIDAD','CV', 'CANCELACIÓN DE VENTA','CM','CANCELACIÓN DE MATRÍCULA','CC', 'CAMBIO DE CILO','CF','CAMBIO DE FECHA','CP','CAMBIO DE PROGRAMA','EG','EGRESADO')
                                  INTO L_DESCRIPCION_ERROR
                                  FROM DUAL;

                              exception when others then
                                  l_descripcion_error:='Sin descripcion';
                              end;

                              if L_DESCRIPCION_ERROR is null then

                                L_DESCRIPCION_ERROR:=c.sgbstdn_stst_code;

                              end if;


                              Begin

                                   UPDATE sztprono SET SZTPRONO_ESTATUS_ERROR ='S',
                                                       SZTPRONO_DESCRIPCION_ERROR=L_DESCRIPCION_ERROR

                                   WHERE 1 = 1
                                   AND SZTPRONO_MATERIA_LEGAL = c.materia
                                   AND TRUNC (SZTPRONO_FECHA_INICIO) = c.fecha_inicio
                                   AND SZTPRONO_NO_REGLA=P_REGLA
                                   AND SZTPRONO_PIDM=c.pidm;

                              EXCEPTION WHEN OTHERS THEN
                                 dbms_output.put_line(' Error al actualizar '||sqlerrm);
                              END;


                            vl_error := 'Estatus no vÃ?Â¡lido para realizar la carga: '||C.SGBSTDN_STST_CODE;

                            BEGIN

                                INSERT INTO sztcarga VALUES (c.iden, --SZCARGA_ID
                                                             c.materia, --SZCARGA_MATERIA
                                                             c.prog,         --SZCARGA_PROGRAM
                                                             c.periodo,         --SZCARGA_TERM_CODE
                                                             c.parte,         --SZCARGA_PTRM_CODE
                                                             c.grupo,         --SZCARGA_GRUPO
                                                             null,         --SZCARGA_CALIF
                                                             c.prof,         --SZCARGA_ID_PROF
                                                             user,         --SZCARGA_USER_ID
                                                             sysdate,         --SZCARGA_ACTIVITY_DATE
                                                             c.fecha_inicio,         --SZCARGA_FECHA_INI
                                                             'A',--'P',          --SZCARGA_ESTATUS
                                                             vl_error,  --SZCARGA_OBSERVACIONES
                                                             'PRONOSTICO',
                                                             p_regla
                                                             );
                                COMMIT;

                            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN

                                Begin

                                  UPDATE sztcarga SET szcarga_estatus = 'A',--'P' ,
                                                      szcarga_observaciones =  vl_error,
                                                      szcarga_activity_date = sysdate
                                  WHERE 1 = 1
                                  AND szcarga_id      = c.iden
                                  AND szcarga_materia = c.materia
                                  AND sztcarga_tipo_proc = 'MATE'
                                  AND TRUNC (szcarga_fecha_ini) = c.fecha_inicio;

                                EXCEPTION WHEN OTHERS THEN
                                  vl_error := 'Se presento un Error al Actualizar la bitacora de Error '||SQLERRM;
                                END;

                            WHEN OTHERS THEN
                                vl_error := 'Se presento un Error al insertar la bitacora de Error '||SQLERRM;
                            END;

                             raise_application_error (-20002,'Este alumno '||c.iden||' se encuentra con '||l_descripcion_error);

                        END IF;

                --end if;

          END LOOP;

                    COMMIT;

                    FOR X IN c_no_proce LOOP

                        vl_error := 'Materia no Registrada para el Alumno en SFAREGS';

                        BEGIN

                            INSERT INTO sztcarga VALUES (
                                                         x.szcarga_id, --szcaRGA_ID
                                                         x.szcarga_materia, --SZCARGA_MATERIA
                                                         x.szcarga_program,         --SZCARGA_PROGRAM
                                                         x.szcarga_term_code,         --SZCARGA_TERM_CODE
                                                         x.szcarga_ptrm_code,         --SZCARGA_PTRM_CODE
                                                         x.szcarga_grupo,         --SZCARGA_GRUPO
                                                         x.szcarga_calif,         --SZCARGA_CALIF
                                                         x.szcarga_id_prof,         --SZCARGA_ID_PROF
                                                         USER,         --SZCARGA_USER_ID
                                                         SYSDATE,         --SZCARGA_ACTIVITY_DATE
                                                         x.szcarga_fecha_ini,         --SZCARGA_FECHA_INI
                                                         'E',          --SZCARGA_ESTATUS
                                                         vl_error,  --SZCARGA_OBSERVACIONES
                                                         'PRONOSTICO '||p_regla,
                                                         p_regla
                                                         );
                            commit;

                        EXCEPTION WHEN DUP_VAL_ON_INDEX THEN

                             BEGIN

                                 UPDATE sztcarga SET szcarga_estatus = 'E',
                                                     szcarga_calif=x.szcarga_calif,
                                                     szcarga_observaciones =  vl_error,
                                                     szcarga_activity_date = SYSDATE
                                 WHERE 1 = 1
                                 AND szcarga_id = x.szcarga_id
                                 AND szcarga_materia = x.szcarga_materia
                                 AND sztcarga_tipo_proc = 'MATE'
                                 AND TRUNC (szcarga_fecha_ini) = x.szcarga_fecha_ini;

                             EXCEPTION WHEN OTHERS THEN
                               vl_error := 'Se presento un Error al Actualizar la bitacora de Error '||SQLERRM;
                             END;

                        WHEN OTHERS THEN
                            vl_error := 'Se presento un Error al insertar la bitacora de Error '||SQLERRM;
                        END;


                        begin

                            UPDATE SZTPRONO SET SZTPRONO_ESTATUS_ERROR ='S',
                                                SZTPRONO_DESCRIPCION_ERROR ='Esta materia no va acorde a la seriacion de SMAPROG con el programa '||x.szcarga_program
                            where 1 = 1
                            and sztprono_no_regla = p_regla
                            and sztprono_materia_legal = x.szcarga_materia
                            and sztprono_id =   x.szcarga_id
                            and SZTPRONO_FECHA_INICIO =  x.szcarga_fecha_ini;

                        exception when others then
                            null;
                        end;

                    END LOOP;

                    COMMIT;

                    --raise_application_error (-20002,vl_error);
                         ------------------- Realiza el proceso de actualizacion de Jornadas  ----------------------------------

                    BEGIN

                        FOR c IN (
                                   SELECT sorlcur_levl_code nivel,
                                          szcarga_id,
                                          szcarga_term_code,
                                          szcarga_ptrm_code,
                                          spriden_pidm ,
                                          sorlcur_key_seqno,
                                          COUNT (*) numero
                                   FROM sztcarga,
                                        spriden,
                                        sorlcur  s
                                   WHERE 1 = 1
                                   AND sztcarga_tipo_proc = 'MATE'
                                   AND szcarga_estatus != 'E'
                                   AND szcarga_id = spriden_id
                                   AND s.sorlcur_pidm = spriden_pidm
                                   AND s.sorlcur_program=szcarga_program
                                   AND s.sorlcur_lmod_code='LEARNER'
                                   AND s.sorlcur_seqno in (SELECT MAX(ss.sorlcur_seqno)
                                                           FROM sorlcur ss
                                                           WHERE 1 = 1
                                                           AND s.sorlcur_pidm=ss.sorlcur_pidm
                                                           AND s.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                           AND s.sorlcur_program=ss.sorlcur_program
                                                           )
                                   GROUP BY sorlcur_levl_code,
                                            szcarga_id,
                                            szcarga_term_code,
                                            szcarga_ptrm_code,
                                            spriden_pidm,
                                            sorlcur_key_seqno
                                   ORDER BY 1, 2, 3
                       ) loop

                          vl_jornada := null;



                           BEGIN

                               SELECT DISTINCT SUBSTR (sgrsatt_atts_code, 1,3) jornada
                               INTO vl_jornada
                               FROM sgrsatt a
                               WHERE 1 = 1
                               AND a.sgrsatt_pidm = c.spriden_pidm
                               AND a.sgrsatt_stsp_key_sequence = c.sorlcur_key_seqno
                               AND SUBSTR(a.sgrsatt_atts_code,2,1) = SUBSTR(c.nivel,1,1)
                               AND REGEXP_LIKE(a.sgrsatt_atts_code, '^[0-9]')
                               AND a.sgrsatt_term_code_eff = (SELECT MAX (a1.sgrsatt_term_code_eff)
                                                              FROM SGRSATT a1
                                                              WHERE 1 = 1
                                                              AND a.sgrsatt_pidm = a1.sgrsatt_pidm
                                                              AND a.sgrsatt_stsp_key_sequence = a1.sgrsatt_stsp_key_sequence
                                                              );
                           EXCEPTION  WHEN OTHERS THEN
                                vl_jornada :=NULL;
                           END ;

                           IF vl_jornada  IS NOT NULL  THEN

                                 if c.numero >= 10 then

                                    c.numero:=4;

                                end if;

                                vl_jornada := vl_jornada||c.numero;

                                BEGIN

                                    pkg_algoritmo.p_actualiza_jornada (c.spriden_pidm, c.szcarga_term_code, vl_jornada, c.sorlcur_key_seqno);

                                EXCEPTION WHEN OTHERS THEN
                                    null;
                                END;

                           END IF;



                       END LOOP;

                       COMMIT;

                    END;

        end if;


        COMMIT;

        pkg_algoritmo.P_ENA_DIS_TRG('E','SATURN.SZT_SSBSECT_POSTINSERT_ROW');
        pkg_algoritmo.P_ENA_DIS_TRG('E','SATURN.SZT_SIRASGN_POSTINSERT_ROW');
        pkg_algoritmo.P_ENA_DIS_TRG('E','SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');


   END;
--
--
     PROCEDURE P_INSERTA_CARGA(P_REGLA NUMBER,pn_fecha VARCHAR2)
    IS

    l_prof_id  VARCHAR2(100);

    BEGIN



        BEGIN
             DELETE SZCARGA
             WHERE 1 = 1
             AND SZCARGA_NO_REGLA=p_regla
             and SZCARGA_FECHA_INI = pn_fecha;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

        BEGIN
            DELETE SZTCARGA
            WHERE 1 = 1
            AND SZTCARGA_NO_REGLA=p_regla
             and SZCARGA_FECHA_INI = pn_fecha;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

       --  si ya tiene las materias sembradas se actualiza antes para que no se tomen en cuenta en el proceso

        FOR c_prono IN(

                            select id_alumno,
                                   pidm_alumno,
                                   periodo,
                                   programa,
                                   parte_periodo,
                                   mat_prono,
                                   longitud,
                                   grupo2,
                                   substr(grupo2,longitud,2) grupo,
                                   fecha_inicio,
                                   regla,
                                   banner
                            from
                            (
                                select  distinct ono.sztprono_id id_alumno,
                                                ono.sztprono_pidm pidm_alumno,
                                                ono.SZTPRONO_TERM_CODE periodo,
                                                SZTPRONO_PROGRAM programa,
                                                ono.SZTPRONO_PTRM_CODE parte_periodo,
                                                ono.SZTPRONO_MATERIA_LEGAL mat_prono,
                                                length(SZSTUME_SUBJ_CODE)+1 longitud,
                                                ume.SZSTUME_TERM_NRC grupo2,
                                                SZTPRONO_FECHA_INICIO fecha_inicio,
                                                sztprono_no_regla regla,
                                                sztprono_materia_banner banner
                                from SZSTUME ume,
                                     sztprono ono
                                where 1  = 1
                                and ono.sztprono_no_regla =ume.SZSTUME_NO_REGLA(+)
                                and ono.sztprono_pidm = ume.SZSTUME_pidm(+)
                                and ono.SZTPRONO_MATERIA_LEGAL = ume.SZSTUME_SUBJ_CODE(+)
                                and ono.SZTPRONO_FECHA_INICIO= ume.SZSTUME_START_DATE (+)
                                AND ono.SZTPRONO_FECHA_INICIO = pn_fecha
                                and ono.SZTPRONO_ENVIO_HORARIOS ='N'
                                and ono.SZTPRONO_ENVIO_MOODL ='S'
--                                and ono.sztprono_id ='010097868'
                                and ono.sztprono_no_regla  = p_regla
                                and SZTPRONO_ESTATUS_ERROR ='N'
-- se quito por que para abcc no se puede espera a sincronizar            AND ume.szstume_stat_ind = '1'
                                )

                            )
                            loop

                                dbms_output.put_line('Entra a carga');

                                begin
                                    select (SELECT SPRIDEN_ID
                                            FROM SPRIDEN
                                            WHERE 1 = 1
                                            AND SPRIDEN_PIDM = nme.SZSGNME_PIDM
                                            AND SPRIDEN_CHANGE_IND IS NULL) MATRICULA
                                    into l_prof_id
                                    from SZSGNME nme
                                    where 1 = 1
                                    and SZSGNME_no_regla = c_prono.regla
                                    and SZSGNME_TERM_NRC = c_prono.grupo2
                                    and rownum = 1;
                                exception when others then
                                    null;
                                end;


                                begin

                                    INSERT INTO SZCARGA values(
                                                                c_prono.id_alumno,
                                                                c_prono.mat_prono,
                                                                c_prono.programa,
                                                                c_prono.periodo,
                                                                c_prono.parte_periodo,
                                                                c_prono.grupo,
                                                                null,
                                                                l_prof_id,
                                                                USER,
                                                                SYSDATE,
                                                                c_prono.fecha_inicio,
                                                                P_REGLA,
                                                                c_prono.banner
                                                                );
                                exception when others then
                                   -- raise_application_error (-20002,'ERROR al insertar en carga matricula  '||c_prono.id_alumno||' error '||sqlerrm);
                                   null;
                                end;

                            end loop;


                commit;

    END P_INSERTA_CARGA;
--
--
    function f_baja_abcc(
                        p_estatus varchar2,
                        p_pidm    number
                        )RETURN   varchar2
        is
        l_programa          varchar2(20);
        l_sp                number;
        l_retorna           varchar2(500):='EXITO';
        l_fecha_inicio_sor  date;
        l_matricula         varchar2(10);
        l_campus            varchar2(5);
        l_nivel             varchar2(5);
        l_periodo           varchar2(10);
        l_regla             number;
        l_materias_re       number;
        l_materias_dd       number;
        l_secuen_max        number;
        l_estatus           varchar2(10);
        l_contar_horario    number;


    BEGIN

        l_matricula:=f_matricula(p_pidm);

        BEGIN

           SELECT DISTINCT sorlcur_program,
                           cur.sorlcur_key_seqno,
                           sorlcur_start_date,
                           sorlcur_camp_code,
                           sorlcur_levl_code,
                           sorlcur_term_code
           INTO l_programa,
                l_sp,
                l_fecha_inicio_sor,
                l_campus,
                l_nivel,
                l_periodo
           FROM sorlcur cur
           WHERE     1 = 1
           AND cur.sorlcur_pidm = p_pidm
--           AND cur.sorlcur_lmod_code = 'LEARNER'
--           AND cur.sorlcur_roll_ind = 'Y'
--           AND cur.sorlcur_cact_code = 'ACTIVE'
           AND cur.sorlcur_seqno =
                                  (SELECT MAX (aa1.sorlcur_seqno)
                                   FROM sorlcur aa1
                                   WHERE     cur.sorlcur_pidm = aa1.sorlcur_pidm
--                                   AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
--                                   AND cur.sorlcur_roll_ind = aa1.sorlcur_roll_ind
--                                   AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code
                                   );

        EXCEPTION WHEN OTHERS THEN
              l_retorna:='No se puede obtener la fecha de inicio para esta matricula '||l_matricula||' '||sqlerrm;
        END;

        dbms_output.put_line('Estar date '||l_fecha_inicio_sor||' matricula '||l_matricula);


        l_estatus:= p_estatus;

        IF l_estatus in ('BI','BA') then

            l_estatus:='BT';


        end if;


        IF l_estatus IN ('BI','BT','BD','CV') then

               BEGIN

                BANINST1.PKG_JORNADAS_ABCC.P_INANTIVA_TZTCOTA (p_estatus,p_pidm );
                COMMIT;

             END;

            dbms_output.put_line('entra 1 4409');

            begin

                SELECT count(*)
                into l_contar_horario
                FROM ssbsect ,
                     sfrstcr
                WHERE 1 = 1
                AND ssbsect_term_code = sfrstcr_term_code
                AND ssbsect_crn = sfrstcr_crn
                AND ssbsect_ptrm_start_date =l_fecha_inicio_sor
                AND sfrstcr_grde_code is  null
                AND substr(ssbsect_term_code,5,1) not in (8,9)
                AND sfrstcr_pidm = p_pidm;

            exception when others then
                null;
            end;

            dbms_output.put_line('Horario '||l_contar_horario);

            if l_contar_horario > 0 then

                    FOR C IN (SELECT ssbsect_crn crn,
                                     ssbsect_term_code term_code,
                                     sfrstcr_ptrm_code ptrm,
                                     sfrstcr_pidm pidm
                              FROM ssbsect ,
                                   sfrstcr
                              WHERE 1 = 1
                              AND ssbsect_term_code = sfrstcr_term_code
                              AND ssbsect_crn = sfrstcr_crn
                              AND ssbsect_ptrm_start_date =l_fecha_inicio_sor
                              AND sfrstcr_grde_code is  null
                              AND substr(ssbsect_term_code,5,1) not in (8,9)
        --                      AND sfrstcr_rsts_code ='RE'
                              AND sfrstcr_pidm = p_pidm
                              )
                              LOOP




                                 dbms_output.put_line('Entra a horario');

                                  BEGIN

                                    UPDATE SFRSTCR SET sfrstcr_rsts_code ='DD',
                                                       SFRSTCR_USER_ID = user,
                                                       SFRSTCR_DATA_ORIGIN ='BAJA SOLICITADA POR COBRANZA',
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


                                  IF l_retorna = 'EXITO' then

                                    FOR d IN (
                                              select *
                                              from sztprono
                                              where 1 = 1
                                              and SZTPRONO_PTRM_CODE = c.ptrm
                                              and SZTPRONO_TERM_CODE = c.term_code
                                              and sztprono_pidm = c.pidm
                                              and exists (select null
                                                            from szstume
                                                            where 1 = 1
                                                            and szstume_no_regla = sztprono_no_regla
                                                            and szstume_subj_code = sztprono_materia_legal
                                                            and szstume_pidm = sztprono_pidm
                                                            AND SZSTUME_STAT_IND = '1'
                                                            )
        --                                      AND sztprono_envio_horarios ='S'
                                              )loop

                                                      dbms_output.put_line('Entra a prono ');

                                                      BEGIN

                                                        SELECT COUNT(*)
                                                        INTO l_materias_re
                                                        FROM szstume
                                                        WHERE 1 = 1
                                                        AND szstume_pidm = d.sztprono_pidm
                                                        AND szstume_no_regla = d.sztprono_no_regla
                                                        AND SZSTUME_SUBJ_CODE_COMP =d.sztprono_materia_legal
                                                        and SZSTUME_RSTS_CODE ='RE';

                                                      EXCEPTION WHEN OTHERS THEN
                                                            NULL;
                                                      END;

                                                      BEGIN

                                                        SELECT COUNT(*)
                                                        INTO l_materias_dd
                                                        FROM szstume
                                                        WHERE 1 = 1
                                                        AND szstume_pidm = d.sztprono_pidm
                                                        AND szstume_no_regla = d.sztprono_no_regla
                                                        AND SZSTUME_SUBJ_CODE_COMP =d.sztprono_materia_legal
                                                        and SZSTUME_RSTS_CODE ='DD';

                                                      EXCEPTION WHEN OTHERS THEN
                                                            NULL;
                                                      END;

                                                      if l_materias_re = 1 and l_materias_dd = 0 then

                                                             for x in (select *
                                                                       from szstume
                                                                       where 1= 1
                                                                       and szstume_no_regla = d.sztprono_no_regla
                                                                       and szstume_subj_code_comp =d.sztprono_materia_legal
                                                                       and szstume_id = d.sztprono_id
                                                                       )
                                                                       loop

                                                                                dbms_output.put_line('Entra a szstume ');

                                                                                dbms_output.put_line('Estar date '||l_fecha_inicio_sor||' matricula '||l_matricula||' crn '||c.crn||' pperiodo '||c.ptrm||' term code '||c.term_code||' grupo '||x.szstume_term_nrc||' REGLA '||d.sztprono_no_regla);

                                                                                 --dbms_output.put_line('Entra a cursor x  ');

                                                                                BEGIN

                                                                                    SELECT MAX(NVL(szstume_seq_no,0))+1
                                                                                    INTO l_secuen_max
                                                                                    FROM szstume
                                                                                    WHERE 1 = 1
                                                                                    AND szstume_no_regla = d.sztprono_no_regla
                                                                                    and szstume_pidm = x.szstume_pidm
                                                                                    AND szstume_subj_code_comp  = d.sztprono_materia_legal
                                                                                    AND szstume_term_nrc =x.szstume_term_nrc ;

                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                    --l_retorna:='No se encontro secuencia maxima '||sqlerrm;
                                                                                    null;
                                                                                END;

                                                                                BEGIN

                                                                                   INSERT INTO szstume VALUES(x.szstume_term_nrc,
                                                                                                               x.szstume_pidm,
                                                                                                               x.szstume_id,
                                                                                                               SYSDATE,
                                                                                                               USER,
                                                                                                               0,
                                                                                                               'BAJAS ABCC',
                                                                                                               X.SZSTUME_PWD,
                                                                                                               NULL,
                                                                                                               l_secuen_max,
                                                                                                               'DD',
                                                                                                               NULL,
                                                                                                               x.szstume_subj_code_comp,
                                                                                                               NULL,-- c.nivel,
                                                                                                               NULL,
                                                                                                               NULL,--  c.ptrm,
                                                                                                               NULL,
                                                                                                               NULL,
                                                                                                               NULL,
                                                                                                               NULL,
                                                                                                               x.szstume_subj_code_comp,
                                                                                                               d.sztprono_fecha_inicio,--  c.inicio_clases,
                                                                                                               d.sztprono_no_regla,
                                                                                                               NULL,
                                                                                                               1,
                                                                                                               0,
                                                                                                               null
                                                                                                               );
                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                   l_retorna:='No se pudo insertar en szstume '||sqlerrm;
                                                                                END;

                                                                                dbms_output.put_line('Inerto baja  ');

                                                                                if l_retorna ='EXITO' then

                                                                                    BEGIN

                                                                                        UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                                                            sztprono_envio_horarios ='N',
                                                                                                            sztprono_descripcion_error ='BAJA SOLICITADA POR COBRANZA'
                                                                                        WHERE 1 = 1
                                                                                        AND sztprono_materia_legal = x.szstume_subj_code_comp
                                                                                        AND sztprono_pidm = x.szstume_pidm
                                                                                        AND sztprono_no_regla = d.sztprono_no_regla
                                                                                        AND sztprono_fecha_inicio =d.sztprono_fecha_inicio;

                                                                                    EXCEPTION WHEN OTHERS THEN
                                                                                        l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
                                                                                    END;

                                                                                end if;



                                                                       end loop;


                                                      end if;


                                              end loop;

                                  else

                                    rollback;

                                  end if;



                              END LOOP;

            else

                null;

--                begin
--
--                    select distinct sztprono_no_regla
--                    into l_regla
--                    from sztprono no1
--                    where 1 = 1
--                    and sztprono_pidm = p_pidm
--                    and sztprono_no_regla = (select max(sztprono_no_regla)
--                                             from sztprono no2
--                                             where 1 = 1
--                                             and no2.sztprono_pidm = no1.sztprono_pidm
--                                             and exists (select null
--                                                         from szstume
--                                                         where 1 = 1
--                                                         and szstume_pidm = no2.sztprono_pidm
--                                                         and szstume_no_regla = no2.sztprono_no_regla)
--                                             ) ;
--
--
--                exception when others then
--                    null;
--                end;
--
--                 for c in (
--                            select distinct SZTPRONO_ID,
--                                            sztprono_no_regla,
--                                           sztprono_materia_legal,
--                                           sztprono_fecha_inicio,
--                                              get_crn_regla(ono.sztprono_pidm,
--                                                               null,
--                                                               ono.sztprono_materia_legal,
--                                                               ono.sztprono_no_regla
--                                                               )crn,
--                                            sztprono_pidm pidm
--                            from sztprono ono
--                            where 1 = 1
--                            and SZTPRONO_FECHA_INICIO = l_fecha_inicio_sor
--                            --and SZTPRONO_DESCRIPCION_ERROR like '%VENTA%'
--                            and sztprono_pidm = p_pidm
--                            union
--                            select distinct SZTPRONO_ID,
--                                            sztprono_no_regla,
--                                           sztprono_materia_legal,
--                                           sztprono_fecha_inicio,
--                                              get_crn_regla(ono.sztprono_pidm,
--                                                               null,
--                                                               ono.sztprono_materia_legal,
--                                                               ono.sztprono_no_regla
--                                                               )crn,
--                                            sztprono_pidm pidm
--                            from sztprono ono
--                            where 1 = 1
--                            and sztprono_no_regla = l_regla
--                            and sztprono_pidm = p_pidm
--                            order by 2
--                            )
--                            loop
--
--
--                                for x in (select *
--                                          from szstume
--                                          where 1= 1
--                                          and szstume_no_regla = c.sztprono_no_regla
--                                          and szstume_subj_code_comp =c.sztprono_materia_legal
--                                          and szstume_id = c.sztprono_id
--                                          )
--                                          loop
--
--                                                   dbms_output.put_line('Entra a szstume ');
--
--                                                --   dbms_output.put_line('Estar date '||l_fecha_inicio_sor||' matricula '||l_matricula||' crn '||c.crn||' pperiodo '||c.ptrm||' term code '||c.term_code||' grupo '||x.szstume_term_nrc||' REGLA '||d.sztprono_no_regla);
--
--                                                    --dbms_output.put_line('Entra a cursor x  ');
--
--                                                   BEGIN
--
--                                                       SELECT MAX(NVL(szstume_seq_no,0))+1
--                                                       INTO l_secuen_max
--                                                       FROM szstume
--                                                       WHERE 1 = 1
--                                                       AND szstume_no_regla = c.sztprono_no_regla
--                                                       and szstume_pidm = x.szstume_pidm
--                                                       AND szstume_subj_code_comp  = c.sztprono_materia_legal
--                                                       AND szstume_term_nrc =x.szstume_term_nrc ;
--
--                                                   EXCEPTION WHEN OTHERS THEN
--                                                       --l_retorna:='No se encontro secuencia maxima '||sqlerrm;
--                                                       null;
--                                                   END;
--
--                                                   BEGIN
--
--                                                      INSERT INTO szstume VALUES(x.szstume_term_nrc,
--                                                                                  x.szstume_pidm,
--                                                                                  x.szstume_id,
--                                                                                  SYSDATE,
--                                                                                  USER,
--                                                                                  0,
--                                                                                  'BAJAS ABCC',
--                                                                                  X.SZSTUME_PWD,
--                                                                                  NULL,
--                                                                                  l_secuen_max,
--                                                                                  'DD',
--                                                                                  NULL,
--                                                                                  x.szstume_subj_code_comp,
--                                                                                  NULL,-- c.nivel,
--                                                                                  NULL,
--                                                                                  NULL,--  c.ptrm,
--                                                                                  NULL,
--                                                                                  NULL,
--                                                                                  NULL,
--                                                                                  NULL,
--                                                                                  x.szstume_subj_code_comp,
--                                                                                  c.sztprono_fecha_inicio,--  c.inicio_clases,
--                                                                                  c.sztprono_no_regla,
--                                                                                  NULL
--                                                                                  );
--                                                   EXCEPTION WHEN OTHERS THEN
--                                                      l_retorna:='No se pudo insertar en szstume '||sqlerrm;
--                                                   END;
--
--                                                   dbms_output.put_line('Inerto baja  ');
--
--                                                   if l_retorna ='EXITO' then
--
--                                                       BEGIN
--
--                                                           UPDATE sztprono SET sztprono_estatus_error ='S',
--                                                                               sztprono_envio_horarios ='N',
--                                                                               sztprono_descripcion_error ='Baja desde Abcc'
--                                                           WHERE 1 = 1
--                                                           AND sztprono_materia_legal = x.szstume_subj_code_comp
--                                                           AND sztprono_pidm = x.szstume_pidm
--                                                           AND sztprono_no_regla = c.sztprono_no_regla
--                                                           AND sztprono_fecha_inicio =c.sztprono_fecha_inicio;
--
--                                                       EXCEPTION WHEN OTHERS THEN
--                                                           l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
--                                                       END;
--
--                                                   end if;
--
--
--
--                                          end loop;
--
--
--
--                            end loop;


            end if;


        end if;

        if l_retorna ='EXITO' then

            commit;
        else

            rollback;


        end if;


        RETURN(l_retorna);

    END;
--
--
 FUNCTION f_baja_abcc_cciclo(
                                    p_estatus varchar2,
                                    p_fecha_inicio date,
                                    p_pidm    number
                                    )RETURN   varchar2
        is
        l_programa          varchar2(20);
        l_sp                number;
        l_retorna           varchar2(500):='EXITO';
        l_fecha_inicio_sor  date;
        l_matricula         varchar2(10);
        l_campus            varchar2(5);
        l_nivel             varchar2(5);
        l_periodo           varchar2(10);
        l_regla             number;
        l_materias_re       number;
        l_materias_dd       number;
        l_secuen_max        number;
        l_estatus           varchar2(10);
        l_contar_horario    number;
        l_acredita          varchar2(1);
        VL_FECHA_BAJA   DATE ;

    BEGIN

        l_matricula:=f_matricula(p_pidm);

        BEGIN

           SELECT DISTINCT sorlcur_program,
                           cur.sorlcur_key_seqno,
                           sorlcur_start_date,
                           sorlcur_camp_code,
                           sorlcur_levl_code,
                           sorlcur_term_code
           INTO l_programa,
                l_sp,
                l_fecha_inicio_sor,
                l_campus,
                l_nivel,
                l_periodo
           FROM sorlcur cur
           WHERE     1 = 1
           AND cur.sorlcur_pidm = p_pidm
--           AND cur.sorlcur_lmod_code = 'LEARNER'
--           AND cur.sorlcur_roll_ind = 'Y'
--           AND cur.sorlcur_cact_code = 'ACTIVE'
           AND cur.sorlcur_seqno =
                                  (SELECT MAX (aa1.sorlcur_seqno)
                                   FROM sorlcur aa1
                                   WHERE     cur.sorlcur_pidm = aa1.sorlcur_pidm
--                                   AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
--                                   AND cur.sorlcur_roll_ind = aa1.sorlcur_roll_ind
--                                   AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code
                                   );

        EXCEPTION WHEN OTHERS THEN
              l_retorna:='No se puede obtener la fecha de inicio para esta matricula '||l_matricula||' '||sqlerrm;
        END;

        dbms_output.put_line('Estar date '||l_fecha_inicio_sor||' matricula '||l_matricula);


        l_estatus:= p_estatus;

        IF  l_estatus in ('BI','BA') then

            l_estatus:='BT';


        end if;


        IF l_estatus IN ('BI','BT','BD','CV') then

             BEGIN

                BANINST1.PKG_JORNADAS_ABCC.P_INANTIVA_TZTCOTA (p_estatus,p_pidm );
                COMMIT;

             END;

            dbms_output.put_line('entra 1 4409');

            begin

                SELECT count(*)
                into l_contar_horario
                FROM ssbsect ,
                     sfrstcr
                WHERE 1 = 1
                AND ssbsect_term_code = sfrstcr_term_code
                AND ssbsect_crn = sfrstcr_crn
                AND ssbsect_ptrm_start_date =l_fecha_inicio_sor
                AND sfrstcr_grde_code is  null
                AND substr(ssbsect_term_code,5,1) not in (8,9)
                AND sfrstcr_pidm = p_pidm;

            exception when others then
                null;
            end;

            dbms_output.put_line('Horario '||l_contar_horario);

            if l_contar_horario > 0 then

                    FOR C IN (SELECT ssbsect_crn crn,
                                     ssbsect_term_code term_code,
                                     sfrstcr_ptrm_code ptrm,
                                     sfrstcr_pidm pidm
                              FROM ssbsect ,
                                   sfrstcr
                              WHERE 1 = 1
                              AND ssbsect_term_code = sfrstcr_term_code
                              AND ssbsect_crn = sfrstcr_crn
                              AND ssbsect_ptrm_start_date =l_fecha_inicio_sor
                              AND sfrstcr_grde_code is  null
                              AND substr(ssbsect_term_code,5,1) not in (8,9)
        --                      AND sfrstcr_rsts_code ='RE'
                              AND sfrstcr_pidm = p_pidm
                              )
                              LOOP




                                 dbms_output.put_line('Entra a horario');

                                  BEGIN

                                    UPDATE SFRSTCR SET sfrstcr_rsts_code ='DD',
                                                       SFRSTCR_USER_ID = user,
                                                       SFRSTCR_DATA_ORIGIN ='Baja desde Abcc',
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


                                  IF l_retorna = 'EXITO' then

                                    FOR d IN (
                                              select *
                                              from sztprono
                                              where 1 = 1
--                                              and SZTPRONO_PTRM_CODE = c.ptrm
                                              and SZTPRONO_TERM_CODE = c.term_code
                                              and sztprono_pidm = c.pidm
                                              and sztprono_materia_legal in (select szstume_subj_code
                                                            from szstume
                                                            where 1 = 1
                                                            and szstume_no_regla = sztprono_no_regla
                                                            and szstume_subj_code = sztprono_materia_legal
                                                            and szstume_pidm = sztprono_pidm
                                                            AND SZSTUME_STAT_IND in('1','5')
                                                            )
        --                                      AND sztprono_envio_horarios ='S'
                                              )loop

                                                      dbms_output.put_line('Entra a prono ');

                                                      BEGIN

                                                        SELECT COUNT(*)
                                                        INTO l_materias_re
                                                        FROM szstume
                                                        WHERE 1 = 1
                                                        AND szstume_pidm = d.sztprono_pidm
                                                        AND szstume_no_regla = d.sztprono_no_regla
                                                        AND SZSTUME_SUBJ_CODE_COMP =d.sztprono_materia_legal
                                                        and SZSTUME_RSTS_CODE ='RE';


                                                      EXCEPTION WHEN OTHERS THEN
                                                            NULL;
                                                      END;

                                                      BEGIN

                                                        SELECT COUNT(*)
                                                        INTO l_materias_dd
                                                        FROM szstume
                                                        WHERE 1 = 1
                                                        AND szstume_pidm = d.sztprono_pidm
                                                        AND szstume_no_regla = d.sztprono_no_regla
                                                        AND SZSTUME_SUBJ_CODE_COMP =d.sztprono_materia_legal
                                                        and SZSTUME_RSTS_CODE ='DD';

                                                      EXCEPTION WHEN OTHERS THEN
                                                            NULL;
                                                      END;

--

                                                      if l_materias_re > 0 AND   l_materias_dd =0 then

                                                             for x in (select *
                                                                       from szstume
                                                                       where 1= 1
                                                                       and szstume_no_regla = d.sztprono_no_regla
                                                                       and szstume_subj_code_comp =d.sztprono_materia_legal
                                                                       and szstume_id = d.sztprono_id

                                                                       )
                                                                       loop

                                                                                dbms_output.put_line('Entra a szstume ');

                                                                                dbms_output.put_line('Estar date '||l_fecha_inicio_sor||' matricula '||l_matricula||' crn '||c.crn||' pperiodo '||c.ptrm||' term code '||c.term_code||' grupo '||x.szstume_term_nrc||' REGLA '||d.sztprono_no_regla);

                                                                                 --dbms_output.put_line('Entra a cursor x  ');

                                                                                BEGIN

                                                                                    SELECT MAX(NVL(szstume_seq_no,0))+1
                                                                                    INTO l_secuen_max
                                                                                    FROM szstume
                                                                                    WHERE 1 = 1
                                                                                    AND szstume_no_regla = d.sztprono_no_regla
                                                                                    and szstume_pidm = x.szstume_pidm
                                                                                    AND szstume_subj_code_comp  = d.sztprono_materia_legal
                                                                                    AND szstume_term_nrc =x.szstume_term_nrc ;

                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                    --l_retorna:='No se encontro secuencia maxima '||sqlerrm;
                                                                                    null;
                                                                                END;

                                                                                BEGIN

                                                                                   INSERT INTO szstume VALUES(x.szstume_term_nrc,
                                                                                                               x.szstume_pidm,
                                                                                                               x.szstume_id,
                                                                                                               SYSDATE,
                                                                                                               USER,
                                                                                                               0,
                                                                                                               'BAJAS ABCC',
                                                                                                               X.SZSTUME_PWD,
                                                                                                               NULL,
                                                                                                               l_secuen_max,
                                                                                                               'DD',
                                                                                                               NULL,
                                                                                                               x.szstume_subj_code_comp,
                                                                                                               NULL,-- c.nivel,
                                                                                                               NULL,
                                                                                                               NULL,--  c.ptrm,
                                                                                                               NULL,
                                                                                                               null,
                                                                                                               NULL,
                                                                                                               NULL,
                                                                                                               x.szstume_subj_code_comp,
                                                                                                               d.sztprono_fecha_inicio,--  c.inicio_clases,
                                                                                                               d.sztprono_no_regla,
                                                                                                               NULL,
                                                                                                               1,
                                                                                                               0,
                                                                                                               null
                                                                                                               );
                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                   l_retorna:='No se pudo insertar en szstume '||sqlerrm;
                                                                                END;

                                                                                dbms_output.put_line('Inerto baja  ');

                                                                                if l_retorna ='EXITO' then

                                                                                    BEGIN

                                                                                        UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                                                            sztprono_envio_horarios ='N',
                                                                                                            sztprono_descripcion_error ='Baja desde Abcc'
                                                                                        WHERE 1 = 1
                                                                                        AND sztprono_materia_legal = x.szstume_subj_code_comp
                                                                                        AND sztprono_pidm = x.szstume_pidm
                                                                                        AND sztprono_no_regla = d.sztprono_no_regla
                                                                                        AND sztprono_fecha_inicio =d.sztprono_fecha_inicio;

                                                                                    EXCEPTION WHEN OTHERS THEN
                                                                                        l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
                                                                                    END;

                                                                                end if;



                                                                       end loop;


                                                      end if;


                                              end loop;

                                  else

                                    rollback;

                                  end if;



                              END LOOP;

            else


                begin

                    select distinct sztprono_no_regla
                    into l_regla
                    from sztprono no1
                    where 1 = 1
                    and sztprono_pidm = p_pidm
                    and sztprono_no_regla = (select max(sztprono_no_regla)
                                             from sztprono no2
                                             where 1 = 1
                                             and no2.sztprono_pidm = no1.sztprono_pidm
                                             and sztprono_materia_legal in (select szstume_subj_code
                                                            from szstume
                                                            where 1 = 1
                                                            and szstume_no_regla = sztprono_no_regla
                                                            and szstume_subj_code = sztprono_materia_legal
                                                            and szstume_pidm = sztprono_pidm
                                                            AND SZSTUME_STAT_IND in('1','5')
                                                            )
                                             ) ;


                exception when others then
                    null;
                end;

                dbms_output.put_line(' regla '||l_regla);

                 for c in (
                            select distinct SZTPRONO_ID,
                                            sztprono_no_regla,
                                           sztprono_materia_legal,
                                           sztprono_fecha_inicio,
                                              get_crn_regla(ono.sztprono_pidm,
                                                               null,
                                                               ono.sztprono_materia_legal,
                                                               ono.sztprono_no_regla
                                                               )crn,
                                            sztprono_pidm pidm,
                                            sztprono_term_code term_code,
                                            sztprono_ptrm_code ptrm
                            from sztprono ono
                            where 1 = 1
                            and sztprono_no_regla = l_regla
                            and sztprono_pidm = p_pidm
                            and SZTPRONO_DESCRIPCION_ERROR is null
                            order by 2
                            )
                            loop

                                  begin

                                    select count(*)
                                    into l_acredita
                                    from SFRSTCR
                                    where 1 = 1
                                    and sfrstcr_pidm = c.pidm
                                    AND sfrstcr_term_code =c.term_code
                                    AND sfrstcr_ptrm_code = c.ptrm
                                    AND sfrstcr_grde_code is not null
                                    AND sfrstcr_crn  =    c.crn;

                                  exception when others then
                                    null;
                                  end;

                                  dbms_output.put_line('Acredita '||l_acredita);

                                  if l_acredita=0 then

                                      BEGIN

                                        UPDATE SFRSTCR SET sfrstcr_rsts_code ='DD',
                                                           SFRSTCR_USER_ID = user,
                                                           SFRSTCR_DATA_ORIGIN ='Baja desde Abcc',
                                                           SFRSTCR_USER = user,
                                                           SFRSTCR_ACTIVITY_DATE=sysdate
                                        WHERE 1 = 1
                                        AND sfrstcr_pidm = c.pidm
                                        AND sfrstcr_term_code =c.term_code
                                        AND sfrstcr_ptrm_code = c.ptrm
                                        AND sfrstcr_grde_code is  null
                                        AND sfrstcr_crn  =c.crn;

                                      EXCEPTION WHEN OTHERS THEN
                                          l_retorna:='No se pudo actualizar el registro sfctcr '||sqlerrm;
                                      END;

                                        dbms_output.put_line('Entra a szstume '||' regla '||l_regla);

                                    for x in (select *
                                              from szstume
                                              where 1= 1
                                              and szstume_no_regla = c.sztprono_no_regla
                                              and szstume_subj_code_comp =c.sztprono_materia_legal
                                              and szstume_id = c.sztprono_id
                                              )
                                              loop

                                                       dbms_output.put_line('Entra a szstume ');

                                                       BEGIN

                                                           SELECT MAX(NVL(szstume_seq_no,0))+1
                                                           INTO l_secuen_max
                                                           FROM szstume
                                                           WHERE 1 = 1
                                                           AND szstume_no_regla = c.sztprono_no_regla
                                                           and szstume_pidm = x.szstume_pidm
                                                           AND szstume_subj_code_comp  = c.sztprono_materia_legal
                                                           AND szstume_term_nrc =x.szstume_term_nrc ;

                                                       EXCEPTION WHEN OTHERS THEN
                                                           --l_retorna:='No se encontro secuencia maxima '||sqlerrm;
                                                           null;
                                                       END;

                                                       BEGIN

                                                          INSERT INTO szstume VALUES(x.szstume_term_nrc,
                                                                                      x.szstume_pidm,
                                                                                      x.szstume_id,
                                                                                      SYSDATE,
                                                                                      USER,
                                                                                      0,
                                                                                      'BAJAS ABCC',
                                                                                      X.SZSTUME_PWD,
                                                                                      NULL,
                                                                                      l_secuen_max,
                                                                                      'DD',
                                                                                      NULL,
                                                                                      x.szstume_subj_code_comp,
                                                                                      NULL,-- c.nivel,
                                                                                      NULL,
                                                                                      NULL,--  c.ptrm,
                                                                                      NULL,
                                                                                      null,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      x.szstume_subj_code_comp,
                                                                                      c.sztprono_fecha_inicio,--  c.inicio_clases,
                                                                                      c.sztprono_no_regla,
                                                                                      NULL,
                                                                                      1,
                                                                                      0,
                                                                                      null
                                                                                      );
                                                       EXCEPTION WHEN OTHERS THEN
                                                          l_retorna:='No se pudo insertar en szstume '||sqlerrm;
                                                       END;

                                                       dbms_output.put_line('Inerto baja  ');

                                                       if l_retorna ='EXITO' then

                                                           BEGIN

                                                               UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                                   sztprono_envio_horarios ='N',
                                                                                   sztprono_descripcion_error ='Baja desde Abcc'
                                                               WHERE 1 = 1
                                                               AND sztprono_materia_legal = x.szstume_subj_code_comp
                                                               AND sztprono_pidm = x.szstume_pidm
                                                               AND sztprono_no_regla = c.sztprono_no_regla
                                                               AND sztprono_fecha_inicio =c.sztprono_fecha_inicio;

                                                           EXCEPTION WHEN OTHERS THEN
                                                               l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
                                                           END;

                                                       end if;



                                              end loop;

                                  end if;

                            end loop;


            end if;



        end if;

        if l_retorna ='EXITO' then

               commit;

        else

            rollback;


        end if;



        RETURN(l_retorna);

    END;

--
--
    FUNCTION f_reversion_baja(p_pidm NUMBER,
                              p_fecha_inicio DATE,
                              p_programa VARCHAR2)
    RETURN   varchar2
    IS

    l_existe NUMBER;
    l_regla  NUMBER;
    l_retorna VARCHAR2(200):='EXITO';
    l_secuen_max NUMBER;
    l_matricula VARCHAR2(20);
    VL_CANCELA_CARTERA VARCHAR2(900);
    VL_PERIODO VARCHAR2(12);
    VL_AJUSTE_TZFACE VARCHAR2(900);

    BEGIN

        BEGIN

            SELECT COUNT(*)
            INTO l_existe
            FROM sztprono
            WHERE 1 = 1
            AND sztprono_pidm = p_pidm
            AND sztprono_fecha_inicio = p_fecha_inicio
            AND sztprono_descripcion_error is not null;

        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

        dbms_output.put_line('existe --> '||l_existe);

        IF l_existe > 0 THEN

            dbms_output.put_line('existe');

            FOR c IN
                (
                 SELECT ono.*,
                        get_crn_regla(sztprono_pidm,
                                            sztprono_term_code,
                                            sztprono_materia_legal,
                                            sztprono_no_regla
                                            )crn
                FROM sztprono ono
                WHERE 1 = 1
                AND sztprono_pidm = p_pidm
                AND sztprono_fecha_inicio = p_fecha_inicio
                AND sztprono_descripcion_error is not null

                )LOOP

                 vl_periodo:= c.sztprono_term_code;

                    dbms_output.put_line('Entra a prono');


                    BEGIN

                        UPDATE   sfrstcr SET sfrstcr_rsts_code ='RE',
                                             SFRSTCR_GRDE_CODE=null,
                                             ---SFRSTCR_GRDE_DATE=sysdate, 250225 GOG
                                             SFRSTCR_GRDE_DATE=null,											 
                                             sfrstcr_user_id = USER,
                                             sfrstcr_data_origin ='Reversion de Baja desde Abcc',
                                             sfrstcr_user = USER,
                                             sfrstcr_activity_date= SYSDATE

                        WHERE 1 = 1
                        AND sfrstcr_term_code = c.sztprono_term_code
                        AND sfrstcr_pidm = c.sztprono_pidm
                        AND sfrstcr_crn = c.crn;

                    EXCEPTION WHEN OTHERS THEN
                       l_retorna:='No se puede actualizar sfrstcr '||SQLERRM;
                    END;

                    BEGIN
                         UPDATE sgrstsp SET SGRSTSP_STSP_CODE = 'AS'
                         WHERE  1 = 1
                         and sgrstsp_pidm = c.sztprono_pidm
                         AND sgrstsp_key_seqno = c.SZTPRONO_STUDY_PATH
                         AND SGRSTSP_STSP_CODE='IN';

                     EXCEPTION WHEN others then
                         l_retorna:='No se puede actualizar el estatus '||sqlerrm;
                    END;

                    COMMIT;

                    FOR x IN (SELECT *
                              FROM szstume
                              WHERE 1= 1
                              AND szstume_no_regla = c.sztprono_no_regla
                              AND szstume_subj_code_comp =c.sztprono_materia_legal
                              AND szstume_id = c.sztprono_id
                              AND szstume_rsts_code ='RE'
                              )
                        LOOP


                            dbms_output.put_line('Entra a szstume');

                            BEGIN

                                SELECT MAX(NVL(szstume_seq_no,0))+1
                                INTO l_secuen_max
                                FROM szstume
                                WHERE 1 = 1
                                AND szstume_no_regla = c.sztprono_no_regla
                                and szstume_pidm = x.szstume_pidm
                                AND szstume_subj_code_comp  = c.sztprono_materia_legal
                                AND szstume_term_nrc =x.szstume_term_nrc ;

                            EXCEPTION WHEN OTHERS THEN
                                --l_retorna:='No se encontro secuencia maxima '||sqlerrm;
                                null;
                            END;

                            BEGIN

                               INSERT INTO szstume VALUES(x.szstume_term_nrc,
                                                           x.szstume_pidm,
                                                           x.szstume_id,
                                                           SYSDATE,
                                                           USER,
                                                           0,
                                                           'ALTAS DESDE ABCC',
                                                           x.szstume_pwd,
                                                           NULL,
                                                           l_secuen_max,
                                                           'RE',
                                                           NULL,
                                                           x.szstume_subj_code_comp,
                                                           NULL,-- c.nivel,
                                                           NULL,
                                                           NULL,--  c.ptrm,
                                                           NULL,
                                                           null,
                                                           NULL,
                                                           NULL,
                                                           x.szstume_subj_code_comp,
                                                           c.sztprono_fecha_inicio,--  c.inicio_clases,
                                                           c.sztprono_no_regla,
                                                           NULL,
                                                           1,
                                                           0,
                                                           null
                                                           );
                            EXCEPTION WHEN OTHERS THEN
                               l_retorna:='No se pudo insertar en szstume '||sqlerrm;
                            END;

                              dbms_output.put_line('Inerto alta  '||l_secuen_max);

                            IF l_retorna ='EXITO' THEN

                                BEGIN

                                    UPDATE sztprono SET sztprono_estatus_error ='N',
                                                        sztprono_envio_horarios ='S',
                                                        sztprono_descripcion_error ='Reversion de Baja desde Abcc'
                                    WHERE 1 = 1
                                    AND sztprono_materia_legal = x.szstume_subj_code_comp
                                    AND sztprono_pidm = x.szstume_pidm
                                    AND sztprono_no_regla = c.sztprono_no_regla
                                    AND sztprono_fecha_inicio =c.sztprono_fecha_inicio;

                                EXCEPTION WHEN OTHERS THEN
                                    l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
                                END;

                            END IF;

                        END LOOP;


                        BEGIN

                           UPDATE sgbstdn a SET a.sgbstdn_styp_code =DECODE(c.sztprono_estatus,'F','N','R','C',c.sztprono_estatus),
                                                   a.sgbstdn_data_origin ='Reversion de Baja desde Abcc',
                                                   a.sgbstdn_user_id =USER,
                                                   a.sgbstdn_activity_date = sysdate
                           WHERE 1 = 1
                           AND a.sgbstdn_pidm = p_pidm
                           and a.sgbstdn_program_1 = p_programa
                           AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                          FROM sgbstdn a1
                                                          WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                          AND a1.sgbstdn_program_1 = a.sgbstdn_program_1
                                                          );

                        EXCEPTION WHEN OTHERS THEN
                           l_retorna := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
                        END;

                                 begin

                                    update SZSTUME set SZSTUME_GRDE_CODE_FINAL ='RE',
                                                    SZSTUME_TERM_NRC_COMP='RE'
                                    WHERE 1 = 1
                                    AND SZSTUME_PIDM = c.sztprono_pidm
                                    and SZSTUME_NO_REGLA=c.SZTPRONO_NO_REGLA;

                                exception when others then
                                    null;
                                end;


                END LOOP;

        END IF;


        dbms_output.put_line('Regreso  '||l_retorna);

        IF l_retorna ='EXITO' THEN

         /* SE AGREGA FUNCION DE CANCELACION DE CARTERA PARA AJUSTAR PARCIALIDADES PENDIENTES
            AUTOR:  JREZAOLI
            FECHA: 10/06/2020
            YA ESTAS MI CHUY
           */
          IF vl_periodo IS NOT NULL THEN
                null;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            ------VL_AJUSTE_TZFACE := PKG_FINANZAS.F_CARTERA_REVERSION_BAJA ( p_pidm, p_fecha_inicio);
            ------- Se detinee porque no esta aplicando de forma correcta los ajustes de revision de baja
            ------- Se debe de volver a prender hasta se mande el requerimiento -------------
            ------- Victor Ramirez 22/08/2022 ------- Preguntar antes de encender

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------


          END IF;

        ELSE

            ROLLBACK;


        END IF;


        RETURN l_retorna;

    END;
--
--
PROCEDURE P_BAJA_ABCC(P_PIDM NUMBER,P_FECHA_INICIO DATE)
    IS

    l_mayor_prono number;
    l_crn_mayor    varchar2(10);
    l_MATERIA_MAYOR VARCHAR2(10);

begin

    for c in
        (
        select a.*,
               get_crn_regla(a.sztprono_pidm,
                              null,
                              a.sztprono_materia_legal,
                              a.sztprono_no_regla)crn
        from sztprono a
        where 1 = 1
        and sztprono_fecha_inicio = p_fecha_inicio
        and sztprono_pidm =p_pidm
        and sztprono_materia_legal not in (   select distinct SZTALMT_MATERIA
                                                from sztalmt
                                                where 1=1)
        )loop

                begin

                    select max(sztprono_secuencia)
                    into l_mayor_prono
                    from sztprono A
                    where 1 = 1
                    and A.sztprono_no_regla = c.sztprono_no_regla
                    and A.sztprono_pidm = c.sztprono_pidm
                    and sztprono_materia_legal not in (   select distinct SZTALMT_MATERIA
                                                from sztalmt
                                                where 1=1)
                    AND get_crn_regla(a.sztprono_pidm,
                              null,
                              a.sztprono_materia_legal,
                              a.sztprono_no_regla)<>'00';

                exception when others then
                    null;
                end;

                begin
                    select distinct get_crn_regla(a.sztprono_pidm,
                                                      null,
                                                      a.sztprono_materia_legal,
                                                      a.sztprono_no_regla)crn,
                                                      A.sztprono_materia_legal
                    into l_crn_mayor,
                         l_MATERIA_MAYOR
                    from sztprono a
                    where 1 = 1
                    and sztprono_no_regla = c.sztprono_no_regla
                    and sztprono_pidm = c.sztprono_pidm
                    and sztprono_materia_legal not in (   select distinct SZTALMT_MATERIA
                                                from sztalmt
                                                where 1=1)
                    and sztprono_secuencia = l_mayor_prono;

                exception when others then
                    null;
                end;

                dbms_output.put_line('Alumno '||c.sztprono_id||' Materia Legal '||c.sztprono_materia_legal||' crn '||c.crn||' Regla '||c.sztprono_no_regla ||' Secuenca Mayor '||l_mayor_prono||' crn mayor '||l_crn_mayor);

                begin

                    update sfrstcr set SFRSTCR_RSTS_CODE ='RE',
                                       SFRSTCR_GRDE_CODE ='NP',
                                       SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                       SFRSTCR_DATA_ORIGIN ='SZFABCC_BAJA',
                                       SFRSTCR_USER = USER,
                                       SFRSTCR_ASSESS_ACTIVITY_DATE=sysdate,
                                    ---SFRSTCR_GRDE_DATE=sysdate, 250225 GOG
                                       SFRSTCR_GRDE_DATE=null,
                                        SFRSTCR_GRDE_CODE_INCMP_FINAL='ASPF'

                    WHERE 1 = 1
                    AND sfrstcr_pidm = c.sztprono_pidm
                    AND SFRSTCR_RSTS_CODE ='DD'
                    and sfrstcr_term_code = c.sztprono_term_code
                    and sfrstcr_crn = l_crn_mayor;


                exception when others then
                    null;
                end;



                   begin

                    update SZSTUME set SZSTUME_GRDE_CODE_FINAL ='NP',
                                    SZSTUME_TERM_NRC_COMP='NP'
                    WHERE 1 = 1
                    AND SZSTUME_PIDM = c.sztprono_pidm
                    AND SZSTUME_RSTS_CODE ='DD'
                    and SZSTUME_NO_REGLA = c.SZTPRONO_NO_REGLA
                    and SZSTUME_SUBJ_CODE =  l_MATERIA_MAYOR
                    AND SZSTUME_SUBJ_CODE not in (   select distinct SZTALMT_MATERIA
                                                from sztalmt
                                                where 1=1);
                exception when others then
                    null;
                end;


        end loop;

        commit;

end;
----
----
PROCEDURE P_INANTIVA_TZTCOTA (P_RAZON VARCHAR2,P_PIDM NUMBER)
as
L_RETORNA  VARCHAR2(1000):='EXITO';
L_SURROGATEDOS NUMBER;
L_SEQNO NUMBER;
L_CONTAR NUMBER;
L_SECNOCOTA NUMBER;
L_PERIODO VARCHAR2(6);

BEGIN

    BEGIN
        SELECT COUNT(GORADID_PIDM)
          INTO L_CONTAR
          FROM GORADID
         WHERE 1 = 1
           AND GORADID_PIDM = P_PIDM
           AND GORADID_ADID_CODE IN (SELECT DISTINCT (ZSTPARA_PARAM_VALOR)
                                    FROM ZSTPARA
                                    WHERE 1=1
                                    AND  ZSTPARA_MAPA_ID = 'COLF_UPSELLING'
                                    and ZSTPARA_PARAM_ID in(P_RAZON))
      ;
      dbms_output.put_line('L_CONTAR '||L_CONTAR||P_RAZON);
    EXCEPTION
        WHEN OTHERS THEN
            L_CONTAR := 0;
         dbms_output.put_line('no L_CONTAR '||L_CONTAR||P_RAZON);
    END;


     BEGIN
        SELECT NVL(MAX(SGRSCMT_SURROGATE_ID),0) + 1
          INTO L_SURROGATEDOS
          FROM SGRSCMT
         WHERE 1 = 1;
--         dbms_output.put_line('L_SURROGATEDOS '||L_SURROGATEDOS);

    EXCEPTION WHEN OTHERS THEN
            L_SURROGATEDOS := 0;
--          dbms_output.put_line('L_SURROGATEDOS '||L_SURROGATEDOS);
    END;


    BEGIN
        SELECT NVL(MAX(SGRSCMT_SEQ_NO),0) + 1
          INTO L_SEQNO
          FROM SGRSCMT
         WHERE 1 = 1
           AND SGRSCMT_PIDM = P_PIDM;
--            dbms_output.put_line('L_SEQNO '||L_SEQNO);

    EXCEPTION
        WHEN OTHERS THEN
        L_SEQNO := 0;
--        dbms_output.put_line('L_SEQNO '||L_SEQNO);
    END;

    BEGIN
        SELECT NVL(MAX(SGBSTDN_TERM_CODE_EFF),'SIN PERIODO')
          INTO L_PERIODO
          FROM SGBSTDN
         WHERE 1 = 1
           AND SGBSTDN_PIDM = P_PIDM;

--            dbms_output.put_line('L_PERIODO '||L_SEQNO);
    EXCEPTION WHEN OTHERS THEN
          L_PERIODO := '000000';
--           dbms_output.put_line('L_PERIODO '||L_SEQNO);

    END;

    BEGIN
             SELECT NVL(MAX (TZTCOTA_SEQNO)+1,0)
             INTO L_SECNOCOTA
             FROM  TZTCOTA
             WHERE 1=1
             AND TZTCOTA_PIDM= P_PIDM
             AND TZTCOTA_STATUS='A'
             AND TZTCOTA_ORIGEN IN (SELECT DISTINCT (ZSTPARA_PARAM_VALOR)
                                    FROM ZSTPARA
                                    WHERE 1=1
                                    AND  ZSTPARA_MAPA_ID = 'COLF_UPSELLING'
                                    and ZSTPARA_PARAM_ID in(P_RAZON));
               dbms_output.put_line('L_SECNOCOTA '||L_SECNOCOTA);

      EXCEPTION WHEN OTHERS THEN

               L_SECNOCOTA:=0;
               dbms_output.put_line(' no L_SECNOCOTA '||L_SECNOCOTA);

               END;

 if L_CONTAR>=1 and  L_SECNOCOTA =0 then

               dbms_output.put_line('no existe en cota');

                BEGIN

                 DELETE GORADID
                 WHERE 1=1
                 AND GORADID_PIDM=P_PIDM
                 AND GORADID_ADID_CODE IN(SELECT DISTINCT (ZSTPARA_PARAM_VALOR)
                                    FROM ZSTPARA
                                    WHERE 1=1
                                    AND  ZSTPARA_MAPA_ID = 'COLF_UPSELLING'
                                    and ZSTPARA_PARAM_ID in(P_RAZON));

                 dbms_output.put_line('borra etiqueta');

               EXCEPTION WHEN OTHERS THEN

                l_retorna:=' Error al borrar etiqueta COLF_UPSELLING en GORADID ' ||SQLERRM;

                dbms_output.put_line('no borra etiqueta'||l_retorna);

               END;

              COMMIT;
 else

  FOR C IN (
              SELECT *
             FROM  TZTCOTA
             WHERE 1=1
             AND TZTCOTA_PIDM= P_PIDM
             AND TZTCOTA_STATUS='A'
             AND TZTCOTA_ORIGEN IN (SELECT DISTINCT (ZSTPARA_PARAM_VALOR)
                                    FROM ZSTPARA
                                    WHERE 1=1
                                    AND  ZSTPARA_MAPA_ID = 'COLF_UPSELLING'
                                    and ZSTPARA_PARAM_ID in(P_RAZON))
            )

         LOOP

           IF L_CONTAR>=1 and L_SECNOCOTA>=1 THEN

--               dbms_output.put_line('ENTRA A COTA');

             BEGIN
                 INSERT INTO TZTCOTA(TZTCOTA_PIDM          ,
                                    TZTCOTA_TERM_CODE      ,
                                    TZTCOTA_CAMPUS        ,
                                    TZTCOTA_NIVEL          ,
                                    TZTCOTA_PROGRAMA      ,
                                    TZTCOTA_CODIGO          ,
                                    TZTCOTA_SERVICIO      ,
                                    TZTCOTA_CARGOS         ,
                                    TZTCOTA_APLICADOS      ,
                                    TZTCOTA_DESCUENTO      ,
                                    TZTCOTA_SEQNO          ,
                                    TZTCOTA_FLAG          ,
                                    TZTCOTA_USER          ,
                                    TZTCOTA_ORIGEN          ,
                                    TZTCOTA_STATUS          ,
                                    TZTCOTA_FECHA_INI      ,
                                    TZTCOTA_ACTIVITY      ,
                                    TZTCOTA_OBSERVACIONES ,
                                    TZTCOTA_MONTO          ,
                                    TZTCOTA_GRATIS          ,
                                    GRATIS_APLICADO          ,
                                    TZTCOTA_EMAIL          ,
                                    TZTCOTA_SINCRONIA      )
                                    VALUES(C.TZTCOTA_PIDM          ,
                                            C.TZTCOTA_TERM_CODE      ,
                                            C.TZTCOTA_CAMPUS        ,
                                            C.TZTCOTA_NIVEL          ,
                                            C.TZTCOTA_PROGRAMA      ,
                                            C.TZTCOTA_CODIGO          ,
                                            C.TZTCOTA_SERVICIO      ,
                                            C.TZTCOTA_CARGOS         ,
                                            C.TZTCOTA_APLICADOS      ,
                                            C.TZTCOTA_DESCUENTO      ,
                                            L_SECNOCOTA          ,
                                            C.TZTCOTA_FLAG          ,
                                            USER        ,
                                            C.TZTCOTA_ORIGEN          ,
                                            'I'          ,
                                            C.TZTCOTA_FECHA_INI      ,
                                            C.TZTCOTA_ACTIVITY      ,
                                            'INACTIVA' ,
                                            C.TZTCOTA_MONTO          ,
                                            C.TZTCOTA_GRATIS          ,
                                            C.GRATIS_APLICADO          ,
                                            C.TZTCOTA_EMAIL          ,
                                            C.TZTCOTA_SINCRONIA      );

--                 dbms_output.put_line('INSERTa en cota');
               EXCEPTION WHEN OTHERS THEN

                l_retorna:=' Error al inactivar en SZTCOTA' ||SQLERRM;
--                dbms_output.put_line('INSERTa en cota'||l_retorna);

               END;


               BEGIN

                 DELETE GORADID
                 WHERE 1=1
                 AND GORADID_PIDM=C.TZTCOTA_PIDM
                 AND GORADID_ADID_CODE IN (SELECT DISTINCT (ZSTPARA_PARAM_VALOR)
                                    FROM ZSTPARA
                                    WHERE 1=1
                                    AND  ZSTPARA_MAPA_ID = 'COLF_UPSELLING'
                                    and ZSTPARA_PARAM_ID in(P_RAZON));
--                 dbms_output.put_line('borra etiqueta');
               EXCEPTION WHEN OTHERS THEN

                l_retorna:=' Error al borrar etiqueta COLF en GORADID ' ||SQLERRM;
--                dbms_output.put_line('no borra etiqueta'||l_retorna);

               END;

                BEGIN
                          INSERT INTO SGRSCMT(SGRSCMT_PIDM
                                                ,SGRSCMT_SEQ_NO
                                                ,SGRSCMT_TERM_CODE
                                                ,SGRSCMT_COMMENT_TEXT
                                                ,SGRSCMT_ACTIVITY_DATE
                                                ,SGRSCMT_SURROGATE_ID
                                                ,SGRSCMT_VERSION
                                                ,SGRSCMT_USER_ID
                                                ,SGRSCMT_DATA_ORIGIN
                                                ,SGRSCMT_VPDI_CODE)
                                          VALUES(P_PIDM                                                                                             --SGRSCMT_PIDM
                                                ,L_SEQNO                                                                                            --SGRSCMT_SEQ_NO
                                                ,L_PERIODO                                                                                          --SGRSCMT_TERM_CODE
                                                ,'INACTIVA'||' Fecha: ' ||SYSDATE    --SGRSCMT_COMMENT_TEXT
                                                ,SYSDATE                                                                                            --SGRSCMT_ACTIVITY_DATE
                                                ,L_SURROGATEDOS                                                                                     --SGRSCMT_SURROGATE_ID
                                                ,1                                                                                                  --SGRSCMT_VERSION
                                                ,USER                                                                                          --SGRSCMT_USER_ID
                                                ,'INACTIVA DESDE SZFABCC'                                                                                      --SGRSCMT_DATA_ORIGIN
                                                ,1);                                                                                                --SGRSCMT_VPDI_CODE
--                         dbms_output.put_line('inserta en bitacora');
                        EXCEPTION WHEN OTHERS THEN

                        L_RETORNA:='Error al insertar en la tabla SGRSCMT para el alumno(Pidm)'||SQLERRM;
--                        dbms_output.put_line('no inserta en bitacora'||L_RETORNA);
                    END;


                COMMIT;

           else

           exit;

           END IF;

         END LOOP;

  end if;

END;

end pkg_jornadas_abcc;
/

DROP PUBLIC SYNONYM PKG_JORNADAS_ABCC;

CREATE OR REPLACE PUBLIC SYNONYM PKG_JORNADAS_ABCC FOR BANINST1.PKG_JORNADAS_ABCC;
