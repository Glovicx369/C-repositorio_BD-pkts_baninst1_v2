DROP PACKAGE BODY BANINST1.PKG_FINANZAS_DINAMICOS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_FINANZAS_DINAMICOS
AS
   /******************************************************************************
    NAME: BANINST1.PKG_FINANZAS_DINAMICOS
    PURPOSE:

    REVISIONS:
    Ver Date Author Description
    --------- ---------- --------------- ------------------------------------
    1.0 08/06/2021 jrezaoli 1. Created this package body.
   ******************************************************************************/

   FUNCTION F_PLAN_DINAMICO (P_PIDM           NUMBER,
                             P_PERIODO        VARCHAR2,
                             P_MONTO          NUMBER,
                             P_DETAIL_CODE    VARCHAR2,
                             P_DETAIL_DESC    VARCHAR2,
                             P_NUM_CARGOS     NUMBER,
                             P_AGREGA_COL     VARCHAR2,
                             P_ELIMINA        NUMBER,
                             P_SOLICITUD      NUMBER,
                             P_USUARIO        VARCHAR2,
                             P_CAMPUS         VARCHAR2 DEFAULT NULL,      
                             P_NIVEL          VARCHAR2 DEFAULT NULL,       
                             P_PROGRAMA       VARCHAR2 DEFAULT NULL,      
                             P_START_DATE     DATE     DEFAULT NULL)          
      RETURN VARCHAR2
   IS
      /*
      Proceso que se encarga de guardar los accesorios dinamicos
      Autor JREZAOLI 08/06/2021
      */
      VL_ERROR   VARCHAR2 (900)
         := 'NO EXISTE SOLICITUD VALIDAR SOLICITUD = ' || P_SOLICITUD;
      VL_SECU    NUMBER;
      VL_ENTRA   NUMBER;
   BEGIN
      BEGIN /* CANCELA TODOS LOS ACCESORIOS DINAMICOS DE UNA SOLICITUD PREVIA*/
         UPDATE TZTPADI
            SET TZTPADI_FLAG = 1
          WHERE TZTPADI_PIDM = P_PIDM AND TZTPADI_REQUEST != P_SOLICITUD;
      END;

      BEGIN
         FOR C
            IN (SELECT DISTINCT
                       SORLCUR_PIDM PIDM,
                       EXTRACT (MONTH FROM SORLCUR_START_DATE) MES,
                       EXTRACT (YEAR FROM SORLCUR_START_DATE) ANO,
                       (DECODE (SUBSTR (SARADAP_RATE_CODE, 4, 1),
                                'A', 15,
                                'B', '30',
                                'C', '10'))
                          VIG,
                       SORLCUR_PROGRAM PROGRAMA,
                         (SORLCUR_START_DATE + 12)
                       + (DECODE (SUBSTR (SARADAP_RATE_CODE, 4, 1),
                                  'A', 15,
                                  'B', '30',
                                  'C', '10'))
                       - TO_CHAR (SORLCUR_START_DATE + 12, 'DD')
                          FECHA_EDO,
                       SORLCUR_KEY_SEQNO STUDY,
                       SORLCUR_CAMP_CODE CAMPUS,
                       SORLCUR_LEVL_CODE NIVEL,
                       SARADAP_APPL_NO SOLI
                  FROM SORLCUR A, SARADAP
                 WHERE     A.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                       AND A.SORLCUR_ROLL_IND = 'N'
                       AND SARADAP_PIDM = A.SORLCUR_PIDM
                       AND SARADAP_APPL_NO = A.SORLCUR_KEY_SEQNO
                       AND SARADAP_APPL_NO = P_SOLICITUD
                       AND SARADAP_PIDM = P_PIDM)
         LOOP
            VL_ERROR := NULL;

            BEGIN
               SELECT COUNT (*)
                 INTO VL_ENTRA
                 FROM TZTPADI
                WHERE     TZTPADI_PIDM = P_PIDM
                      AND TZTPADI_DETAIL_CODE = P_DETAIL_CODE
                      AND TZTPADI_REQUEST = P_SOLICITUD
                      AND TZTPADI_FLAG = 0;
            END;

            IF VL_ENTRA = 0
            THEN
               BEGIN
                  SELECT NVL (MAX (TZTPADI_SEQNO) + 1, 1)
                    INTO VL_SECU
                    FROM TZTPADI
                   WHERE TZTPADI_PIDM = P_PIDM;
               END;

               BEGIN
                  INSERT INTO TZTPADI (TZTPADI_PIDM,
                                       TZTPADI_SEQNO,
                                       TZTPADI_TERM_CODE,
                                       TZTPADI_DETAIL_CODE,
                                       TZTPADI_DESC,
                                       TZTPADI_AMOUNT,
                                       TZTPADI_CHARGES,
                                       TZTPADI_EFFECTIVE_DATE,
                                       TZTPADI_ADD_COL,
                                       TZTPADI_FLAG,
                                       TZTPADI_DELETE,
                                       TZTPADI_REQUEST,
                                       TZTPADI_USER,
                                       TZTPADI_ACTIVITY_DATE,
                                       TZTPADI_CAMPUS,      
                                       TZTPADI_NIVEL,        
                                       TZTPADI_PROGRAMA,      
                                       TZTPADI_START_DATE)          

                       VALUES (P_PIDM,
                               VL_SECU,
                               P_PERIODO,
                               P_DETAIL_CODE,
                               P_DETAIL_DESC,
                               P_MONTO,
                               P_NUM_CARGOS,
                               C.FECHA_EDO,
                               P_AGREGA_COL,
                               0,
                               P_ELIMINA,
                               P_SOLICITUD,
                               P_USUARIO,
                               SYSDATE,
                               P_CAMPUS,      
                               P_NIVEL,        
                               P_PROGRAMA,      
                               P_START_DATE);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VL_ERROR := 'ERROR EN TZTPADI = ' || SQLERRM;
               END;
            END IF;
         END LOOP;
      END;

      IF VL_ERROR IS NULL
      THEN
         VL_ERROR := 'EXITO';
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      RETURN (VL_ERROR);
   END F_PLAN_DINAMICO;
   FUNCTION F_CAMBIO_FECHA_PADI (P_PIDM           NUMBER,
                                 P_PERIODO        VARCHAR2,
                                 P_FECHA_NUEVA    DATE,
                                 P_FECHA_OLD      DATE,
                                 P_PER_NUEVO      VARCHAR2,
                                 P_PROGRAMA       VARCHAR2)
      RETURN VARCHAR2
   IS
      VL_MES             NUMBER;
      VL_ANO             NUMBER;
      VL_VIGENCIA        DATE;
      VL_ERROR           VARCHAR2 (500);
      VL_PROPEDEUTICO    NUMBER;
      VL_MES_FECHA_OLD   NUMBER;
      VL_DIA_FECHA_OLD   NUMBER;
      VL_MES_ACC         NUMBER;
      VL_MES_APLICAR     NUMBER;
      VL_PROPEANTE       NUMBER;
      VL_RESTA           NUMBER;
   BEGIN
      FOR X
         IN (SELECT *
               FROM TZTPADI A
              WHERE     A.TZTPADI_PIDM = P_PIDM
                    AND (   A.TZTPADI_IND_CANCE != 1
                         OR A.TZTPADI_IND_CANCE IS NULL)
                    AND (   A.TZTPADI_FLAG = 0
                         OR     A.TZTPADI_FLAG = 1
                            AND A.TZTPADI_EFFECTIVE_DATE >= P_FECHA_OLD)
                    AND A.TZTPADI_REQUEST = (SELECT MAX (TZTPADI_REQUEST)
                                               FROM TZTPADI
                                              WHERE TZTPADI_PIDM = P_PIDM))
      LOOP
         VL_MES := NULL;
         VL_ANO := NULL;
         VL_MES_FECHA_OLD := NULL;
         VL_DIA_FECHA_OLD := NULL;
         VL_MES_ACC := NULL;

         IF     P_PERIODO IS NULL
            AND P_FECHA_NUEVA IS NULL
            AND P_PER_NUEVO IS NULL
            AND P_PROGRAMA IS NULL
         THEN
            BEGIN
               UPDATE TZTPADI A
                  SET A.TZTPADI_FLAG = 0
                WHERE     A.TZTPADI_PIDM = P_PIDM
                      AND A.TZTPADI_SEQNO = X.TZTPADI_SEQNO;

               IF X.TZTPADI_ADD_COL = 'Y'
               THEN
                  UPDATE TBRACCD
                     SET TBRACCD_FEED_DOC_CODE = 'CANCEL'
                   WHERE     TBRACCD_PIDM = P_PIDM
                         AND TBRACCD_DETAIL_CODE = X.TZTPADI_DETAIL_CODE
                         AND TBRACCD_FEED_DATE = P_FECHA_OLD;
               END IF;
            END;
         ELSE
            BEGIN
               SELECT EXTRACT (DAY FROM P_FECHA_OLD) DIA,
                      EXTRACT (MONTH FROM P_FECHA_OLD) MES,
                      EXTRACT (MONTH FROM X.TZTPADI_EFFECTIVE_DATE) MES_ACC,
                      EXTRACT (MONTH FROM P_FECHA_NUEVA) MES_OLD
                 INTO VL_DIA_FECHA_OLD,
                      VL_MES_FECHA_OLD,
                      VL_MES_ACC,
                      VL_MES
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  VL_ERROR := 'ERROR AL CALCULAR FECHAS = ' || SQLERRM;
            END;

            IF VL_DIA_FECHA_OLD >= 20
            THEN
               VL_MES_FECHA_OLD := VL_MES_FECHA_OLD + 1;
            END IF;

            VL_MES_APLICAR := VL_MES_ACC - VL_MES_FECHA_OLD;

            IF VL_MES_APLICAR < 0
            THEN
               VL_MES_APLICAR := VL_MES_APLICAR + 12;
            END IF;

            IF SUBSTR (P_FECHA_NUEVA, 1, 2) >= 20
            THEN
               VL_MES_APLICAR := VL_MES_APLICAR + 1;
            END IF;

            BEGIN
               SELECT SZTPTRM_PROPEDEUTICO
                 INTO VL_PROPEANTE
                 FROM SZTPTRM A
                WHERE     A.SZTPTRM_PROGRAM = P_PROGRAMA
                      AND A.SZTPTRM_TERM_CODE = P_PERIODO
                      AND A.SZTPTRM_PTRM_CODE IN (SELECT SOBPTRM_PTRM_CODE
                                                    FROM SOBPTRM
                                                   WHERE     SOBPTRM_TERM_CODE =
                                                                A.SZTPTRM_TERM_CODE
                                                         AND SOBPTRM_START_DATE =
                                                                P_FECHA_OLD);
            EXCEPTION
               WHEN OTHERS
               THEN
                  VL_PROPEANTE := 0;
            END;

            BEGIN
               SELECT SZTPTRM_PROPEDEUTICO
                 INTO VL_PROPEDEUTICO
                 FROM SZTPTRM A
                WHERE     A.SZTPTRM_PROGRAM = P_PROGRAMA
                      AND A.SZTPTRM_TERM_CODE = P_PER_NUEVO
                      AND A.SZTPTRM_PTRM_CODE IN (SELECT SOBPTRM_PTRM_CODE
                                                    FROM SOBPTRM
                                                   WHERE     SOBPTRM_TERM_CODE =
                                                                A.SZTPTRM_TERM_CODE
                                                         AND SOBPTRM_START_DATE =
                                                                P_FECHA_NUEVA);
            EXCEPTION
               WHEN OTHERS
               THEN
                  VL_PROPEDEUTICO := 0;
            END;

            IF VL_PROPEDEUTICO > 0
            THEN
               VL_MES_APLICAR := VL_MES_APLICAR + 1;
            END IF;

            IF VL_PROPEANTE > 0
            THEN
               VL_MES_APLICAR := VL_MES_APLICAR - 1;
            END IF;

            VL_VIGENCIA :=
               TO_DATE (ADD_MONTHS (P_FECHA_NUEVA, (VL_MES_APLICAR)),
                        'DD/MM/YYYY');

            IF VL_ERROR IS NULL
            THEN
               VL_RESTA :=
                    TO_CHAR (VL_VIGENCIA, 'DD')
                  - TO_CHAR (X.TZTPADI_EFFECTIVE_DATE, 'DD');
               VL_VIGENCIA := TO_DATE (VL_VIGENCIA - VL_RESTA);

               BEGIN
                  UPDATE TZTPADI
                     SET TZTPADI_EFFECTIVE_DATE = VL_VIGENCIA,
                         TZTPADI_TERM_CODE = P_PER_NUEVO,
                         TZTPADI_FLAG = 0
                   WHERE     TZTPADI_PIDM = P_PIDM
                         AND TZTPADI_SEQNO = X.TZTPADI_SEQNO;
               END;
            END IF;

            IF X.TZTPADI_ADD_COL = 'Y'
            THEN
               UPDATE TBRACCD
                  SET TBRACCD_FEED_DOC_CODE = 'CANCEL'
                WHERE     TBRACCD_PIDM = P_PIDM
                      AND TBRACCD_DETAIL_CODE = X.TZTPADI_DETAIL_CODE
                      AND TBRACCD_FEED_DATE = P_FECHA_OLD;
            END IF;
         END IF;
      END LOOP;

      IF VL_ERROR IS NULL
      THEN
         VL_ERROR := 'EXITO';
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      RETURN VL_ERROR;
   EXCEPTION
      WHEN OTHERS
      THEN
         VL_ERROR := NULL;
   END F_CAMBIO_FECHA_PADI;


    FUNCTION F_CARTERA_DINA (P_PIDM         NUMBER,
                            P_FECHA_INI    DATE,
                            P_CODIGO       VARCHAR2,
                            P_USUARIO      VARCHAR2,
                            P_ACCION       VARCHAR2)
      RETURN VARCHAR2
   IS
      VL_AJUSTE        NUMBER := 0;
      VL_APLICA        NUMBER := 0;
      VL_COSTO         NUMBER := 0;
      VL_SEC           NUMBER;
      VL_PAID          NUMBER;
      VL_CODIGO        VARCHAR2 (5);
      VL_DESCRIPCION   VARCHAR2 (50);
      VL_MONEDA        VARCHAR2 (5);
      VL_ERROR         VARCHAR2 (900);
      VL_VIGENCIA      DATE;
      VL_COSTO_REAL    NUMBER;
      VL_ENTRA_ACC     NUMBER;
      VL_ACC           VARCHAR2 (900);
      VL_ACC_COUNT     NUMBER;
      VL_FECHA_APLI    DATE;
      VL_FECHA         DATE;
      VL_FACCE         NUMBER;
      VL_SALDO         NUMBER;
      VL_SALDO_PARC    NUMBER;
      --CACELACION DE ACCESORIOS 060824 AGOG
      VL_SALUD         NUMBER;
      VL_SEQ_TZTCOTA   NUMBER;        
      --
   BEGIN
      BEGIN
         IF P_ACCION = 'CARTERA'
         THEN
            --------------------------------------------------------
            /* ENTRA AJUSTE A COLEGIATURA POR PAQUETE DINAMICO */
            --------------------------------------------------------
            BEGIN
               FOR EDC
                  IN (SELECT *
                        FROM TBRACCD
                       WHERE     TBRACCD_PIDM = P_PIDM
                             AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                             AND TBRACCD_DOCUMENT_NUMBER IS NULL
                             AND TBRACCD_FEED_DATE = P_FECHA_INI)
               LOOP
                  VL_APLICA := 0;
                  VL_AJUSTE := 0;

                  BEGIN
                     FOR CODI
                        IN (  SELECT A.*,
                                     TBBDETC_DESC DESCRIPCION,
                                     (CASE
                                         WHEN TZTPADI_CHARGES IS NULL
                                         THEN
                                            LAST_DAY (
                                               EDC.TBRACCD_EFFECTIVE_DATE)
                                         WHEN TZTPADI_CHARGES IS NOT NULL
                                         THEN
                                            ADD_MONTHS (TZTPADI_EFFECTIVE_DATE,
                                                        TZTPADI_CHARGES)
                                      END)
                                        FECHA_APLICA
                                FROM TZTPADI A, TBBDETC
                               WHERE     TZTPADI_DETAIL_CODE =
                                            TBBDETC_DETAIL_CODE
                                     AND TZTPADI_FLAG = 0
                                     AND TZTPADI_PIDM = EDC.TBRACCD_PIDM
                                     AND TZTPADI_ADD_COL = 'Y'
                                     AND TZTPADI_IND_CANCE IS NULL
                                     AND LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) BETWEEN LAST_DAY (
                                                                                          TZTPADI_EFFECTIVE_DATE)
                                                                                   AND CASE
                                                                                          WHEN TZTPADI_CHARGES
                                                                                                  IS NULL
                                                                                          THEN
                                                                                             LAST_DAY (
                                                                                                EDC.TBRACCD_EFFECTIVE_DATE)
                                                                                          WHEN TZTPADI_CHARGES
                                                                                                  IS NOT NULL
                                                                                          THEN
                                                                                             ADD_MONTHS (
                                                                                                TZTPADI_EFFECTIVE_DATE,
                                                                                                TZTPADI_CHARGES)
                                                                                       END
                            ORDER BY TZTPADI_ADD_COL DESC)
                     LOOP
                        BEGIN
                           SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                             INTO VL_SEC
                             FROM TBRACCD
                            WHERE TBRACCD_PIDM = EDC.TBRACCD_PIDM;
                        END;

                        BEGIN
                           SELECT COUNT (*)
                             INTO VL_ENTRA_ACC
                             FROM TBRACCD
                            WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                  AND TBRACCD_TERM_CODE = EDC.TBRACCD_TERM_CODE
                                  AND TBRACCD_DETAIL_CODE = CODI.TZTPADI_DETAIL_CODE
                                 -- AND TBRACCD_FEED_DATE = EDC.TBRACCD_FEED_DATE
                                  AND TBRACCD_STSP_KEY_SEQUENCE = EDC.TBRACCD_STSP_KEY_SEQUENCE
                               --   AND TBRACCD_FEED_DOC_CODE != 'CANCEL'
                                  AND TBRACCD_DATA_ORIGIN = 'TZFEDCA (ACDI)';
                        Exception
                            When no_Data_found then 
                             DBMS_OUTPUT.PUT_LINE ('Entra al nota data'||sqlerrm);    
                            
                                Begin
                                       SELECT COUNT (*)
                                         INTO VL_ENTRA_ACC
                                         FROM TBRACCD
                                        WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                              AND TBRACCD_TERM_CODE = EDC.TBRACCD_TERM_CODE
                                              AND TBRACCD_DETAIL_CODE = CODI.TZTPADI_DETAIL_CODE
                                              AND TBRACCD_STSP_KEY_SEQUENCE =  EDC.TBRACCD_STSP_KEY_SEQUENCE
                                              AND TBRACCD_DATA_ORIGIN = 'TZFEDCA (ACDI)';
                                Exception
                                    When others then 
                                    VL_ENTRA_ACC:=0;
                                    DBMS_OUTPUT.PUT_LINE ('Entra al otrhers 1'||sqlerrm);
                                End;

                             When others then 
                             DBMS_OUTPUT.PUT_LINE ('Entra al otrhers 0'||sqlerrm);
                             VL_ENTRA_ACC:=0;

                        END;

                        IF VL_ENTRA_ACC = 0    THEN
                                DBMS_OUTPUT.PUT_LINE ('Entra al Insert tbraccd '||CODI.TZTPADI_DETAIL_CODE || ' * '||VL_ENTRA_ACC);
                        
                           VL_ACC :=
                              PKG_FINANZAS.F_INSERTA_TBRACCD (
                                 EDC.TBRACCD_PIDM,
                                 VL_SEC,
                                 NULL,
                                 EDC.TBRACCD_TERM_CODE,
                                 EDC.TBRACCD_PERIOD,
                                 CODI.TZTPADI_DETAIL_CODE,
                                 0,
                                 0,
                                 EDC.TBRACCD_FEED_DATE,
                                 CODI.DESCRIPCION,
                                 EDC.TBRACCD_STSP_KEY_SEQUENCE,
                                 'TZFEDCA (ACDI)',
                                 EDC.TBRACCD_FEED_DATE);
                        END IF;

                        IF CODI.TZTPADI_CHARGES IS NOT NULL
                        THEN
                           VL_COSTO_REAL :=
                              CODI.TZTPADI_AMOUNT / CODI.TZTPADI_CHARGES;
                        ELSE
                           VL_COSTO_REAL := CODI.TZTPADI_AMOUNT;
                        END IF;

                        VL_AJUSTE := VL_COSTO_REAL;
                        VL_APLICA := VL_AJUSTE + VL_APLICA;

                        IF CODI.TZTPADI_CHARGES IS NOT NULL
                        THEN
                           BEGIN
                              SELECT COUNT (*)
                                INTO VL_ACC_COUNT
                                FROM TBRACCD
                               WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                     AND TBRACCD_CREATE_SOURCE =
                                            'TZFEDCA (PARC)'
                                     AND TBRACCD_EFFECTIVE_DATE >=
                                            CODI.TZTPADI_EFFECTIVE_DATE
                                     AND TBRACCD_DOCUMENT_NUMBER IS NULL;

                              UPDATE TBRACCD
                                 SET TBRACCD_FEED_DOC_CODE =
                                           VL_ACC_COUNT
                                        || ' DE '
                                        || CODI.TZTPADI_CHARGES
                               WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                     AND TBRACCD_DETAIL_CODE =
                                            CODI.TZTPADI_DETAIL_CODE
                                     AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                     AND TBRACCD_CREATE_SOURCE =
                                            'TZFEDCA (ACDI)'
                                     AND TBRACCD_FEED_DATE = P_FECHA_INI
                                     AND (   TBRACCD_FEED_DOC_CODE !=
                                                'CANCEL'
                                          OR TBRACCD_FEED_DOC_CODE IS NULL)
                                     AND TBRACCD_AMOUNT = 0;
                           END;
                        ELSE
                           UPDATE TBRACCD
                              SET TBRACCD_FEED_DOC_CODE = 'RECURREN'
                            WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                  AND TBRACCD_DETAIL_CODE =
                                         CODI.TZTPADI_DETAIL_CODE
                                  AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                  AND TBRACCD_CREATE_SOURCE =
                                         'TZFEDCA (ACDI)'
                                  AND TBRACCD_FEED_DATE = P_FECHA_INI
                                  AND (   TBRACCD_FEED_DOC_CODE != 'CANCEL'
                                       OR TBRACCD_FEED_DOC_CODE IS NULL)
                                  AND TBRACCD_AMOUNT = 0;
                        END IF;

                        IF     CODI.TZTPADI_CHARGES IS NOT NULL
                           AND LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) =
                                  LAST_DAY (
                                     ADD_MONTHS (CODI.TZTPADI_EFFECTIVE_DATE,
                                                 (CODI.TZTPADI_CHARGES - 1)))
                        THEN
                           BEGIN
                              UPDATE TZTPADI
                                 SET TZTPADI_FLAG = 1
                               WHERE     TZTPADI_PIDM = CODI.TZTPADI_PIDM
                                     AND TZTPADI_SEQNO = CODI.TZTPADI_SEQNO;

                              UPDATE TBRACCD
                                 SET TBRACCD_FEED_DOC_CODE =
                                           CODI.TZTPADI_CHARGES
                                        || ' DE '
                                        || CODI.TZTPADI_CHARGES
                               WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                     AND TBRACCD_DETAIL_CODE =
                                            CODI.TZTPADI_DETAIL_CODE
                                     AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                     AND TBRACCD_CREATE_SOURCE =
                                            'TZFEDCA (ACDI)'
                                     AND TBRACCD_FEED_DATE = P_FECHA_INI
                                     AND (   TBRACCD_FEED_DOC_CODE !=
                                                'CANCEL'
                                          OR TBRACCD_FEED_DOC_CODE IS NULL)
                                     AND TBRACCD_AMOUNT = 0;
                           END;
                        END IF;
                     END LOOP;

                     IF VL_APLICA != 0
                     THEN
                        PKG_FINANZAS_DINAMICOS.P_ELIMINA_TRAN (
                           EDC.TBRACCD_PIDM,
                           EDC.TBRACCD_TRAN_NUMBER,
                           VL_APLICA);
                     END IF;
                  END;
               END LOOP;
            END;

            -------------------------------------------------------
            /* INSERTA ACCESORIO POR PAQUETE DINAMICO */
            -------------------------------------------------------
            BEGIN
               FOR EDC
                  IN (SELECT *
                        FROM TBRACCD
                       WHERE     TBRACCD_PIDM = P_PIDM
                             AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                             AND TBRACCD_DOCUMENT_NUMBER IS NULL
                             AND TBRACCD_FEED_DATE = P_FECHA_INI)
               LOOP
                  BEGIN
                     FOR CODI
                        IN (SELECT *
                              FROM TZTPADI
                             WHERE     TZTPADI_FLAG = 0
                                   AND TZTPADI_PIDM = EDC.TBRACCD_PIDM
                                   AND TZTPADI_ADD_COL = 'N'
                                   AND TZTPADI_IND_CANCE IS NULL
                                   AND LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) BETWEEN LAST_DAY (
                                                                                        TZTPADI_EFFECTIVE_DATE)
                                                                                 AND LAST_DAY (
                                                                                        ADD_MONTHS (
                                                                                           TZTPADI_EFFECTIVE_DATE,
                                                                                           (  NVL (
                                                                                                 TZTPADI_CHARGES,
                                                                                                 100)
                                                                                            - 1))))
                     LOOP
                        IF CODI.TZTPADI_CHARGES IS NULL
                        THEN
                           VL_COSTO := CODI.TZTPADI_AMOUNT;
                        ELSE
                           VL_COSTO :=
                              CODI.TZTPADI_AMOUNT / CODI.TZTPADI_CHARGES;
                        END IF;

                        BEGIN
                           SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                             INTO VL_SEC
                             FROM TBRACCD
                            WHERE TBRACCD_PIDM = P_PIDM;
                        END;

                        BEGIN
                           INSERT INTO TBRACCD (TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_DESC,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_CURR_CODE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_CREATE_SOURCE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_PERIOD,
                                                TBRACCD_USER_ID,
                                                TBRACCD_RECEIPT_NUMBER)
                                VALUES (EDC.TBRACCD_PIDM,
                                        VL_SEC,
                                        NULL,
                                        EDC.TBRACCD_TERM_CODE,
                                        CODI.TZTPADI_DETAIL_CODE,
                                        USER,
                                        SYSDATE,
                                        VL_COSTO,
                                        VL_COSTO,
                                        EDC.TBRACCD_EFFECTIVE_DATE,
                                        EDC.TBRACCD_FEED_DATE,
                                        CODI.TZTPADI_DESC,
                                        'T',
                                        'Y',
                                        SYSDATE,
                                        0,
                                        EDC.TBRACCD_EFFECTIVE_DATE,
                                        'MXN',
                                        'TZFEDCA (DIN)',
                                        'TZFEDCA (DIN)',
                                        EDC.TBRACCD_STSP_KEY_SEQUENCE,
                                        EDC.TBRACCD_PERIOD,
                                        USER,
                                        EDC.TBRACCD_RECEIPT_NUMBER);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR AL INSERTAR ACC DINA' || SQLERRM;
                        END;

                        IF LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) =
                              LAST_DAY (
                                 ADD_MONTHS (CODI.TZTPADI_EFFECTIVE_DATE,
                                             (CODI.TZTPADI_CHARGES - 1)))
                        THEN
                           BEGIN
                              UPDATE TZTPADI
                                 SET TZTPADI_FLAG = 1
                               WHERE     TZTPADI_PIDM = CODI.TZTPADI_PIDM
                                     AND TZTPADI_SEQNO = CODI.TZTPADI_SEQNO;
                           END;
                        END IF;
                     END LOOP;
                  END;
               END LOOP;
            END;
         ELSIF P_ACCION = 'ELIMINA'
         THEN
            ---------------------------------------------------------
            /* SE ELIMINA LOS ACCESORIOS DINAMICOS A SOLICITUD DEL ALUMNO */
            ----------------------------------------------------------
            BEGIN
               SELECT SUM (TBRACCD_BALANCE)
                 INTO VL_SALDO
                 FROM TBRACCD
                WHERE     TBRACCD_PIDM = P_PIDM
                      AND TBRACCD_EFFECTIVE_DATE <=
                             LAST_DAY (TRUNC (SYSDATE));
            EXCEPTION
               WHEN OTHERS
               THEN
                  VL_SALDO := 0;
            END;

            BEGIN
               SELECT   TBRACCD_AMOUNT
                      - NVL (
                           (SELECT SUM (TBRACCD_AMOUNT)
                              FROM TBRACCD
                             WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                   AND (   TBRACCD_CREATE_SOURCE =
                                              'CANCELA DINA'
                                        OR     TBRACCD_CREATE_SOURCE =
                                                  'TZFEDCA(ACC)'
                                           AND SUBSTR (TBRACCD_DETAIL_CODE,
                                                       3,
                                                       2) = 'M3')
                                   AND TBRACCD_TRAN_NUMBER_PAID =
                                          A.TBRACCD_TRAN_NUMBER),
                           0)
                         SALDO
                 INTO VL_SALDO_PARC
                 FROM TBRACCD A
                WHERE     A.TBRACCD_PIDM = P_PIDM
                      AND A.TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                      AND A.TBRACCD_EFFECTIVE_DATE <=
                             LAST_DAY (TRUNC (SYSDATE));
            EXCEPTION
               WHEN OTHERS
               THEN
                  VL_SALDO_PARC := 0;
            END;

            VL_SALDO_PARC := VL_SALDO_PARC * .10;
            
            --GOG CANC PAQ FIJA 06082024
            --IF VL_SALDO > VL_SALDO_PARC  
            IF VL_SALDO >= VL_SALDO_PARC OR VL_SALDO <= VL_SALDO_PARC             
            --
            THEN
               BEGIN
                  SELECT DISTINCT (TO_DATE (TZTPADI_EFFECTIVE_DATE))
                    INTO VL_FECHA
                    FROM TZTPADI
                   WHERE     TZTPADI_PIDM = P_PIDM
                         -- AND TZTPADI_DELETE = 1
                         AND TZTPADI_IND_CANCE IS NULL
                         AND TZTPADI_DETAIL_CODE = P_CODIGO;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VL_FECHA := SYSDATE;
               END;

               IF VL_FECHA >= TRUNC (SYSDATE)
               THEN
                  VL_FECHA_APLI := VL_FECHA;
               ELSE
                  VL_FECHA_APLI := TRUNC (SYSDATE);
               END IF;

               BEGIN
                  SELECT COUNT (*)
                    INTO VL_FACCE
                    FROM ZSTPARA
                   WHERE     ZSTPARA_MAPA_ID = 'ACC_ALIANZA'
                         AND ZSTPARA_PARAM_ID = SUBSTR (P_CODIGO, 3, 2);
               END;

               -------------------------------------------------------------
               /* SE IMPLEMENTA VALIDACION DEL CÓDIGO EN TZFACCE O TZTPADI */
               -------------------------------------------------------------

               IF VL_FACCE = 0
               THEN
                  BEGIN
                     FOR ELI
                        IN (SELECT TZTPADI_PIDM,
                                   TZTPADI_SEQNO,
                                   TZTPADI_DETAIL_CODE,
                                   TZTPADI_DESC,
                                   TZTPADI_AMOUNT,
                                   TZTPADI_EFFECTIVE_DATE,
                                   TZTPADI_ADD_COL,
                                   TZTPADI_CHARGES,
                                   CASE
                                      WHEN TZTPADI_CHARGES IS NULL
                                      THEN
                                         LAST_DAY (TRUNC (SYSDATE) + 360)
                                      WHEN TZTPADI_CHARGES IS NOT NULL
                                      THEN
                                         LAST_DAY (
                                            ADD_MONTHS (
                                               TZTPADI_EFFECTIVE_DATE,
                                               TZTPADI_CHARGES))
                                   END
                                      FECHA_FINAL
                              FROM TZTPADI
                             WHERE     TZTPADI_PIDM = P_PIDM
                                   AND TZTPADI_DETAIL_CODE = P_CODIGO
                                   -- AND TZTPADI_DELETE = 1
                                   AND TZTPADI_IND_CANCE IS NULL
                                   AND LAST_DAY (VL_FECHA_APLI) BETWEEN LAST_DAY (
                                                                           TZTPADI_EFFECTIVE_DATE)
                                                                    AND CASE
                                                                           WHEN TZTPADI_CHARGES
                                                                                   IS NULL
                                                                           THEN
                                                                              LAST_DAY (
                                                                                 VL_FECHA_APLI)
                                                                           WHEN TZTPADI_CHARGES
                                                                                   IS NOT NULL
                                                                           THEN
                                                                              LAST_DAY (
                                                                                 ADD_MONTHS (
                                                                                    TZTPADI_EFFECTIVE_DATE,
                                                                                    TZTPADI_CHARGES))
                                                                        END)
                     LOOP
                        VL_PAID := NULL;

                        IF ELI.TZTPADI_CHARGES IS NOT NULL
                        THEN
                           VL_COSTO_REAL :=
                              ELI.TZTPADI_AMOUNT / ELI.TZTPADI_CHARGES;
                        ELSE
                           VL_COSTO_REAL := ELI.TZTPADI_AMOUNT;
                        END IF;

                        IF ELI.TZTPADI_ADD_COL = 'Y'
                        THEN
                           FOR EDC
                              IN (  SELECT *
                                      FROM TBRACCD A
                                     WHERE     A.TBRACCD_PIDM = P_PIDM
                                           AND A.TBRACCD_CREATE_SOURCE =
                                                  'TZFEDCA (PARC)'
                                           AND A.TBRACCD_DOCUMENT_NUMBER
                                                  IS NULL
                                           AND A.TBRACCD_EFFECTIVE_DATE >=
                                                  TRUNC (SYSDATE)
                                           AND LAST_DAY (
                                                  A.TBRACCD_EFFECTIVE_DATE) <=
                                                  LAST_DAY (ELI.FECHA_FINAL)
                                           AND (SELECT SUM (TBRACCD_BALANCE)
                                                  FROM TBRACCD
                                                 WHERE     TBRACCD_PIDM =
                                                              A.TBRACCD_PIDM
                                                       AND TBRACCD_EFFECTIVE_DATE <=
                                                              LAST_DAY (
                                                                 A.TBRACCD_EFFECTIVE_DATE)) >
                                                  0
                                  ORDER BY TBRACCD_TRAN_NUMBER)
                           LOOP
                              VL_PAID := EDC.TBRACCD_TRAN_NUMBER;

                              IF EDC.TBRACCD_BALANCE = 0
                              THEN
                                 VL_PAID := NULL;
                              END IF;

                              BEGIN
                                 SELECT TBBDETC_DETAIL_CODE,
                                        TBBDETC_DESC,
                                        TVRDCTX_CURR_CODE
                                   INTO VL_CODIGO, VL_DESCRIPCION, VL_MONEDA
                                   FROM TBBDETC, TVRDCTX
                                  WHERE     TBBDETC_DETAIL_CODE =
                                               TVRDCTX_DETC_CODE
                                        AND TBBDETC_DETAIL_CODE =
                                                  SUBSTR (
                                                     EDC.TBRACCD_DETAIL_CODE,
                                                     1,
                                                     2)
                                               || (SELECT ZSTPARA_PARAM_VALOR
                                                     FROM ZSTPARA
                                                    WHERE     ZSTPARA_MAPA_ID =
                                                                 'CAN_DINAACC'
                                                          AND ZSTPARA_PARAM_ID =
                                                                 SUBSTR (
                                                                    P_CODIGO,
                                                                    3,
                                                                    2));
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    BEGIN
                                       SELECT TBBDETC_DETAIL_CODE,
                                              TBBDETC_DESC,
                                              TVRDCTX_CURR_CODE
                                         INTO VL_CODIGO,
                                              VL_DESCRIPCION,
                                              VL_MONEDA
                                         FROM TBBDETC, TVRDCTX
                                        WHERE     TBBDETC_DETAIL_CODE =
                                                     TVRDCTX_DETC_CODE
                                              AND TBBDETC_DETAIL_CODE =
                                                        SUBSTR (
                                                           EDC.TBRACCD_TERM_CODE,
                                                           1,
                                                           2)
                                                     || 'B4';
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          VL_ERROR :=
                                                'ERROR CODIGO DINAMICOS'
                                             || SQLERRM;
                                    END;
                              END;

                              BEGIN
                                 SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                                   INTO VL_SEC
                                   FROM TBRACCD
                                  WHERE TBRACCD_PIDM = P_PIDM;
                              END;

                              IF EDC.TBRACCD_EFFECTIVE_DATE < TRUNC (SYSDATE)
                              THEN
                                 VL_VIGENCIA := TRUNC (SYSDATE);
                              ELSE
                                 VL_VIGENCIA := EDC.TBRACCD_EFFECTIVE_DATE;
                              END IF;
                    --GOG           
                     IF EDC.TBRACCD_TRANS_DATE > TRUNC(SYSDATE) THEN 
                              BEGIN
                                 INSERT
                                   INTO TBRACCD (TBRACCD_PIDM,
                                                 TBRACCD_TRAN_NUMBER,
                                                 TBRACCD_TRAN_NUMBER_PAID,
                                                 TBRACCD_TERM_CODE,
                                                 TBRACCD_DETAIL_CODE,
                                                 TBRACCD_USER,
                                                 TBRACCD_ENTRY_DATE,
                                                 TBRACCD_AMOUNT,
                                                 TBRACCD_BALANCE,
                                                 TBRACCD_EFFECTIVE_DATE,
                                                 TBRACCD_FEED_DATE,
                                                 TBRACCD_DESC,
                                                 TBRACCD_SRCE_CODE,
                                                 TBRACCD_ACCT_FEED_IND,
                                                 TBRACCD_ACTIVITY_DATE,
                                                 TBRACCD_SESSION_NUMBER,
                                                 TBRACCD_TRANS_DATE,
                                                 TBRACCD_CURR_CODE,
                                                 TBRACCD_DATA_ORIGIN,
                                                 TBRACCD_CREATE_SOURCE,
                                                 TBRACCD_STSP_KEY_SEQUENCE,
                                                 TBRACCD_PERIOD,
                                                 TBRACCD_USER_ID,
                                                 TBRACCD_RECEIPT_NUMBER,
                                                 TBRACCD_FEED_DOC_CODE)
                                 VALUES (EDC.TBRACCD_PIDM,
                                         VL_SEC,
                                         VL_PAID,
                                         EDC.TBRACCD_TERM_CODE,
                                         VL_CODIGO,
                                         P_USUARIO,
                                         SYSDATE,
                                         VL_COSTO_REAL,
                                         (VL_COSTO_REAL * -1),
                                         VL_VIGENCIA,
                                         EDC.TBRACCD_FEED_DATE,
                                         VL_DESCRIPCION,
                                         'T',
                                         'Y',
                                         SYSDATE,
                                         0,
                                         VL_VIGENCIA,
                                         VL_MONEDA,
                                         'CANCELA DINA',
                                         'CANCELA DINA',
                                         EDC.TBRACCD_STSP_KEY_SEQUENCE,
                                         EDC.TBRACCD_PERIOD,
                                         P_USUARIO,
                                         EDC.TBRACCD_RECEIPT_NUMBER,
                                         'CAN ' || ELI.TZTPADI_DETAIL_CODE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                          'ERROR AL INSERTAR ACC DINA'
                                       || SQLERRM;
                              END;

                              IF     ELI.TZTPADI_CHARGES IS NOT NULL
                                 AND LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) =
                                        LAST_DAY (
                                           ADD_MONTHS (
                                              ELI.TZTPADI_EFFECTIVE_DATE,
                                              (ELI.TZTPADI_CHARGES - 1)))
                              THEN
                                 EXIT;
                              END IF;
                            --GOG
                            END IF;
                           END LOOP;
                        ELSIF ELI.TZTPADI_ADD_COL = 'N'
                        THEN
                           /* VALIDAR SI CANCELARA ACCESORIOS */
                           FOR EDC
                              IN (  SELECT *
                                      FROM TBRACCD A
                                     WHERE     A.TBRACCD_PIDM = P_PIDM
                                           AND A.TBRACCD_CREATE_SOURCE =
                                                  'TZFEDCA (DIN)'
                                           AND A.TBRACCD_DOCUMENT_NUMBER
                                                  IS NULL
                                           AND A.TBRACCD_EFFECTIVE_DATE >=
                                                  TRUNC (SYSDATE)
                                           AND LAST_DAY (
                                                  A.TBRACCD_EFFECTIVE_DATE) <=
                                                  LAST_DAY (ELI.FECHA_FINAL)
                                           AND A.TBRACCD_DETAIL_CODE =
                                                  ELI.TZTPADI_DETAIL_CODE
                                           AND (SELECT SUM (TBRACCD_BALANCE)
                                                  FROM TBRACCD
                                                 WHERE     TBRACCD_PIDM =
                                                              A.TBRACCD_PIDM
                                                       AND TBRACCD_EFFECTIVE_DATE <=
                                                              LAST_DAY (
                                                                 A.TBRACCD_EFFECTIVE_DATE)) >
                                                  0
                                  ORDER BY TBRACCD_TRAN_NUMBER)
                           LOOP
                              VL_PAID := EDC.TBRACCD_TRAN_NUMBER;

                              IF EDC.TBRACCD_BALANCE = 0
                              THEN
                                 VL_PAID := NULL;
                              END IF;

                              BEGIN
                                 SELECT TBBDETC_DETAIL_CODE,
                                        TBBDETC_DESC,
                                        TVRDCTX_CURR_CODE
                                   INTO VL_CODIGO, VL_DESCRIPCION, VL_MONEDA
                                   FROM TBBDETC, TVRDCTX
                                  WHERE     TBBDETC_DETAIL_CODE =
                                               TVRDCTX_DETC_CODE
                                        AND TBBDETC_DETAIL_CODE =
                                                  SUBSTR (
                                                     EDC.TBRACCD_DETAIL_CODE,
                                                     1,
                                                     2)
                                               || (SELECT ZSTPARA_PARAM_VALOR
                                                     FROM ZSTPARA
                                                    WHERE     ZSTPARA_MAPA_ID =
                                                                 'CAN_DINAACC'
                                                          AND ZSTPARA_PARAM_ID =
                                                                 SUBSTR (
                                                                    P_CODIGO,
                                                                    3,
                                                                    2));
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    BEGIN
                                       SELECT TBBDETC_DETAIL_CODE,
                                              TBBDETC_DESC,
                                              TVRDCTX_CURR_CODE
                                         INTO VL_CODIGO,
                                              VL_DESCRIPCION,
                                              VL_MONEDA
                                         FROM TBBDETC, TVRDCTX
                                        WHERE     TBBDETC_DETAIL_CODE =
                                                     TVRDCTX_DETC_CODE
                                              AND TBBDETC_DETAIL_CODE =
                                                        SUBSTR (
                                                           EDC.TBRACCD_TERM_CODE,
                                                           1,
                                                           2)
                                                     || 'B4';
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          VL_ERROR :=
                                                'ERROR CODIGO DINAMICOS'
                                             || SQLERRM;
                                    END;
                              END;

                              BEGIN
                                 SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                                   INTO VL_SEC
                                   FROM TBRACCD
                                  WHERE TBRACCD_PIDM = P_PIDM;
                              END;

                              IF EDC.TBRACCD_EFFECTIVE_DATE < TRUNC (SYSDATE)
                              THEN
                                 VL_VIGENCIA := TRUNC (SYSDATE);
                              ELSE
                                 VL_VIGENCIA := EDC.TBRACCD_EFFECTIVE_DATE;
                              END IF;
                     --GOG
                     IF EDC.TBRACCD_TRANS_DATE > TRUNC(SYSDATE) THEN 
                              BEGIN
                                 INSERT
                                   INTO TBRACCD (TBRACCD_PIDM,
                                                 TBRACCD_TRAN_NUMBER,
                                                 TBRACCD_TRAN_NUMBER_PAID,
                                                 TBRACCD_TERM_CODE,
                                                 TBRACCD_DETAIL_CODE,
                                                 TBRACCD_USER,
                                                 TBRACCD_ENTRY_DATE,
                                                 TBRACCD_AMOUNT,
                                                 TBRACCD_BALANCE,
                                                 TBRACCD_EFFECTIVE_DATE,
                                                 TBRACCD_FEED_DATE,
                                                 TBRACCD_DESC,
                                                 TBRACCD_SRCE_CODE,
                                                 TBRACCD_ACCT_FEED_IND,
                                                 TBRACCD_ACTIVITY_DATE,
                                                 TBRACCD_SESSION_NUMBER,
                                                 TBRACCD_TRANS_DATE,
                                                 TBRACCD_CURR_CODE,
                                                 TBRACCD_DATA_ORIGIN,
                                                 TBRACCD_CREATE_SOURCE,
                                                 TBRACCD_STSP_KEY_SEQUENCE,
                                                 TBRACCD_PERIOD,
                                                 TBRACCD_USER_ID,
                                                 TBRACCD_RECEIPT_NUMBER,
                                                 TBRACCD_FEED_DOC_CODE)
                                 VALUES (EDC.TBRACCD_PIDM,
                                         VL_SEC,
                                         VL_PAID,
                                         EDC.TBRACCD_TERM_CODE,
                                         VL_CODIGO,
                                         P_USUARIO,
                                         SYSDATE,
                                         VL_COSTO_REAL,
                                         (VL_COSTO_REAL * -1),
                                         VL_VIGENCIA,
                                         EDC.TBRACCD_FEED_DATE,
                                         VL_DESCRIPCION,
                                         'T',
                                         'Y',
                                         SYSDATE,
                                         0,
                                         VL_VIGENCIA,
                                         VL_MONEDA,
                                         'CANCELA DINA',
                                         'CANCELA DINA',
                                         EDC.TBRACCD_STSP_KEY_SEQUENCE,
                                         EDC.TBRACCD_PERIOD,
                                         P_USUARIO,
                                         EDC.TBRACCD_RECEIPT_NUMBER,
                                         'CAN ' || ELI.TZTPADI_DETAIL_CODE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                          'ERROR AL INSERTAR ACC DINA'
                                       || SQLERRM;
                              END;

                              BEGIN
                                 UPDATE TBRACCD
                                    SET TBRACCD_FEED_DOC_CODE = 'CANCE'
                                  WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                        AND TBRACCD_TRAN_NUMBER =
                                               EDC.TBRACCD_TRAN_NUMBER;
                              END;

                              IF     ELI.TZTPADI_CHARGES IS NOT NULL
                                 AND LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) =
                                        LAST_DAY (
                                           ADD_MONTHS (
                                              ELI.TZTPADI_EFFECTIVE_DATE,
                                              (ELI.TZTPADI_CHARGES - 1)))
                              THEN
                                 EXIT;
                              END IF;
                            --GOG
                            END IF;
                           END LOOP;
                        END IF;

                        BEGIN
                           UPDATE TZTPADI
                              SET TZTPADI_IND_CANCE = 1,
                                  TZTPADI_FLAG = 1,
                                  TZTPADI_ACTIVITY_DATE = SYSDATE,
                                  TZTPADI_USER = P_USUARIO
                            WHERE     TZTPADI_PIDM = ELI.TZTPADI_PIDM
                                  AND TZTPADI_SEQNO = ELI.TZTPADI_SEQNO;
                        END;
                     END LOOP;
                  END;
               ELSE
                  FOR EDC
                     IN (  SELECT *
                             FROM TBRACCD
                            WHERE     TBRACCD_PIDM = P_PIDM
                                 -- AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (ACC)'
                                 -- AND TBRACCD_FEED_DOC_CODE IS NULL
                                  AND LAST_DAY (TBRACCD_EFFECTIVE_DATE) >=
                                         LAST_DAY (TRUNC (SYSDATE))
                                  AND TBRACCD_DETAIL_CODE = P_CODIGO
                         ORDER BY TBRACCD_TRAN_NUMBER)
                  LOOP
                     VL_PAID := EDC.TBRACCD_TRAN_NUMBER;

                     IF EDC.TBRACCD_BALANCE = 0
                     THEN
                        VL_PAID := NULL;
                     END IF;

                     BEGIN
                        SELECT TBBDETC_DETAIL_CODE,
                               TBBDETC_DESC,
                               TVRDCTX_CURR_CODE
                          INTO VL_CODIGO, VL_DESCRIPCION, VL_MONEDA
                          FROM TBBDETC, TVRDCTX
                         WHERE     TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE
                               AND TBBDETC_DETAIL_CODE =
                                      (SELECT    SUBSTR (P_CODIGO, 1, 2)
                                              || ZSTPARA_PARAM_VALOR
                                         FROM ZSTPARA
                                        WHERE     ZSTPARA_MAPA_ID =
                                                     'ACC_ALIANZA'
                                              AND ZSTPARA_PARAM_ID =
                                                     SUBSTR (P_CODIGO, 3, 2));
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VL_ERROR := 'ERROR CODIGO DINAMICOS' || SQLERRM;
                     END;

                     BEGIN
                        SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                          INTO VL_SEC
                          FROM TBRACCD
                         WHERE TBRACCD_PIDM = P_PIDM;
                     END;

                     IF EDC.TBRACCD_EFFECTIVE_DATE < TRUNC (SYSDATE)
                     THEN
                        VL_VIGENCIA := TRUNC (SYSDATE);
                     ELSE
                        VL_VIGENCIA := EDC.TBRACCD_EFFECTIVE_DATE;
                     END IF;
                    --GOG
                    IF EDC.TBRACCD_TRANS_DATE > TRUNC(SYSDATE) THEN 
                     BEGIN
                        INSERT INTO TBRACCD (TBRACCD_PIDM,
                                             TBRACCD_TRAN_NUMBER,
                                             TBRACCD_TRAN_NUMBER_PAID,
                                             TBRACCD_TERM_CODE,
                                             TBRACCD_DETAIL_CODE,
                                             TBRACCD_USER,
                                             TBRACCD_ENTRY_DATE,
                                             TBRACCD_AMOUNT,
                                             TBRACCD_BALANCE,
                                             TBRACCD_EFFECTIVE_DATE,
                                             TBRACCD_FEED_DATE,
                                             TBRACCD_DESC,
                                             TBRACCD_SRCE_CODE,
                                             TBRACCD_ACCT_FEED_IND,
                                             TBRACCD_ACTIVITY_DATE,
                                             TBRACCD_SESSION_NUMBER,
                                             TBRACCD_TRANS_DATE,
                                             TBRACCD_CURR_CODE,
                                             TBRACCD_DATA_ORIGIN,
                                             TBRACCD_CREATE_SOURCE,
                                             TBRACCD_STSP_KEY_SEQUENCE,
                                             TBRACCD_PERIOD,
                                             TBRACCD_USER_ID,
                                             TBRACCD_RECEIPT_NUMBER,
                                             TBRACCD_FEED_DOC_CODE)
                             VALUES (EDC.TBRACCD_PIDM,
                                     VL_SEC,
                                     VL_PAID,
                                     EDC.TBRACCD_TERM_CODE,
                                     VL_CODIGO,
                                     P_USUARIO,
                                     SYSDATE,
                                     EDC.TBRACCD_AMOUNT,
                                     (EDC.TBRACCD_AMOUNT * -1),
                                     VL_VIGENCIA,
                                     EDC.TBRACCD_FEED_DATE,
                                     VL_DESCRIPCION,
                                     'T',
                                     'Y',
                                     SYSDATE,
                                     0,
                                     VL_VIGENCIA,
                                     VL_MONEDA,
                                     'CANCELA DINA',
                                     'CANCELA DINA',
                                     EDC.TBRACCD_STSP_KEY_SEQUENCE,
                                     EDC.TBRACCD_PERIOD,
                                     P_USUARIO,
                                     EDC.TBRACCD_RECEIPT_NUMBER,
                                     'CAN ' || P_CODIGO);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VL_ERROR := 'ERROR AL INSERTAR ACC DINA' || SQLERRM;
                     END;

                     BEGIN
                        UPDATE TBRACCD
                           SET TBRACCD_FEED_DOC_CODE = 'CANCE'
                         WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                               AND TBRACCD_TRAN_NUMBER =
                                      EDC.TBRACCD_TRAN_NUMBER;
                     END;
                --GOG
                END IF;
                  END LOOP;

                BEGIN
                                  
                SELECT count(1)
                  INTO vl_salud  
                  FROM ZSTPARA
                 WHERE ZSTPARA_MAPA_ID = 'RECU_FIJO' 
                   AND ZSTPARA_PARAM_ID = P_CODIGO;

                select max(TZTCOTA_SEQNO) into VL_SEQ_TZTCOTA from TZTCOTA where TZTCOTA_PIDM = P_PIDM;
                
                VL_SEQ_TZTCOTA := VL_SEQ_TZTCOTA+1;
                    IF vl_salud > 0 THEN 
                    begin 
                       INSERT INTO   TZTCOTA (TZTCOTA_PIDM, TZTCOTA_TERM_CODE, TZTCOTA_CAMPUS, TZTCOTA_NIVEL, TZTCOTA_PROGRAMA, 
                                    TZTCOTA_CODIGO, TZTCOTA_SERVICIO, TZTCOTA_CARGOS, TZTCOTA_APLICADOS, TZTCOTA_SEQNO, 
                                    TZTCOTA_FLAG, TZTCOTA_USER, TZTCOTA_ORIGEN, TZTCOTA_STATUS, TZTCOTA_FECHA_INI, 
                                    TZTCOTA_ACTIVITY, TZTCOTA_OBSERVACIONES)                                                   
                            select TZTCOTA_PIDM, TZTCOTA_TERM_CODE, TZTCOTA_CAMPUS, TZTCOTA_NIVEL, TZTCOTA_PROGRAMA, 
                                    TZTCOTA_CODIGO, TZTCOTA_SERVICIO, TZTCOTA_CARGOS, TZTCOTA_APLICADOS,VL_SEQ_TZTCOTA, 
                                    TZTCOTA_FLAG, TZTCOTA_USER, TZTCOTA_ORIGEN, 'I' TZTCOTA_STATUS, TZTCOTA_FECHA_INI, 
                                    sysdate TZTCOTA_ACTIVITY, 'BAJA SALUD' TZTCOTA_OBSERVACIONES from TZTCOTA where tztcota_pidm =P_PIDM
                                    and tztcota_origen in ('Paq_Fijo','Paq_Dina') ;
                        exception when others then 
                        VL_ERROR := 'Error al insertar en TZTCOTA :'||sqlerrm;

                        end ;
                      BEGIN 
                       delete from GORADID where GORADID_PIDM= P_PIDM and GORADID_ADID_CODE in ('MDSB','MDSP','COLL');
                        exception when others then 
                        VL_ERROR := 'Error al eliminar etiqueta en GORADID :'||sqlerrm;
                        end ;
                    END IF ;
                        begin
                         UPDATE TZFACCE
                            SET TZFACCE_FLAG = 1
                          WHERE     TZFACCE_DETAIL_CODE = P_CODIGO
                                AND TZFACCE_PIDM = P_PIDM;
                        exception when others then 
                        VL_ERROR := 'Error al actualizar bandera en  TZFACCE:'||sqlerrm;
                        end ;                                                    
                END;
               END IF;
           -- ELSE
            --   VL_ERROR :=
            --      'El accesorio seleccionado no se puede cancelar, presenta saldo a favor o pagado.';
            END IF;
         END IF;
      END;
      IF VL_ERROR IS NULL
      THEN
         VL_ERROR := 'EXITO';
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      RETURN (VL_ERROR);

commit;
   END F_CARTERA_DINA;


   PROCEDURE P_ELIMINA_TRAN (P_PIDM NUMBER, P_TRAN NUMBER, P_MONTO NUMBER)
   IS
      VL_ERROR    VARCHAR2 (900);
      VL_APLICA   NUMBER := 0;
   BEGIN
      FOR X
         IN (SELECT *
               FROM TBRACCD
              WHERE     1 = 1
                    AND TBRACCD_PIDM = P_PIDM
                    AND TBRACCD_TRAN_NUMBER = P_TRAN)
      LOOP
         VL_APLICA := P_MONTO + X.TBRACCD_AMOUNT;

         BEGIN
            FOR TVRACCD
               IN (SELECT *
                     FROM TVRACCD
                    WHERE     TVRACCD_PIDM = X.TBRACCD_PIDM
                          AND TVRACCD_ACCD_TRAN_NUMBER =
                                 X.TBRACCD_TRAN_NUMBER)
            LOOP
               BEGIN
                  DELETE TVRAPPL
                   WHERE     TVRAPPL_PIDM = TVRACCD.TVRACCD_PIDM
                         AND (   TVRAPPL_PAY_TRAN_NUMBER =
                                    TVRACCD.TVRACCD_TRAN_NUMBER
                              OR TVRAPPL_CHG_TRAN_NUMBER =
                                    TVRACCD.TVRACCD_TRAN_NUMBER);
               END;
            END LOOP;
         END;

         BEGIN
            DELETE TBRAPPL
             WHERE     TBRAPPL_PIDM = X.TBRACCD_PIDM
                   AND (   TBRAPPL_PAY_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER
                        OR TBRAPPL_CHG_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER);
         END;

         BEGIN
            DELETE TVRTAXD
             WHERE     TVRTAXD_PIDM = X.TBRACCD_PIDM
                   AND TVRTAXD_ACCD_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER;
         END;

         BEGIN
            DELETE TBRACCD
             WHERE     1 = 1
                   AND TBRACCD_PIDM = X.TBRACCD_PIDM
                   AND TBRACCD_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER;
         END;

         BEGIN
            INSERT INTO TBRACCD (TBRACCD_ENTRY_DATE,
                                 TBRACCD_BILL_DATE,
                                 TBRACCD_DUE_DATE,
                                 TBRACCD_DESC,
                                 TBRACCD_TRAN_NUMBER_PAID,
                                 TBRACCD_CROSSREF_DETAIL_CODE,
                                 TBRACCD_SRCE_CODE,
                                 TBRACCD_ACCT_FEED_IND,
                                 TBRACCD_ACTIVITY_DATE,
                                 TBRACCD_SESSION_NUMBER,
                                 TBRACCD_CRN,
                                 TBRACCD_CROSSREF_SRCE_CODE,
                                 TBRACCD_LOC_MDT,
                                 TBRACCD_LOC_MDT_SEQ,
                                 TBRACCD_RATE,
                                 TBRACCD_UNITS,
                                 TBRACCD_DOCUMENT_NUMBER,
                                 TBRACCD_TRANS_DATE,
                                 TBRACCD_PAYMENT_ID,
                                 TBRACCD_INVOICE_NUMBER,
                                 TBRACCD_CURR_CODE,
                                 TBRACCD_FEED_DOC_CODE,
                                 TBRACCD_PIDM,
                                 TBRACCD_USER,
                                 TBRACCD_BALANCE,
                                 TBRACCD_RECEIPT_NUMBER,
                                 TBRACCD_TERM_CODE,
                                 TBRACCD_TRAN_NUMBER,
                                 TBRACCD_CROSSREF_NUMBER,
                                 TBRACCD_CSHR_END_DATE,
                                 TBRACCD_EFFECTIVE_DATE,
                                 TBRACCD_CROSSREF_PIDM,
                                 TBRACCD_DETAIL_CODE,
                                 TBRACCD_AMOUNT,
                                 TBRACCD_STATEMENT_DATE,
                                 TBRACCD_INV_NUMBER_PAID,
                                 TBRACCD_EXCHANGE_DIFF,
                                 TBRACCD_FOREIGN_AMOUNT,
                                 TBRACCD_LATE_DCAT_CODE,
                                 TBRACCD_FEED_DATE,
                                 TBRACCD_ATYP_CODE,
                                 TBRACCD_ATYP_SEQNO,
                                 TBRACCD_CARD_TYPE_VR,
                                 TBRACCD_CARD_EXP_DATE_VR,
                                 TBRACCD_CARD_AUTH_NUMBER_VR,
                                 TBRACCD_CROSSREF_DCAT_CODE,
                                 TBRACCD_ORIG_CHG_IND,
                                 TBRACCD_CCRD_CODE,
                                 TBRACCD_MERCHANT_ID,
                                 TBRACCD_TAX_REPT_YEAR,
                                 TBRACCD_TAX_REPT_BOX,
                                 TBRACCD_TAX_AMOUNT,
                                 TBRACCD_TAX_FUTURE_IND,
                                 TBRACCD_DATA_ORIGIN,
                                 TBRACCD_CREATE_SOURCE,
                                 TBRACCD_CPDT_IND,
                                 TBRACCD_AIDY_CODE,
                                 TBRACCD_STSP_KEY_SEQUENCE,
                                 TBRACCD_PERIOD,
                                 TBRACCD_SURROGATE_ID,
                                 TBRACCD_VERSION,
                                 TBRACCD_USER_ID,
                                 TBRACCD_VPDI_CODE)
                 VALUES (X.TBRACCD_ENTRY_DATE,
                         X.TBRACCD_BILL_DATE,
                         X.TBRACCD_DUE_DATE,
                         X.TBRACCD_DESC,
                         X.TBRACCD_TRAN_NUMBER_PAID,
                         X.TBRACCD_CROSSREF_DETAIL_CODE,
                         X.TBRACCD_SRCE_CODE,
                         X.TBRACCD_ACCT_FEED_IND,
                         X.TBRACCD_ACTIVITY_DATE,
                         X.TBRACCD_SESSION_NUMBER,
                         X.TBRACCD_CRN,
                         X.TBRACCD_CROSSREF_SRCE_CODE,
                         X.TBRACCD_LOC_MDT,
                         X.TBRACCD_LOC_MDT_SEQ,
                         X.TBRACCD_RATE,
                         X.TBRACCD_UNITS,
                         X.TBRACCD_DOCUMENT_NUMBER,
                         X.TBRACCD_TRANS_DATE,
                         X.TBRACCD_PAYMENT_ID,
                         X.TBRACCD_INVOICE_NUMBER,
                         X.TBRACCD_CURR_CODE,
                         X.TBRACCD_FEED_DOC_CODE,
                         X.TBRACCD_PIDM,
                         X.TBRACCD_USER,
                         VL_APLICA,
                         X.TBRACCD_RECEIPT_NUMBER,
                         X.TBRACCD_TERM_CODE,
                         X.TBRACCD_TRAN_NUMBER,
                         X.TBRACCD_CROSSREF_NUMBER,
                         X.TBRACCD_CSHR_END_DATE,
                         X.TBRACCD_EFFECTIVE_DATE,
                         X.TBRACCD_CROSSREF_PIDM,
                         X.TBRACCD_DETAIL_CODE,
                         VL_APLICA,
                         X.TBRACCD_STATEMENT_DATE,
                         X.TBRACCD_INV_NUMBER_PAID,
                         X.TBRACCD_EXCHANGE_DIFF,
                         X.TBRACCD_FOREIGN_AMOUNT,
                         X.TBRACCD_LATE_DCAT_CODE,
                         X.TBRACCD_FEED_DATE,
                         X.TBRACCD_ATYP_CODE,
                         X.TBRACCD_ATYP_SEQNO,
                         X.TBRACCD_CARD_TYPE_VR,
                         X.TBRACCD_CARD_EXP_DATE_VR,
                         X.TBRACCD_CARD_AUTH_NUMBER_VR,
                         X.TBRACCD_CROSSREF_DCAT_CODE,
                         X.TBRACCD_ORIG_CHG_IND,
                         X.TBRACCD_CCRD_CODE,
                         X.TBRACCD_MERCHANT_ID,
                         X.TBRACCD_TAX_REPT_YEAR,
                         X.TBRACCD_TAX_REPT_BOX,
                         X.TBRACCD_TAX_AMOUNT,
                         X.TBRACCD_TAX_FUTURE_IND,
                         X.TBRACCD_DATA_ORIGIN,
                         X.TBRACCD_CREATE_SOURCE,
                         X.TBRACCD_CPDT_IND,
                         X.TBRACCD_AIDY_CODE,
                         X.TBRACCD_STSP_KEY_SEQUENCE,
                         X.TBRACCD_PERIOD,
                         X.TBRACCD_SURROGATE_ID,
                         X.TBRACCD_VERSION,
                         X.TBRACCD_USER_ID,
                         X.TBRACCD_VPDI_CODE);
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_ERROR := 'Error al insertar TBRACCD = ' || SQLERRM;
         END;
      END LOOP;

      IF VL_ERROR IS NULL
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;
   END P_ELIMINA_TRAN;

   FUNCTION F_CURSOR_DINA (P_PIDM NUMBER, P_PERFIL VARCHAR2)
      RETURN PKG_FINANZAS_DINAMICOS.DINAMICOS
   IS
      CURSOR_DINAMICOS   PKG_FINANZAS_DINAMICOS.DINAMICOS;
      VL_FECHA           DATE;
      VL_FECHA_APLI      DATE;
      VL_SALDO           NUMBER;
      VL_SALDO_PARC      NUMBER;
   BEGIN
      BEGIN
         SELECT DISTINCT (TZTPADI_EFFECTIVE_DATE)
           INTO VL_FECHA
           FROM TZTPADI
          WHERE TZTPADI_PIDM = P_PIDM -- AND TZTPADI_DELETE = 1
                AND TZTPADI_IND_CANCE IS NULL;
      EXCEPTION
         WHEN OTHERS
         THEN
            VL_FECHA := SYSDATE;
      END;

      IF VL_FECHA >= TRUNC (SYSDATE)
      THEN
         VL_FECHA_APLI := VL_FECHA;
      ELSE
         VL_FECHA_APLI := TRUNC (SYSDATE);
      END IF;

      BEGIN
         OPEN CURSOR_DINAMICOS FOR
            SELECT DISTINCT
                   TZTPADI_DETAIL_CODE CODIGO,
                   TZTPADI_DESC DESCRIPCION,
                   CASE
                      WHEN TZTPADI_CHARGES IS NOT NULL
                      THEN
                         TZTPADI_AMOUNT / TZTPADI_CHARGES
                      WHEN TZTPADI_CHARGES IS NULL
                      THEN
                         TZTPADI_AMOUNT
                   END
                      MONTO,
                   CASE
                      WHEN TZTPADI_CHARGES IS NULL
                      THEN
                         'RECURRENTE'
                      WHEN TZTPADI_CHARGES IS NOT NULL
                      THEN
                            'FINALIZA EL '
                         || TO_CHAR (
                               ADD_MONTHS (TZTPADI_EFFECTIVE_DATE,
                                           (TZTPADI_CHARGES - 1)),
                               'DD/MM/YYYY')
                   END
                      OBSERVACION,
                   CASE
                      WHEN TZTPADI_CHARGES IS NULL
                      THEN
                         (SELECT MAX (A.TBRACCD_EFFECTIVE_DATE)
                            FROM TBRACCD A
                           WHERE     A.TBRACCD_PIDM = P_PIDM
                                 AND A.TBRACCD_CREATE_SOURCE =
                                        'TZFEDCA (PARC)'
                                 AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                                 AND LAST_DAY (A.TBRACCD_EFFECTIVE_DATE) >=
                                        LAST_DAY (TRUNC (SYSDATE)))
                      WHEN TZTPADI_CHARGES IS NOT NULL
                      THEN
                         ADD_MONTHS (TZTPADI_EFFECTIVE_DATE,
                                     (TZTPADI_CHARGES - 1))
                   END
                      FECHA,
                   SORLCUR_KEY_SEQNO STUDY
              FROM TZTPADI A1, SORLCUR A
             WHERE     A1.TZTPADI_PIDM = P_PIDM
                   AND a1.TZTPADI_FLAG = 0
                   AND A.SORLCUR_APPL_KEY_SEQNO = A1.TZTPADI_REQUEST
                   AND A.SORLCUR_PIDM = A1.TZTPADI_PIDM
                   AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                   AND A.SORLCUR_ROLL_IND = 'Y'
                   AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                   AND A.SORLCUR_SEQNO =
                          (SELECT MAX (A1.SORLCUR_SEQNO)
                             FROM SORLCUR A1
                            WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                  AND A1.SORLCUR_ROLL_IND =
                                         A.SORLCUR_ROLL_IND
                                  AND A1.SORLCUR_CACT_CODE =
                                         A.SORLCUR_CACT_CODE
                                  AND A1.SORLCUR_LMOD_CODE =
                                         A.SORLCUR_LMOD_CODE)
                   AND A1.TZTPADI_DELETE >=
                          CASE WHEN P_PERFIL = 'SI' THEN 0 ELSE 1 END
                   -- AND A1.TZTPADI_AMOUNT != 0
                   AND A1.TZTPADI_IND_CANCE IS NULL
                   AND VL_FECHA_APLI BETWEEN (  A1.TZTPADI_EFFECTIVE_DATE
                                              - (TO_CHAR (
                                                    A1.TZTPADI_EFFECTIVE_DATE,
                                                    'DD')))
                                         AND CASE
                                                WHEN A1.TZTPADI_CHARGES
                                                        IS NULL
                                                THEN
                                                   (VL_FECHA_APLI)
                                                WHEN A1.TZTPADI_CHARGES
                                                        IS NOT NULL
                                                THEN
                                                   (ADD_MONTHS (
                                                       A1.TZTPADI_EFFECTIVE_DATE,
                                                       (  A1.TZTPADI_CHARGES
                                                        - 1)))
                                             END
            UNION
            SELECT DISTINCT
                   B.TBRACCD_DETAIL_CODE CODIGO,
                   B.TBRACCD_DESC DESCRIPCION,
                   B.TBRACCD_AMOUNT MONTO,
                   'RECURRENTE' OBSERVACION,
                   (SELECT MAX (A.TBRACCD_EFFECTIVE_DATE)
                      FROM TBRACCD A
                     WHERE     A.TBRACCD_PIDM = A.TZFACCE_PIDM
                           AND A.TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                           AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                           AND LAST_DAY (A.TBRACCD_EFFECTIVE_DATE) >=
                                  LAST_DAY (TRUNC (SYSDATE)))
                      FECHA,
                   B.TBRACCD_STSP_KEY_SEQUENCE STUDY
              FROM TZFACCE A, TBRACCD B
             WHERE     A.TZFACCE_PIDM = B.TBRACCD_PIDM
                   AND A.TZFACCE_DETAIL_CODE = B.TBRACCD_DETAIL_CODE
                   AND A.TZFACCE_PIDM = P_PIDM
                   AND A.TZFACCE_FLAG = 0
                   AND SUBSTR (A.TZFACCE_DETAIL_CODE, 3, 2) IN (SELECT ZSTPARA_PARAM_ID
                                                                  FROM ZSTPARA
                                                                 WHERE ZSTPARA_MAPA_ID =
                                                                          'ACC_ALIANZA')
            UNION
                SELECT DISTINCT
                   TZTPADI_DETAIL_CODE CODIGO,
                   TZTPADI_DESC DESCRIPCION,
                   TZTPADI_AMOUNT  MONTO,
                   null  OBSERVACION,
                   TZTPADI_EFFECTIVE_DATE   FECHA,
                   SORLCUR_KEY_SEQNO STUDY
              FROM TZTPADI A1, SORLCUR A
             WHERE     A1.TZTPADI_PIDM = P_PIDM
                 and a1.TZTPADI_FLAG = 9
                 and exists (select 1 from goradid b where a1.TZTPADI_PIDM = b.GORADID_PIDM and b.GORADID_ADID_CODE in ('MDSB','MDSP'))
                 and a1.TZTPADI_AMOUNT > 0
                   AND A.SORLCUR_PIDM = A1.TZTPADI_PIDM
                   AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                   AND A.SORLCUR_ROLL_IND = 'Y'
                   AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                   AND A.SORLCUR_SEQNO =
                          (SELECT MAX (A1.SORLCUR_SEQNO)
                             FROM SORLCUR A1
                            WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                  AND A1.SORLCUR_ROLL_IND =
                                         A.SORLCUR_ROLL_IND
                                  AND A1.SORLCUR_CACT_CODE =
                                         A.SORLCUR_CACT_CODE
                                  AND A1.SORLCUR_LMOD_CODE =
                                         A.SORLCUR_LMOD_CODE);    

         RETURN (CURSOR_DINAMICOS);
      END;
   END F_CURSOR_DINA;

   FUNCTION F_DINA_CART (P_PIDM NUMBER)
      RETURN PKG_FINANZAS_DINAMICOS.CART_DINA
   IS
      CUR_TRAN_CART   PKG_FINANZAS_DINAMICOS.CART_DINA;
   BEGIN
      BEGIN
         OPEN CUR_TRAN_CART FOR
              SELECT TBRACCD_DESC DESCRIPCION,
                       (  TBRACCD_AMOUNT
                        - NVL (
                             (SELECT SUM (TBRACCD_AMOUNT)
                                FROM TBRACCD
                               WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                     AND (   TBRACCD_CREATE_SOURCE =
                                                'CANCELA DINA'
                                          OR     TBRACCD_CREATE_SOURCE =
                                                    'TZFEDCA(ACC)'
                                             AND SUBSTR (TBRACCD_DETAIL_CODE,
                                                         3,
                                                         2) = 'M3')
                                     AND TBRACCD_TRAN_NUMBER_PAID =
                                            A.TBRACCD_TRAN_NUMBER),
                             0))
                     + NVL (
                          (SELECT SUM (TBRACCD_AMOUNT)
                             FROM TBRACCD A1
                            WHERE     A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                                  AND A1.TBRACCD_CREATE_SOURCE =
                                         'TZFEDCA (ACC)'
                                  AND A1.TBRACCD_FEED_DOC_CODE IS NULL
                                  AND A1.TBRACCD_TRAN_NUMBER =
                                         (SELECT MAX (TBRACCD_TRAN_NUMBER)
                                            FROM TBRACCD
                                           WHERE     TBRACCD_PIDM =
                                                        A1.TBRACCD_PIDM
                                                 AND TBRACCD_CREATE_SOURCE =
                                                        'TZFEDCA (ACC)'
                                                 AND TBRACCD_DETAIL_CODE =
                                                        A1.TBRACCD_DETAIL_CODE)
                                  AND SUBSTR (A1.TBRACCD_DETAIL_CODE, 3, 2) IN (SELECT ZSTPARA_PARAM_ID
                                                                                  FROM ZSTPARA
                                                                                 WHERE ZSTPARA_MAPA_ID =
                                                                                          'ACC_ALIANZA')),
                          0)
                        MONTO,
                     TBRACCD_EFFECTIVE_DATE FECHA_VIGENCIA,
                     NVL (
                        (SELECT TBRACCD_DESC
                           FROM TBRACCD
                          WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                AND SUBSTR (TBRACCD_DETAIL_CODE, 3, 2) IN ('XA',
                                                                           'XH',
                                                                           'QO',
                                                                           'TH',
                                                                           'TG',
                                                                           'TF')
                                AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                AND TBRACCD_EFFECTIVE_DATE =
                                       A.TBRACCD_EFFECTIVE_DATE),
                        '---')
                        DESCRIP_COMPLEMENTO,
                     NVL (
                        (SELECT TBRACCD_AMOUNT
                           FROM TBRACCD
                          WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                AND SUBSTR (TBRACCD_DETAIL_CODE, 3, 2) IN ('XA',
                                                                           'XH',
                                                                           'QO',
                                                                           'TH',
                                                                           'TG',
                                                                           'TF')
                                AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                AND TBRACCD_EFFECTIVE_DATE =
                                       A.TBRACCD_EFFECTIVE_DATE),
                        0)
                        MONTO_COMPLEMENTO
                FROM TBRACCD A
               WHERE     A.TBRACCD_PIDM = P_PIDM
                     AND A.TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                     AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                     AND A.TBRACCD_EFFECTIVE_DATE >= TRUNC (SYSDATE)
                     AND (SELECT SUM (TBRACCD_BALANCE)
                            FROM TBRACCD
                           WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                 AND TBRACCD_EFFECTIVE_DATE <=
                                        LAST_DAY (A.TBRACCD_EFFECTIVE_DATE)) >
                            0
            ORDER BY 3;

         RETURN (CUR_TRAN_CART);
      END;
   END F_DINA_CART;

   FUNCTION F_COSTO_COMPLE (P_CAMPUS       VARCHAR2,
                            P_NIVEL        VARCHAR2,
                            P_ETIQUETA     VARCHAR2,
                            P_FECHA_SOL    VARCHAR2)
      RETURN VARCHAR2
   IS
      /* Funcion para identificar el precio de Complemento de Colegiatura
       ACTUALIZADO 22/06/2021 JREZAOLI
       */

      VL_ERROR        VARCHAR2 (900);
      VL_ENTRA        NUMBER;
      VL_FECHA_PARA   DATE;
   BEGIN
      BEGIN
         SELECT DISTINCT MAX (x.fecha)
           INTO VL_FECHA_PARA
           FROM (  SELECT DISTINCT MAX (FECHA_SOLICITUD) Fecha,
                          CODIGO,
                          costo,
                          vigencia
                     FROM TZTINC
                    WHERE     trim (campus) = P_CAMPUS
                          AND trim (nivel) = P_NIVEL
                          AND TO_DATE (P_FECHA_SOL, 'dd/mm/rrrr') >= TRUNC (FECHA_SOLICITUD)
                          And nvl (trim(AUMENTO), 0) = 0
                          And nvl (trim(NOTAS_MIN), 1) = 1
                 GROUP BY CODIGO, costo, vigencia) x;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            VL_FECHA_PARA := NULL;
         WHEN OTHERS
         THEN
            VL_FECHA_PARA := NULL;
      END;



      IF VL_FECHA_PARA IS NOT NULL
      THEN
         IF (P_ETIQUETA != 'ESPA' OR P_ETIQUETA IS NULL)
         THEN
            BEGIN
               SELECT costo
                 INTO VL_ERROR
                 FROM TZTINC, tbbdetc
                WHERE     1 = 1
                      AND CODIGO = tbbdetc_detail_code
                      AND trim (campus) = P_CAMPUS
                      AND trim (nivel) = P_NIVEL
                      AND TRUNC (FECHA_SOLICITUD) = VL_FECHA_PARA
                      And nvl (trim (AUMENTO), 0) = 0
                      And nvl (trim (NOTAS_MIN), 1) = 1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  VL_ERROR := 'SIN COMPLEMENTO';
            END;
         /*
             Codigo anterior que se maneja por el parametrizador
                          BEGIN
                          SELECT DISTINCT TBBDETC_AMOUNT
                          INTO VL_ERROR
                          FROM ZSTPARA,TBBDETC
                          WHERE TBBDETC_DETAIL_CODE = ZSTPARA_PARAM_VALOR
                          AND ZSTPARA_MAPA_ID = 'COMPL_COSTOS'
                          AND ZSTPARA_PARAM_ID = P_CAMPUS||P_NIVEL
                          AND SUBSTR(ZSTPARA_PARAM_VALOR,3,2) IN
                          CASE WHEN P_ETIQUETA = 'UAGM' THEN 'UW'
                          ELSE
                          (SELECT SUBSTR(ZSTPARA_PARAM_VALOR,3,2)
                          FROM ZSTPARA,TBBDETC
                          WHERE TBBDETC_DETAIL_CODE = ZSTPARA_PARAM_VALOR
                          AND ZSTPARA_MAPA_ID = 'COMPL_COSTOS'
                          AND ZSTPARA_PARAM_ID = P_CAMPUS||P_NIVEL
                          AND SUBSTR(ZSTPARA_PARAM_VALOR,3,2) != 'UW')
                          END;
                          EXCEPTION
                          WHEN OTHERS THEN
                          VL_ERROR:='ERROR AL CALCULAR CODIGO';
                          END;
         */

         ELSE
            VL_ERROR := 'SIN COMPLEMENTO';
         END IF;
      ELSE
         VL_ERROR := 'SIN COMPLEMENTO';
      END IF;

      RETURN (VL_ERROR);
   END F_COSTO_COMPLE;

   FUNCTION F_CURSOR_ESCALONADO (P_PIDM NUMBER)
      RETURN PKG_FINANZAS_DINAMICOS.ESCA_DINA
   IS
      CUR_ESCA_DINAMICOS   PKG_FINANZAS_DINAMICOS.ESCA_DINA;
   BEGIN
      BEGIN
         OPEN CUR_ESCA_DINAMICOS FOR
            SELECT *
              FROM (SELECT SECU,
                           TZFACCE_DETAIL_CODE CODIGO,
                           TZFACCE_DESC DESCRIPCION,
                           (SELECT DISTINCT TZFACCE_AMOUNT
                              FROM TZFACCE A1
                             WHERE     A1.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                             FROM TZTPADI)
                                   AND A1.TZFACCE_DETAIL_CODE LIKE '%M3'
                                   AND A1.TZFACCE_STUDY =
                                          (SELECT MAX (TZFACCE_STUDY)
                                             FROM TZFACCE
                                            WHERE     TZFACCE_PIDM =
                                                         A1.TZFACCE_PIDM
                                                  AND TZFACCE_STUDY
                                                         IS NOT NULL)
                                   AND A1.TZFACCE_PIDM = FACE.TZFACCE_PIDM
                                   AND A1.TZFACCE_EFFECTIVE_DATE =
                                          CASE
                                             WHEN TO_CHAR (
                                                     ADD_MONTHS (
                                                        FACE.TZFACCE_EFFECTIVE_DATE,
                                                        (SECU - 1)),
                                                     'DD') = '31'
                                             THEN
                                                  ADD_MONTHS (
                                                     FACE.TZFACCE_EFFECTIVE_DATE,
                                                     (SECU - 1))
                                                - 1
                                             ELSE
                                                ADD_MONTHS (
                                                   FACE.TZFACCE_EFFECTIVE_DATE,
                                                   (SECU - 1))
                                          END)
                              MONTO,
                           CASE
                              WHEN TO_CHAR (
                                      ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                                  (SECU - 1)),
                                      'DD') = '31'
                              THEN
                                   ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                               (SECU - 1))
                                 - 1
                              ELSE
                                 ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                             (SECU - 1))
                           END
                              FECHA_VIGENCIA,
                           (CASE
                               WHEN (SELECT COUNT (*)
                                       FROM TBRACCD
                                      WHERE     TBRACCD_PIDM =
                                                   FACE.TZFACCE_PIDM
                                            AND TBRACCD_CREATE_SOURCE =
                                                   'TZFEDCA (PARC)'
                                            AND TBRACCD_BALANCE = 0
                                            AND TBRACCD_EFFECTIVE_DATE =
                                                   CASE
                                                      WHEN TO_CHAR (
                                                              ADD_MONTHS (
                                                                 FACE.TZFACCE_EFFECTIVE_DATE,
                                                                 (SECU - 1)),
                                                              'DD') = '31'
                                                      THEN
                                                           ADD_MONTHS (
                                                              FACE.TZFACCE_EFFECTIVE_DATE,
                                                              (SECU - 1))
                                                         - 1
                                                      ELSE
                                                         ADD_MONTHS (
                                                            FACE.TZFACCE_EFFECTIVE_DATE,
                                                            (SECU - 1))
                                                   END) > 0
                               THEN
                                  'NO APLICA'
                               WHEN TZFACCE_FLAG = 3 AND SECU = 1
                               THEN
                                  'EXCLUIR'
                               ELSE
                                  CASE
                                     WHEN (SELECT COUNT (*)
                                             FROM TBRACCD
                                            WHERE     TBRACCD_PIDM =
                                                         FACE.TZFACCE_PIDM
                                                  AND TBRACCD_CREATE_SOURCE =
                                                         'TZFEDCA (PARC)'
                                                  AND TBRACCD_EFFECTIVE_DATE =
                                                         CASE
                                                            WHEN TO_CHAR (
                                                                    ADD_MONTHS (
                                                                       FACE.TZFACCE_EFFECTIVE_DATE,
                                                                       (  SECU
                                                                        - 1)),
                                                                    'DD') =
                                                                    '31'
                                                            THEN
                                                                 ADD_MONTHS (
                                                                    FACE.TZFACCE_EFFECTIVE_DATE,
                                                                    (SECU - 1))
                                                               - 1
                                                            ELSE
                                                               ADD_MONTHS (
                                                                  FACE.TZFACCE_EFFECTIVE_DATE,
                                                                  (SECU - 1))
                                                         END
                                                  AND TBRACCD_EFFECTIVE_DATE <
                                                         TRUNC (SYSDATE)) > 0
                                     THEN
                                        'NO APLICA'
                                     WHEN TZFACCE_FLAG = 3 AND SECU = 1
                                     THEN
                                        'EXCLUIR'
                                     ELSE
                                        NULL
                                  END
                            END)
                              ESTATUS
                      FROM (SELECT ROW_NUMBER ()
                                   OVER (PARTITION BY A.TZFACCE_PIDM
                                         ORDER BY A.TZFACCE_EFFECTIVE_DATE)
                                      SECU,
                                   TZFACCE_PIDM,
                                   TZFACCE_TERM_CODE,
                                   TZFACCE_DETAIL_CODE,
                                   TZFACCE_DESC,
                                   TZFACCE_EFFECTIVE_DATE,
                                   TZFACCE_FLAG,
                                   TZFACCE_STUDY
                              FROM TZFACCE A
                                   CROSS JOIN
                                   (    SELECT LEVEL NUME
                                          FROM DUAL
                                    CONNECT BY LEVEL BETWEEN 1 AND 12)
                             WHERE     A.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                            FROM TZTPADI)
                                   AND A.TZFACCE_DETAIL_CODE LIKE '%M3'
                                   AND A.TZFACCE_STUDY =
                                          (SELECT MAX (TZFACCE_STUDY)
                                             FROM TZFACCE
                                            WHERE     TZFACCE_PIDM =
                                                         A.TZFACCE_PIDM
                                                  AND TZFACCE_STUDY
                                                         IS NOT NULL)
                                   AND A.TZFACCE_EFFECTIVE_DATE =
                                          (SELECT MIN (
                                                     TZFACCE_EFFECTIVE_DATE)
                                             FROM TZFACCE
                                            WHERE     TZFACCE_PIDM =
                                                         A.TZFACCE_PIDM
                                                  AND TZFACCE_STUDY =
                                                         A.TZFACCE_STUDY
                                                  AND TZFACCE_DETAIL_CODE =
                                                         A.TZFACCE_DETAIL_CODE)
                                   AND A.TZFACCE_PIDM = P_PIDM) FACE
                     WHERE (SELECT COUNT (*)
                              FROM TZFACCE A1
                             WHERE     A1.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                             FROM TZTPADI)
                                   AND A1.TZFACCE_DETAIL_CODE LIKE '%M3'
                                   AND A1.TZFACCE_STUDY =
                                          (SELECT MAX (TZFACCE_STUDY)
                                             FROM TZFACCE
                                            WHERE     TZFACCE_PIDM =
                                                         A1.TZFACCE_PIDM
                                                  AND TZFACCE_STUDY
                                                         IS NOT NULL)
                                   AND A1.TZFACCE_PIDM = FACE.TZFACCE_PIDM
                                   AND A1.TZFACCE_EFFECTIVE_DATE =
                                          CASE
                                             WHEN TO_CHAR (
                                                     ADD_MONTHS (
                                                        FACE.TZFACCE_EFFECTIVE_DATE,
                                                        (SECU - 1)),
                                                     'DD') = '31'
                                             THEN
                                                  ADD_MONTHS (
                                                     FACE.TZFACCE_EFFECTIVE_DATE,
                                                     (SECU - 1))
                                                - 1
                                             ELSE
                                                ADD_MONTHS (
                                                   FACE.TZFACCE_EFFECTIVE_DATE,
                                                   (SECU - 1))
                                          END) > 0)
             WHERE (ESTATUS != 'EXCLUIR' OR ESTATUS IS NULL);

         RETURN (CUR_ESCA_DINAMICOS);
      END;
   END F_CURSOR_ESCALONADO;

   FUNCTION F_AJUSTE_DINA (P_PIDM       NUMBER,
                           P_NUM_ESC    NUMBER,
                           P_MONTO      NUMBER,
                           P_ACCION     VARCHAR2)
      RETURN VARCHAR2
   IS
      VL_SEC_TZFACCE   NUMBER;
      VL_SOL_TZFACCE   NUMBER;
      VL_ERROR         VARCHAR2 (900);
      VL_TRAN_ESCA     NUMBER;
      VL_SECUENCIA     NUMBER;
      VL_ETIQUETA      NUMBER;
      VL_NUMACC        NUMBER;
      VL_PARC_VIG      NUMBER;
      VL_PARC_SALDO    NUMBER;
      VL_EXISTE_PARC   NUMBER;
   BEGIN
      BEGIN
         SELECT COUNT (*)
           INTO VL_ETIQUETA
           FROM GORADID
          WHERE GORADID_PIDM = P_PIDM AND GORADID_ADID_CODE = 'DINA';
      END;

      BEGIN
         SELECT COUNT (*)
           INTO VL_NUMACC
           FROM TZFACCE A
          WHERE     A.TZFACCE_PIDM = P_PIDM
                AND A.TZFACCE_DETAIL_CODE LIKE '%M3'
                AND A.TZFACCE_STUDY =
                       (SELECT MAX (TZFACCE_STUDY)
                          FROM TZFACCE
                         WHERE     TZFACCE_PIDM = A.TZFACCE_PIDM
                               AND TZFACCE_STUDY IS NOT NULL);
      END;

      IF VL_NUMACC = 0 AND VL_ETIQUETA != 0
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO VL_EXISTE_PARC
              FROM TBRACCD
             WHERE     TBRACCD_PIDM = P_PIDM
                   AND TBRACCD_DOCUMENT_NUMBER IS NULL
                   AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)';
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_EXISTE_PARC := 0;
         END;

         IF VL_EXISTE_PARC = 0
         THEN
            VL_ERROR := 'La matricula no cuenta con cartera generada.';
         ELSE
            BEGIN
               FOR X
                  IN (SELECT *
                        FROM (SELECT SECU,
                                     PIDM,
                                     PERIODO,
                                     CODIGO,
                                     DESCRIPCION,
                                     MONTO,
                                     CASE
                                        WHEN TO_CHAR (
                                                ADD_MONTHS (VIGENCIA,
                                                            (SECU - 1)),
                                                'DD') = '31'
                                        THEN
                                             ADD_MONTHS (VIGENCIA,
                                                         (SECU - 1))
                                           - 1
                                        ELSE
                                           ADD_MONTHS (VIGENCIA, (SECU - 1))
                                     END
                                        VIGENCIA,
                                     FLAG,
                                     SOLICITUD,
                                     (SELECT MIN (TBRACCD_EFFECTIVE_DATE)
                                        FROM TBRACCD
                                       WHERE     TBRACCD_PIDM = PIDM
                                             AND TBRACCD_DOCUMENT_NUMBER
                                                    IS NULL
                                             AND TBRACCD_CREATE_SOURCE =
                                                    'TZFEDCA (PARC)')
                                        FECHA_INICIAL
                                FROM (SELECT ROW_NUMBER ()
                                             OVER (
                                                PARTITION BY TBRACCD_PIDM
                                                ORDER BY
                                                   TBRACCD_EFFECTIVE_DATE)
                                                SECU,
                                             TBRACCD_PIDM PIDM,
                                             TBRACCD_TERM_CODE PERIODO,
                                                SUBSTR (TBRACCD_DETAIL_CODE,
                                                        1,
                                                        2)
                                             || 'M3'
                                                CODIGO,
                                             'PROMOCION DE INSCRIPCION'
                                                DESCRIPCION,
                                             NULL MONTO,
                                             TBRACCD_EFFECTIVE_DATE VIGENCIA,
                                             NULL FLAG,
                                             (SELECT MAX (TZFACCE_STUDY)
                                                FROM TZFACCE
                                               WHERE     TZFACCE_PIDM =
                                                            A.TBRACCD_PIDM
                                                     AND TZFACCE_STUDY
                                                            IS NOT NULL)
                                                SOLICITUD
                                        FROM TBRACCD A
                                             CROSS JOIN
                                             (    SELECT LEVEL NUME
                                                    FROM DUAL
                                              CONNECT BY LEVEL BETWEEN 1
                                                                   AND 12)
                                       WHERE     A.TBRACCD_PIDM = P_PIDM
                                             AND A.TBRACCD_TRAN_NUMBER =
                                                    (SELECT MIN (
                                                               TBRACCD_TRAN_NUMBER)
                                                       FROM TBRACCD
                                                      WHERE     TBRACCD_PIDM =
                                                                   A.TBRACCD_PIDM
                                                            AND TBRACCD_DOCUMENT_NUMBER
                                                                   IS NULL
                                                            AND TBRACCD_CREATE_SOURCE =
                                                                   'TZFEDCA (PARC)')))
                       WHERE SECU = P_NUM_ESC)
               LOOP
                  BEGIN
                     SELECT COUNT (*)
                       INTO VL_EXISTE_PARC
                       FROM TBRACCD
                      WHERE     TBRACCD_PIDM = P_PIDM
                            AND TBRACCD_DOCUMENT_NUMBER IS NULL
                            AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA
                            AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        VL_EXISTE_PARC := 0;
                  END;

                  IF VL_EXISTE_PARC = 0
                  THEN
                     /* SI NO EXISTE PARCIALIDAD SOLO INSERTA EN TZFACCE */
                     IF P_NUM_ESC = 1
                     THEN
                        BEGIN
                           SELECT MAX (TZFACCE_SEC_PIDM) + 1
                             INTO VL_SEC_TZFACCE
                             FROM TZFACCE
                            WHERE TZFACCE_PIDM = X.PIDM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TZFACCE_STUDY), 1)
                             INTO VL_SOL_TZFACCE
                             FROM TZFACCE
                            WHERE     TZFACCE_PIDM = X.PIDM
                                  AND TZFACCE_STUDY IS NOT NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_SOL_TZFACCE := 1;
                        END;

                        BEGIN
                           INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                TZFACCE_SEC_PIDM,
                                                TZFACCE_TERM_CODE,
                                                TZFACCE_DETAIL_CODE,
                                                TZFACCE_DESC,
                                                TZFACCE_AMOUNT,
                                                TZFACCE_EFFECTIVE_DATE,
                                                TZFACCE_USER,
                                                TZFACCE_ACTIVITY_DATE,
                                                TZFACCE_FLAG,
                                                TZFACCE_STUDY)
                                VALUES (X.PIDM,
                                        VL_SEC_TZFACCE,
                                        X.PERIODO,
                                        X.CODIGO,
                                        X.DESCRIPCION,
                                        P_MONTO,
                                        X.VIGENCIA,
                                        'REZA',
                                        SYSDATE,
                                        '0',
                                        VL_SOL_TZFACCE);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR TZFACCE INSERTA = ' || SQLERRM;
                        END;
                     ELSE
                        BEGIN
                           SELECT MAX (TZFACCE_SEC_PIDM) + 1
                             INTO VL_SEC_TZFACCE
                             FROM TZFACCE
                            WHERE TZFACCE_PIDM = X.PIDM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TZFACCE_STUDY), 1)
                             INTO VL_SOL_TZFACCE
                             FROM TZFACCE
                            WHERE     TZFACCE_PIDM = X.PIDM
                                  AND TZFACCE_STUDY IS NOT NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_SOL_TZFACCE := 1;
                        END;

                        BEGIN
                           INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                TZFACCE_SEC_PIDM,
                                                TZFACCE_TERM_CODE,
                                                TZFACCE_DETAIL_CODE,
                                                TZFACCE_DESC,
                                                TZFACCE_AMOUNT,
                                                TZFACCE_EFFECTIVE_DATE,
                                                TZFACCE_USER,
                                                TZFACCE_ACTIVITY_DATE,
                                                TZFACCE_FLAG,
                                                TZFACCE_STUDY)
                                VALUES (X.PIDM,
                                        VL_SEC_TZFACCE,
                                        X.PERIODO,
                                        X.CODIGO,
                                        X.DESCRIPCION,
                                        P_MONTO,
                                        X.FECHA_INICIAL,
                                        'REZA',
                                        SYSDATE,
                                        '0',
                                        VL_SOL_TZFACCE);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR TZFACCE INSERTA = ' || SQLERRM;
                        END;

                        BEGIN
                           SELECT MAX (TZFACCE_SEC_PIDM) + 1
                             INTO VL_SEC_TZFACCE
                             FROM TZFACCE
                            WHERE TZFACCE_PIDM = X.PIDM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TZFACCE_STUDY), 1)
                             INTO VL_SOL_TZFACCE
                             FROM TZFACCE
                            WHERE     TZFACCE_PIDM = X.PIDM
                                  AND TZFACCE_STUDY IS NOT NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_SOL_TZFACCE := 1;
                        END;

                        BEGIN
                           INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                TZFACCE_SEC_PIDM,
                                                TZFACCE_TERM_CODE,
                                                TZFACCE_DETAIL_CODE,
                                                TZFACCE_DESC,
                                                TZFACCE_AMOUNT,
                                                TZFACCE_EFFECTIVE_DATE,
                                                TZFACCE_USER,
                                                TZFACCE_ACTIVITY_DATE,
                                                TZFACCE_FLAG,
                                                TZFACCE_STUDY)
                                VALUES (X.PIDM,
                                        VL_SEC_TZFACCE,
                                        X.PERIODO,
                                        X.CODIGO,
                                        X.DESCRIPCION,
                                        P_MONTO,
                                        X.VIGENCIA,
                                        'REZA',
                                        SYSDATE,
                                        '0',
                                        VL_SOL_TZFACCE);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR TZFACCE INSERTA = ' || SQLERRM;
                        END;
                     END IF;
                  ELSE
                     /* SI EXISTE PARCIALIDAD VALIDA SALDO Y VIGENCIA */
                     BEGIN
                        SELECT COUNT (*)
                          INTO VL_PARC_VIG
                          FROM TBRACCD
                         WHERE     TBRACCD_PIDM = P_PIDM
                               AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                               AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA
                               AND TBRACCD_DOCUMENT_NUMBER IS NULL
                               AND TBRACCD_EFFECTIVE_DATE > TRUNC (SYSDATE);
                     END;

                     IF VL_PARC_VIG = 0
                     THEN
                        VL_ERROR :=
                           'No se puede brindar descuento, la parcialidad se encuentra vencida.';
                     ELSE
                        BEGIN
                           SELECT NVL (TBRACCD_BALANCE, 0)
                             INTO VL_PARC_SALDO
                             FROM TBRACCD
                            WHERE     TBRACCD_PIDM = P_PIDM
                                  AND TBRACCD_CREATE_SOURCE =
                                         'TZFEDCA (PARC)'
                                  AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                  AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_PARC_SALDO := 0;
                        END;

                        IF VL_PARC_SALDO = 0
                        THEN
                           VL_ERROR :=
                              'No se puede brindar descuento, la parcialidad se encuentra pagada.';
                        ELSE
                           BEGIN
                              SELECT TBRACCD_TRAN_NUMBER
                                INTO VL_TRAN_ESCA
                                FROM TBRACCD
                               WHERE     TBRACCD_PIDM = P_PIDM
                                     AND TBRACCD_CREATE_SOURCE =
                                            'TZFEDCA (PARC)'
                                     AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                     AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 VL_TRAN_ESCA := 0;
                           END;

                           IF P_NUM_ESC = 1
                           THEN
                              BEGIN
                                 SELECT MAX (TZFACCE_SEC_PIDM) + 1
                                   INTO VL_SEC_TZFACCE
                                   FROM TZFACCE
                                  WHERE TZFACCE_PIDM = X.PIDM;
                              END;

                              BEGIN
                                 SELECT NVL (MAX (TZFACCE_STUDY), 1)
                                   INTO VL_SOL_TZFACCE
                                   FROM TZFACCE
                                  WHERE     TZFACCE_PIDM = X.PIDM
                                        AND TZFACCE_STUDY IS NOT NULL;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_SOL_TZFACCE := 1;
                              END;

                              BEGIN
                                 INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                      TZFACCE_SEC_PIDM,
                                                      TZFACCE_TERM_CODE,
                                                      TZFACCE_DETAIL_CODE,
                                                      TZFACCE_DESC,
                                                      TZFACCE_AMOUNT,
                                                      TZFACCE_EFFECTIVE_DATE,
                                                      TZFACCE_USER,
                                                      TZFACCE_ACTIVITY_DATE,
                                                      TZFACCE_FLAG,
                                                      TZFACCE_STUDY)
                                      VALUES (X.PIDM,
                                              VL_SEC_TZFACCE,
                                              X.PERIODO,
                                              X.CODIGO,
                                              X.DESCRIPCION,
                                              P_MONTO,
                                              X.VIGENCIA,
                                              'REZA',
                                              SYSDATE,
                                              '1',
                                              VL_SOL_TZFACCE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                       'ERROR TZFACCE INSERTA = ' || SQLERRM;
                              END;

                              BEGIN
                                 SELECT   NVL (MAX (TBRACCD_TRAN_NUMBER), 0)
                                        + 1
                                   INTO VL_SECUENCIA
                                   FROM TBRACCD
                                  WHERE TBRACCD_PIDM = P_PIDM;
                              END;

                              BEGIN
                                 INSERT INTO TBRACCD (
                                                TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_DESC,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_SURROGATE_ID,
                                                TBRACCD_VERSION,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_CREATE_SOURCE,
                                                TBRACCD_PERIOD,
                                                TBRACCD_RECEIPT_NUMBER)
                                    (SELECT TBRACCD_PIDM,
                                            VL_SECUENCIA,
                                            TBRACCD_TERM_CODE,
                                            SUBSTR (X.CODIGO, 1, 2) || 'M3',
                                            P_MONTO,
                                            P_MONTO * -1,
                                            'PROMOCION DE INSCRIPCION',
                                            USER,
                                            SYSDATE,
                                            X.VIGENCIA,
                                            X.VIGENCIA,
                                            TBRACCD_SRCE_CODE,
                                            TBRACCD_ACCT_FEED_IND,
                                            SYSDATE,
                                            0,
                                            NULL,
                                            NULL,
                                            VL_TRAN_ESCA,
                                            TBRACCD_FEED_DATE,
                                            TBRACCD_STSP_KEY_SEQUENCE,
                                            'TZFEDCA(ACC)',
                                            'TZFEDCA(ACC)',
                                            TBRACCD_PERIOD,
                                            TBRACCD_RECEIPT_NUMBER
                                       FROM TBRACCD A1
                                      WHERE     A1.TBRACCD_PIDM = P_PIDM
                                            AND TBRACCD_CREATE_SOURCE =
                                                   'TZFEDCA (PARC)'
                                            AND TBRACCD_DOCUMENT_NUMBER
                                                   IS NULL
                                            AND TBRACCD_EFFECTIVE_DATE =
                                                   X.VIGENCIA);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                          ' ERRROR AL INSERTAR TBRACCD REZA = '
                                       || SQLERRM;
                              END;
                           ELSE
                              /* SI EL ESCALONADO ES DIFERENTE A 1, AGREGA EL ESCALONADO 1 Y EL QUE SE VA A APLICAR*/
                              BEGIN
                                 SELECT MAX (TZFACCE_SEC_PIDM) + 1
                                   INTO VL_SEC_TZFACCE
                                   FROM TZFACCE
                                  WHERE TZFACCE_PIDM = X.PIDM;
                              END;

                              BEGIN
                                 SELECT NVL (MAX (TZFACCE_STUDY), 1)
                                   INTO VL_SOL_TZFACCE
                                   FROM TZFACCE
                                  WHERE     TZFACCE_PIDM = X.PIDM
                                        AND TZFACCE_STUDY IS NOT NULL;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_SOL_TZFACCE := 1;
                              END;

                              BEGIN
                                 INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                      TZFACCE_SEC_PIDM,
                                                      TZFACCE_TERM_CODE,
                                                      TZFACCE_DETAIL_CODE,
                                                      TZFACCE_DESC,
                                                      TZFACCE_AMOUNT,
                                                      TZFACCE_EFFECTIVE_DATE,
                                                      TZFACCE_USER,
                                                      TZFACCE_ACTIVITY_DATE,
                                                      TZFACCE_FLAG,
                                                      TZFACCE_STUDY)
                                      VALUES (X.PIDM,
                                              VL_SEC_TZFACCE,
                                              X.PERIODO,
                                              X.CODIGO,
                                              X.DESCRIPCION,
                                              P_MONTO,
                                              X.FECHA_INICIAL,
                                              'REZA',
                                              SYSDATE,
                                              '3',
                                              VL_SOL_TZFACCE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                       'ERROR TZFACCE INSERTA = ' || SQLERRM;
                              END;

                              BEGIN
                                 SELECT MAX (TZFACCE_SEC_PIDM) + 1
                                   INTO VL_SEC_TZFACCE
                                   FROM TZFACCE
                                  WHERE TZFACCE_PIDM = X.PIDM;
                              END;

                              BEGIN
                                 SELECT NVL (MAX (TZFACCE_STUDY), 1)
                                   INTO VL_SOL_TZFACCE
                                   FROM TZFACCE
                                  WHERE     TZFACCE_PIDM = X.PIDM
                                        AND TZFACCE_STUDY IS NOT NULL;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_SOL_TZFACCE := 1;
                              END;

                              BEGIN
                                 INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                      TZFACCE_SEC_PIDM,
                                                      TZFACCE_TERM_CODE,
                                                      TZFACCE_DETAIL_CODE,
                                                      TZFACCE_DESC,
                                                      TZFACCE_AMOUNT,
                                                      TZFACCE_EFFECTIVE_DATE,
                                                      TZFACCE_USER,
                                                      TZFACCE_ACTIVITY_DATE,
                                                      TZFACCE_FLAG,
                                                      TZFACCE_STUDY)
                                      VALUES (X.PIDM,
                                              VL_SEC_TZFACCE,
                                              X.PERIODO,
                                              X.CODIGO,
                                              X.DESCRIPCION,
                                              P_MONTO,
                                              X.VIGENCIA,
                                              'REZA',
                                              SYSDATE,
                                              '1',
                                              VL_SOL_TZFACCE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                       'ERROR TZFACCE INSERTA = ' || SQLERRM;
                              END;

                              BEGIN
                                 SELECT   NVL (MAX (TBRACCD_TRAN_NUMBER), 0)
                                        + 1
                                   INTO VL_SECUENCIA
                                   FROM TBRACCD
                                  WHERE TBRACCD_PIDM = P_PIDM;
                              END;

                              BEGIN
                                 INSERT INTO TBRACCD (
                                                TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_DESC,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_SURROGATE_ID,
                                                TBRACCD_VERSION,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_CREATE_SOURCE,
                                                TBRACCD_PERIOD,
                                                TBRACCD_RECEIPT_NUMBER)
                                    (SELECT TBRACCD_PIDM,
                                            VL_SECUENCIA,
                                            TBRACCD_TERM_CODE,
                                            SUBSTR (X.CODIGO, 1, 2) || 'M3',
                                            P_MONTO,
                                            P_MONTO * -1,
                                            'PROMOCION DE INSCRIPCION',
                                            USER,
                                            SYSDATE,
                                            X.VIGENCIA,
                                            X.VIGENCIA,
                                            TBRACCD_SRCE_CODE,
                                            TBRACCD_ACCT_FEED_IND,
                                            SYSDATE,
                                            0,
                                            NULL,
                                            NULL,
                                            VL_TRAN_ESCA,
                                            TBRACCD_FEED_DATE,
                                            TBRACCD_STSP_KEY_SEQUENCE,
                                            'TZFEDCA(ACC)',
                                            'TZFEDCA(ACC)',
                                            TBRACCD_PERIOD,
                                            TBRACCD_RECEIPT_NUMBER
                                       FROM TBRACCD A1
                                      WHERE     A1.TBRACCD_PIDM = P_PIDM
                                            AND TBRACCD_CREATE_SOURCE =
                                                   'TZFEDCA (PARC)'
                                            AND TBRACCD_DOCUMENT_NUMBER
                                                   IS NULL
                                            AND TBRACCD_EFFECTIVE_DATE =
                                                   X.VIGENCIA);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                          ' ERRROR AL INSERTAR TBRACCD REZA = '
                                       || SQLERRM;
                              END;
                           END IF;
                        END IF;
                     END IF;
                  END IF;
               END LOOP;
            END;
         END IF;
      ELSE
         BEGIN
            FOR X
               IN (SELECT SECU,
                          TZFACCE_PIDM PIDM,
                          TZFACCE_TERM_CODE PERIODO,
                          TZFACCE_DETAIL_CODE CODIGO,
                          TZFACCE_DESC DESCRIPCION,
                          (SELECT DISTINCT TZFACCE_AMOUNT
                             FROM TZFACCE A1
                            WHERE     A1.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                            FROM TZTPADI)
                                  AND A1.TZFACCE_DETAIL_CODE LIKE '%M3'
                                  AND A1.TZFACCE_STUDY =
                                         (SELECT MAX (TZFACCE_STUDY)
                                            FROM TZFACCE
                                           WHERE     TZFACCE_PIDM =
                                                        A1.TZFACCE_PIDM
                                                 AND TZFACCE_STUDY
                                                        IS NOT NULL)
                                  AND A1.TZFACCE_PIDM = FACE.TZFACCE_PIDM
                                  AND A1.TZFACCE_EFFECTIVE_DATE =
                                         CASE
                                            WHEN TO_CHAR (
                                                    ADD_MONTHS (
                                                       FACE.TZFACCE_EFFECTIVE_DATE,
                                                       (SECU - 1)),
                                                    'DD') = '31'
                                            THEN
                                                 ADD_MONTHS (
                                                    FACE.TZFACCE_EFFECTIVE_DATE,
                                                    (SECU - 1))
                                               - 1
                                            ELSE
                                               ADD_MONTHS (
                                                  FACE.TZFACCE_EFFECTIVE_DATE,
                                                  (SECU - 1))
                                         END)
                             MONTO,
                          CASE
                             WHEN TO_CHAR (
                                     ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                                 (SECU - 1)),
                                     'DD') = '31'
                             THEN
                                  ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                              (SECU - 1))
                                - 1
                             ELSE
                                ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                            (SECU - 1))
                          END
                             VIGENCIA,
                          (SELECT DISTINCT TZFACCE_FLAG
                             FROM TZFACCE A1
                            WHERE     A1.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                            FROM TZTPADI)
                                  AND A1.TZFACCE_DETAIL_CODE LIKE '%M3'
                                  AND A1.TZFACCE_STUDY =
                                         (SELECT MAX (TZFACCE_STUDY)
                                            FROM TZFACCE
                                           WHERE     TZFACCE_PIDM =
                                                        A1.TZFACCE_PIDM
                                                 AND TZFACCE_STUDY
                                                        IS NOT NULL)
                                  AND A1.TZFACCE_PIDM = FACE.TZFACCE_PIDM
                                  AND A1.TZFACCE_EFFECTIVE_DATE =
                                         CASE
                                            WHEN TO_CHAR (
                                                    ADD_MONTHS (
                                                       FACE.TZFACCE_EFFECTIVE_DATE,
                                                       (SECU - 1)),
                                                    'DD') = '31'
                                            THEN
                                                 ADD_MONTHS (
                                                    FACE.TZFACCE_EFFECTIVE_DATE,
                                                    (SECU - 1))
                                               - 1
                                            ELSE
                                               ADD_MONTHS (
                                                  FACE.TZFACCE_EFFECTIVE_DATE,
                                                  (SECU - 1))
                                         END)
                             FLAG,
                          TZFACCE_STUDY SOLICITUD
                     FROM (SELECT ROW_NUMBER ()
                                  OVER (PARTITION BY A.TZFACCE_PIDM
                                        ORDER BY A.TZFACCE_EFFECTIVE_DATE)
                                     SECU,
                                  TZFACCE_PIDM,
                                  TZFACCE_TERM_CODE,
                                  TZFACCE_DETAIL_CODE,
                                  TZFACCE_DESC,
                                  TZFACCE_EFFECTIVE_DATE,
                                  TZFACCE_FLAG,
                                  TZFACCE_STUDY
                             FROM TZFACCE A
                                  CROSS JOIN
                                  (    SELECT LEVEL NUME
                                         FROM DUAL
                                   CONNECT BY LEVEL BETWEEN 1 AND 12)
                            WHERE     A.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                           FROM TZTPADI)
                                  AND A.TZFACCE_DETAIL_CODE LIKE '%M3'
                                  AND A.TZFACCE_STUDY =
                                         (SELECT MAX (TZFACCE_STUDY)
                                            FROM TZFACCE
                                           WHERE     TZFACCE_PIDM =
                                                        A.TZFACCE_PIDM
                                                 AND TZFACCE_STUDY
                                                        IS NOT NULL)
                                  AND A.TZFACCE_EFFECTIVE_DATE =
                                         (SELECT MIN (TZFACCE_EFFECTIVE_DATE)
                                            FROM TZFACCE
                                           WHERE     TZFACCE_PIDM =
                                                        A.TZFACCE_PIDM
                                                 AND TZFACCE_STUDY =
                                                        A.TZFACCE_STUDY
                                                 AND TZFACCE_DETAIL_CODE =
                                                        A.TZFACCE_DETAIL_CODE)
                                  AND A.TZFACCE_PIDM = P_PIDM) FACE
                    WHERE SECU = P_NUM_ESC)
            LOOP
               VL_ERROR := NULL;

               IF P_ACCION = 'EDITAR'
               THEN
                  IF X.FLAG IS NULL
                  THEN
                     /* NO EXISTE ESCALONADO EN EDC */
                     BEGIN
                        SELECT TBRACCD_TRAN_NUMBER
                          INTO VL_TRAN_ESCA
                          FROM TBRACCD
                         WHERE     TBRACCD_PIDM = P_PIDM
                               AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                               AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VL_TRAN_ESCA := 0;
                     END;

                     IF VL_TRAN_ESCA = 0
                     THEN
                        BEGIN
                           SELECT MAX (TZFACCE_SEC_PIDM) + 1
                             INTO VL_SEC_TZFACCE
                             FROM TZFACCE
                            WHERE TZFACCE_PIDM = X.PIDM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TZFACCE_STUDY), 1)
                             INTO VL_SOL_TZFACCE
                             FROM TZFACCE
                            WHERE     TZFACCE_PIDM = X.PIDM
                                  AND TZFACCE_STUDY IS NOT NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_SOL_TZFACCE := 1;
                        END;

                        BEGIN
                           INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                TZFACCE_SEC_PIDM,
                                                TZFACCE_TERM_CODE,
                                                TZFACCE_DETAIL_CODE,
                                                TZFACCE_DESC,
                                                TZFACCE_AMOUNT,
                                                TZFACCE_EFFECTIVE_DATE,
                                                TZFACCE_USER,
                                                TZFACCE_ACTIVITY_DATE,
                                                TZFACCE_FLAG,
                                                TZFACCE_STUDY)
                                VALUES (X.PIDM,
                                        VL_SEC_TZFACCE,
                                        X.PERIODO,
                                        X.CODIGO,
                                        X.DESCRIPCION,
                                        P_MONTO,
                                        X.VIGENCIA,
                                        'REZA',
                                        SYSDATE,
                                        '0',
                                        VL_SOL_TZFACCE);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR TZFACCE INSERTA = ' || SQLERRM;
                        END;
                     ELSE
                        BEGIN
                           SELECT MAX (TZFACCE_SEC_PIDM) + 1
                             INTO VL_SEC_TZFACCE
                             FROM TZFACCE
                            WHERE TZFACCE_PIDM = X.PIDM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TZFACCE_STUDY), 1)
                             INTO VL_SOL_TZFACCE
                             FROM TZFACCE
                            WHERE     TZFACCE_PIDM = X.PIDM
                                  AND TZFACCE_STUDY IS NOT NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_SOL_TZFACCE := 1;
                        END;

                        BEGIN
                           INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                TZFACCE_SEC_PIDM,
                                                TZFACCE_TERM_CODE,
                                                TZFACCE_DETAIL_CODE,
                                                TZFACCE_DESC,
                                                TZFACCE_AMOUNT,
                                                TZFACCE_EFFECTIVE_DATE,
                                                TZFACCE_USER,
                                                TZFACCE_ACTIVITY_DATE,
                                                TZFACCE_FLAG,
                                                TZFACCE_STUDY)
                                VALUES (X.PIDM,
                                        VL_SEC_TZFACCE,
                                        X.PERIODO,
                                        X.CODIGO,
                                        X.DESCRIPCION,
                                        P_MONTO,
                                        X.VIGENCIA,
                                        'REZA',
                                        SYSDATE,
                                        '1',
                                        VL_SOL_TZFACCE);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR TZFACCE INSERTA = ' || SQLERRM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TBRACCD_TRAN_NUMBER), 0) + 1
                             INTO VL_SECUENCIA
                             FROM TBRACCD
                            WHERE TBRACCD_PIDM = P_PIDM;
                        END;

                        BEGIN
                           INSERT INTO TBRACCD (TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_DESC,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_SURROGATE_ID,
                                                TBRACCD_VERSION,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_CREATE_SOURCE,
                                                TBRACCD_PERIOD,
                                                TBRACCD_RECEIPT_NUMBER)
                              (SELECT TBRACCD_PIDM,
                                      VL_SECUENCIA,
                                      TBRACCD_TERM_CODE,
                                      SUBSTR (X.CODIGO, 1, 2) || 'M3',
                                      P_MONTO,
                                      P_MONTO * -1,
                                      'PROMOCION DE INSCRIPCION',
                                      USER,
                                      SYSDATE,
                                      X.VIGENCIA,
                                      X.VIGENCIA,
                                      TBRACCD_SRCE_CODE,
                                      TBRACCD_ACCT_FEED_IND,
                                      SYSDATE,
                                      0,
                                      NULL,
                                      NULL,
                                      VL_TRAN_ESCA,
                                      TBRACCD_FEED_DATE,
                                      TBRACCD_STSP_KEY_SEQUENCE,
                                      'TZFEDCA(ACC)',
                                      'TZFEDCA(ACC)',
                                      TBRACCD_PERIOD,
                                      TBRACCD_RECEIPT_NUMBER
                                 FROM TBRACCD A1
                                WHERE     A1.TBRACCD_PIDM = P_PIDM
                                      AND A1.TBRACCD_CREATE_SOURCE =
                                             'TZFEDCA (PARC)'
                                      AND A1.TBRACCD_DOCUMENT_NUMBER IS NULL
                                      AND A1.TBRACCD_EFFECTIVE_DATE =
                                             X.VIGENCIA);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                    ' ERRROR AL INSERTAR TBRACCD REZA = '
                                 || SQLERRM;
                        END;
                     END IF;
                  ELSIF X.FLAG = 3
                  THEN
                     BEGIN
                        SELECT TBRACCD_TRAN_NUMBER
                          INTO VL_TRAN_ESCA
                          FROM TBRACCD
                         WHERE     TBRACCD_PIDM = P_PIDM
                               AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                               AND TBRACCD_DOCUMENT_NUMBER IS NULL
                               AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VL_TRAN_ESCA := 0;
                     END;

                     IF VL_TRAN_ESCA = 0
                     THEN
                        BEGIN
                           UPDATE TZFACCE
                              SET TZFACCE_FLAG = 0, TZFACCE_AMOUNT = P_MONTO
                            WHERE     TZFACCE_PIDM = P_PIDM
                                  AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA;
                        END;
                     ELSE
                        BEGIN
                           UPDATE TZFACCE
                              SET TZFACCE_FLAG = 1, TZFACCE_AMOUNT = P_MONTO
                            WHERE     TZFACCE_PIDM = P_PIDM
                                  AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA;
                        END;


                        BEGIN
                           SELECT NVL (MAX (TBRACCD_TRAN_NUMBER), 0) + 1
                             INTO VL_SECUENCIA
                             FROM TBRACCD
                            WHERE TBRACCD_PIDM = P_PIDM;
                        END;

                        BEGIN
                           INSERT INTO TBRACCD (TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_DESC,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_SURROGATE_ID,
                                                TBRACCD_VERSION,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_CREATE_SOURCE,
                                                TBRACCD_PERIOD,
                                                TBRACCD_RECEIPT_NUMBER)
                              (SELECT TBRACCD_PIDM,
                                      VL_SECUENCIA,
                                      TBRACCD_TERM_CODE,
                                      SUBSTR (X.CODIGO, 1, 2) || 'M3',
                                      P_MONTO,
                                      P_MONTO * -1,
                                      'PROMOCION DE INSCRIPCION',
                                      USER,
                                      SYSDATE,
                                      X.VIGENCIA,
                                      X.VIGENCIA,
                                      TBRACCD_SRCE_CODE,
                                      TBRACCD_ACCT_FEED_IND,
                                      SYSDATE,
                                      0,
                                      NULL,
                                      NULL,
                                      VL_TRAN_ESCA,
                                      TBRACCD_FEED_DATE,
                                      TBRACCD_STSP_KEY_SEQUENCE,
                                      'TZFEDCA(ACC)',
                                      'TZFEDCA(ACC)',
                                      TBRACCD_PERIOD,
                                      TBRACCD_RECEIPT_NUMBER
                                 FROM TBRACCD A1
                                WHERE     A1.TBRACCD_PIDM = P_PIDM
                                      AND TBRACCD_CREATE_SOURCE =
                                             'TZFEDCA (PARC)'
                                      AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                      AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                    ' ERRROR AL INSERTAR TBRACCD REZA = '
                                 || SQLERRM;
                        END;
                     END IF;
                  ELSE
                     IF X.FLAG = 0
                     THEN
                        BEGIN
                           UPDATE TZFACCE
                              SET TZFACCE_AMOUNT = P_MONTO
                            WHERE     TZFACCE_PIDM = P_PIDM
                                  AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                                  AND TZFACCE_FLAG = 0;
                        END;
                     ELSE
                        BEGIN
                           SELECT TBRACCD_TRAN_NUMBER
                             INTO VL_TRAN_ESCA
                             FROM TBRACCD
                            WHERE     TBRACCD_PIDM = P_PIDM
                                  AND TBRACCD_CREATE_SOURCE = 'TZFEDCA(ACC)'
                                  AND SUBSTR (TBRACCD_DETAIL_CODE, 3, 2) =
                                         'M3'
                                  AND TBRACCD_FEED_DOC_CODE IS NULL
                                  AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_TRAN_ESCA := 0;
                        END;

                        IF VL_TRAN_ESCA != 0
                        THEN
                           PKG_FINANZAS.P_DESAPLICA_PAGOS (P_PIDM,
                                                           VL_TRAN_ESCA);
                           PKG_FINANZAS_DINAMICOS.P_ACTUA_ESCA (P_PIDM,
                                                                VL_TRAN_ESCA,
                                                                P_MONTO);

                           BEGIN
                              UPDATE TZFACCE
                                 SET TZFACCE_AMOUNT = P_MONTO
                               WHERE     TZFACCE_PIDM = P_PIDM
                                     AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                                     AND TZFACCE_FLAG = 1;
                           END;
                        END IF;
                     END IF;
                  END IF;
               ELSIF P_ACCION = 'ELIMINA'
               THEN
                  IF X.FLAG = 0
                  THEN
                     IF X.SECU = 1
                     THEN
                        UPDATE TZFACCE
                           SET TZFACCE_FLAG = 3
                         WHERE     TZFACCE_PIDM = P_PIDM
                               AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                               AND TZFACCE_FLAG = 0;
                     ELSE
                        BEGIN
                           DELETE TZFACCE
                            WHERE     TZFACCE_PIDM = P_PIDM
                                  AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                                  AND TZFACCE_FLAG = 0;
                        END;
                     END IF;
                  ELSE
                     BEGIN
                        SELECT TBRACCD_TRAN_NUMBER
                          INTO VL_TRAN_ESCA
                          FROM TBRACCD
                         WHERE     TBRACCD_PIDM = P_PIDM
                               AND TBRACCD_CREATE_SOURCE = 'TZFEDCA(ACC)'
                               AND SUBSTR (TBRACCD_DETAIL_CODE, 3, 2) = 'M3'
                               AND TBRACCD_FEED_DOC_CODE IS NULL
                               AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VL_TRAN_ESCA := 0;
                     END;

                     DBMS_OUTPUT.PUT_LINE (
                        'REZA DINAMICOS = ' || VL_TRAN_ESCA);

                     IF VL_TRAN_ESCA != 0
                     THEN
                        PKG_FINANZAS.P_DESAPLICA_PAGOS (P_PIDM, VL_TRAN_ESCA);
                        DBMS_OUTPUT.PUT_LINE (
                           'REZA DINAMICOS 2 = ' || VL_TRAN_ESCA);

                        BEGIN
                           SELECT NVL (MAX (TBRACCD_TRAN_NUMBER), 0) + 1
                             INTO VL_SECUENCIA
                             FROM TBRACCD
                            WHERE TBRACCD_PIDM = P_PIDM;
                        END;

                        BEGIN
                           INSERT INTO TBRACCD (TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_DESC,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_SURROGATE_ID,
                                                TBRACCD_VERSION,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_PERIOD,
                                                TBRACCD_RECEIPT_NUMBER)
                              (SELECT TBRACCD_PIDM,
                                      VL_SECUENCIA,
                                      TBRACCD_TERM_CODE,
                                      SUBSTR (X.CODIGO, 1, 2) || 'ON',
                                      X.MONTO,
                                      X.MONTO,
                                      'CANCELACION DE PROMOCION',
                                      USER,
                                      SYSDATE,
                                      X.VIGENCIA,
                                      X.VIGENCIA,
                                      TBRACCD_SRCE_CODE,
                                      TBRACCD_ACCT_FEED_IND,
                                      SYSDATE,
                                      0,
                                      NULL,
                                      NULL,
                                      VL_TRAN_ESCA,
                                      TBRACCD_FEED_DATE,
                                      TBRACCD_STSP_KEY_SEQUENCE,
                                      'CAN_DIN',
                                      TBRACCD_PERIOD,
                                      TBRACCD_RECEIPT_NUMBER
                                 FROM TBRACCD A1
                                WHERE     A1.TBRACCD_PIDM = P_PIDM
                                      AND A1.TBRACCD_CREATE_SOURCE =
                                             'TZFEDCA(ACC)'
                                      AND SUBSTR (A1.TBRACCD_DETAIL_CODE,
                                                  3,
                                                  2) = 'M3'
                                      AND A1.TBRACCD_FEED_DOC_CODE IS NULL
                                      AND A1.TBRACCD_EFFECTIVE_DATE =
                                             X.VIGENCIA);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                    ' ERRROR AL INSERTAR TBRACCD REZA = '
                                 || SQLERRM;
                        END;

                        BEGIN
                           UPDATE TBRACCD
                              SET TBRACCD_TRAN_NUMBER_PAID = VL_SECUENCIA,
                                  TBRACCD_FEED_DOC_CODE = 'CANCEL'
                            WHERE     TBRACCD_PIDM = P_PIDM
                                  AND TBRACCD_TRAN_NUMBER = VL_TRAN_ESCA;
                        END;

                        IF X.SECU = 1
                        THEN
                           BEGIN
                              UPDATE TZFACCE
                                 SET TZFACCE_FLAG = 3
                               WHERE     TZFACCE_PIDM = P_PIDM
                                     AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                                     AND TZFACCE_FLAG = 1;
                           END;
                        ELSE
                           DBMS_OUTPUT.PUT_LINE (
                              'REZA DINAMICOS 3 = ' || VL_TRAN_ESCA);

                           BEGIN
                              DELETE TZFACCE
                               WHERE     TZFACCE_PIDM = P_PIDM
                                     AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                                     AND TZFACCE_FLAG = 1;
                           END;
                        END IF;
                     END IF;
                  END IF;
               END IF;
            END LOOP;
         END;
      END IF;

      IF VL_ERROR IS NULL
      THEN
         VL_ERROR := 'EXITO';
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      RETURN (VL_ERROR);
   END F_AJUSTE_DINA;

   PROCEDURE P_ACTUA_ESCA (P_PIDM NUMBER, P_TRAN NUMBER, P_MONTO NUMBER)
   IS
      VL_ERROR    VARCHAR2 (900);
      VL_APLICA   NUMBER := 0;
   BEGIN
      FOR X
         IN (SELECT *
               FROM TBRACCD
              WHERE     1 = 1
                    AND TBRACCD_PIDM = P_PIDM
                    AND TBRACCD_TRAN_NUMBER = P_TRAN)
      LOOP
         VL_APLICA := P_MONTO;

         BEGIN
            FOR TVRACCD
               IN (SELECT *
                     FROM TVRACCD
                    WHERE     TVRACCD_PIDM = X.TBRACCD_PIDM
                          AND TVRACCD_ACCD_TRAN_NUMBER =
                                 X.TBRACCD_TRAN_NUMBER)
            LOOP
               BEGIN
                  DELETE TVRAPPL
                   WHERE     TVRAPPL_PIDM = TVRACCD.TVRACCD_PIDM
                         AND (   TVRAPPL_PAY_TRAN_NUMBER =
                                    TVRACCD.TVRACCD_TRAN_NUMBER
                              OR TVRAPPL_CHG_TRAN_NUMBER =
                                    TVRACCD.TVRACCD_TRAN_NUMBER);
               END;
            END LOOP;
         END;

         BEGIN
            DELETE TBRAPPL
             WHERE     TBRAPPL_PIDM = X.TBRACCD_PIDM
                   AND (   TBRAPPL_PAY_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER
                        OR TBRAPPL_CHG_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER);
         END;

         BEGIN
            DELETE TVRTAXD
             WHERE     TVRTAXD_PIDM = X.TBRACCD_PIDM
                   AND TVRTAXD_ACCD_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER;
         END;

         BEGIN
            DELETE TBRACCD
             WHERE     1 = 1
                   AND TBRACCD_PIDM = X.TBRACCD_PIDM
                   AND TBRACCD_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER;
         END;

         BEGIN
            INSERT INTO TBRACCD (TBRACCD_ENTRY_DATE,
                                 TBRACCD_BILL_DATE,
                                 TBRACCD_DUE_DATE,
                                 TBRACCD_DESC,
                                 TBRACCD_TRAN_NUMBER_PAID,
                                 TBRACCD_CROSSREF_DETAIL_CODE,
                                 TBRACCD_SRCE_CODE,
                                 TBRACCD_ACCT_FEED_IND,
                                 TBRACCD_ACTIVITY_DATE,
                                 TBRACCD_SESSION_NUMBER,
                                 TBRACCD_CRN,
                                 TBRACCD_CROSSREF_SRCE_CODE,
                                 TBRACCD_LOC_MDT,
                                 TBRACCD_LOC_MDT_SEQ,
                                 TBRACCD_RATE,
                                 TBRACCD_UNITS,
                                 TBRACCD_DOCUMENT_NUMBER,
                                 TBRACCD_TRANS_DATE,
                                 TBRACCD_PAYMENT_ID,
                                 TBRACCD_INVOICE_NUMBER,
                                 TBRACCD_CURR_CODE,
                                 TBRACCD_FEED_DOC_CODE,
                                 TBRACCD_PIDM,
                                 TBRACCD_USER,
                                 TBRACCD_BALANCE,
                                 TBRACCD_RECEIPT_NUMBER,
                                 TBRACCD_TERM_CODE,
                                 TBRACCD_TRAN_NUMBER,
                                 TBRACCD_CROSSREF_NUMBER,
                                 TBRACCD_CSHR_END_DATE,
                                 TBRACCD_EFFECTIVE_DATE,
                                 TBRACCD_CROSSREF_PIDM,
                                 TBRACCD_DETAIL_CODE,
                                 TBRACCD_AMOUNT,
                                 TBRACCD_STATEMENT_DATE,
                                 TBRACCD_INV_NUMBER_PAID,
                                 TBRACCD_EXCHANGE_DIFF,
                                 TBRACCD_FOREIGN_AMOUNT,
                                 TBRACCD_LATE_DCAT_CODE,
                                 TBRACCD_FEED_DATE,
                                 TBRACCD_ATYP_CODE,
                                 TBRACCD_ATYP_SEQNO,
                                 TBRACCD_CARD_TYPE_VR,
                                 TBRACCD_CARD_EXP_DATE_VR,
                                 TBRACCD_CARD_AUTH_NUMBER_VR,
                                 TBRACCD_CROSSREF_DCAT_CODE,
                                 TBRACCD_ORIG_CHG_IND,
                                 TBRACCD_CCRD_CODE,
                                 TBRACCD_MERCHANT_ID,
                                 TBRACCD_TAX_REPT_YEAR,
                                 TBRACCD_TAX_REPT_BOX,
                                 TBRACCD_TAX_AMOUNT,
                                 TBRACCD_TAX_FUTURE_IND,
                                 TBRACCD_DATA_ORIGIN,
                                 TBRACCD_CREATE_SOURCE,
                                 TBRACCD_CPDT_IND,
                                 TBRACCD_AIDY_CODE,
                                 TBRACCD_STSP_KEY_SEQUENCE,
                                 TBRACCD_PERIOD,
                                 TBRACCD_SURROGATE_ID,
                                 TBRACCD_VERSION,
                                 TBRACCD_USER_ID,
                                 TBRACCD_VPDI_CODE)
                 VALUES (X.TBRACCD_ENTRY_DATE,
                         X.TBRACCD_BILL_DATE,
                         X.TBRACCD_DUE_DATE,
                         X.TBRACCD_DESC,
                         X.TBRACCD_TRAN_NUMBER_PAID,
                         X.TBRACCD_CROSSREF_DETAIL_CODE,
                         X.TBRACCD_SRCE_CODE,
                         X.TBRACCD_ACCT_FEED_IND,
                         X.TBRACCD_ACTIVITY_DATE,
                         X.TBRACCD_SESSION_NUMBER,
                         X.TBRACCD_CRN,
                         X.TBRACCD_CROSSREF_SRCE_CODE,
                         X.TBRACCD_LOC_MDT,
                         X.TBRACCD_LOC_MDT_SEQ,
                         X.TBRACCD_RATE,
                         X.TBRACCD_UNITS,
                         X.TBRACCD_DOCUMENT_NUMBER,
                         X.TBRACCD_TRANS_DATE,
                         X.TBRACCD_PAYMENT_ID,
                         X.TBRACCD_INVOICE_NUMBER,
                         X.TBRACCD_CURR_CODE,
                         X.TBRACCD_FEED_DOC_CODE,
                         X.TBRACCD_PIDM,
                         X.TBRACCD_USER,
                         VL_APLICA * -1,
                         X.TBRACCD_RECEIPT_NUMBER,
                         X.TBRACCD_TERM_CODE,
                         X.TBRACCD_TRAN_NUMBER,
                         X.TBRACCD_CROSSREF_NUMBER,
                         X.TBRACCD_CSHR_END_DATE,
                         X.TBRACCD_EFFECTIVE_DATE,
                         X.TBRACCD_CROSSREF_PIDM,
                         X.TBRACCD_DETAIL_CODE,
                         VL_APLICA,
                         X.TBRACCD_STATEMENT_DATE,
                         X.TBRACCD_INV_NUMBER_PAID,
                         X.TBRACCD_EXCHANGE_DIFF,
                         X.TBRACCD_FOREIGN_AMOUNT,
                         X.TBRACCD_LATE_DCAT_CODE,
                         X.TBRACCD_FEED_DATE,
                         X.TBRACCD_ATYP_CODE,
                         X.TBRACCD_ATYP_SEQNO,
                         X.TBRACCD_CARD_TYPE_VR,
                         X.TBRACCD_CARD_EXP_DATE_VR,
                         X.TBRACCD_CARD_AUTH_NUMBER_VR,
                         X.TBRACCD_CROSSREF_DCAT_CODE,
                         X.TBRACCD_ORIG_CHG_IND,
                         X.TBRACCD_CCRD_CODE,
                         X.TBRACCD_MERCHANT_ID,
                         X.TBRACCD_TAX_REPT_YEAR,
                         X.TBRACCD_TAX_REPT_BOX,
                         X.TBRACCD_TAX_AMOUNT,
                         X.TBRACCD_TAX_FUTURE_IND,
                         X.TBRACCD_DATA_ORIGIN,
                         X.TBRACCD_CREATE_SOURCE,
                         X.TBRACCD_CPDT_IND,
                         X.TBRACCD_AIDY_CODE,
                         X.TBRACCD_STSP_KEY_SEQUENCE,
                         X.TBRACCD_PERIOD,
                         X.TBRACCD_SURROGATE_ID,
                         X.TBRACCD_VERSION,
                         X.TBRACCD_USER_ID,
                         X.TBRACCD_VPDI_CODE);
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_ERROR := 'Error al insertar TBRACCD = ' || SQLERRM;
         END;
      END LOOP;

      IF VL_ERROR IS NULL
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;
   END P_ACTUA_ESCA;



   /*
   Función que muestra los accesorios de paquetes dinámicos.
   Autor FNAVARRO 27/06/2022
   */
   FUNCTION F_ACCESORIOS_DINAMICOS (v_pdim IN VARCHAR2)
      RETURN SYS_REFCURSOR
   IS
      acc_din         SYS_REFCURSOR;

      l_periodo       VARCHAR2 (10);
      l_fechaInicio   VARCHAR2 (15);
      l_clave         VARCHAR2 (10);
      l_descripcion   VARCHAR2 (500);
      l_monto         VARCHAR2 (15);
      l_cargos        VARCHAR2 (5);
   BEGIN
      -- Cursor para accesorios dinamicos ( Variable de entrada: v_pdim )
      OPEN acc_din FOR
           SELECT SUBSTR (a.TZTPADI_TERM_CODE,
                          LENGTH (a.TZTPADI_TERM_CODE) - 3,
                          4)
                     Periodo,
                  TO_CHAR (a.TZTPADI_EFFECTIVE_DATE, 'DD/MM/YYYY') FechaInicio,
                  a.TZTPADI_DETAIL_CODE Clave,
                  a.TZTPADI_DESC Descripcion,
                  a.TZTPADI_AMOUNT Monto,
                  NVL (a.TZTPADI_CHARGES, '0') Cargos
             FROM TZTPADI a
            WHERE 1 = 1 AND a.TZTPADI_PIDM = v_pdim -- AND
                                                    --a.TZTPADI_DETAIL_CODE LIKE '%M3'
                  AND a.TZTPADI_FLAG = 0
         ORDER BY a.TZTPADI_SEQNO DESC;

      RETURN acc_din;
   END F_ACCESORIOS_DINAMICOS;


   /*
   Función que muestra los accesorios de paquetes escalonados.
   Autor FNAVARRO 27/06/2022
   */
   FUNCTION F_ACCESORIOS_ESCALONADOS (v_pdim IN VARCHAR2)
      RETURN SYS_REFCURSOR
   IS
      acc_esc         SYS_REFCURSOR;

      l_periodo       VARCHAR2 (10);
      l_fechaInicio   VARCHAR2 (15);
      l_clave         VARCHAR2 (5);
      l_descripcion   VARCHAR2 (500);
      l_monto         VARCHAR2 (10);
      l_estatus       VARCHAR2 (10);
   BEGIN
      -- Cursor para accesorios dinamicos ( Variable de entrada: v_pdim )
      OPEN acc_esc FOR
           SELECT SUBSTR (a.TZFACCE_TERM_CODE,
                          LENGTH (a.TZFACCE_TERM_CODE) - 3,
                          4)
                     Periodo,
                  TO_CHAR (a.TZFACCE_EFFECTIVE_DATE, 'DD/MM/YYYY') FechaInicio,
                  a.TZFACCE_DETAIL_CODE Clave,
                  a.TZFACCE_DESC Descripcion,
                  a.TZFACCE_AMOUNT Monto,
                  DECODE (a.TZFACCE_FLAG,  0, 'No aplicado',  1, 'Aplicado')
                     Estatus
             FROM TZFACCE a
            WHERE     1 = 1
                  AND a.TZFACCE_PIDM = v_pdim
                  AND a.TZFACCE_DETAIL_CODE LIKE '%M3'
         ORDER BY a.TZFACCE_EFFECTIVE_DATE DESC;

      RETURN acc_esc;
   END F_ACCESORIOS_ESCALONADOS;

   FUNCTION F_CURSOR_ESCA_PADI (P_PIDM NUMBER, P_ERROR OUT VARCHAR2)
      RETURN PKG_FINANZAS_DINAMICOS.CURSOR_DATOS_CURSOR
   AS
      DATOS_CURSOR   PKG_FINANZAS_DINAMICOS.CURSOR_DATOS_CURSOR;

      /*FNCIONN TIPO CURSOR RETORNA PROMO ESCA Y ACCESORIOS DINA
      AUTOR GGC*/

      VL_ERROR       VARCHAR2 (900) := 'EXITO';
   BEGIN
      OPEN DATOS_CURSOR FOR
         SELECT DISTINCT
                TZTPADI_PIDM PIDM,
                TZTPADI_TERM_CODE PERIODO,
                TZTPADI_DESC DES,
                TZTPADI_AMOUNT MONTO,
                TZTPADI_CHARGES CARGOS,
                TZTPADI_EFFECTIVE_DATE FECHA,
                SORLCUR_PROGRAM PROGRAMA,
                CASE
                   WHEN TZTPADI_AMOUNT > 0 AND TZTPADI_CHARGES IS NULL
                   THEN
                      'RECURRENTE'
                   WHEN TZTPADI_AMOUNT = 0 AND TZTPADI_CHARGES IS NULL
                   THEN
                      'COSTO 0'
                   ELSE
                      'VIGENCIA'
                END
                   TIPO,
                NVL (TO_NUMBER (TZTPADI_IND_CANCE), 0) FLAG,
                CASE
                   WHEN TZTPADI_FLAG > 0 AND TZTPADI_IND_CANCE IS NULL
                   THEN
                      'INACTIVO'
                   WHEN TZTPADI_FLAG > 0 AND TZTPADI_IND_CANCE IS NOT NULL
                   THEN
                      'CANCELADO'
                   ELSE
                      'ACTIVO'
                END
                   STATUS
           FROM TZTPADI
                INNER JOIN SORLCUR
                   ON (    TZTPADI_PIDM = SORLCUR_PIDM
                       AND SORLCUR_APPL_KEY_SEQNO = TZTPADI_REQUEST)
          WHERE     TZTPADI_PIDM = P_PIDM
                AND SORLCUR_LMOD_CODE = 'LEARNER'
                AND SORLCUR_ROLL_IND = 'Y'
                AND SORLCUR_CACT_CODE = 'ACTIVE'
         UNION
         SELECT DISTINCT
                TZFACCE_PIDM,
                TZFACCE_TERM_CODE,
                TZFACCE_DESC,
                TZFACCE_AMOUNT,
                NULL,
                TZFACCE_EFFECTIVE_DATE,
                SORLCUR_PROGRAM,
                'PROMOCION',
                NVL (TO_NUMBER (TZFACCE_FLAG), 0),
                CASE WHEN TZFACCE_FLAG > 0 THEN 'INACTIVO' ELSE 'ACTIVO' END
                   STATUS
           FROM TZFACCE
                INNER JOIN SORLCUR
                   ON (    TZFACCE_PIDM = SORLCUR_PIDM
                       AND SORLCUR_APPL_KEY_SEQNO = TZFACCE_STUDY)
          WHERE     TZFACCE_PIDM = P_PIDM
                AND SORLCUR_LMOD_CODE = 'LEARNER'
                AND SORLCUR_ROLL_IND = 'Y'
                AND SORLCUR_CACT_CODE = 'ACTIVE'
                AND SUBSTR (TZFACCE_DETAIL_CODE, 3, 2) = 'M3'
         ORDER BY 2, 6 DESC;

      RETURN (DATOS_CURSOR);
      VL_ERROR := P_ERROR;
   EXCEPTION
      WHEN OTHERS
      THEN
         VL_ERROR := 'VALIDAR';
         VL_ERROR := P_ERROR;
   END;


   /*
   Función que inserta accesorios en TZTPADI.
   Autor FNAVARRO 08/07/2022
   */
   FUNCTION F_INSERTA_ACCESORIOS (P_PIDM           NUMBER,
                                  P_PERIODO        VARCHAR2,
                                  P_MONTO          NUMBER,
                                  P_DETAIL_CODE    VARCHAR2,
                                  P_DETAIL_DESC    VARCHAR2,
                                  P_NUM_CARGOS     NUMBER,
                                  P_AGREGA_COL     VARCHAR2,
                                  P_ELIMINA        NUMBER,
                                  P_SOLICITUD      NUMBER,
                                  P_USUARIO        VARCHAR2,
                                  P_CAMPUS         VARCHAR2 DEFAULT NULL,      
                                  P_NIVEL          VARCHAR2 DEFAULT NULL,       
                                  P_PROGRAMA       VARCHAR2 DEFAULT NULL,      
                                  P_START_DATE     DATE     DEFAULT NULL)          
      RETURN VARCHAR2
   IS
      VL_ERROR     VARCHAR2 (900) := 'EXITO';
      VL_SECU      NUMBER;
      VL_ENTRA     NUMBER;
      VL_CHARGES   NUMBER;
   BEGIN
      /*
      Marca de Cambio: Ajuste a la Funcion F_INSERTA_ACCESORIOS
      Autor: FNAVARRO
      Prop sito: Actualiza accesorio en caso de ser retirado del paquete.
      Ver: 1.1 => FND@Update 21/07/2022  => Conversion de variable P_NUM_CARGOS de 0 a NULL.
      Ver: 2.0 => FND@Update 05/09/2022  => Validacion de accesorios existentes a ser retirados del paquete.
      */

      IF VL_ERROR = 'EXITO'
      THEN
         BEGIN
            FOR C
               IN (SELECT DISTINCT
                          SORLCUR_PIDM PIDM,
                          EXTRACT (MONTH FROM SORLCUR_START_DATE) MES,
                          EXTRACT (YEAR FROM SORLCUR_START_DATE) ANO,
                          (DECODE (SUBSTR (SARADAP_RATE_CODE, 4, 1),
                                   'A', '15',
                                   'B', '30',
                                   'C', '10'))
                             VIG,
                          SORLCUR_PROGRAM PROGRAMA,
                            (SORLCUR_START_DATE + 12)
                          + (DECODE (SUBSTR (SARADAP_RATE_CODE, 4, 1),
                                     'A', '15',
                                     'B', '30',
                                     'C', '10'))
                          - TO_CHAR (SORLCUR_START_DATE + 12, 'DD')
                             FECHA_EDO,
                          SORLCUR_KEY_SEQNO STUDY,
                          SORLCUR_CAMP_CODE CAMPUS,
                          SORLCUR_LEVL_CODE NIVEL,
                          SARADAP_APPL_NO SOLI
                     FROM SORLCUR A, SARADAP
                    WHERE     A.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                          AND A.SORLCUR_ROLL_IND = 'N'
                          AND SARADAP_PIDM = A.SORLCUR_PIDM
                          AND SARADAP_APPL_NO = A.SORLCUR_KEY_SEQNO
                          AND SARADAP_APPL_NO = P_SOLICITUD
                          AND SARADAP_PIDM = P_PIDM)
            LOOP
               VL_ERROR := 'EXITO';

               BEGIN
                  SELECT COUNT (*)
                    INTO VL_ENTRA
                    FROM TZTPADI
                   WHERE     TZTPADI_PIDM = P_PIDM
                         AND TZTPADI_DETAIL_CODE = P_DETAIL_CODE
                         AND TZTPADI_REQUEST = P_SOLICITUD
                         AND TZTPADI_FLAG = 0;
               END;


               IF VL_ENTRA = 0
               THEN
                  BEGIN
                     SELECT NVL (MAX (TZTPADI_SEQNO) + 1, 1)
                       INTO VL_SECU
                       FROM TZTPADI
                      WHERE TZTPADI_PIDM = P_PIDM;
                  END;



                  IF P_NUM_CARGOS = 0
                  THEN
                     VL_CHARGES := NULL;
                  ELSE
                     VL_CHARGES := P_NUM_CARGOS;
                  END IF;

                  BEGIN
                     INSERT INTO TZTPADI (TZTPADI_PIDM,
                                          TZTPADI_SEQNO,
                                          TZTPADI_TERM_CODE,
                                          TZTPADI_DETAIL_CODE,
                                          TZTPADI_DESC,
                                          TZTPADI_AMOUNT,
                                          TZTPADI_CHARGES,
                                          TZTPADI_EFFECTIVE_DATE,
                                          TZTPADI_ADD_COL,
                                          TZTPADI_FLAG,
                                          TZTPADI_DELETE,
                                          TZTPADI_REQUEST,
                                          TZTPADI_USER,
                                          TZTPADI_ACTIVITY_DATE,
                                          TZTPADI_CAMPUS,      
                                          TZTPADI_NIVEL,       
                                          TZTPADI_PROGRAMA,      
                                          TZTPADI_START_DATE )
                          VALUES (P_PIDM,
                                  VL_SECU,
                                  P_PERIODO,
                                  P_DETAIL_CODE,
                                  P_DETAIL_DESC,
                                  P_MONTO,
                                  VL_CHARGES,
                                  C.FECHA_EDO,
                                  P_AGREGA_COL,
                                  0,
                                  P_ELIMINA,
                                  P_SOLICITUD,
                                  P_USUARIO,
                                  SYSDATE,
                                  P_CAMPUS,      
                                  P_NIVEL,       
                                  P_PROGRAMA,      
                                  P_START_DATE);          

                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        VL_ERROR :=
                              'ERROR AL INSERTAR CODIGO NUEVO EN TZTPADI = '
                           || SQLERRM;
                  END;
               END IF;
            END LOOP;
         END;
      END IF;

      IF VL_ERROR = 'EXITO'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      RETURN (VL_ERROR);
   END F_INSERTA_ACCESORIOS;
   --
   --
   FUNCTION F_BAJA_ACCESORIOS (P_PIDM           NUMBER,
                               P_DETAIL_CODE    VARCHAR2,
                               P_ELIMINA        NUMBER,
                               P_USUARIO        VARCHAR2)
      RETURN VARCHAR2
   IS
      /******************************************************************************
         NAME:      F_BAJA_ACCEOSRIOS
         PURPOSE:   Dar de baja los accesorios que comprenden del paquete.

         REVISIONS:
         Ver        Date        Author           Description
         ---------  ----------  ---------------  ------------------------------------
         1.0        09/09/2022  FND@Create       1. Creación de la función.
         1.1        20/10/2022  FND@Update       1. Actualización de la función.
         1.2        20/01/2023  FND@Update       1. Actualización de la función.

         NOTES:

      ******************************************************************************
         MARCAS DE CAMBIO:
         No. 1
         Clave de cambio: 001-20102022-FND
         Autor: Flavio Navarro Dominguez
         Descripción: Ajuste a la función: se registrará en TBRACCD las notas de
                      cancelación de accesorios en los estados de cuenta.
      ******************************************************************************
         No. 2
         Clave de cambio: 002-20012023-FND
         Autor: Flavio Navarro Dominguez
         Descripción: Discriminar los codigos de detalles de reclasificación de
                      pago(6M) en el Edo. de Cta.(TBRACCD).
      ******************************************************************************

      ******************************************************************************/

      VL_ERROR           VARCHAR2 (900) := 'EXITO';
      VL_EXISTE          NUMBER := NULL;
      VL_ACTUALIZADOS    NUMBER;
      VL_SECUENCIA       NUMBER := 0;  /* Clave de cambio: 001-20102022-FND */
      VL_CODIGO          VARCHAR2 (4) := NULL; /* Clave de cambio: 001-20102022-FND */
      VL_DESC            VARCHAR2 (60) := NULL; /* Clave de cambio: 001-20102022-FND */
      VL_MONTO           NUMBER := 0;  /* Clave de cambio: 001-20102022-FND */
      VL_NO_ORDEN        NUMBER := 0;  /* Clave de cambio: 001-20102022-FND */
      VL_STUDY_PATH      NUMBER := 0;  /* Clave de cambio: 001-20102022-FND */
      VL_PARTE_PERIODO   VARCHAR2 (4) := NULL; /* Clave de cambio: 001-20102022-FND */
      VL_PARAM           VARCHAR2 (5) := NULL; /* Clave de cambio: 001-20102022-FND */
      VL_DESC_PARAM      VARCHAR2 (200) := NULL; /* Clave de cambio: 001-20102022-FND */
      VL_VALOR_PARAM     VARCHAR2 (10) := NULL; /* Clave de cambio: 001-20102022-FND */
   BEGIN
      BEGIN
         SELECT COUNT (1)
           INTO VL_EXISTE
           FROM TZTPADI
          WHERE     1 = 1
                AND TZTPADI_PIDM = P_PIDM
                AND TZTPADI_DETAIL_CODE = P_DETAIL_CODE;

         IF VL_EXISTE = 1
         THEN
            UPDATE TZTPADI
               SET TZTPADI_FLAG = 1,
                   TZTPADI_USER = P_USUARIO,
                   TZTPADI_ACTIVITY_DATE = SYSDATE
             WHERE     1 = 1
                   AND TZTPADI_PIDM = P_PIDM
                   AND TZTPADI_DETAIL_CODE = P_DETAIL_CODE;

            VL_ACTUALIZADOS := SQL%ROWCOUNT;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            VL_ERROR :=
                  'Error al dar de baja el(los) accesorio(s) en TZTPADI. '
               || CHR (10)
               || 'SQLCODE: '
               || SQLCODE
               || CHR (10)
               || SQLERRM;
            ROLLBACK;
      END;

      /* Clave de cambio: 001-20102022-FND */

      -- Traer los accesorios cancelados.
      FOR ACCE_CANC
         IN (SELECT *
               FROM TZTPADI
              WHERE 1 = 1 AND TZTPADI_PIDM = P_PIDM AND TZTPADI_FLAG = 1 --> Si Flag es 1, el accesorio está apagado/cancelado.
                                                                        )
      LOOP
         -- Secuencia: El ultimo registro de la secuencia del PIDM
         BEGIN
            SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
              INTO VL_SECUENCIA
              FROM TBRACCD
             WHERE TBRACCD_PIDM = ACCE_CANC.TZTPADI_PIDM;
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_SECUENCIA := 0;
         END;

         -- Valor del parámetro CAN_DINAACC para accesorios cancelados registrados en ZSTPARA.
         --                           BEGIN
         --                                SELECT ZSTPARA_PARAM_ID
         --                                      ,ZSTPARA_PARAM_DESC
         --                                      ,ZSTPARA_PARAM_VALOR
         --                                  INTO VL_PARAM
         --                                      ,VL_DESC_PARAM
         --                                      ,VL_VALOR_PARAM
         --                                  FROM ZSTPARA
         --                                 WHERE 1 = 1
         --                                   AND ZSTPARA_MAPA_ID = 'CAN_DINAACC'
         --                                   AND ZSTPARA_PARAM_VALOR = SUBSTR(ACCE_CANC.TZTPADI_DETAIL_CODE,3,4);
         --
         --                           EXCEPTION
         --                            WHEN NO_DATA_FOUND THEN
         ----                                    VL_PARAM       := NULL;
         ----                                    VL_DESC_PARAM  := NULL;
         ----                                    VL_VALOR_PARAM := NULL;
         --                                    VL_ERROR       := 'No existe/encontró el código de detalle '||ACCE_CANC.TZTPADI_DETAIL_CODE||' para la cancelación de accesorio(s) dentro del parámetro CAN_DINACC, se requiere darlo de alta en el agrupador, favor de reportarlo. '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM;
         --                           END;
         --
         --
         --                           IF (VL_PARAM = NULL OR VL_DESC_PARAM = NULL OR VL_VALOR_PARAM = NULL) THEN
         --                                    VL_ERROR := 'No se registrará la nota de cancelación en el Edo. de Cta.';
         --
         --                           ELSE

         -- Código de detalle para accesorios cancelados por el campus del alumno registrado.
         BEGIN
            SELECT TBBDETC_AMOUNT, TBBDETC_DETAIL_CODE, TBBDETC_DESC
              INTO VL_MONTO, VL_CODIGO, VL_DESC
              FROM TBBDETC
             WHERE     1 = 1
                   AND TBBDETC_DETAIL_CODE =
                          SUBSTR (ACCE_CANC.TZTPADI_TERM_CODE, 1, 2) || 'B4';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               VL_ERROR :=
                     'No existe/encontró el codigo de detalle para cancelación de accesorio(s) dentro de la tabla TBBDETC, se requiere darlo de alta, favor de revisarlo. '
                  || CHR (10)
                  || 'SQLCODE: '
                  || SQLCODE
                  || CHR (10)
                  || SQLERRM;
         END;

         -- Obtener el máximo de No. de orden, Study Path y Parte Periodo.
         BEGIN
            SELECT DISTINCT
                   (T1.TBRACCD_RECEIPT_NUMBER),
                   T1.TBRACCD_STSP_KEY_SEQUENCE,
                   T1.TBRACCD_PERIOD
              INTO VL_NO_ORDEN, VL_STUDY_PATH, VL_PARTE_PERIODO
              FROM TBRACCD T1
             WHERE     1 = 1
                   AND T1.TBRACCD_PIDM = ACCE_CANC.TZTPADI_PIDM
                   AND T1.TBRACCD_PERIOD IS NOT NULL
                   /*****************************************
                   *    MARCA DE CAMBIO: 002-20012023-FND.  *
                   *****************************************/
                   AND SUBSTR (T1.TBRACCD_DETAIL_CODE, 3, 2) NOT IN ('6M')
                   /***********************************************
                   *    FIN MARCA DE CAMBIO: 002-20012023-FND.    *
                   ***********************************************/
                   AND T1.TBRACCD_RECEIPT_NUMBER =
                          (SELECT MAX (TBRACCD_RECEIPT_NUMBER)
                             FROM TBRACCD
                            WHERE     1 = 1
                                  AND TBRACCD_PIDM = ACCE_CANC.TZTPADI_PIDM);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               VL_ERROR :=
                     'No existe/encontró el No. de orden o Study Path o Parte Periodo del alumno, favor de revisarlo. '
                  || CHR (10)
                  || 'SQLCODE: '
                  || SQLCODE
                  || CHR (10)
                  || SQLERRM;
         END;

         -- Inserta las notas de cancelación de accesorios en el edo. de cta.
         BEGIN
            INSERT INTO TBRACCD (TBRACCD_PIDM,
                                 TBRACCD_TRAN_NUMBER,
                                 TBRACCD_TERM_CODE,
                                 TBRACCD_DETAIL_CODE,
                                 TBRACCD_USER,
                                 TBRACCD_ENTRY_DATE,
                                 TBRACCD_AMOUNT,
                                 TBRACCD_BALANCE,
                                 TBRACCD_EFFECTIVE_DATE,
                                 TBRACCD_BILL_DATE,
                                 TBRACCD_DUE_DATE,
                                 TBRACCD_DESC,
                                 TBRACCD_RECEIPT_NUMBER,
                                 TBRACCD_TRAN_NUMBER_PAID,
                                 TBRACCD_CROSSREF_PIDM,
                                 TBRACCD_CROSSREF_NUMBER,
                                 TBRACCD_CROSSREF_DETAIL_CODE,
                                 TBRACCD_SRCE_CODE,
                                 TBRACCD_ACCT_FEED_IND,
                                 TBRACCD_ACTIVITY_DATE,
                                 TBRACCD_SESSION_NUMBER,
                                 TBRACCD_CSHR_END_DATE,
                                 TBRACCD_CRN,
                                 TBRACCD_CROSSREF_SRCE_CODE,
                                 TBRACCD_LOC_MDT,
                                 TBRACCD_LOC_MDT_SEQ,
                                 TBRACCD_RATE,
                                 TBRACCD_UNITS,
                                 TBRACCD_DOCUMENT_NUMBER,
                                 TBRACCD_TRANS_DATE,
                                 TBRACCD_PAYMENT_ID,
                                 TBRACCD_INVOICE_NUMBER,
                                 TBRACCD_STATEMENT_DATE,
                                 TBRACCD_INV_NUMBER_PAID,
                                 TBRACCD_CURR_CODE,
                                 TBRACCD_EXCHANGE_DIFF,
                                 TBRACCD_FOREIGN_AMOUNT,
                                 TBRACCD_LATE_DCAT_CODE,
                                 TBRACCD_FEED_DATE,
                                 TBRACCD_FEED_DOC_CODE,
                                 TBRACCD_ATYP_CODE,
                                 TBRACCD_ATYP_SEQNO,
                                 TBRACCD_CARD_TYPE_VR,
                                 TBRACCD_CARD_EXP_DATE_VR,
                                 TBRACCD_CARD_AUTH_NUMBER_VR,
                                 TBRACCD_CROSSREF_DCAT_CODE,
                                 TBRACCD_ORIG_CHG_IND,
                                 TBRACCD_CCRD_CODE,
                                 TBRACCD_MERCHANT_ID,
                                 TBRACCD_TAX_REPT_YEAR,
                                 TBRACCD_TAX_REPT_BOX,
                                 TBRACCD_TAX_AMOUNT,
                                 TBRACCD_TAX_FUTURE_IND,
                                 TBRACCD_DATA_ORIGIN,
                                 TBRACCD_CREATE_SOURCE,
                                 TBRACCD_CPDT_IND,
                                 TBRACCD_AIDY_CODE,
                                 TBRACCD_STSP_KEY_SEQUENCE,
                                 TBRACCD_PERIOD,
                                 TBRACCD_SURROGATE_ID,
                                 TBRACCD_VERSION,
                                 TBRACCD_USER_ID,
                                 TBRACCD_VPDI_CODE)
                 VALUES (ACCE_CANC.TZTPADI_PIDM,
                         VL_SECUENCIA,
                         ACCE_CANC.TZTPADI_TERM_CODE,
                         VL_CODIGO, --SUBSTR(ACCE_CANC.TZTPADI_TERM_CODE,1,2)||VL_VALOR_PARAM,
                         USER,
                         SYSDATE,
                         NVL (VL_MONTO, 0),
                         NVL (VL_MONTO, 0),
                         ACCE_CANC.TZTPADI_EFFECTIVE_DATE,
                         NULL,
                         NULL,
                         VL_DESC,                             --VL_DESC_PARAM,
                         VL_NO_ORDEN,
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
                         ACCE_CANC.TZTPADI_EFFECTIVE_DATE,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         'MXN',
                         NULL,
                         NULL,
                         NULL,
                         ACCE_CANC.TZTPADI_EFFECTIVE_DATE,
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
                         'TZFEDCA(PARC)',
                         'TZFEDCA(PARC)',
                         NULL,
                         NULL,
                         VL_STUDY_PATH,
                         VL_PARTE_PERIODO,
                         NULL,
                         NULL,
                         USER,
                         NULL);
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_ERROR :=
                     'Error al insertar accesorio(s) cancelado(s) en TBRACCD, favor de revisarlo '
                  || CHR (10)
                  || 'SQLCODE: '
                  || SQLCODE
                  || CHR (10)
                  || SQLERRM;
         END;
      --  END IF;
      END LOOP;

      /* Fin Clave de cambio: 001-20102022-FND */

      IF VL_ERROR = 'EXITO'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      RETURN (VL_ERROR);
   END F_BAJA_ACCESORIOS;

   --
   --
   FUNCTION F_VALIDA_FECHA_CAMPAQ (P_PIDM IN NUMBER, P_PROGRAMA IN VARCHAR2)
      RETURN VARCHAR2
   IS
      /******************************************************************************
         NAME:      F_VALIDA_FECHA_CAMPAQ
         PURPOSE:   Comparar fechas para cambio de paquete:
                    => Si fecha de inicio del alumno más el valor del parámetro
                    PQ_RANGOTIEMPO es igual a fecha actual, SIU deberá permitir hacer
                    el cambio de paquete.
                    => Si fecha actual(SYSDATE) es mayor a la fecha de inicio más el
                    valor del parámetro PQ_RANGOTIEMPO, SIU no debera permitir
                    (bloquear el cambio).

         REVISIONS:
         Ver        Date        Author           Description
         ---------  ----------  ---------------  ------------------------------------
         1.0        19/10/2022  FND@Create       1. Creación de la función.
         1.1        20/01/2023  FND@Update       1. Actualización de la función

         NOTES:     La función comienza a trabajar a partir de SIU

      ******************************************************************************
         MARCAS DE CAMBIO:
         No. 1
         Clave de cambio: 001-20012023-FND
         Autor: Flavio Navarro Dominguez
         Descripción: Validación de matriculado si es nuevo ingreso o no, en caso de
                      que no sea de nuevo ingreso, no permitira el cambio de paquete.
      ******************************************************************************
         No. 2
         Clave de cambio: 002-DDMMYYYY-(Autor-inciales)
         Autor: (Autor-Iniciales)@(Create, Update, Delete)
         Descripción: (Describir el ajuste/modificación al código)
      ******************************************************************************

      ******************************************************************************/

      VL_FECHA_VALIDACION   DATE;
      VL_PARAM              VARCHAR2 (10) := NULL;
      VL_ERROR              VARCHAR2 (900) := 'EXITO';
      /*****************************************
      *    MARCA DE CAMBIO: 001-20012023-FND.  *
      *****************************************/
      VL_VALIDA_STDN        NUMBER (2) := NULL;
   /***********************************************
   *    FIN MARCA DE CAMBIO: 001-20012023-FND.    *
   ***********************************************/

   BEGIN
      /*****************************************
      *    MARCA DE CAMBIO: 001-20012023-FND.  *
      *****************************************/
      -- Existencia del matriculado si es nuevo ingreso.
      BEGIN
         SELECT COUNT (STDN.SGBSTDN_STYP_CODE)
           INTO VL_VALIDA_STDN
           FROM SGBSTDN STDN
          WHERE     1 = 1
                AND STDN.SGBSTDN_STST_CODE = 'MA'
                AND (   STDN.SGBSTDN_STYP_CODE = 'N'
                     OR STDN.SGBSTDN_STYP_CODE = 'F')
                AND STDN.SGBSTDN_PROGRAM_1 = P_PROGRAMA
                AND STDN.SGBSTDN_PIDM = P_PIDM;
      EXCEPTION
         WHEN OTHERS
         THEN
            VL_VALIDA_STDN := 0;
      END;

      -- Si existe matriculado como nuevo ingreso, entonces...
      IF VL_VALIDA_STDN > 0
      THEN
         /***********************************************
         *    FIN MARCA DE CAMBIO: 001-20012023-FND.    *
         ***********************************************/

         -- Cursor: Extrae fecha de inicio del programa del alumno de acuerdo a su PIDM y Programa inscrito.
         FOR ALUMNO_PROGRAMA
            IN (SELECT FECHA_INICIO
                  FROM TZTPROG
                 WHERE 1 = 1 AND PIDM = P_PIDM AND PROGRAMA = P_PROGRAMA)
         LOOP
            -- Validación de fechas: Fecha de inicio + los días del valor del parámetro PQ_RANGOTIEMPO Vs. Fecha actual

            --Extrae el valor del parámetro para delimitar el rango de tiempo.
            BEGIN
               SELECT ZSTPARA_PARAM_VALOR
                 INTO VL_PARAM
                 FROM ZSTPARA
                WHERE 1 = 1 AND ZSTPARA_MAPA_ID = 'PQ_RANGOTIEMPO';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  VL_ERROR :=
                        'No existe valor del parámetro para PQ_RANGOTIEMPO'
                     || CHR (10)
                     || SQLERRM;
            END;

            -- Suma los días a partir de la fecha de inicio del programa del alumno con el valor del parámetro PQ_RANGOTIEMPO                               .
            VL_FECHA_VALIDACION :=
               ALUMNO_PROGRAMA.FECHA_INICIO + TO_NUMBER (VL_PARAM);

            -- Si el resultado de la fecha de validación es menor o igual a la fecha actual, SIU permitirá el cambio de paquete.
            IF VL_FECHA_VALIDACION >= TRUNC (SYSDATE)
            THEN
               VL_ERROR := 'EXITO';
            -- Sino, SIU deberá bloquear el cambio de paquete.
            ELSE
               VL_ERROR :=
                     'No se puede realizar cambio de paquete pasado de '
                  || VL_PARAM
                  || ' días a partir de la fecha de inicio del programa: '
                  || ALUMNO_PROGRAMA.FECHA_INICIO
                  || '.'
                  || CHR (10)
                  || 'Fecha límite de cambio de paquete: '
                  || TO_CHAR (VL_FECHA_VALIDACION, 'DD/MM/YYYY')
                  || '.';
            --'No se puede realizar cambio de paquete... '||CHR(10)||'Está fuera del rango de tiempo de '||VL_ABCC||' días, a partir de la fecha del '||TO_CHAR(P_FECHA_OLD,'DD/MM/YYYY')||CHR(10)||'Fecha limite de cambio: '||TO_CHAR((P_FECHA_OLD+VL_ABCC),'DD/MM/YYYY')
            END IF;
         END LOOP;
      /*****************************************
      *    MARCA DE CAMBIO: 001-20012023-FND.  *
      *****************************************/

      -- Si no...
      ELSE
         VL_ERROR :=
               'No se puede realizar cambio de paquete, el matriculado no es de nuevo ingreso... Favor de revisar... '
            || CHR (10);
      END IF;

      RETURN (VL_ERROR);
   /***********************************************
   *    FIN MARCA DE CAMBIO: 001-20012023-FND.    *
   ***********************************************/

   END F_VALIDA_FECHA_CAMPAQ;
   
---AGOG INI 06082024 
  FUNCTION F_CURSOR_FIJA (P_PIDM NUMBER, P_PERFIL VARCHAR2)
      RETURN PKG_FINANZAS_DINAMICOS.FIJOS
   IS
      CURSOR_FIJOS   PKG_FINANZAS_DINAMICOS.FIJOS;
      VL_FECHA           DATE;
      VL_FECHA_APLI      DATE;
      VL_SALDO           NUMBER;
      VL_SALDO_PARC      NUMBER;

   BEGIN
      BEGIN
         SELECT DISTINCT (TZFACCE_EFFECTIVE_DATE)
           INTO VL_FECHA
           FROM TZFACCE
          WHERE TZFACCE_PIDM = P_PIDM ;
      EXCEPTION
         WHEN OTHERS
         THEN
            VL_FECHA := SYSDATE;
      END;

      IF VL_FECHA >= TRUNC (SYSDATE)
      THEN
         VL_FECHA_APLI := VL_FECHA;
      ELSE
         VL_FECHA_APLI := TRUNC (SYSDATE);
      END IF;

      BEGIN
         OPEN CURSOR_FIJOS FOR
           SELECT DISTINCT
                   TZFACCE_DETAIL_CODE CODIGO,
                   TZFACCE_DESC DESCRIPCION,
                    TZFACCE_AMOUNT  MONTO,
                    null  OBSERVACION,
                   TZFACCE_EFFECTIVE_DATE   FECHA,
                   SORLCUR_KEY_SEQNO STUDY
              FROM TZFACCE A1, SORLCUR A
             WHERE     A1.TZFACCE_PIDM = P_PIDM
                 and a1.TZFACCE_FLAG = 0
                 and a1.TZFACCE_AMOUNT > 0
                   AND A.SORLCUR_PIDM = A1.TZFACCE_PIDM
                   AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                   AND A.SORLCUR_ROLL_IND = 'Y'
                   AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                   AND A.SORLCUR_SEQNO =
                          (SELECT MAX (A1.SORLCUR_SEQNO)
                             FROM SORLCUR A1
                            WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                  AND A1.SORLCUR_ROLL_IND =
                                         A.SORLCUR_ROLL_IND
                                  AND A1.SORLCUR_CACT_CODE =
                                         A.SORLCUR_CACT_CODE
                                  AND A1.SORLCUR_LMOD_CODE =
                                         A.SORLCUR_LMOD_CODE)
                UNION --GOG
           SELECT DISTINCT
                   TZFACCE_DETAIL_CODE CODIGO,
                   TZFACCE_DESC DESCRIPCION,
                   TZFACCE_AMOUNT  MONTO,
                   null  OBSERVACION,
                   TZFACCE_EFFECTIVE_DATE   FECHA,
                   SORLCUR_KEY_SEQNO STUDY
              FROM TZFACCE A1, SORLCUR A
             WHERE     A1.TZFACCE_PIDM = P_PIDM
                 and a1.TZFACCE_FLAG = 9
                 and exists (select 1 from goradid b where a1.TZFACCE_PIDM = b.GORADID_PIDM and b.GORADID_ADID_CODE in ('MDSB','MDSP'))
                 and a1.TZFACCE_AMOUNT > 0
                   AND A.SORLCUR_PIDM = A1.TZFACCE_PIDM
                   AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                   AND A.SORLCUR_ROLL_IND = 'Y'
                   AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                   AND A.SORLCUR_SEQNO =
                          (SELECT MAX (A1.SORLCUR_SEQNO)
                             FROM SORLCUR A1
                            WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                  AND A1.SORLCUR_ROLL_IND =
                                         A.SORLCUR_ROLL_IND
                                  AND A1.SORLCUR_CACT_CODE =
                                         A.SORLCUR_CACT_CODE
                                  AND A1.SORLCUR_LMOD_CODE =
                                         A.SORLCUR_LMOD_CODE);                

         RETURN (CURSOR_FIJOS);
      END;
   END F_CURSOR_FIJA;
   
   
   FUNCTION F_FIJA_CART (P_PIDM NUMBER)
      RETURN PKG_FINANZAS_DINAMICOS.CART_FIJA
   IS
      CUR_TRAN_CART_F   PKG_FINANZAS_DINAMICOS.CART_FIJA;
   BEGIN
      BEGIN
         OPEN CUR_TRAN_CART_F FOR
              SELECT TBRACCD_DESC DESCRIPCION,
                       (  TBRACCD_AMOUNT
                        - NVL (
                             (SELECT SUM (TBRACCD_AMOUNT)
                                FROM TBRACCD
                               WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                     AND ( TBRACCD_CREATE_SOURCE =
                                                    'TZFEDCA(ACC)'
                                             AND SUBSTR (TBRACCD_DETAIL_CODE,
                                                         3,
                                                         2) = 'M3')
                                     AND TBRACCD_TRAN_NUMBER_PAID =
                                            A.TBRACCD_TRAN_NUMBER),
                             0))
                     + NVL (
                          (SELECT SUM (TBRACCD_AMOUNT)
                             FROM TBRACCD A1
                            WHERE     A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                                  AND A1.TBRACCD_CREATE_SOURCE =
                                         'TZFEDCA (ACC)'
                                  AND A1.TBRACCD_FEED_DOC_CODE IS NULL
                                  AND A1.TBRACCD_TRAN_NUMBER =
                                         (SELECT MAX (TBRACCD_TRAN_NUMBER)
                                            FROM TBRACCD
                                           WHERE     TBRACCD_PIDM =
                                                        A1.TBRACCD_PIDM
                                                 AND TBRACCD_CREATE_SOURCE =
                                                        'TZFEDCA (ACC)'
                                                 AND TBRACCD_DETAIL_CODE =
                                                        A1.TBRACCD_DETAIL_CODE)
                                  AND SUBSTR (A1.TBRACCD_DETAIL_CODE, 3, 2) IN (SELECT ZSTPARA_PARAM_ID
                                                                                  FROM ZSTPARA
                                                                                 WHERE ZSTPARA_MAPA_ID =
                                                                                          'ACC_ALIANZA')),
                          0)
                        MONTO,
                     TBRACCD_EFFECTIVE_DATE FECHA_VIGENCIA,
                     NVL (
                        (SELECT TBRACCD_DESC
                           FROM TBRACCD
                          WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                AND SUBSTR (TBRACCD_DETAIL_CODE, 3, 2) IN ('XA',
                                                                           'XH',
                                                                           'QO',
                                                                           'TH',
                                                                           'TG',
                                                                           'TF')
                                AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                AND TBRACCD_EFFECTIVE_DATE =
                                       A.TBRACCD_EFFECTIVE_DATE),
                        '---')
                        DESCRIP_COMPLEMENTO,
                     NVL (
                        (SELECT TBRACCD_AMOUNT
                           FROM TBRACCD
                          WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                AND SUBSTR (TBRACCD_DETAIL_CODE, 3, 2) IN ('XA',
                                                                           'XH',
                                                                           'QO',
                                                                           'TH',
                                                                           'TG',
                                                                           'TF')
                                AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                AND TBRACCD_EFFECTIVE_DATE =
                                       A.TBRACCD_EFFECTIVE_DATE),
                        0)
                        MONTO_COMPLEMENTO
                FROM TBRACCD A
               WHERE     A.TBRACCD_PIDM = P_PIDM
                     AND A.TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                     AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                     AND A.TBRACCD_EFFECTIVE_DATE >= TRUNC (SYSDATE)
                     AND (SELECT SUM (TBRACCD_BALANCE)
                            FROM TBRACCD
                           WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                 AND TBRACCD_EFFECTIVE_DATE <=
                                        LAST_DAY (A.TBRACCD_EFFECTIVE_DATE)) >
                            0
            ORDER BY 3;

         RETURN (CUR_TRAN_CART_F);
      END;
   END F_FIJA_CART;   



   FUNCTION F_CURSOR_ESCALONADO_FIJA (P_PIDM NUMBER)
      RETURN PKG_FINANZAS_DINAMICOS.ESCA_FIJA
   IS
      CUR_ESCA_FIJOS   PKG_FINANZAS_DINAMICOS.ESCA_FIJA;
   BEGIN
      BEGIN
         OPEN CUR_ESCA_FIJOS FOR
            SELECT *
              FROM (SELECT SECU,
                           TZFACCE_DETAIL_CODE CODIGO,
                           TZFACCE_DESC DESCRIPCION,
                           (SELECT DISTINCT TZFACCE_AMOUNT
                              FROM TZFACCE A1
                             WHERE     A1.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                             FROM TZTPADI)
                                   AND A1.TZFACCE_DETAIL_CODE LIKE '%M3'
                                   AND A1.TZFACCE_STUDY =
                                          (SELECT MAX (TZFACCE_STUDY)
                                             FROM TZFACCE
                                            WHERE     TZFACCE_PIDM =
                                                         A1.TZFACCE_PIDM
                                                  AND TZFACCE_STUDY
                                                         IS NOT NULL)
                                   AND A1.TZFACCE_PIDM = FACE.TZFACCE_PIDM
                                   AND A1.TZFACCE_EFFECTIVE_DATE =
                                          CASE
                                             WHEN TO_CHAR (
                                                     ADD_MONTHS (
                                                        FACE.TZFACCE_EFFECTIVE_DATE,
                                                        (SECU - 1)),
                                                     'DD') = '31'
                                             THEN
                                                  ADD_MONTHS (
                                                     FACE.TZFACCE_EFFECTIVE_DATE,
                                                     (SECU - 1))
                                                - 1
                                             ELSE
                                                ADD_MONTHS (
                                                   FACE.TZFACCE_EFFECTIVE_DATE,
                                                   (SECU - 1))
                                          END)
                              MONTO,
                           CASE
                              WHEN TO_CHAR (
                                      ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                                  (SECU - 1)),
                                      'DD') = '31'
                              THEN
                                   ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                               (SECU - 1))
                                 - 1
                              ELSE
                                 ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                             (SECU - 1))
                           END
                              FECHA_VIGENCIA,
                           (CASE
                               WHEN (SELECT COUNT (*)
                                       FROM TBRACCD
                                      WHERE     TBRACCD_PIDM =
                                                   FACE.TZFACCE_PIDM
                                            AND TBRACCD_CREATE_SOURCE =
                                                   'TZFEDCA (PARC)'
                                            AND TBRACCD_BALANCE = 0
                                            AND TBRACCD_EFFECTIVE_DATE =
                                                   CASE
                                                      WHEN TO_CHAR (
                                                              ADD_MONTHS (
                                                                 FACE.TZFACCE_EFFECTIVE_DATE,
                                                                 (SECU - 1)),
                                                              'DD') = '31'
                                                      THEN
                                                           ADD_MONTHS (
                                                              FACE.TZFACCE_EFFECTIVE_DATE,
                                                              (SECU - 1))
                                                         - 1
                                                      ELSE
                                                         ADD_MONTHS (
                                                            FACE.TZFACCE_EFFECTIVE_DATE,
                                                            (SECU - 1))
                                                   END) > 0
                               THEN
                                  'NO APLICA'
                               WHEN TZFACCE_FLAG = 3 AND SECU = 1
                               THEN
                                  'EXCLUIR'
                               ELSE
                                  CASE
                                     WHEN (SELECT COUNT (*)
                                             FROM TBRACCD
                                            WHERE     TBRACCD_PIDM =
                                                         FACE.TZFACCE_PIDM
                                                  AND TBRACCD_CREATE_SOURCE =
                                                         'TZFEDCA (PARC)'
                                                  AND TBRACCD_EFFECTIVE_DATE =
                                                         CASE
                                                            WHEN TO_CHAR (
                                                                    ADD_MONTHS (
                                                                       FACE.TZFACCE_EFFECTIVE_DATE,
                                                                       (  SECU
                                                                        - 1)),
                                                                    'DD') =
                                                                    '31'
                                                            THEN
                                                                 ADD_MONTHS (
                                                                    FACE.TZFACCE_EFFECTIVE_DATE,
                                                                    (SECU - 1))
                                                               - 1
                                                            ELSE
                                                               ADD_MONTHS (
                                                                  FACE.TZFACCE_EFFECTIVE_DATE,
                                                                  (SECU - 1))
                                                         END
                                                  AND TBRACCD_EFFECTIVE_DATE <
                                                         TRUNC (SYSDATE)) > 0
                                     THEN
                                        'NO APLICA'
                                     WHEN TZFACCE_FLAG = 3 AND SECU = 1
                                     THEN
                                        'EXCLUIR'
                                     ELSE
                                        NULL
                                  END
                            END)
                              ESTATUS
                      FROM (SELECT ROW_NUMBER ()
                                   OVER (PARTITION BY A.TZFACCE_PIDM
                                         ORDER BY A.TZFACCE_EFFECTIVE_DATE)
                                      SECU,
                                   TZFACCE_PIDM,
                                   TZFACCE_TERM_CODE,
                                   TZFACCE_DETAIL_CODE,
                                   TZFACCE_DESC,
                                   TZFACCE_EFFECTIVE_DATE,
                                   TZFACCE_FLAG,
                                   TZFACCE_STUDY
                              FROM TZFACCE A
                                   CROSS JOIN
                                   (    SELECT LEVEL NUME
                                          FROM DUAL
                                    CONNECT BY LEVEL BETWEEN 1 AND 12)
                             WHERE     A.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                            FROM TZTPADI)
                                   AND A.TZFACCE_DETAIL_CODE LIKE '%M3'
                                   AND A.TZFACCE_STUDY =
                                          (SELECT MAX (TZFACCE_STUDY)
                                             FROM TZFACCE
                                            WHERE     TZFACCE_PIDM =
                                                         A.TZFACCE_PIDM
                                                  AND TZFACCE_STUDY
                                                         IS NOT NULL)
                                   AND A.TZFACCE_EFFECTIVE_DATE =
                                          (SELECT MIN (
                                                     TZFACCE_EFFECTIVE_DATE)
                                             FROM TZFACCE
                                            WHERE     TZFACCE_PIDM =
                                                         A.TZFACCE_PIDM
                                                  AND TZFACCE_STUDY =
                                                         A.TZFACCE_STUDY
                                                  AND TZFACCE_DETAIL_CODE =
                                                         A.TZFACCE_DETAIL_CODE)
                                   AND A.TZFACCE_PIDM = P_PIDM) FACE
                     WHERE (SELECT COUNT (*)
                              FROM TZFACCE A1
                             WHERE     A1.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                             FROM TZTPADI)
                                   AND A1.TZFACCE_DETAIL_CODE LIKE '%M3'
                                   AND A1.TZFACCE_STUDY =
                                          (SELECT MAX (TZFACCE_STUDY)
                                             FROM TZFACCE
                                            WHERE     TZFACCE_PIDM =
                                                         A1.TZFACCE_PIDM
                                                  AND TZFACCE_STUDY
                                                         IS NOT NULL)
                                   AND A1.TZFACCE_PIDM = FACE.TZFACCE_PIDM
                                   AND A1.TZFACCE_EFFECTIVE_DATE =
                                          CASE
                                             WHEN TO_CHAR (
                                                     ADD_MONTHS (
                                                        FACE.TZFACCE_EFFECTIVE_DATE,
                                                        (SECU - 1)),
                                                     'DD') = '31'
                                             THEN
                                                  ADD_MONTHS (
                                                     FACE.TZFACCE_EFFECTIVE_DATE,
                                                     (SECU - 1))
                                                - 1
                                             ELSE
                                                ADD_MONTHS (
                                                   FACE.TZFACCE_EFFECTIVE_DATE,
                                                   (SECU - 1))
                                          END) > 0)
             WHERE (ESTATUS != 'EXCLUIR' OR ESTATUS IS NULL);

         RETURN (CUR_ESCA_FIJOS);
      END;
   END F_CURSOR_ESCALONADO_FIJA;
   
      FUNCTION F_AJUSTE_FIJA (P_PIDM       NUMBER,
                           P_NUM_ESC    NUMBER,
                           P_MONTO      NUMBER,
                           P_ACCION     VARCHAR2)
      RETURN VARCHAR2
   IS
      VL_SEC_TZFACCE   NUMBER;
      VL_SOL_TZFACCE   NUMBER;
      VL_ERROR         VARCHAR2 (900);
      VL_TRAN_ESCA     NUMBER;
      VL_SECUENCIA     NUMBER;
      VL_ETIQUETA      NUMBER;
      VL_NUMACC        NUMBER;
      VL_PARC_VIG      NUMBER;
      VL_PARC_SALDO    NUMBER;
      VL_EXISTE_PARC   NUMBER;
   BEGIN
      BEGIN
         SELECT COUNT (*)
           INTO VL_ETIQUETA
           FROM GORADID
          WHERE GORADID_PIDM = P_PIDM AND GORADID_ADID_CODE = 'DINA';
      END;

      BEGIN
         SELECT COUNT (*)
           INTO VL_NUMACC
           FROM TZFACCE A
          WHERE     A.TZFACCE_PIDM = P_PIDM
                AND A.TZFACCE_DETAIL_CODE LIKE '%M3'
                AND A.TZFACCE_STUDY =
                       (SELECT MAX (TZFACCE_STUDY)
                          FROM TZFACCE
                         WHERE     TZFACCE_PIDM = A.TZFACCE_PIDM
                               AND TZFACCE_STUDY IS NOT NULL);
      END;

      IF VL_NUMACC = 0 AND VL_ETIQUETA != 0
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO VL_EXISTE_PARC
              FROM TBRACCD
             WHERE     TBRACCD_PIDM = P_PIDM
                   AND TBRACCD_DOCUMENT_NUMBER IS NULL
                   AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)';
         EXCEPTION
            WHEN OTHERS
            THEN
               VL_EXISTE_PARC := 0;
         END;

         IF VL_EXISTE_PARC = 0
         THEN
            VL_ERROR := 'La matricula no cuenta con cartera generada.';
         ELSE
            BEGIN
               FOR X
                  IN (SELECT *
                        FROM (SELECT SECU,
                                     PIDM,
                                     PERIODO,
                                     CODIGO,
                                     DESCRIPCION,
                                     MONTO,
                                     CASE
                                        WHEN TO_CHAR (
                                                ADD_MONTHS (VIGENCIA,
                                                            (SECU - 1)),
                                                'DD') = '31'
                                        THEN
                                             ADD_MONTHS (VIGENCIA,
                                                         (SECU - 1))
                                           - 1
                                        ELSE
                                           ADD_MONTHS (VIGENCIA, (SECU - 1))
                                     END
                                        VIGENCIA,
                                     FLAG,
                                     SOLICITUD,
                                     (SELECT MIN (TBRACCD_EFFECTIVE_DATE)
                                        FROM TBRACCD
                                       WHERE     TBRACCD_PIDM = PIDM
                                             AND TBRACCD_DOCUMENT_NUMBER
                                                    IS NULL
                                             AND TBRACCD_CREATE_SOURCE =
                                                    'TZFEDCA (PARC)')
                                        FECHA_INICIAL
                                FROM (SELECT ROW_NUMBER ()
                                             OVER (
                                                PARTITION BY TBRACCD_PIDM
                                                ORDER BY
                                                   TBRACCD_EFFECTIVE_DATE)
                                                SECU,
                                             TBRACCD_PIDM PIDM,
                                             TBRACCD_TERM_CODE PERIODO,
                                                SUBSTR (TBRACCD_DETAIL_CODE,
                                                        1,
                                                        2)
                                             || 'M3'
                                                CODIGO,
                                             'PROMOCION DE INSCRIPCION'
                                                DESCRIPCION,
                                             NULL MONTO,
                                             TBRACCD_EFFECTIVE_DATE VIGENCIA,
                                             NULL FLAG,
                                             (SELECT MAX (TZFACCE_STUDY)
                                                FROM TZFACCE
                                               WHERE     TZFACCE_PIDM =
                                                            A.TBRACCD_PIDM
                                                     AND TZFACCE_STUDY
                                                            IS NOT NULL)
                                                SOLICITUD
                                        FROM TBRACCD A
                                             CROSS JOIN
                                             (    SELECT LEVEL NUME
                                                    FROM DUAL
                                              CONNECT BY LEVEL BETWEEN 1
                                                                   AND 12)
                                       WHERE     A.TBRACCD_PIDM = P_PIDM
                                             AND A.TBRACCD_TRAN_NUMBER =
                                                    (SELECT MIN (
                                                               TBRACCD_TRAN_NUMBER)
                                                       FROM TBRACCD
                                                      WHERE     TBRACCD_PIDM =
                                                                   A.TBRACCD_PIDM
                                                            AND TBRACCD_DOCUMENT_NUMBER
                                                                   IS NULL
                                                            AND TBRACCD_CREATE_SOURCE =
                                                                   'TZFEDCA (PARC)')))
                       WHERE SECU = P_NUM_ESC)
               LOOP
                  BEGIN
                     SELECT COUNT (*)
                       INTO VL_EXISTE_PARC
                       FROM TBRACCD
                      WHERE     TBRACCD_PIDM = P_PIDM
                            AND TBRACCD_DOCUMENT_NUMBER IS NULL
                            AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA
                            AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        VL_EXISTE_PARC := 0;
                  END;

                  IF VL_EXISTE_PARC = 0
                  THEN
                     /* SI NO EXISTE PARCIALIDAD SOLO INSERTA EN TZFACCE */
                     IF P_NUM_ESC = 1
                     THEN
                        BEGIN
                           SELECT MAX (TZFACCE_SEC_PIDM) + 1
                             INTO VL_SEC_TZFACCE
                             FROM TZFACCE
                            WHERE TZFACCE_PIDM = X.PIDM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TZFACCE_STUDY), 1)
                             INTO VL_SOL_TZFACCE
                             FROM TZFACCE
                            WHERE     TZFACCE_PIDM = X.PIDM
                                  AND TZFACCE_STUDY IS NOT NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_SOL_TZFACCE := 1;
                        END;

                        BEGIN
                           INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                TZFACCE_SEC_PIDM,
                                                TZFACCE_TERM_CODE,
                                                TZFACCE_DETAIL_CODE,
                                                TZFACCE_DESC,
                                                TZFACCE_AMOUNT,
                                                TZFACCE_EFFECTIVE_DATE,
                                                TZFACCE_USER,
                                                TZFACCE_ACTIVITY_DATE,
                                                TZFACCE_FLAG,
                                                TZFACCE_STUDY)
                                VALUES (X.PIDM,
                                        VL_SEC_TZFACCE,
                                        X.PERIODO,
                                        X.CODIGO,
                                        X.DESCRIPCION,
                                        P_MONTO,
                                        X.VIGENCIA,
                                        'REZA',
                                        SYSDATE,
                                        '0',
                                        VL_SOL_TZFACCE);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR TZFACCE INSERTA = ' || SQLERRM;
                        END;
                     ELSE
                        BEGIN
                           SELECT MAX (TZFACCE_SEC_PIDM) + 1
                             INTO VL_SEC_TZFACCE
                             FROM TZFACCE
                            WHERE TZFACCE_PIDM = X.PIDM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TZFACCE_STUDY), 1)
                             INTO VL_SOL_TZFACCE
                             FROM TZFACCE
                            WHERE     TZFACCE_PIDM = X.PIDM
                                  AND TZFACCE_STUDY IS NOT NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_SOL_TZFACCE := 1;
                        END;

                        BEGIN
                           INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                TZFACCE_SEC_PIDM,
                                                TZFACCE_TERM_CODE,
                                                TZFACCE_DETAIL_CODE,
                                                TZFACCE_DESC,
                                                TZFACCE_AMOUNT,
                                                TZFACCE_EFFECTIVE_DATE,
                                                TZFACCE_USER,
                                                TZFACCE_ACTIVITY_DATE,
                                                TZFACCE_FLAG,
                                                TZFACCE_STUDY)
                                VALUES (X.PIDM,
                                        VL_SEC_TZFACCE,
                                        X.PERIODO,
                                        X.CODIGO,
                                        X.DESCRIPCION,
                                        P_MONTO,
                                        X.FECHA_INICIAL,
                                        'REZA',
                                        SYSDATE,
                                        '0',
                                        VL_SOL_TZFACCE);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR TZFACCE INSERTA = ' || SQLERRM;
                        END;

                        BEGIN
                           SELECT MAX (TZFACCE_SEC_PIDM) + 1
                             INTO VL_SEC_TZFACCE
                             FROM TZFACCE
                            WHERE TZFACCE_PIDM = X.PIDM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TZFACCE_STUDY), 1)
                             INTO VL_SOL_TZFACCE
                             FROM TZFACCE
                            WHERE     TZFACCE_PIDM = X.PIDM
                                  AND TZFACCE_STUDY IS NOT NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_SOL_TZFACCE := 1;
                        END;

                        BEGIN
                           INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                TZFACCE_SEC_PIDM,
                                                TZFACCE_TERM_CODE,
                                                TZFACCE_DETAIL_CODE,
                                                TZFACCE_DESC,
                                                TZFACCE_AMOUNT,
                                                TZFACCE_EFFECTIVE_DATE,
                                                TZFACCE_USER,
                                                TZFACCE_ACTIVITY_DATE,
                                                TZFACCE_FLAG,
                                                TZFACCE_STUDY)
                                VALUES (X.PIDM,
                                        VL_SEC_TZFACCE,
                                        X.PERIODO,
                                        X.CODIGO,
                                        X.DESCRIPCION,
                                        P_MONTO,
                                        X.VIGENCIA,
                                        'REZA',
                                        SYSDATE,
                                        '0',
                                        VL_SOL_TZFACCE);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR TZFACCE INSERTA = ' || SQLERRM;
                        END;
                     END IF;
                  ELSE
                     /* SI EXISTE PARCIALIDAD VALIDA SALDO Y VIGENCIA */
                     BEGIN
                        SELECT COUNT (*)
                          INTO VL_PARC_VIG
                          FROM TBRACCD
                         WHERE     TBRACCD_PIDM = P_PIDM
                               AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                               AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA
                               AND TBRACCD_DOCUMENT_NUMBER IS NULL
                               AND TBRACCD_EFFECTIVE_DATE > TRUNC (SYSDATE);
                     END;

                     IF VL_PARC_VIG = 0
                     THEN
                        VL_ERROR :=
                           'No se puede brindar descuento, la parcialidad se encuentra vencida.';
                     ELSE
                        BEGIN
                           SELECT NVL (TBRACCD_BALANCE, 0)
                             INTO VL_PARC_SALDO
                             FROM TBRACCD
                            WHERE     TBRACCD_PIDM = P_PIDM
                                  AND TBRACCD_CREATE_SOURCE =
                                         'TZFEDCA (PARC)'
                                  AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                  AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_PARC_SALDO := 0;
                        END;

                        IF VL_PARC_SALDO = 0
                        THEN
                           VL_ERROR :=
                              'No se puede brindar descuento, la parcialidad se encuentra pagada.';
                        ELSE
                           BEGIN
                              SELECT TBRACCD_TRAN_NUMBER
                                INTO VL_TRAN_ESCA
                                FROM TBRACCD
                               WHERE     TBRACCD_PIDM = P_PIDM
                                     AND TBRACCD_CREATE_SOURCE =
                                            'TZFEDCA (PARC)'
                                     AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                     AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 VL_TRAN_ESCA := 0;
                           END;

                           IF P_NUM_ESC = 1
                           THEN
                              BEGIN
                                 SELECT MAX (TZFACCE_SEC_PIDM) + 1
                                   INTO VL_SEC_TZFACCE
                                   FROM TZFACCE
                                  WHERE TZFACCE_PIDM = X.PIDM;
                              END;

                              BEGIN
                                 SELECT NVL (MAX (TZFACCE_STUDY), 1)
                                   INTO VL_SOL_TZFACCE
                                   FROM TZFACCE
                                  WHERE     TZFACCE_PIDM = X.PIDM
                                        AND TZFACCE_STUDY IS NOT NULL;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_SOL_TZFACCE := 1;
                              END;

                              BEGIN
                                 INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                      TZFACCE_SEC_PIDM,
                                                      TZFACCE_TERM_CODE,
                                                      TZFACCE_DETAIL_CODE,
                                                      TZFACCE_DESC,
                                                      TZFACCE_AMOUNT,
                                                      TZFACCE_EFFECTIVE_DATE,
                                                      TZFACCE_USER,
                                                      TZFACCE_ACTIVITY_DATE,
                                                      TZFACCE_FLAG,
                                                      TZFACCE_STUDY)
                                      VALUES (X.PIDM,
                                              VL_SEC_TZFACCE,
                                              X.PERIODO,
                                              X.CODIGO,
                                              X.DESCRIPCION,
                                              P_MONTO,
                                              X.VIGENCIA,
                                              'REZA',
                                              SYSDATE,
                                              '1',
                                              VL_SOL_TZFACCE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                       'ERROR TZFACCE INSERTA = ' || SQLERRM;
                              END;

                              BEGIN
                                 SELECT   NVL (MAX (TBRACCD_TRAN_NUMBER), 0)
                                        + 1
                                   INTO VL_SECUENCIA
                                   FROM TBRACCD
                                  WHERE TBRACCD_PIDM = P_PIDM;
                              END;

                              BEGIN
                                 INSERT INTO TBRACCD (
                                                TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_DESC,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_SURROGATE_ID,
                                                TBRACCD_VERSION,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_CREATE_SOURCE,
                                                TBRACCD_PERIOD,
                                                TBRACCD_RECEIPT_NUMBER)
                                    (SELECT TBRACCD_PIDM,
                                            VL_SECUENCIA,
                                            TBRACCD_TERM_CODE,
                                            SUBSTR (X.CODIGO, 1, 2) || 'M3',
                                            P_MONTO,
                                            P_MONTO * -1,
                                            'PROMOCION DE INSCRIPCION',
                                            USER,
                                            SYSDATE,
                                            X.VIGENCIA,
                                            X.VIGENCIA,
                                            TBRACCD_SRCE_CODE,
                                            TBRACCD_ACCT_FEED_IND,
                                            SYSDATE,
                                            0,
                                            NULL,
                                            NULL,
                                            VL_TRAN_ESCA,
                                            TBRACCD_FEED_DATE,
                                            TBRACCD_STSP_KEY_SEQUENCE,
                                            'TZFEDCA(ACC)',
                                            'TZFEDCA(ACC)',
                                            TBRACCD_PERIOD,
                                            TBRACCD_RECEIPT_NUMBER
                                       FROM TBRACCD A1
                                      WHERE     A1.TBRACCD_PIDM = P_PIDM
                                            AND TBRACCD_CREATE_SOURCE =
                                                   'TZFEDCA (PARC)'
                                            AND TBRACCD_DOCUMENT_NUMBER
                                                   IS NULL
                                            AND TBRACCD_EFFECTIVE_DATE =
                                                   X.VIGENCIA);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                          ' ERRROR AL INSERTAR TBRACCD REZA = '
                                       || SQLERRM;
                              END;
                           ELSE
                              /* SI EL ESCALONADO ES DIFERENTE A 1, AGREGA EL ESCALONADO 1 Y EL QUE SE VA A APLICAR*/
                              BEGIN
                                 SELECT MAX (TZFACCE_SEC_PIDM) + 1
                                   INTO VL_SEC_TZFACCE
                                   FROM TZFACCE
                                  WHERE TZFACCE_PIDM = X.PIDM;
                              END;

                              BEGIN
                                 SELECT NVL (MAX (TZFACCE_STUDY), 1)
                                   INTO VL_SOL_TZFACCE
                                   FROM TZFACCE
                                  WHERE     TZFACCE_PIDM = X.PIDM
                                        AND TZFACCE_STUDY IS NOT NULL;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_SOL_TZFACCE := 1;
                              END;

                              BEGIN
                                 INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                      TZFACCE_SEC_PIDM,
                                                      TZFACCE_TERM_CODE,
                                                      TZFACCE_DETAIL_CODE,
                                                      TZFACCE_DESC,
                                                      TZFACCE_AMOUNT,
                                                      TZFACCE_EFFECTIVE_DATE,
                                                      TZFACCE_USER,
                                                      TZFACCE_ACTIVITY_DATE,
                                                      TZFACCE_FLAG,
                                                      TZFACCE_STUDY)
                                      VALUES (X.PIDM,
                                              VL_SEC_TZFACCE,
                                              X.PERIODO,
                                              X.CODIGO,
                                              X.DESCRIPCION,
                                              P_MONTO,
                                              X.FECHA_INICIAL,
                                              'REZA',
                                              SYSDATE,
                                              '3',
                                              VL_SOL_TZFACCE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                       'ERROR TZFACCE INSERTA = ' || SQLERRM;
                              END;

                              BEGIN
                                 SELECT MAX (TZFACCE_SEC_PIDM) + 1
                                   INTO VL_SEC_TZFACCE
                                   FROM TZFACCE
                                  WHERE TZFACCE_PIDM = X.PIDM;
                              END;

                              BEGIN
                                 SELECT NVL (MAX (TZFACCE_STUDY), 1)
                                   INTO VL_SOL_TZFACCE
                                   FROM TZFACCE
                                  WHERE     TZFACCE_PIDM = X.PIDM
                                        AND TZFACCE_STUDY IS NOT NULL;
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_SOL_TZFACCE := 1;
                              END;

                              BEGIN
                                 INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                      TZFACCE_SEC_PIDM,
                                                      TZFACCE_TERM_CODE,
                                                      TZFACCE_DETAIL_CODE,
                                                      TZFACCE_DESC,
                                                      TZFACCE_AMOUNT,
                                                      TZFACCE_EFFECTIVE_DATE,
                                                      TZFACCE_USER,
                                                      TZFACCE_ACTIVITY_DATE,
                                                      TZFACCE_FLAG,
                                                      TZFACCE_STUDY)
                                      VALUES (X.PIDM,
                                              VL_SEC_TZFACCE,
                                              X.PERIODO,
                                              X.CODIGO,
                                              X.DESCRIPCION,
                                              P_MONTO,
                                              X.VIGENCIA,
                                              'REZA',
                                              SYSDATE,
                                              '1',
                                              VL_SOL_TZFACCE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                       'ERROR TZFACCE INSERTA = ' || SQLERRM;
                              END;

                              BEGIN
                                 SELECT   NVL (MAX (TBRACCD_TRAN_NUMBER), 0)
                                        + 1
                                   INTO VL_SECUENCIA
                                   FROM TBRACCD
                                  WHERE TBRACCD_PIDM = P_PIDM;
                              END;

                              BEGIN
                                 INSERT INTO TBRACCD (
                                                TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_DESC,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_SURROGATE_ID,
                                                TBRACCD_VERSION,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_CREATE_SOURCE,
                                                TBRACCD_PERIOD,
                                                TBRACCD_RECEIPT_NUMBER)
                                    (SELECT TBRACCD_PIDM,
                                            VL_SECUENCIA,
                                            TBRACCD_TERM_CODE,
                                            SUBSTR (X.CODIGO, 1, 2) || 'M3',
                                            P_MONTO,
                                            P_MONTO * -1,
                                            'PROMOCION DE INSCRIPCION',
                                            USER,
                                            SYSDATE,
                                            X.VIGENCIA,
                                            X.VIGENCIA,
                                            TBRACCD_SRCE_CODE,
                                            TBRACCD_ACCT_FEED_IND,
                                            SYSDATE,
                                            0,
                                            NULL,
                                            NULL,
                                            VL_TRAN_ESCA,
                                            TBRACCD_FEED_DATE,
                                            TBRACCD_STSP_KEY_SEQUENCE,
                                            'TZFEDCA(ACC)',
                                            'TZFEDCA(ACC)',
                                            TBRACCD_PERIOD,
                                            TBRACCD_RECEIPT_NUMBER
                                       FROM TBRACCD A1
                                      WHERE     A1.TBRACCD_PIDM = P_PIDM
                                            AND TBRACCD_CREATE_SOURCE =
                                                   'TZFEDCA (PARC)'
                                            AND TBRACCD_DOCUMENT_NUMBER
                                                   IS NULL
                                            AND TBRACCD_EFFECTIVE_DATE =
                                                   X.VIGENCIA);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                          ' ERRROR AL INSERTAR TBRACCD REZA = '
                                       || SQLERRM;
                              END;
                           END IF;
                        END IF;
                     END IF;
                  END IF;
               END LOOP;
            END;
         END IF;
      ELSE
         BEGIN
            FOR X
               IN (SELECT SECU,
                          TZFACCE_PIDM PIDM,
                          TZFACCE_TERM_CODE PERIODO,
                          TZFACCE_DETAIL_CODE CODIGO,
                          TZFACCE_DESC DESCRIPCION,
                          (SELECT DISTINCT TZFACCE_AMOUNT
                             FROM TZFACCE A1
                            WHERE     A1.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                            FROM TZTPADI)
                                  AND A1.TZFACCE_DETAIL_CODE LIKE '%M3'
                                  AND A1.TZFACCE_STUDY =
                                         (SELECT MAX (TZFACCE_STUDY)
                                            FROM TZFACCE
                                           WHERE     TZFACCE_PIDM =
                                                        A1.TZFACCE_PIDM
                                                 AND TZFACCE_STUDY
                                                        IS NOT NULL)
                                  AND A1.TZFACCE_PIDM = FACE.TZFACCE_PIDM
                                  AND A1.TZFACCE_EFFECTIVE_DATE =
                                         CASE
                                            WHEN TO_CHAR (
                                                    ADD_MONTHS (
                                                       FACE.TZFACCE_EFFECTIVE_DATE,
                                                       (SECU - 1)),
                                                    'DD') = '31'
                                            THEN
                                                 ADD_MONTHS (
                                                    FACE.TZFACCE_EFFECTIVE_DATE,
                                                    (SECU - 1))
                                               - 1
                                            ELSE
                                               ADD_MONTHS (
                                                  FACE.TZFACCE_EFFECTIVE_DATE,
                                                  (SECU - 1))
                                         END)
                             MONTO,
                          CASE
                             WHEN TO_CHAR (
                                     ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                                 (SECU - 1)),
                                     'DD') = '31'
                             THEN
                                  ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                              (SECU - 1))
                                - 1
                             ELSE
                                ADD_MONTHS (TZFACCE_EFFECTIVE_DATE,
                                            (SECU - 1))
                          END
                             VIGENCIA,
                          (SELECT DISTINCT TZFACCE_FLAG
                             FROM TZFACCE A1
                            WHERE     A1.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                            FROM TZTPADI)
                                  AND A1.TZFACCE_DETAIL_CODE LIKE '%M3'
                                  AND A1.TZFACCE_STUDY =
                                         (SELECT MAX (TZFACCE_STUDY)
                                            FROM TZFACCE
                                           WHERE     TZFACCE_PIDM =
                                                        A1.TZFACCE_PIDM
                                                 AND TZFACCE_STUDY
                                                        IS NOT NULL)
                                  AND A1.TZFACCE_PIDM = FACE.TZFACCE_PIDM
                                  AND A1.TZFACCE_EFFECTIVE_DATE =
                                         CASE
                                            WHEN TO_CHAR (
                                                    ADD_MONTHS (
                                                       FACE.TZFACCE_EFFECTIVE_DATE,
                                                       (SECU - 1)),
                                                    'DD') = '31'
                                            THEN
                                                 ADD_MONTHS (
                                                    FACE.TZFACCE_EFFECTIVE_DATE,
                                                    (SECU - 1))
                                               - 1
                                            ELSE
                                               ADD_MONTHS (
                                                  FACE.TZFACCE_EFFECTIVE_DATE,
                                                  (SECU - 1))
                                         END)
                             FLAG,
                          TZFACCE_STUDY SOLICITUD
                     FROM (SELECT ROW_NUMBER ()
                                  OVER (PARTITION BY A.TZFACCE_PIDM
                                        ORDER BY A.TZFACCE_EFFECTIVE_DATE)
                                     SECU,
                                  TZFACCE_PIDM,
                                  TZFACCE_TERM_CODE,
                                  TZFACCE_DETAIL_CODE,
                                  TZFACCE_DESC,
                                  TZFACCE_EFFECTIVE_DATE,
                                  TZFACCE_FLAG,
                                  TZFACCE_STUDY
                             FROM TZFACCE A
                                  CROSS JOIN
                                  (    SELECT LEVEL NUME
                                         FROM DUAL
                                   CONNECT BY LEVEL BETWEEN 1 AND 12)
                            WHERE     A.TZFACCE_PIDM IN (SELECT TZTPADI_PIDM
                                                           FROM TZTPADI)
                                  AND A.TZFACCE_DETAIL_CODE LIKE '%M3'
                                  AND A.TZFACCE_STUDY =
                                         (SELECT MAX (TZFACCE_STUDY)
                                            FROM TZFACCE
                                           WHERE     TZFACCE_PIDM =
                                                        A.TZFACCE_PIDM
                                                 AND TZFACCE_STUDY
                                                        IS NOT NULL)
                                  AND A.TZFACCE_EFFECTIVE_DATE =
                                         (SELECT MIN (TZFACCE_EFFECTIVE_DATE)
                                            FROM TZFACCE
                                           WHERE     TZFACCE_PIDM =
                                                        A.TZFACCE_PIDM
                                                 AND TZFACCE_STUDY =
                                                        A.TZFACCE_STUDY
                                                 AND TZFACCE_DETAIL_CODE =
                                                        A.TZFACCE_DETAIL_CODE)
                                  AND A.TZFACCE_PIDM = P_PIDM) FACE
                    WHERE SECU = P_NUM_ESC)
            LOOP
               VL_ERROR := NULL;

               IF P_ACCION = 'EDITAR'
               THEN
                  IF X.FLAG IS NULL
                  THEN
                     /* NO EXISTE ESCALONADO EN EDC */
                     BEGIN
                        SELECT TBRACCD_TRAN_NUMBER
                          INTO VL_TRAN_ESCA
                          FROM TBRACCD
                         WHERE     TBRACCD_PIDM = P_PIDM
                               AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                               AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VL_TRAN_ESCA := 0;
                     END;

                     IF VL_TRAN_ESCA = 0
                     THEN
                        BEGIN
                           SELECT MAX (TZFACCE_SEC_PIDM) + 1
                             INTO VL_SEC_TZFACCE
                             FROM TZFACCE
                            WHERE TZFACCE_PIDM = X.PIDM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TZFACCE_STUDY), 1)
                             INTO VL_SOL_TZFACCE
                             FROM TZFACCE
                            WHERE     TZFACCE_PIDM = X.PIDM
                                  AND TZFACCE_STUDY IS NOT NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_SOL_TZFACCE := 1;
                        END;

                        BEGIN
                           INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                TZFACCE_SEC_PIDM,
                                                TZFACCE_TERM_CODE,
                                                TZFACCE_DETAIL_CODE,
                                                TZFACCE_DESC,
                                                TZFACCE_AMOUNT,
                                                TZFACCE_EFFECTIVE_DATE,
                                                TZFACCE_USER,
                                                TZFACCE_ACTIVITY_DATE,
                                                TZFACCE_FLAG,
                                                TZFACCE_STUDY)
                                VALUES (X.PIDM,
                                        VL_SEC_TZFACCE,
                                        X.PERIODO,
                                        X.CODIGO,
                                        X.DESCRIPCION,
                                        P_MONTO,
                                        X.VIGENCIA,
                                        'REZA',
                                        SYSDATE,
                                        '0',
                                        VL_SOL_TZFACCE);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR TZFACCE INSERTA = ' || SQLERRM;
                        END;
                     ELSE
                        BEGIN
                           SELECT MAX (TZFACCE_SEC_PIDM) + 1
                             INTO VL_SEC_TZFACCE
                             FROM TZFACCE
                            WHERE TZFACCE_PIDM = X.PIDM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TZFACCE_STUDY), 1)
                             INTO VL_SOL_TZFACCE
                             FROM TZFACCE
                            WHERE     TZFACCE_PIDM = X.PIDM
                                  AND TZFACCE_STUDY IS NOT NULL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_SOL_TZFACCE := 1;
                        END;

                        BEGIN
                           INSERT INTO TZFACCE (TZFACCE_PIDM,
                                                TZFACCE_SEC_PIDM,
                                                TZFACCE_TERM_CODE,
                                                TZFACCE_DETAIL_CODE,
                                                TZFACCE_DESC,
                                                TZFACCE_AMOUNT,
                                                TZFACCE_EFFECTIVE_DATE,
                                                TZFACCE_USER,
                                                TZFACCE_ACTIVITY_DATE,
                                                TZFACCE_FLAG,
                                                TZFACCE_STUDY)
                                VALUES (X.PIDM,
                                        VL_SEC_TZFACCE,
                                        X.PERIODO,
                                        X.CODIGO,
                                        X.DESCRIPCION,
                                        P_MONTO,
                                        X.VIGENCIA,
                                        'REZA',
                                        SYSDATE,
                                        '1',
                                        VL_SOL_TZFACCE);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR TZFACCE INSERTA = ' || SQLERRM;
                        END;

                        BEGIN
                           SELECT NVL (MAX (TBRACCD_TRAN_NUMBER), 0) + 1
                             INTO VL_SECUENCIA
                             FROM TBRACCD
                            WHERE TBRACCD_PIDM = P_PIDM;
                        END;

                        BEGIN
                           INSERT INTO TBRACCD (TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_DESC,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_SURROGATE_ID,
                                                TBRACCD_VERSION,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_CREATE_SOURCE,
                                                TBRACCD_PERIOD,
                                                TBRACCD_RECEIPT_NUMBER)
                              (SELECT TBRACCD_PIDM,
                                      VL_SECUENCIA,
                                      TBRACCD_TERM_CODE,
                                      SUBSTR (X.CODIGO, 1, 2) || 'M3',
                                      P_MONTO,
                                      P_MONTO * -1,
                                      'PROMOCION DE INSCRIPCION',
                                      USER,
                                      SYSDATE,
                                      X.VIGENCIA,
                                      X.VIGENCIA,
                                      TBRACCD_SRCE_CODE,
                                      TBRACCD_ACCT_FEED_IND,
                                      SYSDATE,
                                      0,
                                      NULL,
                                      NULL,
                                      VL_TRAN_ESCA,
                                      TBRACCD_FEED_DATE,
                                      TBRACCD_STSP_KEY_SEQUENCE,
                                      'TZFEDCA(ACC)',
                                      'TZFEDCA(ACC)',
                                      TBRACCD_PERIOD,
                                      TBRACCD_RECEIPT_NUMBER
                                 FROM TBRACCD A1
                                WHERE     A1.TBRACCD_PIDM = P_PIDM
                                      AND A1.TBRACCD_CREATE_SOURCE =
                                             'TZFEDCA (PARC)'
                                      AND A1.TBRACCD_DOCUMENT_NUMBER IS NULL
                                      AND A1.TBRACCD_EFFECTIVE_DATE =
                                             X.VIGENCIA);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                    ' ERRROR AL INSERTAR TBRACCD REZA = '
                                 || SQLERRM;
                        END;
                     END IF;
                  ELSIF X.FLAG = 3
                  THEN
                     BEGIN
                        SELECT TBRACCD_TRAN_NUMBER
                          INTO VL_TRAN_ESCA
                          FROM TBRACCD
                         WHERE     TBRACCD_PIDM = P_PIDM
                               AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                               AND TBRACCD_DOCUMENT_NUMBER IS NULL
                               AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VL_TRAN_ESCA := 0;
                     END;

                     IF VL_TRAN_ESCA = 0
                     THEN
                        BEGIN
                           UPDATE TZFACCE
                              SET TZFACCE_FLAG = 0, TZFACCE_AMOUNT = P_MONTO
                            WHERE     TZFACCE_PIDM = P_PIDM
                                  AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA;
                        END;
                     ELSE
                        BEGIN
                           UPDATE TZFACCE
                              SET TZFACCE_FLAG = 1, TZFACCE_AMOUNT = P_MONTO
                            WHERE     TZFACCE_PIDM = P_PIDM
                                  AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA;
                        END;


                        BEGIN
                           SELECT NVL (MAX (TBRACCD_TRAN_NUMBER), 0) + 1
                             INTO VL_SECUENCIA
                             FROM TBRACCD
                            WHERE TBRACCD_PIDM = P_PIDM;
                        END;

                        BEGIN
                           INSERT INTO TBRACCD (TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_DESC,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_SURROGATE_ID,
                                                TBRACCD_VERSION,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_CREATE_SOURCE,
                                                TBRACCD_PERIOD,
                                                TBRACCD_RECEIPT_NUMBER)
                              (SELECT TBRACCD_PIDM,
                                      VL_SECUENCIA,
                                      TBRACCD_TERM_CODE,
                                      SUBSTR (X.CODIGO, 1, 2) || 'M3',
                                      P_MONTO,
                                      P_MONTO * -1,
                                      'PROMOCION DE INSCRIPCION',
                                      USER,
                                      SYSDATE,
                                      X.VIGENCIA,
                                      X.VIGENCIA,
                                      TBRACCD_SRCE_CODE,
                                      TBRACCD_ACCT_FEED_IND,
                                      SYSDATE,
                                      0,
                                      NULL,
                                      NULL,
                                      VL_TRAN_ESCA,
                                      TBRACCD_FEED_DATE,
                                      TBRACCD_STSP_KEY_SEQUENCE,
                                      'TZFEDCA(ACC)',
                                      'TZFEDCA(ACC)',
                                      TBRACCD_PERIOD,
                                      TBRACCD_RECEIPT_NUMBER
                                 FROM TBRACCD A1
                                WHERE     A1.TBRACCD_PIDM = P_PIDM
                                      AND TBRACCD_CREATE_SOURCE =
                                             'TZFEDCA (PARC)'
                                      AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                      AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                    ' ERRROR AL INSERTAR TBRACCD REZA = '
                                 || SQLERRM;
                        END;
                     END IF;
                  ELSE
                     IF X.FLAG = 0
                     THEN
                        BEGIN
                           UPDATE TZFACCE
                              SET TZFACCE_AMOUNT = P_MONTO
                            WHERE     TZFACCE_PIDM = P_PIDM
                                  AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                                  AND TZFACCE_FLAG = 0;
                        END;
                     ELSE
                        BEGIN
                           SELECT TBRACCD_TRAN_NUMBER
                             INTO VL_TRAN_ESCA
                             FROM TBRACCD
                            WHERE     TBRACCD_PIDM = P_PIDM
                                  AND TBRACCD_CREATE_SOURCE = 'TZFEDCA(ACC)'
                                  AND SUBSTR (TBRACCD_DETAIL_CODE, 3, 2) =
                                         'M3'
                                  AND TBRACCD_FEED_DOC_CODE IS NULL
                                  AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_TRAN_ESCA := 0;
                        END;

                        IF VL_TRAN_ESCA != 0
                        THEN
                           PKG_FINANZAS.P_DESAPLICA_PAGOS (P_PIDM,
                                                           VL_TRAN_ESCA);
                           PKG_FINANZAS_DINAMICOS.P_ACTUA_ESCA (P_PIDM,
                                                                VL_TRAN_ESCA,
                                                                P_MONTO);

                           BEGIN
                              UPDATE TZFACCE
                                 SET TZFACCE_AMOUNT = P_MONTO
                               WHERE     TZFACCE_PIDM = P_PIDM
                                     AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                                     AND TZFACCE_FLAG = 1;
                           END;
                        END IF;
                     END IF;
                  END IF;
               ELSIF P_ACCION = 'ELIMINA'
               THEN
                  IF X.FLAG = 0
                  THEN
                     IF X.SECU = 1
                     THEN
                        UPDATE TZFACCE
                           SET TZFACCE_FLAG = 3
                         WHERE     TZFACCE_PIDM = P_PIDM
                               AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                               AND TZFACCE_FLAG = 0;
                     ELSE
                        BEGIN
                           DELETE TZFACCE
                            WHERE     TZFACCE_PIDM = P_PIDM
                                  AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                                  AND TZFACCE_FLAG = 0;
                        END;
                     END IF;
                  ELSE
                     BEGIN
                        SELECT TBRACCD_TRAN_NUMBER
                          INTO VL_TRAN_ESCA
                          FROM TBRACCD
                         WHERE     TBRACCD_PIDM = P_PIDM
                               AND TBRACCD_CREATE_SOURCE = 'TZFEDCA(ACC)'
                               AND SUBSTR (TBRACCD_DETAIL_CODE, 3, 2) = 'M3'
                               AND TBRACCD_FEED_DOC_CODE IS NULL
                               AND TBRACCD_EFFECTIVE_DATE = X.VIGENCIA;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VL_TRAN_ESCA := 0;
                     END;

                     DBMS_OUTPUT.PUT_LINE (
                        'REZA DINAMICOS = ' || VL_TRAN_ESCA);

                     IF VL_TRAN_ESCA != 0
                     THEN
                        PKG_FINANZAS.P_DESAPLICA_PAGOS (P_PIDM, VL_TRAN_ESCA);
                        DBMS_OUTPUT.PUT_LINE (
                           'REZA DINAMICOS 2 = ' || VL_TRAN_ESCA);

                        BEGIN
                           SELECT NVL (MAX (TBRACCD_TRAN_NUMBER), 0) + 1
                             INTO VL_SECUENCIA
                             FROM TBRACCD
                            WHERE TBRACCD_PIDM = P_PIDM;
                        END;

                        BEGIN
                           INSERT INTO TBRACCD (TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_DESC,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_SURROGATE_ID,
                                                TBRACCD_VERSION,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_PERIOD,
                                                TBRACCD_RECEIPT_NUMBER)
                              (SELECT TBRACCD_PIDM,
                                      VL_SECUENCIA,
                                      TBRACCD_TERM_CODE,
                                      SUBSTR (X.CODIGO, 1, 2) || 'ON',
                                      X.MONTO,
                                      X.MONTO,
                                      'CANCELACION DE PROMOCION',
                                      USER,
                                      SYSDATE,
                                      X.VIGENCIA,
                                      X.VIGENCIA,
                                      TBRACCD_SRCE_CODE,
                                      TBRACCD_ACCT_FEED_IND,
                                      SYSDATE,
                                      0,
                                      NULL,
                                      NULL,
                                      VL_TRAN_ESCA,
                                      TBRACCD_FEED_DATE,
                                      TBRACCD_STSP_KEY_SEQUENCE,
                                      'CAN_DIN',
                                      TBRACCD_PERIOD,
                                      TBRACCD_RECEIPT_NUMBER
                                 FROM TBRACCD A1
                                WHERE     A1.TBRACCD_PIDM = P_PIDM
                                      AND A1.TBRACCD_CREATE_SOURCE =
                                             'TZFEDCA(ACC)'
                                      AND SUBSTR (A1.TBRACCD_DETAIL_CODE,
                                                  3,
                                                  2) = 'M3'
                                      AND A1.TBRACCD_FEED_DOC_CODE IS NULL
                                      AND A1.TBRACCD_EFFECTIVE_DATE =
                                             X.VIGENCIA);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                    ' ERRROR AL INSERTAR TBRACCD REZA = '
                                 || SQLERRM;
                        END;

                        BEGIN
                           UPDATE TBRACCD
                              SET TBRACCD_TRAN_NUMBER_PAID = VL_SECUENCIA,
                                  TBRACCD_FEED_DOC_CODE = 'CANCEL'
                            WHERE     TBRACCD_PIDM = P_PIDM
                                  AND TBRACCD_TRAN_NUMBER = VL_TRAN_ESCA;
                        END;

                        IF X.SECU = 1
                        THEN
                           BEGIN
                              UPDATE TZFACCE
                                 SET TZFACCE_FLAG = 3
                               WHERE     TZFACCE_PIDM = P_PIDM
                                     AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                                     AND TZFACCE_FLAG = 1;
                           END;
                        ELSE
                           DBMS_OUTPUT.PUT_LINE (
                              'REZA DINAMICOS 3 = ' || VL_TRAN_ESCA);

                           BEGIN
                              DELETE TZFACCE
                               WHERE     TZFACCE_PIDM = P_PIDM
                                     AND TZFACCE_EFFECTIVE_DATE = X.VIGENCIA
                                     AND TZFACCE_FLAG = 1;
                           END;
                        END IF;
                     END IF;
                  END IF;
               END IF;
            END LOOP;
         END;
      END IF;

      IF VL_ERROR IS NULL
      THEN
         VL_ERROR := 'EXITO';
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      RETURN (VL_ERROR);
   END F_AJUSTE_FIJA;


-- FIN GOG  
---cartera fija
  FUNCTION F_CARTERA_FIJA (P_PIDM         NUMBER,
                            P_FECHA_INI    DATE,
                            P_CODIGO       VARCHAR2,
                            P_USUARIO      VARCHAR2,
                            P_ACCION       VARCHAR2)
      RETURN VARCHAR2
   IS
      VL_AJUSTE        NUMBER := 0;
      VL_APLICA        NUMBER := 0;
      VL_COSTO         NUMBER := 0;
      VL_SEC           NUMBER;
      VL_PAID          NUMBER;
      VL_CODIGO        VARCHAR2 (5);
      VL_DESCRIPCION   VARCHAR2 (50);
      VL_MONEDA        VARCHAR2 (5);
      VL_ERROR         VARCHAR2 (900);
      VL_VIGENCIA      DATE;
      VL_COSTO_REAL    NUMBER;
      VL_ENTRA_ACC     NUMBER;
      VL_ACC           VARCHAR2 (900);
      VL_ACC_COUNT     NUMBER;
      VL_FECHA_APLI    DATE;
      VL_FECHA         DATE;
      VL_FACCE         NUMBER;
      VL_SALDO         NUMBER;
      VL_SALDO_PARC    NUMBER;
   BEGIN
      BEGIN
         IF P_ACCION = 'CARTERA'
         THEN
            --------------------------------------------------------
            /* ENTRA AJUSTE A COLEGIATURA POR PAQUETE DINAMICO */
            --------------------------------------------------------
            BEGIN
               FOR EDC
                  IN (SELECT *
                        FROM TBRACCD
                       WHERE     TBRACCD_PIDM = P_PIDM
                             AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                             AND TBRACCD_DOCUMENT_NUMBER IS NULL
                             AND TBRACCD_FEED_DATE = P_FECHA_INI)
               LOOP
                  VL_APLICA := 0;
                  VL_AJUSTE := 0;

                  BEGIN
                     FOR CODI
                        IN (  SELECT A.*,
                                     TBBDETC_DESC DESCRIPCION,
                                     (CASE
                                         WHEN TZTPADI_CHARGES IS NULL
                                         THEN
                                            LAST_DAY (
                                               EDC.TBRACCD_EFFECTIVE_DATE)
                                         WHEN TZTPADI_CHARGES IS NOT NULL
                                         THEN
                                            ADD_MONTHS (TZTPADI_EFFECTIVE_DATE,
                                                        TZTPADI_CHARGES)
                                      END)
                                        FECHA_APLICA
                                FROM TZTPADI A, TBBDETC
                               WHERE     TZTPADI_DETAIL_CODE =
                                            TBBDETC_DETAIL_CODE
                                     AND TZTPADI_FLAG = 0
                                     AND TZTPADI_PIDM = EDC.TBRACCD_PIDM
                                     AND TZTPADI_ADD_COL = 'Y'
                                     AND TZTPADI_IND_CANCE IS NULL
                                     AND LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) BETWEEN LAST_DAY (
                                                                                          TZTPADI_EFFECTIVE_DATE)
                                                                                   AND CASE
                                                                                          WHEN TZTPADI_CHARGES
                                                                                                  IS NULL
                                                                                          THEN
                                                                                             LAST_DAY (
                                                                                                EDC.TBRACCD_EFFECTIVE_DATE)
                                                                                          WHEN TZTPADI_CHARGES
                                                                                                  IS NOT NULL
                                                                                          THEN
                                                                                             ADD_MONTHS (
                                                                                                TZTPADI_EFFECTIVE_DATE,
                                                                                                TZTPADI_CHARGES)
                                                                                       END
                            ORDER BY TZTPADI_ADD_COL DESC)
                     LOOP
                        BEGIN
                           SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                             INTO VL_SEC
                             FROM TBRACCD
                            WHERE TBRACCD_PIDM = EDC.TBRACCD_PIDM;
                        END;

                        BEGIN
                           SELECT COUNT (*)
                             INTO VL_ENTRA_ACC
                             FROM TBRACCD
                            WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                  AND TBRACCD_TERM_CODE =
                                         EDC.TBRACCD_TERM_CODE
                                  AND TBRACCD_DETAIL_CODE =
                                         CODI.TZTPADI_DETAIL_CODE
                                  AND TBRACCD_FEED_DATE =
                                         EDC.TBRACCD_FEED_DATE
                                  AND TBRACCD_STSP_KEY_SEQUENCE =
                                         EDC.TBRACCD_STSP_KEY_SEQUENCE
                                  AND TBRACCD_FEED_DOC_CODE != 'CANCEL'
                                  AND TBRACCD_DATA_ORIGIN = 'TZFEDCA (ACDI)';
                        END;

                        IF VL_ENTRA_ACC = 0
                        THEN
                           VL_ACC :=
                              PKG_FINANZAS.F_INSERTA_TBRACCD (
                                 EDC.TBRACCD_PIDM,
                                 VL_SEC,
                                 NULL,
                                 EDC.TBRACCD_TERM_CODE,
                                 EDC.TBRACCD_PERIOD,
                                 CODI.TZTPADI_DETAIL_CODE,
                                 0,
                                 0,
                                 EDC.TBRACCD_FEED_DATE,
                                 CODI.DESCRIPCION,
                                 EDC.TBRACCD_STSP_KEY_SEQUENCE,
                                 'TZFEDCA (ACDI)',
                                 EDC.TBRACCD_FEED_DATE);
                        END IF;

                        IF CODI.TZTPADI_CHARGES IS NOT NULL
                        THEN
                           VL_COSTO_REAL :=
                              CODI.TZTPADI_AMOUNT / CODI.TZTPADI_CHARGES;
                        ELSE
                           VL_COSTO_REAL := CODI.TZTPADI_AMOUNT;
                        END IF;

                        VL_AJUSTE := VL_COSTO_REAL;
                        VL_APLICA := VL_AJUSTE + VL_APLICA;

                        IF CODI.TZTPADI_CHARGES IS NOT NULL
                        THEN
                           BEGIN
                              SELECT COUNT (*)
                                INTO VL_ACC_COUNT
                                FROM TBRACCD
                               WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                     AND TBRACCD_CREATE_SOURCE =
                                            'TZFEDCA (PARC)'
                                     AND TBRACCD_EFFECTIVE_DATE >=
                                            CODI.TZTPADI_EFFECTIVE_DATE
                                     AND TBRACCD_DOCUMENT_NUMBER IS NULL;

                              UPDATE TBRACCD
                                 SET TBRACCD_FEED_DOC_CODE =
                                           VL_ACC_COUNT
                                        || ' DE '
                                        || CODI.TZTPADI_CHARGES
                               WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                     AND TBRACCD_DETAIL_CODE =
                                            CODI.TZTPADI_DETAIL_CODE
                                     AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                     AND TBRACCD_CREATE_SOURCE =
                                            'TZFEDCA (ACDI)'
                                     AND TBRACCD_FEED_DATE = P_FECHA_INI
                                     AND (   TBRACCD_FEED_DOC_CODE !=
                                                'CANCEL'
                                          OR TBRACCD_FEED_DOC_CODE IS NULL)
                                     AND TBRACCD_AMOUNT = 0;
                           END;
                        ELSE
                           UPDATE TBRACCD
                              SET TBRACCD_FEED_DOC_CODE = 'RECURREN'
                            WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                  AND TBRACCD_DETAIL_CODE =
                                         CODI.TZTPADI_DETAIL_CODE
                                  AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                  AND TBRACCD_CREATE_SOURCE =
                                         'TZFEDCA (ACDI)'
                                  AND TBRACCD_FEED_DATE = P_FECHA_INI
                                  AND (   TBRACCD_FEED_DOC_CODE != 'CANCEL'
                                       OR TBRACCD_FEED_DOC_CODE IS NULL)
                                  AND TBRACCD_AMOUNT = 0;
                        END IF;

                        IF     CODI.TZTPADI_CHARGES IS NOT NULL
                           AND LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) =
                                  LAST_DAY (
                                     ADD_MONTHS (CODI.TZTPADI_EFFECTIVE_DATE,
                                                 (CODI.TZTPADI_CHARGES - 1)))
                        THEN
                           BEGIN
                              UPDATE TZTPADI
                                 SET TZTPADI_FLAG = 1
                               WHERE     TZTPADI_PIDM = CODI.TZTPADI_PIDM
                                     AND TZTPADI_SEQNO = CODI.TZTPADI_SEQNO;

                              UPDATE TBRACCD
                                 SET TBRACCD_FEED_DOC_CODE =
                                           CODI.TZTPADI_CHARGES
                                        || ' DE '
                                        || CODI.TZTPADI_CHARGES
                               WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                     AND TBRACCD_DETAIL_CODE =
                                            CODI.TZTPADI_DETAIL_CODE
                                     AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                     AND TBRACCD_CREATE_SOURCE =
                                            'TZFEDCA (ACDI)'
                                     AND TBRACCD_FEED_DATE = P_FECHA_INI
                                     AND (   TBRACCD_FEED_DOC_CODE !=
                                                'CANCEL'
                                          OR TBRACCD_FEED_DOC_CODE IS NULL)
                                     AND TBRACCD_AMOUNT = 0;
                           END;
                        END IF;
                     END LOOP;

                     IF VL_APLICA != 0
                     THEN
                        PKG_FINANZAS_DINAMICOS.P_ELIMINA_TRAN (
                           EDC.TBRACCD_PIDM,
                           EDC.TBRACCD_TRAN_NUMBER,
                           VL_APLICA);
                     END IF;
                  END;
               END LOOP;
            END;

            -------------------------------------------------------
            /* INSERTA ACCESORIO POR PAQUETE DINAMICO */
            -------------------------------------------------------
            BEGIN
               FOR EDC
                  IN (SELECT *
                        FROM TBRACCD
                       WHERE     TBRACCD_PIDM = P_PIDM
                             AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                             AND TBRACCD_DOCUMENT_NUMBER IS NULL
                             AND TBRACCD_FEED_DATE = P_FECHA_INI)
               LOOP
                  BEGIN
                     FOR CODI
                        IN (SELECT *
                              FROM TZTPADI
                             WHERE     TZTPADI_FLAG = 0
                                   AND TZTPADI_PIDM = EDC.TBRACCD_PIDM
                                   AND TZTPADI_ADD_COL = 'N'
                                   AND TZTPADI_IND_CANCE IS NULL
                                   AND LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) BETWEEN LAST_DAY (
                                                                                        TZTPADI_EFFECTIVE_DATE)
                                                                                 AND LAST_DAY (
                                                                                        ADD_MONTHS (
                                                                                           TZTPADI_EFFECTIVE_DATE,
                                                                                           (  NVL (
                                                                                                 TZTPADI_CHARGES,
                                                                                                 100)
                                                                                            - 1))))
                     LOOP
                        IF CODI.TZTPADI_CHARGES IS NULL
                        THEN
                           VL_COSTO := CODI.TZTPADI_AMOUNT;
                        ELSE
                           VL_COSTO :=
                              CODI.TZTPADI_AMOUNT / CODI.TZTPADI_CHARGES;
                        END IF;

                        BEGIN
                           SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                             INTO VL_SEC
                             FROM TBRACCD
                            WHERE TBRACCD_PIDM = P_PIDM;
                        END;

                        BEGIN
                           INSERT INTO TBRACCD (TBRACCD_PIDM,
                                                TBRACCD_TRAN_NUMBER,
                                                TBRACCD_TRAN_NUMBER_PAID,
                                                TBRACCD_TERM_CODE,
                                                TBRACCD_DETAIL_CODE,
                                                TBRACCD_USER,
                                                TBRACCD_ENTRY_DATE,
                                                TBRACCD_AMOUNT,
                                                TBRACCD_BALANCE,
                                                TBRACCD_EFFECTIVE_DATE,
                                                TBRACCD_FEED_DATE,
                                                TBRACCD_DESC,
                                                TBRACCD_SRCE_CODE,
                                                TBRACCD_ACCT_FEED_IND,
                                                TBRACCD_ACTIVITY_DATE,
                                                TBRACCD_SESSION_NUMBER,
                                                TBRACCD_TRANS_DATE,
                                                TBRACCD_CURR_CODE,
                                                TBRACCD_DATA_ORIGIN,
                                                TBRACCD_CREATE_SOURCE,
                                                TBRACCD_STSP_KEY_SEQUENCE,
                                                TBRACCD_PERIOD,
                                                TBRACCD_USER_ID,
                                                TBRACCD_RECEIPT_NUMBER)
                                VALUES (EDC.TBRACCD_PIDM,
                                        VL_SEC,
                                        NULL,
                                        EDC.TBRACCD_TERM_CODE,
                                        CODI.TZTPADI_DETAIL_CODE,
                                        USER,
                                        SYSDATE,
                                        VL_COSTO,
                                        VL_COSTO,
                                        EDC.TBRACCD_EFFECTIVE_DATE,
                                        EDC.TBRACCD_FEED_DATE,
                                        CODI.TZTPADI_DESC,
                                        'T',
                                        'Y',
                                        SYSDATE,
                                        0,
                                        EDC.TBRACCD_EFFECTIVE_DATE,
                                        'MXN',
                                        'TZFEDCA (DIN)',
                                        'TZFEDCA (DIN)',
                                        EDC.TBRACCD_STSP_KEY_SEQUENCE,
                                        EDC.TBRACCD_PERIOD,
                                        USER,
                                        EDC.TBRACCD_RECEIPT_NUMBER);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              VL_ERROR :=
                                 'ERROR AL INSERTAR ACC DINA' || SQLERRM;
                        END;

                        IF LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) =
                              LAST_DAY (
                                 ADD_MONTHS (CODI.TZTPADI_EFFECTIVE_DATE,
                                             (CODI.TZTPADI_CHARGES - 1)))
                        THEN
                           BEGIN
                              UPDATE TZTPADI
                                 SET TZTPADI_FLAG = 1
                               WHERE     TZTPADI_PIDM = CODI.TZTPADI_PIDM
                                     AND TZTPADI_SEQNO = CODI.TZTPADI_SEQNO;
                           END;
                        END IF;
                     END LOOP;
                  END;
               END LOOP;
            END;
         ELSIF P_ACCION = 'ELIMINA'
         THEN
            ---------------------------------------------------------
            /* SE ELIMINA LOS ACCESORIOS DINAMICOS A SOLICITUD DEL ALUMNO */
            ----------------------------------------------------------
            BEGIN
               SELECT SUM (TBRACCD_BALANCE)
                 INTO VL_SALDO
                 FROM TBRACCD
                WHERE     TBRACCD_PIDM = P_PIDM
                      AND TBRACCD_EFFECTIVE_DATE <=
                             LAST_DAY (TRUNC (SYSDATE));
            EXCEPTION
               WHEN OTHERS
               THEN
                  VL_SALDO := 0;
            END;

            BEGIN
               SELECT   TBRACCD_AMOUNT
                      - NVL (
                           (SELECT SUM (TBRACCD_AMOUNT)
                              FROM TBRACCD
                             WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                   AND (   TBRACCD_CREATE_SOURCE =
                                              'CANCELA DINA'
                                        OR     TBRACCD_CREATE_SOURCE =
                                                  'TZFEDCA(ACC)'
                                           AND SUBSTR (TBRACCD_DETAIL_CODE,
                                                       3,
                                                       2) = 'M3')
                                   AND TBRACCD_TRAN_NUMBER_PAID =
                                          A.TBRACCD_TRAN_NUMBER),
                           0)
                         SALDO
                 INTO VL_SALDO_PARC
                 FROM TBRACCD A
                WHERE     A.TBRACCD_PIDM = P_PIDM
                      AND A.TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                      AND A.TBRACCD_EFFECTIVE_DATE <=
                             LAST_DAY (TRUNC (SYSDATE));
            EXCEPTION
               WHEN OTHERS
               THEN
                  VL_SALDO_PARC := 0;
            END;

            VL_SALDO_PARC := VL_SALDO_PARC * .10;

            IF VL_SALDO > VL_SALDO_PARC
            THEN
               BEGIN
                  SELECT DISTINCT (TO_DATE (TZTPADI_EFFECTIVE_DATE))
                    INTO VL_FECHA
                    FROM TZTPADI
                   WHERE     TZTPADI_PIDM = P_PIDM
                         -- AND TZTPADI_DELETE = 1
                         AND TZTPADI_IND_CANCE IS NULL
                         AND TZTPADI_DETAIL_CODE = P_CODIGO;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VL_FECHA := SYSDATE;
               END;

               IF VL_FECHA >= TRUNC (SYSDATE)
               THEN
                  VL_FECHA_APLI := VL_FECHA;
               ELSE
                  VL_FECHA_APLI := TRUNC (SYSDATE);
               END IF;

               BEGIN
                  SELECT COUNT (*)
                    INTO VL_FACCE
                    FROM ZSTPARA
                   WHERE     ZSTPARA_MAPA_ID = 'ACC_ALIANZA'
                         AND ZSTPARA_PARAM_ID = SUBSTR (P_CODIGO, 3, 2);
               END;

               -------------------------------------------------------------
               /* SE IMPLEMENTA VALIDACION DEL CÓDIGO EN TZFACCE O TZTPADI */
               -------------------------------------------------------------

               IF VL_FACCE = 0
               THEN
                  BEGIN
                     FOR ELI
                        IN (SELECT TZTPADI_PIDM,
                                   TZTPADI_SEQNO,
                                   TZTPADI_DETAIL_CODE,
                                   TZTPADI_DESC,
                                   TZTPADI_AMOUNT,
                                   TZTPADI_EFFECTIVE_DATE,
                                   TZTPADI_ADD_COL,
                                   TZTPADI_CHARGES,
                                   CASE
                                      WHEN TZTPADI_CHARGES IS NULL
                                      THEN
                                         LAST_DAY (TRUNC (SYSDATE) + 360)
                                      WHEN TZTPADI_CHARGES IS NOT NULL
                                      THEN
                                         LAST_DAY (
                                            ADD_MONTHS (
                                               TZTPADI_EFFECTIVE_DATE,
                                               TZTPADI_CHARGES))
                                   END
                                      FECHA_FINAL
                              FROM TZTPADI
                             WHERE     TZTPADI_PIDM = P_PIDM
                                   AND TZTPADI_DETAIL_CODE = P_CODIGO
                                   -- AND TZTPADI_DELETE = 1
                                   AND TZTPADI_IND_CANCE IS NULL
                                   AND LAST_DAY (VL_FECHA_APLI) BETWEEN LAST_DAY (
                                                                           TZTPADI_EFFECTIVE_DATE)
                                                                    AND CASE
                                                                           WHEN TZTPADI_CHARGES
                                                                                   IS NULL
                                                                           THEN
                                                                              LAST_DAY (
                                                                                 VL_FECHA_APLI)
                                                                           WHEN TZTPADI_CHARGES
                                                                                   IS NOT NULL
                                                                           THEN
                                                                              LAST_DAY (
                                                                                 ADD_MONTHS (
                                                                                    TZTPADI_EFFECTIVE_DATE,
                                                                                    TZTPADI_CHARGES))
                                                                        END)
                     LOOP
                        VL_PAID := NULL;

                        IF ELI.TZTPADI_CHARGES IS NOT NULL
                        THEN
                           VL_COSTO_REAL :=
                              ELI.TZTPADI_AMOUNT / ELI.TZTPADI_CHARGES;
                        ELSE
                           VL_COSTO_REAL := ELI.TZTPADI_AMOUNT;
                        END IF;

                        IF ELI.TZTPADI_ADD_COL = 'Y'
                        THEN
                           FOR EDC
                              IN (  SELECT *
                                      FROM TBRACCD A
                                     WHERE     A.TBRACCD_PIDM = P_PIDM
                                           AND A.TBRACCD_CREATE_SOURCE =
                                                  'TZFEDCA (PARC)'
                                           AND A.TBRACCD_DOCUMENT_NUMBER
                                                  IS NULL
                                           AND A.TBRACCD_EFFECTIVE_DATE >=
                                                  TRUNC (SYSDATE)
                                           AND LAST_DAY (
                                                  A.TBRACCD_EFFECTIVE_DATE) <=
                                                  LAST_DAY (ELI.FECHA_FINAL)
                                           AND (SELECT SUM (TBRACCD_BALANCE)
                                                  FROM TBRACCD
                                                 WHERE     TBRACCD_PIDM =
                                                              A.TBRACCD_PIDM
                                                       AND TBRACCD_EFFECTIVE_DATE <=
                                                              LAST_DAY (
                                                                 A.TBRACCD_EFFECTIVE_DATE)) >
                                                  0
                                  ORDER BY TBRACCD_TRAN_NUMBER)
                           LOOP
                              VL_PAID := EDC.TBRACCD_TRAN_NUMBER;

                              IF EDC.TBRACCD_BALANCE = 0
                              THEN
                                 VL_PAID := NULL;
                              END IF;

                              BEGIN
                                 SELECT TBBDETC_DETAIL_CODE,
                                        TBBDETC_DESC,
                                        TVRDCTX_CURR_CODE
                                   INTO VL_CODIGO, VL_DESCRIPCION, VL_MONEDA
                                   FROM TBBDETC, TVRDCTX
                                  WHERE     TBBDETC_DETAIL_CODE =
                                               TVRDCTX_DETC_CODE
                                        AND TBBDETC_DETAIL_CODE =
                                                  SUBSTR (
                                                     EDC.TBRACCD_DETAIL_CODE,
                                                     1,
                                                     2)
                                               || (SELECT ZSTPARA_PARAM_VALOR
                                                     FROM ZSTPARA
                                                    WHERE     ZSTPARA_MAPA_ID =
                                                                 'CAN_DINAACC'
                                                          AND ZSTPARA_PARAM_ID =
                                                                 SUBSTR (
                                                                    P_CODIGO,
                                                                    3,
                                                                    2));
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    BEGIN
                                       SELECT TBBDETC_DETAIL_CODE,
                                              TBBDETC_DESC,
                                              TVRDCTX_CURR_CODE
                                         INTO VL_CODIGO,
                                              VL_DESCRIPCION,
                                              VL_MONEDA
                                         FROM TBBDETC, TVRDCTX
                                        WHERE     TBBDETC_DETAIL_CODE =
                                                     TVRDCTX_DETC_CODE
                                              AND TBBDETC_DETAIL_CODE =
                                                        SUBSTR (
                                                           EDC.TBRACCD_TERM_CODE,
                                                           1,
                                                           2)
                                                     || 'B4';
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          VL_ERROR :=
                                                'ERROR CODIGO DINAMICOS'
                                             || SQLERRM;
                                    END;
                              END;

                              BEGIN
                                 SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                                   INTO VL_SEC
                                   FROM TBRACCD
                                  WHERE TBRACCD_PIDM = P_PIDM;
                              END;

                              IF EDC.TBRACCD_EFFECTIVE_DATE < TRUNC (SYSDATE)
                              THEN
                                 VL_VIGENCIA := TRUNC (SYSDATE);
                              ELSE
                                 VL_VIGENCIA := EDC.TBRACCD_EFFECTIVE_DATE;
                              END IF;
                                                   
                     --GOG
                     IF EDC.TBRACCD_TRANS_DATE > TRUNC(SYSDATE) THEN 
                              BEGIN

                     
                                 INSERT
                                   INTO TBRACCD (TBRACCD_PIDM,
                                                 TBRACCD_TRAN_NUMBER,
                                                 TBRACCD_TRAN_NUMBER_PAID,
                                                 TBRACCD_TERM_CODE,
                                                 TBRACCD_DETAIL_CODE,
                                                 TBRACCD_USER,
                                                 TBRACCD_ENTRY_DATE,
                                                 TBRACCD_AMOUNT,
                                                 TBRACCD_BALANCE,
                                                 TBRACCD_EFFECTIVE_DATE,
                                                 TBRACCD_FEED_DATE,
                                                 TBRACCD_DESC,
                                                 TBRACCD_SRCE_CODE,
                                                 TBRACCD_ACCT_FEED_IND,
                                                 TBRACCD_ACTIVITY_DATE,
                                                 TBRACCD_SESSION_NUMBER,
                                                 TBRACCD_TRANS_DATE,
                                                 TBRACCD_CURR_CODE,
                                                 TBRACCD_DATA_ORIGIN,
                                                 TBRACCD_CREATE_SOURCE,
                                                 TBRACCD_STSP_KEY_SEQUENCE,
                                                 TBRACCD_PERIOD,
                                                 TBRACCD_USER_ID,
                                                 TBRACCD_RECEIPT_NUMBER,
                                                 TBRACCD_FEED_DOC_CODE)
                                 VALUES (EDC.TBRACCD_PIDM,
                                         VL_SEC,
                                         VL_PAID,
                                         EDC.TBRACCD_TERM_CODE,
                                         VL_CODIGO,
                                         P_USUARIO,
                                         SYSDATE,
                                         VL_COSTO_REAL,
                                         (VL_COSTO_REAL * -1),
                                         VL_VIGENCIA,
                                         EDC.TBRACCD_FEED_DATE,
                                         VL_DESCRIPCION,
                                         'T',
                                         'Y',
                                         SYSDATE,
                                         0,
                                         VL_VIGENCIA,
                                         VL_MONEDA,
                                         'CANCELA DINA',
                                         'CANCELA DINA',
                                         EDC.TBRACCD_STSP_KEY_SEQUENCE,
                                         EDC.TBRACCD_PERIOD,
                                         P_USUARIO,
                                         EDC.TBRACCD_RECEIPT_NUMBER,
                                         'CAN ' || ELI.TZTPADI_DETAIL_CODE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                          'ERROR AL INSERTAR ACC DINA'
                                       || SQLERRM;
                              END;

                              IF     ELI.TZTPADI_CHARGES IS NOT NULL
                                 AND LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) =
                                        LAST_DAY (
                                           ADD_MONTHS (
                                              ELI.TZTPADI_EFFECTIVE_DATE,
                                              (ELI.TZTPADI_CHARGES - 1)))
                              THEN
                                 EXIT;
                              END IF;
                        END IF;
                        --GOG                        
                           END LOOP;
                        ELSIF ELI.TZTPADI_ADD_COL = 'N'
                        THEN
                           /* VALIDAR SI CANCELARA ACCESORIOS */
                           FOR EDC
                              IN (  SELECT *
                                      FROM TBRACCD A
                                     WHERE     A.TBRACCD_PIDM = P_PIDM
                                           AND A.TBRACCD_CREATE_SOURCE =
                                                  'TZFEDCA (DIN)'
                                           AND A.TBRACCD_DOCUMENT_NUMBER
                                                  IS NULL
                                           AND A.TBRACCD_EFFECTIVE_DATE >=
                                                  TRUNC (SYSDATE)
                                           AND LAST_DAY (
                                                  A.TBRACCD_EFFECTIVE_DATE) <=
                                                  LAST_DAY (ELI.FECHA_FINAL)
                                           AND A.TBRACCD_DETAIL_CODE =
                                                  ELI.TZTPADI_DETAIL_CODE
                                           AND (SELECT SUM (TBRACCD_BALANCE)
                                                  FROM TBRACCD
                                                 WHERE     TBRACCD_PIDM =
                                                              A.TBRACCD_PIDM
                                                       AND TBRACCD_EFFECTIVE_DATE <=
                                                              LAST_DAY (
                                                                 A.TBRACCD_EFFECTIVE_DATE)) >
                                                  0
                                  ORDER BY TBRACCD_TRAN_NUMBER)
                           LOOP
                              VL_PAID := EDC.TBRACCD_TRAN_NUMBER;

                              IF EDC.TBRACCD_BALANCE = 0
                              THEN
                                 VL_PAID := NULL;
                              END IF;

                              BEGIN
                                 SELECT TBBDETC_DETAIL_CODE,
                                        TBBDETC_DESC,
                                        TVRDCTX_CURR_CODE
                                   INTO VL_CODIGO, VL_DESCRIPCION, VL_MONEDA
                                   FROM TBBDETC, TVRDCTX
                                  WHERE     TBBDETC_DETAIL_CODE =
                                               TVRDCTX_DETC_CODE
                                        AND TBBDETC_DETAIL_CODE =
                                                  SUBSTR (
                                                     EDC.TBRACCD_DETAIL_CODE,
                                                     1,
                                                     2)
                                               || (SELECT ZSTPARA_PARAM_VALOR
                                                     FROM ZSTPARA
                                                    WHERE     ZSTPARA_MAPA_ID =
                                                                 'CAN_DINAACC'
                                                          AND ZSTPARA_PARAM_ID =
                                                                 SUBSTR (
                                                                    P_CODIGO,
                                                                    3,
                                                                    2));
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    BEGIN
                                       SELECT TBBDETC_DETAIL_CODE,
                                              TBBDETC_DESC,
                                              TVRDCTX_CURR_CODE
                                         INTO VL_CODIGO,
                                              VL_DESCRIPCION,
                                              VL_MONEDA
                                         FROM TBBDETC, TVRDCTX
                                        WHERE     TBBDETC_DETAIL_CODE =
                                                     TVRDCTX_DETC_CODE
                                              AND TBBDETC_DETAIL_CODE =
                                                        SUBSTR (
                                                           EDC.TBRACCD_TERM_CODE,
                                                           1,
                                                           2)
                                                     || 'B4';
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                          VL_ERROR :=
                                                'ERROR CODIGO DINAMICOS'
                                             || SQLERRM;
                                    END;
                              END;

                              BEGIN
                                 SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                                   INTO VL_SEC
                                   FROM TBRACCD
                                  WHERE TBRACCD_PIDM = P_PIDM;
                              END;

                              IF EDC.TBRACCD_EFFECTIVE_DATE < TRUNC (SYSDATE)
                              THEN
                                 VL_VIGENCIA := TRUNC (SYSDATE);
                              ELSE
                                 VL_VIGENCIA := EDC.TBRACCD_EFFECTIVE_DATE;
                              END IF;
                     
                     --GOG
                     IF EDC.TBRACCD_TRANS_DATE > TRUNC(SYSDATE) THEN 
                     
                              BEGIN
                                 INSERT
                                   INTO TBRACCD (TBRACCD_PIDM,
                                                 TBRACCD_TRAN_NUMBER,
                                                 TBRACCD_TRAN_NUMBER_PAID,
                                                 TBRACCD_TERM_CODE,
                                                 TBRACCD_DETAIL_CODE,
                                                 TBRACCD_USER,
                                                 TBRACCD_ENTRY_DATE,
                                                 TBRACCD_AMOUNT,
                                                 TBRACCD_BALANCE,
                                                 TBRACCD_EFFECTIVE_DATE,
                                                 TBRACCD_FEED_DATE,
                                                 TBRACCD_DESC,
                                                 TBRACCD_SRCE_CODE,
                                                 TBRACCD_ACCT_FEED_IND,
                                                 TBRACCD_ACTIVITY_DATE,
                                                 TBRACCD_SESSION_NUMBER,
                                                 TBRACCD_TRANS_DATE,
                                                 TBRACCD_CURR_CODE,
                                                 TBRACCD_DATA_ORIGIN,
                                                 TBRACCD_CREATE_SOURCE,
                                                 TBRACCD_STSP_KEY_SEQUENCE,
                                                 TBRACCD_PERIOD,
                                                 TBRACCD_USER_ID,
                                                 TBRACCD_RECEIPT_NUMBER,
                                                 TBRACCD_FEED_DOC_CODE)
                                 VALUES (EDC.TBRACCD_PIDM,
                                         VL_SEC,
                                         VL_PAID,
                                         EDC.TBRACCD_TERM_CODE,
                                         VL_CODIGO,
                                         P_USUARIO,
                                         SYSDATE,
                                         VL_COSTO_REAL,
                                         (VL_COSTO_REAL * -1),
                                         VL_VIGENCIA,
                                         EDC.TBRACCD_FEED_DATE,
                                         VL_DESCRIPCION,
                                         'T',
                                         'Y',
                                         SYSDATE,
                                         0,
                                         VL_VIGENCIA,
                                         VL_MONEDA,
                                         'CANCELA DINA',
                                         'CANCELA DINA',
                                         EDC.TBRACCD_STSP_KEY_SEQUENCE,
                                         EDC.TBRACCD_PERIOD,
                                         P_USUARIO,
                                         EDC.TBRACCD_RECEIPT_NUMBER,
                                         'CAN ' || ELI.TZTPADI_DETAIL_CODE);
                              EXCEPTION
                                 WHEN OTHERS
                                 THEN
                                    VL_ERROR :=
                                          'ERROR AL INSERTAR ACC DINA'
                                       || SQLERRM;
                              END;

                              BEGIN
                                 UPDATE TBRACCD
                                    SET TBRACCD_FEED_DOC_CODE = 'CANCE'
                                  WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                                        AND TBRACCD_TRAN_NUMBER =
                                               EDC.TBRACCD_TRAN_NUMBER;
                              END;

                              IF     ELI.TZTPADI_CHARGES IS NOT NULL
                                 AND LAST_DAY (EDC.TBRACCD_EFFECTIVE_DATE) =
                                        LAST_DAY (
                                           ADD_MONTHS (
                                              ELI.TZTPADI_EFFECTIVE_DATE,
                                              (ELI.TZTPADI_CHARGES - 1)))
                              THEN
                                 EXIT;
                              END IF;
                            END IF;
                            --GOG
                           END LOOP;
                        END IF;

                        BEGIN
                           UPDATE TZTPADI
                              SET TZTPADI_IND_CANCE = 1,
                                  TZTPADI_FLAG = 1,
                                  TZTPADI_ACTIVITY_DATE = SYSDATE,
                                  TZTPADI_USER = P_USUARIO
                            WHERE     TZTPADI_PIDM = ELI.TZTPADI_PIDM
                                  AND TZTPADI_SEQNO = ELI.TZTPADI_SEQNO;
                        END;
                     END LOOP;
                  END;
               ELSE
                  FOR EDC
                     IN (  SELECT *
                             FROM TBRACCD
                            WHERE     TBRACCD_PIDM = P_PIDM
                                  AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (ACC)'
                                  AND TBRACCD_FEED_DOC_CODE IS NULL
                                  AND LAST_DAY (TBRACCD_EFFECTIVE_DATE) >=
                                         LAST_DAY (TRUNC (SYSDATE))
                                  AND TBRACCD_DETAIL_CODE = P_CODIGO
                         ORDER BY TBRACCD_TRAN_NUMBER)
                  LOOP
                     VL_PAID := EDC.TBRACCD_TRAN_NUMBER;

                     IF EDC.TBRACCD_BALANCE = 0
                     THEN
                        VL_PAID := NULL;
                     END IF;

                     BEGIN
                        SELECT TBBDETC_DETAIL_CODE,
                               TBBDETC_DESC,
                               TVRDCTX_CURR_CODE
                          INTO VL_CODIGO, VL_DESCRIPCION, VL_MONEDA
                          FROM TBBDETC, TVRDCTX
                         WHERE     TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE
                               AND TBBDETC_DETAIL_CODE =
                                      (SELECT    SUBSTR (P_CODIGO, 1, 2)
                                              || ZSTPARA_PARAM_VALOR
                                         FROM ZSTPARA
                                        WHERE     ZSTPARA_MAPA_ID =
                                                     'ACC_ALIANZA'
                                              AND ZSTPARA_PARAM_ID =
                                                     SUBSTR (P_CODIGO, 3, 2));
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VL_ERROR := 'ERROR CODIGO DINAMICOS' || SQLERRM;
                     END;

                     BEGIN
                        SELECT MAX (TBRACCD_TRAN_NUMBER) + 1
                          INTO VL_SEC
                          FROM TBRACCD
                         WHERE TBRACCD_PIDM = P_PIDM;
                     END;

                     IF EDC.TBRACCD_EFFECTIVE_DATE < TRUNC (SYSDATE)
                     THEN
                        VL_VIGENCIA := TRUNC (SYSDATE);
                     ELSE
                        VL_VIGENCIA := EDC.TBRACCD_EFFECTIVE_DATE;
                     END IF;
                     
                     --GOG
                     IF EDC.TBRACCD_TRANS_DATE > TRUNC(SYSDATE) THEN 
                     
                     BEGIN
                        INSERT INTO TBRACCD (TBRACCD_PIDM,
                                             TBRACCD_TRAN_NUMBER,
                                             TBRACCD_TRAN_NUMBER_PAID,
                                             TBRACCD_TERM_CODE,
                                             TBRACCD_DETAIL_CODE,
                                             TBRACCD_USER,
                                             TBRACCD_ENTRY_DATE,
                                             TBRACCD_AMOUNT,
                                             TBRACCD_BALANCE,
                                             TBRACCD_EFFECTIVE_DATE,
                                             TBRACCD_FEED_DATE,
                                             TBRACCD_DESC,
                                             TBRACCD_SRCE_CODE,
                                             TBRACCD_ACCT_FEED_IND,
                                             TBRACCD_ACTIVITY_DATE,
                                             TBRACCD_SESSION_NUMBER,
                                             TBRACCD_TRANS_DATE,
                                             TBRACCD_CURR_CODE,
                                             TBRACCD_DATA_ORIGIN,
                                             TBRACCD_CREATE_SOURCE,
                                             TBRACCD_STSP_KEY_SEQUENCE,
                                             TBRACCD_PERIOD,
                                             TBRACCD_USER_ID,
                                             TBRACCD_RECEIPT_NUMBER,
                                             TBRACCD_FEED_DOC_CODE)
                             VALUES (EDC.TBRACCD_PIDM,
                                     VL_SEC,
                                     VL_PAID,
                                     EDC.TBRACCD_TERM_CODE,
                                     VL_CODIGO,
                                     P_USUARIO,
                                     SYSDATE,
                                     EDC.TBRACCD_AMOUNT,
                                     (EDC.TBRACCD_AMOUNT * -1),
                                     VL_VIGENCIA,
                                     EDC.TBRACCD_FEED_DATE,
                                     VL_DESCRIPCION,
                                     'T',
                                     'Y',
                                     SYSDATE,
                                     0,
                                     VL_VIGENCIA,
                                     VL_MONEDA,
                                     'CANCELA DINA',
                                     'CANCELA DINA',
                                     EDC.TBRACCD_STSP_KEY_SEQUENCE,
                                     EDC.TBRACCD_PERIOD,
                                     P_USUARIO,
                                     EDC.TBRACCD_RECEIPT_NUMBER,
                                     'CAN ' || P_CODIGO);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VL_ERROR := 'ERROR AL INSERTAR ACC DINA' || SQLERRM;
                     END;

                     BEGIN
                        UPDATE TBRACCD
                           SET TBRACCD_FEED_DOC_CODE = 'CANCE'
                         WHERE     TBRACCD_PIDM = EDC.TBRACCD_PIDM
                               AND TBRACCD_TRAN_NUMBER =
                                      EDC.TBRACCD_TRAN_NUMBER;
                     END;
                     END IF;
                     --GOG                 
                 END LOOP;

                  BEGIN
                     UPDATE TZFACCE
                        SET TZFACCE_FLAG = 1
                      WHERE     TZFACCE_DETAIL_CODE = P_CODIGO
                            AND TZFACCE_PIDM = P_PIDM;
                  END;
               END IF;
            ELSE
               VL_ERROR :=
                  'El accesorio seleccionado no se puede cancelar, presenta saldo a favor o pagado.';
            END IF;
         END IF;
      END;

      IF VL_ERROR IS NULL
      THEN
         VL_ERROR := 'EXITO';
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      RETURN (VL_ERROR);
   END F_CARTERA_FIJA;
---AGOG FIN 06082024   
END PKG_FINANZAS_DINAMICOS;
/

DROP PUBLIC SYNONYM PKG_FINANZAS_DINAMICOS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FINANZAS_DINAMICOS FOR BANINST1.PKG_FINANZAS_DINAMICOS;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_FINANZAS_DINAMICOS TO PUBLIC;
