DROP PACKAGE BODY BANINST1.PKG_FACTURACION_MANUAL;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_FACTURACION_MANUAL IS


PROCEDURE SP_CARGA_FM
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
                FROM TBRACCD, SPRIDEN, SPREMRG s, TBBDETC
                WHERE 1=1
                AND substr (spriden_id,1,2) IN (SELECT ZSTPARA_PARAM_ID
                                                FROM ZSTPARA
                                                WHERE 1=1
                                                AND ZSTPARA_MAPA_ID = 'FM_OPM')
                AND TBRACCD_PIDM= SPRIDEN_PIDM
                AND SPRIDEN_CHANGE_IND IS NULL
                AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                AND TBBDETC_TYPE_IND = 'P'
                AND TBBDETC_DCAT_CODE = 'CSH'
                AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                           FROM TZTFACT--
                                           WHERE 1=1
                                           AND TBRACCD_PIDM = TZTFACT_PIDM)
               AND TBRACCD_PIDM = s.SPREMRG_PIDM              
               AND TRUNC(TBRACCD_ENTRY_DATE)  BETWEEN TRUNC(SYSDATE,'MM') AND TRUNC(SYSDATE)
               AND TBRACCD_AMOUNT >= 1
             --  and tbraccd_pidm = 305977
               GROUP BY SPRIDEN_PIDM, SPRIDEN_ID, SPRIDEN_FIRST_NAME, TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_AMOUNT, TBRACCD_STSP_KEY_SEQUENCE, TBRACCD_BALANCE, TBRACCD_ENTRY_DATE
               ORDER BY TBRACCD_ENTRY_DATE ASC
               
       )
       LOOP -- PRIMER LOOP-- 
            ---INSERTA EN TZTCRTE LO QUE SE HACE EN PKG_REPORTES1.sp_pagos_facturacion_dia--
                        
          --DBMS_OUTPUT.PUT_LINE('Datos recuperados '|| f.SPRIDEN_PIDM||' '||f.TRUNC_DATE||' '||f.TBRACCD_ENTRY_DATE);      
          
            
          BEGIN
          
                    for a in (SELECT TZTCRTE_PIDM pidm, TZTCRTE_CAMPO10 tran_number, TZTCRTE_TIPO_REPORTE tipo_reporte
                               FROM TZTCRTE
                               WHERE TZTCRTE_TIPO_REPORTE in ( 'Pago_Facturacion_dia', 'Facturacion_dia')
                               AND TZTCRTE_PIDM = f.SPRIDEN_PIDM 
                               AND TZTCRTE_CAMPO10  = f.TBRACCD_TRAN_NUMBER 
                               )
                    LOOP
                           BEGIN
                            delete TZTCRTE
                            where 1=1
                            and TZTCRTE_PIDM = a.pidm 
                            and TZTCRTE_CAMPO10  = a.tran_number
                            and TZTCRTE_TIPO_REPORTE = a.tipo_reporte;
                           END;
                           
                           BEGIN
                            delete TZTCONC
                            WHERE 1=1
                            AND TZTCONC_PIDM = a.pidm
                            AND TZTCONC_TRAN_NUMBER = a.tran_number                 
                            And (TZTCONC_PIDM, TZTCONC_TRAN_NUMBER) not in (select TZTFACT_PIDM,  TZTFACT_TRAN_NUMBER
                                                                            from tztfact);
                           END;
                    end LOOP;
            Exception
            When others then
            null;
          End; 
          Commit; 
            
          Begin 
          
                   BEGIN
                           
                    delete TZTCONC
                    WHERE 1=1
                    AND TZTCONC_PIDM = f.spriden_pidm
                    AND TZTCONC_TRAN_NUMBER = f.tbraccd_tran_number
                     And (TZTCONC_PIDM, TZTCONC_TRAN_NUMBER) not in (select TZTFACT_PIDM,  TZTFACT_TRAN_NUMBER
                                                                     from tztfact);                  
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
                                          SARADAP_LEVL_CODE Nivel,
                                          CASE WHEN LENGTH(SPREMRG_MI) BETWEEN 1 AND 20 THEN
                                          SPREMRG_MI
                                          END RFC,
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
                                          'Bloque1' bloque
                                        from SPREMRG s
                                        join SPRIDEN on s.SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
                                        join TBRACCD on s.SPREMRG_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE)= f.TRUNC_DATE  AND TBRACCD_PIDM =  f.spriden_pidm  AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER
                                        join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                        join SARADAP on SARADAP_PIDM = s.SPREMRG_PIDM AND SARADAP_APPL_NO = vl_appl_no AND SARADAP_PROGRAM_1 = vl_program
                                        left join GORADID on GORADID_PIDM = s.SPREMRG_PIDM AND GORADID_ADID_CODE LIKE'REF%'
                                        left join GOREMAL on GOREMAL_PIDM = s.SPREMRG_PIDM AND GOREMAL_EMAL_CODE in ('PRIN')
                                        left join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                                        left join colegiatura on  colegiatura.pidm = spriden_pidm AND colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                                        left join curp on curp.PIDM = SPRIDEN_PIDM 
                                        where 1=1
                                          and TBBDETC_TYPE_IND = 'P'
                                          and TBBDETC_DCAT_CODE = 'CSH'
                                          And TBRACCD_AMOUNT >= 1
                                          and s.SPREMRG_PRIORITY = (select MAX(s1.SPREMRG_PRIORITY) 
                                                                    FROM SPREMRG s1
                                                                    where s.SPREMRG_PIDM = s1.SPREMRG_PIDM)
                                        GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, saradap_camp_code, SARADAP_LEVL_CODE, s.SPREMRG_MI,
                                                        REPLACE(s.SPREMRG_STREET_LINE1,'"',' ') || ' ' ||REPLACE(s.SPREMRG_STREET_LINE2,'"',' ') || ' ' || REPLACE(s.SPREMRG_STREET_LINE3,'"',' '), s.SPREMRG_CITY, s.SPREMRG_STREET_LINE3,
                                                        s.SPREMRG_ZIP, s.SPREMRG_NATN_CODE, tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_ENTRY_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                                        GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                                        curp.CURP, SARADAP_DEGC_CODE_1, SARADAP_PROGRAM_1,TBRACCD_BALANCE 
                       
                                                                
                                     ) loop
                                                                          
                                      vl_consecutivo := 0;

                                           BEGIN
                                            SELECT NVL(MAX(TZTCRTE_CAMPO57), 0) +1
                                                INTO vl_consecutivo
                                            FROM TZTCRTE
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
                                         Insert into TZTCRTE values (a.pidm, --TZTCRTE_PIDM
                                                                        a.matricula, --TZTCRTE_ID
                                                                        a.campus,--TZTCRTE_CAMP
                                                                        a.nivel,--TZTCRTE_LEVL
                                                                        a.nombre,--TZTCRTE_CAMPO1
                                                                        a.rfc,--TZTCRTE_CAMPO2 no se guarda RFC
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
                                                                        USER||'- EMONTADI_FM_OPM', --TZTCRTE_CAMPO59
                                                                        TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                                        'Pago_Facturacion_dia'--TZTCRTE_TIPO_REPORTE
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
                            FROM TZTCRTE
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
                            FROM TZTCRTE
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
                            FROM TZTCRTE
                            WHERE 1=1
                            AND TZTCRTE_PIDM = f.SPRIDEN_PIDM
                            AND TZTCRTE_CAMPO10= f.TBRACCD_TRAN_NUMBER
                            And TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia';
                            EXCEPTION
                            WHEN OTHERS THEN 
                            vl_consecutivo :=1;
                           END;
                                              
                            BEGIN
                            INSERT INTO TZTCRTE
                            SELECT
                            a.TZTCRTE_PIDM, a.TZTCRTE_ID, a.TZTCRTE_CAMP, a.TZTCRTE_LEVL, a.TZTCRTE_CAMPO1, 
                                a.TZTCRTE_CAMPO2, a.TZTCRTE_CAMPO3, a.TZTCRTE_CAMPO4, a.TZTCRTE_CAMPO5, a.TZTCRTE_CAMPO6, 
                                a.TZTCRTE_CAMPO7, a.TZTCRTE_CAMPO8, a.TZTCRTE_CAMPO9, a.TZTCRTE_CAMPO10, a.TZTCRTE_CAMPO11, 
                                a.TZTCRTE_CAMPO12, a.TZTCRTE_CAMPO13, a.TZTCRTE_CAMPO14,a.TZTCRTE_CAMPO58 * -1,Null, 'COLEGIATURA '||a.TZTCRTE_CAMPO21, 
                                'COL', Null, a.TZTCRTE_CAMPO20, a.TZTCRTE_CAMPO21, a.TZTCRTE_CAMPO22, Null, Null, Null, 
                                a.TZTCRTE_CAMPO26, TZTCRTE_CAMPO27, Null, Null, Null,Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null,
                                Null, Null, Null, Null ,Null, Null, Null, Null, Null, Null, Null, Null, Null,a.TZTCRTE_CAMPO56, vl_consecutivo,
                                a.TZTCRTE_CAMPO58, user||' - BALANCE DIRECCIONADO A COL', TRUNC(SYSDATE),'Pago_Facturacion_dia'
                            FROM TZTCRTE a
                            WHERE 1= 1
                            AND a.TZTCRTE_PIDM = f.SPRIDEN_PIDM
                            AND TO_NUMBER(a.TZTCRTE_CAMPO10) = f.TBRACCD_TRAN_NUMBER
                            AND a.TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                            AND a.TZTCRTE_CAMP is not null
                            AND a.TZTCRTE_CAMPO57 = (SELECT MAX(TZTCRTE_CAMPO57)
                                                   FROM TZTCRTE b
                                                   WHERE 1=1
                                                   AND a.TZTCRTE_PIDM =b.TZTCRTE_PIDM
                                                   AND a.TZTCRTE_CAMP = b.TZTCRTE_CAMP
                                                   AND a.TZTCRTE_CAMPO10 = b.TZTCRTE_CAMPO10);
                            EXCEPTION WHEN OTHERS THEN
                            DBMS_OUTPUT.PUT_LINE('ERROR AQUÍ '||f.SPRIDEN_PIDM||'-'||f.TBRACCD_TRAN_NUMBER||'-'||vl_consecutivo||SQLERRM);
                           END;
                           
                       ELSIF vl_balance like '-%' AND vl_valida_col > 0 THEN 
                                      
                        --dbms_output.put_line(vl_balance||'-'||vl_valida_col);
                                      
                        vl_new_balance := (vl_balance)*-1;
                                        
                        
                        BEGIN
                                        
                        UPDATE TZTCRTE a SET a.TZTCRTE_CAMPO15 = a.TZTCRTE_CAMPO15 + vl_new_balance, TZTCRTE_CAMPO59 = USER||'- CAMPO15 SUMADO CON BALANCE'
                        WHERE 1=1
                        AND a.TZTCRTE_PIDM = f.SPRIDEN_PIDM
                        AND a.TZTCRTE_CAMPO10 = f.TBRACCD_TRAN_NUMBER
                        AND a.TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                        AND a.TZTCRTE_CAMPO18 = 'COL'  
                        AND a.TZTCRTE_CAMPO16 = (SELECT min(TZTCRTE_CAMPO16)
                                                    FROM TZTCRTE b
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
                                            from TZTCRTE
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
                                            from TZTCRTE
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
                                            from TZTCRTE
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
                                            from TZTCRTE
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
                                            from TZTCRTE, intereses b, accesorios c, otros d, colegiatura e
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
                        FROM TZTCRTE
                        WHERE 1=1
                        AND TZTCRTE_PIDM = c.pidm
                        AND TZTCRTE_CAMPO10= c.Transaccion
                        And TZTCRTE_TIPO_REPORTE = 'Facturacion_dia';
                        EXCEPTION
                        WHEN OTHERS THEN 
                        vl_consecutivo :=1;
                       END;
                        

                      Insert into TZTCRTE values (c.pidm,--TZTCRTE_PIDM
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
                                                        USER||'- EMONTADI_FM_OPM', --TZTCRTE_CAMPO59,
                                                        TRUNC(SYSDATE),--TZTCRTE_CAMPO60
                                                        'Facturacion_dia'--TZTCRTE_TIPO_REPORTE
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
                FROM TZTCRTE
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
                                         When GORADID_ADID_CODE <> 'REFS' THEN --'('REFH', 'REFU') then 
                                          to_char (nvl(TBRAPPL_AMOUNT, TBRACCD_AMOUNT), 'fm9999999990.00')
                                          --to_char (nvl(TBRAPPL_AMOUNT+(TBRACCD_BALANCE*(-1)), TBRACCD_AMOUNT), 'fm9999999990.00')
                                        End  SUBTOTAL,
                                        case
                                         When   GORADID_ADID_CODE = 'REFS' then  
                                                 to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT) -    nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT) / 1.16,'fm9999999990.00')
                                         When GORADID_ADID_CODE <> 'REFS' THEN -- IN ('REFH', 'REFU') then
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
                                        when GORADID_ADID_CODE = 'REFI' then
                                         'IW'
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
                                        WHEN TBRACCD_DESC LIKE '%CREDITO%'THEN '04' --'%TARJETA CREDITO%'
                                        WHEN TBRACCD_DESC LIKE '%DEBITO%'THEN '28' --'%TARJETA DEBITO%'
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
                                        left join  TBRAPPL ON TBRAPPL_PIDM = TBRACCD_PIDM AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER AND TBRAPPL_REAPPL_IND IS NULL
                                        left join cargo on cargo.pidm = tbraccd_pidm and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                        join fiscal s on s.SPREMRG_PIDM = tbraccd_pidm --LEFT
                                        left join GORADID on GORADID_PIDM = TBRACCD_PIDM and GORADID_ADID_CODE LIKE 'REF%'
                                        left join tztordr on TZTORDR_PIDM = tbraccd_pidm  and  TZTORDR_CONTADOR = TBRACCD_RECEIPT_NUMBER
                                        WHERE TBBDETC_TYPE_IND = 'P'
                                        AND TBBDETC_DCAT_CODE = 'CSH'
                                        AND TBRACCD_TRAN_NUMBER  NOT IN (SELECT TZTCONC_TRAN_NUMBER  -- 02/12/2019
                                                                  FROM TZTCONC
                                                                  WHERE TBRACCD_PIDM = TZTCONC_PIDM)
                                        AND TRUNC (TBRACCD_ENTRY_DATE) = f.TRUNC_DATE --'02/12/2019' -- --'16/08/2019'
                                        AND TBRACCD_PIDM = f.SPRIDEN_PIDM --38543
                                        AND TBRACCD_TRAN_NUMBER = f.TBRACCD_TRAN_NUMBER --60
                                        --AND TBRACCD_DESC LIKE '%DEBITO%'
                                        )PAGOS_FACT
                                         WHERE 1=1
     
                              )LOOP
                               
                                    vl_tipo_impuesto:= Null;   
                                    vl_moneda:= Null;   
                                    vl_subtotal_accs:=Null;
                                    vl_iva_accs:= Null;
                                    vl_codpago := null;
                                    
                                    
                                    --CÓDIGO PARA BLINDAR EL CÓDIGO DE DETALLE DEL CARGO---
                                    
                                 
                                 If length (conceptos.clave_cargo) != 4 then 
                                       Begin 
                                                
                                                select distinct TBBDETC_DETAIL_CODE
                                                Into vl_codpago
                                                from tztordr, tbraccd, tbbdetc, TZTNCD
                                                where 1= 1 
                                                And TZTORDR_PIDM = tbraccd_pidm
                                                And TZTORDR_PIDM = conceptos.PIDM
                                                And TBRACCD_TRAN_NUMBER = conceptos.TRANSACCION
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
                                                    'TZTCONC_FM_OPM',
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
                                    Insert into TZTCONC values (conceptos.PIDM, --TZTCONC_PIDM
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
                                                              'FM',--TZTCONC_TIPO_DOCTO
                                                              conceptos.numero, --TZTCONC_SEQ_PAGO
                                                              conceptos.forma_pago, --TZTCONC_FORMA_PAGO
                                                              conceptos.transa,--TZTCONC_TRAN_PAGADA
                                                              TRUNC(SYSDATE), --TZTCONC_ACTIVITY_DATE
                                                              USER||'- EMONTADI_FM_OPM', --TZTCON_USER
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
    END SP_CARGA_FM; --CIERRA EL BEGIN GENERAL
    
    
    PROCEDURE SP_GENERA_XML_FM
IS
--GENERA XML
--DECLARE
 --VARIABLES DE CABECERO-- 
     
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
        vl_tipo_cambio number:=1;
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
        vl_enviar_xml varchar2(4):='1';
        vl_enviar_pdf varchar2(15):='1';
        vl_enviar_zip varchar2(15):='1';
        vl_emails varchar(100):='oscar.gonzalez@utel.edu.mx';
        --------------------------------------------------------------------------

        -- VARIABLES PARA EL COMPONENTE  emisor--
        vl_rfc_utel varchar2 (15); -- Variable para el RFC del emisor de la factura
        vl_razon_social_utel varchar2(250); --Variable para la razón social del emisor de la factura
        vl_regimen_fiscal varchar2(5):= '601'; -- variable que ocntiene el regimen fiscal del emisor
        vl_id_emisor_sto number:=1; --Emisor_STO
        vl_id_emisor_erp number:=1; --Emisor_ERP
        vl_idTipoReceptor number:=0;
        vl_correoR Varchar2(100);
        vl_emisor varchar(4000); --variable para almacenar concatenar los componentes del emisor


        -- VARIABLES PARA EL COMPONENTE  receptor--
        vl_receptor varchar(4000);
        vl_residencia_fiscal varchar2(100);
        vl_num_reg_id_trib varchar2(25);
        vl_uso_cfdi varchar2(25); --:='D10';
        vl_referencia_dom_receptor varchar2(224);
        vl_estatus_registro varchar2(25):='1';
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
        
        
        vl_flex_hdrs_tag varchar2(100):= 'flexHeaders';
        vl_flex_hdrs_clave varchar2(100):= 'clave'; 
        vl_flex_hdrs_nombre varchar2(100):='nombre';
        vl_flex_hdrs_valor varchar2(100):='valor';
        x number:= 0;
        vl_flxhdrs_nombre varchar2(224);
        vl_flxhdrs_valor varchar2(224);
        vl_metodo_pago_code varchar2(100);
        vl_pago_metodo_pago varchar2(100);
        vl_pago_id_pago varchar2(100);
        vl_pago_monto_pagado varchar2(100);
        vl_sum_bubtotal varchar2(100);
        vl_residuo varchar2(100);
        vl_pago_fecha_pago varchar2(100);
        vl_pago_monto_interes varchar2(100);
        vl_pago_tipo_accesorio varchar2(150);
        vl_pago_monto_accesorio varchar2(100);
        vl_pago_colegiaturas varchar2(100);
        vl_pago_monto_colegiatura varchar2(100);
        vl_pago_intereses varchar2(100);
        vl_obs varchar(250) := '.';
        ----------------------------------------------------------

        ---- VARIABLES HTML PARA EL COMPONENTE conceptos --|
        
        vl_claveProdserv_tag varchar2(30):='conceptos claveProdServ="';
        vl_conceptos_close_tag varchar2(30):= '</conceptos>';
        vl_cantidad_tag varchar2(30):= '" cantidad="';
        vl_clave_unidad_tag varchar2(30):=' claveUnidad="';
        vl_unidad_tag varchar2(30):= 'unidad="';
        vl_num_identificacion_tag varchar2(30):= ' numIdentificacion="';
        vl_descripcion_tag  varchar2(30):='" descripcion="';
        vl_valor_unitario_tag varchar2(30):= '" valorUnitario="';
        vl_importe_tag varchar2(30):= '" importe="';
        vl_descuento_tag varchar2(30):='" descuento="';
        
        ---- VARIABLES PARA EL COMPONENTE conceptos --|
        vl_prod_serv varchar2(20); --variable con el código de servicio--
        vl_cantidad_concepto varchar2(10):='1" ';
        vl_clave_unidad_concepto varchar2(10):='E48" ';
        vl_unidad_concepto varchar2(50):='Servicio" ';
        vl_numIdentificacion varchar2(150);
        vl_descripcion varchar2(50);
        vl_valorUnitario varchar2(50);
        vl_balance varchar2(50);
        vl_balance_1 varchar(50);
        vl_remanente varchar2(50);
        vl_importe varchar2(50);
        vl_descuento varchar2(15):='0.00';
        -----------------------------------------------------
        
        ---- VARIABLES HTML PARA EL COMPONENTE traslados --
        vl_impuestos_tag varchar2(30):='<impuestos>';
        vl_impuestos_close_tag varchar2(30):='</impuestos>';
        vl_traslados_tag varchar2(30):='trasladados ';
        vl_base_tag varchar2(30):='base="';
        vl_impuesto_tag varchar2(30):= ' impuesto="';
        vl_tipo_factor_tag varchar2(30):=' tipoFactor=';  
        vl_tasa_cuota_impuesto_tag varchar2(30):=' tasaOCuota="';
        vl_importe_tras_tag varchar2(30):= '" importe="';
        
        ---- VARIABLES PARA EL COMPONENTE traslados --

        vl_base varchar2(50);
        vl_impuesto_cod varchar2(10):='002';
        vl_tipo_impuesto varchar2(15);
        vl_tipo_factor_impuesto varchar2(15);
        vl_tipo_factor_impuesto_final varchar2(15);
        vl_tasa_cuota_impuesto varchar2(250); 
        vl_importe_tras  varchar2(30);
        vl_crtgo_code varchar2(6);        
        
        -----------------------------------------------
        
        
        ----VARIABLES  HTML COMPLEMENTO CONCEPTOS--
        vl_InstEducativas_tag varchar2(30):= '<InstEducativas>';
        vl_InstEducativas_close_tag varchar2(30):='</InstEducativas>';
        vl_autrvoe_tag varchar2(30) := '<autrvoe>';
        vl_autrvoe_close_tag varchar2(30) := '</autrvoe>';
        vl_curp_tag varchar2(30) := '<curp>';
        vl_curp__close_tag varchar2(30) := '</curp>';
        vl_nivelEducativo_tag varchar2(30) :='<nivelEducativo>';
        vl_nivelEducativo_close_tag varchar2(30) :='</nivelEducativo>';
        vl_nombreAlumno_tag varchar2(30):='<nombreAlumno>';
        vl_nombreAlumno_close_tag varchar2(30):='</nombreAlumno>';
        vl_numeroLinea_tag varchar2(30):='<numeroLinea>';
        vl_numeroLinea__close_tag varchar2(30):='</numeroLinea>';
        vl_rfcPago_tag varchar2(30) := '<rfcPago>';
        vl_rfcPago_close_tag varchar2(30) := '</rfcPago>';
        vl_version_tag varchar2(30) := '<version>';
        vl_version__close_tag varchar2(30) := '</version>';
        
        ----VARIABLES  COMPLEMENTO CONCEPTOS--
        vl_clave_rvoe varchar2(50);
        vl_curp varchar2(50);
        vl_niveleducativo varchar2(50);
        vl_nombrealumno varchar2(70);
        vl_numerolinea Varchar(10):='1';
        vl_rfc varchar2(50);
        vl_version varchar2(10):='1.0';  
        
        
        -----VARIABLES HTML IMPUESTO RETENIDO---
        vl_totalImpuestosRet_tag varchar2 (70):='<impuestos totalImpuestosRetenidos="';
        vl_totalImpTras_tag varchar2(70):= 'totalImpuestosTrasladados="';
        vl_totalImpuestosTrasladados varchar2(10);
        vl_totalImpuestosRetenidos varchar2(10):= '0.0';
        
        
        vl_tipo_operacion_tag varchar2(30):='<tipoOperacion>';
        vl_tipo_operacion_close_tag varchar2(30):='</tipoOperacion>';
        vl_tipo_operacion varchar2(30); --:='sincrono';
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
        
     BEGIN

        /*CURSOR PARA OBTENER LOS DATOS GENERALES,DE PAGO Y ADICIONALES DEL RECEPTOR(ALUMNO)*/
         FOR d_fiscales IN (SELECT a.TZTCRTE_PIDM pidm,
                    a.TZTCRTE_ID matricula,
                    NVL(REPLACE(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME,'.') nombre_alumno,
                    SUBSTR(TZTCRTE_ID,5) id,
                    REPLACE (a.TZTCRTE_CAMPO1, '&', '&'||'amp;') nombre,
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
                    TZTCRTE_CAMPO14 email,
                    CASE
                        WHEN a.TZTCRTE_CAMPO13 = 'REFI' THEN 'IW'
                        WHEN a.TZTCRTE_CAMPO13 = 'REFU' THEN 'UI'
                        WHEN a.TZTCRTE_CAMPO13  IS NULL THEN 'NI'
                    END serie,
                    a.TZTCRTE_CAMP campus,
                    a.TZTCRTE_CAMPO12 referencia,
                    a.TZTCRTE_CAMPO13 ref_tipo,
                    STVLEVL_DESC nivel,
                    a.TZTCRTE_CAMPO23 curp,
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
                    a.TZTCRTE_CAMPO11 fecha_pago,
                    a.TZTCRTE_CAMPO28 id_pago,  
                (SELECT distinct LISTAGG(TZTCRTE_CAMPO19, ', ') WITHIN GROUP (ORDER BY TZTCRTE_CAMPO19) over (partition by TZTCRTE_CAMPO10) LISTA_NOMBRES
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') tipo_accesorio ,  
                (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO20,0)),'fm9999999990.00')
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_accesorio ,
                    a.TZTCRTE_CAMPO15 colegiaturas,
                 (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO16,0)),'fm9999999990.00')
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_colegiatura ,
                    a.TZTCRTE_CAMPO17 as intereses,
                  (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO18,0)),'fm9999999990.00')
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    AND TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    AND TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_interes ,                    
                    TZTCRTE_CAMPO57 secuencia
                    FROM TZTCRTE a, SPRIDEN, STVLEVL,SZTDTEC r
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
                                                FROM TZTFACT
                                                WHERE TZTFACT_PIDM = a.TZTCRTE_PIDM
                                                AND TZTFACT_TRAN_NUMBER = a.TZTCRTE_CAMPO10)
                    AND TZTCRTE_CAMPO57 = (SELECT MAX(b.TZTCRTE_CAMPO57)
                                          FROM TZTCRTE b 
                                          WHERE 1=1
                                          AND b.TZTCRTE_PIDM = a.TZTCRTE_PIDM
                                          AND b.TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                                          AND b.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia')                                     
                    --AND TZTCRTE_PIDM = 262265 --2611 --38335 --180516 --71319 --99288 --224278 --79355  --117396 --2727 --222622
                    --AND TZTCRTE_CAMPO10 = 12 --70--91 --119--114 --43 --99 --131 --43
                    AND TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                    AND TZTCRTE_CAMPO2 IS NOT Null
                    AND SPRIDEN_PIDM IN (SELECT SARADAP_PIDM FROM saradap)
               --     and spriden_pidm = 305977
                    AND TZTCRTE_CAMP IN (SELECT ZSTPARA_PARAM_VALOR
                                         FROM ZSTPARA
                                         WHERE 1=1
                                         AND ZSTPARA_MAPA_ID = 'FM_OPM')
                    GROUP BY TZTCRTE_PIDM,TZTCRTE_ID,SPRIDEN_LAST_NAME,SPRIDEN_FIRST_NAME,TZTCRTE_CAMPO1,TZTCRTE_CAMPO2,TZTCRTE_CAMPO3,TZTCRTE_CAMPO27,TZTCRTE_CAMPO4,TZTCRTE_CAMPO5,TZTCRTE_CAMPO6,TZTCRTE_CAMPO14,
                             TZTCRTE_CAMPO20,TZTCRTE_CAMPO15,TZTCRTE_CAMPO13, TZTCRTE_CAMP, TZTCRTE_CAMPO12, TZTCRTE_CAMPO13, STVLEVL_DESC,TZTCRTE_CAMPO23,TZTCRTE_CAMPO24,SZTDTEC_NUM_RVOE,SZTDTEC_CLVE_RVOE,TZTCRTE_CAMPO10,
                             TZTCRTE_CAMPO9,TZTCRTE_CAMPO7,TZTCRTE_CAMPO8,TZTCRTE_CAMPO11,TZTCRTE_CAMPO19,TZTCRTE_CAMPO16, TZTCRTE_CAMPO17,TZTCRTE_CAMPO18, TZTCRTE_CAMPO28, TZTCRTE_CAMPO58, TZTCRTE_CAMPO57,
                             a.TZTCRTE_TIPO_REPORTE
           UNION
                    SELECT a.TZTCRTE_PIDM pidm,
                    a.TZTCRTE_ID matricula,
                    NVL(REPLACE(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME,'.') nombre_alumno,
                    SUBSTR(TZTCRTE_ID,5) id,
                    REPLACE (a.TZTCRTE_CAMPO1, '&', '&'||'amp;') nombre,
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
                    TZTCRTE_CAMPO14 email,
                    CASE
                        WHEN a.TZTCRTE_CAMPO13 = 'REFI' THEN 'IW'
                        WHEN a.TZTCRTE_CAMPO13 = 'REFU' THEN 'UI'
                        WHEN a.TZTCRTE_CAMPO13  IS NULL THEN 'NI'
                    END serie,
                    a.TZTCRTE_CAMP campus,
                    a.TZTCRTE_CAMPO12 referencia,
                    a.TZTCRTE_CAMPO13 ref_tipo,
                    STVLEVL_DESC nivel,
                    a.TZTCRTE_CAMPO23 curp,
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
                    a.TZTCRTE_CAMPO11 fecha_pago,
                    a.TZTCRTE_CAMPO28 id_pago,  
                (SELECT distinct LISTAGG(TZTCRTE_CAMPO19, ', ') WITHIN GROUP (ORDER BY TZTCRTE_CAMPO19) over (partition by TZTCRTE_CAMPO10) LISTA_NOMBRES
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') tipo_accesorio ,  
                (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO20,0)),'fm9999999990.00')
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_accesorio ,
                    a.TZTCRTE_CAMPO15 colegiaturas,
                    (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO16,0)),'fm9999999990.00')
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_colegiatura ,
                    a.TZTCRTE_CAMPO17 as intereses,
                     (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO18,0)),'fm9999999990.00')
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_interes ,                    
                    TZTCRTE_CAMPO57 secuencia
                    FROM TZTCRTE a, SPRIDEN, STVLEVL, SZVCAMP
                    WHERE 1=1
                    AND a.TZTCRTE_PIDM = SPRIDEN_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                    AND a.TZTCRTE_LEVL = STVLEVL_CODE
                    AND a.TZTCRTE_CAMP = SZVCAMP_CAMP_CODE
                    AND a.TZTCRTE_CAMPO10 NOT IN (SELECT TZTFACT_TRAN_NUMBER --NOT
                                          FROM TZTFACT
                                          WHERE TZTFACT_PIDM = a.TZTCRTE_PIDM
                                          AND TZTFACT_TRAN_NUMBER = a.TZTCRTE_CAMPO10)
                    AND TZTCRTE_CAMPO57 = (SELECT MAX(b.TZTCRTE_CAMPO57)
                                          FROM TZTCRTE b
                                          WHERE 1=1
                                          AND b.TZTCRTE_PIDM = a.TZTCRTE_PIDM
                                          AND b.TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                                          AND b.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia')               
                    --AND TZTCRTE_PIDM = 262265--38335 --180516 --71319 --99288 --224278 --79355  --117396 --2727 --222622
                    --AND TZTCRTE_CAMPO10 = 106--70--91 --119--114 --43 --99 --131 --43
                    AND TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                    AND TZTCRTE_CAMPO2 IS NOT Null
                    AND SPRIDEN_PIDM NOT IN (SELECT SARADAP_PIDM FROM saradap)
               --     and spriden_pidm = 305977
                     AND TZTCRTE_CAMP IN (SELECT ZSTPARA_PARAM_VALOR
                                         FROM ZSTPARA
                                         WHERE 1=1
                                         AND ZSTPARA_MAPA_ID = 'FM_OPM')
                    GROUP BY TZTCRTE_PIDM,TZTCRTE_ID,SPRIDEN_LAST_NAME,SPRIDEN_FIRST_NAME,TZTCRTE_CAMPO1,TZTCRTE_CAMPO2,TZTCRTE_CAMPO3,TZTCRTE_CAMPO27,TZTCRTE_CAMPO4,TZTCRTE_CAMPO5,TZTCRTE_CAMPO6,TZTCRTE_CAMPO14,
                             TZTCRTE_CAMPO20,TZTCRTE_CAMPO15,TZTCRTE_CAMPO13, TZTCRTE_CAMP, TZTCRTE_CAMPO12, TZTCRTE_CAMPO13, STVLEVL_DESC,TZTCRTE_CAMPO23,TZTCRTE_CAMPO24,TZTCRTE_CAMPO10,
                             TZTCRTE_CAMPO9,TZTCRTE_CAMPO7,TZTCRTE_CAMPO8,TZTCRTE_CAMPO11,TZTCRTE_CAMPO19,TZTCRTE_CAMPO16, TZTCRTE_CAMPO17,TZTCRTE_CAMPO18, TZTCRTE_CAMPO28, TZTCRTE_CAMPO58, TZTCRTE_CAMPO57,
                             a.TZTCRTE_TIPO_REPORTE   
             UNION
                   SELECT a.TZTCRTE_PIDM pidm,
                    a.TZTCRTE_ID matricula,
                    NVL(REPLACE(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME,'.') nombre_alumno,
                    SUBSTR(TZTCRTE_ID,5) id,
                    REPLACE (a.TZTCRTE_CAMPO1, '&', '&'||'amp;') nombre,
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
                    TZTCRTE_CAMPO14 email,
                    CASE
                        WHEN a.TZTCRTE_CAMPO13 = 'REFI' THEN 'IW'
                        WHEN a.TZTCRTE_CAMPO13 = 'REFU' THEN 'UI'
                        WHEN a.TZTCRTE_CAMPO13  IS NULL THEN 'NI'
                    END serie,
                    a.TZTCRTE_CAMP campus,
                    a.TZTCRTE_CAMPO12 referencia,
                    a.TZTCRTE_CAMPO13 ref_tipo,
                    STVLEVL_DESC nivel,
                    a.TZTCRTE_CAMPO23 curp,
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
                    a.TZTCRTE_CAMPO11 fecha_pago,
                    a.TZTCRTE_CAMPO28 id_pago,  
                (SELECT distinct LISTAGG(TZTCRTE_CAMPO19, ', ') WITHIN GROUP (ORDER BY TZTCRTE_CAMPO19) over (partition by TZTCRTE_CAMPO10) LISTA_NOMBRES
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') tipo_accesorio ,  
                (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO20,0)),'fm9999999990.00')
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_accesorio ,
                    a.TZTCRTE_CAMPO15 colegiaturas,
                    (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO16,0)),'fm9999999990.00')
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_colegiatura ,
                    a.TZTCRTE_CAMPO17 as intereses,
                     (select TO_CHAR (sum (nvl (xx.TZTCRTE_CAMPO18,0)),'fm9999999990.00')
                    from TZTCRTE xx
                    where 1= 1
                    aND TZTCRTE_TIPO_REPORTE =  a.TZTCRTE_TIPO_REPORTE
                    AND TZTCRTE_PIDM = a.TZTCRTE_PIDM
                    and TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                    and TZTCRTE_TIPO_REPORTE = 'Facturacion_dia') monto_interes ,                    
                    TZTCRTE_CAMPO57 secuencia
                    FROM TZTCRTE a, SPRIDEN, STVLEVL, SZVCAMP
                    WHERE 1=1
                    AND a.TZTCRTE_PIDM = SPRIDEN_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                 --   and spriden_pidm = 305977
                    AND a.TZTCRTE_LEVL = STVLEVL_CODE
                    AND a.TZTCRTE_CAMP = SZVCAMP_CAMP_CODE
                    AND a.TZTCRTE_CAMPO10 NOT IN (SELECT TZTFACT_TRAN_NUMBER --NOT
                                          FROM TZTFACT
                                          WHERE TZTFACT_PIDM = a.TZTCRTE_PIDM
                                          AND TZTFACT_TRAN_NUMBER = a.TZTCRTE_CAMPO10)
                    AND TZTCRTE_CAMPO57 = (SELECT MAX(b.TZTCRTE_CAMPO57)
                                          FROM TZTCRTE b
                                          WHERE 1=1
                                          AND b.TZTCRTE_PIDM = a.TZTCRTE_PIDM
                                          AND b.TZTCRTE_CAMPO10 = a.TZTCRTE_CAMPO10
                                          AND b.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia')               
                    --AND TZTCRTE_PIDM = 262265 --38335 --180516 --71319 --99288 --224278 --79355  --117396 --2727 --222622
                    --AND TZTCRTE_CAMPO10 = 106 --70--91 --119--114 --43 --99 --131 --43
                    AND SUBSTR (TZTCRTE_ID,3,2) = '99'
                    AND TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                    AND TZTCRTE_CAMPO2 IS NOT Null
                    AND TZTCRTE_CAMP IN (SELECT ZSTPARA_PARAM_VALOR
                                         FROM ZSTPARA
                                         WHERE 1=1
                                         AND ZSTPARA_MAPA_ID = 'FM_OPM')
                    GROUP BY TZTCRTE_PIDM,TZTCRTE_ID,SPRIDEN_LAST_NAME,SPRIDEN_FIRST_NAME,TZTCRTE_CAMPO1,TZTCRTE_CAMPO2,TZTCRTE_CAMPO3,TZTCRTE_CAMPO27,TZTCRTE_CAMPO4,TZTCRTE_CAMPO5,TZTCRTE_CAMPO6,TZTCRTE_CAMPO14,
                             TZTCRTE_CAMPO20,TZTCRTE_CAMPO15,TZTCRTE_CAMPO13, TZTCRTE_CAMP, TZTCRTE_CAMPO12, TZTCRTE_CAMPO13, STVLEVL_DESC,TZTCRTE_CAMPO23,TZTCRTE_CAMPO24,TZTCRTE_CAMPO10,
                             TZTCRTE_CAMPO9,TZTCRTE_CAMPO7,TZTCRTE_CAMPO8,TZTCRTE_CAMPO11,TZTCRTE_CAMPO19,TZTCRTE_CAMPO16, TZTCRTE_CAMPO17,TZTCRTE_CAMPO18, TZTCRTE_CAMPO28, TZTCRTE_CAMPO58, TZTCRTE_CAMPO57,
                             a.TZTCRTE_TIPO_REPORTE
        
                  )
                    
                                    
          LOOP
                vl_pidm:= d_fiscales.pidm;
                vl_matricula:= d_fiscales.matricula;
                vl_rfc:= d_fiscales.rfc;
                vl_serie:=d_fiscales.serie;
                vl_referencia := d_fiscales.referencia;
                vl_nivel:= d_fiscales.nivel;
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
                                    
                IF 
                vl_pago_monto_pagado LIKE '-%' THEN vl_pago_monto_pagado := vl_pago_monto_pagado *(-1);
                END IF; 
                
                IF vl_rfc = 'XAXX010101000' THEN 
                   vl_pidm_gen:='5133';
                   vl_correoR:= vl_emails;
                   vl_idTipoReceptor:=1;
                   vl_tipo_operacion :='asincrono';
                   vl_uso_cfdi:= 'G03';
                ELSE
                   vl_pidm_gen:=vl_pidm;
                   vl_idTipoReceptor:=vl_idTipoReceptor;
                   vl_tipo_operacion :='sincrono';
                   vl_correoR:=vl_correoR;
                   vl_uso_cfdi:=vl_uso_cfdi;
                END IF;
                
               vl_suma_contracargo:= Null;                
               BEGIN
                SELECT NVL(SUM(TZTCRTE_CAMPO15),0) 
                INTO vl_suma_contracargo
                FROM TZTCRTE
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
                FROM TZTCONC
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
                    FROM TZTCONC 
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
                    FROM TZTCONC 
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
                    FROM TZTCONC 
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
                    FROM TZTCONC 
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
                
               /*
               DBMS_OUTPUT.PUT_LINE('Balance:'||vl_balance);
               DBMS_OUTPUT.PUT_LINE('Subtotal:'||vl_subtotal);
               DBMS_OUTPUT.PUT_LINE('Pago Total:'||vl_pago_total);
               */
               
               vl_balance:= vl_balance*(-1);
               vl_valida_total_balance := vl_pago_total - vl_balance;
               
               --DBMS_OUTPUT.PUT_LINE('Pago total-balance:'||vl_valida_total_balance);
              
                IF vl_balance  > 0 THEN

                  IF vl_serie = 'BS' AND vl_valida_total_balance > 0 THEN
                   vl_pago_monto_colegiatura := vl_pago_monto_colegiatura + vl_balance;
                   vl_balance:= to_char (vl_balance / 1.16,'fm9999999990.00');
                   vl_subtotal:= vl_subtotal+vl_balance;
                  
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
                
                vl_pago_monto_accesorio:= Null;
                
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
                FROM TZTCONC, TVRDCTX
                WHERE 1=1
                AND TZTCONC_PIDM = vl_pidm
                AND TZTCONC_TRAN_NUMBER = vl_transaccion
                AND TZTCONC_DCAT_CODE IN ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                AND TZTCONC_CONCEPTO_CODE = TVRDCTX_DETC_CODE
                GROUP BY TZTCON_MONEDA, TVRDCTX_TXPR_CODE;
                EXCEPTION WHEN OTHERS THEN 
                Null;
                END;
                
                                
                vl_niveleducativo:= NULL;
                vl_clave_rvoe := Null;
                
                BEGIN   
                IF vl_serie = 'BH' AND vl_campus = 'UTL' THEN
                    vl_id_emisor_sto := 1;
                    vl_id_emisor_erp := 1;
                    vl_niveleducativo := 'Profesional técnico';
                    vl_clave_rvoe := vl_clave_rvoe;
                    
                ELSIF vl_serie = 'BH' AND vl_campus IN ('CHI','COL','PER','ECU') AND substr(vl_nivel,1,2) = 'LI'THEN
                      vl_id_emisor_sto := 1;
                      vl_id_emisor_erp := 1;
                      vl_niveleducativo := 'Programa de Pregrado';
                      vl_clave_rvoe := vl_clave_rvoe;
                    
                ELSIF vl_serie = 'BH' AND vl_campus IN ('CHI','COL','PER','ECU') AND substr(vl_nivel,1,2) IN ('MA', 'DO') THEN
                      vl_id_emisor_sto := 1;
                      vl_id_emisor_erp := 1;
                      vl_niveleducativo := 'Programa de Posgrado';
                      vl_clave_rvoe := vl_clave_rvoe;
                      
                ELSIF vl_serie = 'BS' THEN
                    vl_id_emisor_sto := 2;
                    vl_id_emisor_erp := 2;
                    vl_niveleducativo := '.';
                    vl_clave_rvoe := '.';  
                  
                END IF;                               
                END;
                               
                                            
                  
                vl_rfc_utel := Null;
                vl_razon_social_utel := Null;
                vl_prod_serv := Null;                              
                BEGIN                                       
                SELECT 
                TZTDFUT_RFC rfc,
                TZTDFUT_RAZON_SOC razon_social,
                TZTDFUT_PROD_SERV_CODE
                INTO vl_rfc_utel, vl_razon_social_utel, vl_prod_serv
                FROM TZTDFUT
                WHERE TZTDFUT_SERIE = d_fiscales.serie;
                EXCEPTION
                WHEN OTHERS THEN
                vl_error:= 'sp_Datos_Facturacion_xml-Error al Recuperer los datos Fiscales de la empresa ' ||sqlerrm;     
                END;              
                     
                vl_consecutivo:= 0;                     
                                                                  
                BEGIN
                SELECT NVL(MAX(TZTFACT_FOLIO),0)+1--TZTDFUT_FOLIO
                INTO  vl_consecutivo
                FROM TZTFACT
                WHERE TZTFACT_SERIE = d_fiscales.serie;
                EXCEPTION
                WHEN OTHERS THEN 
                vl_consecutivo :=1;
                END;
                
      
                
                BEGIN
                UPDATE TZTDFUT
                SET TZTDFUT_FOLIO = vl_consecutivo
                WHERE TZTDFUT_SERIE = D_Fiscales.serie;
                EXCEPTION
                WHEN OTHERS THEN 
                vl_error := 'Se presento un error al Actualizar ' ||sqlerrm;   
                END;
                commit;
                
                vl_forma_pago:= Null;
                BEGIN
                SELECT DISTINCT TZTCONC_FORMA_PAGO 
                INTO vl_forma_pago
                FROM TZTCONC
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
                FROM TZTCONC
                WHERE 1=1   
                AND TZTCONC_PIDM = vl_pidm
                AND TZTCONC_TRAN_NUMBER = vl_transaccion
                GROUP BY TZTCON_MONEDA;
                EXCEPTION WHEN OTHERS THEN
                INSERT INTO TZTLOFA
                VALUES (vl_pidm,
                        vl_matricula,
                        vl_transaccion, 
                        'SIN_FACTURA_GENERADA',
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
                
                
                         -- VARIABLE CON EL  HTML  DE soap --
             vl_soap:= vl_open_tag||'soap:Envelope xmlns:soap="'
                            ||vl_xmlns_soap||'" '
                            ||'xmlns:xsi="'||vl_xmlns_xsi ||'" '
                            ||'xmlns:xsd="'||vl_xmlns_xsd ||'" '
                            ||'xmlns:neon="'||vl_xmlns_neon ||'">'
                            ||vl_open_tag||'soap:Header'||vl_close_tag;
                        
            vl_abre:= vl_open_tag||'soap:Body>'
                      ||vl_open_tag||'neon:emitirWS>';  
                      
                          
                 -- VARIABLE CON EL  HTML  DEL comprobante --
             vl_comprobante:= vl_open_tag||'comprobante serie="'
                              ||d_fiscales.serie||'" '
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
                    

               BEGIN

                    while x <= 26
                
                LOOP
                
                    x:= x + 1;

                   case  when x = 1 then

                        vl_flxhdrs_nombre:='folioInterno';
                        vl_flxhdrs_valor := d_fiscales.pidm;                        
                        vl_flex_header:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;     
                        
                        
                   when x = 2  then
                        vl_flxhdrs_nombre:='razonSocial';
                        vl_flxhdrs_valor := nvl(d_fiscales.nombre, '.'); 
                        vl_flex_header_2:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;   
                        
                                               
                   when x = 3 then
                        vl_flxhdrs_nombre:='metodoDePago';
                        vl_flxhdrs_valor := nvl(vl_metodo_pago_code, '.'); 
                        vl_flex_header_3:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                   
                   when x = 4 then
                        vl_flxhdrs_nombre:='descripcionDeMetodoDePago';
                        vl_flxhdrs_valor := nvl(vl_pago_metodo_pago, '.');  
                        vl_flex_header_4:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                        
                   when x = 5  then
                        vl_flxhdrs_nombre:='IdPago';
                        vl_flxhdrs_valor := nvl(vl_pago_id_pago, '.'); 
                        vl_flex_header_5:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;    
                   
                   when x = 6 then
                        vl_flxhdrs_nombre:='Monto';
                        vl_flxhdrs_valor := nvl(to_char(vl_pago_monto_pagado,'fm9999999990.00'), '.');
                        vl_flex_header_6:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                        
                   when x = 7 then
                        vl_flxhdrs_nombre:='Nivel';
                        vl_flxhdrs_valor := nvl(vl_nivel, '.');  
                        vl_flex_header_7:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                        
                   when x = 8 then
                        vl_flxhdrs_nombre:='Campus';
                        vl_flxhdrs_valor := nvl(vl_campus, '.');
                        vl_flex_header_8:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag; 
                   
                   when x = 9 then
                        vl_flxhdrs_nombre:='matriculaAlumno';
                        vl_flxhdrs_valor := nvl(d_fiscales.matricula, '.');  
                        vl_flex_header_9:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                        
                   when x = 10 then
                        vl_flxhdrs_nombre:='fechaPago';
                        vl_flxhdrs_valor := nvl(vl_fecha_pago, '.'); 
                        vl_flex_header_10:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                   
                   when x = 11 then
                        vl_flxhdrs_nombre:='Referencia';
                        vl_flxhdrs_valor := nvl(d_fiscales.referencia, '.'); 
                        vl_flex_header_11:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag; 
                        
                   when x = 12 then
                        vl_flxhdrs_nombre:='ReferenciaTipo';
                        vl_flxhdrs_valor := nvl(d_fiscales.ref_tipo, '.'); 
                        vl_flex_header_12:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                   
                   when x = 13 then
                        vl_flxhdrs_nombre:='MontoInteresPagoTardio';
                        vl_flxhdrs_valor := nvl(vl_pago_monto_interes , '.');  
                        vl_flex_header_13:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                        
                   when x = 14 then
                        vl_flxhdrs_nombre:='TipoAccesorio';
                        vl_flxhdrs_valor := nvl(vl_pago_tipo_accesorio, '.');    
                        vl_flex_header_14:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;  

                   when x = 15 then
                        vl_flxhdrs_nombre:='MontoAccesorio';
                        vl_flxhdrs_valor := nvl(vl_pago_monto_accesorio, '.');
                        vl_flex_header_15:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag; 
                        

                   when x = 16 then
                        vl_flxhdrs_nombre:='Colegiatura';
                        vl_flxhdrs_valor := nvl(vl_pago_colegiaturas, 'COLEGIATURA LICENCIATURA');
                        vl_flex_header_16:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                        
                   when x = 17 then
                        vl_flxhdrs_nombre:='MontoColegiatura';
                        vl_flxhdrs_valor := nvl(vl_pago_monto_colegiatura, nvl(vl_balance,'.'));
                        vl_flex_header_17:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                               
                   when x = 18 then
                        vl_flxhdrs_nombre:='NombreAlumno';
                        vl_flxhdrs_valor := nvl(d_fiscales.nombre_alumno, '.');  
                        vl_flex_header_18:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                        
                   when x = 19 then
                        vl_flxhdrs_nombre:='CURP';
                        vl_flxhdrs_valor := nvl(d_fiscales.curp, '.'); 
                        vl_flex_header_19:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;    

                   when x = 20 then
                        vl_flxhdrs_nombre:='RFC';
                        vl_flxhdrs_valor := nvl(d_fiscales.rfc, '.'); 
                        vl_flex_header_20:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                   
                   when x = 21 then
                        vl_flxhdrs_nombre:='Grado';
                        vl_flxhdrs_valor := nvl(d_fiscales.grado, '.'); 
                        vl_flex_header_21:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag; 
                        
                   when x = 22 then
                        vl_flxhdrs_nombre:='Nota';
                        vl_flxhdrs_valor := '.';  
                        vl_flex_header_22:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag; 
                               
                       
                   when x = 23 then
                        vl_flxhdrs_nombre:='nivelEducativo';
                        vl_flxhdrs_valor := nvl(vl_niveleducativo, '.');                            
                        vl_flex_header_23:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;   
                        
                   when x = 24 THEN
                        vl_flxhdrs_nombre:='ClaveRVOE';
                        vl_flxhdrs_valor := nvl(vl_clave_rvoe, '.');                            
                        vl_flex_header_24:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                     

                   when x = 25 then
                        vl_flxhdrs_nombre:='Observaciones';
                        vl_flxhdrs_valor := nvl(vl_obs, '.');                            
                        vl_flex_header_25:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                   
                   when x = 26 then
                        vl_flxhdrs_nombre:='InteresPagoTardio';
                        vl_flxhdrs_valor := nvl(vl_pago_intereses, '.');                            
                        vl_flex_header_26:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                        
                   when x = 27 then
                        vl_flxhdrs_nombre:='CorreoReceptor';
                        vl_flxhdrs_valor := nvl(vl_correoR, '.');                            
                        vl_flex_header_27:= vl_open_tag||vl_flex_hdrs_tag||' clave="'||x||'" nombre="'||vl_flxhdrs_nombre||'" valor="'||vl_flxhdrs_valor||'"'||vl_close_tag;
                   else null;

                   end case;  
                               
                EXIT WHEN NULL;
                   
                END LOOP;
                
                x:=0;

               END; 
                
                vl_out:= null;
                vl_sum_bubtotal:= 0;
                
               BEGIN
                SELECT SUM(TZTCONC_SUBTOTAL)
                INTO vl_sum_bubtotal
                FROM TZTCONC
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
                                FROM TZTCONC, TVRDCTX, TVRTPDC a 
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
                    


                    IF vl_tipo_impuesto !='IVE' AND vl_balance = 0 AND vl_crtgo_code != 'APF'  THEN 
                    
                       BEGIN
                        vl_tipo_factor_impuesto:='"Tasa"'; 
                        
                        --DBMS_OUTPUT.PUT_LINE ('Caso '||vl_tipo_factor_impuesto||vl_tipo_impuesto||' '||vl_crtgo_code||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion); 
                        
                        if vl_tipo_impuesto = 'IVA' THEN
                         vl_tasa_cuota_impuesto := '0.160000';
                        elsif vl_tipo_impuesto IN ('IVE','IVP')  THEN
                         vl_tasa_cuota_impuesto := '0.000000';
                        end if;     
                       
 
                        vl_concepto:= vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                                  ||vl_descripcion||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_importe||vl_importe_tag||vl_importe||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_importe||'"'||vl_impuesto_tag||vl_impuesto_cod
                                  ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||vl_tasa_cuota_impuesto_tag||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_iva||'"/>'||vl_impuestos_close_tag||vl_conceptos_close_tag;

                         vl_out:=vl_out||vl_concepto;
                         
                        END;
                              
                             
                    ELSIF vl_tipo_impuesto ='IVE' AND vl_balance = 0 AND vl_crtgo_code != 'APF'  THEN 
                    
                       BEGIN
                        vl_tipo_factor_impuesto:='"Exento"'; 
     
                        
                        --DBMS_OUTPUT.PUT_LINE ('Caso'||vl_tipo_factor_impuesto||vl_tipo_impuesto||' '||vl_crtgo_code||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion);
       
                        vl_concepto:= vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                                  ||vl_descripcion||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_importe||vl_importe_tag||vl_importe||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_importe||'"'||vl_impuesto_tag||vl_impuesto_cod
                                  ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||'/>'||vl_impuestos_close_tag||vl_conceptos_close_tag;
                                  --||vl_tasa_cuota_impuesto_tag||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_iva||'"/>'||vl_impuestos_close_tag||vl_conceptos_close_tag;
                                 
                         vl_out:=vl_out||vl_concepto;
                        END;
                         
                         
                    END IF; 

                  END LOOP;
                     

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
                           ||vl_flex_header_27;   
                       
                           
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
                                FROM TZTCONC, TVRDCTX, TVRTPDC a 
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
                                                                           
                                vl_numIdentificacion:= c.TZTCONC_CONCEPTO_CODE;
                                vl_descripcion:= c.TZTCONC_CONCEPTO;
                                vl_valorUnitario :=c.TZTCONC_MONTO;
                                vl_importe := C.IMPORTE_CONCEPTO;
                                vl_iva := c.TZTCONC_IVA;
                                vl_tipo_impuesto:=c.TIPO_IVA;
                                vl_crtgo_code := c.CRTGO_CODE;   
                         
                        
                            IF
                             vl_tipo_impuesto = 'IVE' AND vl_crtgo_code != 'APF' THEN                     
                             vl_tipo_factor_impuesto:='"Exento"'; 
                             vl_tipo_factor_impuesto_final:='"Exento"'; 
                             vl_tasa_cuota_impuesto:='0.000000';
                                                          
                            ELSIF
                             vl_tipo_impuesto ='IVP' AND vl_crtgo_code != 'APF' THEN
                             vl_tipo_factor_impuesto:='"Tasa"';
                             vl_tipo_factor_impuesto_final:='"Tasa"'; 
                             vl_tasa_cuota_impuesto:='0.000000';
                             
                            ELSIF
                             vl_tipo_impuesto ='IVA' AND vl_crtgo_code != 'APF' THEN
                             vl_tipo_factor_impuesto:='"Tasa"';
                             vl_tipo_factor_impuesto_final:='"Tasa"'; 
                             vl_tasa_cuota_impuesto:='0.160000';
                            
                            END IF; 
 
                        --DBMS_OUTPUT.PUT_LINE ('Entra en balance > 0 y vl_chg_tran_numb >0 ****'||vl_balance||'*'||vl_chg_tran_numb||'*'||vl_tipo_factor_impuesto_final||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion);
                            
                            BEGIN    
                             
                                 BEGIN
                                    SELECT TZTCON_MONEDA
                                    INTO vl_tipo_moneda
                                    FROM TZTCONC
                                    WHERE 1=1
                                      AND TZTCONC_PIDM = d_fiscales.pidm
                                      AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                                     GROUP BY TZTCON_MONEDA;
                                 EXCEPTION WHEN OTHERS THEN
                                 vl_tipo_moneda:='MXN';
                                 END;
                                  
                                IF vl_tipo_moneda <> 'CLP' THEN
                                   
                                   BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0.00'), 'fm9999999990.00')
                                    INTO vl_totalImpuestosTrasladados
                                    FROM  TZTCONC
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0.00';
                                   END; 
                                   
                                   --DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************'||vl_tipo_factor_impuesto_final);
                                    
                                ELSIF vl_tipo_moneda = 'CLP' THEN
                                   
                                   BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0'))
                                    INTO vl_totalImpuestosTrasladados
                                    FROM  TZTCONC
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0';
                                   END; 
                                
                                END IF;
                                    
                            END;

                         vl_concepto:= vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                              ||vl_descripcion||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_importe||vl_importe_tag||vl_importe||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_importe||'"'||vl_impuesto_tag||vl_impuesto_cod
                              ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||vl_tasa_cuota_impuesto_tag||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_iva||'"/>'||vl_impuestos_close_tag||vl_conceptos_close_tag; 

                         vl_out:= vl_out||vl_concepto;

                      end loop;   
                      
                      --DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************'||vl_tipo_factor_impuesto_final);

                        
                       if vl_tipo_factor_impuesto ='"Tasa"' and vl_valida_total_balance > 0 then
                        
                       --DBMS_OUTPUT.PUT_LINE(vl_serie);
                                                       
                            if vl_serie = 'BS' AND vl_valida_total_balance > 0 THEN
                            vl_balance:= to_char (vl_balance * 1.16,'fm9999999990.00'); -- se agrea el IVA al balance para el valor unitario del concepto--
                            end if;
                         --dbms_output.put_line(vl_balance);
                              if vl_serie = 'BS' then--and vl_tipo_impuesto = 'IVA'  then
                              --se utiliza la variable IVA para colocar el importe sin IVA del remanente (balance)
                               vl_iva:= vl_balance - to_char (vl_balance / 1.16,'fm9999999990.00');
                               vl_balance_1:= vl_balance - vl_iva;
                               vl_totalImpuestosTrasladados:= vl_totalImpuestosTrasladados + vl_iva;
                               
                               --dbms_output.put_line(vl_iva);
                             else
                             vl_balance_1:= vl_balance;
                             vl_tipo_factor_impuesto:= vl_tipo_factor_impuesto;--'"Exento"';
                             vl_tasa_cuota_impuesto:='0.000000';
                             vl_iva:= '0.00';
                              
                             end if;
                          
                             vl_concepto_balance:= vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                                          ||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_balance_1||vl_importe_tag||vl_balance_1||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_balance_1||'"'||vl_impuesto_tag||vl_impuesto_cod
                                          ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||vl_tasa_cuota_impuesto_tag||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_iva||'"/>'
                                          ||vl_impuestos_close_tag||vl_conceptos_close_tag; 
                                          
                             vl_out:=vl_out||vl_concepto_balance;
                                          
                       elsif vl_tipo_factor_impuesto ='"Exento"' and vl_valida_total_balance > 0 then
                        
                             
                              vl_concepto_balance := vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                                              ||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_balance||vl_importe_tag||vl_balance||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_balance||'"'||vl_impuesto_tag||vl_impuesto_cod
                                              ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||'/>'||vl_impuestos_close_tag||vl_conceptos_close_tag;
                                               
                              vl_out:=vl_out||vl_concepto_balance;
                              
                              
                        end if;
                        
                       vl_out:= vl_out; --||vl_concepto_balance;  
                       vl_totalImpuestosTrasladados:= vl_totalImpuestosTrasladados;
                       --vl_totalImpuestosRetenidos:= vl_totalImpuestosTrasladados;
                       
                       --DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************1'||vl_tipo_factor_impuesto_final);
                       
                       IF vl_totalImpuestosTrasladados >  0 THEN
                        vl_tipo_factor_impuesto_final:='"Tasa"';
                        vl_tasa_cuota_impuesto :='0.160000';
                       END IF;
                      
                      --DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************2'||vl_tipo_factor_impuesto_final);
                      
                       vl_out:= vl_soap||vl_abre||vl_comprobante||vl_envio_cfdi||vl_emisor||vl_receptor||vl_xml_final||vl_out--||vl_concepto||vl_concepto_balance
                                    ||vl_totalImpuestosRet_tag||vl_totalImpuestosRetenidos||'" '||vl_totalImpTras_tag||vl_totalImpuestosTrasladados||'"> '||vl_open_tag||vl_traslados_tag
                                    ||vl_impuesto_tag||vl_impuesto_cod||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto_final||vl_tasa_cuota_impuesto_tag
                                    ||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_totalImpuestosTrasladados||'"'||vl_close_tag
                                    ||vl_impuestos_close_tag||vl_tipo_operacion_tag||vl_tipo_operacion||vl_tipo_operacion_close_tag||vl_cierre; 
                                    
                     --DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************3'||vl_tipo_factor_impuesto_final);
                                    
                   END;               
                        
                                
                 elsif vl_balance >0 AND vl_chg_tran_numb = 0 then
                 
                   BEGIN
                 
                      
                        IF
                          vl_tipo_impuesto ='IVE' AND vl_crtgo_code != 'APF' THEN
                          vl_tipo_factor_impuesto:='"Exento"'; 
                          vl_tipo_factor_impuesto_final:='"Exento"'; 
                          vl_tasa_cuota_impuesto:='0.000000';
                          
                        ELSIF
                             vl_tipo_impuesto ='IVP' AND vl_crtgo_code != 'APF' THEN
                             vl_tipo_factor_impuesto:='"Tasa"';
                             vl_tipo_factor_impuesto_final:='"Tasa"'; 
                             vl_tasa_cuota_impuesto:='0.000000';
                                 
                        ELSIF
                         vl_tipo_impuesto ='IVA' AND vl_crtgo_code != 'APF' THEN
                         vl_tipo_factor_impuesto:='"Tasa"';
                         vl_tipo_factor_impuesto_final:='"Tasa"';
                          vl_tasa_cuota_impuesto:='0.160000';
                                 
                        END IF; 
                      
                      vl_totalImpuestosTrasladados:=NULL;
                                                   
                         BEGIN    
                             
                             BEGIN
                                SELECT TZTCON_MONEDA
                                INTO vl_tipo_moneda
                                FROM TZTCONC
                                WHERE 1=1
                                AND TZTCONC_PIDM = d_fiscales.pidm
                                AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                                 GROUP BY TZTCON_MONEDA;
                             EXCEPTION WHEN OTHERS THEN
                             vl_tipo_moneda:='MXN';
                             END;
                                  
                            IF vl_tipo_moneda <> 'CLP' THEN
                                   
                               BEGIN
                                SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0.00'), 'fm9999999990.00')
                                INTO vl_totalImpuestosTrasladados
                                FROM  TZTCONC
                                WHERE 1=1
                                AND TZTCONC_PIDM = d_fiscales.pidm
                                AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                               EXCEPTION WHEN OTHERS THEN
                               vl_totalImpuestosTrasladados:='0.00';
                               END; 
                                   
                               --DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************'||vl_tipo_factor_impuesto_final);
                                    
                            ELSIF vl_tipo_moneda = 'CLP' THEN
                                   
                               BEGIN
                                SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0'))
                                INTO vl_totalImpuestosTrasladados
                                FROM  TZTCONC
                                WHERE 1=1
                                AND TZTCONC_PIDM = d_fiscales.pidm
                                AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                               EXCEPTION WHEN OTHERS THEN
                               vl_totalImpuestosTrasladados:='0';
                               END; 
                                
                            END IF;
                                    
                        END;
                        
                        
                       IF vl_tipo_factor_impuesto ='"Tasa"' then
                            
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
                           
                          
                             vl_concepto_balance:= vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                                          ||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_balance_1||vl_importe_tag||vl_balance_1||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_balance_1||'"'||vl_impuesto_tag||vl_impuesto_cod
                                          ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||vl_tasa_cuota_impuesto_tag||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_iva||'"/>'
                                          ||vl_impuestos_close_tag||vl_conceptos_close_tag; 
                               
                                          
                              --vl_out:=vl_out||vl_concepto_balance;
                        elsif vl_tipo_factor_impuesto ='"Exento"' then

                          vl_concepto_balance:= vl_open_tag||vl_claveProdserv_tag||vl_prod_serv||vl_cantidad_tag||vl_cantidad_concepto||vl_clave_unidad_tag||vl_clave_unidad_concepto||vl_unidad_tag||vl_unidad_concepto||vl_num_identificacion_tag||vl_numIdentificacion||vl_descripcion_tag
                                      ||'PCOLEGIATURA '||vl_nivel||', '||vl_nombrealumno||', '||vl_pago_metodo_pago||', '||vl_matricula||', '||vl_referencia||','||vl_nivel||vl_valor_unitario_tag||vl_balance||vl_importe_tag||vl_balance||vl_descuento_tag||vl_descuento||'">'||vl_impuestos_tag||vl_open_tag||vl_traslados_tag||vl_base_tag||vl_balance||'"'||vl_impuesto_tag||vl_impuesto_cod
                                      ||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto||'/>'||vl_impuestos_close_tag||vl_conceptos_close_tag;  
                                      
                            --vl_out:= vl_out||vl_concepto_balance;      
                                      
                        END IF;
                        
                     --DBMS_OUTPUT.PUT_LINE ('Entra en balance > a 0 y vl_chg_tran_numb =0 **'||vl_balance||'*'||vl_chg_tran_numb||'*'||vl_tipo_factor_impuesto_final||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion); 
                    
                        vl_out:= vl_out||vl_concepto_balance;  
 
                        vl_totalImpuestosTrasladados:= vl_totalImpuestosTrasladados;
                        --vl_totalImpuestosRetenidos:= vl_totalImpuestosTrasladados;
                        
                       IF vl_totalImpuestosTrasladados >  0 THEN
                        vl_tipo_factor_impuesto_final:='"Tasa"';
                        vl_tasa_cuota_impuesto :='0.160000';
                       END IF;
     
                      vl_out:= vl_soap||vl_abre||vl_comprobante||vl_envio_cfdi||vl_emisor||vl_receptor||vl_xml_final||vl_out--||vl_concepto_balance
                                ||vl_totalImpuestosRet_tag||vl_totalImpuestosRetenidos||'" '||vl_totalImpTras_tag||vl_totalImpuestosTrasladados||'"> '||vl_open_tag||vl_traslados_tag
                                ||vl_impuesto_tag||vl_impuesto_cod||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto_final||vl_tasa_cuota_impuesto_tag
                                ||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_totalImpuestosTrasladados||'"'||vl_close_tag
                                ||vl_impuestos_close_tag||vl_tipo_operacion_tag||vl_tipo_operacion||vl_tipo_operacion_close_tag||vl_cierre;   
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
                                FROM TZTCONC, TVRDCTX, TVRTPDC a 
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
                                                                           
                                vl_numIdentificacion:= c.TZTCONC_CONCEPTO_CODE;
                                vl_descripcion:= c.TZTCONC_CONCEPTO;
                                vl_valorUnitario :=c.TZTCONC_MONTO;
                                vl_importe := C.IMPORTE_CONCEPTO;
                                vl_iva := c.TZTCONC_IVA;
                                vl_tipo_impuesto:=c.TIPO_IVA;
                                vl_crtgo_code := c.CRTGO_CODE;   
                                

                                
                        IF
                         vl_tipo_impuesto ='IVE' AND vl_crtgo_code != 'APF' THEN 
                         
                         vl_tipo_factor_impuesto_final:='"Exento"';
                         vl_tasa_cuota_impuesto:= '0.000000';
                         
                        ELSIF
                             vl_tipo_impuesto ='IVP' AND vl_crtgo_code != 'APF' THEN
                             vl_tipo_factor_impuesto:='"Tasa"';
                             vl_tipo_factor_impuesto_final:='"Tasa"'; 
                             vl_tasa_cuota_impuesto:='0.000000';
                          
                        ELSIF
                         vl_tipo_impuesto ='IVA' AND vl_crtgo_code != 'APF' THEN
                         vl_tipo_factor_impuesto_final:='"Tasa"';
                         vl_tasa_cuota_impuesto:= '0.160000';
                         
                        END IF; 
                                
                       --DBMS_OUTPUT.PUT_LINE ('Entra en balance = 0 y vl_chg_tran_numb >0 o vl_chg_tran_numb = 0**'||vl_balance||'*'||vl_chg_tran_numb||'*'||vl_tipo_factor_impuesto_final||'**PIDM: '||vl_pidm||'**TRAN: '||vl_transaccion); 
                       
                            BEGIN    
                             
                                 BEGIN
                                    SELECT TZTCON_MONEDA
                                    INTO vl_tipo_moneda
                                    FROM TZTCONC
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion
                                    GROUP BY TZTCON_MONEDA;
                                 EXCEPTION WHEN OTHERS THEN
                                 vl_tipo_moneda:='MXN';
                                 END;
                                  
                                IF vl_tipo_moneda <> 'CLP' THEN
                                   
                                   BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0.00'), 'fm9999999990.00')
                                    INTO vl_totalImpuestosTrasladados
                                    FROM  TZTCONC
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0.00';
                                   END; 
                                   
                                   --DBMS_OUTPUT.PUT_LINE(vl_totalImpuestosTrasladados||'**************'||vl_tipo_factor_impuesto_final);
                                    
                                ELSIF vl_tipo_moneda = 'CLP' THEN
                                   
                                   BEGIN
                                    SELECT TO_CHAR(NVL(SUM(TZTCONC_IVA),'0'))
                                    INTO vl_totalImpuestosTrasladados
                                    FROM  TZTCONC
                                    WHERE 1=1
                                    AND TZTCONC_PIDM = d_fiscales.pidm
                                    AND TZTCONC_TRAN_NUMBER = d_fiscales.transaccion;
                                   EXCEPTION WHEN OTHERS THEN
                                   vl_totalImpuestosTrasladados:='0';
                                   END; 
                                
                                END IF;
                                    
                            END;
                        
                        IF
                        vl_totalImpuestosTrasladados <> 0 THEN
                         vl_tipo_factor_impuesto_final:='"Tasa"';
                         vl_tasa_cuota_impuesto:= '0.160000';
                         
                        END IF;
                         
                      END LOOP;
                      
                      --vl_totalImpuestosRetenidos:= vl_totalImpuestosTrasladados;
                      
                            vl_out:= vl_soap||vl_abre||vl_comprobante||vl_envio_cfdi||vl_emisor||vl_receptor||vl_xml_final||vl_out
                            ||vl_totalImpuestosRet_tag||vl_totalImpuestosRetenidos||'" '||vl_totalImpTras_tag||vl_totalImpuestosTrasladados||'"> '||vl_open_tag||vl_traslados_tag
                            ||vl_impuesto_tag||vl_impuesto_cod||'"'||vl_tipo_factor_tag||vl_tipo_factor_impuesto_final||vl_tasa_cuota_impuesto_tag
                            ||vl_tasa_cuota_impuesto||vl_importe_tras_tag||vl_totalImpuestosTrasladados||'"'||vl_close_tag
                            ||vl_impuestos_close_tag||vl_tipo_operacion_tag||vl_tipo_operacion||vl_tipo_operacion_close_tag||vl_cierre;
                      
                    END;
                                    
                 END IF;

                END;
               
            vl_valida_conc:=0;
           
            BEGIN
            SELECT COUNT(1)
            INTO vl_valida_conc
            FROM TZTCONC
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
                insert into tztfact 
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
                 (vl_pidm, --tztfact_pidm
                 vl_rfc, --tztfact_rfc
                 vl_pago_monto_pagado, --tztfact_monto
                 'FM', --tztfact_tipo_docto 
                 ' ', --tztfact_status_fact
                 ' ', --tztfact_uuii
                 sysdate, --tztfact_fecha_proceso
                 vl_transaccion, --tztfact_tran_number
                 '0', --tztfact_text
                 vl_consecutivo, --tztfact_folio
                 vl_serie, --tztfact_serie
                 0,  --5 Detener --tztfact_respuesta
                 ' ', --tztfact_error
                 '0',--vl_out,--tztfact_xml
                 ' ',--vl_tipo_archivo, --tztfact_tipo
                 vl_tipo_fact, --tztfact_tipo_fact
                 vl_pago_metodo_pago, --Null, --tztfact_tipo_pago
                 'FM_OPM',--Null,--tztfact_stst_timbrado
                 Null,-- tztfact_rvoe 
                 vl_subtotal,--Null, --tztfact_subt
                 vl_totalImpuestosTrasladados, --Null, --tztfact_iva
                 vl_nivel, --tztfact_nivel
                 vl_pago_fecha_pago, --tztfact_fecha_pago
                 vl_campus  --tztfact_curp
                 ); 
                EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
                INSERT INTO TZTLOFA
                VALUES (vl_pidm,
                        vl_matricula,
                        vl_transaccion, 
                        'Restriccion unica violada',
                        SYSDATE,
                        USER,
                        'TZTCONC',
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        vl_campus, 
                        vl_seq_no);   
                --THEN raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM||'PIDM- '||vl_pidm);                               
                END;
           ELSE
           NULL;
           
           END IF;
                
          --*/
          
           /*
           IF vl_valida_conc > 0 THEN   
          DBMS_OUTPUT.PUT_LINE(vl_out);    
           END IF;
          */            

          END LOOP;
        COMMIT;

    END SP_GENERA_XML_FM;
    
    
       FUNCTION F_SZTPAGOS_FACT_OUT (p_pidm in number) RETURN PKG_FACTURACION_MANUAL.cursor_SZTPAGOS_FACT_OUT
   
   AS 
   
   SZTPAGOS_FACT_OUT PKG_FACTURACION_MANUAL.cursor_SZTPAGOS_FACT_OUT;
   
   BEGIN
   
   open SZTPAGOS_FACT_OUT
   FOR
        SELECT a.SORLCUR_PIDM PIDM, 
        NULL Estatus_final, 
        NULL Estatus,  
        NULL Clave_Carrera, 
        a.SORLCUR_PROGRAM  CARRERA, 
        a.SORLCUR_CAMP_CODE CAMPUS, 
        a.SORLCUR_LEVL_CODE NIIVEL,
        NULL tipo_inscripcion,
        NULL inscripcion_desc,
        NULL Area_Mayor,
        NULL Descripcion_Mayor,
        NULL Area_Menor_1,
        NULL Descripcion_Salida_1,
        NULL Area_Menor_2,
        NULL Descripcion_Salida_2 
        from SORLCUR a
        WHERE 1=1
        AND a.SORLCUR_PIDM = p_pidm --230251
        AND a.SORLCUR_LMOD_CODE = 'LEARNER' 
        AND a.SORLCUR_CACT_CODE  != 'CHANGE'
        AND a.SORLCUR_ROLL_IND = 'Y'
        AND a.SORLCUR_TERM_CODE = (SELECT MAX (b.SORLCUR_TERM_CODE)
                             FROM SORLCUR b
                             WHERE 1=1
                             AND b.SORLCUR_PIDM = a.SORLCUR_PIDM
                             AND b.SORLCUR_LMOD_CODE = a.SORLCUR_LMOD_CODE
                             and b.SORLCUR_CACT_CODE= a.SORLCUR_CACT_CODE
                             AND b.SORLCUR_ROLL_IND = a.SORLCUR_ROLL_IND)
                             
        UNION                    
        SELECT a.SORLCUR_PIDM PIDM, 
        NULL Estatus_final, 
        NULL Estatus,  
        NULL Clave_Carrera, 
        a.SORLCUR_PROGRAM  CARRERA, 
        a.SORLCUR_CAMP_CODE CAMPUS, 
        a.SORLCUR_LEVL_CODE NIIVEL,
        NULL tipo_inscripcion,
        NULL inscripcion_desc,
        NULL Area_Mayor,
        NULL Descripcion_Mayor,
        NULL Area_Menor_1,
        NULL Descripcion_Salida_1,
        NULL Area_Menor_2,
        NULL Descripcion_Salida_2 
        from SORLCUR a
        WHERE 1=1
        AND a.SORLCUR_PIDM = p_pidm --230251
        AND a.SORLCUR_LMOD_CODE = 'ADMISSIONS' 
        AND a.SORLCUR_CACT_CODE  != 'CHANGE'
        AND a.SORLCUR_TERM_CODE = (SELECT MAX (b.SORLCUR_TERM_CODE)
                             FROM SORLCUR b
                             WHERE 1=1
                             AND b.SORLCUR_PIDM = a.SORLCUR_PIDM
                             AND b.SORLCUR_LMOD_CODE = a.SORLCUR_LMOD_CODE
                             and b.SORLCUR_CACT_CODE= a.SORLCUR_CACT_CODE);                                            
   RETURN (SZTPAGOS_FACT_OUT);
    
   END F_SZTPAGOS_FACT_OUT;
   

   FUNCTION f_factura_manual_out(pidm in number, trans in number) RETURN PKG_FACTURACION_MANUAL.fmanu_out 
           AS

           my_var long; 
           fm_out PKG_FACTURACION_MANUAL.fmanu_out;
                      
 BEGIN 


        Begin
                
                    For c in (select distinct c.SZTDTEC_NUM_RVOE, a.pidm
                                from tztprog a
                                join TZTFACT b on b.TZTFACT_PIDM = a.pidm and b.TZTFACT_TIPO_DOCTO = 'FM' and b.TZTFACT_RVOE is null AND TZTFACT_STST_TIMBRADO = 'FM_OPM'
                                join SZTDTEC c on c.SZTDTEC_PROGRAM = a.programa  and c.SZTDTEC_TERM_CODE = a.CTLG and c.SZTDTEC_NUM_RVOE is not null
                                union
                                select  DISTINCT SZTDTEC_NUM_RVOE, SPRIDEN_PIDM
                                from spriden
                                join TZTFACT on TZTFACT_PIDM = SPRIDEN_PIDM AND SPRIDEN_CHANGE_IND IS NULL AND TZTFACT_TIPO_DOCTO = 'FM' and TZTFACT_RVOE is null AND TZTFACT_STST_TIMBRADO = 'FM_OPM'
                                join TAISMGR.TZTPAGOS_FACT on TZTPAGO_ID = SPRIDEN_ID AND TZTPAGO_STAT_INSCR != 'CANCELADA'
                                join SZTDTEC a on  a.SZTDTEC_PROGRAM = TZTPAGO_PROGRAMA and a.SZTDTEC_TERM_CODE = (select max (SZTDTEC_TERM_CODE) 
                                                                                                                     from SZTDTEC b 
                                                                                                                     where b.SZTDTEC_PROGRAM = a.SZTDTEC_PROGRAM)
                                and SZTDTEC_NUM_RVOE is not null
                    
                                              
                                             --   Where a.pidm = cc.TZTFACT_PIDM            
                       ) loop
                       
                               Begin
                                        Update TZTFACT
                                        set TZTFACT_RVOE = c.SZTDTEC_NUM_RVOE
                                        Where TZTFACT_PIDM =  c.PIDM
                                        and TZTFACT_TIPO_DOCTO = 'FM'
                                        and TZTFACT_RVOE is null;
                               Exception
                                When Others then 
                                    null;    
                               End;
                    End Loop;
                    Commit;

        End;




                          open fm_out            
                            FOR      
                            select TZTFACT_PIDM PIDM,
                                        TZTFACT_RFC RFC ,
                                        TZTFACT_TRAN_NUMBER TRAN,
                                            TZTFACT_TIPO_PAGO,
                                            TZTFACT_STST_TIMBRADO,
                                            TZTFACT_RVOE,
                                            TZTFACT_MONTO,
                                            TZTFACT_SUBT,
                                            TZTFACT_IVA,
                                            TZTFACT_FECHA_PROCESO,
                                            TZTFACT_NIVEL
                              from TZTFACT
                            where TZTFACT_TIPO_DOCTO = 'FM'
                                 and TZTFACT_STST_TIMBRADO is not null
                                 and TZTFACT_PIDM = pidm
                                 and TZTFACT_TRAN_NUMBER = trans
                                ;
                            

            RETURN (fm_out);                 
                                                                    

     END f_factura_manual_out;
     
     
    FUNCTION f_conceptos_out(pidm in number, transa in number) RETURN PKG_FACTURACION_MANUAL.concep_out

           AS

           my_var long; 
           conc_out PKG_FACTURACION_MANUAL.concep_out;
                      
        BEGIN 


                          open conc_out            
                            FOR      
                                    select 
                                        TZTCONC_PIDM PIDM,
                                        TZTCONC_FOLIO FOLIO,
                                        TZTCONC_CONCEPTO_CODE CONC_CODE,
                                        TZTCONC_CONCEPTO CONCEPTO,
                                        TZTCONC_MONTO MONTO,
                                        TZTCONC_SUBTOTAL SUBTOTAL,
                                        TZTCONC_IVA IVA,
                                        TZTCONC_TRAN_NUMBER TRANSACCION,
                                        TZTCONC_FECHA_CONC FECHA
                                     from TZTCONC
                                     where TZTCONC_TRAN_NUMBER = transa
                                     and TZTCONC_PIDM = pidm
--                                         and TZTCONC_FECHA_CONC = trunc(sysdate)
                                ;
                            

            RETURN (conc_out);                 
                                                                    

    END f_conceptos_out;
    
    
    PROCEDURE sp_Respuesta_Factura(vn_pidm in number, vn_tran in number, vl_t_docto in varchar2, vn_respuesta in number, vl_error varchar2 )

          is 

          p_error varchar2(2500) := 'EXITO';
          
              BEGIN
                  Begin
                       Update TZTFACT
                        set TZTFACT_RESPUESTA = vn_respuesta, TZTFACT_ERROR = vl_error
                        where TZTFACT_PIDM = vn_pidm
                        and TZTFACT_TRAN_NUMBER = vn_tran
                        and TZTFACT_TIPO_DOCTO = vl_t_docto
                        and TZTFACT_STST_TIMBRADO= 'FM_OPM';   
                  Exception
                    when Others then
                    p_error:= 'Error en respuesta'||sqlerrm;
                  End;
             
              Exception 
              When Others then
              p_error := 'Se presento un Error General  ' ||sqlerrm;
            END sp_Respuesta_Factura;  
    
 END;
/

DROP PUBLIC SYNONYM PKG_FACTURACION_MANUAL;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FACTURACION_MANUAL FOR BANINST1.PKG_FACTURACION_MANUAL;
