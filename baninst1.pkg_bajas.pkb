DROP PACKAGE BODY BANINST1.PKG_BAJAS;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_bajas
is

procedure bti(pidm in number, prog in varchar2, periodo varchar2) is

conse_sorlcur number;
i    number;
cde   varchar2(1);
conta   number;

begin

update sfbetrm set sfbetrm_ests_code='NE', sfbetrm_ests_date=trunc(sysdate),  sfbetrm_activity_date=sysdate, sfbetrm_rgre_code='AC', sfbetrm_user=user
where sfbetrm_pidm=pidm and sfbetrm_term_code=periodo;


update sfrstcr set sfrstcr_rsts_code='BD'
where sfrstcr_pidm=pidm and sfrstcr_term_code=periodo;


FOR i IN 1..2 LOOP

    for c in (

    select sorlcur_pidm, sorlcur_seqno, sorlcur_lmod_code, sorlcur_key_seqno, sorlcur_priority_no, sorlcur_roll_ind, sorlcur_data_origin, sorlcur_levl_code, sorlcur_coll_code, sorlcur_degc_code, sorlcur_term_code_ctlg, 
    sorlcur_term_code_end, sorlcur_term_code_matric, sorlcur_term_code_admit, sorlcur_admt_code, sorlcur_camp_code, sorlcur_program, sorlcur_start_date, sorlcur_end_date, sorlcur_curr_rule
    from sorlcur s
    where sorlcur_pidm=pidm and sorlcur_program=prog and sorlcur_lmod_code='LEARNER' and sorlcur_cact_code='ACTIVE'  and sorlcur_seqno in(
    select max(sorlcur_seqno) from sorlcur ss where s.sorlcur_pidm=ss.sorlcur_pidm and s.sorlcur_cact_code=ss.sorlcur_cact_code and s.sorlcur_program=ss.sorlcur_program and s.sorlcur_lmod_code=ss.sorlcur_lmod_code)

    ) loop

            select nvl(max(sorlcur_seqno),0) +1 into conse_sorlcur 
            from sorlcur
            where sorlcur_pidm= c.sorlcur_pidm;
            if i=1 then cde:=null;
                      insert into sorlcur values(c.sorlcur_pidm,  conse_sorlcur, c.sorlcur_lmod_code, periodo, c.sorlcur_key_seqno, c.sorlcur_priority_no, c.sorlcur_roll_ind, 'INACTIVE', user, 'Banner', sysdate, c.sorlcur_levl_code,
                       c.sorlcur_coll_code, c.sorlcur_degc_code, c.sorlcur_term_code_ctlg, periodo,  c.sorlcur_term_code_matric, c.sorlcur_term_code_admit, c.sorlcur_admt_code, c.sorlcur_camp_code, c.sorlcur_program, 
                        c.sorlcur_start_date, c.sorlcur_end_date, c.sorlcur_curr_rule, null, null, null, null, null, null, null, null, null, null, null, null, user, sysdate, null, cde, null, null, null); 
            else cde:='Y';
                       insert into sorlcur values(c.sorlcur_pidm,  conse_sorlcur, c.sorlcur_lmod_code, periodo, c.sorlcur_key_seqno, c.sorlcur_priority_no, c.sorlcur_roll_ind, 'INACTIVE', user, 'Banner', sysdate, c.sorlcur_levl_code,
                        c.sorlcur_coll_code, c.sorlcur_degc_code, c.sorlcur_term_code_ctlg, null ,  c.sorlcur_term_code_matric, c.sorlcur_term_code_admit, c.sorlcur_admt_code, c.sorlcur_camp_code, c.sorlcur_program, 
                         c.sorlcur_start_date, c.sorlcur_end_date, c.sorlcur_curr_rule, null, null, null, null, null, null, null, null, null, null, null, null, user, sysdate, null, cde, null, null, null);
            
            end if;
                           
            for w in (

            select sorlfos_pidm, sorlfos_lcur_seqno, sorlfos_seqno, sorlfos_lfst_code, sorlfos_priority_no, sorlfos_data_origin, sorlfos_user_id, sorlfos_majr_code, sorlfos_term_code_ctlg, 
            sorlfos_majr_code_attach, sorlfos_lfos_rule, sorlfos_conc_attach_rule, sorlfos_current_cde
            from sorlfos 
            where  sorlfos_pidm=c.sorlcur_pidm 
            and sorlfos_lcur_seqno=c.sorlcur_seqno  
            order by sorlfos_seqno

            ) loop

                if i=1 then
                  insert into sorlfos values(w.sorlfos_pidm, conse_sorlcur, w.sorlfos_seqno, w.sorlfos_lfst_code, periodo, w.sorlfos_priority_no, 'CHANGED', 'INACTIVE', w.sorlfos_data_origin, user, sysdate,
                   w.sorlfos_majr_code, w.sorlfos_term_code_ctlg, null, null, w.sorlfos_majr_code_attach, w.sorlfos_lfos_rule, w.sorlfos_conc_attach_rule, null, null, null, null, user, sysdate, cde, null, null, null);
                else
                  insert into sorlfos values(w.sorlfos_pidm, conse_sorlcur, w.sorlfos_seqno, w.sorlfos_lfst_code, periodo, w.sorlfos_priority_no, 'INACTIVE', 'INACTIVE', w.sorlfos_data_origin, user, sysdate,
                   w.sorlfos_majr_code, w.sorlfos_term_code_ctlg, null, null, w.sorlfos_majr_code_attach, w.sorlfos_lfos_rule, w.sorlfos_conc_attach_rule, null, null, null, null, user, sysdate, cde, null, null, null);
                end if; 
                   
            end loop;

    end loop;

end loop;

select count(*) into conta from sgbstdn
where sgbstdn_pidm=pidm and sgbstdn_program_1=prog and sgbstdn_term_code_eff=periodo;

if conta = 0 then

    for z in (
     
          select sgbstdn_pidm, sgbstdn_term_code_eff, sgbstdn_levl_code, sgbstdn_styp_code, sgbstdn_term_code_matric, sgbstdn_term_code_admit, sgbstdn_camp_code, sgbstdn_resd_code, sgbstdn_coll_code_1, sgbstdn_degc_code_1,
          sgbstdn_majr_code_1, sgbstdn_majr_code_conc_1, sgbstdn_rate_code, sgbstdn_admt_code, sgbstdn_prim_roll_ind, sgbstdn_program_1, sgbstdn_term_code_ctlg_1, sgbstdn_curr_rule_1, sgbstdn_cmjr_rule_1_1,
          sgbstdn_ccon_rule_11_1, sgbstdn_data_origin
          from sgbstdn s
          where sgbstdn_pidm = pidm and sgbstdn_program_1=prog and sgbstdn_term_code_eff in (
                  select max(sgbstdn_term_code_eff) from sgbstdn ss
                  where s.sgbstdn_pidm=ss.sgbstdn_pidm and s.sgbstdn_program_1=ss.sgbstdn_program_1)
                  
     ) loop
     
            insert into sgbstdn values(z.sgbstdn_pidm, periodo, 'BI', z.sgbstdn_levl_code, z.sgbstdn_styp_code, z.sgbstdn_term_code_matric, z.sgbstdn_term_code_admit, null, z.sgbstdn_camp_code,
            null, null, z.sgbstdn_resd_code, z.sgbstdn_coll_code_1, z.sgbstdn_degc_code_1, z.sgbstdn_majr_code_1, null, null, z.sgbstdn_majr_code_conc_1, null, null, null, null, null, null, null, null, null, null,null, null, null, null, null,null, null, null, null, null, 
            z.sgbstdn_rate_code, sysdate, null, null, null, null, z.sgbstdn_admt_code, null, null, null, null, null, null, null, null, null, null,null, null, null, null, null,null, null, null, z.sgbstdn_prim_roll_ind, z.sgbstdn_program_1, 
            z.sgbstdn_term_code_ctlg_1,null, null, null, null, null, null, null, null, null, null,null, null, null, null, null,  z.sgbstdn_curr_rule_1, z.sgbstdn_cmjr_rule_1_1, z.sgbstdn_ccon_rule_11_1, 
            null, null, null, null, null, null, null, null, null, null,null, null, null, null, null,null, null, null, null, null,null, null, null, z.sgbstdn_data_origin, user, null, null, null, null);
            
     end loop;
              
else

     update sgbstdn set sgbstdn_stst_code='BI'
     where sgbstdn_pidm=pidm and sgbstdn_program_1=prog and sgbstdn_term_code_eff=periodo;

end if;

commit;

end bti;

end pkg_bajas;
/

DROP PUBLIC SYNONYM PKG_BAJAS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_BAJAS FOR BANINST1.PKG_BAJAS;
