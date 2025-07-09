DROP PACKAGE BODY BANINST1.PKG_PROMOCIONES;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_PROMOCIONES AS
/******************************************************************************
   NAME:       PKG_PROMOCIONES
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        22/02/2022      vramirlo       1. Created this package body.
******************************************************************************/

 FUNCTION F_promocion_documentos_core(p_pidm IN NUMBER) RETURN varchar2 Is
    vl_exito varchar2(500):= 'EXITO';
    vl_monto number :=0;
    vl_existe_promo number :=0;
    vl_pidm  number :=0;
    vl_codigo varchar2(500);
    vl_descripcion varchar2(500);
    vl_fecha_inicio date;
    vl_sp  number :=0;
    vl_pperiodo  varchar2(5);
    vl_secuencia  number :=0;
    vl_periodo varchar2(6);
    vl_trans_paid number;
    vl_pperido varchar2(6);

   
  BEGIN
  
        Begin 
        
                For cx in (
        
                                select distinct  a.pidm,
                                         a.matricula,
                                         a.campus,
                                         a.nivel,
                                         a.fecha_primera Fecha_inicio,
                                         a.Fecha_inicio Fecha_inicio_correcta,
                                         a.sp sp,
                                       nvl (PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia_Titulo(a.pidm),0) Saldo,
                                         a.SGBSTDN_STYP_CODE Tipo_alumno,
                                         a.programa,
                                         a.TIPO_INGRESO,
                                        substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, ZSTPARA_PARAM_ID),1,10) Fecha_documento,
                                        substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, ZSTPARA_PARAM_ID),12,50) Estatus_documento,
                                         ZSTPARA_PARAM_ID,
                                         ZSTPARA_PARAM_VALOR,
                                        to_number (to_Date( substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, ZSTPARA_PARAM_ID),1,10))  - (a.fecha_primera)) dias,
                                        (select min (to_number (ZSTPARA_PARAM_ID)) 
                                            from ZSTPARA 
                                            where ZSTPARA_MAPA_ID = 'INCENT_DOC_HIGH'
                                           and to_Date( substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, b.ZSTPARA_PARAM_ID),1,10))  - to_date(a.fecha_primera) <=  ZSTPARA_PARAM_ID
                                        ) rango,
                                       (Select  x.ZSTPARA_PARAM_VALOR
                                          from ZSTPARA x
                                          where x.ZSTPARA_MAPA_ID = 'INCENT_DOC_HIGH'
                                         And to_number (x.ZSTPARA_PARAM_ID) in  (select min (to_number (x1.ZSTPARA_PARAM_ID)) 
                                                                                                             from ZSTPARA x1
                                                                                                         where x1.ZSTPARA_MAPA_ID = 'INCENT_DOC_HIGH'
                                                                                                       and to_Date( substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, b.ZSTPARA_PARAM_ID),1,10))  - to_date(a.fecha_primera) <=  x1.ZSTPARA_PARAM_ID
                                                                                                        )) Monto,
                                       substr (a.matricula, 1,2) || 'DG' codigo ,
                                       nvl (PKG_UTILERIAS.F_CALCULA_BIMESTRES ( a.pidm,a.sp ),0) Bimestre,
                                        nvl ((Select tbraccd_amount
                                            from tbraccd
                                            where tbraccd_pidm = a.pidm
                                            and substr (tbraccd_detail_code, 3,2) = 'DG'),0) Descuento,
                                         (Select tbbdetc_desc
                                                    from tbbdetc
                                                    where substr (TBBDETC_DETAIL_CODE,3,2) = 'DG'
                                                    And substr (TBBDETC_DETAIL_CODE,1,2) = substr( a.matricula, 1,2)
                                                    ) Descripcion,                                            
                                         nvl( (select tbraccd_amount
                                              from tbraccd
                                              where 1=1
                                              and tbraccd_pidm = a.pidm
                                              and substr (tbraccd_detail_code,3,2)  = 'M3'
                                              and trunc (TBRACCD_EFFECTIVE_DATE) between trunc((sysdate),'month')  and  TRUNC(LAST_DAY(SYSDATE))
                                          ),0) Escalonado,
                                 (select  distinct SFRSTCR_PTRM_CODE
                                     from sfrstcr
                                     join ssbsect on SSBSECT_TERM_CODE =SFRSTCR_TERM_CODE  
                                                        and SSBSECT_CRN = SFRSTCR_CRN 
                                                        and trunc (SSBSECT_PTRM_START_DATE) = a.Fecha_inicio 
                                                        and SFRSTCR_STSP_KEY_SEQUENCE = a.sp
                                     where 1= 1
                                     and SFRSTCR_PIDM = a.pidm )Pperiodo                                              
                                from tztprog a 
                                join ZSTPARA b on b.ZSTPARA_MAPA_ID = 'DESC_ENTREGADOC' 
                                                    and a.campus =  substr (b.ZSTPARA_PARAM_VALOR,1,3) 
                                                    and  a.nivel = substr (b.ZSTPARA_PARAM_VALOR,5,2) and a.tipo_ingreso = trim (b.ZSTPARA_PARAM_DESC)
                                where 1= 1
                                And a.estatus  in ('MA')
                                and a.FECHA_PRIMERA >= '28/02/2022'
                                And a.sp = (select max (a1.sp)
                                                from tztprog a1
                                                Where a.pidm = a1.pidm
                                                )
                                And a.campus in (select ZSTPARA_PARAM_ID
                                                            from ZSTPARA       
                                                            where ZSTPARA_MAPA_ID = 'TIPO_REGLA'
                                                            And   ZSTPARA_PARAM_VALOR ='1')    ---> Esta valor de regla determina si el modelo de beneficios es para Core o Expansion (1 Core, 2 Expansion)
                               And a.pidm = p_pidm
                                 union ----------------------------------------------------------                                  
                                select distinct  a.pidm,
                                         a.matricula,
                                         a.campus,
                                         a.nivel,
                                         a.fecha_inicio Fecha_inicio,
                                         a.Fecha_inicio Fecha_inicio_correcta,
                                         a.sp sp,
                                       nvl (PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia_Titulo(a.pidm),0) Saldo,
                                         a.SGBSTDN_STYP_CODE Tipo_alumno,
                                         a.programa,
                                         a.TIPO_INGRESO,
                                        substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, ZSTPARA_PARAM_ID),1,10) Fecha_documento,
                                        substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, ZSTPARA_PARAM_ID),12,50) Estatus_documento,
                                         ZSTPARA_PARAM_ID,
                                         ZSTPARA_PARAM_VALOR,
                                        to_number (to_Date( substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, ZSTPARA_PARAM_ID),1,10))  - (a.fecha_inicio)) dias,
                                        (select min (to_number (ZSTPARA_PARAM_ID)) 
                                            from ZSTPARA 
                                            where ZSTPARA_MAPA_ID = 'INCENT_DOC_HIGH'
                                           and to_Date( substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, b.ZSTPARA_PARAM_ID),1,10))  - to_date(a.fecha_inicio) <=  ZSTPARA_PARAM_ID
                                        ) rango,
                                       (Select  x.ZSTPARA_PARAM_VALOR
                                          from ZSTPARA x
                                          where x.ZSTPARA_MAPA_ID = 'INCENT_DOC_HIGH'
                                         And to_number (x.ZSTPARA_PARAM_ID) in  (select min (to_number (x1.ZSTPARA_PARAM_ID)) 
                                                                                                             from ZSTPARA x1
                                                                                                         where x1.ZSTPARA_MAPA_ID = 'INCENT_DOC_HIGH'
                                                                                                       and to_Date( substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, b.ZSTPARA_PARAM_ID),1,10))  - to_date(a.fecha_inicio) <=  x1.ZSTPARA_PARAM_ID
                                                                                                        )) Monto,
                                          substr (a.matricula, 1,2) || 'DG' codigo,
                                          nvl (PKG_UTILERIAS.F_CALCULA_BIMESTRES ( a.pidm,a.sp ),0) Bimestre,
                                        nvl ((Select tbraccd_amount
                                            from tbraccd
                                            where tbraccd_pidm = a.pidm
                                            and substr (tbraccd_detail_code, 3,2) = 'DG'),0) Descuento,
                                         (Select tbbdetc_desc
                                                    from tbbdetc
                                                    where substr (TBBDETC_DETAIL_CODE,3,2) = 'DG'
                                                    And substr (TBBDETC_DETAIL_CODE,1,2) = substr( a.matricula, 1,2)
                                                    ) Descripcion,                                            
                                         nvl( (select tbraccd_amount
                                              from tbraccd
                                              where 1=1
                                              and tbraccd_pidm = a.pidm
                                              and substr (tbraccd_detail_code,3,2)  = 'M3'
                                              and trunc (TBRACCD_EFFECTIVE_DATE) between trunc((sysdate),'month')  and  TRUNC(LAST_DAY(SYSDATE))
                                          ),0) Escalonado,
                                 (select  distinct SFRSTCR_PTRM_CODE
                                     from sfrstcr
                                     join ssbsect on SSBSECT_TERM_CODE =SFRSTCR_TERM_CODE  
                                                        and SSBSECT_CRN = SFRSTCR_CRN 
                                                        and trunc (SSBSECT_PTRM_START_DATE) = a.Fecha_inicio 
                                                        and SFRSTCR_STSP_KEY_SEQUENCE = a.sp
                                     where 1= 1
                                     and SFRSTCR_PIDM = a.pidm )Pperiodo                                                                                                                          
                                from tztprog a 
                                join ZSTPARA b on b.ZSTPARA_MAPA_ID = 'DESC_ENTREGADOC' 
                                                    and a.campus =  substr (b.ZSTPARA_PARAM_VALOR,1,3) 
                                                    and  a.nivel = substr (b.ZSTPARA_PARAM_VALOR,5,2) and a.tipo_ingreso = trim (b.ZSTPARA_PARAM_DESC)
                                where 1= 1
                                And a.estatus  in ('MA')
                                AND a.FECHA_INICIO >= '28/02/2022'
                                and a.FECHA_PRIMERA is null
                                And a.sp = (select max (a1.sp)
                                                from tztprog a1
                                                Where a.pidm = a1.pidm
                                                )
                                And a.campus in (select ZSTPARA_PARAM_ID
                                                            from ZSTPARA       
                                                            where ZSTPARA_MAPA_ID = 'TIPO_REGLA'
                                                            And   ZSTPARA_PARAM_VALOR ='1')    ---> Esta valor de regla determina si el modelo de beneficios es para Core o Expansion (1 Core, 2 Expansion)
                               And a.pidm = p_pidm
                              order by rango asc     
                              
                              
                                              
            ) loop
                         
                    
                            vl_monto :=0;
                            vl_existe_promo :=0;
                            
                            If cx.descuento = 0 then 
                            
                                    If cx.saldo <= 500 then ------ Valida que el saldo de colegiatura sea menor a 500 

                                            If cx.escalonado = 0 then 
                                            
                                                    If cx.bimestre >= 4 then 
                                                         vl_monto:= cx.monto;
                                                         vl_pidm := cx.pidm;
                                                         vl_codigo := cx.codigo;
                                                         vl_descripcion := cx.descripcion;
                                                         vl_fecha_inicio := cx.Fecha_inicio_correcta;
                                                         vl_sp := cx.sp;
                                                         vl_pperiodo := cx.pperiodo;
      
                                                          --  dbms_output.put_line('vueltas:'||vl_monto);
                                                    Else 
                                                        vl_monto:= null;     
                                                        --dbms_output.put_line('Bimestre:');                                                     
                                                    End if;
                                            Else 
                                             vl_monto:= null;   
                                          --   dbms_output.put_line('Escalonado:');                                     
                                            End if;                 
                                    Else 
                                         vl_monto:= null;
                                       --  dbms_output.put_line('Saldo:');
                                    End if;
                            Else 
                                vl_monto:= null;
                                --dbms_output.put_line('Sin Descuento:');
                            End if;
                                                                    
            End loop;
                        
            If vl_monto > 0 then 
            
                 Begin  
                       select nvl (max(TBRACCD_TRAN_NUMBER) , 0)+1
                       Into vl_secuencia
                       from tbraccd
                       Where tbraccd_pidm =  vl_pidm;
                 Exception
                 When Others then 
                     vl_secuencia := 1;
                    ---------------------------dbms_output.put_line('secuencia error'||sqlerrm);
                 End;      
                 
                 
                 Begin  
                 
                 
                            select distinct 
                                tbraccd_tran_number
                                ,tbraccd_period
                                ,tbraccd_term_code
                                into vl_trans_paid,  
                                      vl_pperiodo, 
                                      vl_periodo
                            from tbraccd tb,TZTNCD tz
                            Where tb.tbraccd_pidm = vl_pidm
                            and tb.tbraccd_detail_code = tz.tztncd_code
                            and tz.tztncd_concepto ='Venta'
                            and tb.tbraccd_feed_date =vl_fecha_inicio
                            and tb.tbraccd_tran_number = (select min (tb1.tbraccd_tran_number)
                                                                            from tbraccd tb1
                                                                            where tb1.tbraccd_pidm = tb.tbraccd_pidm
                                                                            and tb1.tbraccd_detail_code = tb.tbraccd_detail_code
                                                                            and tb1.tbraccd_feed_date = tb.tbraccd_feed_date);
                 Exception
                    When Others then 
                            vl_trans_paid := null;  
                            vl_pperiodo := null;
                            vl_periodo := null;                                                             
                 End;                           
            
            
                 Begin

                        If vl_trans_paid is not null and vl_pperiodo is not null and vl_periodo is not null then 
                               Insert into TBRACCD values ( 
                                        vl_pidm,   -- TBRACCD_PIDM
                                         vl_secuencia,     --TBRACCD_TRAN_NUMBER
                                         vl_periodo,    -- TBRACCD_TERM_CODE
                                         vl_codigo,     ---TBRACCD_DETAIL_CODE
                                         user,     ---TBRACCD_USER
                                         SYSDATE,     --TBRACCD_ENTRY_DATE
                                         nvl(vl_monto,0),
                                         nvl(vl_monto,0) * -1,    ---TBRACCD_BALANCE
                                         sysdate,     -- TBRACCD_EFFECTIVE_DATE
                                         NULL,    --TBRACCD_BILL_DATE
                                         NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                        vl_descripcion,    -- TBRACCD_DESC
                                        null,     --TBRACCD_RECEIPT_NUMBER
                                        vl_trans_paid,     --TBRACCD_TRAN_NUMBER_PAID
                                        NULL,     --TBRACCD_CROSSREF_PIDM
                                        NULL,    --TBRACCD_CROSSREF_NUMBER
                                        null,       --TBRACCD_CROSSREF_DETAIL_CODE
                                          'T',    --TBRACCD_SRCE_CODE 
                                         'Y',    --TBRACCD_ACCT_FEED_IND
                                         sysdate,  --TBRACCD_ACTIVITY_DATE    
                                         0,        --TBRACCD_SESSION_NUMBER
                                         null,    -- TBRACCD_CSHR_END_DATE 
                                         NULL,     --TBRACCD_CRN
                                         NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                         NULL,     -- TBRACCD_LOC_MDT
                                         NULL,     --TBRACCD_LOC_MDT_SEQ
                                         null,     -- TBRACCD_RATE
                                         NULL,     --TBRACCD_UNITS
                                         NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                         sysdate,
                                         NULL,        -- TBRACCD_PAYMENT_ID
                                         NULL,     -- TBRACCD_INVOICE_NUMBER
                                         NULL,     -- TBRACCD_STATEMENT_DATE
                                         NULL,     -- TBRACCD_INV_NUMBER_PAID
                                         'MXN',     -- TBRACCD_CURR_CODE
                                         null,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                         NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                        NULL,     -- TBRACCD_LATE_DCAT_CODE
                                        vl_fecha_inicio,--NULL,     -- TBRACCD_FEED_DATE
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
                                        'BONIF',     -- TBRACCD_DATA_ORIGIN
                                        'BONIF',   -- TBRACCD_CREATE_SOURCE
                                        null,     -- TBRACCD_CPDT_IND
                                        NULL,     --TBRACCD_AIDY_CODE
                                        vl_sp,     --TBRACCD_STSP_KEY_SEQUENCE
                                        vl_pperiodo,     --TBRACCD_PERIOD
                                         NULL,    --TBRACCD_SURROGATE_ID
                                        NULL,     -- TBRACCD_VERSION
                                        user,     --TBRACCD_USER_ID
                                        NULL );     --TBRACCD_VPDI_CODE
                        End if;                                                                  
                                                                                         
                 Exception
                    When Others then 
                      vl_exito :='Error Insertar descuento' ||sqlerrm; 
                       ---------------------------dbms_output.put_line(vl_error);    
                 End;                     
               
            Else
            dbms_output.put_line('No cubre requsitos para promocion:'||vl_monto);
            End if;
                        
                        
        
        End;
        
        RETURN vl_exito;
    
  Exception
    When Others then 
        
    RETURN vl_exito||SQLERRM;
    
  END F_promocion_documentos_core;  
  
FUNCTION F_GET_DOC_VALIDOS(P_PIDM IN NUMBER) RETURN NUMBER 
IS
--DECLARE

--P_PIDM NUMBER:=359901;


VL_VALIDO NUMBER;
VL_EXISTE NUMBER:=0;

CURSOR DOCS(CP_PIDM NUMBER)
IS
SELECT  a.fecha_inicio 
,a.fecha_inicio + 28 Fecha_aplicacion
,b.ZSTPARA_PARAM_ID Documento
,substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, b.ZSTPARA_PARAM_ID),1,10) Fecha_documento
,substr ( pkg_utilerias.f_documento_valido (a.pidm, a.programa, b.ZSTPARA_PARAM_ID),12,50) Estatus_documento
from tztprog a 
join ZSTPARA b on b.ZSTPARA_MAPA_ID = 'DESC_ENTREGADOC' 
    and a.campus =  substr (b.ZSTPARA_PARAM_VALOR,1,3) 
    and  a.nivel = substr (b.ZSTPARA_PARAM_VALOR,5,2) 
    and a.tipo_ingreso = trim (b.ZSTPARA_PARAM_DESC)
    --join GORADID b on b.GORADID_pidm = a.pidm 
    --and GORADID_ADID_CODE = 'PRRT'
WHERE A.PIDM = CP_PIDM; 


BEGIN


    BEGIN
        
        SELECT COUNT(1) 
        INTO VL_EXISTE
        from tztprog a 
            join ZSTPARA b on b.ZSTPARA_MAPA_ID = 'DESC_ENTREGADOC' 
                and a.campus =  substr (b.ZSTPARA_PARAM_VALOR,1,3) 
                and  a.nivel = substr (b.ZSTPARA_PARAM_VALOR,5,2) 
                and a.tipo_ingreso = trim (b.ZSTPARA_PARAM_DESC)
                --join GORADID b on b.GORADID_pidm = a.pidm 
                --and GORADID_ADID_CODE = 'PRRT'
        WHERE A.PIDM = P_PIDM;
        
    EXCEPTION WHEN OTHERS THEN
        VL_EXISTE:=0;  
    END;
    
    IF VL_EXISTE > 0 THEN
        VL_VALIDO := 1;
        
        FOR C IN DOCS(P_PIDM)       
        LOOP
            
            IF C.FECHA_DOCUMENTO <= C.FECHA_APLICACION THEN --si entrego sus documentos antes de la fecha de aplicacion esta bien
                IF C.ESTATUS_DOCUMENTO != 'VALIDADO' THEN --SI NO ES VALIDADO LO VA MANDAR COMO QUE NO CUMPLE
                    VL_VALIDO :=0;
                END IF;
            ELSE
                VL_VALIDO :=0;
            END IF;
        
        END LOOP;
          
    ELSE
        VL_VALIDO := 0;
    END IF;
    
    --DBMS_OUTPUT.PUT_LINE ( 'VL_VALIDO = ' || VL_VALIDO );
    return VL_VALIDO;

END F_GET_DOC_VALIDOS;


PROCEDURE P_PROMOCION_DOCUMENTOS_LATAM
is

vl_TRAN_NUMBER_PAID number;
vl_colegiatura    number;
vl_monto number :=0;
vl_descripcion varchar2(500);
vl_pperiodo  varchar2(4);
vl_secuencia  number :=0;
vl_periodo varchar2(6);

vl_moneda varchar2(6);

vl_ban number :=1;
vl_ban_desc varchar2(4000);

BEGIN


    FOR C IN 
    (
    
        select 
            a.pidm
            ,a.matricula
            ,a.fecha_inicio
            ,a.fecha_inicio + 28 Fecha_aplicacion
            ,tipo_ingreso
            ,nvl ((Select tbraccd_amount
                    from tbraccd
                    where tbraccd_pidm = a.pidm
                    and substr (tbraccd_detail_code, 3,2) = 'HA'),0) Descuento   
            ,(Select distinct ZSTPARA_PARAM_VALOR
                from ZSTPARA
                where  ZSTPARA_MAPA_ID = 'ENTREGADOC_RETE') Porcentaje
            ,substr (a.matricula, 1,2) || 'HA' codigo
            ,a.programa
            ,a.sp
            --,F_GET_DOC_VALIDOS(a.pidm) doc_validos
        from tztprog a
        join GORADID b on b.GORADID_pidm = a.pidm 
            and GORADID_ADID_CODE = 'PRRT'  --en goradid estan los alumnos que pueden recibir esta promocion  
        where a.estatus  in ('MA')
            --and a.FECHA_PRIMERA is null de dejo de utilizar
            And a.sp = (select max (a1.sp) from tztprog a1 Where a.pidm = a1.pidm) --determina el ultimo estudio que esta cursando, con esto no van a salir alumnos dobles.
            And a.campus in (select ZSTPARA_PARAM_ID
                                from ZSTPARA       
                                where ZSTPARA_MAPA_ID = 'TIPO_REGLA'
                                And   ZSTPARA_PARAM_VALOR ='2')    ---> Esta valor de regla determina si el modelo de beneficios es para Core o Expansion (1 Core, 2 Expansion)
            --And a.pidm = 359901
            and nvl((Select tbraccd_amount
                    from tbraccd
                    where tbraccd_pidm = a.pidm
                    and substr (tbraccd_detail_code, 3,2) = 'HA'),0) = 0 --cubrimos que no agarre los que ya recibieron el descuento.
            and PKG_PROMOCIONES.F_GET_DOC_VALIDOS(a.pidm)  = 1
            order by 2 asc
            
    )
    LOOP
    
        vl_ban:=1; --se inicia con bandera en 1, simbolo de que todo va bien
    
        BEGIN  
        
            select nvl (max(TBRACCD_TRAN_NUMBER) , 0)+1
            Into vl_secuencia
            from tbraccd
            Where tbraccd_pidm =  C.pidm;

        EXCEPTION WHEN OTHERS THEN 
            vl_secuencia := 1;
            --no mando error la ligo a secuencia 1, posiblemente va marcar error en el insert ya que se debe ligar a la colegiatura
        END;
        
        
        BEGIN
                
            select TBBDETC_DESC 
            into vl_descripcion
            from tbbdetc
            where tbbdetc_detail_code = C.codigo;
                
        EXCEPTION WHEN OTHERS THEN
            vl_descripcion :='';
        END;
        
        BEGIN
            
            select max(TBRACCD_TERM_CODE)
            into vl_periodo
            from tbraccd
            where tbraccd_pidm =  c.pidm;
        
        EXCEPTION WHEN OTHERS THEN
            vl_ban:=0;
            vl_ban_desc:='Error al recuperar el periodo: pidm:'||c.pidm||' sqlerrm:'||sqlerrm;
        END;


        IF vl_ban = 1 then
            BEGIN
            
                SELECT tvrdctx_curr_code
                INTO vl_moneda
                from TVRDCTX
                where tvrdctx_detc_code = C.codigo;
            
            EXCEPTION WHEN OTHERS THEN                
                vl_ban:=0;
                vl_ban_desc:='Error al recuperar la moneda: pidm:'||c.pidm||' codigo:'||c.codigo||' sqlerrm:'||sqlerrm;
            END;
        END IF;
        
        
        
        ---saber colegiatura
        --vl_monto
        IF vl_ban = 1 then
            BEGIN

                select tbraccd_amount
                    ,tbraccd_tran_number
                    ,tbraccd_period
                    ,(tbraccd_amount * c.porcentaje)/100 as monto
                into vl_colegiatura
                    ,vl_TRAN_NUMBER_PAID
                    ,vl_pperiodo
                    ,vl_monto
                from tbraccd tb,TZTNCD tz
                Where tb.tbraccd_pidm =  c.pidm
                and tb.tbraccd_detail_code = tz.tztncd_code
                and tz.tztncd_concepto ='Venta'
                and tb.tbraccd_feed_date = c.fecha_inicio --se amarra para saber el inicio de clases
                and to_number(to_char(tbraccd_effective_date, 'mm')) = to_number(to_char(tbraccd_feed_date, 'mm')) + 2; --se amarra contra el segundo mes apartir del inicio de clases
            
            EXCEPTION WHEN OTHERS THEN
                vl_ban:=0;
                vl_ban_desc:='Error al recuperar la colegiatura: pidm:'||c.pidm||' codigo:'||c.codigo||' sqlerrm:'||sqlerrm;
            END;
        END IF;
        
        ---------------

--        DBMS_OUTPUT.PUT_LINE ( 'vl_secuencia = ' || vl_secuencia );
--        DBMS_OUTPUT.PUT_LINE ( 'vl_descripcion = ' || vl_descripcion );
--        DBMS_OUTPUT.PUT_LINE ( 'vl_periodo = ' || vl_periodo );
--        DBMS_OUTPUT.PUT_LINE ( 'vl_moneda = ' || vl_moneda );
--        
--        DBMS_OUTPUT.PUT_LINE ( 'vl_colegiatura = ' || vl_colegiatura );
--        DBMS_OUTPUT.PUT_LINE ( 'vl_TRAN_NUMBER_PAID = ' || vl_TRAN_NUMBER_PAID );
--        DBMS_OUTPUT.PUT_LINE ( 'vl_pperiodo = ' || vl_pperiodo );
--        DBMS_OUTPUT.PUT_LINE ( 'vl_monto = ' || vl_monto );
        
        IF vl_ban = 1 THEN
            BEGIN

                Insert into TBRACCD values 
                    (c.pidm,            --vl_pidm,   -- TBRACCD_PIDM
                    vl_secuencia,   --TBRACCD_TRAN_NUMBER 
                    vl_periodo,        -- TBRACCD_TERM_CODE
                    C.codigo,         --vl_codigo,         ---TBRACCD_DETAIL_CODE --concepto a sembrar, es codigo en query principal
                    user,             ---TBRACCD_USER
                    SYSDATE,         --TBRACCD_ENTRY_DATE
                    nvl(vl_monto,0),        --calcular con el porcenta de la consulta contra la colegiatura
                    nvl(vl_monto,0) * -1,   ---TBRACCD_BALANCE        --mismo valor pero en negativo
                    sysdate,                 -- TBRACCD_EFFECTIVE_DATE
                    NULL,                --TBRACCD_BILL_DATE
                    NULL,                --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                    vl_descripcion,        -- TBRACCD_DESC                    --recuperar descripcion del codigo de detalle en tabla tbbdetc
                    null,                 --TBRACCD_RECEIPT_NUMBER
                    vl_TRAN_NUMBER_PAID, --null,                 --TBRACCD_TRAN_NUMBER_PAID         --amarrar contra la colegiatura que va aplicar
                    NULL,                 --TBRACCD_CROSSREF_PIDM
                    NULL,                --TBRACCD_CROSSREF_NUMBER
                    null,               --TBRACCD_CROSSREF_DETAIL_CODE
                    'T',                --TBRACCD_SRCE_CODE 
                    'Y',                --TBRACCD_ACCT_FEED_IND
                    sysdate,              --TBRACCD_ACTIVITY_DATE    
                    0,                    --TBRACCD_SESSION_NUMBER
                    null,                -- TBRACCD_CSHR_END_DATE 
                    NULL,                 --TBRACCD_CRN
                    NULL,                 --TBRACCD_CROSSREF_SRCE_CODE
                    NULL,                 -- TBRACCD_LOC_MDT
                    NULL,                 --TBRACCD_LOC_MDT_SEQ
                    null,                 -- TBRACCD_RATE
                    NULL,                 --TBRACCD_UNITS
                    NULL,                 -- TBRACCD_DOCUMENT_NUMBER
                    sysdate,
                    NULL,                -- TBRACCD_PAYMENT_ID
                    NULL,                 -- TBRACCD_INVOICE_NUMBER
                    NULL,                 -- TBRACCD_STATEMENT_DATE
                    NULL,                 -- TBRACCD_INV_NUMBER_PAID
                    vl_moneda, --'MXN',                 -- TBRACCD_CURR_CODE                    --recuperamos la moneda con el codigo, EN TABLA TVRDCTX atravez del codigo de detalle
                    null,                 -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                    NULL,                -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                    NULL,                 -- TBRACCD_LATE_DCAT_CODE
                    c.fecha_inicio, --vl_fecha_inicio,    --NULL,     -- TBRACCD_FEED_DATE    --fecha de inicio de clases
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
                    'BONIF',    -- TBRACCD_DATA_ORIGIN
                    'BONIF',       -- TBRACCD_CREATE_SOURCE
                    null,         -- TBRACCD_CPDT_IND
                    NULL,         --TBRACCD_AIDY_CODE
                    c.sp,     --vl_sp,    --TBRACCD_STSP_KEY_SEQUENCE    ---recuerpear columna sp del alumno
                    vl_pperiodo,    --TBRACCD_PERIOD          --recuperar de la cartera
                    NULL,            --TBRACCD_SURROGATE_ID
                    NULL,             -- TBRACCD_VERSION
                    user,             --TBRACCD_USER_ID
                    NULL);         --TBRACCD_VPDI_CODE
                                                                                          
                                                                                         
            Exception When Others then 
                vl_ban :=0;
                vl_ban_desc :='Error Insertar descuento' ||sqlerrm; ---que vamos hacer si hay error?
            End; 
        END IF;
        
        IF vl_ban = 0 then
            
            BEGIN
                INSERT INTO TZTBIPROM
                VALUES(
                    c.pidm
                    ,'DESCUENTO_DOCS_LATAM'
                    ,'ERROR'
                    ,SUBSTR(vl_ban_desc,1,900)
                    ,sysdate
                    );
            EXCEPTION WHEN OTHERS THEN
                INSERT INTO TZTBIPROM
                VALUES(
                    c.pidm
                    ,'DESCUENTO_DOCS_LATAM'
                    ,'ERROR'
                    ,'Error al escribir en bitacora.'
                    ,sysdate
                    );
            END;
        END IF;
        
              
        
    END LOOP;
    

END P_PROMOCION_DOCUMENTOS_LATAM;



  FUNCTION F_promocion_no_materia_LATAM(p_pidm IN NUMBER) RETURN varchar2 is

vl_exito varchar2(500):='EXITO';
vl_bimestre number:=0;
vl_vueltas number :=0;
VL_SECUENCIA number :=0;


Begin

    For cx in (
    
        select 
            a.pidm
            ,a.matricula
            ,a.fecha_inicio
            ,tipo_ingreso
            ,(Select distinct ZSTPARA_PARAM_DESC
                from ZSTPARA
                where  ZSTPARA_MAPA_ID = 'PROMO_MATAPROBA') Porcentaje
            ,substr (a.matricula, 1,2) || 'HB' codigo
           ,TBBDETC_DESC Descripcion
            ,a.programa
            ,a.sp
            ,nvl (PKG_UTILERIAS.F_CALCULA_BIMESTRES ( a.pidm,a.sp ),0) Bimestre,
            nvl ((select SZTHITA_REPROB 
            from szthita 
            Where SZTHITA_PIDM = a.pidm
            And SZTHITA_STUDY = a.sp),0)  Reprobadas
        from tztprog a
        join GORADID b on b.GORADID_pidm = a.pidm 
            and GORADID_ADID_CODE = 'PRRT'  --en goradid estan los alumnos que pueden recibir esta promocion  
          join  tbbdetc on TBBDETC_DETAIL_CODE = substr (a.matricula, 1,2) || 'HB'
        where a.estatus  in ('MA')
            --and a.FECHA_PRIMERA is null de dejo de utilizar
            And a.sp = (select max (a1.sp) from tztprog a1 Where a.pidm = a1.pidm) --determina el ultimo estudio que esta cursando, con esto no van a salir alumnos dobles.
            And a.campus in (select ZSTPARA_PARAM_ID
                                from ZSTPARA       
                                where ZSTPARA_MAPA_ID = 'TIPO_REGLA'
                                And   ZSTPARA_PARAM_VALOR ='2')    ---> Esta valor de regla determina si el modelo de beneficios es para Core o Expansion (1 Core, 2 Expansion)
            And a.pidm = p_pidm
      
    ) loop      
    
            If cx.reprobadas =  0 then
            
                Begin 
                        Select distinct substr (ZSTPARA_PARAM_ID,1,1) bimestre
                            Into vl_bimestre
                        from ZSTPARA
                        where  ZSTPARA_MAPA_ID = 'PROMO_MATAPROBA'
                        and substr (ZSTPARA_PARAM_ID,1,1) = cx.bimestre;
                Exception
                    When Others then        
                        vl_bimestre:=0; 
                End;
                
                If vl_bimestre > 0 then 
                    
                    vl_vueltas:=0;
                    For cc in (
                
                                    select distinct 
                                        tbraccd_tran_number secuencia
                                        ,TBRACCD_EFFECTIVE_DATE vencimiento
                                        ,tbraccd_period Pperiodo
                                        ,tbraccd_term_code Periodo
                                        ,tbraccd_amount cargo
                                         ,(tbraccd_amount * cx.porcentaje)/100  monto
                                         ,TBRACCD_CURR_CODE Moneda
                                    from tbraccd tb,TZTNCD tz
                                    Where tb.tbraccd_pidm = cx.pidm --vl_pidm
                                    and tb.tbraccd_detail_code = tz.tztncd_code
                                    and tz.tztncd_concepto ='Venta'
                                    and tb.tbraccd_feed_date = cx.fecha_inicio
                                    order by 1,2
             
                      ) loop
                
                                 Begin  
                                       select nvl (max(TBRACCD_TRAN_NUMBER) , 0)+1
                                       Into vl_secuencia
                                       from tbraccd
                                       Where tbraccd_pidm =  cx.pidm;
                                 Exception
                                 When Others then 
                                     vl_secuencia := 1;
                                    ---------------------------dbms_output.put_line('secuencia error'||sqlerrm);
                                 End;                     
                
                                vl_vueltas := vl_vueltas + 1;
                                
                                 Begin

                                      
                                                   Insert into TBRACCD values ( 
                                                            cx.pidm,   -- TBRACCD_PIDM
                                                             vl_secuencia,     --TBRACCD_TRAN_NUMBER
                                                             cc.periodo,    -- TBRACCD_TERM_CODE
                                                             cx.codigo,     ---TBRACCD_DETAIL_CODE
                                                             user,     ---TBRACCD_USER
                                                             SYSDATE,     --TBRACCD_ENTRY_DATE
                                                             nvl(cc.monto,0),
                                                             nvl(cc.monto,0) * -1,    ---TBRACCD_BALANCE
                                                             sysdate,     -- TBRACCD_EFFECTIVE_DATE
                                                             NULL,    --TBRACCD_BILL_DATE
                                                             NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                                            cx.descripcion,    -- TBRACCD_DESC
                                                            null,     --TBRACCD_RECEIPT_NUMBER
                                                            cc.secuencia,     --TBRACCD_TRAN_NUMBER_PAID
                                                            NULL,     --TBRACCD_CROSSREF_PIDM
                                                            NULL,    --TBRACCD_CROSSREF_NUMBER
                                                            null,       --TBRACCD_CROSSREF_DETAIL_CODE
                                                              'T',    --TBRACCD_SRCE_CODE 
                                                             'Y',    --TBRACCD_ACCT_FEED_IND
                                                             sysdate,  --TBRACCD_ACTIVITY_DATE    
                                                             0,        --TBRACCD_SESSION_NUMBER
                                                             null,    -- TBRACCD_CSHR_END_DATE 
                                                             NULL,     --TBRACCD_CRN
                                                             NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                                             NULL,     -- TBRACCD_LOC_MDT
                                                             NULL,     --TBRACCD_LOC_MDT_SEQ
                                                             null,     -- TBRACCD_RATE
                                                             NULL,     --TBRACCD_UNITS
                                                             NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                                             sysdate,
                                                             NULL,        -- TBRACCD_PAYMENT_ID
                                                             NULL,     -- TBRACCD_INVOICE_NUMBER
                                                             NULL,     -- TBRACCD_STATEMENT_DATE
                                                             NULL,     -- TBRACCD_INV_NUMBER_PAID
                                                             cc.moneda,     -- TBRACCD_CURR_CODE
                                                             null,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                                             NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                                            NULL,     -- TBRACCD_LATE_DCAT_CODE
                                                            cx.fecha_inicio,--NULL,     -- TBRACCD_FEED_DATE
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
                                                            'BONIF',     -- TBRACCD_DATA_ORIGIN
                                                            'BONIF',   -- TBRACCD_CREATE_SOURCE
                                                            null,     -- TBRACCD_CPDT_IND
                                                            NULL,     --TBRACCD_AIDY_CODE
                                                            cx.sp,     --TBRACCD_STSP_KEY_SEQUENCE
                                                            cc.periodo,     --TBRACCD_PERIOD
                                                             NULL,    --TBRACCD_SURROGATE_ID
                                                            NULL,     -- TBRACCD_VERSION
                                                            user,     --TBRACCD_USER_ID
                                                            NULL );     --TBRACCD_VPDI_CODE


                                 Exception
                                        When Others then 
                                          vl_exito :='Error Insertar descuento' ||sqlerrm; 
                                           ---------------------------dbms_output.put_line(vl_error);    
                                 End;                     
                
                         exit when vl_vueltas=2;
                
                      End loop;
                
                
                End if;
            
            
            
            End if;    
                    
    
    
    End loop;
    
    Return vl_exito;
    
End F_promocion_no_materia_LATAM;        


 PROCEDURE P_PROMOCION_no_adeudo_LATAM 
 Is 
 
vl_exito varchar2(500):= null;
vl_meses number:=0;
vl_aplica number :=0;
VL_SECUENCIA number :=0;


Begin

    For cx in (
    
        select 
            a.pidm
            ,a.matricula
            ,a.fecha_inicio
            ,tipo_ingreso
            ,(Select distinct ZSTPARA_PARAM_DESC
                from ZSTPARA
                where  ZSTPARA_MAPA_ID = 'PROMO_PAGOCORRI') Porcentaje            
            ,substr (a.matricula, 1,2) || 'HC' codigo
           ,TBBDETC_DESC Descripcion
            ,a.programa
            ,a.sp
            ,PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(a.pidm) Saldo
        from tztprog a
        join GORADID b on b.GORADID_pidm = a.pidm 
            and GORADID_ADID_CODE = 'PRRT'  --en goradid estan los alumnos que pueden recibir esta promocion  
         left join  tbbdetc on TBBDETC_DETAIL_CODE = substr (a.matricula, 1,2) || 'HC'
             where a.estatus  in ('MA')
            And PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(a.pidm) <= 0
            And a.sp = (select max (a1.sp) from tztprog a1 Where a.pidm = a1.pidm) --determina el ultimo estudio que esta cursando, con esto no van a salir alumnos dobles.
            And a.campus in (select ZSTPARA_PARAM_ID
                                from ZSTPARA       
                                where ZSTPARA_MAPA_ID = 'TIPO_REGLA'
                                And   ZSTPARA_PARAM_VALOR ='2')    ---> Esta valor de regla determina si el modelo de beneficios es para Core o Expansion (1 Core, 2 Expansion)
         -- And a.pidm = 459042
            
      
    ) loop      
    
                                Begin 
                                    select distinct count(*)
                                        Into vl_meses
                                    from tbraccd tb,TZTNCD tz
                                    Where tb.tbraccd_pidm =cx.pidm 
                                    and tb.tbraccd_detail_code = tz.tztncd_code
                                    and tz.tztncd_concepto ='Venta';
                                Exception
                                    When Others then 
                                        vl_meses:=0;
                                End;
                
                                Begin 
                                    Select distinct ZSTPARA_PARAM_ID
                                        Into vl_aplica
                                    from ZSTPARA
                                    where  ZSTPARA_MAPA_ID = 'PROMO_PAGOCORRI'
                                    and  ZSTPARA_PARAM_ID = vl_meses;
                                Exception
                                    When Others then  
                                    vl_aplica:=0;   
                                End;
    

                
                If vl_aplica > 0 then 

                    For cc in (
                
                                    select distinct 
                                        tbraccd_tran_number secuencia
                                        ,TBRACCD_EFFECTIVE_DATE vencimiento
                                        ,ADD_MONTHS(TO_DATE(TBRACCD_EFFECTIVE_DATE,'DD/MM/RRRR'),1) Sig_vencimiento
                                        ,tbraccd_period Pperiodo
                                        ,tbraccd_term_code Periodo
                                        ,tbraccd_amount cargo
                                         ,(tbraccd_amount * cx.porcentaje)/100  monto
                                         ,TBRACCD_CURR_CODE Moneda
                                    from tbraccd tb,TZTNCD tz
                                    Where tb.tbraccd_pidm =cx.pidm --vl_pidm
                                    and tb.tbraccd_detail_code = tz.tztncd_code
                                    and tz.tztncd_concepto ='Venta'
                                    And tb.tbraccd_tran_number in (select max (tb1.tbraccd_tran_number)
                                                                                    from tbraccd tb1
                                                                                    Where tb1.tbraccd_pidm = tb.tbraccd_pidm
                                                                                    And tb1.tbraccd_detail_code = tb.tbraccd_detail_code
                                                                                  )
                                    order by 1,2
             
                      ) loop
                
                                 Begin  
                                       select nvl (max(TBRACCD_TRAN_NUMBER) , 0)+1
                                       Into vl_secuencia
                                       from tbraccd
                                       Where tbraccd_pidm =  cx.pidm;
                                 Exception
                                 When Others then 
                                     vl_secuencia := 1;
                                    ---------------------------dbms_output.put_line('secuencia error'||sqlerrm);
                                 End;                     
                
                                
                                 Begin

                                      
                                                   Insert into TBRACCD values ( 
                                                            cx.pidm,   -- TBRACCD_PIDM
                                                             vl_secuencia,     --TBRACCD_TRAN_NUMBER
                                                             cc.periodo,    -- TBRACCD_TERM_CODE
                                                             cx.codigo,     ---TBRACCD_DETAIL_CODE
                                                             user,     ---TBRACCD_USER
                                                             SYSDATE,     --TBRACCD_ENTRY_DATE
                                                             nvl(cc.monto,0),
                                                             nvl(cc.monto,0) * -1,    ---TBRACCD_BALANCE
                                                             sysdate,     -- TBRACCD_EFFECTIVE_DATE
                                                             NULL,    --TBRACCD_BILL_DATE
                                                             NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                                            cx.descripcion,    -- TBRACCD_DESC
                                                            null,     --TBRACCD_RECEIPT_NUMBER
                                                            cc.secuencia,     --TBRACCD_TRAN_NUMBER_PAID
                                                            NULL,     --TBRACCD_CROSSREF_PIDM
                                                            NULL,    --TBRACCD_CROSSREF_NUMBER
                                                            null,       --TBRACCD_CROSSREF_DETAIL_CODE
                                                              'T',    --TBRACCD_SRCE_CODE 
                                                             'Y',    --TBRACCD_ACCT_FEED_IND
                                                             sysdate,  --TBRACCD_ACTIVITY_DATE    
                                                             0,        --TBRACCD_SESSION_NUMBER
                                                             null,    -- TBRACCD_CSHR_END_DATE 
                                                             NULL,     --TBRACCD_CRN
                                                             NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                                             NULL,     -- TBRACCD_LOC_MDT
                                                             NULL,     --TBRACCD_LOC_MDT_SEQ
                                                             null,     -- TBRACCD_RATE
                                                             NULL,     --TBRACCD_UNITS
                                                             NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                                             sysdate,
                                                             NULL,        -- TBRACCD_PAYMENT_ID
                                                             NULL,     -- TBRACCD_INVOICE_NUMBER
                                                             NULL,     -- TBRACCD_STATEMENT_DATE
                                                             NULL,     -- TBRACCD_INV_NUMBER_PAID
                                                             cc.moneda,     -- TBRACCD_CURR_CODE
                                                             null,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                                             NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                                            NULL,     -- TBRACCD_LATE_DCAT_CODE
                                                            cx.fecha_inicio,--NULL,     -- TBRACCD_FEED_DATE
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
                                                            'BONIF',     -- TBRACCD_DATA_ORIGIN
                                                            'BONIF',   -- TBRACCD_CREATE_SOURCE
                                                            null,     -- TBRACCD_CPDT_IND
                                                            NULL,     --TBRACCD_AIDY_CODE
                                                            cx.sp,     --TBRACCD_STSP_KEY_SEQUENCE
                                                            cc.periodo,     --TBRACCD_PERIOD
                                                             NULL,    --TBRACCD_SURROGATE_ID
                                                            NULL,     -- TBRACCD_VERSION
                                                            user,     --TBRACCD_USER_ID
                                                            NULL );     --TBRACCD_VPDI_CODE


                                 Exception
                                        When Others then 
                                          vl_exito :='Error Insertar descuento' ||sqlerrm; 
                                           ---------------------------dbms_output.put_line(vl_error);    
                                 End;                     
                
                      End loop;
                
                End if;
            
    End loop;
    

End P_PROMOCION_no_adeudo_LATAM;          



END PKG_PROMOCIONES;
/
