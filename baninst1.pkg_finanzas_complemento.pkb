DROP PACKAGE BODY BANINST1.PKG_FINANZAS_COMPLEMENTO;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_FINANZAS_COMPLEMENTO AS
/******************************************************************************
   NAME:       PKG_FINANZAS_COMPLEMENTO
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/08/2023      vramirlo       1. Created this package body.
******************************************************************************/

Procedure GENERA_COMPLEMENTO ( P_CAMPUS         VARCHAR2,
                             P_NIVEL          VARCHAR2,
                             P_PIDM           NUMBER,
                             P_PERIODO        VARCHAR2,
                             P_PROGRAMA       VARCHAR2,
                             P_STUDY_PATH     NUMBER,
                             P_RATE           NUMBER,
                             P_INICIO_MES     DATE,
                             P_fecha_inicio   DATE,
                             p_matricula      varchar2,    
                             p_pperiodo       varchar2,
                             p_monto          number,
                             p_codigo         varchar2,
                             P_complemento    number                   
                                                     ) IS


 VL_FECHA_SOLI      DATE;
 VL_CODIGO          VARCHAR2(5);
 VL_DESCRIP         VARCHAR2(50);
 VL_MONTO           NUMBER;
 VL_ERROR           VARCHAR2(900);
 VL_ENTRA           NUMBER;
 VL_FECHA_PARA      DATE;
 VL_EXCLUIDO        NUMBER;
 VL_IZZI            NUMBER;
 VL_PORC            NUMBER;
 VL_IZZI_COM        NUMBER;
 vl_existe_inco  number;
 vl_vigencia     number;
 vl_vencimiento  date;
 LV_TRAN_NUM_2   number:=0;
 VL_MONTO_Gen    number;
 VL_SECUENCIA    number;
 VL_SECUEN       number;
 vl_registro     number;
 vl_moneda       varchar2(5);
 

 BEGIN



   -- DBMS_OUTPUT.PUT_LINE('VL_ENTRA '||VL_ENTRA);





     BEGIN
       SELECT COUNT(*)
         INTO VL_EXCLUIDO
         FROM GORADID
        WHERE     GORADID_PIDM = P_PIDM
              AND GORADID_ADID_CODE = 'ESPA';
     END;
     
     --DBMS_OUTPUT.PUT_LINE('VL_EXCLUIDO '||VL_EXCLUIDO);

     BEGIN
       SELECT COUNT(*)
         INTO VL_IZZI
         FROM GORADID
        WHERE     GORADID_PIDM = P_PIDM
              AND GORADID_ADID_CODE = 'IZZI';
     END;

    -- DBMS_OUTPUT.PUT_LINE('VL_IZZI '||VL_IZZI);

         IF VL_IZZI > 0 THEN
         
            --DBMS_OUTPUT.PUT_LINE('ENTRA a IZZI '||VL_IZZI);


           BEGIN
             SELECT DISTINCT TBREDET_PERCENT
               INTO VL_PORC
               FROM TBBEXPT,TBBESTU A,TBBDETC,TBREDET
              WHERE     TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                    AND A.TBBESTU_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                    AND A.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                    AND A.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                    AND A.TBBESTU_DEL_IND IS NULL
                    AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                    AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                    AND A.TBBESTU_TERM_CODE = (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                                 FROM TBBESTU A1,TBBEXPT,TBREDET,TBBDETC
                                                WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                      AND TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                                      AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                      AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                      AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                      AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                      AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                      AND A1.TBBESTU_DEL_IND IS NULL
                                                      AND A1.TBBESTU_TERM_CODE <= P_PERIODO)
                    AND A.TBBESTU_EXEMPTION_PRIORITY = (SELECT MAX(B1.TBBESTU_EXEMPTION_PRIORITY)
                                                          FROM TBBESTU B1,TBBEXPT,TBREDET,TBBDETC
                                                         WHERE     B1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                               AND TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                                               AND B1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                               AND B1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                               AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                               AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                               AND B1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                               AND B1.TBBESTU_DEL_IND IS NULL
                                                               AND B1.TBBESTU_TERM_CODE = A.TBBESTU_TERM_CODE)
                    AND A.TBBESTU_PIDM = P_PIDM
                    AND TBBDETC_DCAT_CODE = 'DSP';
           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR :='Error al buscar el descuento DSP : ' ||SQLERRM;
           END;

           IF VL_PORC <= 90 THEN
             VL_IZZI_COM := 0;
           ELSE
             VL_IZZI_COM := 1;
           END IF;

         END IF;

         IF (VL_EXCLUIDO = 0 OR VL_IZZI_COM = 0 )THEN
            --DBMS_OUTPUT.PUT_LINE('ENTRA al NO Excluido ');
               vl_existe_inco:=0;
               VL_CODIGO:= null;
               VL_DESCRIP:= null;
               VL_MONTO:= null;
               vl_vigencia := null;             

             BEGIN
                    Select distinct TBBDETC_DESC, TVRDCTX_CURR_CODE
                        INTO VL_DESCRIP, vl_moneda
                     from tbbdetc
                     join tvrdctx on TVRDCTX_DETC_CODE = tbbdetc_detail_code
                     Where 1=1
                     And tbbdetc_detail_code = p_codigo;
             EXCEPTION
             WHEN OTHERS THEN
                 VL_ERROR:='ERROR AL CALCULAR CODIGO';
                 VL_CODIGO:= null;
                 VL_DESCRIP:= null;
                 VL_MONTO:= null;
                 vl_vigencia := null;
             END;

             IF VL_ERROR IS NULL and VL_DESCRIP is not null  THEN
                vl_vencimiento:= null;
                vl_vencimiento := P_INICIO_MES;
                 --DBMS_OUTPUT.PUT_LINE('Toma la fecha para cargo '||vl_vencimiento);
                 --DBMS_OUTPUT.PUT_LINE('Toma la fecha para cargo '||vl_vencimiento||'*'||P_RATE);
--                 If p_rate = 30 then 
--                   vl_vencimiento := vl_vencimiento + 29;
--                 Elsif p_rate = 15 then
--                    vl_vencimiento := vl_vencimiento + 14;
--                 Elsif p_rate = 10 then
--                    vl_vencimiento := vl_vencimiento + 9;
--                 End if;
                    -- DBMS_OUTPUT.PUT_LINE('agrega el rate la fecha para cargo '||vl_vencimiento);
                LV_TRAN_NUM_2:=0;
                VL_MONTO_Gen:=0;

                Begin 
                      Delete tzfacce
                      Where 1= 1
                      And tzfacce_pidm = p_pidm
                      And TZFACCE_DETAIL_CODE = p_codigo
                      And trunc (TZFACCE_EFFECTIVE_DATE) >= vl_vencimiento;
                Exception
                    When Others then 
                     null;
                End;

                Begin
                        Select a.tbraccd_amount  
                            Into VL_MONTO_Gen
                        from tbraccd a
                        Where 1=1
                        And a.tbraccd_pidm  = p_pidm
                        And a.tbraccd_detail_code = p_codigo
                        And a.TBRACCD_EFFECTIVE_DATE = (select max (a1.TBRACCD_EFFECTIVE_DATE)
                                                        from tbraccd a1
                                                        Where a.tbraccd_pidm = a1.tbraccd_pidm
                                                        And a.tbraccd_detail_code = a1.tbraccd_detail_code
                                                        );
                Exception
                    When Others then 
                     VL_MONTO_Gen:=0;
                End;

                If VL_MONTO_Gen > 0 then 
                    VL_MONTO:= VL_MONTO_Gen;
                End if;

                BEGIN
                     SELECT NVL(MAX(tzfacce_sec_pidm)+1,1)
                               INTO LV_TRAN_NUM_2
                               FROM tzfacce
                              WHERE 1=1
                                AND tzfacce_pidm = p_pidm;

                EXCEPTION
                   WHEN OTHERS THEN
                       LV_TRAN_NUM_2:=1;
                END;
                    
                ----------------- Valida que no tenga el accesorio cargado en el estado de cuenta -----------
                vl_registro:=0;
    
                Begin
                    
                    Select count(*)
                        Into vl_registro
                    from tbraccd
                    Where 1= 1
                    And tbraccd_pidm = p_pidm
                    And tbraccd_detail_code = p_codigo
                    And  trunc (TBRACCD_EFFECTIVE_DATE) = vl_vencimiento;
                Exception 
                    When others then 
                        vl_registro:=0;    
                End;
                
                        --DBMS_OUTPUT.PUT_LINE('Obtiene respuesta si existe o no el cargo '||vl_registro);

                If vl_registro = 0 then 

                    BEGIN
                         INSERT INTO TZFACCE
                         VALUES  (P_PIDM,                                --TZFACCE_PIDM
                                  LV_TRAN_NUM_2,                         --TZFACCE_SEC_PIDM
                                  P_PERIODO,                             --TZFACCE_TERM_CODE
                                  p_codigo,                         --TZFACCE_DETAIL_CODE
                                  VL_DESCRIP,                         --TZFACCE_DESC
                                  p_monto,                               --TZFACCE_AMOUNT
                                  vl_vencimiento,  --TZFACCE_EFFECTIVE_DATE
                                  'REZA',                                --TZFACCE_USER
                                  SYSDATE,                               --TZFACCE_ACTIVITY_DATE
                                  0,                                     --TZFACCE_FLAG
                                  P_STUDY_PATH);
                    EXCEPTION
                    WHEN OTHERS THEN
                    VL_ERROR:= 'ERROR INSERTAR TZFACCE'||SQLERRM;
                      -- DBMS_OUTPUT.PUT_LINE('Entra ERROR VL_CPM > 0 '||VL_ERROR);
                    END; 



                    VL_SECUENCIA:= pkg_finanzas.F_MAX_SEC_TBRACCD (P_PIDM);

                    if VL_ERROR is null then 
                       VL_SECUEN:= null;
                    
                        Begin
                        
                            Select TZTORDR_CONTADOR
                                Into VL_SECUEN
                            from TZTORDR
                            Where TZTORDR_CAMPUS = p_campus
                            And TZTORDR_NIVEL = p_nivel
                            And TZTORDR_PROGRAMA  = p_programa
                            And TZTORDR_PIDM = p_pidm
                            And trunc (TZTORDR_FECHA_INICIO) = P_fecha_inicio; 
                        
                        Exception
                            When Others then 
                                VL_SECUEN:=null;
                        End;
                    
                        If VL_SECUEN is null then 

                           BEGIN

                              SELECT nvl (MAX(TZTORDR_CONTADOR),0)+1
                                 INTO VL_SECUEN
                              FROM TZTORDR;
                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_SECUEN:= NULL;
                           END;

                           IF VL_SECUEN IS NOT NULL THEN

                              BEGIN

                                INSERT INTO TZTORDR
                                (
                                  TZTORDR_CAMPUS,
                                  TZTORDR_NIVEL,
                                  TZTORDR_CONTADOR,
                                  TZTORDR_PROGRAMA,
                                  TZTORDR_PIDM,
                                  TZTORDR_ID,
                                  TZTORDR_ESTATUS,
                                  TZTORDR_ACTIVITY_DATE,
                                  TZTORDR_USER,
                                  TZTORDR_DATA_ORIGIN,
                                  TZTORDR_NO_REGLA,
                                  TZTORDR_FECHA_INICIO,
                                  TZTORDR_RATE,
                                  TZTORDR_JORNADA,
                                  TZTORDR_DSI,
                                  TZTORDR_TERM_CODE
                                )
                                VALUES( p_campus,
                                        p_nivel,
                                        VL_SECUEN,
                                        p_programa,
                                        p_pidm,
                                        p_matricula,
                                        'S',
                                        SYSDATE,
                                        USER,
                                        'TZTFEDCA',
                                        NULL,
                                        p_fecha_inicio,
                                        null,
                                        null,
                                        null,
                                        p_periodo
                                        );
                              EXCEPTION
                              WHEN OTHERS THEN
                              VL_ERROR:= 'ERROR AL INSERTAR EN TZTORDR = '||SQLERRM;
                              END;

                           END IF;                
                    
                    
                        End if;
                

                        BEGIN
                           INSERT INTO TBRACCD
                           VALUES (
                                   P_PIDM,   -- TBRACCD_PIDM
                                   VL_SECUENCIA,     --TBRACCD_TRAN_NUMBER
                                   p_periodo,    -- TBRACCD_TERM_CODE
                                   p_codigo,--vp_inscrip_code,     ---TBRACCD_DETAIL_CODE
                                   USER,     ---TBRACCD_USER
                                   SYSDATE,     --TBRACCD_ENTRY_DATE
                                   NVL(p_monto,0),
                                   NVL(p_monto,0),    ---TBRACCD_BALANCE
                                   vl_vencimiento,     -- TBRACCD_EFFECTIVE_DATE
                                   NULL,    --TBRACCD_BILL_DATE
                                   NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                   VL_DESCRIP,    -- TBRACCD_DESC
                                   VL_SECUEN,     --TBRACCD_RECEIPT_NUMBER
                                   NULL,     --TBRACCD_TRAN_NUMBER_PAID
                                   NULL,     --TBRACCD_CROSSREF_PIDM
                                   NULL,    --TBRACCD_CROSSREF_NUMBER
                                   NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                   'T',    --TBRACCD_SRCE_CODE
                                   'Y',    --TBRACCD_ACCT_FEED_IND
                                   SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                   0,        --TBRACCD_SESSION_NUMBER
                                   NULL,    -- TBRACCD_CSHR_END_DATE
                                   NULL,     --TBRACCD_CRN
                                   NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                   NULL,     -- TBRACCD_LOC_MDT
                                   NULL,     --TBRACCD_LOC_MDT_SEQ
                                   NULL,     -- TBRACCD_RATE
                                   NULL,     --TBRACCD_UNITS
                                   NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                   VL_VENCIMIENTO,  -- TBRACCD_TRANS_DATE
                                   NULL,        -- TBRACCD_PAYMENT_ID
                                   NULL,     -- TBRACCD_INVOICE_NUMBER
                                   NULL,     -- TBRACCD_STATEMENT_DATE
                                   NULL,     -- TBRACCD_INV_NUMBER_PAID
                                   vl_moneda,     -- TBRACCD_CURR_CODE
                                   NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                   NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                   NULL,     -- TBRACCD_LATE_DCAT_CODE
                                   p_fecha_inicio,     -- TBRACCD_FEED_DATE
                                   NULL,     -- TBRACCD_FEED_DOC_CODE
                                   NULL,     -- TBRACCD_ATYP_CODE
                                   NULL,     -- TBRACCD_ATYP_SEQNO
                                   NULL,     -- TBRACCD_CARD_TYPE_VR
                                   NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                   NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                   NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                   NULL,     -- TBRACCD_ORIG_CHG_IND
                                   NULL,     -- TBRACCD_CCRD_CODE
                                   NULL,     -- TBRACCD_MERCHANT_ID
                                   NULL,     -- TBRACCD_TAX_REPT_YEAR
                                   NULL,     -- TBRACCD_TAX_REPT_BOX
                                   NULL,     -- TBRACCD_TAX_AMOUNT
                                   NULL,     -- TBRACCD_TAX_FUTURE_IND
                                   'TZFEDCA(ACC)',     -- TBRACCD_DATA_ORIGIN
                                   'TZFEDCA(ACC)',   -- TBRACCD_CREATE_SOURCE
                                   NULL,     -- TBRACCD_CPDT_IND
                                   NULL,     --TBRACCD_AIDY_CODE
                                   P_STUDY_PATH,--TBRACCD_STSP_KEY_SEQUENCE
                                   p_pperiodo,  --TBRACCD_PERIOD
                                   NULL,    --TBRACCD_SURROGATE_ID
                                   NULL,     -- TBRACCD_VERSION
                                   USER,     --TBRACCD_USER_ID
                                   NULL );     --TBRACCD_VPDI_CODE
                        EXCEPTION
                         WHEN OTHERS THEN
                         VL_ERROR := 'Se presento ERROR INSERT TBRACCD '||SQLERRM;
                        END;

                        If vl_error is null then 
                            VL_SECUEN:= VL_SECUENCIA;
                             
-----------------------INICIA  Se agrega la validacion para no generar el complemento cuanto tenga en el mismo mes el cargo de diploma Intermedia--------------------------

                            Begin 
                            
                                For cx in (

                                              select *
                                               from tbraccd
                                               where 1=1
                                               And tbraccd_pidm = P_PIDM
                                               And tbraccd_detail_code in (select TZTDIPL_CODE_DET
                                                                            from tZTDIPL
                                                                           where 1=1
                                                                           And TZTDIPL_ACTIVO = '1'
                                                                           And trunc (sysdate) between TZTDIPL_INI_VIGENCIA and TZTDIPL_FIN_VIGENCIA
                                                                           And TZTDIPL_CAMP_CODE = p_campus
                                                                           And TZTDIPL_LEVL_CODE = p_nivel)
                                              And trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and  TRUNC(LAST_DAY(SYSDATE))

                                ) loop
                            
                            
                                         BEGIN
                                                Select distinct TBBDETC_DESC, TVRDCTX_CURR_CODE
                                                    INTO VL_DESCRIP, vl_moneda
                                                 from tbbdetc
                                                 join tvrdctx on TVRDCTX_DETC_CODE = tbbdetc_detail_code
                                                 Where 1=1
                                                 And tbbdetc_detail_code = substr (p_codigo,1,2) ||'IS';
                                         EXCEPTION
                                         WHEN OTHERS THEN
                                             vl_moneda:= null;
                                             VL_DESCRIP:= null;
                                         END;                            
                                    
                                 ------------------------------ Genero la nota de credito del titulo intermedio -----------------
                                         BEGIN
                                         VL_SECUEN:= VL_SECUEN +1;
                                         
                                           INSERT INTO TBRACCD
                                           VALUES (
                                                   P_PIDM,   -- TBRACCD_PIDM
                                                   VL_SECUEN,     --TBRACCD_TRAN_NUMBER
                                                   cx.TBRACCD_TERM_CODE,    -- TBRACCD_TERM_CODE
                                                   substr (p_codigo,1,2) ||'IS',--vp_inscrip_code,     ---TBRACCD_DETAIL_CODE
                                                   USER,     ---TBRACCD_USER
                                                   SYSDATE,     --TBRACCD_ENTRY_DATE
                                                   cx.tbraccd_amount,
                                                   cx.tbraccd_amount*-1,    ---TBRACCD_BALANCE
                                                   cx.TBRACCD_EFFECTIVE_DATE,     -- TBRACCD_EFFECTIVE_DATE
                                                   NULL,    --TBRACCD_BILL_DATE
                                                   NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                                   VL_DESCRIP,    -- TBRACCD_DESC
                                                   cx.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                                                   cx.TBRACCD_TRAN_NUMBER,     --TBRACCD_TRAN_NUMBER_PAID
                                                   NULL,     --TBRACCD_CROSSREF_PIDM
                                                   NULL,    --TBRACCD_CROSSREF_NUMBER
                                                   NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                                   'T',    --TBRACCD_SRCE_CODE
                                                   'Y',    --TBRACCD_ACCT_FEED_IND
                                                   SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                                   0,        --TBRACCD_SESSION_NUMBER
                                                   NULL,    -- TBRACCD_CSHR_END_DATE
                                                   NULL,     --TBRACCD_CRN
                                                   NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                                   NULL,     -- TBRACCD_LOC_MDT
                                                   NULL,     --TBRACCD_LOC_MDT_SEQ
                                                   NULL,     -- TBRACCD_RATE
                                                   NULL,     --TBRACCD_UNITS
                                                   NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                                   cx.TBRACCD_TRANS_DATE,  -- TBRACCD_TRANS_DATE
                                                   NULL,        -- TBRACCD_PAYMENT_ID
                                                   NULL,     -- TBRACCD_INVOICE_NUMBER
                                                   NULL,     -- TBRACCD_STATEMENT_DATE
                                                   NULL,     -- TBRACCD_INV_NUMBER_PAID
                                                   vl_moneda,     -- TBRACCD_CURR_CODE
                                                   NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                                   NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                                   NULL,     -- TBRACCD_LATE_DCAT_CODE
                                                   cx.TBRACCD_FEED_DATE,     -- TBRACCD_FEED_DATE
                                                   NULL,     -- TBRACCD_FEED_DOC_CODE
                                                   NULL,     -- TBRACCD_ATYP_CODE
                                                   NULL,     -- TBRACCD_ATYP_SEQNO
                                                   NULL,     -- TBRACCD_CARD_TYPE_VR
                                                   NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                                   NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                                   NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                                   NULL,     -- TBRACCD_ORIG_CHG_IND
                                                   NULL,     -- TBRACCD_CCRD_CODE
                                                   NULL,     -- TBRACCD_MERCHANT_ID
                                                   NULL,     -- TBRACCD_TAX_REPT_YEAR
                                                   NULL,     -- TBRACCD_TAX_REPT_BOX
                                                   NULL,     -- TBRACCD_TAX_AMOUNT
                                                   NULL,     -- TBRACCD_TAX_FUTURE_IND
                                                   cx.TBRACCD_DATA_ORIGIN,     -- TBRACCD_DATA_ORIGIN
                                                   cx.TBRACCD_CREATE_SOURCE,   -- TBRACCD_CREATE_SOURCE
                                                   NULL,     -- TBRACCD_CPDT_IND
                                                   NULL,     --TBRACCD_AIDY_CODE
                                                   cx.TBRACCD_STSP_KEY_SEQUENCE,--TBRACCD_STSP_KEY_SEQUENCE
                                                   cx.TBRACCD_PERIOD,  --TBRACCD_PERIOD
                                                   NULL,    --TBRACCD_SURROGATE_ID
                                                   NULL,     -- TBRACCD_VERSION
                                                   USER,     --TBRACCD_USER_ID
                                                   NULL );     --TBRACCD_VPDI_CODE
                                         EXCEPTION
                                            WHEN OTHERS THEN
                                            VL_ERROR := 'Se presento ERROR INSERT TBRACCD '||SQLERRM;
                                         END;                                 
                                                 
                                         
                                    if VL_ERROR is null then 
                                            BEGIN
                                            VL_SECUEN:= VL_SECUEN +1;
                                         
                                           INSERT INTO TBRACCD
                                           VALUES (
                                                   P_PIDM,   -- TBRACCD_PIDM
                                                   VL_SECUEN,     --TBRACCD_TRAN_NUMBER
                                                   cx.TBRACCD_TERM_CODE,    -- TBRACCD_TERM_CODE
                                                   cx.TBRACCD_DETAIL_CODE,     ---TBRACCD_DETAIL_CODE
                                                   USER,     ---TBRACCD_USER
                                                   SYSDATE,     --TBRACCD_ENTRY_DATE
                                                   cx.tbraccd_amount,
                                                   cx.tbraccd_amount,    ---TBRACCD_BALANCE
                                                  ADD_MONTHS(cx.TBRACCD_EFFECTIVE_DATE,1),     -- TBRACCD_EFFECTIVE_DATE
                                                   NULL,    --TBRACCD_BILL_DATE
                                                   NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                                   cx.TBRACCD_DESC,    -- TBRACCD_DESC
                                                   cx.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                                                   null,     --TBRACCD_TRAN_NUMBER_PAID
                                                   NULL,     --TBRACCD_CROSSREF_PIDM
                                                   NULL,    --TBRACCD_CROSSREF_NUMBER
                                                   NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                                   'T',    --TBRACCD_SRCE_CODE
                                                   'Y',    --TBRACCD_ACCT_FEED_IND
                                                   SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                                   0,        --TBRACCD_SESSION_NUMBER
                                                   NULL,    -- TBRACCD_CSHR_END_DATE
                                                   NULL,     --TBRACCD_CRN
                                                   NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                                   NULL,     -- TBRACCD_LOC_MDT
                                                   NULL,     --TBRACCD_LOC_MDT_SEQ
                                                   NULL,     -- TBRACCD_RATE
                                                   NULL,     --TBRACCD_UNITS
                                                   NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                                   cx.TBRACCD_TRANS_DATE,  -- TBRACCD_TRANS_DATE
                                                   NULL,        -- TBRACCD_PAYMENT_ID
                                                   NULL,     -- TBRACCD_INVOICE_NUMBER
                                                   NULL,     -- TBRACCD_STATEMENT_DATE
                                                   NULL,     -- TBRACCD_INV_NUMBER_PAID
                                                   cx.TBRACCD_CURR_CODE,     -- TBRACCD_CURR_CODE
                                                   NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                                   NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                                   NULL,     -- TBRACCD_LATE_DCAT_CODE
                                                   cx.TBRACCD_FEED_DATE,     -- TBRACCD_FEED_DATE
                                                   NULL,     -- TBRACCD_FEED_DOC_CODE
                                                   NULL,     -- TBRACCD_ATYP_CODE
                                                   NULL,     -- TBRACCD_ATYP_SEQNO
                                                   NULL,     -- TBRACCD_CARD_TYPE_VR
                                                   NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                                   NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                                   NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                                   NULL,     -- TBRACCD_ORIG_CHG_IND
                                                   NULL,     -- TBRACCD_CCRD_CODE
                                                   NULL,     -- TBRACCD_MERCHANT_ID
                                                   NULL,     -- TBRACCD_TAX_REPT_YEAR
                                                   NULL,     -- TBRACCD_TAX_REPT_BOX
                                                   NULL,     -- TBRACCD_TAX_AMOUNT
                                                   NULL,     -- TBRACCD_TAX_FUTURE_IND
                                                   cx.TBRACCD_DATA_ORIGIN,     -- TBRACCD_DATA_ORIGIN
                                                   cx.TBRACCD_CREATE_SOURCE,   -- TBRACCD_CREATE_SOURCE
                                                   NULL,     -- TBRACCD_CPDT_IND
                                                   NULL,     --TBRACCD_AIDY_CODE
                                                   cx.TBRACCD_STSP_KEY_SEQUENCE,--TBRACCD_STSP_KEY_SEQUENCE
                                                   cx.TBRACCD_PERIOD,  --TBRACCD_PERIOD
                                                   NULL,    --TBRACCD_SURROGATE_ID
                                                   NULL,     -- TBRACCD_VERSION
                                                   USER,     --TBRACCD_USER_ID
                                                   NULL );     --TBRACCD_VPDI_CODE
                                         EXCEPTION
                                            WHEN OTHERS THEN
                                            VL_ERROR := 'Se presento ERROR INSERT TBRACCD '||SQLERRM;
                                         END;                               
                            
                            
                            
                                    End if;
                                    
                                End loop;
                        
                            Exception
                                When Others then 
                                    null;
                            End;
                        
                        End if;


                         DBMS_OUTPUT.PUT_LINE('Salida TBRACCD '||VL_ERROR);

                        If vl_error is null then 
                            begin 
                                Update TZFACCE
                                set TZFACCE_FLAG = 1
                                Where 1= 1
                                And TZFACCE_PIDM = p_pidm
                                And TZFACCE_DETAIL_CODE  = VL_CODIGO
                                And TZFACCE_SEC_PIDM  = LV_TRAN_NUM_2;
                            Exception
                                When Others then 
                                VL_ERROR := 'Se presento ERROR al actualizar TZFACCE '||SQLERRM;
                            End;
                        
                        
                            Begin 
                                Update complementos
                                set MONTO = NVL(p_monto,0),
                                    SALDO =  NVL(p_monto,0),
                                    CODIGO = p_codigo,
                                    VENCIMIENTO = vl_vencimiento,
                                    OBSERVACIONES = 'Se genero el cargo de forma correcta en el estado de cuenta',
                                    COMPLEMENTOS_INCREMENTO = P_complemento,
                                    COMPLEMENTO_CARGADOS = COMPLEMENTO_CARGADOS +1
                               Where PIDM = p_pidm;
                            Exception
                                When OThers then 
                                VL_ERROR := 'Se presento ERROR al actualizar complementos '||SQLERRM;
                            End;                        
                        
                        
                        
                        End if;

                    End if;  ---Vl_error
                
                End if;  ---- Valida existencia

             END IF;  -- Recupera los valores


         END IF;  --- End Excluido



  COMMIT;

 END GENERA_COMPLEMENTO;

------------------------------------------
-------------------------------------------------------------------------

procedure consulta_complemento(p_matricula in varchar2 default null) as 

Begin 

    delete migra.complementos;
    commit;

    For cx in (


                  Select distinct a.campus, 
                         a.nivel, 
                         a.matricula, 
                         a.programa,
                         a.estatus, 
                         a.fecha_inicio,
                 ( SELECT distinct max (TRUNC(SARADAP_APPL_DATE))
                     FROM SARADAP A
                    WHERE     A.SARADAP_PIDM = a.pidm
                          AND A.SARADAP_CAMP_CODE||A.SARADAP_LEVL_CODE = a.campus||a.nivel
                         -- AND A.SARADAP_APST_CODE = 'A'
                          AND A.SARADAP_APPL_NO = (SELECT MAX(SARADAP_APPL_NO)
                                                     FROM SARADAP
                                                    WHERE     SARADAP_PIDM = A.SARADAP_PIDM
                                                          AND SARADAP_CAMP_CODE||SARADAP_LEVL_CODE = a.campus||a.nivel
                                                         -- AND SARADAP_APST_CODE = 'A'
                                                          )
               )Fecha_Solicitud, 
               a.sp,
               (select distinct decode (count(*), '0', 'Sin_costo0', '1', 'Con_costo_0')
                 from tbraccd
                 Where tbraccd_pidm = a.pidm
                 And substr (tbraccd_detail_code, 3,2) = 'B0'
               ) Costo_Cero,
               (Select distinct count(*)
                from sfrstcr
                join ssbsect on  SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                Where 1= 1
                And SFRSTCR_PIDM = a.pidm
                And trunc (SSBSECT_PTRM_START_DATE)  = a.fecha_inicio
                and SFRSTCR_STSP_KEY_SEQUENCE = a.sp
                And SFRSTCR_RSTS_CODE = 'RE'
                And SFRSTCR_DATA_ORIGIN not in ('CONVALIDACION')
                And substr (SFRSTCR_TERM_CODE, 5,1) not in ('8', '9')
              ) Materia_Inscritas, 
                a.pidm,
                SGBSTDN_STYP_CODE tipo_alumno,
                TIPO_INGRESO_DESC Tipo_Ingreso
            from tztprog a 
            join stvcamp b on b.STVCAMP_CODE = campus
            where 1= 1
            And a.estatus = 'MA'
            --And a.campus ='UTL'
            --And a.nivel ='MA'
            and a.campus||a.nivel not in ( 'UTSID', 'UTSEC', 'INIEC')
            And a.sp = (select distinct max (a1.sp)
                            from tztprog a1
                            Where a.pidm = a1.pidm
                            and a1.campus||a1.nivel not in ( 'UTSID', 'UTSEC','INIEC')
                            )
            And  (a.campus, a.nivel) IN (select distinct b.campus, b.nivel
                                from TZTINC b 
                                )          
            And A.PIDM NOT IN (SELECT distinct GORADID_PIDM
                                       FROM GORADID
                                      WHERE     GORADID_PIDM = A.pidm 
                                            AND GORADID_ADID_CODE IN ('IZZI','BCSP','ESPA'))  
             And a.PIDM not in (select goradid_pidm
                                                from GORADID
                                                Where 1=1
                                                And GORADID_ADID_CODE ='SBTI' ----> Se excluyen a los alumnos que cuenten con la etiqueta de Retencion 
                                                )                                                        
            And a.matricula = nvl (p_matricula, a.matricula) 
--            And a.matricula in ('010026466',
--'010197558',
--'010314742',
--'010390509',
--'010497577',
--'010510742',
--'010511516',
--'010516956',
--'010525335',
--'240370081',
--'290363424',
--'010678059',
--'010678090',
--'010678133',
--'010678167',
--'010678291',
--'010678477',
--'010603633',
--'010603956',
--'010604765',
--'010604859',
--'010604935'
--                                )                                                                                           

        ) loop
        
            Begin 
                    insert into migra.complementos values (cx.CAMPUS , 
                                                     cx.NIVEL, 
                                                     cx.MATRICULA,
                                                     cx.programa,
                                                     cx.estatus,
                                                     cx.fecha_inicio,
                                                     null,
                                                     null,
                                                     null,
                                                     null,
                                                     null,
                                                     null,
                                                     null, 
                                                     cx.fecha_solicitud,
                                                     cx.sp,
                                                     cx.COSTO_CERO,
                                                     null ,--cx.PRIMERA_INSCRIPCION,
                                                     cx.MATERIA_INSCRITAS,
                                                     null,
                                                     null,
                                                     cx.pidm,
                                                     NULL,
                                                     NULL,
                                                     null,
                                                     cx.tipo_alumno,
                                                     cx.Tipo_Ingreso,
                                                     null,
                                                     NULL,
                                                     NULL
                                                     ); 
            Exception
                When OThers then 
                    null;
            End;    
            Commit;
    
        End Loop;        
        ------------------------------ Registra primera Inscripcion Cargada ------------------------    
        
        Begin 
              
              For cx in (
                    
                          Select distinct *
                          from migra.complementos
        
              )  loop
                        
                        
                        For cx2 in (
                        
                                    Select distinct min (SSBSECT_PTRM_START_DATE) PRIMERA_INSCRIPCION
                                    from sfrstcr
                                    join ssbsect on  SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                                    Where 1= 1
                                    And SFRSTCR_PIDM = cx.pidm
                                    and SFRSTCR_STSP_KEY_SEQUENCE = cx.sp
                                   -- And trunc (SSBSECT_PTRM_START_DATE) >= cx.FECHA_SOLICITUD
                                    And SFRSTCR_RSTS_CODE = 'RE'
                                    And SFRSTCR_DATA_ORIGIN not in ('CONVALIDACION')
                                    And substr (SFRSTCR_TERM_CODE, 5,1) not in ('8', '9')

                        
                                   ) loop
                                   
                                   Begin
                                        Update migra.complementos
                                        set PRIMERA_INSCRIPCION = cx2.PRIMERA_INSCRIPCION
                                       Where 1=1
                                       And campus = cx.campus
                                       And nivel = cx.nivel
                                       And matricula = cx.matricula
                                       And sp = cx.sp;
                                   Exception
                                    When Others then 
                                        null;
                                   End;
                                   
                                   
                        End Loop cx2;
              
               Commit;    
                        
              End Loop cx;          

              Commit;        
        End;        
        
        
        
        ------------------------------ Registra el numero de materias inscritas en el periodo ------------------------    
        
        Begin 
              
              For cx in (
                    
                          Select distinct *
                          from migra.complementos
        
              )  loop
                        
                        
                        For cx2 in (
                        
                                    Select count(*) materias
                                    from sfrstcr
                                    join ssbsect on  SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                                    Where 1= 1
                                    And SFRSTCR_PIDM = cx.pidm
                                    and SFRSTCR_STSP_KEY_SEQUENCE = cx.sp
                                    And trunc (SSBSECT_PTRM_START_DATE) > cx.FECHA_SOLICITUD
                                    And trunc (SSBSECT_PTRM_START_DATE) =  cx.FECHA_inicio
                                    And SFRSTCR_RSTS_CODE = 'RE'
                                    And substr (SFRSTCR_TERM_CODE, 5,1) not in ('8', '9')

                        
                                   ) loop
                                   
                                   Begin
                                        Update migra.complementos
                                        set NUMERO_MATERIAS = cx2.materias
                                       Where 1=1
                                       And campus = cx.campus
                                       And nivel = cx.nivel
                                       And matricula = cx.matricula
                                       And sp = cx.sp;
                                   Exception
                                    When Others then 
                                        null;
                                   End;
                                   
                                   
                        End Loop cx2;
              
               Commit;    
                        
              End Loop cx;          

              Commit;        
        End;        
        
           
        
        
        ------------------------------ Registra el monto del ultimo complemento cargado ------------------------    
        
        Begin 
              
              For cx in (
                    
                          Select distinct *
                          from migra.complementos
        
              )  loop
                        
                        
                        For cx2 in (
                        
                                    Select distinct a.tbraccd_amount monto, 
                                            a.TBRACCD_DETAIL_CODE codigo, 
                                            trunc (a.TBRACCD_EFFECTIVE_DATE) vencimiento, 
                                            cx.campus campus, 
                                            cx.nivel  nivel, 
                                            a.TBRACCD_TRAN_NUMBER Seq, 
                                            a.tbraccd_balance Saldo
                                    from tbraccd a 
--                                    join TZTINC b on b.campus = cx.campus and b.nivel = cx.nivel   ----> b.CODIGO = a.TBRACCD_DETAIL_CODE Se quita esta condicion para encontrar todos los complementos
--                                                 And b.AUMENTO = 0 and b.NOTAS_MIN = 1
                                    Where 1 =1
                                    And a.tbraccd_pidm = cx.pidm
                                     And a.TBRACCD_STSP_KEY_SEQUENCE = cx.sp
                                    And trunc (a.TBRACCD_EFFECTIVE_DATE)>= cx.PRIMERA_INSCRIPCION
                                    And trunc (a.TBRACCD_EFFECTIVE_DATE) = (select max (trunc (a1.TBRACCD_EFFECTIVE_DATE))
                                                                    from tbraccd a1
                                                                    Where a.tbraccd_pidm = a1.tbraccd_pidm
                                                                    And a.TBRACCD_DETAIL_CODE = a1.TBRACCD_DETAIL_CODE
                                                                    And trunc (a1.TBRACCD_EFFECTIVE_DATE)>= cx.PRIMERA_INSCRIPCION
                                                                   ) 
                                    And a.tbraccd_detail_code in (select b.CODIGO 
                                                                    from TZTINC b
                                                                    where 1=1
                                                                    And b.campus = cx.campus 
                                                                    and b.nivel = cx.nivel 
                                                                    And b.AUMENTO = 0 
                                                                    and b.NOTAS_MIN = 1
                                                                   )   
                                                                            

                        
                                   ) loop
                                   
                                   Begin
                                        Update migra.complementos
                                        set MONTO = cx2.monto, 
                                            SALDO = cx2.saldo,
                                            CODIGO = cx2.codigo,
                                            VENCIMIENTO = cx2.vencimiento,
                                            SECUENCIA_ULTIMA = cx2.seq
                                       Where 1=1
                                       And campus = cx2.campus
                                       And nivel = cx2.nivel
                                       And matricula = cx.matricula
                                       And sp = cx.sp;
                                   Exception
                                    When Others then 
                                        null;
                                   End;
                                   
                                   
                        End Loop cx2;
              
               Commit;    
                        
              End Loop cx;          

              Commit;        
        End;
      
    
    
        ------------------------------ Registra el anterior complemento cargado ------------------------    
        
        Begin 
              
              For cx in (
                    
                          Select distinct *
                          from migra.complementos
        
              )  loop
                        
                        
                        For cx2 in (
                        
                                    Select distinct a.tbraccd_amount monto, 
                                                    a.TBRACCD_DETAIL_CODE codigo, 
                                                    trunc (a.TBRACCD_EFFECTIVE_DATE) vencimiento, 
                                                    cx.campus campus, 
                                                    cx.nivel  nivel, 
                                                    a.TBRACCD_TRAN_NUMBER Seq, 
                                                    a.tbraccd_balance Saldo
                                    from tbraccd a 
--                                    join TZTINC b on  b.campus = cx.campus and b.nivel = cx.nivel  ---b.CODIGO = a.TBRACCD_DETAIL_CODE and SE quita es parte para encontra todos los codigos de complemnento
--                                                 And b.AUMENTO = 0 and b.NOTAS_MIN = 1
                                    Where 1 =1
                                    And a.tbraccd_pidm = cx.pidm
                                     And a.TBRACCD_STSP_KEY_SEQUENCE = cx.sp
                                    And trunc (a.TBRACCD_EFFECTIVE_DATE)>= cx.PRIMERA_INSCRIPCION
                                    And trunc (a.TBRACCD_EFFECTIVE_DATE) <= nvl (cx.vencimiento, trunc (a.TBRACCD_EFFECTIVE_DATE))
                                    And trunc (a.TBRACCD_EFFECTIVE_DATE) in (select max (trunc (a1.TBRACCD_EFFECTIVE_DATE))
                                                                            from tbraccd a1
                                                                            Where a.tbraccd_pidm = a1.tbraccd_pidm
                                                                            And a.TBRACCD_DETAIL_CODE = a1.TBRACCD_DETAIL_CODE
                                                                            And trunc (a1.TBRACCD_EFFECTIVE_DATE)>= cx.PRIMERA_INSCRIPCION
                                                                            And trunc (a1.TBRACCD_EFFECTIVE_DATE) <= nvl (cx.vencimiento, trunc (a1.TBRACCD_EFFECTIVE_DATE))
                                                                   )                        
                                    And a.tbraccd_detail_code in (select b.CODIGO 
                                                                    from TZTINC b
                                                                    where 1=1
                                                                    And b.campus = cx.campus 
                                                                    and b.nivel = cx.nivel 
                                                                    And b.AUMENTO = 0 
                                                                    and b.NOTAS_MIN = 1
                                                                   )  



                        
                                   ) loop
                                   
                                   Begin
                                        Update migra.complementos
                                        set MONTO_ANTERIOR = cx2.monto, 
                                            CODIGO_ANTERIOR = cx2.codigo,
                                            VENCIMIENTO_ANTERIOR = cx2.vencimiento,
                                            SECUENCIA_ANTERIOR = cx2.seq
                                       Where 1=1
                                       And campus = cx2.campus
                                       And nivel = cx2.nivel
                                       And matricula = cx.matricula
                                       And sp = cx.sp;
                                   Exception
                                    When Others then 
                                        null;
                                   End;
                                   
                                   
                        End Loop cx2;
              
               Commit;    
                        
              End Loop cx;          

              Commit;        
        End;

    
        ------------------------------ Registra la nota de credito del complemento cargado ------------------------    
        
        Begin 
              
              For cx in (
                    
                          Select distinct *
                          from migra.complementos
        
              )  loop
                        
                        
                        For cx2 in (
                        
                                    Select sum (TBRAPPL_AMOUNT) monto,  tbraccd_desc Nombre_Nota
                                    from tbrappl, tbraccd, TZTNCD
                                    Where 1= 1 
                                    And TBRACCD_PIDM = tbrappl_pidm
                                    And tbrappl_pidm = cx.pidm
                                    and TBRAPPL_CHG_TRAN_NUMBER = cx.SECUENCIA_ULTIMA
                                    And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                                    And tbraccd_detail_code =  TZTNCD_CODE
                                    And TZTNCD_CONCEPTO IN ('Nota Credito')
                                    And TBRAPPL_REAPPL_IND is null
                                    group by tbraccd_desc                       

                        
                                   ) loop
                                   
                                   Begin
                                        Update migra.complementos
                                        set NOMBRE_NOTA = cx2.NOMBRE_NOTA, 
                                            MONTO_NTCR = cx2.MONTO
                                       Where 1=1
                                       And campus = cx.campus
                                       And nivel = cx.nivel
                                       And matricula = cx.matricula
                                       And sp = cx.sp;
                                   Exception
                                    When Others then 
                                        null;
                                   End;
                                   
                                   
                        End Loop cx2;
              
               Commit;    
                        
              End Loop cx;          

              Commit;        
        End;
    
       ------------------------------ Registra el total de cargados generados  ------------------------    
        
        Begin 
              
              For cx in (
                    
                          Select distinct *
                          from migra.complementos
        
              )  loop
                        
                        
                        For cx2 in (
                        
                                    Select COUNT(*) Cuantos
                                    from tbraccd a 
--                                    join TZTINC b on  b.campus = cx.campus and b.nivel = cx.nivel   --- b.CODIGO = a.TBRACCD_DETAIL_CODE and Se quita esta parte para encontrar todos los complementos cArgados
--                                           And b.AUMENTO = 0 and b.NOTAS_MIN = 1
                                    join tztordr c on c.TZTORDR_PIDM = a.tbraccd_pidm and c.TZTORDR_CAMPUS = cx.campus and c.TZTORDR_NIVEL = cx.nivel and c.TZTORDR_CONTADOR = a.TBRACCD_RECEIPT_NUMBER
                                    Where 1 =1
                                    And a.tbraccd_pidm = cx.pidm
                                    And trunc (a.TBRACCD_EFFECTIVE_DATE)>= cx.PRIMERA_INSCRIPCION
                                    And a.tbraccd_detail_code in (select b.CODIGO 
                                                                    from TZTINC b
                                                                    where 1=1
                                                                    And b.campus = cx.campus 
                                                                    and b.nivel = cx.nivel 
                                                                    And b.AUMENTO = 0 
                                                                    and b.NOTAS_MIN = 1
                                                                   )                                      

                        
                                   ) loop
                                   
                                   Begin
                                        Update migra.complementos
                                        set COMPLEMENTO_CARGADOS = cx2.Cuantos
                                       Where 1=1
                                       And campus = cx.campus
                                       And nivel = cx.nivel
                                       And matricula = cx.matricula
                                       And sp = cx.sp;
                                   Exception
                                    When Others then 
                                        null;
                                   End;
                                   
                                   
                        End Loop cx2;
              
               Commit;    
                        
              End Loop cx;          

              Commit;        
        End;
      
    
-------------------------------------- Consulta complemento 
      
--select distinct campus, nivel, matricula, programa, estatus, fecha_inicio, monto, saldo, codigo, vencimiento, 
--       monto_anterior, codigo_anterior, vencimiento_anterior, fecha_solicitud, sp, costo_cero, primera_inscripcion,
--       nombre_nota, monto_ntcr, COMPLEMENTO_CARGADOS, STVSTYP_DESC Tipo_alumno, TIPO_INGRESO , COMPLEMENTOS_INCREMENTO
--from complementos
--left join stvSTYP on STVSTYP_CODE = TIPO_ALUMNO
--where 1= 1
--order by 1,2,3

    
        
End consulta_complemento;


-------------------------------------------------------------------------


PROCEDURE EJECUTA_COMPLEMENTO(p_matricula in varchar2 default null) IS
 
vl_aumento number:=0;
vl_monto_total number:=0;
vl_fecha_nueva date;
vl_periodo varchar2(6):= null;
vl_pperiodo varchar2(6):= null;

vl_fecha_solicitud date;
vl_codigo varchar2(10):= null;
vl_costo  number:=0;
vl_vigencia number:=0;
vl_fecha_nueva_vac date;
vl_fecha_ancla date;
vl_incremento number:=0;
vl_cantidad number:=0;
vl_cargados number:=0;

Begin 


        PKG_FINANZAS_COMPLEMENTO.consulta_complemento(p_matricula);
        Commit;
        
        
        For cx in (

                    Select  distinct a.*, b.VIGENCIA, 
                       -- ADD_MONTHS(a.vencimiento, b.VIGENCIA) nueva_fecha, 
                        trunc (MONTHS_BETWEEN (sysdate, ADD_MONTHS(a.vencimiento, b.VIGENCIA))) rango,  
                        Case 
                            When decode (substr (pkg_utilerias.f_calcula_rate(a.pidm,a.programa),4,1),'A','15', 'B','30','C','10') not in ('B') then 
                               ADD_MONTHS(ADD_MONTHS(a.vencimiento, b.VIGENCIA),trunc (MONTHS_BETWEEN (sysdate, ADD_MONTHS(a.vencimiento, b.VIGENCIA)))) 
                            When decode (substr (pkg_utilerias.f_calcula_rate(a.pidm,a.programa),4,1),'A','15', 'B','30','C','10')  in ('B') then  
                                ADD_MONTHS(ADD_MONTHS(a.vencimiento, b.VIGENCIA),ceil (MONTHS_BETWEEN (sysdate, ADD_MONTHS(a.vencimiento, b.VIGENCIA))))  
                            End nueva_fecha ,
                     decode (substr (pkg_utilerias.f_calcula_rate(a.pidm,a.programa),4,1),'A','15', 'B','30','C','10') Rate
                    from migra.complementos a
                    left join TZTINC b on b.campus = a.campus and b.nivel = a.nivel and b.CODIGO = a.CODIGO and b.AUMENTO = 0
                    where a.COSTO_CERO in ('Sin_costo0')
                    and a.matricula = nvl (p_matricula, a.MATRICULA) 
                    union
                    Select  distinct a.*, b.VIGENCIA, 
                      --  ADD_MONTHS(a.vencimiento, b.VIGENCIA) nueva_fecha, 
                        trunc (MONTHS_BETWEEN (sysdate, ADD_MONTHS(a.vencimiento, b.VIGENCIA))) rango,    
                        Case 
                            When decode (substr (pkg_utilerias.f_calcula_rate(a.pidm,a.programa),4,1),'A','15', 'B','30','C','10') not in ('B') then 
                               ADD_MONTHS(ADD_MONTHS(a.vencimiento, b.VIGENCIA),trunc (MONTHS_BETWEEN (sysdate, ADD_MONTHS(a.vencimiento, b.VIGENCIA)))) 
                            When decode (substr (pkg_utilerias.f_calcula_rate(a.pidm,a.programa),4,1),'A','15', 'B','30','C','10')  in ('B') then  
                                ADD_MONTHS(ADD_MONTHS(a.vencimiento, b.VIGENCIA),ceil (MONTHS_BETWEEN (sysdate, ADD_MONTHS(a.vencimiento, b.VIGENCIA))))  
                            End nueva_fecha ,
                     decode (substr (pkg_utilerias.f_calcula_rate(a.pidm,a.programa),4,1),'A','15', 'B','30','C','10') Rate
                    from migra.complementos a
                    left join TZTINC b on b.campus = a.campus and b.nivel = a.nivel and b.CODIGO = a.CODIGO and b.AUMENTO = 0
                    where a.COSTO_CERO is null
                    and a.matricula = nvl (p_matricula, a.MATRICULA)    
                    order by 1,2                      
                    
        ) loop
        
            If cx.numero_materias > 0 then  --> Entra al proceso para generacion de complementos 
            
                --DBMS_OUTPUT.PUT_LINE(' Materias Inscritas '|| cx.numero_materias); 
        
              If cx.codigo is not null then  -----------> genera los cargos para cuando ya hay cargos de complemento en el estado de Cuenta
                    --DBMS_OUTPUT.PUT_LINE(' Entra con Monto ');
                    vl_aumento:=0;
                    vl_cargados:=0;
                    
                    --------------------- Calculo el numero de complementos con el mismo costo para calcular los incrementos ------------------
                    Begin
                        select count(*)
                            Into vl_cargados
                        from tbraccd
                        where tbraccd_pidm = cx.pidm 
                        and tbraccd_detail_code = cx.codigo_anterior
                        And tbraccd_amount = cx.monto_anterior        
                        And TBRACCD_STSP_KEY_SEQUENCE = cx.sp;                    
                    Exception
                        When Others then 
                            vl_cargados:=0;
                    End;  
                    
                    vl_cargados:= vl_cargados +1;
                
                    Begin
                        select distinct AUMENTO
                         Into vl_aumento 
                        from TZTINC
                        where 1=1
                        and campus =cx.campus
                        And nivel = cx.nivel
                        And codigo = cx.codigo
                        and vl_cargados between NOTAS_MIN and NOTAS_MAX;           
                    Exception
                        When Others then 
                        vl_aumento:=0;
                    End;
                    
                    vl_incremento:=0;
                    Begin
                        select distinct NOTAS_INCREMENTO
                         Into vl_incremento 
                        from TZTINC
                        where 1=1
                        and campus =cx.campus
                        And nivel = cx.nivel
                        And codigo = cx.codigo
                        and vl_cargados between NOTAS_MIN and NOTAS_MAX;           
                    Exception
                        When Others then 
                        vl_incremento:=0;
                    End;

                    vl_cantidad:= 0;
                    Begin
                    
                        Select vl_cargados / vl_incremento 
                            Into vl_cantidad
                        from dual;
                    Exception
                        When Others then 
                            vl_cantidad:=0;
                    End;

                    vl_monto_total:= null;
                    If vl_cantidad in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,22,23,24,25,26,27,28,29,30) then 
                        vl_monto_total:= cx.monto_anterior+vl_aumento;
                    Elsif vl_cantidad not in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,22,23,24,25,26,27,28,29,30) then 
                        vl_monto_total:= cx.monto;
                    End if;
                    
                    vl_fecha_nueva:= null;
                     --DBMS_OUTPUT.PUT_LINE(' Montos '|| cx.monto_anterior ||'*'||vl_aumento||'*'||vl_monto_total||'Rango'||vl_cantidad ||' Matricula '||cx.matricula||'Cargados '||vl_cargados||'Incremento '||vl_incremento);
                     
                    If cx.rango >= 0 then 
                        Begin 
                            select TRUNC(cx.nueva_fecha, 'MM') 
                             Into vl_fecha_nueva
                            from dual;
                        Exception
                            When Others then 
                                vl_fecha_nueva:= null;
                        End;              
                      
                    End if;
                    
                    vl_fecha_nueva := vl_fecha_nueva + cx.rate-1;
                    --DBMS_OUTPUT.PUT_LINE(' Fechas salida '|| vl_fecha_nueva );
                    
                    If trunc (sysdate, 'MM')  =  trunc (vl_fecha_nueva, 'MM') then 
                       vl_fecha_nueva := trunc (sysdate, 'MM') + cx.rate-1;
                     
                    
                        vl_periodo := null;
                        vl_pperiodo := null;
                        
                        --DBMS_OUTPUT.PUT_LINE(' Entra al Proceso' );
                        
                        Begin
                        
                             Select distinct SFRSTCR_TERM_CODE periodo,  SFRSTCR_PTRM_CODE pperiodo
                                Into vl_periodo, vl_pperiodo
                              from sfrstcr
                             join ssbsect on  SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                             Where 1= 1
                             And SFRSTCR_PIDM =   cx.pidm 
                             And SFRSTCR_STSP_KEY_SEQUENCE = cx.sp
                             And SFRSTCR_RSTS_CODE = 'RE'
                             And substr (SFRSTCR_TERM_CODE, 5,1) not in ('8', '9')                    
                             And trunc (SSBSECT_PTRM_START_DATE)  = cx.fecha_inicio;
                        Exception
                            When Others then 
                             vl_periodo:= null;
                             vl_pperiodo:= null;
                        End;
                        
                            --DBMS_OUTPUT.PUT_LINE(' Obtiene Periodo '||vl_periodo  );
                        If cx.codigo is not null and vl_monto_total > 0 And vl_periodo is not null  then 
                        
                           --DBMS_OUTPUT.PUT_LINE(' Entra a Insertar con Cargo Anterior'|| cx.codigo ||' * '||vl_monto_total ||'*'||vl_periodo||'*'||vl_pperiodo||'*'||vl_fecha_nueva);
--
                            PKG_FINANZAS_COMPLEMENTO.GENERA_COMPLEMENTO ( cx.campus, 
                                                                           cx.nivel, 
                                                                           cx.pidm, 
                                                                           vl_periodo, 
                                                                           cx.programa, 
                                                                           cx.sp, 
                                                                           cx.rate, 
                                                                           vl_fecha_nueva, 
                                                                           cx.fecha_inicio, 
                                                                           cx.matricula, 
                                                                           vl_pperiodo,
                                                                           vl_monto_total,
                                                                           cx.codigo,
                                                                           vl_cargados );
                                                   Commit;
                              Begin
                                    Update complementos
                                    set COMPLEMENTOS_INCREMENTO = vl_cargados,
                                        COMPLEMENTO_CARGADOS = cx.COMPLEMENTO_CARGADOS +1
                                     Where campus = cx.campus
                                     And Nivel = cx.nivel 
                                     And matricula = cx.matricula
                                     And sp = cx.sp
                                     And fecha_inicio = cx.fecha_inicio;
                              Exception
                                When Others then
                                 null;
                              End;                     
                                                  
                        Else
                            --DBMS_OUTPUT.PUT_LINE('algun dato esta vacio con cargo ');
                             Begin
                                Update complementos
                                set observaciones ='No se recuperaron todos los valores '|| cx.codigo ||' * '||vl_monto_total ||'*'||vl_periodo||'*'||vl_pperiodo
                                Where CAMPUS = cx.campus
                                And NIVEL = cx.nivel
                                And MATRICULA = cx.matricula
                                And PROGRAMA = cx.programa;
                             Exception
                                When Others then
                                 null;
                             End;
                             
                        End if;                        
                    
                    Else
                         --DBMS_OUTPUT.PUT_LINE('No Cumple con la Fecha de Generacion Con cargo '|| vl_fecha_nueva );
                             Begin
                                Update complementos
                                set observaciones ='No Cumple con la Fecha de Generacion Con cargo '|| vl_fecha_nueva 
                                Where CAMPUS = cx.campus
                                And NIVEL = cx.nivel
                                And MATRICULA = cx.matricula
                                And PROGRAMA = cx.programa;
                             Exception
                                When Others then
                                 null;
                             End;
                    End if;    
                        
              Elsif cx.codigo is null then  
                      --DBMS_OUTPUT.PUT_LINE(' Proceso Sin Cargos Generados' );
                       
                        vl_fecha_solicitud:= null;
                        vl_codigo := null;
                        vl_costo  :=null;
                        Begin                 

                                Select max (x.fecha)
                                    into vl_fecha_solicitud
                                from (
                                     Select max(FECHA_SOLICITUD) Fecha, CODIGO, costo, vigencia
                                     from TZTINC  
                                     Where campus = cx.campus
                                     And nivel = cx.nivel
                                     And cx.fecha_solicitud >= trunc (fecha_solicitud)
                                     And AUMENTO = 0
                                     And NOTAS_MIN = 1
                                     group by CODIGO, costo, vigencia 
                                    ) x;
                        Exception
                            When Others then 
                             vl_fecha_solicitud := null;
                        End;
                
                          --DBMS_OUTPUT.PUT_LINE('Fecha Solicitd costo '|| vl_fecha_solicitud );

                        Begin
                       
                            Select codigo, costo, VIGENCIA
                                Into vl_codigo, vl_costo, vl_vigencia
                            from TZTINC
                             Where campus = cx.campus
                             And nivel = cx.nivel
                             And trunc (fecha_solicitud) = vl_fecha_solicitud
                             And AUMENTO = 0
                             And NOTAS_MIN = 1;
         
                        Exception
                            When others then 
                                vl_codigo:= null; 
                                vl_costo:= null;
                                vl_vigencia := null;
                        End;                       

                        vl_fecha_nueva:= null;
                        vl_fecha_nueva_vac := null;
                        
                        If cx.PRIMERA_INSCRIPCION is not null then 
                            vl_fecha_ancla := cx.PRIMERA_INSCRIPCION+12; ------Se agrego para brincar el mes por dia 20 de mes
                        Else 
                            vl_fecha_ancla := cx.fecha_inicio+12;
                        End if;

                           --DBMS_OUTPUT.PUT_LINE(' Generacion fecha ancla ' ||vl_fecha_ancla );

                        Begin             
                            Select ADD_MONTHS(vl_fecha_ancla, vl_vigencia-1) 
                            Into vl_fecha_nueva_vac
                            from dual;
                        Exception
                            When others then 
                            vl_fecha_nueva_vac:= null;
                        End;

                            --DBMS_OUTPUT.PUT_LINE(' Generacion mas meses '|| vl_fecha_nueva_vac );

                        Begin 
                            select TRUNC(vl_fecha_nueva_vac, 'MM') 
                             Into vl_fecha_nueva
                            from dual;
                        Exception
                            When Others then 
                                vl_fecha_nueva:= null;
                        End;

                           --DBMS_OUTPUT.PUT_LINE(' fecha truncada  '|| vl_fecha_nueva );
                           
                         If vl_fecha_nueva < sysdate then 
                            vl_fecha_nueva:= trunc (sysdate);
                         End if; 

                        --DBMS_OUTPUT.PUT_LINE(' fecha truncada actualizada  '|| vl_fecha_nueva );

                        If trunc (sysdate, 'MM')  =  trunc (vl_fecha_nueva, 'MM') then 
                           vl_fecha_nueva := trunc (sysdate, 'MM') + cx.rate-1;
                             --DBMS_OUTPUT.PUT_LINE('Fecha de Generacion de Cargo '|| vl_fecha_nueva );
                        

                                Begin 
                                     Select distinct SFRSTCR_TERM_CODE periodo,  SFRSTCR_PTRM_CODE pperiodo
                                        Into vl_periodo, vl_pperiodo
                                      from sfrstcr
                                     join ssbsect on  SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                                     Where 1= 1
                                     And SFRSTCR_PIDM =   cx.pidm 
                                     And SFRSTCR_STSP_KEY_SEQUENCE = cx.sp
                                     And SFRSTCR_RSTS_CODE = 'RE'
                                     And substr (SFRSTCR_TERM_CODE, 5,1) not in ('8', '9')                    
                                     And trunc (SSBSECT_PTRM_START_DATE)  = cx.fecha_inicio;
                                Exception
                                    When Others then 
                                     vl_periodo:= null;
                                     vl_pperiodo:= null;
                                End;                       
                               
                                If vl_codigo is not null and vl_costo > 0 And vl_periodo is not null and vl_fecha_nueva is not null then 
                                
--                                    DBMS_OUTPUT.PUT_LINE(' Entra a Insertar como primera vez '|| vl_codigo||' * '||
--                                                                                                        vl_costo ||'*'||
--                                                                                                        vl_periodo||'*'||
--                                                                                                        vl_fecha_nueva);

                                     PKG_FINANZAS_COMPLEMENTO.GENERA_COMPLEMENTO ( cx.campus, 
                                                                                   cx.nivel, 
                                                                                   cx.pidm, 
                                                                                   vl_periodo, 
                                                                                   cx.programa, 
                                                                                   cx.sp, 
                                                                                   cx.rate, 
                                                                                   vl_fecha_nueva, 
                                                                                   cx.fecha_inicio, 
                                                                                   cx.matricula, 
                                                                                   vl_pperiodo,
                                                                                   vl_costo,
                                                                                   vl_codigo,
                                                                                   1 );
                                                                                   Commit;
                                                       
                                Else
                                        --DBMS_OUTPUT.PUT_LINE('algun dato esta vacio sin cargo');
                                         Begin
                                            Update complementos
                                            set observaciones ='algun dato esta vacio sin cargo '||vl_codigo||' * '||vl_costo||'*'||vl_periodo||'*'||vl_fecha_nueva
                                            Where CAMPUS = cx.campus
                                            And NIVEL = cx.nivel
                                            And MATRICULA = cx.matricula
                                            And PROGRAMA = cx.programa;
                                         Exception
                                            When Others then
                                             null;
                                        End;

                                End if;
                        Else
                                --DBMS_OUTPUT.PUT_LINE('No Cumple con la Fecha de Generacion sin cargo '|| vl_fecha_nueva );
                           
                             Begin
                                Update complementos
                                set observaciones ='No Cumple con la Fecha de Generacion sin cargo '||vl_fecha_nueva
                                Where CAMPUS = cx.campus
                                And NIVEL = cx.nivel
                                And MATRICULA = cx.matricula
                                And PROGRAMA = cx.programa;
                             Exception
                                When Others then
                                 null;
                            End;
                        
                                
                        End if;

              End if;
  
            Else
                        --DBMS_OUTPUT.PUT_LINE(' No Materias Inscritas ');
                 Begin
                    Update complementos
                    set observaciones ='No Materias Inscritas para generar incorporacion en la fecha de inicio '||cx.fecha_inicio
                    Where CAMPUS = cx.campus
                    And NIVEL = cx.nivel
                    And MATRICULA = cx.matricula
                    And PROGRAMA = cx.programa;
                 Exception
                    When Others then
                     null;
                End;

            End if;    
        
        End loop;
        Commit;
        
        
End EJECUTA_COMPLEMENTO;        



END PKG_FINANZAS_COMPLEMENTO;
/

DROP PUBLIC SYNONYM PKG_FINANZAS_COMPLEMENTO;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FINANZAS_COMPLEMENTO FOR BANINST1.PKG_FINANZAS_COMPLEMENTO;
