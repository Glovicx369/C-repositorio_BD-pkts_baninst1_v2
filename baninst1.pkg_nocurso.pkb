DROP PACKAGE BODY BANINST1.PKG_NOCURSO;

CREATE OR REPLACE PACKAGE BODY BANINST1.Pkg_nocurso IS

Procedure titulacion is


vl_id varchar2(9);
vl_existe number:=0;
vl_conta  number:=0;
f_graduacion date;
vl_error varchar2(250);
vl_cumple varchar2(4);
per_eg    varchar2(6);
anio_grad varchar2(4);
per_grad  varchar2(6);
vl_salida varchar2(250);
vl_errores varchar2(4000);

BEGIN

                For c in (select distinct a.SGBSTDN_PIDM, a.SGBSTDN_STST_CODE, a.SGBSTDN_TERM_CODE_EFF, a.SGBSTDN_PROGRAM_1, a.SGBSTDN_LEVL_CODE
                               from SGBSTDN a
                              Where a.SGBSTDN_STST_CODE = 'EG'
                              And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                                      from sgbstdn a1
                                                                                      where a.sgbstdn_pidm = a1.sgbstdn_pidm
                                                                                      And a.SGBSTDN_LEVL_CODE = a1.SGBSTDN_LEVL_CODE
                                                                                      And a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1)) loop
                              
                        Begin   
                               Select substr (spriden_id,1,2)
                               Into vl_id
                               from spriden
                               Where spriden_pidm = c.SGBSTDN_PIDM
                               And SPRIDEN_CHANGE_IND is null;
                        End;
                                             

                        -- Se busca que el cargo esta sembrado en el estado de cuanta ----
                        
                        Begin
                            select count (1)
                            Into vl_existe
                            from tbraccd
                            Where tbraccd_pidm = c.SGBSTDN_PIDM
                            And  TBRACCD_DETAIL_CODE in  (Select vl_id||substr(ZSTPARA_PARAM_ID, 3, 2)
                                                                           from ZSTPARA
                                                                           where ZSTPARA_MAPA_ID = 'MASIVO_TITULO');                              
                               
                        Exception 
                        When others then 
                            vl_existe :=0;
                        End;
                         
                        Begin
                            Select count(1)
                                Into vl_cumple
                            from SHRDGMR
                            Where SHRDGMR_PIDM = c.SGBSTDN_PIDM
                            And SHRDGMR_LEVL_CODE = c.SGBSTDN_LEVL_CODE
                            And SHRDGMR_PROGRAM = c.SGBSTDN_PROGRAM_1
                            And SHRDGMR_DEGS_CODE = 'PE' ;
                        Exception
                        When Others then 
                          vl_cumple :=0;
                        End;

                        If vl_existe >= 1   and vl_cumple >= 1 then 
                                           
                               select count(*) 
                                 into vl_conta 
                               from shrncrs
                               where shrncrs_pidm=c.SGBSTDN_PIDM
                               and     shrncrs_ncst_code='AP';

                               If vl_conta=0 then
                                  vl_error :=0;
                                 
                                         Begin
                                                    insert into  SHRNCRS 
                                                            values(c.SGBSTDN_PIDM,
                                                                        (select nvl(max(shrncrs_seq_no),0) +1 
                                                                        from shrncrs 
                                                                        where shrncrs_pidm=c.SGBSTDN_PIDM), 
                                                                        sysdate, 
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null, 
                                                                        'PT',
                                                                        'AP',
                                                                        sysdate,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        user, 
                                                                        'UTEL', 
                                                                        null);
                                                                      --  dbms_output.put_line('inserto shrncrs');
                                         Exception
                                            When Others then 
                                                     vl_error:=1;
                                                     vl_errores :=sqlerrm;
                                               --      Insert into borrame values ('SHRNCRS'||c.SGBSTDN_PIDM, vl_errores, 1);
                                                     Commit;
                                         End;
                                         
                                         
                                         ---- Se busca la fecha de graduacion solicitda por el alumno
                                         Begin
                                                select distinct svrsvad_addl_data_cde 
                                                    into f_graduacion 
                                                from svrsvad, svrsvpa
                                                where svrsvpa_pidm=c.SGBSTDN_PIDM
                                                and     svrsvpa_srvc_code='SOGR'
                                                and     svrsvpa_srvs_code in ('PA','CR')
                                                and     svrsvad_protocol_seq_no=svrsvpa_protocol_seq_no
                                                and      svrsvad_addl_data_seq=3; 
                                         Exception
                                         When Others then 
                                           f_graduacion := null;
                                         End;
                                         
                                         
                                         Begin               
                                               select distinct shrgada_acyr_code, shrgada_grad_term_code
                                                 into anio_grad, per_grad 
                                               from SHRGADA
                                               where shrgada_grad_date=f_graduacion;
                                         Exception
                                            When Others then 
                                            anio_grad:=null; 
                                            per_grad :=null; 
                                         End;                                         
                                          
                                         If anio_grad is null then 
                                            Begin
                                                  Select distinct STVTERM_ACYR_CODE, STVTERM_CODE
                                                    Into anio_grad, per_grad
                                                  from STVTERM
                                                  Where STVTERM_CODE = c.SGBSTDN_TERM_CODE_EFF;
                                            Exception
                                            When Others then 
                                               anio_grad:=null; 
                                                per_grad :=null; 
                                                vl_error:=1;
                                            End;
                                            
                                        End if;              
                                          --dbms_output.put_line('vl_error:'||vl_error||'PIDM:'||c.SGBSTDN_pidm||' PROGRAMA:'||C.SGBSTDN_PROGRAM_1);
                                          
                                          update shrdgmr set SHRDGMR_DEGS_CODE='GR',
                                                                       SHRDGMR_APPL_DATE=sysdate,
                                                                       SHRDGMR_GRAD_DATE=f_graduacion,
                                                                       SHRDGMR_ACYR_CODE_BULLETIN=anio_grad,
                                                                       SHRDGMR_TERM_CODE_STUREC=c.SGBSTDN_TERM_CODE_EFF,
                                                                       SHRDGMR_TERM_CODE_GRAD=c.SGBSTDN_TERM_CODE_EFF,
                                                                       SHRDGMR_GRST_CODE='TI', SHRDGMR_FEE_IND=NULL, SHRDGMR_FEE_DATE=NULL,
                                                                       SHRDGMR_AUTHORIZED=user, SHRDGMR_TERM_CODE_COMPLETED=c.SGBSTDN_TERM_CODE_EFF,
                                                                       SHRDGMR_DATA_ORIGIN='MASIVO', SHRDGMR_USER_ID=user
                                          WHERE SHRDGMR_PIDM=c.SGBSTDN_pidm AND SHRDGMR_PROGRAM=C.SGBSTDN_PROGRAM_1;
                                                                       
                                  /*                      
                                         Begin
                                               If vl_error = 0 then
                                                        Begin   
                                                                 
                                                              SB_LEARNEROUTCOME.P_UPDATE(
                                                                 p_PIDM                   => c.SGBSTDN_pidm,--:SHRDGMR.SHRDGMR_PIDM,
                                                                 p_SEQ_NO                 =>1, --:SHRDGMR.SHRDGMR_SEQ_NO,
                                                                 p_DEGS_CODE              =>'GR', --:SHRDGMR.SHRDGMR_DEGS_CODE,
                                                                 p_APPL_DATE              => sysdate, --:SHRDGMR.SHRDGMR_APPL_DATE,
                                                                 p_GRAD_DATE              => f_graduacion, --:SHRDGMR.SHRDGMR_GRAD_DATE,
                                                                 p_ACYR_CODE_BULLETIN     =>anio_grad, --:SHRDGMR.SHRDGMR_ACYR_CODE_BULLETIN,
                                                                 p_TERM_CODE_STUREC       =>c.SGBSTDN_TERM_CODE_EFF, --:SHRDGMR.SHRDGMR_TERM_CODE_STUREC,
                                                                 p_TERM_CODE_GRAD         =>c.SGBSTDN_TERM_CODE_EFF,--:SHRDGMR.SHRDGMR_TERM_CODE_GRAD,
                                                                 p_ACYR_CODE              =>anio_grad, --:SHRDGMR.SHRDGMR_ACYR_CODE,
                                                                 p_GRST_CODE              => 'TI', --:SHRDGMR.SHRDGMR_GRST_CODE,
                                                                 p_FEE_IND                => null,--:SHRDGMR.SHRDGMR_FEE_IND,
                                                                 p_FEE_DATE               =>null, --:SHRDGMR.SHRDGMR_FEE_DATE,
                                                                 p_AUTHORIZED             =>user, --:SHRDGMR.SHRDGMR_AUTHORIZED,
                                                                 p_TERM_CODE_COMPLETED    => c.SGBSTDN_TERM_CODE_EFF, --:SHRDGMR.SHRDGMR_TERM_CODE_COMP,
                                                                 p_DEGC_CODE_DUAL         =>null,--:SHRDGMR.SHRDGMR_DEGC_CODE_DUAL,
                                                                 p_LEVL_CODE_DUAL         =>null, --:SHRDGMR.SHRDGMR_LEVL_CODE_DUAL,
                                                                 p_DEPT_CODE_DUAL         =>null, --:SHRDGMR.SHRDGMR_DEPT_CODE_DUAL,
                                                                 p_COLL_CODE_DUAL         =>null, --:SHRDGMR.SHRDGMR_COLL_CODE_DUAL,
                                                                 p_MAJR_CODE_DUAL         =>null, --:SHRDGMR.SHRDGMR_MAJR_CODE_DUAL,
                                                                 p_DATA_ORIGIN            =>'MASIVO',
                                                                 p_USER_ID                =>USER,
                                                                 p_ROWID                  =>vl_salida);

                                                        Exception
                                                        When Others then 
                                                         vl_errores :=sqlerrm;
                                                                -- Insert into borrame values ('SB_LEARNEROUTCOME'||c.SGBSTDN_PIDM, vl_errores, vl_salida);
                                                                    Commit;
                                                        End;
                                               ElsIf vl_error = 1 then
                                                        Begin
                                                              SB_LEARNEROUTCOME.P_UPDATE(
                                                                 p_PIDM                   => c.SGBSTDN_pidm,--:SHRDGMR.SHRDGMR_PIDM,
                                                                 p_SEQ_NO                 =>1, --:SHRDGMR.SHRDGMR_SEQ_NO,
                                                                 p_DEGS_CODE              =>'GR', --:SHRDGMR.SHRDGMR_DEGS_CODE,
                                                                 p_APPL_DATE              => sysdate, --:SHRDGMR.SHRDGMR_APPL_DATE,
                                                                 p_GRAD_DATE              => f_graduacion, --:SHRDGMR.SHRDGMR_GRAD_DATE,
                                                                 p_ACYR_CODE_BULLETIN     =>null, --:SHRDGMR.SHRDGMR_ACYR_CODE_BULLETIN,
                                                                 p_TERM_CODE_STUREC       =>c.SGBSTDN_TERM_CODE_EFF, --:SHRDGMR.SHRDGMR_TERM_CODE_STUREC,
                                                                 p_TERM_CODE_GRAD         =>c.SGBSTDN_TERM_CODE_EFF,--:SHRDGMR.SHRDGMR_TERM_CODE_GRAD,
                                                                 p_ACYR_CODE              =>null, --:SHRDGMR.SHRDGMR_ACYR_CODE,
                                                                 p_GRST_CODE              => 'TI', --:SHRDGMR.SHRDGMR_GRST_CODE,
                                                                 p_FEE_IND                => null,--:SHRDGMR.SHRDGMR_FEE_IND,
                                                                 p_FEE_DATE               =>null, --:SHRDGMR.SHRDGMR_FEE_DATE,
                                                                 p_AUTHORIZED             =>user, --:SHRDGMR.SHRDGMR_AUTHORIZED,
                                                                 p_TERM_CODE_COMPLETED    => c.SGBSTDN_TERM_CODE_EFF, --:SHRDGMR.SHRDGMR_TERM_CODE_COMP,
                                                                 p_DEGC_CODE_DUAL         =>null,--:SHRDGMR.SHRDGMR_DEGC_CODE_DUAL,
                                                                 p_LEVL_CODE_DUAL         =>null, --:SHRDGMR.SHRDGMR_LEVL_CODE_DUAL,
                                                                 p_DEPT_CODE_DUAL         =>null, --:SHRDGMR.SHRDGMR_DEPT_CODE_DUAL,
                                                                 p_COLL_CODE_DUAL         =>null, --:SHRDGMR.SHRDGMR_COLL_CODE_DUAL,
                                                                 p_MAJR_CODE_DUAL         =>null, --:SHRDGMR.SHRDGMR_MAJR_CODE_DUAL,
                                                                 p_DATA_ORIGIN            =>'MASIVO',
                                                                 p_USER_ID                =>USER,
                                                                 p_ROWID                  =>vl_salida);
                                                        Exception
                                                            When Others then 
                                                             vl_errores :=sqlerrm;
                                                                --     Insert into borrame values ('SB_LEARNEROUTCOME1'||c.SGBSTDN_PIDM, vl_errores, vl_salida);
                                                                        Commit;
                                                        End;

                                               End if;          
                                                 
                                         End;*/
                                                        
                               end if;

                        End if;

                Commit;

                End loop;
                              
End;



PROCEDURE graduacion(pidm IN number, servicio IN varchar2, protocolo IN number)
IS

contador number;
conta      number;
f_graduacion date;
per_eg    varchar2(6);
anio_grad varchar2(4);
per_grad  varchar2(6);
prog         varchar2(10);


begin

if servicio = 'SOGR' then
    select count(*) into contador
    from svrsvpa
    where svrsvpa_pidm=pidm
    and     svrsvpa_srvs_code in ('PA','CR')
    and     svrsvpa_srvs_code='SOTI' ;
    
    select count(*) into conta
    from tbraccd
    where tbraccd_pidm=pidm
    and     tbraccd_detail_code='01BQ';
    
    contador:=contador+conta;
    
else
select count(*) into contador
    from svrsvpa
    where svrsvpa_pidm=pidm
    and     svrsvpa_srvs_code in ('PA','CR')
    and     svrsvpa_srvc_code='SOGR' ;
end if;
--dbms_output.put_line('contador:'||contador);
if contador > 0 then
   
   select count(*) into conta from shrncrs
   where shrncrs_pidm=pidm
   and     shrncrs_ncst_code='AP';
   if conta=0 then
   insert into  SHRNCRS values(pidm,(select nvl(max(shrncrs_seq_no),0) +1 from shrncrs where shrncrs_pidm=pidm), sysdate, null,null,null,null, 'PT','AP',sysdate,null,null,null,null,user, 'UTEL', null);
   --commit;
   end if;

   select distinct svrsvad_addl_data_cde into f_graduacion 
   from svrsvad, svrsvpa
   where svrsvpa_pidm=pidm
   and     svrsvpa_srvc_code='SOGR'
   and     svrsvpa_srvs_code in ('PA','CR')
   and     svrsvad_protocol_seq_no=svrsvpa_protocol_seq_no
   and      svrsvad_addl_data_seq=3; 
   --dbms_output.put_line('f_gradua:'||f_graduacion);
   
   begin
   select sgbstdn_term_code_eff,substr(svrsvad_addl_data_cde,1,10)  into per_eg, prog 
   from sgbstdn, svrsvad
   where svrsvad_protocol_seq_no=protocolo
    and     svrsvad_addl_data_seq=1
    and     sgbstdn_pidm=pidm
    and     sgbstdn_program_1=substr(svrsvad_addl_data_cde,1,10)
    and     sgbstdn_stst_code='EG';
   exception when others then 
      per_eg:=null;
   end;
   -- dbms_output.put_line('per_gradua:'||per_eg||' '||'programa:'||prog);
   select distinct shrgada_acyr_code, shrgada_grad_term_code into anio_grad, per_grad 
   from SHRGADA
   where shrgada_grad_date=f_graduacion;
   
   update shrdgmr x set shrdgmr_acyr_code_bulletin=anio_grad, shrdgmr_acyr_code=anio_grad,shrdgmr_term_code_completed=per_eg, shrdgmr_term_code_grad=per_grad, shrdgmr_grst_code='TI', shrdgmr_grad_date=f_graduacion
   where shrdgmr_pidm=pidm
   and     shrdgmr_seq_no in (select min(shrdgmr_seq_no) from shrdgmr xx
                                         where x.shrdgmr_pidm=xx.shrdgmr_pidm
                                         and    xx.shrdgmr_program=prog);
  --commit;
--dbms_output.put_line('actualiza registro');
end if;

end graduacion;

end Pkg_nocurso;
/

DROP PUBLIC SYNONYM PKG_NOCURSO;

CREATE OR REPLACE PUBLIC SYNONYM PKG_NOCURSO FOR BANINST1.PKG_NOCURSO;
