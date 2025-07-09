DROP PACKAGE BODY BANINST1.PKG_ALTA_BAJA_MATERIAS;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_alta_baja_materias IS
----VERSION 25/03/2024 GOG
    PROCEDURE p_baja_materias_face (
        pidm         NUMBER,
        no_materias  NUMBER,
        P_PERIODO VARCHAR2,
        p_user varchar2,
        p_sp VARCHAR2,
        p_programa VARCHAR2,        
        po_respuesta OUT VARCHAR2
    ) IS

        lv_periodo     VARCHAR2(50);
        ln_escalonado  NUMBER;
        lv_codigo      VARCHAR2(10);
        lv_descripcion VARCHAR2(500);
        lv_codigo_d    VARCHAR2(10);
        ln_porcentaje  NUMBER;
        lv_campus      VARCHAR2(20);
        ln_calculo     NUMBER;
        ln_cnt         NUMBER:=0;
        ln_trans_paid  NUMBER;
        ln_cnt_esca    NUMBER:=0;
        ld_fec_inicio  DATE;
        p_pidm number;

    
    
    BEGIN
        execute immediate 'delete from SZTCALP where PIDM = pidm'; 
      --  execute immediate 'delete from taismgr.tbraccd_tmp_bajas where tbraccd_pidm = pidm';
        commit;


        
        p_pidm:= null;
         p_pidm:= pidm;

            --
            BEGIN 
                SELECT distinct b.FECHA_INICIO 
                  INTO ld_fec_inicio
                  FROM tztprog b
                 WHERE b.pidm = p_pidm 
                   AND b.PROGRAMA = p_programa
                   And b.SP = p_sp;
               EXCEPTION WHEN OTHERS THEN 
               po_respuesta := 'Error al obtener Fecha Inicio'||sqlerrm;
            END;
            --
            --       
        BEGIN
        delete from taismgr.tbraccd_tmp_bajas where tbraccd_pidm = p_pidm;
        COMMIT;
        EXCEPTION WHEN OTHERS THEN 
               po_respuesta := 'Error al eliminar info bajas'||sqlerrm;
        
        END ;

        SELECT
            MAX(tbraccd_term_code)
        INTO lv_periodo
        FROM
            tbraccd
        WHERE tbraccd_pidm = pidm
          AND TBRACCD_PERIOD = p_periodo
          AND TBRACCD_STSP_KEY_SEQUENCE = p_sp
            AND tbraccd_feed_date IS NOT NULL;


        SELECT UNIQUE B.SZVCAMP_CAMP_CODE||'_'||C.TBBDETC_TAXT_CODE
        INTO lv_campus
        FROM
            tbraccd A, tbbdetc c,  SZVCAMP B
        WHERE c.TBBDETC_DETAIL_CODE = a.TBRACCD_DETAIL_CODE
        and    substr(A.tbraccd_detail_code, 1, 2) = B.SZVCAMP_CAMP_ALT_CODE
        AND a.tbraccd_pidm = pidm
        AND a.TBRACCD_PERIOD = p_periodo
        AND a.tbraccd_term_code = lv_periodo
        AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
        AND a.tbraccd_detail_code IN (SELECT TZTNCD_CODE
                                        FROM tztncd, tbbdetc
                                        WHERE TZTNCD_concepto = 'Venta'
                                        AND TBBDETC_detail_code = TZTNCD_CODE
                                        AND TBBDETC_type_ind = 'C'
                                        AND TBBDETC_detc_active_ind = 'Y'
                                        AND TBBDETC_dcat_code = 'COL'
                                        AND TBBDETC_taxt_code NOT IN ('GN','EC','CU','ES','ID','BA')                                
               );
        
        ---AGREGAR excepciones para control de errores fn
            SELECT ZSTPARA_PARAM_VALOR
                    INTO ln_porcentaje
                    FROM zstpara
                   WHERE     zstpara_mapa_id = 'PORC_BAJA_MAT'
                   and ZSTPARA_PARAM_ID = lv_campus;

            --Validaciones para escalonados  
                  select count(1)
                   INTO ln_escalonado
                   from GORADID 
                  where GORADID_PIDM = pidm 
                    and GORADID_ADID_CODE in (SELECT ZSTPARA_PARAM_VALOR
                                                FROM zstpara
                                               WHERE zstpara_mapa_id = 'ETIQ_AJUST_MAT'
                                                 and ZSTPARA_PARAM_ID = lv_campus);
                    
 --    if ln_escalonado > 0 then
       BEGIN
        UPDATE TBRACCD a SET a.tbraccd_tran_number_paid = NULL
        WHERE   a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    AND a.tbraccd_feed_date IS NOT NULL
                    AND substr(a.tbraccd_detail_code, 3, 2) IN ('M3');
                    commit;
                    ---desaplica pagos
                    P_DESAPLICA_PAGOS (pidm,p_periodo,lv_periodo) ;
        END;
                    FOR esca IN (
                SELECT UNIQUE
                    a.tbraccd_pidm pidm,a.tbraccd_effective_date,
                    b.tbbdetc_desc,
                    a.tbraccd_amount,
                    a.tbraccd_balance,
                    a.tbraccd_tran_number_paid,
                    a.TBRACCD_TRAN_NUMBER,
                    a.TBRACCD_CURR_CODE
                FROM
                    tbraccd a,
                    tbbdetc b
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                    AND a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    AND a.tbraccd_feed_date IS NOT NULL
                    AND substr(a.tbraccd_detail_code, 3, 2) IN ('M3')
            ) LOOP
    ln_cnt_esca := ln_cnt_esca+1;
                 dbms_output.put_line ('flujo escalonados');


        

            BEGIN
                SELECT
                    unique substr(tbraccd_term_code, 1, 2)
                INTO lv_codigo
                FROM
                    tbraccd
                WHERE
                    tbraccd_pidm = esca.pidm;

            END;
                 dbms_output.put_line ('inserto escalonados'||lv_codigo);

            BEGIN
                SELECT DISTINCT
                    tbbdetc_desc,
                    tbbdetc_detail_code
                INTO
                    lv_descripcion,
                    lv_codigo_d
                FROM
                    tbbdetc
                WHERE
                        1 = 1
                    AND  tbbdetc_detail_code = lv_codigo || 'ON';

            END;
                        
         /*       SELECT
                    a.TBRACCD_TRAN_NUMBER
                    INTO ln_trans_paid
                FROM
                    tbraccd a,
                    tbbdetc b
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                    AND a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.tbraccd_effective_date = esca.tbraccd_effective_date
                    AND substr(a.tbraccd_detail_code, 3, 2) IN ('NL', 'NP', 'NM');*/

 dbms_output.put_line ('inserto escalonados');
begin
                         INSERT INTO tbraccd_tmp_bajas
                         (TBRACCD_PIDM                
                                                ,TBRACCD_TRAN_NUMBER         
                                                ,TBRACCD_TERM_CODE           
                                                ,TBRACCD_DETAIL_CODE         
                                                ,TBRACCD_USER                
                                                ,TBRACCD_ENTRY_DATE          
                                                ,TBRACCD_AMOUNT              
                                                ,TBRACCD_BALANCE             
                                                ,TBRACCD_EFFECTIVE_DATE      
                                                ,TBRACCD_BILL_DATE           
                                                ,TBRACCD_DUE_DATE            
                                                ,TBRACCD_DESC                
                                                ,TBRACCD_RECEIPT_NUMBER      
                                                ,TBRACCD_TRAN_NUMBER_PAID    
                                                ,TBRACCD_CROSSREF_PIDM       
                                                ,TBRACCD_CROSSREF_NUMBER     
                                                ,TBRACCD_CROSSREF_DETAIL_CODE
                                                ,TBRACCD_SRCE_CODE           
                                                ,TBRACCD_ACCT_FEED_IND       
                                                ,TBRACCD_ACTIVITY_DATE       
                                                ,TBRACCD_SESSION_NUMBER      
                                                ,TBRACCD_CSHR_END_DATE       
                                                ,TBRACCD_CRN                 
                                                ,TBRACCD_CROSSREF_SRCE_CODE  
                                                ,TBRACCD_LOC_MDT             
                                                ,TBRACCD_LOC_MDT_SEQ         
                                                ,TBRACCD_RATE                
                                                ,TBRACCD_UNITS               
                                                ,TBRACCD_DOCUMENT_NUMBER     
                                                ,TBRACCD_TRANS_DATE          
                                                ,TBRACCD_PAYMENT_ID          
                                                ,TBRACCD_INVOICE_NUMBER      
                                                ,TBRACCD_STATEMENT_DATE      
                                                ,TBRACCD_INV_NUMBER_PAID     
                                                ,TBRACCD_CURR_CODE           
                                                ,TBRACCD_EXCHANGE_DIFF       
                                                ,TBRACCD_FOREIGN_AMOUNT      
                                                ,TBRACCD_LATE_DCAT_CODE      
                                                ,TBRACCD_FEED_DATE           
                                                ,TBRACCD_FEED_DOC_CODE       
                                                ,TBRACCD_ATYP_CODE           
                                                ,TBRACCD_ATYP_SEQNO          
                                                ,TBRACCD_CARD_TYPE_VR        
                                                ,TBRACCD_CARD_EXP_DATE_VR    
                                                ,TBRACCD_CARD_AUTH_NUMBER_VR 
                                                ,TBRACCD_CROSSREF_DCAT_CODE  
                                                ,TBRACCD_ORIG_CHG_IND        
                                                ,TBRACCD_CCRD_CODE           
                                                ,TBRACCD_MERCHANT_ID         
                                                ,TBRACCD_TAX_REPT_YEAR       
                                                ,TBRACCD_TAX_REPT_BOX        
                                                ,TBRACCD_TAX_AMOUNT          
                                                ,TBRACCD_TAX_FUTURE_IND      
                                                ,TBRACCD_DATA_ORIGIN         
                                                ,TBRACCD_CREATE_SOURCE       
                                                ,TBRACCD_CPDT_IND            
                                                ,TBRACCD_AIDY_CODE           
                                                ,TBRACCD_STSP_KEY_SEQUENCE   
                                                ,TBRACCD_PERIOD              
                                                ,TBRACCD_SURROGATE_ID        
                                                ,TBRACCD_VERSION             
                                                ,TBRACCD_USER_ID             
                                                ,TBRACCD_VPDI_CODE  
                                                ,TBRACCD_FECHA_INSERCION
                                                )                    
                            VALUES ( pidm,                          
                                    0, --ln_secuencia,                
                                     lv_periodo,                     
                                     lv_codigo_d,                      
                                     p_user,                           
                                     SYSDATE,                        
                                    esca.tbraccd_amount,                
                                    esca.tbraccd_amount,               
                                    esca.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     lv_descripcion,                 
                                     NULL,--CX.ORDEN,                       
                                     esca.TBRACCD_TRAN_NUMBER,--tran_paid                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'T',                            
                                     'Y',                            
                                     SYSDATE,                        
                                     0,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     esca.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     esca.tbraccd_curr_code,                          
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     ld_fec_inicio,                
                                     1,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'BAJAS_MAT_ESCA',                 
                                     'BAJAS_MAT_ESCA',                 
                                     NULL,                           
                                     NULL,                           
                                     p_sp,                          
                                     p_periodo,--CX.PERIODO,                     
                                     0,                           
                                     0,                           
                                     USER,                           
                                     0,
                                     trunc(SYSDATE)); 
                                     COMMIT;
                                     exception when others then 
                                     dbms_output.put_line (sqlerrm);
                                     end;

  END LOOP;
-- end if;  -- fin de escalonados
                   
 ln_calculo := ln_porcentaje*no_materias;

 dbms_output.put_line ('no_materias'||no_materias);

   if no_materias >= 1 then 
                    FOR calc IN (
                SELECT UNIQUE
                    a.tbraccd_pidm pidm,
                    a.tbraccd_effective_date,
                    b.tbbdetc_desc,
                    a.tbraccd_amount,
                    a.tbraccd_balance,
                    a.tbraccd_tran_number_paid,
                    a.TBRACCD_TRAN_NUMBER,
                    a.TBRACCD_CURR_CODE
                FROM
                    tbraccd a,
                    tbbdetc b
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                    AND a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    AND a.tbraccd_feed_date IS NOT NULL
                    AND a.tbraccd_detail_code IN (SELECT TZTNCD_CODE
                                                    FROM tztncd, tbbdetc
                                                    WHERE TZTNCD_concepto = 'Venta'
                                                    AND TBBDETC_detail_code = TZTNCD_CODE
                                                    AND TBBDETC_type_ind = 'C'
                                                    AND TBBDETC_detc_active_ind = 'Y'
                                                    AND TBBDETC_dcat_code = 'COL'
                                                    AND TBBDETC_taxt_code NOT IN ('GN','EC','CU','ES','ID','BA')                                
                       )
            ) LOOP
    ln_cnt := ln_cnt+1;
    
    dbms_output.put_line('calcpagos :'||calc.tbbdetc_desc);
    dbms_output.put_line('calcpagos2 :'||calc.tbraccd_amount);
    dbms_output.put_line('calcpagos3 :'||to_char(ln_porcentaje)||'%');
        dbms_output.put_line('calcpagos4 :'||ln_calculo);



                INSERT INTO SZTCALP (
                    fecha_vencimiento,
                    concepto,
                    monto_anterior,
                    pct_alta_baja,
                    monto_cajuste,
                    monto_accesorios,
                    pidm,
                    fec_calculo
                ) VALUES (
                    calc.tbraccd_effective_date,
                    calc.tbbdetc_desc,
                    calc.tbraccd_amount,
                    --to_char(ln_porcentaje)||'%',
                    to_char(ln_porcentaje*no_materias)||'%',
                    round((calc.tbraccd_amount - ( ( calc.tbraccd_amount * ln_calculo ) / 100 ))),
                    NULL,
                    pidm,
                    sysdate
                );
                commit;
                
            BEGIN
                SELECT
                    unique substr(tbraccd_term_code, 1, 2)
                INTO lv_codigo
                FROM
                    tbraccd
                WHERE
                    tbraccd_pidm = calc.pidm;

            END;

            BEGIN
                SELECT DISTINCT
                    tbbdetc_desc,
                    tbbdetc_detail_code
                INTO
                    lv_descripcion,
                    lv_codigo_d
                FROM
                    tbbdetc
                WHERE
                        1 = 1
                    AND  tbbdetc_detail_code = lv_codigo || 'Y2';

            END;
                        
if ln_cnt <= 1 then 
dbms_output.put_line('ln_cnt1 :'||ln_cnt||'balance');
    if calc.tbraccd_balance = 0 then 
    ln_trans_paid := null;
    elsif calc.tbraccd_balance < (calc.tbraccd_amount - ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
    ln_trans_paid := null;
    dbms_output.put_line('ln_cnt2 :'||ln_cnt);
    elsif calc.tbraccd_balance >= (calc.tbraccd_amount - ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
    dbms_output.put_line('ln_cnt3 :'||ln_cnt);
    ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
    end if;

elsif ln_cnt > 1 then 
dbms_output.put_line('ln_cnt4 :'||ln_cnt);
ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
end if;
--general
    if calc.tbraccd_balance = 0 then 
    ln_trans_paid := null;
    elsif calc.tbraccd_balance >= (calc.tbraccd_amount - ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
    dbms_output.put_line('ln_Y2 :'||ln_cnt);
    ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
    end if;
 dbms_output.put_line ('entro a insertar tbraccd_tmp_bajas');

                         INSERT INTO tbraccd_tmp_bajas
                         (TBRACCD_PIDM                
                                                ,TBRACCD_TRAN_NUMBER         
                                                ,TBRACCD_TERM_CODE           
                                                ,TBRACCD_DETAIL_CODE         
                                                ,TBRACCD_USER                
                                                ,TBRACCD_ENTRY_DATE          
                                                ,TBRACCD_AMOUNT              
                                                ,TBRACCD_BALANCE             
                                                ,TBRACCD_EFFECTIVE_DATE      
                                                ,TBRACCD_BILL_DATE           
                                                ,TBRACCD_DUE_DATE            
                                                ,TBRACCD_DESC                
                                                ,TBRACCD_RECEIPT_NUMBER      
                                                ,TBRACCD_TRAN_NUMBER_PAID    
                                                ,TBRACCD_CROSSREF_PIDM       
                                                ,TBRACCD_CROSSREF_NUMBER     
                                                ,TBRACCD_CROSSREF_DETAIL_CODE
                                                ,TBRACCD_SRCE_CODE           
                                                ,TBRACCD_ACCT_FEED_IND       
                                                ,TBRACCD_ACTIVITY_DATE       
                                                ,TBRACCD_SESSION_NUMBER      
                                                ,TBRACCD_CSHR_END_DATE       
                                                ,TBRACCD_CRN                 
                                                ,TBRACCD_CROSSREF_SRCE_CODE  
                                                ,TBRACCD_LOC_MDT             
                                                ,TBRACCD_LOC_MDT_SEQ         
                                                ,TBRACCD_RATE                
                                                ,TBRACCD_UNITS               
                                                ,TBRACCD_DOCUMENT_NUMBER     
                                                ,TBRACCD_TRANS_DATE          
                                                ,TBRACCD_PAYMENT_ID          
                                                ,TBRACCD_INVOICE_NUMBER      
                                                ,TBRACCD_STATEMENT_DATE      
                                                ,TBRACCD_INV_NUMBER_PAID     
                                                ,TBRACCD_CURR_CODE           
                                                ,TBRACCD_EXCHANGE_DIFF       
                                                ,TBRACCD_FOREIGN_AMOUNT      
                                                ,TBRACCD_LATE_DCAT_CODE      
                                                ,TBRACCD_FEED_DATE           
                                                ,TBRACCD_FEED_DOC_CODE       
                                                ,TBRACCD_ATYP_CODE           
                                                ,TBRACCD_ATYP_SEQNO          
                                                ,TBRACCD_CARD_TYPE_VR        
                                                ,TBRACCD_CARD_EXP_DATE_VR    
                                                ,TBRACCD_CARD_AUTH_NUMBER_VR 
                                                ,TBRACCD_CROSSREF_DCAT_CODE  
                                                ,TBRACCD_ORIG_CHG_IND        
                                                ,TBRACCD_CCRD_CODE           
                                                ,TBRACCD_MERCHANT_ID         
                                                ,TBRACCD_TAX_REPT_YEAR       
                                                ,TBRACCD_TAX_REPT_BOX        
                                                ,TBRACCD_TAX_AMOUNT          
                                                ,TBRACCD_TAX_FUTURE_IND      
                                                ,TBRACCD_DATA_ORIGIN         
                                                ,TBRACCD_CREATE_SOURCE       
                                                ,TBRACCD_CPDT_IND            
                                                ,TBRACCD_AIDY_CODE           
                                                ,TBRACCD_STSP_KEY_SEQUENCE   
                                                ,TBRACCD_PERIOD              
                                                ,TBRACCD_SURROGATE_ID        
                                                ,TBRACCD_VERSION             
                                                ,TBRACCD_USER_ID             
                                                ,TBRACCD_VPDI_CODE  
                                                ,TBRACCD_FECHA_INSERCION
                                                )                    
                            VALUES ( pidm,                          
                                    0, --ln_secuencia,                
                                     lv_periodo,                     
                                     lv_codigo_d,                      
                                     p_user,                           
                                     SYSDATE,                        
                                    calc.tbraccd_amount -(calc.tbraccd_amount - ( ( calc.tbraccd_amount * ln_calculo ) / 100 )),                
                                    calc.tbraccd_amount -(calc.tbraccd_amount - ( ( calc.tbraccd_amount * ln_calculo ) / 100 )),               
                                    calc.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     lv_descripcion,                 
                                     NULL,--CX.ORDEN,                       
                                     ln_trans_paid,--tran_paid                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'T',                            
                                     'Y',                            
                                     SYSDATE,                        
                                     0,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                    calc.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     calc.tbraccd_curr_code,                          
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     ld_fec_inicio,                
                                     1,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'BAJAS_MAT',                 
                                     'BAJAS_MAT',                 
                                     NULL,                           
                                     NULL,                           
                                     p_sp,                          
                                     p_periodo,--CX.PERIODO,                     
                                     0,                           
                                     0,                           
                                     p_user,                           
                                     0,
                                     trunc(SYSDATE)); 
                                     COMMIT;

            po_respuesta := '00';
END LOOP;
FOR ACC IN (SELECT UNIQUE
                    a.tbraccd_pidm pidm,a.tbraccd_effective_date,
                    b.tbbdetc_desc,
                    a.tbraccd_amount
                FROM
                    tbraccd a,
                    tbbdetc b,
                    TZTINC c
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                        AND  a.tbraccd_detail_code = c.codigo 
                    AND a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo)
                     LOOP
                INSERT INTO SZTCALP (
                    fecha_vencimiento,
                    concepto,
                    monto_anterior,
                    pct_alta_baja,
                    monto_cajuste,
                    monto_accesorios,
                    pidm,
                    fec_calculo
                ) VALUES (
                    acc.tbraccd_effective_date,
                    acc.tbbdetc_desc,
                    null,
                    null,
                    null,
                    round(acc.tbraccd_amount),
                    pidm,
                    sysdate
                );
                commit;
                end loop;
--end if;
END IF;

   EXCEPTION WHEN OTHERS THEN 
   po_respuesta := 'Error al proceso general'||sqlerrm;        
    END p_baja_materias_face;


 PROCEDURE p_baja_materias_dina (
        pidm         NUMBER,
        no_materias  NUMBER,
        P_PERIODO VARCHAR2,
        p_user VARCHAR2,
        p_sp VARCHAR2,
        p_programa VARCHAR2,        
        po_respuesta OUT VARCHAR2
    ) IS

        lv_periodo     VARCHAR2(50);
        ln_escalonado  NUMBER;
        ln_secuencia   NUMBER;
        lv_codigo      VARCHAR2(10);
        lv_descripcion VARCHAR2(500);
        lv_codigo_d    VARCHAR2(10);
        ln_monto       NUMBER;
        ln_porcentaje  NUMBER;
        lv_campus      VARCHAR2(20);
        ln_calculo     NUMBER;
        ln_seq         NUMBER;
        ln_cnt         NUMBER:=0;
        ln_trans_paid  NUMBER;
        ln_esca        VARCHAR2(5);
        ln_cnt_esca    NUMBER:=0;
        ln_amount_plp  NUMBER;
        ln_rate        NUMBER;
        ln_amount_calc NUMBER;
         ld_fec_inicio  DATE;
        p_pidm number;

    
    
    BEGIN
        execute immediate 'delete from SZTCALP where PIDM = pidm'; 
        --execute immediate 'delete from taismgr.tbraccd_tmp_bajas where tbraccd_pidm = pidm';
        commit;


        
        p_pidm:= null;
         p_pidm:= pidm;

            --
            BEGIN 
                SELECT distinct b.FECHA_INICIO 
                  INTO ld_fec_inicio
                  FROM tztprog b
                 WHERE b.pidm = p_pidm 
                   AND b.PROGRAMA = p_programa
                   And b.SP = p_sp;
               EXCEPTION WHEN OTHERS THEN 
               po_respuesta := 'Error al obtener Fecha Inicio'||sqlerrm;
            END;
            --
            --       

        BEGIN
        delete from taismgr.tbraccd_tmp_bajas where tbraccd_pidm = p_pidm;
        COMMIT;
        EXCEPTION WHEN OTHERS THEN 
               po_respuesta := 'Error al eliminar info bajas'||sqlerrm;
        
        END ;

        
        Begin 
        
            SELECT
                MAX(tbraccd_term_code)
            INTO lv_periodo
            FROM
                tbraccd
            WHERE tbraccd_pidm = pidm
              AND TBRACCD_PERIOD = p_periodo
              AND TBRACCD_STSP_KEY_SEQUENCE = p_sp
              AND tbraccd_feed_date IS NOT NULL;

        Exception
            When Others then 
                    ld_fec_inicio:= null;
                    dbms_output.put_line ('Error al recuperar lv_periodo ' ||sqlerrm);
                    
        End;

        Begin 

            SELECT UNIQUE B.SZVCAMP_CAMP_CODE||'_'||C.TBBDETC_TAXT_CODE
            INTO lv_campus
            FROM
                tbraccd A, tbbdetc c,  SZVCAMP B
            WHERE c.TBBDETC_DETAIL_CODE = a.TBRACCD_DETAIL_CODE
            and    substr(A.tbraccd_detail_code, 1, 2) = B.SZVCAMP_CAMP_ALT_CODE
            AND a.tbraccd_pidm = pidm
            AND a.TBRACCD_PERIOD = p_periodo
            AND a.tbraccd_term_code = lv_periodo
            AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
            AND a.tbraccd_detail_code IN (SELECT TZTNCD_CODE
                        FROM tztncd, tbbdetc
                        WHERE TZTNCD_concepto = 'Venta'
                        AND TBBDETC_detail_code = TZTNCD_CODE
                        AND TBBDETC_type_ind = 'C'
                        AND TBBDETC_detc_active_ind = 'Y'
                        AND TBBDETC_dcat_code = 'COL'
                        AND TBBDETC_taxt_code NOT IN ('GN','EC','CU','ES','ID','BA')                                
                   );
        
        Exception
            When Others then 
                    ld_fec_inicio:= null;
                    dbms_output.put_line ('Error al recuperar lv_campus ' ||sqlerrm);
                    
        End;

        ---AGREGAR excepciones para control de errores fn
            SELECT ZSTPARA_PARAM_VALOR
                    INTO ln_porcentaje
                    FROM zstpara
                   WHERE     zstpara_mapa_id = 'PORC_BAJA_MAT'
                   and ZSTPARA_PARAM_ID = lv_campus;

            --Validaciones para escalonados  
                  select count(1)
                   INTO ln_escalonado
                   from GORADID 
                  where GORADID_PIDM = pidm 
                    and GORADID_ADID_CODE in (SELECT ZSTPARA_PARAM_VALOR
                                                FROM zstpara
                                               WHERE zstpara_mapa_id = 'ETIQ_AJUST_MAT'
                                                 and ZSTPARA_PARAM_ID = lv_campus);
       
--Validacion escalonados             
       if ln_escalonado > 0 then
                                                BEGIN
        UPDATE TBRACCD a SET a.tbraccd_tran_number_paid = NULL
        WHERE   a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    AND a.tbraccd_feed_date IS NOT NULL
                    AND substr(a.tbraccd_detail_code, 3, 2) IN ('M3');
                    commit;
                                        P_DESAPLICA_PAGOS (pidm,p_periodo,lv_periodo) ;

        END;
                
                    FOR esca IN (
                SELECT UNIQUE
                    a.tbraccd_pidm pidm,a.tbraccd_effective_date,
                    b.tbbdetc_desc,
                    a.tbraccd_amount,
                    a.tbraccd_balance,
                    a.tbraccd_tran_number_paid,
                    a.TBRACCD_TRAN_NUMBER,
                    a.TBRACCD_CURR_CODE
                FROM
                    tbraccd a,
                    tbbdetc b
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                    AND a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    AND a.tbraccd_feed_date IS NOT NULL
                    AND substr(a.tbraccd_detail_code, 3, 2) IN ('M3')
            ) LOOP
    ln_cnt_esca := ln_cnt_esca+1;
                
            BEGIN
                SELECT
                    unique substr(tbraccd_term_code, 1, 2)
                INTO lv_codigo
                FROM
                    tbraccd
                WHERE
                    tbraccd_pidm = esca.pidm;

            END;

            BEGIN
                SELECT DISTINCT
                    tbbdetc_desc,
                    tbbdetc_detail_code
                INTO
                    lv_descripcion,
                    lv_codigo_d
                FROM
                    tbbdetc
                WHERE
                        1 = 1
                    AND  tbbdetc_detail_code = lv_codigo || 'ON';

            END;
                        

 
 dbms_output.put_line ('inserto escalonados');

                         INSERT INTO tbraccd_tmp_bajas
                         (TBRACCD_PIDM                
                                                ,TBRACCD_TRAN_NUMBER         
                                                ,TBRACCD_TERM_CODE           
                                                ,TBRACCD_DETAIL_CODE         
                                                ,TBRACCD_USER                
                                                ,TBRACCD_ENTRY_DATE          
                                                ,TBRACCD_AMOUNT              
                                                ,TBRACCD_BALANCE             
                                                ,TBRACCD_EFFECTIVE_DATE      
                                                ,TBRACCD_BILL_DATE           
                                                ,TBRACCD_DUE_DATE            
                                                ,TBRACCD_DESC                
                                                ,TBRACCD_RECEIPT_NUMBER      
                                                ,TBRACCD_TRAN_NUMBER_PAID    
                                                ,TBRACCD_CROSSREF_PIDM       
                                                ,TBRACCD_CROSSREF_NUMBER     
                                                ,TBRACCD_CROSSREF_DETAIL_CODE
                                                ,TBRACCD_SRCE_CODE           
                                                ,TBRACCD_ACCT_FEED_IND       
                                                ,TBRACCD_ACTIVITY_DATE       
                                                ,TBRACCD_SESSION_NUMBER      
                                                ,TBRACCD_CSHR_END_DATE       
                                                ,TBRACCD_CRN                 
                                                ,TBRACCD_CROSSREF_SRCE_CODE  
                                                ,TBRACCD_LOC_MDT             
                                                ,TBRACCD_LOC_MDT_SEQ         
                                                ,TBRACCD_RATE                
                                                ,TBRACCD_UNITS               
                                                ,TBRACCD_DOCUMENT_NUMBER     
                                                ,TBRACCD_TRANS_DATE          
                                                ,TBRACCD_PAYMENT_ID          
                                                ,TBRACCD_INVOICE_NUMBER      
                                                ,TBRACCD_STATEMENT_DATE      
                                                ,TBRACCD_INV_NUMBER_PAID     
                                                ,TBRACCD_CURR_CODE           
                                                ,TBRACCD_EXCHANGE_DIFF       
                                                ,TBRACCD_FOREIGN_AMOUNT      
                                                ,TBRACCD_LATE_DCAT_CODE      
                                                ,TBRACCD_FEED_DATE           
                                                ,TBRACCD_FEED_DOC_CODE       
                                                ,TBRACCD_ATYP_CODE           
                                                ,TBRACCD_ATYP_SEQNO          
                                                ,TBRACCD_CARD_TYPE_VR        
                                                ,TBRACCD_CARD_EXP_DATE_VR    
                                                ,TBRACCD_CARD_AUTH_NUMBER_VR 
                                                ,TBRACCD_CROSSREF_DCAT_CODE  
                                                ,TBRACCD_ORIG_CHG_IND        
                                                ,TBRACCD_CCRD_CODE           
                                                ,TBRACCD_MERCHANT_ID         
                                                ,TBRACCD_TAX_REPT_YEAR       
                                                ,TBRACCD_TAX_REPT_BOX        
                                                ,TBRACCD_TAX_AMOUNT          
                                                ,TBRACCD_TAX_FUTURE_IND      
                                                ,TBRACCD_DATA_ORIGIN         
                                                ,TBRACCD_CREATE_SOURCE       
                                                ,TBRACCD_CPDT_IND            
                                                ,TBRACCD_AIDY_CODE           
                                                ,TBRACCD_STSP_KEY_SEQUENCE   
                                                ,TBRACCD_PERIOD              
                                                ,TBRACCD_SURROGATE_ID        
                                                ,TBRACCD_VERSION             
                                                ,TBRACCD_USER_ID             
                                                ,TBRACCD_VPDI_CODE  
                                                ,TBRACCD_FECHA_INSERCION
                                                )                    
                            VALUES ( pidm,                          
                                    0, --ln_secuencia,                
                                     lv_periodo,                     
                                     lv_codigo_d,                      
                                     p_user,                           
                                     SYSDATE,                        
                                    esca.tbraccd_amount,                
                                    esca.tbraccd_amount,               
                                    esca.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     lv_descripcion,                 
                                     NULL,--CX.ORDEN,                       
                                     esca.TBRACCD_TRAN_NUMBER,--tran_paid                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'T',                            
                                     'Y',                            
                                     SYSDATE,                        
                                     0,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                    esca.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     esca.TBRACCD_CURR_CODE,                          
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     ld_fec_inicio,                
                                     1,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'BAJAS_MAT_ESCA',                 
                                     'BAJAS_MAT_ESCA',                 
                                     NULL,                           
                                     NULL,                           
                                     p_sp,                          
                                     p_periodo,--CX.PERIODO,                     
                                     0,                           
                                     0,                           
                                     p_user,                           
                                     0,
                                     trunc(SYSDATE)); 
                                     COMMIT;

            END LOOP;
       end if;
   -- fin de escalonados
                   
 ln_calculo := ln_porcentaje*no_materias;
        
            BEGIN
                SELECT sum(tbraccd_amount)
                INTO ln_amount_plp
                FROM
                    tbraccd a
                WHERE a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    AND a.tbraccd_feed_date IS NOT NULL
                    AND substr(a.tbraccd_detail_code, 1, 3) = 'PLP' 
                   AND a.TBRACCD_ENTRY_DATE IN (SELECT MAX (b.TBRACCD_ENTRY_DATE)
                                                  FROM tbraccd b
                                                 WHERE     b.tbraccd_pidm =
                                                              a.tbraccd_pidm
                                                       AND SUBSTR (B.tbraccd_detail_code,
                                                                   1,
                                                                   3) = 'PLP');
            END;
        
        SELECT TO_NUMBER(SUBSTR(SORLCUR_RATE_CODE,2,2))
                        INTO ln_rate
                        FROM sorlcur A
                        WHERE 1=1
                        AND a.sorlcur_lmod_code = 'LEARNER'
                        AND a.SORLCUR_PIDM =pidm
                        AND a.sorlcur_seqno = (SELECT MAX (a1.sorlcur_seqno)
                                                           FROM sorlcur A1
                                                           WHERE 1=1
                                                           AND a.sorlcur_pidm = a1.sorlcur_pidm
                                                           AND a.sorlcur_lmod_code = a1.sorlcur_lmod_code);


ln_amount_calc := ln_amount_plp / ln_rate;
 dbms_output.put_line ('no_materias'||no_materias);

   if no_materias >= 1 then 
                    FOR calc IN (
                SELECT UNIQUE
                    a.tbraccd_pidm pidm,a.tbraccd_effective_date,
                    b.tbbdetc_desc,
                    a.tbraccd_amount,
                    a.tbraccd_balance,
                    a.tbraccd_tran_number_paid,
                    a.TBRACCD_TRAN_NUMBER,
                    a.TBRACCD_CURR_CODE
                FROM
                    tbraccd a,
                    tbbdetc b
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                    AND a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    AND a.tbraccd_feed_date IS NOT NULL
                    AND a.tbraccd_detail_code IN (SELECT TZTNCD_CODE
                                                    FROM tztncd, tbbdetc
                                                    WHERE TZTNCD_concepto = 'Venta'
                                                    AND TBBDETC_detail_code = TZTNCD_CODE
                                                    AND TBBDETC_type_ind = 'C'
                                                    AND TBBDETC_detc_active_ind = 'Y'
                                                    AND TBBDETC_dcat_code = 'COL'
                                                    AND TBBDETC_taxt_code NOT IN ('GN','EC','CU','ES','ID','BA')                                
                       )
            ) LOOP
    ln_cnt := ln_cnt+1;
    
        dbms_output.put_line('calcpagos :'||calc.tbbdetc_desc);
    dbms_output.put_line('calcpagos2 :'||calc.tbraccd_amount);
    dbms_output.put_line('calcpagos3 :'||to_char(ln_porcentaje)||'%');
        dbms_output.put_line('calcpagos4 :'||ln_calculo);
    
    
                INSERT INTO SZTCALP (
                    fecha_vencimiento,
                    concepto,
                    monto_anterior,
                    pct_alta_baja,
                    monto_cajuste,
                    monto_accesorios,
                    pidm,
                    fec_calculo
                ) VALUES (
                    calc.tbraccd_effective_date,
                    calc.tbbdetc_desc,
                    ln_amount_calc,
                    --to_char(ln_porcentaje)||'%',
                    to_char(ln_porcentaje*no_materias)||'%',
                    round((ln_amount_calc - ( ( ln_amount_calc* ln_calculo ) / 100 ))),
                    NULL,
                    pidm,
                    sysdate
                );
                commit;
                
            BEGIN
                SELECT
                    unique substr(tbraccd_term_code, 1, 2)
                INTO lv_codigo
                FROM
                    tbraccd
                WHERE
                    tbraccd_pidm = calc.pidm;

            END;

            BEGIN
                SELECT DISTINCT
                    tbbdetc_desc,
                    tbbdetc_detail_code
                INTO
                    lv_descripcion,
                    lv_codigo_d
                FROM
                    tbbdetc
                WHERE
                        1 = 1
                    AND  tbbdetc_detail_code = lv_codigo || 'Y2';

            END;
                        

                        
if ln_cnt <= 1 then 
dbms_output.put_line('ln_cnt1 :'||ln_cnt);
    if calc.tbraccd_balance = 0 then 
    ln_trans_paid := null;
    elsif calc.tbraccd_balance < (calc.tbraccd_amount - ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
    ln_trans_paid := null;
    dbms_output.put_line('ln_cnt2 :'||ln_cnt);
    elsif calc.tbraccd_balance >= (calc.tbraccd_amount - ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
    dbms_output.put_line('ln_cnt3 :'||ln_cnt);
    ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
    end if;

elsif ln_cnt > 1 then 
dbms_output.put_line('ln_cnt4 :'||ln_cnt);
ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
end if;
--general
    if calc.tbraccd_balance = 0 then 
    ln_trans_paid := null;
    elsif calc.tbraccd_balance >= (calc.tbraccd_amount - ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
    dbms_output.put_line('ln_Y2 :'||ln_cnt);
    ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
    end if;
 dbms_output.put_line ('inserto tbraccd_tmp_bajas');

                         INSERT INTO tbraccd_tmp_bajas
                         (TBRACCD_PIDM                
                                                ,TBRACCD_TRAN_NUMBER         
                                                ,TBRACCD_TERM_CODE           
                                                ,TBRACCD_DETAIL_CODE         
                                                ,TBRACCD_USER                
                                                ,TBRACCD_ENTRY_DATE          
                                                ,TBRACCD_AMOUNT              
                                                ,TBRACCD_BALANCE             
                                                ,TBRACCD_EFFECTIVE_DATE      
                                                ,TBRACCD_BILL_DATE           
                                                ,TBRACCD_DUE_DATE            
                                                ,TBRACCD_DESC                
                                                ,TBRACCD_RECEIPT_NUMBER      
                                                ,TBRACCD_TRAN_NUMBER_PAID    
                                                ,TBRACCD_CROSSREF_PIDM       
                                                ,TBRACCD_CROSSREF_NUMBER     
                                                ,TBRACCD_CROSSREF_DETAIL_CODE
                                                ,TBRACCD_SRCE_CODE           
                                                ,TBRACCD_ACCT_FEED_IND       
                                                ,TBRACCD_ACTIVITY_DATE       
                                                ,TBRACCD_SESSION_NUMBER      
                                                ,TBRACCD_CSHR_END_DATE       
                                                ,TBRACCD_CRN                 
                                                ,TBRACCD_CROSSREF_SRCE_CODE  
                                                ,TBRACCD_LOC_MDT             
                                                ,TBRACCD_LOC_MDT_SEQ         
                                                ,TBRACCD_RATE                
                                                ,TBRACCD_UNITS               
                                                ,TBRACCD_DOCUMENT_NUMBER     
                                                ,TBRACCD_TRANS_DATE          
                                                ,TBRACCD_PAYMENT_ID          
                                                ,TBRACCD_INVOICE_NUMBER      
                                                ,TBRACCD_STATEMENT_DATE      
                                                ,TBRACCD_INV_NUMBER_PAID     
                                                ,TBRACCD_CURR_CODE           
                                                ,TBRACCD_EXCHANGE_DIFF       
                                                ,TBRACCD_FOREIGN_AMOUNT      
                                                ,TBRACCD_LATE_DCAT_CODE      
                                                ,TBRACCD_FEED_DATE           
                                                ,TBRACCD_FEED_DOC_CODE       
                                                ,TBRACCD_ATYP_CODE           
                                                ,TBRACCD_ATYP_SEQNO          
                                                ,TBRACCD_CARD_TYPE_VR        
                                                ,TBRACCD_CARD_EXP_DATE_VR    
                                                ,TBRACCD_CARD_AUTH_NUMBER_VR 
                                                ,TBRACCD_CROSSREF_DCAT_CODE  
                                                ,TBRACCD_ORIG_CHG_IND        
                                                ,TBRACCD_CCRD_CODE           
                                                ,TBRACCD_MERCHANT_ID         
                                                ,TBRACCD_TAX_REPT_YEAR       
                                                ,TBRACCD_TAX_REPT_BOX        
                                                ,TBRACCD_TAX_AMOUNT          
                                                ,TBRACCD_TAX_FUTURE_IND      
                                                ,TBRACCD_DATA_ORIGIN         
                                                ,TBRACCD_CREATE_SOURCE       
                                                ,TBRACCD_CPDT_IND            
                                                ,TBRACCD_AIDY_CODE           
                                                ,TBRACCD_STSP_KEY_SEQUENCE   
                                                ,TBRACCD_PERIOD              
                                                ,TBRACCD_SURROGATE_ID        
                                                ,TBRACCD_VERSION             
                                                ,TBRACCD_USER_ID             
                                                ,TBRACCD_VPDI_CODE  
                                                ,TBRACCD_FECHA_INSERCION
                                                )                    
                            VALUES ( pidm,                          
                                    0, --ln_secuencia,                
                                     lv_periodo,                     
                                     lv_codigo_d,                      
                                     p_user,                           
                                     SYSDATE,                        
                                    ln_amount_calc -(ln_amount_calc - ( ( ln_amount_calc * ln_calculo ) / 100 )),                
                                    ln_amount_calc -(ln_amount_calc - ( ( ln_amount_calc * ln_calculo ) / 100 )),               
                                    calc.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     lv_descripcion,                 
                                     NULL,--CX.ORDEN,                       
                                     ln_trans_paid,--tran_paid                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'T',                            
                                     'Y',                            
                                     SYSDATE,                        
                                     0,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                    calc.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     calc.TBRACCD_CURR_CODE,                          
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     ld_fec_inicio,                
                                     1,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'BAJAS_MAT',                 
                                     'BAJAS_MAT',                 
                                     NULL,                           
                                     NULL,                           
                                     p_sp,                          
                                     p_periodo,--CX.PERIODO,                     
                                     0,                           
                                     0,                           
                                     p_user,                           
                                     0,
                                     trunc(SYSDATE)); 
                                     COMMIT;

            po_respuesta := '00';
END LOOP;
FOR ACC IN (SELECT UNIQUE
                    a.tbraccd_pidm pidm,a.tbraccd_effective_date,
                    b.tbbdetc_desc,
                    a.tbraccd_amount
                FROM
                    tbraccd a,
                    tbbdetc b,
                    TZTINC c
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                        AND  a.tbraccd_detail_code = c.codigo 
                    AND a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo)
                     LOOP
                INSERT INTO SZTCALP (
                    fecha_vencimiento,
                    concepto,
                    monto_anterior,
                    pct_alta_baja,
                    monto_cajuste,
                    monto_accesorios,
                    pidm,
                    fec_calculo
                ) VALUES (
                    acc.tbraccd_effective_date,
                    acc.tbbdetc_desc,
                    null,
                    null,
                    null,
                    round(acc.tbraccd_amount),
                    pidm,
                    sysdate
                );
                commit;
                end loop;
--end if;
END IF;

   EXCEPTION WHEN OTHERS THEN 
   po_respuesta := 'Error al proceso general dina'||sqlerrm;     
END p_baja_materias_dina;
    
    FUNCTION f_calc_baja_materias (
        p_pidm        IN NUMBER,
        p_no_materias NUMBER,
        p_periodo varchar2,
        p_user VARCHAR2,
        p_sp VARCHAR2,
        p_programa VARCHAR2
    ) RETURN pkg_alta_baja_materias.cursor_matbajas AS
        c_bajmat     pkg_alta_baja_materias.cursor_matbajas;
        po_respuesta VARCHAR2(10);
        ln_valida_paq  NUMBER;
    BEGIN
    
    SELECT COUNT(1) 
   INTO ln_valida_paq
    FROM GORADID 
    WHERE GORADID_PIDM = p_pidm  
    AND GORADID_ADID_CODE= 'DINA';
    
    IF ln_valida_paq >= 1 THEN 
         pkg_alta_baja_materias.p_baja_materias_dina (p_pidm,p_no_materias, p_periodo,p_user,p_sp,p_programa, po_respuesta);
        ELSE
         pkg_alta_baja_materias.p_baja_materias_face (p_pidm, p_no_materias,p_periodo,p_user,p_sp,p_programa, po_respuesta);
    END IF;

        BEGIN
            OPEN c_bajmat FOR SELECT UNIQUE FECHA_VENCIMIENTO ,
                                                   CONCEPTO ,
                                                   MONTO_ANTERIOR ,
                                                   NVL(PCT_ALTA_BAJA,0) PCT_ALTA_BAJA ,
                                                   MONTO_CAJUSTE ,
                                                   MONTO_ACCESORIOS 
                                                FROM
                                                    SZTCALP
                              WHERE
                                      pidm = p_pidm ORDER BY FECHA_VENCIMIENTO;

            RETURN ( c_bajmat );
        END;

    END f_calc_baja_materias;



 FUNCTION f_calc_baja_materias_2 (
        p_pidm        IN VARCHAR2
    ) RETURN pkg_alta_baja_materias.cursor_CALCR_out AS
        C_CALCR_OUT     pkg_alta_baja_materias.cursor_CALCR_out;
        
        ln_amount_acc NUMBER := 0;
        
        
        
    BEGIN

        BEGIN
        
           SELECT F_CALC_AMOUNT_ACC ( P_PIDM ) 
             INTO ln_amount_acc
             FROM dual;
                                                                                                        
            OPEN C_CALCR_OUT 
            FOR 
              SELECT UNIQUE
                     LTRIM(UPPER (
                        TO_CHAR (FECHA_VENCIMIENTO, 'Month', 'nls_date_language=spanish')))
                        MES,
                     SUM (NVL (MONTO_CAJUSTE, 0) + NVL (MONTO_ACCESORIOS, 0)) + NVL(ln_amount_acc,0) MONTO_PAGAR ,
                     FECHA_VENCIMIENTO
                FROM SZTCALP
               WHERE pidm = p_pidm
            GROUP BY FECHA_VENCIMIENTO
            ORDER BY FECHA_VENCIMIENTO;
            --ORDER BY TO_dATE(MES,'MM') ;

            RETURN ( C_CALCR_OUT );
        END;

    END f_calc_baja_materias_2;
   
   
      PROCEDURE P_EDO_CTA_BAJA_MATERIAS (P_PIDM NUMBER) 
      AS
              ln_secuencia   NUMBER;
              ln_escalonado  NUMBER;
      BEGIN

FOR TBR IN (select
                    tbraccd_pidm,
                    tbraccd_tran_number,
                    tbraccd_term_code,
                    tbraccd_detail_code,
                    tbraccd_user,
                    tbraccd_entry_date,
                    round(tbraccd_amount,0) as tbraccd_amount ,
                    CASE 
                        WHEN substr(tbraccd_detail_code, 3, 2) IN ( 'Y2' ) THEN 
                        to_number('-'||round(tbraccd_balance,0))
                        WHEN substr(tbraccd_detail_code, 3, 2) IN ( 'ON' ) THEN
                        round(tbraccd_balance,0)
                    END tbraccd_balance,
                    tbraccd_effective_date,
                    tbraccd_bill_date,
                    tbraccd_due_date,
                    tbraccd_desc,
                    tbraccd_receipt_number,
                    tbraccd_tran_number_paid,
                    tbraccd_crossref_pidm,
                    tbraccd_crossref_number,
                    tbraccd_crossref_detail_code,
                    tbraccd_srce_code,
                    tbraccd_acct_feed_ind,
                    tbraccd_activity_date,
                    tbraccd_session_number,
                    tbraccd_cshr_end_date,
                    tbraccd_crn,
                    tbraccd_crossref_srce_code,
                    tbraccd_loc_mdt,
                    tbraccd_loc_mdt_seq,
                    tbraccd_rate,
                    tbraccd_units,
                    tbraccd_document_number,
                    tbraccd_trans_date,
                    tbraccd_payment_id,
                    tbraccd_invoice_number,
                    tbraccd_statement_date,
                    tbraccd_inv_number_paid,
                    tbraccd_curr_code,
                    tbraccd_exchange_diff,
                    tbraccd_foreign_amount,
                    tbraccd_late_dcat_code,
                    tbraccd_feed_date,
                    tbraccd_feed_doc_code,
                    tbraccd_atyp_code,
                    tbraccd_atyp_seqno,
                    tbraccd_card_type_vr,
                    tbraccd_card_exp_date_vr,
                    tbraccd_card_auth_number_vr,
                    tbraccd_crossref_dcat_code,
                    tbraccd_orig_chg_ind,
                    tbraccd_ccrd_code,
                    tbraccd_merchant_id,
                    tbraccd_tax_rept_year,
                    tbraccd_tax_rept_box,
                    tbraccd_tax_amount,
                    tbraccd_tax_future_ind,
                    tbraccd_data_origin,
                    tbraccd_create_source,
                    tbraccd_cpdt_ind,
                    tbraccd_aidy_code,
                    tbraccd_stsp_key_sequence,
                    tbraccd_period,
                    tbraccd_surrogate_id,
                    tbraccd_version,
                    tbraccd_user_id,
                    tbraccd_vpdi_code    
                    from TBRACCD_TMP_BAJAS  where TBRACCD_PIDM = p_pidm )
                    LOOP

            ln_secuencia := 0;
            BEGIN
                SELECT
                    MAX(tbraccd_tran_number)+1
                INTO ln_secuencia
                FROM
                    tbraccd
                WHERE
                    tbraccd_pidm = p_pidm;

            EXCEPTION
                WHEN OTHERS THEN
                    ln_secuencia := 0;
            END;

                                    -- Entra 1er. cargo
                INSERT INTO TAISMGR.TBRACCD (
                    tbraccd_pidm,
                    tbraccd_tran_number,
                    tbraccd_term_code,
                    tbraccd_detail_code,
                    tbraccd_user,
                    tbraccd_entry_date,
                    tbraccd_amount,
                    tbraccd_balance,
                    tbraccd_effective_date,
                    tbraccd_bill_date,
                    tbraccd_due_date,
                    tbraccd_desc,
                    tbraccd_receipt_number,
                    tbraccd_tran_number_paid,
                    tbraccd_crossref_pidm,
                    tbraccd_crossref_number,
                    tbraccd_crossref_detail_code,
                    tbraccd_srce_code,
                    tbraccd_acct_feed_ind,
                    tbraccd_activity_date,
                    tbraccd_session_number,
                    tbraccd_cshr_end_date,
                    tbraccd_crn,
                    tbraccd_crossref_srce_code,
                    tbraccd_loc_mdt,
                    tbraccd_loc_mdt_seq,
                    tbraccd_rate,
                    tbraccd_units,
                    tbraccd_document_number,
                    tbraccd_trans_date,
                    tbraccd_payment_id,
                    tbraccd_invoice_number,
                    tbraccd_statement_date,
                    tbraccd_inv_number_paid,
                    tbraccd_curr_code,
                    tbraccd_exchange_diff,
                    tbraccd_foreign_amount,
                    tbraccd_late_dcat_code,
                    tbraccd_feed_date,
                    tbraccd_feed_doc_code,
                    tbraccd_atyp_code,
                    tbraccd_atyp_seqno,
                    tbraccd_card_type_vr,
                    tbraccd_card_exp_date_vr,
                    tbraccd_card_auth_number_vr,
                    tbraccd_crossref_dcat_code,
                    tbraccd_orig_chg_ind,
                    tbraccd_ccrd_code,
                    tbraccd_merchant_id,
                    tbraccd_tax_rept_year,
                    tbraccd_tax_rept_box,
                    tbraccd_tax_amount,
                    tbraccd_tax_future_ind,
                    tbraccd_data_origin,
                    tbraccd_create_source,
                    tbraccd_cpdt_ind,
                    tbraccd_aidy_code,
                    tbraccd_stsp_key_sequence,
                    tbraccd_period,
                    tbraccd_surrogate_id,
                    tbraccd_version,
                    tbraccd_user_id,
                    tbraccd_vpdi_code                    
                ) values(
                tbr.tbraccd_pidm,
                    ln_secuencia,
                    tbr.tbraccd_term_code,
                    tbr.tbraccd_detail_code,
                    tbr.tbraccd_user,
                    tbr.tbraccd_entry_date,
                    tbr.tbraccd_amount,
                    tbr.tbraccd_balance,
                    tbr.tbraccd_effective_date,
                    tbr.tbraccd_bill_date,
                    tbr.tbraccd_due_date,
                    tbr.tbraccd_desc,
                    tbr.tbraccd_receipt_number,
                    tbr.tbraccd_tran_number_paid,
                    tbr.tbraccd_crossref_pidm,
                    tbr.tbraccd_crossref_number,
                    tbr.tbraccd_crossref_detail_code,
                    tbr.tbraccd_srce_code,
                    tbr.tbraccd_acct_feed_ind,
                    tbr.tbraccd_activity_date,
                    tbr.tbraccd_session_number,
                    tbr.tbraccd_cshr_end_date,
                    tbr.tbraccd_crn,
                    tbr.tbraccd_crossref_srce_code,
                    tbr.tbraccd_loc_mdt,
                    tbr.tbraccd_loc_mdt_seq,
                    tbr.tbraccd_rate,
                    tbr.tbraccd_units,
                    tbr.tbraccd_document_number,
                    tbr.tbraccd_trans_date,
                    tbr.tbraccd_payment_id,
                    tbr.tbraccd_invoice_number,
                    tbr.tbraccd_statement_date,
                    tbr.tbraccd_inv_number_paid,
                    tbr.tbraccd_curr_code,
                    tbr.tbraccd_exchange_diff,
                    tbr.tbraccd_foreign_amount,
                    tbr.tbraccd_late_dcat_code,
                    tbr.tbraccd_feed_date,
                    tbr.tbraccd_feed_doc_code,
                    tbr.tbraccd_atyp_code,
                    tbr.tbraccd_atyp_seqno,
                    tbr.tbraccd_card_type_vr,
                    tbr.tbraccd_card_exp_date_vr,
                    tbr.tbraccd_card_auth_number_vr,
                    tbr.tbraccd_crossref_dcat_code,
                    tbr.tbraccd_orig_chg_ind,
                    tbr.tbraccd_ccrd_code,
                    tbr.tbraccd_merchant_id,
                    tbr.tbraccd_tax_rept_year,
                    tbr.tbraccd_tax_rept_box,
                    tbr.tbraccd_tax_amount,
                    tbr.tbraccd_tax_future_ind,
                    tbr.tbraccd_data_origin,
                    tbr.tbraccd_create_source,
                    tbr.tbraccd_cpdt_ind,
                    tbr.tbraccd_aidy_code,
                    tbr.tbraccd_stsp_key_sequence,
                    tbr.tbraccd_period,
                    tbr.tbraccd_surrogate_id,
                    tbr.tbraccd_version,
                    tbr.tbraccd_user_id,
                    tbr.tbraccd_vpdi_code);
                    commit;
                    end loop;
                    
       -- execute immediate 'delete from taismgr.tbraccd_tmp_bajas where tbraccd_pidm = P_PIDM';
        BEGIN
        delete from taismgr.tbraccd_tmp_bajas where tbraccd_pidm = p_pidm;
        COMMIT;
        EXCEPTION WHEN OTHERS THEN 
        null;        
        END ;        
		--commit;
            END P_EDO_CTA_BAJA_MATERIAS;
      

   PROCEDURE P_DESAPLICA_PAGOS (P_PIDM NUMBER, P_PERIODO1 VARCHAR2, P_PERIODO2 VARCHAR2 ) 
   AS
   BEGIN 
  
  FOR X IN ( 
  
                  SELECT A.SPRIDEN_ID,
                         B.TBRACCD_PIDM,
                         B.TBRACCD_TRAN_NUMBER,
                         B.TBRACCD_DETAIL_CODE,
                         B.tbraccd_amount,
                         B.tbraccd_balance,
                         C.TBBDETC_TYPE_IND,
                       case 
                            When C.TBBDETC_TYPE_IND ='C' then 
                                     B.tbraccd_amount
                             When C.TBBDETC_TYPE_IND ='P' then
                                     B.tbraccd_amount * -1
                        End Monto    
                  FROM SPRIDEN A, TBRACCD B, tbbdetc C 
                  WHERE    B.TBRACCD_PIDM = A.SPRIDEN_PIDM
                    AND C.TBBDETC_DETAIL_CODE = B.tbraccd_detail_code
                    AND B.tbraccd_pidm = P_PIDM
                    AND B.TBRACCD_PERIOD = p_periodo1
                    AND B.tbraccd_term_code = p_periodo2
                    AND A.SPRIDEN_CHANGE_IND IS NULL
                    AND B.tbraccd_feed_date IS NOT NULL
                    AND substr(B.tbraccd_detail_code, 3, 2) IN ('M3')
                       order by 3
   )LOOP
   
     BEGIN
           
            Update tbraccd
              set tbraccd_balance = x.monto
            where tbraccd_pidm  = x.tbraccd_pidm
            and tbraccd_tran_number =  x.tbraccd_tran_number;
      
     Exception
        When Others then 
            null;       
     END;
     
     
            DELETE TVRACCD
            where TVRACCD_pidm = x.TBRACCD_PIDM;

            delete tvrappl
            where tvrappl_pidm = x.TBRACCD_PIDM;

            delete tbrappl
            where tbrappl_pidm = x.TBRACCD_PIDM;     
 
       
   END LOOP;
  
  COMMIT;
  
END P_DESAPLICA_PAGOS;
 
    FUNCTION f_datos_generales_out( p_pidm     IN NUMBER, p_programa VARCHAR2) RETURN pkg_alta_baja_materias.cursor_out AS
        c_out pkg_alta_baja_materias.cursor_out;
    BEGIN
        BEGIN
            OPEN c_out FOR 
                            select distinct a.matricula, b.spriden_first_name || ' '|| b.spriden_last_name  nombre, a.programa,
                            pkg_utilerias.f_correo(a.pidm, 'PRIN') Correo,
                            trim (substr (pkg_utilerias.f_jornada(a.pidm, a.sp),1,4)) Jornada,
                            trim (substr (pkg_utilerias.f_jornada(a.pidm, a.sp),5,50)) atributo_jornada,
                            pkg_utilerias.f_calcula_rate (a.pidm, a.programa) Rate,
                            (select stvrate_Desc from stvrate where STVRATE_CODE= pkg_utilerias.f_calcula_rate (a.pidm, a.programa) )DESC_RATE,
                            c.SZTDTEC_PROGRAMA_COMP NOMBRE_PROGRAMA,
                            a.sp SP
                            from tztprog a
                            join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
                            join sztdtec c on c.SZTDTEC_PROGRAM = a.programa and c.SZTDTEC_TERM_CODE= a.CTLG
                            where 1=1
                            and a.pidm = p_pidm
                            and a.programa = p_programa
                            and a.estatus ='MA';
            
--                                        SELECT DISTINCT
--                                              d.spriden_id matricula,
--                                              d.spriden_first_name || ' '|| d.spriden_last_name  nombre,
--                                              a.sorlcur_program   programa,
--                                              g.goremal_email_address correo,
--                                              jor.jornada             jornada,
--                                              jor.desc_jornada        atributo_jornada,
--                                              b.sgbstdn_rate_code     rate,
--                                              (SELECT DISTINCT stvrate_desc
--                                                  FROM stvrate
--                                                  WHERE stvrate_code = b.sgbstdn_rate_code
--                                                  AND ROWNUM = 1 )desc_rate,
--                                                  SZTDTEC_PROGRAMA_COMP Nombre_programa,
--                                                  sp SP
--                                          FROM
--                                              sorlcur a,
--                                              sgbstdn b,
--                                              spriden d,
--                                              sztdtec e,
--                                              goremal g,
--                                              tztprog h,
--                                              ( SELECT t.sgrsatt_term_code_eff,
--                                                       t.sgrsatt_atts_code jornada,
--                                                       j2.stvatts_desc     desc_jornada,
--                                                       t.sgrsatt_pidm      atts_pidm,
--                                                       t.sgrsatt_stsp_key_sequence
--                                                  FROM sgrsatt t,stvatts j2
--                                                  WHERE j2.stvatts_code = t.sgrsatt_atts_code
--                                                  AND REGEXP_LIKE ( j2.stvatts_code, '^[0-9]' )
--                                                  AND REGEXP_LIKE ( t.sgrsatt_atts_code, '^[0-9]' )
--                                                  AND substr(t.sgrsatt_term_code_eff, 5, 2) NOT IN ( 81, 82, 83 )
--                                                  AND t.sgrsatt_term_code_eff = ( SELECT MAX(sgrsatt_term_code_eff)
--                                                                                       FROM sgrsatt tt
--                                                                                       WHERE tt.sgrsatt_pidm = t.sgrsatt_pidm
--                                                                                      AND tt.sgrsatt_stsp_key_sequence = t.sgrsatt_stsp_key_sequence
--                                                                                     --  AND substr(tt.sgrsatt_term_code_eff, 5, 2) NOT IN ( 81, 82, 83 )
--                                                                                     --  AND REGEXP_LIKE ( tt.sgrsatt_atts_code,'^[0-9]' )
--                                                                                 )
----                                                 AND t.sgrsatt_stsp_key_sequence = ( SELECT MAX(sgrsatt_stsp_key_sequence)
----                                                                                          FROM sgrsatt t1
----                                                                                          WHERE t1.sgrsatt_pidm = t.sgrsatt_pidm
----                                                                                          AND t1.sgrsatt_term_code_eff = t.sgrsatt_term_code_eff
----                                                                                          AND substr(t1.sgrsatt_term_code_eff, 5, 2) NOT IN ( 81, 82, 83 )
----                                                                                          AND REGEXP_LIKE ( t1.sgrsatt_atts_code, '^[0-9]' )
----                                                                                    )
--                                                 )jor
--                               WHERE jor.atts_pidm = a.sorlcur_pidm
--                               And jor.sgrsatt_stsp_key_sequence = h.sp
--                               AND a.sorlcur_lmod_code = 'LEARNER'
--                               AND a.sorlcur_cact_code = 'ACTIVE'
--                               AND a.sorlcur_seqno IN ( SELECT MAX(a1.sorlcur_seqno)
--                                                               FROM sorlcur a1
--                                                               WHERE a.sorlcur_pidm = a1.sorlcur_pidm
--                                                               AND a1.sorlcur_lmod_code = 'LEARNER'
--                                                               AND a.sorlcur_program = a1.sorlcur_program
--                                                               AND a.sorlcur_lmod_code = a1.sorlcur_lmod_code
--                                                      )
--                               AND a.sorlcur_pidm = g.goremal_pidm
--                               AND a.sorlcur_pidm = b.sgbstdn_pidm
--                               And a.sorlcur_program = b.SGBSTDN_PROGRAM_1 
--                               AND b.sgbstdn_stst_code = 'MA'
--                               And b.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
--                                                             from SGBSTDN b1
--                                                             Where b1.sgbstdn_pidm = b.sgbstdn_pidm
--                                                             And b1.SGBSTDN_PROGRAM_1 = b.SGBSTDN_PROGRAM_1
--                                                             And b1.sgbstdn_stst_code = b.sgbstdn_stst_code
--                                                             )
--                               AND e.sztdtec_program = a.sorlcur_program
--                               AND a.sorlcur_term_code_ctlg = e.sztdtec_term_code
--                               AND d.spriden_pidm = sgbstdn_pidm
--                               AND g.goremal_emal_code = 'PRIN'
--                               AND a.sorlcur_pidm = p_pidm
--                               AND a.sorlcur_program = p_programa
--                               AND d.spriden_change_ind IS NULL
--                               And d.spriden_pidm = h.pidm
--                               And h.programa = p_programa
--                               And h.estatus ='MA';

            RETURN ( c_out );
        END;
    END f_datos_generales_out;

    FUNCTION f_materias_alta_out(p_pidm IN NUMBER ) RETURN pkg_alta_baja_materias.cursor_matact_out AS
        c_matact_out pkg_alta_baja_materias.cursor_matact_out;
        l_regla      NUMBER;
    BEGIN
        BEGIN
            SELECT  as_alumnos_no_regla
            INTO l_regla
            FROM  as_alumnos,sorlcur a
            WHERE 1 = 1
            AND sgbstdn_pidm = a.sorlcur_pidm
            AND fecha_inicio = a.sorlcur_start_date (+)
            AND a.sorlcur_lmod_code = 'LEARNER'
            AND a.sorlcur_cact_code = 'ACTIVE'
            AND a.sorlcur_seqno IN (SELECT MAX(a1.sorlcur_seqno)
                                    FROM  sorlcur a1
                                    WHERE a.sorlcur_pidm = a1.sorlcur_pidm
                                    AND a1.sorlcur_lmod_code = 'LEARNER'
                                    AND a.sorlcur_program = a1.sorlcur_program
                                    AND a.sorlcur_lmod_code = a1.sorlcur_lmod_code
                                    )
            AND sgbstdn_pidm = p_pidm;

        END;

        BEGIN
            OPEN c_matact_out FOR SELECT materia_legal,
                                         secuencia
                                         FROM( SELECT DISTINCT clave_materia_agp materia_legal,
                                               subj_code || crse_numb materia_hija,
                                               secuencia,
                                               (SELECT scrsyln_long_course_title
                                                  FROM scrsyln
                                                  WHERE 1 = 1
                                                  AND scrsyln_subj_code || scrsyln_crse_numb = clave_materia_agp
                                               )descripcion
                                              FROM rel_alumnos_x_asignar
                                              WHERE 1 = 1
                                              AND rel_alumnos_x_asignar_no_regla = l_regla
                                              AND svrproy_pidm = p_pidm
                                              AND EXISTS ( SELECT sztgpme_subj_crse
                                                            FROM sztgpme
                                                            WHERE 1 = 1
                                                            AND sztgpme_no_regla = l_regla
                                                            AND sztgpme_subj_crse = clave_materia_agp
                                                            AND sztgpme_activar_grupo = 'S'
                                                          )
                                           UNION
                                           SELECT DISTINCT
                                               sztalmt_materia       materia_legal,
                                               sztalmt_materia       materia_hija,
                                               sztalmt_secuencia + 5 secuencia,
                                               (SELECT scrsyln_long_course_title
                                                FROM scrsyln
                                                WHERE 1 = 1
                                                AND scrsyln_subj_code || scrsyln_crse_numb = sztalmt_materia
                                               )descripcion
                                           FROM rel_programaxalumno
                                           JOIN goradid ON goradid_pidm = sgbstdn_pidm
                                           JOIN sztalmt ON sztalmt_alianza = goradid_adid_code AND sztalmt_nivel = nivel
                                           WHERE rel_programaxalumno_no_regla = l_regla
                                           AND sgbstdn_pidm = p_pidm
                                           ORDER BY 3)
                                  WHERE 1 = 1
                                  AND ROWNUM <= 4 - ( SELECT  f_consulta_activos(l_regla, p_pidm)
                                                      FROM dual );

        END;

    END;

    FUNCTION f_materias_baja_out( p_pidm IN NUMBER, P_sp in Number ) RETURN pkg_alta_baja_materias.cursor_matbaj_out AS
        c_matbaj_out pkg_alta_baja_materias.cursor_matbaj_out;
        l_regla      NUMBER := 0;
    BEGIN
        BEGIN
               SELECT DISTINCT sztprono_no_regla
               INTO l_regla
               FROM sztprono,
                   sorlcur a
                WHERE 1 = 1
                AND sztprono_pidm = a.sorlcur_pidm
                AND sztprono_fecha_inicio = a.sorlcur_start_date (+)
                And SZTPRONO_STUDY_PATH = P_sp
                AND sztprono_program = a.sorlcur_program
                AND sztprono_envio_moodl = 'S'
                AND sztprono_envio_horarios = 'S'
                AND a.sorlcur_lmod_code = 'LEARNER'
                AND a.sorlcur_cact_code = 'ACTIVE'
                AND a.sorlcur_seqno IN (SELECT MAX(a1.sorlcur_seqno)
                                         FROM sorlcur a1
                                         WHERE a.sorlcur_pidm = a1.sorlcur_pidm
                                         AND a1.sorlcur_lmod_code = 'LEARNER'
                                         AND a.sorlcur_program = a1.sorlcur_program
                                         AND a.sorlcur_lmod_code = a1.sorlcur_lmod_code
                                        )
                AND sztprono_pidm = p_pidm;

        END;

         BEGIN
            
            OPEN C_MATBAJ_OUT FOR SELECT MATERIA,GRUPO,DESCRIPCION,max_num_mat,SECUENCIA,PERIODO,PARTE_PERIODO
                                     FROM TABLE(BANINST1.PKG_ALTA_BAJA_MATERIAS.F_MAT_ACT_BAJA(P_PIDM,l_regla,P_sp)) ;
                    --                where grupo not like '%X'   ;  
       END;   
       
    RETURN (C_MATBAJ_OUT);
    END f_materias_baja_out;

 FUNCTION f_MAT_ACT (p_pidm number,p_regla number, p_sp in number) return t_tab PIPELINED
    IS l_row t_grupo_sinc;

    
    begin
           
         for c in (
              select distinct  x.MATERIA,
                                   x.GRUPO,
                                   x.DESCRIPCION,
                                   x.SZSTUME_RSTS_CODE,
                                   SZSTUME_SEQ_NO,
                                   x.max_num_mat,
                                   x.periodo,
                                   x.Parte_Periodo,
                                   x.Secuencia_utel Secuencia
                    from
                    (
                      SELECT DISTINCT  SZSTUME_SUBJ_CODE MATERIA,
                                     CASE WHEN SZSTUME_TERM_NRC LIKE '%X' THEN
                                            SUBSTR(SZSTUME_TERM_NRC,-3,3)
                                          ELSE 
                                            SUBSTR(SZSTUME_TERM_NRC,-2)    
                                     END GRUPO ,
                                     SZSTUME_RSTS_CODE,
                                     SZSTUME_SEQ_NO,
                                     DECODE(SZSTUME_GRDE_CODE_FINAL,0,NULL,SZSTUME_GRDE_CODE_FINAL) CALIFICACION,
                                     SZTPRONO_PROGRAM PROGRAMA,
                                     SZTPRONO_TERM_CODE periodo,
                                     SZTPRONO_PTRM_CODE Parte_Periodo,
                                     (SELECT SCRSYLN_LONG_COURSE_TITLE
                                      FROM SCRSYLN
                                      WHERE 1 = 1
                                      AND SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB  =SZSTUME_SUBJ_CODE) DESCRIPCION,
                                      (SELECT SUBSTR(J.SGRSATT_ATTS_CODE,4,1)MAX_NUM_MAT
                                        FROM SGRSATT J
                                        WHERE 1=1
                                        AND J.SGRSATT_PIDM=ME1.SZSTUME_PIDM
                                        AND J.SGRSATT_TERM_CODE_EFF=(SELECT MAX (A.SGRSATT_TERM_CODE_EFF)
                                                                          FROM SGRSATT A
                                                                          WHERE 1=1
                                                                          AND A.SGRSATT_PIDM=J.SGRSATT_PIDM)
--                                                                          AND A.SGRSATT_STSP_KEY_SEQUENCE=J.SGRSATT_STSP_KEY_SEQUENCE)
                                          AND ROWNUM=1   )MAX_NUM_MAT,
                                     ONO.SZTPRONO_SECUENCIA SECUENCIA,
                                     to_number(al.SECUENCIA) Secuencia_utel       
                    FROM SZSTUME ME1,
                         SZTPRONO ONO,
                         SFRSTCR,
                         REL_ALUMNOS_X_ASIGNAR al
                    WHERE 1 = 1
                    AND ME1.SZSTUME_PIDM = ONO.SZTPRONO_PIDM
                    AND ME1.SZSTUME_NO_REGLA = ONO.SZTPRONO_NO_REGLA
                    and ME1.SZSTUME_SUBJ_CODE=ono.SZTPRONO_MATERIA_LEGAL
                    AND ONO.SZTPRONO_PIDM=SFRSTCR_PIDM
                    AND ONO.SZTPRONO_TERM_CODE=SFRSTCR_TERM_CODE
                    AND ONO.SZTPRONO_PTRM_CODE=SFRSTCR_PTRM_CODE
                    AND ono.SZTPRONO_MATERIA_LEGAL=SFRSTCR_RESERVED_KEY
                    And ono.SZTPRONO_STUDY_PATH = P_sp
                    And al.SVRPROY_PIDM = ME1.SZSTUME_PIDM
                    And al.REL_ALUMNOS_X_ASIGNAR_NO_REGLA = ME1.SZSTUME_NO_REGLA
                    AND al.CLAVE_MATERIA_AGP = SZSTUME_SUBJ_CODE
                    AND ME1.SZSTUME_NO_REGLA =p_regla--219
                    AND ME1.SZSTUME_PIDM =p_pidm-- 273304
--                    and ONO.SZTPRONO_SECUENCIA<>1
                    AND ME1.SZSTUME_SEQ_NO  = (SELECT MAX(SZSTUME_SEQ_NO)
                                           FROM SZSTUME ME2
                                           WHERE 1 = 1
                                           AND ME1.SZSTUME_NO_REGLA = ME2.SZSTUME_NO_REGLA
                                           AND ME1.SZSTUME_PIDM = ME2.SZSTUME_PIDM
                                           AND ME1.SZSTUME_SUBJ_CODE_COMP = ME2.SZSTUME_SUBJ_CODE_COMP
                                           AND ME1.SZSTUME_RSTS_CODE ='RE'
                                           )
                   AND ME1.SZSTUME_SUBJ_CODE NOT in (select SZTALMT_MATERIA
                                                from SZTALMT
                                                where 1=1
                                                and SZTALMT_MATERIA not like ('L3HE%')
                                                )
                    --order by to_number(al.SECUENCIA)                        
                    )x
                    where 1=1
                    and x.GRUPO not like '%X'
                    order by x.Secuencia_utel
        )loop
        
        
             l_row.materia:=c.materia;
             l_row.GRUPO := c.GRUPO;
             l_row.DESCRIPCION := c.DESCRIPCION;
             l_row.max_num_mat:=c.max_num_mat;
             l_row.SECUENCIA:=C.SECUENCIA;
             l_row.periodo:=c.periodo;
             l_row.parte_periodo:=C.parte_periodo;
             PIPE ROW (l_row);
        
        end loop;
    
    
    
    end;     
    
    
 FUNCTION f_MAT_ACT_baja (p_pidm number,p_regla number, p_sp in number) return t_tab PIPELINED
    IS l_row t_grupo_sinc;

    
    begin
           
         for c in (
              select distinct  x.MATERIA,
                                   x.GRUPO,
                                   x.DESCRIPCION,
                                   x.SZSTUME_RSTS_CODE,
                                   SZSTUME_SEQ_NO,
                                   x.max_num_mat,
                                   x.periodo,
                                   x.Parte_Periodo,
                                   x.Secuencia_utel Secuencia
                    from
                    (
                      SELECT DISTINCT  SZSTUME_SUBJ_CODE MATERIA,
                                     CASE WHEN SZSTUME_TERM_NRC LIKE '%X' THEN
                                            SUBSTR(SZSTUME_TERM_NRC,-3,3)
                                          ELSE 
                                            SUBSTR(SZSTUME_TERM_NRC,-2)    
                                     END GRUPO ,
                                     SZSTUME_RSTS_CODE,
                                     SZSTUME_SEQ_NO,
                                     DECODE(SZSTUME_GRDE_CODE_FINAL,0,NULL,SZSTUME_GRDE_CODE_FINAL) CALIFICACION,
                                     SZTPRONO_PROGRAM PROGRAMA,
                                     SZTPRONO_TERM_CODE periodo,
                                     SZTPRONO_PTRM_CODE Parte_Periodo,
                                     (SELECT SCRSYLN_LONG_COURSE_TITLE
                                      FROM SCRSYLN
                                      WHERE 1 = 1
                                      AND SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB  =SZSTUME_SUBJ_CODE) DESCRIPCION,
                                      (SELECT SUBSTR(J.SGRSATT_ATTS_CODE,4,1)MAX_NUM_MAT
                                        FROM SGRSATT J
                                        WHERE 1=1
                                        AND J.SGRSATT_PIDM=ME1.SZSTUME_PIDM
                                        AND J.SGRSATT_TERM_CODE_EFF=(SELECT MAX (A.SGRSATT_TERM_CODE_EFF)
                                                                          FROM SGRSATT A
                                                                          WHERE 1=1
                                                                          AND A.SGRSATT_PIDM=J.SGRSATT_PIDM)
--                                                                          AND A.SGRSATT_STSP_KEY_SEQUENCE=J.SGRSATT_STSP_KEY_SEQUENCE)
                                          AND ROWNUM=1   )MAX_NUM_MAT,
                                     ONO.SZTPRONO_SECUENCIA SECUENCIA,
                                     to_number(ONO.SZTPRONO_SECUENCIA) Secuencia_utel       
                    FROM SZSTUME ME1,
                         SZTPRONO ONO,
                         SFRSTCR
                    WHERE 1 = 1
                    AND ME1.SZSTUME_PIDM = ONO.SZTPRONO_PIDM
                    AND ME1.SZSTUME_NO_REGLA = ONO.SZTPRONO_NO_REGLA
                    and ME1.SZSTUME_SUBJ_CODE=ono.SZTPRONO_MATERIA_LEGAL
                    AND ONO.SZTPRONO_PIDM=SFRSTCR_PIDM
                    AND ONO.SZTPRONO_TERM_CODE=SFRSTCR_TERM_CODE
                    AND ONO.SZTPRONO_PTRM_CODE=SFRSTCR_PTRM_CODE
                    AND ono.SZTPRONO_MATERIA_LEGAL=SFRSTCR_RESERVED_KEY
                    And ono.SZTPRONO_STUDY_PATH = P_sp
                    AND ME1.SZSTUME_NO_REGLA =p_regla--219
                    AND ME1.SZSTUME_PIDM =p_pidm-- 273304
                    AND ME1.SZSTUME_SEQ_NO  = (SELECT MAX(SZSTUME_SEQ_NO)
                                           FROM SZSTUME ME2
                                           WHERE 1 = 1
                                           AND ME1.SZSTUME_NO_REGLA = ME2.SZSTUME_NO_REGLA
                                           AND ME1.SZSTUME_PIDM = ME2.SZSTUME_PIDM
                                           AND ME1.SZSTUME_SUBJ_CODE_COMP = ME2.SZSTUME_SUBJ_CODE_COMP
                                           AND ME1.SZSTUME_RSTS_CODE ='RE'
                                           )
                   AND ME1.SZSTUME_SUBJ_CODE NOT in (select SZTALMT_MATERIA
                                                from SZTALMT
                                                where 1=1
                                                and SZTALMT_MATERIA not like ('L3HE%')
                                                )
                    )x
                    where 1=1
                    and x.GRUPO not like '%X'
                    order by x.Secuencia_utel   
        )loop
        
        
             l_row.materia:=c.materia;
             l_row.GRUPO := c.GRUPO;
             l_row.DESCRIPCION := c.DESCRIPCION;
             l_row.max_num_mat:=c.max_num_mat;
             l_row.SECUENCIA:=C.SECUENCIA;
             l_row.periodo:=c.periodo;
             l_row.parte_periodo:=C.parte_periodo;
             PIPE ROW (l_row);
        
        end loop;
    
    
    
    end f_MAT_ACT_baja;     
    
    
    FUNCTION f_aplica_baja_mat(  p_pidm NUMBER, p_materia NUMBER, p_usuario varchar2, p_sp in number) RETURN VARCHAR2 IS

    retval      VARCHAR2(200) := 'EXITO';
    l_newjor    VARCHAR(4);
    vl_term_nrc VARCHAR(20);
    VL_BAJA NUMBER;
    VL_DIAS NUMBER ;
    vl_Fecha date;
    ln_secuencia NUMBER;
 
   
   BEGIN
     
     BEGIN     
                  select COUNT(A.sgrsatt_pidm)
                         INTO VL_BAJA
                          from sgrsatt a          
                          WHERE  1 = 1
                          AND a.sgrsatt_pidm =p_pidm
                          And a.SGRSATT_STSP_KEY_SEQUENCE = p_sp
                          and a.sgrsatt_data_origin = 'BAJA MATERIAS'
                          AND A.sgrsatt_term_code_eff = (SELECT MAX(sgrsatt_term_code_eff)
                                                    FROM sgrsatt tt
                                                    WHERE  tt.sgrsatt_pidm = a.sgrsatt_pidm
                                                    AND tt.sgrsatt_stsp_key_sequence = a.sgrsatt_stsp_key_sequence
                                                    AND substr(tt.sgrsatt_term_code_eff, 5, 2) NOT IN ( 81, 82, 83 )
                                                    AND REGEXP_LIKE ( tt.sgrsatt_atts_code, '^[0-9]' )
                                                    );
     EXCEPTION WHEN OTHERS  THEN
                 VL_BAJA:=0;
                 dbms_output.put_line('Error Recupera Baja'||sqlerrm);
     END;   
           
      dbms_output.put_line('Recupera Baja'||VL_BAJA);
     
     
     vl_Fecha:= null;
     
     BEGIN 
        select distinct trunc (SZTPRONO_FECHA_INICIO + (select to_number (ZSTPARA_PARAM_VALOR)
                                        from ZSTPARA
                                        where 1=1
                                        and ZSTPARA_MAPA_ID in ('ABCC_VIG')
                                        and ZSTPARA_PARAM_ID='BM'
                                        ))
          into vl_Fecha
        from sztprono a
        join tztprog b on b.pidm = a.SZTPRONO_PIDM and b.programa = a.SZTPRONO_PROGRAM and b.fecha_inicio = a.SZTPRONO_FECHA_INICIO  and b.estatus ='MA' and b.SP = p_sp
                            And b.sp = (select max (b1.sp)
                                                          from tztprog b1
                                                          where b.pidm = b1.pidm
                                                          and b.programa = b1.programa
                                                          And b.estatus = b1.estatus
                                                          )
        where 1=1
         and a.SZTPRONO_PIDM=p_pidm;

     EXCEPTION WHEN OTHERS  THEN
        vl_Fecha:=null;
        dbms_output.put_line('Recupera error  Fecha'||sqlerrm);
     END;
     
         dbms_output.put_line('Recupera Fecha'||vl_Fecha);
     
     If vl_Fecha is not null then 
         dbms_output.put_line('Entra porque no es Nulo' );
        If vl_Fecha >= trunc (sysdate) then 
         dbms_output.put_line('Entra cuanto es menor '|| vl_Fecha ||'*'||trunc (sysdate));
          vl_dias:= 1;
        Else
        dbms_output.put_line('Entra cuanto es mayor '|| vl_Fecha ||'*'||trunc (sysdate));
         vl_dias:= 0;
        End if;
     Else
        vl_dias:=0;
        dbms_output.put_line('Entra porque  es Nulo' );
     End if;
     
  IF  vl_dias>0   THEN
               
    IF VL_BAJA=0  THEN 
    
       retval:= 'No encontro las materias para aplicar la baja';
   
       FOR c IN (
                    SELECT * FROM( 
                SELECT DISTINCT
                sztprono_no_regla      regla,
                sztprono_term_code     periodo,
             trim (substr (pkg_utilerias.f_jornada(sztprono_pidm, p_sp),1,4)) Jornada,
                sorlcur_key_seqno      sp,
                sztprono_materia_legal materia,
                sztprono_secuencia     secuencia,
               ( SELECT DISTINCT grupo
                  FROM TABLE ( baninst1.pkg_alta_baja_materias.f_MAT_ACT_baja(sztprono_pidm, sztprono_no_regla, p_sp))
                   WHERE 1=1
                   AND MATERIA=sztprono_materia_legal
                ) grupo,
                ( SELECT DISTINCT max_num_mat
                  FROM TABLE ( baninst1.pkg_alta_baja_materias.f_MAT_ACT_baja(sztprono_pidm, sztprono_no_regla, p_sp))
                )  max_mat
            FROM
                sztprono,
                sorlcur a,
                sfrstcr r
--                (SELECT t.sgrsatt_term_code_eff term,
--                        t.sgrsatt_atts_code jornada,
--                        j2.stvatts_desc     desc_jornada,
--                        t.sgrsatt_pidm      atts_pidm,
--                        t.sgrsatt_stsp_key_sequence
--                    FROM sgrsatt t,
--                         stvatts j2
--                    WHERE j2.stvatts_code = t.sgrsatt_atts_code
--                    AND REGEXP_LIKE ( j2.stvatts_code,  '^[0-9]' )
--                    AND REGEXP_LIKE ( t.sgrsatt_atts_code, '^[0-9]' )
--                    AND substr(t.sgrsatt_term_code_eff, 5, 2) NOT IN ( 81, 82, 83 )
--                    AND t.sgrsatt_term_code_eff = (SELECT MAX(sgrsatt_term_code_eff)
--                                                    FROM sgrsatt tt
--                                                    WHERE  tt.sgrsatt_pidm = t.sgrsatt_pidm
--                                                    AND tt.sgrsatt_stsp_key_sequence = t.sgrsatt_stsp_key_sequence
--                                                    AND substr(tt.sgrsatt_term_code_eff, 5, 2) NOT IN ( 81, 82, 83 )
--                                                    AND REGEXP_LIKE ( tt.sgrsatt_atts_code, '^[0-9]' )
--                                                    )
--                   AND t.sgrsatt_stsp_key_sequence = (SELECT MAX(sgrsatt_stsp_key_sequence)
--                                                       FROM sgrsatt t1
--                                                       WHERE t1.sgrsatt_pidm = t.sgrsatt_pidm
--                                                       AND t1.sgrsatt_term_code_eff = t.sgrsatt_term_code_eff
--                                                       AND substr(t1.sgrsatt_term_code_eff, 5, 2) NOT IN ( 81, 82, 83 )
--                                                       AND REGEXP_LIKE ( t1.sgrsatt_atts_code, '^[0-9]' )
--                                                     )
--                )jor
                WHERE 1 = 1
                AND sztprono_pidm = a.sorlcur_pidm
                AND sztprono_fecha_inicio = a.sorlcur_start_date (+)
                AND sztprono_program = a.sorlcur_program
              --  AND jor.atts_pidm = sztprono_pidm
           --     AND sztprono_term_code=jor.term
                AND sztprono_pidm = sfrstcr_pidm
                and SFRSTCR_RSTS_CODE='RE'
                AND sztprono_term_code = sfrstcr_term_code
                AND sztprono_materia_legal = sfrstcr_reserved_key
                AND sztprono_envio_moodl = 'S'
                AND sztprono_envio_horarios = 'S'
                AND sztprono_secuencia <> 1
                AND a.sorlcur_lmod_code = 'LEARNER'
                AND a.sorlcur_cact_code = 'ACTIVE'
                AND a.sorlcur_seqno IN (SELECT  MAX(a1.sorlcur_seqno)
                                         FROM sorlcur a1
                                         WHERE a.sorlcur_pidm = a1.sorlcur_pidm
                                         AND a1.sorlcur_lmod_code = 'LEARNER'
                                         AND a.sorlcur_program = a1.sorlcur_program
                                         AND a.sorlcur_lmod_code = a1.sorlcur_lmod_code
                                       )
               AND sztprono_pidm = p_pidm
               And SZTPRONO_STUDY_PATH = p_sp
               ORDER BY sztprono_secuencia DESC
               )
               WHERE 1=1
               AND ROWNUM<=p_materia   
        )  
        LOOP
          
        
        dbms_output.put_line('LLEGA AL LOOP'  || p_materia ||'*'|| p_materia ||'*'|| c.max_mat );
           retval:='EXITO';
           IF p_materia = 1 AND p_materia <= c.max_mat THEN
           
            dbms_output.put_line('Pasa el IF 1 del LOOP' );
             
                BEGIN
                   
                     FOR x IN (
                           SELECT sztprono_pidm          pidm,
                                  sztprono_no_regla      regla,
                                  sztprono_term_code     peri,
                                  sztprono_materia_legal mate
                            FROM sztprono
                            WHERE 1 = 1
                            AND sztprono_pidm = p_pidm
                            AND sztprono_no_regla = c.regla
                            AND sztprono_materia_legal =c.materia 
                            AND sztprono_secuencia =c.secuencia
                    ) LOOP
                        dbms_output.put_line('entra 2.2'||p_materia||c.max_mat);
                        BEGIN
                            SELECT DISTINCT( szstume_term_nrc)
                            INTO vl_term_nrc
                            FROM szstume
                            WHERE 1=1
                            and szstume_subj_code = x.mate
                            and szstume_term_nrc=x.mate||c.grupo 
                            AND szstume_pidm = x.pidm
                            AND szstume_no_regla = x.regla;
                         dbms_output.put_line('entra 2.2'||vl_term_nrc);
                         retval := baninst1.f_baja_moodle(x.regla, vl_term_nrc, x.mate, x.pidm);
                        EXCEPTION WHEN OTHERS THEN
                            retval:=(' error al calcular szstume 1'||'*'||x.mate ||'*'||c.grupo ||'*'||x.pidm|| '*'||x.regla||sqlerrm);
                          dbms_output.put_line('entra 2.3'||retval);   
                        END;

                        COMMIT;

                    END LOOP;
                    
                 COMMIT;
                 
                END;
                           BEGIN
                             l_newjor := substr(c.jornada, 1, 3)|| ( substr(c.jornada, 4, 1) - p_materia );
                                  dbms_output.put_line('entra 2  '|| l_newjor);
                           EXCEPTION WHEN OTHERS THEN
                                 retval:=(' error al calcular atts_code'||sqlerrm);
                                 dbms_output.put_line('entra 2');
                           END; 
                        
                           BEGIN
                           UPDATE sgrsatt
                                            SET sgrsatt_atts_code = l_newjor,
                                                sgrsatt_activity_date = sysdate,
                                                sgrsatt_user_id = p_usuario,
                                                sgrsatt_data_origin = 'BAJA MATERIAS'
                                            WHERE 1 = 1
                                            AND sgrsatt_pidm = p_pidm
                                            AND sgrsatt_term_code_eff = c.periodo
                                            AND sgrsatt_stsp_key_sequence = c.sp
                                            AND ROWNUM = 1;

                                            dbms_output.put_line('Entra 2 ');
                           EXCEPTION WHEN OTHERS THEN
                                          retval:=(' error al actualizar en sgrsatt'||sqlerrm);
                                          dbms_output.put_line('entra 2');
                           END;     

           ELSIF p_materia = 2 AND p_materia <= c.max_mat THEN 
          
          dbms_output.put_line('Pasa el IF 2 del LOOP' );
             
                IF c.max_mat=4 THEN
                
                    BEGIN
                        FOR x IN (
                            SELECT
                                sztprono_pidm          pidm,
                                sztprono_no_regla      regla,
                                sztprono_term_code     peri,
                                sztprono_materia_legal mate
                            FROM sztprono
                            WHERE 1 = 1
                                AND sztprono_secuencia =c.secuencia
                                AND sztprono_pidm = p_pidm
                                AND sztprono_no_regla = c.regla
                                AND sztprono_materia_legal =c.materia 
                        ) LOOP
                            BEGIN
                                SELECT distinct (szstume_term_nrc)
                                INTO vl_term_nrc
                                FROM  szstume
                                WHERE szstume_subj_code = x.mate
                                and szstume_term_nrc=c.materia||c.grupo
                                AND szstume_pidm = x.pidm
                                AND szstume_no_regla = x.regla;
                                dbms_output.put_line('entra 9');
                                retval := baninst1.f_baja_moodle(x.regla, vl_term_nrc, x.mate, x.pidm);
                            EXCEPTION WHEN OTHERS THEN
                                   retval:=(' error al calcular szstume 2'||'*'||x.mate ||'*'||c.grupo ||'*'||x.pidm|| '*'||x.regla||sqlerrm);
                                   dbms_output.put_line('entra 10');
                            END;

                            
   
                        END LOOP;
                        
                       COMMIT; 

                    END;

                ELSIF c.max_mat=3 THEN
                  dbms_output.put_line('entra 15');
                  BEGIN
                        FOR x IN (
                            SELECT
                                sztprono_pidm          pidm,
                                sztprono_no_regla      regla,
                                sztprono_term_code     peri,
                                sztprono_materia_legal mate
                            FROM sztprono 
                            WHERE 1 = 1
                                AND sztprono_secuencia =c.secuencia
                                AND sztprono_pidm = p_pidm
                                AND sztprono_no_regla = c.regla
                                AND sztprono_materia_legal = c.materia 
                        ) LOOP
                            BEGIN
                                SELECT distinct (szstume_term_nrc)
                                INTO vl_term_nrc
                                FROM szstume
                                WHERE szstume_subj_code = x.mate
                                and szstume_term_nrc=c.materia||c.grupo 
                                AND szstume_pidm = x.pidm
                                AND szstume_no_regla = x.regla;
                                
                                dbms_output.put_line('entra 16');
                                
                                retval := baninst1.f_baja_moodle(x.regla,vl_term_nrc, x.mate, x.pidm);
                                
                            EXCEPTION WHEN OTHERS THEN
                                 retval:=(' error al calcular szstume 3'||'*'||x.mate ||'*'||c.grupo ||'*'||x.pidm|| '*'||x.regla||sqlerrm);
                                 
                                dbms_output.put_line('entra 17'); 
                            END;

                        END LOOP;
                        
                    END;
                    
                 COMMIT;     
               
                ELSIF c.max_mat = 2 THEN
                dbms_output.put_line('entra 18');
                    BEGIN
                        FOR x IN (SELECT
                                sztprono_pidm          pidm,
                                sztprono_no_regla      regla,
                                sztprono_term_code     peri,
                                sztprono_materia_legal mate
                            FROM sztprono 
                            WHERE 1 = 1
                                AND sztprono_secuencia=c.secuencia
                                AND sztprono_pidm = p_pidm
                                AND sztprono_no_regla = c.regla
                                AND sztprono_materia_legal =c.materia
                        ) LOOP
                            BEGIN
                                SELECT distinct (szstume_term_nrc)
                                INTO vl_term_nrc
                                FROM szstume
                                WHERE szstume_subj_code = x.mate
                                and szstume_term_nrc=c.materia||c.grupo 
                                AND szstume_pidm = x.pidm
                                AND szstume_no_regla = x.regla;
                            dbms_output.put_line('entra 19');
                            retval := baninst1.f_baja_moodle(x.regla, vl_term_nrc, x.mate, x.pidm);
                            EXCEPTION WHEN OTHERS THEN
                                retval:=(' error al calcular szstume 4'||'*'||x.mate ||'*'||c.grupo ||'*'||x.pidm|| '*'||x.regla||sqlerrm);
                            END;


                            COMMIT;


                        END LOOP;
                         

                    END;    
                
                COMMIT;     
                
                END IF;
                
                     BEGIN
                      l_newjor := substr(c.jornada, 1, 3)|| ( substr(c.jornada, 4, 1) - p_materia );
                          dbms_output.put_line('entra 20');
                     EXCEPTION WHEN OTHERS THEN
                         retval:=(' error al calcular atts_code'||sqlerrm);
                         dbms_output.put_line('entra 21');
                     END; 
                
                     BEGIN
                         UPDATE sgrsatt
                                    SET sgrsatt_atts_code = l_newjor,
                                        sgrsatt_activity_date = sysdate,
                                        sgrsatt_user_id = p_usuario,
                                        sgrsatt_data_origin = 'BAJA MATERIAS'
                                    WHERE 1 = 1
                                    AND sgrsatt_pidm = p_pidm
                                    AND sgrsatt_term_code_eff = c.periodo
                                    AND sgrsatt_stsp_key_sequence = c.sp
                                    AND ROWNUM = 1;

                                    dbms_output.put_line('Entra 22 ');
                                EXCEPTION WHEN OTHERS THEN
                                  retval:=(' error al actualizar en sgrsatt'||sqlerrm);
                                  dbms_output.put_line('entra 23');
                                END;    
                    COMMIT;
           ELSIF p_materia = 3  AND p_materia <= c.max_mat AND VL_BAJA=0 THEN
             dbms_output.put_line('Pasa el IF 3 del LOOP' );
                  BEGIN
                    FOR x IN (
                        SELECT
                            sztprono_pidm          pidm,
                            sztprono_no_regla      regla,
                            sztprono_term_code     peri,
                            sztprono_materia_legal mate
                        FROM
                            sztprono
                        WHERE
                                1 = 1
                            AND sztprono_secuencia =c.secuencia
                            AND sztprono_pidm = p_pidm
                            AND sztprono_no_regla = c.regla
                            AND sztprono_materia_legal = c.materia
                    ) LOOP
                        BEGIN
                            SELECT distinct (szstume_term_nrc)
                            INTO vl_term_nrc
                            FROM szstume
                            WHERE szstume_subj_code = x.mate
                            and szstume_term_nrc=c.materia||c.grupo 
                            AND szstume_pidm = x.pidm
                            AND szstume_no_regla = x.regla;
                            
                             retval := baninst1.f_baja_moodle(x.regla, vl_term_nrc, x.mate, x.pidm);  

                        EXCEPTION WHEN OTHERS THEN
                            retval:=(' error al calcular szstume 5'||'*'||x.mate ||'*'||c.grupo ||'*'||x.pidm|| '*'||x.regla||sqlerrm);
                        END;

                     

                        COMMIT;

                    END LOOP;
                  
                  COMMIT;
                 
                  END;
                  
                    BEGIN
                     l_newjor := substr(c.jornada, 1, 3)|| ( substr(c.jornada, 4, 1) - p_materia );
                          dbms_output.put_line('entra 28');
                  EXCEPTION WHEN OTHERS THEN
                         retval:=(' error al calcular atts_code'||sqlerrm);
                         dbms_output.put_line('entra 29');
                  END;  
                
                  BEGIN
                             UPDATE sgrsatt
                                    SET sgrsatt_atts_code = l_newjor,
                                        sgrsatt_activity_date = sysdate,
                                        sgrsatt_user_id = p_usuario,
                                        sgrsatt_data_origin = 'BAJA MATERIAS'
                                    WHERE 1 = 1
                                    AND sgrsatt_pidm = p_pidm
                                    AND sgrsatt_term_code_eff = c.periodo
                                    AND sgrsatt_stsp_key_sequence = c.sp
                                    AND ROWNUM = 1;

                                    dbms_output.put_line('Entra 30 ');
                  EXCEPTION WHEN OTHERS THEN
                                  retval:=(' error al actualizar en sgrsatt'||sqlerrm);
                                  dbms_output.put_line('entra 31');
                  END; 
                  
            COMMIT;
      
           ELSE 
                NULL;
                 dbms_output.put_line('Pasa el IF 5 por el ELSE del LOOP' );
           END IF;   
             
                        
        END LOOP;
        
    ELSE   
          dbms_output.put_line('entra 35');
     retval:='Solo esta permitido un tramite de baja de materias por bimestre';
            
    END IF;     

    
    ELSE
          dbms_output.put_line('entra 36');
     retval:='No se puede realizar esta operación, porque Esta fuera del perido de Baja de Materia';
           
    END IF;  
    
        ---Para insertar escalonados e informacion en estado de cuenta --GOG
        IF retval = 'EXITO' THEN 
          PKG_ALTA_BAJA_MATERIAS.P_EDO_CTA_BAJA_MATERIAS(P_PIDM => p_pidm );
        END IF;
        --- GOG     
        
        RETURN ( retval );
    COMMIT;
 END;
 
 ---------------------- Proceso de Alta de Materias --------------------------------- INICIA
 
     FUNCTION f_Materias_Activas_out( p_pidm IN NUMBER, p_programa VARCHAR2) RETURN pkg_alta_baja_materias.cursor_out_ALMA AS --> Funcion que obtiene LAS materias que esta cursando el alumno
        c_out_ALMA pkg_alta_baja_materias.cursor_out_ALMA;
        
    BEGIN
        BEGIN
            OPEN c_out_ALMA FOR select distinct SFRSTCR_PIDM Pidm, matricula, SFRSTCR_REG_SEQ Grupo,  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB Materia, 
                                SCBCRSE_TITLE Nombre_Materia, fecha_inicio Fecha_inicio, SFRSTCR_STSP_KEY_SEQUENCE Sp,
                                decode (SZTDTEC_MOD_TYPE, 'OL', 'E', 'S', 'E', 'I', 'I') idioma
                            from sfrstcr
                            join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN and SFRSTCR_RSTS_CODE = 'RE' and SFRSTCR_GRDE_CODE is null and SFRSTCR_GRDE_DATE is null 
                            join tztprog on pidm = SFRSTCR_PIDM and sp = SFRSTCR_STSP_KEY_SEQUENCE and estatus ='MA' and SGBSTDN_STYP_CODE ='C' and fecha_inicio = SSBSECT_PTRM_START_DATE 
                            join SCBCRSE on SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB = SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB
                            join SZTDTEC dt on dt.SZTDTEC_CAMP_CODE = campus and dt.SZTDTEC_PROGRAM = programa and dt.SZTDTEC_TERM_CODE = (select max (dt1.SZTDTEC_TERM_CODE)
                                                                                                                                            from SZTDTEC dt1
                                                                                                                                            Where dt.SZTDTEC_CAMP_CODE= dt1.SZTDTEC_CAMP_CODE
                                                                                                                                            And dt.SZTDTEC_PROGRAM = dt1.SZTDTEC_PROGRAM)
                            where 1=1
                            And substr (SFRSTCR_TERM_CODE,5,1) not in ('9')   
                            And pidm = p_pidm
                            and programa = p_programa                                                      
                            order by 3,2,1;

            RETURN ( c_out_ALMA );
        END;
    END f_Materias_Activas_out;
 
 
     FUNCTION f_Materias_nuevas_out( p_pidm IN NUMBER, p_programa VARCHAR2, p_idioma in varchar2) RETURN pkg_alta_baja_materias.cursor_out_NUMA AS --> Funcion que obtiene LAS materias que esta cursando el alumno
        c_out_NUMA pkg_alta_baja_materias.cursor_out_NUMA;
        
    BEGIN
        BEGIN
            OPEN c_out_NUMA FOR 
                                select distinct b.fecha_inicio, b.clave_materia_Agp Clave_Materia,  c.SCBCRSE_TITLE Nombre_Materia, b.SECUENCIA,
                                (select distinct y.SZSTUME_TERM_NRC
                                from (
                                select min(x.numero), x.SZSTUME_TERM_NRC
                                from (
                                select count(*) numero, a.SZSTUME_TERM_NRC, a.SZSTUME_SUBJ_CODE_COMP, a.SZSTUME_NO_REGLA
                                from SZSTUME a
                                where 1=1
                                and a.SZSTUME_NO_REGLA = b.REL_ALUMNOS_X_ASIGNAR_NO_REGLA
                                and a.SZSTUME_SUBJ_CODE_COMP = b.clave_materia_Agp
                                and substr (a.SZSTUME_TERM_NRC, length(a.SZSTUME_TERM_NRC)-1) not in ('0X')    
                                 And a.SZSTUMe_SEQ_NO = (select max (a1.SZSTUMe_SEQ_NO)
                                                                                  from SZSTUMe a1
                                                                                  Where 1=1
                                                                                  And a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                                                  And a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                                           --       And a.SZSTUMU_STAT_IND =  a1.SZSTUMU_STAT_IND
                                                                                  And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA                                
                                                                                                                  )                                                                                
                                group by a.SZSTUME_TERM_NRC, a.SZSTUME_SUBJ_CODE_COMP, a.SZSTUME_NO_REGLA
                                order by 1  
                                ) x
                                where rownum = 1
                                group by x.SZSTUME_TERM_NRC, x.SZSTUME_SUBJ_CODE_COMP, x.SZSTUME_NO_REGLA
                                ) y) grupo,
                                (select max (TZTAABC_MAT_MOSTRAR)
                                from TZTAABC
                                where TZTAABC_CAMPUS = a.campus
                                and TZTAABC_NIVEL = a.nivel 
                                And TZTAABC_BIMESTRE = pkg_utilerias.f_calcula_bimestres(a.pidm, a.sp)
                                ) Materias_Mostrar,
                                (select max(TZTAABC_MAT_TOTALES)
                                from TZTAABC
                                where TZTAABC_CAMPUS = a.campus
                                and TZTAABC_NIVEL = a.nivel 
                                And TZTAABC_BIMESTRE = pkg_utilerias.f_calcula_bimestres(a.pidm, a.sp)
                                ) Materias_totales
                                from tztprog a
                                join REL_ALUMNOS_X_ASIGNAR b on b.SVRPROY_PIDM = a.pidm and b.ID_PROGRAMA = a.programa and b.fecha_inicio = a.fecha_inicio
                                AND clave_materia_Agp NOT in (select SZTALMT_MATERIA
                                                from SZTALMT
                                                where 1=1
                                                and SZTALMT_MATERIA not like ('L3HE%')
                                                )
                                join SCBCRSE c on c.SCBCRSE_SUBJ_CODE||c.SCBCRSE_CRSE_NUMB = b.clave_materia_Agp
                                join SZTGPME d on d.SZTGPME_NO_REGLA = b.REL_ALUMNOS_X_ASIGNAR_NO_REGLA and SZTGPME_SUBJ_CRSE = b.clave_materia_Agp and d.SZTGPME_STAT_IND = 1
                                where 1=1
                                and a.estatus ='MA' and a.SGBSTDN_STYP_CODE ='C'
                                And a.pidm = p_pidm--1220
                                and a.programa = p_programa --'UTLLIDDFED'  
                                And d.SZTGPME_IDIOMA = p_idioma
                                And b.clave_materia not in (select distinct SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB 
                                                            from sfrstcr
                                                            join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN and SFRSTCR_RSTS_CODE = 'RE' 
                                                            join tztprog on pidm = SFRSTCR_PIDM and sp = SFRSTCR_STSP_KEY_SEQUENCE and estatus ='MA' and SGBSTDN_STYP_CODE ='C' 
                                                            where 1=1
                                                            And substr (SFRSTCR_TERM_CODE,5,1) not in ('9')   
                                                            And pidm = p_pidm--1220
                                                            and programa = p_programa--'UTLLIDDFED' 
                                                            )
                                and substr (d.SZTGPME_TERM_NRC, length(d.SZTGPME_TERM_NRC)-1) not in ('0X')                        
                                order by b.SECUENCIA;

            RETURN ( c_out_NUMA );
        END;
    END f_Materias_nuevas_out;



FUNCTION F_Aplica_Alta_materia (p_pidm number, p_programa in varchar2, p_fecha in date, P_MATERIA varchar2, p_grupo in varchar2, p_usuario varchar2 )return varchar2 as 


vl_exito varchar2(500):= 'EXITO';
P_ERROR  varchar2(500):= 'EXITO';
vl_valida number :=0;

Begin 


    For cx in (

                select *
                from sztprono a
                where 1=1
                and a.SZTPRONO_PIDM = p_pidm 
                and a.SZTPRONO_PROGRAM = p_programa
                and trunc (a.SZTPRONO_FECHA_INICIO) = p_fecha
                and a.SZTPRONO_SECUENCIA = (select max (a1.SZTPRONO_SECUENCIA)
                                            from SZTPRONO a1
                                            where a.SZTPRONO_PIDM = a1.SZTPRONO_PIDM
                                            And a.SZTPRONO_PROGRAM = a1.SZTPRONO_PROGRAM
                                            And trunc (a.SZTPRONO_FECHA_INICIO) = trunc (a1.SZTPRONO_FECHA_INICIO)
                                            )
                                            
               ) loop
               
                Begin
                
                    Insert into SZTPRONO values (cx.SZTPRONO_PIDM,
                                                 cx.SZTPRONO_ID,
                                                 cx.SZTPRONO_TERM_CODE,
                                                 cx.SZTPRONO_PROGRAM,
                                                 p_materia,
                                                 cx.SZTPRONO_SECUENCIA +1,
                                                 cx.SZTPRONO_PTRM_CODE,
                                                 p_materia,
                                                 cx.SZTPRONO_COMENTARIO,
                                                 cx.SZTPRONO_FECHA_INICIO,
                                                 cx.SZTPRONO_PTRM_CODE_NW,
                                                 cx.SZTPRONO_FECHA_INICIO_NW,
                                                 cx.SZTPRONO_AVANCE,
                                                 cx.SZTPRONO_NO_REGLA,
                                                 'Automatico',
                                                 cx.SZTPRONO_STUDY_PATH,
                                                 cx.SZTPRONO_RATE,
                                                 cx.SZTPRONO_JORNADA,
                                                 sysdate,
                                                 cx.SZTPRONO_CUATRI,
                                                 cx.SZTPRONO_TIPO_INICIO,
                                                 cx.SZTPRONO_JORNADA_DOS,
                                                 'S', --SZTPRONO_ENVIO_MOODL  -------->>>>>>> NAce como N
                                                 'N', --SZTPRONO_ENVIO_HORARIOS
                                                 cx.SZTPRONO_ESTATUS,
                                                 'N', --SZTPRONO_ESTATUS_ERROR
                                                 null, ---SZTPRONO_DESCRIPCION_ERROR
                                                 cx.SZTPRONO_GRUPO_ASIG);
                
                Exception
                    When Others then 
                       vl_exito:= 'Se presento el error al insertar en Prono ' ||sqlerrm;
                End;
           
                If vl_exito = 'EXITO' then 
                 
                
                    
                         For cx2  in (
                                        select *
                                        from SZSTUME
                                        where SZSTUME_PIDM =  p_pidm 
                                        And trunc (SZSTUME_START_DATE) =  p_fecha
                                        And rownum = 1
                                    
                                    ) loop

                        
                                    Begin
                                        Insert into SZSTUME values ( p_grupo,  ----SZSTUME_TERM_NRC
                                                                    cx2.SZSTUME_PIDM,
                                                                    cx2.SZSTUME_ID,
                                                                    sysdate,   ---SZSTUME_ACTIVITY_DATE
                                                                    'Automatico', ---SZSTUME_USER_ID
                                                                    '1', --SZSTUME_STAT_IND    -------->>>>>>> NAce como 0
                                                                    ' Registro Pendiente Sincronizacion ', ---SZSTUME_OBS
                                                                    cx2.SZSTUME_PWD,
                                                                    null, --SZSTUME_MDLE_ID
                                                                    1, -- SZSTUME_SEQ_NO
                                                                    'RE', --SZSTUME_RSTS_CODE
                                                                    0, --SZSTUME_GRDE_CODE_FINAL
                                                                    p_materia, --SZSTUME_SUBJ_CODE
                                                                    null, --SZSTUME_LEVL_CODE
                                                                    null, --SZSTUME_POBI_SEQ_NO
                                                                    null, -- SZSTUME_PTRM
                                                                    null, -- SZSTUME_CAMP_CODE
                                                                    null, -- SZSTUME_CAMP_CODE_COMP
                                                                    null, -- SZSTUME_LEVL_CODE_COMP,
                                                                    null,  -- SZSTUME_TERM_NRC_COMP
                                                                    p_materia, --SZSTUME_SUBJ_CODE_COMP
                                                                    cx2.SZSTUME_START_DATE,
                                                                    cx2.SZSTUME_NO_REGLA,
                                                                    null, -- SZSTUME_SECUENCIA
                                                                    cx2.SZSTUME_NIVE_SEQNO,
                                                                    cx2.SZSTUME_SINCRO,
                                                                    cx2.SZSTUME_SINCRO_OBS);
                                    Exception
                                        When Others then 
                                           vl_exito:= 'Se presento el error al insertar en SZSTUME ' ||sqlerrm;
                                    End;     
                                    
                                    If vl_exito = 'EXITO' then 
                                    
                                         Begin 
                                            PKG_FORMA_MOODLE.P_INSCR_INDIVIDUAL_XX ( cx2.SZSTUME_START_DATE,
                                                                                     cx2.SZSTUME_NO_REGLA, 
                                                                                     p_materia, 
                                                                                     cx2.SZSTUME_PIDM, 
                                                                                     cx2.SZSTUME_RSTS_CODE, 
                                                                                     null, 
                                                                                     P_ERROR);
                                        Exception
                                            When Others then 
                                                null;
                                        End;
                                        
                                        
                                        Begin
                                            Update SZSTUME
                                            set SZSTUME_STAT_IND = '0'
                                            Where SZSTUME_PIDM =  p_pidm 
                                           And trunc (SZSTUME_START_DATE) =  p_fecha
                                           And SZSTUME_TERM_NRC = p_grupo; 
                                        Exception
                                             When Others then 
                                           vl_exito:= 'Se presento el error al Actualizar en SZSTUME ' ||sqlerrm;
                                        
                                        End;
                                        
                                    End if;
                                    
                                    ---------------------- valida si el alumno existe en sesiones ejecutivas a traves de la etiqueta -----------------  
                                    vl_valida:=0;  
                                    Begin 
                                        select count(1)
                                         Into vl_valida 
                                        from goradid
                                        where goradid_pidm = p_pidm
                                        and GORADID_ADID_CODE ='EJEC';
                                    Exception
                                        When others then 
                                            vl_valida:=0;
                                    End;
                                     
                                    If vl_valida >= 1 then 
                                    
                                            Begin
                                                Insert into SZSTUME values ( p_materia||'90X',  ----SZSTUME_TERM_NRC
                                                                            cx2.SZSTUME_PIDM,
                                                                            cx2.SZSTUME_ID,
                                                                            sysdate,   ---SZSTUME_ACTIVITY_DATE
                                                                            'Automatico', ---SZSTUME_USER_ID
                                                                            '1', --SZSTUME_STAT_IND    -------->>>>>>> NAce como 0
                                                                            ' Registro Pendiente Sincronizacion ', ---SZSTUME_OBS
                                                                            cx2.SZSTUME_PWD,
                                                                            null, --SZSTUME_MDLE_ID
                                                                            1, -- SZSTUME_SEQ_NO
                                                                            'RE', --SZSTUME_RSTS_CODE
                                                                            0, --SZSTUME_GRDE_CODE_FINAL
                                                                            p_materia, --SZSTUME_SUBJ_CODE
                                                                            null, --SZSTUME_LEVL_CODE
                                                                            null, --SZSTUME_POBI_SEQ_NO
                                                                            null, -- SZSTUME_PTRM
                                                                            null, -- SZSTUME_CAMP_CODE
                                                                            null, -- SZSTUME_CAMP_CODE_COMP
                                                                            null, -- SZSTUME_LEVL_CODE_COMP,
                                                                            null,  -- SZSTUME_TERM_NRC_COMP
                                                                            p_materia, --SZSTUME_SUBJ_CODE_COMP
                                                                            cx2.SZSTUME_START_DATE,
                                                                            cx2.SZSTUME_NO_REGLA,
                                                                            null, -- SZSTUME_SECUENCIA
                                                                            cx2.SZSTUME_NIVE_SEQNO,
                                                                            cx2.SZSTUME_SINCRO,
                                                                            cx2.SZSTUME_SINCRO_OBS);
                                            Exception
                                                When Others then 
                                                   vl_exito:= 'Se presento el error al insertar en SZSTUME el ejecutivo ' ||sqlerrm;
                                            End;                                       
                                    
                                            Begin
                                                Update SZSTUME
                                                set SZSTUME_STAT_IND = '0'
                                                Where SZSTUME_PIDM =  p_pidm 
                                               And trunc (SZSTUME_START_DATE) =  p_fecha
                                               And SZSTUME_TERM_NRC = p_materia||'90X'; 
                                            Exception
                                                 When Others then 
                                               vl_exito:= 'Se presento el error al Actualizar en SZSTUME el ejecutivo' ||sqlerrm;
                                            
                                            End;                                    

                                    
                                    End if;                                                          
                                                                    
                         End Loop;            
                    
                    
                
                
                End if;
    


    End Loop;
    
    If vl_exito = 'EXITO' then 
        commit;
        Return ( vl_exito);
    Else
        rollback;
        Return (vl_exito);
    End if;
    
    
       ---Para insertar informacion en estado de cuenta --GOG
        IF vl_exito = 'EXITO' THEN 
          PKG_ALTA_BAJA_MATERIAS.P_EDO_CTA_ALTA_MATERIAS(P_PIDM => p_pidm );
        END IF;
        --- GOG 
    
    
End F_Aplica_Alta_materia;                                                                    



FUNCTION F_valida_materia_sincr (p_pidm number,p_programa in varchar2)return varchar2 as 


vl_exito varchar2(500):= 'EXITO';
vl_existe number :=0;



Begin

        Begin 

            select distinct count(*)
             Into vl_existe
            from SZSTUME a
            join tztprog b on b.pidm = SZSTUME_PIDM and b.programa =p_programa and b.sp = (select max (sp)
                                                                                             from tztprog b1
                                                                                             where b.pidm = b1.pidm
                                                                                             And b.programa = b1.programa)
            where 1=1
            and a.SZSTUME_PIDM = p_pidm
            And trunc (a.SZSTUME_START_DATE)= b.FECHA_INICIO
            And a.SZSTUME_STAT_IND not in ('1')
             And a.SZSTUMe_SEQ_NO = (select max (a1.SZSTUMe_SEQ_NO)
                                      from SZSTUMe a1
                                      Where 1=1
                                      And a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                      And a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                      And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA       
                                    );

        Exception
            When Others then 
                vl_existe:=0;
        End;



    If vl_existe = 0 then
         vl_exito :='EXITO';
        Return ( vl_exito);
    Else
        vl_exito :='Existen materias sin sincronizar en el aula virtual. Inténtalo más tarde.';
        Return (vl_exito);
    End if;



End F_valida_materia_sincr; 



---------------------- Proceso de Alta de Materias --------------------------------- TERMINA

--
--Financiero Alta Materias
   FUNCTION f_calc_alta_materias (
        p_pidm        IN NUMBER,
        p_periodo IN varchar2,
        p_user in varchar2,
        p_programa in varchar2,
        p_fecha_ini in date ,
        p_cve_materia in varchar2,
        p_sp in varchar2
    ) RETURN pkg_alta_baja_materias.cursor_mataltas AS
        c_altmat     pkg_alta_baja_materias.cursor_mataltas;
        po_respuesta VARCHAR2(10);
        ln_valida_paq  NUMBER;
    BEGIN
    
    SELECT COUNT(1) 
   INTO ln_valida_paq
    FROM GORADID 
    WHERE GORADID_PIDM = p_pidm  
    AND GORADID_ADID_CODE= 'DINA';
    
    IF ln_valida_paq >= 1 THEN 
         pkg_alta_baja_materias.p_alta_materias_dina (p_pidm, p_periodo,p_user,p_programa, p_fecha_ini, p_cve_materia ,p_sp,po_respuesta);
        ELSE
         pkg_alta_baja_materias.p_alta_materias_face (p_pidm, p_periodo,p_user,p_programa, p_fecha_ini, p_cve_materia ,p_sp,po_respuesta);
    END IF;

        BEGIN
            OPEN c_altmat FOR SELECT UNIQUE FECHA_VENCIMIENTO ,
                                                   CONCEPTO ,
                                                   MONTO_ANTERIOR ,
                                                   NVL(PCT_ALTA_BAJA,0) PCT_ALTA_BAJA ,
                                                   MONTO_CAJUSTE ,
                                                   MONTO_ACCESORIOS 
                                                FROM
                                                    SZTCALP
                              WHERE
                                      pidm = p_pidm ORDER BY FECHA_VENCIMIENTO;

            RETURN ( c_altmat );
        END;

    END f_calc_alta_materias;

--
--Fija
    PROCEDURE p_alta_materias_face (
        pidm         number,
        p_periodo varchar2,
        p_user varchar2,
        p_programa in varchar2, 
        p_fecha_ini in date, 
        p_cve_materia in varchar2,
        p_sp in varchar2,
        po_respuesta out varchar2
    ) IS

        lv_periodo     VARCHAR2(50);
        lv_codigo      VARCHAR2(10);
        lv_descripcion VARCHAR2(500);
        lv_codigo_d    VARCHAR2(10);
        ln_porcentaje  NUMBER;
        lv_campus      VARCHAR2(20);
        lv_nivel       VARCHAR2(2);
        ln_bimestre    NUMBER;
        ln_calculo     NUMBER;
        ln_cnt         NUMBER:=0;
        ln_trans_paid  NUMBER;
        ln_pidm NUMBER;
        lv_programa    VARCHAR2(20);
        no_materias NUMBER := 1;
        ln_amount_y1 NUMBER := 0;

    
    
    BEGIN
   -- EXECUTE IMMEDIATE 'TRUNCATE TABLE SZTCALP';
        execute immediate 'delete from SZTCALP where PIDM = pidm'; 
        execute immediate 'truncate table taismgr.TBRACCD_TMP_ALTAS';
        commit;
        
  LN_PIDM := PIDM;
  
        BEGIN 
        SELECT
            MAX(tbraccd_term_code)
        INTO lv_periodo
        FROM
            tbraccd
        WHERE tbraccd_pidm = pidm
          AND TBRACCD_PERIOD = p_periodo
          AND TBRACCD_STSP_KEY_SEQUENCE = p_sp
          AND tbraccd_feed_date IS NOT NULL;
          EXCEPTION WHEN OTHERS THEN 
          lv_periodo := NULL;
          END;
 dbms_output.put_line ('lv_periodo'||lv_periodo);

BEGIN 
        SELECT CAMPUS,
               NIVEL,
               TO_NUMBER(NVL (PKG_UTILERIAS.F_CALCULA_BIMESTRES (A.PIDM, A.SP), 0)) BIMESTRE,
               PROGRAMA
          INTO lv_campus, lv_nivel, ln_bimestre, lv_programa
          FROM TZTPROG A
         WHERE     A.PIDM = LN_PIDM
               AND A.SP IN (SELECT MAX (B.SP)
                              FROM TZTPROG B
                             WHERE B.PIDM = A.PIDM);
                                                 
EXCEPTION WHEN OTHERS THEN 
lv_campus:= NULL;
 lv_nivel:= NULL;
  ln_bimestre:= NULL;
END;                  


 dbms_output.put_line ('lv_campus'||lv_campus);
 dbms_output.put_line ('lv_nivel'||lv_nivel);
 dbms_output.put_line ('ln_bimestre'||ln_bimestre);

           
             BEGIN                   
            SELECT TZTAABC_AJUSTE_FIN
              into ln_porcentaje
              FROM TZTAABC
             WHERE     TZTAABC_CAMPUS = lv_campus
                   AND TZTAABC_NIVEL = lv_nivel
                   AND TZTAABC_BIMESTRE = ln_bimestre;
                   EXCEPTION WHEN OTHERS THEN 
                   ln_porcentaje := NULL;
                   END;
       
                         
  
 ln_calculo := ln_porcentaje*no_materias;

 dbms_output.put_line ('no_materias'||no_materias);

   if no_materias >= 1 then 
                    FOR calc IN (
                SELECT UNIQUE
                    a.tbraccd_pidm pidm,
                    a.tbraccd_effective_date,
                    b.tbbdetc_desc,
                    a.tbraccd_amount,
                    a.tbraccd_balance,
                    a.tbraccd_tran_number_paid,
                    a.TBRACCD_TRAN_NUMBER,
                    a.TBRACCD_CURR_CODE
                FROM
                    tbraccd a,
                    tbbdetc b
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                    AND a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    AND a.tbraccd_feed_date IS NOT NULL
                    AND a.tbraccd_detail_code IN ( SELECT TZTNCD_CODE
                            FROM tztncd, tbbdetc
                            WHERE TZTNCD_concepto = 'Venta'
                            AND TBBDETC_detail_code = TZTNCD_CODE
                            AND TBBDETC_type_ind = 'C'
                            AND TBBDETC_detc_active_ind = 'Y'
                            AND TBBDETC_dcat_code = 'COL'
                            AND TBBDETC_taxt_code NOT IN ('GN','EC','CU','ES','ID','BA') )
            ) LOOP
    ln_cnt := ln_cnt+1;
    
    dbms_output.put_line('calcpagos :'||calc.tbbdetc_desc);
    dbms_output.put_line('calcpagos2 :'||calc.tbraccd_amount);
    dbms_output.put_line('calcpagos3 :'||to_char(ln_porcentaje)||'%');
        dbms_output.put_line('calcpagos4 :'||ln_calculo);

            SELECT SUM (TBRACCD_AMOUNT)
              INTO ln_amount_y1 
              FROM TBRACCD
             WHERE     TBRACCD_PIDM = pidm
               AND SUBSTR (TBRACCD_DETAIL_CODE, 3, 2) = 'Y1'
               AND TBRACCD_FEED_DATE = p_fecha_ini
               and tbraccd_effective_date = calc.tbraccd_effective_date;

                INSERT INTO SZTCALP (
                    fecha_vencimiento,
                    concepto,
                    monto_anterior,
                    pct_alta_baja,
                    monto_cajuste,
                    monto_accesorios,
                    pidm,
                    fec_calculo,
                    FEC_INICIAL,
                    MONTO_Y1_ALTAS
                ) VALUES (
                    calc.tbraccd_effective_date,
                    calc.tbbdetc_desc,
                    calc.tbraccd_amount,
                    --to_char(ln_porcentaje)||'%',
                    to_char(ln_porcentaje*no_materias)||'%',
                    round((calc.tbraccd_amount + ( ( calc.tbraccd_amount * ln_calculo ) / 100 ))),
                    NULL,
                    pidm,
                    sysdate,
                    p_fecha_ini,
                    ln_amount_y1
                );
                commit;
                
            BEGIN
                SELECT
                    unique substr(tbraccd_term_code, 1, 2)
                INTO lv_codigo
                FROM
                    tbraccd
                WHERE
                    tbraccd_pidm = calc.pidm;

            END;

            BEGIN
                SELECT DISTINCT
                    tbbdetc_desc,
                    tbbdetc_detail_code
                INTO
                    lv_descripcion,
                    lv_codigo_d
                FROM
                    tbbdetc
                WHERE
                        1 = 1
                    AND  tbbdetc_detail_code = lv_codigo || 'Y1';

            END;
                        
if ln_cnt <= 1 then 
dbms_output.put_line('ln_cnt1 :'||ln_cnt||'balance');
   -- if calc.tbraccd_balance = 0 then 
    ln_trans_paid := null;
  --  elsif calc.tbraccd_balance < (calc.tbraccd_amount + ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
  --  ln_trans_paid := null;
  --  dbms_output.put_line('ln_cnt2 :'||ln_cnt);
  --  elsif calc.tbraccd_balance >= (calc.tbraccd_amount + ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
  --  dbms_output.put_line('ln_cnt3 :'||ln_cnt);
  --  ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
  --  end if;

elsif ln_cnt > 1 then 
dbms_output.put_line('ln_cnt4 :'||ln_cnt);
ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
end if;
--general
    if calc.tbraccd_balance = 0 then 
    ln_trans_paid := null;
    elsif calc.tbraccd_balance >= (calc.tbraccd_amount + ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
    dbms_output.put_line('ln_Y1 :'||ln_cnt);
    ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
    end if;
 dbms_output.put_line ('entro a insertar TBRACCD_TMP_ALTAS');

                         INSERT INTO taismgr.TBRACCD_TMP_ALTAS
                         (TBRACCD_PIDM                
                                                ,TBRACCD_TRAN_NUMBER         
                                                ,TBRACCD_TERM_CODE           
                                                ,TBRACCD_DETAIL_CODE         
                                                ,TBRACCD_USER                
                                                ,TBRACCD_ENTRY_DATE          
                                                ,TBRACCD_AMOUNT              
                                                ,TBRACCD_BALANCE             
                                                ,TBRACCD_EFFECTIVE_DATE      
                                                ,TBRACCD_BILL_DATE           
                                                ,TBRACCD_DUE_DATE            
                                                ,TBRACCD_DESC                
                                                ,TBRACCD_RECEIPT_NUMBER      
                                                ,TBRACCD_TRAN_NUMBER_PAID    
                                                ,TBRACCD_CROSSREF_PIDM       
                                                ,TBRACCD_CROSSREF_NUMBER     
                                                ,TBRACCD_CROSSREF_DETAIL_CODE
                                                ,TBRACCD_SRCE_CODE           
                                                ,TBRACCD_ACCT_FEED_IND       
                                                ,TBRACCD_ACTIVITY_DATE       
                                                ,TBRACCD_SESSION_NUMBER      
                                                ,TBRACCD_CSHR_END_DATE       
                                                ,TBRACCD_CRN                 
                                                ,TBRACCD_CROSSREF_SRCE_CODE  
                                                ,TBRACCD_LOC_MDT             
                                                ,TBRACCD_LOC_MDT_SEQ         
                                                ,TBRACCD_RATE                
                                                ,TBRACCD_UNITS               
                                                ,TBRACCD_DOCUMENT_NUMBER     
                                                ,TBRACCD_TRANS_DATE          
                                                ,TBRACCD_PAYMENT_ID          
                                                ,TBRACCD_INVOICE_NUMBER      
                                                ,TBRACCD_STATEMENT_DATE      
                                                ,TBRACCD_INV_NUMBER_PAID     
                                                ,TBRACCD_CURR_CODE           
                                                ,TBRACCD_EXCHANGE_DIFF       
                                                ,TBRACCD_FOREIGN_AMOUNT      
                                                ,TBRACCD_LATE_DCAT_CODE      
                                                ,TBRACCD_FEED_DATE           
                                                ,TBRACCD_FEED_DOC_CODE       
                                                ,TBRACCD_ATYP_CODE           
                                                ,TBRACCD_ATYP_SEQNO          
                                                ,TBRACCD_CARD_TYPE_VR        
                                                ,TBRACCD_CARD_EXP_DATE_VR    
                                                ,TBRACCD_CARD_AUTH_NUMBER_VR 
                                                ,TBRACCD_CROSSREF_DCAT_CODE  
                                                ,TBRACCD_ORIG_CHG_IND        
                                                ,TBRACCD_CCRD_CODE           
                                                ,TBRACCD_MERCHANT_ID         
                                                ,TBRACCD_TAX_REPT_YEAR       
                                                ,TBRACCD_TAX_REPT_BOX        
                                                ,TBRACCD_TAX_AMOUNT          
                                                ,TBRACCD_TAX_FUTURE_IND      
                                                ,TBRACCD_DATA_ORIGIN         
                                                ,TBRACCD_CREATE_SOURCE       
                                                ,TBRACCD_CPDT_IND            
                                                ,TBRACCD_AIDY_CODE           
                                                ,TBRACCD_STSP_KEY_SEQUENCE   
                                                ,TBRACCD_PERIOD              
                                                ,TBRACCD_SURROGATE_ID        
                                                ,TBRACCD_VERSION             
                                                ,TBRACCD_USER_ID             
                                                ,TBRACCD_VPDI_CODE  
                                                ,TBRACCD_FECHA_INSERCION
                                                )                    
                            VALUES ( pidm,                          
                                    0, --ln_secuencia,                
                                     lv_periodo,                     
                                     lv_codigo_d,                      
                                     p_user,                           
                                     SYSDATE,   
                                     (( calc.tbraccd_amount * ln_calculo ) / 100 ),
                                     (( calc.tbraccd_amount * ln_calculo ) / 100 ),                                                          
                                --    calc.tbraccd_amount + (calc.tbraccd_amount + ( ( calc.tbraccd_amount * ln_calculo ) / 100 )),                
                                --    calc.tbraccd_amount + (calc.tbraccd_amount + ( ( calc.tbraccd_amount * ln_calculo ) / 100 )),               
                                    calc.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     lv_descripcion,                 
                                     NULL,--CX.ORDEN,                       
                                     ln_trans_paid,--tran_paid                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'T',                            
                                     'Y',                            
                                     SYSDATE,                        
                                     0,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                    calc.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     calc.TBRACCD_CURR_CODE,                          
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     p_fecha_ini,--CX.FECHA_INICIO,                
                                     1,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'ALTAS_MAT',                 
                                     'ALTAS_MAT',                 
                                     NULL,                           
                                     NULL,                           
                                     p_sp, --CX.SP,                          
                                     p_periodo,--CX.PERIODO,                     
                                     0,                           
                                     0,                           
                                     p_user,                           
                                     0,
                                     trunc(SYSDATE)); 
                                     COMMIT;

            po_respuesta := '00';
END LOOP;
FOR ACC IN (SELECT UNIQUE
                    a.tbraccd_pidm pidm,a.tbraccd_effective_date,
                    b.tbbdetc_desc,
                    a.tbraccd_amount
                FROM
                    tbraccd a,
                    tbbdetc b,
                    TZTINC c
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                        AND  a.tbraccd_detail_code = c.codigo 
                    AND a.tbraccd_pidm = pidm
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo)
                     LOOP
                INSERT INTO SZTCALP (
                    fecha_vencimiento,
                    concepto,
                    monto_anterior,
                    pct_alta_baja,
                    monto_cajuste,
                    monto_accesorios,
                    pidm,
                    fec_calculo,
                    fec_inicial
                ) VALUES (
                    acc.tbraccd_effective_date,
                    acc.tbbdetc_desc,
                    null,
                    null,
                    null,
                    round(acc.tbraccd_amount),
                    pidm,
                    sysdate,
                    p_fecha_ini
                );
                commit;
                end loop;
--end if;
END IF;
        INSERT INTO TAISMGR.TZTBABC
        (
          TZTBABC_PIDM     ,
          TZTBABC_ID           ,
          TZTBABC_FEC_INI     ,
          TZTBABC_AJUSTE       ,
          TZTBABC_PORC_AJUSTE,
          TZTBABC_STAT_IND,
          TZTBABC_PROGRAMA,
          TZTBABC_MATERIA  )
          VALUES 
          (pidm,
          F_MATRICULA (pidm),
          P_FECHA_INI,
          'AM',
          ln_porcentaje,
          0,
          P_PROGRAMA,
          P_CVE_MATERIA);
          commit;
          

      --  execute immediate 'truncate table tbraccd_tmp_bajas';
        
    END p_alta_materias_face;
--
--Dinamica
 PROCEDURE p_alta_materias_dina (
        pidm         number,
        p_periodo varchar2,
        p_user varchar2,
        p_programa in varchar2, 
        p_fecha_ini in date, 
        p_cve_materia in varchar2,  
        p_sp in varchar2,              
        po_respuesta out varchar2
    ) IS

        lv_periodo     VARCHAR2(50);
        lv_codigo      VARCHAR2(10);
        lv_descripcion VARCHAR2(500);
        lv_codigo_d    VARCHAR2(10);
        ln_porcentaje  NUMBER;
        lv_campus      VARCHAR2(20);
        lv_nivel       VARCHAR2(2);
        ln_bimestre    NUMBER;        
        ln_calculo     NUMBER;
        ln_cnt         NUMBER:=0;
        ln_trans_paid  NUMBER;
        ln_amount_plp  NUMBER;
        ln_rate        NUMBER;
        ln_amount_calc NUMBER;
        ln_pidm NUMBER;
        lv_programa    VARCHAR2(20);
        no_materias NUMBER := 1;  
        ln_amount_y1 NUMBER := 0;      

    
    
    BEGIN
   -- EXECUTE IMMEDIATE 'TRUNCATE TABLE SZTCALP';
        execute immediate 'delete from SZTCALP where PIDM = pidm'; 
        execute immediate 'truncate table taismgr.TBRACCD_TMP_ALTAS';
        commit;
        
  LN_PIDM := PIDM;
  
        BEGIN 
        SELECT
            MAX(tbraccd_term_code)
        INTO lv_periodo
        FROM
            tbraccd
        WHERE tbraccd_pidm = LN_PIDM
          AND TBRACCD_PERIOD = p_periodo
          AND TBRACCD_STSP_KEY_SEQUENCE = p_sp
          AND tbraccd_feed_date IS NOT NULL;
          EXCEPTION WHEN OTHERS THEN 
          lv_periodo := NULL;
          END;
 dbms_output.put_line ('lv_periodo'||lv_periodo);

BEGIN 
        SELECT CAMPUS,
               NIVEL,
               TO_NUMBER(NVL (PKG_UTILERIAS.F_CALCULA_BIMESTRES (A.PIDM, A.SP), 0)) BIMESTRE,
               PROGRAMA
          INTO lv_campus, lv_nivel, ln_bimestre, lv_programa
          FROM TZTPROG A
         WHERE     A.PIDM = LN_PIDM
               AND A.SP IN (SELECT MAX (B.SP)
                              FROM TZTPROG B
                             WHERE B.PIDM = A.PIDM);
                                                 
EXCEPTION WHEN OTHERS THEN 
lv_campus:= NULL;
 lv_nivel:= NULL;
  ln_bimestre:= NULL;
END;                  


 dbms_output.put_line ('lv_campus'||lv_campus);
 dbms_output.put_line ('lv_nivel'||lv_nivel);
 dbms_output.put_line ('ln_bimestre'||ln_bimestre);

           
             BEGIN                   
            SELECT TZTAABC_AJUSTE_FIN
              into ln_porcentaje
              FROM TZTAABC
             WHERE     TZTAABC_CAMPUS = lv_campus
                   AND TZTAABC_NIVEL = lv_nivel
                   AND TZTAABC_BIMESTRE = ln_bimestre;
                   EXCEPTION WHEN OTHERS THEN 
                   ln_porcentaje := NULL;
                   END;
       
                         
 ln_calculo := ln_porcentaje*no_materias;
        
            BEGIN
                SELECT tbraccd_amount
                INTO ln_amount_plp
                FROM
                    tbraccd a
                WHERE a.tbraccd_pidm = LN_PIDM
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.tbraccd_feed_date IS NOT NULL
                    AND substr(a.tbraccd_detail_code, 1, 3) = 'PLP' ;
            EXCEPTION WHEN OTHERS THEN 
            ln_amount_plp := 0;
            END;
        
        SELECT TO_NUMBER(SUBSTR(SORLCUR_RATE_CODE,2,2))
                        INTO ln_rate
                        FROM sorlcur A
                        WHERE 1=1
                        AND a.sorlcur_lmod_code = 'LEARNER'
                        AND a.SORLCUR_PIDM =LN_PIDM
                        AND a.sorlcur_seqno = (SELECT MAX (a1.sorlcur_seqno)
                                                           FROM sorlcur A1
                                                           WHERE 1=1
                                                           AND a.sorlcur_pidm = a1.sorlcur_pidm
                                                           AND a.sorlcur_lmod_code = a1.sorlcur_lmod_code);


ln_amount_calc := ln_amount_plp / ln_rate;
 dbms_output.put_line ('no_materias'||no_materias);

   if no_materias >= 1 then 
                    FOR calc IN (
                SELECT UNIQUE
                    a.tbraccd_pidm pidm,a.tbraccd_effective_date,
                    b.tbbdetc_desc,
                    a.tbraccd_amount,
                    a.tbraccd_balance,
                    a.tbraccd_tran_number_paid,
                    a.TBRACCD_TRAN_NUMBER,
                    a.TBRACCD_CURR_CODE
                FROM
                    tbraccd a,
                    tbbdetc b
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                    AND a.tbraccd_pidm = LN_PIDM
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo
                    AND a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    AND a.tbraccd_feed_date IS NOT NULL
                    AND a.tbraccd_detail_code IN ( SELECT TZTNCD_CODE
                            FROM tztncd, tbbdetc
                            WHERE TZTNCD_concepto = 'Venta'
                            AND TBBDETC_detail_code = TZTNCD_CODE
                            AND TBBDETC_type_ind = 'C'
                            AND TBBDETC_detc_active_ind = 'Y'
                            AND TBBDETC_dcat_code = 'COL'
                            AND TBBDETC_taxt_code NOT IN ('GN','EC','CU','ES','ID','BA') )
            ) LOOP
    ln_cnt := ln_cnt+1;
    
        dbms_output.put_line('calcpagos :'||calc.tbbdetc_desc);
    dbms_output.put_line('calcpagos2 :'||calc.tbraccd_amount);
    dbms_output.put_line('calcpagos3 :'||to_char(ln_porcentaje)||'%');
        dbms_output.put_line('calcpagos4 :'||ln_calculo);
    
                SELECT SUM (TBRACCD_AMOUNT)
              INTO ln_amount_y1 
              FROM TBRACCD
             WHERE     TBRACCD_PIDM = LN_PIDM
               AND SUBSTR (TBRACCD_DETAIL_CODE, 3, 2) = 'Y1'
               AND TBRACCD_FEED_DATE = p_fecha_ini
               and tbraccd_effective_date = calc.tbraccd_effective_date;
               
                INSERT INTO SZTCALP (
                    fecha_vencimiento,
                    concepto,
                    monto_anterior,
                    pct_alta_baja,
                    monto_cajuste,
                    monto_accesorios,
                    pidm,
                    fec_calculo,
                    fec_inicial,
                    MONTO_Y1_ALTAS
                ) VALUES (
                    calc.tbraccd_effective_date,
                    calc.tbbdetc_desc,
                    ln_amount_calc,
                    --to_char(ln_porcentaje)||'%',
                    to_char(ln_porcentaje*no_materias)||'%',
                    round((ln_amount_calc + ( ( ln_amount_calc* ln_calculo ) / 100 ))),
                    NULL,
                    LN_PIDM,
                    sysdate,
                    p_fecha_ini,
                    ln_amount_y1
                );
                commit;
                
            BEGIN
                SELECT
                    unique substr(tbraccd_term_code, 1, 2)
                INTO lv_codigo
                FROM
                    tbraccd
                WHERE
                    tbraccd_pidm = calc.pidm;

            END;

            BEGIN
                SELECT DISTINCT
                    tbbdetc_desc,
                    tbbdetc_detail_code
                INTO
                    lv_descripcion,
                    lv_codigo_d
                FROM
                    tbbdetc
                WHERE
                        1 = 1
                    AND  tbbdetc_detail_code = lv_codigo || 'Y1';

            END;
                        

                        
if ln_cnt <= 1 then 
dbms_output.put_line('ln_cnt1 :'||ln_cnt);
    ln_trans_paid := null;
    --if calc.tbraccd_balance < (calc.tbraccd_amount + ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
    --ln_trans_paid := null;
   -- dbms_output.put_line('ln_cnt2 :'||ln_cnt);
   -- elsif calc.tbraccd_balance >= (calc.tbraccd_amount + ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
   -- dbms_output.put_line('ln_cnt3 :'||ln_cnt);
   -- ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
   -- end if;

elsif ln_cnt > 1 then 
dbms_output.put_line('ln_cnt4 :'||ln_cnt);
ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
end if;
--general
    if calc.tbraccd_balance = 0 then 
    ln_trans_paid := null;
    elsif calc.tbraccd_balance >= (calc.tbraccd_amount - ( ( calc.tbraccd_amount * ln_calculo ) / 100 )) then 
    dbms_output.put_line('ln_Y2 :'||ln_cnt);
    ln_trans_paid := calc.TBRACCD_TRAN_NUMBER;
    end if;
 dbms_output.put_line ('inserto TBRACCD_TMP_ALTAS');

                         INSERT INTO taismgr.TBRACCD_TMP_ALTAS
                         (TBRACCD_PIDM                
                                                ,TBRACCD_TRAN_NUMBER         
                                                ,TBRACCD_TERM_CODE           
                                                ,TBRACCD_DETAIL_CODE         
                                                ,TBRACCD_USER                
                                                ,TBRACCD_ENTRY_DATE          
                                                ,TBRACCD_AMOUNT              
                                                ,TBRACCD_BALANCE             
                                                ,TBRACCD_EFFECTIVE_DATE      
                                                ,TBRACCD_BILL_DATE           
                                                ,TBRACCD_DUE_DATE            
                                                ,TBRACCD_DESC                
                                                ,TBRACCD_RECEIPT_NUMBER      
                                                ,TBRACCD_TRAN_NUMBER_PAID    
                                                ,TBRACCD_CROSSREF_PIDM       
                                                ,TBRACCD_CROSSREF_NUMBER     
                                                ,TBRACCD_CROSSREF_DETAIL_CODE
                                                ,TBRACCD_SRCE_CODE           
                                                ,TBRACCD_ACCT_FEED_IND       
                                                ,TBRACCD_ACTIVITY_DATE       
                                                ,TBRACCD_SESSION_NUMBER      
                                                ,TBRACCD_CSHR_END_DATE       
                                                ,TBRACCD_CRN                 
                                                ,TBRACCD_CROSSREF_SRCE_CODE  
                                                ,TBRACCD_LOC_MDT             
                                                ,TBRACCD_LOC_MDT_SEQ         
                                                ,TBRACCD_RATE                
                                                ,TBRACCD_UNITS               
                                                ,TBRACCD_DOCUMENT_NUMBER     
                                                ,TBRACCD_TRANS_DATE          
                                                ,TBRACCD_PAYMENT_ID          
                                                ,TBRACCD_INVOICE_NUMBER      
                                                ,TBRACCD_STATEMENT_DATE      
                                                ,TBRACCD_INV_NUMBER_PAID     
                                                ,TBRACCD_CURR_CODE           
                                                ,TBRACCD_EXCHANGE_DIFF       
                                                ,TBRACCD_FOREIGN_AMOUNT      
                                                ,TBRACCD_LATE_DCAT_CODE      
                                                ,TBRACCD_FEED_DATE           
                                                ,TBRACCD_FEED_DOC_CODE       
                                                ,TBRACCD_ATYP_CODE           
                                                ,TBRACCD_ATYP_SEQNO          
                                                ,TBRACCD_CARD_TYPE_VR        
                                                ,TBRACCD_CARD_EXP_DATE_VR    
                                                ,TBRACCD_CARD_AUTH_NUMBER_VR 
                                                ,TBRACCD_CROSSREF_DCAT_CODE  
                                                ,TBRACCD_ORIG_CHG_IND        
                                                ,TBRACCD_CCRD_CODE           
                                                ,TBRACCD_MERCHANT_ID         
                                                ,TBRACCD_TAX_REPT_YEAR       
                                                ,TBRACCD_TAX_REPT_BOX        
                                                ,TBRACCD_TAX_AMOUNT          
                                                ,TBRACCD_TAX_FUTURE_IND      
                                                ,TBRACCD_DATA_ORIGIN         
                                                ,TBRACCD_CREATE_SOURCE       
                                                ,TBRACCD_CPDT_IND            
                                                ,TBRACCD_AIDY_CODE           
                                                ,TBRACCD_STSP_KEY_SEQUENCE   
                                                ,TBRACCD_PERIOD              
                                                ,TBRACCD_SURROGATE_ID        
                                                ,TBRACCD_VERSION             
                                                ,TBRACCD_USER_ID             
                                                ,TBRACCD_VPDI_CODE  
                                                ,TBRACCD_FECHA_INSERCION
                                                )                    
                            VALUES ( pidm,                          
                                    0, --ln_secuencia,                
                                     lv_periodo,                     
                                     lv_codigo_d,                      
                                     p_user,                           
                                     SYSDATE,                        
                                     (( ln_amount_calc * ln_calculo ) / 100 ),
                                     (( ln_amount_calc * ln_calculo ) / 100 ),
                                    --ln_amount_calc +(ln_amount_calc + ( ( ln_amount_calc * ln_calculo ) / 100 )),                
                                    --ln_amount_calc +(ln_amount_calc + ( ( ln_amount_calc * ln_calculo ) / 100 )),               
                                    calc.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     lv_descripcion,                 
                                     NULL,--CX.ORDEN,                       
                                     ln_trans_paid,--tran_paid                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'T',                            
                                     'Y',                            
                                     SYSDATE,                        
                                     0,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                    calc.tbraccd_effective_date, 
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     calc.TBRACCD_CURR_CODE,                          
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     p_fecha_ini,--CX.FECHA_INICIO,                
                                     1,                              
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     NULL,                           
                                     'ALTAS_MAT',                 
                                     'ALTAS_MAT',                 
                                     NULL,                           
                                     NULL,                           
                                     p_sp, --CX.SP,                          
                                     p_periodo,--CX.PERIODO,                     
                                     0,                           
                                     0,                           
                                     p_user,                           
                                     0,
                                     trunc(SYSDATE)); 
                                     COMMIT;

            po_respuesta := '00';
END LOOP;
FOR ACC IN (SELECT UNIQUE
                    a.tbraccd_pidm pidm,a.tbraccd_effective_date,
                    b.tbbdetc_desc,
                    a.tbraccd_amount
                FROM
                    tbraccd a,
                    tbbdetc b,
                    TZTINC c
                WHERE
                        a.tbraccd_detail_code = b.tbbdetc_detail_code
                        AND  a.tbraccd_detail_code = c.codigo 
                    AND a.tbraccd_pidm = LN_PIDM
                    AND a.TBRACCD_PERIOD = p_periodo
                    AND a.tbraccd_term_code = lv_periodo)
                     LOOP
                INSERT INTO SZTCALP (
                    fecha_vencimiento,
                    concepto,
                    monto_anterior,
                    pct_alta_baja,
                    monto_cajuste,
                    monto_accesorios,
                    pidm,
                    fec_calculo,
                    fec_inicial
                ) VALUES (
                    acc.tbraccd_effective_date,
                    acc.tbbdetc_desc,
                    null,
                    null,
                    null,
                    round(acc.tbraccd_amount),
                    pidm,
                    sysdate,
                    p_fecha_ini
                );
                commit;
                end loop;
--end if;
END IF;
        INSERT INTO TAISMGR.TZTBABC
        (
          TZTBABC_PIDM     ,
          TZTBABC_ID           ,
          TZTBABC_FEC_INI     ,
          TZTBABC_AJUSTE       ,
          TZTBABC_PORC_AJUSTE,
          TZTBABC_STAT_IND,
          TZTBABC_PROGRAMA,
          TZTBABC_MATERIA  )
          VALUES 
          (LN_PIDM,
          F_MATRICULA (pidm),
          P_FECHA_INI,
          'AM',
          ln_porcentaje,
          0,
          P_PROGRAMA,
          P_CVE_MATERIA);
          commit;
          
          
       -- execute immediate 'truncate table tbraccd_tmp_bajas';
    END p_alta_materias_dina;

--   
--
      PROCEDURE P_EDO_CTA_ALTA_MATERIAS (P_PIDM NUMBER) 
      AS
              ln_secuencia   NUMBER;
      BEGIN

FOR TBR IN (select
                    tbraccd_pidm,
                    tbraccd_tran_number,
                    tbraccd_term_code,
                    tbraccd_detail_code,
                    tbraccd_user,
                    tbraccd_entry_date,
                    round(tbraccd_amount,0) as tbraccd_amount ,
                    round(tbraccd_balance,0) as tbraccd_balance,
                    tbraccd_effective_date,
                    tbraccd_bill_date,
                    tbraccd_due_date,
                    tbraccd_desc,
                    tbraccd_receipt_number,
                    tbraccd_tran_number_paid,
                    tbraccd_crossref_pidm,
                    tbraccd_crossref_number,
                    tbraccd_crossref_detail_code,
                    tbraccd_srce_code,
                    tbraccd_acct_feed_ind,
                    tbraccd_activity_date,
                    tbraccd_session_number,
                    tbraccd_cshr_end_date,
                    tbraccd_crn,
                    tbraccd_crossref_srce_code,
                    tbraccd_loc_mdt,
                    tbraccd_loc_mdt_seq,
                    tbraccd_rate,
                    tbraccd_units,
                    tbraccd_document_number,
                    tbraccd_trans_date,
                    tbraccd_payment_id,
                    tbraccd_invoice_number,
                    tbraccd_statement_date,
                    tbraccd_inv_number_paid,
                    tbraccd_curr_code,
                    tbraccd_exchange_diff,
                    tbraccd_foreign_amount,
                    tbraccd_late_dcat_code,
                    tbraccd_feed_date,
                    tbraccd_feed_doc_code,
                    tbraccd_atyp_code,
                    tbraccd_atyp_seqno,
                    tbraccd_card_type_vr,
                    tbraccd_card_exp_date_vr,
                    tbraccd_card_auth_number_vr,
                    tbraccd_crossref_dcat_code,
                    tbraccd_orig_chg_ind,
                    tbraccd_ccrd_code,
                    tbraccd_merchant_id,
                    tbraccd_tax_rept_year,
                    tbraccd_tax_rept_box,
                    tbraccd_tax_amount,
                    tbraccd_tax_future_ind,
                    tbraccd_data_origin,
                    tbraccd_create_source,
                    tbraccd_cpdt_ind,
                    tbraccd_aidy_code,
                    tbraccd_stsp_key_sequence,
                    tbraccd_period,
                    tbraccd_surrogate_id,
                    tbraccd_version,
                    tbraccd_user_id,
                    tbraccd_vpdi_code    
                    from TAISMGR.TBRACCD_TMP_ALTAS  where TBRACCD_PIDM = p_pidm 
                    and tbraccd_amount > 0
                    order by tbraccd_effective_date)
                    LOOP

            ln_secuencia := 0;
            BEGIN
                SELECT
                    MAX(tbraccd_tran_number)+1
                INTO ln_secuencia
                FROM
                    tbraccd
                WHERE
                    tbraccd_pidm = p_pidm;

            EXCEPTION
                WHEN OTHERS THEN
                    ln_secuencia := 0;
            END;

                                    -- Entra 1er. cargo
                INSERT INTO TAISMGR.TBRACCD (
                    tbraccd_pidm,
                    tbraccd_tran_number,
                    tbraccd_term_code,
                    tbraccd_detail_code,
                    tbraccd_user,
                    tbraccd_entry_date,
                    tbraccd_amount,
                    tbraccd_balance,
                    tbraccd_effective_date,
                    tbraccd_bill_date,
                    tbraccd_due_date,
                    tbraccd_desc,
                    tbraccd_receipt_number,
                    tbraccd_tran_number_paid,
                    tbraccd_crossref_pidm,
                    tbraccd_crossref_number,
                    tbraccd_crossref_detail_code,
                    tbraccd_srce_code,
                    tbraccd_acct_feed_ind,
                    tbraccd_activity_date,
                    tbraccd_session_number,
                    tbraccd_cshr_end_date,
                    tbraccd_crn,
                    tbraccd_crossref_srce_code,
                    tbraccd_loc_mdt,
                    tbraccd_loc_mdt_seq,
                    tbraccd_rate,
                    tbraccd_units,
                    tbraccd_document_number,
                    tbraccd_trans_date,
                    tbraccd_payment_id,
                    tbraccd_invoice_number,
                    tbraccd_statement_date,
                    tbraccd_inv_number_paid,
                    tbraccd_curr_code,
                    tbraccd_exchange_diff,
                    tbraccd_foreign_amount,
                    tbraccd_late_dcat_code,
                    tbraccd_feed_date,
                    tbraccd_feed_doc_code,
                    tbraccd_atyp_code,
                    tbraccd_atyp_seqno,
                    tbraccd_card_type_vr,
                    tbraccd_card_exp_date_vr,
                    tbraccd_card_auth_number_vr,
                    tbraccd_crossref_dcat_code,
                    tbraccd_orig_chg_ind,
                    tbraccd_ccrd_code,
                    tbraccd_merchant_id,
                    tbraccd_tax_rept_year,
                    tbraccd_tax_rept_box,
                    tbraccd_tax_amount,
                    tbraccd_tax_future_ind,
                    tbraccd_data_origin,
                    tbraccd_create_source,
                    tbraccd_cpdt_ind,
                    tbraccd_aidy_code,
                    tbraccd_stsp_key_sequence,
                    tbraccd_period,
                    tbraccd_surrogate_id,
                    tbraccd_version,
                    tbraccd_user_id,
                    tbraccd_vpdi_code                    
                ) values(
                tbr.tbraccd_pidm,
                    ln_secuencia,
                    tbr.tbraccd_term_code,
                    tbr.tbraccd_detail_code,
                    tbr.tbraccd_user,
                    tbr.tbraccd_entry_date,
                    tbr.tbraccd_amount,
                    tbr.tbraccd_balance,
                    tbr.tbraccd_effective_date,
                    tbr.tbraccd_bill_date,
                    tbr.tbraccd_due_date,
                    tbr.tbraccd_desc,
                    tbr.tbraccd_receipt_number,
                    tbr.tbraccd_tran_number_paid,
                    tbr.tbraccd_crossref_pidm,
                    tbr.tbraccd_crossref_number,
                    tbr.tbraccd_crossref_detail_code,
                    tbr.tbraccd_srce_code,
                    tbr.tbraccd_acct_feed_ind,
                    tbr.tbraccd_activity_date,
                    tbr.tbraccd_session_number,
                    tbr.tbraccd_cshr_end_date,
                    tbr.tbraccd_crn,
                    tbr.tbraccd_crossref_srce_code,
                    tbr.tbraccd_loc_mdt,
                    tbr.tbraccd_loc_mdt_seq,
                    tbr.tbraccd_rate,
                    tbr.tbraccd_units,
                    tbr.tbraccd_document_number,
                    tbr.tbraccd_trans_date,
                    tbr.tbraccd_payment_id,
                    tbr.tbraccd_invoice_number,
                    tbr.tbraccd_statement_date,
                    tbr.tbraccd_inv_number_paid,
                    tbr.tbraccd_curr_code,
                    tbr.tbraccd_exchange_diff,
                    tbr.tbraccd_foreign_amount,
                    tbr.tbraccd_late_dcat_code,
                    tbr.tbraccd_feed_date,
                    tbr.tbraccd_feed_doc_code,
                    tbr.tbraccd_atyp_code,
                    tbr.tbraccd_atyp_seqno,
                    tbr.tbraccd_card_type_vr,
                    tbr.tbraccd_card_exp_date_vr,
                    tbr.tbraccd_card_auth_number_vr,
                    tbr.tbraccd_crossref_dcat_code,
                    tbr.tbraccd_orig_chg_ind,
                    tbr.tbraccd_ccrd_code,
                    tbr.tbraccd_merchant_id,
                    tbr.tbraccd_tax_rept_year,
                    tbr.tbraccd_tax_rept_box,
                    tbr.tbraccd_tax_amount,
                    tbr.tbraccd_tax_future_ind,
                    tbr.tbraccd_data_origin,
                    tbr.tbraccd_create_source,
                    tbr.tbraccd_cpdt_ind,
                    tbr.tbraccd_aidy_code,
                    tbr.tbraccd_stsp_key_sequence,
                    tbr.tbraccd_period,
                    tbr.tbraccd_surrogate_id,
                    tbr.tbraccd_version,
                    tbr.tbraccd_user_id,
                    tbr.tbraccd_vpdi_code);
                  --  commit;
                    end loop;
                    
      execute immediate 'truncate table TAISMGR.tbraccd_tmp_altas';
  
END P_EDO_CTA_ALTA_MATERIAS;
--         
--
FUNCTION  F_CALC_AMOUNT_ACC (P_PIDM NUMBER) RETURN NUMBER AS

        ln_amount_padi NUMBER := 0;
        ln_amount_face NUMBER := 0;
        ln_valida_paq  NUMBER := 0;
        ln_cnt_padi_ms NUMBER := 0;
        ln_cnt_face_ms NUMBER := 0;
        ln_cnt_ms_d    NUMBER := 0;
        ln_cnt_ms_f    NUMBER := 0;
        ln_amount_acc  NUMBER := 0;
        ln_amount_ms_d NUMBER := 0;
        ln_amount_ms_f NUMBER := 0;

BEGIN
        
        SELECT COUNT(1) 
       INTO ln_valida_paq
        FROM GORADID 
        WHERE GORADID_PIDM = p_pidm  
        AND GORADID_ADID_CODE= 'DINA';        
     
     --Dina     
     IF ln_valida_paq > 0 THEN 
     
            
                BEGIN
                SELECT SUM (TZTPADI_AMOUNT)
                  INTO ln_amount_padi
                  FROM tztpadi a
                 WHERE     a.TZTPADI_PIDM = p_pidm
                       AND a.TZTPADI_FLAG = '0'
                       AND a.TZTPADI_REQUEST IN (SELECT b.solicitud
                                                   FROM SZTACTU b
                                                  WHERE     b.pidm = a.TZTPADI_PIDM
                                                        AND FECHA_REGISTRO IN (SELECT MAX (
                                                                                         c.FECHA_REGISTRO)
                                                                                 FROM SZTACTU c
                                                                                WHERE     c.pidm =
                                                                                             b.pidm
                                                                                      AND estatus =
                                                                                             3
                                                                                      AND evento =
                                                                                             7)); 
                EXCEPTION WHEN OTHERS THEN 
                ln_amount_padi := 0;
                END;
                
                
        SELECT COUNT(1)
          INTO ln_cnt_padi_ms
          FROM tztpadi 
         WHERE     TZTPADI_PIDM = p_PIDM
               AND SUBSTR (tztpadi_DETAIL_CODE, 3, 2) IN ('CY', '4U');

        if ln_cnt_padi_ms > 0 then 
        SELECT COUNT (1)
          INTO ln_cnt_ms_d
          FROM GORADID
         WHERE GORADID_PIDM = p_PIDM AND GORADID_ADID_CODE IN ('MDSB', 'MDSP');
          
            if ln_cnt_ms_d > 0 then        
            SELECT sum(a.TZTPADI_AMOUNT)
              INTO ln_amount_ms_d
              FROM tztpadi a
             WHERE     a.TZTPADI_PIDM = p_PIDM
                   AND SUBSTR (a.tztpadi_DETAIL_CODE, 3, 2) IN ('CY', '4U')
                  and a.TZTPADI_SEQNO in (select max(b.TZTPADI_SEQNO) 
                         from tztpadi b 
                        where b.TZTPADI_PIDM =a.TZTPADI_PIDM
                          and SUBSTR (b.tztpadi_DETAIL_CODE, 3, 2) IN ('CY', '4U'));
            end if;

        end if;       
        
        ln_amount_acc := ln_amount_padi + ln_amount_ms_d;
     
     --Fija
     ELSE     
                BEGIN
                SELECT SUM (TZFACCE_AMOUNT)
                  INTO ln_amount_face 
                  FROM TZFACCE
                 WHERE     TZFACCE_PIDM = p_PIDM
                       AND SUBSTR (TZFACCE_DETAIL_CODE, 3, 2) IN (SELECT ZSTPARA_PARAM_VALOR
                                                                    FROM zstpara
                                                                   WHERE zstpara_mapa_id =
                                                                            'ACCS_AJ_AB')
                       AND TZFACCE_FLAG = 0;
                EXCEPTION WHEN OTHERS THEN 
                ln_amount_face := 0;
                END;
                
                
        SELECT COUNT(1)
          INTO ln_cnt_face_ms
          FROM TZFACCE
         WHERE     TZFACCE_PIDM = p_PIDM
               AND SUBSTR (TZFACCE_DETAIL_CODE, 3, 2) IN ('CY', '4U');

        if ln_cnt_face_ms > 0 then 
        SELECT COUNT (1)
          INTO ln_cnt_ms_f
          FROM GORADID
         WHERE GORADID_PIDM = p_PIDM AND GORADID_ADID_CODE IN ('MDSB', 'MDSP');
          
            if ln_cnt_ms_f > 0 then        
            SELECT sum(TZFACCE_AMOUNT)
              INTO ln_amount_ms_f
              FROM TZFACCE a
             WHERE     a.TZFACCE_PIDM = p_PIDM
                   AND SUBSTR (a.TZFACCE_DETAIL_CODE, 3, 2) IN ('CY', '4U')
                   and a.TZFACCE_SEC_PIDM in (select max(b.TZFACCE_SEC_PIDM) 
                                         from TZFACCE b 
                                        where b.TZFACCE_PIDM =a.TZFACCE_PIDM
                                          and SUBSTR (b.TZFACCE_DETAIL_CODE, 3, 2) IN ('CY', '4U'))     ;              

            end if;

        end if;       
        
        ln_amount_acc := ln_amount_face + ln_amount_ms_f;
        
     END IF ;
     
     
    RETURN (ln_amount_acc);  

END F_CALC_AMOUNT_ACC;
--
--
 FUNCTION f_calc_alta_materias_2 (
        p_pidm        IN VARCHAR2
    ) RETURN pkg_alta_baja_materias.cursor_CALCRA_out AS
        C_CALCRA_OUT     pkg_alta_baja_materias.cursor_CALCRA_out;
        
        ln_amount_acc NUMBER := 0;
        ld_fec_ini    DATE;
        ln_amount_y1  NUMBER := 0;
        
        
    BEGIN
       
        BEGIN
          --Accesorios
           SELECT F_CALC_AMOUNT_ACC ( P_PIDM ) 
             INTO ln_amount_acc
             FROM dual;
                                                                                                        
            OPEN C_CALCRA_OUT 
            FOR 
              SELECT UNIQUE
                     LTRIM(UPPER (
                        TO_CHAR (FECHA_VENCIMIENTO, 'Month', 'nls_date_language=spanish')))
                        MES,
                     SUM (NVL (MONTO_CAJUSTE, 0) 
                     + NVL (MONTO_ACCESORIOS, 0) 
                     + NVL(MONTO_Y1_ALTAS,0) 
                     )+ NVL(ln_amount_acc,0) MONTO_PAGAR ,
                     FECHA_VENCIMIENTO
                FROM SZTCALP
               WHERE pidm = p_pidm
            GROUP BY FECHA_VENCIMIENTO
            ORDER BY FECHA_VENCIMIENTO;
            --ORDER BY TO_dATE(MES,'MM') ;

            RETURN ( C_CALCRA_OUT );
        END;

    END f_calc_alta_materias_2;
   
--Valida bajas
FUNCTION F_VALIDA_BAJA_MAT (P_PIDM NUMBER, P_PERIODO VARCHAR2, P_SP VARCHAR2)
   RETURN VARCHAR2
AS
   ln_count      NUMBER;
   ln_bimestre   NUMBER := 0;
   lv_max_periodo VARCHAR2(20);
   
   lv_return     VARCHAR2 (1000) := 'EXITO';
BEGIN
   BEGIN
      SELECT MAX(TBRACCD_TERM_CODE)
        INTO lv_max_periodo
        FROM tbraccd
       WHERE     tbraccd_pidm = p_pidm
         AND tbraccd_detail_code IN (SELECT TZTNCD_CODE
                                        FROM tztncd, tbbdetc
                                        WHERE TZTNCD_concepto = 'Venta'
                                        AND TBBDETC_detail_code = TZTNCD_CODE
                                        AND TBBDETC_type_ind = 'C'
                                        AND TBBDETC_detc_active_ind = 'Y'
                                        AND TBBDETC_dcat_code = 'COL'
                                        AND TBBDETC_taxt_code NOT IN ('GN','EC','CU','ES','ID','BA'));
       
      SELECT COUNT (1)
        INTO ln_count
        FROM
            tbraccd A, tbbdetc c,  SZVCAMP B
        WHERE c.TBBDETC_DETAIL_CODE = a.TBRACCD_DETAIL_CODE
        and    substr(A.tbraccd_detail_code, 1, 2) = B.SZVCAMP_CAMP_ALT_CODE
        AND a.tbraccd_pidm = p_pidm
        AND a.TBRACCD_PERIOD = p_periodo
        and a.TBRACCD_TERM_CODE = lv_max_periodo
        AND a.TBRACCD_STSP_KEY_SEQUENCE =p_sp
        AND a.tbraccd_detail_code IN (SELECT TZTNCD_CODE
                                        FROM tztncd, tbbdetc
                                        WHERE TZTNCD_concepto = 'Venta'
                                        AND TBBDETC_detail_code = TZTNCD_CODE
                                        AND TBBDETC_type_ind = 'C'
                                        AND TBBDETC_detc_active_ind = 'Y'
                                        AND TBBDETC_dcat_code = 'COL'
                                        AND TBBDETC_taxt_code NOT IN ('GN','EC','CU','ES','ID','BA')                                
               );            
      IF ln_count <= 0
      THEN
         lv_return :=
            ' El alumno no cuenta con colegiaturas cargadas para el bimestre en curso. Favor de validar con el equipo de CXC';
      END IF;
   END;

   BEGIN
      SELECT TO_NUMBER (
                NVL (PKG_UTILERIAS.F_CALCULA_BIMESTRES (p_PIDM, p_SP), 0))
        INTO ln_bimestre
        FROM DUAL;

      IF ln_bimestre <= 2
      THEN
         lv_return :=
            'De acuerdo a tu avance académico, por el momento no es posible realizar este proceso.';
      END IF;
   END;
   
   RETURN lv_return;
EXCEPTION WHEN OTHERS THEN 
   lv_return:= 'ERROR '||SQLERRM;
   RETURN lv_return;
END F_VALIDA_BAJA_MAT;      
--
--   
END;
/

DROP PUBLIC SYNONYM PKG_ALTA_BAJA_MATERIAS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ALTA_BAJA_MATERIAS FOR BANINST1.PKG_ALTA_BAJA_MATERIAS;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_ALTA_BAJA_MATERIAS TO PUBLIC;
