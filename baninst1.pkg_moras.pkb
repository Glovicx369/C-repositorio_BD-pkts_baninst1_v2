DROP PACKAGE BODY BANINST1.PKG_MORAS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_MORAS IS

PROCEDURE sp_moras
IS

 BEGIN
 

         Begin

              EXECUTE IMMEDIATE 'TRUNCATE TABLE TAISMGR.TZTMORA';
              Commit;

             For mora in (

                         select distinct c.TBRACCD_PIDM pidm,
                         b.spriden_id Matricula,
                         b.SPRIDEN_LAST_NAME ||' '||b.SPRIDEN_FIRST_NAME Nombre,
                         c.TBRACCD_Balance Saldo,
                         TRUNC (c.TBRACCD_EFFECTIVE_DATE) Fecha_cargo,
                         ceil ((sysdate) - TRUNC (c.TBRACCD_EFFECTIVE_DATE)) dias ,
                         c.TBRACCD_DETAIL_CODE codigo,
                         a.tbbdetc_desc descrip,
                         a.TBBDETC_DCAT_CODE
                          from tbbdetc a, spriden b, tbraccd c
                         Where c.TBRACCD_DETAIL_CODE = a.tbbdetc_detail_code
                         And c.TBRACCD_DETAIL_CODE in (select a1.tbbdetc_detail_code
                         from tbbdetc a1
                         Where a.TBBDETC_TYPE_IND = a1.TBBDETC_TYPE_IND)
                         and a.TBBDETC_TYPE_IND = 'C'
                         And c.TBRACCD_AMOUNT >0
                         And c.tbraccd_balance > 0
                         And b.spriden_pidm = TBRACCD_PIDM
                         and b.SPRIDEN_CHANGE_IND is null
                         And PKG_DASHBOARD_ALUMNO.f_dashboard_saldototal(tbraccd_pidm) > 0
                        -- And spriden_id ='010043587'
                         ORDER BY 1, 9 DESC


             ) loop

                    Begin 
                         Insert into TZTMORA values (mora.pidm,
                         mora.matricula,
                         mora.nombre,
                         mora.saldo,
                         mora.fecha_cargo,
                         mora.dias,
                         mora.descrip,
                         null);
                    Exception
                        When Others then 
                         null;
                    End;

             End Loop;

         End;


         Begin

             for estat in (
                             select distinct b.sgbstdn_pidm pidm, b.SGBSTDN_STST_CODE estatus
                             from TZTMORA a, sgbstdn b
                             Where a.TZTMORA_PIDM = b.sgbstdn_pidm
                             And b.SGBSTDN_TERM_CODE_EFF = (select max ( b1.SGBSTDN_TERM_CODE_EFF)
                             from SGBSTDN b1
                             where b.sgbstdn_pidm = b1.sgbstdn_pidm) 
             ) loop

                    Begin 
                         Update TZTMORA
                         set TZTMORA_ESTATUS = estat.estatus
                         where TZTMORA_PIDM= estat.pidm;
                    Exception
                        When Others then 
                            null;
                    End;
             End Loop;

         Commit;

         End;


         Begin
         
             For act in ( 
             
                         select distinct TZTMORA_pidm pidm, TZTMORA_DIAS dias
                         from TZTMORA a
                         where a.TZTMORA_DIAS = (select max (a1.TZTMORA_DIAS)
                         from TZTMORA a1
                         where a.TZTMORA_pidm = a1.TZTMORA_pidm)
                         order by 1
                       
             ) loop

                         Begin 
                             Update TZTMORA
                             set TZTMORA_DIAS = act.dias
                             where TZTMORA_pidm = act.pidm;
                         Exception
                            When OThers then 
                                null;
                         End;
             End Loop;
             Commit;
         End;

 END sp_moras;


PROCEDURE sp_moras_col
IS

 BEGIN

     Begin
           EXECUTE IMMEDIATE 'TRUNCATE TABLE TAISMGR.TZTMORA_COL';
           Commit;

         For mora in (

                     select distinct c.TBRACCD_PIDM pidm,
                     b.spriden_id Matricula,
                     b.SPRIDEN_LAST_NAME ||' '||b.SPRIDEN_FIRST_NAME Nombre,
                     c.TBRACCD_Balance Saldo,
                     TRUNC (c.TBRACCD_EFFECTIVE_DATE) Fecha_cargo,
                     ceil ((sysdate) - TRUNC (c.TBRACCD_EFFECTIVE_DATE)) dias ,
                     c.TBRACCD_DETAIL_CODE codigo,
                     a.tbbdetc_desc descrip,
                     a.TBBDETC_DCAT_CODE
                     from tbbdetc a, spriden b, tbraccd c
                     Where c.TBRACCD_DETAIL_CODE = a.tbbdetc_detail_code
                     And c.TBRACCD_DETAIL_CODE in (select a1.tbbdetc_detail_code
                     from tbbdetc a1
                     Where a.TBBDETC_TYPE_IND = a1.TBBDETC_TYPE_IND)
                     and a.TBBDETC_TYPE_IND = 'C'
                     and a.TBBDETC_DCAT_CODE = 'COL'
                     And c.TBRACCD_AMOUNT >0
                     And c.tbraccd_balance > 0
                     And b.spriden_pidm = TBRACCD_PIDM
                     and b.SPRIDEN_CHANGE_IND is null
                     And PKG_DASHBOARD_ALUMNO.f_dashboard_saldototal(tbraccd_pidm) > 0
                     ORDER BY 1, 9 DESC


         ) loop
                
                Begin 
                     Insert into TZTMORA_col values 
                     (mora.pidm,
                     mora.matricula,
                     mora.nombre,
                     mora.saldo,
                     mora.fecha_cargo,
                     mora.dias,
                     mora.descrip,
                     null);
                Exception
                    When Others then 
                     null;
                End;

         End Loop;

     End;


     Begin

             for estat in (
                             select distinct b.sgbstdn_pidm pidm, b.SGBSTDN_STST_CODE estatus
                             from TZTMORA_col a, sgbstdn b
                             Where a.TZTMORA_PIDM = b.sgbstdn_pidm
                             And b.SGBSTDN_TERM_CODE_EFF = (select max ( b1.SGBSTDN_TERM_CODE_EFF)
                             from SGBSTDN b1
                             where b.sgbstdn_pidm = b1.sgbstdn_pidm) 
             ) loop

                    Begin 
                         Update TZTMORA_col
                         set TZTMORA_ESTATUS = estat.estatus
                         where TZTMORA_PIDM= estat.pidm;
                    Exception
                        When Others then 
                            null;
                    End;
                    
             End Loop;

            Commit;

     End;


     Begin
         For act in ( 
                    select distinct TZTMORA_pidm pidm, TZTMORA_DIAS dias
                     from TZTMORA_col a
                     where a.TZTMORA_DIAS = (select max (a1.TZTMORA_DIAS)
                     from TZTMORA_col a1
                     where a.TZTMORA_pidm = a1.TZTMORA_pidm)
                     order by 1
         ) loop

                Begin 
                     Update TZTMORA_col
                     set TZTMORA_DIAS = act.dias
                     where TZTMORA_pidm = act.pidm;
                Exception
                    When OThers then 
                        null;
                End;

         End Loop;
     Commit;
     End;

 END sp_moras_col;


END PKG_MORAS;
/

DROP PUBLIC SYNONYM PKG_MORAS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_MORAS FOR BANINST1.PKG_MORAS;
