DROP PACKAGE BODY BANINST1.PKG_D_ACADEMICOS;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_d_academicos
is

function reprobadas2(p_pidm number,prog varchar2) return float is

repro number;


begin

repro:=0;

    Begin

     select count(distinct ssbsect_subj_code||ssbsect_crse_numb) into repro
        from tztprog_hist s, sfrstcr a, ssbsect b , shrgrde , smrpaap, smrarul
        where s.pidm=p_pidm
             and s.pidm=sfrstcr_pidm
             and s.programa=prog
             and sfrstcr_rsts_code='RE'
             and s.nivel=SFRSTCR_LEVL_CODE
             and sfrstcr_grde_code=shrgrde_code
             and shrgrde_passed_ind != 'Y'
             and SHRGRDE_LEVL_CODE=SFRSTCR_LEVL_CODE
             and sfrstcr_term_code=ssbsect_term_code
/* cambio escalas para prod */
             and shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                               where zstpara_mapa_id='ESC_SHAGRD'
                                                 and substr((select f_getspridenid(p_pidm) from dual),1,2)=zstpara_param_id
                                                 and zstpara_param_valor=SFRSTCR_LEVL_CODE)
             and sfrstcr_crn=ssbsect_crn
             and s.programa=smrpaap_program
             and s.ctlg=smrpaap_term_code_eff
             and smrarul_area=smrpaap_area
             and smrarul_term_code_eff=smrpaap_term_code_eff
             and smrarul_subj_code=ssbsect_subj_code
             and smrarul_crse_numb_low=ssbsect_crse_numb
             and ((smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                            from  sorlcur cu, sorlfos ss
                                                                                           where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                             and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                             and   cu.sorlcur_pidm=p_pidm
                                                                                             and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                             and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                                             and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                           and ss.sorlcur_program =prog)
                                                                                             and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                             where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                               and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                               and ss.sorlcur_program =prog)
                                                                                             and  cu.SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                             and  cu.sorlcur_program =s.programa
                                                                                           )    )
                   and smrarul_area not in (select smriecc_area from smriecc)) or
                                           (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                    ( select distinct SORLFOS_MAJR_CODE
                                                                        from  sorlcur cu, sorlfos ss
                                                                       where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                         and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                         and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                     where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                       and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                       and ss.sorlcur_program =prog )
                                                                         and   cu.sorlcur_pidm=p_pidm
                                                                         and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                         and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                         and   cu.SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                         and   cu.sorlcur_program   =s.programa
                                                                       ) )) )
             and (sfrstcr_pidm,ssbsect_subj_code,ssbsect_crse_numb) not in (select sfrstcr_pidm,ssbsect_subj_code,ssbsect_crse_numb from sfrstcr c, ssbsect d
                                                     where a.sfrstcr_pidm=c.sfrstcr_pidm
                                                         and c.sfrstcr_rsts_code='RE'
                                                         and c.sfrstcr_grde_code is null
                                                         and c.sfrstcr_term_code=d.ssbsect_term_code
                                                         and c.sfrstcr_crn=d.ssbsect_crn
                                                         and d.ssbsect_subj_code=b.ssbsect_subj_code
                                                         and d.ssbsect_crse_numb=b.ssbsect_crse_numb)
             and (sfrstcr_pidm,ssbsect_subj_code,ssbsect_crse_numb) not in (select sfrstcr_pidm,ssbsect_subj_code,ssbsect_crse_numb from sfrstcr c, ssbsect d,  shrgrde e
                                                     where  a.sfrstcr_pidm=c.sfrstcr_pidm
                                                         and c.sfrstcr_rsts_code='RE'
                                                         and c.sfrstcr_grde_code is not null
                                                         and c.sfrstcr_term_code=d.ssbsect_term_code
                                                         and c.sfrstcr_crn=d.ssbsect_crn
                                                         and d.ssbsect_subj_code=b.ssbsect_subj_code
                                                         and d.ssbsect_crse_numb=b.ssbsect_crse_numb
                                                         and e.SHRGRDE_LEVL_CODE=c.SFRSTCR_LEVL_CODE
                                                         and c.sfrstcr_grde_code=e.shrgrde_code
                                                         and e.shrgrde_passed_ind = 'Y'
                                                         and e.shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                                                           where zstpara_mapa_id='ESC_SHAGRD'
                                                                                             and substr((select f_getspridenid(p_pidm) from dual),1,2)=zstpara_param_id
                                                                                             and zstpara_param_valor=SFRSTCR_LEVL_CODE));

    Exception
        When Others then
            repro:=0;
    End;


return repro;

end reprobadas2;

function e_cur2( pidm1 number, prog varchar2) return varchar2 is

ecur varchar2(2);
nivel  varchar2(2);

begin

ecur:='0';

        Begin

             select   count(*) into ecur
                  from  tztprog_hist w ,smrpaap s , smrarul , smracaa ,sgbstdn x ,sfrstcr, ssbsect,  smrprle
                  where   w.pidm=pidm1 and w.programa=prog
                    and  smrpaap_program= w.programa
                    and  smrpaap_term_code_eff = (select max(smrpaap_term_code_eff) from smrpaap sm
                                                     where s.smrpaap_program=sm.smrpaap_program
                                                      and sm.smrpaap_term_code_eff <= w.ctlg)
                    and  smrpaap_area=smrarul_area
                    and  smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
                    AND  smracaa_area  NOT IN (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES'
                                                  and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                    and  sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                    where x.sgbstdn_pidm=xx.sgbstdn_pidm)
                    and  w.CTLG=SMRARUL_TERM_CODE_EFF
                    and  w.CTLG=SMRACAA_TERM_CODE_EFF
                    and  ((smrarul_area not in (select smriecc_area from smriecc)) or
                        (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
                        (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
                    and  sgbstdn_pidm=sfrstcr_pidm
                    and  w.pidm=sfrstcr_pidm
                    and  (sfrstcr_pidm,sfrstcr_term_code,sfrstcr_crn) not in (select shrtckn_pidm,shrtckn_term_code,shrtckn_crn from shrtckn)
                    and  sfrstcr_rsts_code='RE'
                    and  ssbsect_term_code=sfrstcr_term_code
                    and  ssbsect_crn=sfrstcr_crn
                    and  ssbsect_subj_code=smrarul_subj_code
                    and  ssbsect_crse_numb=smrarul_crse_numb_low
                    and  sfrstcr_stsp_key_sequence=w.sp
                    and  sfrstcr_grde_code IS NULL
                    and  smrprle_program=smrpaap_program;

    Exception
        When Others then
            ecur:=null;
    End;

    return ecur;

end e_cur2;

function total_mate2(pidm number, prog varchar2) return float is

total  number(3);

 begin

          Begin
            select  distinct SMBPGEN_REQ_COURSES_I_TRAD  into total from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMAPROG
             where SMBPGEN_program=prog
               and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                             where  sorlcur_pidm=pidm
                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                     where ss.sorlcur_pidm=pidm
                                                                       and ss.sorlcur_program=prog
                                                                       and ss.sorlcur_lmod_code='LEARNER'
                                                                    )
                                            );
          Exception
           When Others then
            total :=0;
          End;

   return total;

end total_mate2;

procedure alu_porc_avance(pidm number,p_prog varchar2)
      is
      existe number:=0;

    ---esta funcion INCLUYE los talleres de titulacion para conteo de total de materias

  begin

    for c in  (
           with avances1 as (
                                                  SELECT    prog,
                                                            materia,
                                                            pidm,
                                                            pcat,
                                                        --    area,
                                                            tot_materias
                                                        FROM
                                                        (
                                                            SELECT DISTINCT smrpaap_program prog,
                                                                            smrarul_subj_code||smrarul_crse_numb_low materia,
                                                                            c.sorlcur_pidm pidm,
                                                                            c.sorlcur_term_code_ctlg pcat,
                                                                            SMRARUL_AREA area,
                                                                            (SELECT  DISTINCT smbpgen_req_courses_i_trad
                                                                             FROM SMBPGEN
                                                                             where 1 = 1
                                                                             AND smbpgen_program=p_prog
                                                                             and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG
                                                                                                        from sorlcur s
                                                                                                        where  s.sorlcur_pidm=pidm
                                                                                                        and s.sorlcur_program=p_prog
                                                                                                        and s.sorlcur_lmod_code='LEARNER'
                                                                                                        and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO)
                                                                                                                               from sorlcur ss
                                                                                                                               where ss.sorlcur_pidm=pidm
                                                                                                                               and ss.sorlcur_program=p_prog
                                                                                                                               and ss.sorlcur_lmod_code='LEARNER'))) tot_materias
                                                            FROM smrpaap,
                                                                 smrarul,
                                                                 smracaa,
                                                                 sorlcur c,
                                                                 ssbsect,
                                                                 shrgrde,
                                                                 shrtckn,
                                                                 shrtckg,
                                                                 smbagen,
--                                                                 sgbstdn,
                                                                 smbpgen
                                                            WHERE 1 = 1
                                                            AND smrpaap_program=p_prog
                                                            AND smrpaap_program=sorlcur_program
                                                            AND smrpaap_term_code_eff=smrarul_term_code_eff
                                                            AND smrpaap_area=smrarul_area
                                                            AND smrarul_term_code_eff=smrpaap_term_code_eff
                                                            AND smracaa_area=smrarul_area
                                                            AND smracaa_rule=smrarul_key_rule
                                                            AND smrpaap_area=smbagen_area
                                                            AND smbagen_active_ind='Y'
                                                            AND smrpaap_term_code_eff=smbagen_term_code_eff
                                                            AND c.sorlcur_pidm=pidm
--                                                            AND c.sorlcur_pidm=sgbstdn_pidm
                                                            AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
                                                            AND c.sorlcur_lmod_code = 'LEARNER'
                                                            AND c.sorlcur_seqno IN (SELECT MAX(sorlcur_seqno)
                                                                                    FROM sorlcur ss
                                                                                    WHERE  ss.sorlcur_pidm=c.sorlcur_pidm
                                                                                    AND ss.sorlcur_program=c.sorlcur_program
                                                                                    AND ss.sorlcur_lmod_code='LEARNER'
                                                                                    )
                                                            AND smrpaap_program=c.sorlcur_program
                                                            AND c.sorlcur_seqno = (SELECT MAX (c1x.sorlcur_seqno)
                                                                                   FROM sorlcur c1x
                                                                                   WHERE  c.sorlcur_pidm = c1x.sorlcur_pidm
                                                                                   AND  c.sorlcur_lmod_code= c1x.sorlcur_lmod_code
                                                                                   AND c.sorlcur_roll_ind     = c1x.sorlcur_roll_ind
                                                                                   AND c.sorlcur_cact_code = c1x.sorlcur_cact_code
                                                                                   AND c.sorlcur_program=c1x.sorlcur_program)
                                                            AND c.sorlcur_program=smrpaap_program
                                                            AND smrpaap_term_code_eff=  (SELECT DISTINCT MIN(sorlcur_term_code_ctlg)
                                                                                         FROM sorlcur ii
                                                                                         WHERE  1 = 1
                                                                                         AND ii.sorlcur_pidm= c.sorlcur_pidm
                                                                                         AND ii.sorlcur_pidm=c.sorlcur_pidm
                                                                                         AND ii.SORLCUR_LMOD_CODE=c.sorlcur_lmod_code
                                                                                         AND ii.sorlcur_seqno=c.sorlcur_seqno
                                                                                         )
                                                            and ((smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                 (smrarul_area in (select smriemj_area from smriemj
                                                                                    where smriemj_majr_code=(select distinct SORLFOS_MAJR_CODE
                                                                                                               from sorlcur cu, sorlfos ss
                                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                and cu.sorlcur_pidm=pidm
                                                                                                                and SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                and SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                            and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                            and ss.sorlcur_program =p_prog
                                                                                                                                        )
                                                                                                                and cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                              where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                            )
                                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                and  sorlcur_program=p_prog
                                                                                                             )
                                                                                 )
                                                                   and smrarul_area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                        (smrarul_area in (select smriecc_area from smriecc
                                                                                           where smriecc_majr_code_conc in
                                                                                                    ( select distinct SORLFOS_MAJR_CODE
                                                                                                        from  sorlcur cu, sorlfos ss
                                                                                                       where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                         and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                         ---------
                                                                                                         and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                     where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                       and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                       and ss.sorlcur_program =p_prog )
                                                                                                                                ---------
                                                                                                         and   cu.sorlcur_pidm=pidm
                                                                                                         and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                         and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                         and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                         and   sorlcur_program   =p_prog
                                                                                                     )
                                                                                         )
                                                                       )
                                                             )
                                                            AND smrarul_subj_code||smrarul_crse_numb_low=ssbsect_subj_code || ssbsect_crse_numb
                                                            AND ssbsect_crn=shrtckn_crn
                                                            AND ssbsect_term_code=shrtckn_term_code
                                                            AND shrtckn_pidm = c.sorlcur_pidm
                                                            AND shrtckn_pidm = shrtckg_pidm
                                                            AND shrtckn_term_code = shrtckg_term_code
                                                            AND shrtckn_stsp_key_sequence=sorlcur_key_seqno
                                                            AND shrtckn_seq_no = shrtckg_tckn_seq_no
                                                            AND shrtckg_grde_code_final =  shrgrde_code
--                                                            AND shrgrde_code not in 'AC'
                                                            AND shrtckn_subj_code||shrtckn_crse_numb not in (SELECT zstpara_param_valor
                                                                                                               FROM zstpara
                                                                                                              WHERE zstpara_mapa_id='NOVER_MAT_DASHB'
                                                                                                                AND shrtckn_pidm in (SELECT spriden_pidm
                                                                                                                                       FROM spriden
                                                                                                                                      WHERE spriden_id=zstpara_param_id
                                                                                                                                    )
                                                                                                            )
                                                            AND c.sorlcur_levl_code = shrgrde_levl_code
                                                            AND shrgrde_passed_ind = 'Y'
  /* cambio escalas para prod */                            AND shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                                                               where zstpara_mapa_id='ESC_SHAGRD'
                                                                                                 and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id
                                                                                                 and zstpara_param_valor=SORLCUR_LEVL_CODE)
                                                        )x
                                                        WHERE 1 = 1
                                                        AND tot_materias >= 42
                                                        AND area  NOT IN  (SELECT zstpara_param_valor
                                                                                  FROM zstpara
                                                                                  WHERE zstpara_mapa_id='ORDEN_CUATRIMES'
                                                                                  AND  substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT'
                                                                                  )
                                                        UNION
                                                        SELECT
                                                            prog,
                                                            materia,
                                                            pidm,
                                                            pcat,
                                                          --  area,
                                                            tot_materias
                                                        FROM
                                                        (
                                                        SELECT DISTINCT smrpaap_program prog,
                                                                        smrarul_subj_code||smrarul_crse_numb_low materia,
                                                                        c.sorlcur_pidm pidm,
                                                                        c.sorlcur_term_code_ctlg pcat,
                                                                        SMRARUL_AREA area,
                                                                        (SELECT  DISTINCT smbpgen_req_courses_i_trad
                                                                           FROM SMBPGEN
                                                                          where 1 = 1
                                                                            AND smbpgen_program=p_prog
                                                                            and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG
                                                                                                        from sorlcur s
                                                                                                        where s.sorlcur_pidm=pidm
                                                                                                          and s.sorlcur_program=p_prog
                                                                                                          and s.sorlcur_lmod_code='LEARNER'
                                                                                                          and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO)
                                                                                                                                   from sorlcur ss
                                                                                                                                  where ss.sorlcur_pidm=pidm
                                                                                                                                    and ss.sorlcur_program=p_prog
                                                                                                                                    and ss.sorlcur_lmod_code='LEARNER')
                                                                                                    )
                                                                        ) tot_materias
                                                        FROM smrpaap,
                                                             smrarul,
                                                             smracaa,
                                                             sorlcur c,
                                                             ssbsect,
                                                             shrgrde,
                                                             shrtckn,
                                                             shrtckg,
                                                             smbagen,
--                                                             sgbstdn,
                                                             smbpgen
                                                        WHERE 1 = 1
                                                        AND smrpaap_program=p_prog
                                                        AND smrpaap_program=sorlcur_program
                                                        AND smrpaap_term_code_eff=smrarul_term_code_eff
                                                        AND smrpaap_area=smrarul_area
                                                        AND smrarul_term_code_eff=smrpaap_term_code_eff
                                                        AND smracaa_area=smrarul_area
                                                        AND smracaa_rule=smrarul_key_rule
                                                        AND smrpaap_area=smbagen_area
                                                        AND smbagen_active_ind='Y'
                                                        AND smrpaap_term_code_eff=smbagen_term_code_eff
                                                        AND c.sorlcur_pidm=pidm
--                                                        AND c.sorlcur_pidm=sgbstdn_pidm
                                                        AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
                                                        AND c.sorlcur_lmod_code = 'LEARNER'
                                                        AND c.sorlcur_seqno IN (SELECT MAX(sorlcur_seqno)
                                                                                FROM sorlcur ss
                                                                                WHERE  ss.sorlcur_pidm=c.sorlcur_pidm
                                                                                AND ss.sorlcur_program=c.sorlcur_program
                                                                                AND ss.sorlcur_lmod_code='LEARNER'
                                                                                )
                                                        AND smrpaap_program=c.sorlcur_program
                                                        AND c.sorlcur_seqno = (SELECT MAX (c1x.sorlcur_seqno)
                                                                               FROM sorlcur c1x
                                                                               WHERE  c.sorlcur_pidm = c1x.sorlcur_pidm
                                                                               AND  c.sorlcur_lmod_code= c1x.sorlcur_lmod_code
                                                                               AND c.sorlcur_roll_ind     = c1x.sorlcur_roll_ind
                                                                               AND c.sorlcur_cact_code = c1x.sorlcur_cact_code
                                                                               AND c.sorlcur_program=c1x.sorlcur_program)
                                                        AND c.sorlcur_program=smrpaap_program
                                                        AND smrpaap_term_code_eff=  (SELECT DISTINCT MIN(sorlcur_term_code_ctlg)
                                                                                     FROM sorlcur ii
                                                                                     WHERE  1 = 1
                                                                                     AND ii.sorlcur_pidm= c.sorlcur_pidm
                                                                                     AND ii.sorlcur_pidm=c.sorlcur_pidm
                                                                                     AND ii.SORLCUR_LMOD_CODE=c.sorlcur_lmod_code
                                                                                     AND ii.sorlcur_seqno=c.sorlcur_seqno
                                                                                     )
--                                                        AND  ( (smrarul_area not in (select smriecc_area from smriecc)) or
--                                                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
--                                                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
                                                         and ((smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                 (smrarul_area in (select smriemj_area from smriemj
                                                                                    where smriemj_majr_code=(select distinct SORLFOS_MAJR_CODE
                                                                                                               from sorlcur cu, sorlfos ss
                                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                and cu.sorlcur_pidm=pidm
                                                                                                                and SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                and SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                            and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                            and ss.sorlcur_program =p_prog
                                                                                                                                        )
                                                                                                                and cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                              where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                            )
                                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                and  sorlcur_program=p_prog
                                                                                                             )
                                                                                 )
                                                                   and smrarul_area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                        (smrarul_area in (select smriecc_area from smriecc
                                                                                           where smriecc_majr_code_conc in
                                                                                                    ( select distinct SORLFOS_MAJR_CODE
                                                                                                        from  sorlcur cu, sorlfos ss
                                                                                                       where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                         and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                         ---------
                                                                                                         and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                     where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                       and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                       and ss.sorlcur_program =p_prog )
                                                                                                                                ---------
                                                                                                         and   cu.sorlcur_pidm=pidm
                                                                                                         and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                         and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                         and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                         and   sorlcur_program   =p_prog
                                                                                                     )
                                                                                         )
                                                                       )
                                                             )
                                                        AND smrarul_subj_code||smrarul_crse_numb_low=ssbsect_subj_code || ssbsect_crse_numb
                                                        AND ssbsect_crn=shrtckn_crn
                                                        AND ssbsect_term_code=shrtckn_term_code
                                                        AND shrtckn_pidm = c.sorlcur_pidm
                                                        AND shrtckn_pidm = shrtckg_pidm
                                                        AND shrtckn_term_code = shrtckg_term_code
                                                        AND shrtckn_stsp_key_sequence=sorlcur_key_seqno
                                                        AND shrtckn_seq_no = shrtckg_tckn_seq_no
                                                        AND shrtckg_grde_code_final =  shrgrde_code
--                                                        AND shrgrde_code not in 'AC'
                                                        AND shrtckn_subj_code||shrtckn_crse_numb not in (SELECT zstpara_param_valor
                                                                                                         FROM zstpara
                                                                                                         WHERE zstpara_mapa_id='NOVER_MAT_DASHB'
                                                                                                         AND shrtckn_pidm in (SELECT spriden_pidm
                                                                                                                               FROM spriden
                                                                                                                              WHERE spriden_id=zstpara_param_id
                                                                                                                             )
                                                                                                          )
                                                        AND c.sorlcur_levl_code = shrgrde_levl_code
                                                        AND shrgrde_passed_ind = 'Y'
/* cambio escalas para prod */                          AND shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                                                               where zstpara_mapa_id='ESC_SHAGRD'
                                                                                                 and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id
                                                                                                 and zstpara_param_valor=SORLCUR_LEVL_CODE)
                                                        )x
                                                        WHERE 1 = 1
                                                        AND tot_materias <= 40
                                                        AND area  NOT IN  (SELECT ZSTPARA_PARAM_VALOR
                                                                           FROM ZSTPARA
                                                                           WHERE ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                    ),
                                avances2 as (
                                                      select DISTINCT SMRPAAP_PROGRAM PROG,
                                                                              SMRPAAP_AREA AREA,
                                                                              SMRALIB_AREA_DESC DES,
                                                                              SMRPAAP_AREA_PRIORITY PRIO,
                                                                              SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW MATERIA,
                                                                              SHRTRCE_GRDE_CODE  CAL_HIST,
                                                                              d.SORLCUR_pidm pidm,
                                                                              d.SORLCUR_TERM_CODE_CTLG PCAT
                                                              from SMRPAAP,SMRALIB,SMRARUL,SORLCUR d,SHRGRDE,SHRTRCE,SHRTRCR,smbagen --,sgbstdn
                                                              where SMRPAAP_PROGRAM=p_prog
                                                                and SMRPAAP_AREA=SMRALIB_AREA
                                                                AND SMRPAAP_AREA=SMRARUL_AREA
                                                                and  smrpaap_area=SMBAGEN_AREA
                                                                and  SMBAGEN_ACTIVE_IND='Y'
                                                                and  SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                                                AND SMRARUL_AREA NOT IN   (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                            where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES'
                                                                                              and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT'
                                                                                          )
                                                                AND d.SORLCUR_PIDM=pidm
--                                                                AND d.SORLCUR_PIDM=sgbstdn_pidm
                                                                AND d.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                and d.SORLCUR_SEQNO in (select max(sorlcur_seqno) from sorlcur ss
                                                                                         where  ss.sorlcur_pidm=d.sorlcur_pidm
                                                                                           and ss.sorlcur_program=d.sorlcur_program
                                                                                           and ss.sorlcur_lmod_code='LEARNER'
                                                                                        )
                                                                and SMRPAAP_PROGRAM=SORLCUR_PROGRAM
                                                                and  (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or  -- VALIDA LA EXITENCIA EN SMAALIB
                                                                         (smrarul_area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                        from  sorlcur cu, sorlfos ss
                                                                                                                       where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                         and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                         and   cu.sorlcur_pidm=pidm
                                                                                                                         and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                         and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                         and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                     where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                       and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                       and ss.sorlcur_program =p_prog )
                                                                                                                         and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code)
                                                                                                                         and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                         and   sorlcur_program   =p_prog
                                                                                                                       )
                                                                                             )
                                                                       and smrarul_area not in (select smriecc_area from smriecc)) or    -- VALIDA LA EXITENCIA EN SMAALIB
                                                                             (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =p_prog
                                                                                                                              )
                                                                                                 )
                                                                              )
                                                                    )
                                                              and SMRPAAP_TERM_CODE_EFF=  (select distinct min(SORLCUR_TERM_CODE_CTLG) from sorlcur jj
                                                                                            where jj.sorlcur_pidm= d.SORLCUR_PIDM
                                                                                              and jj.sorlcur_pidm=d.sorlcur_pidm
                                                                                              and jj.SORLCUR_LMOD_CODE=d.sorlcur_lmod_code
                                                                                              and jj.sorlcur_seqno=d.sorlcur_seqno
                                                                                           )
                                                              AND SHRTRCE_pidm = d.sorlcur_pidm
                                                              AND d.SORLCUR_PROGRAM=SMRPAAP_PROGRAM
                                                              AND SHRTRCE_pidm = d.sorlcur_pidm
                                                              AND SHRTRCE_TERM_CODE_EFF = SHRTRCR_TERM_CODE
                                                              AND SHRTRCE_pidm = SHRTRCR_PIDM
                                                              AND SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW=SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB
                                                              and SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                                                where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                  and SHRTRCE_pidm in (select spriden_pidm from spriden
                                                                                                                                        where spriden_id=ZSTPARA_PARAM_ID)
                                                                                                               )
                                                              AND SHRTRCE_GRDE_CODE =  SHRGRDE_CODE
                                                              AND SHRTRCE_LEVL_CODE = SHRGRDE_LEVL_CODE
                                                              AND SHRGRDE_PASSED_IND = 'Y'
/* cambio escalas para prod */                                AND shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                                                               where zstpara_mapa_id='ESC_SHAGRD'
                                                                                                 and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id
                                                                                                 and zstpara_param_valor=SORLCUR_LEVL_CODE)
                                                              AND SHRTRCE_TRCR_SEQ_NO=SHRTRCR_SEQ_NO
                                             ),
                      aproba1 as (
                                   select avances1.pidm, avances1.PCAT cat, count(*) aprobadas1 from avances1
                                   group by  avances1.pidm,avances1.PCAT
                                  ),
                      aproba2 as (
                                   select avances2.pidm, avances2.PCAT cat, count(*) aprobadas2 from avances2
                                   group by  avances2.pidm,avances2.PCAT
                                 ),
                      aprobadas as (
                                     select aproba1.pidm pidm1,aproba2.pidm pidm2,aproba1.cat pcat,
                                        nvl(aproba1.aprobadas1,0)+nvl(aproba2.aprobadas2,0)  tot_aprob
                                       from aproba1,aproba2
                                      where aproba1.pidm=aproba2.pidm(+)
                                    )
                            select  distinct aprobadas.pidm1 pidm, p_prog  prog,
                                   case when
                                       (nvl(tot_aprob,0)*100/nvl((SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
                                                                                           WHERE SMBPGEN_PROGRAM=p_prog
                                                                                              AND SMBPGEN_TERM_CODE_EFF= aprobadas.pcat),0))>100 then 100
                                    else
                                      round((nvl(tot_aprob,0)*100/nvl((SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
                                                                                           WHERE SMBPGEN_PROGRAM=p_prog
                                                                                              AND SMBPGEN_TERM_CODE_EFF= aprobadas.pcat),0)),2)
                                    end  p_avance,
                                   case when (aprobadas.tot_aprob) >(SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN WHERE SMBPGEN_PROGRAM=p_prog AND SMBPGEN_TERM_CODE_EFF= aprobadas.pcat)
                                          then (SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN WHERE SMBPGEN_PROGRAM=p_prog AND SMBPGEN_TERM_CODE_EFF= aprobadas.pcat)
                                   ELSE
                                       aprobadas.tot_aprob
                                   end mat_aprob,
                                   (SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
                                     WHERE SMBPGEN_PROGRAM=p_prog
                                       AND SMBPGEN_TERM_CODE_EFF= aprobadas.pcat
                                    ) tot_matxprog,
                                   aprobadas.pcat pcat
                                from aprobadas

        ) loop

                                 begin
                                    UPDATE SATURN.SZTHITA
                                      SET SZTHITA_AVANCE=round(c.p_avance,2),
                                              SZTHITA_APROB=c.mat_aprob
                                           where SZTHITA_PIDM=c.pidm
                                           and SZTHITA_PROG=c.prog
                                           and SZTHITA_PER_CATALOGO=c.pcat;
                                      commit;
                                 EXCEPTION
                                        WHEN OTHERS THEN
                                         DBMS_OUTPUT.PUT_LINE('Error al actualizar Avance del alumno '||sqlerrm);
                                 end;
       End loop;
   end;

procedure promedio( pidm number, prog varchar2) is

prom   decimal(6,3);
p_ord  number:=0;
c_ord  number:=0;
p_equi number:=0;
c_equi number:=0;
p_ec   number:=0;
c_ec   number:=0;
nivel  varchar2(2);

begin
          select smrprle_levl_code into nivel
            from smrprle
           where smrprle_program=prog;


           if nivel not in ('MA','MS','DO') then
              select  nvl(sum(puntos),0) , count(*)
               into p_ord, c_ord
              from (
               select   distinct SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL) calificacion , nvl(sum(shrgrde_quality_points),0)  puntos ,smracaa_area
                from smrpaap s, smrarul, smracaa,shrtckg b, shrtckn a, shrgrde c, sorlcur w, smrprle d, sgbstdn x,smbagen
               where sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                        where w.sorlcur_pidm=ww.sorlcur_pidm
                                        and w.sorlcur_program=ww.sorlcur_program
                                        and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)
                and smrpaap_program= sorlcur_program
                and smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                where s.smrpaap_program=sm.smrpaap_program
                                                  and sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
                and     smrpaap_area=smrarul_area
                and     smrpaap_area=SMBAGEN_AREA
                and     SMBAGEN_TERM_CODE_EFF=SORLCUR_TERM_CODE_CTLG
                and     SMBAGEN_ACTIVE_IND='Y'
                and     smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                and     a.shrtckn_pidm=sorlcur_pidm
                and     a.shrtckn_subj_code=smrarul_subj_code
                and     a.shrtckn_crse_numb=smrarul_crse_numb_low
                and     a.shrtckn_stsp_key_sequence=sorlcur_key_seqno
                and     b.shrtckg_pidm=a.shrtckn_pidm
                and     TO_NUMBER (decode (trim (b.shrtckg_grde_code_final)
                                       /*, 'AC',1*/,'NA',1,'NP',1
                                      ,'10',10,'10.0',10,'100',10
                                      ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                      ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                      ,'6.0',6,'6',6,'6.1',6,'61',6,'6.2',6,'6.3',6,'63',6,'6.5',6,'65',6,'6.6',6,'6.7',6,'6.8',6,'6.9',6
                                      ,'7.0',7,'7',7,'7.1',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'7.7',7,'77',7,'7.8',7,'7.9',7
                                      ,'8.0',8,'8',8,'80',8,'8.1',8,'8.2',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                     ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9
                                    )) =
                                    (select max (TO_NUMBER (decode (trim(yy1.shrtckg_grde_code_final)
                                      /*,'AC',1*/,'NA',1,'NP',1
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
                and     b.shrtckg_tckn_seq_no=a.shrtckn_seq_no   and b.shrtckg_term_code=a.shrtckn_term_code
                and     b.shrtckg_grde_code_final=c.shrgrde_code
                and     b.shrtckg_seq_no=(select max(shrtckg_seq_no) from shrtckg c
                                                              where b.SHRTCKG_PIDM=c.SHRTCKG_PIDM
                                                               and b.SHRTCKG_TERM_CODE=c.SHRTCKG_TERM_CODE
                                                               and b.shrtckg_tckn_seq_no=c.shrtckg_tckn_seq_no)
                and     (b.shrtckg_final_grde_chg_date,SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB) in (select max(dd.shrtckg_final_grde_chg_date),ee.SHRTCKN_SUBJ_CODE||ee.SHRTCKN_CRSE_NUMB
                                                                    from shrtckg dd , shrtckn ee
                                                                          where  b.shrtckg_grde_code_final=dd.shrtckg_grde_code_final
                                                                          and    b.shrtckg_pidm= dd.shrtckg_pidm
                                                                          and  dd.shrtckg_pidm=ee.shrtckn_pidm
                                                                          and dd.shrtckg_term_code=ee.shrtckn_term_code
                                                                          and dd.SHRTCKG_TCKN_SEQ_NO =ee.SHRTCKN_SEQ_NO
                                                                          group by ee.SHRTCKN_SUBJ_CODE||ee.SHRTCKN_CRSE_NUMB )
                and    SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                    where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                      and sorlcur_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                and    SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_ID from zstpara
                                                                     where  ZSTPARA_MAPA_ID='TALLER_HIAC'
                                                                       and SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB=ZSTPARA_PARAM_ID)
                and     d.smrprle_program=smrpaap_program
                and     c.shrgrde_levl_code=d.smrprle_levl_code
                and     c.shrgrde_passed_ind='Y'
                /* cambio escalas para prod */
--                and     c. shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
--                                                         where zstpara_mapa_id='ESC_SHAGRD'
--                                                           and substr((select f_getspridenid(sorlcur_pidm) from dual),1,2)=zstpara_param_id
--                                                           and zstpara_param_valor=SORLCUR_LEVL_CODE)
                and     sgbstdn_pidm=a.shrtckn_pidm
                and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                                and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
                and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
                            (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
                            (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
                            group by a.SHRTCKN_PIDM,
                                a.SHRTCKN_SUBJ_CODE,
                                a.SHRTCKN_CRSE_NUMB ,
                                a.SHRTCKN_STSP_KEY_SEQUENCE,
                                smracaa_area
                order by 2
               );
        else
                  select     nvl(sum(puntos),0) , count(*)
                       into p_ord, c_ord
                  from (
                   select   distinct SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL) calificacion , nvl(sum(shrgrde_quality_points),0)  puntos ,smracaa_area
                     from  smrpaap s, smrarul, smracaa,shrtckg b, shrtckn a, shrgrde c, sorlcur w, smrprle d, sgbstdn x
                    where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                                  where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code) -- and sorlcur_roll_ind='Y'
                      and       smrpaap_program= sorlcur_program
                      and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                           where s.smrpaap_program=sm.smrpaap_program
                                                             and sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
                      and      smrpaap_area=smrarul_area
                      and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                      and     a.shrtckn_pidm=sorlcur_pidm
                      and     a.shrtckn_subj_code=smrarul_subj_code
                      and     a.shrtckn_crse_numb=smrarul_crse_numb_low
                      and     a.shrtckn_stsp_key_sequence=sorlcur_key_seqno
                      and     b.shrtckg_pidm=a.shrtckn_pidm
                      and    TO_NUMBER (decode (trim (b.shrtckg_grde_code_final)
                                      /*, 'AC',1*/,'NA',1,'NP',1
                                      ,'10',10,'10.0',10,'100',10
                                      ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                      ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                      ,'6.0',6,'6',6,'6.1',6,'61',6,'6.2',6,'6.3',6,'63',6,'6.5',6,'65',6,'6.6',6,'6.7',6,'6.8',6,'6.9',6
                                      ,'7.0',7,'7',7,'7.1',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'7.7',7,'77',7,'7.8',7,'7.9',7
                                      ,'8.0',8,'8',8,'80',8,'8.1',8,'8.2',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                     ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9
                                    )) =
                                    (select max (TO_NUMBER (decode (trim(yy1.shrtckg_grde_code_final)
                                    /*, 'AC',1*/,'NA',1,'NP',1
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
                     and     b.shrtckg_tckn_seq_no=a.shrtckn_seq_no   and b.shrtckg_term_code=a.shrtckn_term_code
                     and     b.shrtckg_grde_code_final=c.shrgrde_code
                     and     b.shrtckg_seq_no=(select max(shrtckg_seq_no) from shrtckg c
                                                              where b.SHRTCKG_PIDM=c.SHRTCKG_PIDM
                                                               and b.SHRTCKG_TERM_CODE=c.SHRTCKG_TERM_CODE
                                                               and b.shrtckg_tckn_seq_no=c.shrtckg_tckn_seq_no)
                     and     (b.shrtckg_final_grde_chg_date,SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB) in (select max(dd.shrtckg_final_grde_chg_date),ee.SHRTCKN_SUBJ_CODE||ee.SHRTCKN_CRSE_NUMB
                                                                    from shrtckg dd , shrtckn ee
                                                                          where  b.shrtckg_grde_code_final=dd.shrtckg_grde_code_final
                                                                          and b.shrtckg_pidm= dd.shrtckg_pidm
                                                                          and dd.shrtckg_pidm=ee.shrtckn_pidm
                                                                          and dd.shrtckg_term_code=ee.shrtckn_term_code
                                                                          and dd.SHRTCKG_TCKN_SEQ_NO =ee.SHRTCKN_SEQ_NO
                                                                          group by ee.SHRTCKN_SUBJ_CODE||ee.SHRTCKN_CRSE_NUMB )
                     and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_ID from zstpara
                                                                         where ZSTPARA_MAPA_ID='TALLER_HIAC'
                                                                           and SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB=ZSTPARA_PARAM_ID)
                     and     smrprle_program=smrpaap_program
                     and     c.shrgrde_levl_code=smrprle_levl_code
                     and     c.shrgrde_passed_ind='Y'
                /* cambio escalas para prod */
                     and     c. shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                              where zstpara_mapa_id='ESC_SHAGRD'
                                                                and substr((select f_getspridenid(sorlcur_pidm) from dual),1,2)=zstpara_param_id
                                                                and zstpara_param_valor=SORLCUR_LEVL_CODE)
                     and     sgbstdn_pidm=a.shrtckn_pidm
                     and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                    where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                                    and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
                               group by a.SHRTCKN_PIDM,
                                    a.SHRTCKN_SUBJ_CODE,
                                    a.SHRTCKN_CRSE_NUMB ,
                                    a.SHRTCKN_STSP_KEY_SEQUENCE,
                                    smracaa_area
                   order by 2
                   );

        end if;

         if nivel not in ('MA','MS','DO') then
          select   nvl(sum(shrgrde_quality_points),0) , count(*)
           into p_equi, c_equi
            from  smrpaap s, smrarul, smracaa, shrtrce, shrtrcr, shrgrde, sorlcur w, smrprle, sgbstdn x
           where  sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
             and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                     where w.sorlcur_pidm=ww.sorlcur_pidm
                                       and w.sorlcur_program=ww.sorlcur_program
                                       and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)
             and smrpaap_program= sorlcur_program
             and smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                            where s.smrpaap_program=sm.smrpaap_program
                                              and sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
             and     smrpaap_area=smrarul_area
             and     smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
             and     shrtrce_pidm=sorlcur_pidm
             and     shrtrce_subj_code=smrarul_subj_code
             and     shrtrce_crse_numb=smrarul_crse_numb_low
             and     shrtrce_pidm=shrtrcr_pidm
             and     shrtrce_trit_seq_no=shrtrcr_trit_seq_no
             and     shrtrce_tram_seq_no=shrtrcr_tram_seq_no
             and     shrtrce_trcr_seq_no=shrtrcr_seq_no
             and     shrtrcr_program=smrpaap_program
             and     shrtrce_grde_code=shrgrde_code
             and     shrtrce_grde_code!='AC'
             and     smrprle_program=smrpaap_program
             and     shrgrde_levl_code=smrprle_levl_code
             and     shrgrde_passed_ind='Y'
                /* cambio escalas para prod */
--             and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
--                                                      where zstpara_mapa_id='ESC_SHAGRD'
--                                                        and substr((select f_getspridenid(sorlcur_pidm) from dual),1,2)=zstpara_param_id
--                                                        and zstpara_param_valor=SORLCUR_LEVL_CODE)
             and     sgbstdn_pidm=shrtrce_pidm
             and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                  and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
             and    (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                     (smrarul_area in (select smriemj_area from smriemj
                                        where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                     from sorlcur cu, sorlfos ss
                                                                    where cu.sorlcur_pidm  = Ss.SORLfos_PIDM
                                                                      and cu.SORLCUR_SEQNO = ss.SORLFOS_LCUR_SEQNO
                                                                      and cu.sorlcur_pidm  = pidm
                                                                      and cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                      and SORLFOS_LFST_CODE = 'MAJOR'--CONCENTRATION
                                                                      and cu.SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                      and cu.sorlcur_program   =prog
                                                                      and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur si
                                                                                                where cu.SORLCUR_PIDM=si.sorlcur_pidm
                                                                                                  and cu.sorlcur_lmod_code=si.sorlcur_lmod_code
                                                                                                  and si.sorlcur_program =prog)
                                                                    )
                                       )
                                       and smrarul_area not in (select smriecc_area from smriecc)) or
                                       (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                               ( select distinct SORLFOS_MAJR_CODE
                                                                   from  sorlcur cu, sorlfos ss
                                                                  where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                    and  cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                    and  cu.sorlcur_pidm =pidm
                                                                    and  cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                    and  SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                    and  cu.sorlcur_program   =prog
                                                                    and  cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur si
                                                                                                where cu.SORLCUR_PIDM=si.sorlcur_pidm
                                                                                                  and cu.sorlcur_lmod_code=si.sorlcur_lmod_code
                                                                                                  and si.sorlcur_program =prog)
                                                                 )
                                                         )
                                       )
                  )
           order by substr(smrarul_area,9,2);
       else
          select   nvl(sum(shrgrde_quality_points),0) , count(*) into p_equi, c_equi
            from  smrpaap s, smrarul, smracaa, shrtrce, shrtrcr, shrgrde, sorlcur w, smrprle, sgbstdn x
           where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
             and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                     where w.sorlcur_pidm=ww.sorlcur_pidm
                                       and w.sorlcur_program=ww.sorlcur_program
                                       and w.sorlcur_lmod_code=ww.sorlcur_lmod_code
                                  )
             and smrpaap_program= sorlcur_program
             and smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                            where s.smrpaap_program=sm.smrpaap_program
                                              and sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
             and     smrpaap_area=smrarul_area
             and     smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
             and     shrtrce_pidm=sorlcur_pidm
             and     shrtrce_subj_code=smrarul_subj_code
             and     shrtrce_crse_numb=smrarul_crse_numb_low
             and     shrtrce_pidm=shrtrcr_pidm
             and     shrtrce_trit_seq_no=shrtrcr_trit_seq_no
             and     shrtrce_tram_seq_no=shrtrcr_tram_seq_no
             and     shrtrce_trcr_seq_no=shrtrcr_seq_no
             and     shrtrcr_program=smrpaap_program
             and     shrtrce_grde_code=shrgrde_code
             and     shrtrce_grde_code!='AC'
             and     smrprle_program=smrpaap_program
             and     shrgrde_levl_code=smrprle_levl_code
             and     shrgrde_passed_ind='Y'
--                /* cambio escalas para prod */
             and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                      where zstpara_mapa_id='ESC_SHAGRD'
                                                        and substr((select f_getspridenid(sorlcur_pidm) from dual),1,2)=zstpara_param_id
                                                        and zstpara_param_valor=SORLCUR_LEVL_CODE)
             and     sgbstdn_pidm=shrtrce_pidm
             and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                  and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
             order by substr(smrarul_area,9,2);
       end if;

       if (p_ord+p_equi) > 0 and (c_ord+c_equi) > 0 then
          prom:=round((p_ord+p_equi)/(c_ord+c_equi),3);
       else
         prom:=0;
       end if;

       if prom>10 then
          prom:=10.0;
       end if;

--       DBMS_OUTPUT.PUT_LINE('Promedio resultante antes '||prom);

       begin

         select
                case when length(prom)>=5 then
                   substr(prom,1,(length(prom)-1))
                  when length(prom) between 1 and 4 then
                      to_char(round((p_ord+p_equi)/(c_ord+c_equi),2))
                  when prom=0 then
                    to_char(0)
                end into prom
           from dual;

--          DBMS_OUTPUT.PUT_LINE('Promedio resultante '||prom);

          UPDATE SATURN.SZTHITA
           SET SZTHITA_PROMEDIO=prom
          where SZTHITA_PIDM=pidm
           and SZTHITA_PROG=prog;
         commit;
       EXCEPTION
        WHEN OTHERS THEN
        NULL;
       end;

end promedio;

Procedure alimenta_datos_Hist_Academica is

    existe         number:=0;
    tot            number:=0;
    ecur           number:=0;
    apro           number:=0;
    xcur           number:=0;

    BEGIN


          for c in (
                               select distinct PIDM,
                                               MATRICULA,
                                               replace(SPRIDEN_LAST_NAME,'/',' ') || ' ' || SPRIDEN_FIRST_NAME as Nombre,
                                               CAMPUS,
                                               NIVEL,
                                               PROGRAMA,
                                               SZTDTEC_PROGRAMA_COMP Nombre_Programa,
                                               ESTATUS_D,
                                               SP,
                                               CTLG,
                                               null Mayor,
                                               TIPO_INGRESO Descripcion_Mayor,
                                               null Salida1,
                                               TIPO_INGRESO_DESC Descripcion_Salida1,
                                               null Salida2,
                                               SGBSTDN_STYP_CODE Descripcion_Salida2
                             from tztprog_hist
                                join SPRIDEN on SPRIDEN_PIDM = PIDM AND  SPRIDEN_CHANGE_IND IS NULL
                                join sztdtec on sztdtec_program=programa and SZTDTEC_CAMP_CODE=CAMPUS and SZTDTEC_TERM_CODE=CTLG
                                where 1=1
--                                  AND PIDM=264
            ) loop

                            Begin
                             select count(*) into existe from SATURN.SZTHITA
                               where SZTHITA_PIDM=c.pidm
                                 and SZTHITA_CAMP=c.campus
                                 and SZTHITA_LEVL=c.nivel
                                 and SZTHITA_PROG=c.programa;
                            Exception
                              When Others then
                                existe :=0;
                            End;

                             if existe=0 then
                                             begin
                                                Insert into SATURN.SZTHITA values
                                                      (c.pidm,
                                                       c.Matricula,
                                                       c.Nombre,
                                                       c.campus,
                                                       c.nivel,
                                                       c.Programa,
                                                       c.Nombre_Programa,
                                                       c.ESTATUS_D,
                                                       '0', --Aprobadas
                                                       '0', --Reprobadas
                                                       '0', --En_Curso
                                                       '0', --Por_Cursar
                                                       '0', --Total
                                                        0, --avances
                                                       '0', --promedio
                                                       c.SP,
                                                       c.CTLG,
                                                       c.mayor,
                                                       c.Salida1,
                                                       c.Salida2,
                                                       c.Descripcion_Mayor,  --TIPO_INGRESO
                                                       c.Descripcion_Salida1,  --TIPO_INGRESO_DESC
                                                       c.Descripcion_Salida2   -- SGBSTDN_STYP_CODE
                                                        );
                                                   commit;
                                             EXCEPTION
                                              WHEN OTHERS THEN
                                                NULL;
                                               DBMS_OUTPUT.PUT_LINE('Error al insertar Registro'||sqlerrm);
                                             end;
                             else
                                           begin
                                            UPDATE SATURN.SZTHITA
                                              SET  SZTHITA_STATUS=c.ESTATUS_D,
                                                   SZTHITA_MAJOR=c.mayor,
                                                   SZTHITA_CONCENT1=c.Salida1,
                                                   SZTHITA_CONCENT2=c.Salida2,
                                                   SZTHITA_M_DESC=c.Descripcion_Mayor,
                                                   SZTHITA_C1_DESC=c.Descripcion_Salida1,
                                                   SZTHITA_C2_DESC=c.Descripcion_Salida2,
                                                   SZTHITA_PER_CATALOGO=c.CTLG,
                                                   SZTHITA_STUDY=c.sp
                                              where SZTHITA_PIDM=c.pidm
                                                and SZTHITA_CAMP=c.campus
                                                and SZTHITA_LEVL=c.nivel
                                                and SZTHITA_PROG=c.programa;
                                               commit;
                                           EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro'||sqlerrm);
                                           end;
                             end if;

                         existe:=0;
            End loop;

      begin
         pkg_d_academicos.alimenta_total_mate;   Commit;
         pkg_d_academicos.alimenta_reprobadas;   Commit;
         pkg_d_academicos.alimenta_en_curso;     Commit;
         pkg_d_academicos.alimenta_porc_avance;  Commit;
         pkg_d_academicos.alimenta_por_cursar;   Commit;
         pkg_d_academicos.alimenta_areas;        Commit;
     exception when others then
     null;
     end;     



    END;

Procedure alimenta_areas
is

    BEGIN

        Begin

            for c in (
                         select x.pidm,x.Matricula, x.campus,x.nivel, x.Programa, x.Estatus, x.seqno,x.pcatalogo, x.mayor,x.salida1,x.salida2
                    from (
                               select  distinct /*+ INDEX( IDX2_PIDM) , + FIRST_ROWS */
                                    SZTHITA_PIDM pidm,
                                    SZTHITA_ID as Matricula,
                                    SZTHITA_CAMP campus,
                                    SZTHITA_LEVL nivel,
                                    SZTHITA_PROG  Programa,
                                    SZTHITA_STATUS Estatus,
                                    SZTHITA_STUDY seqno,
                                    SZTHITA_PER_CATALOGO pcatalogo,
                                    SGBSTDN_MAJR_CODE_1 Mayor,
                                    SGBSTDN_MAJR_CODE_CONC_1 Salida1,
                                    SGBSTDN_MAJR_CODE_CONC_1_2 Salida2
                             from SATURN.SZTHITA,SGBSTDN A
                              WHERE SZTHITA_PIDM = SGBSTDN_PIDM
                                   AND SZTHITA_PROG=SGBSTDN_PROGRAM_1
                                   AND SZTHITA_PER_CATALOGO=SGBSTDN_TERM_CODE_CTLG_1
                                   AND SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF) FROM  SGBSTDN B
                                                                 WHERE A.SGBSTDN_PIDM = B.SGBSTDN_PIDM
                                                                   AND A.SGBSTDN_PROGRAM_1=B.SGBSTDN_PROGRAM_1
                                                                   AND A.SGBSTDN_TERM_CODE_CTLG_1=B.SGBSTDN_TERM_CODE_CTLG_1
                                                                )
                                ) x

            ) loop
                                          begin
                                             UPDATE SATURN.SZTHITA
                                               SET SZTHITA_MAJOR=c.Mayor,
                                                    SZTHITA_CONCENT1=c.Salida1,
                                                    SZTHITA_CONCENT2=c.salida2
                                               where SZTHITA_PIDM=c.pidm
                                                 and SZTHITA_PROG=c.programa
                                                 and SZTHITA_STUDY=c.seqno;
                                               commit;
                                          EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              DBMS_OUTPUT.PUT_LINE('Error al actualizar Areas '||sqlerrm);
                                          end;

            End loop;
        End;
    END;

Procedure alimenta_total_mate
is

    tot              number:=0;
    ecur           number:=0;
    apro           number:=0;
    xcur           number:=0;

    BEGIN

        Begin

            for c in (
                         select x.pidm,x.Matricula, x.campus,x.nivel, x.Programa, x.Estatus, x.seqno,x.pcatalogo, x.mayor,x.salida1,x.Total
                    from (
                               select  distinct /*+ INDEX( IDX2_PIDM) , + FIRST_ROWS */
                                    SZTHITA_PIDM pidm,
                                    SZTHITA_ID as Matricula,
                                    SZTHITA_CAMP campus,
                                    SZTHITA_LEVL nivel,
                                    SZTHITA_PROG  Programa,
                                    SZTHITA_STATUS Estatus,
                                    SZTHITA_STUDY seqno,
                                   SZTHITA_PER_CATALOGO pcatalogo,
                                   SZTHITA_MAJOR Mayor,
                                   SZTHITA_CONCENT1 Salida1,
                                   (select to_char(pkg_d_academicos.total_mate2(SZTHITA_PIDM, SZTHITA_PROG)) from dual) Total
                             from SATURN.SZTHITA a
                              WHERE a.SZTHITA_PIDM = (Select distinct a1.SZTHITA_PIDM /*+ INDEX( IDX2_PIDM) , + FIRST_ROWS */
                                                                       from SZTHITA a1
                                                                       WHERE a.SZTHITA_PIDM = a1.SZTHITA_PIDM
                                                                       )
                                ) x

            ) loop

                                           begin
                                             UPDATE SATURN.SZTHITA
                                               SET SZTHITA_TOT_MAT=c.Total
                                               where SZTHITA_PIDM=c.pidm
                                                 and SZTHITA_PROG=c.programa
                                                 and SZTHITA_STUDY=c.seqno;
                                               commit;
                                           EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              --DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro'||sqlerrm);
                                           end;

            End loop;
        End;
    END;

Procedure alimenta_reprobadas
is

    BEGIN

        Begin

            for c in (
                         select x.pidm,x.Matricula, x.campus,x.nivel, x.Programa, x.Estatus, x.seqno,x.pcatalogo, x.mayor,x.salida1,x.Reprobadas
                    from (
                               select  distinct   /*+ INDEX( IDX2_PIDM) , + FIRST_ROWS */
                                   SZTHITA_PIDM pidm,
                                   SZTHITA_ID as Matricula,
                                   SZTHITA_CAMP campus,
                                   SZTHITA_LEVL nivel,
                                   SZTHITA_PROG  Programa,
                                   SZTHITA_STATUS Estatus,
                                   SZTHITA_STUDY seqno,
                                   SZTHITA_PER_CATALOGO pcatalogo,
                                   SZTHITA_MAJOR Mayor,
                                   SZTHITA_CONCENT1 Salida1,
                                   (select to_char(pkg_d_academicos.reprobadas2(SZTHITA_PIDM, SZTHITA_PROG)) from dual) Reprobadas
                             from SATURN.SZTHITA a
                              WHERE a.SZTHITA_PIDM = (Select distinct a1.SZTHITA_PIDM /*+ INDEX( IDX2_PIDM) , + FIRST_ROWS */
                                                                       from SZTHITA a1
                                                                     WHERE a.SZTHITA_PIDM = a1.SZTHITA_PIDM
                                                                     )
                           ) x

            ) loop

                                           begin
                                            UPDATE SATURN.SZTHITA
                                              SET  SZTHITA_REPROB=c.Reprobadas
                                              where SZTHITA_PIDM=c.pidm
                                                and SZTHITA_PROG=c.programa
                                                 and SZTHITA_STUDY=c.seqno;
                                               commit;
                                           EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              --DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro'||sqlerrm);
                                           end;

            End loop;
        End;
    END;


Procedure alimenta_en_curso
is

    BEGIN

        Begin

            for c in (
                         select x.pidm,x.Matricula, x.campus,x.nivel, x.Programa, x.Estatus, x.seqno,x.pcatalogo, x.mayor,x.salida1,x.En_Curso
                    from (
                               select  distinct  /*+ INDEX( IDX2_PIDM) , + FIRST_ROWS */
                                    SZTHITA_PIDM pidm,
                                    SZTHITA_ID as Matricula,
                                    SZTHITA_CAMP campus,
                                    SZTHITA_LEVL nivel,
                                    SZTHITA_PROG  Programa,
                                    SZTHITA_STATUS Estatus,
                                    SZTHITA_STUDY seqno,
                                    SZTHITA_PER_CATALOGO pcatalogo,
                                    SZTHITA_MAJOR Mayor,
                                    SZTHITA_CONCENT1 Salida1,
                                    (select to_char(pkg_d_academicos.e_cur2(SZTHITA_PIDM, SZTHITA_PROG)) from dual) En_Curso
                             from SATURN.SZTHITA a
                              WHERE a.SZTHITA_PIDM = (Select unique  a1.SZTHITA_PIDM /*+ INDEX( IDX2_PIDM) , + FIRST_ROWS */
                                                                       from SZTHITA a1
                                                                       WHERE a.SZTHITA_PIDM = a1.SZTHITA_PIDM
                                                                       )
                                ) x

            ) loop

                                           begin
                                             UPDATE SATURN.SZTHITA
                                              SET  SZTHITA_E_CURSO=c.En_Curso
                                              where SZTHITA_PIDM=c.pidm
                                                and SZTHITA_PROG=c.programa
                                                 and SZTHITA_STUDY=c.seqno;
                                               commit;
                                           EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              --DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro'||sqlerrm);
                                           end;

            End loop;
        End;
    END;


Procedure alimenta_por_cursar
is

    tot            number:=0;
    ecur           number:=0;
    apro           number:=0;
    xcurr          number:=0;
    xcur           number:=0;

    BEGIN

            for c in (
            
            
            
                         select distinct /*+ INDEX_JOIN(X) */ 
                                        x.pidm, 
                                        x.Matricula, 
                                        x.campus, 
                                        x.nivel, 
                                        x.Programa, 
                                        x.Estatus, 
                                        x.seqno,
                                        x.pcatalogo, 
                                        x.mayor,
                                        x.salida1,
                                        x.total,
                                        x.aprobadas, 
                                        x.reprobadas,
                                        x.curso,
                                        x.xcursar,
                                        (x.total- (x.aprobadas+x.reprobadas+x.curso)) porcursar 
                    from (
                               select  distinct /*+ INDEX( DX4_SZTHITA) , + FIRST_ROWS */
                                   SZTHITA_PIDM pidm,
                                   SZTHITA_ID as Matricula,
                                   SZTHITA_CAMP campus,
                                   SZTHITA_LEVL nivel,
                                   SZTHITA_PROG  Programa,
                                   SZTHITA_STATUS Estatus,
                                   SZTHITA_STUDY seqno,
                                   SZTHITA_PER_CATALOGO pcatalogo,
                                   SZTHITA_MAJOR Mayor,
                                   SZTHITA_CONCENT1 Salida1,
                                   nvl (SZTHITA_TOT_MAT,0)total ,
                                   nvl (SZTHITA_APROB,0) aprobadas,
                                   nvl (SZTHITA_REPROB, 0) reprobadas, 
                                   nvl (SZTHITA_E_CURSO,0) curso,
                                   nvl (SZTHITA_X_CURSAR,0)xcursar
                              from SATURN.SZTHITA a
                              WHERE (a.SZTHITA_STUDY ) = (Select max (a1.SZTHITA_STUDY) /*+ INDEX( DX4_SZTHITA) , + FIRST_ROWS */
                                                                       from SZTHITA a1
                                                                       WHERE a.SZTHITA_PIDM = a1.SZTHITA_PIDM
                                                                       AND a.SZTHITA_PROG = a1.SZTHITA_PROG
                                                                       )
                                                                       
                                ) x
                                
            ) loop


                    Begin 
                         UPDATE SZTHITA
                          SET  SZTHITA_X_CURSAR= c.porcursar
                          where SZTHITA_PIDM=c.pidm
                            and SZTHITA_PROG=c.programa
                            and SZTHITA_STUDY=c.seqno;
                           commit;
                       EXCEPTION
                         WHEN OTHERS THEN
                            null;
                         --DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro 1'||sqlerrm);
                    end;

                   


            End loop;
            
            commit;       
    
    END alimenta_por_cursar;


Procedure alimenta_porc_avance IS

       cursor c1 is
                               select  distinct /*+ INDEX( DX4_SZTHITA) , + FIRST_ROWS */
                                   SZTHITA_PIDM pidm,
                                   SZTHITA_ID as Matricula,
                                   SZTHITA_CAMP campus,
                                   SZTHITA_LEVL nivel,
                                   SZTHITA_PROG  Programa,
                                   SZTHITA_STATUS Estatus,
                                   SZTHITA_STUDY seqno,
                                   SZTHITA_PER_CATALOGO pcatalogo,
                                   SZTHITA_MAJOR Mayor,
                                   SZTHITA_CONCENT1 Salida1
                              from SATURN.SZTHITA a
                              WHERE (a.SZTHITA_PIDM,SZTHITA_PROG, A.SZTHITA_LEVL ) = (Select a1.SZTHITA_PIDM,a1.SZTHITA_PROG,a1.SZTHITA_LEVL /*+ INDEX( DX4_SZTHITA) , + FIRST_ROWS */
                                                                                               from SZTHITA a1
                                                                                               WHERE a.SZTHITA_PIDM = a1.SZTHITA_PIDM
                                                                                               AND a.SZTHITA_PROG = a1.SZTHITA_PROG
                                                                                               );
      begin
            for x in c1  loop
               begin
                 DBMS_OUTPUT.PUT_LINE('Error al actualizar Avance del alumno '||x.PIDM||' - '||x.PROGRAMA);
                 pkg_d_academicos.alu_porc_avance(x.PIDM, x.PROGRAMA);
               end;
             end loop;
       end;

Procedure alimenta_promedio
is
       cursor c1 is
                               select  distinct /*+ INDEX( DX4_SZTHITA) , + FIRST_ROWS */
                                    SZTHITA_PIDM pidm,
                                    SZTHITA_ID as Matricula,
                                    SZTHITA_CAMP campus,
                                    SZTHITA_LEVL nivel,
                                    SZTHITA_PROG  Programa,
                                    SZTHITA_STATUS Estatus,
                                    SZTHITA_STUDY seqno,
                                    SZTHITA_PER_CATALOGO pcatalogo,
                                    SZTHITA_MAJOR Mayor,
                                    SZTHITA_CONCENT1 Salida1
                              from SATURN.SZTHITA
                                Where SZTHITA_LEVL='LI'
                                AND SZTHITA_APROB>0;
--                                AND SZTHITA_PIDM=264;
      begin
            for x in c1  loop
               pkg_d_academicos.promedio(x.PIDM, x.PROGRAMA);
             end loop;
       end;

Procedure alimenta_promedio2
is
       cursor c1 is
                               select  distinct /*+ INDEX( DX4_SZTHITA) , + FIRST_ROWS */
                                    SZTHITA_PIDM pidm,
                                    SZTHITA_ID as Matricula,
                                    SZTHITA_CAMP campus,
                                    SZTHITA_LEVL nivel,
                                    SZTHITA_PROG  Programa,
                                    SZTHITA_STATUS Estatus,
                                    SZTHITA_STUDY seqno,
                                    SZTHITA_PER_CATALOGO pcatalogo,
                                    SZTHITA_MAJOR Mayor,
                                    SZTHITA_CONCENT1 Salida1
                              from SATURN.SZTHITA
                                where SZTHITA_LEVL!='LI'
                                  AND SZTHITA_APROB>0;
--                                  AND SZTHITA_PIDM=264;
      begin
            for x in c1  loop
              pkg_d_academicos.promedio(x.PIDM, x.PROGRAMA);
            end loop;
       end;

function f_documentos_alu(ppidm number) return varchar2
is

validaS  varchar2(1);
validaN  varchar2(1):='A';

cursor c_doctos is
select distinct s.sorlcur_pidm pdm ,s.SORLCUR_ADMT_CODE adm, SARCHKL_ADMR_CODE codigo, SARCHKL_CKST_CODE estatus from sorlcur s,SARCHKL ,SARCHKB
WHERE s.sorlcur_pidm=ppidm and s.sorlcur_lmod_code='LEARNER'  and s.sorlcur_seqno in (select max(ss.sorlcur_seqno) from sorlcur ss
                                                                                       where  s.sorlcur_pidm=ss.sorlcur_pidm
                                                                                         and s.sorlcur_program=ss.sorlcur_program
                                                                                         and s.sorlcur_lmod_code=ss.sorlcur_lmod_code)
and s.sorlcur_pidm=SARCHKL_PIDM
and SARCHKL_MANDATORY_IND = 'Y'
and s.SORLCUR_ADMT_CODE=SARCHKB_ADMT_CODE
and SARCHKL_ADMR_CODE=SARCHKB_ADMR_CODE;


   begin
      for jump in c_doctos  loop

        IF  jump.estatus = 'VALIDADO'  then
            validaS := 'Y';
        else
            validaN  := 'N';
        end if;

      end loop;

       IF validaN = 'N'  then
         return (validaN);
        else
            if validaS = 'S' then
                  return (validaS);
              else
                 return (validaN);
            end if;

        end if;


exception when others then
return ('S');

end f_documentos_alu;

procedure bitacora_jobs  is

EXISTE NUMBER;

 BEGIN

                       FOR C IN (
                                  select JOB,(select substr(UPPER(b.WHAT),
                                           (select  ("Posicion de PK"-1) from (select job, instr(UPPER(a.WHAT), 'PK',1,1) as  "Posicion de PK"  from dba_jobs a
                                                                       where (instr(UPPER(a.WHAT), 'PK',1,1))>0 and a.job=b.job)) ,
                                           (select  ("Posicion de ;"-4) from (select job, instr(a1.WHAT, ';',1,1) as  "Posicion de ;"  from dba_jobs a1
                                                                               where (instr(a1.WHAT, ';',1,1))>0 and a1.job=b.job))
                                                            )   Nombre
                                            from dba_jobs b where b.job=d.job) nombre,
                                             LAST_DATE FECHA,
                                             ('JOB EJECUTADO CON EXITO ') MENSAJE
                                              from dba_jobs d
                                              where FAILURES=0
                                              AND BROKEN='N'
                                              AND  trunc(LAST_DATE)=trunc(SYSDATE)
                                        )

                        LOOP

                                   Begin
                                         IF C.NOMBRE IS NOT NULL THEN
                                           BEGIN
                                                 INSERT INTO SZTBJOB
                                                  VALUES (  NULL,
                                                                  C.JOB,
                                                                  C.NOMBRE,
                                                                  C.FECHA,
                                                                  C.MENSAJE,
                                                                  SYSDATE
                                                              );
                                                    commit;
                                             END;
                                          END IF;
                                   Exception
                                         When Others then
                                           begin
                                                dbms_output.put_line( 'no entro 1 JOB EJECUTADO: SZTBJOB: '||sqlerrm);
                                                null;
                                           end;
                                    End;
                        end loop;


                       FOR D IN (
                                                         select JOB,
                                                             (select substr(UPPER(b.WHAT),(select  ("Posicion de SP"-1) from (select job, instr(UPPER(a.WHAT), 'SP_',1,1) as  "Posicion de SP"  from dba_jobs a
                                                                                                                                                            where (instr(UPPER(a.WHAT), 'SP_',1,1))>0 and a.job=b.job)) ,
                                                                                                                                                        (select  ("Posicion de ;"-4) from (select job, instr(a1.WHAT, ';',1,1) as  "Posicion de ;"  from dba_jobs a1
                                                                                                                                                            where (instr(a1.WHAT, ';',1,1))>0 and a1.job=b.job))
                                                                                  )   Nombre
                                                                from dba_jobs b where b.job=d.job) nombre,
                                                             LAST_DATE FECHA,
                                                              ('JOB EJECUTADO CON EXITO ') MENSAJE
                                                           from dba_jobs d
                                                        where FAILURES=0 AND BROKEN='N' AND  trunc(LAST_DATE)=trunc(SYSDATE)
                                        )

                        LOOP

                         EXISTE:=0;
                                   Begin
                                         SELECT COUNT(*) INTO EXISTE
                                         FROM SZTBJOB
                                            WHERE TRUNC(SZTBJOB_FECHA)=TRUNC(SYSDATE)
                                                 AND SZTBJOB_J_NUM=D.JOB;

                                         IF D.NOMBRE IS NOT NULL AND EXISTE=0 THEN
                                           BEGIN
                                                 INSERT INTO SZTBJOB
                                                  VALUES (  NULL,
                                                                  D.JOB,
                                                                  D.NOMBRE,
                                                                  D.FECHA,
                                                                  D.MENSAJE,
                                                                  SYSDATE
                                                              );
                                                    commit;
                                             END;
                                          END IF;
                                   Exception
                                         When Others then
                                           begin
                                                dbms_output.put_line( 'no entro 2 JOB EJECUTADO: SZTBJOB: '||sqlerrm);
                                                null;
                                           end;
                                    End;
                        end loop;



                          FOR E IN (
                                                   select JOB,
                                                             (select substr(UPPER(b.WHAT),(select  ("Posicion de SP"-1) from (select job, instr(UPPER(a.WHAT), 'SP',1,1) as  "Posicion de SP"  from dba_jobs a
                                                                                                                                                            where (instr(UPPER(a.WHAT), 'SP',1,1))>0 and a.job=b.job)) ,
                                                                                                                                                        (select  ("Posicion de ;"-4) from (select job, instr(a1.WHAT, ';',1,1) as  "Posicion de ;"  from dba_jobs a1
                                                                                                                                                            where (instr(a1.WHAT, ';',1,1))>0 and a1.job=b.job))
                                                                                   ) Nombre
                                                                from dba_jobs b where b.job=d.job) nombre,
                                                             LAST_DATE FECHA,
                                                             ('JOB '||JOB||'  DESHABILTADO ') MENSAJE
                                                           from dba_jobs d
                                                        where BROKEN='Y'
                                         )
                        LOOP

                                   Begin
                                        IF E.NOMBRE IS NOT NULL THEN
                                           BEGIN
                                                 INSERT INTO SZTBJOB
                                                  VALUES (  NULL,
                                                                  E.JOB,
                                                                  E.NOMBRE,
                                                                  E.FECHA,
                                                                  E.MENSAJE,
                                                                  SYSDATE
                                                              );
                                                    commit;
                                             END;
                                          END IF;
                                   Exception
                                         When Others then
                                           begin
                                                dbms_output.put_line( 'no entro 1  JOB DESHABILTADO SZTBJOB: '||sqlerrm);
                                                null;
                                           end;
                                        End;
                        end loop;


                         FOR F IN (
                                                   select JOB,
                                                             (select substr(UPPER(b.WHAT),(select  ("Posicion de PK"-1) from (select job, instr(UPPER(a.WHAT), 'PK',1,1) as  "Posicion de PK"  from dba_jobs a
                                                                                                                                                            where (instr(UPPER(a.WHAT), 'PK',1,1))>0 and a.job=b.job)) ,
                                                                                                                                                        (select  ("Posicion de ;"-4) from (select job, instr(a1.WHAT, ';',1,1) as  "Posicion de ;"  from dba_jobs a1
                                                                                                                                                            where (instr(a1.WHAT, ';',1,1))>0 and a1.job=b.job))
                                                                                   ) Nombre
                                                                from dba_jobs b where b.job=d.job) nombre,
                                                             LAST_DATE FECHA,
                                                              ('JOB '||JOB||'  DESHABILTADO ') MENSAJE
                                                           from dba_jobs d
                                                        where BROKEN='Y'
                                         )
                        LOOP
                                   Begin
                                    EXISTE:=0;
                                          SELECT COUNT(*) INTO EXISTE  FROM SZTBJOB
                                            WHERE  TRUNC(SZTBJOB_FECHA)=TRUNC(SYSDATE)  AND
                                               SZTBJOB_J_NUM=F.JOB;

                                         IF F.NOMBRE IS NOT NULL AND EXISTE=0 THEN
                                           BEGIN
                                                 INSERT INTO SZTBJOB
                                                  VALUES (  NULL,
                                                                  F.JOB,
                                                                  F.NOMBRE,
                                                                  F.FECHA,
                                                                  F.MENSAJE,
                                                                  SYSDATE
                                                              );
                                                    commit;
                                             END;
                                          END IF;
                                   Exception
                                         When Others then
                                           begin
                                                dbms_output.put_line( 'no entro 2  JOB DESHABILTADO SZTBJOB: '||sqlerrm);
                                                null;
                                           end;
                                        End;

                        end loop;


                         FOR G IN (
                                                   select JOB,  substr(UPPER(WHAT),1,99) nombre,
                                                             LAST_DATE FECHA,
                                                             CASE  when BROKEN='Y' THEN
                                                                        ('JOB '||JOB||'  DESHABILTADO ')
                                                                    when  BROKEN='N' THEN
                                                                       ('JOB EJECUTADO CON EXITO ')
                                                             END MENSAJE
                                                           from dba_jobs
                                         )
                        LOOP
                                   Begin
                                    EXISTE:=0;
                                          SELECT COUNT(*) INTO EXISTE  FROM SZTBJOB
                                            WHERE  TRUNC(SZTBJOB_FECHA)=TRUNC(SYSDATE)  AND
                                               SZTBJOB_J_NUM=G.JOB;

                                         IF G.NOMBRE IS NOT NULL AND EXISTE=0 THEN
                                           BEGIN
                                                 INSERT INTO SZTBJOB
                                                  VALUES (  NULL,
                                                                  G.JOB,
                                                                  G.NOMBRE,
                                                                  G.FECHA,
                                                                  G.MENSAJE,
                                                                  SYSDATE
                                                              );
                                                    commit;
                                             END;
                                          END IF;
                                   Exception
                                         When Others then
                                           begin
                                                dbms_output.put_line( 'no entro 3  JOB HABILTADO SZTBJOB: '||sqlerrm);
                                                null;
                                           end;
                                        End;

                        end loop;


 END;

Procedure alimenta_total_mate_alu(p_pidm number)
is

    tot            number:=0;
    ecur           number:=0;
    apro           number:=0;
    xcur           number:=0;

    BEGIN

        Begin

            for c in (
                         select x.pidm,x.Matricula, x.campus,x.nivel, x.Programa, x.Estatus, x.seqno,x.pcatalogo, x.mayor,x.salida1,x.Total
                    from (
                               select  distinct /*+ INDEX( IDX2_PIDM) , + FIRST_ROWS */
                                    SZTHITA_PIDM pidm,
                                    SZTHITA_ID as Matricula,
                                    SZTHITA_CAMP campus,
                                    SZTHITA_LEVL nivel,
                                    SZTHITA_PROG  Programa,
                                    SZTHITA_STATUS Estatus,
                                    SZTHITA_STUDY seqno,
                                    SZTHITA_PER_CATALOGO pcatalogo,
                                    SZTHITA_MAJOR Mayor,
                                    SZTHITA_CONCENT1 Salida1,
                                   (select to_char(pkg_d_academicos.total_mate2(SZTHITA_PIDM, SZTHITA_PROG)) from dual) Total
                             from SATURN.SZTHITA a
                              WHERE a.SZTHITA_PIDM = p_pidm
                                ) x

            ) loop

                                           begin
                                             UPDATE SATURN.SZTHITA
                                               SET SZTHITA_TOT_MAT=c.Total
                                               where SZTHITA_PIDM=c.pidm
                                                 and SZTHITA_PROG=c.programa
                                                 and SZTHITA_STUDY=c.seqno;
                                               commit;
                                           EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              --DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro'||sqlerrm);
                                           end;

            End loop;
        End;
    END;

Procedure alimenta_reprobadas_alu(p_pidm number)
is

    BEGIN

        Begin

            for c in (
                         select x.pidm,x.Matricula, x.campus,x.nivel, x.Programa, x.Estatus, x.seqno,x.pcatalogo, x.mayor,x.salida1,x.Reprobadas
                    from (
                               select  distinct   /*+ INDEX( IDX2_PIDM) , + FIRST_ROWS */
                                   SZTHITA_PIDM pidm,
                                   SZTHITA_ID as Matricula,
                                   SZTHITA_CAMP campus,
                                   SZTHITA_LEVL nivel,
                                   SZTHITA_PROG  Programa,
                                   SZTHITA_STATUS Estatus,
                                   SZTHITA_STUDY seqno,
                                   SZTHITA_PER_CATALOGO pcatalogo,
                                   SZTHITA_MAJOR Mayor,
                                   SZTHITA_CONCENT1 Salida1,
                                   (select to_char(pkg_d_academicos.reprobadas2(SZTHITA_PIDM, SZTHITA_PROG)) from dual) Reprobadas
                             from SATURN.SZTHITA a
                              WHERE a.SZTHITA_PIDM = p_pidm
                           ) x

            ) loop

                                           begin
                                            UPDATE SATURN.SZTHITA
                                              SET  SZTHITA_REPROB=c.Reprobadas
                                              where SZTHITA_PIDM=c.pidm
                                                and SZTHITA_PROG=c.programa
                                                 and SZTHITA_STUDY=c.seqno;
                                               commit;
                                           EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              --DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro'||sqlerrm);
                                           end;

            End loop;
        End;
    END;

Procedure alimenta_en_curso_alu(p_pidm number)
is

    BEGIN

        Begin

            for c in (
                         select x.pidm,x.Matricula, x.campus,x.nivel, x.Programa, x.Estatus, x.seqno,x.pcatalogo, x.mayor,x.salida1,x.En_Curso
                    from (
                               select  distinct  /*+ INDEX( IDX2_PIDM) , + FIRST_ROWS */
                                    SZTHITA_PIDM pidm,
                                    SZTHITA_ID as Matricula,
                                    SZTHITA_CAMP campus,
                                    SZTHITA_LEVL nivel,
                                    SZTHITA_PROG  Programa,
                                    SZTHITA_STATUS Estatus,
                                    SZTHITA_STUDY seqno,
                                    SZTHITA_PER_CATALOGO pcatalogo,
                                    SZTHITA_MAJOR Mayor,
                                    SZTHITA_CONCENT1 Salida1,
                                    (select to_char(pkg_d_academicos.e_cur2(SZTHITA_PIDM, SZTHITA_PROG)) from dual) En_Curso
                             from SATURN.SZTHITA a
                              WHERE a.SZTHITA_PIDM = p_pidm
                                ) x

            ) loop

                                           begin
                                             UPDATE SATURN.SZTHITA
                                              SET  SZTHITA_E_CURSO=c.En_Curso
                                              where SZTHITA_PIDM=c.pidm
                                                and SZTHITA_PROG=c.programa
                                                 and SZTHITA_STUDY=c.seqno;
                                               commit;
                                           EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              --DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro'||sqlerrm);
                                           end;

            End loop;
        End;
    END;

Procedure alimenta_por_cursar_alu(p_pidm number,p_prog varchar2)
is

    tot            number:=0;
    ecur           number:=0;
    apro           number:=0;
    xcurr          number:=0;
    xcur           number:=0;

    BEGIN

        Begin

            for c in (
                         select x.pidm,x.Matricula, x.campus,x.nivel, x.Programa, x.Estatus, x.seqno,x.pcatalogo, x.mayor,x.salida1
                    from (
                               select  distinct /*+ INDEX( DX4_SZTHITA) , + FIRST_ROWS */
                                   SZTHITA_PIDM pidm,
                                   SZTHITA_ID as Matricula,
                                   SZTHITA_CAMP campus,
                                   SZTHITA_LEVL nivel,
                                   SZTHITA_PROG  Programa,
                                   SZTHITA_STATUS Estatus,
                                   SZTHITA_STUDY seqno,
                                   SZTHITA_PER_CATALOGO pcatalogo,
                                   SZTHITA_MAJOR Mayor,
                                   SZTHITA_CONCENT1 Salida1
                              from SATURN.SZTHITA
                              WHERE SZTHITA_PIDM = p_pidm
                                    and SZTHITA_PROG = p_prog
                                ) x

            ) loop
                                Begin

                                    select SZTHITA_TOT_MAT ,SZTHITA_APROB, SZTHITA_E_CURSO,SZTHITA_X_CURSAR
                                            into tot, apro, ecur, xcur
                                      from SATURN.SZTHITA
                                      where SZTHITA_PIDM=c.pidm
                                          and SZTHITA_CAMP=c.campus
                                          and SZTHITA_LEVL=c.nivel
                                          and SZTHITA_PROG=c.programa
                                          and SZTHITA_STATUS=c.estatus
                                          and SZTHITA_STUDY=c.seqno
                                          and SZTHITA_PER_CATALOGO=c.pcatalogo;
                                Exception
                                    When others then
                                         tot:= 0;
                                         apro:= 0;
                                         ecur:= 0;
                                         xcur:= 0;
                                End;

                            if tot>0 then
                                           begin
                                             xcurr:=tot-(apro+ecur);

                                              if tot=apro then
                                                 xcurr:=0;
                                              end if;

                                              if  tot=(apro+ecur) then
                                                 xcurr:=0;
                                              end if;

                                              if  (apro+ecur)>tot then
                                                 xcurr:=0;
                                              end if;

                                              if tot=xcur then
                                                begin
                                                 if apro>0 then
                                                            xcurr:=tot-(apro+ecur);
                                                 elsif apro=0 then
                                                            xcurr:=tot-ecur;
                                                 end if;
                                                end;
                                              end if;

                                            UPDATE SATURN.SZTHITA
                                              SET  SZTHITA_X_CURSAR=xcurr
                                              where SZTHITA_PIDM=c.pidm
                                                and SZTHITA_PROG=c.programa
                                                and SZTHITA_STUDY=c.seqno;
                                               commit;
                                           EXCEPTION
                                             WHEN OTHERS THEN
                                                null;
                                             --DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro 1'||sqlerrm);
                                           end;

                            elsif tot=0 then
                                        begin
                                            xcurr:=0;
                                            UPDATE SATURN.SZTHITA
                                            SET  SZTHITA_X_CURSAR=xcurr,
                                                 SZTHITA_AVANCE=0,
                                                 SZTHITA_PROMEDIO=0,
                                                 SZTHITA_APROB=0
                                            where SZTHITA_PIDM=c.pidm
                                              and SZTHITA_PROG=c.programa
                                                 and SZTHITA_STUDY=c.seqno;
                                             commit;
                                            EXCEPTION
                                             WHEN OTHERS THEN
                                              null;
                                             --DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro 2'||sqlerrm);
                                        end;
                             end if;

                             if apro is null then
                                           begin
                                             xcurr:=tot-ecur;
                                            UPDATE SATURN.SZTHITA
                                              SET  SZTHITA_APROB=0,
                                                   SZTHITA_X_CURSAR=xcurr
                                              where SZTHITA_PIDM=c.pidm
                                                and SZTHITA_PROG=c.programa
                                                and SZTHITA_STUDY=c.seqno;
                                               commit;
                                           EXCEPTION
                                             WHEN OTHERS THEN
                                                null;
                                             --DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro 3'||sqlerrm);
                                           end;
                             end if;

            End loop;
        End;
    END;

Procedure alimenta_d_Hist_Academica_alu(p_pidm number) is

    existe         number:=0;
    tot            number:=0;
    ecur           number:=0;
    apro           number:=0;
    xcur           number:=0;

    BEGIN


          for c in (
                               select distinct PIDM,
                                               MATRICULA,
                                               replace(SPRIDEN_LAST_NAME,'/',' ') || ' ' || SPRIDEN_FIRST_NAME as Nombre,
                                               CAMPUS,
                                               NIVEL,
                                               PROGRAMA,
                                               SZTDTEC_PROGRAMA_COMP Nombre_Programa,
                                               ESTATUS_D,
                                               SP,
                                               CTLG,
                                               null Mayor,
                                               TIPO_INGRESO Descripcion_Mayor,
                                               null Salida1,
                                               TIPO_INGRESO_DESC Descripcion_Salida1,
                                               null Salida2,
                                               null Descripcion_Salida2
                             from tztprog_hist
                                join SPRIDEN on SPRIDEN_PIDM = PIDM AND  SPRIDEN_CHANGE_IND IS NULL
                                join sztdtec on sztdtec_program=programa and SZTDTEC_CAMP_CODE=CAMPUS and SZTDTEC_TERM_CODE=CTLG
                                where 1=1
                                  AND PIDM=p_pidm
            ) loop

                            Begin
                             select count(*) into existe from SATURN.SZTHITA
                               where SZTHITA_PIDM=c.pidm
                                 and SZTHITA_CAMP=c.campus
                                 and SZTHITA_LEVL=c.nivel
                                 and SZTHITA_PROG=c.programa;
                            Exception
                              When Others then
                                existe :=0;
                            End;

                             if existe=0 then
                                             begin
                                                Insert into SATURN.SZTHITA values
                                                      (c.pidm,
                                                       c.Matricula,
                                                       c.Nombre,
                                                       c.campus,
                                                       c.nivel,
                                                       c.Programa,
                                                       c.Nombre_Programa,
                                                       c.ESTATUS_D,
                                                       null, --Aprobadas
                                                       null, --Reprobadas
                                                       null, --En_Curso
                                                       null, --Por_Cursar
                                                       null, --Total
                                                       null, --avances
                                                       null, --promedio
                                                       c.SP,
                                                       c.CTLG,
                                                       c.mayor,
                                                       c.Salida1,
                                                       c.Salida2,
                                                       c.Descripcion_Mayor,  --TIPO_INGRESO
                                                       c.Descripcion_Salida1,  --TIPO_INGRESO_DESC
                                                       c.Descripcion_Salida2
                                                        );
                                                   commit;
                                             EXCEPTION
                                              WHEN OTHERS THEN
                                                NULL;
                                               DBMS_OUTPUT.PUT_LINE('Error al insertar Registro'||sqlerrm);
                                             end;
                             else
                                           begin
                                            UPDATE SATURN.SZTHITA
                                              SET  SZTHITA_STATUS=c.ESTATUS_D,
                                                   SZTHITA_MAJOR=c.mayor,
                                                   SZTHITA_CONCENT1=c.Salida1,
                                                   SZTHITA_CONCENT2=c.Salida2,
                                                   SZTHITA_M_DESC=c.Descripcion_Mayor,
                                                   SZTHITA_C1_DESC=c.Descripcion_Salida1,
                                                   SZTHITA_C2_DESC=c.Descripcion_Salida2,
                                                   SZTHITA_PER_CATALOGO=c.CTLG,
                                                   SZTHITA_STUDY=c.sp
                                              where SZTHITA_PIDM=c.pidm
                                                and SZTHITA_CAMP=c.campus
                                                and SZTHITA_LEVL=c.nivel
                                                and SZTHITA_PROG=c.programa;
                                               commit;
                                           EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              DBMS_OUTPUT.PUT_LINE('Error al actualizar Registro'||sqlerrm);
                                           end;
                             end if;

                         existe:=0;
            End loop;

    END;

Procedure alimenta_p_avance_matricula (matricula varchar2) IS
--- fincion para ajustar el avance de un solo alumno
       cursor c1 is
                               select  distinct /*+ INDEX( DX4_SZTHITA) , + FIRST_ROWS */
                                   SZTHITA_PIDM pidm,
                                   SZTHITA_ID as Matricula,
                                   SZTHITA_CAMP campus,
                                   SZTHITA_LEVL nivel,
                                   SZTHITA_PROG Programa,
                                   SZTHITA_STATUS Estatus,
                                   SZTHITA_STUDY seqno,
                                   SZTHITA_PER_CATALOGO pcatalogo,
                                   SZTHITA_MAJOR Mayor,
                                   SZTHITA_CONCENT1 Salida1
                              from SATURN.SZTHITA a
                              WHERE SZTHITA_ID=matricula
                              and (a.SZTHITA_PIDM,SZTHITA_PROG) = (Select a1.SZTHITA_PIDM,a1.SZTHITA_PROG /*+ INDEX( DX4_SZTHITA) , + FIRST_ROWS */
                                                                       from SZTHITA a1
                                                                       WHERE a.SZTHITA_PIDM = a1.SZTHITA_PIDM
                                                                       AND a.SZTHITA_PROG = a1.SZTHITA_PROG
                                                                       );
      begin
            for x in c1  loop
               begin
                 DBMS_OUTPUT.PUT_LINE('Error al actualizar Avance del alumno '||x.PIDM||' - '||x.PROGRAMA);
                 pkg_d_academicos.alimenta_d_Hist_Academica_alu(x.PIDM);
                 pkg_d_academicos.alu_porc_avance(x.PIDM, x.PROGRAMA);
                 pkg_d_academicos.alimenta_total_mate_alu(x.PIDM);
                 pkg_d_academicos.alimenta_reprobadas_alu(x.PIDM);
                 pkg_d_academicos.alimenta_en_curso_alu(x.PIDM);
                 pkg_d_academicos.alimenta_por_cursar_alu(x.PIDM, x.PROGRAMA);
                 pkg_d_academicos.promedio( x.pidm, x.programa);
               end;
             end loop;
       end;


procedure p_cargatztprog_hist is

/* Formatted on 08/05/2019 12:24:05 p.m. (QP5 v5.215.12089.38647) */
 vl_pago number:=0;
 vl_pago_minimo number:=0;
 vl_sp number:=0;

BEGIN


EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.tztprog_hist';
COMMIT;



 insert into migra.tztprog_hist
select distinct b.spriden_pidm pidm,
 b.spriden_id Matricula,
 a.SGBSTDN_STST_CODE Estatus,
 STVSTST_DESC Estatus_D,
 a.SGBSTDN_STYP_CODE,
 f.sorlcur_camp_code Campus,
 f.sorlcur_levl_code Nivel ,
 a.sgbstdn_program_1 programa,
 SMRPRLE_PROGRAM_DESC Nombre,
 f.SORLCUR_KEY_SEQNO sp,
 trunc (SGBSTDN_ACTIVITY_DATE) Fecha_Mov,
 f.SORLCUR_TERM_CODE_CTLG ctlg,
 nvl ( f.SORLCUR_TERM_CODE_MATRIC,SORLCUR_TERM_CODE_ADMIT )  Matriculacion,
 b.SPRIDEN_CREATE_FDMN_CODE,
 f.SORLCUR_START_DATE fecha_inicio
 ,sysdate as fecha_carga,
 f.sorlcur_ADMT_CODE,
 STVADMT_DESC
 from sgbstdn a, spriden b, STVSTYP, stvSTST, smrprle, sorlcur f, stvADMT
 where 1= 1
-- And a.sgbstdn_camp_code = 'UTL'
-- and a.sgbstdn_levl_code = 'LI'
and a.SGBSTDN_STYP_CODE = STVSTYP_CODE
 and a.sgbstdn_pidm = b.spriden_pidm
 and b.spriden_change_ind is null
 and a.SGBSTDN_STST_CODE = STVSTST_CODE
 And a.sgbstdn_program_1 = SMRPRLE_PROGRAM
 and a.SGBSTDN_STST_CODE != 'CP'
 And nvl (f.sorlcur_ADMT_CODE,'RE') = stvADMT_code
 and a.SGBSTDN_TERM_CODE_EFF = ( select max (a1.SGBSTDN_TERM_CODE_EFF)
 from sgbstdn a1
 where a.sgbstdn_pidm = a1.sgbstdn_pidm
 And a.sgbstdn_camp_code = a1.sgbstdn_camp_code
 and a.sgbstdn_levl_code = a1.sgbstdn_levl_code
 and a.sgbstdn_program_1 = a1.sgbstdn_program_1
 )
and f.sorlcur_pidm = a.sgbstdn_pidm
And f.sorlcur_program = a.sgbstdn_program_1
and f.SORLCUR_LMOD_CODE = 'LEARNER'
and f.SORLCUR_SEQNO = (select max (f1.SORLCUR_SEQNO)
 from sorlcur f1
 Where f.sorlcur_pidm = f1.sorlcur_pidm
 and f.sorlcur_camp_code = f1.sorlcur_camp_code
 and f.sorlcur_levl_code = f1.sorlcur_levl_code
 and f.SORLCUR_LMOD_CODE = f1.SORLCUR_LMOD_CODE
 And f.SORLCUR_PROGRAM = f1.SORLCUR_PROGRAM )
--and f.sorlcur_pidm = 460
UNION
select distinct b.spriden_pidm pidm,
b.spriden_id matricula,
nvl (c.ESTATUS, decode (SORLCUR_CACT_CODE,'INACTIVE', 'BT', 'ACTIVE', 'MA', 'CHANGE', 'CP' )) Estatus,
stvSTST_desc TIPO_ALUMNO,
a.SORLCUR_STYP_CODE ,
a.sorlcur_camp_code CAMPUS,
a.sorlcur_levl_code NIVEL,
a.sorlcur_program Programa,
SMRPRLE_PROGRAM_DESC Nombre,
a.SORLCUR_KEY_SEQNO sp,
trunc (a.SORLCUR_ACTIVITY_DATE) Fecha_Mov,
a.SORLCUR_TERM_CODE_CTLG ctlg,
nvl (a.SORLCUR_TERM_CODE_MATRIC,SORLCUR_TERM_CODE_ADMIT)  Matriculacion,
b.SPRIDEN_CREATE_FDMN_CODE,
 a.SORLCUR_START_DATE fecha_inicio,
 sysdate as fecha_carga,
a.sorlcur_ADMT_CODE,
STVADMT_DESC
from sorlcur a
join spriden b on b.spriden_pidm = a.sorlcur_pidm and spriden_change_ind is null
left join migra.ESTATUS_REPORTE c on c.SPRIDEN_PIDM =a.sorlcur_pidm and c.PROGRAMAS = a.SORLCUR_PROGRAM
join SMRPRLE on SMRPRLE_PROGRAM = a.SORLCUR_PROGRAM
join stvADMT on stvADMT_code = nvl (a.sorlcur_ADMT_CODE,'RE')
left join stvSTST on stvSTST_code = nvl (c.ESTATUS, decode (SORLCUR_CACT_CODE,'INACTIVE', 'BT', 'ACTIVE', 'MA', 'CHANGE', 'CP' ))
where 1= 1
and a.SORLCUR_LMOD_CODE = 'LEARNER'
--and a.SORLCUR_CACT_CODE != 'CHANGE'
--and a.SGBSTDN_STST_CODE != 'CP'
and a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
 from sorlcur a1
 Where a.sorlcur_pidm = a1.sorlcur_pidm
 and a.sorlcur_camp_code = a1.sorlcur_camp_code
 and a.sorlcur_levl_code = a1.sorlcur_levl_code
 and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE
 And a.SORLCUR_PROGRAM = a1.SORLCUR_PROGRAM )
and (a.sorlcur_camp_code, a.sorlcur_levl_code, a.SORLCUR_PROGRAM) not in (select sgbstdn_camp_code, sgbstdn_levl_code, ax.sgbstdn_program_1
 from sgbstdn ax
 Where ax.sgbstdn_pidm = a.sorlcur_pidm);

 --and a.sorlcur_pidm = 460;
commit;


-----------------------------------------------------------Se actualiza la fecha de movimientos ---------------------------------------------------------------------------
 ----------------se modifica 17/07/2019 para realizara actualizacion de la fecha de movimiento--------------------------------------
 Begin

 For c in (

 Select distinct pidm, sp, nvl (fecha_inicio, '04/03/2017' ) fecha_inicio, campus||nivel campus, FECHA_MOV
 from tztprog_hist
 where 1= 1
 --CAMPUS||nivel = 'ULTLI'
 --and fecha_mov is null

 ) loop

 If c.fecha_inicio < '04/03/2017' and c.campus != 'UTLLI' then

 Begin
 Update tztprog_hist
 set FECHA_MOV = '04/03/2017'
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 ElsIf c.fecha_inicio >= '04/03/2017' and c.fecha_mov is null then

 Begin
 Update tztprog_hist
 set FECHA_MOV = c.fecha_inicio
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 End if;

 Commit;
 End Loop;
 End;

 Update tztprog_hist
 set FECHA_MOV = '03/04/2017'
 Where FECHA_MOV is null;
 Commit;


 ---- Se actualiza la fecha de la primera inscripcion ----------


 begin


 for c in (
 select *
 from tztprog_hist
 where 1 = 1
 -- and rownum <= 50
 )loop



 Begin


 Update tztprog_hist
 set FECHA_PRIMERA = (
 select min (x.fecha_inicio) --, rownum
 from (
 SELECT DISTINCT
 min (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
 FROM SFRSTCR a, SSBSECT b
 WHERE a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
 AND a.SFRSTCR_CRN = b.SSBSECT_CRN
 AND a.SFRSTCR_RSTS_CODE = 'RE'
 AND b.SSBSECT_PTRM_START_DATE =
 (SELECT min (b1.SSBSECT_PTRM_START_DATE)
 FROM SSBSECT b1
 WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
 AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
 and sfrstcr_pidm = c.pidm
 AND SFRSTCR_STSP_KEY_SEQUENCE = c.sp
 GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
 order by 1,3 asc
 ) x
 )
 Where pidm = c.pidm
 And sp = c.sp;

 exception when others then

 null;
 end;

 end loop;
 Commit;

 end;

---------- Pone el tipoo de estatus desercion para todos las bajas

Begin

    For cx in (

                    select *
                    from tztprog_hist
                    where 1= 1
                    and estatus in ('BT','BD','CM','CV','BI')
                    and SGBSTDN_STYP_CODE !='D'


     ) loop

        Begin
            Update tztprog_hist
            set SGBSTDN_STYP_CODE ='D'
            where pidm = cx.pidm
            And estatus = cx.estatus
            And programa = cx.programa
            And SGBSTDN_STYP_CODE = cx.SGBSTDN_STYP_CODE;
       Exception
        When Others then
            null;
       End;


     End Loop;

     Commit;

End;



end p_cargatztprog_hist;




end pkg_d_academicos;
/

DROP PUBLIC SYNONYM PKG_D_ACADEMICOS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_D_ACADEMICOS FOR BANINST1.PKG_D_ACADEMICOS;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_D_ACADEMICOS TO PUBLIC;
