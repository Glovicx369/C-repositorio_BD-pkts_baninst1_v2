DROP PACKAGE BODY BANINST1.PKG_ACTAS_TITULACION;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_ACTAS_TITULACION IS
   /******************************************************************************
      NAME:       BANINST1.PKG_ACTAS_TITULACION
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        08/01/2025      GOLVERA       1. Created this package.
   ******************************************************************************/

FUNCTION fn_carga_mec (p_num_acta IN NUMBER, 
                       p_matricula IN VARCHAR2, 
                       p_tip_documento IN VARCHAR2, 
                       p_tip_titulo VARCHAR2,
                       p_fec_exp_cert VARCHAR2,
                       p_tip_cargo IN VARCHAR2,
                       p_num_rvoe IN NUMBER,
                       p_fec_rvoe IN VARCHAR2,
                       p_nombre_egresado IN VARCHAR2,
                       p_folio_acta IN VARCHAR2,
                       p_firmante IN VARCHAR2,
                       p_nom_programa IN VARCHAR2,
                       p_clave_plan IN NUMBER,
                       p_nivel_estudios IN VARCHAR2
                       ) RETURN VARCHAR2 IS

         l_retorna      varchar2(200):='Exito';
         
BEGIN 
    BEGIN
    insert into sztacmc (SZTACMC_NUM_ACTA,
                        SZTACMC_ID,
                        SZTACMC_TIP_DOCUMENTO,
                        SZTACMC_TIP_TITULACION,
                        SZTACMC_FEC_EXP_CERT,
                        SZTACMC_TIP_GRADO,
                        SZTACMC_NUM_RVOE,
                        SZTACMC_FEC_RVOE,
                        SZTACMC_NOM_EGRESADO,
                        SZTACMC_FOLIO_ACTA,
                        SZTACMC_FIRMANTE,
                        SZTACMC_NOM_PROGRAMA,
                        SZTACMC_CVE_PLAN,
                        SZTACMC_NIVEL_ESTUDIOS)
                        VALUES
                        (to_number(p_num_acta) , 
                       p_matricula , 
                       p_tip_documento , 
                       p_tip_titulo ,
                       p_fec_exp_cert ,
                       p_tip_cargo ,
                       to_number(p_num_rvoe),
                       p_fec_rvoe ,
                       p_nombre_egresado,
                       p_folio_acta ,
                       p_firmante,
                       p_nom_programa,
                       to_number(p_clave_plan) ,
                       p_nivel_estudios );
                       COMMIT;
                       l_retorna := 'Exito';
            EXCEPTION
            WHEN OTHERS THEN
            l_retorna :=' Error al insertar actas titulación' || SQLERRM ;    
                                                        
            End;   
   RETURN(l_retorna);                                
END fn_carga_mec;                             

FUNCTION fn_carga_met (p_num_libro IN NUMBER, 
                       p_matricula IN VARCHAR2, 
                       p_tip_documento IN VARCHAR2, 
                       p_fec_carga VARCHAR2,
                       p_tip_cargo IN VARCHAR2,
                       p_num_rvoe IN NUMBER,
                       p_fec_rvoe IN VARCHAR2,
                       p_nombre_egresado IN VARCHAR2,
                       p_nombre_plan_estudios IN VARCHAR2,
                       p_fec_exp_titulo IN VARCHAR2,
                       p_folio_docto IN VARCHAR2,
                       p_firmante IN VARCHAR2,
                       p_folio_titulo IN VARCHAR2,
                       p_nivel_estudios IN VARCHAR2,
                       p_estatus_titulo IN VARCHAR2
                       ) RETURN VARCHAR2 IS

         l_retorna      varchar2(200):='Exito';
         
BEGIN 
    BEGIN
    insert into sztacmt  (SZTACMT_NUM_LIBRO     ,
                          SZTACMT_ID            ,
                          SZTACMT_TIP_DOCUMENTO ,
                          SZTACMT_FEC_CARGA     ,
                          SZTACMT_TIP_GRADO     ,
                          SZTACMT_NUM_RVOE      ,
                          SZTACMT_FEC_RVOE      ,
                          SZTACMT_NOM_EGRESADO  ,
                          SZTACMT_NOM_PLAN_EST  ,
                          SZTACMT_FEC_EXP_TITULO,
                          SZTACMT_FOLIO_DOC     ,
                          SZTACMT_FIRMANTE      ,
                          SZTACMT_FOLIO_TITULO  ,
                          SZTACMT_NIVEL_ESTUDIOS,
                          SZTACMT_ESTATUS_TITULO)
                        VALUES
                        (to_number(p_num_libro),
                       p_matricula ,
                       p_tip_documento, 
                       p_fec_carga,
                       p_tip_cargo,
                       to_number(p_num_rvoe),
                       p_fec_rvoe,
                       p_nombre_egresado,
                       p_nombre_plan_estudios,
                       p_fec_exp_titulo,
                       p_folio_docto,
                       p_firmante,
                       p_folio_titulo,
                       p_nivel_estudios,
                       p_estatus_titulo);
                       COMMIT;
                      l_retorna := 'Exito';
            EXCEPTION
            WHEN OTHERS THEN
            l_retorna :=' Error al insertar libros de titulo' || SQLERRM ;    
                                                        
            End;   
   RETURN(l_retorna);  
END fn_carga_met;   

END PKG_ACTAS_TITULACION;
/

DROP PUBLIC SYNONYM PKG_ACTAS_TITULACION;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ACTAS_TITULACION FOR BANINST1.PKG_ACTAS_TITULACION;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_ACTAS_TITULACION TO PUBLIC;
