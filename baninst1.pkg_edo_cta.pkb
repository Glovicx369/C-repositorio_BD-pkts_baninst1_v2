DROP PACKAGE BODY BANINST1.PKG_EDO_CTA;

CREATE OR REPLACE PACKAGE BODY BANINST1."PKG_EDO_CTA" 
AS
   /******************************************************************************
      NAME:       BANINST1.PKG_EDO_CTA
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        30/11/2022      GOLVERA       1. Created this package.
   ******************************************************************************/

   /*FUNCION CON RETORNO DE CIFRAS POR PERIODO*/
   FUNCTION F_RESUMEN_PERIODO (P_PIDM NUMBER, PI_PERIODO VARCHAR2)
      RETURN PKG_EDO_CTA.CCP_OUT
   AS
      PERIODO_OUT    PKG_EDO_CTA.CCP_OUT;

      -- Periodos
      ---- 1 Enero 01 - Abril 04
      ---- 2 Mayo 05 - Agosto 08
      ---- 3 Septiembre 09 - Diciembre 12

      vIniPeriodo    VARCHAR2 (10);
      vAnioPeriodo   VARCHAR2 (10);
      vFecIniP       DATE;
      vFecFinP       DATE;
      v_error        VARCHAR2 (4000);
   BEGIN
      vIniPeriodo := TO_CHAR (SUBSTR (PI_PERIODO, 1, 1));
      vAnioPeriodo := TO_CHAR (SUBSTR (PI_PERIODO, 3, 4));


      IF vIniPeriodo = '1'
      THEN
         vFecIniP := TO_DATE ('01/01/' || vAnioPeriodo, 'DD/MM/YYYY');
         vFecFinP :=
            LAST_DAY (TO_DATE ('01/04/' || vAnioPeriodo, 'DD/MM/YYYY'));
      ELSIF vIniPeriodo = '2'
      THEN
         vFecIniP := TO_DATE ('01/05/' || vAnioPeriodo, 'DD/MM/YYYY');
         vFecFinP :=
            LAST_DAY (TO_DATE ('01/08/' || vAnioPeriodo, 'DD/MM/YYYY'));
      ELSIF vIniPeriodo = '3'
      THEN
         vFecIniP := TO_DATE ('01/09/' || vAnioPeriodo, 'DD/MM/YYYY');
         vFecFinP :=
            LAST_DAY (TO_DATE ('01/12/' || vAnioPeriodo, 'DD/MM/YYYY'));
      END IF;


      OPEN PERIODO_OUT FOR
         SELECT SUM (CARGOS_PERIODO) CARGOS_PERIODO,
                SUM (PAGOS_PERIODO) PAGOS_PERIODO,
                SUM ( (CARGOS_PERIODO - PAGOS_PERIODO)) BALANCE_PERIODO
           FROM (SELECT NVL (SUM (TBRACCD_AMOUNT), 0) CARGOS_PERIODO,
                        0 PAGOS_PERIODO,
                        0 BALANCE_PERIODO
                   FROM tbraccd
                        JOIN tbbdetc
                           ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                        JOIN TZTNCD
                           ON     TZTNCD_CODE = TBRACCD_DETAIL_CODE
                              AND UPPER (TZTNCD_CONCEPTO) IN ('VENTA',
                                                              'INTERES',
                                                              'NOTA DEBITO')
                              AND TBBDETC_TYPE_IND IN ('C')
                  WHERE     TBRACCD_PIDM = P_PIDM
                        AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN vFecIniP
                                                               AND vFecFinP
                 UNION
                 SELECT 0,
                        NVL (SUM (TBRACCD_AMOUNT), 0) PAGOS_PERIODO,
                        0 BALANCE_PERIODO
                   FROM tbraccd
                        JOIN tbbdetc
                           ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                        JOIN TZTNCD
                           ON     TZTNCD_CODE = TBRACCD_DETAIL_CODE
                              AND UPPER (TZTNCD_CONCEPTO) IN ('POLIZA',
                                                              'DEPOSITO',
                                                              'NOTA DISTRIBUCION',
                                                              'NOTA CREDITO','INTERES', 'FINANCIERAS')
                              AND TBBDETC_TYPE_IND IN ('P')
                  WHERE     TBRACCD_PIDM = P_PIDM
                        AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN vFecIniP
                                                               AND vFecFinP);

      RETURN (PERIODO_OUT);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error := 'No se encontraron registros' || SQLERRM;

         OPEN PERIODO_OUT FOR SELECT NULL, NULL, NULL || v_error FROM DUAL;

         RETURN (PERIODO_OUT);
   END F_RESUMEN_PERIODO;


   /*FUNCION DETALLES DE CARGOS*/
   FUNCTION F_DETALLE_PERIODO (P_PIDM NUMBER, PI_SECUENCE NUMBER)
      RETURN PKG_EDO_CTA.CPP_OUT
   AS
      PROMOS_OUT   PKG_EDO_CTA.CPP_OUT;

      v_error      VARCHAR2 (4000);
   BEGIN
      OPEN PROMOS_OUT FOR
                  SELECT DESCRIPCION_CARGO, to_char( monto_cargo), fecha, secuencia from (
With pagos as (
                    Select tbraccd_desc descripcion, tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER SEq, TBRACCD_ENTRY_DATE fecha
                        from tbraccd
    ),
 cargos as (Select tbraccd_desc descripcion, tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER SEq, tbraccd_amount Monto, TBRACCD_ENTRY_DATE fecha
                        from tbraccd
)                    
Select c.descripcion Descripcion_cargo, c.Monto Monto_Cargo, c.fecha, c.seq as Secuencia
from tbrappl
join cargos c on c.pidm =  tbrappl_pidm and c.seq = TBRAPPL_CHG_TRAN_NUMBER
left join pagos b on b.pidm =  tbrappl_pidm and b.seq = TBRAPPL_PAY_TRAN_NUMBER 
where 1= 1
and tbrappl_pidm = P_PIDM
and TBRAPPL_CHG_TRAN_NUMBER = PI_SECUENCE
and (tbrappl_pidm, TBRAPPL_PAY_TRAN_NUMBER ) in (select tbraccd_pidm, TBRACCD_TRAN_NUMBER
                                                                                                                                 from tbraccd, TZTNCD 
                                                                                                                                 where tbraccd_detail_code = TZTNCD_CODE
                                                                                                                                                               AND UPPER (TZTNCD_CONCEPTO) IN ('VENTA',
                                                              'INTERES',
                                                              'NOTA DEBITO', 
                                                              'FINANCIERAS',
                                                              'NOTA CREDITO',
                                                              'POLIZA',
                                                              'DEPOSITO',
                                                              'NOTA DISTRIBUCION')))
union
sELECT DESCRIPCION_CARGO, to_char('-'||monto_cargo) monto_cargo, fecha, secuencia from (
With pagos as (
                    Select tbraccd_desc descripcion, tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER SEq, TBRACCD_EFFECTIVE_DATE fecha
                        from tbraccd
    ),
 cargos as (Select tbraccd_desc descripcion, tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER SEq, tbraccd_amount Monto, TBRACCD_EFFECTIVE_DATE fecha
                        from tbraccd
)                    
Select b.descripcion descripcion_cargo,TBRAPPL_AMOUNT Monto_cargo, TBRAPPL_ACTIVITY_DATE fecha , TBRAPPL_PAY_TRAN_NUMBER secuencia
from tbrappl
join cargos c on c.pidm =  tbrappl_pidm and c.seq = TBRAPPL_CHG_TRAN_NUMBER
left join pagos b on b.pidm =  tbrappl_pidm and b.seq = TBRAPPL_PAY_TRAN_NUMBER 
where 1= 1
and tbrappl_pidm = P_PIDM
and TBRAPPL_CHG_TRAN_NUMBER = PI_SECUENCE
and (tbrappl_pidm, TBRAPPL_PAY_TRAN_NUMBER ) in (select tbraccd_pidm, TBRACCD_TRAN_NUMBER
                                                                                                                                 from tbraccd, TZTNCD 
                                                                                                                                 where tbraccd_detail_code = TZTNCD_CODE
                                                                                                                                                               AND UPPER (TZTNCD_CONCEPTO) IN ('VENTA',
                                                              'INTERES',
                                                              'NOTA DEBITO', 
                                                              'FINANCIERAS',
                                                              'NOTA CREDITO',
                                                              'POLIZA',
                                                              'DEPOSITO',
                                                              'NOTA DISTRIBUCION'))
                                                              )
union
sELECT DESCRIPCION_CARGO, to_char (monto_cargo), fecha, secuencia from (
With pagos as (
                    Select tbraccd_desc descripcion, tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER SEq, TBRACCD_EFFECTIVE_DATE fecha
                        from tbraccd
    ),
 cargos as (Select tbraccd_desc descripcion, tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER SEq, tbraccd_amount Monto, TBRACCD_EFFECTIVE_DATE fecha
                        from tbraccd
)                    
Select 'TOTAL' descripcion_cargo,  ((c.monto) - (sum(TBRAPPL_AMOUNT))) Monto_cargo, null fecha , null secuencia
from tbrappl
join cargos c on c.pidm =  tbrappl_pidm and c.seq = TBRAPPL_CHG_TRAN_NUMBER
left join pagos b on b.pidm =  tbrappl_pidm and b.seq = TBRAPPL_PAY_TRAN_NUMBER 
where 1= 1
and tbrappl_pidm = P_PIDM
and TBRAPPL_CHG_TRAN_NUMBER = PI_SECUENCE
and (tbrappl_pidm, TBRAPPL_PAY_TRAN_NUMBER ) in (select tbraccd_pidm, TBRACCD_TRAN_NUMBER
                                                                                                                                 from tbraccd, TZTNCD 
                                                                                                                                 where tbraccd_detail_code = TZTNCD_CODE
                                                                                                                                                               AND UPPER (TZTNCD_CONCEPTO) IN ('VENTA',
                                                              'INTERES',
                                                              'NOTA DEBITO', 
                                                              'FINANCIERAS',
                                                              'NOTA CREDITO',
                                                              'POLIZA',
                                                              'DEPOSITO',
                                                              'NOTA DISTRIBUCION'))
                                                       group by c.monto       )
                                                              order by fecha;

      RETURN (PROMOS_OUT);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error := 'No se encontraron registros' || SQLERRM;

         OPEN PROMOS_OUT FOR SELECT NULL, NULL, NULL, null || v_error FROM DUAL;

         RETURN (PROMOS_OUT);
   END F_DETALLE_PERIODO;

   /*FUNCION DETALLES DE PAGOS*/
   FUNCTION F_DETALLE_PAGOS (P_PIDM NUMBER, PI_SECUENCE NUMBER)
      RETURN PKG_EDO_CTA.DP_OUT
   AS
      DETPA_OUT   PKG_EDO_CTA.DP_OUT;

      v_error     VARCHAR2 (4000);
   BEGIN
      OPEN DETPA_OUT FOR
  
select descripcion_PAGO, PAGO, FECHA from (
With pagos as (
                    Select tbraccd_desc descripcion, tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER SEq,  TBRACCD_PAYMENT_ID no_pago, TBRACCD_EFFECTIVE_DATE fecha
                        from tbraccd
    ),
 cargos as (Select tbraccd_desc descripcion, tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER SEq, tbraccd_amount Monto, TBRACCD_EFFECTIVE_DATE fecha
                        from tbraccd
)                    
Select UNIQUE b.descripcion Descripcion_PAGO, TBRAPPL_AMOUNT PAGO, b.fecha
from tbrappl
join cargos c on c.pidm =  tbrappl_pidm and c.seq = TBRAPPL_PAY_TRAN_NUMBER
left join pagos b on b.pidm =  tbrappl_pidm and b.seq = TBRAPPL_CHG_TRAN_NUMBER 
where 1= 1
and tbrappl_pidm = P_PIDM
AND TBRAPPL_PAY_TRAN_NUMBER =PI_SECUENCE
and TBRAPPL_REAPPL_IND is null)
UNION 
select 'TOTAL' descripcion_PAGO, SUM(PAGO) PAGO, NULL FECHA from (
With pagos as (
                    Select tbraccd_desc descripcion, tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER SEq,  TBRACCD_PAYMENT_ID no_pago, TBRACCD_EFFECTIVE_DATE fecha
                        from tbraccd
    ),
 cargos as (Select tbraccd_desc descripcion, tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER SEq, tbraccd_amount Monto, TBRACCD_EFFECTIVE_DATE fecha
                        from tbraccd
)                    
Select UNIQUE b.descripcion Descripcion_PAGO, TBRAPPL_AMOUNT PAGO, null fecha
from tbrappl
join cargos c on c.pidm =  tbrappl_pidm and c.seq = TBRAPPL_PAY_TRAN_NUMBER
left join pagos b on b.pidm =  tbrappl_pidm and b.seq = TBRAPPL_CHG_TRAN_NUMBER 
where 1= 1
and tbrappl_pidm = P_PIDM
AND TBRAPPL_PAY_TRAN_NUMBER =PI_SECUENCE
and TBRAPPL_REAPPL_IND is null)
GROUP BY FECHA;


      RETURN (DETPA_OUT);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error := 'No se encontraron registros' || SQLERRM;

         OPEN DETPA_OUT FOR SELECT NULL, NULL,NULL || v_error FROM DUAL;

         RETURN (DETPA_OUT);
   END F_DETALLE_PAGOS;

   /*FUNCION DETALLES DE SALDO PENDIENTE */
   FUNCTION F_SALDO_PENDIENTE (P_PIDM NUMBER, PI_SECUENCE NUMBER)
      RETURN PKG_EDO_CTA.SPP_OUT
   AS
      SALDO_OUT   PKG_EDO_CTA.SPP_OUT;

      v_error     VARCHAR2 (4000);
   BEGIN
      OPEN SALDO_OUT FOR
       SELECT b.tbraccd_desc DESCRIPCION_SALDO,
               TBRACCD_BALANCE SALDO
           FROM tbrappl
                LEFT JOIN tbraccd b
                   ON     b.tbraccd_pidm = tbrappl_pidm
                      AND b.TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
          WHERE     1 = 1
                AND tbrappl_pidm = P_PIDM
                AND TBRAPPL_PAY_TRAN_NUMBER = PI_SECUENCE
            UNION
                   SELECT 'TOTAL' DESCRIPCION_SALDO,
               SUM(TBRACCD_BALANCE) SALDO
           FROM tbrappl
                LEFT JOIN tbraccd b
                   ON     b.tbraccd_pidm = tbrappl_pidm
                      AND b.TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
          WHERE     1 = 1
                AND tbrappl_pidm = P_PIDM
               AND TBRAPPL_PAY_TRAN_NUMBER = PI_SECUENCE;
      RETURN (SALDO_OUT);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error := 'No se encontraron registros' || SQLERRM;

         OPEN SALDO_OUT FOR SELECT NULL, NULL || v_error FROM DUAL;

         RETURN (SALDO_OUT);
   END F_SALDO_PENDIENTE;
   

Function  f_dashboard_edo_cta (p_pidm in number )RETURN SYS_REFCURSOR -- PKG_EDO_CTA.desc_edocta_out
As

   desc_edocta SYS_REFCURSOR; -- PKG_EDO_CTA.desc_edocta_out;
   v_error varchar2(4000);
   vl_id varchar2(2):= null;

               BEGIN

                      Begin
                        Select distinct substr (spriden_id,1,2)
                         Into vl_id
                        from spriden
                        Where spriden_pidm = p_pidm
                        And spriden_Change_ind is null;
                      Exception
                        When Others then 
                            null;
                      End;


--                 P_dashboard_detail_code;
                 P_dashboard_detail_code(p_pidm, vl_id) ;

                 open desc_edocta
                   FOR
                      -- OMS 15/Febrero/2024 (Se agrega el Nombre del Programa, de acuerdo al Study-Path, 4 Columnas al final del cursor)
                     SELECT DISTINCT z.*, x.programa, x.nombre
                      FROM (

                     -- OMS 15/Febrero/2024 (Versi n del Query Original, solo se agregan los campos al final del cursor (4 Columnas))
                     SELECT DISTINCT  TBRACCD_TERM_CODE Periodo,
                                      TBRACCD_TRAN_NUMBER Secuencia,
                                      TBRACCD_DETAIL_CODE Concepto,
                                  --  OMS 07/Agosto/2024
                                  --  TBBDETC_DESC Descripcion_Concepto,    
                                      NVL (TZTEDTC_DESC_NE, TBBDETC_DESC || '.') Descripcion_Concepto,

                                      (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN TBRACCD_AMOUNT
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN NULL
                                       END)
                                         AS Monto_Inicial_Cargo,
                                      TBRACCD_BALANCE Saldo_Actual_Cargo,
                                      TRUNC (TBRACCD_TRANS_DATE) Fecha_Cargo,
                                      TRUNC (TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                      (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN NULL
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN TBRACCD_AMOUNT
                                       END)
                                         AS Monto_Pago,
                                      DECODE (TBBDETC_TYPE_IND,  'C', 'Cargo',  'P', 'Pago') Tipo,
                                        null Iva,
                                        null Concepto_IVA,
--                                      TVRTAXD_TAX_AMOUNT Iva,
--                                      TVRTAXD_DETAIL_CODE Concepto_IVA,
                                      NVL (TBRACCD_CURR_CODE, 'MXN') MONEDA,
                                      TBRACCD_RECEIPT_NUMBER ORDEN,
                                      TBRACCD_PAYMENT_ID NUMERO_PAGO,
                                      TBRACCD_ENTRY_DATE Fecha_Ajuste,
                                      tbraccd_pidm,
                                      TBRACCD_STSP_KEY_SEQUENCE Study_Path
                        FROM tbraccd, tbbdetc, TVRTAXD, TZTEDTC

                       WHERE TBRACCD_PIDM = p_pidm
                             AND TBRACCD_DETAIL_CODE IN
                                     (SELECT TVRDCTX_DETC_CODE
                                        FROM TVRDCTX
                                       WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                             --AND TVRDCTX_CURR_CODE = 'MXN'
                                             )

                         --  OMS 07/Agosto/2024 LEFT JOIN
                             AND TZTEDTC_DETAIL_CODE (+) = TBRACCD_DETAIL_CODE

                             AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                             AND TVRTAXD_PIDM(+) = TBRACCD_PIDM
                             AND TVRTAXD_ACCD_TRAN_NUMBER(+) = TBRACCD_TRAN_NUMBER

                             --Se agreg??                            --and TBBDETC_DETC_ACTIVE_IND = 'Y'  Debe se saber su Edo de Cta aunque no est?activos
                             --Para homologar el mismo campus
                             AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2) =  SUBSTR (TBRACCD_TERM_CODE, 1, 2)
                             AND TBRACCD_DETAIL_CODE NOT IN --Excluye Tanto categoria como Detalle configurados en Param (Si existe detalle, no toma la Categoria)
                             --En caso de ser abonos, no se lleva el cargo que cubrio
                                    (  SELECT DISTINCT TZTCODD_DETAIL_CODE FROM TZTCODD 
                                                                            WHERE TZTCODD_ORIGEN IN ('C1','C2')
                                                                            And TZTCODD_PIDM = p_pidm
                                                                                )
                             AND (--Para quitar blancos y ceros en cargos y pagos
                                   (CASE
                                     WHEN TBBDETC_TYPE_IND = 'C' THEN TBRACCD_AMOUNT
                                     WHEN TBBDETC_TYPE_IND = 'P' THEN NULL
                                  END) IS NOT NULL
                                  OR
                                  (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN NULL
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN TBRACCD_AMOUNT
                                  END) IS NOT NULL
                                    )
                             --Para Quitar los cargos negativos que se matan asi  mismos
                             AND TBRACCD_TRAN_NUMBER NOT IN(
                                     (SELECT TBRACCD_TRAN_NUMBER
                                        FROM TBRACCD, TBBDETC
                                        WHERE     TBRACCD_PIDM = p_pidm
                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        AND TBBDETC_TYPE_IND = 'C'
                                        AND TBRACCD_AMOUNT < 0
                                        UNION
                                        SELECT TBRAPPL_CHG_TRAN_NUMBER
                                        FROM TBRAPPL,TBRACCD
                                        WHERE TBRACCD_PIDM = p_pidm
                                        AND TBRAPPL_PIDM= TBRACCD_PIDM
                                        AND TBRAPPL_REAPPL_IND IS NULL
                                        AND TBRAPPL_PAY_TRAN_NUMBER IN (
                                                                        SELECT TBRACCD_TRAN_NUMBER
                                                                        FROM TBRACCD, TBBDETC
                                                                        WHERE     TBRACCD_PIDM = p_pidm
                                                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                                                        AND TBBDETC_TYPE_IND = 'C'
                                                                        AND TBRACCD_AMOUNT < 0
                                                                        )
                                        UNION
                                        SELECT NVL(TBRACCD_TRAN_NUMBER_PAID,0)
                                        FROM TBRACCD, TBBDETC
                                        WHERE     TBRACCD_PIDM = p_pidm
                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        AND TBBDETC_TYPE_IND = 'C'
                                        AND TBRACCD_AMOUNT < 0
                                         )
                                        UNION --Excluye Tanto categoria como Detalle configurados en Param (Si existe detalle, no toma la Categoria)
                                        --En cancelaciones definidas en Param y que se requiere que no se muestre la transaccion pagada que cubrio
                                        (SELECT TBRACCD_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = p_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_PAY_TRAN_NUMBER= TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE FROM TZTCODD 
                                                                                WHERE TZTCODD_ORIGEN IN ('C3','C4')
                                                                                And TZTCODD_PIDM = p_pidm
                                                                                 )
                                        UNION
                                         SELECT TBRAPPL_CHG_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = p_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_PAY_TRAN_NUMBER= TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE 
                                                                                FROM TZTCODD 
                                                                                WHERE TZTCODD_ORIGEN IN ('C3','C4')
                                                                                And TZTCODD_PIDM = p_pidm
                                                                                 )
                                        UNION
                                         SELECT TBRAPPL_PAY_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = p_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_CHG_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE 
                                                                                FROM TZTCODD 
                                                                                WHERE TZTCODD_ORIGEN IN ('C3','C4')
                                                                                And TZTCODD_PIDM = p_pidm
                                                                                 )
                                          )
                                          )
                    ORDER BY TRUNC (TBRACCD_TRANS_DATE) desc

                    -- OMS 15/Febrero/2024 (Se agrega el Nombre del Programa, de acuerdo al Study-Path
                    ) z, -- tztprog x

                    -- PARCHE 21/Nov/2024 OMS
                    -- Evita que se duplique el concepto, cuando exista inconsistencia en TZTPROG 
                    -- porque tiene mismo numero de "Study-Path" para diferente programa
                    (SELECT *
                       FROM tztprog x2
                      WHERE x2.pidm    = p_pidm
                        AND x2.estatus = 'MA'
                        AND ( x2.pidm, x2.sp, x2.programa ) IN (SELECT x3.pidm, x3.sp, MAX (x3.programa) Programa
                                                                  FROM tztprog x3
                                                                 WHERE x3.pidm    = x2.pidm
                                                                   AND x3.estatus = 'MA'
                                                                 GROUP BY x3.pidm, x3.sp
                                                               )
                     ) x
                    
                WHERE x.pidm (+) = z.tbraccd_pidm
                  AND x.sp   (+) = z.Study_Path
                   order by z.fECHA_CARGO desc;

                        RETURN (desc_edocta);
               Exception when others then
                       v_error:='No se encontraron registros'||sqlerrm;
                       open desc_edocta for select null, null, null, null, null, null, null, null, null, null, null,null,NULL,null,null, v_error, null, null, null, null from dual;
                                RETURN (desc_edocta);

               End f_dashboard_edo_cta;



PROCEDURE P_dashboard_detail_code(ppidm in number, p_id varchar2) as 

    EXISTE NUMBER;
    

    cursor c1 is
    select DISTINCT x1.TBBDETC_DCAT_CODE, x1.TBBDETC_DETAIL_CODE
    from tbbdetc x1
    where  x1.TBBDETC_DETAIL_CODE  in   (  SELECT ZSTPARA_PARAM_VALOR
                                                                 FROM ZSTPARA WHERE ZSTPARA_MAPA_ID= 'COD_EDO_CTA'
                                                                 and ZSTPARA_PARAM_ID='DETAIL_CODE'); 

    cursor c2 is
    select  distinct x1.TBBDETC_DCAT_CODE, X1.TBBDETC_DETAIL_CODE --971
    from tbbdetc x1
    where x1.TBBDETC_DCAT_CODE in ( SELECT ZSTPARA_PARAM_VALOR
                                                            FROM ZSTPARA WHERE ZSTPARA_MAPA_ID= 'COD_EDO_CTA'
                                                            and ZSTPARA_PARAM_ID='DCAT_CODE')
    and substr (x1.TBBDETC_DETAIL_CODE,1,2)  = p_id ;

    cursor c3 is
    select DISTINCT x1.TBBDETC_DCAT_CODE, x1.TBBDETC_DETAIL_CODE
    from tbbdetc x1
    where  x1.TBBDETC_DETAIL_CODE  in   (  SELECT ZSTPARA_PARAM_VALOR
                                                                 FROM ZSTPARA WHERE ZSTPARA_MAPA_ID= 'COD_EDO_CTA'
                                                                 and ZSTPARA_PARAM_ID='DETAIL_CODE2') 
    and substr (x1.TBBDETC_DETAIL_CODE,1,2)  = p_id ;                                                                 

    cursor c4 is
    select  distinct x1.TBBDETC_DCAT_CODE, X1.TBBDETC_DETAIL_CODE --971
    from tbbdetc x1
    where x1.TBBDETC_DCAT_CODE in ( SELECT ZSTPARA_PARAM_VALOR
                                                            FROM ZSTPARA WHERE ZSTPARA_MAPA_ID= 'COD_EDO_CTA'
                                                            and ZSTPARA_PARAM_ID='DCAT_CODE') 
    and substr (x1.TBBDETC_DETAIL_CODE,1,2)  = p_id ;                                                            

begin

       DELETE TZTCODD
       Where TZTCODD_pidm = ppidm;
       Commit;
       
        DELETE TZTCODD
       Where TZTCODD_pidm is null;
       Commit;

       for z in c1 loop
                insert into TZTCODD (TZTCODD_DETAIL_CODE, TZTCODD_DCAT_CODE,TZTCODD_ORIGEN, TZTCODD_PIDM)
                             values    ( z.TBBDETC_DETAIL_CODE,z.TBBDETC_DCAT_CODE, 'C1', ppidm);
                Commit;
       end loop;

       for y in c2 loop

           select  COUNT(*)
           INTO EXISTE
           from TZTCODD
           WHERE  TZTCODD_DCAT_CODE = Y.TBBDETC_DCAT_CODE
           AND TZTCODD_ORIGEN= 'C1'
           And TZTCODD_PIDM = ppidm;

           IF EXISTE > 0 THEN
              CONTINUE;
           ELSE
              insert into TZTCODD (TZTCODD_DETAIL_CODE, TZTCODD_DCAT_CODE,TZTCODD_ORIGEN, TZTCODD_PIDM)
                             values    ( y.TBBDETC_DETAIL_CODE,y.TBBDETC_DCAT_CODE, 'C2', ppidm);
              Commit;

           END IF;

       end loop;

       for z in c3 loop
                insert into TZTCODD (TZTCODD_DETAIL_CODE, TZTCODD_DCAT_CODE,TZTCODD_ORIGEN, TZTCODD_PIDM)
                             values    ( z.TBBDETC_DETAIL_CODE,z.TBBDETC_DCAT_CODE, 'C3', ppidm);
                Commit;
       end loop;


       for y in c4 loop

           select  COUNT(*)
           INTO EXISTE
           from TZTCODD
           WHERE  TZTCODD_DCAT_CODE = Y.TBBDETC_DCAT_CODE
           AND TZTCODD_ORIGEN= 'C3' 
           And TZTCODD_PIDM = ppidm;

           IF EXISTE > 0 THEN
              CONTINUE;
           ELSE
              insert into TZTCODD (TZTCODD_DETAIL_CODE, TZTCODD_DCAT_CODE,TZTCODD_ORIGEN, TZTCODD_PIDM)
                             values    ( y.TBBDETC_DETAIL_CODE,y.TBBDETC_DCAT_CODE, 'C4', ppidm);

            Commit;
           END IF;

       end loop;

       commit;

END P_dashboard_detail_code;
  
  
  ---SALO AL DIA Y SALDO TOTAL
   FUNCTION F_SALDOS (P_PIDM NUMBER)
      RETURN PKG_EDO_CTA.SDT_OUT
   AS
      SALDOS_OUT    PKG_EDO_CTA.SDT_OUT;
      
      v_error        VARCHAR2 (4000);

    Begin

      OPEN SALDOS_OUT FOR
SELECT SUM(SALDO_DIA) SALDO_DIA, SUM(SALDO_TOTAL) SALDO_TOTAL FROM (
  select sum(nvl (tbraccd_balance, 0)) SALDO_DIA, 0 SALDO_TOTAL
          --  Into vl_monto
            from tbraccd, TBBDETC
            Where tbraccd_pidm = p_pidm
           And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
--            And TBBDETC_TYPE_IND = 'C'
            And TRUNC(TBRACCD_EFFECTIVE_DATE) <= trunc(sysdate)
            UNION 
    select 0 SALDO_DIA, sum(nvl (tbraccd_balance, 0)) SALDO_TOTAL
          --  Into vl_monto
            from tbraccd
            Where tbraccd_pidm =  p_pidm);

          RETURN (SALDOS_OUT);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_error := 'No se encontraron registros' || SQLERRM;
         OPEN SALDOS_OUT FOR SELECT NULL, NULL || v_error FROM DUAL;
         RETURN (SALDOS_OUT);

  END F_SALDOS;
  

FUNCTION f_obt_fecha_limite_rate (p_matricula IN VARCHAR2) RETURN DATE IS
-- DESCRIPCION: Obtiene la fecha limite para el pago; dependiendo del RATE A,B,C
-- AUTOR......: Omar L. Meza Sol
-- FECHA......: 08/Nov/2024

-- Variable
   Vm_Fecha DATE := sysdate; -- Fecha de salida
   
BEGIN
   -- Localiza el RATE en la tabla SORLCUR
   SELECT CASE WHEN Rate = 'A' THEN TO_DATE ('15/' || TO_CHAR (sysdate, 'MM/YYYY'), 'DD/MM/YYYY')
            WHEN Rate = 'C' THEN TO_DATE ('10/' || TO_CHAR (sysdate, 'MM/YYYY'), 'DD/MM/YYYY')
            WHEN Rate = 'B'  AND TO_CHAR (sysdate, 'MM')  = '02' THEN LAST_DAY (sysdate)
            WHEN Rate = 'B'  AND TO_CHAR (sysdate, 'MM') != '02' THEN TO_DATE ('30/' || TO_CHAR (sysdate, 'MM/YYYY'), 'DD/MM/YYYY')
            ELSE TRUNC (sysdate)
        END Fecha_Limite 
  INTO Vm_Fecha
  FROM (SELECT DISTINCT SUBSTR (sorlcur_rate_code,4,1) Rate
          FROM sorlcur a
         WHERE 1 = 1 
           AND sorlcur_pidm = fget_pidm (p_matricula)
           AND sorlcur_rate_code IS NOT NULL
           AND rownum <= 1
       );

   RETURN Vm_Fecha;
  
EXCEPTION
  WHEN OTHERS THEN RETURN TRUNC (sysdate);
END f_obt_fecha_limite_rate;


-- OMS 25/Abril/2024: Estado de cuenta envio masivo por correo
FUNCTION f_masiva_edo_cta_resumen (pe_pidm     IN NUMBER,                   -- ENTRADA: Identificador del Alumno
                                   pe_programa IN VARCHAR2    DEFAULT NULL, -- ENTRADA: Programa relacionado al Study-Path
                                   pe_Rate     IN VARCHAR2    DEFAULT NULL, -- ENTRADA: A=15, B=10, C=30   Dia de Corte
                                   pe_Punto_dePartida IN DATE DEFAULT NULL, -- ENTRADA: Fecha de partida; NULL, TO_DATE (Fecha, 'Formato'), Sysdate
                                   pe_version         IN NUMBER DEFAULT 0   -- 2=Resumen Total
       ) RETURN SYS_REFCURSOR IS


-- DESCRIPCION: Estado de cuenta mensual para envio masivo por correo (RESUMEN)
-- AUTOR......: Omar L. Meza Sol
-- FECHA......: 25/Abril/2024


   -- Variables Locales
-- Variable del Bloque Anonimo
   Vm_Bandera         VARCHAR2 (500) := NULL;    -- Salida del Proceso COMPLEMENTO DE COLEGIATURA

   Vm_Inicio          DATE           := NULL;    -- Inicio del Periodo
   Vm_Fin             DATE           := NULL;    -- Fin    del Periodo
   Vm_Moneda          VARCHAR2 (20)  := NULL;    -- Moneda, MXN=Pesos Mexicanos, Etc.
   Vm_Depositos       NUMBER (15,2)  := 0;       -- N mero de Depositos Realizados
   Vm_Cargos          NUMBER (15,2)  := 0;       -- N mero de Cargos Aplicados
   Vm_Cargos_Periodo  NUMBER (5)     := 0;       -- Cargos dentro del periodo
   Vm_Dias_Tolerancia NUMBER (5)     := 0;       -- Dias de Tolerancia para el pago
   Vm_Saldo_Final     NUMBER (15,2)  := 0;       -- Saldo Final
   Vm_Saldo_ANTERIOR  NUMBER (15,2)  := 0;       -- Saldo ANTERIOR
   Vm_Inicio_Anterior DATE           := NULL;    -- Inicio del Periodo ANTERIOR
   Vm_Fin_Anterior    DATE           := NULL;    -- Fin    del Periodo ANTERIOR

   Vm_Saldo_Dia       TBRACCD.tbraccd_balance%TYPE;
   Vm_Saldo_Total     TBRACCD.tbraccd_balance%TYPE;


   p_pidm            NUMBER         := pe_pidm;            -- ENTRADA: pidm del Alumno
   p_Rate            VARCHAR2 ( 1)  := pe_rate;            -- ENTRADA: RATE (Dia de corte)
   p_programa        VARCHAR2 (50)  := pe_programa;        -- ENTRADA: Programa relacionado al Study-Path
   p_Punto_dePartida DATE           := pe_Punto_dePartida; -- ENTRADA: Fecha de Punto de Partida
   p_periodo         VARCHAR2 (100) := NULL;               -- SALIDA.: Descripci n del Periodo en Cuestion
   p_Fecha_limite    DATE           := NULL;               -- SALIDA.: Fecha Limite para el pago

   Vm_Registros      SYS_REFCURSOR;	                       -- Registros recuperados en la consulta

-- Bloque Anonimo
BEGIN

   -- Validaci n de parametros
   IF p_rate     IS NULL THEN NULL; END IF;
   IF p_programa IS NULL THEN NULL; END IF;
   IF p_Punto_dePartida IS NULL THEN p_Punto_dePartida := sysdate; END IF;



   -- DBMS_OUTPUT.PUT_LINE ('Resumen Estado de Cuenta:' || CHR(10));
   -- DBMS_OUTPUT.PUT_LINE ('Punto de Partida:     ' || TO_CHAR (p_Punto_dePartida, 'DD-MM-YYYY'));
   -- DBMS_OUTPUT.PUT_LINE ('Rate (Entrada)        ' || p_Rate);

   -- Calcula la Fecha Final del periodo
   IF p_rate IN ('A', 'C') THEN
      SELECT TO_DATE (DECODE (p_Rate, 'A', '15', 'B', '30', 'C', '10', '01') || TO_CHAR (p_Punto_dePartida, 'MMYYYY'), 'DDMMYYYY')
        INTO Vm_Fin
        FROM dual;

   -- Caso contrario: Fin de MES
   ELSE
      SELECT LAST_DAY (p_Punto_dePartida)
        INTO Vm_Fin
        FROM dual;
   END IF;


   SELECT ADD_MONTHS (Vm_Fin, -1) + 1
     INTO Vm_Inicio
     FROM dual;

   -- En caso de que sea RESUMEN TOTAL
   IF pe_version = 2 THEN
      BEGIN
         SELECT MIN (tbraccd_effective_date) Minima, MAX (tbraccd_effective_date) Maxima
           INTO Vm_Inicio, Vm_Fin
           FROM tbraccd a
          WHERE TBRACCD_PIDM    = p_pidm
         -- AND TBRACCD_BALANCE > 0
              ;

      EXCEPTION
         WHEN OTHERS THEN
              Vm_Inicio := TO_DATE ('01/01/1900', 'DD/MM/YYYY');
              Vm_Fin    := sysdate;
      END;

   END IF;

   p_periodo := TO_CHAR (Vm_Inicio, 'DD-MM-YYYY') || ' al ' || TO_CHAR (Vm_Fin, 'DD-MM-YYYY');


   -- Obtiene los dias de tolerancia para el pago
   /* Versión Anterior
   BEGIN
      SELECT MAX (c.ZSTPARA_PARAM_VALOR) Vm_Dias_Tolerancia
        INTO Vm_Dias_Tolerancia
        FROM TBRACCD a, TBBDETC b, ZSTPARA c
       WHERE TBRACCD_PIDM    = p_pidm
--       AND TBRACCD_BALANCE > 0
         AND TRUNC (TBRACCD_EFFECTIVE_DATE) >= TRUNC (Vm_Inicio)
         AND TRUNC (TBRACCD_EFFECTIVE_DATE) <  TRUNC (Vm_Fin)
         AND TBBDETC_DETAIL_CODE    =  TBRACCD_DETAIL_CODE 
         AND ZSTPARA_MAPA_ID        = 'INTERESES' 
         AND ZSTPARA_PARAM_ID       = 'NUM_DIAS'
         AND ZSTPARA_PARAM_DESC LIKE '%' || TBBDETC_DCAT_CODE || '%';

   EXCEPTION
     WHEN OTHERS THEN Vm_Dias_Tolerancia := 0;
   END;
   */

   -- 08/Nov/2024 REDEFINE LA FECHA LIMITE
   Vm_Dias_Tolerancia := 0;
   IF    p_rate = 'A' THEN p_Fecha_limite := TO_DATE ('15/' || TO_CHAR (Vm_Fin, 'MM/YYYY'), 'DD/MM/YYYY') ;
   ELSIF p_rate = 'B' THEN 
         IF TO_CHAR (Vm_Fin, 'MM') = '02' 
            THEN p_Fecha_limite := LAST_DAY (Vm_Fin);
            ELSE p_Fecha_limite := TO_DATE ('30/' || TO_CHAR (Vm_Fin, 'MM/YYYY'), 'DD/MM/YYYY') ;
         END IF;
   ELSIF p_rate = 'C' THEN p_Fecha_limite := TO_DATE ('10/' || TO_CHAR (Vm_Fin, 'MM/YYYY'), 'DD/MM/YYYY') ;
   END IF;

   -- p_Fecha_limite := Vm_Fin + NVL (Vm_Dias_Tolerancia,0); 
   -- IF TO_CHAR (p_Fecha_limite, 'DD') = '31' THEN p_Fecha_limite := p_Fecha_limite -1; END IF;
   
   -- Periodo ANTERIOR
   Vm_Inicio_Anterior := ADD_MONTHS (Vm_Inicio, -1);    -- Inicio del Periodo ANTERIOR
   Vm_Fin_Anterior    := Vm_Inicio - 1;                 -- Fin    del Periodo ANTERIOR


   -- Cuenta cuantos DEPOSITOS y CARGOS se han realizado con la moneda correspondiente.
   BEGIN
      SELECT SUM (Suma_Abonos) Depositos,           -- Version 002 --> Suma de Depositos
             SUM (Suma_Cargos) Cargos,              -- Versi n 002 --> Suma de Cargos
--           SUM (PAGOS_PERIODO)   Depositos,       -- Version Anterior CONTADOR DE REGISTROS
--           SUM (CARGOS_PERIODO)  Cargos,          -- Version Anterior CONTADOR DE REGISTROS
             MAX (Moneda)          Moneda,
             SUM (Suma_Cargos)  -  SUM (Suma_Abonos) Saldo_Final
        INTO Vm_Depositos, Vm_Cargos, Vm_Moneda, Vm_Saldo_Final
        FROM (SELECT tbraccd_pidm, NVL (COUNT (TBRACCD_AMOUNT), 0) CARGOS_PERIODO, 0 PAGOS_PERIODO, 0 BALANCE_PERIODO, 
                     MAX (tbraccd_curr_code) MONEDA, SUM (tbraccd_amount) Suma_Cargos, 0 Suma_Abonos
                FROM tbraccd
                JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('VENTA', 'INTERES', 
                                                                                                  'NOTA DEBITO', 'NOTA CXC', 'ANTICIPO',
                                                                                                  'OTROS INGRESOS', 'FINANCIERAS')
                            AND TBBDETC_TYPE_IND IN ('C')
               WHERE TBRACCD_PIDM = p_pidm
                 AND NVL (TBRACCD_AMOUNT,0) != 0
                 AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN Vm_Inicio AND Vm_FIn
               GROUP BY tbraccd_pidm
               UNION
              SELECT tbraccd_pidm, 0 Cargos_Periodo, NVL (COUNT (TBRACCD_AMOUNT), 0) PAGOS_PERIODO, 0 BALANCE_PERIODO, 
                     MAX (tbraccd_curr_code) MONEDA, 0 Suma_Cargos, SUM (tbraccd_amount)  Suma_Abonos
                FROM tbraccd
                JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('POLIZA', 'DEPOSITO', 'NOTA DISTRIBUCION',
                                                                                                  'NOTA CREDITO', 'INTERES', 'FINANCIERAS',
                                                                                                  'INCOBRABLE') -- 
                            AND TBBDETC_TYPE_IND IN ('P')
               WHERE TBRACCD_PIDM = p_pidm
                 AND NVL (TBRACCD_AMOUNT,0) != 0
                 AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN Vm_Inicio AND Vm_Fin
               GROUP BY tbraccd_pidm
                   );

   EXCEPTION
      WHEN OTHERS THEN 
           Vm_Moneda         := NULL;
           Vm_Depositos      := 0;
           Vm_Cargos         := 0;
           Vm_Saldo_Final    := 0;

   END;
   IF Vm_Cargos < 0 THEN Vm_Cargos := 0; END IF;


   -- Re-asigna la moneda VERSION 002
   BEGIN
      SELECT DISTINCT zstpara_param_valor
        INTO Vm_Moneda
        FROM spriden b, zstpara a
       WHERE spriden_pidm       = p_pidm
         AND spriden_change_Ind IS NULL
         AND zstpara_mapa_Id    = 'CAMP_URL_MONEDA'
         AND zstpara_param_id   = SUBSTR (spriden_Id,1,2);

   EXCEPTION
      WHEN OTHERS THEN Vm_Moneda := NULL; -- 'XXX';

   END;


   -- Calculos del periodo ANTERIOR
   BEGIN
      SELECT SUM (Suma_Cargos) -  SUM (Suma_Abonos) Saldo_Final
        INTO Vm_Saldo_ANTERIOR
        FROM (SELECT tbraccd_pidm, NVL (COUNT (TBRACCD_AMOUNT), 0) CARGOS_PERIODO, 0 PAGOS_PERIODO, 0 BALANCE_PERIODO, 
                     MAX (tbraccd_curr_code) MONEDA, SUM (tbraccd_balance) Suma_Cargos, 0 Suma_Abonos    -- 15/Nov/2024 SUM (tbraccd_amount)
                FROM tbraccd
                JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('VENTA', 'INTERES', 'NOTA DEBITO', 'NOTA CXC', 'ANTICIPO',
                                                                                                  'OTROS INGRESOS', 'FINANCIERAS')
                            AND TBBDETC_TYPE_IND IN ('C')
               WHERE TBRACCD_PIDM = p_pidm
                 AND NVL (TBRACCD_AMOUNT,0) != 0
                 AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN TO_DATE ('01/01/2000', 'DD/MM/YYYY')    -- Version 002 --> Todo el Saldo Anterior
                                                     -- AND Vm_Inicio_ANTERIOR                      -- Version Anterior 
                                                        AND Vm_FIn_ANTERIOR
               GROUP BY tbraccd_pidm
               UNION
              SELECT tbraccd_pidm, 0 Cargos_Periodo, NVL (COUNT (TBRACCD_AMOUNT), 0) PAGOS_PERIODO, 0 BALANCE_PERIODO, 
                     MAX (tbraccd_curr_code) MONEDA, 0 Suma_Cargos, SUM (tbraccd_balance)  Suma_Abonos   -- 15/Nov/2024 SUM (tbraccd_amount)
                FROM tbraccd
                JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('POLIZA', 'DEPOSITO', 'NOTA DISTRIBUCION',
                                                                                                  'NOTA CREDITO', 'INTERES', 'FINANCIERAS',
                                                                                                  'INCOBRABLE') -- 
                            AND TBBDETC_TYPE_IND IN ('P')
               WHERE TBRACCD_PIDM = p_pidm
                 AND NVL (TBRACCD_AMOUNT,0) != 0
                 AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN TO_DATE ('01/01/2000', 'DD/MM/YYYY')    -- Version 002 --> Todo el Saldo Anterior
                                                     -- AND Vm_Inicio_ANTERIOR                      -- Version Anterior
                                                        AND Vm_Fin_ANTERIOR
               GROUP BY tbraccd_pidm
                   );

   EXCEPTION
      WHEN OTHERS THEN 
           Vm_Saldo_ANTERIOR := 0;
   END;
   Vm_Saldo_Anterior := NVL (Vm_Saldo_Anterior, 0);


-- DBMS_OUTPUT.PUT_LINE (CHR(10));
/* 
   DBMS_OUTPUT.PUT_LINE ('PERIODO ANTERIOR:     ' || TO_CHAR (Vm_Inicio_Anterior, 'DD-MM-YYYY') || ' al ' 
                                                  || TO_CHAR (Vm_Fin_Anterior,    'DD-MM-YYYY') );

   DBMS_OUTPUT.PUT_LINE ('Saldo ANTERIOR:       ' || TO_CHAR (Vm_Saldo_Anterior, 'FM99999999999999990.00')
                                                  || ' ' || Vm_Moneda || CHR(10));

   DBMS_OUTPUT.PUT_LINE ('Depositos:            ' || Vm_Depositos);
   DBMS_OUTPUT.PUT_LINE ('Cargos:               ' || Vm_Cargos);
   DBMS_OUTPUT.PUT_LINE ('Saldo_Final:          ' || TO_CHAR (Vm_Saldo_Final, 'FM99999999999999990.00') 
                                                  || ' ' || Vm_Moneda || CHR(10));

   DBMS_OUTPUT.PUT_LINE ('Periodo:              ' || p_Periodo);
   DBMS_OUTPUT.PUT_LINE ('Fecha de Corte:       ' || TO_CHAR (Vm_Fin, 'DD-MM-YYYY'));
   DBMS_OUTPUT.PUT_LINE ('Fecha Limite de Pago: ' || TO_CHAR (p_Fecha_Limite, 'DD-MM-YYYY'));
*/

   -- Calcula los saldos al dia y saldo total
   BEGIN

      -- Saldo al d a
      Vm_Saldo_Dia := 0;
      SELECT SUM (NVL (tbraccd_balance, 0)) SALDO_DIA
        INTO Vm_Saldo_Dia
        FROM tbraccd, TBBDETC
       WHERE tbraccd_pidm        = p_pidm
         AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
      -- AND TBBDETC_TYPE_IND    = 'C'
         AND TRUNC(TBRACCD_EFFECTIVE_DATE) <=  DECODE (pe_version, 2, sysdate, TRUNC (Vm_Fin)); -- TRUNC (sysdate);

      -- Saldo TOTAL
      Vm_Saldo_TOTAL := 0;
      SELECT SUM (NVL (tbraccd_balance, 0)) SALDO_TOTAL
        INTO Vm_Saldo_TOTAL
        FROM tbraccd
       WHERE tbraccd_pidm = p_pidm;

   EXCEPTION
     WHEN OTHERS THEN
          Vm_Saldo_Dia   := 0;
          Vm_Saldo_TOTAL := 0;

   END;


   -- Regresa el CURSOR de Informaci n
   Vm_Bandera := SQLERRM;
   OPEN Vm_Registros FOR 
        SELECT TO_CHAR (Vm_Inicio_Anterior, 'DD-MM-YYYY') || ' al ' || TO_CHAR (Vm_Fin_Anterior,    'DD-MM-YYYY')  Periodo_Anterior, 
               NVL (Vm_Saldo_Anterior,0) Saldo_Anterior, 
               NVL (Vm_Moneda, '') Moneda,  -- 'MONEDA'
               NVL (Vm_Depositos,0) Depositos, 
               NVL (Vm_Cargos,0) Cargos, 
               Vm_Saldo_Dia Saldo_Final,
               p_Periodo Periodo_Actual, 
               p_Fecha_limite Fecha_Corte, Vm_Bandera Msj_Error,
               Vm_Saldo_Final Saldo_del_periodo
               -- NVL (Vm_Saldo_Total,0) Saldo_Total 
               -- p_Fecha_Limite Fecha_Limite,  
          FROM DUAL;

   RETURN Vm_Registros;

END f_masiva_edo_cta_resumen;



FUNCTION f_masiva_edo_cta_detalle (pe_pidm       IN NUMBER, -- Identificador del Alumno
                                   pe_study_path IN NUMBER, -- Study-Path
                                   pe_Inicio     IN DATE,   -- Fecha de Inicio del Periodo
                                   pe_Fin        IN DATE    --Fecha de Fin del Periodo
       ) RETURN SYS_REFCURSOR IS

-- DESCRIPCION: Estado de cuenta mensual para envio masivo por correo (DETALLE)
-- AUTOR......: Omar L. Meza Sol
-- FECHA......: 25/Abril/2024

   -- Variables
   Vm_Registros      SYS_REFCURSOR;	                       -- Registros recuperados en la consulta


BEGIN

   OPEN Vm_Registros FOR 
         SELECT PIDM, 0 Study_Path, Codigo, Descripcion, Fecha,
             -- PIDM, Study_Path, Codigo, Descripcion, Fecha,
             -- tbraccd_tran_number,
                SUM (Suma_Cargos) Cargos, SUM (Suma_Abonos) Abonos,
                SUM (Suma_Cargos - Suma_Abonos) Cargos_menos_abonos,
                SUM (Balance) Balance
           FROM (-- Cargos
                 SELECT tbraccd_pidm PIDM, 0 Study_Path, TRUNC (tbraccd_effective_date) Fecha,
                     -- tbraccd_pidm PIDM, tbraccd_stsp_key_sequence Study_Path, TRUNC (tbraccd_effective_date) Fecha, 
                        tbraccd_detail_code Codigo, NVL (TZTEDTC_DESC_NE, tbraccd_desc || '.') Descripcion,
                        tbraccd_tran_number,
                        SUM (tbraccd_amount) Suma_Cargos, 0 Suma_Abonos , SUM (tbraccd_balance) Balance
                   FROM tbraccd

                   LEFT JOIN TZTEDTC ON TZTEDTC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                        JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                        JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('VENTA', 'INTERES', 
                                                                                                          'NOTA DEBITO', 'NOTA CXC', 'ANTICIPO',
                                                                                                          'OTROS INGRESOS', 'FINANCIERAS')
                                    AND TBBDETC_TYPE_IND IN ('C')
                  WHERE TBRACCD_PIDM = pe_pidm
                    AND NVL (TBRACCD_AMOUNT,0) != 0
                    AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN pe_Inicio AND pe_FIn
               --   AND tbraccd_stsp_key_sequence = pe_study_path
               -- GROUP BY tbraccd_pidm, tbraccd_stsp_key_sequence, TRUNC (tbraccd_effective_date), tbraccd_detail_code, tbraccd_desc
                  GROUP BY tbraccd_pidm, 0, TRUNC (tbraccd_effective_date), tbraccd_detail_code, 
                           NVL (TZTEDTC_DESC_NE, tbraccd_desc || '.'), tbraccd_tran_number

                  UNION ALL

                 -- Abonos
                 SELECT tbraccd_pidm PIDM, 0 Study_Path, TRUNC (tbraccd_effective_date) Fecha,
                     -- tbraccd_pidm PIDM, tbraccd_stsp_key_sequence Study_Path, TRUNC (tbraccd_effective_date) Fecha,
                        tbraccd_detail_code Codigo, NVL (TZTEDTC_DESC_NE, tbraccd_desc || '.') Descripcion,
                        tbraccd_tran_number,
                        0 Suma_Cargos, SUM (tbraccd_amount) Suma_Abonos, SUM (tbraccd_balance) Balance
                   FROM tbraccd

                   LEFT JOIN TZTEDTC ON TZTEDTC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                        JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                        JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('POLIZA', 'DEPOSITO', 'NOTA DISTRIBUCION',
                                                                                                          'NOTA CREDITO', 'INTERES', 'FINANCIERAS',
                                                                                                          'INCOBRABLE') -- 
                                    AND TBBDETC_TYPE_IND IN ('P')
                  WHERE TBRACCD_PIDM = pe_pidm
                    AND NVL (TBRACCD_AMOUNT,0) != 0
                    AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN pe_Inicio AND pe_Fin
               --   AND tbraccd_stsp_key_sequence = pe_study_path
               -- GROUP BY tbraccd_pidm, tbraccd_stsp_key_sequence, TRUNC (tbraccd_effective_date), tbraccd_detail_code, tbraccd_desc
                  GROUP BY tbraccd_pidm, 0, TRUNC (tbraccd_effective_date), tbraccd_detail_code, 
                           NVL (TZTEDTC_DESC_NE, tbraccd_desc || '.'), tbraccd_tran_number
                )
--        GROUP BY PIDM,  Study_Path, Codigo, Descripcion, Fecha
          GROUP BY PIDM,  0, Codigo, Descripcion, Fecha, tbraccd_tran_number
          ORDER BY Fecha, tbraccd_tran_number;

    RETURN Vm_Registros;

END f_masiva_edo_cta_detalle;



FUNCTION f_masiva_edo_cta_universo (pe_rate IN VARCHAR2) RETURN SYS_REFCURSOR IS

-- DESCRIPCION: Recupera el universo de alumnos involucrados para el envio del estado de cuenta MASIVO
-- AUTOR......: Omar L. Meza Sol
-- FECHA......: 01/Nov/2024

   -- Variables
   Vm_Registros      SYS_REFCURSOR;	                       -- Registros recuperados en la consulta

BEGIN

   OPEN Vm_Registros FOR 
        SELECT DISTINCT PIDM, MATRICULA, PROGRAMA || '|' || NOMBRE Programa
            -- DISTINCT b.sorlcur_rate_code, PIDM, MATRICULA, ESTATUS, CAMPUS, NIVEL, PROGRAMA
          FROM zstpara c, tztprog a, sorlcur b
         WHERE c.zstpara_mapa_id = 'EMAIL_EDO_CTA'
           AND a.estatus = 'MA'
           AND a.campus  = c.zstpara_param_ID
           AND b.sorlcur_pidm      = a.pidm
           AND b.sorlcur_program   = a.programa
           AND b.sorlcur_lmod_code = 'LEARNER'
           AND SUBSTR (b.sorlcur_rate_code,4,1) = pe_rate
           
           -- Excluye alumnos que no DEBEN TENER CONOCIMIENTO del estado de cuenta
           AND a.pidm NOT IN (SELECT DISTINCT goradid_pidm
                                FROM goradid b
                               WHERE b.goradid_adid_code IN (SELECT zstpara_param_Id
                                                               FROM zstpara a
                                                              WHERE zstpara_mapa_Id = 'EXC_ENVIO_EMAIL'
                                                            )
                             )
           /*
           AND b.sorlcur_seqno = (SELECT MAX (c.sorlcur_seqno) 
                                    FROM sorlcur c
                                   WHERE c.sorlcur_pidm      = b.sorlcur_pidm
                                     AND c.sorlcur_program   = b.sorlcur_program
                                     AND c.sorlcur_lmod_code = b.sorlcur_lmod_code
                                     AND c.sorlcur_rate_code = b.sorlcur_rate_code) */
           ;
                                     
    RETURN Vm_Registros;

END f_masiva_edo_cta_universo;



-- OMS 01/Noviembre/2024: Estado de cuenta UNIFICADO --> envio masivo por correo
FUNCTION f_masiva_edo_cta_unificado (pe_pidm     IN NUMBER,                   -- ENTRADA: Identificador del Alumno
                                     pe_Rate     IN VARCHAR2    DEFAULT NULL, -- ENTRADA: A=15, B=10, C=30   Dia de Corte
                                     pe_Punto_dePartida IN DATE DEFAULT NULL, -- ENTRADA: Fecha de partida; NULL, TO_DATE (Fecha, 'Formato'), Sysdate
                                     pe_version         IN NUMBER DEFAULT 0   -- 2=Resumen Total
       ) RETURN SYS_REFCURSOR IS


-- DESCRIPCION: Estado de cuenta mensual para envio masivo por correo (RESUMEN)
-- AUTOR......: Omar L. Meza Sol
-- FECHA......: 25/Abril/2024


   -- Variables Locales
-- Variable del Bloque Anonimo
   Vm_Bandera         VARCHAR2 (500) := NULL;    -- Salida del Proceso COMPLEMENTO DE COLEGIATURA

   Vm_Inicio          DATE           := NULL;    -- Inicio del Periodo
   Vm_Fin             DATE           := NULL;    -- Fin    del Periodo
   Vm_Moneda          VARCHAR2 (20)  := NULL;    -- Moneda, MXN=Pesos Mexicanos, Etc.
   Vm_Depositos       NUMBER (15,2)  := 0;       -- N mero de Depositos Realizados
   Vm_Cargos          NUMBER (15,2)  := 0;       -- N mero de Cargos Aplicados
   Vm_Cargos_Periodo  NUMBER (5)     := 0;       -- Cargos dentro del periodo
   Vm_Dias_Tolerancia NUMBER (5)     := 0;       -- Dias de Tolerancia para el pago
   Vm_Saldo_Final     NUMBER (15,2)  := 0;       -- Saldo Final
   Vm_Saldo_ANTERIOR  NUMBER (15,2)  := 0;       -- Saldo ANTERIOR
   Vm_Inicio_Anterior DATE           := NULL;    -- Inicio del Periodo ANTERIOR
   Vm_Fin_Anterior    DATE           := NULL;    -- Fin    del Periodo ANTERIOR

   Vm_Saldo_Dia       TBRACCD.tbraccd_balance%TYPE;
   Vm_Saldo_Total     TBRACCD.tbraccd_balance%TYPE;


   p_pidm            NUMBER         := pe_pidm;            -- ENTRADA: pidm del Alumno
   p_Rate            VARCHAR2 ( 1)  := pe_rate;            -- ENTRADA: RATE (Dia de corte)
   p_Punto_dePartida DATE           := pe_Punto_dePartida; -- ENTRADA: Fecha de Punto de Partida
   p_periodo         VARCHAR2 (100) := NULL;               -- SALIDA.: Descripci n del Periodo en Cuestion
   p_Fecha_limite    DATE           := NULL;               -- SALIDA.: Fecha Limite para el pago

   Vm_Registros      SYS_REFCURSOR;	                       -- Registros recuperados en la consulta

-- Bloque Anonimo
BEGIN

   -- Validaci n de parametros
   IF p_rate     IS NULL THEN NULL; END IF;
   IF p_Punto_dePartida IS NULL THEN p_Punto_dePartida := sysdate; END IF;



   -- DBMS_OUTPUT.PUT_LINE ('Resumen Estado de Cuenta:' || CHR(10));
   -- DBMS_OUTPUT.PUT_LINE ('Punto de Partida:     ' || TO_CHAR (p_Punto_dePartida, 'DD-MM-YYYY'));
   -- DBMS_OUTPUT.PUT_LINE ('Rate (Entrada)        ' || p_Rate);

   -- Calcula la Fecha Final del periodo
   IF p_rate IN ('A', 'C') THEN
      SELECT TO_DATE (DECODE (p_Rate, 'A', '15', 'B', '30', 'C', '10', '01') || TO_CHAR (p_Punto_dePartida, 'MMYYYY'), 'DDMMYYYY')
        INTO Vm_Fin
        FROM dual;

   -- Caso contrario: Fin de MES
   ELSE
      SELECT LAST_DAY (p_Punto_dePartida)
        INTO Vm_Fin
        FROM dual;
   END IF;


   SELECT ADD_MONTHS (Vm_Fin, -1) + 1
     INTO Vm_Inicio
     FROM dual;

   -- En caso de que sea RESUMEN TOTAL
   IF pe_version = 2 THEN
      BEGIN
         SELECT MIN (tbraccd_effective_date) Minima, MAX (tbraccd_effective_date) Maxima
           INTO Vm_Inicio, Vm_Fin
           FROM tbraccd a
          WHERE TBRACCD_PIDM    = p_pidm
         -- AND TBRACCD_BALANCE > 0
              ;

      EXCEPTION
         WHEN OTHERS THEN
              Vm_Inicio := TO_DATE ('01/01/1900', 'DD/MM/YYYY');
              Vm_Fin    := sysdate;
      END;

   END IF;

   p_periodo := TO_CHAR (Vm_Inicio, 'DD-MM-YYYY') || ' al ' || TO_CHAR (Vm_Fin, 'DD-MM-YYYY');


   -- Obtiene los dias de tolerancia para el pago
   /* Versión Anterior
   BEGIN
      SELECT MAX (c.ZSTPARA_PARAM_VALOR) Vm_Dias_Tolerancia
        INTO Vm_Dias_Tolerancia
        FROM TBRACCD a, TBBDETC b, ZSTPARA c
       WHERE TBRACCD_PIDM    = p_pidm
--       AND TBRACCD_BALANCE > 0
         AND TRUNC (TBRACCD_EFFECTIVE_DATE) >= TRUNC (Vm_Inicio)
         AND TRUNC (TBRACCD_EFFECTIVE_DATE) <  TRUNC (Vm_Fin)
         AND TBBDETC_DETAIL_CODE    =  TBRACCD_DETAIL_CODE 
         AND ZSTPARA_MAPA_ID        = 'INTERESES' 
         AND ZSTPARA_PARAM_ID       = 'NUM_DIAS'
         AND ZSTPARA_PARAM_DESC LIKE '%' || TBBDETC_DCAT_CODE || '%';

   EXCEPTION
     WHEN OTHERS THEN Vm_Dias_Tolerancia := 0;
   END;
   */
   

   -- 08/Nov/2024 REDEFINE LA FECHA LIMITE
   Vm_Dias_Tolerancia := 0;
   IF    p_rate = 'A' THEN p_Fecha_limite := TO_DATE ('15/' || TO_CHAR (Vm_Fin, 'MM/YYYY'), 'DD/MM/YYYY') ;
   ELSIF p_rate = 'B' THEN 
         IF TO_CHAR (Vm_Fin, 'MM') = '02' 
            THEN p_Fecha_limite := LAST_DAY (Vm_Fin);
            ELSE p_Fecha_limite := TO_DATE ('30/' || TO_CHAR (Vm_Fin, 'MM/YYYY'), 'DD/MM/YYYY') ;
         END IF;
   ELSIF p_rate = 'C' THEN p_Fecha_limite := TO_DATE ('10/' || TO_CHAR (Vm_Fin, 'MM/YYYY'), 'DD/MM/YYYY') ;
   END IF;

   -- p_Fecha_limite := Vm_Fin + NVL (Vm_Dias_Tolerancia,0); 
   -- IF TO_CHAR (p_Fecha_limite, 'DD') = '31' THEN p_Fecha_limite := p_Fecha_limite -1; END IF;

   -- Periodo ANTERIOR
   Vm_Inicio_Anterior := ADD_MONTHS (Vm_Inicio, -1);    -- Inicio del Periodo ANTERIOR
   Vm_Fin_Anterior    := Vm_Inicio - 1;                 -- Fin    del Periodo ANTERIOR


   -- Cuenta cuantos DEPOSITOS y CARGOS se han realizado con la moneda correspondiente.
   BEGIN
      SELECT SUM (Suma_Abonos) Depositos,           -- Version 002 --> Suma de Depositos
             SUM (Suma_Cargos) Cargos,              -- Versi n 002 --> Suma de Cargos
--           SUM (PAGOS_PERIODO)   Depositos,       -- Version Anterior CONTADOR DE REGISTROS
--           SUM (CARGOS_PERIODO)  Cargos,          -- Version Anterior CONTADOR DE REGISTROS
             MAX (Moneda)          Moneda,
             SUM (Suma_Cargos)  -  SUM (Suma_Abonos) Saldo_Final
        INTO Vm_Depositos, Vm_Cargos, Vm_Moneda, Vm_Saldo_Final
        FROM (SELECT tbraccd_pidm, NVL (COUNT (TBRACCD_AMOUNT), 0) CARGOS_PERIODO, 0 PAGOS_PERIODO, 0 BALANCE_PERIODO, 
                     MAX (tbraccd_curr_code) MONEDA, SUM (tbraccd_amount) Suma_Cargos, 0 Suma_Abonos
                FROM tbraccd
                JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('VENTA', 'INTERES', 
                                                                                                  'NOTA DEBITO', 'NOTA CXC', 'ANTICIPO',
                                                                                                  'OTROS INGRESOS', 'FINANCIERAS')
                            AND TBBDETC_TYPE_IND IN ('C')
               WHERE TBRACCD_PIDM = p_pidm
                 AND NVL (TBRACCD_AMOUNT,0) != 0
                 AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN Vm_Inicio AND Vm_FIn
               GROUP BY tbraccd_pidm
               UNION
              SELECT tbraccd_pidm, 0 Cargos_Periodo, NVL (COUNT (TBRACCD_AMOUNT), 0) PAGOS_PERIODO, 0 BALANCE_PERIODO, 
                     MAX (tbraccd_curr_code) MONEDA, 0 Suma_Cargos, SUM (tbraccd_amount)  Suma_Abonos
                FROM tbraccd
                JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('POLIZA', 'DEPOSITO', 'NOTA DISTRIBUCION',
                                                                                                  'NOTA CREDITO', 'INTERES', 'FINANCIERAS',
                                                                                                  'INCOBRABLE') --
                            AND TBBDETC_TYPE_IND IN ('P')
               WHERE TBRACCD_PIDM = p_pidm
                 AND NVL (TBRACCD_AMOUNT,0) != 0
                 AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN Vm_Inicio AND Vm_Fin
               GROUP BY tbraccd_pidm
                   );

   EXCEPTION
      WHEN OTHERS THEN 
           Vm_Moneda         := NULL;
           Vm_Depositos      := 0;
           Vm_Cargos         := 0;
           Vm_Saldo_Final    := 0;

   END;
   IF Vm_Cargos < 0 THEN Vm_Cargos := 0; END IF;


   -- Re-asigna la moneda VERSION 002
   BEGIN
      SELECT DISTINCT zstpara_param_valor
        INTO Vm_Moneda
        FROM spriden b, zstpara a
       WHERE spriden_pidm       = p_pidm
         AND spriden_change_Ind IS NULL
         AND zstpara_mapa_Id    = 'CAMP_URL_MONEDA'
         AND zstpara_param_id   = SUBSTR (spriden_Id,1,2);

   EXCEPTION
      WHEN OTHERS THEN Vm_Moneda := NULL; -- 'XXX';

   END;


   -- Calculos del periodo ANTERIOR
   BEGIN
      SELECT SUM (Suma_Cargos) -  SUM (Suma_Abonos) Saldo_Final
        INTO Vm_Saldo_ANTERIOR
        FROM (SELECT tbraccd_pidm, NVL (COUNT (TBRACCD_AMOUNT), 0) CARGOS_PERIODO, 0 PAGOS_PERIODO, 0 BALANCE_PERIODO, 
                     MAX (tbraccd_curr_code) MONEDA, SUM (tbraccd_balance) Suma_Cargos, 0 Suma_Abonos    -- 15/Nov/2024 SUM (tbraccd_amount)
                FROM tbraccd
                JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('VENTA', 'INTERES', 'NOTA DEBITO', 'NOTA CXC', 'ANTICIPO',
                                                                                                  'OTROS INGRESOS', 'FINANCIERAS')
                            AND TBBDETC_TYPE_IND IN ('C')
               WHERE TBRACCD_PIDM = p_pidm
                 AND NVL (TBRACCD_AMOUNT,0) != 0
                 AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN TO_DATE ('01/01/2000', 'DD/MM/YYYY')    -- Version 002 --> Todo el Saldo Anterior
                                                     -- AND Vm_Inicio_ANTERIOR                      -- Version Anterior 
                                                        AND Vm_FIn_ANTERIOR
               GROUP BY tbraccd_pidm
               UNION
              SELECT tbraccd_pidm, 0 Cargos_Periodo, NVL (COUNT (TBRACCD_AMOUNT), 0) PAGOS_PERIODO, 0 BALANCE_PERIODO, 
                     MAX (tbraccd_curr_code) MONEDA, 0 Suma_Cargos, SUM (tbraccd_balance)  Suma_Abonos   -- 15/Nov/2024 SUM (tbraccd_amount)
                FROM tbraccd
                JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('POLIZA', 'DEPOSITO', 'NOTA DISTRIBUCION',
                                                                                                  'NOTA CREDITO', 'INTERES', 'FINANCIERAS',
                                                                                                  'INCOBRABLE') --
                            AND TBBDETC_TYPE_IND IN ('P')
               WHERE TBRACCD_PIDM = p_pidm
                 AND NVL (TBRACCD_AMOUNT,0) != 0
                 AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN TO_DATE ('01/01/2000', 'DD/MM/YYYY')    -- Version 002 --> Todo el Saldo Anterior
                                                     -- AND Vm_Inicio_ANTERIOR                      -- Version Anterior
                                                        AND Vm_Fin_ANTERIOR
               GROUP BY tbraccd_pidm
                   );

   EXCEPTION
      WHEN OTHERS THEN 
           Vm_Saldo_ANTERIOR := 0;
   END;
   Vm_Saldo_Anterior := NVL (Vm_Saldo_Anterior, 0);


-- DBMS_OUTPUT.PUT_LINE (CHR(10));
/* 
   DBMS_OUTPUT.PUT_LINE ('PERIODO ANTERIOR:     ' || TO_CHAR (Vm_Inicio_Anterior, 'DD-MM-YYYY') || ' al ' 
                                                  || TO_CHAR (Vm_Fin_Anterior,    'DD-MM-YYYY') );

   DBMS_OUTPUT.PUT_LINE ('Saldo ANTERIOR:       ' || TO_CHAR (Vm_Saldo_Anterior, 'FM99999999999999990.00')
                                                  || ' ' || Vm_Moneda || CHR(10));

   DBMS_OUTPUT.PUT_LINE ('Depositos:            ' || Vm_Depositos);
   DBMS_OUTPUT.PUT_LINE ('Cargos:               ' || Vm_Cargos);
   DBMS_OUTPUT.PUT_LINE ('Saldo_Final:          ' || TO_CHAR (Vm_Saldo_Final, 'FM99999999999999990.00') 
                                                  || ' ' || Vm_Moneda || CHR(10));

   DBMS_OUTPUT.PUT_LINE ('Periodo:              ' || p_Periodo);
   DBMS_OUTPUT.PUT_LINE ('Fecha de Corte:       ' || TO_CHAR (Vm_Fin, 'DD-MM-YYYY'));
   DBMS_OUTPUT.PUT_LINE ('Fecha Limite de Pago: ' || TO_CHAR (p_Fecha_Limite, 'DD-MM-YYYY'));
*/

   -- Calcula los saldos al dia y saldo total
   BEGIN

      -- Saldo al d a
      Vm_Saldo_Dia := 0;
      SELECT SUM (NVL (tbraccd_balance, 0)) SALDO_DIA
        INTO Vm_Saldo_Dia
        FROM tbraccd, TBBDETC
       WHERE tbraccd_pidm        = p_pidm
         AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
      -- AND TBBDETC_TYPE_IND    = 'C'
         AND TRUNC(TBRACCD_EFFECTIVE_DATE) <=  DECODE (pe_version, 2, sysdate, TRUNC (Vm_Fin)); -- TRUNC (sysdate);

      -- Saldo TOTAL
      Vm_Saldo_TOTAL := 0;
      SELECT SUM (NVL (tbraccd_balance, 0)) SALDO_TOTAL
        INTO Vm_Saldo_TOTAL
        FROM tbraccd
       WHERE tbraccd_pidm = p_pidm;

   EXCEPTION
     WHEN OTHERS THEN
          Vm_Saldo_Dia   := 0;
          Vm_Saldo_TOTAL := 0;

   END;


   -- Regresa el CURSOR de Informaci n
   Vm_Bandera := SQLERRM;
   OPEN Vm_Registros FOR 

        SELECT 'RESUMEN' Categoria,
               TO_CHAR (Vm_Inicio_Anterior, 'DD-MM-YYYY') || ' al ' || TO_CHAR (Vm_Fin_Anterior, 'DD-MM-YYYY') PeriodoAnterior_PIDM, 
               TO_CHAR (NVL (Vm_Saldo_Anterior,0)) SaldoAnterior_NOAPLICA, 
               TO_CHAR (NVL (Vm_Moneda, '')) Moneda_CODIGO, --  'MONEDA' 
               TO_CHAR (NVL (Vm_Depositos,0))      Depositos_DESCRIPCION, 
               TO_CHAR (NVL (Vm_Cargos,0))         Cargos_FECHA, 
               TO_CHAR (Vm_Saldo_Dia)              SaldoFinal_CARGOS,
               p_Periodo PeriodoActual_ABONOS, 
               TO_CHAR (p_Fecha_limite, 'DD/MM/YYYY') FechaCorte_CARGOSMENOSABONOS, 
               Vm_Bandera Msj_Error_BALANCE,
               TO_CHAR (Vm_Saldo_Final) Saldodelperiodo_TRANSACCION
               -- NVL (Vm_Saldo_Total,0) Saldo_Total 
               -- p_Fecha_Limite Fecha_Limite,  
          FROM DUAL

         UNION ALL

-- Detalle del estado de cuenta UNIFICADO
         SELECT 'DETALLE' Categoria, 
                TO_CHAR (PIDM) pidm, '0' Study_Path, Codigo, Descripcion, 
                TO_CHAR (Fecha, 'YYYY-MM-DD') Fecha,
             -- PIDM, Study_Path, Codigo, Descripcion, Fecha,
             -- tbraccd_tran_number,
                TO_CHAR (SUM (Suma_Cargos)) Cargos, 
                TO_CHAR (SUM (Suma_Abonos)) Abonos,
                TO_CHAR (SUM (Suma_Cargos - Suma_Abonos)) Cargos_menos_abonos,
                TO_CHAR (SUM (Balance)) Balance,
                NULL No_Aplica -- TO_CHAR (tbraccd_tran_number) Transaccion
           FROM (-- Cargos
                 SELECT tbraccd_pidm PIDM, 0 Study_Path, TRUNC (tbraccd_effective_date) Fecha,
                     -- tbraccd_pidm PIDM, tbraccd_stsp_key_sequence Study_Path, TRUNC (tbraccd_effective_date) Fecha, 
                        tbraccd_detail_code Codigo, NVL (TZTEDTC_DESC_NE, tbraccd_desc || '.') Descripcion,
                        tbraccd_tran_number,
                        SUM (tbraccd_amount) Suma_Cargos, 0 Suma_Abonos , SUM (tbraccd_balance) Balance
                   FROM tbraccd

                   LEFT JOIN TZTEDTC ON TZTEDTC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                        JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                        JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('VENTA', 'INTERES', 
                                                                                                          'NOTA DEBITO', 'NOTA CXC', 'ANTICIPO',
                                                                                                          'OTROS INGRESOS', 'FINANCIERAS')
                                    AND TBBDETC_TYPE_IND IN ('C')
                  WHERE TBRACCD_PIDM = pe_pidm
                    AND NVL (TBRACCD_AMOUNT,0) != 0
                    AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN Vm_Inicio AND Vm_FIn
               --   AND tbraccd_stsp_key_sequence = pe_study_path
               -- GROUP BY tbraccd_pidm, tbraccd_stsp_key_sequence, TRUNC (tbraccd_effective_date), tbraccd_detail_code, tbraccd_desc
                  GROUP BY tbraccd_pidm, 0, TRUNC (tbraccd_effective_date), tbraccd_detail_code, 
                           NVL (TZTEDTC_DESC_NE, tbraccd_desc || '.'), tbraccd_tran_number

                  UNION ALL

                 -- Abonos
                 SELECT tbraccd_pidm PIDM, 0 Study_Path, TRUNC (tbraccd_effective_date) Fecha,
                     -- tbraccd_pidm PIDM, tbraccd_stsp_key_sequence Study_Path, TRUNC (tbraccd_effective_date) Fecha,
                        tbraccd_detail_code Codigo, NVL (TZTEDTC_DESC_NE, tbraccd_desc || '.') Descripcion,
                        tbraccd_tran_number,
                        0 Suma_Cargos, SUM (tbraccd_amount) Suma_Abonos, SUM (tbraccd_balance) Balance
                   FROM tbraccd

                   LEFT JOIN TZTEDTC ON TZTEDTC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                        JOIN tbbdetc ON TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                        JOIN TZTNCD  ON TZTNCD_CODE = TBRACCD_DETAIL_CODE AND UPPER (TZTNCD_CONCEPTO) IN ('POLIZA', 'DEPOSITO', 'NOTA DISTRIBUCION',
                                                                                                          'NOTA CREDITO', 'INTERES', 'FINANCIERAS',
                                                                                                          'INCOBRABLE') -- 
                                    AND TBBDETC_TYPE_IND IN ('P')
                  WHERE TBRACCD_PIDM = pe_pidm
                    AND NVL (TBRACCD_AMOUNT,0) != 0
                    AND TRUNC (TBRACCD_EFFECTIVE_DATE) BETWEEN Vm_Inicio AND Vm_Fin
               --   AND tbraccd_stsp_key_sequence = pe_study_path
               -- GROUP BY tbraccd_pidm, tbraccd_stsp_key_sequence, TRUNC (tbraccd_effective_date), tbraccd_detail_code, tbraccd_desc
                  GROUP BY tbraccd_pidm, 0, TRUNC (tbraccd_effective_date), tbraccd_detail_code, 
                           NVL (TZTEDTC_DESC_NE, tbraccd_desc || '.'), tbraccd_tran_number
                )
--        GROUP BY PIDM,  Study_Path, Codigo, Descripcion, Fecha
          GROUP BY PIDM,  0, Codigo, Descripcion, Fecha, tbraccd_tran_number
--        ORDER BY Fecha, tbraccd_tran_number;
          ORDER BY 1 DESC, 6, 4, 11;

   RETURN Vm_Registros;

END f_masiva_edo_cta_unificado;

   
END PKG_EDO_CTA;
/

DROP PUBLIC SYNONYM PKG_EDO_CTA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_EDO_CTA FOR BANINST1.PKG_EDO_CTA;
