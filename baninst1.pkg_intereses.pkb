DROP PACKAGE BODY BANINST1.PKG_INTERESES;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_INTERESES
AS
   PROCEDURE P_RECARGOS (P_PIDM IN NUMBER DEFAULT NULL)
   IS
      RECARGO          NUMBER;
      TRANSACCION      NUMBER;
      PERIODO          VARCHAR2 (6);
      VL_DESCRIPCION   VARCHAR2 (30);
      IDEN             VARCHAR2 (5);
      vl_moneda        VARCHAR2(3);
      P_ERROR          varchar2(500):= null;

      CURSOR C1
      IS
                                             
        SELECT TBRACCD_PIDM PIDM,
                matricula ,
                TBBDETC_DCAT_CODE DCAT,
                SZTINTE_PCT_CARGO PORCENTAJE,
                0 MESES,
                SZTINTE_DIAS DIAS,
                SUBSTR (SZTINTE_CODE_DET, 3, 2) CONCEPTO,
                SUBSTR(SZTINTE_CODE_DET_C,1,2)||SUBSTR (SZTINTE_CODE_DET, 3, 2) CODIGO_CARGO,
                TBRACCD_TERM_CODE PERIODO,
                TBRACCD_RECEIPT_NUMBER ORDEN,
                TBBDETC_DESC CODIGO,
                TBRACCD_BALANCE,
                case 
                    when PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(tbraccd_pidm) < 0 then 
                     0 --TBRACCD_BALANCE  -  PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(tbraccd_pidm)*-1 
                    when PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(tbraccd_pidm) > 0 then 
                    TBRACCD_BALANCE
                    when PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(tbraccd_pidm) = 0 then
                     0 
                End  IMPORTE,
                case 
                    when PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(tbraccd_pidm) < 0 then 
                    0 -- round ((TBRACCD_BALANCE  -  PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(tbraccd_pidm)*-1) * (SZTINTE_PCT_CARGO / 100))
                    when PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(tbraccd_pidm) > 0 then 
                    ROUND (TBRACCD_BALANCE * (SZTINTE_PCT_CARGO / 100))
                    when PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(tbraccd_pidm) = 0 then
                     0 
                End  RECARGO,                
               -- ROUND (TBRACCD_BALANCE * (SZTINTE_PCT_CARGO / 100))  RECARGO,           
                TBRACCD_EFFECTIVE_DATE+SZTINTE_DIAS FECHA, TBRACCD_EFFECTIVE_DATE,
                TBRACCD_TRAN_NUMBER TRAN,
                SUBSTR (pkg_utilerias.f_calcula_rate (pidm, programa), 4, 1)
                   rate,
                   SZTINTE_CODE_DET_C,
                   SP STUDY_PATH ,
                   PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(tbraccd_pidm) Saldo_dia              
           FROM tbraccd a
                JOIN tbbdetc b
                   ON b.TBBDETC_DETAIL_CODE = a.TBRACCD_DETAIL_CODE
                JOIN TZTNCD c
                   ON     c.TZTNCD_CODE = a.TBRACCD_DETAIL_CODE
                      AND UPPER (c.TZTNCD_CONCEPTO) = 'VENTA'
                      AND b.TBBDETC_TYPE_IND = 'C'
                      AND b.TBBDETC_DETC_ACTIVE_IND = 'Y'
                JOIN TZTPROG d
                   ON     a.TBRACCD_PIDM = d.pidm
                      AND d.estatus IN ('BA',
                                        'BD',
                                        'BI',
                                        'BT',
                                        'MA') 
                JOIN SZTINTE e
                   ON b.TBBDETC_DETAIL_CODE = e.SZTINTE_CODE_DET_C  
                   and  e.SZTINTE_RATE = SUBSTR (pkg_utilerias.f_calcula_rate (pidm, programa), 4, 1)
                   and E.SZTINTE_CAMP_CODE = D.CAMPUS
                   and E.SZTINTE_LEVL_CODE = D.NIVEL
          WHERE    
           a.TBRACCD_PIDM = NVL (P_PIDM, a.TBRACCD_PIDM)
               -- AND a.TBRACCD_TRAN_NUMBER = (select pkg_intereses.F_TBRACCD_TRANS( NVL (780014, a.TBRACCD_PIDM)) FROM DUAL)
                AND 
                 a.TBRACCD_BALANCE > 0
                and a.TBRACCD_EFFECTIVE_DATE between trunc(sysdate-30) and trunc(sysdate)
                --AND a.TBRACCD_EFFECTIVE_DATE BETWEEN TRUNC(SYSDATE,'MM')  AND LAST_DAY(TRUNC(SYSDATE))
                AND D.SP = (SELECT MAX (G.SP)
                     FROM TZTPROG G
                    WHERE G.PIDM = D.PIDM)                    
                AND A.TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTINTE_TRAN_NUMBER
                                                    FROM TZTINTE
                                                   WHERE     TZTINTE_PIDM =
                                                                TBRACCD_PIDM
                                                          --   AND tZTINTE_ACTIVITY_DATE BETWEEN TRUNC(SYSDATE,'MM') AND LAST_DAY(TRUNC(SYSDATE)))
                                                        -- AND TZTINTE_TRAN_NUMBER =
                                                       --         TBRACCD_TRAN_NUMBER
                                                       )
      AND NOT EXISTS  (SELECT 1
                        FROM GORADID f
                        WHERE 1=1
                        AND f.GORADID_ADID_CODE = 'RECU'
                        AND f.GORADID_PIDM = a.tbraccd_pidm); 
   BEGIN
     
     P_ERROR := NULL;

      FOR C IN C1
    LOOP
    
     If c.importe >0 then 
      IF C.FECHA <= TRUNC(SYSDATE) THEN 
         DBMS_OUTPUT.PUT_LINE (
            'pidm:' || c.pidm || ' categoria:' || c.dcat || '*' || c.concepto);

         --Obtiene moneda
         BEGIN
         select TVRDCTX_CURR_CODE
         into vl_moneda 
         from TVRDCTX 
         where TVRDCTX_DETC_CODE =C.SZTINTE_CODE_DET_C;
         EXCEPTION
            WHEN OTHERS
            THEN
               vl_moneda := null;
         END;
         --
         BEGIN
         /*Ontiene descripcion para la nota que cae en tbraccd*/
             SELECT TBBDETC_DESC
              INTO VL_DESCRIPCION
              FROM TBBDETC
             WHERE TBBDETC_DETAIL_CODE = C.CODIGO_CARGO;
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_DESCRIPCION := 'N/A';
         END;


            IF C.RECARGO > 0
            THEN
               SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                 INTO TRANSACCION
                 FROM TBRACCD
                WHERE TBRACCD_PIDM = C.PIDM;

               SELECT FGET_PERIODO_GENERAL (IDEN) INTO PERIODO FROM DUAL;

               BEGIN
                  DBMS_OUTPUT.PUT_LINE (
                        'TBRACCD:'
                     || c.pidm
                     || ' categoria:'
                     || c.dcat
                     || '*'
                     || c.concepto);

                  INSERT INTO TBRACCD
                       VALUES (C.PIDM,
                               TRANSACCION,
                               C.PERIODO,
                               C.CODIGO_CARGO,
                               USER,
                               SYSDATE,
                               C.RECARGO,
                               C.RECARGO,
                               SYSDATE,
                               NULL,
                               NULL,
                               VL_DESCRIPCION,
                               C.ORDEN,
                               NULL,
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
                               SYSDATE,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               vl_moneda,
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
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               'INTERES',
                               'Banner',
                               NULL,
                               NULL,
                               C.STUDY_PATH,
                               NULL,
                               NULL,
                               NULL,
                               USER,
                               NULL);

                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                P_ERROR:='Error al insertar en tbraccd la nota'||sqlerrm;

               END;


            IF P_ERROR is null 
            THEN

                  DBMS_OUTPUT.put_line (
                     'TZTINTE:' || c.pidm || ' tran:' || C.tran);
            BEGIN
                  INSERT INTO TZTINTE
                       VALUES (C.PIDM,
                               c.TRAN,
                               c.IMPORTE,
                               c.FECHA,
                               C.RECARGO,
                               TO_NUMBER (TO_CHAR (SYSDATE, 'mm')),
                               TO_NUMBER (TO_CHAR (SYSDATE, 'yyyy')),
                               SYSDATE,
                               USER);

            EXCEPTION
                 WHEN OTHERS
                 THEN
             P_ERROR:='Error al insertar en bitacora'||sqlerrm;
            END;            
             END IF; --ERROR
          END IF; --RECARGO
            
          COMMIT;
      
      END IF;--FECHA
      
     End if; --- Monto 
    END LOOP;

      COMMIT;
   END P_RECARGOS;
   
   
FUNCTION F_TBRACCD_TRANS (P_PIDM IN NUMBER DEFAULT NULL) RETURN NUMBER
   IS
      ln_trans_number NUMBER;
  BEGIN    
     
     SELECT max(TBRACCD_TRAN_NUMBER)  
           INTO ln_trans_number     
           FROM tbraccd a
                JOIN tbbdetc b
                   ON b.TBBDETC_DETAIL_CODE = a.TBRACCD_DETAIL_CODE
                JOIN TZTNCD c
                   ON     c.TZTNCD_CODE = a.TBRACCD_DETAIL_CODE
                      AND UPPER (c.TZTNCD_CONCEPTO) = 'VENTA'
                      AND b.TBBDETC_TYPE_IND = 'C'
                      AND b.TBBDETC_DETC_ACTIVE_IND = 'Y'
                JOIN TZTPROG d
                   ON     a.TBRACCD_PIDM = d.pidm
                      AND d.estatus IN ('BA',
                                        'BD',
                                        'BI',
                                        'BT',
                                        'MA') 
                JOIN SZTINTE e
                   ON b.TBBDETC_DETAIL_CODE = e.SZTINTE_CODE_DET_C  
                   and  e.SZTINTE_RATE = SUBSTR (pkg_utilerias.f_calcula_rate (pidm, programa), 4, 1)
                   and E.SZTINTE_CAMP_CODE = D.CAMPUS
                   and E.SZTINTE_LEVL_CODE = D.NIVEL
          WHERE    
           a.TBRACCD_PIDM = NVL (P_PIDM, a.TBRACCD_PIDM)
                AND
                 a.TBRACCD_BALANCE > 0
       AND D.SP = (SELECT MAX (G.SP)
                     FROM TZTPROG G
                    WHERE G.PIDM = D.PIDM)                    
                AND NOT EXISTS (SELECT 1
                                                    FROM TZTINTE
                                                   WHERE     TZTINTE_PIDM =
                                                                TBRACCD_PIDM
                                                             AND   tZTINTE_ACTIVITY_DATE BETWEEN TRUNC(SYSDATE,'MM') 
                                                 AND LAST_DAY(TRUNC(SYSDATE)))
      AND NOT EXISTS  (SELECT 1
                        FROM GORADID f
                        WHERE 1=1
                        AND f.GORADID_ADID_CODE = 'RECU'
                        AND f.GORADID_PIDM = a.tbraccd_pidm);

RETURN ln_trans_number;

END F_TBRACCD_TRANS;

   
END PKG_INTERESES;
/

DROP PUBLIC SYNONYM PKG_INTERESES;

CREATE OR REPLACE PUBLIC SYNONYM PKG_INTERESES FOR BANINST1.PKG_INTERESES;
