DROP PACKAGE BODY BANINST1.PKG_UTLX;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_UTLX
 IS

 FUNCTION f_gztpasx_out RETURN PKG_UTLX.cursor_gztpasx_out
 AS
 goztpasx_out PKG_UTLX.cursor_gztpasx_out;

 BEGIN

 BEGIN

 OPEN goztpasx_out FOR

 SELECT DISTINCT GZTPASX_PIDM,
 GZTPASX_ID,
 GZTPASX_PIN,
 GZTPASX_PIN_DISABLED_IND,
 GZTPASX_STAT_IND,
 Null servidor,
 A.GOREMAL_EMAIL_ADDRESS,
 REPLACE(SPRIDEN_LAST_NAME,'/',' ') Apellido,
 SPRIDEN_FIRST_NAME Nombre
 FROM GZTPASX, GOREMAL A, SPRIDEN
 WHERE 1=1
 AND GZTPASX_PIDM = SPRIDEN_PIDM
 AND GZTPASX_PIDM = A.GOREMAL_PIDM
 And a.GOREMAL_STATUS_IND = 'A'
 AND SPRIDEN_CHANGE_IND IS NULL
 AND GZTPASX_PIN_DISABLED_IND = 'A'
 AND GZTPASX_STAT_IND = 1
 AND A.GOREMAL_EMAL_CODE = NVL ('PRIN', A.GOREMAL_EMAL_CODE)
 AND A.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
 FROM GOREMAL A1
 WHERE A.GOREMAL_PIDM = A1.GOREMAL_PIDM
 AND A.GOREMAL_EMAL_CODE = A1.GOREMAL_EMAL_CODE)
 ORDER BY GZTPASX_PIDM ASC;
 END;
 RETURN(goztpasx_out);


 END f_gztpasx_out;


 FUNCTION f_gztpasx_update(p_pidm in number, p_stat_ind in varchar2, p_error_desc in Varchar2, p_error_code in Varchar2) Return Varchar2
 AS
 vl_error varchar2(250):='EXITO';
 vl_aux varchar2(1);
 vl_maximo number;

 ----- Este procedimiento realiza la actualizcion de los estatus en la tabla de Banner y MySql
 ----- Se realiza modificacion para version final 30-May- 2017 ------
 ----- Preguntar antes de modificar -----
 BEGIN ----- vmrl -----

 IF p_stat_ind ='2' THEN

 begin
 Select nvl (max (SZTMEBI_SEQ_NO), 0 ) +1
 Into vl_maximo
 from SZTMEBI
 Where SZTMEBI_PIDM = p_pidm
 AND SZTMEBI_CTGY_ID = 'User_pass_UTLX';
 Exception
 When Others then
 vl_maximo :=1;
 End;

 dbms_output.put_line('trae el m·ximo seqno '||vl_maximo||'pidm '||p_pidm);

 begin

 insert into sztmebi
 values('00000',
 p_stat_ind,
 p_error_code,
 p_error_desc,
 vl_maximo,
 sysdate,
 user,
 'User_pass_UTLX',
 p_pidm);

 Exception when others then
 vl_error := 'Error al insertar en SZTMEBI '||sqlerrm;
 end;

 --dbms_output.put_line('salida en sztmebi a='||vl_error);

 begin

 update gztpasx set gztpasx_stat_ind = p_stat_ind
 where gztpasx_pidm= p_pidm;


 Exception when others then
 vl_error := 'Error al actualizar gztpasx con stat_ind = 2 '||sqlerrm;
 end;

 -- dbms_output.put_line('actualiza estatus 6= ' ||vl_error);


 ELSIF p_stat_ind ='1' THEN

 begin
 update gztpasx set gztpasx_stat_ind= '0'
 where gztpasx_pidm = p_pidm;
 exception when others then
 vl_error:= 'Error al actualizar gztpasx con stat_ind 0 '||sqlerrm;
 end;

 --dbms_output.put_line('actualizÛ a:'|| p_pidm||'con: '||p_stat_ind);

 ELSIF p_stat_ind = '3' THEN

 begin

 update gztpasx set gztpasx_pin_disabled_ind = Null, gztpasx_stat_ind = 0
 where gztpasx_pidm = p_pidm;
 exception when others then
 vl_error:= 'Error al actualizar gztpasx con stat_ind 3 '||sqlerrm;

 end;
 --dbms_output.put_line('actualizÛ a:'|| p_pidm||'con: '||p_stat_ind);
 END IF;

 If vl_error = 'EXITO' then
 commit;
 Else
 rollback;
 End if;
 Return vl_error;

 END f_gztpasx_update;



FUNCTION f_registros_out  RETURN PKG_UTLX.cursor_out
 /*CURSOR CREADO PARA SINCRONIZAR A LOS ALUMNOS CON EL BENEFECIO DE UTLX*/
 AS registros_out PKG_UTLX.cursor_out;
 BEGIN
 OPEN registros_out FOR
 SELECT SPRIDEN_PIDM PIDM,
 SPRIDEN_ID Matricula,
 REPLACE(TRANSLATE (SPRIDEN.SPRIDEN_LAST_NAME,'·ÈÌÛ˙¡…Õ”⁄','aeiouAEIOU'),'/',' ')Apellido,
 SPRIDEN_FIRST_NAME Nombre,
 /*
 CASE WHEN a.SZTUTLX_DISABLE_IND = 'I' THEN
 'Bloc'||substr(SPRIDEN_ID,1,2)||GOREMAL_EMAIL_ADDRESS
 WHEN a.SZTUTLX_DISABLE_IND != 'I' THEN
 GOREMAL_EMAIL_ADDRESS
 END email,
 CASE WHEN a.SZTUTLX_DISABLE_IND = 'I' THEN
 'Bloc'||substr(SPRIDEN_ID,1,2)||GZTPASS_PIN
 WHEN a.SZTUTLX_DISABLE_IND != 'I' THEN
 GZTPASS_PIN
 END ContraseÒa,
 */
 GOREMAL_EMAIL_ADDRESS email,
 GZTPASS_PIN ContraseÒa, 
 a.SZTUTLX_DISABLE_IND Identificador,
 a.SZTUTLX_SEQ_NO Seq_no
 FROM SPRIDEN, GOREMAL, SZTUTLX a, GZTPASS
 WHERE 1=1
 AND SPRIDEN_PIDM = GOREMAL_PIDM
 AND SZTUTLX_PIDM = GZTPASS_PIDM
 AND SPRIDEN_PIDM = GZTPASS_PIDM
 AND GOREMAL_EMAL_CODE = NVL ('PRIN', GOREMAL_EMAL_CODE)
 And GOREMAL_STATUS_IND = 'A'
 AND SPRIDEN_CHANGE_IND IS NULL
 AND a.SZTUTLX_STAT_IND = 0
 AND a.SZTUTLX_DISABLE_IND IN ('I','A')
 AND a.SZTUTLX_SEQ_NO = (SELECT MAX(SZTUTLX_SEQ_NO)
 FROM SZTUTLX b
 WHERE 1=1
 AND b.SZTUTLX_PIDM = a.SZTUTLX_PIDM);
 --AND SPRIDEN_ID = '010042009';

 RETURN(registros_out);
 END f_registros_out;


 FUNCTION f_actualiza(p_pidm in number, p_seqno in number,p_stat_ind in number, p_obs in varchar2, p_mdl_id in number) RETURN VARCHAR2
 AS

 vl_msje VARCHAR2(250);
 vl_seq_no NUMBER:=0;

 BEGIN

 IF p_stat_ind = 1 THEN
 BEGIN
 FOR c in (
 SELECT SZTUTLX_PIDM, SZTUTLX_SEQ_NO
 FROM SZTUTLX
 WHERE 1=1
 AND SZTUTLX_PIDM = p_pidm
 AND SZTUTLX_SEQ_NO = p_seqno
 )

 LOOP
 UPDATE SZTUTLX
 SET SZTUTLX_STAT_IND = p_stat_ind,
 SZTUTLX_OBS = p_obs,
 SZTUTLX_MDL_ID = p_mdl_id,
 SZTUTLX_USER_UPDATE = user,
 SZTUTLX_DATE_UPDATE = sysdate
 WHERE 1=1
 AND SZTUTLX_PIDM = c.SZTUTLX_PIDM
                                AND SZTUTLX_SEQ_NO = c.SZTUTLX_SEQ_NO;
                                vl_msje:='Registro actalizzado: '||c.SZTUTLX_PIDM||'-'||c.SZTUTLX_SEQ_NO;
                               END LOOP;
                               EXCEPTION
                               WHEN OTHERS THEN
                               vl_msje:='Error al actualizar'||sqlerrm;
                            END;
                            COMMIT;

                      ELSIF p_stat_ind=2  THEN

                        BEGIN
                            SELECT NVL(MAX(SZTMEBI_SEQ_NO),0)+1
                            INTO vl_seq_no
                            FROM SZTMEBI
                            WHERE 1=1
                            AND SZTMEBI_PIDM = p_pidm
                            AND SZTMEBI_CTGY_ID = 'UTLX';
                            EXCEPTION WHEN OTHERS THEN
                            vl_seq_no:=1;

                        END;

                       BEGIN
                        INSERT INTO SZTMEBI
                        VALUES('000000',
                               p_stat_ind,
                               p_stat_ind,
                               p_obs,
                               vl_seq_no,
                               SYSDATE,
                               USER,
                               'UTLX',
                               p_pidm);
                        END;


                        BEGIN
                            UPDATE SZTUTLX SET SZTUTLX_STAT_IND = p_stat_ind, SZTUTLX_OBS = p_obs, SZTUTLX_USER_UPDATE = user,SZTUTLX_DATE_UPDATE = sysdate
                            WHERE 1=1
                            AND SZTUTLX_PIDM = p_pidm
                            AND SZTUTLX_SEQ_NO = p_seqno;
                        END;
                      END IF;
                     COMMIT;
               return vl_msje;
               END f_actualiza;


FUNCTION f_inserta_utlx (p_pidm in number, p_matricula in varchar2, p_numero_meses in number, p_descuento in varchar2, p_gratis in number default null
                                 , P_FRECUENCIA_PAGO VARCHAR2 DEFAULT NULL, 
                                 P_MONTO_DESC   number DEFAULT NULL ,
                                 P_NUM_DESC      number DEFAULT NULL ,
                                 P_NUM_DESC_APLIC  number DEFAULT NULL ) RETURN VARCHAR2
                   AS
-- se agragan nuevos parametros proy de retencion utlx glovicx 27072023

                 vl_msje VARCHAR2(250):='EXITO';
                 vl_utlx_seqno NUMBER:=0;
                 vl_password VARCHAR2(250);
                 vl_bandera NUMBER;

/*
se agrega validaciÛn para que no inserte m·s de una vez el alumno en la tabla glovicx 27.01.2023
*/
v_valida       varchar2(1):= 'N';
  
 BEGIN
      
         begin
                SELECT distinct  'Y'  as encontro
                    into v_valida
                       FROM SZTUTLX
                            WHERE 1=1
                            and SZTUTLX_STAT_IND > 0
                            and SZTUTLX_DISABLE_IND in ('A','I')
                            AND SZTUTLX_PIDM = p_pidm;

         exception when others then
         v_valida := 'N';

          end;

  IF v_valida = 'Y'  THEN
            ------- YA EXISTE Y NO DEBE HACER EL INSERT REGA FERNANDO 27.01.2023
     NULL;
     --insert into twpasow (valor1, valor2, valor3  )
    -- values  ( 'inserta utelx mediante job', p_pidm, p_gratis );
    -- commit;
     
  ELSE

                    BEGIN
                    SELECT NVL(MAX(SZTUTLX_SEQ_NO),0)+1
                    into vl_utlx_seqno
                    FROM SZTUTLX
                    WHERE 1=1
                    AND SZTUTLX_PIDM = p_pidm;
                    EXCEPTION
                    WHEN OTHERS THEN
                    vl_utlx_seqno:=1;
                    END;


                   BEGIN
                    SELECT GOZTPAC_PIN
                    INTO vl_password
                    FROM GOZTPAC
                    WHERE GOZTPAC_PIDM =p_pidm;
                   Exception
                   when no_data_found then
                   vl_bandera:=0;
                   END;

          BEGIN

          FOR c IN(SELECT a.SORLCUR_PIDM pidm, a.SORLCUR_TERM_CODE term_code, a.SORLCUR_CAMP_CODE campus, a.SORLCUR_LEVL_CODE nivel
                                    FROM SORLCUR a
                                    WHERE 1=1
                                    --AND a.SORLCUR_ROLL_IND ='Y'
                                    --AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                    AND a.SORLCUR_SEQNO = (SELECT MAX(SORLCUR_SEQNO)
                                                             FROM SORLCUR b
                                                             WHERE 1=1
                                                             AND a.SORLCUR_PIDM = b.SORLCUR_PIDM)
                                    AND SORLCUR_PIDM = p_pidm

            )LOOP
            INSERT INTO SZTUTLX (SZTUTLX_PIDM,
            SZTUTLX_ID,
            SZTUTLX_TERM_CODE,
            SZTUTLX_CAMP_CODE,
            SZTUTLX_LEVL_CODE,
            SZTUTLX_SEQ_NO,
            SZTUTLX_STAT_IND,
            SZTUTLX_OBS,
            SZTUTLX_DISABLE_IND,
            SZTUTLX_PWD,
            SZTUTLX_MDL_ID,
            SZTUTLX_USER_INSERT,
            SZTUTLX_ACTIVITY_DATE,
            SZTUTLX_USER_UPDATE,
            SZTUTLX_DATE_UPDATE,
            SZTUTLX_ROW1,
            SZTUTLX_ROW2,
            SZTUTLX_ROW3,
            SZTUTLX_ROW4,
            SZTUTLX_ROW5,
            SZTUTLX_USER_BLOQUEO,
            SZTUTLX_ACTIVITY_BLOQUEO,
            SZTUTLX_GRATIS,
            SZTUTLX_GRATIS_APLI,
            SZTUTLX_FREC_PAGO,
            SZTUTLX_MONTO_DESC,
            SZTUTLX_NUM_DESC,
            SZTUTLX_NUM_DESC_APLIC)
            VALUES(c.pidm,--SZTUTLX_PIDM
               p_matricula, --SZTUTLX_ID
               c.term_code,--SZTUTLX_TERM_CODE
               c.campus,--SZTUTLX_CAMP_CODE
               c.nivel,--SZTUTLX_LEVL_CODE
               vl_utlx_seqno,--SZTUTLX_SEQ_NO
               0,--SZTUTLX_STAT_IND
               Null,--SZTUTLX_OBS
               'A',--SZTUTLX_DISABLE_IND
               vl_password,--SZTUTLX_PWD
               Null,--SZTUTLX_MDL_ID
               USER,--SZTUTLX_USER_INSERT
               SYSDATE,--SZTUTLX_ACTIVITY_DATE
               Null,--SZTUTLX_DATE_UPDATE
               Null,--SZTUTLX_USER_UPDATE
               sysdate,--SZTUTLX_ROW1
               p_numero_meses,--SZTUTLX_ROW2
               p_descuento,--SZTUTLX_ROW3
               Null,--SZTUTLX_ROW4
               Null,--SZTUTLX_ROW5
               null,
               null,
               p_gratis,
               null,
               P_FRECUENCIA_PAGO, --SZTUTLX_FREC_PAGO -- COL NEW GLOVICX 27072023
               P_MONTO_DESC,
               P_NUM_DESC,
               P_NUM_DESC_APLIC
                  );
             END LOOP;

          END;
                     --COMMIT;
  END IF; ---CIERA EL INICIO GRAL EXISTE O NO??  
 
     return vl_msje;

 EXCEPTION WHEN OTHERS THEN
       vl_msje := sqlerrm;
 END  f_inserta_utlx;



         FUNCTION f_inserta_baja_utlx (p_pidm in number, p_matricula in varchar2, p_user varchar2, pfecha_bloq date ) RETURN VARCHAR2
                   AS

                 vl_msje VARCHAR2(250):='EXITO';
                 vl_utlx_seqno NUMBER:=0;
                 vl_password VARCHAR2(250);
                 vl_bandera NUMBER;



       BEGIN

                    BEGIN
                    SELECT NVL(MAX(SZTUTLX_SEQ_NO),0)+1
                    into vl_utlx_seqno
                    FROM SZTUTLX
                    WHERE 1=1
                    AND SZTUTLX_PIDM = p_pidm;
                    EXCEPTION
                    WHEN OTHERS THEN
                    vl_utlx_seqno:=1;
                    END;


                   BEGIN
                    SELECT GOZTPAC_PIN
                    INTO vl_password
                    FROM GOZTPAC
                    WHERE GOZTPAC_PIDM =p_pidm;
                   Exception
                   when no_data_found then
                   vl_bandera:=0;
                   END;

          BEGIN

          FOR c IN(SELECT a.SORLCUR_PIDM pidm, a.SORLCUR_TERM_CODE term_code, a.SORLCUR_CAMP_CODE campus, a.SORLCUR_LEVL_CODE nivel
                                    FROM SORLCUR a
                                    WHERE 1=1
                                    --AND a.SORLCUR_ROLL_IND ='Y'
                                    --AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                                    AND a.SORLCUR_SEQNO = (SELECT MAX(SORLCUR_SEQNO)
                                                             FROM SORLCUR b
                                                             WHERE 1=1
                                                             AND a.SORLCUR_PIDM = b.SORLCUR_PIDM)
                                    AND SORLCUR_PIDM = p_pidm

          )LOOP
            INSERT INTO SZTUTLX VALUES(c.pidm,--SZTUTLX_PIDM
                                               p_matricula, --SZTUTLX_ID
                                               c.term_code,--SZTUTLX_TERM_CODE
                                               c.campus,--SZTUTLX_CAMP_CODE
                                               c.nivel,--SZTUTLX_LEVL_CODE
                                               vl_utlx_seqno,--SZTUTLX_SEQ_NO
                                               0,--SZTUTLX_STAT_IND
                                               Null,--SZTUTLX_OBS
                                               'I',--SZTUTLX_DISABLE_IND
                                               vl_password,--SZTUTLX_PWD
                                               Null,--SZTUTLX_MDL_ID
                                               USER,--SZTUTLX_USER_INSERT
                                               SYSDATE,--SZTUTLX_ACTIVITY_DATE
                                               Null,--SZTUTLX_DATE_UPDATE
                                               Null,--SZTUTLX_USER_UPDATE
                                               sysdate,--SZTUTLX_ROW1
                                               Null,--SZTUTLX_ROW2
                                               Null,--SZTUTLX_ROW3
                                               Null,--SZTUTLX_ROW4
                                               Null,--SZTUTLX_ROW5
                                               p_user,
                                               pfecha_bloq,
                                               null,
                                               null,
                                               null,
                                               null,
                                               null,
                                               null
                                               );
           END LOOP;
           COMMIT;
           END;
           return vl_msje;
           EXCEPTION WHEN OTHERS THEN
           vl_msje := 'Error General'||sqlerrm;
       END  f_inserta_baja_utlx;



   FUNCTION f_cambio_pqte_utlx (p_pidm in number) RETURN VARCHAR2
    AS
       vl_msje VARCHAR2(250):='Proceso exitoso';
       vl_valida NUMBER;
       vl_utlx_seqno NUMBER:=0;

      BEGIN

            BEGIN
                SELECT COUNT(0)
                INTO vl_valida
                FROM GORADID
                WHERE 1=1
                AND GORADID_PIDM = p_pidm--89028-- FGET_PIDM('010246392')
                AND GORADID_ADDITIONAL_ID = 'UTEL-X';
              EXCEPTION
              WHEN OTHERS THEN
              vl_valida:=0;
            END;

             IF vl_valida = 0 THEN

                BEGIN
                  SELECT NVL(MAX(SZTUTLX_SEQ_NO),0)+1
                  into vl_utlx_seqno
                  FROM SZTUTLX
                  WHERE 1=1
                  AND SZTUTLX_PIDM = p_pidm;
                  EXCEPTION
                  WHEN OTHERS THEN
                  vl_utlx_seqno:=1;
                  END;

                 BEGIN
                   FOR i IN (

                            SELECT SPRIDEN_ID cuenta, SARADAP_TERM_CODE_ENTRY periodo, SARADAP_CAMP_CODE campus, SARADAP_LEVL_CODE nivel,GOZTPAC_PIN pass
                            FROM SARADAP a, SPRIDEN, GOZTPAC
                            WHERE 1=1
                            AND a.SARADAP_PIDM = spriden_pidm
                            AND a.SARADAP_PIDM = goztpac_pidm
                            AND SPRIDEN_CHANGE_IND is null
                            AND a.SARADAP_APST_CODE = 'A'
                            AND a.SARADAP_PIDM = p_pidm --fget_pidm('010243783')
                            AND a.SARADAP_APPL_NO = (SELECT MAX(b.SARADAP_APPL_NO)
                                                     FROM SARADAP b
                                                     WHERE 1=1
                                                     AND a.SARADAP_PIDM = b.SARADAP_PIDM
                                                     AND a.SARADAP_APST_CODE =b.SARADAP_APST_CODE)


                      )loop
                            INSERT INTO SZTUTLX VALUES(P_PIDM,--SZTUTLX_PIDM
                                               i.cuenta, --SZTUTLX_ID
                                               i.periodo,--SZTUTLX_TERM_CODE
                                               i.campus,--SZTUTLX_CAMP_CODE
                                               i.nivel,--SZTUTLX_LEVL_UPDATE
                                               vl_utlx_seqno,--SZTUTLX_SEQ_NO
                                               0,--SZTUTLX_STAT_IND
                                               Null,--SZTUTLX_OBS
                                               'A',--SZTUTLX_DISABLE_IND
                                               i.pass,--SZTUTLX_PWD
                                               Null,--SZTUTLX_MDL_ID
                                               USER,--SZTUTLX_USER_INSERT
                                               SYSDATE,--SZTUTLX_ACTIVITY_DATE
                                               Null,--SZTUTLX_DATE_UPDATE
                                               Null,--SZTUTLX_USER_UPDATE
                                               Null,--SZTUTLX_ROW1
                                               Null,--SZTUTLX_ROW2
                                               Null,--SZTUTLX_ROW3
                                               Null,--SZTUTLX_ROW4
                                               Null,--SZTUTLX_ROW5
                                               Null,
                                               Null,
                                               null,
                                               null,
                                               null,
                                               null,
                                               null,
                                               null
                                               );
                    END LOOP;
                   COMMIT;
                  END;
                 RETURN vl_msje;
              END IF;
              EXCEPTION WHEN OTHERS THEN
             vl_msje := 'Error General'||sqlerrm;
      END f_cambio_pqte_utlx;


    FUNCTION f_cambio_pqte_baja_utlx (p_pidm in number) RETURN VARCHAR2
           AS
            vl_msje VARCHAR2(250):='Proceso exitoso';
            vl_valida NUMBER;
            vl_seqno NUMBER;

        BEGIN

            BEGIN
                SELECT COUNT(0)
                INTO vl_valida
                FROM GORADID
                WHERE 1=1
                AND GORADID_PIDM = p_pidm --89028-- FGET_PIDM('010246392')
                AND GORADID_ADDITIONAL_ID = 'UTEL-X';
            EXCEPTION
            WHEN OTHERS THEN
            vl_valida:=0;
            END;

          IF vl_valida = 1 THEN

            BEGIN
                SELECT SZTUTLX_SEQ_NO
                INTO vl_seqno
                FROM SZTUTLX a
                WHERE 1=1
                AND a.SZTUTLX_PIDM = p_pidm --89028 --FGET_PIDM('010246392')
                AND a.SZTUTLX_DISABLE_IND = 'A'
                AND a.SZTUTLX_STAT_IND = 1
                AND a.SZTUTLX_SEQ_NO = (SELECT MAX(b.SZTUTLX_SEQ_NO)
                                       FROM SZTUTLX b
                                       WHERE 1=1
                                       AND a.SZTUTLX_PIDM = b.SZTUTLX_PIDM
                                       AND a.SZTUTLX_DISABLE_IND = b.SZTUTLX_DISABLE_IND
                                       AND a.SZTUTLX_STAT_IND = b.SZTUTLX_STAT_IND);
            EXCEPTION
            WHEN OTHERS THEN
            vl_msje:= sqlerrm||'Valor no encontrado';
            END;

            BEGIN
                UPDATE SZTUTLX SET  SZTUTLX_DISABLE_IND = 'I', SZTUTLX_STAT_IND = 0, SZTUTLX_USER_UPDATE = USER, SZTUTLX_DATE_UPDATE = SYSDATE
                WHERE 1=1
                AND SZTUTLX_PIDM = p_pidm
                AND SZTUTLX_SEQ_NO = vl_seqno;
            END;
            COMMIT;
            return vl_msje;
          END IF;
          EXCEPTION WHEN OTHERS THEN
          vl_msje := 'Error General'||sqlerrm;

      END f_cambio_pqte_baja_utlx;



     FUNCTION f_datos_actualizados_out RETURN PKG_UTLX.cursor_actualiza_out
        AS datos_out PKG_UTLX.cursor_actualiza_out;
 -- MODIFICO glovicx para que si viene otro dato diferente de name y mail  lo marque como otro,  08.12.2022
     BEGIN

        BEGIN

            OPEN datos_out FOR

         SELECT distinct c.SZTBIMA_PIDM pidm, c.SZTBIMA_ID matricula, 
                    c.SZTBIMA_FIRST_NAME nombre, 
                    REPLACE(c.SZTBIMA_LAST_NAME,'/', ' ') apellido, c.SZTBIMA_EMAIL_ADDRESS email,
                    decode (SZTBIMA_PROCESO, 'SPRIDEN','name','GOREMAL','mail')    dato
            FROM SZTBIMA c, SZTUTLX a
            WHERE 1=1
            AND c.SZTBIMA_PIDM = SZTUTLX_PIDM
            AND SZTUTLX_DISABLE_IND = 'A'
            AND c.SZTBIMA_STATUS_IND ='1'
            And c.SZTBIMA_PROCESO in ('GOREMAL', 'SPRIDEN')
            AND a.SZTUTLX_SEQ_NO = (SELECT MAX(SZTUTLX_SEQ_NO)
                                    FROM SZTUTLX b
                                    WHERE 1=1
                                    AND b.SZTUTLX_PIDM = a.SZTUTLX_PIDM)
            AND c.SZTBIMA_FECHA_ACTUALIZA = (SELECT MAX(d.SZTBIMA_FECHA_ACTUALIZA)
                                           FROM SZTBIMA d
                                           WHERE 1=1
                                           AND c.SZTBIMA_PIDM = d.SZTBIMA_PIDM);

        END;
        RETURN(datos_out);

      END f_datos_actualizados_out;

  FUNCTION f_update (p_pidm in number, p_dato in varchar2, p_obs in varchar2) Return Varchar2
     AS
       vl_error varchar2(250):='EXITO';
       vl_obs Varchar2(500):= p_obs;
       vl_dato Varchar2(30);
  -- MODIFICO glovicx para que si viene otro dato diferente de name y mail no haga nada 08.12.2022
     BEGIN

        IF p_dato = 'otro' THEN
        dbms_output.put_line('entro a otro y se sale '  || p_pidm ||'-'|| p_dato );
        return (vl_error) ;
        
        ELSIF  p_dato = 'name'THEN
           vl_dato:= 'SPRIDEN';
        ELSIF p_dato ='mail' THEN
           vl_dato:= 'GOREMAL';
        END IF;


        IF vl_dato IN ('SPRIDEN', 'GOREMAL'  ) THEN 
                BEGIN

                    UPDATE SZTBIMA SET SZTBIMA_STATUS_IND = '0', SZTBIMA_OBSERVACIONES = vl_obs, SZTBIMA_USUARIO_ACTUALIZA = user, SZTBIMA_FECHA_ACTUALIZA = sysdate
                    WHERE 1=1
                    AND SZTBIMA_PIDM = p_pidm
                    AND SZTBIMA_PROCESO = vl_dato;
                EXCEPTION
                WHEN OTHERS THEN
                vl_error:= 'Error linea 596'||sqlerrm;
                rollback;
                END;
                commit;
         END IF;       
        
        dbms_output.put_line('fuera de otro y se sale '  || p_pidm ||'-'|| p_dato );
        return(vl_error);


     END f_update;

 FUNCTION f_valida_utlx(p_pidm in number) RETURN VARCHAR2
   AS

   vl_return varchar2(10);

    BEGIN

       --FUNCI”N QUE HABILITA EL BOT”N DE REACTIVAVCI”N DEL SERVCIO--

        BEGIN

                SELECT COUNT(*)
                INTO vl_return
                FROM
                SZTUTLX a
                join SWTMDAC sw on SWTMDAC_PIDM = SZTUTLX_PIDM
                WHERE 1=1
                and  sw.SWTMDAC_MASTER_IND = 'Y'
                and sw.SWTMDAC_FLAG = 'Y'
                and substr (sw.SWTMDAC_DETAIL_CODE_ACC, 3,2) not in ('AJ', 'AC', 'YQ', 'QG', 'AD', 'ZV')
                and substr (sw.SWTMDAC_DETAIL_CODE_ACC, 3,2)  in ('QI', 'NA', 'WH', 'QI', 'WH')
                AND a.SZTUTLX_DISABLE_IND = 'I'
                And a.SZTUTLX_SEQ_NO = (select max (a1.SZTUTLX_SEQ_NO)
                                                        from  SZTUTLX a1
                                                        Where  a.SZTUTLX_PIDM = a1.SZTUTLX_PIDM)
                AND SZTUTLX_PIDM = p_pidm;

        RETURN vl_return;
        EXCEPTION WHEN OTHERS THEN
        vl_return:='0';
        RETURN vl_return;
        END;

    END;
    
--
--
FUNCTION f_reg_conecta_out  RETURN PKG_UTLX.cursor_conecta_out -- FER V3 24/01/2023

                    AS regist_conecta_out PKG_UTLX.cursor_conecta_out;
 BEGIN
     OPEN regist_conecta_out FOR
      SELECT 
                SPRIDEN_PIDM PIDM,
                SPRIDEN_ID Matricula,
                REPLACE(TRANSLATE (SPRIDEN.SPRIDEN_LAST_NAME,'·ÈÌÛ˙¡…Õ”⁄','aeiouAEIOU'),'/',' ')Apellido,
                SPRIDEN_FIRST_NAME Nombre,
                GOREMAL_EMAIL_ADDRESS email,
                PROGRAMA PROGRAMA,
                GZTPASS_PIN ContraseÒa,                                       
                a.ESTATUS Identificador,
                a.SECUENCIA Seq_no,
                a.COD_DETALLE Cod_Detalle,
                (SELECT SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER FROM SPRTELE WHERE 1=1 AND SPRTELE_PIDM = a.PIDM AND SPRTELE_TELE_CODE = 'CELU' ) Telefono,
                A.ORIGEN Origen_Vent, 
                35 DecisiÛn_Adm
                FROM SZTCONE A, SPRIDEN ,GOREMAL,GZTPASS, TZTPROG B
                WHERE 1=1
                AND SPRIDEN_PIDM = GOREMAL_PIDM
                AND SPRIDEN_PIDM = a.PIDM
                AND SPRIDEN_PIDM = GZTPASS_PIDM
                AND a.PIDM = GZTPASS_PIDM
                and GOREMAL_PIDM = a.PIDM
                AND SPRIDEN_ID = B.MATRICULA
                AND A.PIDM = B.PIDM
                AND GOREMAL_PIDM = B.PIDM
                AND GZTPASS_PIDM = B.PIDM
                AND SPRIDEN_CHANGE_IND IS NULL
                AND GOREMAL_EMAL_CODE = 'PRIN'
                And GOREMAL_STATUS_IND = 'A'
                AND GOREMAL_PREFERRED_IND = 'Y'
                AND a.ESTATUS_SINCRO = 0 
                AND a.ESTATUS IN ('I','A')
                AND a.SECUENCIA = (SELECT MAX(A1.SECUENCIA)
                                                          FROM SZTCONE a1
                                                          WHERE 1=1
                                                          AND a.PIDM = a1.PIDM)
                and B.SP = (SELECT MAX (B1.SP)
                                   FROM TZTPROG B1
                                   WHERE 1=1
                                   AND B.PIDM = B1.PIDM);

     RETURN(regist_conecta_out);
     
 END f_reg_conecta_out;
  

  END;
/

DROP PUBLIC SYNONYM PKG_UTLX;

CREATE OR REPLACE PUBLIC SYNONYM PKG_UTLX FOR BANINST1.PKG_UTLX;


GRANT EXECUTE ON BANINST1.PKG_UTLX TO SATURN;
