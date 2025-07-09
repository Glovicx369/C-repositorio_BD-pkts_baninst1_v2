DROP PACKAGE BODY BANINST1.PKG_SSB;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_SSB AS
/******************************************************************************
   NAME:       PKG_SSB
   PURPOSE: Paquete que controlara los llamadas a procedimientos y funciones del SSB nativo.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        27/11/2015      vramirlo       1. Created this package body.
******************************************************************************/
PROCEDURE P_CANCELA_CARGO_AUTOMATICO  IS

vl_existe number;
vl_valida number;
vl_secuencia number;
vl_val_sol number;


BEGIN

            For servicio in (select SVRRSRV_SEQ_NO, SVRRSRV_SRVC_CODE, SZRRCON_VIG_PAG
                                    from SVRRSRV, SZRRCON
                                    where SVRRSRV_INACTIVE_IND = 'Y'   ---- Unicamente Activas
                                    And SVRRSRV_WEB_IND = 'Y'   --- Unicamente las que se muestren por WEB
                                    And SVRRSRV_SEQ_NO = SZRRCON_RSRV_SEQ_NO
                                    And SVRRSRV_SRVC_CODE = SZRRCON_SRVC_CODE
                                    And SZRRCON_PAG_FOR = 'S'
                                    And SZRRCON_VIG_PAG > 0 ) loop
                                    
                                    --dbms_output.put_line('SVRRSRV_SEQ_NO:'||servicio.SVRRSRV_SEQ_NO||'SVRRSRV_SRVC_CODE:'||servicio.SVRRSRV_SRVC_CODE||'SZRRCON_VIG_PAG:'||servicio.SZRRCON_VIG_PAG);

  ----- Validacion que la solicitud para ser canceladas----

                                    For solicitud in (select SVRSVPR_PROTOCOL_SEQ_NO, SVRSVPR_PIDM    ----SZRRCON_PAG_FOR
                                                             from SVRSVPR
                                                             Where SVRSVPR_SRVS_CODE not  in ('CA', 'AN')  
                                                             And SVRSVPR_RSRV_SEQ_NO = servicio.SVRRSRV_SEQ_NO
                                                             And SVRSVPR_SRVC_CODE = servicio.SVRRSRV_SRVC_CODE
                                                             ) loop
                                                 
                                                 ----- En caso que la solicitud  no este cancelada se buscaran los codigos de detalle que fueron creados en el estado de de cuenta
                                                vl_existe :=0;
                                                vl_valida := 0; 
                                                vl_secuencia :=0;
                                                --dbms_output.put_line('SVRSVPR_PROTOCOL_SEQ_NO:'||solicitud.SVRSVPR_PROTOCOL_SEQ_NO||'SVRSVPR_PIDM:'||solicitud.SVRSVPR_PIDM);
                                                
                                                For valida_cargo in (select TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_DETAIL_CODE, TBRACCD_ENTRY_DATE + servicio.SZRRCON_VIG_PAG vigencia,
                                                                                        TBRACCD_AMOUNT, TBRACCD_BALANCE, TBRACCD_EFFECTIVE_DATE
                                                                                From tbraccd 
                                                                                Where tbraccd_pidm = solicitud.SVRSVPR_PIDM
                                                                                And TBRACCD_CROSSREF_NUMBER = solicitud.SVRSVPR_PROTOCOL_SEQ_NO
                                                                                  ) loop
                                                       --dbms_output.put_line('TBRACCD_PIDM:'||valida_cargo.TBRACCD_PIDM||'TBRACCD_TRAN_NUMBER:'||valida_cargo.TBRACCD_TRAN_NUMBER||'TBRACCD_DETAIL_CODE;'||valida_cargo.TBRACCD_DETAIL_CODE||'vigencia:'||valida_cargo.vigencia||'TBRACCD_AMOUNT:'||valida_cargo.TBRACCD_AMOUNT||'TBRACCD_BALANCE:'||valida_cargo.TBRACCD_BALANCE||'TBRACCD_EFFECTIVE_DATE:'||valida_cargo.TBRACCD_EFFECTIVE_DATE);                          
                                                                               
                                                        If  valida_cargo.TBRACCD_AMOUNT  =   valida_cargo.TBRACCD_BALANCE and valida_cargo.vigencia < sysdate    then
                                                            vl_valida := 1;
                                                            Begin 
                                                                Select count(1)
                                                                 Into vl_existe
                                                                from tbrappl 
                                                                Where TBRAPPL_PIDM = valida_cargo.TBRACCD_PIDM
                                                                And TBRAPPL_CHG_TRAN_NUMBER = valida_cargo.TBRACCD_TRAN_NUMBER
                                                                And TBRAPPL_REAPPL_IND is null;
                                                            Exception 
                                                                When Others then 
                                                                   vl_existe :=0;
                                                            End;
                                                            
                                                        End if;                    
                                                                               
                                                --dbms_output.put_line(' Valida Cargo '||'--'||solicitud.SVRSVPR_PROTOCOL_SEQ_NO|| '--'||solicitud.SVRSVPR_PIDM||'--' ||valida_cargo.TBRACCD_AMOUNT ||' -- '||  valida_cargo.TBRACCD_BALANCE||'--'|| valida_cargo.vigencia );

                                                End loop valida_cargo;
                                                --dbms_output.put_line('vl_valida:'||vl_valida||'vl_existe:'||vl_existe);
                                                If  vl_valida = 1 and  vl_existe =0 then 
                                                    
                                                
                                                       Begin   
                                                             
                                                         update SVRSVPR
                                                         Set SVRSVPR_SRVS_CODE = 'AN', SVRSVPR_ACTIVITY_DATE=SYSDATE, SVRSVPR_STEP_COMMENT='CANCELADO'
                                                         Where SVRSVPR_SRVS_CODE not  in ('CA', 'AN')  
                                                         And SVRSVPR_RSRV_SEQ_NO = servicio.SVRRSRV_SEQ_NO
                                                         And SVRSVPR_SRVC_CODE = servicio.SVRRSRV_SRVC_CODE
                                                         And SVRSVPR_PIDM = solicitud.SVRSVPR_PIDM;

                                                         vl_val_sol := 1;

                                                       Exception
                                                       When Others then 
                                                            vl_val_sol :=2;
                                                             
                                                       End;   
                                                       --dbms_output.put_line('vl_val_sol:'||vl_val_sol);
                                                       If vl_val_sol = 1 then       
                                                
                                                               Begin 
                                                                    select max (TBRACCD_TRAN_NUMBER)
                                                                    Into vl_secuencia
                                                                    from tbraccd
                                                                    where tbraccd_pidm = solicitud.SVRSVPR_PIDM;
                                                               Exception
                                                                When Others then 
                                                                   vl_secuencia :=0;
                                                               End;
                                                        
                                                                        
                                                               For cancela_cargo in (select TBRACCD_PIDM
                                                                                                        ,TBRACCD_TRAN_NUMBER,TBRACCD_TERM_CODE,TBRACCD_DETAIL_CODE ,TBRACCD_USER ,TBRACCD_ENTRY_DATE ,TBRACCD_AMOUNT, TBRACCD_BALANCE
                                                                                                        ,TBRACCD_EFFECTIVE_DATE, TBRACCD_BILL_DATE ,TBRACCD_DUE_DATE ,TBRACCD_DESC ,TBRACCD_RECEIPT_NUMBER ,TBRACCD_TRAN_NUMBER_PAID ,TBRACCD_CROSSREF_PIDM
                                                                                                        ,TBRACCD_CROSSREF_NUMBER, TBRACCD_CROSSREF_DETAIL_CODE ,TBRACCD_SRCE_CODE ,TBRACCD_ACCT_FEED_IND ,TBRACCD_ACTIVITY_DATE ,TBRACCD_SESSION_NUMBER ,TBRACCD_CSHR_END_DATE
                                                                                                        ,TBRACCD_CRN, TBRACCD_CROSSREF_SRCE_CODE ,TBRACCD_LOC_MDT ,TBRACCD_LOC_MDT_SEQ ,TBRACCD_RATE ,TBRACCD_UNITS ,TBRACCD_DOCUMENT_NUMBER ,TBRACCD_TRANS_DATE ,TBRACCD_PAYMENT_ID
                                                                                                        ,TBRACCD_INVOICE_NUMBER ,TBRACCD_STATEMENT_DATE ,TBRACCD_INV_NUMBER_PAID ,TBRACCD_CURR_CODE ,TBRACCD_EXCHANGE_DIFF ,TBRACCD_FOREIGN_AMOUNT ,TBRACCD_LATE_DCAT_CODE ,TBRACCD_FEED_DATE
                                                                                                        ,TBRACCD_FEED_DOC_CODE ,TBRACCD_ATYP_CODE ,TBRACCD_ATYP_SEQNO ,TBRACCD_CARD_TYPE_VR ,TBRACCD_CARD_EXP_DATE_VR ,TBRACCD_CARD_AUTH_NUMBER_VR ,TBRACCD_CROSSREF_DCAT_CODE ,TBRACCD_ORIG_CHG_IND
                                                                                                        ,TBRACCD_CCRD_CODE ,TBRACCD_MERCHANT_ID ,TBRACCD_TAX_REPT_YEAR ,TBRACCD_TAX_REPT_BOX ,TBRACCD_TAX_AMOUNT ,TBRACCD_TAX_FUTURE_IND ,TBRACCD_DATA_ORIGIN ,TBRACCD_CREATE_SOURCE
                                                                                                        ,TBRACCD_CPDT_IND ,TBRACCD_AIDY_CODE ,TBRACCD_STSP_KEY_SEQUENCE ,TBRACCD_PERIOD ,TBRACCD_SURROGATE_ID ,TBRACCD_VERSION ,TBRACCD_USER_ID ,TBRACCD_VPDI_CODE
                                                                                                From tbraccd 
                                                                                                Where tbraccd_pidm = solicitud.SVRSVPR_PIDM
                                                                                                And TBRACCD_CROSSREF_NUMBER = solicitud.SVRSVPR_PROTOCOL_SEQ_NO ) loop
                                                                
                                                                                                vl_secuencia := vl_secuencia+1;
                                                                
                                                                                               Begin
                                                                                                   --dbms_output.put_line('vl_secuencia:'||vl_secuencia);
                                                                                                   Insert into TBRACCD values ( 
                                                                                                                                            cancela_cargo.TBRACCD_PIDM,
                                                                                                                                            vl_secuencia,
                                                                                                                                            cancela_cargo.TBRACCD_TERM_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_DETAIL_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_USER,
                                                                                                                                            sysdate,
                                                                                                                                            cancela_cargo.TBRACCD_AMOUNT * -1 ,
                                                                                                                                            0,
                                                                                                                                            cancela_cargo.TBRACCD_EFFECTIVE_DATE,
                                                                                                                                            cancela_cargo.TBRACCD_BILL_DATE,
                                                                                                                                            cancela_cargo.TBRACCD_DUE_DATE,
                                                                                                                                            'Cancela Aut '||'SR '||cancela_cargo.TBRACCD_CROSSREF_NUMBER,
                                                                                                                                            cancela_cargo.TBRACCD_RECEIPT_NUMBER,
                                                                                                                                            cancela_cargo.TBRACCD_TRAN_NUMBER,
                                                                                                                                            cancela_cargo.TBRACCD_CROSSREF_PIDM,
                                                                                                                                            cancela_cargo.TBRACCD_CROSSREF_NUMBER,
                                                                                                                                            cancela_cargo.TBRACCD_CROSSREF_DETAIL_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_SRCE_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_ACCT_FEED_IND,
                                                                                                                                            cancela_cargo.TBRACCD_ACTIVITY_DATE,
                                                                                                                                            cancela_cargo.TBRACCD_SESSION_NUMBER,
                                                                                                                                            cancela_cargo.TBRACCD_CSHR_END_DATE,
                                                                                                                                            cancela_cargo.TBRACCD_CRN,
                                                                                                                                            cancela_cargo.TBRACCD_CROSSREF_SRCE_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_LOC_MDT,
                                                                                                                                            cancela_cargo.TBRACCD_LOC_MDT_SEQ,
                                                                                                                                            cancela_cargo.TBRACCD_RATE,
                                                                                                                                            cancela_cargo.TBRACCD_UNITS,
                                                                                                                                            cancela_cargo.TBRACCD_DOCUMENT_NUMBER,
                                                                                                                                            cancela_cargo.TBRACCD_TRANS_DATE,
                                                                                                                                            cancela_cargo.TBRACCD_PAYMENT_ID,
                                                                                                                                            cancela_cargo.TBRACCD_INVOICE_NUMBER,
                                                                                                                                            cancela_cargo.TBRACCD_STATEMENT_DATE,
                                                                                                                                            cancela_cargo.TBRACCD_INV_NUMBER_PAID,
                                                                                                                                            cancela_cargo.TBRACCD_CURR_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_EXCHANGE_DIFF,
                                                                                                                                            cancela_cargo.TBRACCD_FOREIGN_AMOUNT,
                                                                                                                                            cancela_cargo.TBRACCD_LATE_DCAT_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_FEED_DATE,
                                                                                                                                            cancela_cargo.TBRACCD_FEED_DOC_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_ATYP_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_ATYP_SEQNO,
                                                                                                                                            cancela_cargo.TBRACCD_CARD_TYPE_VR,
                                                                                                                                            cancela_cargo.TBRACCD_CARD_EXP_DATE_VR,
                                                                                                                                            cancela_cargo.TBRACCD_CARD_AUTH_NUMBER_VR,
                                                                                                                                            cancela_cargo.TBRACCD_CROSSREF_DCAT_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_ORIG_CHG_IND,
                                                                                                                                            cancela_cargo.TBRACCD_CCRD_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_MERCHANT_ID,
                                                                                                                                            cancela_cargo.TBRACCD_TAX_REPT_YEAR,
                                                                                                                                            cancela_cargo.TBRACCD_TAX_REPT_BOX,
                                                                                                                                            cancela_cargo.TBRACCD_TAX_AMOUNT,
                                                                                                                                            cancela_cargo.TBRACCD_TAX_FUTURE_IND,
                                                                                                                                            cancela_cargo.TBRACCD_DATA_ORIGIN,
                                                                                                                                            cancela_cargo.TBRACCD_CREATE_SOURCE,
                                                                                                                                            cancela_cargo.TBRACCD_CPDT_IND,
                                                                                                                                            cancela_cargo.TBRACCD_AIDY_CODE,
                                                                                                                                            cancela_cargo.TBRACCD_STSP_KEY_SEQUENCE,
                                                                                                                                            cancela_cargo.TBRACCD_PERIOD,
                                                                                                                                            null,
                                                                                                                                            null,
                                                                                                                                            cancela_cargo.TBRACCD_USER_ID,
                                                                                                                                            null ) ;
                                                                                               End;                                      
                                                                                                                                    
                                                                                                Begin
                                                                                                        Update tbraccd
                                                                                                        Set TBRACCD_BALANCE = 0
                                                                                                        Where TBRACCD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                                                                        And TBRACCD_CROSSREF_NUMBER = cancela_cargo.TBRACCD_CROSSREF_NUMBER
                                                                                                        And TBRACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;
                                                                                                                                               
                                                                                                Exception
                                                                                                When Others then 
                                                                                                   --dbms_output.put_line ('error update ' ||sqlerrm);        
                                                                                                   null;                                    
                                                                                                End;     
                                                   
                                                                                                Begin
                                                   
                                                                                            --dbms_output.put_line ('Valores Impuetos ' ||cancela_cargo.TBRACCD_PIDM ||'*'|| cancela_cargo.TBRACCD_DETAIL_CODE||'*'||cancela_cargo.TBRACCD_TRAN_NUMBER);             
                                                                                                   Update TVRTAXD
                                                                                                        Set TVRTAXD_TAX_AMOUNT = 0
                                                                                                    Where TVRTAXD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                                                                    And TVRTAXD_ACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;
                                                                                                Exception
                                                                                                When Others then
                                                                                                   NULL; 
                                                                                                   --dbms_output.put_line ('error update impuesto ' ||sqlerrm);                                            
                                                                                                End;     

                                                                End Loop cancela_cargo;
                               
                                                       End if;     
                                                       
                                                 End if;

                                   End loop solicitud;
                     
                    End loop servicio;
                    
                    commit;

END P_CANCELA_CARGO_AUTOMATICO;




PROCEDURE P_CANCELA_CARGO_DIRECTO (p_pidm in number, p_solicitud in number)  IS

/******************************************************************************
   NAME:       P_CANCELA_CARGO
   PURPOSE:    Cancelar los cargos de las solicitudes del SSB que son canceladas de forma directa por el usuario 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/11/2015   vramirlo       1. Created this procedure.

  *****************************************************************************/


vl_existe number;
vl_valida number;
vl_secuencia number;
vl_desaplica number;


BEGIN

  ----- Validacion que la solicitud fue cancelada----
  
  --dbms_output.put_line ('Entra al proceso');

        For solicitud in (select SVRSVPR_PROTOCOL_SEQ_NO, SVRSVPR_PIDM
                                 from SVRSVPR
                                 Where SVRSVPR_PROTOCOL_SEQ_NO = nvl(p_solicitud, SVRSVPR_PROTOCOL_SEQ_NO)
                                 And SVRSVPR_PIDM = nvl (p_pidm , SVRSVPR_PIDM)
                                And SVRSVPR_SRVS_CODE  in ('CA', 'AN')
                     ) loop
                     
                     ----- En caso que la solicitud este cancelada se buscaran los codigos de detalle que fueron creados en el estado de de cuenta como cargos 
                    vl_existe :=0;
                    vl_valida := 0; 
                    vl_secuencia :=0;
 
 --dbms_output.put_line ('VALIDA 00' ||solicitud.SVRSVPR_PROTOCOL_SEQ_NO ||'*'||  solicitud.SVRSVPR_PIDM);   

                    For valida_cargo in (select TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_DETAIL_CODE, TBRACCD_ENTRY_DATE,
                                                            TBRACCD_AMOUNT, TBRACCD_BALANCE, TBRACCD_EFFECTIVE_DATE
                                                    From tbraccd , tbbdetc
                                                    Where tbraccd_pidm = solicitud.SVRSVPR_PIDM
                                                    And TBRACCD_CROSSREF_NUMBER = solicitud.SVRSVPR_PROTOCOL_SEQ_NO 
                                                    And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                    And TBBDETC_TYPE_IND = 'C'
                                                    ) loop
                                                   
                    --dbms_output.put_line ('VALIDA 01' ||valida_cargo.TBRACCD_AMOUNT ||'*'||  valida_cargo.TBRACCD_BALANCE);           
                    
                                         
                            If  valida_cargo.TBRACCD_AMOUNT  =   valida_cargo.TBRACCD_BALANCE then
                                 --dbms_output.put_line ('Entra 1');                           
                            
                                vl_valida := 1;
                                  Begin 
                                    Select count(1)
                                     Into vl_existe
                                    from tbrappl 
                                    Where TBRAPPL_PIDM = valida_cargo.TBRACCD_PIDM
                                    And TBRAPPL_CHG_TRAN_NUMBER = valida_cargo.TBRACCD_TRAN_NUMBER
                                    And TBRAPPL_REAPPL_IND is null;
                                Exception 
                                    When Others then 
                                       vl_existe :=0;
                                End;
                                
                            End if;                    
                                                   
                    End loop valida_cargo;
                      
                  dbms_output.put_line ('Evalua los IF' || vl_valida ||'*'||vl_existe);                     
                    
                    If  vl_valida = 1 and  vl_existe =0 then 
                         --   dbms_output.put_line ('Entra 2');
                            Begin 
                                select max (TBRACCD_TRAN_NUMBER)
                                Into vl_secuencia
                                from tbraccd
                                where tbraccd_pidm = solicitud.SVRSVPR_PIDM;
                            Exception
                            When Others then 
                               vl_secuencia :=0;
                            End;
                            
                                                
                            For cancela_cargo in (select TBRACCD_PIDM
                                                                    ,TBRACCD_TRAN_NUMBER,TBRACCD_TERM_CODE,TBRACCD_DETAIL_CODE ,TBRACCD_USER ,TBRACCD_ENTRY_DATE ,TBRACCD_AMOUNT, TBRACCD_BALANCE
                                                                    ,TBRACCD_EFFECTIVE_DATE, TBRACCD_BILL_DATE ,TBRACCD_DUE_DATE ,TBRACCD_DESC ,TBRACCD_RECEIPT_NUMBER ,TBRACCD_TRAN_NUMBER_PAID ,TBRACCD_CROSSREF_PIDM
                                                                    ,TBRACCD_CROSSREF_NUMBER, TBRACCD_CROSSREF_DETAIL_CODE ,TBRACCD_SRCE_CODE ,TBRACCD_ACCT_FEED_IND ,TBRACCD_ACTIVITY_DATE ,TBRACCD_SESSION_NUMBER ,TBRACCD_CSHR_END_DATE
                                                                    ,TBRACCD_CRN, TBRACCD_CROSSREF_SRCE_CODE ,TBRACCD_LOC_MDT ,TBRACCD_LOC_MDT_SEQ ,TBRACCD_RATE ,TBRACCD_UNITS ,TBRACCD_DOCUMENT_NUMBER ,TBRACCD_TRANS_DATE ,TBRACCD_PAYMENT_ID
                                                                    ,TBRACCD_INVOICE_NUMBER ,TBRACCD_STATEMENT_DATE ,TBRACCD_INV_NUMBER_PAID ,TBRACCD_CURR_CODE ,TBRACCD_EXCHANGE_DIFF ,TBRACCD_FOREIGN_AMOUNT ,TBRACCD_LATE_DCAT_CODE ,TBRACCD_FEED_DATE
                                                                    ,TBRACCD_FEED_DOC_CODE ,TBRACCD_ATYP_CODE ,TBRACCD_ATYP_SEQNO ,TBRACCD_CARD_TYPE_VR ,TBRACCD_CARD_EXP_DATE_VR ,TBRACCD_CARD_AUTH_NUMBER_VR ,TBRACCD_CROSSREF_DCAT_CODE ,TBRACCD_ORIG_CHG_IND
                                                                    ,TBRACCD_CCRD_CODE ,TBRACCD_MERCHANT_ID ,TBRACCD_TAX_REPT_YEAR ,TBRACCD_TAX_REPT_BOX ,TBRACCD_TAX_AMOUNT ,TBRACCD_TAX_FUTURE_IND ,TBRACCD_DATA_ORIGIN ,TBRACCD_CREATE_SOURCE
                                                                    ,TBRACCD_CPDT_IND ,TBRACCD_AIDY_CODE ,TBRACCD_STSP_KEY_SEQUENCE ,TBRACCD_PERIOD ,TBRACCD_SURROGATE_ID ,TBRACCD_VERSION ,TBRACCD_USER_ID ,TBRACCD_VPDI_CODE
                                                            From tbraccd , TBBDETC
                                                            Where tbraccd_pidm = solicitud.SVRSVPR_PIDM
                                                            And TBRACCD_CROSSREF_NUMBER = solicitud.SVRSVPR_PROTOCOL_SEQ_NO 
                                                            And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                           And TBBDETC_TYPE_IND = 'C'
                                                            
                                                            ) loop
                            
                                                            vl_secuencia := vl_secuencia+1;
                            
                                                    Begin
                                                       Insert into TBRACCD values ( 
                                                                                                cancela_cargo.TBRACCD_PIDM,
                                                                                                vl_secuencia,
                                                                                                cancela_cargo.TBRACCD_TERM_CODE,
                                                                                                cancela_cargo.TBRACCD_DETAIL_CODE,
                                                                                                cancela_cargo.TBRACCD_USER,
                                                                                                sysdate,
                                                                                                cancela_cargo.TBRACCD_AMOUNT * -1,
                                                                                                0,
                                                                                                cancela_cargo.TBRACCD_EFFECTIVE_DATE,
                                                                                                cancela_cargo.TBRACCD_BILL_DATE,
                                                                                                cancela_cargo.TBRACCD_DUE_DATE,
                                                                                                 'Cancelacion '||'SR '||cancela_cargo.TBRACCD_CROSSREF_NUMBER,
                                                                                                cancela_cargo.TBRACCD_RECEIPT_NUMBER,
                                                                                                cancela_cargo.TBRACCD_TRAN_NUMBER,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_PIDM,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_NUMBER,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_DETAIL_CODE,
                                                                                                cancela_cargo.TBRACCD_SRCE_CODE,
                                                                                                cancela_cargo.TBRACCD_ACCT_FEED_IND,
                                                                                                cancela_cargo.TBRACCD_ACTIVITY_DATE,
                                                                                                cancela_cargo.TBRACCD_SESSION_NUMBER,
                                                                                                cancela_cargo.TBRACCD_CSHR_END_DATE,
                                                                                                cancela_cargo.TBRACCD_CRN,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_SRCE_CODE,
                                                                                                cancela_cargo.TBRACCD_LOC_MDT,
                                                                                                cancela_cargo.TBRACCD_LOC_MDT_SEQ,
                                                                                                cancela_cargo.TBRACCD_RATE,
                                                                                                cancela_cargo.TBRACCD_UNITS,
                                                                                                cancela_cargo.TBRACCD_DOCUMENT_NUMBER,
                                                                                                cancela_cargo.TBRACCD_TRANS_DATE,
                                                                                                cancela_cargo.TBRACCD_PAYMENT_ID,
                                                                                                cancela_cargo.TBRACCD_INVOICE_NUMBER,
                                                                                                cancela_cargo.TBRACCD_STATEMENT_DATE,
                                                                                                cancela_cargo.TBRACCD_INV_NUMBER_PAID,
                                                                                                cancela_cargo.TBRACCD_CURR_CODE,
                                                                                                cancela_cargo.TBRACCD_EXCHANGE_DIFF,
                                                                                                cancela_cargo.TBRACCD_FOREIGN_AMOUNT,
                                                                                                cancela_cargo.TBRACCD_LATE_DCAT_CODE,
                                                                                                cancela_cargo.TBRACCD_FEED_DATE,
                                                                                                cancela_cargo.TBRACCD_FEED_DOC_CODE,
                                                                                                cancela_cargo.TBRACCD_ATYP_CODE,
                                                                                                cancela_cargo.TBRACCD_ATYP_SEQNO,
                                                                                                cancela_cargo.TBRACCD_CARD_TYPE_VR,
                                                                                                cancela_cargo.TBRACCD_CARD_EXP_DATE_VR,
                                                                                                cancela_cargo.TBRACCD_CARD_AUTH_NUMBER_VR,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_DCAT_CODE,
                                                                                                cancela_cargo.TBRACCD_ORIG_CHG_IND,
                                                                                                cancela_cargo.TBRACCD_CCRD_CODE,
                                                                                                cancela_cargo.TBRACCD_MERCHANT_ID,
                                                                                                cancela_cargo.TBRACCD_TAX_REPT_YEAR,
                                                                                                cancela_cargo.TBRACCD_TAX_REPT_BOX,
                                                                                                cancela_cargo.TBRACCD_TAX_AMOUNT,
                                                                                                cancela_cargo.TBRACCD_TAX_FUTURE_IND,
                                                                                                cancela_cargo.TBRACCD_DATA_ORIGIN,
                                                                                                cancela_cargo.TBRACCD_CREATE_SOURCE,
                                                                                                cancela_cargo.TBRACCD_CPDT_IND,
                                                                                                cancela_cargo.TBRACCD_AIDY_CODE,
                                                                                                cancela_cargo.TBRACCD_STSP_KEY_SEQUENCE,
                                                                                                cancela_cargo.TBRACCD_PERIOD,
                                                                                                null,
                                                                                                null,
                                                                                                cancela_cargo.TBRACCD_USER_ID,
                                                                                                null ) ;
                                                                                                
                                                    Exception
                                                    When Others then 
                                                       dbms_output.put_line ('error insert ' ||sqlerrm); 
                                                       NULL;                                           
                                                    End;             
                                                                                                
                                                    Begin
                                                            Update tbraccd
                                                            Set TBRACCD_BALANCE = 0
                                                            Where TBRACCD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                            And TBRACCD_CROSSREF_NUMBER = cancela_cargo.TBRACCD_CROSSREF_NUMBER
                                                            And TBRACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;
                                                            
                                                            Update TVRACCD
                                                            set TVRACCD_BALANCE = 0
                                                            Where TVRACCD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                            And TVRACCD_CROSSREF_NUMBER = cancela_cargo.TBRACCD_CROSSREF_NUMBER
                                                            And TVRACCD_ACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;
                                                                                                   
                                                    Exception
                                                    When Others then 
                                                       dbms_output.put_line ('error update ' ||sqlerrm);       
                                                       NULL;                                     
                                                    End;     
       
                                                    Begin
       
                                                dbms_output.put_line ('Valores Impuetos ' ||cancela_cargo.TBRACCD_PIDM ||'*'|| cancela_cargo.TBRACCD_DETAIL_CODE||'*'||cancela_cargo.TBRACCD_TRAN_NUMBER);             
                                                       Update TVRTAXD
                                                            Set TVRTAXD_TAX_AMOUNT = 0
                                                        Where TVRTAXD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                        And TVRTAXD_ACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;
                                                     Exception
                                                    When Others then 
                                                       dbms_output.put_line ('error update impuesto ' ||sqlerrm);    
                                                       null;                                        
                                                    End;     
      
      
                                                                                               
                            End Loop cancela_cargo;
                            
                            
                      dbms_output.put_line ('Evalua los IF 2' || vl_valida ||'*'||vl_existe);                     
                             
                    ElsIf  vl_valida = 0 and  vl_existe =0 then       ----->>>> Cancelara los pagos realizados por descuentos unicamente.   
                    
                              P_LIBERA_PAGO_DIRECTO (solicitud.SVRSVPR_PIDM, solicitud.SVRSVPR_PROTOCOL_SEQ_NO);
                    
       
                    End if;


-----------------------------------------------------------------------------------
------------------------------------ Cancela Pagos -----------------------------
-----------------------------------------------------------------------------------

                     ----- En caso que la solicitud este cancelada se buscaran los codigos de detalle que fueron creados en el estado de de cuenta como cargos 
                    vl_existe :=0;
                    vl_valida := 0; 
                    vl_secuencia :=0;
                    
                    For valida_pago in (select TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_DETAIL_CODE, TBRACCD_ENTRY_DATE,
                                                            TBRACCD_AMOUNT, TBRACCD_BALANCE * -1 TBRACCD_BALANCE, TBRACCD_EFFECTIVE_DATE
                                                    From tbraccd , tbbdetc
                                                    Where tbraccd_pidm = solicitud.SVRSVPR_PIDM
                                                    And TBRACCD_CROSSREF_NUMBER = solicitud.SVRSVPR_PROTOCOL_SEQ_NO 
                                                    And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                    And TBBDETC_TYPE_IND = 'P'
                                                    
                                                    ) loop
                                                   
                                                   --dbms_output.put_line ('Entra 05 Pagos'|| valida_pago.TBRACCD_AMOUNT ||'*' ||  valida_pago.TBRACCD_BALANCE );           
                                                   
                            If  valida_pago.TBRACCD_AMOUNT  =   valida_pago.TBRACCD_BALANCE then
                                vl_valida := 1;
                                  Begin 
                                    Select count(1)
                                     Into vl_existe
                                    from tbrappl 
                                    Where TBRAPPL_PIDM = valida_pago.TBRACCD_PIDM
                                    And TBRAPPL_CHG_TRAN_NUMBER = valida_pago.TBRACCD_TRAN_NUMBER
                                    And TBRAPPL_REAPPL_IND is null;
                                Exception 
                                    When Others then 
                                       vl_existe :=0;
                                End;
                                
                            End if;                    
                                                   
                    End loop;
                      
                    If  vl_valida = 1 and  vl_existe =0 then 
                     --dbms_output.put_line ('Entra 06 Pagos'|| vl_valida ||'*' ||  vl_existe ); 
                        Begin 
                            select max (TBRACCD_TRAN_NUMBER)
                            Into vl_secuencia
                            from tbraccd
                            where tbraccd_pidm = solicitud.SVRSVPR_PIDM;
                        Exception
                        When Others then 
                           vl_secuencia :=0;
                        End;
                        
                                            
                        For cancela_pago in (select TBRACCD_PIDM
                                                                ,TBRACCD_TRAN_NUMBER,TBRACCD_TERM_CODE,TBRACCD_DETAIL_CODE ,TBRACCD_USER ,TBRACCD_ENTRY_DATE ,TBRACCD_AMOUNT, TBRACCD_BALANCE
                                                                ,TBRACCD_EFFECTIVE_DATE, TBRACCD_BILL_DATE ,TBRACCD_DUE_DATE ,TBRACCD_DESC ,TBRACCD_RECEIPT_NUMBER ,TBRACCD_TRAN_NUMBER_PAID ,TBRACCD_CROSSREF_PIDM
                                                                ,TBRACCD_CROSSREF_NUMBER, TBRACCD_CROSSREF_DETAIL_CODE ,TBRACCD_SRCE_CODE ,TBRACCD_ACCT_FEED_IND ,TBRACCD_ACTIVITY_DATE ,TBRACCD_SESSION_NUMBER ,TBRACCD_CSHR_END_DATE
                                                                ,TBRACCD_CRN, TBRACCD_CROSSREF_SRCE_CODE ,TBRACCD_LOC_MDT ,TBRACCD_LOC_MDT_SEQ ,TBRACCD_RATE ,TBRACCD_UNITS ,TBRACCD_DOCUMENT_NUMBER ,TBRACCD_TRANS_DATE ,TBRACCD_PAYMENT_ID
                                                                ,TBRACCD_INVOICE_NUMBER ,TBRACCD_STATEMENT_DATE ,TBRACCD_INV_NUMBER_PAID ,TBRACCD_CURR_CODE ,TBRACCD_EXCHANGE_DIFF ,TBRACCD_FOREIGN_AMOUNT ,TBRACCD_LATE_DCAT_CODE ,TBRACCD_FEED_DATE
                                                                ,TBRACCD_FEED_DOC_CODE ,TBRACCD_ATYP_CODE ,TBRACCD_ATYP_SEQNO ,TBRACCD_CARD_TYPE_VR ,TBRACCD_CARD_EXP_DATE_VR ,TBRACCD_CARD_AUTH_NUMBER_VR ,TBRACCD_CROSSREF_DCAT_CODE ,TBRACCD_ORIG_CHG_IND
                                                                ,TBRACCD_CCRD_CODE ,TBRACCD_MERCHANT_ID ,TBRACCD_TAX_REPT_YEAR ,TBRACCD_TAX_REPT_BOX ,TBRACCD_TAX_AMOUNT ,TBRACCD_TAX_FUTURE_IND ,TBRACCD_DATA_ORIGIN ,TBRACCD_CREATE_SOURCE
                                                                ,TBRACCD_CPDT_IND ,TBRACCD_AIDY_CODE ,TBRACCD_STSP_KEY_SEQUENCE ,TBRACCD_PERIOD ,TBRACCD_SURROGATE_ID ,TBRACCD_VERSION ,TBRACCD_USER_ID ,TBRACCD_VPDI_CODE
                                                        From tbraccd , TBBDETC
                                                        Where tbraccd_pidm = solicitud.SVRSVPR_PIDM
                                                        And TBRACCD_CROSSREF_NUMBER = solicitud.SVRSVPR_PROTOCOL_SEQ_NO 
                                                        And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                       And TBBDETC_TYPE_IND = 'P'
                                                        
                                                        ) loop
                        
                                                        vl_secuencia := vl_secuencia+1;
                        
                                
                                        Begin
                                                   Insert into TBRACCD values ( 
                                                                                            cancela_pago.TBRACCD_PIDM,
                                                                                            vl_secuencia,
                                                                                            cancela_pago.TBRACCD_TERM_CODE,
                                                                                            cancela_pago.TBRACCD_DETAIL_CODE,
                                                                                            cancela_pago.TBRACCD_USER,
                                                                                            sysdate,
                                                                                            cancela_pago.TBRACCD_AMOUNT * -1,
                                                                                            0,
                                                                                            cancela_pago.TBRACCD_EFFECTIVE_DATE,
                                                                                            cancela_pago.TBRACCD_BILL_DATE,
                                                                                            cancela_pago.TBRACCD_DUE_DATE,
                                                                                             'Cancelacion '||'SR '||cancela_pago.TBRACCD_CROSSREF_NUMBER,
                                                                                            cancela_pago.TBRACCD_RECEIPT_NUMBER,
                                                                                            cancela_pago.TBRACCD_TRAN_NUMBER,
                                                                                            cancela_pago.TBRACCD_CROSSREF_PIDM,
                                                                                            cancela_pago.TBRACCD_CROSSREF_NUMBER,
                                                                                            cancela_pago.TBRACCD_CROSSREF_DETAIL_CODE,
                                                                                            cancela_pago.TBRACCD_SRCE_CODE,
                                                                                            cancela_pago.TBRACCD_ACCT_FEED_IND,
                                                                                            cancela_pago.TBRACCD_ACTIVITY_DATE,
                                                                                            cancela_pago.TBRACCD_SESSION_NUMBER,
                                                                                            cancela_pago.TBRACCD_CSHR_END_DATE,
                                                                                            cancela_pago.TBRACCD_CRN,
                                                                                            cancela_pago.TBRACCD_CROSSREF_SRCE_CODE,
                                                                                            cancela_pago.TBRACCD_LOC_MDT,
                                                                                            cancela_pago.TBRACCD_LOC_MDT_SEQ,
                                                                                            cancela_pago.TBRACCD_RATE,
                                                                                            cancela_pago.TBRACCD_UNITS,
                                                                                            cancela_pago.TBRACCD_DOCUMENT_NUMBER,
                                                                                            cancela_pago.TBRACCD_TRANS_DATE,
                                                                                            cancela_pago.TBRACCD_PAYMENT_ID,
                                                                                            cancela_pago.TBRACCD_INVOICE_NUMBER,
                                                                                            cancela_pago.TBRACCD_STATEMENT_DATE,
                                                                                            cancela_pago.TBRACCD_INV_NUMBER_PAID,
                                                                                            cancela_pago.TBRACCD_CURR_CODE,
                                                                                            cancela_pago.TBRACCD_EXCHANGE_DIFF,
                                                                                            cancela_pago.TBRACCD_FOREIGN_AMOUNT,
                                                                                            cancela_pago.TBRACCD_LATE_DCAT_CODE,
                                                                                            cancela_pago.TBRACCD_FEED_DATE,
                                                                                            cancela_pago.TBRACCD_FEED_DOC_CODE,
                                                                                            cancela_pago.TBRACCD_ATYP_CODE,
                                                                                            cancela_pago.TBRACCD_ATYP_SEQNO,
                                                                                            cancela_pago.TBRACCD_CARD_TYPE_VR,
                                                                                            cancela_pago.TBRACCD_CARD_EXP_DATE_VR,
                                                                                            cancela_pago.TBRACCD_CARD_AUTH_NUMBER_VR,
                                                                                            cancela_pago.TBRACCD_CROSSREF_DCAT_CODE,
                                                                                            cancela_pago.TBRACCD_ORIG_CHG_IND,
                                                                                            cancela_pago.TBRACCD_CCRD_CODE,
                                                                                            cancela_pago.TBRACCD_MERCHANT_ID,
                                                                                            cancela_pago.TBRACCD_TAX_REPT_YEAR,
                                                                                            cancela_pago.TBRACCD_TAX_REPT_BOX,
                                                                                            cancela_pago.TBRACCD_TAX_AMOUNT,
                                                                                            cancela_pago.TBRACCD_TAX_FUTURE_IND,
                                                                                            cancela_pago.TBRACCD_DATA_ORIGIN,
                                                                                            cancela_pago.TBRACCD_CREATE_SOURCE,
                                                                                            cancela_pago.TBRACCD_CPDT_IND,
                                                                                            cancela_pago.TBRACCD_AIDY_CODE,
                                                                                            cancela_pago.TBRACCD_STSP_KEY_SEQUENCE,
                                                                                            cancela_pago.TBRACCD_PERIOD,
                                                                                            null,
                                                                                            null,
                                                                                            cancela_pago.TBRACCD_USER_ID,
                                                                                            null ) ;
                                        Exception
                                        When Others then 
                                            --dbms_output.put_line ('Entra 07 Pagos'|| sqlerrm );                                                     
                                            null;
                                        End;
                                        

                                       Begin
                                                Update tbraccd
                                                Set TBRACCD_BALANCE = 0
                                                Where TBRACCD_PIDM = cancela_pago.TBRACCD_PIDM
                                                And TBRACCD_CROSSREF_NUMBER = cancela_pago.TBRACCD_CROSSREF_NUMBER
                                                And TBRACCD_TRAN_NUMBER = cancela_pago.TBRACCD_TRAN_NUMBER;
                                                
                                                
                                                Update TVRACCD
                                                set TVRACCD_BALANCE = 0
                                                Where TVRACCD_PIDM = cancela_pago.TBRACCD_PIDM
                                                And TVRACCD_CROSSREF_NUMBER = cancela_pago.TBRACCD_CROSSREF_NUMBER
                                                And TVRACCD_ACCD_TRAN_NUMBER = cancela_pago.TBRACCD_TRAN_NUMBER;
                                                                                                                                                   
                                                                                               
                                       Exception
                                        When Others then 
                                           --dbms_output.put_line ('error update ' ||sqlerrm);    
                                           null;                                        
                                       End;     
                                        
                        End Loop;
   
                End if;






       End loop;
                     
 

END P_CANCELA_CARGO_DIRECTO;


  Procedure  P_LIBERA_PAGO_DIRECTO (p_pidm in number, p_solicitud in number)  IS 

v_pago number:=0;

vl_existe number;
vl_valida number;
vl_secuencia number;
vl_val_sol number;



    Begin
                            v_pago:=0;                    
        
                           For pago in (select TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_CROSSREF_NUMBER, TBRAPPL_PAY_TRAN_NUMBER
                                                from tbraccd , tbbdetc, tbrappl
                                               Where TBRACCD_PIDM   = p_pidm
                                               And   TBRACCD_CROSSREF_NUMBER  =  p_solicitud
                                               --And TBRACCD_DETAIL_CODE in (select ZSTPARA_PARAM_VALOR from zstpara where ZSTPARA_MAPA_ID = 'DESCUENTO')
                                               And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                               And tbraccd_pidm = TBRAPPL_PIDM
                                               And TBRAPPL_CHG_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                                              And TBRAPPL_REAPPL_IND is null
                                               order by 3 desc ) loop
                                               v_pago :=1;
                                      For pagoppl in (select TBRAPPL_PIDM, TBRAPPL_PAY_TRAN_NUMBER, TBRAPPL_CHG_TRAN_NUMBER, TBRAPPL_AMOUNT, TBRAPPL_DIRECT_PAY_TYPE
                                                            from tbrappl 
                                                            Where TBRAPPL_PIDM = pago.TBRACCD_PIDM
                                                            And TBRAPPL_PAY_TRAN_NUMBER = pago.TBRAPPL_PAY_TRAN_NUMBER
                                                            And TBRAPPL_REAPPL_IND is null )  loop
                                                            
                                                            gb_common.p_set_context('TB_RECEIVABLE','PROCESS','APPLPMNT-FORCE','N');

                                                           tv_application.p_unapply_by_tran_number( p_pidm               => pagoppl.TBRAPPL_PIDM,
                                                                                                                          p_pay_tran_number    => pagoppl.TBRAPPL_PAY_TRAN_NUMBER,
                                                                                                                          p_unapply_direct_pay => pagoppl.TBRAPPL_DIRECT_PAY_TYPE);                                                            
                                                            
                                      End Loop pagoppl;
                                                            
                             End Loop pago;
                             
                             
                             
                                                  ----- En caso que la solicitud este cancelada se buscaran los codigos de detalle que fueron creados en el estado de de cuenta como cargos 
                    vl_existe :=0;
                    vl_valida := 0; 
                    vl_secuencia :=0;
                    For valida_cargo in (select TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_DETAIL_CODE, TBRACCD_ENTRY_DATE,
                                                            TBRACCD_AMOUNT, TBRACCD_BALANCE, TBRACCD_EFFECTIVE_DATE
                                                    From tbraccd , tbbdetc
                                                    Where tbraccd_pidm = p_pidm
                                                    And TBRACCD_CROSSREF_NUMBER = p_solicitud
                                                    And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                    And TBBDETC_TYPE_IND = 'C'
                                                    ) loop
                                                   
                    --dbms_output.put_line ('Entra 01');           
                    
                                         
                            If  valida_cargo.TBRACCD_AMOUNT  =   valida_cargo.TBRACCD_BALANCE then
                                -- dbms_output.put_line ('Entra 1');                           
                            
                                vl_valida := 1;
                                  Begin 
                                    Select count(1)
                                     Into vl_existe
                                    from tbrappl 
                                    Where TBRAPPL_PIDM = valida_cargo.TBRACCD_PIDM
                                    And TBRAPPL_CHG_TRAN_NUMBER = valida_cargo.TBRACCD_TRAN_NUMBER
                                    And TBRAPPL_REAPPL_IND is null;
                                Exception 
                                    When Others then 
                                       vl_existe :=0;
                                End;
                                
                            End if;                    
                                                   
                    End loop valida_cargo;
                      
                    If  vl_valida = 1 and  vl_existe =0 then 
                            --dbms_output.put_line ('Entra 2');
                            Begin 
                                select max (TBRACCD_TRAN_NUMBER)
                                Into vl_secuencia
                                from tbraccd
                                where tbraccd_pidm = p_pidm;
                            Exception
                            When Others then 
                               vl_secuencia :=0;
                            End;
                            
                                                
                            For cancela_cargo in (select TBRACCD_PIDM
                                                                    ,TBRACCD_TRAN_NUMBER,TBRACCD_TERM_CODE,TBRACCD_DETAIL_CODE ,TBRACCD_USER ,TBRACCD_ENTRY_DATE ,TBRACCD_AMOUNT, TBRACCD_BALANCE
                                                                    ,TBRACCD_EFFECTIVE_DATE, TBRACCD_BILL_DATE ,TBRACCD_DUE_DATE ,TBRACCD_DESC ,TBRACCD_RECEIPT_NUMBER ,TBRACCD_TRAN_NUMBER_PAID ,TBRACCD_CROSSREF_PIDM
                                                                    ,TBRACCD_CROSSREF_NUMBER, TBRACCD_CROSSREF_DETAIL_CODE ,TBRACCD_SRCE_CODE ,TBRACCD_ACCT_FEED_IND ,TBRACCD_ACTIVITY_DATE ,TBRACCD_SESSION_NUMBER ,TBRACCD_CSHR_END_DATE
                                                                    ,TBRACCD_CRN, TBRACCD_CROSSREF_SRCE_CODE ,TBRACCD_LOC_MDT ,TBRACCD_LOC_MDT_SEQ ,TBRACCD_RATE ,TBRACCD_UNITS ,TBRACCD_DOCUMENT_NUMBER ,TBRACCD_TRANS_DATE ,TBRACCD_PAYMENT_ID
                                                                    ,TBRACCD_INVOICE_NUMBER ,TBRACCD_STATEMENT_DATE ,TBRACCD_INV_NUMBER_PAID ,TBRACCD_CURR_CODE ,TBRACCD_EXCHANGE_DIFF ,TBRACCD_FOREIGN_AMOUNT ,TBRACCD_LATE_DCAT_CODE ,TBRACCD_FEED_DATE
                                                                    ,TBRACCD_FEED_DOC_CODE ,TBRACCD_ATYP_CODE ,TBRACCD_ATYP_SEQNO ,TBRACCD_CARD_TYPE_VR ,TBRACCD_CARD_EXP_DATE_VR ,TBRACCD_CARD_AUTH_NUMBER_VR ,TBRACCD_CROSSREF_DCAT_CODE ,TBRACCD_ORIG_CHG_IND
                                                                    ,TBRACCD_CCRD_CODE ,TBRACCD_MERCHANT_ID ,TBRACCD_TAX_REPT_YEAR ,TBRACCD_TAX_REPT_BOX ,TBRACCD_TAX_AMOUNT ,TBRACCD_TAX_FUTURE_IND ,TBRACCD_DATA_ORIGIN ,TBRACCD_CREATE_SOURCE
                                                                    ,TBRACCD_CPDT_IND ,TBRACCD_AIDY_CODE ,TBRACCD_STSP_KEY_SEQUENCE ,TBRACCD_PERIOD ,TBRACCD_SURROGATE_ID ,TBRACCD_VERSION ,TBRACCD_USER_ID ,TBRACCD_VPDI_CODE
                                                            From tbraccd , TBBDETC
                                                            Where tbraccd_pidm = p_pidm
                                                            And TBRACCD_CROSSREF_NUMBER = p_solicitud
                                                            And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                           And TBBDETC_TYPE_IND = 'C'
                                                            
                                                            ) loop
                            
                                                            vl_secuencia := vl_secuencia+1;
                            
                                                    Begin
                                                       Insert into TBRACCD values ( 
                                                                                                cancela_cargo.TBRACCD_PIDM,
                                                                                                vl_secuencia,
                                                                                                cancela_cargo.TBRACCD_TERM_CODE,
                                                                                                cancela_cargo.TBRACCD_DETAIL_CODE,
                                                                                                cancela_cargo.TBRACCD_USER,
                                                                                                sysdate,
                                                                                                cancela_cargo.TBRACCD_AMOUNT * -1,
                                                                                                0,
                                                                                                cancela_cargo.TBRACCD_EFFECTIVE_DATE,
                                                                                                cancela_cargo.TBRACCD_BILL_DATE,
                                                                                                cancela_cargo.TBRACCD_DUE_DATE,
                                                                                                 'Cancelacion '||'SR '||cancela_cargo.TBRACCD_CROSSREF_NUMBER,
                                                                                                cancela_cargo.TBRACCD_RECEIPT_NUMBER,
                                                                                                cancela_cargo.TBRACCD_TRAN_NUMBER,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_PIDM,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_NUMBER,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_DETAIL_CODE,
                                                                                                cancela_cargo.TBRACCD_SRCE_CODE,
                                                                                                cancela_cargo.TBRACCD_ACCT_FEED_IND,
                                                                                                cancela_cargo.TBRACCD_ACTIVITY_DATE,
                                                                                                cancela_cargo.TBRACCD_SESSION_NUMBER,
                                                                                                cancela_cargo.TBRACCD_CSHR_END_DATE,
                                                                                                cancela_cargo.TBRACCD_CRN,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_SRCE_CODE,
                                                                                                cancela_cargo.TBRACCD_LOC_MDT,
                                                                                                cancela_cargo.TBRACCD_LOC_MDT_SEQ,
                                                                                                cancela_cargo.TBRACCD_RATE,
                                                                                                cancela_cargo.TBRACCD_UNITS,
                                                                                                cancela_cargo.TBRACCD_DOCUMENT_NUMBER,
                                                                                                cancela_cargo.TBRACCD_TRANS_DATE,
                                                                                                cancela_cargo.TBRACCD_PAYMENT_ID,
                                                                                                cancela_cargo.TBRACCD_INVOICE_NUMBER,
                                                                                                cancela_cargo.TBRACCD_STATEMENT_DATE,
                                                                                                cancela_cargo.TBRACCD_INV_NUMBER_PAID,
                                                                                                cancela_cargo.TBRACCD_CURR_CODE,
                                                                                                cancela_cargo.TBRACCD_EXCHANGE_DIFF,
                                                                                                cancela_cargo.TBRACCD_FOREIGN_AMOUNT,
                                                                                                cancela_cargo.TBRACCD_LATE_DCAT_CODE,
                                                                                                cancela_cargo.TBRACCD_FEED_DATE,
                                                                                                cancela_cargo.TBRACCD_FEED_DOC_CODE,
                                                                                                cancela_cargo.TBRACCD_ATYP_CODE,
                                                                                                cancela_cargo.TBRACCD_ATYP_SEQNO,
                                                                                                cancela_cargo.TBRACCD_CARD_TYPE_VR,
                                                                                                cancela_cargo.TBRACCD_CARD_EXP_DATE_VR,
                                                                                                cancela_cargo.TBRACCD_CARD_AUTH_NUMBER_VR,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_DCAT_CODE,
                                                                                                cancela_cargo.TBRACCD_ORIG_CHG_IND,
                                                                                                cancela_cargo.TBRACCD_CCRD_CODE,
                                                                                                cancela_cargo.TBRACCD_MERCHANT_ID,
                                                                                                cancela_cargo.TBRACCD_TAX_REPT_YEAR,
                                                                                                cancela_cargo.TBRACCD_TAX_REPT_BOX,
                                                                                                cancela_cargo.TBRACCD_TAX_AMOUNT,
                                                                                                cancela_cargo.TBRACCD_TAX_FUTURE_IND,
                                                                                                cancela_cargo.TBRACCD_DATA_ORIGIN,
                                                                                                cancela_cargo.TBRACCD_CREATE_SOURCE,
                                                                                                cancela_cargo.TBRACCD_CPDT_IND,
                                                                                                cancela_cargo.TBRACCD_AIDY_CODE,
                                                                                                cancela_cargo.TBRACCD_STSP_KEY_SEQUENCE,
                                                                                                cancela_cargo.TBRACCD_PERIOD,
                                                                                                null,
                                                                                                null,
                                                                                                cancela_cargo.TBRACCD_USER_ID,
                                                                                                null ) ;
                                                                                                
                                                    Exception
                                                    When Others then 
                                                      -- dbms_output.put_line ('error insert ' ||sqlerrm);       
                                                      null;                                     
                                                    End;             
                                                                                                
                                                    Begin
                                                            Update tbraccd
                                                            Set TBRACCD_BALANCE = 0
                                                            Where TBRACCD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                            And TBRACCD_CROSSREF_NUMBER = cancela_cargo.TBRACCD_CROSSREF_NUMBER
                                                            And TBRACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;
                                                                                                   
                                                
                                                            Update TVRACCD
                                                            set TVRACCD_BALANCE = 0
                                                            Where TVRACCD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                            And TVRACCD_CROSSREF_NUMBER = cancela_cargo.TBRACCD_CROSSREF_NUMBER
                                                            And TVRACCD_ACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;                                                            
                                                            
                                                            
                                                    Exception
                                                    When Others then 
                                                       --dbms_output.put_line ('error update ' ||sqlerrm);         
                                                       null;                                   
                                                    End;     
       
                                                    Begin
       
                                                --dbms_output.put_line ('Valores Impuetos ' ||cancela_cargo.TBRACCD_PIDM ||'*'|| cancela_cargo.TBRACCD_DETAIL_CODE||'*'||cancela_cargo.TBRACCD_TRAN_NUMBER);             
                                                       Update TVRTAXD
                                                            Set TVRTAXD_TAX_AMOUNT = 0
                                                        Where TVRTAXD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                        And TVRTAXD_ACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;
                                                     Exception
                                                    When Others then 
                                                       --dbms_output.put_line ('error update impuesto ' ||sqlerrm);                  
                                                       null;                          
                                                    End;     
                                                                                                
                            End Loop cancela_cargo;
                            
       
                    End if;

    Exception
    When Others then 
          v_pago:=0;
    End P_LIBERA_PAGO_DIRECTO;  
    
     
 ------ Procedimiento que cambia los estatus de las solicitudes que estaran en proceso 
 PROCEDURE P_CAMBIA_ESTATUS_PROGRESO Is 
 
 v_error Varchar2(2500);
 
 Begin 
 
             For sin_pago in ( select SVRRSRV_SEQ_NO, SVRRSRV_SRVC_CODE, SZRRCON_VIG_PAG
                                                from SVRRSRV, SZRRCON
                                                where SVRRSRV_INACTIVE_IND = 'Y'   ---- Unicamente Activas
                                                And SVRRSRV_WEB_IND = 'Y'   --- Unicamente las que se muestren por WEB
                                                And SVRRSRV_SEQ_NO = SZRRCON_RSRV_SEQ_NO
                                                And SVRRSRV_SRVC_CODE = SZRRCON_SRVC_CODE
                                                And SZRRCON_PAG_FOR = 'N'  ---> No requieren estar pagadas para otorgar el servicio
                                                And SZRRCON_VIG_PAG >= 0  ) loop
                  
                    ------ Se actualizan unicamente los registros que cumplen con las condiciones y no requieren pago para dar continuidad -----
                          
                                                Update  SVRSVPR
                                                Set  SVRSVPR_SRVS_CODE = 'PR'
                                                Where SVRSVPR_RSRV_SEQ_NO = sin_pago.SVRRSRV_SEQ_NO
                                                And SVRSVPR_SRVC_CODE = sin_pago.SVRRSRV_SRVC_CODE
                                                And SVRSVPR_SRVS_CODE = 'AC';
                                                
                                                
              End loop sin_pago;


 
             For pagado in ( select SVRRSRV_SEQ_NO, SVRRSRV_SRVC_CODE, SZRRCON_VIG_PAG
                                                from SVRRSRV, SZRRCON
                                                where SVRRSRV_INACTIVE_IND = 'Y'   ---- Unicamente Activas
                                                And SVRRSRV_WEB_IND = 'Y'   --- Unicamente las que se muestren por WEB
                                                And SVRRSRV_SEQ_NO = SZRRCON_RSRV_SEQ_NO
                                                And SVRRSRV_SRVC_CODE = SZRRCON_SRVC_CODE
                                                And SZRRCON_PAG_FOR = 'S'  ---> Busca las que requieren pago
                                                And SZRRCON_VIG_PAG >= 0 ---> Vigencia mayor a 0
                                                  ) loop
                  
                    ------ Se actualizan unicamente los registros que cumplen con las condiciones y no requieren pago para dar continuidad -----
                          
                                                Update  SVRSVPR
                                                Set  SVRSVPR_SRVS_CODE = 'PR'
                                                Where SVRSVPR_RSRV_SEQ_NO = pagado.SVRRSRV_SEQ_NO
                                                And SVRSVPR_SRVC_CODE = pagado.SVRRSRV_SRVC_CODE
                                                And SVRSVPR_SRVS_CODE = 'PA';
                                                
                                                
              End loop pagado;


  
  
Exception

when Others then 
      v_error := 'Se Presento el Error '|| sqlerrm;
End; 

                             
PROCEDURE P_CANCELA_CARGO_DIRECTO_INB (p_pidm in number, p_solicitud in number)  IS

/******************************************************************************
   NAME:       P_CANCELA_CARGO
   PURPOSE:    Cancelar los cargos de las solicitudes del SSB que son canceladas de forma directa por el usuario 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/11/2015   vramirlo       1. Created this procedure.

  *****************************************************************************/


vl_existe number;
vl_valida number;
vl_secuencia number;
vl_desaplica number;


BEGIN

  ----- Validacion que la solicitud fue cancelada----
  
  dbms_output.put_line ('Entra al proceso');


                     
                     ----- En caso que la solicitud este cancelada se buscaran los codigos de detalle que fueron creados en el estado de de cuenta como cargos 
                    vl_existe :=0;
                    vl_valida := 0; 
                    vl_secuencia :=0;
 
 --dbms_output.put_line ('VALIDA 00 ' ||solicitud.SVRSVPR_PROTOCOL_SEQ_NO ||'*'||  solicitud.SVRSVPR_PIDM);   

                    For valida_cargo in (select TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_DETAIL_CODE, TBRACCD_ENTRY_DATE,
                                                            TBRACCD_AMOUNT, TBRACCD_BALANCE, TBRACCD_EFFECTIVE_DATE
                                                    From tbraccd , tbbdetc
                                                    Where tbraccd_pidm = p_pidm
                                                    And TBRACCD_CROSSREF_NUMBER = p_solicitud
                                                    And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                    And TBBDETC_TYPE_IND = 'C'
                                                    ) loop
                                                   
                 --   dbms_output.put_line ('VALIDA 01 ' ||valida_cargo.TBRACCD_AMOUNT ||'*'||  valida_cargo.TBRACCD_BALANCE);           
                    
                                         
                            If  valida_cargo.TBRACCD_AMOUNT  =   valida_cargo.TBRACCD_BALANCE then
                   --              dbms_output.put_line ('Entra 1');                           
                            
                                vl_valida := 1;
                                  Begin 
                                    Select count(1)
                                     Into vl_existe
                                    from tbrappl 
                                    Where TBRAPPL_PIDM = valida_cargo.TBRACCD_PIDM
                                    And TBRAPPL_CHG_TRAN_NUMBER = valida_cargo.TBRACCD_TRAN_NUMBER
                                    And TBRAPPL_REAPPL_IND is null;
                                Exception 
                                    When Others then 
                                       vl_existe :=0;
                                End;
                                
                            End if;                    
                                                   
                    End loop valida_cargo;
                      
               --   dbms_output.put_line ('Evalua los IF ' || vl_valida ||'*'||vl_existe);                     
                    
                    If  vl_valida = 1 and  vl_existe =0 then 
                         --   dbms_output.put_line ('Entra 2');
                            Begin 
                                select max (TBRACCD_TRAN_NUMBER)
                                Into vl_secuencia
                                from tbraccd
                                where tbraccd_pidm = p_pidm;
                            Exception
                            When Others then 
                               vl_secuencia :=0;
                            End;
                            
                            --dbms_output.put_line ('Entra a Cancelas sin pagos ' || vl_valida ||'*'||vl_existe);                    
                                                
                            For cancela_cargo in (select TBRACCD_PIDM
                                                                    ,TBRACCD_TRAN_NUMBER,TBRACCD_TERM_CODE,TBRACCD_DETAIL_CODE ,TBRACCD_USER ,TBRACCD_ENTRY_DATE ,TBRACCD_AMOUNT, TBRACCD_BALANCE
                                                                    ,TBRACCD_EFFECTIVE_DATE, TBRACCD_BILL_DATE ,TBRACCD_DUE_DATE ,TBRACCD_DESC ,TBRACCD_RECEIPT_NUMBER ,TBRACCD_TRAN_NUMBER_PAID ,TBRACCD_CROSSREF_PIDM
                                                                    ,TBRACCD_CROSSREF_NUMBER, TBRACCD_CROSSREF_DETAIL_CODE ,TBRACCD_SRCE_CODE ,TBRACCD_ACCT_FEED_IND ,TBRACCD_ACTIVITY_DATE ,TBRACCD_SESSION_NUMBER ,TBRACCD_CSHR_END_DATE
                                                                    ,TBRACCD_CRN, TBRACCD_CROSSREF_SRCE_CODE ,TBRACCD_LOC_MDT ,TBRACCD_LOC_MDT_SEQ ,TBRACCD_RATE ,TBRACCD_UNITS ,TBRACCD_DOCUMENT_NUMBER ,TBRACCD_TRANS_DATE ,TBRACCD_PAYMENT_ID
                                                                    ,TBRACCD_INVOICE_NUMBER ,TBRACCD_STATEMENT_DATE ,TBRACCD_INV_NUMBER_PAID ,TBRACCD_CURR_CODE ,TBRACCD_EXCHANGE_DIFF ,TBRACCD_FOREIGN_AMOUNT ,TBRACCD_LATE_DCAT_CODE ,TBRACCD_FEED_DATE
                                                                    ,TBRACCD_FEED_DOC_CODE ,TBRACCD_ATYP_CODE ,TBRACCD_ATYP_SEQNO ,TBRACCD_CARD_TYPE_VR ,TBRACCD_CARD_EXP_DATE_VR ,TBRACCD_CARD_AUTH_NUMBER_VR ,TBRACCD_CROSSREF_DCAT_CODE ,TBRACCD_ORIG_CHG_IND
                                                                    ,TBRACCD_CCRD_CODE ,TBRACCD_MERCHANT_ID ,TBRACCD_TAX_REPT_YEAR ,TBRACCD_TAX_REPT_BOX ,TBRACCD_TAX_AMOUNT ,TBRACCD_TAX_FUTURE_IND ,TBRACCD_DATA_ORIGIN ,TBRACCD_CREATE_SOURCE
                                                                    ,TBRACCD_CPDT_IND ,TBRACCD_AIDY_CODE ,TBRACCD_STSP_KEY_SEQUENCE ,TBRACCD_PERIOD ,TBRACCD_SURROGATE_ID ,TBRACCD_VERSION ,TBRACCD_USER_ID ,TBRACCD_VPDI_CODE
                                                            From tbraccd , TBBDETC
                                                            Where tbraccd_pidm = p_pidm
                                                            And TBRACCD_CROSSREF_NUMBER = p_solicitud
                                                            And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                           And TBBDETC_TYPE_IND = 'C'
                                                            
                                                            ) loop
                            
                                                            vl_secuencia := vl_secuencia+1;
                            
                                                    Begin
                                                    
                                                    --dbms_output.put_line ('Entra a insertar cancelacion ' || vl_valida ||'*'||vl_existe);       
                                                    
                                                    
                                                       Insert into TBRACCD values ( 
                                                                                                cancela_cargo.TBRACCD_PIDM,
                                                                                                vl_secuencia,
                                                                                                cancela_cargo.TBRACCD_TERM_CODE,
                                                                                                cancela_cargo.TBRACCD_DETAIL_CODE,
                                                                                                cancela_cargo.TBRACCD_USER,
                                                                                                sysdate,
                                                                                                cancela_cargo.TBRACCD_AMOUNT * -1,
                                                                                                0,
                                                                                                cancela_cargo.TBRACCD_EFFECTIVE_DATE,
                                                                                                cancela_cargo.TBRACCD_BILL_DATE,
                                                                                                cancela_cargo.TBRACCD_DUE_DATE,
                                                                                                 'Cancelacion '||'SR '||cancela_cargo.TBRACCD_CROSSREF_NUMBER,
                                                                                                cancela_cargo.TBRACCD_RECEIPT_NUMBER,
                                                                                                cancela_cargo.TBRACCD_TRAN_NUMBER,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_PIDM,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_NUMBER,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_DETAIL_CODE,
                                                                                                cancela_cargo.TBRACCD_SRCE_CODE,
                                                                                                cancela_cargo.TBRACCD_ACCT_FEED_IND,
                                                                                                cancela_cargo.TBRACCD_ACTIVITY_DATE,
                                                                                                cancela_cargo.TBRACCD_SESSION_NUMBER,
                                                                                                cancela_cargo.TBRACCD_CSHR_END_DATE,
                                                                                                cancela_cargo.TBRACCD_CRN,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_SRCE_CODE,
                                                                                                cancela_cargo.TBRACCD_LOC_MDT,
                                                                                                cancela_cargo.TBRACCD_LOC_MDT_SEQ,
                                                                                                cancela_cargo.TBRACCD_RATE,
                                                                                                cancela_cargo.TBRACCD_UNITS,
                                                                                                cancela_cargo.TBRACCD_DOCUMENT_NUMBER,
                                                                                                cancela_cargo.TBRACCD_TRANS_DATE,
                                                                                                cancela_cargo.TBRACCD_PAYMENT_ID,
                                                                                                cancela_cargo.TBRACCD_INVOICE_NUMBER,
                                                                                                cancela_cargo.TBRACCD_STATEMENT_DATE,
                                                                                                cancela_cargo.TBRACCD_INV_NUMBER_PAID,
                                                                                                cancela_cargo.TBRACCD_CURR_CODE,
                                                                                                cancela_cargo.TBRACCD_EXCHANGE_DIFF,
                                                                                                cancela_cargo.TBRACCD_FOREIGN_AMOUNT,
                                                                                                cancela_cargo.TBRACCD_LATE_DCAT_CODE,
                                                                                                cancela_cargo.TBRACCD_FEED_DATE,
                                                                                                cancela_cargo.TBRACCD_FEED_DOC_CODE,
                                                                                                cancela_cargo.TBRACCD_ATYP_CODE,
                                                                                                cancela_cargo.TBRACCD_ATYP_SEQNO,
                                                                                                cancela_cargo.TBRACCD_CARD_TYPE_VR,
                                                                                                cancela_cargo.TBRACCD_CARD_EXP_DATE_VR,
                                                                                                cancela_cargo.TBRACCD_CARD_AUTH_NUMBER_VR,
                                                                                                cancela_cargo.TBRACCD_CROSSREF_DCAT_CODE,
                                                                                                cancela_cargo.TBRACCD_ORIG_CHG_IND,
                                                                                                cancela_cargo.TBRACCD_CCRD_CODE,
                                                                                                cancela_cargo.TBRACCD_MERCHANT_ID,
                                                                                                cancela_cargo.TBRACCD_TAX_REPT_YEAR,
                                                                                                cancela_cargo.TBRACCD_TAX_REPT_BOX,
                                                                                                cancela_cargo.TBRACCD_TAX_AMOUNT,
                                                                                                cancela_cargo.TBRACCD_TAX_FUTURE_IND,
                                                                                                cancela_cargo.TBRACCD_DATA_ORIGIN,
                                                                                                cancela_cargo.TBRACCD_CREATE_SOURCE,
                                                                                                cancela_cargo.TBRACCD_CPDT_IND,
                                                                                                cancela_cargo.TBRACCD_AIDY_CODE,
                                                                                                cancela_cargo.TBRACCD_STSP_KEY_SEQUENCE,
                                                                                                cancela_cargo.TBRACCD_PERIOD,
                                                                                                null,
                                                                                                null,
                                                                                                cancela_cargo.TBRACCD_USER_ID,
                                                                                                null ) ;
                                                                                                
                                                    Exception
                                                    When Others then 
                                                       dbms_output.put_line ('error insert ' ||sqlerrm); 
                                                       NULL;                                           
                                                    End;             
                                                                                                
                                                    Begin
                                                            Update tbraccd
                                                            Set TBRACCD_BALANCE = 0
                                                            Where TBRACCD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                            And TBRACCD_CROSSREF_NUMBER = cancela_cargo.TBRACCD_CROSSREF_NUMBER
                                                            And TBRACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;
                                                            
                                                            Update TVRACCD
                                                            set TVRACCD_BALANCE = 0
                                                            Where TVRACCD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                            And TVRACCD_CROSSREF_NUMBER = cancela_cargo.TBRACCD_CROSSREF_NUMBER
                                                            And TVRACCD_ACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;
                                                                                                   
                                                    Exception
                                                    When Others then 
                                                       dbms_output.put_line ('error update ' ||sqlerrm);       
                                                       NULL;                                     
                                                    End;     
       
                                                    Begin
       
                                                dbms_output.put_line ('Valores Impuetos ' ||cancela_cargo.TBRACCD_PIDM ||'*'|| cancela_cargo.TBRACCD_DETAIL_CODE||'*'||cancela_cargo.TBRACCD_TRAN_NUMBER);             
                                                       Update TVRTAXD
                                                            Set TVRTAXD_TAX_AMOUNT = 0
                                                        Where TVRTAXD_PIDM = cancela_cargo.TBRACCD_PIDM
                                                        And TVRTAXD_ACCD_TRAN_NUMBER = cancela_cargo.TBRACCD_TRAN_NUMBER;
                                                     Exception
                                                    When Others then 
                                                       dbms_output.put_line ('error update impuesto ' ||sqlerrm);    
                                                       null;                                        
                                                    End;     
      
      
                                                                                               
                            End Loop cancela_cargo;
                            
                            
                     -- dbms_output.put_line ('Evalua los IF 2' || vl_valida ||'*'||vl_existe);                     
                             
                    ElsIf  vl_valida = 0 and  vl_existe =0 then       ----->>>> Cancelara los pagos realizados por descuentos unicamente.   
                    
                              P_LIBERA_PAGO_DIRECTO (p_pidm, p_solicitud);
                    
       
                    End if;


-----------------------------------------------------------------------------------
------------------------------------ Cancela Pagos -----------------------------
-----------------------------------------------------------------------------------

                     ----- En caso que la solicitud este cancelada se buscaran los codigos de detalle que fueron creados en el estado de de cuenta como cargos 
                    vl_existe :=0;
                    vl_valida := 0; 
                    vl_secuencia :=0;
                    
                    For valida_pago in (select TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_DETAIL_CODE, TBRACCD_ENTRY_DATE,
                                                            TBRACCD_AMOUNT, TBRACCD_BALANCE * -1 TBRACCD_BALANCE, TBRACCD_EFFECTIVE_DATE
                                                    From tbraccd , tbbdetc
                                                    Where tbraccd_pidm = p_pidm
                                                    And TBRACCD_CROSSREF_NUMBER = p_solicitud 
                                                    And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                    And TBBDETC_TYPE_IND = 'P'
                                                    
                                                    ) loop
                                                   
                                                   --dbms_output.put_line ('Entra 05 Pagos'|| valida_pago.TBRACCD_AMOUNT ||'*' ||  valida_pago.TBRACCD_BALANCE );           
                                                   
                            If  valida_pago.TBRACCD_AMOUNT  =   valida_pago.TBRACCD_BALANCE then
                                vl_valida := 1;
                                  Begin 
                                    Select count(1)
                                     Into vl_existe
                                    from tbrappl 
                                    Where TBRAPPL_PIDM = valida_pago.TBRACCD_PIDM
                                    And TBRAPPL_CHG_TRAN_NUMBER = valida_pago.TBRACCD_TRAN_NUMBER
                                    And TBRAPPL_REAPPL_IND is null;
                                Exception 
                                    When Others then 
                                       vl_existe :=0;
                                End;
                                
                            End if;                    
                                                   
                    End loop;
                      
                    If  vl_valida = 1 and  vl_existe =0 then 
                     --dbms_output.put_line ('Entra 06 Pagos'|| vl_valida ||'*' ||  vl_existe ); 
                        Begin 
                            select max (TBRACCD_TRAN_NUMBER)
                            Into vl_secuencia
                            from tbraccd
                            where tbraccd_pidm = p_pidm;
                        Exception
                        When Others then 
                           vl_secuencia :=0;
                        End;
                        
                                            
                        For cancela_pago in (select TBRACCD_PIDM
                                                                ,TBRACCD_TRAN_NUMBER,TBRACCD_TERM_CODE,TBRACCD_DETAIL_CODE ,TBRACCD_USER ,TBRACCD_ENTRY_DATE ,TBRACCD_AMOUNT, TBRACCD_BALANCE
                                                                ,TBRACCD_EFFECTIVE_DATE, TBRACCD_BILL_DATE ,TBRACCD_DUE_DATE ,TBRACCD_DESC ,TBRACCD_RECEIPT_NUMBER ,TBRACCD_TRAN_NUMBER_PAID ,TBRACCD_CROSSREF_PIDM
                                                                ,TBRACCD_CROSSREF_NUMBER, TBRACCD_CROSSREF_DETAIL_CODE ,TBRACCD_SRCE_CODE ,TBRACCD_ACCT_FEED_IND ,TBRACCD_ACTIVITY_DATE ,TBRACCD_SESSION_NUMBER ,TBRACCD_CSHR_END_DATE
                                                                ,TBRACCD_CRN, TBRACCD_CROSSREF_SRCE_CODE ,TBRACCD_LOC_MDT ,TBRACCD_LOC_MDT_SEQ ,TBRACCD_RATE ,TBRACCD_UNITS ,TBRACCD_DOCUMENT_NUMBER ,TBRACCD_TRANS_DATE ,TBRACCD_PAYMENT_ID
                                                                ,TBRACCD_INVOICE_NUMBER ,TBRACCD_STATEMENT_DATE ,TBRACCD_INV_NUMBER_PAID ,TBRACCD_CURR_CODE ,TBRACCD_EXCHANGE_DIFF ,TBRACCD_FOREIGN_AMOUNT ,TBRACCD_LATE_DCAT_CODE ,TBRACCD_FEED_DATE
                                                                ,TBRACCD_FEED_DOC_CODE ,TBRACCD_ATYP_CODE ,TBRACCD_ATYP_SEQNO ,TBRACCD_CARD_TYPE_VR ,TBRACCD_CARD_EXP_DATE_VR ,TBRACCD_CARD_AUTH_NUMBER_VR ,TBRACCD_CROSSREF_DCAT_CODE ,TBRACCD_ORIG_CHG_IND
                                                                ,TBRACCD_CCRD_CODE ,TBRACCD_MERCHANT_ID ,TBRACCD_TAX_REPT_YEAR ,TBRACCD_TAX_REPT_BOX ,TBRACCD_TAX_AMOUNT ,TBRACCD_TAX_FUTURE_IND ,TBRACCD_DATA_ORIGIN ,TBRACCD_CREATE_SOURCE
                                                                ,TBRACCD_CPDT_IND ,TBRACCD_AIDY_CODE ,TBRACCD_STSP_KEY_SEQUENCE ,TBRACCD_PERIOD ,TBRACCD_SURROGATE_ID ,TBRACCD_VERSION ,TBRACCD_USER_ID ,TBRACCD_VPDI_CODE
                                                        From tbraccd , TBBDETC
                                                        Where tbraccd_pidm = p_pidm
                                                        And TBRACCD_CROSSREF_NUMBER = p_solicitud 
                                                        And TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                       And TBBDETC_TYPE_IND = 'P'
                                                        
                                                        ) loop
                        
                                                        vl_secuencia := vl_secuencia+1;
                        
                                
                                        Begin
                                                   Insert into TBRACCD values ( 
                                                                                            cancela_pago.TBRACCD_PIDM,
                                                                                            vl_secuencia,
                                                                                            cancela_pago.TBRACCD_TERM_CODE,
                                                                                            cancela_pago.TBRACCD_DETAIL_CODE,
                                                                                            cancela_pago.TBRACCD_USER,
                                                                                            sysdate,
                                                                                            cancela_pago.TBRACCD_AMOUNT * -1,
                                                                                            0,
                                                                                            cancela_pago.TBRACCD_EFFECTIVE_DATE,
                                                                                            cancela_pago.TBRACCD_BILL_DATE,
                                                                                            cancela_pago.TBRACCD_DUE_DATE,
                                                                                             'Cancelacion '||'SR '||cancela_pago.TBRACCD_CROSSREF_NUMBER,
                                                                                            cancela_pago.TBRACCD_RECEIPT_NUMBER,
                                                                                            cancela_pago.TBRACCD_TRAN_NUMBER,
                                                                                            cancela_pago.TBRACCD_CROSSREF_PIDM,
                                                                                            cancela_pago.TBRACCD_CROSSREF_NUMBER,
                                                                                            cancela_pago.TBRACCD_CROSSREF_DETAIL_CODE,
                                                                                            cancela_pago.TBRACCD_SRCE_CODE,
                                                                                            cancela_pago.TBRACCD_ACCT_FEED_IND,
                                                                                            cancela_pago.TBRACCD_ACTIVITY_DATE,
                                                                                            cancela_pago.TBRACCD_SESSION_NUMBER,
                                                                                            cancela_pago.TBRACCD_CSHR_END_DATE,
                                                                                            cancela_pago.TBRACCD_CRN,
                                                                                            cancela_pago.TBRACCD_CROSSREF_SRCE_CODE,
                                                                                            cancela_pago.TBRACCD_LOC_MDT,
                                                                                            cancela_pago.TBRACCD_LOC_MDT_SEQ,
                                                                                            cancela_pago.TBRACCD_RATE,
                                                                                            cancela_pago.TBRACCD_UNITS,
                                                                                            cancela_pago.TBRACCD_DOCUMENT_NUMBER,
                                                                                            cancela_pago.TBRACCD_TRANS_DATE,
                                                                                            cancela_pago.TBRACCD_PAYMENT_ID,
                                                                                            cancela_pago.TBRACCD_INVOICE_NUMBER,
                                                                                            cancela_pago.TBRACCD_STATEMENT_DATE,
                                                                                            cancela_pago.TBRACCD_INV_NUMBER_PAID,
                                                                                            cancela_pago.TBRACCD_CURR_CODE,
                                                                                            cancela_pago.TBRACCD_EXCHANGE_DIFF,
                                                                                            cancela_pago.TBRACCD_FOREIGN_AMOUNT,
                                                                                            cancela_pago.TBRACCD_LATE_DCAT_CODE,
                                                                                            cancela_pago.TBRACCD_FEED_DATE,
                                                                                            cancela_pago.TBRACCD_FEED_DOC_CODE,
                                                                                            cancela_pago.TBRACCD_ATYP_CODE,
                                                                                            cancela_pago.TBRACCD_ATYP_SEQNO,
                                                                                            cancela_pago.TBRACCD_CARD_TYPE_VR,
                                                                                            cancela_pago.TBRACCD_CARD_EXP_DATE_VR,
                                                                                            cancela_pago.TBRACCD_CARD_AUTH_NUMBER_VR,
                                                                                            cancela_pago.TBRACCD_CROSSREF_DCAT_CODE,
                                                                                            cancela_pago.TBRACCD_ORIG_CHG_IND,
                                                                                            cancela_pago.TBRACCD_CCRD_CODE,
                                                                                            cancela_pago.TBRACCD_MERCHANT_ID,
                                                                                            cancela_pago.TBRACCD_TAX_REPT_YEAR,
                                                                                            cancela_pago.TBRACCD_TAX_REPT_BOX,
                                                                                            cancela_pago.TBRACCD_TAX_AMOUNT,
                                                                                            cancela_pago.TBRACCD_TAX_FUTURE_IND,
                                                                                            cancela_pago.TBRACCD_DATA_ORIGIN,
                                                                                            cancela_pago.TBRACCD_CREATE_SOURCE,
                                                                                            cancela_pago.TBRACCD_CPDT_IND,
                                                                                            cancela_pago.TBRACCD_AIDY_CODE,
                                                                                            cancela_pago.TBRACCD_STSP_KEY_SEQUENCE,
                                                                                            cancela_pago.TBRACCD_PERIOD,
                                                                                            null,
                                                                                            null,
                                                                                            cancela_pago.TBRACCD_USER_ID,
                                                                                            null ) ;
                                        Exception
                                        When Others then 
                                            --dbms_output.put_line ('Entra 07 Pagos'|| sqlerrm );                                                     
                                            null;
                                        End;
                                        

                                       Begin
                                                Update tbraccd
                                                Set TBRACCD_BALANCE = 0
                                                Where TBRACCD_PIDM = cancela_pago.TBRACCD_PIDM
                                                And TBRACCD_CROSSREF_NUMBER = cancela_pago.TBRACCD_CROSSREF_NUMBER
                                                And TBRACCD_TRAN_NUMBER = cancela_pago.TBRACCD_TRAN_NUMBER;
                                                
                                                
                                                Update TVRACCD
                                                set TVRACCD_BALANCE = 0
                                                Where TVRACCD_PIDM = cancela_pago.TBRACCD_PIDM
                                                And TVRACCD_CROSSREF_NUMBER = cancela_pago.TBRACCD_CROSSREF_NUMBER
                                                And TVRACCD_ACCD_TRAN_NUMBER = cancela_pago.TBRACCD_TRAN_NUMBER;
                                                                                                                                                   
                                                                                               
                                       Exception
                                        When Others then 
                                           --dbms_output.put_line ('error update ' ||sqlerrm);    
                                           null;                                        
                                       End;     
                                        
                        End Loop;
   
                End if;



END P_CANCELA_CARGO_DIRECTO_INB;

       
 
END  PKG_SSB;
/

DROP PUBLIC SYNONYM PKG_SSB;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SSB FOR BANINST1.PKG_SSB;


GRANT EXECUTE ON BANINST1.PKG_SSB TO CONSULTA;

GRANT EXECUTE ON BANINST1.PKG_SSB TO SATURN;
