DROP PACKAGE BODY BANINST1.PKG_SIR_UTILERIAS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_SIR_UTILERIAS AS
    FUNCTION fn_obtener_goradid_check_venta( p_pidm NUMBER ) RETURN VARCHAR2 AS
        v_respuesta VARCHAR2(2);
        v_check     INT;

        BEGIN
            SELECT  COUNT(*)
            INTO    v_check
            FROM    goradid
            WHERE   goradid_pidm = p_pidm
            AND     goradid_adid_code = 'CHEK';

            IF v_check > 0 THEN
                v_respuesta := 'SI';
            ELSE
                v_respuesta := 'NO';
            END IF;

            RETURN v_respuesta;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN '';
            WHEN OTHERS THEN
                RETURN 'ERROR: ' || SQLCODE;
    END fn_obtener_goradid_check_venta;
    
    FUNCTION fn_obtener_goradid_descripcion( p_pidm NUMBER, p_codigo VARCHAR2 ) RETURN VARCHAR2 AS
        v_descripcion VARCHAR2(100);

        BEGIN
            SELECT  goradid_additional_id
            INTO    v_descripcion
            FROM    goradid
            WHERE   goradid_pidm = p_pidm
            AND     goradid_adid_code = p_codigo;

            IF v_descripcion IS NULL THEN
                v_descripcion := '';
            END IF;

            RETURN v_descripcion;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN '';
            WHEN OTHERS THEN
                RETURN 'ERROR: ' || SQLCODE;
    END fn_obtener_goradid_descripcion;

    FUNCTION fn_obtener_status_reins( p_pidm NUMBER ) RETURN VARCHAR2 AS
        v_status VARCHAR2(10);

        BEGIN
            SELECT  DISTINCT GORADID_ADDITIONAL_ID 
            INTO    v_status
            FROM    goradid 
            WHERE   goradid_pidm = p_pidm
            AND     GORADID_ADID_CODE = 'REIN' 
            AND     GORADID_ACTIVITY_DATE IN 
                (
                    SELECT  MAX(GORADID_ACTIVITY_DATE) 
                    FROM    GORADID G
                    WHERE   G.goradid_pidm = p_pidm
                    AND     G.GORADID_ADID_CODE = 'REIN'
                );

            IF v_status IS NULL THEN
                v_status := 'NA';
            END IF;

            RETURN v_status;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'NA';
            WHEN OTHERS THEN
                RETURN 'ERROR: ' || SQLCODE;
    END fn_obtener_status_reins;

    FUNCTION fn_obtener_status_sosd( p_pidm NUMBER ) RETURN VARCHAR2 AS
        v_status_sosd VARCHAR2(10);

        BEGIN
            SELECT  DISTINCT GORADID_ADDITIONAL_ID 
            INTO    v_status_sosd
            FROM    goradid 
            WHERE   goradid_pidm = p_pidm 
            AND     GORADID_ADID_CODE = 'SOSD' 
            AND     GORADID_ACTIVITY_DATE IN 
                (
                    SELECT  MAX(GORADID_ACTIVITY_DATE) 
                    FROM    GORADID G
                    WHERE   G.goradid_pidm = p_pidm 
                    AND     G.GORADID_ADID_CODE = 'SOSD'
                );

            IF v_status_sosd IS NULL THEN
                v_status_sosd := 'NA';
            END IF;

            RETURN v_status_sosd;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'NA';
            WHEN OTHERS THEN
                RETURN 'ERROR: ' || SQLCODE;
    END fn_obtener_status_sosd;

    FUNCTION fn_obtener_razon( p_pidm NUMBER ) RETURN VARCHAR2 AS
        v_razon VARCHAR2(10);

        BEGIN
            SELECT  UNIQUE sfbetrm_rgre_code
            INTO    v_razon
            FROM    sfbetrm
            WHERE   sfbetrm_pidm = p_pidm
            AND     trunc(SFBETRM_ACTIVITY_DATE) = 
                (
                    SELECT  max(trunc(t1.SFBETRM_ACTIVITY_DATE))
                    FROM    sfbetrm t1
                    where   t1.sfbetrm_pidm = p_pidm
                )
            AND ROWNUM <= 1
            GROUP BY sfbetrm_rgre_code;

            IF v_razon IS NULL THEN -- cuando encuentra resultado NULL
                v_razon := 'NA';
            END IF;

            RETURN v_razon;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'NA'; -- cuando no encuentra resultados
            WHEN OTHERS THEN
                RETURN 'ERROR: ' || SQLCODE;
    END fn_obtener_razon;

    FUNCTION fn_usuario_spriden( p_pidm NUMBER, p_programa VARCHAR2, p_codigo_doc VARCHAR2 ) RETURN VARCHAR2 AS
        v_nombre    VARCHAR2(49);
        v_apellidos VARCHAR2(49);
        v_appl_no   NUMBER;
        v_user_id   VARCHAR2(49);

        BEGIN
            SELECT  MAX( SARADAP_APPL_NO )
            INTO    v_appl_no
            FROM    saradap
            WHERE   saradap_pidm = p_pidm
            AND     saradap_program_1 = p_programa;

            SELECT      sarchkl_user_id, spriden_first_name, spriden_last_name
            INTO        v_user_id, v_nombre, v_apellidos
            FROM        sarchkl 
            LEFT JOIN   spriden ON spriden_id = sarchkl_user_id
            WHERE       sarchkl_admr_code = p_codigo_doc
            AND         sarchkl_pidm = p_pidm
            AND         sarchkl_appl_no = v_appl_no;

            IF v_apellidos IS NULL THEN
                RETURN 'MASIVO';
            ELSE
                RETURN v_nombre || ' ' || v_apellidos;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'NA';
            WHEN OTHERS THEN
                RETURN 'ERROR: ' || SQLCODE;
    END fn_usuario_spriden;

    FUNCTION fn_fecha_documento( p_pidm NUMBER, p_programa VARCHAR2, p_codigo_doc VARCHAR2 ) RETURN VARCHAR2 AS
        v_fecha     VARCHAR2(30);
        v_appl_no   NUMBER;
        BEGIN
            v_fecha := '';

            SELECT  MAX( SARADAP_APPL_NO )
            INTO    v_appl_no
            FROM    saradap
            WHERE   saradap_pidm = p_pidm
            AND     saradap_program_1 = p_programa;

            SELECT      TO_CHAR(sarchkl_source_date, 'YYYY/MM/DD HH24:MI:SS')
            INTO        v_fecha
            FROM        sarchkl a
            WHERE       sarchkl_admr_code = p_codigo_doc
            AND         sarchkl_pidm = p_pidm
            AND         sarchkl_appl_no = v_appl_no;

            RETURN v_fecha;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'NA';
            WHEN OTHERS THEN
                RETURN 'ERROR: ' || SQLCODE;
    END fn_fecha_documento;

END PKG_SIR_UTILERIAS;
/
