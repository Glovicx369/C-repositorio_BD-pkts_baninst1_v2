DROP PACKAGE BODY BANINST1.PKG_FACTURACION_NT;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_FACTURACION_NT IS



   ---SE AGREGO PARA ELIINAR LOS REGISTROS QUE GENERAN ERRORRES POR NO CUMPLIR CON LOS DATOS FISCALES,
   ---SE EJECUTARA DOS VECES A LA SEMANA Y A FIN DE MES,
   ---CREADO 29/05/2023 Caty
PROCEDURE SP_BORRA_SIN_DATOS
IS

  BEGIN

        BEGIN

            FOR c IN (

            SELECT TZTFACT_PIDM, TZTFACT_RFC, TZTFACT_TRAN_NUMBER, TZTFACT_FOLIO, TZTFACT_MONTO,TZTFACT_FECHA_PROCESO, TZTCONC_CONCEPTO_CODE
            FROM TZTFCTU, TZTCONT
            WHERE 1=1
           -- AND tztfact_pidm=fget_pidm('020241832')
            AND TZTFACT_PIDM = TZTCONC_PIDM
            AND TZTFACT_TRAN_NUMBER = TZTCONC_TRAN_NUMBER
            AND TZTFACT_TIPO_DOCTO = 'FA'
            AND TZTFACT_RESPUESTA ='0'
            AND
             (
                tztfact_error like '%Fiscal del Receptor es requerida%'
                or
                tztfact_error like '%Este RFC del receptor no existe en la lista de RFC inscritos no cancelados del SAT%'
                 or
                tztfact_error like '%El campo Nombre del receptor, debe pertenecer al nombre asociado al RFC%'
                 or
                tztfact_error like '%El campo DomicilioFiscalReceptor del receptor, debe pertenecer al nombre asociado al RFC%'
                 or
                tztfact_error like '%La clave del campo RegimenFiscalR debe corresponder con el tipo de persona (f sica o moral)%'
                or
                tztfact_error like '%La clave del campo UsoCFDI debe corresponder con el tipo de persona (f sica o moral)%'


              )
            AND TRUNC(TZTFACT_FECHA_PROCESO) BETWEEN TRUNC(SYSDATE,'MM') AND TRUNC(SYSDATE)

            )

         LOOP

                BEGIN

                    DELETE TZTFCTU
                    WHERE 1=1
                    AND TZTFACT_PIDM =c.TZTFACT_PIDM
                    AND TZTFACT_TRAN_NUMBER = c.TZTFACT_TRAN_NUMBER
                    AND TZTFACT_FOLIO = c.TZTFACT_FOLIO;

                END;

                   BEGIN
                        delete TZTCRNT
                        where 1=1
                        and TZTCRTE_PIDM = c.TZTFACT_PIDM
                        and TZTCRTE_CAMPO10  = c.TZTFACT_TRAN_NUMBER
                        and TZTCRTE_TIPO_REPORTE  in ( 'Pago_Facturacion_dia', 'Facturacion_dia');
                  END;
                  Begin
                                    Delete TZTCONT
                                    Where TZTCONC_PIDM =c.TZTFACT_PIDM
                                    And TZTCONC_TRAN_NUMBER = c.TZTFACT_TRAN_NUMBER;
                  END;

            END LOOP;
            COMMIT;

         END;


    END SP_BORRA_SIN_DATOS;


--PROCEDIMIENTO CREADO PARA ELIMINAR LAS FACTURAS GENERADAS SIN CLAVE DE CARGO Y SE VUELVAN A PROCESAR--

PROCEDURE SP_BORRA_FCATURAS
IS

  BEGIN

--SE APAG  ELIMINAR REGISTROS SIN DATOS FISCALES PORQUE TARDABA M S EL PROCESO 29/05/2023 Caty
        BEGIN

            FOR c IN (

            SELECT TZTFACT_PIDM, TZTFACT_RFC, TZTFACT_TRAN_NUMBER, TZTFACT_FOLIO, TZTFACT_MONTO,TZTFACT_FECHA_PROCESO, TZTCONC_CONCEPTO_CODE
            FROM TZTFCTU, TZTCONT
            WHERE 1=1
            AND TZTFACT_PIDM = TZTCONC_PIDM
            AND TZTFACT_TRAN_NUMBER = TZTCONC_TRAN_NUMBER
            AND TZTFACT_TIPO_DOCTO = 'FA'
            AND TZTFACT_RESPUESTA ='0'
            AND
                (TZTFACT_ERROR LIKE 'No fue posible realizar%'
                OR
                TZTFACT_ERROR LIKE '%object is not iterable%'
                or
                tztfact_error like '%is not accepted by the pattern%'
              /*  tztfact_error like '%Fiscal del Receptor es requerida%'
                or
                tztfact_error like '%Este RFC del receptor no existe en la lista de RFC inscritos no cancelados del SAT%'
                 or
                tztfact_error like '%El campo Nombre del receptor, debe pertenecer al nombre asociado al RFC%'
                 or
                tztfact_error like '%El campo DomicilioFiscalReceptor del receptor, debe pertenecer al nombre asociado al RFC%'
                 or
                tztfact_error like '%La clave del campo RegimenFiscalR debe corresponder con el tipo de persona (f sica o moral)%'
                or
                tztfact_error like '%La clave del campo UsoCFDI debe corresponder con el tipo de persona (f sica o moral)%'*/


                )
            AND TRUNC(TZTFACT_FECHA_PROCESO) BETWEEN TRUNC(SYSDATE,'MM') AND TRUNC(SYSDATE)

            )

            LOOP

                BEGIN

                    DELETE TZTFCTU
                    WHERE 1=1
                    AND TZTFACT_PIDM =c.TZTFACT_PIDM
                    AND TZTFACT_TRAN_NUMBER = c.TZTFACT_TRAN_NUMBER
                    AND TZTFACT_FOLIO = c.TZTFACT_FOLIO;

                END;
            END LOOP;
            COMMIT;

         END;

        BEGIN
            DELETE  TZTFCTU
            WHERE 1=1
            AND TZTFACT_RESPUESTA = 0
            AND trunc(TZTFACT_FECHA_PROCESO) BETWEEN TRUNC(SYSDATE,'MM') AND TRUNC(SYSDATE)
            AND TZTFACT_ERROR like '%Ocurrio un error al tratar de generar el Comprobante del SAT, Error: Ocurrio un error al tratar de obtener la informaci n del certificado%';
        END;
        COMMIT;




    END SP_BORRA_FCATURAS;





 PROCEDURE SP_CARGA_FA
IS

--DECLARE
    VL_ERROR VARCHAR2(200);
    vl_pidm number;
    vl_date varchar2(100);
    vl_rvoe varchar2 (50);
    vl_consecutivo number:=0;
    vl_bandera number :=0;
    vl_appl_no varchar2(2);
    vl_program varchar2(20);
    vl_tipo_impuesto varchar2(20);
    vl_subtotal_accs number;
    vl_iva_accs number;
    vl_moneda varchar2(6);
    vl_balance number;
    vl_distribuye_balance number;
    vl_new_balance number;
    vl_valida_col number;
    vl_levl varchar2(4);
    vl_codpago varchar2(4):= null;
    vl_fecha_pago varchar2(30);
    vl_tipo_iva varchar2(5);
         -- BEGIN DEL CURSOR DE LOS DATOS A BUSCAR
         --MODIFICAR EL RANGO DE FECHA DEL TRUNC(TBRACCD_ENTRY_DATE)--
  --MODIFICADO PARA FACTURACION 4.0 30/03/2023 --CATY


  BEGIN


        BEGIN

                for a in (

                          SELECT distinct TZTCRTE_PIDM pidm, TZTCRTE_CAMPO10 tran_number, TZTCRTE_TIPO_REPORTE tipo_reporte
                           FROM TZTCRNT
                           WHERE TZTCRTE_TIPO_REPORTE in ( 'Pago_Facturacion_dia', 'Facturacion_dia')
                            AND (TZTCRTE_PIDM, TZTCRTE_CAMPO10) NOT IN (SELECT TZTFACT_PIDM,
                                                                               TZTFACT_TRAN_NUMBER
                                                                        FROM TZTFCTU)

                           )
                LOOP
                       BEGIN
                        delete TZTCRNT
                        where 1=1
                        and TZTCRTE_PIDM = a.pidm
                        and TZTCRTE_CAMPO10  = a.tran_number
                        and TZTCRTE_TIPO_REPORTE = a.tipo_reporte;
                       Exception
                        When Others then
                            null;
                       END;
                        Commit;
                end LOOP;
                 Commit;
        Exception
        When others then
        null;
        End;

        Begin

                For cx in (

                              select *
                              from  TZTCONT
                             WHERE     1 = 1
                                   AND (TZTCONC_PIDM, TZTCONC_TRAN_NUMBER) NOT IN (SELECT TZTFACT_PIDM,
                                                                                          TZTFACT_TRAN_NUMBER
                                                                                     FROM TZTFCTU)
                ) loop

                            Begin
                                    Delete TZTCONT
                                    Where TZTCONC_PIDM = cx.TZTCONC_PIDM
                                    And TZTCONC_TRAN_NUMBER = cx.TZTCONC_TRAN_NUMBER;
                            Exception
                                When Others then
                                    null;
                            End;

                       Commit;

                End loop;
                Commit;


        Exception
        When others then
        null;
        End;




      FOR f in(

        SELECT SPRIDEN_PIDM, SPRIDEN_ID, SPRIDEN_FIRST_NAME, TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_AMOUNT, TBRACCD_STSP_KEY_SEQUENCE, to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                TRUNC(TBRACCD_ENTRY_DATE) TRUNC_DATE, TBRACCD_ENTRY_DATE--, TBRACCD_RECEIPT_NUMBER orden
                FROM TBRACCD, SPRIDEN, SPREMRG s, TZTNCD ----Agregar esta tabla Victor
                WHERE 1=1
                AND substr (spriden_id,1,2) NOT IN (SELECT ZSTPARA_PARAM_ID
                                                FROM ZSTPARA
                                                WHERE 1=1
                                                AND ZSTPARA_MAPA_ID = 'FM_OPM')
                AND TBRACCD_PIDM= SPRIDEN_PIDM
                AND SPRIDEN_CHANGE_IND IS NULL
               -- AND TBBDETC_DCAT_CODE = 'CSH' -- apagar esta linea
                And tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                AND (TBRACCD_PIDM, TBRACCD_TRAN_NUMBER) NOT IN(SELECT TZTFACT_PIDM, TZTFACT_TRAN_NUMBER FROM TZTFCTU)
                AND TBRACCD_PIDM = s.SPREMRG_PIDM(+)
                AND TRUNC(TBRACCD_ENTRY_DATE) > '01/10/2024' ---> Se actualiza esta fecha para recuperar los pagos incluidos POLZAS y Notas de distrubucion
                AND TBRACCD_AMOUNT >= 1  --- Este valor debe de estar en todos las consultas
               --AND TRUNC(TBRACCD_ENTRY_DATE) BETWEEN TRUNC(SYSDATE,'MM') AND TRUNC(SYSDATE)
                --AND TBRACCD_PIDM = 432372 --NOT IN (141775, 95001)-- 241122--238240 --  186280--163826 --18524
               --AND TBRACCD_TRAN_NUMBER = 63 --251
              -- and tbraccd_pidm=fget_pidm('010587507')--fget_pidm('530000381')--440000853,440000454
               group by SPRIDEN_PIDM, SPRIDEN_ID, SPRIDEN_FIRST_NAME, TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_AMOUNT, TBRACCD_STSP_KEY_SEQUENCE, TBRACCD_BALANCE, TBRACCD_ENTRY_DATE--, TBRACCD_RECEIPT_NUMBER
               ,TZTNCD_CONCEPTO
               order by TBRACCD_ENTRY_DATE DESC

       )
       LOOP -- PRIMER LOOP--
            ---INSERTA EN TZTCRTE LO QUE SE HACE EN PKG_REPORTES1.sp_pagos_facturacion_dia--

      --    DBMS_OUTPUT.PUT_LINE('Datos recuperados '|| f.SPRIDEN_PIDM||' '||f.TRUNC_DATE||' '||f.TBRACCD_ENTRY_DATE);

          BEGIN

                  BEGIN


                            SELECT a.SARADAP_APPL_NO, a.SARADAP_PROGRAM_1
                               INTO vl_appl_no, vl_program
                            FROM SARADAP a
                            WHERE 1=1
                            AND a.SARADAP_PIDM = f.SPRIDEN_PIDM  --248484
                            AND a.SARADAP_APPL_NO in  (SELECT MAX(b.SARADAP_APPL_NO)
                                                                     FROM
                                                                     SARADAP b
                                                                     WHERE 1=1
                                                                     AND b.SARADAP_PIDM = a.SARADAP_PIDM
                                                                     AND b.SARADAP_PROGRAM_1 = a.SARADAP_PROGRAM_1
                                                                     );


                    EXCEPTION WHEN OTHERS THEN
                        Begin

                            SELECT a.SARADAP_APPL_NO, a.SARADAP_PROGRAM_1
                               INTO vl_appl_no, vl_program
                            FROM SARADAP a
                            WHERE 1=1
                            AND a.SARADAP_PIDM = f.SPRIDEN_PIDM  --248484
                            AND a.SARADAP_APPL_NO in  (SELECT MAX(b.SARADAP_APPL_NO)
                                                                     FROM
                                                                     SARADAP b
                                                                     WHERE 1=1
                                                                     AND b.SARADAP_PIDM = a.SARADAP_PIDM
                                                                    -- AND b.SARADAP_PROGRAM_1 = a.SARADAP_PROGRAM_1
                                                                     );

                        exception
                            When Others then
                                 vl_appl_no :=0;
                                 vl_program := null;

                        End;


                    END;



                  --  DBMS_OUTPUT.PUT_LINE('Llego al for ');

             If  substr (f.SPRIDEN_ID, 1,2) in ('40') then ---> Campus que llegan desde pasarelas de ventas distintas a SIU

                      BEGIN
 --DBMS_OUTPUT.PUT_LINE('Llego if 1');
                                   for a IN (
                                     with colegiatura as (Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbbdetc_desc desc_cargo,
                                              TBBDETC_DCAT_CODE Categ_Col
                                              from tbraccd a, tbbdetc b
                                              where 1=1
                                              and a.tbraccd_detail_code = b.tbbdetc_detail_code
                                              and  a.tbraccd_pidm = f.spriden_pidm
                                              ),
                                      curp as (select  GORADID_PIDM PIDM,
                                              GORADID_ADDITIONAL_ID CURP
                                              from GORADID
                                              where GORADID_ADID_CODE = 'CURP'
                                              AND LENGTH(GORADID_ADDITIONAL_ID)= 18
                                              GROUP BY GORADID_PIDM, GORADID_ADDITIONAL_ID)
                                              select DISTINCT
                                              tbraccd_pidm pidm ,
                                              spriden_id as Matricula,
                                              s.SPREMRG_LAST_NAME as Nombre,
                                              'BOT' Campus,
                                              'EC' Nivel,
                                                CASE WHEN LENGTH(SPREMRG_MI) BETWEEN 1 AND 20 THEN
                                                NVL(SPREMRG_MI, 'XAXX010101000')
                                                WHEN TBRACCD_CURR_CODE != 'MXN' THEN
                                                  'XEXX010101000'
                                                WHEN TBRACCD_CURR_CODE = 'MXN' THEN
                                                  'XAXX010101000'
                                                END as RFC,
                                                REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' ') as Dom_Fiscal,
                                                s.SPREMRG_CITY as Ciudad,
                                                s.SPREMRG_STREET_LINE3 Colonia,
                                                s.SPREMRG_ZIP as CP,
                                                s.SPREMRG_NATN_CODE as Pais,
                                                tbraccd_detail_code as Tipo_Deposito,
                                                tbraccd_desc as Descripcion,
                                                to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                                TBRACCD_TRAN_NUMBER as Transaccion,
                                                TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')Fecha_Pago,
                                                GORADID_ADDITIONAL_ID as REFERENCIA,
                                                GORADID_ADID_CODE as Referencia_Tipo,
                                                GOREMAL_EMAIL_ADDRESS as EMAIL,
                                                to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                                to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                                TBRAPPL_AMOUNT accesorio,
                                                TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                                CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                                THEN 'PCOLEGIATURA'
                                                WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                                THEN colegiatura.desc_cargo
                                                END descripcion_pago,
                                                CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                                THEN 'COL'
                                                WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                                THEN NVL(colegiatura.Categ_Col,'COL')
                                                END Categ_Col,
                                                min(SPREMRG_PRIORITY) Prioridad,
                                                curp.CURP,
                                                'CURS' Grado,
                                                s.SPREMRG_LAST_NAME Razon_social,
                                                'BOTECSEMCU' programa,
                                                'Bloque5' bloque,
                                                SPREMRG_RG_FS Reg_fiscal,
                                                SPREMRG_CFDI cfdi
                                              from SPREMRG s
                                              join SPRIDEN on s.SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
                                              join TBRACCD on s.SPREMRG_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE)= f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm  AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                              join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                              left join GORADID on GORADID_PIDM = s.SPREMRG_PIDM AND GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                              left join GOREMAL on GOREMAL_PIDM = s.SPREMRG_PIDM AND GOREMAL_EMAL_CODE in ('PRIN', 'UTLX', 'UCAM')
                                              left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                              left join colegiatura on  colegiatura.pidm = spriden_pidm AND colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                              left join curp on curp.PIDM = SPRIDEN_PIDM
                                              join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                              And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                              where 1=1
                                              and TBBDETC_TYPE_IND = 'P'
                                              -- and TBBDETC_DCAT_CODE = 'CSH'
                                              and TBRACCD_AMOUNT >= 1
                                              and s.SPREMRG_PRIORITY = (select MAX(s1.SPREMRG_PRIORITY)
                                                                          FROM SPREMRG s1
                                                                          where s.SPREMRG_PIDM = s1.SPREMRG_PIDM)
                                              GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, s.SPREMRG_MI,
                                                              REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' '), s.SPREMRG_CITY, s.SPREMRG_STREET_LINE3,
                                                              s.SPREMRG_ZIP, s.SPREMRG_NATN_CODE, tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                                              GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                                              curp.CURP,TBRACCD_BALANCE, TBRACCD_CURR_CODE, TZTNCD_CONCEPTO,SPREMRG_RG_FS,SPREMRG_CFDI
                                             UNION
                                              select DISTINCT
                                              tbraccd_pidm pidm ,
                                              spriden_id as Matricula,
                                              null as Nombre,
                                              'BOT' Campus,
                                              'EC' Nivel,
                                                CASE
                                                WHEN TBRACCD_CURR_CODE != 'MXN' THEN
                                                  'XEXX010101000'
                                                WHEN TBRACCD_CURR_CODE = 'MXN' THEN
                                                  'XAXX010101000'
                                                END as RFC,
                                              null as Dom_Fiscal,
                                              null as Ciudad,
                                              null colonia,
                                              null as CP,
                                              null as Pais,
                                                tbraccd_detail_code as Tipo_Deposito,
                                                tbraccd_desc as Descripcion,
                                                to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                                TBRACCD_TRAN_NUMBER as Transaccion,
                                                TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')Fecha_Pago,
                                                GORADID_ADDITIONAL_ID as REFERENCIA,
                                                GORADID_ADID_CODE as Referencia_Tipo,
                                                GOREMAL_EMAIL_ADDRESS as EMAIL,
                                                to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                                to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                                TBRAPPL_AMOUNT accesorio,
                                                TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                                CASE WHEN colegiatura.Categ_Col IN ('CAN', 'ACC')
                                                THEN 'PCOLEGIATURA'
                                                WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                                THEN colegiatura.desc_cargo
                                                END descripcion_pago,
                                                CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                                THEN 'COL'
                                                WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                                THEN NVL(colegiatura.Categ_Col,'COL')
                                                END Categ_Col,
                                                null Prioridad,
                                                curp.CURP,
                                                'CURS' Grado,
                                               null Razon_social,
                                               'BOTECSEMCU' programa,
                                               'Bloque6' bloque,
                                                null Reg_fiscal,
                                                null cfdi
                                              from SPRIDEN
                                              join TBRACCD on SPRIDEN_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                              join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                              left join GORADID on SPRIDEN_PIDM = GORADID_PIDM and GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                              left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE  in ('PRIN', 'UTLX', 'UCAM')
                                              left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                              left join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                              left join curp on SPRIDEN_PIDM = curp.PIDM
                                              join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                              And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                              where 1= 1
                                              And spriden_change_ind is null
                                              and TBBDETC_TYPE_IND = 'P'
                                            --  and TBBDETC_DCAT_CODE = 'CSH'
                                              And spriden_pidm not in (select SPREMRG_pidm from SPREMRG)
                                              And TBRACCD_AMOUNT >= 1
                                              GROUP BY tbraccd_pidm, spriden_id,
                                              tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TBRACCD_ENTRY_DATE,TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                              GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                              curp.CURP, TBRACCD_BALANCE, TBRACCD_CURR_CODE, TZTNCD_CONCEPTO

                                         ) loop

                                          vl_consecutivo := 0;
                                          vl_fecha_pago:=null;

                                              BEGIN

                                                 SELECT
                                                    CASE
                                                    WHEN (SYSDATE - 72/24) >= TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(SYSDATE,'YYYY-MM-DD"T"HH24:MI:SS')
                                                    WHEN (SYSDATE - 72/24) <  TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                                                    END INTO vl_fecha_pago
                                                    FROM TBRACCD
                                                    WHERE 1=1
                                                    AND TBRACCD_PIDM = f.spriden_pidm
                                                    AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER;
                                              EXCEPTION WHEN OTHERS THEN
                                              vl_fecha_pago:= ('0000-00-00"T"00:00:00');
                                               END;

                                               BEGIN
                                                SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                                                    INTO vl_consecutivo
                                                FROM TZTCRNT
                                                WHERE 1=1
                                                AND TZTCRTE_PIDM = f.spriden_pidm
                                                AND TZTCRTE_CAMPO10= f.TBRACCD_TRAN_NUMBER
                                                And TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia';
                                                EXCEPTION
                                                WHEN OTHERS THEN
                                                vl_consecutivo :=1;
                                               --DBMS_OUTPUT.PUT_LINE('Error XX3 '||sqlerrm);
                                                END;



                                            begin
                                             Insert into TZTCRNT values (a.pidm, --TZTCRTE_PIDM
                                                                            a.matricula, --TZTCRTE_ID
                                                                            a.campus,--TZTCRTE_CAMP
                                                                            a.nivel,--TZTCRTE_LEVL
                                                                            a.nombre,--TZTCRTE_CAMPO1
                                                                            a.rfc,--TZTCRTE_CAMPO2
                                                                            a.dom_fiscal,--TZTCRTE_CAMPO3
                                                                            a.ciudad,--TZTCRTE_CAMPO4
                                                                            a.cp,--TZTCRTE_CAMPO5
                                                                            a.pais,--TZTCRTE_CAMPO6
                                                                            a.tipo_deposito,--TZTCRTE_CAMP07
                                                                            a.descripcion,--TZTCRTE_CAMPO8
                                                                            a.monto,--TZTCRTE_CAMPO9
                                                                            a.transaccion,--TZTCRTE_CAMP1O
                                                                            vl_fecha_pago, --TZTCRTE_CAMPO11
                                                                            --a.fecha_pago,--TZTCRTE_CAMPO11
                                                                            a.referencia,--TZTCRTE_CAMPO12
                                                                            a.referencia_tipo,--TZTCRTE_CAMPO13
                                                                            a.email,--TZTCRTE_CAMPO14
                                                                            a.accesorio, ---TZTCRTE_CAMPO15
                                                                            --c.monto_pagado,--TZTCRTE_CAMPO15
                                                                            a.secuencia_pago,--TZTCRTE_CAMPO16
                                                                            a.descripcion_pago,---TZTCRTE_CAMPO17
                                                                            a.Categ_Col,--TZTCRTE_CAMPO18
                                                                            a.Prioridad,--TZTCRTE_CAMPO19
                                                                            a.CURP,--TZTCRTE_CAMPO20
                                                                            a.Grado,--TZTCRTE_CAMPO21
                                                                            a.Razon_social,--TZTCRTE_CAMPO22
                                                                            null, --TZTCRTE_CAMPO23
                                                                            null, --TZTCRTE_CAMPO24
                                                                            null, --TZTCRTE_CAMPO25
                                                                            a.programa, --TZTCRTE_CAMPO26
                                                                            a.colonia, --TZTCRTE_CAMPO27
                                                                            null, --TZTCRTE_CAMPO28
                                                                            null, --TZTCRTE_CAMPO29
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            a.bloque, --TZTCRTE_CAMPO56
                                                                            vl_consecutivo,
                                                                            a.balance, --TZTCRTE_CAMPO58
                                                                            USER||'- EMONTADI_FA', --TZTCRTE_CAMPO59
                                                                            TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                                            'Pago_Facturacion_dia',--TZTCRTE_TIPO_REPORTE,
                                                                            a.Reg_fiscal,
                                                                            a.cfdi
                                                                            );
                                            --DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCRTE '||c.pidm||' '||c.monto||' '||c.transaccion||' '||c.Categ_Col);
                                          --  DBMS_OUTPUT.PUT_LINE(vl_bandera||'-'||a.RFC ||'-'||a.descripcion_pago||'-'||a.nombre||'-'||'Primero');
                                            Exception
                                                When Others then
                                                --      DBMS_OUTPUT.PUT_LINE('Error XX2 '||sqlerrm);
                                                      null;
                                            end;
                                        End Loop;
                                      COMMIT;
                      Exception
                            When Others then
                              --  DBMS_OUTPUT.PUT_LINE('Error XX1 '||sqlerrm);
                              null;

                      END;
--campus 53
  ElsIf  substr (f.SPRIDEN_ID, 1,2) in ('53') then ---> Campus que llegan desde pasarelas de ventas distintas a SIU
--DBMS_OUTPUT.PUT_LINE('Llego if 2');
                      BEGIN

                                   for a IN (
                                   with colegiatura as (Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbbdetc_desc desc_cargo,
                                            TBBDETC_DCAT_CODE Categ_Col
                                            from tbraccd a, tbbdetc b
                                            where 1=1
                                            and a.tbraccd_detail_code = b.tbbdetc_detail_code
                                            and  a.tbraccd_pidm = f.spriden_pidm
                                            ),
                                    curp as (select  GORADID_PIDM PIDM,
                                            GORADID_ADDITIONAL_ID CURP
                                            from GORADID
                                            where GORADID_ADID_CODE = 'CURP'
                                            AND LENGTH(GORADID_ADDITIONAL_ID)= 18
                                            GROUP BY GORADID_PIDM, GORADID_ADDITIONAL_ID)
                                            select DISTINCT
                                            tbraccd_pidm pidm ,
                                            spriden_id as Matricula,
                                            s.SPREMRG_LAST_NAME as Nombre,
                                            'UDD' Campus,
                                            'EC' Nivel,
                                              CASE WHEN LENGTH(SPREMRG_MI) BETWEEN 1 AND 20 THEN
                                              NVL(SPREMRG_MI, 'XAXX010101000')
                                              WHEN TBRACCD_CURR_CODE != 'MXN' THEN
                                                'XEXX010101000'
                                              WHEN TBRACCD_CURR_CODE = 'MXN' THEN
                                                'XAXX010101000'
                                              END as RFC,
                                              REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' ') as Dom_Fiscal,
                                              s.SPREMRG_CITY as Ciudad,
                                              s.SPREMRG_STREET_LINE3 Colonia,
                                              s.SPREMRG_ZIP as CP,
                                              s.SPREMRG_NATN_CODE as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              min(SPREMRG_PRIORITY) Prioridad,
                                              curp.CURP,
                                              'CURS' Grado,
                                              s.SPREMRG_LAST_NAME Razon_social,
                                              'BOTECSEMCU' programa,
                                              'Bloque5' bloque,
                                              SPREMRG_RG_FS Reg_fiscal,--facto 4
                                              SPREMRG_CFDI cfdi --facto 4
                                            from SPREMRG s
                                            join SPRIDEN on s.SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
                                            join TBRACCD on s.SPREMRG_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE)= f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm  AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            left join GORADID on GORADID_PIDM = s.SPREMRG_PIDM AND GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on GOREMAL_PIDM = s.SPREMRG_PIDM AND GOREMAL_EMAL_CODE in ('PRIN', 'UTLX', 'UCAM')
                                            left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left join colegiatura on  colegiatura.pidm = spriden_pidm AND colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left join curp on curp.PIDM = SPRIDEN_PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1=1
                                            and TBBDETC_TYPE_IND = 'P'
                                           -- and TBBDETC_DCAT_CODE = 'CSH'
                                            and TBRACCD_AMOUNT >= 1
                                            and s.SPREMRG_PRIORITY = (select MAX(s1.SPREMRG_PRIORITY)
                                                                        FROM SPREMRG s1
                                                                        where s.SPREMRG_PIDM = s1.SPREMRG_PIDM)
                                            GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, s.SPREMRG_MI,
                                                            REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' '), s.SPREMRG_CITY, s.SPREMRG_STREET_LINE3,
                                                            s.SPREMRG_ZIP, s.SPREMRG_NATN_CODE, tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col, curp.CURP,TBRACCD_BALANCE, TBRACCD_CURR_CODE, TZTNCD_CONCEPTO
                                           UNION
                                            select DISTINCT
                                            tbraccd_pidm pidm ,
                                            spriden_id as Matricula,
                                            null as Nombre,
                                            'UDD' Campus,
                                            'EC' Nivel,
                                              CASE
                                              WHEN TBRACCD_CURR_CODE != 'MXN' THEN
                                                'XEXX010101000'
                                              WHEN TBRACCD_CURR_CODE = 'MXN' THEN
                                                'XAXX010101000'
                                              END as RFC,
                                            null as Dom_Fiscal,
                                            null as Ciudad,
                                            null colonia,
                                            null as CP,
                                            null as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'ACC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              null Prioridad,
                                              curp.CURP,
                                              'CURS' Grado,
                                             null Razon_social,
                                             'BOTECSEMCU' programa,
                                             'Bloque6' bloque,
                                             null Reg_fiscal,--facto 4
                                             null cfdi --facto 4
                                            from SPRIDEN
                                            join TBRACCD on SPRIDEN_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            left join GORADID on SPRIDEN_PIDM = GORADID_PIDM and GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE  in ('PRIN', 'UTLX', 'UCAM')
                                            left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left join curp on SPRIDEN_PIDM = curp.PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1= 1
                                            And spriden_change_ind is null
                                            and TBBDETC_TYPE_IND = 'P'
                                           -- and TBBDETC_DCAT_CODE = 'CSH'
                                            And spriden_pidm not in (select SPREMRG_pidm from SPREMRG)
                                            And TBRACCD_AMOUNT >= 1
                                            GROUP BY tbraccd_pidm, spriden_id,
                                            tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TBRACCD_ENTRY_DATE,TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                            curp.CURP, TBRACCD_BALANCE, TBRACCD_CURR_CODE,TZTNCD_CONCEPTO

                                         ) loop

                                          vl_consecutivo := 0;
                                          vl_fecha_pago:=null;

                                              BEGIN

                                                 SELECT
                                                    CASE
                                                    WHEN (SYSDATE - 72/24) >= TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(SYSDATE,'YYYY-MM-DD"T"HH24:MI:SS')
                                                    WHEN (SYSDATE - 72/24) <  TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                                                    END INTO vl_fecha_pago
                                                    FROM TBRACCD
                                                    WHERE 1=1
                                                    AND TBRACCD_PIDM = f.spriden_pidm
                                                    AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER;
                                              EXCEPTION WHEN OTHERS THEN
                                              vl_fecha_pago:= ('0000-00-00"T"00:00:00');
                                               END;

                                               BEGIN
                                                SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                                                    INTO vl_consecutivo
                                                FROM TZTCRNT
                                                WHERE 1=1
                                                AND TZTCRTE_PIDM = f.spriden_pidm
                                                AND TZTCRTE_CAMPO10= f.TBRACCD_TRAN_NUMBER
                                                And TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia';
                                                EXCEPTION
                                                WHEN OTHERS THEN
                                                vl_consecutivo :=1;
                                               --DBMS_OUTPUT.PUT_LINE('Error XX3 '||sqlerrm);
                                                END;



                                            begin
                                             Insert into TZTCRNT values (a.pidm, --TZTCRTE_PIDM
                                                                            a.matricula, --TZTCRTE_ID
                                                                            a.campus,--TZTCRTE_CAMP
                                                                            a.nivel,--TZTCRTE_LEVL
                                                                            a.nombre,--TZTCRTE_CAMPO1
                                                                            a.rfc,--TZTCRTE_CAMPO2
                                                                            a.dom_fiscal,--TZTCRTE_CAMPO3
                                                                            a.ciudad,--TZTCRTE_CAMPO4
                                                                            a.cp,--TZTCRTE_CAMPO5
                                                                            a.pais,--TZTCRTE_CAMPO6
                                                                            a.tipo_deposito,--TZTCRTE_CAMP07
                                                                            a.descripcion,--TZTCRTE_CAMPO8
                                                                            a.monto,--TZTCRTE_CAMPO9
                                                                            a.transaccion,--TZTCRTE_CAMP1O
                                                                            vl_fecha_pago, --TZTCRTE_CAMPO11
                                                                            --a.fecha_pago,--TZTCRTE_CAMPO11
                                                                            a.referencia,--TZTCRTE_CAMPO12
                                                                            a.referencia_tipo,--TZTCRTE_CAMPO13
                                                                            a.email,--TZTCRTE_CAMPO14
                                                                            a.accesorio, ---TZTCRTE_CAMPO15
                                                                            --c.monto_pagado,--TZTCRTE_CAMPO15
                                                                            a.secuencia_pago,--TZTCRTE_CAMPO16
                                                                            a.descripcion_pago,---TZTCRTE_CAMPO17
                                                                            a.Categ_Col,--TZTCRTE_CAMPO18
                                                                            a.Prioridad,--TZTCRTE_CAMPO19
                                                                            a.CURP,--TZTCRTE_CAMPO20
                                                                            a.Grado,--TZTCRTE_CAMPO21
                                                                            a.Razon_social,--TZTCRTE_CAMPO22
                                                                            null, --TZTCRTE_CAMPO23
                                                                            null, --TZTCRTE_CAMPO24
                                                                            null, --TZTCRTE_CAMPO25
                                                                            a.programa, --TZTCRTE_CAMPO26
                                                                            a.colonia, --TZTCRTE_CAMPO27
                                                                            null, --TZTCRTE_CAMPO28
                                                                            null, --TZTCRTE_CAMPO29
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            a.bloque, --TZTCRTE_CAMPO56
                                                                            vl_consecutivo,
                                                                            a.balance, --TZTCRTE_CAMPO58
                                                                            USER||'- EMONTADI_FA', --TZTCRTE_CAMPO59
                                                                            TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                                            'Pago_Facturacion_dia',--TZTCRTE_TIPO_REPORTE,
                                                                            a.Reg_fiscal,
                                                                            a.cfdi
                                                                            );
                                     --       DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCRTE '||a.pidm||' '||a.monto||' '||a.transaccion||' '||a.Categ_Col);
                                          --  DBMS_OUTPUT.PUT_LINE(vl_bandera||'-'||a.RFC ||'-'||a.descripcion_pago||'-'||a.nombre||'-'||'Primero');
                                            Exception
                                                When Others then
                                                      DBMS_OUTPUT.PUT_LINE('Error XX2 '||sqlerrm);
                                                      null;
                                            end;
                                        End Loop;
                                      COMMIT;
                      Exception
                            When Others then
                              --  DBMS_OUTPUT.PUT_LINE('Error XX1 '||sqlerrm);
                              null;

                      END;
   --campus 41

                  ElsIf  substr (f.SPRIDEN_ID, 1,2) in ('41') then ---> Campus que llegan desde pasarelas de ventas distintas a SIU

                      BEGIN
DBMS_OUTPUT.PUT_LINE('Llego if 3');
                                   for a IN (
                                   with colegiatura as (Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbbdetc_desc desc_cargo,
                                            TBBDETC_DCAT_CODE Categ_Col
                                            from tbraccd a, tbbdetc b
                                            where 1=1
                                            and a.tbraccd_detail_code = b.tbbdetc_detail_code
                                            and  a.tbraccd_pidm = f.spriden_pidm
                                            ),
                                    curp as (select  GORADID_PIDM PIDM,
                                            GORADID_ADDITIONAL_ID CURP
                                            from GORADID
                                            where GORADID_ADID_CODE = 'CURP'
                                            AND LENGTH(GORADID_ADDITIONAL_ID)= 18
                                            GROUP BY GORADID_PIDM, GORADID_ADDITIONAL_ID)
                                            select DISTINCT
                                            tbraccd_pidm pidm ,
                                            spriden_id as Matricula,
                                            s.SPREMRG_LAST_NAME as Nombre,
                                            'SEN' Campus,
                                            'LI' Nivel,
                                              CASE WHEN LENGTH(SPREMRG_MI) BETWEEN 1 AND 20 THEN
                                              NVL(SPREMRG_MI, 'XAXX010101000')
                                              WHEN TBRACCD_CURR_CODE != 'MXN' THEN
                                                'XEXX010101000'
                                              WHEN TBRACCD_CURR_CODE = 'MXN' THEN
                                                'XAXX010101000'
                                              END as RFC,
                                              REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' ') as Dom_Fiscal,
                                              s.SPREMRG_CITY as Ciudad,
                                              s.SPREMRG_STREET_LINE3 Colonia,
                                              s.SPREMRG_ZIP as CP,
                                              s.SPREMRG_NATN_CODE as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              min(SPREMRG_PRIORITY) Prioridad,
                                              curp.CURP,
                                              'LICE' Grado,
                                              s.SPREMRG_LAST_NAME Razon_social,
                                              'SENLIALNAS' programa,
                                              'Bloque5' bloque,
                                              SPREMRG_RG_FS Reg_fiscal,--facto 4
                                              SPREMRG_CFDI cfdi --facto 4
                                            from SPREMRG s
                                            join SPRIDEN on s.SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
                                            join TBRACCD on s.SPREMRG_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE)= f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm  AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            left join GORADID on GORADID_PIDM = s.SPREMRG_PIDM AND GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on GOREMAL_PIDM = s.SPREMRG_PIDM AND GOREMAL_EMAL_CODE in ('PRIN', 'UTLX', 'UCAM')
                                            left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left join colegiatura on  colegiatura.pidm = spriden_pidm AND colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left join curp on curp.PIDM = SPRIDEN_PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1=1
                                            and TBBDETC_TYPE_IND = 'P'
                                            -- and TBBDETC_DCAT_CODE = 'CSH'
                                            and TBRACCD_AMOUNT >= 1
                                            and s.SPREMRG_PRIORITY = (select MAX(s1.SPREMRG_PRIORITY)
                                                                        FROM SPREMRG s1
                                                                        where s.SPREMRG_PIDM = s1.SPREMRG_PIDM)
                                            GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, s.SPREMRG_MI,
                                                            REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' '), s.SPREMRG_CITY, s.SPREMRG_STREET_LINE3,
                                                            s.SPREMRG_ZIP, s.SPREMRG_NATN_CODE, tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                                            curp.CURP,TBRACCD_BALANCE, TBRACCD_CURR_CODE, TZTNCD_CONCEPTO
                                           UNION
                                            select DISTINCT
                                            tbraccd_pidm pidm ,
                                            spriden_id as Matricula,
                                            null as Nombre,
                                            'SEN' Campus,
                                            'LI' Nivel,
                                              CASE
                                              WHEN TBRACCD_CURR_CODE != 'MXN' THEN
                                                'XEXX010101000'
                                              WHEN TBRACCD_CURR_CODE = 'MXN' THEN
                                                'XAXX010101000'
                                              END as RFC,
                                            null as Dom_Fiscal,
                                            null as Ciudad,
                                            null colonia,
                                            null as CP,
                                            null as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'ACC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              null Prioridad,
                                              curp.CURP,
                                              'LICE' Grado,
                                             null Razon_social,
                                             'SENLIALNAS' programa,
                                             'Bloque6' bloque,
                                             null Reg_fiscal,--facto 4
                                             null cfdi --facto 4
                                            from SPRIDEN
                                            join TBRACCD on SPRIDEN_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            left join GORADID on SPRIDEN_PIDM = GORADID_PIDM and GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE  in ('PRIN', 'UTLX', 'UCAM')
                                            left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left join curp on SPRIDEN_PIDM = curp.PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1= 1
                                            And spriden_change_ind is null
                                            and TBBDETC_TYPE_IND = 'P'
                                          --  and TBBDETC_DCAT_CODE = 'CSH'
                                            And spriden_pidm not in (select SPREMRG_pidm from SPREMRG)
                                            And TBRACCD_AMOUNT >= 1
                                            GROUP BY tbraccd_pidm, spriden_id,
                                            tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TBRACCD_ENTRY_DATE,TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                            curp.CURP, TBRACCD_BALANCE, TBRACCD_CURR_CODE, TZTNCD_CONCEPTO

                                         ) loop

                                          vl_consecutivo := 0;
                                          vl_fecha_pago:=null;

                                              BEGIN

                                                 SELECT
                                                    CASE
                                                    WHEN (SYSDATE - 72/24) >= TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(SYSDATE,'YYYY-MM-DD"T"HH24:MI:SS')
                                                    WHEN (SYSDATE - 72/24) <  TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                                                    END INTO vl_fecha_pago
                                                    FROM TBRACCD
                                                    WHERE 1=1
                                                    AND TBRACCD_PIDM = f.spriden_pidm
                                                    AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER;
                                              EXCEPTION WHEN OTHERS THEN
                                              vl_fecha_pago:= ('0000-00-00"T"00:00:00');
                                               END;

                                               BEGIN
                                                SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                                                    INTO vl_consecutivo
                                                FROM TZTCRNT
                                                WHERE 1=1
                                                AND TZTCRTE_PIDM = f.spriden_pidm
                                                AND TZTCRTE_CAMPO10= f.TBRACCD_TRAN_NUMBER
                                                And TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia';
                                                EXCEPTION
                                                WHEN OTHERS THEN
                                                vl_consecutivo :=1;
                                               --DBMS_OUTPUT.PUT_LINE('Error XX3 '||sqlerrm);
                                                END;



                                            begin
                                             Insert into TZTCRNT values (a.pidm, --TZTCRTE_PIDM
                                                                            a.matricula, --TZTCRTE_ID
                                                                            a.campus,--TZTCRTE_CAMP
                                                                            a.nivel,--TZTCRTE_LEVL
                                                                            a.nombre,--TZTCRTE_CAMPO1
                                                                            a.rfc,--TZTCRTE_CAMPO2
                                                                            a.dom_fiscal,--TZTCRTE_CAMPO3
                                                                            a.ciudad,--TZTCRTE_CAMPO4
                                                                            a.cp,--TZTCRTE_CAMPO5
                                                                            a.pais,--TZTCRTE_CAMPO6
                                                                            a.tipo_deposito,--TZTCRTE_CAMP07
                                                                            a.descripcion,--TZTCRTE_CAMPO8
                                                                            a.monto,--TZTCRTE_CAMPO9
                                                                            a.transaccion,--TZTCRTE_CAMP1O
                                                                            vl_fecha_pago, --TZTCRTE_CAMPO11
                                                                            --a.fecha_pago,--TZTCRTE_CAMPO11
                                                                            a.referencia,--TZTCRTE_CAMPO12
                                                                            a.referencia_tipo,--TZTCRTE_CAMPO13
                                                                            a.email,--TZTCRTE_CAMPO14
                                                                            a.accesorio, ---TZTCRTE_CAMPO15
                                                                            --c.monto_pagado,--TZTCRTE_CAMPO15
                                                                            a.secuencia_pago,--TZTCRTE_CAMPO16
                                                                            a.descripcion_pago,---TZTCRTE_CAMPO17
                                                                            a.Categ_Col,--TZTCRTE_CAMPO18
                                                                            a.Prioridad,--TZTCRTE_CAMPO19
                                                                            a.CURP,--TZTCRTE_CAMPO20
                                                                            a.Grado,--TZTCRTE_CAMPO21
                                                                            a.Razon_social,--TZTCRTE_CAMPO22
                                                                            null, --TZTCRTE_CAMPO23
                                                                            null, --TZTCRTE_CAMPO24
                                                                            null, --TZTCRTE_CAMPO25
                                                                            a.programa, --TZTCRTE_CAMPO26
                                                                            a.colonia, --TZTCRTE_CAMPO27
                                                                            null, --TZTCRTE_CAMPO28
                                                                            null, --TZTCRTE_CAMPO29
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            a.bloque, --TZTCRTE_CAMPO56
                                                                            vl_consecutivo,
                                                                            a.balance, --TZTCRTE_CAMPO58
                                                                            USER||'- EMONTADI_FA', --TZTCRTE_CAMPO59
                                                                            TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                                            'Pago_Facturacion_dia',--TZTCRTE_TIPO_REPORTE
                                                                            a.Reg_fiscal,
                                                                            a.cfdi
                                                                            );
                                            --DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCRTE '||c.pidm||' '||c.monto||' '||c.transaccion||' '||c.Categ_Col);
                                          --  DBMS_OUTPUT.PUT_LINE(vl_bandera||'-'||a.RFC ||'-'||a.descripcion_pago||'-'||a.nombre||'-'||'Primero');
                                            Exception
                                                When Others then
                                                --      DBMS_OUTPUT.PUT_LINE('Error XX2 '||sqlerrm);
                                                      null;
                                            end;
                                        End Loop;
                                      COMMIT;
                      Exception
                            When Others then
                              --  DBMS_OUTPUT.PUT_LINE('Error XX1 '||sqlerrm);
                              null;

                      END;

            ElsIf  substr (f.SPRIDEN_ID, 1,2) in ('54') then ---> Campus que llegan desde pasarelas de ventas distintas a SIU

                      BEGIN
DBMS_OUTPUT.PUT_LINE('Llego if 4');
                                   for a IN (
                                   with colegiatura as (Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbbdetc_desc desc_cargo,
                                            TBBDETC_DCAT_CODE Categ_Col
                                            from tbraccd a, tbbdetc b
                                            where 1=1
                                            and a.tbraccd_detail_code = b.tbbdetc_detail_code
                                            and  a.tbraccd_pidm = f.spriden_pidm
                                            ),
                                    curp as (select  GORADID_PIDM PIDM,
                                            GORADID_ADDITIONAL_ID CURP
                                            from GORADID
                                            where GORADID_ADID_CODE = 'CURP'
                                            AND LENGTH(GORADID_ADDITIONAL_ID)= 18
                                            GROUP BY GORADID_PIDM, GORADID_ADDITIONAL_ID)
                                            select DISTINCT
                                            tbraccd_pidm pidm ,
                                            spriden_id as Matricula,
                                            s.SPREMRG_LAST_NAME as Nombre,
                                            'UTX' Campus,
                                            'EC' Nivel,
                                              CASE WHEN LENGTH(SPREMRG_MI) BETWEEN 1 AND 20 THEN
                                              NVL(SPREMRG_MI, 'XAXX010101000')
                                              WHEN TBRACCD_CURR_CODE != 'MXN' THEN
                                                'XEXX010101000'
                                              WHEN TBRACCD_CURR_CODE = 'MXN' THEN
                                                'XAXX010101000'
                                              END as RFC,
                                              REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' ') as Dom_Fiscal,
                                              s.SPREMRG_CITY as Ciudad,
                                              s.SPREMRG_STREET_LINE3 Colonia,
                                              s.SPREMRG_ZIP as CP,
                                              s.SPREMRG_NATN_CODE as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              min(SPREMRG_PRIORITY) Prioridad,
                                              curp.CURP,
                                              'CURS' Grado,
                                              s.SPREMRG_LAST_NAME Razon_social,
                                              'UTELXEMCU' programa,
                                              'Bloque5' bloque,
                                              SPREMRG_RG_FS Reg_fiscal,--facto 4
                                              SPREMRG_CFDI cfdi --facto 4
                                            from SPREMRG s
                                            join SPRIDEN on s.SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
                                            join TBRACCD on s.SPREMRG_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE)= f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm  AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            left join GORADID on GORADID_PIDM = s.SPREMRG_PIDM AND GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on GOREMAL_PIDM = s.SPREMRG_PIDM AND GOREMAL_EMAL_CODE in ('PRIN', 'UTLX', 'UCAM')
                                            left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left join colegiatura on  colegiatura.pidm = spriden_pidm AND colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left join curp on curp.PIDM = SPRIDEN_PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1=1
                                            and TBBDETC_TYPE_IND = 'P'
                                           -- and TBBDETC_DCAT_CODE = 'CSH'
                                            and TBRACCD_AMOUNT >= 1
                                            and s.SPREMRG_PRIORITY = (select MAX(s1.SPREMRG_PRIORITY)
                                                                        FROM SPREMRG s1
                                                                        where s.SPREMRG_PIDM = s1.SPREMRG_PIDM)
                                            GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, s.SPREMRG_MI,
                                                            REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' '), s.SPREMRG_CITY, s.SPREMRG_STREET_LINE3,
                                                            s.SPREMRG_ZIP, s.SPREMRG_NATN_CODE, tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col, curp.CURP,TBRACCD_BALANCE, TBRACCD_CURR_CODE, TZTNCD_CONCEPTO, SPREMRG_RG_FS ,--facto 4
                                                            SPREMRG_CFDI
                                           UNION
                                            select DISTINCT
                                            tbraccd_pidm pidm ,
                                            spriden_id as Matricula,
                                            null as Nombre,
                                            'UTX' Campus,
                                            'EC' Nivel,
                                              CASE
                                              WHEN TBRACCD_CURR_CODE != 'MXN' THEN
                                                'XEXX010101000'
                                              WHEN TBRACCD_CURR_CODE = 'MXN' THEN
                                                'XAXX010101000'
                                              END as RFC,
                                            null as Dom_Fiscal,
                                            null as Ciudad,
                                            null colonia,
                                            null as CP,
                                            null as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'ACC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              null Prioridad,
                                              curp.CURP,
                                              'CURS' Grado,
                                             null Razon_social,
                                             'UTELXEMCU' programa,
                                             'Bloque6' bloque,
                                              null Reg_fiscal,--facto 4
                                              null cfdi --facto 4
                                            from SPRIDEN
                                            join TBRACCD on SPRIDEN_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            left join GORADID on SPRIDEN_PIDM = GORADID_PIDM and GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE  in ('PRIN', 'UTLX', 'UCAM')
                                            left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left join curp on SPRIDEN_PIDM = curp.PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1= 1
                                            And spriden_change_ind is null
                                            and TBBDETC_TYPE_IND = 'P'
                                           -- and TBBDETC_DCAT_CODE = 'CSH'
                                            And spriden_pidm not in (select SPREMRG_pidm from SPREMRG)
                                            And TBRACCD_AMOUNT >= 1
                                            GROUP BY tbraccd_pidm, spriden_id,
                                            tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TBRACCD_ENTRY_DATE,TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                            curp.CURP, TBRACCD_BALANCE, TBRACCD_CURR_CODE,TZTNCD_CONCEPTO

                                         ) loop

                                          vl_consecutivo := 0;
                                          vl_fecha_pago:=null;

                                              BEGIN

                                                 SELECT
                                                    CASE
                                                    WHEN (SYSDATE - 72/24) >= TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(SYSDATE,'YYYY-MM-DD"T"HH24:MI:SS')
                                                    WHEN (SYSDATE - 72/24) <  TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                                                    END INTO vl_fecha_pago
                                                    FROM TBRACCD
                                                    WHERE 1=1
                                                    AND TBRACCD_PIDM = f.spriden_pidm
                                                    AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER;
                                              EXCEPTION WHEN OTHERS THEN
                                              vl_fecha_pago:= ('0000-00-00"T"00:00:00');
                                               END;

                                               BEGIN
                                                SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                                                    INTO vl_consecutivo
                                                FROM TZTCRNT
                                                WHERE 1=1
                                                AND TZTCRTE_PIDM = f.spriden_pidm
                                                AND TZTCRTE_CAMPO10= f.TBRACCD_TRAN_NUMBER
                                                And TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia';
                                                EXCEPTION
                                                WHEN OTHERS THEN
                                                vl_consecutivo :=1;
                                               --DBMS_OUTPUT.PUT_LINE('Error XX3 '||sqlerrm);
                                                END;



                                            begin
                                             Insert into TZTCRNT values (a.pidm, --TZTCRTE_PIDM
                                                                            a.matricula, --TZTCRTE_ID
                                                                            a.campus,--TZTCRTE_CAMP
                                                                            a.nivel,--TZTCRTE_LEVL
                                                                            a.nombre,--TZTCRTE_CAMPO1
                                                                            a.rfc,--TZTCRTE_CAMPO2
                                                                            a.dom_fiscal,--TZTCRTE_CAMPO3
                                                                            a.ciudad,--TZTCRTE_CAMPO4
                                                                            a.cp,--TZTCRTE_CAMPO5
                                                                            a.pais,--TZTCRTE_CAMPO6
                                                                            a.tipo_deposito,--TZTCRTE_CAMP07
                                                                            a.descripcion,--TZTCRTE_CAMPO8
                                                                            a.monto,--TZTCRTE_CAMPO9
                                                                            a.transaccion,--TZTCRTE_CAMP1O
                                                                            vl_fecha_pago, --TZTCRTE_CAMPO11
                                                                            --a.fecha_pago,--TZTCRTE_CAMPO11
                                                                            a.referencia,--TZTCRTE_CAMPO12
                                                                            a.referencia_tipo,--TZTCRTE_CAMPO13
                                                                            a.email,--TZTCRTE_CAMPO14
                                                                            a.accesorio, ---TZTCRTE_CAMPO15
                                                                            --c.monto_pagado,--TZTCRTE_CAMPO15
                                                                            a.secuencia_pago,--TZTCRTE_CAMPO16
                                                                            a.descripcion_pago,---TZTCRTE_CAMPO17
                                                                            a.Categ_Col,--TZTCRTE_CAMPO18
                                                                            a.Prioridad,--TZTCRTE_CAMPO19
                                                                            a.CURP,--TZTCRTE_CAMPO20
                                                                            a.Grado,--TZTCRTE_CAMPO21
                                                                            a.Razon_social,--TZTCRTE_CAMPO22
                                                                            null, --TZTCRTE_CAMPO23
                                                                            null, --TZTCRTE_CAMPO24
                                                                            null, --TZTCRTE_CAMPO25
                                                                            a.programa, --TZTCRTE_CAMPO26
                                                                            a.colonia, --TZTCRTE_CAMPO27
                                                                            null, --TZTCRTE_CAMPO28
                                                                            null, --TZTCRTE_CAMPO29
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            a.bloque, --TZTCRTE_CAMPO56
                                                                            vl_consecutivo,
                                                                            a.balance, --TZTCRTE_CAMPO58
                                                                            USER||'- EMONTADI_FA', --TZTCRTE_CAMPO59
                                                                            TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                                            'Pago_Facturacion_dia',--TZTCRTE_TIPO_REPORTE
                                                                            a.Reg_fiscal,
                                                                            a.cfdi
                                                                            );
                                            --DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCRTE '||c.pidm||' '||c.monto||' '||c.transaccion||' '||c.Categ_Col);
                                          --  DBMS_OUTPUT.PUT_LINE(vl_bandera||'-'||a.RFC ||'-'||a.descripcion_pago||'-'||a.nombre||'-'||'Primero');
                                            Exception
                                                When Others then
                                                --      DBMS_OUTPUT.PUT_LINE('Error XX2 '||sqlerrm);
                                                      null;
                                            end;
                                        End Loop;
                                      COMMIT;
                      Exception
                            When Others then
                              --  DBMS_OUTPUT.PUT_LINE('Error XX1 '||sqlerrm);
                              null;

                      END;
  ElsIf  substr (f.SPRIDEN_ID, 1,2) in ('58') then ---> Campus 58

            --  DBMS_OUTPUT.PUT_LINE('Entro al 58 ');

                      BEGIN
DBMS_OUTPUT.PUT_LINE('Llego if 5');
                                   for a IN (
                                   with colegiatura as (Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbbdetc_desc desc_cargo,
                                            TBBDETC_DCAT_CODE Categ_Col
                                            from tbraccd a, tbbdetc b
                                            where 1=1
                                            and a.tbraccd_detail_code = b.tbbdetc_detail_code
                                            and  a.tbraccd_pidm = f.spriden_pidm
                                            ),
                                    curp as (select  GORADID_PIDM PIDM,
                                            GORADID_ADDITIONAL_ID CURP
                                            from GORADID
                                            where GORADID_ADID_CODE = 'CURP'
                                            AND LENGTH(GORADID_ADDITIONAL_ID)= 18
                                            GROUP BY GORADID_PIDM, GORADID_ADDITIONAL_ID)
                                            select DISTINCT
                                            tbraccd_pidm pidm ,
                                            spriden_id as Matricula,
                                            s.SPREMRG_LAST_NAME as Nombre,
                                            'CON' Campus,
                                            'EC' Nivel,
                                              CASE WHEN LENGTH(SPREMRG_MI) BETWEEN 1 AND 20 THEN
                                              NVL(SPREMRG_MI, 'XAXX010101000')
                                              WHEN TBRACCD_CURR_CODE != 'MXN' THEN
                                                'XEXX010101000'
                                              WHEN TBRACCD_CURR_CODE = 'MXN' THEN
                                                'XAXX010101000'
                                              END as RFC,
                                              REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' ') as Dom_Fiscal,
                                              s.SPREMRG_CITY as Ciudad,
                                              s.SPREMRG_STREET_LINE3 Colonia,
                                              s.SPREMRG_ZIP as CP,
                                              s.SPREMRG_NATN_CODE as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              min(SPREMRG_PRIORITY) Prioridad,
                                              curp.CURP,
                                              'CURS' Grado,
                                              s.SPREMRG_LAST_NAME Razon_social,
                                              'CONECTAMCU' programa,
                                              'Bloque5' bloque,
                                              SPREMRG_RG_FS Reg_fiscal,--facto 4
                                              SPREMRG_CFDI cfdi --facto 4
                                            from SPREMRG s
                                            join SPRIDEN on s.SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
                                            join TBRACCD on s.SPREMRG_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE)= f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm  AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            left join GORADID on GORADID_PIDM = s.SPREMRG_PIDM AND GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on GOREMAL_PIDM = s.SPREMRG_PIDM AND GOREMAL_EMAL_CODE in ('PRIN', 'UTLX', 'UCAM')
                                            left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left join colegiatura on  colegiatura.pidm = spriden_pidm AND colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left join curp on curp.PIDM = SPRIDEN_PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1=1
                                            and TBBDETC_TYPE_IND = 'P'
                                           -- and TBBDETC_DCAT_CODE = 'CSH'
                                            and TBRACCD_AMOUNT >= 1
                                            and s.SPREMRG_PRIORITY = (select MAX(s1.SPREMRG_PRIORITY)
                                                                        FROM SPREMRG s1
                                                                        where s.SPREMRG_PIDM = s1.SPREMRG_PIDM)
                                            GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, s.SPREMRG_MI,
                                                            REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' '), s.SPREMRG_CITY, s.SPREMRG_STREET_LINE3,
                                                            s.SPREMRG_ZIP, s.SPREMRG_NATN_CODE, tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col, curp.CURP,TBRACCD_BALANCE, TBRACCD_CURR_CODE, TZTNCD_CONCEPTO
                                           UNION
                                            select DISTINCT
                                            tbraccd_pidm pidm ,
                                            spriden_id as Matricula,
                                            null as Nombre,
                                            'CON' Campus,
                                            'EC' Nivel,
                                              CASE
                                              WHEN TBRACCD_CURR_CODE != 'MXN' THEN
                                                'XEXX010101000'
                                              WHEN TBRACCD_CURR_CODE = 'MXN' THEN
                                                'XAXX010101000'
                                              END as RFC,
                                            null as Dom_Fiscal,
                                            null as Ciudad,
                                            null colonia,
                                            null as CP,
                                            null as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'ACC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              null Prioridad,
                                              curp.CURP,
                                              'CURS' Grado,
                                             null Razon_social,
                                             'CONECTAMCU' programa,
                                             'Bloque6' bloque,
                                             null Reg_fiscal,--facto 4
                                             null cfdi --facto 4
                                            from SPRIDEN
                                            join TBRACCD on SPRIDEN_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            left join GORADID on SPRIDEN_PIDM = GORADID_PIDM and GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE  in ('PRIN', 'UTLX', 'UCAM')
                                            left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left join curp on SPRIDEN_PIDM = curp.PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1= 1
                                            And spriden_change_ind is null
                                            and TBBDETC_TYPE_IND = 'P'
                                           -- and TBBDETC_DCAT_CODE = 'CSH'
                                            And spriden_pidm not in (select SPREMRG_pidm from SPREMRG)
                                            And TBRACCD_AMOUNT >= 1
                                            GROUP BY tbraccd_pidm, spriden_id,
                                            tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TBRACCD_ENTRY_DATE,TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                            curp.CURP, TBRACCD_BALANCE, TBRACCD_CURR_CODE,TZTNCD_CONCEPTO

                                         ) loop

                                          vl_consecutivo := 0;
                                          vl_fecha_pago:=null;

                                       --   DBMS_OUTPUT.PUT_LINE('Entro al FOR  al 58 ');

                                              BEGIN

                                                 SELECT
                                                    CASE
                                                    WHEN (SYSDATE - 72/24) >= TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(SYSDATE,'YYYY-MM-DD"T"HH24:MI:SS')
                                                    WHEN (SYSDATE - 72/24) <  TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                                                    END INTO vl_fecha_pago
                                                    FROM TBRACCD
                                                    WHERE 1=1
                                                    AND TBRACCD_PIDM = f.spriden_pidm
                                                    AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER;
                                              EXCEPTION WHEN OTHERS THEN
                                              vl_fecha_pago:= ('0000-00-00"T"00:00:00');
                                               END;

                                               BEGIN
                                                SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                                                    INTO vl_consecutivo
                                                FROM TZTCRNT
                                                WHERE 1=1
                                                AND TZTCRTE_PIDM = f.spriden_pidm
                                                AND TZTCRTE_CAMPO10= f.TBRACCD_TRAN_NUMBER
                                                And TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia';
                                                EXCEPTION
                                                WHEN OTHERS THEN
                                                vl_consecutivo :=1;
                                               --DBMS_OUTPUT.PUT_LINE('Error XX3 '||sqlerrm);
                                                END;

                             --    DBMS_OUTPUT.PUT_LINE('Entro al 58 por consecutivo  '||vl_consecutivo);

                                            begin
                                             Insert into TZTCRNT values (a.pidm, --TZTCRTE_PIDM
                                                                            a.matricula, --TZTCRTE_ID
                                                                            a.campus,--TZTCRTE_CAMP
                                                                            a.nivel,--TZTCRTE_LEVL
                                                                            a.nombre,--TZTCRTE_CAMPO1
                                                                            a.rfc,--TZTCRTE_CAMPO2
                                                                            a.dom_fiscal,--TZTCRTE_CAMPO3
                                                                            a.ciudad,--TZTCRTE_CAMPO4
                                                                            a.cp,--TZTCRTE_CAMPO5
                                                                            a.pais,--TZTCRTE_CAMPO6
                                                                            a.tipo_deposito,--TZTCRTE_CAMP07
                                                                            a.descripcion,--TZTCRTE_CAMPO8
                                                                            a.monto,--TZTCRTE_CAMPO9
                                                                            a.transaccion,--TZTCRTE_CAMP1O
                                                                            vl_fecha_pago, --TZTCRTE_CAMPO11
                                                                            --a.fecha_pago,--TZTCRTE_CAMPO11
                                                                            a.referencia,--TZTCRTE_CAMPO12
                                                                            a.referencia_tipo,--TZTCRTE_CAMPO13
                                                                            a.email,--TZTCRTE_CAMPO14
                                                                            a.accesorio, ---TZTCRTE_CAMPO15
                                                                            --c.monto_pagado,--TZTCRTE_CAMPO15
                                                                            a.secuencia_pago,--TZTCRTE_CAMPO16
                                                                            a.descripcion_pago,---TZTCRTE_CAMPO17
                                                                            a.Categ_Col,--TZTCRTE_CAMPO18
                                                                            a.Prioridad,--TZTCRTE_CAMPO19
                                                                            a.CURP,--TZTCRTE_CAMPO20
                                                                            a.Grado,--TZTCRTE_CAMPO21
                                                                            a.Razon_social,--TZTCRTE_CAMPO22
                                                                            null, --TZTCRTE_CAMPO23
                                                                            null, --TZTCRTE_CAMPO24
                                                                            null, --TZTCRTE_CAMPO25
                                                                            a.programa, --TZTCRTE_CAMPO26
                                                                            a.colonia, --TZTCRTE_CAMPO27
                                                                            null, --TZTCRTE_CAMPO28
                                                                            null, --TZTCRTE_CAMPO29
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            a.bloque, --TZTCRTE_CAMPO56
                                                                            vl_consecutivo,
                                                                            a.balance, --TZTCRTE_CAMPO58
                                                                            USER||'- EMONTADI_FA', --TZTCRTE_CAMPO59
                                                                            TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                                            'Pago_Facturacion_dia',--TZTCRTE_TIPO_REPORTE
                                                                            a.Reg_fiscal,
                                                                            a.cfdi
                                                                            );
                                            --DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCRTE '||c.pidm||' '||c.monto||' '||c.transaccion||' '||c.Categ_Col);
                                          --  DBMS_OUTPUT.PUT_LINE(vl_bandera||'-'||a.RFC ||'-'||a.descripcion_pago||'-'||a.nombre||'-'||'Primero');
                                       --    DBMS_OUTPUT.PUT_LINE('Inserto para el 58 ');

                                            Exception
                                                When Others then
                                                   --   DBMS_OUTPUT.PUT_LINE('Error XX2 '||sqlerrm);
                                                      null;
                                            end;
                                        End Loop;
                                      COMMIT;
                      Exception
                            When Others then
                              --  DBMS_OUTPUT.PUT_LINE('Error XX1 '||sqlerrm);
                              null;

                      END;

            Else
                       BEGIN
                                DBMS_OUTPUT.PUT_LINE('Entra else ');
                                   for a IN (

                                   with colegiatura as (Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbbdetc_desc desc_cargo,
                                            TBBDETC_DCAT_CODE Categ_Col
                                            from tbraccd a, tbbdetc b
                                            where 1=1
                                            and a.tbraccd_detail_code = b.tbbdetc_detail_code
                                            and  a.tbraccd_pidm = f.spriden_pidm
                                            ),
                                    curp as (select  GORADID_PIDM PIDM,
                                            GORADID_ADDITIONAL_ID CURP
                                            from GORADID
                                            where GORADID_ADID_CODE = 'CURP'
                                            AND LENGTH(GORADID_ADDITIONAL_ID)= 18
                                            GROUP BY GORADID_PIDM, GORADID_ADDITIONAL_ID)
                                            select DISTINCT
                                            tbraccd_pidm pidm ,
                                            spriden_id as Matricula,
                                            s.SPREMRG_LAST_NAME as Nombre,
                                            nvl(SARADAP_CAMP_CODE,(select SZVCAMP_CAMP_CODE
                                                                   from spriden, szvcamp
                                                                   where 1=1
                                                                   and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                   and spriden_id = f.spriden_id
                                                                   And spriden_Change_ind is null
                                                                   )
                                            )as Campus,
                                            nvl(SARADAP_LEVL_CODE,(select  x.Casse nivel
                                                                        from (select distinct SZVCAMP_CAMP_CODE campus, spriden_id Matricula,
                                                                                case
                                                                                    When SZVCAMP_CAMP_CODE ='UTL' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='UTS' then 'MS'
                                                                                    When SZVCAMP_CAMP_CODE ='UMM' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='COL' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='UIN' then 'MA'
                                                                                    When SZVCAMP_CAMP_CODE ='CHI' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='COE' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='PER' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='ECU' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='UVE' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='EBE' then 'MS'
                                                                                    When SZVCAMP_CAMP_CODE ='UNA' then 'MA'
                                                                                    When SZVCAMP_CAMP_CODE ='UNI' then 'LI'
                                                                                    When  SZVCAMP_CAMP_CODE ='BOT' then 'EC'
                                                                                 End Casse
                                                                        from spriden, szvcamp
                                                                        where 1=1
                                                                        and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                        And spriden_change_ind is null
                                                                     )x
                                                                     where 1=1
                                                                     and x.Matricula = f.spriden_id
                                                                     )
                                              )as Nivel,
                                              CASE WHEN LENGTH(SPREMRG_MI) BETWEEN 1 AND 20 THEN
                                              NVL(SPREMRG_MI, 'XAXX010101000')
                                              WHEN SPREMRG_MI IS NULL AND SARADAP_CAMP_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                                                                   FROM ZSTPARA
                                                                                                   WHERE 1=1
                                                                                                   AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                                              THEN
                                              'XAXX010101000'
                                              WHEN
                                                nvl(SARADAP_CAMP_CODE,(select SZVCAMP_CAMP_CODE
                                                                       from spriden, szvcamp
                                                                       where 1=1
                                                                       and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                       and spriden_id = f.spriden_id
                                                                        And spriden_change_ind is null)
                                                                      )
                                              IN (SELECT ZSTPARA_PARAM_VALOR
                                              FROM ZSTPARA
                                              WHERE 1=1
                                              AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                                              THEN
                                               'XEXX010101000'
                                              END as RFC,
                                              REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' ') as Dom_Fiscal,
                                              s.SPREMRG_CITY as Ciudad,
                                              s.SPREMRG_STREET_LINE3 Colonia,
                                              s.SPREMRG_ZIP as CP,
                                              s.SPREMRG_NATN_CODE as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS') as Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              min(SPREMRG_PRIORITY) Prioridad,
                                              curp.CURP,
                                              SARADAP_DEGC_CODE_1 Grado,
                                              s.SPREMRG_LAST_NAME Razon_social,
                                              SARADAP_PROGRAM_1 programa,
                                              'Bloque1' bloque,
                                              SPREMRG_RG_FS Reg_fiscal,--facto 4
                                              SPREMRG_CFDI cfdi --facto 4
                                            from SPREMRG s
                                            join SPRIDEN on s.SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
                                            join TBRACCD on s.SPREMRG_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE)= f.TRUNC_DATE  AND TBRACCD_PIDM =  f.spriden_pidm  AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            join SARADAP on SARADAP_PIDM = s.SPREMRG_PIDM AND SARADAP_APPL_NO = vl_appl_no AND SARADAP_PROGRAM_1 = vl_program
                                            left join GORADID on GORADID_PIDM = s.SPREMRG_PIDM AND GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on GOREMAL_PIDM = s.SPREMRG_PIDM AND GOREMAL_EMAL_CODE in ('PRIN')
                                            left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left join colegiatura on  colegiatura.pidm = spriden_pidm AND colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left join curp on curp.PIDM = SPRIDEN_PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1=1
                                            and TBBDETC_TYPE_IND = 'P'
                                            --and TBBDETC_DCAT_CODE = 'CSH'
                                            and TBRACCD_AMOUNT >= 1
                                            and s.SPREMRG_PRIORITY = (select MAX(s1.SPREMRG_PRIORITY)
                                                                        FROM SPREMRG s1
                                                                        where s.SPREMRG_PIDM = s1.SPREMRG_PIDM)
                                            GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, saradap_camp_code, SARADAP_LEVL_CODE, s.SPREMRG_MI,
                                                            REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' '), s.SPREMRG_CITY, s.SPREMRG_STREET_LINE3,
                                                            s.SPREMRG_ZIP, s.SPREMRG_NATN_CODE, tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                                            curp.CURP, SARADAP_DEGC_CODE_1, SARADAP_PROGRAM_1,TBRACCD_BALANCE, TZTNCD_CONCEPTO ,SPREMRG_RG_FS,SPREMRG_CFDI
                                          UNION
                                            select DISTINCT
                                            tbraccd_pidm pidm ,
                                            spriden_id as Matricula,
                                            null as Nombre,
                                            nvl(SARADAP_CAMP_CODE,(select SZVCAMP_CAMP_CODE
                                                                   from spriden, szvcamp
                                                                   where 1=1
                                                                   and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                   and spriden_id = f.spriden_id
                                                                   And spriden_change_ind is null
                                                                   )
                                            )as Campus,
                                            nvl(SARADAP_LEVL_CODE,(select  x.Casse nivel
                                                                        from (select distinct SZVCAMP_CAMP_CODE campus, spriden_id Matricula,
                                                                                case
                                                                                    When SZVCAMP_CAMP_CODE ='UTL' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='UTS' then 'MS'
                                                                                    When SZVCAMP_CAMP_CODE ='UMM' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='COL' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='UIN' then 'MA'
                                                                                    When SZVCAMP_CAMP_CODE ='CHI' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='COE' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='PER' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='ECU' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='UVE' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='EBE' then 'MS'
                                                                                    When SZVCAMP_CAMP_CODE ='UNA' then 'MA'
                                                                                    When SZVCAMP_CAMP_CODE ='UNI' then 'LI'
                                                                                    When  SZVCAMP_CAMP_CODE ='BOT' then 'EC'
                                                                                 End Casse
                                                                        from spriden, szvcamp
                                                                        where 1=1
                                                                        and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                        And spriden_change_ind is null
                                                                     )x
                                                                     where 1=1
                                                                     and x.Matricula = f.spriden_id )
                                              )as Nivel,
                                              CASE WHEN
                                                nvl(SARADAP_CAMP_CODE,(select SZVCAMP_CAMP_CODE
                                                                                           from spriden, szvcamp
                                                                                           where 1=1
                                                                                           and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                                           and spriden_id = f.spriden_id
                                                                                            And spriden_change_ind is null)
                                                                                            )
                                                IN (SELECT ZSTPARA_PARAM_VALOR
                                                FROM ZSTPARA
                                                WHERE 1=1
                                                AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                                              THEN
                                               'XEXX010101000'
                                              WHEN
                                                nvl(SARADAP_CAMP_CODE,(select SZVCAMP_CAMP_CODE
                                                                       from spriden, szvcamp
                                                                       where 1=1
                                                                       and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                       and spriden_id = f.spriden_id
                                                                       And spriden_change_ind is null))
                                                 NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                               FROM ZSTPARA
                                                               WHERE 1=1
                                                               AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                                              THEN
                                               'XAXX010101000'
                                              END RFC,
                                            null as Dom_Fiscal,
                                            null as Ciudad,
                                            null colonia,
                                            null as CP,
                                            null as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS') as Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'ACC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              null Prioridad,
                                              curp.CURP,
                                              SARADAP_DEGC_CODE_1 Grado,
                                             null Razon_social,
                                             SARADAP_PROGRAM_1 programa,
                                             'Bloque2' bloque,
                                              null Reg_fiscal,--facto 4
                                              null cfdi --facto 4
                                            from SPRIDEN
                                            join TBRACCD on SPRIDEN_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE  AND TBRACCD_PIDM =  f.spriden_pidm AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            join SARADAP on SPRIDEN_PIDM = SARADAP_PIDM AND SARADAP_APPL_NO = vl_appl_no  AND SARADAP_PROGRAM_1 = vl_program
                                            left join GORADID on SPRIDEN_PIDM = GORADID_PIDM and GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                                            left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left join curp on SPRIDEN_PIDM = curp.PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1= 1
                                            And spriden_change_ind is null
                                            and TBBDETC_TYPE_IND = 'P'
                                           -- and TBBDETC_DCAT_CODE = 'CSH'
                                            And spriden_pidm not in (select SPREMRG_pidm from SPREMRG)
                                            And TBRACCD_AMOUNT >= 1
                                            GROUP BY tbraccd_pidm, spriden_id,
                                                            saradap_camp_code, SARADAP_LEVL_CODE,
                                                            tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                                            curp.CURP, SARADAP_DEGC_CODE_1,SARADAP_PROGRAM_1,TBRACCD_BALANCE ,TZTNCD_CONCEPTO
                                           UNION

                                         select DISTINCT
                                              tbraccd_pidm pidm ,
                                              spriden_id as Matricula,
                                              null as Nombre,
                                            nvl(TZTPAGO_CAMP,(select SZVCAMP_CAMP_CODE
                                                                   from spriden, szvcamp
                                                                   where 1=1
                                                                   and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                   And spriden_change_ind is null
                                                                   and spriden_id = f.spriden_id)
                                            )as Campus,
                                            nvl(TZTPAGO_LEVL,(select  x.Casse nivel
                                                                        from (select distinct SZVCAMP_CAMP_CODE campus, spriden_id Matricula,
                                                                                case
                                                                                    When SZVCAMP_CAMP_CODE ='UTL' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='UTS' then 'MS'
                                                                                    When SZVCAMP_CAMP_CODE ='UMM' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='COL' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='UIN' then 'MA'
                                                                                    When SZVCAMP_CAMP_CODE ='CHI' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='COE' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='PER' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='ECU' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='UVE' then 'LI'
                                                                                    When SZVCAMP_CAMP_CODE ='EBE' then 'MS'
                                                                                    When SZVCAMP_CAMP_CODE ='UNA' then 'MA'
                                                                                    When SZVCAMP_CAMP_CODE ='UNI' then 'LI'
                                                                                    When  SZVCAMP_CAMP_CODE ='BOT' then 'EC'
                                                                                 End Casse
                                                                        from spriden, szvcamp
                                                                        where 1=1
                                                                        and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                        And spriden_change_ind is null
                                                                     )x
                                                                     where 1=1
                                                                     and x.Matricula = f.spriden_id
                                                                      )
                                              )as Nivel,
                                              CASE WHEN
                                              TZTPAGO_CAMP IN (SELECT ZSTPARA_PARAM_VALOR
                                                                FROM ZSTPARA
                                                                WHERE 1=1
                                                                AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                                              THEN 'XEXX010101000'
                                              WHEN TZTPAGO_CAMP NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                                        FROM ZSTPARA
                                                                        WHERE 1=1
                                                                        AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                                              THEN 'XAXX010101000'
                                              WHEN substr (spriden_id,3,2)  = '99'
                                              THEN 'XAXX010101000'
                                              END RFC,
                                              null as Dom_Fiscal,
                                              null as Ciudad,
                                              null colonia,
                                              null as CP,
                                              null as Pais,
                                              tbraccd_detail_code as Tipo_Deposito,
                                              tbraccd_desc as Descripcion,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                              TBRACCD_TRAN_NUMBER as Transaccion,
                                              TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS') as Fecha_Pago,
                                              GORADID_ADDITIONAL_ID as REFERENCIA,
                                              GORADID_ADID_CODE as Referencia_Tipo,
                                              GOREMAL_EMAIL_ADDRESS as EMAIL,
                                              to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                              to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                              TBRAPPL_AMOUNT accesorio,
                                              TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'PCOLEGIATURA'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN colegiatura.desc_cargo
                                              END descripcion_pago,
                                              CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                              THEN 'COL'
                                              WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                              THEN NVL(colegiatura.Categ_Col,'COL')
                                              END Categ_Col,
                                              null Prioridad,
                                              curp.CURP,
                                              Null as Grado,
                                             null Razon_social,
                                             TZTPAGO_PROGRAMA  programa,
                                             'Bloque3' bloque,
                                             null Reg_fiscal,--facto 4
                                             null cfdi --facto 4
                                            from TAISMGR.TZTPAGOS_FACT a
                                            join SPRIDEN on SPRIDEN_ID = a.TZTPAGO_ID and SPRIDEN_CHANGE_IND IS NULL
                                            join TBRACCD on SPRIDEN_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                            join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            left join GORADID on SPRIDEN_PIDM = GORADID_PIDM and GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                            left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                                            left outer join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                            left outer join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                            left outer join curp on SPRIDEN_PIDM = curp.PIDM
                                            join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            where 1= 1
                                            and TBBDETC_TYPE_IND = 'P'
                                           -- and TBBDETC_DCAT_CODE = 'CSH'
                                            And spriden_pidm not in (select saradap_pidm from saradap
                                                                  WHERE 1=1
                                                                  AND SARADAP_PROGRAM_1 = TZTPAGO_PROGRAMA
                                                                  AND SARADAP_APPL_NO = vl_appl_no)
                                            And TZTPAGO_STAT_INSCR <>'ALUMNO'
                                            And TZTPAGO_STAT_SOLIC <> 'Enviada'
                                            And TZTPAGO_STAT_INSCR <> 'CANCELADA'
                                            and TBRACCD_AMOUNT >= 1
                                            GROUP BY tbraccd_pidm, spriden_id,
                                                            TZTPAGO_CAMP, TZTPAGO_LEVL,
                                                            tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                                            GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                                            curp.CURP, TZTPAGO_PROGRAMA,TBRACCD_BALANCE,TZTNCD_CONCEPTO


                                         ) loop

                                          vl_consecutivo := 0;
                                          vl_fecha_pago:=null;

                                              BEGIN

                                                 SELECT
                                                    CASE
                                                    WHEN (SYSDATE - 72/24) >= TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(SYSDATE,'YYYY-MM-DD"T"HH24:MI:SS')
                                                    WHEN (SYSDATE - 72/24) <  TBRACCD_ENTRY_DATE THEN
                                                    TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                                                    END INTO vl_fecha_pago
                                                    FROM TBRACCD
                                                    WHERE 1=1
                                                    AND TBRACCD_PIDM = f.spriden_pidm
                                                    AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER;
                                              EXCEPTION WHEN OTHERS THEN
                                              vl_fecha_pago:= ('0000-00-00"T"00:00:00');
                                              END;

                                               BEGIN
                                                SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                                                    INTO vl_consecutivo
                                                FROM TZTCRNT
                                                WHERE 1=1
                                                AND TZTCRTE_PIDM = f.spriden_pidm
                                                AND TZTCRTE_CAMPO10= f.TBRACCD_TRAN_NUMBER
                                                And TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia';
                                                EXCEPTION
                                                WHEN OTHERS THEN
                                                vl_consecutivo :=1;
                                               --DBMS_OUTPUT.PUT_LINE('Error XX3 '||sqlerrm);
                                                END;



                                            begin
                                             Insert into TZTCRNT values (a.pidm, --TZTCRTE_PIDM
                                                                            a.matricula, --TZTCRTE_ID
                                                                            a.campus,--TZTCRTE_CAMP
                                                                            a.nivel,--TZTCRTE_LEVL
                                                                            a.nombre,--TZTCRTE_CAMPO1
                                                                            a.rfc,--TZTCRTE_CAMPO2
                                                                            a.dom_fiscal,--TZTCRTE_CAMPO3
                                                                            a.ciudad,--TZTCRTE_CAMPO4
                                                                            a.cp,--TZTCRTE_CAMPO5
                                                                            a.pais,--TZTCRTE_CAMPO6
                                                                            a.tipo_deposito,--TZTCRTE_CAMP07
                                                                            a.descripcion,--TZTCRTE_CAMPO8
                                                                            a.monto,--TZTCRTE_CAMPO9
                                                                            a.transaccion,--TZTCRTE_CAMP1O
                                                                            vl_fecha_pago, --TZTCRTE_CAMPO11
                                                                            --a.fecha_pago,--TZTCRTE_CAMPO11
                                                                            a.referencia,--TZTCRTE_CAMPO12
                                                                            a.referencia_tipo,--TZTCRTE_CAMPO13
                                                                            a.email,--TZTCRTE_CAMPO14
                                                                            a.accesorio, ---TZTCRTE_CAMPO15
                                                                            --c.monto_pagado,--TZTCRTE_CAMPO15
                                                                            a.secuencia_pago,--TZTCRTE_CAMPO16
                                                                            a.descripcion_pago,---TZTCRTE_CAMPO17
                                                                            a.Categ_Col,--TZTCRTE_CAMPO18
                                                                            a.Prioridad,--TZTCRTE_CAMPO19
                                                                            a.CURP,--TZTCRTE_CAMPO20
                                                                            a.Grado,--TZTCRTE_CAMPO21
                                                                            a.Razon_social,--TZTCRTE_CAMPO22
                                                                            null, --TZTCRTE_CAMPO23
                                                                            null, --TZTCRTE_CAMPO24
                                                                            null, --TZTCRTE_CAMPO25
                                                                            a.programa, --TZTCRTE_CAMPO26
                                                                            a.colonia, --TZTCRTE_CAMPO27
                                                                            null, --TZTCRTE_CAMPO28
                                                                            null, --TZTCRTE_CAMPO29
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            null,
                                                                            a.bloque, --TZTCRTE_CAMPO56
                                                                            vl_consecutivo,
                                                                            a.balance, --TZTCRTE_CAMPO58
                                                                            USER||'- EMONTADI_FA', --TZTCRTE_CAMPO59
                                                                            TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                                            'Pago_Facturacion_dia',--TZTCRTE_TIPO_REPORTE
                                                                            a.reg_fiscal,
                                                                            a.cfdi
                                                                            );
                                          --  DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCRTE '||c.pidm||' '||c.monto||' '||c.transaccion||' '||c.Categ_Col);
                                            DBMS_OUTPUT.PUT_LINE(vl_bandera||'-'||a.RFC ||'-'||a.descripcion_pago||'-'||a.nombre||'-'||'Primero');
                                            Exception
                                                When Others then
                                                --      DBMS_OUTPUT.PUT_LINE('Error XX2 '||sqlerrm);
                                                      null;
                                            end;
                                        End Loop;
                                      COMMIT;
                       Exception
                            When Others then
                              --  DBMS_OUTPUT.PUT_LINE('Error XX1 '||sqlerrm);
                              null;

                       END;

            End if;

                     BEGIN

                            BEGIN
                            SELECT TZTCRTE_CAMPO58
                            INTO vl_balance
                            FROM TZTCRNT
                            WHERE 1=1
                            AND TZTCRTE_PIDM = f.SPRIDEN_PIDM
                            AND TZTCRTE_CAMPO10 = f.TBRACCD_TRAN_NUMBER
                            AND TZTCRTE_TIPO_REPORTE ='Pago_Facturacion_dia'
                            GROUP BY TZTCRTE_CAMPO58;
                            EXCEPTION
                            WHEN OTHERS THEN
                            NULL;
                            END;

                            BEGIN
                            SELECT COUNT(TZTCRTE_CAMPO18)
                            INTO vl_valida_col
                            FROM TZTCRNT
                            WHERE 1=1
                            AND TZTCRTE_PIDM = f.SPRIDEN_PIDM
                            AND TZTCRTE_CAMPO10 = f.TBRACCD_TRAN_NUMBER
                            AND TZTCRTE_TIPO_REPORTE ='Pago_Facturacion_dia'
                            AND TZTCRTE_CAMPO18 ='COL';
                            EXCEPTION
                            WHEN OTHERS THEN
                            NULL;
                            END;

                         IF vl_balance like '-%' AND vl_valida_col = 0 THEN

                         vl_consecutivo:=0;

                           BEGIN
                            SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                            INTO vl_consecutivo
                            FROM TZTCRNT
                            WHERE 1=1
                            AND TZTCRTE_PIDM = f.SPRIDEN_PIDM
                            AND TZTCRTE_CAMPO10= f.TBRACCD_TRAN_NUMBER
                            And TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia';
                            EXCEPTION
                            WHEN OTHERS THEN
                            vl_consecutivo :=1;
                           END;

                            BEGIN
                            INSERT INTO TZTCRNT
                            SELECT
                            a.TZTCRTE_PIDM, a.TZTCRTE_ID, a.TZTCRTE_CAMP, a.TZTCRTE_LEVL, a.TZTCRTE_CAMPO1,
                                a.TZTCRTE_CAMPO2, a.TZTCRTE_CAMPO3, a.TZTCRTE_CAMPO4, a.TZTCRTE_CAMPO5, a.TZTCRTE_CAMPO6,
                                a.TZTCRTE_CAMPO7, a.TZTCRTE_CAMPO8, a.TZTCRTE_CAMPO9, a.TZTCRTE_CAMPO10, a.TZTCRTE_CAMPO11,
                                a.TZTCRTE_CAMPO12, a.TZTCRTE_CAMPO13, a.TZTCRTE_CAMPO14,a.TZTCRTE_CAMPO58 * -1,Null, 'COLEGIATURA '||a.TZTCRTE_CAMPO21,
                                'COL', Null, a.TZTCRTE_CAMPO20, a.TZTCRTE_CAMPO21, a.TZTCRTE_CAMPO22, Null, Null, Null,
                                a.TZTCRTE_CAMPO26, TZTCRTE_CAMPO27, Null, Null, Null,Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null,
                                Null, Null, Null, Null ,Null, Null, Null, Null, Null, Null, Null, Null, Null,a.TZTCRTE_CAMPO56, vl_consecutivo,
                                a.TZTCRTE_CAMPO58, user||' - BALANCE DIRECCIONADO A COL', TRUNC(SYSDATE),'Pago_Facturacion_dia',a.tztcrte_Reg_fiscal,a.tztcrte_Cfdi
                            FROM TZTCRNT a
                            WHERE 1= 1
                            AND a.TZTCRTE_PIDM = f.SPRIDEN_PIDM
                            AND TO_NUMBER(a.TZTCRTE_CAMPO10) = f.TBRACCD_TRAN_NUMBER
                            AND a.TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                            AND a.TZTCRTE_CAMP is not null
                            AND a.TZTCRTE_CAMPO57 = (SELECT MAX(TZTCRTE_CAMPO57)
                                                   FROM TZTCRNT b
                                                   WHERE 1=1
                                                   AND a.TZTCRTE_PIDM =b.TZTCRTE_PIDM
                                                   AND a.TZTCRTE_CAMP = b.TZTCRTE_CAMP
                                                   AND a.TZTCRTE_CAMPO10 = b.TZTCRTE_CAMPO10);
                            EXCEPTION WHEN OTHERS THEN
                            DBMS_OUTPUT.PUT_LINE('ERROR AQU  '||f.SPRIDEN_PIDM||'-'||f.TBRACCD_TRAN_NUMBER||'-'||vl_consecutivo||SQLERRM);
                           END;

                       ELSIF vl_balance like '-%' AND vl_valida_col > 0 THEN

                        --dbms_output.put_line(vl_balance||'-'||vl_valida_col);

                        vl_new_balance := (vl_balance)*-1;


                        BEGIN

                        UPDATE TZTCRNT a SET a.TZTCRTE_CAMPO15 = a.TZTCRTE_CAMPO15 + vl_new_balance, TZTCRTE_CAMPO59 = USER||'- CAMPO15 SUMADO CON BALANCE'
                        WHERE 1=1
                        AND a.TZTCRTE_PIDM = f.SPRIDEN_PIDM
                        AND a.TZTCRTE_CAMPO10 = f.TBRACCD_TRAN_NUMBER
                        AND a.TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                        AND a.TZTCRTE_CAMPO18 = 'COL'
                        AND a.TZTCRTE_CAMPO16 = (SELECT min(TZTCRTE_CAMPO16)
                                                    FROM TZTCRNT b
                                                    WHERE 1=1
                                                    AND b.TZTCRTE_PIDM = a.TZTCRTE_PIDM
                                                    AND b.TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                                                    AND b.TZTCRTE_CAMPO18 = a.TZTCRTE_CAMPO18);
                        END;


                       END IF;
                      COMMIT;

                     END;


               BEGIN

                     For c in (with intereses as (select distinct
                                            TZTCRTE_PIDM Pidm,
                                            TZTCRTE_LEVL as Nivel,
                                            TZTCRTE_CAMP as Campus,
                                            TZTCRTE_CAMPO11  as Fecha_Pago,
                                            TZTCRTE_CAMPO17 as Intereses,
                                            sum (TZTCRTE_CAMPO15) as Monto_intereses,
                                            TZTCRTE_CAMPO18 as Categoria,
                                            TZTCRTE_CAMPO10 as Secuencia,
                                            TZTCRTE_CAMPO26 programa,
                                            TZTCRTE_CAMPO27 colonia,
                                            TZTCRTE_CAMPO56 bloque,
                                            TZTCRTE_CAMPO58 balance
                                            from TZTCRNT
                                            where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                            and TZTCRTE_CAMPO18 = 'INT'
                                            group by
                                                      TZTCRTE_PIDM,
                                                      TZTCRTE_LEVL,
                                                      TZTCRTE_CAMP,
                                                      TZTCRTE_CAMPO11,
                                                      TZTCRTE_CAMPO17,
                                                      TZTCRTE_CAMPO18,
                                                      TZTCRTE_CAMPO10,
                                                      TZTCRTE_CAMPO26,
                                                      TZTCRTE_CAMPO27,
                                                      TZTCRTE_CAMPO56,
                                                      TZTCRTE_CAMPO58
                                            ),
                                            accesorios as (
                                            select distinct
                                                      TZTCRTE_PIDM Pidm,
                                                      TZTCRTE_LEVL as Nivel,
                                                      TZTCRTE_CAMP as Campus,
                                                      TZTCRTE_CAMPO11  as Fecha_Pago,
                                                      TZTCRTE_CAMPO17 as accesorios,
                                                      TO_CHAR(SUM(TO_NUMBER (TZTCRTE_CAMPO15)),'fm9999999990.00') as Monto_accesorios,
                                                      TZTCRTE_CAMPO18 as Categoria,
                                                      TZTCRTE_CAMPO10 as Secuencia,
                                                      TZTCRTE_CAMPO26 programa,
                                                      TZTCRTE_CAMPO27 colonia,
                                                      TZTCRTE_CAMPO56 bloque,
                                                      TZTCRTE_CAMPO58 balance
                                            from TZTCRNT
                                            where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                            and TZTCRTE_CAMPO18 in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                                            group by
                                                      TZTCRTE_PIDM,
                                                      TZTCRTE_LEVL,
                                                      TZTCRTE_CAMP,
                                                      TZTCRTE_CAMPO11,
                                                      TZTCRTE_CAMPO17,
                                                      TZTCRTE_CAMPO18,
                                                      TZTCRTE_CAMPO10,
                                                      TZTCRTE_CAMPO26,
                                                      TZTCRTE_CAMPO27,
                                                      TZTCRTE_CAMPO56,
                                                      TZTCRTE_CAMPO58
                                                      --TZTCRTE_CAMPO15
                                            ),
                                            colegiatura as (
                                            select distinct
                                                      TZTCRTE_PIDM Pidm,
                                                      TZTCRTE_LEVL as Nivel,
                                                      TZTCRTE_CAMP as Campus,
                                                      TZTCRTE_CAMPO11  as Fecha_Pago,
                                                      TZTCRTE_CAMPO17 as colegiatura,
                                                      TO_CHAR(SUM(TO_NUMBER(TZTCRTE_CAMPO15)),'fm9999999990.00') as Monto_colegiatura,
                                                      TZTCRTE_CAMPO18 as Categoria,
                                                      TZTCRTE_CAMPO10 as Secuencia,
                                                      TZTCRTE_CAMPO26 programa,
                                                      TZTCRTE_CAMPO27 colonia,
                                                      TZTCRTE_CAMPO56 bloque,
                                                      TZTCRTE_CAMPO58 balance,
                                                      TZTCRTE_REG_FISCAL reg_fiscal,
                                                      TZTCRTE_CFDI cfdi
                                            from TZTCRNT
                                            where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                            and TZTCRTE_CAMPO18 in  ('COL')
                                            group by
                                                      TZTCRTE_PIDM,
                                                      TZTCRTE_LEVL,
                                                      TZTCRTE_CAMP,
                                                      TZTCRTE_CAMPO11,
                                                      TZTCRTE_CAMPO17,
                                                      TZTCRTE_CAMPO18,
                                                      TZTCRTE_CAMPO10,
                                                      TZTCRTE_CAMPO26,
                                                      TZTCRTE_CAMPO27,
                                                      TZTCRTE_CAMPO56,
                                                      TZTCRTE_CAMPO58,
                                                      TZTCRTE_REG_FISCAL,
                                                      TZTCRTE_CFDI
                                            ),
                                            otros as (
                                            select distinct
                                                      TZTCRTE_PIDM Pidm,
                                                      TZTCRTE_LEVL as Nivel,
                                                      TZTCRTE_CAMP as Campus,
                                                      TZTCRTE_CAMPO11  as Fecha_Pago,
                                                      TZTCRTE_CAMPO17 as otros,
                                                      sum (TZTCRTE_CAMPO15) as Monto_otros,
                                                      TZTCRTE_CAMPO18 as Categoria,
                                                      TZTCRTE_CAMPO10 as Secuencia,
                                                      TZTCRTE_CAMPO26 programa,
                                                      TZTCRTE_CAMPO27 colonia,
                                                      TZTCRTE_CAMPO56 bloque,
                                                      TZTCRTE_CAMPO58 balance,
                                                      TZTCRTE_REG_FISCAL reg_fiscal,
                                                      TZTCRTE_CFDI cfdi
                                            from TZTCRNT
                                            where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                            and TZTCRTE_CAMPO18 not in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL', 'VTA', 'TUI')
                                            group by
                                                      TZTCRTE_PIDM,
                                                      TZTCRTE_LEVL,
                                                      TZTCRTE_CAMP,
                                                      TZTCRTE_CAMPO11,
                                                      TZTCRTE_CAMPO17,
                                                      TZTCRTE_CAMPO18,
                                                      TZTCRTE_CAMPO10,
                                                      TZTCRTE_CAMPO26,
                                                      TZTCRTE_CAMPO27,
                                                      TZTCRTE_CAMPO56,
                                                      TZTCRTE_CAMPO58,
                                                      TZTCRTE_REG_FISCAL,
                                                      TZTCRTE_CFDI
                                            )
                                            select distinct
                                                      TZTCRTE_pidm as pidm,
                                                      TZTCRTE_CAMPO1 as Nombre,
                                                      TZTCRTE_CAMPO2 as RFC,
                                                      TZTCRTE_CAMPO3 as Dom_Fiscal,
                                                      TZTCRTE_CAMPO4 as Ciudad,
                                                      TZTCRTE_CAMPO5 as CP,
                                                      TZTCRTE_CAMPO6 as Pais,
                                                      TZTCRTE_CAMPO7 as Tipo_Deposito,
                                                      TZTCRTE_CAMPO8 as Descripcion,
                                                      TZTCRTE_CAMPO9 as Monto,
                                                      TZTCRTE_LEVL as Nivel,
                                                      TZTCRTE_CAMP as Campus,
                                                      TZTCRTE_ID as Matricula,
                                                      TZTCRTE_CAMPO10  as Transaccion,
                                                      TZTCRTE_CAMPO11  as Fecha_Pago,
                                                      TZTCRTE_CAMPO12 as REFERENCIA,
                                                      TZTCRTE_CAMPO13 as Referencia_Tipo,
                                                      TZTCRTE_CAMPO14  as EMAIL,
                                                      e.Colegiatura,
                                                      e.Monto_colegiatura,
                                                      b.intereses,
                                                      b.Monto_intereses,
                                                      c.accesorios,
                                                      c.Monto_accesorios,
                                                      d.otros,
                                                      d.monto_otros,
                                                      TZTCRTE_CAMPO20 as Curp,
                                                      TZTCRTE_CAMPO21 as Grado,
                                                      TZTCRTE_CAMPO22 as Razon_social,
                                                      TZTCRTE_CAMPO26 programa,
                                                      TZTCRTE_CAMPO27 colonia,
                                                      TZTCRTE_CAMPO58 balance,
                                                      TZTCRTE_CAMPO56 bloque,
                                                      TZTCRTE_REG_FISCAL reg_fiscal,
                                                      TZTCRTE_CFDI cfdi
                                            from TZTCRNT, intereses b, accesorios c, otros d, colegiatura e
                                            where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                            and TZTCRTE_CAMPO18 in ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL','VTA')
                                            and TZTCRTE_PIDM = e.pidm (+)
                                            and TZTCRTE_LEVL = e.nivel (+)
                                            and TZTCRTE_CAMP = e.campus (+)
                                            and TZTCRTE_CAMPO11 = e.Fecha_Pago (+)
                                            And TZTCRTE_CAMPO10 = e.secuencia (+)
                                            and TZTCRTE_PIDM = b.pidm (+)
                                            and TZTCRTE_LEVL = b.nivel (+)
                                            and TZTCRTE_CAMP = b.campus (+)
                                            and TZTCRTE_CAMPO11 = b.Fecha_Pago (+)
                                            And TZTCRTE_CAMPO10 = b.secuencia (+)
                                            and TZTCRTE_PIDM = c.pidm (+)
                                            and TZTCRTE_LEVL = c.nivel (+)
                                            and TZTCRTE_CAMP = c.campus (+)
                                            and TZTCRTE_CAMPO11 = c.Fecha_Pago (+)
                                            And TZTCRTE_CAMPO10 = c.secuencia (+)
                                            and TZTCRTE_PIDM = d.pidm (+)
                                            and TZTCRTE_LEVL = d.nivel (+)
                                            and TZTCRTE_CAMP = d.campus (+)
                                            and TZTCRTE_CAMPO11 = d.Fecha_Pago (+)
                                            And TZTCRTE_CAMPO10 = d.secuencia (+)
                                            and TZTCRTE_PIDM = f.SPRIDEN_PIDM
                                            and TZTCRTE_CAMPO10 = f.TBRACCD_TRAN_NUMBER
                                            group by TZTCRTE_pidm,
                                                      TZTCRTE_CAMPO1,
                                                      TZTCRTE_CAMPO2,
                                                      TZTCRTE_CAMPO3,
                                                      TZTCRTE_CAMPO4,
                                                      TZTCRTE_CAMPO5,
                                                      TZTCRTE_CAMPO6,
                                                      TZTCRTE_CAMPO7,
                                                      TZTCRTE_CAMPO8,
                                                      TZTCRTE_CAMPO9,
                                                      TZTCRTE_LEVL,
                                                      TZTCRTE_CAMP,
                                                      TZTCRTE_ID,
                                                      TZTCRTE_CAMPO10,
                                                      TZTCRTE_CAMPO11,
                                                      TZTCRTE_CAMPO12,
                                                      TZTCRTE_CAMPO13,
                                                      TZTCRTE_CAMPO14,
                                                      e.Colegiatura,
                                                      e.Monto_colegiatura,
                                                      b.intereses,
                                                      b.Monto_intereses,
                                                      c.accesorios,
                                                      c.Monto_accesorios,
                                                      d.otros,
                                                      d.monto_otros,
                                                      TZTCRTE_CAMPO20,
                                                      TZTCRTE_CAMPO21,
                                                      TZTCRTE_CAMPO22,
                                                      TZTCRTE_CAMPO26,
                                                      TZTCRTE_CAMPO27,
                                                      TZTCRTE_CAMPO58,
                                                      TZTCRTE_CAMPO56,
                                                      TZTCRTE_REG_FISCAL,
                                                      TZTCRTE_CFDI
                                                     order by TZTCRTE_ID, TZTCRTE_CAMPO11, TZTCRTE_CAMPO10

                     )

                     loop
                        vl_consecutivo:=0;
                       BEGIN
                        SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                        INTO vl_consecutivo
                        FROM TZTCRNT
                        WHERE 1=1
                        AND TZTCRTE_PIDM = c.pidm
                        AND TZTCRTE_CAMPO10= c.Transaccion
                        And TZTCRTE_TIPO_REPORTE = 'Facturacion_dia';
                        EXCEPTION
                        WHEN OTHERS THEN
                        vl_consecutivo :=1;
                       END;


                      Insert into TZTCRNT values (c.pidm,--TZTCRTE_PIDM
                                                       c.matricula,--TZTCRTE_ID
                                                        c.campus,--TZTCRTE_CAMP
                                                        c.nivel,--TZTCRTE_LEVL
                                                        c.nombre,--TZTCRTE_CAMPO1
                                                        c.rfc,--TZTCRTE_CAMPO2
                                                        c.dom_fiscal,--TZTCRTE_CAMPO3
                                                        c.ciudad, --TZTCRTE_CAMPO4
                                                        c.cp, --TZTCRTE_CAMPO5
                                                        c.pais,--TZTCRTE_CAMPO6
                                                        c.tipo_deposito,--TZTCRTE_CAMPO7
                                                        c.descripcion,--TZTCRTE_CAMPO8
                                                        c.monto,--TZTCRTE_CAMPO9
                                                        c.transaccion,--TZTCRTE_CAMPO10
                                                        c.fecha_pago,--TZTCRTE_CAMPO11
                                                        c.referencia,--TZTCRTE_CAMPO12
                                                        c.referencia_tipo,--TZTCRTE_CAMPO13
                                                        c.email,--TZTCRTE_CAMPO14
                                                        c.colegiatura, --TZTCRTE_CAMPO15
                                                        c.monto_colegiatura, --TZTCRTE_CAMPO16
                                                        c.intereses,--TZTCRTE_CAMPO17
                                                        c.monto_intereses,--TZTCRTE_CAMPO18
                                                        c.accesorios,--TZTCRTE_CAMPO19
                                                        c.monto_accesorios,--TZTCRTE_CAMPO20
                                                        c.otros,--TZTCRTE_CAMPO21
                                                        c.monto_otros,--TZTCRTE_CAMPO22
                                                        c.CURP,--TZTCRTE_CAMPO23
                                                        c.Grado,--TZTCRTE_CAMPO24
                                                        c.Razon_social,--TZTCRTE_CAMPO25
                                                        c.programa,--TZTCRTE_CAMPO26
                                                        c.colonia, --TZTCRTE_CAMPO27,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        c.bloque,
                                                        vl_consecutivo, --TZTCRTE_CAMPO57
                                                        c.balance, --TZTCRTE_CAMPO58
                                                        USER||'- EMONTADI_FA', --TZTCRTE_CAMPO59,
                                                        TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                        'Facturacion_dia',--TZTCRTE_TIPO_REPORTE
                                                        c.Reg_fiscal,
                                                        c.cfdi
                                                        );
                        DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCRTE con "Facturacion_dia"'||c.pidm||' '||c.monto||' '||c.transaccion||' '||c.colegiatura);
                        End loop;


                   END;
                 COMMIT;



            BEGIN

               vl_levl:= null;

               --DBMS_OUTPUT.PUT_LINE('Entra pidm a TZTCRTE '||f.SPRIDEN_PIDM||'-'||f.TBRACCD_TRAN_NUMBER);


                BEGIN
                    select distinct TZTORDR_NIVEL
                                    into vl_levl
                    from tbraccd, tztordr
                    where tbraccd_pidm =  f.SPRIDEN_PIDM
                    And TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                    And tbraccd_pidm = TZTORDR_PIDM
                    And TBRACCD_RECEIPT_NUMBER = TZTORDR_CONTADOR;
                    EXCEPTION WHEN OTHERS THEN
                    --DBMS_OUTPUT.PUT_LINE(vl_levl||'-'||f.SPRIDEN_PIDM||'-'||f.TBRACCD_TRAN_NUMBER);
                 --   DBMS_OUTPUT.PUT_LINE(sqlerrm||f.SPRIDEN_PIDM||'|'||f.TBRACCD_TRAN_NUMBER);
                    --vl_levl :=
                            vl_levl := null;
                    END;


                --DBMS_OUTPUT.PUT_LINE(vl_levl||'-'||f.SPRIDEN_PIDM||'-'||f.TBRACCD_TRAN_NUMBER);

                     FOR conceptos in (SELECT PAGOS_FACT .*, ROW_NUMBER() OVER(PARTITION BY TRANSACCION ORDER BY TBRACCD_ACTIVITY_DATE) numero
                                        FROM (with cargo as (
                                                select
                                                c.TVRACCD_PIDM PIDM,
                                                c.TVRACCD_DETAIL_CODE cargo,
                                                c.TVRACCD_ACCD_TRAN_NUMBER transa,
                                                c.TVRACCD_DESC descripcion,
                                                to_char(nvl(c.TVRACCD_AMOUNT,0) - nvl(c.TVRACCD_balance,0),'fm9999999990.00') MONTO_CARGO,
                                                Monto_Iv Monto_IVAS
                                           from TVRACCD c, TBBDETC a, (select distinct to_char(nvl (i.TVRACCD_AMOUNT, 0) -nvl (i.TVRACCD_BALANCE, 0) ,'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                         from tvraccd i
                                                                                         where 1=1
                                                                                         and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                         ) monto_iva
                                           where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                and a.TBBDETC_TYPE_IND = 'C'
                                                and c.TVRACCD_DESC not like 'IVA%'
                                                and c.TVRACCD_DETAIL_CODE not like ('IVA%')
                                                and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
                                                   ) ,
                                          FISCAL AS (
                                            Select SPREMRG_PIDM, SPREMRG_PRIORITY, SPREMRG_LAST_NAME, SPREMRG_FIRST_NAME, SPREMRG_MI,
                                            SPREMRG_STREET_LINE1, SPREMRG_STREET_LINE2, SPREMRG_STREET_LINE3, SPREMRG_CITY, SPREMRG_STAT_CODE, SPREMRG_NATN_CODE,
                                            SPREMRG_ZIP, SPREMRG_PHONE_AREA, SPREMRG_PHONE_NUMBER, SPREMRG_PHONE_EXT, SPREMRG_RELT_CODE
                                            from SPREMRG s
                                        Where  s.SPREMRG_MI IS NOT NULL
                                        AND SPREMRG_RELT_CODE = 'I'
                                            AND to_number (s.SPREMRG_PRIORITY) = (SELECT MAX (to_number (s1.SPREMRG_PRIORITY))
                                                                                                           FROM SPREMRG s1
                                                                                                           WHERE s.SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                                                                           AND s.SPREMRG_RELT_CODE = s1.SPREMRG_RELT_CODE)
                                        AND length(s.SPREMRG_MI) <=13
                                        )
                                        SELECT DISTINCT
                                        TBRACCD_PIDM PIDM,
                                        SPRIDEN_ID MATRICULA,
                                        SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                        TBRACCD_TRAN_NUMBER TRANSACCION,
                                        to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                        to_char(nvl(TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                        --to_char(nvl((TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1))), TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                        case
                                         When GORADID_ADID_CODE = 'REFS'then
                                               to_char(nvl(TBRAPPL_AMOUNT, TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                               --to_char(nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                         When GORADID_ADID_CODE IN ('REFH', 'REFU') then
                                          to_char (nvl(TBRAPPL_AMOUNT, TBRACCD_AMOUNT), 'fm9999999990.00')
                                          --to_char (nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT), 'fm9999999990.00')
                                        End  SUBTOTAL,
                                        case
                                         When   GORADID_ADID_CODE = 'REFS' then
                                                 to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT) -    nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                         When GORADID_ADID_CODE IN ('REFH', 'REFU') then
                                                --to_char (TBRACCD_AMOUNT- (TBRACCD_AMOUNT /1.16),'fm9999999990.00')
                                             '0.00'
                                           End IVA,
                                        nvl (TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                        to_char(TBRACCD_ENTRY_DATE, 'dd/mm/rrrr') Fecha_pago,
                                        TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                        TBBDETC_DESC DESCRIPCION,
                                        nvl (cargo.cargo, substr(TBBDETC_DETAIL_CODE,1, 2)||(SELECT SUBSTR(TBBDETC_DETAIL_CODE,3,2)
                                                                                                                            FROM TBBDETC
                                                                                                                            WHERE 1=1
                                                                                                                            AND TBBDETC_TAXT_CODE = vl_levl
                                                                                                                            AND TBBDETC_DCAT_CODE IN ('COL', 'CCC')
                                                                                                                            AND TBBDETC_DESC like 'COLEGIATURA%'
                                                                                                                            AND TBBDETC_DESC not like  '%REFI'
                                                                                                                            AND TBBDETC_DESC not like '%NOTA'
                                                                                                                            AND TBBDETC_DESC not like  '%LIC'
                                                                                                                            AND TBBDETC_DETC_ACTIVE_IND = 'Y'
                                                                                                                            AND SUBSTR(TBBDETC_DETAIL_CODE,1,2)=substr(SPRIDEN_ID,1,2)
                                                                                                                             and rownum = 1
                                                                                                                            group by TBBDETC_DETAIL_CODE
                                                            )
                                        )clave_cargo,
                                        CASE WHEN cargo.descripcion LIKE '%CANC%'
                                        THEN 'PCOLEGIATURA'
                                        WHEN cargo.descripcion NOT LIKE '%CANC%'
                                        THEN
                                        nvl (cargo.descripcion, 'PCOLEGIATURA')
                                        END Descripcion_cargo,
                                        nvl(cargo.transa,0) transa,
                                       upper(NVL(SPREMRG_MI, 'XAXX010101000')) RFC,
                                        CASE
                                         when GORADID_ADID_CODE = 'REFH' then
                                         'BH'
                                         when GORADID_ADID_CODE = 'REFS' then
                                         'BS'
                                         when GORADID_ADID_CODE = 'REFU' then
                                         'UI'
                                         when GORADID_ADID_CODE IS NULL then
                                         'NI'
                                        end Serie,
                                        TBRACCD_ACTIVITY_DATE,
                                        CASE
                                        WHEN TBRACCD_DESC LIKE '%EFEC%'THEN '01'
                                        WHEN TBRACCD_DESC LIKE '%CHEQUE%'THEN '02'
                                        WHEN TBRACCD_DESC LIKE '%TRANS%'THEN '03'
                                        WHEN TBRACCD_DESC LIKE '%EMPRESARIALES%' THEN '03'
                                        WHEN TBRACCD_DESC LIKE '%RECLAS%'THEN '03'
                                        WHEN TBRACCD_DESC LIKE '%TDC%'THEN '04'
                                        WHEN TBRACCD_DESC LIKE '%CRED%'THEN '04' --'%TARJETA CREDITO%'
                                        WHEN TBRACCD_DESC LIKE '%DEB%'THEN '28' --'%TARJETA DEBITO%'
                                        WHEN TBRACCD_DESC LIKE '%ELECT%'THEN '28'
                                        WHEN TBRACCD_DESC LIKE '%POLIZA%'THEN '100'
                                        ELSE '99'
                                        END forma_pago,
                                        TBRACCD_RECEIPT_NUMBER,
                                        NVL((SELECT
                                             CASE
                                             WHEN TBBDETC_DCAT_CODE IN ('CAN', 'AAC')
                                             THEN 'COL'
                                             WHEN TBBDETC_DCAT_CODE NOT IN ('CAN', 'AAC')
                                             THEN TBBDETC_DCAT_CODE
                                             END
                                             FROM TBBDETC
                                             WHERE 1=1
                                             AND TBBDETC_DETAIL_CODE = cargo.cargo),'COL')cargo_code
                                        FROM TBRACCD
                                        join SPRIDEN ON SPRIDEN_PIDM = TBRACCD_PIDM and SPRIDEN_CHANGE_IND is null
                                        join TBBDETC ON  TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        join  TBRAPPL ON TBRAPPL_PIDM = TBRACCD_PIDM AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER AND TBRAPPL_REAPPL_IND IS NULL
                                        left join cargo on cargo.pidm = tbraccd_pidm and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                        left join fiscal s on s.SPREMRG_PIDM = tbraccd_pidm
                                        left join GORADID on GORADID_PIDM = TBRACCD_PIDM and GORADID_ADID_CODE LIKE 'REF%'
                                        left join tztordr on TZTORDR_PIDM = tbraccd_pidm  and  TZTORDR_CONTADOR = TBRACCD_RECEIPT_NUMBER
                                        join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                        And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                        WHERE TBBDETC_TYPE_IND = 'P'
                                       -- AND TBBDETC_DCAT_CODE = 'CSH'
                                        AND TBRACCD_AMOUNT >= 1
                                        AND TBRACCD_TRAN_NUMBER  NOT IN (SELECT TZTCONC_TRAN_NUMBER  -- 02/12/2019
                                                                  FROM TZTCONT
                                                                  WHERE TBRACCD_PIDM = TZTCONC_PIDM)
                                        AND TRUNC (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE --'02/12/2019' -- --'16/08/2019'
                                        AND TBRACCD_PIDM = f.SPRIDEN_PIDM --38543
                                        AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER --60
                                        --AND TBRACCD_DESC LIKE '%DEBITO%'
                                        )PAGOS_FACT
                                         WHERE 1=1
                                UNION
                                SELECT
                                             TZTCRTE_PIDM PIDM,
                                             TZTCRTE_ID MATRICULA,
                                             SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                             TBRACCD_TRAN_NUMBER TRANSACCION,
                                             to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                             to_char(TBRACCD_AMOUNT,'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                              case
                                             When GORADID_ADID_CODE = 'REFS'then
                                                   to_char(TBRACCD_AMOUNT / 1.16,'fm9999999990.00')
                                                   --to_char(nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                             When GORADID_ADID_CODE IN ('REFH','REFU') then
                                              to_char (TBRACCD_AMOUNT, 'fm9999999990.00')
                                              --to_char (nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT), 'fm9999999990.00')
                                            End  SUBTOTAL,
                                            case
                                             When   GORADID_ADID_CODE ='REFS' then
                                                     to_char(TBRACCD_AMOUNT - TBRACCD_AMOUNT / 1.16,'fm9999999990.00')
                                             When GORADID_ADID_CODE IN ('REFH','REFU')  then
                                                    --to_char (TBRACCD_AMOUNT- (TBRACCD_AMOUNT /1.16),'fm9999999990.00')
                                                 '0.00'
                                               End IVA,
                                            Null CARGO_CUBIERTO,
                                            to_char(TBRACCD_ENTRY_DATE, 'dd/mm/rrrr') Fecha_pago,
                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                            TBBDETC_DESC DESCRIPCION,
                                            substr(TBBDETC_DETAIL_CODE,1, 2)||(SELECT SUBSTR(TBBDETC_DETAIL_CODE,3,2)
                                                                                                    FROM TBBDETC
                                                                                                    WHERE 1=1
                                                                                                    AND TBBDETC_TAXT_CODE = vl_levl --TZTORDR_NIVEL
                                                                                                    AND TBBDETC_DCAT_CODE IN ('COL', 'CCC')
                                                                                                    AND TBBDETC_DESC like 'COLEGIATURA%'
                                                                                                    AND TBBDETC_DESC not like  '%REFI'
                                                                                                    AND TBBDETC_DESC not like '%NOTA'
                                                                                                    AND TBBDETC_DESC not like  '%LIC'
                                                                                                    AND TBBDETC_DETC_ACTIVE_IND = 'Y'
                                                                                                    AND SUBSTR(TBBDETC_DETAIL_CODE,1,2)=substr(SPRIDEN_ID,1,2)
                                                                                                     and rownum = 1
                                                                                                    group by TBBDETC_DETAIL_CODE
                                                                                                    )clave_cargo,
                                            'PCOLEGIATURA' Descripcion_cargo,
                                            TVRACCD_ACCD_TRAN_NUMBER transa,
                                             --0 transa,
                                             'XAXX010101000' RFC,
                                            CASE
                                             when GORADID_ADID_CODE = 'REFH' then
                                             'BH'
                                             when GORADID_ADID_CODE = 'REFS' then
                                             'BS'
                                             when GORADID_ADID_CODE = 'REFU' then
                                             'UI'
                                             when GORADID_ADID_CODE IS NULL then
                                             'NI'
                                            end Serie,
                                            TBRACCD_ACTIVITY_DATE,
                                            CASE
                                            WHEN TBRACCD_DESC LIKE '%EFEC%'THEN '01'
                                            WHEN TBRACCD_DESC LIKE '%CHEQUE%'THEN '02'
                                            WHEN TBRACCD_DESC LIKE '%TRANS%'THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%EMPRESARIALES%' THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%RECLAS%'THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%TDC%'THEN '04'
                                            WHEN TBRACCD_DESC LIKE '%CRED%'THEN '04' --'%TARJETA CREDITO%'
                                            WHEN TBRACCD_DESC LIKE '%DEB%'THEN  '28' --'%TARJETA DEBITO%'
                                            WHEN TBRACCD_DESC LIKE '%ELECT%'THEN '28'
                                            WHEN TBRACCD_DESC LIKE '%POLIZA%'THEN '100'
                                            ELSE '99'
                                            END forma_pago,
                                            TBRACCD_RECEIPT_NUMBER,
                                            'COL' cargo_code,
                                            1 numero
                                             FROM TZTCRNT a, SPRIDEN, TBRACCD, GORADID, TBBDETC, TVRACCD, TZTNCD ----Agregar esta tabla Victor
                                             WHERE 1=1
                                             AND a.TZTCRTE_PIDM = SPRIDEN_PIDM
                                             AND a.TZTCRTE_PIDM = TBRACCD_PIDM
                                             AND a.TZTCRTE_CAMPO10  = TBRACCD_TRAN_NUMBER
                                             AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                             AND SPRIDEN_CHANGE_IND IS NULL
                                             AND GORADID_PIDM = TBRACCD_PIDM
                                             AND GORADID_ADID_CODE LIKE 'REF%'
                                             AND a.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                                             AND TBBDETC_TYPE_IND = 'P'
                                             --AND TBBDETC_DCAT_CODE = 'CSH'
                                             And tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                             And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                             AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTCONC_TRAN_NUMBER  -- 02/12/2019
                                                                      FROM TZTCONT
                                                                      WHERE TBRACCD_PIDM = TZTCONC_PIDM)
                                             AND TBRACCD_PIDM = TVRACCD_PIDM
                                             AND TBRACCD_TRAN_NUMBER = TVRACCD_TRAN_NUMBER
                                             AND TBRACCD_TRAN_NUMBER IN (SELECT TBRAPPL_PAY_TRAN_NUMBER
                                                                             FROM TBRAPPL
                                                                             WHERE 1=1
                                                                             AND TBRACCD_PIDM = TBRAPPL_PIDM
                                                                             AND TBRAPPL_REAPPL_IND = 'Y')
                                            AND a.TZTCRTE_CAMPO57 IN (SELECT MAX(TZTCRTE_CAMPO57)
                                                                       FROM TZTCRNT b
                                                                       WHERE 1=1
                                                                       AND a.TZTCRTE_PIDM =b.TZTCRTE_PIDM
                                                                       AND a.TZTCRTE_CAMP = b.TZTCRTE_CAMP
                                                                       AND a.TZTCRTE_CAMPO10 = b.TZTCRTE_CAMPO10
                                                                       AND a.TZTCRTE_TIPO_REPORTE = b.TZTCRTE_TIPO_REPORTE)
                                            AND TRUNC (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE --'02/12/2019' -- --'16/08/2019'
                                            AND TBRACCD_AMOUNT >= 1  --- Este valor debe de estar en todos las consultas
                                            AND TBRACCD_PIDM = f.SPRIDEN_PIDM  --38543
                                            AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER  --60
                                UNION
                                SELECT
                                             TZTCRTE_PIDM PIDM,
                                             TZTCRTE_ID MATRICULA,
                                             SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                             TBRACCD_TRAN_NUMBER TRANSACCION,
                                             to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                             to_char(TBRACCD_AMOUNT,'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                              case
                                             When GORADID_ADID_CODE = 'REFS'then
                                                   to_char(TBRACCD_AMOUNT / 1.16,'fm9999999990.00')
                                                   --to_char(nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                             When GORADID_ADID_CODE IN ('REFH','REFU') then
                                              to_char (TBRACCD_AMOUNT, 'fm9999999990.00')
                                              --to_char (nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT), 'fm9999999990.00')
                                            End  SUBTOTAL,
                                            case
                                             When   GORADID_ADID_CODE ='REFS' then
                                                     to_char(TBRACCD_AMOUNT - TBRACCD_AMOUNT / 1.16,'fm9999999990.00')
                                             When GORADID_ADID_CODE IN ('REFH','REFU')  then
                                                    --to_char (TBRACCD_AMOUNT- (TBRACCD_AMOUNT /1.16),'fm9999999990.00')
                                                 '0.00'
                                               End IVA,
                                            Null CARGO_CUBIERTO,
                                            to_char(TBRACCD_ENTRY_DATE, 'dd/mm/rrrr') Fecha_pago,
                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                            TBBDETC_DESC DESCRIPCION,
                                            substr(TBBDETC_DETAIL_CODE,1, 2)||(SELECT SUBSTR(TBBDETC_DETAIL_CODE,3,2)
                                                                                                    FROM TBBDETC
                                                                                                    WHERE 1=1
                                                                                                    AND TBBDETC_TAXT_CODE = vl_levl --TZTORDR_NIVEL
                                                                                                    AND TBBDETC_DCAT_CODE IN ('COL', 'CCC')
                                                                                                    AND TBBDETC_DESC like 'COLEGIATURA%'
                                                                                                    AND TBBDETC_DESC not like  '%REFI'
                                                                                                    AND TBBDETC_DESC not like '%NOTA'
                                                                                                    AND TBBDETC_DESC not like  '%LIC'
                                                                                                    AND TBBDETC_DETC_ACTIVE_IND = 'Y'
                                                                                                    AND SUBSTR(TBBDETC_DETAIL_CODE,1,2)=substr(SPRIDEN_ID,1,2)
                                                                                                     and rownum = 1
                                                                                                    group by TBBDETC_DETAIL_CODE
                                                                                                    )clave_cargo,
                                            'PCOLEGIATURA' Descripcion_cargo,
                                             0 transa,
                                             'XAXX010101000' RFC,
                                            CASE
                                             when GORADID_ADID_CODE = 'REFH' then
                                             'BH'
                                             when GORADID_ADID_CODE = 'REFS' then
                                             'BS'
                                             when GORADID_ADID_CODE = 'REFU' then
                                             'UI'
                                             when GORADID_ADID_CODE IS NULL then
                                             'NI'
                                            end Serie,
                                            TBRACCD_ACTIVITY_DATE,
                                            CASE
                                            WHEN TBRACCD_DESC LIKE '%EFEC%'THEN '01'
                                            WHEN TBRACCD_DESC LIKE '%CHEQUE%'THEN '02'
                                            WHEN TBRACCD_DESC LIKE '%TRANS%'THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%EMPRESARIALES%' THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%RECLAS%'THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%TDC%'THEN '04'
                                            WHEN TBRACCD_DESC LIKE '%CRED%'THEN '04' --'%TARJETA CREDITO%'
                                            WHEN TBRACCD_DESC LIKE '%DEB%'THEN  '28' --'%TARJETA DEBITO%'
                                            WHEN TBRACCD_DESC LIKE '%ELECT%'THEN '28'
                                            WHEN TBRACCD_DESC LIKE '%POLIZA%'THEN '100'
                                            ELSE '99'
                                            END forma_pago,
                                            TBRACCD_RECEIPT_NUMBER,
                                            'COL' cargo_code,
                                            1 numero
                                             FROM TZTCRNT a, SPRIDEN, TBRACCD, GORADID, TBBDETC, TZTNCD ----Agregar esta tabla Victor
                                             WHERE 1=1
                                             AND a.TZTCRTE_PIDM = SPRIDEN_PIDM
                                             AND a.TZTCRTE_PIDM = TBRACCD_PIDM
                                             AND a.TZTCRTE_CAMPO10  = TBRACCD_TRAN_NUMBER
                                             AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                             AND SPRIDEN_CHANGE_IND IS NULL
                                             AND GORADID_PIDM = TBRACCD_PIDM
                                             AND GORADID_ADID_CODE LIKE 'REF%'
                                             AND a.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                                             AND TBBDETC_TYPE_IND = 'P'
                                            -- AND TBBDETC_DCAT_CODE = 'CSH'
                                             And tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                             And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                             AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTCONC_TRAN_NUMBER  -- 02/12/2019
                                                                      FROM TZTCONT
                                                                      WHERE TBRACCD_PIDM = TZTCONC_PIDM)
                                             AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TBRAPPL_PAY_TRAN_NUMBER
                                                                             FROM TBRAPPL
                                                                             WHERE 1=1
                                                                             AND TBRACCD_PIDM = TBRAPPL_PIDM)
                                            AND a.TZTCRTE_CAMPO57 IN (SELECT MAX(TZTCRTE_CAMPO57)
                                                                       FROM TZTCRNT b
                                                                       WHERE 1=1
                                                                       AND a.TZTCRTE_PIDM =b.TZTCRTE_PIDM
                                                                       AND a.TZTCRTE_CAMP = b.TZTCRTE_CAMP
                                                                       AND a.TZTCRTE_CAMPO10 = b.TZTCRTE_CAMPO10
                                                                       AND a.TZTCRTE_TIPO_REPORTE = b.TZTCRTE_TIPO_REPORTE)
                                            AND TRUNC (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE --'02/12/2019' -- --'16/08/2019'
                                            AND TBRACCD_AMOUNT >= 1  --- Este valor debe de estar en todos las consultas
                                            AND TBRACCD_PIDM = f.SPRIDEN_PIDM --38543
                                            AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER --60

                              )LOOP

                                    vl_tipo_impuesto:= Null;
                                    vl_moneda:= Null;
                                    vl_subtotal_accs:=Null;
                                    vl_iva_accs:= Null;
                                    vl_codpago := null;


                                    --C DIGO PARA BLINDAR EL C DIGO DE DETALLE DEL CARGO---


                          --    DBMS_OUTPUT.PUT_LINE('conceptos.clave_cargo '||conceptos.clave_cargo);

                                 If length (conceptos.clave_cargo) != 4 then
                                       Begin

                                                select distinct TBBDETC_DETAIL_CODE
                                                Into vl_codpago
                                                from tztordr, tbraccd, tbbdetc, TZTNCD
                                                where 1= 1
                                                And TZTORDR_PIDM = tbraccd_pidm
                                                And TZTORDR_PIDM = conceptos.PIDM
--                                                And TBRACCD_TRAN_NUMBER = conceptos.TRANSACCION
                                                and  TZTORDR_CONTADOR = TBRACCD_RECEIPT_NUMBER
                                                And substr (TBBDETC_DETAIL_CODE, 1,2) = substr (TZTORDR_ID,1,2)
                                                And TBBDETC_DCAT_CODE ='COL'
                                                and TBBDETC_DETC_ACTIVE_IND ='Y'
                                               And TBBDETC_TAXT_CODE = TZTORDR_NIVEL
                                                And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                And TZTNCD_CONCEPTO ='Venta';

                                       Exception
                                        When Others then

                                         vl_consecutivo := 0;

                                         BEGIN
                                            SELECT NVL(MAX(TZTLOFA_SEQ_NO), 0) +1
                                            INTO vl_consecutivo
                                            FROM TZTLOFA
                                            WHERE 1=1
                                            AND TZTLOFA_PIDM = conceptos.PIDM
                                            AND TZTLOFA_TRAN_NUMBER= conceptos.TRANSACCION
                                            And TZTLOFA_CAMPO1 = 'TZTCONC';
                                            EXCEPTION
                                            WHEN OTHERS THEN
                                            vl_consecutivo :=1;
                                         END;

                                         BEGIN
                                            INSERT INTO TZTLOFA
                                            (TZTLOFA_PIDM,
                                                TZTLOFA_ID,
                                                TZTLOFA_TRAN_NUMBER,
                                                TZTLOFA_OBS,
                                                TZTLOFA_ACTIVITY_DATE,
                                                TZTLOFA_USER,
                                                TZTLOFA_CAMPO1,
                                                TZTLOFA_CAMPO2,
                                                TZTLOFA_CAMPO3,
                                                TZTLOFA_CAMPO4,
                                                TZTLOFA_CAMPO5,
                                                TZTLOFA_CAMPO6,
                                                TZTLOFA_SEQ_NO
                                             )
                                             VALUES(conceptos.PIDM,
                                                    conceptos.MATRICULA,
                                                    conceptos.TRANSACCION,
                                                    'FACTURA_REPROCESADA',
                                                    SYSDATE,
                                                    USER,
                                                    'TZTCONC',
                                                    Null,
                                                    Null,
                                                    'vl_codpago_no_generado',
                                                    Null,
                                                    Null,
                                                    vl_consecutivo
                                                    );
                                         END;

                                            vl_codpago := conceptos.clave_cargo;

                                       End;
                                 Elsif length (conceptos.clave_cargo) = 4 then
                                    vl_codpago := conceptos.clave_cargo;
                                 End if;


                                -- DBMS_OUTPUT.PUT_LINE('vl_codpago '||vl_codpago);
                                 --------------------FIN-------------------


                                    BEGIN
                                       SELECT TVRDCTX_TXPR_CODE
                                       INTO vl_tipo_impuesto
                                       from TVRDCTX
                                       WHERE 1=1
                                       AND TVRDCTX_DETC_CODE = vl_codpago;-- conceptos.clave_cargo ;
                                       EXCEPTION WHEN OTHERS THEN
                                       NULL;
                                    END;



                                    BEGIN

                                        SELECT TBRACCD_CURR_CODE
                                        INTO vl_moneda
                                        FROM
                                        TBRACCD
                                        WHERE 1=1
                                        AND TBRACCD_PIDM = conceptos.PIDM
                                        AND TBRACCD_TRAN_NUMBER = conceptos.TRANSACCION;

                                        EXCEPTION WHEN OTHERS THEN

                                        vl_consecutivo := 0;

                                         BEGIN
                                            SELECT NVL(MAX(TZTLOFA_SEQ_NO), 0) +1
                                            INTO vl_consecutivo
                                            FROM TZTLOFA
                                            WHERE 1=1
                                            AND TZTLOFA_PIDM = conceptos.PIDM
                                            AND TZTLOFA_TRAN_NUMBER= conceptos.TRANSACCION
                                            And TZTLOFA_CAMPO1 = 'TZTCONC';
                                            EXCEPTION
                                            WHEN OTHERS THEN
                                            vl_consecutivo :=1;
                                         END;

                                            BEGIN
                                            INSERT INTO TZTLOFA
                                            (TZTLOFA_PIDM,
                                                TZTLOFA_ID,
                                                TZTLOFA_TRAN_NUMBER,
                                                TZTLOFA_OBS,
                                                TZTLOFA_ACTIVITY_DATE,
                                                TZTLOFA_USER,
                                                TZTLOFA_CAMPO1,
                                                TZTLOFA_CAMPO2,
                                                TZTLOFA_CAMPO3,
                                                TZTLOFA_CAMPO4,
                                                TZTLOFA_CAMPO5,
                                                TZTLOFA_CAMPO6,
                                                TZTLOFA_SEQ_NO
                                             )
                                             VALUES(conceptos.PIDM,
                                                    conceptos.MATRICULA,
                                                    conceptos.TRANSACCION,
                                                    'ERROR EN LA MONEDA',
                                                    SYSDATE,
                                                    USER,
                                                    'TZTCONC',
                                                    Null,
                                                    Null,
                                                    Null,
                                                    Null,
                                                    Null,
                                                    vl_consecutivo
                                                    );
                                            END;
                                        COMMIT;
                                    END;


                                    BEGIN
                                       select TVRDCTX_TXPR_CODE
                                       into vl_tipo_iva
                                       from TVRDCTX
                                       where TVRDCTX_DETC_CODE =vl_codpago;
                                        EXCEPTION
                                            WHEN OTHERS THEN
                                            vl_tipo_iva :=1;
                                    END;

                               --     DBMS_OUTPUT.PUT_LINE('tipoiva '|| vl_codpago ||'Concepto '||vl_codpago||' Tipo IVA '||vl_tipo_impuesto||'**'||vl_subtotal_accs);




                                    IF vl_tipo_impuesto ='IVA' AND conceptos.Serie IN ('BH', 'UI')THEN
                                        vl_subtotal_accs:= TO_CHAR((conceptos.SUBTOTAL /1.16), 'fm9999999990.00');
                                        vl_iva_accs:= (conceptos.MONTO_PAGADO_CARGO - (conceptos.SUBTOTAL /1.16));
                                  ELSif vl_tipo_impuesto ='IVP' or vl_tipo_impuesto ='IVE' then
                                        vl_subtotal_accs:=conceptos.MONTO_PAGADO_CARGO;
                                        vl_iva_accs:= 0;
                                    else
                                        vl_subtotal_accs:=conceptos.SUBTOTAL;
                                        vl_iva_accs:= conceptos.IVA;

                                    END IF;



                                Begin
                                    Insert into TZTCONT values (conceptos.PIDM, --TZTCONC_PIDM
                                                              NULL, --TZTCONC_FOLIO
                                                              vl_codpago, --TZTCONC_CONCEPTO_CODE
                                                              conceptos.Descripcion_cargo, --TZTCONC_CONCEPTO
                                                              conceptos.MONTO_PAGADO_CARGO, --TZTCONC_MONTO
                                                              vl_subtotal_accs,--conceptos.SUBTOTAL,--TZTCONC_SUBTOTAL
                                                              vl_iva_accs, --conceptos.IVA, --TZTCONC_IVA
                                                              conceptos.TRANSACCION, --TZTCONC_TRAN_NUMBER
                                                              conceptos.Fecha_pago, --TZTCONC_FECHA_CONC
                                                              conceptos.Serie, --TZTCONC_SERIE
                                                              conceptos.RFC, --TZTCONC_RFC
                                                              'FA',--TZTCONC_TIPO_DOCTO
                                                              conceptos.numero, --TZTCONC_SEQ_PAGO
                                                              conceptos.forma_pago, --TZTCONC_FORMA_PAGO
                                                              conceptos.transa,--TZTCONC_TRAN_PAGADA
                                                              TRUNC(SYSDATE), --TZTCONC_ACTIVITY_DATE
                                                              USER||'- EMONTADI_FA', --TZTCON_USER
                                                              conceptos.cargo_code,
                                                              vl_moneda --TZTCONC_MONEDA
                                                                             );
                                EXCEPTION
                                    When Others then
                                    VL_ERROR := 'Error al Insertar' ||sqlerrm;
                             --       dbms_output.put_line('Error '||conceptos.PIDM||'+'||VL_ERROR );
                                END;

                                --DBMS_OUTPUT.PUT_LINE('inSERT  EN TZTCONC'||f.SPRIDEN_PIDM||'|'||f.TBRACCD_TRAN_NUMBER);
                                --DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCONC con "Facturacion_dia"'||conceptos.pidm||' '||conceptos.MONTO_PAGADO_CARGO||' '||conceptos.TRANSACCION);
                              END LOOP;
                             COMMIT;
            END;

          END; --CIERRA EL BEGIN DEL CURSOSR DE LOS DATOS A BUSCAR

               --DBMS_OUTPUT.PUT_LINE(vl_levl||'-'||f.SPRIDEN_PIDM||'-'||f.TBRACCD_TRAN_NUMBER);
       END LOOP;

      COMMIT;
  END SP_CARGA_FA; --CIERRA EL BEGIN GENERAL

PROCEDURE SP_CARGA_FA_PI
    IS

--DECLARE
    VL_ERROR VARCHAR2(200);
    vl_pidm number;
    vl_date varchar2(100);
    vl_rvoe varchar2 (50);
    vl_consecutivo number:=0;
    vl_bandera number :=0;
    vl_appl_no varchar2(2);
    vl_program varchar2(20);
    vl_tipo_impuesto varchar2(20);
    vl_subtotal_accs number;
    vl_iva_accs number;
    vl_moneda varchar2(6);
    vl_balance number;
    vl_distribuye_balance number;
    vl_new_balance number;
    vl_valida_col number;
    vl_levl varchar2(4);
    vl_codpago varchar2(4):= null;
         -- BEGIN DEL CURSOR DE LOS DATOS A BUSCAR
         --MODIFICAR EL RANGO DE FECHA DEL TRUNC(TBRACCD_ENTRY_DATE)--



  BEGIN

      FOR f in(

        SELECT SPRIDEN_PIDM, SPRIDEN_ID, SPRIDEN_FIRST_NAME, TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_AMOUNT, TBRACCD_STSP_KEY_SEQUENCE, to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                TRUNC(TBRACCD_ENTRY_DATE) TRUNC_DATE, TBRACCD_ENTRY_DATE
                FROM TBRACCD, SPRIDEN, SPREMRG s, TBBDETC, TZTNCD ----Agregar esta tabla Victor
                WHERE 1=1
                AND substr (spriden_id,1,2) NOT IN (SELECT ZSTPARA_PARAM_ID
                                                    FROM ZSTPARA
                                                    WHERE 1=1
                                                    AND ZSTPARA_MAPA_ID = 'FM_OPM')
                AND TBRACCD_PIDM= SPRIDEN_PIDM
                AND SPRIDEN_CHANGE_IND IS NULL
                AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                AND TBBDETC_TYPE_IND = 'P'
                 -- AND TBBDETC_DCAT_CODE = 'CSH' -- apagar esta linea
                And tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                           FROM TZTFCTU--
                                           WHERE 1=1
                                           AND TBRACCD_PIDM = TZTFACT_PIDM)
               AND TBRACCD_PIDM = s.SPREMRG_PIDM(+)
               AND TRUNC(TBRACCD_ENTRY_DATE) BETWEEN TRUNC(SYSDATE,'MM') AND TRUNC(SYSDATE)
               AND TBRACCD_AMOUNT >= 1
               AND SUBSTR(SPRIDEN_ID, 3,2) = '99'
               group by SPRIDEN_PIDM, SPRIDEN_ID, SPRIDEN_FIRST_NAME, TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_AMOUNT, TBRACCD_STSP_KEY_SEQUENCE,
               TBRACCD_BALANCE, TBRACCD_ENTRY_DATE,TZTNCD_CONCEPTO
               order by TBRACCD_ENTRY_DATE DESC

       )
       LOOP -- PRIMER LOOP--

          BEGIN

                    for a in (SELECT TZTCRTE_PIDM pidm, TZTCRTE_CAMPO10 tran_number, TZTCRTE_TIPO_REPORTE tipo_reporte
                               FROM TZTCRNT
                               WHERE TZTCRTE_TIPO_REPORTE in ( 'Pago_Facturacion_dia', 'Facturacion_dia')
                               AND TZTCRTE_PIDM = f.SPRIDEN_PIDM
                               AND TZTCRTE_CAMPO10  = f.TBRACCD_TRAN_NUMBER
                               )
                    LOOP
                           BEGIN
                            delete TZTCRNT
                            where 1=1
                            and TZTCRTE_PIDM = a.pidm
                            and TZTCRTE_CAMPO10  = a.tran_number
                            and TZTCRTE_TIPO_REPORTE = a.tipo_reporte;
                           END;

                           BEGIN
                            delete TZTCONT
                            WHERE 1=1
                            AND TZTCONC_PIDM = a.pidm
                            AND TZTCONC_TRAN_NUMBER = a.tran_number
                            And (TZTCONC_PIDM, TZTCONC_TRAN_NUMBER) not in (select TZTFACT_PIDM,  TZTFACT_TRAN_NUMBER
                                                                            FROM TZTFCTU);
                           END;
                    end LOOP;
            Exception
            When others then
            null;
          End;
          Commit;

          Begin

                   BEGIN

                    delete TZTCONT
                    WHERE 1=1
                    AND TZTCONC_PIDM = f.spriden_pidm
                    AND TZTCONC_TRAN_NUMBER = f.tbraccd_tran_number
                     And (TZTCONC_PIDM, TZTCONC_TRAN_NUMBER) not in (select TZTFACT_PIDM,  TZTFACT_TRAN_NUMBER
                                                                     FROM TZTFCTU);
                   Exception
                    When Others then
                        null;
                   END;


          End;
          commit;


          BEGIN

                  BEGIN


                            SELECT a.SARADAP_APPL_NO, a.SARADAP_PROGRAM_1
                               INTO vl_appl_no, vl_program
                            FROM SARADAP a
                            WHERE 1=1
                            AND a.SARADAP_PIDM = f.SPRIDEN_PIDM  --248484
                            AND a.SARADAP_APPL_NO in  (SELECT MAX(b.SARADAP_APPL_NO)
                                                                     FROM
                                                                     SARADAP b
                                                                     WHERE 1=1
                                                                     AND b.SARADAP_PIDM = a.SARADAP_PIDM
                                                                     AND b.SARADAP_PROGRAM_1 = a.SARADAP_PROGRAM_1
                                                                     );


                    EXCEPTION WHEN OTHERS THEN
                        Begin

                            SELECT a.SARADAP_APPL_NO, a.SARADAP_PROGRAM_1
                               INTO vl_appl_no, vl_program
                            FROM SARADAP a
                            WHERE 1=1
                            AND a.SARADAP_PIDM = f.SPRIDEN_PIDM  --248484
                            AND a.SARADAP_APPL_NO in  (SELECT MAX(b.SARADAP_APPL_NO)
                                                                     FROM
                                                                     SARADAP b
                                                                     WHERE 1=1
                                                                     AND b.SARADAP_PIDM = a.SARADAP_PIDM
                                                                    -- AND b.SARADAP_PROGRAM_1 = a.SARADAP_PROGRAM_1
                                                                     );

                        exception
                            When Others then
                                 vl_appl_no :=0;
                                 vl_program := null;

                        End;


                    END;



         --           DBMS_OUTPUT.PUT_LINE('Llego al for ');

                        BEGIN

                               for a IN (
                               with colegiatura as (Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbbdetc_desc desc_cargo,
                                        TBBDETC_DCAT_CODE Categ_Col
                                        from tbraccd a, tbbdetc b
                                        where 1=1
                                        and a.tbraccd_detail_code = b.tbbdetc_detail_code
                                        and  a.tbraccd_pidm = f.spriden_pidm
                                        ),
                                curp as (select  GORADID_PIDM PIDM,
                                        GORADID_ADDITIONAL_ID CURP
                                        from GORADID
                                        where GORADID_ADID_CODE = 'CURP'
                                        AND LENGTH(GORADID_ADDITIONAL_ID)= 18
                                        GROUP BY GORADID_PIDM, GORADID_ADDITIONAL_ID)
                                       SELECT DISTINCT
                                        tbraccd_pidm pidm ,
                                        spriden_id as Matricula,
                                        null as Nombre,
                                        nvl(SARADAP_CAMP_CODE,(select SZVCAMP_CAMP_CODE
                                                               from spriden, szvcamp
                                                               where 1=1
                                                               and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                               and spriden_id = f.spriden_id
                                                               And spriden_change_ind is null
                                                               )
                                        )as Campus,
                                        nvl(SARADAP_LEVL_CODE,(select  x.Casse nivel
                                                                    from (select distinct SZVCAMP_CAMP_CODE campus, spriden_id Matricula,
                                                                            case
                                                                                When SZVCAMP_CAMP_CODE ='UTL' then 'LI'
                                                                                When SZVCAMP_CAMP_CODE ='UTS' then 'MS'
                                                                                When SZVCAMP_CAMP_CODE ='UMM' then 'LI'
                                                                                When SZVCAMP_CAMP_CODE ='COL' then 'LI'
                                                                                When SZVCAMP_CAMP_CODE ='UIN' then 'MA'
                                                                                When SZVCAMP_CAMP_CODE ='CHI' then 'LI'
                                                                                When SZVCAMP_CAMP_CODE ='COE' then 'LI'
                                                                                When SZVCAMP_CAMP_CODE ='PER' then 'LI'
                                                                                When SZVCAMP_CAMP_CODE ='ECU' then 'LI'
                                                                                When SZVCAMP_CAMP_CODE ='UVE' then 'LI'
                                                                                When SZVCAMP_CAMP_CODE ='EBE' then 'MS'
                                                                                When SZVCAMP_CAMP_CODE ='UNA' then 'MA'
                                                                                When SZVCAMP_CAMP_CODE ='UNI' then 'LI'
                                                                             End Casse
                                                                    from spriden, szvcamp
                                                                    where 1=1
                                                                    and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                    And spriden_change_ind is null
                                                                 )x
                                                                 where 1=1
                                                                 and x.Matricula = f.spriden_id )
                                          )as Nivel,
                                          CASE WHEN
                                          nvl(SARADAP_CAMP_CODE,(select SZVCAMP_CAMP_CODE
                                                                 from spriden, szvcamp
                                                                 where 1=1
                                                                 and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                 and spriden_id = f.spriden_id
                                                                 and spriden_change_ind is null))
                                            IN (SELECT ZSTPARA_PARAM_VALOR
                                                FROM ZSTPARA
                                                WHERE 1=1
                                                AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                                          THEN
                                           'XEXX010101000'
                                          WHEN
                                            nvl(SARADAP_CAMP_CODE,(select SZVCAMP_CAMP_CODE
                                                                   from spriden, szvcamp
                                                                   where 1=1
                                                                   and SZVCAMP_CAMP_ALT_CODE = substr (spriden_id,1,2)
                                                                   and spriden_id = f.spriden_id
                                                                   And spriden_change_ind is null))
                                             NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                     FROM ZSTPARA
                                                     WHERE 1=1
                                                     AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                                          THEN
                                           'XAXX010101000'
                                          END RFC,
                                        null as Dom_Fiscal,
                                        null as Ciudad,
                                        null colonia,
                                        null as CP,
                                        null as Pais,
                                          tbraccd_detail_code as Tipo_Deposito,
                                          tbraccd_desc as Descripcion,
                                          to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto,
                                          TBRACCD_TRAN_NUMBER as Transaccion,
                                          TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS') as Fecha_Pago,
                                          GORADID_ADDITIONAL_ID as REFERENCIA,
                                          GORADID_ADID_CODE as Referencia_Tipo,
                                          GOREMAL_EMAIL_ADDRESS as EMAIL,
                                          to_char(TBRACCD_AMOUNT,'fm9999999990.00') as Monto_pagado,
                                          to_char(nvl(TBRACCD_BALANCE,'0'),'fm9999999990.00') as balance,
                                          TBRAPPL_AMOUNT accesorio,
                                          TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                                          CASE WHEN colegiatura.Categ_Col IN ('CAN', 'ACC')
                                          THEN 'PCOLEGIATURA'
                                          WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                          THEN colegiatura.desc_cargo
                                          END descripcion_pago,
                                          CASE WHEN colegiatura.Categ_Col IN ('CAN', 'AAC')
                                          THEN 'COL'
                                          WHEN colegiatura.Categ_Col NOT IN ('CAN', 'AAC')
                                          THEN NVL(colegiatura.Categ_Col,'COL')
                                          END Categ_Col,
                                          null Prioridad,
                                          curp.CURP,
                                          SARADAP_DEGC_CODE_1 Grado,
                                         null Razon_social,
                                         SARADAP_PROGRAM_1 programa,
                                         'Bloque_PI' bloque
                                        from SPRIDEN
                                        join TBRACCD on SPRIDEN_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE  AND TBRACCD_PIDM = f.spriden_pidm AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                        join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                        left join SARADAP on SPRIDEN_PIDM = SARADAP_PIDM --AND SARADAP_APPL_NO = :vl_appl_no  AND SARADAP_PROGRAM_1 = :vl_program
                                        left join GORADID on SPRIDEN_PIDM = GORADID_PIDM and GORADID_ADID_CODE IN ('REFH','REFS','REFU')
                                        left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                                        left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                        left join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                        left join curp on SPRIDEN_PIDM = curp.PIDM
                                        join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                        And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                        where 1= 1
                                        And spriden_change_ind is null
                                        and TBBDETC_TYPE_IND = 'P'
                                        --and TBBDETC_DCAT_CODE = 'CSH'
                                        And spriden_pidm not in (select SPREMRG_pidm from SPREMRG)
                                        And TBRACCD_AMOUNT >= 1
                                        And (TBRACCD_PIDM, TBRACCD_TRAN_NUMBER) NOT IN (SELECT TZTCRTE_PIDM, TZTCRTE_CAMPO10
                                                                                        FROM TZTCRNT
                                                                                        WHERE 1=1
                                                                                        AND TZTCRTE_TIPO_REPORTE = 'Facturacion_dia')
                                        GROUP BY tbraccd_pidm, spriden_id,
                                        saradap_camp_code, SARADAP_LEVL_CODE,
                                        tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                        GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                        curp.CURP, SARADAP_DEGC_CODE_1,SARADAP_PROGRAM_1,TBRACCD_BALANCE, TZTNCD_CONCEPTO




                                     ) loop

                                           vl_consecutivo := 0;


                                           BEGIN
                                            SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                                            INTO vl_consecutivo
                                            FROM TZTCRNT
                                            WHERE 1=1
                                            AND TZTCRTE_PIDM = f.spriden_pidm
                                            AND TZTCRTE_CAMPO10= f.TBRACCD_TRAN_NUMBER
                                            And TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia';
                                            EXCEPTION
                                            WHEN OTHERS THEN
                                            vl_consecutivo :=1;
                                      --      DBMS_OUTPUT.PUT_LINE('Error XX3 '||sqlerrm);
                                           END;



                                        begin
                                         Insert into TZTCRNT values (a.pidm, --TZTCRTE_PIDM
                                                                        a.matricula, --TZTCRTE_ID
                                                                        a.campus,--TZTCRTE_CAMP
                                                                        a.nivel,--TZTCRTE_LEVL
                                                                        a.nombre,--TZTCRTE_CAMPO1
                                                                        a.rfc,--TZTCRTE_CAMPO2
                                                                        a.dom_fiscal,--TZTCRTE_CAMPO3
                                                                        a.ciudad,--TZTCRTE_CAMPO4
                                                                        a.cp,--TZTCRTE_CAMPO5
                                                                        a.pais,--TZTCRTE_CAMPO6
                                                                        a.tipo_deposito,--TZTCRTE_CAMP07
                                                                        a.descripcion,--TZTCRTE_CAMPO8
                                                                        a.monto,--TZTCRTE_CAMPO9
                                                                        a.transaccion,--TZTCRTE_CAMP1O
                                                                        a.fecha_pago,--TZTCRTE_CAMPO11
                                                                        a.referencia,--TZTCRTE_CAMPO12
                                                                        a.referencia_tipo,--TZTCRTE_CAMPO13
                                                                        a.email,--TZTCRTE_CAMPO14
                                                                        a.accesorio, ---TZTCRTE_CAMPO15
                                                                        --c.monto_pagado,--TZTCRTE_CAMPO15
                                                                        a.secuencia_pago,--TZTCRTE_CAMPO16
                                                                        a.descripcion_pago,---TZTCRTE_CAMPO17
                                                                        a.Categ_Col,--TZTCRTE_CAMPO18
                                                                        a.Prioridad,--TZTCRTE_CAMPO19
                                                                        a.CURP,--TZTCRTE_CAMPO20
                                                                        a.Grado,--TZTCRTE_CAMPO21
                                                                        a.Razon_social,--TZTCRTE_CAMPO22
                                                                        null, --TZTCRTE_CAMPO23
                                                                        null, --TZTCRTE_CAMPO24
                                                                        null, --TZTCRTE_CAMPO25
                                                                        a.programa, --TZTCRTE_CAMPO26
                                                                        a.colonia, --TZTCRTE_CAMPO27
                                                                        null, --TZTCRTE_CAMPO28
                                                                        null, --TZTCRTE_CAMPO29
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        a.bloque, --TZTCRTE_CAMPO56
                                                                        vl_consecutivo,
                                                                        a.balance, --TZTCRTE_CAMPO58
                                                                        USER||'- EMONTADI_FA', --TZTCRTE_CAMPO59
                                                                        TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                                        'Pago_Facturacion_dia',--TZTCRTE_TIPO_REPORTE
                                                                        '',
                                                                        ''
                                                                        );
                                        --DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCRTE '||c.pidm||' '||c.monto||' '||c.transaccion||' '||c.Categ_Col);
                                      --  DBMS_OUTPUT.PUT_LINE(vl_bandera||'-'||a.RFC ||'-'||a.descripcion_pago||'-'||a.nombre||'-'||'Primero');
                                        Exception
                                            When Others then
                                            --      DBMS_OUTPUT.PUT_LINE('Error XX2 '||sqlerrm);
                                                  null;
                                        end;
                                    End Loop;
                                  COMMIT;
                        Exception
                            When Others then
                              --  DBMS_OUTPUT.PUT_LINE('Error XX1 '||sqlerrm);
                              null;

                        END;


                     BEGIN

                            BEGIN
                            SELECT TZTCRTE_CAMPO58
                            INTO vl_balance
                            FROM TZTCRNT
                            WHERE 1=1
                            AND TZTCRTE_PIDM = f.SPRIDEN_PIDM
                            AND TZTCRTE_CAMPO10 = f.TBRACCD_TRAN_NUMBER
                            AND TZTCRTE_TIPO_REPORTE ='Pago_Facturacion_dia'
                            GROUP BY TZTCRTE_CAMPO58;
                            EXCEPTION
                            WHEN OTHERS THEN
                            NULL;
                            END;

                            BEGIN
                            SELECT COUNT(TZTCRTE_CAMPO18)
                            INTO vl_valida_col
                            FROM TZTCRNT
                            WHERE 1=1
                            AND TZTCRTE_PIDM = f.SPRIDEN_PIDM
                            AND TZTCRTE_CAMPO10 = f.TBRACCD_TRAN_NUMBER
                            AND TZTCRTE_TIPO_REPORTE ='Pago_Facturacion_dia'
                            AND TZTCRTE_CAMPO18 ='COL';
                            EXCEPTION
                            WHEN OTHERS THEN
                            NULL;
                            END;

                         IF vl_balance like '-%' AND vl_valida_col = 0 THEN

                          vl_consecutivo := 0;


                           BEGIN
                            SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                            INTO vl_consecutivo
                            FROM TZTCRNT
                            WHERE 1=1
                            AND TZTCRTE_PIDM = f.SPRIDEN_PIDM
                            AND TZTCRTE_CAMPO10= f.TBRACCD_TRAN_NUMBER
                            And TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia';
                            EXCEPTION
                            WHEN OTHERS THEN
                            vl_consecutivo :=1;
                           END;

                            BEGIN
                            INSERT INTO TZTCRNT
                            SELECT
                            a.TZTCRTE_PIDM, a.TZTCRTE_ID, a.TZTCRTE_CAMP, a.TZTCRTE_LEVL, a.TZTCRTE_CAMPO1,
                                a.TZTCRTE_CAMPO2, a.TZTCRTE_CAMPO3, a.TZTCRTE_CAMPO4, a.TZTCRTE_CAMPO5, a.TZTCRTE_CAMPO6,
                                a.TZTCRTE_CAMPO7, a.TZTCRTE_CAMPO8, a.TZTCRTE_CAMPO9, a.TZTCRTE_CAMPO10, a.TZTCRTE_CAMPO11,
                                a.TZTCRTE_CAMPO12, a.TZTCRTE_CAMPO13, a.TZTCRTE_CAMPO14,a.TZTCRTE_CAMPO58 * -1,Null, 'COLEGIATURA '||a.TZTCRTE_CAMPO21,
                                'COL', Null, a.TZTCRTE_CAMPO20, a.TZTCRTE_CAMPO21, a.TZTCRTE_CAMPO22, Null, Null, Null,
                                a.TZTCRTE_CAMPO26, TZTCRTE_CAMPO27, Null, Null, Null,Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null,
                                Null, Null, Null, Null ,Null, Null, Null, Null, Null, Null, Null, Null, Null,a.TZTCRTE_CAMPO56, vl_consecutivo,
                                a.TZTCRTE_CAMPO58, user||' - BALANCE DIRECCIONADO A COL', TRUNC(SYSDATE),'Pago_Facturacion_dia','',''
                            FROM TZTCRNT a
                            WHERE 1= 1
                            AND a.TZTCRTE_PIDM = f.SPRIDEN_PIDM
                            AND TO_NUMBER(a.TZTCRTE_CAMPO10) = f.TBRACCD_TRAN_NUMBER
                            AND a.TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                            AND a.TZTCRTE_CAMP is not null
                            AND a.TZTCRTE_CAMPO57 = (SELECT MAX(TZTCRTE_CAMPO57)
                                                   FROM TZTCRNT b
                                                   WHERE 1=1
                                                   AND a.TZTCRTE_PIDM =b.TZTCRTE_PIDM
                                                   AND a.TZTCRTE_CAMP = b.TZTCRTE_CAMP
                                                   AND a.TZTCRTE_CAMPO10 = b.TZTCRTE_CAMPO10);
                            EXCEPTION WHEN OTHERS THEN
                            DBMS_OUTPUT.PUT_LINE('ERROR AQU  '||f.SPRIDEN_PIDM||'-'||f.TBRACCD_TRAN_NUMBER||'-'||vl_consecutivo||SQLERRM);
                           END;

                       ELSIF vl_balance like '-%' AND vl_valida_col > 0 THEN

                        --dbms_output.put_line(vl_balance||'-'||vl_valida_col);

                        vl_new_balance := (vl_balance)*-1;


                        BEGIN

                        UPDATE TZTCRNT a SET a.TZTCRTE_CAMPO15 = a.TZTCRTE_CAMPO15 + vl_new_balance, TZTCRTE_CAMPO59 = USER||'- CAMPO15 SUMADO CON BALANCE'
                        WHERE 1=1
                        AND a.TZTCRTE_PIDM = f.SPRIDEN_PIDM
                        AND a.TZTCRTE_CAMPO10 = f.TBRACCD_TRAN_NUMBER
                        AND a.TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                        AND a.TZTCRTE_CAMPO18 = 'COL'
                        AND a.TZTCRTE_CAMPO16 = (SELECT min(TZTCRTE_CAMPO16)
                                                    FROM TZTCRNT b
                                                    WHERE 1=1
                                                    AND b.TZTCRTE_PIDM = a.TZTCRTE_PIDM
                                                    AND b.TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                                                    AND b.TZTCRTE_CAMPO18 = a.TZTCRTE_CAMPO18);
                        END;


                       END IF;
                      COMMIT;

                     END;


               BEGIN

                     For c in (with intereses as (select distinct
                                            TZTCRTE_PIDM Pidm,
                                            TZTCRTE_LEVL as Nivel,
                                            TZTCRTE_CAMP as Campus,
                                            TZTCRTE_CAMPO11  as Fecha_Pago,
                                            TZTCRTE_CAMPO17 as Intereses,
                                            sum (TZTCRTE_CAMPO15) as Monto_intereses,
                                            TZTCRTE_CAMPO18 as Categoria,
                                            TZTCRTE_CAMPO10 as Secuencia,
                                            TZTCRTE_CAMPO26 programa,
                                            TZTCRTE_CAMPO27 colonia,
                                            TZTCRTE_CAMPO56 bloque,
                                            TZTCRTE_CAMPO58 balance
                                            from TZTCRNT
                                            where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                            and TZTCRTE_CAMPO18 = 'INT'
                                            group by
                                                      TZTCRTE_PIDM,
                                                      TZTCRTE_LEVL,
                                                      TZTCRTE_CAMP,
                                                      TZTCRTE_CAMPO11,
                                                      TZTCRTE_CAMPO17,
                                                      TZTCRTE_CAMPO18,
                                                      TZTCRTE_CAMPO10,
                                                      TZTCRTE_CAMPO26,
                                                      TZTCRTE_CAMPO27,
                                                      TZTCRTE_CAMPO56,
                                                      TZTCRTE_CAMPO58
                                            ),
                                            accesorios as (
                                            select distinct
                                                      TZTCRTE_PIDM Pidm,
                                                      TZTCRTE_LEVL as Nivel,
                                                      TZTCRTE_CAMP as Campus,
                                                      TZTCRTE_CAMPO11  as Fecha_Pago,
                                                      TZTCRTE_CAMPO17 as accesorios,
                                                      TO_CHAR(SUM(TO_NUMBER (TZTCRTE_CAMPO15)),'fm9999999990.00') as Monto_accesorios,
                                                      TZTCRTE_CAMPO18 as Categoria,
                                                      TZTCRTE_CAMPO10 as Secuencia,
                                                      TZTCRTE_CAMPO26 programa,
                                                      TZTCRTE_CAMPO27 colonia,
                                                      TZTCRTE_CAMPO56 bloque,
                                                      TZTCRTE_CAMPO58 balance
                                            FROM TZTCRNT
                                            where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                            and TZTCRTE_CAMPO18 in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                                            group by
                                                      TZTCRTE_PIDM,
                                                      TZTCRTE_LEVL,
                                                      TZTCRTE_CAMP,
                                                      TZTCRTE_CAMPO11,
                                                      TZTCRTE_CAMPO17,
                                                      TZTCRTE_CAMPO18,
                                                      TZTCRTE_CAMPO10,
                                                      TZTCRTE_CAMPO26,
                                                      TZTCRTE_CAMPO27,
                                                      TZTCRTE_CAMPO56,
                                                      TZTCRTE_CAMPO58
                                                      --TZTCRTE_CAMPO15
                                            ),
                                            colegiatura as (
                                            select distinct
                                                      TZTCRTE_PIDM Pidm,
                                                      TZTCRTE_LEVL as Nivel,
                                                      TZTCRTE_CAMP as Campus,
                                                      TZTCRTE_CAMPO11  as Fecha_Pago,
                                                      TZTCRTE_CAMPO17 as colegiatura,
                                                      TO_CHAR(SUM(TO_NUMBER(TZTCRTE_CAMPO15)),'fm9999999990.00') as Monto_colegiatura,
                                                      TZTCRTE_CAMPO18 as Categoria,
                                                      TZTCRTE_CAMPO10 as Secuencia,
                                                      TZTCRTE_CAMPO26 programa,
                                                      TZTCRTE_CAMPO27 colonia,
                                                      TZTCRTE_CAMPO56 bloque,
                                                      TZTCRTE_CAMPO58 balance
                                            FROM TZTCRNT
                                            where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                            and TZTCRTE_CAMPO18 in  ('COL')
                                            group by
                                                      TZTCRTE_PIDM,
                                                      TZTCRTE_LEVL,
                                                      TZTCRTE_CAMP,
                                                      TZTCRTE_CAMPO11,
                                                      TZTCRTE_CAMPO17,
                                                      TZTCRTE_CAMPO18,
                                                      TZTCRTE_CAMPO10,
                                                      TZTCRTE_CAMPO26,
                                                      TZTCRTE_CAMPO27,
                                                      TZTCRTE_CAMPO56,
                                                      TZTCRTE_CAMPO58
                                            ),
                                            otros as (
                                            select distinct
                                                      TZTCRTE_PIDM Pidm,
                                                      TZTCRTE_LEVL as Nivel,
                                                      TZTCRTE_CAMP as Campus,
                                                      TZTCRTE_CAMPO11  as Fecha_Pago,
                                                      TZTCRTE_CAMPO17 as otros,
                                                      sum (TZTCRTE_CAMPO15) as Monto_otros,
                                                      TZTCRTE_CAMPO18 as Categoria,
                                                      TZTCRTE_CAMPO10 as Secuencia,
                                                      TZTCRTE_CAMPO26 programa,
                                                      TZTCRTE_CAMPO27 colonia,
                                                      TZTCRTE_CAMPO56 bloque,
                                                      TZTCRTE_CAMPO58 balance
                                            FROM TZTCRNT
                                            where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                            and TZTCRTE_CAMPO18 not in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL', 'VTA', 'TUI')
                                            group by
                                                      TZTCRTE_PIDM,
                                                      TZTCRTE_LEVL,
                                                      TZTCRTE_CAMP,
                                                      TZTCRTE_CAMPO11,
                                                      TZTCRTE_CAMPO17,
                                                      TZTCRTE_CAMPO18,
                                                      TZTCRTE_CAMPO10,
                                                      TZTCRTE_CAMPO26,
                                                      TZTCRTE_CAMPO27,
                                                      TZTCRTE_CAMPO56,
                                                      TZTCRTE_CAMPO58
                                            )
                                            select distinct
                                                      TZTCRTE_pidm as pidm,
                                                      TZTCRTE_CAMPO1 as Nombre,
                                                      TZTCRTE_CAMPO2 as RFC,
                                                      TZTCRTE_CAMPO3 as Dom_Fiscal,
                                                      TZTCRTE_CAMPO4 as Ciudad,
                                                      TZTCRTE_CAMPO5 as CP,
                                                      TZTCRTE_CAMPO6 as Pais,
                                                      TZTCRTE_CAMPO7 as Tipo_Deposito,
                                                      TZTCRTE_CAMPO8 as Descripcion,
                                                      TZTCRTE_CAMPO9 as Monto,
                                                      TZTCRTE_LEVL as Nivel,
                                                      TZTCRTE_CAMP as Campus,
                                                      TZTCRTE_ID as Matricula,
                                                      TZTCRTE_CAMPO10  as Transaccion,
                                                      TZTCRTE_CAMPO11  as Fecha_Pago,
                                                      TZTCRTE_CAMPO12 as REFERENCIA,
                                                      TZTCRTE_CAMPO13 as Referencia_Tipo,
                                                      TZTCRTE_CAMPO14  as EMAIL,
                                                      e.Colegiatura,
                                                      e.Monto_colegiatura,
                                                      b.intereses,
                                                      b.Monto_intereses,
                                                      c.accesorios,
                                                      c.Monto_accesorios,
                                                      d.otros,
                                                      d.monto_otros,
                                                      TZTCRTE_CAMPO20 as Curp,
                                                      TZTCRTE_CAMPO21 as Grado,
                                                      TZTCRTE_CAMPO22 as Razon_social,
                                                      TZTCRTE_CAMPO26 programa,
                                                      TZTCRTE_CAMPO27 colonia,
                                                      TZTCRTE_CAMPO58 balance,
                                                      TZTCRTE_CAMPO56 bloque
                                            FROM TZTCRNT, intereses b, accesorios c, otros d, colegiatura e
                                            where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                            and TZTCRTE_CAMPO18 in ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL','VTA')
                                            and TZTCRTE_PIDM = e.pidm (+)
                                            and TZTCRTE_LEVL = e.nivel (+)
                                            and TZTCRTE_CAMP = e.campus (+)
                                            and TZTCRTE_CAMPO11 = e.Fecha_Pago (+)
                                            And TZTCRTE_CAMPO10 = e.secuencia (+)
                                            and TZTCRTE_PIDM = b.pidm (+)
                                            and TZTCRTE_LEVL = b.nivel (+)
                                            and TZTCRTE_CAMP = b.campus (+)
                                            and TZTCRTE_CAMPO11 = b.Fecha_Pago (+)
                                            And TZTCRTE_CAMPO10 = b.secuencia (+)
                                            and TZTCRTE_PIDM = c.pidm (+)
                                            and TZTCRTE_LEVL = c.nivel (+)
                                            and TZTCRTE_CAMP = c.campus (+)
                                            and TZTCRTE_CAMPO11 = c.Fecha_Pago (+)
                                            And TZTCRTE_CAMPO10 = c.secuencia (+)
                                            and TZTCRTE_PIDM = d.pidm (+)
                                            and TZTCRTE_LEVL = d.nivel (+)
                                            and TZTCRTE_CAMP = d.campus (+)
                                            and TZTCRTE_CAMPO11 = d.Fecha_Pago (+)
                                            And TZTCRTE_CAMPO10 = d.secuencia (+)
                                            and TZTCRTE_PIDM = f.SPRIDEN_PIDM
                                            and TZTCRTE_CAMPO10 = f.TBRACCD_TRAN_NUMBER
                                            group by TZTCRTE_pidm,
                                                      TZTCRTE_CAMPO1,
                                                      TZTCRTE_CAMPO2,
                                                      TZTCRTE_CAMPO3,
                                                      TZTCRTE_CAMPO4,
                                                      TZTCRTE_CAMPO5,
                                                      TZTCRTE_CAMPO6,
                                                      TZTCRTE_CAMPO7,
                                                      TZTCRTE_CAMPO8,
                                                      TZTCRTE_CAMPO9,
                                                      TZTCRTE_LEVL,
                                                      TZTCRTE_CAMP,
                                                      TZTCRTE_ID,
                                                      TZTCRTE_CAMPO10,
                                                      TZTCRTE_CAMPO11,
                                                      TZTCRTE_CAMPO12,
                                                      TZTCRTE_CAMPO13,
                                                      TZTCRTE_CAMPO14,
                                                      e.Colegiatura,
                                                      e.Monto_colegiatura,
                                                      b.intereses,
                                                      b.Monto_intereses,
                                                      c.accesorios,
                                                      c.Monto_accesorios,
                                                      d.otros,
                                                      d.monto_otros,
                                                      TZTCRTE_CAMPO20,
                                                      TZTCRTE_CAMPO21,
                                                      TZTCRTE_CAMPO22,
                                                      TZTCRTE_CAMPO26,
                                                      TZTCRTE_CAMPO27,
                                                      TZTCRTE_CAMPO58,
                                                      TZTCRTE_CAMPO56
                                                     order by TZTCRTE_ID, TZTCRTE_CAMPO11, TZTCRTE_CAMPO10

                     )

                     loop
                        vl_consecutivo:=0;
                       BEGIN
                        SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                        INTO vl_consecutivo
                        FROM TZTCRNT
                        WHERE 1=1
                        AND TZTCRTE_PIDM = c.pidm
                        AND TZTCRTE_CAMPO10= c.Transaccion
                        And TZTCRTE_TIPO_REPORTE = 'Facturacion_dia';
                        EXCEPTION
                        WHEN OTHERS THEN
                        vl_consecutivo :=1;
                       END;


                      Insert into TZTCRNT values (c.pidm,--TZTCRTE_PIDM
                                                       c.matricula,--TZTCRTE_ID
                                                        c.campus,--TZTCRTE_CAMP
                                                        c.nivel,--TZTCRTE_LEVL
                                                        c.nombre,--TZTCRTE_CAMPO1
                                                        c.rfc,--TZTCRTE_CAMPO2
                                                        c.dom_fiscal,--TZTCRTE_CAMPO3
                                                        c.ciudad, --TZTCRTE_CAMPO4
                                                        c.cp, --TZTCRTE_CAMPO5
                                                        c.pais,--TZTCRTE_CAMPO6
                                                        c.tipo_deposito,--TZTCRTE_CAMPO7
                                                        c.descripcion,--TZTCRTE_CAMPO8
                                                        c.monto,--TZTCRTE_CAMPO9
                                                        c.transaccion,--TZTCRTE_CAMPO10
                                                        c.fecha_pago,--TZTCRTE_CAMPO11
                                                        c.referencia,--TZTCRTE_CAMPO12
                                                        c.referencia_tipo,--TZTCRTE_CAMPO13
                                                        c.email,--TZTCRTE_CAMPO14
                                                        c.colegiatura, --TZTCRTE_CAMPO15
                                                        c.monto_colegiatura, --TZTCRTE_CAMPO16
                                                        c.intereses,--TZTCRTE_CAMPO17
                                                        c.monto_intereses,--TZTCRTE_CAMPO18
                                                        c.accesorios,--TZTCRTE_CAMPO19
                                                        c.monto_accesorios,--TZTCRTE_CAMPO20
                                                        c.otros,--TZTCRTE_CAMPO21
                                                        c.monto_otros,--TZTCRTE_CAMPO22
                                                        c.CURP,--TZTCRTE_CAMPO23
                                                        c.Grado,--TZTCRTE_CAMPO24
                                                        c.Razon_social,--TZTCRTE_CAMPO25
                                                        c.programa,--TZTCRTE_CAMPO26
                                                        c.colonia, --TZTCRTE_CAMPO27,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        c.bloque,
                                                        vl_consecutivo, --TZTCRTE_CAMPO57
                                                        c.balance, --TZTCRTE_CAMPO58
                                                        USER||'- EMONTADI_FA', --TZTCRTE_CAMPO59,
                                                        TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                        'Facturacion_dia',--TZTCRTE_TIPO_REPORTE
                                                        '',
                                                        ''
                                                        );
                        --DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCRTE con "Facturacion_dia"'||c.pidm||' '||c.monto||' '||c.transaccion||' '||c.colegiatura);
                        End loop;


                   END;
                 COMMIT;


            BEGIN

               vl_levl:= null;

                BEGIN
                SELECT TZTCRTE_LEVL
                into vl_levl
                FROM TZTCRNT
                WHERE 1=1
                AND TZTCRTE_PIDM = f.SPRIDEN_PIDM
                AND TZTCRTE_CAMPO10 = f.TBRACCD_TRAN_NUMBER
                GROUP BY TZTCRTE_LEVL;
                EXCEPTION WHEN OTHERS THEN
                vl_levl := null;
                END;

                --DBMS_OUTPUT.PUT_LINE(vl_levl||f.SPRIDEN_PIDM);

                     FOR conceptos in (SELECT PAGOS_FACT .*, ROW_NUMBER() OVER(PARTITION BY TRANSACCION ORDER BY TBRACCD_ACTIVITY_DATE) numero
                                        FROM (with cargo as (
                                                select
                                                c.TVRACCD_PIDM PIDM,
                                                c.TVRACCD_DETAIL_CODE cargo,
                                                c.TVRACCD_ACCD_TRAN_NUMBER transa,
                                                c.TVRACCD_DESC descripcion,
                                                to_char(nvl(c.TVRACCD_AMOUNT,0) - nvl(c.TVRACCD_balance,0),'fm9999999990.00') MONTO_CARGO,
                                                Monto_Iv Monto_IVAS
                                           from TVRACCD c, TBBDETC a, (select distinct to_char(nvl (i.TVRACCD_AMOUNT, 0) -nvl (i.TVRACCD_BALANCE, 0) ,'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                         from tvraccd i
                                                                                         where 1=1
                                                                                         and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                         ) monto_iva
                                           where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                and a.TBBDETC_TYPE_IND = 'C'
                                                and c.TVRACCD_DESC not like 'IVA%'
                                                and c.TVRACCD_DETAIL_CODE not like ('IVA%')
                                                and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
                                                   ) ,
                                          FISCAL AS (
                                            Select SPREMRG_PIDM, SPREMRG_PRIORITY, SPREMRG_LAST_NAME, SPREMRG_FIRST_NAME, SPREMRG_MI,
                                            SPREMRG_STREET_LINE1, SPREMRG_STREET_LINE2, SPREMRG_STREET_LINE3, SPREMRG_CITY, SPREMRG_STAT_CODE, SPREMRG_NATN_CODE,
                                            SPREMRG_ZIP, SPREMRG_PHONE_AREA, SPREMRG_PHONE_NUMBER, SPREMRG_PHONE_EXT, SPREMRG_RELT_CODE
                                            from SPREMRG s
                                        Where  s.SPREMRG_MI IS NOT NULL
                                        AND SPREMRG_RELT_CODE = 'I'
                                            AND to_number (s.SPREMRG_PRIORITY) = (SELECT MAX (to_number (s1.SPREMRG_PRIORITY))
                                                                                                           FROM SPREMRG s1
                                                                                                           WHERE s.SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                                                                           AND s.SPREMRG_RELT_CODE = s1.SPREMRG_RELT_CODE)
                                        AND length(s.SPREMRG_MI) <=13
                                        )
                                        SELECT DISTINCT
                                        TBRACCD_PIDM PIDM,
                                        SPRIDEN_ID MATRICULA,
                                        SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                        TBRACCD_TRAN_NUMBER TRANSACCION,
                                        to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                        to_char(nvl(TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                        --to_char(nvl((TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1))), TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                        case
                                         When GORADID_ADID_CODE = 'REFS'then
                                               to_char(nvl(TBRAPPL_AMOUNT, TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                               --to_char(nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                         When GORADID_ADID_CODE IN ('REFH', 'REFU') then
                                          to_char (nvl(TBRAPPL_AMOUNT, TBRACCD_AMOUNT), 'fm9999999990.00')
                                          --to_char (nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT), 'fm9999999990.00')
                                        End  SUBTOTAL,
                                        case
                                         When   GORADID_ADID_CODE = 'REFS' then
                                                 to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT) -    nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                         When GORADID_ADID_CODE IN ('REFH', 'REFU') then
                                                --to_char (TBRACCD_AMOUNT- (TBRACCD_AMOUNT /1.16),'fm9999999990.00')
                                             '0.00'
                                           End IVA,
                                        nvl (TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                        to_char(TBRACCD_ENTRY_DATE, 'dd/mm/rrrr') Fecha_pago,
                                        TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                        TBBDETC_DESC DESCRIPCION,
                                        nvl (cargo.cargo, substr(TBBDETC_DETAIL_CODE,1, 2)||(SELECT SUBSTR(TBBDETC_DETAIL_CODE,3,2)
                                                            FROM TBBDETC
                                                            WHERE 1=1
                                                            AND TBBDETC_TAXT_CODE = vl_levl
                                                            AND TBBDETC_DCAT_CODE IN ('COL', 'CCC')
                                                            AND TBBDETC_DESC like 'COLEGIATURA%'
                                                            AND TBBDETC_DESC not like  '%REFI'
                                                            AND TBBDETC_DESC not like '%NOTA'
                                                            AND TBBDETC_DESC not like  '%LIC'
                                                            AND TBBDETC_DETC_ACTIVE_IND = 'Y'
                                                            AND SUBSTR(TBBDETC_DETAIL_CODE,1,2)=substr(SPRIDEN_ID,1,2)
                                                            group by TBBDETC_DETAIL_CODE
                                                            )
                                        )clave_cargo,
                                        CASE WHEN cargo.descripcion LIKE '%CANC%'
                                        THEN 'PCOLEGIATURA'
                                        WHEN cargo.descripcion NOT LIKE '%CANC%'
                                        THEN
                                        nvl (cargo.descripcion, 'PCOLEGIATURA')
                                        END Descripcion_cargo,
                                        nvl(cargo.transa,0) transa,
                                       upper(NVL(SPREMRG_MI, 'XAXX010101000')) RFC,
                                        CASE
                                         when GORADID_ADID_CODE = 'REFH' then
                                         'BH'
                                         when GORADID_ADID_CODE = 'REFS' then
                                         'BS'
                                         when GORADID_ADID_CODE = 'REFU' then
                                         'UI'
                                         when GORADID_ADID_CODE IS NULL then
                                         'NI'
                                        end Serie,
                                        TBRACCD_ACTIVITY_DATE,
                                        CASE
                                        WHEN TBRACCD_DESC LIKE '%EFEC%'THEN '01'
                                        WHEN TBRACCD_DESC LIKE '%CHEQUE%'THEN '02'
                                        WHEN TBRACCD_DESC LIKE '%TRANS%'THEN '03'
                                        WHEN TBRACCD_DESC LIKE '%EMPRESARIALES%' THEN '03'
                                        WHEN TBRACCD_DESC LIKE '%RECLAS%'THEN '03'
                                        WHEN TBRACCD_DESC LIKE '%TDC%'THEN '04'
                                        WHEN TBRACCD_DESC LIKE '%CRED%'THEN '04' --'%TARJETA CREDITO%'
                                        WHEN TBRACCD_DESC LIKE '%DEB%'THEN  '28' --'%TARJETA DEBITO%'
                                        WHEN TBRACCD_DESC LIKE '%POLIZA%'THEN '100'
                                        ELSE '99'
                                        END forma_pago,
                                        TBRACCD_RECEIPT_NUMBER,
                                        NVL((SELECT
                                             CASE
                                             WHEN TBBDETC_DCAT_CODE IN ('CAN', 'AAC')
                                             THEN 'COL'
                                             WHEN TBBDETC_DCAT_CODE NOT IN ('CAN', 'AAC')
                                             THEN TBBDETC_DCAT_CODE
                                             END
                                             FROM TBBDETC
                                             WHERE 1=1
                                             AND TBBDETC_DETAIL_CODE = cargo.cargo),'COL')cargo_code
                                        FROM TBRACCD
                                        join SPRIDEN ON SPRIDEN_PIDM = TBRACCD_PIDM and SPRIDEN_CHANGE_IND is null
                                        join TBBDETC ON  TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        join  TBRAPPL ON TBRAPPL_PIDM = TBRACCD_PIDM AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER AND TBRAPPL_REAPPL_IND IS NULL
                                        left join cargo on cargo.pidm = tbraccd_pidm and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                        left join fiscal s on s.SPREMRG_PIDM = tbraccd_pidm
                                        left join GORADID on GORADID_PIDM = TBRACCD_PIDM and GORADID_ADID_CODE LIKE 'REF%'
                                        left join tztordr on TZTORDR_PIDM = tbraccd_pidm  and  TZTORDR_CONTADOR = TBRACCD_RECEIPT_NUMBER
                                        join TZTNCD on tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                        And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                        WHERE TBBDETC_TYPE_IND = 'P'
                                        --AND TBBDETC_DCAT_CODE = 'CSH'
                                        and TBRACCD_AMOUNT >= 1
                                        AND TBRACCD_TRAN_NUMBER  NOT IN (SELECT TZTCONC_TRAN_NUMBER  -- 02/12/2019
                                                                  FROM TZTCONT
                                                                  WHERE TBRACCD_PIDM = TZTCONC_PIDM)
                                        AND TRUNC (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE --'02/12/2019' -- --'16/08/2019'
                                        AND TBRACCD_PIDM = f.SPRIDEN_PIDM --38543
                                        AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER --60
                                        --AND TBRACCD_DESC LIKE '%DEBITO%'
                                        )PAGOS_FACT
                                         WHERE 1=1
                                UNION
                                SELECT
                                             TZTCRTE_PIDM PIDM,
                                             TZTCRTE_ID MATRICULA,
                                             SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                             TBRACCD_TRAN_NUMBER TRANSACCION,
                                             to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                             to_char(TBRACCD_AMOUNT,'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                              case
                                             When GORADID_ADID_CODE = 'REFS'then
                                                   to_char(TBRACCD_AMOUNT / 1.16,'fm9999999990.00')
                                                   --to_char(nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                             When GORADID_ADID_CODE IN ('REFH','REFU') then
                                              to_char (TBRACCD_AMOUNT, 'fm9999999990.00')
                                              --to_char (nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT), 'fm9999999990.00')
                                            End  SUBTOTAL,
                                            case
                                             When   GORADID_ADID_CODE ='REFS' then
                                                     to_char(TBRACCD_AMOUNT - TBRACCD_AMOUNT / 1.16,'fm9999999990.00')
                                             When GORADID_ADID_CODE IN ('REFH','REFU')  then
                                                    --to_char (TBRACCD_AMOUNT- (TBRACCD_AMOUNT /1.16),'fm9999999990.00')
                                                 '0.00'
                                               End IVA,
                                            Null CARGO_CUBIERTO,
                                            to_char(TBRACCD_ENTRY_DATE, 'dd/mm/rrrr') Fecha_pago,
                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                            TBBDETC_DESC DESCRIPCION,
                                            substr(TBBDETC_DETAIL_CODE,1, 2)||(SELECT SUBSTR(TBBDETC_DETAIL_CODE,3,2)
                                                                FROM TBBDETC
                                                                WHERE 1=1
                                                                AND TBBDETC_TAXT_CODE = 'vl_levl' --TZTORDR_NIVEL
                                                                AND TBBDETC_DCAT_CODE IN ('COL', 'CCC')
                                                                AND TBBDETC_DESC like 'COLEGIATURA%'
                                                                AND TBBDETC_DESC not like  '%REFI'
                                                                AND TBBDETC_DESC not like '%NOTA'
                                                                AND TBBDETC_DESC not like  '%LIC'
                                                                AND TBBDETC_DETC_ACTIVE_IND = 'Y'
                                                                AND SUBSTR(TBBDETC_DETAIL_CODE,1,2)=substr(SPRIDEN_ID,1,2)
                                                                group by TBBDETC_DETAIL_CODE
                                                                --and rownum = 1
                                                                )clave_cargo,
                                            'PCOLEGIATURA' Descripcion_cargo,
                                            TVRACCD_ACCD_TRAN_NUMBER transa,
                                             --0 transa,
                                             'XAXX010101000' RFC,
                                            CASE
                                             when GORADID_ADID_CODE = 'REFH' then
                                             'BH'
                                             when GORADID_ADID_CODE = 'REFS' then
                                             'BS'
                                             when GORADID_ADID_CODE = 'REFU' then
                                             'UI'
                                             when GORADID_ADID_CODE IS NULL then
                                             'NI'
                                            end Serie,
                                            TBRACCD_ACTIVITY_DATE,
                                            CASE
                                            WHEN TBRACCD_DESC LIKE '%EFEC%'THEN '01'
                                            WHEN TBRACCD_DESC LIKE '%CHEQUE%'THEN '02'
                                            WHEN TBRACCD_DESC LIKE '%TRANS%'THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%EMPRESARIALES%' THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%RECLAS%'THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%TDC%'THEN '04'
                                            WHEN TBRACCD_DESC LIKE '%CRED%'THEN '04' --'%TARJETA CREDITO%'
                                            WHEN TBRACCD_DESC LIKE '%DEB%'THEN  '28' --'%TARJETA DEBITO%'
                                            WHEN TBRACCD_DESC LIKE '%ELECT%'THEN '28'
                                            WHEN TBRACCD_DESC LIKE '%POLIZA%'THEN '100'
                                            ELSE '99'
                                            END forma_pago,
                                            TBRACCD_RECEIPT_NUMBER,
                                            'COL' cargo_code,
                                            1 numero
                                             FROM TZTCRNT a, SPRIDEN, TBRACCD, GORADID, TBBDETC, TVRACCD, TZTNCD ----Agregar esta tabla Victor
                                             WHERE 1=1
                                             AND a.TZTCRTE_PIDM = SPRIDEN_PIDM
                                             AND a.TZTCRTE_PIDM = TBRACCD_PIDM
                                             AND a.TZTCRTE_CAMPO10  = TBRACCD_TRAN_NUMBER
                                             AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                             AND SPRIDEN_CHANGE_IND IS NULL
                                             AND GORADID_PIDM = TBRACCD_PIDM
                                             AND GORADID_ADID_CODE LIKE 'REF%'
                                             AND a.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                                             AND TBBDETC_TYPE_IND = 'P'
                                             -- AND TBBDETC_DCAT_CODE = 'CSH' -- apagar esta linea
                                            And tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                            AND TBRACCD_AMOUNT >= 1
                                             AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTCONC_TRAN_NUMBER  -- 02/12/2019
                                                                      FROM TZTCONT
                                                                      WHERE TBRACCD_PIDM = TZTCONC_PIDM)
                                             AND TBRACCD_PIDM = TVRACCD_PIDM
                                             AND TBRACCD_TRAN_NUMBER = TVRACCD_TRAN_NUMBER
                                             AND TBRACCD_TRAN_NUMBER IN (SELECT TBRAPPL_PAY_TRAN_NUMBER
                                                                             FROM TBRAPPL
                                                                             WHERE 1=1
                                                                             AND TBRACCD_PIDM = TBRAPPL_PIDM
                                                                             AND TBRAPPL_REAPPL_IND = 'Y')
                                            AND a.TZTCRTE_CAMPO57 IN (SELECT MAX(TZTCRTE_CAMPO57)
                                                                       FROM TZTCRNT b
                                                                       WHERE 1=1
                                                                       AND a.TZTCRTE_PIDM =b.TZTCRTE_PIDM
                                                                       AND a.TZTCRTE_CAMP = b.TZTCRTE_CAMP
                                                                       AND a.TZTCRTE_CAMPO10 = b.TZTCRTE_CAMPO10
                                                                       AND a.TZTCRTE_TIPO_REPORTE = b.TZTCRTE_TIPO_REPORTE)
                                            AND TRUNC (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE --'02/12/2019' -- --'16/08/2019'
                                            AND TBRACCD_PIDM = f.SPRIDEN_PIDM  --38543
                                            AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER  --60
                                UNION
                                SELECT
                                             TZTCRTE_PIDM PIDM,
                                             TZTCRTE_ID MATRICULA,
                                             SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                             TBRACCD_TRAN_NUMBER TRANSACCION,
                                             to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                             to_char(TBRACCD_AMOUNT,'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                              case
                                             When GORADID_ADID_CODE = 'REFS'then
                                                   to_char(TBRACCD_AMOUNT / 1.16,'fm9999999990.00')
                                                   --to_char(nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                             When GORADID_ADID_CODE IN ('REFH','REFU') then
                                              to_char (TBRACCD_AMOUNT, 'fm9999999990.00')
                                              --to_char (nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT), 'fm9999999990.00')
                                            End  SUBTOTAL,
                                            case
                                             When   GORADID_ADID_CODE ='REFS' then
                                                     to_char(TBRACCD_AMOUNT - TBRACCD_AMOUNT / 1.16,'fm9999999990.00')
                                             When GORADID_ADID_CODE IN ('REFH','REFU')  then
                                                    --to_char (TBRACCD_AMOUNT- (TBRACCD_AMOUNT /1.16),'fm9999999990.00')
                                                 '0.00'
                                               End IVA,
                                            Null CARGO_CUBIERTO,
                                            to_char(TBRACCD_ENTRY_DATE, 'dd/mm/rrrr') Fecha_pago,
                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                            TBBDETC_DESC DESCRIPCION,
                                            substr(TBBDETC_DETAIL_CODE,1, 2)||(SELECT SUBSTR(TBBDETC_DETAIL_CODE,3,2)
                                                                FROM TBBDETC
                                                                WHERE 1=1
                                                                AND TBBDETC_TAXT_CODE = vl_levl --TZTORDR_NIVEL
                                                                AND TBBDETC_DCAT_CODE IN ('COL', 'CCC')
                                                                AND TBBDETC_DESC like 'COLEGIATURA%'
                                                                AND TBBDETC_DESC not like  '%REFI'
                                                                AND TBBDETC_DESC not like '%NOTA'
                                                                AND TBBDETC_DESC not like  '%LIC'
                                                                AND TBBDETC_DETC_ACTIVE_IND = 'Y'
                                                                AND SUBSTR(TBBDETC_DETAIL_CODE,1,2)=substr(SPRIDEN_ID,1,2)
                                                                group by TBBDETC_DETAIL_CODE
                                                                --and rownum = 1
                                                                )clave_cargo,
                                            'PCOLEGIATURA' Descripcion_cargo,
                                             0 transa,
                                             'XAXX010101000' RFC,
                                            CASE
                                             when GORADID_ADID_CODE = 'REFH' then
                                             'BH'
                                             when GORADID_ADID_CODE = 'REFS' then
                                             'BS'
                                             when GORADID_ADID_CODE = 'REFU' then
                                             'UI'
                                             when GORADID_ADID_CODE IS NULL then
                                             'NI'
                                            end Serie,
                                            TBRACCD_ACTIVITY_DATE,
                                            CASE
                                            WHEN TBRACCD_DESC LIKE '%EFEC%'THEN '01'
                                            WHEN TBRACCD_DESC LIKE '%CHEQUE%'THEN '02'
                                            WHEN TBRACCD_DESC LIKE '%TRANS%'THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%EMPRESARIALES%' THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%RECLAS%'THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%TDC%'THEN '04'
                                            WHEN TBRACCD_DESC LIKE '%CRED%'THEN '04' --'%TARJETA CREDITO%'
                                            WHEN TBRACCD_DESC LIKE '%DEB%'THEN  '28' --'%TARJETA DEBITO%'
                                            WHEN TBRACCD_DESC LIKE '%ELECT%'THEN '28'
                                            WHEN TBRACCD_DESC LIKE '%POLIZA%'THEN '100'
                                            ELSE '99'
                                            END forma_pago,
                                            TBRACCD_RECEIPT_NUMBER,
                                            'COL' cargo_code,
                                            1 numero
                                             FROM TZTCRNT a, SPRIDEN, TBRACCD, GORADID, TBBDETC, TZTNCD ----Agregar esta tabla Victor
                                             WHERE 1=1
                                             AND a.TZTCRTE_PIDM = SPRIDEN_PIDM
                                             AND a.TZTCRTE_PIDM = TBRACCD_PIDM
                                             AND a.TZTCRTE_CAMPO10  = TBRACCD_TRAN_NUMBER
                                             AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                             AND SPRIDEN_CHANGE_IND IS NULL
                                             AND GORADID_PIDM = TBRACCD_PIDM
                                             AND GORADID_ADID_CODE LIKE 'REF%'
                                             AND a.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                                             AND TBBDETC_TYPE_IND = 'P'
                                             -- AND TBBDETC_DCAT_CODE = 'CSH' -- apagar esta linea
                                            And tbraccd_detail_code =  TZTNCD_CODE ----Agregar esta columna Victor
                                            And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')        ----Agregar esta columna Victor
                                             AND TBRACCD_AMOUNT >= 1
                                             AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTCONC_TRAN_NUMBER  -- 02/12/2019
                                                                      FROM TZTCONT
                                                                      WHERE TBRACCD_PIDM = TZTCONC_PIDM)
                                             AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TBRAPPL_PAY_TRAN_NUMBER
                                                                             FROM TBRAPPL
                                                                             WHERE 1=1
                                                                             AND TBRACCD_PIDM = TBRAPPL_PIDM)
                                            AND a.TZTCRTE_CAMPO57 IN (SELECT MAX(TZTCRTE_CAMPO57)
                                                                       FROM TZTCRNT b
                                                                       WHERE 1=1
                                                                       AND a.TZTCRTE_PIDM =b.TZTCRTE_PIDM
                                                                       AND a.TZTCRTE_CAMP = b.TZTCRTE_CAMP
                                                                       AND a.TZTCRTE_CAMPO10 = b.TZTCRTE_CAMPO10
                                                                       AND a.TZTCRTE_TIPO_REPORTE = b.TZTCRTE_TIPO_REPORTE)
                                            AND TRUNC (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE --'02/12/2019' -- --'16/08/2019'
                                            AND TBRACCD_PIDM = f.SPRIDEN_PIDM --38543
                                            AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER --60

                              )LOOP

                                    vl_tipo_impuesto:= Null;
                                    vl_moneda:= Null;
                                    vl_subtotal_accs:=Null;
                                    vl_iva_accs:= Null;
                                    vl_codpago := null;


                                         If length (conceptos.clave_cargo) != 4 then
                                               Begin

                                                        select distinct TBBDETC_DETAIL_CODE
                                                        Into vl_codpago
                                                        from tztordr, tbraccd, tbbdetc, TZTNCD
                                                        where 1= 1
                                                        And TZTORDR_PIDM = tbraccd_pidm
                                                        And TZTORDR_PIDM = conceptos.PIDM
                                                       --And TBRACCD_TRAN_NUMBER = conceptos.TRANSACCION
                                                        and  TZTORDR_CONTADOR = TBRACCD_RECEIPT_NUMBER
                                                        And substr (TBBDETC_DETAIL_CODE, 1,2) = substr (TZTORDR_ID,1,2)
                                                        And TBBDETC_DCAT_CODE ='COL'
                                                        and TBBDETC_DETC_ACTIVE_IND ='Y'
                                                        And TBBDETC_TAXT_CODE = TZTORDR_NIVEL
                                                        And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                        And TZTNCD_CONCEPTO ='Venta';

                                               Exception
                                                When Others then
                                                vl_codpago := conceptos.clave_cargo;
                                               End;
                                            Elsif length (conceptos.clave_cargo) = 4 then
                                            vl_codpago := conceptos.clave_cargo;
                                          End if;


                                    BEGIN
                                       SELECT TVRDCTX_TXPR_CODE
                                       INTO vl_tipo_impuesto
                                       from TVRDCTX
                                       WHERE 1=1
                                       AND TVRDCTX_DETC_CODE = vl_codpago;-- conceptos.clave_cargo ;
                                       EXCEPTION WHEN OTHERS THEN
                                       NULL;
                                    END;


                                 vl_consecutivo := 0;

                                   BEGIN
                                    SELECT NVL(MAX(TZTLOFA_SEQ_NO), 0) +1
                                    INTO vl_consecutivo
                                    FROM TZTLOFA
                                    WHERE 1=1
                                    AND TZTLOFA_PIDM = conceptos.PIDM
                                    AND TZTLOFA_TRAN_NUMBER= conceptos.TRANSACCION
                                    And TZTLOFA_CAMPO1 = 'TZTCONC';
                                    EXCEPTION
                                    WHEN OTHERS THEN
                                    vl_consecutivo :=1;
                                   END;


                                    BEGIN

                                        SELECT TBRACCD_CURR_CODE
                                        INTO vl_moneda
                                        FROM
                                        TBRACCD
                                        WHERE 1=1
                                        AND TBRACCD_PIDM = conceptos.PIDM
                                        AND TBRACCD_TRAN_NUMBER = conceptos.TRANSACCION;
                                        EXCEPTION WHEN OTHERS THEN
                                            BEGIN
                                            INSERT INTO TZTLOFA
                                            (TZTLOFA_PIDM,
                                                TZTLOFA_ID,
                                                TZTLOFA_TRAN_NUMBER,
                                                TZTLOFA_OBS,
                                                TZTLOFA_ACTIVITY_DATE,
                                                TZTLOFA_USER,
                                                TZTLOFA_CAMPO1,
                                                TZTLOFA_CAMPO2,
                                                TZTLOFA_CAMPO3,
                                                TZTLOFA_CAMPO4,
                                                TZTLOFA_CAMPO5,
                                                TZTLOFA_CAMPO6,
                                                TZTLOFA_SEQ_NO
                                             )
                                             VALUES(conceptos.PIDM,
                                                    conceptos.MATRICULA,
                                                    conceptos.TRANSACCION,
                                                    'ERROR EN LA MONEDA',
                                                    SYSDATE,
                                                    USER,
                                                    'TZTCONC',
                                                    Null,
                                                    Null,
                                                    Null,
                                                    Null,
                                                    Null,
                                                    vl_consecutivo
                                                    );
                                            END;
                                        COMMIT;
                                    END;



                                        IF vl_tipo_impuesto ='IVA' AND conceptos.Serie IN ('BH', 'UI')THEN
                                            vl_subtotal_accs:= TO_CHAR((conceptos.SUBTOTAL /1.16), 'fm9999999990.00');
                                            vl_iva_accs:= (conceptos.MONTO_PAGADO_CARGO - (conceptos.SUBTOTAL /1.16));

                                        ELSE

                                            vl_subtotal_accs:=conceptos.SUBTOTAL;
                                            vl_iva_accs:= conceptos.IVA;

                                        END IF;

                                        --DBMS_OUTPUT.PUT_LINE('Tipo IVA '||vl_tipo_impuesto||'**'||vl_subtotal_accs);



                                Begin
                                    Insert into TZTCONT values (conceptos.PIDM, --TZTCONC_PIDM
                                                              NULL, --TZTCONC_FOLIO
                                                              vl_codpago, --TZTCONC_CONCEPTO_CODE
                                                              conceptos.Descripcion_cargo, --TZTCONC_CONCEPTO
                                                              conceptos.MONTO_PAGADO_CARGO, --TZTCONC_MONTO
                                                              vl_subtotal_accs,--conceptos.SUBTOTAL,--TZTCONC_SUBTOTAL
                                                              vl_iva_accs, --conceptos.IVA, --TZTCONC_IVA
                                                              conceptos.TRANSACCION, --TZTCONC_TRAN_NUMBER
                                                              conceptos.Fecha_pago, --TZTCONC_FECHA_CONC
                                                              conceptos.Serie, --TZTCONC_SERIE
                                                              conceptos.RFC, --TZTCONC_RFC
                                                              'FA',--TZTCONC_TIPO_DOCTO
                                                              conceptos.numero, --TZTCONC_SEQ_PAGO
                                                              conceptos.forma_pago, --TZTCONC_FORMA_PAGO
                                                              conceptos.transa,--TZTCONC_TRAN_PAGADA
                                                              TRUNC(SYSDATE), --TZTCONC_ACTIVITY_DATE
                                                              USER||'- EMONTADI_FA', --TZTCON_USER
                                                              conceptos.cargo_code,
                                                              vl_moneda --TZTCONC_MONEDA
                                                                             );
                                EXCEPTION
                                    When Others then
                                    VL_ERROR := 'Error al Insertar' ||sqlerrm;
                             --       dbms_output.put_line('Error '||conceptos.PIDM||'+'||VL_ERROR );
                                END;

                                --DBMS_OUTPUT.PUT_LINE('Datos insertados en  TZTCONC con "Facturacion_dia"'||conceptos.pidm||' '||conceptos.MONTO_PAGADO_CARGO||' '||conceptos.TRANSACCION);
                              END LOOP;
                             COMMIT;
                  END;

          END; --CIERRA EL BEGIN DEL CURSOSR DE LOS DATOS A BUSCAR

       END LOOP;
      COMMIT;
    END SP_CARGA_FA_PI; --CIERRA EL BEGIN GENERAL



PROCEDURE SP_GENERA_XML_NT
IS
--GENERA XML NT
--DECLARE
 --VARIABLES DE CABECERO--
 /*<soapenv:Envelope
    xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:end="http://endpoint.nexttech.com/">
    <soapenv:Header/>
    <soapenv:Body>
        <end:generarCFDI>
            */

        vl_soap varchar2(4000);
        vl_xmlns_soap varchar2(200):= 'http://schemas.xmlsoap.org/soap/envelope/';
        vl_xmlns_xsi varchar2(200):= 'http://www.w3.org/2001/XMLSchema-instance';
        vl_xmlns_xsd varchar2(200):='http://www.w3.org/2001/XMLSchema';
        vl_xmlns_neon varchar2(200):='http://neon.stoconsulting.com/NeonEmisionWS/NeonEmisionWS';
        --------------------------------------------------------

        -- VARIABLES PARA EL COMPONENTE  comprobante--'
        vl_comprobante varchar2(2000);
        vl_consecutivo number :=0; -- variable que contiene el folio de cpomponente--
        vl_condicion_pago varchar2(250):= 'Pago en una sola exhibicion';
        vl_tipo_cambio varchar2(10):=1;
        vl_tipo_moneda varchar2(10);
        vl_metodo_pago varchar2(10):= 'PUE';
        vl_lugar_expedicion varchar2(10):= '53370';
        vl_tipo_comprobante varchar2(5):= 'I';
        vl_subtotal number(16,2);
        vl_descuento_comprobante varchar2(15):='0.00';
        vl_pago_total number :=0;
        vl_confirmacion varchar2(4);
        vl_tipo_documento number:=1;
        vl_fecha_pago varchar2(20);
        --------------------------------------------------------

        -- VARIABLES CON EL  HTML  DEL envioCfdi --
        vl_envio_cfdi varchar2(2000);
        vl_enviar_xml varchar2(4);--:='1';
        vl_enviar_pdf varchar2(15);--:='1';
        vl_enviar_zip varchar2(15);--:='1';
        vl_enviar varchar2(1);


        --------------------------------------------------------------------------

        -- VARIABLES PARA EL COMPONENTE  emisor--
        vl_rfc_utel varchar2 (50); -- Variable para el RFC del emisor de la factura
        vl_razon_social_utel varchar2(250); --Variable para la razón social del emisor de la factura
        vl_regimen_fiscal varchar2(5):= '601'; -- variable que ocntiene el regimen fiscal del emisor
        vl_id_emisor_sto number:=1; --Emisor_STO
        vl_id_emisor_erp number:=1; --Emisor_ERP
        vl_idTipoReceptor number:=0;
        vl_correoR Varchar2(100);
        vl_emisor varchar(4000); --variable para almacenar concatenar los componentes del emisor
        vl_cp_emisor varchar2(10);


        -- VARIABLES PARA EL COMPONENTE  receptor--
        vl_receptor varchar(4000);
        vl_residencia_fiscal varchar2(100);
        vl_num_reg_id_trib varchar2(250);
        vl_uso_cfdi varchar2(25); --:='D10';
        vl_referencia_dom_receptor varchar2(224);
        vl_estatus_registro varchar2(250); --:='2';
        vl_cuenta_registro number;
        vl_cuenta_registro1 number;
        -----------------------------------------

        ---- VARIABLES PARA EL COMPONENTE flexHeaders --
        vl_flex_header varchar2(1000);
        vl_flex_header_2 varchar2(1000);
        vl_flex_header_3 varchar2(1000);
        vl_flex_header_4 varchar2(1000);
        vl_flex_header_5 varchar2(1000);
        vl_flex_header_6 varchar2(1000);
        vl_flex_header_7 varchar2(1000);
        vl_flex_header_8 varchar2(1000);
        vl_flex_header_9 varchar2(1000);
        vl_flex_header_10 varchar2(1000);
        vl_flex_header_11 varchar2(1000);
        vl_flex_header_12 varchar2(1000);
        vl_flex_header_13 varchar2(1000);
        vl_flex_header_14 varchar2(1000);
        vl_flex_header_15 varchar2(1000);
        vl_flex_header_16 varchar2(1000);
        vl_flex_header_17 varchar2(1000);
        vl_flex_header_18 varchar2(1000);
        vl_flex_header_19 varchar2(1000);
        vl_flex_header_20 varchar2(1000);
        vl_flex_header_21 varchar2(1000);
        vl_flex_header_22 varchar2(1000);
        vl_flex_header_23 varchar2(1000);
        vl_flex_header_24 varchar2(1000);
        vl_flex_header_25 varchar2(1000);
        vl_flex_header_26 varchar2(1000);
        vl_flex_header_27 varchar2(1000);
        vl_flex_header_28 varchar2(1000);
        vl_flex_header_29 varchar2(1000);
        vl_flex_header_30 varchar2(1000);
        vl_flex_header_31 varchar2(1000);
        vl_flex_header_32 varchar2(1000);
        vl_flex_header_33 varchar2(1000);
        vl_flex_header_34 varchar2(1000);


        vl_flex_hdrs_tag varchar2(100):= 'flexHeaders';
        vl_flex_hdrs_clave varchar2(100):= 'clave';
        vl_flex_hdrs_nombre varchar2(100):='nombre';
        vl_flex_hdrs_valor varchar2(100):='valor';
        x number:= 0;
        vl_flxhdrs_nombre varchar2(1000);
        vl_flxhdrs_valor varchar2(1000);
        vl_metodo_pago_code varchar2(1000);
        vl_pago_metodo_pago varchar2(1000);
        vl_pago_id_pago varchar2(1000);
        vl_pago_monto_pagado varchar2(1000);
        vl_sum_bubtotal varchar2(1000);
        vl_residuo varchar2(1000);
        vl_pago_fecha_pago varchar2(1000);
        vl_pago_monto_interes varchar2(1000);
        vl_pago_tipo_accesorio varchar2(2500);
        vl_pago_monto_accesorio varchar2(1000);
        vl_pago_monto_accesorio_G varchar2(1000);
        vl_pago_colegiaturas varchar2(1000);
        vl_pago_monto_colegiatura varchar2(1000);
        vl_pago_intereses varchar2(1000);
        vl_obs varchar(1000) := '.';
        ----------------------------------------------------------

        ---- VARIABLES HTML PARA EL COMPONENTE conceptos --|

        vl_claveProdserv_tag varchar2(50):='conceptos claveProdServ="';
        vl_conceptos_close_tag varchar2(50):= '</conceptos>';
        vl_cantidad_tag varchar2(50):= '" cantidad="';
        vl_clave_unidad_tag varchar2(50):=' claveUnidad="';
        vl_unidad_tag varchar2(50):= 'unidad="';
        vl_num_identificacion_tag varchar2(50):= ' numIdentificacion="';
        vl_descripcion_tag  varchar2(50):='" descripcion="';
        vl_valor_unitario_tag varchar2(50):= '" valorUnitario="';
        vl_importe_tag varchar2(50):= '" importe="';
        vl_descuento_tag varchar2(50):='" descuento="';

        ---- VARIABLES PARA EL COMPONENTE conceptos --|
        vl_prod_serv varchar2(500); --variable con el código de servicio--
        vl_cantidad_concepto varchar2(10):='1';
        vl_clave_unidad_concepto varchar2(10):='E48';
       -- vl_unidad_concepto varchar2(500):='Servicio" ';
        vl_unidad_concepto varchar2(500):='Servicio ';--'Servicio" '; -- Se elimina la comilla doble para facto 4
        vl_numIdentificacion varchar2(500);
        vl_descripcion varchar2(500);
        vl_valorUnitario varchar2(500);
        vl_balance varchar2(500);
        vl_balance_1 varchar(50);
        vl_remanente varchar2(50);
        vl_importe varchar2(50);
        vl_descuento varchar2(15):='0.00';
        vl_objetoImp varchar2(2):='03'; --Agregado para facto 4.0 Caty
       -- vl_objetoImp varchar2(2):='02'; --Agregado para facto 4.0 Caty
      --  vl_objetoImp_01 varchar2(2):='01'; --Agregado para facto 4.0 Caty        -----------------------------------------------------

        ---- VARIABLES HTML PARA EL COMPONENTE traslados --
        vl_impuestos_tag varchar2(500):='<impuestos>';
        vl_impuestos_close_tag varchar2(500):='</impuestos>';
        vl_traslados_tag varchar2(500):='<trasladado>';
        vl_base_tag varchar2(500):='base="';
        vl_impuesto_tag varchar2(500):= '<impuesto>';
        vl_tipo_factor_tag varchar2(500):='<tipoFactor>';
        vl_tasa_cuota_impuesto_tag varchar2(500):='<tasaOCuota>"';
        vl_importe_tras_tag varchar2(500):= '<importe>';
        ---- VARIABLES PARA EL COMPONENTE traslados --

        vl_base varchar2(500);
        vl_impuesto_cod varchar2(500):='002';
        vl_tipo_impuesto varchar2(500);
        vl_tipo_factor_impuesto varchar2(500);
        vl_tipo_factor_impuesto_final varchar2(500);
        vl_tasa_cuota_impuesto varchar2(500);
        vl_importe_tras  varchar2(500);
        vl_crtgo_code varchar2(6);

        -----------------------------------------------


        ----VARIABLES  HTML COMPLEMENTO CONCEPTOS--
        vl_InstEducativas_tag varchar2(50):= '<InstEducativas>';
        vl_InstEducativas_close_tag varchar2(50):='</InstEducativas>';
        vl_autrvoe_tag varchar2(50) := '<autrvoe>';
        vl_autrvoe_close_tag varchar2(50) := '</autrvoe>';
        vl_curp_tag varchar2(50) := '<curp>';
        vl_curp__close_tag varchar2(50) := '</curp>';
        vl_nivelEducativo_tag varchar2(50) :='<nivelEducativo>';
        vl_nivelEducativo_close_tag varchar2(50) :='</nivelEducativo>';
        vl_nombreAlumno_tag varchar2(50):='<nombreAlumno>';
        vl_nombreAlumno_close_tag varchar2(50):='</nombreAlumno>';
        vl_numeroLinea_tag varchar2(50):='<numeroLinea>';
        vl_numeroLinea__close_tag varchar2(100):='</numeroLinea>';
        vl_rfcPago_tag varchar2(50) := '<rfcPago>';
        vl_rfcPago_close_tag varchar2(50) := '</rfcPago>';
        vl_version_tag varchar2(50) := '<version>';
        vl_version__close_tag varchar2(50) := '</version>';

        ----VARIABLES  COMPLEMENTO CONCEPTOS--
        vl_clave_rvoe varchar2(100);
        vl_curp varchar2(100);
        vl_niveleducativo varchar2(100);
        vl_nombrealumno varchar2(100);
        vl_numerolinea Varchar(10):='1';
        vl_rfc varchar2(50);
        vl_version varchar2(10):='1.0';



        -----VARIABLES HTML IMPUESTO RETENIDO---
        vl_totalImpuestosRet_tag varchar2 (100):='<totalImpuestosRetenidos>';
        vl_totalImpuestosRet_close varchar2 (100):='</totalImpuestosRetenidos>';
        vl_totalImpTras_tag varchar2(100):= '<totalImpuestosTrasladados>';
        vl_totalImpTras_close varchar2(100):= '</totalImpuestosTrasladados>';
        vl_totalImpuestosTrasladados varchar2(100);
        vl_totalImpuestosRetenidos varchar2(10):= '0.0';


        vl_tipo_operacion_tag varchar2(100):='<tipoOperacion>';
        vl_tipo_operacion_close_tag varchar2(100):='</tipoOperacion>';
        vl_tipo_operacion varchar2(100); --:='sincrono';
        --vl_tipo_operacion_asincrono varchar2(30):='asincrono'; --solo para pruEbas--

       vl_cierre varchar2(70):='</comprobante>'
          ||'</neon:emitirWS>'
          ||'</soap:Body>'
          ||'</soap:Envelope>';


        -- VAIABLE CON EL IMPUESTO RETENIDO --
        vl_total_impret number(24,6):=0;
        ---------------------------------------

        -- VAIABLE CON EL IMPUESTO TRASLADADOS --
        vl_total_imptras number(24,6):=0;
        ---------------------------------------


        vl_error varchar2(2500); --variable para el control de exdepciones


        vl_iva varchar2(10);
        vn_iva number:=0;

        vl_pago_total_faltante number :=0;
        vl_forma_pago varchar2(100);


        vl_secuencia number:=0;

        ----------------------

        vl_concepto clob;
        vl_concepto_balance clob;
        vl_concepto_1 varchar2(300);
        vl_traslado varchar2(300);
        vl_insteducativas varchar2(500);
        vl_impuestos varchar2(300);
        vl_traslado_1 varchar2(300);
        vl_tipooperacion varchar2(300);

        vl_open_tag varchar(4):= '<';
        vl_close_tag varchar(4):= '/>';

        vl_abre varchar2(100);
        vl_xml_final clob;
        vl_xml_final_1 clob;
        vl_xml_insert clob;

        vl_pidm number;
        vl_pidm_gen number;
        vl_matricula varchar2(10);
        vl_nivel varchar2(50);
        vl_nivel_code varchar2(50);
        vl_campus Varchar2(20);
        vl_referencia varchar2(50);
        vl_serie varchar2(10);
        vl_tipo_archivo varchar2(50):='XML';
        vl_tipo_fact varchar2(50):='Con_D_facturacion';
        --vl_total number(16,2);
        vl_transaccion number :=0;
        vl_out CLOB;

        vl_seq_no NUMBER:=0;
        vl_chg_tran_numb NUMBER:= 0;
        vl_suma_contracargo NUMBER:=0;
        vl_valida_conc NUMBER:=0;
        vl_valida_total_balance NUMBER:=0;
        vl_bandera number:= Null;

        ---VARIABLE PARA EL DOCUMENTO DE IDENTIDAD PARA EXTRAJEROS---
        vl_dni Varchar2(30);




 -----------------------------VARIABLES PATA NT----------------------------

 --------------------------------------------------------------------------


 ---------------VARIABLES CONTENEDORAS------------------
         vl_cabecero_cont varchar2(500);
         vl_cabecero_close varchar2(500);
         vl_datos_factura_cont varchar2(5000);
         vl_conceptos_cont varchar2(5000);
         vl_impuestos_tras_cont varchar2(500);

         -------------------------------------------------------
         -------------------CABECERO XML------------------------
         vl_xml_version varchar2(50):='<?xml version="1.0" encoding="UTF-8"?>';---Se elimina para facto 4
         vl_soap_op varchar2(30):= '<soapenv:Envelope';
         vl_soap_close varchar2(30) :='</soapenv:Envelope>';
         vl_xmlns_tag varchar(30):= ' xmlns:soapenv=';
         vl_xmlns_sopa_value Varchar2(150):= '"http://schemas.xmlsoap.org/soap/envelope/"';
         --vl_xmlns_ejb_tag Varchar2(30):=' xmlns:ejb=';
         vl_xmlns_ejb_tag Varchar2(30):='';
        -- vl_xmlns_ejb_value Varchar2(150):= '"http://ejb.endpoint.hospitality.nexttech.mx.com/">';--se alimina para facto
         vl_xmlns_ejb_value Varchar2(150):= ' xmlns:end="http://endpoint.nexttech.com/">';--se agrega para facto 4
         vl_soap_header varchar2(30):='<soapenv:Header />';
         vl_soap_body varchar2(30):= '<soapenv:Body>';
         vl_soap_body_close varchar2(30):='</soapenv:Body>';
         vl_ejb varchar2(30):='<end:generarCFDI>';   --'<ejb:generarCfdi>';
         vl_ejb_close varchar2(30):='</end:generarCFDI>'; --'</ejb:generarCfdi>';
         vl_apikey varchar2(30):='<apikey />'; --Se elimina nodo el timbrado actual no recibirá este nodo para facto 4.0 Caty
         vl_request_op varchar2(30):= '<request>';
         vl_request_close varchar2(30):='</request>';
         vl_cfdi_op varchar2(30):='<cfdi>';
         vl_cfdi_close varchar2(30):='</cfdi>';

         ----para facto 4.0

       /*  <soapenv:Envelope
            xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
            xmlns:end="http://endpoint.nexttech.com/">
            <soapenv:Header/>
            <soapenv:Body>
                <end:generarCFDI>
            <request>*/

         -------------------------------------------------------
         --------------DATOS DE LA FACTURA----------------------

         vl_serie_op varchar2(30):='<serie>';
         vl_serie_close varchar2(30):='</serie>';
         vl_folio varchar2(30):='<folio>';
         vl_folio_close varchar2(30):='</folio>';
         vl_fecha varchar2(30):='<fecha>';
         vl_fecha_close varchar2(30):='</fecha>';
         vl_exportacion_op varchar2(30):='<exportacion>';  ---Agregado para facto 4.0 Caty
         vl_exportacion_close varchar2(30):='</exportacion>'; ---Agregado para facto 4.0 Caty
         vl_forma_pago_op varchar2(30):='<formaPago>';
         vl_forma_pago_close varchar2(30):='</formaPago>';
         vl_monto varchar2(30):='<monto>';
         vl_monto_close varchar2(30):='</monto>';
         vl_condPago varchar2(30):='<condicionesDePago>';
         vl_condPago_close varchar2(30):='</condicionesDePago>';
         vl_gran_total varchar2(30):='<granTotal>';
         vl_gran_total_close varchar2(30):='</granTotal>';
         vl_total varchar2(30):='<total>';
         vl_total_close varchar2(30):='</total>';
         vl_subtotal_op varchar2(30):='<subTotal>';
         vl_subtotal_close varchar2(30):='</subTotal>';
         vl_descuento_op varchar2(50):='<descuento>';
         vl_descuento_close varchar2(30):='</descuento>';
         vl_moneda varchar2(30):='<moneda>';
         vl_moneda_close varchar2(30):='</moneda>';
         vl_tipo_cambio_op varchar2(20):= '<tipoCambio>';
         vl_tipo_cambio_close varchar2(20):= '</tipoCambio>';
         vl_lugar_exp_op varchar(30):='<lugarExpedicion>';--facto 4.0
         vl_lugar_exp_close varchar(30):='</lugarExpedicion>';--facto 4.0
         vl_tipocfdi varchar2(30):='<tipoCfdi>';
         vl_tipocfdi_close varchar2(30):='</tipoCfdi>';
         vl_metodo_pago_op varchar2(30):= '<metodoPago>';
         vl_metodo_pago_close varchar2(30):='</metodoPago>';
         vl_emisor_op varchar2(30):= '<emisor>';
         vl_emisor_close varchar2(30):='</emisor>';
         vl_rfc_op varchar2(30):='<rfc>';
         vl_rfc_close varchar2(30):='</rfc>';
         vl_cp_emisor_op varchar2(20):='<codigoPostal>';--facto 4.0
         vl_cp_emisor_close varchar2(20):='</codigoPostal>';--facto 4.0
         vl_nombre_emisor_op varchar2(10):='<nombre>';--facto 4.0
         vl_nombre_emisor_close varchar2(50):='</nombre>';--facto 4.0
         vl_reg_fiscal_op varchar2(20):='<regimenFiscal>';--facto 4.0
         vl_reg_fiscal_close varchar2(20):='</regimenFiscal>';--facto 4.0
         vl_receptor_op varchar2(30):='<receptor>';
         vl_receptor_close varchar2(30):='</receptor>';



         vl_email varchar(30):= '<email>';
         vl_email_close varchar(30):= '</email>';
         vl_nombre varchar(30):= '<nombre>';
         vl_nombre_close varchar(30):= '</nombre>';
         vl_identificador varchar(30):= '<identificador>';
         vl_identificador_close varchar(30):= '</identificador>';
         vl_noExt varchar(30):= '<noExterior>';
         vl_noEx_close varchar(30):= '</noExterior>';
         vl_calle_op varchar(30):= '<calle>';
         vl_calle_close varchar(30):='</calle>';
         vl_noInt varchar(50):= '<noInterior>';
         vl_noInt_close varchar(30):='</noInterior>';
         vl_col_op varchar(30):= '<colonia>';
         vl_col_close varchar(30):= '</colonia>';
         vl_mcpo_op varchar(30):= '<municipio>';
         vl_mcpo_close varchar(30):= '</municipio>';
         vl_edo_op varchar(30):= '<estado>';
         vl_edo_close varchar(30):= '</estado>';
         vl_pais_op varchar(30):= '<pais>';
         vl_pais_close varchar(30):= '</pais>';
         vl_cp_op varchar(30):= '<codigoPostal>';--se elimina para facto 4
         vl_cp_close varchar(30):= '</codigoPostal>';--se elimina para facto 4
         vl_numregtri varchar(30):= '<numRegIdTrib />';
         vl_resifis_op varchar(30):= '<residenciaFiscal>';
         vl_resifis_close varchar(30):= '</residenciaFiscal>';
         vl_rfc_recp_op varchar(30):= '<rfc>';
         vl_rfc_recp_close varchar(30):= '</rfc>';
         vl_usocfdi_op varchar(30):= '<usoCFDI>';
         vl_usocfdi_close varchar(30):= '</usoCFDI>';
         vl_dom_fiscal_op varchar2(30):='<domicilioFiscal>';
         vl_dom_fiscal_close varchar2(30):='</domicilioFiscal>';

         vl_conceptos varchar2(30):='<conceptos>';
         vl_conceptos_close varchar2(30):='</conceptos>';
         vl_cantidad varchar2(30):= '<cantidad>';
         vl_cantidad_close varchar2(30):= '</cantidad>';
         vl_cve_prod_ser varchar2(30):= '<claveProdServ>';
         vl_cve_prod_ser_close varchar2(30):= '</claveProdServ>';
         vl_cve_unidad varchar2(30):= '<claveUnidad>';
         vl_cve_unidad_close varchar2(30):= '</claveUnidad>';
         vl_desc varchar2(30):= '<descripcion>';
         vl_desc_close varchar2(30):= '</descripcion>';
         vl_deto varchar2(30):= '<descuento>';
         vl_deto_close varchar2(30):= '</descuento>';
         vl_vlor_uni varchar2(30):= '<valorUnitario>';
         vl_vlor_uni_close varchar2(30):= '</valorUnitario>';
         vl_importe_op varchar2(30):= '<importe>';
         vl_importe_close varchar2(30):= '</importe>';
         vl_unidad varchar2(30):= '<unidad>';
         vl_unidad_close varchar2(30):= '</unidad>';
         vl_impuestos_op varchar2(30):= '<impuestos>';
         vl_impuestos_close varchar2(30):= '</impuestos>';
         vl_trslds varchar2(30):= '<traslados>';
         vl_trslds_close varchar2(30):= '</traslados>';
         vl_trldo_op varchar2(30):= '<traslado>';
         vl_trldo_close varchar2(30):= '</traslado>';
         vl_base_op varchar2(30):= '<base>';
         vl_base_close varchar2(30):= '</base>';
         vl_importe_tras_op varchar2(30):= '<importe>';
         vl_importe_tras_close varchar2(30):= '</importe>';
         vl_impuesto_op varchar2(30):= '<impuesto>';
         vl_impuesto_close varchar2(30):= '</impuesto>';
         vl_tasa_cta_op varchar2(30):= '<tasaoCuota>';
         vl_tasa_cta_close varchar2(30):= '</tasaoCuota>';
         vl_tipo_fctr_op varchar2(30):= '<tipoFactor>';
         vl_tipo_fctr_close varchar2(30):= '</tipoFactor>';
         vl_noIden varchar2(30):='<noIdentificacion>';
         vl_noIden_close varchar2(30) :='</noIdentificacion>';
         vl_objeto_imp_op varchar2(20):='<objetoImp>';
         vl_objeto_imp_close varchar2(20):='</objetoImp>';

         vl_tot_impuestos_ret varchar2(30):= '<totalImpuestosRetenidos>';
         vl_tot_impuestos_ret_close varchar2(30):= '</totalImpuestosRetenidos>';
         vl_tot_impuestos_tras varchar2(30):= '<totalImpuestosTrasladados>';
         vl_tot_impuestos_tras_close varchar2(30):= '</totalImpuestosTrasladados>';
         vl_traslado_op varchar2(30):= '<traslado>';
         vl_traslado_close varchar2(30):= '</traslado>';
         vl_tasa_cuota varchar2(30):= '<tasaoCuota>';
         vl_tasa_cuota_close varchar2(30):= '</tasaoCuota>';
         vl_tipo_factor varchar2(30):= '<tipoFactor>';
         vl_tipo_factor_close varchar2(30):= '</tipoFactor>';

        vl_inf_ad_op varchar2(50):= '<informacionAdicional>';
        vl_inf_ad_close varchar2(50):= '</informacionAdicional>';
        vl_dat_ad_op varchar2(50):='<datosAdicionales>';
        vl_dat_ad_close varchar2(50):='</datosAdicionales>';
        vl_entry_op varchar2(10):= '<entry>';
        vl_entry_close varchar2(10):= '</entry>';
        vl_key_op varchar2(10):= '<key>';
        vl_key_close varchar2(10):= '</key>';
        vl_value_op varchar2(10):=  '<value>';
        vl_value_close varchar2(10):=  '</value>';
        vl_info_facto_op varchar2(50):='<informacionFacto>';
        vl_info_facto_close varchar2(50):='</informacionFacto>';
        vl_id_integracion_op varchar2(50):='<identificadorIntegracion>';
        vl_id_integracion_close varchar2(50):='</identificadorIntegracion>';
        vl_id_integracion_value varchar2(50):='SHE-PRD-051021';
        vl_factu_auto_op varchar2(20):='<facturaAutomatica>';
        vl_factu_auto_close varchar2(20):='</facturaAutomatica>';
        vl_folios_facto_op varchar2(20):='<foliosFacto>';
        vl_folios_facto_close varchar2(20):='</foliosFacto>';
        vl_integracion_op varchar2(20):='<integracion>';
        vl_integracion_close varchar2(20):='</integracion>';



       vl_num_ext varchar2(100);
       vl_calle varchar2(200);
       vl_num_int varchar2(100);
       vl_col varchar2(200);
       vl_mncpo varchar2(100);
       vl_edo varchar2(100);
       vl_pais varchar2 (100);
       vl_cp varchar2 (100);


       --variables facto 4.0

       -----Notas
       vl_notas varchar(200);
       vl_notas_op varchar2(10):=  '<notas>';
       vl_notas_close varchar2(10):=  '</notas>';
       vl_idioma_op varchar2(10):=  '<idioma>';
       vl_idioma_close varchar2(10):=  '</idioma>';
       vl_bimestre varchar(30);
       vl_mespago varchar(20);
       vl_desprograma varchar(150);
       mes varchar(50);
       sp number(2);
       vl_idioma varchar2(2);
       vl_idi varchar(100);
       vl_factu_auto varchar2(10):='true';
       vl_folios_facto varchar2(10):='true';
       vl_integracion varchar2(20):='CFDI_SERVICE';
       vl_cfdi_receptor_op varchar2(10):='<usoCFDI>';
       vl_cfdi_receptor_close varchar2(10):='</usoCFDI>';
       vl_cfdi_receptor varchar2(10);
       vl_reg_fiscal varchar2(10);
       vl_total_importe number:=0; --facto 4.0 suma los importes que se le aplica impuestos
       vl_nombre_receptor varchar2(200);
       res_fiscal varchar(200);
       vl_total_importe_exento number:=0; ---Lo usare para sumar los importes exentos y restarselos a el importe total que va en el totaltrasladados
       vl_tasa_cero number :=0; --suma tasa 0
       vl_totalImpuestosTrasladados_balance number:=0;
       vl_balance_sf number:=0;
       vl_concepto_tasa_cero varchar2(500);
       vl_carac_esp number:=0;
       vl_nombre_receptor2 varchar2(200);
       vl_rfc2 varchar(30);
       vl_ObjImp_02_Exento varchar2(2):='NO';
       vl_total_importe_exento_02 number:=0;
       vl_concepto_objImp02 varchar2(1000);

     BEGIN

        /*CURSOR PARA OBTENER LOS DATOS GENERALES,DE PAGO Y ADICIONALES DEL RECEPTOR(ALUMNO)*/
         FOR d_fiscales IN (

         SELECT a.TZTCRTE_PIDM pidm,
                    a.TZTCRTE_ID matricula,
                   UPPER(REPLACE(REPLACE(NVL(REPLACE(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME,'.'), '|', ''),'-',' ')) nombre_alumno,
                    SUBSTR(TZTCRTE_ID,5) id,
                  --  UPPER(REPLACE (a.TZTCRTE_CAMPO1, '&', '&'||'amp;')) nombre,
                    UPPER(a.TZTCRTE_CAMPO1) nombre,
                    UPPER(SUBSTR(a.TZTCRTE_CAMPO2,1,15)) rfc,
                    CASE
                     WHEN LENGTH(a.TZTCRTE_CAMPO2) BETWEEN 10 AND 12 THEN 'G03'
                     WHEN LENGTH(a.TZTCRTE_CAMPO2) <= 9 THEN 'D10'
                     WHEN LENGTH(a.TZTCRTE_CAMPO2) >= 13 THEN 'D10'
                    END tipo_razon,
                    REGEXP_SUBSTR(a.TZTCRTE_CAMPO3, '[^#"]+', 1, 1) calle,
                    NVL(SUBSTR(REGEXP_SUBSTR(a.TZTCRTE_CAMPO3, '#[^#]*'),2), 0) num_ext,
                    NVL (SUBSTR (REGEXP_SUBSTR(UPPER(a.TZTCRTE_CAMPO3), 'INT[^*]*'),1,10),0) num_int,
                    REPLACE (TZTCRTE_CAMPO27,'"',Null) colonia,
                    a.TZTCRTE_CAMPO4 municipio,
                    a.TZTCRTE_CAMPO5 cp,
                    'MME' estado,
                    a.TZTCRTE_CAMPO6 pais,
                    --'oscar.gonzalez@utel.edu.mx' email,
                    --'catalina.almeida@s4learning.com' email,
                   REPLACE(TZTCRTE_CAMPO14,CHR(9),'')email,
                    CASE
                        WHEN a.TZTCRTE_CAMPO13 = 'REFH' THEN 'BH'
                        WHEN a.TZTCRTE_CAMPO13 = 'REFS' THEN 'BS'
                        WHEN a.TZTCRTE_CAMPO13 = 'REFU' THEN 'UI'
                        WHEN a.TZTCRTE_CAMPO13  IS NULL THEN 'NI'
                    END serie,
                    a.TZTCRTE_CAMP campus,
                    a.TZTCRTE_CAMPO12 referencia,
                    a.TZTCRTE_CAMPO13 ref_tipo,
                    STVLEVL_CODE nivel_code,
                    STVLEVL_DESC nivel,
                    NVL(a.TZTCRTE_CAMPO23,'.') curp,
                    a.TZTCRTE_CAMPO24 grado,
                    r.SZTDTEC_NUM_RVOE RVOE_num,
                    NVL(r.SZTDTEC_CLVE_RVOE,'.') RVOE_clave,
                    a.TZTCRTE_CAMPO10 transaccion,
                    TO_CHAR(TZTCRTE_CAMPO9,'fm9999999990.00') monto_pagado,
                    a.TZTCRTE_CAMPO58 balance,
                    a.TZTCRTE_CAMPO16 remanente,
                    SUBSTR(TZTCRTE_CAMPO7,1,2)forma_pago,
                    a.TZTCRTE_CAMPO7 metodo_pago_code,
                    a.TZTCRTE_CAMPO8 metodo_pago,
                    --'2021-10-03T22:00:00' fecha_pago,
                    a.TZTCRTE_CAMPO11 fecha_pago,
                    a.TZTCRTE_CAMPO28 id_pago,
                    a.TZTCRTE_CAMPO26 programa, ---Agregado para facto 4.0
                (SELECT distinct LISTAGG(TZTCRTE_CAMPO19, ', ') WITHIN GROUP (ORDER BY TZTCRTE_CAMPO19) over (partition by TZTCRTE_CAMPO10) LISTA_NOMBRES
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') tipo_accesorio ,
                (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO20,0)),'fm9999999990.00')
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_accesorio ,
                    a.TZTCRTE_CAMPO15 colegiaturas,
                 (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO16,0)),'fm9999999990.00')
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_colegiatura ,
                    a.TZTCRTE_CAMPO17 as intereses,
                  (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO18,0)),'fm9999999990.00')
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    AND TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    AND TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_interes ,
                    TZTCRTE_CAMPO57 secuencia,
                    ( select SZVCAMP_TRANS_CODE from SZVCAMP WHERE SZVCAMP_CAMP_CODE=a.TZTCRTE_CAMP )idioma, --agregado para facto 4, para saber si es factura en ingles
                    TZTCRTE_REG_FISCAL reg_fiscal,
                    TZTCRTE_CFDI cfdi
                    FROM TZTCRNT a, SPRIDEN, STVLEVL,SZTDTEC r
                    WHERE 1=1
                    AND a.TZTCRTE_PIDM = SPRIDEN_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                    AND a.TZTCRTE_LEVL = STVLEVL_CODE
                    AND a.TZTCRTE_CAMPO26 = r.SZTDTEC_PROGRAM
                    AND a.TZTCRTE_CAMP = r.SZTDTEC_CAMP_CODE
                    AND r.SZTDTEC_TERM_CODE = (SELECT MAX (r1.SZTDTEC_TERM_CODE)
                                               FROM SZTDTEC r1
                                               WHERE  r1.SZTDTEC_PROGRAM = r.SZTDTEC_PROGRAM
                                               AND r1.SZTDTEC_CAMP_CODE = r.SZTDTEC_CAMP_CODE)
                    AND a.TZTCRTE_CAMPO10 NOT IN(SELECT TZTFACT_TRAN_NUMBER --NOT
                                                FROM TZTFCTU
                                                WHERE TZTFACT_PIDM = a.TZTCRTE_PIDM
                                                AND TZTFACT_TRAN_NUMBER = a.TZTCRTE_CAMPO10)
                    AND TZTCRTE_CAMPO57 = (SELECT MAX(b.TZTCRTE_CAMPO57)
                                          FROM TZTCRNT b
                                          WHERE 1=1
                                          AND b.TZTCRTE_PIDM = a.TZTCRTE_PIDM
                                          AND b.TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                                          AND b.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia')
               --      AND TZTCRTE_PIDM in (fget_pidm('010601937'))--,('480000251'),fget_pidm('010629101'))--(fget_pidm('010629101'),fget_pidm('010441882'),fget_pidm('290567738'),fget_pidm('480000251'),fget_pidm('010483277'))
                 -- AND TZTCRTE_PIDM in ( fget_pidm('010045700'),fget_pidm('010441882'),fget_pidm('400584926'),fget_pidm('290567738'),fget_pidm('010500991'),fget_pidm('100592132'),fget_pidm('320302382'))  
               --   AND TZTCRTE_PIDM in ( fget_pidm('010584787'),fget_pidm('010046117'),fget_pidm('010580783'),fget_pidm('010045373'),fget_pidm('010041737'),fget_pidm('010585288'))
                    --AND TZTCRTE_CAMPO10 = 44
                    --AND SUBSTR (TZTCRTE_CAMPO11, 3,5) = '21-10'
                    --AND TZTCRTE_CAMPO60 = '15/08/21' --BETWEEN '01/08/21' AND '20/08/21'
                    AND TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                    AND TZTCRTE_CAMPO2 IS NOT Null
                    AND SPRIDEN_PIDM IN (SELECT SARADAP_PIDM FROM saradap)
                    GROUP BY TZTCRTE_PIDM,TZTCRTE_ID,SPRIDEN_LAST_NAME,SPRIDEN_FIRST_NAME,TZTCRTE_CAMPO1,TZTCRTE_CAMPO2,TZTCRTE_CAMPO3,TZTCRTE_CAMPO27,TZTCRTE_CAMPO4,TZTCRTE_CAMPO5,TZTCRTE_CAMPO6,TZTCRTE_CAMPO14,
                             TZTCRTE_CAMPO20,TZTCRTE_CAMPO15,TZTCRTE_CAMPO13, TZTCRTE_CAMP, TZTCRTE_CAMPO12, TZTCRTE_CAMPO13, STVLEVL_CODE,STVLEVL_DESC,TZTCRTE_CAMPO23,TZTCRTE_CAMPO24,SZTDTEC_NUM_RVOE,SZTDTEC_CLVE_RVOE,TZTCRTE_CAMPO10,
                             TZTCRTE_CAMPO9,TZTCRTE_CAMPO7,TZTCRTE_CAMPO8,TZTCRTE_CAMPO11,TZTCRTE_CAMPO19,TZTCRTE_CAMPO16, TZTCRTE_CAMPO17,TZTCRTE_CAMPO18, TZTCRTE_CAMPO28,TZTCRTE_CAMPO26, TZTCRTE_CAMPO58, TZTCRTE_CAMPO57,
                             a.TZTCRTE_TIPO_REPORTE, TZTCRTE_REG_FISCAL,TZTCRTE_CFDI
           UNION
                    SELECT a.TZTCRTE_PIDM pidm,
                    a.TZTCRTE_ID matricula,
                    UPPER(REPLACE(REPLACE(NVL(REPLACE(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME,'.'), '|', ''),'-',' ')) nombre_alumno,
                    SUBSTR(TZTCRTE_ID,5) id,
                 --   UPPER(REPLACE (a.TZTCRTE_CAMPO1, '&', '&'||'amp;')) nombre,
                    UPPER(a.TZTCRTE_CAMPO1) nombre,
                    UPPER(SUBSTR(a.TZTCRTE_CAMPO2,1,15)) rfc,
                    CASE
                     WHEN LENGTH(a.TZTCRTE_CAMPO2) BETWEEN 10 AND 12 THEN 'G03'
                     WHEN LENGTH(a.TZTCRTE_CAMPO2) <= 9 THEN 'D10'
                     WHEN LENGTH(a.TZTCRTE_CAMPO2) >= 13 THEN 'D10'
                    END tipo_razon,
                    REGEXP_SUBSTR(a.TZTCRTE_CAMPO3, '[^#"]+', 1, 1) calle,
                    NVL(SUBSTR(REGEXP_SUBSTR(a.TZTCRTE_CAMPO3, '#[^#]*'),2), 0) num_ext,
                    NVL (SUBSTR (REGEXP_SUBSTR(UPPER(a.TZTCRTE_CAMPO3), 'INT[^*]*'),1,10),0) num_int,
                    REPLACE (TZTCRTE_CAMPO27,'"',Null) colonia,
                    a.TZTCRTE_CAMPO4 municipio,
                    a.TZTCRTE_CAMPO5 cp,
                    'MME' estado,
                    a.TZTCRTE_CAMPO6 pais,
                    --'oscar.gonzalez@utel.edu.mx' email,
                  --   'catalina.almeida@s4learning.com' email,
                    REPLACE(TZTCRTE_CAMPO14,CHR(9),'')email,
                    CASE
                        WHEN a.TZTCRTE_CAMPO13 = 'REFH' THEN 'BH'
                        WHEN a.TZTCRTE_CAMPO13 = 'REFS' THEN 'BS'
                        WHEN a.TZTCRTE_CAMPO13 = 'REFU' THEN 'UI'
                        WHEN a.TZTCRTE_CAMPO13  IS NULL THEN 'NI'
                    END serie,
                    a.TZTCRTE_CAMP campus,
                    a.TZTCRTE_CAMPO12 referencia,
                    a.TZTCRTE_CAMPO13 ref_tipo,
                    STVLEVL_DESC nivel,
                    STVLEVL_CODE nivel_code,
                    NVL(a.TZTCRTE_CAMPO23,'.') curp,
                    a.TZTCRTE_CAMPO24 grado,
                    Null RVOE_num,
                    Null RVOE_clave,
                    a.TZTCRTE_CAMPO10 transaccion,
                    TO_CHAR(TZTCRTE_CAMPO9,'fm9999999990.00') monto_pagado,
                    a.TZTCRTE_CAMPO58 balance,
                    a.TZTCRTE_CAMPO16 remanente,
                    SUBSTR(TZTCRTE_CAMPO7,1,2)forma_pago,
                    a.TZTCRTE_CAMPO7 metodo_pago_code,
                    a.TZTCRTE_CAMPO8 metodo_pago,
                    --'2021-10-03T22:00:00' fecha_pago,
                    a.TZTCRTE_CAMPO11 fecha_pago,
                    a.TZTCRTE_CAMPO28 id_pago,
                     a.TZTCRTE_CAMPO26 programa, ---Agregado para facto 4.0
                (SELECT distinct LISTAGG(TZTCRTE_CAMPO19, ', ') WITHIN GROUP (ORDER BY TZTCRTE_CAMPO19) over (partition by TZTCRTE_CAMPO10) LISTA_NOMBRES
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') tipo_accesorio ,
                (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO20,0)),'fm9999999990.00')
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_accesorio ,
                    a.TZTCRTE_CAMPO15 colegiaturas,
                    (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO16,0)),'fm9999999990.00')
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_colegiatura ,
                    a.TZTCRTE_CAMPO17 as intereses,
                     (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO18,0)),'fm9999999990.00')
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_interes ,
                    TZTCRTE_CAMPO57 secuencia,
                    SZVCAMP_TRANS_CODE idioma,
                    TZTCRTE_REG_FISCAL reg_fiscal,
                    TZTCRTE_CFDI cfdi
                    FROM TZTCRNT a, SPRIDEN, STVLEVL, SZVCAMP
                    WHERE 1=1
                    AND a.TZTCRTE_PIDM = SPRIDEN_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                    AND a.TZTCRTE_LEVL = STVLEVL_CODE
                    AND a.TZTCRTE_CAMP = SZVCAMP_CAMP_CODE
                    AND a.TZTCRTE_CAMPO10 NOT IN (SELECT TZTFACT_TRAN_NUMBER --NOT
                                          FROM TZTFCTU
                                          WHERE TZTFACT_PIDM = a.TZTCRTE_PIDM
                                          AND TZTFACT_TRAN_NUMBER = a.TZTCRTE_CAMPO10)
                    AND TZTCRTE_CAMPO57 = (SELECT MAX(b.TZTCRTE_CAMPO57)
                                          FROM TZTCRNT b
                                          WHERE 1=1
                                          AND b.TZTCRTE_PIDM = a.TZTCRTE_PIDM
                                          AND b.TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                                          AND b.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia')
              --     AND TZTCRTE_PIDM in (fget_pidm('010601937'))--,('480000251'),fget_pidm('010629101'))--(fget_pidm('010629101'),fget_pidm('010441882'),fget_pidm('290567738'),fget_pidm('480000251'),fget_pidm('010483277'))
                  -- AND TZTCRTE_PIDM in ( fget_pidm('010584787'),fget_pidm('010046117'),fget_pidm('010580783'),fget_pidm('010045373'),fget_pidm('010041737'),fget_pidm('010585288')) 
                  -- AND TZTCRTE_PIDM in (fget_pidm('010045700'),fget_pidm('010441882'),fget_pidm('400584926'),fget_pidm('290567738'),fget_pidm('010500991'),fget_pidm('100592132'),fget_pidm('320302382')) 
                    --AND TZTCRTE_CAMPO10 = 44
                    --AND SUBSTR (TZTCRTE_CAMPO11, 3,5) = '21-10'
                    --AND TZTCRTE_CAMPO60 = '15/08/21' --BETWEEN '01/08/21' AND '20/08/21'
                 --    AND TZTCRTE_PIDM in (fget_pidm('010445016'),fget_pidm('010377477'),fget_pidm('010524358'),fget_pidm('010084938'),fget_pidm('020466138'),fget_pidm('240313812'))
                    AND TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                    AND TZTCRTE_CAMPO2 IS NOT Null
                    AND SPRIDEN_PIDM NOT IN (SELECT SARADAP_PIDM FROM saradap)
                    GROUP BY TZTCRTE_PIDM,TZTCRTE_ID,SPRIDEN_LAST_NAME,SPRIDEN_FIRST_NAME,TZTCRTE_CAMPO1,TZTCRTE_CAMPO2,TZTCRTE_CAMPO3,TZTCRTE_CAMPO27,TZTCRTE_CAMPO4,TZTCRTE_CAMPO5,TZTCRTE_CAMPO6,TZTCRTE_CAMPO14,
                             TZTCRTE_CAMPO20,TZTCRTE_CAMPO15,TZTCRTE_CAMPO13, TZTCRTE_CAMP, TZTCRTE_CAMPO12, TZTCRTE_CAMPO13,STVLEVL_CODE, STVLEVL_DESC,TZTCRTE_CAMPO23,TZTCRTE_CAMPO24,TZTCRTE_CAMPO10,
                             TZTCRTE_CAMPO9,TZTCRTE_CAMPO7,TZTCRTE_CAMPO8,TZTCRTE_CAMPO11,TZTCRTE_CAMPO19,TZTCRTE_CAMPO16, TZTCRTE_CAMPO17,TZTCRTE_CAMPO18, TZTCRTE_CAMPO28,TZTCRTE_CAMPO26, TZTCRTE_CAMPO58, TZTCRTE_CAMPO57,
                             a.TZTCRTE_TIPO_REPORTE,SZVCAMP_TRANS_CODE , TZTCRTE_REG_FISCAL,TZTCRTE_CFDI
             UNION
                   SELECT a.TZTCRTE_PIDM pidm,
                    a.TZTCRTE_ID matricula,
                    UPPER(REPLACE(REPLACE(NVL(REPLACE(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME,'.'), '|', ''),'-',' ')) nombre_alumno,
                    SUBSTR(TZTCRTE_ID,5) id,
                 --   UPPER(REPLACE (a.TZTCRTE_CAMPO1, '&', '&'||'amp;')) nombre,
                    UPPER(a.TZTCRTE_CAMPO1) nombre,
                    UPPER(SUBSTR(a.TZTCRTE_CAMPO2,1,15)) rfc,
                    CASE
                     WHEN LENGTH(a.TZTCRTE_CAMPO2) BETWEEN 10 AND 12 THEN 'G03'
                     WHEN LENGTH(a.TZTCRTE_CAMPO2) <= 9 THEN 'D10'
                     WHEN LENGTH(a.TZTCRTE_CAMPO2) >= 13 THEN 'D10'
                    END tipo_razon,
                    REGEXP_SUBSTR(a.TZTCRTE_CAMPO3, '[^#"]+', 1, 1) calle,
                    NVL(SUBSTR(REGEXP_SUBSTR(a.TZTCRTE_CAMPO3, '#[^#]*'),2), 0) num_ext,
                    NVL (SUBSTR (REGEXP_SUBSTR(UPPER(a.TZTCRTE_CAMPO3), 'INT[^*]*'),1,10),0) num_int,
                    REPLACE (TZTCRTE_CAMPO27,'"',Null) colonia,
                    a.TZTCRTE_CAMPO4 municipio,
                    a.TZTCRTE_CAMPO5 cp,
                    'MME' estado,
                    a.TZTCRTE_CAMPO6 pais,
                    --'oscar.gonzalez@utel.edu.mx' email,
                  --   'catalina.almeida@s4learning.com' email,
                   REPLACE(TZTCRTE_CAMPO14,CHR(9),'')email,
                    CASE
                        WHEN a.TZTCRTE_CAMPO13 = 'REFH' THEN 'BH'
                        WHEN a.TZTCRTE_CAMPO13 = 'REFS' THEN 'BS'
                        WHEN a.TZTCRTE_CAMPO13 = 'REFU' THEN 'UI'
                        WHEN a.TZTCRTE_CAMPO13  IS NULL THEN 'NI'
                    END serie,
                    a.TZTCRTE_CAMP campus,
                    a.TZTCRTE_CAMPO12 referencia,
                    a.TZTCRTE_CAMPO13 ref_tipo,
                    STVLEVL_CODE nivel_code,
                    STVLEVL_DESC nivel,
                    NVL(a.TZTCRTE_CAMPO23,'.') curp,
                    a.TZTCRTE_CAMPO24 grado,
                    Null RVOE_num,
                    Null RVOE_clave,
                    a.TZTCRTE_CAMPO10 transaccion,
                    TO_CHAR(TZTCRTE_CAMPO9,'fm9999999990.00') monto_pagado,
                    a.TZTCRTE_CAMPO58 balance,
                    a.TZTCRTE_CAMPO16 remanente,
                    SUBSTR(TZTCRTE_CAMPO7,1,2)forma_pago,
                    a.TZTCRTE_CAMPO7 metodo_pago_code,
                    a.TZTCRTE_CAMPO8 metodo_pago,
                    --'2021-10-03T22:00:00' fecha_pago,
                    a.TZTCRTE_CAMPO11 fecha_pago,
                    a.TZTCRTE_CAMPO28 id_pago,
                    a.TZTCRTE_CAMPO26 programa, ---Agregado para facto 4.0
                (SELECT distinct LISTAGG(TZTCRTE_CAMPO19, ', ') WITHIN GROUP (ORDER BY TZTCRTE_CAMPO19) over (partition by TZTCRTE_CAMPO10) LISTA_NOMBRES
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') tipo_accesorio ,
                (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO20,0)),'fm9999999990.00')
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_accesorio ,
                    a.TZTCRTE_CAMPO15 colegiaturas,
                    (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO16,0)),'fm9999999990.00')
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_colegiatura ,
                    a.TZTCRTE_CAMPO17 as intereses,
                     (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO18,0)),'fm9999999990.00')
                    FROM TZTCRNT xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_interes ,
                    TZTCRTE_CAMPO57 secuencia,
                    SZVCAMP_TRANS_CODE idioma,
                    TZTCRTE_REG_FISCAL reg_fiscal,
                    TZTCRTE_CFDI cfdi
                    FROM TZTCRNT a, SPRIDEN, STVLEVL, SZVCAMP
                    WHERE 1=1
                    AND a.TZTCRTE_PIDM = SPRIDEN_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                    AND a.TZTCRTE_LEVL = STVLEVL_CODE
                    AND a.TZTCRTE_CAMP = SZVCAMP_CAMP_CODE
                    AND a.TZTCRTE_CAMPO10 NOT IN (SELECT TZTFACT_TRAN_NUMBER --NOT
                                          FROM TZTFCTU
                                          WHERE TZTFACT_PIDM = a.TZTCRTE_PIDM
                                          AND TZTFACT_TRAN_NUMBER = a.TZTCRTE_CAMPO10)
                    AND TZTCRTE_CAMPO57 = (SELECT MAX(b.TZTCRTE_CAMPO57)
                                          FROM TZTCRNT b
                                          WHERE 1=1
                                          AND b.TZTCRTE_PIDM = a.TZTCRTE_PIDM
                                          AND b.TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                                          AND b.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia')
                 --    AND TZTCRTE_PIDM in (fget_pidm('010584787'),fget_pidm('010046117'),fget_pidm('010580783'),fget_pidm('010045373'),fget_pidm('010041737'),fget_pidm('010585288'))
              --   AND TZTCRTE_PIDM in (fget_pidm('010601937'))--,('480000251'),fget_pidm('010629101'))--(fget_pidm('010629101'),fget_pidm('010441882'),fget_pidm('290567738'),fget_pidm('480000251'),fget_pidm('010483277'))
                 -- AND TZTCRTE_PIDM in (fget_pidm('010045700'),fget_pidm('010441882'),fget_pidm('400584926'),fget_pidm('290567738'),fget_pidm('010500991'),fget_pidm('100592132'),fget_pidm('320302382'))  
                    --AND TZTCRTE_CAMPO10 = 44
                    --AND SUBSTR (TZTCRTE_CAMPO11, 3,5) = '21-10'
                    --AND TZTCRTE_CAMPO60 = '15/08/21' --BETWEEN '01/08/21' AND '20/08/21'
                --     AND TZTCRTE_PIDM in (fget_pidm('010445016'),fget_pidm('010377477'),fget_pidm('010524358'),fget_pidm('010084938'),fget_pidm('020466138'),fget_pidm('240313812'))
                    AND SUBSTR (TZTCRTE_ID,3,2) = '99'
                    AND TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                    AND TZTCRTE_CAMPO2 IS NOT Null
                    GROUP BY TZTCRTE_PIDM,TZTCRTE_ID,SPRIDEN_LAST_NAME,SPRIDEN_FIRST_NAME,TZTCRTE_CAMPO1,TZTCRTE_CAMPO2,TZTCRTE_CAMPO3,TZTCRTE_CAMPO27,TZTCRTE_CAMPO4,TZTCRTE_CAMPO5,TZTCRTE_CAMPO6,TZTCRTE_CAMPO14,
                             TZTCRTE_CAMPO20,TZTCRTE_CAMPO15,TZTCRTE_CAMPO13, TZTCRTE_CAMP, TZTCRTE_CAMPO12, TZTCRTE_CAMPO13, STVLEVL_CODE, STVLEVL_DESC,TZTCRTE_CAMPO23,TZTCRTE_CAMPO24,TZTCRTE_CAMPO10,
                             TZTCRTE_CAMPO9,TZTCRTE_CAMPO7,TZTCRTE_CAMPO8,TZTCRTE_CAMPO11,TZTCRTE_CAMPO19,TZTCRTE_CAMPO16, TZTCRTE_CAMPO17,TZTCRTE_CAMPO18, TZTCRTE_CAMPO28,TZTCRTE_CAMPO26, TZTCRTE_CAMPO58, TZTCRTE_CAMPO57,
                             a.TZTCRTE_TIPO_REPORTE,SZVCAMP_TRANS_CODE, TZTCRTE_REG_FISCAL,TZTCRTE_CFDI



                  )


          LOOP
                vl_pidm:= d_fiscales.pidm;
                vl_matricula:= d_fiscales.matricula;
                vl_num_ext:= d_fiscales.num_ext;
                vl_calle:= d_fiscales.calle;
                vl_num_int:= d_fiscales.num_int;
                vl_col:= d_fiscales.colonia;
                vl_mncpo:= d_fiscales.municipio;
                vl_edo := d_fiscales.estado;
                vl_pais := d_fiscales.pais;
                vl_cp := d_fiscales.cp;
                vl_rfc:= d_fiscales.rfc;
                vl_serie:=d_fiscales.serie;
                vl_referencia := d_fiscales.referencia;
                vl_nivel:= d_fiscales.nivel;
                vl_nivel_code := d_fiscales.nivel_code;
                vl_campus:= d_fiscales.campus;
                vl_clave_rvoe:= d_fiscales.RVOE_clave;
                vl_curp:= d_fiscales.curp;
                vl_nombrealumno:= d_fiscales.nombre_alumno;
                vl_fecha_pago := d_fiscales.fecha_pago;
                vl_metodo_pago_code :=d_fiscales.metodo_pago_code;
                vl_pago_metodo_pago := d_fiscales.metodo_pago;
                vl_pago_id_pago := d_fiscales.transaccion; ---id_pago;
                vl_pago_monto_pagado := d_fiscales.monto_pagado;
                vl_pago_fecha_pago := d_fiscales.fecha_pago;
                --vl_pago_monto_interes := d_fiscales.monto_interes;
                vl_pago_tipo_accesorio := d_fiscales.tipo_accesorio;
                --vl_pago_monto_accesorio := d_fiscales.monto_accesorio;
                vl_pago_colegiaturas := d_fiscales.colegiaturas;
                --vl_pago_monto_colegiatura := d_fiscales.monto_colegiatura;
                vl_pago_intereses := d_fiscales.intereses;
                vl_transaccion := d_fiscales.transaccion;
                vl_uso_cfdi:= d_fiscales.tipo_razon;
                vl_balance := d_fiscales.balance;
                vl_remanente:= d_fiscales.remanente;
                vl_idTipoReceptor:=d_fiscales.id;
                vl_correoR := d_fiscales.email;
                vl_cfdi_receptor:=d_fiscales.cfdi;
                vl_reg_fiscal:=d_fiscales.reg_fiscal;
                vl_total_importe_exento:=0;
                vl_tasa_cero:=0;
                vl_totalImpuestosTrasladados_balance:=0;
                vl_balance_sf:=0;
                vl_nombre_receptor2:='';
                vl_concepto_tasa_cero:='';
                vl_balance_1:=0;
                vl_idi:='';
                vl_rfc2:='';
                vl_ObjImp_02_Exento:='NO';
                vl_total_importe_exento_02:=0;
                vl_concepto_objImp02:='';

           --     DBMS_OUTPUT.PUT_LINE(' pidm '||vl_pidm||' matricula ' ||vl_matricula);


                ---Agregado para facto 4.0 Caty
                if d_fiscales.nombre is null then

                            vl_nombre_receptor:=d_fiscales.nombre_alumno;
                        else
                            vl_nombre_receptor:=d_fiscales.nombre;

                end if;

                begin
                    select
                        Translate(vl_nombre_receptor,'Áá�?éÍí�?ó�?ú','AaEeIiOoUu')
                         into vl_nombre_receptor
                    from Dual;
                end;

                begin

                    SELECT INSTR(vl_nombre_receptor,'&') into vl_carac_esp from dual;

                end;
                if vl_carac_esp > 0 then
                    vl_nombre_receptor:='<![CDATA['||vl_nombre_receptor||']]>';
                    vl_nombre_receptor2:= vl_nombre_receptor;
                    /* begin
                            select
                                replace(d_fiscales.nombre,'&',';')
                                 into vl_nombre_receptor2
                            from Dual;
                    end;*/
                 else
                    vl_nombre_receptor2:=d_fiscales.nombre;

                end if;
                
                
                begin

                    SELECT INSTR(vl_rfc,'&') into vl_carac_esp from dual;

                end;
                if vl_carac_esp > 0 then
                    vl_rfc:='<![CDATA['||vl_rfc||']]>';
                    vl_rfc2:= d_fiscales.rfc;
                  
                 else
                    vl_rfc2:= d_fiscales.rfc;

                end if;
                
              --  DBMS_OUTPUT.PUT_LINE(vl_rfc);

                begin
                    select
                        Translate(vl_nombrealumno,'Áá�?éÍí�?ó�?ú','AaEeIiOoUu')
                         into vl_nombrealumno
                    from Dual;
                end;


                vl_idioma:=d_fiscales.idioma;

             -- obtiene el dato para el nodo residenciaFiscal
             --- pasar a funcion de bd al paquete utilerias
             BEGIN
                 select
                   zstpara_param_id
                 into vl_residencia_fiscal
                from
                    ZSTPARA
                where
                    zstpara_mapa_id='COD_FACTURACION' and
                    zstpara_param_valor=vl_pais;

                 EXCEPTION WHEN OTHERS THEN
                       vl_residencia_fiscal:='MEX';
             END;


              --DBMS_OUTPUT.PUT_LINE(vl_pais)

                vl_DesPrograma:=pkg_utilerias.f_programa_desc (d_fiscales.programa);

             --    DBMS_OUTPUT.PUT_LINE(' calle: '||vl_calle||' col: '||vl_col);
                 begin
                    select
                        Translate(vl_DesPrograma,'Áá�?éÍí�?ó�?ú','AaEeIiOoUu'),  Translate(vl_calle,'Áá�?éÍí�?ó�?ú','AaEeIiOoUu'), Translate(vl_col,'Áá�?éÍí�?ó�?ú','AaEeIiOoUu')
                         into vl_DesPrograma, vl_calle, vl_col
                    from Dual;
                end;

               -- DBMS_OUTPUT.PUT_LINE('pidm:'||d_fiscales.pidm||' programa '||d_fiscales.programa||' nivel '||d_fiscales.nivel||' campus '||d_fiscales.campus );
               ---Obtiene mes en español facto 4.0

               BEGIN
                select
                    to_char(to_date(substr(d_fiscales.fecha_pago,1,10),'YYYY/MM/DD'), 'Month','nls_date_language=spanish')
                INTO mes
                from
                    dual;
               END;
                vl_mespago:=mes;

                BEGIN
                  select  sp
                   into sp
                    from tztprog t1
                    where 1=1
                    and t1.pidm = d_fiscales.pidm
                    and t1.programa  = d_fiscales.programa;

                    EXCEPTION WHEN OTHERS THEN
                       vl_Bimestre:='N/A';
                       sp:=null;
                END;


                if sp is not null then
                    begin
                        vl_Bimestre:= pkg_utilerias.f_calcula_bimestres(d_fiscales.pidm,sp);
                    end;
                end if;

                if vl_Bimestre is null then
                 begin
                        vl_Bimestre:= 'N/A';
                    end;
                end if;
                
                --Se agrega para facturas con conceptos exentos con objimp 04,y solicitan el cambio objimp 02 exento
                  begin
                           select distinct ss.SPREMRG_PHONE_AREA,ss.SPREMRG_PHONE_NUMBER
                           into vl_objetoImp,vl_tipo_factor_impuesto
                           from spremrg ss
                           where
                                ss.spremrg_pidm=d_fiscales.pidm
                            and   ss.SPREMRG_PRIORITY = (select MAX(s1.SPREMRG_PRIORITY)
                                                          FROM SPREMRG s1
                                                          where ss.SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                        );
                                                        
                           EXCEPTION WHEN OTHERS THEN
                            vl_ObjImp_02_Exento:='NO';
                            vl_objetoImp:='04';
                            vl_tipo_factor_impuesto:='Exento';
                           END;
                            -- si cumple esta condicion debe agregar al xml el nodo de total de impuestos trasladados
                           if vl_objetoImp = '02' and vl_tipo_factor_impuesto = 'Exento' then
                                vl_ObjImp_02_Exento:='SI';
                                                           
                           end if;

               --  DBMS_OUTPUT.PUT_LINE('vl_objetoImp '||vl_objetoImp||' vl_tipo_factor_impuesto '||vl_tipo_factor_impuesto||' vl_ObjImp_02_Exento '||vl_ObjImp_02_Exento);
                
                --------------

                IF
                vl_pago_monto_pagado LIKE '-%' THEN vl_pago_monto_pagado := vl_pago_monto_pagado *(-1);
                END IF;

                vl_enviar:= Null;

                IF vl_rfc = 'XAXX010101000' THEN

                    BEGIN

                     vl_pidm_gen:='5133';
                     vl_uso_cfdi:= 'S01';
                     vl_idTipoReceptor:='1';
                     vl_reg_fiscal:='616';--Agregado facto 4.0
                     vl_cp:=vl_cp_emisor;

                       IF vl_correoR IS NULL THEN
                           BEGIN
                            SELECT ZSTPARA_PARAM_VALOR
                            INTO vl_correoR
                            FROM ZSTPARA
                            WHERE 1=1
                            AND ZSTPARA_MAPA_ID = 'FA_SEND_EMAIL';
                            EXCEPTION WHEN OTHERS THEN
                            vl_correoR:='.';
                           END;
                        END IF;


                       BEGIN
                        SELECT ZSTPARA_PARAM_VALOR
                        INTO vl_tipo_operacion
                        FROM ZSTPARA
                        WHERE 1=1
                        AND ZSTPARA_MAPA_ID = 'FA_OP_TYPE';
                       EXCEPTION WHEN OTHERS THEN
                       vl_tipo_operacion:='sincrono';
                       END;

                       BEGIN
                        SELECT ZSTPARA_PARAM_VALOR
                        INTO vl_enviar
                        FROM ZSTPARA
                        WHERE 1=1
                        AND ZSTPARA_MAPA_ID = 'FA_SEND_TYPE';
                        EXCEPTION WHEN OTHERS THEN
                        vl_enviar:='1';
                       END;


                    END;

                ELSE

                     vl_pidm_gen:=vl_pidm;
                     vl_idTipoReceptor:=vl_idTipoReceptor;
                     vl_correoR:=vl_correoR;
                     vl_uso_cfdi:=vl_uso_cfdi;
                     vl_tipo_operacion:= 'sincrono';
                     vl_enviar:=1;


                END IF;

               vl_suma_contracargo:= Null;
               BEGIN
                SELECT NVL(SUM(TZTCRTE_CAMPO15),0)
                INTO vl_suma_contracargo
                FROM TZTCRNT
                WHERE 1=1
                AND TZTCRTE_CAMPO18 = 'APF'
                AND TZTCRTE_PIDM = vl_pidm
                AND TZTCRTE_CAMPO10 = vl_transaccion;
                EXCEPTION WHEN OTHERS THEN
                vl_suma_contracargo:=0;
               END;


                vl_subtotal := Null;
                BEGIN
                SELECT NVL(SUM(TZTCONC_SUBTOTAL),vl_pago_total)
                INTO vl_subtotal
                FROM TZTCONT
                WHERE 1=1
                AND TZTCONC_PIDM = vl_pidm
                AND TZTCONC_TRAN_NUMBER = vl_transaccion;
                EXCEPTION WHEN NO_DATA_FOUND THEN
                vl_subtotal:= 0;
                END;


            -- se restan los contracargos--

               IF vl_suma_contracargo > 0 then
               vl_pago_total := vl_pago_monto_pagado - vl_suma_contracargo;
               vl_pago_monto_pagado := vl_pago_monto_pagado - vl_suma_contracargo;
               vl_subtotal:= vl_subtotal-vl_suma_contracargo;
               ELSE
               vl_pago_total := vl_pago_monto_pagado;
               vl_pago_monto_pagado := vl_pago_monto_pagado;
               vl_subtotal:= vl_subtotal;
               END IF;


               vl_pago_monto_colegiatura:= Null;
               vl_pago_monto_interes := Null;

                  IF vl_serie = 'BS' THEN

                    BEGIN
                    SELECT CASE
                        WHEN TZTCON_MONEDA <> 'CLP' THEN
                        TO_CHAR(SUM(TZTCONC_SUBTOTAL),'fm9999999990.00')
                        WHEN TZTCON_MONEDA = 'CLP' THEN
                        TO_CHAR(SUM(TZTCONC_SUBTOTAL))
                     END
                    INTO vl_pago_monto_colegiatura
                    FROM TZTCONT
                    WHERE 1=1
                    AND TZTCONC_PIDM = vl_pidm
                    AND TZTCONC_TRAN_NUMBER = vl_transaccion
                    AND TZTCONC_DCAT_CODE = 'COL'
                    GROUP BY TZTCON_MONEDA;
                    EXCEPTION WHEN OTHERS THEN
                    Null;
                    END;

                    BEGIN

                    SELECT CASE
                        WHEN TZTCON_MONEDA <> 'CLP' THEN
                        TO_CHAR(SUM(TZTCONC_MONTO)/1.16,'fm9999999990.00')
                        WHEN TZTCON_MONEDA = 'CLP' THEN
                        TO_CHAR(SUM(TZTCONC_MONTO)/1.16)
                    END
                    INTO vl_pago_monto_interes
                    FROM TZTCONT
                    WHERE 1=1
                    AND TZTCONC_PIDM = vl_pidm
                    AND TZTCONC_TRAN_NUMBER = vl_transaccion
                    AND TZTCONC_DCAT_CODE = 'INT'
                    GROUP BY TZTCON_MONEDA;
                    EXCEPTION WHEN OTHERS THEN
                    Null;
                    END;

                  ELSE


                    BEGIN
                    SELECT CASE
                        WHEN TZTCON_MONEDA <> 'CLP' THEN
                        TO_CHAR(SUM(TZTCONC_MONTO),'fm9999999990.00')
                        WHEN TZTCON_MONEDA = 'CLP' THEN
                        TO_CHAR(SUM(TZTCONC_MONTO))
                     END
                    INTO vl_pago_monto_colegiatura
                    FROM TZTCONT
                    WHERE 1=1
                    AND TZTCONC_PIDM = vl_pidm
                    AND TZTCONC_TRAN_NUMBER = vl_transaccion
                    AND TZTCONC_DCAT_CODE = 'COL'
                    GROUP BY TZTCON_MONEDA;
                    EXCEPTION WHEN OTHERS THEN
                    Null;
                    END;


                    BEGIN

                    SELECT CASE
                        WHEN TZTCON_MONEDA <> 'CLP' THEN
                        TO_CHAR(SUM(TZTCONC_MONTO),'fm9999999990.00')
                        WHEN TZTCON_MONEDA = 'CLP' THEN
                        TO_CHAR(SUM(TZTCONC_MONTO))
                    END
                    INTO vl_pago_monto_interes
                    FROM TZTCONT
                    WHERE 1=1
                    AND TZTCONC_PIDM = vl_pidm
                    AND TZTCONC_TRAN_NUMBER = vl_transaccion
                    AND TZTCONC_DCAT_CODE = 'INT'
                    GROUP BY TZTCON_MONEDA;
                    EXCEPTION WHEN OTHERS THEN
                    Null;
                    END;


                  END IF;

               --DBMS_OUTPUT.PUT_LINE('SERIE : '||vl_serie);

                vl_chg_tran_numb := Null;
                BEGIN
                SELECT COUNT(TBRAPPL_CHG_TRAN_NUMBER)
                INTO vl_chg_tran_numb
                FROM TBRAPPL
                WHERE 1=1
                AND TBRAPPL_PIDM = vl_pidm
                AND TBRAPPL_PAY_TRAN_NUMBER = vl_transaccion;
                EXCEPTION WHEN OTHERS THEN
                vl_chg_tran_numb:= 0;

                END;

                vl_cuenta_registro:= null;
                vl_cuenta_registro1:= null;
                vl_estatus_registro := null;

                BEGIN

                SELECT COUNT(0)
                INTO vl_cuenta_registro
                FROM TZTFCTU
                WHERE 1=1
                AND TZTFACT_PIDM = vl_pidm
                AND TZTFACT_TIPO_DOCTO = 'FA'
                AND TZTFACT_RESPUESTA = 1;
                EXCEPTION
                WHEN OTHERS THEN
                vl_cuenta_registro:= 0;
                END;


                BEGIN
                   SELECT count(0)
                   INTO vl_cuenta_registro1
                   FROM TZTCRNT
                   WHERE 1=1
                   AND TZTCRTE_PIDM = vl_pidm
                   AND TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                   AND TZTCRTE_CAMPO2 ='XAXX010101000';

                END;

                IF vl_cuenta_registro = 0 THEN

                    vl_estatus_registro := '1';

                ELSIF vl_cuenta_registro >= 1 AND vl_cuenta_registro1 >= 1 THEN

                    vl_estatus_registro := '1';

                ELSIF vl_cuenta_registro >= 1 AND vl_cuenta_registro1 = 0 THEN

                    vl_estatus_registro := '2';

                END IF;


               /*
               DBMS_OUTPUT.PUT_LINE('Balance:'||vl_balance);
               DBMS_OUTPUT.PUT_LINE('Subtotal:'||vl_subtotal);
               DBMS_OUTPUT.PUT_LINE('Pago Total:'||vl_pago_total);
               */
             --  DBMS_OUTPUT.PUT_LINE('Balance:'||vl_balance);

               vl_balance:= vl_balance*(-1);
               vl_balance_sf:=vl_balance;

               vl_valida_total_balance := vl_pago_total - vl_balance;

             --  DBMS_OUTPUT.PUT_LINE('Pago total-balance:'||vl_valida_total_balance);

                IF vl_balance  > 0 THEN

                  IF vl_serie = 'BS' AND vl_valida_total_balance > 0 THEN
                    vl_pago_monto_colegiatura := vl_pago_monto_colegiatura + vl_balance;
                     vl_iva:= vl_balance - to_char (vl_balance / 1.16,'fm9999999990.00');
                     vl_balance:=vl_balance-vl_iva;

                      vl_iva:= vl_balance_sf - to_char (vl_balance_sf / 1.16,'fm9999999990.00');
                     vl_balance:=vl_balance_sf-vl_iva;
                    /* vl_iva:=to_char (vl_balance * 0.16,'fm9999999990.00');
                     vl_balance:=vl_balance - vl_iva;   */


                     vl_subtotal:= vl_subtotal+vl_balance;


                 --   DBMS_OUTPUT.PUT_LINE('Balance:'||vl_balance|| ' iva '|| vl_iva);
                  ---dbms_output.put_line(vl_pago_monto_colegiatura);

                  ELSE
                    vl_subtotal:= vl_subtotal+vl_balance;

                    IF vl_subtotal > vl_pago_total THEN
                    vl_subtotal:= vl_subtotal-vl_balance;
                    ELSE
                    vl_pago_monto_colegiatura := vl_pago_monto_colegiatura + vl_balance;
                    END IF;
                  END IF;


                ELSE
                vl_subtotal:= vl_subtotal;

                END IF;

                /*
                DBMS_OUTPUT.PUT_LINE('Balance:'||vl_balance);
               DBMS_OUTPUT.PUT_LINE('Subtotal + Balance:'||vl_subtotal);
               DBMS_OUTPUT.PUT_LINE('Monto Colegiatura:'||vl_pago_monto_colegiatura);
               DBMS_OUTPUT.PUT_LINE('PIDM :'||vl_pidm||' Transacción :'||vl_transaccion);
               */


               /* SE comebta para obtener losmontos con las fucniones desarrolladas por Victor
                BEGIN

                SELECT CASE
                WHEN TZTCON_MONEDA <> 'CLP' AND TVRDCTX_TXPR_CODE = 'IVA' THEN
                TO_CHAR(SUM(TZTCONC_MONTO)/1.16,'fm9999999990.00')
                WHEN TZTCON_MONEDA <> 'CLP' AND TVRDCTX_TXPR_CODE <> 'IVA' THEN
                TO_CHAR(SUM(TZTCONC_MONTO),'fm9999999990.00')
                WHEN TZTCON_MONEDA = 'CLP' AND TVRDCTX_TXPR_CODE = 'IVA' THEN
                TO_CHAR(SUM(TZTCONC_MONTO)/1.16)
                WHEN TZTCON_MONEDA = 'CLP' AND TVRDCTX_TXPR_CODE <> 'IVA' THEN
                TO_CHAR(SUM(TZTCONC_MONTO))
                END
                INTO vl_pago_monto_accesorio
                FROM TZTCONT, TVRDCTX
                WHERE 1=1
                AND TZTCONC_PIDM = vl_pidm
                AND TZTCONC_TRAN_NUMBER = vl_transaccion
                AND TZTCONC_DCAT_CODE IN ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                AND TZTCONC_CONCEPTO_CODE = TVRDCTX_DETC_CODE
                GROUP BY TZTCON_MONEDA, TVRDCTX_TXPR_CODE;
                EXCEPTION WHEN OTHERS THEN
                Null;
                END;
               */

                vl_pago_monto_accesorio_G:= NUll;
                vl_pago_monto_accesorio := Null;

                BEGIN

                    vl_pago_monto_accesorio_G:= pkg_utilerias.f_total_grabado_nt(vl_pidm,vl_transaccion);
                    vl_pago_monto_accesorio:= pkg_utilerias.f_total_Excento_nt(vl_pidm, vl_transaccion);

                EXCEPTION WHEN OTHERS THEN
                vl_pago_monto_accesorio_G:= 0;
                vl_pago_monto_accesorio:=0;
                END;



                vl_niveleducativo:= NULL;
                vl_id_emisor_sto:=NULL;
                vl_id_emisor_erp:=NULL;
                vl_bandera:= NULL;


                BEGIN

                    SELECT COUNT(1)
                    INTO vl_bandera
                    FROM ZSTPARA
                    WHERE 1=1
                    AND ZSTPARA_PARAM_VALOR = vl_campus
                    AND ZSTPARA_MAPA_ID = 'FA_GENEX';
                EXCEPTION
                WHEN OTHERS THEN
                vl_bandera:=0;

                END;


                BEGIN

                    IF SUBSTR(vl_nivel,1,2) = 'LI'  THEN

                    vl_niveleducativo:= 'Programas de pregrado';

                    ELSIF SUBSTR(vl_nivel,1,2) IN ('MA','DO', 'ES', 'EC') THEN

                    vl_niveleducativo:= 'Programas de posgrado';
                    ELSE
                    vl_niveleducativo := '.';

                    END IF;

                END;


                BEGIN

                IF vl_serie = 'BH' AND vl_bandera = '0' THEN
                    vl_id_emisor_sto := 1;
                    vl_id_emisor_erp := 1;
                    vl_clave_rvoe := vl_clave_rvoe;

                ELSIF vl_serie = 'BH' AND vl_bandera = 1 AND substr(vl_nivel,1,2) = 'LI' THEN
                      vl_id_emisor_sto := 1;
                      vl_id_emisor_erp := 1;
                      vl_clave_rvoe := vl_clave_rvoe;

                ELSIF vl_serie = 'BH' AND vl_bandera = 1 AND substr(vl_nivel,1,2) IN ('MA', 'DO') THEN
                      vl_id_emisor_sto := 1;
                      vl_id_emisor_erp := 1;
                      vl_clave_rvoe := vl_clave_rvoe;

                ELSIF vl_serie = 'BS' THEN
                    vl_id_emisor_sto := 2;
                    vl_id_emisor_erp := 2;
                    vl_clave_rvoe := '.';

                END IF;
                END;

               --SE PLANCHA LA VARIANLE PARA TIMBRAR CON SCALA HIGHER EDUCATION SC--
                vl_id_emisor_sto:=1;
                vl_id_emisor_erp := 1;

                vl_rfc_utel := Null;
                vl_razon_social_utel := Null;
                vl_prod_serv := Null;
                vl_cp_emisor:=null;


                BEGIN
                SELECT
                TZTDFUT_RFC rfc,
                UPPER(TZTDFUT_RAZON_SOC) razon_social,
                TZTDFUT_PROD_SERV_CODE,
                TZTDFUT_ZIP cp
                INTO vl_rfc_utel, vl_razon_social_utel, vl_prod_serv, vl_cp_emisor
                FROM TZTFOLF
                WHERE TZTDFUT_SERIE = 'BH';---d_fiscales.serie;
                EXCEPTION
                WHEN OTHERS THEN
                vl_error:= 'sp_Datos_Facturacion_xml-Error al Recuperer los datos Fiscales de la empresa ' ||sqlerrm;
                END;

                vl_consecutivo:= 0;


                BEGIN
                SELECT NVL(MAX(TZTFACT_FOLIO),0)+1--TZTDFUT_FOLIO
                INTO  vl_consecutivo
                FROM TZTFCTU
                WHERE TZTFACT_SERIE = 'BH';---d_fiscales.serie;
                EXCEPTION
                WHEN OTHERS THEN
                vl_consecutivo :=1;
                END;


                BEGIN
                UPDATE TZTDFUT
                SET TZTDFUT_FOLIO = vl_consecutivo
                WHERE TZTDFUT_SERIE = 'BH';---d_fiscales.serie;
                EXCEPTION
                WHEN OTHERS THEN
                vl_error := 'Se presento un error al Actualizar ' ||sqlerrm;
                END;
                commit;



                vl_forma_pago:= Null;
                BEGIN
                SELECT DISTINCT TZTCONC_FORMA_PAGO
                INTO vl_forma_pago
                FROM TZTCONT
                WHERE 1=1
                AND TZTCONC_PIDM = d_fiscales.pidm
                AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                EXCEPTION WHEN OTHERS THEN
                vl_forma_pago:='99';

                END;

                /* COMENTADO SOLO PARA PRUEBAS, PARA NO MOVER EL FOLIO*/
              --dbms_output.put_line(vl_consecutivo);

                vl_seq_no:= Null;
                BEGIN
                SELECT NVL(MAX(TZTLOFA_SEQ_NO)+1,1)
                INTO vl_seq_no
                FROM TZTLOFA
                WHERE 1=1
                AND TZTLOFA_PIDM = vl_pidm
                AND TZTLOFA_TRAN_NUMBER = vl_transaccion;
                EXCEPTION WHEN OTHERS THEN
                vl_seq_no:= 1;
                END;


                vl_tipo_moneda:= Null;
                BEGIN
                SELECT TZTCON_MONEDA
                INTO vl_tipo_moneda
                FROM TZTCONT
                WHERE 1=1
                AND TZTCONC_PIDM = vl_pidm
                AND TZTCONC_TRAN_NUMBER = vl_transaccion
                GROUP BY TZTCON_MONEDA;
                EXCEPTION WHEN OTHERS THEN
                INSERT INTO TZTLOFA
                VALUES (vl_pidm,
                        vl_matricula,
                        vl_transaccion,
                        'SIN_FACTURA_GENERADA_NT',
                        SYSDATE,
                        USER,
                        'TZTCONC',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        vl_seq_no);
                END;
               --COMMIT;

              --ACTIVAR A PATIR DEL 01/04/2022--
             --/*
               vl_tipo_cambio:= NUll;

                BEGIN
                   SELECT a.CONVERSION
                    INTO vl_tipo_cambio
                    FROM TZTCODA a
                    WHERE 1=1
                    and rownum <=1
                    AND a.CAMPUS = SUBSTR (vl_matricula,1,2)
                    AND a.FECHA_INSERTA IN (SELECT MAX(FECHA_INSERTA)
                                           FROM TZTCODA a1
                                           WHERE 1=1
                                           AND a.CAMPUS = a1.CAMPUS);

                EXCEPTION WHEN NO_DATA_FOUND THEN
                vl_tipo_cambio:=1;
                END;

            --*/

                       -- VARIABLE CON EL  HTML  DE soap --
             /*
             vl_soap:= vl_open_tag||'soap:Envelope xmlns:soap="'
                            ||vl_xmlns_soap||'" '
                            ||'xmlns:xsi="'||vl_xmlns_xsi ||'" '
                            ||'xmlns:xsd="'||vl_xmlns_xsd ||'" '
                            ||'xmlns:neon="'||vl_xmlns_neon ||'">'
                            ||vl_open_tag||'soap:Header'||vl_close_tag;

            vl_abre:= vl_open_tag||'soap:Body>'
                      ||vl_open_tag||'neon:emitirWS>';
             */

              IF d_fiscales.rfc = 'XEXX010101000' or  d_fiscales.rfc = 'XAXX010101000' THEN
                        vl_cfdi_receptor:= 'S01';--Agregado facto 4.0
                        vl_reg_fiscal:='616';--Agregado facto 4.0
                        vl_cp:=vl_cp_emisor;
              end if;

              ---Nodo Residencia Fiscal solo para RFC extranjeros
               IF d_fiscales.rfc = 'XEXX010101000' THEN
                   BEGIN
                      select
                          zstpara_param_id
                        into vl_residencia_fiscal
                        from
                            ZSTPARA
                        where
                            zstpara_mapa_id='FACT_EXTRANJERO'
                        AND ZSTPARA_PARAM_VALOR=SUBSTR(vl_matricula,1,2);

                        EXCEPTION WHEN OTHERS THEN
                           vl_residencia_fiscal:='MEX';

                  END;


                        if substr(vl_matricula,1,2)='40' then

                            case
                                when vl_tipo_moneda='USD' then
                                    vl_residencia_fiscal:='USA';
                                when vl_tipo_moneda='COP' then
                                    vl_residencia_fiscal:='COL';
                                when vl_tipo_moneda='PEN' then
                                    vl_residencia_fiscal:='PER';
                                when vl_tipo_moneda='CLP' then
                                    vl_residencia_fiscal:='CHL';
                                else
                                    vl_residencia_fiscal:='';

                            end case;
                         end if;

                    res_fiscal:= vl_resifis_op||vl_residencia_fiscal||vl_resifis_close;

            end if;

            --Si es MEX se omite el nodo de residencia fiscal
            if vl_residencia_fiscal='MEX' then
                begin
                     res_fiscal:='';
                end;
            end if;


             ---Se agrega nodo idioma
             begin
                 if vl_idioma = 'EN' then
                     vl_idi:=vl_idioma_op||vl_idioma||vl_idioma_close;
                 end if;
             end;
              ----Se agrega nodo notas

             vl_notas:=vl_notas_op||'Descripcion del Programa: '||vl_Desprograma||' | Bimestre: '||vl_Bimestre||' | Mes pago: '||vl_mespago||vl_notas_close;


            -- vl_cabecero_cont := vl_xml_version||vl_soap_op||vl_xmlns_tag||vl_xmlns_sopa_value||vl_xmlns_ejb_tag||vl_xmlns_ejb_value||vl_soap_header||vl_soap_body||vl_ejb||vl_request_op||vl_cfdi_op;
             vl_cabecero_cont := vl_soap_op||vl_xmlns_tag||vl_xmlns_sopa_value||vl_xmlns_ejb_tag||vl_xmlns_ejb_value||vl_soap_header||vl_soap_body||vl_ejb||vl_request_op||vl_cfdi_op;

             vl_cabecero_close:= vl_dat_ad_close||vl_inf_ad_close||vl_notas||vl_cfdi_close||vl_idi||vl_request_close/*||vl_apikey*/||vl_ejb_close||vl_soap_body_close||vl_soap_close;



          /*   vl_datos_factura_cont:= vl_serie_op||'BH'||vl_serie_close||vl_folio||vl_consecutivo||vl_folio_close||vl_fecha||vl_fecha_pago||vl_fecha_close||vl_forma_pago_op||vl_forma_pago_op||vl_forma_pago||vl_forma_pago_close
            ||vl_monto||vl_pago_total||vl_monto_close||vl_forma_pago_close||vl_condPago||vl_condicion_pago||vl_condPago_close||vl_gran_total||vl_pago_total||vl_gran_total_close||vl_total||vl_pago_total||vl_total_close
            ||vl_subtotal_op||vl_subtotal||vl_subtotal_close||vl_descuento_op||vl_descuento||vl_descuento_close||vl_moneda||vl_tipo_moneda||vl_moneda_close||vl_tipo_cambio_op||vl_tipo_cambio||vl_tipo_cambio_close||vl_tipocfdi||'FACTURA'||vl_tipocfdi_close||vl_metodo_pago_op||vl_metodo_pago||vl_metodo_pago_close
            ||vl_emisor_op||vl_rfc_op||vl_rfc_utel||vl_rfc_close||vl_emisor_close
            ||vl_receptor_op||vl_email||vl_correoR||vl_email_close||vl_nombre||d_fiscales.nombre||vl_nombre_close||vl_identificador||vl_matricula||vl_identificador_close
            ||vl_noExt||vl_num_ext||vl_noEx_close||vl_calle_op||vl_calle||vl_calle_close||vl_noInt||vl_num_int||vl_noInt_close||vl_col_op||vl_col||vl_col_close||vl_mcpo_op||vl_mncpo||vl_mcpo_close
            ||vl_edo_op||vl_edo||vl_edo_close||vl_pais_op||vl_pais||vl_pais_close||vl_cp_op||vl_cp||vl_cp_close||vl_numregtri||vl_resifis||vl_rfc_recp_op||vl_rfc||vl_rfc_recp_close||vl_usocfdi||vl_uso_cfdi||vl_usocfdi_close
            ||vl_receptor_close;
            */--comentado caty

            ---Modificado Caty para Facto 4.0 --Se pone F para pruebas , regresar a BH
            vl_datos_factura_cont:= vl_serie_op||'BH'||vl_serie_close||vl_folio||vl_consecutivo||vl_folio_close||vl_fecha||vl_fecha_pago||vl_fecha_close||vl_exportacion_op||'01'||vl_exportacion_close||vl_forma_pago_op||vl_forma_pago||vl_forma_pago_close
            /*||vl_monto||vl_pago_total||vl_monto_close||||vl_forma_pago_close*/||vl_condPago||vl_condicion_pago||vl_condPago_close||vl_gran_total||vl_pago_total||vl_gran_total_close||vl_total||vl_pago_total||vl_total_close
            ||vl_subtotal_op||vl_subtotal||vl_subtotal_close||vl_descuento_op||vl_descuento||vl_descuento_close||vl_moneda||vl_tipo_moneda||vl_moneda_close||vl_tipo_cambio_op||vl_tipo_cambio||vl_tipo_cambio_close||vl_lugar_exp_op||vl_cp_emisor||vl_lugar_exp_close||vl_tipocfdi||'FACTURA'||vl_tipocfdi_close||vl_metodo_pago_op||vl_metodo_pago||vl_metodo_pago_close
            ||vl_emisor_op||vl_cp_emisor_op||vl_cp_emisor||vl_cp_emisor_close||vl_nombre_emisor_op||vl_razon_social_utel||vl_nombre_emisor_close||vl_reg_fiscal_op||'601'||vl_reg_fiscal_close||vl_rfc_op||vl_rfc_utel||vl_rfc_close||vl_emisor_close
            ||vl_receptor_op||vl_calle_op||vl_calle||vl_calle_close||vl_col_op||vl_col||vl_col_close||vl_dom_fiscal_op||vl_cp||vl_dom_fiscal_close||vl_email||vl_correoR||vl_email_close||vl_edo_op||vl_edo||vl_edo_close||vl_identificador||vl_matricula||vl_identificador_close||vl_mcpo_op||vl_mncpo||vl_mcpo_close
            ||vl_noExt||vl_num_ext||vl_noEx_close||vl_noInt||vl_num_int||vl_noInt_close||vl_nombre||vl_nombre_receptor||vl_nombre_close
            ||vl_pais_op||vl_pais||vl_pais_close||vl_reg_fiscal_op||vl_reg_fiscal||vl_reg_fiscal_close||res_fiscal||vl_rfc_recp_op||vl_rfc||vl_rfc_recp_close||vl_cfdi_receptor_op||vl_cfdi_receptor||vl_cfdi_receptor_close
            ||vl_receptor_close;


            /*
                 -- VARIABLE CON EL  HTML  DEL comprobante --
             vl_comprobante:= vl_open_tag||'comprobante serie="'
                              ||'BH'||'" ' --d_fiscales.serie SE PLANCHA LA VARIABLE PARA TIMBRAR CON SCALA HIGHER EDUCATION SC'--
                              ||'folio="'||vl_consecutivo ||'" '
                              ||'fecha="'||vl_fecha_pago||'" '
                              ||'formaPago="'||vl_forma_pago||'" '
                              ||'condicionesDePago="'||vl_condicion_pago||'" '
                              ||'tipoCambio="'||vl_tipo_cambio||'" '
                              ||'moneda="'||vl_tipo_moneda||'" '
                              ||'metodoPago="'||vl_metodo_pago||'" '
                              ||'lugarExpedicion="'||vl_lugar_expedicion||'" '
                              ||'tipoComprobante="'||vl_tipo_comprobante||'" '
                              ||'subTotal="'||vl_subtotal||'" '
                              ||'descuento="'||vl_descuento||'" '
                              ||'total="'||vl_pago_total||'" '
                              ||'confirmacion="'||vl_confirmacion||'" '
                              ||'tipoDocumento="'||vl_tipo_documento||'">';

               vl_enviar_xml:= vl_enviar;
               vl_enviar_pdf:= vl_enviar;
               vl_enviar_zip:= vl_enviar;

                    -- VARIABLE CON EL  HTML  DEL envioCfdi --
              vl_envio_cfdi:= vl_open_tag||'envioCfdi enviarXml="'
                              ||vl_enviar_xml||'" '
                              ||'enviarPdf="'||vl_enviar_pdf||'" '
                              ||'enviarZip="'||vl_enviar_zip||'" '
                              ||'emails="'||vl_correoR||'"'||vl_close_tag;


                           -- VARIABLE CON EL  HTML  DEL emisor --
             vl_emisor:= vl_open_tag||'emisor rfc="'
                         ||vl_rfc_utel||'" '
                         ||'nombre="' ||vl_razon_social_utel||'" '
                         ||'regimenFiscal="'||vl_regimen_fiscal||'" '
                         ||'idEmisorSto="'||vl_id_emisor_sto||'" '
                         ||'idEmisorErp="'||vl_id_emisor_erp||'"'||vl_close_tag;


                           -- VARIABLE CON EL  HTML  DEL receptor --
             vl_receptor:= vl_open_tag||'receptor rfc="'
                           ||d_fiscales.rfc||'" '
                           ||'nombre="'||d_fiscales.nombre||'" '
                           ||'residenciaFiscal="'||vl_residencia_fiscal||'" '
                           ||'numRegIdTrib="'||vl_num_reg_id_trib||'" '
                           ||'usoCfdi="'||vl_uso_cfdi||'" '
                           ||'idReceptoSto="'||vl_pidm_gen||'" '  --d_fiscales.pidm
                           ||'idReceptorErp="'||vl_pidm_gen||'" ' --d_fiscales.pidm
                           ||'numeroExterior="'||d_fiscales.num_ext||'" '
                           ||'calle="'||d_fiscales.calle||'" '
                           ||'numeroInterior="'||d_fiscales.num_int||'" '
                           ||'colonia="'||d_fiscales.colonia||'" '
                           ||'localidad="'||d_fiscales.municipio||'" '
                           ||'referencia="'||vl_referencia_dom_receptor||'" '
                           ||'municipio="'||d_fiscales.municipio||'" '
                           ||'estado="'||d_fiscales.estado||'" '
                           ||'pais="'||d_fiscales.pais||'" '
                           ||'codigoPostal="'||d_fiscales.cp||'" '
                           ||'email="'||vl_correoR||'" '
                           ||'idTipoReceptor="'||vl_idTipoReceptor||'" '  --d_fiscales.id
                           ||'estatusRegistro="'||vl_estatus_registro||'"'||vl_close_tag;
             */


              BEGIN

                IF d_fiscales.rfc = 'XEXX010101000' THEN
                        vl_uso_cfdi:= 'G03';--Agregado facto 4.0
                        vl_reg_fiscal:='601';--Agregado facto 4.0

                        --DBMS_OUTPUT.PUT_LINE('Entra al if de RFC a extranjeros '||d_fiscales.rfc);

                            BEGIN

                                 vl_dni:= Null;

                                    BEGIN
                                        SELECT DISTINCT(SPBPERS_SSN)
                                        INTO vl_dni
                                        FROM SPBPERS
                                        WHERE 1=1
                                        AND SPBPERS_PIDM = d_fiscales.pidm;
                                    EXCEPTION
                                    WHEN OTHERS THEN
                                    vl_dni:= '.';
                                    END;

                                 --DBMS_OUTPUT.PUT_LINE('Recupera el DNI '||vl_dni);

                                   -- while x <= 28
                                    while x <= 34

                                    LOOP

                                        x:= x + 1;

                                       case  when x = 1 then

                                            vl_flxhdrs_nombre:='folioInterno';
                                            vl_flxhdrs_valor := d_fiscales.pidm;
                                            vl_flex_header:= vl_inf_ad_op||vl_dat_ad_op||vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                            /*
                                            vl_flxhdrs_nombre:='folioInterno';
                                            vl_flxhdrs_valor := d_fiscales.pidm;
                                            vl_flex_header:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                                            */
                                         when x = 2  then

                                               vl_flxhdrs_nombre:='razonSocial';

                                               vl_flxhdrs_valor := nvl(vl_nombre_receptor2, '.');
                                              -- vl_flxhdrs_valor := nvl(d_fiscales.nombre, '.');
                                               vl_flex_header_2:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_2:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;



                                           when x = 3 then
                                                vl_flxhdrs_nombre:='metodoDePago';
                                                vl_flxhdrs_valor := nvl(vl_metodo_pago_code, '.');
                                                vl_flex_header_3:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_3:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;--

                                           when x = 4 then
                                                vl_flxhdrs_nombre:='descripcionDeMetodoDePago';
                                                vl_flxhdrs_valor := nvl(vl_pago_metodo_pago, '.');
                                                vl_flex_header_4:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_4:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;--

                                           when x = 5  then
                                                vl_flxhdrs_nombre:='IdPago';
                                                vl_flxhdrs_valor := nvl(vl_pago_id_pago, '.');
                                                vl_flex_header_5:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_5:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;--

                                           when x = 6 then
                                                vl_flxhdrs_nombre:='Monto';
                                                vl_flxhdrs_valor := nvl(to_char(vl_pago_monto_pagado,'fm9999999990.00'), '.');
                                                vl_flex_header_6:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_6:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;--

                                           when x = 7 then
                                                vl_flxhdrs_nombre:='Nivel';
                                                vl_flxhdrs_valor := nvl(vl_nivel, '.');
                                                vl_flex_header_7:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_7:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 8 then
                                                vl_flxhdrs_nombre:='Campus';
                                                vl_flxhdrs_valor := nvl(vl_campus, '.');
                                                vl_flex_header_8:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_8:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag; --

                                           when x = 9 then

                                              /*
                                               IF d_fiscales.rfc = 'XAXX010101000' THEN
                                                vl_flxhdrs_nombre:='matriculaAlumno';
                                                vl_flxhdrs_valor := nvl('G_'||d_fiscales.matricula, '.');
                                                vl_flex_header_9:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                                               ELSE
                                                vl_flxhdrs_nombre:='matriculaAlumno';
                                                vl_flxhdrs_valor := nvl(d_fiscales.matricula, '.');
                                                vl_flex_header_9:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                                               END IF;
                                              */

                                              vl_flxhdrs_nombre:='matriculaAlumno';
                                              vl_flxhdrs_valor := nvl(d_fiscales.matricula, '.');
                                              vl_flex_header_9:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                           when x = 10 then
                                                vl_flxhdrs_nombre:='fechaPago';
                                                vl_flxhdrs_valor := nvl(vl_fecha_pago, '.');
                                                vl_flex_header_10:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_10:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;--

                                           when x = 11 then
                                                vl_flxhdrs_nombre:='Referencia';
                                                vl_flxhdrs_valor := nvl(d_fiscales.referencia, '.');
                                                vl_flex_header_11:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_11:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag; --

                                           when x = 12 then
                                                vl_flxhdrs_nombre:='ReferenciaTipo';
                                                vl_flxhdrs_valor := nvl(d_fiscales.ref_tipo, '.');
                                                vl_flex_header_12:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_12:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 13 then
                                                vl_flxhdrs_nombre:='MontoInteresPagoTardio';
                                                vl_flxhdrs_valor := nvl(vl_pago_monto_interes , '.');
                                                vl_flex_header_13:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_13:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 14 then
                                                vl_flxhdrs_nombre:='TipoAccesorio';
                                                vl_flxhdrs_valor := nvl(vl_pago_tipo_accesorio, '.');
                                                vl_flex_header_14:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_14:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 15 then
                                                vl_flxhdrs_nombre:='MontoAccesorio';
                                                vl_flxhdrs_valor := nvl(vl_pago_monto_accesorio, '.');
                                                vl_flex_header_15:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                           when x = 16 then
                                                vl_flxhdrs_nombre:='MontoAccesorioG';
                                                vl_flxhdrs_valor := nvl(vl_pago_monto_accesorio_G, '.');
                                                vl_flex_header_16:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_15:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;


                                           when x = 17 then
                                                vl_flxhdrs_nombre:='Colegiatura';
                                                vl_flxhdrs_valor := nvl(vl_pago_colegiaturas, 'COLEGIATURA LICENCIATURA');
                                                vl_flex_header_17:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_16:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 18 then
                                                vl_flxhdrs_nombre:='MontoColegiatura';
                                                vl_flxhdrs_valor := nvl(vl_pago_monto_colegiatura, nvl(vl_balance,'.'));
                                                vl_flex_header_18:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_17:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 19 then
                                                vl_flxhdrs_nombre:='NombreAlumno';
                                               -- vl_flxhdrs_valor := nvl(d_fiscales.nombre_alumno, '.');
                                                vl_flxhdrs_valor := nvl(vl_nombrealumno, '.');
                                                vl_flex_header_19:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_18:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 20 then
                                                vl_flxhdrs_nombre:='CURP';
                                                vl_flxhdrs_valor := nvl(d_fiscales.curp, '.');
                                                vl_flex_header_20:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_19:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 21 then
                                                vl_flxhdrs_nombre:='RFC';
                                             --   vl_flxhdrs_valor := nvl(d_fiscales.rfc, '.');
                                                vl_flxhdrs_valor := nvl(vl_rfc, '.');
                                                vl_flex_header_21:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_20:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 22 then
                                                vl_flxhdrs_nombre:='Grado';
                                                vl_flxhdrs_valor := nvl(d_fiscales.grado, '.');
                                                vl_flex_header_22:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_21:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 23 then
                                                vl_flxhdrs_nombre:='Nota';
                                                vl_flxhdrs_valor := '.';
                                                vl_flex_header_23:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_22:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;


                                           when x = 24 then
                                                vl_flxhdrs_nombre:='nivelEducativo';
                                                vl_flxhdrs_valor := nvl(vl_niveleducativo, '.');
                                                vl_flex_header_24:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_23:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 25 THEN
                                                vl_flxhdrs_nombre:='ClaveRVOE';
                                                vl_flxhdrs_valor := nvl(vl_clave_rvoe, '.');
                                                vl_flex_header_25:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_24:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;


                                           when x = 26 then
                                                vl_flxhdrs_nombre:='Observaciones';
                                                vl_flxhdrs_valor := nvl(vl_obs, '.');
                                                vl_flex_header_26:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_25:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 27 then
                                                vl_flxhdrs_nombre:='InteresPagoTardio';
                                                vl_flxhdrs_valor := nvl(vl_pago_intereses, '.');
                                                vl_flex_header_27:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_26:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                                           when x = 28 then
                                                vl_flxhdrs_nombre:='CorreoReceptor';
                                                vl_flxhdrs_valor := nvl(vl_correoR, '.');
                                                vl_flex_header_28:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                                --vl_flex_header_27:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;


                                           when x = 29 then
                                                vl_flxhdrs_nombre:='NDI';
                                                vl_flxhdrs_valor := nvl(vl_dni, '.');
                                                vl_flex_header_29:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                               -- vl_flex_header_28:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                                          when x=30 then
                                                vl_flxhdrs_nombre:='Sucursal';
                                                vl_flxhdrs_valor := 'UTEL';
                                                vl_flex_header_30:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                          when x=31 then
                                                vl_flxhdrs_nombre:='Centro_Consumo';
                                                vl_flxhdrs_valor := 'UTEL';
                                                vl_flex_header_31:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                          when x=32 then
                                                vl_flxhdrs_nombre:='Folio_Fiscal';
                                                vl_flxhdrs_valor := '.';
                                                vl_flex_header_32:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                          when x=33 then
                                                vl_flxhdrs_nombre:='Fecha_Emision';
                                                vl_flxhdrs_valor := '.';
                                                vl_flex_header_33:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                          when x=34 then
                                                vl_flxhdrs_nombre:='Fecha_Timbrado';
                                                vl_flxhdrs_valor := '.';
                                                vl_flex_header_34:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;


                                    else null;

                                    end case;

                                    EXIT WHEN NULL;

                                        --DBMS_OUTPUT.PUT_LINE('Se imprime el valor de x '||x);
                                    END LOOP;

                                x:=0;
                            END;

                ELSIF  d_fiscales.rfc != 'XEXX010101000' THEN

                    --DBMS_OUTPUT.PUT_LINE('Entra al if de RFC diferente a extranjeros '||d_fiscales.rfc);

                         BEGIN
                                while x <= 33

                            LOOP

                                x:= x + 1;

                               case  when x = 1 then

                                   vl_flxhdrs_nombre:='folioInterno';
                                   vl_flxhdrs_valor := d_fiscales.pidm;
                                   vl_flex_header:= vl_inf_ad_op||vl_dat_ad_op||vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                   --vl_flex_header:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;


                               when x = 2  then

                                   vl_flxhdrs_nombre:='razonSocial';
                                  -- vl_flxhdrs_valor := nvl(d_fiscales.nombre, '.');
                                  vl_flxhdrs_valor := nvl(vl_nombre_receptor2, '.');
                                   vl_flex_header_2:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    /*
                                    vl_flxhdrs_nombre:='razonSocial';
                                    vl_flxhdrs_valor := nvl(d_fiscales.nombre, '.');
                                    vl_flex_header_2:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                                    */


                               when x = 3 then
                                    vl_flxhdrs_nombre:='metodoDePago';
                                    vl_flxhdrs_valor := nvl(vl_metodo_pago_code, '.');
                                    vl_flex_header_3:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;
                                    --vl_flex_header_3:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;--

                               when x = 4 then
                                    vl_flxhdrs_nombre:='descripcionDeMetodoDePago';
                                    vl_flxhdrs_valor := nvl(vl_pago_metodo_pago, '.');
                                    vl_flex_header_4:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_4:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;--

                               when x = 5  then
                                    vl_flxhdrs_nombre:='IdPago';
                                    vl_flxhdrs_valor := nvl(vl_pago_id_pago, '.');
                                    vl_flex_header_5:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_5:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;--

                               when x = 6 then
                                    vl_flxhdrs_nombre:='Monto';
                                    vl_flxhdrs_valor := nvl(to_char(vl_pago_monto_pagado,'fm9999999990.00'), '.');
                                    vl_flex_header_6:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_6:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;--

                               when x = 7 then
                                    vl_flxhdrs_nombre:='Nivel';
                                    vl_flxhdrs_valor := nvl(vl_nivel, '.');
                                    vl_flex_header_7:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_7:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 8 then
                                    vl_flxhdrs_nombre:='Campus';
                                    vl_flxhdrs_valor := nvl(vl_campus, '.');
                                    vl_flex_header_8:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_8:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag; --

                               when x = 9 then

                                  /*
                                   IF d_fiscales.rfc = 'XAXX010101000' THEN
                                    vl_flxhdrs_nombre:='matriculaAlumno';
                                    vl_flxhdrs_valor := nvl('G_'||d_fiscales.matricula, '.');
                                    vl_flex_header_9:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                                   ELSE
                                    vl_flxhdrs_nombre:='matriculaAlumno';
                                    vl_flxhdrs_valor := nvl(d_fiscales.matricula, '.');
                                    vl_flex_header_9:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                                   END IF;
                                  */

                                  vl_flxhdrs_nombre:='matriculaAlumno';
                                  vl_flxhdrs_valor := nvl(d_fiscales.matricula, '.');
                                  vl_flex_header_9:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                               when x = 10 then
                                    vl_flxhdrs_nombre:='fechaPago';
                                    vl_flxhdrs_valor := nvl(vl_fecha_pago, '.');
                                    vl_flex_header_10:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_10:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;--

                               when x = 11 then
                                    vl_flxhdrs_nombre:='Referencia';
                                    vl_flxhdrs_valor := nvl(d_fiscales.referencia, '.');
                                    vl_flex_header_11:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_11:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag; --

                               when x = 12 then
                                    vl_flxhdrs_nombre:='ReferenciaTipo';
                                    vl_flxhdrs_valor := nvl(d_fiscales.ref_tipo, '.');
                                    vl_flex_header_12:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_12:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 13 then
                                    vl_flxhdrs_nombre:='MontoInteresPagoTardio';
                                    vl_flxhdrs_valor := nvl(vl_pago_monto_interes , '.');
                                    vl_flex_header_13:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_13:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 14 then
                                    vl_flxhdrs_nombre:='TipoAccesorio';
                                    vl_flxhdrs_valor := nvl(vl_pago_tipo_accesorio, '.');
                                    vl_flex_header_14:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_14:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 15 then
                                    vl_flxhdrs_nombre:='MontoAccesorio';
                                    vl_flxhdrs_valor := nvl(vl_pago_monto_accesorio, '.');
                                    vl_flex_header_15:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_15:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 16 then
                                    vl_flxhdrs_nombre:='MontoAccesorioG';
                                    vl_flxhdrs_valor := nvl(vl_pago_monto_accesorio_G, '.');
                                    vl_flex_header_16:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;


                               when x = 17 then
                                    vl_flxhdrs_nombre:='Colegiatura';
                                    vl_flxhdrs_valor := nvl(vl_pago_colegiaturas, 'COLEGIATURA LICENCIATURA');
                                    vl_flex_header_17:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_16:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 18 then
                                    vl_flxhdrs_nombre:='MontoColegiatura';
                                    vl_flxhdrs_valor := nvl(vl_pago_monto_colegiatura, nvl(vl_balance,'.'));
                                    vl_flex_header_18:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_17:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 19 then
                                    vl_flxhdrs_nombre:='NombreAlumno';
                                   -- vl_flxhdrs_valor := nvl(d_fiscales.nombre_alumno, '.');
                                    vl_flxhdrs_valor := nvl(vl_nombrealumno, '.');
                                    vl_flex_header_19:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_18:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 20 then
                                    vl_flxhdrs_nombre:='CURP';
                                    vl_flxhdrs_valor := nvl(d_fiscales.curp, '.');
                                    vl_flex_header_20:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_19:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 21 then
                                    vl_flxhdrs_nombre:='RFC';
                                  --  vl_flxhdrs_valor := nvl(d_fiscales.rfc, '.');
                                    vl_flxhdrs_valor := nvl(vl_rfc, '.');
                                    vl_flex_header_21:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_20:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 22 then
                                    vl_flxhdrs_nombre:='Grado';
                                    vl_flxhdrs_valor := nvl(d_fiscales.grado, '.');
                                    vl_flex_header_22:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_21:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 23 then
                                    vl_flxhdrs_nombre:='Nota';
                                    vl_flxhdrs_valor := '.';
                                    vl_flex_header_23:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_22:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;


                               when x = 24 then
                                    vl_flxhdrs_nombre:='nivelEducativo';
                                    vl_flxhdrs_valor := nvl(vl_niveleducativo, '.');
                                    vl_flex_header_24:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_23:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 25 THEN
                                    vl_flxhdrs_nombre:='ClaveRVOE';
                                    vl_flxhdrs_valor := nvl(vl_clave_rvoe, '.');
                                    vl_flex_header_25:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_24:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;


                               when x = 26 then
                                    vl_flxhdrs_nombre:='Observaciones';
                                    vl_flxhdrs_valor := nvl(vl_obs, '.');
                                    vl_flex_header_26:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_25:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 27 then
                                    vl_flxhdrs_nombre:='InteresPagoTardio';
                                    vl_flxhdrs_valor := nvl(vl_pago_intereses, '.');
                                    vl_flex_header_27:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_26:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;

                               when x = 28 then
                                    vl_flxhdrs_nombre:='CorreoReceptor';
                                    vl_flxhdrs_valor := nvl(vl_correoR, '.');
                                    vl_flex_header_28:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                                    --vl_flex_header_27:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                              when x=29 then
                                    vl_flxhdrs_nombre:='Sucursal';
                                    vl_flxhdrs_valor := 'UTEL';
                                    vl_flex_header_29:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                              when x=30 then
                                    vl_flxhdrs_nombre:='Centro_Consumo';
                                    vl_flxhdrs_valor := 'UTEL';
                                    vl_flex_header_30:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                              when x=31 then
                                    vl_flxhdrs_nombre:='Folio_Fiscal';
                                    vl_flxhdrs_valor := '.';
                                    vl_flex_header_31:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                              when x=32 then
                                    vl_flxhdrs_nombre:='Fecha_Emision';
                                    vl_flxhdrs_valor := '.';
                                    vl_flex_header_32:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;

                              when x=33 then
                                    vl_flxhdrs_nombre:='Fecha_Timbrado';
                                    vl_flxhdrs_valor := '.';
                                    vl_flex_header_33:= vl_entry_op||vl_key_op||vl_flxhdrs_nombre||vl_key_close||vl_value_op||vl_flxhdrs_valor||vl_value_close||vl_entry_close;


                               else null;

                               end case;

                            EXIT WHEN NULL;

                             --DBMS_OUTPUT.PUT_LINE('Se imprime el valor de x '||x);

                            END LOOP;

                            x:=0;

                          END;

                END IF;

              END;

                vl_out:= null;
                vl_sum_bubtotal:= 0;

               BEGIN
                SELECT SUM(TZTCONC_SUBTOTAL)
                INTO vl_sum_bubtotal
                FROM TZTCONT
                WHERE 1=1
                AND TZTCONC_PIDM = d_fiscales.pidm
                AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                EXCEPTION WHEN OTHERS THEN
                vl_sum_bubtotal:=0;
               END;

               vl_residuo:= (vl_subtotal - vl_sum_bubtotal);

              /* IF vl_residuo != 0 THEN
                DBMS_OUTPUT.PUT_LINE (vl_residuo);
               end if;
              */

              --SE PLANCHA LA VARIABLE PARA TIMBRAR CON SCALA HIGHER EDUCATION SC --

              vl_prod_serv:= '86121700';

            --  DBMS_OUTPUT.PUT_LINE ('tipo iva '|| vl_tipo_impuesto||' tipo impuesto '||vl_tipo_factor_impuesto||vl_tipo_impuesto||' '||vl_crtgo_code||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion);

               BEGIN

                    FOR C IN (SELECT TZTCONC_CONCEPTO_CODE, TZTCONC_CONCEPTO,
                                CASE
                                    WHEN TZTCON_MONEDA <> 'CLP' THEN
                                    TO_CHAR(TZTCONC_MONTO,'fm9999999990.00')
                                    WHEN TZTCON_MONEDA = 'CLP' THEN
                                    TO_CHAR(TZTCONC_MONTO)
                                END TZTCONC_MONTO,
                                CASE
                                    WHEN TZTCON_MONEDA <> 'CLP' THEN
                                    TO_CHAR(TZTCONC_SUBTOTAL,'fm9999999990.00')
                                    WHEN TZTCON_MONEDA = 'CLP' THEN
                                    TO_CHAR(TZTCONC_SUBTOTAL)
                                END IMPORTE_CONCEPTO,
                                CASE
                                    WHEN TZTCON_MONEDA <> 'CLP' THEN
                                    TO_CHAR(NVL(TZTCONC_IVA,'0.00'),'fm9999999990.00')
                                    WHEN TZTCON_MONEDA = 'CLP' THEN
                                    TO_CHAR(TZTCONC_IVA)
                                END TZTCONC_IVA,
                                TVRDCTX_TXPR_CODE TIPO_IVA ,
                                TZTCONC_DCAT_CODE CRTGO_CODE
                                FROM TZTCONT, TVRDCTX, TVRTPDC a
                            WHERE 1=1
                            AND TZTCONC_CONCEPTO_CODE = TVRDCTX_DETC_CODE
                            AND TVRTPDC_TXPR_CODE = TVRDCTX_TXPR_CODE
                            And a.TVRTPDC_DATE_FROM = (select max (b.TVRTPDC_DATE_FROM)
                                                  from TVRTPDC b
                                                  Where a.TVRTPDC_TXPR_CODE = b.TVRTPDC_TXPR_CODE)
                            AND TZTCONC_PIDM = d_fiscales.pidm
                            AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion

                    )LOOP



                    vl_numIdentificacion:= Null;
                    vl_descripcion:= Null;
                    vl_valorUnitario:= Null;
                    vl_importe:= Null;
                    vl_crtgo_code := Null;

                    vl_numIdentificacion:= c.TZTCONC_CONCEPTO_CODE;
                    vl_descripcion:= c.TZTCONC_CONCEPTO;
                    vl_valorUnitario :=c.TZTCONC_MONTO;
                    vl_importe := C.IMPORTE_CONCEPTO;
                    vl_iva := c.TZTCONC_IVA;
                    vl_tipo_impuesto:=c.TIPO_IVA;
                    vl_crtgo_code := c.CRTGO_CODE;

                --    DBMS_OUTPUT.PUT_LINE ('valor unitario '|| vl_valorUnitario);

 --DBMS_OUTPUT.PUT_LINE ('tipo iva '|| vl_tipo_impuesto||' tipo impuesto '||vl_tipo_factor_impuesto||vl_tipo_impuesto||' '||vl_crtgo_code||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion);

                    IF vl_tipo_impuesto !='IVE' AND vl_balance = 0 AND vl_crtgo_code != 'APF'  THEN

                       BEGIN
                        vl_tipo_factor_impuesto:='Tasa';

                     --   DBMS_OUTPUT.PUT_LINE ('Caso 1 linea 7155'||vl_tipo_factor_impuesto||vl_tipo_impuesto||' '||vl_crtgo_code||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion);

                        if vl_tipo_impuesto = 'IVA' THEN
                         vl_tasa_cuota_impuesto := '0.160000';
                        elsif vl_tipo_impuesto IN ('IVE','IVP')  THEN
                         vl_tasa_cuota_impuesto := '0.000000';
                        end if;


                        --se quito para probar si funciona despues de asignar el valor de 03 a objetoimp
                        --vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||
                        -- Se lo volvi a poner porque marca error
                        --Se elimina nodo impuestos ´para todos los casos cuando es obj imp=3 07/06/2023
                        vl_objetoImp:='02';

                        if vl_iva = 0.00 or vl_iva = 0 then
                            vl_total_importe_exento:= vl_total_importe_exento + vl_importe;
                            vl_tasa_cero := vl_tasa_cero + vl_importe; --Se usa cuando el tipofactorimpuesto = tasa y la base es cero se suma el importe de tasa 0
                        end if;

                         vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                       ||vl_desc||vl_curp||', '||vl_descripcion||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                       ||vl_deto||'0.0'||vl_deto_close||vl_importe_op||vl_importe||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                       ||vl_impuestos_op||vl_trslds||vl_base_op||vl_importe||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                       ||vl_trslds_close||vl_impuestos_close||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_importe||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;


                        /*
                        vl_concepto:= vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                                  ||vl_descripcion||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_importe||vl_importe_tag||vl_importe||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_importe||'"'||vl_impuesto_tag||vl_impuesto_cod
                                  ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||vl_tasa_cuota_impuesto_tag||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_iva||'"/>'||vl_impuestos_close_tag||vl_conceptos_close_tag;

                            vl_out:=vl_out||vl_concepto;
                        */

                         vl_out:=vl_out||vl_conceptos_cont;

                        END;


                    ELSIF vl_tipo_impuesto ='IVE' AND vl_balance = 0 AND vl_crtgo_code != 'APF'  THEN

                       BEGIN
                       
                       --Se agrega para exentos con ObjImp 02  
                        IF vl_ObjImp_02_Exento = 'SI' then
                                vl_tipo_factor_impuesto:='Exento'; 
                                vl_objetoImp:='02';
                                vl_tasa_cuota_impuesto := '0.000000';
                        
                            vl_total_importe_exento_02:= vl_total_importe_exento_02 + vl_importe;
                                          

                            vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                                           ||vl_desc||vl_curp||', '||vl_descripcion||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                                           ||vl_deto||'0.0'||vl_deto_close||vl_importe_op||vl_importe||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                                           ||vl_impuestos_op||vl_trslds||vl_base_op||vl_importe||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                                           ||vl_trslds_close||vl_impuestos_close||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_importe||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;

                      --   DBMS_OUTPUT.PUT_LINE ('linea 7206 '||vl_tipo_factor_impuesto||vl_tipo_impuesto||' '||vl_crtgo_code||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion||' vl_total_importe_exento_02 '||vl_total_importe_exento_02);
                        else
                        
                         vl_tipo_factor_impuesto:='Exento'; -- Se omite para exportacion 01
                         vl_objetoImp:='04';
                        --se quito para probar si funciona despues de asignar el valor de 03 a objetoimp
                        --vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||
                        -- Se lo volvi a poner porque marca error

                        --Cuando es exento, Se omite el nodo impuesto y para objeto Imp 03
                        --Se elimina nodo impuestos ´para todos los casos cuando es obj imp=3 07/06/2023
                        vl_total_importe_exento := vl_total_importe_exento + nvl(vl_importe,0);
                      --   DBMS_OUTPUT.PUT_LINE ('linea 7117 vl_importe'|| vl_importe);
                       vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                                           ||vl_desc||vl_curp||', '||vl_descripcion||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                                           ||vl_deto||'0.0'||vl_deto_close||vl_importe_op||vl_importe||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                     /*  ||vl_impuestos_op||vl_trslds||vl_base_op||vl_importe||vl_base_close||vl_importe_tras_op||'0.0'||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||'0.000000'||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                       ||vl_trslds_close||vl_impuestos_close*/||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_importe||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;
                        end if;
                        
                        
                        vl_out:=vl_out||vl_concepto;

                      --  DBMS_OUTPUT.PUT_LINE ('linea 7117 Caso 2'||vl_tipo_factor_impuesto||vl_tipo_impuesto||' '||vl_crtgo_code||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion);
                    
                         vl_out:=vl_out||vl_conceptos_cont;

                        END;
                        
                        


                    END IF;

                  END LOOP;

                  --DBMS_OUTPUT.PUT_LINE ('Out'||vl_out);

                END;


                BEGIN


                  vl_xml_final:=vl_flex_header
                           ||vl_flex_header_2
                           ||vl_flex_header_3
                           ||vl_flex_header_4
                           ||vl_flex_header_5
                           ||vl_flex_header_6
                           ||vl_flex_header_7
                           ||vl_flex_header_8
                           ||vl_flex_header_9
                           ||vl_flex_header_10
                           ||vl_flex_header_11
                           ||vl_flex_header_12
                           ||vl_flex_header_13
                           ||vl_flex_header_14
                           ||vl_flex_header_15
                           ||vl_flex_header_16
                           ||vl_flex_header_17
                           ||vl_flex_header_18
                           ||vl_flex_header_19
                           ||vl_flex_header_20
                           ||vl_flex_header_21
                           ||vl_flex_header_22
                           ||vl_flex_header_23
                           ||vl_flex_header_24
                           ||vl_flex_header_25
                           ||vl_flex_header_26
                           ||vl_flex_header_27
                           ||vl_flex_header_28
                           ||vl_flex_header_29
                           ||vl_flex_header_30
                           ||vl_flex_header_31
                           ||vl_flex_header_32
                           ||vl_flex_header_33
                           ||vl_flex_header_34
                           ;


                 if vl_balance >0 AND vl_chg_tran_numb > 0 then


                   BEGIN

                     FOR C IN (SELECT TZTCONC_CONCEPTO_CODE, TZTCONC_CONCEPTO,
                                CASE
                                    WHEN TZTCON_MONEDA <> 'CLP' THEN
                                    TO_CHAR(TZTCONC_MONTO,'fm9999999990.00')
                                    WHEN TZTCON_MONEDA = 'CLP' THEN
                                    TO_CHAR(TZTCONC_MONTO)
                                END TZTCONC_MONTO,
                                CASE
                                    WHEN TZTCON_MONEDA <> 'CLP' THEN
                                    TO_CHAR(TZTCONC_SUBTOTAL,'fm9999999990.00')
                                    WHEN TZTCON_MONEDA = 'CLP' THEN
                                    TO_CHAR(TZTCONC_SUBTOTAL)
                                END IMPORTE_CONCEPTO,
                                CASE
                                    WHEN TZTCON_MONEDA <> 'CLP' THEN
                                    TO_CHAR(NVL(TZTCONC_IVA,'0.00'),'fm9999999990.00')
                                    WHEN TZTCON_MONEDA = 'CLP' THEN
                                    TO_CHAR(TZTCONC_IVA)
                                END TZTCONC_IVA,
                                TVRDCTX_TXPR_CODE TIPO_IVA ,
                                TZTCONC_DCAT_CODE CRTGO_CODE
                                FROM TZTCONT, TVRDCTX, TVRTPDC a
                            WHERE 1=1
                            AND TZTCONC_CONCEPTO_CODE = TVRDCTX_DETC_CODE
                            AND TVRTPDC_TXPR_CODE = TVRDCTX_TXPR_CODE
                            And a.TVRTPDC_DATE_FROM = (select max (b.TVRTPDC_DATE_FROM)
                                                  from TVRTPDC b
                                                  Where a.TVRTPDC_TXPR_CODE = b.TVRTPDC_TXPR_CODE)
                            AND TZTCONC_PIDM = d_fiscales.pidm
                            AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion

                        )LOOP

                                vl_numIdentificacion:= Null;
                                vl_descripcion:= Null;
                                vl_valorUnitario:= Null;
                                vl_importe:= Null;
                                vl_crtgo_code := Null;
                                vl_totalImpuestosTrasladados:=NULL;
                                vl_total_importe:=NULL;

                                vl_numIdentificacion:= c.TZTCONC_CONCEPTO_CODE;
                                vl_descripcion:= c.TZTCONC_CONCEPTO;
                                vl_valorUnitario :=c.TZTCONC_MONTO;
                                vl_importe := C.IMPORTE_CONCEPTO;
                                vl_iva := c.TZTCONC_IVA;
                                vl_tipo_impuesto:=c.TIPO_IVA;
                                vl_crtgo_code := c.CRTGO_CODE;


                            IF
                             vl_tipo_impuesto = 'IVE' AND vl_crtgo_code != 'APF' THEN
                             vl_tipo_factor_impuesto:='Exento';
                             vl_tipo_factor_impuesto_final:='Exento';
                             vl_tasa_cuota_impuesto:='0.000000';

                            ELSIF
                             vl_tipo_impuesto ='IVP' AND vl_crtgo_code != 'APF' THEN
                             vl_tipo_factor_impuesto:='Tasa';
                             vl_tipo_factor_impuesto_final:='Tasa';
                             vl_tasa_cuota_impuesto:='0.000000';

                            ELSIF
                             vl_tipo_impuesto ='IVA' AND vl_crtgo_code != 'APF' THEN
                             vl_tipo_factor_impuesto:='Tasa';
                             vl_tipo_factor_impuesto_final:='Tasa';
                             vl_tasa_cuota_impuesto:='0.160000';

                            END IF;

                    --  DBMS_OUTPUT.PUT_LINE ('Entra 1 en balance > 0 y vl_chg_tran_numb >0 ****'||vl_balance||'*'||vl_chg_tran_numb||'*'||vl_tipo_factor_impuesto_final||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion);

                            BEGIN

                                 BEGIN
                                    SELECT TZTCON_MONEDA
                                    INTO vl_tipo_moneda
                                    FROM TZTCONT
                                    WHERE 1=1
                                      AND TZTCONC_PIDM = d_fiscales.pidm
                                      AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                                     GROUP BY TZTCON_MONEDA;
                                 EXCEPTION WHEN OTHERS THEN
                                 vl_tipo_moneda:='MXN';
                                 END;

                                IF vl_tipo_moneda <> 'CLP' THEN

                                   BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0.00'), 'fm9999999990.00'),TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                    INTO vl_totalImpuestosTrasladados,vl_total_importe
                                    FROM  TZTCONT
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0.00';
                                   vl_total_importe:='0.00'; --Agregué sum de subtotal paa el nodo base en total de impuestos trasladados
                                   END;

                              --   DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'*****IF vl_tipo_moneda <> CLP********'||vl_tipo_factor_impuesto_final);

                                ELSIF vl_tipo_moneda = 'CLP' THEN

                                   BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0')),TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                    INTO vl_totalImpuestosTrasladados,vl_total_importe
                                    FROM  TZTCONT
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0';
                                    vl_total_importe:='0.00'; --Agregué sum de subtotal paa el nodo base en total de impuestos trasladados
                                   END;

                                END IF;

                            END;
                          --objimp 01
                        --  DBMS_OUTPUT.PUT_LINE('linea 7338 vl_importe total'||vl_total_importe);
                         --se quito para probar si funciona despues de asignar el valor de 03 a objetoimp
                        --vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||
                        -- Se lo volvi a poner porque marca error

                        --Se elimina nodo impuestos ´para todos los casos cuando es obj imp=3 07/06/2023

                       if vl_tipo_factor_impuesto = 'Tasa' then

                                vl_objetoImp:='02';

                             if vl_iva = 0.00 or vl_iva = 0 then
                                 vl_total_importe_exento:= vl_total_importe_exento + vl_importe;
                                 vl_tasa_cero := vl_tasa_cero + vl_importe; --lo habilite 21072023
                                 
                               --     DBMS_OUTPUT.PUT_LINE('linea7435'||vl_tipo_factor_impuesto||' importe '||vl_importe || ' vl_total_importe_exento '||vl_total_importe_exento);
                            end if;
                      



                                vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                               ||vl_desc||vl_curp||', '||vl_descripcion||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                               ||vl_deto||'0.0'||vl_deto_close||vl_importe_op||vl_importe||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                               ||vl_impuestos_op||vl_trslds||vl_base_op||vl_importe||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                               ||vl_trslds_close||vl_impuestos_close||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_importe||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;
                        end if;

                        if vl_tipo_factor_impuesto = 'Exento' then
                        
                        --Se agrega para exentos con ObjImp 02  
                            IF vl_ObjImp_02_Exento = 'SI' then
                                    vl_tipo_factor_impuesto:='Exento'; 
                                    vl_objetoImp:='02';
                                    vl_tasa_cuota_impuesto := '0.000000';
                            
                                vl_total_importe_exento_02:= vl_total_importe_exento_02 + vl_importe;
                                
                                 vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                                   ||vl_desc||vl_curp||', '||vl_descripcion||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                                   ||vl_deto||'0.0'||vl_deto_close||vl_importe_op||vl_importe||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                                   ||vl_impuestos_op||vl_trslds||vl_base_op||vl_importe||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                                   ||vl_trslds_close||vl_impuestos_close||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_importe||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;
                                
                            --    DBMS_OUTPUT.PUT_LINE('linea7453'||vl_tipo_factor_impuesto||' importe '||vl_importe || ' vl_total_importe_exento '||vl_total_importe_exento);
                                
                            else  
                                vl_total_importe_exento := vl_total_importe_exento + vl_importe;
                                vl_objetoImp:='04';

                           --   DBMS_OUTPUT.PUT_LINE('entra aqui linea 7470 vl_balance'|| vl_balance);

                                 vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                                   ||vl_desc||vl_curp||', '||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                                   ||vl_deto||vl_descuento||vl_deto_close||vl_importe_op||/*vl_balance*/vl_importe||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                                   /*||vl_impuestos_op||vl_trslds||vl_base_op||vl_balance||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                                   ||vl_trslds_close||vl_impuestos_close*/||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||/*vl_balance*/vl_importe||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;


                            end if;
                         end if;   
                       vl_out:=vl_out||vl_conceptos_cont;

                        /*
                         vl_concepto:= vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                              ||vl_descripcion||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_importe||vl_importe_tag||vl_importe||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_importe||'"'||vl_impuesto_tag||vl_impuesto_cod
                              ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||vl_tasa_cuota_impuesto_tag||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_iva||'"/>'||vl_impuestos_close_tag||vl_conceptos_close_tag;

                         vl_out:= vl_out||vl_concepto;
                        */

                 --       vl_total_importe:=vl_total_importe+vl_importe;-- Se agrega para obtener el total de los importes para el nodo base de impuestos trasladados

                      end loop;

                   --   DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************'||vl_tipo_factor_impuesto_final);

                   --      DBMS_OUTPUT.PUT_LINE(' Tasa '||vl_tipo_factor_impuesto || ' total balance ' ||vl_valida_total_balance);
                       if vl_tipo_factor_impuesto ='Tasa' and vl_valida_total_balance > 0 then

                      -- DBMS_OUTPUT.PUT_LINE(vl_serie);

                            if vl_serie = 'BS' AND vl_valida_total_balance > 0 THEN
                     --       dbms_output.put_line(vl_balance);
                            vl_iva:=to_char(vl_balance * 0.16 , 'fm9999999990.00');
                       --    DBMS_OUTPUT.PUT_LINE('entra  vl_serie = BS AND vl_valida_total_balance > 0' );
                           -- vl_balance:= to_char (vl_balance * 1.16,'fm9999999990.00'); -- se agrea el IVA al balance para el valor unitario del concepto--
                             vl_iva:= vl_balance - to_char (vl_balance / 1.16,'fm9999999990.00');--

                             vl_balance_sf:=vl_balance_sf-vl_iva; --Agregue vl_balance_sf para obtener el iva y no afecte el redondeo de decimales en el resultado final
                             vl_balance:=vl_balance_sf+vl_iva;
                        --     dbms_output.put_line(vl_balance);

                            end if;
                         --dbms_output.put_line(vl_balance);
                              if vl_serie = 'BS' then--and vl_tipo_impuesto = 'IVA'  then
                              --se utiliza la variable IVA para colocar el importe sin IVA del remanente (balance)
                              --dbms_output.put_line('vl_balance '||vl_balance);
                               vl_iva:= vl_balance - to_char (vl_balance / 1.16,'fm9999999990.00');
                               vl_balance_1:= vl_balance - vl_iva;
                               vl_totalImpuestosTrasladados:= vl_totalImpuestosTrasladados + vl_iva;
                               vl_totalImpuestosTrasladados_balance:=vl_iva;

                          --     dbms_output.put_line('vl_ivaa '||vl_iva);
                             else
                             vl_balance_1:= vl_balance;
                             vl_tipo_factor_impuesto:= vl_tipo_factor_impuesto;--'"Exento"';
                             vl_tasa_cuota_impuesto:='0.000000';
                             vl_iva:= '0.00';

                             end if;
                              vl_total_importe:=vl_total_importe+nvl(vl_balance_1,0); --suma al importe total el balance

                         --   dbms_output.put_line(' balance_1 '||vl_balance_1 || 'vl_iva '||vl_iva);

                            --se quito para probar si funciona despues de asignar el valor de 03 a objetoimp
                            --vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||
                            -- Se lo volvi a poner porque marca error
                              vl_objetoImp:='02';

                                if vl_iva = 0.00 or vl_iva = 0 then
                                 vl_total_importe_exento:= vl_total_importe_exento + nvl(vl_balance_1,0);
                                 vl_tasa_cero := vl_tasa_cero + nvl(vl_balance_1,0); --Se usa cuando el tipofactorimpuesto = tasa y la base es cero se suma el importe de tasa 0
                                end if;
                           --    DBMS_OUTPUT.PUT_LINE('linea7411'||vl_tipo_factor_impuesto||' importe '||vl_balance_1||' vl_tasa_cero '||vl_tasa_cero);

                               vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                               ||vl_desc||vl_curp||', '||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                               ||vl_deto||vl_descuento||vl_deto_close||vl_importe_op||vl_balance_1||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                               ||vl_impuestos_op||vl_trslds||vl_base_op||vl_balance_1||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                               ||vl_trslds_close||vl_impuestos_close||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_balance_1||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;

                               vl_out:=vl_out||vl_conceptos_cont;

                       --      dbms_output.put_line(vl_conceptos_cont);
                            

                        elsif vl_tipo_factor_impuesto ='Exento' and vl_valida_total_balance > 0 then
                            --suma al importe total el saldo a favor (vl_balance)
                           --  vl_total_importe:=vl_total_importe+vl_balance; --ya no lleva el importe del balance porque es exento
                      --   DBMS_OUTPUT.PUT_LINE('linea7419 entra  vl_tipo_factor_impuesto =Exento and vl_valida_total_balance > 0 ');

                    
                        ---AQUI LE MOVI AL VALOR UNITARIO que sea igual a la base tenia balance_1
                        --se quito para probar si funciona despues de asignar el valor de 03 a objetoimp
                        --vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||
                        -- Se lo volvi a poner porque marca error
                        --Se elimina nodo impuesto para objimp 03
                              IF vl_ObjImp_02_Exento = 'SI' then
                                 vl_tipo_factor_impuesto:='Exento'; 
                                 vl_objetoImp:='02';
                        
                                 vl_total_importe_exento_02:= vl_total_importe_exento_02 + vl_balance;
                                 
                                
                           --    DBMS_OUTPUT.PUT_LINE('linea7411'||vl_tipo_factor_impuesto||' importe '||vl_balance_1||' vl_tasa_cero '||vl_tasa_cero);

                               vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                               ||vl_desc||vl_curp||', '||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                               ||vl_deto||vl_descuento||vl_deto_close||vl_importe_op||vl_balance||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                               ||vl_impuestos_op||vl_trslds||vl_base_op||vl_balance||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                               ||vl_trslds_close||vl_impuestos_close||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_balance||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;

                                 vl_out:=vl_out||vl_conceptos_cont;
                                 
                           --  DBMS_OUTPUT.PUT_LINE('linea7572'||vl_tipo_factor_impuesto||' importe '||vl_importe || ' vl_total_importe_exento '||vl_total_importe_exento ||' vl_balance '||vl_balance);
                               else

                                        vl_objetoImp:='04';

                                        vl_total_importe_exento := vl_total_importe_exento + vl_balance;

                                         vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                                           ||vl_desc||vl_curp||', '||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                                           ||vl_deto||vl_descuento||vl_deto_close||vl_importe_op||vl_balance||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                                           /*||vl_impuestos_op||vl_trslds||vl_base_op||vl_balance||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                                           ||vl_trslds_close||vl_impuestos_close*/||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_balance||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;

                                         
                                            vl_out:=vl_out||vl_conceptos_cont;

                                          /*
                                          vl_concepto_balance := vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                                                          ||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_balance||vl_importe_tag||vl_balance||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_balance||'"'||vl_impuesto_tag||vl_impuesto_cod
                                                          ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||'/>'||vl_impuestos_close_tag||vl_conceptos_close_tag;

                                          vl_out:=vl_out||vl_concepto_balance;
                                          */
                               end if;           

                        end if;

                       vl_out:= vl_out; --||vl_concepto_balance;
                       vl_totalImpuestosTrasladados:= vl_totalImpuestosTrasladados;
                       --vl_totalImpuestosRetenidos:= vl_totalImpuestosTrasladados;

                    --   DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************1'||vl_tipo_factor_impuesto_final);

                       IF vl_totalImpuestosTrasladados >  0 THEN
                        vl_tipo_factor_impuesto_final:='Tasa';
                        vl_tasa_cuota_impuesto :='0.160000';
                    --     DBMS_OUTPUT.PUT_LINE('linea 7621 aqui si');

                          BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0.00'), 'fm9999999990.00'),TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                    INTO vl_totalImpuestosTrasladados, vl_total_importe
                                    FROM  TZTCONT
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                              --      and TZTCONC_IVA>0
                                    ;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0.00';
                                   vl_total_importe:='0.00';
                            END;

                       END IF;



                  --    DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************2'||vl_tipo_factor_impuesto_final);
                       --Modificado para facto 4.0 se agrega nodo base

                       --se quito para probar si funciona despues de asignar el valor de 03 a objetoimp
                        --vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close|| -- Se lo volvi a poner porque marca error

                        --||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close --tambien se quito

                        --Se elimina nodo impuestos e impuestos trasladados para todos los casos cuando es obj imp=3 07/06/2023

                        if vl_tipo_factor_impuesto_final='Exento' then
                        
                                if vl_ObjImp_02_Exento='SI' then
                                    
                                   -- vl_tipo_factor_impuesto_final:='Exento';
                                     vl_concepto_objImp02:=   vl_traslado_op
                                                                ||vl_base_op|| TO_CHAR(vl_total_importe_exento_02,'fm9999999990.00')||vl_base_close
                                                                ||vl_importe_tras_op||'0.00'||vl_importe_tras_close
                                                                ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close
                                                                ||vl_tasa_cta_op||'0.000000'||vl_tasa_cta_close
                                                                ||vl_tipo_fctr_op||'Exento'||vl_tipo_fctr_close
                                                                ||vl_traslado_close;
                                                                
                                   vl_out:= vl_cabecero_cont||vl_datos_factura_cont||vl_out
                                            ||vl_impuestos_op/*||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close*/
                                            ||vl_tot_impuestos_tras||vl_totalImpuestosTrasladados||vl_tot_impuestos_tras_close
                                          --  ||vl_concepto_tasa_cero --Se agrega para separar el importe cuando es tasa cero y con iva
                                            ||vl_concepto_objImp02
                                         /*   ||vl_traslado_op||vl_base_op||vl_total_importe||vl_base_close||vl_importe_tras_op||vl_totalImpuestosTrasladados||vl_importe_tras_close
                                            ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close||vl_traslado_close
                                            */
                                            ||vl_impuestos_close
                                            ||vl_info_facto_op||vl_factu_auto_op||vl_factu_auto||vl_factu_auto_close||vl_folios_facto_op||vl_folios_facto||vl_folios_facto_close||vl_id_integracion_op||vl_id_integracion_value||vl_id_integracion_close||vl_integracion_op||vl_integracion||vl_integracion_close||vl_info_facto_close
                                            ||vl_xml_final||vl_cabecero_close;
                                                                            
                                                                
                                                     --   DBMS_OUTPUT.PUT_LINE('entra aqui 7646 tasa_cero'||vl_concepto_tasa_cero);
                                else


                                vl_out:= vl_cabecero_cont||vl_datos_factura_cont||vl_out
                                    /*||vl_impuestos_op||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close
                                    ||vl_tot_impuestos_tras||vl_totalImpuestosTrasladados||vl_tot_impuestos_tras_close||vl_traslado_op||vl_base_op||vl_total_importe||vl_base_close||vl_importe_tras_op||vl_totalImpuestosTrasladados||vl_importe_tras_close
                                    ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close||vl_traslado_close
                                    ||vl_impuestos_close*/
                                    ||vl_info_facto_op||vl_factu_auto_op||vl_factu_auto||vl_factu_auto_close||vl_folios_facto_op||vl_folios_facto||vl_folios_facto_close||vl_id_integracion_op||vl_id_integracion_value||vl_id_integracion_close||vl_integracion_op||vl_integracion||vl_integracion_close||vl_info_facto_close
                                    ||vl_xml_final||vl_cabecero_close;
                               end if;     
                        else
                            if vl_totalImpuestosTrasladados >= 0 then
                              if    vl_iva = 0.00 or vl_iva = 0 then
                         --       DBMS_OUTPUT.PUT_LINE('entra aqui 7531 vl_total_importe_exento'|| vl_total_importe_exento || 'vl_total_importe '|| vl_total_importe|| 'vl_balance_1 '||vl_balance_1 ||'vl_balance '||vl_balance);
                             
                                if vl_balance >0 and vl_balance_1 =0 then vl_balance_1:=vl_balance; end if;
                                
                                vl_total_importe := (vl_total_importe ) - (vl_total_importe_exento - nvl(vl_balance_1,0));---aqui cambie balance a balance_1
                               
                           --     DBMS_OUTPUT.PUT_LINE('linea 7591 vl_total_importe'||vl_total_importe);
                                if vl_tasa_cero >  0  and vl_totalImpuestosTrasladados > 0 then

                                    vl_concepto_tasa_cero:=   vl_traslado_op
                                                            ||vl_base_op||vl_tasa_cero||vl_base_close
                                                            ||vl_importe_tras_op||'0.00'||vl_importe_tras_close
                                                            ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close
                                                            ||vl_tasa_cta_op||'0.000000'||vl_tasa_cta_close
                                                            ||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close
                                                            ||vl_traslado_close;

                                end if;

                              else
                                vl_total_importe := (vl_total_importe +nvl(vl_balance_1,0)) - vl_total_importe_exento;
                            --    DBMS_OUTPUT.PUT_LINE('linea 7578 vl_total_importe '||vl_total_importe||' vl_balance_1 '||vl_balance_1);
                                  vl_totalImpuestosTrasladados:=vl_totalImpuestosTrasladados + vl_totalImpuestosTrasladados_balance;

                                  if vl_tasa_cero >  0  then

                                    vl_concepto_tasa_cero:=   vl_traslado_op
                                                            ||vl_base_op||vl_tasa_cero||vl_base_close
                                                            ||vl_importe_tras_op||'0.00'||vl_importe_tras_close
                                                            ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close
                                                            ||vl_tasa_cta_op||'0.000000'||vl_tasa_cta_close
                                                            ||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close
                                                            ||vl_traslado_close;

                                end if;



                           --     DBMS_OUTPUT.PUT_LINE('entra aqui 7535 vl_total_importe_exento'|| vl_total_importe_exento || 'vl_total_importe '|| vl_total_importe|| 'vl_balance_1 '||vl_balance_1);
                               end if;
                            end if;

                            if vl_tipo_factor_impuesto_final = 'Tasa' and ( vl_totalImpuestosTrasladados = 0 or vl_totalImpuestosTrasladados = 0.00  ) then
                                vl_total_importe := vl_tasa_cero;
                                 if(vl_totalImpuestosTrasladados_balance>0 ) then
                                    vl_total_importe:=vl_balance_1;
                                    vl_totalImpuestosTrasladados:=vl_totalImpuestosTrasladados_balance;
                                 end if;
                              --  DBMS_OUTPUT.PUT_LINE('entra aqui 7537 vl_total_importe_exento'|| vl_total_importe_exento || 'vl_total_importe '|| vl_total_importe);
                            end if;


                         --   DBMS_OUTPUT.PUT_LINE('entra linea 7718 vl_total_importe '||vl_total_importe||' vl_total_importe_exento ' || vl_total_importe_exento ||' vl_tasa_cero '|| vl_tasa_cero ||' vl_concepto_objImp02 '||vl_concepto_objImp02);
                             vl_out:= vl_cabecero_cont||vl_datos_factura_cont||vl_out
                                ||vl_impuestos_op/*||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close*/
                                ||vl_tot_impuestos_tras||vl_totalImpuestosTrasladados||vl_tot_impuestos_tras_close
                                ||vl_concepto_tasa_cero --Se agrega para separar el importe cuando es tasa cero y con iva
                                ||vl_concepto_objImp02
                                ||vl_traslado_op||vl_base_op||vl_total_importe||vl_base_close||vl_importe_tras_op||vl_totalImpuestosTrasladados||vl_importe_tras_close
                                ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close||vl_traslado_close
                                ||vl_impuestos_close
                                ||vl_info_facto_op||vl_factu_auto_op||vl_factu_auto||vl_factu_auto_close||vl_folios_facto_op||vl_folios_facto||vl_folios_facto_close||vl_id_integracion_op||vl_id_integracion_value||vl_id_integracion_close||vl_integracion_op||vl_integracion||vl_integracion_close||vl_info_facto_close
                                ||vl_xml_final||vl_cabecero_close;
                        end if;

                      /*
                        vl_out:= vl_cabecero_cont||vl_datos_factura_cont||vl_out
                            ||vl_impuestos_op||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close
                            ||vl_tot_impuestos_tras||vl_totalImpuestosTrasladados||vl_tot_impuestos_tras_close||vl_traslado_op||vl_importe_tras_op||vl_totalImpuestosTrasladados||vl_importe_tras_close
                            ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close||vl_traslado_close
                            ||vl_impuestos_close
                            ||vl_xml_final||vl_cabecero_close;*/
                      /*
                       vl_out:= vl_soap||vl_abre||vl_comprobante||vl_envio_cfdi||vl_emisor||vl_receptor||vl_xml_final||vl_out--||vl_concepto||vl_concepto_balance
                                    ||vl_totalImpuestosRet_tag||vl_totalImpuestosRetenidos||'" '||vl_totalImpTras_tag||vl_totalImpuestosTrasladados||'"> '||vl_open_tag||vl_traslados_tag
                                    ||vl_impuesto_tag||vl_impuesto_cod||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto_final||vl_tasa_cuota_impuesto_tag
                                    ||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_totalImpuestosTrasladados||'"'||vl_close_tag
                                    ||vl_impuestos_close_tag||vl_tipo_operacion_tag||vl_tipo_operacion||vl_tipo_operacion_close_tag||vl_cierre;
                      */
                     --DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************3'||vl_tipo_factor_impuesto_final);

                   END;


                 elsif vl_balance >0 AND vl_chg_tran_numb = 0 then

                   BEGIN
               --  DBMS_OUTPUT.PUT_LINE('elsif vl_balance >0 AND vl_chg_tran_numb = 0');

                        IF
                          vl_tipo_impuesto ='IVE' AND vl_crtgo_code != 'APF' THEN
                          vl_tipo_factor_impuesto:='Exento';
                          vl_tipo_factor_impuesto_final:='Exento';
                          vl_tasa_cuota_impuesto:='0.000000';

                        ELSIF
                             vl_tipo_impuesto ='IVP' AND vl_crtgo_code != 'APF' THEN
                             vl_tipo_factor_impuesto:='Tasa';
                             vl_tipo_factor_impuesto_final:='Tasa';
                             vl_tasa_cuota_impuesto:='0.000000';

                        ELSIF
                         vl_tipo_impuesto ='IVA' AND vl_crtgo_code != 'APF' THEN
                         vl_tipo_factor_impuesto:='Tasa';
                         vl_tipo_factor_impuesto_final:='Tasa';
                          vl_tasa_cuota_impuesto:='0.160000';

                        END IF;

                      vl_totalImpuestosTrasladados:=NULL;

                         BEGIN

                             BEGIN
                                SELECT TZTCON_MONEDA
                                INTO vl_tipo_moneda
                                FROM TZTCONT
                                WHERE 1=1
                                AND TZTCONC_PIDM = d_fiscales.pidm
                                AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                                 GROUP BY TZTCON_MONEDA;
                             EXCEPTION WHEN OTHERS THEN
                             vl_tipo_moneda:='MXN';
                             END;

                            IF vl_tipo_moneda <> 'CLP' THEN

                               BEGIN
                                SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0.00'), 'fm9999999990.00'),TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                INTO vl_totalImpuestosTrasladados, vl_total_importe
                                FROM  TZTCONT
                                WHERE 1=1
                                AND TZTCONC_PIDM = d_fiscales.pidm
                                AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                               EXCEPTION WHEN OTHERS THEN
                               vl_totalImpuestosTrasladados:='0.00';
                               END;

                               --DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************'||vl_tipo_factor_impuesto_final);

                            ELSIF vl_tipo_moneda = 'CLP' THEN

                               BEGIN
                                SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0')),TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                INTO vl_totalImpuestosTrasladados,vl_total_importe
                                FROM  TZTCONT
                                WHERE 1=1
                                AND TZTCONC_PIDM = d_fiscales.pidm
                                AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                               EXCEPTION WHEN OTHERS THEN
                               vl_totalImpuestosTrasladados:='0';
                               END;

                            END IF;

                        END;

                 --     DBMS_OUTPUT.PUT_LINE ('Entra 2 en balance > 0 y vl_chg_tran_numb = 0 ****'||vl_balance||'*'||vl_chg_tran_numb||'*'||vl_tipo_factor_impuesto_final||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion);

                       IF vl_tipo_factor_impuesto ='Tasa' then

                            if vl_serie = 'BS' AND vl_valida_total_balance > 0 THEN
                                vl_balance:= to_char (vl_balance * 1.16,'fm9999999990.00'); -- se agrea el IVA al balance para el valor unitario- del concepto--
                            end if;

                          --dbms_output.put_line(vl_balance);
                              if vl_tipo_impuesto = 'IVA'  then
                              --se utiliza la variable IVA para colocar el importe sin IVA del remanente (balance)
                               vl_iva:= vl_balance - to_char (vl_balance / 1.16,'fm9999999990.00');
                               vl_balance_1:= vl_balance - vl_iva;
                               vl_totalImpuestosTrasladados:= vl_totalImpuestosTrasladados;-- + vl_iva;
                               --dbms_output.put_line(vl_iva);
                             else
                             vl_balance_1:= vl_balance;

                             end if;


                         /*
                         vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                               ||vl_desc||vl_curp||', '||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                               ||vl_deto||vl_descuento||vl_deto_close||vl_importe_op||vl_balance_1||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                               ||vl_impuestos_op||vl_trslds||vl_base_op||vl_balance_1||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                               ||vl_trslds_close||vl_impuestos_close||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_balance_1||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;

                         */

                         --se quito para probar si funciona despues de asignar el valor de 03 a objetoimp
                         --vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||
                         -- Se lo volvi a poner porque marca error
                          --Se elimina nodo impuestos e impuestos trasladados para todos los casos cuando es obj imp=3 07/06/2023
                         vl_objetoImp:='02';

                            if vl_iva = 0.00 or vl_iva = 0 then
                                 vl_total_importe_exento:= vl_total_importe_exento + vl_balance_1;
                                 vl_tasa_cero := vl_tasa_cero + vl_balance_1; --Se usa cuando el tipofactorimpuesto = tasa y la base es cero se suma el importe de tasa 0

                            end if;
                       --   DBMS_OUTPUT.PUT_LINE ('linea7679 '||vl_balance_1||' vl_tasa_Cero '||vl_tasa_cero);
                               vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                               ||vl_desc||vl_curp||', '||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                               ||vl_deto||vl_descuento||vl_deto_close||vl_importe_op||vl_balance_1||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                               ||vl_impuestos_op||vl_trslds||vl_base_op||vl_balance_1||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                               ||vl_trslds_close||vl_impuestos_close||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_balance_1||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;

                          --||vl_vlor_uni||vl_balance_1||vl_vlor_uni_close
                            /*
                             vl_concepto_balance:= vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                                          ||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_balance_1||vl_importe_tag||vl_balance_1||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_balance_1||'"'||vl_impuesto_tag||vl_impuesto_cod
                                          ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||vl_tasa_cuota_impuesto_tag||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_iva||'"/>'
                                          ||vl_impuestos_close_tag||vl_conceptos_close_tag;

                             */
                              --vl_out:=vl_out||vl_concepto_balance;
                       elsif vl_tipo_factor_impuesto ='Exento' then
                       ----Caty

                  
                         --se quito para probar si funciona despues de asignar el valor de 03 a objetoimp
                        --vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||
                        -- Se lo volvi a poner porque marca error
                         --Se elimina nodo impuestos e impuestos trasladados para todos los casos cuando es obj imp=3 07/06/2023
                              IF vl_ObjImp_02_Exento = 'SI' then
                                         vl_tipo_factor_impuesto:='Exento'; 
                                         vl_objetoImp:='02';
                                         vl_balance_1:=vl_balance;
                                         vl_total_importe_exento_02:= vl_total_importe_exento_02 + vl_balance_1;
                                         
                                            
                                      --     DBMS_OUTPUT.PUT_LINE('linea7895 vl_total_importe_exento_02'||vl_total_importe_exento_02||' vl_balance_1 '||vl_balance_1||' vl_tasa_cero '||vl_tasa_cero);

                                           vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                                           ||vl_desc||vl_curp||', '||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                                           ||vl_deto||vl_descuento||vl_deto_close||vl_importe_op||vl_balance_1||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                                           ||vl_impuestos_op||vl_trslds||vl_base_op||vl_balance_1||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                                           ||vl_trslds_close||vl_impuestos_close||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_balance_1||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;

                               else
                             
                             
                                         vl_objetoImp:='04';
                                         vl_total_importe_exento := vl_total_importe_exento + vl_balance;

                                               vl_conceptos_cont:= vl_conceptos||vl_cantidad||vl_cantidad_concepto||vl_cantidad_close||vl_cve_prod_ser||vl_prod_serv||vl_cve_prod_ser_close||vl_cve_unidad||vl_clave_unidad_concepto||vl_cve_unidad_close
                                               ||vl_desc||vl_curp||', '||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||', '||vl_clave_rvoe||vl_desc_close
                                               ||vl_deto||vl_descuento||vl_deto_close||vl_importe_op||vl_balance||vl_importe_close||vl_unidad||vl_unidad_concepto||vl_unidad_close
                                               /*||vl_impuestos_op||vl_trslds||vl_base_op||vl_balance||vl_base_close||vl_importe_tras_op||vl_iva||vl_importe_tras_close||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto||vl_tipo_fctr_close
                                               ||vl_trslds_close||vl_impuestos_close*/||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close||vl_unidad||vl_unidad_concepto||vl_unidad_close||vl_vlor_uni||vl_balance||vl_vlor_uni_close||vl_noIden||vl_numIdentificacion||vl_noIden_close||vl_conceptos_close;

                                       --||vl_vlor_uni||vl_balance||vl_vlor_uni_close||vl_objeto_imp_op||vl_objetoImp||vl_objeto_imp_close
                                          /*
                                          vl_concepto_balance:= vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                                                      ||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_balance||vl_importe_tag||vl_balance||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_balance||'"'||vl_impuesto_tag||vl_impuesto_cod
                                                      ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||'/>'||vl_impuestos_close_tag||vl_conceptos_close_tag;

                                            --vl_out:= vl_out||vl_concepto_balance;
                                          */

                              end if;
                        END IF;

                   -- DBMS_OUTPUT.PUT_LINE ('linea 7953 Entra en balance > a 0 y vl_chg_tran_numb =0 **'||vl_balance||'*'||vl_chg_tran_numb||'*'||vl_tipo_factor_impuesto_final||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion);

                        vl_out:= vl_out||vl_conceptos_cont; --PARA USO NT
                        --DBMS_OUTPUT.PUT_LINE (vl_out);
                        --vl_out:= vl_out||vl_concepto_balance;

                        vl_totalImpuestosTrasladados:= vl_totalImpuestosTrasladados;
                        --vl_totalImpuestosRetenidos:= vl_totalImpuestosTrasladados;

                       IF vl_totalImpuestosTrasladados >  0 THEN
                        vl_tipo_factor_impuesto_final:='Tasa';
                        vl_tasa_cuota_impuesto :='0.160000';
                        vl_totalImpuestosTrasladados:= vl_totalImpuestosTrasladados;--Se agrega facto 4.0
                      --  DBMS_OUTPUT.PUT_LINE ('entra aquiiiiiii linea 7700');
                         BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0.00'), 'fm9999999990.00'),TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                    INTO vl_totalImpuestosTrasladados, vl_total_importe
                                    FROM  TZTCONT
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                                   -- and TZTCONC_IVA>0  --comente 22/06/2023
                                    ;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0.00';
                                   vl_total_importe:='0.00';
                                   END;

                       END IF;


                       --se quito para probar si funciona despues de asignar el valor de 03 a objetoimp
                        --vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||
                       -- ||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close --tambien se quitó
                        --Se elimina nodo impuestos e impuestos trasladados para todos los casos cuando es obj imp=3 07/06/2023

                       if vl_tipo_factor_impuesto_final='Exento' then
                            if vl_ObjImp_02_Exento='SI' then
                                    
                                   -- vl_tipo_factor_impuesto_final:='Exento';
                                     vl_concepto_objImp02:=   vl_traslado_op
                                                                ||vl_base_op|| TO_CHAR(vl_total_importe_exento_02,'fm9999999990.00')||vl_base_close
                                                                ||vl_importe_tras_op||'0.00'||vl_importe_tras_close
                                                                ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close
                                                                ||vl_tasa_cta_op||'0.000000'||vl_tasa_cta_close
                                                                ||vl_tipo_fctr_op||'Exento'||vl_tipo_fctr_close
                                                                ||vl_traslado_close;
                                                                 
                                                     --   DBMS_OUTPUT.PUT_LINE('entra aqui 8001');
                                                        --  DBMS_OUTPUT.PUT_LINE('entra linea 7777');
                                       
                                       vl_out:= vl_cabecero_cont||vl_datos_factura_cont||vl_out
                                            ||vl_impuestos_op/*||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close*/                                
                                            ||vl_tot_impuestos_tras||vl_totalImpuestosTrasladados||vl_tot_impuestos_tras_close
                                            ||vl_concepto_objImp02
                                           /* ||vl_traslado_op||vl_base_op||vl_total_importe||vl_base_close||vl_importe_tras_op||vl_totalImpuestosTrasladados||vl_importe_tras_close
                                            ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close||vl_traslado_close*/
                                            ||vl_impuestos_close||vl_info_facto_op||vl_factu_auto_op||vl_factu_auto||vl_factu_auto_close||vl_folios_facto_op||vl_folios_facto||vl_folios_facto_close||vl_id_integracion_op||vl_id_integracion_value||vl_id_integracion_close||vl_integracion_op||vl_integracion||vl_integracion_close||vl_info_facto_close
                                            ||vl_xml_final||vl_cabecero_close;
                                            
                                       
                            else
                                vl_out:= vl_cabecero_cont||vl_datos_factura_cont||vl_out
                                    /*||vl_impuestos_op||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close
                                    ||vl_tot_impuestos_tras||vl_totalImpuestosTrasladados||vl_tot_impuestos_tras_close||vl_traslado_op||vl_base_op||vl_total_importe||vl_base_close||vl_importe_tras_op||vl_totalImpuestosTrasladados||vl_importe_tras_close
                                    ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close||vl_traslado_close
                                    ||vl_impuestos_close*/||vl_info_facto_op||vl_factu_auto_op||vl_factu_auto||vl_factu_auto_close||vl_folios_facto_op||vl_folios_facto||vl_folios_facto_close||vl_id_integracion_op||vl_id_integracion_value||vl_id_integracion_close||vl_integracion_op||vl_integracion||vl_integracion_close||vl_info_facto_close
                                    ||vl_xml_final||vl_cabecero_close;
                            end if;    
                        else
                            if vl_totalImpuestosTrasladados >= 0 then
                               vl_total_importe := vl_total_importe - vl_total_importe_exento;
                            --   DBMS_OUTPUT.PUT_LINE('entra linea 7816 vl_total_importe '||vl_total_importe||' vl_total_importe_exento '||vl_total_importe_exento);
                            end if;

                            if vl_tipo_factor_impuesto_final = 'Tasa' and ( vl_totalImpuestosTrasladados = 0 or vl_totalImpuestosTrasladados = 0.00  ) then
                                vl_total_importe := vl_tasa_cero;

                            end if;

                          --  DBMS_OUTPUT.PUT_LINE('entra linea 8025');
                           vl_out:= vl_cabecero_cont||vl_datos_factura_cont||vl_out
                                ||vl_impuestos_op/*||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close*/                                
                                ||vl_tot_impuestos_tras||vl_totalImpuestosTrasladados||vl_tot_impuestos_tras_close||vl_traslado_op||vl_base_op||vl_total_importe||vl_base_close||vl_importe_tras_op||vl_totalImpuestosTrasladados||vl_importe_tras_close
                                ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close||vl_traslado_close
                                ||vl_impuestos_close||vl_info_facto_op||vl_factu_auto_op||vl_factu_auto||vl_factu_auto_close||vl_folios_facto_op||vl_folios_facto||vl_folios_facto_close||vl_id_integracion_op||vl_id_integracion_value||vl_id_integracion_close||vl_integracion_op||vl_integracion||vl_integracion_close||vl_info_facto_close
                                ||vl_xml_final||vl_cabecero_close;


                       end if;

                     /*
                      vl_out:= vl_soap||vl_comprobante||vl_envio_cfdi||vl_emisor||vl_receptor||vl_xml_final||vl_out--||vl_concepto_balance
                                ||vl_totalImpuestosRet_tag||vl_totalImpuestosRetenidos||'" '||vl_totalImpTras_tag||vl_totalImpuestosTrasladados||'"> '||vl_open_tag||vl_traslados_tag
                                ||vl_impuesto_tag||vl_impuesto_cod||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto_final||vl_tasa_cuota_impuesto_tag
                                ||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_totalImpuestosTrasladados||'"'||vl_close_tag
                                ||vl_impuestos_close_tag||vl_tipo_operacion_tag||vl_tipo_operacion||vl_tipo_operacion_close_tag||vl_cierre;
                     */
                   END;


                 ELSIF vl_balance =0 AND vl_chg_tran_numb > 0 OR vl_chg_tran_numb = 0 THEN



                   BEGIN

                        FOR C IN (SELECT TZTCONC_CONCEPTO_CODE, TZTCONC_CONCEPTO,
                                CASE
                                    WHEN TZTCON_MONEDA <> 'CLP' THEN
                                    TO_CHAR(TZTCONC_MONTO,'fm9999999990.00')
                                    WHEN TZTCON_MONEDA = 'CLP' THEN
                                    TO_CHAR(TZTCONC_MONTO)
                                END TZTCONC_MONTO,
                                CASE
                                    WHEN TZTCON_MONEDA <> 'CLP' THEN
                                    TO_CHAR(TZTCONC_SUBTOTAL,'fm9999999990.00')
                                    WHEN TZTCON_MONEDA = 'CLP' THEN
                                    TO_CHAR(TZTCONC_SUBTOTAL)
                                END IMPORTE_CONCEPTO,
                                CASE
                                    WHEN TZTCON_MONEDA <> 'CLP' THEN
                                    TO_CHAR(NVL(TZTCONC_IVA,'0.00'),'fm9999999990.00')
                                    WHEN TZTCON_MONEDA = 'CLP' THEN
                                    TO_CHAR(TZTCONC_IVA)
                                END TZTCONC_IVA,
                                TVRDCTX_TXPR_CODE TIPO_IVA ,
                                TZTCONC_DCAT_CODE CRTGO_CODE
                                FROM TZTCONT, TVRDCTX, TVRTPDC a
                            WHERE 1=1
                            AND TZTCONC_CONCEPTO_CODE = TVRDCTX_DETC_CODE
                            AND TVRTPDC_TXPR_CODE = TVRDCTX_TXPR_CODE
                            And a.TVRTPDC_DATE_FROM = (select max (b.TVRTPDC_DATE_FROM)
                                                  from TVRTPDC b
                                                  Where a.TVRTPDC_TXPR_CODE = b.TVRTPDC_TXPR_CODE)
                            AND TZTCONC_PIDM = d_fiscales.pidm
                            AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion

                        )LOOP
                                --vl_out:=NULL;
                                --vl_concepto:=NULL;

                                vl_numIdentificacion:= Null;
                                vl_descripcion:= Null;
                                vl_valorUnitario:= Null;
                                vl_importe:= Null;
                                vl_crtgo_code := Null;
                                vl_totalImpuestosTrasladados:=NULL;
                                vl_total_importe:=NULL;

                                vl_numIdentificacion:= c.TZTCONC_CONCEPTO_CODE;
                                vl_descripcion:= c.TZTCONC_CONCEPTO;
                                vl_valorUnitario :=c.TZTCONC_MONTO;
                                vl_importe := C.IMPORTE_CONCEPTO;
                                vl_iva := c.TZTCONC_IVA;
                                vl_tipo_impuesto:=c.TIPO_IVA;
                                vl_crtgo_code := c.CRTGO_CODE;



                        IF
                         vl_tipo_impuesto ='IVE' AND vl_crtgo_code != 'APF' THEN

                         vl_tipo_factor_impuesto_final:='Exento';
                         vl_tasa_cuota_impuesto:= '0.000000';

                        ELSIF
                             vl_tipo_impuesto ='IVP' AND vl_crtgo_code != 'APF' THEN
                             vl_tipo_factor_impuesto:='Tasa';
                             vl_tipo_factor_impuesto_final:='Tasa';
                             vl_tasa_cuota_impuesto:='0.000000';

                        ELSIF
                         vl_tipo_impuesto ='IVA' AND vl_crtgo_code != 'APF' THEN
                         vl_tipo_factor_impuesto_final:='Tasa';
                         vl_tasa_cuota_impuesto:= '0.160000';

                        END IF;

                       --DBMS_OUTPUT.PUT_LINE ('Entra en balance = 0 y vl_chg_tran_numb >0 o vl_chg_tran_numb = 0**'||vl_balance||'*'||vl_chg_tran_numb||'*'||vl_tipo_factor_impuesto_final||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion);

                            BEGIN

                                 BEGIN
                                    SELECT TZTCON_MONEDA
                                    INTO vl_tipo_moneda
                                    FROM TZTCONT
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                                    GROUP BY TZTCON_MONEDA;
                                 EXCEPTION WHEN OTHERS THEN
                                 vl_tipo_moneda:='MXN';
                                 END;

                                IF vl_tipo_moneda <> 'CLP' THEN

                                   BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0.00'), 'fm9999999990.00'),TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                    INTO vl_totalImpuestosTrasladados, vl_total_importe
                                    FROM  TZTCONT
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0.00';
                                   vl_total_importe:='0.00';
                                   END;

                        --           DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'*aqui*************'||vl_tipo_factor_impuesto_final);

                                ELSIF vl_tipo_moneda = 'CLP' THEN

                                   BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0')),TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                    INTO vl_totalImpuestosTrasladados, vl_total_importe
                                    FROM  TZTCONT
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0';
                                   vl_total_importe:='0.00';
                                   END;

                                END IF;

                            END;

                        IF
                         vl_totalImpuestosTrasladados <> 0 THEN
                         vl_tipo_factor_impuesto_final:='Tasa';
                         vl_tasa_cuota_impuesto:= '0.160000';


                          BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0.00'), 'fm9999999990.00'),TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                    INTO vl_totalImpuestosTrasladados, vl_total_importe
                                    FROM  TZTCONT
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                                 --   and TZTCONC_IVA>0
                                    ;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0.00';
                                   vl_total_importe:='0.00';
                                   END;


                        END IF;

                      END LOOP;

                   /*     if vl_tipo_factor_impuesto_final='Tasa' then

                            BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                    INTO vl_total_importe
                                    FROM  TZTCONT
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                                    and TZTCONC_IVA>0;
                                   EXCEPTION WHEN OTHERS THEN

                                    vl_total_importe:='0.00'; --Agregué sum de subtotal paa el nodo base en total de impuestos trasladados
                                   END;

                       end if;
                       if vl_tipo_factor_impuesto_final='Exento' then

                            BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_SUBTOTAL),'0.00'), 'fm9999999990.00')
                                    INTO vl_total_importe
                                    FROM  TZTCONT
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                                    and TZTCONC_IVA=0;
                                   EXCEPTION WHEN OTHERS THEN

                                    vl_total_importe:='0.00'; --Agregué sum de subtotal paa el nodo base en total de impuestos trasladados
                                   END;

                       end if;*/

                      --vl_totalImpuestosRetenidos:= vl_totalImpuestosTrasladados;
                        --se quito para probar si funciona despues de asignar el valor de 03 a objetoimp
                        --vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||
                         -- ||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close --tambien se quitó
                         --Se elimina nodo impuestos e impuestos trasladados para todos los casos cuando es obj imp=3 07/06/2023


                       if vl_tipo_factor_impuesto_final= 'Exento' then
                       
                              if vl_ObjImp_02_Exento='SI' then
                                    
                                   -- vl_tipo_factor_impuesto_final:='Exento';
                                     vl_concepto_objImp02:=   vl_traslado_op
                                                                ||vl_base_op|| TO_CHAR(vl_total_importe_exento_02,'fm9999999990.00')||vl_base_close
                                                                ||vl_importe_tras_op||'0.00'||vl_importe_tras_close
                                                                ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close
                                                                ||vl_tasa_cta_op||'0.000000'||vl_tasa_cta_close
                                                                ||vl_tipo_fctr_op||'Exento'||vl_tipo_fctr_close
                                                                ||vl_traslado_close;
                                                                 
                                                    --    DBMS_OUTPUT.PUT_LINE('entra aqui 7971');
                                                        --  DBMS_OUTPUT.PUT_LINE('entra linea 7777');
                                       
                                    vl_out:= vl_cabecero_cont||vl_datos_factura_cont||vl_out
                                            ||vl_impuestos_op                                
                                            ||vl_tot_impuestos_tras||vl_totalImpuestosTrasladados||vl_tot_impuestos_tras_close
                                            ||vl_concepto_objImp02
                                           /* ||vl_traslado_op||vl_base_op||TO_CHAR(vl_total_importe_exento_02,'fm9999999990.00')||vl_base_close||vl_importe_tras_op||vl_totalImpuestosTrasladados||vl_importe_tras_close
                                            ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close||vl_traslado_close*/
                                            ||vl_impuestos_close||vl_info_facto_op||vl_factu_auto_op||vl_factu_auto||vl_factu_auto_close||vl_folios_facto_op||vl_folios_facto||vl_folios_facto_close||vl_id_integracion_op||vl_id_integracion_value||vl_id_integracion_close||vl_integracion_op||vl_integracion||vl_integracion_close||vl_info_facto_close
                                            ||vl_xml_final||vl_cabecero_close;
                                            
                                       
                            else
                                     vl_out:= vl_cabecero_cont||vl_datos_factura_cont||vl_out
                                    /*||vl_impuestos_op||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close
                                    ||vl_tot_impuestos_tras||vl_totalImpuestosTrasladados||vl_tot_impuestos_tras_close||vl_traslado_op||vl_base_op||vl_total_importe||vl_base_close||vl_importe_tras_op||vl_totalImpuestosTrasladados||vl_importe_tras_close
                                    ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close||vl_traslado_close
                                    ||vl_impuestos_close*/ ||vl_info_facto_op||vl_factu_auto_op||vl_factu_auto||vl_factu_auto_close||vl_folios_facto_op||vl_folios_facto||vl_folios_facto_close||vl_id_integracion_op||vl_id_integracion_value||vl_id_integracion_close||vl_integracion_op||vl_integracion||vl_integracion_close||vl_info_facto_close
                                    ||vl_xml_final||vl_cabecero_close;
                            end if;
                       else
                     --   DBMS_OUTPUT.PUT_LINE('entra linea 8041  vl_total_importe '|| vl_total_importe ||' vl_total_importe_exento '||vl_total_importe_exento ||' vl_tasa_cero '|| vl_tasa_cero);
                            if vl_totalImpuestosTrasladados >= 0 then
                              vl_total_importe := vl_total_importe - vl_total_importe_exento - vl_total_importe_exento_02;
                            --   DBMS_OUTPUT.PUT_LINE('entra linea 8283  vl_total_importe '|| vl_total_importe ||' vl_total_importe_exento '||vl_total_importe_exento);
                                   if vl_tasa_cero >  0 and  vl_totalImpuestosTrasladados > 0 then

                                    vl_concepto_tasa_cero:=   vl_traslado_op
                                                            ||vl_base_op||vl_tasa_cero||vl_base_close
                                                            ||vl_importe_tras_op||'0.00'||vl_importe_tras_close
                                                            ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close
                                                            ||vl_tasa_cta_op||'0.000000'||vl_tasa_cta_close
                                                            ||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close
                                                            ||vl_traslado_close;

                                end if;
                            end if;

                            if vl_tipo_factor_impuesto_final = 'Tasa' and ( vl_totalImpuestosTrasladados = 0 or vl_totalImpuestosTrasladados = 0.00  ) then
                          --   DBMS_OUTPUT.PUT_LINE('entra linea 8053  vl_total_importe '|| vl_total_importe ||' vl_total_importe_exento '||vl_total_importe_exento);
                                vl_total_importe := vl_tasa_cero;
                            end if;

--DBMS_OUTPUT.PUT_LINE('entra linea 8278  vl_total_importe '|| vl_total_importe ||' vl_total_importe_exento_02 '||vl_total_importe_exento_02);

                        if vl_ObjImp_02_Exento='SI' and vl_total_importe_exento_02> 0 then
                                    
                                   -- vl_tipo_factor_impuesto_final:='Exento';
                                     vl_concepto_objImp02:=   vl_traslado_op
                                                                ||vl_base_op|| TO_CHAR(vl_total_importe_exento_02,'fm9999999990.00')||vl_base_close
                                                                ||vl_importe_tras_op||'0.00'||vl_importe_tras_close
                                                                ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close
                                                                ||vl_tasa_cta_op||'0.000000'||vl_tasa_cta_close
                                                                ||vl_tipo_fctr_op||'Exento'||vl_tipo_fctr_close
                                                                ||vl_traslado_close;
                                                                 
                                                     --   DBMS_OUTPUT.PUT_LINE('entra aqui 8309');
                       end if;
                          vl_out:= vl_cabecero_cont||vl_datos_factura_cont||vl_out
                            ||vl_impuestos_op/*||vl_tot_impuestos_ret||vl_totalImpuestosRetenidos||vl_tot_impuestos_ret_close*/
                            ||vl_tot_impuestos_tras||vl_totalImpuestosTrasladados||vl_tot_impuestos_tras_close
                            ||vl_concepto_tasa_cero
                            ||vl_concepto_objImp02
                            ||vl_traslado_op||vl_base_op||vl_total_importe||vl_base_close||vl_importe_tras_op||vl_totalImpuestosTrasladados||vl_importe_tras_close
                            ||vl_impuesto_op||vl_impuesto_cod||vl_impuesto_close||vl_tasa_cta_op||vl_tasa_cuota_impuesto||vl_tasa_cta_close||vl_tipo_fctr_op||vl_tipo_factor_impuesto_final||vl_tipo_fctr_close||vl_traslado_close
                            ||vl_impuestos_close||vl_info_facto_op||vl_factu_auto_op||vl_factu_auto||vl_factu_auto_close||vl_folios_facto_op||vl_folios_facto||vl_folios_facto_close||vl_id_integracion_op||vl_id_integracion_value||vl_id_integracion_close||vl_integracion_op||vl_integracion||vl_integracion_close||vl_info_facto_close
                            ||vl_xml_final||vl_cabecero_close;
                       end if;


                            /*
                            ||vl_totalImpuestosRet_tag||vl_totalImpuestosRetenidos||'" '||vl_totalImpTras_tag||vl_totalImpuestosTrasladados||'"> '||vl_open_tag||vl_traslados_tag
                            ||vl_impuesto_tag||vl_impuesto_cod||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto_final||vl_tasa_cuota_impuesto_tag
                            ||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_totalImpuestosTrasladados||'"'||vl_close_tag
                            ||vl_impuestos_close_tag||vl_tipo_operacion_tag||vl_tipo_operacion||vl_tipo_operacion_close_tag||vl_cierre;*/

                    END;

                 END IF;

                END;

            vl_valida_conc:=0;

            BEGIN
            SELECT COUNT(1)
            INTO vl_valida_conc
            FROM TZTCONT
            WHERE 1=1
            AND TZTCONC_PIDM = vl_pidm
            AND TZTCONC_TRAN_NUMBER = vl_transaccion;
            EXCEPTION WHEN OTHERS THEN
            vl_valida_conc:=0;
            END;

            --/*
            IF vl_valida_conc > 0 THEN

            vl_pago_fecha_pago:= Null;
             BEGIN
                SELECT DISTINCT TRUNC (CAST(to_timestamp_tz(vl_fecha_pago,
                'yyyy-mm-dd"T"hh24:mi:sstzh:tzm') at time zone to_char(systimestamp,
                'tzh:tzm') AS DATE) ) TZTFACT_FECHA_PAGO
                INTO vl_pago_fecha_pago
                from DUAL;
                Exception
                When Others then
                null;
             End;



             BEGIN
                insert into TZTFCTU
                (tztfact_pidm,
                 tztfact_rfc,
                 tztfact_monto,
                 tztfact_tipo_docto,
                 tztfact_status_fact,
                 tztfact_uuii,
                 tztfact_fecha_proceso,
                 tztfact_tran_number,
                 tztfact_text,
                 tztfact_folio,
                 tztfact_serie,
                 tztfact_respuesta,
                 tztfact_error,
                 tztfact_xml,
                 tztfact_tipo,
                 tztfact_tipo_fact,
                 tztfact_tipo_pago,
                 tztfact_stst_timbrado,
                 tztfact_rvoe,
                 tztfact_subt,
                 tztfact_iva,
                 tztfact_nivel,
                 tztfact_fecha_pago,
                 tztfact_curp)
                 values
                 (vl_pidm,
                 vl_rfc2,
                 vl_pago_monto_pagado,
                 'FA',
                 Null,
                 Null,
                 sysdate,
                 vl_transaccion,
                 Null,
                 vl_consecutivo,
                 'BH',
                 Null, --5 Detener
                 Null,
                 vl_out,
                 vl_tipo_archivo,
                 vl_tipo_fact,
                 Null,
                 vl_tipo_operacion,
                 vl_subtotal, --Null,
                 vl_totalImpuestosTrasladados,--Null,
                 vl_pago_total, --Null,
                 Null,
                 vl_pago_fecha_pago,
                 Null);
                EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
                INSERT INTO TZTLOFA
                VALUES (vl_pidm,
                        vl_matricula,
                        vl_transaccion,
                        'Restriccion unica violada NT',
                        SYSDATE,
                        USER,
                        'TZTCONC',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        vl_seq_no);
                --THEN raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM||'PIDM- '||vl_pidm);
                END;
           ELSE
           NULL;

           END IF;

          --*/

           /*
           IF vl_valida_conc > 0 THEN
           null;
           DBMS_OUTPUT.PUT_LINE(vl_out);
           END IF;

          */

          END LOOP;

        COMMIT;

    END SP_GENERA_XML_NT;



    PROCEDURE SP_STOP_FA_GENEX

    -- procedimiento creado para detener facturas cuando se estaba validando el tipo d ecambio en las facturas con RFC gen rico EXTRANJERO--

    IS

    BEGIN

            FOR c IN (
                    SELECT TZTCRTE_PIDM pidm, TZTCRTE_CAMPO10 tran, TO_CHAR(TZTFACT_FECHA_PROCESO, 'DD/MM/YYYY') fecha_proceso, TZTFACT_RESPUESTA resp
                    FROM TZTCRNT, TZTFCTU
                    WHERE 1=1
                    AND TZTCRTE_PIDM = TZTFACT_PIDM
                    AND TZTCRTE_CAMPO10 = TZTFACT_TRAN_NUMBER
                    AND TZTCRTE_CAMP IN (SELECT ZSTPARA_PARAM_VALOR
                                         FROM ZSTPARA
                                         WHERE 1=1
                                         AND ZSTPARA_MAPA_ID = 'FA_GENEX')
                    AND TZTFACT_FECHA_PROCESO >= '23/02/2022'
                    AND TZTFACT_RESPUESTA = '5'
            )


            LOOP

                BEGIN

                    UPDATE TZTFCTU SET TZTFACT_RESPUESTA = '8', TZTFACT_ERROR = 'Factura retenida para validaci n tipo ce cambio en moneda'
                    WHERE 1=1
                    AND TZTFACT_PIDM = c.pidm
                    AND TZTFACT_TRAN_NUMBER = c.tran
                    AND TZTFACT_RESPUESTA = c.resp;
                EXCEPTION WHEN OTHERS THEN
                NULL;
                END;


            END LOOP;



            BEGIN

                BEGIN

                    UPDATE TZTFCTU SET TZTFACT_RESPUESTA = Null
                    WHERE 1=1
                    AND TZTFACT_FECHA_PROCESO >= '23/02/2022'
                    AND TZTFACT_RESPUESTA = '5';

                EXCEPTION WHEN OTHERS THEN
                NULL;
                END;

            END;


        COMMIT;


    END SP_STOP_FA_GENEX;


    FUNCTION  F_REQUEST_OUT RETURN PKG_FACTURACION_NT.crsr_req_out
    AS
        c_req_out PKG_FACTURACION_NT.crsr_req_out;

    BEGIN

        BEGIN

            OPEN c_req_out FOR
                SELECT TZTFACT_PIDM pidm,
                TZTFACT_RFC rfc,
                TZTFACT_TRAN_NUMBER transaccion,
                TZTFACT_SERIE serie,
                TZTFACT_FOLIO folio,
                TZTFACT_XML request
                FROM TZTFCTU
                WHERE 1=1
                AND TZTFACT_TIPO_DOCTO = 'FA'
                AND TRUNC(TZTFACT_FECHA_PROCESO) BETWEEN TRUNC(SYSDATE,'MM') AND TRUNC(SYSDATE)
                AND TZTFACT_RESPUESTA IS NULL
                ORDER BY TZTFACT_FECHA_PROCESO ASC;
                --AND TRUNC(TZTFACT_FECHA_PROCESO) = '18/09/2021';


        RETURN(c_req_out);
        END;


    END;


    FUNCTION F_UPDATE_REQUEST (p_pidm in number, p_rfc in varchar2, p_tran in number, p_serie in varchar2, p_folio in varchar2, p_resp_code in number, p_resp_desc in varchar2) RETURN VARCHAR2
    AS

    vl_return varchar2(250);

    BEGIN

        UPDATE TZTFCTU
        SET TZTFACT_FECHA_PROCESO = SYSDATE, TZTFACT_RESPUESTA = p_resp_code, TZTFACT_ERROR = p_resp_desc
        WHERE 1=1
        AND TZTFACT_PIDM = p_pidm
        AND TZTFACT_RFC = p_rfc
        AND TZTFACT_TRAN_NUMBER = p_tran
        AND TZTFACT_SERIE = p_serie
        AND TZTFACT_FOLIO = p_folio;
    COMMIT;
    vl_return:='Exito: '||p_pidm||'-'||p_tran||'-'||p_folio;
    RETURN(vl_return);
    EXCEPTION WHEN OTHERS THEN
    vl_return:='Error al actualizar'||SQLERRM;
    RETURN vl_return;
    END;



  PROCEDURE SP_BORRA_FAC_MAX72
   IS

   BEGIN
    DELETE TZTFCTU
    WHERE 1=1
    AND TZTFACT_RESPUESTA = 0
    AND
    (
           TZTFACT_ERROR LIKE '%La fecha de generaci n est  fuera de los rangos establecidos%'
        OR TZTFACT_ERROR LIKE '%Fecha y hora de generaci n fuera de rango%'
        OR TZTFACT_ERROR LIKE '%La fecha de emisi n est  fuera de rango%'
        OR TZTFACT_ERROR LIKE '%La fecha de generaci n no debe de ser mayor a 72%'
    )
    ;
    COMMIT;
  EXCEPTION WHEN OTHERS THEN
  NULL;
  END SP_BORRA_FAC_MAX72;




END PKG_FACTURACION_NT;
/

DROP PUBLIC SYNONYM PKG_FACTURACION_NT;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FACTURACION_NT FOR BANINST1.PKG_FACTURACION_NT;
