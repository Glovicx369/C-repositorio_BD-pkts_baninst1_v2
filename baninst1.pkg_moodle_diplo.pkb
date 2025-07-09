DROP PACKAGE BODY BANINST1.PKG_MOODLE_DIPLO;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_MOODLE_DIPLO
IS
   --
   --
   PROCEDURE p_inserta_conf (p_materia         VARCHAR2,
                             p_grupo           NUMBER,
                             p_fecha_inicio    VARCHAR2,
                             p_regla           NUMBER)
   IS
      l_retorna   VARCHAR2 (20);
   BEGIN
      INSERT INTO sztconf (SZTCONF_SUBJ_CODE,
                           SZTCONF_GROUP,
                           SZTCONF_STUDENT_NUMB,
                           SZTCONF_COST,
                           SZTCONF_USSER_INSERT,
                           SZTCONF_DATE_INSERT,
                           SZTCONF_USSER_UPDATE,
                           SZTCONF_DATE_UPDATE,
                           SZTCONF_NO_REGLA,
                           SZTCONF_ESTATUS_CERRADO,
                           SZTCONF_FECHA_INICIO,
                           SZTCONF_NI,
                           SZTCONF_SECUENCIA,
                           SZTCONF_NUMERO_PROF,
                           SZTCONF_IDIOMA )
           VALUES (p_materia,
                   p_grupo,
                   0,
                   2000,
                   USER,
                   SYSDATE,
                   USER,
                   SYSDATE,
                   p_regla,
                   'N',
                   to_char(to_date(p_fecha_inicio),'DD/MM/YYYY'),
                   null,
                   null,
                   null,
                   'E');
      COMMIT;
   END;

   --
   --

   FUNCTION f_materia_manual (p_subj             VARCHAR2,
                              p_numb             VARCHAR2,
                              p_regla            NUMBER,
                              p_grupo            VARCHAR2,
                              p_inicio_clases    VARCHAR2)
      RETURN VARCHAR2
   AS
      l_retorna         VARCHAR (200);
      l_grupo_max       NUMBER;
      l_pidm_prof       NUMBER;
      l_crn             VARCHAR2 (100);
      l_periodo         VARCHAR2 (100);
      l_parte_periodo   VARCHAR2 (3);
      l_campus          VARCHAR2 (3);
      schd              VARCHAR2 (3);
      title             VARCHAR2 (100);
      credit            NUMBER;
      credit_bill       NUMBER;
      gmod              NUMBER;
      f_inicio          DATE;
      f_fin             DATE;
      sem               NUMBER;
      l_term_nrc        VARCHAR2 (30);
      l_nivel           VARCHAR2 (3);
      l_short_name      VARCHAR2 (100);
      l_pwd             VARCHAR2 (100);
   BEGIN
      PKG_ALGORITMO.P_ENA_DIS_TRG ('D', 'SATURN.SZT_SSBSECT_POSTINSERT_ROW');
      PKG_ALGORITMO.P_ENA_DIS_TRG ('D', 'SATURN.SZT_SIRASGN_POSTINSERT_ROW');
      PKG_ALGORITMO.P_ENA_DIS_TRG ('D', 'SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');



      BEGIN
         SELECT DISTINCT SZTALGO_TERM_CODE_NEW,
                         SZTALGO_PTRM_CODE_NEW,
                         SZTALGO_CAMP_CODE,
                         SZTALGO_LEVL_CODE
           INTO l_periodo,
                l_parte_periodo,
                l_campus,
                l_nivel
           FROM SZTALGO
          WHERE 1 = 1 AND SZTALGO_NO_REGLA = P_REGLA;
      EXCEPTION
         WHEN OTHERS
         THEN
            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,
                            SZTALGO_PTRM_CODE_NEW,
                            SZTALGO_CAMP_CODE,
                            SZTALGO_LEVL_CODE
              INTO l_periodo,
                   l_parte_periodo,
                   l_campus,
                   l_nivel
              FROM SZTALGO
             WHERE 1 = 1 AND SZTALGO_NO_REGLA = P_REGLA AND ROWNUM = 1;
      END;

      BEGIN
         SELECT    DECODE (SUBSTR (l_periodo, 1, 2),
                           '02', '01',
                           SUBSTR (l_periodo, 1, 2))
                || SUBSTR (l_periodo, 3, 5)
                   dato
           INTO l_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;


      BEGIN
         SELECT    DECODE (SUBSTR (l_parte_periodo, 1, 1),
                           'A', 'M',
                           SUBSTR (l_parte_periodo, 1, 1))
                || SUBSTR (l_parte_periodo, 2, 4)
                   dato
           INTO l_parte_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         SELECT    DECODE (SUBSTR (l_parte_periodo, 1, 2),
                           '02', '01',
                           SUBSTR (l_parte_periodo, 1, 2))
                || SUBSTR (l_parte_periodo, 3, 5)
                   dato
           INTO l_parte_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         SELECT NVL (MAX (crn), 1000) + 1
           INTO l_crn
           FROM (SELECT CASE
                           WHEN SUBSTR (SSBSECT_CRN, 1, 1) IN ('L',
                                                               'M',
                                                               'D',
                                                               'A')
                           THEN
                              TO_NUMBER (SUBSTR (SSBSECT_CRN, 2, 100)) + 1
                           ELSE
                              TO_NUMBER (SSBSECT_CRN)
                        END
                           crn
                   FROM ssbsect
                  WHERE ssbsect_term_code = l_periodo);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_crn := NULL;
      END;


      BEGIN
         SELECT scrschd_schd_code,
                scbcrse_title,
                scbcrse_credit_hr_low,
                scbcrse_bill_hr_low
           INTO schd,
                title,
                credit,
                credit_bill
           FROM scbcrse, scrschd
          WHERE     1 = 1
                AND scbcrse_subj_code = p_subj
                AND scbcrse_crse_numb = p_numb
                AND scbcrse_eff_term = '000000'
                AND scrschd_subj_code = scbcrse_subj_code
                AND scrschd_crse_numb = scbcrse_crse_numb
                AND scrschd_eff_term = scbcrse_eff_term;
      EXCEPTION
         WHEN OTHERS
         THEN
            schd := NULL;
            title := NULL;
            credit := NULL;
            credit_bill := NULL;
      END;

      BEGIN
         SELECT scrgmod_gmod_code
           INTO gmod
           FROM scrgmod
          WHERE     1 = 1
                AND scrgmod_subj_code = p_subj
                AND scrgmod_crse_numb = p_numb
                AND scrgmod_default_ind = 'D';
      EXCEPTION
         WHEN OTHERS
         THEN
            gmod := '1';
      END;


      BEGIN
         SELECT DISTINCT sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
           INTO f_inicio, f_fin, sem
           FROM sobptrm
          WHERE     1 = 1
                AND sobptrm_term_code = l_periodo
                AND sobptrm_ptrm_code = l_parte_periodo;
      EXCEPTION
         WHEN OTHERS
         THEN
            -- vl_error := 'No se Encontro configuracion para el Periodo= ' ||c.periodo ||' y Parte de Periodo= '||c.parte ||SQLERRM;
            NULL;
      END;

      BEGIN
         SELECT DISTINCT sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
           INTO f_inicio, f_fin, sem
           FROM sobptrm
          WHERE     1 = 1
                AND sobptrm_term_code = l_periodo
                AND sobptrm_ptrm_code = l_parte_periodo;
      EXCEPTION
         WHEN OTHERS
         THEN
            --vl_error := 'No se Encontro configuracion para el Periodo= ' ||c.periodo ||' y Parte de Periodo= '||c.parte ||SQLERRM;
            NULL;
      END;


      IF l_campus = 'UTS'
      THEN
         l_campus := 'UTL';
      END IF;


      IF l_nivel = 'LI'
      THEN
         l_crn := 'L' || l_crn;
      ELSE
         l_crn := 'M' || l_crn;
      END IF;

      BEGIN
         INSERT INTO ssbsect
              VALUES (l_periodo,                           --SSBSECT_TERM_CODE
                      l_crn,                                     --SSBSECT_CRN
                      l_parte_periodo,                     --SSBSECT_PTRM_CODE
                      p_subj,                              --SSBSECT_SUBJ_CODE
                      p_numb,                              --SSBSECT_CRSE_NUMB
                      p_grupo,                              --SSBSECT_SEQ_NUMB
                      'A',                                 --SSBSECT_SSTS_CODE
                      'ENL',                               --SSBSECT_SCHD_CODE
                      l_campus,                            --SSBSECT_CAMP_CODE
                      title,                              --SSBSECT_CRSE_TITLE
                      credit,                             --SSBSECT_CREDIT_HRS
                      credit_bill,                          --SSBSECT_BILL_HRS
                      gmod,                                --SSBSECT_GMOD_CODE
                      NULL,                                --SSBSECT_SAPR_CODE
                      NULL,                                --SSBSECT_SESS_CODE
                      NULL,                               --SSBSECT_LINK_IDENT
                      NULL,                                 --SSBSECT_PRNT_IND
                      'Y',                              --SSBSECT_GRADABLE_IND
                      NULL,                                 --SSBSECT_TUIW_IND
                      0,                                   --SSBSECT_REG_ONEUP
                      0,                                  --SSBSECT_PRIOR_ENRL
                      0,                                   --SSBSECT_PROJ_ENRL
                      90,                                   --SSBSECT_MAX_ENRL
                      0,                                        --SSBSECT_ENRL
                      50,                                --SSBSECT_SEATS_AVAIL
                      NULL,                           --SSBSECT_TOT_CREDIT_HRS
                      '0',                               --SSBSECT_CENSUS_ENRL
                      f_inicio,                     --SSBSECT_CENSUS_ENRL_DATE
                      SYSDATE,                         --SSBSECT_ACTIVITY_DATE
                      p_inicio_clases,               --SSBSECT_PTRM_START_DATE
                      f_fin,                           --SSBSECT_PTRM_END_DATE
                      sem,                                --SSBSECT_PTRM_WEEKS
                      NULL,                             --SSBSECT_RESERVED_IND
                      NULL,                            --SSBSECT_WAIT_CAPACITY
                      NULL,                               --SSBSECT_WAIT_COUNT
                      NULL,                               --SSBSECT_WAIT_AVAIL
                      NULL,                                   --SSBSECT_LEC_HR
                      NULL,                                   --SSBSECT_LAB_HR
                      NULL,                                   --SSBSECT_OTH_HR
                      NULL,                                  --SSBSECT_CONT_HR
                      NULL,                                --SSBSECT_ACCT_CODE
                      NULL,                                --SSBSECT_ACCL_CODE
                      NULL,                            --SSBSECT_CENSUS_2_DATE
                      NULL,                        --SSBSECT_ENRL_CUT_OFF_DATE
                      NULL,                        --SSBSECT_ACAD_CUT_OFF_DATE
                      NULL,                        --SSBSECT_DROP_CUT_OFF_DATE
                      NULL,                            --SSBSECT_CENSUS_2_ENRL
                      'Y',                               --SSBSECT_VOICE_AVAIL
                      'N',                      --SSBSECT_CAPP_PREREQ_TEST_IND
                      NULL,                                --SSBSECT_GSCH_NAME
                      NULL,                             --SSBSECT_BEST_OF_COMP
                      NULL,                           --SSBSECT_SUBSET_OF_COMP
                      'NOP',                               --SSBSECT_INSM_CODE
                      NULL,                            --SSBSECT_REG_FROM_DATE
                      NULL,                              --SSBSECT_REG_TO_DATE
                      NULL,                   --SSBSECT_LEARNER_REGSTART_FDATE
                      NULL,                   --SSBSECT_LEARNER_REGSTART_TDATE
                      NULL,                                --SSBSECT_DUNT_CODE
                      NULL,                          --SSBSECT_NUMBER_OF_UNITS
                      0,                        --SSBSECT_NUMBER_OF_EXTENSIONS
                      'PRONOSTICO ' || p_regla,          --SSBSECT_DATA_ORIGIN
                      USER,                                  --SSBSECT_USER_ID
                      'MOOD',                               --SSBSECT_INTG_CDE
                      'B',                     --SSBSECT_PREREQ_CHK_METHOD_CDE
                      USER,                         --SSBSECT_KEYWORD_INDEX_ID
                      NULL,                          --SSBSECT_SCORE_OPEN_DATE
                      NULL,                        --SSBSECT_SCORE_CUTOFF_DATE
                      NULL,                     --SSBSECT_REAS_SCORE_OPEN_DATE
                      NULL,                     --SSBSECT_REAS_SCORE_CTOF_DATE
                      NULL,                             --SSBSECT_SURROGATE_ID
                      NULL,                                  --SSBSECT_VERSION
                      NULL                                 --SSBSECT_VPDI_CODE
                          );

         l_retorna := 'EXITO';
      EXCEPTION
         WHEN OTHERS
         THEN
            -- l_retorna:='Error al insertar ssbsect periodo '||l_periodo||' Error '||sqlerrm;
            NULL;
      END;

      IF l_retorna = 'EXITO'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      RETURN (l_retorna || ' ' || l_crn);

      PKG_ALGORITMO.P_ENA_DIS_TRG ('E', 'SATURN.SZT_SSBSECT_POSTINSERT_ROW');
      PKG_ALGORITMO.P_ENA_DIS_TRG ('E', 'SATURN.SZT_SIRASGN_POSTINSERT_ROW');
      PKG_ALGORITMO.P_ENA_DIS_TRG ('E','SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');
   END;

   --
   --
   FUNCTION f_prof_manual (p_prof_id          VARCHAR2,
                           p_crn              VARCHAR2,
                           p_inicio_clases    VARCHAR2,
                           p_regla            NUMBER)
      RETURN VARCHAR2
   IS
      l_retorna         VARCHAR2 (100);
      l_grupo_max       NUMBER;
      l_pidm_prof       NUMBER;
      l_crn             VARCHAR2 (100);
      l_periodo         VARCHAR2 (100);
      l_parte_periodo   VARCHAR2 (3);
      l_campus          VARCHAR2 (3);
      schd              VARCHAR2 (3);
      title             VARCHAR2 (100);
      credit            NUMBER;
      credit_bill       NUMBER;
      gmod              NUMBER;
      f_inicio          DATE;
      f_fin             DATE;
      sem               NUMBER;
      l_term_nrc        VARCHAR2 (30);
      l_nivel           VARCHAR2 (3);
      l_short_name      VARCHAR2 (100);
      l_pwd             VARCHAR2 (100);
   BEGIN
      BEGIN
         SELECT DISTINCT SZTALGO_TERM_CODE_NEW,
                         SZTALGO_PTRM_CODE_NEW,
                         SZTALGO_CAMP_CODE,
                         SZTALGO_LEVL_CODE
           INTO l_periodo,
                l_parte_periodo,
                l_campus,
                l_nivel
           FROM SZTALGO
          WHERE 1 = 1 AND SZTALGO_NO_REGLA = P_REGLA;
      EXCEPTION
         WHEN OTHERS
         THEN
            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,
                            SZTALGO_PTRM_CODE_NEW,
                            SZTALGO_CAMP_CODE,
                            SZTALGO_LEVL_CODE
              INTO l_periodo,
                   l_parte_periodo,
                   l_campus,
                   l_nivel
              FROM SZTALGO
             WHERE 1 = 1 AND SZTALGO_NO_REGLA = P_REGLA AND ROWNUM = 1;
      END;

      BEGIN
         SELECT    DECODE (SUBSTR (l_periodo, 1, 2),
                           '02', '01',
                           SUBSTR (l_periodo, 1, 2))
                || SUBSTR (l_periodo, 3, 5)
                   dato
           INTO l_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;


      BEGIN
         SELECT    DECODE (SUBSTR (l_parte_periodo, 1, 1),
                           'A', 'M',
                           SUBSTR (l_parte_periodo, 1, 1))
                || SUBSTR (l_parte_periodo, 2, 4)
                   dato
           INTO l_parte_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         SELECT    DECODE (SUBSTR (l_parte_periodo, 1, 2),
                           '02', '01',
                           SUBSTR (l_parte_periodo, 1, 2))
                || SUBSTR (l_parte_periodo, 3, 5)
                   dato
           INTO l_parte_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;


      BEGIN
         SELECT spriden_pidm
           INTO l_pidm_prof
           FROM spriden
          WHERE     1 = 1
                AND spriden_change_ind IS NULL
                AND spriden_id = p_prof_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;


      BEGIN
         INSERT INTO sirasgn
              VALUES (l_periodo,
                      p_crn,
                      l_pidm_prof,
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
                      'UTEL',
                      'PRONOSTICO',
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL);

         l_retorna := 'EXITO';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_retorna := 'Error al insertar sirasgn ' || SQLERRM;
      END;


      RETURN (l_retorna);
   END;

   --
   --
   FUNCTION f_alumno_manual (p_periodo          VARCHAR2,
                             p_parte            VARCHAR2,
                             p_pidm             NUMBER,
                             p_crn              VARCHAR2,
                             p_inicio_clases    VARCHAR2,
                             p_regla            NUMBER,
                             p_grupo            VARCHAR2,
                             p_materia          VARCHAR2)
      RETURN VARCHAR2
   IS
      l_retorna         VARCHAR2 (100);
      l_grupo_max       NUMBER;
      l_pidm_prof       NUMBER;
      l_crn             VARCHAR2 (100);
      l_periodo         VARCHAR2 (100);
      l_parte_periodo   VARCHAR2 (3);
      l_campus          VARCHAR2 (3);
      schd              VARCHAR2 (3);
      title             VARCHAR2 (100);
      credit            NUMBER;
      credit_bill       NUMBER;
      gmod              NUMBER;
      f_inicio          DATE;
      f_fin             DATE;
      sem               NUMBER;
      l_term_nrc        VARCHAR2 (30);
      l_nivel           VARCHAR2 (3);
      l_short_name      VARCHAR2 (100);
      l_pwd             VARCHAR2 (100);
   BEGIN
      BEGIN
         SELECT DISTINCT SZTALGO_TERM_CODE_NEW,
                         SZTALGO_PTRM_CODE_NEW,
                         SZTALGO_CAMP_CODE,
                         SZTALGO_LEVL_CODE
           INTO l_periodo,
                l_parte_periodo,
                l_campus,
                l_nivel
           FROM SZTALGO
          WHERE 1 = 1 AND SZTALGO_NO_REGLA = P_REGLA;
      EXCEPTION
         WHEN OTHERS
         THEN
            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,
                            SZTALGO_PTRM_CODE_NEW,
                            SZTALGO_CAMP_CODE,
                            SZTALGO_LEVL_CODE
              INTO l_periodo,
                   l_parte_periodo,
                   l_campus,
                   l_nivel
              FROM SZTALGO
             WHERE 1 = 1 AND SZTALGO_NO_REGLA = P_REGLA AND ROWNUM = 1;
      END;

      BEGIN
         SELECT    DECODE (SUBSTR (l_periodo, 1, 2),
                           '02', '01',
                           SUBSTR (l_periodo, 1, 2))
                || SUBSTR (l_periodo, 3, 5)
                   dato
           INTO l_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;


      BEGIN
         SELECT    DECODE (SUBSTR (l_parte_periodo, 1, 1),
                           'A', 'M',
                           SUBSTR (l_parte_periodo, 1, 1))
                || SUBSTR (l_parte_periodo, 2, 4)
                   dato
           INTO l_parte_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         SELECT    DECODE (SUBSTR (l_parte_periodo, 1, 2),
                           '02', '01',
                           SUBSTR (l_parte_periodo, 1, 2))
                || SUBSTR (l_parte_periodo, 3, 5)
                   dato
           INTO l_parte_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      IF p_crn != '00' AND p_crn IS NOT NULL
      THEN
         BEGIN
            INSERT INTO sfrstcr
                 VALUES (p_periodo,                        --SFRSTCR_TERM_CODE
                         p_pidm,                                --SFRSTCR_PIDM
                         p_crn,                                  --SFRSTCR_CRN
                         1,                           --SFRSTCR_CLASS_SORT_KEY
                         p_grupo,                            --SFRSTCR_REG_SEQ
                         p_parte,                          --SFRSTCR_PTRM_CODE
                         'RE',                             --SFRSTCR_RSTS_CODE
                         SYSDATE,                          --SFRSTCR_RSTS_DATE
                         NULL,                            --SFRSTCR_ERROR_FLAG
                         NULL,                               --SFRSTCR_MESSAGE
                         credit_bill,                        --SFRSTCR_BILL_HR
                         3,                                  --SFRSTCR_WAIV_HR
                         NULL,                   --credit, --SFRSTCR_CREDIT_HR
                         NULL,           --credit_bill, --SFRSTCR_BILL_HR_HOLD
                         NULL,              --credit, --SFRSTCR_CREDIT_HR_HOLD
                         NULL,                     --gmod, --SFRSTCR_GMOD_CODE
                         NULL,                             --SFRSTCR_GRDE_CODE
                         NULL,                         --SFRSTCR_GRDE_CODE_MID
                         NULL,                             --SFRSTCR_GRDE_DATE
                         'N',                              --SFRSTCR_DUPL_OVER
                         'N',                              --SFRSTCR_LINK_OVER
                         'N',                              --SFRSTCR_CORQ_OVER
                         'N',                              --SFRSTCR_PREQ_OVER
                         'N',                              --SFRSTCR_TIME_OVER
                         'N',                              --SFRSTCR_CAPC_OVER
                         'N',                              --SFRSTCR_LEVL_OVER
                         'N',                              --SFRSTCR_COLL_OVER
                         'N',                              --SFRSTCR_MAJR_OVER
                         'N',                              --SFRSTCR_CLAS_OVER
                         'N',                              --SFRSTCR_APPR_OVER
                         'N',                      --SFRSTCR_APPR_RECEIVED_IND
                         SYSDATE,                           --SFRSTCR_ADD_DATE
                         SYSDATE,                      --SFRSTCR_ACTIVITY_DATE
                         l_nivel,                          --SFRSTCR_LEVL_CODE
                         l_campus,                         --SFRSTCR_CAMP_CODE
                         p_materia,                     --SFRSTCR_RESERVED_KEY
                         NULL,                             --SFRSTCR_ATTEND_HR
                         'Y',                              --SFRSTCR_REPT_OVER
                         'N',                              --SFRSTCR_RPTH_OVER
                         NULL,                             --SFRSTCR_TEST_OVER
                         'N',                              --SFRSTCR_CAMP_OVER
                         USER,                                  --SFRSTCR_USER
                         'N',                              --SFRSTCR_DEGC_OVER
                         'N',                              --SFRSTCR_PROG_OVER
                         NULL,                           --SFRSTCR_LAST_ATTEND
                         NULL,                             --SFRSTCR_GCMT_CODE
                         'PRONOSTICO ' || p_regla,       --SFRSTCR_DATA_ORIGIN
                         SYSDATE,               --SFRSTCR_ASSESS_ACTIVITY_DATE
                         'N',                              --SFRSTCR_DEPT_OVER
                         'N',                              --SFRSTCR_ATTS_OVER
                         'N',                              --SFRSTCR_CHRT_OVER
                         p_grupo,                           --SFRSTCR_RMSG_CDE
                         NULL,                           --SFRSTCR_WL_PRIORITY
                         NULL,                      --SFRSTCR_WL_PRIORITY_ORIG
                         NULL,                 --SFRSTCR_GRDE_CODE_INCMP_FINAL
                         NULL,                   --SFRSTCR_INCOMPLETE_EXT_DATE
                         'N',                              --SFRSTCR_MEXC_OVER
                         1,                        --SFRSTCR_STSP_KEY_SEQUENCE
                         NULL,                          --SFRSTCR_BRDH_SEQ_NUM
                         '01',                             --SFRSTCR_BLCK_CODE
                         NULL,                            --SFRSTCR_STRH_SEQNO
                         NULL,                            --SFRSTCR_STRD_SEQNO
                         NULL,                          --SFRSTCR_SURROGATE_ID
                         NULL,                               --SFRSTCR_VERSION
                         USER,                               --SFRSTCR_USER_ID
                         NULL                              --SFRSTCR_VPDI_CODE
                             );

            l_retorna := 'EXITO';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_retorna := ('Error al insertar SFRSTCR ' || SQLERRM);
         END;
      ELSE
         l_retorna := ('Esta grupo no tiene CRN en Banner verifica ');
      END IF;

      RETURN (l_retorna);
   END;

   --
   --
   FUNCTION f_agrega_crn (p_periodo          VARCHAR2,
                          p_parte            VARCHAR2,
                          p_pidm             NUMBER,
                          p_inicio_clases    VARCHAR2,
                          p_regla            NUMBER,
                          p_grupo            VARCHAR2,
                          p_materia          VARCHAR2,
                          p_subj             VARCHAR2,
                          p_numb             VARCHAR2)
      RETURN VARCHAR2
   IS
      l_retorna         VARCHAR (200);
      l_grupo_max       NUMBER;
      l_pidm_prof       NUMBER;
      l_crn             VARCHAR (200);
      l_periodo         VARCHAR2 (100);
      l_parte_periodo   VARCHAR2 (3);
      l_campus          VARCHAR2 (3);
      schd              VARCHAR2 (3);
      title             VARCHAR2 (100);
      credit            NUMBER;
      credit_bill       NUMBER;
      gmod              NUMBER;
      f_inicio          DATE;
      f_fin             DATE;
      sem               NUMBER;
      l_term_nrc        VARCHAR2 (30);
      l_nivel           VARCHAR2 (3);
      l_short_name      VARCHAR2 (100);
      l_pwd             VARCHAR2 (100);
      l_order           NUMBER;
      l_programa        VARCHAR2 (100);
      l_matricula       VARCHAR2 (9);
      l_valida          NUMBER;
   BEGIN
      pkg_algoritmo.P_ENA_DIS_TRG ('D', 'SATURN.SZT_SSBSECT_POSTINSERT_ROW');
      pkg_algoritmo.P_ENA_DIS_TRG ('D', 'SATURN.SZT_SIRASGN_POSTINSERT_ROW');
      pkg_algoritmo.P_ENA_DIS_TRG ('D',
                                   'SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');

      BEGIN
         SELECT DISTINCT SZTALGO_TERM_CODE_NEW,
                         SZTALGO_PTRM_CODE_NEW,
                         SZTALGO_CAMP_CODE,
                         SZTALGO_LEVL_CODE
           INTO l_periodo,
                l_parte_periodo,
                l_campus,
                l_nivel
           FROM SZTALGO
          WHERE 1 = 1 AND SZTALGO_NO_REGLA = P_REGLA;
      EXCEPTION
         WHEN OTHERS
         THEN
            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,
                            SZTALGO_PTRM_CODE_NEW,
                            SZTALGO_CAMP_CODE,
                            SZTALGO_LEVL_CODE
              INTO l_periodo,
                   l_parte_periodo,
                   l_campus,
                   l_nivel
              FROM SZTALGO
             WHERE 1 = 1 AND SZTALGO_NO_REGLA = P_REGLA AND ROWNUM = 1;
      END;

      BEGIN
         SELECT    DECODE (SUBSTR (l_periodo, 1, 2),
                           '02', '01',
                           SUBSTR (l_periodo, 1, 2))
                || SUBSTR (l_periodo, 3, 5)
                   dato
           INTO l_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;


      BEGIN
         SELECT    DECODE (SUBSTR (l_parte_periodo, 1, 1),
                           'A', 'M',
                           SUBSTR (l_parte_periodo, 1, 1))
                || SUBSTR (l_parte_periodo, 2, 4)
                   dato
           INTO l_parte_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         SELECT    DECODE (SUBSTR (l_parte_periodo, 1, 2),
                           '02', '01',
                           SUBSTR (l_parte_periodo, 1, 2))
                || SUBSTR (l_parte_periodo, 3, 5)
                   dato
           INTO l_parte_periodo
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         SELECT NVL (MAX (ssbsect_crn), 1000) + 1
           INTO l_crn
           FROM ssbsect
          WHERE 1 = 1 AND ssbsect_term_code = l_periodo;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_crn := NULL;
      END;


      BEGIN
         SELECT scrschd_schd_code,
                scbcrse_title,
                scbcrse_credit_hr_low,
                scbcrse_bill_hr_low
           INTO schd,
                title,
                credit,
                credit_bill
           FROM scbcrse, scrschd
          WHERE     1 = 1
                AND scbcrse_subj_code = p_subj
                AND scbcrse_crse_numb = p_numb
                AND scbcrse_eff_term = '000000'
                AND scrschd_subj_code = scbcrse_subj_code
                AND scrschd_crse_numb = scbcrse_crse_numb
                AND scrschd_eff_term = scbcrse_eff_term;
      EXCEPTION
         WHEN OTHERS
         THEN
            schd := NULL;
            title := NULL;
            credit := NULL;
            credit_bill := NULL;
      END;

      BEGIN
         SELECT scrgmod_gmod_code
           INTO gmod
           FROM scrgmod
          WHERE     1 = 1
                AND scrgmod_subj_code = p_subj
                AND scrgmod_crse_numb = p_numb
                AND scrgmod_default_ind = 'D';
      EXCEPTION
         WHEN OTHERS
         THEN
            gmod := '1';
      END;


      BEGIN
         SELECT DISTINCT sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
           INTO f_inicio, f_fin, sem
           FROM sobptrm
          WHERE     1 = 1
                AND sobptrm_term_code = l_periodo
                AND sobptrm_ptrm_code = l_parte_periodo;
      EXCEPTION
         WHEN OTHERS
         THEN
            -- vl_error := 'No se Encontro configuracion para el Periodo= ' ||c.periodo ||' y Parte de Periodo= '||c.parte ||SQLERRM;
            NULL;
      END;

      BEGIN
         SELECT DISTINCT sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
           INTO f_inicio, f_fin, sem
           FROM sobptrm
          WHERE     1 = 1
                AND sobptrm_term_code = l_periodo
                AND sobptrm_ptrm_code = l_parte_periodo;
      EXCEPTION
         WHEN OTHERS
         THEN
            --vl_error := 'No se Encontro configuracion para el Periodo= ' ||c.periodo ||' y Parte de Periodo= '||c.parte ||SQLERRM;
            NULL;
      END;


      IF l_campus = 'UTS'
      THEN
         l_campus := 'UTL';
      END IF;

      BEGIN
         SELECT NVL (MAX (crn), 1000) + 1
           INTO l_crn
           FROM (SELECT CASE
                           WHEN SUBSTR (SSBSECT_CRN, 1, 1) IN ('L',
                                                               'M',
                                                               'D',
                                                               'A')
                           THEN
                              TO_NUMBER (SUBSTR (SSBSECT_CRN, 2, 100)) + 1
                           ELSE
                              TO_NUMBER (SSBSECT_CRN)
                        END
                           crn
                   FROM ssbsect
                  WHERE ssbsect_term_code = l_periodo);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_crn := NULL;
      END;


      IF l_nivel = 'LI'
      THEN
         l_crn := 'L' || l_crn;
      ELSE
         l_crn := 'M' || l_crn;
      END IF;

      BEGIN
         SELECT SZTPRONO_PROGRAM
           INTO l_programa
           FROM sztprono
          WHERE     1 = 1
                AND sztprono_no_regla = p_regla
                AND sztprono_pidm = p_pidm
                AND ROWNUM = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_programa := NULL;
      END;

      BEGIN
         SELECT spriden_id
           INTO l_matricula
           FROM spriden
          WHERE     1 = 1
                AND spriden_change_ind IS NULL
                AND spriden_pidm = p_pidm;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      BEGIN
         SELECT COUNT (*)
           INTO l_valida
           FROM tztordr
          WHERE     1 = 1
                AND TZTORDR_CAMPUS = l_campus
                AND TZTORDR_NIVEL = l_nivel
                AND TZTORDR_PROGRAMA = l_programa
                AND TZTORDR_FECHA_INICIO = p_inicio_clases
                AND TZTORDR_TERM_CODE = l_periodo
                AND TZTORDR_PIDM = p_pidm
                AND TZTORDR_ESTATUS = 'N';
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;


      IF l_valida = 0
      THEN
         BEGIN
            SELECT COUNT (*) + 1
              INTO l_order
              FROM tztordr
             WHERE     1 = 1
                   AND TZTORDR_CAMPUS = l_campus
                   AND TZTORDR_NIVEL = l_nivel
                   AND TZTORDR_PROGRAMA = l_programa
                   AND TZTORDR_FECHA_INICIO = p_inicio_clases
                   AND TZTORDR_TERM_CODE = l_periodo
                   AND TZTORDR_PIDM = p_pidm;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;


         BEGIN
            INSERT INTO TZTORDR
                 VALUES (l_campus,
                         l_nivel,
                         l_order,
                         l_programa,
                         p_pidm,
                         l_matricula,
                         'S',
                         SYSDATE,
                         USER,
                         'PRONOSTICO',
                         p_regla,
                         p_inicio_clases,
                         NULL,
                         NULL,
                         NULL,
                         l_periodo);
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.put_line ('Error al insertar TZTORDR ' || SQLERRM);
         END;
      END IF;

      BEGIN
         INSERT INTO ssbsect
              VALUES (l_periodo,                           --SSBSECT_TERM_CODE
                      l_crn,                                     --SSBSECT_CRN
                      l_parte_periodo,                     --SSBSECT_PTRM_CODE
                      p_subj,                              --SSBSECT_SUBJ_CODE
                      p_numb,                              --SSBSECT_CRSE_NUMB
                      p_grupo,                              --SSBSECT_SEQ_NUMB
                      'A',                                 --SSBSECT_SSTS_CODE
                      'ENL',                               --SSBSECT_SCHD_CODE
                      l_campus,                            --SSBSECT_CAMP_CODE
                      title,                              --SSBSECT_CRSE_TITLE
                      credit,                             --SSBSECT_CREDIT_HRS
                      credit_bill,                          --SSBSECT_BILL_HRS
                      gmod,                                --SSBSECT_GMOD_CODE
                      NULL,                                --SSBSECT_SAPR_CODE
                      NULL,                                --SSBSECT_SESS_CODE
                      NULL,                               --SSBSECT_LINK_IDENT
                      NULL,                                 --SSBSECT_PRNT_IND
                      'Y',                              --SSBSECT_GRADABLE_IND
                      NULL,                                 --SSBSECT_TUIW_IND
                      0,                                   --SSBSECT_REG_ONEUP
                      0,                                  --SSBSECT_PRIOR_ENRL
                      0,                                   --SSBSECT_PROJ_ENRL
                      90,                                   --SSBSECT_MAX_ENRL
                      0,                                        --SSBSECT_ENRL
                      50,                                --SSBSECT_SEATS_AVAIL
                      NULL,                           --SSBSECT_TOT_CREDIT_HRS
                      '0',                               --SSBSECT_CENSUS_ENRL
                      f_inicio,                     --SSBSECT_CENSUS_ENRL_DATE
                      SYSDATE,                         --SSBSECT_ACTIVITY_DATE
                      p_inicio_clases,               --SSBSECT_PTRM_START_DATE
                      f_fin,                           --SSBSECT_PTRM_END_DATE
                      sem,                                --SSBSECT_PTRM_WEEKS
                      NULL,                             --SSBSECT_RESERVED_IND
                      NULL,                            --SSBSECT_WAIT_CAPACITY
                      NULL,                               --SSBSECT_WAIT_COUNT
                      NULL,                               --SSBSECT_WAIT_AVAIL
                      NULL,                                   --SSBSECT_LEC_HR
                      NULL,                                   --SSBSECT_LAB_HR
                      NULL,                                   --SSBSECT_OTH_HR
                      NULL,                                  --SSBSECT_CONT_HR
                      NULL,                                --SSBSECT_ACCT_CODE
                      NULL,                                --SSBSECT_ACCL_CODE
                      NULL,                            --SSBSECT_CENSUS_2_DATE
                      NULL,                        --SSBSECT_ENRL_CUT_OFF_DATE
                      NULL,                        --SSBSECT_ACAD_CUT_OFF_DATE
                      NULL,                        --SSBSECT_DROP_CUT_OFF_DATE
                      NULL,                            --SSBSECT_CENSUS_2_ENRL
                      'Y',                               --SSBSECT_VOICE_AVAIL
                      'N',                      --SSBSECT_CAPP_PREREQ_TEST_IND
                      NULL,                                --SSBSECT_GSCH_NAME
                      NULL,                             --SSBSECT_BEST_OF_COMP
                      NULL,                           --SSBSECT_SUBSET_OF_COMP
                      'NOP',                               --SSBSECT_INSM_CODE
                      NULL,                            --SSBSECT_REG_FROM_DATE
                      NULL,                              --SSBSECT_REG_TO_DATE
                      NULL,                   --SSBSECT_LEARNER_REGSTART_FDATE
                      NULL,                   --SSBSECT_LEARNER_REGSTART_TDATE
                      NULL,                                --SSBSECT_DUNT_CODE
                      NULL,                          --SSBSECT_NUMBER_OF_UNITS
                      0,                        --SSBSECT_NUMBER_OF_EXTENSIONS
                      'PRONOSTICO ' || p_regla,          --SSBSECT_DATA_ORIGIN
                      USER,                                  --SSBSECT_USER_ID
                      'MOOD',                               --SSBSECT_INTG_CDE
                      'B',                     --SSBSECT_PREREQ_CHK_METHOD_CDE
                      USER,                         --SSBSECT_KEYWORD_INDEX_ID
                      NULL,                          --SSBSECT_SCORE_OPEN_DATE
                      NULL,                        --SSBSECT_SCORE_CUTOFF_DATE
                      NULL,                     --SSBSECT_REAS_SCORE_OPEN_DATE
                      NULL,                     --SSBSECT_REAS_SCORE_CTOF_DATE
                      NULL,                             --SSBSECT_SURROGATE_ID
                      NULL,                                  --SSBSECT_VERSION
                      NULL                                 --SSBSECT_VPDI_CODE
                          );

         l_retorna := 'EXITO';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_retorna := 'Error al insertar ssbsect ' || SQLERRM;
      END;

      BEGIN
         INSERT INTO sirasgn
              VALUES (l_periodo,
                      l_crn,
                      l_pidm_prof,
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
                      'UTEL',
                      'PRONOSTICO ' || p_regla,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL);

         l_retorna := 'EXITO';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_retorna := 'Error al insertar sirasgn ' || SQLERRM;
      END;

      BEGIN
         INSERT INTO sfrstcr
              VALUES (p_periodo,                           --SFRSTCR_TERM_CODE
                      p_pidm,                                   --SFRSTCR_PIDM
                      l_crn,                                     --SFRSTCR_CRN
                      1,                              --SFRSTCR_CLASS_SORT_KEY
                      p_grupo,                               --SFRSTCR_REG_SEQ
                      p_parte,                             --SFRSTCR_PTRM_CODE
                      'RE',                                --SFRSTCR_RSTS_CODE
                      SYSDATE,                             --SFRSTCR_RSTS_DATE
                      NULL,                               --SFRSTCR_ERROR_FLAG
                      NULL,                                  --SFRSTCR_MESSAGE
                      credit_bill,                           --SFRSTCR_BILL_HR
                      3,                                     --SFRSTCR_WAIV_HR
                      NULL,                      --credit, --SFRSTCR_CREDIT_HR
                      NULL,              --credit_bill, --SFRSTCR_BILL_HR_HOLD
                      NULL,                 --credit, --SFRSTCR_CREDIT_HR_HOLD
                      NULL,                        --gmod, --SFRSTCR_GMOD_CODE
                      NULL,                                --SFRSTCR_GRDE_CODE
                      NULL,                            --SFRSTCR_GRDE_CODE_MID
                      NULL,                                --SFRSTCR_GRDE_DATE
                      'N',                                 --SFRSTCR_DUPL_OVER
                      'N',                                 --SFRSTCR_LINK_OVER
                      'N',                                 --SFRSTCR_CORQ_OVER
                      'N',                                 --SFRSTCR_PREQ_OVER
                      'N',                                 --SFRSTCR_TIME_OVER
                      'N',                                 --SFRSTCR_CAPC_OVER
                      'N',                                 --SFRSTCR_LEVL_OVER
                      'N',                                 --SFRSTCR_COLL_OVER
                      'N',                                 --SFRSTCR_MAJR_OVER
                      'N',                                 --SFRSTCR_CLAS_OVER
                      'N',                                 --SFRSTCR_APPR_OVER
                      'N',                         --SFRSTCR_APPR_RECEIVED_IND
                      SYSDATE,                              --SFRSTCR_ADD_DATE
                      SYSDATE,                         --SFRSTCR_ACTIVITY_DATE
                      l_nivel,                             --SFRSTCR_LEVL_CODE
                      l_campus,                            --SFRSTCR_CAMP_CODE
                      p_materia,                        --SFRSTCR_RESERVED_KEY
                      NULL,                                --SFRSTCR_ATTEND_HR
                      'Y',                                 --SFRSTCR_REPT_OVER
                      'N',                                 --SFRSTCR_RPTH_OVER
                      NULL,                                --SFRSTCR_TEST_OVER
                      'N',                                 --SFRSTCR_CAMP_OVER
                      USER,                                     --SFRSTCR_USER
                      'N',                                 --SFRSTCR_DEGC_OVER
                      'N',                                 --SFRSTCR_PROG_OVER
                      NULL,                              --SFRSTCR_LAST_ATTEND
                      NULL,                                --SFRSTCR_GCMT_CODE
                      'PRONOSTICO ' || p_regla,          --SFRSTCR_DATA_ORIGIN
                      SYSDATE,                  --SFRSTCR_ASSESS_ACTIVITY_DATE
                      'N',                                 --SFRSTCR_DEPT_OVER
                      'N',                                 --SFRSTCR_ATTS_OVER
                      'N',                                 --SFRSTCR_CHRT_OVER
                      p_grupo,                              --SFRSTCR_RMSG_CDE
                      NULL,                              --SFRSTCR_WL_PRIORITY
                      NULL,                         --SFRSTCR_WL_PRIORITY_ORIG
                      NULL,                    --SFRSTCR_GRDE_CODE_INCMP_FINAL
                      NULL,                      --SFRSTCR_INCOMPLETE_EXT_DATE
                      'N',                                 --SFRSTCR_MEXC_OVER
                      1,                           --SFRSTCR_STSP_KEY_SEQUENCE
                      NULL,                             --SFRSTCR_BRDH_SEQ_NUM
                      '01',                                --SFRSTCR_BLCK_CODE
                      NULL,                               --SFRSTCR_STRH_SEQNO
                      NULL,                               --SFRSTCR_STRD_SEQNO
                      NULL,                             --SFRSTCR_SURROGATE_ID
                      NULL,                                  --SFRSTCR_VERSION
                      USER,                                  --SFRSTCR_USER_ID
                      NULL                                 --SFRSTCR_VPDI_CODE
                          );

         l_retorna := 'EXITO';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_retorna := ('Error al insertar SFRSTCR ' || SQLERRM);
      END;

      pkg_algoritmo.P_ENA_DIS_TRG ('E', 'SATURN.SZT_SSBSECT_POSTINSERT_ROW');
      pkg_algoritmo.P_ENA_DIS_TRG ('E', 'SATURN.SZT_SIRASGN_POSTINSERT_ROW');
      pkg_algoritmo.P_ENA_DIS_TRG ('E',
                                   'SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');

      COMMIT;

      RETURN (l_retorna);
   END;

   --
   --

   FUNCTION f_reasigna_prof (p_pidm            NUMBER,
                             p_fecha_inicio    VARCHAR2,
                             p_materia         VARCHAR2,
                             p_grupo           VARCHAR2)
      RETURN VARCHAR2
   IS
      l_retorna   VARCHAR2 (200) := 'EXITO';
      l_valida    NUMBER;
   BEGIN
      BEGIN
         SELECT COUNT (*)
           INTO l_valida
           FROM sirasgn
          WHERE     1 = 1
                AND (SIRASGN_TERM_CODE, sirasgn_crn) IN (SELECT SSBSECT_TERM_CODE,
                                                                SSBSECT_CRN
                                                           FROM ssbsect
                                                          WHERE        SSBSECT_SUBJ_CODE
                                                                    || SSBSECT_CRSE_NUMB IN (SELECT SZTMACO_MATHIJO
                                                                                               FROM sztmaco
                                                                                              WHERE SZTMACO_MATPADRE =
                                                                                                       p_materia)
                                                                AND SSBSECT_PTRM_START_DATE =
                                                                       TO_DATE (
                                                                          p_fecha_inicio,
                                                                          'DD/MM/YYYY')
                                                                AND SSBSECT_SEQ_NUMB =
                                                                       p_grupo)
                AND SIRASGN_PIDM = p_pidm;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_valida := 0;
      END;


      IF l_valida > 0
      THEN
         BEGIN
            UPDATE sirasgn
               SET SIRASGN_PRIMARY_IND = 'N'
             WHERE     1 = 1
                   AND (SIRASGN_TERM_CODE, sirasgn_crn) IN (SELECT SSBSECT_TERM_CODE,
                                                                   SSBSECT_CRN
                                                              FROM ssbsect
                                                             WHERE        SSBSECT_SUBJ_CODE
                                                                       || SSBSECT_CRSE_NUMB IN (SELECT SZTMACO_MATHIJO
                                                                                                  FROM sztmaco
                                                                                                 WHERE SZTMACO_MATPADRE =
                                                                                                          p_materia)
                                                                   AND SSBSECT_PTRM_START_DATE =
                                                                          TO_DATE (
                                                                             p_fecha_inicio,
                                                                             'DD/MM/YYYY')
                                                                   AND SSBSECT_SEQ_NUMB =
                                                                          p_grupo)
                   AND SIRASGN_PIDM = p_pidm;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_retorna :=
                     'Error al actualizar profesor pidm '
                  || p_pidm
                  || ' ora error '
                  || SQLERRM;
         END;

         COMMIT;
      ELSE
         l_retorna := 'No existen registos para actualizar ';
      END IF;

      RETURN (l_retorna);
   END;

   --
   --
   FUNCTION f_grupo_moodl (p_inicio_clase IN VARCHAR2, p_regla IN NUMBER)
      RETURN VARCHAR2
   AS
      l_retorna          VARCHAR2 (1000);
      l_contar           NUMBER;
      l_conse            NUMBER;
      l_materia          VARCHAR2 (15);
      l_desripcion_mat   VARCHAR2 (500);
      l_campus           VARCHAR2 (15);
      l_nivel            VARCHAR2 (15);
      l_parte_perido     VARCHAR2 (15);
      l_term_code        VARCHAR2 (15);
      l_regla_cerrada    VARCHAR2 (1);
      l_short_name       VARCHAR2 (250);
      l_grupo_moodl      VARCHAR2 (15);
      l_grupo            VARCHAR2 (5);
      l_secuencia        NUMBER := NULL;
      vl_materia         VARCHAR2 (15);
      vl_cont_reza       NUMBER := 0;
      l_contador         NUMBER := 0;
      l_Sql              VARCHAR2 (2000);
      L_DIPLO_EXCLUIR    NUMBER;
   BEGIN
      DBMS_OUTPUT.put_line (' entramos ');

      BEGIN
         SELECT DISTINCT sztalgo_estatus_cerrado
           INTO l_regla_cerrada
           FROM sztalgo
          WHERE 1 = 1 AND sztalgo_no_regla = p_regla;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      IF l_regla_cerrada = 'S'
      THEN
         DBMS_OUTPUT.put_line (' entramos 1 ');

         FOR c
            IN (SELECT materia,
                       pidm,
                       matricula,
                       maximo,
                       CASE
                          WHEN LENGTH (grupo) = 2 THEN grupo
                          WHEN LENGTH (grupo) = 1 THEN TO_CHAR ('0' || grupo)
                       END
                          GRUPO,
                       secuencia,
                       grupo grupo2,
                       estatus,
                       mat_conv
                  FROM (SELECT sztconf_subj_code materia,
                               sztconf_pidm pidm,
                               sztconf_id matricula,
                               70 maximo,
                               -- TO_CHAR(ROW_NUMBER() OVER (PARTITION BY sztconf_subj_code ORDER BY sztconf_group)) grupo,
                               TO_CHAR (SZTCONF_GROUP) grupo,
                               SZTCONF_SECUENCIA secuencia,
                               sztconf_estatus_cerrado estatus,
                               (SELECT    SZTCOMA_SUBJ_CODE_ADM
                                       || SZTCOMA_CRSE_NUMB_ADM
                                  FROM SZTCOMA
                                 WHERE    SZTCOMA_SUBJ_CODE_BAN
                                       || SZTCOMA_CRSE_NUMB_BAN =
                                          a.sztconf_subj_code)
                                  mat_conv
                          FROM sztconf a
                         WHERE     1 = 1
                               AND sztconf_no_regla = p_regla
                               AND SZTCONF_ESTATUS_CERRADO = 'N'-- and SZTCONF_SUBJ_CODE in  (select distinct SZTPRONO_MATERIA_LEGAL
                                                                --                                                        from sztprono
                                                                --                                                        where 1=1
                                                                --                                                          and sztprono_no_regla=312
                                                                --                                                         and SZTPRONO_PROGRAM not in ( select ZSTPARA_PARAM_ID
                                                                --                                                            from zstpara
                                                                --                                                            where 1=1
                                                                --                                                            and ZSTPARA_MAPA_ID='DIPLO_EXCLUIR'))
                       ) x
                 WHERE 1 = 1-- and materia ='M1ED102'
               )
         LOOP
            DBMS_OUTPUT.put_line (' entramos 2');

            vl_cont_reza := vl_cont_reza + 1;

            vl_materia := NULL;

            IF c.mat_conv IS NULL
            THEN
               vl_materia := c.materia;
            ELSE
               vl_materia := c.mat_conv;
            END IF;

            DBMS_OUTPUT.put_line ('entra 1');

            BEGIN
               SELECT UPPER (scrsyln_long_course_title)
                 INTO l_desripcion_mat
                 FROM scrsyln
                WHERE     1 = 1
                      AND scrsyln_subj_code || scrsyln_crse_numb = c.materia;
            EXCEPTION
               WHEN OTHERS
               THEN
                  DBMS_OUTPUT.put_line (' Error en SCRSYLN ' || SQLERRM);
                  l_retorna :=
                        ' No se econtro descripcion para materia '
                     || c.materia
                     || ' '
                     || SQLERRM;
            END;

            BEGIN
               SELECT DISTINCT sztalgo_camp_code, sztalgo_levl_code
                 INTO l_campus, l_nivel
                 FROM sztalgo
                WHERE 1 = 1 AND sztalgo_no_regla = p_regla AND ROWNUM = 1;

               IF l_campus = 'UTS'
               THEN
                  l_campus := 'UTL';
               END IF;

               IF l_nivel = 'MS'
               THEN
                  l_nivel := 'MA';
               END IF;

               IF l_nivel = 'LI'
               THEN
                  l_nivel := 'LI';
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

            BEGIN
               SELECT CASE
                         WHEN LENGTH (grupo) = 2 THEN grupo
                         WHEN LENGTH (grupo) = 1 THEN '0' || TO_CHAR (grupo)
                      END
                         GRUPO
                 INTO l_grupo
                 FROM (SELECT TO_CHAR (NVL (COUNT (*), 0) + 1) grupo
                         FROM szstume
                        WHERE     1 = 1
                              AND szstume_no_regla = p_regla
                              AND SZSTUME_SUBJ_CODE = c.materia);
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_grupo := 0;
            END;


            DBMS_OUTPUT.put_line (' Nivel ' || l_nivel);

            IF l_nivel NOT IN ( 'EC','ID')
            THEN
               FOR x
                  IN (  SELECT DISTINCT
                               DECODE (
                                  SUBSTR (SZTALGO_TERM_CODE_NEW, 1, 2),
                                  '02',    '01'
                                        || SUBSTR (SZTALGO_TERM_CODE_NEW, 3, 5),
                                  SZTALGO_TERM_CODE_NEW)
                                  periodo,
                               DECODE (
                                  SUBSTR (SZTALGO_PTRM_CODE_NEW, 1, 1),
                                  'A',    'M'
                                       || SUBSTR (SZTALGO_PTRM_CODE_NEW, 2, 3),
                                  SZTALGO_PTRM_CODE_NEW)
                                  ptrm,
                               SZTALGO_FECHA_NEW fecha_inicio
                          FROM sztalgo
                         WHERE     1 = 1
                               AND sztalgo_no_regla = p_regla
                               AND SZTALGO_FECHA_NEW =
                                      (SELECT MAX (SZTALGO_FECHA_NEW)
                                         FROM sztalgo
                                        WHERE     1 = 1
                                              AND sztalgo_no_regla = p_regla)
                      ORDER BY 2 DESC)
               LOOP
                  l_short_name :=
                     f_get_short_name (x.ptrm,
                                       x.periodo,
                                       c.materia,
                                       x.fecha_inicio);

                  --
                  -- l_Sql :=' INSERT INTO sztgpme VALUES ('||c.materia||c.grupo||','||
                  -- CHR(39)||c.materia||CHR(39)||','||
                  -- CHR(39)||l_desripcion_mat||CHR(39)||','||
                  -- 5||','||
                  -- NULL||','||
                  -- USER||','||
                  -- SYSDATE||','||
                  -- x.ptrm||','||
                  -- x.fecha_inicio||','||
                  -- l_nivel||','||
                  -- c.maximo||','||--number
                  -- l_nivel ||','||
                  -- l_campus||','||
                  -- NULL||','||--number
                  -- c.materia||','||
                  -- NULL||','||
                  -- x.periodo||','||
                  -- NULL||','||
                  -- NULL||','||
                  -- NULL||','||-- number
                  -- l_short_name||','||
                  -- p_regla||','||-- number
                  -- l_secuencia||','||-- number
                  -- c.grupo2||','||-- number
                  -- 'S'||','||
                  -- 1||','--number
                  ------ ||')';

                  BEGIN
                     INSERT INTO sztgpme
                          VALUES (c.materia || c.grupo,
                                  c.materia,
                                  l_desripcion_mat,
                                  5,
                                  NULL,
                                  USER,
                                  SYSDATE,
                                  x.ptrm,
                                  x.fecha_inicio,
                                  NULL,
                                  c.maximo,                           --number
                                  l_nivel,
                                  l_campus,
                                  NULL,                               --number
                                  c.materia,
                                  NULL,
                                  x.periodo,
                                  NULL,
                                  NULL,
                                  NULL,                              -- number
                                  l_short_name,
                                  p_regla,                           -- number
                                  l_secuencia,                       -- number
                                  c.grupo2,                          -- number
                                  'S',
                                  1, 
                                  'E'                                   --number
                                   );

                     l_retorna := 'EXITO';

                     DBMS_OUTPUT.put_line (' entramos 3');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        -- dbms_output.put_line(' Error en al insertar gpme grupo '||c.materia||c.grupo||' error '||SQLERRM||' sentnecia sql '||l_Sql);
                        --l_retorna:=' Error en al insertar gpme '||sqlerrm;
                        NULL;
                  END;

                  COMMIT;
               END LOOP;
            ELSE
               l_contador := 0;

               DBMS_OUTPUT.put_line (' entra a EC ');

               FOR x
                  IN (  SELECT DISTINCT sztprono_term_code periodo,
                                        sztprono_ptrm_code ptrm,
                                        SZTPRONO_FECHA_INICIO_NW fecha_inicio,
                                        SZTPRONO_SECUENCIA secuencia,
                                        SZTPRONO_PROGRAM programa_diplo
                          FROM sztprono
                         WHERE     1 = 1
                               AND sztprono_no_regla = p_regla
                               AND sztprono_materia_legal = c.materia
                      ORDER BY 3)
               LOOP
                  l_contador := l_contador + 1;

                  l_short_name :=
                     f_get_short_name (x.ptrm,
                                       x.periodo,
                                       c.materia,
                                       x.fecha_inicio);

                  BEGIN
                     SELECT COUNT (*)
                       INTO L_DIPLO_EXCLUIR
                       FROM zstpara
                      WHERE     1 = 1
                            AND ZSTPARA_MAPA_ID = 'DIPLO_EXCLUIR'
                            AND ZSTPARA_PARAM_ID = x.programa_diplo;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        L_DIPLO_EXCLUIR := 0;
                  END;

                  IF x.secuencia = 1 AND L_DIPLO_EXCLUIR = 0
                  THEN
                     BEGIN
                        INSERT INTO sztgpme
                             VALUES (c.materia || c.grupo,
                                     c.materia,
                                     l_desripcion_mat,
                                     0,
                                     NULL,
                                     USER,
                                     SYSDATE,
                                     x.ptrm,
                                     x.fecha_inicio,
                                     NULL,
                                     c.maximo,
                                     l_nivel,
                                     'UTS',
                                     NULL,
                                     c.materia,
                                     NULL,
                                     x.periodo,
                                     NULL,
                                     NULL,
                                     NULL,
                                     l_short_name,
                                     p_regla,
                                     x.secuencia,
                                     c.grupo2,
                                     'S',
                                     1,
                                      'E');

                        l_retorna := 'EXITO';

                        DBMS_OUTPUT.put_line (' entramos 3');
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           DBMS_OUTPUT.put_line (
                                 ' Error en al insertar gpme grupo '
                              || c.materia
                              || c.grupo
                              || ' error '
                              || SQLERRM
                              || ' ptrm '
                              || x.ptrm);
                           --l_retorna:=' Error en al insertar gpme '||sqlerrm;
                           NULL;
                     END;
                  ELSE
                     BEGIN
                        INSERT INTO sztgpme
                             VALUES (c.materia || c.grupo,
                                     c.materia,
                                     l_desripcion_mat,
                                     5,
                                     NULL,
                                     USER,
                                     SYSDATE,
                                     x.ptrm,
                                     x.fecha_inicio,
                                     NULL,
                                     c.maximo,
                                     l_nivel,
                                     'UTS',
                                     NULL,
                                     c.materia,
                                     NULL,
                                     x.periodo,
                                     NULL,
                                     NULL,
                                     NULL,
                                     l_short_name,
                                     p_regla,
                                     x.secuencia,
                                     c.grupo2,
                                     'S',
                                     1, 
                                     'E');

                        l_retorna := 'EXITO';

                        DBMS_OUTPUT.put_line (' entramos 3');
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           DBMS_OUTPUT.put_line (
                                 ' Error en al insertar gpme grupo '
                              || c.materia
                              || c.grupo
                              || ' error '
                              || SQLERRM
                              || ' ptrm '
                              || x.ptrm);
                           --l_retorna:=' Error en al insertar gpme '||sqlerrm;
                           NULL;
                     END;
                  END IF;

                  EXIT WHEN l_contador = 1;

                  COMMIT;
               END LOOP;
            END IF;
         END LOOP;


         COMMIT;
      ELSE
         DBMS_OUTPUT.put_line (' Esta regla no esta cerrada ' || p_regla);
         l_retorna := 'Esta regla no esta cerrada ' || l_regla_cerrada;
         RETURN (l_retorna);
      END IF;

      RETURN (l_retorna);
   END;

   --
   --
   FUNCTION f_prof_moodl (p_inicio_clase IN VARCHAR2, p_regla IN NUMBER)
      RETURN VARCHAR2
   AS
      l_retorna         VARCHAR2 (1000) := 'EXITO';
      l_regla_cerrada   VARCHAR2 (1);
      l_pwd             VARCHAR2 (100);
      l_id              VARCHAR (20);
      l_pidm            NUMBER;
      l_secuenia        NUMBER;
      l_grupo           NUMBER;
      L_DIPLO_EXCLUIR   NUMBER;
   BEGIN
      DBMS_OUTPUT.put_line (' Esta regla no esta cerrada ' || p_regla);

      BEGIN
         SELECT DISTINCT sztalgo_estatus_cerrado
           INTO l_regla_cerrada
           FROM sztalgo
          WHERE 1 = 1 AND sztalgo_no_regla = p_regla;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      IF l_regla_cerrada = 'S'
      THEN
         FOR c
            IN (  SELECT SZTGPME_TERM_NRC padre,
                         sztgpme_no_regla regla,
                         SZTGPME_PTRM_CODE ptrm,
                         SZTGPME_SECUENCIA secuencia,
                         LENGTH (SZTGPME_TERM_NRC) largo,
                         LENGTH (SZTGPME_TERM_NRC) - 1 SUBT,
                         SZTGPME_SUBJ_CRSE materia,
                         TO_NUMBER (
                            SUBSTR (SZTGPME_TERM_NRC,
                                    LENGTH (SZTGPME_TERM_NRC) - 1,
                                    100))
                            GRUPO,
                         SZTGPME_START_DATE fecha_inicio,
                         SZTGPME_LEVL_CODE nivel
                    FROM sztgpme me
                   WHERE     1 = 1
                         AND sztgpme_no_regla = P_REGLA
--                         AND SZTGPME_START_DATE=p_inicio_clase
                         AND SZTGPME_SUBJ_CRSE  in (SELECT SZTCONF_SUBJ_CODE
                                   FROM sztconf
                                  WHERE     1 = 1
                                        AND sztconf_no_regla = P_REGLA
--                                        AND SZTCONF_SUBJ_CODE =SZTGPME_SUBJ_CRSE
                                        )
--                         AND EXISTS
--                                (SELECT NULL
--                                   FROM sztconf
--                                  WHERE     1 = 1
--                                        AND sztconf_no_regla = P_REGLA
--                                        AND SZTCONF_SUBJ_CODE =SZTGPME_SUBJ_CRSE)
                ORDER BY 4)
         LOOP
            BEGIN
               SELECT sztconf_id, sztconf_pidm
                 INTO l_id, l_pidm
                 FROM sztconf
                WHERE     1 = 1
                      AND sztconf_no_regla = p_regla
                      --and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY') = p_inicio_clase
                      AND SZTCONF_GROUP = c.grupo
                      AND SZTCONF_SUBJ_CODE = c.materia;
            EXCEPTION
               WHEN OTHERS
               THEN
                  DBMS_OUTPUT.put_line (' Error al obtener pidm ' || SQLERRM);
                  NULL;
            END;


            BEGIN
               SELECT GOZTPAC_PIN
                 INTO l_pwd
                 FROM GOZTPAC pac
                WHERE     1 = 1
                      AND pac.GOZTPAC_ID = l_id
                      AND GOZTPAC_PIN IS NOT NULL
                      AND ROWNUM = 1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  DBMS_OUTPUT.put_line (
                        ' Error al obtener pwd '
                     || SQLERRM
                     || ' pidm '
                     || l_pidm);
                  l_retorna :=
                        ' Error al obtener pwd '
                     || SQLERRM
                     || ' regla '
                     || p_regla
                     || ' grupo '
                     || c.grupo
                     || ' materia '
                     || c.materia;
            END;


            IF l_pwd IS NOT NULL
            THEN
               IF c.secuencia IS NULL
               THEN
                  BEGIN
                     SELECT MAX (SZTCONF_SECUENCIA)
                       INTO c.secuencia
                       FROM sztconf;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        c.secuencia := 0;
                  END;
               END IF;


               IF c.nivel  NOT IN ('EC','ID')
               THEN
                  BEGIN
                     INSERT INTO SZSGNME
                          VALUES (c.padre,
                                  l_pidm,
                                  SYSDATE,
                                  USER,
                                  '5',
                                  NULL,
                                  l_pwd,
                                  NULL,
                                  'AC',
                                  c.secuencia,
                                  NULL,
                                  c.ptrm,
                                  c.fecha_inicio,
                                  c.regla,
                                  c.secuencia,
                                  1,
                                  'E');

                     l_retorna := 'EXITO';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        DBMS_OUTPUT.put_line (
                              ' Error al insertar tabla de profesores moodl '
                           || SQLERRM);
                        l_retorna :=
                              ' Error al insertar tabla de profesores moodl '
                           || SQLERRM;
                  END;
               ELSE
                  BEGIN
                     SELECT COUNT (*)
                       INTO L_DIPLO_EXCLUIR
                       FROM zstpara
                      WHERE     1 = 1
                            AND ZSTPARA_MAPA_ID = 'DIPLO_EXCLUIR'
                            AND ZSTPARA_PARAM_ID IN (SELECT DISTINCT
                                                            SZTPRONO_PROGRAM
                                                       FROM sztprono
                                                      WHERE     1 = 1
                                                            AND sztprono_no_regla =
                                                                   P_REGLA
                                                            AND SZTPRONO_MATERIA_LEGAL =
                                                                   c.materia);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        L_DIPLO_EXCLUIR := 0;
                  END;

                  IF c.secuencia = 1 AND L_DIPLO_EXCLUIR = 0
                  THEN
                     BEGIN
                        INSERT INTO SZSGNME
                             VALUES (c.padre,
                                     l_pidm,
                                     SYSDATE,
                                     USER,
                                     '0',
                                     NULL,
                                     l_pwd,
                                     NULL,
                                     'AC',
                                     c.secuencia,
                                     NULL,
                                     c.ptrm,
                                     c.fecha_inicio,
                                     c.regla,
                                     c.secuencia,
                                     1,
                                     'E');

                        l_retorna := 'EXITO';
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           DBMS_OUTPUT.put_line (
                                 ' Error al insertar tabla de profesores moodl '
                              || SQLERRM);
                           l_retorna :=
                                 ' Error al insertar tabla de profesores moodl '
                              || SQLERRM;
                     END;
                  ELSE
                     BEGIN
                        INSERT INTO SZSGNME
                             VALUES (c.padre,
                                     l_pidm,
                                     SYSDATE,
                                     USER,
                                     '5',
                                     NULL,
                                     l_pwd,
                                     NULL,
                                     'AC',
                                     c.secuencia,
                                     NULL,
                                     c.ptrm,
                                     c.fecha_inicio,
                                     c.regla,
                                     c.secuencia,
                                     1,
                                     'E');

                        l_retorna := 'EXITO';
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           DBMS_OUTPUT.put_line (
                                 ' Error al insertar tabla de profesores moodl '
                              || SQLERRM);
                           l_retorna :=
                                 ' Error al insertar tabla de profesores moodl '
                              || SQLERRM;
                     END;
                  END IF;
               END IF;

               BEGIN
                  UPDATE SZTCONF
                     SET SZTCONF_ESTATUS_CERRADO = 'S'
                   WHERE     1 = 1
                         AND SZTCONF_SUBJ_CODE = c.materia
                         AND sztconf_no_regla = p_regla
                         AND SZTCONF_GROUP = c.grupo;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     DBMS_OUTPUT.put_line (
                        ' Error al actualizar grupos pronostico ' || SQLERRM);
                     l_retorna :=
                        ' Error al actualizar grupos pronostico ' || SQLERRM;
               END;
            END IF;
         END LOOP;

         COMMIT;
      ELSE
         DBMS_OUTPUT.put_line (' Esta regla no esta cerrada ' || p_regla);
         l_retorna := 'Esta regla no esta cerrada ';
      END IF;

      RETURN (l_retorna);
   END;

   --
   --
   FUNCTION f_alumnos_moodl (p_inicio_clase in varchar2, p_regla IN NUMBER)
      RETURN VARCHAR2
   AS
      l_retorna             VARCHAR2 (1000) := 'EXITO';
      l_regla_cerrada       VARCHAR2 (1);
      l_contar              NUMBER;
      l_numero_grupos       NUMBER;
      vl_alumnos            NUMBER := 0;
      l_cuenta_alumnos      NUMBER;
      l_numero_alumnos      NUMBER;
      l_total               NUMBER;
      l_grupo_disponible    VARCHAR2 (100);
      l_numero_alumnos2     NUMBER;
      l_tope_grupos         NUMBER;
      l_total_alumnos       NUMBER;
      l_sobrecupo           NUMBER;
      l_cuenta_grupo        NUMBER;
      l_estatus_gaston      VARCHAR2 (10);
      l_descripcion_error   VARCHAR2 (500);
      l_estatus_sgbstn      VARCHAR2 (5) := NULL;
      l_fecha_inicio        DATE;
      l_programa            VARCHAR2 (20);
      l_sp                  NUMBER;
      l_cuenta_uve          NUMBER;
      l_sincro_grupo        NUMBER;
      l_sincro_prof         NUMBER;
      L_DIPLO_EXCLUIR       NUMBER;

   BEGIN

      l_estatus_sgbstn := NULL;


      BEGIN
         SELECT DISTINCT TRIM (SZTALGO_ESTATUS_CERRADO),
                SZTALGO_TOPE_ALUMNOS,
                SZTALGO_SOBRECUPO_ALUMNOS
           INTO l_regla_cerrada, l_tope_grupos, l_sobrecupo
           FROM sztalgo
          WHERE 1 = 1 AND sztalgo_no_regla = p_regla;
      EXCEPTION
         WHEN OTHERS
         THEN
            -- raise_application_error (-20002,'Error al '||sqlerrm);
            NULL;
      END;

    IF l_regla_cerrada = 'S' THEN

          l_contar := 0;

          l_numero_alumnos := 0;



          FOR c IN
                   (SELECT SZTGPME_TERM_NRC padre,
                          sztgpme_no_regla regla,
                          sztgpme_subj_crse materia,
                          SZTGPME_START_DATE inicio_clases,
                          TO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100))grupo,
                          SZTGPME_SECUENCIA secuencia,
                          SZTGPME_NIVE_SEQNO sqno,
                          SZTGPME_LEVL_CODE nivel
                     FROM sztgpme grp
                    WHERE     1 = 1
                          AND sztgpme_no_regla = p_regla
--                           AND  to_date(to_char(SZTGPME_START_DATE),'DD/MM/YYYY')= to_date(to_char(p_inicio_clase),'DD/MM/YYYY')
                          AND SZTGPME_LEVL_CODE NOT IN ( 'EC','ID')
--                          AND TO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) NOT IN (SELECT TO_NUMBER (SUBSTR (SZSTUME_TERM_NRC, LENGTH(SZSTUME_TERM_NRC)- 1,100))
--                                                        FROM szstume
--                                                        WHERE     1 = 1
--                                                        AND szstume_no_regla =grp.sztgpme_no_regla
--                                                        AND SZSTUME_SUBJ_CODE = grp.sztgpme_subj_crse
--                                                        AND NOT EXISTS(SELECT NULL
--                                                                        FROM SZTPREXT
--                                                                         WHERE  1 =1
--                                                                             AND SZTPREXT_pidm =szstume_pidm
--                                                                             AND SZTPREXT_no_regla = szstume_no_regla
--                                                                             AND SZTPREXT_MATERIA_CAMBIO =szstume_subj_code
--                                                                             AND SZTPREXT_CON_GRUPO = 'S'))
                   UNION
                   SELECT SZTGPME_TERM_NRC padre,
                          sztgpme_no_regla regla,
                          sztgpme_subj_crse materia,
                          SZTGPME_START_DATE inicio_clases,
                          TO_NUMBER (SUBSTR (SZTGPME_TERM_NRC, LENGTH (SZTGPME_TERM_NRC) - 1,100))grupo,
                          SZTGPME_SECUENCIA secuencia,
                          SZTGPME_NIVE_SEQNO sqno,
                          SZTGPME_LEVL_CODE nivel
                     FROM sztgpme grp
                    WHERE     1 = 1
                          AND sztgpme_no_regla = p_regla
--                          AND  to_date(to_char(SZTGPME_START_DATE),'DD/MM/YYYY')= to_date(to_char(p_inicio_clase),'DD/MM/YYYY')
                          AND SZTGPME_LEVL_CODE IN ('EC','ID')
--                          AND TO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) NOT IN (SELECT TO_NUMBER (SUBSTR (SZSTUME_TERM_NRC,LENGTH (SZSTUME_TERM_NRC)- 1,100))
--                                                         FROM szstume
--                                                        WHERE 1 = 1
--                                                        AND szstume_no_regla =grp.sztgpme_no_regla
--                                                        AND SZSTUME_SUBJ_CODE =grp.sztgpme_subj_crse
--                                                        AND NOT EXISTS(SELECT NULL
--                                                                        FROM SZTPREXT
--                                                                       WHERE     1 =1
--                                                                             AND SZTPREXT_pidm =szstume_pidm
--                                                                             AND SZTPREXT_no_regla =szstume_no_regla
--                                                                             AND SZTPREXT_MATERIA_CAMBIO =szstume_subj_code
--                                                                             AND SZTPREXT_CON_GRUPO ='S'))
                                                                             )
            LOOP

               DBMS_OUTPUT.put_line (' Materia '|| c.materia|| ' Grupo '|| c.grupo || ' nrc ' || c.materia || c.grupo);


               FOR e
                  IN (SELECT COUNT (*) vueltas
                        FROM sztconf onf
                       WHERE     1 = 1
                             AND onf.sztconf_no_regla = c.regla
--                             AND onf.SZTCONF_FECHA_INICIO = c.inicio_clases
                             AND SZTCONF_SUBJ_CODE = c.materia
                             AND SZTCONF_GROUP = c.grupo)
               LOOP
                  l_estatus_sgbstn := NULL;

                  SELECT COUNT (*)
                    INTO l_cuenta_alumnos
                    FROM szstume
                   WHERE     1 = 1
                         AND szstume_no_regla = c.regla
                         AND SZSTUME_SUBJ_CODE = c.materia
                         AND SZSTUME_TERM_NRC = c.padre;

                  DBMS_OUTPUT.put_line (
                     ' Entra alumno EC ' || l_cuenta_alumnos);

                  BEGIN
                     SELECT SZTCONF_STUDENT_NUMB
                       INTO l_numero_alumnos2
                       FROM sztconf
                      WHERE     1 = 1
                            AND sztconf_no_regla = c.regla
                            AND sztconf_subj_code = c.materia
                            -- and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')=c.inicio_clases
                            AND SZTCONF_GROUP = c.grupo;
                  EXCEPTION WHEN OTHERS THEN
                        NULL;
                  END;



                  DBMS_OUTPUT.put_line (' Entra alumnoS EC2 '|| c.regla|| ' alumnos numero '|| l_numero_alumnos2|| ' inicio clases '|| c.inicio_clases|| ' Materia ' ||c.materia || ' nivel '||c.nivel);

                l_contar := 0;

                  FOR d
                     IN (SELECT *
                           FROM (SELECT sztprono_id matricula,
                                        SZTPRONO_PIDM pidm,
                                        'RE' estatus_alumno,
                                        (SELECT GOZTPAC_PIN
                                           FROM GOZTPAC pac
                                          WHERE 1 = 1
                                          AND pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM)pwd,
                                        SZTPRONO_COMENTARIO comentario,
                                        65 tope,
                                        SZTPRONO_PROGRAM programa,
                                        sztprono_materia_legal materia,
                                        DECODE ((SELECT DISTINCT SZTDTEC_MOD_TYPE
                                              FROM sztdtec ax
                                             WHERE     1 = 1
                                             AND ax.SZTDTEC_TERM_CODE =(SELECT MAX (ax1.SZTDTEC_TERM_CODE)
                                                             FROM sztdtec ax1
                                                            WHERE ax.SZTDTEC_PROGRAM =ax1.SZTDTEC_PROGRAM)
                                                            AND ax.SZTDTEC_PROGRAM =ono.SZTPRONO_PROGRAM),'S', 1,'OL', 2)semi
                                   FROM sztprono ono
                                  WHERE     1 = 1
                                        AND sztprono_no_regla = c.regla
                                        AND sztprono_materia_legal =c.materia
                                        AND SZTPRONO_ESTATUS_ERROR = 'N'
                                        AND SZTPRONO_ENVIO_MOODL = 'N'
--                                        AND SZTPRONO_ID='020541145'
                                        AND DECODE ((SELECT DISTINCT SZTDTEC_MOD_TYPE
                                                  FROM sztdtec ax
                                                  WHERE     1 = 1
                                                  AND ax.SZTDTEC_TERM_CODE =(SELECT MAX (ax1.SZTDTEC_TERM_CODE)
                                                                                 FROM sztdtec ax1
                                                                                WHERE ax.SZTDTEC_PROGRAM = ax1.SZTDTEC_PROGRAM)
                                                  AND ax.SZTDTEC_PROGRAM =ono.SZTPRONO_PROGRAM), 'S', 1,'OL', 2) = 1
                                 UNION
                                 SELECT sztprono_id matricula,
                                        SZTPRONO_PIDM pidm,
                                        'RE' estatus_alumno,
                                        (SELECT GOZTPAC_PIN
                                           FROM GOZTPAC pac
                                          WHERE     1 = 1
                                          AND pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM)pwd,
                                        SZTPRONO_COMENTARIO comentario,
                                        65 tope,
                                        SZTPRONO_PROGRAM programa,
                                        sztprono_materia_legal materia,
                                        DECODE ((SELECT DISTINCT SZTDTEC_MOD_TYPE
                                                 FROM sztdtec ax
                                                 WHERE     1 = 1
                                                 AND ax.SZTDTEC_TERM_CODE = (SELECT MAX (ax1.SZTDTEC_TERM_CODE)
                                                                             FROM sztdtec ax1
                                                                            WHERE ax.SZTDTEC_PROGRAM =ax1.SZTDTEC_PROGRAM)
                                                   AND ax.SZTDTEC_PROGRAM =ono.SZTPRONO_PROGRAM),'S', 1,'OL', 2)semi
                                  FROM sztprono ono
                                  WHERE     1 = 1
                                        AND sztprono_no_regla = c.regla
                                        AND sztprono_materia_legal =c.materia
                                        AND SZTPRONO_ESTATUS_ERROR = 'N'
                                        AND SZTPRONO_ENVIO_MOODL = 'N'
--                                         AND SZTPRONO_ID='020541145'
                                        AND DECODE ((SELECT DISTINCT SZTDTEC_MOD_TYPE
                                                  FROM sztdtec ax
                                                 WHERE     1 = 1
                                                       AND ax.SZTDTEC_TERM_CODE =(SELECT MAX (ax1.SZTDTEC_TERM_CODE)
                                                                 FROM sztdtec ax1
                                                                WHERE ax.SZTDTEC_PROGRAM =ax1.SZTDTEC_PROGRAM)
                                                                AND ax.SZTDTEC_PROGRAM =ono.SZTPRONO_PROGRAM),'S', 1,'OL', 2) = 2
                                 ORDER BY 9, 4)
                          WHERE 1 = 1 AND ROWNUM <= l_numero_alumnos2)

                  LOOP

                     DBMS_OUTPUT.put_line ('Entra a alumnos ');

                     l_contar := l_contar + 1;

                    IF c.nivel NOT IN ( 'EC','ID') THEN
                        DBMS_OUTPUT.put_line (
                              ' Padre '
                           || c.padre
                           || ' Alumno '
                           || d.matricula
                           || ' Semi '
                           || d.semi
                           || ' Contar '
                           || l_contar
                           || ' Tope Grupo '
                           || l_numero_alumnos2);


                        BEGIN
                            DBMS_OUTPUT.put_line (' ENTRA A NO EC ' );
                           INSERT INTO SZSTUME
                                VALUES (c.padre,
                                        d.pidm,
                                        d.matricula,
                                        SYSDATE,
                                        USER,
                                        5,
                                        NULL,
                                        d.pwd,
                                        NULL,
                                        1,
                                        d.estatus_alumno,
                                        0,
                                        c.materia,
                                        NULL,             --D.semi,-- c.nivel,
                                        NULL,
                                        NULL,                       -- c.ptrm,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        c.materia,
                                        p_inicio_clase,
                                        --c.inicio_clases,
                                        c.regla,
                                        c.secuencia,
                                        c.sqno,
                                        0,
                                        null);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              DBMS_OUTPUT.put_line (' Error al insertar ' || SQLERRM);
                        END;

                    ELSE

                         BEGIN
                           SELECT COUNT (*)
                             INTO L_DIPLO_EXCLUIR
                             FROM zstpara
                            WHERE 1 = 1
                                  AND ZSTPARA_MAPA_ID = 'DIPLO_EXCLUIR'
                                  AND ZSTPARA_PARAM_ID = d.programa;
                           DBMS_OUTPUT.put_line ('CALCULO SI SE EXCLUYE'|| L_DIPLO_EXCLUIR ||'   '||d.programa);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              L_DIPLO_EXCLUIR := 0;
                        END;

                        IF c.secuencia = 1 AND L_DIPLO_EXCLUIR = 0 THEN

                             DBMS_OUTPUT.put_line ('ENTRA A NO EXCLUIDOS '||L_DIPLO_EXCLUIR ||'   '||d.programa );

                            BEGIN

                              INSERT INTO SZSTUME
                                   VALUES (c.padre,
                                           d.pidm,
                                           d.matricula,
                                           SYSDATE,
                                           USER,
                                           0,
                                           NULL,
                                           d.pwd,
                                           NULL,
                                           1,
                                           d.estatus_alumno,
                                           0,
                                           c.materia,
                                           NULL,          --D.semi,-- c.nivel,
                                           NULL,
                                           NULL,                    -- c.ptrm,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           c.materia,
                                           --p_inicio_clase,
                                           c.inicio_clases,
                                           c.regla,
                                           c.secuencia,
                                           c.sqno,
                                           0,
                                           null);
                                        COMMIT;
                               EXCEPTION
                                  WHEN OTHERS
                                  THEN
                                     DBMS_OUTPUT.put_line (
                                        ' Error al insertar ' || SQLERRM);
                               END;

                        ELSE
                          null;
--                           BEGIN
--                             DBMS_OUTPUT.put_line ('ENTRA A EXCLUIDOS 2 '||L_DIPLO_EXCLUIR||'   '||d.programa );
--
--                              INSERT INTO SZSTUME
--                                   VALUES (c.padre,
--                                           d.pidm,
--                                           d.matricula,
--                                           SYSDATE,
--                                           USER,
--                                           5,
--                                           NULL,
--                                           d.pwd,
--                                           NULL,
--                                           1,
--                                           d.estatus_alumno,
--                                           0,
--                                           c.materia,
--                                           NULL,          --D.semi,-- c.nivel,
--                                           NULL,
--                                           NULL,                    -- c.ptrm,
--                                           NULL,
--                                           NULL,
--                                           NULL,
--                                           NULL,
--                                           c.materia,
--                                           --p_inicio_clase,
--                                           c.inicio_clases,
--                                           c.regla,
--                                           c.secuencia,
--                                           c.sqno,
--                                           0,
--                                           null);
--                                           commit;
--                           EXCEPTION WHEN OTHERS  THEN
--                                 DBMS_OUTPUT.put_line (' Error al insertar ' || SQLERRM);
--                           END;

                        END IF;

                    END IF;

                     BEGIN

                      DBMS_OUTPUT.put_line ( ' ENTRA A ACTULIZAR SZTPRONO');

                        UPDATE SZTPRONO
                           SET SZTPRONO_ENVIO_MOODL = 'S',
                               SZTPRONO_GRUPO_ASIG = c.grupo
                         WHERE     1 = 1
                               AND SZTPRONO_MATERIA_LEGAL = c.materia
                               AND SZTPRONO_PIDM = d.pidm
                               AND SZTPRONO_NO_REGLA = c.regla
                               AND SZTPRONO_ENVIO_MOODL = 'N'
                               AND SZTPRONO_SECUENCIA=1;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           NULL;
                     END;
                  -- exit when l_contar =l_numero_alumnos2;
                  END LOOP;

               END LOOP;

            END LOOP;

--                      for c in (select *
--                              from szstume
--                              where 1 = 1
--                              and szstume_no_regla = p_regla
--                              )
--                              loop
--
--                                     BEGIN
--
--                                        SELECT DISTINCT sorlcur_program, cur.sorlcur_key_seqno
--                                        INTO l_programa, l_sp
--                                        FROM sorlcur cur
--                                        WHERE     1 = 1
--                                        AND cur.sorlcur_pidm = c.szstume_pidm
--                                        AND cur.sorlcur_lmod_code = 'LEARNER'
--                                        AND cur.sorlcur_roll_ind = 'Y'
--                                        AND cur.sorlcur_cact_code = 'ACTIVE'
--                                        AND cur.sorlcur_seqno =
--                                                               (SELECT MAX (aa1.sorlcur_seqno)
--                                                                FROM sorlcur aa1
--                                                                WHERE     cur.sorlcur_pidm = aa1.sorlcur_pidm
--                                                                AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
--                                                                AND cur.sorlcur_roll_ind = aa1.sorlcur_roll_ind
--                                                                AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code);
--
--                                     EXCEPTION WHEN OTHERS THEN
--                                           NULL;
--                                     END;
--
--
--                                     begin
--                                         select distinct SGBSTDN_STST_CODE
--                                         into l_estatus_sgbstn
--                                         from sgbstdn a
--                                         WHERE 1 = 1
--                                         AND a.sgbstdn_pidm = c.szstume_pidm
--                                         AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
--                                                                        FROM sgbstdn a1
--                                                                        WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
--                                                                                               );
--                                     exception when others then
--                                        l_estatus_sgbstn:=null;
--                                     end;
--
--
--                                    BEGIN
--
--                                        SELECT DISTINCT SORLCUR_START_DATE
--                                        INTO l_fecha_inicio
--                                        FROM sorlcur cur
--                                        WHERE     1 = 1
--                                        AND cur.sorlcur_pidm = c.szstume_pidm
--                                        AND cur.sorlcur_key_seqno = l_sp
--                                        AND cur.sorlcur_lmod_code = 'LEARNER'
--                                        AND cur.sorlcur_roll_ind = 'Y'
--                                        AND cur.sorlcur_cact_code = 'ACTIVE'
--                                        AND cur.sorlcur_seqno =
--                                                               (SELECT MAX (aa1.sorlcur_seqno)
--                                                                FROM sorlcur aa1
--                                                                WHERE     cur.sorlcur_pidm = aa1.sorlcur_pidm
--                                                                AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
--                                                                AND cur.sorlcur_roll_ind = aa1.sorlcur_roll_ind
--                                                                AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code);
--
--                                    EXCEPTION WHEN OTHERS THEN
--                                          NULL;
--                                    END;
--
--
--                                    if l_fecha_inicio > c.SZSTUME_START_DATE then
--
--                                         --dbms_output.put_line('Matricula '||c.SZSTUME_ID||' fecha inicio '||l_fecha_inicio||' start date '|| c.SZSTUME_START_DATE);
----
--                                         BEGIN
--
--                                              UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='N',
--                                                                  SZTPRONO_ESTATUS_ERROR ='S',
--                                                                  SZTPRONO_DESCRIPCION_ERROR=' Este alumno tiene un cambio de fecha  '||to_char(l_fecha_inicio,'DD/MM/YYYY')
--                                              WHERE 1 = 1
--                                              and SZTPRONO_MATERIA_LEGAL = c.szstume_subj_code
--                                              and SZTPRONO_PIDM =c.szstume_pidm
--                                              and SZTPRONO_NO_REGLA = c.szstume_no_regla;
--
--                                         EXCEPTION WHEN OTHERS THEN
--                                             null;
--                                         END;
--
--                                         begin
--
--                                            delete szstume
--                                            where 1 = 1
--                                            and szstume_subj_code = c.szstume_subj_code
--                                            and szstume_pidm =c.szstume_pidm
--                                            and szstume_no_regla = c.szstume_no_regla
--                                            and szstume_term_nrc =c.szstume_term_nrc;
--
--                                         EXCEPTION WHEN OTHERS THEN
--                                             null;
--                                         END;
--
--
--                                    end if;
--
--
--                              end loop;
--
    END IF;
      commit;
    RETURN (l_retorna);

END;

   --
   --
   FUNCTION f_alumnos_insur (p_inicio_clase   IN VARCHAR2,
                             p_regla          IN NUMBER,
                             p_programa          VARCHAR2)
      RETURN VARCHAR2
   AS
      l_retorna             VARCHAR2 (1000) := 'EXITO';
      l_regla_cerrada       VARCHAR2 (1);
      l_contar              NUMBER;
      l_numero_grupos       NUMBER;
      vl_alumnos            NUMBER := 0;
      l_cuenta_alumnos      NUMBER;
      l_numero_alumnos      NUMBER;
      l_total               NUMBER;
      l_grupo_disponible    VARCHAR2 (100);
      l_numero_alumnos2     NUMBER;
      l_tope_grupos         NUMBER;
      l_total_alumnos       NUMBER;
      l_sobrecupo           NUMBER;
      l_cuenta_grupo        NUMBER;
      l_estatus_gaston      VARCHAR2 (10);
      l_descripcion_error   VARCHAR2 (500);
      l_estatus_sgbstn      VARCHAR2 (5) := NULL;
   BEGIN
      l_estatus_sgbstn := NULL;



      BEGIN
         SELECT DISTINCT
                TRIM (SZTALGO_ESTATUS_CERRADO),
                SZTALGO_TOPE_ALUMNOS,
                SZTALGO_SOBRECUPO_ALUMNOS
           INTO l_regla_cerrada, l_tope_grupos, l_sobrecupo
           FROM sztalgo
          WHERE 1 = 1 AND sztalgo_no_regla = p_regla;
      EXCEPTION
         WHEN OTHERS
         THEN
            -- raise_application_error (-20002,'Error al '||sqlerrm);
            NULL;
      END;

      IF l_regla_cerrada = 'S'
      THEN
         l_contar := 0;
         l_numero_alumnos2 := 0;
         l_numero_alumnos := 0;


         FOR c
            IN (SELECT SZTGPME_TERM_NRC padre,
                       sztgpme_no_regla regla,
                       sztgpme_subj_crse materia,
                       TO_CHAR (SZTGPME_START_DATE, 'DD/MM/YYYY')
                          inicio_clases,
                       TO_NUMBER (
                          f_get_group (p_regla,
                                       p_inicio_clase,
                                       SZTGPME_TERM_NRC))
                          grupo,
                       SZTGPME_SECUENCIA secuencia
                  FROM sztgpme grp
                 WHERE     1 = 1
                       AND sztgpme_no_regla = p_regla
                       AND SZTGPME_START_DATE = p_inicio_clase
                       AND grp.sztgpme_subj_crse = 'L1PS108'
                       AND TO_NUMBER (
                              f_get_group (p_regla,
                                           p_inicio_clase,
                                           SZTGPME_TERM_NRC)) NOT IN (SELECT TO_NUMBER (
                                                                                f_get_group (
                                                                                   p_regla,
                                                                                   p_inicio_clase,
                                                                                   SZSTUME_TERM_NRC))
                                                                        FROM szstume
                                                                       WHERE     1 =
                                                                                    1
                                                                             AND szstume_no_regla =
                                                                                    grp.sztgpme_no_regla
                                                                             AND SZSTUME_START_DATE =
                                                                                    TO_CHAR (
                                                                                       grp.SZTGPME_START_DATE,
                                                                                       'DD/MM/YYYY')
                                                                             AND SZSTUME_SUBJ_CODE =
                                                                                    grp.sztgpme_subj_crse
                                                                             AND NOT EXISTS
                                                                                    (SELECT NULL
                                                                                       FROM SZTPREXT
                                                                                      WHERE     1 =
                                                                                                   1
                                                                                            AND SZTPREXT_pidm =
                                                                                                   szstume_pidm
                                                                                            AND SZTPREXT_no_regla =
                                                                                                   szstume_no_regla
                                                                                            AND SZTPREXT_MATERIA_CAMBIO =
                                                                                                   szstume_subj_code
                                                                                            AND SZTPREXT_CON_GRUPO =
                                                                                                   'S')))
         LOOP
            FOR e
               IN (SELECT COUNT (*) vueltas
                     FROM sztconf onf
                    WHERE     1 = 1
                          AND onf.sztconf_no_regla = c.regla
                          AND onf.SZTCONF_FECHA_INICIO = c.inicio_clases
                          AND SZTCONF_SUBJ_CODE = c.materia
                          AND SZTCONF_GROUP = c.grupo)
            LOOP
               l_contar := l_contar + 1;

               l_estatus_sgbstn := NULL;

               SELECT COUNT (*)
                 INTO l_cuenta_alumnos
                 FROM szstume
                WHERE     1 = 1
                      AND szstume_no_regla = c.regla
                      AND SZSTUME_SUBJ_CODE = c.materia
                      AND SZSTUME_TERM_NRC = c.padre;

               DBMS_OUTPUT.put_line (
                  ' Entra alumno no alumnos ' || l_cuenta_alumnos);

               BEGIN
                  SELECT SZTCONF_STUDENT_NUMB
                    INTO l_numero_alumnos2
                    FROM sztconf
                   WHERE     1 = 1
                         AND sztconf_no_regla = c.regla
                         AND sztconf_subj_code = c.materia
                         AND TO_CHAR (
                                TO_DATE (SZTCONF_FECHA_INICIO, 'DD/MM/YYYY'),
                                'DD/MM/YYYY') = c.inicio_clases
                         AND TO_NUMBER (SZTCONF_GROUP) = c.grupo;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;

               DBMS_OUTPUT.put_line (
                     ' Entra alumno no alumnos regla '
                  || c.regla
                  || ' alumnos numero '
                  || l_numero_alumnos2
                  || ' inicio clases '
                  || c.inicio_clases
                  || ' Materia '
                  || c.materia);


               FOR d
                  IN (SELECT sztprono_id matricula,
                             SZTPRONO_PIDM pidm,
                             'RE' estatus_alumno,
                             (SELECT GOZTPAC_PIN
                                FROM GOZTPAC pac
                               WHERE     1 = 1
                                     AND pac.GOZTPAC_pidm = ono.SZTPRONO_PIDM)
                                pwd,
                             SZTPRONO_COMENTARIO comentario,
                             65 tope,
                             SZTPRONO_PROGRAM programa,
                             sztprono_materia_legal materia
                        FROM sztprono ono
                       WHERE     1 = 1
                             AND sztprono_no_regla = c.regla
                             AND sztprono_materia_legal = c.materia
                             AND ROWNUM <= l_numero_alumnos2
                             AND SZTPRONO_FECHA_INICIO = c.inicio_clases
                             -- and sztprono_id ='010197198'
                             AND SZTPRONO_ENVIO_MOODL = 'N')
               LOOP
                  DBMS_OUTPUT.put_line (
                     ' Entra alumno no alumnos 3 ' || l_cuenta_alumnos);

                  BEGIN
                     INSERT INTO SZSTUME
                          VALUES (c.padre,
                                  d.pidm,
                                  d.matricula,
                                  SYSDATE,
                                  USER,
                                  5,
                                  NULL,
                                  d.pwd,
                                  NULL,
                                  1,
                                  d.estatus_alumno,
                                  0,
                                  c.materia,
                                  NULL,                            -- c.nivel,
                                  NULL,
                                  NULL,                             -- c.ptrm,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  c.materia,
                                  p_inicio_clase,          -- c.inicio_clases,
                                  c.regla,
                                  c.secuencia,
                                  1,
                                  0,
                                  null);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        DBMS_OUTPUT.put_line (
                           ' Error al insertar ' || SQLERRM);
                  END;

                  BEGIN
                     UPDATE SZTPRONO
                        SET SZTPRONO_ENVIO_MOODL = 'S',
                            SZTPRONO_GRUPO_ASIG = c.grupo
                      WHERE     1 = 1
                            AND SZTPRONO_MATERIA_LEGAL = c.materia
                            AND SZTPRONO_PIDM = d.pidm
                            AND SZTPRONO_NO_REGLA = c.regla
                            AND SZTPRONO_ENVIO_MOODL = 'N';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  END;

                  DBMS_OUTPUT.put_line (' Inserto');
               END LOOP;
            END LOOP;
         END LOOP;

         FOR c IN (SELECT *
                     FROM szstume
                    WHERE 1 = 1 AND szstume_no_regla = p_regla)
         LOOP
            BEGIN
               SELECT DISTINCT SGBSTDN_STST_CODE
                 INTO l_estatus_sgbstn
                 FROM sgbstdn a
                WHERE     1 = 1
                      AND a.sgbstdn_pidm = c.szstume_pidm
                      AND a.sgbstdn_term_code_eff =
                             (SELECT MAX (a1.sgbstdn_term_code_eff)
                                FROM sgbstdn a1
                               WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm);
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_estatus_sgbstn := NULL;
            END;

            IF l_estatus_sgbstn NOT IN ('AS', 'PR', 'MA')
            THEN
               BEGIN
                  UPDATE SZTPRONO
                     SET SZTPRONO_ENVIO_MOODL = 'N',
                         SZTPRONO_ESTATUS_ERROR = 'S',
                         SZTPRONO_DESCRIPCION_ERROR =
                               ' Este alumno se encuentra con estatus en gaston de '
                            || l_estatus_sgbstn
                   WHERE     1 = 1
                         AND SZTPRONO_MATERIA_LEGAL = c.szstume_subj_code
                         AND SZTPRONO_PIDM = c.szstume_pidm
                         AND SZTPRONO_NO_REGLA = c.szstume_no_regla;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;

               BEGIN
                  DELETE szstume
                   WHERE     1 = 1
                         AND szstume_subj_code = c.szstume_subj_code
                         AND szstume_pidm = c.szstume_pidm
                         AND szstume_no_regla = c.szstume_no_regla
                         AND szstume_term_nrc = c.szstume_term_nrc;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            END IF;
         END LOOP;
      END IF;

      COMMIT;

      RETURN (l_retorna);
   END;

   --
   --
   PROCEDURE p_inscr_individual (pn_fecha           VARCHAR2,
                                 p_regla            NUMBER,
                                 p_materia_legal    VARCHAR2,
                                 p_pidm             NUMBER)
   IS
      crn                    VARCHAR2 (20);
      gpo                    NUMBER;
      mate                   VARCHAR2 (20);
      ciclo                  VARCHAR2 (6);
      subj                   VARCHAR2 (4);
      crse                   VARCHAR2 (5);
      sb                     VARCHAR2 (4);
      cr                     VARCHAR2 (5);
      schd                   VARCHAR2 (3);
      title                  VARCHAR2 (30);
      credit                 DECIMAL (7, 3);
      credit_bill            DECIMAL (7, 3);
      gmod                   VARCHAR2 (1);
      f_inicio               DATE;
      f_fin                  DATE;
      sem                    NUMBER;
      conta_ptrm             NUMBER;
      conta_blck             NUMBER;
      pidm                   NUMBER;
      pidm_doc               NUMBER;
      pidm_doc2              NUMBER;
      ests                   VARCHAR2 (2);
      levl                   VARCHAR2 (2);
      camp                   VARCHAR2 (3);
      rsts                   VARCHAR2 (3);
      conta_origen           NUMBER := 0;
      conta_destino          NUMBER := 0;
      conta_origen_ssbsect   NUMBER := 0;
      conta_origen_ssrblck   NUMBER := 0;
      conta_origen_sobptrm   NUMBER := 0;
      sp                     INTEGER;
      ciclo_ext              VARCHAR2 (6);
      mensaje                VARCHAR2 (200);
      parte                  VARCHAR2 (3);
      pidm_prof              NUMBER;
      per                    VARCHAR2 (6);
      grupo                  VARCHAR2 (4);
      conta_sirasgn          NUMBER;
      fecha_ini              DATE;
      vl_existe              NUMBER := 0;

      vn_lugares             NUMBER := 0;
      vn_cupo_max            NUMBER := 0;
      vn_cupo_act            NUMBER := 0;
      vl_error               VARCHAR2 (2500) := 'EXITO';

      parteper_cur           VARCHAR2 (3);
      period_cur             VARCHAR2 (10);
      vl_jornada             VARCHAR2 (250) := NULL;
      vl_exite_prof          NUMBER := 0;
      l_contar               NUMBER := 0;
      l_maximo_alumnos       NUMBER;
      l_numero_contador      NUMBER;
      l_valida_order         NUMBER;
      L_DESCRIPCION_ERROR    VARCHAR2 (250) := NULL;
      l_valida               NUMBER;
      l_cuneta_prono         NUMBER;
      l_term_code            VARCHAR2 (10);
      l_ptrm                 VARCHAR2 (10);
      vl_orden               VARCHAR2 (10);
      l_cuenta_ni            NUMBER;
      l_cambio_estatus       NUMBER;
      l_type                 VARCHAR2 (20);
      l_pperiodo_ni          VARCHAR2 (20);
      l_campus_ms            VARCHAR2 (20);



      CURSOR c_no_proce
      IS
         SELECT *
           FROM szcarga carg
          WHERE     1 = 1
                AND szcarga_no_regla = p_regla
                AND SZCARGA_MATERIA = p_materia_legal
                AND ROWNUM = 1
                --and carg.SZCARGA_ID='010078157'
                AND NOT EXISTS
                       (SELECT 1
                          FROM szcarga
                               JOIN spriden
                                  ON     spriden_id = szcarga_id
                                     AND spriden_change_ind IS NULL
                               JOIN sgbstdn d
                                  ON     d.sgbstdn_pidm = spriden_pidm
                                     AND d.sgbstdn_term_code_eff =
                                            (SELECT MAX (
                                                       b1.sgbstdn_term_code_eff)
                                               FROM sgbstdn b1
                                              WHERE     1 = 1
                                                    AND d.sgbstdn_pidm =
                                                           b1.sgbstdn_pidm
                                                    AND d.sgbstdn_program_1 =
                                                           b1.sgbstdn_program_1)
                               JOIN sorlcur s
                                  ON     sorlcur_pidm = spriden_pidm
                                     AND s.sorlcur_program = szcarga_program
                                     AND s.sorlcur_lmod_code = 'LEARNER'
                                     AND s.sorlcur_seqno IN (SELECT MAX (
                                                                       ss.sorlcur_seqno)
                                                               FROM sorlcur ss
                                                              WHERE     1 = 1
                                                                    AND s.sorlcur_pidm =
                                                                           ss.sorlcur_pidm
                                                                    AND s.sorlcur_lmod_code =
                                                                           ss.sorlcur_lmod_code
                                                                    AND s.sorlcur_program =
                                                                           ss.sorlcur_program)
                               JOIN smrpaap
                                  ON     smrpaap_program = sorlcur_program
                                     AND smrpaap_term_code_eff =
                                            sorlcur_term_code_ctlg
                               JOIN scrtext ON scrtext_text = szcarga_materia
                               JOIN smrarul
                                  ON     smrarul_area = smrpaap_area
                                     AND smrarul_term_code_eff =
                                            smrpaap_term_code_eff
                               LEFT OUTER JOIN sztdtec
                                  ON     sztdtec_program = sorlcur_program
                                     AND sztdtec_term_code =
                                            sorlcur_term_code_ctlg
                         WHERE     smrarul_subj_code = scrtext_subj_code
                               AND smrarul_crse_numb_low = scrtext_crse_numb
                               AND carg.szcarga_id = spriden_id
                               AND carg.szcarga_materia = szcarga_materia
                               AND carg.szcarga_program = szcarga_program
                               AND carg.szcarga_fecha_ini = szcarga_fecha_ini
                               AND szcarga_no_regla = p_regla
                               AND sorlcur_pidm = p_pidm
                               AND szcarga_materia = p_materia_legal);
   BEGIN
      PKG_ALGORITMO.P_ENA_DIS_TRG ('D', 'SATURN.SZT_SSBSECT_POSTINSERT_ROW');
      PKG_ALGORITMO.P_ENA_DIS_TRG ('D', 'SATURN.SZT_SIRASGN_POSTINSERT_ROW');
      PKG_ALGORITMO.P_ENA_DIS_TRG ('D',
                                   'SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');


      BEGIN
         PKG_ALGORITMO.P_INSERTA_CARGA (p_regla, pn_fecha);
      EXCEPTION
         WHEN OTHERS
         THEN
            -- raise_application_error (-20002,'ERROR al insertar en carga '||sqlerrm);
            NULL;
      END;

      DBMS_OUTPUT.PUT_LINE ('pasa la carga ');

      BEGIN
         SELECT COUNT (*)
           INTO l_contar
           FROM SZCARGA
          WHERE 1 = 1 AND SZCARGA_NO_REGLA = p_regla;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      IF l_contar > 0
      THEN
         fecha_ini := TO_DATE (pn_fecha, 'DD/MM/RRRR');

         DBMS_OUTPUT.PUT_LINE ('antes cursor ' || p_materia_legal);

         FOR c
            IN (  SELECT DISTINCT
                         spriden_pidm pidm,
                         szcarga_id iden,
                         szcarga_program prog,
                         sorlcur_camp_code campus,
                         sorlcur_levl_code nivel,
                         sorlcur_term_code_ctlg ctlg,
                         szcarga_materia materia,
                         smrarul_subj_code subj,
                         smrarul_crse_numb_low crse,
                         szcarga_term_code periodo,
                         szcarga_ptrm_code parte,
                         DECODE (sztdtec_periodicidad,
                                 1, 'BIMESTRAL',
                                 2, 'CUATRIMESTRAL')
                            periodicidad,
                         NVL (szcarga_grupo, '01') grupo,
                         --szcarga_grupo grupo,
                         szcarga_calif calif,
                         szcarga_id_prof prof,
                         szcarga_fecha_ini fecha_inicio,
                         sorlcur_key_seqno study,
                         d.sgbstdn_stst_code,
                         d.sgbstdn_styp_code,
                         sgbstdn_rate_code RATE
                    FROM szcarga a
                         JOIN spriden
                            ON     spriden_id = szcarga_id
                               AND spriden_change_ind IS NULL
                         JOIN sgbstdn d
                            ON     d.sgbstdn_pidm = spriden_pidm
                               AND d.sgbstdn_term_code_eff =
                                      (SELECT MAX (b1.sgbstdn_term_code_eff)
                                         FROM sgbstdn b1
                                        WHERE     1 = 1
                                              AND d.sgbstdn_pidm =
                                                     b1.sgbstdn_pidm
                                              AND d.sgbstdn_program_1 =
                                                     b1.sgbstdn_program_1)
                         JOIN sorlcur s
                            ON     sorlcur_pidm = spriden_pidm
                               AND s.sorlcur_pidm = d.sgbstdn_pidm
                               AND s.sorlcur_program = d.sgbstdn_program_1
                               AND sorlcur_program = szcarga_program
                               AND sorlcur_lmod_code = 'LEARNER'
                               AND sorlcur_seqno IN (SELECT MAX (sorlcur_seqno)
                                                       FROM sorlcur ss
                                                      WHERE     1 = 1
                                                            AND s.sorlcur_pidm =
                                                                   ss.sorlcur_pidm
                                                            AND s.sorlcur_lmod_code =
                                                                   ss.sorlcur_lmod_code
                                                            AND s.sorlcur_program =
                                                                   ss.sorlcur_program)
                         LEFT OUTER JOIN sztdtec
                            ON     sztdtec_program = sorlcur_program
                               AND sztdtec_term_code = sorlcur_term_code_ctlg
                         JOIN smrpaap
                            ON     smrpaap_program = sorlcur_program
                               AND smrpaap_term_code_eff =
                                      sorlcur_term_code_ctlg
                         JOIN sztmaco ON SZTMACO_MATPADRE = szcarga_materia
                         JOIN smrarul
                            ON               /*smrarul_area=smrpaap_area AND*/
                              smrarul_term_code_eff = smrpaap_term_code_eff
                   WHERE     1 = 1
                         --AND smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
                         AND szcarga_no_regla = p_regla
                         AND spriden_pidm = p_pidm
                         AND SZCARGA_MATERIA = p_materia_legal
                         AND ROWNUM = 1
                ORDER BY iden, 10)
         LOOP
            DBMS_OUTPUT.PUT_LINE ('Entradndo al cursor ');

            DBMS_OUTPUT.PUT_LINE ('Entra a cursor normal ');

            --------------- Limpia Variables --------------------
            --niv := null;
            parte := NULL;
            crn := NULL;
            pidm_doc2 := NULL;
            conta_sirasgn := NULL;
            pidm_doc := NULL;
            f_inicio := NULL;
            f_fin := NULL;
            sem := NULL;
            schd := NULL;
            title := NULL;
            credit := NULL;
            credit_bill := NULL;
            levl := NULL;
            camp := NULL;
            mate := NULL;
            parte := NULL;
            per := NULL;
            -- grupo := NULL;
            vl_existe := 0;
            vl_error := 'EXITO';
            vn_lugares := 0;
            vn_cupo_max := 0;
            vn_cupo_act := 0;

            parteper_cur := NULL;
            period_cur := NULL;
            vl_exite_prof := 0;

            BEGIN
               SELECT DISTINCT SFRSTCR_VPDI_CODE
                 INTO VL_ORDEN
                 FROM SFRSTCR
                WHERE     SFRSTCR_PIDM = C.PIDM
                      AND SFRSTCR_TERM_CODE = C.PERIODO
                      AND SFRSTCR_PTRM_CODE = C.PARTE
                      AND SFRSTCR_RSTS_CODE = 'RE'
                      AND SFRSTCR_VPDI_CODE IS NOT NULL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     SELECT TBRACCD_RECEIPT_NUMBER
                       INTO VL_ORDEN
                       FROM TBRACCD A
                      WHERE     A.TBRACCD_PIDM = C.PIDM
                            AND A.TBRACCD_TERM_CODE = C.PERIODO
                            AND A.TBRACCD_PERIOD = C.PARTE
                            AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                            FROM TBBDETC
                                                           WHERE TBBDETC_DCAT_CODE =
                                                                    'COL')
                            AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                            AND A.TBRACCD_TRAN_NUMBER =
                                   (SELECT MAX (TBRACCD_TRAN_NUMBER)
                                      FROM TBRACCD A1
                                     WHERE     A1.TBRACCD_PIDM =
                                                  A.TBRACCD_PIDM
                                           AND A1.TBRACCD_TERM_CODE =
                                                  A.TBRACCD_TERM_CODE
                                           AND A1.TBRACCD_PERIOD =
                                                  A.TBRACCD_PERIOD
                                           AND A1.TBRACCD_DETAIL_CODE =
                                                  A.TBRACCD_DETAIL_CODE
                                           AND A1.TBRACCD_DOCUMENT_NUMBER
                                                  IS NULL);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        VL_ORDEN := NULL;
                  END;
            END;


            IF c.sgbstdn_stst_code IN ('AS', 'PR', 'MA')
            THEN
               ----------------- Se valida que el alumno no tenga la materia sembrada en el horario como Activa ---------------------------------------

               DBMS_OUTPUT.PUT_LINE ('Entra a cursor normal ');

               BEGIN
                    --existe y es aprobatoria
                    SELECT COUNT (1), sfrstcr_term_code, sfrstcr_ptrm_code
                      INTO vl_existe, period_cur, parteper_cur
                      FROM ssbsect, sfrstcr, shrgrde
                     WHERE     1 = 1
                           AND sfrstcr_pidm = c.pidm
                           AND ssbsect_term_code = sfrstcr_term_code
                           AND sfrstcr_ptrm_code = ssbsect_ptrm_code
                           AND ssbsect_crn = sfrstcr_crn
                           AND ssbsect_subj_code = c.subj
                           AND ssbsect_crse_numb = c.crse
                           AND sfrstcr_rsts_code = 'RE'
                           AND (   sfrstcr_grde_code = shrgrde_code
                                OR sfrstcr_grde_code IS NULL)
                           AND SUBSTR (sfrstcr_term_code, 5, 1) NOT IN ('8',
                                                                        '9')
                           AND shrgrde_passed_ind = 'Y'
                           AND shrgrde_levl_code = c.nivel
                           /* cambio escalas para prod */
                           AND shrgrde_term_code_effective =
                                  (SELECT zstpara_param_desc
                                     FROM zstpara
                                    WHERE     zstpara_mapa_id = 'ESC_SHAGRD'
                                          AND SUBSTR (
                                                 (SELECT f_getspridenid (
                                                            p_pidm)
                                                    FROM DUAL),
                                                 1,
                                                 2) = zstpara_param_id
                                          AND zstpara_param_valor = c.nivel)
                  /* cambio escalas para prod */
                  GROUP BY sfrstcr_term_code, sfrstcr_ptrm_code;

                  DBMS_OUTPUT.PUT_LINE ('Entrando aqui ' || vl_existe);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vl_existe := 0;
                     DBMS_OUTPUT.PUT_LINE (
                           'Error lll '
                        || ' SUBJ '
                        || c.subj
                        || ' crse '
                        || c.crse
                        || ' nivel '
                        || c.nivel);
               END;

               DBMS_OUTPUT.PUT_LINE ('Entra a existe ' || vl_existe);

               IF vl_existe = 0
               THEN
                  ---- Se busca que exista el grupo y tenga cupo


                  --DBMS_OUTPUT.PUT_LINE('Entra 3');

                  DBMS_OUTPUT.put_line ('sin profesor ' || vl_existe);

                  BEGIN
                     SELECT ct.ssbsect_crn,
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
                       INTO crn,
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
                            AND ct.ssbsect_term_code = c.periodo
                            AND ct.ssbsect_subj_code = c.subj
                            AND ct.ssbsect_crse_numb = c.crse
                            AND ct.ssbsect_seq_numb = c.grupo
                            AND ct.ssbsect_ptrm_code = c.parte
                            AND TRUNC (ct.ssbsect_ptrm_start_date) =
                                   c.Fecha_Inicio
                            AND ct.ssbsect_seats_avail > 0
                            AND ct.ssbsect_seats_avail IN (SELECT MAX (
                                                                     a1.ssbsect_seats_avail)
                                                             FROM ssbsect a1
                                                            WHERE     a1.ssbsect_term_code =
                                                                         ct.ssbsect_term_code
                                                                  AND a1.ssbsect_seq_numb =
                                                                         ct.ssbsect_seq_numb
                                                                  AND a1.ssbsect_subj_code =
                                                                         ct.ssbsect_subj_code
                                                                  AND a1.ssbsect_crse_numb =
                                                                         ct.ssbsect_crse_numb
                                                                  AND TRUNC (
                                                                         a1.ssbsect_ptrm_start_date) =
                                                                         TRUNC (
                                                                            ct.ssbsect_ptrm_start_date));
                  -- DBMS_OUTPUT.PUT_LINE('Entra 4');

                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        crn := NULL;
                        vn_lugares := 0;
                        vn_cupo_max := 0;
                        vn_cupo_act := 0;
                        f_inicio := NULL;
                        f_fin := NULL;
                        sem := NULL;
                        credit := NULL;
                        credit_bill := NULL;
                        gmod := NULL;
                  END;



                  IF crn IS NOT NULL
                  THEN
                     DBMS_OUTPUT.put_line ('CRN no es null XX ' || crn);

                     IF vn_cupo_act > 0
                     THEN
                        IF credit IS NULL
                        THEN
                           BEGIN
                              SELECT ssrmeet_credit_hr_sess
                                INTO credit
                                FROM ssrmeet
                               WHERE     1 = 1
                                     AND ssrmeet_term_code = c.periodo
                                     AND ssrmeet_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 credit := NULL;
                           END;

                           IF credit IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_credit_hrs = credit
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;
                           END IF;
                        END IF;

                        IF credit_bill IS NULL
                        THEN
                           credit_bill := 1;

                           IF credit IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_bill_hrs = credit_bill
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;
                           END IF;
                        END IF;

                        IF gmod IS NULL
                        THEN
                           BEGIN
                              SELECT scrgmod_gmod_code
                                INTO gmod
                                FROM scrgmod
                               WHERE     1 = 1
                                     AND scrgmod_subj_code = c.subj
                                     AND scrgmod_crse_numb = c.crse
                                     AND scrgmod_default_ind = 'D';
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 gmod := '1';
                           END;

                           IF gmod IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_gmod_code = gmod
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;
                           END IF;
                        END IF;

                        BEGIN
                           SELECT spriden_pidm
                             INTO pidm_prof
                             FROM spriden
                            WHERE     1 = 1
                                  AND spriden_id = c.prof
                                  AND spriden_change_ind IS NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              pidm_prof := NULL;
                        END;

                        conta_ptrm := 0;

                        BEGIN
                           SELECT COUNT (1)
                             INTO conta_ptrm
                             FROM sirasgn
                            WHERE     SIRASGN_TERM_CODE = c.periodo
                                  AND SIRASGN_CRN = crn
                                  AND SIRASGN_PIDM = pidm_prof
                                  AND SIRASGN_PRIMARY_IND = 'Y';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              conta_ptrm := 0;
                        END;

                        IF pidm_prof IS NOT NULL AND conta_ptrm = 0
                        THEN
                           BEGIN
                              INSERT INTO sirasgn
                                   VALUES (c.periodo,
                                           crn,
                                           pidm_prof,
                                           '01',
                                           100,
                                           NULL,
                                           100,
                                           'Y',
                                           NULL,
                                           NULL,
                                           SYSDATE - 5,
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
                                           NULL);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        END IF;

                        conta_ptrm := 0;

                        BEGIN
                           SELECT COUNT (*)
                             INTO conta_ptrm
                             FROM sfbetrm
                            WHERE     1 = 1
                                  AND sfbetrm_term_code = c.periodo
                                  AND sfbetrm_pidm = c.pidm;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              conta_ptrm := 0;
                        END;


                        IF conta_ptrm = 0
                        THEN
                           BEGIN
                              INSERT INTO sfbetrm
                                   VALUES (c.periodo,
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
                                           NULL);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                    (   'Se presento un error al insertar en la tabla sfbetrm '
                                     || SQLERRM);
                           END;
                        END IF;

                        BEGIN
                           BEGIN
                              INSERT INTO sfrstcr
                                   VALUES (c.periodo,      --SFRSTCR_TERM_CODE
                                           c.pidm,              --SFRSTCR_PIDM
                                           crn,                  --SFRSTCR_CRN
                                           1,         --SFRSTCR_CLASS_SORT_KEY
                                           c.grupo,          --SFRSTCR_REG_SEQ
                                           parte,          --SFRSTCR_PTRM_CODE
                                           'RE',           --SFRSTCR_RSTS_CODE
                                           SYSDATE - 5,    --SFRSTCR_RSTS_DATE
                                           NULL,          --SFRSTCR_ERROR_FLAG
                                           NULL,             --SFRSTCR_MESSAGE
                                           credit_bill,      --SFRSTCR_BILL_HR
                                           3,                --SFRSTCR_WAIV_HR
                                           credit,         --SFRSTCR_CREDIT_HR
                                           credit_bill, --SFRSTCR_BILL_HR_HOLD
                                           credit,    --SFRSTCR_CREDIT_HR_HOLD
                                           gmod,           --SFRSTCR_GMOD_CODE
                                           NULL,           --SFRSTCR_GRDE_CODE
                                           NULL,       --SFRSTCR_GRDE_CODE_MID
                                           NULL,           --SFRSTCR_GRDE_DATE
                                           'N',            --SFRSTCR_DUPL_OVER
                                           'N',            --SFRSTCR_LINK_OVER
                                           'N',            --SFRSTCR_CORQ_OVER
                                           'N',            --SFRSTCR_PREQ_OVER
                                           'N',            --SFRSTCR_TIME_OVER
                                           'N',            --SFRSTCR_CAPC_OVER
                                           'N',            --SFRSTCR_LEVL_OVER
                                           'N',            --SFRSTCR_COLL_OVER
                                           'N',            --SFRSTCR_MAJR_OVER
                                           'N',            --SFRSTCR_CLAS_OVER
                                           'N',            --SFRSTCR_APPR_OVER
                                           'N',    --SFRSTCR_APPR_RECEIVED_IND
                                           SYSDATE - 5,     --SFRSTCR_ADD_DATE
                                           SYSDATE - 5, --SFRSTCR_ACTIVITY_DATE
                                           c.nivel,        --SFRSTCR_LEVL_CODE
                                           c.campus,       --SFRSTCR_CAMP_CODE
                                           c.materia,   --SFRSTCR_RESERVED_KEY
                                           NULL,           --SFRSTCR_ATTEND_HR
                                           'Y',            --SFRSTCR_REPT_OVER
                                           'N',            --SFRSTCR_RPTH_OVER
                                           NULL,           --SFRSTCR_TEST_OVER
                                           'N',            --SFRSTCR_CAMP_OVER
                                           USER,                --SFRSTCR_USER
                                           'N',            --SFRSTCR_DEGC_OVER
                                           'N',            --SFRSTCR_PROG_OVER
                                           NULL,         --SFRSTCR_LAST_ATTEND
                                           NULL,           --SFRSTCR_GCMT_CODE
                                           'PRONOSTICO', --SFRSTCR_DATA_ORIGIN
                                           SYSDATE, --SFRSTCR_ASSESS_ACTIVITY_DATE
                                           'N',            --SFRSTCR_DEPT_OVER
                                           'N',            --SFRSTCR_ATTS_OVER
                                           'N',            --SFRSTCR_CHRT_OVER
                                           c.grupo,         --SFRSTCR_RMSG_CDE
                                           NULL,         --SFRSTCR_WL_PRIORITY
                                           NULL,    --SFRSTCR_WL_PRIORITY_ORIG
                                           NULL, --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                           NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                           'N',            --SFRSTCR_MEXC_OVER
                                           c.study, --SFRSTCR_STSP_KEY_SEQUENCE
                                           NULL,        --SFRSTCR_BRDH_SEQ_NUM
                                           '01',           --SFRSTCR_BLCK_CODE
                                           NULL,          --SFRSTCR_STRH_SEQNO
                                           NULL,          --SFRSTCR_STRD_SEQNO
                                           NULL,        --SFRSTCR_SURROGATE_ID
                                           NULL,             --SFRSTCR_VERSION
                                           USER,             --SFRSTCR_USER_ID
                                           vl_orden        --SFRSTCR_VPDI_CODE
                                                   );
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 DBMS_OUTPUT.put_line (
                                    'Error al insertar SFRSTCR ' || SQLERRM);
                           END;


                           BEGIN
                              UPDATE ssbsect
                                 SET ssbsect_enrl = ssbsect_enrl + 1
                               WHERE     1 = 1
                                     AND ssbsect_term_code = c.periodo
                                     AND ssbsect_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al actualizar el enrolamiento '
                                    || SQLERRM;
                           END;

                           BEGIN
                              UPDATE SZTPRONO
                                 SET SZTPRONO_ENVIO_HORARIOS = 'S'
                               WHERE     1 = 1
                                     AND SZTPRONO_NO_REGLA = p_regla
                                     AND SZTPRONO_FECHA_INICIO = pn_fecha
                                     AND SZTPRONO_PIDM = c.pidm
                                     AND sztprono_materia_legal = c.materia
                                     AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                     AND SZTPRONO_PTRM_CODE = parte;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;

                           BEGIN
                              UPDATE ssbsect
                                 SET ssbsect_seats_avail =
                                        ssbsect_seats_avail - 1
                               WHERE     1 = 1
                                     AND ssbsect_term_code = c.periodo
                                     AND ssbsect_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al actualizar la disponibilidad del grupo '
                                    || SQLERRM;
                           END;

                           BEGIN
                              UPDATE ssbsect
                                 SET ssbsect_census_enrl = ssbsect_enrl
                               WHERE     1 = 1
                                     AND ssbsect_term_code = c.periodo
                                     AND ssbsect_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al actualizar el Censo del grupo '
                                    || SQLERRM;
                           END;


                           IF C.SGBSTDN_STYP_CODE = 'F'
                           THEN
                              BEGIN
                                 UPDATE sgbstdn a
                                    SET a.sgbstdn_styp_code = 'N',
                                        a.SGBSTDN_DATA_ORIGIN = 'PRONOSTICO',
                                        A.SGBSTDN_USER_ID = USER
                                  WHERE     1 = 1
                                        AND a.sgbstdn_pidm = c.pidm
                                        AND a.sgbstdn_term_code_eff =
                                               (SELECT MAX (
                                                          a1.sgbstdn_term_code_eff)
                                                  FROM sgbstdn a1
                                                 WHERE     a1.sgbstdn_pidm =
                                                              a.sgbstdn_pidm
                                                       AND a1.sgbstdn_program_1 =
                                                              a.sgbstdn_program_1)
                                        AND a.sgbstdn_program_1 = c.prog;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                       || SQLERRM;
                              END;
                           END IF;


                           BEGIN
                              SELECT COUNT (*)
                                INTO l_cambio_estatus
                                FROM sfrstcr
                               WHERE     1 = 1
                                     AND    SFRSTCR_TERM_CODE
                                         || SFRSTCR_PTRM_CODE =
                                            c.periodo || c.parte
                                     AND sfrstcr_pidm = c.pidm
                                     AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 l_cambio_estatus := 0;
                           END;


                           IF l_cambio_estatus > 0
                           THEN
                              IF C.SGBSTDN_STYP_CODE IN ('N', 'R')
                              THEN
                                 BEGIN
                                    UPDATE sgbstdn a
                                       SET a.sgbstdn_styp_code = 'C',
                                           a.SGBSTDN_DATA_ORIGIN =
                                              'PRONOSTICO',
                                           A.SGBSTDN_USER_ID = USER
                                     WHERE     1 = 1
                                           AND a.sgbstdn_pidm = c.pidm
                                           AND a.sgbstdn_term_code_eff =
                                                  (SELECT MAX (
                                                             a1.sgbstdn_term_code_eff)
                                                     FROM sgbstdn a1
                                                    WHERE     a1.sgbstdn_pidm =
                                                                 a.sgbstdn_pidm
                                                          AND a1.sgbstdn_program_1 =
                                                                 a.sgbstdn_program_1)
                                           AND a.sgbstdn_program_1 = c.prog;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                          || SQLERRM;
                                 END;
                              END IF;
                           END IF;

                           --

                           IF c.fecha_inicio IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE sorlcur
                                    SET sorlcur_start_date =
                                           TRUNC (c.fecha_inicio),
                                        sorlcur_data_origin = 'PRONOSTICO',
                                        sorlcur_user_id = USER,
                                        SORLCUR_RATE_CODE = c.rate
                                  WHERE     1 = 1
                                        AND sorlcur_pidm = c.pidm
                                        AND sorlcur_program = c.prog
                                        AND sorlcur_lmod_code = 'LEARNER'
                                        AND sorlcur_key_seqno = c.study;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur '
                                       || SQLERRM;
                              END;
                           END IF;

                           conta_ptrm := 0;

                           BEGIN
                              SELECT COUNT (*)
                                INTO conta_ptrm
                                FROM sfrareg
                               WHERE     1 = 1
                                     AND sfrareg_pidm = c.pidm
                                     AND sfrareg_term_code = c.periodo
                                     AND sfrareg_crn = crn
                                     AND sfrareg_extension_number = 0
                                     AND sfrareg_rsts_code = 'RE';
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 conta_ptrm := 0;
                           END;

                           IF conta_ptrm = 0
                           THEN
                              BEGIN
                                 INSERT INTO sfrareg
                                      VALUES (c.pidm,
                                              c.periodo,
                                              crn,
                                              0,
                                              'RE',
                                              NVL (c.fecha_inicio, pn_fecha),
                                              NVL (f_fin, SYSDATE),
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
                                              NULL);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar el registro de la materia para el alumno '
                                       || SQLERRM;
                              END;
                           END IF;


                           BEGIN
                              SELECT COUNT (1)
                                INTO vl_existe
                                FROM SHRINST
                               WHERE     1 = 1
                                     AND shrinst_term_code = c.periodo
                                     AND shrinst_crn = crn
                                     AND shrinst_pidm = c.pidm;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_existe := 0;
                           END;

                           IF vl_existe = 0
                           THEN
                              BEGIN
                                 INSERT INTO SHRINST
                                      VALUES (c.periodo,   --SHRINST_TERM_CODE
                                              crn,               --SHRINST_CRN
                                              c.pidm,           --SHRINST_PIDM
                                              SYSDATE, --SHRINST_ACTIVITY_DATE
                                              'Y',       --SHRINST_PRIMARY_IND
                                              NULL,     --SHRINST_SURROGATE_ID
                                              NULL,          --SHRINST_VERSION
                                              USER,          --SHRINST_USER_ID
                                              'PRONOSTICO', --SHRINST_DATA_ORIGIN
                                              NULL);       --SHRINST_VPDI_CODE
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar al alumno en SHRINST '
                                       || SQLERRM;
                              END;
                           END IF;

                           BEGIN
                              UPDATE SZTPRONO
                                 SET SZTPRONO_ENVIO_HORARIOS = 'S'
                               WHERE     1 = 1
                                     AND SZTPRONO_NO_REGLA = p_regla
                                     AND SZTPRONO_FECHA_INICIO = pn_fecha
                                     AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                     AND sztprono_materia_legal = c.materia
                                     AND SZTPRONO_PIDM = c.pidm
                                     AND SZTPRONO_PTRM_CODE = parte;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              vl_error :=
                                    'Se presento un error al insertar al alumno en el grupo '
                                 || SQLERRM;
                        END;
                     ELSE
                        DBMS_OUTPUT.put_line (
                           'mensaje:' || 'No hay cupo en el grupo creado');
                        schd := NULL;
                        title := NULL;
                        credit := NULL;
                        gmod := NULL;
                        f_inicio := NULL;
                        f_fin := NULL;
                        sem := NULL;
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
                             FROM scbcrse, scrschd
                            WHERE     1 = 1
                                  AND scbcrse_subj_code = c.subj
                                  AND scbcrse_crse_numb = c.crse
                                  AND scbcrse_eff_term = '000000'
                                  AND scrschd_subj_code = scbcrse_subj_code
                                  AND scrschd_crse_numb = scbcrse_crse_numb
                                  AND scrschd_eff_term = scbcrse_eff_term;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              schd := NULL;
                              title := NULL;
                              credit := NULL;
                              credit_bill := NULL;
                        END;


                        BEGIN
                           SELECT scrgmod_gmod_code
                             INTO gmod
                             FROM scrgmod
                            WHERE     scrgmod_subj_code = c.subj
                                  AND scrgmod_crse_numb = c.crse
                                  AND scrgmod_default_ind = 'D';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              gmod := '1';
                        END;


                        IF c.prof IS NULL
                        THEN
                           crn := crn;

                           IF c.nivel = 'MS'
                           THEN
                              l_campus_ms := 'AS';
                           ELSE
                              l_campus_ms := c.niVel;
                           END IF;


                           BEGIN
                              SELECT sztcrnv_crn
                                INTO crn
                                FROM SZTCRNV
                               WHERE     1 = 1
                                     AND ROWNUM = 1
                                     AND SZTCRNV_LVEL_CODE =
                                            SUBSTR (l_campus_ms, 1, 1)
                                     AND (SZTCRNV_crn, SZTCRNV_LVEL_CODE) NOT IN (SELECT TO_NUMBER (
                                                                                            crn),
                                                                                         SUBSTR (
                                                                                            SSBSECT_CRN,
                                                                                            1,
                                                                                            1)
                                                                                    FROM (SELECT CASE
                                                                                                    WHEN SUBSTR (
                                                                                                            SSBSECT_CRN,
                                                                                                            1,
                                                                                                            1) IN ('L',
                                                                                                                   'M',
                                                                                                                   'A',
                                                                                                                   'D',
                                                                                                                   'B')
                                                                                                    THEN
                                                                                                       TO_NUMBER (
                                                                                                          SUBSTR (
                                                                                                             SSBSECT_CRN,
                                                                                                             2,
                                                                                                             10))
                                                                                                    ELSE
                                                                                                       TO_NUMBER (
                                                                                                          SSBSECT_CRN)
                                                                                                 END
                                                                                                    crn,
                                                                                                 SSBSECT_CRN
                                                                                            FROM ssbsect
                                                                                           WHERE     1 =
                                                                                                        1
                                                                                                 AND ssbsect_term_code =
                                                                                                        c.periodo-- AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                         )
                                                                                   WHERE 1 =
                                                                                            1);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 -- raise_application_error (-20002,'Error al 2 '|| SQLCODE||' Error: '||SQLERRM);
                                 DBMS_OUTPUT.put_line (
                                    ' error en crn 2 ' || SQLERRM);
                                 crn := NULL;
                           END;

                           IF crn IS NOT NULL
                           THEN
                              IF c.nivel = 'LI'
                              THEN
                                 crn := 'L' || crn;
                              ELSE
                                 crn := 'M' || crn;
                              END IF;
                           ELSE
                              BEGIN
                                 SELECT   NVL (MAX (TO_NUMBER (SSBSECT_CRN)),
                                               0)
                                        + 1
                                   INTO crn
                                   FROM ssbsect
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND SUBSTR (ssbsect_crn, 1, 1) NOT IN ('L',
                                                                               'M',
                                                                               'A',
                                                                               'D',
                                                                               'B');
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    DBMS_OUTPUT.put_line (
                                       'sqlerrm ' || crn || ' ' || SQLERRM);
                                    crn := NULL;
                              END;

                              DBMS_OUTPUT.put_line ('crn ' || crn);
                           END IF;
                        END IF;

                        BEGIN
                           SELECT DISTINCT
                                  sobptrm_start_date,
                                  sobptrm_end_date,
                                  sobptrm_weeks
                             INTO f_inicio, f_fin, sem
                             FROM sobptrm
                            WHERE     1 = 1
                                  AND sobptrm_term_code = c.periodo
                                  AND sobptrm_ptrm_code = c.parte;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        IF crn IS NOT NULL
                        THEN
                           BEGIN
                              l_maximo_alumnos := 90;
                           END;


                           --raise_application_error (-20002,'Buscamos SSBSECT_CENSUS_ENRL_DATE '||f_inicio);

                           BEGIN
                              INSERT INTO ssbsect
                                   VALUES (c.periodo,      --SSBSECT_TERM_CODE
                                           crn,                  --SSBSECT_CRN
                                           c.parte,        --SSBSECT_PTRM_CODE
                                           c.subj,         --SSBSECT_SUBJ_CODE
                                           c.crse,         --SSBSECT_CRSE_NUMB
                                           c.grupo,         --SSBSECT_SEQ_NUMB
                                           'A',            --SSBSECT_SSTS_CODE
                                           'ENL',          --SSBSECT_SCHD_CODE
                                           c.campus,       --SSBSECT_CAMP_CODE
                                           title,         --SSBSECT_CRSE_TITLE
                                           credit,        --SSBSECT_CREDIT_HRS
                                           credit_bill,     --SSBSECT_BILL_HRS
                                           gmod,           --SSBSECT_GMOD_CODE
                                           NULL,           --SSBSECT_SAPR_CODE
                                           NULL,           --SSBSECT_SESS_CODE
                                           NULL,          --SSBSECT_LINK_IDENT
                                           NULL,            --SSBSECT_PRNT_IND
                                           'Y',         --SSBSECT_GRADABLE_IND
                                           NULL,            --SSBSECT_TUIW_IND
                                           0,              --SSBSECT_REG_ONEUP
                                           0,             --SSBSECT_PRIOR_ENRL
                                           0,              --SSBSECT_PROJ_ENRL
                                           l_maximo_alumnos, --SSBSECT_MAX_ENRL
                                           0,                   --SSBSECT_ENRL
                                           l_maximo_alumnos, --SSBSECT_SEATS_AVAIL
                                           NULL,      --SSBSECT_TOT_CREDIT_HRS
                                           '0',          --SSBSECT_CENSUS_ENRL
                                           f_inicio, --SSBSECT_CENSUS_ENRL_DATE
                                           SYSDATE - 5, --SSBSECT_ACTIVITY_DATE
                                           f_inicio, --SSBSECT_PTRM_START_DATE
                                           f_fin,      --SSBSECT_PTRM_END_DATE
                                           sem,           --SSBSECT_PTRM_WEEKS
                                           NULL,        --SSBSECT_RESERVED_IND
                                           NULL,       --SSBSECT_WAIT_CAPACITY
                                           NULL,          --SSBSECT_WAIT_COUNT
                                           NULL,          --SSBSECT_WAIT_AVAIL
                                           NULL,              --SSBSECT_LEC_HR
                                           NULL,              --SSBSECT_LAB_HR
                                           NULL,              --SSBSECT_OTH_HR
                                           NULL,             --SSBSECT_CONT_HR
                                           NULL,           --SSBSECT_ACCT_CODE
                                           NULL,           --SSBSECT_ACCL_CODE
                                           NULL,       --SSBSECT_CENSUS_2_DATE
                                           NULL,   --SSBSECT_ENRL_CUT_OFF_DATE
                                           NULL,   --SSBSECT_ACAD_CUT_OFF_DATE
                                           NULL,   --SSBSECT_DROP_CUT_OFF_DATE
                                           NULL,       --SSBSECT_CENSUS_2_ENRL
                                           'Y',          --SSBSECT_VOICE_AVAIL
                                           'N', --SSBSECT_CAPP_PREREQ_TEST_IND
                                           NULL,           --SSBSECT_GSCH_NAME
                                           NULL,        --SSBSECT_BEST_OF_COMP
                                           NULL,      --SSBSECT_SUBSET_OF_COMP
                                           'NOP',          --SSBSECT_INSM_CODE
                                           NULL,       --SSBSECT_REG_FROM_DATE
                                           NULL,         --SSBSECT_REG_TO_DATE
                                           NULL, --SSBSECT_LEARNER_REGSTART_FDATE
                                           NULL, --SSBSECT_LEARNER_REGSTART_TDATE
                                           NULL,           --SSBSECT_DUNT_CODE
                                           NULL,     --SSBSECT_NUMBER_OF_UNITS
                                           0,   --SSBSECT_NUMBER_OF_EXTENSIONS
                                           'PRONOSTICO', --SSBSECT_DATA_ORIGIN
                                           USER,             --SSBSECT_USER_ID
                                           'MOOD',          --SSBSECT_INTG_CDE
                                           'B', --SSBSECT_PREREQ_CHK_METHOD_CDE
                                           USER,    --SSBSECT_KEYWORD_INDEX_ID
                                           NULL,     --SSBSECT_SCORE_OPEN_DATE
                                           NULL,   --SSBSECT_SCORE_CUTOFF_DATE
                                           NULL, --SSBSECT_REAS_SCORE_OPEN_DATE
                                           NULL, --SSBSECT_REAS_SCORE_CTOF_DATE
                                           NULL,        --SSBSECT_SURROGATE_ID
                                           NULL,             --SSBSECT_VERSION
                                           NULL);          --SSBSECT_VPDI_CODE


                              BEGIN
                                 UPDATE sobterm
                                    SET sobterm_crn_oneup = crn
                                  WHERE     1 = 1
                                        AND sobterm_term_code = c.periodo;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;



                              BEGIN
                                 INSERT INTO ssrmeet
                                      VALUES (C.periodo,
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
                                              NULL);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un Error al insertar en ssrmeet '
                                       || SQLERRM;
                              END;

                              BEGIN
                                 SELECT spriden_pidm
                                   INTO pidm_prof
                                   FROM spriden
                                  WHERE     1 = 1
                                        AND spriden_id = c.prof
                                        AND spriden_change_ind IS NULL;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    pidm_prof := NULL;
                              END;

                              IF pidm_prof IS NOT NULL
                              THEN
                                 DBMS_OUTPUT.put_line (
                                       'Crea el CRN para el docente:'
                                    || pidm_prof
                                    || '*'
                                    || crn);

                                 BEGIN
                                    SELECT COUNT (1)
                                      INTO vl_exite_prof
                                      FROM sirasgn
                                     WHERE     1 = 1
                                           AND sirasgn_term_code = c.periodo
                                           AND sirasgn_crn = crn;
                                 -- And SIRASGN_PIDM = pidm_prof;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_exite_prof := 0;
                                 END;

                                 IF vl_exite_prof = 0
                                 THEN
                                    BEGIN
                                       INSERT INTO sirasgn
                                            VALUES (c.periodo,
                                                    crn,
                                                    pidm_prof,
                                                    '01',
                                                    100,
                                                    NULL,
                                                    100,
                                                    'Y',
                                                    NULL,
                                                    NULL,
                                                    SYSDATE - 5,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    'PRONOSTICO',
                                                    'SZFALGO 2',
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL);
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          NULL;
                                    END;
                                 ELSE
                                    BEGIN
                                       UPDATE sirasgn
                                          SET sirasgn_primary_ind = NULL
                                        WHERE     1 = 1
                                              AND sirasgn_term_code =
                                                     c.periodo
                                              AND sirasgn_crn = crn;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          NULL;
                                    END;

                                    BEGIN
                                       INSERT INTO sirasgn
                                            VALUES (c.periodo,
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
                                                    NULL);
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          NULL;
                                    END;
                                 END IF;
                              END IF;

                              conta_ptrm := 0;

                              BEGIN
                                 SELECT COUNT (*)
                                   INTO conta_ptrm
                                   FROM sfbetrm
                                  WHERE     1 = 1
                                        AND sfbetrm_term_code = c.periodo
                                        AND sfbetrm_pidm = c.pidm;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    conta_ptrm := 0;
                              END;


                              IF conta_ptrm = 0
                              THEN
                                 BEGIN
                                    INSERT INTO sfbetrm
                                         VALUES (c.periodo,
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                          (   'Se presento un error al insertar en la tabla sfbetrm '
                                           || SQLERRM);
                                 END;
                              END IF;

                              BEGIN
                                 BEGIN
                                    INSERT INTO sfrstcr
                                         VALUES (c.periodo, --SFRSTCR_TERM_CODE
                                                 c.pidm,        --SFRSTCR_PIDM
                                                 crn,            --SFRSTCR_CRN
                                                 1,   --SFRSTCR_CLASS_SORT_KEY
                                                 c.grupo,    --SFRSTCR_REG_SEQ
                                                 c.parte,  --SFRSTCR_PTRM_CODE
                                                 'RE',     --SFRSTCR_RSTS_CODE
                                                 SYSDATE - 5, --SFRSTCR_RSTS_DATE
                                                 NULL,    --SFRSTCR_ERROR_FLAG
                                                 NULL,       --SFRSTCR_MESSAGE
                                                 credit_bill, --SFRSTCR_BILL_HR
                                                 3,          --SFRSTCR_WAIV_HR
                                                 credit,   --SFRSTCR_CREDIT_HR
                                                 credit_bill, --SFRSTCR_BILL_HR_HOLD
                                                 credit, --SFRSTCR_CREDIT_HR_HOLD
                                                 gmod,     --SFRSTCR_GMOD_CODE
                                                 NULL,     --SFRSTCR_GRDE_CODE
                                                 NULL, --SFRSTCR_GRDE_CODE_MID
                                                 NULL,     --SFRSTCR_GRDE_DATE
                                                 'N',      --SFRSTCR_DUPL_OVER
                                                 'N',      --SFRSTCR_LINK_OVER
                                                 'N',      --SFRSTCR_CORQ_OVER
                                                 'N',      --SFRSTCR_PREQ_OVER
                                                 'N',      --SFRSTCR_TIME_OVER
                                                 'N',      --SFRSTCR_CAPC_OVER
                                                 'N',      --SFRSTCR_LEVL_OVER
                                                 'N',      --SFRSTCR_COLL_OVER
                                                 'N',      --SFRSTCR_MAJR_OVER
                                                 'N',      --SFRSTCR_CLAS_OVER
                                                 'N',      --SFRSTCR_APPR_OVER
                                                 'N', --SFRSTCR_APPR_RECEIVED_IND
                                                 SYSDATE - 5, --SFRSTCR_ADD_DATE
                                                 SYSDATE - 5, --SFRSTCR_ACTIVITY_DATE
                                                 c.nivel,  --SFRSTCR_LEVL_CODE
                                                 c.campus, --SFRSTCR_CAMP_CODE
                                                 c.materia, --SFRSTCR_RESERVED_KEY
                                                 NULL,     --SFRSTCR_ATTEND_HR
                                                 'Y',      --SFRSTCR_REPT_OVER
                                                 'N',      --SFRSTCR_RPTH_OVER
                                                 NULL,     --SFRSTCR_TEST_OVER
                                                 'N',      --SFRSTCR_CAMP_OVER
                                                 USER,          --SFRSTCR_USER
                                                 'N',      --SFRSTCR_DEGC_OVER
                                                 'N',      --SFRSTCR_PROG_OVER
                                                 NULL,   --SFRSTCR_LAST_ATTEND
                                                 NULL,     --SFRSTCR_GCMT_CODE
                                                 'PRONOSTICO', --SFRSTCR_DATA_ORIGIN
                                                 SYSDATE, --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                 'N',      --SFRSTCR_DEPT_OVER
                                                 'N',      --SFRSTCR_ATTS_OVER
                                                 'N',      --SFRSTCR_CHRT_OVER
                                                 c.grupo,   --SFRSTCR_RMSG_CDE
                                                 NULL,   --SFRSTCR_WL_PRIORITY
                                                 NULL, --SFRSTCR_WL_PRIORITY_ORIG
                                                 NULL, --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                 NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                 'N',      --SFRSTCR_MEXC_OVER
                                                 c.study, --SFRSTCR_STSP_KEY_SEQUENCE
                                                 NULL,  --SFRSTCR_BRDH_SEQ_NUM
                                                 '01',     --SFRSTCR_BLCK_CODE
                                                 NULL,    --SFRSTCR_STRH_SEQNO
                                                 NULL,    --SFRSTCR_STRD_SEQNO
                                                 NULL,  --SFRSTCR_SURROGATE_ID
                                                 NULL,       --SFRSTCR_VERSION
                                                 USER,       --SFRSTCR_USER_ID
                                                 vl_orden  --SFRSTCR_VPDI_CODE
                                                         );
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       DBMS_OUTPUT.put_line (
                                             'Error al insertar SFRSTCR 2 '
                                          || SQLERRM);
                                 END;


                                 BEGIN
                                    UPDATE SZTPRONO
                                       SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                     WHERE     1 = 1
                                           AND SZTPRONO_NO_REGLA = p_regla
                                           AND SZTPRONO_FECHA_INICIO =
                                                  pn_fecha
                                           AND SZTPRONO_PIDM = c.pidm
                                           AND sztprono_materia_legal =
                                                  c.materia
                                           AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                           AND SZTPRONO_PTRM_CODE = parte;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;


                                 BEGIN
                                    UPDATE ssbsect
                                       SET ssbsect_enrl = ssbsect_enrl + 1
                                     WHERE     1 = 1
                                           AND ssbsect_term_code = c.periodo
                                           AND SSBSECT_CRN = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el enrolamiento '
                                          || SQLERRM;
                                 END;

                                 BEGIN
                                    UPDATE ssbsect
                                       SET ssbsect_seats_avail =
                                              ssbsect_seats_avail - 1
                                     WHERE     1 = 1
                                           AND ssbsect_term_code = c.periodo
                                           AND ssbsect_crn = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar la disponibilidad del grupo '
                                          || SQLERRM;
                                 END;

                                 BEGIN
                                    UPDATE ssbsect
                                       SET ssbsect_census_enrl = ssbsect_enrl
                                     WHERE     SSBSECT_TERM_CODE = c.periodo
                                           AND SSBSECT_CRN = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el Censo del grupo '
                                          || SQLERRM;
                                 END;

                                 IF C.SGBSTDN_STYP_CODE = 'F'
                                 THEN
                                    BEGIN
                                       UPDATE sgbstdn a
                                          SET a.sgbstdn_styp_code = 'N',
                                              a.SGBSTDN_DATA_ORIGIN =
                                                 'PRONOSTICO',
                                              A.SGBSTDN_USER_ID = USER
                                        WHERE     1 = 1
                                              AND a.sgbstdn_pidm = c.pidm
                                              AND a.sgbstdn_term_code_eff =
                                                     (SELECT MAX (
                                                                a1.sgbstdn_term_code_eff)
                                                        FROM sgbstdn a1
                                                       WHERE     a1.sgbstdn_pidm =
                                                                    a.sgbstdn_pidm
                                                             AND a1.sgbstdn_program_1 =
                                                                    a.sgbstdn_program_1)
                                              AND a.sgbstdn_program_1 =
                                                     c.prog;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                             || SQLERRM;
                                    END;
                                 END IF;

                                 BEGIN
                                    SELECT COUNT (*)
                                      INTO l_cambio_estatus
                                      FROM sfrstcr
                                     WHERE     1 = 1
                                           AND    SFRSTCR_TERM_CODE
                                               || SFRSTCR_PTRM_CODE =
                                                  c.periodo || c.parte
                                           AND sfrstcr_pidm = c.pidm
                                           AND SFRSTCR_STSP_KEY_SEQUENCE =
                                                  c.study;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       l_cambio_estatus := 0;
                                 END;


                                 IF l_cambio_estatus > 0
                                 THEN
                                    IF C.SGBSTDN_STYP_CODE IN ('N', 'R')
                                    THEN
                                       BEGIN
                                          UPDATE sgbstdn a
                                             SET a.sgbstdn_styp_code = 'C',
                                                 a.SGBSTDN_DATA_ORIGIN =
                                                    'PRONOSTICO',
                                                 A.SGBSTDN_USER_ID = USER
                                           WHERE     1 = 1
                                                 AND a.sgbstdn_pidm = c.pidm
                                                 AND a.sgbstdn_term_code_eff =
                                                        (SELECT MAX (
                                                                   a1.sgbstdn_term_code_eff)
                                                           FROM sgbstdn a1
                                                          WHERE     a1.sgbstdn_pidm =
                                                                       a.sgbstdn_pidm
                                                                AND a1.sgbstdn_program_1 =
                                                                       a.sgbstdn_program_1)
                                                 AND a.sgbstdn_program_1 =
                                                        c.prog;
                                       EXCEPTION
                                          WHEN OTHERS
                                          THEN
                                             vl_error :=
                                                   'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                                || SQLERRM;
                                       END;
                                    END IF;
                                 END IF;

                                 f_inicio := NULL;

                                 BEGIN
                                    SELECT DISTINCT sobptrm_start_date
                                      INTO f_inicio
                                      FROM sobptrm
                                     WHERE     sobptrm_term_code = c.periodo
                                           AND sobptrm_ptrm_code = c.parte;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       f_inicio := NULL;
                                       vl_error :=
                                             'Se presento un error al Obtener la fecha de inicio de Clases periodo '
                                          || c.periodo
                                          || ' parte '
                                          || c.parte
                                          || ' '
                                          || SQLERRM
                                          || ' poe';
                                 END;

                                 IF f_inicio IS NOT NULL
                                 THEN
                                    BEGIN
                                       UPDATE sorlcur
                                          SET sorlcur_start_date =
                                                 TRUNC (f_inicio),
                                              SORLCUR_RATE_CODE = c.rate
                                        WHERE     SORLCUR_PIDM = c.pidm
                                              AND SORLCUR_PROGRAM = c.prog
                                              AND SORLCUR_LMOD_CODE =
                                                     'LEARNER'
                                              AND SORLCUR_KEY_SEQNO = c.study;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur '
                                             || SQLERRM;
                                    END;
                                 END IF;

                                 conta_ptrm := 0;

                                 BEGIN
                                    SELECT COUNT (*)
                                      INTO conta_ptrm
                                      FROM sfrareg
                                     WHERE     1 = 1
                                           AND sfrareg_pidm = c.pidm
                                           AND sfrareg_term_code = c.periodo
                                           AND sfrareg_crn = crn
                                           AND sfrareg_extension_number = 0
                                           AND sfrareg_rsts_code = 'RE';
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       conta_ptrm := 0;
                                 END;

                                 IF conta_ptrm = 0
                                 THEN
                                    BEGIN
                                       INSERT INTO sfrareg
                                            VALUES (c.pidm,
                                                    c.periodo,
                                                    crn,
                                                    0,
                                                    'RE',
                                                    NVL (f_inicio, pn_fecha),
                                                    NVL (f_fin, SYSDATE),
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
                                                    NULL);
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al insertar el registro de la materia para el alumno '
                                             || SQLERRM;
                                    END;
                                 END IF;

                                 BEGIN
                                    UPDATE SZTPRONO
                                       SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                     WHERE     1 = 1
                                           AND SZTPRONO_NO_REGLA = p_regla
                                           AND SZTPRONO_FECHA_INICIO =
                                                  pn_fecha
                                           AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                           AND sztprono_materia_legal =
                                                  c.materia
                                           AND SZTPRONO_PIDM = c.pidm
                                           AND SZTPRONO_PTRM_CODE = parte;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar al alumno en el grupo2 '
                                       || SQLERRM;
                              END;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un Error al insertar el nuevo grupo en la tabla SSBSECT '
                                    || SQLERRM;
                           END;
                        END IF;
                     END IF;                -------- > No hay cupo en el grupo
                  ELSE
                     DBMS_OUTPUT.put_line (
                        'mensaje:' || 'No hay grupo creado Con docente este');

                     schd := NULL;
                     title := NULL;
                     credit := NULL;
                     gmod := NULL;
                     f_inicio := NULL;
                     f_fin := NULL;
                     sem := NULL;
                     crn := NULL;
                     pidm_prof := NULL;
                     vl_exite_prof := 0;

                     BEGIN
                        SELECT scrschd_schd_code,
                               scbcrse_title,
                               scbcrse_credit_hr_low,
                               scbcrse_bill_hr_low
                          INTO schd,
                               title,
                               credit,
                               credit_bill
                          FROM scbcrse, scrschd
                         WHERE     1 = 1
                               AND scbcrse_subj_code = c.subj
                               AND scbcrse_crse_numb = c.crse
                               AND scbcrse_eff_term = '000000'
                               AND scrschd_subj_code = scbcrse_subj_code
                               AND scrschd_crse_numb = scbcrse_crse_numb
                               AND scrschd_eff_term = scbcrse_eff_term;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           schd := NULL;
                           title := NULL;
                           credit := NULL;
                           credit_bill := NULL;
                     END;

                     BEGIN
                        SELECT scrgmod_gmod_code
                          INTO gmod
                          FROM scrgmod
                         WHERE     1 = 1
                               AND scrgmod_subj_code = c.subj
                               AND scrgmod_crse_numb = c.crse
                               AND scrgmod_default_ind = 'D';
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           gmod := '1';
                     END;

                     IF c.nivel = 'MS'
                     THEN
                        l_campus_ms := 'AS';
                     ELSE
                        l_campus_ms := c.niVel;
                     END IF;

                     BEGIN
                        SELECT sztcrnv_crn
                          INTO crn
                          FROM SZTCRNV
                         WHERE     1 = 1
                               AND ROWNUM = 1
                               AND SZTCRNV_LVEL_CODE =
                                      SUBSTR (l_campus_ms, 1, 1)
                               AND (SZTCRNV_crn, SZTCRNV_LVEL_CODE) NOT IN (SELECT TO_NUMBER (
                                                                                      crn),
                                                                                   SUBSTR (
                                                                                      SSBSECT_CRN,
                                                                                      1,
                                                                                      1)
                                                                              FROM (SELECT CASE
                                                                                              WHEN SUBSTR (
                                                                                                      SSBSECT_CRN,
                                                                                                      1,
                                                                                                      1) IN ('L',
                                                                                                             'M',
                                                                                                             'A',
                                                                                                             'D',
                                                                                                             'B',
                                                                                                             'E')
                                                                                              THEN
                                                                                                 TO_NUMBER (
                                                                                                    SUBSTR (
                                                                                                       SSBSECT_CRN,
                                                                                                       2,
                                                                                                       10))
                                                                                              ELSE
                                                                                                 TO_NUMBER (
                                                                                                    SSBSECT_CRN)
                                                                                           END
                                                                                              crn,
                                                                                           SSBSECT_CRN
                                                                                      FROM ssbsect
                                                                                     WHERE     1 =
                                                                                                  1
                                                                                           AND ssbsect_term_code =
                                                                                                  c.periodo-- AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                   )
                                                                             WHERE 1 =
                                                                                      1);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           -- raise_application_error (-20002,'Error al 2 '|| SQLCODE||' Error: '||SQLERRM);
                           -- dbms_output.put_line(' error en crn 2 '||sqlerrm);
                           crn := NULL;
                     END;

                     IF crn IS NOT NULL
                     THEN
                        IF c.nivel = 'LI'
                        THEN
                           crn := 'L' || crn;
                        ELSE
                           crn := 'M' || crn;
                        END IF;
                     ELSE
                        BEGIN
                           SELECT NVL (MAX (TO_NUMBER (SSBSECT_CRN)), 0) + 1
                             INTO crn
                             FROM ssbsect
                            WHERE     1 = 1
                                  AND ssbsect_term_code = c.periodo
                                  AND SUBSTR (ssbsect_crn, 1, 1) NOT IN ('L',
                                                                         'M',
                                                                         'A',
                                                                         'D',
                                                                         'B');
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              DBMS_OUTPUT.put_line (
                                 'sqlerrm ' || crn || ' ' || SQLERRM);
                              crn := NULL;
                        END;

                        DBMS_OUTPUT.put_line ('crn ' || crn);
                     END IF;

                     BEGIN
                        SELECT DISTINCT
                               sobptrm_start_date,
                               sobptrm_end_date,
                               sobptrm_weeks
                          INTO f_inicio, f_fin, sem
                          FROM sobptrm
                         WHERE     1 = 1
                               AND sobptrm_term_code = c.periodo
                               AND sobptrm_ptrm_code = c.parte;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'No se Encontro configuracion para el Periodo= '
                              || c.periodo
                              || ' y Parte de Periodo= '
                              || c.parte
                              || SQLERRM;
                     END;


                     IF crn IS NOT NULL
                     THEN
                        -- le movemos extraemos el numero de alumonos de la tabla de profesores

                        BEGIN
                           l_maximo_alumnos := 90;
                        END;

                        BEGIN
                           INSERT INTO ssbsect
                                VALUES (c.periodo,         --SSBSECT_TERM_CODE
                                        crn,                     --SSBSECT_CRN
                                        c.parte,           --SSBSECT_PTRM_CODE
                                        c.subj,            --SSBSECT_SUBJ_CODE
                                        c.crse,            --SSBSECT_CRSE_NUMB
                                        c.grupo,            --SSBSECT_SEQ_NUMB
                                        'A',               --SSBSECT_SSTS_CODE
                                        'ENL',             --SSBSECT_SCHD_CODE
                                        c.campus,          --SSBSECT_CAMP_CODE
                                        title,            --SSBSECT_CRSE_TITLE
                                        credit,           --SSBSECT_CREDIT_HRS
                                        credit_bill,        --SSBSECT_BILL_HRS
                                        gmod,              --SSBSECT_GMOD_CODE
                                        NULL,              --SSBSECT_SAPR_CODE
                                        NULL,              --SSBSECT_SESS_CODE
                                        NULL,             --SSBSECT_LINK_IDENT
                                        NULL,               --SSBSECT_PRNT_IND
                                        'Y',            --SSBSECT_GRADABLE_IND
                                        NULL,               --SSBSECT_TUIW_IND
                                        0,                 --SSBSECT_REG_ONEUP
                                        0,                --SSBSECT_PRIOR_ENRL
                                        0,                 --SSBSECT_PROJ_ENRL
                                        l_maximo_alumnos,   --SSBSECT_MAX_ENRL
                                        0,                      --SSBSECT_ENRL
                                        l_maximo_alumnos, --SSBSECT_SEATS_AVAIL
                                        NULL,         --SSBSECT_TOT_CREDIT_HRS
                                        '0',             --SSBSECT_CENSUS_ENRL
                                        NVL (f_inicio, SYSDATE), --SSBSECT_CENSUS_ENRL_DATE
                                        SYSDATE,       --SSBSECT_ACTIVITY_DATE
                                        NVL (f_inicio, SYSDATE), --SSBSECT_PTRM_START_DATE
                                        NVL (f_FIN, SYSDATE), --SSBSECT_PTRM_END_DATE
                                        sem,              --SSBSECT_PTRM_WEEKS
                                        NULL,           --SSBSECT_RESERVED_IND
                                        NULL,          --SSBSECT_WAIT_CAPACITY
                                        NULL,             --SSBSECT_WAIT_COUNT
                                        NULL,             --SSBSECT_WAIT_AVAIL
                                        NULL,                 --SSBSECT_LEC_HR
                                        NULL,                 --SSBSECT_LAB_HR
                                        NULL,                 --SSBSECT_OTH_HR
                                        NULL,                --SSBSECT_CONT_HR
                                        NULL,              --SSBSECT_ACCT_CODE
                                        NULL,              --SSBSECT_ACCL_CODE
                                        NULL,          --SSBSECT_CENSUS_2_DATE
                                        NULL,      --SSBSECT_ENRL_CUT_OFF_DATE
                                        NULL,      --SSBSECT_ACAD_CUT_OFF_DATE
                                        NULL,      --SSBSECT_DROP_CUT_OFF_DATE
                                        NULL,            --SSBSECT_CENSUS_ENRL
                                        'Y',             --SSBSECT_VOICE_AVAIL
                                        'N',    --SSBSECT_CAPP_PREREQ_TEST_IND
                                        NULL,              --SSBSECT_GSCH_NAME
                                        NULL,           --SSBSECT_BEST_OF_COMP
                                        NULL,         --SSBSECT_SUBSET_OF_COMP
                                        'NOP',             --SSBSECT_INSM_CODE
                                        NULL,          --SSBSECT_REG_FROM_DATE
                                        NULL,            --SSBSECT_REG_TO_DATE
                                        NULL, --SSBSECT_LEARNER_REGSTART_FDATE
                                        NULL, --SSBSECT_LEARNER_REGSTART_TDATE
                                        NULL,              --SSBSECT_DUNT_CODE
                                        NULL,        --SSBSECT_NUMBER_OF_UNITS
                                        0,      --SSBSECT_NUMBER_OF_EXTENSIONS
                                        'PRONOSTICO',    --SSBSECT_DATA_ORIGIN
                                        USER,                --SSBSECT_USER_ID
                                        'MOOD',             --SSBSECT_INTG_CDE
                                        'B',   --SSBSECT_PREREQ_CHK_METHOD_CDE
                                        USER,       --SSBSECT_KEYWORD_INDEX_ID
                                        NULL,        --SSBSECT_SCORE_OPEN_DATE
                                        NULL,      --SSBSECT_SCORE_CUTOFF_DATE
                                        NULL,   --SSBSECT_REAS_SCORE_OPEN_DATE
                                        NULL,   --SSBSECT_REAS_SCORE_CTOF_DATE
                                        NULL,           --SSBSECT_SURROGATE_ID
                                        NULL,                --SSBSECT_VERSION
                                        NULL               --SSBSECT_VPDI_CODE
                                            );


                           BEGIN
                              UPDATE SOBTERM
                                 SET sobterm_crn_oneup = crn
                               WHERE 1 = 1 AND sobterm_term_code = c.periodo;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;

                           BEGIN
                              INSERT INTO ssrmeet
                                   VALUES (C.periodo,
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
                                           NULL);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un Error al insertar en ssrmeet '
                                    || SQLERRM;
                           END;

                           BEGIN
                              SELECT spriden_pidm
                                INTO pidm_prof
                                FROM spriden
                               WHERE     1 = 1
                                     AND spriden_id = c.prof
                                     AND spriden_change_ind IS NULL;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 pidm_prof := NULL;
                           END;

                           IF pidm_prof IS NOT NULL
                           THEN
                              DBMS_OUTPUT.put_line (
                                    'Crea el CRN para el docente:'
                                 || pidm_prof
                                 || '*'
                                 || crn);

                              BEGIN
                                 SELECT COUNT (1)
                                   INTO vl_exite_prof
                                   FROM sirasgn
                                  WHERE     1 = 1
                                        AND sirasgn_term_code = c.periodo
                                        AND sirasgn_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_exite_prof := 0;
                              END;

                              IF vl_exite_prof = 0
                              THEN
                                 BEGIN
                                    INSERT INTO sirasgn
                                         VALUES (c.periodo,
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;
                              ELSE
                                 BEGIN
                                    UPDATE sirasgn
                                       SET sirasgn_primary_ind = NULL
                                     WHERE     1 = 1
                                           AND sirasgn_term_code = c.periodo
                                           AND sirasgn_crn = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;

                                 BEGIN
                                    INSERT INTO sirasgn
                                         VALUES (c.periodo,
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;
                              END IF;
                           END IF;

                           conta_ptrm := 0;

                           BEGIN
                              SELECT COUNT (*)
                                INTO conta_ptrm
                                FROM sfbetrm
                               WHERE     1 = 1
                                     AND sfbetrm_term_code = c.periodo
                                     AND sfbetrm_pidm = c.pidm;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 conta_ptrm := 0;
                           END;


                           IF conta_ptrm = 0
                           THEN
                              BEGIN
                                 INSERT INTO sfbetrm
                                      VALUES (c.periodo,
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
                                              NULL);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                       (   'Se presento un error al insertar en la tabla sfbetrm '
                                        || SQLERRM);
                              END;
                           END IF;

                           BEGIN
                              BEGIN
                                 INSERT INTO sfrstcr
                                      VALUES (c.periodo,   --SFRSTCR_TERM_CODE
                                              c.pidm,           --SFRSTCR_PIDM
                                              crn,               --SFRSTCR_CRN
                                              1,      --SFRSTCR_CLASS_SORT_KEY
                                              c.grupo,       --SFRSTCR_REG_SEQ
                                              c.parte,     --SFRSTCR_PTRM_CODE
                                              'RE',        --SFRSTCR_RSTS_CODE
                                              SYSDATE - 5, --SFRSTCR_RSTS_DATE
                                              NULL,       --SFRSTCR_ERROR_FLAG
                                              NULL,          --SFRSTCR_MESSAGE
                                              credit_bill,   --SFRSTCR_BILL_HR
                                              3,             --SFRSTCR_WAIV_HR
                                              credit,      --SFRSTCR_CREDIT_HR
                                              credit_bill, --SFRSTCR_BILL_HR_HOLD
                                              credit, --SFRSTCR_CREDIT_HR_HOLD
                                              gmod,        --SFRSTCR_GMOD_CODE
                                              NULL,        --SFRSTCR_GRDE_CODE
                                              NULL,    --SFRSTCR_GRDE_CODE_MID
                                              NULL,        --SFRSTCR_GRDE_DATE
                                              'N',         --SFRSTCR_DUPL_OVER
                                              'N',         --SFRSTCR_LINK_OVER
                                              'N',         --SFRSTCR_CORQ_OVER
                                              'N',         --SFRSTCR_PREQ_OVER
                                              'N',         --SFRSTCR_TIME_OVER
                                              'N',         --SFRSTCR_CAPC_OVER
                                              'N',         --SFRSTCR_LEVL_OVER
                                              'N',         --SFRSTCR_COLL_OVER
                                              'N',         --SFRSTCR_MAJR_OVER
                                              'N',         --SFRSTCR_CLAS_OVER
                                              'N',         --SFRSTCR_APPR_OVER
                                              'N', --SFRSTCR_APPR_RECEIVED_IND
                                              SYSDATE - 5,  --SFRSTCR_ADD_DATE
                                              SYSDATE - 5, --SFRSTCR_ACTIVITY_DATE
                                              c.nivel,     --SFRSTCR_LEVL_CODE
                                              c.campus,    --SFRSTCR_CAMP_CODE
                                              c.materia, --SFRSTCR_RESERVED_KEY
                                              NULL,        --SFRSTCR_ATTEND_HR
                                              'Y',         --SFRSTCR_REPT_OVER
                                              'N',         --SFRSTCR_RPTH_OVER
                                              NULL,        --SFRSTCR_TEST_OVER
                                              'N',         --SFRSTCR_CAMP_OVER
                                              USER,             --SFRSTCR_USER
                                              'N',         --SFRSTCR_DEGC_OVER
                                              'N',         --SFRSTCR_PROG_OVER
                                              NULL,      --SFRSTCR_LAST_ATTEND
                                              NULL,        --SFRSTCR_GCMT_CODE
                                              'PRONOSTICO', --SFRSTCR_DATA_ORIGIN
                                              SYSDATE, --SFRSTCR_ASSESS_ACTIVITY_DATE
                                              'N',         --SFRSTCR_DEPT_OVER
                                              'N',         --SFRSTCR_ATTS_OVER
                                              'N',         --SFRSTCR_CHRT_OVER
                                              c.grupo,      --SFRSTCR_RMSG_CDE
                                              NULL,      --SFRSTCR_WL_PRIORITY
                                              NULL, --SFRSTCR_WL_PRIORITY_ORIG
                                              NULL, --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                              NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                              'N',         --SFRSTCR_MEXC_OVER
                                              c.study, --SFRSTCR_STSP_KEY_SEQUENCE
                                              NULL,     --SFRSTCR_BRDH_SEQ_NUM
                                              '01',        --SFRSTCR_BLCK_CODE
                                              NULL,       --SFRSTCR_STRH_SEQNO
                                              NULL,       --SFRSTCR_STRD_SEQNO
                                              NULL,     --SFRSTCR_SURROGATE_ID
                                              NULL,          --SFRSTCR_VERSION
                                              USER,          --SFRSTCR_USER_ID
                                              vl_orden     --SFRSTCR_VPDI_CODE
                                                      );
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    DBMS_OUTPUT.put_line (
                                          'Error al insertar SFRSTCR xxx '
                                       || SQLERRM);
                              END;


                              BEGIN
                                 UPDATE SZTPRONO
                                    SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                  WHERE     1 = 1
                                        AND SZTPRONO_NO_REGLA = p_regla
                                        AND SZTPRONO_FECHA_INICIO = pn_fecha
                                        AND SZTPRONO_PIDM = c.pidm
                                        AND sztprono_materia_legal =
                                               c.materia
                                        AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                        AND SZTPRONO_PTRM_CODE = parte;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;


                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_enrl = ssbsect_enrl + 1
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND SSBSECT_CRN = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar el enrolamiento '
                                       || SQLERRM;
                              END;

                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_seats_avail =
                                           ssbsect_seats_avail - 1
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar la disponibilidad del grupo '
                                       || SQLERRM;
                              END;

                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_census_enrl = ssbsect_enrl
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar el Censo del grupo '
                                       || SQLERRM;
                              END;

                              IF C.SGBSTDN_STYP_CODE = 'F'
                              THEN
                                 BEGIN
                                    UPDATE sgbstdn a
                                       SET a.sgbstdn_styp_code = 'N',
                                           a.SGBSTDN_DATA_ORIGIN =
                                              'PRONOSTICO',
                                           A.SGBSTDN_USER_ID = USER
                                     WHERE     1 = 1
                                           AND a.sgbstdn_pidm = c.pidm
                                           AND a.sgbstdn_term_code_eff =
                                                  (SELECT MAX (
                                                             a1.sgbstdn_term_code_eff)
                                                     FROM sgbstdn a1
                                                    WHERE     a1.sgbstdn_pidm =
                                                                 a.sgbstdn_pidm
                                                          AND a1.sgbstdn_program_1 =
                                                                 a.sgbstdn_program_1)
                                           AND a.sgbstdn_program_1 = c.prog;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                          || SQLERRM;
                                 END;
                              END IF;

                              BEGIN
                                 SELECT COUNT (*)
                                   INTO l_cambio_estatus
                                   FROM sfrstcr
                                  WHERE     1 = 1
                                        AND    SFRSTCR_TERM_CODE
                                            || SFRSTCR_PTRM_CODE =
                                               c.periodo || c.parte
                                        AND sfrstcr_pidm = c.pidm
                                        AND SFRSTCR_STSP_KEY_SEQUENCE =
                                               c.study;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    l_cambio_estatus := 0;
                              END;


                              IF l_cambio_estatus > 0
                              THEN
                                 IF C.SGBSTDN_STYP_CODE IN ('N', 'R')
                                 THEN
                                    BEGIN
                                       UPDATE sgbstdn a
                                          SET a.sgbstdn_styp_code = 'C',
                                              a.SGBSTDN_DATA_ORIGIN =
                                                 'PRONOSTICO',
                                              A.SGBSTDN_USER_ID = USER
                                        WHERE     1 = 1
                                              AND a.sgbstdn_pidm = c.pidm
                                              AND a.sgbstdn_term_code_eff =
                                                     (SELECT MAX (
                                                                a1.sgbstdn_term_code_eff)
                                                        FROM sgbstdn a1
                                                       WHERE     a1.sgbstdn_pidm =
                                                                    a.sgbstdn_pidm
                                                             AND a1.sgbstdn_program_1 =
                                                                    a.sgbstdn_program_1)
                                              AND a.sgbstdn_program_1 =
                                                     c.prog;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                             || SQLERRM;
                                    END;
                                 END IF;
                              END IF;

                              f_inicio := NULL;

                              BEGIN
                                 SELECT DISTINCT sobptrm_start_date
                                   INTO f_inicio
                                   FROM sobptrm
                                  WHERE     sobptrm_term_code = c.periodo
                                        AND sobptrm_ptrm_code = c.parte;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    f_inicio := NULL;
                                    vl_error :=
                                          'Se presento un error al Obtener la fecha de inicio de Clases periodo '
                                       || c.periodo
                                       || ' parte '
                                       || c.parte
                                       || ' '
                                       || SQLERRM
                                       || ' poe';
                              -- raise_application_error (-20002,vl_error);

                              END;

                              IF f_inicio IS NOT NULL
                              THEN
                                 BEGIN
                                    UPDATE sorlcur
                                       SET sorlcur_start_date =
                                              TRUNC (f_inicio),
                                           sorlcur_data_origin = 'PRONOSTICO',
                                           sorlcur_user_id = USER,
                                           SORLCUR_RATE_CODE = c.rate
                                     WHERE     1 = 1
                                           AND sorlcur_pidm = c.pidm
                                           AND sorlcur_program = c.prog
                                           AND sorlcur_lmod_code = 'LEARNER'
                                           AND sorlcur_key_seqno = c.study;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur '
                                          || SQLERRM;
                                 END;
                              END IF;

                              conta_ptrm := 0;

                              BEGIN
                                 SELECT COUNT (*)
                                   INTO conta_ptrm
                                   FROM sfrareg
                                  WHERE     1 = 1
                                        AND sfrareg_pidm = c.pidm
                                        AND sfrareg_term_code = c.periodo
                                        AND sfrareg_crn = crn
                                        AND sfrareg_extension_number = 0
                                        AND sfrareg_rsts_code = 'RE';
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    conta_ptrm := 0;
                              END;

                              IF conta_ptrm = 0
                              THEN
                                 BEGIN
                                    INSERT INTO sfrareg
                                         VALUES (c.pidm,
                                                 c.periodo,
                                                 crn,
                                                 0,
                                                 'RE',
                                                 NVL (f_inicio, pn_fecha),
                                                 NVL (f_fin, SYSDATE),
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al insertar el registro de la materia para el alumno '
                                          || SQLERRM;
                                 END;
                              END IF;

                              BEGIN
                                 UPDATE SZTPRONO
                                    SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                  WHERE     1 = 1
                                        AND SZTPRONO_NO_REGLA = p_regla
                                        AND SZTPRONO_FECHA_INICIO = pn_fecha
                                        AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                        AND sztprono_materia_legal =
                                               c.materia
                                        AND SZTPRONO_PIDM = c.pidm
                                        AND SZTPRONO_PTRM_CODE = parte;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al insertar al alumno en el grupo3 '
                                    || SQLERRM;
                           END;

                           DBMS_OUTPUT.put_line (
                              'mensaje1:' || 'SE creo el grupo :=' || crn);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              vl_error :=
                                    'Se presento un Error al insertar el nuevo grupo 3 crn '
                                 || crn
                                 || ' error '
                                 || SQLERRM;
                        END;
                     END IF;
                  END IF;                             ------ No hay CRN Creado

                  IF vl_error = 'EXITO'
                  THEN
                     COMMIT;                                         --Commit;

                     --dbms_output.put_line('mensaje:'||vl_error);
                     BEGIN
                        INSERT INTO sztcarga
                             VALUES (c.iden,                      --SZCARGA_ID
                                     c.materia,              --SZCARGA_MATERIA
                                     c.prog,                 --SZCARGA_PROGRAM
                                     c.periodo,            --SZCARGA_TERM_CODE
                                     c.parte,              --SZCARGA_PTRM_CODE
                                     c.grupo,                  --SZCARGA_GRUPO
                                     NULL,                     --SZCARGA_CALIF
                                     c.prof,                 --SZCARGA_ID_PROF
                                     USER,                   --SZCARGA_USER_ID
                                     SYSDATE,          --SZCARGA_ACTIVITY_DATE
                                     c.fecha_inicio,       --SZCARGA_FECHA_INI
                                     'P',                    --SZCARGA_ESTATUS
                                     'Horario Generado', --SZCARGA_OBSERVACIONES
                                     'PRONOSTICO',
                                     p_regla);
                     EXCEPTION
                        WHEN DUP_VAL_ON_INDEX
                        THEN
                           BEGIN
                              UPDATE sztcarga
                                 SET szcarga_estatus = 'P',
                                     szcarga_observaciones =
                                        'Horario Generado',
                                     szcarga_activity_date = SYSDATE
                               WHERE     1 = 1
                                     AND SZCARGA_ID = c.iden
                                     AND SZCARGA_MATERIA = c.materia
                                     AND SZTCARGA_TIPO_PROC = 'MATE'
                                     AND TRUNC (SZCARGA_FECHA_INI) =
                                            c.fecha_inicio;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 VL_ERROR :=
                                       'Se presento un Error al Actualizar la bitacora '
                                    || SQLERRM;
                           END;
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'Se presento un Error al insertar la bitacora '
                              || SQLERRM;
                     END;
                  ELSE
                     DBMS_OUTPUT.put_line ('mensaje:' || vl_error);

                     ROLLBACK;

                     BEGIN
                        INSERT INTO sztcarga
                             VALUES (c.iden,                      --SZCARGA_ID
                                     c.materia,              --SZCARGA_MATERIA
                                     c.prog,                 --SZCARGA_PROGRAM
                                     c.periodo,            --SZCARGA_TERM_CODE
                                     c.parte,              --SZCARGA_PTRM_CODE
                                     c.grupo,                  --SZCARGA_GRUPO
                                     NULL,                     --SZCARGA_CALIF
                                     c.prof,                 --SZCARGA_ID_PROF
                                     USER,                   --SZCARGA_USER_ID
                                     SYSDATE,          --SZCARGA_ACTIVITY_DATE
                                     c.fecha_inicio,       --SZCARGA_FECHA_INI
                                     'E',                    --SZCARGA_ESTATUS
                                     vl_error,         --SZCARGA_OBSERVACIONES
                                     'PRONOSTICO',
                                     p_regla);

                        COMMIT;
                     EXCEPTION
                        WHEN DUP_VAL_ON_INDEX
                        THEN
                           BEGIN
                              UPDATE sztcarga
                                 SET szcarga_estatus = 'E',
                                     szcarga_observaciones = vl_error,
                                     szcarga_activity_date = SYSDATE
                               WHERE     1 = 1
                                     AND szcarga_id = c.iden
                                     AND szcarga_materia = c.materia
                                     AND sztcarga_tipo_proc = 'MATE'
                                     AND TRUNC (szcarga_fecha_ini) =
                                            c.fecha_inicio;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un Error al Actualizar la bitacora de Error '
                                    || SQLERRM;
                           END;
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'Se presento un Error al insertar la bitacora de Error '
                              || SQLERRM;
                     END;
                  END IF;
               ELSE
                  vl_error :=
                        'El alumno ya tiene la materia Inscritas en el Periodo:'
                     || period_cur
                     || '. Parte-periodo:'
                     || parteper_cur;

                  DBMS_OUTPUT.put_line (
                        'El alumno ya tiene la materia Inscritas en el Periodo:'
                     || period_cur
                     || '. Parte-periodo:'
                     || parteper_cur);

                  BEGIN
                     UPDATE sztprono
                        SET SZTPRONO_ESTATUS_ERROR = 'S',
                            SZTPRONO_DESCRIPCION_ERROR = vl_error
                      --SZTPRONO_ENVIO_HORARIOS ='S'

                      WHERE     1 = 1
                            AND SZTPRONO_MATERIA_LEGAL = c.materia
                            -- AND TRUNC (SZTPRONO_FECHA_INICIO) = c.fecha_inicio
                            AND SZTPRONO_NO_REGLA = P_REGLA
                            AND SZTPRONO_pIDm = c.pidm;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        DBMS_OUTPUT.put_line (
                           ' Error al actualizar ' || SQLERRM);
                  END;

                  COMMIT;

                  -- raise_application_error (-20002,vl_error);

                  BEGIN
                     INSERT INTO sztcarga
                          VALUES (c.iden,                         --SZCARGA_ID
                                  c.materia,                 --SZCARGA_MATERIA
                                  c.prog,                    --SZCARGA_PROGRAM
                                  c.periodo,               --SZCARGA_TERM_CODE
                                  c.parte,                 --SZCARGA_PTRM_CODE
                                  c.grupo,                     --SZCARGA_GRUPO
                                  NULL,                        --SZCARGA_CALIF
                                  c.prof,                    --SZCARGA_ID_PROF
                                  USER,                      --SZCARGA_USER_ID
                                  SYSDATE,             --SZCARGA_ACTIVITY_DATE
                                  c.fecha_inicio,          --SZCARGA_FECHA_INI
                                  'A',                --'P', --SZCARGA_ESTATUS
                                  vl_error,            --SZCARGA_OBSERVACIONES
                                  'PRONOSTICO',
                                  p_regla);

                     COMMIT;
                  EXCEPTION
                     WHEN DUP_VAL_ON_INDEX
                     THEN
                        BEGIN
                           UPDATE sztcarga
                              SET szcarga_estatus = 'A',               --'P' ,
                                  szcarga_observaciones = vl_error,
                                  szcarga_activity_date = SYSDATE
                            WHERE     1 = 1
                                  AND szcarga_id = c.iden
                                  AND szcarga_materia = c.materia
                                  AND sztcarga_tipo_proc = 'MATE'
                                  AND TRUNC (szcarga_fecha_ini) =
                                         c.fecha_inicio;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              vl_error :=
                                    'Se presento un Error al Actualizar la bitacora de Error '
                                 || SQLERRM;
                        END;
                     WHEN OTHERS
                     THEN
                        vl_error :=
                              'Se presento un Error al insertar la bitacora de Error '
                           || SQLERRM;
                  END;
               END IF;            ----> El alumno ya tiene inscrita la materia
            ELSE
               BEGIN
                  SELECT DECODE (c.sgbstdn_stst_code,
                                 'BT', 'BAJA TEMPORAL',
                                 'BD', 'BAJA TEMPORAL',
                                 'BI', 'BAJA POR INACTIVIDAD',
                                 'CV', 'CANCELACI? DE VENTA',
                                 'CM', 'CANCELACI? DE MATR?ULA',
                                 'CC', 'CAMBIO DE CILO',
                                 'CF', 'CAMBIO DE FECHA',
                                 'CP', 'CAMBIO DE PROGRAMA',
                                 'EG', 'EGRESADO')
                    INTO L_DESCRIPCION_ERROR
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_descripcion_error := 'Sin descripcion';
               END;

               IF L_DESCRIPCION_ERROR IS NULL
               THEN
                  L_DESCRIPCION_ERROR := c.sgbstdn_stst_code;
               END IF;


               BEGIN
                  UPDATE sztprono
                     SET SZTPRONO_ESTATUS_ERROR = 'S',
                         SZTPRONO_DESCRIPCION_ERROR = L_DESCRIPCION_ERROR
                   WHERE     1 = 1
                         AND SZTPRONO_MATERIA_LEGAL = c.materia
                         AND TRUNC (SZTPRONO_FECHA_INICIO) = c.fecha_inicio
                         AND SZTPRONO_NO_REGLA = P_REGLA
                         AND SZTPRONO_PIDM = c.pidm
                         AND SZTPRONO_PTRM_CODE = parte;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     DBMS_OUTPUT.put_line (
                        ' Error al actualizar ' || SQLERRM);
               END;


               vl_error :=
                     'Estatus no v?do para realizar la carga: '
                  || C.SGBSTDN_STST_CODE;

               BEGIN
                  INSERT INTO sztcarga
                       VALUES (c.iden,                            --SZCARGA_ID
                               c.materia,                    --SZCARGA_MATERIA
                               c.prog,                       --SZCARGA_PROGRAM
                               c.periodo,                  --SZCARGA_TERM_CODE
                               c.parte,                    --SZCARGA_PTRM_CODE
                               c.grupo,                        --SZCARGA_GRUPO
                               NULL,                           --SZCARGA_CALIF
                               c.prof,                       --SZCARGA_ID_PROF
                               USER,                         --SZCARGA_USER_ID
                               SYSDATE,                --SZCARGA_ACTIVITY_DATE
                               c.fecha_inicio,             --SZCARGA_FECHA_INI
                               'A',                   --'P', --SZCARGA_ESTATUS
                               vl_error,               --SZCARGA_OBSERVACIONES
                               'PRONOSTICO',
                               p_regla);

                  COMMIT;
               EXCEPTION
                  WHEN DUP_VAL_ON_INDEX
                  THEN
                     BEGIN
                        UPDATE sztcarga
                           SET szcarga_estatus = 'A',                  --'P' ,
                               szcarga_observaciones = vl_error,
                               szcarga_activity_date = SYSDATE
                         WHERE     1 = 1
                               AND szcarga_id = c.iden
                               AND szcarga_materia = c.materia
                               AND sztcarga_tipo_proc = 'MATE'
                               AND TRUNC (szcarga_fecha_ini) = c.fecha_inicio;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'Se presento un Error al Actualizar la bitacora de Error '
                              || SQLERRM;
                     END;
                  WHEN OTHERS
                  THEN
                     vl_error :=
                           'Se presento un Error al insertar la bitacora de Error '
                        || SQLERRM;
               END;
            -- raise_application_error (-20002,'Este alumno '||c.iden||' se encuentra con '||l_descripcion_error);

            END IF;
         --end if;

         END LOOP;

         COMMIT;

         FOR X IN c_no_proce
         LOOP
            vl_error := 'Materia no Registrada para el Alumno en SFAREGS';

            BEGIN
               INSERT INTO sztcarga
                    VALUES (x.szcarga_id,                         --szcaRGA_ID
                            x.szcarga_materia,               --SZCARGA_MATERIA
                            x.szcarga_program,               --SZCARGA_PROGRAM
                            x.szcarga_term_code,           --SZCARGA_TERM_CODE
                            x.szcarga_ptrm_code,           --SZCARGA_PTRM_CODE
                            x.szcarga_grupo,                   --SZCARGA_GRUPO
                            x.szcarga_calif,                   --SZCARGA_CALIF
                            x.szcarga_id_prof,               --SZCARGA_ID_PROF
                            USER,                            --SZCARGA_USER_ID
                            SYSDATE,                   --SZCARGA_ACTIVITY_DATE
                            x.szcarga_fecha_ini,           --SZCARGA_FECHA_INI
                            'E',                             --SZCARGA_ESTATUS
                            vl_error,                  --SZCARGA_OBSERVACIONES
                            'PRONOSTICO ' || p_regla,
                            p_regla);

               COMMIT;
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX
               THEN
                  BEGIN
                     UPDATE sztcarga
                        SET szcarga_estatus = 'E',
                            szcarga_calif = x.szcarga_calif,
                            szcarga_observaciones = vl_error,
                            szcarga_activity_date = SYSDATE
                      WHERE     1 = 1
                            AND szcarga_id = x.szcarga_id
                            AND szcarga_materia = x.szcarga_materia
                            AND sztcarga_tipo_proc = 'MATE'
                            AND TRUNC (szcarga_fecha_ini) =
                                   x.szcarga_fecha_ini;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        vl_error :=
                              'Se presento un Error al Actualizar la bitacora de Error '
                           || SQLERRM;
                  END;
               WHEN OTHERS
               THEN
                  vl_error :=
                        'Se presento un Error al insertar la bitacora de Error '
                     || SQLERRM;
            END;


            BEGIN
               UPDATE SZTPRONO
                  SET SZTPRONO_ESTATUS_ERROR = 'S',
                      SZTPRONO_DESCRIPCION_ERROR =
                            'Esta materia no va acorde a la seriacion de SMAPROG con el programa '
                         || x.szcarga_program
                WHERE     1 = 1
                      AND sztprono_no_regla = p_regla
                      AND sztprono_materia_legal = x.szcarga_materia
                      AND sztprono_id = x.szcarga_id
                      AND SZTPRONO_FECHA_INICIO = x.szcarga_fecha_ini;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END LOOP;

         COMMIT;

         --raise_application_error (-20002,vl_error);
         ------------------- Realiza el proceso de actualizacion de Jornadas ----------------------------------

         BEGIN
            FOR c
               IN (  SELECT sorlcur_levl_code nivel,
                            szcarga_id,
                            szcarga_term_code,
                            szcarga_ptrm_code,
                            spriden_pidm,
                            sorlcur_key_seqno,
                            COUNT (*) numero
                       FROM sztcarga, spriden, sorlcur s
                      WHERE     1 = 1
                            AND sztcarga_tipo_proc = 'MATE'
                            AND szcarga_estatus != 'E'
                            AND szcarga_id = spriden_id
                            AND s.sorlcur_pidm = spriden_pidm
                            AND s.sorlcur_program = szcarga_program
                            AND s.sorlcur_lmod_code = 'LEARNER'
                            AND s.sorlcur_seqno IN (SELECT MAX (
                                                              ss.sorlcur_seqno)
                                                      FROM sorlcur ss
                                                     WHERE     1 = 1
                                                           AND s.sorlcur_pidm =
                                                                  ss.sorlcur_pidm
                                                           AND s.sorlcur_lmod_code =
                                                                  ss.sorlcur_lmod_code
                                                           AND s.sorlcur_program =
                                                                  ss.sorlcur_program)
                   GROUP BY sorlcur_levl_code,
                            szcarga_id,
                            szcarga_term_code,
                            szcarga_ptrm_code,
                            spriden_pidm,
                            sorlcur_key_seqno
                   ORDER BY 1, 2, 3)
            LOOP
               vl_jornada := NULL;



               BEGIN
                  SELECT DISTINCT SUBSTR (sgrsatt_atts_code, 1, 3) jornada
                    INTO vl_jornada
                    FROM sgrsatt a
                   WHERE     1 = 1
                         AND a.sgrsatt_pidm = c.spriden_pidm
                         AND a.sgrsatt_stsp_key_sequence =
                                c.sorlcur_key_seqno
                         AND SUBSTR (a.sgrsatt_atts_code, 2, 1) =
                                SUBSTR (c.nivel, 1, 1)
                         AND REGEXP_LIKE (a.sgrsatt_atts_code, '^[0-9]')
                         AND a.sgrsatt_term_code_eff =
                                (SELECT MAX (a1.sgrsatt_term_code_eff)
                                   FROM SGRSATT a1
                                  WHERE     1 = 1
                                        AND a.sgrsatt_pidm = a1.sgrsatt_pidm
                                        AND a.sgrsatt_stsp_key_sequence =
                                               a1.sgrsatt_stsp_key_sequence);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vl_jornada := NULL;
               END;

               IF vl_jornada IS NOT NULL
               THEN
                  IF c.numero >= 10
                  THEN
                     c.numero := 4;
                  END IF;

                  vl_jornada := vl_jornada || c.numero;

                  BEGIN
                     pkg_algoritmo.p_actualiza_jornada (c.spriden_pidm,
                                                        c.szcarga_term_code,
                                                        vl_jornada,
                                                        c.sorlcur_key_seqno);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  END;
               END IF;
            END LOOP;

            COMMIT;
         END;
      END IF;


      COMMIT;

      pkg_algoritmo.P_ENA_DIS_TRG ('E', 'SATURN.SZT_SSBSECT_POSTINSERT_ROW');
      pkg_algoritmo.P_ENA_DIS_TRG ('E', 'SATURN.SZT_SIRASGN_POSTINSERT_ROW');
      pkg_algoritmo.P_ENA_DIS_TRG ('E',
                                   'SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');
   END;


   PROCEDURE p_inscr_individual_DD (pn_fecha              VARCHAR2,
                                    p_regla               NUMBER,
                                    p_materia_legal       VARCHAR2,
                                    p_pidm                NUMBER,
                                    p_estatus             VARCHAR2,
                                    p_secuencia           NUMBER,
                                    p_error           OUT VARCHAR2)
   IS
      crn                    VARCHAR2 (20);
      gpo                    NUMBER;
      mate                   VARCHAR2 (20);
      ciclo                  VARCHAR2 (6);
      subj                   VARCHAR2 (4);
      crse                   VARCHAR2 (5);
      sb                     VARCHAR2 (4);
      cr                     VARCHAR2 (5);
      schd                   VARCHAR2 (3);
      title                  VARCHAR2 (30);
      credit                 DECIMAL (7, 3);
      credit_bill            DECIMAL (7, 3);
      gmod                   VARCHAR2 (1);
      f_inicio               DATE;
      f_fin                  DATE;
      sem                    NUMBER;
      conta_ptrm             NUMBER;
      conta_blck             NUMBER;
      pidm                   NUMBER;
      pidm_doc               NUMBER;
      pidm_doc2              NUMBER;
      ests                   VARCHAR2 (2);
      levl                   VARCHAR2 (2);
      camp                   VARCHAR2 (3);
      rsts                   VARCHAR2 (3);
      conta_origen           NUMBER := 0;
      conta_destino          NUMBER := 0;
      conta_origen_ssbsect   NUMBER := 0;
      conta_origen_ssrblck   NUMBER := 0;
      conta_origen_sobptrm   NUMBER := 0;
      sp                     INTEGER;
      ciclo_ext              VARCHAR2 (6);
      mensaje                VARCHAR2 (200);
      parte                  VARCHAR2 (3);
      pidm_prof              NUMBER;
      per                    VARCHAR2 (6);
      grupo                  VARCHAR2 (4);
      conta_sirasgn          NUMBER;
      fecha_ini              DATE;
      vl_existe              NUMBER := 0;
      vn_lugares             NUMBER := 0;
      vn_cupo_max            NUMBER := 0;
      vn_cupo_act            NUMBER := 0;
      vl_error               VARCHAR2 (2500) := 'EXITO';
      parteper_cur           VARCHAR2 (3);
      period_cur             VARCHAR2 (10);
      vl_jornada             VARCHAR2 (250) := NULL;
      vl_exite_prof          NUMBER := 0;
      l_contar               NUMBER := 0;
      l_maximo_alumnos       NUMBER;
      l_numero_contador      NUMBER := 0;                         --Jpg@Modify
      l_valida_order         NUMBER;
      L_DESCRIPCION_ERROR    VARCHAR2 (250) := NULL;
      l_valida               NUMBER;
      l_cuneta_prono         NUMBER;
      l_term_code            VARCHAR2 (10);
      l_ptrm                 VARCHAR2 (10);
      vl_orden               VARCHAR2 (10);
      l_cuenta_ni            NUMBER;
      l_cambio_estatus       NUMBER;
      l_type                 VARCHAR2 (20);
      l_pperiodo_ni          VARCHAR2 (20);
      l_matricula            VARCHAR2 (9) := NULL;
      l_campus_ms            VARCHAR2 (20);
      l_retorna_dsi          VARCHAR2 (250);

      --
      --Jpg@Create@Dic@21
      --Procedimiento que revisa configuracion de area sea correcta
      PROCEDURE p_check_area (p_regla            NUMBER,
                              p_pidm             NUMBER,
                              p_materia_legal    VARCHAR2)
      IS
      BEGIN
         FOR c
            IN (SELECT DISTINCT sorlcur_program,
                                sorlcur_term_code_ctlg term,
                                smrpaap_term_code_eff term_eff,
                                smrarul_area,
                                szcarga_id iden,
                                szcarga_fecha_ini fecha_inicio,
                                szcarga_materia materia
                  FROM szcarga a
                       JOIN spriden
                          ON     spriden_id = szcarga_id
                             AND spriden_change_ind IS NULL
                       JOIN sgbstdn d
                          ON     d.sgbstdn_pidm = spriden_pidm
                             AND d.sgbstdn_term_code_eff =
                                    (SELECT MAX (b1.sgbstdn_term_code_eff)
                                       FROM sgbstdn b1
                                      WHERE     1 = 1
                                            AND d.sgbstdn_pidm =
                                                   b1.sgbstdn_pidm
                                            AND d.sgbstdn_program_1 =
                                                   b1.sgbstdn_program_1)
                       JOIN sorlcur s
                          ON     sorlcur_pidm = spriden_pidm
                             AND s.sorlcur_pidm = d.sgbstdn_pidm
                             AND s.sorlcur_program = d.sgbstdn_program_1
                             AND sorlcur_program = szcarga_program
                             AND sorlcur_lmod_code = 'LEARNER'
                             AND sorlcur_seqno IN (SELECT MAX (sorlcur_seqno)
                                                     FROM sorlcur ss
                                                    WHERE     1 = 1
                                                          AND s.sorlcur_pidm =
                                                                 ss.sorlcur_pidm
                                                          AND s.sorlcur_lmod_code =
                                                                 ss.sorlcur_lmod_code
                                                          AND s.sorlcur_program =
                                                                 ss.sorlcur_program)
                       JOIN sztdtec
                          ON     sztdtec_program = sorlcur_program
                             AND sztdtec_term_code = sorlcur_term_code_ctlg
                       JOIN smrpaap ON smrpaap_program = sorlcur_program --AND smrpaap_term_code_eff=sorlcur_term_code_ctlg
                       JOIN sztmaco ON SZTMACO_MATPADRE = szcarga_materia
                       JOIN smrarul
                          ON     smrarul_area = smrpaap_area
                             AND smrarul_subj_code || smrarul_crse_numb_low =
                                    sztmaco_mathijo
                 WHERE     1 = 1
                       AND smrarul_subj_code || smrarul_crse_numb_low =
                              sztmaco_mathijo
                       AND szcarga_no_regla = p_regla
                       AND sorlcur_pidm = p_pidm
                       AND SZCARGA_MATERIA = p_materia_legal)
         LOOP
            IF c.term <> c.term_eff
            THEN
               DBMS_OUTPUT.put_line ('Entra a p_check_area');

               BEGIN
                  UPDATE sztprono
                     SET SZTPRONO_ESTATUS_ERROR = 'S',
                         SZTPRONO_descripcion_error =
                               'Error de configuracion en area de concentracion de la materia:'
                            || p_materia_legal,
                         sztprono_activity_date = SYSDATE,
                         sztprono_usuario = USER
                   WHERE     1 = 1
                         AND sztprono_id = c.iden
                         AND sztprono_materia_legal = c.materia
                         AND sztprono_no_regla = p_regla
                         AND sztprono_fecha_inicio = c.fecha_inicio;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;

               COMMIT;
            END IF;
         END LOOP;
      END;
   --Jpg@Create@Dic@21

   BEGIN
      -- raise_application_error (-20002,'pasa la carga');

      BEGIN
         SELECT DISTINCT spriden_id
           INTO l_matricula
           FROM spriden
          WHERE spriden_pidm = p_pidm AND spriden_change_ind IS NULL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;



      BEGIN
         P_INSERTA_CARGA_PIDM (p_regla, pn_fecha, p_pidm);
      EXCEPTION
         WHEN OTHERS
         THEN
            -- raise_application_error (-20002,'ERROR al insertar en carga '||sqlerrm);
            NULL;
      END;

      DBMS_OUTPUT.PUT_LINE ('pasa la carga ');

      BEGIN
         SELECT COUNT (*)
           INTO l_contar
           FROM SZCARGA
          WHERE     1 = 1
                AND SZCARGA_ID = l_matricula
                AND SZCARGA_NO_REGLA = p_regla;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      IF l_contar > 0
      THEN
         fecha_ini := TO_DATE (pn_fecha, 'DD/MM/RRRR');

         DBMS_OUTPUT.PUT_LINE ('antes cursor ' || p_materia_legal);

         FOR c
            IN (  -- SELECT DISTINCT spriden_pidm pidm,
                  -- szcarga_id iden ,
                  -- szcarga_program prog,
                  -- sorlcur_camp_code campus,
                  -- sorlcur_levl_code nivel,
                  -- sorlcur_term_code_ctlg ctlg ,
                  -- szcarga_materia materia ,
                  -- smrarul_subj_code subj,
                  -- smrarul_crse_numb_low crse ,
                  -- szcarga_term_code periodo ,
                  -- szcarga_ptrm_code parte,
                  -- DECODE(sztdtec_periodicidad,1,'BIMESTRAL',2,'CUATRIMESTRAL') periodicidad,
                  -- nvl(szcarga_grupo,'01') grupo,
                  -- --szcarga_grupo grupo,
                  -- szcarga_calif calif,
                  -- szcarga_id_prof prof,
                  -- szcarga_fecha_ini fecha_inicio,
                  -- sorlcur_key_seqno study,
                  -- d.sgbstdn_stst_code,
                  -- d.sgbstdn_styp_code,
                  -- SGBSTDN_RATE_CODE rate,
                  -- s.sorlcur_program,
                  -- d.sgbstdn_program_1
                  -- FROM szcarga a
                  -- JOIN spriden ON spriden_id=szcarga_id AND spriden_change_ind IS NULL
                  -- JOIN sgbstdn d ON d.sgbstdn_pidm=spriden_pidm
                  -- AND d.sgbstdn_term_code_eff = (SELECT MAX (b1.sgbstdn_term_code_eff)
                  -- FROM sgbstdn b1
                  -- WHERE 1 = 1
                  -- AND d.sgbstdn_pidm = b1.sgbstdn_pidm
                  -- AND d.sgbstdn_program_1 = b1.sgbstdn_program_1
                  -- )
                  -- JOIN sorlcur s ON sorlcur_pidm=spriden_pidm
                  -- AND s.sorlcur_pidm = d.sgbstdn_pidm
                  -- --AND s.sorlcur_program = d.sgbstdn_program_1
                  -- AND sorlcur_program=szcarga_program
                  -- JOIN sztdtec ON sztdtec_program=sorlcur_program AND sztdtec_term_code=sorlcur_term_code_ctlg
                  -- JOIN smrpaap ON smrpaap_program=sorlcur_program AND smrpaap_term_code_eff=sorlcur_term_code_ctlg
                  -- JOIN sztmaco ON SZTMACO_MATPADRE=szcarga_materia
                  -- JOIN smrarul ON smrarul_area=smrpaap_area and smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
                  -- WHERE 1 = 1
                  -- AND szcarga_no_regla = p_regla
                  -- AND sorlcur_pidm = p_pidm
                  -- and SZCARGA_MATERIA = p_materia_legal
                  -- ORDER BY iden, 10
                  SELECT DISTINCT
                         spriden_pidm pidm,
                         szcarga_id iden,
                         szcarga_program prog,
                         sorlcur_camp_code campus,
                         sorlcur_levl_code nivel,
                         sorlcur_term_code_ctlg ctlg,
                         szcarga_materia materia,
                         smrarul_subj_code subj,
                         smrarul_crse_numb_low crse,
                         szcarga_term_code periodo,
                         szcarga_ptrm_code parte,
                         DECODE (sztdtec_periodicidad,
                                 1, 'BIMESTRAL',
                                 2, 'CUATRIMESTRAL')
                            periodicidad,
                         NVL (szcarga_grupo, '01') grupo,
                         --szcarga_grupo grupo,
                         szcarga_calif calif,
                         szcarga_id_prof prof,
                         szcarga_fecha_ini fecha_inicio,
                         sorlcur_key_seqno study,
                         d.sgbstdn_stst_code,
                         d.sgbstdn_styp_code,
                         SGBSTDN_RATE_CODE rate
                    FROM szcarga a
                         JOIN spriden
                            ON     spriden_id = szcarga_id
                               AND spriden_change_ind IS NULL
                         JOIN sgbstdn d
                            ON     d.sgbstdn_pidm = spriden_pidm
                               AND d.sgbstdn_term_code_eff =
                                      (SELECT MAX (b1.sgbstdn_term_code_eff)
                                         FROM sgbstdn b1
                                        WHERE     1 = 1
                                              AND d.sgbstdn_pidm =
                                                     b1.sgbstdn_pidm
                                              AND d.sgbstdn_program_1 =
                                                     b1.sgbstdn_program_1)
                         JOIN sorlcur s
                            ON     sorlcur_pidm = spriden_pidm
                               AND s.sorlcur_pidm = d.sgbstdn_pidm
                               AND s.sorlcur_program = d.sgbstdn_program_1
                               AND sorlcur_program = szcarga_program
                               AND sorlcur_lmod_code = 'LEARNER'
                               AND sorlcur_seqno IN (SELECT MAX (sorlcur_seqno)
                                                       FROM sorlcur ss
                                                      WHERE     1 = 1
                                                            AND s.sorlcur_pidm =
                                                                   ss.sorlcur_pidm
                                                            AND s.sorlcur_lmod_code =
                                                                   ss.sorlcur_lmod_code
                                                            AND s.sorlcur_program =
                                                                   ss.sorlcur_program)
                         JOIN sztdtec
                            ON     sztdtec_program = sorlcur_program
                               AND sztdtec_term_code = sorlcur_term_code_ctlg
                         JOIN smrpaap
                            ON     smrpaap_program = sorlcur_program
                               AND smrpaap_term_code_eff =
                                      sorlcur_term_code_ctlg
                         JOIN sztmaco ON SZTMACO_MATPADRE = szcarga_materia
                         JOIN smrarul
                            ON     smrarul_area = smrpaap_area
                               AND smrarul_subj_code || smrarul_crse_numb_low =
                                      sztmaco_mathijo
                   WHERE     1 = 1
                         AND smrarul_subj_code || smrarul_crse_numb_low =
                                sztmaco_mathijo
                         AND szcarga_no_regla = p_regla
                         AND sorlcur_pidm = p_pidm
                         AND SZCARGA_MATERIA = p_materia_legal
                ORDER BY iden, 10)
         LOOP
            DBMS_OUTPUT.PUT_LINE ('Entra a cursor normal ');

            --------------- Limpia Variables --------------------
            --niv := null;
            parte := NULL;
            crn := NULL;
            pidm_doc2 := NULL;
            conta_sirasgn := NULL;
            pidm_doc := NULL;
            f_inicio := NULL;
            f_fin := NULL;
            sem := NULL;
            schd := NULL;
            title := NULL;
            credit := NULL;
            credit_bill := NULL;
            levl := NULL;
            camp := NULL;
            mate := NULL;
            parte := NULL;
            per := NULL;
            -- grupo := NULL;
            vl_existe := 0;
            vl_error := 'EXITO';
            vn_lugares := 0;
            vn_cupo_max := 0;
            vn_cupo_act := 0;

            parteper_cur := NULL;
            period_cur := NULL;
            vl_exite_prof := 0;

            BEGIN
               SELECT DISTINCT TO_NUMBER (SFRSTCR_VPDI_CODE)
                 INTO VL_ORDEN
                 FROM SFRSTCR
                WHERE     SFRSTCR_PIDM = C.PIDM
                      AND SFRSTCR_TERM_CODE = C.PERIODO
                      AND SFRSTCR_PTRM_CODE = C.PARTE
                      AND SFRSTCR_RSTS_CODE = 'RE'
                      AND SFRSTCR_VPDI_CODE IS NOT NULL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  DBMS_OUTPUT.put_line ('No se encontro 3 ' || SQLERRM);

                  BEGIN
                     SELECT TBRACCD_RECEIPT_NUMBER
                       INTO VL_ORDEN
                       FROM TBRACCD A
                      WHERE     A.TBRACCD_PIDM = C.PIDM
                            AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                            FROM TBBDETC
                                                           WHERE     TBBDETC_DCAT_CODE =
                                                                        'COL'
                                                                 AND TBBDETC_DESC LIKE
                                                                        'COLEGIATURA %'
                                                                 AND TBBDETC_DESC !=
                                                                        'COLEGIATURA LIC NOTA'
                                                                 AND TBBDETC_DESC !=
                                                                        'COLEGIATURA EXTRAORDINARIO')
                            AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                            AND A.TBRACCD_TRAN_NUMBER =
                                   (SELECT MAX (TBRACCD_TRAN_NUMBER)
                                      FROM TBRACCD A1
                                     WHERE     A1.TBRACCD_PIDM =
                                                  A.TBRACCD_PIDM
                                           AND A1.TBRACCD_TERM_CODE =
                                                  A.TBRACCD_TERM_CODE
                                           AND A1.TBRACCD_PERIOD =
                                                  A.TBRACCD_PERIOD
                                           AND A1.TBRACCD_DETAIL_CODE =
                                                  A.TBRACCD_DETAIL_CODE
                                           AND LAST_DAY (
                                                  TBRACCD_EFFECTIVE_DATE) =
                                                  LAST_DAY (
                                                       TO_DATE (
                                                          C.fecha_inicio)
                                                     + 12)
                                           AND A1.TBRACCD_DOCUMENT_NUMBER
                                                  IS NULL
                                           AND A1.TBRACCD_STSP_KEY_SEQUENCE =
                                                  c.study);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        DBMS_OUTPUT.put_line ('No se encontro 4 ' || SQLERRM);

                        VL_ORDEN := NULL;
                  END;
            END;

            DBMS_OUTPUT.put_line ('Orden ' || VL_ORDEN);


            IF c.sgbstdn_stst_code IN ('AS', 'PR', 'MA')
            THEN
               ----------------- Se valida que el alumno no tenga la materia sembrada en el horario como Activa ---------------------------------------

               DBMS_OUTPUT.PUT_LINE ('Entra a cursor normal ');

               BEGIN
                    --existe y es aprobatoria
                    SELECT COUNT (1), sfrstcr_term_code, sfrstcr_ptrm_code
                      INTO vl_existe, period_cur, parteper_cur
                      FROM ssbsect, sfrstcr, shrgrde
                     WHERE     1 = 1
                           AND sfrstcr_pidm = c.pidm
                           AND ssbsect_term_code = sfrstcr_term_code
                           AND sfrstcr_ptrm_code = ssbsect_ptrm_code
                           AND ssbsect_crn = sfrstcr_crn
                           AND ssbsect_subj_code = c.subj
                           AND ssbsect_crse_numb = c.crse
                           AND sfrstcr_rsts_code = 'RE'
                           AND (   sfrstcr_grde_code = shrgrde_code
                                OR sfrstcr_grde_code IS NULL)
                           AND SUBSTR (sfrstcr_term_code, 5, 1) NOT IN ('8',
                                                                        '9')
                           AND shrgrde_passed_ind = 'Y'
                           AND shrgrde_levl_code = c.nivel
                           /* cambio escalas para prod */
                           AND shrgrde_term_code_effective =
                                  (SELECT zstpara_param_desc
                                     FROM zstpara
                                    WHERE     zstpara_mapa_id = 'ESC_SHAGRD'
                                          AND SUBSTR (
                                                 (SELECT f_getspridenid (
                                                            p_pidm)
                                                    FROM DUAL),
                                                 1,
                                                 2) = zstpara_param_id
                                          AND zstpara_param_valor = c.nivel)
                  /* cambio escalas para prod */
                  GROUP BY sfrstcr_term_code, sfrstcr_ptrm_code;

                  DBMS_OUTPUT.PUT_LINE (
                        'Entrando aqui '
                     || vl_existe
                     || ' PIDM '
                     || c.pidm
                     || ' SUBJ '
                     || c.subj
                     || ' crse '
                     || c.crse);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vl_existe := 0;
                     DBMS_OUTPUT.PUT_LINE ('Error ' || SQLERRM);
               END;

               IF vl_existe IS NULL
               THEN
                  vl_existe := 0;
               END IF;

               DBMS_OUTPUT.PUT_LINE ('Entra a existe ' || vl_existe);

               IF vl_existe = 0
               THEN
                  ---- Se busca que exista el grupo y tenga cupo

                  DBMS_OUTPUT.put_line (
                        'sin profesor '
                     || vl_existe
                     || ' Periodo '
                     || c.periodo
                     || ' Subj '
                     || c.subj
                     || ' crse '
                     || c.crse
                     || ' grupo '
                     || c.grupo
                     || ' ptrm '
                     || c.parte);

                  BEGIN
                     SELECT ct.ssbsect_crn,
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
                       INTO crn,
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
                            AND ct.ssbsect_term_code = c.periodo
                            AND ct.ssbsect_subj_code = c.subj
                            AND ct.ssbsect_crse_numb = c.crse
                            AND ct.ssbsect_seq_numb = c.grupo
                            AND ct.ssbsect_ptrm_code = c.parte
                            AND TRUNC (ct.ssbsect_ptrm_start_date) =
                                   c.Fecha_Inicio
                            AND SSBSECT_CAMP_CODE = c.campus
                            AND ct.ssbsect_seats_avail > 0
                            AND ct.ssbsect_seats_avail IN (SELECT MAX (
                                                                     a1.ssbsect_seats_avail)
                                                             FROM ssbsect a1
                                                            WHERE     a1.ssbsect_term_code =
                                                                         ct.ssbsect_term_code
                                                                  AND a1.ssbsect_seq_numb =
                                                                         ct.ssbsect_seq_numb
                                                                  AND a1.ssbsect_subj_code =
                                                                         ct.ssbsect_subj_code
                                                                  AND a1.ssbsect_crse_numb =
                                                                         ct.ssbsect_crse_numb
                                                                  AND TRUNC (
                                                                         a1.ssbsect_ptrm_start_date) =
                                                                         TRUNC (
                                                                            ct.ssbsect_ptrm_start_date));
                  -- DBMS_OUTPUT.PUT_LINE('Entra 4');

                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        crn := NULL;
                        vn_lugares := 0;
                        vn_cupo_max := 0;
                        vn_cupo_act := 0;
                        f_inicio := NULL;
                        f_fin := NULL;
                        sem := NULL;
                        credit := NULL;
                        credit_bill := NULL;
                        gmod := NULL;
                  END;



                  IF crn IS NOT NULL
                  THEN
                     DBMS_OUTPUT.put_line ('CRN no es null lx ' || crn);

                     IF vn_cupo_act > 0
                     THEN
                        IF credit IS NULL
                        THEN
                           BEGIN
                              SELECT ssrmeet_credit_hr_sess
                                INTO credit
                                FROM ssrmeet
                               WHERE     1 = 1
                                     AND ssrmeet_term_code = c.periodo
                                     AND ssrmeet_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 credit := NULL;
                           END;

                           IF credit IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_credit_hrs = credit
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;
                           END IF;
                        END IF;

                        IF credit_bill IS NULL
                        THEN
                           credit_bill := 1;

                           IF credit IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_bill_hrs = credit_bill
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;
                           END IF;
                        END IF;

                        IF gmod IS NULL
                        THEN
                           BEGIN
                              SELECT scrgmod_gmod_code
                                INTO gmod
                                FROM scrgmod
                               WHERE     1 = 1
                                     AND scrgmod_subj_code = c.subj
                                     AND scrgmod_crse_numb = c.crse
                                     AND scrgmod_default_ind = 'D';
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 gmod := '1';
                           END;

                           IF gmod IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_gmod_code = gmod
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;
                           END IF;
                        END IF;

                        BEGIN
                           SELECT spriden_pidm
                             INTO pidm_prof
                             FROM spriden
                            WHERE     1 = 1
                                  AND spriden_id = c.prof
                                  AND spriden_change_ind IS NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              pidm_prof := NULL;
                        END;

                        conta_ptrm := 0;

                        BEGIN
                           SELECT COUNT (1)
                             INTO conta_ptrm
                             FROM sirasgn
                            WHERE     SIRASGN_TERM_CODE = c.periodo
                                  AND SIRASGN_CRN = crn
                                  AND SIRASGN_PIDM = pidm_prof
                                  AND SIRASGN_PRIMARY_IND = 'Y';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              conta_ptrm := 0;
                        END;

                        IF pidm_prof IS NOT NULL AND conta_ptrm = 0
                        THEN
                           BEGIN
                              INSERT INTO sirasgn
                                   VALUES (c.periodo,
                                           crn,
                                           pidm_prof,
                                           '01',
                                           100,
                                           NULL,
                                           100,
                                           'Y',
                                           NULL,
                                           NULL,
                                           SYSDATE - 5,
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
                                           NULL);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        END IF;

                        conta_ptrm := 0;

                        BEGIN
                           SELECT COUNT (*)
                             INTO conta_ptrm
                             FROM sfbetrm
                            WHERE     1 = 1
                                  AND sfbetrm_term_code = c.periodo
                                  AND sfbetrm_pidm = c.pidm;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              conta_ptrm := 0;
                        END;


                        IF conta_ptrm = 0
                        THEN
                           BEGIN
                              INSERT INTO sfbetrm
                                   VALUES (c.periodo,
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
                                           NULL);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                    (   'Se presento un error al insertar en la tabla sfbetrm '
                                     || SQLERRM);
                           END;
                        END IF;

                        BEGIN
                           BEGIN
                              INSERT INTO sfrstcr
                                   VALUES (c.periodo,      --SFRSTCR_TERM_CODE
                                           c.pidm,              --SFRSTCR_PIDM
                                           crn,                  --SFRSTCR_CRN
                                           1,         --SFRSTCR_CLASS_SORT_KEY
                                           c.grupo,          --SFRSTCR_REG_SEQ
                                           parte,          --SFRSTCR_PTRM_CODE
                                           p_estatus,      --SFRSTCR_RSTS_CODE
                                           SYSDATE - 5,    --SFRSTCR_RSTS_DATE
                                           NULL,          --SFRSTCR_ERROR_FLAG
                                           NULL,             --SFRSTCR_MESSAGE
                                           credit_bill,      --SFRSTCR_BILL_HR
                                           3,                --SFRSTCR_WAIV_HR
                                           credit,         --SFRSTCR_CREDIT_HR
                                           credit_bill, --SFRSTCR_BILL_HR_HOLD
                                           credit,    --SFRSTCR_CREDIT_HR_HOLD
                                           gmod,           --SFRSTCR_GMOD_CODE
                                           NULL,           --SFRSTCR_GRDE_CODE
                                           NULL,       --SFRSTCR_GRDE_CODE_MID
                                           NULL,           --SFRSTCR_GRDE_DATE
                                           'N',            --SFRSTCR_DUPL_OVER
                                           'N',            --SFRSTCR_LINK_OVER
                                           'N',            --SFRSTCR_CORQ_OVER
                                           'N',            --SFRSTCR_PREQ_OVER
                                           'N',            --SFRSTCR_TIME_OVER
                                           'N',            --SFRSTCR_CAPC_OVER
                                           'N',            --SFRSTCR_LEVL_OVER
                                           'N',            --SFRSTCR_COLL_OVER
                                           'N',            --SFRSTCR_MAJR_OVER
                                           'N',            --SFRSTCR_CLAS_OVER
                                           'N',            --SFRSTCR_APPR_OVER
                                           'N',    --SFRSTCR_APPR_RECEIVED_IND
                                           SYSDATE - 5,     --SFRSTCR_ADD_DATE
                                           SYSDATE - 5, --SFRSTCR_ACTIVITY_DATE
                                           c.nivel,        --SFRSTCR_LEVL_CODE
                                           c.campus,       --SFRSTCR_CAMP_CODE
                                           c.materia,   --SFRSTCR_RESERVED_KEY
                                           NULL,           --SFRSTCR_ATTEND_HR
                                           'Y',            --SFRSTCR_REPT_OVER
                                           'N',            --SFRSTCR_RPTH_OVER
                                           NULL,           --SFRSTCR_TEST_OVER
                                           'N',            --SFRSTCR_CAMP_OVER
                                           USER,                --SFRSTCR_USER
                                           'N',            --SFRSTCR_DEGC_OVER
                                           'N',            --SFRSTCR_PROG_OVER
                                           NULL,         --SFRSTCR_LAST_ATTEND
                                           NULL,           --SFRSTCR_GCMT_CODE
                                           'PRONOSTICO', --SFRSTCR_DATA_ORIGIN
                                           SYSDATE, --SFRSTCR_ASSESS_ACTIVITY_DATE
                                           'N',            --SFRSTCR_DEPT_OVER
                                           'N',            --SFRSTCR_ATTS_OVER
                                           'N',            --SFRSTCR_CHRT_OVER
                                           c.grupo,         --SFRSTCR_RMSG_CDE
                                           NULL,         --SFRSTCR_WL_PRIORITY
                                           NULL,    --SFRSTCR_WL_PRIORITY_ORIG
                                           NULL, --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                           NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                           'N',            --SFRSTCR_MEXC_OVER
                                           c.study, --SFRSTCR_STSP_KEY_SEQUENCE
                                           NULL,        --SFRSTCR_BRDH_SEQ_NUM
                                           '01',           --SFRSTCR_BLCK_CODE
                                           NULL,          --SFRSTCR_STRH_SEQNO
                                           NULL,          --SFRSTCR_STRD_SEQNO
                                           NULL,        --SFRSTCR_SURROGATE_ID
                                           NULL,             --SFRSTCR_VERSION
                                           USER,             --SFRSTCR_USER_ID
                                           vl_orden        --SFRSTCR_VPDI_CODE
                                                   );
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 DBMS_OUTPUT.put_line (
                                    'Error al insertar SFRSTCR ' || SQLERRM);
                                 vl_error :=
                                    (   'Se presento un error al insertar en la tabla SFRSTCR '
                                     || SQLERRM);
                           END;


                           BEGIN
                              UPDATE ssbsect
                                 SET ssbsect_enrl = ssbsect_enrl + 1
                               WHERE     1 = 1
                                     AND ssbsect_term_code = c.periodo
                                     AND ssbsect_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al actualizar el enrolamiento '
                                    || SQLERRM;
                           END;

                           BEGIN
                              UPDATE SZTPRONO
                                 SET SZTPRONO_ENVIO_HORARIOS = 'S'
                               WHERE     1 = 1
                                     AND SZTPRONO_NO_REGLA = p_regla
                                     AND SZTPRONO_FECHA_INICIO = pn_fecha
                                     AND SZTPRONO_PIDM = c.pidm
                                     AND sztprono_materia_legal = c.materia
                                     AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                     AND SZTPRONO_PTRM_CODE = parte;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                    (   'Se presento un error al insertar en la tabla SZTPRONO 1 '
                                     || SQLERRM);
                           END;

                           BEGIN
                              UPDATE ssbsect
                                 SET ssbsect_seats_avail =
                                        ssbsect_seats_avail - 1
                               WHERE     1 = 1
                                     AND ssbsect_term_code = c.periodo
                                     AND ssbsect_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al actualizar la disponibilidad del grupo '
                                    || SQLERRM;
                           END;

                           BEGIN
                              UPDATE ssbsect
                                 SET ssbsect_census_enrl = ssbsect_enrl
                               WHERE     1 = 1
                                     AND ssbsect_term_code = c.periodo
                                     AND ssbsect_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al actualizar el Censo del grupo '
                                    || SQLERRM;
                           END;


                           IF C.SGBSTDN_STYP_CODE = 'F'
                           THEN
                              BEGIN
                                 UPDATE sgbstdn a
                                    SET a.sgbstdn_styp_code = 'N',
                                        a.SGBSTDN_DATA_ORIGIN = 'PRONOSTICO',
                                        A.SGBSTDN_USER_ID = USER
                                  WHERE     1 = 1
                                        AND a.sgbstdn_pidm = c.pidm
                                        AND a.sgbstdn_term_code_eff =
                                               (SELECT MAX (
                                                          a1.sgbstdn_term_code_eff)
                                                  FROM sgbstdn a1
                                                 WHERE     a1.sgbstdn_pidm =
                                                              a.sgbstdn_pidm
                                                       AND a1.sgbstdn_program_1 =
                                                              a.sgbstdn_program_1)
                                        AND a.sgbstdn_program_1 = c.prog;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                       || SQLERRM;
                              END;
                           END IF;


                           BEGIN
                              SELECT COUNT (*)
                                INTO l_cambio_estatus
                                FROM sfrstcr
                               WHERE     1 = 1
                                     AND    SFRSTCR_TERM_CODE
                                         || SFRSTCR_PTRM_CODE !=
                                            c.periodo || c.parte
                                     AND sfrstcr_pidm = c.pidm
                                     AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 l_cambio_estatus := 0;
                           END;


                           IF l_cambio_estatus > 0
                           THEN
                              IF C.SGBSTDN_STYP_CODE IN ('N', 'R')
                              THEN
                                 BEGIN
                                    UPDATE sgbstdn a
                                       SET a.sgbstdn_styp_code = 'C',
                                           a.SGBSTDN_DATA_ORIGIN =
                                              'PRONOSTICO',
                                           A.SGBSTDN_USER_ID = USER
                                     WHERE     1 = 1
                                           AND a.sgbstdn_pidm = c.pidm
                                           AND a.sgbstdn_term_code_eff =
                                                  (SELECT MAX (
                                                             a1.sgbstdn_term_code_eff)
                                                     FROM sgbstdn a1
                                                    WHERE     a1.sgbstdn_pidm =
                                                                 a.sgbstdn_pidm
                                                          AND a1.sgbstdn_program_1 =
                                                                 a.sgbstdn_program_1)
                                           AND a.sgbstdn_program_1 = c.prog;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                          || SQLERRM;
                                 END;
                              END IF;
                           END IF;

                           --

                           IF c.fecha_inicio IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE sorlcur
                                    SET sorlcur_start_date =
                                           TRUNC (c.fecha_inicio),
                                        sorlcur_data_origin = 'PRONOSTICO',
                                        sorlcur_user_id = USER,
                                        SORLCUR_RATE_CODE = c.rate
                                  WHERE     1 = 1
                                        AND sorlcur_pidm = c.pidm
                                        AND sorlcur_program = c.prog
                                        AND sorlcur_lmod_code = 'LEARNER'
                                        AND sorlcur_key_seqno = c.study;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur '
                                       || SQLERRM;
                              END;
                           END IF;

                           conta_ptrm := 0;

                           BEGIN
                              SELECT COUNT (*)
                                INTO conta_ptrm
                                FROM sfrareg
                               WHERE     1 = 1
                                     AND sfrareg_pidm = c.pidm
                                     AND sfrareg_term_code = c.periodo
                                     AND sfrareg_crn = crn
                                     AND sfrareg_extension_number = 0
                                     AND sfrareg_rsts_code = p_estatus;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 conta_ptrm := 0;
                           END;

                           IF conta_ptrm = 0
                           THEN
                              BEGIN
                                 INSERT INTO sfrareg
                                      VALUES (c.pidm,
                                              c.periodo,
                                              crn,
                                              0,
                                              p_estatus,
                                              NVL (c.fecha_inicio, pn_fecha),
                                              NVL (f_fin, SYSDATE),
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
                                              NULL);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar el registro de la materia para el alumno '
                                       || SQLERRM;
                              END;
                           END IF;


                           BEGIN
                              SELECT COUNT (1)
                                INTO vl_existe
                                FROM SHRINST
                               WHERE     1 = 1
                                     AND shrinst_term_code = c.periodo
                                     AND shrinst_crn = crn
                                     AND shrinst_pidm = c.pidm;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_existe := 0;
                           END;

                           IF vl_existe = 0
                           THEN
                              BEGIN
                                 INSERT INTO SHRINST
                                      VALUES (c.periodo,   --SHRINST_TERM_CODE
                                              crn,               --SHRINST_CRN
                                              c.pidm,           --SHRINST_PIDM
                                              SYSDATE, --SHRINST_ACTIVITY_DATE
                                              'Y',       --SHRINST_PRIMARY_IND
                                              NULL,     --SHRINST_SURROGATE_ID
                                              NULL,          --SHRINST_VERSION
                                              USER,          --SHRINST_USER_ID
                                              'PRONOSTICO', --SHRINST_DATA_ORIGIN
                                              NULL);       --SHRINST_VPDI_CODE
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar al alumno en SHRINST '
                                       || SQLERRM;
                              END;
                           END IF;

                           BEGIN
                              UPDATE SZTPRONO
                                 SET SZTPRONO_ENVIO_HORARIOS = 'S'
                               WHERE     1 = 1
                                     AND SZTPRONO_NO_REGLA = p_regla
                                     --and SZTPRONO_FECHA_INICIO = pn_fecha
                                     AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                     AND sztprono_materia_legal = c.materia
                                     AND SZTPRONO_PIDM = c.pidm;
                           -- AND SZTPRONO_PTRM_CODE =parte;

                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              vl_error :=
                                    'Se presento un error al insertar al alumno en el grupo '
                                 || SQLERRM;
                        END;
                     ELSE
                        DBMS_OUTPUT.put_line (
                           'mensaje:' || 'No hay cupo en el grupo creado');
                        schd := NULL;
                        title := NULL;
                        credit := NULL;
                        gmod := NULL;
                        f_inicio := NULL;
                        f_fin := NULL;
                        sem := NULL;
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
                             FROM scbcrse, scrschd
                            WHERE     1 = 1
                                  AND scbcrse_subj_code = c.subj
                                  AND scbcrse_crse_numb = c.crse
                                  AND scbcrse_eff_term = '000000'
                                  AND scrschd_subj_code = scbcrse_subj_code
                                  AND scrschd_crse_numb = scbcrse_crse_numb
                                  AND scrschd_eff_term = scbcrse_eff_term;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              schd := NULL;
                              title := NULL;
                              credit := NULL;
                              credit_bill := NULL;
                        END;


                        BEGIN
                           SELECT scrgmod_gmod_code
                             INTO gmod
                             FROM scrgmod
                            WHERE     scrgmod_subj_code = c.subj
                                  AND scrgmod_crse_numb = c.crse
                                  AND scrgmod_default_ind = 'D';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              gmod := '1';
                        END;

                        --aqui se agrego para no gnerera mas grupos



                        IF c.prof IS NULL
                        THEN
                           crn := crn;
                        ELSE
                           IF c.nivel = 'MS'
                           THEN
                              l_campus_ms := 'AS';
                           ELSE
                              l_campus_ms := c.niVel;
                           END IF;

                           BEGIN
                              SELECT sztcrnv_crn
                                INTO crn
                                FROM SZTCRNV
                               WHERE     1 = 1
                                     AND ROWNUM = 1
                                     AND SZTCRNV_LVEL_CODE =
                                            SUBSTR (l_campus_ms, 1, 1)
                                     AND (SZTCRNV_crn, SZTCRNV_LVEL_CODE) NOT IN (SELECT TO_NUMBER (
                                                                                            crn),
                                                                                         SUBSTR (
                                                                                            SSBSECT_CRN,
                                                                                            1,
                                                                                            1)
                                                                                    FROM (SELECT CASE
                                                                                                    WHEN SUBSTR (
                                                                                                            SSBSECT_CRN,
                                                                                                            1,
                                                                                                            1) IN ('L',
                                                                                                                   'M',
                                                                                                                   'A',
                                                                                                                   'D',
                                                                                                                   'B')
                                                                                                    THEN
                                                                                                       TO_NUMBER (
                                                                                                          SUBSTR (
                                                                                                             SSBSECT_CRN,
                                                                                                             2,
                                                                                                             10))
                                                                                                    ELSE
                                                                                                       TO_NUMBER (
                                                                                                          SSBSECT_CRN)
                                                                                                 END
                                                                                                    crn,
                                                                                                 SSBSECT_CRN
                                                                                            FROM ssbsect
                                                                                           WHERE     1 =
                                                                                                        1
                                                                                                 AND ssbsect_term_code =
                                                                                                        c.periodo-- AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                         )
                                                                                   WHERE 1 =
                                                                                            1);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 -- raise_application_error (-20002,'Error al 2 '|| SQLCODE||' Error: '||SQLERRM);
                                 DBMS_OUTPUT.put_line (
                                    ' error en crn 2 ' || SQLERRM);
                                 crn := NULL;
                           END;


                           IF crn IS NOT NULL
                           THEN
                              IF c.nivel = 'LI'
                              THEN
                                 crn := 'L' || crn;
                              ELSIF c.nivel = 'MA'
                              THEN
                                 crn := 'M' || crn;
                              ELSIF c.nivel = 'MS'
                              THEN
                                 crn := 'A' || crn;
                              ELSIF c.nivel = 'EC'
                              THEN
                                 crn := 'E' || crn;
                              END IF;
                           ELSE
                              BEGIN
                                 SELECT   NVL (MAX (TO_NUMBER (SSBSECT_CRN)),
                                               0)
                                        + 1
                                   INTO crn
                                   FROM ssbsect
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND SUBSTR (ssbsect_crn, 1, 1) NOT IN ('L',
                                                                               'M',
                                                                               'A',
                                                                               'D',
                                                                               'B');
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    DBMS_OUTPUT.put_line (
                                       'sqlerrm ' || crn || ' ' || SQLERRM);
                                    crn := NULL;
                              END;

                              DBMS_OUTPUT.put_line ('crn ' || crn);
                           END IF;
                        END IF;

                        BEGIN
                           SELECT DISTINCT
                                  sobptrm_start_date,
                                  sobptrm_end_date,
                                  sobptrm_weeks
                             INTO f_inicio, f_fin, sem
                             FROM sobptrm
                            WHERE     1 = 1
                                  AND sobptrm_term_code = c.periodo
                                  AND sobptrm_ptrm_code = c.parte;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        IF crn IS NOT NULL
                        THEN
                           BEGIN
                              l_maximo_alumnos := 90;
                           END;


                           --raise_application_error (-20002,'Buscamos SSBSECT_CENSUS_ENRL_DATE '||f_inicio);

                           BEGIN
                              INSERT INTO ssbsect
                                   VALUES (c.periodo,      --SSBSECT_TERM_CODE
                                           crn,                  --SSBSECT_CRN
                                           c.parte,        --SSBSECT_PTRM_CODE
                                           c.subj,         --SSBSECT_SUBJ_CODE
                                           c.crse,         --SSBSECT_CRSE_NUMB
                                           c.grupo,         --SSBSECT_SEQ_NUMB
                                           'A',            --SSBSECT_SSTS_CODE
                                           'ENL',          --SSBSECT_SCHD_CODE
                                           c.campus,       --SSBSECT_CAMP_CODE
                                           title,         --SSBSECT_CRSE_TITLE
                                           credit,        --SSBSECT_CREDIT_HRS
                                           credit_bill,     --SSBSECT_BILL_HRS
                                           gmod,           --SSBSECT_GMOD_CODE
                                           NULL,           --SSBSECT_SAPR_CODE
                                           NULL,           --SSBSECT_SESS_CODE
                                           NULL,          --SSBSECT_LINK_IDENT
                                           NULL,            --SSBSECT_PRNT_IND
                                           'Y',         --SSBSECT_GRADABLE_IND
                                           NULL,            --SSBSECT_TUIW_IND
                                           0,              --SSBSECT_REG_ONEUP
                                           0,             --SSBSECT_PRIOR_ENRL
                                           0,              --SSBSECT_PROJ_ENRL
                                           l_maximo_alumnos, --SSBSECT_MAX_ENRL
                                           0,                   --SSBSECT_ENRL
                                           l_maximo_alumnos, --SSBSECT_SEATS_AVAIL
                                           NULL,      --SSBSECT_TOT_CREDIT_HRS
                                           '0',          --SSBSECT_CENSUS_ENRL
                                           f_inicio, --SSBSECT_CENSUS_ENRL_DATE
                                           SYSDATE - 5, --SSBSECT_ACTIVITY_DATE
                                           f_inicio, --SSBSECT_PTRM_START_DATE
                                           f_fin,      --SSBSECT_PTRM_END_DATE
                                           sem,           --SSBSECT_PTRM_WEEKS
                                           NULL,        --SSBSECT_RESERVED_IND
                                           NULL,       --SSBSECT_WAIT_CAPACITY
                                           NULL,          --SSBSECT_WAIT_COUNT
                                           NULL,          --SSBSECT_WAIT_AVAIL
                                           NULL,              --SSBSECT_LEC_HR
                                           NULL,              --SSBSECT_LAB_HR
                                           NULL,              --SSBSECT_OTH_HR
                                           NULL,             --SSBSECT_CONT_HR
                                           NULL,           --SSBSECT_ACCT_CODE
                                           NULL,           --SSBSECT_ACCL_CODE
                                           NULL,       --SSBSECT_CENSUS_2_DATE
                                           NULL,   --SSBSECT_ENRL_CUT_OFF_DATE
                                           NULL,   --SSBSECT_ACAD_CUT_OFF_DATE
                                           NULL,   --SSBSECT_DROP_CUT_OFF_DATE
                                           NULL,       --SSBSECT_CENSUS_2_ENRL
                                           'Y',          --SSBSECT_VOICE_AVAIL
                                           'N', --SSBSECT_CAPP_PREREQ_TEST_IND
                                           NULL,           --SSBSECT_GSCH_NAME
                                           NULL,        --SSBSECT_BEST_OF_COMP
                                           NULL,      --SSBSECT_SUBSET_OF_COMP
                                           'NOP',          --SSBSECT_INSM_CODE
                                           NULL,       --SSBSECT_REG_FROM_DATE
                                           NULL,         --SSBSECT_REG_TO_DATE
                                           NULL, --SSBSECT_LEARNER_REGSTART_FDATE
                                           NULL, --SSBSECT_LEARNER_REGSTART_TDATE
                                           NULL,           --SSBSECT_DUNT_CODE
                                           NULL,     --SSBSECT_NUMBER_OF_UNITS
                                           0,   --SSBSECT_NUMBER_OF_EXTENSIONS
                                           'PRONOSTICO', --SSBSECT_DATA_ORIGIN
                                           USER,             --SSBSECT_USER_ID
                                           'MOOD',          --SSBSECT_INTG_CDE
                                           'B', --SSBSECT_PREREQ_CHK_METHOD_CDE
                                           USER,    --SSBSECT_KEYWORD_INDEX_ID
                                           NULL,     --SSBSECT_SCORE_OPEN_DATE
                                           NULL,   --SSBSECT_SCORE_CUTOFF_DATE
                                           NULL, --SSBSECT_REAS_SCORE_OPEN_DATE
                                           NULL, --SSBSECT_REAS_SCORE_CTOF_DATE
                                           NULL,        --SSBSECT_SURROGATE_ID
                                           NULL,             --SSBSECT_VERSION
                                           NULL);          --SSBSECT_VPDI_CODE


                              BEGIN
                                 UPDATE sobterm
                                    SET sobterm_crn_oneup = crn
                                  WHERE     1 = 1
                                        AND sobterm_term_code = c.periodo;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;



                              BEGIN
                                 INSERT INTO ssrmeet
                                      VALUES (C.periodo,
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
                                              NULL);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un Error al insertar en ssrmeet '
                                       || SQLERRM;
                              END;

                              BEGIN
                                 SELECT spriden_pidm
                                   INTO pidm_prof
                                   FROM spriden
                                  WHERE     1 = 1
                                        AND spriden_id = c.prof
                                        AND spriden_change_ind IS NULL;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    pidm_prof := NULL;
                              END;

                              IF pidm_prof IS NOT NULL
                              THEN
                                 DBMS_OUTPUT.put_line (
                                       'Crea el CRN para el docente:'
                                    || pidm_prof
                                    || '*'
                                    || crn);

                                 BEGIN
                                    SELECT COUNT (1)
                                      INTO vl_exite_prof
                                      FROM sirasgn
                                     WHERE     1 = 1
                                           AND sirasgn_term_code = c.periodo
                                           AND sirasgn_crn = crn;
                                 -- And SIRASGN_PIDM = pidm_prof;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_exite_prof := 0;
                                 END;

                                 IF vl_exite_prof = 0
                                 THEN
                                    BEGIN
                                       INSERT INTO sirasgn
                                            VALUES (c.periodo,
                                                    crn,
                                                    pidm_prof,
                                                    '01',
                                                    100,
                                                    NULL,
                                                    100,
                                                    'Y',
                                                    NULL,
                                                    NULL,
                                                    SYSDATE - 5,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    'PRONOSTICO',
                                                    'SZFALGO 2',
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL);
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          NULL;
                                    END;
                                 ELSE
                                    BEGIN
                                       UPDATE sirasgn
                                          SET sirasgn_primary_ind = NULL
                                        WHERE     1 = 1
                                              AND sirasgn_term_code =
                                                     c.periodo
                                              AND sirasgn_crn = crn;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          NULL;
                                    END;

                                    BEGIN
                                       INSERT INTO sirasgn
                                            VALUES (c.periodo,
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
                                                    NULL);
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          NULL;
                                    END;
                                 END IF;
                              END IF;

                              conta_ptrm := 0;

                              BEGIN
                                 SELECT COUNT (*)
                                   INTO conta_ptrm
                                   FROM sfbetrm
                                  WHERE     1 = 1
                                        AND sfbetrm_term_code = c.periodo
                                        AND sfbetrm_pidm = c.pidm;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    conta_ptrm := 0;
                              END;


                              IF conta_ptrm = 0
                              THEN
                                 BEGIN
                                    INSERT INTO sfbetrm
                                         VALUES (c.periodo,
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                          (   'Se presento un error al insertar en la tabla sfbetrm '
                                           || SQLERRM);
                                 END;
                              END IF;

                              BEGIN
                                 BEGIN
                                    INSERT INTO sfrstcr
                                         VALUES (c.periodo, --SFRSTCR_TERM_CODE
                                                 c.pidm,        --SFRSTCR_PIDM
                                                 crn,            --SFRSTCR_CRN
                                                 1,   --SFRSTCR_CLASS_SORT_KEY
                                                 c.grupo,    --SFRSTCR_REG_SEQ
                                                 c.parte,  --SFRSTCR_PTRM_CODE
                                                 p_estatus, --SFRSTCR_RSTS_CODE
                                                 SYSDATE - 5, --SFRSTCR_RSTS_DATE
                                                 NULL,    --SFRSTCR_ERROR_FLAG
                                                 NULL,       --SFRSTCR_MESSAGE
                                                 credit_bill, --SFRSTCR_BILL_HR
                                                 3,          --SFRSTCR_WAIV_HR
                                                 credit,   --SFRSTCR_CREDIT_HR
                                                 credit_bill, --SFRSTCR_BILL_HR_HOLD
                                                 credit, --SFRSTCR_CREDIT_HR_HOLD
                                                 gmod,     --SFRSTCR_GMOD_CODE
                                                 NULL,     --SFRSTCR_GRDE_CODE
                                                 NULL, --SFRSTCR_GRDE_CODE_MID
                                                 NULL,     --SFRSTCR_GRDE_DATE
                                                 'N',      --SFRSTCR_DUPL_OVER
                                                 'N',      --SFRSTCR_LINK_OVER
                                                 'N',      --SFRSTCR_CORQ_OVER
                                                 'N',      --SFRSTCR_PREQ_OVER
                                                 'N',      --SFRSTCR_TIME_OVER
                                                 'N',      --SFRSTCR_CAPC_OVER
                                                 'N',      --SFRSTCR_LEVL_OVER
                                                 'N',      --SFRSTCR_COLL_OVER
                                                 'N',      --SFRSTCR_MAJR_OVER
                                                 'N',      --SFRSTCR_CLAS_OVER
                                                 'N',      --SFRSTCR_APPR_OVER
                                                 'N', --SFRSTCR_APPR_RECEIVED_IND
                                                 SYSDATE - 5, --SFRSTCR_ADD_DATE
                                                 SYSDATE - 5, --SFRSTCR_ACTIVITY_DATE
                                                 c.nivel,  --SFRSTCR_LEVL_CODE
                                                 c.campus, --SFRSTCR_CAMP_CODE
                                                 c.materia, --SFRSTCR_RESERVED_KEY
                                                 NULL,     --SFRSTCR_ATTEND_HR
                                                 'Y',      --SFRSTCR_REPT_OVER
                                                 'N',      --SFRSTCR_RPTH_OVER
                                                 NULL,     --SFRSTCR_TEST_OVER
                                                 'N',      --SFRSTCR_CAMP_OVER
                                                 USER,          --SFRSTCR_USER
                                                 'N',      --SFRSTCR_DEGC_OVER
                                                 'N',      --SFRSTCR_PROG_OVER
                                                 NULL,   --SFRSTCR_LAST_ATTEND
                                                 NULL,     --SFRSTCR_GCMT_CODE
                                                 'PRONOSTICO', --SFRSTCR_DATA_ORIGIN
                                                 SYSDATE, --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                 'N',      --SFRSTCR_DEPT_OVER
                                                 'N',      --SFRSTCR_ATTS_OVER
                                                 'N',      --SFRSTCR_CHRT_OVER
                                                 c.grupo,   --SFRSTCR_RMSG_CDE
                                                 NULL,   --SFRSTCR_WL_PRIORITY
                                                 NULL, --SFRSTCR_WL_PRIORITY_ORIG
                                                 NULL, --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                 NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                 'N',      --SFRSTCR_MEXC_OVER
                                                 c.study, --SFRSTCR_STSP_KEY_SEQUENCE
                                                 NULL,  --SFRSTCR_BRDH_SEQ_NUM
                                                 '01',     --SFRSTCR_BLCK_CODE
                                                 NULL,    --SFRSTCR_STRH_SEQNO
                                                 NULL,    --SFRSTCR_STRD_SEQNO
                                                 NULL,  --SFRSTCR_SURROGATE_ID
                                                 NULL,       --SFRSTCR_VERSION
                                                 USER,       --SFRSTCR_USER_ID
                                                 vl_orden  --SFRSTCR_VPDI_CODE
                                                         );
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                          (   'Se presento un error al insertar en la tabla SFRSTCR 2 '
                                           || SQLERRM);
                                 END;


                                 BEGIN
                                    UPDATE SZTPRONO
                                       SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                     WHERE     1 = 1
                                           AND SZTPRONO_NO_REGLA = p_regla
                                           -- and SZTPRONO_FECHA_INICIO = pn_fecha
                                           AND SZTPRONO_PIDM = c.pidm
                                           AND sztprono_materia_legal =
                                                  c.materia
                                           AND SZTPRONO_ENVIO_HORARIOS = 'N';
                                 -- AND SZTPRONO_PTRM_CODE =parte;


                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al insertar en la tabla SZTPRONO 2 '
                                          || SQLERRM;
                                 END;


                                 BEGIN
                                    UPDATE ssbsect
                                       SET ssbsect_enrl = ssbsect_enrl + 1
                                     WHERE     1 = 1
                                           AND ssbsect_term_code = c.periodo
                                           AND SSBSECT_CRN = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el enrolamiento '
                                          || SQLERRM;
                                 END;

                                 BEGIN
                                    UPDATE ssbsect
                                       SET ssbsect_seats_avail =
                                              ssbsect_seats_avail - 1
                                     WHERE     1 = 1
                                           AND ssbsect_term_code = c.periodo
                                           AND ssbsect_crn = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar la disponibilidad del grupo '
                                          || SQLERRM;
                                 END;

                                 BEGIN
                                    UPDATE ssbsect
                                       SET ssbsect_census_enrl = ssbsect_enrl
                                     WHERE     SSBSECT_TERM_CODE = c.periodo
                                           AND SSBSECT_CRN = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el Censo del grupo '
                                          || SQLERRM;
                                 END;

                                 IF C.SGBSTDN_STYP_CODE = 'F'
                                 THEN
                                    BEGIN
                                       UPDATE sgbstdn a
                                          SET a.sgbstdn_styp_code = 'N',
                                              a.SGBSTDN_DATA_ORIGIN =
                                                 'PRONOSTICO',
                                              A.SGBSTDN_USER_ID = USER
                                        WHERE     1 = 1
                                              AND a.sgbstdn_pidm = c.pidm
                                              AND a.sgbstdn_term_code_eff =
                                                     (SELECT MAX (
                                                                a1.sgbstdn_term_code_eff)
                                                        FROM sgbstdn a1
                                                       WHERE     a1.sgbstdn_pidm =
                                                                    a.sgbstdn_pidm
                                                             AND a1.sgbstdn_program_1 =
                                                                    a.sgbstdn_program_1)
                                              AND a.sgbstdn_program_1 =
                                                     c.prog;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                             || SQLERRM;
                                    END;
                                 END IF;

                                 BEGIN
                                    SELECT COUNT (*)
                                      INTO l_cambio_estatus
                                      FROM sfrstcr
                                     WHERE     1 = 1
                                           AND    SFRSTCR_TERM_CODE
                                               || SFRSTCR_PTRM_CODE !=
                                                  c.periodo || c.parte
                                           AND sfrstcr_pidm = c.pidm
                                           AND SFRSTCR_STSP_KEY_SEQUENCE =
                                                  c.study;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       l_cambio_estatus := 0;
                                 END;


                                 IF l_cambio_estatus > 0
                                 THEN
                                    IF C.SGBSTDN_STYP_CODE IN ('N', 'R')
                                    THEN
                                       BEGIN
                                          UPDATE sgbstdn a
                                             SET a.sgbstdn_styp_code = 'C',
                                                 a.SGBSTDN_DATA_ORIGIN =
                                                    'PRONOSTICO',
                                                 A.SGBSTDN_USER_ID = USER
                                           WHERE     1 = 1
                                                 AND a.sgbstdn_pidm = c.pidm
                                                 AND a.sgbstdn_term_code_eff =
                                                        (SELECT MAX (
                                                                   a1.sgbstdn_term_code_eff)
                                                           FROM sgbstdn a1
                                                          WHERE     a1.sgbstdn_pidm =
                                                                       a.sgbstdn_pidm
                                                                AND a1.sgbstdn_program_1 =
                                                                       a.sgbstdn_program_1)
                                                 AND a.sgbstdn_program_1 =
                                                        c.prog;
                                       EXCEPTION
                                          WHEN OTHERS
                                          THEN
                                             vl_error :=
                                                   'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                                || SQLERRM;
                                       END;
                                    END IF;
                                 END IF;

                                 f_inicio := NULL;

                                 BEGIN
                                    SELECT DISTINCT sobptrm_start_date
                                      INTO f_inicio
                                      FROM sobptrm
                                     WHERE     sobptrm_term_code = c.periodo
                                           AND sobptrm_ptrm_code = c.parte;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       f_inicio := NULL;
                                       vl_error :=
                                             'Se presento un error al Obtener la fecha de inicio de Clases periodo '
                                          || c.periodo
                                          || ' parte '
                                          || c.parte
                                          || ' '
                                          || SQLERRM
                                          || ' poe';
                                 END;

                                 IF f_inicio IS NOT NULL
                                 THEN
                                    BEGIN
                                       UPDATE sorlcur
                                          SET sorlcur_start_date =
                                                 TRUNC (f_inicio),
                                              SORLCUR_RATE_CODE = c.rate
                                        WHERE     SORLCUR_PIDM = c.pidm
                                              AND SORLCUR_PROGRAM = c.prog
                                              AND SORLCUR_LMOD_CODE =
                                                     'LEARNER'
                                              AND SORLCUR_KEY_SEQNO = c.study;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur '
                                             || SQLERRM;
                                    END;
                                 END IF;

                                 conta_ptrm := 0;

                                 BEGIN
                                    SELECT COUNT (*)
                                      INTO conta_ptrm
                                      FROM sfrareg
                                     WHERE     1 = 1
                                           AND sfrareg_pidm = c.pidm
                                           AND sfrareg_term_code = c.periodo
                                           AND sfrareg_crn = crn
                                           AND sfrareg_extension_number = 0
                                           AND sfrareg_rsts_code = p_estatus;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       conta_ptrm := 0;
                                 END;

                                 IF conta_ptrm = 0
                                 THEN
                                    BEGIN
                                       INSERT INTO sfrareg
                                            VALUES (c.pidm,
                                                    c.periodo,
                                                    crn,
                                                    0,
                                                    p_estatus,
                                                    NVL (f_inicio, pn_fecha),
                                                    NVL (f_fin, SYSDATE),
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
                                                    NULL);
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al insertar sfrareg 2 el registro de la materia para el alumno '
                                             || SQLERRM;
                                    END;
                                 END IF;

                                 BEGIN
                                    UPDATE SZTPRONO
                                       SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                     WHERE     1 = 1
                                           AND SZTPRONO_NO_REGLA = p_regla
                                           -- and SZTPRONO_FECHA_INICIO = pn_fecha
                                           AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                           AND sztprono_materia_legal =
                                                  c.materia
                                           AND SZTPRONO_PIDM = c.pidm;
                                 -- AND SZTPRONO_PTRM_CODE =parte;


                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al insertar en la tabla SZTPRONO 3 '
                                          || SQLERRM;
                                 END;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar al alumno en el grupo2 '
                                       || SQLERRM;
                              END;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un Error al insertar el nuevo grupo en la tabla SSBSECT '
                                    || SQLERRM;
                           END;
                        END IF;
                     END IF;                -------- > No hay cupo en el grupo
                  ELSE
                     DBMS_OUTPUT.put_line (
                           'mensaje:'
                        || 'No hay grupo creado Con docente 2 chuy');

                     schd := NULL;
                     title := NULL;
                     credit := NULL;
                     gmod := NULL;
                     f_inicio := NULL;
                     f_fin := NULL;
                     sem := NULL;
                     crn := NULL;
                     pidm_prof := NULL;
                     vl_exite_prof := 0;

                     BEGIN
                        SELECT scrschd_schd_code,
                               scbcrse_title,
                               scbcrse_credit_hr_low,
                               scbcrse_bill_hr_low
                          INTO schd,
                               title,
                               credit,
                               credit_bill
                          FROM scbcrse, scrschd
                         WHERE     1 = 1
                               AND scbcrse_subj_code = c.subj
                               AND scbcrse_crse_numb = c.crse
                               AND scbcrse_eff_term = '000000'
                               AND scrschd_subj_code = scbcrse_subj_code
                               AND scrschd_crse_numb = scbcrse_crse_numb
                               AND scrschd_eff_term = scbcrse_eff_term;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           schd := NULL;
                           title := NULL;
                           credit := NULL;
                           credit_bill := NULL;
                     END;

                     DBMS_OUTPUT.put_line ('mensaje 2-->1');

                     BEGIN
                        SELECT scrgmod_gmod_code
                          INTO gmod
                          FROM scrgmod
                         WHERE     1 = 1
                               AND scrgmod_subj_code = c.subj
                               AND scrgmod_crse_numb = c.crse
                               AND scrgmod_default_ind = 'D';
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           gmod := '1';
                     END;

                     DBMS_OUTPUT.put_line ('mensaje 3 ' || c.nivel);

                     --
                     IF c.nivel = 'MS'
                     THEN
                        l_campus_ms := 'AS';
                     ELSE
                        l_campus_ms := c.niVel;
                     END IF;

                     DBMS_OUTPUT.put_line (
                        'nivel' || l_campus_ms || ' cnivel ' || c.niVel);


                     BEGIN
                        SELECT sztcrnv_crn
                          INTO crn
                          FROM SZTCRNV
                         WHERE     1 = 1
                               AND ROWNUM = 1
                               AND SZTCRNV_LVEL_CODE =
                                      SUBSTR (l_campus_ms, 1, 1)
                               AND (SZTCRNV_crn, SZTCRNV_LVEL_CODE) NOT IN (SELECT TO_NUMBER (
                                                                                      crn),
                                                                                   SUBSTR (
                                                                                      SSBSECT_CRN,
                                                                                      1,
                                                                                      1)
                                                                              FROM (SELECT CASE
                                                                                              WHEN SUBSTR (
                                                                                                      SSBSECT_CRN,
                                                                                                      1,
                                                                                                      1) IN ('L',
                                                                                                             'M',
                                                                                                             'A',
                                                                                                             'D',
                                                                                                             'B',
                                                                                                             'E')
                                                                                              THEN
                                                                                                 TO_NUMBER (
                                                                                                    SUBSTR (
                                                                                                       SSBSECT_CRN,
                                                                                                       2,
                                                                                                       10))
                                                                                              ELSE
                                                                                                 TO_NUMBER (
                                                                                                    SSBSECT_CRN)
                                                                                           END
                                                                                              crn,
                                                                                           SSBSECT_CRN
                                                                                      FROM ssbsect
                                                                                     WHERE     1 =
                                                                                                  1
                                                                                           AND ssbsect_term_code =
                                                                                                  c.periodo-- AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                   )
                                                                             WHERE 1 =
                                                                                      1);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           --raise_application_error (-20002,'Error al 2 '|| SQLCODE||' Error: '||SQLERRM);
                           DBMS_OUTPUT.put_line (
                              ' error en crn 2 ' || SQLERRM);
                           crn := NULL;
                     END;

                     DBMS_OUTPUT.put_line ('mensaje 4 ' || crn);

                     IF crn IS NOT NULL
                     THEN
                        DBMS_OUTPUT.put_line ('mensaje 5');

                        IF c.nivel = 'LI'
                        THEN
                           crn := 'L' || crn;
                        ELSIF c.nivel = 'MA'
                        THEN
                           crn := 'M' || crn;
                        ELSIF c.nivel = 'DO'
                        THEN
                           crn := 'D' || crn;
                        ELSIF c.nivel = 'MS'
                        THEN
                           crn := 'A' || crn;
                        ELSIF c.nivel = 'EC'
                        THEN
                           crn := 'E' || crn;
                        END IF;
                     ELSE
                        BEGIN
                           SELECT NVL (MAX (TO_NUMBER (SSBSECT_CRN)), 0) + 1
                             INTO crn
                             FROM ssbsect
                            WHERE     1 = 1
                                  AND ssbsect_term_code = c.periodo
                                  AND SUBSTR (ssbsect_crn, 1, 1) NOT IN ('L',
                                                                         'M',
                                                                         'A',
                                                                         'D',
                                                                         'B');
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              DBMS_OUTPUT.put_line (
                                 'sqlerrm ' || crn || ' ' || SQLERRM);
                              crn := NULL;
                        END;

                        DBMS_OUTPUT.put_line ('crn ' || crn);
                     END IF;

                     BEGIN
                        DBMS_OUTPUT.put_line ('mensaje 6');

                        SELECT DISTINCT
                               sobptrm_start_date,
                               sobptrm_end_date,
                               sobptrm_weeks
                          INTO f_inicio, f_fin, sem
                          FROM sobptrm
                         WHERE     1 = 1
                               AND sobptrm_term_code = c.periodo
                               AND sobptrm_ptrm_code = c.parte;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'No se Encontro configuracion para el Periodo= '
                              || c.periodo
                              || ' y Parte de Periodo= '
                              || c.parte
                              || SQLERRM;
                     END;


                     IF crn IS NOT NULL
                     THEN
                        -- le movemos extraemos el numero de alumonos de la tabla de profesores

                        DBMS_OUTPUT.put_line ('mensaje 7 crn ' || crn);

                        BEGIN
                           l_maximo_alumnos := 90;
                        END;



                        BEGIN
                           INSERT INTO ssbsect
                                VALUES (c.periodo,         --SSBSECT_TERM_CODE
                                        crn,                     --SSBSECT_CRN
                                        c.parte,           --SSBSECT_PTRM_CODE
                                        c.subj,            --SSBSECT_SUBJ_CODE
                                        c.crse,            --SSBSECT_CRSE_NUMB
                                        c.grupo,            --SSBSECT_SEQ_NUMB
                                        'A',               --SSBSECT_SSTS_CODE
                                        'ENL',             --SSBSECT_SCHD_CODE
                                        c.campus,          --SSBSECT_CAMP_CODE
                                        title,            --SSBSECT_CRSE_TITLE
                                        credit,           --SSBSECT_CREDIT_HRS
                                        credit_bill,        --SSBSECT_BILL_HRS
                                        gmod,              --SSBSECT_GMOD_CODE
                                        NULL,              --SSBSECT_SAPR_CODE
                                        NULL,              --SSBSECT_SESS_CODE
                                        NULL,             --SSBSECT_LINK_IDENT
                                        NULL,               --SSBSECT_PRNT_IND
                                        'Y',            --SSBSECT_GRADABLE_IND
                                        NULL,               --SSBSECT_TUIW_IND
                                        0,                 --SSBSECT_REG_ONEUP
                                        0,                --SSBSECT_PRIOR_ENRL
                                        0,                 --SSBSECT_PROJ_ENRL
                                        l_maximo_alumnos,   --SSBSECT_MAX_ENRL
                                        0,                      --SSBSECT_ENRL
                                        l_maximo_alumnos, --SSBSECT_SEATS_AVAIL
                                        NULL,         --SSBSECT_TOT_CREDIT_HRS
                                        '0',             --SSBSECT_CENSUS_ENRL
                                        NVL (f_inicio, SYSDATE), --SSBSECT_CENSUS_ENRL_DATE
                                        SYSDATE,       --SSBSECT_ACTIVITY_DATE
                                        NVL (f_inicio, SYSDATE), --SSBSECT_PTRM_START_DATE
                                        NVL (f_FIN, SYSDATE), --SSBSECT_PTRM_END_DATE
                                        sem,              --SSBSECT_PTRM_WEEKS
                                        NULL,           --SSBSECT_RESERVED_IND
                                        NULL,          --SSBSECT_WAIT_CAPACITY
                                        NULL,             --SSBSECT_WAIT_COUNT
                                        NULL,             --SSBSECT_WAIT_AVAIL
                                        NULL,                 --SSBSECT_LEC_HR
                                        NULL,                 --SSBSECT_LAB_HR
                                        NULL,                 --SSBSECT_OTH_HR
                                        NULL,                --SSBSECT_CONT_HR
                                        NULL,              --SSBSECT_ACCT_CODE
                                        NULL,              --SSBSECT_ACCL_CODE
                                        NULL,          --SSBSECT_CENSUS_2_DATE
                                        NULL,      --SSBSECT_ENRL_CUT_OFF_DATE
                                        NULL,      --SSBSECT_ACAD_CUT_OFF_DATE
                                        NULL,      --SSBSECT_DROP_CUT_OFF_DATE
                                        NULL,            --SSBSECT_CENSUS_ENRL
                                        'Y',             --SSBSECT_VOICE_AVAIL
                                        'N',    --SSBSECT_CAPP_PREREQ_TEST_IND
                                        NULL,              --SSBSECT_GSCH_NAME
                                        NULL,           --SSBSECT_BEST_OF_COMP
                                        NULL,         --SSBSECT_SUBSET_OF_COMP
                                        'NOP',             --SSBSECT_INSM_CODE
                                        NULL,          --SSBSECT_REG_FROM_DATE
                                        NULL,            --SSBSECT_REG_TO_DATE
                                        NULL, --SSBSECT_LEARNER_REGSTART_FDATE
                                        NULL, --SSBSECT_LEARNER_REGSTART_TDATE
                                        NULL,              --SSBSECT_DUNT_CODE
                                        NULL,        --SSBSECT_NUMBER_OF_UNITS
                                        0,      --SSBSECT_NUMBER_OF_EXTENSIONS
                                        'PRONOSTICO',    --SSBSECT_DATA_ORIGIN
                                        USER,                --SSBSECT_USER_ID
                                        'MOOD',             --SSBSECT_INTG_CDE
                                        'B',   --SSBSECT_PREREQ_CHK_METHOD_CDE
                                        USER,       --SSBSECT_KEYWORD_INDEX_ID
                                        NULL,        --SSBSECT_SCORE_OPEN_DATE
                                        NULL,      --SSBSECT_SCORE_CUTOFF_DATE
                                        NULL,   --SSBSECT_REAS_SCORE_OPEN_DATE
                                        NULL,   --SSBSECT_REAS_SCORE_CTOF_DATE
                                        NULL,           --SSBSECT_SURROGATE_ID
                                        NULL,                --SSBSECT_VERSION
                                        NULL               --SSBSECT_VPDI_CODE
                                            );


                           BEGIN
                              UPDATE SOBTERM
                                 SET sobterm_crn_oneup = crn
                               WHERE 1 = 1 AND sobterm_term_code = c.periodo;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;

                           BEGIN
                              INSERT INTO ssrmeet
                                   VALUES (C.periodo,
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
                                           NULL);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un Error al insertar en ssrmeet '
                                    || SQLERRM;
                           END;

                           BEGIN
                              SELECT spriden_pidm
                                INTO pidm_prof
                                FROM spriden
                               WHERE     1 = 1
                                     AND spriden_id = c.prof
                                     AND spriden_change_ind IS NULL;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 pidm_prof := NULL;
                           END;

                           IF pidm_prof IS NOT NULL
                           THEN
                              DBMS_OUTPUT.put_line (
                                    'Crea el CRN para el docente:'
                                 || pidm_prof
                                 || '*'
                                 || crn);

                              BEGIN
                                 SELECT COUNT (1)
                                   INTO vl_exite_prof
                                   FROM sirasgn
                                  WHERE     1 = 1
                                        AND sirasgn_term_code = c.periodo
                                        AND sirasgn_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_exite_prof := 0;
                              END;

                              IF vl_exite_prof = 0
                              THEN
                                 BEGIN
                                    INSERT INTO sirasgn
                                         VALUES (c.periodo,
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;
                              ELSE
                                 BEGIN
                                    UPDATE sirasgn
                                       SET sirasgn_primary_ind = NULL
                                     WHERE     1 = 1
                                           AND sirasgn_term_code = c.periodo
                                           AND sirasgn_crn = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;

                                 BEGIN
                                    INSERT INTO sirasgn
                                         VALUES (c.periodo,
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;
                              END IF;
                           END IF;

                           conta_ptrm := 0;

                           BEGIN
                              SELECT COUNT (*)
                                INTO conta_ptrm
                                FROM sfbetrm
                               WHERE     1 = 1
                                     AND sfbetrm_term_code = c.periodo
                                     AND sfbetrm_pidm = c.pidm;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 conta_ptrm := 0;
                           END;

                           -- dbms_output.put_line(' cuenta ptrm '||conta_ptrm);

                           IF conta_ptrm = 0
                           THEN
                              DBMS_OUTPUT.put_line (
                                 ' cuenta ptrm --> ' || conta_ptrm);

                              BEGIN
                                 INSERT INTO sfbetrm
                                      VALUES (c.periodo,
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
                                              NULL);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                       (   'Se presento un error al insertar en la tabla sfbetrm '
                                        || SQLERRM);

                                    DBMS_OUTPUT.put_line (vl_error);
                              END;
                           END IF;

                           BEGIN
                              BEGIN
                                 INSERT INTO sfrstcr
                                      VALUES (c.periodo,   --SFRSTCR_TERM_CODE
                                              c.pidm,           --SFRSTCR_PIDM
                                              crn,               --SFRSTCR_CRN
                                              1,      --SFRSTCR_CLASS_SORT_KEY
                                              c.grupo,       --SFRSTCR_REG_SEQ
                                              c.parte,     --SFRSTCR_PTRM_CODE
                                              p_estatus,   --SFRSTCR_RSTS_CODE
                                              SYSDATE - 5, --SFRSTCR_RSTS_DATE
                                              NULL,       --SFRSTCR_ERROR_FLAG
                                              NULL,          --SFRSTCR_MESSAGE
                                              credit_bill,   --SFRSTCR_BILL_HR
                                              3,             --SFRSTCR_WAIV_HR
                                              credit,      --SFRSTCR_CREDIT_HR
                                              credit_bill, --SFRSTCR_BILL_HR_HOLD
                                              credit, --SFRSTCR_CREDIT_HR_HOLD
                                              gmod,        --SFRSTCR_GMOD_CODE
                                              NULL,        --SFRSTCR_GRDE_CODE
                                              NULL,    --SFRSTCR_GRDE_CODE_MID
                                              NULL,        --SFRSTCR_GRDE_DATE
                                              'N',         --SFRSTCR_DUPL_OVER
                                              'N',         --SFRSTCR_LINK_OVER
                                              'N',         --SFRSTCR_CORQ_OVER
                                              'N',         --SFRSTCR_PREQ_OVER
                                              'N',         --SFRSTCR_TIME_OVER
                                              'N',         --SFRSTCR_CAPC_OVER
                                              'N',         --SFRSTCR_LEVL_OVER
                                              'N',         --SFRSTCR_COLL_OVER
                                              'N',         --SFRSTCR_MAJR_OVER
                                              'N',         --SFRSTCR_CLAS_OVER
                                              'N',         --SFRSTCR_APPR_OVER
                                              'N', --SFRSTCR_APPR_RECEIVED_IND
                                              SYSDATE - 5,  --SFRSTCR_ADD_DATE
                                              SYSDATE - 5, --SFRSTCR_ACTIVITY_DATE
                                              c.nivel,     --SFRSTCR_LEVL_CODE
                                              c.campus,    --SFRSTCR_CAMP_CODE
                                              c.materia, --SFRSTCR_RESERVED_KEY
                                              NULL,        --SFRSTCR_ATTEND_HR
                                              'Y',         --SFRSTCR_REPT_OVER
                                              'N',         --SFRSTCR_RPTH_OVER
                                              NULL,        --SFRSTCR_TEST_OVER
                                              'N',         --SFRSTCR_CAMP_OVER
                                              USER,             --SFRSTCR_USER
                                              'N',         --SFRSTCR_DEGC_OVER
                                              'N',         --SFRSTCR_PROG_OVER
                                              NULL,      --SFRSTCR_LAST_ATTEND
                                              NULL,        --SFRSTCR_GCMT_CODE
                                              'PRONOSTICO', --SFRSTCR_DATA_ORIGIN
                                              SYSDATE, --SFRSTCR_ASSESS_ACTIVITY_DATE
                                              'N',         --SFRSTCR_DEPT_OVER
                                              'N',         --SFRSTCR_ATTS_OVER
                                              'N',         --SFRSTCR_CHRT_OVER
                                              c.grupo,      --SFRSTCR_RMSG_CDE
                                              NULL,      --SFRSTCR_WL_PRIORITY
                                              NULL, --SFRSTCR_WL_PRIORITY_ORIG
                                              NULL, --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                              NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                              'N',         --SFRSTCR_MEXC_OVER
                                              c.study, --SFRSTCR_STSP_KEY_SEQUENCE
                                              NULL,     --SFRSTCR_BRDH_SEQ_NUM
                                              '01',        --SFRSTCR_BLCK_CODE
                                              NULL,       --SFRSTCR_STRH_SEQNO
                                              NULL,       --SFRSTCR_STRD_SEQNO
                                              NULL,     --SFRSTCR_SURROGATE_ID
                                              NULL,          --SFRSTCR_VERSION
                                              USER,          --SFRSTCR_USER_ID
                                              vl_orden     --SFRSTCR_VPDI_CODE
                                                      );
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    -- dbms_output.put_line('Error al insertar SFRSTCR xxx '||sqlerrm);
                                    vl_error :=
                                       (   'Se presento un error al insertar en la tabla SFRSTCR 4 '
                                        || SQLERRM);
                              END;


                              BEGIN
                                 UPDATE SZTPRONO
                                    SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                  WHERE     1 = 1
                                        AND SZTPRONO_NO_REGLA = p_regla
                                        -- and SZTPRONO_FECHA_INICIO = pn_fecha
                                        AND SZTPRONO_PIDM = c.pidm
                                        AND sztprono_materia_legal =
                                               c.materia
                                        AND SZTPRONO_ENVIO_HORARIOS = 'N';
                              -- AND SZTPRONO_PTRM_CODE =parte;


                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                       (   'Se presento un error al insertar en la tabla SZTPRONO 4 '
                                        || SQLERRM);
                              END;


                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_enrl = ssbsect_enrl + 1
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND SSBSECT_CRN = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar el enrolamiento '
                                       || SQLERRM;
                              END;

                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_seats_avail =
                                           ssbsect_seats_avail - 1
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar la disponibilidad del grupo '
                                       || SQLERRM;
                              END;

                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_census_enrl = ssbsect_enrl
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar el Censo del grupo '
                                       || SQLERRM;
                              END;

                              IF C.SGBSTDN_STYP_CODE = 'F'
                              THEN
                                 BEGIN
                                    UPDATE sgbstdn a
                                       SET a.sgbstdn_styp_code = 'N',
                                           a.SGBSTDN_DATA_ORIGIN =
                                              'PRONOSTICO',
                                           A.SGBSTDN_USER_ID = USER
                                     WHERE     1 = 1
                                           AND a.sgbstdn_pidm = c.pidm
                                           AND a.sgbstdn_term_code_eff =
                                                  (SELECT MAX (
                                                             a1.sgbstdn_term_code_eff)
                                                     FROM sgbstdn a1
                                                    WHERE     a1.sgbstdn_pidm =
                                                                 a.sgbstdn_pidm
                                                          AND a1.sgbstdn_program_1 =
                                                                 a.sgbstdn_program_1)
                                           AND a.sgbstdn_program_1 = c.prog;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                          || SQLERRM;
                                 END;
                              END IF;

                              BEGIN
                                 SELECT COUNT (*)
                                   INTO l_cambio_estatus
                                   FROM sfrstcr
                                  WHERE     1 = 1
                                        AND    SFRSTCR_TERM_CODE
                                            || SFRSTCR_PTRM_CODE !=
                                               c.periodo || c.parte
                                        AND sfrstcr_pidm = c.pidm
                                        AND SFRSTCR_STSP_KEY_SEQUENCE =
                                               c.study;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    l_cambio_estatus := 0;
                              END;


                              IF l_cambio_estatus > 0
                              THEN
                                 IF C.SGBSTDN_STYP_CODE IN ('N', 'R')
                                 THEN
                                    BEGIN
                                       UPDATE sgbstdn a
                                          SET a.sgbstdn_styp_code = 'C',
                                              a.SGBSTDN_DATA_ORIGIN =
                                                 'PRONOSTICO',
                                              A.SGBSTDN_USER_ID = USER
                                        WHERE     1 = 1
                                              AND a.sgbstdn_pidm = c.pidm
                                              AND a.sgbstdn_term_code_eff =
                                                     (SELECT MAX (
                                                                a1.sgbstdn_term_code_eff)
                                                        FROM sgbstdn a1
                                                       WHERE     a1.sgbstdn_pidm =
                                                                    a.sgbstdn_pidm
                                                             AND a1.sgbstdn_program_1 =
                                                                    a.sgbstdn_program_1)
                                              AND a.sgbstdn_program_1 =
                                                     c.prog;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                             || SQLERRM;
                                    END;
                                 END IF;
                              END IF;

                              f_inicio := NULL;

                              BEGIN
                                 SELECT DISTINCT sobptrm_start_date
                                   INTO f_inicio
                                   FROM sobptrm
                                  WHERE     sobptrm_term_code = c.periodo
                                        AND sobptrm_ptrm_code = c.parte;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    f_inicio := NULL;
                                    vl_error :=
                                          'Se presento un error al Obtener la fecha de inicio de Clases periodo '
                                       || c.periodo
                                       || ' parte '
                                       || c.parte
                                       || ' '
                                       || SQLERRM
                                       || ' poe';
                              -- raise_application_error (-20002,vl_error);

                              END;

                              IF f_inicio IS NOT NULL
                              THEN
                                 BEGIN
                                    UPDATE sorlcur
                                       SET sorlcur_start_date =
                                              TRUNC (f_inicio),
                                           sorlcur_data_origin = 'PRONOSTICO',
                                           sorlcur_user_id = USER,
                                           SORLCUR_RATE_CODE = c.rate
                                     WHERE     1 = 1
                                           AND sorlcur_pidm = c.pidm
                                           AND sorlcur_program = c.prog
                                           AND sorlcur_lmod_code = 'LEARNER'
                                           AND sorlcur_key_seqno = c.study;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur '
                                          || SQLERRM;
                                 END;
                              END IF;

                              conta_ptrm := 0;

                              BEGIN
                                 SELECT COUNT (*)
                                   INTO conta_ptrm
                                   FROM sfrareg
                                  WHERE     1 = 1
                                        AND sfrareg_pidm = c.pidm
                                        AND sfrareg_term_code = c.periodo
                                        AND sfrareg_crn = crn
                                        AND sfrareg_extension_number = 0
                                        AND sfrareg_rsts_code = p_estatus;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    conta_ptrm := 0;
                              END;

                              IF conta_ptrm = 0
                              THEN
                                 BEGIN
                                    INSERT INTO sfrareg
                                         VALUES (c.pidm,
                                                 c.periodo,
                                                 crn,
                                                 0,
                                                 p_estatus,
                                                 NVL (f_inicio, pn_fecha),
                                                 NVL (f_fin, SYSDATE),
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al insertar el registro de la materia para el alumno '
                                          || SQLERRM;
                                 END;
                              END IF;

                              BEGIN
                                 UPDATE SZTPRONO
                                    SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                  WHERE     1 = 1
                                        AND SZTPRONO_NO_REGLA = p_regla
                                        -- and SZTPRONO_FECHA_INICIO = pn_fecha
                                        AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                        AND sztprono_materia_legal =
                                               c.materia
                                        AND SZTPRONO_PIDM = c.pidm;
                              -- AND SZTPRONO_PTRM_CODE =parte;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar el registro de la materia en SZTPRONO '
                                       || SQLERRM;
                              END;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al insertar al alumno en el grupo3 '
                                    || SQLERRM;
                           END;

                           DBMS_OUTPUT.put_line (
                              'mensaje1:' || 'SE creo el grupo :=' || crn);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              vl_error :=
                                    'Se presento un Error al insertar el nuevo grupo 3 crn '
                                 || crn
                                 || ' error '
                                 || SQLERRM;
                        END;
                     END IF;
                  END IF;                             ------ No hay CRN Creado

                  IF vl_error = 'EXITO'
                  THEN
                     COMMIT;                                         --Commit;

                     --dbms_output.put_line('mensaje:'||vl_error);
                     BEGIN
                        INSERT INTO sztcarga
                             VALUES (c.iden,                      --SZCARGA_ID
                                     c.materia,              --SZCARGA_MATERIA
                                     c.prog,                 --SZCARGA_PROGRAM
                                     c.periodo,            --SZCARGA_TERM_CODE
                                     c.parte,              --SZCARGA_PTRM_CODE
                                     c.grupo,                  --SZCARGA_GRUPO
                                     NULL,                     --SZCARGA_CALIF
                                     c.prof,                 --SZCARGA_ID_PROF
                                     USER,                   --SZCARGA_USER_ID
                                     SYSDATE,          --SZCARGA_ACTIVITY_DATE
                                     c.fecha_inicio,       --SZCARGA_FECHA_INI
                                     'P',                    --SZCARGA_ESTATUS
                                     'Horario Generado', --SZCARGA_OBSERVACIONES
                                     'PRON',
                                     p_regla);
                     EXCEPTION
                        WHEN DUP_VAL_ON_INDEX
                        THEN
                           BEGIN
                              UPDATE sztcarga
                                 SET szcarga_estatus = 'P',
                                     szcarga_observaciones =
                                        'Horario Generado',
                                     szcarga_activity_date = SYSDATE
                               WHERE     1 = 1
                                     AND SZCARGA_ID = c.iden
                                     AND SZCARGA_MATERIA = c.materia
                                     AND SZTCARGA_TIPO_PROC = 'MATE'
                                     AND TRUNC (SZCARGA_FECHA_INI) =
                                            c.fecha_inicio;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 VL_ERROR :=
                                       'Se presento un Error al Actualizar la bitacora '
                                    || SQLERRM;
                           END;
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'Se presento un Error al insertar la bitacora '
                              || SQLERRM;
                     END;
                  ELSE
                     DBMS_OUTPUT.put_line ('mensaje:' || vl_error);

                     ROLLBACK;

                     BEGIN
                        INSERT INTO sztcarga
                             VALUES (c.iden,                      --SZCARGA_ID
                                     c.materia,              --SZCARGA_MATERIA
                                     c.prog,                 --SZCARGA_PROGRAM
                                     c.periodo,            --SZCARGA_TERM_CODE
                                     c.parte,              --SZCARGA_PTRM_CODE
                                     c.grupo,                  --SZCARGA_GRUPO
                                     NULL,                     --SZCARGA_CALIF
                                     c.prof,                 --SZCARGA_ID_PROF
                                     USER,                   --SZCARGA_USER_ID
                                     SYSDATE,          --SZCARGA_ACTIVITY_DATE
                                     c.fecha_inicio,       --SZCARGA_FECHA_INI
                                     'E',                    --SZCARGA_ESTATUS
                                     vl_error,         --SZCARGA_OBSERVACIONES
                                     'PRON',
                                     p_regla);

                        COMMIT;
                     EXCEPTION
                        WHEN DUP_VAL_ON_INDEX
                        THEN
                           BEGIN
                              UPDATE sztcarga
                                 SET szcarga_estatus = 'E',
                                     szcarga_observaciones = vl_error,
                                     szcarga_activity_date = SYSDATE
                               WHERE     1 = 1
                                     AND szcarga_id = c.iden
                                     AND szcarga_materia = c.materia
                                     AND sztcarga_tipo_proc = 'MATE'
                                     AND TRUNC (szcarga_fecha_ini) =
                                            c.fecha_inicio;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un Error al Actualizar la bitacora de Error '
                                    || SQLERRM;
                           END;
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'Se presento un Error al insertar la bitacora de Error '
                              || SQLERRM;
                     END;
                  END IF;
               ELSE
                  vl_error :=
                        'El alumno ya tiene la materia Inscritas en el Periodo:'
                     || period_cur
                     || '. Parte-periodo:'
                     || parteper_cur;

                  BEGIN
                     UPDATE sztprono
                        SET --SZTPRONO_ESTATUS_ERROR ='S',
                            SZTPRONO_DESCRIPCION_ERROR = vl_error
                      --SZTPRONO_ENVIO_HORARIOS ='S'

                      WHERE     1 = 1
                            AND SZTPRONO_MATERIA_LEGAL = c.materia
                            --AND TRUNC (SZTPRONO_FECHA_INICIO) = c.fecha_inicio
                            AND SZTPRONO_NO_REGLA = P_REGLA
                            AND SZTPRONO_pIDm = c.pidm;
                  --AND SZTPRONO_PTRM_CODE =parte;

                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        DBMS_OUTPUT.put_line (
                           ' Error al actualizar ' || SQLERRM);
                  END;

                  --l_retorna_dsi:=PKG_FINANZAS_REZA.F_ACTUALIZA_RATE_DSI ( c.iden, c.fecha_inicio );

                  COMMIT;

                  -- raise_application_error (-20002,vl_error);

                  BEGIN
                     INSERT INTO sztcarga
                          VALUES (c.iden,                         --SZCARGA_ID
                                  c.materia,                 --SZCARGA_MATERIA
                                  c.prog,                    --SZCARGA_PROGRAM
                                  c.periodo,               --SZCARGA_TERM_CODE
                                  c.parte,                 --SZCARGA_PTRM_CODE
                                  c.grupo,                     --SZCARGA_GRUPO
                                  NULL,                        --SZCARGA_CALIF
                                  c.prof,                    --SZCARGA_ID_PROF
                                  USER,                      --SZCARGA_USER_ID
                                  SYSDATE,             --SZCARGA_ACTIVITY_DATE
                                  c.fecha_inicio,          --SZCARGA_FECHA_INI
                                  'A',                --'P', --SZCARGA_ESTATUS
                                  vl_error,            --SZCARGA_OBSERVACIONES
                                  'PRON',
                                  p_regla);

                     COMMIT;
                  EXCEPTION
                     WHEN DUP_VAL_ON_INDEX
                     THEN
                        BEGIN
                           UPDATE sztcarga
                              SET szcarga_estatus = 'A',               --'P' ,
                                  szcarga_observaciones = vl_error,
                                  szcarga_activity_date = SYSDATE
                            WHERE     1 = 1
                                  AND szcarga_id = c.iden
                                  AND szcarga_materia = c.materia
                                  AND sztcarga_tipo_proc = 'MATE'
                                  AND TRUNC (szcarga_fecha_ini) =
                                         c.fecha_inicio;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              vl_error :=
                                    'Se presento un Error al Actualizar la bitacora de Error '
                                 || SQLERRM;
                        END;
                     WHEN OTHERS
                     THEN
                        vl_error :=
                              'Se presento un Error al insertar la bitacora de Error '
                           || SQLERRM;
                  END;
               END IF;            ----> El alumno ya tiene inscrita la materia
            ELSE
               BEGIN
                  SELECT DECODE (c.sgbstdn_stst_code,
                                 'BT', 'BAJA TEMPORAL',
                                 'BD', 'BAJA TEMPORAL',
                                 'BI', 'BAJA POR INACTIVIDAD',
                                 'CV', 'CANCELACI? DE VENTA',
                                 'CM', 'CANCELACI? DE MATR?ULA',
                                 'CC', 'CAMBIO DE CILO',
                                 'CF', 'CAMBIO DE FECHA',
                                 'CP', 'CAMBIO DE PROGRAMA',
                                 'EG', 'EGRESADO')
                    INTO L_DESCRIPCION_ERROR
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_descripcion_error := 'Sin descripcion';
               END;

               IF L_DESCRIPCION_ERROR IS NULL
               THEN
                  L_DESCRIPCION_ERROR := c.sgbstdn_stst_code;
               END IF;


               BEGIN
                  UPDATE sztprono
                     SET SZTPRONO_ESTATUS_ERROR = 'S',
                         SZTPRONO_DESCRIPCION_ERROR = L_DESCRIPCION_ERROR
                   WHERE     1 = 1
                         AND SZTPRONO_MATERIA_LEGAL = c.materia
                         --AND TRUNC (SZTPRONO_FECHA_INICIO) = c.fecha_inicio
                         AND SZTPRONO_NO_REGLA = P_REGLA
                         AND SZTPRONO_PIDM = c.pidm;
               --AND SZTPRONO_PTRM_CODE =parte;

               EXCEPTION
                  WHEN OTHERS
                  THEN
                     DBMS_OUTPUT.put_line (
                        ' Error al actualizar ' || SQLERRM);
               END;


               vl_error :=
                     'Estatus no v?do para realizar la carga: '
                  || C.SGBSTDN_STST_CODE;

               BEGIN
                  INSERT INTO sztcarga
                       VALUES (c.iden,                            --SZCARGA_ID
                               c.materia,                    --SZCARGA_MATERIA
                               c.prog,                       --SZCARGA_PROGRAM
                               c.periodo,                  --SZCARGA_TERM_CODE
                               c.parte,                    --SZCARGA_PTRM_CODE
                               c.grupo,                        --SZCARGA_GRUPO
                               NULL,                           --SZCARGA_CALIF
                               c.prof,                       --SZCARGA_ID_PROF
                               USER,                         --SZCARGA_USER_ID
                               SYSDATE,                --SZCARGA_ACTIVITY_DATE
                               c.fecha_inicio,             --SZCARGA_FECHA_INI
                               'A',                   --'P', --SZCARGA_ESTATUS
                               vl_error,               --SZCARGA_OBSERVACIONES
                               'PRON',
                               p_regla);

                  COMMIT;
               EXCEPTION
                  WHEN DUP_VAL_ON_INDEX
                  THEN
                     BEGIN
                        UPDATE sztcarga
                           SET szcarga_estatus = 'A',                  --'P' ,
                               szcarga_observaciones = vl_error,
                               szcarga_activity_date = SYSDATE
                         WHERE     1 = 1
                               AND szcarga_id = c.iden
                               AND szcarga_materia = c.materia
                               AND sztcarga_tipo_proc = 'MATE'
                               AND TRUNC (szcarga_fecha_ini) = c.fecha_inicio;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'Se presento un Error al Actualizar la bitacora de Error '
                              || SQLERRM;
                     END;
                  WHEN OTHERS
                  THEN
                     vl_error :=
                           'Se presento un Error al insertar la bitacora de Error '
                        || SQLERRM;
               END;

               raise_application_error (
                  -20002,
                     'Este alumno '
                  || c.iden
                  || ' se encuentra con '
                  || l_descripcion_error);
            END IF;

            --end if;

            l_numero_contador := 1;    --Jpg@Modify valida si entra a procesar
         END LOOP;

         COMMIT;

         IF l_numero_contador = 0
         THEN --Jpg@Modify en el caso de no procesar validamos algun error en area de concetración.
            p_check_area (p_regla, p_pidm, p_materia_legal);
         END IF;



         --raise_application_error (-20002,vl_error);
         ------------------- Realiza el proceso de actualizacion de Jornadas ----------------------------------

         BEGIN
            FOR c
               IN (  SELECT sorlcur_levl_code nivel,
                            szcarga_id,
                            szcarga_term_code,
                            szcarga_ptrm_code,
                            spriden_pidm,
                            sorlcur_key_seqno,
                            COUNT (*) numero
                       FROM sztcarga, spriden, sorlcur s
                      WHERE     1 = 1
                            AND sztcarga_tipo_proc = 'MATE'
                            AND szcarga_estatus != 'E'
                            AND szcarga_id = spriden_id
                            AND spriden_change_ind IS NULL
                            AND s.sorlcur_pidm = spriden_pidm
                            AND s.sorlcur_pidm = p_pidm
                            AND s.sorlcur_program = szcarga_program
                            AND s.sorlcur_lmod_code = 'LEARNER'
                            AND s.sorlcur_seqno IN (SELECT MAX (
                                                              ss.sorlcur_seqno)
                                                      FROM sorlcur ss
                                                     WHERE     1 = 1
                                                           AND s.sorlcur_pidm =
                                                                  ss.sorlcur_pidm
                                                           AND s.sorlcur_lmod_code =
                                                                  ss.sorlcur_lmod_code
                                                           AND s.sorlcur_program =
                                                                  ss.sorlcur_program)
                   GROUP BY sorlcur_levl_code,
                            szcarga_id,
                            szcarga_term_code,
                            szcarga_ptrm_code,
                            spriden_pidm,
                            sorlcur_key_seqno
                   ORDER BY 1, 2, 3)
            LOOP
               vl_jornada := NULL;



               BEGIN
                  SELECT DISTINCT SUBSTR (sgrsatt_atts_code, 1, 3) jornada
                    INTO vl_jornada
                    FROM sgrsatt a
                   WHERE     1 = 1
                         AND a.sgrsatt_pidm = c.spriden_pidm
                         AND a.sgrsatt_stsp_key_sequence =
                                c.sorlcur_key_seqno
                         AND SUBSTR (a.sgrsatt_atts_code, 2, 1) =
                                SUBSTR (c.nivel, 1, 1)
                         AND REGEXP_LIKE (a.sgrsatt_atts_code, '^[0-9]')
                         AND a.sgrsatt_term_code_eff =
                                (SELECT MAX (a1.sgrsatt_term_code_eff)
                                   FROM SGRSATT a1
                                  WHERE     1 = 1
                                        AND a.sgrsatt_pidm = a1.sgrsatt_pidm
                                        AND a.sgrsatt_stsp_key_sequence =
                                               a1.sgrsatt_stsp_key_sequence);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vl_jornada := NULL;
               END;

               IF vl_jornada IS NOT NULL
               THEN
                  IF c.numero >= 10
                  THEN
                     c.numero := 4;
                  END IF;

                  vl_jornada := vl_jornada || c.numero;

                  BEGIN
                     pkg_algoritmo.p_actualiza_jornada (c.spriden_pidm,
                                                        c.szcarga_term_code,
                                                        vl_jornada,
                                                        c.sorlcur_key_seqno);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  END;
               END IF;
            END LOOP;

            COMMIT;
         END;
      ELSE
         vl_error :=
            'Esta Materia presenta Errores No se puede crear el Horario conserva el grupo 00... validar el Error en el Pronostico ';
      END IF;



      COMMIT;

      p_error := vl_error;
   END;


   PROCEDURE p_inserta_carga_pidm (p_regla     NUMBER,
                                   pn_fecha    VARCHAR2,
                                   pn_pidm     NUMBER)
   IS
      l_prof_id        VARCHAR2 (100);
      l_alumno_id      VARCHAR2 (9);
      l_cuenta_grupo   NUMBER;
      l_cuenta_prof    NUMBER;
      l_contar_ec      NUMBER;
   BEGIN
      -- raise_application_error (-20002,'Entra a inserta carga');

--      BEGIN
--         SELECT COUNT (*)
--           INTO l_contar_ec
--           FROM sztalgo
--          WHERE     1 = 1
--                AND SZTALGO_LEVL_CODE = 'EC'
--                AND sztalgo_no_regla = p_regla;
--      EXCEPTION
--         WHEN OTHERS
--         THEN
--            NULL;
--      END;

      BEGIN
         SELECT spriden_id
           INTO l_alumno_id
           FROM spriden
          WHERE spriden_pidm = pn_pidm
          AND spriden_change_ind IS NULL;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_alumno_id := 0;
      END;


      BEGIN
         DELETE SZCARGA
          WHERE     1 = 1
                AND SZCARGA_NO_REGLA = p_regla
                AND SZCARGA_FECHA_INI =pn_fecha
                AND SZCARGA_ID = l_alumno_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

--      BEGIN
--         DELETE SZTCARGA
--          WHERE     1 = 1
--                AND SZTCARGA_NO_REGLA = p_regla
--                AND SZCARGA_FECHA_INI = pn_fecha
--                AND SZCARGA_ID = l_alumno_id;
--      EXCEPTION
--         WHEN OTHERS
--         THEN
--            NULL;
--      END;


--      IF l_contar_ec = 0 THEN
--         -- si ya tiene las materias sembradas se actualiza antes para que no se tomen en cuenta en el proceso
--
--         FOR c_prono
--            IN (SELECT id_alumno,
--                       pidm_alumno,
--                       periodo,
--                       programa,
--                       parte_periodo,
--                       mat_prono,
--                       longitud,
--                       grupo2,
--                       SUBSTR (grupo2, longitud, 2) grupo,
--                       fecha_inicio,
--                       regla,
--                       banner
--                  FROM (SELECT DISTINCT
--                               ono.sztprono_id id_alumno,
--                               ono.sztprono_pidm pidm_alumno,
--                               ono.SZTPRONO_TERM_CODE periodo,
--                               SZTPRONO_PROGRAM programa,
--                               ono.SZTPRONO_PTRM_CODE parte_periodo,
--                               ono.SZTPRONO_MATERIA_LEGAL mat_prono,
--                               LENGTH (SZSTUME_SUBJ_CODE) + 1 longitud,
--                               ume.SZSTUME_TERM_NRC grupo2,
--                               SZTPRONO_FECHA_INICIO fecha_inicio,
--                               sztprono_no_regla regla,
--                               SZTPRONO_MATERIA_BANNER banner
--                          FROM SZSTUME ume, sztprono ono
--                         WHERE     1 = 1
--                               AND ono.sztprono_no_regla =
--                                      ume.SZSTUME_NO_REGLA(+)
--                               AND ono.sztprono_pidm = ume.SZSTUME_pidm(+)
--                               AND ono.SZTPRONO_MATERIA_LEGAL =
--                                      ume.SZSTUME_SUBJ_CODE(+)
--                               AND ono.SZTPRONO_ENVIO_HORARIOS = 'N'
--                               AND ono.SZTPRONO_ENVIO_MOODL = 'S'
--                               AND ono.sztprono_id = l_alumno_id
--                               AND ono.sztprono_no_regla = p_regla
--                               AND SZTPRONO_ESTATUS_ERROR = 'N'
--                               AND ume.szstume_stat_ind = '1'
--                               AND ume.SZSTUME_SEQ_NO =
--                                      (SELECT MAX (a1.SZSTUME_SEQ_NO)
--                                         FROM SZSTUME a1
--                                        WHERE     ume.SZSTUME_PIDM =
--                                                     a1.SZSTUME_PIDM
--                                              AND ume.SZSTUME_STAT_IND =
--                                                     a1.SZSTUME_STAT_IND
--                                              AND ume.SZSTUME_NO_REGLA =
--                                                     a1.SZSTUME_NO_REGLA
--                                              AND ume.SZSTUME_SUBJ_CODE =
--                                                     a1.SZSTUME_SUBJ_CODE)))
--         LOOP
--            DBMS_OUTPUT.put_line ('Entra a carga');
--
--            BEGIN
--               SELECT (SELECT SPRIDEN_ID
--                         FROM SPRIDEN
--                        WHERE     1 = 1
--                              AND SPRIDEN_PIDM = nme.SZSGNME_PIDM
--                              AND SPRIDEN_CHANGE_IND IS NULL)
--                         MATRICULA
--                 INTO l_prof_id
--                 FROM SZSGNME nme
--                WHERE     1 = 1
--                      AND SZSGNME_no_regla = c_prono.regla
--                      AND SZSGNME_TERM_NRC = c_prono.grupo2
--                      AND ROWNUM = 1;
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  NULL;
--            END;
--
--            BEGIN
--               SELECT COUNT (*)
--                 INTO l_cuenta_grupo
--                 FROM sztgpme
--                WHERE     1 = 1
--                      AND SZTGPME_NO_REGLA = c_prono.regla
--                      AND SZTGPME_TERM_NRC = c_prono.GRUPO2
--                      AND SZTGPME_STAT_IND = '1';
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  l_cuenta_grupo := 0;
--            END;
--
--            BEGIN
--               SELECT COUNT (*)
--                 INTO l_cuenta_prof
--                 FROM SZSGNME
--                WHERE     1 = 1
--                      AND SZSGNME_NO_REGLA = c_prono.regla
--                      AND SZSGNME_TERM_NRC = c_prono.GRUPO2
--                      AND SZSGNME_STAT_IND = '1';
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  l_cuenta_prof := 0;
--            END;
--
--            -- para validar que esten sincronizados
--
--            DBMS_OUTPUT.put_line (
--                  'Cuenta Grupo '
--               || l_cuenta_grupo
--               || ' Cuenta Prof '
--               || l_cuenta_prof);
--
--            IF l_cuenta_grupo > 0 AND l_cuenta_prof > 0
--            THEN
--               BEGIN
--                  INSERT INTO SZCARGA
--                       VALUES (c_prono.id_alumno,
--                               c_prono.mat_prono,
--                               c_prono.programa,
--                               c_prono.periodo,
--                               c_prono.parte_periodo,
--                               c_prono.grupo,
--                               NULL,
--                               l_prof_id,
--                               USER,
--                               SYSDATE,
--                               c_prono.fecha_inicio,
--                               P_REGLA,
--                               c_prono.banner);
--               EXCEPTION
--                  WHEN OTHERS
--                  THEN
--                     --raise_application_error (-20002,'ERROR al insertar en carga matricula '||c_prono.id_alumno||' error '||sqlerrm);
--                     NULL;
--               END;
--            END IF;
--         END LOOP;
--
--      ELSE
         -- para educaci??ontinua para la inscripci??o es necesario que el alumno se encuentre en aula

         -- raise_application_error (-20002,'Entra a Ec');

       FOR c_prono IN (
            SELECT id_alumno,
                       pidm_alumno,
                       periodo,
                       programa,
                       parte_periodo,
                       mat_prono,
                       longitud,
                       grupo2,
                       SUBSTR (grupo2, longitud, 2) grupo,
                       fecha_inicio,
                       regla,
                       banner
                  FROM (SELECT DISTINCT
                               ono.sztprono_id id_alumno,
                               ono.sztprono_pidm pidm_alumno,
                               ono.SZTPRONO_TERM_CODE periodo,
                               SZTPRONO_PROGRAM programa,
                               ono.SZTPRONO_PTRM_CODE parte_periodo,
                               ono.SZTPRONO_MATERIA_LEGAL mat_prono,
                               LENGTH (SZSTUME_SUBJ_CODE) + 1 longitud,
                               ume.SZSTUME_TERM_NRC grupo2,
                               SZTPRONO_FECHA_INICIO fecha_inicio,
                               sztprono_no_regla regla,
                               SZTPRONO_MATERIA_BANNER banner
                          FROM SZSTUME ume, sztprono ono
                         WHERE     1 = 1
                               AND ono.sztprono_no_regla =ume.SZSTUME_NO_REGLA(+)
                               AND ono.sztprono_pidm = ume.SZSTUME_pidm(+)
                               AND ono.SZTPRONO_MATERIA_LEGAL =ume.SZSTUME_SUBJ_CODE(+)
                               AND ono.SZTPRONO_ENVIO_HORARIOS = 'N'
                               AND ono.SZTPRONO_ENVIO_MOODL = 'S'
                               AND ono.sztprono_id =l_alumno_id
                               AND ono.sztprono_no_regla =p_regla
                               AND SZTPRONO_ESTATUS_ERROR = 'N'
                               AND ume.szstume_stat_ind = '1'
                               AND ume.szstume_start_date=pn_fecha
                               AND ume.SZSTUME_SEQ_NO =(SELECT MAX (a1.SZSTUME_SEQ_NO)
                                                         FROM SZSTUME a1
                                                        WHERE     ume.SZSTUME_PIDM =a1.SZSTUME_PIDM
                                                              AND ume.SZSTUME_STAT_IND =a1.SZSTUME_STAT_IND
                                                              AND ume.SZSTUME_NO_REGLA =a1.SZSTUME_NO_REGLA
                                                              AND ume.SZSTUME_SUBJ_CODE =a1.SZSTUME_SUBJ_CODE))
                                                     )
         LOOP
            -- raise_application_error (-20002,'entra a ec');

            BEGIN
               SELECT (SELECT SPRIDEN_ID
                         FROM SPRIDEN
                        WHERE     1 = 1
                              AND SPRIDEN_PIDM = nme.SZSGNME_PIDM
                              AND SPRIDEN_CHANGE_IND IS NULL)
                         MATRICULA
                 INTO l_prof_id
                 FROM SZSGNME nme
                WHERE     1 = 1
                      AND SZSGNME_no_regla = c_prono.regla
                      AND SZSGNME_TERM_NRC = c_prono.grupo2
                      AND ROWNUM = 1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

            --
            -- begin
            --
            -- select count(*)
            -- into l_cuenta_grupo
            -- from sztgpme
            -- where 1 = 1
            -- and SZTGPME_NO_REGLA = c_prono.regla
            -- and SZTGPME_TERM_NRC = c_prono.GRUPO2
            -- and SZTGPME_STAT_IND ='1';
            --
            --
            -- exception when others then
            -- l_cuenta_grupo:=0;
            -- end;

            -- begin
            --
            -- select count(*)
            -- into l_cuenta_prof
            -- from SZSGNME
            -- where 1 = 1
            -- and SZSGNME_NO_REGLA = c_prono.regla
            -- and SZSGNME_TERM_NRC = c_prono.GRUPO2
            -- and SZSGNME_STAT_IND ='1';
            --
            --
            -- exception when others then
            -- l_cuenta_prof:=0;
            -- end;

            -- para validar que esten sincronizados

            DBMS_OUTPUT.put_line ('Entra a ec');

            -- if l_cuenta_grupo > 0 and l_cuenta_prof > 0 then

            BEGIN
               INSERT INTO SZCARGA
                    VALUES (c_prono.id_alumno,
                            c_prono.mat_prono,
                            c_prono.programa,
                            c_prono.periodo,
                            c_prono.parte_periodo,
                            c_prono.grupo,
                            NULL,
                            l_prof_id,
                            USER,
                            SYSDATE,
                            c_prono.fecha_inicio,
                            P_REGLA,
                            c_prono.banner);
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_application_error (
                     -20002,
                        'ERROR al insertar en carga matricula '
                     || c_prono.id_alumno
                     || ' error '
                     || SQLERRM);
            --null;
            END;
         -- end if;

         END LOOP;

--      END IF;

      COMMIT;
   END P_INSERTA_CARGA_PIDM;

   --

   PROCEDURE p_inscr_individual_XX (pn_fecha              VARCHAR2,
                                    p_regla               NUMBER,
                                    p_materia_legal       VARCHAR2,
                                    p_pidm                NUMBER,
                                    p_estatus             VARCHAR2,
                                    p_secuencia           NUMBER,
                                    p_error           OUT VARCHAR2)
   IS
      crn                    VARCHAR2 (20);
      gpo                    NUMBER;
      mate                   VARCHAR2 (20);
      ciclo                  VARCHAR2 (6);
      subj                   VARCHAR2 (4);
      crse                   VARCHAR2 (5);
      sb                     VARCHAR2 (4);
      cr                     VARCHAR2 (5);
      schd                   VARCHAR2 (3);
      title                  VARCHAR2 (30);
      credit                 DECIMAL (7, 3);
      credit_bill            DECIMAL (7, 3);
      gmod                   VARCHAR2 (1);
      f_inicio               DATE;
      f_fin                  DATE;
      sem                    NUMBER;
      conta_ptrm             NUMBER;
      conta_blck             NUMBER;
      pidm                   NUMBER;
      pidm_doc               NUMBER;
      pidm_doc2              NUMBER;
      ests                   VARCHAR2 (2);
      levl                   VARCHAR2 (2);
      camp                   VARCHAR2 (3);
      rsts                   VARCHAR2 (3);
      conta_origen           NUMBER := 0;
      conta_destino          NUMBER := 0;
      conta_origen_ssbsect   NUMBER := 0;
      conta_origen_ssrblck   NUMBER := 0;
      conta_origen_sobptrm   NUMBER := 0;
      sp                     INTEGER;
      ciclo_ext              VARCHAR2 (6);
      mensaje                VARCHAR2 (200);
      parte                  VARCHAR2 (3);
      pidm_prof              NUMBER;
      per                    VARCHAR2 (6);
      grupo                  VARCHAR2 (4);
      conta_sirasgn          NUMBER;
      fecha_ini              DATE;
      vl_existe              NUMBER := 0;

      vn_lugares             NUMBER := 0;
      vn_cupo_max            NUMBER := 0;
      vn_cupo_act            NUMBER := 0;
      vl_error               VARCHAR2 (2500) := 'EXITO';

      parteper_cur           VARCHAR2 (3);
      period_cur             VARCHAR2 (10);
      vl_jornada             VARCHAR2 (250) := NULL;
      vl_exite_prof          NUMBER := 0;
      l_contar               NUMBER := 0;
      l_maximo_alumnos       NUMBER;
      l_numero_contador      NUMBER;
      l_valida_order         NUMBER;
      L_DESCRIPCION_ERROR    VARCHAR2 (250) := NULL;
      l_valida               NUMBER;



      l_cuneta_prono         NUMBER;
      l_term_code            VARCHAR2 (10);
      l_ptrm                 VARCHAR2 (10);
      vl_orden               VARCHAR2 (10);
      l_cuenta_ni            NUMBER;



      l_cambio_estatus       NUMBER;
      l_type                 VARCHAR2 (20);
      l_pperiodo_ni          VARCHAR2 (20);
      l_matricula            VARCHAR2 (9) := NULL;
      l_campus_ms            VARCHAR2 (20);
      l_retorna_dsi          VARCHAR2 (250);
   BEGIN
      BEGIN
         SELECT DISTINCT spriden_id
           INTO l_matricula
           FROM spriden
          WHERE spriden_pidm = p_pidm AND spriden_change_ind IS NULL;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;


      -- raise_application_error (-20002,'Error al '||sqlerrm);



      BEGIN
         P_INSERTA_CARGA_PIDM (p_regla, pn_fecha, p_pidm);
      EXCEPTION
         WHEN OTHERS
         THEN
            -- raise_application_error (-20002,'ERROR al insertar en carga '||sqlerrm);
            NULL;
      END;

      DBMS_OUTPUT.PUT_LINE ('pasa la carga ');

      BEGIN
         SELECT COUNT (*)
           INTO l_contar
           FROM SZCARGA
          WHERE     1 = 1
                AND SZCARGA_ID = l_matricula
                AND SZCARGA_NO_REGLA = p_regla;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      IF l_contar > 0
      THEN
         fecha_ini := TO_DATE (pn_fecha, 'DD/MM/RRRR');

         --DBMS_OUTPUT.PUT_LINE('antes cursor');

         FOR c
            IN (  SELECT DISTINCT
                         spriden_pidm pidm,
                         szcarga_id iden,
                         szcarga_program prog,
                         sorlcur_camp_code campus,
                         sorlcur_levl_code nivel,
                         sorlcur_term_code_ctlg ctlg,
                         szcarga_materia materia,
                         smrarul_subj_code subj,
                         smrarul_crse_numb_low crse,
                         szcarga_term_code periodo,
                         szcarga_ptrm_code parte,
                         DECODE (sztdtec_periodicidad,
                                 1, 'BIMESTRAL',
                                 2, 'CUATRIMESTRAL')
                            periodicidad,
                         NVL (szcarga_grupo, '01') grupo,
                         --szcarga_grupo grupo,
                         szcarga_calif calif,
                         szcarga_id_prof prof,
                         szcarga_fecha_ini fecha_inicio,
                         sorlcur_key_seqno study,
                         d.sgbstdn_stst_code,
                         d.sgbstdn_styp_code,
                         SGBSTDN_RATE_CODE rate
                    FROM szcarga a
                         JOIN spriden ON spriden_id = szcarga_id
                               AND spriden_change_ind IS NULL
                         JOIN sgbstdn d ON d.sgbstdn_pidm = spriden_pidm
                               AND d.sgbstdn_term_code_eff =(SELECT MAX (b1.sgbstdn_term_code_eff)
                                                                 FROM sgbstdn b1
                                                                  WHERE     1 = 1
                                                                  AND d.sgbstdn_pidm =b1.sgbstdn_pidm
                                                                  AND d.sgbstdn_program_1 =b1.sgbstdn_program_1)
                         JOIN sorlcur s ON sorlcur_pidm = spriden_pidm
                               AND s.sorlcur_pidm = d.sgbstdn_pidm
                               AND s.sorlcur_program = d.sgbstdn_program_1
                               AND sorlcur_program = szcarga_program
                               AND sorlcur_lmod_code = 'LEARNER'
                               AND sorlcur_seqno IN (SELECT MAX (sorlcur_seqno)
                                                       FROM sorlcur ss
                                                       WHERE 1 = 1
                                                       AND s.sorlcur_pidm =ss.sorlcur_pidm
                                                       AND s.sorlcur_lmod_code =ss.sorlcur_lmod_code
                                                       AND s.sorlcur_program =ss.sorlcur_program)
                         JOIN sztdtec ON sztdtec_program = sorlcur_program
                               AND sztdtec_term_code = sorlcur_term_code_ctlg
                         JOIN smrpaap ON smrpaap_program = sorlcur_program
                               AND smrpaap_term_code_eff =sorlcur_term_code_ctlg
                         JOIN sztmaco ON SZTMACO_MATPADRE = szcarga_materia
                         JOIN smrarul ON smrarul_area = smrpaap_area
                               AND SMRARUL_TERM_CODE_EFF =sorlcur_term_code_ctlg
                               AND smrarul_subj_code || smrarul_crse_numb_low =sztmaco_mathijo
                         WHERE 1 = 1
                         AND smrarul_subj_code || smrarul_crse_numb_low =sztmaco_mathijo
                         AND szcarga_no_regla = p_regla
                         AND sorlcur_pidm = p_pidm
                         AND SZCARGA_MATERIA = p_materia_legal
                ORDER BY iden, 10)
         LOOP
            -- DBMS_OUTPUT.PUT_LINE('Entra a cursor normal ');

            --------------- Limpia Variables --------------------
            --niv := null;
            parte := NULL;
            crn := NULL;
            pidm_doc2 := NULL;
            conta_sirasgn := NULL;
            pidm_doc := NULL;
            f_inicio := NULL;
            f_fin := NULL;
            sem := NULL;
            schd := NULL;
            title := NULL;
            credit := NULL;
            credit_bill := NULL;
            levl := NULL;
            camp := NULL;
            mate := NULL;
            parte := NULL;
            per := NULL;
            -- grupo := NULL;
            vl_existe := 0;
            vl_error := 'EXITO';
            vn_lugares := 0;
            vn_cupo_max := 0;
            vn_cupo_act := 0;

            parteper_cur := NULL;
            period_cur := NULL;
            vl_exite_prof := 0;


            BEGIN
               SELECT DISTINCT TO_NUMBER (SFRSTCR_VPDI_CODE)
                 INTO VL_ORDEN
                 FROM SFRSTCR
                WHERE     SFRSTCR_PIDM = C.PIDM
                      AND SFRSTCR_TERM_CODE = C.PERIODO
                      AND SFRSTCR_PTRM_CODE = C.PARTE
                      AND SFRSTCR_RSTS_CODE = 'RE'
                      AND SFRSTCR_VPDI_CODE IS NOT NULL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  BEGIN
                     SELECT TBRACCD_RECEIPT_NUMBER
                       INTO VL_ORDEN
                       FROM TBRACCD A
                      WHERE     A.TBRACCD_PIDM = C.PIDM
                            AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                            FROM TBBDETC
                                                           WHERE TBBDETC_DCAT_CODE = 'COL'
                                                           AND TBBDETC_DESC LIKE 'COLEGIATURA %'
                                                           AND TBBDETC_DESC !='COLEGIATURA LIC NOTA'
                                                           AND TBBDETC_DESC !='COLEGIATURA EXTRAORDINARIO')
                            AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                            AND A.TBRACCD_TRAN_NUMBER =(SELECT MAX (TBRACCD_TRAN_NUMBER)
                                      FROM TBRACCD A1
                                     WHERE A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                                           AND A1.TBRACCD_TERM_CODE =A.TBRACCD_TERM_CODE
                                           AND A1.TBRACCD_PERIOD =A.TBRACCD_PERIOD
                                           AND A1.TBRACCD_DETAIL_CODE = A.TBRACCD_DETAIL_CODE
                                           AND LAST_DAY ( TBRACCD_EFFECTIVE_DATE) =LAST_DAY (TO_DATE ( C.fecha_inicio)+ 12)
                                           AND A1.TBRACCD_DOCUMENT_NUMBER IS NULL
                                           AND A1.TBRACCD_STSP_KEY_SEQUENCE =c.study);
                  EXCEPTION WHEN OTHERS THEN

                        DBMS_OUTPUT.put_line ('No se encontro 4 ' || SQLERRM);

                         BEGIN
                            SELECT MAX(TZTORDR_CONTADOR)+1
                              INTO VL_ORDEN
                              FROM TZTORDR;
                          EXCEPTION
                          WHEN OTHERS THEN
                                dbms_output.put_line('Error al recuperar orden ' ||sqlerrm);
                         END;

                         BEGIN
                              INSERT INTO TZTORDR values (c.campus,
                                                          c.nivel,
                                                           VL_ORDEN,
                                                           c.prog,
                                                           c.pidm,
                                                           c.iden,
                                                           'S',
                                                           sysdate,
                                                           user,
                                                           'MANUAL',
                                                           null,
                                                           null,
                                                           null,
                                                           null,
                                                           null,
                                                           null);

                         Exception When Others then
                                      dbms_output.put_line('Error al insertar orden ' ||sqlerrm);
                         End;
                  END;
            END;

            IF C.SGBSTDN_STST_CODE IN ('AS', 'PR', 'MA')
            THEN
               ----------------- Se valida que el alumno no tenga la materia sembrada en el horario como Activa ---------------------------------------

               --DBMS_OUTPUT.PUT_LINE('Entra a cursor normal ');

               BEGIN
                    --existe y es aprobatoria
                    SELECT COUNT (1), sfrstcr_term_code, sfrstcr_ptrm_code
                      INTO vl_existe, period_cur, parteper_cur
                      FROM ssbsect, sfrstcr, shrgrde
                     WHERE     1 = 1
                           AND sfrstcr_pidm = c.pidm
                           AND ssbsect_term_code = sfrstcr_term_code
                           AND sfrstcr_ptrm_code = ssbsect_ptrm_code
                           AND ssbsect_crn = sfrstcr_crn
                           AND ssbsect_subj_code = c.subj
                           AND ssbsect_crse_numb = c.crse
                           AND sfrstcr_rsts_code = 'RE'
                           AND (   sfrstcr_grde_code = shrgrde_code
                                OR sfrstcr_grde_code IS NULL)
                           AND SUBSTR (sfrstcr_term_code, 5, 1) NOT IN ('8',
                                                                        '9')
                           AND shrgrde_passed_ind = 'Y'
                           AND shrgrde_levl_code = c.nivel
                           /* cambio escalas para prod */
                           AND shrgrde_term_code_effective =
                                  (SELECT zstpara_param_desc
                                     FROM zstpara
                                    WHERE     zstpara_mapa_id = 'ESC_SHAGRD'
                                          AND SUBSTR (
                                                 (SELECT f_getspridenid (
                                                            p_pidm)
                                                    FROM DUAL),
                                                 1,
                                                 2) = zstpara_param_id
                                          AND zstpara_param_valor = c.nivel)
                  /* cambio escalas para prod */
                  GROUP BY sfrstcr_term_code, sfrstcr_ptrm_code;
               --DBMS_OUTPUT.PUT_LINE('Entrando aqui '||vl_existe||' PIDM '||c.pidm ||' SUBJ '||c.subj ||' crse '||c.crse );

               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vl_existe := 0;
                     DBMS_OUTPUT.PUT_LINE ('Error ' || SQLERRM);
               END;

               IF vl_existe IS NULL
               THEN
                  vl_existe := 0;
               END IF;

               DBMS_OUTPUT.PUT_LINE ('Entra a existe ' || vl_existe);

               IF vl_existe = 0
               THEN
                  ---- Se busca que exista el grupo y tenga cupo

                  DBMS_OUTPUT.put_line ('sin profesor ' || vl_existe);

                  BEGIN
                     SELECT ct.ssbsect_crn,
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
                       INTO crn,
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
                            AND ct.ssbsect_term_code = c.periodo
                            AND ct.ssbsect_subj_code = c.subj
                            AND ct.ssbsect_crse_numb = c.crse
                            AND ct.ssbsect_seq_numb = c.grupo
                            AND ct.ssbsect_ptrm_code = c.parte
                            AND TRUNC (ct.ssbsect_ptrm_start_date) = c.Fecha_Inicio
                            AND SSBSECT_CAMP_CODE = c.campus
                            AND ct.ssbsect_seats_avail > 0
                            AND ct.ssbsect_seats_avail IN (SELECT MAX (
                                                                     a1.ssbsect_seats_avail)
                                                             FROM ssbsect a1
                                                            WHERE a1.ssbsect_term_code =ct.ssbsect_term_code
                                                                  AND a1.ssbsect_seq_numb =ct.ssbsect_seq_numb
                                                                  AND a1.ssbsect_subj_code = ct.ssbsect_subj_code
                                                                  AND a1.ssbsect_crse_numb =ct.ssbsect_crse_numb
                                                                  AND TRUNC (a1.ssbsect_ptrm_start_date) =TRUNC (ct.ssbsect_ptrm_start_date));

                     DBMS_OUTPUT.PUT_LINE ('Entra 4');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        crn := NULL;
                        vn_lugares := 0;
                        vn_cupo_max := 0;
                        vn_cupo_act := 0;
                        f_inicio := NULL;
                        f_fin := NULL;
                        sem := NULL;
                        credit := NULL;
                        credit_bill := NULL;
                        gmod := NULL;
                  END;

                  IF crn IS NOT NULL
                  THEN
                     DBMS_OUTPUT.put_line ('CRN no es null gx ' || crn);

                     IF vn_cupo_act > 0
                     THEN
                        IF credit IS NULL
                        THEN
                           BEGIN
                              SELECT ssrmeet_credit_hr_sess
                                INTO credit
                                FROM ssrmeet
                               WHERE     1 = 1
                                     AND ssrmeet_term_code = c.periodo
                                     AND ssrmeet_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 credit := NULL;
                           END;

                           IF credit IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_credit_hrs = credit
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;
                           END IF;
                        END IF;

                        IF credit_bill IS NULL
                        THEN
                           credit_bill := 1;

                           IF credit IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_bill_hrs = credit_bill
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;
                           END IF;
                        END IF;

                        IF gmod IS NULL
                        THEN
                           BEGIN
                              SELECT scrgmod_gmod_code
                                INTO gmod
                                FROM scrgmod
                               WHERE     1 = 1
                                     AND scrgmod_subj_code = c.subj
                                     AND scrgmod_crse_numb = c.crse
                                     AND scrgmod_default_ind = 'D';
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 gmod := '1';
                           END;

                           IF gmod IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_gmod_code = gmod
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;
                           END IF;
                        END IF;

                        BEGIN
                           SELECT spriden_pidm
                             INTO pidm_prof
                             FROM spriden
                            WHERE     1 = 1
                                  AND spriden_id = c.prof
                                  AND spriden_change_ind IS NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              pidm_prof := NULL;
                        END;

                        conta_ptrm := 0;

                        BEGIN
                           SELECT COUNT (1)
                             INTO conta_ptrm
                             FROM sirasgn
                            WHERE     SIRASGN_TERM_CODE = c.periodo
                                  AND SIRASGN_CRN = crn
                                  AND SIRASGN_PIDM = pidm_prof
                                  AND SIRASGN_PRIMARY_IND = 'Y';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              conta_ptrm := 0;
                        END;

                        IF pidm_prof IS NOT NULL AND conta_ptrm = 0
                        THEN
                           BEGIN
                              INSERT INTO sirasgn
                                   VALUES (c.periodo,
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
                                           USER,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        END IF;

                        conta_ptrm := 0;

                        BEGIN
                           SELECT COUNT (*)
                             INTO conta_ptrm
                             FROM sfbetrm
                            WHERE     1 = 1
                                  AND sfbetrm_term_code = c.periodo
                                  AND sfbetrm_pidm = c.pidm;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              conta_ptrm := 0;
                        END;

                        IF conta_ptrm = 0
                        THEN
                           BEGIN
                              INSERT INTO sfbetrm
                                   VALUES (c.periodo,
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
                                           NULL);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                    (   'Se presento un error al insertar en la tabla sfbetrm '
                                     || SQLERRM);
                           END;
                        END IF;

                        BEGIN
                           BEGIN
                              INSERT INTO sfrstcr
                                   VALUES (c.periodo,      --SFRSTCR_TERM_CODE
                                           c.pidm,              --SFRSTCR_PIDM
                                           crn,                  --SFRSTCR_CRN
                                           1,         --SFRSTCR_CLASS_SORT_KEY
                                           c.grupo,          --SFRSTCR_REG_SEQ
                                           parte,          --SFRSTCR_PTRM_CODE
                                           p_estatus,      --SFRSTCR_RSTS_CODE
                                           SYSDATE,        --SFRSTCR_RSTS_DATE
                                           NULL,          --SFRSTCR_ERROR_FLAG
                                           NULL,             --SFRSTCR_MESSAGE
                                           credit_bill,      --SFRSTCR_BILL_HR
                                           3,                --SFRSTCR_WAIV_HR
                                           credit,         --SFRSTCR_CREDIT_HR
                                           credit_bill, --SFRSTCR_BILL_HR_HOLD
                                           credit,    --SFRSTCR_CREDIT_HR_HOLD
                                           gmod,           --SFRSTCR_GMOD_CODE
                                           NULL,           --SFRSTCR_GRDE_CODE
                                           NULL,       --SFRSTCR_GRDE_CODE_MID
                                           NULL,           --SFRSTCR_GRDE_DATE
                                           'N',            --SFRSTCR_DUPL_OVER
                                           'N',            --SFRSTCR_LINK_OVER
                                           'N',            --SFRSTCR_CORQ_OVER
                                           'N',            --SFRSTCR_PREQ_OVER
                                           'N',            --SFRSTCR_TIME_OVER
                                           'N',            --SFRSTCR_CAPC_OVER
                                           'N',            --SFRSTCR_LEVL_OVER
                                           'N',            --SFRSTCR_COLL_OVER
                                           'N',            --SFRSTCR_MAJR_OVER
                                           'N',            --SFRSTCR_CLAS_OVER
                                           'N',            --SFRSTCR_APPR_OVER
                                           'N',    --SFRSTCR_APPR_RECEIVED_IND
                                           SYSDATE,         --SFRSTCR_ADD_DATE
                                           SYSDATE,    --SFRSTCR_ACTIVITY_DATE
                                           c.nivel,        --SFRSTCR_LEVL_CODE
                                           c.campus,       --SFRSTCR_CAMP_CODE
                                           c.materia,   --SFRSTCR_RESERVED_KEY
                                           NULL,           --SFRSTCR_ATTEND_HR
                                           'Y',            --SFRSTCR_REPT_OVER
                                           'N',            --SFRSTCR_RPTH_OVER
                                           NULL,           --SFRSTCR_TEST_OVER
                                           'N',            --SFRSTCR_CAMP_OVER
                                           USER,                --SFRSTCR_USER
                                           'N',            --SFRSTCR_DEGC_OVER
                                           'N',            --SFRSTCR_PROG_OVER
                                           NULL,         --SFRSTCR_LAST_ATTEND
                                           NULL,           --SFRSTCR_GCMT_CODE
                                           'PRONOSTICO', --SFRSTCR_DATA_ORIGIN
                                           SYSDATE, --SFRSTCR_ASSESS_ACTIVITY_DATE
                                           'N',            --SFRSTCR_DEPT_OVER
                                           'N',            --SFRSTCR_ATTS_OVER
                                           'N',            --SFRSTCR_CHRT_OVER
                                           c.grupo,         --SFRSTCR_RMSG_CDE
                                           NULL,         --SFRSTCR_WL_PRIORITY
                                           NULL,    --SFRSTCR_WL_PRIORITY_ORIG
                                           NULL, --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                           NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                           'N',            --SFRSTCR_MEXC_OVER
                                           c.study, --SFRSTCR_STSP_KEY_SEQUENCE
                                           NULL,        --SFRSTCR_BRDH_SEQ_NUM
                                           '01',           --SFRSTCR_BLCK_CODE
                                           NULL,          --SFRSTCR_STRH_SEQNO
                                           NULL,          --SFRSTCR_STRD_SEQNO
                                           NULL,        --SFRSTCR_SURROGATE_ID
                                           NULL,             --SFRSTCR_VERSION
                                           USER,             --SFRSTCR_USER_ID
                                           vl_orden        --SFRSTCR_VPDI_CODE
                                                   );
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 DBMS_OUTPUT.put_line (
                                    'Error al insertar SFRSTCR ' || SQLERRM);
                                 vl_error :=
                                    (   'Se presento un error al insertar en la tabla SFRSTCR '
                                     || SQLERRM);
                           END;


                           BEGIN
                              UPDATE ssbsect
                                 SET ssbsect_enrl = ssbsect_enrl + 1
                               WHERE     1 = 1
                                     AND ssbsect_term_code = c.periodo
                                     AND ssbsect_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al actualizar el enrolamiento '
                                    || SQLERRM;
                           END;

                           BEGIN
                              UPDATE SZTPRONO
                                 SET SZTPRONO_ENVIO_HORARIOS = 'S'
                               WHERE     1 = 1
                                     AND SZTPRONO_NO_REGLA = p_regla
                                     AND SZTPRONO_FECHA_INICIO = pn_fecha
                                     AND SZTPRONO_PIDM = c.pidm
                                     AND sztprono_materia_legal = c.materia
                                     AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                     AND SZTPRONO_PTRM_CODE = parte;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                    (   'Se presento un error al insertar en la tabla SZTPRONO 1 '
                                     || SQLERRM);
                           END;

                           BEGIN
                              UPDATE ssbsect
                                 SET ssbsect_seats_avail =
                                        ssbsect_seats_avail - 1
                               WHERE     1 = 1
                                     AND ssbsect_term_code = c.periodo
                                     AND ssbsect_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al actualizar la disponibilidad del grupo '
                                    || SQLERRM;
                           END;

                           BEGIN
                              UPDATE ssbsect
                                 SET ssbsect_census_enrl = ssbsect_enrl
                               WHERE     1 = 1
                                     AND ssbsect_term_code = c.periodo
                                     AND ssbsect_crn = crn;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al actualizar el Censo del grupo '
                                    || SQLERRM;
                           END;


                           IF C.SGBSTDN_STYP_CODE = 'F'
                           THEN
                              BEGIN
                                 UPDATE sgbstdn a
                                    SET a.sgbstdn_styp_code = 'N',
                                        a.SGBSTDN_DATA_ORIGIN = 'PRONOSTICO',
                                        a.SGBSTDN_USER_ID = USER
                                  WHERE     1 = 1
                                        AND a.sgbstdn_pidm = c.pidm
                                        AND a.sgbstdn_term_code_eff =
                                               (SELECT MAX (
                                                          a1.sgbstdn_term_code_eff)
                                                  FROM sgbstdn a1
                                                 WHERE     a1.sgbstdn_pidm =
                                                              a.sgbstdn_pidm
                                                       AND a1.sgbstdn_program_1 =
                                                              a.sgbstdn_program_1)
                                        AND a.sgbstdn_program_1 = c.prog;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                       || SQLERRM;
                              END;
                           END IF;

                           BEGIN
                              SELECT COUNT (*)
                                INTO l_cambio_estatus
                                FROM sfrstcr
                               WHERE     1 = 1
                                     AND    SFRSTCR_TERM_CODE
                                         || SFRSTCR_PTRM_CODE !=
                                            c.periodo || c.parte
                                     AND sfrstcr_pidm = c.pidm
                                     AND SFRSTCR_RSTS_CODE = 'RE'
                                     AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 l_cambio_estatus := 0;
                           END;


                           IF l_cambio_estatus > 0
                           THEN
                              IF C.SGBSTDN_STYP_CODE IN ('N', 'R')
                              THEN
                                 BEGIN
                                    UPDATE sgbstdn a
                                       SET a.sgbstdn_styp_code = 'C',
                                           a.SGBSTDN_DATA_ORIGIN =
                                              'PRONOSTICO',
                                           A.SGBSTDN_USER_ID = USER
                                     WHERE     1 = 1
                                           AND a.sgbstdn_pidm = c.pidm
                                           AND a.sgbstdn_term_code_eff =
                                                  (SELECT MAX (
                                                             a1.sgbstdn_term_code_eff)
                                                     FROM sgbstdn a1
                                                    WHERE     a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                          AND a1.sgbstdn_program_1 = a.sgbstdn_program_1)
                                                          AND a.sgbstdn_program_1 = c.prog;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                          || SQLERRM;
                                 END;
                              END IF;
                           END IF;

                           IF c.fecha_inicio IS NOT NULL
                           THEN
                              BEGIN
                                 UPDATE sorlcur
                                    SET sorlcur_start_date =
                                           TRUNC (c.fecha_inicio),
                                        sorlcur_data_origin = 'PRONOSTICO',
                                        sorlcur_user_id = USER,
                                        SORLCUR_RATE_CODE = c.rate
                                  WHERE     1 = 1
                                        AND sorlcur_pidm = c.pidm
                                        AND sorlcur_program = c.prog
                                        AND sorlcur_lmod_code = 'LEARNER'
                                        AND sorlcur_key_seqno = c.study;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur '
                                       || SQLERRM;
                              END;
                           END IF;

                           conta_ptrm := 0;

                           BEGIN
                              SELECT COUNT (*)
                                INTO conta_ptrm
                                FROM sfrareg
                               WHERE     1 = 1
                                     AND sfrareg_pidm = c.pidm
                                     AND sfrareg_term_code = c.periodo
                                     AND sfrareg_crn = crn
                                     AND sfrareg_extension_number = 0
                                     AND sfrareg_rsts_code = p_estatus;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 conta_ptrm := 0;
                           END;

                           IF conta_ptrm = 0
                           THEN
                              BEGIN
                                 INSERT INTO sfrareg
                                      VALUES (c.pidm,
                                              c.periodo,
                                              crn,
                                              0,
                                              p_estatus,
                                              NVL (c.fecha_inicio, pn_fecha),
                                              NVL (f_fin, SYSDATE),
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
                                              NULL);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar el registro de la materia para el alumno '
                                       || SQLERRM;
                              END;
                           END IF;

                           BEGIN
                              SELECT COUNT (1)
                                INTO vl_existe
                                FROM SHRINST
                               WHERE     1 = 1
                                     AND shrinst_term_code = c.periodo
                                     AND shrinst_crn = crn
                                     AND shrinst_pidm = c.pidm;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_existe := 0;
                           END;

                           IF vl_existe = 0
                           THEN
                              BEGIN
                                 INSERT INTO SHRINST
                                      VALUES (c.periodo,   --SHRINST_TERM_CODE
                                              crn,               --SHRINST_CRN
                                              c.pidm,           --SHRINST_PIDM
                                              SYSDATE, --SHRINST_ACTIVITY_DATE
                                              'Y',       --SHRINST_PRIMARY_IND
                                              NULL,     --SHRINST_SURROGATE_ID
                                              NULL,          --SHRINST_VERSION
                                              USER,          --SHRINST_USER_ID
                                              'PRONOSTICO', --SHRINST_DATA_ORIGIN
                                              NULL);       --SHRINST_VPDI_CODE
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar al alumno en SHRINST '
                                       || SQLERRM;
                              END;
                           END IF;

                           BEGIN
                              UPDATE SZTPRONO
                                 SET SZTPRONO_ENVIO_HORARIOS = 'S'
                               WHERE     1 = 1
                                     AND SZTPRONO_NO_REGLA = p_regla
                                     AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                     AND sztprono_materia_legal = c.materia
                                     AND SZTPRONO_PIDM = c.pidm;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              vl_error :=
                                    'Se presento un error al insertar al alumno en el grupo '
                                 || SQLERRM;
                        END;
                     ELSE
                        DBMS_OUTPUT.put_line (
                           'mensaje:' || 'No hay cupo en el grupo creado');
                        schd := NULL;
                        title := NULL;
                        credit := NULL;
                        gmod := NULL;
                        f_inicio := NULL;
                        f_fin := NULL;
                        sem := NULL;
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
                             FROM scbcrse, scrschd
                            WHERE     1 = 1
                                  AND scbcrse_subj_code = c.subj
                                  AND scbcrse_crse_numb = c.crse
                                  AND scbcrse_eff_term = '000000'
                                  AND scrschd_subj_code = scbcrse_subj_code
                                  AND scrschd_crse_numb = scbcrse_crse_numb
                                  AND scrschd_eff_term = scbcrse_eff_term;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              schd := NULL;
                              title := NULL;
                              credit := NULL;
                              credit_bill := NULL;
                        END;

                        BEGIN
                           SELECT scrgmod_gmod_code
                             INTO gmod
                             FROM scrgmod
                            WHERE     scrgmod_subj_code = c.subj
                                  AND scrgmod_crse_numb = c.crse
                                  AND scrgmod_default_ind = 'D';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              gmod := '1';
                        END;

                        --aqui se agrego para no gnerera mas grupos

                        IF c.prof IS NULL THEN
                           crn := crn;
                        ELSE
                           IF c.nivel = 'MS'
                           THEN
                              l_campus_ms := 'AS';
                           ELSE
                              l_campus_ms := c.niVel;
                           END IF;

                           BEGIN
                              SELECT sztcrnv_crn
                                INTO crn
                                FROM SZTCRNV
                               WHERE     1 = 1
                                     AND ROWNUM = 1
                                     AND SZTCRNV_LVEL_CODE =
                                            SUBSTR (C.NIVEL, 1, 1)
                                     AND (SZTCRNV_crn, SZTCRNV_LVEL_CODE) NOT IN (SELECT TO_NUMBER (
                                                                                            crn),
                                                                                         SUBSTR (
                                                                                            SSBSECT_CRN,
                                                                                            1,
                                                                                            1)
                                                                                    FROM (SELECT CASE
                                                                                                    WHEN SUBSTR (
                                                                                                            SSBSECT_CRN,
                                                                                                            1,
                                                                                                            1) IN ('L',
                                                                                                                   'M',
                                                                                                                   'A',
                                                                                                                   'D',
                                                                                                                   'B')
                                                                                                    THEN
                                                                                                       TO_NUMBER (
                                                                                                          SUBSTR (
                                                                                                             SSBSECT_CRN,
                                                                                                             2,
                                                                                                             10))
                                                                                                    ELSE
                                                                                                       TO_NUMBER (
                                                                                                          SSBSECT_CRN)
                                                                                                 END
                                                                                                    crn,
                                                                                                 SSBSECT_CRN
                                                                                            FROM ssbsect
                                                                                           WHERE     1 =
                                                                                                        1
                                                                                                 AND ssbsect_term_code =
                                                                                                        c.periodo-- AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                         )
                                                                                   WHERE 1 =
                                                                                            1);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 -- raise_application_error (-20002,'Error al 2 '|| SQLCODE||' Error: '||SQLERRM);
                                 DBMS_OUTPUT.put_line (
                                    ' error en crn 2 ' || SQLERRM);
                                 crn := NULL;
                           END;


                           IF crn IS NOT NULL
                           THEN
                              IF c.nivel = 'LI'
                              THEN
                                 crn := 'L' || crn;
                              ELSIF c.nivel = 'MA'
                              THEN
                                 crn := 'M' || crn;
                              ELSIF c.nivel = 'MS'
                              THEN
                                 crn := 'A' || crn;
                              ELSIF c.nivel = 'DO'
                              THEN
                                 crn := 'D' || crn;
                              ELSIF c.nivel = 'ID'
                              THEN
                                 crn := 'I' || crn;
                              ELSIF c.nivel = 'EC'
                              THEN
                                 crn := 'E' || crn;
                              END IF;
                           ELSE
                              BEGIN
                                 SELECT   NVL (MAX (TO_NUMBER (SSBSECT_CRN)),0) + 1
                                   INTO crn
                                   FROM ssbsect
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND SUBSTR (ssbsect_crn, 1, 1) NOT IN ('L',
                                                                               'M',
                                                                               'A',
                                                                               'D',
                                                                               'B',
                                                                               'I');
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    crn := 0;
                              END;
                           END IF;
                        END IF;

                        BEGIN
                           SELECT DISTINCT
                                  sobptrm_start_date,
                                  sobptrm_end_date,
                                  sobptrm_weeks
                             INTO f_inicio, f_fin, sem
                             FROM sobptrm
                            WHERE     1 = 1
                                  AND sobptrm_term_code = c.periodo
                                  AND sobptrm_ptrm_code = c.parte;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        IF crn IS NOT NULL
                        THEN
                           BEGIN
                              l_maximo_alumnos := 90;
                           END;


                           --raise_application_error (-20002,'Buscamos SSBSECT_CENSUS_ENRL_DATE '||f_inicio);

                           BEGIN
                              INSERT INTO ssbsect
                                   VALUES (c.periodo,      --SSBSECT_TERM_CODE
                                           crn,                  --SSBSECT_CRN
                                           c.parte,        --SSBSECT_PTRM_CODE
                                           c.subj,         --SSBSECT_SUBJ_CODE
                                           c.crse,         --SSBSECT_CRSE_NUMB
                                           c.grupo,         --SSBSECT_SEQ_NUMB
                                           'A',            --SSBSECT_SSTS_CODE
                                           'ENL',          --SSBSECT_SCHD_CODE
                                           c.campus,       --SSBSECT_CAMP_CODE
                                           title,         --SSBSECT_CRSE_TITLE
                                           credit,        --SSBSECT_CREDIT_HRS
                                           credit_bill,     --SSBSECT_BILL_HRS
                                           gmod,           --SSBSECT_GMOD_CODE
                                           NULL,           --SSBSECT_SAPR_CODE
                                           NULL,           --SSBSECT_SESS_CODE
                                           NULL,          --SSBSECT_LINK_IDENT
                                           NULL,            --SSBSECT_PRNT_IND
                                           'Y',         --SSBSECT_GRADABLE_IND
                                           NULL,            --SSBSECT_TUIW_IND
                                           0,              --SSBSECT_REG_ONEUP
                                           0,             --SSBSECT_PRIOR_ENRL
                                           0,              --SSBSECT_PROJ_ENRL
                                           l_maximo_alumnos, --SSBSECT_MAX_ENRL
                                           0,                   --SSBSECT_ENRL
                                           l_maximo_alumnos, --SSBSECT_SEATS_AVAIL
                                           NULL,      --SSBSECT_TOT_CREDIT_HRS
                                           '0',          --SSBSECT_CENSUS_ENRL
                                           f_inicio, --SSBSECT_CENSUS_ENRL_DATE
                                           SYSDATE,    --SSBSECT_ACTIVITY_DATE
                                           f_inicio, --SSBSECT_PTRM_START_DATE
                                           f_fin,      --SSBSECT_PTRM_END_DATE
                                           sem,           --SSBSECT_PTRM_WEEKS
                                           NULL,        --SSBSECT_RESERVED_IND
                                           NULL,       --SSBSECT_WAIT_CAPACITY
                                           NULL,          --SSBSECT_WAIT_COUNT
                                           NULL,          --SSBSECT_WAIT_AVAIL
                                           NULL,              --SSBSECT_LEC_HR
                                           NULL,              --SSBSECT_LAB_HR
                                           NULL,              --SSBSECT_OTH_HR
                                           NULL,             --SSBSECT_CONT_HR
                                           NULL,           --SSBSECT_ACCT_CODE
                                           NULL,           --SSBSECT_ACCL_CODE
                                           NULL,       --SSBSECT_CENSUS_2_DATE
                                           NULL,   --SSBSECT_ENRL_CUT_OFF_DATE
                                           NULL,   --SSBSECT_ACAD_CUT_OFF_DATE
                                           NULL,   --SSBSECT_DROP_CUT_OFF_DATE
                                           NULL,       --SSBSECT_CENSUS_2_ENRL
                                           'Y',          --SSBSECT_VOICE_AVAIL
                                           'N', --SSBSECT_CAPP_PREREQ_TEST_IND
                                           NULL,           --SSBSECT_GSCH_NAME
                                           NULL,        --SSBSECT_BEST_OF_COMP
                                           NULL,      --SSBSECT_SUBSET_OF_COMP
                                           'NOP',          --SSBSECT_INSM_CODE
                                           NULL,       --SSBSECT_REG_FROM_DATE
                                           NULL,         --SSBSECT_REG_TO_DATE
                                           NULL, --SSBSECT_LEARNER_REGSTART_FDATE
                                           NULL, --SSBSECT_LEARNER_REGSTART_TDATE
                                           NULL,           --SSBSECT_DUNT_CODE
                                           NULL,     --SSBSECT_NUMBER_OF_UNITS
                                           0,   --SSBSECT_NUMBER_OF_EXTENSIONS
                                           'PRONOSTICO', --SSBSECT_DATA_ORIGIN
                                           USER,             --SSBSECT_USER_ID
                                           'MOOD',          --SSBSECT_INTG_CDE
                                           'B', --SSBSECT_PREREQ_CHK_METHOD_CDE
                                           USER,    --SSBSECT_KEYWORD_INDEX_ID
                                           NULL,     --SSBSECT_SCORE_OPEN_DATE
                                           NULL,   --SSBSECT_SCORE_CUTOFF_DATE
                                           NULL, --SSBSECT_REAS_SCORE_OPEN_DATE
                                           NULL, --SSBSECT_REAS_SCORE_CTOF_DATE
                                           NULL,        --SSBSECT_SURROGATE_ID
                                           NULL,             --SSBSECT_VERSION
                                           NULL);          --SSBSECT_VPDI_CODE


                              BEGIN
                                 UPDATE sobterm
                                    SET sobterm_crn_oneup = crn
                                  WHERE     1 = 1
                                        AND sobterm_term_code = c.periodo;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    NULL;
                              END;

                              BEGIN
                                 INSERT INTO ssrmeet
                                      VALUES (C.periodo,
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
                                              NULL);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un Error al insertar en ssrmeet '
                                       || SQLERRM;
                              END;

                              BEGIN
                                 SELECT spriden_pidm
                                   INTO pidm_prof
                                   FROM spriden
                                  WHERE     1 = 1
                                        AND spriden_id = c.prof
                                        AND spriden_change_ind IS NULL;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    pidm_prof := NULL;
                              END;

                              IF pidm_prof IS NOT NULL
                              THEN
                                 DBMS_OUTPUT.put_line (
                                       'Crea el CRN para el docente:'
                                    || pidm_prof
                                    || '*'
                                    || crn);

                                 BEGIN
                                    SELECT COUNT (1)
                                      INTO vl_exite_prof
                                      FROM sirasgn
                                     WHERE     1 = 1
                                           AND sirasgn_term_code = c.periodo
                                           AND sirasgn_crn = crn;
                                 -- And SIRASGN_PIDM = pidm_prof;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_exite_prof := 0;
                                 END;

                                 IF vl_exite_prof = 0
                                 THEN
                                    BEGIN
                                       INSERT INTO sirasgn
                                            VALUES (c.periodo,
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
                                                    'SZFALGO 2',
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL);
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          NULL;
                                    END;
                                 ELSE
                                    BEGIN
                                       UPDATE sirasgn
                                          SET sirasgn_primary_ind = NULL
                                        WHERE     1 = 1
                                              AND sirasgn_term_code =
                                                     c.periodo
                                              AND sirasgn_crn = crn;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          NULL;
                                    END;

                                    BEGIN
                                       INSERT INTO sirasgn
                                            VALUES (c.periodo,
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
                                                    NULL);
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          NULL;
                                    END;
                                 END IF;
                              END IF;

                              conta_ptrm := 0;

                              BEGIN
                                 SELECT COUNT (*)
                                   INTO conta_ptrm
                                   FROM sfbetrm
                                  WHERE     1 = 1
                                        AND sfbetrm_term_code = c.periodo
                                        AND sfbetrm_pidm = c.pidm;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    conta_ptrm := 0;
                              END;


                              IF conta_ptrm = 0
                              THEN
                                 BEGIN
                                    INSERT INTO sfbetrm
                                         VALUES (c.periodo,
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                          (   'Se presento un error al insertar en la tabla sfbetrm '
                                           || SQLERRM);
                                 END;
                              END IF;

                              BEGIN
                                 BEGIN
                                    INSERT INTO sfrstcr
                                         VALUES (c.periodo, --SFRSTCR_TERM_CODE
                                                 c.pidm,        --SFRSTCR_PIDM
                                                 crn,            --SFRSTCR_CRN
                                                 1,   --SFRSTCR_CLASS_SORT_KEY
                                                 c.grupo,    --SFRSTCR_REG_SEQ
                                                 c.parte,  --SFRSTCR_PTRM_CODE
                                                 p_estatus, --SFRSTCR_RSTS_CODE
                                                 SYSDATE,  --SFRSTCR_RSTS_DATE
                                                 NULL,    --SFRSTCR_ERROR_FLAG
                                                 NULL,       --SFRSTCR_MESSAGE
                                                 credit_bill, --SFRSTCR_BILL_HR
                                                 3,          --SFRSTCR_WAIV_HR
                                                 credit,   --SFRSTCR_CREDIT_HR
                                                 credit_bill, --SFRSTCR_BILL_HR_HOLD
                                                 credit, --SFRSTCR_CREDIT_HR_HOLD
                                                 gmod,     --SFRSTCR_GMOD_CODE
                                                 NULL,     --SFRSTCR_GRDE_CODE
                                                 NULL, --SFRSTCR_GRDE_CODE_MID
                                                 NULL,     --SFRSTCR_GRDE_DATE
                                                 'N',      --SFRSTCR_DUPL_OVER
                                                 'N',      --SFRSTCR_LINK_OVER
                                                 'N',      --SFRSTCR_CORQ_OVER
                                                 'N',      --SFRSTCR_PREQ_OVER
                                                 'N',      --SFRSTCR_TIME_OVER
                                                 'N',      --SFRSTCR_CAPC_OVER
                                                 'N',      --SFRSTCR_LEVL_OVER
                                                 'N',      --SFRSTCR_COLL_OVER
                                                 'N',      --SFRSTCR_MAJR_OVER
                                                 'N',      --SFRSTCR_CLAS_OVER
                                                 'N',      --SFRSTCR_APPR_OVER
                                                 'N', --SFRSTCR_APPR_RECEIVED_IND
                                                 SYSDATE,   --SFRSTCR_ADD_DATE
                                                 SYSDATE, --SFRSTCR_ACTIVITY_DATE
                                                 c.nivel,  --SFRSTCR_LEVL_CODE
                                                 c.campus, --SFRSTCR_CAMP_CODE
                                                 c.materia, --SFRSTCR_RESERVED_KEY
                                                 NULL,     --SFRSTCR_ATTEND_HR
                                                 'Y',      --SFRSTCR_REPT_OVER
                                                 'N',      --SFRSTCR_RPTH_OVER
                                                 NULL,     --SFRSTCR_TEST_OVER
                                                 'N',      --SFRSTCR_CAMP_OVER
                                                 USER,          --SFRSTCR_USER
                                                 'N',      --SFRSTCR_DEGC_OVER
                                                 'N',      --SFRSTCR_PROG_OVER
                                                 NULL,   --SFRSTCR_LAST_ATTEND
                                                 NULL,     --SFRSTCR_GCMT_CODE
                                                 'PRONOSTICO', --SFRSTCR_DATA_ORIGIN
                                                 SYSDATE, --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                 'N',      --SFRSTCR_DEPT_OVER
                                                 'N',      --SFRSTCR_ATTS_OVER
                                                 'N',      --SFRSTCR_CHRT_OVER
                                                 c.grupo,   --SFRSTCR_RMSG_CDE
                                                 NULL,   --SFRSTCR_WL_PRIORITY
                                                 NULL, --SFRSTCR_WL_PRIORITY_ORIG
                                                 NULL, --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                 NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                 'N',      --SFRSTCR_MEXC_OVER
                                                 c.study, --SFRSTCR_STSP_KEY_SEQUENCE
                                                 NULL,  --SFRSTCR_BRDH_SEQ_NUM
                                                 '01',     --SFRSTCR_BLCK_CODE
                                                 NULL,    --SFRSTCR_STRH_SEQNO
                                                 NULL,    --SFRSTCR_STRD_SEQNO
                                                 NULL,  --SFRSTCR_SURROGATE_ID
                                                 NULL,       --SFRSTCR_VERSION
                                                 USER,       --SFRSTCR_USER_ID
                                                 vl_orden  --SFRSTCR_VPDI_CODE
                                                         );
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                          (   'Se presento un error al insertar en la tabla SFRSTCR 2 '
                                           || SQLERRM);
                                 END;


                                 BEGIN
                                    UPDATE SZTPRONO
                                       SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                     WHERE     1 = 1
                                           AND SZTPRONO_NO_REGLA = p_regla
                                           AND SZTPRONO_PIDM = c.pidm
                                           AND sztprono_materia_legal =
                                                  c.materia
                                           AND SZTPRONO_ENVIO_HORARIOS = 'N';
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al insertar en la tabla SZTPRONO 2 '
                                          || SQLERRM;
                                 END;


                                 BEGIN
                                    UPDATE ssbsect
                                       SET ssbsect_enrl = ssbsect_enrl + 1
                                     WHERE     1 = 1
                                           AND ssbsect_term_code = c.periodo
                                           AND SSBSECT_CRN = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el enrolamiento '
                                          || SQLERRM;
                                 END;

                                 BEGIN
                                    UPDATE ssbsect
                                       SET ssbsect_seats_avail =
                                              ssbsect_seats_avail - 1
                                     WHERE     1 = 1
                                           AND ssbsect_term_code = c.periodo
                                           AND ssbsect_crn = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar la disponibilidad del grupo '
                                          || SQLERRM;
                                 END;

                                 BEGIN
                                    UPDATE ssbsect
                                       SET ssbsect_census_enrl = ssbsect_enrl
                                     WHERE     SSBSECT_TERM_CODE = c.periodo
                                           AND SSBSECT_CRN = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el Censo del grupo '
                                          || SQLERRM;
                                 END;

                                 IF C.SGBSTDN_STYP_CODE = 'F'
                                 THEN
                                    BEGIN
                                       UPDATE sgbstdn a
                                          SET a.sgbstdn_styp_code = 'N',
                                              a.SGBSTDN_DATA_ORIGIN =
                                                 'PRONOSTICO',
                                              A.SGBSTDN_USER_ID = USER
                                        WHERE     1 = 1
                                              AND a.sgbstdn_pidm = c.pidm
                                              AND a.sgbstdn_term_code_eff =
                                                     (SELECT MAX (
                                                                a1.sgbstdn_term_code_eff)
                                                        FROM sgbstdn a1
                                                       WHERE     a1.sgbstdn_pidm =
                                                                    a.sgbstdn_pidm
                                                             AND a1.sgbstdn_program_1 =
                                                                    a.sgbstdn_program_1)
                                              AND a.sgbstdn_program_1 =
                                                     c.prog;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                             || SQLERRM;
                                    END;
                                 END IF;

                                 BEGIN
                                    SELECT COUNT (*)
                                      INTO l_cambio_estatus
                                      FROM sfrstcr
                                     WHERE     1 = 1
                                           AND    SFRSTCR_TERM_CODE
                                               || SFRSTCR_PTRM_CODE !=
                                                  c.periodo || c.parte
                                           AND SFRSTCR_RSTS_CODE = 'RE'
                                           AND sfrstcr_pidm = c.pidm
                                           AND SFRSTCR_STSP_KEY_SEQUENCE =
                                                  c.study;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       l_cambio_estatus := 0;
                                 END;


                                 IF l_cambio_estatus > 0
                                 THEN
                                    IF C.SGBSTDN_STYP_CODE IN ('N', 'R')
                                    THEN
                                       BEGIN
                                          UPDATE sgbstdn a
                                             SET a.sgbstdn_styp_code = 'C',
                                                 a.SGBSTDN_DATA_ORIGIN =
                                                    'PRONOSTICO',
                                                 A.SGBSTDN_USER_ID = USER
                                           WHERE     1 = 1
                                                 AND a.sgbstdn_pidm = c.pidm
                                                 AND a.sgbstdn_term_code_eff =
                                                        (SELECT MAX (
                                                                   a1.sgbstdn_term_code_eff)
                                                           FROM sgbstdn a1
                                                          WHERE     a1.sgbstdn_pidm =
                                                                       a.sgbstdn_pidm
                                                                AND a1.sgbstdn_program_1 =
                                                                       a.sgbstdn_program_1)
                                                 AND a.sgbstdn_program_1 =
                                                        c.prog;
                                       EXCEPTION
                                          WHEN OTHERS
                                          THEN
                                             vl_error :=
                                                   'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                                || SQLERRM;
                                       END;
                                    END IF;
                                 END IF;

                                 f_inicio := NULL;

                                 BEGIN
                                    SELECT DISTINCT sobptrm_start_date
                                      INTO f_inicio
                                      FROM sobptrm
                                     WHERE     sobptrm_term_code = c.periodo
                                           AND sobptrm_ptrm_code = c.parte;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       f_inicio := NULL;
                                       vl_error :=
                                             'Se presento un error al Obtener la fecha de inicio de Clases periodo '
                                          || c.periodo
                                          || ' parte '
                                          || c.parte
                                          || ' '
                                          || SQLERRM
                                          || ' poe';
                                 END;

                                 IF f_inicio IS NOT NULL
                                 THEN
                                    BEGIN
                                       UPDATE sorlcur
                                          SET sorlcur_start_date =
                                                 TRUNC (f_inicio),
                                              SORLCUR_RATE_CODE = c.rate
                                        WHERE     SORLCUR_PIDM = c.pidm
                                              AND SORLCUR_PROGRAM = c.prog
                                              AND SORLCUR_LMOD_CODE =
                                                     'LEARNER'
                                              AND SORLCUR_KEY_SEQNO = c.study;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur '
                                             || SQLERRM;
                                    END;
                                 END IF;

                                 conta_ptrm := 0;

                                 BEGIN
                                    SELECT COUNT (*)
                                      INTO conta_ptrm
                                      FROM sfrareg
                                     WHERE     1 = 1
                                           AND sfrareg_pidm = c.pidm
                                           AND sfrareg_term_code = c.periodo
                                           AND sfrareg_crn = crn
                                           AND sfrareg_extension_number = 0
                                           AND sfrareg_rsts_code = p_estatus;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       conta_ptrm := 0;
                                 END;

                                 IF conta_ptrm = 0
                                 THEN
                                    BEGIN
                                       INSERT INTO sfrareg
                                            VALUES (c.pidm,
                                                    c.periodo,
                                                    crn,
                                                    0,
                                                    p_estatus,
                                                    NVL (f_inicio, pn_fecha),
                                                    NVL (f_fin, SYSDATE),
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
                                                    NULL);
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al insertar sfrareg 2 el registro de la materia para el alumno '
                                             || SQLERRM;
                                    END;
                                 END IF;

                                 BEGIN
                                    UPDATE SZTPRONO
                                       SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                     WHERE     1 = 1
                                           AND SZTPRONO_NO_REGLA = p_regla
                                           AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                           AND sztprono_materia_legal =
                                                  c.materia
                                           AND SZTPRONO_PIDM = c.pidm;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al insertar en la tabla SZTPRONO 3 '
                                          || SQLERRM;
                                 END;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar al alumno en el grupo2 '
                                       || SQLERRM;
                              END;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un Error al insertar el nuevo grupo en la tabla SSBSECT '
                                    || SQLERRM;
                           END;
                        END IF;
                     END IF;                -------- > No hay cupo en el grupo
                  ELSE
                     DBMS_OUTPUT.put_line (
                        'mensaje:' || 'No hay grupo creado Con docente 3');

                     schd := NULL;
                     title := NULL;
                     credit := NULL;
                     gmod := NULL;
                     f_inicio := NULL;
                     f_fin := NULL;
                     sem := NULL;
                     crn := NULL;
                     pidm_prof := NULL;
                     vl_exite_prof := 0;

                     BEGIN
                        SELECT scrschd_schd_code,
                               scbcrse_title,
                               scbcrse_credit_hr_low,
                               scbcrse_bill_hr_low
                          INTO schd,
                               title,
                               credit,
                               credit_bill
                          FROM scbcrse, scrschd
                         WHERE     1 = 1
                               AND scbcrse_subj_code = c.subj
                               AND scbcrse_crse_numb = c.crse
                               AND scbcrse_eff_term = '000000'
                               AND scrschd_subj_code = scbcrse_subj_code
                               AND scrschd_crse_numb = scbcrse_crse_numb
                               AND scrschd_eff_term = scbcrse_eff_term;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           schd := NULL;
                           title := NULL;
                           credit := NULL;
                           credit_bill := NULL;
                     END;

                     BEGIN
                        SELECT scrgmod_gmod_code
                          INTO gmod
                          FROM scrgmod
                         WHERE     1 = 1
                               AND scrgmod_subj_code = c.subj
                               AND scrgmod_crse_numb = c.crse
                               AND scrgmod_default_ind = 'D';
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           gmod := '1';
                     END;

                     IF c.nivel = 'MS'
                     THEN
                        l_campus_ms := 'AS';
                     ELSE
                        l_campus_ms := c.niVel;
                     END IF;

                     BEGIN
                        SELECT sztcrnv_crn
                          INTO crn
                          FROM SZTCRNV
                         WHERE     1 = 1
                               AND ROWNUM = 1
                               AND SZTCRNV_LVEL_CODE =
                                      SUBSTR (l_campus_ms, 1, 1)
                               AND (SZTCRNV_crn, SZTCRNV_LVEL_CODE) NOT IN (SELECT TO_NUMBER (
                                                                                      crn),
                                                                                   SUBSTR (
                                                                                      SSBSECT_CRN,
                                                                                      1,
                                                                                      1)
                                                                              FROM (SELECT CASE
                                                                                              WHEN SUBSTR (
                                                                                                      SSBSECT_CRN,
                                                                                                      1,
                                                                                                      1) IN ('L',
                                                                                                             'M',
                                                                                                             'A',
                                                                                                             'D',
                                                                                                             'B',
                                                                                                             'E',
                                                                                                             'I')
                                                                                              THEN
                                                                                                 TO_NUMBER (
                                                                                                    SUBSTR (
                                                                                                       SSBSECT_CRN,
                                                                                                       2,
                                                                                                       10))
                                                                                              ELSE
                                                                                                 TO_NUMBER (
                                                                                                    SSBSECT_CRN)
                                                                                           END
                                                                                              crn,
                                                                                           SSBSECT_CRN
                                                                                      FROM ssbsect
                                                                                     WHERE     1 =
                                                                                                  1
                                                                                           AND ssbsect_term_code =
                                                                                                  c.periodo-- AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                   )
                                                                             WHERE 1 =
                                                                                      1);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           -- raise_application_error (-20002,'Error al 2 '|| SQLCODE||' Error: '||SQLERRM);
                           DBMS_OUTPUT.put_line (
                              ' error en crn 2 ' || SQLERRM);
                           crn := NULL;
                     END;

                     IF crn IS NOT NULL
                     THEN
                        IF c.nivel = 'LI'   THEN
                           crn := 'L' || crn;
                        ELSIF c.nivel = 'MA'  THEN
                           crn := 'M' || crn;
                        ELSIF c.nivel = 'MS'  THEN
                           crn := 'A' || crn;
                        ELSIF c.nivel = 'DO'  THEN
                           crn := 'D' || crn;
                       ELSIF c.nivel = 'ID'  THEN
                           crn := 'I' || crn; 
                       ELSIF c.nivel = 'EC'  THEN
                           crn := 'E' || crn;
                        END IF;
                     ELSE
                        BEGIN
                           SELECT NVL (MAX (TO_NUMBER (SSBSECT_CRN)), 0) + 1
                             INTO crn
                             FROM ssbsect
                            WHERE     1 = 1
                                  AND ssbsect_term_code = c.periodo
                                   AND SUBSTR (ssbsect_crn, 1, 1) NOT IN ('L',
                                                                               'M',
                                                                               'A',
                                                                               'D',
                                                                               'B',
                                                                               'I');
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              crn := 0;
                        END;
                     END IF;

                     BEGIN
                        SELECT DISTINCT
                               sobptrm_start_date,
                               sobptrm_end_date,
                               sobptrm_weeks
                          INTO f_inicio, f_fin, sem
                          FROM sobptrm
                         WHERE     1 = 1
                               AND sobptrm_term_code = c.periodo
                               AND sobptrm_ptrm_code = c.parte;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'No se Encontro configuracion para el Periodo= '
                              || c.periodo
                              || ' y Parte de Periodo= '
                              || c.parte
                              || SQLERRM;
                     END;


                     IF crn IS NOT NULL
                     THEN
                        -- le movemos extraemos el numero de alumonos de la tabla de profesores

                        BEGIN
                           l_maximo_alumnos := 90;
                        END;

                        BEGIN
                           INSERT INTO ssbsect
                                VALUES (c.periodo,         --SSBSECT_TERM_CODE
                                        crn,                     --SSBSECT_CRN
                                        c.parte,           --SSBSECT_PTRM_CODE
                                        c.subj,            --SSBSECT_SUBJ_CODE
                                        c.crse,            --SSBSECT_CRSE_NUMB
                                        c.grupo,            --SSBSECT_SEQ_NUMB
                                        'A',               --SSBSECT_SSTS_CODE
                                        'ENL',             --SSBSECT_SCHD_CODE
                                        c.campus,          --SSBSECT_CAMP_CODE
                                        title,            --SSBSECT_CRSE_TITLE
                                        credit,           --SSBSECT_CREDIT_HRS
                                        credit_bill,        --SSBSECT_BILL_HRS
                                        gmod,              --SSBSECT_GMOD_CODE
                                        NULL,              --SSBSECT_SAPR_CODE
                                        NULL,              --SSBSECT_SESS_CODE
                                        NULL,             --SSBSECT_LINK_IDENT
                                        NULL,               --SSBSECT_PRNT_IND
                                        'Y',            --SSBSECT_GRADABLE_IND
                                        NULL,               --SSBSECT_TUIW_IND
                                        0,                 --SSBSECT_REG_ONEUP
                                        0,                --SSBSECT_PRIOR_ENRL
                                        0,                 --SSBSECT_PROJ_ENRL
                                        l_maximo_alumnos,   --SSBSECT_MAX_ENRL
                                        0,                      --SSBSECT_ENRL
                                        l_maximo_alumnos, --SSBSECT_SEATS_AVAIL
                                        NULL,         --SSBSECT_TOT_CREDIT_HRS
                                        '0',             --SSBSECT_CENSUS_ENRL
                                        NVL (f_inicio, SYSDATE), --SSBSECT_CENSUS_ENRL_DATE
                                        SYSDATE,       --SSBSECT_ACTIVITY_DATE
                                        NVL (f_inicio, SYSDATE), --SSBSECT_PTRM_START_DATE
                                        NVL (f_FIN, SYSDATE), --SSBSECT_PTRM_END_DATE
                                        sem,              --SSBSECT_PTRM_WEEKS
                                        NULL,           --SSBSECT_RESERVED_IND
                                        NULL,          --SSBSECT_WAIT_CAPACITY
                                        NULL,             --SSBSECT_WAIT_COUNT
                                        NULL,             --SSBSECT_WAIT_AVAIL
                                        NULL,                 --SSBSECT_LEC_HR
                                        NULL,                 --SSBSECT_LAB_HR
                                        NULL,                 --SSBSECT_OTH_HR
                                        NULL,                --SSBSECT_CONT_HR
                                        NULL,              --SSBSECT_ACCT_CODE
                                        NULL,              --SSBSECT_ACCL_CODE
                                        NULL,          --SSBSECT_CENSUS_2_DATE
                                        NULL,      --SSBSECT_ENRL_CUT_OFF_DATE
                                        NULL,      --SSBSECT_ACAD_CUT_OFF_DATE
                                        NULL,      --SSBSECT_DROP_CUT_OFF_DATE
                                        NULL,            --SSBSECT_CENSUS_ENRL
                                        'Y',             --SSBSECT_VOICE_AVAIL
                                        'N',    --SSBSECT_CAPP_PREREQ_TEST_IND
                                        NULL,              --SSBSECT_GSCH_NAME
                                        NULL,           --SSBSECT_BEST_OF_COMP
                                        NULL,         --SSBSECT_SUBSET_OF_COMP
                                        'NOP',             --SSBSECT_INSM_CODE
                                        NULL,          --SSBSECT_REG_FROM_DATE
                                        NULL,            --SSBSECT_REG_TO_DATE
                                        NULL, --SSBSECT_LEARNER_REGSTART_FDATE
                                        NULL, --SSBSECT_LEARNER_REGSTART_TDATE
                                        NULL,              --SSBSECT_DUNT_CODE
                                        NULL,        --SSBSECT_NUMBER_OF_UNITS
                                        0,      --SSBSECT_NUMBER_OF_EXTENSIONS
                                        'PRONOSTICO',    --SSBSECT_DATA_ORIGIN
                                        USER,                --SSBSECT_USER_ID
                                        'MOOD',             --SSBSECT_INTG_CDE
                                        'B',   --SSBSECT_PREREQ_CHK_METHOD_CDE
                                        USER,       --SSBSECT_KEYWORD_INDEX_ID
                                        NULL,        --SSBSECT_SCORE_OPEN_DATE
                                        NULL,      --SSBSECT_SCORE_CUTOFF_DATE
                                        NULL,   --SSBSECT_REAS_SCORE_OPEN_DATE
                                        NULL,   --SSBSECT_REAS_SCORE_CTOF_DATE
                                        NULL,           --SSBSECT_SURROGATE_ID
                                        NULL,                --SSBSECT_VERSION
                                        NULL               --SSBSECT_VPDI_CODE
                                            );

                           BEGIN
                              UPDATE SOBTERM
                                 SET sobterm_crn_oneup = crn
                               WHERE 1 = 1 AND sobterm_term_code = c.periodo;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;

                           BEGIN
                              INSERT INTO ssrmeet
                                   VALUES (C.periodo,
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
                                           NULL);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un Error al insertar en ssrmeet '
                                    || SQLERRM;
                           END;

                           BEGIN
                              SELECT spriden_pidm
                                INTO pidm_prof
                                FROM spriden
                               WHERE     1 = 1
                                     AND spriden_id = c.prof
                                     AND spriden_change_ind IS NULL;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 pidm_prof := NULL;
                           END;

                           IF pidm_prof IS NOT NULL
                           THEN
                              --dbms_output.put_line('Crea el CRN para el docente:'|| pidm_prof ||'*'||crn);

                              BEGIN
                                 SELECT COUNT (1)
                                   INTO vl_exite_prof
                                   FROM sirasgn
                                  WHERE     1 = 1
                                        AND sirasgn_term_code = c.periodo
                                        AND sirasgn_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_exite_prof := 0;
                              END;

                              IF vl_exite_prof = 0
                              THEN
                                 BEGIN
                                    INSERT INTO sirasgn
                                         VALUES (c.periodo,
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;
                              ELSE
                                 BEGIN
                                    UPDATE sirasgn
                                       SET sirasgn_primary_ind = NULL
                                     WHERE     1 = 1
                                           AND sirasgn_term_code = c.periodo
                                           AND sirasgn_crn = crn;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;

                                 BEGIN
                                    INSERT INTO sirasgn
                                         VALUES (c.periodo,
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       NULL;
                                 END;
                              END IF;
                           END IF;

                           conta_ptrm := 0;

                           BEGIN
                              SELECT COUNT (*)
                                INTO conta_ptrm
                                FROM sfbetrm
                               WHERE     1 = 1
                                     AND sfbetrm_term_code = c.periodo
                                     AND sfbetrm_pidm = c.pidm;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 conta_ptrm := 0;
                           END;


                           IF conta_ptrm = 0
                           THEN
                              BEGIN
                                 INSERT INTO sfbetrm
                                      VALUES (c.periodo,
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
                                              NULL);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                       (   'Se presento un error al insertar en la tabla sfbetrm '
                                        || SQLERRM);
                              END;
                           END IF;

                           BEGIN
                              BEGIN
                                 INSERT INTO sfrstcr
                                      VALUES (c.periodo,   --SFRSTCR_TERM_CODE
                                              c.pidm,           --SFRSTCR_PIDM
                                              crn,               --SFRSTCR_CRN
                                              1,      --SFRSTCR_CLASS_SORT_KEY
                                              c.grupo,       --SFRSTCR_REG_SEQ
                                              c.parte,     --SFRSTCR_PTRM_CODE
                                              p_estatus,   --SFRSTCR_RSTS_CODE
                                              SYSDATE,     --SFRSTCR_RSTS_DATE
                                              NULL,       --SFRSTCR_ERROR_FLAG
                                              NULL,          --SFRSTCR_MESSAGE
                                              credit_bill,   --SFRSTCR_BILL_HR
                                              3,             --SFRSTCR_WAIV_HR
                                              credit,      --SFRSTCR_CREDIT_HR
                                              credit_bill, --SFRSTCR_BILL_HR_HOLD
                                              credit, --SFRSTCR_CREDIT_HR_HOLD
                                              gmod,        --SFRSTCR_GMOD_CODE
                                              NULL,        --SFRSTCR_GRDE_CODE
                                              NULL,    --SFRSTCR_GRDE_CODE_MID
                                              NULL,        --SFRSTCR_GRDE_DATE
                                              'N',         --SFRSTCR_DUPL_OVER
                                              'N',         --SFRSTCR_LINK_OVER
                                              'N',         --SFRSTCR_CORQ_OVER
                                              'N',         --SFRSTCR_PREQ_OVER
                                              'N',         --SFRSTCR_TIME_OVER
                                              'N',         --SFRSTCR_CAPC_OVER
                                              'N',         --SFRSTCR_LEVL_OVER
                                              'N',         --SFRSTCR_COLL_OVER
                                              'N',         --SFRSTCR_MAJR_OVER
                                              'N',         --SFRSTCR_CLAS_OVER
                                              'N',         --SFRSTCR_APPR_OVER
                                              'N', --SFRSTCR_APPR_RECEIVED_IND
                                              SYSDATE,      --SFRSTCR_ADD_DATE
                                              SYSDATE, --SFRSTCR_ACTIVITY_DATE
                                              c.nivel,     --SFRSTCR_LEVL_CODE
                                              c.campus,    --SFRSTCR_CAMP_CODE
                                              c.materia, --SFRSTCR_RESERVED_KEY
                                              NULL,        --SFRSTCR_ATTEND_HR
                                              'Y',         --SFRSTCR_REPT_OVER
                                              'N',         --SFRSTCR_RPTH_OVER
                                              NULL,        --SFRSTCR_TEST_OVER
                                              'N',         --SFRSTCR_CAMP_OVER
                                              USER,             --SFRSTCR_USER
                                              'N',         --SFRSTCR_DEGC_OVER
                                              'N',         --SFRSTCR_PROG_OVER
                                              NULL,      --SFRSTCR_LAST_ATTEND
                                              NULL,        --SFRSTCR_GCMT_CODE
                                              'PRONOSTICO', --SFRSTCR_DATA_ORIGIN
                                              SYSDATE, --SFRSTCR_ASSESS_ACTIVITY_DATE
                                              'N',         --SFRSTCR_DEPT_OVER
                                              'N',         --SFRSTCR_ATTS_OVER
                                              'N',         --SFRSTCR_CHRT_OVER
                                              c.grupo,      --SFRSTCR_RMSG_CDE
                                              NULL,      --SFRSTCR_WL_PRIORITY
                                              NULL, --SFRSTCR_WL_PRIORITY_ORIG
                                              NULL, --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                              NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                              'N',         --SFRSTCR_MEXC_OVER
                                              c.study, --SFRSTCR_STSP_KEY_SEQUENCE
                                              NULL,     --SFRSTCR_BRDH_SEQ_NUM
                                              '01',        --SFRSTCR_BLCK_CODE
                                              NULL,       --SFRSTCR_STRH_SEQNO
                                              NULL,       --SFRSTCR_STRD_SEQNO
                                              NULL,     --SFRSTCR_SURROGATE_ID
                                              NULL,          --SFRSTCR_VERSION
                                              USER,          --SFRSTCR_USER_ID
                                              vl_orden     --SFRSTCR_VPDI_CODE
                                                      );
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    -- dbms_output.put_line('Error al insertar SFRSTCR xxx '||sqlerrm);
                                    vl_error :=
                                       (   'Se presento un error al insertar en la tabla SFRSTCR 4 '
                                        || SQLERRM);
                              END;

                              BEGIN
                                 UPDATE SZTPRONO
                                    SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                  WHERE     1 = 1
                                        AND SZTPRONO_NO_REGLA = p_regla
                                        AND SZTPRONO_PIDM = c.pidm
                                        AND sztprono_materia_legal =
                                               c.materia
                                        AND SZTPRONO_ENVIO_HORARIOS = 'N';
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                       (   'Se presento un error al insertar en la tabla SZTPRONO 4 '
                                        || SQLERRM);
                              END;


                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_enrl = ssbsect_enrl + 1
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND SSBSECT_CRN = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar el enrolamiento '
                                       || SQLERRM;
                              END;

                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_seats_avail =
                                           ssbsect_seats_avail - 1
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar la disponibilidad del grupo '
                                       || SQLERRM;
                              END;

                              BEGIN
                                 UPDATE ssbsect
                                    SET ssbsect_census_enrl = ssbsect_enrl
                                  WHERE     1 = 1
                                        AND ssbsect_term_code = c.periodo
                                        AND ssbsect_crn = crn;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al actualizar el Censo del grupo '
                                       || SQLERRM;
                              END;

                              IF C.SGBSTDN_STYP_CODE = 'F'
                              THEN
                                 BEGIN
                                    UPDATE sgbstdn a
                                       SET a.sgbstdn_styp_code = 'N',
                                           a.SGBSTDN_DATA_ORIGIN =
                                              'PRONOSTICO',
                                           A.SGBSTDN_USER_ID = USER
                                     WHERE     1 = 1
                                           AND a.sgbstdn_pidm = c.pidm
                                           AND a.sgbstdn_term_code_eff =
                                                  (SELECT MAX (
                                                             a1.sgbstdn_term_code_eff)
                                                     FROM sgbstdn a1
                                                    WHERE     a1.sgbstdn_pidm =
                                                                 a.sgbstdn_pidm
                                                          AND a1.sgbstdn_program_1 =
                                                                 a.sgbstdn_program_1)
                                           AND a.sgbstdn_program_1 = c.prog;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                          || SQLERRM;
                                 END;
                              END IF;

                              BEGIN
                                 SELECT COUNT (*)
                                   INTO l_cambio_estatus
                                   FROM sfrstcr
                                  WHERE     1 = 1
                                        AND    SFRSTCR_TERM_CODE
                                            || SFRSTCR_PTRM_CODE !=
                                               c.periodo || c.parte
                                        AND SFRSTCR_RSTS_CODE = 'RE'
                                        AND sfrstcr_pidm = c.pidm
                                        AND SFRSTCR_STSP_KEY_SEQUENCE =
                                               c.study;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    l_cambio_estatus := 0;
                              END;


                              IF l_cambio_estatus > 0
                              THEN
                                 IF C.SGBSTDN_STYP_CODE IN ('N', 'R')
                                 THEN
                                    BEGIN
                                       UPDATE sgbstdn a
                                          SET a.sgbstdn_styp_code = 'C',
                                              a.SGBSTDN_DATA_ORIGIN =
                                                 'PRONOSTICO',
                                              A.SGBSTDN_USER_ID = USER
                                        WHERE     1 = 1
                                              AND a.sgbstdn_pidm = c.pidm
                                              AND a.sgbstdn_term_code_eff =
                                                     (SELECT MAX (
                                                                a1.sgbstdn_term_code_eff)
                                                        FROM sgbstdn a1
                                                       WHERE     a1.sgbstdn_pidm =
                                                                    a.sgbstdn_pidm
                                                             AND a1.sgbstdn_program_1 =
                                                                    a.sgbstdn_program_1)
                                              AND a.sgbstdn_program_1 =
                                                     c.prog;
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          vl_error :=
                                                'Se presento un error al actualizar el tipo de alumno en sgbstdn '
                                             || SQLERRM;
                                    END;
                                 END IF;
                              END IF;

                              f_inicio := NULL;

                              BEGIN
                                 SELECT DISTINCT sobptrm_start_date
                                   INTO f_inicio
                                   FROM sobptrm
                                  WHERE     sobptrm_term_code = c.periodo
                                        AND sobptrm_ptrm_code = c.parte;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    f_inicio := NULL;
                                    vl_error :=
                                          'Se presento un error al Obtener la fecha de inicio de Clases periodo '
                                       || c.periodo
                                       || ' parte '
                                       || c.parte
                                       || ' '
                                       || SQLERRM
                                       || ' poe';
                              -- raise_application_error (-20002,vl_error);

                              END;

                              IF f_inicio IS NOT NULL
                              THEN
                                 BEGIN
                                    UPDATE sorlcur
                                       SET sorlcur_start_date =
                                              TRUNC (f_inicio),
                                           sorlcur_data_origin = 'PRONOSTICO',
                                           sorlcur_user_id = USER,
                                           SORLCUR_RATE_CODE = c.rate
                                     WHERE     1 = 1
                                           AND sorlcur_pidm = c.pidm
                                           AND sorlcur_program = c.prog
                                           AND sorlcur_lmod_code = 'LEARNER'
                                           AND sorlcur_key_seqno = c.study;
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al actualizar la fecha de Inicio de Clases en sorlcur '
                                          || SQLERRM;
                                 END;
                              END IF;

                              conta_ptrm := 0;

                              BEGIN
                                 SELECT COUNT (*)
                                   INTO conta_ptrm
                                   FROM sfrareg
                                  WHERE     1 = 1
                                        AND sfrareg_pidm = c.pidm
                                        AND sfrareg_term_code = c.periodo
                                        AND sfrareg_crn = crn
                                        AND sfrareg_extension_number = 0
                                        AND sfrareg_rsts_code = p_estatus;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    conta_ptrm := 0;
                              END;

                              IF conta_ptrm = 0
                              THEN
                                 BEGIN
                                    INSERT INTO sfrareg
                                         VALUES (c.pidm,
                                                 c.periodo,
                                                 crn,
                                                 0,
                                                 p_estatus,
                                                 NVL (f_inicio, pn_fecha),
                                                 NVL (f_fin, SYSDATE),
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
                                                 NULL);
                                 EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                       vl_error :=
                                             'Se presento un error al insertar el registro de la materia para el alumno '
                                          || SQLERRM;
                                 END;
                              END IF;

                              BEGIN
                                 UPDATE SZTPRONO
                                    SET SZTPRONO_ENVIO_HORARIOS = 'S'
                                  WHERE     1 = 1
                                        AND SZTPRONO_NO_REGLA = p_regla
                                        AND SZTPRONO_ENVIO_HORARIOS = 'N'
                                        AND sztprono_materia_legal =
                                               c.materia
                                        AND SZTPRONO_PIDM = c.pidm;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    vl_error :=
                                          'Se presento un error al insertar el registro de la materia en SZTPRONO '
                                       || SQLERRM;
                              END;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un error al insertar al alumno en el grupo3 '
                                    || SQLERRM;
                           END;

                           --l_retorna_dsi:=PKG_FINANZAS_REZA.F_ACTUALIZA_RATE_DSI ( c.iden, c.fecha_inicio );

                           DBMS_OUTPUT.put_line (
                              'mensaje1:' || 'SE creo el grupo :=' || crn);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              vl_error :=
                                    'Se presento un Error al insertar el nuevo grupo 3 crn '
                                 || crn
                                 || ' error '
                                 || SQLERRM;
                        END;
                     END IF;
                  END IF;                             ------ No hay CRN Creado

                  IF vl_error = 'EXITO'
                  THEN
                     COMMIT;                                         --Commit;

                     --dbms_output.put_line('mensaje:'||vl_error);
                     BEGIN
                        INSERT INTO sztcarga
                             VALUES (c.iden,                      --SZCARGA_ID
                                     c.materia,              --SZCARGA_MATERIA
                                     c.prog,                 --SZCARGA_PROGRAM
                                     c.periodo,            --SZCARGA_TERM_CODE
                                     c.parte,              --SZCARGA_PTRM_CODE
                                     c.grupo,                  --SZCARGA_GRUPO
                                     NULL,                     --SZCARGA_CALIF
                                     c.prof,                 --SZCARGA_ID_PROF
                                     USER,                   --SZCARGA_USER_ID
                                     SYSDATE,          --SZCARGA_ACTIVITY_DATE
                                     c.fecha_inicio,       --SZCARGA_FECHA_INI
                                     'P',                    --SZCARGA_ESTATUS
                                     'Horario Generado', --SZCARGA_OBSERVACIONES
                                     'PRON',
                                     p_regla);
                     EXCEPTION
                        WHEN DUP_VAL_ON_INDEX
                        THEN
                           BEGIN
                              UPDATE sztcarga
                                 SET szcarga_estatus = 'P',
                                     szcarga_observaciones =
                                        'Horario Generado',
                                     szcarga_activity_date = SYSDATE
                               WHERE     1 = 1
                                     AND SZCARGA_ID = c.iden
                                     AND SZCARGA_MATERIA = c.materia
                                     AND SZTCARGA_TIPO_PROC = 'MATE'
                                     AND TRUNC (SZCARGA_FECHA_INI) =
                                            c.fecha_inicio;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 VL_ERROR :=
                                       'Se presento un Error al Actualizar la bitacora '
                                    || SQLERRM;
                           END;
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'Se presento un Error al insertar la bitacora '
                              || SQLERRM;
                     END;
                  ELSE
                     DBMS_OUTPUT.put_line ('mensaje:' || vl_error);

                     ROLLBACK;

                     BEGIN
                        INSERT INTO sztcarga
                             VALUES (c.iden,                      --SZCARGA_ID
                                     c.materia,              --SZCARGA_MATERIA
                                     c.prog,                 --SZCARGA_PROGRAM
                                     c.periodo,            --SZCARGA_TERM_CODE
                                     c.parte,              --SZCARGA_PTRM_CODE
                                     c.grupo,                  --SZCARGA_GRUPO
                                     NULL,                     --SZCARGA_CALIF
                                     c.prof,                 --SZCARGA_ID_PROF
                                     USER,                   --SZCARGA_USER_ID
                                     SYSDATE,          --SZCARGA_ACTIVITY_DATE
                                     c.fecha_inicio,       --SZCARGA_FECHA_INI
                                     'E',                    --SZCARGA_ESTATUS
                                     vl_error,         --SZCARGA_OBSERVACIONES
                                     'PRON',
                                     p_regla);

                        COMMIT;
                     EXCEPTION
                        WHEN DUP_VAL_ON_INDEX
                        THEN
                           BEGIN
                              UPDATE sztcarga
                                 SET szcarga_estatus = 'E',
                                     szcarga_observaciones = vl_error,
                                     szcarga_activity_date = SYSDATE
                               WHERE     1 = 1
                                     AND szcarga_id = c.iden
                                     AND szcarga_materia = c.materia
                                     AND sztcarga_tipo_proc = 'MATE'
                                     AND TRUNC (szcarga_fecha_ini) =
                                            c.fecha_inicio;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 vl_error :=
                                       'Se presento un Error al Actualizar la bitacora de Error '
                                    || SQLERRM;
                           END;
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'Se presento un Error al insertar la bitacora de Error '
                              || SQLERRM;
                     END;
                  END IF;
               ELSE
                  vl_error :=
                        'El alumno ya tiene la materia Inscritas en el Periodo:'
                     || period_cur
                     || '. Parte-periodo:'
                     || parteper_cur;

                  BEGIN
                     UPDATE sztprono
                        SET SZTPRONO_ESTATUS_ERROR = 'S',
                            SZTPRONO_DESCRIPCION_ERROR = vl_error
                      WHERE     1 = 1
                            AND SZTPRONO_MATERIA_LEGAL = c.materia
                            AND SZTPRONO_NO_REGLA = P_REGLA
                            AND SZTPRONO_pIDm = c.pidm;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        DBMS_OUTPUT.put_line (
                           ' Error al actualizar ' || SQLERRM);
                  END;

                  COMMIT;

                  -- raise_application_error (-20002,vl_error);

                  BEGIN
                     INSERT INTO sztcarga
                          VALUES (c.iden,                         --SZCARGA_ID
                                  c.materia,                 --SZCARGA_MATERIA
                                  c.prog,                    --SZCARGA_PROGRAM
                                  c.periodo,               --SZCARGA_TERM_CODE
                                  c.parte,                 --SZCARGA_PTRM_CODE
                                  c.grupo,                     --SZCARGA_GRUPO
                                  NULL,                        --SZCARGA_CALIF
                                  c.prof,                    --SZCARGA_ID_PROF
                                  USER,                      --SZCARGA_USER_ID
                                  SYSDATE,             --SZCARGA_ACTIVITY_DATE
                                  c.fecha_inicio,          --SZCARGA_FECHA_INI
                                  'A',                --'P', --SZCARGA_ESTATUS
                                  vl_error,            --SZCARGA_OBSERVACIONES
                                  'PRON',
                                  p_regla);

                     COMMIT;
                  EXCEPTION
                     WHEN DUP_VAL_ON_INDEX
                     THEN
                        BEGIN
                           UPDATE sztcarga
                              SET szcarga_estatus = 'A',               --'P' ,
                                  szcarga_observaciones = vl_error,
                                  szcarga_activity_date = SYSDATE
                            WHERE     1 = 1
                                  AND szcarga_id = c.iden
                                  AND szcarga_materia = c.materia
                                  AND sztcarga_tipo_proc = 'MATE'
                                  AND TRUNC (szcarga_fecha_ini) =
                                         c.fecha_inicio;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              vl_error :=
                                    'Se presento un Error al Actualizar la bitacora de Error '
                                 || SQLERRM;
                        END;
                     WHEN OTHERS
                     THEN
                        vl_error :=
                              'Se presento un Error al insertar la bitacora de Error '
                           || SQLERRM;
                  END;
               END IF;            ----> El alumno ya tiene inscrita la materia
            ELSE
               BEGIN
                  SELECT DECODE (c.sgbstdn_stst_code,
                                 'BT', 'BAJA TEMPORAL',
                                 'BD', 'BAJA TEMPORAL',
                                 'BI', 'BAJA POR INACTIVIDAD',
                                 'CV', 'CANCELACI? DE VENTA',
                                 'CM', 'CANCELACI? DE MATR?ULA',
                                 'CC', 'CAMBIO DE CILO',
                                 'CF', 'CAMBIO DE FECHA',
                                 'CP', 'CAMBIO DE PROGRAMA',
                                 'EG', 'EGRESADO')
                    INTO L_DESCRIPCION_ERROR
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_descripcion_error := 'Sin descripcion';
               END;

               IF L_DESCRIPCION_ERROR IS NULL
               THEN
                  L_DESCRIPCION_ERROR := c.sgbstdn_stst_code;
               END IF;

               BEGIN
                  UPDATE sztprono
                     SET SZTPRONO_ESTATUS_ERROR = 'S',
                         SZTPRONO_DESCRIPCION_ERROR = L_DESCRIPCION_ERROR
                   WHERE     1 = 1
                         AND SZTPRONO_MATERIA_LEGAL = c.materia
                         AND SZTPRONO_NO_REGLA = P_REGLA
                         AND SZTPRONO_PIDM = c.pidm;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     DBMS_OUTPUT.put_line (
                        ' Error al actualizar ' || SQLERRM);
               END;


               vl_error :=
                     'Estatus no validoo para realizar la carga: '
                  || C.SGBSTDN_STST_CODE;

               BEGIN
                  INSERT INTO sztcarga
                       VALUES (c.iden,                            --SZCARGA_ID
                               c.materia,                    --SZCARGA_MATERIA
                               c.prog,                       --SZCARGA_PROGRAM
                               c.periodo,                  --SZCARGA_TERM_CODE
                               c.parte,                    --SZCARGA_PTRM_CODE
                               c.grupo,                        --SZCARGA_GRUPO
                               NULL,                           --SZCARGA_CALIF
                               c.prof,                       --SZCARGA_ID_PROF
                               USER,                         --SZCARGA_USER_ID
                               SYSDATE,                --SZCARGA_ACTIVITY_DATE
                               c.fecha_inicio,             --SZCARGA_FECHA_INI
                               'A',                   --'P', --SZCARGA_ESTATUS
                               vl_error,               --SZCARGA_OBSERVACIONES
                               'PRON',
                               p_regla);

                  COMMIT;
               EXCEPTION
                  WHEN DUP_VAL_ON_INDEX
                  THEN
                     BEGIN
                        UPDATE sztcarga
                           SET szcarga_estatus = 'A',                  --'P' ,
                               szcarga_observaciones = vl_error,
                               szcarga_activity_date = SYSDATE
                         WHERE     1 = 1
                               AND szcarga_id = c.iden
                               AND szcarga_materia = c.materia
                               AND sztcarga_tipo_proc = 'MATE'
                               AND TRUNC (szcarga_fecha_ini) = c.fecha_inicio;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           vl_error :=
                                 'Se presento un Error al Actualizar la bitacora de Error '
                              || SQLERRM;
                     END;
                  WHEN OTHERS
                  THEN
                     vl_error :=
                           'Se presento un Error al insertar la bitacora de Error '
                        || SQLERRM;
               END;
            -- raise_application_error (-20002,'Este alumno '||c.iden||' se encuentra con '||l_descripcion_error);

            END IF;
         --end if;

         END LOOP;

         COMMIT;



         --raise_application_error (-20002,vl_error);
         ------------------- Realiza el proceso de actualizacion de Jornadas ----------------------------------

         BEGIN
            FOR c
               IN (  SELECT SZTPRONO_ID,
                            SZTPRONO_TERM_CODE,
                            SZTPRONO_PTRM_CODE,
                            spriden_pidm,
                            sorlcur_key_seqno,
                            sorlcur_levl_code Nivel,
                            COUNT (*) numero
                       FROM sztprono, spriden, sorlcur s
                      WHERE     1 = 1
                            AND SZTPRONO_ENVIO_MOODL = 'S'
                            AND SZTPRONO_ENVIO_HORARIOS = 'S'
                            AND SZTPRONO_NO_REGLA = p_regla
                            AND SZTPRONO_ID = spriden_id
                            AND spriden_change_ind IS NULL
                            AND s.sorlcur_pidm = spriden_pidm
                            AND s.sorlcur_pidm = p_pidm
                            AND s.sorlcur_program = SZTPRONO_PROGRAM
                            AND s.sorlcur_lmod_code = 'LEARNER'
                            AND s.sorlcur_seqno IN (SELECT MAX (
                                                              ss.sorlcur_seqno)
                                                      FROM sorlcur ss
                                                     WHERE     1 = 1
                                                           AND s.sorlcur_pidm =
                                                                  ss.sorlcur_pidm
                                                           AND s.sorlcur_lmod_code =
                                                                  ss.sorlcur_lmod_code
                                                           AND s.sorlcur_program =
                                                                  ss.sorlcur_program)
                   GROUP BY sorlcur_levl_code,
                            SZTPRONO_ID,
                            SZTPRONO_TERM_CODE,
                            SZTPRONO_PTRM_CODE,
                            spriden_pidm,
                            sorlcur_key_seqno,
                            sorlcur_levl_code
                   ORDER BY 1, 2, 3)
            LOOP
               vl_jornada := NULL;



               BEGIN
                  SELECT DISTINCT SUBSTR (sgrsatt_atts_code, 1, 3) jornada
                    INTO vl_jornada
                    FROM sgrsatt a
                   WHERE     1 = 1
                         AND a.sgrsatt_pidm = c.spriden_pidm
                         AND a.sgrsatt_stsp_key_sequence =
                                c.sorlcur_key_seqno
                         AND SUBSTR (a.sgrsatt_atts_code, 2, 1) =
                                SUBSTR (c.nivel, 1, 1)
                         AND REGEXP_LIKE (a.sgrsatt_atts_code, '^[0-9]')
                         AND a.sgrsatt_term_code_eff =
                                (SELECT MAX (a1.sgrsatt_term_code_eff)
                                   FROM SGRSATT a1
                                  WHERE     1 = 1
                                        AND a.sgrsatt_pidm = a1.sgrsatt_pidm
                                        AND a.sgrsatt_stsp_key_sequence =
                                               a1.sgrsatt_stsp_key_sequence);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vl_jornada := NULL;
               END;

               IF vl_jornada IS NOT NULL
               THEN
                  IF c.numero >= 10
                  THEN
                     c.numero := 4;
                  END IF;

                  vl_jornada := vl_jornada || c.numero;

                  BEGIN
                     pkg_algoritmo.p_actualiza_jornada (c.spriden_pidm,
                                                        c.SZTPRONO_TERM_CODE,
                                                        vl_jornada,
                                                        c.sorlcur_key_seqno);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  END;
               END IF;
            END LOOP;

            COMMIT;
         END;
      ELSE
         vl_error :=
            'Esta Materia presenta Errores No se puede crear el Horario conserva el grupo 00... validar el Error en el Pronostico ';
      END IF;


      COMMIT;

      p_error := vl_error;
   END;

   PROCEDURE p_ajusta_rate (p_regla NUMBER)
   IS
      vl_salida   VARCHAR2 (250) := NULL;
   BEGIN
      FOR c
         IN (WITH numero
                  AS (  SELECT COUNT (*) cantidad,
                               SFRSTCR_PIDM pidm,
                               SFRSTCR_STSP_KEY_SEQUENCE sp
                          FROM sfrstcr
                         WHERE 1 = 1 -- And sfrstcr_pidm = 54510
                               AND SFRSTCR_RSTS_CODE = 'RE'
                      GROUP BY SFRSTCR_PIDM, SFRSTCR_STSP_KEY_SEQUENCE)
               SELECT DISTINCT b.SZTPRONO_ID matricula,
                               a.SZSTUME_START_DATE Fecha_Inicio,
                               a.SZSTUME_NO_REGLA Regla,
                               -- b.SZTPRONO_MATERIA_LEGAL Materia,
                               a.SZSTUME_PIDM,
                               b.SZTPRONO_RATE rate,
                               b.SZTPRONO_TERM_CODE Periodo,
                               b.SZTPRONO_STUDY_PATH Sp,
                               d.cantidad,
                               c.SZTALGO_CAMP_CODE campus,
                               c.SZTALGO_LEVL_CODE Nivel
                 FROM SZSTUME a,
                      sztprono b,
                      SZTALGO c,
                      numero d
                WHERE     a.SZSTUME_NO_REGLA = p_regla
                      AND a.SZSTUME_RSTS_CODE = 'RE'
                      AND a.SZSTUME_STAT_IND = '1'
                      AND a.SZSTUME_SEQ_NO =
                             (SELECT MAX (a1.SZSTUME_SEQ_NO)
                                FROM SZSTUME a1
                               WHERE     1 = 1
                                     AND a.SZSTUME_TERM_NRC =
                                            a1.SZSTUME_TERM_NRC
                                     AND a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                     AND a.SZSTUME_STAT_IND =
                                            a1.SZSTUME_STAT_IND
                                     AND a.SZSTUME_RSTS_CODE =
                                            a1.SZSTUME_RSTS_CODE
                                     AND a.SZSTUME_NO_REGLA =
                                            a1.SZSTUME_NO_REGLA)
                      AND b.SZTPRONO_PIDM = a.SZSTUME_PIDM
                      AND b.SZTPRONO_NO_REGLA = a.SZSTUME_NO_REGLA
                      AND SZTPRONO_MATERIA_LEGAL = SZSTUME_SUBJ_CODE_COMP
                      AND b.SZTPRONO_ENVIO_MOODL = 'S'
                      AND b.SZTPRONO_ENVIO_HORARIOS = 'S'
                      AND c.SZTALGO_NO_REGLA = a.SZSTUME_NO_REGLA
                      AND SZTALGO_ESTATUS_CERRADO = 'S'
                      AND SUBSTR (b.SZTPRONO_RATE, 3, 1) = 3
                      AND SUBSTR (b.SZTPRONO_RATE, 1, 1) != 'P'
                      AND b.SZTPRONO_PIDM = d.pidm
                      AND b.SZTPRONO_STUDY_PATH = d.sp
                      AND d.cantidad >= 4
             -- And SZTPRONO_ID ='010196324'
             --and SZSTUME_TERM_NRC = 'L3HE40101'
             ORDER BY 3)
      LOOP
         BEGIN
            vl_salida :=
               PKG_FINANZAS.F_ACTUALIZA_RATE (c.SZSTUME_PIDM,
                                              c.periodo,
                                              c.rate,
                                              c.sp,
                                              c.regla);
            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END LOOP;
   END p_ajusta_rate;

   --
   PROCEDURE p_ajusta_tipo_F (p_regla NUMBER)
   IS
   BEGIN
      FOR c
         IN (SELECT DISTINCT a.SZSTUME_START_DATE Fecha_Inicio,
                             a.SZSTUME_NO_REGLA Regla,
                             a.SZSTUME_PIDM Pidm,
                             b.SZTPRONO_PROGRAM programa
               FROM SZSTUME a, sztprono b, AS_ALUMNOS d
              WHERE     a.SZSTUME_NO_REGLA = p_regla --:BUTTON_CONTROL_BLOCK.regla
                    AND a.SZSTUME_RSTS_CODE = 'RE'
                    AND a.SZSTUME_STAT_IND = '1'
                    AND a.SZSTUME_SEQ_NO =
                           (SELECT MAX (a1.SZSTUME_SEQ_NO)
                              FROM SZSTUME a1
                             WHERE     1 = 1
                                   AND a.SZSTUME_TERM_NRC =
                                          a1.SZSTUME_TERM_NRC
                                   AND a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                   AND a.SZSTUME_STAT_IND =
                                          a1.SZSTUME_STAT_IND
                                   AND a.SZSTUME_RSTS_CODE =
                                          a1.SZSTUME_RSTS_CODE
                                   AND a.SZSTUME_NO_REGLA =
                                          a1.SZSTUME_NO_REGLA)
                    AND b.SZTPRONO_PIDM = a.SZSTUME_PIDM
                    AND b.SZTPRONO_NO_REGLA = a.SZSTUME_NO_REGLA
                    AND SZTPRONO_MATERIA_LEGAL = SZSTUME_SUBJ_CODE_COMP
                    AND b.SZTPRONO_ENVIO_MOODL = 'S'
                    AND b.SZTPRONO_ENVIO_HORARIOS = 'S'
                    AND d.AS_ALUMNOS_NO_REGLA = a.SZSTUME_NO_REGLA
                    AND d.SGBSTDN_PIDM = b.SZTPRONO_PIDM
                    AND d.AS_ALUMNOS_TYPE_CODE = 'F')
      LOOP
         BEGIN
            UPDATE sgbstdn a
               SET a.sgbstdn_styp_code = 'N',
                   a.SGBSTDN_DATA_ORIGIN = 'PRONOSTICO',
                   A.SGBSTDN_USER_ID = USER
             WHERE     1 = 1
                   AND a.sgbstdn_pidm = c.pidm
                   AND a.sgbstdn_styp_code IN ('F')
                   AND a.sgbstdn_term_code_eff =
                          (SELECT MAX (a1.sgbstdn_term_code_eff)
                             FROM sgbstdn a1
                            WHERE     a1.sgbstdn_pidm = a.sgbstdn_pidm
                                  AND a1.sgbstdn_program_1 =
                                         a.sgbstdn_program_1
                                  AND a1.sgbstdn_styp_code =
                                         a.sgbstdn_styp_code)
                   AND a.sgbstdn_program_1 = c.programa;
         EXCEPTION
            WHEN OTHERS
            THEN
               -- vl_error := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
               NULL;
         END;


         BEGIN
            UPDATE AS_ALUMNOS
               SET AS_ALUMNOS_TYPE_CODE = 'C'
             WHERE     1 = 1
                   AND SGBSTDN_PIDM = c.pidm
                   AND AS_ALUMNOS_NO_REGLA = c.regla
                   AND AS_ALUMNOS_TYPE_CODE = 'F';
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;


         BEGIN
            UPDATE tztprog
               SET SGBSTDN_STYP_CODE = 'N'
             WHERE pidm = c.pidm AND SGBSTDN_STYP_CODE = 'F';
         -- And PROGRAMA = c.programa;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END LOOP;
   END p_ajusta_tipo_F;


   PROCEDURE p_ajusta_tipo_N_R (p_regla NUMBER)
   IS
   BEGIN
      FOR c
         IN (WITH numero
                  AS (  SELECT COUNT (DISTINCT SFRSTCR_PTRM_CODE) cantidad,
                               SFRSTCR_PIDM pidm,
                               SFRSTCR_STSP_KEY_SEQUENCE sp
                          FROM sfrstcr
                         WHERE 1 = 1 -- And sfrstcr_pidm = 42519
                               AND SFRSTCR_RSTS_CODE = 'RE'
                      GROUP BY SFRSTCR_PIDM, SFRSTCR_STSP_KEY_SEQUENCE)
               SELECT DISTINCT b.SZTPRONO_ID matricula,
                               a.SZSTUME_NO_REGLA Regla,
                               a.SZSTUME_PIDM pidm,
                               d.cantidad,
                               SZTPRONO_PROGRAM Programa
                 FROM SZSTUME a,
                      sztprono b,
                      numero d,
                      AS_ALUMNOS c
                WHERE     a.SZSTUME_NO_REGLA = p_regla
                      AND a.SZSTUME_RSTS_CODE = 'RE'
                      AND a.SZSTUME_STAT_IND = '1'
                      AND a.SZSTUME_SEQ_NO =
                             (SELECT MAX (a1.SZSTUME_SEQ_NO)
                                FROM SZSTUME a1
                               WHERE     1 = 1
                                     AND a.SZSTUME_TERM_NRC =
                                            a1.SZSTUME_TERM_NRC
                                     AND a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                     AND a.SZSTUME_STAT_IND =
                                            a1.SZSTUME_STAT_IND
                                     AND a.SZSTUME_RSTS_CODE =
                                            a1.SZSTUME_RSTS_CODE
                                     AND a.SZSTUME_NO_REGLA =
                                            a1.SZSTUME_NO_REGLA)
                      AND b.SZTPRONO_PIDM = a.SZSTUME_PIDM
                      AND b.SZTPRONO_NO_REGLA = a.SZSTUME_NO_REGLA
                      AND SZTPRONO_MATERIA_LEGAL = SZSTUME_SUBJ_CODE_COMP
                      AND b.SZTPRONO_ENVIO_MOODL = 'S'
                      AND b.SZTPRONO_ENVIO_HORARIOS = 'S'
                      AND b.SZTPRONO_PIDM = d.pidm
                      AND b.SZTPRONO_STUDY_PATH = d.sp
                      AND d.cantidad >= 2
                      AND c.AS_ALUMNOS_NO_REGLA = a.SZSTUME_NO_REGLA
                      AND c.SGBSTDN_PIDM = b.SZTPRONO_PIDM
                      AND c.AS_ALUMNOS_TYPE_CODE IN ('N', 'R')
             -- And SZTPRONO_ID ='010196324'
             --and SZSTUME_TERM_NRC = 'L3HE40101'
             ORDER BY 3)
      LOOP
         IF c.cantidad >= 2
         THEN
            BEGIN
               UPDATE sgbstdn a
                  SET a.sgbstdn_styp_code = 'C',
                      a.SGBSTDN_DATA_ORIGIN = 'PRONOSTICO',
                      A.SGBSTDN_USER_ID = USER
                WHERE     1 = 1
                      AND a.sgbstdn_pidm = c.pidm
                      AND a.sgbstdn_styp_code IN ('R', 'N')
                      AND a.sgbstdn_term_code_eff =
                             (SELECT MAX (a1.sgbstdn_term_code_eff)
                                FROM sgbstdn a1
                               WHERE     a1.sgbstdn_pidm = a.sgbstdn_pidm
                                     AND a1.sgbstdn_program_1 =
                                            a.sgbstdn_program_1
                                     AND a1.sgbstdn_styp_code =
                                            a.sgbstdn_styp_code)
                      AND a.sgbstdn_program_1 = c.programa;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            --vl_error := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
            END;


            BEGIN
               UPDATE AS_ALUMNOS
                  SET AS_ALUMNOS_TYPE_CODE = 'C'
                WHERE     1 = 1
                      AND SGBSTDN_PIDM = c.pidm
                      AND AS_ALUMNOS_NO_REGLA = c.regla
                      AND AS_ALUMNOS_TYPE_CODE IN ('R', 'N');
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

            BEGIN
               UPDATE tztprog
                  SET SGBSTDN_STYP_CODE = 'C'
                WHERE pidm = c.pidm AND SGBSTDN_STYP_CODE IN ('R', 'N');
            --And PROGRAMA = c.programa;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;
         END IF;
      END LOOP;
   END p_ajusta_tipo_N_R;

   --
   --
   PROCEDURE p_job_ec (p_sysdate DATE)
   IS
      l_fecha_inicio         DATE := TRUNC (SYSDATE);
      l_cuenta_grupo         NUMBER;
      l_cuenta_prof          NUMBER;
      l_cuenta_alumno        NUMBER;
      l_valida               VARCHAR2 (10) := 'EXITO';
      l_secuencia_anterior   NUMBER;
      l_califiacion          VARCHAR2 (4);
      l_acredita             VARCHAR2 (1);
      l_fecha_final          DATE;
      l_dias_gracia          NUMBER;
      l_fecha                DATE;
      l_cuenta_otro          NUMBER;
      l_fecha_correcta       DATE;
      l_contador             NUMBER;
      l_fecha_menor          DATE;
      l_secuencia_menor      NUMBER;
      l_fecha_fuera          DATE;
      l_baja_abcc            VARCHAR2 (200);
   BEGIN
      BEGIN
         SELECT DISTINCT zstpara_param_valor
           INTO l_dias_gracia
           FROM zstpara
          WHERE 1 = 1 AND zstpara_mapa_id = 'PRONO_DAY';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_dias_gracia := 0;
      END;

      -- obtenemos las fechas para el proceso la regla es que son 48 hrs para bajar calificaciones
      l_fecha_inicio := TRUNC (p_sysdate);
      --l_fecha_final:= l_fecha_inicio+ l_dias_gracia;


      DBMS_OUTPUT.put_line (' Fecha hoy ' || l_fecha_inicio);

      -- dbms_output.put_line(' Fecha hoy '||l_fecha_inicio||' Dias gracia '||l_dias_gracia||' Fecha final '||l_fecha_final);

      FOR c
         IN (SELECT DISTINCT sztalgo_no_regla regla
               FROM sztalgo A
              WHERE     1 = 1
                    AND sztalgo_camp_code IN ('UTS', 'EAF')
                    AND sztalgo_levl_code = 'EC'
                    AND sztalgo_estatus_cerrado = 'S'
                    AND EXISTS
                           (SELECT NULL
                              FROM sztgpme b
                             WHERE     1 = 1
                                   AND a.sztalgo_no_regla =
                                          b.sztgpme_no_regla))
      LOOP
         DBMS_OUTPUT.put_line (
               ' Fecha hoy '
            || l_fecha_inicio
            || ' Dias gracia '
            || l_dias_gracia
            || ' Fecha final '
            || l_fecha_final);

         FOR x IN 1 .. l_dias_gracia
         LOOP
            l_fecha := l_fecha_inicio - x;

            BEGIN
               SELECT COUNT (*)
                 INTO l_cuenta_otro
                 FROM sztgpme
                WHERE     1 = 1
                      AND sztgpme_no_regla = c.regla
                      AND sztgpme_start_date BETWEEN l_fecha
                                                 AND l_fecha_inicio
                      AND sztgpme_secuencia > 1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

            l_contador := 0;

            IF l_cuenta_otro > 0
            THEN
               DBMS_OUTPUT.put_line (' Entra a cuenta otro ');

               -- se evalua la fecha aa ver si encontramos una para poder anclar el proceso JOB
               BEGIN
                  SELECT DISTINCT sztgpme_start_date
                    INTO l_fecha_correcta
                    FROM sztgpme
                   WHERE     1 = 1
                         AND sztgpme_no_regla = c.regla
                         AND sztgpme_start_date BETWEEN l_fecha
                                                    AND l_fecha_inicio
                         AND sztgpme_secuencia > 1;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;


               -- cursor para mandar a los grupos cuando no esten sincronizados
               FOR d
                  IN (SELECT *
                        FROM sztgpme
                       WHERE     1 = 1
                             AND sztgpme_no_regla = c.regla
                             AND sztgpme_start_date = l_fecha_correcta
                             AND sztgpme_stat_ind = '5'
                             AND sztgpme_secuencia > 1)
               LOOP
                  l_secuencia_anterior := d.sztgpme_secuencia - 1;

                  BEGIN
                     UPDATE sztgpme
                        SET sztgpme_stat_ind = '0'
                      WHERE     1 = 1
                            AND sztgpme_no_regla = d.sztgpme_no_regla
                            AND sztgpme_term_nrc = d.sztgpme_term_nrc
                            AND sztgpme_start_date = d.sztgpme_start_date
                            AND sztgpme_nive_seqno = d.sztgpme_nive_seqno;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  END;

                  BEGIN
                     SELECT COUNT (*)
                       INTO l_cuenta_prof
                       FROM SZSGNME
                      WHERE     1 = 1
                            AND szsgnme_no_regla = d.sztgpme_no_regla
                            AND szsgnme_term_nrc = d.sztgpme_term_nrc
                            AND szsgnme_start_date = d.sztgpme_start_date
                            AND szsgnme_nive_seqno = d.sztgpme_nive_seqno
                            AND szsgnme_stat_ind = '5';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  END;

                  IF l_cuenta_prof > 0
                  THEN
                     BEGIN
                        UPDATE szsgnme
                           SET szsgnme_stat_ind = '0'
                         WHERE     1 = 1
                               AND szsgnme_no_regla = d.sztgpme_no_regla
                               AND szsgnme_term_nrc = d.sztgpme_term_nrc
                               AND szsgnme_start_date = d.sztgpme_start_date
                               AND szsgnme_nive_seqno = d.sztgpme_nive_seqno;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           NULL;
                     END;
                  END IF;

                  BEGIN
                     SELECT COUNT (*)
                       INTO l_cuenta_alumno
                       FROM szstume
                      WHERE     1 = 1
                            AND szstume_no_regla = d.sztgpme_no_regla
                            AND szstume_term_nrc = d.sztgpme_term_nrc
                            AND szstume_start_date = d.sztgpme_start_date
                            AND szstume_nive_seqno = d.sztgpme_nive_seqno;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  END;

                  IF l_cuenta_alumno > 0
                  THEN
                     FOR x
                        IN (SELECT ume.*,
                                   get_crn_regla (ume.szstume_pidm,
                                                  NULL,
                                                  ume.szstume_subj_code,
                                                  ume.szstume_no_regla)
                                      crn,
                                   (SELECT DISTINCT sztprono_term_code
                                      FROM sztprono
                                     WHERE     1 = 1
                                           AND sztprono_no_regla =
                                                  ume.szstume_no_regla
                                           AND sztprono_pidm =
                                                  ume.szstume_pidm
                                           AND ROWNUM = 1)
                                      term_code
                              FROM szstume ume
                             WHERE     1 = 1
                                   AND szstume_no_regla = d.sztgpme_no_regla
                                   AND szstume_no_regla = d.sztgpme_no_regla
                                   AND szstume_nive_seqno =
                                          d.sztgpme_nive_seqno
                                   AND szstume_term_nrc = d.sztgpme_term_nrc
                                   AND szstume_rsts_code = 'RE')
                     LOOP
                        BEGIN
                           SELECT DISTINCT
                                  DECODE (szstume_grde_code_final,
                                          '0', NULL,
                                          szstume_grde_code_final)
                                     calif
                             INTO l_califiacion
                             FROM szstume
                            WHERE     1 = 1
                                  AND szstume_no_regla = x.szstume_no_regla
                                  AND szstume_pidm = szstume_pidm
                                  AND szstume_secuencia =
                                         l_secuencia_anterior;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        BEGIN
                           SELECT shrgrde_passed_ind
                             INTO l_acredita
                             FROM shrgrde
                            WHERE     1 = 1
                                  AND shrgrde_levl_code = 'EC'
                                  AND shrgrde_code = l_califiacion;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                              l_acredita := NULL;
                        END;

                        DBMS_OUTPUT.put_line (
                              ' Contar grupo '
                           || l_cuenta_grupo
                           || ' Cuenta Prof '
                           || l_cuenta_prof
                           || ' Cuenta Alumno '
                           || l_cuenta_alumno
                           || ' Secuencia grupo '
                           || d.sztgpme_secuencia
                           || ' anterior '
                           || l_secuencia_anterior
                           || ' califica anterior '
                           || l_califiacion
                           || ' Acredita '
                           || l_acredita
                           || ' Crn '
                           || x.crn);

                        IF l_acredita IS NULL
                        THEN
                           NULL;
                        ELSIF l_acredita = 'Y'
                        THEN
                           BEGIN
                              UPDATE szstume
                                 SET szstume_stat_ind = '0'
                               WHERE     1 = 1
                                     AND szstume_no_regla =
                                            x.szstume_no_regla
                                     AND szstume_pidm = x.szstume_pidm
                                     AND szstume_secuencia =
                                            d.sztgpme_secuencia
                                     AND szstume_stat_ind = '5';
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        ELSIF l_acredita = 'N'
                        THEN
                           --Proceso para dar debaja si se reprueba

                           BEGIN
                              UPDATE szstume
                                 SET SZSTUME_STAT_IND = '2',
                                     SZSTUME_OBS =
                                        'Este registro se encuentra cocmo dado de Baja'
                               WHERE     1 = 1
                                     AND szstume_no_regla =
                                            x.szstume_no_regla
                                     AND szstume_pidm = x.szstume_pidm
                                     AND szstume_secuencia >
                                            l_secuencia_anterior;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;

                           BEGIN
                              UPDATE sztprono
                                 SET sztprono_estatus_error = 'S',
                                     sztprono_descripcion_error =
                                        'Este registro se encuentra cocmo dado de Baja'
                               WHERE     1 = 1
                                     AND sztprono_no_regla =
                                            x.szstume_no_regla
                                     AND sztprono_pidm = x.szstume_pidm
                                     AND sztprono_secuencia >
                                            l_secuencia_anterior;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;

                           BEGIN
                              UPDATE sfrstcr
                                 SET SFRSTCR_RSTS_CODE = 'DD',
                                     SFRSTCR_DATA_ORIGIN = 'REPROBO',
                                     SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                     SFRSTCR_USER = USER
                               WHERE     1 = 1
                                     AND sfrstcr_term_code = x.term_code
                                     -- and sfrstcr_crn = x.crn
                                     AND sfrstcr_pidm = x.szstume_pidm
                                     AND SFRSTCR_GRDE_CODE IS NULL;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;

                           l_contador := 0;

                           FOR s
                              IN (SELECT DISTINCT
                                         SZTPRONO_STUDY_PATH, SZTPRONO_pidm
                                    FROM sztprono
                                   WHERE     1 = 1
                                         AND sztprono_no_regla =
                                                x.szstume_no_regla
                                         AND sztprono_pidm = x.szstume_pidm-- and sztprono_materia_legal = x.szstume_subj_code
                                 )
                           LOOP
                              l_contador := l_contador + 1;

                              l_baja_abcc :=
                                 PKG_ABCC.f_monetos_abcc (
                                    'CAMBIO_ETSTAUS',
                                    s.SZTPRONO_STUDY_PATH,
                                    s.SZTPRONO_pidm,
                                    'BD',
                                    USER);

                              IF l_baja_abcc = 'EXITO'
                              THEN
                                 -- DELETE SGRSCMT
                                 -- WHERE 1 = 1
                                 -- AND SGRSCMT_SEQ_NO <> 1
                                 -- AND SGRSCMT_PIDM = S.SZTPRONO_pidm;
                                 --
                                 COMMIT;
                              ELSE
                                 ROLLBACK;
                              END IF;

                              EXIT WHEN l_contador = 1;
                           END LOOP;
                        END IF;
                     END LOOP;
                  END IF;
               END LOOP;

               FOR d
                  IN (SELECT *
                        FROM sztgpme
                       WHERE     1 = 1
                             AND sztgpme_no_regla = c.regla
                             AND sztgpme_start_date = l_fecha_correcta
                             AND sztgpme_stat_ind IN ('0', '1')
                             AND sztgpme_secuencia > 1)
               LOOP
                  DBMS_OUTPUT.put_line (
                        'Entra a proceso GRUPO d.secuencia '
                     || d.sztgpme_secuencia);
                  l_secuencia_anterior := d.sztgpme_secuencia - 1;

                  BEGIN
                     SELECT COUNT (*)
                       INTO l_cuenta_alumno
                       FROM szstume
                      WHERE     1 = 1
                            AND szstume_no_regla = d.sztgpme_no_regla
                            AND szstume_term_nrc = d.sztgpme_term_nrc
                            AND szstume_start_date = d.sztgpme_start_date
                            AND szstume_nive_seqno = d.sztgpme_nive_seqno
                            AND szstume_stat_ind = '5';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  END;

                  IF l_cuenta_alumno > 0
                  THEN
                     DBMS_OUTPUT.put_line ('Entra a proceso GRUPO 2');

                     FOR x
                        IN (SELECT ume.*,
                                   get_crn_regla (ume.szstume_pidm,
                                                  NULL,
                                                  ume.szstume_subj_code,
                                                  ume.szstume_no_regla)
                                      crn,
                                   (SELECT DISTINCT sztprono_term_code
                                      FROM sztprono
                                     WHERE     1 = 1
                                           AND sztprono_no_regla =
                                                  ume.szstume_no_regla
                                           AND sztprono_pidm =
                                                  ume.szstume_pidm
                                           AND ROWNUM = 1)
                                      term_code
                              FROM szstume ume
                             WHERE     1 = 1
                                   AND szstume_no_regla = d.sztgpme_no_regla
                                   AND szstume_no_regla = d.sztgpme_no_regla
                                   AND szstume_nive_seqno =
                                          d.sztgpme_nive_seqno
                                   AND szstume_term_nrc = d.sztgpme_term_nrc
                                   AND szstume_rsts_code = 'RE'
                                   AND szstume_stat_ind = '5')
                     LOOP
                        DBMS_OUTPUT.put_line (
                              'Entra a proceso regla '
                           || x.szstume_no_regla
                           || ' Califica '
                           || l_secuencia_anterior);

                        BEGIN
                           SELECT DISTINCT
                                  DECODE (szstume_grde_code_final,
                                          '0', NULL,
                                          szstume_grde_code_final)
                                     calif
                             INTO l_califiacion
                             FROM szstume
                            WHERE     1 = 1
                                  AND szstume_no_regla = x.szstume_no_regla
                                  AND szstume_pidm = x.szstume_pidm
                                  AND szstume_secuencia =
                                         l_secuencia_anterior;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;


                        DBMS_OUTPUT.put_line (
                              'Calificacion '
                           || l_califiacion
                           || ' Secuencia anterior '
                           || l_secuencia_anterior);

                        BEGIN
                           SELECT shrgrde_passed_ind
                             INTO l_acredita
                             FROM shrgrde
                            WHERE     1 = 1
                                  AND shrgrde_levl_code = 'EC'
                                  AND shrgrde_code = l_califiacion;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              DBMS_OUTPUT.put_line (
                                    'Error--> '
                                 || SQLERRM
                                 || ' Califica '
                                 || l_califiacion);
                              l_acredita := NULL;
                        END;

                        --
                        -- dbms_output.put_line(' Contar grupo '||l_cuenta_grupo||
                        -- ' Cuenta Prof '||l_cuenta_prof||
                        -- ' Cuenta Alumno '||l_cuenta_alumno||
                        -- ' Secuencia grupo '||d.sztgpme_secuencia||
                        -- ' anterior '||l_secuencia_anterior||
                        -- ' califica anterior '||l_califiacion||
                        -- ' Acredita '||l_acredita||
                        -- ' Crn '||x.crn);

                        IF l_acredita IS NULL
                        THEN
                           NULL;
                        ELSIF l_acredita = 'Y'
                        THEN
                           BEGIN
                              UPDATE szstume
                                 SET szstume_stat_ind = '0'
                               WHERE     1 = 1
                                     AND szstume_no_regla =
                                            x.szstume_no_regla
                                     AND szstume_pidm = x.szstume_pidm
                                     AND szstume_secuencia =
                                            d.sztgpme_secuencia
                                     AND szstume_stat_ind = '5';
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;
                        ELSIF l_acredita = 'N'
                        THEN
                           BEGIN
                              UPDATE szstume
                                 SET SZSTUME_STAT_IND = '2',
                                     SZSTUME_OBS =
                                        'Este registro se encuentra como dado de Baja',
                                     SZSTUME_RSTS_CODE = 'DD'
                               WHERE     1 = 1
                                     AND szstume_no_regla =
                                            x.szstume_no_regla
                                     AND szstume_pidm = x.szstume_pidm
                                     AND szstume_secuencia >
                                            l_secuencia_anterior;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;

                           BEGIN
                              UPDATE sztprono
                                 SET sztprono_estatus_error = 'S',
                                     sztprono_descripcion_error =
                                        'Este registro se encuentra cocmo dado de Baja'
                               WHERE     1 = 1
                                     AND sztprono_no_regla =
                                            x.szstume_no_regla
                                     AND sztprono_pidm = x.szstume_pidm
                                     AND sztprono_secuencia >
                                            l_secuencia_anterior;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;

                           BEGIN
                              UPDATE sfrstcr
                                 SET SFRSTCR_RSTS_CODE = 'DD',
                                     SFRSTCR_DATA_ORIGIN = 'REPROBO',
                                     SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                     SFRSTCR_USER = USER
                               WHERE     1 = 1
                                     AND sfrstcr_term_code = x.term_code
                                     -- and sfrstcr_crn = x.crn
                                     AND sfrstcr_pidm = x.szstume_pidm
                                     AND SFRSTCR_GRDE_CODE IS NULL;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 NULL;
                           END;


                           l_contador := 0;

                           FOR s
                              IN (SELECT DISTINCT
                                         SZTPRONO_STUDY_PATH, SZTPRONO_pidm
                                    FROM sztprono
                                   WHERE     1 = 1
                                         AND sztprono_no_regla =
                                                x.szstume_no_regla
                                         AND sztprono_pidm = x.szstume_pidm-- and sztprono_materia_legal = x.szstume_subj_code
                                 )
                           LOOP
                              l_contador := l_contador + 1;

                              l_baja_abcc :=
                                 PKG_ABCC.f_monetos_abcc (
                                    'CAMBIO_ETSTAUS',
                                    s.SZTPRONO_STUDY_PATH,
                                    s.SZTPRONO_pidm,
                                    'BD',
                                    USER);

                              IF l_baja_abcc = 'EXITO'
                              THEN
                                 -- DELETE SGRSCMT
                                 -- WHERE 1 = 1
                                 -- AND SGRSCMT_SEQ_NO > 2
                                 -- AND SGRSCMT_PIDM = S.SZTPRONO_pidm;

                                 COMMIT;
                              ELSE
                                 ROLLBACK;
                              END IF;


                              DBMS_OUTPUT.put_line ('Prono ' || l_contador);

                              EXIT WHEN l_contador = 1;
                           END LOOP;
                        END IF;
                     END LOOP;
                  END IF;
               END LOOP;
            ELSE
               l_contador := l_contador + 1;

               BEGIN
                  SELECT DISTINCT a.szstume_secuencia, a.szstume_start_date
                    INTO l_secuencia_menor, l_fecha_menor
                    FROM szstume a
                   WHERE     1 = 1
                         AND a.SZSTUME_RSTS_CODE = 'RE'
                         AND a.szstume_no_regla = c.regla
                         AND a.SZSTUME_STAT_IND = '5'
                         AND a.szstume_secuencia =
                                (SELECT MIN (b.szstume_secuencia)
                                   FROM szstume b
                                  WHERE     1 = 1
                                        AND b.SZSTUME_RSTS_CODE =
                                               a.SZSTUME_RSTS_CODE
                                        AND b.szstume_no_regla =
                                               a.szstume_no_regla
                                        AND b.SZSTUME_STAT_IND =
                                               a.SZSTUME_STAT_IND);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;

               l_fecha_fuera := l_fecha_menor + l_dias_gracia;

               IF l_fecha_fuera < l_fecha_inicio
               THEN
                  FOR w
                     IN (SELECT ume.*,
                                get_crn_regla (ume.szstume_pidm,
                                               NULL,
                                               ume.szstume_subj_code,
                                               ume.szstume_no_regla)
                                   crn,
                                (SELECT DISTINCT sztprono_term_code
                                   FROM sztprono
                                  WHERE     1 = 1
                                        AND sztprono_no_regla =
                                               ume.szstume_no_regla
                                        AND sztprono_pidm = ume.szstume_pidm
                                        AND ROWNUM = 1)
                                   term_code
                           FROM szstume ume
                          WHERE     1 = 1
                                AND szstume_no_regla = c.regla
                                AND szstume_secuencia = l_secuencia_menor)
                  LOOP
                     DBMS_OUTPUT.put_line (
                        ' Calificacion ' || w.szstume_grde_code_final);

                     IF    w.szstume_grde_code_final = '0'
                        OR w.szstume_grde_code_final IS NULL
                     THEN
                        DBMS_OUTPUT.put_line (' entra 1 ');

                        BEGIN
                           UPDATE szstume
                              SET SZSTUME_STAT_IND = '2',
                                  SZSTUME_OBS =
                                     'Este registro no tiene la calificacion en tiempo y forma',
                                  SZSTUME_RSTS_CODE = 'DD'
                            WHERE     1 = 1
                                  AND szstume_no_regla = w.szstume_no_regla
                                  AND szstume_pidm = w.szstume_pidm
                                  AND szstume_secuencia >= l_secuencia_menor;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        BEGIN
                           UPDATE sztprono
                              SET sztprono_estatus_error = 'S',
                                  sztprono_descripcion_error =
                                     'Este registro no tiene la calificacion en tiempo y forma'
                            WHERE     1 = 1
                                  AND sztprono_no_regla = w.szstume_no_regla
                                  AND sztprono_pidm = w.szstume_pidm
                                  AND sztprono_secuencia >= l_secuencia_menor;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        BEGIN
                           UPDATE sfrstcr
                              SET SFRSTCR_RSTS_CODE = 'DD',
                                  SFRSTCR_DATA_ORIGIN = 'REPROBO',
                                  SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                  SFRSTCR_USER = USER
                            WHERE     1 = 1
                                  AND sfrstcr_term_code = w.term_code
                                  -- and sfrstcr_crn = w.crn
                                  AND sfrstcr_pidm = w.szstume_pidm
                                  AND SFRSTCR_GRDE_CODE IS NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        l_contador := 0;

                        FOR s
                           IN (SELECT DISTINCT
                                      SZTPRONO_STUDY_PATH, SZTPRONO_pidm
                                 FROM sztprono
                                WHERE     1 = 1
                                      AND sztprono_no_regla =
                                             w.szstume_no_regla
                                      AND sztprono_pidm = w.szstume_pidm-- and sztprono_materia_legal = w.szstume_subj_code
                              )
                        LOOP
                           l_contador := l_contador + 1;

                           l_baja_abcc :=
                              PKG_ABCC.f_monetos_abcc ('CAMBIO_ETSTAUS',
                                                       s.SZTPRONO_STUDY_PATH,
                                                       s.SZTPRONO_pidm,
                                                       'BD',
                                                       USER);

                           IF l_baja_abcc = 'EXITO'
                           THEN
                              --
                              -- DELETE SGRSCMT
                              -- WHERE 1 = 1
                              -- AND SGRSCMT_SEQ_NO <> 1
                              -- AND SGRSCMT_PIDM = S.SZTPRONO_pidm;
                              COMMIT;
                           ELSE
                              ROLLBACK;
                           END IF;

                           DBMS_OUTPUT.put_line ('Prono ' || l_contador);

                           EXIT WHEN l_contador = 1;
                        END LOOP;
                     ELSE
                        DBMS_OUTPUT.put_line (' entra 1 ');

                        BEGIN
                           UPDATE szstume
                              SET SZSTUME_STAT_IND = '2',
                                  SZSTUME_OBS =
                                        'Este registro no se le bajo la calificacion '
                                     || w.szstume_grde_code_final
                                     || ' En tiempo',
                                  SZSTUME_RSTS_CODE = 'DD'
                            WHERE     1 = 1
                                  AND szstume_no_regla = w.szstume_no_regla
                                  AND szstume_pidm = w.szstume_pidm
                                  AND szstume_secuencia >= l_secuencia_menor;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        BEGIN
                           UPDATE sztprono
                              SET sztprono_estatus_error = 'S',
                                  sztprono_descripcion_error =
                                        'Este registro no se le bajo la calificacion '
                                     || w.szstume_grde_code_final
                                     || ' En tiempo'
                            WHERE     1 = 1
                                  AND sztprono_no_regla = w.szstume_no_regla
                                  AND sztprono_pidm = w.szstume_pidm
                                  AND sztprono_secuencia >= l_secuencia_menor;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        BEGIN
                           UPDATE sfrstcr
                              SET SFRSTCR_RSTS_CODE = 'DD',
                                  SFRSTCR_DATA_ORIGIN = 'REPROBO',
                                  SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                  SFRSTCR_USER = USER
                            WHERE     1 = 1
                                  AND sfrstcr_term_code = w.term_code
                                  -- and sfrstcr_crn = w.crn
                                  AND sfrstcr_pidm = w.szstume_pidm
                                  AND SFRSTCR_GRDE_CODE IS NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              NULL;
                        END;

                        l_contador := 0;

                        FOR s
                           IN (SELECT DISTINCT
                                      SZTPRONO_STUDY_PATH, SZTPRONO_pidm
                                 FROM sztprono
                                WHERE     1 = 1
                                      AND sztprono_no_regla =
                                             w.szstume_no_regla
                                      AND sztprono_pidm = w.szstume_pidm-- and sztprono_materia_legal = w.szstume_subj_code
                              )
                        LOOP
                           l_contador := l_contador + 1;
                           l_baja_abcc :=
                              pkg_abcc.f_monetos_abcc ('CAMBIO_ETSTAUS',
                                                       s.SZTPRONO_STUDY_PATH,
                                                       s.SZTPRONO_pidm,
                                                       'BD',
                                                       USER);

                           IF l_baja_abcc = 'EXITO'
                           THEN
                              --
                              -- DELETE SGRSCMT
                              -- WHERE 1 = 1
                              -- AND SGRSCMT_SEQ_NO <> 1
                              -- AND SGRSCMT_PIDM = S.SZTPRONO_pidm;
                              COMMIT;
                           ELSE
                              ROLLBACK;
                           END IF;

                           DBMS_OUTPUT.put_line ('Prono ' || l_contador);

                           -- DELETE SGRSCMT
                           -- WHERE 1 = 1
                           -- AND SGRSCMT_SEQ_NO <> 1
                           -- AND SGRSCMT_PIDM = S.SZTPRONO_pidm;

                           EXIT WHEN l_contador = 1;
                        END LOOP;
                     END IF;
                  END LOOP;
               END IF;


               EXIT WHEN l_contador = 1;
            END IF;
         --dbms_output.put_line(' Fecha hoy '||x||' fecha 0 '||l_fecha||' Fecha Inicio '||l_fecha_inicio||' cuntra otro '||l_cuenta_otro||' Fecha Correcta '||l_fecha_correcta);


         END LOOP;
      END LOOP;

      COMMIT;
   END;

   --
   --Jpg@Create@Nov@21 Function
   --Funcion que genera grupos nuevos para alumnos semi-presenciales
   --Esta funcion se usa despues de la integracion de alumnos desde forms szfmodl
   FUNCTION f_create_gpo_semi (p_regla NUMBER)
      RETURN VARCHAR2
   IS
      lc_error   VARCHAR2 (500) := 'OK';

      FUNCTION f_create_grupo (p_regla NUMBER, p_materia VARCHAR2)
         RETURN VARCHAR2
      IS
         l_grupo_NEW            VARCHAR2 (3);
         l_nrc                  VARCHAR2 (30);
         l_NRC_NEW              VARCHAR2 (30);
         l_pidm_dummy_docente   spriden.spriden_pidm%TYPE := 310784; --ProfesorDummy
         l_error                VARCHAR2 (500) := 'OK';
      BEGIN
         BEGIN
            SELECT X.SZTGPME_TERM_NRC,
                      X.SZTGPME_SUBJ_CRSE
                   || LTRIM (TO_CHAR (X.SZTGPME_GRUPO + 1, '09') || 'X'),
                   X.SZTGPME_GRUPO + 1
              INTO l_nrc, l_NRC_NEW, l_grupo_NEW
              FROM SZTGPME X
             WHERE     X.SZTGPME_no_regla = P_REGLA
                   AND X.SZTGPME_SUBJ_CRSE = P_MATERIA
                   AND X.SZTGPME_GRUPO =
                          (SELECT MAX (SZTGPME_GRUPO)
                             FROM SZTGPME Z
                            WHERE     Z.SZTGPME_no_regla = X.SZTGPME_no_regla
                                  AND Z.SZTGPME_SUBJ_CRSE =
                                         X.SZTGPME_SUBJ_CRSE);
         END;

         DBMS_OUTPUT.put_line (
               'Creando Grupo NRC: '
            || l_nrc
            || ' NRC_NEW: '
            || l_NRC_NEW
            || ' Grupo New:'
            || l_grupo_NEW);

         BEGIN
            INSERT INTO sztgpme
               SELECT l_NRC_NEW,
                      X.SZTGPME_SUBJ_CRSE,
                      X.SZTGPME_TITLE,
                      '0'                                --,X.SZTGPME_STAT_IND
                         ,
                      NULL                                    --,X.SZTGPME_OBS
                          ,
                      X.SZTGPME_USER_ID,
                      SYSDATE                       --,X.SZTGPME_ACTIVITY_DATE
                             ,
                      X.SZTGPME_PTRM_CODE,
                      X.SZTGPME_START_DATE,
                      X.SZTGPME_CRSE_MDLE_ID,
                      X.SZTGPME_MAX_ENRL,
                      X.SZTGPME_LEVL_CODE,
                      X.SZTGPME_CAMP_CODE,
                      X.SZTGPME_POBI_SEQ_NO,
                      X.SZTGPME_SUBJ_CRSE_COMP,
                      X.SZTGPME_INT_OBS,
                      X.SZTGPME_TERM_NRC_COMP,
                      X.SZTGPME_CAMP_CODE_COMP,
                      X.SZTGPME_PTRM_CODE_COMP,
                      NULL                              --,X.SZTGPME_GPMDLE_ID
                          ,
                      X.SZTGPME_CRSE_MDLE_CODE,
                      X.SZTGPME_NO_REGLA,
                      X.SZTGPME_SECUENCIA,
                      l_grupo_NEW,
                      X.SZTGPME_ACTIVAR_GRUPO,
                      X.SZTGPME_NIVE_SEQNO,
                      'E'
                 FROM SZTGPME X
                WHERE     X.SZTGPME_no_regla = P_REGLA
                      AND X.SZTGPME_SUBJ_CRSE = P_MATERIA
                      AND X.SZTGPME_GRUPO =
                             (SELECT MAX (SZTGPME_GRUPO)
                                FROM SZTGPME Z
                               WHERE     Z.SZTGPME_no_regla =
                                            X.SZTGPME_no_regla
                                     AND Z.SZTGPME_SUBJ_CRSE =
                                            X.SZTGPME_SUBJ_CRSE);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error := 'ErrorInsert->sztgpme: ' || SQLERRM;
         END;

         BEGIN
            INSERT INTO SZSGNME
               SELECT l_NRC_NEW,
                      l_pidm_dummy_docente,                  --x.SZSGNME_PIDM,
                      SYSDATE,                      --x.SZSGNME_ACTIVITY_DATE,
                      x.SZSGNME_USER_ID,
                      '0',                               --x.SZSGNME_STAT_IND,
                      NULL,                                   --x.SZSGNME_OBS,
                      x.SZSGNME_PWD,
                      NULL,                           --x.SZSGNME_ASGNMDLE_ID,
                      x.SZSGNME_FCST_CODE,
                      x.SZSGNME_SEQ_NO,
                      x.SZNME_POBI_SEQ_NO,
                      x.SZSGNME_PTRM,
                      x.SZSGNME_START_DATE,
                      x.SZSGNME_NO_REGLA,
                      x.SZSGNME_SECUENCIA,
                      x.SZSGNME_NIVE_SEQNO,
                      'E'
                 FROM SZSGNME x
                WHERE     x.SZSGNME_NO_REGLA = p_regla
                      AND x.SZSGNME_TERM_NRC = l_nrc;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error := 'ErrorInsert->SZSGNME: ' || SQLERRM;
         END;

         BEGIN
            INSERT INTO szstume
                 SELECT DISTINCT l_NRC_NEW,
                                 SZSTUME_PIDM,
                                 SZSTUME_ID,
                                 SYSDATE              --,SZSTUME_ACTIVITY_DATE
                                        ,
                                 SZSTUME_USER_ID,
                                 '0'                       --,SZSTUME_STAT_IND
                                    ,
                                 NULL                           --,SZSTUME_OBS
                                     ,
                                 SZSTUME_PWD,
                                 NULL                       --,SZSTUME_MDLE_ID
                                     ,
                                 SZSTUME_SEQ_NO,
                                 'RE'                     --,SZSTUME_RSTS_CODE
                                     ,
                                 SZSTUME_GRDE_CODE_FINAL,
                                 SZSTUME_SUBJ_CODE,
                                 SZSTUME_LEVL_CODE,
                                 SZSTUME_POBI_SEQ_NO,
                                 SZSTUME_PTRM,
                                 SZSTUME_CAMP_CODE,
                                 SZSTUME_CAMP_CODE_COMP,
                                 SZSTUME_LEVL_CODE_COMP,
                                 SZSTUME_TERM_NRC_COMP,
                                 SZSTUME_SUBJ_CODE_COMP,
                                 SZSTUME_START_DATE,
                                 SZSTUME_NO_REGLA,
                                 SZSTUME_SECUENCIA,
                                 SZSTUME_NIVE_SEQNO,
                                 0,
                                 null
                   FROM sztgpme
                        JOIN szstume
                           ON     szstume_term_nrc = sztgpme_term_nrc
                              AND szstume_no_regla = sztgpme_no_regla
                        JOIN sztprono
                           ON     sztprono_pidm = SZSTUME_PIDM
                              AND sztprono_no_regla = szstume_no_regla
                  WHERE     sztgpme_no_regla = p_regla
                        AND SZSTUME_RSTS_CODE = 'RE'
                        AND SZSTUME_SUBJ_CODE = p_materia
                        AND EXISTS
                               (SELECT 1
                                  FROM sztdtec ax
                                 WHERE     SZTDTEC_MOD_TYPE = 'S'
                                       AND ax.SZTDTEC_TERM_CODE =
                                              (SELECT MAX (
                                                         ax1.SZTDTEC_TERM_CODE)
                                                 FROM sztdtec ax1
                                                WHERE ax.SZTDTEC_PROGRAM =
                                                         ax1.SZTDTEC_PROGRAM)
                                       AND ax.SZTDTEC_PROGRAM =
                                              SZTPRONO_PROGRAM)
               ORDER BY 2;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error := 'ErrorInsert->szstume: ' || SQLERRM;
         END;

         RETURN l_error;
      END f_create_grupo;
   BEGIN
      FOR x
         IN (SELECT DISTINCT SZTGPME_SUBJ_CRSE materia
               FROM sztgpme
                    JOIN szstume
                       ON     szstume_term_nrc = sztgpme_term_nrc
                          AND szstume_no_regla = sztgpme_no_regla
                    JOIN sztprono
                       ON     sztprono_pidm = SZSTUME_PIDM
                          AND sztprono_no_regla = szstume_no_regla
              WHERE     sztgpme_no_regla = p_regla
                    AND EXISTS
                           (SELECT 1
                              FROM sztdtec ax
                             WHERE     SZTDTEC_MOD_TYPE = 'S'
                                   AND ax.SZTDTEC_TERM_CODE =
                                          (SELECT MAX (ax1.SZTDTEC_TERM_CODE)
                                             FROM sztdtec ax1
                                            WHERE ax.SZTDTEC_PROGRAM =
                                                     ax1.SZTDTEC_PROGRAM)
                                   AND ax.SZTDTEC_PROGRAM = SZTPRONO_PROGRAM)
                    --Jpg@Modify:REQ:Agos22 Auto enrolamiento a grupo de estudiantes de programas ejecutivos.
                    AND sztprono_materia_legal = 'L1C101'
                    AND (   EXISTS
                               (SELECT 1
                                  FROM tztprog
                                 WHERE     matricula = sztprono_id
                                       AND programa = SZTPRONO_PROGRAM
                                       AND SGBSTDN_STYP_CODE IN ('N', 'F')
                                       AND FECHA_INICIO >= '29/08/2022')
                         OR EXISTS
                               (SELECT 1
                                  FROM tztprog
                                 WHERE     matricula = sztprono_id
                                       AND programa = SZTPRONO_PROGRAM
                                       AND SGBSTDN_STYP_CODE IN ('C')
                                       AND FECHA_INICIO BETWEEN '29/08/2022'
                                                            AND SYSDATE))--Jpg@Modify:REQ:Agos22 Auto enrolamiento a grupo de estudiantes de programas ejecutivos.
            )
      LOOP
         DBMS_OUTPUT.put_line ('Procesando materia: ' || x.materia);
         lc_error := f_create_grupo (p_regla, x.materia);

         IF lc_error <> 'OK'
         THEN
            EXIT;
         END IF;
      END LOOP;

      RETURN lc_error;
   END f_create_gpo_semi;

   -----
   -----
 FUNCTION F_INTEGRA_CONTINUOS_REGLAS(P_REGLA IN NUMBER, P_FECHA_INICIO IN VARCHAR2, P_USUARIO IN VARCHAR2)
      RETURN VARCHAR2
   IS
      L_SECUENCIA      NUMBER;
      RetVal2          VARCHAR2(200);
      L_VALIDA         VARCHAR2 (300) := 'EXITO';
      L_CUPLAY         NUMBER;
      L_CUPALG         NUMBER;
      L_SUMACT         NUMBER;
      L_NUMGRUP        NUMBER;
      L_VUELTAS        NUMBER;
      L_DIPLO_EXCLUIR  NUMBER;
      l_contar         NUMBER;
      L_GRUPO          NUMBER;
      l_estatus_sgbstn varchar2(3);
      VL_MAXIMO        number;
      l_cact_code      VARCHAR2(30);
      L_VALIDA1        VARCHAR2 (500) := 'EXITO';
      l_fecha          varchar(20);

 BEGIN
   BEGIN
   
        BEGIN
            SELECT DISTINCT (SZTGPME_SECUENCIA)+1
              INTO L_SECUENCIA
              FROM SZTGPME
             WHERE     1 = 1
                   AND SZTGPME_NO_REGLA = P_REGLA              
                   AND SZTGPME_START_DATE = TO_DATE(P_FECHA_INICIO,'DD/MM/YYYY')
                   and SZTGPME_STAT_IND=1
                   ;
             -- DBMS_OUTPUT.put_line ( '13948 L SECUENCIA' || SQLERRM||L_SECUENCIA);       
             EXCEPTION WHEN OTHERS THEN
             --  DBMS_OUTPUT.put_line ( ' Error EN SECUENCIA' || SQLERRM||L_SECUENCIA);
               L_VALIDA:=( ' Error EN SECUENCIA 1 ' || SQLERRM||L_SECUENCIA);
         END;
        
      FOR C IN (select *
                from sztprono--,tztprog 
                where   1=1
              --  and SZTPRONO_PIDM=PIDM
                and SZTPRONO_NO_REGLA=P_REGLA
                and SZTPRONO_FECHA_INICIO=P_FECHA_INICIO                
                and SZTPRONO_ESTATUS_ERROR ='N'
             --   and SZTPRONO_PROGRAM=PROGRAMA
               -- and ESTATUS in ('MA')
               -- and SZTPRONO_PIDM= 946362
                )
      LOOP
         
         BEGIN 
              FOR D IN
                   (SELECT SZTGPME_TERM_NRC padre,
                          sztgpme_no_regla regla,
                          sztgpme_subj_crse materia,
                          to_char(SZTGPME_START_DATE,'DD/MM/YYYY') inicio_clases,
                          SZTGPME_START_DATE inicio_clases2,
                          TO_NUMBER (SUBSTR (SZTGPME_TERM_NRC, LENGTH (SZTGPME_TERM_NRC) - 1,100))grupo,
                          SZTGPME_SECUENCIA secuencia,
                          SZTGPME_NIVE_SEQNO sqno,
                          SZTGPME_LEVL_CODE nivel
                     FROM sztgpme grp
                    WHERE     1 = 1
                          AND sztgpme_no_regla = p_regla
                           AND SZTGPME_SECUENCIA=L_SECUENCIA
                          AND SZTGPME_LEVL_CODE = 'EC' 
                      --    and sztgpme_subj_crse='C1RA012' --lo agregué´para prueba
                   )                 
            LOOP   
                   /* BEGIN
                           SELECT COUNT(*)
                            INTO L_SUMACT
                            FROM  SZTPRONO,TZTPROG 
                            WHERE   1=1
                            AND  SZTPRONO_PIDM=PIDM --LE AGREGUÉ CONDICION
                            AND  SZTPRONO_PIDM=C.SZTPRONO_PIDM
                            AND  SZTPRONO_NO_REGLA=C.SZTPRONO_NO_REGLA
                            AND SZTPRONO_FECHA_INICIO=to_date(D.inicio_clases,'DD/MM/YYYY')
                           -- AND  SZTPRONO_FECHA_INICIO=D.inicio_clases --C.SZTPRONO_FECHA_INICIO, lo cambié porque toma la del 31/03 y debe ser 05/05
                            AND  SZTPRONO_MATERIA_LEGAL=D.materia
                            AND  ESTATUS='MA'
                            AND SZTPRONO_ESTATUS_ERROR ='N';
                            
                        --  DBMS_OUTPUT.put_line ( ' linea 13991 SECUENCIA' || SQLERRM||L_SUMACT);   
                     EXCEPTION WHEN OTHERS THEN
                      L_VALIDA:=( ' Error CUENTA ACTIVOS' || SQLERRM||L_SUMACT||D.inicio_clases);
                    END;

                    BEGIN
                          SELECT DISTINCT (SZTCONF_STUDENT_NUMB)
                          into L_CUPLAY
                          from SZTCONF
                          where 1=1
                          and SZTCONF_NO_REGLA=C.SZTPRONO_NO_REGLA
                          and SZTCONF_SUBJ_CODE=D.materia;
                         -- DBMS_OUTPUT.put_line ( 'linea 14003 SECUENCIA' || SQLERRM||L_CUPLAY);
                    EXCEPTION WHEN OTHERS THEN
                      L_VALIDA:=( ' Error NUMERO ALUMNOS LOYAUT' || SQLERRM||L_CUPLAY);   
                    END;

                    BEGIN
                        SELECT (SZTALGO_TOPE_ALUMNOS)+(SZTALGO_SOBRECUPO_ALUMNOS)
                        INTO L_CUPALG
                        FROM sztalgo
                        WHERE 1=1
                        AND SZTALGO_NO_REGLA=p_regla;
                     --   DBMS_OUTPUT.put_line ( '14014 SECUENCIA' || SQLERRM||L_CUPALG);
                    EXCEPTION WHEN OTHERS THEN
                       L_VALIDA:=( ' Error NUMERO ALUMNOS LOYAUT' || SQLERRM||L_CUPALG); 
                    END;
                    
                    BEGIN
                         SELECT COUNT(sztgpme_subj_crse)materia
                         INTO L_NUMGRUP
                         FROM sztgpme grp
                         WHERE     1 = 1
                         AND sztgpme_no_regla = P_REGLA
                         AND SZTGPME_SECUENCIA=L_SECUENCIA
                         AND SZTGPME_LEVL_CODE = 'EC'
                         AND SZTGPME_SUBJ_CRSE=D.materia ;
                 --        DBMS_OUTPUT.put_line ( '14028 SECUENCIA' || SQLERRM||L_NUMGRUP);
                    EXCEPTION WHEN OTHERS THEN
                       L_VALIDA:=( ' Error NUMERO ALUMNOS LOYAUT' || SQLERRM||L_NUMGRUP);   
                    END;                     
              
              --se omite validación de cupo en grupo
                  IF L_SUMACT<=L_CUPALG THEN
                    L_VUELTAS:=L_SUMACT/L_NUMGRUP; 
                --   DBMS_OUTPUT.put_line ( '14035 ENTRA SUMA ACTIVOS MENOR QUE ALGO' || SQLERRM||L_VUELTAS);
                  ELSIF L_SUMACT>L_CUPALG AND L_SUMACT >(L_CUPLAY-1) THEN 
                    L_VUELTAS:=L_SUMACT;              
               --    DBMS_OUTPUT.put_line ( 'ENTRA SUMA ACTIVO MAYOR QUE ALGO' || SQLERRM||L_VUELTAS);
                  ELSE 
                    L_VUELTAS:=L_CUPLAY;
                  -- DBMS_OUTPUT.put_line ( 'ENTRA OTRO ACTIVO MENOR QUE ALGO' || SQLERRM||L_VUELTAS); 
                  END IF;
              
               */
                l_contar := 0;
              --  DBMS_OUTPUT.put_line ( '14046 LVUELTAS ' ||L_VUELTAS|| ' materia '||D.materia || ' pidm '||C.SZTPRONO_PIDM ||' / '||c.sztprono_no_regla); 
                  FOR F IN (SELECT *
                           FROM (SELECT distinct sztprono_id matricula,
                                        SZTPRONO_PIDM pidm,
                                        SZTPRONO_NO_REGLA regla,
                                        'RE' estatus_alumno,
                                        (SELECT GOZTPAC_PIN
                                           FROM GOZTPAC pac
                                          WHERE 1 = 1
                                          AND pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM)pwd,
                                        SZTPRONO_COMENTARIO comentario,
                                        SZTPRONO_PROGRAM programa,
                                        sztprono_materia_legal materia,
                                        DECODE ((SELECT DISTINCT SZTDTEC_MOD_TYPE
                                              FROM sztdtec ax
                                             WHERE     1 = 1
                                             AND ax.SZTDTEC_TERM_CODE =(SELECT MAX (ax1.SZTDTEC_TERM_CODE)
                                                             FROM sztdtec ax1
                                                            WHERE ax.SZTDTEC_PROGRAM =ax1.SZTDTEC_PROGRAM)
                                                            AND ax.SZTDTEC_PROGRAM =ono.SZTPRONO_PROGRAM),'S', 1,'OL', 2)semi,
                                        SZTPRONO_STUDY_PATH sp                    
                                   FROM sztprono ono
                                  WHERE     1 = 1
                                        AND sztprono_no_regla = c.sztprono_no_regla
                                        AND sztprono_materia_legal =D.materia--c.sztprono_materia_legal
                                        AND SZTPRONO_ESTATUS_ERROR = 'N'
                                        AND SZTPRONO_ENVIO_MOODL = 'N'
                                        AND DECODE ((SELECT DISTINCT SZTDTEC_MOD_TYPE
                                                  FROM sztdtec ax
                                                  WHERE     1 = 1
                                                  AND ax.SZTDTEC_TERM_CODE =(SELECT MAX (ax1.SZTDTEC_TERM_CODE)
                                                                                 FROM sztdtec ax1
                                                                                WHERE ax.SZTDTEC_PROGRAM = ax1.SZTDTEC_PROGRAM)
                                                  AND ax.SZTDTEC_PROGRAM =ono.SZTPRONO_PROGRAM), 'S', 1,'OL', 2) in (1,2)
                                )
                          WHERE 1 = 1 
                         -- and pidm = C.SZTPRONO_PIDM
                         -- AND ROWNUM <= L_VUELTAS
                        --  and pidm=946362--lo agregué para pruebas
                          )

                  LOOP

                 
         
                
--Debe insertar la materia 
--Modificación Caty en Abril 2025

l_estatus_sgbstn:=null;
l_cact_code:=null;
--------------------------------------------------------------
                   BEGIN
                   
                        SELECT SORLCUR_CACT_CODE,upper(TO_CHAR(TRUNC(SORLCUR_START_DATE),'DD-Mon-YYYY'))
                        INTO l_cact_code, l_fecha
                        FROM SORLCUR
                        WHERE  1=1
                        AND SORLCUR_PIDM = F.pidm
                        AND SORLCUR_PROGRAM = F.programa
                        AND SORLCUR_KEY_SEQNO = F.sp                  
                        AND upper(TO_CHAR(TRUNC(SORLCUR_START_DATE),'DD-Mon-YYYY'))=P_FECHA_INICIO  --funciona para ejecutarlo desde banner
                     --  AND SORLCUR_START_DATE = TO_DATE(P_FECHA_INICIO,'DD/MM/YYYY')--P_FECHA_INICIO    --funciona para probar directo en la bd                  
                        and SORLCUR_LMOD_CODE = 'LEARNER'
                        AND SORLCUR_SEQNO in (select max(s.SORLCUR_SEQNO)
                                              from sorlcur s
                                              where 
                                                    s.SORLCUR_PIDM = F.pidm
                                                AND s.SORLCUR_PROGRAM = F.programa
                                                AND s.SORLCUR_KEY_SEQNO = F.sp
                                                AND upper(TO_CHAR(TRUNC(SORLCUR_START_DATE),'DD-Mon-YYYY'))=P_FECHA_INICIO --funciona para ejecutarlo desde banner
                                              --  AND s.SORLCUR_START_DATE=TO_DATE(P_FECHA_INICIO,'DD/MM/YYYY') --funciona para probar directo en la bd                                              
                                                AND s.SORLCUR_LMOD_CODE = 'LEARNER');
                    EXCEPTION WHEN OTHERS THEN
                      l_cact_code:= 'Cambio_ciclo';
                      L_VALIDA:=' ERROR BLOQUE l_cact_code '||l_fecha||' / '||sqlerrm || c.SZTPRONO_FECHA_INICIO||' / '||F.pidm||' / '||F.programa;
                    END;   
                   
                   
                    BEGIN
                                          
                            SELECT NVL(MAX(SZSTUME_SEQ_NO),0)+1 --Secuencia
                            INTO VL_MAXIMO
                            FROM SZSTUME
                            WHERE SZSTUME_SUBJ_CODE = D.materia
                            AND  SZSTUME_PIDM = F.pidm 
                            and szstume_no_regla =c.sztprono_no_regla;                            
                    EXCEPTION WHEN OTHERS THEN
                        VL_MAXIMO := 0;                            
                    END;
                    
                     begin
                             select distinct SGBSTDN_STST_CODE  --Estatus del alumno
                             into l_estatus_sgbstn
                             from sgbstdn a
                             WHERE 1 = 1
                             AND a.sgbstdn_pidm =F.pidm
                             AND a.SGBSTDN_PROGRAM_1 =F.programa
                             AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                            FROM sgbstdn a1
                                                            WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                            AND   a1.SGBSTDN_PROGRAM_1 =F.programa
                                                                                   );
                     exception when others then
                        l_estatus_sgbstn:=null;
                     end;
                       L_VALIDA:='ANTES DE INSERTAR '||l_cact_code||'/'||l_estatus_sgbstn||'/'||P_FECHA_INICIO||'/'||l_fecha||' / '||F.pidm;
                       
                    --   DBMS_OUTPUT.put_line ('ANTES DE INSERTAR '||l_cact_code||'/'||l_estatus_sgbstn||'/'||P_FECHA_INICIO||'/'||F.pidm);
                    if l_estatus_sgbstn  in ('AS','PR','MA') AND l_cact_code = 'ACTIVE' THEN    
                    begin   
                        l_contar := l_contar + 1; --hace el conteo si cumple con los estatus
                      L_VALIDA:='ENTRA A INSERTAR '||l_cact_code||'/'||l_estatus_sgbstn||'/'||upper(to_CHAR(D.inicio_clases2,'DD/MM/RR'));
                    begin   
                    -- DBMS_OUTPUT.put_line ('ENTRA A INSERTAR '||l_cact_code||'/'||l_estatus_sgbstn||'/'||upper(to_CHAR(D.inicio_clases2,'DD/MM/RR')));
                        INSERT INTO SZSTUME
                        (
                                SZSTUME_TERM_NRC,
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
                                SZSTUME_GRDE_CODE_FINAL,
                                SZSTUME_SUBJ_CODE,
                                SZSTUME_LEVL_CODE,
                                SZSTUME_POBI_SEQ_NO,
                                SZSTUME_PTRM,
                                SZSTUME_CAMP_CODE,
                                SZSTUME_CAMP_CODE_COMP,
                                SZSTUME_LEVL_CODE_COMP,
                                SZSTUME_TERM_NRC_COMP,
                                SZSTUME_SUBJ_CODE_COMP,
                                SZSTUME_START_DATE,
                                SZSTUME_NO_REGLA,
                                SZSTUME_SECUENCIA,
                                SZSTUME_NIVE_SEQNO,
                                SZSTUME_SINCRO,
                                SZSTUME_SINCRO_OBS
                        )
                        VALUES
                            (   D.padre,--C.SZTPANI_GRUPO,
                                F.pidm,--C.SZTPANI_PIDM,
                                F.matricula,--C.SZTPANI_ID,
                                SYSDATE,
                                P_USUARIO,--USER,
                                '0',
                                NULL,
                                F.pwd, --C.SZTPANI_PWD,
                                NULL,
                                VL_MAXIMO,
                                'RE',
                                NULL,    
                                D.materia,--C.SZTPANI_MATERIA,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                D.materia,--C.SZTPANI_MATERIA,
                                upper(to_DATE(D.inicio_clases2,'DD/MM/RR')),
                                c.sztprono_no_regla,
                                D.secuencia,
                                1,
                                0,
                                null
                            );
                        exception when others then
                            L_VALIDA:=('No se pudo insertar  en SZSTUME '||F.pidm||upper(to_DATE(D.inicio_clases2,'DD/MM/RR'))||' /'|| sqlerrm );
                        end;
                        
--------------------------------                           
                           /* BEGIN
                            
                              update  SZSTUME 
                               set SZSTUME_TERM_NRC = SZSTUME_SUBJ_CODE||l_contar
                                WHERE 1=1
                                AND SZSTUME_NO_REGLA= F.regla
                                AND SZSTUME_SUBJ_CODE=F.materia
                                AND SZSTUME_PIDM=F.pidm;
                                DBMS_OUTPUT.put_line ( 'ACTUALIZA SZSTUME materia'|| f.materia || SQLERRM);
                               COMMIT;
                               EXCEPTION
                                  WHEN OTHERS
                                  THEN
                                     DBMS_OUTPUT.put_line (
                                        ' Error al insertar ' || SQLERRM);
                                 L_VALIDA:=( ' Error UPADTE SZSTUME' || SQLERRM);         
                               END;
                               */

                     BEGIN

                    --  DBMS_OUTPUT.put_line ( ' ENTRA A ACTULIZAR SZTPRONO');

                        UPDATE SZTPRONO
                           SET SZTPRONO_ENVIO_MOODL = 'S',
                               SZTPRONO_GRUPO_ASIG = l_contar
                         WHERE     1 = 1
                               AND SZTPRONO_MATERIA_LEGAL = F.materia
                               AND SZTPRONO_PIDM = F.PIDM
                               AND SZTPRONO_NO_REGLA = F.regla
                               AND SZTPRONO_ENVIO_MOODL = 'N';
                            DBMS_OUTPUT.put_line ( 'ACTUALIZA SZTPRONO' || SQLERRM);   
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           L_VALIDA:=( ' Error UPADTE SZSTPRONO' || SQLERRM);  
                     END;
                   end;
                   
                   else
                   
                     BEGIN
                        --Se marca con error a la materia de esta regla y los subsecuentes
                          UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='N',
                                              SZTPRONO_ESTATUS_ERROR ='S',
                                              SZTPRONO_DESCRIPCION_ERROR='Este alumno se encuentra con estatus en sgbstn de '||l_estatus_sgbstn || ' y sorlcur '||l_cact_code
                          WHERE 1 = 1
                        --  and SZTPRONO_MATERIA_LEGAL = F.materia
                          and SZTPRONO_PIDM =F.PIDM
                      --    and SZTPRONO_NO_REGLA = F.regla
                          and SZTPRONO_FECHA_INICIO >=to_date(D.inicio_clases,'DD/MM/YYYY');

                     EXCEPTION WHEN OTHERS THEN
                         null;
                     END;
                   
                   end if;
                   
                 --  EXIT WHEN l_contar =L_NUMGRUP;
                     COMMIT;
                  END LOOP;

            END LOOP;
            
        END;
        
       END LOOP;
    
       L_VALIDA1:='Actualiza grupos Regla '||P_REGLA || ' Fecha Inicio '||P_FECHA_INICIO;-- ||' / '||L_VALIDA; 

   EXCEPTION  WHEN OTHERS THEN

   L_VALIDA1:='no actualiza grupos '|| SQLERRM ||' / '||L_VALIDA;
   
   END;
  
   RETURN L_VALIDA1;

   COMMIT;
  
   
  END F_INTEGRA_CONTINUOS_REGLAS;
-------
-------
   FUNCTION F_INTEGRA_DIPLOMADOS (P_REGLA          IN NUMBER,
                                  P_FECHA_INICIO   IN VARCHAR2)
      RETURN VARCHAR2
   AS
      L_SECUENCIA      NUMBER;
      L_CUENTA_PROF    NUMBER;
      L_VALIDA         VARCHAR2 (300) := 'EXITO';
      L_CALIFICACION   VARCHAR2 (4);
      L_ACREDITA       VARCHAR2 (1);
      L_CONTADOR       NUMBER;
      L_BAJA_ABCC      VARCHAR2 (200);
      L_SERIACION      NUMBER;
      L_SURRGORADID    NUMBER;
      L_SALDO          NUMBER;
      RetVal2          VARCHAR2(200);
      L_BAJA_ABCC2     VARCHAR2 (200);
BEGIN
   BEGIN
       DBMS_OUTPUT.put_line ('entra1'||P_FECHA_INICIO||' ENTRA A ACTULIZAR SZTPRONO');
      FOR C IN (SELECT DISTINCT SZTALGO_NO_REGLA REGLA, SZTALGO_CAMP_CODE CAMPUS
               FROM SZTALGO A
              WHERE     1 = 1
                    AND SZTALGO_CAMP_CODE IN ('UTS')
                    AND SZTALGO_LEVL_CODE = 'EC'
                    AND SZTALGO_ESTATUS_CERRADO = 'S'
                    AND SZTALGO_NO_REGLA = P_REGLA
                    AND EXISTS
                           (SELECT NULL
                              FROM SZTGPME B
                             WHERE 1 = 1 AND SZTGPME_NO_REGLA = P_REGLA))
      LOOP

         BEGIN
            SELECT DISTINCT (SZTGPME_SECUENCIA)
              INTO L_SECUENCIA
              FROM SZTGPME
             WHERE     1 = 1
                   AND SZTGPME_NO_REGLA = P_REGLA
                   AND SZTGPME_START_DATE = P_FECHA_INICIO
                   and SZTGPME_STAT_IND=5
                   ;
            DBMS_OUTPUT.put_line ('entra secuencia'||L_SECUENCIA||' ENTRA A ACTULIZAR SZTPRONO');
         EXCEPTION
            WHEN OTHERS
            THEN 
              L_VALIDA:=(' Error al insertar ' || SQLERRM||P_FECHA_INICIO);
         END;

         L_CONTADOR := 0;

         IF L_SECUENCIA >= 0 THEN
             DBMS_OUTPUT.put_line ('entra secuencia 2'||L_SECUENCIA||' ENTRA A ACTULIZAR SZTPRONO');
            FOR D
               IN (SELECT *
                     FROM SZTGPME
                    WHERE     1 = 1
                          AND SZTGPME_NO_REGLA = P_REGLA
                          AND SZTGPME_STAT_IND = '5'
                          AND SZTGPME_SECUENCIA = L_SECUENCIA 
                          and SZTGPME_SUBJ_CRSE not in (select distinct SZTPRONO_MATERIA_LEGAL
                                                                 from SZTPRONO
                                                                WHERE 1=1
                                                                AND SZTPRONO_NO_REGLA = P_REGLA
                                                                and SZTPRONO_PROGRAM in (select ZSTPARA_PARAM_ID
                                                                                             from zstpara
                                                                                             where 1=1
                                                                                             and ZSTPARA_MAPA_ID='DIPLO_EXCLUIR'))
                )

            LOOP
                DBMS_OUTPUT.put_line ('entra secuencia a actulizar'||L_SECUENCIA||' ENTRA A ACTULIZAR SZTPRONO');
               BEGIN
                  UPDATE SZTGPME
                     SET SZTGPME_STAT_IND = '0'
                   WHERE     1 = 1
                         AND SZTGPME_NO_REGLA = D.SZTGPME_NO_REGLA
                         AND SZTGPME_TERM_NRC = D.SZTGPME_TERM_NRC
                         AND SZTGPME_START_DATE = D.SZTGPME_START_DATE
                         AND SZTGPME_NIVE_SEQNO = D.SZTGPME_NIVE_SEQNO;
                         
               DBMS_OUTPUT.put_line ('entra actulizar grupos'||L_SECUENCIA);     
               EXCEPTION
                  WHEN OTHERS
                  THEN
                   L_VALIDA:='no actualiza grupos';
               END;

               BEGIN
                  SELECT COUNT (*)
                    INTO L_CUENTA_PROF
                    FROM SZSGNME
                   WHERE     1 = 1
                         AND SZSGNME_NO_REGLA = D.SZTGPME_NO_REGLA
                         AND SZSGNME_TERM_NRC = D.SZTGPME_TERM_NRC
                         AND SZSGNME_START_DATE = D.SZTGPME_START_DATE
                         AND SZSGNME_NIVE_SEQNO = D.SZTGPME_NIVE_SEQNO
                         AND SZSGNME_STAT_IND = '5';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     L_VALIDA:='no cuenta prof';
               END;

               IF L_CUENTA_PROF > 0 THEN
                 DBMS_OUTPUT.put_line ('entr cuenta prof'||L_CUENTA_PROF);
                  BEGIN
                     UPDATE SZSGNME
                        SET SZSGNME_STAT_IND = '0'
                      WHERE     1 = 1
                            AND SZSGNME_NO_REGLA = D.SZTGPME_NO_REGLA
                            AND SZSGNME_TERM_NRC = D.SZTGPME_TERM_NRC
                            AND SZSGNME_START_DATE = D.SZTGPME_START_DATE
                            AND SZSGNME_NIVE_SEQNO = D.SZTGPME_NIVE_SEQNO;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                          L_VALIDA:='no actualiza grupos';
                  END;

               END IF;

              COMMIT;

             FOR X IN (SELECT UME.*,
                             GET_CRN_REGLA (UME.SZSTUME_PIDM,
                                            NULL,
                                            UME.SZSTUME_SUBJ_CODE,
                                            UME.SZSTUME_NO_REGLA)CRN,
                             (SELECT DISTINCT SZTPRONO_PROGRAM
                                FROM SZTPRONO
                               WHERE     1 = 1
                                     AND SZTPRONO_NO_REGLA =UME.SZSTUME_NO_REGLA
                                     AND SZTPRONO_PIDM = UME.SZSTUME_PIDM
                                     AND ROWNUM = 1)PROGRAMA,
                             (SELECT DISTINCT SZTPRONO_TERM_CODE
                                FROM SZTPRONO
                               WHERE     1 = 1
                                     AND SZTPRONO_NO_REGLA = UME.SZSTUME_NO_REGLA
                                     AND SZTPRONO_PIDM = UME.SZSTUME_PIDM
                                     AND ROWNUM = 1)TERM_CODE
                        FROM SZSTUME UME
                             WHERE     1 = 1
                             AND SZSTUME_NO_REGLA = P_REGLA
                             AND SZSTUME_START_DATE = P_FECHA_INICIO
                             AND SZSTUME_RSTS_CODE = 'RE')
              LOOP
                   DBMS_OUTPUT.put_line ('entra for alumnos'||L_CUENTA_PROF);

                          BEGIN

                                 UPDATE SZSTUME
                                 SET SZSTUME_STAT_IND = '0'
                                 WHERE     1 = 1
                                     AND SZSTUME_NO_REGLA = D.SZTGPME_NO_REGLA
                                     AND SZSTUME_SECUENCIA = D.SZTGPME_SECUENCIA
                                     AND SZSTUME_START_DATE = D.SZTGPME_START_DATE
                                     and SZSTUME_PIDM=X.SZSTUME_PIDM
                                     and SZSTUME_SUBJ_CODE=d.SZTGPME_SUBJ_CRSE
                                     AND SZSTUME_STAT_IND = '5';

                           EXCEPTION  WHEN OTHERS THEN

                                 L_VALIDA:='no actualiza grupos';

                            END;

               END LOOP;

               COMMIT;

            END LOOP;

         END IF;

      END LOOP;

            
    EXCEPTION  WHEN OTHERS THEN

    L_VALIDA:='no actuaLIZA INTEGRACION';
   
   END;
   
   RETURN L_VALIDA;


   COMMIT;


 END F_INTEGRA_DIPLOMADOS;
-------
-------
-------
Procedure p_Job_baja_diplomados
    IS
    l_fecha_inicio     date ;
    l_valida_fecha     number;
    l_fecha_act        date;
    L_SALDO           number;
    L_DIAS            NUMBER;
    L_VALSALDO        NUMBER;
    l_baja_abcc     varchar2(100);
    RetVal          varchar2(100);
    RetVal2         varchar2(100);
    L_DIPLO_EXCLUIR  number;


BEGIN
     FOR C IN
          (SELECT DISTINCT SZTALGO_NO_REGLA REGLA,B.SZTPRONO_FECHA_INICIO FECHA_INI,SZTPRONO_PIDM PIDM,SZTPRONO_STUDY_PATH STUDY,SZTPRONO_PROGRAM
               FROM SZTALGO A
               JOIN SZTPRONO B ON B.SZTPRONO_NO_REGLA=A.SZTALGO_NO_REGLA
--               AND SZTPRONO_ID='020476891'
              WHERE     1 = 1
                    AND A.SZTALGO_CAMP_CODE IN ('UTS')
                    AND A.SZTALGO_LEVL_CODE = 'EC'
                    AND A.SZTALGO_ESTATUS_CERRADO = 'S'
                    and SZTPRONO_ESTATUS_ERROR='N'
                    AND B.SZTPRONO_FECHA_INICIO IN  (SELECT C.SZTGPME_START_DATE
                              FROM SZTGPME C
                             WHERE 1 = 1
                             AND C.SZTGPME_STAT_IND = '1'
                             AND C.SZTGPME_SECUENCIA =(SELECT MAX (D.SZTGPME_SECUENCIA)
                                                        FROM SZTGPME D
                                                        WHERE 1=1
                                                        AND D.SZTGPME_STAT_IND = '1'
                                                        AND D.SZTGPME_NO_REGLA = A.SZTALGO_NO_REGLA))
          )
         LOOP

                  BEGIN
                      SELECT TO_CHAR(SORLCUR_START_DATE,'DD/MM/YYYY')
                      into l_fecha_inicio
                      FROM sorlcur a
                      WHERE 1 = 1
                      AND a.SORLCUR_PIDM=C.PIDM
                      and a.SORLCUR_LMOD_CODE='LEARNER'
                      and a.SORLCUR_SEQNO=(select max (a1.SORLCUR_SEQNO)
                                            from SORLCUR a1
                                            where 1=1
                                            and a1.SORLCUR_PIDM=a.SORLCUR_PIDM
                                            and a1.SORLCUR_LMOD_CODE='LEARNER');

                    EXCEPTION WHEN OTHERS THEN
                        l_fecha_inicio:= C.FECHA_INI;
                  END;

                          l_fecha_act := TRUNC(sysdate);

                          l_valida_fecha:=l_fecha_act-l_fecha_inicio;


                           DBMS_OUTPUT.put_line (l_valida_fecha);

                  BEGIN

                      SELECT ZSTPARA_PARAM_ID
                      INTO L_DIAS
                      FROM ZSTPARA
                      WHERE 1=1
                      AND ZSTPARA_MAPA_ID= 'BAJA_DIPLOMADO';

                  EXCEPTION WHEN OTHERS THEN
                        l_fecha_inicio:= null;
                  END;

                   BEGIN

                      SELECT ZSTPARA_PARAM_VALOR
                      INTO L_VALSALDO
                      FROM ZSTPARA
                      WHERE 1=1
                      AND ZSTPARA_MAPA_ID= 'BAJA_DIPLOMADO';

                  EXCEPTION WHEN OTHERS THEN
                        l_fecha_inicio:= null;
                  END;


                  BEGIN
                      select COUNT(*)
                      INTO L_DIPLO_EXCLUIR
                             from zstpara
                             where 1=1
                             and ZSTPARA_MAPA_ID='DIPLO_EXCLUIR'
                             and ZSTPARA_PARAM_ID=c.SZTPRONO_PROGRAM;

                  Exception When Others then

                       L_DIPLO_EXCLUIR:=0;

                  END;

            IF L_DIPLO_EXCLUIR=0 THEN


                 if l_valida_fecha > L_DIAS then

                            L_SALDO := BANINST1.F_SALDO_ALU (c.PIDM);

                    IF L_SALDO >=L_VALSALDO THEN

                     BEGIN

                         l_baja_abcc:=PKG_MOODLE_DIPLO.f_monetos_abcc('CAMBIO_ETSTAUS',C.STUDY,c.pidm,'BT',USER);

                         RetVal := PKG_MOODLE_DIPLO.F_BAJA_ABCC ('BT',c.pidm );

                      commit;

                     EXCEPTION WHEN OTHERS THEN

                           l_baja_abcc:='NO SE DIO DE BAJA'||c.pidm||' '||sqlerrm;

                           RetVal:='NO SE DIO DE BAJA MATERIA'||c.pidm||' '||sqlerrm;

                     END;

--                     BEGIN
--
--                          RetVal2 := BANINST1.PKG_FINANZAS_GGC.CANCELA_DIPLOMADO ( c.PIDM );
--
--                          COMMIT;
--                     EXCEPTION WHEN OTHERS THEN
--
--                          RetVal2:='NO SE REALIZO CANCELACION DE ACCESORIO'||c.pidm||' '||sqlerrm;
--                     END;


                    END IF;

                 END IF;
            ELSE
              NULL;
            END IF;

         END LOOP;

END;
-----
-----
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
--                                                        And a.SZSTUME_PTRM = '1'
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
                                                                         v_sal:=PKG_MOODLE_DIPLO.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                                      --   dbms_output.Put_line('SALIDA 1' || v_sal);

                                                                    EXCEPTION
                                                                        WHEN OTHERS THEN
                                                                          dbms_output.Put_line('Error al actulizar historia ' ||cx.periodo ||'*'|| cx.crn ||'*'|| cx.pidm  ||'*' ||v_sal ||'*'||SQLERRM);
                                                                    END;
                                                ELSE
                                                                    v_sal := PKG_MOODLE_DIPLO.F_pase_historia_califica (cx.campus, cx.nivel, cx.periodo, cx.crn, cx.pidm); --- Envia a Historia Academica
                                                                 --    dbms_output.Put_line('SALIDA 2' || v_sal);
                                                                     v_sal:=PKG_MOODLE_DIPLO.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                END IF;

                                End Loop;


                                 v_proc:=PKG_MOODLE_DIPLO.F_UPDATE_TMP_SYNC ( 2, trim (p_no_regla), trunc (p_fecha_inicio), 'rolado_calificaciones' );
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
--                                                        And a.SZSTUME_PTRM = '1'
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
                                                                         v_sal:=PKG_MOODLE_DIPLO.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                                      --   dbms_output.Put_line('SALIDA 1' || v_sal);

                                                                    EXCEPTION
                                                                        WHEN OTHERS THEN
                                                                                dbms_output.Put_line('Error al actulizar Calficacion22'
                                                                             ||SQLERRM);
                                                                    END;
                                                ELSE
                                                                    v_sal := PKG_MOODLE_DIPLO.F_pase_historia_califica (cx.campus, cx.nivel, cx.periodo, cx.crn, cx.pidm); --- Envia a Historia Academica
                                                                 --    dbms_output.Put_line('SALIDA 2' || v_sal);
                                                                     v_sal:=PKG_MOODLE_DIPLO.f_update_intermedia(cx.pidm, cx.regla, p_fecha_inicio, cx.grupo, cx.secuencia);

                                                END IF;

                                End Loop;

                                 v_proc:=PKG_MOODLE_DIPLO.F_UPDATE_TMP_SYNC ( 2, trim (p_no_regla), trunc (p_fecha_inicio), 'rolado_calificaciones' );
                              --   dbms_output.Put_line('SALIDA 4' || v_proc);
                                  Return(v_salida);
                                  Commit;
                        EXCEPTION
                                WHEN OTHERS THEN  v_sal := sqlerrm||': Error al actualizar el estatus de la calificacion 333' || v_fecha_inicio;
                                Return(v_salida);
                        END;



            End if;



   End f_update_horario;
-----
-----
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
  -------
  -------
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
------
------
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
------
------
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

        IF l_estatus ='BI' then

            l_estatus:='BT';


        end if;


        IF l_estatus IN ('BI','BT','BD','CV') then

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
--                AND sfrstcr_grde_code is  null
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
                                     sfrstcr_pidm pidm,
                                     sfrstcr_grde_code
                              FROM ssbsect ,
                                   sfrstcr
                              WHERE 1 = 1
                              AND ssbsect_term_code = sfrstcr_term_code
                              AND ssbsect_crn = sfrstcr_crn
                              AND ssbsect_ptrm_start_date =l_fecha_inicio_sor
--                              AND sfrstcr_grde_code is  null
                              AND substr(ssbsect_term_code,5,1) not in (8,9)
        --                      AND sfrstcr_rsts_code ='RE'
                              AND sfrstcr_pidm = p_pidm
                              )
                              LOOP


                               IF c.sfrstcr_grde_code IS NULL THEN

                                 dbms_output.put_line('Entra a horario');

                                  BEGIN

                                    UPDATE SFRSTCR SET sfrstcr_rsts_code ='DD',
                                                       SFRSTCR_USER_ID = user,
                                                       SFRSTCR_DATA_ORIGIN ='Baja por adeudo',
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
                                                                                                               5,
                                                                                                               NULL,
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
                                                                                                            sztprono_envio_horarios ='S',
                                                                                                            sztprono_descripcion_error ='Baja por adeudo'
                                                                                        WHERE 1 = 1
                                                                                        AND sztprono_pidm = x.szstume_pidm
                                                                                        AND sztprono_no_regla = d.sztprono_no_regla
                                                                                        and sztprono_estatus_error ='N';

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

                                ELSE
                                      BEGIN

                                               UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                   sztprono_envio_horarios ='S',
                                                                   sztprono_descripcion_error ='Baja por adeudo'
                                               WHERE 1 = 1
                                               AND sztprono_envio_horarios ='N'
                                               AND sztprono_pidm = P_PIDM;

                                           EXCEPTION WHEN OTHERS THEN
                                               l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
                                           END;

--                                      BEGIN
--
--                                                 UPDATE SZSTUME
--                                                 SET SZSTUME_RSTS_CODE ='DD'
--                                                     WHERE 1 = 1
--                                                     AND szstume_pidm = d.sztprono_pidm
--                                                     AND szstume_no_regla = d.sztprono_no_regla
--                                                     AND SZSTUME_START_DATE<>l_fecha_inicio_sor
--                                                     and SZSTUME_RSTS_CODE ='RE';
--                                       EXCEPTION WHEN OTHERS THEN
--                                            l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
--                                        END;

                                END IF;

                              END LOOP;

            else

                null;


            end if;


        end if;

        if l_retorna ='EXITO' then

            commit;
        else

            rollback;


        end if;


        RETURN(l_retorna);

    END;
----
----
FUNCTION f_monetos_abcc (p_evento varchar2, p_sp number, p_pidm number,p_estatus varchar2, p_user varchar2)
    return varchar2 is
        l_retorna varchar2(200):='EXITO';
        l_maximor_horarios varchar2(20);
        l_vaor_biracora varchar2(200);
        l_contador      number:=0;
        l_conse_sorlcur number;
    begin

        dbms_output.put_line('Entra 1 ');

        if p_evento ='CAMBIO_ETSTAUS' THEN

            for c in (select *
                      from tztprog
                      where 1 = 1
                      and pidm = p_pidm
                      and SP = p_sp
                      and rownum = 1
                       )loop

                           BEGIN
                                select max(SFRSTCR_TERM_CODE)
                                into l_maximor_horarios
                                from  SFRSTCR a
                                where 1 = 1
                                and A.SFRSTCR_PIDM = c.pidm
                              --  and A.SFRSTCR_STSP_KEY_SEQUENCE = p_sp
                                --and trunc (SSBSECT_PTRM_START_DATE) = to_Date(f_fecha_inicio_old, 'dd/mm/yyyy')
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

                              l_maximor_horarios:=c.MATRICULACION;

                           END IF;

                           if p_estatus ='BT' then

                               dbms_output.put_line('Periodo matriculacion '||c.MATRICULACION||' Periodo Mayor '||l_maximor_horarios);

                               --if c.MATRICULACION = l_maximor_horarios then

                                     BEGIN

                                        update sgbstdn a set sgbstdn_stst_code= p_estatus,--'BI'
                                                           SGBSTDN_STYP_CODE='D',
                                                           SGBSTDN_ACTIVITY_DATE = SYSDATE,
                                                           SGBSTDN_USER_ID = USER
                                        where 1 = 1
                                        AND a.sgbstdn_pidm=c.pidm
                                        and a.sgbstdn_program_1=c.programa
                                        AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                        FROM sgbstdn a1
                                                                        WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                        and a1.sgbstdn_program_1  = a.sgbstdn_program_1
                                                                                                         );

                                     EXCEPTION WHEN OTHERS THEN
                                        l_retorna:='No se pudo cambiar el estatus '||sqlerrm;
                                     END;

                                     if l_retorna ='EXITO' then

                                            l_contador:= 0;

                                            FOR t in (select *
                                                      from sorlcur b
                                                      where 1 = 1
                                                      and b.sorlcur_pidm =C.PIDM
                                                      AND b.sorlcur_lmod_code = 'LEARNER'
                                                      AND b.sorlcur_roll_ind = 'Y'
                                                      AND b.sorlcur_cact_code = 'ACTIVE'
                                                      AND b.SORLCUR_KEY_SEQNO = c.sp
                                                      AND b.sorlcur_seqno =
                                                                           (SELECT MAX (c1x.sorlcur_seqno)
                                                                            FROM sorlcur c1x
                                                                            WHERE     c1x.sorlcur_pidm = b.sorlcur_pidm
                                                                            AND c1x.sorlcur_lmod_code = b.sorlcur_lmod_code
                                                                            AND c1x.sorlcur_roll_ind =  b.sorlcur_roll_ind
                                                                            AND c1x.sorlcur_cact_code = b.sorlcur_cact_code
                                                                            )
                                                      )loop

                                                            l_contador:=l_contador+1;

                                                            begin

                                                                 SELECT NVL (MAX (sorlcur_seqno), 0) + 1
                                                                 INTO l_conse_sorlcur
                                                                 FROM sorlcur
                                                                 WHERE sorlcur_pidm = t.sorlcur_pidm;

                                                            exception when others then
                                                                null;
                                                            end;


                                                            begin

                                                                insert into sorlcur values (t.sorlcur_pidm,
                                                                                            l_conse_sorlcur,
                                                                                            t.sorlcur_lmod_code,
                                                                                            t.SORLCUR_TERM_CODE,
                                                                                            t.sorlcur_key_seqno,
                                                                                            t.sorlcur_priority_no,
                                                                                            'N',
                                                                                            'INACTIVE',
                                                                                            USER,
                                                                                            'Baja por adeudo',
                                                                                            SYSDATE,
                                                                                            t.sorlcur_levl_code,
                                                                                            t.sorlcur_coll_code,
                                                                                            t.sorlcur_degc_code,
                                                                                            t.sorlcur_term_code_ctlg,
                                                                                            l_maximor_horarios,
                                                                                            t.sorlcur_term_code_matric,
                                                                                            t.sorlcur_term_code_admit,
                                                                                            t.sorlcur_admt_code,
                                                                                            t.sorlcur_camp_code,
                                                                                            t.sorlcur_program,
                                                                                            t.sorlcur_start_date,
                                                                                            t.sorlcur_end_date,
                                                                                            t.sorlcur_curr_rule,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            t.SORLCUR_RATE_CODE,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            USER,
                                                                                            SYSDATE,
                                                                                            NULL,
                                                                                            t.SORLCUR_CURRENT_CDE,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL);

                                                            exception when others then
                                                                l_retorna:='No se actualizar el registro en sorlcur '||sqlerrm;
                                                            end;

                                                            IF l_retorna ='EXITO' then

                                                                 FOR w
                                                                  IN (  SELECT *
                                                                         FROM sorlfos
                                                                         WHERE sorlfos_pidm = t.sorlcur_pidm
                                                                         AND sorlfos_lcur_seqno = t.sorlcur_seqno
                                                                         ORDER BY sorlfos_seqno
                                                                      )loop

                                                                          begin

                                                                              INSERT INTO sorlfos
                                                                                    VALUES (w.sorlfos_pidm,
                                                                                            l_conse_sorlcur,
                                                                                            w.sorlfos_seqno,
                                                                                            w.sorlfos_lfst_code,
                                                                                            w.SORLFOS_TERM_CODE,
                                                                                            w.sorlfos_priority_no,
                                                                                            'CHANGED',
                                                                                            'INACTIVE',
                                                                                            'Baja por adeudo',
                                                                                            USER,
                                                                                            SYSDATE,
                                                                                            w.sorlfos_majr_code,
                                                                                            w.sorlfos_term_code_ctlg,
                                                                                            w.SORLFOS_TERM_CODE,
                                                                                            NULL,
                                                                                            w.sorlfos_majr_code_attach,
                                                                                            w.sorlfos_lfos_rule,
                                                                                            w.sorlfos_conc_attach_rule,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            USER,
                                                                                            SYSDATE,
                                                                                            w.SORLFOS_CURRENT_CDE,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL);

                                                                          exception when others then
                                                                              l_retorna:='No se puede insertar a sorlfos '||sqlerrm;
                                                                          end;

                                                                          if l_retorna='EXITO' then

                                                                            l_vaor_biracora:=f_bitacora_abcc(p_evento,c.sp,c.pidm,p_estatus,p_user);

                                                                            dbms_output.put_line('Contador  t-->'||l_contador);


                                                                                    if l_vaor_biracora ='EXITO' then

                                                                                       begin

                                                                                            UPDATE sgrstsp SET SGRSTSP_STSP_CODE = 'IN'
                                                                                            WHERE  1 = 1
                                                                                            and sgrstsp_pidm = C.PIDM
                                                                                            AND sgrstsp_key_seqno = c.sp;

                                                                                       exception when others then
                                                                                            l_retorna:='No se puede actualizar el estatus '||sqlerrm;
                                                                                       end;


                                                                                    end if;

                                                                                    if l_vaor_biracora ='EXITO' then
                                                                                        commit;
                                                                                    else

                                                                                        rollback;

                                                                                    end if;

                                                                                exit when l_contador = 1;


                                                                          end if;

                                                                      end loop;

                                                            end if;

                                                            exit when l_contador = 1;

                                                      end loop;



                                     end if;


                           end if;


                       END LOOP;

        END IF;

        return l_retorna;

    end;
 -----
 -----
     function f_bitacora_abcc ( p_evento varchar2,p_sp number, p_pidm number,p_estatus varchar2,p_user varchar2)
      return varchar2
      IS
      l_retorna varchar2(200):='EXITO';
      l_max_sgrscmt number;
      l_descripcion varchar2(2000);
      l_maximor_horarios varchar2(20);
      l_contador number:=0;
      l_codigo_domi varchar2(500);
      l_desc_domi varchar2(500);

    BEGIN

        dbms_output.put_line('entra bitacora 1');

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

        dbms_output.put_line('bitacora entra 2 -->'||l_contador);

        for c in (select *
                          from tztprog
                          where 1 = 1
                          and pidm = p_pidm
                          and SP = p_sp
                          AND ROWNUM = 1
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
                                     dbms_output.put_line('error inserta SGBSTDB '||l_retorna);
                               end;

         --                      dbms_output.put_line('entra 4');

                               if l_retorna ='EXITO' then

                                  dbms_output.put_line('entra 5' ||l_retorna);

                                   if p_evento ='CAMBIO_ETSTAUS' then

             --                        dbms_output.put_line('entra a evento  '||p_evento);

                                        l_descripcion:=UPPER('BAJA POR ADEUDO'||':'||' Estatus Anterior '||C.ESTATUS||' Estatus  Nuevo '||p_estatus||' Usuario '||user||' Fecha '||Sysdate);

                                   elsif p_evento ='BAJA_DOMI' then

                                        begin

                                            select listagg( GORADID_ADID_CODE ||',')WITHIN GROUP (ORDER BY GORADID_ADID_CODE) codigo_domi
                                            INTO l_codigo_domi
                                            from goradid
                                            where 1 = 1
                                            and goradid_pidm = p_pidm
                                            AND EXISTS (SELECT NULL
                                                        FROM ZSTPARA
                                                        WHERE 1 = 1
                                                        AND ZSTPARA_MAPA_ID='PORCENTAJE_DOM'
                                                        AND ZSTPARA_PARAM_ID = GORADID_ADID_CODE );

                                        exception when others then
                                            null;
                                        end;


                                        begin

                                            select listagg( GORADID_ADDITIONAL_ID ||',')WITHIN GROUP (ORDER BY GORADID_ADDITIONAL_ID) desc_domi
                                                INTO l_desc_domi
                                                from goradid a
                                                where 1 = 1
                                                and goradid_pidm = p_pidm
                                                AND EXISTS (SELECT NULL
                                                            FROM ZSTPARA
                                                            WHERE 1 = 1
                                                            AND ZSTPARA_MAPA_ID='PORCENTAJE_DOM'
                                                            AND ZSTPARA_PARAM_ID = GORADID_ADID_CODE );

                                         exception when others then
                                            null;
                                        end;
                                        l_descripcion:=UPPER('BAJA_DOMI, Codigo Goradid: '||l_codigo_domi||' '||l_desc_domi||' Usuario '||p_user||' Fecha '||Sysdate);

                                   end if;

               --                    dbms_output.put_line('entra 5 '||l_descripcion);

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

                                      l_maximor_horarios:=c.MATRICULACION;

                                   END IF;

                                  dbms_output.put_line('entra descripcion '||l_descripcion||' for '||l_contador);


                                   if l_descripcion is not null then

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
                                             , 'SSB'
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
 -------
 -------
END PKG_MOODLE_DIPLO;
/

DROP PUBLIC SYNONYM PKG_MOODLE_DIPLO;

CREATE OR REPLACE PUBLIC SYNONYM PKG_MOODLE_DIPLO FOR BANINST1.PKG_MOODLE_DIPLO;
