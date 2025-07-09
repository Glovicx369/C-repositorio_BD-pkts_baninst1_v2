DROP PACKAGE BODY BANINST1.PKG_FINANZAS_REZA;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_FINANZAS_REZA AS
/******************************************************************************
   NAME:       PKG_FINANZAS_REZA
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        16/07/2020      jrezaoli       1. Created this package body.
******************************************************************************/

FUNCTION F_CYE_EMPLEADO ( P_CAMPUS       VARCHAR2,
                          P_NIVEL        VARCHAR2,
                          P_PIDM         NUMBER,
                          P_MATRICULA    VARCHAR2,
                          P_PROGRAMA     VARCHAR2,
                          P_PERIODO      VARCHAR2,
                          P_FECHA_INICIO DATE,
                          P_PARTE        VARCHAR2,
                          P_ACCION       VARCHAR2
                                                  )RETURN VARCHAR2 IS

VL_ERROR            VARCHAR2(800):='EXITO';
VL_DESCUENTO_COD    NUMBER;
VL_DESC_COD         NUMBER;
VL_ETIQUETA         VARCHAR2(20);
VL_TIPO             VARCHAR2(20);
VL_BITA             NUMBER;
VL_JORNADA          VARCHAR2(5);
VL_COD_ETIQ         VARCHAR2(10);


 BEGIN
   FOR EMPLEADO IN (
                    SELECT *
                      FROM TZVBECA A
                     WHERE     A.PIDM = P_PIDM
                           AND A.FECHA_INICIO = (SELECT MAX(FECHA_INICIO)
                                                   FROM TZVBECA
                                                  WHERE     PIDM = A.PIDM
                                                        AND FECHA_INICIO = NVL(P_FECHA_INICIO,FECHA_INICIO))
                     UNION
                    SELECT TZTBECA_CAMP CAMPUS,
                           TZTBECA_LEVL NIVEL,
                           TZTBECA_PIDM PIDM,
                           TZTBECA_ID MATRICULA,
                           TZTBECA_PROGRAM PROGRAMA,
                           TZTBECA_TERM_CODE PERIODO,
                           TZTBECA_PTRM_CODE PARTE,
                           TZTBECA_START_DATE,
                           TZTBECA_ETIQUETA ETIQUETA,
                           TZTBECA_OBSERVACIONES OBSERVACION
                      FROM TZTBECA B
                     WHERE     B.TZTBECA_PIDM = P_PIDM
                           AND B.TZTBECA_START_DATE = (SELECT MAX(TZTBECA_START_DATE)
                                                         FROM TZTBECA
                                                        WHERE     TZTBECA_PIDM = B.TZTBECA_PIDM
                                                              AND TZTBECA_START_DATE = NVL(P_FECHA_INICIO,TZTBECA_START_DATE))
   )LOOP

     BEGIN
       SELECT COUNT(*)
       INTO VL_BITA
       FROM TZTBECA
       WHERE TZTBECA_PIDM = EMPLEADO.PIDM
       AND TZTBECA_START_DATE = EMPLEADO.FECHA_INICIO;
     EXCEPTION
     WHEN OTHERS THEN
     VL_BITA:=0;
     END;
     --DBMS_OUTPUT.PUT_LINE('INICIO 1 = '||P_ACCION);

     BEGIN
       SELECT SUBSTR(T.SGRSATT_ATTS_CODE,3,1)
         INTO VL_JORNADA
         FROM SGRSATT T
        WHERE T.SGRSATT_PIDM = EMPLEADO.PIDM
              AND T.SGRSATT_STSP_KEY_SEQUENCE = (SELECT MAX(DISTINCT TBRACCD_STSP_KEY_SEQUENCE)
                                                    FROM TBRACCD
                                                    WHERE TBRACCD_PIDM = EMPLEADO.PIDM
                                                    AND TBRACCD_TERM_CODE = EMPLEADO.PERIODO
                                                    AND TBRACCD_PERIOD = EMPLEADO.PARTE
                                                    AND TBRACCD_CREATE_SOURCE LIKE 'TZFEDCA%'
                                                    AND TBRACCD_DOCUMENT_NUMBER IS NULL)
              AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
              AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
              AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                                FROM SGRSATT TT
                                               WHERE     TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                     AND TT.SGRSATT_STSP_KEY_SEQUENCE= T.SGRSATT_STSP_KEY_SEQUENCE
                                                     AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
                                                     AND REGEXP_LIKE  (TT.SGRSATT_ATTS_CODE , '^[0-9]'))
        AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                       FROM SGRSATT T1
                                       WHERE T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                       AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                       AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                       AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
                                       AND REGEXP_LIKE  (T1.SGRSATT_ATTS_CODE , '^[0-9]'));
     EXCEPTION
     WHEN OTHERS THEN
     VL_JORNADA:=NULL;
     END;

     IF VL_JORNADA IN ('R','C') THEN
        VL_JORNADA:='COM';
     ELSIF VL_JORNADA IN ('I','S') THEN
        VL_JORNADA:='INT';
     END IF;

     IF P_ACCION = 'ELIMINA' THEN /*    SE ELIMINA REGISTRO DESDE LA FORMA PESTAÑA CARGAR  */

         IF EMPLEADO.ETIQUETA = 'FUTL' THEN
            VL_ETIQUETA :='FUTL';
            VL_TIPO     :='FAM';
         ELSIF EMPLEADO.ETIQUETA = 'EUTL' THEN
            VL_ETIQUETA :='EUTL';
            VL_TIPO     :='COL';
         ELSIF EMPLEADO.ETIQUETA = 'PRUT' THEN
            VL_ETIQUETA :='PRUT';
            VL_TIPO     :='PUTL';
         ELSIF EMPLEADO.ETIQUETA = 'PRAL' THEN
            VL_ETIQUETA :='PRAL';
            VL_TIPO     :='PALI';
         ELSIF EMPLEADO.ETIQUETA = 'EMOC' THEN
            VL_ETIQUETA :='EMOC';
            VL_TIPO     :='OCC';
         END IF;

         BEGIN
             INSERT
               INTO TZTBECA
                    (TZTBECA_CAMP,
                     TZTBECA_LEVL,
                     TZTBECA_PIDM,
                     TZTBECA_ID,
                     TZTBECA_PROGRAM,
                     TZTBECA_TERM_CODE,
                     TZTBECA_START_DATE,
                     TZTBECA_PTRM_CODE,
                     TZTBECA_ETIQUETA,
                     TZTBECA_ACTIVITY_DATE,
                     TZTBECA_ACTIVITY_UPDATE,
                     TZTBECA_USER,
                     TZTBECA_USER_UPDATE,
                     TZTBECA_DATA_ORIGIN,
                     TZTBECA_STATUS,
                     TZTBECA_ORDEN,
                     TZTBECA_OBSERVACIONES)
             VALUES (P_CAMPUS,
                     P_NIVEL,
                     P_PIDM,
                     P_MATRICULA,
                     P_PROGRAMA,
                     P_PERIODO,
                     P_FECHA_INICIO,
                     P_PARTE,
                     VL_ETIQUETA,
                     SYSDATE,
                     SYSDATE,
                     USER,
                     USER,
                     'TZFBECA',
                     'ELIMINADO',
                     1,
                     'SE ELIMINO LA MATRICULA DE LA BASE DE EMPLEADOS'
                      );
         EXCEPTION
         WHEN OTHERS THEN
         VL_ERROR:= 'ERROR AL INSERTAR BITACORA';
         END;

         BEGIN
             SELECT TBBESTU_EXEMPTION_CODE
               INTO VL_DESC_COD
               FROM TBBEXPT, TBBESTU A, TBBDETC, TBREDET
              WHERE     TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                    AND A.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                    AND A.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                    AND A.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                    AND A.TBBESTU_DEL_IND IS NULL
                    AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                    AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                    AND A.TBBESTU_TERM_CODE = (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                                 FROM TBBESTU A1,TBBEXPT,TBREDET
                                                WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                      AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                      AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                      AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                      AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                      AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                      AND A1.TBBESTU_DEL_IND IS NULL
                                                      AND A1.TBBESTU_TERM_CODE <= P_PERIODO)
                    AND A.TBBESTU_EXEMPTION_PRIORITY = (SELECT MAX(TBBESTU_EXEMPTION_PRIORITY)
                                                          FROM TBBESTU A1
                                                         WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                               AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = A.TBBESTU_STUDENT_EXPT_ROLL_IND
                                                               AND A1.TBBESTU_DEL_IND IS NULL
                                                               AND A1.TBBESTU_TERM_CODE = A.TBBESTU_TERM_CODE)
                    AND TBBESTU_PIDM = P_PIDM
                    AND TBBDETC_DCAT_CODE = 'DSP';
         EXCEPTION
         WHEN OTHERS THEN
         VL_DESC_COD:=0;
         END;

         IF EMPLEADO.NIVEL = 'LI' THEN

             BEGIN
               SELECT ZSTPARA_PARAM_VALOR
                 INTO VL_DESCUENTO_COD
                 FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'BECA_EXCOL'
                AND ZSTPARA_PARAM_ID = P_CAMPUS||P_NIVEL||'_'||VL_TIPO||'_'||VL_JORNADA;
             EXCEPTION
             WHEN OTHERS THEN
             VL_DESCUENTO_COD:=0;
             END;

         ELSE
             BEGIN
               SELECT ZSTPARA_PARAM_VALOR
                 INTO VL_DESCUENTO_COD
                 FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'BECA_EXCOL'
                AND ZSTPARA_PARAM_ID = P_CAMPUS||P_NIVEL||'_'||VL_TIPO;
             EXCEPTION
             WHEN OTHERS THEN
             VL_DESCUENTO_COD:=0;
             END;
         END IF;

         IF VL_DESCUENTO_COD != 0 THEN

             BEGIN
               UPDATE TBBESTU
                  SET TBBESTU_EXEMPTION_CODE = VL_DESCUENTO_COD
                WHERE     TBBESTU_PIDM = P_PIDM
                      AND TBBESTU_EXEMPTION_CODE = VL_DESC_COD
                      AND TBBESTU_TERM_CODE>= P_PERIODO;

             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR:= 'NO ACTUALIZA TBB';
             END;

             IF SQL%ROWCOUNT = 0 THEN

                 BEGIN

                    INSERT INTO TBBESTU
                    VALUES(VL_DESCUENTO_COD,
                           P_PIDM,
                           P_PERIODO,
                           SYSDATE,
                           NULL,
                           'Y',
                           NULL,
                           USER,
                           1,
                           NULL,
                           NULL,
                           NULL,
                          'MANU',
                           NULL
                                );

                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_ERROR:= 'ERROR TBB';
                 END;

             END IF;
         END IF;

         BEGIN
           DELETE GORADID
            WHERE GORADID_PIDM = P_PIDM
                  AND GORADID_ADID_CODE = VL_ETIQUETA;
         END;

     ELSIF P_ACCION LIKE 'ELIMINA_SIU_%' THEN  /*    SE ELIMINA REGISTRO DESDE LA PANTALLA DE SIU   */

       IF EMPLEADO.ETIQUETA = 'FUTL' THEN
          VL_ETIQUETA :='FUTL';
          VL_TIPO     :='FAM';
       ELSIF EMPLEADO.ETIQUETA = 'EUTL' THEN
          VL_ETIQUETA :='EUTL';
          VL_TIPO     :='COL';
       ELSIF EMPLEADO.ETIQUETA = 'PRUT' THEN
          VL_ETIQUETA :='PRUT';
          VL_TIPO     :='PUTL';
       ELSIF EMPLEADO.ETIQUETA = 'PRAL' THEN
          VL_ETIQUETA :='PRAL';
          VL_TIPO     :='PALI';
       ELSIF EMPLEADO.ETIQUETA = 'EMOC' THEN
          VL_ETIQUETA :='EMOC';
          VL_TIPO     :='OCC';
       END IF;

       IF VL_BITA = 0 THEN

           BEGIN
                 INSERT
                   INTO TZTBECA
                        (TZTBECA_CAMP,
                         TZTBECA_LEVL,
                         TZTBECA_PIDM,
                         TZTBECA_ID,
                         TZTBECA_PROGRAM,
                         TZTBECA_TERM_CODE,
                         TZTBECA_START_DATE,
                         TZTBECA_PTRM_CODE,
                         TZTBECA_ETIQUETA,
                         TZTBECA_ACTIVITY_DATE,
                         TZTBECA_ACTIVITY_UPDATE,
                         TZTBECA_USER,
                         TZTBECA_USER_UPDATE,
                         TZTBECA_DATA_ORIGIN,
                         TZTBECA_STATUS,
                         TZTBECA_ORDEN,
                         TZTBECA_OBSERVACIONES)
                 VALUES (EMPLEADO.CAMPUS,
                         EMPLEADO.NIVEL,
                         EMPLEADO.PIDM,
                         EMPLEADO.MATRICULA,
                         EMPLEADO.PROGRAMA,
                         EMPLEADO.PERIODO,
                         EMPLEADO.FECHA_INICIO,
                         EMPLEADO.PARTE,
                         VL_ETIQUETA,
                         SYSDATE,
                         SYSDATE,
                         USER,
                         USER,
                         'SIUV2',
                         'ELIMINADO',
                         1,
                         'SE ELIMINO LA MATRICULA DE LA BASE DE EMPLEADOS Y FAMILIARES'
                          );
           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR:= 'ERROR AL INSERTAR BITACORA';
           END;

       ELSE

         BEGIN
           UPDATE TZTBECA
              SET TZTBECA_ACTIVITY_UPDATE = SYSDATE,
                  TZTBECA_USER_UPDATE = USER,
                  TZTBECA_DATA_ORIGIN = 'SIUV2',
                  TZTBECA_OBSERVACIONES = 'SE ELIMINO LA MATRICULA DE LA BASE DE EMPLEADOS Y FAMILIARES'
            WHERE     TZTBECA_PIDM = EMPLEADO.PIDM
                  AND TZTBECA_START_DATE = EMPLEADO.FECHA_INICIO;
         END;

       END IF;

       BEGIN
           SELECT TBBESTU_EXEMPTION_CODE
             INTO VL_DESC_COD
             FROM TBBEXPT, TBBESTU A, TBBDETC, TBREDET
            WHERE     TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                  AND A.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                  AND A.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                  AND A.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                  AND A.TBBESTU_DEL_IND IS NULL
                  AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                  AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                  AND A.TBBESTU_TERM_CODE = (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                               FROM TBBESTU A1,TBBEXPT,TBREDET
                                              WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                    AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                    AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                    AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                    AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                    AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                    AND A1.TBBESTU_DEL_IND IS NULL
                                                    AND A1.TBBESTU_TERM_CODE <= EMPLEADO.PERIODO)
                  AND A.TBBESTU_EXEMPTION_PRIORITY = (SELECT MAX(TBBESTU_EXEMPTION_PRIORITY)
                                                        FROM TBBESTU A1
                                                       WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                             AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = A.TBBESTU_STUDENT_EXPT_ROLL_IND
                                                             AND A1.TBBESTU_DEL_IND IS NULL
                                                             AND A1.TBBESTU_TERM_CODE = A.TBBESTU_TERM_CODE)
                  AND TBBESTU_PIDM = EMPLEADO.PIDM
                  AND TBBDETC_DCAT_CODE = 'DSP';
       EXCEPTION
       WHEN OTHERS THEN
       VL_DESC_COD:=0;
       END;
       --DBMS_OUTPUT.PUT_LINE('ELIMINA 1 = '||VL_DESC_COD);

       IF EMPLEADO.NIVEL = 'LI' THEN

          BEGIN
            SELECT ZSTPARA_PARAM_VALOR
              INTO VL_DESCUENTO_COD
              FROM ZSTPARA
             WHERE ZSTPARA_MAPA_ID = 'BECA_EXCOL'
             AND ZSTPARA_PARAM_ID = EMPLEADO.CAMPUS||EMPLEADO.NIVEL||'_'||VL_TIPO||'_'||VL_JORNADA;
          EXCEPTION
          WHEN OTHERS THEN
          VL_DESCUENTO_COD:=0;
          END;

       ELSE

         BEGIN
           SELECT ZSTPARA_PARAM_VALOR
             INTO VL_DESCUENTO_COD
             FROM ZSTPARA
            WHERE ZSTPARA_MAPA_ID = 'BECA_EXCOL'
            AND ZSTPARA_PARAM_ID = EMPLEADO.CAMPUS||EMPLEADO.NIVEL||'_'||VL_TIPO;
         EXCEPTION
         WHEN OTHERS THEN
         VL_DESCUENTO_COD:=0;
         END;

       END IF;
       --DBMS_OUTPUT.PUT_LINE('ELIMINA 2 = '||VL_DESCUENTO_COD);
       IF VL_DESCUENTO_COD != 0 THEN

           BEGIN
             UPDATE TBBESTU
                SET TBBESTU_EXEMPTION_CODE = VL_DESCUENTO_COD
              WHERE     TBBESTU_PIDM = EMPLEADO.PIDM
                    AND TBBESTU_EXEMPTION_CODE = VL_DESC_COD
                    AND TBBESTU_TERM_CODE>= EMPLEADO.PERIODO;

           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR:= 'NO ACTUALIZA TBB';
           END;

           IF SQL%ROWCOUNT = 0 THEN

               BEGIN

                  INSERT INTO TBBESTU
                  VALUES(VL_DESCUENTO_COD,
                         EMPLEADO.PIDM,
                         EMPLEADO.PERIODO,
                         SYSDATE,
                         NULL,
                         'Y',
                         NULL,
                         USER,
                         1,
                         NULL,
                         NULL,
                         NULL,
                        'BECA',
                         NULL
                              );

               EXCEPTION
               WHEN OTHERS THEN
               VL_ERROR:= 'ERROR TBB';
               END;

           END IF;
       END IF;

       BEGIN
         DELETE GORADID
          WHERE GORADID_PIDM = EMPLEADO.PIDM
                AND GORADID_ADID_CODE = VL_ETIQUETA;
       END;

     ELSIF P_ACCION LIKE 'CREA_SIU_%' THEN /*    SE CREA REGISTRO DESDE SIU ALUMNO CONTINUO  */

       IF EMPLEADO.ETIQUETA = 'FUTL' THEN
          VL_ETIQUETA :='FUTL';
          VL_TIPO     :='FAM';
          VL_COD_ETIQ :='EMPLEADO';
       ELSIF EMPLEADO.ETIQUETA = 'EUTL' THEN
          VL_ETIQUETA :='EUTL';
          VL_TIPO     :='COL';
          VL_COD_ETIQ :='EMPLEADO';
       ELSIF EMPLEADO.ETIQUETA = 'PRUT' THEN
          VL_ETIQUETA :='PRUT';
          VL_TIPO     :='PUTL';
          VL_COD_ETIQ :='PROFEUTL';
       ELSIF EMPLEADO.ETIQUETA = 'PRAL' THEN
          VL_ETIQUETA :='PRAL';
          VL_TIPO     :='PALI';
          VL_COD_ETIQ :='PROFEALI';
       ELSIF EMPLEADO.ETIQUETA = 'EMOC' THEN
          VL_ETIQUETA :='EMOC';
          VL_TIPO     :='OCC';
          VL_COD_ETIQ :='EMPLEOCC';
       END IF;


       IF VL_BITA = 0  THEN
           BEGIN
               INSERT
                 INTO TZTBECA
                      (TZTBECA_CAMP,
                       TZTBECA_LEVL,
                       TZTBECA_PIDM,
                       TZTBECA_ID,
                       TZTBECA_PROGRAM,
                       TZTBECA_TERM_CODE,
                       TZTBECA_START_DATE,
                       TZTBECA_PTRM_CODE,
                       TZTBECA_ETIQUETA,
                       TZTBECA_ACTIVITY_DATE,
                       TZTBECA_ACTIVITY_UPDATE,
                       TZTBECA_USER,
                       TZTBECA_USER_UPDATE,
                       TZTBECA_DATA_ORIGIN,
                       TZTBECA_STATUS,
                       TZTBECA_ORDEN,
                       TZTBECA_OBSERVACIONES)
               VALUES (EMPLEADO.CAMPUS,
                       EMPLEADO.NIVEL,
                       EMPLEADO.PIDM,
                       EMPLEADO.MATRICULA,
                       EMPLEADO.PROGRAMA,
                       EMPLEADO.PERIODO,
                       EMPLEADO.FECHA_INICIO,
                       EMPLEADO.PARTE,
                       VL_ETIQUETA,
                       SYSDATE,
                       SYSDATE,
                       USER,
                       USER,
                       'SIUV2',
                       'CONTINUO',
                       0,
                       'SE DA DE ALTA A '||VL_ETIQUETA
                        );
           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR:= 'ERROR AL INSERTAR BITACORA';
           END;

       ELSE

         BEGIN
           UPDATE TZTBECA
              SET TZTBECA_ACTIVITY_UPDATE = SYSDATE,
                  TZTBECA_USER_UPDATE = USER,
                  TZTBECA_DATA_ORIGIN = 'SIUV2',
                  TZTBECA_OBSERVACIONES = 'SE DA DE ALTA A '||VL_ETIQUETA
            WHERE     TZTBECA_PIDM = EMPLEADO.PIDM
                  AND TZTBECA_START_DATE = EMPLEADO.FECHA_INICIO;
         END;

       END IF;

       BEGIN
           SELECT TBBESTU_EXEMPTION_CODE
             INTO VL_DESC_COD
             FROM TBBEXPT, TBBESTU A, TBBDETC, TBREDET
            WHERE     TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                  AND A.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                  AND A.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                  AND A.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                  AND A.TBBESTU_DEL_IND IS NULL
                  AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                  AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                  AND A.TBBESTU_TERM_CODE = (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                               FROM TBBESTU A1,TBBEXPT,TBREDET
                                              WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                    AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                    AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                    AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                    AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                    AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                    AND A1.TBBESTU_DEL_IND IS NULL
                                                    AND A1.TBBESTU_TERM_CODE <= EMPLEADO.PERIODO)
                  AND A.TBBESTU_EXEMPTION_PRIORITY = (SELECT MAX(TBBESTU_EXEMPTION_PRIORITY)
                                                        FROM TBBESTU A1
                                                       WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                             AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = A.TBBESTU_STUDENT_EXPT_ROLL_IND
                                                             AND A1.TBBESTU_DEL_IND IS NULL
                                                             AND A1.TBBESTU_TERM_CODE = A.TBBESTU_TERM_CODE)
                  AND TBBESTU_PIDM = EMPLEADO.PIDM
                  AND TBBDETC_DCAT_CODE = 'DSP';
       EXCEPTION
       WHEN OTHERS THEN
       VL_DESC_COD:=0;
       END;
       --DBMS_OUTPUT.PUT_LINE('CREA 1 = '||VL_DESC_COD);
       BEGIN
         SELECT ZSTPARA_PARAM_VALOR
           INTO VL_DESCUENTO_COD
           FROM ZSTPARA
          WHERE ZSTPARA_MAPA_ID = 'BECA_EXCOL'
            AND ZSTPARA_PARAM_ID = EMPLEADO.CAMPUS||EMPLEADO.NIVEL||'_'||VL_COD_ETIQ;
       EXCEPTION
       WHEN OTHERS THEN
       VL_DESCUENTO_COD:=0;
       END;
       --DBMS_OUTPUT.PUT_LINE('CREA 2 = '||VL_DESCUENTO_COD);
       IF VL_DESCUENTO_COD != 0 THEN

           BEGIN
             UPDATE TBBESTU
                SET TBBESTU_EXEMPTION_CODE = VL_DESCUENTO_COD
              WHERE     TBBESTU_PIDM = EMPLEADO.PIDM
                    AND TBBESTU_EXEMPTION_CODE = VL_DESC_COD
                    AND TBBESTU_TERM_CODE = EMPLEADO.PERIODO;

           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR:= 'NO ACTUALIZA TBB';
           END;

           IF SQL%ROWCOUNT = 0 THEN

               BEGIN

                  INSERT INTO TBBESTU
                  VALUES(VL_DESCUENTO_COD,
                         EMPLEADO.PIDM,
                         EMPLEADO.PERIODO,
                         SYSDATE,
                         NULL,
                         'Y',
                         NULL,
                         USER,
                         1,
                         NULL,
                         NULL,
                         NULL,
                        'BECA',
                         NULL
                              );

               EXCEPTION
               WHEN OTHERS THEN
               VL_ERROR:= 'ERROR TBB';
               END;

           END IF;
       END IF;
       --DBMS_OUTPUT.PUT_LINE('CREA 3 = '||VL_ERROR);
     ELSIF P_ACCION = 'ACTUALIZA' THEN DBMS_OUTPUT.PUT_LINE('EMPIEZA'); /*    SE ELIMINA REGISTRO DESDE LA FORMA PESTAÑA HISTORICO */

         BEGIN
             SELECT TBBESTU_EXEMPTION_CODE
               INTO VL_DESC_COD
               FROM TBBEXPT, TBBESTU A, TBBDETC, TBREDET
              WHERE     TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                    AND A.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                    AND A.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                    AND A.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                    AND A.TBBESTU_DEL_IND IS NULL
                    AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                    AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                    AND A.TBBESTU_TERM_CODE = (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                                 FROM TBBESTU A1,TBBEXPT,TBREDET
                                                WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                      AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                      AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                      AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                      AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                      AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                      AND A1.TBBESTU_DEL_IND IS NULL
                                                      AND A1.TBBESTU_TERM_CODE <= P_PERIODO)
                    AND A.TBBESTU_EXEMPTION_PRIORITY = (SELECT MAX(TBBESTU_EXEMPTION_PRIORITY)
                                                          FROM TBBESTU A1
                                                         WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                               AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = A.TBBESTU_STUDENT_EXPT_ROLL_IND
                                                               AND A1.TBBESTU_DEL_IND IS NULL
                                                               AND A1.TBBESTU_TERM_CODE = A.TBBESTU_TERM_CODE)
                    AND TBBESTU_PIDM = P_PIDM
                    AND TBBDETC_DCAT_CODE = 'DSP';
         EXCEPTION
         WHEN OTHERS THEN
         VL_DESC_COD:=0;
         END;

        -- DBMS_OUTPUT.PUT_LINE('EMPIEZA 2 '||VL_DESC_COD);

          IF EMPLEADO.ETIQUETA = 'FUTL' THEN
            VL_ETIQUETA :='FUTL';
            VL_TIPO     :='FAM';
         ELSIF EMPLEADO.ETIQUETA = 'EUTL' THEN
            VL_ETIQUETA :='EUTL';
            VL_TIPO     :='COL';
         ELSIF EMPLEADO.ETIQUETA = 'PRUT' THEN
            VL_ETIQUETA :='PRUT';
            VL_TIPO     :='PUTL';
         ELSIF EMPLEADO.ETIQUETA = 'PRAL' THEN
            VL_ETIQUETA :='PRAL';
            VL_TIPO     :='PALI';
         ELSIF EMPLEADO.ETIQUETA = 'EMOC' THEN
            VL_ETIQUETA :='EMOC';
            VL_TIPO     :='OCC';
         END IF;

         IF EMPLEADO.NIVEL = 'LI' THEN

             BEGIN
               SELECT ZSTPARA_PARAM_VALOR
                 INTO VL_DESCUENTO_COD
                 FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'BECA_EXCOL'
                AND ZSTPARA_PARAM_ID = P_CAMPUS||P_NIVEL||'_'||VL_TIPO||'_'||VL_JORNADA;
             EXCEPTION
             WHEN OTHERS THEN
             VL_DESCUENTO_COD:=0;
             END;

         ELSE
             BEGIN
               SELECT ZSTPARA_PARAM_VALOR
                 INTO VL_DESCUENTO_COD
                 FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'BECA_EXCOL'
                AND ZSTPARA_PARAM_ID = P_CAMPUS||P_NIVEL||'_'||VL_TIPO;
             EXCEPTION
             WHEN OTHERS THEN
             VL_DESCUENTO_COD:=0;
             END;
         END IF;
         --DBMS_OUTPUT.PUT_LINE('EMPIEZA 3 '||VL_DESCUENTO_COD);
         IF VL_DESCUENTO_COD IS NOT NULL THEN

             BEGIN
               UPDATE TBBESTU
                  SET TBBESTU_EXEMPTION_CODE = VL_DESCUENTO_COD
                WHERE     TBBESTU_PIDM = P_PIDM
                      AND TBBESTU_EXEMPTION_CODE = VL_DESC_COD
                      AND TBBESTU_TERM_CODE = P_PERIODO;

             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR:= 'NO ACTUALIZA TBB';
             END;

             IF SQL%ROWCOUNT = 0 THEN

                 BEGIN

                    INSERT INTO TBBESTU
                    VALUES(VL_DESCUENTO_COD,
                           P_PIDM,
                           P_PERIODO,
                           SYSDATE,
                           NULL,
                           'Y',
                           NULL,
                           USER,
                           1,
                           NULL,
                           NULL,
                           NULL,
                          'MANU',
                           NULL
                                );

                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_ERROR:= 'ERROR TBB';
                 END;

             END IF;
         END IF;
         --DBMS_OUTPUT.PUT_LINE('EMPIEZA 4 '||VL_ERROR||' = '||P_PIDM);
         BEGIN
           DELETE GORADID
            WHERE GORADID_PIDM = P_PIDM
                  AND GORADID_ADID_CODE = VL_ETIQUETA;
         END;

     END IF;
   END LOOP;
    COMMIT;
  RETURN(VL_ERROR);
 END F_CYE_EMPLEADO;

FUNCTION F_COMPLEMENTO ( P_CAMPUS         VARCHAR2,
                         P_NIVEL          VARCHAR2,
                         P_PIDM           NUMBER,
                         P_PERIODO        VARCHAR2,
                         P_PROGRAMA       VARCHAR2,
                         P_STUDY_PATH     NUMBER                         
                         ) RETURN VARCHAR2 IS

/* SE AGREGA AJUSTE PARA EXCLUIR A LOS ALUMNOS DE ESPAÑA
  Y PARA CALCULAR CORRECTAMENTE CUANDO CAMBIA DE STUDY
  ** SE AGREGA CALCULO PARA ALUMNOS IZZI
  ACTUALIZADO 22/10/2021 JREZAOLI
  */

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

 BEGIN

   BEGIN
     Select count(*)
        Into VL_ENTRA
     from TZTINC  
     Where campus = P_CAMPUS
     And nivel = P_NIVEL;
   EXCEPTION
   WHEN OTHERS THEN
    VL_ENTRA:=0;
   END;

   --- DBMS_OUTPUT.PUT_LINE('VL_ENTRA '||VL_ENTRA);

   IF VL_ENTRA > 0 THEN
      


     BEGIN
       SELECT TRUNC(SARADAP_APPL_DATE)
         INTO VL_FECHA_SOLI
         FROM SARADAP A
        WHERE     A.SARADAP_PIDM = P_PIDM
              AND A.SARADAP_CAMP_CODE||A.SARADAP_LEVL_CODE = P_CAMPUS||P_NIVEL
              AND A.SARADAP_APST_CODE = 'A'
              AND A.SARADAP_APPL_NO = (SELECT MAX(SARADAP_APPL_NO)
                                         FROM SARADAP
                                        WHERE     SARADAP_PIDM = A.SARADAP_PIDM
                                              AND SARADAP_CAMP_CODE||SARADAP_LEVL_CODE = P_CAMPUS||P_NIVEL
                                              AND SARADAP_APST_CODE = 'A');
     EXCEPTION
     WHEN OTHERS THEN
     VL_FECHA_SOLI:=TO_DATE('01/01/2011','DD/MM/YYYY');
     END;

   -- DBMS_OUTPUT.PUT_LINE('VL_FECHA_SOLI '||VL_FECHA_SOLI);

    Begin    
        Select max (x.fecha)
            Into VL_FECHA_PARA
        from (
             Select max(FECHA_SOLICITUD) Fecha, CODIGO, costo, vigencia
             from TZTINC  
             Where campus = P_CAMPUS
             And nivel = P_NIVEL
             And  TRUNC(VL_FECHA_SOLI) >= trunc (FECHA_SOLICITUD)
             group by CODIGO, costo, vigencia 
            ) x;
    Exception
        when no_Data_found then
            VL_FECHA_PARA:= null;
        When Others then 
            VL_FECHA_PARA:= null;        
    End;


    --DBMS_OUTPUT.PUT_LINE('VL_FECHA_PARA '||VL_FECHA_PARA);

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

    --- DBMS_OUTPUT.PUT_LINE('VL_IZZI '||VL_IZZI);

         IF VL_IZZI > 0 THEN
         
           -- DBMS_OUTPUT.PUT_LINE('ENTRA a IZZI '||VL_IZZI);


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
           -- DBMS_OUTPUT.PUT_LINE('ENTRA al NO Excluido ');
            vl_existe_inco:=0;

           IF VL_FECHA_PARA Is not null  THEN
           
             --DBMS_OUTPUT.PUT_LINE('ENTRA fecha Solicitud y Fecha Para ');
                VL_CODIGO:= null;
                VL_DESCRIP:= null;
                VL_MONTO:= null;
                vl_vigencia := null;             

             BEGIN
                     Select CODIGO, TBBDETC_DESC, costo , VIGENCIA
                        INTO VL_CODIGO,VL_DESCRIP,VL_MONTO, vl_vigencia
                     from TZTINC, tbbdetc  
                     Where 1=1
                     And CODIGO = tbbdetc_detail_code
                     And campus = P_CAMPUS
                     And nivel =  P_NIVEL
                     And TRUNC (FECHA_SOLICITUD) = VL_FECHA_PARA;
             EXCEPTION
             WHEN OTHERS THEN
                 VL_ERROR:='ERROR AL CALCULAR CODIGO';
                 VL_CODIGO:= null;
                 VL_DESCRIP:= null;
                 VL_MONTO:= null;
                 vl_vigencia := null;
             END;

             IF VL_ERROR IS NULL and VL_CODIGO is not null and VL_DESCRIP is not null and VL_MONTO is not null THEN
               --DBMS_OUTPUT.PUT_LINE('LLega a insertar complemento en FACCE  = '||VL_MONTO||'='||VL_CODIGO||'='||VL_DESCRIP||'='||vl_vigencia);
               PKG_FINANZAS.P_INSERTA_COMPLE ( P_PIDM,
                                               P_PERIODO,
                                               VL_MONTO,
                                               VL_CODIGO,
                                               VL_DESCRIP,
                                               1,
                                               vl_vigencia,
                                               P_PROGRAMA,
                                               P_STUDY_PATH);

             END IF;

           END IF;
         END IF;
   END IF;
  COMMIT;
 RETURN(VL_ERROR);
 END F_COMPLEMENTO;


FUNCTION F_ACTUALIZA_RATE_DSI ( P_MATRICULA VARCHAR2,
                                P_FECHA     DATE)RETURN VARCHAR2 IS

VL_FECHA_APLICACION     DATE;
VL_RATE                 NUMBER;
VL_DSI_ACTU             NUMBER;
VL_CODIGO               VARCHAR2(4);
VL_DESCRIPCION          VARCHAR2(40);
VL_ERROR                VARCHAR2(900);
VL_SYUDY                VARCHAR2(900);

 BEGIN
   /*  ACTUALIZA EL STUDY CORRECTO EN LA TABLA DE TZTDMTO  */
   VL_SYUDY:= PKG_FINANZAS_REZA.F_ACTUALIZA_STUDY ( P_FECHA);

   FOR RATE IN (
                SELECT DISTINCT
                       SORLCUR_CAMP_CODE CAMPUS,
                       SORLCUR_LEVL_CODE NIVEL,
                       SPRIDEN_ID MATRICULA,
                       SORLCUR_PIDM PIDM,
                       SFRSTCR_TERM_CODE PERIODO,
                       SFRSTCR_PTRM_CODE PARTE,
                       SORLCUR_PROGRAM PROGRAMA,
                       SORLCUR_KEY_SEQNO STUDY,
                       SORLCUR_RATE_CODE RATE,
                       SUBSTR(SORLCUR_RATE_CODE,3,1) PAGOS,
                       SSBSECT_PTRM_START_DATE FECHA,
                       TO_NUMBER(TO_CHAR(SSBSECT_PTRM_START_DATE,'DD')) DIA,
                       TO_NUMBER(TO_CHAR(SSBSECT_PTRM_START_DATE,'MM')) MES,
                       TO_NUMBER(TO_CHAR(SSBSECT_PTRM_START_DATE,'YYYY')) ANO,
                       (SELECT DISTINCT TZTDMTO_MONTO
                          FROM TZTDMTO A
                         WHERE     A.TZTDMTO_PIDM   = A.SORLCUR_PIDM
                               AND A.TZTDMTO_CAMP_CODE = A.SORLCUR_CAMP_CODE
                               AND A.TZTDMTO_NIVEL  = A.SORLCUR_LEVL_CODE
                               AND A.TZTDMTO_PROGRAMA =  A.SORLCUR_PROGRAM
                               AND A.TZTDMTO_IND = 1
                               AND A.TZTDMTO_STUDY_PATH = A.SORLCUR_KEY_SEQNO
                               AND (   A.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                                    OR A.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                FROM TZTDMTO TZT
                                                               WHERE     TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                     AND TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                     AND TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                     AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                     AND TZT.TZTDMTO_IND = 1
                                                                     AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                     AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE))
                               AND A.TZTDMTO_ACTIVITY_DATE = (SELECT MAX (A1.TZTDMTO_ACTIVITY_DATE)
                                                                FROM TZTDMTO A1
                                                               WHERE     A1.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                     AND A1.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                     AND A1.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                     AND A1.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                     AND A1.TZTDMTO_IND = 1
                                                                     AND A1.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                     AND (   A1.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                                                                          OR A1.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                                                       FROM TZTDMTO TZT
                                                                                                      WHERE     TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                                                            AND TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                                                            AND TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                                                            AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                                                            AND TZT.TZTDMTO_IND = 1
                                                                                                            AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                                                            AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE)))
                               AND A.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE
                               AND ROWNUM = 1)MONTO_DSI
                  FROM SORLCUR A,
                       SPRIDEN D,
                       SFRSTCR F,
                       SSBSECT G,
                       SGBSTDN N
                 WHERE     A.SORLCUR_PIDM = D.SPRIDEN_PIDM
                       AND D.SPRIDEN_CHANGE_IND IS NULL
                       AND N.SGBSTDN_PIDM = A.SORLCUR_PIDM
                       AND N.SGBSTDN_TERM_CODE_EFF IN (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                                                        FROM SGBSTDN
                                                       WHERE SGBSTDN_PIDM = N.SGBSTDN_PIDM)
                       AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                       AND A.SORLCUR_ROLL_IND  = 'Y'
                       AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                       AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                 FROM SORLCUR A1
                                                WHERE     A1.SORLCUR_PIDM      = A.SORLCUR_PIDM
                                                      AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                                      AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                                      AND A1.SORLCUR_PROGRAM   = A.SORLCUR_PROGRAM
                                                      AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
                       AND F.SFRSTCR_PIDM = A.SORLCUR_PIDM
                       AND F.SFRSTCR_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                       AND F.SFRSTCR_TERM_CODE = G.SSBSECT_TERM_CODE
                       AND F.SFRSTCR_CRN = G.SSBSECT_CRN
                       AND F.SFRSTCR_PTRM_CODE = G.SSBSECT_PTRM_CODE
                       AND A.SORLCUR_START_DATE = G.SSBSECT_PTRM_START_DATE
                       AND SUBSTR(F.SFRSTCR_TERM_CODE,5,1) NOT IN (8,9)
                       AND F.SFRSTCR_RSTS_CODE = 'RE'
                       AND (F.SFRSTCR_RESERVED_KEY NOT IN ('M1HB401','CP001','CPB13001') OR SFRSTCR_RESERVED_KEY IS NULL )
                       AND (F.SFRSTCR_DATA_ORIGIN  != 'CONVALIDACION' OR F.SFRSTCR_DATA_ORIGIN IS NULL)
                       AND (F.SFRSTCR_DATA_ORIGIN  != 'EXCLUIR'       OR SFRSTCR_DATA_ORIGIN IS NULL)
                       AND (F.SFRSTCR_USER_ID      != 'MIGRA_D'       OR F.SFRSTCR_USER_ID IS NULL)
                       AND A.SORLCUR_CAMP_CODE||A.SORLCUR_LEVL_CODE IN (SELECT ZSTPARA_PARAM_ID
                                                                          FROM ZSTPARA
                                                                         WHERE ZSTPARA_MAPA_ID = 'CAMPUS_RATE')
                       AND SUBSTR(SORLCUR_RATE_CODE,1,1) = 'J'
                       AND SUBSTR(SORLCUR_RATE_CODE,3,1) != 1
                       AND SUBSTR(SORLCUR_RATE_CODE,3,1) != (SELECT ZSTPARA_PARAM_VALOR
                                                               FROM ZSTPARA
                                                              WHERE     ZSTPARA_MAPA_ID = 'CALCULO_RATE'
                                                                    AND TO_NUMBER(ZSTPARA_PARAM_ID) = TO_CHAR(TO_DATE(G.SSBSECT_PTRM_START_DATE)+12,'MM'))
                       AND A.SORLCUR_START_DATE  = P_FECHA
                       AND D.SPRIDEN_ID               = NVL(P_MATRICULA,D.SPRIDEN_ID)

   )LOOP

     VL_FECHA_APLICACION    :=NULL;
     VL_RATE                :=NULL;
     VL_DSI_ACTU            :=NULL;
     VL_CODIGO              :=NULL;
     VL_DESCRIPCION         :=NULL;
     VL_ERROR               :=NULL;

     IF RATE.DIA >= 20 THEN
       VL_FECHA_APLICACION:= ADD_MONTHS(RATE.FECHA,1);
     ELSE
       VL_FECHA_APLICACION:= RATE.FECHA;
     END IF;

     BEGIN
       SELECT ZSTPARA_PARAM_VALOR
         INTO VL_RATE
         FROM ZSTPARA
        WHERE     ZSTPARA_MAPA_ID = 'CALCULO_RATE'
              AND TO_NUMBER(ZSTPARA_PARAM_ID) = TO_CHAR(VL_FECHA_APLICACION,'MM');
     EXCEPTION
     WHEN OTHERS THEN
     VL_RATE := NULL;
     END;

     IF VL_RATE != RATE.PAGOS THEN

        /* SE ACTUALIZA DSI CUANDO EL NUMERO DE PAGOS NO COINCIDE CON EL RATE  */

       IF (RATE.MONTO_DSI IS NULL OR RATE.MONTO_DSI = 0)THEN
         VL_ERROR:= 'EXITO';
       ELSE

         VL_ERROR:= 'EXITO';

         VL_DSI_ACTU:= (RATE.MONTO_DSI/RATE.PAGOS);
         VL_DSI_ACTU:= ROUND((RATE.MONTO_DSI/RATE.PAGOS),1);
         VL_DSI_ACTU:= VL_DSI_ACTU*VL_RATE;

         BEGIN
              UPDATE TZTDMTO A
                 SET A.TZTDMTO_MONTO = VL_DSI_ACTU,
                     A.TZTDMTO_IND = 1,
                     A.TZTDMTO_STUDY_PATH = RATE.STUDY
               WHERE     A.TZTDMTO_ID         = RATE.MATRICULA
                     AND A.TZTDMTO_NIVEL      = RATE.NIVEL
                     AND A.TZTDMTO_CAMP_CODE  = RATE.CAMPUS
                     AND A.TZTDMTO_PROGRAMA   = RATE.PROGRAMA
                     AND A.TZTDMTO_TERM_CODE  = RATE.PERIODO;
         END;

         IF SQL%ROWCOUNT = 0 THEN

           BEGIN
             SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC
               INTO VL_CODIGO,VL_DESCRIPCION
             FROM TBBDETC
             WHERE TBBDETC_DETAIL_CODE = SUBSTR(RATE.MATRICULA,1,2)||'GA';
           END;

           BEGIN
             INSERT
               INTO TZTDMTO
             VALUES ( RATE.MATRICULA,
                      RATE.PIDM,
                      RATE.CAMPUS,
                      RATE.NIVEL,
                      RATE.PROGRAMA,
                      RATE.PERIODO,
                      VL_CODIGO,
                      NULL,
                      VL_DSI_ACTU,
                      RATE.STUDY,
                      1,
                      SYSDATE,
                      VL_DESCRIPCION,
                      null);
           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR:= 'ERROR AL INSERTAR EN TZTDMTO  '||SQLERRM;
           END;

         END IF;

       END IF;
         /* SE ACTUALIZA RATE CUANDO EL NUMERO DE PAGOS NO COINCIDE CON EL RATE  */

       BEGIN
         UPDATE SORLCUR A
            SET SORLCUR_RATE_CODE = SUBSTR(RATE.RATE,1,2)||VL_RATE||SUBSTR(RATE.RATE,4,2)
          WHERE     A.SORLCUR_LMOD_CODE = 'LEARNER'
                AND A.SORLCUR_ROLL_IND  = 'Y'
                AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                AND A.SORLCUR_PIDM = RATE.PIDM
                AND A.SORLCUR_KEY_SEQNO = RATE.STUDY
                AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                          FROM SORLCUR A1
                                         WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                               AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                               AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                               AND A1.SORLCUR_KEY_SEQNO = RATE.STUDY
                                               AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE);
       END;

       BEGIN
         UPDATE SGBSTDN B
            SET SGBSTDN_RATE_CODE = SUBSTR(RATE.RATE,1,2)||VL_RATE||SUBSTR(RATE.RATE,4,2)
          WHERE     B.SGBSTDN_PIDM = RATE.PIDM
                AND B.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                 FROM SGBSTDN A1
                                                 WHERE A1.SGBSTDN_PIDM = B.SGBSTDN_PIDM);
       END;

       --DBMS_OUTPUT.PUT_LINE('CAMBIO DE RATE EXITO = '||RATE.MATRICULA);

     END IF;

   END LOOP;
  COMMIT;
 RETURN(VL_ERROR);
 END F_ACTUALIZA_RATE_DSI;

FUNCTION F_ACTUALIZA_STUDY ( P_FECHA DATE)RETURN VARCHAR2 IS

VL_ERROR        VARCHAR2(500);

 BEGIN
   FOR STUDY IN (
                SELECT DISTINCT
                       SORLCUR_CAMP_CODE CAMPUS,
                       SORLCUR_LEVL_CODE NIVEL,
                       SPRIDEN_ID MATRICULA,
                       SORLCUR_PIDM PIDM,
                       SFRSTCR_TERM_CODE PERIODO,
                       SFRSTCR_PTRM_CODE PARTE,
                       SORLCUR_PROGRAM PROGRAMA,
                       SORLCUR_KEY_SEQNO STUDY
                  FROM SORLCUR A,
                       SPRIDEN D,
                       SFRSTCR F,
                       SSBSECT G,
                       SGBSTDN N
                 WHERE     A.SORLCUR_PIDM = D.SPRIDEN_PIDM
                       AND D.SPRIDEN_CHANGE_IND IS NULL
                       AND N.SGBSTDN_PIDM = A.SORLCUR_PIDM
                       AND N.SGBSTDN_TERM_CODE_EFF IN (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                                                        FROM SGBSTDN
                                                       WHERE SGBSTDN_PIDM = N.SGBSTDN_PIDM)
                       AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                       AND A.SORLCUR_ROLL_IND  = 'Y'
                       AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                       AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                 FROM SORLCUR A1
                                                WHERE     A1.SORLCUR_PIDM      = A.SORLCUR_PIDM
                                                      AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                                      AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                                      AND A1.SORLCUR_PROGRAM   = A.SORLCUR_PROGRAM
                                                      AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
                       AND F.SFRSTCR_PIDM = A.SORLCUR_PIDM
                       AND F.SFRSTCR_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                       AND F.SFRSTCR_TERM_CODE = G.SSBSECT_TERM_CODE
                       AND F.SFRSTCR_CRN = G.SSBSECT_CRN
                       AND F.SFRSTCR_PTRM_CODE = G.SSBSECT_PTRM_CODE
                       AND SUBSTR(F.SFRSTCR_TERM_CODE,5,1) NOT IN (8,9)
                       AND F.SFRSTCR_RSTS_CODE = 'RE'
                       AND (F.SFRSTCR_RESERVED_KEY NOT IN ('M1HB401','CP001','CPB13001') OR SFRSTCR_RESERVED_KEY IS NULL )
                       AND (F.SFRSTCR_DATA_ORIGIN  != 'CONVALIDACION' OR F.SFRSTCR_DATA_ORIGIN IS NULL)
                       AND (F.SFRSTCR_DATA_ORIGIN  != 'EXCLUIR'       OR SFRSTCR_DATA_ORIGIN IS NULL)
                       AND (F.SFRSTCR_USER_ID      != 'MIGRA_D'       OR F.SFRSTCR_USER_ID IS NULL)
                       AND SUBSTR(SORLCUR_RATE_CODE,1,1) = 'J'
                       AND (SELECT COUNT(*)
                              FROM TZTDMTO
                             WHERE     TZTDMTO_ID = D.SPRIDEN_ID
                                   AND TZTDMTO_PROGRAMA = A.SORLCUR_PROGRAM
                                   AND TZTDMTO_STUDY_PATH != SORLCUR_KEY_SEQNO)>0
                       AND EXISTS (SELECT TZTDMTO_PIDM
                                     FROM TZTDMTO
                                    WHERE TZTDMTO_ID = D.SPRIDEN_ID)
                       AND A.SORLCUR_START_DATE  = P_FECHA
   )LOOP

     BEGIN
        UPDATE TZTDMTO
           SET TZTDMTO_STUDY_PATH =  STUDY.STUDY
         WHERE    TZTDMTO_ID = STUDY.MATRICULA
              AND TZTDMTO_TERM_CODE = STUDY.PERIODO
              AND TZTDMTO_PROGRAMA = STUDY.PROGRAMA;
     EXCEPTION
     WHEN OTHERS THEN
     NULL;
     END;

   END LOOP;

  COMMIT;
  RETURN(VL_ERROR);

 END F_ACTUALIZA_STUDY;

FUNCTION F_AJ_CAN_BECA(P_PIDM NUMBER,
                       P_TRAN NUMBER,
                       P_FECHA DATE,
                       P_PROCESO VARCHAR2)RETURN VARCHAR2 IS

VL_AP_AJUSTE    VARCHAR2(500);
VL_ENTRA        NUMBER;
VL_TRANS        NUMBER;
VL_CODIGO       VARCHAR2(4);
VL_DESCRIP      VARCHAR2(40);
VL_MONTO        NUMBER;
VL_PERIODO      VARCHAR2(11);
VL_PARTE        VARCHAR2(4);
VL_FECHA        DATE;
VL_STUDY        NUMBER;
VL_ERROR        VARCHAR2(900);
VL_AJUSTA       NUMBER;
VL_CAMPUS       VARCHAR2(4);
VL_NIVEL        VARCHAR2(4);
VL_PROGRAMA     VARCHAR2(14);
VL_APL_BECA     VARCHAR2(500);

BEGIN

  IF P_PROCESO = 'CANCELACION' THEN
      BEGIN
        SELECT COUNT(*)
          INTO VL_ENTRA
          FROM TBRACCD
         WHERE TBRACCD_PIDM = P_PIDM
         AND TBRACCD_TRAN_NUMBER_PAID = P_TRAN
         AND SUBSTR(TBRACCD_DETAIL_CODE,3,2) IN (SELECT ZSTPARA_PARAM_ID
                                                   FROM ZSTPARA
                                                  WHERE ZSTPARA_MAPA_ID = 'AJ_CAN_BECA');
      END;

      IF VL_ENTRA > 0 THEN

        BEGIN
          SELECT TBRACCD_TRAN_NUMBER,
                 SUBSTR(TBRACCD_TERM_CODE,1,2)||ZSTPARA_PARAM_VALOR COD_AJUSTE,
                 TBBDETC_DESC,
                 TBRACCD_AMOUNT,
                 TBRACCD_TERM_CODE,
                 TBRACCD_PERIOD,
                 TBRACCD_FEED_DATE,
                 TBRACCD_STSP_KEY_SEQUENCE
            INTO VL_TRANS,
                 VL_CODIGO,
                 VL_DESCRIP,
                 VL_MONTO,
                 VL_PERIODO,
                 VL_PARTE,
                 VL_FECHA,
                 VL_STUDY
            FROM TBRACCD,ZSTPARA,TBBDETC
           WHERE     SUBSTR(TBRACCD_TERM_CODE,1,2)||ZSTPARA_PARAM_VALOR = TBBDETC_DETAIL_CODE
                 AND TBRACCD_PIDM = P_PIDM
                 AND TBRACCD_TRAN_NUMBER_PAID = P_TRAN
                 AND SUBSTR(TBRACCD_DETAIL_CODE,3,2) = ZSTPARA_PARAM_ID
                 AND ZSTPARA_MAPA_ID = 'AJ_CAN_BECA';
        EXCEPTION
        WHEN OTHERS THEN
        VL_ERROR:= 'ERROR AL RECUPERAR VARIABLES = '||SQLERRM;
        END;

        IF VL_ERROR IS NULL THEN

          BEGIN
          PKG_FINANZAS.P_DESAPLICA_PAGOS (P_PIDM, P_TRAN) ;
          END;

          BEGIN
            VL_AP_AJUSTE:= PKG_FINANZAS.SP_APLICA_AJUSTE (P_PIDM,
                                                          VL_TRANS,
                                                          VL_CODIGO,
                                                          VL_MONTO,
                                                          VL_PERIODO,
                                                          VL_DESCRIP,
                                                          SYSDATE,
                                                          VL_STUDY,
                                                          VL_FECHA,
                                                          VL_PARTE,
                                                          USER);
          END;
        END IF;

        BEGIN
          UPDATE TBRACCD
             SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
           WHERE TBRACCD_PIDM = P_PIDM
           AND TBRACCD_TRAN_NUMBER = VL_TRANS;

           UPDATE TVRACCD
             SET TVRACCD_DOCUMENT_NUMBER = 'SZFABCC'
           WHERE TVRACCD_PIDM = P_PIDM
           AND TVRACCD_ACCD_TRAN_NUMBER = VL_TRANS;
        END;

        BEGIN
          UPDATE TBRACCD
             SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
           WHERE TBRACCD_PIDM = P_PIDM
           AND TBRACCD_DETAIL_CODE = VL_CODIGO
           AND TRUNC(TBRACCD_EFFECTIVE_DATE) = TRUNC(SYSDATE);

           UPDATE TVRACCD
             SET TVRACCD_DOCUMENT_NUMBER = 'SZFABCC'
           WHERE TVRACCD_PIDM = P_PIDM
           AND TVRACCD_DETAIL_CODE = VL_CODIGO
           AND TRUNC(TVRACCD_EFFECTIVE_DATE) = TRUNC(SYSDATE);

        END;

        BEGIN
          UPDATE TZTBECA
             SET TZTBECA_OBSERVACIONES = 'ELIMINADO PARA REPROCESO'
           WHERE     TZTBECA_PIDM = P_PIDM
                 AND TZTBECA_START_DATE = P_FECHA
                 AND TZTBECA_ETIQUETA = 'EUTL'
                 AND TZTBECA_OBSERVACIONES = 'AJUSTES APLICADOS CORRECTAMENTE';
        END;

      END IF;

  ELSIF P_PROCESO = 'BECA' THEN

    BEGIN
      SELECT COUNT(*)
        INTO VL_AJUSTA
        FROM TZTBECA
       WHERE TZTBECA_PIDM = P_PIDM
       AND TZTBECA_START_DATE = P_FECHA
       AND TZTBECA_ETIQUETA = 'EUTL'
       AND TZTBECA_OBSERVACIONES = 'ELIMINADO PARA REPROCESO';
    EXCEPTION
    WHEN OTHERS THEN
    NULL;
    END;

    IF VL_AJUSTA > 0 THEN

      BEGIN
        SELECT SORLCUR_CAMP_CODE,SORLCUR_LEVL_CODE,SORLCUR_PROGRAM
          INTO VL_CAMPUS,VL_NIVEL,VL_PROGRAMA
          FROM SORLCUR A, SFRSTCR F, SSBSECT G
         WHERE     A.SORLCUR_LMOD_CODE = 'LEARNER'
               AND A.SORLCUR_ROLL_IND  = 'Y'
               AND A.SORLCUR_CACT_CODE = 'ACTIVE'
               AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                     FROM SORLCUR A1
                                     WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                     AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                     AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                     AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                     AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
               AND F.SFRSTCR_PIDM = A.SORLCUR_PIDM
               AND F.SFRSTCR_RSTS_CODE = 'RE'
               AND F.SFRSTCR_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
               AND F.SFRSTCR_TERM_CODE = G.SSBSECT_TERM_CODE
               AND SUBSTR(F.SFRSTCR_TERM_CODE,5,1) NOT IN (8,9)
               AND (F.SFRSTCR_RESERVED_KEY != 'M1HB401' OR SFRSTCR_RESERVED_KEY IS NULL )
               AND (F.SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR F.SFRSTCR_DATA_ORIGIN IS NULL)
               AND (F.SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR SFRSTCR_DATA_ORIGIN IS NULL)
               AND (F.SFRSTCR_USER_ID != 'MIGRA_D' OR F.SFRSTCR_USER_ID IS NULL)
               AND F.SFRSTCR_CRN = G.SSBSECT_CRN
               AND F.SFRSTCR_PTRM_CODE = G.SSBSECT_PTRM_CODE
               AND G.SSBSECT_PTRM_START_DATE = P_FECHA
               AND SORLCUR_PIDM = P_PIDM;
      EXCEPTION
      WHEN OTHERS THEN
      NULL;
      END;

      VL_APL_BECA:= PKG_FINANZAS.F_BECA_COLABORADOR ( VL_CAMPUS,
                                                      VL_NIVEL,
                                                      P_PIDM,
                                                      P_FECHA,
                                                      VL_PROGRAMA,
                                                      10);

      BEGIN
        UPDATE TZTBECA
           SET TZTBECA_OBSERVACIONES = 'AJUSTES APLICADOS CORRECTAMENTE'
         WHERE     TZTBECA_PIDM = P_PIDM
               AND TZTBECA_START_DATE = P_FECHA
               AND TZTBECA_ETIQUETA = 'EUTL'
               AND TZTBECA_OBSERVACIONES = 'ELIMINADO PARA REPROCESO';
      END;

    END IF;
  END IF;
  COMMIT;
RETURN(VL_ERROR);
END F_AJ_CAN_BECA;

FUNCTION F_CARTERA_CJOR ( P_PIDM NUMBER,
                          P_STUDY NUMBER,
                          P_FECHA DATE
                          )RETURN VARCHAR2 IS

---------------- Funcion para insertar cartera en TVAAREV para cambios de jornada
---------------- ACTUALIZADO: JREZAOLI 24/11/2020 --

VL_ERROR            VARCHAR2(800):= NULL;
VL_JORNADA          VARCHAR2(5);
VL_ACCESORIOS       NUMBER;
VL_COD_ACCE         VARCHAR2(2);
VL_COD_SZF          VARCHAR2(8);
VL_RATE             VARCHAR2(8);
VL_COSTO            NUMBER;
VL_FECHA_APLICAR    DATE;
VL_DIA              NUMBER;
VL_MES              NUMBER;
VL_ANO              NUMBER;
VL_PERIODO          VARCHAR2(7);
VL_PARTE            VARCHAR2(4);
VL_CODIGO           VARCHAR2(4);
VL_DESCRI           VARCHAR2(40);
VL_ORDEN            NUMBER;
VL_PAGOS            NUMBER;
VL_VENCIMIENTO      DATE;
VL_SECUENCIA        NUMBER;
VL_INCREMENTO       NUMBER;
VL_BITACORA         NUMBER;

 BEGIN
   BEGIN
     SELECT SUBSTR(T.SGRSATT_ATTS_CODE,3,1)
       INTO VL_JORNADA
       FROM SGRSATT T
      WHERE     T.SGRSATT_PIDM = P_PIDM
            AND T.SGRSATT_STSP_KEY_SEQUENCE = P_STUDY
            AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
            AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
            AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                              FROM SGRSATT TT
                                             WHERE     TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                   AND TT.SGRSATT_STSP_KEY_SEQUENCE= T.SGRSATT_STSP_KEY_SEQUENCE
                                                   AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
                                                   AND REGEXP_LIKE  (TT.SGRSATT_ATTS_CODE , '^[0-9]'))
            AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                             FROM SGRSATT T1
                                            WHERE     T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                                  AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                                  AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                                  AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
                                                  AND REGEXP_LIKE  (T1.SGRSATT_ATTS_CODE , '^[0-9]'));
   EXCEPTION
   WHEN OTHERS THEN
   VL_JORNADA:='SIN';
   END;
  /* SE CALCULA SI TIENE BENEFICIOS */
   BEGIN
     SELECT COUNT(*)
       INTO VL_ACCESORIOS
       FROM TBRACCD,TBBDETC
      WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
            AND TBRACCD_PIDM = P_PIDM
            AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY
            AND TBBDETC_DCAT_CODE = 'VTA'
            AND TBRACCD_DETAIL_CODE NOT LIKE '%XH'
            AND TBRACCD_DETAIL_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                              FROM ZSTPARA
                                              WHERE ZSTPARA_MAPA_ID = 'COMPL_COSTOS');
   END;

   IF VL_ACCESORIOS = 0 THEN
     VL_COD_ACCE := 'S';
   ELSE

     BEGIN
       SELECT COUNT(*)
         INTO VL_ACCESORIOS
         FROM TBRACCD,TBBDETC
        WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
              AND TBRACCD_PIDM = P_PIDM
              AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY
              AND TBBDETC_DCAT_CODE = 'VTA'
              AND SUBSTR(TBBDETC_DETAIL_CODE,3,2) IN ('OT','SE')
              AND TBRACCD_DETAIL_CODE NOT LIKE '%XH'
              AND TBRACCD_DETAIL_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                FROM ZSTPARA
                                                WHERE ZSTPARA_MAPA_ID = 'COMPL_COSTOS');
     END;

     IF VL_ACCESORIOS = 0 THEN
       VL_COD_ACCE := 'C';
     ELSE
       VL_COD_ACCE := 'T';
     END IF;

   END IF;

   IF VL_JORNADA = 'SIN' THEN
     VL_ERROR:= 'ALUMNO SIN JORNADA EN SGASADD, VALIDAR INFORMACION.';
   ELSE
     /* ENTRA A GENERAR LOS CARGOS */
     BEGIN
       SELECT SORLCUR_CAMP_CODE||SORLCUR_LEVL_CODE||VL_COD_ACCE||VL_JORNADA,SORLCUR_RATE_CODE
         INTO VL_COD_SZF,VL_RATE
         FROM SORLCUR A
         WHERE     A.SORLCUR_PIDM = P_PIDM
               AND A.SORLCUR_LMOD_CODE = 'LEARNER'
               AND A.SORLCUR_ROLL_IND  = 'Y'
               AND A.SORLCUR_CACT_CODE = 'ACTIVE'
               AND A.SORLCUR_KEY_SEQNO = P_STUDY
               AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                         FROM SORLCUR A1
                                        WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                              AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                              AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                              AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                              AND A1.SORLCUR_KEY_SEQNO = A.SORLCUR_KEY_SEQNO
                                              AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE);
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:= 'ERROR AL CALCULAR SORLCUR = '||SQLERRM;
     END;

     IF SUBSTR(VL_RATE,1,1) = 'J' THEN

       BEGIN
         SELECT ZSTPARA_PARAM_VALOR
           INTO VL_COSTO
           FROM ZSTPARA
          WHERE     ZSTPARA_MAPA_ID = 'PRECIO_CJOR'
                AND ZSTPARA_PARAM_ID = VL_COD_SZF;
       END;

       BEGIN
         SELECT TZDOCTR_PORC_INCREM
           INTO VL_INCREMENTO
           FROM TZDOCTR
          WHERE     TZDOCTR_PIDM = P_PIDM
                AND TZDOCTR_START_DATE = P_FECHA
                AND TZDOCTR_TIPO_PROC = 'AUME';
       EXCEPTION
       WHEN OTHERS THEN
       VL_INCREMENTO:=0;
       END;

       IF VL_INCREMENTO = 0 THEN
        VL_COSTO:= VL_COSTO;
       ELSE
        VL_COSTO:= ROUND(VL_COSTO*(1+(VL_INCREMENTO/100)),0);
       END IF;

       BEGIN
         SELECT TBRACCD_TERM_CODE,TBRACCD_PERIOD,TBRACCD_DETAIL_CODE,TBRACCD_DESC,TBRACCD_RECEIPT_NUMBER
           INTO VL_PERIODO,VL_PARTE,VL_CODIGO,VL_DESCRI,VL_ORDEN
           FROM TBRACCD A
          WHERE     TBRACCD_PIDM = P_PIDM
                AND TBRACCD_TRAN_NUMBER = (SELECT MAX(TBRACCD_TRAN_NUMBER)
                                             FROM TBRACCD A1,TBBDETC
                                            WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                  AND TBBDETC_DCAT_CODE = 'COL'
                                                  AND A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                                                  AND A1.TBRACCD_CREATE_SOURCE LIKE 'TZFEDCA%'
                                                  AND A1.TBRACCD_FEED_DATE = P_FECHA
                                                  AND A1.TBRACCD_STSP_KEY_SEQUENCE = P_STUDY);
       EXCEPTION
       WHEN OTHERS THEN
       VL_ERROR:='ERROR AL CALCULAR TBRACCD = '||SQLERRM;
       END;

       IF TO_CHAR(P_FECHA,'DD') >= 20 THEN
       VL_FECHA_APLICAR:= ADD_MONTHS(P_FECHA,1);
       ELSE
       VL_FECHA_APLICAR:= P_FECHA;
       END IF;

       VL_DIA := CASE SUBSTR(VL_RATE,4,1) WHEN 'A' THEN 15 WHEN 'B' THEN 30 WHEN 'C' THEN 10 END;
       VL_MES :=SUBSTR (TO_CHAR(VL_FECHA_APLICAR, 'dd/mm/rrrr'), 4, 2);
       VL_ANO :=SUBSTR (TO_CHAR(VL_FECHA_APLICAR, 'dd/mm/rrrr'), 7, 4);

       BEGIN

         VL_PAGOS:= SUBSTR(VL_RATE,3,1);

         FOR I IN 1..VL_PAGOS LOOP

             IF VL_DIA = '30' THEN
               VL_VENCIMIENTO := TO_DATE((CASE LPAD(VL_MES,2,'0') WHEN '02' THEN '28' ELSE VL_DIA END||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO),'DD/MM/YYYY');
             ELSE
               VL_VENCIMIENTO := TO_DATE((VL_DIA||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO),'DD/MM/YYYY');
             END IF;

             VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (P_PIDM);

             VL_ERROR:= PKG_FINANZAS.F_INSERTA_TBRACCD(
                                                       P_PIDM => P_PIDM
                                                     , P_SECUENCIA => VL_SECUENCIA
                                                     , P_NUMBER_PAID => NULL
                                                     , P_PERIODO => VL_PERIODO
                                                     , P_PARTE_PERIODO => VL_PARTE
                                                     , P_CODIGO => VL_CODIGO
                                                     , P_MONTO => VL_COSTO
                                                     , P_BALANCE => VL_COSTO
                                                     , P_FECHA_VENC => VL_VENCIMIENTO
                                                     , P_DESCRIP => VL_DESCRI
                                                     , P_STUDY_PATH => P_STUDY
                                                     , P_ORIGEN => 'TZFEDCA (PARC)'
                                                     , P_FECHA_INICIO => P_FECHA);

             VL_MES := VL_MES +1;

             IF VL_MES = '13' THEN
                VL_MES := '01';
                VL_ANO := VL_ANO +1;
             END IF;

         END LOOP;

         BEGIN
           UPDATE TBRACCD
              SET TBRACCD_RECEIPT_NUMBER = VL_ORDEN
            WHERE     TBRACCD_PIDM = P_PIDM
                  AND TBRACCD_CREATE_SOURCE LIKE 'TZFEDCA%'
                  AND TBRACCD_FEED_DATE = P_FECHA
                  AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY
                  AND TBRACCD_RECEIPT_NUMBER IS NULL;
         END;

         BEGIN
           UPDATE TZDOCTR
              SET TZDOCTR_OBSERVACIONES = 'REPROCESO'
            WHERE     TZDOCTR_PIDM = P_PIDM
                  AND TZDOCTR_START_DATE = P_FECHA;
         END;

         BEGIN
           SELECT COUNT(*)
             INTO VL_BITACORA
             FROM TZTCJOR
            WHERE TZTCJOR_PIDM = P_PIDM
            AND TZTCJOR_START_DATE = P_FECHA
            AND TZTCJOR_STUDY_PAHT = P_STUDY;
         END;

         IF VL_BITACORA = 0 THEN

             BEGIN
                 INSERT
                   INTO TZTCJOR
                       (TZTCJOR_PIDM,
                        TZTCJOR_START_DATE,
                        TZTCJOR_TERM_CODE,
                        TZTCJOR_PTRM_CODE,
                        TZTCJOR_STUDY_PAHT,
                        TZTCJOR_ATTS_CODE,
                        TZTCJOR_ACTIVITY_DATE,
                        TZTCJOR_ACTIVITY_UPDATE,
                        TZTCJOR_USER,
                        TZTCJOR_USER_UPDATE,
                        TZTCJOR_DATA_ORIGIN,
                        TZTCJOR_ORDEN        )
                 VALUES (P_PIDM,
                         P_FECHA,
                         VL_PERIODO,
                         VL_PARTE,
                         P_STUDY,
                         VL_JORNADA,
                         SYSDATE,
                         SYSDATE,
                         USER,
                         USER,
                         'CAMBIO_JOR',
                         VL_ORDEN
                         );
             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR:= 'ERROR AL INSERTAR EN TZTCJOR = '||SQLERRM;
             END;

         ELSE

           BEGIN
             UPDATE TZTCJOR
                SET TZTCJOR_ATTS_CODE = VL_JORNADA,
                    TZTCJOR_ACTIVITY_UPDATE = SYSDATE,
                    TZTCJOR_USER_UPDATE = USER
              WHERE     TZTCJOR_PIDM = P_PIDM
                    AND TZTCJOR_START_DATE = P_FECHA
                    AND TZTCJOR_STUDY_PAHT = P_STUDY;
           END;

         END IF;

       END;

     ELSE
       VL_ERROR:='NO SE GENERA CARGO POR SER UN PLAN';
     END IF;

   END IF;

   IF VL_ERROR IS NULL THEN
     VL_ERROR:= 'EXITO';
     COMMIT;
     RETURN(VL_ERROR);
   ELSE
     ROLLBACK;
     RETURN(VL_ERROR);
   END IF;

 END F_CARTERA_CJOR;

FUNCTION F_CAMBIOS_JORNADA (P_MATRICULA VARCHAR2) RETURN PKG_FINANZAS_REZA.JORNADAS
AS
PRECIO_JORN PKG_FINANZAS_REZA.JORNADAS;

VL_PROMO        NUMBER;

 BEGIN

   BEGIN
     SELECT COUNT(*)
       INTO VL_PROMO
       FROM TBRACCD A
      WHERE      A.TBRACCD_PIDM = FGET_PIDM(P_MATRICULA)
            AND SUBSTR(A.TBRACCD_DETAIL_CODE,3,2) = 'M3'
            AND A.TBRACCD_FEED_DATE = (SELECT DISTINCT(MAX(TBRACCD_FEED_DATE))
                                         FROM TBRACCD,TBBDETC
                                        WHERE     TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                              AND TBRACCD_PIDM = A.TBRACCD_PIDM
                                              AND TBBDETC_DCAT_CODE = 'COL'
                                              AND TBBDETC_DESC != 'COLEGIATURA EXTRAORDINARIO'
                                              AND TBBDETC_DESC NOT LIKE '%NOTA');
   EXCEPTION
   WHEN OTHERS THEN
   VL_PROMO:=0;
   END;

   IF VL_PROMO <= 1 THEN

     BEGIN

      OPEN PRECIO_JORN FOR

          SELECT CAMPUS,
                 NIVEL,
                 MATRICULA,
                 PROGRAMA,
                 JORNADA,
                 INCREMENTO,
                 CAMBIO_JORNADA,
                 PRECIO,
                 PRECIO_ACTUAL
            FROM (
                  SELECT SORLCUR_CAMP_CODE CAMPUS,
                         SORLCUR_LEVL_CODE NIVEL,
                         SPRIDEN_ID MATRICULA,
                         SORLCUR_PROGRAM PROGRAMA,
                         (SELECT T.SGRSATT_ATTS_CODE
                            FROM SGRSATT T
                           WHERE     T.SGRSATT_PIDM = A.SORLCUR_PIDM
                                 AND T.SGRSATT_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                 AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
                                 AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
                                 AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                                                   FROM SGRSATT TT
                                                                  WHERE     TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                                        AND TT.SGRSATT_STSP_KEY_SEQUENCE= T.SGRSATT_STSP_KEY_SEQUENCE
                                                                        AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
                                                                        AND REGEXP_LIKE  (TT.SGRSATT_ATTS_CODE , '^[0-9]'))
                                 AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                                                  FROM SGRSATT T1
                                                                 WHERE     T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                                                       AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                                                       AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                                                       AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
                                                                       AND REGEXP_LIKE  (T1.SGRSATT_ATTS_CODE , '^[0-9]')))JORNADA,
                         NVL((SELECT NVL(TZDOCTR_PORC_INCREM,0)
                            FROM TZDOCTR
                           WHERE     TZDOCTR_PIDM = A.SORLCUR_PIDM
                                 AND TZDOCTR_START_DATE = A.SORLCUR_START_DATE
                                 AND TZDOCTR_TIPO_PROC = 'AUME'),0)INCREMENTO,
                         ZSTPARA_PARAM_ID CODIGO,
                         ZSTPARA_PARAM_DESC CAMBIO_JORNADA,
                         ROUND(ZSTPARA_PARAM_VALOR* ((NVL((SELECT NVL(TZDOCTR_PORC_INCREM,0)
                                           FROM TZDOCTR
                                          WHERE     TZDOCTR_PIDM = A.SORLCUR_PIDM
                                                AND TZDOCTR_START_DATE = A.SORLCUR_START_DATE
                                                AND TZDOCTR_TIPO_PROC = 'AUME'),0)/100)+1),0)PRECIO,
                        (SELECT DISTINCT(TBRACCD_AMOUNT)
                           FROM TBRACCD
                          WHERE TBRACCD_PIDM = A.SORLCUR_PIDM
                                AND TBRACCD_FEED_DATE = A.SORLCUR_START_DATE
                                AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                AND TBRACCD_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                AND TBRACCD_DOCUMENT_NUMBER IS NULL)PRECIO_ACTUAL
                  FROM SORLCUR A, SPRIDEN D,ZSTPARA
                  WHERE A.SORLCUR_PIDM = D.SPRIDEN_PIDM
                  AND D.SPRIDEN_CHANGE_IND IS NULL
                  AND ZSTPARA_MAPA_ID = 'PRECIO_CJOR'
                  AND SUBSTR(ZSTPARA_PARAM_ID,1,5) = A.SORLCUR_CAMP_CODE||A.SORLCUR_LEVL_CODE
                  AND SUBSTR(ZSTPARA_PARAM_ID,6,1) = (SELECT
                                                             CASE
                                                               WHEN TITULACION > 0 THEN 'T'
                                                               WHEN TITULACION = 0 AND ACCESORIOS >0 THEN 'C'
                                                               WHEN ACCESORIOS = 0 THEN 'S'
                                                             END AS ACCESORIOS
                                                      FROM (
                                                            SELECT (SELECT COUNT(*)
                                                                      FROM TBRACCD,TBBDETC
                                                                     WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                                           AND TBRACCD_PIDM = A.SORLCUR_PIDM
                                                                           AND TBRACCD_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                                                           AND TBBDETC_DCAT_CODE = 'VTA'
                                                                           AND TBRACCD_DETAIL_CODE NOT LIKE '%XH'
                                                                           AND TBRACCD_DETAIL_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                                                                             FROM ZSTPARA
                                                                                                            WHERE ZSTPARA_MAPA_ID = 'COMPL_COSTOS'))ACCESORIOS,
                                                                   (SELECT COUNT(*)
                                                                      FROM TBRACCD,TBBDETC
                                                                     WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                                           AND TBRACCD_PIDM = A.SORLCUR_PIDM
                                                                           AND TBRACCD_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                                                           AND TBBDETC_DCAT_CODE = 'VTA'
                                                                           AND SUBSTR(TBBDETC_DETAIL_CODE,3,2) IN ('OT','SE')
                                                                           AND TBRACCD_DETAIL_CODE NOT LIKE '%XH'
                                                                           AND TBRACCD_DETAIL_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                                                                             FROM ZSTPARA
                                                                                                             WHERE ZSTPARA_MAPA_ID = 'COMPL_COSTOS'))TITULACION
                                                              FROM DUAL))
                  AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                  AND A.SORLCUR_ROLL_IND  = 'Y'
                  AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                  AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                         FROM SORLCUR A1
                                         WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                         AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                         AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                         AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
                  AND SUBSTR(A.SORLCUR_RATE_CODE,1,1) = 'J'
                  AND D.SPRIDEN_ID IN (P_MATRICULA))CAMBIO
          WHERE SUBSTR(JORNADA,3,1) != SUBSTR(CODIGO,7,1);

       RETURN (PRECIO_JORN);

     END;

   ELSE

     BEGIN

      OPEN PRECIO_JORN FOR

         SELECT DISTINCT
                NULL,
                NULL,
                SPRIDEN_ID MATRICULA,
                SORLCUR_PROGRAM PROGRAMA,
                NULL,
                NULL,
                'NO SE PUEDE REALIZAR CAMBIO DE JORNADA, ALUMNO CUENTA CON DESCUENTO ESCALONADO',
                NULL,
                (SELECT DISTINCT(TBRACCD_AMOUNT)
                  FROM TBRACCD
                 WHERE TBRACCD_PIDM = A.SORLCUR_PIDM
                       AND TBRACCD_FEED_DATE = A.SORLCUR_START_DATE
                       AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                       AND TBRACCD_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                       AND TBRACCD_DOCUMENT_NUMBER IS NULL)PRECIO_ACTUAL
           FROM SORLCUR A, SPRIDEN D,ZSTPARA
          WHERE     A.SORLCUR_PIDM = D.SPRIDEN_PIDM
                AND D.SPRIDEN_CHANGE_IND IS NULL
                AND ZSTPARA_MAPA_ID = 'PRECIO_CJOR'
                AND SUBSTR(ZSTPARA_PARAM_ID,1,5) = A.SORLCUR_CAMP_CODE||A.SORLCUR_LEVL_CODE
                AND SUBSTR(ZSTPARA_PARAM_ID,6,1) = (SELECT
                                                           CASE
                                                             WHEN TITULACION > 0 THEN 'T'
                                                             WHEN TITULACION = 0 AND ACCESORIOS >0 THEN 'C'
                                                             WHEN ACCESORIOS = 0 THEN 'S'
                                                           END AS ACCESORIOS
                                                    FROM (
                                                          SELECT (SELECT COUNT(*)
                                                                    FROM TBRACCD,TBBDETC
                                                                   WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                                         AND TBRACCD_PIDM = A.SORLCUR_PIDM
                                                                         AND TBRACCD_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                                                         AND TBBDETC_DCAT_CODE = 'VTA'
                                                                         AND TBRACCD_DETAIL_CODE NOT LIKE '%XH'
                                                                         AND TBRACCD_DETAIL_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                                                                           FROM ZSTPARA
                                                                                                          WHERE ZSTPARA_MAPA_ID = 'COMPL_COSTOS'))ACCESORIOS,
                                                                 (SELECT COUNT(*)
                                                                    FROM TBRACCD,TBBDETC
                                                                   WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                                         AND TBRACCD_PIDM = A.SORLCUR_PIDM
                                                                         AND TBRACCD_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                                                         AND TBBDETC_DCAT_CODE = 'VTA'
                                                                         AND SUBSTR(TBBDETC_DETAIL_CODE,3,2) IN ('OT','SE')
                                                                         AND TBRACCD_DETAIL_CODE NOT LIKE '%XH'
                                                                         AND TBRACCD_DETAIL_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                                                                           FROM ZSTPARA
                                                                                                           WHERE ZSTPARA_MAPA_ID = 'COMPL_COSTOS'))TITULACION
                                                            FROM DUAL))
                AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                AND A.SORLCUR_ROLL_IND  = 'Y'
                AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                       FROM SORLCUR A1
                                       WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                       AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                       AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                       AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
                AND SUBSTR(A.SORLCUR_RATE_CODE,1,1) = 'J'
                AND D.SPRIDEN_ID IN (P_MATRICULA);

        RETURN (PRECIO_JORN);

     END;

   END IF;

 END F_CAMBIOS_JORNADA;

FUNCTION F_PRECIO_JORNADA (P_MATRICULA VARCHAR2,P_JORNADA VARCHAR2) RETURN VARCHAR2 IS

VL_RESULTADO        VARCHAR2(40);

 BEGIN
   BEGIN
      SELECT ROUND(ZSTPARA_PARAM_VALOR* ((NVL((SELECT NVL(TZDOCTR_PORC_INCREM,0)
                                                 FROM TZDOCTR
                                                WHERE     TZDOCTR_PIDM = A.SORLCUR_PIDM
                                                      AND TZDOCTR_START_DATE = A.SORLCUR_START_DATE
                                                      AND TZDOCTR_IND = 1
                                                      AND TZDOCTR_TIPO_PROC = 'AUME'),0)/100)+1),0)||'_'||
             (SELECT DISTINCT(TBRACCD_AMOUNT)
                FROM TBRACCD
               WHERE TBRACCD_PIDM = A.SORLCUR_PIDM
                     AND TBRACCD_FEED_DATE = A.SORLCUR_START_DATE
                     AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                     AND TBRACCD_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                     AND TBRACCD_DOCUMENT_NUMBER IS NULL)RETORNA
        INTO VL_RESULTADO
        FROM SORLCUR A, SPRIDEN D,ZSTPARA
       WHERE     A.SORLCUR_PIDM = D.SPRIDEN_PIDM
             AND D.SPRIDEN_CHANGE_IND IS NULL
             AND ZSTPARA_MAPA_ID = 'PRECIO_CJOR'
             AND SUBSTR(ZSTPARA_PARAM_ID,1,5) = A.SORLCUR_CAMP_CODE||A.SORLCUR_LEVL_CODE
             AND SUBSTR(ZSTPARA_PARAM_ID,6,1) = (SELECT
                                                        CASE
                                                          WHEN TITULACION > 0 THEN 'T'
                                                          WHEN TITULACION = 0 AND ACCESORIOS >0 THEN 'C'
                                                          WHEN ACCESORIOS = 0 THEN 'S'
                                                        END AS ACCESORIOS
                                                 FROM (
                                                       SELECT (SELECT COUNT(*)
                                                                 FROM TBRACCD,TBBDETC
                                                                WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                                      AND TBRACCD_PIDM = A.SORLCUR_PIDM
                                                                      AND TBRACCD_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                                                      AND TBBDETC_DCAT_CODE = 'VTA'
                                                                      AND TBRACCD_DETAIL_CODE NOT LIKE '%XH'
                                                                      AND TBRACCD_DETAIL_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                                                                        FROM ZSTPARA
                                                                                                       WHERE ZSTPARA_MAPA_ID = 'COMPL_COSTOS'))ACCESORIOS,
                                                              (SELECT COUNT(*)
                                                                 FROM TBRACCD,TBBDETC
                                                                WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                                      AND TBRACCD_PIDM = A.SORLCUR_PIDM
                                                                      AND TBRACCD_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                                                      AND TBBDETC_DCAT_CODE = 'VTA'
                                                                      AND SUBSTR(TBBDETC_DETAIL_CODE,3,2) IN ('OT','SE')
                                                                      AND TBRACCD_DETAIL_CODE NOT LIKE '%XH'
                                                                      AND TBRACCD_DETAIL_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                                                                        FROM ZSTPARA
                                                                                                        WHERE ZSTPARA_MAPA_ID = 'COMPL_COSTOS'))TITULACION
                                                         FROM DUAL))
             AND A.SORLCUR_LMOD_CODE = 'LEARNER'
             AND A.SORLCUR_ROLL_IND  = 'Y'
             AND A.SORLCUR_CACT_CODE = 'ACTIVE'
             AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                       FROM SORLCUR A1
                                      WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                            AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                            AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                            AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
             AND SUBSTR(A.SORLCUR_RATE_CODE,1,1) = 'J'
             AND SUBSTR(ZSTPARA_PARAM_ID,7,1) = P_JORNADA
             AND D.SPRIDEN_ID = P_MATRICULA;
   EXCEPTION
   WHEN OTHERS THEN
   VL_RESULTADO:='INCORRECTO';
   END;

  RETURN(VL_RESULTADO);

 END F_PRECIO_JORNADA;

FUNCTION F_CONTINUOS_CJOR ( P_PIDM      NUMBER,
                            P_STUDY     NUMBER,
                            P_FECHA     DATE,
                            P_JORNADA   VARCHAR2,
                            P_ORDEN     NUMBER,
                            P_PERIODO   VARCHAR2,
                            P_PARTE     VARCHAR2
                                                )RETURN VARCHAR2 IS

---------------- Funcion para insertar cartera en TVAAREV para continuos que realizaron un cambio de jornada
---------------- ACTUALIZADO: JREZAOLI 21/12/2020 --

VL_ERROR            VARCHAR2(800):= NULL;
VL_ACCESORIOS       NUMBER;
VL_COD_ACCE         VARCHAR2(2);
VL_COD_SZF          VARCHAR2(8);
VL_RATE             VARCHAR2(8);
VL_COSTO            NUMBER;
VL_FECHA_APLICAR    DATE;
VL_DIA              NUMBER;
VL_MES              NUMBER;
VL_ANO              NUMBER;
VL_CODIGO           VARCHAR2(4);
VL_DESCRI           VARCHAR2(40);
VL_PAGOS            NUMBER;
VL_VENCIMIENTO      DATE;
VL_SECUENCIA        NUMBER;
VL_INCREMENTO       NUMBER;

 BEGIN

  /* SE CALCULA SI TIENE BENEFICIOS */
   BEGIN
     SELECT COUNT(*)
       INTO VL_ACCESORIOS
       FROM TBRACCD,TBBDETC
      WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
            AND TBRACCD_PIDM = P_PIDM
            AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY
            AND TBBDETC_DCAT_CODE = 'VTA'
            AND TBRACCD_DETAIL_CODE NOT LIKE '%XH'
            AND TBRACCD_DETAIL_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                              FROM ZSTPARA
                                              WHERE ZSTPARA_MAPA_ID = 'COMPL_COSTOS');
   END;

   IF VL_ACCESORIOS = 0 THEN
     VL_COD_ACCE := 'S';
   ELSE

     BEGIN
       SELECT COUNT(*)
         INTO VL_ACCESORIOS
         FROM TBRACCD,TBBDETC
        WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
              AND TBRACCD_PIDM = P_PIDM
              AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY
              AND TBBDETC_DCAT_CODE = 'VTA'
              AND SUBSTR(TBBDETC_DETAIL_CODE,3,2) IN ('OT','SE')
              AND TBRACCD_DETAIL_CODE NOT LIKE '%XH'
              AND TBRACCD_DETAIL_CODE NOT IN (SELECT ZSTPARA_PARAM_VALOR
                                                FROM ZSTPARA
                                                WHERE ZSTPARA_MAPA_ID = 'COMPL_COSTOS');
     END;

     IF VL_ACCESORIOS = 0 THEN
       VL_COD_ACCE := 'C';
     ELSE
       VL_COD_ACCE := 'T';
     END IF;

   END IF;

   IF P_JORNADA = 'SIN' THEN
     VL_ERROR:= 'ALUMNO SIN JORNADA EN SGASADD, VALIDAR INFORMACION.';
   ELSE
     /* ENTRA A GENERAR LOS CARGOS */
     BEGIN
       SELECT SORLCUR_CAMP_CODE||SORLCUR_LEVL_CODE||VL_COD_ACCE||P_JORNADA,SORLCUR_RATE_CODE
         INTO VL_COD_SZF,VL_RATE
         FROM SORLCUR A
         WHERE     A.SORLCUR_PIDM = P_PIDM
               AND A.SORLCUR_LMOD_CODE = 'LEARNER'
               AND A.SORLCUR_ROLL_IND  = 'Y'
               AND A.SORLCUR_CACT_CODE = 'ACTIVE'
               AND A.SORLCUR_KEY_SEQNO = P_STUDY
               AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                         FROM SORLCUR A1
                                        WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                              AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                              AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                              AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                              AND A1.SORLCUR_KEY_SEQNO = A.SORLCUR_KEY_SEQNO
                                              AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE);
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:= 'ERROR AL CALCULAR SORLCUR = '||SQLERRM;
     END;

     IF SUBSTR(VL_RATE,1,1) = 'J' THEN

       BEGIN
         SELECT ZSTPARA_PARAM_VALOR
           INTO VL_COSTO
           FROM ZSTPARA
          WHERE     ZSTPARA_MAPA_ID = 'PRECIO_CJOR'
                AND ZSTPARA_PARAM_ID = VL_COD_SZF;
       END;

       BEGIN
         SELECT TZDOCTR_PORC_INCREM
           INTO VL_INCREMENTO
           FROM TZDOCTR
          WHERE     TZDOCTR_PIDM = P_PIDM
                AND TZDOCTR_START_DATE = P_FECHA
                AND TZDOCTR_TIPO_PROC = 'AUME';
       EXCEPTION
       WHEN OTHERS THEN
       VL_INCREMENTO:=0;
       END;

       IF VL_INCREMENTO = 0 THEN
        VL_COSTO:= VL_COSTO;
       ELSE
        VL_COSTO:= ROUND(VL_COSTO*(1+(VL_INCREMENTO/100)),0);
       END IF;

       BEGIN
         SELECT TBRACCD_DETAIL_CODE,TBRACCD_DESC
           INTO VL_CODIGO,VL_DESCRI
           FROM TBRACCD A
          WHERE     TBRACCD_PIDM = P_PIDM
                AND TBRACCD_TRAN_NUMBER = (SELECT MAX(TBRACCD_TRAN_NUMBER)
                                             FROM TBRACCD A1,TBBDETC
                                            WHERE     TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                  AND TBBDETC_DCAT_CODE = 'COL'
                                                  AND A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                                                  AND A1.TBRACCD_CREATE_SOURCE LIKE 'TZFEDCA%'
                                                  AND A1.TBRACCD_STSP_KEY_SEQUENCE = P_STUDY);
       EXCEPTION
       WHEN OTHERS THEN
       VL_ERROR:='ERROR AL CALCULAR TBRACCD = '||SQLERRM;
       END;

       IF TO_CHAR(P_FECHA,'DD') >= 20 THEN
       VL_FECHA_APLICAR:= ADD_MONTHS(P_FECHA,1);
       ELSE
       VL_FECHA_APLICAR:= P_FECHA;
       END IF;

       VL_DIA := CASE SUBSTR(VL_RATE,4,1) WHEN 'A' THEN 15 WHEN 'B' THEN 30 WHEN 'C' THEN 10 END;
       VL_MES :=SUBSTR (TO_CHAR(VL_FECHA_APLICAR, 'dd/mm/rrrr'), 4, 2);
       VL_ANO :=SUBSTR (TO_CHAR(VL_FECHA_APLICAR, 'dd/mm/rrrr'), 7, 4);

       BEGIN

         VL_PAGOS:= SUBSTR(VL_RATE,3,1);

         FOR I IN 1..VL_PAGOS LOOP

             IF VL_DIA = '30' THEN
               VL_VENCIMIENTO := TO_DATE((CASE LPAD(VL_MES,2,'0') WHEN '02' THEN '28' ELSE VL_DIA END||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO),'DD/MM/YYYY');
             ELSE
               VL_VENCIMIENTO := TO_DATE((VL_DIA||'/'||LPAD(VL_MES,2,'0')||'/'||VL_ANO),'DD/MM/YYYY');
             END IF;

             VL_SECUENCIA:= PKG_FINANZAS.F_MAX_SEC_TBRACCD (P_PIDM);

             VL_ERROR:= PKG_FINANZAS.F_INSERTA_TBRACCD(
                                                       P_PIDM => P_PIDM
                                                     , P_SECUENCIA => VL_SECUENCIA
                                                     , P_NUMBER_PAID => NULL
                                                     , P_PERIODO => P_PERIODO
                                                     , P_PARTE_PERIODO => P_PARTE
                                                     , P_CODIGO => VL_CODIGO
                                                     , P_MONTO => VL_COSTO
                                                     , P_BALANCE => VL_COSTO
                                                     , P_FECHA_VENC => VL_VENCIMIENTO
                                                     , P_DESCRIP => VL_DESCRI
                                                     , P_STUDY_PATH => P_STUDY
                                                     , P_ORIGEN => 'TZFEDCA (PARC)'
                                                     , P_FECHA_INICIO => P_FECHA);

             VL_MES := VL_MES +1;

             IF VL_MES = '13' THEN
                VL_MES := '01';
                VL_ANO := VL_ANO +1;
             END IF;

         END LOOP;

       END;

     ELSE
       VL_ERROR:='NO SE GENERA CARGO POR SER UN PLAN';
     END IF;

   END IF;


   IF VL_ERROR IS NULL THEN
     COMMIT;
     RETURN(VL_ERROR);
   ELSE
     ROLLBACK;
     RETURN(VL_ERROR);
   END IF;

 END F_CONTINUOS_CJOR;

FUNCTION F_MESES_GENERAL (P_PIDM IN NUMBER) RETURN VARCHAR2
AS

VL_MESES    NUMBER;

BEGIN

    BEGIN
                    SELECT
                           NVL( CASE
                                WHEN MESES < 0 THEN 0
                                WHEN MESES > 0 THEN MESES
                           END,0)MESES
                    INTO VL_MESES
                    FROM(
                    SELECT CAMP,
                           NIVEL,
                           ID,
                           PIDM,
                           PROGRAMA,
                           RATE,
                           STUDY,
                           FECHA_MATE,
                           FECHA_CXC,
                           FECHA_INICIO,
                           (CASE
                                 WHEN FECHA_CXC IS NOT NULL THEN (SELECT ROUND(MONTHS_BETWEEN(TO_DATE(FECHA_INICIO),TO_DATE(FECHA_CXC)))FROM DUAL)
                                 WHEN FECHA_CXC IS NULL THEN (SELECT ROUND(MONTHS_BETWEEN(TO_DATE(FECHA_INICIO),TO_DATE(FECHA_MATE)))FROM DUAL)
                           END) MESES
                    FROM (
                    SELECT DISTINCT
                           SORLCUR_CAMP_CODE CAMP,
                           SORLCUR_LEVL_CODE NIVEL,
                           SORLCUR_PROGRAM PROGRAMA,
                           SPRIDEN_ID ID,
                           SFRSTCR_PIDM PIDM,
                           SPRIDEN_FIRST_NAME||' '||SPRIDEN_LAST_NAME ALUMNO,
                           (SELECT TO_DATE(TRUNC(MIN (SSBSECT_PTRM_START_DATE+12),'MONTH'))
                            FROM SFRSTCR F1,SSBSECT T1
                            WHERE SFRSTCR_CRN = SSBSECT_CRN
                            AND SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                            AND SFRSTCR_PTRM_CODE = SSBSECT_PTRM_CODE
                            AND SFRSTCR_PIDM = CUR.SORLCUR_PIDM
                            AND SFRSTCR_STSP_KEY_SEQUENCE = CUR.SORLCUR_KEY_SEQNO
                            AND SFRSTCR_RSTS_CODE = 'RE')FECHA_MATE,
                           (SELECT MAX(TZTINCR_START_DATE)
                            FROM TZTINCR
                            WHERE TZTINCR_PIDM = CUR.SORLCUR_PIDM
                            AND TZTINCR_STUDY = CUR.SORLCUR_KEY_SEQNO)FECHA_CXC,
                           SORLCUR_START_DATE FECHA_INICIO,
                           SORLCUR_KEY_SEQNO STUDY,
                           SORLCUR_RATE_CODE RATE
                    FROM SFRSTCR HST,
                         SORLCUR CUR,
                         SPRIDEN
                    WHERE 1 = 1
                    AND HST.SFRSTCR_PIDM=CUR.SORLCUR_PIDM
                    AND SPRIDEN_PIDM = SORLCUR_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL
                    AND SPRIDEN_PIDM = P_PIDM
                    AND CUR.SORLCUR_LMOD_CODE = 'LEARNER'
                    AND CUR.SORLCUR_ROLL_IND  = 'Y'
                    AND CUR.SORLCUR_CACT_CODE = 'ACTIVE'
                    AND SPRIDEN_PIDM NOT IN (SELECT TBRACCD_PIDM
                                                FROM TBRACCD CCD
                                               WHERE     CCD.TBRACCD_PIDM = CUR.SORLCUR_PIDM
                                                     AND SUBSTR(CCD.TBRACCD_DETAIL_CODE,3,2) IN ('RM','RN','RP')
                                                     AND CCD.TBRACCD_STSP_KEY_SEQUENCE = CUR.SORLCUR_KEY_SEQNO)
                    AND CUR.SORLCUR_SEQNO = (SELECT MAX(CUR2.SORLCUR_SEQNO)
                                              FROM SORLCUR CUR2
                                              WHERE 1 = 1
                                              AND CUR2.SORLCUR_PIDM=CUR.SORLCUR_PIDM
                                              AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE
                                              AND CUR2.SORLCUR_ROLL_IND = CUR.SORLCUR_ROLL_IND
                                              AND CUR2.SORLCUR_CACT_CODE = CUR.SORLCUR_CACT_CODE)
                    AND CUR.SORLCUR_KEY_SEQNO = HST.SFRSTCR_STSP_KEY_SEQUENCE
                    AND HST.SFRSTCR_RSTS_CODE = 'RE'
                    AND NOT EXISTS (SELECT GORADID_PIDM
                                      FROM GORADID
                                     WHERE     GORADID_ADID_CODE = 'INBE'
                                           AND GORADID_PIDM = CUR.SORLCUR_PIDM)
                    )ALUMNO
                    WHERE 1=1)X
                    WHERE 1=1;

    EXCEPTION
    WHEN OTHERS THEN
    VL_MESES:=NULL;
    END;

  RETURN(VL_MESES);

END F_MESES_GENERAL;

FUNCTION F_CURSOR_PAGOUNICO (P_PIDM NUMBER, P_MESES NUMBER,P_PROGRAMA VARCHAR2) RETURN PKG_FINANZAS_REZA.PARCIALIDADES AS

PARCI_PAGOUNI  PKG_FINANZAS_REZA.PARCIALIDADES;


VL_FECHA_INICIO     DATE;
VL_FECHA_VALIDA     DATE;
VL_ERROR            VARCHAR2(900);
VL_VALIDA_CART      NUMBER:=1;
VL_SALTO            NUMBER:=0;
VL_SALTO_PARC       NUMBER:=0;

 BEGIN
   BEGIN
     SELECT TBRACCD_FEED_DATE
       INTO VL_FECHA_INICIO
       FROM TBRACCD
      WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
            AND TBRACCD_DOCUMENT_NUMBER IS NULL
            AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE))
            AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                               FROM SORLCUR
                                              WHERE     SORLCUR_PIDM = P_PIDM
                                                    AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                    AND SORLCUR_ROLL_IND  = 'Y'
                                                    AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                    AND SORLCUR_PROGRAM = P_PROGRAMA)
            AND TBRACCD_PIDM = P_PIDM;
   EXCEPTION
   WHEN OTHERS THEN

     VL_VALIDA_CART:=0;

     BEGIN
       SELECT TBRACCD_FEED_DATE
         INTO VL_FECHA_INICIO
         FROM TBRACCD
        WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
              AND TBRACCD_DOCUMENT_NUMBER IS NULL
              AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1))
              AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                 FROM SORLCUR
                                                WHERE     SORLCUR_PIDM = P_PIDM
                                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                      AND SORLCUR_ROLL_IND  = 'Y'
                                                      AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                      AND SORLCUR_PROGRAM = P_PROGRAMA)
              AND TBRACCD_PIDM = P_PIDM;
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR CALCULO DE FECHA = '||SQLERRM;
     VL_FECHA_INICIO:=NULL;
     END;
   END;
 --DBMS_OUTPUT.PUT_LINE('g 1 = '|| VL_FECHA_INICIO||' = '||VL_VALIDA_CART);
   IF VL_VALIDA_CART = 1 AND VL_ERROR IS NULL THEN

     BEGIN
       SELECT MIN (TBRACCD_EFFECTIVE_DATE)
         INTO VL_FECHA_VALIDA
         FROM TBRACCD
        WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
              AND TBRACCD_DOCUMENT_NUMBER IS NULL
              AND TBRACCD_FEED_DATE = VL_FECHA_INICIO
              AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) >= LAST_DAY(TRUNC(SYSDATE))
              AND TBRACCD_BALANCE > 0
              AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                 FROM SORLCUR
                                                WHERE     SORLCUR_PIDM = P_PIDM
                                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                      AND SORLCUR_ROLL_IND  = 'Y'
                                                      AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                      AND SORLCUR_PROGRAM = P_PROGRAMA)
              AND TBRACCD_PIDM = P_PIDM;
     END;

      --DBMS_OUTPUT.PUT_LINE('antes reza '||VL_FECHA_INICIO||' = '||P_PIDM||' = '||P_PROGRAMA||' = '||VL_FECHA_VALIDA);

     IF VL_FECHA_VALIDA IS NULL THEN

       VL_SALTO:=2;
       VL_SALTO_PARC:=1;

        --DBMS_OUTPUT.PUT_LINE('exception reza '||VL_FECHA_INICIO||' = '||P_PIDM||' = '||P_PROGRAMA);

       BEGIN
         SELECT MAX (TBRACCD_EFFECTIVE_DATE)
           INTO VL_FECHA_VALIDA
           FROM TBRACCD
          WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                AND TBRACCD_DOCUMENT_NUMBER IS NULL
                AND TBRACCD_FEED_DATE = VL_FECHA_INICIO
                AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                   FROM SORLCUR
                                                  WHERE     SORLCUR_PIDM = P_PIDM
                                                        AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                        AND SORLCUR_ROLL_IND  = 'Y'
                                                        AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                        AND SORLCUR_PROGRAM = P_PROGRAMA)
                AND TBRACCD_PIDM = P_PIDM;
       END;

     ELSE

       VL_SALTO:= TO_CHAR((VL_FECHA_VALIDA),'MM') - TO_CHAR((VL_FECHA_INICIO+12),'MM');

     END IF;

    --DBMS_OUTPUT.PUT_LINE('g 2 = '|| VL_FECHA_VALIDA||' = '||VL_SALTO);

   ELSIF VL_VALIDA_CART = 0 AND VL_FECHA_INICIO IS NOT NULL AND VL_ERROR IS NULL  THEN

     VL_SALTO:=2;
     VL_SALTO_PARC:=1;

     BEGIN
       SELECT TBRACCD_EFFECTIVE_DATE
        INTO VL_FECHA_VALIDA
        FROM TBRACCD
       WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
             AND TBRACCD_DOCUMENT_NUMBER IS NULL
             AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1))
             AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                FROM SORLCUR
                                               WHERE     SORLCUR_PIDM = P_PIDM
                                                     AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                     AND SORLCUR_ROLL_IND  = 'Y'
                                                     AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                     AND SORLCUR_PROGRAM = P_PROGRAMA)
             AND TBRACCD_PIDM = P_PIDM;
     END;
     --DBMS_OUTPUT.PUT_LINE('g 3 = '|| VL_FECHA_VALIDA||' = '||VL_SALTO);
   END IF;

   IF VL_ERROR IS NULL THEN
   --DBMS_OUTPUT.PUT_LINE('entra al cursor = '||VL_SALTO||' = '||VL_FECHA_VALIDA||' = '||VL_SALTO_PARC);
       BEGIN
           OPEN PARCI_PAGOUNI
            FOR
            SELECT NUMERO,
                   CODIGO,
                   DESCRIPCION,
                   PARCIALIDAD,
                   ROUND
                   (CASE
                     WHEN BALANCE != 0 AND NUMERO = 1 THEN BALANCE
                    ELSE
                       CASE
                         WHEN INCREMENTO > 0 THEN INCREMENTO*(MONTO)
                         WHEN INCREMENTO = 0 THEN MONTO
                       ELSE
                          CASE
                             WHEN MESES_CURSADOS IS NULL THEN MONTO
                             WHEN MESES_CURSADOS < 12 THEN MONTO
                             WHEN MESES_CURSADOS = 12 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN MONTO
                             WHEN MESES_CURSADOS BETWEEN 13 AND 23 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN (1.05)*(MONTO)
                             WHEN MESES_CURSADOS = 24 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN (1.05)*(MONTO)
                             WHEN MESES_CURSADOS > 24 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN (1.10)*(MONTO)
                          END
                       END
                   END,0) SALDO
            FROM(
                SELECT NUMERO,
                       TBRACCD_PIDM PIDM,
                       TBRACCD_DETAIL_CODE CODIGO,
                       TBRACCD_DESC DESCRIPCION,
                       TBRACCD_BALANCE BALANCE,
                       TBRACCD_AMOUNT AMOUNT,
                       ADD_MONTHS(TBRACCD_EFFECTIVE_DATE,((NUMERO-1)+0))PARCIALIDAD,
                       PKG_FINANZAS_REZA.F_PARCIALIDAD ( D.TBRACCD_PIDM, D.TBRACCD_FEED_DATE ) MONTO,
                       PKG_FINANZAS_REZA.F_MESES_GENERAL ( TBRACCD_PIDM)+((CASE SIN_INCRE WHEN 1 THEN 1 ELSE NUMERO END -1)+0) MESES_CURSADOS,
                       CASE
                         WHEN PKG_FINANZAS_REZA.F_MESES_GENERAL ( TBRACCD_PIDM)+((CASE SIN_INCRE WHEN 1 THEN 1 ELSE NUMERO END-1)+0) < 12 THEN 0
                         WHEN PKG_FINANZAS_REZA.F_MESES_GENERAL ( TBRACCD_PIDM)+((CASE SIN_INCRE WHEN 1 THEN 1 ELSE NUMERO END-1)+0) BETWEEN 12 AND 23 THEN 1.05
                         WHEN PKG_FINANZAS_REZA.F_MESES_GENERAL ( TBRACCD_PIDM)+((CASE SIN_INCRE WHEN 1 THEN 1 ELSE NUMERO END-1)+0) >= 24 THEN 1.10
                       END INCREMENTO
                  FROM TBRACCD D,(SELECT DISTINCT
                                         TZFACCE_SEC_PIDM NUMERO,
                                         (SELECT COUNT(DISTINCT TBRACCD_PIDM)
                                            FROM TBRACCD CCD
                                           WHERE     CCD.TBRACCD_PIDM = P_PIDM
                                                 AND SUBSTR(CCD.TBRACCD_DETAIL_CODE,3,2) IN ('RM','RN','RP')
                                                 AND CCD.TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                                                         FROM SORLCUR
                                                                                        WHERE     SORLCUR_PIDM = P_PIDM
                                                                                              AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                              AND SORLCUR_ROLL_IND  = 'Y'
                                                                                              AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                              AND SORLCUR_PROGRAM = P_PROGRAMA
                                                                                              ))SIN_INCRE
                                FROM TZFACCE
                                WHERE TZFACCE_SEC_PIDM BETWEEN 1 AND 50
                                ORDER BY 1)
                 WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                       AND TBRACCD_DOCUMENT_NUMBER IS NULL
                       AND TBRACCD_EFFECTIVE_DATE = VL_FECHA_VALIDA
                       AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                         FROM SORLCUR
                                                        WHERE     SORLCUR_PIDM = P_PIDM
                                                              AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                              AND SORLCUR_ROLL_IND  = 'Y'
                                                              AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                              AND SORLCUR_PROGRAM = P_PROGRAMA)
                       AND NUMERO BETWEEN 1 AND P_MESES
                       AND TBRACCD_PIDM = P_PIDM
                ORDER BY 1);

           RETURN (PARCI_PAGOUNI);
       END;

   ELSE
   --DBMS_OUTPUT.PUT_LINE('No entra '||VL_ERROR);
     BEGIN
       OPEN PARCI_PAGOUNI
        FOR
         SELECT NULL,NULL,'No cuentas con promociones por el momento',NULL,NULL
         FROM DUAL;

       RETURN (PARCI_PAGOUNI);
     END;

   END IF;

 END F_CURSOR_PAGOUNICO;

FUNCTION F_SALDOS_PAGOUNICO (P_PIDM NUMBER, P_MESES NUMBER,P_PROGRAMA VARCHAR2) RETURN PKG_FINANZAS_REZA.SALDOS_PAGOUNI AS

SALDO_PUNI  PKG_FINANZAS_REZA.SALDOS_PAGOUNI;

VL_FECHA_INICIO     DATE;
VL_FECHA_VALIDA     DATE;
VL_ERROR            VARCHAR2(900);
VL_VALIDA_CART      NUMBER:=1;
VL_SALTO            NUMBER:=0;
VL_SALTO_PARC       NUMBER:=0;
VL_SALDO_VENCIDO    NUMBER;
VL_FECHA_COMPLE     DATE;
VL_COMPLE_EDC       DATE;
VL_MONTO_COMPL      NUMBER;
VL_DIFERE_COMPLE    NUMBER;
VL_NUMERO_COMP      NUMBER;

 BEGIN

   BEGIN
     SELECT TBRACCD_FEED_DATE
       INTO VL_FECHA_INICIO
       FROM TBRACCD
      WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
            AND TBRACCD_DOCUMENT_NUMBER IS NULL
            AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE))
            AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                               FROM SORLCUR
                                              WHERE     SORLCUR_PIDM = P_PIDM
                                                    AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                    AND SORLCUR_ROLL_IND  = 'Y'
                                                    AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                    AND SORLCUR_PROGRAM = P_PROGRAMA)
            AND TBRACCD_PIDM = P_PIDM;
   EXCEPTION
   WHEN OTHERS THEN

     VL_VALIDA_CART:=0;

     BEGIN
       SELECT TBRACCD_FEED_DATE
         INTO VL_FECHA_INICIO
         FROM TBRACCD
        WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
              AND TBRACCD_DOCUMENT_NUMBER IS NULL
              AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1))
              AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                 FROM SORLCUR
                                                WHERE     SORLCUR_PIDM = P_PIDM
                                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                      AND SORLCUR_ROLL_IND  = 'Y'
                                                      AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                      AND SORLCUR_PROGRAM = P_PROGRAMA)
              AND TBRACCD_PIDM = P_PIDM;
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR CALCULO DE FECHA = '||SQLERRM;
     VL_FECHA_INICIO:=NULL;
     END;
   END;

   IF VL_VALIDA_CART = 1 AND VL_ERROR IS NULL THEN

     BEGIN
       SELECT MIN (TBRACCD_EFFECTIVE_DATE)
         INTO VL_FECHA_VALIDA
         FROM TBRACCD
        WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
              AND TBRACCD_DOCUMENT_NUMBER IS NULL
              AND TBRACCD_FEED_DATE = VL_FECHA_INICIO
              AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) >= LAST_DAY(TRUNC(SYSDATE))
              AND TBRACCD_BALANCE > 0
              AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                 FROM SORLCUR
                                                WHERE     SORLCUR_PIDM = P_PIDM
                                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                      AND SORLCUR_ROLL_IND  = 'Y'
                                                      AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                      AND SORLCUR_PROGRAM = P_PROGRAMA)
              AND TBRACCD_PIDM = P_PIDM;
     END;

      --DBMS_OUTPUT.PUT_LINE('antes reza '||VL_FECHA_INICIO||' = '||P_PIDM||' = '||P_PROGRAMA||' = '||VL_FECHA_VALIDA);

     IF VL_FECHA_VALIDA IS NULL THEN
       VL_SALTO:=2;
       VL_SALTO_PARC:=1;

       BEGIN
         SELECT MAX (TBRACCD_EFFECTIVE_DATE)
           INTO VL_FECHA_VALIDA
           FROM TBRACCD
          WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                AND TBRACCD_DOCUMENT_NUMBER IS NULL
                AND TBRACCD_FEED_DATE = VL_FECHA_INICIO
                AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                   FROM SORLCUR
                                                  WHERE     SORLCUR_PIDM = P_PIDM
                                                        AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                        AND SORLCUR_ROLL_IND  = 'Y'
                                                        AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                        AND SORLCUR_PROGRAM = P_PROGRAMA)
                AND TBRACCD_PIDM = P_PIDM;
       END;

     ELSE

       VL_SALTO:= TO_CHAR((VL_FECHA_VALIDA),'MM') - TO_CHAR((VL_FECHA_INICIO+12),'MM');

     END IF;

   ELSIF VL_VALIDA_CART = 0 AND VL_FECHA_INICIO IS NOT NULL AND VL_ERROR IS NULL  THEN

     VL_SALTO:=2;
     VL_SALTO_PARC:=1;

     BEGIN
       SELECT TBRACCD_EFFECTIVE_DATE
        INTO VL_FECHA_VALIDA
        FROM TBRACCD
       WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
             AND TBRACCD_DOCUMENT_NUMBER IS NULL
             AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1))
             AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                FROM SORLCUR
                                               WHERE     SORLCUR_PIDM = P_PIDM
                                                     AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                     AND SORLCUR_ROLL_IND  = 'Y'
                                                     AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                     AND SORLCUR_PROGRAM = P_PROGRAMA)
             AND TBRACCD_PIDM = P_PIDM;
     END;
   END IF;

   BEGIN
     SELECT NVL(SUM(TBRACCD_BALANCE),0)
       INTO VL_SALDO_VENCIDO
       FROM TBRACCD A
      WHERE     A.TBRACCD_PIDM = P_PIDM
            AND A.TBRACCD_TRAN_NUMBER IN (SELECT TBRACCD_TRAN_NUMBER TRAN
                                            FROM TBRACCD
                                           WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                                 AND (TBRACCD_FEED_DATE < VL_FECHA_INICIO OR TBRACCD_FEED_DATE IS NULL)
                                                 AND TBRACCD_BALANCE > 0
                                           UNION
                                          SELECT TBRACCD_TRAN_NUMBER TRAN
                                            FROM TBRACCD
                                           WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                                 AND TBRACCD_FEED_DATE = VL_FECHA_INICIO
                                                 AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) < LAST_DAY(TRUNC(SYSDATE))
                                                 AND TBRACCD_BALANCE > 0);

   END;

   BEGIN /* CALCULO DE COMPLEMENTO */

     BEGIN
       SELECT ADD_MONTHS(TBRACCD_EFFECTIVE_DATE,(VL_SALTO_PARC+(P_MESES-1)))
         INTO VL_FECHA_COMPLE
         FROM TBRACCD D
         WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
               AND TBRACCD_EFFECTIVE_DATE = VL_FECHA_VALIDA
               AND TBRACCD_PIDM = P_PIDM
               AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                 FROM SORLCUR
                                                WHERE     SORLCUR_PIDM = P_PIDM
                                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                      AND SORLCUR_ROLL_IND  = 'Y'
                                                      AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                      AND SORLCUR_PROGRAM = P_PROGRAMA);
     EXCEPTION
     WHEN OTHERS THEN
     VL_FECHA_COMPLE:=NULL;
     END;

     BEGIN
       SELECT TRUNC(TBRACCD_EFFECTIVE_DATE),TBRACCD_AMOUNT,(TBRACCD_AMOUNT-TBRACCD_BALANCE)
         INTO VL_COMPLE_EDC,VL_MONTO_COMPL,VL_DIFERE_COMPLE
         FROM TBRACCD
        WHERE     TBRACCD_PIDM = P_PIDM
              AND TBRACCD_DESC LIKE '%COMPLEMENTO%'
              AND TBRACCD_BALANCE > 0
              AND TBRACCD_FEED_DATE = VL_FECHA_INICIO
              AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                  FROM SORLCUR
                                                 WHERE     SORLCUR_PIDM = P_PIDM
                                                       AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                       AND SORLCUR_ROLL_IND  = 'Y'
                                                       AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                       AND SORLCUR_PROGRAM = P_PROGRAMA);
     EXCEPTION
     WHEN OTHERS THEN
       BEGIN
         SELECT DISTINCT TZFACCE_EFFECTIVE_DATE,TZFACCE_AMOUNT,0
           INTO VL_COMPLE_EDC,VL_MONTO_COMPL,VL_DIFERE_COMPLE
           FROM TZFACCE A
          WHERE     A.TZFACCE_PIDM = P_PIDM
                AND A.TZFACCE_DESC LIKE '%COMPLEMENTO%'
                AND A.TZFACCE_FLAG = 0
                AND A.TZFACCE_STUDY = (SELECT MAX(TZFACCE_STUDY)
                                         FROM TZFACCE
                                        WHERE     TZFACCE_STUDY IS NOT NULL
                                              AND TZFACCE_PIDM = A.TZFACCE_PIDM);
       EXCEPTION
       WHEN OTHERS THEN
       VL_COMPLE_EDC:=NULL;
       VL_MONTO_COMPL:=NULL;
       VL_DIFERE_COMPLE:=NULL;
       END;
     END;

     BEGIN
       SELECT
              CASE

                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 0 AND 3  THEN 1
                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 4 AND 7  THEN 2
                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 8 AND 11 THEN 3
                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 12 AND 15 THEN 4
                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 16 AND 19THEN 5
                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 20 AND 23 THEN 6
                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 24 AND 27 THEN 7
                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 28 AND 31 THEN 8
                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 32 AND 35 THEN 9
                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 36 AND 39 THEN 10
                WHEN MONTHS_BETWEEN(VL_FECHA_COMPLE,VL_COMPLE_EDC) BETWEEN 40 AND 43 THEN 11
              ELSE 0
              END
       INTO VL_NUMERO_COMP
       FROM DUAL;
     END;

   END;

--    DBMS_OUTPUT.PUT_LINE('entra cursor = VL_FECHA_INICIO = '
--                             ||VL_FECHA_INICIO||', VL_FECHA_VALIDA = '
--                             ||VL_FECHA_VALIDA||', VL_SALTO = '
--                             ||VL_SALTO||', VL_SALTO_PARC = '
--                             ||VL_SALTO_PARC||', VL_NUMERO_COMP = '
--                             ||VL_NUMERO_COMP||', VL_COMPLE_EDC = '
--                             ||VL_COMPLE_EDC||', VL_MONTO_COMPL = '
--                             ||VL_MONTO_COMPL||', VL_DIFERE_COMPLE = '
--                             ||VL_DIFERE_COMPLE||', VL_SALDO_VENCIDO = '
--                             ||VL_SALDO_VENCIDO||', VL_FECHA_COMPLE = '
--                             ||VL_FECHA_COMPLE
--                                              );

   IF VL_ERROR IS NULL THEN
       BEGIN
           OPEN SALDO_PUNI
            FOR

               SELECT SUM(SALDO) SALDO_TOTAL,
                      SUM(DESCUENTO) DESCUENTO_TOTAL,
                      SUM(SALDO)-SUM(DESCUENTO)+SUM((CASE WHEN SALDO_FAVOR < 0 THEN SALDO_FAVOR ELSE 0 END)/P_MESES) TOTAL_A_PAGAR,
                      SUM((CASE WHEN SALDO_FAVOR < 0 THEN SALDO_FAVOR ELSE 0 END)/P_MESES) SALDO_FAVOR,
                      SUM(PORCENTAJE/P_MESES)PORCENTAJE,
                      VL_SALDO_VENCIDO SALDO_VENCIDO,
                      NVL(VL_NUMERO_COMP,0) NUM_COMPLEMENTO,
                      NVL((VL_NUMERO_COMP*VL_MONTO_COMPL) - VL_DIFERE_COMPLE,0) MONTO_COMPLEMENTO
                 FROM (SELECT ROUND
                               (CASE
                                 WHEN BALANCE != 0 AND NUMERO = 1 THEN BALANCE
                                ELSE
                                   CASE
                                     WHEN INCREMENTO > 0 THEN INCREMENTO*(MONTO)
                                     WHEN INCREMENTO = 0 THEN MONTO
                                   ELSE
                                      CASE
                                         WHEN MESES_CURSADOS IS NULL THEN MONTO
                                         WHEN MESES_CURSADOS < 12 THEN MONTO
                                         WHEN MESES_CURSADOS = 12 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN MONTO
                                         WHEN MESES_CURSADOS BETWEEN 13 AND 23 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN (1.05)*(MONTO)
                                         WHEN MESES_CURSADOS = 24 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN (1.05)*(MONTO)
                                         WHEN MESES_CURSADOS > 24 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN (1.10)*(MONTO)
                                      END
                                   END
                               END,0) SALDO,
                               (FLOOR
                               (CASE
                                 WHEN BALANCE != 0 AND NUMERO = 1 THEN BALANCE
                                ELSE
                                   CASE
                                     WHEN INCREMENTO > 0 THEN INCREMENTO*(MONTO)
                                     WHEN INCREMENTO = 0 THEN MONTO
                                   ELSE
                                      CASE
                                         WHEN MESES_CURSADOS IS NULL THEN MONTO
                                         WHEN MESES_CURSADOS < 12 THEN MONTO
                                         WHEN MESES_CURSADOS = 12 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN MONTO
                                         WHEN MESES_CURSADOS BETWEEN 13 AND 23 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN (1.05)*(MONTO)
                                         WHEN MESES_CURSADOS = 24 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN (1.05)*(MONTO)
                                         WHEN MESES_CURSADOS > 24 AND (TO_CHAR(PARCIALIDAD,'MM')-1) IN (1,3,5,7,9,11) THEN (1.10)*(MONTO)
                                      END
                                   END
                               END*(SELECT ZSTPARA_PARAM_VALOR/100
                                         FROM ZSTPARA
                                        WHERE ZSTPARA_MAPA_ID = 'PAGUNI_SIU'
                                              AND P_MESES BETWEEN ZSTPARA_PARAM_ID AND ZSTPARA_PARAM_DESC)))descuento,
                              SALDO_FAVOR,
                              PORCENTAJE
                          FROM (SELECT NUMERO,
                                       TBRACCD_PIDM PIDM,
                                       TBRACCD_DETAIL_CODE CODIGO,
                                       TBRACCD_DESC DESCRIPCION,
                                       TBRACCD_BALANCE BALANCE,
                                       TBRACCD_AMOUNT AMOUNT,
                                       ADD_MONTHS(TBRACCD_EFFECTIVE_DATE,((NUMERO-1)+0))PARCIALIDAD,
                                       PKG_FINANZAS_REZA.F_PARCIALIDAD ( D.TBRACCD_PIDM, D.TBRACCD_FEED_DATE ) MONTO,
                                       PKG_FINANZAS_REZA.F_MESES_GENERAL ( TBRACCD_PIDM)+((CASE SIN_INCRE WHEN 1 THEN 1 ELSE NUMERO END -1)+0) MESES_CURSADOS,
                                       CASE
                                         WHEN PKG_FINANZAS_REZA.F_MESES_GENERAL ( TBRACCD_PIDM)+((CASE SIN_INCRE WHEN 1 THEN 1 ELSE NUMERO END-1)+0) < 12 THEN 0
                                         WHEN PKG_FINANZAS_REZA.F_MESES_GENERAL ( TBRACCD_PIDM)+((CASE SIN_INCRE WHEN 1 THEN 1 ELSE NUMERO END-1)+0) BETWEEN 12 AND 23 THEN 1.05
                                         WHEN PKG_FINANZAS_REZA.F_MESES_GENERAL ( TBRACCD_PIDM)+((CASE SIN_INCRE WHEN 1 THEN 1 ELSE NUMERO END-1)+0) >= 24 THEN 1.10
                                       END INCREMENTO,
                                       (SELECT SUM (TBRACCD_BALANCE)
                                          FROM TBRACCD
                                         WHERE     TBRACCD_PIDM = D.TBRACCD_PIDM
                                               AND TRUNC(TBRACCD_EFFECTIVE_DATE) <= TRUNC(SYSDATE))SALDO_FAVOR,
                                       (SELECT ZSTPARA_PARAM_VALOR
                                          FROM ZSTPARA
                                         WHERE     ZSTPARA_MAPA_ID = 'PAGUNI_SIU'
                                               AND P_MESES BETWEEN ZSTPARA_PARAM_ID AND ZSTPARA_PARAM_DESC)PORCENTAJE
                                  FROM TBRACCD D,(SELECT DISTINCT
                                                         TZFACCE_SEC_PIDM NUMERO,
                                                         (SELECT COUNT(DISTINCT TBRACCD_PIDM)
                                                            FROM TBRACCD CCD
                                                           WHERE     CCD.TBRACCD_PIDM = P_PIDM
                                                                 AND SUBSTR(CCD.TBRACCD_DETAIL_CODE,3,2) IN ('RM','RN','RP')
                                                                 AND CCD.TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                                                                         FROM SORLCUR
                                                                                                        WHERE     SORLCUR_PIDM = P_PIDM
                                                                                                              AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                              AND SORLCUR_ROLL_IND  = 'Y'
                                                                                                              AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                                              AND SORLCUR_PROGRAM = P_PROGRAMA
                                                                                                              ))SIN_INCRE
                                                    FROM TZFACCE
                                                   WHERE TZFACCE_SEC_PIDM BETWEEN 1 AND 50
                                                   ORDER BY 1)
                                 WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                       AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                       AND TBRACCD_EFFECTIVE_DATE = VL_FECHA_VALIDA
                                       AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                                         FROM SORLCUR
                                                                        WHERE     SORLCUR_PIDM = P_PIDM
                                                                              AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                              AND SORLCUR_ROLL_IND  = 'Y'
                                                                              AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                              AND SORLCUR_PROGRAM = P_PROGRAMA)
                                       AND NUMERO BETWEEN 1 AND P_MESES
                                       AND TBRACCD_PIDM = P_PIDM
                                ORDER BY 1)
                         WHERE 1=1)
                WHERE 1=1;
           RETURN (SALDO_PUNI);
       END;

   ELSE
     BEGIN
       OPEN SALDO_PUNI
        FOR
         SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
         FROM DUAL;
         RETURN (SALDO_PUNI);
     END;
   END IF;
 END F_SALDOS_PAGOUNICO;

FUNCTION F_PARCIALIDAD (P_PIDM NUMBER, P_FECHA DATE )RETURN NUMBER IS

VL_PARCIALIDAD      NUMBER;

BEGIN
  BEGIN
        SELECT DISTINCT
               ROUND(((SELECT  A.SFRRGFE_MAX_CHARGE
               FROM SFRRGFE A , TBBDETC
               WHERE TBBDETC_DETAIL_CODE = A.SFRRGFE_DETL_CODE
               AND  A.SFRRGFE_TERM_CODE= PERIODO
               AND A.SFRRGFE_TYPE = 'STUDENT'
               AND A.SFRRGFE_ENTRY_TYPE = 'R'
               AND A.SFRRGFE_LEVL_CODE = NIVEL
               AND A.SFRRGFE_CAMP_CODE = CAMPUS
               AND A.SFRRGFE_ATTS_CODE = JORNADA--ALUMNO.JORNADA
               AND A.SFRRGFE_RATE_CODE = RATE
               AND NVL(A.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
               AND NVL(A.SFRRGFE_PROGRAM,'SIN') = PRO_SFR
               AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                      FROM SFRRGFE A1
                                      WHERE A1.SFRRGFE_TERM_CODE=A.SFRRGFE_TERM_CODE
                                      AND A1.SFRRGFE_TYPE=A.SFRRGFE_TYPE
                                      AND A1.SFRRGFE_ENTRY_TYPE=A.SFRRGFE_ENTRY_TYPE
                                      AND A1.SFRRGFE_LEVL_CODE=A.SFRRGFE_LEVL_CODE
                                      AND A1.SFRRGFE_CAMP_CODE=A.SFRRGFE_CAMP_CODE
                                      AND A1.SFRRGFE_ATTS_CODE=A.SFRRGFE_ATTS_CODE
                                      AND A1.SFRRGFE_RATE_CODE=A.SFRRGFE_RATE_CODE
                                      AND NVL(A1.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
                                      AND NVL(A1.SFRRGFE_PROGRAM,'SIN') = PRO_SFR)) - NVL(MONTO_DSI,0) - NVL(((SELECT A.SFRRGFE_MAX_CHARGE
               FROM SFRRGFE A , TBBDETC
               WHERE TBBDETC_DETAIL_CODE = A.SFRRGFE_DETL_CODE
               AND  A.SFRRGFE_TERM_CODE= PERIODO
               AND A.SFRRGFE_TYPE = 'STUDENT'
               AND A.SFRRGFE_ENTRY_TYPE = 'R'
               AND A.SFRRGFE_LEVL_CODE = NIVEL
               AND A.SFRRGFE_CAMP_CODE = CAMPUS
               AND A.SFRRGFE_ATTS_CODE = JORNADA--ALUMNO.JORNADA
               AND A.SFRRGFE_RATE_CODE = RATE
               AND NVL(A.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
               AND NVL(A.SFRRGFE_PROGRAM,'SIN') = PRO_SFR
               AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                      FROM SFRRGFE A1
                                      WHERE A1.SFRRGFE_TERM_CODE=A.SFRRGFE_TERM_CODE
                                      AND A1.SFRRGFE_TYPE=A.SFRRGFE_TYPE
                                      AND A1.SFRRGFE_ENTRY_TYPE=A.SFRRGFE_ENTRY_TYPE
                                      AND A1.SFRRGFE_LEVL_CODE=A.SFRRGFE_LEVL_CODE
                                      AND A1.SFRRGFE_CAMP_CODE=A.SFRRGFE_CAMP_CODE
                                      AND A1.SFRRGFE_ATTS_CODE=A.SFRRGFE_ATTS_CODE
                                      AND A1.SFRRGFE_RATE_CODE=A.SFRRGFE_RATE_CODE
                                      AND NVL(A1.SFRRGFE_DEPT_CODE,'0') = nvl(PRE_ACTUALIZADO,'0')
                                      AND NVL(A1.SFRRGFE_PROGRAM,'SIN') = PRO_SFR))*DESCUENTO/100),0))/NUM_PAG)PARCIALIDAD
        INTO VL_PARCIALIDAD
        FROM(SELECT DISTINCT
                SORLCUR_PIDM PIDM,
                SORLCUR_KEY_SEQNO STUDY,
                SORLCUR_PROGRAM PROGRAMA,
                SORLCUR_RATE_CODE RATE,
                SORLCUR_CAMP_CODE CAMPUS,
                SPRIDEN_ID,
                SORLCUR_START_DATE,
                SORLCUR_LEVL_CODE NIVEL,
                SFRSTCR_TERM_CODE PERIODO,
                SFRSTCR_PTRM_CODE PPARTE,
                SSBSECT_PTRM_START_DATE FECHA,
                NVL((SELECT NVL(SFRRGFE_PROGRAM,'SIN')
                FROM SFRRGFE A , TBBDETC
                WHERE TBBDETC_DETAIL_CODE = A.SFRRGFE_DETL_CODE
                AND  A.SFRRGFE_TERM_CODE= F.SFRSTCR_TERM_CODE
                AND A.SFRRGFE_TYPE = 'STUDENT'
                AND A.SFRRGFE_ENTRY_TYPE = 'R'
                AND A.SFRRGFE_LEVL_CODE = A.SORLCUR_LEVL_CODE
                AND A.SFRRGFE_CAMP_CODE = A.SORLCUR_CAMP_CODE
                AND A.SFRRGFE_ATTS_CODE = (SELECT MAX (T.SGRSATT_ATTS_CODE)
                                            FROM SGRSATT T
                                            WHERE T.SGRSATT_PIDM = A.SORLCUR_PIDM
                                            AND T.SGRSATT_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                                            AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
                                            AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                            AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                                                               FROM SGRSATT TT
                                                                               WHERE  TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                                               AND  TT.SGRSATT_STSP_KEY_SEQUENCE= T.SGRSATT_STSP_KEY_SEQUENCE
                                                                               AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                                               AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]'))
                                            AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                                                           FROM SGRSATT T1
                                                                           WHERE T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                                                           AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                                                           AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                                                           AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                                           AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')))
                AND A.SFRRGFE_RATE_CODE = A.SORLCUR_RATE_CODE
                AND nvl(A.SFRRGFE_DEPT_CODE,0) = nvl((SELECT DISTINCT NVL(SORLCUR_SITE_CODE,0)
                                          FROM SORLCUR CUR
                                          WHERE CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                                          AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                          AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                                   FROM SORLCUR CUR2
                                                                   WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                                   AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE)),'0')
                AND A.SFRRGFE_PROGRAM = A.SORLCUR_PROGRAM
                AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                      FROM SFRRGFE A1
                                      WHERE A1.SFRRGFE_TERM_CODE=A.SFRRGFE_TERM_CODE
                                      AND A1.SFRRGFE_TYPE=A.SFRRGFE_TYPE
                                      AND A1.SFRRGFE_ENTRY_TYPE=A.SFRRGFE_ENTRY_TYPE
                                      AND A1.SFRRGFE_LEVL_CODE=A.SFRRGFE_LEVL_CODE
                                      AND A1.SFRRGFE_CAMP_CODE=A.SFRRGFE_CAMP_CODE
                                      AND A1.SFRRGFE_ATTS_CODE=A.SFRRGFE_ATTS_CODE
                                      AND A1.SFRRGFE_RATE_CODE=A.SFRRGFE_RATE_CODE
                                      AND nvl(A1.SFRRGFE_DEPT_CODE,0) = nvl((SELECT DISTINCT NVL(SORLCUR_SITE_CODE,'0')
                                                                  FROM SORLCUR CUR
                                                                  WHERE CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                  AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                                                  AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                                                           FROM SORLCUR CUR2
                                                                                           WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                                                           AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE)),'0')
                                      AND A1.SFRRGFE_PROGRAM = A.SORLCUR_PROGRAM)),'SIN')PRO_SFR,
                (SELECT DISTINCT NVL(SORLCUR_SITE_CODE,0)
                              FROM SORLCUR CUR
                              WHERE CUR.SORLCUR_PIDM = A.SORLCUR_PIDM
                              AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                              AND CUR.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                       FROM SORLCUR CUR2
                                                       WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                       AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE))PRE_ACTUALIZADO,
               (SELECT T.SGRSATT_ATTS_CODE
                FROM SGRSATT T
                WHERE T.SGRSATT_PIDM = A.SORLCUR_PIDM
                AND T.SGRSATT_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
                AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                                   FROM SGRSATT TT
                                                   WHERE  TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                   AND  TT.SGRSATT_STSP_KEY_SEQUENCE= T.SGRSATT_STSP_KEY_SEQUENCE
                                                   AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                                   AND REGEXP_LIKE  (TT.SGRSATT_ATTS_CODE , '^[0-9]'))
                AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                               FROM SGRSATT T1
                                               WHERE T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                               AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                               AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                               AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,2) NOT IN (81,82,83,90)
                                               AND REGEXP_LIKE  (T1.SGRSATT_ATTS_CODE , '^[0-9]')))JORNADA,
               (SELECT TBREDET_PERCENT
                FROM TBBEXPT, TBBESTU A, TBBDETC, TBREDET
                WHERE TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                AND TBBDETC_TAXT_CODE = A.SORLCUR_LEVL_CODE
                AND A.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                AND A.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                AND A.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                AND A.TBBESTU_DEL_IND IS NULL
                AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                AND A.TBBESTU_TERM_CODE = (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                             FROM TBBESTU A1,TBBEXPT,TBREDET
                                            WHERE A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                  AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                  AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                  AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                  AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                  AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                  AND A1.TBBESTU_DEL_IND IS NULL
                                                  AND A1.TBBESTU_TERM_CODE <= F.SFRSTCR_TERM_CODE)
                AND A.TBBESTU_EXEMPTION_PRIORITY = (SELECT MAX(TBBESTU_EXEMPTION_PRIORITY)
                                                    FROM TBBEXPT, TBBESTU A1, TBBDETC, TBREDET
                                                    WHERE TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                                    AND A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                    AND TBBDETC_TAXT_CODE = A.SORLCUR_LEVL_CODE
                                                    AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                    AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                    AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                                                    AND A1.TBBESTU_DEL_IND IS NULL
                                                    AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                    AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                    AND A1.TBBESTU_TERM_CODE = (SELECT MAX(A2.TBBESTU_TERM_CODE)
                                                                                 FROM TBBESTU A2,TBBEXPT,TBREDET
                                                                                WHERE A2.TBBESTU_PIDM = A1.TBBESTU_PIDM
                                                                                      AND A2.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                                                      AND A2.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                                                      AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                                                      AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                                                      AND A2.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                                                      AND A2.TBBESTU_DEL_IND IS NULL
                                                                                      AND A2.TBBESTU_TERM_CODE <= F.SFRSTCR_TERM_CODE)
                                                    )
                AND TBBESTU_PIDM = A.SORLCUR_PIDM
                AND TBBDETC_DCAT_CODE = 'DSP')DESCUENTO,
                (SELECT TBBESTU_EXEMPTION_CODE
                FROM TBBEXPT, TBBESTU A, TBBDETC, TBREDET
                WHERE TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                AND TBBDETC_TAXT_CODE = A.SORLCUR_LEVL_CODE
                AND A.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                AND A.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                AND A.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                AND A.TBBESTU_DEL_IND IS NULL
                AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                AND A.TBBESTU_TERM_CODE = (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                             FROM TBBESTU A1,TBBEXPT,TBREDET
                                            WHERE A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                  AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                  AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                  AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                  AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                  AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                  AND A1.TBBESTU_DEL_IND IS NULL
                                                  AND A1.TBBESTU_TERM_CODE <= F.SFRSTCR_TERM_CODE)
                AND A.TBBESTU_EXEMPTION_PRIORITY = (SELECT MAX(TBBESTU_EXEMPTION_PRIORITY)
                                                    FROM TBBEXPT, TBBESTU A1, TBBDETC, TBREDET
                                                    WHERE TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                                    AND TBBDETC_TAXT_CODE = A.SORLCUR_LEVL_CODE
                                                    AND A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                    AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                    AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                    AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                                                    AND A1.TBBESTU_DEL_IND IS NULL
                                                    AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                    AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                    AND A1.TBBESTU_TERM_CODE = (SELECT MAX(A2.TBBESTU_TERM_CODE)
                                                                                 FROM TBBESTU A2,TBBEXPT,TBREDET
                                                                                WHERE A2.TBBESTU_PIDM = A1.TBBESTU_PIDM
                                                                                      AND A2.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                                                      AND A2.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                                                      AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                                                      AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                                                      AND A2.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                                                      AND A2.TBBESTU_DEL_IND IS NULL
                                                                                      AND A2.TBBESTU_TERM_CODE <= F.SFRSTCR_TERM_CODE))
                AND TBBESTU_PIDM = A.SORLCUR_PIDM
                AND TBBDETC_DCAT_CODE = 'DSP')DESC_COD,
                (
                SELECT DISTINCT TZTDMTO_MONTO
                FROM TZTDMTO A
                WHERE A.TZTDMTO_PIDM   = A.SORLCUR_PIDM
                AND   A.TZTDMTO_CAMP_CODE = A.SORLCUR_CAMP_CODE
                AND  A.TZTDMTO_NIVEL  = A.SORLCUR_LEVL_CODE
                AND A.TZTDMTO_PROGRAMA =  A.SORLCUR_PROGRAM
                AND A.TZTDMTO_IND = 1
                AND A.TZTDMTO_STUDY_PATH = A.SORLCUR_KEY_SEQNO
                AND ( A.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                     OR A.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                               FROM TZTDMTO TZT
                                               WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                               AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                               AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                               AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                               AND TZT.TZTDMTO_IND = 1
                                               AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                               AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE))
                AND A.TZTDMTO_ACTIVITY_DATE = (SELECT MAX (A1.TZTDMTO_ACTIVITY_DATE)
                                                FROM TZTDMTO A1
                                                WHERE A1.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                AND   A1.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                AND  A1.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                AND A1.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                AND A1.TZTDMTO_IND = 1
                                                AND A1.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                AND ( A1.TZTDMTO_TERM_CODE  = F.SFRSTCR_TERM_CODE
                                                      OR A1.TZTDMTO_TERM_CODE = (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                                 FROM TZTDMTO TZT
                                                                                 WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                                 AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                                 AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                                 AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                                 AND TZT.TZTDMTO_IND = 1
                                                                                 AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                                 AND TZT.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE)))
                 AND A.TZTDMTO_TERM_CODE  <= F.SFRSTCR_TERM_CODE
                 AND ROWNUM = 1)MONTO_DSI,
                CASE
                SUBSTR (SORLCUR_RATE_CODE, 1, 1)
                WHEN  ('P') THEN SUBSTR (SORLCUR_RATE_CODE, 2, 2)
                WHEN  ('C') THEN SUBSTR (SORLCUR_RATE_CODE, 3, 1)-- Se agrega
                WHEN  ('J') THEN SUBSTR (SORLCUR_RATE_CODE, 3, 1)
                END NUM_PAG,
                SFRSTCR_VPDI_CODE FOLIO
        FROM SORLCUR A, SPRIDEN D, SFRSTCR F, SSBSECT G, SZTDTEC E
        WHERE A.SORLCUR_PIDM = D.SPRIDEN_PIDM
        AND A.SORLCUR_LMOD_CODE = 'LEARNER'
        AND A.SORLCUR_ROLL_IND  = 'Y'
        AND A.SORLCUR_CACT_CODE = 'ACTIVE'
        AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                               FROM SORLCUR A1
                               WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                               AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                               AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                               AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                               AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
        AND A.SORLCUR_TERM_CODE_CTLG = E.SZTDTEC_TERM_CODE
        AND D.SPRIDEN_CHANGE_IND IS NULL
        AND F.SFRSTCR_PIDM = A.SORLCUR_PIDM
        AND F.SFRSTCR_RSTS_CODE = 'RE'
        AND F.SFRSTCR_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
        AND F.SFRSTCR_TERM_CODE = G.SSBSECT_TERM_CODE
        AND SUBSTR(F.SFRSTCR_TERM_CODE,5,1) NOT IN (8,9)
        AND (SFRSTCR_RESERVED_KEY NOT IN ('M1HB401', 'CP001', 'CPB13001') OR SFRSTCR_RESERVED_KEY IS NULL )
        AND (F.SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR F.SFRSTCR_DATA_ORIGIN IS NULL)
        AND (F.SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR SFRSTCR_DATA_ORIGIN IS NULL)
        AND (F.SFRSTCR_USER_ID != 'MIGRA_D' OR F.SFRSTCR_USER_ID IS NULL)
        AND F.SFRSTCR_CRN = G.SSBSECT_CRN
        AND F.SFRSTCR_PTRM_CODE = G.SSBSECT_PTRM_CODE
        AND G.SSBSECT_PTRM_START_DATE = P_FECHA
        AND D.SPRIDEN_PIDM = P_PIDM );
  EXCEPTION
  WHEN OTHERS THEN
  VL_PARCIALIDAD:=0;
  END;
  RETURN(VL_PARCIALIDAD);
END F_PARCIALIDAD;

FUNCTION F_INSERTA_PGOUNI (P_PIDM           NUMBER,
                           P_MATRICULA      VARCHAR2,
                           P_MONTO          NUMBER,
                           P_MESES          NUMBER,
                           P_FECHA_PAR      DATE,
                           P_PROGRAMA       VARCHAR2,
                           P_IND_COMPLE     NUMBER)RETURN VARCHAR2 IS

 VL_CODIGO          VARCHAR2(5);
 VL_ERROR           VARCHAR2(900);
 VL_PERIODO         VARCHAR2(12);
 VL_PORCENTAJE      NUMBER;
 VL_FECHA_INICIO    DATE;
 VL_INTER           NUMBER:=0;
 VL_PERIODO_CTL     VARCHAR2(20);
 VL_PERIODICIDAD    NUMBER;

 BEGIN

   BEGIN
     SELECT DISTINCT SORLCUR_TERM_CODE_CTLG
       INTO VL_PERIODO_CTL
       FROM SORLCUR A
      WHERE     A.SORLCUR_LMOD_CODE = 'LEARNER'
            AND A.SORLCUR_ROLL_IND  = 'Y'
            AND A.SORLCUR_CACT_CODE = 'ACTIVE' --Va?
            AND A.SORLCUR_PROGRAM = P_PROGRAMA
            AND A.SORLCUR_SEQNO = (SELECT MAX(A1.SORLCUR_SEQNO)
                                     FROM SORLCUR A1
                                    WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                          AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                          AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                          AND A1.SORLCUR_PROGRAM = P_PROGRAMA
                                          AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
            AND A.SORLCUR_PIDM =  P_PIDM;

   EXCEPTION
   WHEN OTHERS THEN

     BEGIN
       SELECT DISTINCT SORLCUR_TERM_CODE_CTLG
         INTO VL_PERIODO_CTL
         FROM SORLCUR A
        WHERE     A.SORLCUR_LMOD_CODE = 'LEARNER'
              AND A.SORLCUR_PROGRAM = P_PROGRAMA
              AND A.SORLCUR_SEQNO = (SELECT MAX(A1.SORLCUR_SEQNO)
                                     FROM SORLCUR A1
                                     WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                     AND A1.SORLCUR_PROGRAM = P_PROGRAMA
                                     AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
              AND A.SORLCUR_PIDM =  P_PIDM;
     EXCEPTION
     WHEN OTHERS THEN
     VL_PERIODO_CTL:=NULL;
     END;

   END;

   BEGIN
     SELECT DECODE (SZTDTEC_PERIODICIDAD, 1,2,2,4,3,6,4,12)
       INTO VL_PERIODICIDAD
       FROM SZTDTEC
      WHERE     SZTDTEC_PROGRAM = P_PROGRAMA
            AND SZTDTEC_TERM_CODE = VL_PERIODO_CTL;
   END;

   BEGIN
     SELECT SUBSTR(P_MATRICULA,1,2)||ZSTPARA_PARAM_VALOR
       INTO VL_CODIGO
       FROM ZSTPARA
      WHERE     ZSTPARA_MAPA_ID = 'AJU_PAGOUNI'
            AND ZSTPARA_PARAM_ID IN (SELECT DISTINCT SORLCUR_LEVL_CODE
                                       FROM SORLCUR A
                                      WHERE     A.SORLCUR_PIDM = P_PIDM
                                            AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                                            AND A.SORLCUR_PROGRAM = P_PROGRAMA
                                            AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                                    FROM SORLCUR A1
                                                                    WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                    AND A1.SORLCUR_PROGRAM = P_PROGRAMA
                                                                    AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE));
   EXCEPTION
   WHEN OTHERS THEN
   VL_ERROR:='ERROR AL OBTENER EL CODIGO DE DETALLE = '||SQLERRM;
   END;

   BEGIN
     SELECT DISTINCT TBRACCD_FEED_DATE,TBRACCD_TERM_CODE
       INTO VL_FECHA_INICIO,VL_PERIODO
       FROM TBRACCD
      WHERE     TBRACCD_PIDM = P_PIDM
            AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
            AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(P_FECHA_PAR)
            AND TBRACCD_DOCUMENT_NUMBER IS NULL
            AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                               FROM SORLCUR
                                              WHERE     SORLCUR_PIDM = P_PIDM
                                                    AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                    AND SORLCUR_ROLL_IND  = 'Y'
                                                    AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                    AND SORLCUR_PROGRAM = P_PROGRAMA);
   EXCEPTION
   WHEN OTHERS THEN
   VL_FECHA_INICIO:=NULL;
   END;

   BEGIN
      SELECT ZSTPARA_PARAM_VALOR
        INTO VL_PORCENTAJE
        FROM ZSTPARA
       WHERE     ZSTPARA_MAPA_ID = 'PAGUNI_SIU'
             AND P_MESES BETWEEN ZSTPARA_PARAM_ID AND ZSTPARA_PARAM_DESC;
   EXCEPTION
   WHEN OTHERS THEN
   VL_ERROR:='ERROR AL CALCULAR PORCENTAJE';
   END;

   IF LAST_DAY(VL_FECHA_INICIO+12) = LAST_DAY(P_FECHA_PAR) THEN
     VL_INTER:=1;
   END IF;

   IF VL_FECHA_INICIO IS NULL THEN
     VL_FECHA_INICIO:=(P_FECHA_PAR-(TO_NUMBER(TO_CHAR(P_FECHA_PAR,'DD')-1)));

       BEGIN
         SELECT TBRACCD_TERM_CODE
           INTO VL_PERIODO
           FROM TBRACCD
          WHERE     TBRACCD_PIDM = P_PIDM
                AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(ADD_MONTHS(P_FECHA_PAR,-1))
                AND TBRACCD_DOCUMENT_NUMBER IS NULL
                AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                   FROM SORLCUR
                                                  WHERE     SORLCUR_PIDM = P_PIDM
                                                        AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                        AND SORLCUR_ROLL_IND  = 'Y'
                                                        AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                        AND SORLCUR_PROGRAM = P_PROGRAMA);
       EXCEPTION
       WHEN OTHERS THEN
       VL_PERIODO:=NULL;
       END;
   ELSE
     VL_FECHA_INICIO:=VL_FECHA_INICIO;
   END IF;

--   VL_PERIODO:= FGET_PERIODO_GENERAL ( SUBSTR(P_MATRICULA,1,2), VL_FECHA_INICIO);

   IF VL_ERROR IS NULL THEN

       BEGIN

         INSERT
           INTO TZTPUNI
               ( TZTPUNI_PIDM,
                 TZTPUNI_ID,
                 TZTPUNI_TERM_CODE,
                 TZTPUNI_FECHA_INICIO,
                 TZTPUNI_PROX_FECHA,
                 TZTPUNI_MONTO,
                 TZTPUNI_CODIGO,
                 TZTPUNI_REPLICA,
                 TZTPUNI_VECES,
                 TZTPUNI_ACTIVITY_DATE,
                 TZTPUNI_USER,
                 TZTPUNI_DATA_ORIGIN,
                 TZTPUNI_PORCENTAJE,
                 TZTPUNI_FINALIZADO,
                 TZTPUNI_OBSERVACIONES,
                 TZTPUNI_IND_COMPL)
          VALUES
                (P_PIDM,            -- PARAMETRO
                 P_MATRICULA,       -- VARIABLE
                 VL_PERIODO,        -- VARIABLE
                 VL_FECHA_INICIO,   -- VALIDAR SI TIENE CARTERA PARA FECHA INICIO DEL MES, DE LO CONTRARIO SYSDATE
                 VL_FECHA_INICIO,   -- VALIDAR SI TIENE CARTERA PARA ESE MES
                 P_MONTO,           -- PARAMETRO
                 VL_CODIGO,         -- VARIABLE
                 VL_PERIODICIDAD,   -- PERIODICIDAD
                 P_MESES,           -- PARAMETRO MESES
                 SYSDATE,
                 USER,
                 'UNICO_SIU',
                 VL_PORCENTAJE,          -- PORCENTAJE VARIABLE
                 VL_INTER,           -- VALIDAR SI COINCIDE EL MES VS LA FECHA INICIO
                 NULL,
                 P_IND_COMPLE
                 );
       END;
        VL_ERROR:='EXITO';
   END IF;
  COMMIT;
  RETURN(VL_ERROR);
 END F_INSERTA_PGOUNI;

FUNCTION F_APLICA_PUNI_SIU (P_PIDM   NUMBER)RETURN VARCHAR2 IS

VL_ENTRA        NUMBER;
VL_FECHA        DATE;
VL_EXI_TBRA     NUMBER;
VL_PAGO_UNICO   VARCHAR2(900);

BEGIN
  BEGIN
    SELECT COUNT(*)
    INTO VL_ENTRA
      FROM TZTPUNI
     WHERE     TZTPUNI_PIDM = P_PIDM
           AND TZTPUNI_DATA_ORIGIN = 'UNICO_SIU'
           AND TZTPUNI_CHECH_FINAL IS NULL;
  END;

  IF VL_ENTRA > 0 THEN
    BEGIN
       SELECT TZTPUNI_PROX_FECHA
         INTO VL_FECHA
         FROM TZTPUNI
        WHERE     TZTPUNI_PIDM = P_PIDM
              AND TZTPUNI_DATA_ORIGIN = 'UNICO_SIU'
              AND TZTPUNI_CHECH_FINAL IS NULL;
    EXCEPTION
    WHEN OTHERS THEN
    VL_FECHA:=NULL;
    END;

    BEGIN
      SELECT COUNT(*)
        INTO VL_EXI_TBRA
        FROM TBRACCD A,TBBDETC
       WHERE TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
             AND TBRACCD_PIDM = P_PIDM
             AND TBRACCD_FEED_DATE = VL_FECHA
             AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
             AND TBRACCD_DOCUMENT_NUMBER IS NULL;
    END;

    IF VL_EXI_TBRA > 0 THEN
 --   DBMS_OUTPUT.PUT_LINE('ENTRA FUNCION DE PAGO UNICO ');
      VL_PAGO_UNICO := PKG_FINANZAS.F_DES_PAG_UNI ( P_PIDM, VL_FECHA);
    ELSE
      UPDATE TZTPUNI
         SET TZTPUNI_CHECK = 1
       WHERE     TZTPUNI_PIDM = P_PIDM
             AND TZTPUNI_DATA_ORIGIN = 'UNICO_SIU'
             AND TZTPUNI_CHECH_FINAL IS NULL
             AND TZTPUNI_PROX_FECHA = VL_FECHA;
    END IF;

  END IF;
 COMMIT;
RETURN(VL_PAGO_UNICO);
END F_APLICA_PUNI_SIU;

FUNCTION F_VALIDA_PAGOUNICO(P_PIDM      NUMBER,
                            P_PROGRAMA  VARCHAR2
                            )RETURN VARCHAR2 IS

VL_FECHA_INICIO     DATE;
VL_ERROR            VARCHAR2(900);
VL_CARGOS           NUMBER;
VL_PARCIALIDAD      NUMBER;
VL_ESCALONADO       NUMBER;
VL_SALDO            NUMBER;
VL_EXIS_PUNI        NUMBER;
VL_PUNI_ACTIVO      NUMBER;
VL_INFO_PUNI        VARCHAR2(90);
VL_FECHA_TERMINO    DATE;
VL_VENCIDO          NUMBER;

 BEGIN

   BEGIN
     SELECT TBRACCD_FEED_DATE,TBRACCD_AMOUNT
       INTO VL_FECHA_INICIO,VL_PARCIALIDAD
       FROM TBRACCD
      WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
            AND TBRACCD_DOCUMENT_NUMBER IS NULL
            AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE))
            AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                               FROM SORLCUR
                                              WHERE     SORLCUR_PIDM = P_PIDM
                                                    AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                    AND SORLCUR_ROLL_IND  = 'Y'
                                                    AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                    AND SORLCUR_PROGRAM = P_PROGRAMA)
            AND TBRACCD_PIDM = P_PIDM;
   EXCEPTION
   WHEN OTHERS THEN

     BEGIN
       SELECT TBRACCD_FEED_DATE,TBRACCD_AMOUNT
         INTO VL_FECHA_INICIO,VL_PARCIALIDAD
         FROM TBRACCD
        WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
              AND TBRACCD_DOCUMENT_NUMBER IS NULL
              AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1))
              AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                 FROM SORLCUR
                                                WHERE     SORLCUR_PIDM = P_PIDM
                                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                      AND SORLCUR_ROLL_IND  = 'Y'
                                                      AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                      AND SORLCUR_PROGRAM = P_PROGRAMA)
              AND TBRACCD_PIDM = P_PIDM;
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR CALCULO DE FECHA = '||SQLERRM;
     VL_FECHA_INICIO:=NULL;
     END;
   END;

   BEGIN
     SELECT SUM(TBRACCD_BALANCE)
       INTO VL_SALDO
       FROM TBRACCD
      WHERE TBRACCD_PIDM = P_PIDM;
   END;

   BEGIN
     SELECT COUNT(*)
       INTO VL_ESCALONADO
       FROM TZFACCE A
      WHERE     A.TZFACCE_PIDM = P_PIDM
            AND A.TZFACCE_DETAIL_CODE LIKE '%M3'
            AND A.TZFACCE_STUDY = (SELECT MAX(TZFACCE_STUDY)
                                     FROM TZFACCE
                                    WHERE     TZFACCE_PIDM = A.TZFACCE_PIDM
                                          AND TZFACCE_STUDY IS NOT NULL)
            AND LAST_DAY(A.TZFACCE_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE));
   END;

   BEGIN
     SELECT NVL(SUM(TBRACCD_BALANCE),0)
      INTO VL_CARGOS
      FROM TBRACCD A
     WHERE     A.TBRACCD_PIDM = P_PIDM
           AND A.TBRACCD_TRAN_NUMBER IN (SELECT TBRACCD_TRAN_NUMBER
                                         FROM TBRACCD
                                        WHERE    TBRACCD_PIDM = A.TBRACCD_PIDM
                                              AND TBRACCD_BALANCE > 0
                                              AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                              AND TBRACCD_FEED_DATE < VL_FECHA_INICIO
                                              AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                                               FROM SORLCUR
                                                                              WHERE     SORLCUR_PIDM = P_PIDM
                                                                                    AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                    AND SORLCUR_ROLL_IND  = 'Y'
                                                                                    AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                    AND SORLCUR_PROGRAM = P_PROGRAMA)
                                        UNION
                                       SELECT TBRACCD_TRAN_NUMBER
                                         FROM TBRACCD
                                        WHERE    TBRACCD_PIDM = A.TBRACCD_PIDM
                                              AND TBRACCD_BALANCE > 0
                                              AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                              AND TBRACCD_FEED_DATE = VL_FECHA_INICIO
                                              AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) < LAST_DAY(TRUNC(SYSDATE))
                                              AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                                               FROM SORLCUR
                                                                              WHERE     SORLCUR_PIDM = P_PIDM
                                                                                    AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                    AND SORLCUR_ROLL_IND  = 'Y'
                                                                                    AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                    AND SORLCUR_PROGRAM = P_PROGRAMA)
                                                                                    );
   EXCEPTION
   WHEN OTHERS THEN
   VL_CARGOS:=0;
   END;

   BEGIN
     SELECT TO_NUMBER(ZSTPARA_PARAM_VALOR)
       INTO VL_VENCIDO
       FROM ZSTPARA
      WHERE     ZSTPARA_MAPA_ID = 'MAX_PAGOUNI'
            AND ZSTPARA_PARAM_ID = (SELECT DISTINCT (SORLCUR_CAMP_CODE)
                                      FROM SORLCUR
                                     WHERE     SORLCUR_PIDM = P_PIDM
                                           AND SORLCUR_LMOD_CODE = 'LEARNER'
                                           AND SORLCUR_ROLL_IND  = 'Y'
                                           AND SORLCUR_CACT_CODE = 'ACTIVE'
                                           AND SORLCUR_PROGRAM = P_PROGRAMA);
   EXCEPTION
   WHEN OTHERS THEN
   VL_VENCIDO:=100000000;
   END;

   IF (    VL_ERROR IS NOT NULL
        OR VL_SALDO < (VL_PARCIALIDAD*-1)
        OR VL_ESCALONADO > 0 ) THEN

     VL_ERROR:= 'No cuentas con promociones por el momento.';
     --DBMS_OUTPUT.PUT_LINE('AQUI 1 = '||VL_SALDO||' = '||VL_PARCIALIDAD||' = '||VL_ESCALONADO);
      BEGIN
        SELECT COUNT(*)
          INTO VL_PUNI_ACTIVO
          FROM TZTPUNI
         WHERE     TZTPUNI_PIDM = P_PIDM
         AND TZTPUNI_CHECH_FINAL IS NULL
         AND TZTPUNI_OBSERVACIONES = 'GENERADO CORRECTAMENTE';
      END;

      IF VL_PUNI_ACTIVO = 0 THEN

         VL_ERROR:= 'No cuentas con promociones por el momento.';

      ELSE

        BEGIN
          SELECT TO_CHAR(ADD_MONTHS(TZTPUNI_FECHA_INICIO,TZTPUNI_VECES),'MONTH YYYY','nls_date_language=spanish')
            INTO VL_INFO_PUNI
            FROM TZTPUNI
           WHERE     TZTPUNI_OBSERVACIONES = 'GENERADO CORRECTAMENTE'
                 AND TZTPUNI_CHECH_FINAL IS NULL
                 AND TZTPUNI_PIDM = P_PIDM;
        END;
          VL_ERROR:= 'Descuento aplicado hasta '||INITCAP(VL_INFO_PUNI);
      END IF;

   ELSIF VL_CARGOS > VL_VENCIDO THEN
     --DBMS_OUTPUT.PUT_LINE('AQUI 2 = '||VL_ERROR);
     VL_ERROR:='Presenta saldo vencido, liquidar saldo para obtener promociones.';

   ELSE
   --DBMS_OUTPUT.PUT_LINE('AQUI 3 = '||VL_ERROR);
     BEGIN
       SELECT COUNT(*)
         INTO VL_EXIS_PUNI
         FROM TZTPUNI
        WHERE TZTPUNI_PIDM = P_PIDM;
     END;

     IF VL_EXIS_PUNI = 0 THEN
       VL_ERROR:='EXITO';
     ELSE
       BEGIN
         SELECT COUNT(*)
         INTO VL_EXIS_PUNI
           FROM TZTPUNI
          WHERE     TZTPUNI_CHECH_FINAL IS NULL
                AND TZTPUNI_APLI IS NULL
                AND TZTPUNI_PIDM = P_PIDM;
       END;

       IF VL_EXIS_PUNI = 0 THEN

         BEGIN
           SELECT COUNT(*)
             INTO VL_PUNI_ACTIVO
             FROM TZTPUNI
            WHERE     TZTPUNI_PIDM = P_PIDM
            AND TZTPUNI_CHECH_FINAL IS NULL;
         END;

         IF VL_PUNI_ACTIVO = 0 THEN

           BEGIN
             SELECT LAST_DAY(ADD_MONTHS(TZTPUNI_FECHA_INICIO,TZTPUNI_VECES))
               INTO VL_FECHA_TERMINO
               FROM TZTPUNI A
              WHERE     A.TZTPUNI_CHECH_FINAL IS NOT NULL
                    AND A.TZTPUNI_PIDM = P_PIDM
                    AND TRUNC(A.TZTPUNI_ACTIVITY_DATE) = (SELECT MAX(TRUNC(TZTPUNI_ACTIVITY_DATE))
                                                            FROM TZTPUNI
                                                           WHERE     TZTPUNI_CHECH_FINAL IS NOT NULL
                                                                 AND TZTPUNI_PIDM = A.TZTPUNI_PIDM);
           EXCEPTION
           WHEN OTHERS THEN
           VL_FECHA_TERMINO:=NULL;
           END;

           IF (VL_FECHA_TERMINO < TRUNC(SYSDATE) OR VL_FECHA_TERMINO IS NULL ) THEN
             VL_ERROR:='EXITO';
           ELSE
             VL_ERROR:='No cuentas con promociones en este momento.';
           END IF;

         ELSE

           BEGIN
             SELECT COUNT(*)
               INTO VL_PUNI_ACTIVO
               FROM TZTPUNI
              WHERE     TZTPUNI_PIDM = P_PIDM
              AND TZTPUNI_CHECH_FINAL IS NULL
              AND TZTPUNI_OBSERVACIONES = 'GENERADO CORRECTAMENTE';
           END;

           IF VL_PUNI_ACTIVO = 0 THEN

             BEGIN
               SELECT TO_CHAR(TZTPUNI_MONTO,'$999,999,999.00')||', aplica para '||TZTPUNI_VECES||' mesualidades' INFO
                 INTO VL_INFO_PUNI
                   FROM TZTPUNI
                  WHERE     TZTPUNI_CHECH_FINAL IS NULL
                        AND TZTPUNI_APLI IS NULL
                        AND TZTPUNI_PIDM = P_PIDM;
             END;
             VL_ERROR:= 'DESCUENTO ACTIVO. Realizar pago por'||VL_INFO_PUNI;

           ELSE

             BEGIN
               SELECT TO_CHAR(ADD_MONTHS(TZTPUNI_FECHA_INICIO,TZTPUNI_VECES),'MONTH YYYY','nls_date_language=spanish')
                 INTO VL_INFO_PUNI
                 FROM TZTPUNI
                WHERE     TZTPUNI_OBSERVACIONES = 'GENERADO CORRECTAMENTE'
                      AND TZTPUNI_CHECH_FINAL IS NULL
                      AND TZTPUNI_PIDM = P_PIDM;
             END;
               VL_ERROR:= 'Descuento aplicado hasta '||INITCAP(VL_INFO_PUNI);
           END IF;

         END IF;

       ELSE

           BEGIN
             SELECT TO_CHAR(TZTPUNI_MONTO,'$999,999,999.00')||', aplica para '||TZTPUNI_VECES||' mesualidades' INFO
               INTO VL_INFO_PUNI
                 FROM TZTPUNI
                WHERE     TZTPUNI_CHECH_FINAL IS NULL
                      AND TZTPUNI_APLI IS NULL
                      AND TZTPUNI_PIDM = P_PIDM;
           END;

           VL_ERROR:= 'DESCUENTO ACTIVO. Realizar pago por'||VL_INFO_PUNI;


       END IF;
     END IF;
   END IF;
   RETURN(VL_ERROR);
 END F_VALIDA_PAGOUNICO;

FUNCTION F_ELIMINA_UNI (P_PIDM NUMBER)RETURN VARCHAR2 IS

VL_ERROR    VARCHAR2(50):='EXITO';
 BEGIN
   DELETE TZTPUNI
    WHERE     TZTPUNI_CHECH_FINAL IS NULL
          AND TZTPUNI_APLI IS NULL
          AND TZTPUNI_PIDM = P_PIDM;
   COMMIT;
   RETURN(VL_ERROR);
 END F_ELIMINA_UNI;

 FUNCTION F_MESES_POR_CURSAR ( P_PIDM NUMBER)  RETURN VARCHAR2
IS

  VL_NIVEL      VARCHAR2(4);
  VL_STUDY      VARCHAR2(1);
  VPOR_CC       NUMBER:=0;
  VPOR_CC2      NUMBER:=0;
  VL_JORNADA    NUMBER:=0;
  VL_ERROR      VARCHAR2(900);


 BEGIN

   BEGIN
     SELECT DISTINCT SORLCUR_LEVL_CODE, SORLCUR_KEY_SEQNO
       INTO  VL_NIVEL, VL_STUDY
       FROM SORLCUR A
      WHERE     A.SORLCUR_PIDM = P_PIDM--FGET_PIDM ('010004009')
            AND A.SORLCUR_LMOD_CODE = 'LEARNER'
            AND A.SORLCUR_ROLL_IND  = 'Y'
            AND A.SORLCUR_CACT_CODE = 'ACTIVE'
            AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                      FROM SORLCUR A1
                                     WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                           AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                           AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                           AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                           AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE);
   EXCEPTION WHEN OTHERS THEN
   VL_ERROR := 'ERROR EN SORLCUR = '|| SQLERRM;
   END;

   BEGIN
     SELECT SUBSTR(SGRSATT_ATTS_CODE,4,1)
       INTO VL_JORNADA
       FROM SGRSATT T
      WHERE     T.SGRSATT_PIDM = P_PIDM
            AND T.SGRSATT_STSP_KEY_SEQUENCE = VL_STUDY
            AND REGEXP_LIKE  (T.SGRSATT_ATTS_CODE , '^[0-9]')
            AND SUBSTR(T.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
            AND T.SGRSATT_TERM_CODE_EFF = ( SELECT MAX(SGRSATT_TERM_CODE_EFF)
                                              FROM SGRSATT TT
                                             WHERE     TT.SGRSATT_PIDM =  T.SGRSATT_PIDM
                                                   AND TT.SGRSATT_STSP_KEY_SEQUENCE= T.SGRSATT_STSP_KEY_SEQUENCE
                                                   AND SUBSTR(TT.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
                                                   AND REGEXP_LIKE  (TT.SGRSATT_ATTS_CODE , '^[0-9]'))
            AND T.SGRSATT_ACTIVITY_DATE = (SELECT MAX(SGRSATT_ACTIVITY_DATE)
                                             FROM SGRSATT T1
                                            WHERE      T1.SGRSATT_PIDM = T.SGRSATT_PIDM
                                                   AND T1.SGRSATT_STSP_KEY_SEQUENCE = T.SGRSATT_STSP_KEY_SEQUENCE
                                                   AND T1.SGRSATT_TERM_CODE_EFF = T.SGRSATT_TERM_CODE_EFF
                                                   AND SUBSTR(T1.SGRSATT_TERM_CODE_EFF,5,1) NOT IN (8,9)
                                                   AND REGEXP_LIKE  (T1.SGRSATT_ATTS_CODE , '^[0-9]'));

   EXCEPTION WHEN OTHERS THEN
   VL_JORNADA  := 2;
   VL_ERROR :=  'f_cal_jornada'||SQLERRM;
   END;


   BEGIN
    SELECT SZTHITA_X_CURSAR
      INTO VPOR_CC
      FROM SZTHITA
     WHERE     SZTHITA_PIDM = P_PIDM
           AND SZTHITA_LEVL = VL_NIVEL
           AND SZTHITA_STUDY  = VL_STUDY;

   EXCEPTION WHEN OTHERS THEN

     BEGIN
       SELECT SZTHITA_X_CURSAR
         INTO VPOR_CC
         FROM SZTHITA
        WHERE     SZTHITA_PIDM = P_PIDM
              AND SZTHITA_LEVL = VL_NIVEL;
     EXCEPTION WHEN OTHERS THEN
     VPOR_CC  := 0;
     VL_ERROR :=  'szthita = '||SQLERRM;
     END;
   END;

   VPOR_CC2 := ROUND((VPOR_CC/VL_JORNADA)*2,0);

   IF VL_ERROR IS NULL THEN
   RETURN(VPOR_CC2);
   ELSE
   RETURN(VL_ERROR);
   END IF;

 END F_MESES_POR_CURSAR;

PROCEDURE P_CANCE_PAGOUNICO IS

 BEGIN
  FOR X IN (
                SELECT *
                FROM TZTPUNI
                WHERE     TRUNC(TZTPUNI_ACTIVITY_DATE)+(SELECT ZSTPARA_PARAM_VALOR
                                                          FROM ZSTPARA
                                                         WHERE ZSTPARA_MAPA_ID = 'VIG_PAGOUNI'
                                                         ) < TRUNC (SYSDATE)
                      AND TZTPUNI_CHECH_FINAL IS NULL
                      AND (    TZTPUNI_OBSERVACIONES LIKE 'No existe pago en el estado de cuenta%'
                            OR TZTPUNI_OBSERVACIONES IS NULL)
    )LOOP

      BEGIN
        DELETE TZTPUNI
         WHERE TZTPUNI_PIDM = X.TZTPUNI_PIDM
          AND TRUNC(TZTPUNI_ACTIVITY_DATE)+(SELECT ZSTPARA_PARAM_VALOR
                                              FROM ZSTPARA
                                             WHERE ZSTPARA_MAPA_ID = 'VIG_PAGOUNI') < TRUNC (SYSDATE)
          AND TZTPUNI_CHECH_FINAL IS NULL
          AND (    TZTPUNI_OBSERVACIONES LIKE 'No existe pago en el estado de cuenta%'
                OR TZTPUNI_OBSERVACIONES IS NULL);

      END;
    END LOOP;
   COMMIT;
 END P_CANCE_PAGOUNICO;

 FUNCTION F_COMP_VAL_SALDO (P_PIDM NUMBER) RETURN VARCHAR2 IS

VL_IND_COMPL  NUMBER;
VL_ERROR      VARCHAR2(900);

 BEGIN
   BEGIN
     SELECT NVL(TZTPUNI_IND_COMPL,0)
       INTO  VL_IND_COMPL
       FROM  TZTPUNI
      WHERE     TZTPUNI_PIDM=P_PIDM
            AND TZTPUNI_APLI IS NULL
            AND TZTPUNI_CHECK IS NULL;
   EXCEPTION WHEN OTHERS THEN
   VL_ERROR:= 'ERROR AL CALCULAR = '||SQLERRM;
   END;

   IF VL_ERROR IS NULL THEN
     RETURN (VL_IND_COMPL);
   ELSE
     RETURN (VL_ERROR);
   END IF;
 END F_COMP_VAL_SALDO;

FUNCTION F_FECHA_NIVELACION (P_FECHA DATE)RETURN DATE IS

  VL_DIA        VARCHAR2(20);
  RESPUESTA     DATE;

BEGIN

    BEGIN
      SELECT TRIM(TO_CHAR(P_FECHA,'DAY'))
        INTO VL_DIA
        FROM DUAL;
    END;

    IF VL_DIA != 'LUNES' THEN
      BEGIN
        SELECT TRUNC(NEXT_DAY(P_FECHA,'LUNES'))
          INTO RESPUESTA
          FROM DUAL;
      END;
    ELSE
      --RESPUESTA:=P_FECHA;
      RESPUESTA:='LUNES';
    END IF;
  RETURN(RESPUESTA);
END F_FECHA_NIVELACION;

FUNCTION F_PGUNI_CUATRI (P_CAMP     VARCHAR2,
                         P_NIVEL    VARCHAR2,
                         P_PERIODO  VARCHAR2,
                         P_PARTE    VARCHAR2,
                         P_COSTO    VARCHAR2,
                         P_PIDM     NUMBER,
                         P_FECHA    DATE,
                         P_STUDY    NUMBER)RETURN VARCHAR2 IS

VL_CUATRI           NUMBER;
VL_VALIDA_CUA       NUMBER;
VL_DESCUENTO        NUMBER;
VL_CODEXEMTION      NUMBER;
VL_DESC_NUM         NUMBER;
VL_FECHA_ANTE       DATE;
VL_MESES            NUMBER;
VL_ENTDESC          NUMBER;
VL_ERROR            VARCHAR2(900);
VL_ACCION           VARCHAR2(90);
VL_ENTRA            NUMBER;
VL_FOLIO            NUMBER;
VL_NUEVO            NUMBER;

 BEGIN

   BEGIN
    SELECT COUNT(*)
      INTO VL_NUEVO
      FROM TBRACCD
     WHERE     TBRACCD_PIDM = P_PIDM
           AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
           AND TBRACCD_DOCUMENT_NUMBER IS NULL
           AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY;
   END;

   IF VL_NUEVO = 0 THEN

     VL_ERROR:='EXITO';

   ELSE

     BEGIN
       SELECT TBRACCD_FEED_DATE,TBRACCD_RECEIPT_NUMBER
        INTO VL_FECHA_ANTE,VL_FOLIO
        FROM TBRACCD A
       WHERE     A.TBRACCD_PIDM = P_PIDM
             AND A.TBRACCD_TRAN_NUMBER = (SELECT MAX(TBRACCD_TRAN_NUMBER)
                                            FROM TBRACCD
                                           WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                                 AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                                 AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                                 AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY);
     EXCEPTION
     WHEN OTHERS THEN
     VL_FECHA_ANTE:='01/01/1990';
     VL_FOLIO     :=NULL;
     END;

     BEGIN
       SELECT MONTHS_BETWEEN((P_FECHA+12)-(TO_CHAR((P_FECHA+12),'DD')-1),(VL_FECHA_ANTE+12)-(TO_CHAR((VL_FECHA_ANTE+12),'DD')-1))
         INTO VL_MESES
         FROM DUAL;
     END;

     IF TO_CHAR(VL_FECHA_ANTE,'DD') >= 20 THEN
       IF VL_MESES >= 3 THEN
         VL_ENTRA:=1; VL_ERROR:='EXITO';
       ELSE
        VL_ENTRA:=0; VL_ERROR:='GENERADA';
       END IF;
     ELSE
       IF VL_MESES >= 4 THEN
         VL_ENTRA:=1; VL_ERROR:='EXITO';
       ELSE
         VL_ENTRA:=0; VL_ERROR:='GENERADA';
       END IF;
     END IF;

     IF VL_ENTRA = 0 THEN
       UPDATE SFRSTCR
          SET SFRSTCR_VPDI_CODE = VL_FOLIO
        WHERE SFRSTCR_PIDM = P_PIDM
              AND SFRSTCR_TERM_CODE = P_PERIODO
              AND SFRSTCR_PTRM_CODE = P_PARTE
              AND SFRSTCR_RSTS_CODE = 'RE';
     END IF;

     IF VL_ENTRA > 0 THEN

       BEGIN
         SELECT COUNT(*)
          INTO VL_CUATRI
          FROM TBRACCD
         WHERE     TBRACCD_PIDM = P_PIDM
               AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
               AND TBRACCD_DOCUMENT_NUMBER IS NULL
               AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY;
       END;

       BEGIN
         SELECT MAX(SUBSTR(ZSTPARA_PARAM_ID,10,1))
           INTO VL_VALIDA_CUA
           FROM ZSTPARA
          WHERE     ZSTPARA_MAPA_ID = 'PORC_CUATRI'
                AND SUBSTR(ZSTPARA_PARAM_ID,1,8) = P_CAMP||P_NIVEL||'_'||P_COSTO;
       EXCEPTION
       WHEN OTHERS THEN
         BEGIN
           SELECT MAX(SUBSTR(ZSTPARA_PARAM_ID,9,2))
             INTO VL_VALIDA_CUA
             FROM ZSTPARA
            WHERE     ZSTPARA_MAPA_ID = 'PORC_CUATRI'
                  AND ZSTPARA_PARAM_ID LIKE 'GENERAL%';
         END;
       END;

       VL_CUATRI:= VL_CUATRI+1;

       IF VL_CUATRI > VL_VALIDA_CUA THEN
         VL_CUATRI:= VL_VALIDA_CUA;
         VL_ACCION:='NO ENTRA';
       ELSE
         VL_CUATRI:= VL_CUATRI;
         VL_ACCION:='ACTUALIZA';
       END IF;

       --DBMS_OUTPUT.PUT_LINE('AQUI VALIDA CUATRI = '||P_CAMP||P_NIVEL||'_'||P_COSTO||'_'||VL_CUATRI||'='||VL_FECHA_ANTE||'='||VL_ACCION||'='||VL_MESES);
       BEGIN
         SELECT ZSTPARA_PARAM_VALOR
           INTO VL_DESCUENTO
           FROM ZSTPARA
          WHERE     ZSTPARA_MAPA_ID = 'PORC_CUATRI'
                AND ZSTPARA_PARAM_ID = P_CAMP||P_NIVEL||'_'||P_COSTO||'_'||VL_CUATRI;
       EXCEPTION
       WHEN OTHERS THEN
         BEGIN
           SELECT ZSTPARA_PARAM_VALOR
             INTO VL_DESCUENTO
             FROM ZSTPARA
            WHERE     ZSTPARA_MAPA_ID = 'PORC_CUATRI'
                  AND ZSTPARA_PARAM_ID = 'GENERAL_'||VL_CUATRI;
         EXCEPTION
         WHEN OTHERS THEN
         VL_DESCUENTO:=0;
         END;
       END;

       IF VL_ACCION = 'ACTUALIZA' THEN
         BEGIN
           SELECT DISTINCT TBBESTU_EXEMPTION_CODE
             INTO VL_CODEXEMTION
             FROM TBBEXPT,TBBESTU A,TBBDETC,TBREDET
            WHERE     TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                  AND TBBDETC_TAXT_CODE = P_NIVEL
                  AND A.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                  AND A.TBBESTU_TERM_CODE         = TBBEXPT_TERM_CODE
                  AND A.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                  AND A.TBBESTU_DEL_IND IS NULL
                  AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                  AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                  AND A.TBBESTU_TERM_CODE = (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                               FROM TBBESTU A1,TBBEXPT,TBREDET,TBBDETC
                                              WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                    AND TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                                    AND TBBDETC_TAXT_CODE = P_NIVEL
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
                                                             AND TBBDETC_TAXT_CODE = P_NIVEL
                                                             AND B1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                             AND B1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                             AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                             AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                             AND B1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                             AND B1.TBBESTU_DEL_IND IS NULL
                                                             AND B1.TBBESTU_TERM_CODE = (SELECT MAX(B2.TBBESTU_TERM_CODE)
                                                                                           FROM TBBESTU B2,TBBEXPT,TBREDET,TBBDETC
                                                                                          WHERE     B2.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                                                                AND TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                                                                                AND TBBDETC_TAXT_CODE = P_NIVEL
                                                                                                AND B2.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                                                                AND B2.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                                                                AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                                                                AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                                                                AND B2.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                                                                AND B2.TBBESTU_DEL_IND IS NULL
                                                                                                AND B2.TBBESTU_TERM_CODE <= P_PERIODO))
                  AND TBBESTU_PIDM = P_PIDM
                  AND TBBDETC_DCAT_CODE = 'DSP';
         EXCEPTION
         WHEN OTHERS THEN
         VL_ERROR :='Error descuento DSP : ' ||SQLERRM;
         END;

         BEGIN
           SELECT SUBSTR(VL_CODEXEMTION,(LENGTH(VL_CODEXEMTION)-1),2) DESCU
             INTO VL_DESC_NUM
             FROM DUAL;
         END;

         VL_DESC_NUM:= VL_DESC_NUM - VL_DESCUENTO;
         VL_CODEXEMTION:=VL_CODEXEMTION-VL_DESC_NUM;

         BEGIN
           SELECT COUNT(*)
             INTO VL_ENTDESC
             FROM TBBESTU
            WHERE     TBBESTU_PIDM = P_PIDM
                  AND TBBESTU_TERM_CODE = P_PERIODO;
         EXCEPTION
         WHEN OTHERS THEN
         VL_ENTDESC:=0;
         END;

         --DBMS_OUTPUT.PUT_LINE('VALIDA ROLADO = '||VL_CODEXEMTION||' = '||VL_DESC_NUM||' = '||VL_DESCUENTO||' = '||VL_ENTDESC);

         IF VL_ENTDESC = 0 THEN

           BEGIN
               INSERT
                 INTO TBBESTU
               VALUES(VL_CODEXEMTION,
                      P_PIDM,
                      P_PERIODO,
                      SYSDATE,
                      NULL,
                      'Y',
                      NULL,
                      USER,
                      1,
                      NULL,
                      NULL,
                      NULL,
                      'PGUNI_CUATRI',
                      NULL);
           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR:='ERROR DESCUENTO = '||SQLERRM;
           END;
         --DBMS_OUTPUT.PUT_LINE('ERROR AL INSERTAR CODIGO DE DESCUENTO REZA 1 ===== '||VL_ERROR);
         ELSE

           BEGIN
             UPDATE TBBESTU
                SET TBBESTU_EXEMPTION_CODE = VL_CODEXEMTION
              WHERE     TBBESTU_PIDM = P_PIDM
                    AND TBBESTU_TERM_CODE = P_PERIODO;

           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR:= 'NO ACTUALIZA TBB';
           END;

         END IF;

       END IF;

     END IF;
   END IF;

   IF (VL_ERROR = 'EXITO' OR VL_ERROR = 'GENERADA') THEN
     COMMIT;
   ELSE
     ROLLBACK;
   END IF;

  RETURN (VL_ERROR);

 END F_PGUNI_CUATRI;

FUNCTION F_COND_UTELX (P_PIDM NUMBER, P_NUM_CDN NUMBER, P_ACCION VARCHAR2)RETURN VARCHAR2 IS

VL_FECHA_APLICA         DATE;
VL_FECHA_FIN            DATE;
VL_SALTO                NUMBER:=0;
VL_SECUENCIA            NUMBER;
VL_CODIGO               VARCHAR2(5);
VL_DESCRIP              VARCHAR2(50);
VL_MONEDA               VARCHAR2(4);
VL_ENTRA                NUMBER;
VL_ERROR                VARCHAR2(900);
VL_REGISTRO             NUMBER;
VL_INICIO               DATE;
VL_EFF_DATE             DATE;

 BEGIN
   IF P_ACCION = 'INSERTA' THEN

     BEGIN
       SELECT COUNT(*)
         INTO VL_ENTRA
         FROM TZTCONX
        WHERE     TZTCONX_ESTATUS = 0
              AND TZTCONX_PIDM = P_PIDM;
     END;

     BEGIN
       SELECT COUNT(*)
         INTO VL_REGISTRO
         FROM TZTCONX
        WHERE TZTCONX_PIDM = P_PIDM;
     END;

     IF VL_ENTRA = 0 THEN

       BEGIN
         SELECT COUNT(*)
           INTO VL_ENTRA
           FROM TZTCONX A
          WHERE     A.TZTCONX_PIDM = P_PIDM
                AND A.TZTCONX_ESTATUS = 1;
       END;

       IF VL_ENTRA = 0 THEN

         BEGIN
           SELECT COUNT(*)
             INTO VL_ENTRA
             FROM TZTCONX A
            WHERE     A.TZTCONX_PIDM = P_PIDM
                  AND A.TZTCONX_ESTATUS = 1
                  AND A.TZTCONX_ACTIVITY_DATE = (SELECT MAX(TZTCONX_ACTIVITY_DATE)
                                                   FROM TZTCONX
                                                  WHERE     TZTCONX_PIDM = A.TZTCONX_PIDM
                                                        AND TZTCONX_ESTATUS = 1)
                  AND LAST_DAY(A.TZTCONX_FECHA_FIN) > TRUNC(SYSDATE);
         END;

         IF VL_REGISTRO = 0 THEN VL_ENTRA:=1; END IF;

         IF VL_ENTRA = 0 THEN
           VL_ERROR:='ALUMNO PRESENTA CONDONACIÓN VIGENTE';
         ELSE
           BEGIN
             SELECT DISTINCT (TBRACCD_FEED_DATE)
               INTO VL_INICIO
               FROM TBRACCD
              WHERE     TBRACCD_PIDM = P_PIDM
                    AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                    AND TBRACCD_DOCUMENT_NUMBER IS NULL
                    AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE));
           EXCEPTION
           WHEN OTHERS THEN
             BEGIN
               SELECT DISTINCT (TBRACCD_FEED_DATE)
                 INTO VL_INICIO
                 FROM TBRACCD
                WHERE     TBRACCD_PIDM = P_PIDM
                      AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                      AND TBRACCD_DOCUMENT_NUMBER IS NULL
                      AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE-(TO_CHAR(SYSDATE,'DD'))));
             END;
           END;

           BEGIN
             SELECT MIN(TBRACCD_EFFECTIVE_DATE)
             INTO VL_FECHA_APLICA
               FROM TBRACCD A
              WHERE     A.TBRACCD_DESC = 'MEMBRESIA UTEL X'
                    AND A.TBRACCD_BALANCE = (SELECT A.TBRACCD_AMOUNT-TBRACCD_AMOUNT
                                               FROM TBRACCD
                                              WHERE TBRACCD_PIDM = A.TBRACCD_PIDM
                                                    AND TBRACCD_TRAN_NUMBER_PAID = A.TBRACCD_TRAN_NUMBER
                                                    AND TBRACCD_DESC = 'DESCUENTO MEMBRESIA UTEL X')
                    AND A.TBRACCD_PIDM = P_PIDM
                    AND A.TBRACCD_FEED_DATE = VL_INICIO
                    AND LAST_DAY(A.TBRACCD_EFFECTIVE_DATE) >= LAST_DAY(TRUNC(SYSDATE));
           EXCEPTION
           WHEN OTHERS THEN
             VL_SALTO:=1;
             BEGIN
               SELECT MAX(TBRACCD_EFFECTIVE_DATE)
                 INTO VL_FECHA_APLICA
                 FROM TBRACCD A
                WHERE     A.TBRACCD_DESC = 'MEMBRESIA UTEL X'
                      AND A.TBRACCD_PIDM = P_PIDM
                      AND A.TBRACCD_FEED_DATE = VL_INICIO;
             EXCEPTION
             WHEN OTHERS THEN
             VL_FECHA_APLICA:=NULL;
             END;
           END;

           IF VL_FECHA_APLICA IS NOT NULL THEN
             IF VL_SALTO = 1 THEN

               VL_FECHA_APLICA :=ADD_MONTHS(VL_FECHA_APLICA,1);
               VL_FECHA_FIN    :=ADD_MONTHS(VL_FECHA_APLICA,(P_NUM_CDN-1));

               BEGIN
                 INSERT
                   INTO TZTCONX
                        ( TZTCONX_PIDM,
                          TZTCONX_FECHA_EJECUCION,
                          TZTCONX_FECHA_FIN,
                          TZTCONX_MESES,
                          TZTCONX_ESTATUS,
                          TZTCONX_USER)
                 VALUES (P_PIDM,
                         VL_FECHA_APLICA,
                         VL_FECHA_FIN,
                         P_NUM_CDN,
                         0,
                         USER);
               EXCEPTION
               WHEN OTHERS THEN
               VL_ERROR:='ERROR AL INSERTAR TZTCONX = '||SQLERRM;
               END;

             ELSE

               VL_FECHA_FIN :=ADD_MONTHS(VL_FECHA_APLICA,(P_NUM_CDN-1));

               BEGIN
                 INSERT
                   INTO TZTCONX
                        ( TZTCONX_PIDM,
                          TZTCONX_FECHA_EJECUCION,
                          TZTCONX_FECHA_FIN,
                          TZTCONX_MESES,
                          TZTCONX_ESTATUS,
                          TZTCONX_USER)
                 VALUES (P_PIDM,
                         VL_FECHA_APLICA,
                         VL_FECHA_FIN,
                         P_NUM_CDN,
                         0,
                         USER);
               EXCEPTION
               WHEN OTHERS THEN
               VL_ERROR:='ERROR AL INSERTAR TZTCONX = '||SQLERRM;
               END;

               BEGIN
                 FOR UTLX IN (
                              SELECT A.*,(SELECT (A.TBRACCD_AMOUNT-TBRACCD_AMOUNT)
                                            FROM TBRACCD
                                           WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                                 AND TBRACCD_DESC = 'DESCUENTO MEMBRESIA UTEL X'
                                                 AND TBRACCD_TRAN_NUMBER_PAID = A.TBRACCD_TRAN_NUMBER )MONTO_AJUSTE
                                 FROM TBRACCD A
                                WHERE     A.TBRACCD_DESC = 'MEMBRESIA UTEL X'
                                      AND A.TBRACCD_EFFECTIVE_DATE >= VL_FECHA_APLICA
                                      AND A.TBRACCD_PIDM = P_PIDM
                 )LOOP

                   PKG_FINANZAS.P_DESAPLICA_PAGOS ( UTLX.TBRACCD_PIDM, UTLX.TBRACCD_TRAN_NUMBER);

                   BEGIN
                     SELECT MAX(TBRACCD_TRAN_NUMBER)+1
                       INTO VL_SECUENCIA
                       FROM TBRACCD
                      WHERE TBRACCD_PIDM = P_PIDM;
                   END;

                   BEGIN
                     SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC,TVRDCTX_CURR_CODE
                       INTO VL_CODIGO,VL_DESCRIP,VL_MONEDA
                       FROM TBBDETC,TVRDCTX
                      WHERE     TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE
                            AND TBBDETC_DETAIL_CODE = SUBSTR(UTLX.TBRACCD_DETAIL_CODE,1,2)||'17';
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_ERROR:='ERROR EN CODIGO = '||SQLERRM;
                   END;

                   IF UTLX.TBRACCD_EFFECTIVE_DATE < TRUNC(SYSDATE) THEN
                     VL_EFF_DATE := TRUNC(SYSDATE);
                   ELSE
                     VL_EFF_DATE := UTLX.TBRACCD_EFFECTIVE_DATE;
                   END IF;

                   BEGIN
                     INSERT
                       INTO TBRACCD
                            (TBRACCD_PIDM,
                             TBRACCD_TRAN_NUMBER,
                             TBRACCD_TERM_CODE,
                             TBRACCD_DETAIL_CODE,
                             TBRACCD_USER,
                             TBRACCD_ENTRY_DATE,
                             TBRACCD_AMOUNT,
                             TBRACCD_BALANCE,
                             TBRACCD_EFFECTIVE_DATE,
                             TBRACCD_DESC,
                             TBRACCD_ACTIVITY_DATE,
                             TBRACCD_TRANS_DATE,
                             TBRACCD_DATA_ORIGIN,
                             TBRACCD_CREATE_SOURCE,
                             TBRACCD_SRCE_CODE ,
                             TBRACCD_ACCT_FEED_IND,
                             TBRACCD_SESSION_NUMBER,
                             TBRACCD_CURR_CODE,
                             TBRACCD_TRAN_NUMBER_PAID,
                             TBRACCD_STSP_KEY_SEQUENCE,
                             TBRACCD_PERIOD,
                             TBRACCD_FEED_DATE)
                     VALUES (P_PIDM,
                             VL_SECUENCIA,
                             UTLX.TBRACCD_TERM_CODE,
                             VL_CODIGO,
                             USER,
                             SYSDATE,
                             UTLX.MONTO_AJUSTE,
                             (UTLX.MONTO_AJUSTE)*-1 ,
                             VL_EFF_DATE,
                             VL_DESCRIP,
                             SYSDATE,
                             VL_EFF_DATE,
                             'CDN_UTLX',
                             'CDN_UTLX',
                             'T' ,
                             'Y',
                             0 ,
                             VL_MONEDA,
                             UTLX.TBRACCD_TRAN_NUMBER,
                             UTLX.TBRACCD_STSP_KEY_SEQUENCE,
                             UTLX.TBRACCD_PERIOD,
                             UTLX.TBRACCD_FEED_DATE);

                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_ERROR :=' Errror al Insertar cdn UTLX' || SQLERRM ;
                   END;

                   IF LAST_DAY(VL_FECHA_FIN) = LAST_DAY(UTLX.TBRACCD_EFFECTIVE_DATE) THEN

                     BEGIN
                       UPDATE TZTCONX
                          SET TZTCONX_ESTATUS = 1,
                              TZTCONX_OBSERVACIONES = 'FINALIZADO CORRECTAMENTE'
                        WHERE     TZTCONX_ESTATUS = 0
                              AND TZTCONX_PIDM = P_PIDM;
                     END;
                     EXIT;
                   END IF;
                 END LOOP;
               END;
             END IF;
           END IF;
         END IF;
       ELSE
       VL_ERROR:='ALUMNO PRESENTA CONDONACIÓN VIGENTE';
       END IF;

     ELSE
       VL_ERROR:='ALUMNO PRESENTA CONDONACIÓN VIGENTE';
     END IF;

   ELSIF P_ACCION = 'CONTINUO' THEN

     BEGIN
       SELECT TZTCONX_FECHA_EJECUCION,TZTCONX_FECHA_FIN
         INTO VL_FECHA_APLICA,VL_FECHA_FIN
         FROM TZTCONX
        WHERE     TZTCONX_PIDM = P_PIDM
              AND TZTCONX_ESTATUS = 0;
     EXCEPTION
     WHEN OTHERS THEN
     VL_FECHA_APLICA:=NULL;
     VL_FECHA_FIN:=NULL;
     END;

     IF VL_FECHA_APLICA IS NOT NULL THEN
       BEGIN
         FOR UTLX IN (
                      SELECT A.*,(SELECT (A.TBRACCD_AMOUNT-TBRACCD_AMOUNT)
                                    FROM TBRACCD
                                   WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                         AND TBRACCD_DESC = 'DESCUENTO MEMBRESIA UTEL X'
                                         AND TBRACCD_TRAN_NUMBER_PAID = A.TBRACCD_TRAN_NUMBER )MONTO_AJUSTE
                         FROM TBRACCD A
                        WHERE     A.TBRACCD_DESC = 'MEMBRESIA UTEL X'
                              AND LAST_DAY(A.TBRACCD_EFFECTIVE_DATE) BETWEEN LAST_DAY(VL_FECHA_APLICA) AND LAST_DAY(VL_FECHA_FIN)
                              AND A.TBRACCD_PIDM = P_PIDM
                              AND A.TBRACCD_FEED_DATE = (SELECT DISTINCT (TBRACCD_FEED_DATE)
                                                           FROM TBRACCD A1
                                                           WHERE A1.TBRACCD_PIDM = P_PIDM
                                                           AND A1.TBRACCD_TRAN_NUMBER = (SELECT MAX(TBRACCD_TRAN_NUMBER)
                                                                                           FROM TBRACCD
                                                                                          WHERE     TBRACCD_PIDM = P_PIDM
                                                                                                AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                                                                                AND TBRACCD_DOCUMENT_NUMBER IS NULL))
         )LOOP

           PKG_FINANZAS.P_DESAPLICA_PAGOS ( UTLX.TBRACCD_PIDM, UTLX.TBRACCD_TRAN_NUMBER);

           BEGIN
             SELECT MAX(TBRACCD_TRAN_NUMBER)+1
               INTO VL_SECUENCIA
               FROM TBRACCD
              WHERE TBRACCD_PIDM = P_PIDM;
           END;

           BEGIN
             SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC,TVRDCTX_CURR_CODE
               INTO VL_CODIGO,VL_DESCRIP,VL_MONEDA
               FROM TBBDETC,TVRDCTX
              WHERE     TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE
                    AND TBBDETC_DETAIL_CODE = SUBSTR(UTLX.TBRACCD_DETAIL_CODE,1,2)||'17';
           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR:='ERROR EN CODIGO = '||SQLERRM;
           END;

           BEGIN
             INSERT
               INTO TBRACCD
                    (TBRACCD_PIDM,
                     TBRACCD_TRAN_NUMBER,
                     TBRACCD_TERM_CODE,
                     TBRACCD_DETAIL_CODE,
                     TBRACCD_USER,
                     TBRACCD_ENTRY_DATE,
                     TBRACCD_AMOUNT,
                     TBRACCD_BALANCE,
                     TBRACCD_EFFECTIVE_DATE,
                     TBRACCD_DESC,
                     TBRACCD_ACTIVITY_DATE,
                     TBRACCD_TRANS_DATE,
                     TBRACCD_DATA_ORIGIN,
                     TBRACCD_CREATE_SOURCE,
                     TBRACCD_SRCE_CODE ,
                     TBRACCD_ACCT_FEED_IND,
                     TBRACCD_SESSION_NUMBER,
                     TBRACCD_CURR_CODE,
                     TBRACCD_TRAN_NUMBER_PAID,
                     TBRACCD_STSP_KEY_SEQUENCE,
                     TBRACCD_PERIOD,
                     TBRACCD_FEED_DATE)
             VALUES (P_PIDM,
                     VL_SECUENCIA,
                     UTLX.TBRACCD_TERM_CODE,
                     VL_CODIGO,
                     USER,
                     SYSDATE,
                     UTLX.MONTO_AJUSTE,
                     (UTLX.MONTO_AJUSTE)*-1 ,
                     UTLX.TBRACCD_EFFECTIVE_DATE,
                     VL_DESCRIP,
                     SYSDATE,
                     UTLX.TBRACCD_EFFECTIVE_DATE,
                     'CDN_UTLX',
                     'CDN_UTLX',
                     'T' ,
                     'Y',
                     0 ,
                     VL_MONEDA,
                     UTLX.TBRACCD_TRAN_NUMBER,
                     UTLX.TBRACCD_STSP_KEY_SEQUENCE,
                     UTLX.TBRACCD_PERIOD,
                     UTLX.TBRACCD_FEED_DATE);

           EXCEPTION
           WHEN OTHERS THEN
           VL_ERROR :=' Errror al Insertar cdn UTLX' || SQLERRM ;
           END;

           IF LAST_DAY(VL_FECHA_FIN) = LAST_DAY(UTLX.TBRACCD_EFFECTIVE_DATE) THEN

             BEGIN
               UPDATE TZTCONX
                  SET TZTCONX_ESTATUS = 1,
                      TZTCONX_OBSERVACIONES = 'FINALIZADO CORRECTAMENTE'
                WHERE     TZTCONX_ESTATUS = 0
                      AND TZTCONX_PIDM = P_PIDM;
             END;
             EXIT;
           END IF;

         END LOOP;
       END;
     END IF;
   END IF;
--     DBMS_OUTPUT.PUT_LINE('FINAL F_COND_UTELX = '||VL_ERROR);
   IF VL_ERROR IS NULL THEN
     VL_ERROR:='EXITO';
     COMMIT;
   ELSE
     ROLLBACK;
   END IF;
   RETURN(VL_ERROR);
 END F_COND_UTELX;

 FUNCTION F_ORDEN_AFIN (P_CAMPUS     VARCHAR2,
                       P_NIVEL      VARCHAR2,
                       P_PIDM       NUMBER,
                       P_PROGRAMA   VARCHAR2,
                       P_PERIODO    VARCHAR2,
                       P_FECHA_INI  DATE,
                       P_ACCION     VARCHAR2)RETURN VARCHAR2 IS

VL_ERROR            VARCHAR2(900);
VL_ORDEN            NUMBER;

 BEGIN
   IF P_ACCION = 'INSERTA' THEN

       BEGIN
         SELECT MAX(TZTORDR_CONTADOR)+1
           INTO VL_ORDEN
           FROM TZTORDR;
       EXCEPTION
       WHEN OTHERS THEN
       VL_ORDEN:= NULL;
       END;

       BEGIN

         INSERT
           INTO TZTORDR
                 ( TZTORDR_CAMPUS,
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
                   TZTORDR_TERM_CODE)
         VALUES ( P_CAMPUS,
                  P_NIVEL,
                  VL_ORDEN,
                  P_PROGRAMA,
                  P_PIDM,
                  GB_COMMON.F_GET_ID (P_PIDM),
                  'S',
                  SYSDATE,
                  USER,
                  'PROSPECTO',
                  NULL,
                  P_FECHA_INI,
                  NULL,
                  NULL,
                  NULL,
                  P_PERIODO);
       EXCEPTION
       WHEN OTHERS THEN
       VL_ERROR:= 'ERROR AL GENERAR ORDEN 3 = '||SQLERRM;
       END;

   ELSIF P_ACCION = 'CONSULTA' THEN
     BEGIN
       SELECT MAX(TZTORDR_CONTADOR)
         INTO VL_ORDEN
         FROM TZTORDR
         WHERE TZTORDR_PIDM = P_PIDM;
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:= 'ERROR EN ORDEN = '||SQLERRM;
     END;
   END IF;

   IF VL_ERROR IS NULL THEN
     VL_ERROR:=VL_ORDEN;
     COMMIT;
   ELSE
     ROLLBACK;
   END IF;

  RETURN(VL_ERROR);

 END F_ORDEN_AFIN;

FUNCTION F_PARC_DESCDOM (P_PIDM NUMBER,P_PROGRAMA VARCHAR2, P_TRANSA NUMBER) RETURN VARCHAR2 IS

 VL_ERROR VARCHAR2(900);
 VL_PARCIALIDAD NUMBER;
 VL_ESCALONADO NUMBER;

/* SE ACTUALIZA FUNCIÓN PARA IDENTIFICAR LOS CARGOS A FUTURO Y DETERMINAR EL ESCALONADO
 AUTOR: GGARCICA
 ACTUALIZADO: 21/10/2021
*/

 BEGIN

   BEGIN
     SELECT COUNT(*)
       INTO VL_ESCALONADO
       FROM TBRACCD
      WHERE     TBRACCD_PIDM = P_PIDM
            AND TBRACCD_DETAIL_CODE LIKE '%M3'
            AND TBRACCD_DOCUMENT_NUMBER IS NULL
            AND (     TBRACCD_TRAN_NUMBER_PAID = P_TRANSA AND (CASE WHEN P_TRANSA IS NOT NULL THEN 1 ELSE 0 END) = 1
                   OR LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE)) AND (CASE WHEN P_TRANSA IS NOT NULL THEN 1 ELSE 0 END) = 0 );
   EXCEPTION
   WHEN OTHERS THEN
   VL_ESCALONADO:=0;
   END;

   IF VL_ESCALONADO > 0 THEN
    VL_ERROR:='NO APLICA DESCUENTO.';
   ELSIF VL_ESCALONADO = 0 THEN

     BEGIN
        SELECT TBRACCD_AMOUNT
          INTO VL_PARCIALIDAD
          FROM TBRACCD
         WHERE     TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
               AND TBRACCD_PIDM = P_PIDM
               AND TBRACCD_DOCUMENT_NUMBER IS NULL
               AND (       TBRACCD_TRAN_NUMBER = P_TRANSA
                       AND (CASE WHEN P_TRANSA IS NOT NULL THEN 1 ELSE 0 END) = 1
                    OR     LAST_DAY (TBRACCD_EFFECTIVE_DATE) = LAST_DAY (TRUNC (SYSDATE))
                       AND (CASE WHEN P_TRANSA IS NOT NULL THEN 1 ELSE 0 END) = 0)
               AND TBRACCD_STSP_KEY_SEQUENCE = (SELECT SORLCUR_KEY_SEQNO
                                                 FROM SORLCUR
                                                WHERE     SORLCUR_PIDM = P_PIDM
                                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                      AND SORLCUR_ROLL_IND = 'Y'
                                                      AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                      AND SORLCUR_PROGRAM = P_PROGRAMA);
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='NO SE ENCONTRO P_TRANSA =' ||SQLERRM;
     END;

   END IF;

   IF VL_ESCALONADO=0 THEN
     RETURN(VL_PARCIALIDAD);
   ELSE
     RETURN (VL_ERROR);
   END IF;

 END F_PARC_DESCDOM;

PROCEDURE P_INCREMENTO_ARG (P_FECHA DATE)  IS


VL_TZCARRE          NUMBER;
VL_TZDOCTR          NUMBER;
VL_ERROR            VARCHAR2(500);
VL_PORC_ACU         NUMBER;
VL_MESES            NUMBER;
VL_PORC_PARA        NUMBER;
VL_PORC_REAL        NUMBER;
VL_CART_EXISTE      NUMBER;


 BEGIN

    FOR ALUMNO IN (
                             SELECT DISTINCT
                                    SORLCUR_CAMP_CODE CAMP,
                                    SORLCUR_LEVL_CODE NIVEL,
                                    SORLCUR_PROGRAM PROGRAMA,
                                    SPRIDEN_ID ID,
                                    SFRSTCR_PIDM PIDM,
                                    SPRIDEN_FIRST_NAME||' '||SPRIDEN_LAST_NAME ALUMNO,
                                    (SELECT TO_DATE(TRUNC(MIN (SSBSECT_PTRM_START_DATE),'MONTH'))
                                       FROM SFRSTCR F1,SSBSECT T1
                                      WHERE     SFRSTCR_CRN = SSBSECT_CRN
                                            AND SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                                            AND SFRSTCR_PTRM_CODE = SSBSECT_PTRM_CODE
                                            AND SFRSTCR_PIDM = CUR.SORLCUR_PIDM
                                            AND SFRSTCR_STSP_KEY_SEQUENCE = CUR.SORLCUR_KEY_SEQNO
                                            AND (SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR SFRSTCR_DATA_ORIGIN IS NULL)
                                            AND (SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR SFRSTCR_DATA_ORIGIN IS NULL)
                                            AND SFRSTCR_RSTS_CODE = 'RE')FECHA_MATE,
                                    (SELECT DISTINCT SFRSTCR_PTRM_CODE
                                            FROM SFRSTCR A1,SSBSECT
                                          WHERE SFRSTCR_CRN = SSBSECT_CRN
                                            AND SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                                            AND SFRSTCR_PTRM_CODE = SSBSECT_PTRM_CODE
                                            AND SFRSTCR_PIDM = CUR.SORLCUR_PIDM
                                            AND SFRSTCR_STSP_KEY_SEQUENCE = CUR.SORLCUR_KEY_SEQNO
                                            AND (SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR SFRSTCR_DATA_ORIGIN IS NULL)
                                            AND (SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR SFRSTCR_DATA_ORIGIN IS NULL)
                                            AND SFRSTCR_RSTS_CODE = 'RE'
                                            AND SSBSECT_PTRM_START_DATE = (SELECT MIN (SSBSECT_PTRM_START_DATE)
                                                                              FROM SFRSTCR F1,SSBSECT T1
                                                                          WHERE     SFRSTCR_CRN = SSBSECT_CRN
                                                                                AND SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                                                                                AND SFRSTCR_PTRM_CODE = SSBSECT_PTRM_CODE
                                                                                AND SFRSTCR_PIDM = CUR.SORLCUR_PIDM
                                                                                AND SFRSTCR_STSP_KEY_SEQUENCE = CUR.SORLCUR_KEY_SEQNO
                                                                                AND (SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR SFRSTCR_DATA_ORIGIN IS NULL)
                                                                                AND (SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR SFRSTCR_DATA_ORIGIN IS NULL)
                                                                                AND SFRSTCR_RSTS_CODE = 'RE')
                                                                                )PARTE,
                                    (SELECT MAX(TZTINCR_START_DATE)
                                       FROM TZTINCR
                                      WHERE     TZTINCR_PIDM = CUR.SORLCUR_PIDM
                                            AND TZTINCR_STUDY = CUR.SORLCUR_KEY_SEQNO)FECHA_CXC,
                                    SORLCUR_START_DATE FECHA_INICIO,
                                    SORLCUR_KEY_SEQNO STUDY,
                                    SORLCUR_RATE_CODE RATE
                               FROM SFRSTCR HST,
                                    SORLCUR CUR,
                                    SPRIDEN
                              WHERE     HST.SFRSTCR_PIDM=CUR.SORLCUR_PIDM
                                    AND SPRIDEN_PIDM = SORLCUR_PIDM
                                    AND SPRIDEN_CHANGE_IND IS NULL
                                    AND CUR.SORLCUR_LMOD_CODE = 'LEARNER'
                                    AND CUR.SORLCUR_ROLL_IND  = 'Y'
                                    AND CUR.SORLCUR_CACT_CODE = 'ACTIVE'
                                    AND CUR.SORLCUR_SEQNO = (SELECT MAX(CUR2.SORLCUR_SEQNO)
                                                               FROM SORLCUR CUR2
                                                              WHERE     CUR2.SORLCUR_PIDM=CUR.SORLCUR_PIDM
                                                                    AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE
                                                                    AND CUR2.SORLCUR_ROLL_IND = CUR.SORLCUR_ROLL_IND
                                                                    AND CUR2.SORLCUR_CACT_CODE = CUR.SORLCUR_CACT_CODE)
                                    AND CUR.SORLCUR_KEY_SEQNO = HST.SFRSTCR_STSP_KEY_SEQUENCE
                                    AND HST.SFRSTCR_RSTS_CODE = 'RE'
                                    AND (SELECT COUNT(*)
                                           FROM TBRACCD
                                          WHERE     TBRACCD_PIDM = CUR.SORLCUR_PIDM
                                                AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                                AND TBRACCD_STSP_KEY_SEQUENCE = CUR.SORLCUR_KEY_SEQNO
                                                AND TBRACCD_FEED_DATE != CUR.SORLCUR_START_DATE
                                                AND TBRACCD_DOCUMENT_NUMBER IS NULL)>=3
                                    AND SPRIDEN_PIDM NOT IN (SELECT TBRACCD_PIDM
                                                                FROM TBRACCD CCD
                                                               WHERE     CCD.TBRACCD_PIDM = CUR.SORLCUR_PIDM
                                                                     AND SUBSTR(CCD.TBRACCD_DETAIL_CODE,3,2) IN ('RM','RN','RP')
                                                                     AND CCD.TBRACCD_STSP_KEY_SEQUENCE = CUR.SORLCUR_KEY_SEQNO)
                                    AND (HST.SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR HST.SFRSTCR_DATA_ORIGIN IS NULL)
                                    AND (HST.SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR HST.SFRSTCR_DATA_ORIGIN IS NULL)
                                    AND CUR.SORLCUR_START_DATE = P_FECHA
                                    AND SPRIDEN_ID LIKE '39%'
                                    AND CUR.SORLCUR_PIDM NOT IN (SELECT GORADID_PIDM
                                                                   FROM GORADID
                                                                  WHERE GORADID_ADID_CODE IN ('INBE','INBC'))

   )LOOP
     BEGIN
       SELECT COUNT(*)
         INTO VL_MESES
         FROM TBRACCD
        WHERE     TBRACCD_PIDM = ALUMNO.PIDM
              AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
              AND TBRACCD_STSP_KEY_SEQUENCE = ALUMNO.STUDY
              AND TBRACCD_FEED_DATE != ALUMNO.FECHA_INICIO
              AND TBRACCD_DOCUMENT_NUMBER IS NULL;
     END;

     IF VL_MESES >=3 THEN

       VL_PORC_ACU := NULL;
       VL_PORC_REAL:= NULL;

       BEGIN
         SELECT TZDOCTR_PORC_INCREM
           INTO VL_PORC_ACU
           FROM TZDOCTR A
          WHERE     A.TZDOCTR_PIDM = ALUMNO.PIDM
                AND A.TZDOCTR_PROGRAM = ALUMNO.PROGRAMA
                AND A.TZDOCTR_START_DATE != ALUMNO.FECHA_INICIO
                AND A.TZDOCTR_START_DATE = (SELECT MAX(TZDOCTR_START_DATE)
                                              FROM TZDOCTR
                                             WHERE TZDOCTR_PIDM = A.TZDOCTR_PIDM
                                                   AND TZDOCTR_PROGRAM = A.TZDOCTR_PROGRAM
                                                   AND TZDOCTR_START_DATE != ALUMNO.FECHA_INICIO
                                                   AND TZDOCTR_TIPO_PROC = 'ARGE')
                AND TZDOCTR_TIPO_PROC = 'ARGE';
       EXCEPTION
       WHEN OTHERS THEN
       VL_PORC_ACU:=0;
       END;

       BEGIN
         SELECT ZSTPARA_PARAM_VALOR
           INTO VL_PORC_PARA
           FROM ZSTPARA
          WHERE     ZSTPARA_MAPA_ID = 'PORC_INCR'
                AND ZSTPARA_PARAM_ID = ALUMNO.CAMP||ALUMNO.NIVEL;
       EXCEPTION
       WHEN OTHERS THEN
       VL_PORC_PARA:=0;
       END;


       IF VL_MESES IN (3,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60) THEN
       VL_PORC_REAL:=VL_PORC_PARA+VL_PORC_ACU;
       ELSE
       VL_PORC_REAL:=VL_PORC_ACU;
       END IF;

       FOR X IN (

                  SELECT DISTINCT
                         SORLCUR_PIDM PIDM,
                         SORLCUR_KEY_SEQNO STUDY,
                         SORLCUR_PROGRAM PROGRAMA,
                         SORLCUR_RATE_CODE RATE,
                         SORLCUR_CAMP_CODE CAMPUS,
                         SORLCUR_START_DATE,
                         SORLCUR_LEVL_CODE NIVEL,
                         SFRSTCR_TERM_CODE PERIODO,
                         SFRSTCR_PTRM_CODE PPARTE,
                         SSBSECT_PTRM_START_DATE FECHA,
                         (SELECT A.SGBSTDN_STST_CODE
                            FROM SGBSTDN A
                           WHERE A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                                                              FROM SGBSTDN
                                                             WHERE SGBSTDN_PIDM = A.SGBSTDN_PIDM)
                                 AND A.SGBSTDN_PIDM = A.SORLCUR_PIDM)STST_CODE,
                         (SELECT A.SGBSTDN_STYP_CODE
                            FROM SGBSTDN A
                           WHERE A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX(SGBSTDN_TERM_CODE_EFF)
                                                              FROM SGBSTDN
                                                             WHERE SGBSTDN_PIDM = A.SGBSTDN_PIDM)
                                 AND A.SGBSTDN_PIDM = A.SORLCUR_PIDM)TIPO
                    FROM SORLCUR A, SFRSTCR F, SSBSECT G, SZTDTEC E
                   WHERE     A.SORLCUR_LMOD_CODE = 'LEARNER'
                         AND A.SORLCUR_ROLL_IND  = 'Y'
                         AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                         AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                   FROM SORLCUR A1
                                                  WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                        AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                                        AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                                        AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                                        AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE)
                         AND A.SORLCUR_TERM_CODE_CTLG = E.SZTDTEC_TERM_CODE
                         AND F.SFRSTCR_PIDM = A.SORLCUR_PIDM
                         AND F.SFRSTCR_STSP_KEY_SEQUENCE = A.SORLCUR_KEY_SEQNO
                         AND F.SFRSTCR_TERM_CODE = G.SSBSECT_TERM_CODE
                         AND SUBSTR(F.SFRSTCR_TERM_CODE,5,1) NOT IN (8,9)
                         AND (F.SFRSTCR_RESERVED_KEY != 'M1HB401' OR SFRSTCR_RESERVED_KEY IS NULL )
                         AND (F.SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR F.SFRSTCR_DATA_ORIGIN IS NULL)
                         AND (F.SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR SFRSTCR_DATA_ORIGIN IS NULL)
                         AND F.SFRSTCR_CRN = G.SSBSECT_CRN
                         AND F.SFRSTCR_PTRM_CODE = G.SSBSECT_PTRM_CODE
                         AND TRUNC (G.SSBSECT_PTRM_START_DATE) = A.SORLCUR_START_DATE
                         AND A.SORLCUR_START_DATE = ALUMNO.FECHA_INICIO
                         AND A.SORLCUR_PIDM = ALUMNO.PIDM
       )LOOP

         VL_TZCARRE:= NULL;
         VL_TZDOCTR:= NULL;
         VL_CART_EXISTE:= NULL;

         BEGIN
           SELECT COUNT(*)
             INTO VL_TZDOCTR
             FROM TZDOCTR
            WHERE     TZDOCTR_PIDM = X.PIDM
                  AND TZDOCTR_PROGRAM = X.PROGRAMA
                  AND TZDOCTR_TERM_CODE = X.PERIODO
                  AND TZDOCTR_START_DATE = X.FECHA
                  AND TZDOCTR_TIPO_PROC = 'ARGE';
         EXCEPTION
         WHEN OTHERS THEN
         VL_TZDOCTR:=0;
         END;

         IF SUBSTR(ALUMNO.PARTE,2,1) = '0' THEN

           BEGIN
             SELECT COUNT(*)
               INTO VL_CART_EXISTE
               FROM TBRACCD
              WHERE     TBRACCD_PIDM = ALUMNO.PIDM
                    AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                    AND TBRACCD_STSP_KEY_SEQUENCE = ALUMNO.STUDY
                    AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(ALUMNO.FECHA_INICIO + 12)
                    AND TBRACCD_DOCUMENT_NUMBER IS NULL;
           END;

         ELSE
           VL_CART_EXISTE:= 0;

         END IF;

         IF VL_CART_EXISTE = 0 THEN


           IF VL_TZDOCTR = 0 THEN

             BEGIN
               INSERT
                 INTO  TZDOCTR
                      (TZDOCTR_PIDM,
                       TZDOCTR_PROGRAM,
                       TZDOCTR_STST_CODE,
                       TZDOCTR_STYP_CODE,
                       TZDOCTR_CAMP_CODE,
                       TZDOCTR_LEVL_CODE,
                       TZDOCTR_TERM_CODE,
                       TZDOCTR_START_DATE,
                       TZDOCTR_PTRM_CODE,
                       TZDOCTR_STUDY_PATH,
                       FECHA_PROCESO,
                       TZDOCTR_ID,
                       TZDOCTR_TIPO_PROC,
                       TZDOCTR_DESCUENTO,
                       TZDOCTR_PERIODOS_CURSADOS,
                       TZDOCTR_PORC_INCREM)
                VALUES (X.PIDM,
                        X.PROGRAMA,
                        X.STST_CODE,
                        X.TIPO,
                        ALUMNO.CAMP,
                        ALUMNO.NIVEL,
                        X.PERIODO,
                        X.FECHA,
                        X.PPARTE,
                        X.STUDY,
                        SYSDATE,
                        ALUMNO.ID,
                        'ARGE',
                        0,
                        0,
                        VL_PORC_REAL);
             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR:=('Error 1 TZDOCTR '|| ALUMNO.PIDM ||'*'||SQLERRM);
             END;

           ELSE

             BEGIN
               DELETE TZDOCTR
                WHERE     TZDOCTR_PIDM = X.PIDM
                      AND TZDOCTR_PROGRAM = X.PROGRAMA
                      AND TZDOCTR_TERM_CODE = X.PERIODO
                      AND TZDOCTR_START_DATE = X.FECHA
                      AND TZDOCTR_TIPO_PROC = 'ARGE';
             END;

             BEGIN
               INSERT
                 INTO  TZDOCTR
                      (TZDOCTR_PIDM,
                       TZDOCTR_PROGRAM,
                       TZDOCTR_STST_CODE,
                       TZDOCTR_STYP_CODE,
                       TZDOCTR_CAMP_CODE,
                       TZDOCTR_LEVL_CODE,
                       TZDOCTR_TERM_CODE,
                       TZDOCTR_START_DATE,
                       TZDOCTR_PTRM_CODE,
                       TZDOCTR_STUDY_PATH,
                       FECHA_PROCESO,
                       TZDOCTR_ID,
                       TZDOCTR_TIPO_PROC,
                       TZDOCTR_DESCUENTO,
                       TZDOCTR_PERIODOS_CURSADOS,
                       TZDOCTR_PORC_INCREM)
                VALUES (X.PIDM,
                        X.PROGRAMA,
                        X.STST_CODE,
                        X.TIPO,
                        ALUMNO.CAMP,
                        ALUMNO.NIVEL,
                        X.PERIODO,
                        X.FECHA,
                        X.PPARTE,
                        X.STUDY,
                        SYSDATE,
                        ALUMNO.ID,
                        'ARGE',
                        0,
                        0,
                        VL_PORC_REAL);
             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR:=('Error 2 TZDOCTR '|| ALUMNO.PIDM ||'*'||SQLERRM);
             END;



           END IF;

         END IF;

       END LOOP;

     END IF;

   END LOOP;

  COMMIT;

 END P_INCREMENTO_ARG;

FUNCTION F_MONTO_INCRE (P_CAMP          VARCHAR2,
                        P_NIVEL         VARCHAR2,
                        P_PIDM          NUMBER,
                        P_PROGRAMA      VARCHAR2,
                        P_FECHA_INICIO  DATE,
                        P_STUDY         NUMBER) RETURN NUMBER IS

VL_MESES        NUMBER;
VL_PORC_ACU     NUMBER;
VL_PORC_PARA    NUMBER;
VL_PORC_REAL    NUMBER:=0;
VL_BANDERA      NUMBER:=0;
VL_MONTO        NUMBER;
VL_ERROR        VARCHAR2(50);

 BEGIN
   BEGIN
       SELECT COUNT(*)
         INTO VL_MESES
         FROM TBRACCD
        WHERE     TBRACCD_PIDM = P_PIDM
              AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
              AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY
              AND TBRACCD_DOCUMENT_NUMBER IS NULL;
   END;

   IF VL_MESES >= 4 THEN

       VL_PORC_ACU := NULL;
       VL_PORC_REAL:= NULL;

       BEGIN
         SELECT TZDOCTR_PORC_INCREM
           INTO VL_PORC_ACU
           FROM TZDOCTR A
          WHERE     A.TZDOCTR_PIDM = P_PIDM
                AND A.TZDOCTR_PROGRAM = P_PROGRAMA
                AND A.TZDOCTR_START_DATE != P_FECHA_INICIO
                AND A.TZDOCTR_START_DATE = (SELECT MAX(TZDOCTR_START_DATE)
                                              FROM TZDOCTR
                                             WHERE TZDOCTR_PIDM = A.TZDOCTR_PIDM
                                                   AND TZDOCTR_PROGRAM = A.TZDOCTR_PROGRAM
                                                   AND TZDOCTR_START_DATE != P_FECHA_INICIO
                                                   AND TZDOCTR_TIPO_PROC = 'ARGE')
                AND TZDOCTR_TIPO_PROC = 'ARGE';
       EXCEPTION
       WHEN OTHERS THEN
         BEGIN
           SELECT TZDOCTR_PORC_INCREM
             INTO VL_PORC_ACU
             FROM TZDOCTR A
            WHERE     A.TZDOCTR_PIDM = P_PIDM
                  AND A.TZDOCTR_PROGRAM = P_PROGRAMA
                  AND A.TZDOCTR_START_DATE = P_FECHA_INICIO
                  AND A.TZDOCTR_START_DATE = (SELECT MAX(TZDOCTR_START_DATE)
                                                FROM TZDOCTR
                                               WHERE TZDOCTR_PIDM = A.TZDOCTR_PIDM
                                                     AND TZDOCTR_PROGRAM = A.TZDOCTR_PROGRAM
                                                     AND TZDOCTR_START_DATE = P_FECHA_INICIO
                                                     AND TZDOCTR_TIPO_PROC = 'ARGE')
                  AND TZDOCTR_TIPO_PROC = 'ARGE';
          VL_BANDERA:=1;
         EXCEPTION
         WHEN OTHERS THEN
           VL_PORC_ACU:=0;
           VL_ERROR:='SIN INCREMENTO';
         END;
       END;

       BEGIN
         SELECT ZSTPARA_PARAM_VALOR
           INTO VL_PORC_PARA
           FROM ZSTPARA
          WHERE     ZSTPARA_MAPA_ID = 'PORC_INCR'
                AND ZSTPARA_PARAM_ID = P_CAMP||P_NIVEL;
       EXCEPTION
       WHEN OTHERS THEN
       VL_PORC_PARA:=0;
       END;


       IF VL_MESES IN (4,8,12,16,20,24,28,32,36,40,44,48,52,56,60) THEN
         IF VL_BANDERA = 1 THEN
           VL_PORC_REAL:=VL_PORC_PARA/100;
         ELSE
           VL_PORC_REAL:=(VL_PORC_PARA+VL_PORC_ACU)/100;
         END IF;
       ELSE
       VL_PORC_REAL:=VL_PORC_ACU/100;
       END IF;
   END IF;

   IF VL_ERROR IS NULL THEN
     VL_PORC_REAL:=VL_PORC_REAL;
   ELSE
     VL_PORC_REAL:=0;
   END IF;

   RETURN(VL_PORC_REAL);

 END F_MONTO_INCRE;

FUNCTION F_ACC_RECURENTE (P_PIDM        NUMBER,
                          P_PERIODO     VARCHAR2,
                          P_VIGENCIA    DATE,
                          P_STUDY       NUMBER,
                          P_PARTE       VARCHAR2,
                          P_ORDEN       NUMBER
                                                )RETURN VARCHAR2 IS

VL_ERROR                VARCHAR2(900);
VL_SECUENCIA            NUMBER;

 BEGIN
   BEGIN
     FOR X IN (
                 SELECT TBBDETC_DESC,TZFACCE_AMOUNT,TZFACCE_DETAIL_CODE,TVRDCTX_CURR_CODE MONEDA
                   FROM ZSTPARA,TBBDETC,TZFACCE,TVRDCTX
                  WHERE     ZSTPARA_PARAM_ID = SUBSTR(TBBDETC_DETAIL_CODE,3,2)
                        AND ZSTPARA_MAPA_ID = 'ACC_ALIANZA'
                        AND TZFACCE_DETAIL_CODE = TBBDETC_DETAIL_CODE
                        AND TBBDETC_DETAIL_CODE = TVRDCTX_DETC_CODE
                        AND ZSTPARA_PARAM_ID = SUBSTR(TZFACCE_DETAIL_CODE,3,2)
                        AND TZFACCE_PIDM = P_PIDM
                        AND TZFACCE_FLAG = 0
     )LOOP
     VL_ERROR:=NULL;

       BEGIN
         SELECT MAX(TBRACCD_TRAN_NUMBER)+1
         INTO VL_SECUENCIA
           FROM TBRACCD
           WHERE TBRACCD_PIDM = P_PIDM;
       END;

       BEGIN
         INSERT
           INTO TBRACCD (  TBRACCD_PIDM
                         , TBRACCD_TRAN_NUMBER
                         , TBRACCD_TRAN_NUMBER_PAID
                         , TBRACCD_CROSSREF_NUMBER
                         , TBRACCD_TERM_CODE
                         , TBRACCD_DETAIL_CODE
                         , TBRACCD_USER
                         , TBRACCD_ENTRY_DATE
                         , TBRACCD_AMOUNT
                         , TBRACCD_BALANCE
                         , TBRACCD_EFFECTIVE_DATE
                         , TBRACCD_FEED_DATE
                         , TBRACCD_DESC
                         , TBRACCD_SRCE_CODE
                         , TBRACCD_ACCT_FEED_IND
                         , TBRACCD_ACTIVITY_DATE
                         , TBRACCD_SESSION_NUMBER
                         , TBRACCD_TRANS_DATE
                         , TBRACCD_CURR_CODE
                         , TBRACCD_DATA_ORIGIN
                         , TBRACCD_CREATE_SOURCE
                         , TBRACCD_STSP_KEY_SEQUENCE
                         , TBRACCD_PERIOD
                         , TBRACCD_USER_ID
                         , TBRACCD_RECEIPT_NUMBER)
         VALUES (P_PIDM,                 -- TBRACCD_PIDM
                 VL_SECUENCIA,           -- TBRACCD_TRAN_NUMBER
                 NULL,                   -- TBRACCD_TRAN_NUMBER_PAID
                 NULL,                   -- TBRACCD_CROSSREF_NUMBER
                 P_PERIODO,              -- TBRACCD_TERM_CODE
                 X.TZFACCE_DETAIL_CODE,  -- TBRACCD_DETAIL_CODE
                 USER,                   -- TBRACCD_USER
                 SYSDATE,                -- TBRACCD_ENTRY_DATE
                 X.TZFACCE_AMOUNT,       -- TBRACCD_AMOUNT
                 X.TZFACCE_AMOUNT,       -- TBRACCD_BALANCE
                 to_date(P_VIGENCIA,'DD/MM/RRRR'),             -- TBRACCD_EFFECTIVE_DATE
                 NULL,                   -- TBRACCD_FEED_DATE
                 X.TBBDETC_DESC,         -- TBRACCD_DESC
                 'T',                    -- TBRACCD_SRCE_CODE
                 'Y',                    -- TBRACCD_ACCT_FEED_IND
                 SYSDATE,                -- TBRACCD_ACTIVITY_DATE
                 0,                      -- TBRACCD_SESSION_NUMBER
                 P_VIGENCIA,             -- TBRACCD_TRANS_DATE
                 X.MONEDA,               -- TBRACCD_CURR_CODE
                 'TZFEDCA (ACC)',        -- TBRACCD_DATA_ORIGIN
                 'TZFEDCA (ACC)',        -- TBRACCD_CREATE_SOURCE
                 P_STUDY,                -- TBRACCD_STSP_KEY_SEQUENCE
                 P_PARTE,                -- TBRACCD_PERIOD
                 USER,                   -- TBRACCD_USER_ID
                 P_ORDEN);
       EXCEPTION
       WHEN OTHERS THEN
       VL_ERROR :='Error al insertar cargo = '||SQLERRM;
       END;

     END LOOP;
   END;

   IF VL_ERROR IS NULL THEN
     COMMIT;
   ELSE
     ROLLBACK;
   END IF;

  RETURN(VL_ERROR);

 END F_ACC_RECURENTE;

FUNCTION F_ACT_DATOS RETURN PKG_FINANZAS_REZA.CURSOR_DATA_OUT AS
 DATA_OUT PKG_FINANZAS_REZA.CURSOR_DATA_OUT;


 BEGIN
        BEGIN
           OPEN DATA_OUT FOR
           SELECT DISTINCT SPRIDEN_ID MATRICULA,
                           REPLACE(SPRIDEN_LAST_NAME,'/',' ') APELLIDO,
                           SPRIDEN_FIRST_NAME NOMBRE,
                           A.GOREMAL_EMAIL_ADDRESS CORREO,
                           GZTPASS_PIN
                            FROM SPRIDEN,GZTPASS,GOREMAL A
                           WHERE GZTPASS_PIDM = SPRIDEN_PIDM
                           AND GOREMAL_PIDM=SPRIDEN_PIDM
                           AND GOREMAL_PIDM=GZTPASS_PIDM
                           AND SPRIDEN_CHANGE_IND IS NULL
                           AND SUBSTR(SPRIDEN_ID,1,2)='41'
                           AND A.GOREMAL_STATUS_IND = 'A'
                           AND TRUNC (GOREMAL_ACTIVITY_DATE)= TRUNC(SYSDATE)
                           AND A.GOREMAL_EMAL_CODE = NVL ('PRIN', A.GOREMAL_EMAL_CODE)
                           AND A.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                            FROM GOREMAL A1
                                                            WHERE A1.GOREMAL_PIDM = A.GOREMAL_PIDM
                                                            AND A1.GOREMAL_EMAL_CODE = A.GOREMAL_EMAL_CODE
                                                            AND A1.GOREMAL_STATUS_IND = A.GOREMAL_STATUS_IND
                                                            AND A1.GOREMAL_ACTIVITY_DATE = A.GOREMAL_ACTIVITY_DATE)
            UNION
            SELECT DISTINCT SPRIDEN_ID MATRICULA,
                            REPLACE(SPRIDEN_LAST_NAME,'/',' ') APELLIDO,
                            SPRIDEN_FIRST_NAME NOMBRE,
                            A.GOREMAL_EMAIL_ADDRESS CORREO,
                            GZTPASS_PIN
                             FROM SPRIDEN,GZTPASS,GOREMAL A
                           WHERE GZTPASS_PIDM = SPRIDEN_PIDM
                           AND GOREMAL_PIDM=SPRIDEN_PIDM
                           AND GOREMAL_PIDM=GZTPASS_PIDM
                           AND SPRIDEN_CHANGE_IND IS NULL
                           AND SUBSTR(SPRIDEN_ID,1,2)='41'
                           AND A.GOREMAL_STATUS_IND = 'A'
                           AND TRUNC(GZTPASS_DATE_UPDATE) = TRUNC(SYSDATE)
                           AND A.GOREMAL_EMAL_CODE = NVL ('PRIN', A.GOREMAL_EMAL_CODE)
                           AND A.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                        FROM GOREMAL A1
                                                        WHERE A1.GOREMAL_PIDM = A.GOREMAL_PIDM
                                                        AND A1.GOREMAL_EMAL_CODE = A.GOREMAL_EMAL_CODE
                                                        AND A1.GOREMAL_STATUS_IND = A.GOREMAL_STATUS_IND)
                           AND GZTPASS_PIDM     IN      (SELECT GZTPASS_PIDM
                                                         FROM GZTPASS A
                                                         WHERE A.GZTPASS_PIDM=GZTPASS_PIDM
                                                         AND A.GZTPASS_DATE_UPDATE = GZTPASS_DATE_UPDATE);
          RETURN (DATA_OUT);
          END;
     END F_ACT_DATOS;

FUNCTION F_ACC_DIFERIDO(P_PIDM      NUMBER,
                        P_CODIGO    VARCHAR2,
                        P_CARGOS    NUMBER,
                        P_PROGRAMA  VARCHAR2,
                        P_SERVICIO  NUMBER,
                        P_TIPO_SER  VARCHAR2
                        )RETURN VARCHAR2 IS

VL_ERROR                VARCHAR2(900);
VL_MONTO                NUMBER;
VL_SECUENCIA            NUMBER;
VL_COD_DIFER            VARCHAR2(5);
VL_DESC_DIFE            VARCHAR2(50);
VL_FECHA_EFE            DATE;
VL_PERIODO              VARCHAR2(11);
VL_CAMPUS               VARCHAR2(4);
VL_NIVEL                VARCHAR2(4);
VL_STUDY                NUMBER;
VL_MATRICULA            VARCHAR2(11);
VL_FOLIO                NUMBER;
VL_SECUENCIA_INICIAL    NUMBER;
VL_MESES                NUMBER;
VL_SALTO_FECHA          NUMBER;
VL_DIA_SALTO            NUMBER;

 BEGIN

   BEGIN
     SELECT ZSTPARA_PARAM_VALOR,TBBDETC_DESC
       INTO VL_COD_DIFER,VL_DESC_DIFE
       FROM ZSTPARA,TBBDETC
      WHERE     ZSTPARA_PARAM_VALOR = TBBDETC_DETAIL_CODE
            AND ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'
            AND ZSTPARA_PARAM_ID = P_CODIGO;
   EXCEPTION
   WHEN OTHERS THEN
   VL_ERROR:='ERROR AL CALCULAR CODIGO = '||P_CODIGO||', '||SQLERRM;
   END;

   BEGIN
     SELECT ROUND(TBBDETC_AMOUNT/P_CARGOS,2)
       INTO VL_MONTO
       FROM TBBDETC
      WHERE TBBDETC_DETAIL_CODE = P_CODIGO;
   EXCEPTION
   WHEN OTHERS THEN
   VL_ERROR:= 'ERROR AL CALCULAR MONTO '||SQLERRM;
   END;

   BEGIN
     SELECT SORLCUR_CAMP_CODE,SORLCUR_LEVL_CODE,SORLCUR_KEY_SEQNO
       INTO VL_CAMPUS,VL_NIVEL,VL_STUDY
       FROM SORLCUR A
      WHERE     A.SORLCUR_PIDM = P_PIDM
            AND A.SORLCUR_LMOD_CODE = 'LEARNER'
            AND A.SORLCUR_ROLL_IND  = 'Y'
            AND A.SORLCUR_CACT_CODE = 'ACTIVE'
            AND A.SORLCUR_PROGRAM = P_PROGRAMA
            AND A.SORLCUR_SEQNO = ( SELECT MAX(SORLCUR_SEQNO)
                                      FROM SORLCUR
                                     WHERE     SORLCUR_PIDM = A.SORLCUR_PIDM
                                           AND SORLCUR_LMOD_CODE = 'LEARNER'
                                           AND SORLCUR_ROLL_IND  = 'Y'
                                           AND SORLCUR_CACT_CODE = 'ACTIVE'
                                           AND SORLCUR_PROGRAM = P_PROGRAMA);
   EXCEPTION
   WHEN OTHERS THEN
     BEGIN
       SELECT SORLCUR_CAMP_CODE,SORLCUR_LEVL_CODE,SORLCUR_KEY_SEQNO
         INTO VL_CAMPUS,VL_NIVEL,VL_STUDY
         FROM SORLCUR A
        WHERE     A.SORLCUR_PIDM = P_PIDM
              AND A.SORLCUR_LMOD_CODE = 'LEARNER'
              AND A.SORLCUR_PROGRAM = P_PROGRAMA
              AND A.SORLCUR_SEQNO = ( SELECT MAX(SORLCUR_SEQNO)
                                        FROM SORLCUR
                                       WHERE     SORLCUR_PIDM = A.SORLCUR_PIDM
                                             AND SORLCUR_LMOD_CODE = 'LEARNER'
                                             AND SORLCUR_PROGRAM = P_PROGRAMA);

     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR AL CALCULAR STUDY = '||SQLERRM;
     END;
   END;

   BEGIN
     SELECT MAX(DISTINCT SOBPTRM_TERM_CODE)
       INTO VL_PERIODO
       FROM SOBPTRM
      WHERE     SUBSTR(SOBPTRM_TERM_CODE,1,2) = SUBSTR(P_CODIGO,1,2)
            AND SUBSTR(SOBPTRM_TERM_CODE,5,1) NOT IN (8,9,0)
            AND SUBSTR(SOBPTRM_PTRM_CODE,1,1) =
                                                CASE VL_NIVEL
                                                   WHEN 'MA' THEN 'M'
                                                   WHEN 'LI' THEN 'L'
                                                   WHEN 'DO' THEN 'O'
                                                   WHEN 'EC' THEN 'D'
                                                   WHEN 'MS' THEN 'A'
                                                END
            AND TO_DATE(SYSDATE) BETWEEN SOBPTRM_START_DATE AND SOBPTRM_END_DATE;
   EXCEPTION
   WHEN OTHERS THEN
   VL_ERROR:='ERROR AL CALCULAR PERIODO = '||SQLERRM;
   END;

   BEGIN
     SELECT SPRIDEN_ID
       INTO VL_MATRICULA
       FROM SPRIDEN
      WHERE     SPRIDEN_PIDM = P_PIDM
            AND SPRIDEN_CHANGE_IND IS NULL;
   END;

   --DBMS_OUTPUT.PUT_LINE('ACC DIFERIDO 1 = '||VL_ERROR||' = '||VL_PERIODO);

   IF P_TIPO_SER IS NOT NULL THEN
       BEGIN    -----------------recupera la parte de periodo que solicito el alumno
         SELECT SUBSTR(TO_CHAR(SUBSTR(RANGO,1, INSTR(RANGO,'-AL-',1 )-1)),4,2),
                SUBSTR(TO_CHAR(SUBSTR(RANGO,1, INSTR(RANGO,'-AL-',1 )-1)),1,2)
           INTO VL_SALTO_FECHA,VL_DIA_SALTO
           FROM ( SELECT SVRSVAD_ADDL_DATA_DESC  RANGO
                    FROM SVRSVPR V,SVRSVAD VA
                   WHERE     SVRSVPR_SRVC_CODE = P_TIPO_SER
                         AND SVRSVPR_PROTOCOL_SEQ_NO = P_SERVICIO
                         AND SVRSVPR_PIDM    = P_PIDM
                         AND V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                         AND VA.SVRSVAD_ADDL_DATA_SEQ = '7') ;
       EXCEPTION WHEN OTHERS THEN
       VL_ERROR:='ERROR REZA FECHA '||SQLERRM;
       END;
   END IF;

   IF P_TIPO_SER IS NULL THEN
    VL_FECHA_EFE:= (TRUNC(SYSDATE+1)-(TO_CHAR(TRUNC(SYSDATE),'DD')))+9 ;
   ELSE

     IF VL_DIA_SALTO >20 THEN
       VL_SALTO_FECHA:=VL_SALTO_FECHA+1;
     END IF;

     VL_MESES:=VL_SALTO_FECHA-(TO_CHAR(TRUNC(SYSDATE),'MM'));

     IF VL_MESES < 0 THEN
       VL_MESES:= VL_MESES+12;
     END IF;

     BEGIN
       VL_FECHA_EFE:= (TRUNC(SYSDATE+1)-(TO_CHAR(TRUNC(SYSDATE),'DD')))+9;
     END;

     BEGIN
       VL_FECHA_EFE:= ADD_MONTHS(VL_FECHA_EFE,VL_MESES);
     END;

   END IF;

   IF VL_ERROR IS NULL THEN
     BEGIN
       FOR DIF IN 1..P_CARGOS LOOP

         IF VL_FECHA_EFE <= TRUNC(SYSDATE) THEN
           VL_FECHA_EFE:= ADD_MONTHS(VL_FECHA_EFE,1);
         END IF;

         BEGIN
           SELECT MAX(TBRACCD_TRAN_NUMBER)+1
           INTO VL_SECUENCIA
             FROM TBRACCD
             WHERE TBRACCD_PIDM = P_PIDM;
         END;


         BEGIN
           INSERT
             INTO TBRACCD (  TBRACCD_PIDM
                           , TBRACCD_TRAN_NUMBER
                           , TBRACCD_TRAN_NUMBER_PAID
                           , TBRACCD_CROSSREF_NUMBER
                           , TBRACCD_TERM_CODE
                           , TBRACCD_DETAIL_CODE
                           , TBRACCD_USER
                           , TBRACCD_ENTRY_DATE
                           , TBRACCD_AMOUNT
                           , TBRACCD_BALANCE
                           , TBRACCD_EFFECTIVE_DATE
                           , TBRACCD_FEED_DATE
                           , TBRACCD_DESC --No SecPAdre
                           , TBRACCD_SRCE_CODE
                           , TBRACCD_ACCT_FEED_IND
                           , TBRACCD_ACTIVITY_DATE
                           , TBRACCD_SESSION_NUMBER
                           , TBRACCD_TRANS_DATE
                           , TBRACCD_CURR_CODE
                           , TBRACCD_DATA_ORIGIN
                           , TBRACCD_CREATE_SOURCE
                           , TBRACCD_STSP_KEY_SEQUENCE
                           , TBRACCD_PERIOD
                           , TBRACCD_USER_ID
                           , TBRACCD_RECEIPT_NUMBER)
           VALUES (P_PIDM,                 -- TBRACCD_PIDM
                   VL_SECUENCIA,           -- TBRACCD_TRAN_NUMBER
                   NULL,                   -- TBRACCD_TRAN_NUMBER_PAID
                   P_SERVICIO,             -- TBRACCD_CROSSREF_NUMBER
                   VL_PERIODO,             -- TBRACCD_TERM_CODE
                   VL_COD_DIFER,           -- TBRACCD_DETAIL_CODE
                   USER,                   -- TBRACCD_USER
                   SYSDATE,                -- TBRACCD_ENTRY_DATE
                   VL_MONTO,               -- TBRACCD_AMOUNT
                   VL_MONTO,               -- TBRACCD_BALANCE
                   VL_FECHA_EFE,           -- TBRACCD_EFFECTIVE_DATE
                   NULL,                   -- TBRACCD_FEED_DATE
                   VL_DESC_DIFE,           -- TBRACCD_DESC
                   'T',                    -- TBRACCD_SRCE_CODE
                   'Y',                    -- TBRACCD_ACCT_FEED_IND
                   SYSDATE,                -- TBRACCD_ACTIVITY_DATE
                   0,                      -- TBRACCD_SESSION_NUMBER
                   VL_FECHA_EFE,           -- TBRACCD_TRANS_DATE
                   'MXN',                  -- TBRACCD_CURR_CODE
                   'ACC_DIFER',            -- TBRACCD_DATA_ORIGIN
                   'ACC_DIFER',            -- TBRACCD_CREATE_SOURCE
                   VL_STUDY,               -- TBRACCD_STSP_KEY_SEQUENCE
                   NULL,                   -- TBRACCD_PERIOD
                   USER,                   -- TBRACCD_USER_ID
                   NULL);
         EXCEPTION
         WHEN OTHERS THEN
         VL_ERROR :='Error al insertar cargo = '||SQLERRM;
         END;

         VL_FECHA_EFE:= ADD_MONTHS(VL_FECHA_EFE,1);

       END LOOP;

       BEGIN
       SELECT MIN(TBRACCD_TRAN_NUMBER)
       INTO VL_SECUENCIA_INICIAL
       FROM TBRACCD
       WHERE TBRACCD_PIDM=P_PIDM
       AND TBRACCD_CROSSREF_NUMBER=P_SERVICIO;
       END;


       IF VL_ERROR IS NULL THEN

         BEGIN
           SELECT MAX(TZTORDR_CONTADOR)+1
             INTO VL_FOLIO
             FROM TZTORDR;
         EXCEPTION
         WHEN OTHERS THEN
         VL_FOLIO:= NULL;
         END;

         BEGIN

           INSERT
             INTO TZTORDR (  TZTORDR_CAMPUS,
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
                             TZTORDR_TERM_CODE)
           VALUES ( VL_CAMPUS,
                    VL_NIVEL,
                    VL_FOLIO,
                    P_PROGRAMA,
                    P_PIDM,
                    VL_MATRICULA,
                    'S',
                    SYSDATE,
                    USER,
                    'ACC_DIFER',
                    NULL,
                    TRUNC(SYSDATE),
                    NULL,
                    NULL,
                    NULL,
                    VL_PERIODO);
         EXCEPTION
         WHEN OTHERS THEN
         VL_ERROR:='ERROR AL GUARDAR ORDEN = '||SQLERRM;
         END;

         BEGIN
           UPDATE TBRACCD
              SET TBRACCD_RECEIPT_NUMBER = VL_FOLIO
            WHERE     TBRACCD_PIDM = P_PIDM
                  AND TBRACCD_DETAIL_CODE =  VL_COD_DIFER
                  AND TRUNC(TBRACCD_ENTRY_DATE) = TRUNC(SYSDATE);

           UPDATE TVRACCD
              SET TVRACCD_RECEIPT_NUMBER = VL_FOLIO
            WHERE     TVRACCD_PIDM = P_PIDM
                  AND TVRACCD_DETAIL_CODE =  VL_COD_DIFER
                  AND TRUNC(TVRACCD_ENTRY_DATE) = TRUNC(SYSDATE);
         END;

       END IF;
     END;

   END IF;

   IF VL_ERROR IS NULL THEN
     VL_ERROR:='EXITO|'||VL_SECUENCIA_INICIAL;
     COMMIT;
   ELSE
     ROLLBACK;
   END IF;

  RETURN(VL_ERROR);

 END F_ACC_DIFERIDO;

 FUNCTION F_CANCELA_DIFERIDO(P_PIDM      NUMBER,
                            P_SERVICIO  NUMBER)RETURN VARCHAR2 IS

VL_ERROR            VARCHAR2(900);
VL_SECUENCIA        NUMBER;
VL_COD_DIFER        VARCHAR2(5);
VL_DESC_DIFE        VARCHAR2(50);
VL_FECHA_EFE        DATE;
VL_MATRICULA        VARCHAR2(11);
VL_ACC_DIF          VARCHAR2(40);
VL_COD_CANCELA      VARCHAR2(5);

 BEGIN
   BEGIN
     SELECT SPRIDEN_ID
       INTO VL_MATRICULA
       FROM SPRIDEN
      WHERE     SPRIDEN_PIDM = P_PIDM
            AND SPRIDEN_CHANGE_IND IS NULL;
   END;

   BEGIN
     SELECT DISTINCT TBRACCD_DETAIL_CODE
       INTO VL_ACC_DIF
       FROM TBRACCD,TBBDETC
       WHERE TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
       AND TBRACCD_CROSSREF_NUMBER = P_SERVICIO
       AND TBBDETC_TYPE_IND = 'C'
       AND TBRACCD_PIDM = P_PIDM;
   EXCEPTION
   WHEN OTHERS THEN
   VL_ACC_DIF:=NULL;
   END;

   BEGIN
       SELECT SUBSTR(VL_ACC_DIF,1,2)||ZSTPARA_PARAM_VALOR
         INTO VL_COD_CANCELA
         FROM ZSTPARA
        WHERE     ZSTPARA_MAPA_ID = 'ABCC_DIFERIDO'
              AND ZSTPARA_PARAM_ID = SUBSTR(VL_ACC_DIF,3,2);
              EXCEPTION
   WHEN OTHERS THEN
   VL_COD_CANCELA:=NULL;
   END;

   IF VL_COD_CANCELA IS NULL THEN

     VL_COD_DIFER:= SUBSTR(VL_MATRICULA,1,2)||'RE';

   ELSE
    VL_COD_DIFER:=VL_COD_CANCELA;
   END IF;

   BEGIN
     SELECT TBBDETC_DESC
     INTO VL_DESC_DIFE
     FROM TBBDETC
     WHERE TBBDETC_DETAIL_CODE = VL_COD_DIFER;
   EXCEPTION WHEN OTHERS THEN
     VL_ERROR:='ERROR AL CALCULAR COD = '||SQLERRM;
   END;
   --DBMS_OUTPUT.PUT_LINE('respuesta final = '||VL_DESC_DIFE||' = '||VL_COD_DIFER||' = '||VL_MATRICULA);
   BEGIN
       FOR DIF IN (

             SELECT *
               FROM TBRACCD
              WHERE     TBRACCD_PIDM = P_PIDM
                    AND TBRACCD_CROSSREF_NUMBER = P_SERVICIO
                    AND TBRACCD_DOCUMENT_NUMBER IS NULL

       )LOOP

        IF DIF.TBRACCD_AMOUNT = DIF.TBRACCD_BALANCE THEN

             BEGIN
               SELECT MAX(TBRACCD_TRAN_NUMBER)+1
               INTO VL_SECUENCIA
                 FROM TBRACCD
                 WHERE TBRACCD_PIDM = P_PIDM;
             END;

             IF DIF.TBRACCD_EFFECTIVE_DATE >= TRUNC(SYSDATE) THEN
               VL_FECHA_EFE:= DIF.TBRACCD_EFFECTIVE_DATE;
             ELSE
               VL_FECHA_EFE:=TRUNC(SYSDATE);
             END IF;


             BEGIN
               INSERT
                 INTO TBRACCD (  TBRACCD_PIDM
                               , TBRACCD_TRAN_NUMBER
                               , TBRACCD_TRAN_NUMBER_PAID
                               , TBRACCD_CROSSREF_NUMBER
                               , TBRACCD_TERM_CODE
                               , TBRACCD_DETAIL_CODE
                               , TBRACCD_USER
                               , TBRACCD_ENTRY_DATE
                               , TBRACCD_AMOUNT
                               , TBRACCD_BALANCE
                               , TBRACCD_EFFECTIVE_DATE
                               , TBRACCD_FEED_DATE
                               , TBRACCD_DESC --No SecPAdre
                               , TBRACCD_SRCE_CODE
                               , TBRACCD_ACCT_FEED_IND
                               , TBRACCD_ACTIVITY_DATE
                               , TBRACCD_SESSION_NUMBER
                               , TBRACCD_TRANS_DATE
                               , TBRACCD_CURR_CODE
                               , TBRACCD_DATA_ORIGIN
                               , TBRACCD_CREATE_SOURCE
                               , TBRACCD_STSP_KEY_SEQUENCE
                               , TBRACCD_PERIOD
                               , TBRACCD_USER_ID
                               , TBRACCD_RECEIPT_NUMBER)
               VALUES (P_PIDM,                 -- TBRACCD_PIDM
                       VL_SECUENCIA,           -- TBRACCD_TRAN_NUMBER
                       DIF.TBRACCD_TRAN_NUMBER,-- TBRACCD_TRAN_NUMBER_PAID
                       P_SERVICIO,             -- TBRACCD_CROSSREF_NUMBER
                       DIF.TBRACCD_TERM_CODE,  -- TBRACCD_TERM_CODE
                       VL_COD_DIFER,           -- TBRACCD_DETAIL_CODE
                       USER,                   -- TBRACCD_USER
                       SYSDATE,                -- TBRACCD_ENTRY_DATE
                       DIF.TBRACCD_AMOUNT,     -- TBRACCD_AMOUNT
                       DIF.TBRACCD_AMOUNT*-1,  -- TBRACCD_BALANCE
                       VL_FECHA_EFE,           -- TBRACCD_EFFECTIVE_DATE
                       NULL,                   -- TBRACCD_FEED_DATE
                       VL_DESC_DIFE,           -- TBRACCD_DESC
                       'T',                    -- TBRACCD_SRCE_CODE
                       'Y',                    -- TBRACCD_ACCT_FEED_IND
                       SYSDATE,                -- TBRACCD_ACTIVITY_DATE
                       0,                      -- TBRACCD_SESSION_NUMBER
                       VL_FECHA_EFE,           -- TBRACCD_TRANS_DATE
                       'MXN',                  -- TBRACCD_CURR_CODE
                       'ACC_DIFER',            -- TBRACCD_DATA_ORIGIN
                       'ACC_DIFER',            -- TBRACCD_CREATE_SOURCE
                       NULL,                   -- TBRACCD_STSP_KEY_SEQUENCE
                       NULL,                   -- TBRACCD_PERIOD
                       USER,                   -- TBRACCD_USER_ID
                       NULL);
             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR :='Error al insertar cargo = '||SQLERRM;
             END;
        END IF;
      END LOOP;

     BEGIN
       UPDATE TBRACCD
          SET TBRACCD_DOCUMENT_NUMBER = 'WCANCE'
        WHERE     TBRACCD_PIDM = P_PIDM
              AND TBRACCD_CROSSREF_NUMBER = P_SERVICIO
              AND TBRACCD_DETAIL_CODE NOT IN (SELECT TBBDETC_DETAIL_CODE
                                                FROM TBBDETC
                                               WHERE TBBDETC_DCAT_CODE = 'ENV');
     END;
   END;

   IF VL_ERROR IS NULL THEN
     VL_ERROR:='EXITO';
     COMMIT;
   ELSE
     ROLLBACK;
   END IF;

  RETURN(VL_ERROR);

 END F_CANCELA_DIFERIDO;

FUNCTION F_COMPLE_FILI (P_FECHA        DATE,
                         P_PIDM         NUMBER,
                         P_CODIGO       VARCHAR2,
                         P_DESCRI       VARCHAR2,
                         P_MONTO        NUMBER,
                         P_PERIODO      VARCHAR2,
                         P_SOL          NUMBER) RETURN VARCHAR2 IS

/* FUNCIÓN PARA EL ROLADO DE COMPLEMENTO DE FILIPINAS
   AUTOR: JREZAOLI
   ACTUALIZACIÓN: 22/10/2021   */

 VL_MES_COMPLE  NUMBER;
 VL_ERROR       VARCHAR2(500);
 VL_TRAN_NUM    NUMBER;
 VL_FECHA_FUTU  VARCHAR2(11);
 VL_DIA         NUMBER;
 VL_MES         VARCHAR2(3);
 VL_ANO         VARCHAR2(5);


 BEGIN
   BEGIN
     SELECT ZSTPARA_PARAM_VALOR
       INTO VL_MES_COMPLE
       FROM ZSTPARA
      --WHERE     ZSTPARA_MAPA_ID ='COMPL_INICIO'--CAMBIO DE REGLA GENERACION DE COMPLEMENTO NORMAL
      WHERE     ZSTPARA_MAPA_ID ='COMPL_MES'
            AND ZSTPARA_PARAM_ID = TO_NUMBER(TO_CHAR(P_FECHA,'MM'));
   EXCEPTION
   WHEN OTHERS THEN
   VL_ERROR:='BAILO EL GIBRI = '||SQLERRM;
   END;

   IF VL_ERROR IS NULL THEN

     VL_DIA:= TO_CHAR(P_FECHA,'DD');
     VL_MES:= LPAD(VL_MES_COMPLE,2,'0');
     VL_ANO:= TO_CHAR(P_FECHA,'YYYY');

     IF TO_NUMBER(TO_CHAR(P_FECHA,'MM')) BETWEEN 7 AND 12 THEN
      VL_ANO:= VL_ANO+1;
     END IF;

     BEGIN
        SELECT VL_DIA||'/'||VL_MES||'/'||VL_ANO
          INTO VL_FECHA_FUTU
          FROM DUAL;
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR AL CALCULAR FECHA = '||SQLERRM;
     END;

     IF VL_ERROR IS NULL THEN

       BEGIN
         SELECT NVL(MAX(TZFACCE_SEC_PIDM)+1,1)
           INTO VL_TRAN_NUM
           FROM TZFACCE
          WHERE TZFACCE_PIDM = P_PIDM;
       END;

       BEGIN
         INSERT
           INTO TZFACCE
         VALUES ( P_PIDM,
                  VL_TRAN_NUM,
                  P_PERIODO,
                  P_CODIGO,
                  P_DESCRI,
                  P_MONTO,
                  TO_DATE(VL_FECHA_FUTU,'DD/MM/YYYY'),
                  'REZA',
                  SYSDATE,
                  0,
                  P_SOL);
       EXCEPTION
       WHEN OTHERS THEN
       VL_ERROR:= 'ERROR INSERTAR TZFACCE'||SQLERRM;
       END;
     END IF;
   END IF;
  RETURN(VL_ERROR);
  COMMIT;
 END F_COMPLE_FILI;


 PROCEDURE P_TRASP_AGM IS

 /*SE GENERAN CARGOS DEACUERDO AL NUMERO DE MATERIAS CURSADAS CUANDO CAMBIA DE ESTATUS TR*/
VL_MATERIA      NUMBER;
VL_CARGOS       NUMBER;
VL_VIGENCIA     DATE;
VL_SECU         NUMBER;
VL_INSERT       VARCHAR2(900);
VL_ERROR        VARCHAR2(900);
VL_ERROR_REC    VARCHAR2(900);
VL_DOCTR        NUMBER;


 BEGIN
   FOR X IN (

    SELECT SORLCUR_CAMP_CODE CAMPUS,
           SORLCUR_LEVL_CODE NIVEL,
           SORLCUR_PROGRAM PROGRAMA,
           SORLCUR_RATE_CODE RATE,
           TBRACCD_PIDM PIDM,
           TBRACCD_DETAIL_CODE CODIGO,
           TBRACCD_DESC DESCRIPCION,
           TBRACCD_EFFECTIVE_DATE FECHA,
           TO_CHAR(TBRACCD_EFFECTIVE_DATE,'DD')VENCIMIENTO,
           TBRACCD_AMOUNT MONTO,
           TBRACCD_TERM_CODE PERIODO,
           TBRACCD_PERIOD PARTE,
           TBRACCD_FEED_DATE INICIO,
           TBRACCD_STSP_KEY_SEQUENCE STUDY
      FROM SORLCUR S,TBRACCD T
     WHERE     S.SORLCUR_PIDM = T.TBRACCD_PIDM
           AND S.SORLCUR_KEY_SEQNO = T.TBRACCD_STSP_KEY_SEQUENCE
           AND T.TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
           AND T.TBRACCD_DOCUMENT_NUMBER IS NULL
           AND T.TBRACCD_EFFECTIVE_DATE = (SELECT MAX(DISTINCT TBRACCD_EFFECTIVE_DATE)
                                             FROM TBRACCD
                                             WHERE     TBRACCD_PIDM = T.TBRACCD_PIDM
                                                   AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                                   AND TBRACCD_STSP_KEY_SEQUENCE = T.TBRACCD_STSP_KEY_SEQUENCE
                                                   AND TBRACCD_DOCUMENT_NUMBER IS NULL )
           AND S.SORLCUR_PIDM = (SELECT A.SGBSTDN_PIDM
                                   FROM SGBSTDN A
                                  WHERE     A.SGBSTDN_PIDM = S.SORLCUR_PIDM
                                        AND A.SGBSTDN_STST_CODE = 'TR'
                                        AND A.SGBSTDN_TERM_CODE_EFF = (SELECT SGBSTDN_TERM_CODE_EFF
                                                                         FROM SGBSTDN
                                                                        WHERE SGBSTDN_PIDM = A.SGBSTDN_PIDM))
--           AND S.SORLCUR_PIDM = FGET_PIDM('300385808')
           AND S.SORLCUR_LMOD_CODE = 'LEARNER'
           AND S.SORLCUR_ROLL_IND  = 'Y'
           AND S.SORLCUR_CACT_CODE = 'ACTIVE'
           AND S.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                     FROM SORLCUR A1
                                    WHERE     A1.SORLCUR_PIDM = S.SORLCUR_PIDM
                                          AND A1.SORLCUR_ROLL_IND  = S.SORLCUR_ROLL_IND
                                          AND A1.SORLCUR_CACT_CODE = S.SORLCUR_CACT_CODE
                                          AND A1.SORLCUR_PROGRAM = S.SORLCUR_PROGRAM
                                          AND A1.SORLCUR_LMOD_CODE = S.SORLCUR_LMOD_CODE)
           AND S.SORLCUR_PIDM IN (SELECT GORADID_PIDM
                                    FROM GORADID
                                    WHERE GORADID_PIDM = S.SORLCUR_PIDM
                                    AND GORADID_ADID_CODE = 'UAGM')
           AND S.SORLCUR_PIDM NOT IN (SELECT TZDOCTR_PIDM
                                        FROM TZDOCTR
                                       WHERE     TBRACCD_PIDM = S.SORLCUR_PIDM
                                             AND TBRACCD_STSP_KEY_SEQUENCE = S.SORLCUR_KEY_SEQNO
                                             AND TBRACCD_FEED_DOC_CODE = 'TRASPASO')

   )LOOP

    VL_VIGENCIA:=NULL;

     BEGIN
       SELECT COUNT (*)
         INTO VL_MATERIA
         FROM SFRSTCR
        WHERE     SFRSTCR_RSTS_CODE = 'RE'
              AND SUBSTR (SFRSTCR_TERM_CODE,5,1) NOT IN (8,9)
              AND SFRSTCR_STSP_KEY_SEQUENCE = X.STUDY
              AND SFRSTCR_PIDM = X.PIDM;
     EXCEPTION
     WHEN OTHERS THEN
     VL_MATERIA := 0;
     END;

     IF VL_MATERIA = 6 THEN
       VL_CARGOS:= 8;
     ELSIF VL_MATERIA = 7 THEN
       VL_CARGOS:= 6;
     ELSE
       VL_CARGOS:=0;
       VL_ERROR_REC:='CUENTA CON MUMERO DE MATERIAS NO DEFINIDO';
     END IF;

     IF VL_CARGOS != 0 THEN

       VL_VIGENCIA:=X.FECHA;

       IF TO_CHAR(VL_VIGENCIA,'DD') >= 27 THEN
         VL_VIGENCIA:=
                       CASE
                         WHEN TO_CHAR(LAST_DAY(VL_VIGENCIA),'DD') = 31 THEN
                              LAST_DAY(VL_VIGENCIA)-1
                       ELSE LAST_DAY(VL_VIGENCIA)
                       END;
       END IF;

       BEGIN
         FOR I IN 1..VL_CARGOS LOOP
           VL_ERROR:=NULL;
           VL_VIGENCIA:= ADD_MONTHS(VL_VIGENCIA,1);

           VL_VIGENCIA:=
                         CASE
                           WHEN TO_CHAR(LAST_DAY(VL_VIGENCIA),'DD') = 31 THEN
                                LAST_DAY(VL_VIGENCIA)-1
                         ELSE LAST_DAY(VL_VIGENCIA)
                         END;

           BEGIN
             SELECT MAX(TBRACCD_TRAN_NUMBER)+1
               INTO VL_SECU
               FROM TBRACCD
              WHERE TBRACCD_PIDM = X.PIDM;
           END;

           VL_INSERT:= PKG_FINANZAS.F_INSERTA_TBRACCD ( X.PIDM,
                                                        VL_SECU,
                                                        NULL,
                                                        X.PERIODO,
                                                        X.PARTE,
                                                        X.CODIGO,
                                                        X.MONTO,
                                                        X.MONTO,
                                                        TO_DATE(VL_VIGENCIA,'DD/MM/YYYY'),
                                                        X.DESCRIPCION,
                                                        X.STUDY,
                                                        'TZFEDCA (PARC)',
                                                        X.INICIO );
           VL_ERROR:= VL_INSERT;

           VL_ERROR_REC:=VL_ERROR_REC||VL_ERROR;

           BEGIN
             UPDATE TBRACCD
                SET TBRACCD_FEED_DOC_CODE = 'TRASPASO'
              WHERE     TBRACCD_PIDM = X.PIDM
                    AND TBRACCD_TRAN_NUMBER = VL_SECU;
           END;

         END LOOP;

         BEGIN
           DELETE TZDOCTR
            WHERE     TZDOCTR_PIDM = X.PIDM
                  AND TZDOCTR_TIPO_PROC = 'AGME'
                  AND TZDOCTR_START_DATE = X.INICIO;
         END;

       END;

     END IF;

     IF VL_ERROR_REC IS NULL THEN
       COMMIT;
     ELSE
       ROLLBACK;
     END IF;

     IF VL_ERROR_REC IS NOT NULL THEN

       BEGIN
         SELECT COUNT(*)
           INTO VL_DOCTR
           FROM TZDOCTR
          WHERE     TZDOCTR_PIDM = X.PIDM
                AND TZDOCTR_TIPO_PROC = 'AGME'
                AND TZDOCTR_START_DATE = X.INICIO;
       EXCEPTION
       WHEN OTHERS THEN
       VL_DOCTR:=0;
       END;

       IF VL_DOCTR = 0 THEN

         BEGIN
           INSERT
             INTO TZDOCTR (TZDOCTR_PIDM,
                           TZDOCTR_PROGRAM,
                           TZDOCTR_STST_CODE,
                           TZDOCTR_STYP_CODE,
                           TZDOCTR_CAMP_CODE,
                           TZDOCTR_LEVL_CODE,
                           TZDOCTR_TERM_CODE,
                           TZDOCTR_START_DATE,
                           TZDOCTR_PTRM_CODE,
                           TZDOCTR_STUDY_PATH,
                           TZDOCTR_NUM_PAGOS,
                           TZDOCTR_RATE_CODE,
                           TZDOCTR_COLEG,
                           TZDOCTR_DESC,
                           TZDOCTR_PPAGO,
                           TZDOCTR_PARCI,
                           FECHA_PROCESO,
                           TZDOCTR_IND,
                           TZDOCTR_OBSERVACIONES,
                           TZDOCTR_VENCIMIENTO,
                           TZDOCTR_ID,
                           TZDOCTR_TIPO_PROC,
                           TZDOCTR_DESCUENTO)
             VALUES (X.PIDM,
                     X.PROGRAMA,
                     'TR',
                     'C',
                     X.CAMPUS,
                     X.NIVEL,
                     X.PERIODO,
                     X.INICIO,
                     X.PARTE,
                     X.STUDY,
                     VL_CARGOS,
                     X.RATE,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     SYSDATE,
                     0,
                     VL_ERROR_REC,
                     X.VENCIMIENTO,
                     GB_COMMON.F_GET_ID (X.PIDM),
                     'AGME',
                     1);
         EXCEPTION
         WHEN OTHERS THEN
         VL_ERROR:= 'Error al insertar en TZDOCTR'||SQLERRM;
         END;

       ELSE

         UPDATE TZDOCTR
            SET TZDOCTR_OBSERVACIONES = VL_ERROR_REC,
                FECHA_PROCESO = SYSDATE
          WHERE     TZDOCTR_PIDM = X.PIDM
                AND TZDOCTR_TIPO_PROC = 'AGME'
                AND TZDOCTR_START_DATE = X.INICIO;

       END IF;

     END IF;
     COMMIT;
   END LOOP;

 EXCEPTION
 WHEN OTHERS THEN
 --DBMS_OUTPUT.PUT_LINE('ERROR GENERAL = '||SQLERRM);
 null;
 END P_TRASP_AGM;

FUNCTION F_ALTA_BAJA_MAT (P_CAMPUS       VARCHAR2,
                          P_NIVEL        VARCHAR2,
                          P_PIDM         NUMBER,
                          P_FECHA_INI    DATE,
                          P_STUDY        NUMBER,
                          P_JOR_NEW      VARCHAR2,
                          P_JOR_OLD      VARCHAR2,
                          P_ACCION       VARCHAR2)RETURN VARCHAR2 IS

VL_ERROR            VARCHAR2(900);
VL_BITA             NUMBER;
VL_SEC              NUMBER;
VL_MONTO            NUMBER;
VL_ENTRA            NUMBER;
VL_FECHA_VIG        DATE;
VL_PAID             NUMBER;
VL_TRAN_SEC         NUMBER;
VL_MONTO_APLICABLE  NUMBER;
VL_MONTO_ANTE       NUMBER;
VL_CODIGO           VARCHAR2(5);
VL_DESCR            VARCHAR2(50);
VL_BECA             NUMBER;
VL_ESCALONADO       NUMBER;
VL_MATERIAS         NUMBER;
VL_PERIODO          VARCHAR2(11);
VL_PARTE            VARCHAR2(11);
VL_ACCION           VARCHAR2(20);
VL_EXIS             NUMBER;
VL_SUM_AJUSTE       NUMBER;
VL_BANDERA          NUMBER:=0;
VL_MAT_ANTE         NUMBER;

 BEGIN

   BEGIN
     SELECT COUNT(*)
       INTO VL_ENTRA
       FROM ZSTPARA
      WHERE     ZSTPARA_MAPA_ID = 'ALBA_MA'
            AND SUBSTR(ZSTPARA_PARAM_ID,1,5) = P_CAMPUS||P_NIVEL;
   END;

   BEGIN
     SELECT COUNT(*)
       INTO VL_ESCALONADO
       FROM TBRACCD
       WHERE TBRACCD_PIDM = P_PIDM
       AND TBRACCD_FEED_DATE = P_FECHA_INI
       AND TBRACCD_DETAIL_CODE LIKE '%M3';
   END;

   BEGIN
     SELECT DISTINCT TBRACCD_TERM_CODE,TBRACCD_PERIOD
       INTO VL_PERIODO,VL_PARTE
       FROM TBRACCD
      WHERE     TBRACCD_PIDM = P_PIDM
            AND TBRACCD_FEED_DATE = P_FECHA_INI
            AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY
            AND TBRACCD_DOCUMENT_NUMBER IS NULL
            AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)';
   END;

   BEGIN
     SELECT DISTINCT TBREDET_PERCENT
       INTO VL_BECA
       FROM TBBEXPT, TBBESTU A, TBBDETC, TBREDET
      WHERE     TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
            AND TBBDETC_TAXT_CODE = P_NIVEL
            AND A.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
            AND A.TBBESTU_TERM_CODE         = TBBEXPT_TERM_CODE
            AND A.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
            AND A.TBBESTU_DEL_IND IS NULL
            AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
            AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
            AND A.TBBESTU_TERM_CODE = (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                         FROM TBBESTU A1,TBBEXPT,TBREDET,TBBDETC
                                        WHERE     A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                              AND TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                              AND TBBDETC_TAXT_CODE = P_NIVEL
                                              AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                              AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                              AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                              AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                              AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                              AND A1.TBBESTU_DEL_IND IS NULL
                                              AND A1.TBBESTU_TERM_CODE <= VL_PERIODO)
            AND A.TBBESTU_EXEMPTION_PRIORITY = (SELECT MAX(B1.TBBESTU_EXEMPTION_PRIORITY)
                                                  FROM TBBESTU B1,TBBEXPT,TBREDET,TBBDETC
                                                 WHERE     B1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                       AND TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                                       AND TBBDETC_TAXT_CODE = P_NIVEL
                                                       AND B1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                       AND B1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                       AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                       AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                       AND B1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                       AND B1.TBBESTU_DEL_IND IS NULL
                                                       AND B1.TBBESTU_TERM_CODE = (SELECT MAX(B2.TBBESTU_TERM_CODE)
                                                                                     FROM TBBESTU B2,TBBEXPT,TBREDET,TBBDETC
                                                                                    WHERE     B2.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                                                          AND TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                                                                          AND TBBDETC_TAXT_CODE = P_NIVEL
                                                                                          AND B2.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                                                          AND B2.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                                                          AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
                                                                                          AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE
                                                                                          AND B2.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                                                          AND B2.TBBESTU_DEL_IND IS NULL
                                                                                          AND B2.TBBESTU_TERM_CODE <= VL_PERIODO))
            AND TBBESTU_PIDM = P_PIDM
            AND TBBDETC_DCAT_CODE = 'DSP';
   EXCEPTION
   WHEN OTHERS THEN
   VL_BECA:=0;
   END;

   VL_MATERIAS:= SUBSTR(P_JOR_OLD,4,1) - SUBSTR(P_JOR_NEW,4,1);

   IF VL_MATERIAS < 0 THEN
     VL_ACCION := 'ALTA';
   ELSE
     VL_ACCION := 'BAJA';
   END IF;

  -- DBMS_OUTPUT.PUT_LINE('PROCESO REZA ENTRA = '||VL_ENTRA||' = '||VL_ESCALONADO||' = '||VL_BECA);

   IF VL_ENTRA > 0 AND VL_ESCALONADO = 0 AND VL_BECA <= 70 THEN

    /* SOLO SE REALIZA AJUSTE SI SE ENCUENTRA EN EL PARAMETRIZADOR*/

     IF VL_ACCION = 'BAJA' THEN

       --DBMS_OUTPUT.PUT_LINE('PROCESO REZA 1 = '||VL_MATERIAS);

       BEGIN
         SELECT ZSTPARA_PARAM_VALOR
           INTO VL_MONTO
           FROM ZSTPARA
          WHERE     ZSTPARA_MAPA_ID = 'ALBA_MA'
                AND ZSTPARA_PARAM_ID = P_CAMPUS||P_NIVEL||'_'||VL_MATERIAS;
       EXCEPTION
       WHEN OTHERS THEN
       VL_ERROR:='No existe configuración para dar de baja '||VL_MATERIAS||' materias, validar con finanzas.';
       END;

       VL_MONTO_APLICABLE:= VL_MONTO;

       BEGIN
         SELECT COUNT(*)
           INTO VL_BITA
           FROM TZTALBA
          WHERE     TZTALBA_PIDM = P_PIDM
                AND TZTALBA_IND_CANCE = 0
                AND TZTALBA_START_DATE = P_FECHA_INI
                AND (SELECT SUM(TZTALBA_AMOUNT)
                       FROM TZTALBA
                      WHERE     TZTALBA_PIDM = P_PIDM
                            AND TZTALBA_IND_CANCE = 0
                            AND TZTALBA_START_DATE = P_FECHA_INI) < ( SELECT MAX(ZSTPARA_PARAM_VALOR)
                                                                        FROM ZSTPARA
                                                                       WHERE     ZSTPARA_MAPA_ID = 'ALBA_MA'
                                                                             AND SUBSTR(ZSTPARA_PARAM_ID,1,5) = P_CAMPUS||P_NIVEL);
       END;

       BEGIN
         SELECT COUNT(*)
           INTO VL_EXIS
           FROM TZTALBA
          WHERE     TZTALBA_PIDM = P_PIDM
                AND TZTALBA_IND_CANCE = 0
                AND TZTALBA_START_DATE = P_FECHA_INI;
       END;

       IF VL_BITA = 0 AND VL_EXIS > 0 THEN
         VL_ERROR:='No se puede dar de baja mas de 2 materias';
       ELSE

         BEGIN
           SELECT NVL(SUBSTR(TZTALBA_OBSERVACIONES,4,1),SUBSTR(P_JOR_OLD,4,1)) - SUBSTR(P_JOR_NEW,4,1)
             INTO VL_MATERIAS
             FROM TZTALBA A
            WHERE     A.TZTALBA_PIDM = P_PIDM
                  AND A.TZTALBA_IND_CANCE = 0
                  AND A.TZTALBA_SEQNO = (SELECT MAX(TZTALBA_SEQNO)
                                           FROM TZTALBA
                                          WHERE     TZTALBA_PIDM = P_PIDM
                                                AND TZTALBA_IND_CANCE = 0);
         EXCEPTION
         WHEN OTHERS THEN
         VL_MATERIAS :=SUBSTR(P_JOR_OLD,4,1) - SUBSTR(P_JOR_NEW,4,1);
        -- DBMS_OUTPUT.PUT_LINE('PROCESO REZA 2 = '||VL_MATERIAS);
         END;

         BEGIN
           SELECT ZSTPARA_PARAM_VALOR
             INTO VL_MONTO
             FROM ZSTPARA
            WHERE     ZSTPARA_MAPA_ID = 'ALBA_MA'
                  AND ZSTPARA_PARAM_ID = P_CAMPUS||P_NIVEL||'_'||VL_MATERIAS;
         EXCEPTION
         WHEN OTHERS THEN
         VL_ERROR:='No existe configuración para dar de baja '||VL_MATERIAS||' materias, validar con finanzas.';
         END;

         --DBMS_OUTPUT.PUT_LINE('PROCESO REZA 3 = '||VL_MATERIAS);

         BEGIN
           SELECT TZTALBA_AMOUNT
             INTO VL_MONTO_ANTE
             FROM TZTALBA
            WHERE     TZTALBA_PIDM = P_PIDM
                  AND TZTALBA_IND_CANCE = 0
                  AND TZTALBA_SEQNO = (SELECT MAX(TZTALBA_SEQNO)
                                         FROM TZTALBA
                                        WHERE TZTALBA_PIDM = P_PIDM);

           VL_MONTO_APLICABLE:= VL_MONTO-VL_MONTO_ANTE;

         EXCEPTION
         WHEN OTHERS THEN
         VL_MONTO_APLICABLE:= VL_MONTO;
         END;

       END IF;

       IF VL_ERROR IS NULL THEN

         BEGIN
           SELECT NVL(MAX(TZTALBA_SEQNO)+1,1)
             INTO VL_SEC
             FROM TZTALBA
            WHERE TZTALBA_PIDM = P_PIDM;
         END;

         BEGIN
           INSERT
             INTO TZTALBA
                  (TZTALBA_PIDM,
                   TZTALBA_SEQNO,
                   TZTALBA_TERM_CODE,
                   TZTALBA_PTRM_CODE,
                   TZTALBA_START_DATE,
                   TZTALBA_STUDY_PATH,
                   TZTALBA_AMOUNT,
                   TZTALBA_IND_CANCE,
                   TZTALBA_ACTIVITY_DATE,
                   TZTALBA_UPDATE_DATE,
                   TZTALBA_USER,
                   TZTALBA_USER_UPDATE,
                   TZTALBA_DATA_ORIGIN,
                   TZTALBA_OBSERVACIONES)
           VALUES (P_PIDM,
                   VL_SEC,
                   VL_PERIODO,
                   VL_PARTE,
                   P_FECHA_INI,
                   P_STUDY,
                   VL_MONTO_APLICABLE,
                   0,
                   SYSDATE,
                   SYSDATE,
                   USER,
                   USER,
                   'F_ALTA_BAJA_MAT',
                   P_JOR_OLD);
         EXCEPTION
         WHEN OTHERS THEN
         VL_ERROR:='ERROR AL INSERTAR EN TABLA TZTALBA = '||SQLERRM;
         END;

       --DBMS_OUTPUT.PUT_LINE('REZA = '||VL_PERIODO||' = '||VL_PARTE||' = '||P_STUDY);

         BEGIN
           FOR BAJA IN (
                         SELECT *
                           FROM TBRACCD
                          WHERE     TBRACCD_PIDM = P_PIDM
                                AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                AND TBRACCD_TERM_CODE = VL_PERIODO
                                AND TBRACCD_PERIOD = VL_PARTE
                                AND TBRACCD_STSP_KEY_SEQUENCE = P_STUDY
           )LOOP

             IF BAJA.TBRACCD_BALANCE >= VL_MONTO_APLICABLE THEN
               VL_PAID:= BAJA.TBRACCD_TRAN_NUMBER;
             END IF;

             IF BAJA.TBRACCD_EFFECTIVE_DATE <= SYSDATE THEN
               VL_FECHA_VIG:= TRUNC(SYSDATE);
             ELSE
               VL_FECHA_VIG:= BAJA.TBRACCD_EFFECTIVE_DATE;
             END IF;

             BEGIN
               SELECT NVL(MAX(TBRACCD_TRAN_NUMBER)+1,1)
                 INTO VL_TRAN_SEC
                 FROM TBRACCD
               WHERE TBRACCD_PIDM = P_PIDM;
             END;

             BEGIN
               SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC
                 INTO VL_CODIGO,VL_DESCR
                 FROM TBBDETC
                WHERE TBBDETC_DETAIL_CODE = SUBSTR(BAJA.TBRACCD_DETAIL_CODE,1,2)||'Y2';
             END;

             BEGIN
               INSERT
                 INTO TBRACCD
                      ( TBRACCD_PIDM
                      , TBRACCD_TRAN_NUMBER
                      , TBRACCD_TRAN_NUMBER_PAID
                      , TBRACCD_TERM_CODE
                      , TBRACCD_DETAIL_CODE
                      , TBRACCD_USER
                      , TBRACCD_ENTRY_DATE
                      , TBRACCD_AMOUNT
                      , TBRACCD_BALANCE
                      , TBRACCD_EFFECTIVE_DATE
                      , TBRACCD_FEED_DATE
                      , TBRACCD_DESC
                      , TBRACCD_SRCE_CODE
                      , TBRACCD_ACCT_FEED_IND
                      , TBRACCD_ACTIVITY_DATE
                      , TBRACCD_SESSION_NUMBER
                      , TBRACCD_TRANS_DATE
                      , TBRACCD_CURR_CODE
                      , TBRACCD_DATA_ORIGIN
                      , TBRACCD_CREATE_SOURCE
                      , TBRACCD_STSP_KEY_SEQUENCE
                      , TBRACCD_PERIOD
                      , TBRACCD_USER_ID
                      , TBRACCD_RECEIPT_NUMBER)
               VALUES (
                        P_PIDM,
                        VL_TRAN_SEC,
                        VL_PAID,
                        BAJA.TBRACCD_TERM_CODE,
                        VL_CODIGO,
                        USER,
                        SYSDATE,
                        VL_MONTO_APLICABLE,
                        VL_MONTO_APLICABLE*-1,
                        SYSDATE,
                        BAJA.TBRACCD_FEED_DATE,
                        VL_DESCR,
                        'T',
                        'Y',
                        SYSDATE,
                        0,
                        SYSDATE,
                        'MXN',
                        'BAJA_MAT',
                        'BAJA_MAT',
                        P_STUDY,
                        VL_PARTE,
                        USER,
                        BAJA.TBRACCD_RECEIPT_NUMBER
                        );
             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR :='ERROR AL INSERTAR EN TBRACCD = '||SQLERRM;
             END;

             BEGIN
               UPDATE TZTALBA
                  SET TZTALBA_ORDER = BAJA.TBRACCD_RECEIPT_NUMBER
                WHERE     TZTALBA_PIDM = P_PIDM
                      AND TZTALBA_SEQNO = VL_SEC;

             END;
           END LOOP;
         END;

       END IF;

     ELSIF VL_ACCION = 'ALTA' THEN

       BEGIN
         SELECT TZTALBA_SEQNO
           INTO VL_BITA
           FROM TZTALBA
          WHERE     TZTALBA_PIDM = P_PIDM
                AND TZTALBA_IND_CANCE = 0
                AND TZTALBA_OBSERVACIONES = P_JOR_NEW;
       EXCEPTION
       WHEN OTHERS THEN

         VL_BANDERA:=1;

         BEGIN
           SELECT TZTALBA_SEQNO
             INTO VL_BITA
             FROM TZTALBA A
            WHERE     A.TZTALBA_PIDM = P_PIDM
                  AND A.TZTALBA_IND_CANCE = 0
                  AND A.TZTALBA_SEQNO = (SELECT MAX(TZTALBA_SEQNO)
                                           FROM TZTALBA
                                          WHERE     TZTALBA_PIDM = P_PIDM
                                                AND TZTALBA_IND_CANCE = 0 );
         EXCEPTION
         WHEN OTHERS THEN
         VL_BITA:=NULL;
         END;
       END;

       IF VL_BANDERA = 1 THEN

         BEGIN
           SELECT SUBSTR(TZTALBA_OBSERVACIONES,4,1)
             INTO VL_MAT_ANTE
             FROM TZTALBA A
            WHERE     A.TZTALBA_PIDM = P_PIDM
                  AND A.TZTALBA_SEQNO = VL_BITA;
         END;

         VL_MATERIAS:= VL_MAT_ANTE-SUBSTR(P_JOR_NEW,4,1);

         BEGIN
           SELECT ZSTPARA_PARAM_VALOR
             INTO VL_MONTO
             FROM ZSTPARA
            WHERE     ZSTPARA_MAPA_ID = 'ALBA_MA'
                  AND ZSTPARA_PARAM_ID = P_CAMPUS||P_NIVEL||'_'||VL_MATERIAS;
         EXCEPTION
         WHEN OTHERS THEN
         VL_MONTO:=0;
         END;



       END IF;

       IF VL_BITA IS NOT NULL THEN

         BEGIN
           FOR BAJA IN (
                         SELECT A.*,
                                CASE
                                  WHEN VL_MONTO > 0 THEN TBRACCD_AMOUNT - VL_MONTO
                                ELSE
                                  TBRACCD_AMOUNT - NVL((SELECT SUM(TBRACCD_AMOUNT)
                                                          FROM TBRACCD
                                                          WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                                                AND TBRACCD_TRAN_NUMBER_PAID = A.TBRACCD_TRAN_NUMBER
                                                                AND TBRACCD_CREATE_SOURCE = 'BAJA_MAT'),0)
                                END AJUSTE
                           FROM TBRACCD A
                          WHERE     A.TBRACCD_PIDM = P_PIDM
                                AND A.TBRACCD_CREATE_SOURCE = 'BAJA_MAT'
                                AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                                AND A.TBRACCD_TERM_CODE = VL_PERIODO
                                AND A.TBRACCD_PERIOD = VL_PARTE
                                AND SUBSTR(A.TBRACCD_DETAIL_CODE,3,2) = 'Y2'
                                AND A.TBRACCD_STSP_KEY_SEQUENCE = P_STUDY
                                AND A.TBRACCD_AMOUNT IN (SELECT TZTALBA_AMOUNT
                                                           FROM TZTALBA
                                                          WHERE     TZTALBA_PIDM = P_PIDM
                                                                AND TZTALBA_IND_CANCE = 0
                                                                AND TZTALBA_SEQNO >= VL_BITA)
           )LOOP

             PKG_FINANZAS.P_DESAPLICA_PAGOS(BAJA.TBRACCD_PIDM,BAJA.TBRACCD_TRAN_NUMBER);

             BEGIN
               SELECT NVL(MAX(TBRACCD_TRAN_NUMBER)+1,1)
                 INTO VL_TRAN_SEC
                 FROM TBRACCD
                WHERE TBRACCD_PIDM = P_PIDM;
             END;

             BEGIN
               SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC
                 INTO VL_CODIGO,VL_DESCR
                 FROM TBBDETC
                WHERE TBBDETC_DETAIL_CODE = SUBSTR(BAJA.TBRACCD_DETAIL_CODE,1,2)||'82';
             END;

             BEGIN
               INSERT
                 INTO TBRACCD
                      ( TBRACCD_PIDM
                      , TBRACCD_TRAN_NUMBER
                      , TBRACCD_TRAN_NUMBER_PAID
                      , TBRACCD_TERM_CODE
                      , TBRACCD_DETAIL_CODE
                      , TBRACCD_USER
                      , TBRACCD_ENTRY_DATE
                      , TBRACCD_AMOUNT
                      , TBRACCD_BALANCE
                      , TBRACCD_EFFECTIVE_DATE
                      , TBRACCD_FEED_DATE
                      , TBRACCD_DESC
                      , TBRACCD_SRCE_CODE
                      , TBRACCD_ACCT_FEED_IND
                      , TBRACCD_ACTIVITY_DATE
                      , TBRACCD_SESSION_NUMBER
                      , TBRACCD_TRANS_DATE
                      , TBRACCD_CURR_CODE
                      , TBRACCD_DATA_ORIGIN
                      , TBRACCD_CREATE_SOURCE
                      , TBRACCD_STSP_KEY_SEQUENCE
                      , TBRACCD_PERIOD
                      , TBRACCD_USER_ID
                      , TBRACCD_RECEIPT_NUMBER)
               VALUES (
                        P_PIDM,
                        VL_TRAN_SEC,
                        BAJA.TBRACCD_TRAN_NUMBER,
                        BAJA.TBRACCD_TERM_CODE,
                        VL_CODIGO,
                        USER,
                        SYSDATE,
                        BAJA.AJUSTE,
                        BAJA.AJUSTE,
                        SYSDATE,
                        BAJA.TBRACCD_FEED_DATE,
                        VL_DESCR,
                        'T',
                        'Y',
                        SYSDATE,
                        0,
                        SYSDATE,
                        'MXN',
                        'BAJA_MAT',
                        'BAJA_MAT',
                        P_STUDY,
                        VL_PARTE,
                        USER,
                        BAJA.TBRACCD_RECEIPT_NUMBER
                        );
             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR :='ERROR AL INSERTAR EN TBRACCD = '||SQLERRM;
             END;

             BEGIN
               SELECT SUM(TBRACCD_AMOUNT)
                 INTO VL_SUM_AJUSTE
                 FROM TBRACCD
                WHERE     TBRACCD_PIDM = BAJA.TBRACCD_PIDM
                      AND TBRACCD_TRAN_NUMBER_PAID = BAJA.TBRACCD_TRAN_NUMBER
                      AND TBRACCD_CREATE_SOURCE = 'BAJA_MAT';
             EXCEPTION
             WHEN OTHERS THEN
             VL_SUM_AJUSTE:=BAJA.AJUSTE;
             END;

             IF BAJA.TBRACCD_AMOUNT = VL_SUM_AJUSTE THEN

               BEGIN
                 UPDATE TBRACCD
                    SET TBRACCD_DOCUMENT_NUMBER = 'CANCE',
                        TBRACCD_TRAN_NUMBER_PAID = NULL
                  WHERE TBRACCD_PIDM = BAJA.TBRACCD_PIDM
                  AND TBRACCD_TRAN_NUMBER = BAJA.TBRACCD_TRAN_NUMBER;
               END;

               BEGIN
                 UPDATE TZTALBA
                    SET TZTALBA_IND_CANCE = 1,
                        TZTALBA_UPDATE_DATE = SYSDATE,
                        TZTALBA_USER_UPDATE = USER
                  WHERE     TZTALBA_PIDM = P_PIDM
                        AND TZTALBA_SEQNO >= VL_BITA;

               END;
             END IF;
           END LOOP;
         END;

       END IF;

     ELSE
       VL_ERROR:='ACCION INCORRECTA';
     END IF;

   END IF;

   IF VL_ERROR IS NULL THEN
     COMMIT;
   ELSE
     ROLLBACK;
   END IF;

   RETURN(VL_ERROR);
 END F_ALTA_BAJA_MAT;

-- 03/Agosto/2023 ----------------------------------------------
-- Funciones para el proceso de COMPLEMENTO DE COLEGIATURAS ----

FUNCTION F_COMPLE_ACCION_IMPLEMENTAR (p_pidm            IN NUMBER,      -- Identificador del Registro
                                      p_codigo          IN VARCHAR2,    -- Código del complemento de colegiatura 
                                      p_Campus          IN VARCHAR2,    -- Campus: UTL
                                      p_Nivel           IN VARCHAR2,    -- Nivel.: LI
                                      p_Vigencia        IN NUMBER,      -- Número de Meses de Vigencia
                                      p_fecha_proceso   IN DATE,        -- Fecha en que se ejecuta el proceso (1=Enero, 2=Febrero, Etc...)
                                      p_Effective_Date OUT DATE,        -- Fecha para que se aplique el complemento de colegiatura
                                      p_dia_corte       IN VARCHAR2,    -- Dia de corte del estado de cuenta (RATE)
                                      p_study_path      IN NUMBER       -- Study Path del Alumno
) RETURN VARCHAR2 IS

-- DESCRIPCION: Obtiene la fecha para aplicar el complemento de colegiatura y la accion a realizar (INSERT, UPDATE, NINGUNA)
-- VERSION....: 1.0.0   10/Julio/2023      Omar Meza    Inicio

   -- Variables
   Vm_Accion VARCHAR2 (10) := 'INSERTAR';                 -- Insertar, Update, Ninguna
   Vm_Codigo          tbraccd.tbraccd_detail_code%TYPE    := NULL;
   Vm_Monto           tbraccd.tbraccd_amount%TYPE         := NULL;
   Vm_Descripcion     tbraccd.tbraccd_Desc%TYPE           := NULL;
   Vm_Nueva_Creacion  VARCHAR2 (2)                        := 'NO';        -- Registro de nueva creación en TBRACCD
   Vm_Effective_Date  tbraccd.tbraccd_effective_date%TYPE := NULL;
   Vm_Mes_Proceso     NUMBER  (2) := TO_CHAR (p_Fecha_Proceso, 'MM');      -- Mes en que se ejecuta el proceso
   Vm_anio_proceso    NUMBER  (4) := TO_CHAR (p_Fecha_Proceso, 'YYYY');    -- Año en que se ejecuta el proceso
   Vm_mes_Temporal    VARCHAR (2) := NULL;                                 -- Mes para calculos temporales
   Vm_Anio_Temporal   VARCHAR (4) := NULL;                                 -- Año para calculos temporales
   

BEGIN
   -- Obtiene el máximo EFECCTIVE DATE
   BEGIN
   
      -- DBMS_OUTPUT.PUT_LINE ('------------------------------------------');
      -- DBMS_OUTPUT.PUT_LINE ('[ACCION] p_Study_Path = ' || p_Study_Path);
      -- DBMS_OUTPUT.PUT_LINE ('[ACCION] p_Pidm       = ' || p_Pidm);
      -- DBMS_OUTPUT.PUT_LINE ('[ACCION] p_Campus     = ' || p_Campus);
      -- DBMS_OUTPUT.PUT_LINE ('[ACCION] p_Nivel      = ' || p_Nivel);
      
      SELECT tbraccd_detail_code, tbraccd_amount, tbraccd_Desc, tbraccd_effective_date
        INTO Vm_Codigo, Vm_Monto, Vm_Descripcion, Vm_Effective_Date
        FROM tbraccd
       WHERE TBRACCD_STSP_KEY_SEQUENCE = p_Study_Path
         AND (tbraccd_PIDM, tbraccd_Tran_Number) IN (SELECT tbraccd_PIDM, MAX (tbraccd_Tran_Number) Tran_Number
                                                       FROM tbraccd f, tztinc b
                                                      WHERE tbraccd_PIDM = p_Pidm
                                                        AND TBRACCD_STSP_KEY_SEQUENCE = p_Study_Path
                                                        AND b.campus     = p_Campus
                                                        AND b.nivel      = p_Nivel
                                                        AND b.codigo = f.tbraccd_detail_code
                                                      GROUP BY tbraccd_PIDM
                                                    );


   -- Control de Errores
   EXCEPTION
      WHEN OTHERS THEN
      -- DBMS_OUTPUT.PUT_LINE (CHR(10));
      -- DBMS_OUTPUT.PUT_LINE ('En la Exception 01 de accion a implementar...');
      -- DBMS_OUTPUT.PUT_LINE ('Construye Fecha: ' || p_dia_corte ||  TO_CHAR (sysdate, '/MM/YYYY'));
      -- DBMS_OUTPUT.PUT_LINE (CHR(10));

      Vm_Nueva_Creacion := 'SI';                    -- Registro de nueva creación en TBRACCD
      Vm_Codigo         := NULL; Vm_Monto := NULL;  Vm_Descripcion := NULL; 
      Vm_Effective_Date := TO_DATE (p_dia_corte ||  TO_CHAR (sysdate, '/MM/YYYY'), 'DD/MM/YYYY');  -- Version Anterior
   END;

   -- Busca si se encuentra el registro en TBRACCD para el mes de proceso
   BEGIN

      -- DBMS_OUTPUT.PUT_LINE (CHR(10));
      -- DBMS_OUTPUT.PUT_LINE ('Antes del IF de accion a implementar...');
      -- DBMS_OUTPUT.PUT_LINE ('Vm_Effective_Date: ' || TO_CHAR (Vm_Effective_Date, 'YYYYMM'));
      -- DBMS_OUTPUT.PUT_LINE ('Vm_anio_proceso..: ' || Vm_anio_proceso);
      -- DBMS_OUTPUT.PUT_LINE ('Mes de Proceso...: ' || LPAD (Vm_mes_proceso,2,'0'));
      -- DBMS_OUTPUT.PUT_LINE (CHR(10));

      -- Valida la fecha para aplicar el complemeto
      Vm_Accion := 'NINGUNA';
      IF Vm_Nueva_Creacion = 'SI' OR TO_CHAR (Vm_Effective_Date, 'YYYYMM') = Vm_anio_proceso || LPAD (Vm_mes_proceso,2,'0') THEN
--    IF Vm_Effective_Date <= TO_DATE ('15/' || LPAD (Vm_mes_proceso,2,'0') || '/' || Vm_anio_proceso, 'DD/MM/YYYY') THEN -- Version Anterior
         -- DBMS_OUTPUT.PUT_LINE ('[001] Entra al IF... Accion a implementar');
         -- DBMS_OUTPUT.PUT_LINE ('Vm_Nueva_Creacion... ' || Vm_Nueva_Creacion);
         
         -- Calcula la fecha de aplicación EFECTIVE DATE
         Vm_Accion := 'INSERTAR'; 
         
         -- Valida que no rebase el mes 12=Diciembre
         IF Vm_Nueva_Creacion = 'NO' THEN
            IF TO_CHAR (Vm_Effective_Date, 'MM') + p_vigencia <= 12 THEN
          
               -- Dentro del mismo año
               Vm_mes_Temporal   := TO_CHAR (Vm_Effective_Date, 'MM') + p_vigencia; 
               Vm_Effective_Date := TO_DATE (p_dia_corte || '/' || LPAD (vm_mes_Temporal,2,'0') || 
                                                            '/'  || TO_CHAR (Vm_Effective_Date, 'YYYY'), 'DD/MM/YYYY');
            ELSE
               -- Cambia de año
               Vm_mes_Temporal   := TO_CHAR (Vm_Effective_Date, 'MM')   + p_vigencia - 12;
               Vm_Anio_Temporal  := TO_CHAR (Vm_Effective_Date, 'YYYY') + 1;
               Vm_Effective_Date := TO_DATE (p_dia_corte || '/' || LPAD (Vm_mes_Temporal, 2,'0')  || 
                                                            '/' || LPAD (Vm_Anio_Temporal,4,'0'), 'DD/MM/YYYY');
            END IF;
            
            -- Valida que no se pase de la fecha de proceso
            -- DBMS_OUTPUT.PUT_LINE ('Compara: ' || TO_CHAR (Vm_Effective_Date, 'YYYYMM') || ' <= ' || Vm_anio_proceso || LPAD (Vm_mes_proceso,2,'0'));
            IF TO_CHAR (Vm_Effective_Date, 'YYYYMM') <= Vm_anio_proceso || LPAD (Vm_mes_proceso,2,'0')
--          IF TO_CHAR (Vm_Effective_Date, 'YYYYMM')  = Vm_anio_proceso || LPAD (Vm_mes_proceso,2,'0')
               THEN NULL;                   -- DBMS_OUTPUT.PUT_LINE ('Then de compara: ');
               ELSE Vm_Accion := 'NINGUNA'; -- DBMS_OUTPUT.PUT_LINE ('Else de compara: ');
            END IF;
         END IF;
      END IF;

   EXCEPTION
      WHEN OTHERS 
           THEN Vm_Accion := 'NINGUNA';
                -- DBMS_OUTPUT.PUT_LINE ('Exception final de Accion_Implementar');
   END;


   -- Regresa la accion a implementar
   p_Effective_Date := Vm_Effective_Date;
   RETURN Vm_Accion;

-- Control de Errores
EXCEPTION
    WHEN OTHERS THEN RETURN 'NINGUNA';
END F_COMPLE_ACCION_IMPLEMENTAR;


FUNCTION F_COMPLE_OBTIENE_COLEGIATURA (P_CAMPUS           IN VARCHAR2,     -- Ejemplo: UTL
                                       P_NIVEL            IN VARCHAR2,     -- Ejemplo: LI
                                       P_PIDM             IN NUMBER,       -- Identificador del Alumno
                                       P_PERIODO          IN VARCHAR2,     -- Periodo en Cuestion
                                       P_CODIGO          OUT VARCHAR2,     -- Código del complemento de colegiatura
                                       P_DESCRIPCION     OUT VARCHAR2,     -- Descripción del concepto
                                       P_MONTO           OUT NUMBER,       -- Importe del complemento de colegiatura
                                       P_VIGENCIA        OUT NUMBER,       -- Numero de meses de vigencia
                                       P_FECHA_SOLICITUD OUT DATE,         -- Fecha de la tabla TZTINC (Registro de inicio del codigo)
                                       P_FECHA_INICIO    OUT DATE,         -- Fecha de Inicio del Alumno
                                       P_AUMENTO         OUT NUMBER,       -- Incremento en el costo del complemento
                                       P_CUANTAS_VECES   OUT NUMBER,       -- Cuantas veces consecutivas se debe aplicar el incremento
                                       P_MONEDA          OUT VARCHAR2,     -- Divisa (MXN, DLS, EUR, Etc...
                                       p_Status_Codigo   OUT VARCHAR2,     -- Se reutiliza el codigo existente (Se pueden aplicar recurrencias)
                                       p_fInicio          IN DATE,         -- Fecha de Inicio del Alumno, se toma del cursor
                                       p_Study_Path       IN NUMBER        -- Study Path del alumno
) RETURN VARCHAR2 IS

-- DESCRIPCION: Obtiene los valores a insertar del complemento de colegiatura
-- VERSION....: 1.0.0   07/Julio/2023      Omar Meza    Inicio

-- Variables
   Vm_Bandera         VARCHAR2 (500) := 'NORMAL';     -- Bandera de finalizacion del procedimiento
   Vm_Fecha_Solicitud DATE           := sysdate;      -- Fecha de Solicitud del Alumno
   Vm_Excluido        NUMBER         := 0;            -- Si es de españa; esta excluido del cobro de COMPLEMENTO
   Vm_IZZI            NUMBER         := 0;            -- Si es alumno tipo IZZI; esta excluido del cobro de COMPLEMENTO
   Vm_Porcentaje      NUMBER         := 0;            -- Porcentaje de Descuento; si es alumno tipo IZZI

   Vm_Codigo_TBRACCD  TBRACCD.TBRACCD_DETAIL_CODE%TYPE;  -- Codigo de detalle
   Vm_aMount_TBRACCD  TBRACCD.TBRACCD_AMOUNT%TYPE;       -- Importe aplicado en TBRACCD
   Vm_Cuantas_Veces_TztINC  NUMBER  (3) := 0;            -- Numero de veces que se debe aplicar la cuota (Configuración)
   Vm_Cuantas_Veces_TBRACCD NUMBER  (3) := 0;            -- Número de veces que ha sido aplocada la cuota en TBRACCD
   Vm_Tiene_Configuracion   VARCHAR (2) := 'SI';         -- Existe el importe de TBRACCD en la configuracion de TZTINC 

BEGIN
   -- Inicializa los valores de salida
   p_Codigo          := NULL; 
   p_Descripcion     := NULL;
   p_Monto           := NULL;
   p_Vigencia        := NULL;
   p_fecha_solicitud := NULL;
   p_fecha_inicio    := NULL;

   BEGIN
      -- Obtiene la fecha de solicitud del alumno
      SELECT TRUNC(SARADAP_APPL_DATE)
        INTO Vm_Fecha_Solicitud
        FROM SARADAP A
       WHERE A.SARADAP_PIDM = P_PIDM
         AND A.SARADAP_CAMP_CODE||A.SARADAP_LEVL_CODE = P_CAMPUS||P_NIVEL
         AND A.SARADAP_APST_CODE = 'A'
         AND A.SARADAP_APPL_NO = (SELECT MAX(SARADAP_APPL_NO)
                                    FROM SARADAP
                                   WHERE SARADAP_PIDM = A.SARADAP_PIDM
                                     AND SARADAP_CAMP_CODE||SARADAP_LEVL_CODE = P_CAMPUS||P_NIVEL
                                     AND SARADAP_APST_CODE = 'A'
                                 );

   -- Control de errores: En caso de que no encuentre el registro en SARADAP 
   EXCEPTION
     WHEN OTHERS
          THEN Vm_Fecha_Solicitud := TO_DATE('01/01/2011','DD/MM/YYYY');
   END;

   -- Se excluye por que es de ESPAÑA
   BEGIN
      SELECT COUNT(*)
        INTO Vm_Excluido
        FROM GORADID
       WHERE GORADID_PIDM      = P_PIDM
         AND GORADID_ADID_CODE = 'ESPA';

    EXCEPTION
       WHEN OTHERS THEN Vm_Excluido := 0;
    END;

    -- Si es de ESPAÑA; esta excluido del proceso termina la función
    IF Vm_Excluido > 0 THEN Vm_Bandera := 'EXCLUIDO'; RETURN Vm_Bandera;
    ELSE
       null;
    END IF;


    -- Busca si es alumno tipo IZZI
    BEGIN
       SELECT COUNT(*)
         INTO Vm_IZZI
         FROM GORADID
        WHERE GORADID_PIDM      = P_PIDM
          AND GORADID_ADID_CODE = 'IZZI';

    EXCEPTION
       WHEN OTHERS THEN Vm_IZZI := 0;
    END;


    -- Verifica el porcentaje de descuento por ser alumno tipo IZZI
    IF Vm_IZZI > 0 THEN
       BEGIN
          SELECT DISTINCT TBREDET_PERCENT
            INTO Vm_Porcentaje
            FROM TBBEXPT,TBBESTU A,TBBDETC,TBREDET
           WHERE TBBDETC_DETAIL_CODE      = TBBEXPT_DETAIL_CODE
             AND A.TBBESTU_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
             AND A.TBBESTU_TERM_CODE      = TBBEXPT_TERM_CODE
             AND A.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
             AND A.TBBESTU_DEL_IND IS NULL
             AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE
             AND TBREDET_TERM_CODE   = TBBEXPT_TERM_CODE
             AND A.TBBESTU_TERM_CODE = (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                          FROM TBBESTU A1,TBBEXPT,TBREDET,TBBDETC
                                         WHERE A1.TBBESTU_PIDM            = A.TBBESTU_PIDM
                                           AND TBBDETC_DETAIL_CODE        = TBBEXPT_DETAIL_CODE
                                           AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                           AND A1.TBBESTU_TERM_CODE       = TBBEXPT_TERM_CODE
                                           AND TBREDET_EXEMPTION_CODE     = TBBEXPT_EXEMPTION_CODE
                                           AND TBREDET_TERM_CODE          = TBBEXPT_TERM_CODE
                                           AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                           AND A1.TBBESTU_DEL_IND IS NULL
                                           AND A1.TBBESTU_TERM_CODE <= P_PERIODO
                                       )
             AND A.TBBESTU_EXEMPTION_PRIORITY = (SELECT MAX(B1.TBBESTU_EXEMPTION_PRIORITY)
                                                   FROM TBBESTU B1,TBBEXPT,TBREDET,TBBDETC
                                                  WHERE B1.TBBESTU_PIDM            = A.TBBESTU_PIDM
                                                    AND TBBDETC_DETAIL_CODE        = TBBEXPT_DETAIL_CODE
                                                    AND B1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE
                                                    AND B1.TBBESTU_TERM_CODE       = TBBEXPT_TERM_CODE
                                                    AND TBREDET_EXEMPTION_CODE     = TBBEXPT_EXEMPTION_CODE
                                                    AND TBREDET_TERM_CODE          = TBBEXPT_TERM_CODE
                                                    AND B1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                    AND B1.TBBESTU_DEL_IND IS NULL
                                                    AND B1.TBBESTU_TERM_CODE = A.TBBESTU_TERM_CODE
                                                )
             AND A.TBBESTU_PIDM = P_PIDM
             AND TBBDETC_DCAT_CODE = 'DSP';

       EXCEPTION
       WHEN OTHERS 
            THEN Vm_Porcentaje := 0;
       END;

       -- Si es el 100 de descuento si se excluye del proceso
       IF Vm_Porcentaje <= 90 
          THEN null;
          ELSE Vm_Bandera := 'EXCLUIDO';
               RETURN Vm_Bandera;
          END  IF;

    END IF;


    -- Veririca que siga el proceso normal
    IF Vm_Bandera = 'NORMAL' THEN
       BEGIN

         -- Obtiene la ultima cantidad pagada en TBRACCD
         BEGIN
            p_Status_Codigo := 'REUTILIZAR';                -- Se reutiliza el codigo existente (todavia se pueden aplicar recurrencias
            -- DBMS_OUTPUT.PUT_LINE ('p_Status_Codigo (Antes del Query): ' || p_Status_Codigo);

            -- Nueva Version 28/Julio
            SELECT tbraccd_detail_code, tbraccd_amount,    tbraccd_Desc,  Count(*) Veces_Aplicado
              INTO Vm_Codigo_TBRACCD,   Vm_aMount_TBRACCD, p_Descripcion, Vm_Cuantas_Veces_TBRACCD
              FROM TBRACCD f
             WHERE tbraccd_pidm = p_pidm
               AND TBRACCD_STSP_KEY_SEQUENCE = p_Study_Path
               AND (tbraccd_detail_code, tbraccd_amount) IN 
                                    (SELECT tbraccd_detail_code, tbraccd_amount
                                       FROM tbraccd
                                      WHERE TBRACCD_STSP_KEY_SEQUENCE = p_Study_Path
                                        AND (tbraccd_PIDM, tbraccd_Tran_Number) IN (SELECT tbraccd_PIDM, MAX (tbraccd_Tran_Number) Tran_Number
                                                                                      FROM tbraccd f, tztinc b
                                                                                     WHERE tbraccd_PIDM = p_pidm
                                                                                       AND TBRACCD_STSP_KEY_SEQUENCE = p_Study_Path
                                                                                       AND b.campus     = p_campus
                                                                                       AND b.nivel      = p_nivel
                                                                                       AND b.codigo     = f.tbraccd_detail_code
                                                                                     GROUP BY tbraccd_PIDM
                                                                                   )
                                    )
             GROUP BY tbraccd_detail_code, tbraccd_amount,tbraccd_Desc;

            /*
            DBMS_OUTPUT.PUT_LINE ('Valores de REUTILIZACION..');
            DBMS_OUTPUT.PUT_LINE (   'Vm_Codigo_TBRACCD = '        || Vm_Codigo_TBRACCD || ' / Vm_aMount_TBRACCD = ' || Vm_aMount_TBRACCD || 
                                  ' / Vm_aMount_TBRACCD = '        || Vm_aMount_TBRACCD || ' / p_Descripcion = '     || p_Descripcion     ||
                                  ' / Vm_Cuantas_Veces_TBRACCD = ' || Vm_Cuantas_Veces_TBRACCD);
            */

            -- Busca en la tabla de configuración las veces que se tiene aplica el CODIGO-IMPORTE
            BEGIN
               SELECT NVL (d.notas_max,0) - NVL (d.notas_min,0) +1 Veces_tztINC
                 INTO Vm_Cuantas_Veces_TztINC
                 FROM tztinc d
                WHERE d.campus = p_campus
                  AND d.nivel  = p_nivel
                  AND d.codigo = Vm_Codigo_TBRACCD
                  AND NVL (d.costo,0) + NVL (d.aumento,0) = Vm_aMount_TBRACCD
                  AND d.fecha_solicitud = (SELECT MAX (c.fecha_solicitud)
                                             FROM tztinc c
                                            WHERE c.campus = p_campus
                                              AND c.nivel  = p_nivel
                                              AND c.codigo = Vm_Codigo_TBRACCD
                                              AND NVL (c.costo,0) + NVL (c.aumento,0) = Vm_aMount_TBRACCD
                                              AND c.fecha_solicitud <= p_fInicio
                                          );

               -- Si no encuentra el registro = CERO                           
               EXCEPTION
                  WHEN OTHERS THEN
                       -- Cuando no se encuentre en la tabla de configuración el IMPORTE de TBRACCD
                       IF NVL (Vm_aMount_TBRACCD, 0) > 0 THEN
                          BEGIN 
                             SELECT MAX (NVL (d.notas_max,0) - NVL (d.notas_min,0) +1) Veces_tztINC
                               INTO Vm_Cuantas_Veces_TztINC
                               FROM tztinc d
                              WHERE d.campus = p_campus
                                AND d.nivel  = p_nivel
                                AND d.codigo = Vm_Codigo_TBRACCD
                                AND NVL (d.notas_min,0) = 1
                                AND d.fecha_solicitud   = (SELECT MAX (c.fecha_solicitud)
                                                             FROM tztinc c
                                                            WHERE c.campus = p_campus
                                                              AND c.nivel  = p_nivel
                                                              AND c.codigo = Vm_Codigo_TBRACCD
                                                              AND c.fecha_solicitud <= p_fInicio
                                                          );
                                                          
                             Vm_Tiene_Configuracion := 'NO';         -- Existe el importe de TBRACCD en la configuracion de TZTINC 
                             -- DBMS_OUTPUT.PUT_LINE (CHR(10));
                             -- DBMS_OUTPUT.PUT_LINE ('Inconsistencia: Vm_Tiene_Configuracion = ' || Vm_Tiene_Configuracion);
                             
                             EXCEPTION WHEN OTHERS THEN Vm_Cuantas_Veces_TztINC := 0;
                          END;  
                         
                       ELSE Vm_Cuantas_Veces_TztINC := 0;
                       END IF;
            END;

            -- DBMS_OUTPUT.PUT_LINE ('Vm_Cuantas_Veces_TBRACCD: ' || Vm_Cuantas_Veces_TBRACCD);
            -- DBMS_OUTPUT.PUT_LINE ('Vm_Cuantas_Veces_TztINC.: ' || Vm_Cuantas_Veces_TztINC);
            IF Vm_Cuantas_Veces_TBRACCD >= Vm_Cuantas_Veces_TztINC THEN
               p_Status_Codigo := 'NUEVO';
               -- DBMS_OUTPUT.PUT_LINE ('p_Status_Codigo (Dentro del IF): ' || p_Status_Codigo);
            ELSE
                -- En caso de volver aplicar la misma cuota, asigna los valores anteriores
                BEGIN
                   p_codigo        := Vm_Codigo_TBRACCD;
                   p_Monto         := Vm_aMount_TBRACCD;
                   p_Aumento       := 0;               
                   p_Cuantas_Veces := Vm_Cuantas_Veces_TztINC;
                
                   -- Obtiene datos Generales de la cuota para re-aplicar
                   BEGIN
                      SELECT DISTINCT a.vigencia, a.fecha_solicitud, Vm_Fecha_Solicitud, NVL (c.TVRDCTX_CURR_CODE, 'XXX') Moneda
                        INTO p_Vigencia, p_fecha_solicitud, p_fecha_inicio,     p_Moneda
                        FROM TZTINC a, TBBDETC b, TVRDCTX c  
                       WHERE a.campus = p_campus
                         AND a.nivel  = p_nivel
                         AND a.codigo = p_codigo
                         AND c.TVRDCTX_DETC_CODE = p_codigo 
                         AND RowNum <= 1
                           ;
                   END;
                    
                EXCEPTION
                  WHEN OTHERS THEN 
                       Vm_Bandera := 'ERROR AL OBTENER EL MONTO EN "TZTINC [03]" --> ' || SUBSTR(SQLERRM, 1, 500);
                END;
            END IF;

         -- Control de Errores
         EXCEPTION
            WHEN OTHERS THEN p_Status_Codigo := 'NUEVO';
         END;

         -- Obtiene los valores del complemento de colegiatura
         IF p_Status_Codigo = 'NUEVO' THEN 
            -- Obtiene el ultimo código disponible
            IF Vm_Codigo_TBRACCD IS NULL THEN
               -- DBMS_OUTPUT.PUT_LINE ('******************* No tiene antecedentes de COLEGIATURA ****** ' || P_PIDM);
               -- DBMS_OUTPUT.PUT_LINE ('Parametro p_fInicio: ' || p_fInicio);
               -- DBMS_OUTPUT.PUT_LINE (CHR(10));
               Vm_aMount_TBRACCD        := 0;
               Vm_Cuantas_Veces_TBRACCD := 0;

               BEGIN
                  SELECT DISTINCT a.codigo
                    INTO Vm_Codigo_TBRACCD 
                    FROM tztINC a
                   WHERE a.campus = p_Campus
                     AND a.nivel  = p_nivel
                     AND a.fecha_solicitud = (SELECT MAX (b.fecha_solicitud) Fecha_Solicitud 
                                                FROM tztINC b 
                                               WHERE b.campus = p_Campus 
                                                 AND b.nivel  = p_nivel
                                                 AND b.fecha_solicitud <= p_fInicio
                                             )
                       ;

               EXCEPTION
                  WHEN OTHERS THEN NULL;
               END;
            END IF;
            
            -- Obtiene información de la configuración (TZTINC)
            -- DBMS_OUTPUT.PUT_LINE ('Antes del IF de si tiene configuración...');
            IF Vm_Tiene_Configuracion = 'SI' THEN
               BEGIN
                 SELECT a.codigo,  b.tbbdetc_Desc,  a.costo, a.vigencia, a.fecha_solicitud, Vm_Fecha_Solicitud, 
                        a.Aumento, NVL (a.notas_max,99) - NVL (a.notas_min,0)+1 Cuantas_Veces, NVL (c.TVRDCTX_CURR_CODE, 'XXX')
                   INTO p_codigo,   p_Descripcion,   p_Monto, p_Vigencia, p_fecha_solicitud, p_fecha_inicio,     
                        p_Aumento,  p_Cuantas_Veces, p_Moneda
                   FROM TZTINC a, TBBDETC b, TVRDCTX c  
                  WHERE a.campus = p_campus
                    AND a.nivel  = p_nivel
                    AND b.tbbdetc_detail_code = a.codigo 
                    AND c.TVRDCTX_DETC_CODE   = a.codigo 
                    AND (a.codigo, a.costo, a.notas_min) = (SELECT a2.codigo, a2.costo, a2.notas_min
                                                              FROM (SELECT *
                                                                      FROM TZTINC a1
                                                                     WHERE a1.campus = p_campus
                                                                       AND a1.nivel  = p_nivel
                                                                       AND a1.codigo = Vm_Codigo_TBRACCD
                                                                       AND a1.Costo + NVL (a1.Aumento,0) > Vm_aMount_TBRACCD
                                                                     ORDER BY a1.Costo, a1.notas_min
                                                                   ) a2
                                                               WHERE RowNum <= 1
                                                           );


               -- Contro de Errores
               EXCEPTION
                  WHEN OTHERS THEN
                       Vm_Bandera := 'ERROR AL OBTENER EL MONTO EN "TZTINC [01]" --> ' || Vm_Codigo_TBRACCD || '/'   || 
                                                                                          Vm_aMount_TBRACCD || ' - ' ||SUBSTR(SQLERRM, 1, 500);
               END;
               
            ELSE
               -- No existe configuracion en TZTINC para el importe de TBRACCD (Casos especiales)
               BEGIN
                 -- DBMS_OUTPUT.PUT_LINE ('Query sin configuración... ');
                 -- DBMS_OUTPUT.PUT_LINE ('Vm_Cuantas_Veces_TBRACCD = ' || Vm_Cuantas_Veces_TBRACCD);
                 -- DBMS_OUTPUT.PUT_LINE ('Vm_Codigo_TBRACCD        = ' || Vm_Codigo_TBRACCD);
                 -- DBMS_OUTPUT.PUT_LINE ('Vm_aMount_TBRACCD        = ' || Vm_aMount_TBRACCD);
                 
                 SELECT a.codigo,  b.tbbdetc_Desc,  a.costo, a.vigencia, a.fecha_solicitud, Vm_Fecha_Solicitud, 
                        a.Aumento, NVL (a.notas_max,99) - NVL (a.notas_min,0)+1 Cuantas_Veces, NVL (c.TVRDCTX_CURR_CODE, 'XXX')
                   INTO p_codigo,   p_Descripcion,   p_Monto, p_Vigencia, p_fecha_solicitud, p_fecha_inicio,     
                        p_Aumento,  p_Cuantas_Veces, p_Moneda
                   FROM TZTINC a, TBBDETC b, TVRDCTX c  
                  WHERE a.campus = p_campus
                    AND a.nivel  = p_nivel
                    AND b.tbbdetc_detail_code = a.codigo 
                    AND c.TVRDCTX_DETC_CODE   = a.codigo 
                    AND (a.codigo, a.costo, a.notas_min) = (SELECT a2.codigo, a2.costo, a2.notas_min
                                                              FROM (SELECT *
                                                                      FROM TZTINC a1
                                                                     WHERE a1.campus    = p_campus
                                                                       AND a1.nivel     = p_nivel
                                                                       AND a1.codigo    = Vm_Codigo_TBRACCD
                                                                       AND a1.notas_min = (SELECT MIN (z.notas_min)
                                                                                             FROM TZTINC z
                                                                                            WHERE z.campus     = p_campus
                                                                                              AND z.nivel      = p_nivel
                                                                                              AND z.codigo     = Vm_Codigo_TBRACCD
                                                                                              AND Vm_Cuantas_Veces_TBRACCD+1 BETWEEN z.notas_min AND z.notas_max
                                                                                           )
                                                                     ORDER BY a1.Costo, a1.notas_min
                                                                   ) a2
                                                               WHERE RowNum <= 1
                                                           );
                                                           
               -- Asigna el valor inconsistente de TBRACCD (Monto sin configuración)
               -- DBMS_OUTPUT.PUT_LINE ('--------------- Antes de hacer la asignación---------------------');
               -- DBMS_OUTPUT.PUT_LINE ('Vm_aMount_TBRACCD (Sin Configuracion) = ' || Vm_aMount_TBRACCD);
               -- DBMS_OUTPUT.PUT_LINE ('p_monto   (Sin Configuracion)         = ' || p_monto);
               -- DBMS_OUTPUT.PUT_LINE ('p_Aumento (Sin Configuracion)         = ' || p_Aumento);
               
               IF Vm_aMount_TBRACCD >  p_monto THEN p_Aumento := 0; END IF;
               p_monto := Vm_aMount_TBRACCD;    -- Asigna el valor inconsistente de TBRACCD (Monto sin configuración)
               
               -- DBMS_OUTPUT.PUT_LINE ('p_monto [Despues de la Aignación] = ' || p_monto);
             
               -- Contro de Errores (ELSE sin configuración)                  
               EXCEPTION
                  WHEN OTHERS THEN
                       Vm_Bandera := 'ERROR AL OBTENER EL MONTO EN "TZTINC [01]-SIN CONFIGURACION" --> ' || Vm_Codigo_TBRACCD || '/'   || 
                                                                                                            Vm_aMount_TBRACCD || ' - ' ||SUBSTR(SQLERRM, 1, 500);
               END;
               
            END IF; -- Vm_Tiene_Configuracion
          
        ELSE
           NULL;
        END IF;


        -- Contro de Errores
        EXCEPTION
          WHEN OTHERS THEN
               Vm_Bandera := 'ERROR AL OBTENER EL MONTO EN "TZTINC [02]" --> ' || SUBSTR(SQLERRM, 1, 500);
             END;
    END IF;

    RETURN Vm_Bandera;

END F_COMPLE_OBTIENE_COLEGIATURA;

FUNCTION F_COMPLE_PROCESA_COMPLEMENTO (P_MATRICULA     IN VARCHAR2,     -- NULL = Todos los alumnos
                                       P_CAMPUS        IN VARCHAR2,     -- NULL = Todos los campus
                                       P_NIVEL         IN VARCHAR2,     -- NULL = Todos los niveles
                                       P_FECHA_PROCESO IN DATE          -- Fecha en que se ejecuta el proceso; Puede ser NULL
) RETURN VARCHAR2 IS
-- DESCRIPCION: Inserta el registro del complemento de colegiatura con las nuevas reglas a partir del 1/Julio/2023
-- AUTOR......: Omar Meza
-- FECHA......: 06/Julio/2023
-- VERSION....: 1.0.0        Creación


   -- Variables
      Vm_Indice          NUMBER   (10)    := 1;               -- Indice para contar los elementos del FOR
      Vm_Error           VARCHAR2 (500)  := NULL;             -- Bandera para el control de errores
      Vm_Codigo          TZTINC.Codigo%TYPE;                  -- Codigo del Complementp
      Vm_Insertadas      NUMBER   (10)    := 0;               -- Contador de Matriculas que se insertaron en TBRACCD
      Vm_Codigo_Anterior TZTINC.Codigo%TYPE;                  -- Código de Anterior de TBRACCD
      Vm_Desc_Anterior   TBBDETC.TBBDETC_Desc%TYPE;           -- Descripcion del complemento de colegiatura      
      Vm_Monto           TZTINC.Costo%TYPE;                   -- Importe del Complemento
      Vm_Vigencia        TZTINC.Vigencia%TYPE;                -- Numero de meses de vigencia (Complemento de Colegiatura)
      Vm_Fecha_Solicitud TZTINC.Fecha_Solicitud%TYPE;         -- Fecha de Solicitud de Inicio del Complemento de Colegiatura
      Vm_Descripcion     TBBDETC.TBBDETC_Desc%TYPE;           -- Descripcion del complemento de colegiatura
      Vm_Fecha_Inicio    DATE;                                -- Fecha de Inicio de Alumno
      Vm_Fecha_Proceso   DATE;                                -- Fecha en que se ejecuta este proceso
      Vm_Accion          VARCHAR2 (20):= 'NINGUNA';           -- Insert, Update, Ninguna
      Vm_SecuenciaCOL    TBRACCD.TBRACCD_TRAN_NUMBER%TYPE;    -- Numero de Transaccion en TBRACCD
      Vm_Effective_Date  TBRACCD.TBRACCD_EFFECTIVE_DATE%TYPE; -- Fecha para aplicar el complemento
      Vm_dEffective_Ant  TBRACCD.TBRACCD_EFFECTIVE_DATE%TYPE; -- Fecha de comparacion con el ultimo registro de TBRACCD
      Vm_Amount_Anterior TBRACCD.TBRACCD_AMOUNT%TYPE;         -- Importe Anterior (Version para el futuro)
      Vm_Moneda          TBRACCD.TBRACCD_CURR_CODE%TYPE;      -- Divisa (MXN, DLS, EUR, Etc...
      Vm_Aumento         NUMBER := 0;                         -- Incremento en el costo del compelento de colegiatura
      Vm_Cuantas_Veces   NUMBER := 0;                         -- Numero de veces consecutivas que se debe aplicar el incremento
      Vm_Veces_Aplicado  NUMBER := 0;                         -- Cuantas veces se ha aplicado el incremento consecutivo
      Vm_Status_Codigo   VARCHAR2 (10)  := 'REUTILIZAR';      -- Se reutiliza el codigo existente (todavia se pueden aplicar recurrencias
      
      --------------------------
      vl_fecha_ini_fin date;
      

   -- Cursores
   CURSOR c_Alumnos IS
          -- Curso tomado del procedimiento de VMRL (24/Julio)
          SELECT DISTINCT a.matricula, a.pidm, a.programa, a.campus, a.nivel, b.SFRSTCR_TERM_CODE periodo, a.fecha_inicio,
                 b.SFRSTCR_PTRM_CODE Parte_Periodo, a.sp STUDY_PATH, 
                 DECODE (SUBSTR (pkg_utilerias.f_calcula_rate(a.pidm,a.programa),4,1),'A','15', 'B','30', 'C', '10') Rate
                 , NULL Folio   -- OMS (Pendiente de Obtener)
            FROM tztprog a, sfrstcr b, ssbsect c
           WHERE 1 = 1
             AND a.matricula = NVL (p_matricula, a.matricula) 
             AND a.campus    = NVL (p_campus,    a.campus)
             AND a.nivel     = NVL (p_nivel,     a.nivel)
             AND a.estatus   = 'MA'
             AND a.sp        = (SELECT MAX (a1.sp) FROM tztprog a1 WHERE a1.matricula = a.matricula)
             AND b.SFRSTCR_PIDM      = a.pidm
             AND b.SFRSTCR_RSTS_CODE = 'RE'
             And b.SFRSTCR_STSP_KEY_SEQUENCE = a.sp
             AND SUBSTR (b.SFRSTCR_TERM_CODE, 5,1) NOT IN ('8', '9')   
             AND c.SSBSECT_TERM_CODE = b.SFRSTCR_TERM_CODE 
             AND c.SSBSECT_CRN       = b.SFRSTCR_CRN
             AND TRUNC (c.SSBSECT_PTRM_START_DATE) = a.fecha_inicio
           ORDER BY 3,4,2
               ;

BEGIN
   -- Recorre el ciclo para todos los alumnos recuperados en el cursor
   FOR i_Alumnos IN c_Alumnos LOOP

       -- DBMS_OUTPUT.PUT_LINE ('Procesando matricula No. ' || Vm_Indice || ' [' || i_Alumnos.Matricula || ' / ' || i_Alumnos.Pidm ||
       --                      '] i_Alumnos.Fecha_Inicio: ' || i_alumnos.Fecha_Inicio);

       -- Obtiene los valores del complemento de colegiatura
       Vm_Aumento         := 0;         Vm_Cuantas_Veces   := 0;          Vm_Codigo          := NULL;
       Vm_Descripcion     := NULL;      Vm_Monto           := NULL;       Vm_Vigencia        := 0;
       Vm_Fecha_Solicitud := sysdate;   Vm_Fecha_Inicio    := sysdate;
       Vm_Status_Codigo   := NULL;

       Vm_Error := F_COMPLE_OBTIENE_COLEGIATURA (i_Alumnos.Campus, i_Alumnos.Nivel, i_Alumnos.Pidm,   i_Alumnos.Periodo,
                                                 Vm_Codigo,  Vm_Descripcion,   Vm_Monto,  Vm_Vigencia, Vm_Fecha_Solicitud, Vm_Fecha_Inicio,
                                                 Vm_Aumento, Vm_Cuantas_Veces, Vm_Moneda, Vm_Status_Codigo, i_Alumnos.fecha_Inicio,
                                                 i_Alumnos.Study_Path);

       -- Imprime los valores de salida, solo si se procesa de manaera individual 
       IF p_matricula IS NOT NULL THEN
          DBMS_OUTPUT.PUT_LINE (CHR(10));
          DBMS_OUTPUT.PUT_LINE ('Vm_Codigo.....: ' || Vm_Codigo);
          DBMS_OUTPUT.PUT_LINE ('Vm_Perodo.....: ' || i_Alumnos.Periodo);
          DBMS_OUTPUT.PUT_LINE ('Vm_Descripcion: ' || Vm_Descripcion);
          DBMS_OUTPUT.PUT_LINE ('Vm_Monto......: ' || Vm_Monto);
          DBMS_OUTPUT.PUT_LINE ('Vm_Vigencia...: ' || Vm_Vigencia);
          DBMS_OUTPUT.PUT_LINE ('Vm_Aumento....: ' || Vm_Aumento);
          DBMS_OUTPUT.PUT_LINE ('Vm_Cuantas_Vcs: ' || Vm_Cuantas_Veces);
          DBMS_OUTPUT.PUT_LINE ('Rate..........: ' || i_Alumnos.Rate);
          DBMS_OUTPUT.PUT_LINE ('Vm_Error......: ' || Vm_Error);
          DBMS_OUTPUT.PUT_LINE ('Vm_Status_Codi: ' || Vm_Status_Codigo); 
      --  DBMS_OUTPUT.PUT_LINE ('Vm_Fecha_Solicitud (TZTINC): ' || Vm_Fecha_Solicitud);
      --  DBMS_OUTPUT.PUT_LINE ('Vm_Fecha_Inicio (Funcion)..: ' || Vm_Fecha_Inicio);
          DBMS_OUTPUT.PUT_LINE ('Vm_Fecha_Inicio (Cursor)...: ' || i_Alumnos.Fecha_Inicio);
       END IF;

       IF Vm_Error = 'NORMAL' THEN

          -- Compatibilidad con la version anterior
          Vm_Codigo_Anterior := Vm_Codigo; 
          Vm_Desc_Anterior   := Vm_Descripcion;
          Vm_Amount_Anterior := Vm_Monto;


          -- Reasigna el codigo de NACIMIENTO del complemento
          IF Vm_Codigo_Anterior IS NOT NULL THEN 
             Vm_Codigo      := Vm_Codigo_Anterior;
             Vm_Descripcion := Vm_Desc_Anterior;

             IF Vm_Status_Codigo = 'NUEVO' THEN
                Vm_Monto := Vm_Monto + Vm_Aumento;
             ELSE
                Vm_Monto := Vm_Amount_Anterior;
             END IF;
          END IF;

          -- En que fecha se ejecuta este proceso?
          IF p_fecha_proceso IS NULL 
             THEN Vm_Fecha_Proceso := Sysdate;
             ELSE Vm_Fecha_Proceso := p_fecha_Proceso;
          END IF;

          -- Define la acción a implementar
          Vm_Accion := F_Comple_Accion_Implementar (i_Alumnos.pidm,   Vm_Codigo,  i_Alumnos.Campus, i_Alumnos.Nivel, Vm_Vigencia, 
                                             Vm_Fecha_Proceso, Vm_Effective_Date, i_Alumnos.Rate,  i_Alumnos.Study_Path);


          -- Imprime los valores de salida, solo si se procesa de manaera individual 
          IF p_matricula IS NOT NULL THEN                                             
             DBMS_OUTPUT.PUT_LINE (CHR(10));
             DBMS_OUTPUT.PUT_LINE ('Regresa de Accion_Implementar...');
             DBMS_OUTPUT.PUT_LINE ('Vm_Accion........: ' || Vm_Accion);
             DBMS_OUTPUT.PUT_LINE ('Vm_Monto.........: ' || Vm_Monto);    
             DBMS_OUTPUT.PUT_LINE ('Vm_Aumento.......: ' || Vm_Aumento);
             DBMS_OUTPUT.PUT_LINE ('Vm_Codigo........: ' || Vm_Codigo);
             DBMS_OUTPUT.PUT_LINE ('Vm_Effective_Date: ' || Vm_Effective_Date);
          -- DBMS_OUTPUT.PUT_LINE ('Vm_dEffective_Ant: ' || Vm_dEffective_Ant);
          END IF;

          -- Inicia con las validaciones de la version 2.0 del proceso
          -- DBMS_OUTPUT.PUT_LINE ('Validaciones del proceso 2.0');
          IF Vm_dEffective_Ant < TO_DATE ('01/07/2023', 'DD/MM/YYYY') THEN          
             Vm_Monto := Vm_Monto + Vm_Aumento;
          ELSE

             -- Cuenta cuantas veces se a aplicado el incremento con la misma cantidad
             BEGIN
               SELECT Count(*)
                 INTO Vm_Veces_Aplicado
                 FROM tbraccd a
                WHERE tbraccd_pidm        = i_Alumnos.PIDM
                  AND tbraccd_detail_code = Vm_Codigo
                  AND tbraccd_amount      = Vm_Monto + Vm_Aumento;

             EXCEPTION
               WHEN OTHERS THEN Vm_Veces_Aplicado := 0;
             END;

             -- Imprime los valores de salida, solo si se procesa de manaera individual 
             IF p_matricula IS NOT NULL THEN                                             
                DBMS_OUTPUT.PUT_LINE (CHR(10));
                DBMS_OUTPUT.PUT_LINE ('Vm_Veces_Aplicado: ' || Vm_Veces_Aplicado);
                DBMS_OUTPUT.PUT_LINE ('Vm_Cuantas_Veces.: ' || Vm_Cuantas_Veces);
                DBMS_OUTPUT.PUT_LINE ('Vm_Monto.........: ' || Vm_Monto);
                DBMS_OUTPUT.PUT_LINE ('Vm_Aumento.......: ' || Vm_Aumento);
             END IF;

             -- Si alcanzo el limite de veces aplicado el incremento; aplica el EPSILON del costo             
             IF Vm_Veces_Aplicado >= Vm_Cuantas_Veces THEN
                Vm_Monto := Vm_Monto + Vm_Aumento;
             END IF;
          END IF;

          -- Accion a implementar...?
          IF Vm_Accion = 'INSERTAR' THEN
             -- Inserta el nuevo registro en la cartera del alumno
             Vm_SecuenciaCOL := PKG_FINANZAS.F_MAX_SEC_TBRACCD (i_Alumnos.PIDM);
             -- DBMS_OUTPUT.PUT_LINE ('Vm_SecuenciaCOL ...........: ' || Vm_SecuenciaCOL);
            
               vl_fecha_ini_fin := i_Alumnos.FECHA_INICIO + 60;  ---> Rango de fechas con base a la fecha de inicio
               
               /*
               DBMS_OUTPUT.PUT_LINE ('Compara: ' || to_char (Vm_Effective_Date,      'DD/MM/YYYY')  || ' entre ' || 
                                                    to_char (i_Alumnos.FECHA_INICIO, 'DD/MM/YYYY')  || ' y '     ||
                                                    to_char (vl_fecha_ini_fin,       'DD/MM/YYYY')) ;
               */
                                                    
               if Vm_Effective_Date  between  i_Alumnos.FECHA_INICIO and  vl_fecha_ini_fin then 


                     BEGIN
                        -- DBMS_OUTPUT.PUT_LINE ('JUSTO ANTES DEL INSERT... i_Alumnos.STUDY_PATH = ' || i_Alumnos.STUDY_PATH);
                        INSERT INTO TBRACCD 
                                  ( TBRACCD_PIDM,              TBRACCD_TRAN_NUMBER,        TBRACCD_TERM_CODE,           TBRACCD_DETAIL_CODE,        TBRACCD_USER,     TBRACCD_ENTRY_DATE,
                                    TBRACCD_AMOUNT,            TBRACCD_BALANCE,            TBRACCD_EFFECTIVE_DATE,      TBRACCD_BILL_DATE,          TBRACCD_DUE_DATE, TBRACCD_DESC,
                                    TBRACCD_RECEIPT_NUMBER,    TBRACCD_TRAN_NUMBER_PAID,   TBRACCD_CROSSREF_PIDM,       TBRACCD_CROSSREF_NUMBER,    TBRACCD_CROSSREF_DETAIL_CODE,
                                    TBRACCD_SRCE_CODE,         TBRACCD_ACCT_FEED_IND,      TBRACCD_ACTIVITY_DATE,       TBRACCD_SESSION_NUMBER,     TBRACCD_CSHR_END_DATE,
                                    TBRACCD_CRN,               TBRACCD_CROSSREF_SRCE_CODE, TBRACCD_LOC_MDT,             TBRACCD_LOC_MDT_SEQ,        TBRACCD_RATE,
                                    TBRACCD_UNITS,             TBRACCD_DOCUMENT_NUMBER,    TBRACCD_TRANS_DATE,          TBRACCD_PAYMENT_ID,         TBRACCD_INVOICE_NUMBER,
                                    TBRACCD_STATEMENT_DATE,    TBRACCD_INV_NUMBER_PAID,    TBRACCD_CURR_CODE,           TBRACCD_EXCHANGE_DIFF,      TBRACCD_FOREIGN_AMOUNT,
                                    TBRACCD_LATE_DCAT_CODE,    TBRACCD_FEED_DATE,          TBRACCD_FEED_DOC_CODE,       TBRACCD_ATYP_CODE,          TBRACCD_ATYP_SEQNO,
                                    TBRACCD_CARD_TYPE_VR,      TBRACCD_CARD_EXP_DATE_VR,   TBRACCD_CARD_AUTH_NUMBER_VR, TBRACCD_CROSSREF_DCAT_CODE, TBRACCD_ORIG_CHG_IND,
                                    TBRACCD_CCRD_CODE,         TBRACCD_MERCHANT_ID,        TBRACCD_TAX_REPT_YEAR,       TBRACCD_TAX_REPT_BOX,       TBRACCD_TAX_AMOUNT,
                                    TBRACCD_TAX_FUTURE_IND,    TBRACCD_DATA_ORIGIN,        TBRACCD_CREATE_SOURCE,       TBRACCD_CPDT_IND,           TBRACCD_AIDY_CODE,
                                    TBRACCD_STSP_KEY_SEQUENCE, TBRACCD_PERIOD,             TBRACCD_SURROGATE_ID,        TBRACCD_VERSION,            TBRACCD_USER_ID, TBRACCD_VPDI_CODE)
                             VALUES (i_Alumnos.PIDM,          -- TBRACCD_PIDM
                                     Vm_SecuenciaCOL,         -- TBRACCD_TRAN_NUMBER
                                     i_Alumnos.PERIODO,       -- TBRACCD_TERM_CODE
                                     Vm_Codigo,               -- TBRACCD_DETAIL_CODE 
                                     USER,                    -- TBRACCD_USER
                                     SYSDATE,                 -- TBRACCD_ENTRY_DATE
                                     NVL(Vm_Monto,0),         -- TBRACCD_AMOUNT
                                     NVL(Vm_Monto,0),         -- TBRACCD_BALANCE
                                     Vm_Effective_Date,       -- TBRACCD_EFFECTIVE_DATE
                                     NULL,                    -- TBRACCD_BILL_DATE
                                     NULL,                    -- TBRACCD_DUE_DATE
                                     Vm_Descripcion,          -- TBRACCD_DESC
                                     i_Alumnos.FOLIO,         -- TBRACCD_RECEIPT_NUMBER
                                     NULL,                    -- TBRACCD_TRAN_NUMBER_PAID
                                     NULL,                    -- TBRACCD_CROSSREF_PIDM
                                     NULL,                    -- TBRACCD_CROSSREF_NUMBER
                                     NULL,                    -- TBRACCD_CROSSREF_DETAIL_CODE
                                     'T',                     -- TBRACCD_SRCE_CODE
                                     'Y',                     -- TBRACCD_ACCT_FEED_IND
                                     SYSDATE,                 -- TBRACCD_ACTIVITY_DATE
                                     0,                       -- TBRACCD_SESSION_NUMBER
                                     NULL,                    -- TBRACCD_CSHR_END_DATE
                                     NULL,                    -- TBRACCD_CRN
                                     NULL,                    -- TBRACCD_CROSSREF_SRCE_CODE
                                     NULL,                    -- TBRACCD_LOC_MDT
                                     NULL,                    -- TBRACCD_LOC_MDT_SEQ
                                     NULL,                    -- TBRACCD_RATE
                                     NULL,                    -- TBRACCD_UNITS
                                     NULL,                    -- TBRACCD_DOCUMENT_NUMBER
                                     Vm_Effective_Date,       -- TBRACCD_TRANS_DATE
                                     NULL,                    -- TBRACCD_PAYMENT_ID
                                     NULL,                    -- TBRACCD_INVOICE_NUMBER
                                     NULL,                    -- TBRACCD_STATEMENT_DATE
                                     NULL,                    -- TBRACCD_INV_NUMBER_PAID
                                     Vm_Moneda,               -- TBRACCD_CURR_CODE
                                     NULL,                    -- TBRACCD_EXCHANGE_DIFF  -- Se gurada la referencia del cargo
                                     NULL,                    -- TBRACCD_FOREIGN_AMOUNT
                                     NULL,                    -- TBRACCD_LATE_DCAT_CODE
                                     i_Alumnos.FECHA_INICIO,  -- TBRACCD_FEED_DATE
                                     NULL,                    -- TBRACCD_FEED_DOC_CODE
                                     NULL,                    -- TBRACCD_ATYP_CODE
                                     NULL,                    -- TBRACCD_ATYP_SEQNO
                                     NULL,                    -- TBRACCD_CARD_TYPE_VR
                                     NULL,                    -- TBRACCD_CARD_EXP_DATE_VR
                                     NULL,                    -- TBRACCD_CARD_AUTH_NUMBER_VR
                                     NULL,                    -- TBRACCD_CROSSREF_DCAT_CODE
                                     NULL,                    -- TBRACCD_ORIG_CHG_IND
                                     NULL,                    -- TBRACCD_CCRD_CODE
                                     NULL,                    -- TBRACCD_MERCHANT_ID
                                     NULL,                    -- TBRACCD_TAX_REPT_YEAR
                                     NULL,                    -- TBRACCD_TAX_REPT_BOX
                                     NULL,                    -- TBRACCD_TAX_AMOUNT
                                     NULL,                    -- TBRACCD_TAX_FUTURE_IND
                                     'COMPLEMENTO (COLE)',    -- TBRACCD_DATA_ORIGIN
                                     'COMPLEMENTO (COLE)',    -- TBRACCD_CREATE_SOURCE
                                     NULL,                    -- TBRACCD_CPDT_IND
                                     NULL,                    -- TBRACCD_AIDY_CODE
                                     i_Alumnos.STUDY_PATH,    -- TBRACCD_STSP_KEY_SEQUENCE
                                     i_Alumnos.PARTE_PERIODO, -- TBRACCD_PERIOD
                                     NULL,                    -- TBRACCD_SURROGATE_ID
                                     NULL,                    -- TBRACCD_VERSION
                                     USER,                    -- TBRACCD_USER_ID
                                     NULL );                  -- TBRACCD_VPDI_CODE

                         -- Control de Matriculas insertadas
                         Vm_Insertadas := Vm_Insertadas +1;

                      -- Control de errores del INSERT
                     EXCEPTION
                         WHEN OTHERS THEN
                              Vm_Error := 'Se presento ERROR INSERT TBRACCD --> '|| SUBSTR (SQLERRM, 1, 450);
                     END;
               End if;

          ELSIF Vm_Accion = 'UPDATE' THEN 
                DBMS_OUTPUT.PUT_LINE ('Actualiza el registro en el estado de cuenta TBRACCD');
          ELSE  DBMS_OUTPUT.PUT_LINE ('NO Realiza ninguna acción...');
          END IF;   
       END IF; -- Vm_Error = 'NORMAL'

       -- Control para pruebas; pocos registros
       Vm_Indice := Vm_Indice + 1; -- Indice para contar los elementos del FOR
       IF Vm_Indice > 1000000 THEN
          EXIT; -- Sale del Ciclo
       END IF;
   END LOOP;
   Commit;
   Vm_Indice := Vm_Indice - 1; -- Indice para contar los elementos del FOR
   


   -- Imprime los valores de salida, solo si se procesa de manaera individual 
   IF p_matricula IS NOT NULL THEN                                             
      DBMS_OUTPUT.PUT_LINE (CHR(10));
      DBMS_OUTPUT.PUT_LINE ('Termina el Ciclo principal... ');
      DBMS_OUTPUT.PUT_LINE ('Universo de Matriculas....... ' || Vm_Indice);
      DBMS_OUTPUT.PUT_LINE ('Matriculas Procesadas........ ' || Vm_Insertadas);
      
      RETURN Vm_Error;
   END IF;

   -- Si no hay error; regresa el numero de registros procesados
   RETURN Vm_Insertadas || ' Matricula(s) Procesada(s) de un Universo de ' ||  Vm_Indice || ' Alumno(s)';


-- Control de Errores
EXCEPTION
   WHEN OTHERS 
        THEN Vm_Error := SUBSTR(SQLERRM, 1, 500);
             DBMS_OUTPUT.PUT_LINE ('Ocurrio un error el proceso...');

END F_COMPLE_PROCESA_COMPLEMENTO;

-- End - Funciones Complementos de colegiaturas


Procedure ejecuta_complemento is
VL_ERROR            VARCHAR2(500);

------------------ Procedimiento que invoca la recurrencia de los complementos de colegiatura --------------------------

Begin 
    
   VL_ERROR:= PKG_FINANZAS_REZA.F_COMPLE_PROCESA_COMPLEMENTO(null, null, null, sysdate);
   Commit;

End ejecuta_complemento;




END PKG_FINANZAS_REZA;
/

DROP PUBLIC SYNONYM PKG_FINANZAS_REZA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FINANZAS_REZA FOR BANINST1.PKG_FINANZAS_REZA;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_FINANZAS_REZA TO PUBLIC;
