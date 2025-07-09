DROP PACKAGE BODY BANINST1.PKG_NIVEL_RIESGO_UNI;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_NIVEL_RIESGO_UNI AS

  PROCEDURE P_INSERTAR_NIVEL_RIESGO (
    p_datos_riesgo IN TY_TAB_NIVEL_RIESGO_GLOBAL
  )
  IS

    e_dml_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_dml_errors, -24381); 

    v_error_index NUMBER; 
    v_error_code  NUMBER ;
    v_error_msg   VARCHAR2(4000);    

    v_errores_encontrados BOOLEAN := FALSE; -- Bandera para saber si hubo errores
    v_rows_insertadas NUMBER := 0; -- Contador de filas insertadas exitosamente
  BEGIN
    
  
    IF p_datos_riesgo IS NULL OR p_datos_riesgo.COUNT = 0 THEN
      RETURN;
    END IF;

    -- Usar FORALL con SAVE EXCEPTIONS para capturar errores por fila
    BEGIN
      FORALL i IN 1 .. p_datos_riesgo.COUNT SAVE EXCEPTIONS
        INSERT INTO nivel_riesgo (
          MATRICULA,
          BLOQUE_SEG,
          NIVEL_RIESGO,
          SEMAFORO,
          TUTOR,
          SUPERVISOR,
          LINEA_NEGOCIO,
          MODALIDAD,
          ESTRATEGIA_1,
          ESTRATEGIA_2,
          ESTRATEGIA_3,
          RIESGO_PERMANENCIA,
          FASE_1,
          FASE_2,
          NR_NIVELACION,
          CLAVE_MATERIA_NIVE,
          MODALIDAD_EVA_NIVE,
          EGEL_PLAN_ESTUDIO,
          FLAG_HUBSPOT
        ) VALUES (
          p_datos_riesgo(i).MATRICULA,
          p_datos_riesgo(i).BLOQUE_SEG,
          p_datos_riesgo(i).NIVEL_RIESGO,
          p_datos_riesgo(i).SEMAFORO,
          p_datos_riesgo(i).TUTOR,
          p_datos_riesgo(i).SUPERVISOR,
          p_datos_riesgo(i).LINEA_NEGOCIO,
          p_datos_riesgo(i).MODALIDAD,
          p_datos_riesgo(i).ESTRATEGIA_1,
          p_datos_riesgo(i).ESTRATEGIA_2,
          p_datos_riesgo(i).ESTRATEGIA_3,
          p_datos_riesgo(i).RIESGO_PERMANENCIA,
          p_datos_riesgo(i).FASE_1,
          p_datos_riesgo(i).FASE_2,
          p_datos_riesgo(i).NR_NIVELACION,
          p_datos_riesgo(i).CLAVE_MATERIA_NIVE,
          p_datos_riesgo(i).MODALIDAD_EVA_NIVE,
          p_datos_riesgo(i).EGEL_PLAN_ESTUDIO,
          '1'
        );



    EXCEPTION
      WHEN e_dml_errors THEN
        v_errores_encontrados := TRUE;

        FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
            v_error_index := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
            v_error_code  := SQL%BULK_EXCEPTIONS(i).ERROR_CODE;
            v_error_msg   := SUBSTR(SQLERRM(-v_error_code), 1, 2500); 
          BEGIN
            INSERT INTO Bita_riesgo (MATRICULA, ERROR)
            VALUES (p_datos_riesgo(v_error_index).MATRICULA,
                    'Error: ' || v_error_code || ' - ' || v_error_msg);

          EXCEPTION
            WHEN OTHERS THEN
                null;
          END;
        END LOOP;
        
    END; 
    Commit;


  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK; 
      RAISE; 
  END P_INSERTAR_NIVEL_RIESGO;


function f_integra_hubspot RETURN PKG_NIVEL_RIESGO_UNI.riesgo_out as

                riesgo_out_aut PKG_NIVEL_RIESGO_UNI.riesgo_out;

                Begin
                          open riesgo_out_aut
                            FOR
                                 select distinct a.matricula, 
                                        c.SPRIDEN_FIRST_NAME Nombre, 
                                        SUBSTR(c.SPRIDEN_LAST_NAME, 1, INSTR(c.SPRIDEN_LAST_NAME, '/') - 1) ||' '|| SUBSTR(c.SPRIDEN_LAST_NAME, INSTR(c.SPRIDEN_LAST_NAME, '/') + 1, 150)  Apellido, 
                                        SZVCAMP_COUNTRY pais, 
                                        a.campus, 
                                        a.nivel, 
                                        STVLEVL_DESC Nivel_Descripcion, 
                                        NVL(TRIM(pkg_utilerias.f_correo(a.pidm, 'PRIN')), NVL(TRIM(pkg_utilerias.f_correo(a.pidm, 'UCAM')), TRIM(pkg_utilerias.f_correo(a.pidm, 'UTLX')))) Correo,
                                        pkg_utilerias.f_celular(a.pidm, 'CELU')  Celular,                                        
                                        a.PROGRAMA,  
                                        (select distinct a.SZTDTEC_PROGRAMA_COMP
                                        from sztdtec a
                                        where a.SZTDTEC_PROGRAM = a.programa
                                        And a.SZTDTEC_CAMP_CODE = a.campus
                                        And a.SZTDTEC_TERM_CODE = (select max(a1.SZTDTEC_TERM_CODE) 
                                                                   from sztdtec a1 
                                                                   where 1=1
                                                                   And a.SZTDTEC_CAMP_CODE = a1.SZTDTEC_CAMP_CODE
                                                                   And a.SZTDTEC_PROGRAM = a1.SZTDTEC_PROGRAM)) PROGRAMA_DESCRIPCION,                                     
                                        a.fecha_inicio, 
                                        b.BLOQUE_SEG Bimestre,
                                        b.SEMAFORO, 
                                        ceil((sysdate-a.fecha_inicio) / 7) NO_SEMANA,
                                        a.sp sp,
                                        a.matricula||'-'||a.sp validador,
                                        CONTACTO_HUBSPOT contacto_hubspot,
                                        REGISTRO_ACADEMICO registro_academico
                                from TZTPROG_INCR a
                                join nivel_riesgo b on b.matricula = a.matricula 
                                join spriden c on c.spriden_pidm = a.pidm and c.spriden_change_ind is null
                                join SZVCAMP on SZVCAMP_CAMP_CODE = a.campus
                                join stvlevl on STVLEVL_CODE = a.nivel 
                                where 1=1
                                And a.ESTATUS = 'MA'
                                And b.FLAG_HUBSPOT ='1'
                                And a.campus in ('UTL', 'PER', 'ECU', 'USA', 'DOM', 'ARG', 'COL')
                                And a.nivel in ('LI')
                                And ceil((sysdate-a.fecha_inicio) / 7) Between 1 and 8;
                                 ---> Se prende solo para las pruebas

                        RETURN (riesgo_out_aut);

END f_integra_hubspot;


function actualiza_integracion (p_matricula in varchar2, p_sp in number, p_contacto_hubspot in varchar2 default null, p_registro_academico in varchar2 default null  ) return varchar2
as

    vl_valor varchar2(250) := null;

    Begin

                vl_valor:= 'EXITO';
                
                If trim (p_contacto_hubspot) is not null and trim (p_registro_academico) is not null then  
                
                    Begin
                            update nivel_riesgo
                            set FLAG_HUBSPOT = '0',
                            contacto_hubspot = p_contacto_hubspot,
                            registro_academico = p_registro_academico
                            where matricula = p_matricula;
                            --and sp = p_sp;
                            Commit;
                    Exception
                        When Others then
                            vl_valor := 'Error al actualizar '||sqlerrm;
                    End;
                    
                End if;

               Return (vl_valor);

    Exception
        when Others then
         vl_valor := 'No Encontro registro para actualizar ' ||sqlerrm;
          Return (vl_valor);
    End actualiza_integracion;


PROCEDURE P_INSERTAR_NIVEL_RIESGO_v2 (
    p_datos_riesgo IN TY_TAB_NIVEL_RIESGO_GLOBAL
)
IS
    e_dml_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_dml_errors, -24381);

    v_error_index NUMBER;
    v_error_code  NUMBER ;
    v_error_msg   VARCHAR2(4000);

    v_errores_encontrados BOOLEAN := FALSE; -- Bandera para saber si hubo errores
BEGIN

    IF p_datos_riesgo IS NULL OR p_datos_riesgo.COUNT = 0 THEN
        RETURN;
    END IF;

    -- Usar FORALL con MERGE para actualizar si existe o insertar si no existe
    BEGIN
        FORALL i IN 1 .. p_datos_riesgo.COUNT SAVE EXCEPTIONS
            MERGE INTO nivel_riesgo nr
            USING (SELECT p_datos_riesgo(i).MATRICULA AS MATRICULA_IN,
                          p_datos_riesgo(i).BLOQUE_SEG AS BLOQUE_SEG_IN,
                          p_datos_riesgo(i).NIVEL_RIESGO AS NIVEL_RIESGO_IN,
                          p_datos_riesgo(i).SEMAFORO AS SEMAFORO_IN,
                          p_datos_riesgo(i).TUTOR AS TUTOR_IN,
                          p_datos_riesgo(i).SUPERVISOR AS SUPERVISOR_IN,
                          p_datos_riesgo(i).LINEA_NEGOCIO AS LINEA_NEGOCIO_IN,
                          p_datos_riesgo(i).MODALIDAD AS MODALIDAD_IN,
                          p_datos_riesgo(i).ESTRATEGIA_1 AS ESTRATEGIA_1_IN,
                          p_datos_riesgo(i).ESTRATEGIA_2 AS ESTRATEGIA_2_IN,
                          p_datos_riesgo(i).ESTRATEGIA_3 AS ESTRATEGIA_3_IN,
                          p_datos_riesgo(i).RIESGO_PERMANENCIA AS RIESGO_PERMANENCIA_IN,
                          p_datos_riesgo(i).FASE_1 AS FASE_1_IN,
                          p_datos_riesgo(i).FASE_2 AS FASE_2_IN,
                          p_datos_riesgo(i).NR_NIVELACION AS NR_NIVELACION_IN,
                          p_datos_riesgo(i).CLAVE_MATERIA_NIVE AS CLAVE_MATERIA_NIVE_IN,
                          p_datos_riesgo(i).MODALIDAD_EVA_NIVE AS MODALIDAD_EVA_NIVE_IN,
                          p_datos_riesgo(i).EGEL_PLAN_ESTUDIO AS EGEL_PLAN_ESTUDIO_IN
                    FROM DUAL) datos_in
            ON (nr.MATRICULA = datos_in.MATRICULA_IN)
            WHEN MATCHED THEN
                UPDATE SET
                    nr.BLOQUE_SEG = datos_in.BLOQUE_SEG_IN,
                    nr.NIVEL_RIESGO = datos_in.NIVEL_RIESGO_IN,
                    nr.SEMAFORO = datos_in.SEMAFORO_IN,
                    nr.TUTOR = datos_in.TUTOR_IN,
                    nr.SUPERVISOR = datos_in.SUPERVISOR_IN,
                    nr.LINEA_NEGOCIO = datos_in.LINEA_NEGOCIO_IN,
                    nr.MODALIDAD = datos_in.MODALIDAD_IN,
                    nr.ESTRATEGIA_1 = datos_in.ESTRATEGIA_1_IN,
                    nr.ESTRATEGIA_2 = datos_in.ESTRATEGIA_2_IN,
                    nr.ESTRATEGIA_3 = datos_in.ESTRATEGIA_3_IN,
                    nr.RIESGO_PERMANENCIA = datos_in.RIESGO_PERMANENCIA_IN,
                    nr.FASE_1 = datos_in.FASE_1_IN,
                    nr.FASE_2 = datos_in.FASE_2_IN,
                    nr.NR_NIVELACION = datos_in.NR_NIVELACION_IN,
                    nr.CLAVE_MATERIA_NIVE = datos_in.CLAVE_MATERIA_NIVE_IN,
                    nr.MODALIDAD_EVA_NIVE = datos_in.MODALIDAD_EVA_NIVE_IN,
                    nr.EGEL_PLAN_ESTUDIO = datos_in.EGEL_PLAN_ESTUDIO_IN,
                    nr.FLAG_HUBSPOT = '1' 
            WHEN NOT MATCHED THEN
                INSERT (
                    MATRICULA,
                    BLOQUE_SEG,
                    NIVEL_RIESGO,
                    SEMAFORO,
                    TUTOR,
                    SUPERVISOR,
                    LINEA_NEGOCIO,
                    MODALIDAD,
                    ESTRATEGIA_1,
                    ESTRATEGIA_2,
                    ESTRATEGIA_3,
                    RIESGO_PERMANENCIA,
                    FASE_1,
                    FASE_2,
                    NR_NIVELACION,
                    CLAVE_MATERIA_NIVE,
                    MODALIDAD_EVA_NIVE,
                    EGEL_PLAN_ESTUDIO,
                    FLAG_HUBSPOT
                ) VALUES (
                    datos_in.MATRICULA_IN,
                    datos_in.BLOQUE_SEG_IN,
                    datos_in.NIVEL_RIESGO_IN,
                    datos_in.SEMAFORO_IN,
                    datos_in.TUTOR_IN,
                    datos_in.SUPERVISOR_IN,
                    datos_in.LINEA_NEGOCIO_IN,
                    datos_in.MODALIDAD_IN,
                    datos_in.ESTRATEGIA_1_IN,
                    datos_in.ESTRATEGIA_2_IN,
                    datos_in.ESTRATEGIA_3_IN,
                    datos_in.RIESGO_PERMANENCIA_IN,
                    datos_in.FASE_1_IN,
                    datos_in.FASE_2_IN,
                    datos_in.NR_NIVELACION_IN,
                    datos_in.CLAVE_MATERIA_NIVE_IN,
                    datos_in.MODALIDAD_EVA_NIVE_IN,
                    datos_in.EGEL_PLAN_ESTUDIO_IN,
                    '1'
                );

    EXCEPTION
        WHEN e_dml_errors THEN
            v_errores_encontrados := TRUE;

            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                v_error_index := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
                v_error_code  := SQL%BULK_EXCEPTIONS(i).ERROR_CODE;
                v_error_msg   := SUBSTR(SQLERRM(-v_error_code), 1, 2500);
                BEGIN
                    INSERT INTO Bita_riesgo (MATRICULA, ERROR)
                    VALUES (p_datos_riesgo(v_error_index).MATRICULA,
                            'Error: ' || v_error_code || ' - ' || v_error_msg);
                EXCEPTION
                    WHEN OTHERS THEN
                        -- Si falla la inserción en la tabla de errores, simplemente ignora para no detener el proceso
                        NULL;
                END;
            END LOOP;

    END;
    COMMIT; 

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END P_INSERTAR_NIVEL_RIESGO_v2;


END PKG_NIVEL_RIESGO_UNI;
/

DROP PUBLIC SYNONYM PKG_NIVEL_RIESGO_UNI;

CREATE OR REPLACE PUBLIC SYNONYM PKG_NIVEL_RIESGO_UNI FOR BANINST1.PKG_NIVEL_RIESGO_UNI;
