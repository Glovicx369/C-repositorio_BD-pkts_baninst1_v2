DROP PACKAGE BODY BANINST1.PKG_DATOS_ACADEMICOS;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_datos_academicos
is

function promedio( soli number) return float is

prom decimal(6,2);
p_ord number;
c_ord number;
p_equi number;
c_equi number;
nivel    varchar2(2);

begin

          select smrprle_levl_code into nivel
          from svrsvpr, svrsvad ,smrprle
          where svrsvpr_protocol_seq_no=soli
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrprle_program=substr(svrsvad_addl_data_cde,1,10);

         if nivel not in ('MA','MS','DO') then
           select  nvl(sum(shrgrde_quality_points),0) , count(*)  into p_ord, c_ord
           from    svrsvpr, svrsvad, smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn y
           where   svrsvpr_protocol_seq_no=soli
           and     svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and     svrsvad_addl_data_seq=1
           and     smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
           and     sgbstdn_pidm=svrsvpr_pidm
           and     sgbstdn_program_1=smrpaap_program
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                              and     x.sgbstdn_program_1=y.sgbstdn_program_1)
           AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
           and     sorlcur_pidm=sgbstdn_pidm
           and     sorlcur_program=smrpaap_program
           and     sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ww
                                               where w.sorlcur_pidm=ww.sorlcur_pidm
                                               and     w.sorlcur_program=ww.sorlcur_program)
           and     shrtckn_pidm=sorlcur_pidm
           and     shrtckn_subj_code=smrarul_subj_code
           and     shrtckn_crse_numb=smrarul_crse_numb_low
           and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
           and     shrtckg_pidm=shrtckn_pidm
           and     shrtckg_tckn_seq_no=shrtckn_seq_no   and shrtckg_term_code=shrtckn_term_code
           and     shrtckg_grde_code_final=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_gpa_ind='Y'
--           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
--                                                 where zstpara_mapa_id='ESC_SHAGRD'
--                                                   and substr((select f_getspridenid(sorlcur_pidm) from dual),1,2)=zstpara_param_id
--                                                   and zstpara_param_valor=sorlcur_levl_code)
            and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc)) or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)))
                          );
        else
          select    nvl(sum(shrgrde_quality_points),0) , count(*)  into p_ord, c_ord
            from    svrsvpr, svrsvad, smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn y
           where    svrsvpr_protocol_seq_no=soli
             and    svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
             and    svrsvad_addl_data_seq=1
             and    smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
             and    sgbstdn_pidm=svrsvpr_pidm
             and    sgbstdn_program_1=smrpaap_program
             and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                               where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                 and x.sgbstdn_program_1=y.sgbstdn_program_1)
             AND    (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
             and    smrpaap_area=smrarul_area
             and    smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  ('UTLMTI0101',
                                                                                                              'UTLLTE0101',
                                                                                                              'UTLLTI0101',
                                                                                                              'UTLLTS0101',
                                                                                                              'UTLLTT0110',
                                                                                                              'UOCATN0101',
                                                                                                              'UTSMTI0101',
                                                                                                              'UNAMPT0111',
                                                                                                              'UVEBTB0101',
                                                                                                              'UTLTSS0110')
             and     sorlcur_pidm=sgbstdn_pidm
             and     sorlcur_program=smrpaap_program
             and     sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ww
                                        where w.sorlcur_pidm=ww.sorlcur_pidm
                                          and w.sorlcur_program=ww.sorlcur_program)
             and     shrtckn_pidm=sorlcur_pidm
             and     shrtckn_subj_code=smrarul_subj_code
             and     shrtckn_crse_numb=smrarul_crse_numb_low
             and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
             and     shrtckg_pidm=shrtckn_pidm
             and     shrtckg_tckn_seq_no=shrtckn_seq_no   and shrtckg_term_code=shrtckn_term_code
             and     shrtckg_grde_code_final=shrgrde_code
             and     smrprle_program=smrpaap_program
             and     shrgrde_levl_code=smrprle_levl_code
             and     shrgrde_gpa_ind='Y'
             and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                   where zstpara_mapa_id='ESC_SHAGRD'
                                                     and substr((select f_getspridenid(sorlcur_pidm) from dual),1,2)=zstpara_param_id
                                                     and zstpara_param_valor=sorlcur_levl_code);
        end if;

         if nivel not in ('MA','MS','DO') then
            select  nvl(sum(shrgrde_quality_points),0) , count(*) into p_equi, c_equi
            from    svrsvpr, svrsvad,smrpaap s, smrarul, smracaa,shrtrce, shrtrcr, shrgrde, smrprle, sgbstdn y
           where    svrsvpr_protocol_seq_no=soli
             and    svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
             and    svrsvad_addl_data_seq=1
             and    smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
             and    sgbstdn_pidm=svrsvpr_pidm
             AND    (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
             and    sgbstdn_program_1=smrpaap_program
             and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                              and     x.sgbstdn_program_1=y.sgbstdn_program_1)
             and     smrpaap_area=smrarul_area
             and     smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  ('UTLMTI0101',
                                                                                                             'UTLLTE0101',
                                                                                                             'UTLLTI0101',
                                                                                                             'UTLLTS0101',
                                                                                                             'UTLLTT0110',
                                                                                                             'UOCATN0101',
                                                                                                             'UTSMTI0101',
                                                                                                             'UNAMPT0111',
                                                                                                             'UVEBTB0101',
                                                                                                             'UTLTSS0110')
            and      shrtrce_pidm=sgbstdn_pidm
            and      shrtrce_subj_code=smrarul_subj_code
            and      shrtrce_crse_numb=smrarul_crse_numb_low
            and      shrtrce_pidm=shrtrcr_pidm
            and      shrtrce_trit_seq_no=shrtrcr_trit_seq_no
            and      shrtrce_tram_seq_no=shrtrcr_tram_seq_no
            and      shrtrce_trcr_seq_no=shrtrcr_seq_no
            and      shrtrcr_program=smrpaap_program
            and      smrprle_program=smrpaap_program
            and      shrtrce_grde_code=shrgrde_code
            and      shrgrde_levl_code=smrprle_levl_code
            and      shrgrde_gpa_ind='Y'
--            and      shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
--                                                 where zstpara_mapa_id='ESC_SHAGRD'
--                                                   and substr((select f_getspridenid(sgbstdn_pidm) from dual),1,2)=zstpara_param_id
--                                                   and zstpara_param_valor=sgbstdn_levl_code)
            and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc)) or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)))
                          );
        else
            select   nvl(sum(shrgrde_quality_points),0) , count(*) into p_equi, c_equi
              from   svrsvpr, svrsvad,smrpaap s, smrarul, smracaa,shrtrce, shrtrcr, shrgrde, smrprle, sgbstdn y
             where   svrsvpr_protocol_seq_no=soli
               and   svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
               and   svrsvad_addl_data_seq=1
               and   smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
               and   sgbstdn_pidm=svrsvpr_pidm
               and   (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
               and   sgbstdn_program_1=smrpaap_program
               and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                  and x.sgbstdn_program_1=y.sgbstdn_program_1)
               and   smrpaap_area=smrarul_area
               and   smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
               and      shrtrce_pidm=sgbstdn_pidm
               and      shrtrce_subj_code=smrarul_subj_code
               and      shrtrce_crse_numb=smrarul_crse_numb_low
               and      shrtrce_pidm=shrtrcr_pidm
               and      shrtrce_trit_seq_no=shrtrcr_trit_seq_no
               and      shrtrce_tram_seq_no=shrtrcr_tram_seq_no
               and      shrtrce_trcr_seq_no=shrtrcr_seq_no
               and      shrtrcr_program=smrpaap_program
               and      smrprle_program=smrpaap_program
               and      shrtrce_grde_code=shrgrde_code
               and      shrgrde_levl_code=smrprle_levl_code
               and      shrgrde_gpa_ind='Y'
               and      shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                      where zstpara_mapa_id='ESC_SHAGRD'
                                                        and substr((select f_getspridenid(sgbstdn_pidm) from dual),1,2)=zstpara_param_id
                                                        and zstpara_param_valor=sgbstdn_levl_code);
        end if;

            if (p_ord+p_equi) > 0 and (c_ord+c_equi) > 0 then
               prom:=round((p_ord+p_equi)/(c_ord+c_equi),1);
            else
               prom:=0;
             end if;

return prom;



end promedio;

function promedio1( pidm number, prog varchar2) return float is

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
          where   smrprle_program=prog;


        if nivel not in ('MA','MS','DO') then

              select  nvl(sum(puntos),0) , count(*)
               into p_ord, c_ord
              from (
               select   distinct SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL) calificacion , nvl(max(shrgrde_quality_points),0)  puntos ,smracaa_area
                from  smrpaap s, smrarul, smracaa,shrtckg b, shrtckn a, shrgrde c, sorlcur w, smrprle d, sgbstdn x,smbagen
               where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
               and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                       where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code) -- and sorlcur_roll_ind='Y'
               and       smrpaap_program= sorlcur_program
               and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
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
--               and     c.shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
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
                   select   distinct SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL) calificacion , nvl(max(shrgrde_quality_points),0)  puntos ,smracaa_area
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
                                                                          and    b.shrtckg_pidm= dd.shrtckg_pidm
                                                                          and  dd.shrtckg_pidm=ee.shrtckn_pidm
                                                                          and dd.shrtckg_term_code=ee.shrtckn_term_code
                                                                          and dd.SHRTCKG_TCKN_SEQ_NO =ee.SHRTCKN_SEQ_NO
                                                                          group by ee.SHRTCKN_SUBJ_CODE||ee.SHRTCKN_CRSE_NUMB )
                     and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_ID from zstpara
                                                                         where ZSTPARA_MAPA_ID='TALLER_HIAC'
                                                                           and SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB=ZSTPARA_PARAM_ID)
                   and     smrprle_program=smrpaap_program
                   and     c.shrgrde_levl_code=smrprle_levl_code
                   and     c.shrgrde_passed_ind='Y'
                   and     c.shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
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
          where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                          where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
          and       smrpaap_program= sorlcur_program
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
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
--           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
           and     sgbstdn_pidm=shrtrce_pidm
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
           and    (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.sorlcur_pidm =pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'MAJOR'--CONCENTRATION
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                           )    )
                                                   and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.sorlcur_pidm =pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                                 ) )) )
               order by substr(smrarul_area,9,2);
       else
          select   nvl(sum(shrgrde_quality_points),0) , count(*) into p_equi, c_equi
          from  smrpaap s, smrarul, smracaa, shrtrce, shrtrcr, shrgrde, sorlcur w, smrprle, sgbstdn x
          where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                          where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
          and       smrpaap_program= sorlcur_program
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
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
           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
           and     sgbstdn_pidm=shrtrce_pidm
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
           order by substr(smrarul_area,9,2);
           --dbms_output.put_line('puntos3:'||p_equi||'*'|| c_equi );
       end if;

        -- dbms_output.put_line('puntos_total:'||p_equi||'*'|| c_equi ||'*'||p_ord ||'*'||c_ord);

             if (p_ord+p_equi) > 0 and (c_ord+c_equi) > 0 then
--               prom:=round((p_ord+p_equi+p_ec)/(c_ord+c_equi+c_ec),1);
               prom:=round((p_ord+p_equi)/(c_ord+c_equi),3);   -- PROMEDIO SIN REDONDEO
            else
               prom:=0;
             end if;

           if prom>10 then
             prom:=10.0;
           end if;

return prom;

end promedio1;





function promedio_letras(soli number) return varchar2 is

prom decimal(6,2);
p_ord number;
c_ord number;
p_equi number;
c_equi number;
letras varchar2(40);
nivel   varchar2(2);

begin

          select smrprle_levl_code into nivel
          from svrsvpr, svrsvad ,smrprle
          where svrsvpr_protocol_seq_no=soli
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrprle_program=substr(svrsvad_addl_data_cde,1,10);

        if nivel not in ('MA','MS','DO') then
           select     nvl(sum(shrgrde_quality_points),0) , count(*)  into p_ord, c_ord
           from      svrsvpr, svrsvad, smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn y
           where    svrsvpr_protocol_seq_no=soli
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
            and     sgbstdn_pidm=svrsvpr_pidm
            and     sgbstdn_program_1=smrpaap_program
            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                              and     x.sgbstdn_program_1=y.sgbstdn_program_1)
           AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
           and     sorlcur_pidm=sgbstdn_pidm
           and     sorlcur_program=smrpaap_program
           and     sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ww
                                               where w.sorlcur_pidm=ww.sorlcur_pidm
                                               and     w.sorlcur_program=ww.sorlcur_program)
           and     shrtckn_pidm=sorlcur_pidm
           and     shrtckn_subj_code=smrarul_subj_code
           and     shrtckn_crse_numb=smrarul_crse_numb_low
           and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
           and     shrtckg_pidm=shrtckn_pidm
           and     shrtckg_tckn_seq_no=shrtckn_seq_no   and shrtckg_term_code=shrtckn_term_code
           and     shrtckg_grde_code_final=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_gpa_ind='Y'
--           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
--                                                 where zstpara_mapa_id='ESC_SHAGRD'
--                                                   and substr((select f_getspridenid(sorlcur_pidm) from dual),1,2)=zstpara_param_id
--                                                   and zstpara_param_valor=sorlcur_levl_code)
            and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc)) or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)))
                          );
         else
           select     nvl(sum(shrgrde_quality_points),0) , count(*)  into p_ord, c_ord
           from      svrsvpr, svrsvad, smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn y
           where    svrsvpr_protocol_seq_no=soli
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
            and     sgbstdn_pidm=svrsvpr_pidm
            and     sgbstdn_program_1=smrpaap_program
            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                              and     x.sgbstdn_program_1=y.sgbstdn_program_1)
           AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
           and     sorlcur_pidm=sgbstdn_pidm
           and     sorlcur_program=smrpaap_program
           and     sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ww
                                               where w.sorlcur_pidm=ww.sorlcur_pidm
                                               and     w.sorlcur_program=ww.sorlcur_program)
           and     shrtckn_pidm=sorlcur_pidm
           and     shrtckn_subj_code=smrarul_subj_code
           and     shrtckn_crse_numb=smrarul_crse_numb_low
           and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
           and     shrtckg_pidm=shrtckn_pidm
           and     shrtckg_tckn_seq_no=shrtckn_seq_no   and shrtckg_term_code=shrtckn_term_code
           and     shrtckg_grde_code_final=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_gpa_ind='Y'
           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                 where zstpara_mapa_id='ESC_SHAGRD'
                                                   and substr((select f_getspridenid(sorlcur_pidm) from dual),1,2)=zstpara_param_id
                                                   and zstpara_param_valor=sorlcur_levl_code) ;
         end if;

       if nivel not in ('MA','MS','DO') then
            select   nvl(sum(shrgrde_quality_points),0) , count(*) into p_equi, c_equi
              from   svrsvpr, svrsvad,smrpaap s, smrarul, smracaa,shrtrce, shrtrcr, shrgrde, smrprle, sgbstdn y
             where   svrsvpr_protocol_seq_no=soli
               and   svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
               and   svrsvad_addl_data_seq=1
               and   smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
               and   sgbstdn_pidm=svrsvpr_pidm
               AND  (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
               and   sgbstdn_program_1=smrpaap_program
               and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                              and     x.sgbstdn_program_1=y.sgbstdn_program_1)
               and   smrpaap_area=smrarul_area
               and   smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
               and    shrtrce_pidm=sgbstdn_pidm
               and    shrtrce_subj_code=smrarul_subj_code
               and    shrtrce_crse_numb=smrarul_crse_numb_low
               and    shrtrce_pidm=shrtrcr_pidm
               and    shrtrce_trit_seq_no=shrtrcr_trit_seq_no
               and    shrtrce_tram_seq_no=shrtrcr_tram_seq_no
               and    shrtrce_trcr_seq_no=shrtrcr_seq_no
               and    shrtrcr_program=smrpaap_program
               and    smrprle_program=smrpaap_program
               and    shrtrce_grde_code=shrgrde_code
               and    shrgrde_levl_code=smrprle_levl_code
               and    shrgrde_gpa_ind='Y'
--               and    shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
--                                                      where zstpara_mapa_id='ESC_SHAGRD'
--                                                        and substr((select f_getspridenid(sgbstdn_pidm) from dual),1,2)=zstpara_param_id
--                                                        and zstpara_param_valor=sgbstdn_levl_code)
               and    (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                         (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc)) or
                         (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)))
                          );
       else
            select   nvl(sum(shrgrde_quality_points),0) , count(*) into p_equi, c_equi
              from   svrsvpr, svrsvad,smrpaap s, smrarul, smracaa,shrtrce, shrtrcr, shrgrde, smrprle, sgbstdn y
             where   svrsvpr_protocol_seq_no=soli
               and   svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
               and   svrsvad_addl_data_seq=1
               and   smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
               and   sgbstdn_pidm=svrsvpr_pidm
               AND   (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                      substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
               and   sgbstdn_program_1=smrpaap_program
               and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                  where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                  and     x.sgbstdn_program_1=y.sgbstdn_program_1)
               and   smrpaap_area=smrarul_area
               and   smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  ('UTLMTI0101',
                                                                                                                                                                  'UTLLTE0101',
                                                                                                                                                                  'UTLLTI0101',
                                                                                                                                                                  'UTLLTS0101',
                                                                                                                                                                  'UTLLTT0110',
                                                                                                                                                                  'UOCATN0101',
                                                                                                                                                                  'UTSMTI0101',
                                                                                                                                                                  'UNAMPT0111',
                                                                                                                                                                  'UVEBTB0101',
                                                                                                                                                                  'UTLTSS0110')
               and  shrtrce_pidm=sgbstdn_pidm
               and  shrtrce_subj_code=smrarul_subj_code
               and  shrtrce_crse_numb=smrarul_crse_numb_low
               and  shrtrce_pidm=shrtrcr_pidm
               and  shrtrce_trit_seq_no=shrtrcr_trit_seq_no
               and  shrtrce_tram_seq_no=shrtrcr_tram_seq_no
               and  shrtrce_trcr_seq_no=shrtrcr_seq_no
               and  shrtrcr_program=smrpaap_program
               and  smrprle_program=smrpaap_program
               and  shrtrce_grde_code=shrgrde_code
               and  shrgrde_levl_code=smrprle_levl_code
               and  shrgrde_gpa_ind='Y'
               and  shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                  where zstpara_mapa_id='ESC_SHAGRD'
                                                    and substr((select f_getspridenid(sgbstdn_pidm) from dual),1,2)=zstpara_param_id
                                                    and zstpara_param_valor=sgbstdn_levl_code);
        end if;

            if (p_ord+p_equi) > 0 and (c_ord+c_equi) > 0 then
               prom:=round((p_ord+p_equi)/(c_ord+c_equi),1);
            else
               prom:=0;
             end if;

            SELECT baninst1.Numero_a_Texto (prom,01, 'ESP') into letras FROM DUAL;

return letras;

end promedio_letras;

function avance(soli number) return float is

ord    number;
equi  number;
avan decimal(6,2);
total  number;

begin

          select count(*) into total
            from svrsvpr, svrsvad,smrpaap s, smrarul, sgbstdn y
           where svrsvpr_protocol_seq_no=soli
             and svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
             and svrsvad_addl_data_seq=1
             and smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
             and sgbstdn_pidm=svrsvpr_pidm
             AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                    substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
             and smrpaap_area=smrarul_area
             and smrarul_area not in ('UTLMTI0101',
                                                      'UTLLTE0101',
                                                      'UTLLTI0101',
                                                      'UTLLTS0101',
                                                      'UTLLTT0110',
                                                      'UOCATN0101',
                                                      'UTSMTI0101',
                                                      'UNAMPT0111',
                                                      'UVEBTB0101',
                                                      'UTLTSS0110')
             and sgbstdn_program_1=smrpaap_program
             and sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                              and     x.sgbstdn_program_1=y.sgbstdn_program_1)
             and (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc)) or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)))
                          );

          select   count(*) into ord
          from  svrsvpr, svrsvad,smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x
           where    svrsvpr_protocol_seq_no=soli
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
           AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in  ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
           and     sorlcur_pidm=svrsvpr_pidm
           and     sorlcur_program=smrpaap_program
           and     sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ww
                                               where w.sorlcur_pidm=ww.sorlcur_pidm
                                               and     w.sorlcur_program=ww.sorlcur_program)
           and     shrtckn_pidm=sorlcur_pidm
           and     shrtckn_subj_code=smrarul_subj_code
           and     shrtckn_crse_numb=smrarul_crse_numb_low
           and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
           and     shrtckg_pidm=shrtckn_pidm
           and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
           and     shrtckg_grde_code_final=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y'
           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                  where zstpara_mapa_id='ESC_SHAGRD'
                                                    and substr((select f_getspridenid(sgbstdn_pidm) from dual),1,2)=zstpara_param_id
                                                    and zstpara_param_valor=sgbstdn_levl_code)
           and     sgbstdn_pidm=shrtckn_pidm
           and     sgbstdn_program_1=smrpaap_program
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and    x.sgbstdn_program_1=xx.sgbstdn_program_1)
           and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
            (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
            (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
           order by substr(smrarul_area,9,2);

            select   count(*) into equi
            from svrsvpr, svrsvad,smrpaap s, smrarul, smracaa,shrtrce, shrtrcr, shrgrde, smrprle, sgbstdn x
           where    svrsvpr_protocol_seq_no=soli
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
           AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
            and      smrpaap_area=smrarul_area
            and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
            and      shrtrce_pidm=svrsvpr_pidm
            and      shrtrce_subj_code=smrarul_subj_code
            and      shrtrce_crse_numb=smrarul_crse_numb_low
            and      shrtrce_pidm=shrtrcr_pidm
            and      shrtrce_trit_seq_no=shrtrcr_trit_seq_no
            and      shrtrce_tram_seq_no=shrtrcr_tram_seq_no
            and      shrtrce_trcr_seq_no=shrtrcr_seq_no
            and      shrtrcr_program=smrpaap_program
            and      shrtrce_grde_code=shrgrde_code
            and      smrprle_program=smrpaap_program
            and      shrgrde_levl_code=smrprle_levl_code
            and      shrgrde_passed_ind='Y'
            and      shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                  where zstpara_mapa_id='ESC_SHAGRD'
                                                    and substr((select f_getspridenid(sgbstdn_pidm) from dual),1,2)=zstpara_param_id
                                                    and zstpara_param_valor=sgbstdn_levl_code)
            and     sgbstdn_pidm=shrtrce_pidm
            and     sgbstdn_program_1=smrpaap_program
            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and    x.sgbstdn_program_1=xx.sgbstdn_program_1)
            and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
            (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
            (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
            order by substr(smrarul_area,9,2);

           if (ord+equi) > 0 and total > 0 then
               avan:=round((ord+equi) * 100 / total,2);
           else
               avan:=0;
           end if;

return avan;

end avance;

function avance1(pidm number,  prog varchar2) return float is

ord    number;
equi  number;
ec     number;
avan decimal(6,2);
total  number;
nivel  varchar2(2);
-- ajuste glovicx 05.07.2024
begin

          select smrprle_levl_code into nivel
          from smrprle
          where   smrprle_program=prog;

           if nivel not in ('MS','MA','DO') then

                    Begin
                       select  distinct SMBPGEN_REQ_COURSES_I_TRAD  into total from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMAPROG
                                                where SMBPGEN_program=prog
                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                            where  sorlcur_pidm=pidm
                                                                                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                    where ss.sorlcur_pidm=pidm
                                                                                                                                                       and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'));

                    Exception
                        When Others then
                        total :=0;
                    End;
          else
                    Begin
                       select  distinct SMBPGEN_REQ_COURSES_I_TRAD into total from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMAPROG
                                                where SMBPGEN_program=prog
                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                            where  sorlcur_pidm=pidm
                                                                                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                            where ss.sorlcur_pidm=pidm
                                                                                                               and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'));
                    Exception
                        When Others then
                        total :=0;
                    End;

          end if;

        if nivel not in ('MS','MA','DO') then

             if total >40 then
                     select   count(*)  into ord
                      from (
                     select   SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL)
                      from  smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x,smbagen
                      where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                  and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                                      where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
                      and       smrpaap_program= sorlcur_program
                      and       smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                      and       SMBAGEN_ACTIVE_IND='Y'   --solo areas activas  OLC
                      and       SMBAGEN_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF   --solo areas activas  OLC
                      and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                                           where s.smrpaap_program=sm.smrpaap_program
                                                                           and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
                       and      smrpaap_area=smrarul_area
                       and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                                      'UTLLTE0101',
                                                                                                                                                                      'UTLLTI0101',
                                                                                                                                                                      'UTLLTS0101',    --        'UTLLTT0110',
                                                                                                                                                                      'UOCATN0101',
                                                                                                                                                                      'UTSMTI0101',
                                                                                                                                                                      'UNAMPT0111',
                                                                                                                                                                      'UVEBTB0101',
                                                                                                                                                                      'UMMLAE0111',
                                                                                                                                                                      'UTLTSS0110',
                                                                                                                                                                      'COLLTT0110',
                                                                                                                                                                      'COLTSS0110',
                                                                                                                                                                      'PERLTT0110',
                                                                                                                                                                      'PERTSS0110')
                       and     shrtckn_pidm=sorlcur_pidm
                       and     shrtckn_subj_code=smrarul_subj_code
                       and     shrtckn_crse_numb=smrarul_crse_numb_low
                       and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
                       and     shrtckg_pidm=shrtckn_pidm
                       and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
                       and     shrtckg_grde_code_final=shrgrde_code
                       and     smrprle_program=smrpaap_program
                       and     shrgrde_levl_code=smrprle_levl_code
                       and     shrgrde_passed_ind='Y'
--                       and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
                       and     sgbstdn_pidm=shrtckn_pidm
                       and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                        where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                                        and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
                        and  ( (smrarul_area not in (select smriecc_area from smriecc)) or
                        (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
                        (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
                       group by SHRTCKN_PIDM,
                                    SHRTCKN_SUBJ_CODE,
                                    SHRTCKN_CRSE_NUMB ,
                                    SHRTCKN_STSP_KEY_SEQUENCE
                        order by 2 );
             else
                 select   count(*)  into ord
                  from (
                 select   SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL)
                  from  smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x,smbagen
                  where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                              and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                                  where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
                  and       smrpaap_program= sorlcur_program
                  and       smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                  and       SMBAGEN_ACTIVE_IND='Y'   --solo areas activas  OLC
                  and       SMBAGEN_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF   --solo areas activas  OLC
                  and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                                       where s.smrpaap_program=sm.smrpaap_program
                                                                       and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
                   and      smrpaap_area=smrarul_area
                   and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                                  'UTLLTE0101',
                                                                                                                                                                  'UTLLTI0101',
                                                                                                                                                                  'UTLLTS0101',
                                                                                                                                                                  'UTLLTT0110',
                                                                                                                                                                  'UOCATN0101',
                                                                                                                                                                  'UTSMTI0101',
                                                                                                                                                                  'UNAMPT0111',
                                                                                                                                                                  'UVEBTB0101',
                                                                                                                                                                  'UMMLAE0111',
                                                                                                                                                                  'UTLTSS0110',
                                                                                                                                                                  'COLLTT0110',
                                                                                                                                                                  'COLTSS0110',
                                                                                                                                                                  'PERLTT0110',
                                                                                                                                                                  'PERTSS0110')
                   and     shrtckn_pidm=sorlcur_pidm
                   and     shrtckn_subj_code=smrarul_subj_code
                   and     shrtckn_crse_numb=smrarul_crse_numb_low
                   and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
                   and     shrtckg_pidm=shrtckn_pidm
                   and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
                   and     shrtckg_grde_code_final=shrgrde_code
                   and     smrprle_program=smrpaap_program
                   and     shrgrde_levl_code=smrprle_levl_code
                   and     shrgrde_passed_ind='Y'
--                   and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
                   and     sgbstdn_pidm=shrtckn_pidm
                   and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                    where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                                    and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
                    and  ( (smrarul_area not in (select smriecc_area from smriecc)) or
                    (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
                    (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
                   group by SHRTCKN_PIDM,
                                SHRTCKN_SUBJ_CODE,
                                SHRTCKN_CRSE_NUMB ,
                                SHRTCKN_STSP_KEY_SEQUENCE
                    order by 2 );
             end if;
        else
           Select count (*) into ord
            from (
          select   SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL)
          from  smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x,smbagen
          where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                          where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
          and       smrpaap_program= sorlcur_program
          and       smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
          and       SMBAGEN_ACTIVE_IND='Y'   --solo areas activas  OLC
          and       SMBAGEN_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF   --solo areas activas  OLC
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UMMLAE0111',
                                                                                                                                                              'UTLTSS0110',
                                                                                                                                                              'COLLTT0110',
                                                                                                                                                              'COLTSS0110',
                                                                                                                                                              'PERLTT0110',
                                                                                                                                                              'PERTSS0110')
           and     shrtckn_pidm=sorlcur_pidm
           and     shrtckn_subj_code=smrarul_subj_code
           and     shrtckn_crse_numb=smrarul_crse_numb_low
           and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
           and     shrtckg_pidm=shrtckn_pidm
           and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
           and     shrtckg_grde_code_final=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y'
           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
           and     sgbstdn_pidm=shrtckn_pidm
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
           group by SHRTCKN_PIDM,
                        SHRTCKN_SUBJ_CODE,
                        SHRTCKN_CRSE_NUMB ,
                        SHRTCKN_STSP_KEY_SEQUENCE
            order by 2 ) ;
        end if;


         if nivel not in ('MS','MA','DO') then
         select   count(*) into ec
          from  smrpaap s, smrarul, smracaa , sorlcur w, sgbstdn x, sfrstcr, ssbsect, shrgrde,  smrprle
          where   sorlcur_pidm=pidm and sorlcur_program=prog  and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                          where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
          and       smrpaap_program= sorlcur_program
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
--                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UMMLAE0111',
                                                                                                                                                              'UTLTSS0110',
--                                                                                                                                                              'COLLTT0110',
                                                                                                                                                              'COLTSS0110',
--                                                                                                                                                              'PERLTT0110',
                                                                                                                                                              'PERTSS0110')
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm)
           and    (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code  IN ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                                                and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and cu.sorlcur_pidm = pidm
                                                                                                and cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and ss.SORLFOS_LFST_CODE = 'MAJOR'--CONCENTRATION
                                                                                                and cu.SORLCUR_CACT_CODE = ss.SORLFOS_CACT_CODE
                                                                                                and cu.sorlcur_program   = prog
                                                                                                AND CU.SORLCUR_SEQNO = (SELECT MAX (CU1.SORLCUR_SEQNO) --- nuevo filtro glovicx 05072024
                                                                                                                            FROM SORLCUR CU1
                                                                                                                            WHERE 1=1
                                                                                                                            AND cu1.sorlcur_pidm = cu.sorlcur_pidm
                                                                                                                            AND cu1.sorlcur_lmod_code = cu.sorlcur_lmod_code)
                                                                                                                         )    )
                                                   and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                                                and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and cu.sorlcur_pidm = pidm
                                                                                                and cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and ss.SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                                                                and cu.SORLCUR_CACT_CODE = ss.SORLFOS_CACT_CODE
                                                                                                and cu.sorlcur_program   = prog
                                                                                                AND CU.SORLCUR_SEQNO = (SELECT MAX (CU1.SORLCUR_SEQNO) --- nuevo filtro glovicx 05072024
                                                                                                                            FROM SORLCUR CU1
                                                                                                                            WHERE 1=1
                                                                                                                            AND cu1.sorlcur_pidm = cu.sorlcur_pidm
                                                                                                                            AND cu1.sorlcur_lmod_code = cu.sorlcur_lmod_code)
                                                                                                 ) )) )
--           and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
--                (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
--                (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
           and     sgbstdn_pidm=sfrstcr_pidm
           and     sorlcur_pidm=sfrstcr_pidm
           and     sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and sfrstcr_crn=shrtckn_crn) and sfrstcr_grde_code is not null
           and     sfrstcr_rsts_code='RE'
           and     ssbsect_term_code=sfrstcr_term_code and ssbsect_crn=sfrstcr_crn
           and     ssbsect_subj_code=smrarul_subj_code
           and     ssbsect_crse_numb=smrarul_crse_numb_low
           and     sfrstcr_stsp_key_sequence=sorlcur_key_seqno
           and     sfrstcr_grde_code=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y';
--           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code) ;
         else
             select   count(*) into ec
              from  smrpaap s, smrarul, smracaa , sorlcur w, sgbstdn x, sfrstcr, ssbsect, shrgrde,  smrprle
              where   sorlcur_pidm=pidm and sorlcur_program=prog  and sorlcur_lmod_code='LEARNER'
                          and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                              where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
              and       smrpaap_program= sorlcur_program
              and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                                   where s.smrpaap_program=sm.smrpaap_program
                                                                   and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
               and      smrpaap_area=smrarul_area
               and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UMMLAE0111',
                                                                                                                                                              'UTLTSS0110',
                                                                                                                                                              'COLLTT0110',
                                                                                                                                                              'COLTSS0110',
                                                                                                                                                              'PERLTT0110',
                                                                                                                                                              'PERTSS0110')
               and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                where x.sgbstdn_pidm=xx.sgbstdn_pidm)
               and     sgbstdn_pidm=sfrstcr_pidm
               and     sorlcur_pidm=sfrstcr_pidm
               and     sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and sfrstcr_crn=shrtckn_crn) and sfrstcr_grde_code is not null
               and     sfrstcr_rsts_code='RE'
               and     ssbsect_term_code=sfrstcr_term_code and ssbsect_crn=sfrstcr_crn
               and     ssbsect_subj_code=smrarul_subj_code
               and     ssbsect_crse_numb=smrarul_crse_numb_low
               and     sfrstcr_stsp_key_sequence=sorlcur_key_seqno
               and     sfrstcr_grde_code=shrgrde_code
               and     smrprle_program=smrpaap_program
               and     shrgrde_levl_code=smrprle_levl_code
               and     shrgrde_passed_ind='Y'
               and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)  ;
         end if;

         if nivel not in ('MS','MA','DO') then
          select   count(*) into equi
          from  smrpaap s, smrarul, smracaa, shrtrce, shrtrcr, shrgrde, sorlcur w, smrprle, sgbstdn x,smbagen
          where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                          where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
          and       smrpaap_program= sorlcur_program
          and       smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
          and       SMBAGEN_ACTIVE_IND='Y'            --solo areas activas  OLC
          and       SMBAGEN_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF    --solo areas activas  OLC
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
--                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UMMLAE0111',
                                                                                                                                                              'UTLTSS0110',
--                                                                                                                                                              'COLLTT0110',
                                                                                                                                                              'COLTSS0110',
--                                                                                                                                                              'PERLTT0110',
                                                                                                                                                              'PERTSS0110')
           and     shrtrce_pidm=sorlcur_pidm
           and     shrtrce_subj_code=smrarul_subj_code
           and     shrtrce_crse_numb=smrarul_crse_numb_low
           and     shrtrce_pidm=shrtrcr_pidm
           and     shrtrce_trit_seq_no=shrtrcr_trit_seq_no
           and     shrtrce_tram_seq_no=shrtrcr_tram_seq_no
           and     shrtrce_trcr_seq_no=shrtrcr_seq_no
           and     shrtrcr_program=smrpaap_program
           and     shrtrce_grde_code=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y'
--           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
           and     sgbstdn_pidm=shrtrce_pidm
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
                      and    (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.sorlcur_pidm = pidm
                                                                                                and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   ss.SORLFOS_LFST_CODE = 'MAJOR'--CONCENTRATION
                                                                                                and   cu.SORLCUR_CACT_CODE = ss.SORLFOS_CACT_CODE
                                                                                                and   cu.sorlcur_program   = prog
                                                                                                AND CU.SORLCUR_SEQNO = (SELECT MAX (CU1.SORLCUR_SEQNO) --- nuevo filtro glovicx 05072024
                                                                                                                            FROM SORLCUR CU1
                                                                                                                            WHERE 1=1
                                                                                                                            AND cu1.sorlcur_pidm = cu.sorlcur_pidm
                                                                                                                            AND cu1.sorlcur_lmod_code = cu.sorlcur_lmod_code)
                                                                                           )    )
                                                   and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.sorlcur_pidm = pidm
                                                                                                and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   ss.SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                                                                and   cu.SORLCUR_CACT_CODE = ss.SORLFOS_CACT_CODE
                                                                                                and   cu.sorlcur_program   = prog
                                                                                                AND CU.SORLCUR_SEQNO = (SELECT MAX (CU1.SORLCUR_SEQNO) --- nuevo filtro glovicx 05072024
                                                                                                                            FROM SORLCUR CU1
                                                                                                                            WHERE 1=1
                                                                                                                            AND cu1.sorlcur_pidm = cu.sorlcur_pidm
                                                                                                                            AND cu1.sorlcur_lmod_code = cu.sorlcur_lmod_code)
                                                                                                 ) )) )
--           and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
--                (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
--                (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
           order by substr(smrarul_area,9,2);
         else
          select   count(*) into equi
          from  smrpaap s, smrarul, smracaa, shrtrce, shrtrcr, shrgrde, sorlcur w, smrprle, sgbstdn x
          where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                          where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
          and       smrpaap_program= sorlcur_program
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UMMLAE0111',
                                                                                                                                                              'UTLTSS0110',
                                                                                                                                                              'COLLTT0110',
                                                                                                                                                              'COLTSS0110',
                                                                                                                                                              'PERLTT0110',
                                                                                                                                                              'PERTSS0110')
           and     shrtrce_pidm=sorlcur_pidm
           and     shrtrce_subj_code=smrarul_subj_code
           and     shrtrce_crse_numb=smrarul_crse_numb_low
           and     shrtrce_pidm=shrtrcr_pidm
           and     shrtrce_trit_seq_no=shrtrcr_trit_seq_no
           and     shrtrce_tram_seq_no=shrtrcr_tram_seq_no
           and     shrtrce_trcr_seq_no=shrtrcr_seq_no
           and     shrtrcr_program=smrpaap_program
           and     shrtrce_grde_code=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y'
           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
           and     sgbstdn_pidm=shrtrce_pidm
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
           order by substr(smrarul_area,9,2);
         end if;


           if (ord+equi+ec) > 0 and total > 0 then
               avan:=round((ord+equi+ec) * 100 / total,2);
           else
               avan:=0;
           end if;

return avan;

end avance1;

function avance2(pidm number,  prog varchar2) return float is

ord    number;
equi  number;
ec     number;
avan2 decimal(6,2);
total  number;
nivel  varchar2(2);

begin

          select smrprle_levl_code into nivel
          from smrprle
          where   smrprle_program=prog;

           if nivel not in ('MS','MA','DO') then

                    Begin
                       select  distinct  SMBPGEN_REQ_COURSES_INST into total from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMAPROG    SMBPGEN_REQ_COURSES_INST

                                                where SMBPGEN_program=prog
                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                            where  sorlcur_pidm=pidm
                                                                                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                            where ss.sorlcur_pidm=pidm
                                                                                                               and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'));

                    Exception
                        When Others then
                        total :=0;
                    End;
          else

                    Begin
                       select  distinct SMBPGEN_REQ_COURSES_I_TRAD into total from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMAPROG   SMBPGEN_REQ_COURSES_INST
                                                where SMBPGEN_program=prog
                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                            where  sorlcur_pidm=pidm
                                                                                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                            where ss.sorlcur_pidm=pidm
                                                                                                               and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'));
                    Exception
                        When Others then
                        total :=0;
                    End;

          end if;

        if nivel not in ('MS','MA','DO') then
              select   count(*)
               into ord
              from (
             select   SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL)
              from  smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x
              where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                          and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                              where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
              and       smrpaap_program= sorlcur_program
              and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                                   where s.smrpaap_program=sm.smrpaap_program
                                                                   and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
               and      smrpaap_area=smrarul_area
               and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
--                                                                                                                        and  smracaa_area not in ('UTLMTI0101',
--                                                                                                                                                              'UTLLTE0101',
--                                                                                                                                                              'UTLLTI0101',
--                                                                                                                                                              'UTLLTS0101',
--                                                                                                                                                              'UTLLTT0110',
--                                                                                                                                                              'UOCATN0101',
--                                                                                                                                                              'UTSMTI0101',
--                                                                                                                                                              'UNAMPT0111',
--                                                                                                                                                              'UVEBTB0101',
--                                                                                                                                                              'UMMLAE0111')
               and     shrtckn_pidm=sorlcur_pidm
               and     shrtckn_subj_code=smrarul_subj_code
               and     shrtckn_crse_numb=smrarul_crse_numb_low
               and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
               and     shrtckg_pidm=shrtckn_pidm
               and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
               and     shrtckg_grde_code_final=shrgrde_code
               and     smrprle_program=smrpaap_program
               and     shrgrde_levl_code=smrprle_levl_code
               and     shrgrde_passed_ind='Y'
--               and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code)
               and     sgbstdn_pidm=shrtckn_pidm
               and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                where x.sgbstdn_pidm=xx.sgbstdn_pidm)
                and  ( (smrarul_area not in (select smriecc_area from smriecc)) or
                (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
                (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
               group by SHRTCKN_PIDM,
                            SHRTCKN_SUBJ_CODE,
                            SHRTCKN_CRSE_NUMB ,
                            SHRTCKN_STSP_KEY_SEQUENCE
                order by 2 );
        else
           Select count (*)
           into ord
            from (
          select   SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL)
          from  smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x
          where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                          where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
          and       smrpaap_program= sorlcur_program
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
--                                                                                                                       and  smracaa_area not in ('UTLMTI0101',
--                                                                                                                                                              'UTLLTE0101',
--                                                                                                                                                              'UTLLTI0101',
--                                                                                                                                                              'UTLLTS0101',
--                                                                                                                                                              'UTLLTT0110',
--                                                                                                                                                              'UOCATN0101',
--                                                                                                                                                              'UTSMTI0101',
--                                                                                                                                                              'UNAMPT0111',
--                                                                                                                                                              'UVEBTB0101',
--                                                                                                                                                              'UMMLAE0111')
           and     shrtckn_pidm=sorlcur_pidm
           and     shrtckn_subj_code=smrarul_subj_code
           and     shrtckn_crse_numb=smrarul_crse_numb_low
           and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
           and     shrtckg_pidm=shrtckn_pidm
           and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
           and     shrtckg_grde_code_final=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y'
           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code)
           and     sgbstdn_pidm=shrtckn_pidm
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm)
           group by SHRTCKN_PIDM,
                        SHRTCKN_SUBJ_CODE,
                        SHRTCKN_CRSE_NUMB ,
                        SHRTCKN_STSP_KEY_SEQUENCE
            order by 2 ) ;
        end if;

         if nivel not in ('MS','MA','DO') then
         select   count(*) into ec
          from  smrpaap s, smrarul, smracaa , sorlcur w, sgbstdn x, sfrstcr, ssbsect, shrgrde,  smrprle
          where   sorlcur_pidm=pidm and sorlcur_program=prog  and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                          where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
          and       smrpaap_program= sorlcur_program
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
--                                                                                                                       and  smracaa_area not in ('UTLMTI0101',
--                                                                                                                                                              'UTLLTE0101',
--                                                                                                                                                              'UTLLTI0101',
--                                                                                                                                                              'UTLLTS0101',
--                                                                                                                                                              'UTLLTT0110',
--                                                                                                                                                              'UOCATN0101',
--                                                                                                                                                              'UTSMTI0101',
--                                                                                                                                                              'UNAMPT0111',
--                                                                                                                                                              'UVEBTB0101',
--                                                                                                                                                              'UMMLAE0111')
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm)
           and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
                (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
                (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
           and     sgbstdn_pidm=sfrstcr_pidm
           and     sorlcur_pidm=sfrstcr_pidm
           and     sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and sfrstcr_crn=shrtckn_crn) and sfrstcr_grde_code is not null
           and     sfrstcr_rsts_code='RE'
           and     ssbsect_term_code=sfrstcr_term_code and ssbsect_crn=sfrstcr_crn
           and     ssbsect_subj_code=smrarul_subj_code
           and     ssbsect_crse_numb=smrarul_crse_numb_low
           and     sfrstcr_stsp_key_sequence=sorlcur_key_seqno
           and     sfrstcr_grde_code=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y';
--           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code);
         else
             select   count(*) into ec
              from  smrpaap s, smrarul, smracaa , sorlcur w, sgbstdn x, sfrstcr, ssbsect, shrgrde,  smrprle
              where   sorlcur_pidm=pidm and sorlcur_program=prog  and sorlcur_lmod_code='LEARNER'
                          and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                              where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
              and       smrpaap_program= sorlcur_program
              and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                                   where s.smrpaap_program=sm.smrpaap_program
                                                                   and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
               and      smrpaap_area=smrarul_area
               and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
--                                                                                                                        and  smracaa_area not in ('UTLMTI0101',
--                                                                                                                                                              'UTLLTE0101',
--                                                                                                                                                              'UTLLTI0101',
--                                                                                                                                                              'UTLLTS0101',
--                                                                                                                                                              'UTLLTT0110',
--                                                                                                                                                              'UOCATN0101',
--                                                                                                                                                              'UTSMTI0101',
--                                                                                                                                                              'UNAMPT0111',
--                                                                                                                                                              'UVEBTB0101',
--                                                                                                                                                              'UMMLAE0111')
               and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                where x.sgbstdn_pidm=xx.sgbstdn_pidm)
               and     sgbstdn_pidm=sfrstcr_pidm
               and     sorlcur_pidm=sfrstcr_pidm
               and     sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and sfrstcr_crn=shrtckn_crn) and sfrstcr_grde_code is not null
               and     sfrstcr_rsts_code='RE'
               and     ssbsect_term_code=sfrstcr_term_code and ssbsect_crn=sfrstcr_crn
               and     ssbsect_subj_code=smrarul_subj_code
               and     ssbsect_crse_numb=smrarul_crse_numb_low
               and     sfrstcr_stsp_key_sequence=sorlcur_key_seqno
               and     sfrstcr_grde_code=shrgrde_code
               and     smrprle_program=smrpaap_program
               and     shrgrde_levl_code=smrprle_levl_code
               and     shrgrde_passed_ind='Y'
               and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code);
         end if;

         if nivel not in ('MS','MA','DO') then
          select   count(*) into equi
          from  smrpaap s, smrarul, smracaa, shrtrce, shrtrcr, shrgrde, sorlcur w, smrprle, sgbstdn x
          where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                          where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
          and       smrpaap_program= sorlcur_program
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
--                                                                                                                       and  smracaa_area not in ('UTLMTI0101',
--                                                                                                                                                              'UTLLTE0101',
--                                                                                                                                                              'UTLLTI0101',
--                                                                                                                                                              'UTLLTS0101',
--                                                                                                                                                              'UTLLTT0110',
--                                                                                                                                                              'UOCATN0101',
--                                                                                                                                                              'UTSMTI0101',
--                                                                                                                                                              'UNAMPT0111',
--                                                                                                                                                              'UVEBTB0101',
--                                                                                                                                                              'UMMLAE0111')
           and     shrtrce_pidm=sorlcur_pidm
           and     shrtrce_subj_code=smrarul_subj_code
           and     shrtrce_crse_numb=smrarul_crse_numb_low
           and     shrtrce_pidm=shrtrcr_pidm
           and     shrtrce_trit_seq_no=shrtrcr_trit_seq_no
           and     shrtrce_tram_seq_no=shrtrcr_tram_seq_no
           and     shrtrce_trcr_seq_no=shrtrcr_seq_no
           and     shrtrcr_program=smrpaap_program
           and     shrtrce_grde_code=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y'
--           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code)
           and     sgbstdn_pidm=shrtrce_pidm
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm)
           and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
                (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
                (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
           order by substr(smrarul_area,9,2);
         else
          select   count(*) into equi
          from  smrpaap s, smrarul, smracaa, shrtrce, shrtrcr, shrgrde, sorlcur w, smrprle, sgbstdn x
          where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                      and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                          where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
          and       smrpaap_program= sorlcur_program
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
--                                                                                                                       and  smracaa_area not in ('UTLMTI0101',
--                                                                                                                                                              'UTLLTE0101',
--                                                                                                                                                              'UTLLTI0101',
--                                                                                                                                                              'UTLLTS0101',
--                                                                                                                                                              'UTLLTT0110',
--                                                                                                                                                              'UOCATN0101',
--                                                                                                                                                              'UTSMTI0101',
--                                                                                                                                                              'UNAMPT0111',
--                                                                                                                                                              'UVEBTB0101',
--                                                                                                                                                              'UMMLAE0111')
           and     shrtrce_pidm=sorlcur_pidm
           and     shrtrce_subj_code=smrarul_subj_code
           and     shrtrce_crse_numb=smrarul_crse_numb_low
           and     shrtrce_pidm=shrtrcr_pidm
           and     shrtrce_trit_seq_no=shrtrcr_trit_seq_no
           and     shrtrce_tram_seq_no=shrtrcr_tram_seq_no
           and     shrtrce_trcr_seq_no=shrtrcr_seq_no
           and     shrtrcr_program=smrpaap_program
           and     shrtrce_grde_code=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y'
           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code)
           and     sgbstdn_pidm=shrtrce_pidm
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm)
           order by substr(smrarul_area,9,2);
         end if;


           if (ord+equi+ec) > 0 and total > 0 then
               avan2:=round((ord+equi+ec) * 100 / total,2);
           else
               avan2:=0;
           end if;

return avan2;

end avance2;

function avance_historia(pidm number,  prog varchar2) return float is

ord    number;
equi  number;
ec     number;
avan decimal(6,2);
total  number;
nivel  varchar2(2);

begin

          select smrprle_levl_code into nivel
          from smrprle
          where   smrprle_program=prog;

dbms_output.put_line(' nivel:'||nivel);

           if nivel not in ('MS','MA','DO') then

                    Begin
                       select  distinct SMBPGEN_REQ_COURSES_I_TRAD  into total  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMAPROG
                                                where SMBPGEN_program=prog
                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                            where  sorlcur_pidm=pidm
                                                                                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                        where ss.sorlcur_pidm=pidm
                                                                                                                                                           and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'));
                    Exception
                        When Others then
                        total :=0;
                    End;
          else
                    Begin
                       select  distinct SMBPGEN_REQ_COURSES_I_TRAD into total from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMAPROG
                                                where SMBPGEN_program=prog
                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                            where  sorlcur_pidm=pidm
                                                                                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                        where ss.sorlcur_pidm=pidm
                                                                                                                                                           and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'));
                    Exception
                        When Others then
                        total :=0;
                    End;

          end if;

dbms_output.put_line(' total:'||total);

        if nivel not in ('MS','MA','DO') then

             if total >40 then
                     select   count(*) into ord
                      from (
                     select   SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL)
                      from  smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x,smbagen
                      where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                  and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                                      where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)
                      and       smrpaap_program= sorlcur_program
                      and       smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                      and       SMBAGEN_ACTIVE_IND='Y'   --solo areas activas  OLC
                      and       SMBAGEN_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF   --solo areas activas  OLC
                      and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                                           where s.smrpaap_program=sm.smrpaap_program
                                                                           and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
                       and      smrpaap_area=smrarul_area
                       and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
                       and  smracaa_area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2) not in ('TT','TC') )
                       and     shrtckn_pidm=sorlcur_pidm
                       and     shrtckn_subj_code=smrarul_subj_code
                       and     shrtckn_crse_numb=smrarul_crse_numb_low
                       and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
                       and     shrtckg_pidm=shrtckn_pidm
                       and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
                       and     shrtckg_grde_code_final=shrgrde_code
                       and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                                 and sorlcur_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                       and     smrprle_program=smrpaap_program
                       and     shrgrde_levl_code=smrprle_levl_code
                       and     shrgrde_passed_ind='Y'
--                       and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
                       and     sgbstdn_pidm=shrtckn_pidm
                       and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                        where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                                                 and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
                       and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
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
                                                                                                                                                                                  and ss.sorlcur_program =prog )
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)   ----- CAMBIO  DEL AVANCE CURRICULAR
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                             and smrarul_area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )
--                        and  ( (smrarul_area not in (select smriecc_area from smriecc)) or
--                        (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
--                        (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
                       group by SHRTCKN_PIDM,
                                    SHRTCKN_SUBJ_CODE,
                                    SHRTCKN_CRSE_NUMB ,
                                    SHRTCKN_STSP_KEY_SEQUENCE
                        order by 2 );
             else
                 select   count(*)  into ord
                  from (
                 select  SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL)
                   from  smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x,smbagen
                  where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                              and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                                  where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)
                   and    smrpaap_program= sorlcur_program
                   and    smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                   and    SMBAGEN_ACTIVE_IND='Y'   --solo areas activas  OLC
                   and    SMBAGEN_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF   --solo areas activas  OLC
                   and    smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                     where s.smrpaap_program=sm.smrpaap_program
                                                       and sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
                   and    smrpaap_area=smrarul_area
                   and    smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' )
                   and    shrtckn_pidm=sorlcur_pidm
                   and    shrtckn_subj_code=smrarul_subj_code
                   and    shrtckn_crse_numb=smrarul_crse_numb_low
                   and    shrtckn_stsp_key_sequence=sorlcur_key_seqno
                   and    shrtckg_pidm=shrtckn_pidm
                   and    shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
                   and    shrtckg_grde_code_final=shrgrde_code
                   and    SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                   and sorlcur_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                   and    smrprle_program=smrpaap_program
                   and    shrgrde_levl_code=smrprle_levl_code
                   and    shrgrde_passed_ind='Y'
--                   and    shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
                   and    sgbstdn_pidm=shrtckn_pidm
                   and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                     where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                       and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
                   and  ( (smrarul_area not in (select smriecc_area from smriecc)) or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
                   group by SHRTCKN_PIDM,
                                SHRTCKN_SUBJ_CODE,
                                SHRTCKN_CRSE_NUMB ,
                                SHRTCKN_STSP_KEY_SEQUENCE
                    order by 2 );
             end if;
        else
           Select count (*) into ord
            from (
                  select   SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL)
                  from  smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x,smbagen
                  where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                              and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                                  where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)
                   and     smrpaap_program= sorlcur_program
                   and     smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                   and     SMBAGEN_ACTIVE_IND='Y'   --solo areas activas  OLC
                   and     SMBAGEN_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF   --solo areas activas  OLC
                   and     smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                                       where s.smrpaap_program=sm.smrpaap_program
                                                                       and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
                   and     smrpaap_area=smrarul_area
                   and     smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2) not in ('TT','TC'))
                   and     shrtckn_pidm=sorlcur_pidm
                   and     shrtckn_subj_code=smrarul_subj_code
                   and     shrtckn_crse_numb=smrarul_crse_numb_low
                   and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
                   and     shrtckg_pidm=shrtckn_pidm
                   and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
                   and     shrtckg_grde_code_final=shrgrde_code
                   and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                           and sorlcur_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                   and     smrprle_program=smrpaap_program
                   and     shrgrde_levl_code=smrprle_levl_code
                   and     shrgrde_passed_ind='Y'
                   and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
                   and     sgbstdn_pidm=shrtckn_pidm
                   and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                    where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                                    and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
                   group by SHRTCKN_PIDM,
                                SHRTCKN_SUBJ_CODE,
                                SHRTCKN_CRSE_NUMB ,
                                SHRTCKN_STSP_KEY_SEQUENCE
                   order by 2 ) ;
        end if;

dbms_output.put_line(' ord:'||ord);

         if nivel not in ('MS','MA','DO') then
                  select   count(*) into equi
                  from  smrpaap s, smrarul, smracaa, shrtrce, shrtrcr, shrgrde, sorlcur w, smrprle, sgbstdn x,smbagen
                  where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                              and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                                  where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
                   and    smrpaap_program= sorlcur_program
                   and    smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                   and    SMBAGEN_ACTIVE_IND='Y'            --solo areas activas  OLC
                   and    SMBAGEN_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF    --solo areas activas  OLC
                   and    smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                                       where s.smrpaap_program=sm.smrpaap_program
                                                                       and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
                   and    smrpaap_area=smrarul_area
                   and    smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule
                   and    smracaa_area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2) not in ('TT','TC') )
                   and    shrtrce_pidm=sorlcur_pidm
                   and    shrtrce_subj_code=smrarul_subj_code
                   and    shrtrce_crse_numb=smrarul_crse_numb_low
                   and    shrtrce_pidm=shrtrcr_pidm
                   and    shrtrce_trit_seq_no=shrtrcr_trit_seq_no
                   and    shrtrce_tram_seq_no=shrtrcr_tram_seq_no
                   and    shrtrce_trcr_seq_no=shrtrcr_seq_no
                   and    shrtrcr_program=smrpaap_program
                   and    shrtrce_grde_code=shrgrde_code
                   and    smrprle_program=smrpaap_program
                   and    shrgrde_levl_code=smrprle_levl_code
                   and    shrgrde_passed_ind='Y'
--                   and    shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code)
                   and    sgbstdn_pidm=shrtrce_pidm
                   and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                    where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                                    and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
                              and    (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                               (smrarul_area in (select smriemj_area from smriemj
                                                                       where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                      where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                        and   cu.sorlcur_pidm =pidm
                                                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                        and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                        and   sorlcur_program   =prog
                                                                                                   )    )
                                                           and smrarul_area not in (select smriecc_area from smriecc)) or
                                                             (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                 ( select distinct SORLFOS_MAJR_CODE
                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                      where cu.sorlcur_pidm = Ss.SORLfos_PIDM
                                                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                        and   cu.sorlcur_pidm =pidm
                                                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                        and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                        and   sorlcur_program   =prog
                                                                                                         ) )) )
        --           and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
        --                (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
        --                (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
                   order by substr(smrarul_area,9,2);
         else
                 select   count(*) into equi
                  from  smrpaap s, smrarul, smracaa, shrtrce, shrtrcr, shrgrde, sorlcur w, smrprle, sgbstdn x,smbagen
                  where   sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                              and sorlcur_seqno in ( select max(sorlcur_seqno) from sorlcur ww
                                                  where w.sorlcur_pidm=ww.sorlcur_pidm and w.sorlcur_program=ww.sorlcur_program and w.sorlcur_lmod_code=ww.sorlcur_lmod_code)  -- and sorlcur_roll_ind='Y'
                  and       smrpaap_program= sorlcur_program
                  and       smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                  and       SMBAGEN_ACTIVE_IND='Y'            --solo areas activas  OLC
                  and       SMBAGEN_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF    --solo areas activas  OLC
                  and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                                       where s.smrpaap_program=sm.smrpaap_program
                                                                       and     sm.smrpaap_term_code_eff <= sorlcur_term_code_ctlg)
                   and      smrpaap_area=smrarul_area
                   and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                   and     shrtrce_pidm=sorlcur_pidm
                   and     shrtrce_subj_code=smrarul_subj_code
                   and     shrtrce_crse_numb=smrarul_crse_numb_low
                   and      shrtrce_pidm=shrtrcr_pidm
                   and      shrtrce_trit_seq_no=shrtrcr_trit_seq_no
                   and      shrtrce_tram_seq_no=shrtrcr_tram_seq_no
                   and      shrtrce_trcr_seq_no=shrtrcr_seq_no
                   and      shrtrcr_program=smrpaap_program
                   and      shrtrce_grde_code=shrgrde_code
                   and     smrprle_program=smrpaap_program
                   and     shrgrde_levl_code=smrprle_levl_code
                   and     shrgrde_passed_ind='Y'
                   and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=w.sorlcur_levl_code)
                   and     sgbstdn_pidm=shrtrce_pidm
                   and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                    where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                                    and xx.SGBSTDN_PROGRAM_1=sorlcur_program)
                   order by substr(smrarul_area,9,2);

                 end if;

dbms_output.put_line(' equi:'||equi);

                   if (ord+equi) > 0 and total > 0 then
                       avan:=round((ord+equi)*100 / total,2);
                   else
                       avan:=0;
                   end if;

return avan;

end avance_historia;

function acreditadas(soli number) return float is

a_ord number;
a_equi number;
acred decimal(6,2);

begin

          select   count(*) into a_ord
          from  svrsvpr, svrsvad,smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x
           where    svrsvpr_protocol_seq_no=soli
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
           AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
           and     sorlcur_pidm=svrsvpr_pidm
           and     sorlcur_program=smrpaap_program
           and     sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ww
                                               where w.sorlcur_pidm=ww.sorlcur_pidm
                                               and     w.sorlcur_program=ww.sorlcur_program)
           and     shrtckn_pidm=sorlcur_pidm
           and     shrtckn_subj_code=smrarul_subj_code
           and     shrtckn_crse_numb=smrarul_crse_numb_low
           and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
           and     shrtckg_pidm=shrtckn_pidm
           and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckn_term_code=shrtckg_term_code
           and     shrtckg_grde_code_final=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y'
           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(sorlcur_pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code)
           and     sgbstdn_pidm=shrtckn_pidm
           and     sgbstdn_program_1=smrpaap_program
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and    x.sgbstdn_program_1=xx.sgbstdn_program_1)
           and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
            (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
            (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
           order by substr(smrarul_area,9,2);

            select   count(*) into a_equi
            from svrsvpr, svrsvad,smrpaap s, smrarul, smracaa,shrtrce, shrtrcr, shrgrde, smrprle, sgbstdn x
           where    svrsvpr_protocol_seq_no=soli
            and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
            and        svrsvad_addl_data_seq=1
            and       smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
            AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
            and      smrpaap_area=smrarul_area
            and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
            and      shrtrce_pidm=svrsvpr_pidm
            and      shrtrce_subj_code=smrarul_subj_code
            and      shrtrce_crse_numb=smrarul_crse_numb_low
            and      shrtrce_pidm=shrtrcr_pidm
            and      shrtrce_trit_seq_no=shrtrcr_trit_seq_no
            and      shrtrce_tram_seq_no=shrtrcr_tram_seq_no
            and      shrtrce_trcr_seq_no=shrtrcr_seq_no
            and      shrtrcr_program=smrpaap_program
            and      shrtrce_grde_code=shrgrde_code
            and      smrprle_program=smrpaap_program
            and      shrgrde_levl_code=smrprle_levl_code
            and      shrgrde_passed_ind='Y'
            and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(sgbstdn_pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code)
            and     sgbstdn_pidm=shrtrce_pidm
            and     sgbstdn_program_1=smrpaap_program
            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and    x.sgbstdn_program_1=xx.sgbstdn_program_1)
            and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
            (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
            (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
            order by substr(smrarul_area,9,2);

            acred:=a_ord+a_equi;

return acred;

end acreditadas;

function acreditadas1(pidm number,  prog varchar2) return float is

a_ord number;
a_equi number;
acred decimal(6,2);

begin

          select   count(*)
 into a_ord
 from (
           select SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL) calificacion
          from  smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, sgbstdn x
           where  smrpaap_program=  prog
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
           and     sorlcur_pidm= pidm
           and sorlcur_lmod_code='LEARNER'
           and     sorlcur_program=smrpaap_program
           and     sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ww
                                               where w.sorlcur_pidm=ww.sorlcur_pidm
                                               and     w.sorlcur_program=ww.sorlcur_program
                                              and     w.sorlcur_lmod_code=ww.sorlcur_lmod_code)
            AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
           and     shrtckn_pidm=sorlcur_pidm
           and     shrtckn_subj_code=smrarul_subj_code
           and     shrtckn_crse_numb=smrarul_crse_numb_low
           and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
           and     shrtckg_pidm=shrtckn_pidm
           and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckn_term_code=shrtckg_term_code
           and     shrtckg_grde_code_final=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y'
           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code)
           and     sgbstdn_pidm=shrtckn_pidm
           and     sgbstdn_program_1=smrpaap_program
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and    x.sgbstdn_program_1=xx.sgbstdn_program_1)
           and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
            (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
            (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
              group by SHRTCKN_PIDM,
                    SHRTCKN_SUBJ_CODE,
                    SHRTCKN_CRSE_NUMB ,
                    SHRTCKN_STSP_KEY_SEQUENCE);

            select   count(*) into a_equi
            from smrpaap s, smrarul, smracaa,shrtrce, shrtrcr, shrgrde, smrprle, sorlcur w, sgbstdn x
           where    smrpaap_program=prog
            and     smrpaap_area=smrarul_area
            and     smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
            and     shrtrce_pidm=pidm
            and     shrtrce_subj_code=smrarul_subj_code
            and     shrtrce_crse_numb=smrarul_crse_numb_low
            and     shrtrce_pidm=shrtrcr_pidm
            and     shrtrce_trit_seq_no=shrtrcr_trit_seq_no
            and     shrtrce_tram_seq_no=shrtrcr_tram_seq_no
            and     shrtrce_trcr_seq_no=shrtrcr_seq_no
            and     shrtrcr_program=smrpaap_program
            and     shrtrce_grde_code=shrgrde_code
            and     smrprle_program=smrpaap_program
            and     shrgrde_levl_code=smrprle_levl_code
            and     shrgrde_passed_ind='Y'
            and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=x.sgbstdn_levl_code)
            and     sorlcur_pidm=pidm and sorlcur_lmod_code='LEARNER'
            and     sorlcur_program=smrpaap_program
            and     sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ww
                                               where w.sorlcur_pidm=ww.sorlcur_pidm
                                               and     w.sorlcur_program=ww.sorlcur_program
                                               and     w.sorlcur_lmod_code=ww.sorlcur_lmod_code)
            and     sgbstdn_pidm=sorlcur_pidm
            and     sgbstdn_program_1=smrpaap_program
            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and    x.sgbstdn_program_1=xx.sgbstdn_program_1)
           and      smrpaap_term_code_eff=sorlcur_term_code_ctlg
           and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
            (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
            (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
            order by substr(smrarul_area,9,2);

            acred:=a_ord+a_equi;

return acred;

end acreditadas1;

function reprobadas(pidm number,  prog varchar2) return float is

repro number;


begin

select count(distinct shrtckn_subj_code||shrtckn_crse_numb) into repro
from shrtckn z, shrtckg w, sorlcur s,shrgrde, smrpaap, smrarul
where shrtckn_pidm=shrtckg_pidm and shrtckn_term_code=shrtckg_term_code and shrtckn_seq_no=shrtckg_tckn_seq_no
and   sorlcur_pidm=shrtckn_pidm and sorlcur_key_seqno=shrtckn_stsp_key_sequence and sorlcur_lmod_code='LEARNER' and sorlcur_program=prog
and   sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ss
       where S.SORLCUR_PIDM=ss.sorlcur_pidm and s.sorlcur_key_seqno=ss.sorlcur_key_seqno and s.sorlcur_lmod_code=ss.sorlcur_lmod_code)
and   shrgrde_levl_code=sorlcur_levl_code and shrgrde_code=shrtckg_grde_code_final and shrgrde_passed_ind != 'Y'
and   shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=SORLCUR_LEVL_CODE)
and   shrtckn_pidm=pidm
and   smrpaap_program=sorlcur_program and smrpaap_term_code_eff=sorlcur_term_code_ctlg
and   smrarul_area=smrpaap_area and smrarul_term_code_eff=smrpaap_term_code_eff and smrarul_subj_code=shrtckn_subj_code and smrarul_crse_numb_low=shrtckn_crse_numb
and   shrtckn_pidm not in (select shrtckn_pidm from shrtckn zz, shrtckg ww, shrgrde qq
     where z.shrtckn_subj_code=zz.shrtckn_subj_code and z.shrtckn_crse_numb=zz.shrtckn_crse_numb
     and    zz.shrtckn_pidm=ww.shrtckg_pidm and zz.shrtckn_term_code=ww.shrtckg_term_code and zz.shrtckn_seq_no=ww.shrtckg_tckn_seq_no
     and   qq.shrgrde_levl_code=sorlcur_levl_code and qq.shrgrde_code=ww.shrtckg_grde_code_final and shrgrde_passed_ind = 'Y'
     and   qq.shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=SORLCUR_LEVL_CODE)
     )
and   shrtckn_pidm not in (select sfrstcr_pidm from sfrstcr, ssbsect where  sfrstcr_rsts_code='RE' and sfrstcr_grde_code is null  and sfrstcr_term_code=ssbsect_term_code and sfrstcr_crn=ssbsect_crn
and   ssbsect_subj_code=shrtckn_subj_code and ssbsect_crse_numb=shrtckn_crse_numb);

return repro;

end reprobadas;

function total_mat(soli number) return float is

total  number;

begin

            select count(*) into total
            from svrsvpr, svrsvad,smrpaap s, smrarul, sgbstdn y
           where    svrsvpr_protocol_seq_no=soli
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
           AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
            and     smrpaap_area=smrarul_area
            and     smrarul_area not in ('UTLMTI0101',
                                                      'UTLLTE0101',
                                                      'UTLLTI0101',
                                                      'UTLLTS0101',
                                                      'UTLLTT0110',
                                                      'UOCATN0101',
                                                      'UTSMTI0101',
                                                      'UNAMPT0111',
                                                      'UVEBTB0101',
                                                      'UTLTSS0110')
            and     sgbstdn_pidm=svrsvpr_pidm
            and     sgbstdn_program_1=smrpaap_program
            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                              and     x.sgbstdn_program_1=y.sgbstdn_program_1)
            and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc)) or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)))
                          );

 return total;

end total_mat;

function total_mate(prog varchar2, pidm number) return float is

total  number;

begin

            select count(*) into total
            from smrpaap s, smrarul, sgbstdn y
           where    smrpaap_program=prog
           AND smrpaap_term_code_eff = sgbstdn_term_code_ctlg_1
            and     smrpaap_area=smrarul_area
            and     smrarul_area not in ('UTLMTI0101',
                                                      'UTLLTE0101',
                                                      'UTLLTI0101',
                                                      'UTLLTS0101',
                                                      'UTLLTT0110',
                                                      'UOCATN0101',
                                                      'UTSMTI0101',
                                                      'UNAMPT0111',
                                                      'UVEBTB0101',
                                                      'UTLTSS0110')
            and     sgbstdn_pidm=pidm
            and     sgbstdn_program_1=smrpaap_program
            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                              and     x.sgbstdn_program_1=y.sgbstdn_program_1)
            and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc)) or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)))
                          );

 return total;

end total_mate;

function total_mate1(pidm number, prog varchar2) return float is

total  number(3);

begin
                               select  distinct SMBPGEN_REQ_COURSES_I_TRAD into total  from SMBPGEN
                                  where SMBPGEN_program=prog
                                      and SMBPGEN_TERM_CODE_EFF = (select distinct c.SORLCUR_TERM_CODE_CTLG from sorlcur c
                                                                                          where  c.sorlcur_pidm=pidm
                                                                                              and c.sorlcur_program=prog
                                                                                              and c.sorlcur_lmod_code='LEARNER'
                                                                                              and c.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                      where ss.sorlcur_pidm=pidm
                                                                                                                                         and ss.sorlcur_program=prog
                                                                                                                                         and ss.sorlcur_lmod_code='LEARNER'));
 return total;

end total_mate1;

function total_mate2(pidm number, prog varchar2) return float is

total  number(3);

begin
                               select  distinct SMBPGEN_REQ_COURSES_OVERALL into total  from SMBPGEN
                                  where SMBPGEN_program=prog
                                      and SMBPGEN_TERM_CODE_EFF = (select distinct c.SORLCUR_TERM_CODE_CTLG from sorlcur c
                                                                                          where  c.sorlcur_pidm=pidm
                                                                                              and c.sorlcur_program=prog
                                                                                              and c.sorlcur_lmod_code='LEARNER'
                                                                                              and c.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                      where ss.sorlcur_pidm=pidm
                                                                                                                                         and ss.sorlcur_program=prog
                                                                                                                                         and ss.sorlcur_lmod_code='LEARNER'));
 return total;

end total_mate2;

function creditos(soli number) return float is

ord    decimal(6,2);
equi   decimal(6,2);
cred decimal(6,2);
total  number;

begin


         select  nvl(sum(credito),0)
          into ord
          from (
          select   SHRTCKN_PIDM, SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB materia, SHRTCKN_STSP_KEY_SEQUENCE study, max (SHRTCKG_GRDE_CODE_FINAL) calificacion, nvl(sum(scbcrse_credit_hr_low),0) credito
          from  svrsvpr, svrsvad,smrpaap s, smrarul, smracaa,shrtckg, shrtckn, shrgrde, sorlcur w, smrprle, scbcrse, sgbstdn y
           where    svrsvpr_protocol_seq_no= 1  --soli
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
           AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
           and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc)) or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2))))
            and     sgbstdn_pidm=svrsvpr_pidm
            and     sgbstdn_program_1=smrpaap_program
            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                              and     x.sgbstdn_program_1=y.sgbstdn_program_1)
           and     sorlcur_pidm=sgbstdn_pidm
           and     sorlcur_program=smrpaap_program
           and     sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ww
                                               where w.sorlcur_pidm=ww.sorlcur_pidm
                                               and     w.sorlcur_program=ww.sorlcur_program)
           and     sorlcur_pidm=shrtckn_pidm
           and     shrtckn_subj_code=smrarul_subj_code
           and     shrtckn_crse_numb=smrarul_crse_numb_low
           and     shrtckn_stsp_key_sequence=sorlcur_key_seqno
           and     shrtckg_pidm=shrtckn_pidm
           and     shrtckg_tckn_seq_no=shrtckn_seq_no  and shrtckg_term_code=shrtckn_term_code
           and     shrtckg_grde_code_final=shrgrde_code
           and     smrprle_program=smrpaap_program
           and     shrgrde_levl_code=smrprle_levl_code
           and     shrgrde_passed_ind='Y'
           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(sorlcur_pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=y.sgbstdn_levl_code)
           and     scbcrse_subj_code=shrtckn_subj_code
           and     scbcrse_crse_numb=shrtckn_crse_numb
           and     scbcrse_eff_term='000000'
            group by SHRTCKN_PIDM,
                                    SHRTCKN_SUBJ_CODE,
                                    SHRTCKN_CRSE_NUMB ,
                                    SHRTCKN_STSP_KEY_SEQUENCE);


            select   nvl(sum(scbcrse_credit_hr_low),0) into equi
            from svrsvpr, svrsvad,smrpaap s, smrarul, smracaa,shrtrce, shrtrcr, shrgrde,  smrprle, scbcrse, sgbstdn y
           where  svrsvpr_protocol_seq_no=soli
            and   svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
            and   svrsvad_addl_data_seq=1
            and   smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
            AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
            and   smrpaap_area=smrarul_area
            and   smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
            and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc)) or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2))))
            and     sgbstdn_pidm=svrsvpr_pidm
            and     sgbstdn_program_1=smrpaap_program
            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                              and     x.sgbstdn_program_1=y.sgbstdn_program_1)
            and     shrtrce_pidm=sgbstdn_pidm
            and     shrtrce_subj_code=smrarul_subj_code
            and     shrtrce_crse_numb=smrarul_crse_numb_low
            and     shrtrce_pidm=shrtrcr_pidm
            and     shrtrce_trit_seq_no=shrtrcr_trit_seq_no
            and     shrtrce_tram_seq_no=shrtrcr_tram_seq_no
            and     shrtrce_trcr_seq_no=shrtrcr_seq_no
            and     shrtrcr_program=smrpaap_program
            and     shrtrce_grde_code=shrgrde_code
            and     smrprle_program=smrpaap_program
            and     shrgrde_levl_code=smrprle_levl_code
            and     shrgrde_passed_ind='Y'
            and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(y.sgbstdn_pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=y.sgbstdn_levl_code)
            and     scbcrse_subj_code=shrtrce_subj_code
            and     scbcrse_crse_numb=shrtrce_crse_numb
            and     scbcrse_eff_term='000000';

           if (ord+equi) > 0  then
               cred:=ord+equi;
           else
               cred:=0;
           end if;

return cred;

end creditos;

procedure ins_szasign(pidm1 in number, prog in varchar2) is

begin

delete from szasign;
commit;

insert into szasign
SELECT
          TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) per,
          smrarul_area area,
          smralib_area_desc nombre_area,
          smrarul_subj_code || smrarul_crse_numb_low materia,
          scrsyln_long_course_title nombre_mat,
          smbpgen_req_courses_overall Total_Cursos,
          smracaa_rule regla,
          kardex.calif,
          kardex.apr,
          CASE
             WHEN kardex.apr = 'Y' AND kardex.tipo = 'OE'
             THEN
                'AP'
             WHEN kardex.apr = 'N'
             THEN
                'NA'
             WHEN kardex.tipo = 'EQ'
             THEN
                'EQ'
             WHEN kardex.tipo IS NULL
             THEN
                CASE
                   WHEN (SELECT COUNT (*)
                           FROM ssbsect, sfrstcr a
                          WHERE     sfrstcr_pidm = sgbstdn_pidm
                                AND ssbsect_subj_code = smrarul_subj_code
                                AND ssbsect_crse_numb = smrarul_crse_numb_low
                                AND sfrstcr_term_code = ssbsect_term_code
                                AND sfrstcr_crn = ssbsect_crn
                                AND sfrstcr_rsts_code = 'RE'
                                AND sfrstcr_term_code IN
                                       (SELECT MAX (sfrstcr_term_code)
                                          FROM sfrstcr b
                                         WHERE a.sfrstcr_pidm =
                                                  b.sfrstcr_pidm)) > 0
                   THEN
                      'EC'
                   ELSE
                      'PC'
                END
          END
             tipo,
          kardex.tipo tipo1
     FROM
          (SELECT shrtckn_pidm pidm,
                  shrtckn_term_code periodo,
                  shrtckn_subj_code subj,
                  shrtckn_crse_numb crse,
                  shrtckg_grde_code_final calif,
                  'OE' tipo,
                  shrgrde_passed_ind apr
             FROM shrtckn,
                  shrtckg,
                  scrlevl,
                  shrgrde
            WHERE  shrtckn_pidm=pidm1
                  AND shrtckg_pidm = shrtckn_pidm
                  AND shrtckg_tckn_seq_no = shrtckn_seq_no And shrtckg_term_code=shrtckn_term_code
                  AND scrlevl_subj_code = shrtckn_subj_code
                  AND scrlevl_crse_numb = shrtckn_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtckg_grde_code_final
           UNION
           SELECT shrtrce_pidm pidm,
                  shrtrce_term_code_eff periodo,
                  shrtrce_subj_code subj,
                  shrtrce_crse_numb crse,
                  shrtrce_grde_code calif,
                  'EQ' tipo,
                  shrgrde_passed_ind apr
             FROM shrtrce, scrlevl, shrgrde
            WHERE shrtrce_pidm = pidm1
                  AND scrlevl_subj_code = shrtrce_subj_code
                  AND scrlevl_crse_numb = shrtrce_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtrce_grde_code) kardex,
          svrsvpr, svrsvad,sgbstdn a,
          smrprle,
          spriden,
          sztdtec,
          smbpgen,
          smrpaap s,
          smrarul,
          smralib,
          smracaa,
          scrsyln
           where    svrsvpr_protocol_seq_no=13
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
           AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
          AND sgbstdn_term_code_eff IN
                 (SELECT MAX (sgbstdn_term_code_eff)
                    FROM sgbstdn b
                   WHERE a.sgbstdn_pidm = b.sgbstdn_pidm
                         AND a.sgbstdn_program_1 = b.sgbstdn_program_1)
          AND sgbstdn_program_1 = smrprle_program
          AND spriden_pidm = sgbstdn_pidm
          AND spriden_change_ind IS NULL
          AND sgbstdn_program_1 = sztdtec_program
          AND sgbstdn_camp_code = sztdtec_camp_code
          AND sgbstdn_program_1 = smbpgen_program
          AND smrpaap_area = smrarul_area
          AND smrarul_area not in('UTLMTI0101',
                                              'UTLLTE0101',
                                              'UTLLTI0101',
                                              'UTLLTS0101',
                                              'UTLLTT0110',
                                              'UOCATN0101',
                                              'UTSMTI0101',
                                              'UNAMPT0111',
                                              'UVEBTB0101',
                                              'UTLTSS0110')
          AND smrarul_area NOT IN (SELECT smriecc_area FROM smriecc)
          AND smrarul_area NOT IN (SELECT smriemj_area FROM smriemj)
          AND smrpaap_area = smralib_area
          AND smracaa_area = smrarul_area
          AND smracaa_rule = smrarul_key_rule --and  substr(smracaa_rule,1,1)!='H'
          AND scrsyln_subj_code = smrarul_subj_code
          AND scrsyln_crse_numb = smrarul_crse_numb_low
          AND smrarul_subj_code = kardex.subj(+)
          AND smrarul_crse_numb_low = kardex.crse(+)
          AND smralib_area = smrarul_area
  UNION
   SELECT
          TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) per,
          smrarul_area area,
          smralib_area_desc nombre_area,
          smrarul_subj_code || smrarul_crse_numb_low materia,
          scrsyln_long_course_title nombre_mat,
          smbpgen_req_courses_overall Total_Cursos,
          smracaa_rule regla,
          kardex.calif,
          kardex.apr,
          CASE
             WHEN kardex.apr = 'Y' AND kardex.tipo = 'OE'
             THEN
                'AP'
             WHEN kardex.apr = 'N'
             THEN
                'NA'
             WHEN kardex.tipo = 'EQ'
             THEN
                'EQ'
             WHEN kardex.tipo IS NULL
             THEN
                CASE
                   WHEN (SELECT COUNT (*)
                           FROM ssbsect, sfrstcr a
                          WHERE     sfrstcr_pidm = sgbstdn_pidm
                                AND ssbsect_subj_code = smrarul_subj_code
                                AND ssbsect_crse_numb = smrarul_crse_numb_low
                                AND sfrstcr_term_code = ssbsect_term_code
                                AND sfrstcr_crn = ssbsect_crn
                                AND sfrstcr_rsts_code = 'RE'
                                AND sfrstcr_term_code IN
                                       (SELECT MAX (sfrstcr_term_code)
                                          FROM sfrstcr b
                                         WHERE a.sfrstcr_pidm =
                                                  b.sfrstcr_pidm)) > 0
                   THEN
                      'EC'
                   ELSE
                      'PC'
                END
          END
             tipo,
          kardex.tipo tipo1
     FROM
          (SELECT shrtckn_pidm pidm,
                  shrtckn_term_code periodo,
                  shrtckn_subj_code subj,
                  shrtckn_crse_numb crse,
                  shrtckg_grde_code_final calif,
                  'OE' tipo,
                  shrgrde_passed_ind apr
             FROM shrtckn,
                  shrtckg,
                  scrlevl,
                  shrgrde
            WHERE shrtckn_pidm = pidm1
                  AND shrtckg_pidm = shrtckn_pidm
                  AND shrtckg_tckn_seq_no = shrtckn_seq_no And shrtckg_term_code=shrtckn_term_code
                  AND scrlevl_subj_code = shrtckn_subj_code
                  AND scrlevl_crse_numb = shrtckn_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtckg_grde_code_final
           UNION
           SELECT shrtrce_pidm pidm,
                  shrtrce_term_code_eff periodo,
                  shrtrce_subj_code subj,
                  shrtrce_crse_numb crse,
                  shrtrce_grde_code calif,
                  'EQ' tipo,
                  shrgrde_passed_ind apr
             FROM shrtrce, scrlevl, shrgrde
            WHERE shrtrce_pidm = pidm1
                  AND scrlevl_subj_code = shrtrce_subj_code
                  AND scrlevl_crse_numb = shrtrce_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtrce_grde_code) kardex,
          svrsvpr, svrsvad,sgbstdn a,
          smrprle,
          spriden,
          sztdtec,
          smbpgen,
          smrpaap s,
          smrarul,
          smralib,
          smracaa,
          scrsyln,
          smriemj
           where    svrsvpr_protocol_seq_no=13
           and        svrsvpr_protocol_seq_no=svrsvad_protocol_seq_no
           and        svrsvad_addl_data_seq=1
           and       smrpaap_program=substr(svrsvad_addl_data_cde,1,10)
           AND (smrpaap_term_code_eff = decode(substr(svrsvad_addl_data_desc,50,2),'11','000000') or
                           substr(smrpaap_term_code_eff,3,2)=substr(svrsvad_addl_data_desc,50,2))
          AND sgbstdn_term_code_eff IN
                 (SELECT MAX (sgbstdn_term_code_eff)
                    FROM sgbstdn b
                   WHERE a.sgbstdn_pidm = b.sgbstdn_pidm
                         AND a.sgbstdn_program_1 = b.sgbstdn_program_1)
          AND sgbstdn_program_1 = smrprle_program
          AND spriden_pidm = sgbstdn_pidm
          AND spriden_change_ind IS NULL
          AND sgbstdn_program_1 = sztdtec_program
          AND sgbstdn_camp_code = sztdtec_camp_code
          AND sgbstdn_program_1 = smbpgen_program
          AND smrpaap_area = smrarul_area
          AND smrarul_area = smriemj_area
          AND smriemj_majr_code = sgbstdn_majr_code_1
          AND smrarul_area not in ('UTLMTI0101',
                                              'UTLLTE0101',
                                              'UTLLTI0101',
                                              'UTLLTS0101',
                                              'UTLLTT0110',
                                              'UOCATN0101',
                                              'UTSMTI0101',
                                              'UNAMPT0111',
                                              'UVEBTB0101',
                                              'UTLTSS0110')
          AND smrarul_area NOT IN (SELECT smriecc_area FROM smriecc)
          AND smrpaap_area = smralib_area
          AND smracaa_area = smrarul_area
          AND smracaa_rule = smrarul_key_rule --and  substr(smracaa_rule,1,1)!='H'
          AND scrsyln_subj_code = smrarul_subj_code
          AND scrsyln_crse_numb = smrarul_crse_numb_low
          AND smrarul_subj_code = kardex.subj(+)
          AND smrarul_crse_numb_low = kardex.crse(+)
          AND smralib_area = smrarul_area
   UNION
   SELECT
          TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) per,
          smrarul_area area,
          smralib_area_desc nombre_area,
          smrarul_subj_code || smrarul_crse_numb_low materia,
          scrsyln_long_course_title nombre_mat,
          smbpgen_req_courses_overall Total_Cursos,
          smracaa_rule regla,
          kardex.calif,
          kardex.apr,
          CASE
             WHEN kardex.apr = 'Y' AND kardex.tipo = 'OE'
             THEN
                'AP'
             WHEN kardex.apr = 'N'
             THEN
                'NA'
             WHEN kardex.tipo = 'EQ'
             THEN
                'EQ'
             WHEN kardex.tipo IS NULL
             THEN
                CASE
                   WHEN (SELECT COUNT (*)
                           FROM ssbsect, sfrstcr a
                          WHERE     sfrstcr_pidm = sgbstdn_pidm
                                AND ssbsect_subj_code = smrarul_subj_code
                                AND ssbsect_crse_numb = smrarul_crse_numb_low
                                AND sfrstcr_term_code = ssbsect_term_code
                                AND sfrstcr_crn = ssbsect_crn
                                AND sfrstcr_rsts_code = 'RE'
                                AND sfrstcr_term_code IN
                                       (SELECT MAX (sfrstcr_term_code)
                                          FROM sfrstcr b
                                         WHERE a.sfrstcr_pidm =
                                                  b.sfrstcr_pidm)) > 0
                   THEN
                      'EC'
                   ELSE
                      'PC'
                END
          END
             tipo,
          kardex.tipo tipo1
     FROM
          (SELECT shrtckn_pidm pidm,
                  shrtckn_term_code periodo,
                  shrtckn_subj_code subj,
                  shrtckn_crse_numb crse,
                  shrtckg_grde_code_final calif,
                  'OE' tipo,
                  shrgrde_passed_ind apr
             FROM shrtckn,
                  shrtckg,
                  scrlevl,
                  shrgrde
            WHERE shrtckn_pidm =  pidm1
                  AND shrtckg_pidm = shrtckn_pidm
                  AND shrtckg_tckn_seq_no = shrtckn_seq_no  And shrtckg_term_code=shrtckn_term_code
                  AND scrlevl_subj_code = shrtckn_subj_code
                  AND scrlevl_crse_numb = shrtckn_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtckg_grde_code_final
           UNION
           SELECT shrtrce_pidm pidm,
                  shrtrce_term_code_eff periodo,
                  shrtrce_subj_code subj,
                  shrtrce_crse_numb crse,
                  shrtrce_grde_code calif,
                  'EQ' tipo,
                  shrgrde_passed_ind apr
             FROM shrtrce, scrlevl, shrgrde
            WHERE shrtrce_pidm = pidm1
                  AND scrlevl_subj_code = shrtrce_subj_code
                  AND scrlevl_crse_numb = shrtrce_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtrce_grde_code) kardex,
          sgbstdn a,
          smrprle,
          spriden,
          sztdtec,
          smbpgen,
          smrpaap s,
          smrarul,
          smralib,
          smracaa,
          scrsyln,
          smriecc
    WHERE     sgbstdn_pidm = pidm1
          AND sgbstdn_program_1 = prog
          AND sgbstdn_term_code_eff IN
                 (SELECT MAX (sgbstdn_term_code_eff)
                    FROM sgbstdn b
                   WHERE a.sgbstdn_pidm = b.sgbstdn_pidm
                         AND a.sgbstdn_program_1 = b.sgbstdn_program_1)
          AND sgbstdn_program_1 = smrprle_program
          AND spriden_pidm = sgbstdn_pidm
          AND spriden_change_ind IS NULL
          AND sgbstdn_program_1 = sztdtec_program
          AND sgbstdn_camp_code = sztdtec_camp_code
          AND sgbstdn_program_1 = smbpgen_program
          AND smrpaap_program = sgbstdn_program_1
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sgbstdn_term_code_ctlg_1)
          AND smrpaap_area = smrarul_area
          AND smrarul_area not in ('UTLMTI0101',
                                              'UTLLTE0101',
                                              'UTLLTI0101',
                                              'UTLLTS0101',
                                              'UTLLTT0110',
                                              'UOCATN0101',
                                              'UTSMTI0101',
                                              'UNAMPT0111',
                                              'UVEBTB0101',
                                              'UTLTSS0110')
          AND smrarul_area = smriecc_area
          AND smriecc_majr_code_conc IN
                 (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)
          AND smrpaap_area = smralib_area
          AND smracaa_area = smrarul_area
          AND smracaa_rule = smrarul_key_rule --and  substr(smracaa_rule,1,1)!='H'
          AND scrsyln_subj_code = smrarul_subj_code
          AND scrsyln_crse_numb = smrarul_crse_numb_low
          AND smrarul_subj_code = kardex.subj(+)
          AND smrarul_crse_numb_low = kardex.crse(+)
          AND smralib_area = smrarul_area
   ORDER BY  per;

 commit;


end ins_szasign;

function alta_asig(pidm number,  prog varchar2) return varchar2 is

alta varchar2(30);
conta  number;

begin


alta:=null;
for c in (select per,materia, nombre_mat, apr, tipo from szasign
       order by per,materia, calif desc) loop

       if c.apr = 'N' then
          select count(*) into conta from szasign
          where materia=c.materia
          and    apr='Y' ;
          if conta = 0 then
             alta := c.materia;
             exit;
          end if;
       end if;

       if c.tipo = 'PC' then
          alta:= c.materia;
          exit;
       end if;

end loop;

if alta is null then alta:='NO hay materias para asignar'; end if;

--dbms_output.put_line('Materia:'||alta);
return alta;

end alta_asig;

function asigna_mat( pidm1 number, prog varchar2) return varchar2 is

sb varchar2(4);
cr varchar2(5);
crn varchar2(5);
term varchar2(6);
gpo varchar2(5);
leyenda varchar2(200);
nivel     varchar2(2);
campus  varchar2(4);
st_path   number;


cursor asigna is

 select distinct subj, crse,per, tipo from
(
SELECT
          distinct TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) per, smrarul_area area,smralib_area_desc nombre_area, smrarul_subj_code subj, smrarul_crse_numb_low crse,scrsyln_long_course_title nombre_mat,
          smbpgen_req_courses_overall Total_Cursos,smracaa_rule regla,kardex.calif,kardex.apr,
          CASE
             WHEN kardex.apr = 'Y' AND kardex.tipo = 'OE'
             THEN
                'AP'
             WHEN kardex.apr = 'N'
             THEN
                'NA'
             WHEN kardex.tipo = 'EQ'
             THEN
                'EQ'
             WHEN kardex.tipo IS NULL
             THEN
                CASE
                   WHEN (SELECT COUNT (*)
                           FROM ssbsect, sfrstcr a
                          WHERE     sfrstcr_pidm = sgbstdn_pidm
                                AND ssbsect_subj_code = smrarul_subj_code
                                AND ssbsect_crse_numb = smrarul_crse_numb_low
                                AND sfrstcr_term_code = ssbsect_term_code
                                AND sfrstcr_crn = ssbsect_crn
                                AND sfrstcr_rsts_code = 'RE'
                                AND sfrstcr_term_code IN
                                       (SELECT MAX (sfrstcr_term_code)
                                          FROM sfrstcr b
                                         WHERE a.sfrstcr_pidm =
                                                  b.sfrstcr_pidm)) > 0
                   THEN
                      'EC'
                   ELSE
                      'PC'
                END
          END
             tipo, kardex.tipo tipo1, kardex.fecha--,
         -- row_number() over(partition by sgbstdn_pidm order by SUBSTR (smrarul_area, 9, 2), smrarul_subj_code || smrarul_crse_numb_low) numero
     FROM
          (SELECT shrtckn_pidm pidm,shrtckn_term_code periodo, shrtckn_subj_code subj, shrtckn_crse_numb crse, shrtckg_grde_code_final calif, 'OE' tipo,
                  shrgrde_passed_ind apr,shrtckn_activity_date fecha
             FROM shrtckn, shrtckg, scrlevl,shrgrde
            WHERE shrtckn_pidm=pidm1
                  AND shrtckg_pidm = shrtckn_pidm
                  AND shrtckg_tckn_seq_no = shrtckn_seq_no And shrtckg_term_code=shrtckn_term_code
                  AND scrlevl_subj_code = shrtckn_subj_code
                  AND scrlevl_crse_numb = shrtckn_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtckg_grde_code_final
           UNION
           SELECT shrtrce_pidm pidm, shrtrce_term_code_eff periodo, shrtrce_subj_code subj, shrtrce_crse_numb crse,shrtrce_grde_code calif,'EQ' tipo,shrgrde_passed_ind apr, shrtrce_activity_date "fecha"
             FROM shrtrce, scrlevl, shrgrde
            WHERE shrtrce_pidm=pidm1
                  AND scrlevl_subj_code = shrtrce_subj_code
                  AND scrlevl_crse_numb = shrtrce_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtrce_grde_code) kardex,
          sgbstdn a, smrprle, spriden, sztdtec,smbpgen z, smrpaap s, smrarul,smralib,smracaa,scrsyln
    WHERE    sgbstdn_program_1 = prog
          AND  sgbstdn_pidm=pidm1
          AND sgbstdn_term_code_eff IN
                 (SELECT MAX (sgbstdn_term_code_eff)
                    FROM sgbstdn b
                   WHERE a.sgbstdn_pidm = b.sgbstdn_pidm
                         AND a.sgbstdn_program_1 = b.sgbstdn_program_1)
          AND sgbstdn_program_1 = smrprle_program
          AND spriden_pidm = sgbstdn_pidm
          AND spriden_change_ind IS NULL
          AND sgbstdn_program_1 = sztdtec_program
          AND sgbstdn_camp_code = sztdtec_camp_code
          AND sgbstdn_program_1 = smbpgen_program
          AND smbpgen_term_code_eff in (select max(smbpgen_term_code_eff) from smbpgen sm
                                                               where z.smbpgen_program=sm.smbpgen_program
                                                               and     sm.smbpgen_term_code_eff <= sgbstdn_term_code_ctlg_1)
          AND smrpaap_program = sgbstdn_program_1
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sgbstdn_term_code_ctlg_1)
          AND smrpaap_area = smrarul_area
          AND smrarul_area NOT IN (SELECT smriecc_area FROM smriecc)
          AND smrarul_area NOT IN (SELECT smriemj_area FROM smriemj)
          AND smrpaap_area = smralib_area
          AND smracaa_area = smrarul_area
          AND smracaa_rule = smrarul_key_rule --and  substr(smracaa_rule,1,1)!='H'
          AND scrsyln_subj_code = smrarul_subj_code
          AND scrsyln_crse_numb = smrarul_crse_numb_low
          AND smrarul_subj_code = kardex.subj(+)
          AND smrarul_crse_numb_low = kardex.crse(+)
          AND sgbstdn_pidm = kardex.pidm(+)
          AND smralib_area = smrarul_area
   UNION
   SELECT
          distinct TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) per, smrarul_area area, smralib_area_desc nombre_area, smrarul_subj_code subj, smrarul_crse_numb_low crse, scrsyln_long_course_title nombre_mat,
          smbpgen_req_courses_overall Total_Cursos, smracaa_rule regla, kardex.calif, kardex.apr,
          CASE
             WHEN kardex.apr = 'Y' AND kardex.tipo = 'OE'
             THEN
                'AP'
             WHEN kardex.apr = 'N'
             THEN
                'NA'
             WHEN kardex.tipo = 'EQ'
             THEN
                'EQ'
             WHEN kardex.tipo IS NULL
             THEN
                CASE
                   WHEN (SELECT COUNT (*)
                           FROM ssbsect, sfrstcr a
                          WHERE     sfrstcr_pidm = sgbstdn_pidm
                                AND ssbsect_subj_code = smrarul_subj_code
                                AND ssbsect_crse_numb = smrarul_crse_numb_low
                                AND sfrstcr_term_code = ssbsect_term_code
                                AND sfrstcr_crn = ssbsect_crn
                                AND sfrstcr_rsts_code = 'RE'
                                AND sfrstcr_term_code IN
                                       (SELECT MAX (sfrstcr_term_code)
                                          FROM sfrstcr b
                                         WHERE a.sfrstcr_pidm =
                                                  b.sfrstcr_pidm)) > 0
                   THEN
                      'EC'
                   ELSE
                      'PC'
                END
          END
             tipo, kardex.tipo tipo1, kardex.fecha --,
         --  row_number() over(partition by sgbstdn_pidm order by SUBSTR (smrarul_area, 9, 2), smrarul_subj_code || smrarul_crse_numb_low) numero
     FROM
          (SELECT shrtckn_pidm pidm, shrtckn_term_code periodo, shrtckn_subj_code subj, shrtckn_crse_numb crse, shrtckg_grde_code_final calif, 'OE' tipo, shrgrde_passed_ind apr, shrtckn_activity_date fecha
             FROM shrtckn, shrtckg, scrlevl, shrgrde
            WHERE shrtckn_pidm = pidm1
                  AND shrtckg_pidm = shrtckn_pidm
                  AND shrtckg_tckn_seq_no = shrtckn_seq_no  And shrtckg_term_code=shrtckn_term_code
                  AND scrlevl_subj_code = shrtckn_subj_code
                  AND scrlevl_crse_numb = shrtckn_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtckg_grde_code_final
           UNION
           SELECT shrtrce_pidm pidm,shrtrce_term_code_eff periodo, shrtrce_subj_code subj, shrtrce_crse_numb crse, shrtrce_grde_code calif,'EQ' tipo, shrgrde_passed_ind apr, shrtrce_activity_date fecha
             FROM shrtrce, scrlevl, shrgrde
            WHERE shrtrce_pidm = pidm1
                  AND scrlevl_subj_code = shrtrce_subj_code
                  AND scrlevl_crse_numb = shrtrce_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtrce_grde_code) kardex,
          sgbstdn a, smrprle, spriden, sztdtec, smbpgen z, smrpaap s, smrarul, smralib, smracaa,scrsyln,smriemj
    WHERE     sgbstdn_program_1 = prog
    AND         sgbstdn_pidm=pidm1
          AND sgbstdn_term_code_eff IN
                 (SELECT MAX (sgbstdn_term_code_eff)
                    FROM sgbstdn b
                   WHERE a.sgbstdn_pidm = b.sgbstdn_pidm
                         AND a.sgbstdn_program_1 = b.sgbstdn_program_1)
          AND sgbstdn_program_1 = smrprle_program
          AND spriden_pidm = sgbstdn_pidm
          AND spriden_change_ind IS NULL
          AND sgbstdn_program_1 = sztdtec_program
          AND sgbstdn_camp_code = sztdtec_camp_code
          AND sgbstdn_program_1 = smbpgen_program
          AND smbpgen_term_code_eff in (select max(smbpgen_term_code_eff) from smbpgen sm
                                                               where z.smbpgen_program=sm.smbpgen_program
                                                               and     sm.smbpgen_term_code_eff <= sgbstdn_term_code_ctlg_1)
          AND smrpaap_program = sgbstdn_program_1
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sgbstdn_term_code_ctlg_1)
          AND smrpaap_area = smrarul_area
          AND smrarul_area = smriemj_area
          AND smriemj_majr_code = sgbstdn_majr_code_1
          AND smrarul_area NOT IN (SELECT smriecc_area FROM smriecc)
          AND smrpaap_area = smralib_area
          AND smracaa_area = smrarul_area
          AND smracaa_rule = smrarul_key_rule --and  substr(smracaa_rule,1,1)!='H'
          AND scrsyln_subj_code = smrarul_subj_code
          AND scrsyln_crse_numb = smrarul_crse_numb_low
          AND smrarul_subj_code = kardex.subj(+)
          AND smrarul_crse_numb_low = kardex.crse(+)
          AND sgbstdn_pidm = kardex.pidm(+)
          AND smralib_area = smrarul_area
   UNION
   SELECT
          distinct TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) per, smrarul_area area, smralib_area_desc nombre_area, smrarul_subj_code subj,smrarul_crse_numb_low crse, scrsyln_long_course_title nombre_mat,
           smbpgen_req_courses_overall Total_Cursos, smracaa_rule regla, kardex.calif, kardex.apr,
          CASE
             WHEN kardex.apr = 'Y' AND kardex.tipo = 'OE'
             THEN
                'AP'
             WHEN kardex.apr = 'N'
             THEN
                'NA'
             WHEN kardex.tipo = 'EQ'
             THEN
                'EQ'
             WHEN kardex.tipo IS NULL
             THEN
                CASE
                   WHEN (SELECT COUNT (*)
                           FROM ssbsect, sfrstcr a
                          WHERE     sfrstcr_pidm = sgbstdn_pidm
                                AND ssbsect_subj_code = smrarul_subj_code
                                AND ssbsect_crse_numb = smrarul_crse_numb_low
                                AND sfrstcr_term_code = ssbsect_term_code
                                AND sfrstcr_crn = ssbsect_crn
                                AND sfrstcr_rsts_code = 'RE'
                                AND sfrstcr_term_code IN
                                       (SELECT MAX (sfrstcr_term_code)
                                          FROM sfrstcr b
                                         WHERE a.sfrstcr_pidm =
                                                  b.sfrstcr_pidm)) > 0
                   THEN
                      'EC'
                   ELSE
                      'PC'
                END
          END
             tipo, kardex.tipo tipo1, kardex.fecha --,
           --row_number() over(partition by sgbstdn_pidm order by SUBSTR (smrarul_area, 9, 2), smrarul_subj_code || smrarul_crse_numb_low) numero
     FROM
          (SELECT shrtckn_pidm pidm, shrtckn_term_code periodo, shrtckn_subj_code subj, shrtckn_crse_numb crse, shrtckg_grde_code_final calif, 'OE' tipo, shrgrde_passed_ind apr, shrtckn_activity_date fecha
             FROM shrtckn, shrtckg, scrlevl, shrgrde
            WHERE shrtckn_pidm = pidm1
                  AND shrtckg_pidm = shrtckn_pidm
                  AND shrtckg_tckn_seq_no = shrtckn_seq_no And shrtckg_term_code=shrtckn_term_code
                  AND scrlevl_subj_code = shrtckn_subj_code
                  AND scrlevl_crse_numb = shrtckn_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtckg_grde_code_final
           UNION
           SELECT shrtrce_pidm pidm, shrtrce_term_code_eff periodo, shrtrce_subj_code subj, shrtrce_crse_numb crse, shrtrce_grde_code calif, 'EQ' tipo, shrgrde_passed_ind apr, shrtrce_activity_date fecha
             FROM shrtrce, scrlevl, shrgrde
            WHERE shrtrce_pidm = pidm1
                  AND scrlevl_subj_code = shrtrce_subj_code
                  AND scrlevl_crse_numb = shrtrce_crse_numb
                  AND shrgrde_levl_code = scrlevl_levl_code
                  AND shrgrde_code = shrtrce_grde_code) kardex,
          sgbstdn a, smrprle, spriden, sztdtec, smbpgen z, smrpaap s, smrarul, smralib, smracaa, scrsyln,smriecc
    WHERE    sgbstdn_program_1 = prog
    AND         sgbstdn_pidm=pidm1
          AND sgbstdn_term_code_eff IN
                 (SELECT MAX (sgbstdn_term_code_eff)
                    FROM sgbstdn b
                   WHERE a.sgbstdn_pidm = b.sgbstdn_pidm
                         AND a.sgbstdn_program_1 = b.sgbstdn_program_1)
          AND sgbstdn_program_1 = smrprle_program
          AND spriden_pidm = sgbstdn_pidm
          AND spriden_change_ind IS NULL
          AND sgbstdn_program_1 = sztdtec_program
          AND sgbstdn_camp_code = sztdtec_camp_code
          AND sgbstdn_program_1 = smbpgen_program
          AND smbpgen_term_code_eff in (select max(smbpgen_term_code_eff) from smbpgen sm
                                                               where z.smbpgen_program=sm.smbpgen_program
                                                               and     sm.smbpgen_term_code_eff <= sgbstdn_term_code_ctlg_1)
          AND smrpaap_program = sgbstdn_program_1
          and       smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sgbstdn_term_code_ctlg_1)
          AND smrpaap_area = smrarul_area
          AND smrarul_area = smriecc_area
          AND smriecc_majr_code_conc IN
                 (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)
          AND smrpaap_area = smralib_area
          AND smracaa_area = smrarul_area
          AND smracaa_rule = smrarul_key_rule --and  substr(smracaa_rule,1,1)!='H'
          AND scrsyln_subj_code = smrarul_subj_code
          AND scrsyln_crse_numb = smrarul_crse_numb_low
          AND smrarul_subj_code = kardex.subj(+)
          AND smrarul_crse_numb_low = kardex.crse(+)
          AND sgbstdn_pidm = kardex.pidm(+)
          AND smralib_area = smrarul_area
   ORDER BY  per, subj, crse)  avan
   where tipo in ('NA','PC')
   order by per ;



begin
leyenda:=null;
--dbms_output.put_line('pidm-prog:'||pidm1||' '||prog);
for c in asigna loop

   begin
    -- dbms_output.put_line('materia:'||c.subj||' '||c.crse);
     select distinct ssbsect_term_code||' '||ssbsect_crn
     into leyenda
     from ssbsect x, sfrstcr a, scrsyln
     where sfrstcr_pidm=pidm1
     and    sfrstcr_term_code in (select max(sfrstcr_term_code) from sfrstcr aa
                                              where a.sfrstcr_pidm=aa.sfrstcr_pidm)
     and    ssbsect_term_code=sfrstcr_term_code
     and    ssbsect_subj_code=c.subj
     and    ssbsect_crse_numb=c.crse
     and    ssbsect_seats_avail > 0
     and    ssbsect_subj_code=scrsyln_subj_code
     and    ssbsect_crse_numb=scrsyln_crse_numb
     and    ssbsect_crn in (select min(ssbsect_crn) from ssbsect xx
                                     where x.ssbsect_term_code=xx.ssbsect_term_code
                                     and    x.ssbsect_subj_code=xx.ssbsect_subj_code
                                     and    x.ssbsect_crse_numb=xx.ssbsect_crse_numb
                                     and    xx.ssbsect_seats_avail > 0);

  exception when others then
     leyenda:=null;
  end;

     if leyenda is not null then
        exit;
     end if;

/*
         select unique sgbstdn_levl_code, sgbstdn_camp_code, sorlcur_key_seqno
         into nivel, campus, st_path
         from sgbstdn, sorlcur
         where sgbstdn_pidm=pidm
         and    sgbstdn_program_1=prog
         and    sorlcur_pidm=sgbstdn_pidm
         and    sorlcur_program=sgbstdn_program_1;
        insert into sfrstcr values(term, pidm, crn, null,1,'1','RE', trunc(sysdate),null,null,3,null,null,null,null,null,'AC',null,null,null,null,null,null,null,null,null,null,null,null,null,null,trunc(sysdate),sysdate,nivel,campus,
                                            null,null,null,null,null,null,null,null,null,null,null,'UTEL',null,null,null,null,null,null,null,null,null,null,st_path,null,null,null,null,null,null,'MIGRA',null);
        update ssbsect set ssbsect_seats_avail=ssbsect_seats_avail-1, ssbsect_enrl=ssbsect_enrl+1
        where ssbsect_term_code=term
        and     ssbsect_crn=crn;
        commit;
        exit;
     end if;
  */
end loop;

if leyenda is null then
   leyenda:='NO existe grupo materia para asignar';
end if;

return leyenda;

end asigna_mat;

function p_cur( pidm1 number, prog varchar2) return varchar2 is

per varchar2(2);

begin

select max(area) into per
from
(select area,count(*) nmat from
(select sfrstcr_pidm pidm,ssbsect_term_code, ssbsect_crn, ssbsect_subj_code, ssbsect_crse_numb, substr(capp.area,9,2) area
from ssbsect, sfrstcr a,
( select distinct smrarul_area AREA, smrarul_subj_code subj,smrarul_crse_numb_low crse, scbcrse_title NOMBRE
            from smrpaap s, smrarul, scbcrse, sgbstdn x
where  sgbstdn_pidm =pidm1
and      sgbstdn_program_1=prog
and      sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                   where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                   and     x.sgbstdn_program_1=xx.sgbstdn_program_1)
and     smrpaap_program=sgbstdn_program_1
and     smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sgbstdn_term_code_ctlg_1)
and     smrpaap_area=smrarul_area
and     scbcrse_subj_code=smrarul_subj_code and smrarul_crse_numb_low=scbcrse_crse_numb
            and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc))  or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2))))
order by  AREA,subj,crse) capp
where sfrstcr_pidm =pidm1
and    sfrstcr_term_code in (select max(sfrstcr_term_code) from sfrstcr b, sorlcur, stvterm
                                         where a.sfrstcr_pidm=b.sfrstcr_pidm
                                         and     b.sfrstcr_rsts_code='RE'
                                         and     sorlcur_pidm=a.sfrstcr_pidm
                                         and     sorlcur_program=prog
                                         and     sorlcur_key_seqno=sfrstcr_stsp_key_sequence
                                         and    b.sfrstcr_term_code=stvterm_code and stvterm_trmt_code!='E')
and   sfrstcr_term_code=ssbsect_term_code
and   sfrstcr_crn=ssbsect_crn
and   capp.subj=ssbsect_subj_code
and   capp.crse=ssbsect_crse_numb) per_cur
group by area) totales
where nmat in (select max(nmat) from
(select area,count(*) nmat from
(select sfrstcr_pidm pidm,ssbsect_term_code, ssbsect_crn, ssbsect_subj_code, ssbsect_crse_numb, substr(capp.area,9,2) area
from ssbsect, sfrstcr a,
( select distinct smrarul_area AREA, smrarul_subj_code subj,smrarul_crse_numb_low crse, scbcrse_title NOMBRE
            from smrpaap s, smrarul, scbcrse, sgbstdn x
where  sgbstdn_pidm =pidm1
and      sgbstdn_program_1=prog
and      sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                   where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                   and     x.sgbstdn_program_1=xx.sgbstdn_program_1)
and     smrpaap_program=sgbstdn_program_1
and     smrpaap_term_code_eff in (select max(smrpaap_term_code_eff) from smrpaap sm
                                                               where s.smrpaap_program=sm.smrpaap_program
                                                               and     sm.smrpaap_term_code_eff <= sgbstdn_term_code_ctlg_1)
and     smrpaap_area=smrarul_area
and     scbcrse_subj_code=smrarul_subj_code and smrarul_crse_numb_low=scbcrse_crse_numb
            and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                          (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1) and smrarul_area not in (select smriecc_area from smriecc))  or
                          (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2))))
order by  AREA,subj,crse) capp
where sfrstcr_pidm =pidm1
and    sfrstcr_term_code in (select max(sfrstcr_term_code) from sfrstcr b, sorlcur, stvterm
                                         where a.sfrstcr_pidm=b.sfrstcr_pidm
                                         and     b.sfrstcr_rsts_code='RE'
                                         and     sorlcur_pidm=a.sfrstcr_pidm
                                         and     sorlcur_program=prog
                                         and     sorlcur_key_seqno=sfrstcr_stsp_key_sequence
                                         and    b.sfrstcr_term_code=stvterm_code and stvterm_trmt_code!='E')
and   sfrstcr_term_code=ssbsect_term_code
and   sfrstcr_crn=ssbsect_crn
and   capp.subj=ssbsect_subj_code
and   capp.crse=ssbsect_crse_numb) per_cur
group by area)) ;

if per is null then
   per:='01';
end if;

return per;

end p_cur;



PROCEDURE sp_inserta_egresados_ant
is
vl_msje varchar2(200):='Proceso inserta egresada exitoso';
vl_program_code varchar2(15);
vl_percent varchar2(15);
vl_pidm number;
vl_stsp_key number;
vl_contador number;
vl_per_max varchar2(6);
stst_code varchar(2);
incorporante varchar2(15);
periodo_ctg varchar2(6);
styp_code    varchar2(1);
vl_per_sgb varchar2(6) := null;


   begin
    for c in (

    SELECT DISTINCT SHRTCKN_PIDM pidm, SHRTCKN_STSP_KEY_SEQUENCE sequence, SPRIDEN_ID iden
              FROM  SHRTCKN, SPRIDEN
              --WHERE TRUNC(SHRTCKN_ACTIVITY_DATE) >= TRUNC(sysdate) - 5
             where     SPRIDEN_PIDM=SHRTCKN_PIDM AND SPRIDEN_CHANGE_IND IS NULL AND SUBSTR(SPRIDEN_ID,1,2)!='08'

)

    loop


vl_program_code := null;
vl_percent := null;
vl_pidm := null;
vl_stsp_key := 0;
vl_contador := 0;
vl_per_max := null;
stst_code := null;
incorporante := null;
periodo_ctg := null;
vl_per_sgb := null;



            BEGIN
             SELECT DISTINCT a.SORLCUR_PROGRAM, SORLCUR_TERM_CODE_CTLG
                INTO vl_program_code , periodo_ctg
             FROM SORLCUR a
             WHERE a.SORLCUR_KEY_SEQNO = c.sequence
             AND a.SORLCUR_PIDM = c.pidm
             AND a.SORLCUR_LMOD_CODE='LEARNER'
             And a.SORLCUR_SEQNO in (select max (a1.SORLCUR_SEQNO)
                                                      from SORLCUR a1
                                                      Where a.SORLCUR_PIDM = a1.SORLCUR_PIDM
                                                      And a.SORLCUR_KEY_SEQNO = a1.SORLCUR_KEY_SEQNO
                                                      And a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
             ;
             EXCEPTION WHEN OTHERS THEN
             --dbms_output.put_line('pidm:'||c.pidm||' secuencia:'||c.sequence);
             continue;
             END;

             vl_percent := BANINST1.pkg_datos_academicos.avance2(c.pidm,vl_program_code);


          if vl_percent >=100 then
                       --dbms_output.put_line('Si cumple'||' '||c.pidm ||' '||vl_percent||' '||vl_program_code||' '||c.sequence);

                         begin
                              select  COUNT(*)
                              INTO vl_contador
                               FROM SGBSTDN WHERE SGBSTDN_PIDM = c.pidm
                               AND SGBSTDN_PROGRAM_1 = vl_program_code
                               AND SGBSTDN_STST_CODE ='EG';
                         Exception
                         When Others then
                         vl_contador :=0;
                         end;

                        if vl_contador  = 0 then

                                 Begin
                                    SELECT DISTINCT MAX(SHRTCKN_TERM_CODE)
                                            INTO vl_per_max
                                    FROM SHRTCKN
                                    WHERE  SHRTCKN_PIDM=c.pidm
                                    AND SHRTCKN_STSP_KEY_SEQUENCE =c.sequence;
                                 Exception
                                 When Others then
                                    vl_per_max := null;
                                 End;

                               Begin
                                    Select a.sgbstdn_term_code_eff
                                        into vl_per_sgb
                                    from sgbstdn a
                                    where a.sgbstdn_pidm = c.pidm
                                    and a.sgbstdn_program_1 = vl_program_code
                                    and a.sgbstdn_term_code_eff = (select max (a1.sgbstdn_term_code_eff)
                                                                                    from sgbstdn a1
                                                                                    where a.sgbstdn_pidm = a1.sgbstdn_pidm
                                                                                    and a.sgbstdn_program_1 = a1.sgbstdn_program_1);
                               Exception
                                    When Others then
                                       vl_per_sgb := null;
                               End;



                                begin
                                select  sztdtec_incorporante
                                    into incorporante
                                 from sztdtec
                                where sztdtec_program=vl_program_code
                                and sztdtec_status='ACTIVO'
                                And  SZTDTEC_TERM_CODE = periodo_ctg;
                                exception when others then
                                incorporante:=null;
                                end;

                                if incorporante='SEGEM' then
                                   stst_code:='SG';
                                else
                                   stst_code:='EG';
                                end if;

                                If vl_per_sgb > vl_per_max then
                                       Begin
                                          Update sgbstdn a
                                           set SGBSTDN_STST_CODE = stst_code,
                                                SGBSTDN_DATA_ORIGIN = 'PROCESO_XXX'
                                           where a.SGBSTDN_PIDM = c.pidm
                                           and a.SGBSTDN_PROGRAM_1 = vl_program_code
                                            And a.sgbstdn_term_code_eff = (select max (a1.sgbstdn_term_code_eff)
                                                                                    from sgbstdn a1
                                                                                    where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                                    and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1);
                                       Exception
                                        When Others then
                                                null;
                                        End;
                              Else

                                        Begin
                                                INSERT INTO SGBSTDN
                                                SELECT
                                                SGBSTDN_PIDM,
                                                vl_per_max,
                                                stst_code,
                                                SGBSTDN_LEVL_CODE,
                                                SGBSTDN_STYP_CODE,
                                                SGBSTDN_TERM_CODE_MATRIC,
                                                SGBSTDN_TERM_CODE_ADMIT,
                                                SGBSTDN_EXP_GRAD_DATE,
                                                SGBSTDN_CAMP_CODE,
                                                SGBSTDN_FULL_PART_IND,
                                                SGBSTDN_SESS_CODE,
                                                SGBSTDN_RESD_CODE,
                                                SGBSTDN_COLL_CODE_1,
                                                SGBSTDN_DEGC_CODE_1,
                                                SGBSTDN_MAJR_CODE_1,
                                                SGBSTDN_MAJR_CODE_MINR_1,
                                                SGBSTDN_MAJR_CODE_MINR_1_2,
                                                SGBSTDN_MAJR_CODE_CONC_1,
                                                SGBSTDN_MAJR_CODE_CONC_1_2,
                                                SGBSTDN_MAJR_CODE_CONC_1_3,
                                                SGBSTDN_COLL_CODE_2,
                                                SGBSTDN_DEGC_CODE_2,
                                                SGBSTDN_MAJR_CODE_2,
                                                SGBSTDN_MAJR_CODE_MINR_2,
                                                SGBSTDN_MAJR_CODE_MINR_2_2,
                                                SGBSTDN_MAJR_CODE_CONC_2,
                                                SGBSTDN_MAJR_CODE_CONC_2_2,
                                                SGBSTDN_MAJR_CODE_CONC_2_3,
                                                SGBSTDN_ORSN_CODE,
                                                SGBSTDN_PRAC_CODE,
                                                SGBSTDN_ADVR_PIDM,
                                                SGBSTDN_GRAD_CREDIT_APPR_IND,
                                                SGBSTDN_CAPL_CODE,
                                                SGBSTDN_LEAV_CODE,
                                                SGBSTDN_LEAV_FROM_DATE,
                                                SGBSTDN_LEAV_TO_DATE,
                                                SGBSTDN_ASTD_CODE,
                                                SGBSTDN_TERM_CODE_ASTD,
                                                SGBSTDN_RATE_CODE,
                                                sysdate,
                                                SGBSTDN_MAJR_CODE_1_2,
                                                SGBSTDN_MAJR_CODE_2_2,
                                                SGBSTDN_EDLV_CODE,
                                                SGBSTDN_INCM_CODE,
                                                SGBSTDN_ADMT_CODE,
                                                SGBSTDN_EMEX_CODE,
                                                SGBSTDN_APRN_CODE,
                                                SGBSTDN_TRCN_CODE,
                                                SGBSTDN_GAIN_CODE,
                                                SGBSTDN_VOED_CODE,
                                                SGBSTDN_BLCK_CODE,
                                                SGBSTDN_TERM_CODE_GRAD,
                                                SGBSTDN_ACYR_CODE,
                                                SGBSTDN_DEPT_CODE,
                                                SGBSTDN_SITE_CODE,
                                                SGBSTDN_DEPT_CODE_2,
                                                SGBSTDN_EGOL_CODE,
                                                SGBSTDN_DEGC_CODE_DUAL,
                                                SGBSTDN_LEVL_CODE_DUAL,
                                                SGBSTDN_DEPT_CODE_DUAL,
                                                SGBSTDN_COLL_CODE_DUAL,
                                                SGBSTDN_MAJR_CODE_DUAL,
                                                SGBSTDN_BSKL_CODE,
                                                SGBSTDN_PRIM_ROLL_IND,
                                                SGBSTDN_PROGRAM_1,
                                                SGBSTDN_TERM_CODE_CTLG_1,
                                                SGBSTDN_DEPT_CODE_1_2,
                                                SGBSTDN_MAJR_CODE_CONC_121,
                                                SGBSTDN_MAJR_CODE_CONC_122,
                                                SGBSTDN_MAJR_CODE_CONC_123,
                                                SGBSTDN_SECD_ROLL_IND,
                                                SGBSTDN_TERM_CODE_ADMIT_2,
                                                SGBSTDN_ADMT_CODE_2,
                                                SGBSTDN_PROGRAM_2,
                                                SGBSTDN_TERM_CODE_CTLG_2,
                                                SGBSTDN_LEVL_CODE_2,
                                                SGBSTDN_CAMP_CODE_2,
                                                SGBSTDN_DEPT_CODE_2_2,
                                                SGBSTDN_MAJR_CODE_CONC_221,
                                                SGBSTDN_MAJR_CODE_CONC_222,
                                                SGBSTDN_MAJR_CODE_CONC_223,
                                                SGBSTDN_CURR_RULE_1,
                                                SGBSTDN_CMJR_RULE_1_1,
                                                SGBSTDN_CCON_RULE_11_1,
                                                SGBSTDN_CCON_RULE_11_2,
                                                SGBSTDN_CCON_RULE_11_3,
                                                SGBSTDN_CMJR_RULE_1_2,
                                                SGBSTDN_CCON_RULE_12_1,
                                                SGBSTDN_CCON_RULE_12_2,
                                                SGBSTDN_CCON_RULE_12_3,
                                                SGBSTDN_CMNR_RULE_1_1,
                                                SGBSTDN_CMNR_RULE_1_2,
                                                SGBSTDN_CURR_RULE_2,
                                                SGBSTDN_CMJR_RULE_2_1,
                                                SGBSTDN_CCON_RULE_21_1,
                                                SGBSTDN_CCON_RULE_21_2,
                                                SGBSTDN_CCON_RULE_21_3,
                                                SGBSTDN_CMJR_RULE_2_2,
                                                SGBSTDN_CCON_RULE_22_1,
                                                SGBSTDN_CCON_RULE_22_2,
                                                SGBSTDN_CCON_RULE_22_3,
                                                SGBSTDN_CMNR_RULE_2_1,
                                                SGBSTDN_CMNR_RULE_2_2,
                                                SGBSTDN_PREV_CODE,
                                                SGBSTDN_TERM_CODE_PREV,
                                                SGBSTDN_CAST_CODE,
                                                SGBSTDN_TERM_CODE_CAST,
                                                'PROCESO',
                                                user,
                                                SGBSTDN_SCPC_CODE,
                                                NULL,
                                                NULL,
                                                NULL
                                                FROM SGBSTDN a
                                                WHERE
                                                SGBSTDN_PIDM= c.pidm
                                                AND SGBSTDN_PROGRAM_1 = vl_program_code
                                                AND SGBSTDN_TERM_CODE_EFF in (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                                                                                                    FROM SGBSTDN a1
                                                                                                    WHERE a.SGBSTDN_PIDM=a1.SGBSTDN_PIDM
                                                                                                    AND a.SGBSTDN_PROGRAM_1=a1.SGBSTDN_PROGRAM_1);
                                                 --dbms_output.put_line( 'Exit0 ' || c.pidm ||' '||vl_percent||' '||vl_program_code||' '||c.sequence||'*'||vl_per_max ||'*'||c.iden);
                                       Exception
                                       When Others then
                                            --dbms_output.put_line( 'error ' || c.pidm ||' '||vl_percent||' '||vl_program_code||' '||c.sequence||'*'||vl_per_max ||'*'||c.iden);
                                                update  SGBSTDN a
                                                set  a.SGBSTDN_STST_CODE = stst_code
                                                WHERE SGBSTDN_PIDM= c.pidm
                                                AND SGBSTDN_PROGRAM_1 = vl_program_code
                                                AND SGBSTDN_TERM_CODE_EFF in (SELECT MAX(SGBSTDN_TERM_CODE_EFF) FROM SGBSTDN a1
                                                                              WHERE a.SGBSTDN_PIDM=a1.SGBSTDN_PIDM
                                                                              AND a.SGBSTDN_PROGRAM_1=a1.SGBSTDN_PROGRAM_1);

                                       End;


                                       Begin
                                           update SHRDGMR
                                           SET SHRDGMR_DEGS_CODE ='PE',
                                           SHRDGMR_ACTIVITY_DATE = sysdate,
                                           SHRDGMR_DATA_ORIGIN = 'PROCESO'
                                           WHERE SHRDGMR_PIDM =c.pidm
                                           AND SHRDGMR_PROGRAM=vl_program_code;
                                       Exception
                                       When others then
                                        null;
                                       End;

                                        --dbms_output.put_line(c.pidm ||' '||vl_percent||' '||vl_program_code||' '||c.sequence||' iden:'||c.iden);
                                end if;
                    End if;
         else
                              -- Verifica si el ??mo estatus de tipo de alumno
                                Begin
                                    select sgbstdn_styp_code into styp_code from sgbstdn s
                                      where sgbstdn_pidm=c.pidm and sgbstdn_program_1=vl_program_code
                                      and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn ss
                                                   where s.sgbstdn_pidm=ss.sgbstdn_pidm and s.sgbstdn_program_1=ss.sgbstdn_program_1);
                                Exception
                                When Others then
                                    styp_code := null;
                                End;

          -- Si es N=Nuevo Ingreso lo cambia a C=Continuo
                              if styp_code in ('N', 'R' ) then
                                 update sgbstdn s set sgbstdn_styp_code='C',
                                           SGBSTDN_ACTIVITY_DATE = sysdate,
                                           SGBSTDN_DATA_ORIGIN =' PROCESO'
                                  where sgbstdn_pidm=c.pidm and sgbstdn_program_1=vl_program_code
                                  and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn ss
                                           where s.sgbstdn_pidm=ss.sgbstdn_pidm and s.sgbstdn_program_1=ss.sgbstdn_program_1);
                              end if;
         end if;
    end loop;
       commit;
  end;

PROCEDURE sp_inserta_egresados
is

vl_per_max varchar2(6);
stst_code varchar(2);
incorporante varchar2(15);
vl_per_sgb varchar2(6) := null;
v_error varchar2(4000);
v_adeudo number;
v_programa varchar(12);
vl_utelx number:=0;

   begin
        for c in (
                      SELECT SZTHITA_PIDM PIDM,
                                  SZTHITA_ID ID,
                                  SZTHITA_PROG prog ,
                                  SZTHITA_AVANCE ava,
                                  SZTHITA_PER_CATALOGO per_cat,
                                  SZTHITA_STUDY study,
                                  SZTHITA_STATUS stat
                       FROM  SZTHITA,SMBPGEN
                      WHERE SZTHITA_AVANCE>=100
                          AND SZTHITA_STATUS IN  ('MATRICULADO','PREMATRICULADO','ADMITIDO')
                          AND SZTHITA_PROG=SMBPGEN_PROGRAM
                          AND SZTHITA_PER_CATALOGO=SMBPGEN_TERM_CODE_EFF
                          AND SMBPGEN_ACTIVE_IND='Y'
                          AND SZTHITA_APROB>=SMBPGEN_REQ_COURSES_I_TRAD
                  )

    loop

            vl_per_max := null;
            stst_code := null;
            incorporante := null;
            vl_per_sgb := null;
            v_adeudo:=0;
            v_programa := null;
            vl_utelx :=0;

         if c.ava >=100  then

                                 IF SUBSTR(C.ID,1,2)='30' then
                                   begin
                                     select zstpara_param_id into v_programa from ZSTPARA where zstpara_mapa_id='AG_MENDEZ' and zstpara_param_id=c.prog;
                                   Exception When Others then
                                     v_programa := null;
                                   end;
                                 END IF;

                                  Begin
                                    SELECT DISTINCT MAX(SHRTCKN_TERM_CODE)
                                            INTO vl_per_max
                                    FROM SHRTCKN
                                    WHERE  SHRTCKN_PIDM=c.pidm
                                    AND SHRTCKN_STSP_KEY_SEQUENCE =c.study
                                    AND SUBSTR(SHRTCKN_TERM_CODE,5,1) NOT IN ('8','9');
                                 Exception
                                 When Others then
                                    vl_per_max := null;
                                 End;

                                Begin
                                    Select a.sgbstdn_term_code_eff
                                        into vl_per_sgb
                                    from sgbstdn a
                                    where a.sgbstdn_pidm = c.pidm
                                    and a.sgbstdn_program_1 = c.prog
                                    and a.sgbstdn_term_code_eff = (select max (a1.sgbstdn_term_code_eff)
                                                                                    from sgbstdn a1
                                                                                    where a.sgbstdn_pidm = a1.sgbstdn_pidm
                                                                                    and a.sgbstdn_program_1 = a1.sgbstdn_program_1);
                                Exception
                                    When Others then
                                       vl_per_sgb := null;
                                End;


                                begin
                                select  sztdtec_incorporante
                                    into incorporante
                                 from sztdtec
                                where sztdtec_program=c.prog
                                and sztdtec_status='ACTIVO'
                                And  SZTDTEC_TERM_CODE = c.per_cat;
                                exception when others then
                                 incorporante:=null;
                                end;

                                if incorporante='SEGEM' then
                                   stst_code:='SG';
                                else
                                   stst_code:='EG';
                                end if;


                                IF  SUBSTR(C.ID,1,2)='30' and c.prog= v_programa then
                                  stst_code:='TR';
                                end if;

                                select PKG_DASHBOARD_ALUMNO.f_dashboard_saldototal(c.pidm) into v_adeudo from dual;    --- cambio para  alumnos 08 si tiene adeudos no cambia a TR traspaso

                                IF v_adeudo=0 then
                                      IF  SUBSTR(C.ID,1,2)='08' then
                                          stst_code:='TR';
                                      end if;
                                end if;


                                If vl_per_sgb > vl_per_max then
                                       Begin
                                          Update sgbstdn a
                                           set SGBSTDN_STST_CODE = stst_code,
                                                SGBSTDN_DATA_ORIGIN = 'PROCESO_EGX',
                                                SGBSTDN_ACTIVITY_DATE=sysdate
                                           where a.SGBSTDN_PIDM = c.pidm
                                           and a.SGBSTDN_PROGRAM_1 = c.prog
                                            And a.sgbstdn_term_code_eff = (select max (a1.sgbstdn_term_code_eff) from sgbstdn a1
                                                                                                      where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                                                          and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1);
                                       Exception
                                        When Others then
                                                 v_error:='Se presento el error ='||sqlerrm;
                                        End;

                                       begin
                                          CASE WHEN SUBSTR(C.ID,1,2)='08' then
                                            UPDATE SZTHITA
                                             SET SZTHITA_STATUS='TRASPASO_'
                                                WHERE  SZTHITA_PIDM=C.PIDM
                                                AND  SZTHITA_PROG=C.PROG
                                                AND  SZTHITA_STATUS=c.stat;
                                           WHEN SUBSTR(C.ID,1,2)='30' and c.prog= v_programa then
                                            UPDATE SZTHITA
                                             SET SZTHITA_STATUS='TRASPASO_'
                                                WHERE  SZTHITA_PIDM=C.PIDM
                                                AND  SZTHITA_PROG=C.PROG
                                                AND  SZTHITA_STATUS=c.stat;
                                           ELSE
                                            UPDATE SZTHITA
                                             SET SZTHITA_STATUS='EGRESADO_'
                                                WHERE  SZTHITA_PIDM=C.PIDM
                                                AND  SZTHITA_PROG=C.PROG
                                                AND  SZTHITA_STATUS=c.stat;
                                          end case;
                                       Exception When Others then
                                           begin
                                                dbms_output.put_line( 'no actualizo SZTHITA: ' || c.pidm ||' programa: '||c.prog);
                                                null;
                                           end;
                                        End;



                                        Begin
--                                         dbms_output.put_line( 'entro 1  SGRSCMT PROCESO_EG  : ' || c.pidm ||' programa: '||c.prog||' per: '||vl_per_sgb);
                                             CASE WHEN SUBSTR(C.ID,1,2)='08' then
                                                     INSERT INTO SGRSCMT
                                                         VALUES (
                                                                      c.pidm,
                                                                      c.study,
                                                                      vl_per_sgb,
                                                                      'Cambio_estatus:  TR,  Proceso INSERTA-TRANSFERENCIA UOC',
                                                                      sysdate,
                                                                      null,
                                                                      0,
                                                                      null,
                                                                      'PROCESO_EG',
                                                                      null
                                                                  );
                                                 WHEN SUBSTR(C.ID,1,2)='30' and c.prog= v_programa then
                                                     INSERT INTO SGRSCMT
                                                      VALUES (
                                                                      c.pidm,
                                                                      c.study,
                                                                      vl_per_sgb,
                                                                      'Cambio_estatus:  TR,  Proceso INSERTA-TRANSFERENCIA AG_MENDEZ',
                                                                      sysdate,
                                                                      null,
                                                                      0,
                                                                      null,
                                                                      'PROCESO_EG',
                                                                      null
                                                                  );
                                                ELSE
                                                   INSERT INTO SGRSCMT
                                                      VALUES (
                                                                      c.pidm,
                                                                      c.study,
                                                                      vl_per_sgb,
                                                                      'Cambio_estatus:  EG,  Proceso INSERTA_EGRESADOS',
                                                                      sysdate,
                                                                      null,
                                                                      0,
                                                                      null,
                                                                      'PROCESO_EG',
                                                                      null
                                                                  );
                                             END CASE;
                                        Exception When Others then
                                           begin
                                                dbms_output.put_line( 'no entro 1  SGRSCMT: ' || c.pidm ||' programa: '||c.prog||' per: '||vl_per_sgb);
                                                null;
                                           end;
                                        End;
                                Else
                                        Begin
                                                INSERT INTO SGBSTDN
                                                SELECT
                                                SGBSTDN_PIDM,
                                                vl_per_max,
                                                stst_code,
                                                SGBSTDN_LEVL_CODE,
                                                SGBSTDN_STYP_CODE,
                                                SGBSTDN_TERM_CODE_MATRIC,
                                                SGBSTDN_TERM_CODE_ADMIT,
                                                SGBSTDN_EXP_GRAD_DATE,
                                                SGBSTDN_CAMP_CODE,
                                                SGBSTDN_FULL_PART_IND,
                                                SGBSTDN_SESS_CODE,
                                                SGBSTDN_RESD_CODE,
                                                SGBSTDN_COLL_CODE_1,
                                                SGBSTDN_DEGC_CODE_1,
                                                SGBSTDN_MAJR_CODE_1,
                                                SGBSTDN_MAJR_CODE_MINR_1,
                                                SGBSTDN_MAJR_CODE_MINR_1_2,
                                                SGBSTDN_MAJR_CODE_CONC_1,
                                                SGBSTDN_MAJR_CODE_CONC_1_2,
                                                SGBSTDN_MAJR_CODE_CONC_1_3,
                                                SGBSTDN_COLL_CODE_2,
                                                SGBSTDN_DEGC_CODE_2,
                                                SGBSTDN_MAJR_CODE_2,
                                                SGBSTDN_MAJR_CODE_MINR_2,
                                                SGBSTDN_MAJR_CODE_MINR_2_2,
                                                SGBSTDN_MAJR_CODE_CONC_2,
                                                SGBSTDN_MAJR_CODE_CONC_2_2,
                                                SGBSTDN_MAJR_CODE_CONC_2_3,
                                                SGBSTDN_ORSN_CODE,
                                                SGBSTDN_PRAC_CODE,
                                                SGBSTDN_ADVR_PIDM,
                                                SGBSTDN_GRAD_CREDIT_APPR_IND,
                                                SGBSTDN_CAPL_CODE,
                                                SGBSTDN_LEAV_CODE,
                                                SGBSTDN_LEAV_FROM_DATE,
                                                SGBSTDN_LEAV_TO_DATE,
                                                SGBSTDN_ASTD_CODE,
                                                SGBSTDN_TERM_CODE_ASTD,
                                                SGBSTDN_RATE_CODE,
                                                sysdate,
                                                SGBSTDN_MAJR_CODE_1_2,
                                                SGBSTDN_MAJR_CODE_2_2,
                                                SGBSTDN_EDLV_CODE,
                                                SGBSTDN_INCM_CODE,
                                                SGBSTDN_ADMT_CODE,
                                                SGBSTDN_EMEX_CODE,
                                                SGBSTDN_APRN_CODE,
                                                SGBSTDN_TRCN_CODE,
                                                SGBSTDN_GAIN_CODE,
                                                SGBSTDN_VOED_CODE,
                                                SGBSTDN_BLCK_CODE,
                                                SGBSTDN_TERM_CODE_GRAD,
                                                SGBSTDN_ACYR_CODE,
                                                SGBSTDN_DEPT_CODE,
                                                SGBSTDN_SITE_CODE,
                                                SGBSTDN_DEPT_CODE_2,
                                                SGBSTDN_EGOL_CODE,
                                                SGBSTDN_DEGC_CODE_DUAL,
                                                SGBSTDN_LEVL_CODE_DUAL,
                                                SGBSTDN_DEPT_CODE_DUAL,
                                                SGBSTDN_COLL_CODE_DUAL,
                                                SGBSTDN_MAJR_CODE_DUAL,
                                                SGBSTDN_BSKL_CODE,
                                                SGBSTDN_PRIM_ROLL_IND,
                                                SGBSTDN_PROGRAM_1,
                                                SGBSTDN_TERM_CODE_CTLG_1,
                                                SGBSTDN_DEPT_CODE_1_2,
                                                SGBSTDN_MAJR_CODE_CONC_121,
                                                SGBSTDN_MAJR_CODE_CONC_122,
                                                SGBSTDN_MAJR_CODE_CONC_123,
                                                SGBSTDN_SECD_ROLL_IND,
                                                SGBSTDN_TERM_CODE_ADMIT_2,
                                                SGBSTDN_ADMT_CODE_2,
                                                SGBSTDN_PROGRAM_2,
                                                SGBSTDN_TERM_CODE_CTLG_2,
                                                SGBSTDN_LEVL_CODE_2,
                                                SGBSTDN_CAMP_CODE_2,
                                                SGBSTDN_DEPT_CODE_2_2,
                                                SGBSTDN_MAJR_CODE_CONC_221,
                                                SGBSTDN_MAJR_CODE_CONC_222,
                                                SGBSTDN_MAJR_CODE_CONC_223,
                                                SGBSTDN_CURR_RULE_1,
                                                SGBSTDN_CMJR_RULE_1_1,
                                                SGBSTDN_CCON_RULE_11_1,
                                                SGBSTDN_CCON_RULE_11_2,
                                                SGBSTDN_CCON_RULE_11_3,
                                                SGBSTDN_CMJR_RULE_1_2,
                                                SGBSTDN_CCON_RULE_12_1,
                                                SGBSTDN_CCON_RULE_12_2,
                                                SGBSTDN_CCON_RULE_12_3,
                                                SGBSTDN_CMNR_RULE_1_1,
                                                SGBSTDN_CMNR_RULE_1_2,
                                                SGBSTDN_CURR_RULE_2,
                                                SGBSTDN_CMJR_RULE_2_1,
                                                SGBSTDN_CCON_RULE_21_1,
                                                SGBSTDN_CCON_RULE_21_2,
                                                SGBSTDN_CCON_RULE_21_3,
                                                SGBSTDN_CMJR_RULE_2_2,
                                                SGBSTDN_CCON_RULE_22_1,
                                                SGBSTDN_CCON_RULE_22_2,
                                                SGBSTDN_CCON_RULE_22_3,
                                                SGBSTDN_CMNR_RULE_2_1,
                                                SGBSTDN_CMNR_RULE_2_2,
                                                SGBSTDN_PREV_CODE,
                                                SGBSTDN_TERM_CODE_PREV,
                                                SGBSTDN_CAST_CODE,
                                                SGBSTDN_TERM_CODE_CAST,
                                                'PROCESO_EG',
                                                user,
                                                SGBSTDN_SCPC_CODE,
                                                NULL,
                                                NULL,
                                                NULL
                                                FROM SGBSTDN a
                                                WHERE
                                                SGBSTDN_PIDM= c.pidm
                                                AND SGBSTDN_PROGRAM_1 = c.prog
                                                AND SGBSTDN_TERM_CODE_EFF in (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                                                                                                    FROM SGBSTDN a1
                                                                                                    WHERE a.SGBSTDN_PIDM=a1.SGBSTDN_PIDM
                                                                                                    AND a.SGBSTDN_PROGRAM_1=a1.SGBSTDN_PROGRAM_1);

                                              dbms_output.put_line( 'entro insert ' || c.pidm ||' - '||c.prog||'-'||c.per_cat);
                                       Exception
                                       When Others then
                                         begin
                                                dbms_output.put_line( 'Exception error entro a Update SGBSTDN ' || c.pidm ||' - '||c.prog||'-'||c.per_cat);
                                                v_error:=' Realiza Update a SGBSTDN y Se presento el error al insertar ='||sqlerrm;
                                                update  SGBSTDN a
                                                set  a.SGBSTDN_STST_CODE = stst_code,
                                                SGBSTDN_DATA_ORIGIN = 'PROCESO_U_EG',
                                                SGBSTDN_ACTIVITY_DATE=sysdate
                                                WHERE SGBSTDN_PIDM= c.pidm
                                                AND SGBSTDN_PROGRAM_1 = c.prog
                                                AND SGBSTDN_TERM_CODE_EFF in (SELECT MAX(SGBSTDN_TERM_CODE_EFF) FROM SGBSTDN a1
                                                                              WHERE a.SGBSTDN_PIDM=a1.SGBSTDN_PIDM
                                                                              AND a.SGBSTDN_PROGRAM_1=a1.SGBSTDN_PROGRAM_1);
                                         end;
                                       End;

                                       begin
                                          CASE WHEN SUBSTR(C.ID,1,2)='08' then
                                            UPDATE SZTHITA
                                             SET SZTHITA_STATUS='TRASPASO_'
                                                WHERE  SZTHITA_PIDM=C.PIDM
                                                AND  SZTHITA_PROG=C.PROG
                                                AND  SZTHITA_STATUS=c.stat;
                                           WHEN SUBSTR(C.ID,1,2)='30' and c.prog= v_programa then
                                            UPDATE SZTHITA
                                             SET SZTHITA_STATUS='TRASPASO_'
                                                WHERE  SZTHITA_PIDM=C.PIDM
                                                AND  SZTHITA_PROG=C.PROG
                                                AND  SZTHITA_STATUS=c.stat;
                                           ELSE
                                            UPDATE SZTHITA
                                             SET SZTHITA_STATUS='EGRESADO_'
                                                WHERE  SZTHITA_PIDM=C.PIDM
                                                AND  SZTHITA_PROG=C.PROG
                                                AND  SZTHITA_STATUS=c.stat;
                                          end case;
                                       Exception When Others then
                                           begin
                                                dbms_output.put_line( 'no actualizo SZTHITA: ' || c.pidm ||' programa: '||c.prog);
                                                null;
                                           end;
                                        End;



                                       Begin
                                           update SHRDGMR
                                           SET SHRDGMR_DEGS_CODE ='PE',
                                           SHRDGMR_ACTIVITY_DATE = sysdate,
                                           SHRDGMR_DATA_ORIGIN = 'PROCESO_EG'
                                           WHERE SHRDGMR_PIDM =c.pidm
                                           AND SHRDGMR_PROGRAM=c.prog;
                                       Exception
                                       When others then
                                        null;
                                       End;

                                        Begin
                                         dbms_output.put_line( 'entro 2  SGRSCMT PROCESO_EG  : ' || c.pidm ||' programa: '||c.prog||' per : '||vl_per_sgb);
                                             CASE WHEN SUBSTR(C.ID,1,2)='08' then
                                                     INSERT INTO SGRSCMT
                                                         VALUES (
                                                                      c.pidm,
                                                                      c.study,
                                                                      vl_per_sgb,
                                                                      'Cambio_estatus:  TR,  Proceso INSERTA-TRANSFERENCIA UOC',
                                                                      sysdate,
                                                                      null,
                                                                      0,
                                                                      null,
                                                                      'PROCESO_EG',
                                                                      null
                                                                  );
                                                 WHEN SUBSTR(C.ID,1,2)='30' and c.prog= v_programa then
                                                     INSERT INTO SGRSCMT
                                                      VALUES (
                                                                      c.pidm,
                                                                      c.study,
                                                                      vl_per_sgb,
                                                                      'Cambio_estatus:  TR,  Proceso INSERTA-TRANSFERENCIA AG_MENDEZ',
                                                                      sysdate,
                                                                      null,
                                                                      0,
                                                                      null,
                                                                      'PROCESO_EG',
                                                                      null
                                                                  );
                                                ELSE
                                                   INSERT INTO SGRSCMT
                                                      VALUES (
                                                                      c.pidm,
                                                                      c.study,
                                                                      vl_per_sgb,
                                                                      'Cambio_estatus:  EG,  Proceso INSERTA_EGRESADOS',
                                                                      sysdate,
                                                                      null,
                                                                      0,
                                                                      null,
                                                                      'PROCESO_EG',
                                                                      null
                                                                  );
                                             END CASE;
                                        Exception
                                         When Others then
                                           begin
                                                dbms_output.put_line( 'no entro 2  SGRSCMT: ' || c.pidm ||' programa: '||c.prog||' per : '||vl_per_sgb);
                                                null;
                                           end;
                                        End;

                                       dbms_output.put_line( 'salida ' || c.pidm ||' - '||c.prog||'-'||c.per_cat);
                                end if;


                                ---------------------------- Se apaga este codigo porque se solicita que Utelx se quede activo para los egresados -------------------------
                                /*


                                                    vl_utelx := 0;
                                                    Begin
                                                            select count(*)
                                                                Into vl_utelx
                                                            from  SZTUTLX b
                                                            where 1= 1
                                                            and b.SZTUTLX_PIDM = c.pidm
                                                            and b.SZTUTLX_DISABLE_IND = 'A'
                                                            and b.SZTUTLX_STAT_IND ='1'
                                                            and b.SZTUTLX_SEQ_NO = (select max (b1.SZTUTLX_SEQ_NO)
                                                                                                     from SZTUTLX b1
                                                                                                     Where 1= 1
                                                                                                     And b.SZTUTLX_PIDM = b1.SZTUTLX_PIDM
                                                                                                     );
                                                    Exception
                                                        When Others then
                                                            vl_utelx:=0;
                                                    End;

                                                    If vl_utelx >= 1 then
                                                    
                                                           vl_utelx:=0;
                                                    
                                                            Begin 
                                                                    Select count(*)
                                                                        Into vl_utelx
                                                                    from UTELX_CARGO
                                                                    Where  pidm = c.pidm
                                                                    And ORIGEN = 'SSB';
                                                            Exception
                                                                When Others then 
                                                                 vl_utelx:=0;
                                                            End;
                                                    
                                                           If vl_utelx = 0 then 
                                                                ---------- Aqui entrara el cambio de la funcion de Utel-x -----------------------
                                                                v_error:= PKG_UTLX.f_inserta_baja_utlx(c.pidm ,
                                                                                                       c.id,
                                                                                                       'EGRESO',
                                                                                                       sysdate );

                                                                commit;
                                                           End if;
                                                    End  if;
                                */


         end if;
    end loop;

   commit;

  end sp_inserta_egresados;


--PROCEDURE sp_inserta_egresados
--is
--
--vl_per_max varchar2(6);
--stst_code varchar(2);
--incorporante varchar2(15);
--vl_per_sgb varchar2(6) := null;
--v_error varchar2(4000);
--v_adeudo number;
--
--   begin
--        for c in (
--                      SELECT SZTHITA_PIDM PIDM,
--                                  SZTHITA_ID ID,
--                                  SZTHITA_PROG prog ,
--                                  SZTHITA_AVANCE ava,
--                                  SZTHITA_PER_CATALOGO per_cat,
--                                  SZTHITA_STUDY study,
--                                  SZTHITA_STATUS stat
--                       FROM  SZTHITA,SMBPGEN
--                      WHERE SZTHITA_AVANCE>=100
--                          AND SZTHITA_STATUS IN  ('MATRICULADO','PREMATRICULADO','ADMITIDO')
--                          AND SZTHITA_PROG=SMBPGEN_PROGRAM
--                          AND SZTHITA_PER_CATALOGO=SMBPGEN_TERM_CODE_EFF
--                          AND SMBPGEN_ACTIVE_IND='Y'
--                          AND SZTHITA_APROB>=SMBPGEN_REQ_COURSES_I_TRAD
--                  )
--
--    loop
--
--            vl_per_max := null;
--            stst_code := null;
--            incorporante := null;
--            vl_per_sgb := null;
--            v_adeudo:=0;
--
--         if c.ava >=100  then
--
--                                  Begin
--                                    SELECT DISTINCT MAX(SHRTCKN_TERM_CODE)
--                                            INTO vl_per_max
--                                    FROM SHRTCKN
--                                    WHERE  SHRTCKN_PIDM=c.pidm
--                                    AND SHRTCKN_STSP_KEY_SEQUENCE =c.study
--                                    AND SUBSTR(SHRTCKN_TERM_CODE,5,1) NOT IN ('8','9');
--                                 Exception
--                                 When Others then
--                                    vl_per_max := null;
--                                 End;
--
--                               Begin
--                                    Select a.sgbstdn_term_code_eff
--                                        into vl_per_sgb
--                                    from sgbstdn a
--                                    where a.sgbstdn_pidm = c.pidm
--                                    and a.sgbstdn_program_1 = c.prog
--                                    and a.sgbstdn_term_code_eff = (select max (a1.sgbstdn_term_code_eff)
--                                                                                    from sgbstdn a1
--                                                                                    where a.sgbstdn_pidm = a1.sgbstdn_pidm
--                                                                                    and a.sgbstdn_program_1 = a1.sgbstdn_program_1);
--                               Exception
--                                    When Others then
--                                       vl_per_sgb := null;
--                               End;
--
--
--                                begin
--                                select  sztdtec_incorporante
--                                    into incorporante
--                                 from sztdtec
--                                where sztdtec_program=c.prog
--                                and sztdtec_status='ACTIVO'
--                                And  SZTDTEC_TERM_CODE = c.per_cat;
--                                exception when others then
--                                 incorporante:=null;
--                                end;
--
--                                if incorporante='SEGEM' then
--                                   stst_code:='SG';
--                                else
--                                   stst_code:='EG';
--                                end if;
--
--                                select PKG_DASHBOARD_ALUMNO.f_dashboard_saldototal(c.pidm) into v_adeudo from dual;    --- cambio para  alumnos 08 si tiene adeudos no cambia a TR traspaso
--
--                                IF v_adeudo=0 then
--                                      IF  SUBSTR(C.ID,1,2)='08' then
--                                          stst_code:='TR';
--                                      end if;
--                                end if;
--
--
--                                If vl_per_sgb > vl_per_max then
--                                       Begin
--                                          Update sgbstdn a
--                                           set SGBSTDN_STST_CODE = stst_code,
--                                                SGBSTDN_DATA_ORIGIN = 'PROCESO_EGX',
--                                                SGBSTDN_ACTIVITY_DATE=sysdate
--                                           where a.SGBSTDN_PIDM = c.pidm
--                                           and a.SGBSTDN_PROGRAM_1 = c.prog
--                                            And a.sgbstdn_term_code_eff = (select max (a1.sgbstdn_term_code_eff) from sgbstdn a1
--                                                                                                      where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
--                                                                                                          and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1);
--                                       Exception
--                                        When Others then
--                                                 v_error:='Se presento el error ='||sqlerrm;
--                                        End;
--
--                                       Begin
--                                          IF  SUBSTR(C.ID,1,2)='08' then
--                                            UPDATE SZTHITA
--                                             SET SZTHITA_STATUS='TRASPASO_'
--                                                WHERE  SZTHITA_PIDM=C.PIDM
--                                                AND  SZTHITA_PROG=C.PROG
--                                                AND  SZTHITA_STATUS=c.stat;
--                                         else
--                                            UPDATE SZTHITA
--                                             SET SZTHITA_STATUS='EGRESADO_'
--                                                WHERE  SZTHITA_PIDM=C.PIDM
--                                                AND  SZTHITA_PROG=C.PROG
--                                                AND  SZTHITA_STATUS=c.stat;
--                                          end if;
--                                       Exception
--                                        When Others then
--                                                null;
--                                        End;
--
--                                        Begin
--                                         dbms_output.put_line( 'entro 1  SGRSCMT PROCESO_EG  : ' || c.pidm ||' programa: '||c.prog||' per: '||vl_per_sgb);
--                                         IF  SUBSTR(C.ID,1,2)='08' then
--                                                 INSERT INTO SGRSCMT
--                                                  VALUES (
--                                                                  c.pidm,
--                                                                  c.study,
--                                                                  vl_per_sgb,
--                                                                  'Cambio_estatus:  TR,  Proceso INSERTA-TRANSFERENCIA UOC',
--                                                                  sysdate,
--                                                                  null,
--                                                                  0,
--                                                                  null,
--                                                                  'PROCESO_EG',
--                                                                  null
--                                                              );
--                                            ELSE
--                                               INSERT INTO SGRSCMT
--                                                  VALUES (
--                                                                  c.pidm,
--                                                                  c.study,
--                                                                  vl_per_sgb,
--                                                                  'Cambio_estatus:  EG,  Proceso INSERTA_EGRESADOS',
--                                                                  sysdate,
--                                                                  null,
--                                                                  0,
--                                                                  null,
--                                                                  'PROCESO_EG',
--                                                                  null
--                                                              );
--                                             END IF;
--                                        Exception When Others then
--                                           begin
--                                                dbms_output.put_line( 'no entro 1  SGRSCMT: ' || c.pidm ||' programa: '||c.prog||' per: '||vl_per_sgb);
--                                                null;
--                                           end;
--                                        End;
--                              Else
--                                        Begin
--                                                INSERT INTO SGBSTDN
--                                                SELECT
--                                                SGBSTDN_PIDM,
--                                                vl_per_max,
--                                                stst_code,
--                                                SGBSTDN_LEVL_CODE,
--                                                SGBSTDN_STYP_CODE,
--                                                SGBSTDN_TERM_CODE_MATRIC,
--                                                SGBSTDN_TERM_CODE_ADMIT,
--                                                SGBSTDN_EXP_GRAD_DATE,
--                                                SGBSTDN_CAMP_CODE,
--                                                SGBSTDN_FULL_PART_IND,
--                                                SGBSTDN_SESS_CODE,
--                                                SGBSTDN_RESD_CODE,
--                                                SGBSTDN_COLL_CODE_1,
--                                                SGBSTDN_DEGC_CODE_1,
--                                                SGBSTDN_MAJR_CODE_1,
--                                                SGBSTDN_MAJR_CODE_MINR_1,
--                                                SGBSTDN_MAJR_CODE_MINR_1_2,
--                                                SGBSTDN_MAJR_CODE_CONC_1,
--                                                SGBSTDN_MAJR_CODE_CONC_1_2,
--                                                SGBSTDN_MAJR_CODE_CONC_1_3,
--                                                SGBSTDN_COLL_CODE_2,
--                                                SGBSTDN_DEGC_CODE_2,
--                                                SGBSTDN_MAJR_CODE_2,
--                                                SGBSTDN_MAJR_CODE_MINR_2,
--                                                SGBSTDN_MAJR_CODE_MINR_2_2,
--                                                SGBSTDN_MAJR_CODE_CONC_2,
--                                                SGBSTDN_MAJR_CODE_CONC_2_2,
--                                                SGBSTDN_MAJR_CODE_CONC_2_3,
--                                                SGBSTDN_ORSN_CODE,
--                                                SGBSTDN_PRAC_CODE,
--                                                SGBSTDN_ADVR_PIDM,
--                                                SGBSTDN_GRAD_CREDIT_APPR_IND,
--                                                SGBSTDN_CAPL_CODE,
--                                                SGBSTDN_LEAV_CODE,
--                                                SGBSTDN_LEAV_FROM_DATE,
--                                                SGBSTDN_LEAV_TO_DATE,
--                                                SGBSTDN_ASTD_CODE,
--                                                SGBSTDN_TERM_CODE_ASTD,
--                                                SGBSTDN_RATE_CODE,
--                                                sysdate,
--                                                SGBSTDN_MAJR_CODE_1_2,
--                                                SGBSTDN_MAJR_CODE_2_2,
--                                                SGBSTDN_EDLV_CODE,
--                                                SGBSTDN_INCM_CODE,
--                                                SGBSTDN_ADMT_CODE,
--                                                SGBSTDN_EMEX_CODE,
--                                                SGBSTDN_APRN_CODE,
--                                                SGBSTDN_TRCN_CODE,
--                                                SGBSTDN_GAIN_CODE,
--                                                SGBSTDN_VOED_CODE,
--                                                SGBSTDN_BLCK_CODE,
--                                                SGBSTDN_TERM_CODE_GRAD,
--                                                SGBSTDN_ACYR_CODE,
--                                                SGBSTDN_DEPT_CODE,
--                                                SGBSTDN_SITE_CODE,
--                                                SGBSTDN_DEPT_CODE_2,
--                                                SGBSTDN_EGOL_CODE,
--                                                SGBSTDN_DEGC_CODE_DUAL,
--                                                SGBSTDN_LEVL_CODE_DUAL,
--                                                SGBSTDN_DEPT_CODE_DUAL,
--                                                SGBSTDN_COLL_CODE_DUAL,
--                                                SGBSTDN_MAJR_CODE_DUAL,
--                                                SGBSTDN_BSKL_CODE,
--                                                SGBSTDN_PRIM_ROLL_IND,
--                                                SGBSTDN_PROGRAM_1,
--                                                SGBSTDN_TERM_CODE_CTLG_1,
--                                                SGBSTDN_DEPT_CODE_1_2,
--                                                SGBSTDN_MAJR_CODE_CONC_121,
--                                                SGBSTDN_MAJR_CODE_CONC_122,
--                                                SGBSTDN_MAJR_CODE_CONC_123,
--                                                SGBSTDN_SECD_ROLL_IND,
--                                                SGBSTDN_TERM_CODE_ADMIT_2,
--                                                SGBSTDN_ADMT_CODE_2,
--                                                SGBSTDN_PROGRAM_2,
--                                                SGBSTDN_TERM_CODE_CTLG_2,
--                                                SGBSTDN_LEVL_CODE_2,
--                                                SGBSTDN_CAMP_CODE_2,
--                                                SGBSTDN_DEPT_CODE_2_2,
--                                                SGBSTDN_MAJR_CODE_CONC_221,
--                                                SGBSTDN_MAJR_CODE_CONC_222,
--                                                SGBSTDN_MAJR_CODE_CONC_223,
--                                                SGBSTDN_CURR_RULE_1,
--                                                SGBSTDN_CMJR_RULE_1_1,
--                                                SGBSTDN_CCON_RULE_11_1,
--                                                SGBSTDN_CCON_RULE_11_2,
--                                                SGBSTDN_CCON_RULE_11_3,
--                                                SGBSTDN_CMJR_RULE_1_2,
--                                                SGBSTDN_CCON_RULE_12_1,
--                                                SGBSTDN_CCON_RULE_12_2,
--                                                SGBSTDN_CCON_RULE_12_3,
--                                                SGBSTDN_CMNR_RULE_1_1,
--                                                SGBSTDN_CMNR_RULE_1_2,
--                                                SGBSTDN_CURR_RULE_2,
--                                                SGBSTDN_CMJR_RULE_2_1,
--                                                SGBSTDN_CCON_RULE_21_1,
--                                                SGBSTDN_CCON_RULE_21_2,
--                                                SGBSTDN_CCON_RULE_21_3,
--                                                SGBSTDN_CMJR_RULE_2_2,
--                                                SGBSTDN_CCON_RULE_22_1,
--                                                SGBSTDN_CCON_RULE_22_2,
--                                                SGBSTDN_CCON_RULE_22_3,
--                                                SGBSTDN_CMNR_RULE_2_1,
--                                                SGBSTDN_CMNR_RULE_2_2,
--                                                SGBSTDN_PREV_CODE,
--                                                SGBSTDN_TERM_CODE_PREV,
--                                                SGBSTDN_CAST_CODE,
--                                                SGBSTDN_TERM_CODE_CAST,
--                                                'PROCESO_EG',
--                                                user,
--                                                SGBSTDN_SCPC_CODE,
--                                                NULL,
--                                                NULL,
--                                                NULL
--                                                FROM SGBSTDN a
--                                                WHERE
--                                                SGBSTDN_PIDM= c.pidm
--                                                AND SGBSTDN_PROGRAM_1 = c.prog
--                                                AND SGBSTDN_TERM_CODE_EFF in (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
--                                                                                                    FROM SGBSTDN a1
--                                                                                                    WHERE a.SGBSTDN_PIDM=a1.SGBSTDN_PIDM
--                                                                                                    AND a.SGBSTDN_PROGRAM_1=a1.SGBSTDN_PROGRAM_1);
--
--                                              dbms_output.put_line( 'entro insert ' || c.pidm ||' - '||c.prog||'-'||c.per_cat);
--                                       Exception
--                                       When Others then
--                                         begin
--                                                dbms_output.put_line( 'Exception error entro a Update SGBSTDN ' || c.pidm ||' - '||c.prog||'-'||c.per_cat);
--                                                v_error:=' Realiza Update a SGBSTDN y Se presento el error al insertar ='||sqlerrm;
--                                                update  SGBSTDN a
--                                                set  a.SGBSTDN_STST_CODE = stst_code,
--                                                SGBSTDN_DATA_ORIGIN = 'PROCESO_U_EG',
--                                                SGBSTDN_ACTIVITY_DATE=sysdate
--                                                WHERE SGBSTDN_PIDM= c.pidm
--                                                AND SGBSTDN_PROGRAM_1 = c.prog
--                                                AND SGBSTDN_TERM_CODE_EFF in (SELECT MAX(SGBSTDN_TERM_CODE_EFF) FROM SGBSTDN a1
--                                                                              WHERE a.SGBSTDN_PIDM=a1.SGBSTDN_PIDM
--                                                                              AND a.SGBSTDN_PROGRAM_1=a1.SGBSTDN_PROGRAM_1);
--                                         end;
--                                       End;
--
--                                       Begin
--                                          IF  SUBSTR(C.ID,1,2)='08' then
--                                            UPDATE SZTHITA
--                                             SET SZTHITA_STATUS='TRASPASO_'
--                                                WHERE  SZTHITA_PIDM=C.PIDM
--                                                AND  SZTHITA_PROG=C.PROG
--                                                AND  SZTHITA_STATUS=c.stat;
--                                          else
--                                            UPDATE SZTHITA
--                                             SET SZTHITA_STATUS='EGRESADO_'
--                                                WHERE  SZTHITA_PIDM=C.PIDM
--                                                AND  SZTHITA_PROG=C.PROG
--                                                AND  SZTHITA_STATUS=c.stat;
--                                          end if;
--                                       Exception
--                                       When Others then
--                                              null;
--                                       End;
--
--                                       Begin
--                                           update SHRDGMR
--                                           SET SHRDGMR_DEGS_CODE ='PE',
--                                           SHRDGMR_ACTIVITY_DATE = sysdate,
--                                           SHRDGMR_DATA_ORIGIN = 'PROCESO_EG'
--                                           WHERE SHRDGMR_PIDM =c.pidm
--                                           AND SHRDGMR_PROGRAM=c.prog;
--                                       Exception
--                                       When others then
--                                        null;
--                                       End;
--
--                                        Begin
--                                         dbms_output.put_line( 'entro 2  SGRSCMT PROCESO_EG  : ' || c.pidm ||' programa: '||c.prog||' per : '||vl_per_sgb);
--                                             IF  SUBSTR(C.ID,1,2)='08' then
--                                                 INSERT INTO SGRSCMT
--                                                  VALUES (
--                                                                  c.pidm,
--                                                                  c.study,
--                                                                  vl_per_sgb,
--                                                                  'Cambio_estatus:  TR,  Proceso INSERTA-TRANSFERENCIA UOC',
--                                                                  sysdate,
--                                                                  null,
--                                                                  0,
--                                                                  null,
--                                                                  'PROCESO_EG',
--                                                                  null
--                                                              );
--                                             ELSE
--                                               INSERT INTO SGRSCMT
--                                                  VALUES (
--                                                                  c.pidm,
--                                                                  c.study,
--                                                                  vl_per_sgb,
--                                                                  'Cambio_estatus:  EG,  Proceso INSERTA_EGRESADOS',
--                                                                  sysdate,
--                                                                  null,
--                                                                  0,
--                                                                  null,
--                                                                  'PROCESO_EG',
--                                                                  null
--                                                              );
--                                             END IF;
--                                        Exception
--                                         When Others then
--                                           begin
--                                                dbms_output.put_line( 'no entro 2  SGRSCMT: ' || c.pidm ||' programa: '||c.prog||' per : '||vl_per_sgb);
--                                                null;
--                                           end;
--                                        End;
--
--                                       dbms_output.put_line( 'salida ' || c.pidm ||' - '||c.prog||'-'||c.per_cat);
--                                end if;
--         end if;
--    end loop;
--
--   commit;
--
--  end;

PROCEDURE sp_cambia_tipo_alumno
is

styp_code    varchar2(1);

   begin

     for c in (

              SELECT SZTHITA_PIDM PIDM, SZTHITA_ID ID,SZTHITA_PROG prog ,SZTHITA_STATUS stta ,SZTHITA_AVANCE ava,SZTHITA_PER_CATALOGO per_cat,SZTHITA_STUDY study  FROM  SZTHITA
              WHERE (SZTHITA_AVANCE>0 and  SZTHITA_AVANCE<100) AND SZTHITA_STATUS in ('MATRICULADO','PREMATRICULADO','ADMITIDO')

               )

     loop

                -- Verifica si el ultimo estatus de tipo de alumno
                                Begin
                                    select sgbstdn_styp_code into styp_code from sgbstdn s
                                      where sgbstdn_pidm=c.pidm and sgbstdn_program_1=c.prog
                                      and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn ss
                                                   where s.sgbstdn_pidm=ss.sgbstdn_pidm and s.sgbstdn_program_1=ss.sgbstdn_program_1);
                                Exception
                                When Others then
                                    styp_code := null;
                                End;

               -- Si es N=Nuevo Ingreso lo cambia a C=Continuo
                              if styp_code in ('N', 'R' ) then
                                 update sgbstdn s set sgbstdn_styp_code='C',
                                           SGBSTDN_ACTIVITY_DATE = sysdate,
                                           SGBSTDN_DATA_ORIGIN ='PROCESO'
                                  where sgbstdn_pidm=c.pidm and sgbstdn_program_1=c.prog
                                  and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn ss
                                           where s.sgbstdn_pidm=ss.sgbstdn_pidm and s.sgbstdn_program_1=ss.sgbstdn_program_1);
                              end if;

     end loop;

    commit;

  end;
function e_cur( pidm1 number, prog varchar2) return varchar2 is

ecur varchar2(2);

begin

select COUNT(*)
into ecur
from sfrstcr, sorlcur w, ssbsect,  smrpaap s, smrarul, smracaa, sgbstdn x
        where  smrpaap_program=prog
           and      smrpaap_area=smrarul_area
           and      smracaa_area=smrarul_area and  smracaa_rule=smrarul_key_rule and  smracaa_area not in ('UTLMTI0101',
                                                                                                                                                              'UTLLTE0101',
                                                                                                                                                              'UTLLTI0101',
                                                                                                                                                              'UTLLTS0101',
                                                                                                                                                              'UTLLTT0110',
                                                                                                                                                              'UOCATN0101',
                                                                                                                                                              'UTSMTI0101',
                                                                                                                                                              'UNAMPT0111',
                                                                                                                                                              'UVEBTB0101',
                                                                                                                                                              'UTLTSS0110')
           and     sorlcur_pidm=pidm1 and sorlcur_lmod_code='LEARNER'
           and     sorlcur_program=smrpaap_program and sorlcur_lmod_code='LEARNER'
           and     sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ww
                                               where w.sorlcur_pidm=ww.sorlcur_pidm
                                               and     w.sorlcur_program=ww.sorlcur_program
                                               and    w.sorlcur_lmod_code=ww.sorlcur_lmod_code
                                                and    w.sorlcur_lmod_code=ww.sorlcur_lmod_code)
           AND smrpaap_term_code_eff = sorlcur_term_code_ctlg
           and     sfrstcr_pidm=sorlcur_pidm
           and sfrstcr_grde_code is null and sfrstcr_rsts_code='RE'
           and    ssbsect_term_code=sfrstcr_term_code
           and    ssbsect_crn=sfrstcr_crn
           and    sfrstcr_pidm not in (select shrtckn_pidm from shrtckn
                                            where sfrstcr_term_code=shrtckn_term_code and sfrstcr_crn=shrtckn_crn)
           and     sgbstdn_pidm=sorlcur_pidm
           and     sgbstdn_program_1=smrpaap_program
           and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                            where x.sgbstdn_pidm=xx.sgbstdn_pidm
                                                            and    x.sgbstdn_program_1=xx.sgbstdn_program_1)
           and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
            (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
            (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
           and     ssbsect_subj_code=smrarul_subj_code
           and     ssbsect_crse_numb=smrarul_crse_numb_low;


    return ecur;

end e_cur;

Procedure p_actualiza_outcome is



  CONT NUMBER:=0;

  CURSOR C_1 (P_PIDM NUMBER) IS
          SELECT *
          FROM (SELECT DISTINCT
                       A.SORLCUR_PIDM PIDM_A,
                       A.SORLCUR_LMOD_CODE MODO_A,
                       A.SORLCUR_TERM_CODE_CTLG PERIODO_A,
                       B.SORLCUR_LMOD_CODE MODO_B,
                       B.SORLCUR_TERM_CODE_CTLG PERIODO_B,
                       A.SORLCUR_PROGRAM PROG_A,
                       B.SORLCUR_PROGRAM PROG_B,
                       B.ROWID ROW_B,
                       A.SORLCUR_SEQNO SEQ_A,
                       B.SORLCUR_SEQNO SEQ_B,
                       (SELECT MAX (SORLCUR_KEY_SEQNO)
                          FROM SORLCUR
                         WHERE     SORLCUR_PIDM = A.SORLCUR_PIDM
                               AND SORLCUR_PROGRAM = B.SORLCUR_PROGRAM
                               AND SORLCUR_KEY_SEQNO <> B.SORLCUR_KEY_SEQNO)
                          KEY_SEQ_BB,
                       a.SORLCUR_KEY_SEQNO KEY_SEQ_A,
                       'SOLCUR IN SGBST'
                  FROM SORLCUR A, SORLCUR B, sgbstdn C
                 WHERE A.SORLCUR_PIDM = B.SORLCUR_PIDM
                       AND A.SORLCUR_KEY_SEQNO = B.SORLCUR_KEY_SEQNO
                       AND (A.SORLCUR_TERM_CODE_CTLG <> B.SORLCUR_TERM_CODE_CTLG
                            OR A.SORLCUR_PROGRAM <> B.SORLCUR_PROGRAM)
                       AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                       --            and A.SORLCUR_ROLL_IND  = 'Y'
                       --            And A.SORLCUR_CACT_CODE = 'ACTIVE'
                       AND B.SORLCUR_LMOD_CODE = 'OUTCOME'
                       AND A.sorlcur_pidm = C.sgbstdn_pidm
                       AND A.sorlcur_program = C.sgbstdn_program_1 --CUANDO SI COINCIDEN
                       AND A.SORLCUR_TERM_CODE_CTLG = C.sgbstdn_TERM_CODE_CTLG_1
                       AND C.sgbstdn_term_code_eff IN
                              (SELECT MAX (b1.sgbstdn_term_code_eff)
                                 FROM sgbstdn b1
                                WHERE     b1.sgbstdn_pidm = C.sgbstdn_pidm
                                      AND b1.SGBSTDN_STYP_CODE = C.SGBSTDN_STYP_CODE
                                      AND b1.sgbstdn_program_1 = C.sgbstdn_program_1)
                       AND A.SORLCUR_SEQNO =
                              (SELECT MAX (SORLCUR_SEQNO)
                                 FROM SORLCUR C
                                WHERE     C.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                      AND C.SORLCUR_PIDM = A.SORLCUR_PIDM
                                      AND C.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM)
                -- AND A.SORLCUR_PIDM = 3540
                UNION
                SELECT DISTINCT
                       A.SORLCUR_PIDM PIDM_A,
                       A.SORLCUR_LMOD_CODE MODO_A,
                       A.SORLCUR_TERM_CODE_CTLG PERIODO_A,
                       B.SORLCUR_LMOD_CODE MODO_B,
                       B.SORLCUR_TERM_CODE_CTLG PERIODO_B,
                       A.SORLCUR_PROGRAM PROG_A,
                       B.SORLCUR_PROGRAM PROG_B,
                       B.ROWID ROW_B,
                       A.SORLCUR_SEQNO SEQ_A,
                       B.SORLCUR_SEQNO SEQ_B,
                       (SELECT MAX (SORLCUR_KEY_SEQNO)
                          FROM SORLCUR
                         WHERE     SORLCUR_PIDM = A.SORLCUR_PIDM
                               AND SORLCUR_PROGRAM = B.SORLCUR_PROGRAM
                               AND SORLCUR_KEY_SEQNO <> B.SORLCUR_KEY_SEQNO)
                          KEY_SEQ_BB,
                       a.SORLCUR_KEY_SEQNO KEY_SEQ_A,
                       'SOLCUR NOT IN SGBST'
                  FROM SORLCUR A, SORLCUR B                             --,  sgbstdn C
                 WHERE A.SORLCUR_PIDM = B.SORLCUR_PIDM
                       AND A.SORLCUR_KEY_SEQNO = B.SORLCUR_KEY_SEQNO
                       AND (A.SORLCUR_TERM_CODE_CTLG <> B.SORLCUR_TERM_CODE_CTLG
                            OR A.SORLCUR_PROGRAM <> B.SORLCUR_PROGRAM)
                       AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                       --            and A.SORLCUR_ROLL_IND  = 'Y'
                       --            And A.SORLCUR_CACT_CODE = 'ACTIVE'
                       AND B.SORLCUR_LMOD_CODE = 'OUTCOME'
                       AND NOT EXISTS
                                  (SELECT 1
                                     FROM sgbstdn C
                                    WHERE A.sorlcur_pidm = C.sgbstdn_pidm
                                          AND A.sorlcur_program = C.sgbstdn_program_1 --CUANDO SI COINCIDEN
                                          AND A.SORLCUR_TERM_CODE_CTLG =
                                                 C.sgbstdn_TERM_CODE_CTLG_1
                                          AND C.sgbstdn_term_code_eff IN
                                                 (SELECT MAX (
                                                            b1.sgbstdn_term_code_eff)
                                                    FROM sgbstdn b1
                                                   WHERE b1.sgbstdn_pidm =
                                                            C.sgbstdn_pidm
                                                         AND b1.SGBSTDN_STYP_CODE =
                                                                C.SGBSTDN_STYP_CODE
                                                         AND b1.sgbstdn_program_1 =
                                                                C.sgbstdn_program_1))
                       AND A.SORLCUR_SEQNO =
                              (SELECT MAX (SORLCUR_SEQNO)
                                 FROM SORLCUR C
                                WHERE     C.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                      AND C.SORLCUR_PIDM = A.SORLCUR_PIDM
                                      AND C.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM))
         WHERE PIDM_A = NVL (P_PIDM, PIDM_A)  ;

      CURSOR C_2 (P_PIDM NUMBER) IS
          SELECT *
          FROM (SELECT DISTINCT
                       A.SORLCUR_PIDM PIDM_A,
                       A.SORLCUR_LMOD_CODE MODO_A,
                       A.SORLCUR_TERM_CODE_CTLG PERIODO_A,
                       B.SORLCUR_LMOD_CODE MODO_B,
                       B.SORLCUR_TERM_CODE_CTLG PERIODO_B,
                       A.SORLCUR_PROGRAM PROG_A,
                       B.SORLCUR_PROGRAM PROG_B,
                       B.ROWID ROW_B,
                       A.SORLCUR_SEQNO SEQ_A,
                       B.SORLCUR_SEQNO SEQ_B,
                       (SELECT MAX (SORLCUR_KEY_SEQNO)
                          FROM SORLCUR
                         WHERE     SORLCUR_PIDM = A.SORLCUR_PIDM
                               AND SORLCUR_PROGRAM = B.SORLCUR_PROGRAM
                               AND SORLCUR_KEY_SEQNO <> B.SORLCUR_KEY_SEQNO)
                          KEY_SEQ_BB,
                       a.SORLCUR_KEY_SEQNO KEY_SEQ_A,
                       'SOLCUR IN SGBST'
                  FROM SORLCUR A, SORLCUR B, sgbstdn C
                 WHERE A.SORLCUR_PIDM = B.SORLCUR_PIDM
                       AND A.SORLCUR_KEY_SEQNO = B.SORLCUR_KEY_SEQNO
                       AND (A.SORLCUR_TERM_CODE_CTLG <> B.SORLCUR_TERM_CODE_CTLG
                            OR A.SORLCUR_PROGRAM <> B.SORLCUR_PROGRAM)
                       AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                       --            and A.SORLCUR_ROLL_IND  = 'Y'
                       --            And A.SORLCUR_CACT_CODE = 'ACTIVE'
                       AND B.SORLCUR_LMOD_CODE = 'OUTCOME'
                       AND A.sorlcur_pidm = C.sgbstdn_pidm
                       AND A.sorlcur_program = C.sgbstdn_program_1 --CUANDO SI COINCIDEN
                       AND A.SORLCUR_TERM_CODE_CTLG = C.sgbstdn_TERM_CODE_CTLG_1
                       AND C.sgbstdn_term_code_eff IN
                              (SELECT MAX (b1.sgbstdn_term_code_eff)
                                 FROM sgbstdn b1
                                WHERE     b1.sgbstdn_pidm = C.sgbstdn_pidm
                                      AND b1.SGBSTDN_STYP_CODE = C.SGBSTDN_STYP_CODE
                                      AND b1.sgbstdn_program_1 = C.sgbstdn_program_1)
                       AND A.SORLCUR_SEQNO =
                              (SELECT MAX (SORLCUR_SEQNO)
                                 FROM SORLCUR C
                                WHERE     C.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                      AND C.SORLCUR_PIDM = A.SORLCUR_PIDM
                                      AND C.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM)
                -- AND A.SORLCUR_PIDM = 3540
                UNION
                SELECT DISTINCT
                       A.SORLCUR_PIDM PIDM_A,
                       A.SORLCUR_LMOD_CODE MODO_A,
                       A.SORLCUR_TERM_CODE_CTLG PERIODO_A,
                       B.SORLCUR_LMOD_CODE MODO_B,
                       B.SORLCUR_TERM_CODE_CTLG PERIODO_B,
                       A.SORLCUR_PROGRAM PROG_A,
                       B.SORLCUR_PROGRAM PROG_B,
                       B.ROWID ROW_B,
                       A.SORLCUR_SEQNO SEQ_A,
                       B.SORLCUR_SEQNO SEQ_B,
                       (SELECT MAX (SORLCUR_KEY_SEQNO)
                          FROM SORLCUR
                         WHERE     SORLCUR_PIDM = A.SORLCUR_PIDM
                               AND SORLCUR_PROGRAM = B.SORLCUR_PROGRAM
                               AND SORLCUR_KEY_SEQNO <> B.SORLCUR_KEY_SEQNO)
                          KEY_SEQ_BB,
                       a.SORLCUR_KEY_SEQNO KEY_SEQ_A,
                       'SOLCUR NOT IN SGBST'
                  FROM SORLCUR A, SORLCUR B                             --,  sgbstdn C
                 WHERE A.SORLCUR_PIDM = B.SORLCUR_PIDM
                       AND A.SORLCUR_KEY_SEQNO = B.SORLCUR_KEY_SEQNO
                       AND (A.SORLCUR_TERM_CODE_CTLG <> B.SORLCUR_TERM_CODE_CTLG
                            OR A.SORLCUR_PROGRAM <> B.SORLCUR_PROGRAM)
                       AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                       --            and A.SORLCUR_ROLL_IND  = 'Y'
                       --            And A.SORLCUR_CACT_CODE = 'ACTIVE'
                       AND B.SORLCUR_LMOD_CODE = 'OUTCOME'
                       AND NOT EXISTS
                                  (SELECT 1
                                     FROM sgbstdn C
                                    WHERE A.sorlcur_pidm = C.sgbstdn_pidm
                                          AND A.sorlcur_program = C.sgbstdn_program_1 --CUANDO SI COINCIDEN
                                          AND A.SORLCUR_TERM_CODE_CTLG =
                                                 C.sgbstdn_TERM_CODE_CTLG_1
                                          AND C.sgbstdn_term_code_eff IN
                                                 (SELECT MAX (
                                                            b1.sgbstdn_term_code_eff)
                                                    FROM sgbstdn b1
                                                   WHERE b1.sgbstdn_pidm =
                                                            C.sgbstdn_pidm
                                                         AND b1.SGBSTDN_STYP_CODE =
                                                                C.SGBSTDN_STYP_CODE
                                                         AND b1.sgbstdn_program_1 =
                                                                C.sgbstdn_program_1))
                       AND A.SORLCUR_SEQNO =
                              (SELECT MAX (SORLCUR_SEQNO)
                                 FROM SORLCUR C
                                WHERE     C.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                      AND C.SORLCUR_PIDM = A.SORLCUR_PIDM
                                      AND C.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM))
         WHERE PIDM_A = NVL (P_PIDM, PIDM_A)  ;


        BEGIN

           FOR X IN C_1 (NULL) LOOP

                    CONT:=CONT +1;

                    IF X.KEY_SEQ_BB IS NOT NULL THEN
                       UPDATE SORLCUR SET SORLCUR_KEY_SEQNO= X.KEY_SEQ_BB,
                                    SORLCUR_DATA_ORIGIN='UPDATE_KEY_SEQNO/ANT:'||X.SEQ_B
                       WHERE  SORLCUR_PIDM=X.PIDM_A
                       AND ROWID = X.ROW_B;
                    END IF;

                    FOR Y IN C_2 (X.PIDM_A) LOOP

                       IF Y.PERIODO_A IS NOT NULL THEN
                         UPDATE SORLCUR SET SORLCUR_TERM_CODE_CTLG= Y.PERIODO_A,
                                      SORLCUR_DATA_ORIGIN='UPDATE_CODE_CTLG/ANT:'||Y.PERIODO_B
                         WHERE  SORLCUR_PIDM=Y.PIDM_A
                         AND ROWID = Y.ROW_B;
                       END IF;

                    END LOOP;

           END LOOP;

           --dbms_output.put_line ('REG: '|| CONT);
           --ROLLBACK;
           COMMIT;
        END p_actualiza_outcome;


Procedure actualiza_tipo_alumno is

vl_tipo number:=0;
vl_recibido number:=0;

BEGIN

        For status in (

                            select
                                a.SGBSTDN_PIDM Pidm,
                                b.SPRIDEN_ID Matricula,
                                a.SGBSTDN_PROGRAM_1 Programa,
                                a.SGBSTDN_CAMP_CODE Campus,
                                a.SGBSTDN_STST_CODE Estatus,
                                SGBSTDN_TERM_CODE_EFF Periodo
                            from SGBSTDN a, SPRIDEN b
                            where a.SGBSTDN_PIDM = b.SPRIDEN_PIDM
                            and b.SPRIDEN_CHANGE_IND is null
                            and a.SGBSTDN_STST_CODE = 'AS'
                            and a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                                         from SGBSTDN a1
                                                                                         where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                                         And a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1)
                            order by a.SGBSTDN_PIDM

            )loop

                            ---- Documentos obligatorios por alumno ----
                            Begin
                                    select   count (*) tipo
                                        Into vl_tipo
                                    from SARCHKL a, sarappd b
                                    where b.SARAPPD_PIDM = SARCHKL_PIDM
                                    And b.SARAPPD_TERM_CODE_ENTRY = SARCHKL_TERM_CODE_ENTRY
                                    And b.SARAPPD_APPL_NO = SARCHKL_APPL_NO
                                    And b.SARAPPD_APDC_CODE in ( '35', '53')
                                    And a.SARCHKL_MANDATORY_IND = 'Y'
                                    and  b.SARAPPD_PIDM = status.pidm
                                    group by a.SARCHKL_PIDM ,  a.SARCHKL_MANDATORY_IND;
                            Exception
                                When Others then
                                  vl_tipo :=0;
                            End;


                           ---- Documentos obligatorios por Recibidos  ----
                            Begin
                                    select   count (*) tipo
                                        Into vl_recibido
                                    from SARCHKL a, sarappd b
                                    where b.SARAPPD_PIDM = SARCHKL_PIDM
                                    And b.SARAPPD_TERM_CODE_ENTRY = SARCHKL_TERM_CODE_ENTRY
                                    And b.SARAPPD_APPL_NO = SARCHKL_APPL_NO
                                    And b.SARAPPD_APDC_CODE in ( '35', '53')
                                    And a.SARCHKL_MANDATORY_IND = 'Y'
                                    And a.SARCHKL_CKST_CODE = 'VALIDADO'
                                    and  b.SARAPPD_PIDM = status.pidm
                                    group by a.SARCHKL_PIDM ,  a.SARCHKL_MANDATORY_IND;
                            Exception
                                When Others then
                                  vl_recibido :=0;
                            End;


                           If vl_tipo = vl_recibido then    -------> Todos los documentos Obligatorios recibidos Convierte a Matriculado

                                -- DBMS_OUTPUT.PUT_LINE('Matriculados ' ||status.matricula ||'*'||  status.estatus ||'*'||status.periodo);

                                Begin
                                        Update sgbstdn
                                            set SGBSTDN_STST_CODE = 'MA'
                                         where  SGBSTDN_PIDM = status.pidm
                                         and SGBSTDN_STST_CODE = status.estatus
                                         and SGBSTDN_TERM_CODE_EFF = status.periodo
                                         And SGBSTDN_PROGRAM_1 = status.programa;
                                Exception
                                When Others then
                                  null;
                                End;

                           ElsIf vl_tipo > vl_recibido and vl_recibido >= 1 then    -------> Todos los documentos Obligatorios recibidos Convierte a Prematriculado
                               -- DBMS_OUTPUT.PUT_LINE('Prematriculado ' ||status.matricula ||'*'||  status.estatus ||'*'||status.periodo);
                                Begin
                                        Update sgbstdn
                                            set SGBSTDN_STST_CODE = 'PR'
                                         where  SGBSTDN_PIDM = status.pidm
                                         and SGBSTDN_STST_CODE = status.estatus
                                         and SGBSTDN_TERM_CODE_EFF = status.periodo
                                         And SGBSTDN_PROGRAM_1 = status.programa;
                                Exception
                                When Others then
                                  null;
                                End;
                          ElsIf  vl_recibido = 0 then    -------> Todos los documentos Obligatorios recibidos Convierte a Prematriculado
                                --DBMS_OUTPUT.PUT_LINE('Admitido ' ||status.matricula ||'*'||  status.estatus ||'*'||status.periodo);
                                    null;

                           End if;

            End loop;

           Commit;

    END actualiza_tipo_alumno;


Procedure cancela_solicitud_duplicada is

Begin

        for c in (

        select count (*) cuantos, SARADAP_PROGRAM_1 programa, SARADAP_LEVL_CODE nivel, saradap_pidm pidm, spriden_id
        from saradap, spriden
        where SARADAP_APST_CODE = 'A'
        and spriden_pidm = saradap_pidm
        and spriden_change_ind is null
        --and saradap_pidm = 23553
        group by SARADAP_PROGRAM_1, SARADAP_LEVL_CODE, saradap_pidm, spriden_id
        having  count (*) > 1

        ) loop


        update saradap
        set SARADAP_APST_CODE = 'X',
             SARADAP_DATA_ORIGIN = trunc (sysdate)
        where saradap_pidm = c.pidm
        and SARADAP_PROGRAM_1 = c.programa
        and SARADAP_LEVL_CODE  = c.nivel
        and SARADAP_APST_CODE = 'A'
        and SARADAP_APPL_NO < c.cuantos;

        End Loop;

        Commit;

End cancela_solicitud_duplicada;


Procedure p_act_rate_jora_algo is


Begin

For jornada in (

                        Select distinct SZTPROC_PIDM Pidm, SZTPROC_CAMP_CODE Campus, SZTPROC_LEVL_CODE Nivel, SZTPROC_PROGRAM Programa, SZTPROC_STUDY_PATH Study, SZTPROC_FECHA_INI Fecha_Inicio,
                                  SZTPROC_JORNADA Jornada_Ant, SZTPROC_JORNADA_NW Jornada_Nw, SZTPROC_TERM_CTGL Catalogo_ctgl, SZTALGO_TERM_CODE periodo
                        from SZTPROC, sztalgo
                        where SZTPROC_JORNADA_nw is not null
                        And SZTALGO_CAMP_CODE = SZTPROC_CAMP_CODE
                        and SZTALGO_LEVL_CODE = SZTPROC_LEVL_CODE
                        and trunc (SZTALGO_FECHA_ANT) = trunc (SZTPROC_FECHA_INI)
                       -- and SZTPROC_PIDM = 22905

) loop


        Begin
                Update SGRSATT
                set SGRSATT_ATTS_CODE =  jornada.JORNADA_NW,
                     SGRSATT_TERM_CODE_EFF = jornada.periodo,
                     SGRSATT_DATA_ORIGIN = 'ALGORITMO',
                     SGRSATT_ACTIVITY_DATE = sysdate
                where SGRSATT_pidm = jornada.pidm
                And regexp_like  (SGRSATT_ATTS_CODE, '^[0-9]')
                --and SGRSATT_ATTS_CODE = jornada.jornada_ant
                and SGRSATT_STSP_KEY_SEQUENCE = jornada.study;
        Exception
            When Others then
              null;
        End;

End loop Jornada;


For Rate in (

                        Select distinct SZTPROC_PIDM Pidm, SZTPROC_CAMP_CODE Campus, SZTPROC_LEVL_CODE Nivel, SZTPROC_PROGRAM Programa, SZTPROC_STUDY_PATH Study,
                                            SZTPROC_FECHA_INI Fecha_Inicio, SZTPROC_RATE Rate_Ant, SZTPROC_RATE_NW Rate_Nw, SZTPROC_TERM_CTGL Catalogo_ctgl, SZTALGO_TERM_CODE periodo
                        from SZTPROC, sztalgo
                        where SZTPROC_RATE_NW is not null
                        And SZTALGO_CAMP_CODE = SZTPROC_CAMP_CODE
                        and SZTALGO_LEVL_CODE = SZTPROC_LEVL_CODE
                        and trunc (SZTALGO_FECHA_ANT) = trunc (SZTPROC_FECHA_INI)
                       -- and SZTPROC_PIDM = 22905

) loop


        Begin

                update sgbstdn
                set SGBSTDN_RATE_CODE = rate.rate_nw
                Where SGBSTDN_PIDM = rate.pidm
                And SGBSTDN_CAMP_CODE = rate.campus
                And SGBSTDN_LEVL_CODE = rate.nivel
                And SGBSTDN_PROGRAM_1 = rate.programa
                And SGBSTDN_RATE_CODE = rate.rate_ant;

        Exception
            When Others then
              null;
        End;

End loop Jornada;

Commit;



End p_act_rate_jora_algo;

Function f_estatus_final (vl_id varchar2 ) return varchar2 Is

vl_salida varchar2(10):= null;

Begin

           Begin
                   select distinct SGBSTDN_STST_CODE Estatus
                        Into vl_salida
                    from sgbstdn a, spriden
                    where a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                               from SGBSTDN a1
                                                                               Where a.sgbstdn_pidm = a1.sgbstdn_pidm)
                    and a.sgbstdn_pidm = spriden_pidm
                    and spriden_change_ind is null
                    and spriden_id = vl_id;

           Exception
            When Others then
               vl_salida := null;
           End;

Return vl_salida;

End f_estatus_final;


Procedure p_estatus_final_uoc
as

Begin

        for c in (

                        With aprobadas as (
                        SELECT DISTINCT  c.SFRSTCR_pidm pidm ,   SFRSTCR_STSP_KEY_SEQUENCE study , count (*) aprobadas
                        FROM ssbsect, SFRSTCR c , SHRGRDE
                        WHERE     SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE
                        AND SFRSTCR_CRN = SSBSECT_CRN
                        AND SFRSTCR_LEVL_CODE = SHRGRDE_LEVL_CODE
                        AND SFRSTCR_GRDE_CODE = SHRGRDE_CODE
                        AND SHRGRDE_PASSED_IND = 'Y'
                        group by c.SFRSTCR_pidm, SFRSTCR_STSP_KEY_SEQUENCE
                        ),
                         reprobadas as (
                        SELECT DISTINCT  c.SFRSTCR_pidm pidm ,   SFRSTCR_STSP_KEY_SEQUENCE study , count (*) reprobadas
                        FROM ssbsect, SFRSTCR c , SHRGRDE
                        WHERE     SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE
                        AND SFRSTCR_CRN = SSBSECT_CRN
                        AND SFRSTCR_LEVL_CODE = SHRGRDE_LEVL_CODE
                        AND SFRSTCR_GRDE_CODE = SHRGRDE_CODE
                        AND SHRGRDE_PASSED_IND = 'N'
                        group by c.SFRSTCR_pidm, SFRSTCR_STSP_KEY_SEQUENCE
                        ),
                         materias as (
                        SELECT DISTINCT  c.SFRSTCR_pidm pidm ,   SFRSTCR_STSP_KEY_SEQUENCE study , count (*) total
                        FROM ssbsect, SFRSTCR c
                        WHERE     SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE
                        AND SFRSTCR_CRN = SSBSECT_CRN
                        and SFRSTCR_RSTS_CODE = 'RE'
                        group by c.SFRSTCR_pidm, SFRSTCR_STSP_KEY_SEQUENCE
                        )
                        select  a.sorlcur_pidm, c.aprobadas, d.reprobadas, e.total, pkg_reportes.f_saldototal(a.sorlcur_pidm) saldo, SGBSTDN_STST_CODE estatus_actual, spriden_id matricula, b.sgbstdn_program_1 programa
                        from sorlcur a, sgbstdn b, aprobadas c, reprobadas d, materias e, spriden f
                        where a.SORLCUR_LMOD_CODE = 'LEARNER'
                        and a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
                                                                from sorlcur a1
                                                                where  a.sorlcur_pidm = a1.sorlcur_pidm
                                                                and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
                        and a.sorlcur_pidm = b.sgbstdn_pidm
                        and a.sorlcur_program = b.sgbstdn_program_1
                        and b.sgbstdn_term_code_eff = (select max (b1.sgbstdn_term_code_eff)
                                                                        from sgbstdn b1
                                                                        where b.sgbstdn_pidm = b1.sgbstdn_pidm
                                                                        and b.sgbstdn_program_1 = b1.sgbstdn_program_1
                                                                        and b.sgbstdn_camp_code = b1.sgbstdn_camp_code
                                                                        And b.sgbstdn_levl_code     = b1.sgbstdn_levl_code)
                        and b.sgbstdn_camp_code =  a.sorlcur_camp_code
                        and  b.sgbstdn_levl_code =   a.sorlcur_levl_code
                        and b.SGBSTDN_STST_CODE in ('AS', 'PR', 'MA', 'EG')
                        and a.sorlcur_camp_code = 'UOC'
                        and a.sorlcur_levl_code = 'MS'
                        and a.sorlcur_pidm = f.spriden_pidm
                        and f.spriden_change_ind is null
                        and a.sorlcur_pidm = c.pidm  (+)
                        and a.SORLCUR_KEY_SEQNO = c.study (+)
                        and a.sorlcur_pidm = d.pidm   (+)
                        and a.SORLCUR_KEY_SEQNO = d.study (+)
                        and a.sorlcur_pidm = e.pidm  (+)
                        and a.SORLCUR_KEY_SEQNO = e.study (+)
                        --and a.sorlcur_pidm = 828

                        ) loop

                        If c.aprobadas = c.total and c.saldo = 0 then
                             -- dbms_output.put_line('puntos:'||c.aprobadas||'*'|| c.total ||'*'||c.saldo );

                             Begin
                                   Update sgbstdn a
                                   set a.SGBSTDN_STST_CODE = 'TR',
                                         a.SGBSTDN_ACTIVITY_DATE = sysdate ,
                                         a.SGBSTDN_DATA_ORIGIN = 'PROCESO',
                                         a.SGBSTDN_USER_ID = 'PROCESO'
                                   wHERE a.sgbstdn_PIDM = c.sorlcur_pidm
                                   and a.sgbstdn_program_1 = c.programa
                                   and a.sgbstdn_term_code_eff = (select max (a.sgbstdn_term_code_eff)
                                                                                from sgbstdn a1
                                                                                where a.sgbstdn_PIDM = a1.sgbstdn_PIDM
                                                                                and a.sgbstdn_program_1 = a1.sgbstdn_program_1);
                              Exception
                              When Others then
                               null;
                               --dbms_output.put_line('errr:'||sqlerrm );
                              End;

                        End if;
        End loop;
        Commit;

End p_estatus_final_uoc;


Procedure p_cancela_solicitud as


vl_fecha date := null;
vl_fecha_o date := null;
vl_dias number :=0;
vl_exito varchar2 (500):= 'Exito';
max_seqno number:=0;

Begin
        for c in (


                     with inicio as (
                        select a.sorlcur_pidm pidm, a.SORLCUR_KEY_SEQNO study, trunc (a.SORLCUR_START_DATE) inicio, a.sorlcur_program programa, SORLCUR_VPDI_CODE parte
                        from sorlcur a
                        where a.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                          )
                        select distinct a.SARADAP_PIDM pidm, a.SARADAP_TERM_CODE_ENTRY periodo,
                                            a.SARADAP_APPL_NO solicitud , a.SARADAP_LEVL_CODE nivel , a.SARADAP_CAMP_CODE campus,
                                            a.SARADAP_APST_CODE estatus, c.inicio, d.spriden_id matricula, a.saradap_program_1 programa, c.parte,
                                            b.SARAPPD_APDC_CODE decision
                        from saradap a, sarappd b, inicio c, spriden d
                        where a.SARADAP_APST_CODE = 'A'
                        and a.SARADAP_PIDM = b.SARAPPD_PIDM
                        and a.SARADAP_TERM_CODE_ENTRY = b.SARAPPD_TERM_CODE_ENTRY
                        and a.SARADAP_APPL_NO = b.SARAPPD_APPL_NO
                        and b.SARAPPD_SEQ_NO = (select max (b1.SARAPPD_SEQ_NO)
                                                                 from sarappd b1
                                                                 where b.SARAPPD_PIDM = b1.SARAPPD_PIDM
                                                                 and b.SARAPPD_TERM_CODE_ENTRY = b1.SARAPPD_TERM_CODE_ENTRY
                                                                 and b.SARAPPD_APPL_NO = b1.SARAPPD_APPL_NO)
                        and a.saradap_pidm = d.spriden_pidm
                        and d.spriden_change_ind is null
                        and a.saradap_pidm not in (select sorlcur_pidm
                                                                 from sorlcur
                                                                 where SORLCUR_PROGRAM = saradap_program_1
                                                                 And SORLCUR_KEY_SEQNO = SARADAP_APPL_NO
                                                                 And SORLCUR_LMOD_CODE = 'LEARNER')
                        and   a.saradap_pidm = c.pidm
                        and a.SARADAP_APPL_NO = c.study
                        and a.saradap_program_1 = c.programa
--                        and d.spriden_id = '010614339'
                        union
                        select distinct a.SARADAP_PIDM pidm, a.SARADAP_TERM_CODE_ENTRY periodo,
                                            a.SARADAP_APPL_NO solicitud , a.SARADAP_LEVL_CODE nivel , a.SARADAP_CAMP_CODE campus,
                                            a.SARADAP_APST_CODE estatus, c.inicio, d.spriden_id matricula, a.saradap_program_1 programa, c.parte,
                                            b.SARAPPD_APDC_CODE decision
                        from saradap a
                        join sarappd b on b.SARAPPD_PIDM = a.SARADAP_PIDM
                                                    and b.SARAPPD_TERM_CODE_ENTRY = a.SARADAP_TERM_CODE_ENTRY
                                                    and b.SARAPPD_APPL_NO = a.SARADAP_APPL_NO
                                                    And b.SARAPPD_SEQ_NO = (select max ( b1.SARAPPD_SEQ_NO)
                                                                                                from sarappd b1
                                                                                                Where b.SARAPPD_PIDM = b1.SARAPPD_PIDM
                                                                                                And b.SARAPPD_TERM_CODE_ENTRY = b1.SARAPPD_TERM_CODE_ENTRY
                                                                                                And b.SARAPPD_APPL_NO = b1.SARAPPD_APPL_NO
                                                                                                )
                        join spriden d on d.spriden_pidm = a.saradap_pidm and d.spriden_change_ind is null
                        join inicio c on c.pidm = a.saradap_pidm and c.study = a.SARADAP_APPL_NO and c.programa = a.saradap_program_1
                        where a.SARADAP_APST_CODE = 'A'
                        and a.saradap_pidm not in (select sorlcur_pidm
                                                                                         from sorlcur
                                                                                         where SORLCUR_PROGRAM = saradap_program_1
                                                                                         And SORLCUR_KEY_SEQNO = SARADAP_APPL_NO
                                                                                         And SORLCUR_LMOD_CODE = 'LEARNER')
--                        and d.spriden_id = '010614339'
                        union
                        select distinct a.SARADAP_PIDM pidm, a.SARADAP_TERM_CODE_ENTRY periodo,
                                            a.SARADAP_APPL_NO solicitud , a.SARADAP_LEVL_CODE nivel , a.SARADAP_CAMP_CODE campus,
                                            a.SARADAP_APST_CODE estatus, c.inicio, d.spriden_id matricula, a.saradap_program_1 programa, c.parte,
                                            b.SARAPPD_APDC_CODE decision
                        from saradap a, sarappd b, inicio c, spriden d
                        where a.SARADAP_APST_CODE = 'A'
                        and a.SARADAP_PIDM = b.SARAPPD_PIDM
                        and a.SARADAP_TERM_CODE_ENTRY = b.SARAPPD_TERM_CODE_ENTRY
                        and a.SARADAP_APPL_NO = b.SARAPPD_APPL_NO
                        And b.SARAPPD_SEQ_NO = (select max ( b1.SARAPPD_SEQ_NO)
                                                                from sarappd b1
                                                                Where b.SARAPPD_PIDM = b1.SARAPPD_PIDM
                                                                And b.SARAPPD_TERM_CODE_ENTRY = b1.SARAPPD_TERM_CODE_ENTRY
                                                                And b.SARAPPD_APPL_NO = b1.SARAPPD_APPL_NO
                                                                )
                        and a.saradap_pidm = d.spriden_pidm
                        and d.spriden_change_ind is null
                        and a.saradap_pidm not in (select sorlcur_pidm
                                                                 from sorlcur
                                                                 where SORLCUR_PROGRAM = saradap_program_1
                                                                 And SORLCUR_KEY_SEQNO = SARADAP_APPL_NO
                                                                 And SORLCUR_LMOD_CODE = 'LEARNER')
                        and   a.saradap_pidm = c.pidm
                        and a.saradap_program_1 = c.programa
                        and a.SARADAP_APPL_NO = c.study
--                        and d.spriden_id = '010614339'
                       union
                       select distinct a.SARADAP_PIDM pidm, a.SARADAP_TERM_CODE_ENTRY periodo,
                                            a.SARADAP_APPL_NO solicitud , a.SARADAP_LEVL_CODE nivel , a.SARADAP_CAMP_CODE campus,
                                            a.SARADAP_APST_CODE estatus, c.inicio, d.spriden_id matricula, a.saradap_program_1 programa, c.parte,
                                            null decision
                        from saradap a,  inicio c, spriden d
                        where a.SARADAP_APST_CODE = 'A'
                        and a.saradap_pidm = d.spriden_pidm
                        and d.spriden_change_ind is null
                        and a.saradap_pidm not in (select sorlcur_pidm
                                                                                         from sorlcur
                                                                                         where SORLCUR_PROGRAM = saradap_program_1
                                                                                         And SORLCUR_KEY_SEQNO = SARADAP_APPL_NO
                                                                                         And SORLCUR_LMOD_CODE = 'LEARNER')
                        and   a.saradap_pidm = c.pidm
                        and a.SARADAP_APPL_NO = c.study
                        and a.saradap_program_1 = c.programa
                        and a.saradap_pidm not in (select b.sarappd_pidm
                                                                  from sarappd b
                                                                  where b.SARAPPD_TERM_CODE_ENTRY = a.SARADAP_TERM_CODE_ENTRY
                                                                  and   b.SARAPPD_APPL_NO    = a.SARADAP_APPL_NO)
--                         and d.spriden_id = '010614339'
                        order by 7

                        ) loop

                        vl_fecha := null;
                        vl_fecha_o := null;
                        vl_dias :=0;

                      dbms_output.put_line('DATOS DE FECHA  '||c.campus ||'*'||' nivel '||c.nivel ||'*'||' Periodo '||c.periodo ||'*'||' Programa '|| c.programa||'*'||'Parte '||c.parte||'*'||'INICIO'||c.inicio);

                        Begin
                                select DISTINCT SOBPTRM_START_DATE + SZTPTRM_ADICIONAL fecha_fin, SZTPTRM_ADICIONAL
                                 Into  vl_fecha, vl_dias
                                from SZTPTRM, SOBPTRM
                                where SZTPTRM_CAMP_CODE = c.campus
                                and SZTPTRM_LEVL_CODE =   c.nivel
                                and SZTPTRM_TERM_CODE = c.periodo
                                and SZTPTRM_PROGRAM = c.programa
                                and SZTPTRM_PTRM_CODE = c.parte
                                and SOBPTRM_TERM_CODE = SZTPTRM_TERM_CODE
                               -- and trunc (SOBPTRM_START_DATE) =  c.inicio
                                and SOBPTRM_PTRM_CODE = SZTPTRM_PTRM_CODE;

                        Exception
                            When others then
                                    vl_fecha := null;
                                    vl_dias :=0;
                                    vl_exito := 'Se presento el error al obtener la fecha'||sqlerrm;
                        End;

                     vl_fecha_o := to_date(c.inicio)+ vl_dias;

                     dbms_output.put_line('COMO: vl_fecha_o  '||vl_fecha_o ||'*'||' f_inicio '||c.inicio ||'*'||' dias '||vl_dias ||'*'||' vl_fecha '|| vl_fecha||'*'||'Desicion '||c.decision);

                     If vl_fecha is not null and SYSDATE > vl_fecha_o and c.decision not in ( '35', '53')  then -----Cancelo la solicitud

                            dbms_output.put_line('Entra a Actualizar la solicitud  ');

                                Begin
                                  Update saradap
                                  set SARADAP_APST_CODE ='X',
                                       SARADAP_APST_DATE = sysdate,
                                       SARADAP_DATA_ORIGIN = 'MASIVO',
                                       SARADAP_USER_ID = 'MASIVO'
                                  Where saradap_pidm = c.pidm
                                  And SARADAP_TERM_CODE_ENTRY = c.periodo
                                  And  SARADAP_APPL_NO = c.solicitud
                                  And SARADAP_CAMP_CODE = c.campus
                                  and SARADAP_LEVL_CODE  = c.nivel;
                                Exception
                                  When others then
                                    vl_exito := 'Se presento el error al cancelar la solicitud'||sqlerrm;
                                    dbms_output.put_line(vl_exito);
                                End;

                                  max_seqno :=0;

                                 Begin
                                          select nvl(max(SARACMT_SEQNO),0) +1
                                                  Into max_seqno
                                           from SARACMT
                                           Where  SARACMT_PIDM = c.pidm
                                           and SARACMT_TERM_CODE = c.periodo
                                           and SARACMT_APPL_NO = c.solicitud;
                                 Exception
                                  When others then
                                    max_seqno :=0;
                                    vl_exito := 'Se No se puedo obtener la secuencia para el comentario'||sqlerrm;
                                    dbms_output.put_line(vl_exito);
                                 End;

                                 If   vl_exito = 'Exito' then


                                       Begin
                                                  insert into SARACMT values (c.pidm,
                                                                                            c.periodo,
                                                                                            c.solicitud,
                                                                                            max_seqno,
                                                                                            'Cancelaci??e Matriculaci??uera de tiempo',
                                                                                            'COES',
                                                                                            sysdate,
                                                                                            null,
                                                                                            null,
                                                                                            'MASIVO',
                                                                                            'MASIVO',
                                                                                            NULL);
                                       Exception
                                              When Others then
                                               vl_exito := 'Se No se puedo insertar  el comentario'||sqlerrm;
                                               dbms_output.put_line(vl_exito);
                                       End;
                                 End if;

                                  If vl_exito = 'Exito' then

                                      max_seqno :=0;

                                         Begin
                                                  select nvl(max(sarappd_seq_no),0) +1
                                                      into max_seqno
                                                  from sarappd
                                                  where sarappd_pidm = c.pidm
                                                  and SARAPPD_TERM_CODE_ENTRY  = c.periodo
                                                  and SARAPPD_APPL_NO  =  c.solicitud;
                                         Exception
                                          when others then
                                              vl_exito :='Error al obtener la secuencia para ppd'||sqlerrm;
                                             dbms_output.put_line(vl_exito);
                                         End;

                                 End if;

                                 If  vl_exito = 'Exito' then

                                         begin
                                            insert into sarappd values(c.pidm,
                                                                                  c.periodo,
                                                                                   c.solicitud,
                                                                                  max_seqno,
                                                                                  sysdate,
                                                                                  '40',
                                                                                  'U',
                                                                                  sysdate,
                                                                                  'MASIVO',
                                                                                  'MASIVO',
                                                                                  Null,
                                                                                  Null,
                                                                                  Null,
                                                                                  Null );
                                         Exception
                                              when others then
                                            vl_exito:='Error al insertar sarappd'||sqlerrm;
                                            dbms_output.put_line(vl_exito);
                                         end;

                                 End if;

                                 If  vl_exito = 'Exito' then
                                      Begin
                                          Update sorlcur
                                          set  SORLCUR_CACT_CODE = 'INACTIVE',
                                                SORLCUR_ROLL_IND = 'N',
                                                SORLCUR_USER_ID ='MASIVO',
                                                SORLCUR_ACTIVITY_DATE = sysdate,
                                                SORLCUR_USER_ID_UPDATE = 'MASIVO',
                                                SORLCUR_ACTIVITY_DATE_UPDATE = sysdate
                                          where SORLCUR_PIDM = c.pidm
                                          and SORLCUR_LMOD_CODE ='ADMISSIONS'
                                          and SORLCUR_TERM_CODE = c.periodo
                                          and SORLCUR_KEY_SEQNO  = c.solicitud;
                                      Exception
                                          When others then
                                           vl_exito:='Error al actualizar la curricula sorlcur'||sqlerrm;
                                           dbms_output.put_line(vl_exito);
                                      End;
                                 End if;

                                 If  vl_exito = 'Exito' then
                                      Begin
                                          Update sorlfos
                                          set SORLFOS_CACT_CODE = 'INACTIVE',
                                          SORLFOS_USER_ID_UPDATE = 'MASIVO',
                                          SORLFOS_ACTIVITY_DATE_UPDATE = sysdate
                                          Where SORLFOS_PIDM = c.pidm
                                          and SORLFOS_LCUR_SEQNO = c.solicitud
                                          and SORLFOS_TERM_CODE = c.periodo
                                          and SORLFOS_CSTS_CODE = 'INPROGRESS';
                                      Exception
                                          When others then
                                           vl_exito:='Error al actualizar la curricula sorlfos'||sqlerrm;
                                           dbms_output.put_line(vl_exito);
                                      End;

                                 End if;

                                 If  vl_exito = 'Exito' then
                                      Begin
                                             Insert into sztactu values ( c.pidm,
                                                                                   c.matricula,
                                                                                   c.programa,
                                                                                   c.solicitud,
                                                                                   '6',
                                                                                   '8',
                                                                                   null,
                                                                                   null,
                                                                                   sysdate);
                                      Exception
                                          When others then
                                           vl_exito:='Error al insertar en la sincronizacion'||sqlerrm;
                                           dbms_output.put_line(vl_exito);
                                      End;

                                 End if;

                     ElsIf vl_fecha is not null and SYSDATE > vl_fecha_o and c.decision is null then -----Cancelo la solicitud

                            dbms_output.put_line('Entra a Actualizar la solicitud VACIA  ');

                                Begin
                                  Update saradap
                                  set SARADAP_APST_CODE ='X',
                                       SARADAP_APST_DATE = sysdate,
                                       SARADAP_ACTIVITY_DATE = sysdate,
                                       SARADAP_DATA_ORIGIN = 'MASIVO',
                                       SARADAP_USER_ID = 'MASIVO'
                                  Where saradap_pidm = c.pidm
                                  And SARADAP_TERM_CODE_ENTRY = c.periodo
                                  And  SARADAP_APPL_NO = c.solicitud
                                  And SARADAP_CAMP_CODE = c.campus
                                  and SARADAP_LEVL_CODE  = c.nivel;
                                Exception
                                  When others then
                                    vl_exito := 'Se presento el error al cancelar la solicitud'||sqlerrm;
                                    dbms_output.put_line(vl_exito);
                                End;

                                  max_seqno :=0;

                                 Begin
                                          select nvl(max(SARACMT_SEQNO),0) +1
                                                  Into max_seqno
                                           from SARACMT
                                           Where  SARACMT_PIDM = c.pidm
                                           and SARACMT_TERM_CODE = c.periodo
                                           and SARACMT_APPL_NO = c.solicitud;
                                 Exception
                                  When others then
                                    max_seqno :=0;
                                    vl_exito := 'Se No se puedo obtener la secuencia para el comentario'||sqlerrm;
                                    dbms_output.put_line(vl_exito);
                                 End;

                                 If   vl_exito = 'Exito' then


                                       Begin
                                                  insert into SARACMT values (c.pidm,
                                                                                            c.periodo,
                                                                                            c.solicitud,
                                                                                            max_seqno,
                                                                                            'Cancelaci??e Matriculaci??uera de tiempo',
                                                                                            'COES',
                                                                                            sysdate,
                                                                                            null,
                                                                                            null,
                                                                                            'MASIVO',
                                                                                            'MASIVO',
                                                                                            NULL);
                                       Exception
                                              When Others then
                                               vl_exito := 'Se No se puedo insertar  el comentario'||sqlerrm;
                                               dbms_output.put_line(vl_exito);
                                       End;
                                 End if;

                                  If vl_exito = 'Exito' then

                                      max_seqno :=0;

                                         Begin
                                                  select nvl(max(sarappd_seq_no),0) +1
                                                      into max_seqno
                                                  from sarappd
                                                  where sarappd_pidm = c.pidm
                                                  and SARAPPD_TERM_CODE_ENTRY  = c.periodo
                                                  and SARAPPD_APPL_NO  =  c.solicitud;
                                         Exception
                                          when others then
                                              vl_exito :='Error al obtener la secuencia para ppd'||sqlerrm;
                                             dbms_output.put_line(vl_exito);
                                         End;

                                 End if;

                                 If  vl_exito = 'Exito' then

                                         begin
                                            insert into sarappd values(c.pidm,
                                                                                  c.periodo,
                                                                                   c.solicitud,
                                                                                  max_seqno,
                                                                                  sysdate,
                                                                                  '40',
                                                                                  'U', sysdate,
                                                                                  'MASIVO',
                                                                                  'MASIVO',
                                                                                  Null,
                                                                                  Null,
                                                                                  Null,
                                                                                  Null );
                                         Exception
                                              when others then
                                            vl_exito:='Error al insertar sarappd'||sqlerrm;
                                            dbms_output.put_line(vl_exito);
                                         end;

                                 End if;

                                 If  vl_exito = 'Exito' then
                                      Begin
                                          Update sorlcur
                                          set  SORLCUR_CACT_CODE = 'INACTIVE',
                                                SORLCUR_ROLL_IND = 'N',
                                                SORLCUR_USER_ID ='MASIVO',
                                                SORLCUR_ACTIVITY_DATE = sysdate,
                                                SORLCUR_USER_ID_UPDATE = 'MASIVO',
                                                SORLCUR_ACTIVITY_DATE_UPDATE = sysdate
                                          where SORLCUR_PIDM = c.pidm
                                          and SORLCUR_LMOD_CODE ='ADMISSIONS'
                                          and SORLCUR_TERM_CODE = c.periodo
                                          and SORLCUR_KEY_SEQNO  = c.solicitud;
                                      Exception
                                          When others then
                                           vl_exito:='Error al actualizar la curricula sorlcur'||sqlerrm;
                                           dbms_output.put_line(vl_exito);
                                      End;
                                 End if;

                                 If  vl_exito = 'Exito' then
                                      Begin
                                          Update sorlfos
                                          set SORLFOS_CACT_CODE = 'INACTIVE',
                                          SORLFOS_USER_ID_UPDATE = 'MASIVO',
                                          SORLFOS_ACTIVITY_DATE_UPDATE = sysdate
                                          Where SORLFOS_PIDM = c.pidm
                                          and SORLFOS_LCUR_SEQNO = c.solicitud
                                          and SORLFOS_TERM_CODE = c.periodo
                                          and SORLFOS_CSTS_CODE = 'INPROGRESS';
                                      Exception
                                          When others then
                                           vl_exito:='Error al actualizar la curricula sorlfos'||sqlerrm;
                                           dbms_output.put_line(vl_exito);
                                      End;

                                 End if;

                                 If  vl_exito = 'Exito' then
                                      Begin
                                             Insert into sztactu values ( c.pidm,
                                                                                   c.matricula,
                                                                                   c.programa,
                                                                                   c.solicitud,
                                                                                   '6',
                                                                                   '8',
                                                                                   null,
                                                                                   null,
                                                                                   sysdate);
                                      Exception
                                          When others then
                                           vl_exito:='Error al insertar en la sincronizacion'||sqlerrm;
                                           dbms_output.put_line(vl_exito);
                                      End;

                                 End if;

                     else
                      null;
                       dbms_output.put_line('NO OO Entra a Actualizar la solicitud  ');


                     End if;

                     If  vl_exito = 'Exito' then
                         commit;
                         --rollback;
                     End if;

                     Begin

                              insert into sztactu
                              select a.SARADAP_PIDM pidm, b.spriden_id matricula, a.saradap_program_1 programa, a.SARADAP_APPL_NO solicitud, 6 estatus, 8 evento, null, null, sysdate
                              from saradap a , spriden b
                              where 1=1
                              and a.saradap_pidm = b.spriden_pidm
                              and b.spriden_change_ind is null
                              and b.spriden_id = c.matricula
                              AND a.SARADAP_APPL_NO=c.solicitud
                              and a.SARADAP_APST_CODE = 'X'
                              and a.SARADAP_USER_ID = 'MASIVO'
                              and a.SARADAP_APPL_NO = (select max (a1.SARADAP_APPL_NO)
                                                       from SARADAP a1
                                                       where a.saradap_pidm = a1.saradap_pidm
                                                       and a.saradap_program_1 = a1.saradap_program_1)
                              AND a.SARADAP_PIDM NOT IN (select a1.SARADAP_PIDM pidm
                                                            from saradap a1 , spriden b1
                                                          where 1=1
                                                          and a1.saradap_pidm = b1.spriden_pidm
                                                          and b1.spriden_change_ind is null
                                                          and b1.spriden_id =c.matricula
                                                          and a1.SARADAP_APST_CODE = 'X'
                                                          and a1.SARADAP_USER_ID = 'MASIVO'
                                                          and a1.SARADAP_APPL_NO = (select max (a2.SARADAP_APPL_NO)
                                                                                   from SARADAP a2
                                                                                   where a1.saradap_pidm = a2.saradap_pidm
                                                                                   and a1.saradap_program_1 = a2.saradap_program_1));

                     Exception
                         When Others then
                                  vl_exito:='Error al insertar en la sztactu '||sqlerrm;
                                           dbms_output.put_line(vl_exito);
                     End;

        End loop;

        commit;



dbms_output.put_line('salida: '||vl_exito);



End p_cancela_solicitud;
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
            if validaS = 'Y' then
                  return (validaS);
              else
                 return (validaN);
            end if;

        end if;


exception when others then
return ('S');

end f_documentos_alu;
--
--
    FUNCTION F_borra_etiquetas_dom (p_pidm number,p_bandera number,p_user varchar2) return varchar2

    is

    L_CONTAR NUMBER;
    vl_exito varchar2(500):='Exito' ;
    L_PROGRAMA VARCHAR2(20);

     BEGIN

               BEGIN
                 SELECT COUNT(*)
                INTO L_CONTAR
                FROM goradid
                where 1=1
                AND GORADID_PIDM=P_PIDM
                and GORADID_ADID_CODE IN (select ZSTPARA_PARAM_ID
                                           FROM ZSTPARA
                                           WHERE 1=1
                                           AND ZSTPARA_MAPA_ID = 'PORCENTAJE_DOM');

                EXCEPTION
                WHEN OTHERS THEN
                 NULL;

                END;



               BEGIN

                 SELECT d.SORLCUR_PROGRAM
                 INTO L_PROGRAMA
                 FROM SORLCUR D
                 WHERE 1=1
                 AND D.SORLCUR_PIDM=P_PIDM
                 AND D.SORLCUR_SEQNO IN  ( SELECT MAX(SORLCUR_SEQNO)
                                            FROM SORLCUR SS
                                            WHERE  D.SORLCUR_PIDM = SS.SORLCUR_PIDM
                                            )

                ;

                EXCEPTION

                 WHEN OTHERS THEN

                 NULL;

                END;

            IF L_CONTAR>0 THEN

                      BEGIN

                            DELETE
                            FROM goradid
                            where 1=1
                            AND GORADID_PIDM=P_PIDM
                            and GORADID_ADID_CODE IN (select ZSTPARA_PARAM_ID
                                                       FROM ZSTPARA
                                                       WHERE 1=1
                                                       AND ZSTPARA_MAPA_ID = 'PORCENTAJE_DOM');


                      Exception
                             When Others then
                                 vl_exito:='se encontro un error '||sqlerrm ;
                       End;
            else
               vl_exito:='este alumno no tiene registro' ;

            END IF;

            if  vl_exito = 'Exito' then

                   if  p_bandera=1 then

                         BEGIN


                                   INSERT INTO SZTDOMI  VALUES
                                                 (
                                                 P_PIDM,
                                                 L_PROGRAMA,
                                                 p_user,
                                                 'Y',
                                                 'N',
                                                 NULL,
                                                 sysdate,
                                                 NULL,
                                                 NULL
                                                 );
                                     COMMIT;

                                 EXCEPTION

                                      WHEN OTHERS THEN

                                   NULL;

                          END;
                   else
                     null;

                   end if;

             COMMIT;

            else
                null;

            end if;

            RETURN vl_exito;
     END F_borra_etiquetas_dom;
     
     
Function f_bandera_siu_sztdomi (p_pidm number) Return Varchar2 
is 

    vl_exito varchar2(500):='Exito' ;

Begin

        Begin
            Update sztdomi
            set SZTDOMI_CHECK_SIU ='Y',
                SZTDOMI_COMENTARIOS = 'Se Elimina la Domiciliacion',
                SZTDOMI_FECHA_CHECK_SIU = sysdate
            Where SZTDOMI_PIDM = p_pidm;
        Exception
            When Others then 
              vl_exito := 'Se presento el Error al borrar la Domiciliacion' ||sqlerrm;        
        End;

        RETURN vl_exito;

END f_bandera_siu_sztdomi;     

end pkg_datos_academicos;
/

DROP PUBLIC SYNONYM PKG_DATOS_ACADEMICOS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_DATOS_ACADEMICOS FOR BANINST1.PKG_DATOS_ACADEMICOS;


GRANT EXECUTE ON BANINST1.PKG_DATOS_ACADEMICOS TO CONSULTA;
