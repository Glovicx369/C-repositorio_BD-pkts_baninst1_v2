DROP PACKAGE BODY BANINST1.PKG_FREEMIUM;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_FREEMIUM AS
/******************************************************************************
   NAME:       PKG_FREEMIUM
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        29/07/2020      vramirlo       1. Created this package body.
******************************************************************************/


  PROCEDURE cancela_inscripcion
  as
    
  vl_salida varchar2(250):= 'EXITO';
  vl_periodo varchar2(6):= null;
  vl_no_sol number:=0;
  vl_decision varchar2(8):= null;
  vl_pago number:=0;
  vl_pago_minimo number:=0;
  vl_materias number:=0;
  vl_fecha_primera date;
  
  BEGIN
  
                ------------- Busco todos los alumnos que tienen la etiqueta de Freemiun en base al agrupador  ------------
       
            For c in (
           
                               select distinct a.pidm, 
                            a.matricula, 
                            a.programa,
                            a.campus,
                            a.nivel,
                            nvl (a.fecha_primera, a.fecha_inicio) fecha_inicio,
                            nvl (a.fecha_primera, a.fecha_inicio) + to_number((  Select ZSTPARA_PARAM_VALOR
                                                                        from ZSTPARA
                                                                        where 1= 1
                                                                        And ZSTPARA_PARAM_ID = 'FREE' 
                                                                        And ZSTPARA_MAPA_ID = 'DIAS_FREEMIUM')) +1 dias,
                                a.sp,
                                (select nvl (sum (tbraccd_amount),0)
                                from tbraccd, TZTNCD
                                where 1= 1
                                And tbraccd_detail_code = TZTNCD_CODE
                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                And tbraccd_pidm = a.pidm) pago,
                                'FREE' FREE
                            from tztprog a
                            join goradid b on b.goradid_pidm = a.pidm and b.GORADID_ADID_CODE in (  Select ZSTPARA_PARAM_VALOR
                                                                                                                                            from ZSTPARA
                                                                                                                                            where 1= 1
                                                                                                                                            And ZSTPARA_PARAM_VALOR = 'FREE' 
                                                                                                                                            And ZSTPARA_MAPA_ID = 'FREEMIUM_ADID'
                                                                                                                                        )
                            Where 1= 1
                      --     And a.matricula in  ('010302678')
                            And a.estatus = 'MA'
                            And a.sp = (select max (a1.sp)
                                                from tztprog a1
                                                Where a.pidm = a1.pidm
                                                And a.estatus = a1.estatus
                                                )                                                                        
                           Union                   ----------------- > Se aplica esta union para agregar los de 30 dias                               
                            select distinct a.pidm, 
                            a.matricula, 
                            a.programa,
                            a.campus,
                            a.nivel,
                            nvl (a.fecha_primera, a.fecha_inicio) fecha_inicio,
                            nvl (a.fecha_primera, a.fecha_inicio) + to_number((  Select ZSTPARA_PARAM_VALOR
                                                                        from ZSTPARA
                                                                        where 1= 1
                                                                        And ZSTPARA_PARAM_ID = 'FR30' 
                                                                        And ZSTPARA_MAPA_ID = 'DIAS_FREEMIUM')) +1 dias,
                                a.sp,
                               (select nvl (sum (tbraccd_amount),0)
                                from tbraccd, TZTNCD
                                where 1= 1
                                And tbraccd_detail_code = TZTNCD_CODE
                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                And tbraccd_pidm = a.pidm) pago,
                                'FR30' FREE
                            from tztprog a
                            join goradid b on b.goradid_pidm = a.pidm and b.GORADID_ADID_CODE in (  Select ZSTPARA_PARAM_VALOR
                                                                                                                                            from ZSTPARA
                                                                                                                                            Where 1= 1
                                                                                                                                            And ZSTPARA_PARAM_VALOR = 'FR30' 
                                                                                                                                            And  ZSTPARA_MAPA_ID = 'FREEMIUM_ADID'
                                                                                                                                        )
                            Where 1= 1
                        --   And a.matricula in  ('010302678')
                            And a.estatus = 'MA'
                            And a.sp = (select max (a1.sp)
                                                from tztprog a1
                                                Where a.pidm = a1.pidm
                                                And a.estatus = a1.estatus
                                                )                                                     
                           Union                   ----------------- > Se aplica esta union para agregar los de 60 dias                               
                            select distinct a.pidm, 
                            a.matricula, 
                            a.programa,
                            a.campus,
                            a.nivel,
                            nvl (a.fecha_primera, a.fecha_inicio) fecha_inicio,
                            nvl (a.fecha_primera, a.fecha_inicio) + to_number((  Select ZSTPARA_PARAM_VALOR
                                                                        from ZSTPARA
                                                                        where 1= 1
                                                                        And ZSTPARA_PARAM_ID = 'FR60' 
                                                                        And ZSTPARA_MAPA_ID = 'DIAS_FREEMIUM')) +1 dias,
                                a.sp,
                               (select nvl (sum (tbraccd_amount),0)
                                from tbraccd, TZTNCD
                                where 1= 1
                                And tbraccd_detail_code = TZTNCD_CODE
                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                And tbraccd_pidm = a.pidm) pago,
                                'FR60' FREE
                            from tztprog a
                            join goradid b on b.goradid_pidm = a.pidm and b.GORADID_ADID_CODE in (  Select ZSTPARA_PARAM_VALOR
                                                                                                                                            from ZSTPARA
                                                                                                                                            Where 1= 1
                                                                                                                                            And ZSTPARA_PARAM_VALOR = 'FR60' 
                                                                                                                                            And  ZSTPARA_MAPA_ID = 'FREEMIUM_ADID'
                                                                                                                                        )
                            Where 1= 1
                      --      And a.matricula in  ('010302678')
                            And a.estatus = 'MA'
                            And a.sp = (select max (a1.sp)
                                                from tztprog a1
                                                Where a.pidm = a1.pidm
                                                And a.estatus = a1.estatus
                                                )                                                      



        ) loop
                    
                ----------- Se obtiene el monto para el primer pago ----------------
                vl_pago_minimo:=0;
                vl_pago:=0;
                Begin
                
                         select distinct TZFACCE_AMOUNT
                            Into vl_pago_minimo
                        from TZFACCE
                        where 1= 1
                        And TZFACCE_PIDM  = c.pidm
                        And TZFACCE_DETAIL_CODE = 'PRIM'
                        and TZFACCE_FLAG = 0;               
                Exception
                    When Others then 
                        vl_pago_minimo :=0;
                End;

                DBMS_OUTPUT.PUT_LINE('pago_minimo ' ||vl_pago_minimo); 
                 
                vl_pago := c.pago;    
                If vl_pago_minimo is null then 
                   vl_pago_minimo :=0;
                End if;

                If vl_pago< vl_pago_minimo then 
                   vl_pago :=0;
                End if;

                Begin 
                        select distinct  trunc (SSBSECT_PTRM_END_DATE)
                            Into vl_fecha_primera
                        from sfrstcr, ssbsect
                        Where SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                        And SFRSTCR_CRN = SSBSECT_CRN
                        And SFRSTCR_PIDM = c.pidm
                        And SFRSTCR_STSP_KEY_SEQUENCE = c.sp
                        And trunc (SSBSECT_PTRM_START_DATE ) = trunc (c.fecha_inicio);
                Exception
                    When Others then 
                        vl_fecha_primera := null;
                End;

        
                If c.dias <= trunc (sysdate) and vl_pago = 0  And c.free != 'FR60'  then   ---- Cancela la venta 
                     DBMS_OUTPUT.PUT_LINE('Entra al cancelar ');
                       
                    ------------------------ Recupero el periodo  de SGBSTDN  para Bitacora ---------------------
                    
                        Begin
                                    
                                Select distinct a.SGBSTDN_TERM_CODE_EFF
                                   Into vl_periodo
                                from sgbstdn a
                               where 1 = 1
                               AND a.sgbstdn_pidm=c.pidm 
                               and a.sgbstdn_program_1=c.programa
                               And a.SGBSTDN_STST_CODE = 'MA' 
                               And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                                     from SGBSTDN a1
                                                                                     Where a.sgbstdn_pidm = a1.sgbstdn_pidm
                                                                                     And a.sgbstdn_program_1 = a1.sgbstdn_program_1
                                                                                     And a.SGBSTDN_STST_CODE = a1.SGBSTDN_STST_CODE);
                        Exception
                            When Others then 
                            vl_periodo := null;
                            vl_salida := 'Error el estatus en  SGBSTDN '||sqlerrm;
                        End;                
                     
                    DBMS_OUTPUT.PUT_LINE('SGBSTDN ' ||vl_periodo); 
                    
                                  
                       If  vl_salida = 'EXITO' then 
           
                            Begin 
                                                 ------------------------ Se cambia el estatus de SGBSTDN  a CV---------------------
                                   update sgbstdn a 
                                        set a.sgbstdn_stst_code= 'CV',
                                             a.SGBSTDN_STYP_CODE = 'D',
                                             a.SGBSTDN_ACTIVITY_DATE = SYSDATE,
                                             a.SGBSTDN_USER_ID = USER
                                   where 1 = 1
                                   AND a.sgbstdn_pidm=c.pidm 
                                   and a.sgbstdn_program_1=c.programa
                                   And a.SGBSTDN_STST_CODE = 'MA' 
                                   And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                                         from SGBSTDN a1
                                                                                         Where a.sgbstdn_pidm = a1.sgbstdn_pidm
                                                                                         And a.sgbstdn_program_1 = a1.sgbstdn_program_1
                                                                                         And a.SGBSTDN_STST_CODE = a1.SGBSTDN_STST_CODE);
                            Exception
                                When Others then 
                                vl_salida := 'Error al Actualizar Estatus en SGBSTDN '||sqlerrm;
                            End;
                            
                            DBMS_OUTPUT.PUT_LINE('Actualiza SGBSTDN ' ||vl_salida); 
                            
                            If  vl_salida = 'EXITO' then 
                                  PKG_FREEMIUM.bitacora (c.pidm, vl_periodo, c.sp, c.programa,'Cancelacion de Venta por FREEMIUM: '||c.free);
                                  PKG_FREEMIUM.Cancela_Solicitud (c.pidm, c.programa);
                                  PKG_FREEMIUM.cancela_curricula (c.pidm, c.programa,vl_periodo);
                                  PKG_FREEMIUM.cancela_sp  (c.pidm,c.sp, vl_periodo);
                                  vl_salida := pkg_jornadas_abcc.f_baja_abcc_cciclo('CV',c.fecha_inicio, c.pidm);
                                  PKG_FREEMIUM.quita_etiqueta (c.pidm, c.FREE);
                                  PKG_FREEMIUM.bitacora (c.pidm, vl_periodo, c.sp, c.programa,'Se elimina etiqueta FREEMIUM por Cancelacion de Venta: '||c.free);
                                  PKG_FREEMIUM.cancela_UtelX (c.pidm,vl_periodo, c.matricula, c.campus, c.nivel);
                            End if;                  
                               
                              DBMS_OUTPUT.PUT_LINE('Respuesta salida ' ||vl_salida); 
                            
                            If  vl_salida = 'EXITO' then 
                                Commit;
                            Else
                                rollback;
                            End if;  
                               
                    
                       End  if;
                       
                       
                ElsIf vl_fecha_primera is not null and vl_fecha_primera <=  trunc (sysdate) and vl_pago = 0  then   ---- Cancela la venta 
                            DBMS_OUTPUT.PUT_LINE('Entra al cancelar ');
                       
                    ------------------------ Recupero el periodo  de SGBSTDN  para Bitacora ---------------------
                    
                        Begin
                                    
                                Select distinct a.SGBSTDN_TERM_CODE_EFF
                                Into vl_periodo
                                from sgbstdn a
                               where 1 = 1
                               AND a.sgbstdn_pidm=c.pidm 
                               and a.sgbstdn_program_1=c.programa
                               And a.SGBSTDN_STST_CODE = 'MA' 
                               And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                                     from SGBSTDN a1
                                                                                     Where a.sgbstdn_pidm = a1.sgbstdn_pidm
                                                                                     And a.sgbstdn_program_1 = a1.sgbstdn_program_1
                                                                                     And a.SGBSTDN_STST_CODE = a1.SGBSTDN_STST_CODE);
                        Exception
                            When Others then 
                            vl_periodo := null;
                            vl_salida := 'Error el estatus en  SGBSTDN '||sqlerrm;
                        End;                
                     
                    DBMS_OUTPUT.PUT_LINE('SGBSTDN ' ||vl_periodo); 
                    
                                  
                       If  vl_salida = 'EXITO' then 
           
                            Begin 
                                                 ------------------------ Se cambia el estatus de SGBSTDN  a CV---------------------
                                   update sgbstdn a 
                                        set a.sgbstdn_stst_code= 'CV',
                                             a.SGBSTDN_STYP_CODE = 'D',
                                             a.SGBSTDN_ACTIVITY_DATE = SYSDATE,
                                             a.SGBSTDN_USER_ID = USER
                                   where 1 = 1
                                   AND a.sgbstdn_pidm=c.pidm 
                                   and a.sgbstdn_program_1=c.programa
                                   And a.SGBSTDN_STST_CODE = 'MA' 
                                   And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                                         from SGBSTDN a1
                                                                                         Where a.sgbstdn_pidm = a1.sgbstdn_pidm
                                                                                         And a.sgbstdn_program_1 = a1.sgbstdn_program_1
                                                                                         And a.SGBSTDN_STST_CODE = a1.SGBSTDN_STST_CODE);
                            Exception
                                When Others then 
                                vl_salida := 'Error al Actualizar Estatus en SGBSTDN '||sqlerrm;
                            End;
                            
                            DBMS_OUTPUT.PUT_LINE('Actualiza SGBSTDN ' ||vl_salida); 
                            
                            If  vl_salida = 'EXITO' then 
                                  PKG_FREEMIUM.bitacora (c.pidm, vl_periodo, c.sp, c.programa,'Cancelacion de Venta por FREEMIUM: '||c.free);
                                  PKG_FREEMIUM.Cancela_Solicitud (c.pidm, c.programa);
                                  PKG_FREEMIUM.cancela_curricula (c.pidm, c.programa,vl_periodo);
                                  PKG_FREEMIUM.cancela_sp  (c.pidm,c.sp, vl_periodo);
                                  vl_salida := pkg_jornadas_abcc.f_baja_abcc_cciclo('CV',c.fecha_inicio, c.pidm);
                                  PKG_FREEMIUM.quita_etiqueta (c.pidm, c.FREE);
                                  PKG_FREEMIUM.bitacora (c.pidm, vl_periodo, c.sp, c.programa,'Se elimina etiqueta FREEMIUM por Cancelacion de Venta: '||c.free);
                                  PKG_FREEMIUM.cancela_UtelX (c.pidm,vl_periodo, c.matricula, c.campus, c.nivel);
                            End if;                  
                               
                              DBMS_OUTPUT.PUT_LINE('Respuesta salida ' ||vl_salida); 
                            
                            If  vl_salida = 'EXITO' then 
                                Commit;
                            Else
                                rollback;
                            End if;  
                               
                    
                       End  if;                       
                       
                  --------------------------------------------------------------------------------------------------------------     
                       
                Elsif  c.pago >= vl_pago_minimo and c.pago > 0   then  ----- Quito la etiqueta de freemium para generar cartera
                        vl_no_sol:=0;
                        vl_decision:= null;
                        DBMS_OUTPUT.PUT_LINE('Entra al pago ');
                        
                        Begin
                        
                                Select SARAPPD_APDC_CODE, SARAPPD_APPL_NO, SARAPPD_TERM_CODE_ENTRY
                                   Into  vl_decision, vl_no_sol, vl_periodo
                                from sarappd a
                                where 1 = 1
                                And a.sarappd_pidm = c.pidm
                                And a.SARAPPD_APDC_CODE ='35'
                                And a.SARAPPD_APPL_NO = (select max (a1.SARAPPD_APPL_NO)
                                                                              from sarappd a1
                                                                            Where a.sarappd_pidm = a1.sarappd_pidm
                                                                            And a.SARAPPD_APDC_CODE = a1.SARAPPD_APDC_CODE
                                                                            And a1.SARAPPD_SEQ_NO = (select max (a2.SARAPPD_SEQ_NO)
                                                                                                                        from sarappd a2
                                                                                                                        Where a1.sarappd_pidm = a2.sarappd_pidm
                                                                                                                        And a1.SARAPPD_APPL_NO = a2.SARAPPD_APPL_NO
                                                                                                                        And a1.SARAPPD_APDC_CODE = a2.SARAPPD_APDC_CODE
                                                                                                                        )
                                                                         );
                        Exception
                            When Others then 
                                 vl_decision:= null; 
                                 vl_no_sol:=0;
                        End;
                        
                        DBMS_OUTPUT.PUT_LINE('recupero saradap ' ||vl_decision||'*'|| vl_no_sol||'*'|| vl_periodo);
                        
                        vl_materias:=0;
                        Begin
                                
                                Select count(1)
                                Into vl_materias
                                from sfrstcr, ssbsect
                                Where 1= 1
                                And SFRSTCR_PIDM = c.pidm
                                And SFRSTCR_STSP_KEY_SEQUENCE = c.sp
                                And SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                                And SFRSTCR_CRN = SSBSECT_CRN
                                And trunc (SSBSECT_PTRM_START_DATE)  = c.fecha_inicio;
                        Exception
                            When Others then 
                                vl_materias :=0;
                        End;
                        
                         DBMS_OUTPUT.PUT_LINE('recupero Materias ' ||vl_materias ||'*'||vl_decision||'*'||vl_no_sol||'*'||vl_periodo);
                        
                        If vl_materias >= 1 then  --> valida que existan materias
                                    If vl_decision = '35' and vl_no_sol > 0 and vl_periodo is not null then 
                                       DBMS_OUTPUT.PUT_LINE('Entra al con decision  ');
                                    
                                        If c.FREE ='FREE' then 
                                          DBMS_OUTPUT.PUT_LINE('Entra al con FREE  '||c.FREE);
                                            
                                            PKG_FREEMIUM.quita_etiqueta (c.pidm, c.free);
                                            PKG_FREEMIUM.bitacora (c.pidm, vl_periodo, c.sp, c.programa,'Se elimina etiqueta FREEMIUM por Pago realizado: '||c.free);
                                            PKG_MOODLE2.p_inserta_sztbnda (c.pidm, vl_periodo, vl_no_sol);  
                                            PKG_FINANZAS.P_GEN_CART_CONF ( null, c.fecha_inicio, c.matricula, null, null );
                                        Elsif  c.FREE ='FR30' then 
                                            DBMS_OUTPUT.PUT_LINE('Entra al con FREE30  '||c.FREE);
                                            PKG_FREEMIUM.quita_etiqueta (c.pidm, c.free);
                                            PKG_FREEMIUM.bitacora (c.pidm, vl_periodo, c.sp, c.programa,'Se elimina etiqueta FREEMIUM por Pago realizado: '||c.free);
                                            PKG_MOODLE2.p_inserta_sztbnda (c.pidm, vl_periodo, vl_no_sol);  
                                            PKG_FINANZAS.P_GEN_CART_CONF ( null, c.fecha_inicio, c.matricula, null, null );

                                            Begin 
                                                                            
                                                        For cx in (
                                                                                    
                                                                        select a.TBRACCD_PIDM pidm, a.TBRACCD_TRAN_NUMBER secuencia, substr (d.matricula, 1, 2)||'RY' Concepto, 
                                                                        nvl (a.TBRACCD_AMOUNT,0) - (select sum (nvl (a1.TZFACCE_AMOUNT,0))
                                                                                                                        from tzfacce a1
                                                                                                                        join tbbdetc on TBBDETC_DETAIL_CODE = a1.TZFACCE_DETAIL_CODE and TBBDETC_TYPE_IND ='P'  and TBBDETC_DCAT_CODE ='DEP'
                                                                                                                        where a1.TZFACCE_PIDM = a.tbraccd_pidm and to_char (a1.TZFACCE_EFFECTIVE_DATE,'MM/YYYY') = to_char (TBRACCD_EFFECTIVE_DATE,'MM/YYYY')
                                                                                                                        and a1.TZFACCE_FLAG = '1'
                                                                                                                        And  a1.TZFACCE_SEC_PIDM = (select max (a2.TZFACCE_SEC_PIDM)
                                                                                                                                                                        from TZFACCE a2
                                                                                                                                                                        Where a1.TZFACCE_PIDM = a2.TZFACCE_PIDM
                                                                                                                                                                           And a1.TZFACCE_DETAIL_CODE = a2.TZFACCE_DETAIL_CODE
                                                                                                                                                                          And a1.TZFACCE_FLAG = a2.TZFACCE_FLAG
                                                                                                                                                                        )
                                                                                                                        )   Monto ,                                                     
                                                                                       a.TBRACCD_TERM_CODE periodo, 'PROMOCION FREEMIUM' Descripcion, trunc (sysdate)  Vencimiento, a.TBRACCD_STSP_KEY_SEQUENCE Sp,
                                                                                       a.TBRACCD_FEED_DATE Fecha_Inicio, a.TBRACCD_PERIOD Pperiodo, user usuario
                                                                        from tbraccd a
                                                                        join  TZTNCD b on b.TZTNCD_CODE = a.tbraccd_detail_code and b.TZTNCD_CONCEPTO = 'Venta'
                                                                        join tbbdetc c on c.TBBDETC_DETAIL_CODE = b.TZTNCD_CODE and c.TBBDETC_DCAT_CODE = 'COL'
                                                                        join tztprog d on d.pidm = a.tbraccd_pidm
                                                                        where 1= 1
                                                                        And a.TBRACCD_AMOUNT = a.TBRACCD_BALANCE
                                                                        And trunc (TBRACCD_EFFECTIVE_DATE) = (select min  (trunc (a1.TBRACCD_EFFECTIVE_DATE))
                                                                                                                                         from tbraccd a1
                                                                                                                                         Where a.tbraccd_pidm = a1.tbraccd_pidm
                                                                                                                                         And a.tbraccd_detail_code = a1.tbraccd_detail_code
                                                                                                                                         And a1.TBRACCD_AMOUNT = a1.TBRACCD_BALANCE
                                                                                                                                         )
                                                                        and tbraccd_pidm = c.pidm 
                                                                         And trunc (TBRACCD_FEED_DATE) =c.fecha_inicio     
                                                                                                                                   
                                                        ) loop                 
                                                                                       
                                                            vl_salida:= PKG_FINANZAS.SP_APLICA_AJUSTE ( cx.pidm, 
                                                                                                                    cx.secuencia, 
                                                                                                                    cx.concepto, 
                                                                                                                    cx.monto, 
                                                                                                                    cx.periodo, 
                                                                                                                    cx.descripcion, 
                                                                                                                    cx.Vencimiento, 
                                                                                                                    cx.sp, 
                                                                                                                    cx.fecha_inicio, 
                                                                                                                    cx.pperiodo, 
                                                                                                                    cx.usuario );        
                                                        End Loop;
                                            Exception
                                                When Others then    
                                                    null;
                                            End;               

                                        Elsif  c.FREE ='FR60' then 
                                         DBMS_OUTPUT.PUT_LINE('Entra al con FREE60  '||c.FREE);
                                            PKG_FREEMIUM.quita_etiqueta (c.pidm, c.free);
                                            PKG_FREEMIUM.bitacora (c.pidm, vl_periodo, c.sp, c.programa,'Se elimina etiqueta FREEMIUM por Pago realizado: '||c.free);
                                            PKG_MOODLE2.p_inserta_sztbnda (c.pidm, vl_periodo, vl_no_sol);  
                                            PKG_FINANZAS.P_GEN_CART_CONF ( null, c.fecha_inicio, c.matricula, null, null );

                                            Begin 
                                                                            
                                                        For cx in (
                                                                                    
                                                                        select a.TBRACCD_PIDM pidm, a.TBRACCD_TRAN_NUMBER secuencia, substr (d.matricula, 1, 2)||'RY' Concepto, 
                                                                        nvl (a.TBRACCD_AMOUNT,0) - (select sum (nvl (TZFACCE_AMOUNT,0))
                                                                                                                        from tzfacce
                                                                                                                        join tbbdetc on TBBDETC_DETAIL_CODE = TZFACCE_DETAIL_CODE and TBBDETC_TYPE_IND ='P'  and TBBDETC_DCAT_CODE ='DEP'
                                                                                                                        where TZFACCE_PIDM = a.tbraccd_pidm and trunc (TZFACCE_EFFECTIVE_DATE) = trunc (TBRACCD_EFFECTIVE_DATE)
                                                                                                                        and TZFACCE_FLAG = '1' 
                                                                                                                        )   Monto ,                                                     
                                                                                       a.TBRACCD_TERM_CODE periodo, 'PROMOCION FREEMIUM' Descripcion, trunc (sysdate)  Vencimiento, a.TBRACCD_STSP_KEY_SEQUENCE Sp,
                                                                                       a.TBRACCD_FEED_DATE Fecha_Inicio, a.TBRACCD_PERIOD Pperiodo, user usuario
                                                                        from tbraccd a
                                                                        join  TZTNCD b on b.TZTNCD_CODE = a.tbraccd_detail_code and b.TZTNCD_CONCEPTO = 'Venta'
                                                                        join tbbdetc c on c.TBBDETC_DETAIL_CODE = b.TZTNCD_CODE and c.TBBDETC_DCAT_CODE = 'COL'
                                                                        join tztprog d on d.pidm = a.tbraccd_pidm
                                                                        where 1= 1
                                                                        And a.TBRACCD_AMOUNT = a.TBRACCD_BALANCE
                                                                        and tbraccd_pidm = c.pidm           
                                                                        And trunc (TBRACCD_FEED_DATE) = c.fecha_inicio                                                  
                                                        ) loop                 
                                                                                       
                                                            vl_salida:= PKG_FINANZAS.SP_APLICA_AJUSTE ( cx.pidm, 
                                                                                                                    cx.secuencia, 
                                                                                                                    cx.concepto, 
                                                                                                                    cx.monto, 
                                                                                                                    cx.periodo, 
                                                                                                                    cx.descripcion, 
                                                                                                                    cx.Vencimiento, 
                                                                                                                    cx.sp, 
                                                                                                                    cx.fecha_inicio, 
                                                                                                                    cx.pperiodo, 
                                                                                                                    cx.usuario );        
                                                        End Loop;
                                            Exception
                                                When Others then    
                                                    null;
                                            End;               

                                               
                                            
                                        End if;             
                                        
                                        
                                    End if;
                        End if;
                        
                        If  vl_salida = 'EXITO' then 
                            Commit;
                        Else
                            rollback;
                        End if;                          
                        
                End if;
                        
        End Loop;
        
  
  END cancela_inscripcion;
  
  
procedure bitacora (vl_pidm in number, vl_periodo in varchar2, vl_sp in number, vl_programa in varchar2, vl_comentario in varchar2)

as

  vn_sec_SGRSCMT number:=0;
  l_descripcion varchar2(2000):= null;
  
    Begin 
        
        Begin
              SELECT NVL(MAX(SGRSCMT_SEQ_NO),0)+1
            INTO vn_sec_SGRSCMT
          FROM SGRSCMT
          WHERE SGRSCMT_PIDM  = vl_pidm
          AND SGRSCMT_TERM_CODE = vl_periodo;
        Exception
                When Others then 
                  vn_sec_SGRSCMT :=1;
        End;

         l_descripcion:=   vl_comentario||' ' ||vl_periodo ||' '||vl_programa;


                      
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
                vl_pidm
              , vn_sec_SGRSCMT
              , vl_periodo
              , l_descripcion
              , SYSDATE
              , 'FREEMIUM'
              , user
              , vl_sp
             );
        Exception
                When Others then 
                null;         
        End;


Exception
    when others then 
        null;
End bitacora;  
  
procedure Cancela_Solicitud (vl_pidm in number, vl_programa in varchar2)
as

Begin

        Begin
        
                Insert into SZTACTU
                    select a.pidm, a.id, a.programa, a.solicitud, '6', '8', null, null, sysdate
                    from SZTACTU a 
                    where pidm = vl_pidm
                    And PROGRAMA = vl_programa
                    And estatus||evento = '37' 
                    And PROCESADO ='P';
        Exception
            When Others then 
                null;        
        End;
        
        
        Begin
                Update saradap
                  set SARADAP_APST_CODE = 'X',
                        SARADAP_ACTIVITY_DATE = sysdate,
                        SARADAP_DATA_ORIGIN = 'FREEMIUM'
                 Where saradap_pidm = vl_pidm
                 And SARADAP_APST_CODE ='A'
                 And SARADAP_PROGRAM_1 = vl_programa;
        Exception
            When Others then 
                null;
        End;
        
        
        Begin
                update sarappd
                set SARAPPD_APDC_CODE = '50',
                SARAPPD_DATA_ORIGIN = 'FREEMIUM',
                SARAPPD_ACTIVITY_DATE = sysdate
                where sarappd_pidm = vl_pidm
                And SARAPPD_APDC_CODE  ='35';
        Exception
            When Others then 
                null;
        End;
        


End Cancela_Solicitud;

procedure quita_etiqueta (vl_pidm in number, vl_etiqueta in varchar2) 

As 

Begin 

        Begin 
                    delete goradid
                    where GORADID_PIDM = vl_pidm
                    And GORADID_ADID_CODE = vl_etiqueta;
        Exception
            When Others then 
                null;
        End;

End quita_etiqueta;

procedure cancela_curricula  (vl_pidm in number, vl_programa in varchar2, vl_periodo in varchar2)

As 
  lv_salida varchar2(250):= 'EXITO';

Begin 


        Begin 
                update  sorlfos
                set SORLFOS_CACT_CODE = 'INACTIVE',
                     SORLFOS_TERM_CODE_END = vl_periodo,
                     SORLFOS_DATA_ORIGIN ='FREEMIUM',
                     SORLFOS_ACTIVITY_DATE = sysdate
                where sorlfos_pidm = vl_pidm
                and SORLFOS_LCUR_SEQNO in (select SORLCUR_SEQNO
                                                                        from sorlcur
                                                                where 1= 1
                                                                And sorlcur_pidm = vl_pidm
                                                                And SORLCUR_PROGRAM = vl_programa
                                                                and SORLCUR_LMOD_CODE in ( 'LEARNER', 'ADMISSIONS'));
        Exception
            When Others then 
               lv_salida := 'Error';                                                         
        End;

        Begin 
                update  sorlcur
                set SORLCUR_CACT_CODE = 'INACTIVE',
                      SORLCUR_ROLL_IND ='N',
                      SORLCUR_TERM_CODE_END = vl_periodo,
                      SORLCUR_PRIORITY_NO = '99',
                      SORLCUR_DATA_ORIGIN   = 'FREEMIUM',
                      SORLCUR_ACTIVITY_DATE = sysdate
                where 1= 1
                And sorlcur_pidm = vl_pidm
                And SORLCUR_PROGRAM = vl_programa
                and SORLCUR_LMOD_CODE in ( 'LEARNER', 'ADMISSIONS');
        Exception
            When Others then 
                lv_salida := 'Error';    
        End;
        
 End cancela_curricula;
        
procedure cancela_sp  (vl_pidm in number, vl_sp in varchar2, vl_periodo in varchar2)
As 

Begin 

        Begin
                Update SGRSTSP
                    set SGRSTSP_STSP_CODE = 'IN',
                          SGRSTSP_ACTIVITY_DATE = sysdate,
                          SGRSTSP_DATA_ORIGIN = 'FREEMIUM'
                Where  SGRSTSP_PIDM = vl_pidm
                And SGRSTSP_KEY_SEQNO = vl_sp;
        Exception
            When Others then 
                null;
        End;


End cancela_sp;

procedure cancela_sgbstdn  (vl_pidm in number)

as 

vl_canal varchar2(10):= null;
vl_sp number:=0;
vl_programa varchar2(50):= null;

Begin 

        Begin 
                select pkg_utilerias.f_canal_venta(vl_pidm, 'CANF') 
                Into vl_canal
                from dual;
        Exception
            When Others then 
                null;        
        End;      
        --dbms_output.put_line ('Cana de Venta   ' || vl_canal );
        
        Begin
                Select a.sp, a.programa
                    Into vl_sp, vl_programa
                from tztprog a   
                Where a.pidm = vl_pidm
                And  a.estatus = 'CV'
                And a.sp = (select max (a1.sp)
                                    from tztprog a1
                                    Where a.pidm = a1.pidm
                                    And a.estatus = a1.estatus);
        Exception
            When Others then 
                null;
        End;
     --   dbms_output.put_line ('sp, programa   ' || vl_sp ||'*'|| vl_programa);

        If vl_canal = '45' then 
                
                    Begin 
                            Delete sgbstdn
                            Where sgbstdn_pidm = vl_pidm
                            And SGBSTDN_PROGRAM_1 = vl_programa
                            And SGBSTDN_STST_CODE = 'CV';
                    Exception
                        When Others then 
                            null;
                         --   dbms_output.put_line ('Borra SGBSTDN  ' ||sqlerrm);
                    End;    
        
                    Begin
                        delete SGRSATT
                        where SGRSATT_PIDM = vl_pidm
                        And SGRSATT_STSP_KEY_SEQUENCE = vl_sp;
                    Exception
                        When Others then 
                            null;     
                         --   dbms_output.put_line ('Borra SGRSATT  ' ||sqlerrm);
                    End;
                    
                    Begin 
                            delete SGRCHRT
                            Where SGRCHRT_PIDM = vl_pidm
                            And SGRCHRT_STSP_KEY_SEQUENCE = vl_sp;
                    Exception
                        When Others then 
                            null;    
                         --   dbms_output.put_line ('Borra SGRCHRT  ' ||sqlerrm);
                    End;
                    
                    Begin 
                            delete   sorlfos
                            where sorlfos_pidm = vl_pidm
                            And SORLFOS_CACT_CODE = 'INACTIVE'
                            and SORLFOS_LCUR_SEQNO in (select SORLCUR_SEQNO
                                                                                    from sorlcur
                                                                            where 1= 1
                                                                            And sorlcur_pidm = vl_pidm
                                                                            And SORLCUR_PROGRAM = vl_programa
                                                                            and SORLCUR_LMOD_CODE in ( 'LEARNER'));
                    Exception
                        When Others then 
                           null;                                                  
                    End;

                    Begin 
                            Delete sorlcur
                            where 1= 1
                            And sorlcur_pidm = vl_pidm
                            And SORLCUR_CACT_CODE = 'INACTIVE'
                            And SORLCUR_PRIORITY_NO = '99'
                            And SORLCUR_PROGRAM = vl_programa
                            and SORLCUR_LMOD_CODE in ( 'LEARNER');
                    Exception
                        When Others then 
                            null;
                    End;
        
                    
        End if ;
        Commit;

End cancela_sgbstdn;

Procedure cancela_UtelX (vl_pidm in number, vl_periodo in varchar2, vl_matricula varchar2, vl_campus varchar2, vl_nivel varchar2)

as 
vl_contador number :=0;
vl_pass varchar2(50);

Begin 


                          BEGIN
                              SELECT NVL(MAX(SZTUTLX_SEQ_NO),0)+1
                              into vl_contador
                              FROM SZTUTLX
                              WHERE 1=1
                              AND SZTUTLX_PIDM = vl_pidm;
                          EXCEPTION 
                          WHEN OTHERS THEN
                          vl_contador:=1;                                                    
                          END;                                 
                                 
                          vl_pass:= null;   
                          Begin
                                Select distinct GOZTPAC_PIN pass
                                    Into vl_pass
                                from GOZTPAC
                                Where GOZTPAC_PIDM = vl_pidm;
                          Exception
                            When Others then 
                                vl_pass:= null;
                          End;
                                        
                            begin                                
                                     INSERT INTO SZTUTLX VALUES(vl_pidm,--SZTUTLX_PIDM
                                                                               vl_matricula, --SZTUTLX_ID
                                                                               vl_periodo,--SZTUTLX_TERM_CODE
                                                                               vl_campus,--SZTUTLX_CAMP_CODE
                                                                               vl_nivel,--SZTUTLX_LEVL_UPDATE
                                                                               vl_contador,--SZTUTLX_SEQ_NO
                                                                               0,--SZTUTLX_STAT_IND
                                                                               Null,--SZTUTLX_OBS
                                                                               'I',--SZTUTLX_DISABLE_IND
                                                                               vl_pass,--SZTUTLX_PWD
                                                                               Null,--SZTUTLX_MDL_ID
                                                                               USER,--SZTUTLX_USER_INSERT
                                                                               SYSDATE,--SZTUTLX_ACTIVITY_DATE                                          
                                                                               Null,--SZTUTLX_DATE_UPDATE
                                                                               Null,--SZTUTLX_USER_UPDATE
                                                                               Null,--SZTUTLX_ROW1
                                                                               Null,--SZTUTLX_ROW2
                                                                               Null,--SZTUTLX_ROW3
                                                                               Null,--SZTUTLX_ROW4
                                                                               Null,--SZTUTLX_ROW5
                                                                               'BLOCK_FREEMIUM',--
                                                                               SYSDATE,
                                                                               null,
                                                                               null,
                                                                               null,
                                                                               null,
                                                                               null,
                                                                               null
                                                                               );                              
                            Exception
                            When Others then 
                            null;
                            --dbms_output.put_line('Error al insertar 1:  '||sqlerrm); 
                            end;





End cancela_UtelX;



END PKG_FREEMIUM;
/

GRANT EXECUTE, DEBUG ON BANINST1.PKG_FREEMIUM TO PUBLIC;
