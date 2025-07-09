DROP PACKAGE BODY BANINST1.PKG_REPORTE_BI;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_REPORTE_BI AS
/******************************************************************************
 NAME: BANINST1.PKG_REPORTE_BI
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        24/01/2023  FND@Create       1. Creación del paquete.
******************************************************************************/

PROCEDURE P_REPORTE_UPSELLING IS
/******************************************************************************
   NAME:      P_REPORTE_BI
   PURPOSE:   Concentrado de ventas adicionales (UPSELLING).

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        24/01/2023  FND@Create       1. Creación del procedimiento.

   NOTES:

******************************************************************************
   MARCAS DE CAMBIO:
   No. 1
   Clave de cambio: 001-DDMMYYYY-(Autor-inciales)
   Autor: (Autor-Iniciales)@(Create, Update, Delete)
   Descripción: Descripción: (Describir el ajuste/modificación al código).
******************************************************************************
   No. 2
   Clave de cambio: 002-DDMMYYYY-(Autor-inciales)
   Autor: (Autor-Iniciales)@(Create, Update, Delete)
   Descripción: Descripción: (Describir el ajuste/modificación al código).
******************************************************************************

******************************************************************************/

--Variables del proceso.
VL_ERROR    VARCHAR2(900);
vl_pago_min date;
vl_pago_max date;
vl_desc_min  varchar2(500);
vl_desc_max  varchar2(500);

BEGIN

   -- DBMS_OUTPUT.PUT_LINE('Comienza proceso: '||TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')||CHR(10)||CHR(10));


    EXECUTE IMMEDIATE 'TRUNCATE TABLE SIU_CONN_BI.UPSELLING';
            commit;




    BEGIN
        INSERT INTO SIU_CONN_BI.UPSELLING
         Select x.campus,
                x.nivel,
                x.programa,
                x.matricula,
                x.correo_principal,
                x.correo_alterno,
               x.estatus,
               x.tran,
               x.periodo,
               x.vencimiento,
               x.codigo,
               x.descripcion,
               x.monto_cargo,
               x.descripcion_ntcr,
               x.monto_ntcr Monto_Nota_Credito,
               x.monto_pagado,
               x.monto_faltante,
               x.fecha_pago,
               x.descrp_pago Descripcion_Pago,
               x.montopromocion,
               case
                when x.monto_cargo = x.montopromocion then
                   0
                when x.monto_cargo < x.montopromocion then
                   x.descuentopromocion
               End por_descuento,
               x.SZT_TIPO_ALIANZA Categoria_Plataforma,
               nvl (to_char(to_date(x.FECHA_STATUS,'yyyy/mm/dd'),'dd/mm/yyyy'), trunc (x.Fecha_creacion)) Fecha_Compra,
               null,
               null
        from (
        with pagos as (
        Select sum (TBRAPPL_AMOUNT) monto, tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--, TBRACCD_EFFECTIVE_DATE, tbraccd_desc
        from tbrappl, tbraccd, TZTNCD
        Where 1= 1
--        And tbrappl_pidm = fget_pidm ('010354993')
--        And TBRAPPL_CHG_TRAN_NUMBER = 56
        And TBRACCD_PIDM = tbrappl_pidm
        And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
        And tbraccd_detail_code =  TZTNCD_CODE
        And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
        And TBRAPPL_REAPPL_IND is null
        --And trunc (TBRACCD_EFFECTIVE_DATE) between '01/06/2022' and '30/06/2022'
        group by tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--,TBRACCD_EFFECTIVE_DATE, tbraccd_desc
        ),
        credito as (
        Select sum (TBRAPPL_AMOUNT) monto, tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--, tbraccd_desc Nombre_Nota
        from tbrappl, tbraccd, TZTNCD
        Where 1= 1
--        And tbrappl_pidm = fget_pidm ('010354993')
--        And TBRAPPL_CHG_TRAN_NUMBER = 56
        And TBRACCD_PIDM = tbrappl_pidm
        And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
        And tbraccd_detail_code =  TZTNCD_CODE
        And TZTNCD_CONCEPTO IN ('Nota Credito','Incobrable','Poliza abono','Financieras','Otros Ingresos')
        And TBRAPPL_REAPPL_IND is null
        group by tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--,tbraccd_desc
        ),
        Categoria as (
                        select distinct SZT_TIPO_ALIANZA, SZT_CODE_SERV, SZT_NIVEL
                        from SZTGECE
                        Where 1=1
        )
        select distinct --spriden_pidm,
                            e.campus,
                            e.nivel,
                            e.programa,
                            spriden_id matricula,
                             nvl (trim (pkg_utilerias.f_correo(a.tbraccd_pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.tbraccd_pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.tbraccd_pidm, 'UTLX')) )) Correo_Principal,
                              pkg_utilerias.f_correo(a.tbraccd_pidm, 'ALTE') Correo_Alterno,
                            e.estatus,
                            a.TBRACCD_TRAN_NUMBER Tran,
                            a.TBRACCD_TERM_CODE Periodo,
                            trunc (a.TBRACCD_EFFECTIVE_DATE) Vencimiento,
                            a.tbraccd_detail_code Codigo,
                            TBBDETC_DESC Descripcion,
                            (nvl (a.TBRACCD_AMOUNT,0) /*- nvl (d.monto,0)*/) Monto_Cargo,
                            null Descripcion_NTCR,
                            nvl (d.monto,0) Monto_NTCR,
                            nvl (c.monto,0) Monto_Pagado,
                            (nvl (a.TBRACCD_AMOUNT,0) - nvl (d.monto,0)) - ( nvl (c.monto,0)) Monto_Faltante,
                            null Fecha_Pago,
                            null descrp_pago,
                            (SELECT max (A.TZTCOTA_MONTO)
                                    FROM TZTCOTA A
                                    where 1=1
                                    and A.TZTCOTA_PIDM = a.TBRACCD_PIDM--414873
                                    and substr(A.TZTCOTA_CODIGO,3,2)= substr(a.TBRACCD_DETAIL_CODE,3,2)
                                    and A.TZTCOTA_SEQNO=(   SELECT MAX(A1.TZTCOTA_SEQNO)
                                                            FROM TZTCOTA A1
                                                            WHERE
                                                                1=1 AND
                                                                A1.TZTCOTA_PIDM = A.TZTCOTA_PIDM AND
                                                                A1.TZTCOTA_CODIGO=A.TZTCOTA_CODIGO)
                                   )MontoPromocion ,
                                   (SELECT max (A.TZTCOTA_DESCUENTO)
                                    FROM TZTCOTA A
                                    where 1=1
                                    and A.TZTCOTA_PIDM =a.TBRACCD_PIDM-- fget_pidm('010022232')
                                    and substr(A.TZTCOTA_CODIGO,3,2)= substr(a.TBRACCD_DETAIL_CODE,3,2)
                                    and A.TZTCOTA_SEQNO=(   SELECT MAX(A1.TZTCOTA_SEQNO)
                                                            FROM TZTCOTA A1
                                                            WHERE
                                                                1=1 AND
                                                                A1.TZTCOTA_PIDM = A.TZTCOTA_PIDM AND
                                                                A1.TZTCOTA_CODIGO=A.TZTCOTA_CODIGO)
                                   )DescuentoPromocion ,
                                    FECHA_STATUS,
                                    f.SZT_TIPO_ALIANZA,
                                    trunc(a.TBRACCD_ENTRY_DATE) Fecha_creacion
        from tbraccd a
        join tbbdetc on tbbdetc_detail_code = a.tbraccd_detail_code
        join TZTNCD on TZTNCD_CODE = a.tbraccd_detail_code
        join spriden on spriden_pidm = a.tbraccd_pidm and spriden_change_ind is null
        left join SZRVSSB on matricula = spriden_id and SEQ_NO = a.TBRACCD_CROSSREF_NUMBER
        join tztprog e on e.pidm = a.tbraccd_pidm and e.sp in (select max (e1.sp)
                                                                from tztprog e1
                                                                where e.pidm = e1.pidm
                                                              )
        left join pagos  c on tbrappl_pidm = a.tbraccd_pidm and c.TBRAPPL_CHG_TRAN_NUMBER= a.TBRACCD_TRAN_NUMBER
        left join credito d on d.tbrappl_pidm = a.tbraccd_pidm and d.TBRAPPL_CHG_TRAN_NUMBER= a.TBRACCD_TRAN_NUMBER
        left join Categoria f on f.SZT_CODE_SERV = COD_SERVICIO and f.SZT_NIVEL = e.nivel
        where 1= 1
        And TZTNCD_CONCEPTO ='Nota Debito'
       -- And substr (a.tbraccd_detail_code,3,2)  in ('HJ','XP','XR','YR','YT','B2','B3','1A','IP','AQ','AS','AX','FL','HO','HM','HK','HP','HN','AC','AD','AJ','NA','YX','CW','SY','TJ','HW')
     --   and spriden_id in ('010348331')
      --  and TBRACCD_TRAN_NUMBER = 56
        ) X;

    EXCEPTION
        WHEN OTHERS THEN
            VL_ERROR := 'Error al procesar información en SIU_CONN_BI.UPSELLING... Favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM||CHR(10)||CHR(10);
    END;

    COMMIT;


--------------------------------------- Se carga el campus de UtelX ---------------------------------------


     Begin
        INSERT INTO SIU_CONN_BI.UPSELLING
        with pagos as (
                        Select sum (TBRAPPL_AMOUNT) monto, tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--, TBRACCD_EFFECTIVE_DATE, tbraccd_desc
                        from tbrappl, tbraccd, TZTNCD
                        Where 1= 1
                --        And tbrappl_pidm = fget_pidm ('010354993')
                --        And TBRAPPL_CHG_TRAN_NUMBER = 56
                        And TBRACCD_PIDM = tbrappl_pidm
                        And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                        And tbraccd_detail_code =  TZTNCD_CODE
                        And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                        And TBRAPPL_REAPPL_IND is null
                        --And trunc (TBRACCD_EFFECTIVE_DATE) between '01/06/2022' and '30/06/2022'
                        group by tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--,TBRACCD_EFFECTIVE_DATE, tbraccd_desc
        ),
        credito as (
                        Select sum (TBRAPPL_AMOUNT) monto, tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--, tbraccd_desc Nombre_Nota
                        from tbrappl, tbraccd, TZTNCD
                        Where 1= 1
                --        And tbrappl_pidm = fget_pidm ('010354993')
                --        And TBRAPPL_CHG_TRAN_NUMBER = 56
                        And TBRACCD_PIDM = tbrappl_pidm
                        And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                        And tbraccd_detail_code =  TZTNCD_CODE
                        And TZTNCD_CONCEPTO IN ('Nota Credito','Incobrable','Poliza abono','Financieras','Otros Ingresos')
                        And TBRAPPL_REAPPL_IND is null
                        group by tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--,tbraccd_desc
        )
        select distinct
                'UTX' Campus,
                'EC' Nivel,
                'UTXECSEMCU' Programa,
                spriden_id matricula,
                nvl (trim (pkg_utilerias.f_correo(a.tbraccd_pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.tbraccd_pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.tbraccd_pidm, 'UTLX')) )) Correo_Principal,
                pkg_utilerias.f_correo(a.tbraccd_pidm, 'ALTE') Correo_Alterno,
                null Estatus,
                a.TBRACCD_TRAN_NUMBER Tran,
                a.TBRACCD_TERM_CODE Periodo,
                trunc (a.TBRACCD_EFFECTIVE_DATE) Vencimiento,
                a.tbraccd_detail_code Codigo,
                a.tbraccd_desc Descripcion,
                a.TBRACCD_AMOUNT Monto_Cargo,
                null Descripcion_NTCR,
                nvl (d.Monto,0)MONTO_NOTA_CREDITO,
                nvl (c.monto,0) Monto_Pagado,
                (nvl (a.TBRACCD_AMOUNT,0) - nvl (d.monto,0)) - ( nvl (c.monto,0)) Monto_Faltante,
                null fecha_pago,
                null descripcion_pago,
                null monto_promocion,
                null por_descuento,
                null categoria_plataforma,
                null fecha_compra,
                null fecha_pago_max,
                null desc_pago_max
        from tbraccd a
        join tbbdetc on tbbdetc_detail_code = a.tbraccd_detail_code and TBBDETC_TYPE_IND = 'C'
        join spriden on spriden_pidm = a.tbraccd_pidm and spriden_change_ind is null
        left join pagos  c on tbrappl_pidm = a.tbraccd_pidm and c.TBRAPPL_CHG_TRAN_NUMBER= a.TBRACCD_TRAN_NUMBER
        left join credito d on d.tbrappl_pidm = a.tbraccd_pidm and d.TBRAPPL_CHG_TRAN_NUMBER= a.TBRACCD_TRAN_NUMBER
        where 1= 1
        And spriden_id like '54%';
    EXCEPTION
        WHEN OTHERS THEN
            VL_ERROR := 'Error al procesar información en SIU_CONN_BI.UPSELLING... Favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM||CHR(10)||CHR(10);
    END;

    COMMIT;



--------------------------------------- Se carga el campus de UtelX ---------------------------------------


     Begin
        INSERT INTO SIU_CONN_BI.UPSELLING
        with pagos as (
                        Select sum (TBRAPPL_AMOUNT) monto, tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--, TBRACCD_EFFECTIVE_DATE, tbraccd_desc
                        from tbrappl, tbraccd, TZTNCD
                        Where 1= 1
                --        And tbrappl_pidm = fget_pidm ('010354993')
                --        And TBRAPPL_CHG_TRAN_NUMBER = 56
                        And TBRACCD_PIDM = tbrappl_pidm
                        And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                        And tbraccd_detail_code =  TZTNCD_CODE
                        And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                        And TBRAPPL_REAPPL_IND is null
                        --And trunc (TBRACCD_EFFECTIVE_DATE) between '01/06/2022' and '30/06/2022'
                        group by tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--,TBRACCD_EFFECTIVE_DATE, tbraccd_desc
        ),
        credito as (
                        Select sum (TBRAPPL_AMOUNT) monto, tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--, tbraccd_desc Nombre_Nota
                        from tbrappl, tbraccd, TZTNCD
                        Where 1= 1
                --        And tbrappl_pidm = fget_pidm ('010354993')
                --        And TBRAPPL_CHG_TRAN_NUMBER = 56
                        And TBRACCD_PIDM = tbrappl_pidm
                        And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                        And tbraccd_detail_code =  TZTNCD_CODE
                        And TZTNCD_CONCEPTO IN ('Nota Credito','Incobrable','Poliza abono','Financieras','Otros Ingresos')
                        And TBRAPPL_REAPPL_IND is null
                        group by tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER--,tbraccd_desc
        )
        select distinct
                'CON' Campus,
                'EC' Nivel,
                'CONECSEMCU' Programa,
                spriden_id matricula,
                nvl (trim (pkg_utilerias.f_correo(a.tbraccd_pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.tbraccd_pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.tbraccd_pidm, 'UTLX')) )) Correo_Principal,
                pkg_utilerias.f_correo(a.tbraccd_pidm, 'ALTE') Correo_Alterno,
                null Estatus,
                a.TBRACCD_TRAN_NUMBER Tran,
                a.TBRACCD_TERM_CODE Periodo,
                trunc (a.TBRACCD_EFFECTIVE_DATE) Vencimiento,
                a.tbraccd_detail_code Codigo,
                a.tbraccd_desc Descripcion,
                a.TBRACCD_AMOUNT Monto_Cargo,
                null Descripcion_NTCR,
                nvl (d.Monto,0)MONTO_NOTA_CREDITO,
                nvl (c.monto,0) Monto_Pagado,
                (nvl (a.TBRACCD_AMOUNT,0) - nvl (d.monto,0)) - ( nvl (c.monto,0)) Monto_Faltante,
                null fecha_pago,
                null descripcion_pago,
                null monto_promocion,
                null por_descuento,
                null categoria_plataforma,
                null fecha_compra,
                null fecha_pago_max,
                null desc_pago_max
        from tbraccd a
        join tbbdetc on tbbdetc_detail_code = a.tbraccd_detail_code and TBBDETC_TYPE_IND = 'C'
        join spriden on spriden_pidm = a.tbraccd_pidm and spriden_change_ind is null
        left join pagos  c on tbrappl_pidm = a.tbraccd_pidm and c.TBRAPPL_CHG_TRAN_NUMBER= a.TBRACCD_TRAN_NUMBER
        left join credito d on d.tbrappl_pidm = a.tbraccd_pidm and d.TBRAPPL_CHG_TRAN_NUMBER= a.TBRACCD_TRAN_NUMBER
        where 1= 1
        And spriden_id like '58%';
    EXCEPTION
        WHEN OTHERS THEN
            VL_ERROR := 'Error al procesar información en SIU_CONN_BI.UPSELLING... Favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM||CHR(10)||CHR(10);
    END;

    COMMIT;





    Begin

        For cx in (

                    Select distinct spriden_pidm pidm, tran, matricula
                    from UPSELLING
                    join spriden on spriden_id = matricula and spriden_change_ind is null

        ) loop


           For cx2 in (
                     Select distinct trunc (min(x.Pago_Min)) Pago_Min, x.tbraccd_desc Desc_min
                    from(
                        Select distinct min (trunc (TBRACCD_EFFECTIVE_DATE)) Pago_Min, tbraccd_desc
                        from tbrappl, tbraccd, TZTNCD
                        Where 1= 1
                        And tbrappl_pidm = cx.pidm
                        And TBRAPPL_CHG_TRAN_NUMBER = cx.tran
                        And TBRACCD_PIDM = tbrappl_pidm
                        And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                        And tbraccd_detail_code =  TZTNCD_CODE
                        And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                        And TBRAPPL_REAPPL_IND is null
                        group by tbraccd_desc
                        ) x
                        group by x.tbraccd_desc
                        order by 1 desc


            ) loop


                   Begin
                        Update UPSELLING
                          set FECHA_PAGO = cx2.Pago_Min,
                              DESCRP_PAGO = cx2.Desc_min
                        Where MATRICULA = cx.matricula
                        And TRAN = cx.tran;
                   Exception
                    When Others then
                        null;
                   End;

                  Commit;


            End Loop;

            For cx3 in (

                    Select distinct trunc (max(x.Pago_Max)) Pago_Max, x.tbraccd_desc desc_max
                    from(
                        Select distinct max (trunc (TBRACCD_EFFECTIVE_DATE)) Pago_Max , tbraccd_desc
                        from tbrappl, tbraccd, TZTNCD
                        Where 1= 1
                        And tbrappl_pidm = cx.pidm
                        And TBRAPPL_CHG_TRAN_NUMBER = cx.tran
                        And TBRACCD_PIDM = tbrappl_pidm
                        And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                        And tbraccd_detail_code =  TZTNCD_CODE
                        And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                        And TBRAPPL_REAPPL_IND is null
                        group by tbraccd_desc
                        ) x
                        group by x.tbraccd_desc
                        order by 1 desc

            ) loop

                   Begin
                        Update UPSELLING
                          set FECHA_PAGO_FIN = cx3.Pago_Max,
                              DESCRP_PAGO_FIN = cx3.desc_max
                        Where MATRICULA = cx.matricula
                        And TRAN = cx.tran;
                   Exception
                    When Others then
                        null;
                   End;

                   Commit;

            End Loop;


        End loop;

        Commit;
    Exception
        When Others then
            null;
    End;

    ------------------- Se coloca la fecha de Compra por accesorio y busco el valor mas pequeño  ----------

    Begin

            For cx in (

                        Select distinct CODIGO, matricula
                        from UPSELLING
                        where 1=1
                       -- and matricula ='010362860'
                        order by 2,1

            ) loop


                For cx2 in (

                            Select distinct a.vencimiento
                            from UPSELLING a
                            where 1=1
                            And a.matricula = cx.matricula
                            And a.codigo = cx.codigo
                            And trunc (a.vencimiento) = (select min (a1.vencimiento)
                                                         from UPSELLING a1
                                                         Where a.matricula = a1.matricula
                                                         And a.codigo = a1.codigo)
                ) loop

                    Begin
                        update UPSELLING
                        set FECHA_COMPRA = cx2.vencimiento
                        Where matricula = cx.matricula
                        And codigo = cx.codigo;

                    Exception
                        When OThers then
                            null;
                    End;


                End Loop cx2;

                Commit;
            End Loop cx;

    End;

END P_REPORTE_UPSELLING;


PROCEDURE P_REPORTE_UTELX_HIST IS


--Variables del proceso.
VL_ERROR    VARCHAR2(900);

BEGIN

   -- DBMS_OUTPUT.PUT_LINE('Comienza proceso: '||TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')||CHR(10)||CHR(10));


    EXECUTE IMMEDIATE 'TRUNCATE TABLE SIU_CONN_BI.UTELX_HIST';
            commit;

    Begin
        Insert into UTELX_HIST
        select SZTUTLX_ID Matricula, SZTUTLX_ACTIVITY_DATE Fecha_Registro,
                SZTUTLX_SEQ_NO Secuencia, decode (SZTUTLX_STAT_IND,'0','Sin_Sincronizar','1', 'Sincronizado','2','Error') Estatus_Sincronizado , decode (SZTUTLX_DISABLE_IND, 'A', 'Activo', 'I', 'InActivo') Estado,
                nvl (trim (pkg_utilerias.f_correo(SZTUTLX_PIDM, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(SZTUTLX_PIDM, 'UCAM')),trim (pkg_utilerias.f_correo(SZTUTLX_PIDM, 'UTLX')) )) Correo_Principal,
                pkg_utilerias.f_correo(SZTUTLX_PIDM, 'ALTE') Correo_Alterno
        from SZTUTLX
        where 1=1
        --And  SZTUTLX_ID ='010002949'
        order by 1, 3;
        commit;
    Exception
        When Others then
            null;
    End;



End P_REPORTE_UTELX_HIST;


PROCEDURE P_REPORTE_USUARIO_UPSELLING IS

p_pidm number;
-------- SSB ------
vl_monto number:=0;
vl_porcentaje number:=0;
vl_monto_Descuento number:=0;
vl_Fecha varchar2(12):= null;
-------- PAquete Fijo ------
vl_codigo_Desc varchar2(4):= null;
vl_porc_desc number := 0;
vl_monto_Desc number:=0;

vl_codigo_Descrip varchar2(50):= null;
vl_moneda varchar2(10):= null;
vl_cod_desc_Descrip varchar2(50):= null;
----------- Generacion de cargos ----------
vl_existe_cargo number:=0;
VL_DIA VARCHAR2(2);
VL_MES VARCHAR2(2);
VL_ANO VARCHAR2(4);
vl_orden NUMBER:= null;
vl_codigo_cargo varchar2(4):= null;
VL_VENCIMIENTO VARCHAR2(15);
VL_SECUENCIA number:=0;
VL_SEC_CARGO number:=0;
VL_VENCIMIENTO_ssb VARCHAR2(15);
vl_secuencia_ssb number:=0;
vl_existe_cartera number:=0;
vl_salida varchar2(250):= null;
vl_fecha_ret date;
vl_inserto number:=0;


  Begin


    EXECUTE IMMEDIATE 'TRUNCATE TABLE SIU_CONN_BI.USER_MEMBRESIA';
    commit;



    For cx in (


                            SELECT DISTINCT
                                 A.pidm,
                                 a.matricula,
                                 a.campus,
                                 a.nivel,
                                 a.programa,
                                 nvl (trim (pkg_utilerias.f_correo(a.pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.pidm, 'UTLX')) )) Correo_Principal,
                                 pkg_utilerias.f_correo(a.pidm, 'ALTE') Correo_Alterno,
                                 a.estatus,
                                 a.ESTATUS_D Descrip_Estatus,
                                 b.SZTUTLX_SEQ_NO Seq,
                                 b.SZTUTLX_DISABLE_IND Estatus_Memb,
                                 b.SZTUTLX_OBS Observaciones,
                                 b.SZTUTLX_ACTIVITY_DATE Fecha_Estatus,
                                 PKG_UTILERIAS.f_paquete_programa(a.pidm, a.programa) Paquete,
                                 a.sp,
                                 'SZTUTLX' Fuente
                            FROM tztprog a
                                 JOIN SZTUTLX b ON     b.SZTUTLX_PIDM = a.pidm
                                       AND b.SZTUTLX_STAT_IND IN ('1', '2')
                                       AND b.SZTUTLX_SEQ_NO = (SELECT MAX (b1.SZTUTLX_SEQ_NO)
                                                                FROM SZTUTLX b1
                                                                WHERE     1 = 1
                                                                AND b.SZTUTLX_PIDM = b1.SZTUTLX_PIDM
                                                                AND b1.SZTUTLX_STAT_IND = b.SZTUTLX_STAT_IND)
                           WHERE     1 = 1
                           And a.estatus not in ('CP')
                           AND a.sp = (SELECT MAX (a1.sp)
                                        FROM tztprog a1
                                        WHERE a.pidm = a1.pidm)
                            Order by 1
      ) loop


            vl_inserto:=0;
            --------------- Busco los valores para el AutoServicio ----------------
        Begin
            select a.monto, a.PORCENTAJE, a.MONTODESCUENTO, a.FECHA_STATUS
                Into vl_monto, vl_porcentaje, vl_monto_Descuento, vl_Fecha
            from SZRVSSB a
            where 1= 1
            And a.ESTATUS_SOLC = 'CONCLUIDO'
            And a.COD_SERVICIO = 'UTLX'
            And a.Matricula = cx.matricula
            And a.Campus = cx.campus
            And a.nivel  = cx.nivel
            And to_number(a.SEQ_NO) = (select maX(to_number(a1.SEQ_NO))
                               from SZRVSSB a1
                               Where a.Matricula = a1.Matricula
                               And a.COD_SERVICIO = a1.COD_SERVICIO
                               );
        Exception
            When Others then
                vl_monto:=null;
                vl_porcentaje:=null;
                vl_monto_Descuento:=null;
        End;

        If vl_monto >=0 then --------- Registro por SSB
           vl_codigo_Descrip:= null;
           vl_moneda := null;

           Begin
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'NA';
           Exception
            When Others then
              vl_codigo_Descrip:= null;
              vl_moneda:= null;
           End;

           Begin
                Insert into USER_MEMBRESIA values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.correo_principal,
                                                cx.correo_alterno,
                                                cx.ESTATUS,
                                                cx.DESCRIP_ESTATUS,
                                                substr (cx.matricula,1,2) ||'NA', ---> SSB
                                                cx.seq,
                                                cx.ESTATUS_MEMB,
                                                cx.OBSERVACIONES,
                                                cx.FECHA_ESTATUS,
                                                cx.paquete,
                                                'SSB',
                                                cx.sp,
                                                1,
                                                vl_codigo_Descrip,
                                                cx.fuente,
                                                null,
                                                NULL
                                                );
                   vl_inserto:=1;
           Exception
            When Others then
                 DBMS_OUTPUT.PUT_LINE('salida'||sqlerrm );
                 vl_inserto:=0;
           End;


        End if;

        ---------------------------- Se buscan los registros de paquete fijo ------------------

        vl_monto:=0;
        vl_porcentaje:=0;
        vl_monto_Descuento:=0;
        vl_codigo_Desc:= null;
        vl_porc_desc:=0;
        vl_monto_Desc:=0;

        Begin

            Select TZFACCE_AMOUNT
                Into vl_monto
            from TZFACCE a
            Where 1=1
            and a.TZFACCE_PIDM = cx.pidm
             and substr (a.TZFACCE_DETAIL_CODE, 3,2) in ('QI', 'QG')
             And a.TZFACCE_SEC_PIDM = (select max (a1.TZFACCE_SEC_PIDM)
                                        from TZFACCE a1
                                        Where a.TZFACCE_pidm  = a1.TZFACCE_pidm
                                        And a.TZFACCE_DETAIL_CODE = a1.TZFACCE_DETAIL_CODE

                                        );
        Exception
            When Others then
               vl_monto:=null;

        End;

        Begin

        select SWTMDAC_DETAIL_CODE_DESC , SWTMDAC_PERCENT_DESC, (nvl (vl_monto,0)*SWTMDAC_PERCENT_DESC/100) monto_desc
            into vl_codigo_Desc, vl_porc_desc, vl_monto_Desc
        from SWTMDAC a
        where 1= 1
        And a.SWTMDAC_PIDM = cx.pidm
        and substr (a.SWTMDAC_DETAIL_CODE_ACC, 3,2) in ('QI', 'QG')
        And a.SWTMDAC_SEC_PIDM = (select max (a1.SWTMDAC_SEC_PIDM)
                                  from SWTMDAC a1
                                  Where 1 = 1
                                  And a.SWTMDAC_PIDM = a1.SWTMDAC_PIDM
                                  And a.SWTMDAC_DETAIL_CODE_ACC = a1.SWTMDAC_DETAIL_CODE_ACC);
        Exception
            When Others then
              vl_codigo_Desc := null;
              vl_porc_desc := 0;
              vl_monto_Desc :=0;
        End;

        If vl_monto_Desc = 0 then

            Begin
                select SWTMDAC_AMOUNT_DESC
                    into vl_monto_Desc
                from SWTMDAC a
                where 1= 1
                And a.SWTMDAC_PIDM = cx.pidm
                and substr (a.SWTMDAC_DETAIL_CODE_ACC, 3,2) in ('QI', 'QG')
                And a.SWTMDAC_SEC_PIDM = (select max (a1.SWTMDAC_SEC_PIDM)
                                          from SWTMDAC a1
                                          Where 1 = 1
                                          And a.SWTMDAC_PIDM = a1.SWTMDAC_PIDM
                                          And a.SWTMDAC_DETAIL_CODE_ACC = a1.SWTMDAC_DETAIL_CODE_ACC);
            Exception
                When Others then
                  vl_codigo_Desc := null;
                  vl_porc_desc := 0;
                  vl_monto_Desc :=0;
            End;
        End if;


        If vl_monto >=0 and vl_inserto = 0 then --------- Registro por Fijo
           vl_codigo_Descrip:= null;
           vl_moneda:= null;
           vl_cod_desc_Descrip:= null;

           Begin
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'QI';
           Exception
            When Others then
              vl_codigo_Descrip:= null;
              vl_moneda:= null;
           End;

           Begin
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_cod_desc_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = vl_codigo_Desc;
           Exception
            When Others then
              vl_cod_desc_Descrip:= null;
              vl_moneda:= null;
           End;




           Begin
                Insert into USER_MEMBRESIA values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.correo_principal,
                                                cx.correo_alterno,
                                                cx.ESTATUS,
                                                cx.DESCRIP_ESTATUS,
                                                substr (cx.matricula,1,2) ||'QI', ----Paquete Fijo
                                                cx.seq,
                                                cx.ESTATUS_MEMB,
                                                cx.OBSERVACIONES,
                                                cx.FECHA_ESTATUS,
                                                cx.paquete,
                                                'FJO',
                                                cx.sp,
                                                2,
                                                vl_codigo_Descrip,
                                                cx.fuente,
                                                null,
                                                NULL
                                                );
              vl_inserto:=1;
           Exception
            When Others then
                 DBMS_OUTPUT.PUT_LINE('salida'||sqlerrm );
                 vl_inserto:=0;
           End;


        End if;


        ---------------------------- Se buscan los registros de paquete Dinamico ------------------
        vl_monto:=0;
        vl_codigo_Desc:= null;
        vl_monto_Desc:=null;


        Begin
            Select distinct  TZTPADI_AMOUNT
                Into vl_monto
            from tztpadi a
            where 1= 1
            and a.TZTPADI_PIDM = cx.pidm
            and substr (a.TZTPADI_DETAIL_CODE, 3,2) in ('QI','QG')
            And a.TZTPADI_FLAG = 0
            And a.TZTPADI_SEQNO = (select max (a1.TZTPADI_SEQNO)
                                    from TZTPADI a1
                                    Where a.TZTPADI_PIDM = a1.TZTPADI_PIDM
                                    And a.TZTPADI_DETAIL_CODE = a1.TZTPADI_DETAIL_CODE
                                    And a.TZTPADI_FLAG = a1.TZTPADI_FLAG
                                    ) ;
        Exception
            When Others then
             vl_monto:=null;
        End;

        If vl_monto >=0 and vl_inserto = 0 then --------- Registro por Dinamico
           vl_codigo_Descrip:= null;
           vl_moneda:= null;
           vl_cod_desc_Descrip:= null;

           Begin
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'QI';
           Exception
            When Others then
              vl_codigo_Descrip:= null;
              vl_moneda:= null;
           End;


           Begin
                Insert into USER_MEMBRESIA values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.correo_principal,
                                                cx.correo_alterno,
                                                cx.ESTATUS,
                                                cx.DESCRIP_ESTATUS,
                                                substr (cx.matricula,1,2) ||'QI', ----Paquete Fijo
                                                cx.seq,
                                                cx.ESTATUS_MEMB,
                                                cx.OBSERVACIONES,
                                                cx.FECHA_ESTATUS,
                                                cx.paquete,
                                                'Dinamico',
                                                cx.sp,
                                                3,
                                                vl_codigo_Descrip,
                                                cx.fuente,
                                                null,
                                                NULL
                                                );
               vl_inserto:=1;
           Exception
            When Others then
                 DBMS_OUTPUT.PUT_LINE('salida'||sqlerrm );
                 vl_inserto:=0;
           End;



        End if;

        If vl_monto is null and vl_inserto = 0 then
           vl_monto:=0;

           vl_codigo_Descrip:= null;
           vl_moneda:= null;
           vl_cod_desc_Descrip:= null;

           Begin
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'QI';
           Exception
            When Others then
              vl_codigo_Descrip:= null;
              vl_moneda:= null;
           End;


           Begin
                Insert into USER_MEMBRESIA values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.correo_principal,
                                                cx.correo_alterno,
                                                cx.ESTATUS,
                                                cx.DESCRIP_ESTATUS,
                                                substr (cx.matricula,1,2) ||'QI', ----Paquete Fijo
                                                cx.seq,
                                                cx.ESTATUS_MEMB,
                                                cx.OBSERVACIONES,
                                                cx.FECHA_ESTATUS,
                                                cx.paquete,
                                                'No_Definido',
                                                cx.sp,
                                                4,
                                                vl_codigo_Descrip,
                                                cx.fuente,
                                                null,
                                                NULL
                                                );
           Exception
            When Others then
                 DBMS_OUTPUT.PUT_LINE('salida No_Definido'||sqlerrm );
           End;


        End if;

        Commit;


      End loop;
      Commit;


      ----------------- Se eliminan los registros duplicados para registros mayores -------------------
        Begin

              For cx in (

                            select count(*), matricula, CODIGO_DETALLE
                            from USER_MEMBRESIA
                            where 1=1
                            --And matricula ='010586903'
                            group by matricula, CODIGO_DETALLE
                            having count(*) > 1

              ) loop


                    For cx2 in (

                                select *
                                from USER_MEMBRESIA a
                                Where 1=1
                                And a.matricula = cx.matricula
                                And a.CODIGO_DETALLE = cx.CODIGO_DETALLE
                                And a.ORDEN_APLICACION = (select min (a1.ORDEN_APLICACION)
                                                           from USER_MEMBRESIA a1
                                                           Where a.matricula = a1.matricula
                                                           And a.CODIGO_DETALLE = a1.CODIGO_DETALLE
                                                         )
                               And a.seq =(select min (a1.seq)
                                             from USER_MEMBRESIA a1
                                             Where a.matricula = a1.matricula
                                             And a.CODIGO_DETALLE = a1.CODIGO_DETALLE
                                             And a.ORDEN_APLICACION = a1.ORDEN_APLICACION)

                    ) loop


                            Begin
                                delete USER_MEMBRESIA
                                Where 1= 1
                                And matricula = cx2.matricula
                                And CODIGO_DETALLE = cx2.CODIGO_DETALLE
                                And ORDEN_APLICACION = cx2.ORDEN_APLICACION
                                And seq = cx2.seq
                                --And origen not in ('SSB')
                                ;
                            Exception
                                When Others then
                                 null;
                            End;
                            Commit;

                  End loop;

              End loop;

      End;


      ----------------------------------------  Inserta los registros de SSB de COTA ---------------------------------
      Begin

                For cx in (


                             SELECT DISTINCT
                                 A.pidm,
                                 a.matricula,
                                 a.campus,
                                 a.nivel,
                                 a.programa,
                                 nvl (trim (pkg_utilerias.f_correo(a.pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.pidm, 'UTLX')) )) Correo_Principal,
                                 pkg_utilerias.f_correo(a.pidm, 'ALTE') Correo_Alterno,
                                 a.estatus,
                                 a.ESTATUS_D Descrip_Estatus,
                                 b.TZTCOTA_CODIGO Codigo_detalle,
                                 b.TZTCOTA_SEQNO Seq,
                                 b.TZTCOTA_STATUS Estatus_Memb,
                                 b.TZTCOTA_OBSERVACIONES Observaciones,
                                 b.TZTCOTA_ACTIVITY Fecha_Estatus,
                                 PKG_UTILERIAS.f_paquete_programa(a.pidm, a.programa) Paquete,
                                 'SSB' origen,
                                 a.sp,
                                 4 orden_aplicacion,
                                 c.tbbdetc_Desc descrip_codigo,
                                 'TZTCOTA' Fuente,
                                 null vacio,
                                 NULL vacio1
                            FROM tztprog a
                            JOIN tztcota b ON b.TZTCOTA_PIDM = a.pidm
                                           AND b.TZTCOTA_SEQNO = (SELECT MAX (b1.TZTCOTA_SEQNO)
                                                                  FROM tztcota b1
                                                                  WHERE     1 = 1
                                                                  AND b.TZTCOTA_PIDM = b1.TZTCOTA_PIDM
                                                                  And b.TZTCOTA_CODIGO = b1.TZTCOTA_CODIGO
                                                                )
                           join tbbdetc c on c.tbbdetc_detail_code = b.TZTCOTA_CODIGO
                           WHERE     1 = 1
                           And a.estatus not in ('CP')
                           AND a.sp = (SELECT MAX (a1.sp)
                                        FROM tztprog a1
                                        WHERE a.pidm = a1.pidm)
                            -- And a.matricula = '010002238'
                 ) loop       
                 
                 
                       Begin
                            Insert into USER_MEMBRESIA values (cx.pidm,
                                                            cx.matricula,
                                                            cx.campus,
                                                            cx.nivel,
                                                            cx.programa,
                                                            cx.correo_principal,
                                                            cx.correo_alterno,
                                                            cx.ESTATUS,
                                                            cx.DESCRIP_ESTATUS,
                                                            cx.CODIGO_DETALLE,
                                                            cx.seq,
                                                            cx.ESTATUS_MEMB,
                                                            cx.OBSERVACIONES,
                                                            cx.FECHA_ESTATUS,
                                                            cx.paquete,
                                                            cx.origen,
                                                            cx.sp,
                                                            cx.orden_aplicacion,
                                                            cx.descrip_codigo,
                                                            cx.fuente,
                                                            null,
                                                            NULL
                                                            );
                       Exception
                        When Others then
                         null;
                             --DBMS_OUTPUT.PUT_LINE('salida No_Definido'||sqlerrm );
                       End;                 
                       Commit;
                 End Loop;  
                 Commit;
       
      End;

      ---------------------------------------------------  Registros de TZFACCE  -----------------------------
      Begin

                For cx in (

                                Select
                                     b.pidm,
                                     b.matricula,
                                     b.campus,
                                     b.nivel,
                                     b.programa,
                                     nvl (trim (pkg_utilerias.f_correo(b.pidm, 'PRIN')),
                                     nvl (trim (pkg_utilerias.f_correo(b.pidm, 'UCAM')),
                                     trim (pkg_utilerias.f_correo(b.pidm, 'UTLX'))
                                     )) Correo_Principal,
                                     pkg_utilerias.f_correo(b.pidm, 'ALTE') Correo_Alterno,
                                     b.estatus,
                                     b.ESTATUS_D Descrip_Estatus,
                                     a.TZFACCE_DETAIL_CODE Codigo_detalle,
                                     a.TZFACCE_SEC_PIDM Seq,
                                     decode (a.TZFACCE_FLAG,'0', 'A', '2', 'I', '1', 'I') Estatus_Memb,
                                     c.OBSERVACIONES Observaciones,
                                     nvl (a.TZFACCE_ACTIVITY_DATE,c.FECHA_SINCRO) Fecha_Estatus,
                                     PKG_UTILERIAS.f_paquete_programa(b.pidm, b.programa) Paquete,
                                     'FIJO' origen,
                                     b.sp,
                                     5 orden_aplicacion,
                                     a.TZFACCE_DESC descrip_codigo,
                                     'TZFACCE' Fuente
                                    from TZFACCE a
                                    join tztprog b on b.pidm = a.TZFACCE_PIDM
                                    AND b.sp = (SELECT MAX (b1.sp)
                                                FROM tztprog b1
                                                WHERE b.pidm = b1.pidm)
                                    left join SZTCONE c on c.pidm  = a.TZFACCE_PIDM and c.COD_DETALLE = a.TZFACCE_DETAIL_CODE
                                                         And c.secuencia = (Select max (c1.secuencia)
                                                                            from SZTCONE c1
                                                                            Where c.pidm = c1.pidm
                                                                            And c.COD_DETALLE = c1.COD_DETALLE
                                                                            )
                                    where 1=1
                                    And b.estatus not in ('CP')
                                    And a.TZFACCE_SEC_PIDM = (select max (a1.TZFACCE_SEC_PIDM)
                                                                from TZFACCE a1
                                                                where a.TZFACCE_PIDM = a1.TZFACCE_PIDM
                                                                And a.TZFACCE_DETAIL_CODE = a1.TZFACCE_DETAIL_CODE
                                                             )
                                    and substr (a.TZFACCE_DETAIL_CODE,3,2) in ('HJ', 'XP', 'YR', 'YT',
                                                                               'B2', 'B3', '1A', 'IP',
                                                                               'AQ', 'AS', 'AX', 'FL',
                                                                               'HO','HM', 'HK', 'HP',
                                                                               'HN', 'AC', 'AD', 'AJ',
                                                                               'YX', 'CW', 'SY', 'TJ',
                                                                               'HW','ZU', 'WG')

                        ) loop

                                Begin
                                    insert into USER_MEMBRESIA values(cx.pidm,
                                                                      cx.matricula,
                                                                      cx.campus,
                                                                      cx.nivel,
                                                                      cx.programa,
                                                                      cx.Correo_Principal,
                                                                      cx.Correo_Alterno,
                                                                      cx.estatus,
                                                                      cx.Descrip_Estatus,
                                                                      cx.Codigo_detalle,
                                                                      cx.seq,
                                                                      cx.Estatus_Memb,
                                                                      cx.observaciones,
                                                                      cx.Fecha_Estatus,
                                                                      cx.Paquete,
                                                                      cx.origen,
                                                                      cx.sp,
                                                                      cx.orden_aplicacion,
                                                                      cx.descrip_codigo,
                                                                      cx.fuente,
                                                                      null,
                                                                      NULL);

                                Exception
                                    When Others then
                                        null;
                                End;

                                Commit;

                        end loop;

      Exception
        When Others then
            null;
      End;

    ---------------------------------------------------  Registros de TZTPADI  -----------------------------


      Begin

                For cx in (


                                Select
                                     b.pidm,
                                     b.matricula,
                                     b.campus,
                                     b.nivel,
                                     b.programa,
                                     nvl (trim (pkg_utilerias.f_correo(b.pidm, 'PRIN')),
                                     nvl (trim (pkg_utilerias.f_correo(b.pidm, 'UCAM')),
                                     trim (pkg_utilerias.f_correo(b.pidm, 'UTLX'))
                                     )) Correo_Principal,
                                     pkg_utilerias.f_correo(b.pidm, 'ALTE') Correo_Alterno,
                                     b.estatus,
                                     b.ESTATUS_D Descrip_Estatus,
                                     a.TZTPADI_DETAIL_CODE Codigo_detalle,
                                     a.TZTPADI_SEQNO Seq,
                                     decode (a.TZTPADI_FLAG,'0', 'A', '2', 'I', '1', 'I') Estatus_Memb,
                                     c.OBSERVACIONES Observaciones,
                                     nvl (a.TZTPADI_ACTIVITY_DATE,c.FECHA_SINCRO) Fecha_Estatus,
                                     PKG_UTILERIAS.f_paquete_programa(b.pidm, b.programa) Paquete,
                                     'Dinamico' origen,
                                     b.sp,
                                     5 orden_aplicacion,
                                     a.TZTPADI_DESC descrip_codigo,
                                     'TZTPADI' Fuente
                                    from TZTPADI a
                                    join tztprog b on b.pidm = a.TZTPADI_PIDM
                                    AND b.sp = (SELECT MAX (b1.sp)
                                                FROM tztprog b1
                                                WHERE b.pidm = b1.pidm)
                                    left join SZTCONE c on c.pidm  = a.TZTPADI_PIDM and c.COD_DETALLE = a.TZTPADI_DETAIL_CODE
                                                         And c.secuencia = (Select max (c1.secuencia)
                                                                            from SZTCONE c1
                                                                            Where c.pidm = c1.pidm
                                                                            And c.COD_DETALLE = c1.COD_DETALLE
                                                                            )
                                    where 1=1
                                    And b.estatus not in ('CP')
                                    And a.TZTPADI_SEQNO = (select max (a1.TZTPADI_SEQNO)
                                                                from TZTPADI a1
                                                                where a.TZTPADI_PIDM = a1.TZTPADI_PIDM
                                                                And a.TZTPADI_DETAIL_CODE = a1.TZTPADI_DETAIL_CODE
                                                             )
                                    and substr (a.TZTPADI_DETAIL_CODE,3,2) in ('HJ', 'XP', 'YR', 'YT',
                                                                               'B2', 'B3', '1A', 'IP',
                                                                               'AQ', 'AS', 'AX', 'FL',
                                                                               'HO','HM', 'HK', 'HP',
                                                                               'HN', 'AC', 'AD', 'AJ',
                                                                               'YX', 'CW', 'SY', 'TJ',
                                                                               'HW','ZU', 'WG')

                        ) loop

                                Begin
                                    insert into USER_MEMBRESIA values(cx.pidm,
                                                                      cx.matricula,
                                                                      cx.campus,
                                                                      cx.nivel,
                                                                      cx.programa,
                                                                      cx.Correo_Principal,
                                                                      cx.Correo_Alterno,
                                                                      cx.estatus,
                                                                      cx.Descrip_Estatus,
                                                                      cx.Codigo_detalle,
                                                                      cx.seq,
                                                                      cx.Estatus_Memb,
                                                                      cx.observaciones,
                                                                      cx.Fecha_Estatus,
                                                                      cx.Paquete,
                                                                      cx.origen,
                                                                      cx.sp,
                                                                      cx.orden_aplicacion,
                                                                      cx.descrip_codigo,
                                                                      cx.fuente,
                                                                      null,
                                                                      NULL);

                                Exception
                                    When Others then
                                        null;
                                End;

                                Commit;

                        end loop;

      Exception
        When Others then
            null;
      End;


    ---------------------------------------------------------
      Begin

            For cx in (

                        select distinct pidm, TZTCOTA_ACTIVITY, seq, programa, FECHA_ESTATUS, FECHA_SUSCRIPCION, CODIGO_DETALLE
                        from USER_MEMBRESIA
                        join TZTCOTA on TZTCOTA_PIDM = pidm and TZTCOTA_CODIGO = CODIGO_DETALLE and TZTCOTA_STATUS ='A'
                        where 1 = 1
                        And ESTATUS_MEMB = 'I'
                        And fuente ='TZTCOTA'

            ) loop

                    begin
                            update USER_MEMBRESIA
                            set FECHA_SUSCRIPCION = cx.TZTCOTA_ACTIVITY
                            Where pidm = cx.pidm
                            And seq = cx.seq
                            And programa = cx.programa;
                    Exception
                        When others then
                            null;

                    End;

                    Commit;

            End loop;

      Exception
        When Others then
            null;
      End;

      Begin

            For cx in (

                        select distinct pidm, trunc (TZTPADI_ACTIVITY_DATE) TZTPADI_ACTIVITY_DATE , seq, programa, FECHA_ESTATUS, FECHA_SUSCRIPCION, CODIGO_DETALLE
                        from USER_MEMBRESIA
                        join TZTPADI on TZTPADI_PIDM = pidm and TZTPADI_DETAIL_CODE = CODIGO_DETALLE and TZTPADI_FLAG =0
                        where 1 = 1
                        And ESTATUS_MEMB = 'I'
                        And fuente ='TZTPADI'
                      --  And pidm = 493478

            ) loop

                    begin
                            update USER_MEMBRESIA
                            set FECHA_SUSCRIPCION = cx.TZTPADI_ACTIVITY_DATE
                            Where pidm = cx.pidm
                            And seq = cx.seq
                            And programa = cx.programa;
                    Exception
                        When others then
                            null;

                    End;

                    Commit;

            End loop;

      Exception
        When Others then
            null;
      End;

      Begin

            For cx in (

                        select distinct pidm, TZFACCE_ACTIVITY_DATE, seq, programa, FECHA_ESTATUS, FECHA_SUSCRIPCION, TZFACCE_DETAIL_CODE
                        from USER_MEMBRESIA
                        join TZFACCE on TZFACCE_PIDM = pidm and TZFACCE_DETAIL_CODE = CODIGO_DETALLE --and TZFACCE_FLAG =0
                        where 1 = 1
                        And ESTATUS_MEMB = 'I'
                        And fuente ='TZFACCE'

            ) loop

                    begin
                            update USER_MEMBRESIA
                            set FECHA_SUSCRIPCION = cx.TZFACCE_ACTIVITY_DATE
                            Where pidm = cx.pidm
                            And seq = cx.seq
                            And programa = cx.programa;
                    Exception
                        When others then
                            null;

                    End;

                    Commit;

            End loop;

      Exception
        When Others then
            null;
      End;

      Begin

            For cx in (

                        select distinct pidm, b.SZTUTLX_ACTIVITY_DATE, seq, programa, FECHA_ESTATUS, FECHA_SUSCRIPCION
                        from USER_MEMBRESIA
                        join SZTUTLX b on b.SZTUTLX_PIDM = pidm and b.SZTUTLX_DISABLE_IND ='A'
                             And b.SZTUTLX_SEQ_NO = (select min (b1.SZTUTLX_SEQ_NO)
                                                       from SZTUTLX b1
                                                      Where b1.SZTUTLX_PIDM = b.SZTUTLX_PIDM
                                                    )
                        where 1 = 1
                        And ESTATUS_MEMB = 'I'
                        And fuente ='SZTUTLX'

            ) loop

                    begin
                            update USER_MEMBRESIA
                            set FECHA_SUSCRIPCION = cx.SZTUTLX_ACTIVITY_DATE
                            Where pidm = cx.pidm
                            And seq = cx.seq
                            And programa = cx.programa;
                    Exception
                        When others then
                            null;

                    End;

                    Commit;

            End loop;

      Exception
        When Others then
            null;
      End;




    Begin

         For cx in (

                    Select PIDM, CODIGO_DETALLE, SEQ, FECHA_ESTATUS
                    from USER_MEMBRESIA a
                    where FECHA_SUSCRIPCION is null

          ) loop

              Begin
                    Update USER_MEMBRESIA
                    set FECHA_SUSCRIPCION = cx.FECHA_ESTATUS
                    Where PIDM = cx.PIDM
                    And CODIGO_DETALLE = cx.CODIGO_DETALLE
                    And SEQ = cx.SEQ;
              Exception
                When Others then
                    null;
              End;

       end loop;
       Commit;

    End;

--------------------- Se registra la fecha del pago del primer registro del accesorio ---------------------------

    Begin 

        For cx in (

                    Select Distinct *
                    from USER_MEMBRESIA
                    
                    
                 ) loop
                 
                 
                    
                    For cx2 in (

                        Select distinct min (a.TBRAPPL_ACTIVITY_DATE) fecha_pago
                        from tbrappl a, tbraccd b
                        Where 1= 1 
                        And b.TBRACCD_PIDM = a.tbrappl_pidm
                        And a.TBRAPPL_CHG_TRAN_NUMBER = b.TBRACCD_TRAN_NUMBER
                        And a.TBRAPPL_REAPPL_IND is null
                        And b.tbraccd_pidm = Cx.pidm
                        and b.TBRACCD_DETAIL_CODE = cx.CODIGO_DETALLE
                        And a.TBRAPPL_PAY_TRAN_NUMBER in (select b1.TBRACCD_TRAN_NUMBER
                                                          from tbraccd b1
                                                          join TZTNCD c1 on c1.TZTNCD_CODE = b1.tbraccd_detail_code And c1.TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion', 'Financieras')
                                                          Where 1=1
                                                          And b1.tbraccd_pidm = a.tbrappl_pidm 
                                                          )
                    
                    ) loop
                    
                    
                            Begin
                            
                                    Update USER_MEMBRESIA
                                    set fecha_pago = cx2.fecha_pago
                                    Where pidm = cx.pidm
                                    And codigo_detalle = cx.codigo_detalle;
                             Exception
                                When Others then 
                                    null;
                            End;
                            
                    
                    End Loop;

                    
                    Commit;

             
        End Loop;
        Commit;
        
        
    End;    





  End P_REPORTE_USUARIO_UPSELLING;


PROCEDURE P_REPORTE_BITACORA_ESTATUS IS

BEGIN

---CREADO 30/05/2023
---BITACORA DE ESTATUS DE ALUMNOS
---CATY

 EXECUTE IMMEDIATE 'TRUNCATE TABLE SIU_CONN_BI.bitacora_estatus';
            commit;


----------------------MATRICULADO

Insert into SIU_CONN_BI.bitacora_estatus
With solicitud as (
    Select distinct SARADAP_PROGRAM_1, SARADAP_TERM_CODE_CTLG_1, SARADAP_TERM_CODE_ENTRY, SARADAP_APPL_NO, SARADAP_APST_CODE, saradap_pidm,SARADAP_APST_DATE
    from saradap
)
select  distinct
        a.campus,
        a.nivel,
        a.matricula,
         c.spriden_first_name||' '||c.spriden_last_name nombre_alumno,
        --a.estatus,
        'MA' estatus,
        'MATRICULADO' estatus_D,
        a.programa,
     --   a.fecha_inicio,
       -- a.sp ,
       -- decode(b.SARADAP_TERM_CODE_CTLG_1,null,d.SGBSTDN_TERM_CODE_CTLG_1,b.SARADAP_TERM_CODE_CTLG_1) Periodo_CTL,
         decode(s1.sorlcur_start_date,null,a.fecha_inicio,s1.sorlcur_start_date)  fecha_inicio,
         decode(s1.sorlcur_key_seqno,null,a.sp,s1.sorlcur_key_seqno) sp,
         decode(b.SARADAP_TERM_CODE_CTLG_1,null,s1.SORLCUR_TERM_CODE_CTLG,b.SARADAP_TERM_CODE_CTLG_1) Periodo_CTL,
         decode(b.SARADAP_TERM_CODE_ENTRY,null,SGBSTDN_TERM_CODE_MATRIC,b.SARADAP_TERM_CODE_ENTRY)Periodo_Matriculacion,
        --b.SARADAP_TERM_CODE_ENTRY Periodo_Matriculacion,
        decode(b.SARADAP_APPL_NO,null,a.sp,b.SARADAP_APPL_NO) No_Solicitud,
        nvl (trim (pkg_utilerias.f_correo(a.pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.pidm, 'UTLX')) )) Correo_Principal,
        pkg_utilerias.f_correo(a.pidm, 'ALTE') Correo_Alterno,
       -- pkg_utilerias.f_sarappd_fecha_decision(a.pidm, B.SARADAP_TERM_CODE_ENTRY,b.SARADAP_APPL_NO) Fecha_estatus,
        nvl(( Select distinct sarappd_apdc_date
            from SARAPPD ss
            Where sarappd_pidm = a.pidm
               AND sarappd_term_code_entry = b.SARADAP_TERM_CODE_ENTRY
               AND sarappd_appl_no = b.SARADAP_APPL_NO
             --  AND ss.sarappd_user != 'MIGRA_D'
               AND SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                        FROM SARAPPD s
                                        WHERE ss.sarappd_pidm = s.sarappd_pidm
                                              AND ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY
                                              AND ss.SARAPPD_APPL_NO = s.SARAPPD_APPL_NO
                                        )
        ),SARADAP_APST_DATE) Fecha_estatus,
       (
          Select distinct SARAPPD_APDC_CODE

          from SARAPPD ss
           Where sarappd_pidm = a.pidm
           AND sarappd_term_code_entry = b.SARADAP_TERM_CODE_ENTRY
           AND sarappd_appl_no = b.SARADAP_APPL_NO
         --  AND ss.sarappd_user != 'MIGRA_D'
           AND SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                 FROM SARAPPD s
                                 WHERE ss.sarappd_pidm = s.sarappd_pidm
                                      AND ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY
                                      AND ss.SARAPPD_APPL_NO = s.SARAPPD_APPL_NO
                                 )
      )desicion

from tztprog_All a
left join solicitud b on b.saradap_pidm = a.pidm and b.SARADAP_PROGRAM_1 = a.programa and b.SARADAP_APST_CODE ='A'
left join sgbstdn d on d.sgbstdn_pidm=a.pidm and d.SGBSTDN_PROGRAM_1=a.programa
left join sorlcur S1 on S1.sorlcur_pidm=a.pidm and S1.SORLCUR_LMOD_CODE='LEARNER' AND S1.SORLCUR_PROGRAM=a.programa AND S1.SORLCUR_TERM_CODE=b.SARADAP_TERM_CODE_ENTRY
join spriden c on c.spriden_pidm = a.pidm and c.spriden_change_ind is null
where 1= 1
--And a.matricula IN ( '010010899')--And a.matricula IN ( '010017225', '010022857','010000454')
and a.sp = (select max (a1.sp)
            from tztprog_All a1
            Where a.pidm = a1.pidm
            And a.programa = a1.programa);

commit;

----------------------- TODOS LOS ESTATUS EXCEPTO MA
Insert into SIU_CONN_BI.bitacora_estatus
With solicitud as (
     Select distinct SARADAP_PROGRAM_1, SARADAP_TERM_CODE_CTLG_1, SARADAP_TERM_CODE_ENTRY, SARADAP_APPL_NO, SARADAP_APST_CODE, saradap_pidm
    from saradap
)
select distinct
                        a.campus campus,
                        a.nivel nivel,
                        a.matricula matricula,
                         b.spriden_first_name||' '||spriden_last_name nombre_alumno,
                        a.estatus,
                        a.estatus_D,
                        a.programa,
                        a.fecha_inicio,
                        a.sp study_path,
                        decode(d.SARADAP_TERM_CODE_CTLG_1,null,a.ctlg,d.SARADAP_TERM_CODE_CTLG_1) Periodo_CTL,
                        decode(d.SARADAP_TERM_CODE_ENTRY,null,SGBSTDN_TERM_CODE_MATRIC,d.SARADAP_TERM_CODE_ENTRY) Periodo_Matriculacion,
                        decode(d.SARADAP_APPL_NO,null,a.sp,d.SARADAP_APPL_NO) No_Solicitud,
                        pkg_utilerias.f_correo(a.pidm,'PRIN')correo_prin,
                        pkg_utilerias.f_correo(a.pidm,'ALTE')correo_secu,
                       -- pkg_utilerias.f_sarappd_fecha_decision(a.pidm, d.SARADAP_TERM_CODE_ENTRY,d.SARADAP_APPL_NO) Fecha_estatus,
                        decode(SGBSTDN_ACTIVITY_DATE,null, a.fecha_mov,SGBSTDN_ACTIVITY_DATE) Fecha_estatus,
                        (
                              Select distinct SARAPPD_APDC_CODE

                                from SARAPPD ss
                               Where sarappd_pidm = a.pidm
                               AND sarappd_term_code_entry =decode( d.SARADAP_TERM_CODE_ENTRY,null,S1.SORLCUR_TERM_CODE,d.SARADAP_TERM_CODE_ENTRY)
                               AND sarappd_appl_no = decode(d.SARADAP_APPL_NO,null,a.sp,d.SARADAP_APPL_NO)--d.SARADAP_APPL_NO
                             --  AND ss.sarappd_user != 'MIGRA_D'
                               AND SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                                     FROM SARAPPD s
                                                     WHERE ss.sarappd_pidm = s.sarappd_pidm
                                                          AND ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY
                                                          AND ss.SARAPPD_APPL_NO = s.SARAPPD_APPL_NO
                                                     )
                        )desicion

--select *
from tztprog_all a
left join solicitud d on d.saradap_pidm = a.pidm and d.SARADAP_PROGRAM_1 = a.programa and d.SARADAP_APST_CODE ='A' and d.SARADAP_TERM_CODE_ENTRY=a.matriculacion
left join sgbstdn on SGBSTDN_PIDM=a.pidm and  SGBSTDN_STST_CODE=a.estatus and  SGBSTDN_PROGRAM_1=a.programa
left join sorlcur S1 on S1.sorlcur_pidm=a.pidm and S1.SORLCUR_LMOD_CODE='LEARNER' AND S1.SORLCUR_PROGRAM=a.programa AND S1.SORLCUR_TERM_CODE=d.SARADAP_TERM_CODE_ENTRY
join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
--left join decision1 des on des.pidm=a.pidm

where  1= 1
/*and a.sp in (select max(f.sp)
                from tztprog_all f
                where f.pidm=a.pidm
                and f.programa=a.programa)*/
  and a.estatus <> 'MA'
--     And a.matricula IN ( '010010899')
;

commit;

--and a.estatus like 'B%' --'EG'
--And a.matricula IN ( '010022857')
--And a.campus in ('UTL')
--And a.matricula IN ( '010017225', '010022857','010000454');

-----Inserta estatus BI que no estan en tztprog se obtiene de sgrscmt

Insert into SIU_CONN_BI.bitacora_estatus
 With solicitud as (
    Select distinct SARADAP_PROGRAM_1, SARADAP_TERM_CODE_CTLG_1, SARADAP_TERM_CODE_ENTRY, SARADAP_APPL_NO, SARADAP_APST_CODE, saradap_pidm,SARADAP_APST_DATE
    from saradap
)
              select
               distinct
                        a.campus,
                        a.nivel,
                        a.matricula,
                         c.spriden_first_name||' '||c.spriden_last_name nombre_alumno,
                        --a.estatus,
                        'BI' estatus,
                        'BAJA INACTIVO' estatus_D,
                        a.programa,
                        a.fecha_inicio,
                        a.sp ,
                        decode(b.SARADAP_TERM_CODE_CTLG_1,null,d.SGBSTDN_TERM_CODE_CTLG_1,b.SARADAP_TERM_CODE_CTLG_1) Periodo_CTL,
                         decode(b.SARADAP_TERM_CODE_ENTRY,null,e.SGBSTDN_TERM_CODE_MATRIC,b.SARADAP_TERM_CODE_ENTRY)Periodo_Matriculacion,
                        --b.SARADAP_TERM_CODE_ENTRY Periodo_Matriculacion,
                        decode(b.SARADAP_APPL_NO,null,a.sp,b.SARADAP_APPL_NO) No_Solicitud,
                        nvl (trim (pkg_utilerias.f_correo(a.pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.pidm, 'UTLX')) )) Correo_Principal,
                        pkg_utilerias.f_correo(a.pidm, 'ALTE') Correo_Alterno,
                       -- pkg_utilerias.f_sarappd_fecha_decision(a.pidm, B.SARADAP_TERM_CODE_ENTRY,b.SARADAP_APPL_NO) Fecha_estatus,
                        nvl(SGRSCMT_ACTIVITY_DATE,SARADAP_APST_DATE) Fecha_estatus,
                       (
                          Select distinct SARAPPD_APDC_CODE

                          from SARAPPD ss
                           Where sarappd_pidm = a.pidm
                           AND sarappd_term_code_entry = b.SARADAP_TERM_CODE_ENTRY
                           AND sarappd_appl_no = b.SARADAP_APPL_NO
                         --  AND ss.sarappd_user != 'MIGRA_D'
                           AND SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                                 FROM SARAPPD s
                                                 WHERE ss.sarappd_pidm = s.sarappd_pidm
                                                      AND ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY
                                                      AND ss.SARAPPD_APPL_NO = s.SARAPPD_APPL_NO
                                                 )
                      )desicion

              from
              tztprog_all a

              left join solicitud b on b.saradap_pidm = a.pidm and b.SARADAP_PROGRAM_1 = a.programa and b.SARADAP_APST_CODE ='A'
              left join sgbstdn e on SGBSTDN_PIDM=a.pidm and  e.SGBSTDN_STST_CODE=a.estatus and  e.SGBSTDN_PROGRAM_1=a.programa
              left join sgbstdn d on d.sgbstdn_pidm=a.pidm and d.SGBSTDN_PROGRAM_1=a.programa
              join spriden c on c.spriden_pidm = a.pidm and c.spriden_change_ind is null
               inner join
              sgrscmt on pidm=sgrscmt_pidm AND b.SARADAP_APPL_NO=sgrscmt_seq_no and sgrscmt_seq_no in (select sgrscmt_seq_no from sgrscmt
              left join sorlcur on sorlcur_pidm=sgrscmt_pidm and SORLCUR_KEY_SEQNO=sgrscmt.sgrscmt_seq_no
              where sgrscmt_comment_text like '%ESTATUS ANTERIOR BI%'-- and estatus<>'BI'
           --   and sgrscmt_pidm=fget_pidm('010000901')
              and sgrscmt_pidm=a.pidm
              and SORLCUR_CACT_CODE='INACTIVE' and SORLCUR_PROGRAM=a.programa)
              where sgrscmt_comment_text like '%ESTATUS ANTERIOR BI%' and estatus<>'BI'
            --  and sgrscmt_pidm=fget_pidm('010010899')
              and a.sp in (select max(f.sp)
                from tztprog_all f
                where f.pidm=a.pidm
                and f.programa=a.programa)
              order by matricula;

 commit;

----



---Rellena periodo catalogo en nulo
begin
for c in(
        select
                matricula,
                programa,
                sp,
                periodo_ctl
        from
                SIU_CONN_BI.bitacora_estatus
        where
                periodo_matriculacion is null and matricula in
                (select matricula from tztprog_all where matriculacion is not null)
     )loop


     --Actualiza periodo_matriculacion
     update
            SIU_CONN_BI.bitacora_estatus
     set
            periodo_matriculacion= (select distinct
                                        MATRICULACION
                                    from TZTPROG_ALL
                                    where
                                            PIDM=fget_pidm(c.matricula)
                                        and PROGRAMA=c.programa
                                        and CTLG=c.periodo_ctl
                                        and sp=c.sp
                                       )
     where
                matricula=c.matricula
         and    programa=c.programa and sp=c.sp
         and    periodo_matriculacion is null;
    --       DBMS_OUTPUT.PUT_LINE ( c.matricula  );
     end loop;
     commit;
end;

---Rellena periodo catalogo
begin
for c in(
        select
                matricula,
                programa,
                sp,
                periodo_ctl
        from
                SIU_CONN_BI.bitacora_estatus
        where
                periodo_ctl is null and matricula in
                (select matricula from tztprog_all where ctlg is not null)
     )loop


     --Actualiza periodo_matriculacion
     update
            SIU_CONN_BI.bitacora_estatus
     set
            periodo_ctl= (select distinct
                                        ctlg
                                    from TZTPROG_ALL
                                    where
                                            PIDM=fget_pidm(c.matricula)
                                        and PROGRAMA=c.programa
                                        and sp=c.sp
                                        and estatus='MA'

                                       -- and CTLG=c.periodo_ctl
                                       )
     where
                matricula=c.matricula
         and    programa=c.programa and sp=c.sp
         and    periodo_ctl is null;
        --  DBMS_OUTPUT.PUT_LINE ( c.matricula  );
     end loop;

 commit;
 end;

 /*
 begin

for c in(

select matricula,estatus,no_solicitud,fecha_estatus,desicion,desicion1
from
(select matricula,estatus,no_solicitud, fecha_estatus,desicion,
  (Select distinct SARAPPD_APDC_CODE

                                from SARAPPD ss
                               Where sarappd_pidm = fget_pidm(matricula)
                             --  AND sarappd_term_code_entry = d.SARADAP_TERM_CODE_ENTRY
                               AND sarappd_appl_no = no_solicitud--d.SARADAP_APPL_NO
                             --  AND ss.sarappd_user != 'MIGRA_D'
                               AND SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                                     FROM SARAPPD s
                                                     WHERE ss.sarappd_pidm = s.sarappd_pidm
                                                          AND ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY
                                                          AND ss.SARAPPD_APPL_NO = s.SARAPPD_APPL_NO
                                                     ))desicion1
from SIU_CONN_BI.bitacora_estatus where desicion is null)
where desicion1 is not null

     )loop


 update SIU_CONN_BI.bitacora_estatus set desicion=c.desicion1
        where matricula=c.matricula
         and  no_solicitud=c.no_solicitud
         and desicion is null;


 end loop;
--commit;
     end;
     */
  begin
     update SIU_CONN_BI.bitacora_estatus set desicion=35 where desicion  is null;
  end;

commit;
END  P_REPORTE_BITACORA_ESTATUS;

PROCEDURE P_REPORTE_USUARIO_UPSELLING_ALL IS

    p_pidm number;
    -------- SSB ------
    vl_monto number:=0;
    vl_porcentaje number:=0;
    vl_monto_Descuento number:=0;
    vl_Fecha varchar2(12):= null;
    -------- PAquete Fijo ------
    vl_codigo_Desc varchar2(4):= null;
    vl_porc_desc number := 0;
    vl_monto_Desc number:=0;
    vl_codigo_Descrip varchar2(50):= null;
    vl_moneda varchar2(10):= null;
    vl_cod_desc_Descrip varchar2(50):= null;
    ----------- Generacion de cargos ----------
    vl_existe_cargo number:=0;
    VL_DIA VARCHAR2(2);
    VL_MES VARCHAR2(2);
    VL_ANO VARCHAR2(4);
    vl_orden NUMBER:= null;
    vl_codigo_cargo varchar2(4):= null;
    VL_VENCIMIENTO VARCHAR2(15);
    VL_SECUENCIA number:=0;
    VL_SEC_CARGO number:=0;
    VL_VENCIMIENTO_ssb VARCHAR2(15);
    vl_secuencia_ssb number:=0;
    vl_existe_cartera number:=0;
    vl_salida varchar2(250):= null;
    vl_fecha_ret date;
    vl_inserto number:=0;


  Begin


    EXECUTE IMMEDIATE 'TRUNCATE TABLE SIU_CONN_BI.USER_MEMBRESIA_ALL';
    commit;



    For cx in (


                            SELECT DISTINCT
                                 A.pidm,
                                 a.matricula,
                                 a.campus,
                                 a.nivel,
                                 a.programa,
                                 nvl (trim (pkg_utilerias.f_correo(a.pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.pidm, 'UTLX')) )) Correo_Principal,
                                 pkg_utilerias.f_correo(a.pidm, 'ALTE') Correo_Alterno,
                                 a.estatus,
                                 a.ESTATUS_D Descrip_Estatus,
                                 b.SZTUTLX_SEQ_NO Seq,
                                 b.SZTUTLX_DISABLE_IND Estatus_Memb,
                                 b.SZTUTLX_OBS Observaciones,
                                 b.SZTUTLX_ACTIVITY_DATE Fecha_Estatus,
                                 PKG_UTILERIAS.f_paquete_programa(a.pidm, a.programa) Paquete,
                                 a.sp,
                                 'SZTUTLX' Fuente
                            FROM tztprog a
                                 JOIN SZTUTLX b ON     b.SZTUTLX_PIDM = a.pidm
                                       AND b.SZTUTLX_STAT_IND IN ('1', '2')
                           WHERE     1 = 1
                           And a.estatus not in ('CP')
                           AND a.sp = (SELECT MAX (a1.sp)
                                        FROM tztprog a1
                                        WHERE a.pidm = a1.pidm)
                            Order by 1
      ) loop


            vl_inserto:=0;
            --------------- Busco los valores para el AutoServicio ----------------
        Begin
            select a.monto, a.PORCENTAJE, a.MONTODESCUENTO, a.FECHA_STATUS
                Into vl_monto, vl_porcentaje, vl_monto_Descuento, vl_Fecha
            from SZRVSSB a
            where 1= 1
            And a.ESTATUS_SOLC = 'CONCLUIDO'
            And a.COD_SERVICIO = 'UTLX'
            And a.Matricula = cx.matricula
            And a.Campus = cx.campus
            And a.nivel  = cx.nivel
            And to_number(a.SEQ_NO) = (select maX(to_number(a1.SEQ_NO))
                               from SZRVSSB a1
                               Where a.Matricula = a1.Matricula
                               And a.COD_SERVICIO = a1.COD_SERVICIO
                               );
        Exception
            When Others then
                vl_monto:=null;
                vl_porcentaje:=null;
                vl_monto_Descuento:=null;
        End;

        If vl_monto >=0 then --------- Registro por SSB
           vl_codigo_Descrip:= null;
           vl_moneda := null;

           Begin
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'NA';
           Exception
            When Others then
              vl_codigo_Descrip:= null;
              vl_moneda:= null;
           End;

           Begin
                Insert into USER_MEMBRESIA_ALL values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.correo_principal,
                                                cx.correo_alterno,
                                                cx.ESTATUS,
                                                cx.DESCRIP_ESTATUS,
                                                substr (cx.matricula,1,2) ||'NA', ---> SSB
                                                cx.seq,
                                                cx.ESTATUS_MEMB,
                                                cx.OBSERVACIONES,
                                                cx.FECHA_ESTATUS,
                                                cx.paquete,
                                                'SSB',
                                                cx.sp,
                                                1,
                                                vl_codigo_Descrip,
                                                cx.fuente,
                                                null
                                                );
                   vl_inserto:=1;
           Exception
            When Others then
                 DBMS_OUTPUT.PUT_LINE('salida'||sqlerrm );
                 vl_inserto:=0;
           End;


        End if;

        ---------------------------- Se buscan los registros de paquete fijo ------------------

        vl_monto:=0;
        vl_porcentaje:=0;
        vl_monto_Descuento:=0;
        vl_codigo_Desc:= null;
        vl_porc_desc:=0;
        vl_monto_Desc:=0;

        Begin

            Select TZFACCE_AMOUNT
                Into vl_monto
            from TZFACCE a
            Where 1=1
            and a.TZFACCE_PIDM = cx.pidm
             and substr (a.TZFACCE_DETAIL_CODE, 3,2) in ('QI', 'QG')
             And a.TZFACCE_SEC_PIDM = (select max (a1.TZFACCE_SEC_PIDM)
                                        from TZFACCE a1
                                        Where a.TZFACCE_pidm  = a1.TZFACCE_pidm
                                        And a.TZFACCE_DETAIL_CODE = a1.TZFACCE_DETAIL_CODE

                                        );
        Exception
            When Others then
               vl_monto:=null;

        End;

        Begin

        select SWTMDAC_DETAIL_CODE_DESC , SWTMDAC_PERCENT_DESC, (nvl (vl_monto,0)*SWTMDAC_PERCENT_DESC/100) monto_desc
            into vl_codigo_Desc, vl_porc_desc, vl_monto_Desc
        from SWTMDAC a
        where 1= 1
        And a.SWTMDAC_PIDM = cx.pidm
        and substr (a.SWTMDAC_DETAIL_CODE_ACC, 3,2) in ('QI', 'QG')
        And a.SWTMDAC_SEC_PIDM = (select max (a1.SWTMDAC_SEC_PIDM)
                                  from SWTMDAC a1
                                  Where 1 = 1
                                  And a.SWTMDAC_PIDM = a1.SWTMDAC_PIDM
                                  And a.SWTMDAC_DETAIL_CODE_ACC = a1.SWTMDAC_DETAIL_CODE_ACC);
        Exception
            When Others then
              vl_codigo_Desc := null;
              vl_porc_desc := 0;
              vl_monto_Desc :=0;
        End;

        If vl_monto_Desc = 0 then

            Begin
                select SWTMDAC_AMOUNT_DESC
                    into vl_monto_Desc
                from SWTMDAC a
                where 1= 1
                And a.SWTMDAC_PIDM = cx.pidm
                and substr (a.SWTMDAC_DETAIL_CODE_ACC, 3,2) in ('QI', 'QG')
                And a.SWTMDAC_SEC_PIDM = (select max (a1.SWTMDAC_SEC_PIDM)
                                          from SWTMDAC a1
                                          Where 1 = 1
                                          And a.SWTMDAC_PIDM = a1.SWTMDAC_PIDM
                                          And a.SWTMDAC_DETAIL_CODE_ACC = a1.SWTMDAC_DETAIL_CODE_ACC);
            Exception
                When Others then
                  vl_codigo_Desc := null;
                  vl_porc_desc := 0;
                  vl_monto_Desc :=0;
            End;
        End if;


        If vl_monto >=0 and vl_inserto = 0 then --------- Registro por Fijo
           vl_codigo_Descrip:= null;
           vl_moneda:= null;
           vl_cod_desc_Descrip:= null;

           Begin
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'QI';
           Exception
            When Others then
              vl_codigo_Descrip:= null;
              vl_moneda:= null;
           End;

           Begin
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_cod_desc_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = vl_codigo_Desc;
           Exception
            When Others then
              vl_cod_desc_Descrip:= null;
              vl_moneda:= null;
           End;




           Begin
                Insert into USER_MEMBRESIA_ALL values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.correo_principal,
                                                cx.correo_alterno,
                                                cx.ESTATUS,
                                                cx.DESCRIP_ESTATUS,
                                                substr (cx.matricula,1,2) ||'QI', ----Paquete Fijo
                                                cx.seq,
                                                cx.ESTATUS_MEMB,
                                                cx.OBSERVACIONES,
                                                cx.FECHA_ESTATUS,
                                                cx.paquete,
                                                'FJO',
                                                cx.sp,
                                                2,
                                                vl_codigo_Descrip,
                                                cx.fuente,
                                                null
                                                );
              vl_inserto:=1;
           Exception
            When Others then
                 DBMS_OUTPUT.PUT_LINE('salida'||sqlerrm );
                 vl_inserto:=0;
           End;


        End if;


        ---------------------------- Se buscan los registros de paquete Dinamico ------------------
        vl_monto:=0;
        vl_codigo_Desc:= null;
        vl_monto_Desc:=null;


        Begin
            Select distinct  TZTPADI_AMOUNT
                Into vl_monto
            from tztpadi a
            where 1= 1
            and a.TZTPADI_PIDM = cx.pidm
            and substr (a.TZTPADI_DETAIL_CODE, 3,2) in ('QI','QG')
            And a.TZTPADI_FLAG = 0
            And a.TZTPADI_SEQNO = (select max (a1.TZTPADI_SEQNO)
                                    from TZTPADI a1
                                    Where a.TZTPADI_PIDM = a1.TZTPADI_PIDM
                                    And a.TZTPADI_DETAIL_CODE = a1.TZTPADI_DETAIL_CODE
                                    And a.TZTPADI_FLAG = a1.TZTPADI_FLAG
                                    ) ;
        Exception
            When Others then
             vl_monto:=null;
        End;

        If vl_monto >=0 and vl_inserto = 0 then --------- Registro por Dinamico
           vl_codigo_Descrip:= null;
           vl_moneda:= null;
           vl_cod_desc_Descrip:= null;

           Begin
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'QI';
           Exception
            When Others then
              vl_codigo_Descrip:= null;
              vl_moneda:= null;
           End;


           Begin
                Insert into USER_MEMBRESIA_ALL values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.correo_principal,
                                                cx.correo_alterno,
                                                cx.ESTATUS,
                                                cx.DESCRIP_ESTATUS,
                                                substr (cx.matricula,1,2) ||'QI', ----Paquete Fijo
                                                cx.seq,
                                                cx.ESTATUS_MEMB,
                                                cx.OBSERVACIONES,
                                                cx.FECHA_ESTATUS,
                                                cx.paquete,
                                                'Dinamico',
                                                cx.sp,
                                                3,
                                                vl_codigo_Descrip,
                                                cx.fuente,
                                                null
                                                );
               vl_inserto:=1;
           Exception
            When Others then
                 DBMS_OUTPUT.PUT_LINE('salida'||sqlerrm );
                 vl_inserto:=0;
           End;



        End if;

        If vl_monto is null and vl_inserto = 0 then
           vl_monto:=0;

           vl_codigo_Descrip:= null;
           vl_moneda:= null;
           vl_cod_desc_Descrip:= null;

           Begin
                 SELECT TBBDETC_DESC, TVRDCTX_CURR_CODE
                     Into vl_codigo_Descrip, vl_moneda
                 FROM TBBDETC
                 join TVRDCTX on TVRDCTX_DETC_CODE = TBBDETC_DETAIL_CODE
                 WHERE TBBDETC_DETAIL_CODE = substr (cx.matricula,1,2) ||'QI';
           Exception
            When Others then
              vl_codigo_Descrip:= null;
              vl_moneda:= null;
           End;


           Begin
                Insert into USER_MEMBRESIA_ALL values (cx.pidm,
                                                cx.matricula,
                                                cx.campus,
                                                cx.nivel,
                                                cx.programa,
                                                cx.correo_principal,
                                                cx.correo_alterno,
                                                cx.ESTATUS,
                                                cx.DESCRIP_ESTATUS,
                                                substr (cx.matricula,1,2) ||'QI', ----Paquete Fijo
                                                cx.seq,
                                                cx.ESTATUS_MEMB,
                                                cx.OBSERVACIONES,
                                                cx.FECHA_ESTATUS,
                                                cx.paquete,
                                                'No_Definido',
                                                cx.sp,
                                                4,
                                                vl_codigo_Descrip,
                                                cx.fuente,
                                                null
                                                );
           Exception
            When Others then
                 DBMS_OUTPUT.PUT_LINE('salida No_Definido'||sqlerrm );
           End;


        End if;

        Commit;


     End loop;
      Commit;
      

      ----------------------------------------  Inserta los registros de SSB de COTA ---------------------------------
      Begin
                       Insert into USER_MEMBRESIA_ALL
                             SELECT DISTINCT
                                 A.pidm,
                                 a.matricula,
                                 a.campus,
                                 a.nivel,
                                 a.programa,
                                 nvl (trim (pkg_utilerias.f_correo(a.pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.pidm, 'UTLX')) )) Correo_Principal,
                                 pkg_utilerias.f_correo(a.pidm, 'ALTE') Correo_Alterno,
                                 a.estatus,
                                 a.ESTATUS_D Descrip_Estatus,
                                 b.TZTCOTA_CODIGO Codigo_detalle,
                                 b.TZTCOTA_SEQNO Seq,
                                 b.TZTCOTA_STATUS Estatus_Memb,
                                 b.TZTCOTA_OBSERVACIONES Observaciones,
                                 b.TZTCOTA_ACTIVITY Fecha_Estatus,
                                 PKG_UTILERIAS.f_paquete_programa(a.pidm, a.programa) Paquete,
                                 'SSB' origen,
                                 a.sp,
                                 4 orden_aplicacion,
                                 c.tbbdetc_Desc descrip_codigo,
                                 'TZTCOTA' Fuente,
                                 null
                            FROM tztprog a
                            JOIN tztcota b ON b.TZTCOTA_PIDM = a.pidm
                           join tbbdetc c on c.tbbdetc_detail_code = b.TZTCOTA_CODIGO
                           WHERE     1 = 1
                           And a.estatus not in ('CP')
                           AND a.sp = (SELECT MAX (a1.sp)
                                        FROM tztprog a1
                                        WHERE a.pidm = a1.pidm)
                         --   And a.matricula = '010002238'
                            Order by 1;
                            Commit;
      Exception
        When Others then
            null;
      End;      
      
      
      ---------------------------------------------------  Registros de TZFACCE  -----------------------------
      Begin

                For cx in (

                                Select
                                     b.pidm,
                                     b.matricula,
                                     b.campus,
                                     b.nivel,
                                     b.programa,
                                     nvl (trim (pkg_utilerias.f_correo(b.pidm, 'PRIN')),
                                     nvl (trim (pkg_utilerias.f_correo(b.pidm, 'UCAM')),
                                     trim (pkg_utilerias.f_correo(b.pidm, 'UTLX'))
                                     )) Correo_Principal,
                                     pkg_utilerias.f_correo(b.pidm, 'ALTE') Correo_Alterno,
                                     b.estatus,
                                     b.ESTATUS_D Descrip_Estatus,
                                     a.TZFACCE_DETAIL_CODE Codigo_detalle,
                                     a.TZFACCE_SEC_PIDM Seq,
                                     decode (a.TZFACCE_FLAG,'0', 'A', '2', 'I', '1', 'I') Estatus_Memb,
                                     c.OBSERVACIONES Observaciones,
                                     nvl (a.TZFACCE_ACTIVITY_DATE,c.FECHA_SINCRO) Fecha_Estatus,
                                     PKG_UTILERIAS.f_paquete_programa(b.pidm, b.programa) Paquete,
                                     'FIJO' origen,
                                     b.sp,
                                     5 orden_aplicacion,
                                     a.TZFACCE_DESC descrip_codigo,
                                     'TZFACCE' Fuente
                                    from TZFACCE a
                                    join tztprog b on b.pidm = a.TZFACCE_PIDM
                                    AND b.sp = (SELECT MAX (b1.sp)
                                                FROM tztprog b1
                                                WHERE b.pidm = b1.pidm)
                                    left join SZTCONE c on c.pidm  = a.TZFACCE_PIDM and c.COD_DETALLE = a.TZFACCE_DETAIL_CODE
                                                         And c.secuencia = (Select max (c1.secuencia)
                                                                            from SZTCONE c1
                                                                            Where c.pidm = c1.pidm
                                                                            And c.COD_DETALLE = c1.COD_DETALLE
                                                                            )
                                    where 1=1
                                    And b.estatus not in ('CP')
                                    and substr (a.TZFACCE_DETAIL_CODE,3,2) in ('HJ', 'XP', 'YR', 'YT',
                                                                               'B2', 'B3', '1A', 'IP',
                                                                               'AQ', 'AS', 'AX', 'FL',
                                                                               'HO','HM', 'HK', 'HP',
                                                                               'HN', 'AC', 'AD', 'AJ',
                                                                               'YX', 'CW', 'SY', 'TJ',
                                                                               'HW','ZU', 'WG')

                        ) loop

                                Begin
                                    insert into USER_MEMBRESIA_ALL values(cx.pidm,
                                                                      cx.matricula,
                                                                      cx.campus,
                                                                      cx.nivel,
                                                                      cx.programa,
                                                                      cx.Correo_Principal,
                                                                      cx.Correo_Alterno,
                                                                      cx.estatus,
                                                                      cx.Descrip_Estatus,
                                                                      cx.Codigo_detalle,
                                                                      cx.seq,
                                                                      cx.Estatus_Memb,
                                                                      cx.observaciones,
                                                                      cx.Fecha_Estatus,
                                                                      cx.Paquete,
                                                                      cx.origen,
                                                                      cx.sp,
                                                                      cx.orden_aplicacion,
                                                                      cx.descrip_codigo,
                                                                      cx.fuente,
                                                                      null);

                                Exception
                                    When Others then
                                        null;
                                End;

                        end loop;
                         Commit;

      Exception
        When Others then
            null;
      End;      
      
   ---------------------------------------------------  Registros de TZTPADI  -----------------------------

      Begin

                For cx in (


                                Select
                                     b.pidm,
                                     b.matricula,
                                     b.campus,
                                     b.nivel,
                                     b.programa,
                                     nvl (trim (pkg_utilerias.f_correo(b.pidm, 'PRIN')),
                                     nvl (trim (pkg_utilerias.f_correo(b.pidm, 'UCAM')),
                                     trim (pkg_utilerias.f_correo(b.pidm, 'UTLX'))
                                     )) Correo_Principal,
                                     pkg_utilerias.f_correo(b.pidm, 'ALTE') Correo_Alterno,
                                     b.estatus,
                                     b.ESTATUS_D Descrip_Estatus,
                                     a.TZTPADI_DETAIL_CODE Codigo_detalle,
                                     a.TZTPADI_SEQNO Seq,
                                     decode (a.TZTPADI_FLAG,'0', 'A', '2', 'I', '1', 'I') Estatus_Memb,
                                     c.OBSERVACIONES Observaciones,
                                     nvl (a.TZTPADI_ACTIVITY_DATE,c.FECHA_SINCRO) Fecha_Estatus,
                                     PKG_UTILERIAS.f_paquete_programa(b.pidm, b.programa) Paquete,
                                     'Dinamico' origen,
                                     b.sp,
                                     5 orden_aplicacion,
                                     a.TZTPADI_DESC descrip_codigo,
                                     'TZTPADI' Fuente
                                    from TZTPADI a
                                    join tztprog b on b.pidm = a.TZTPADI_PIDM
                                    AND b.sp = (SELECT MAX (b1.sp)
                                                FROM tztprog b1
                                                WHERE b.pidm = b1.pidm)
                                    left join SZTCONE c on c.pidm  = a.TZTPADI_PIDM and c.COD_DETALLE = a.TZTPADI_DETAIL_CODE
                                                         And c.secuencia = (Select max (c1.secuencia)
                                                                            from SZTCONE c1
                                                                            Where c.pidm = c1.pidm
                                                                            And c.COD_DETALLE = c1.COD_DETALLE
                                                                            )
                                    where 1=1
                                    And b.estatus not in ('CP')
                                    and substr (a.TZTPADI_DETAIL_CODE,3,2) in ('HJ', 'XP', 'YR', 'YT',
                                                                               'B2', 'B3', '1A', 'IP',
                                                                               'AQ', 'AS', 'AX', 'FL',
                                                                               'HO','HM', 'HK', 'HP',
                                                                               'HN', 'AC', 'AD', 'AJ',
                                                                               'YX', 'CW', 'SY', 'TJ',
                                                                               'HW','ZU', 'WG')

                        ) loop

                                Begin
                                    insert into USER_MEMBRESIA_ALL values(cx.pidm,
                                                                      cx.matricula,
                                                                      cx.campus,
                                                                      cx.nivel,
                                                                      cx.programa,
                                                                      cx.Correo_Principal,
                                                                      cx.Correo_Alterno,
                                                                      cx.estatus,
                                                                      cx.Descrip_Estatus,
                                                                      cx.Codigo_detalle,
                                                                      cx.seq,
                                                                      cx.Estatus_Memb,
                                                                      cx.observaciones,
                                                                      cx.Fecha_Estatus,
                                                                      cx.Paquete,
                                                                      cx.origen,
                                                                      cx.sp,
                                                                      cx.orden_aplicacion,
                                                                      cx.descrip_codigo,
                                                                      cx.fuente,
                                                                      null);

                                Exception
                                    When Others then
                                        null;
                                End;

                                Commit;

                        end loop;

      Exception
        When Others then
            null;
      End;      
      
      
    ---------------------------------------------------------
      Begin

            For cx in (

                        select distinct pidm, TZTCOTA_ACTIVITY, seq, programa, FECHA_ESTATUS, FECHA_SUSCRIPCION, CODIGO_DETALLE
                        from USER_MEMBRESIA_ALL
                        join TZTCOTA on TZTCOTA_PIDM = pidm and TZTCOTA_CODIGO = CODIGO_DETALLE and TZTCOTA_STATUS ='A'
                        where 1 = 1
                        And ESTATUS_MEMB = 'I'
                        And fuente ='TZTCOTA'

            ) loop

                    begin
                            update USER_MEMBRESIA_ALL
                            set FECHA_SUSCRIPCION = cx.TZTCOTA_ACTIVITY
                            Where pidm = cx.pidm
                            And seq = cx.seq
                            And programa = cx.programa;
                    Exception
                        When others then
                            null;

                    End;

                    Commit;

            End loop;

      Exception
        When Others then
            null;
      End;      
      
      
      Begin

            For cx in (

                        select distinct pidm, trunc (TZTPADI_ACTIVITY_DATE) TZTPADI_ACTIVITY_DATE , seq, programa, FECHA_ESTATUS, FECHA_SUSCRIPCION, CODIGO_DETALLE
                        from USER_MEMBRESIA_ALL
                        join TZTPADI on TZTPADI_PIDM = pidm and TZTPADI_DETAIL_CODE = CODIGO_DETALLE and TZTPADI_FLAG =0
                        where 1 = 1
                        And ESTATUS_MEMB = 'I'
                        And fuente ='TZTPADI'
                      --  And pidm = 493478

            ) loop

                    begin
                            update USER_MEMBRESIA_ALL
                            set FECHA_SUSCRIPCION = cx.TZTPADI_ACTIVITY_DATE
                            Where pidm = cx.pidm
                            And seq = cx.seq
                            And programa = cx.programa;
                    Exception
                        When others then
                            null;

                    End;

                    Commit;

            End loop;

      Exception
        When Others then
            null;
      End;      
      
      Begin

            For cx in (

                        select distinct pidm, TZFACCE_ACTIVITY_DATE, seq, programa, FECHA_ESTATUS, FECHA_SUSCRIPCION, TZFACCE_DETAIL_CODE
                        from USER_MEMBRESIA_ALL
                        join TZFACCE on TZFACCE_PIDM = pidm and TZFACCE_DETAIL_CODE = CODIGO_DETALLE --and TZFACCE_FLAG =0
                        where 1 = 1
                        And ESTATUS_MEMB = 'I'
                        And fuente ='TZFACCE'

            ) loop

                    begin
                            update USER_MEMBRESIA_ALL
                            set FECHA_SUSCRIPCION = cx.TZFACCE_ACTIVITY_DATE
                            Where pidm = cx.pidm
                            And seq = cx.seq
                            And programa = cx.programa;
                    Exception
                        When others then
                            null;

                    End;

                    Commit;

            End loop;

      Exception
        When Others then
            null;
      End;      
      


      Begin

            For cx in (

                        select distinct pidm, b.SZTUTLX_ACTIVITY_DATE, seq, programa, FECHA_ESTATUS, FECHA_SUSCRIPCION
                        from USER_MEMBRESIA_ALL
                        join SZTUTLX b on b.SZTUTLX_PIDM = pidm and b.SZTUTLX_DISABLE_IND ='A'
                             And b.SZTUTLX_SEQ_NO = (select min (b1.SZTUTLX_SEQ_NO)
                                                       from SZTUTLX b1
                                                      Where b1.SZTUTLX_PIDM = b.SZTUTLX_PIDM
                                                    )
                        where 1 = 1
                        And ESTATUS_MEMB = 'I'
                        And fuente ='SZTUTLX'

            ) loop

                    begin
                            update USER_MEMBRESIA_ALL
                            set FECHA_SUSCRIPCION = cx.SZTUTLX_ACTIVITY_DATE
                            Where pidm = cx.pidm
                            And seq = cx.seq
                            And programa = cx.programa;
                    Exception
                        When others then
                            null;

                    End;

                    Commit;

            End loop;

      Exception
        When Others then
            null;
      End;
      

    Begin

         For cx in (

                    Select PIDM, CODIGO_DETALLE, SEQ, FECHA_ESTATUS
                    from USER_MEMBRESIA_ALL a
                    where FECHA_SUSCRIPCION is null

          ) loop

              Begin
                    Update USER_MEMBRESIA_ALL
                    set FECHA_SUSCRIPCION = cx.FECHA_ESTATUS
                    Where PIDM = cx.PIDM
                    And CODIGO_DETALLE = cx.CODIGO_DETALLE
                    And SEQ = cx.SEQ;
              Exception
                When Others then
                    null;
              End;

       end loop;
       Commit;

    End;      
      
    Begin 
        update  USER_MEMBRESIA_ALL
        set FECHA_SUSCRIPCION = null
        where ESTATUS_MEMB = 'I';
        commit;
    Exception
    When Others then 
     null;
    End;     
    
    
      
  End P_REPORTE_USUARIO_UPSELLING_ALL;


PROCEDURE P_REPORTE_RETENCION_UTELX IS


    BEGIN
    
    
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SIU_CONN_BI.RETENCION_UTLX';
            commit;

    
            Begin 
                                        INSERT INTO SIU_CONN_BI.RETENCION_UTLX
                                        select distinct a.pidm,
                                         a.matricula,
                                         substr (b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME,'/')-1) Paterno ,
                                         substr (b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME,'/')+1,150) Materno,
                                         SPRIDEN_FIRST_NAME Nombre,
                                         a.campus,
                                         a.nivel,
                                         a.ESTATUS_D estatus,
                                         a.programa,
                                            pkg_utilerias.f_celular(a.pidm, 'CELU') Celular,
                                            pkg_utilerias.f_celular(a.pidm, 'RESI') Residencia,
                                             nvl (trim (pkg_utilerias.f_correo(a.pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.pidm, 'UTLX')) )) Correo_Principal,
                                             pkg_utilerias.f_correo(a.pidm, 'ALTE') Correo_Alterno,
                                            (Select trunc (GORADID_ACTIVITY_DATE) Fecha_Activacion
                                            from GORADID
                                            where 1=1
                                            And GORADID_ADID_CODE = 'RUTX'
                                            And GORADID_pidm = a.pidm ) Fecha_Evento                                             
                                         from TZTPROG a
                                         join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
                                         where 1= 1
--                                         And campus ='UTL'
--                                         And nivel ='MA'
                                         And a.estatus not in ('CV', 'CP')
                                         And a.sp = (select max (a1.sp)
                                                             from TZTPROG a1
                                                             Where a.pidm = a1.pidm
                                                             )
                                         And pkg_utilerias.f_tipo_etiqueta( a.pidm, 'RUTX') = 'RUTX';
            Exception
               When Others then 
                null;
            End;
                    
           Commit;                     
 End P_REPORTE_RETENCION_UTELX;                                      


PROCEDURE P_REPORTE_PAGOS_APLICADOS IS


    BEGIN
    
    
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SIU_CONN_BI.PAGOS_APLICADOS';
            commit;

    
            Begin 
                                         
                    Insert into SIU_CONN_BI.pagos_aplicados
                    with pagos as (
                    Select sum (TBRAPPL_AMOUNT) monto, tbrappl_pidm, TBRAPPL_PAY_TRAN_NUMBER, TBRACCD_EFFECTIVE_DATE , tbraccd_desc, tbraccd_balance balance, TBRACCD_TRAN_NUMBER seq, tbraccd_amount
                    from tbrappl, tbraccd, TZTNCD
                    Where 1= 1 
                    And TBRACCD_PIDM = tbrappl_pidm
                    And TBRAPPL_CHG_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                    And tbraccd_detail_code =  TZTNCD_CODE
                    --And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                    And TBRAPPL_REAPPL_IND is null
                    group by tbrappl_pidm, TBRAPPL_PAY_TRAN_NUMBER, TBRACCD_EFFECTIVE_DATE, tbraccd_desc, tbraccd_balance, TBRACCD_TRAN_NUMBER, tbraccd_amount
                    )
                    select distinct SZVCAMP_CAMP_CODE campus,
                             spriden_id matricula, 
                            a.TBRACCD_TRAN_NUMBER Tran, 
                            a.TBRACCD_TERM_CODE Periodo, 
                            a.TBRACCD_PERIOD Parte, 
                             trunc (a.TBRACCD_EFFECTIVE_DATE)  Vencimiento, 
                             b.TZTNCD_CONCEPTO Tipo,
                             a.tbraccd_detail_code Codigo,
                              a.tbraccd_desc Descripcion, 
                              trunc (a.TBRACCD_FEED_DATE) Fecha_inicio,
                             c.monto Monto_Pagado, 
                            trunc (c.TBRACCD_EFFECTIVE_DATE)  Fecha_Pago_sistema,  
                            trunc (TBRACCD_TRANS_DATE) Fecha_pago_alumno,
                            c.tbraccd_desc descrp_pago,
                            c.tbraccd_amount Monto_Cargo,
                            c.balance Balance,
                            c.seq Sequencia_Cargo        
                    from tbraccd a
                    join spriden on spriden_pidm = a.tbraccd_pidm and spriden_change_ind is null
                    join TZTNCD b on b.TZTNCD_CODE  = a.TBRACCD_DETAIL_CODE and b.TZTNCD_CONCEPTO in ('Poliza', 'Deposito', 'Nota Distribucion')
                     join pagos  c on tbrappl_pidm = a.tbraccd_pidm and c.TBRAPPL_PAY_TRAN_NUMBER= a.TBRACCD_TRAN_NUMBER
                     join SZVCAMP on SZVCAMP_CAMP_ALT_CODE = substr (spriden_id, 1, 2)
                    where 1= 1
                     and trunc (a.TBRACCD_EFFECTIVE_DATE) between '01/08/2018' and trunc (sysdate)
                    --And spriden_id = '010219015'
                    order by 2,17,3;
            Exception
               When Others then 
                null;
            End;
                    
           Commit;                     
 End P_REPORTE_PAGOS_APLICADOS;       


End PKG_REPORTE_BI;
/

DROP PUBLIC SYNONYM PKG_REPORTE_BI;

CREATE OR REPLACE PUBLIC SYNONYM PKG_REPORTE_BI FOR BANINST1.PKG_REPORTE_BI;
