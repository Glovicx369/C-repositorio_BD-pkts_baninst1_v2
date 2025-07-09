DROP PACKAGE BODY BANINST1.PKG_MASIVOS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_MASIVOS AS

  FUNCTION F_RAZON_DA(P_MATRICULA VARCHAR2) RETURN VARCHAR2  IS
 
  v_existe number := 0;
  v_periodo varchar2(6):= null;
  vl_error varchar2(200)  := 'EXITO';
  BEGIN



         begin
                select 
                    distinct matriculacion 
                    into v_periodo
                from tztprog 
                where 1=1
                  and pidm = fget_pidm(P_MATRICULA)
                  and sp in 
                            (
                                select min(a1.sp) 
                                from tztprog a1 
                                where a1.pidm = fget_pidm(P_MATRICULA)
                            );
        end;

        BEGIN
            select SFBETRM_PIDM
               into v_existe
            from sfbetrm
            where SFBETRM_PIDM = fget_pidm(P_MATRICULA)
            and   SFBETRM_TERM_CODE = v_periodo;
           -- and   SFBETRM_RGRE_CODE='DA';


            UPDATE sfbetrm
            SET 
                SFBETRM_ACTIVITY_DATE = SYSDATE,
                SFBETRM_ESTS_CODE = 'NE',   
                SFBETRM_RGRE_CODE = 'DA',
                SFBETRM_USER= user,
                SFBETRM_DATA_ORIGIN='F_RAZON_DA',
                SFBETRM_USER_ID=USER                
            WHERE 
                SFBETRM_PIDM = fget_pidm(P_MATRICULA)
            and SFBETRM_TERM_CODE = v_periodo;

          exception 
             when others then

                BEGIN
                    INSERT INTO sfbetrm 
                                    (   SFBETRM_TERM_CODE,
                                        SFBETRM_PIDM,
                                        SFBETRM_ESTS_CODE,
                                        SFBETRM_ESTS_DATE,
                                        SFBETRM_MHRS_OVER,
                                        SFBETRM_AR_IND,
                                        SFBETRM_ASSESSMENT_DATE,
                                        SFBETRM_ADD_DATE,
                                        SFBETRM_ACTIVITY_DATE,
                                        SFBETRM_RGRE_CODE,
                                        SFBETRM_TMST_CODE,
                                        SFBETRM_TMST_DATE,
                                        SFBETRM_TMST_MAINT_IND,
                                        SFBETRM_USER,
                                        SFBETRM_REFUND_DATE,
                                        SFBETRM_DATA_ORIGIN,
                                        SFBETRM_INITIAL_REG_DATE,
                                        SFBETRM_MIN_HRS,
                                        SFBETRM_MINH_SRCE_CDE,
                                        SFBETRM_MAXH_SRCE_CDE,
                                        SFBETRM_SURROGATE_ID,
                                        SFBETRM_VERSION,
                                        SFBETRM_USER_ID,
                                        SFBETRM_VPDI_CODE
                                    )   
                                VALUES( 
                                       v_periodo, 
                                       fget_pidm(P_MATRICULA), 
                                       'NE', 
                                       SYSDATE, 
                                       99.99, 
                                       'Y', 
                                       NULL, 
                                       SYSDATE, 
                                       SYSDATE, 
                                       'DA',
                                       NULL,
                                       NULL,
                                       NULL,
                                       USER, 
                                       NULL,
                                       USER, 
                                       NULL, 
                                       0,
                                       NULL,
                                       NULL, 
                                       NULL,
                                       NULL,
                                       USER,
                                       NULL
                                    );
                  exception 
                    when others then                  
                         vl_error := 'Error al insertar SFBETRM: '||sqlerrm;
                  END;   
                  
                  vl_error := 'Inserta porque no encontró inforción para actualizar: '||sqlerrm;
        END; 
        commit;
    
    return vl_error;
    
  END F_RAZON_DA;
  
   PROCEDURE P_RAZON_BA AS
 
    vl_error varchar2(200)  := 'REGISTRO ACTUALIZADO CORRECTAMENTE';
    BEGIN
  
          
            for c in
                    (
                             select SFBETRM_PIDM, SFBETRM_TERM_CODE 
                             from  SFBETRM 
                             where SFBETRM_RGRE_CODE='BA'
                               AND --SFBETRM_PIDM = fget_pidm('010609309') and
                                 (
                                        SELECT distinct SFBETRM_PIDM --, SFBETRM_TERM_CODE
                                        FROM SFBETRM 
                                        join tbraccd  on tbraccd_pidm = SFBETRM_PIDM                                                  
                                        WHERE 
                                            SFBETRM_RGRE_CODE='BA'
                                        AND PKG_REPORTES_1.f_saldodia (SFBETRM_PIDM) <= 0
                                        AND tbraccd_detail_code  in (select ZSTPARA_PARAM_ID 
                                                                        from zstpara 
                                                                        where zstpara_mapa_id='COD_BA')
                                        and rownum=1
                                     --   AND SFBETRM_PIDM = fget_pidm('010609309')--60376
                                ) is null and  PKG_REPORTES_1.f_saldodia (SFBETRM_PIDM) <= 0
                    ) 
            loop
            
               
                    begin
                        update SFBETRM
                        set 
                                SFBETRM_RGRE_CODE = null,
                                SFBETRM_ESTS_CODE = 'EL',
                                SFBETRM_ACTIVITY_DATE = sysdate,
                                SFBETRM_USER='F_RAZON_BA',                               
                                SFBETRM_USER_ID = 'F_RAZON_BA'
                        where 
                                SFBETRM_RGRE_CODE='BA'
                        and     SFBETRM_PIDM=C.SFBETRM_PIDM;
                   
                   -- dbms_output.put_line('pidm: '||C.SFBETRM_PIDM);
                    exception 
                    when others then                  
                         vl_error := 'ERROR AL ACTUALIZAR SFBETRM: '||sqlerrm;
                    --     dbms_output.put_line('error: '||vl_error);
                         
                    END; 
                    
                    BEGIN
                    insert into SATURN.SZTHRZN
                                    (
                                        SZTHRZN_PIDM,
                                        SZTHRZN_TERM_CODE,
                                        SZTHRZN_RAZON,
                                        SZTHRZN_ACTIVITY_DATE,
                                        SZTHRZN_STATUS,
                                        SZTHRZN_COMENTARIOS,
                                        SZTHRZN_USER,
                                        SZTHRZN_SECUENCIA
                                     )   
                              values
                                    (
                                        C.SFBETRM_PIDM,
                                        C.SFBETRM_TERM_CODE,
                                        'BA',
                                        SYSDATE,
                                        1,
                                        vl_error,
                                        'MASIVO_BA',
                                        ( SELECT nvl(MAX(SZTHRZN_SECUENCIA),0)+1
                                          FROM SZTHRZN 
                                          WHERE 
                                            SZTHRZN_PIDM = C.SFBETRM_PIDM
                                        )
                                    );
                                    
                   exception 
                    when others then                  
                         vl_error := 'ERROR AL INSERTAR SZTHRZN: '||sqlerrm;
                    --     dbms_output.put_line('error: '||vl_error);                         
                    END;                   
                    
            end loop;
           
            COMMIT;
  
  
    END P_RAZON_BA;
   

END PKG_MASIVOS;
/

DROP PUBLIC SYNONYM PKG_MASIVOS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_MASIVOS FOR BANINST1.PKG_MASIVOS;
