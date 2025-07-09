DROP PACKAGE BODY BANINST1.PKG_GRADUACION;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_graduacion
IS

PROCEDURE Graduado ( protocolo   IN number, pidm IN number, servicio IN varchar2) IS

conta number;
per_ter  varchar2(6);
per     varchar2(6);
anio    varchar2(4);
f_gradu date;


begin

    if servicio='SOTI' then
    
           select count(*) into conta from svrsvpa 
           where svrsvpa_pidm=pidm
           and     svrsvpa_srvc_code='SOGR'
           and     svrsvpa_srvs_code in ('PA','CR');
    
    end if;
    
        if servicio='SOGR' then
    
           select count(*) into conta from svrsvpa
           where svrsvpa_pidm=pidm
           and     svrsvpa_srvc_code='SOTI'
           and     svrsvpa_srvs_code in ('PA','CR');
    
    end if;
    
    if conta > 0 then
    
       select max(shrtckn_term_code) into per_ter
       from  svrsvad, shrtckn, sorlcur
       where  shrtckn_pidm=pidm
       and     svrsvad_protocol_seq_no=protocolo
       and     svrsvad_addl_data_seq=1
       and     sorlcur_pidm=shrtckn_pidm
       and     sorlcur_program=substr(svrsvad_addl_data_cde,1,10)
       and     sorlcur_lmod_code='LEARNER' and sorlcur_roll_ind='Y' and sorlcur_current_cde='Y' and sorlcur_appl_key_seqno is not null
       and     shrtckn_stsp_key_sequence=sorlcur_key_seqno; 
    
       select  svrsvad_addl_data_cde, stvterm_acyr_code  into  per, anio
       from svrsvad, stvterm
       where svrsvad_protocol_seq_no=protocolo
       and     svrsvad_addl_data_seq=2
       and     svrsvad_addl_data_cde=stvterm_code;
       
       select to_date(svrsvad_addl_data_cde,'dd/mm/rrrr')  into  f_gradu
       from svrsvad
       where  svrsvad_protocol_seq_no=protocolo
       and     svrsvad_addl_data_seq=3;

       
       insert into shrncrs values(pidm, (select nvl(max(shrncrs_seq_no),0) +1 from shrncrs where shrncrs_pidm=pidm), sysdate, null,null,null,null, 'PT', 'AP', trunc(sysdate), null,null,null,null, user, '1SS', null);
            
       update shrdgmr x set shrdgmr_degs_code='GR', shrdgmr_acyr_code_bulletin=anio, shrdgmr_term_code_completed=per_ter,  shrdgmr_appl_date=trunc(sysdate),  shrdgmr_term_code_grad=per, shrdgmr_acyr_code=anio,
                  shrdgmr_grst_code='TI', shrdgmr_grad_date=f_gradu
       where shrdgmr_pidm=pidm
       and     shrdgmr_seq_no in (select min(shrdgmr_seq_no) from shrdgmr xx
                                               where x.shrdgmr_pidm=xx.shrdgmr_pidm);
      -- commit;
                  
    end if;

end Graduado;

end pkg_graduacion;
/

DROP PUBLIC SYNONYM PKG_GRADUACION;

CREATE OR REPLACE PUBLIC SYNONYM PKG_GRADUACION FOR BANINST1.PKG_GRADUACION;
