DROP PACKAGE BODY BANINST1.PKG_FORMA_MOODLE;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_FORMA_MOODLE IS
--
--
    PROCEDURE p_inserta_conf(p_materia varchar2,
                             p_grupo number,
                             p_fecha_inicio varchar2,
                             p_regla number)
    is

        l_retorna varchar2(20);

    begin

        insert into sztconf (SZTCONF_SUBJ_CODE,
                             SZTCONF_GROUP,
                             SZTCONF_STUDENT_NUMB,
                             SZTCONF_COST,
                             SZTCONF_USSER_INSERT,
                             SZTCONF_DATE_INSERT,
                             SZTCONF_USSER_UPDATE,
                             SZTCONF_DATE_UPDATE,
                             SZTCONF_NO_REGLA,
                             SZTCONF_ESTATUS_CERRADO,
                             SZTCONF_FECHA_INICIO
                             )values
                             (
                             p_materia,
                             p_grupo,
                             0,
                             2000,
                             user,
                             sysdate,
                             user,
                             sysdate,
                             p_regla,
                             'N',
                             p_fecha_inicio
                             );
        commit;
    end p_inserta_conf;

--
--

    function f_materia_manual(p_subj varchar2,
                              p_numb  varchar2,
                              p_regla number,
                              p_grupo varchar2,
                              p_inicio_clases  varchar2) return varchar2
    as
        l_retorna varchar(200);
        l_grupo_max number;
        l_pidm_prof number;
        l_crn   varchar2(100);
        l_periodo varchar2(100);
        l_parte_periodo varchar2(3);
        l_campus varchar2(3);
        schd varchar2(3);
        title varchar2(100);
        credit number;
        credit_bill number;
        gmod     NUMBER;
        f_inicio             DATE;
        f_fin                DATE;
        sem                  NUMBER;
        l_term_nrc  varchar2(30);
        l_nivel varchar2(3);
        l_short_name varchar2(100);
        l_pwd  varchar2(100);

    begin

        PKG_ALGORITMO.P_ENA_DIS_TRG('D','SATURN.SZT_SSBSECT_POSTINSERT_ROW');
        PKG_ALGORITMO.P_ENA_DIS_TRG('D','SATURN.SZT_SIRASGN_POSTINSERT_ROW');
        PKG_ALGORITMO.P_ENA_DIS_TRG('D','SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');



         BEGIN

            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,SZTALGO_PTRM_CODE_NEW,SZTALGO_CAMP_CODE,SZTALGO_LEVL_CODE
            INTO l_periodo,l_parte_periodo,l_campus,l_nivel
            FROM SZTALGO
            WHERE 1 = 1
            AND SZTALGO_NO_REGLA = P_REGLA;


         EXCEPTION WHEN OTHERS THEN

            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,SZTALGO_PTRM_CODE_NEW,SZTALGO_CAMP_CODE,SZTALGO_LEVL_CODE
            INTO l_periodo,l_parte_periodo,l_campus,l_nivel
            FROM SZTALGO
            WHERE 1 = 1
            AND SZTALGO_NO_REGLA = P_REGLA
            AND ROWNUM = 1;


         END;

         BEGIN

            select DECODE (SUBSTR(l_periodo,1,2),'02','01',SUBSTR(l_periodo,1,2))||SUBSTR(l_periodo,3,5)dato
            into l_periodo
            from dual;
         EXCEPTION WHEN OTHERS THEN
            NULL;
         END;


         BEGIN
            select DECODE (SUBSTR(l_parte_periodo,1,1),'A','M',SUBSTR(l_parte_periodo,1,1))||SUBSTR(l_parte_periodo,2,4)dato
            into l_parte_periodo
            from dual;
         EXCEPTION WHEN OTHERS THEN
            NULL;
         END;

         BEGIN

            select DECODE (SUBSTR(l_parte_periodo,1,2),'02','01',SUBSTR(l_parte_periodo,1,2))||SUBSTR(l_parte_periodo,3,5)dato
            into l_parte_periodo
            from dual;
         EXCEPTION WHEN OTHERS THEN
            NULL;
         END;

         BEGIN

            select nvl(max(crn),1000)+1
            into l_crn
            from
            (
                select case when
                                    substr(SSBSECT_CRN,1,1) IN('L','M','D','A') then to_number(substr(SSBSECT_CRN,2,100))+1
                          else
                                to_number(SSBSECT_CRN)
                          end crn
                from ssbsect
                where ssbsect_term_code= l_periodo
            );

         EXCEPTION WHEN OTHERS THEN
            l_crn := NULL;
         END;


         begin

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
            AND scbcrse_subj_code=p_subj
            AND scbcrse_crse_numb=p_numb
            AND scbcrse_eff_term='000000'
            AND scrschd_subj_code=scbcrse_subj_code
            AND scrschd_crse_numb=scbcrse_crse_numb
            AND scrschd_eff_term=scbcrse_eff_term;

         exception when others then

           schd         := NULL;
           title        := NULL;
           credit       := NULL;
           credit_bill  := NULL;

         end;

         BEGIN

             SELECT scrgmod_gmod_code
             INTO gmod
             FROM scrgmod
             WHERE 1 = 1
             AND scrgmod_subj_code=p_subj
             AND scrgmod_crse_numb=p_numb
             AND scrgmod_default_ind='D';

         EXCEPTION WHEN OTHERS THEN
             gmod:='1';
         END;


         BEGIN

           SELECT DISTINCT sobptrm_start_date,
                           sobptrm_end_date,
                           sobptrm_weeks
           INTO f_inicio,
                f_fin,
                sem
           FROM sobptrm
           WHERE 1  = 1
           AND sobptrm_term_code=l_periodo
           AND sobptrm_ptrm_code=l_parte_periodo;

         EXCEPTION WHEN OTHERS THEN
          --  vl_error := 'No se Encontro configuracion para el Periodo= ' ||c.periodo ||' y Parte de Periodo= '||c.parte ||SQLERRM;
          null;
         END;

         BEGIN

            SELECT DISTINCT sobptrm_start_date,
                            sobptrm_end_date,
                            sobptrm_weeks
            INTO f_inicio,
                 f_fin,
                 sem
            FROM sobptrm
            WHERE 1  = 1
            AND sobptrm_term_code=l_periodo
            AND sobptrm_ptrm_code=l_parte_periodo;

         EXCEPTION WHEN OTHERS THEN
             --vl_error := 'No se Encontro configuracion para el Periodo= ' ||c.periodo ||' y Parte de Periodo= '||c.parte ||SQLERRM;
             null;
         END;


         IF l_campus ='UTS' THEN

            l_campus:='UTL';

         END IF;


         if l_nivel ='LI' then

            l_crn:='L'||l_crn;

         else

            l_crn:='M'||l_crn;


         end if;

         BEGIN

            INSERT INTO ssbsect VALUES (
                                        l_periodo,           --SSBSECT_TERM_CODE
                                        l_crn,               --SSBSECT_CRN
                                        l_parte_periodo,     --SSBSECT_PTRM_CODE
                                        p_subj,              --SSBSECT_SUBJ_CODE
                                        p_numb,              --SSBSECT_CRSE_NUMB
                                        p_grupo,     --SSBSECT_SEQ_NUMB
                                        'A',    --SSBSECT_SSTS_CODE
                                        'ENL',    --SSBSECT_SCHD_CODE
                                        l_campus,    --SSBSECT_CAMP_CODE
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
                                        90, --SSBSECT_MAX_ENRL
                                        0,--SSBSECT_ENRL
                                        50,--SSBSECT_SEATS_AVAIL
                                        NULL,--SSBSECT_TOT_CREDIT_HRS
                                        '0',--SSBSECT_CENSUS_ENRL
                                        f_inicio,--SSBSECT_CENSUS_ENRL_DATE
                                        SYSDATE,--SSBSECT_ACTIVITY_DATE
                                        p_inicio_clases,--SSBSECT_PTRM_START_DATE
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
                                        'PRONOSTICO '||p_regla,--SSBSECT_DATA_ORIGIN
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
            l_retorna:='EXITO';

         EXCEPTION WHEN OTHERS THEN
           -- l_retorna:='Error al insertar ssbsect periodo '||l_periodo||' Error '||sqlerrm;
           null;
         END;

         IF l_retorna ='EXITO' then
            commit;
         ELSE
                ROLLBACK;
         end if;

        return(l_retorna||' '||l_crn);

        PKG_ALGORITMO.P_ENA_DIS_TRG('E','SATURN.SZT_SSBSECT_POSTINSERT_ROW');
        PKG_ALGORITMO.P_ENA_DIS_TRG('E','SATURN.SZT_SIRASGN_POSTINSERT_ROW');
        PKG_ALGORITMO.P_ENA_DIS_TRG('E','SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');

    end;
--
--
     function f_prof_manual(
                           p_prof_id varchar2,
                           p_crn     varchar2,
                           p_inicio_clases  varchar2,
                           p_regla number) return varchar2
    is
        l_retorna varchar2(100);
        l_grupo_max number;
        l_pidm_prof number;
        l_crn   varchar2(100);
        l_periodo varchar2(100);
        l_parte_periodo varchar2(3);
        l_campus varchar2(3);
        schd varchar2(3);
        title varchar2(100);
        credit number;
        credit_bill number;
        gmod     NUMBER;
        f_inicio             DATE;
        f_fin                DATE;
        sem                  NUMBER;
        l_term_nrc  varchar2(30);
        l_nivel varchar2(3);
        l_short_name varchar2(100);
        l_pwd  varchar2(100);
    begin

        BEGIN

            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,SZTALGO_PTRM_CODE_NEW,SZTALGO_CAMP_CODE,SZTALGO_LEVL_CODE
            INTO l_periodo,l_parte_periodo,l_campus,l_nivel
            FROM SZTALGO
            WHERE 1 = 1
            AND SZTALGO_NO_REGLA = P_REGLA;


        EXCEPTION WHEN OTHERS THEN

            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,SZTALGO_PTRM_CODE_NEW,SZTALGO_CAMP_CODE,SZTALGO_LEVL_CODE
            INTO l_periodo,l_parte_periodo,l_campus,l_nivel
            FROM SZTALGO
            WHERE 1 = 1
            AND SZTALGO_NO_REGLA = P_REGLA
            AND ROWNUM = 1;

        END;

        BEGIN

            select DECODE (SUBSTR(l_periodo,1,2),'02','01',SUBSTR(l_periodo,1,2))||SUBSTR(l_periodo,3,5)dato
            into l_periodo
            from dual;
        EXCEPTION WHEN OTHERS THEN
           NULL;
        END;


        BEGIN
           select DECODE (SUBSTR(l_parte_periodo,1,1),'A','M',SUBSTR(l_parte_periodo,1,1))||SUBSTR(l_parte_periodo,2,4)dato
           into l_parte_periodo
           from dual;
        EXCEPTION WHEN OTHERS THEN
           NULL;
        END;

        BEGIN

           select DECODE (SUBSTR(l_parte_periodo,1,2),'02','01',SUBSTR(l_parte_periodo,1,2))||SUBSTR(l_parte_periodo,3,5)dato
           into l_parte_periodo
           from dual;
        EXCEPTION WHEN OTHERS THEN
           NULL;
        END;


        begin
            select spriden_pidm
            into l_pidm_prof
            from spriden
            where 1 = 1
            and spriden_change_ind is null
            and spriden_id = p_prof_id;

        exception when others then
            null;
        end;


        BEGIN
                 INSERT INTO sirasgn VALUES(
                                            l_periodo,
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
                                            NULL
                                            );
            l_retorna:='EXITO';

        EXCEPTION WHEN OTHERS THEN
             l_retorna:='Error al insertar sirasgn '||sqlerrm;
        END;


        return(l_retorna);
    end;
--
--
     function f_alumno_manual(
                             p_periodo        varchar2,
                             p_parte          varchar2,
                             p_pidm           number,
                             p_crn            varchar2,
                             p_inicio_clases  varchar2,
                             p_regla number,
                             p_grupo varchar2,
                             p_materia varchar2 ) return varchar2
    is
        l_retorna varchar2(100);
        l_grupo_max number;
        l_pidm_prof number;
        l_crn   varchar2(100);
        l_periodo varchar2(100);
        l_parte_periodo varchar2(3);
        l_campus varchar2(3);
        schd varchar2(3);
        title varchar2(100);
        credit number;
        credit_bill number;
        gmod     NUMBER;
        f_inicio             DATE;
        f_fin                DATE;
        sem                  NUMBER;
        l_term_nrc  varchar2(30);
        l_nivel varchar2(3);
        l_short_name varchar2(100);
        l_pwd  varchar2(100);
    begin
        BEGIN

            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,SZTALGO_PTRM_CODE_NEW,SZTALGO_CAMP_CODE,SZTALGO_LEVL_CODE
            INTO l_periodo,l_parte_periodo,l_campus,l_nivel
            FROM SZTALGO
            WHERE 1 = 1
            AND SZTALGO_NO_REGLA = P_REGLA;


        EXCEPTION WHEN OTHERS THEN

            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,SZTALGO_PTRM_CODE_NEW,SZTALGO_CAMP_CODE,SZTALGO_LEVL_CODE
            INTO l_periodo,l_parte_periodo,l_campus,l_nivel
            FROM SZTALGO
            WHERE 1 = 1
            AND SZTALGO_NO_REGLA = P_REGLA
            AND ROWNUM = 1;

        END;

        BEGIN

            select DECODE (SUBSTR(l_periodo,1,2),'02','01',SUBSTR(l_periodo,1,2))||SUBSTR(l_periodo,3,5)dato
            into l_periodo
            from dual;
        EXCEPTION WHEN OTHERS THEN
           NULL;
        END;


        BEGIN
           select DECODE (SUBSTR(l_parte_periodo,1,1),'A','M',SUBSTR(l_parte_periodo,1,1))||SUBSTR(l_parte_periodo,2,4)dato
           into l_parte_periodo
           from dual;
        EXCEPTION WHEN OTHERS THEN
           NULL;
        END;

        BEGIN

           select DECODE (SUBSTR(l_parte_periodo,1,2),'02','01',SUBSTR(l_parte_periodo,1,2))||SUBSTR(l_parte_periodo,3,5)dato
           into l_parte_periodo
           from dual;
        EXCEPTION WHEN OTHERS THEN
           NULL;
        END;

        if p_crn != '00' AND p_crn is not null then

            BEGIN

                INSERT INTO sfrstcr VALUES(
                                            p_periodo,     --SFRSTCR_TERM_CODE
                                            p_pidm,     --SFRSTCR_PIDM
                                            p_crn,     --SFRSTCR_CRN
                                            1,     --SFRSTCR_CLASS_SORT_KEY
                                            p_grupo,    --SFRSTCR_REG_SEQ
                                            p_parte,    --SFRSTCR_PTRM_CODE
                                            'RE',     --SFRSTCR_RSTS_CODE
                                            SYSDATE,    --SFRSTCR_RSTS_DATE
                                            NULL,    --SFRSTCR_ERROR_FLAG
                                            NULL,    --SFRSTCR_MESSAGE
                                            credit_bill,    --SFRSTCR_BILL_HR
                                            3, --SFRSTCR_WAIV_HR
                                            null,--credit,     --SFRSTCR_CREDIT_HR
                                            null,--credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                            null,--credit,     --SFRSTCR_CREDIT_HR_HOLD
                                            null,--gmod,     --SFRSTCR_GMOD_CODE
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
                                            SYSDATE,      --SFRSTCR_ADD_DATE
                                            Sysdate,     --SFRSTCR_ACTIVITY_DATE
                                            l_nivel,     --SFRSTCR_LEVL_CODE
                                            l_campus,     --SFRSTCR_CAMP_CODE
                                            p_materia,     --SFRSTCR_RESERVED_KEY
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
                                            'PRONOSTICO '||p_regla,    --SFRSTCR_DATA_ORIGIN
                                            SYSDATE,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                            'N',  --SFRSTCR_DEPT_OVER
                                            'N',  --SFRSTCR_ATTS_OVER
                                            'N', --SFRSTCR_CHRT_OVER
                                            p_grupo , --SFRSTCR_RMSG_CDE
                                            NULL,  --SFRSTCR_WL_PRIORITY
                                            NULL,  --SFRSTCR_WL_PRIORITY_ORIG
                                            NULL,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                            NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                            'N', --SFRSTCR_MEXC_OVER
                                            1,--SFRSTCR_STSP_KEY_SEQUENCE
                                            NULL,--SFRSTCR_BRDH_SEQ_NUM
                                            '01',--SFRSTCR_BLCK_CODE
                                            NULL,--SFRSTCR_STRH_SEQNO
                                            NULL, --SFRSTCR_STRD_SEQNO
                                            NULL,  --SFRSTCR_SURROGATE_ID
                                            NULL, --SFRSTCR_VERSION
                                            USER,--SFRSTCR_USER_ID
                                            null --SFRSTCR_VPDI_CODE
                                          );
                l_retorna:='EXITO';



            EXCEPTION WHEN OTHERS THEN
                l_retorna:=('Error al insertar  SFRSTCR '||sqlerrm);
            END;

        else

            l_retorna:=('Esta grupo no tiene CRN en Banner verifica ');

        end if;

        return(l_retorna);
    end;

--
--
    function f_agrega_crn(p_periodo        varchar2,
                          p_parte          varchar2,
                          p_pidm           number,
                          p_inicio_clases  varchar2,
                          p_regla number,
                          p_grupo varchar2,
                          p_materia varchar2,
                          p_subj varchar2,
                          p_numb varchar2) return varchar2
    is
        l_retorna varchar(200);
        l_grupo_max number;
        l_pidm_prof number;
        l_crn   varchar(200);
        l_periodo varchar2(100);
        l_parte_periodo varchar2(3);
        l_campus varchar2(3);
        schd varchar2(3);
        title varchar2(100);
        credit number;
        credit_bill number;
        gmod     NUMBER;
        f_inicio             DATE;
        f_fin                DATE;
        sem                  NUMBER;
        l_term_nrc  varchar2(30);
        l_nivel varchar2(3);
        l_short_name varchar2(100);
        l_pwd  varchar2(100);
        l_order number;
        l_programa varchar2(100);
        l_matricula varchar2(9);
        l_valida number;
    begin

        pkg_algoritmo.P_ENA_DIS_TRG('D','SATURN.SZT_SSBSECT_POSTINSERT_ROW');
        pkg_algoritmo.P_ENA_DIS_TRG('D','SATURN.SZT_SIRASGN_POSTINSERT_ROW');
        pkg_algoritmo.P_ENA_DIS_TRG('D','SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');

        BEGIN

            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,SZTALGO_PTRM_CODE_NEW,SZTALGO_CAMP_CODE,SZTALGO_LEVL_CODE
            INTO l_periodo,l_parte_periodo,l_campus,l_nivel
            FROM SZTALGO
            WHERE 1 = 1
            AND SZTALGO_NO_REGLA = P_REGLA;


        EXCEPTION WHEN OTHERS THEN

            SELECT DISTINCT SZTALGO_TERM_CODE_NEW,SZTALGO_PTRM_CODE_NEW,SZTALGO_CAMP_CODE,SZTALGO_LEVL_CODE
            INTO l_periodo,l_parte_periodo,l_campus,l_nivel
            FROM SZTALGO
            WHERE 1 = 1
            AND SZTALGO_NO_REGLA = P_REGLA
            AND ROWNUM = 1;


        END;

        BEGIN

            select DECODE (SUBSTR(l_periodo,1,2),'02','01',SUBSTR(l_periodo,1,2))||SUBSTR(l_periodo,3,5)dato
            into l_periodo
            from dual;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;


        BEGIN
            select DECODE (SUBSTR(l_parte_periodo,1,1),'A','M',SUBSTR(l_parte_periodo,1,1))||SUBSTR(l_parte_periodo,2,4)dato
            into l_parte_periodo
            from dual;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

         BEGIN

            select DECODE (SUBSTR(l_parte_periodo,1,2),'02','01',SUBSTR(l_parte_periodo,1,2))||SUBSTR(l_parte_periodo,3,5)dato
            into l_parte_periodo
            from dual;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

        BEGIN

            SELECT NVL(MAX(ssbsect_crn),1000)+1
            INTO l_crn
            FROM ssbsect
            WHERE 1 = 1
            AND ssbsect_term_code= l_periodo;

        EXCEPTION WHEN OTHERS THEN
            l_crn := NULL;
        END;


        begin

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
            AND scbcrse_subj_code=p_subj
            AND scbcrse_crse_numb=p_numb
            AND scbcrse_eff_term='000000'
            AND scrschd_subj_code=scbcrse_subj_code
            AND scrschd_crse_numb=scbcrse_crse_numb
            AND scrschd_eff_term=scbcrse_eff_term;

        exception when others then

           schd         := NULL;
           title        := NULL;
           credit       := NULL;
           credit_bill  := NULL;

        end;

        BEGIN

            SELECT scrgmod_gmod_code
            INTO gmod
            FROM scrgmod
            WHERE 1 = 1
            AND scrgmod_subj_code=p_subj
            AND scrgmod_crse_numb=p_numb
            AND scrgmod_default_ind='D';

        EXCEPTION WHEN OTHERS THEN
            gmod:='1';
        END;


        BEGIN

           SELECT DISTINCT sobptrm_start_date,
                           sobptrm_end_date,
                           sobptrm_weeks
           INTO f_inicio,
                f_fin,
                sem
           FROM sobptrm
           WHERE 1  = 1
           AND sobptrm_term_code=l_periodo
           AND sobptrm_ptrm_code=l_parte_periodo;

        EXCEPTION WHEN OTHERS THEN
          --  vl_error := 'No se Encontro configuracion para el Periodo= ' ||c.periodo ||' y Parte de Periodo= '||c.parte ||SQLERRM;
          null;
        END;

        BEGIN

           SELECT DISTINCT sobptrm_start_date,
                           sobptrm_end_date,
                           sobptrm_weeks
           INTO f_inicio,
                f_fin,
                sem
           FROM sobptrm
           WHERE 1  = 1
           AND sobptrm_term_code=l_periodo
           AND sobptrm_ptrm_code=l_parte_periodo;

        EXCEPTION WHEN OTHERS THEN
            --vl_error := 'No se Encontro configuracion para el Periodo= ' ||c.periodo ||' y Parte de Periodo= '||c.parte ||SQLERRM;
            null;
        END;


        IF l_campus ='UTS' THEN

            l_campus:='UTL';

        END IF;

        BEGIN

           select nvl(max(crn),1000)+1
           into l_crn
           from
           (
               select case when
                                   substr(SSBSECT_CRN,1,1) in('L','M','D','A') then to_number(substr(SSBSECT_CRN,2,100))+1
                         else
                               to_number(SSBSECT_CRN)
                       end crn
               from ssbsect
               where ssbsect_term_code= l_periodo
           );

        EXCEPTION WHEN OTHERS THEN
           l_crn := NULL;
        END;


        if l_nivel ='LI' then

            l_crn:='L'||l_crn;

        else

            l_crn:='M'||l_crn;

        end if;

        begin

            select SZTPRONO_PROGRAM
            into l_programa
            from sztprono
            where 1 = 1
            and sztprono_no_regla = p_regla
            and sztprono_pidm = p_pidm
            and rownum = 1;


        exception when others then
            l_programa:=null;
        end;

        begin

            select spriden_id
            into l_matricula
            from spriden
            where 1 = 1
            and spriden_change_ind is null
            and spriden_pidm = p_pidm;


        exception when others then
            null;
        end;

        BEGIN

            select count(*)
            into l_valida
            from tztordr
            where 1 = 1
            and TZTORDR_CAMPUS = l_campus
            and TZTORDR_NIVEL  = l_nivel
            and TZTORDR_PROGRAMA = l_programa
            and TZTORDR_FECHA_INICIO =p_inicio_clases
            and TZTORDR_TERM_CODE  =l_periodo
            and TZTORDR_PIDM = p_pidm
            and TZTORDR_ESTATUS ='N';

        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;


        if l_valida = 0 then

            BEGIN

                select count(*)+1
                into l_order
                from tztordr
                where 1 = 1
                and TZTORDR_CAMPUS = l_campus
                and TZTORDR_NIVEL  = l_nivel
                and TZTORDR_PROGRAMA = l_programa
                and TZTORDR_FECHA_INICIO =p_inicio_clases
                and TZTORDR_TERM_CODE  =l_periodo
                and TZTORDR_PIDM = p_pidm;

            EXCEPTION WHEN OTHERS THEN
                NULL;
            END;


            BEGIN

                INSERT INTO TZTORDR VALUES(l_campus,
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
                                           null,
                                           null,
                                           null,
                                           l_periodo
                                          );

            EXCEPTION WHEN OTHERS THEN
                dbms_output.put_line('Error al insertar  TZTORDR '||sqlerrm);
            END;

        end if;

        BEGIN

            INSERT INTO ssbsect VALUES (
                                        l_periodo,           --SSBSECT_TERM_CODE
                                        l_crn,               --SSBSECT_CRN
                                        l_parte_periodo,     --SSBSECT_PTRM_CODE
                                        p_subj,              --SSBSECT_SUBJ_CODE
                                        p_numb,              --SSBSECT_CRSE_NUMB
                                        p_grupo,     --SSBSECT_SEQ_NUMB
                                        'A',    --SSBSECT_SSTS_CODE
                                        'ENL',    --SSBSECT_SCHD_CODE
                                        l_campus,    --SSBSECT_CAMP_CODE
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
                                        90, --SSBSECT_MAX_ENRL
                                        0,--SSBSECT_ENRL
                                        50,--SSBSECT_SEATS_AVAIL
                                        NULL,--SSBSECT_TOT_CREDIT_HRS
                                        '0',--SSBSECT_CENSUS_ENRL
                                        f_inicio,--SSBSECT_CENSUS_ENRL_DATE
                                        SYSDATE,--SSBSECT_ACTIVITY_DATE
                                        p_inicio_clases,--SSBSECT_PTRM_START_DATE
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
                                        'PRONOSTICO '||p_regla,--SSBSECT_DATA_ORIGIN
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
            l_retorna:='EXITO';

        EXCEPTION WHEN OTHERS THEN
            l_retorna:='Error al insertar ssbsect '||sqlerrm;
        END;

        BEGIN
                 INSERT INTO sirasgn VALUES(
                                            l_periodo,
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
                                            'PRONOSTICO '||p_regla,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL,
                                            NULL
                                            );
            l_retorna:='EXITO';

        EXCEPTION WHEN OTHERS THEN
             l_retorna:='Error al insertar sirasgn '||sqlerrm;
        END;

        BEGIN

            INSERT INTO sfrstcr VALUES(
                                        p_periodo,     --SFRSTCR_TERM_CODE
                                        p_pidm,     --SFRSTCR_PIDM
                                        l_crn,     --SFRSTCR_CRN
                                        1,     --SFRSTCR_CLASS_SORT_KEY
                                        p_grupo,    --SFRSTCR_REG_SEQ
                                        p_parte,    --SFRSTCR_PTRM_CODE
                                        'RE',     --SFRSTCR_RSTS_CODE
                                        SYSDATE,    --SFRSTCR_RSTS_DATE
                                        NULL,    --SFRSTCR_ERROR_FLAG
                                        NULL,    --SFRSTCR_MESSAGE
                                        credit_bill,    --SFRSTCR_BILL_HR
                                        3, --SFRSTCR_WAIV_HR
                                        null,--credit,     --SFRSTCR_CREDIT_HR
                                        null,--credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                        null,--credit,     --SFRSTCR_CREDIT_HR_HOLD
                                        null,--gmod,     --SFRSTCR_GMOD_CODE
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
                                        SYSDATE,      --SFRSTCR_ADD_DATE
                                        Sysdate,     --SFRSTCR_ACTIVITY_DATE
                                        l_nivel,     --SFRSTCR_LEVL_CODE
                                        l_campus,     --SFRSTCR_CAMP_CODE
                                        p_materia,     --SFRSTCR_RESERVED_KEY
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
                                        'PRONOSTICO '||p_regla,    --SFRSTCR_DATA_ORIGIN
                                        SYSDATE,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                        'N',  --SFRSTCR_DEPT_OVER
                                        'N',  --SFRSTCR_ATTS_OVER
                                        'N', --SFRSTCR_CHRT_OVER
                                        p_grupo , --SFRSTCR_RMSG_CDE
                                        NULL,  --SFRSTCR_WL_PRIORITY
                                        NULL,  --SFRSTCR_WL_PRIORITY_ORIG
                                        NULL,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                        NULL, --SFRSTCR_INCOMPLETE_EXT_DATE
                                        'N', --SFRSTCR_MEXC_OVER
                                        1,--SFRSTCR_STSP_KEY_SEQUENCE
                                        NULL,--SFRSTCR_BRDH_SEQ_NUM
                                        '01',--SFRSTCR_BLCK_CODE
                                        NULL,--SFRSTCR_STRH_SEQNO
                                        NULL, --SFRSTCR_STRD_SEQNO
                                        NULL,  --SFRSTCR_SURROGATE_ID
                                        NULL, --SFRSTCR_VERSION
                                        USER,--SFRSTCR_USER_ID
                                        null --SFRSTCR_VPDI_CODE
                                      );
            l_retorna:='EXITO';



        EXCEPTION WHEN OTHERS THEN
            l_retorna:=('Error al insertar  SFRSTCR '||sqlerrm);
        END;

        pkg_algoritmo.P_ENA_DIS_TRG('E','SATURN.SZT_SSBSECT_POSTINSERT_ROW');
        pkg_algoritmo.P_ENA_DIS_TRG('E','SATURN.SZT_SIRASGN_POSTINSERT_ROW');
        pkg_algoritmo.P_ENA_DIS_TRG('E','SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');

        commit;

        return(l_retorna);
    end;
--
--

    function f_reasigna_prof(
                            p_pidm      number,
                            p_fecha_inicio varchar2,
                            p_materia      varchar2,
                            p_grupo         varchar2
                            )return varchar2
    is

        l_retorna varchar2(200):='EXITO';
        l_valida number;

    begin

        begin

            select count(*)
            into l_valida
            from sirasgn
            where 1 = 1
            and (SIRASGN_TERM_CODE,sirasgn_crn) in (SELECT SSBSECT_TERM_CODE,SSBSECT_CRN
                                                    FROM ssbsect
                                                    WHERE SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB in (select SZTMACO_MATHIJO
                                                                                                    from sztmaco
                                                                                                    where SZTMACO_MATPADRE = p_materia
                                                                                         )
                                                    and  SSBSECT_PTRM_START_DATE = TO_DATE(p_fecha_inicio,'DD/MM/YYYY')
                                                    and  SSBSECT_SEQ_NUMB =  p_grupo)

            AND SIRASGN_PIDM = p_pidm;


        exception when others then
            l_valida:=0;
        end;


        if l_valida > 0 then

            begin

                UPDATE sirasgn SET   SIRASGN_PRIMARY_IND ='N'
                where 1 = 1
                and (SIRASGN_TERM_CODE,sirasgn_crn) in (SELECT SSBSECT_TERM_CODE,SSBSECT_CRN
                                                        FROM ssbsect
                                                        WHERE SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB in (select SZTMACO_MATHIJO
                                                                                                        from sztmaco
                                                                                                        where SZTMACO_MATPADRE = p_materia
                                                                                             )
                                                        and  SSBSECT_PTRM_START_DATE = TO_DATE(p_fecha_inicio,'DD/MM/YYYY')
                                                        and  SSBSECT_SEQ_NUMB =  p_grupo)

                AND SIRASGN_PIDM = p_pidm;
            EXCEPTION WHEN OTHERS THEN
                l_retorna:='Error al actualizar profesor  pidm '||p_pidm||' ora error '||sqlerrm;
            END;

            commit;

        else

            l_retorna:='No existen registos para actualizar ';

        end if;

        return(l_retorna);
    end;
--
--
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
        l_contador   number:=0;
        l_Sql        VARCHAR2(2000);
        l_materia_taller   varchar2(20);


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

                        dbms_output.put_line(' entramos 1 ');

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
                                    WHERE SZTCOMA_SUBJ_CODE_BAN||SZTCOMA_CRSE_NUMB_BAN = a.sztconf_subj_code) mat_conv,
                                    sztconf_idioma idioma
                                FROM sztconf a
                                WHERE 1 = 1
                                AND sztconf_no_regla = p_regla
                                and SZTCONF_ESTATUS_CERRADO ='N'
                            )x
                            where 1 = 1
--and materia='L1C101'                            
                            Order by materia, grupo
--                            and materia ='M1ED102'
                        )
             LOOP

                dbms_output.put_line('Procesando Materia:'||c.materia||' Grupo:'||c.GRupo||' Idioma:'||c.idioma);

                 vl_cont_reza:= vl_cont_reza+1;

                 vl_materia:= null;

                 IF c.mat_conv IS NULL THEN

                 vl_materia := c.materia;

                 else

                 vl_materia := c.mat_conv;

                 end if;


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
                
                dbms_output.put_line('entra 1');
                l_materia_taller:=null;
                BEGIN
                    SELECT UPPER(scrsyln_long_course_title)
                    INTO l_desripcion_mat
                    FROM scrsyln
                    WHERE 1 = 1
                    AND scrsyln_subj_code||scrsyln_crse_numb =c.materia;

                EXCEPTION WHEN OTHERS THEN
                    Begin
                            SELECT Distinct SZTMADI_MATPADRE, UPPER(sztmadi_matasigna_descripcion)
                            INTO l_materia_taller, l_desripcion_mat
                            FROM sztmadi
                            WHERE 1 = 1
                            AND sztmadi.SZTMADI_MATASIGNA=c.materia
--                            AND SZTMADI_CAMP_CODE= l_campus
                            AND sztmadi.SZTMADI_LEVL_CODE=l_nivel;
                        
                    Exception When Others Then
                        dbms_output.put_line(' Error en SCRSYLN '||SQLERRM);
                        l_retorna:=' No se econtro descripcion para materia  '||c.materia||' '||sqlerrm;
                    End;

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


                dbms_output.put_line(' Nivel '||l_nivel);

                if   l_nivel <> 'EC' then



                      for x in (SELECT DISTINCT
                                        decode(substr(SZTALGO_TERM_CODE_NEW,1,2),'02','01'||substr(SZTALGO_TERM_CODE_NEW,3,5),SZTALGO_TERM_CODE_NEW) periodo,
                                        decode(substr(SZTALGO_PTRM_CODE_NEW,1,1),'A','M'||substr(SZTALGO_PTRM_CODE_NEW,2,3),SZTALGO_PTRM_CODE_NEW) ptrm,
                                        SZTALGO_FECHA_NEW  fecha_inicio
                                FROM sztalgo
                                WHERE 1 = 1
                                AND sztalgo_no_regla = p_regla
                                and SZTALGO_FECHA_NEW = (select max(SZTALGO_FECHA_NEW)
                                                         from sztalgo
                                                         where 1 = 1
                                                         and sztalgo_no_regla = p_regla)
                                order by 2 desc

                            )loop



                                  l_short_name:=f_get_short_name(x.ptrm,x.periodo,c.materia,x.fecha_inicio);

                                  BEGIN
                                         INSERT INTO sztgpme VALUES(
                                                                        c.materia||c.grupo,
                                                                        Nvl(l_materia_taller,c.materia),
                                                                        l_desripcion_mat,
                                                                        5,
                                                                        NULL,
                                                                        USER,
                                                                        SYSDATE,
                                                                        x.ptrm,
                                                                        x.fecha_inicio,
                                                                        null,
                                                                        c.maximo,--number
                                                                        l_nivel ,
                                                                        l_campus,
                                                                        NULL,--number
                                                                        c.materia,
                                                                        NULL,
                                                                        x.periodo ,
                                                                        NULL,
                                                                        NULL,
                                                                        NULL,-- number
                                                                        l_short_name,
                                                                        p_regla,-- number
                                                                        l_secuencia,-- number
                                                                        c.grupo2,-- number
                                                                        'S',
                                                                        1--number
                                                                        ,c.idioma
                                                                        );

                                      l_retorna:='EXITO';

                                      dbms_output.put_line(' entramos 3 Materia'||c.Materia||' Grupo:'||c.grupo||' idioma:'||c.idioma);
                                        exit;
                                  EXCEPTION WHEN OTHERS THEN
                                      dbms_output.put_line(' Error en al insertar gpme  grupo '||c.materia||c.grupo||' error '||SQLERRM);
                                      exit;
                                      --l_retorna:=' Error en al insertar gpme  '||sqlerrm;
                                      null;
                                  END;

                                  commit;


                            end loop;

                else

                    l_contador:=0;

                    dbms_output.put_line(' entra a EC ');

                     for x in (
                                SELECT DISTINCT
                                               sztprono_term_code periodo,
                                               sztprono_ptrm_code ptrm,
                                               SZTPRONO_FECHA_INICIO_NW  fecha_inicio,
                                               SZTPRONO_SECUENCIA secuencia
                                FROM sztprono
                                WHERE 1 = 1
                                AND sztprono_no_regla  = p_regla
                                and sztprono_materia_legal =c.materia
                                order by 3
                            )loop

                                  l_contador:=l_contador+1;

                                  l_short_name:=f_get_short_name(x.ptrm,x.periodo,c.materia,x.fecha_inicio);

                                  if x.secuencia= 1 then

                                      BEGIN
                                             INSERT INTO sztgpme VALUES(
                                                                            c.materia||c.grupo,
                                                                            Nvl(l_materia_taller,c.materia),
                                                                            l_desripcion_mat,
                                                                            0,
                                                                            NULL,
                                                                            USER,
                                                                            SYSDATE,
                                                                            x.ptrm,
                                                                            x.fecha_inicio,
                                                                            NULL,
                                                                            c.maximo,
                                                                            l_nivel ,
                                                                            'UTS',
                                                                            NULL,
                                                                            c.materia,
                                                                            NULL,
                                                                            x.periodo ,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            l_short_name,
                                                                            p_regla,
                                                                            x.secuencia,
                                                                            c.grupo2,
                                                                            'S',
                                                                            1 ,c.idioma
                                                                            );

                                          l_retorna:='EXITO';

                                          dbms_output.put_line(' entramos 3');

                                      EXCEPTION WHEN OTHERS THEN
                                          dbms_output.put_line(' Error en al insertar gpme  grupo '||c.materia||c.grupo||' error '||SQLERRM||' ptrm '||x.ptrm);
                                          --l_retorna:=' Error en al insertar gpme  '||sqlerrm;
                                          null;
                                      END;

                                  else

                                      BEGIN
                                             INSERT INTO sztgpme VALUES(
                                                                            c.materia||c.grupo,
                                                                            Nvl(l_materia_taller,c.materia),
                                                                            l_desripcion_mat,
                                                                            5,
                                                                            NULL,
                                                                            USER,
                                                                            SYSDATE,
                                                                            x.ptrm,
                                                                            x.fecha_inicio,
                                                                            NULL,
                                                                            c.maximo,
                                                                            l_nivel ,
                                                                            l_campus,
                                                                            NULL,
                                                                            c.materia,
                                                                            NULL,
                                                                            x.periodo ,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            l_short_name,
                                                                            p_regla,
                                                                            x.secuencia,
                                                                            c.grupo2,
                                                                            'S',
                                                                            1,c.idioma
                                                                            );

                                          l_retorna:='EXITO';

                                          dbms_output.put_line(' entramos 3');

                                      EXCEPTION WHEN OTHERS THEN
                                          dbms_output.put_line(' Error en al insertar gpme  grupo '||c.materia||c.grupo||' error '||SQLERRM||' ptrm '||x.ptrm);
                                          --l_retorna:=' Error en al insertar gpme  '||sqlerrm;
                                          null;
                                      END;



                                  end if;

                                  exit when l_contador = 1;

                                  commit;


                            end loop;


                end if;

             END LOOP;


             COMMIT;
        ELSE
            dbms_output.put_line(' Esta regla no esta cerrada '||p_regla);
            l_retorna:='Esta regla no esta cerrada '||l_regla_cerrada;
            return(l_retorna);

        END IF;

        return(l_retorna);


    end;
--
--
    FUNCTION f_prof_moodl(p_inicio_clase in varchar, p_regla in number)return varchar2
    as
        l_retorna  varchar2(1000):='EXITO';
        l_regla_cerrada varchar2(1);
        l_pwd           varchar2(100);
        l_id            varchar(20);
        l_pidm          number;
        l_secuenia      number;
        l_grupo         number;
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
                        select SZTGPME_TERM_NRC padre,
                               sztgpme_no_regla regla,
                               SZTGPME_PTRM_CODE ptrm,
                               SZTGPME_SECUENCIA secuencia,
                               length (SZTGPME_TERM_NRC) largo,
                               length (SZTGPME_TERM_NRC)  -1 SUBT,
                               SZTGPME_SUBJ_CRSE_comp materia,
                               tO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) GRUPO,
                               SZTGPME_START_DATE fecha_inicio,
                               SZTGPME_LEVL_CODE nivel
                               ,SZTGPME_IDIOMA idioma
                        from sztgpme me
                        where 1 = 1
                        and sztgpme_no_regla = P_REGLA
                        and  exists(select null
                                       from sztconf
                                       where 1 = 1
                                       and sztconf_no_regla = P_REGLA
                                       AND SZTCONF_SUBJ_CODE = SZTGPME_SUBJ_CRSE_comp
                                       and SZTCONF_ESTATUS_CERRADO='N'
                                       )
                       order by 4
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
                            --and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')     = p_inicio_clase
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
                           and pac.GOZTPAC_ID  =l_id
                           and GOZTPAC_PIN is not null
                           and rownum = 1;

                        exception when others then
                            dbms_output.put_line(' Error al obtener pwd '||sqlerrm||' pidm '||l_pidm);
                            l_retorna:=' Error al obtener pwd '||sqlerrm||' regla  '||p_regla ||' grupo '||c.grupo||' materia '||c.materia;
                        end;


                       IF l_pwd IS NOT NULL THEN

                            if c.secuencia is null then

                               begin
                                    select max(SZTCONF_SECUENCIA)
                                    into c.secuencia
                                    from sztconf;
                               exception when others then
                                    c.secuencia:=0;
                               end;


                            end if;


                            if c.nivel <> 'EC' then

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
                                                               c.fecha_inicio,
                                                               c.regla,
                                                               c.secuencia,
                                                               1, c.idioma
                                                               );
                                    l_retorna:='EXITO';

                                exception when others then
                                    dbms_output.put_line(' Error al insertar tabla de profesores moodl '||sqlerrm);
                                    l_retorna:= ' Error al insertar tabla de profesores moodl '||sqlerrm;
                                end;

                            else

                                IF c.secuencia = 1 then

                                    begin

                                        INSERT INTO SZSGNME VALUES(c.padre,
                                                                   l_pidm,
                                                                   sysdate,
                                                                   user,
                                                                   '0',
                                                                   null,
                                                                   l_pwd,
                                                                   null,
                                                                   'AC',
                                                                   c.secuencia,
                                                                   null,
                                                                   c.ptrm,
                                                                   c.fecha_inicio,
                                                                   c.regla,
                                                                   c.secuencia,
                                                                   1, c.idioma
                                                                   );
                                        l_retorna:='EXITO';

                                    exception when others then
                                        dbms_output.put_line(' Error al insertar tabla de profesores moodl '||sqlerrm);
                                        l_retorna:= ' Error al insertar tabla de profesores moodl '||sqlerrm;
                                    end;

                                else



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
                                                                   c.fecha_inicio,
                                                                   c.regla,
                                                                   c.secuencia,
                                                                   1, c.idioma
                                                                   );
                                        l_retorna:='EXITO';

                                    exception when others then
                                        dbms_output.put_line(' Error al insertar tabla de profesores moodl '||sqlerrm);
                                        l_retorna:= ' Error al insertar tabla de profesores moodl '||sqlerrm;
                                    end;
                                end if;

                            end if;

                            BEGIN

                                UPDATE SZTCONF SET SZTCONF_ESTATUS_CERRADO='S'
                                WHERE 1 = 1
                                AND SZTCONF_SUBJ_CODE  =c.materia
                                and sztconf_no_regla =p_regla
                                and SZTCONF_GROUP = c.grupo;

                            EXCEPTION WHEN OTHERS THEN
                                dbms_output.put_line(' Error al actualizar grupos pronostico '||SQLERRM);
                                l_retorna:=' Error al actualizar grupos pronostico '||sqlerrm;

                            END;


                       END IF;

                    end loop;

                    commit;

        else

           dbms_output.put_line(' Esta regla no esta cerrada '||p_regla);
           l_retorna:='Esta regla no esta cerrada ';

        end if;

        return(l_retorna);
    end;
--
--
function f_alumnos_moodl_utel(p_inicio_clase in VARCHAR2, 
                                         p_regla in NUMBER, 
                                         p_filtro_utl varchar2 default null)return varchar2
    as
    l_retorna            varchar2(1000):='EXITO';
    l_regla_cerrada      varchar2(1);
    l_contar             number;
    l_numero_grupos      number;
    vl_alumnos           number :=0;
    l_cuenta_alumnos     number;
    l_numero_alumnos     number;
    l_total              number;
    l_grupo_disponible   varchar2(100);
    l_numero_alumnos2    number;
    l_alum_extranjeros        constant number :=7;   --Desminuye el total de alumnos por grupo para alums extranjeros
    l_alum_sentados      number; 
    l_tope_grupos        number;
    l_total_alumnos      number;
    l_sobrecupo          number;
    l_cuenta_grupo       number;
    l_estatus_gaston     varchar2(10);
    l_descripcion_error  varchar2(500);
    l_exists_taller      number;
    l_cuenta_uve         number;
    l_sincro_grupo       number;
    l_sincro_prof        number;
    v_tipo_alumno        NUMBER;
    v_inicio_clases      DATE;
    
    lc_solo_utl         constant varchar2(10):='SOLO_UTL';
    lc_sin_utl         constant varchar2(10):='SIN_UTL';
    lc_camp_utl        constant varchar2(10):='UTL'; 
    
    cursor cur_alumnos_taller(p_regla NUMBER, p_materia_comp VARCHAR2,  p_idioma VARCHAR2) is
        select DISTINCT 
            sztprono_id matricula,
            SZTPRONO_PIDM pidm,
            'RE'  estatus_alumno,
            (select GOZTPAC_PIN
             from GOZTPAC pac
             where pac.GOZTPAC_pidm = ono.SZTPRONO_PIDM) pwd,
            SZTPRONO_COMENTARIO comentario,
            65 tope,
            SZTPRONO_PROGRAM programa,
            sztprono_materia_legal materia,
            Decode(substr(sztprono_jornada,3,1),'I',1,'C',2,'S',3,'R',4,5)  ord_jor,            
            SZTPRPA_PRI_PADRE pri_padre,
            SZTPRPA_PROGRAM   prog_padre,
            SZTPRPA_prghijo   prog_hijo,    
            pr.Ord_on_s
        from sztprono ono
        join as_alumnos on as_alumnos_no_regla = sztprono_no_regla 
                         and sztprono_pidm = SGBSTDN_PIDM
        left join SZTPRPA on SZTPRPA_prghijo = sztprono_program 
                         and SZTPRPA_CAMP_CODE_HIJO = campus
        left join (
            select Max(sztdtec_term_code) TERM,
                   case when SZTDTEC_MOD_TYPE = 'S' THEN 1 ELSE 2 END ORD_ON_S,
                   SZTDTEC_PROGRAM program
            from sztdtec
            group by SZTDTEC_PROGRAM, SZTDTEC_MOD_TYPE
        ) pr on pr.program = sztprono_program
        where sztprono_no_regla = p_regla
          and SZTPRONO_ESTATUS_ERROR = 'N'
          and SZTPRONO_ENVIO_MOODL = 'N'
          and sztprono_materia_banner = p_materia_comp
          and sztprono_materia_legal <> sztprono_materia_banner
          and not exists (
              select 1 from szstume 
              where szstume_no_regla = sztprono_no_regla 
                and szstume_pidm = sztprono_pidm 
                and szstume_subj_code = sztprono_materia_legal
          )
          and pkg_algoritmo.f_prog_idioma(campus, sztprono_program) = p_idioma
        order by pri_padre, pr.ORD_ON_S, ord_jor, substr(sztprono_id, 3, 7);
 
        
    Cursor cur_alumnos_normales(p_regla NUMBER, p_materia VARCHAR2, p_idioma VARCHAR2) is
        select DISTINCT 
            sztprono_id matricula,
            SZTPRONO_PIDM pidm,
            'RE'  estatus_alumno,
            (select GOZTPAC_PIN
             from GOZTPAC pac
             where pac.GOZTPAC_pidm = ono.SZTPRONO_PIDM) pwd,
            SZTPRONO_COMENTARIO comentario,
            65 tope,
            SZTPRONO_PROGRAM programa,
            sztprono_materia_legal materia,
            Decode(substr(sztprono_jornada,3,1),'I',1,'C',2,'S',3,'R',4,5)  ord_jor,            
            SZTPRPA_PRI_PADRE pri_padre,
            SZTPRPA_PROGRAM   prog_padre,
            SZTPRPA_prghijo   prog_hijo,    
            pr.Ord_on_s
        from sztprono ono
        join as_alumnos on as_alumnos_no_regla = sztprono_no_regla 
                         and sztprono_pidm = SGBSTDN_PIDM
        left join SZTPRPA on SZTPRPA_prghijo = sztprono_program 
                         and SZTPRPA_CAMP_CODE_HIJO = campus
        left join (
            select Max(sztdtec_term_code) TERM,
                   case when SZTDTEC_MOD_TYPE = 'S' THEN 1 ELSE 2 END ORD_ON_S,
                   SZTDTEC_PROGRAM program
            from sztdtec
            group by SZTDTEC_PROGRAM, SZTDTEC_MOD_TYPE
        ) pr on pr.program = sztprono_program
        where sztprono_no_regla = p_regla
          and SZTPRONO_ESTATUS_ERROR = 'N'
          and SZTPRONO_ENVIO_MOODL = 'N'
          and sztprono_materia_legal = p_materia
          and Not Exists(Select 1 from sztmadi where sztmadi_matasigna= sztprono_materia_banner)
          and not exists (
              select 1 from szstume 
              where szstume_no_regla = sztprono_no_regla 
                and szstume_pidm = sztprono_pidm 
                and szstume_subj_code = sztprono_materia_legal
          )
          and pkg_algoritmo.f_prog_idioma(campus, sztprono_program) = p_idioma
          AND (
              p_filtro_utl is null
              OR (p_filtro_utl = lc_solo_utl AND campus = lc_camp_utl)
              OR (p_filtro_utl = lc_sin_utl AND campus <> lc_camp_utl)
          )                      
        order by pri_padre, pr.ORD_ON_S, ord_jor, substr(sztprono_id, 3, 7);
        
        -- Procedimiento auxiliar para insertar alumno y actualizar SZTPRONO
        PROCEDURE p_inserta_alumno (
            p_padre           IN VARCHAR2,
            p_pidm            IN NUMBER,
            p_matricula       IN VARCHAR2,
            p_pwd             IN VARCHAR2,
            p_estatus         IN VARCHAR2,
            p_materia         IN VARCHAR2,
            p_inicio_clases   IN DATE,
            p_regla           IN NUMBER,
            p_secuencia       IN NUMBER,
            p_sqno            IN NUMBER,
            p_grupo           IN NUMBER,
            p_materia_legal   IN VARCHAR2,
            p_materia_banner  IN VARCHAR2,
            p_l_exists_taller IN NUMBER
        ) IS
        BEGIN
            l_contar := l_contar + 1;

            DBMS_OUTPUT.PUT_LINE('Padre: ' || p_padre || ' Alumno: ' || p_matricula || ' Contar: ' || l_contar || ' Tope Grupo: ' || l_numero_alumnos2);

            BEGIN
                INSERT INTO SZSTUME VALUES (
                    p_padre,
                    p_pidm,
                    p_matricula,
                    SYSDATE,
                    USER,
                    v_tipo_alumno,
                    NULL,
                    p_pwd,
                    NULL,
                    1,
                    p_estatus,
                    0,
                    p_materia,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    p_materia,
                    p_inicio_clases,
                    p_regla,
                    p_secuencia,
                    p_sqno,
                    0,
                    NULL
                );
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error al insertar: ' || SQLERRM);
            END;

            BEGIN
                UPDATE SZTPRONO
                   SET SZTPRONO_ENVIO_MOODL = 'S',
                       SZTPRONO_GRUPO_ASIG = p_grupo
                 WHERE SZTPRONO_PIDM = p_pidm
                   AND ((p_l_exists_taller > 0 AND SZTPRONO_MATERIA_BANNER = p_materia_banner)
                     OR (p_l_exists_taller = 0 AND SZTPRONO_MATERIA_LEGAL = p_materia_legal))
                   AND SZTPRONO_NO_REGLA = p_regla
                   AND SZTPRONO_ENVIO_MOODL = 'N';
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END p_inserta_alumno;
    
    begin


        begin

            select count(*)
            into l_cuenta_uve
            from sztalgo
            where 1 = 1
            and sztalgo_no_regla = p_regla
            and SZTALGO_CAMP_CODE ='UVE';

        exception when others then
            null;
        end;

        BEGIN

            SELECT DISTINCT trim(SZTALGO_ESTATUS_CERRADO),SZTALGO_TOPE_ALUMNOS,SZTALGO_SOBRECUPO_ALUMNOS
            INTO  l_regla_cerrada,l_tope_grupos,l_sobrecupo
            FROM sztalgo
            WHERE 1 = 1
            AND sztalgo_no_regla = p_regla;

        EXCEPTION WHEN OTHERS THEN
--            raise_application_error (-20002,'Error al   '||sqlerrm);
            null;
        END;

          dbms_output.put_line( 'cuenta uve  '||l_cuenta_uve||' l_regla_cerrada  '||l_regla_cerrada||'l_tope_grupos '|| l_tope_grupos||'l_sobrecupo '||l_sobrecupo);
                
        IF l_regla_cerrada = 'S' THEN
            dbms_output.put_line(' ********************* INICIA PROCESO INTEGRACION UTEL ************************');
            pkg_algoritmo.p_track_prono(p_regla,'INICIA PROCESO INTEGRACION UTEL');

            l_contar:=0;
            l_numero_alumnos:=0;

            if l_cuenta_uve = 0 then

                 dbms_output.put_line('entra diferente uve');

                for c in (
                             select SZTGPME_TERM_NRC padre,
                                    sztgpme_no_regla regla,
                                    sztgpme_subj_crse materia,
                                    sztgpme_subj_crse_comp materia_comp,
                                    to_char(SZTGPME_START_DATE,'DD/MM/YYYY') inicio_clases,
                                    tO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) grupo,
                                    SZTGPME_SECUENCIA secuencia,
                                    SZTGPME_NIVE_SEQNO sqno,
--                                    sztgpme_camp_code campus,
                                    SZTGPME_LEVL_CODE nivel,
                                    SZTGPME_idioma idioma
                            from sztgpme grp
                            where 1 = 1
                            and sztgpme_no_regla = p_regla
                            and SZTGPME_START_DATE = p_inicio_clase
                            and SZTGPME_LEVL_CODE <>'EC'                            
--and sztgpme_subj_crse = 'L3HE403' 
and SZTGPME_TERM_NRC not like  '%X'                         
--                            and  tO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) not in (select
--                                                                                                                         tO_NUMBER (SUBSTR (SZSTUME_TERM_NRC,LENGTH (SZSTUME_TERM_NRC) - 1,100))
--                                                                                                                 from szstume
--                                                                                                                 where 1 = 1
--                                                                                                                 and szstume_no_regla =grp.sztgpme_no_regla
--                                                                                                                 and SZSTUME_SUBJ_CODE = grp.sztgpme_subj_crse
--and szstume_term_nrc not like '%X'                                                                                                                 
--                                                                                                                 AND not exists (select null
--                                                                                                                                 from SZTPREXT
--                                                                                                                                 where 1 = 1
--                                                                                                                                 and SZTPREXT_pidm = szstume_pidm
--                                                                                                                                 and SZTPREXT_no_regla = szstume_no_regla
--                                                                                                                                 and SZTPREXT_MATERIA_CAMBIO = szstume_subj_code
--                                                                                                                                 and SZTPREXT_CON_GRUPO ='S')
--                                                                                                                 )
                        UNION
                        select SZTGPME_TERM_NRC padre,
                                    sztgpme_no_regla regla,
                                    sztgpme_subj_crse materia,
                                    sztgpme_subj_crse_comp materia_comp,
                                    to_char(SZTGPME_START_DATE,'DD/MM/YYYY') inicio_clases,
                                    tO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) grupo,
                                    SZTGPME_SECUENCIA secuencia,
                                    SZTGPME_NIVE_SEQNO sqno,
--                                    sztgpme_camp_code campus,
                                    SZTGPME_LEVL_CODE nivel,
                                    SZTGPME_idioma idioma
                            from sztgpme grp
                            where 1 = 1
                            and sztgpme_no_regla = p_regla
--                            and SZTGPME_START_DATE = p_inicio_clase
                            and SZTGPME_LEVL_CODE ='EC'
--and sztgpme_subj_crse = 'M1AN101' 
--                            and  tO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) not in (select
--                                                                                                                         tO_NUMBER (SUBSTR (SZSTUME_TERM_NRC,LENGTH (SZSTUME_TERM_NRC) - 1,100))
--                                                                                                                 from szstume
--                                                                                                                 where 1 = 1
--                                                                                                                 and szstume_no_regla =grp.sztgpme_no_regla
--                                                                                                                 and SZSTUME_SUBJ_CODE = grp.sztgpme_subj_crse
--                                                                                                                 AND not exists (select null
--                                                                                                                                 from SZTPREXT
--                                                                                                                                 where 1 = 1
--                                                                                                                                 and SZTPREXT_pidm = szstume_pidm
--                                                                                                                                 and SZTPREXT_no_regla = szstume_no_regla
--                                                                                                                                 and SZTPREXT_MATERIA_CAMBIO = szstume_subj_code
--                                                                                                                                 and SZTPREXT_CON_GRUPO ='S')
--                                                                                                                 )
                        order by materia,materia_comp, grupo
                        )
                        loop

                                    dbms_output.put_line(' Materia: '||c.materia||
                                                         ' Materia_Comp: '||c.materia_comp||
                                                         ' Grupo: '||c.grupo||
                                                         ' nrc: '||c.PADRE||
                                                         ' grupo:'||c.grupo||
                                                         ' idioma:'||c.idioma);
                                    l_exists_taller:=0;
                                    If c.materia <> c.materia_comp then 
                                        Begin
                                            Select count(1) Into l_exists_taller
                                            from sztmadi 
                                            Where sztmadi_matpadre=c.materia
                                            and sztmadi_matasigna=c.materia_comp
--                                            and sztmadi_camp_code=c.campus
                                            and sztmadi_levl_code=c.nivel;
                                        Exception When Others Then
                                            l_exists_taller:=0;
                                        End;
                                    end if;

                                     for e in(select count(*) vueltas
                                                 from sztconf onf
                                                 where 1 = 1
                                                 and onf.sztconf_no_regla = c.regla
                                                 and onf.SZTCONF_FECHA_INICIO =c.inicio_clases
--                                                 and SZTCONF_SUBJ_CODE=c.materia
                                                AND ((l_exists_taller > 0 AND SZTCONF_SUBJ_CODE = c.materia_comp)
                                                   OR(l_exists_taller = 0 AND SZTCONF_SUBJ_CODE = c.materia)
                                                    )                                                            
                                                 AND SZTCONF_GROUP = c.grupo
                                                 and sztconf_idioma = c.idioma
                                     )
                                     loop

                                            begin

                                                select SZTCONF_STUDENT_NUMB
                                                into l_numero_alumnos2
                                                from sztconf
                                                where 1 = 1
                                                and sztconf_no_regla  = c.regla
--                                                and sztconf_subj_code = c.materia
                                                AND ((l_exists_taller > 0 AND SZTCONF_SUBJ_CODE = c.materia_comp)
                                                   OR(l_exists_taller = 0 AND SZTCONF_SUBJ_CODE = c.materia)
                                                    )                                                            
                                                and to_number(SZTCONF_GROUP)= c.grupo;
                                            exception when others then
                                                null;
                                            end;

                                            BEgin
                                                Select count(1) into l_alum_sentados
                                                From szstume
                                                Where szstume_no_regla = c.regla
                                                and szstume_term_nrc= c.PADRE;
                                            exception
                                                when no_data_found then
                                                    l_alum_sentados:=0;
                                                when others then
                                                    l_alum_sentados:=0;
                                            End;
                                            


                                            IF p_filtro_utl = lc_solo_utl THEN
                                                l_numero_alumnos2 := l_numero_alumnos2 - l_alum_extranjeros;
                                            else 
                                                l_numero_alumnos2 := l_numero_alumnos2 - l_alum_sentados;
                                            END IF;                                            

                                            IF  l_numero_alumnos2 <= 0 THEN
                                                Continue; --Grupo lleno al tope.
                                            END IF;

                                            l_contar:=0;

                                            IF l_exists_taller > 0 THEN
                                                FOR d IN cur_alumnos_taller(c.regla, c.materia_comp, c.idioma) LOOP
                                                    -- Lógica de tipo de alumno
                                                    v_tipo_alumno := CASE
                                                                        WHEN c.nivel = 'EC' AND c.secuencia = 1 THEN 0
                                                                        WHEN c.nivel = 'EC' THEN 5
                                                                        ELSE 5
                                                                    END;

                                                    v_inicio_clases := CASE
                                                                        WHEN c.nivel = 'EC' THEN c.inicio_clases
                                                                        ELSE p_inicio_clase
                                                                    END;
                                            dbms_output.put_line(' Entra alumnos con taller regla '||c.regla||' alumnos numero '||l_numero_alumnos2||
                                                    ' inicio clases '||c.inicio_clases||' Materia '||c.materia||'  nivel '||c.nivel||
                                                    ' l_exist_taller:'||l_exists_taller||' idioma:'||c.idioma);
                                                    
                                                    p_inserta_alumno(c.padre, d.pidm, d.matricula, d.pwd, d.estatus_alumno,
                                                                     c.materia, v_inicio_clases, c.regla, c.secuencia, c.sqno,
                                                                     c.grupo, c.materia, c.materia_comp, l_exists_taller);

                                                    EXIT WHEN l_contar = l_numero_alumnos2;
                                                END LOOP;
                                            ELSE
                                                FOR d IN cur_alumnos_normales(c.regla, c.materia,  c.idioma) LOOP
                                                    v_tipo_alumno := CASE
                                                        WHEN c.nivel = 'EC' AND c.secuencia = 1 THEN 0
                                                        WHEN c.nivel = 'EC' THEN 5
                                                        ELSE 5
                                                    END;

                                                    v_inicio_clases := CASE
                                                        WHEN c.nivel = 'EC' THEN c.inicio_clases
                                                        ELSE p_inicio_clase
                                                    END;
                                            dbms_output.put_line(' Entra alumnos sin taller regla '||c.regla||' alumnos numero '||l_numero_alumnos2||
                                                    ' inicio clases '||c.inicio_clases||' Materia '||c.materia||'  nivel '||c.nivel||
                                                    ' l_exist_taller:'||l_exists_taller||' idioma:'||c.idioma);
                                                    
                                                    p_inserta_alumno(c.padre, d.pidm, d.matricula, d.pwd, d.estatus_alumno,
                                                                     c.materia, v_inicio_clases, c.regla, c.secuencia, c.sqno,
                                                                     c.grupo, c.materia, c.materia_comp, l_exists_taller);

                                                    EXIT WHEN l_contar = l_numero_alumnos2;
                                                END LOOP;
                                            END IF;
                                          
                                            Commit; --Frank@Mod_July23 commit por tot de alum x materia
                            pkg_algoritmo.p_track_prono(p_regla,' Materia  '||c.materia||' Grupo '||c.grupo||
                                        ' nrc '||c.materia||c.grupo||' TotAlumInsert:'||l_contar||' TopeXGpo:'||l_numero_alumnos2||
                                        ' ProcUtel_Local');  

                                    end loop;
                        end loop;

            else

                for c in (
                             select SZTGPME_TERM_NRC padre,
                                    sztgpme_no_regla regla,
                                    sztgpme_subj_crse materia,
                                    sztgpme_subj_crse_comp materia_comp,                                    
                                    to_char(SZTGPME_START_DATE,'DD/MM/YYYY') inicio_clases,
                                    tO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) grupo,
                                    SZTGPME_SECUENCIA secuencia,
                                    sztgpme_camp_code campus,
                                    SZTGPME_LEVL_CODE nivel,                                    
                                    SZTGPME_NIVE_SEQNO sqno, 
                                    sztgpme_idioma idioma
                            from sztgpme grp
                            where 1 = 1
                            and sztgpme_no_regla = p_regla
                            and SZTGPME_START_DATE = p_inicio_clase
                            and SZTGPME_TERM_NRC not like '%X'
                            and  tO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) not in (select
                                                                                                                         tO_NUMBER (SUBSTR (SZSTUME_TERM_NRC,LENGTH (SZSTUME_TERM_NRC) - 1,100))
                                                                                                                 from szstume
                                                                                                                 where 1 = 1
                                                                                                                 and szstume_no_regla =grp.sztgpme_no_regla
                                                                                                                 and SZSTUME_SUBJ_CODE = grp.sztgpme_subj_crse
and SZSTUME_TERM_NRC        not like '%X'                                                                                                           
                                                                                                                 AND not exists (select null
                                                                                                                                 from SZTPREXT
                                                                                                                                 where 1 = 1
                                                                                                                                 and SZTPREXT_pidm = szstume_pidm
                                                                                                                                 and SZTPREXT_no_regla = szstume_no_regla
                                                                                                                                 and SZTPREXT_MATERIA_CAMBIO = szstume_subj_code
                                                                                                                                 and SZTPREXT_CON_GRUPO ='S')
                                                                                                                 )
                        order by materia,grupo
                        )
                        loop

                                    dbms_output.put_line(' Materia: '||c.materia||
                                                         ' Materia_Comp: '||c.materia_comp||
                                                         ' Grupo: '||c.grupo||
                                                         ' nrc: '||c.materia||c.grupo);
                                    l_exists_taller:=0;
                                    If c.materia <> c.materia_comp then 
                                        Begin
                                            Select count(1) Into l_exists_taller
                                            from sztmadi 
                                            Where sztmadi_matpadre=c.materia
                                            and sztmadi_matasigna=c.materia_comp
                                            and sztmadi_camp_code=c.campus
                                            and sztmadi_levl_code=c.nivel;
                                        Exception When Others Then
                                            l_exists_taller:=0;
                                        End;
                                    end if;

                                     for e in(select count(*) vueltas
                                                 from sztconf onf
                                                 where 1 = 1
                                                 and onf.sztconf_no_regla = c.regla
                                                 and onf.SZTCONF_FECHA_INICIO =c.inicio_clases
--                                                 and SZTCONF_SUBJ_CODE=c.materia
                                                AND ((l_exists_taller > 0 AND SZTCONF_SUBJ_CODE = c.materia_comp)
                                                   OR(l_exists_taller = 0 AND SZTCONF_SUBJ_CODE = c.materia)
                                                    )                                                    
                                                 AND SZTCONF_GROUP = c.grupo
                                                 and sztconf_idioma = c.idioma
                                     )
                                     loop

                                            begin

                                                select SZTCONF_STUDENT_NUMB
                                                into l_numero_alumnos2
                                                from sztconf
                                                where 1 = 1
                                                and sztconf_no_regla  = c.regla
                                                and sztconf_subj_code = c.materia
                                                AND ((l_exists_taller > 0 AND SZTCONF_SUBJ_CODE = c.materia_comp)
                                                   OR(l_exists_taller = 0 AND SZTCONF_SUBJ_CODE = c.materia)
                                                    ) 
                                                and to_number(SZTCONF_GROUP)= c.grupo;
                                            exception when others then
                                                null;
                                            end;



                                           dbms_output.put_line(' Entra alumno no alumnos regla '||c.regla||' alumnos numero '||l_numero_alumnos2||' inicio clases '||c.inicio_clases||' Materia '||c.materia||' alumno ');
                                            l_contar:=0;

                                             for d in (
                                                            select DISTINCT sztprono_id matricula,
                                                                  SZTPRONO_PIDM pidm,
                                                                   'RE'  estatus_alumno,
                                                                   (select GOZTPAC_PIN
                                                                     from GOZTPAC pac
                                                                     where 1 = 1
                                                                     and pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM ) pwd,
                                                                     SZTPRONO_COMENTARIO comentario,
                                                                     65 tope,
                                                                     SZTPRONO_PROGRAM programa,
                                                                     sztprono_materia_legal materia,
                                                                    --Frank@July.2023 Integración de Alumnos Ordenados Programa padre, hijo, jornada, matricula         
                                                                    Decode(substr(sztprono_jornada,3,1),'I',1,'C',2,'S',3,'R',4,5)  ord_jor,          
                                                            --          Substr(sztprono_jornada,3,1) J,
                                                                      SZTPRPA_PRI_PADRE pri_padre,
                                                                      SZTPRPA_PROGRAM   prog_padre,
                                                            --          SZTPRPA_PRI_hijo  pri_hijo,
                                                                      SZTPRPA_prghijo   prog_hijo                                                                             
                                                                    --Frank@July.2023 Integración de Alumnos Ordenados Programa padre, hijo, jornada, matricula         
                                                                    ,pr.Ord_on_s --FRank@Sep23: se agrega el programa tipo Online o Ejecutivo para agrupar alumns                                                                                                                                                  
                                                            from sztprono ono
                                                                join as_alumnos on as_alumnos_no_regla=sztprono_no_regla and sztprono_pidm = SGBSTDN_PIDM   --Frank@July.2023
                                                                left join SZTPRPA on SZTPRPA_prghijo = sztprono_program and SZTPRPA_CAMP_CODE_HIJO = campus --Frank@July.2023                                                           
                                                                    --FRank@Sep23: se agrega el programa tipo Online o Ejecutivo para agrupar alumns
                                                                    left join (select Max(sztdtec_term_code) TERM, case when SZTDTEC_MOD_TYPE = 'S' THEN 1 ELSE 2 END ORD_ON_S , SZTDTEC_PROGRAM program
                                                                                from sztdtec                                                                                                                                        
                                                                                group by SZTDTEC_PROGRAM, SZTDTEC_MOD_TYPE) pr on pr.program =  sztprono_program
                                                                    --FRank@Sep23: se agrega el programa tipo Online o Ejecutivo para agrupar alumns                                                                                                                                                                                                       
                                                        where 1 = 1
                                                        and sztprono_no_regla  = c.regla
--                                                        and sztprono_materia_legal = c.materia
                                                        AND SZTPRONO_ESTATUS_ERROR ='N'
                                                        And SZTPRONO_ENVIO_MOODL = 'N'
                                                        AND ((l_exists_taller > 0 AND sztprono_materia_banner = c.materia_comp)
                                                           OR(l_exists_taller = 0 AND sztprono_materia_legal = c.materia)
                                                            )                                                         
                                                            AND sztprono_secuencia = (select distinct ZSTPARA_PARAM_VALOR
                                                                                      from ZSTPARA
                                                                                      where 1 = 1
                                                                                      and ZSTPARA_MAPA_ID ='CAMP_UVE' )
                                                            And not exists(select 1 from szstume 
                                                                            where szstume_no_regla=sztprono_no_regla 
                                                                                and szstume_pidm=sztprono_pidm 
                                                                                and szstume_subj_code = sztprono_materia_legal)  
                                                            and pkg_algoritmo.f_prog_idioma(campus, sztprono_program) = c.idioma                                                                                                                                                                     
                                                            Order by pri_padre,  ord_jor, substr(sztprono_id,3,7)                                       --Frank@July.2023
                                                      )
                                                  loop

                                                                l_contar:=l_contar+1;
                                                              dbms_output.put_line(' Padre  '||c.padre||' Alumno '||d.matricula||' Contar '||l_contar||' Tope Grupo '||l_numero_alumnos2);
                                                              begin

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
                                                                                              0,
                                                                                              c.materia,
                                                                                              null,--D.semi,-- c.nivel,
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
                                                                                              c.sqno,
                                                                                              0,
                                                                                              null
                                                                                              );



                                                              exception when others then

                                                                   dbms_output.put_line(' Error al insertar '||sqlerrm);

                                                              end;

                                                              BEGIN

                                                                   UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='S',
                                                                                       SZTPRONO_GRUPO_ASIG =c.grupo
                                                                   WHERE SZTPRONO_PIDM =d.pidm
                                                                    AND ((l_exists_taller > 0 AND sztprono_materia_banner = c.materia_comp)
                                                                       OR(l_exists_taller = 0 AND sztprono_materia_legal = c.materia)
                                                                        )                                                                                                                            
                                                                   and SZTPRONO_NO_REGLA = c.regla
                                                                   and SZTPRONO_ENVIO_MOODL ='N';

                                                              EXCEPTION WHEN OTHERS THEN

                                                                   null;
                                                              END;

                                                              exit when l_contar =l_numero_alumnos2;


                                                  end loop;
                                            
                                            Commit; --Frank@Mod_July23 commit por tot de alum x materia

                                    end loop;
                        end loop;

            end if;


        end if;

        commit;

        RETURN(l_retorna);

    end f_alumnos_moodl_utel;
--
--
function f_alumnos_moodl_latam(p_inicio_clase in VARCHAR2, p_regla in NUMBER)return varchar2
    as
    l_retorna            varchar2(1000):='EXITO';
    l_regla_cerrada      varchar2(1);
    l_contar             number;
    l_numero_alumnos     number;
    l_numero_alumnos2    number;

    Cursor orden is 
        --Alumnos excluidos ordenados por el campus con mayor alumnos primeramente.
        WITH ex AS (
            SELECT DISTINCT 
                sztprono_pidm pidm, 
                sztprono_no_regla regla, 
                sztprono_materia_legal materia,
                xmate.ZSTPARA_PARAM_VALOR tope
            FROM sztprono
            JOIN tztprogM p 
                ON p.pidm = sztprono_pidm 
                AND p.estatus = 'MA' 
            JOIN zstpara xcamp 
                ON xcamp.zstpara_mapa_id = 'EX_CAMPUS' 
                AND p.campus IN xcamp.zstpara_param_id -- Incluye Campus
            JOIN zstpara xmate 
                ON xmate.zstpara_mapa_id = 'MATERIA_INTEGRA' 
                AND sztprono_materia_legal IN xmate.zstpara_param_id -- Incluye Materias
            WHERE sztprono_no_regla = p_regla
              AND SZTPRONO_ENVIO_MOODL = 'N'
              AND SZTPRONO_ESTATUS_ERROR = 'N'
        )
        ,campus_totals AS (
            SELECT 
                campus, 
                COUNT(distinct sztprono_pidm) AS total_alumnos
            FROM sztprono
            JOIN as_alumnos 
                ON as_alumnos_no_regla = sztprono_no_regla
                AND sztprono_pidm = sgbstdn_pidm   
            Join ex on ex.pidm = sztprono_pidm 
                    AND ex.regla = sztprono_no_regla
                    AND ex.materia = sztprono_materia_legal          
            WHERE sztprono_no_regla = p_regla
              AND SZTPRONO_ENVIO_MOODL = 'N'
              AND SZTPRONO_ESTATUS_ERROR = 'N'
            GROUP BY campus
        )
        SELECT 
            COUNT(sztprono_id) AS no_alumno,
            sztprono_materia_legal AS materia,
            as_alumnos.campus,
            pkg_algoritmo.f_prog_idioma(as_alumnos.campus, sztprono_program) AS idioma,
            campus_totals.total_alumnos,
            ex.tope tope
        FROM sztprono
        JOIN as_alumnos 
            ON as_alumnos_no_regla = sztprono_no_regla
            AND sztprono_pidm = sgbstdn_pidm
        JOIN campus_totals 
            ON campus_totals.campus = as_alumnos.campus
        Join ex on ex.pidm = sztprono_pidm 
                AND ex.regla = sztprono_no_regla
                AND ex.materia = sztprono_materia_legal          
        WHERE sztprono_no_regla = p_regla
          AND SZTPRONO_ENVIO_MOODL = 'N'
          AND SZTPRONO_ESTATUS_ERROR = 'N'
--and sztprono_materia_legal='L3HE403'          
        GROUP BY 
            as_alumnos.campus, 
            sztprono_materia_legal, 
            pkg_algoritmo.f_prog_idioma(as_alumnos.campus, sztprono_program), 
            campus_totals.total_alumnos, ex.tope
        ORDER BY 
            campus_totals.total_alumnos DESC, 
            as_alumnos.campus, 
            no_alumno DESC;

        Cursor grupo_mate(p_materia in varchar2, p_idioma varchar) is
                 select SZTGPME_TERM_NRC padre,
                        sztgpme_no_regla regla,
                        sztgpme_subj_crse materia,
                        to_char(SZTGPME_START_DATE,'DD/MM/YYYY') inicio_clases,
                        tO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) grupo,
                        SZTGPME_SECUENCIA secuencia,
                        SZTGPME_NIVE_SEQNO sqno,
                        SZTGPME_LEVL_CODE nivel,
                        SZTGPME_idioma idioma
                from sztgpme grp
                where 1 = 1
                and sztgpme_no_regla = p_regla
                and SZTGPME_START_DATE = p_inicio_clase
                and sztgpme_subj_crse = p_materia
                and SZTGPME_idioma = p_idioma
--and sztgpme_subj_crse='L3HE403'                 
                and SZTGPME_TERM_NRC not like  '%X'                         
                and  tO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) not in (select
                                                                                                             tO_NUMBER (SUBSTR (SZSTUME_TERM_NRC,LENGTH (SZSTUME_TERM_NRC) - 1,100))
                                                                                                     from szstume
                                                                                                     where 1 = 1
                                                                                                     and szstume_no_regla =grp.sztgpme_no_regla
                                                                                                     and SZSTUME_SUBJ_CODE = grp.sztgpme_subj_crse
                and szstume_term_nrc not like '%X'                                                                                                                 
                                                                                                     AND not exists (select null
                                                                                                                     from SZTPREXT
                                                                                                                     where 1 = 1
                                                                                                                     and SZTPREXT_pidm = szstume_pidm
                                                                                                                     and SZTPREXT_no_regla = szstume_no_regla
                                                                                                                     and SZTPREXT_MATERIA_CAMBIO = szstume_subj_code
                                                                                                                     and SZTPREXT_CON_GRUPO ='S')
                                                                                                     )                                                                                                             
            order by 5;

    Cursor alum_mate (p_regla number, p_materia varchar, p_campus varchar2, p_idioma varchar2) is
        select DISTINCT sztprono_id matricula,
                  SZTPRONO_PIDM pidm,
                   'RE'  estatus_alumno,
                   (select GOZTPAC_PIN
                     from GOZTPAC pac
                     where 1 = 1
                     and pac.GOZTPAC_pidm =ono.SZTPRONO_PIDM ) pwd,
                     SZTPRONO_COMENTARIO comentario,
                     65 tope,
                     SZTPRONO_PROGRAM programa,
                     sztprono_materia_legal materia,
                    --Frank@July.2023 Integración de Alumnos Ordenados Programa padre, hijo, jornada, matricula         
                    Decode(substr(sztprono_jornada,3,1),'I',1,'C',2,'S',3,'R',4,5)  ord_jor,            
                    SZTPRPA_PRI_PADRE pri_padre,
                    SZTPRPA_PROGRAM   prog_padre,
--                                                                    SZTPRPA_PRI_hijo  pri_hijo,
                    SZTPRPA_prghijo   prog_hijo        
                    --Frank@July.2023 Integración de Alumnos Ordenados Programa padre, hijo, jornada, matricula                                                                                                                                                    
                      ,pr.Ord_on_s --FRank@Sep23: se agrega el programa tipo Online o Ejecutivo para agrupar alumns                                                                     
          from sztprono ono
                JOIN tztprogM p 
                    ON p.pidm = sztprono_pidm 
                    AND p.estatus = 'MA' 
                JOIN zstpara xcamp 
                    ON xcamp.zstpara_mapa_id = 'EX_CAMPUS' 
                    AND p.campus IN xcamp.zstpara_param_id -- Incluye Campus
                JOIN zstpara xmate 
                    ON xmate.zstpara_mapa_id = 'MATERIA_INTEGRA' 
                    AND sztprono_materia_legal IN xmate.zstpara_param_id -- Incluye Materias
                left join SZTPRPA on SZTPRPA_prghijo = sztprono_program and SZTPRPA_CAMP_CODE_HIJO = campus  --Frank@July.2023                                                              
                  --FRank@Sep23: se agrega el programa tipo Online o Ejecutivo para agrupar alumns                                                                    
                left join (select Max(sztdtec_term_code) TERM, case when SZTDTEC_MOD_TYPE = 'S' THEN 1 ELSE 2 END ORD_ON_S , SZTDTEC_PROGRAM program
                              from sztdtec
                            group by SZTDTEC_PROGRAM, SZTDTEC_MOD_TYPE) pr on pr.program =  sztprono_program
                --FRank@Sep23: se agrega el programa tipo Online o Ejecutivo para agrupar alumns
          where 1 = 1
          and sztprono_no_regla  = p_regla
          and sztprono_materia_legal = p_materia
--and sztprono_materia_legal='L1C101'                    
          and p.campus = p_campus
            AND SZTPRONO_ESTATUS_ERROR ='N'
            And SZTPRONO_ENVIO_MOODL = 'N'
            And not exists(select 1 from szstume 
                            where szstume_no_regla=sztprono_no_regla 
                                and szstume_pidm=sztprono_pidm 
                                and szstume_subj_code = sztprono_materia_legal) 
            and pkg_algoritmo.f_prog_idioma(p.campus, sztprono_program) = p_idioma
            Order by pri_padre,  pr.ORD_ON_S, ord_jor, substr(sztprono_id,3,7); --Frank@July.2023     

    
    begin  --inicio proceso
        --Frank@Modify@Nov23 se reordena de nuevo los grupos y alumnos de prono ya que cuando se llega la integración a moodle ya hubo cambios (ABC de alumnos)  
        declare 
            lc_result varchar2(999);
        Begin
            lc_result:= F_CARGA_PRONO_END(p_regla);
        End;
        --Frank@Modify@Nov23
        
        BEGIN

            SELECT DISTINCT trim(SZTALGO_ESTATUS_CERRADO)
            INTO  l_regla_cerrada
            FROM sztalgo
            WHERE 1 = 1
            AND sztalgo_no_regla = p_regla;

        EXCEPTION WHEN OTHERS THEN
--            raise_application_error (-20002,'Error al   '||sqlerrm);
            null;
        END;
                
        IF l_regla_cerrada = 'S' THEN
            dbms_output.put_line(' ********************* INICIA PROCESO INTEGRACION LATAM ************************');
            pkg_algoritmo.p_track_prono(p_regla,'INICIA PROCESO INTEGRACION LATAM');
            
            l_contar:=0;
            l_numero_alumnos:=0;

                FOR ord IN orden LOOP  --Ordena materias segun campus vs materia latam
                        for c in grupo_mate(ord.materia, ord.idioma) loop  --grupos y materias

                            dbms_output.put_line(' Materia  '||c.materia||' Grupo '||c.grupo||' nrc '||c.materia||c.grupo);

                                 for e in(select count(*) vueltas
                                             from sztconf onf
                                             where 1 = 1
                                             and onf.sztconf_no_regla = c.regla
                                             and onf.SZTCONF_FECHA_INICIO =c.inicio_clases
                                             and SZTCONF_SUBJ_CODE=c.materia
                                             AND SZTCONF_GROUP = c.grupo
                                             and sztconf_idioma = c.idioma
                                 )
                                 loop
                                        l_numero_alumnos2:=ord.tope; --tope por grupo 
                                        dbms_output.put_line(' Entra alumno no alumnos regla '||c.regla||' alumnos numero '||l_numero_alumnos2||
                                                                ' inicio clases '||c.inicio_clases||' Materia '||c.materia||'  nivel '||c.nivel||
                                                                ' Campus:'||ord.campus||' Idioma:'||ord.idioma);
                                        l_contar:=0;

                                         for d in alum_mate (c.regla,c.materia,ord.campus,ord.idioma) loop

                                                    l_contar:=l_contar+1;
                                                    dbms_output.put_line(' Padre  '||c.padre||' Alumno '||d.matricula||'Contar '||l_contar||' Tope Grupo '||l_numero_alumnos2);
                                                    begin

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
                                                                                    0,
                                                                                    c.materia,
                                                                                    null,--D.semi,-- c.nivel,
                                                                                    null,
                                                                                    null,--  c.ptrm,
                                                                                    null,
                                                                                    null,
                                                                                    null,
                                                                                    null,
                                                                                    c.materia,
                                                                                    p_inicio_clase,
                                                                                    --c.inicio_clases,
                                                                                    c.regla,
                                                                                    c.secuencia,
                                                                                    c.sqno,
                                                                                    0,
                                                                                    null
                                                                                    );

                                                    exception when others then
                                                         dbms_output.put_line(' Error al insertar '||sqlerrm);
                                                    end;

                                                      BEGIN
                                                           UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='S',
                                                                               SZTPRONO_GRUPO_ASIG =c.grupo
                                                           WHERE 1 = 1
                                                           and SZTPRONO_MATERIA_LEGAL = c.materia
                                                           and SZTPRONO_PIDM =d.pidm
                                                           and SZTPRONO_NO_REGLA = c.regla
                                                           and SZTPRONO_ENVIO_MOODL ='N';
                                                      EXCEPTION WHEN OTHERS THEN
                                                           null;
                                                      END;
                                                  exit when l_contar =l_numero_alumnos2;
                                        end loop;
                                end loop;
                            pkg_algoritmo.p_track_prono(p_regla,' Materia  '||c.materia||' Grupo '||c.grupo||
                                        ' nrc '||c.materia||c.grupo||' TotAlumInsert:'||l_contar||' TopeXGpo:'||l_numero_alumnos2||
                                        ' ProcLatam');                                
                        end loop;
                END LOOP;  --End Orde
            end if;

        RETURN(l_retorna);

end f_alumnos_moodl_latam;
--
--
function f_alumnos_moodl_compact(p_inicio_clase in VARCHAR2, p_regla in NUMBER)return varchar2
    as
    l_retorna            varchar2(1000):='EXITO';
    l_regla_cerrada      varchar2(1);
    l_contar             number;
    l_numero_alumnos     number;
    l_numero_alumnos2    number;

    Cursor orden is 
        --Materias con grupos menores a 50 
        SELECT 
            COUNT(sztprono_id) AS no_alumno,
--            sztprono_materia_legal AS materia,
            sztprono_materia_banner AS materia,                        
            p.campus,
            pkg_algoritmo.f_prog_idioma(p.campus, sztprono_program) AS idioma,
            50 as  tope
        FROM SZTPRONO
            JOIN TZTPROGM P
                ON P.PIDM = SZTPRONO_PIDM AND P.ESTATUS = 'MA' 
            join (Select szstume_no_regla regla, szstume_subj_code materia, 
                            szstume_term_nrc nrc, count(1) tot
                    from szstume  where szstume_no_regla=p_regla
                    group by szstume_term_nrc, szstume_no_regla, szstume_subj_code
                    having count(1) < 50
                ) tume on tume.materia = sztprono_materia_legal and regla=sztprono_no_regla
        Where sztprono_no_regla=p_Regla
                      AND SZTPRONO_ENVIO_MOODL = 'N'
                      AND SZTPRONO_ESTATUS_ERROR = 'N'
--and sztprono_materia_legal='L3HE403'                      
        Group by sztprono_materia_banner,p.campus,
                    pkg_algoritmo.f_prog_idioma(p.campus, sztprono_program), 50
        Order by p.Campus,materia,no_alumno;

        Cursor grupo_mate(p_materia in varchar2, p_idioma varchar) is
                 select SZTGPME_TERM_NRC padre,
                        sztgpme_no_regla regla,
--                        sztgpme_subj_crse materia,
                                    sztgpme_subj_crse_comp materia,                        
                        to_char(SZTGPME_START_DATE,'DD/MM/YYYY') inicio_clases,
                        tO_NUMBER (SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,100)) grupo,
                        SZTGPME_SECUENCIA secuencia,
                        SZTGPME_NIVE_SEQNO sqno,
                        SZTGPME_LEVL_CODE nivel,
                        SZTGPME_idioma idioma,
                        (Select count(1)
                            from szstume 
                            where szstume_no_regla= sztgpme_no_regla
                            and SZTGPME_TERM_NRC = SZstume_TERM_NRC
                        ) as tot_gpo
                from sztgpme grp
                where 1 = 1
                and sztgpme_no_regla = p_regla
                and SZTGPME_START_DATE = p_inicio_clase
                and sztgpme_subj_crse_comp = p_materia
                and SZTGPME_idioma = p_idioma
                and SZTGPME_TERM_NRC not like  '%X'
                and (Select count(1)
                        from szstume 
                        where szstume_no_regla= sztgpme_no_regla
                        and SZTGPME_TERM_NRC = SZstume_TERM_NRC
                    ) < 50                                                                                                                                                      
            order by materia, grupo;

    Cursor alum_mate (p_regla number, p_materia varchar, p_campus varchar2, p_idioma varchar2) is
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
                     sztprono_materia_legal materia,
                    --Frank@July.2023 Integración de Alumnos Ordenados Programa padre, hijo, jornada, matricula         
                    Decode(substr(sztprono_jornada,3,1),'I',1,'C',2,'S',3,'R',4,5)  ord_jor,            
                    SZTPRPA_PRI_PADRE pri_padre,
                    SZTPRPA_PROGRAM   prog_padre,
--                                                                    SZTPRPA_PRI_hijo  pri_hijo,
                    SZTPRPA_prghijo   prog_hijo        
                    --Frank@July.2023 Integración de Alumnos Ordenados Programa padre, hijo, jornada, matricula                                                                                                                                                    
                      ,pr.Ord_on_s --FRank@Sep23: se agrega el programa tipo Online o Ejecutivo para agrupar alumns                                                                     
          from sztprono ono
                JOIN tztprogM p 
                    ON p.pidm = sztprono_pidm 
                    AND p.estatus = 'MA' 
                left join SZTPRPA on SZTPRPA_prghijo = sztprono_program and SZTPRPA_CAMP_CODE_HIJO = campus  --Frank@July.2023                                                              
                  --FRank@Sep23: se agrega el programa tipo Online o Ejecutivo para agrupar alumns                                                                    
                left join (select Max(sztdtec_term_code) TERM, case when SZTDTEC_MOD_TYPE = 'S' THEN 1 ELSE 2 END ORD_ON_S , SZTDTEC_PROGRAM program
                              from sztdtec
                            group by SZTDTEC_PROGRAM, SZTDTEC_MOD_TYPE) pr on pr.program =  sztprono_program
                --FRank@Sep23: se agrega el programa tipo Online o Ejecutivo para agrupar alumns
          where 1 = 1
          and sztprono_no_regla  = p_regla
          and sztprono_materia_banner = p_materia
          and p.campus = p_campus
            AND SZTPRONO_ESTATUS_ERROR ='N'
            And SZTPRONO_ENVIO_MOODL = 'N'
            And not exists(select 1 from szstume 
                            where szstume_no_regla=sztprono_no_regla 
                                and szstume_pidm=sztprono_pidm 
                                and szstume_subj_code = sztprono_materia_legal) 
            and pkg_algoritmo.f_prog_idioma(p.campus, sztprono_program) = p_idioma
            Order by pri_padre,  pr.ORD_ON_S, ord_jor, substr(sztprono_id,3,7); --Frank@July.2023     

    
    begin  --inicio proceso
        
        BEGIN

            SELECT DISTINCT trim(SZTALGO_ESTATUS_CERRADO)
            INTO  l_regla_cerrada
            FROM sztalgo
            WHERE 1 = 1
            AND sztalgo_no_regla = p_regla;

        EXCEPTION WHEN OTHERS THEN
--            raise_application_error (-20002,'Error al   '||sqlerrm);
            null;
        END;
                
        IF l_regla_cerrada = 'S' THEN
            dbms_output.put_line(' ********************* INICIA PROCESO COMPACTACIÓN DE GRUPOS DESPUES DE LA INTEGRACION ************************');
            pkg_algoritmo.p_track_prono(p_regla,'INICIA PROCESO COMPACTACIÓN DE GRUPOS DESPUES DE LA INTEGRACION');


            l_contar:=0;
            l_numero_alumnos:=0;

                FOR ord IN orden LOOP  --Ordena materias segun campus vs materia latam
                        for c in grupo_mate(ord.materia, ord.idioma) loop  --grupos y materias

                            dbms_output.put_line(' Materia  '||c.materia||' Grupo '||c.grupo||' nrc '||c.materia||c.grupo);                          
                            
                                 for e in(select count(*) vueltas
                                             from sztconf onf
                                             where 1 = 1
                                             and onf.sztconf_no_regla = c.regla
                                             and onf.SZTCONF_FECHA_INICIO =c.inicio_clases
                                             and SZTCONF_SUBJ_CODE=c.materia
                                             AND SZTCONF_GROUP = c.grupo
                                             and sztconf_idioma = c.idioma
                                 )
                                 loop
                                        l_numero_alumnos2:=ord.tope - c.tot_gpo; --tope por grupo - tot alum x gpo sentados
                                        dbms_output.put_line(' Entra alumno no alumnos regla '||c.regla||' alumnos numero '||l_numero_alumnos2||
                                                                ' inicio clases '||c.inicio_clases||' Materia '||c.materia||'  nivel '||c.nivel||
                                                                ' Campus:'||ord.campus||' Idioma:'||ord.idioma);
                                        l_contar:=0;

                                         for d in alum_mate (c.regla,c.materia,ord.campus,ord.idioma) loop

                                                    l_contar:=l_contar+1;
                                                    dbms_output.put_line(' Padre  '||c.padre||' Alumno '||d.matricula||'Contar '||l_contar||' Tope Grupo '||l_numero_alumnos2);
                                                    begin

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
                                                                                    0,
                                                                                    c.materia,
                                                                                    null,--D.semi,-- c.nivel,
                                                                                    null,
                                                                                    null,--  c.ptrm,
                                                                                    null,
                                                                                    null,
                                                                                    null,
                                                                                    null,
                                                                                    c.materia,
                                                                                    p_inicio_clase,
                                                                                    --c.inicio_clases,
                                                                                    c.regla,
                                                                                    c.secuencia,
                                                                                    c.sqno,
                                                                                    0,
                                                                                    null
                                                                                    );

                                                    exception when others then
                                                         dbms_output.put_line(' Error al insertar '||sqlerrm);
                                                    end;

                                                      BEGIN
                                                           UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='S',
                                                                               SZTPRONO_GRUPO_ASIG =c.grupo
                                                           WHERE 1 = 1
                                                           and SZTPRONO_MATERIA_LEGAL = c.materia
                                                           and SZTPRONO_PIDM =d.pidm
                                                           and SZTPRONO_NO_REGLA = c.regla
                                                           and SZTPRONO_ENVIO_MOODL ='N';
                                                      EXCEPTION WHEN OTHERS THEN
                                                           null;
                                                      END;
                                                  exit when l_contar =l_numero_alumnos2;
                                        end loop;
                            pkg_algoritmo.p_track_prono(p_regla,' Materia  '||c.materia||' Grupo '||c.grupo||
                                        ' nrc '||c.materia||c.grupo||' TotAlumInsert:'||l_contar||' TopeXGpo:'||l_numero_alumnos2||
                                        ' ProcCompact');                                          
                                end loop;
                        end loop;
                END LOOP;  --End Orde
            end if;

        RETURN(l_retorna);

end f_alumnos_moodl_compact;
--
--
--
 function f_alumnos_moodl(p_inicio_clase in VARCHAR2, p_regla in NUMBER)return varchar2
    as
    l_retorna            varchar2(1000):='EXITO';

    begin

        l_retorna:= f_alumnos_moodl_latam(p_inicio_clase, p_regla);
        l_retorna:= f_alumnos_moodl_utel(p_inicio_clase, p_regla, 'SOLO_UTL');
        l_retorna:= f_alumnos_moodl_utel(p_inicio_clase, p_regla, 'SIN_UTL');
        l_retorna:= f_alumnos_moodl_compact(p_inicio_clase, p_regla);
        commit;

        RETURN(l_retorna);

    end f_alumnos_moodl;
--
--
    function f_alumnos_insur(p_inicio_clase in VARCHAR2,
                             p_regla in NUMBER,
                             p_programa varchar2
                             )return varchar2
    as
    l_retorna            varchar2(1000):='EXITO';
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
    l_estatus_sgbstn     varchar2(5):=NULL;


    begin

        l_estatus_sgbstn:=null;



        BEGIN

            SELECT DISTINCT trim(SZTALGO_ESTATUS_CERRADO),SZTALGO_TOPE_ALUMNOS,SZTALGO_SOBRECUPO_ALUMNOS
            INTO  l_regla_cerrada,l_tope_grupos,l_sobrecupo
            FROM sztalgo
            WHERE 1 = 1
            AND sztalgo_no_regla = p_regla;

        EXCEPTION WHEN OTHERS THEN
--            raise_application_error (-20002,'Error al   '||sqlerrm);
            NULL;
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
                              to_number(f_get_group(p_regla,p_inicio_clase,SZTGPME_TERM_NRC)) grupo,
                               SZTGPME_SECUENCIA secuencia
                        from sztgpme grp
                        where 1 = 1
                        and sztgpme_no_regla = p_regla
                        and SZTGPME_START_DATE = p_inicio_clase
                        AND grp.sztgpme_subj_crse ='L1PS108'
                        and to_number(f_get_group(p_regla,p_inicio_clase,SZTGPME_TERM_NRC)) not in (select to_number(f_get_group(p_regla,p_inicio_clase,SZSTUME_TERM_NRC))
                                                                                                      from szstume
                                                                                                      where 1 = 1
                                                                                                      and szstume_no_regla =grp.sztgpme_no_regla
                                                                                                      and SZSTUME_START_DATE =to_char(grp.SZTGPME_START_DATE,'DD/MM/YYYY')
                                                                                                      and SZSTUME_SUBJ_CODE = grp.sztgpme_subj_crse
                                                                                                      AND not exists (select null
                                                                                                                        from SZTPREXT
                                                                                                                        where 1 = 1
                                                                                                                        and SZTPREXT_pidm = szstume_pidm
                                                                                                                        and SZTPREXT_no_regla = szstume_no_regla
                                                                                                                        and SZTPREXT_MATERIA_CAMBIO = szstume_subj_code
                                                                                                                        and SZTPREXT_CON_GRUPO ='S')
                                                                                              )
                    )
                    loop


                                 for e in(select count(*) vueltas
                                             from sztconf onf
                                             where 1 = 1
                                             and onf.sztconf_no_regla = c.regla
                                             and onf.SZTCONF_FECHA_INICIO =c.inicio_clases
                                             and SZTCONF_SUBJ_CODE=c.materia
                                             AND SZTCONF_GROUP = c.grupo
                                 )
                                 loop


                                      l_contar:=l_contar+1;

                                      l_estatus_sgbstn:=null;

                                      select count(*)
                                      into l_cuenta_alumnos
                                      from szstume
                                      where 1 = 1
                                      and szstume_no_regla = c.regla
                                      and SZSTUME_SUBJ_CODE = c.materia
                                      and SZSTUME_TERM_NRC = c.padre;

                                     dbms_output.put_line(' Entra alumno no alumnos  '||l_cuenta_alumnos);

                                        begin

                                            select SZTCONF_STUDENT_NUMB
                                            into l_numero_alumnos2
                                            from sztconf
                                            where 1 = 1
                                            and sztconf_no_regla  = c.regla
                                            and sztconf_subj_code = c.materia
                                            and to_char(to_date(SZTCONF_FECHA_INICIO,'DD/MM/YYYY'),'DD/MM/YYYY')=c.inicio_clases
                                            and to_number(SZTCONF_GROUP)= c.grupo;
                                        exception when others then
                                            null;
                                        end;

                                        dbms_output.put_line(' Entra alumno no alumnos regla '||c.regla||' alumnos numero '||l_numero_alumnos2||' inicio clases '||c.inicio_clases||' Materia '||c.materia);


                                         for d in (
                                                     select DISTINCT sztprono_id matricula,
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
--                                                      and sztprono_id ='010197198'
                                                      And SZTPRONO_ENVIO_MOODL = 'N'
                                                  )
                                              loop

                                                      dbms_output.put_line(' Entra alumno no alumnos  3 '||l_cuenta_alumnos);

                                                      begin

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
                                                                                      0,
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



                                                      exception when others then

                                                           dbms_output.put_line(' Error al insertar '||sqlerrm);

                                                      end;

                                                      BEGIN

                                                           UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='S',
                                                                               SZTPRONO_GRUPO_ASIG =c.grupo
                                                           WHERE 1 = 1
                                                           and SZTPRONO_MATERIA_LEGAL = c.materia
                                                           and SZTPRONO_PIDM =d.pidm
                                                           and SZTPRONO_NO_REGLA = c.regla
                                                           and SZTPRONO_ENVIO_MOODL ='N';

                                                      EXCEPTION WHEN OTHERS THEN

                                                           null;
                                                      END;

                                                      dbms_output.put_line(' Inserto');


                                              end loop;


                                end loop;
                    end loop;

                    for c in (select *
                              from szstume
                              where 1 = 1
                              and szstume_no_regla = p_regla
                              )
                              loop

                                     begin
                                         select distinct SGBSTDN_STST_CODE
                                         into l_estatus_sgbstn
                                         from sgbstdn a
                                         WHERE 1 = 1
                                         AND a.sgbstdn_pidm = c.szstume_pidm
                                         AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                        FROM sgbstdn a1
                                                                        WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                                               );
                                     exception when others then
                                        l_estatus_sgbstn:=null;
                                     end;

                                    if l_estatus_sgbstn not in ('AS','PR','MA') then

                                         BEGIN

                                              UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL ='N',
                                                                  SZTPRONO_ESTATUS_ERROR ='S',
                                                                  SZTPRONO_DESCRIPCION_ERROR=' Este alumno se encuentra con estatus en gaston de '||l_estatus_sgbstn
                                              WHERE 1 = 1
                                              and SZTPRONO_MATERIA_LEGAL = c.szstume_subj_code
                                              and SZTPRONO_PIDM =c.szstume_pidm
                                              and SZTPRONO_NO_REGLA = c.szstume_no_regla;

                                         EXCEPTION WHEN OTHERS THEN
                                             null;
                                         END;

                                         begin

                                            delete szstume
                                            where 1 = 1
                                            and szstume_subj_code = c.szstume_subj_code
                                            and szstume_pidm =c.szstume_pidm
                                            and szstume_no_regla = c.szstume_no_regla
                                            and szstume_term_nrc =c.szstume_term_nrc;

                                         EXCEPTION WHEN OTHERS THEN
                                             null;
                                         END;


                                    end if;


                              end loop;


        end if;

        commit;

        RETURN(l_retorna);

    end;
--
--
 PROCEDURE p_inscr_individual  (
                                 pn_fecha  VARCHAR2 ,
                                 p_regla   NUMBER,
                                 p_materia_legal  varchar2,
                                 p_pidm    number
                                 )
    IS
       crn                  varchar2(20);
       gpo                  NUMBER;
       mate                 VARCHAR2(20);
       ciclo                VARCHAR2(6);
       subj                 VARCHAR2(4);
       crse                 VARCHAR2(5);
       sb                   VARCHAR2(4);
       cr                   VARCHAR2(5);
       schd                 VARCHAR2(3);
       title                VARCHAR2(30);
       credit               DECIMAL(7,3);
       credit_bill          DECIMAL(7,3);
       gmod                 VARCHAR2(1);
       f_inicio             DATE;
       f_fin                DATE;
       sem                  NUMBER;
       conta_ptrm           NUMBER;
       conta_blck           NUMBER;
       pidm                 NUMBER;
       pidm_doc             NUMBER;
       pidm_doc2            NUMBER;
       ests                 VARCHAR2(2);
       levl                 VARCHAR2(2);
       camp                 VARCHAR2(3);
       rsts                 VARCHAR2(3);
       conta_origen         NUMBER:=0;
       conta_destino        NUMBER :=0;
       conta_origen_ssbsect NUMBER:=0;
       conta_origen_ssrblck NUMBER:=0;
       conta_origen_sobptrm NUMBER:=0;
       sp                   INTEGER;
       ciclo_ext            VARCHAR2(6);
       mensaje              VARCHAR2(200);
       parte                VARCHAR2(3);
       pidm_prof            NUMBER;
       per                  VARCHAR2(6);
       grupo                VARCHAR2(4);
       conta_sirasgn        NUMBER;
       fecha_ini            DATE;
       vl_existe            NUMBER :=0;

       vn_lugares           NUMBER:=0;
       vn_cupo_max          NUMBER:=0;
       vn_cupo_act          NUMBER:=0;
       vl_error             VARCHAR2 (2500):= 'EXITO';

       parteper_cur         VARCHAR2(3);
       period_cur           VARCHAR2(10);
       vl_jornada           VARCHAR2(250):=NULL;
       vl_exite_prof        NUMBER :=0;
       l_contar             NUMBER:=0;
       l_maximo_alumnos     NUMBER;
       l_numero_contador    number;
       l_valida_order       number;
       L_DESCRIPCION_ERROR  VARCHAR2(250):=NULL;
       l_valida  number;
       l_cuneta_prono number;
       l_term_code  VARCHAR2(10);
       l_ptrm       VARCHAR2(10);
       vl_orden     VARCHAR2(10);
       l_cuenta_ni  number;
       l_cambio_estatus number;
       l_type varchar2(20);
       l_pperiodo_ni varchar2(20);
       l_campus_ms varchar2(20);



            CURSOR c_no_proce IS
            SELECT *
            FROM szcarga carg
            WHERE  1=1
            and szcarga_no_regla = p_regla
            AND SZCARGA_MATERIA = p_materia_legal
            and rownum = 1
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
                           and szcarga_materia = p_materia_legal
                            ) ;


   BEGIN
        PKG_ALGORITMO.P_ENA_DIS_TRG('D','SATURN.SZT_SSBSECT_POSTINSERT_ROW');
        PKG_ALGORITMO.P_ENA_DIS_TRG('D','SATURN.SZT_SIRASGN_POSTINSERT_ROW');
        PKG_ALGORITMO.P_ENA_DIS_TRG('D','SATURN.SZT_SFRSTCR_POSTINS_UDP_REGS');


        begin
           PKG_ALGORITMO.P_INSERTA_CARGA(p_regla,pn_fecha);
        exception when others then
--          raise_application_error (-20002,'ERROR al insertar en carga '||sqlerrm);
          null;
        end;

        DBMS_OUTPUT.PUT_LINE('pasa la carga ');

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

            DBMS_OUTPUT.PUT_LINE('antes cursor '||p_materia_legal);

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
                                       d.sgbstdn_styp_code,
                                       sgbstdn_rate_code RATE
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
                       JOIN smrarul ON /*smrarul_area=smrpaap_area  AND*/ smrarul_term_code_eff=smrpaap_term_code_eff
                       WHERE  1 = 1
                       --AND smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
                       AND szcarga_no_regla = p_regla
                       AND spriden_pidm = p_pidm
                       and SZCARGA_MATERIA = p_materia_legal
                       AND ROWNUM = 1
                       ORDER BY  iden, 10

            ) LOOP

                        DBMS_OUTPUT.PUT_LINE('Entradndo al cursor ');

                        DBMS_OUTPUT.PUT_LINE('Entra a cursor normal ');

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

                               SELECT DISTINCT SFRSTCR_VPDI_CODE
                               INTO VL_ORDEN
                               FROM SFRSTCR
                               WHERE SFRSTCR_PIDM = C.PIDM
                               AND SFRSTCR_TERM_CODE = C.PERIODO
                               AND SFRSTCR_PTRM_CODE = C.PARTE
                               AND SFRSTCR_RSTS_CODE = 'RE'
                               AND SFRSTCR_VPDI_CODE IS NOT NULL;

                            EXCEPTION
                            WHEN others THEN

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

                                       BEGIN
                                          SELECT MAX(TZTORDR_CONTADOR)+1
                                            INTO VL_ORDEN
                                            FROM TZTORDR;
                                        EXCEPTION
                                        WHEN OTHERS THEN
                                              dbms_output.put_line('Error al recuperar orden ' ||sqlerrm);
                                       END;

                                       Begin
                                                  Insert into tztordr values (c.campus,
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

                                           Exception
                                              When Others then
                                                    dbms_output.put_line('Error al insertar orden ' ||sqlerrm);
                                           End;

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
                                And substr (sfrstcr_term_code,5,1) not in ( '8','9')
                                AND shrgrde_passed_ind = 'Y'
                                AND shrgrde_levl_code  = c.nivel
                                /* cambio escalas para prod */
                                and     shrgrde_term_code_effective=(select zstpara_param_desc
                                                                from zstpara
                                                                where zstpara_mapa_id='ESC_SHAGRD'
                                                                and substr((select f_getspridenid(p_pidm) from dual),1,2)=zstpara_param_id
                                                                and zstpara_param_valor=c.nivel)
                                /* cambio escalas para prod */
                                GROUP BY sfrstcr_term_code, sfrstcr_ptrm_code;

                                DBMS_OUTPUT.PUT_LINE('Entrando  aqui '||vl_existe);

                            EXCEPTION
                             WHEN OTHERS THEN
                                 vl_existe:=0;
                                 DBMS_OUTPUT.PUT_LINE('Error  lll '||' SUBJ '||c.subj||' crse '||c.crse||' nivel '||c.nivel);

                            END;

                            DBMS_OUTPUT.PUT_LINE('Entra a existe '||vl_existe);

                            IF vl_existe = 0 THEN

                                ---- Se busca que exista el grupo y tenga cupo


                                    --DBMS_OUTPUT.PUT_LINE('Entra 3');

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

                                  dbms_output.put_line ('CRN no es null XX '||crn);

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
                                                UPDATE SZTPRONO SET SZTPRONO_ENVIO_HORARIOS='S'
                                                WHERE 1 = 1
                                                AND SZTPRONO_NO_REGLA = p_regla
                                                and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                AND SZTPRONO_PIDM = c.pidm
                                                and sztprono_materia_legal = c.materia
                                                and SZTPRONO_ENVIO_HORARIOS='N'
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
                                                 AND sfrstcr_pidm = c.pidm
                                                 AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;

                                             EXCEPTION WHEN OTHERS THEN
                                                 l_cambio_estatus:=0;
                                             END;


                                             IF l_cambio_estatus > 0 THEN

                                                 IF C.SGBSTDN_STYP_CODE in ('N','R') THEN

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

--

                                            IF c.fecha_inicio IS NOT NULL THEN

                                                BEGIN

                                                    UPDATE sorlcur SET sorlcur_start_date  = TRUNC (c.fecha_inicio),
                                                                       sorlcur_data_origin = 'PRONOSTICO',
                                                                       sorlcur_user_id = USER,
                                                                       SORLCUR_RATE_CODE = c.rate
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
                                                and sztprono_materia_legal = c.materia
                                                AND SZTPRONO_PIDM = c.pidm
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


                                        if c.prof is null then


                                            crn:=crn;

                                            if c.nivel ='MS' then

                                                l_campus_ms:='AS';
                                            else
                                                l_campus_ms:=c.niVel;

                                            end if;


                                             BEGIN

                                                select sztcrnv_crn
                                                into crn
                                                from SZTCRNV
                                                where 1 = 1
                                                and rownum = 1
                                                AND SZTCRNV_LVEL_CODE = SUBSTR(l_campus_ms,1,1)
                                                and (SZTCRNV_crn,SZTCRNV_LVEL_CODE) not in (select to_number(crn),
                                                                                                   substr(SSBSECT_CRN,1,1)
                                                                                           from
                                                                                           (
                                                                                           select case when
                                                                                                          substr(SSBSECT_CRN,1,1) in('L','M','A','D','B') then to_number(substr(SSBSECT_CRN,2,10))
                                                                                                         else
                                                                                                               to_number(SSBSECT_CRN)
                                                                                                         end crn,
                                                                                                         SSBSECT_CRN
                                                                                               from ssbsect
                                                                                               where 1 = 1
                                                                                               and ssbsect_term_code=  c.periodo
                                                --                                               AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                           )
                                                                                           where 1 = 1
                                                                                           );

                                             EXCEPTION WHEN OTHERS THEN
--                                                raise_application_error (-20002,'Error al 2  '|| SQLCODE||' Error: '||SQLERRM);
                                                dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                                crn := NULL;
                                             END;

                                            if crn is not null then

                                                 if c.nivel ='LI' then

                                                     crn:='L'||crn;

                                                 else

                                                     crn:='M'||crn;

                                                 end if;

                                            else

                                                 begin

                                                     select NVL(MAX(to_number(SSBSECT_CRN)),0)+1
                                                     into crn
                                                     from ssbsect
                                                     where 1 = 1
                                                     and ssbsect_term_code = c.periodo
                                                     and SUBSTR(ssbsect_crn,1,1)  not in ('L','M','A','D','B');

                                                 exception   when others then
                                                     dbms_output.put_line('sqlerrm '||crn||' '||sqlerrm);
                                                     crn:=null;
                                                 end;

                                                dbms_output.put_line('crn '||crn);


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

                                                l_maximo_alumnos:=90;

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
                                                                            'ENL',    --SSBSECT_SCHD_CODE
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
                                                        and sztprono_materia_legal = c.materia
                                                        and SZTPRONO_ENVIO_HORARIOS='N'
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
                                                        AND sfrstcr_pidm = c.pidm
                                                        AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;

                                                    EXCEPTION WHEN OTHERS THEN
                                                        l_cambio_estatus:=0;
                                                    END;


                                                     IF l_cambio_estatus > 0 THEN

                                                         IF C.SGBSTDN_STYP_CODE in ('N','R') THEN

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
                                                                set sorlcur_start_date  = trunc (f_inicio),
                                                                       SORLCUR_RATE_CODE = c.rate
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
                                                        and sztprono_materia_legal = c.materia
                                                        AND SZTPRONO_PIDM = c.pidm
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

                                    dbms_output.put_line('mensaje:'|| 'No hay grupo creado Con docente este');

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

                                    if c.nivel ='MS' then

                                        l_campus_ms:='AS';
                                    else
                                        l_campus_ms:=c.niVel;

                                    end if;

                                    BEGIN

                                        select sztcrnv_crn
                                        into crn
                                        from SZTCRNV
                                        where 1 = 1
                                        and rownum = 1
                                        AND SZTCRNV_LVEL_CODE = SUBSTR(l_campus_ms,1,1)
                                        and (SZTCRNV_crn,SZTCRNV_LVEL_CODE) not in (select to_number(crn),
                                                                                           substr(SSBSECT_CRN,1,1)
                                                                                   from
                                                                                   (
                                                                                   select case when
                                                                                                  substr(SSBSECT_CRN,1,1) in('L','M','A','D','B','E') then to_number(substr(SSBSECT_CRN,2,10))
                                                                                                 else
                                                                                                       to_number(SSBSECT_CRN)
                                                                                                 end crn,
                                                                                                 SSBSECT_CRN
                                                                                       from ssbsect
                                                                                       where 1 = 1
                                                                                       and ssbsect_term_code=  c.periodo
                                        --                                               AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                   )
                                                                                   where 1 = 1
                                                                                   );

                                     EXCEPTION WHEN OTHERS THEN
--                                        raise_application_error (-20002,'Error al 2  '|| SQLCODE||' Error: '||SQLERRM);
--                                        dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                        crn := NULL;
                                     END;

                                     if crn is not null then


                                        if c.nivel ='LI' then

                                            crn:='L'||crn;

                                        else

                                            crn:='M'||crn;

                                        end if;

                                     else

                                         begin

                                             select NVL(MAX(to_number(SSBSECT_CRN)),0)+1
                                             into crn
                                             from ssbsect
                                             where 1 = 1
                                             and ssbsect_term_code = c.periodo
                                             and SUBSTR(ssbsect_crn,1,1)  not in ('L','M','A','D','B');

                                         exception   when others then
                                             dbms_output.put_line('sqlerrm '||crn||' '||sqlerrm);
                                             crn:=null;
                                         end;

                                        dbms_output.put_line('crn '||crn);



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
                                                l_maximo_alumnos:=90;
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
                                                                        'ENL',    --SSBSECT_SCHD_CODE
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
                                                    and sztprono_materia_legal = c.materia
                                                    and SZTPRONO_ENVIO_HORARIOS='N'
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
                                                     AND sfrstcr_pidm = c.pidm
                                                     AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;

                                                 EXCEPTION WHEN OTHERS THEN
                                                     l_cambio_estatus:=0;
                                                 END;


                                                 IF l_cambio_estatus > 0 THEN

                                                     IF C.SGBSTDN_STYP_CODE in ('N','R') THEN

                                                         BEGIN

                                                             UPDATE sgbstdn a SET  a.sgbstdn_styp_code ='C',
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
--                                                    raise_application_error (-20002,vl_error);

                                                END;

                                                IF f_inicio IS NOT NULL THEN

                                                    BEGIN

                                                        UPDATE sorlcur SET sorlcur_start_date  = TRUNC(f_inicio),
                                                                        sorlcur_data_origin = 'PRONOSTICO',
                                                                        sorlcur_user_id = USER,
                                                                       SORLCUR_RATE_CODE = c.rate
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
                                                    and sztprono_materia_legal = c.materia
                                                    AND SZTPRONO_PIDM = c.pidm
                                                    AND SZTPRONO_PTRM_CODE =parte;


                                               EXCEPTION WHEN OTHERS THEN
                                                  NULL;
                                               END;

                                            EXCEPTION WHEN OTHERS THEN
                                                vl_error := 'Se presento un error al insertar al alumno en el grupo3 ' ||SQLERRM;
                                            END;

                                            dbms_output.put_line('mensaje1:'|| 'SE creo el grupo :=' ||crn);

                                        EXCEPTION WHEN OTHERS THEN
                                            vl_error := 'Se presento un Error al insertar el nuevo grupo 3 crn '||crn||' error ' ||SQLERRM;
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

                               dbms_output.put_line('El alumno ya tiene la materia Inscritas en el Periodo:'||period_cur||'. Parte-periodo:'||parteper_cur);

                               Begin

                                     UPDATE sztprono SET
                                                         SZTPRONO_ESTATUS_ERROR ='S',
                                                         SZTPRONO_DESCRIPCION_ERROR=vl_error
                                                         --SZTPRONO_ENVIO_HORARIOS ='S'

                                     WHERE 1 = 1
                                     AND SZTPRONO_MATERIA_LEGAL = c.materia
--                                     AND TRUNC (SZTPRONO_FECHA_INICIO) = c.fecha_inicio
                                     AND SZTPRONO_NO_REGLA=P_REGLA
                                     AND SZTPRONO_pIDm=c.pidm;

                               EXCEPTION WHEN OTHERS THEN
                                  dbms_output.put_line(' Error al actualizar '||sqlerrm);
                               END;

                               commit;

--                               raise_application_error (-20002,vl_error);

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

                                  SELECT DECODE(c.sgbstdn_stst_code,'BT','BAJA TEMPORAL','BD','BAJA TEMPORAL','BI', 'BAJA POR INACTIVIDAD','CV', 'CANCELACI? DE VENTA','CM','CANCELACI? DE MATR?ULA','CC', 'CAMBIO DE CILO','CF','CAMBIO DE FECHA','CP','CAMBIO DE PROGRAMA','EG','EGRESADO')
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
                                   AND SZTPRONO_PIDM=c.pidm
                                   AND SZTPRONO_PTRM_CODE =parte;

                              EXCEPTION WHEN OTHERS THEN
                                 dbms_output.put_line(' Error al actualizar '||sqlerrm);
                              END;


                            vl_error := 'Estatus no v?do para realizar la carga: '||C.SGBSTDN_STST_CODE;

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

--                             raise_application_error (-20002,'Este alumno '||c.iden||' se encuentra con '||l_descripcion_error);

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


   END p_inscr_individual;


    PROCEDURE p_inscr_individual_DD  (
                                 pn_fecha  VARCHAR2 ,
                                 p_regla   NUMBER,
                                 p_materia_legal  varchar2,
                                 p_pidm    number,
                                 p_estatus varchar2,
                                 p_secuencia number,
                                 p_error out varchar2
                                 ,p_status_alum varchar2 default null
                                 )
    IS
       crn                  varchar2(20);
       gpo                  NUMBER;
       mate                 VARCHAR2(20);
       ciclo                VARCHAR2(6);
       subj                 VARCHAR2(4);
       crse                 VARCHAR2(5);
       sb                   VARCHAR2(4);
       cr                   VARCHAR2(5);
       schd                 VARCHAR2(3);
       title                VARCHAR2(30);
       credit               DECIMAL(7,3);
       credit_bill          DECIMAL(7,3);
       gmod                 VARCHAR2(1);
       f_inicio             DATE;
       f_fin                DATE;
       sem                  NUMBER;
       conta_ptrm           NUMBER;
       conta_blck           NUMBER;
       pidm                 NUMBER;
       pidm_doc             NUMBER;
       pidm_doc2            NUMBER;
       ests                 VARCHAR2(2);
       levl                 VARCHAR2(2);
       camp                 VARCHAR2(3);
       rsts                 VARCHAR2(3);
       conta_origen         NUMBER:=0;
       conta_destino        NUMBER :=0;
       conta_origen_ssbsect NUMBER:=0;
       conta_origen_ssrblck NUMBER:=0;
       conta_origen_sobptrm NUMBER:=0;
       sp                   INTEGER;
       ciclo_ext            VARCHAR2(6);
       mensaje              VARCHAR2(200);
       parte                VARCHAR2(3);
       pidm_prof            NUMBER;
       per                  VARCHAR2(6);
       grupo                VARCHAR2(4);
       conta_sirasgn        NUMBER;
       fecha_ini            DATE;
       vl_existe            NUMBER :=0;
       vn_lugares           NUMBER:=0;
       vn_cupo_max          NUMBER:=0;
       vn_cupo_act          NUMBER:=0;
       vl_error             VARCHAR2 (2500):= 'EXITO';
       parteper_cur         VARCHAR2(3);
       period_cur           VARCHAR2(10);
       vl_jornada           VARCHAR2(250):=NULL;
       vl_exite_prof        NUMBER :=0;
       l_contar             NUMBER:=0;
       l_maximo_alumnos     NUMBER;
       l_numero_contador    number:=0; --Jpg@Modify
       l_valida_order       number;
       L_DESCRIPCION_ERROR  VARCHAR2(250):=NULL;
       l_valida  number;
       l_cuneta_prono number;
       l_term_code  VARCHAR2(10);
       l_ptrm       VARCHAR2(10);
       vl_orden     VARCHAR2(10);
       l_cuenta_ni  number;
       l_cambio_estatus number;
       l_type varchar2(20);
       l_pperiodo_ni varchar2(20);
       l_matricula varchar2(9):= null;
       l_campus_ms varchar2(20);
       l_retorna_dsi VARCHAR2(250);
--
--Jpg@Create@Dic@21
--Procedimiento que revisa configuracion de area sea correcta
	Procedure p_check_area(p_regla number, p_pidm number, p_materia_legal varchar2) is
	BEGIN
		For c in (
                       SELECT DISTINCT sorlcur_program, sorlcur_term_code_ctlg term,
							smrpaap_term_code_eff term_eff , smrarul_area,
							szcarga_id iden, szcarga_fecha_ini fecha_inicio,
							szcarga_materia  materia
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
                       JOIN sztdtec ON sztdtec_program=sorlcur_program AND sztdtec_term_code=sorlcur_term_code_ctlg
                       JOIN smrpaap ON smrpaap_program=sorlcur_program --AND smrpaap_term_code_eff=sorlcur_term_code_ctlg
                       JOIN sztmaco ON SZTMACO_MATPADRE=szcarga_materia
                       JOIN smrarul ON  smrarul_area=smrpaap_area and smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
                       WHERE  1 = 1
                       AND smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
                       AND szcarga_no_regla = p_regla
                       AND sorlcur_pidm = p_pidm
                       and SZCARGA_MATERIA = p_materia_legal
		) LOOP
			if c.term <> c.term_eff THEN
				dbms_output.put_line('Entra a p_check_area');
				BEGIN
				  UPDATE sztprono SET SZTPRONO_ESTATUS_ERROR = 'S' ,
									  SZTPRONO_descripcion_error = 'Error de configuracion en area de concentracion de la materia:'||p_materia_legal,
									  sztprono_activity_date = SYSDATE,
									  sztprono_usuario = user
				  WHERE 1 = 1
				  AND sztprono_id = c.iden
				  AND sztprono_materia_legal = c.materia
				  AND sztprono_no_regla= p_regla
				  AND sztprono_fecha_inicio= c.fecha_inicio;

				EXCEPTION WHEN OTHERS THEN
				  null;
				END;
				COMMIT;
			end IF;
		ENd Loop;
	End;

--Jpg@Create@Dic@21

   BEGIN

   -- raise_application_error (-20002,'pasa la carga');

    Begin
            Select distinct spriden_id
                Into l_matricula
                from spriden
                where spriden_pidm = p_pidm
                And spriden_change_ind is null;

    Exception
        When Others then
            null;
    End;




        begin

           P_INSERTA_CARGA_PIDM(p_regla,pn_fecha, p_pidm);

        exception when others then
--          raise_application_error (-20002,'ERROR al insertar en carga '||sqlerrm);
          null;
        end;

        DBMS_OUTPUT.PUT_LINE('pasa la carga ');

        BEGIN

              SELECT COUNT(*)
              INTO l_contar
              from SZCARGA
              WHERE 1 = 1
              And  SZCARGA_ID = l_matricula
              AND SZCARGA_NO_REGLA =p_regla;

        EXCEPTION WHEN OTHERS THEN
          NULL;
        END;

        IF l_contar > 0 then

            fecha_ini:=TO_DATE(pn_fecha,'DD/MM/RRRR');

            DBMS_OUTPUT.PUT_LINE('antes cursor '||p_materia_legal);

             FOR c IN (
--                       SELECT DISTINCT spriden_pidm pidm,
--                                      szcarga_id iden  ,
--                                      szcarga_program prog,
--                                      sorlcur_camp_code campus,
--                                      sorlcur_levl_code nivel,
--                                      sorlcur_term_code_ctlg ctlg ,
--                                      szcarga_materia  materia ,
--                                      smrarul_subj_code subj,
--                                      smrarul_crse_numb_low crse ,
--                                      szcarga_term_code periodo ,
--                                      szcarga_ptrm_code parte,
--                                      DECODE(sztdtec_periodicidad,1,'BIMESTRAL',2,'CUATRIMESTRAL') periodicidad,
--                                      nvl(szcarga_grupo,'01') grupo,
--                                      --szcarga_grupo grupo,
--                                      szcarga_calif calif,
--                                      szcarga_id_prof prof,
--                                      szcarga_fecha_ini fecha_inicio,
--                                      sorlcur_key_seqno study,
--                                      d.sgbstdn_stst_code,
--                                      d.sgbstdn_styp_code,
--                                      SGBSTDN_RATE_CODE rate,
--                                      s.sorlcur_program,
--                                      d.sgbstdn_program_1
--                        FROM szcarga a
--                        JOIN spriden ON spriden_id=szcarga_id AND spriden_change_ind IS NULL
--                        JOIN sgbstdn d ON  d.sgbstdn_pidm=spriden_pidm
--                        AND  d.sgbstdn_term_code_eff = (SELECT MAX (b1.sgbstdn_term_code_eff)
--                                                        FROM sgbstdn b1
--                                                        WHERE 1 = 1
--                                                        AND d.sgbstdn_pidm = b1.sgbstdn_pidm
--                                                        AND d.sgbstdn_program_1 = b1.sgbstdn_program_1
--                                                                               )
--                        JOIN sorlcur s ON sorlcur_pidm=spriden_pidm
--                        AND s.sorlcur_pidm = d.sgbstdn_pidm
--                        --AND s.sorlcur_program = d.sgbstdn_program_1
--                        AND sorlcur_program=szcarga_program
--                        JOIN sztdtec ON sztdtec_program=sorlcur_program AND sztdtec_term_code=sorlcur_term_code_ctlg
--                        JOIN smrpaap ON smrpaap_program=sorlcur_program AND smrpaap_term_code_eff=sorlcur_term_code_ctlg
--                        JOIN sztmaco ON SZTMACO_MATPADRE=szcarga_materia
--                        JOIN smrarul ON  smrarul_area=smrpaap_area and smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
--                        WHERE  1 = 1
--                        AND szcarga_no_regla = p_regla
--                        AND sorlcur_pidm = p_pidm
--                        and SZCARGA_MATERIA = p_materia_legal
--                        ORDER BY  iden, 10
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
                                       d.sgbstdn_styp_code,
                                       SGBSTDN_RATE_CODE rate
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
                       JOIN sztdtec ON sztdtec_program=sorlcur_program AND sztdtec_term_code=sorlcur_term_code_ctlg
                       JOIN smrpaap ON smrpaap_program=sorlcur_program AND smrpaap_term_code_eff=sorlcur_term_code_ctlg
                       JOIN sztmaco ON SZTMACO_MATPADRE=szcarga_materia
                       JOIN smrarul ON  smrarul_area=smrpaap_area and smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
                       WHERE  1 = 1
                       AND smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
                       AND szcarga_no_regla = p_regla
                       AND sorlcur_pidm = p_pidm
                       and SZCARGA_MATERIA = p_materia_legal
                       ORDER BY  iden, 10

            ) LOOP


                        DBMS_OUTPUT.PUT_LINE('Entra a cursor normal ');

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

                               SELECT DISTINCT to_number (SFRSTCR_VPDI_CODE)
                               INTO VL_ORDEN
                               FROM SFRSTCR
                               WHERE SFRSTCR_PIDM = C.PIDM
                               AND SFRSTCR_TERM_CODE = C.PERIODO
                               AND SFRSTCR_PTRM_CODE = C.PARTE
                               AND SFRSTCR_RSTS_CODE = 'RE'
                               AND SFRSTCR_VPDI_CODE IS NOT NULL;

                            EXCEPTION
                            WHEN others THEN

                                dbms_output.put_line('No se encontro 3 '||sqlerrm);

                               BEGIN

                                    SELECT TBRACCD_RECEIPT_NUMBER
                                    INTO VL_ORDEN
                                    FROM TBRACCD A
                                    WHERE A.TBRACCD_PIDM = C.PIDM
                                    AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                               FROM TBBDETC
                                                               WHERE TBBDETC_DCAT_CODE = 'COL'
                                                               AND TBBDETC_DESC LIKE 'COLEGIATURA %'
                                                                AND TBBDETC_DESC != 'COLEGIATURA LIC NOTA'
                                                                AND TBBDETC_DESC != 'COLEGIATURA EXTRAORDINARIO')
                                    AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                                    AND A.TBRACCD_TRAN_NUMBER = (SELECT MAX(TBRACCD_TRAN_NUMBER)
                                                                FROM TBRACCD A1
                                                                WHERE A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                                                                AND A1.TBRACCD_TERM_CODE = A.TBRACCD_TERM_CODE
                                                                AND A1.TBRACCD_PERIOD = A.TBRACCD_PERIOD
                                                                AND A1.TBRACCD_DETAIL_CODE = A.TBRACCD_DETAIL_CODE
                                                                AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(to_date(C.fecha_inicio)+12)
                                                                AND A1.TBRACCD_DOCUMENT_NUMBER IS NULL
                                                                AND A1.TBRACCD_STSP_KEY_SEQUENCE =c.study) ;

                               EXCEPTION
                               WHEN OTHERS THEN

                                    dbms_output.put_line('No se encontro 4 '||sqlerrm);

                               VL_ORDEN := NULL;
                               END;

                            END;

                        dbms_output.put_line('Orden '||VL_ORDEN);


                        IF NVL(p_status_alum,c.sgbstdn_stst_code) IN  ('AS','PR','MA') then
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
                                And substr (sfrstcr_term_code,5,1) not in ('8', '9')
                                AND shrgrde_passed_ind = 'Y'
                                AND shrgrde_levl_code  = c.nivel
                                /* cambio escalas para prod */
                                and     shrgrde_term_code_effective=(select zstpara_param_desc
                                                                from zstpara
                                                                where zstpara_mapa_id='ESC_SHAGRD'
                                                                and substr((select f_getspridenid(p_pidm) from dual),1,2)=zstpara_param_id
                                                                and zstpara_param_valor=c.nivel)
                                /* cambio escalas para prod */
                                GROUP BY sfrstcr_term_code, sfrstcr_ptrm_code;

                                DBMS_OUTPUT.PUT_LINE('Entrando  aqui '||vl_existe||' PIDM '||c.pidm ||' SUBJ '||c.subj ||' crse '||c.crse );

                            EXCEPTION
                             WHEN OTHERS THEN
                                 vl_existe:=0;
                                 DBMS_OUTPUT.PUT_LINE('Error '||sqlerrm);

                            END;

                            if vl_existe is null then
                                    vl_existe:=0;
                            end if;

                            DBMS_OUTPUT.PUT_LINE('Entra a existe '||vl_existe);

                            IF vl_existe = 0 THEN

                                ---- Se busca que exista el grupo y tenga cupo

                                    dbms_output.put_line ('sin profesor '||vl_existe||' Periodo '||c.periodo||' Subj '||c.subj||' crse '||c.crse||' grupo '||c.grupo||' ptrm '||c.parte);

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
                                                     and  SSBSECT_CAMP_CODE = c.campus
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

                                  dbms_output.put_line ('CRN no es null lx '||crn);

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
                                                                            p_estatus,     --SFRSTCR_RSTS_CODE
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
                                                vl_error := ('Se presento un error al insertar en la tabla SFRSTCR ' || SQLERRM);
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
                                                UPDATE SZTPRONO SET SZTPRONO_ENVIO_HORARIOS='S'
                                                WHERE 1 = 1
                                                AND SZTPRONO_NO_REGLA = p_regla
                                                and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                AND SZTPRONO_PIDM = c.pidm
                                                and sztprono_materia_legal = c.materia
                                                and SZTPRONO_ENVIO_HORARIOS='N'
                                                AND SZTPRONO_PTRM_CODE =parte;


                                           EXCEPTION WHEN OTHERS THEN
                                              vl_error := ('Se presento un error al insertar en la tabla SZTPRONO 1 ' || SQLERRM);
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
                                                 AND SFRSTCR_TERM_CODE||SFRSTCR_PTRM_CODE != c.periodo||c.parte
                                                 AND sfrstcr_pidm = c.pidm
                                                 AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;

                                             EXCEPTION WHEN OTHERS THEN
                                                 l_cambio_estatus:=0;
                                             END;


                                             IF l_cambio_estatus > 0 THEN

                                                 IF C.SGBSTDN_STYP_CODE in ('N','R') THEN

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

--

                                            IF c.fecha_inicio IS NOT NULL THEN

                                                BEGIN

                                                    UPDATE sorlcur SET sorlcur_start_date  = TRUNC (c.fecha_inicio),
                                                                       sorlcur_data_origin = 'PRONOSTICO',
                                                                       sorlcur_user_id = USER,
                                                                       SORLCUR_RATE_CODE = c.rate
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
                                                AND sfrareg_rsts_code = p_estatus;

                                            EXCEPTION WHEN OTHERS THEN
                                               conta_ptrm :=0;
                                            END;

                                            IF conta_ptrm = 0 THEN

                                                BEGIN
                                                        INSERT INTO sfrareg VALUES(c.pidm,
                                                                                   c.periodo,
                                                                                   crn ,
                                                                                   0,
                                                                                   p_estatus,
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
                                                --and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                and SZTPRONO_ENVIO_HORARIOS='N'
                                                and sztprono_materia_legal = c.materia
                                                AND SZTPRONO_PIDM = c.pidm;
                                              --  AND SZTPRONO_PTRM_CODE =parte;

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

                                            if c.nivel ='MS' then

                                                l_campus_ms:='AS';
                                            else
                                                l_campus_ms:=c.niVel;

                                            end if;

                                             BEGIN

                                                select sztcrnv_crn
                                                into crn
                                                from SZTCRNV
                                                where 1 = 1
                                                and rownum = 1
                                                AND SZTCRNV_LVEL_CODE = SUBSTR(l_campus_ms,1,1)
                                                and (SZTCRNV_crn,SZTCRNV_LVEL_CODE) not in (select to_number(crn),
                                                                                                   substr(SSBSECT_CRN,1,1)
                                                                                           from
                                                                                           (
                                                                                           select case when
                                                                                                          substr(SSBSECT_CRN,1,1) in('L','M','A','D','B') then to_number(substr(SSBSECT_CRN,2,10))
                                                                                                         else
                                                                                                               to_number(SSBSECT_CRN)
                                                                                                         end crn,
                                                                                                         SSBSECT_CRN
                                                                                               from ssbsect
                                                                                               where 1 = 1
                                                                                               and ssbsect_term_code=  c.periodo
                                                --                                               AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                           )
                                                                                           where 1 = 1
                                                                                           );

                                             EXCEPTION WHEN OTHERS THEN
--                                                raise_application_error (-20002,'Error al 2  '|| SQLCODE||' Error: '||SQLERRM);
                                                dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                                crn := NULL;
                                             END;


                                            if crn is not null then

                                                if c.nivel ='LI' then

                                                    crn:='L'||crn;

                                                Elsif c.nivel ='MA' then

                                                    crn:='M'||crn;

                                                Elsif c.nivel ='MS' then

                                                    crn:='A'||crn;

                                                Elsif c.nivel ='EC' then

                                                    crn:='E'||crn;

                                                end if;
                                           else


                                                 begin

                                                     select NVL(MAX(to_number(SSBSECT_CRN)),0)+1
                                                     into crn
                                                     from ssbsect
                                                     where 1 = 1
                                                     and ssbsect_term_code = c.periodo
                                                     and SUBSTR(ssbsect_crn,1,1)  not in ('L','M','A','D','B');

                                                 exception   when others then
                                                     dbms_output.put_line('sqlerrm '||crn||' '||sqlerrm);
                                                     crn:=null;
                                                 end;

                                                dbms_output.put_line('crn '||crn);



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
                                                    l_maximo_alumnos:=90;
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
                                                                            'ENL',    --SSBSECT_SCHD_CODE
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
                                                                                   p_estatus,     --SFRSTCR_RSTS_CODE
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

                                                        vl_error := ('Se presento un error al insertar en la tabla SFRSTCR 2 ' || sqlerrm);
                                                    end;


                                                    BEGIN

                                                        UPDATE SZTPRONO SET SZTPRONO_ENVIO_HORARIOS='S'
                                                        WHERE 1 = 1
                                                        AND SZTPRONO_NO_REGLA = p_regla
--                                                        and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                        AND SZTPRONO_PIDM = c.pidm
                                                        and sztprono_materia_legal = c.materia
                                                        and SZTPRONO_ENVIO_HORARIOS='N';
                                                      --  AND SZTPRONO_PTRM_CODE =parte;


                                                    EXCEPTION WHEN OTHERS THEN
                                                      vl_error := 'Se presento un error al insertar en la tabla SZTPRONO 2 ' || sqlerrm;
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
                                                        AND SFRSTCR_TERM_CODE||SFRSTCR_PTRM_CODE != c.periodo||c.parte
                                                        AND sfrstcr_pidm = c.pidm
                                                        AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;

                                                    EXCEPTION WHEN OTHERS THEN
                                                        l_cambio_estatus:=0;
                                                    END;


                                                     IF l_cambio_estatus > 0 THEN

                                                         IF C.SGBSTDN_STYP_CODE in ('N','R')THEN

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
                                                                set sorlcur_start_date  = trunc (f_inicio),
                                                                    SORLCUR_RATE_CODE = c.rate
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
                                                        And sfrareg_rsts_code = p_estatus;

                                                    EXCEPTION WHEN OTHERS THEN
                                                       conta_ptrm :=0;
                                                    END;

                                                    IF conta_ptrm = 0 THEN

                                                         BEGIN
                                                                 INSERT INTO sfrareg VALUES(c.pidm,
                                                                                            c.periodo,
                                                                                            crn ,
                                                                                            0,
                                                                                            p_estatus,
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
                                                              vl_error := 'Se presento un error al insertar sfrareg 2 el registro de la materia para el alumno ' ||SQLERRM;
                                                         END;

                                                    END IF;

                                                    BEGIN
                                                        UPDATE SZTPRONO SET SZTPRONO_ENVIO_HORARIOS='S'
                                                        WHERE 1 = 1
                                                        AND SZTPRONO_NO_REGLA = p_regla
                                                       -- and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                        and SZTPRONO_ENVIO_HORARIOS='N'
                                                        and sztprono_materia_legal = c.materia
                                                        AND SZTPRONO_PIDM = c.pidm;
                                                     --   AND SZTPRONO_PTRM_CODE =parte;


                                                   EXCEPTION WHEN OTHERS THEN
                                                      vl_error := 'Se presento un error al insertar en la tabla SZTPRONO 3 ' || sqlerrm;
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

                                    dbms_output.put_line('mensaje:'|| 'No hay grupo creado Con docente 2 chuy');

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

                                    dbms_output.put_line('mensaje 2-->1');

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

                                    dbms_output.put_line('mensaje 3 '||c.nivel);

--
                                    if c.nivel ='MS' then

                                        l_campus_ms:='AS';
                                    else
                                        l_campus_ms:=c.niVel;

                                    end if;

                                    dbms_output.put_line('nivel'||l_campus_ms||' cnivel '|| c.niVel);


                                    BEGIN

                                        select sztcrnv_crn
                                        into crn
                                        from SZTCRNV
                                        where 1 = 1
                                        and rownum = 1
                                        AND SZTCRNV_LVEL_CODE = SUBSTR(l_campus_ms,1,1)
                                        and (SZTCRNV_crn,SZTCRNV_LVEL_CODE) not in (select to_number(crn),
                                                                                           substr(SSBSECT_CRN,1,1)
                                                                                   from
                                                                                   (
                                                                                   select case when
                                                                                                  substr(SSBSECT_CRN,1,1) in('L','M','A','D','B','E') then to_number(substr(SSBSECT_CRN,2,10))
                                                                                                 else
                                                                                                       to_number(SSBSECT_CRN)
                                                                                                 end crn,
                                                                                                 SSBSECT_CRN
                                                                                       from ssbsect
                                                                                       where 1 = 1
                                                                                       and ssbsect_term_code=  c.periodo
                                        --                                               AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                   )
                                                                                   where 1 = 1
                                                                                   );
                                    EXCEPTION WHEN OTHERS THEN
                                        --raise_application_error (-20002,'Error al 2  '|| SQLCODE||' Error: '||SQLERRM);
                                        dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                        crn := NULL;
                                    END;

                                    dbms_output.put_line('mensaje 4  '||crn);

                                    If crn is not null then

                                            dbms_output.put_line('mensaje 5');

                                            if c.nivel ='LI' then

                                                crn:='L'||crn;

                                            Elsif c.nivel ='MA' then

                                                crn:='M'||crn;

                                            Elsif c.nivel ='DO' then

                                                crn:='D'||crn;

                                            Elsif c.nivel ='MS' then

                                                crn:='A'||crn;

                                            Elsif c.nivel ='EC' then

                                                  crn:='E'||crn;

                                            end if;

                                    else

                                        begin

                                            select NVL(MAX(to_number(SSBSECT_CRN)),0)+1
                                            into crn
                                            from ssbsect
                                            where 1 = 1
                                            and ssbsect_term_code = c.periodo
                                            and SUBSTR(ssbsect_crn,1,1)  not in ('L','M','A','D','B');

                                        exception   when others then
                                            dbms_output.put_line('sqlerrm '||crn||' '||sqlerrm);
                                            crn:=null;
                                        end;

                                       dbms_output.put_line('crn '||crn);


                                    End if;

                                    BEGIN

                                        dbms_output.put_line('mensaje 6');

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

                                        dbms_output.put_line('mensaje 7  crn '||crn);

                                        BEGIN
                                                l_maximo_alumnos:=90;
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
                                                                        'ENL',    --SSBSECT_SCHD_CODE
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

                                           -- dbms_output.put_line(' cuenta ptrm '||conta_ptrm);

                                            IF conta_ptrm =0 THEN

                                                dbms_output.put_line(' cuenta ptrm --> '||conta_ptrm);

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

                                                    dbms_output.put_line(vl_error);
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
                                                                               p_estatus,     --SFRSTCR_RSTS_CODE
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
                                                 --   dbms_output.put_line('Error al insertar  SFRSTCR xxx '||sqlerrm);
                                                     vl_error := ('Se presento un error al insertar en la tabla SFRSTCR 4 ' || SQLERRM);
                                                END;


                                                BEGIN
                                                    UPDATE SZTPRONO SET SZTPRONO_ENVIO_HORARIOS='S'
                                                    WHERE 1 = 1
                                                    AND SZTPRONO_NO_REGLA = p_regla
                                                   -- and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                    AND SZTPRONO_PIDM = c.pidm
                                                    and sztprono_materia_legal = c.materia
                                                    and SZTPRONO_ENVIO_HORARIOS='N';
                                                  --  AND SZTPRONO_PTRM_CODE =parte;


                                                EXCEPTION WHEN OTHERS THEN
                                                   vl_error := ('Se presento un error al insertar en la tabla SZTPRONO 4 ' || SQLERRM);
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
                                                     AND SFRSTCR_TERM_CODE||SFRSTCR_PTRM_CODE != c.periodo||c.parte
                                                     AND sfrstcr_pidm = c.pidm
                                                     AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;

                                                 EXCEPTION WHEN OTHERS THEN
                                                     l_cambio_estatus:=0;
                                                 END;


                                                 IF l_cambio_estatus > 0 THEN

                                                     IF C.SGBSTDN_STYP_CODE in ('N','R') THEN

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
--                                                    raise_application_error (-20002,vl_error);

                                                END;

                                                IF f_inicio IS NOT NULL THEN

                                                    BEGIN

                                                        UPDATE sorlcur SET sorlcur_start_date  = TRUNC(f_inicio),
                                                                            sorlcur_data_origin = 'PRONOSTICO',
                                                                       sorlcur_user_id = USER,
                                                                       SORLCUR_RATE_CODE = c.rate
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
                                                    AND sfrareg_rsts_code = p_estatus;

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
                                                                                  p_estatus,
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
                                               --     and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                    and SZTPRONO_ENVIO_HORARIOS='N'
                                                    and sztprono_materia_legal = c.materia
                                                    AND SZTPRONO_PIDM = c.pidm;
                                                 --   AND SZTPRONO_PTRM_CODE =parte;
                                                EXCEPTION WHEN OTHERS THEN
                                                     vl_error := 'Se presento un error al insertar el registro de la materia en SZTPRONO ' ||SQLERRM;
                                                END;

                                            EXCEPTION WHEN OTHERS THEN
                                                vl_error := 'Se presento un error al insertar al alumno en el grupo3 ' ||SQLERRM;
                                            END;

                                            dbms_output.put_line('mensaje1:'|| 'SE creo el grupo :=' ||crn);

                                        EXCEPTION WHEN OTHERS THEN
                                            vl_error := 'Se presento un Error al insertar el nuevo grupo 3 crn '||crn||' error ' ||SQLERRM;
                                        END;

                                    END IF;

                                END IF;  ------ No hay  CRN Creado

                                IF vl_error = 'EXITO' THEN

                                    COMMIT; --Commit;
                                    --dbms_output.put_line('mensaje:'||vl_error);
                                    BEGIN
                                        UPDATE SZTPRONO SET SZTPRONO_ENVIO_MOODL='S'
                                        WHERE 1 = 1
                                        AND SZTPRONO_NO_REGLA = p_regla
                                        and SZTPRONO_ENVIO_MOODL='N'
                                        and sztprono_materia_legal = c.materia
                                        AND SZTPRONO_PIDM = c.pidm;
                                    EXCEPTION WHEN OTHERS THEN
                                         vl_error := 'Se presento un error al actualizar el registro de la materia en SZTPRONO ' ||SQLERRM;
                                    END;

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
                                                                     'PRON',
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
                                                                     'PRON',
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
                                    --AND TRUNC (SZTPRONO_FECHA_INICIO) = c.fecha_inicio
                                     AND SZTPRONO_NO_REGLA=P_REGLA
                                     AND SZTPRONO_pIDm=c.pidm;
                                     --AND SZTPRONO_PTRM_CODE =parte;

                                EXCEPTION WHEN OTHERS THEN
                                   dbms_output.put_line(' Error al actualizar '||sqlerrm);
                                END;

                               --l_retorna_dsi:=PKG_FINANZAS_REZA.F_ACTUALIZA_RATE_DSI ( c.iden, c.fecha_inicio );

                               commit;

                             --  raise_application_error (-20002,vl_error);

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
                                                                 'PRON',
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

                                  SELECT DECODE(c.sgbstdn_stst_code,'BT','BAJA TEMPORAL','BD','BAJA TEMPORAL','BI', 'BAJA POR INACTIVIDAD','CV', 'CANCELACI? DE VENTA','CM','CANCELACI? DE MATR?ULA','CC', 'CAMBIO DE CILO','CF','CAMBIO DE FECHA','CP','CAMBIO DE PROGRAMA','EG','EGRESADO')
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
                                   --AND TRUNC (SZTPRONO_FECHA_INICIO) = c.fecha_inicio
                                   AND SZTPRONO_NO_REGLA=P_REGLA
                                   AND SZTPRONO_PIDM=c.pidm;
                                   --AND SZTPRONO_PTRM_CODE =parte;

                              EXCEPTION WHEN OTHERS THEN
                                 dbms_output.put_line(' Error al actualizar '||sqlerrm);
                              END;


                            vl_error := 'Estatus no v?do para realizar la carga: '||C.SGBSTDN_STST_CODE;

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
                                                             'PRON',
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

		    l_numero_contador:=1; --Jpg@Modify valida si entra a procesar
          END LOOP;

          COMMIT;

		  if l_numero_contador = 0 THEN  --Jpg@Modify en el caso de no procesar validamos algun error en area de concetración.
			 p_check_area(p_regla,p_pidm,p_materia_legal);
		  end if;



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
                                   And spriden_change_ind is null
                                   AND s.sorlcur_pidm = spriden_pidm
                                   ANd s.sorlcur_pidm = p_pidm
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
        Else
                 vl_error := 'Esta Materia presenta Errores No se puede crear el Horario conserva el grupo 00...  validar el Error en el Pronostico ';
        end if;




        COMMIT;

        p_error := vl_error;

   END p_inscr_individual_DD;


 PROCEDURE p_inserta_carga_pidm(p_regla  NUMBER,
                                pn_fecha VARCHAR2,
                                pn_pidm  NUMBER)
    IS

    l_prof_id      VARCHAR2(100);
    l_alumno_id    VARCHAR2(9);
    l_cuenta_grupo number;
    l_cuenta_prof  number;
    l_contar_ec    number;

    BEGIN

--        raise_application_error (-20002,'Entra a inserta carga');

        begin

            select count(*)
            into l_contar_ec
            from sztalgo
            where 1 = 1
            and SZTALGO_LEVL_CODE ='EC'
            and  sztalgo_no_regla = p_regla;

        exception when others then
            null;
        end;

        Begin

            Select spriden_id
            Into l_alumno_id
            from spriden
            where spriden_pidm = pn_pidm
            And spriden_change_ind is null;
        Exception
            When Others then
                l_alumno_id :=0;
        End;


        BEGIN
             DELETE SZCARGA
             WHERE 1 = 1
             AND SZCARGA_NO_REGLA=p_regla
             and SZCARGA_FECHA_INI = pn_fecha
             And SZCARGA_ID = l_alumno_id;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

        BEGIN
            DELETE SZTCARGA
            WHERE 1 = 1
            AND SZTCARGA_NO_REGLA=p_regla
             and SZCARGA_FECHA_INI = pn_fecha
             And SZCARGA_ID = l_alumno_id;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;


        IF l_contar_ec = 0 THEN
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
                                                    SZTPRONO_MATERIA_BANNER banner
                                    from SZSTUME ume,
                                         sztprono ono
                                    where 1  = 1
                                    and ono.sztprono_no_regla =ume.SZSTUME_NO_REGLA(+)
                                    and ono.sztprono_pidm = ume.SZSTUME_pidm(+)
                                    and ono.SZTPRONO_MATERIA_LEGAL = ume.SZSTUME_SUBJ_CODE(+)
                                    and ono.SZTPRONO_ENVIO_HORARIOS ='N'
--                                    and ono.SZTPRONO_ENVIO_MOODL ='S'
                                    and ono.sztprono_id = l_alumno_id
                                    and ono.sztprono_no_regla  = p_regla
                                    and SZTPRONO_ESTATUS_ERROR ='N'
and ume.szstume_term_nrc not like '%X'
and ume.szstume_rsts_code='RE'
                                    AND ume.szstume_stat_ind = '1'
                                    And ume.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                               from SZSTUME a1
                                                               Where ume.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                               And ume.SZSTUME_STAT_IND = a1.SZSTUME_STAT_IND
                                                               And ume.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                               AND ume.SZSTUME_SUBJ_CODE = a1.SZSTUME_SUBJ_CODE
                                                               AND ume.szstume_term_nrc = a1.szstume_term_nrc
                                                              )
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

                                        select count(*)
                                        into l_cuenta_grupo
                                        from sztgpme
                                        where 1 = 1
                                        and SZTGPME_NO_REGLA = c_prono.regla
                                        and SZTGPME_TERM_NRC = c_prono.GRUPO2
                                        and SZTGPME_STAT_IND ='1';


                                    exception when others then
                                            l_cuenta_grupo:=0;
                                    end;

                                    begin

                                        select count(*)
                                        into l_cuenta_prof
                                        from SZSGNME
                                        where 1 = 1
                                        and SZSGNME_NO_REGLA = c_prono.regla
                                        and SZSGNME_TERM_NRC = c_prono.GRUPO2
                                        and SZSGNME_STAT_IND ='1';


                                    exception when others then
                                            l_cuenta_prof:=0;
                                    end;

                                    -- para validar que esten sincronizados

                                    dbms_output.put_line('Cuenta Grupo  '||l_cuenta_grupo||' Cuenta Prof '||l_cuenta_prof);

                                    if l_cuenta_grupo > 0 and l_cuenta_prof > 0 then

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
                                           --raise_application_error (-20002,'ERROR al insertar en carga matricula  '||c_prono.id_alumno||' error '||sqlerrm);
                                           null;
                                        end;


                                    end if;

                                end loop;

        ELSE

        -- para educaci??ontinua para la inscripci??o es necesario que el alumno se encuentre en aula

           -- raise_application_error (-20002,'Entra a Ec');

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
                                                    SZTPRONO_MATERIA_BANNER banner
                                    from SZSTUME ume,
                                         sztprono ono
                                    where 1  = 1
                                    and ono.sztprono_no_regla =ume.SZSTUME_NO_REGLA(+)
                                    and ono.sztprono_pidm = ume.SZSTUME_pidm(+)
                                    and ono.SZTPRONO_MATERIA_LEGAL = ume.SZSTUME_SUBJ_CODE(+)
                                    and ono.SZTPRONO_ENVIO_HORARIOS ='N'
                                    and ono.SZTPRONO_ENVIO_MOODL ='S'
                                    and ono.sztprono_id = l_alumno_id
                                    and ono.sztprono_no_regla  = p_regla
                                    and SZTPRONO_ESTATUS_ERROR ='N'
                                    And ume.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                               from SZSTUME a1
                                                               Where ume.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                               And ume.SZSTUME_STAT_IND = a1.SZSTUME_STAT_IND
                                                               And ume.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                               AND ume.SZSTUME_SUBJ_CODE = a1.SZSTUME_SUBJ_CODE
                                                              )
                                    )

                                )
                                loop


                                   -- raise_application_error (-20002,'entra a ec');

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
--
--                                    begin
--
--                                        select count(*)
--                                        into l_cuenta_grupo
--                                        from sztgpme
--                                        where 1 = 1
--                                        and SZTGPME_NO_REGLA = c_prono.regla
--                                        and SZTGPME_TERM_NRC = c_prono.GRUPO2
--                                        and SZTGPME_STAT_IND ='1';
--
--
--                                    exception when others then
--                                            l_cuenta_grupo:=0;
--                                    end;

--                                    begin
--
--                                        select count(*)
--                                        into l_cuenta_prof
--                                        from SZSGNME
--                                        where 1 = 1
--                                        and SZSGNME_NO_REGLA = c_prono.regla
--                                        and SZSGNME_TERM_NRC = c_prono.GRUPO2
--                                        and SZSGNME_STAT_IND ='1';
--
--
--                                    exception when others then
--                                            l_cuenta_prof:=0;
--                                    end;

                                    -- para validar que esten sincronizados

                                    dbms_output.put_line('Entra a ec');

                                   -- if l_cuenta_grupo > 0 and l_cuenta_prof > 0 then

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
                                           raise_application_error (-20002,'ERROR al insertar en carga matricula  '||c_prono.id_alumno||' error '||sqlerrm);
                                           --null;
                                        end;


                                   -- end if;

                                end loop;


        END IF;

                commit;

    END P_INSERTA_CARGA_PIDM;
    --

   PROCEDURE p_inscr_individual_XX (
                                 pn_fecha  VARCHAR2 ,
                                 p_regla   NUMBER,
                                 p_materia_legal  varchar2,
                                 p_pidm    number,
                                 p_estatus varchar2,
                                 p_secuencia number,
                                 p_error out varchar2,
                                 p_usuario varchar2 default null
                                 )
    IS
       crn                  varchar2(20);
       gpo                  NUMBER;
       mate                 VARCHAR2(20);
       ciclo                VARCHAR2(6);
       subj                 VARCHAR2(4);
       crse                 VARCHAR2(5);
       sb                   VARCHAR2(4);
       cr                   VARCHAR2(5);
       schd                 VARCHAR2(3);
       title                VARCHAR2(30);
       credit               DECIMAL(7,3);
       credit_bill          DECIMAL(7,3);
       gmod                 VARCHAR2(1);
       f_inicio             DATE;
       f_fin                DATE;
       sem                  NUMBER;
       conta_ptrm           NUMBER;
       conta_blck           NUMBER;
       pidm                 NUMBER;
       pidm_doc             NUMBER;
       pidm_doc2            NUMBER;
       ests                 VARCHAR2(2);
       levl                 VARCHAR2(2);
       camp                 VARCHAR2(3);
       rsts                 VARCHAR2(3);
       conta_origen         NUMBER:=0;
       conta_destino        NUMBER :=0;
       conta_origen_ssbsect NUMBER:=0;
       conta_origen_ssrblck NUMBER:=0;
       conta_origen_sobptrm NUMBER:=0;
       sp                   INTEGER;
       ciclo_ext            VARCHAR2(6);
       mensaje              VARCHAR2(200);
       parte                VARCHAR2(3);
       pidm_prof            NUMBER;
       per                  VARCHAR2(6);
       grupo                VARCHAR2(4);
       conta_sirasgn        NUMBER;
       fecha_ini            DATE;
       vl_existe            NUMBER :=0;

       vn_lugares           NUMBER:=0;
       vn_cupo_max          NUMBER:=0;
       vn_cupo_act          NUMBER:=0;
       vl_error             VARCHAR2 (2500):= 'EXITO';

       parteper_cur         VARCHAR2(3);
       period_cur           VARCHAR2(10);
       vl_jornada           VARCHAR2(250):=NULL;
       vl_exite_prof        NUMBER :=0;
       l_contar             NUMBER:=0;
       l_maximo_alumnos     NUMBER;
       l_numero_contador    number;
       l_valida_order       number;
       L_DESCRIPCION_ERROR  VARCHAR2(250):=NULL;
       l_valida  number;








       l_cuneta_prono number;
       l_term_code  VARCHAR2(10);
       l_ptrm       VARCHAR2(10);
       vl_orden     VARCHAR2(10);
       l_cuenta_ni  number;








       l_cambio_estatus number;
       l_type varchar2(20);
       l_pperiodo_ni varchar2(20);
       l_matricula varchar2(9):= null;
       l_campus_ms varchar2(20);
       l_retorna_dsi varchar2(250);



   BEGIN

    Begin
            Select distinct spriden_id
                Into l_matricula
                from spriden
                where spriden_pidm = p_pidm
                And spriden_change_ind is null;

    Exception
        When Others then
            null;
    End;


--    raise_application_error (-20002,'Error al   '||sqlerrm);



        begin
           P_INSERTA_CARGA_PIDM(p_regla,pn_fecha, p_pidm);
        exception when others then
         -- raise_application_error (-20002,'ERROR al insertar en carga '||sqlerrm);
          null;
        end;

        DBMS_OUTPUT.PUT_LINE('pasa la carga ');

        BEGIN

              SELECT COUNT(*)
              INTO l_contar
              from SZCARGA
              WHERE 1 = 1
              And  SZCARGA_ID = l_matricula
              AND SZCARGA_NO_REGLA =p_regla;

        EXCEPTION WHEN OTHERS THEN
          NULL;
        END;

        IF l_contar > 0 then

            fecha_ini:=TO_DATE(pn_fecha,'DD/MM/RRRR');

            --DBMS_OUTPUT.PUT_LINE('antes cursor');

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
                                       d.sgbstdn_styp_code,
                                       SGBSTDN_RATE_CODE rate
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
                       JOIN sztdtec ON sztdtec_program=sorlcur_program AND sztdtec_term_code=sorlcur_term_code_ctlg
                       JOIN smrpaap ON smrpaap_program=sorlcur_program AND smrpaap_term_code_eff=sorlcur_term_code_ctlg
                       JOIN sztmaco ON SZTMACO_MATPADRE=szcarga_materia
                       JOIN smrarul ON  smrarul_area=smrpaap_area and SMRARUL_TERM_CODE_EFF = sorlcur_term_code_ctlg  and smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
                       WHERE  1 = 1
                       AND smrarul_subj_code||smrarul_crse_numb_low =sztmaco_mathijo
                       AND szcarga_no_regla = p_regla
                       AND sorlcur_pidm = p_pidm
                       and SZCARGA_MATERIA = p_materia_legal
                       ORDER BY  iden, 10

            ) LOOP


                    --    DBMS_OUTPUT.PUT_LINE('Entra a cursor normal ');

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

                           SELECT DISTINCT TO_NUMBER (SFRSTCR_VPDI_CODE)
                           INTO VL_ORDEN
                           FROM SFRSTCR
                           WHERE SFRSTCR_PIDM = C.PIDM
                           AND SFRSTCR_TERM_CODE = C.PERIODO
                           AND SFRSTCR_PTRM_CODE = C.PARTE
                           AND SFRSTCR_RSTS_CODE = 'RE'
                           AND SFRSTCR_VPDI_CODE IS NOT NULL;

                        EXCEPTION
                        WHEN OTHERS THEN

                           BEGIN

                                SELECT TBRACCD_RECEIPT_NUMBER
                                INTO VL_ORDEN
                                FROM TBRACCD A
                                WHERE A.TBRACCD_PIDM = C.PIDM
                                AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                           FROM TBBDETC
                                                           WHERE TBBDETC_DCAT_CODE = 'COL'
                                                           AND TBBDETC_DESC LIKE 'COLEGIATURA %'
                                                            AND TBBDETC_DESC != 'COLEGIATURA LIC NOTA'
                                                            AND TBBDETC_DESC != 'COLEGIATURA EXTRAORDINARIO')
                                AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                                AND A.TBRACCD_TRAN_NUMBER = (SELECT MAX(TBRACCD_TRAN_NUMBER)
                                                            FROM TBRACCD A1
                                                            WHERE A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                                                            AND A1.TBRACCD_TERM_CODE = A.TBRACCD_TERM_CODE
                                                            AND A1.TBRACCD_PERIOD = A.TBRACCD_PERIOD
                                                            AND A1.TBRACCD_DETAIL_CODE = A.TBRACCD_DETAIL_CODE
                                                            AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(to_date(C.fecha_inicio)+12)
                                                            AND A1.TBRACCD_DOCUMENT_NUMBER IS NULL
                                                            AND A1.TBRACCD_STSP_KEY_SEQUENCE =c.study) ;

                           EXCEPTION
                           WHEN OTHERS THEN

                                dbms_output.put_line('No se encontro 4 '||sqlerrm);

                           VL_ORDEN := NULL;
                           END;

                        END;

                        IF C.SGBSTDN_STST_CODE IN  ('AS','PR','MA') THEN
                        ----------------- Se valida que el alumno no tenga la materia sembrada en el horario como Activa ---------------------------------------

                            --DBMS_OUTPUT.PUT_LINE('Entra a cursor normal ');

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
                                And substr (sfrstcr_term_code,5,1) not in ( '8','9')
                                AND shrgrde_passed_ind = 'Y'
                                AND shrgrde_levl_code  = c.nivel
                                /* cambio escalas para prod */
                                and     shrgrde_term_code_effective=(select zstpara_param_desc
                                                                from zstpara
                                                                where zstpara_mapa_id='ESC_SHAGRD'
                                                                and substr((select f_getspridenid(p_pidm) from dual),1,2)=zstpara_param_id
                                                                and zstpara_param_valor=c.nivel)
                                /* cambio escalas para prod */
                                GROUP BY sfrstcr_term_code, sfrstcr_ptrm_code;

                                --DBMS_OUTPUT.PUT_LINE('Entrando  aqui '||vl_existe||' PIDM '||c.pidm ||' SUBJ '||c.subj ||' crse '||c.crse );

                            EXCEPTION
                             WHEN OTHERS THEN
                                 vl_existe:=0;
                                 DBMS_OUTPUT.PUT_LINE('Error '||sqlerrm);

                            END;

                            if vl_existe is null then
                                    vl_existe:=0;
                            end if;

                            DBMS_OUTPUT.PUT_LINE('Entra a existe '||vl_existe);

                            IF vl_existe = 0 THEN

                                ---- Se busca que exista el grupo y tenga cupo

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
                                                     and  SSBSECT_CAMP_CODE = c.campus
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

                                                DBMS_OUTPUT.PUT_LINE('Entra 4');

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

                                  dbms_output.put_line ('CRN no es null gx '||crn);

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
                                                    UPDATE ssbsect
                                                        SET ssbsect_gmod_code = gmod
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
                                                                                    SYSDATE,
                                                                                    NULL,
                                                                                    NULL,
                                                                                    NULL,
                                                                                    NULL,
                                                                                    'PRONOSTICO',
                                                                                    nvl (p_usuario,user),
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
                                                                                   nvl (p_usuario,user),
                                                                                   NULL,
                                                                                   'PRONOSTICO',
                                                                                   NULL,
                                                                                   0,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   NULL,
                                                                                   nvl (p_usuario,user),
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
                                                                                p_estatus,     --SFRSTCR_RSTS_CODE
                                                                                SYSDATE ,    --SFRSTCR_RSTS_DATE
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
                                                                                SYSDATE,      --SFRSTCR_ADD_DATE
                                                                                Sysdate,     --SFRSTCR_ACTIVITY_DATE
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
                                                                                nvl (p_usuario,user),--SFRSTCR_USER_ID
                                                                                vl_orden --SFRSTCR_VPDI_CODE
                                                                              );

                                                EXCEPTION WHEN OTHERS THEN
                                                    dbms_output.put_line('Error al insertar  SFRSTCR '||sqlerrm);
                                                    vl_error := ('Se presento un error al insertar en la tabla SFRSTCR ' || SQLERRM);
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
                                                    UPDATE SZTPRONO
                                                        SET SZTPRONO_ENVIO_HORARIOS='S'
                                                    WHERE 1 = 1
                                                    AND SZTPRONO_NO_REGLA = p_regla
                                                    and SZTPRONO_FECHA_INICIO =  pn_fecha
                                                    AND SZTPRONO_PIDM = c.pidm
                                                    and sztprono_materia_legal = c.materia
                                                    and SZTPRONO_ENVIO_HORARIOS='N'
                                                    AND SZTPRONO_PTRM_CODE =parte;
                                               EXCEPTION
                                               WHEN OTHERS THEN
                                                  vl_error := ('Se presento un error al insertar en la tabla SZTPRONO 1 ' || SQLERRM);
                                               END;

                                               BEGIN
                                                    UPDATE ssbsect
                                                        SET ssbsect_seats_avail=ssbsect_seats_avail -1
                                                    WHERE 1 = 1
                                                    AND ssbsect_term_code = c.periodo
                                                    AND ssbsect_crn  = crn;
                                               EXCEPTION WHEN OTHERS THEN
                                                    vl_error := 'Se presento un error al actualizar la disponibilidad del grupo ' ||SQLERRM;
                                               END;

                                                BEGIN
                                                    UPDATE ssbsect
                                                        SET ssbsect_census_enrl=ssbsect_enrl
                                                    WHERE 1 = 1
                                                    AND ssbsect_term_code = c.periodo
                                                    AND ssbsect_crn  = crn;
                                                EXCEPTION WHEN OTHERS THEN
                                                    vl_error := 'Se presento un error al actualizar el Censo del grupo ' ||SQLERRM;
                                                END;


                                                IF C.SGBSTDN_STYP_CODE = 'F' THEN
                                                        BEGIN
                                                            UPDATE sgbstdn a
                                                                SET a.sgbstdn_styp_code ='N',
                                                                       a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                                       a.SGBSTDN_USER_ID =nvl (p_usuario,user)
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
                                                     AND SFRSTCR_TERM_CODE||SFRSTCR_PTRM_CODE != c.periodo||c.parte
                                                     AND sfrstcr_pidm = c.pidm
                                                     And SFRSTCR_RSTS_CODE ='RE'
                                                     AND SFRSTCR_STSP_KEY_SEQUENCE = c.study
                                                     ;
                                                EXCEPTION WHEN OTHERS THEN
                                                     l_cambio_estatus:=0;
                                                END;


                                                 IF l_cambio_estatus > 0 THEN
                                                     IF C.SGBSTDN_STYP_CODE in ('N','R') THEN
                                                         BEGIN
                                                             UPDATE sgbstdn a SET a.sgbstdn_styp_code ='C',
                                                                                  a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                                                  A.SGBSTDN_USER_ID =nvl (p_usuario,user)
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
                                                 End if;

                                                 IF c.fecha_inicio IS NOT NULL THEN
                                                            BEGIN
                                                                UPDATE sorlcur
                                                                            SET sorlcur_start_date  = TRUNC (c.fecha_inicio),
                                                                                   sorlcur_data_origin = 'PRONOSTICO',
                                                                                   sorlcur_user_id = nvl (p_usuario,user),
                                                                                   SORLCUR_RATE_CODE = c.rate
                                                                WHERE 1 = 1
                                                                AND sorlcur_pidm = c.pidm
                                                                AND sorlcur_program = c.prog
                                                                AND sorlcur_lmod_code = 'LEARNER'
                                                                AND sorlcur_key_seqno = c.study;

                                                            EXCEPTION
                                                                WHEN OTHERS THEN
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
                                                    AND sfrareg_rsts_code = p_estatus;
                                                EXCEPTION
                                                    WHEN OTHERS THEN
                                                   conta_ptrm :=0;
                                                END;

                                                IF conta_ptrm = 0 THEN

                                                        BEGIN
                                                                INSERT INTO sfrareg VALUES(c.pidm,
                                                                                           c.periodo,
                                                                                           crn ,
                                                                                           0,
                                                                                           p_estatus,
                                                                                           nvl(c.fecha_inicio,pn_fecha),
                                                                                           nvl(f_fin,sysdate),
                                                                                           'N',
                                                                                           'N',
                                                                                           SYSDATE,
                                                                                           nvl (p_usuario,user),
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
                                                                                        nvl (p_usuario,user),       --SHRINST_USER_ID
                                                                                        'PRONOSTICO',       --SHRINST_DATA_ORIGIN
                                                                                        null
                                                                                        );      --SHRINST_VPDI_CODE

                                                        EXCEPTION WHEN OTHERS THEN
                                                             vl_error := 'Se presento un error al insertar al alumno en SHRINST ' ||sqlerrm;
                                                        END;

                                                END IF;

                                                BEGIN
                                                    UPDATE SZTPRONO
                                                        SET SZTPRONO_ENVIO_HORARIOS='S'
                                                    WHERE 1 = 1
                                                    AND SZTPRONO_NO_REGLA = p_regla
                                                    and SZTPRONO_ENVIO_HORARIOS='N'
                                                    and sztprono_materia_legal = c.materia
                                                    AND SZTPRONO_PIDM = c.pidm;
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

                                            if c.nivel ='MS' then

                                                l_campus_ms:='AS';
                                            else
                                                l_campus_ms:=c.niVel;

                                            end if;

                                             BEGIN

                                                select sztcrnv_crn
                                                into crn
                                                from SZTCRNV
                                                where 1 = 1
                                                and rownum = 1
                                                AND SZTCRNV_LVEL_CODE = SUBSTR(C.NIVEL,1,1)
                                                and (SZTCRNV_crn,SZTCRNV_LVEL_CODE) not in (select to_number(crn),
                                                                                                   substr(SSBSECT_CRN,1,1)
                                                                                           from
                                                                                           (
                                                                                           select case when
                                                                                                          substr(SSBSECT_CRN,1,1) in('L','M','A','D','B') then to_number(substr(SSBSECT_CRN,2,10))
                                                                                                         else
                                                                                                               to_number(SSBSECT_CRN)
                                                                                                         end crn,
                                                                                                         SSBSECT_CRN
                                                                                               from ssbsect
                                                                                               where 1 = 1
                                                                                               and ssbsect_term_code=  c.periodo
                                                --                                               AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                           )
                                                                                           where 1 = 1
                                                                                           );

                                             EXCEPTION WHEN OTHERS THEN
--                                                raise_application_error (-20002,'Error al 2  '|| SQLCODE||' Error: '||SQLERRM);
                                                dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                                crn := NULL;
                                             END;


                                            if crn is not null then

                                                if c.nivel ='LI' then
                                                    crn:='L'||crn;
                                                Elsif c.nivel ='MA' then
                                                    crn:='M'||crn;
                                                Elsif c.nivel ='MS' then
                                                    crn:='A'||crn;
                                                Elsif c.nivel ='DO' then
                                                    crn:='D'||crn;
                                                Elsif c.nivel ='EC' then
                                                    crn:='E'||crn;
                                                end if;

                                            else

                                                begin

                                                    select NVL(MAX(to_number(SSBSECT_CRN)),0)+1
                                                    into crn
                                                    from ssbsect
                                                    where 1 = 1
                                                    and ssbsect_term_code = c.periodo
                                                    and SUBSTR(ssbsect_crn,1,1)  not in ('L','M','A','D','B');

                                                exception   when others then
                                                    crn:=0;
                                                end;


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
                                                l_maximo_alumnos:=90;
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
                                                                            'ENL',    --SSBSECT_SCHD_CODE
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
                                                                            SYSDATE,--SSBSECT_ACTIVITY_DATE
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
                                                                            nvl (p_usuario,user),--SSBSECT_USER_ID
                                                                            'MOOD',--SSBSECT_INTG_CDE
                                                                            'B',--SSBSECT_PREREQ_CHK_METHOD_CDE
                                                                            nvl (p_usuario,user),--SSBSECT_KEYWORD_INDEX_ID
                                                                            NULL,--SSBSECT_SCORE_OPEN_DATE
                                                                            NULL,--SSBSECT_SCORE_CUTOFF_DATE
                                                                            NULL,--SSBSECT_REAS_SCORE_OPEN_DATE
                                                                            NULL,--SSBSECT_REAS_SCORE_CTOF_DATE
                                                                            NULL,--SSBSECT_SURROGATE_ID
                                                                            NULL,--SSBSECT_VERSION
                                                                            NULL
                                                                            );--SSBSECT_VPDI_CODE


                                                BEGIN
                                                    UPDATE sobterm
                                                        SET sobterm_crn_oneup = crn
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
                                                                                nvl (p_usuario,user),
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
                                                                                          sysdate,
                                                                                          null,
                                                                                          null,
                                                                                          null,
                                                                                          null,
                                                                                          'PRONOSTICO',
                                                                                          nvl (p_usuario,user),
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
                                                                                          nvl (p_usuario,user),
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
                                                                                       nvl (p_usuario,user),
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
                                                                                   p_estatus,     --SFRSTCR_RSTS_CODE
                                                                                   SYSDATE,    --SFRSTCR_RSTS_DATE
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
                                                                                   SYSDATE ,      --SFRSTCR_ADD_DATE
                                                                                   SYSDATE ,     --SFRSTCR_ACTIVITY_DATE
                                                                                   c.nivel,     --SFRSTCR_LEVL_CODE
                                                                                   c.campus,     --SFRSTCR_CAMP_CODE
                                                                                   c.materia,     --SFRSTCR_RESERVED_KEY
                                                                                   NULL,     --SFRSTCR_ATTEND_HR
                                                                                   'Y',     --SFRSTCR_REPT_OVER
                                                                                   'N' ,    --SFRSTCR_RPTH_OVER
                                                                                   NULL,    --SFRSTCR_TEST_OVER
                                                                                   'N',    --SFRSTCR_CAMP_OVER
                                                                                   nvl (p_usuario,user),    --SFRSTCR_USER
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
                                                                                   nvl (p_usuario,user),--SFRSTCR_USER_ID
                                                                                   vl_orden--SFRSTCR_VPDI_CODE
                                                                                    );
                                                    exception when others then
                                                        vl_error := ('Se presento un error al insertar en la tabla SFRSTCR 2 ' || sqlerrm);
                                                    end;


                                                    BEGIN
                                                        UPDATE SZTPRONO
                                                                SET SZTPRONO_ENVIO_HORARIOS='S'
                                                        WHERE 1 = 1
                                                        AND SZTPRONO_NO_REGLA = p_regla
                                                        AND SZTPRONO_PIDM = c.pidm
                                                        and sztprono_materia_legal = c.materia
                                                        and SZTPRONO_ENVIO_HORARIOS='N';
                                                    EXCEPTION WHEN OTHERS THEN
                                                      vl_error := 'Se presento un error al insertar en la tabla SZTPRONO 2 ' || sqlerrm;
                                                    END;


                                                    BEGIN
                                                         UPDATE ssbsect
                                                            SET ssbsect_enrl = ssbsect_enrl + 1
                                                         WHERE 1 = 1
                                                         AND ssbsect_term_code = c.periodo
                                                         AND SSBSECT_CRN  = crn;
                                                    EXCEPTION WHEN OTHERS THEN
                                                        vl_error := 'Se presento un error al actualizar el enrolamiento ' ||SQLERRM;
                                                    END;

                                                    BEGIN
                                                        UPDATE ssbsect
                                                                SET ssbsect_seats_avail=ssbsect_seats_avail -1
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
                                                                                     A.SGBSTDN_USER_ID =nvl (p_usuario,user)
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
                                                        AND SFRSTCR_TERM_CODE||SFRSTCR_PTRM_CODE != c.periodo||c.parte
                                                        And SFRSTCR_RSTS_CODE = 'RE'
                                                        AND sfrstcr_pidm = c.pidm
                                                        AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;
                                                    EXCEPTION WHEN OTHERS THEN
                                                        l_cambio_estatus:=0;
                                                    END;


                                                     IF l_cambio_estatus > 0 THEN
                                                         IF C.SGBSTDN_STYP_CODE in ('N','R') THEN
                                                             BEGIN
                                                                 UPDATE sgbstdn a SET a.sgbstdn_styp_code ='C',
                                                                                      a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                                                      A.SGBSTDN_USER_ID =nvl (p_usuario,user)
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
                                                                set sorlcur_start_date  = trunc (f_inicio),
                                                                    SORLCUR_RATE_CODE = c.rate
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
                                                        And sfrareg_rsts_code = p_estatus;

                                                    EXCEPTION WHEN OTHERS THEN
                                                       conta_ptrm :=0;
                                                    END;

                                                    IF conta_ptrm = 0 THEN

                                                         BEGIN
                                                                 INSERT INTO sfrareg VALUES(c.pidm,
                                                                                            c.periodo,
                                                                                            crn ,
                                                                                            0,
                                                                                            p_estatus,
                                                                                            nvl(f_inicio,pn_fecha),
                                                                                            nvl(f_fin,sysdate),
                                                                                            'N',
                                                                                            'N',
                                                                                            SYSDATE,
                                                                                            nvl (p_usuario,user),
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
                                                              vl_error := 'Se presento un error al insertar sfrareg 2 el registro de la materia para el alumno ' ||SQLERRM;
                                                         END;

                                                    END IF;

                                                    BEGIN
                                                        UPDATE SZTPRONO
                                                            SET SZTPRONO_ENVIO_HORARIOS='S'
                                                        WHERE 1 = 1
                                                        AND SZTPRONO_NO_REGLA = p_regla
                                                        and SZTPRONO_ENVIO_HORARIOS='N'
                                                        and sztprono_materia_legal = c.materia
                                                        AND SZTPRONO_PIDM = c.pidm;
                                                    EXCEPTION WHEN OTHERS THEN
                                                          vl_error := 'Se presento un error al insertar en la tabla SZTPRONO 3 ' || sqlerrm;
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

                                    dbms_output.put_line('mensaje:'|| 'No hay grupo creado Con docente 3');

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

                                    if c.nivel ='MS' then

                                        l_campus_ms:='AS';
                                    else
                                        l_campus_ms:=c.niVel;

                                    end if;

                                    BEGIN
                                        select sztcrnv_crn
                                        into crn
                                        from SZTCRNV
                                        where 1 = 1
                                        and rownum = 1
                                        AND SZTCRNV_LVEL_CODE = SUBSTR(l_campus_ms,1,1)
                                        and (SZTCRNV_crn,SZTCRNV_LVEL_CODE) not in (select to_number(crn),
                                                                                           substr(SSBSECT_CRN,1,1)
                                                                                   from
                                                                                   (
                                                                                   select case when
                                                                                                  substr(SSBSECT_CRN,1,1) in('L','M','A','D','B','E') then to_number(substr(SSBSECT_CRN,2,10))
                                                                                                 else
                                                                                                       to_number(SSBSECT_CRN)
                                                                                                 end crn,
                                                                                                 SSBSECT_CRN
                                                                                       from ssbsect
                                                                                       where 1 = 1
                                                                                       and ssbsect_term_code=  c.periodo
                                        --                                               AND SUBSTR(SSBSECT_CRN,1,1) !='L'
                                                                                   )
                                                                                   where 1 = 1
                                                                                   );

                                    EXCEPTION WHEN OTHERS THEN
--                                        raise_application_error (-20002,'Error al 2  '|| SQLCODE||' Error: '||SQLERRM);
                                        dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                        crn := NULL;
                                    END;

                                    If crn is not null then

                                            if c.nivel ='LI' then
                                                crn:='L'||crn;
                                            Elsif c.nivel ='MA' then
                                                crn:='M'||crn;
                                            Elsif c.nivel ='MS' then
                                                crn:='A'||crn;
                                            Elsif c.nivel ='DO' then
                                                crn:='D'||crn;
                                            Elsif c.nivel ='EC' then
                                                crn:='E'||crn;
                                            end if;

                                    else

                                        begin

                                            select NVL(MAX(to_number(SSBSECT_CRN)),0)+1
                                            into crn
                                            from ssbsect
                                            where 1 = 1
                                            and ssbsect_term_code = c.periodo
                                            and SUBSTR(ssbsect_crn,1,1)  not in ('L','M','A','D','B');

                                        exception   when others then
                                            crn:=0;
                                        end;
                                    End if;

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
                                                l_maximo_alumnos:=90;
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
                                                                        'ENL',    --SSBSECT_SCHD_CODE
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
                                                                        nvl (p_usuario,user),--SSBSECT_USER_ID
                                                                        'MOOD',--SSBSECT_INTG_CDE
                                                                        'B',--SSBSECT_PREREQ_CHK_METHOD_CDE
                                                                        nvl (p_usuario,user),--SSBSECT_KEYWORD_INDEX_ID
                                                                        NULL,--SSBSECT_SCORE_OPEN_DATE
                                                                        NULL,--SSBSECT_SCORE_CUTOFF_DATE
                                                                        NULL,--SSBSECT_REAS_SCORE_OPEN_DATE
                                                                        NULL,--SSBSECT_REAS_SCORE_CTOF_DATE
                                                                        NULL,--SSBSECT_SURROGATE_ID
                                                                        NULL,--SSBSECT_VERSION
                                                                        NULL--SSBSECT_VPDI_CODE
                                                                        );

                                            BEGIN
                                                UPDATE SOBTERM
                                                        set sobterm_crn_oneup = crn
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
                                                                            nvl (p_usuario,user),
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

                                                --dbms_output.put_line('Crea el CRN para el docente:'|| pidm_prof  ||'*'||crn);

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
                                                                                                nvl (p_usuario,user),
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
                                                                UPDATE sirasgn
                                                                    SET sirasgn_primary_ind = NULL
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
                                                                                               nvl (p_usuario,user),
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
                                                                               nvl (p_usuario,user),
                                                                               NULL,
                                                                               'PRONOSTICO',
                                                                               NULL,
                                                                               0,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               nvl (p_usuario,user),
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
                                                                                   p_estatus,     --SFRSTCR_RSTS_CODE
                                                                                   sysdate,    --SFRSTCR_RSTS_DATE
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
                                                                                   sysdate,      --SFRSTCR_ADD_DATE
                                                                                   sysdate,     --SFRSTCR_ACTIVITY_DATE
                                                                                   c.nivel,     --SFRSTCR_LEVL_CODE
                                                                                   c.campus,     --SFRSTCR_CAMP_CODE
                                                                                   c.materia,     --SFRSTCR_RESERVED_KEY
                                                                                   null,     --SFRSTCR_ATTEND_HR
                                                                                   'Y',     --SFRSTCR_REPT_OVER
                                                                                   'N' ,    --SFRSTCR_RPTH_OVER
                                                                                   null,    --SFRSTCR_TEST_OVER
                                                                                   'N',    --SFRSTCR_CAMP_OVER
                                                                                   nvl (p_usuario,user),    --SFRSTCR_USER
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
                                                                                   nvl (p_usuario,user),--SFRSTCR_USER_ID
                                                                                   vl_orden--SFRSTCR_VPDI_CODE
                                                                                   );
                                                    EXCEPTION WHEN OTHERS THEN
                                                     --   dbms_output.put_line('Error al insertar  SFRSTCR xxx '||sqlerrm);
                                                         vl_error := ('Se presento un error al insertar en la tabla SFRSTCR 4 ' || SQLERRM);
                                                    END;

                                                    BEGIN
                                                        UPDATE SZTPRONO
                                                            SET SZTPRONO_ENVIO_HORARIOS='S'
                                                        WHERE 1 = 1
                                                        AND SZTPRONO_NO_REGLA = p_regla
                                                        AND SZTPRONO_PIDM = c.pidm
                                                        and sztprono_materia_legal = c.materia
                                                        and SZTPRONO_ENVIO_HORARIOS='N';
                                                    EXCEPTION WHEN OTHERS THEN
                                                       vl_error := ('Se presento un error al insertar en la tabla SZTPRONO 4 ' || SQLERRM);
                                                    END;


                                                    BEGIN
                                                         UPDATE ssbsect
                                                            SET ssbsect_enrl = ssbsect_enrl + 1
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
                                                        UPDATE ssbsect
                                                            SET ssbsect_census_enrl=ssbsect_enrl
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
                                                                                 A.SGBSTDN_USER_ID =nvl (p_usuario,user)
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
                                                             AND SFRSTCR_TERM_CODE||SFRSTCR_PTRM_CODE != c.periodo||c.parte
                                                             And SFRSTCR_RSTS_CODE = 'RE'
                                                             AND sfrstcr_pidm = c.pidm
                                                             AND SFRSTCR_STSP_KEY_SEQUENCE = c.study;
                                                    EXCEPTION WHEN OTHERS THEN
                                                         l_cambio_estatus:=0;
                                                    END;


                                                     IF l_cambio_estatus > 0 THEN

                                                         IF C.SGBSTDN_STYP_CODE in ('N','R') THEN
                                                                 BEGIN
                                                                     UPDATE sgbstdn a
                                                                                        SET a.sgbstdn_styp_code ='C',
                                                                                          a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                                                          A.SGBSTDN_USER_ID =nvl (p_usuario,user)
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
--                                                        raise_application_error (-20002,vl_error);

                                                    END;

                                                    IF f_inicio IS NOT NULL THEN

                                                        BEGIN
                                                            UPDATE sorlcur SET sorlcur_start_date  = TRUNC(f_inicio),
                                                                                sorlcur_data_origin = 'PRONOSTICO',
                                                                           sorlcur_user_id = nvl (p_usuario,user),
                                                                           SORLCUR_RATE_CODE = c.rate
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
                                                        AND sfrareg_rsts_code = p_estatus;

                                                    EXCEPTION
                                                        WHEN OTHERS THEN
                                                       conta_ptrm :=0;
                                                    END;

                                                    IF conta_ptrm = 0 THEN

                                                        BEGIN

                                                            INSERT INTO sfrareg VALUES(
                                                                                       c.pidm,
                                                                                       c.periodo,
                                                                                       crn ,
                                                                                       0,
                                                                                      p_estatus,
                                                                                       nvl(f_inicio,pn_fecha),
                                                                                       nvl(f_fin,sysdate),
                                                                                       'N',
                                                                                       'N',
                                                                                       SYSDATE,
                                                                                       nvl (p_usuario,user),
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
                                                        UPDATE SZTPRONO
                                                            SET SZTPRONO_ENVIO_HORARIOS='S'
                                                        WHERE 1 = 1
                                                        AND SZTPRONO_NO_REGLA = p_regla
                                                        and SZTPRONO_ENVIO_HORARIOS='N'
                                                        and sztprono_materia_legal = c.materia
                                                        AND SZTPRONO_PIDM = c.pidm;
                                                    EXCEPTION WHEN OTHERS THEN
                                                         vl_error := 'Se presento un error al insertar el registro de la materia en SZTPRONO ' ||SQLERRM;
                                                    END;

                                            EXCEPTION WHEN OTHERS THEN
                                                vl_error := 'Se presento un error al insertar al alumno en el grupo3 ' ||SQLERRM;
                                            END;

                                            --l_retorna_dsi:=PKG_FINANZAS_REZA.F_ACTUALIZA_RATE_DSI ( c.iden, c.fecha_inicio );

                                            dbms_output.put_line('mensaje1:'|| 'SE creo el grupo :=' ||crn);

                                        EXCEPTION WHEN OTHERS THEN
                                            vl_error := 'Se presento un Error al insertar el nuevo grupo 3 crn '||crn||' error ' ||SQLERRM;
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
                                                                     nvl (p_usuario,user),         --SZCARGA_USER_ID
                                                                     SYSDATE,         --SZCARGA_ACTIVITY_DATE
                                                                     c.fecha_inicio,         --SZCARGA_FECHA_INI
                                                                     'P',          --SZCARGA_ESTATUS
                                                                     'Horario Generado' ,  --SZCARGA_OBSERVACIONES
                                                                     'PRON',
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
                                                                     nvl (p_usuario,user),         --SZCARGA_USER_ID
                                                                     sysdate,         --SZCARGA_ACTIVITY_DATE
                                                                     c.fecha_inicio,         --SZCARGA_FECHA_INI
                                                                     'E',          --SZCARGA_ESTATUS
                                                                     vl_error,  --SZCARGA_OBSERVACIONES
                                                                     'PRON',
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
                                                         SZTPRONO_ESTATUS_ERROR ='S',
                                                         SZTPRONO_DESCRIPCION_ERROR=vl_error
                                     WHERE 1 = 1
                                     AND SZTPRONO_MATERIA_LEGAL = c.materia
                                     AND SZTPRONO_NO_REGLA=P_REGLA
                                     AND SZTPRONO_pIDm=c.pidm;

                               EXCEPTION WHEN OTHERS THEN
                                   dbms_output.put_line(' Error al actualizar '||sqlerrm);
                               END;

                               commit;

--                               raise_application_error (-20002,vl_error);

                                BEGIN

                                    INSERT INTO sztcarga VALUES (c.iden, --SZCARGA_ID
                                                                 c.materia, --SZCARGA_MATERIA
                                                                 c.prog,         --SZCARGA_PROGRAM
                                                                 c.periodo,         --SZCARGA_TERM_CODE
                                                                 c.parte,         --SZCARGA_PTRM_CODE
                                                                 c.grupo,         --SZCARGA_GRUPO
                                                                 null,         --SZCARGA_CALIF
                                                                 c.prof,         --SZCARGA_ID_PROF
                                                                 nvl (p_usuario,user),         --SZCARGA_USER_ID
                                                                 sysdate,         --SZCARGA_ACTIVITY_DATE
                                                                 c.fecha_inicio,         --SZCARGA_FECHA_INI
                                                                 'A',--'P',          --SZCARGA_ESTATUS
                                                                 vl_error,  --SZCARGA_OBSERVACIONES
                                                                 'PRON',
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

                                  SELECT DECODE(c.sgbstdn_stst_code,'BT','BAJA TEMPORAL','BD','BAJA TEMPORAL','BI', 'BAJA POR INACTIVIDAD','CV', 'CANCELACI? DE VENTA','CM','CANCELACI? DE MATR?ULA','CC', 'CAMBIO DE CILO','CF','CAMBIO DE FECHA','CP','CAMBIO DE PROGRAMA','EG','EGRESADO')
                                  INTO L_DESCRIPCION_ERROR
                                  FROM DUAL;
                              exception when others then
                                  l_descripcion_error:='Sin descripcion';
                              end;

                              if L_DESCRIPCION_ERROR is null then
                                   L_DESCRIPCION_ERROR:=c.sgbstdn_stst_code;
                              end if;

                              Begin
                                   UPDATE sztprono
                                        SET SZTPRONO_ESTATUS_ERROR ='S',
                                              SZTPRONO_DESCRIPCION_ERROR=L_DESCRIPCION_ERROR
                                   WHERE 1 = 1
                                   AND SZTPRONO_MATERIA_LEGAL = c.materia
                                   AND SZTPRONO_NO_REGLA=P_REGLA
                                   AND SZTPRONO_PIDM=c.pidm;
                              EXCEPTION WHEN OTHERS THEN
                                 dbms_output.put_line(' Error al actualizar '||sqlerrm);
                              END;


                            vl_error := 'Estatus no validoo para realizar la carga: '||C.SGBSTDN_STST_CODE;

                            BEGIN

                                INSERT INTO sztcarga VALUES (c.iden, --SZCARGA_ID
                                                             c.materia, --SZCARGA_MATERIA
                                                             c.prog,         --SZCARGA_PROGRAM
                                                             c.periodo,         --SZCARGA_TERM_CODE
                                                             c.parte,         --SZCARGA_PTRM_CODE
                                                             c.grupo,         --SZCARGA_GRUPO
                                                             null,         --SZCARGA_CALIF
                                                             c.prof,         --SZCARGA_ID_PROF
                                                             nvl (p_usuario,user),         --SZCARGA_USER_ID
                                                             sysdate,         --SZCARGA_ACTIVITY_DATE
                                                             c.fecha_inicio,         --SZCARGA_FECHA_INI
                                                             'A',--'P',          --SZCARGA_ESTATUS
                                                             vl_error,  --SZCARGA_OBSERVACIONES
                                                             'PRON',
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

--                             raise_application_error (-20002,'Este alumno '||c.iden||' se encuentra con '||l_descripcion_error);

                        END IF;

                --end if;

          END LOOP;

          COMMIT;



                    --raise_application_error (-20002,vl_error);
                         ------------------- Realiza el proceso de actualizacion de Jornadas  ----------------------------------

                    BEGIN

                        FOR c IN (
                                   SELECT SZTPRONO_ID,
                                          SZTPRONO_TERM_CODE,
                                          SZTPRONO_PTRM_CODE,
                                          spriden_pidm ,
                                          sorlcur_key_seqno,
                                          sorlcur_levl_code Nivel,
                                          COUNT (*) numero
                                   FROM sztprono,
                                        spriden,
                                        sorlcur  s
                                   WHERE 1 = 1
                                    And SZTPRONO_ENVIO_MOODL = 'S'
                                    and SZTPRONO_ENVIO_HORARIOS ='S'
                                    And SZTPRONO_NO_REGLA = p_regla
                                   AND SZTPRONO_ID = spriden_id
                                   And spriden_change_ind is null
                                   AND s.sorlcur_pidm = spriden_pidm
                                   ANd s.sorlcur_pidm = p_pidm
                                   AND s.sorlcur_program=SZTPRONO_PROGRAM
                                   AND s.sorlcur_lmod_code='LEARNER'
                                   AND s.sorlcur_seqno in (SELECT MAX(ss.sorlcur_seqno)
                                                           FROM sorlcur ss
                                                           WHERE 1 = 1
                                                           AND s.sorlcur_pidm=ss.sorlcur_pidm
                                                           AND s.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                           AND s.sorlcur_program=ss.sorlcur_program
                                                           )
                                   GROUP BY sorlcur_levl_code,
                                            SZTPRONO_ID,
                                            SZTPRONO_TERM_CODE,
                                            SZTPRONO_PTRM_CODE,
                                            spriden_pidm,
                                            sorlcur_key_seqno,
                                            sorlcur_levl_code
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
                                    pkg_algoritmo.p_actualiza_jornada (c.spriden_pidm, c.SZTPRONO_TERM_CODE, vl_jornada, c.sorlcur_key_seqno);
                                EXCEPTION WHEN OTHERS THEN
                                    null;
                                END;

                           END IF;



                       END LOOP;

                       COMMIT;

                    END;
        Else
                 vl_error := 'Esta Materia presenta Errores No se puede crear el Horario conserva el grupo 00...  validar el Error en el Pronostico ';
        end if;


        COMMIT;

        p_error := vl_error;

   END;

  PROCEDURE p_ajusta_rate ( p_regla   NUMBER
                                          )

is
vl_salida varchar2(250):= null;

        Begin

                        For c in (

                                    With numero as (
                                      Select count(*) cantidad, SFRSTCR_PIDM pidm, SFRSTCR_STSP_KEY_SEQUENCE sp
                                      from sfrstcr
                                      where 1= 1
                                    --  And sfrstcr_pidm = 54510
                                      And SFRSTCR_RSTS_CODE ='RE'
                                      group by SFRSTCR_PIDM, SFRSTCR_STSP_KEY_SEQUENCE
                                      )
                                      select distinct  b.SZTPRONO_ID matricula,
                                                            a.SZSTUME_START_DATE Fecha_Inicio,
                                                            a.SZSTUME_NO_REGLA Regla,
                                                     --       b.SZTPRONO_MATERIA_LEGAL Materia,
                                                            a.SZSTUME_PIDM,
                                                            b.SZTPRONO_RATE  rate,
                                                            b.SZTPRONO_TERM_CODE Periodo,
                                                            b.SZTPRONO_STUDY_PATH Sp,
                                                            d.cantidad,
                                                            c.SZTALGO_CAMP_CODE campus,
                                                            c.SZTALGO_LEVL_CODE Nivel
                                      from SZSTUME a, sztprono b, SZTALGO c, numero d
                                      where a.SZSTUME_NO_REGLA = p_regla
                                      And a.SZSTUME_RSTS_CODE = 'RE'
                                      And a.SZSTUME_STAT_IND = '1'
                                       And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                          from SZSTUME a1
                                                          Where 1=1
                                                          And a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                          And a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                          And a.SZSTUME_STAT_IND =  a1.SZSTUME_STAT_IND
                                                          And a.SZSTUME_RSTS_CODE = a1.SZSTUME_RSTS_CODE
                                                          And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                                                          )
                                      And b.SZTPRONO_PIDM = a.SZSTUME_PIDM and  b.SZTPRONO_NO_REGLA= a.SZSTUME_NO_REGLA and SZTPRONO_MATERIA_LEGAL = SZSTUME_SUBJ_CODE_COMP
                                              and b.SZTPRONO_ENVIO_MOODL = 'S' and b.SZTPRONO_ENVIO_HORARIOS ='S'
                                              And c.SZTALGO_NO_REGLA = a.SZSTUME_NO_REGLA and  SZTALGO_ESTATUS_CERRADO = 'S'
                                              And substr (b.SZTPRONO_RATE, 3,1) = 3
                                              And substr (b.SZTPRONO_RATE, 1,1) != 'P'
                                              And b.SZTPRONO_PIDM = d.pidm and b.SZTPRONO_STUDY_PATH = d.sp
                                              And d.cantidad >= 4
                                         --    And SZTPRONO_ID ='010196324'
                                              --and SZSTUME_TERM_NRC = 'L3HE40101'
                                      order by 3

        ) Loop

                    Begin
                        vl_salida :=PKG_FINANZAS.F_ACTUALIZA_RATE(c.SZSTUME_PIDM, c.periodo, c.rate, c.sp, c.regla);
                        Commit;
                    Exception
                        When Others then
                            null;
                    End;

        End loop;





End    p_ajusta_rate;

--
  PROCEDURE p_ajusta_tipo_F ( p_regla   NUMBER
                                      )

    Is


Begin

            For c in (

                                         select distinct a.SZSTUME_START_DATE Fecha_Inicio, a.SZSTUME_NO_REGLA Regla, a.SZSTUME_PIDM Pidm, b.SZTPRONO_PROGRAM programa
                                          from SZSTUME a, sztprono b, AS_ALUMNOS d
                                          where a.SZSTUME_NO_REGLA = p_regla--:BUTTON_CONTROL_BLOCK.regla
                                          And a.SZSTUME_RSTS_CODE = 'RE'
                                          And a.SZSTUME_STAT_IND = '1'
                                           And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                      from SZSTUME a1
                                                                                      Where 1=1
                                                                                      And a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                                                      And a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                                                      And a.SZSTUME_STAT_IND =  a1.SZSTUME_STAT_IND
                                                                                      And a.SZSTUME_RSTS_CODE = a1.SZSTUME_RSTS_CODE
                                                                                      And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                                                              )
                                          And b.SZTPRONO_PIDM = a.SZSTUME_PIDM and  b.SZTPRONO_NO_REGLA= a.SZSTUME_NO_REGLA and SZTPRONO_MATERIA_LEGAL = SZSTUME_SUBJ_CODE_COMP
                                          and b.SZTPRONO_ENVIO_MOODL = 'S' and b.SZTPRONO_ENVIO_HORARIOS ='S'
                                          And d.AS_ALUMNOS_NO_REGLA = a.SZSTUME_NO_REGLA AND d.SGBSTDN_PIDM = b.SZTPRONO_PIDM And d.AS_ALUMNOS_TYPE_CODE ='F'

            ) loop


                                   BEGIN

                                        UPDATE sgbstdn a SET a.sgbstdn_styp_code ='N',
                                                             a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                             A.SGBSTDN_USER_ID =USER
                                        WHERE 1 = 1
                                        AND a.sgbstdn_pidm = c.pidm
                                        And a.sgbstdn_styp_code in ('F')
                                        AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                       FROM sgbstdn a1
                                                                       WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                       AND a1.sgbstdn_program_1 = a.sgbstdn_program_1
                                                                       And a1.sgbstdn_styp_code = a.sgbstdn_styp_code
                                                                       )
                                        AND a.sgbstdn_program_1 = c.programa;

                                   EXCEPTION WHEN OTHERS THEN
                                       -- vl_error := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
                                       null;
                                   END;


                                   Begin
                                            Update AS_ALUMNOS
                                            set AS_ALUMNOS_TYPE_CODE ='C'
                                            Where 1= 1
                                            And SGBSTDN_PIDM = c.pidm
                                            And AS_ALUMNOS_NO_REGLA = c.regla
                                            and AS_ALUMNOS_TYPE_CODE = 'F';
                                   Exception
                                    When Others then
                                        null;
                                   End;


                                   Begin
                                                Update tztprog
                                                set SGBSTDN_STYP_CODE = 'N'
                                                Where pidm = c.pidm
                                                And SGBSTDN_STYP_CODE = 'F';
                                               -- And PROGRAMA = c.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

            End Loop;


End p_ajusta_tipo_F;


  PROCEDURE p_ajusta_tipo_N_R ( p_regla   NUMBER
                                      )

    Is


Begin

           For c in (

                                    With numero as (
                                      Select count(distinct SFRSTCR_PTRM_CODE) cantidad, SFRSTCR_PIDM pidm, SFRSTCR_STSP_KEY_SEQUENCE sp
                                      from sfrstcr
                                      where 1= 1
                                   --   And sfrstcr_pidm = 42519
                                      And SFRSTCR_RSTS_CODE ='RE'
                                      group by SFRSTCR_PIDM, SFRSTCR_STSP_KEY_SEQUENCE
                                      )
                                      select distinct  b.SZTPRONO_ID matricula,
                                                            a.SZSTUME_NO_REGLA Regla,
                                                            a.SZSTUME_PIDM pidm,
                                                            d.cantidad,
                                                            SZTPRONO_PROGRAM Programa
                                      from SZSTUME a, sztprono b, numero d, AS_ALUMNOS c
                                      where a.SZSTUME_NO_REGLA = p_regla
                                      And a.SZSTUME_RSTS_CODE = 'RE'
                                      And a.SZSTUME_STAT_IND = '1'
                                       And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                  from SZSTUME a1
                                                                                  Where 1=1
                                                                                  And a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                                                  And a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                                                  And a.SZSTUME_STAT_IND =  a1.SZSTUME_STAT_IND
                                                                                  And a.SZSTUME_RSTS_CODE = a1.SZSTUME_RSTS_CODE
                                                                                  And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                                               )
                                      And b.SZTPRONO_PIDM = a.SZSTUME_PIDM and  b.SZTPRONO_NO_REGLA= a.SZSTUME_NO_REGLA and SZTPRONO_MATERIA_LEGAL = SZSTUME_SUBJ_CODE_COMP
                                              and b.SZTPRONO_ENVIO_MOODL = 'S' and b.SZTPRONO_ENVIO_HORARIOS ='S'
                                              And b.SZTPRONO_PIDM = d.pidm and b.SZTPRONO_STUDY_PATH = d.sp
                                              And d.cantidad >= 2
                                              And c.AS_ALUMNOS_NO_REGLA = a.SZSTUME_NO_REGLA AND c.SGBSTDN_PIDM = b.SZTPRONO_PIDM And c.AS_ALUMNOS_TYPE_CODE in ('N','R')
                                         --    And SZTPRONO_ID ='010196324'
                                              --and SZSTUME_TERM_NRC = 'L3HE40101'
                                      order by 3


          ) loop

                        If c.cantidad >= 2 then

                                   BEGIN

                                        UPDATE sgbstdn a SET a.sgbstdn_styp_code ='C',
                                                             a.SGBSTDN_DATA_ORIGIN ='PRONOSTICO',
                                                             A.SGBSTDN_USER_ID =USER
                                        WHERE 1 = 1
                                        AND a.sgbstdn_pidm = c.pidm
                                        And a.sgbstdn_styp_code in ('R', 'N')
                                        AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                       FROM sgbstdn a1
                                                                       WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                       AND a1.sgbstdn_program_1 = a.sgbstdn_program_1
                                                                       And a1.sgbstdn_styp_code = a.sgbstdn_styp_code
                                                                       )
                                        AND a.sgbstdn_program_1 = c.programa;

                                   EXCEPTION WHEN OTHERS THEN
                                    null;
                                        --vl_error := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||SQLERRM;
                                   END;


                                   Begin
                                            Update AS_ALUMNOS
                                            set AS_ALUMNOS_TYPE_CODE ='C'
                                            Where 1= 1
                                            And SGBSTDN_PIDM = c.pidm
                                            And AS_ALUMNOS_NO_REGLA = c.regla
                                            and AS_ALUMNOS_TYPE_CODE  in ('R', 'N');
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                   Begin
                                                Update tztprog
                                                set SGBSTDN_STYP_CODE = 'C'
                                                Where pidm = c.pidm
                                                And SGBSTDN_STYP_CODE in ('R', 'N');
                                                --And PROGRAMA = c.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                        End if;

          End Loop;

End p_ajusta_tipo_N_R;

--
--
    PROCEDURE      p_job_ec (p_sysdate DATE)
    IS
        l_fecha_inicio       DATE:=TRUNC(SYSDATE);
        l_cuenta_grupo       NUMBER;
        l_cuenta_prof        NUMBER;
        l_cuenta_alumno      NUMBER;
        l_valida             VARCHAR2(10):='EXITO';
        l_secuencia_anterior NUMBER;
        l_califiacion        VARCHAR2(4);
        l_acredita           VARCHAR2(1);
        l_fecha_final        DATE;
        l_dias_gracia        NUMBER;
        l_fecha              DATE;
        l_cuenta_otro        number;
        l_fecha_correcta     date;
        l_contador           number;
        l_fecha_menor        date;
        l_secuencia_menor    number;
        l_fecha_fuera        date;
        l_baja_abcc         VARCHAR2(200);
    BEGIN

        BEGIN

            SELECT DISTINCt zstpara_param_valor
            INTO l_dias_gracia
            FROM zstpara
            WHERE 1 = 1
            AND zstpara_mapa_id ='PRONO_DAY';

        exception when others then
            l_dias_gracia:=0;
        end;

        -- obtenemos las fechas para el proceso la regla es que son 48 hrs para bajar calificaciones
        l_fecha_inicio:= trunc(p_sysdate);
        --l_fecha_final:=  l_fecha_inicio+  l_dias_gracia;


        dbms_output.put_line(' Fecha hoy  '||l_fecha_inicio);

       -- dbms_output.put_line(' Fecha hoy  '||l_fecha_inicio||' Dias gracia '||l_dias_gracia||' Fecha final '||l_fecha_final);

        FOR c in (SELECT DISTINCT sztalgo_no_regla regla
                  FROM sztalgo A
                  WHERE 1 = 1
                  AND sztalgo_camp_code IN ('UTS','EAF')
                  AND sztalgo_levl_code='EC'
                  AND sztalgo_estatus_cerrado ='S'
                  AND EXISTS(SELECT NULL
                             FROM sztgpme b
                             WHERE 1 = 1
                             AND a.sztalgo_no_regla = b.sztgpme_no_regla)
                  )LOOP

                       dbms_output.put_line(' Fecha hoy  '||l_fecha_inicio||' Dias gracia '||l_dias_gracia||' Fecha final '||l_fecha_final);

                       FOR x IN 1..l_dias_gracia LOOP

                            l_fecha:= l_fecha_inicio - x;

                            BEGIN

                               SELECT COUNT(*)
                               INTO l_cuenta_otro
                               FROM sztgpme
                               WHERE 1 = 1
                               AND sztgpme_no_regla = c.regla
                               AND sztgpme_start_date between  l_fecha and l_fecha_inicio
                               and sztgpme_secuencia > 1;

                            EXCEPTION WHEN OTHERS THEN
                              NULL;
                            END;

                            l_contador:=0;

                            if l_cuenta_otro > 0 then

                                dbms_output.put_line(' Entra a cuenta otro ');

                                -- se evalua la fecha aa ver si encontramos una para poder anclar el proceso JOB
                                BEGIN

                                   SELECT DISTINCT sztgpme_start_date
                                   INTO l_fecha_correcta
                                   FROM sztgpme
                                   WHERE 1 = 1
                                   AND sztgpme_no_regla = c.regla
                                   AND sztgpme_start_date BETWEEN  l_fecha AND l_fecha_inicio
                                   AND sztgpme_secuencia > 1;

                                EXCEPTION WHEN OTHERS THEN
                                  NULL;
                                END;


                                -- cursor para mandar a los grupos cuando no esten sincronizados
                                FOR d in (SELECT *
                                          FROM sztgpme
                                          WHERE 1 = 1
                                          AND sztgpme_no_regla = c.regla
                                          AND sztgpme_start_date = l_fecha_correcta
                                          AND sztgpme_stat_ind ='5'
                                          and sztgpme_secuencia > 1
                                      )LOOP

                                          l_secuencia_anterior:=d.sztgpme_secuencia -1;

                                          BEGIN

                                            UPDATE sztgpme SET sztgpme_stat_ind='0'
                                            WHERE 1 = 1
                                            AND sztgpme_no_regla   = d.sztgpme_no_regla
                                            AND sztgpme_term_nrc   = d.sztgpme_term_nrc
                                            AND sztgpme_start_date = d.sztgpme_start_date
                                            AND sztgpme_nive_seqno = d.sztgpme_nive_seqno;

                                          EXCEPTION WHEN OTHERS THEN
                                            NULL;
                                          END;

                                          BEGIN

                                              SELECT COUNT(*)
                                              INTO l_cuenta_prof
                                              FROM SZSGNME
                                              WHERE 1 = 1
                                              AND szsgnme_no_regla = d.sztgpme_no_regla
                                              AND szsgnme_term_nrc = d.sztgpme_term_nrc
                                              AND szsgnme_start_date = d.sztgpme_start_date
                                              AND szsgnme_nive_seqno = d.sztgpme_nive_seqno
                                              AND szsgnme_stat_ind ='5';

                                          EXCEPTION WHEN OTHERS THEN
                                              NULL;
                                          END;

                                          IF l_cuenta_prof > 0 THEN

                                              BEGIN

                                                  UPDATE szsgnme SET szsgnme_stat_ind ='0'
                                                  WHERE 1 = 1
                                                  AND szsgnme_no_regla = d.sztgpme_no_regla
                                                  AND szsgnme_term_nrc = d.sztgpme_term_nrc
                                                  AND szsgnme_start_date = d.sztgpme_start_date
                                                  AND szsgnme_nive_seqno = d.sztgpme_nive_seqno;

                                              EXCEPTION WHEN OTHERS THEN
                                                  NULL;
                                              END;

                                          END IF;

                                          BEGIN

                                              SELECT COUNT(*)
                                              INTO l_cuenta_alumno
                                              FROM szstume
                                              WHERE 1 = 1
                                              AND szstume_no_regla = d.sztgpme_no_regla
                                              AND szstume_term_nrc = d.sztgpme_term_nrc
                                              AND szstume_start_date = d.sztgpme_start_date
                                              AND szstume_nive_seqno = d.sztgpme_nive_seqno;

                                          EXCEPTION WHEN OTHERS THEN
                                              NULL;
                                          END;

                                          IF l_cuenta_alumno > 0 THEN

                                              FOR x IN (SELECT ume.*,
                                                               get_crn_regla(ume.szstume_pidm,
                                                                             NULL,
                                                                             ume.szstume_subj_code,
                                                                             ume.szstume_no_regla)crn,
                                                                (select DISTINCT sztprono_term_code
                                                                 from sztprono
                                                                 where 1 = 1
                                                                 and sztprono_no_regla =ume.szstume_no_regla
                                                                 and sztprono_pidm = ume.szstume_pidm
                                                                 AND ROWNUM = 1 )term_code
                                                        FROM szstume ume
                                                        WHERE 1 = 1
                                                        AND szstume_no_regla = d.sztgpme_no_regla
                                                        AND szstume_no_regla = d.sztgpme_no_regla
                                                        AND szstume_nive_seqno = d.sztgpme_nive_seqno
                                                        AND szstume_term_nrc = d.sztgpme_term_nrc
                                                        AND szstume_rsts_code ='RE'
                                                        )LOOP

                                                            BEGIN

                                                                SELECT DISTINCT DECODE (szstume_grde_code_final,'0',null,szstume_grde_code_final) calif
                                                                INTO l_califiacion
                                                                FROM szstume
                                                                WHERE 1 = 1
                                                                AND szstume_no_regla = x.szstume_no_regla
                                                                AND szstume_pidm = szstume_pidm
                                                                AND szstume_secuencia = l_secuencia_anterior;

                                                            EXCEPTION WHEN OTHERS THEN
                                                                NULL;
                                                            END;

                                                            BEGIN

                                                                SELECT shrgrde_passed_ind
                                                                INTO l_acredita
                                                                FROM shrgrde
                                                                WHERE 1 = 1
                                                                AND shrgrde_levl_code= 'EC'
                                                                AND shrgrde_code = l_califiacion;

                                                            EXCEPTION WHEN OTHERS THEN
                                                                NULL;
                                                                l_acredita:=null;
                                                            END;

                                                            dbms_output.put_line(' Contar grupo '||l_cuenta_grupo||
                                                                                 ' Cuenta Prof '||l_cuenta_prof||
                                                                                 ' Cuenta Alumno '||l_cuenta_alumno||
                                                                                 ' Secuencia grupo '||d.sztgpme_secuencia||
                                                                                 ' anterior '||l_secuencia_anterior||
                                                                                 ' califica anterior '||l_califiacion||
                                                                                 ' Acredita '||l_acredita||
                                                                                 ' Crn '||x.crn);

                                                            IF l_acredita IS NULL THEN

                                                                NULL;

                                                            ELSIF l_acredita ='Y'  THEN

                                                                BEGIN

                                                                  UPDATE szstume set szstume_stat_ind ='0'
                                                                  WHERE 1 = 1
                                                                  AND szstume_no_regla = x.szstume_no_regla
                                                                  AND szstume_pidm = x.szstume_pidm
                                                                  AND szstume_secuencia = d.sztgpme_secuencia
                                                                  AND szstume_stat_ind ='5';

                                                                EXCEPTION WHEN OTHERS THEN
                                                                  NULL;
                                                                END;

                                                            ELSIF l_acredita ='N' THEN

                                                                 --Proceso para dar debaja si se  reprueba

                                                                BEGIN

                                                                  update  szstume set SZSTUME_STAT_IND ='2',
                                                                                      SZSTUME_OBS='Este registro se encuentra cocmo dado de Baja'
                                                                  WHERE 1 = 1
                                                                  AND szstume_no_regla = x.szstume_no_regla
                                                                  AND szstume_pidm = x.szstume_pidm
                                                                  AND szstume_secuencia > l_secuencia_anterior;

                                                                EXCEPTION WHEN OTHERS THEN
                                                                  NULL;
                                                                END;

                                                                BEGIN

                                                                  UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                                      sztprono_descripcion_error ='Este registro se encuentra cocmo dado de Baja'
                                                                  WHERE 1 = 1
                                                                  AND sztprono_no_regla = x.szstume_no_regla
                                                                  AND sztprono_pidm =x.szstume_pidm
                                                                  AND sztprono_secuencia > l_secuencia_anterior;

                                                                EXCEPTION WHEN OTHERS THEN
                                                                  NULL;
                                                                END;

                                                                begin

                                                                    update sfrstcr set SFRSTCR_RSTS_CODE ='DD',
                                                                                       SFRSTCR_DATA_ORIGIN ='REPROBO',
                                                                                       SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                                                                       SFRSTCR_USER = USER
                                                                    WHERE 1 = 1
                                                                    AND  sfrstcr_term_code = x.term_code
--                                                                    and sfrstcr_crn = x.crn
                                                                    and sfrstcr_pidm = x.szstume_pidm
                                                                    and SFRSTCR_GRDE_CODE is null;

                                                                EXCEPTION WHEN OTHERS THEN
                                                                  NULL;
                                                                END;

                                                                l_contador:=0;
                                                                FOR s in (select DISTINCT SZTPRONO_STUDY_PATH,SZTPRONO_pidm
                                                                           from sztprono
                                                                           where 1 = 1
                                                                           and sztprono_no_regla = x.szstume_no_regla
                                                                           and sztprono_pidm = x.szstume_pidm
--                                                                           and sztprono_materia_legal = x.szstume_subj_code
                                                                           )loop

                                                                                l_contador:=l_contador+1;

                                                                                 l_baja_abcc:=PKG_ABCC.f_monetos_abcc('CAMBIO_ETSTAUS',s.SZTPRONO_STUDY_PATH,s.SZTPRONO_pidm,'BD',USER);

                                                                                    if l_baja_abcc ='EXITO' then

--                                                                                        DELETE SGRSCMT
--                                                                                        WHERE 1 = 1
--                                                                                        AND SGRSCMT_SEQ_NO <> 1
--                                                                                        AND SGRSCMT_PIDM = S.SZTPRONO_pidm;
--
                                                                                        commit;
                                                                                    else
                                                                                        rollback;
                                                                                    end if;

                                                                                exit when l_contador = 1;

                                                                           end loop;

                                                            END IF;

                                                        END LOOP;

                                          END IF;

                                      END LOOP;

                                FOR d IN (SELECT *
                                            FROM sztgpme
                                            WHERE 1 = 1
                                            AND sztgpme_no_regla = c.regla
                                            AND sztgpme_start_date = l_fecha_correcta
                                            AND sztgpme_stat_ind in ('0','1')
                                            AND sztgpme_secuencia > 1
                                    )LOOP
                                              dbms_output.put_line('Entra a proceso GRUPO d.secuencia  '||d.sztgpme_secuencia);
                                          l_secuencia_anterior:=d.sztgpme_secuencia -1;

                                          BEGIN

                                              SELECT COUNT(*)
                                              INTO l_cuenta_alumno
                                              FROM szstume
                                              WHERE 1 = 1
                                              AND szstume_no_regla = d.sztgpme_no_regla
                                              AND szstume_term_nrc = d.sztgpme_term_nrc
                                              AND szstume_start_date = d.sztgpme_start_date
                                              AND szstume_nive_seqno = d.sztgpme_nive_seqno
                                              and szstume_stat_ind ='5';

                                          EXCEPTION WHEN OTHERS THEN
                                              NULL;
                                          END;

                                          IF l_cuenta_alumno > 0 THEN

                                              dbms_output.put_line('Entra a proceso GRUPO 2');
                                              FOR x IN (SELECT ume.*,
                                                               get_crn_regla(ume.szstume_pidm,
                                                                             null,
                                                                             ume.szstume_subj_code,
                                                                             ume.szstume_no_regla)crn,
                                                               (select DISTINCT sztprono_term_code
                                                                 from sztprono
                                                                 where 1 = 1
                                                                 and sztprono_no_regla =ume.szstume_no_regla
                                                                 and sztprono_pidm = ume.szstume_pidm
                                                                 AND ROWNUM = 1 )term_code
                                                        FROM szstume ume
                                                        WHERE 1 = 1
                                                        AND szstume_no_regla = d.sztgpme_no_regla
                                                        AND szstume_no_regla = d.sztgpme_no_regla
                                                        AND szstume_nive_seqno = d.sztgpme_nive_seqno
                                                        AND szstume_term_nrc = d.sztgpme_term_nrc
                                                        AND szstume_rsts_code ='RE'
                                                        and szstume_stat_ind ='5'
                                                        )LOOP

                                                            dbms_output.put_line('Entra a proceso regla '||x.szstume_no_regla||' Califica '||l_secuencia_anterior);

                                                            BEGIN

                                                                SELECT DISTINCT DECODE (szstume_grde_code_final,'0',null,szstume_grde_code_final) calif
                                                                INTO l_califiacion
                                                                FROM szstume
                                                                WHERE 1 = 1
                                                                AND szstume_no_regla = x.szstume_no_regla
                                                                AND szstume_pidm = x.szstume_pidm
                                                                AND szstume_secuencia = l_secuencia_anterior;

                                                            EXCEPTION WHEN OTHERS THEN
                                                                NULL;
                                                            END;


                                                             dbms_output.put_line('Calificacion  '||l_califiacion||' Secuencia anterior '||l_secuencia_anterior);

                                                            BEGIN
                                                                SELECT shrgrde_passed_ind
                                                                INTO l_acredita
                                                                FROM shrgrde
                                                                WHERE 1 = 1
                                                                AND shrgrde_levl_code= 'EC'
                                                                AND shrgrde_code = l_califiacion;

                                                            EXCEPTION WHEN OTHERS THEN
                                                                dbms_output.put_line('Error--> '||sqlerrm||' Califica '||l_califiacion);
                                                                l_acredita:=null;
                                                            END;
--
--                                                            dbms_output.put_line(' Contar grupo '||l_cuenta_grupo||
--                                                                                 ' Cuenta Prof '||l_cuenta_prof||
--                                                                                 ' Cuenta Alumno '||l_cuenta_alumno||
--                                                                                 ' Secuencia grupo '||d.sztgpme_secuencia||
--                                                                                 ' anterior '||l_secuencia_anterior||
--                                                                                 ' califica anterior '||l_califiacion||
--                                                                                 ' Acredita '||l_acredita||
--                                                                                 ' Crn '||x.crn);

                                                            IF l_acredita IS NULL THEN

                                                                NULL;

                                                            ELSIF l_acredita ='Y'  THEN

                                                                BEGIN

                                                                  UPDATE szstume set szstume_stat_ind ='0'
                                                                  WHERE 1 = 1
                                                                  AND szstume_no_regla = x.szstume_no_regla
                                                                  AND szstume_pidm = x.szstume_pidm
                                                                  AND szstume_secuencia = d.sztgpme_secuencia
                                                                  AND szstume_stat_ind ='5';

                                                                EXCEPTION WHEN OTHERS THEN
                                                                  NULL;
                                                                END;

                                                            ELSIF l_acredita ='N' THEN

                                                                BEGIN

                                                                  update  szstume set SZSTUME_STAT_IND ='2',
                                                                                      SZSTUME_OBS='Este registro se encuentra como dado de Baja',
                                                                                      SZSTUME_RSTS_CODE ='DD'
                                                                  WHERE 1 = 1
                                                                  AND szstume_no_regla = x.szstume_no_regla
                                                                  AND szstume_pidm = x.szstume_pidm
                                                                  AND szstume_secuencia > l_secuencia_anterior;

                                                                EXCEPTION WHEN OTHERS THEN
                                                                  NULL;
                                                                END;

                                                                BEGIN

                                                                  UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                                      sztprono_descripcion_error ='Este registro se encuentra cocmo dado de Baja'
                                                                  WHERE 1 = 1
                                                                  AND sztprono_no_regla = x.szstume_no_regla
                                                                  AND sztprono_pidm =x.szstume_pidm
                                                                  AND sztprono_secuencia > l_secuencia_anterior;

                                                                EXCEPTION WHEN OTHERS THEN
                                                                  NULL;
                                                                END;

                                                                begin

                                                                    update sfrstcr set SFRSTCR_RSTS_CODE ='DD',
                                                                                       SFRSTCR_DATA_ORIGIN ='REPROBO',
                                                                                       SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                                                                       SFRSTCR_USER = USER
                                                                    WHERE 1 = 1
                                                                    AND  sfrstcr_term_code = x.term_code
--                                                                    and sfrstcr_crn = x.crn
                                                                    and sfrstcr_pidm = x.szstume_pidm
                                                                    and SFRSTCR_GRDE_CODE is  null;

                                                                EXCEPTION WHEN OTHERS THEN
                                                                  NULL;
                                                                END;


                                                                l_contador:=0;

                                                                FOR s in (select DISTINCT SZTPRONO_STUDY_PATH,SZTPRONO_pidm
                                                                           from sztprono
                                                                           where 1 = 1
                                                                           and sztprono_no_regla = x.szstume_no_regla
                                                                           and sztprono_pidm = x.szstume_pidm
--                                                                           and sztprono_materia_legal = x.szstume_subj_code
                                                                           )loop

                                                                                l_contador:=l_contador+1;

                                                                                 l_baja_abcc:=PKG_ABCC.f_monetos_abcc('CAMBIO_ETSTAUS',s.SZTPRONO_STUDY_PATH,s.SZTPRONO_pidm,'BD',USER);

                                                                                if l_baja_abcc ='EXITO' then

--                                                                                     DELETE SGRSCMT
--                                                                                     WHERE 1 = 1
--                                                                                     AND SGRSCMT_SEQ_NO > 2
--                                                                                     AND SGRSCMT_PIDM = S.SZTPRONO_pidm;

                                                                                    commit;
                                                                                else
                                                                                    rollback;
                                                                                end if;


                                                                                dbms_output.put_line('Prono '||l_contador);

                                                                                exit when l_contador = 1;




                                                                           end loop;

                                                            END IF;

                                                        END LOOP;

                                          END IF;

                                    END LOOP;

                            ELSE

                                l_contador:=l_contador+1;

                                begin

                                     select distinct a.szstume_secuencia,
                                                     a.szstume_start_date
                                     into l_secuencia_menor,
                                          l_fecha_menor
                                     from szstume a
                                     where 1 = 1
                                     and a.SZSTUME_RSTS_CODE ='RE'
                                     and a.szstume_no_regla = c.regla
                                     and a.SZSTUME_STAT_IND ='5'
                                     and a.szstume_secuencia =(select min(b.szstume_secuencia)
                                                               from szstume b
                                                               where 1 = 1
                                                               and b.SZSTUME_RSTS_CODE =a.SZSTUME_RSTS_CODE
                                                               and b.szstume_no_regla = a.szstume_no_regla
                                                               and b.SZSTUME_STAT_IND =a.SZSTUME_STAT_IND) ;

                                exception when others then
                                     null;
                                end;

                                l_fecha_fuera := l_fecha_menor+l_dias_gracia;

                                if l_fecha_fuera < l_fecha_inicio then



                                   for w in (SELECT ume.*,
                                                               get_crn_regla(ume.szstume_pidm,
                                                                             null,
                                                                             ume.szstume_subj_code,
                                                                             ume.szstume_no_regla)crn,
                                                               (select DISTINCT sztprono_term_code
                                                                 from sztprono
                                                                 where 1 = 1
                                                                 and sztprono_no_regla =ume.szstume_no_regla
                                                                 and sztprono_pidm = ume.szstume_pidm
                                                                 AND ROWNUM = 1 )term_code
                                             FROM szstume ume
                                             where 1 = 1
                                             and szstume_no_regla = c.regla
                                             and szstume_secuencia = l_secuencia_menor
                                             )loop

                                                 dbms_output.put_line(' Calificacion '||w.szstume_grde_code_final);

                                                 if w.szstume_grde_code_final = '0' or w.szstume_grde_code_final is null then

                                                    dbms_output.put_line(' entra 1 ');

                                                     BEGIN

                                                       update  szstume set SZSTUME_STAT_IND ='2',
                                                                           SZSTUME_OBS='Este registro no tiene la calificacion en tiempo y forma',
                                                                           SZSTUME_RSTS_CODE ='DD'
                                                       WHERE 1 = 1
                                                       AND szstume_no_regla = w.szstume_no_regla
                                                       AND szstume_pidm = w.szstume_pidm
                                                       AND szstume_secuencia >= l_secuencia_menor;

                                                     EXCEPTION WHEN OTHERS THEN
                                                       NULL;
                                                     END;

                                                     BEGIN

                                                       UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                           sztprono_descripcion_error ='Este registro no tiene la calificacion en tiempo y forma'
                                                       WHERE 1 = 1
                                                       AND sztprono_no_regla = w.szstume_no_regla
                                                       AND sztprono_pidm =w.szstume_pidm
                                                       AND sztprono_secuencia  >= l_secuencia_menor;

                                                     EXCEPTION WHEN OTHERS THEN
                                                       NULL;
                                                     END;

                                                     begin

                                                         update sfrstcr set SFRSTCR_RSTS_CODE ='DD',
                                                                            SFRSTCR_DATA_ORIGIN ='REPROBO',
                                                                            SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                                                            SFRSTCR_USER = USER
                                                         WHERE 1 = 1
                                                         AND  sfrstcr_term_code = w.term_code
--                                                         and sfrstcr_crn = w.crn
                                                         and sfrstcr_pidm = w.szstume_pidm
                                                         and SFRSTCR_GRDE_CODE is  null;

                                                     EXCEPTION WHEN OTHERS THEN
                                                       NULL;
                                                     END;

                                                     l_contador:=0;
                                                     FOR s in (select DISTINCT SZTPRONO_STUDY_PATH,SZTPRONO_pidm
                                                               from sztprono
                                                               where 1 = 1
                                                               and sztprono_no_regla = w.szstume_no_regla
                                                               and sztprono_pidm = w.szstume_pidm
--                                                               and sztprono_materia_legal = w.szstume_subj_code
                                                               )loop

                                                                    l_contador:=l_contador+1;

                                                                    l_baja_abcc:=PKG_ABCC.f_monetos_abcc('CAMBIO_ETSTAUS',s.SZTPRONO_STUDY_PATH,s.SZTPRONO_pidm,'BD',USER);

                                                                    if l_baja_abcc ='EXITO' then
--
--                                                                         DELETE SGRSCMT
--                                                                        WHERE 1 = 1
--                                                                        AND SGRSCMT_SEQ_NO <> 1
--                                                                        AND SGRSCMT_PIDM = S.SZTPRONO_pidm;
                                                                        commit;
                                                                    else
                                                                        rollback;
                                                                    end if;

                                                                    dbms_output.put_line('Prono '||l_contador);

                                                                    exit when l_contador = 1;

                                                               end loop;



                                                 else

                                                    dbms_output.put_line(' entra 1 ');

                                                     BEGIN

                                                       update  szstume set SZSTUME_STAT_IND ='2',
                                                                           SZSTUME_OBS='Este registro no se le bajo la calificacion '||w.szstume_grde_code_final||' En tiempo',
                                                                           SZSTUME_RSTS_CODE ='DD'
                                                       WHERE 1 = 1
                                                       AND szstume_no_regla = w.szstume_no_regla
                                                       AND szstume_pidm = w.szstume_pidm
                                                       AND szstume_secuencia >= l_secuencia_menor;

                                                     EXCEPTION WHEN OTHERS THEN
                                                       NULL;
                                                     END;

                                                     BEGIN

                                                       UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                           sztprono_descripcion_error ='Este registro no se le bajo la calificacion '||w.szstume_grde_code_final||' En tiempo'
                                                       WHERE 1 = 1
                                                       AND sztprono_no_regla = w.szstume_no_regla
                                                       AND sztprono_pidm =w.szstume_pidm
                                                       AND sztprono_secuencia  >= l_secuencia_menor;

                                                     EXCEPTION WHEN OTHERS THEN
                                                       NULL;
                                                     END;

                                                     begin

                                                          update sfrstcr set SFRSTCR_RSTS_CODE ='DD',
                                                                             SFRSTCR_DATA_ORIGIN ='REPROBO',
                                                                             SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                                                             SFRSTCR_USER = USER
                                                          WHERE 1 = 1
                                                          AND  sfrstcr_term_code = w.term_code
--                                                          and sfrstcr_crn = w.crn
                                                          and sfrstcr_pidm = w.szstume_pidm
                                                          and SFRSTCR_GRDE_CODE is  null;

                                                      EXCEPTION WHEN OTHERS THEN
                                                        NULL;
                                                      END;

                                                     l_contador:=0;

                                                     FOR s in (select DISTINCT SZTPRONO_STUDY_PATH,SZTPRONO_pidm
                                                               from sztprono
                                                               where 1 = 1
                                                               and sztprono_no_regla = w.szstume_no_regla
                                                               and sztprono_pidm = w.szstume_pidm
                                                            --   and sztprono_materia_legal = w.szstume_subj_code
                                                               )loop

                                                                    l_contador:=l_contador+1;
                                                                    l_baja_abcc:=pkg_abcc.f_monetos_abcc('CAMBIO_ETSTAUS',s.SZTPRONO_STUDY_PATH,s.SZTPRONO_pidm,'BD',USER);

                                                                    if l_baja_abcc ='EXITO' then
--
--                                                                         DELETE SGRSCMT
--                                                                    WHERE 1 = 1
--                                                                    AND SGRSCMT_SEQ_NO <> 1
--                                                                    AND SGRSCMT_PIDM = S.SZTPRONO_pidm;
                                                                        commit;
                                                                    else
                                                                        rollback;
                                                                    end if;

                                                                    dbms_output.put_line('Prono '||l_contador);

--                                                                    DELETE SGRSCMT
--                                                                    WHERE 1 = 1
--                                                                    AND SGRSCMT_SEQ_NO <> 1
--                                                                    AND SGRSCMT_PIDM = S.SZTPRONO_pidm;

                                                                    exit when l_contador = 1;

                                                               end loop;

                                                 end if;

                                             end loop;


                                end if;


                                exit when l_contador = 1;

                            END IF;

                            --dbms_output.put_line(' Fecha hoy '||x||' fecha 0 '||l_fecha||' Fecha Inicio '||l_fecha_inicio||' cuntra otro '||l_cuenta_otro||' Fecha Correcta '||l_fecha_correcta);


                       END LOOP;

                  END LOOP;

                  COMMIT;
    end p_job_ec;
--
--Jpg@Create@Nov22 Function revisa si el alumno tiene codigos de detalle de paquetería dinamica
function f_check_online(p_pidm number) Return number is
    dummy number:=0;
Begin
    Begin
        SELECT 1 Into dummy
            FROM TZTPADI PADI
            WHERE 1= 1
            and PADI.TZTPADI_PIDM = p_pidm  ---> Se pone el Pidm del alumno a buscar
            AND PADI.TZTPADI_DETAIL_CODE in (Select ZSTPARA_PARAM_VALOR
                                                                        from ZSTPARA
                                                                        where ZSTPARA_MAPA_ID = 'SESION_EJECUTIV')
            AND PADI.TZTPADI_SEQNO = (SELECT MAX(TZTPADI_SEQNO)
                                                        FROM TZTPADI P2
                                                        WHERE P2.TZTPADI_PIDM=PADI.TZTPADI_PIDM
                                                        AND P2.TZTPADI_DETAIL_CODE=PADI.TZTPADI_DETAIL_CODE
                                                        )
            AND PADI.TZTPADI_FLAG =0;
    Exception When Others Then
            dummy:=0;
    End;

    Return dummy;
End f_check_online;
--
--
--
--Jpg@Create@Nov@21 Function
--Funcion que genera grupos nuevos para alumnos semi-presenciales
--Esta funcion se usa despues de la integracion de alumnos desde forms szfmodl
function f_create_gpo_semi( p_regla number, p_pidm number default null) return varchar2 is

		lc_error varchar2(500):='EXITO';
		
		--Cursor Principal de Poblacion
		Cursor pob_gpo_x is
                Select Distinct SZTGPME_SUBJ_CRSE materia
                    from sztgpme
                    join szstume x on szstume_term_nrc=sztgpme_term_nrc
                                and szstume_no_regla=sztgpme_no_regla
                    join sztprono on sztprono_pidm = SZSTUME_PIDM
                                and sztprono_no_regla=szstume_no_regla
                    Where sztgpme_no_regla = p_regla
                    and szstume_pidm = nvl(p_pidm,szstume_pidm)
                    And Exists(Select 1
                        from sztdtec ax
                        --WHERE SZTDTEC_MOD_TYPE='S' Jpg@Modify@Nov22 Se agregan alumnos online
                        Where  ax.SZTDTEC_TERM_CODE = (select max (ax1.SZTDTEC_TERM_CODE)
                                                    from sztdtec ax1
                                                    Where ax.SZTDTEC_PROGRAM = ax1.SZTDTEC_PROGRAM)
                                                    AND ax.SZTDTEC_PROGRAM = SZTPRONO_PROGRAM
                    --Jpg@Modify@Nov22 Se agregan alumnos online
                            and (ax.SZTDTEC_MOD_TYPE = 'S' OR
                                            ( ax.SZTDTEC_MOD_TYPE = 'OL' and Exists(SELECT 1
                                                    FROM TZTPADI PADI
                                                    WHERE 1= 1
                                                    and PADI.TZTPADI_PIDM = sztprono_pidm
                                                    AND PADI.TZTPADI_DETAIL_CODE in (Select ZSTPARA_PARAM_VALOR
                                                                                                                from ZSTPARA
                                                                                                                where ZSTPARA_MAPA_ID = 'SESION_EJECUTIV')
                                                    AND PADI.TZTPADI_SEQNO = (SELECT MAX(TZTPADI_SEQNO)
                                                                                                FROM TZTPADI P2
                                                                                                WHERE P2.TZTPADI_PIDM=PADI.TZTPADI_PIDM
                                                                                                AND P2.TZTPADI_DETAIL_CODE=PADI.TZTPADI_DETAIL_CODE
                                                                                                )
                                                    AND PADI.TZTPADI_FLAG =0) )
                                )
                    --Jpg@Modify@Nov22 Se agregan alumnos online
                                                    )
                    --Jpg@Modify:REQ:Agos22 Auto enrolamiento a grupo de estudiantes de programas ejecutivos.
                            And (Exists(Select 1 from TZTPROGM where matricula=sztprono_id
                                        and ((SGBSTDN_STYP_CODE in ('N','F')
                                                AND FECHA_INICIO >= TO_DATE('29/08/2022','DD/MM/YYYY')) OR
                                             (SGBSTDN_STYP_CODE in ('C')
                                                AND FECHA_PRIMERA BETWEEN TO_DATE('29/08/2022','DD/MM/YYYY') AND SYSDATE)
                                             )
                                        and estatus='MA'
                                        And Exists(Select 1 from zstpara where zstpara_mapa_id = 'REGLA_GPO EJEC' and ZSTPARA_PARAM_ID = Campus and ZSTPARA_PARAM_VALOR = Nivel)
                                       )
                                )
                            and Not Exists(Select 1 from szstume z  --Solo Alumnos que falte asig gpoX
                                            where x.szstume_pidm=z.szstume_pidm
                                                and x.szstume_no_regla=z.szstume_no_regla
                                                and x.szstume_subj_code=z.szstume_subj_code
                                                and z.szstume_term_nrc like '%X')
                    --Jpg@Modify:REQ:Agos22 Auto enrolamiento a grupo de estudiantes de programas ejecutivos.
                            and Not Exists(Select 1 from sztalmt where sztalmt_materia = szstume_subj_code 
                                            AND sztalmt_alianza not in ('EJEC') --Todos menos EJEC, ahora aceptamos alum con EJEC. FRank@Feb25 
                                          ); --Descarte Materia de Alianzas

        --Funcion que se encarga de crear grupo x's 
		function f_create_grupo ( p_regla number, p_materia varchar2, p_pidm number default null) return varchar2 is

			l_grupo_NEW		varchar2(3);
			l_nrc		varchar2(30);
			l_NRC_NEW	VARCHAR2(30);
			l_pidm_dummy_docente spriden.spriden_pidm%Type := 310784; --ProfesorDummy
			l_error		varchar2(500):='EXITO';
		BEGIN
				BEGIN
					SELECT  X.SZTGPME_TERM_NRC,
--					X.SZTGPME_SUBJ_CRSE||LTRIM(TO_CHAR(X.SZTGPME_GRUPO+1,'09')||'X'),
					X.SZTGPME_SUBJ_CRSE||'90X', --Se cambia, ahora gpo90X para todos los nuevos gpoX
					null --X.SZTGPME_GRUPO+1  --Frank@Modify@Dec22: Se va en nulo para no afectar el conteo de grupos y exista saltos.
					Into l_nrc,
						 l_NRC_NEW,
						 l_grupo_NEW
					FROM SZTGPME X
					Where X.SZTGPME_no_regla= P_REGLA
					and X.SZTGPME_SUBJ_CRSE=  P_MATERIA
					AND X.SZTGPME_TERM_NRC =
						(SELECT MAX(SZTGPME_TERM_NRC)
							FROM SZTGPME Z
							WHERE Z.SZTGPME_no_regla =  X.SZTGPME_no_regla
                            and z.sztgpme_idioma ='E'  --Frank@Abril2024 se fija grupos x's en Español														
							AND Z.SZTGPME_SUBJ_CRSE=X.SZTGPME_SUBJ_CRSE);
				END;

				dbms_output.put_line('Creando Grupo NRC: '||l_nrc||
									 ' NRC_NEW: '||l_NRC_NEW||' Grupo New:'|| l_grupo_NEW);
--pkg_algoritmo.p_track_prono(p_regla,'Creando Grupo NRC: '||l_nrc||
--									 ' NRC_NEW: '||l_NRC_NEW||' Grupo New:'|| l_grupo_NEW);
									 

                IF l_nrc NOT LIKE '%X' THEN
                        BEGIN
                            Insert into sztgpme
                             Select
                                    l_NRC_NEW
                                  ,X.SZTGPME_SUBJ_CRSE
                                  ,X.SZTGPME_TITLE
                                  ,'0'--,X.SZTGPME_STAT_IND
                                  ,null --,X.SZTGPME_OBS
                                  ,X.SZTGPME_USER_ID
                                  ,sysdate --,X.SZTGPME_ACTIVITY_DATE
                                  ,X.SZTGPME_PTRM_CODE
                                  ,X.SZTGPME_START_DATE
                                  ,X.SZTGPME_CRSE_MDLE_ID
                                  ,X.SZTGPME_MAX_ENRL
                                  ,X.SZTGPME_LEVL_CODE
                                  ,X.SZTGPME_CAMP_CODE
                                  ,X.SZTGPME_POBI_SEQ_NO
                                  ,X.SZTGPME_SUBJ_CRSE_COMP
                                  ,X.SZTGPME_INT_OBS
                                  ,X.SZTGPME_TERM_NRC_COMP
                                  ,X.SZTGPME_CAMP_CODE_COMP
                                  ,X.SZTGPME_PTRM_CODE_COMP
                                  ,null --,X.SZTGPME_GPMDLE_ID
                                  ,X.SZTGPME_CRSE_MDLE_CODE
                                  ,X.SZTGPME_NO_REGLA
                                  ,X.SZTGPME_SECUENCIA
                                  ,l_grupo_NEW
                                  ,X.SZTGPME_ACTIVAR_GRUPO
                                  ,X.SZTGPME_NIVE_SEQNO
                                  ,x.sztgpme_idioma  
                            From SZTGPME X
                            Where X.SZTGPME_no_regla= P_REGLA
--                            and X.SZTGPME_SUBJ_CRSE=  P_MATERIA
                            and x.sztgpme_term_nrc=l_nrc;
--                            AND X.SZTGPME_GRUPO =
--                                (SELECT MAX(SZTGPME_GRUPO)
--                                    FROM SZTGPME Z
--                                    WHERE Z.SZTGPME_no_regla =  X.SZTGPME_no_regla
--                                    and z.sztgpme_idioma ='E'  --Frank@Abril2024 se fija grupos x's en Español                                    
--                                    AND Z.SZTGPME_SUBJ_CRSE=X.SZTGPME_SUBJ_CRSE);

                        EXCEPTION WHEN OTHERS THEN
                            l_error:='ErrorInsert->sztgpme: '||SQLERRM;
                        END;

                        BEGIN
                            Insert into SZSGNME
                            Select
                                l_NRC_NEW,
                                l_pidm_dummy_docente,  --x.SZSGNME_PIDM,
                                sysdate,--x.SZSGNME_ACTIVITY_DATE,
                                x.SZSGNME_USER_ID,
                                '0',--x.SZSGNME_STAT_IND,
                                null, --x.SZSGNME_OBS,
                                x.SZSGNME_PWD,
                                null,--x.SZSGNME_ASGNMDLE_ID,
                                x.SZSGNME_FCST_CODE,
                                x.SZSGNME_SEQ_NO,
                                x.SZNME_POBI_SEQ_NO,
                                x.SZSGNME_PTRM,
                                x.SZSGNME_START_DATE,
                                x.SZSGNME_NO_REGLA,
                                x.SZSGNME_SECUENCIA,
                                x.SZSGNME_NIVE_SEQNO
                                , 'E' --x.szsgnme_idioma  --Frank@Abril2024 se fija grupos x's en Español
                            from SZSGNME x
                            where x.SZSGNME_NO_REGLA=	p_regla
                            AND x.SZSGNME_TERM_NRC=		l_nrc;

                        EXCEPTION WHEN OTHERS THEN
                            l_error:='ErrorInsert->SZSGNME: '||SQLERRM;
                        END;
                ELSE
                    --SE ENCONTRO UN GPOX ENTONCES AHI LO METE
                    l_NRC_NEW:=l_NRC;

                        dbms_output.put_line('CAMBIANDO Grupo NRC: '||l_nrc||
									 ' NRC_NEW: '||l_NRC_NEW);
--			pkg_algoritmo.p_track_prono(p_regla,'CAMBIANDO Grupo NRC: '||l_nrc||
--									 ' NRC_NEW: '||l_NRC_NEW);

                END IF;


				BEGIN
					Insert into szstume
					Select Distinct
							l_NRC_NEW
						  ,SZSTUME_PIDM
						  ,SZSTUME_ID
						  ,sysdate --,SZSTUME_ACTIVITY_DATE
						  ,SZSTUME_USER_ID
						  ,'0'--,SZSTUME_STAT_IND
						  ,null--,SZSTUME_OBS
						  ,SZSTUME_PWD
						  ,null--,SZSTUME_MDLE_ID
						  ,SZSTUME_SEQ_NO
						  ,'RE'--,SZSTUME_RSTS_CODE
						  ,SZSTUME_GRDE_CODE_FINAL
						  ,SZSTUME_SUBJ_CODE
						  ,SZSTUME_LEVL_CODE
						  ,SZSTUME_POBI_SEQ_NO
						  ,SZSTUME_PTRM
						  ,SZSTUME_CAMP_CODE
						  ,SZSTUME_CAMP_CODE_COMP
						  ,SZSTUME_LEVL_CODE_COMP
						  ,SZSTUME_TERM_NRC_COMP
						  ,SZSTUME_SUBJ_CODE_COMP
						  ,SZSTUME_START_DATE
						  ,SZSTUME_NO_REGLA
						  ,SZSTUME_SECUENCIA
						  ,SZSTUME_NIVE_SEQNO
                          ,0
                          ,null
					from sztgpme
					join szstume x on szstume_term_nrc=sztgpme_term_nrc
								and szstume_no_regla=sztgpme_no_regla
					join sztprono on sztprono_pidm = SZSTUME_PIDM
								and sztprono_no_regla=szstume_no_regla
					Where sztgpme_no_regla = p_regla
					and SZSTUME_RSTS_CODE='RE'
					AND SZSTUME_SUBJ_CODE=	p_materia
					and szstume_pidm = nvl(p_pidm,szstume_pidm)
					And Exists(Select 1
						from sztdtec ax
				--WHERE SZTDTEC_MOD_TYPE='S' Jpg@Modify@Nov22 Se agregan alumnos online
				Where  ax.SZTDTEC_TERM_CODE = (select max (ax1.SZTDTEC_TERM_CODE)
											from sztdtec ax1
											Where ax.SZTDTEC_PROGRAM = ax1.SZTDTEC_PROGRAM)
											AND ax.SZTDTEC_PROGRAM = SZTPRONO_PROGRAM
            --Jpg@Modify@Nov22 Se agregan alumnos online
                    and (ax.SZTDTEC_MOD_TYPE = 'S' OR
                                    ( ax.SZTDTEC_MOD_TYPE = 'OL' and Exists(SELECT 1
                                            FROM TZTPADI PADI
                                            WHERE 1= 1
                                            and PADI.TZTPADI_PIDM = sztprono_pidm
                                            AND PADI.TZTPADI_DETAIL_CODE in (Select ZSTPARA_PARAM_VALOR
                                                                                                        from ZSTPARA
                                                                                                        where ZSTPARA_MAPA_ID = 'SESION_EJECUTIV')
                                            AND PADI.TZTPADI_SEQNO = (SELECT MAX(TZTPADI_SEQNO)
                                                                                        FROM TZTPADI P2
                                                                                        WHERE P2.TZTPADI_PIDM=PADI.TZTPADI_PIDM
                                                                                        AND P2.TZTPADI_DETAIL_CODE=PADI.TZTPADI_DETAIL_CODE
                                                                                        )
                                            AND PADI.TZTPADI_FLAG =0) )
                        )
            --Jpg@Modify@Nov22 Se agregan alumnos online
											)
            --Jpg@Modify:REQ:Agos22 Auto enrolamiento a grupo de estudiantes de programas ejecutivos.
                    And (Exists(Select 1 from TZTPROGM where matricula=sztprono_id
                                and ((SGBSTDN_STYP_CODE in ('N','F')
                                        AND FECHA_INICIO >= TO_DATE('29/08/2022','DD/MM/YYYY')) OR
                                     (SGBSTDN_STYP_CODE in ('C')
                                        AND FECHA_PRIMERA BETWEEN TO_DATE('29/08/2022','DD/MM/YYYY') AND SYSDATE)
                                     )
                                and estatus='MA'
                                And Exists(Select 1 from zstpara where zstpara_mapa_id = 'REGLA_GPO EJEC' and ZSTPARA_PARAM_ID = Campus and ZSTPARA_PARAM_VALOR = Nivel)
                               )
                        )
                    and Not Exists(Select 1 from szstume z  --Solo Alumnos que falte asig gpoX
                                    where x.szstume_pidm=z.szstume_pidm
                                        and x.szstume_no_regla=z.szstume_no_regla
                                        and x.szstume_subj_code=z.szstume_subj_code
                                        and z.szstume_term_nrc like '%X')
            --Jpg@Modify:REQ:Agos22 Auto enrolamiento a grupo de estudiantes de programas ejecutivos.
                    and Not Exists(Select 1 from sztalmt where sztalmt_materia = szstume_subj_code) --Descarte Materia de Alianzas
					order by 2;

					dbms_output.put_line('Total Alumnos Insertaodos: '||SQL%rowcount||' NRC_Grupo: '||l_NRC_NEW);
--			pkg_algoritmo.p_track_prono(p_regla,'Total Alumnos Insertaodos: '||SQL%rowcount||' NRC_Grupo: '||l_NRC_NEW );

				EXCEPTION WHEN OTHERS THEN
					l_error:='ErrorInsert->szstume: '||SQLERRM;
				END;
			return l_error;
		END f_create_grupo;

    --Inicio Programa principal
	BEGIN

		For x IN pob_gpo_x Loop
			dbms_output.put_line('Procesando materia: '||x.materia);
			begin
                lc_error := f_create_grupo(p_regla,x.materia, p_pidm);
                if lc_error <> 'EXITO' THEN
                    Rollback;
                    Exit;
                else
                    Commit;
                End if;
            end;
--			pkg_algoritmo.p_track_prono(p_regla,'Procesando materia: '||x.materia||' f_create_grupo return: lc_error:'||lc_error );			
		End LOOP;

	  RETURN lc_error;
End f_create_gpo_semi;


--Create@Frank@Sep22: Asigna Grupo X ejecutivo a un alumno en caso de no contar con él en moodle.
PROCEDURE p_asig_gpox_pidm(p_Regla number, p_pidm number)
IS
BEGIN
Insert into szstume
Select Distinct
--x.szstume_term_nrc nrc_ini,
					xx.szstume_term_nrc nrc_fin
						  ,x.SZSTUME_PIDM
						  ,x.SZSTUME_ID
						  ,sysdate --,SZSTUME_ACTIVITY_DATE
						  ,x.SZSTUME_USER_ID
						  ,'0'--,SZSTUME_STAT_IND
						  ,null--,SZSTUME_OBS
						  ,x.SZSTUME_PWD
						  ,null--,SZSTUME_MDLE_ID
						  ,x.SZSTUME_SEQ_NO
						  ,'RE'--,SZSTUME_RSTS_CODE
						  ,x.SZSTUME_GRDE_CODE_FINAL
						  ,x.SZSTUME_SUBJ_CODE
						  ,x.SZSTUME_LEVL_CODE
						  ,x.SZSTUME_POBI_SEQ_NO
						  ,x.SZSTUME_PTRM
						  ,x.SZSTUME_CAMP_CODE
						  ,x.SZSTUME_CAMP_CODE_COMP
						  ,x.SZSTUME_LEVL_CODE_COMP
						  ,x.SZSTUME_TERM_NRC_COMP
						  ,x.SZSTUME_SUBJ_CODE_COMP
						  ,x.SZSTUME_START_DATE
						  ,x.SZSTUME_NO_REGLA
						  ,x.SZSTUME_SECUENCIA
						  ,x.SZSTUME_NIVE_SEQNO
                          ,0
                          ,null
			from sztgpme
			join szstume x on x.szstume_term_nrc=sztgpme_term_nrc --Alumnos que no tienen GpoX
						and x.szstume_no_regla=sztgpme_no_regla
			join szstume xx on xx.szstume_subj_code=x.szstume_subj_code  --busco gpoX correspondiente a la regla
						and xx.szstume_no_regla=sztgpme_no_regla
						and xx.szstume_term_nrc like '%X'
			join sztprono on sztprono_pidm = x.SZSTUME_PIDM
						and sztprono_no_regla=x.szstume_no_regla
--						and xx.szstume_pidm = sztprono_pidm
						and x.szstume_pidm = sztprono_pidm
			Where sztgpme_no_regla = p_regla
			and x.szstume_pidm = p_pidm
			And Exists(Select 1
				from sztdtec ax
				WHERE SZTDTEC_MOD_TYPE='S'
				And ax.SZTDTEC_TERM_CODE = (select max (ax1.SZTDTEC_TERM_CODE)
											from sztdtec ax1
											Where ax.SZTDTEC_PROGRAM = ax1.SZTDTEC_PROGRAM)
											AND ax.SZTDTEC_PROGRAM = SZTPRONO_PROGRAM)
            --Jpg@Modify:REQ:Agos22 Auto enrolamiento a grupo de estudiantes de programas ejecutivos.
                    And (Exists(Select 1 from TZTPROGM where matricula=sztprono_id
                                and ((SGBSTDN_STYP_CODE in ('N','F')
                                        AND FECHA_INICIO >= TO_DATE('29/08/2022','DD/MM/YYYY')) OR
                                     (SGBSTDN_STYP_CODE in ('C')
                                        AND FECHA_PRIMERA BETWEEN TO_DATE('29/08/2022','DD/MM/YYYY') AND SYSDATE)
                                     )
                                and estatus='MA'
                                And Exists(Select 1 from zstpara where zstpara_mapa_id = 'REGLA_GPO EJEC' and ZSTPARA_PARAM_ID = Campus and ZSTPARA_PARAM_VALOR = Nivel)
                               )
                        )
            and not exists(select 1 from szstume z
                    where x.szstume_no_regla=z.szstume_no_regla
                    and x.szstume_id = z.szstume_id
                    and x.szstume_subj_code = z.szstume_subj_code
                    and z.szstume_term_nrc like '%X');

		dbms_output.put_line('Insert->SZSTUME regla:'||p_regla||
                             ' pidm: '||p_pidm||' CantRegs:'||SQL%RowCount );
    Commit;

EXCEPTION WHEN OTHERS THEN
		dbms_output.put_line('ErrorInsert->SZSTUME: '||SQLERRM);
END p_asig_gpox_pidm;

END PKG_FORMA_MOODLE;
/

DROP PUBLIC SYNONYM PKG_FORMA_MOODLE;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FORMA_MOODLE FOR BANINST1.PKG_FORMA_MOODLE;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_FORMA_MOODLE TO PUBLIC;
