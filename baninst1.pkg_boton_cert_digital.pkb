DROP PACKAGE BODY BANINST1.PKG_BOTON_CERT_DIGITAL;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_BOTON_CERT_DIGITAL AS
   /******************************************************************************
      NAME:       BANINST1.PKG_BOTON_CERT_DIGITAL
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        15/08/2024      GOLVERA       1. Created this package.
   ******************************************************************************/
   
   /*FUNCION ELIMINA ETIQUETA DE SOSD_DOCUMENTO */
   FUNCTION f_elimina_etiqueta (p_pidm IN NUMBER) RETURN VARCHAR2 

      IS 

      l_error VARCHAR2 (2500) := 'EXITO';
        
BEGIN

    BEGIN
        DELETE goradid 
        WHERE 1=1
        AND goradid_pidm = p_pidm
        AND goradid_adid_code IN (SELECT ZSTPARA_PARAM_VALOR
                                    FROM ZSTPARA
                                   WHERE ZSTPARA_MAPA_ID = 'SOSD_DOCUMENTO'); 
          
                          
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR AL ELIMINAR CÓDIGO EN GORADID '||SQLERRM);  
            l_error:= ('ERROR AL ELIMINAR CÓDIGO EN GORADID '||sqlerrm);
    END;

COMMIT;

RETURN(l_error);
END f_elimina_etiqueta;
--
--

   /*FUNCION INSERTA ETIQUETA DE SOSD_DOCUMENTO */
    FUNCTION f_inserta_etiqueta (p_pidm IN NUMBER,p_etiqueta in VARCHAR2) RETURN VARCHAR2

      IS 

      l_error VARCHAR2 (2500) := 'EXITO';
      ln_MAX_SURROGATE     NUMBER := 0;
      lv_desc   ZSTPARA.ZSTPARA_PARAM_DESC%TYPE;
      lv_etiqueta ZSTPARA.ZSTPARA_PARAM_VALOR%TYPE;
        
BEGIN
    
    BEGIN 
    SELECT ZSTPARA_PARAM_VALOR, ZSTPARA_PARAM_DESC
      INTO lv_etiqueta, lv_desc
      FROM ZSTPARA
     WHERE ZSTPARA_MAPA_ID = 'SOSD_DOCUMENTO'
       AND ZSTPARA_PARAM_ID = p_etiqueta;
    EXCEPTION
        WHEN OTHERS THEN
          l_error := 'Error al consultar datos del parametrizador SOSD_DOCUMENTO ...'|| P_PIDM || CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;
    END;

    -- Maximo registro del ID a sustituir(SURROGATE) en GORADID mas 1.
    BEGIN
        SELECT NVL (MAX (GORA.GORADID_SURROGATE_ID), 0) + 1
          INTO ln_MAX_SURROGATE
          FROM GORADID GORA
         WHERE 1 = 1;

    EXCEPTION
        WHEN OTHERS THEN
            LN_MAX_SURROGATE := 1;
    END;

    
  -- Inserta registro de etiqueta en la tabla GORADID.
         BEGIN
            INSERT INTO GORADID (GORADID_PIDM,
                                 GORADID_ADDITIONAL_ID,
                                 GORADID_ADID_CODE,
                                 GORADID_USER_ID,
                                 GORADID_ACTIVITY_DATE,
                                 GORADID_DATA_ORIGIN,
                                 GORADID_SURROGATE_ID,
                                 GORADID_VERSION,
                                 GORADID_VPDI_CODE)
                         VALUES (P_PIDM                                 --GORADID_PIDM
                               ,
                         lv_desc              --GORADID_ADDITIONAL_ID
                                         ,
                         lv_etiqueta                        --GORADID_ADID_CODE
                                   ,
                         USER                           --GORADID_USER_ID
                                  ,
                         SYSDATE                       --GORADID_ACTIVITY_DATE
                                ,
                         'UTEL'                          --GORADID_DATA_ORIGIN
                               ,
                         ln_MAX_SURROGATE               --GORADID_SURROGATE_ID
                                         ,
                         0                                   --GORADID_VERSION
                          ,
                         NULL);                            --GORADID_VPDI_CODE
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error := 'Error al insertar en la tabla GORADID para el alumno(Pidm) '|| P_PIDM || ' para etiqueta, favor de revisarlo... '|| CHR (10)|| 'SQLCODE: '|| SQLCODE|| CHR (10)|| SQLERRM;

         END;

COMMIT;
    
    RETURN(l_error);

END f_inserta_etiqueta;
END PKG_BOTON_CERT_DIGITAL;
/

DROP PUBLIC SYNONYM PKG_BOTON_CERT_DIGITAL;

CREATE OR REPLACE PUBLIC SYNONYM PKG_BOTON_CERT_DIGITAL FOR BANINST1.PKG_BOTON_CERT_DIGITAL;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_BOTON_CERT_DIGITAL TO PUBLIC;
