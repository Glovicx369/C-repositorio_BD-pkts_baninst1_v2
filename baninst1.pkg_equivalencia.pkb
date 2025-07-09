DROP PACKAGE BODY BANINST1.PKG_EQUIVALENCIA;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_EQUIVALENCIA AS
   FUNCTION f_dato_grls (p_pidm in number,p_programa varchar2) RETURN PKG_EQUIVALENCIA.cursor_out_dato_grls
           AS
                c_out_dato_grls PKG_EQUIVALENCIA.cursor_out_dato_grls;

  BEGIN
       open c_out_dato_grls
         FOR
                 SELECT DISTINCT
                    spriden_id ID,
                    spriden_first_name||' '||replace(spriden_last_name,'/',' ') NOMBRE_ALUMNO,
                    (SELECT goremal_email_address
                    FROM goremal
                    WHERE
                    1=1
                    AND a.pidm = goremal_pidm
                    AND goremal_emal_code = 'PRIN'
                    AND GOREMAL_PREFERRED_IND = 'Y') CORREO,
                    (SELECT sztdtec_programa_comp
                    FROM sztdtec
                    WHERE 1=1
                    AND a.programa = sztdtec_program
                    AND a.ctlg = sztdtec_term_code) DESCRIP_PROGRA,
                    nvl((select DECODE(max(SARCHKL_CKST_CODE),
                                  'VALIDADO','OK_ACNO')
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACNO')
                         and SARCHKL_PIDM =a.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_TERM_CODE_ENTRY = SARCHKL_TERM_CODE_ENTRY
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO),'sin información')Acta_de_nacimiento,
                    nvl((select DECODE(max(SARCHKL_CKST_CODE),
                                 'VALIDADO','OK_CTBO')
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBO')
                         and SARCHKL_PIDM =a.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_TERM_CODE_ENTRY = SARCHKL_TERM_CODE_ENTRY
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'sin información')Certificado_de_Bachillerato,
                      nvl((select DECODE (max(SARCHKL_CKST_CODE),
                                     'VALIDADO','OK_CAPO')
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAPO')
                         and SARCHKL_PIDM =a.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_TERM_CODE_ENTRY = SARCHKL_TERM_CODE_ENTRY
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'sin información')Carta_poder,
                    nvl((select decode(max(SARCHKL_CKST_CODE),
                                    'VALIDADO','OK_CPLO')
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPLO')
                         and SARCHKL_PIDM =a.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_TERM_CODE_ENTRY = SARCHKL_TERM_CODE_ENTRY
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'sin información')Certificado_parcial_de_Lic ,
                    NVL((SELECT
                           CASE WHEN B.TBRACCD_BALANCE=0 THEN
                                    'PAGADO'
                                WHEN  B.TBRACCD_BALANCE=B.TBRACCD_AMOUNT THEN
                                     'NO PAGADO'
                                WHEN  B.TBRACCD_BALANCE>0 AND B.TBRACCD_BALANCE< B.TBRACCD_AMOUNT THEN
                                     'PAGO PARCIAL'
                              END PAGO
                          FROM SPRIDEN a, TBRACCD b
                          WHERE a.SPRIDEN_CHANGE_IND IS NULL
                               AND a.SPRIDEN_PIDM = b.TBRACCD_PIDM
                               AND a.spriden_pidm=a.pidm
                               AND SUBSTR(b.TBRACCD_DETAIL_CODE,3,2)='BH'
                               and b.TBRACCD_TRAN_NUMBER  IN (select a.TBRAPPL_CHG_TRAN_NUMBER
                                                                from TBRAPPL a
                                                                Where b.tbraccd_pidm = a.TBRAPPL_pidm
                                                                  And a.TBRAPPL_PAY_TRAN_NUMBER  in (select x1.TBRACCD_TRAN_NUMBER
                                                                                                                from tbraccd  x1, TZTNCD
                                                                                                                where a.TBRAPPL_pidm = x1.tbraccd_pidm
                                                                                                                And tbraccd_detail_code =  TZTNCD_CODE
                                                                                                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                                                                    )
                                                             )
                         UNION
                         SELECT DISTINCT
                                CASE WHEN B.TBRACCD_BALANCE=0 THEN
                                    'NOTAS DE CREDITO'
                                WHEN  B.TBRACCD_BALANCE=B.TBRACCD_AMOUNT THEN
                                     'NO PAGADO'
                                WHEN  B.TBRACCD_BALANCE>0 AND B.TBRACCD_BALANCE< B.TBRACCD_AMOUNT THEN
                                     'PAGO PARCIAL'
                              END PAGO
                             FROM SPRIDEN a, TBRACCD b
                          WHERE a.SPRIDEN_CHANGE_IND IS NULL
                               AND a.SPRIDEN_PIDM = b.TBRACCD_PIDM
                               AND a.spriden_pidm=a.pidm
                               AND SUBSTR(b.TBRACCD_DETAIL_CODE,3,2)='BH'
                               and b.TBRACCD_TRAN_NUMBER  NOT IN (select a.TBRAPPL_CHG_TRAN_NUMBER
                                                                from TBRAPPL a
                                                                Where b.tbraccd_pidm = a.TBRAPPL_pidm
                                                                  And a.TBRAPPL_PAY_TRAN_NUMBER  in (select x1.TBRACCD_TRAN_NUMBER
                                                                                                                from tbraccd  x1, TZTNCD
                                                                                                                where a.TBRAPPL_pidm = x1.tbraccd_pidm
                                                                                                                And tbraccd_detail_code =  TZTNCD_CODE
                                                                                                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                                                                    )
                                                     )),'sin información')pago,
                    (SELECT nvl(SHRNCRS_NCST_CODE,'IN')
                         FROM SHRNCRS
                         WHERE 1=1
                         AND SHRNCRS_PIDM=a.pidm
                         AND SHRNCRS_NCRQ_CODE='EQ')ESTATUS,
                        SGRCOOP_END_DATE FECHA_INIC,
                        SGRCOOP_BEGIN_DATE FECHA_FIN,
                        SGRCOOP_TERM_CODE periodo
                FROM tztprog A, spriden,sgrcoop
                WHERE 1=1
                AND a.pidm = spriden_pidm
                AND a.matricula = spriden_id
                AND A.PIDM=SGRCOOP_PIDM(+)
                AND a.TIPO_INGRESO=SGRCOOP_COPC_CODE(+)
                AND spriden_change_ind IS NULL
                AND a.pidm = p_pidm
                and a.PROGRAMA=p_programa
                and a.TIPO_INGRESO IN (select ZSTPARA_PARAM_ID
                                     FROM ZSTPARA
                                     where 1=1
                                     AND ZSTPARA_MAPA_ID='ING_VALID')
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg);
       RETURN (c_out_dato_grls);

  END;
------
------
FUNCTION f_inserta_eq(p_pidm NUMBER, p_usuario VARCHAR2,p_fecha_tramite varchar2,p_estatus VARCHAR2) RETURN VARCHAR2
      IS

l_contar NUMBER;
l_max_sgrcoop_surrogate_id NUMBER;
VL_NIVEL VARCHAR2(4);
VL_SEQNO number;
VL_SEQNOCOOP varchar(2);
vl_fecha_ten date;
VL_PERIODO VARCHAR2(6);
l_error VARCHAR2 (1000);
l_contar_SHRNCRS NUMBER;


BEGIN
--

    BEGIN

       SELECT (sgrcoop_surrogate_id_sequence.NEXTVAL)
       INTO l_max_sgrcoop_surrogate_id
       FROM dual
       WHERE 1=1;

        DBMS_OUTPUT.PUT_LINE('CONTAR 1: '||l_max_sgrcoop_surrogate_id);
     Exception When Others then

                   l_error := 'SIN REGISTRO SGRCOOP_SURROGATE'||sqlerrm;

      DBMS_OUTPUT.PUT_LINE('SIN REGISTRO'||l_error);

       END;

      BEGIN
                SELECT NIVEL
                   INTO VL_NIVEL
                    FROM tztprog A
                WHERE 1=1
                AND a.pidm = p_pidm
                and TIPO_INGRESO='EQ'
--                AND ESTATUS='MA'
                and a.TIPO_INGRESO IN (select ZSTPARA_PARAM_ID
                                     FROM ZSTPARA
                                     where 1=1
                                     AND ZSTPARA_MAPA_ID='ING_VALID')
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg);
                                   
                DBMS_OUTPUT.PUT_LINE('NIVEL'||VL_NIVEL);
                
       Exception When Others then

                   l_error := 'SIN REGISTRO'||sqlerrm;

                 DBMS_OUTPUT.PUT_LINE('SIN REGISTRO TZTPROG'||l_error);

       END;

   BEGIN
       FOR C IN (     SELECT *
                    FROM tztprog A
                WHERE 1=1
                AND a.pidm = p_pidm
--                and a.PROGRAMA=p_programa
                and TIPO_INGRESO='EQ'
--                AND ESTATUS='MA'
                and a.TIPO_INGRESO IN (select ZSTPARA_PARAM_ID
                                     FROM ZSTPARA
                                     where 1=1
                                     AND ZSTPARA_MAPA_ID='ING_VALID')
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg)
              )

     LOOP

          BEGIN

                select nvl(MAX(SHRNCRS_SEQ_NO)+1,1)
                 INTO VL_SEQNO
                from SHRNCRS
                where 1=1
                AND SHRNCRS_pidm = p_pidm;
                
            DBMS_OUTPUT.PUT_LINE('SEQNO '||VL_SEQNO);
            
          Exception

              When Others then

                  VL_SEQNO:=1;

                 DBMS_OUTPUT.PUT_LINE('SIN SEQNO SHRNCRS'||l_error);

           END;

          BEGIN
            SELECT MAX(SFRSTCR_TERM_CODE)
               INTO VL_PERIODO
                FROM SFRSTCR
                WHERE 1=1
                AND SFRSTCR_PIDM= p_pidm
                and SFRSTCR_RSTS_CODE='RE'
                and substr(SFRSTCR_TERM_CODE,5,2) not in(90,81,82,83);
                
                DBMS_OUTPUT.PUT_LINE('PERIODO '||VL_PERIODO);
                
           Exception

              When Others then
                         l_error := 'SIN PERIODO SFRSTCR' ||sqlerrm;

                 DBMS_OUTPUT.PUT_LINE('SIN PERIODO'||l_error);

           END;

          DBMS_OUTPUT.PUT_LINE(p_estatus);

          IF p_estatus='EP' THEN


                 BEGIN

                 SELECT DISTINCT COUNT (*)
                 INTO l_contar_SHRNCRS
                 FROM SHRNCRS
                 WHERE 1=1
                 --AND sgrcoop_pidm = FGET_PIDM ('010017225')
                 AND SHRNCRS_pidm = p_pidm
                 AND SHRNCRS_NCRQ_CODE='EQ';
--                 l_error := 'EXITO';
                 DBMS_OUTPUT.PUT_LINE('CONTAR  1: '||l_contar);
                 Exception

                       When Others then
                                  l_error := sqlerrm;

                          DBMS_OUTPUT.PUT_LINE('SIN CONTAR SHRNCRS'||l_error);

                END;

               if l_contar_SHRNCRS=0 then

                  BEGIN
                      INSERT INTO SHRNCRS
                          VALUES
                       ( P_PIDM ,--SHRNCRS_PIDM
                        VL_SEQNO,--SHRNCRS_SEQ_NO
                        sysdate,--SHRNCRS_ACTIVITY_DATE
                        null,--SHRNCRS_QPNM_SEQ_NO
                        NULL,--SHRNCRS_COMT_CODE
                        NULL,--SHRNCRS_EVEN_CODE
                        null,--SHRNCRS_LEVL_CODE
                        'EQ',--SHRNCRS_NCRQ_CODE
                        'EP',--SHRNCRS_NCST_CODE
                        to_date(p_fecha_tramite,'dd/mm/yyyy'),--SHRNCRS_NCST_DATE
                        NULL,--SHRNCRS_ADVR_PIDM
                        NULL,--SHRNCRS_COMPLETE_DATE
                        NULL,--SHRNCRS_SURROGATE_ID
                        NULL,--SHRNCRS_VERSION
                        p_usuario,--SHRNCRS_USER_ID
                        p_usuario,--SHRNCRS_DATA_ORIGIN
                        NULL)--SHRNCRS_VPDI_CODE
                        ;
                      DBMS_OUTPUT.PUT_LINE('Inserta SHRNCRS');
                     l_error := 'EXITO';
                  Exception
                         When Others then

                         l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SHRNCRS ' ||sqlerrm;

                         DBMS_OUTPUT.PUT_LINE('ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SHRNCRS '||l_error);

                    END;

               ELSIF l_contar_SHRNCRS>=1 then


                    l_error := 'YA EXISTE REGISTRO DE EQUIVALENCIA';

               END IF;



--                      BEGIN
--                        UPDATE SHRNCRS
--                        SET SHRNCRS_ACTIVITY_DATE=SYSDATE,
--                            SHRNCRS_NCST_CODE = 'EP',
--                            SHRNCRS_NCST_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy'),
--                            SHRNCRS_USER_ID=p_usuario,
--                            SHRNCRS_DATA_ORIGIN=p_usuario
--                        WHERE 1=1
--                        AND SHRNCRS_PIDM = P_PIDM
--                        AND SHRNCRS_NCRQ_CODE='EQ'
--                        AND SHRNCRS_NCST_CODE='IN';
--                        COMMIT;
--                        l_error := 'EXITO';
--                       DBMS_OUTPUT.PUT_LINE('ACTUALIZA SHRNCRS');
--                      EXCEPTION
--                          WHEN OTHERS THEN
--                          l_error :='ALUMNO ESTA EN ESTATUS EP';
--                      END;

                      BEGIN

                                select nvl(MAX(SGRCOOP_SEQ_NO)+1,1)
                                 INTO VL_SEQNOCOOP
                                from SGRCOOP
                                where 1=1
                                AND SGRCOOP_pidm = p_pidm;

                      Exception

                              When Others then
                                         l_error := 'SIN SEQNO SGRCOOP' ||sqlerrm;

                                 DBMS_OUTPUT.PUT_LINE('SIN SEQNO SGRCOOP'||l_error);

                      END;

                       BEGIN

                        SELECT DISTINCT COUNT (*)
                        INTO l_contar
                        FROM SGRCOOP
                        WHERE 1=1
                        --AND sgrcoop_pidm = FGET_PIDM ('010017225')
                        AND sgrcoop_pidm = p_pidm
                        and SGRCOOP_COPC_CODE='EQ';
--                        l_error := 'EXITO';
                        DBMS_OUTPUT.PUT_LINE('CONTAR  1: '||l_contar);

                       END;

                    IF l_contar = 0 THEN

                          vl_fecha_ten:=(to_date(p_fecha_tramite,'dd/mm/yyyy'))+90;

                         BEGIN

                          INSERT INTO sgrcoop --(SGRCOOP_PIDM,SGRCOOP_TERM_CODE,SGRCOOP_LEVL_CODE,SGRCOOP_EMPL_CODE,SGRCOOP_COPC_CODE,SGRCOOP_END_DATE,SGRCOOP_BEGIN_DATE,SGRCOOP_INTEREST_IND,SGRCOOP_EMPL_CONTACT_NAME,SGRCOOP_EMPL_CONTACT_TITLE,SGRCOOP_ACTIVITY_DATE,SGRCOOP_PHONE_AREA,SGRCOOP_PHONE_NUMBER,SGRCOOP_PHONE_EXT,SGRCOOP_SEQ_NO,SGRCOOP_CRN,SGRCOOP_EVAL_PREPARED_DATE,SGRCOOP_EVAL_RECEIVED_DATE,SGRCOOP_OVERRIDE_IND,SGRCOOP_CTRY_CODE_PHONE,SGRCOOP_SURROGATE_ID,SGRCOOP_VERSION,SGRCOOP_USER_ID,SGRCOOP_DATA_ORIGIN,SGRCOOP_VPDI_CODE)
                          VALUES
                          (p_pidm,
                          VL_PERIODO,
                          VL_NIVEL,
                          null,
                          'EQ',
                          vl_fecha_ten,
                          to_date(p_fecha_tramite,'dd/mm/yyyy'),
                          NULL,
                          NULL,
                          'EQUIVALENCIA',
                          SYSDATE,
                          NULL,
                          NULL,
                          NULL,
                          VL_SEQNOCOOP,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          l_max_sgrcoop_surrogate_id,
                          NULL,
                          'SIU_EQUIVALENCIA',
                          p_usuario,
                          NULL);

                          DBMS_OUTPUT.PUT_LINE('Inserta SGRCOOP');
                          l_error :='EXITO';
                         Exception
                         When Others then
                         l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP ' ||sqlerrm;

                         DBMS_OUTPUT.PUT_LINE('ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP '||l_error);


                         END;

                    ELSIF l_contar >=1 THEN

                      l_error :='ALUMNO YA CUENTA CON EQUIVALENCIA EN PROCESO ';
--                      DBMS_OUTPUT.PUT_LINE('ERROR: '|| 'ALUMNO CUENTA CON EQUIVALENCIA ');

                      END IF;


        ELSIF p_estatus='FI' THEN

                        BEGIN
                          UPDATE SHRNCRS
                          SET SHRNCRS_NCST_CODE = 'FI',
                              SHRNCRS_NCST_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy'),
                              SHRNCRS_USER_ID=p_usuario
                          WHERE 1=1
                          AND SHRNCRS_PIDM = C.PIDM
                          AND SHRNCRS_NCRQ_CODE='EQ'
                          and SHRNCRS_NCST_CODE='EP';
                          COMMIT;
                         l_error := 'EXITO';
                        DBMS_OUTPUT.PUT_LINE('CONTAR  13: '||l_contar);

                        EXCEPTION
                            WHEN OTHERS THEN
                         l_error :='ALUMNO ESTA EN ESTATUS FINALIZADO';
                        END;

                        BEGIN
                          UPDATE SGRCOOP
                          SET SGRCOOP_ACTIVITY_DATE=SYSDATE,
                              SGRCOOP_END_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy'),
                              SGRCOOP_DATA_ORIGIN=p_usuario
                          WHERE 1=1
                          AND SGRCOOP_PIDM = C.PIDM
                          AND SGRCOOP_COPC_CODE='EQ';
                          COMMIT;
                         l_error := 'EXITO';
                          DBMS_OUTPUT.PUT_LINE('CONTAR  13.5: '||l_contar);
                        EXCEPTION
                            WHEN OTHERS THEN
                             l_error :='ALUMNO ESTA EN ESTATUS FINALIZADO';
                        END;
        end if;

     END LOOP;

   END;

COMMIT;

RETURN (l_error);

END;
--
--
FUNCTION f_inserta_eq_masivo(p_pidm NUMBER, p_usuario VARCHAR2,p_fecha_tramite varchar2,p_estatus VARCHAR2) RETURN VARCHAR2
      IS

l_contar NUMBER;
l_max_sgrcoop_surrogate_id NUMBER;
VL_NIVEL VARCHAR2(4);
VL_SEQNO number;
VL_SEQNOCOOP varchar(2);
vl_fecha_ten date;
VL_PERIODO VARCHAR2(6);
l_error VARCHAR2 (1000);
l_contar_SHRNCRS number;


BEGIN
--

    BEGIN

       SELECT (sgrcoop_surrogate_id_sequence.NEXTVAL)
       INTO l_max_sgrcoop_surrogate_id
       FROM dual
       WHERE 1=1;

        DBMS_OUTPUT.PUT_LINE('CONTAR 2: '||l_max_sgrcoop_surrogate_id);

    END;

      BEGIN
                SELECT NIVEL
                   INTO VL_NIVEL
                    FROM tztprog A
                WHERE 1=1
                AND a.pidm = p_pidm
                and TIPO_INGRESO='EQ'
--                AND ESTATUS='MA'
                and a.TIPO_INGRESO IN (select ZSTPARA_PARAM_ID
                                     FROM ZSTPARA
                                     where 1=1
                                     AND ZSTPARA_MAPA_ID='ING_VALID')
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg);

            DBMS_OUTPUT.PUT_LINE('CONTAR 3 : '||VL_NIVEL);
    END;

   BEGIN
       FOR C IN (     SELECT *
                    FROM tztprog A
                WHERE 1=1
                AND a.pidm = p_pidm
--                and a.PROGRAMA=p_programa
                and TIPO_INGRESO='EQ'
--                AND ESTATUS='MA'
                and a.TIPO_INGRESO IN (select ZSTPARA_PARAM_ID
                                     FROM ZSTPARA
                                     where 1=1
                                     AND ZSTPARA_MAPA_ID='ING_VALID')
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg)
              )

     LOOP

          BEGIN

                select nvl(MAX(SHRNCRS_SEQ_NO)+1,1)
                 INTO VL_SEQNO
                from SHRNCRS
                where 1=1
                AND SHRNCRS_pidm = p_pidm;

          Exception

              When Others then

                  VL_SEQNO:=1||sqlerrm;

                 DBMS_OUTPUT.PUT_LINE('SIN SEQNO SHRNCRS'||sqlerrm);

           END;

          BEGIN
            SELECT MAX(SFRSTCR_TERM_CODE)
               INTO VL_PERIODO
                FROM SFRSTCR
                WHERE 1=1
                AND SFRSTCR_PIDM= p_pidm
                and SFRSTCR_RSTS_CODE='RE'
                and substr(SFRSTCR_TERM_CODE,5,2) not in(90,81,82,83);

           Exception

              When Others then
                         l_error := 'SIN PERIODO' ||sqlerrm;

                 DBMS_OUTPUT.PUT_LINE('SIN PERIODO'||l_error);

           END;

          DBMS_OUTPUT.PUT_LINE(p_estatus);

          IF  p_estatus='EP' THEN


                BEGIN

                 SELECT DISTINCT COUNT (*)
                 INTO l_contar_SHRNCRS
                 FROM SHRNCRS
                 WHERE 1=1
                 --AND sgrcoop_pidm = FGET_PIDM ('010017225')
                 AND SHRNCRS_pidm = p_pidm
                 AND SHRNCRS_NCRQ_CODE='EQ'
                 and SHRNCRS_NCST_CODE='EP';

--                 l_error := 'EXITO';

                 DBMS_OUTPUT.PUT_LINE('CONTAR  1: '||l_contar_SHRNCRS);
                 Exception

                       When Others then
                                  l_error :='SIN CONTAR'||sqlerrm;

                          DBMS_OUTPUT.PUT_LINE('SIN CONTAR'||l_error);

                END;

               if l_contar_SHRNCRS=0 then

                  BEGIN
                      INSERT INTO SHRNCRS
                          VALUES
                       ( P_PIDM ,--SHRNCRS_PIDM
                        VL_SEQNO,--SHRNCRS_SEQ_NO
                        SYSDATE,--SHRNCRS_ACTIVITY_DATE
                        NULL,--SHRNCRS_QPNM_SEQ_NO
                        NULL,--SHRNCRS_COMT_CODE
                        NULL,--SHRNCRS_EVEN_CODE
                        null,--SHRNCRS_LEVL_CODE
                        'EQ',--SHRNCRS_NCRQ_CODE
                        'EP',--SHRNCRS_NCST_CODE
                        to_date(p_fecha_tramite,'dd/mm/yyyy'),--SHRNCRS_NCST_DATE
                        NULL,--SHRNCRS_ADVR_PIDM
                        NULL,--SHRNCRS_COMPLETE_DATE
                        NULL,--SHRNCRS_SURROGATE_ID
                        NULL,--SHRNCRS_VERSION
                        p_usuario,--SHRNCRS_USER_ID
                        p_usuario,--SHRNCRS_DATA_ORIGIN
                        NULL)--SHRNCRS_VPDI_CODE
                        ;
                      l_error := 'EXITO';

                      EXCEPTION
                          WHEN OTHERS THEN
                              l_error :=('NO INSERTO YA EXISTE REGISTRO EN EP'||sqlerrm);
                      END;

               ELSIF l_contar_SHRNCRS >= 1 THEN

                l_error :='NO INSERTO YA EXISTE REGISTRO EN EP';

               end if;

                BEGIN

                    select nvl(MAX(SGRCOOP_SEQ_NO)+1,1)
                     INTO VL_SEQNOCOOP
                    from SGRCOOP
                    where 1=1
                    AND SGRCOOP_pidm = p_pidm;

                Exception

                   When Others then
                              l_error := 'SIN SEQNO SGRCOOP' ||sqlerrm;

                      DBMS_OUTPUT.PUT_LINE('SIN SEQNO SGRCOOP'||l_error);

                END;

                BEGIN

                  SELECT DISTINCT COUNT (*)
                  INTO l_contar
                  FROM SGRCOOP
                  WHERE 1=1
                  AND sgrcoop_pidm = p_pidm
                  and SGRCOOP_COPC_CODE='EQ';

                  DBMS_OUTPUT.PUT_LINE('CONTAR  1: '||l_contar);

                Exception When Others then

                  l_error := sqlerrm;

                  DBMS_OUTPUT.PUT_LINE('SIN CONTAR'||l_error);

                END;

                 IF l_contar = 0 THEN

                       vl_fecha_ten:=(to_date(p_fecha_tramite,'dd/mm/yyyy'))+90;

                      BEGIN

                       INSERT INTO sgrcoop --(SGRCOOP_PIDM,SGRCOOP_TERM_CODE,SGRCOOP_LEVL_CODE,SGRCOOP_EMPL_CODE,SGRCOOP_COPC_CODE,SGRCOOP_END_DATE,SGRCOOP_BEGIN_DATE,SGRCOOP_INTEREST_IND,SGRCOOP_EMPL_CONTACT_NAME,SGRCOOP_EMPL_CONTACT_TITLE,SGRCOOP_ACTIVITY_DATE,SGRCOOP_PHONE_AREA,SGRCOOP_PHONE_NUMBER,SGRCOOP_PHONE_EXT,SGRCOOP_SEQ_NO,SGRCOOP_CRN,SGRCOOP_EVAL_PREPARED_DATE,SGRCOOP_EVAL_RECEIVED_DATE,SGRCOOP_OVERRIDE_IND,SGRCOOP_CTRY_CODE_PHONE,SGRCOOP_SURROGATE_ID,SGRCOOP_VERSION,SGRCOOP_USER_ID,SGRCOOP_DATA_ORIGIN,SGRCOOP_VPDI_CODE)
                       VALUES
                       (p_pidm,
                       VL_PERIODO,
                       VL_NIVEL,
                       null,
                       'EQ',
                       vl_fecha_ten,
                       to_date(p_fecha_tramite,'dd/mm/yyyy'),
                       NULL,
                       NULL,
                       'EQUIVALENCIA',
                       SYSDATE,
                       NULL,
                       NULL,
                       NULL,
                       VL_SEQNOCOOP,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       l_max_sgrcoop_surrogate_id,
                       NULL,
                       'SIU_EQUIVALENCIA',
                       p_usuario,
                       NULL);

                       l_error := 'EXITO';

                       DBMS_OUTPUT.PUT_LINE('Inserta SGRCOOP');

                      Exception When Others then

                      l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP '||sqlerrm;

                      DBMS_OUTPUT.PUT_LINE('ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP '||l_error);

                      END;

                 ELSIF l_contar >= 1 THEN

                 l_error :='NO INSERTO YA EXISTE REGISTRO EN EP';

                   DBMS_OUTPUT.PUT_LINE('ERROR: '|| 'ALUMNO CUENTA CON EQUIVALENCIA ');

                 END IF;


        ELSIF p_estatus='FI' THEN

                 BEGIN

                 SELECT DISTINCT COUNT (*)
                 INTO l_contar_SHRNCRS
                 FROM SHRNCRS
                 WHERE 1=1
                 AND SHRNCRS_pidm = p_pidm
                 AND SHRNCRS_NCRQ_CODE='EQ'
                 and SHRNCRS_NCST_CODE='FI';

                 DBMS_OUTPUT.PUT_LINE('CONTAR  1: '||l_contar_SHRNCRS);

                Exception When Others then

                 l_error := sqlerrm;

                  DBMS_OUTPUT.PUT_LINE('SIN CONTAR'||l_error);

                END;

                IF l_contar_SHRNCRS=0 THEN

                        BEGIN
                          UPDATE SHRNCRS
                          SET SHRNCRS_NCST_CODE=p_estatus,
                              SHRNCRS_NCST_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy'),
                              SHRNCRS_USER_ID=p_usuario
                          WHERE 1=1
                          AND SHRNCRS_PIDM = C.PIDM
                          AND SHRNCRS_NCRQ_CODE='EQ'
                          and SHRNCRS_NCST_CODE='EP';

                          COMMIT;

                         l_error := 'EXITO';

                        DBMS_OUTPUT.PUT_LINE('CONTAR  13: '||l_contar);

                        EXCEPTION WHEN OTHERS THEN
                           l_error :='Fallo Actualiza Estatus FI SHRNCRS'||sqlerrm;
                        END;

                ELSIF l_contar_SHRNCRS >=1 THEN

                l_error :='ALUMNO ESTA EN ESTATUS FINALIZADO';

                END IF;

                BEGIN

                  SELECT DISTINCT COUNT (*)
                  INTO l_contar
                  FROM SGRCOOP
                  WHERE 1=1
                  AND sgrcoop_pidm = p_pidm
                  and SGRCOOP_COPC_CODE='EQ'
                  and SGRCOOP_END_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy');

                  DBMS_OUTPUT.PUT_LINE('CONTAR  1: '||l_contar);

                Exception When Others then

                  l_error := sqlerrm;

                  DBMS_OUTPUT.PUT_LINE('SIN CONTAR'||l_error);

                END;

                if l_contar=0 then

                    BEGIN
                      UPDATE SGRCOOP
                      SET SGRCOOP_ACTIVITY_DATE=SYSDATE,
                          SGRCOOP_END_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy'),
                          SGRCOOP_DATA_ORIGIN=p_usuario
                      WHERE 1=1
                      AND SGRCOOP_PIDM = C.PIDM
                      AND SGRCOOP_COPC_CODE='EQ'
                      and SGRCOOP_END_DATE<>to_date(p_fecha_tramite,'dd/mm/yyyy');
                      COMMIT;

                     l_error := 'EXITO';
                      DBMS_OUTPUT.PUT_LINE('CONTAR  13.5: '||l_contar);
                    EXCEPTION

                        WHEN OTHERS THEN

                         l_error :='ALUMNO ESTA EN ESTATUS FINALIZADO';

                    END;

                 elsif l_contar>=1 then

                 l_error :='ALUMNO ESTA EN ESTATUS FINALIZADO';

                 end if;

        END IF;

     END LOOP;

   END;

COMMIT;

RETURN (l_error);

END;
--
--


FUNCTION f_inserta_rv (p_pidm NUMBER, p_usuario VARCHAR2,p_fecha_tramite varchar2,p_estatus VARCHAR2) RETURN VARCHAR2 -- V1.FER.23012025
      IS

l_contar NUMBER;
l_max_sgrcoop_surrogate_id NUMBER;
VL_NIVEL VARCHAR2(4);
VL_SEQNO number;
VL_SEQNOCOOP varchar(2);
vl_fecha_ten date;
VL_PERIODO VARCHAR2(6);
l_error VARCHAR2 (1000);
l_contar_SHRNCRS NUMBER;


BEGIN
--

    BEGIN

       SELECT (sgrcoop_surrogate_id_sequence.NEXTVAL)
       INTO l_max_sgrcoop_surrogate_id
       FROM dual
       WHERE 1=1;

     Exception When Others then

                   l_error := 'SIN REGISTRO SGRCOOP_SURROGATE'||sqlerrm;

       END;

      BEGIN
                SELECT NIVEL
                   INTO VL_NIVEL
                    FROM tztprog A
                WHERE 1=1
                AND a.pidm = p_pidm
                and TIPO_INGRESO='RV'
--                AND ESTATUS='MA'
                and a.TIPO_INGRESO IN (select ZSTPARA_PARAM_ID
                                     FROM ZSTPARA
                                     where 1=1
                                     AND ZSTPARA_MAPA_ID='ING_VALID')
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg);
                
       Exception When Others then

                   l_error := 'SIN REGISTRO'||sqlerrm;


       END;

   BEGIN
       FOR C IN (     SELECT *
                    FROM tztprog A
                WHERE 1=1
                AND a.pidm = p_pidm
--                and a.PROGRAMA=p_programa
                and a.TIPO_INGRESO='RV'
--                AND ESTATUS='MA'
                and a.TIPO_INGRESO IN (select ZSTPARA_PARAM_ID
                                     FROM ZSTPARA
                                     where 1=1
                                     AND ZSTPARA_MAPA_ID='ING_VALID')
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg)
              )

     LOOP

          BEGIN

                select nvl(MAX(SHRNCRS_SEQ_NO)+1,1)
                 INTO VL_SEQNO
                from SHRNCRS
                where 1=1
                AND SHRNCRS_pidm = p_pidm;
                
            
          Exception

              When Others then

                  VL_SEQNO:=1;


           END;
          
          
          BEGIN
            SELECT MAX(MATRICULACION)
               INTO VL_PERIODO
                FROM TZTPROG XX
                WHERE 1=1
                AND XX.PIDM = p_pidm
                and XX.SP = (SELECT MAX (XX1.SP)
                              FROM TZTPROG XX1
                              WHERE 1=1
                               AND XX1.PIDM = XX.PIDM) 
                ;

           Exception

              When Others then
                         l_error := 'SIN PERIODO' ||sqlerrm;

           END;           

         

          IF p_estatus='EP' THEN


                 BEGIN

                 SELECT DISTINCT COUNT (*)
                 INTO l_contar_SHRNCRS
                 FROM SHRNCRS
                 WHERE 1=1
                 --AND sgrcoop_pidm = FGET_PIDM ('010017225')
                 AND SHRNCRS_pidm = p_pidm
                 AND SHRNCRS_NCRQ_CODE='RV';

                 Exception

                       When Others then
                                  l_error := sqlerrm;

                END;

               if l_contar_SHRNCRS=0 then

                  BEGIN
                      INSERT INTO SHRNCRS
                          VALUES
                       ( P_PIDM ,--SHRNCRS_PIDM
                        VL_SEQNO,--SHRNCRS_SEQ_NO
                        sysdate,--SHRNCRS_ACTIVITY_DATE
                        null,--SHRNCRS_QPNM_SEQ_NO
                        NULL,--SHRNCRS_COMT_CODE
                        NULL,--SHRNCRS_EVEN_CODE
                        null,--SHRNCRS_LEVL_CODE
                        'RV',--SHRNCRS_NCRQ_CODE
                        'EP',--SHRNCRS_NCST_CODE
                        to_date(p_fecha_tramite,'dd/mm/yyyy'),--SHRNCRS_NCST_DATE
                        NULL,--SHRNCRS_ADVR_PIDM
                        NULL,--SHRNCRS_COMPLETE_DATE
                        NULL,--SHRNCRS_SURROGATE_ID
                        NULL,--SHRNCRS_VERSION
                        p_usuario,--SHRNCRS_USER_ID
                        p_usuario,--SHRNCRS_DATA_ORIGIN
                        NULL);--SHRNCRS_VPDI_CODE
                        
                     l_error := 'EXITO';
                  Exception
                         When Others then

                         l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SHRNCRS ' ||sqlerrm;


                    END;

               ELSIF l_contar_SHRNCRS>=1 then


                    l_error := 'YA EXISTE REGISTRO DE REVALIDACIÓN';

               END IF;


                      BEGIN

                                select nvl(MAX(SGRCOOP_SEQ_NO)+1,1)
                                 INTO VL_SEQNOCOOP
                                from SGRCOOP
                                where 1=1
                                AND SGRCOOP_pidm = p_pidm;

                      Exception

                              When Others then
                                         l_error := 'SIN SEQNO SGRCOOP' ||sqlerrm;


                      END;

                       BEGIN

                        SELECT DISTINCT COUNT (*)
                        INTO l_contar
                        FROM SGRCOOP
                        WHERE 1=1
                        --AND sgrcoop_pidm = FGET_PIDM ('010017225')
                        AND sgrcoop_pidm = p_pidm
--                        and SGRCOOP_COPC_CODE='EQ'
                        ;



                       END;

                    IF l_contar = 0 THEN

                          vl_fecha_ten:=(to_date(p_fecha_tramite,'dd/mm/yyyy'))+90;

                         BEGIN

                          INSERT INTO sgrcoop --(SGRCOOP_PIDM,SGRCOOP_TERM_CODE,SGRCOOP_LEVL_CODE,SGRCOOP_EMPL_CODE,SGRCOOP_COPC_CODE,SGRCOOP_END_DATE,SGRCOOP_BEGIN_DATE,SGRCOOP_INTEREST_IND,SGRCOOP_EMPL_CONTACT_NAME,SGRCOOP_EMPL_CONTACT_TITLE,SGRCOOP_ACTIVITY_DATE,SGRCOOP_PHONE_AREA,SGRCOOP_PHONE_NUMBER,SGRCOOP_PHONE_EXT,SGRCOOP_SEQ_NO,SGRCOOP_CRN,SGRCOOP_EVAL_PREPARED_DATE,SGRCOOP_EVAL_RECEIVED_DATE,SGRCOOP_OVERRIDE_IND,SGRCOOP_CTRY_CODE_PHONE,SGRCOOP_SURROGATE_ID,SGRCOOP_VERSION,SGRCOOP_USER_ID,SGRCOOP_DATA_ORIGIN,SGRCOOP_VPDI_CODE)
                          VALUES
                          (p_pidm,
                          VL_PERIODO,
                          VL_NIVEL,
                          null,
                          'RV',
                          vl_fecha_ten,
                          to_date(p_fecha_tramite,'dd/mm/yyyy'),
                          NULL,
                          NULL,
                          'REVALIDACION',
                          SYSDATE,
                          NULL,
                          NULL,
                          NULL,
                          VL_SEQNOCOOP,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          l_max_sgrcoop_surrogate_id,
                          NULL,
                          'SIU_REVALIDACION',
                          p_usuario,
                          NULL);

                          l_error :='EXITO';
                         Exception
                         When Others then
                         l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP ' ||sqlerrm;


                         END;

                    ELSIF l_contar >=1 THEN

                      l_error :='ALUMNO YA CUENTA CON EQUIVALENCIA EN PROCESO ';

                      END IF;


        ELSIF p_estatus='FI' THEN

                        BEGIN
                          UPDATE SHRNCRS
                          SET SHRNCRS_NCST_CODE = 'FI',
                              SHRNCRS_NCST_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy'),
                              SHRNCRS_USER_ID=p_usuario
                          WHERE 1=1
                          AND SHRNCRS_PIDM = C.PIDM
                          AND SHRNCRS_NCRQ_CODE='RV'
                          and SHRNCRS_NCST_CODE='EP';
                          COMMIT;
                         l_error := 'EXITO';


                        EXCEPTION
                            WHEN OTHERS THEN
                         l_error :='ALUMNO ESTA EN ESTATUS FINALIZADO';
                        END;

                        BEGIN
                          UPDATE SGRCOOP
                          SET SGRCOOP_ACTIVITY_DATE=SYSDATE,
                              SGRCOOP_END_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy'),
                              SGRCOOP_DATA_ORIGIN=p_usuario
                          WHERE 1=1
                          AND SGRCOOP_PIDM = C.PIDM
                          AND SGRCOOP_COPC_CODE='RV';
                          COMMIT;
                         l_error := 'EXITO';

                        EXCEPTION
                            WHEN OTHERS THEN
                             l_error :='ALUMNO ESTA EN ESTATUS FINALIZADO';
                        END;
        end if;

     END LOOP;

   END;

COMMIT;

RETURN (l_error);

END;

--
--
FUNCTION f_inserta_rv_masivo(p_pidm NUMBER, p_usuario VARCHAR2,p_fecha_tramite varchar2,p_estatus VARCHAR2) RETURN VARCHAR2 -- V1.FER.23012025
      IS

l_contar NUMBER;
l_max_sgrcoop_surrogate_id NUMBER;
VL_NIVEL VARCHAR2(4);
VL_SEQNO number;
VL_SEQNOCOOP varchar(2);
vl_fecha_ten date;
VL_PERIODO VARCHAR2(6);
l_error VARCHAR2 (1000);
l_contar_SHRNCRS number;


BEGIN
--

    BEGIN

       SELECT (sgrcoop_surrogate_id_sequence.NEXTVAL)
       INTO l_max_sgrcoop_surrogate_id
       FROM dual
       WHERE 1=1;


    END;

      BEGIN
                SELECT NIVEL
                   INTO VL_NIVEL
                    FROM tztprog A
                WHERE 1=1
                AND a.pidm = p_pidm
                and TIPO_INGRESO='RV'
                AND ESTATUS in ('MA', 'BT', 'EG', 'BI')
                and a.TIPO_INGRESO IN (select ZSTPARA_PARAM_ID
                                     FROM ZSTPARA
                                     where 1=1
                                     AND ZSTPARA_MAPA_ID='ING_VALID')
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg);

    END;

   BEGIN
       FOR C IN (     SELECT *
                    FROM tztprog A
                WHERE 1=1
                AND a.pidm = p_pidm
--                and a.PROGRAMA=p_programa
                and TIPO_INGRESO='RV'
--                AND ESTATUS='MA'
                and a.TIPO_INGRESO IN (select ZSTPARA_PARAM_ID
                                     FROM ZSTPARA
                                     where 1=1
                                     AND ZSTPARA_MAPA_ID='ING_VALID')
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg)
              )

     LOOP

          BEGIN

                select nvl(MAX(SHRNCRS_SEQ_NO)+1,1)
                 INTO VL_SEQNO
                from SHRNCRS
                where 1=1
                AND SHRNCRS_pidm = p_pidm;

          Exception

              When Others then

                  VL_SEQNO:=1||sqlerrm;


           END;

          BEGIN
            SELECT MAX(MATRICULACION)
               INTO VL_PERIODO
                FROM TZTPROG XX
                WHERE 1=1
                AND XX.PIDM = p_pidm
                and XX.SP = (SELECT MAX (XX1.SP)
                              FROM TZTPROG XX1
                              WHERE 1=1
                               AND XX1.PIDM = XX.PIDM) 
                ;

           Exception

              When Others then
                         l_error := 'SIN PERIODO' ||sqlerrm;

           END;


          IF  p_estatus='EP' THEN


                BEGIN

                 SELECT DISTINCT COUNT (*)
                 INTO l_contar_SHRNCRS
                 FROM SHRNCRS
                 WHERE 1=1
                 --AND sgrcoop_pidm = FGET_PIDM ('010017225')
                 AND SHRNCRS_pidm = p_pidm
                 AND SHRNCRS_NCRQ_CODE='RV'
                 and SHRNCRS_NCST_CODE='EP';


                 Exception

                       When Others then
                                  l_error :='SIN CONTAR'||sqlerrm;

                END;

               if l_contar_SHRNCRS=0 then

                  BEGIN
                      INSERT INTO SHRNCRS
                          VALUES
                       ( P_PIDM ,--SHRNCRS_PIDM
                        VL_SEQNO,--SHRNCRS_SEQ_NO
                        SYSDATE,--SHRNCRS_ACTIVITY_DATE
                        NULL,--SHRNCRS_QPNM_SEQ_NO
                        NULL,--SHRNCRS_COMT_CODE
                        NULL,--SHRNCRS_EVEN_CODE
                        null,--SHRNCRS_LEVL_CODE
                        'RV',--SHRNCRS_NCRQ_CODE
                        'EP',--SHRNCRS_NCST_CODE
                        to_date(p_fecha_tramite,'dd/mm/yyyy'),--SHRNCRS_NCST_DATE
                        NULL,--SHRNCRS_ADVR_PIDM
                        NULL,--SHRNCRS_COMPLETE_DATE
                        NULL,--SHRNCRS_SURROGATE_ID
                        NULL,--SHRNCRS_VERSION
                        p_usuario,--SHRNCRS_USER_ID
                        p_usuario,--SHRNCRS_DATA_ORIGIN
                        NULL)--SHRNCRS_VPDI_CODE
                        ;
                      l_error := 'EXITO';

                      EXCEPTION
                          WHEN OTHERS THEN
                              l_error :=('NO INSERTO YA EXISTE REGISTRO EN EP'||sqlerrm);
                      END;

               ELSIF l_contar_SHRNCRS >= 1 THEN

                l_error :='NO INSERTO YA EXISTE REGISTRO EN EP';

               end if;

                BEGIN

                    select nvl(MAX(SGRCOOP_SEQ_NO)+1,1)
                     INTO VL_SEQNOCOOP
                    from SGRCOOP
                    where 1=1
                    AND SGRCOOP_pidm = p_pidm;

                Exception

                   When Others then
                              l_error := 'SIN SEQNO SGRCOOP' ||sqlerrm;


                END;

                BEGIN

                  SELECT DISTINCT COUNT (*)
                  INTO l_contar
                  FROM SGRCOOP
                  WHERE 1=1
                  AND sgrcoop_pidm = p_pidm
--                  and SGRCOOP_COPC_CODE='EQ'
                  ;


                Exception When Others then

                  l_error := sqlerrm;


                END;

                 IF l_contar = 0 THEN

                       vl_fecha_ten:=(to_date(p_fecha_tramite,'dd/mm/yyyy'))+90;

                      BEGIN

                       INSERT INTO sgrcoop --(SGRCOOP_PIDM,SGRCOOP_TERM_CODE,SGRCOOP_LEVL_CODE,SGRCOOP_EMPL_CODE,SGRCOOP_COPC_CODE,SGRCOOP_END_DATE,SGRCOOP_BEGIN_DATE,SGRCOOP_INTEREST_IND,SGRCOOP_EMPL_CONTACT_NAME,SGRCOOP_EMPL_CONTACT_TITLE,SGRCOOP_ACTIVITY_DATE,SGRCOOP_PHONE_AREA,SGRCOOP_PHONE_NUMBER,SGRCOOP_PHONE_EXT,SGRCOOP_SEQ_NO,SGRCOOP_CRN,SGRCOOP_EVAL_PREPARED_DATE,SGRCOOP_EVAL_RECEIVED_DATE,SGRCOOP_OVERRIDE_IND,SGRCOOP_CTRY_CODE_PHONE,SGRCOOP_SURROGATE_ID,SGRCOOP_VERSION,SGRCOOP_USER_ID,SGRCOOP_DATA_ORIGIN,SGRCOOP_VPDI_CODE)
                       VALUES
                       (p_pidm,
                       VL_PERIODO,
                       VL_NIVEL,
                       null,
                       'RV',
                       vl_fecha_ten,
                       to_date(p_fecha_tramite,'dd/mm/yyyy'),
                       NULL,
                       NULL,
                       'REVALIDACION',
                       SYSDATE,
                       NULL,
                       NULL,
                       NULL,
                       VL_SEQNOCOOP,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       l_max_sgrcoop_surrogate_id,
                       NULL,
                       'SIU_REVALIDACION',
                       p_usuario,
                       NULL);

                       l_error := 'EXITO';

                      Exception When Others then

                      l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP '||sqlerrm;


                      END;

                 ELSIF l_contar >= 1 THEN

                 l_error :='NO INSERTO YA EXISTE REGISTRO EN EP';


                 END IF;


        ELSIF p_estatus='FI' THEN

                 BEGIN

                 SELECT DISTINCT COUNT (*)
                 INTO l_contar_SHRNCRS
                 FROM SHRNCRS
                 WHERE 1=1
                 AND SHRNCRS_pidm = p_pidm
                 AND SHRNCRS_NCRQ_CODE='RV'
                 and SHRNCRS_NCST_CODE='FI';

                Exception When Others then

                 l_error := sqlerrm;


                END;

                IF l_contar_SHRNCRS=0 THEN

                        BEGIN
                          UPDATE SHRNCRS
                          SET SHRNCRS_NCST_CODE=p_estatus,
                              SHRNCRS_NCST_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy'),
                              SHRNCRS_USER_ID=p_usuario
                          WHERE 1=1
                          AND SHRNCRS_PIDM = C.PIDM
                          AND SHRNCRS_NCRQ_CODE='RV'
                          and SHRNCRS_NCST_CODE='EP';

                          COMMIT;

                         l_error := 'EXITO';


                        EXCEPTION WHEN OTHERS THEN
                           l_error :='Fallo Actualiza Estatus FI SHRNCRS'||sqlerrm;
                        END;

                ELSIF l_contar_SHRNCRS >=1 THEN

                l_error :='ALUMNO ESTA EN ESTATUS FINALIZADO';

                END IF;

                BEGIN

                  SELECT DISTINCT COUNT (*)
                  INTO l_contar
                  FROM SGRCOOP
                  WHERE 1=1
                  AND sgrcoop_pidm = p_pidm
                  and SGRCOOP_COPC_CODE='RV'
                  and SGRCOOP_END_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy');

                Exception When Others then

                  l_error := sqlerrm;


                END;

                if l_contar=0 then

                    BEGIN
                      UPDATE SGRCOOP
                      SET SGRCOOP_ACTIVITY_DATE=SYSDATE,
                          SGRCOOP_END_DATE=to_date(p_fecha_tramite,'dd/mm/yyyy'),
                          SGRCOOP_DATA_ORIGIN=p_usuario
                      WHERE 1=1
                      AND SGRCOOP_PIDM = C.PIDM
                      AND SGRCOOP_COPC_CODE='RV'
                      and SGRCOOP_END_DATE<>to_date(p_fecha_tramite,'dd/mm/yyyy');
                      COMMIT;

                     l_error := 'EXITO';

                    EXCEPTION

                        WHEN OTHERS THEN

                         l_error :='ALUMNO ESTA EN ESTATUS FINALIZADO';

                    END;

                 elsif l_contar>=1 then

                 l_error :='ALUMNO ESTA EN ESTATUS FINALIZADO';

                 end if;

        END IF;

     END LOOP;

   END;

COMMIT;

RETURN (l_error);

END;
--
--
   FUNCTION f_dato_grls_rv (p_pidm in number,p_programa varchar2) RETURN PKG_EQUIVALENCIA.cursor_out_dato_grls_rv   -- V1 FER 27012025
           AS
                c_out_dato_grls_rv PKG_EQUIVALENCIA.cursor_out_dato_grls_rv;

  BEGIN
       open c_out_dato_grls_rv
         FOR
SELECT DISTINCT
                    spriden_id ID,
                    spriden_first_name||' '||replace(spriden_last_name,'/',' ') NOMBRE_ALUMNO,
                    (SELECT goremal_email_address
                    FROM goremal
                    WHERE
                    1=1
                    AND a.pidm = goremal_pidm
                    AND goremal_emal_code = 'PRIN'
                    AND GOREMAL_PREFERRED_IND = 'Y') CORREO,
                    (SELECT sztdtec_programa_comp
                    FROM sztdtec
                    WHERE 1=1
                    AND a.programa = sztdtec_program
                    AND a.ctlg = sztdtec_term_code
                    and rownum = 1) DESCRIP_PROGRA,
                    nvl((select DECODE(max(SARCHKL_CKST_CODE),
                                  'VALIDADO','OK_ACNO')
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACNO')
                         and SARCHKL_PIDM =a.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_TERM_CODE_ENTRY = SARCHKL_TERM_CODE_ENTRY
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO),'sin información')Acta_de_nacimiento,
                    nvl((select DECODE(max(SARCHKL_CKST_CODE),
                                 'VALIDADO','OK_CTBO')
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBO')
                         and SARCHKL_PIDM =a.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_TERM_CODE_ENTRY = SARCHKL_TERM_CODE_ENTRY
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'sin información')Certificado_de_Bachillerato,
                      nvl((select DECODE (max(SARCHKL_CKST_CODE),
                                     'VALIDADO','OK_ACSO')
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACSO')
                         and SARCHKL_PIDM =a.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_TERM_CODE_ENTRY = SARCHKL_TERM_CODE_ENTRY
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'sin información') ANTECEDENTE_CERT,
--                    nvl((select decode(max(SARCHKL_CKST_CODE),
--                                    'VALIDADO','OK_CPLO')
--                        from SARCHKL ,SARAPPD
--                        where SARCHKL_ADMR_CODE in ('CPLO')
--                         and SARCHKL_PIDM =a.pidm
--                        AND SARAPPD_PIDM = SARCHKL_PIDM
--                        AND SARAPPD_TERM_CODE_ENTRY = SARCHKL_TERM_CODE_ENTRY
--                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'sin información')Certificado_parcial_de_Lic ,
                    NVL((SELECT
                           CASE WHEN B.TBRACCD_BALANCE=0 THEN
                                    'PAGADO'
                                WHEN  B.TBRACCD_BALANCE=B.TBRACCD_AMOUNT THEN
                                     'NO PAGADO'
                                WHEN  B.TBRACCD_BALANCE>0 AND B.TBRACCD_BALANCE< B.TBRACCD_AMOUNT THEN
                                     'PAGO PARCIAL'
                              END PAGO
                          FROM SPRIDEN a, TBRACCD b
                          WHERE a.SPRIDEN_CHANGE_IND IS NULL
                               AND a.SPRIDEN_PIDM = b.TBRACCD_PIDM
                               AND a.spriden_pidm=a.pidm
                               AND SUBSTR(b.TBRACCD_DETAIL_CODE,3,2)='BO'
                               and b.TBRACCD_TRAN_NUMBER  IN (select a.TBRAPPL_CHG_TRAN_NUMBER
                                                                from TBRAPPL a
                                                                Where b.tbraccd_pidm = a.TBRAPPL_pidm
                                                                  And a.TBRAPPL_PAY_TRAN_NUMBER  in (select x1.TBRACCD_TRAN_NUMBER
                                                                                                                from tbraccd  x1, TZTNCD
                                                                                                                where a.TBRAPPL_pidm = x1.tbraccd_pidm
                                                                                                                And tbraccd_detail_code =  TZTNCD_CODE
                                                                                                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                                                                    )
                                                             )
                         UNION
                         SELECT DISTINCT
                                CASE WHEN B.TBRACCD_BALANCE=0 THEN
                                    'NOTAS DE CREDITO'
                                WHEN  B.TBRACCD_BALANCE=B.TBRACCD_AMOUNT THEN
                                     'NO PAGADO'
                                WHEN  B.TBRACCD_BALANCE>0 AND B.TBRACCD_BALANCE< B.TBRACCD_AMOUNT THEN
                                     'PAGO PARCIAL'
                              END PAGO
                             FROM SPRIDEN a, TBRACCD b
                          WHERE a.SPRIDEN_CHANGE_IND IS NULL
                               AND a.SPRIDEN_PIDM = b.TBRACCD_PIDM
                               AND a.spriden_pidm=a.pidm
                               AND SUBSTR(b.TBRACCD_DETAIL_CODE,3,2)='BO'
                               and b.TBRACCD_TRAN_NUMBER  NOT IN (select a.TBRAPPL_CHG_TRAN_NUMBER
                                                                from TBRAPPL a
                                                                Where b.tbraccd_pidm = a.TBRAPPL_pidm
                                                                  And a.TBRAPPL_PAY_TRAN_NUMBER  in (select x1.TBRACCD_TRAN_NUMBER
                                                                                                                from tbraccd  x1, TZTNCD
                                                                                                                where a.TBRAPPL_pidm = x1.tbraccd_pidm
                                                                                                                And tbraccd_detail_code =  TZTNCD_CODE
                                                                                                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                                                                    )
                                                     )),'sin información')pago,
                    (SELECT nvl(SHRNCRS_NCST_CODE,'IN')
                         FROM SHRNCRS
                         WHERE 1=1
                         AND SHRNCRS_PIDM=a.pidm
                         AND SHRNCRS_NCRQ_CODE='RV')ESTATUS,
                        SGRCOOP_END_DATE FECHA_INIC,
                        SGRCOOP_BEGIN_DATE FECHA_FIN,
                        SGRCOOP_TERM_CODE periodo
                FROM tztprog A, spriden,sgrcoop
                WHERE 1=1
                AND a.pidm = spriden_pidm
                AND a.matricula = spriden_id
                AND A.PIDM=SGRCOOP_PIDM(+)
                AND a.TIPO_INGRESO=SGRCOOP_COPC_CODE(+)
                AND spriden_change_ind IS NULL
                AND a.pidm = p_pidm --FGET_PIDM ('010017225')-- 
                and a.PROGRAMA=  p_programa
                and a.TIPO_INGRESO IN (select ZSTPARA_PARAM_ID
                                     FROM ZSTPARA
                                     where 1=1
                                     AND ZSTPARA_MAPA_ID='ING_VALID')
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg);
                                   
       RETURN (c_out_dato_grls_rv);

  END;
--
--

   FUNCTION f_estatus_rv (p_pidm in number,p_programa varchar2) RETURN PKG_EQUIVALENCIA.cursor_out_estatus_rv   -- V1 FER 13022025
           AS
                c_out_estatus_rv PKG_EQUIVALENCIA.cursor_out_estatus_rv;

  BEGIN
       open c_out_estatus_rv
         FOR
            SELECT TIPO_INGRESO ingreso
            FROM TZTPROG A
            WHERE 1=1
            and a.PIDM = p_pidm--'010422869'
            and a.programa = p_programa
--            and a.TIPO_INGRESO = 'RV'
            and a.ESTATUS in ('MA', 'EG', 'BT', 'BI')
            and a.sp = (select max (a1.sp)
                         from TZTPROG a1
                         where 1=1
                         and a1.pidm = a.pidm 
                         and a1.programa = a.programa);
                                               
                   RETURN (c_out_estatus_rv);

  END;
--
END PKG_EQUIVALENCIA;
--
/

DROP PUBLIC SYNONYM PKG_EQUIVALENCIA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_EQUIVALENCIA FOR BANINST1.PKG_EQUIVALENCIA;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_EQUIVALENCIA TO PUBLIC;
