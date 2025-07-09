DROP PACKAGE BODY BANINST1.PKG_FUNCIONES_PIPELINED;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_funciones_pipelined AS
  FUNCTION get_matricula(p_pidm number) RETURN t_tab PIPELINED is
    l_row  t_spriden;
    
     
    BEGIN
        
        for c in (select  SPRIDEN_FIRST_NAME nombre, 
                    SPRIDEN_ID matricula, 
                    SPRIDEN_LAST_NAME apaterno,
                    SPRIDEN_USER direccion
                 from spriden
                 where 1 = 1
                 and spriden_pidm = nvl(p_pidm,spriden_pidm)
                 and spriden_change_ind is null
                 )loop
                 
                        l_row.nombre  := c.nombre;
                        l_row.matricula  := c.matricula;
                        l_row.apaterno  := c.apaterno;
                        l_row.direccion:= c.direccion;
                        PIPE ROW (l_row);
                 
                 end loop;
    
        
        RETURN;
    END;
FUNCTION GET_SZTALIN (P_REGLA NUMBER)RETURN  T_szta PIPELINED IS
  l_row t_sztalian;
  
  BEGIN 
  
     FOR C IN (SELECT
                    SZTALIAN_PIDM PIDM,
                    SZTALIAN_ID   MATRICULA,            
                    SZTALIAN_PROGRAMA  PROGRAMA,       
                    SZTALIAN_ALIANZA   ALIANZA,       
                    SZTALIAN_AVANCE    AVANCE,       
                    SZTALIAN_NO_REGLA  NO_REGLA,       
                    SZTALIAN_ESTATUS   ESTATUS,       
                    SZTALIAN_MATERIAS_PARA  MATERIAS_PARA,  
                    SZTALIAN_MATERIAS_HORARIOS MATERIAS_HORARIOS
                FROM SZTALIAN
                WHERE 1=1
                AND SZTALIAN_NO_REGLA=P_REGLA
                
               ) LOOP
               
                    l_row.pidm  :=c.pidm   ;        
                    l_row.matricula :=c.matricula;                    
                    l_row.programa    :=c.programa;                
                    l_row.alianza    :=c.alianza     ;            
                    l_row.avance    :=c.avance        ;
                    l_row.no_regla  :=c.no_regla      ;
                    l_row.estatus  :=c.estatus        ;      
                    l_row.materias_para :=c.materias_para;    
                    l_row.materias_horarios :=c.materias_horarios;
                    pipe row (l_row);
              
                END LOOP;
        RETURN;  
  END;
 
--
--
    function f_mate_alian_a(p_regla number) return t_mat_alian_a pipelined
    is l_row t_materias_alianza_a;
    
        l_regla_anterior number;
        l_cuenta_materias NUMBER;
        l_contador number:=0;
        
    begin
        
        begin
            select max(sztalgo_no_regla)
            into l_regla_anterior
            from sztalgo a
            where 1 = 1
            AND a.SZTALGO_PTRM_CODE_NEW ='L0A'
            and a.sztalgo_estatus_cerrado ='S'
            AND EXISTS (SELECT NULL
                        FROM SZTALGO b
                        WHERE 1 = 1
                        AND b.SZTALGO_NO_REGLA = p_regla
                        and a.SZTALGO_CAMP_CODE= b.SZTALGO_CAMP_CODE
                        and a.SZTALGO_LEVL_CODE = b.SZTALGO_LEVL_CODE);
        exception when others then
            null; 
        end;               
        
       BEGIN
       
           select distinct ZSTPARA_PARAM_VALOR
           into l_cuenta_materias
           from ZSTPARA
           where 1 = 1
           and ZSTPARA_MAPA_ID ='MATERIA_UNICEF'
           and ZSTPARA_PARAM_ID = p_regla; 
       EXCEPTION WHEN OTHERS THEN
           l_cuenta_materias:=1;
       END;   
       
       l_contador:=0; 
        
       FOR C IN
            (
            SELECT materia_legal,
                   'UNICEF' alianza,
                   l_regla_anterior regla
            FROM
            (
                SELECT DISTINCT  ZSTPARA_PARAM_ID materia_legal
                FROM zstpara
                WHERE 1 = 1
                AND zstpara_mapa_id ='MATERIAS_IEBS'
                AND zstpara_param_id like 'UNI%'
--                and ZSTPARA_PARAM_DESC ='NO'
                AND SUBSTR(zstpara_param_id,5,1)='L'
                MINUS
                SELECT *
                FROM
                (
                select sztprono_materia_legal materia_legal
                from sztprono
                where 1 = 1
                and sztprono_no_regla =l_regla_anterior
                and sztprono_materia_legal like 'UNI%'
                )
                ORDER BY 1
                )
            )LOOP
            
                  l_contador:=l_contador+1;
            
                  l_row.materia_legal:= c.materia_legal;
                  l_row.alianza := c.alianza;
                  l_row.regla_anterior := c.regla;
                        
                  pipe row (l_row);
                    
                  EXIT WHEN l_contador = l_cuenta_materias;
            
            END LOOP;
        
            l_contador:=0;
       
            FOR C IN
            (
            SELECT materia_legal,
                   'IEBS' alianza,
                   l_regla_anterior regla
            FROM
            (
                SELECT DISTINCT  ZSTPARA_PARAM_ID materia_legal
                FROM zstpara
                WHERE 1 = 1
                AND zstpara_mapa_id ='MATERIAS_IEBS'
                AND zstpara_param_id like 'IEBS%'
--                and ZSTPARA_PARAM_DESC ='NO'
                AND SUBSTR(zstpara_param_id,5,1)='L'
                AND ZSTPARA_PARAM_ID NOT IN ('IEBSL01','IEBSL03')
                MINUS
                SELECT *
                FROM
                (
                select sztprono_materia_legal materia_legal
                from sztprono
                where 1 = 1
                and sztprono_no_regla =l_regla_anterior
                and sztprono_materia_legal like 'IEBS%'
                )
                ORDER BY 1
                )
            )LOOP
            
                  l_contador:=l_contador+1;
            
                  l_row.materia_legal:= c.materia_legal;
                  l_row.alianza := c.alianza;
                  l_row.regla_anterior := c.regla;
                        
                  pipe row (l_row);
                    
                  EXIT WHEN l_contador = 1;
            
            END LOOP;
       
    
        
            
    
        RETURN;  
    END;
--
--
FUNCTION get_documentos(p_CAMPUS VARCHAR2,P_NIVEL VARCHAR2,P_PROGRAMA VARCHAR2 ) RETURN t_docu PIPELINED is
    l_row  T_TDOCUMEN;
    
          
     
    BEGIN
        
        for c in 
        (
         SELECT  DISTINCT
          NVL(Campus,'NA')Campus,
          NVL(Nivel,'NA')Nivel,
          periodo_de_catalogo,
          NVL(Programa,'NA')Programa,
          NVL(Descripcion_Programa,'NA')Descripcion_Programa,
          NVL(Matricula,'NA')Matricula,
          NVL(nombre,'NA')nombre,
          NVL(Tipo_de_ingreso,'NA')Tipo_de_ingreso,
          NVL(Estatus,'NA')Estatus,
          NVL(Decision,0)Decision,
          NVL(usuario_decision,'NA')usuario_decision,    
          NVL(TO_CHAR(Fecha_decision,'YYYY/MM/DD'),'1900/01/01')Fecha_decision,
          NVL(TO_CHAR(Fecha_Inicio,'YYYY/MM/DD'),'1900/01/01')Fecha_Inicio,
          Acta_Orig,
          Fecha_Acta_Orig,
          Certificado_Parcial,
          Fecha_Certificado_Parcial,
          Carta_Compromiso_Orig,
          Fecha_Carta_Compromiso_Orig,
          Carta_Autentic_Certi_Bach_Orig,
          F_Carta_Aut_Certi_Bach_Orig,
          Carta_Protes_Decir_Verdad_Orig,
          Fecha_Car_Prot_Decir_Verd_Orig,
          Carta_Responsiva_Orig,
          Fecha_Carta_Responsiva_Orig,
          Certificado_De_Secundaria_Orig,
          Fecha_Certif_De_Sec_Orig,        
          Cert_Total_Bachillerat_Orig,
          Fecha_Cert_Total_Bach_Orig,
          Certif_Tot_Lic_Orig,
          Fecha_Cert_Tot_Lic_Orig,
          Cert_Tot_Maes_Orig,
          Fecha_Cert_Tot_Maes_Orig,
          Cert_Tot_Especial_Orig,
          Fecha_Cert_Tot_Especial_Orig, 
          Cert_Tot_Lic_AP_Orig,
          Fecha_Cert_Tot_Lic_AP__Orig,
          Cert_Diploma_Titu_Orig,
          Fecha_Cert_Diploma_Titu_Orig,
          Equivalencia_De_Estudios_Orig,
          Fecha_Equiv_De_Estudios_Orig,
          Fotografias_Infantil_4_BN_M,
          Fecha_Foto_Infantil_4_BN_M,
          Fotografias_Infantil_6_BN_M,
          Fecha_Foto_Infantil_6_BN_M,
          Fotografias_Cert_4_Ova_Creden,
          Fecha_Foto_Cert_4_Ova_Creden,
          Fotografias_Titulo_6_b_n,
          Fecha_Fotografias_Titulo_6_b_n, 
          Formato_Inscripcion_Alumn_Orig,
          Fecha_Form_Inscr_Alumn_Orig,
          Constancia_Laboral_Original,
          Fecha_Const_Laboral_Orig,
          Acta_De_Nacimiento_Digital,
          Fecha_Acta_De_Nac_Digital,
          Carta_Autentic_Certi_Ba_Dig,
          Fecha_Car_Auten_Certi_Ba_Dig,
          Carta_Motivos_Digital,
          Fecha_Carta_Motivos_Digital,
          Carta_Protes_Decir_Verdad_Dig,
          Fecha_Cart_Prot_Decir_Verd_Dig,
          Constancia_Laboral_Digital,
          Fecha_Const_Lab_Dig,
          Carta_Compromiso,
          Fecha_Carta_Comp,
          Certificado_De_Secundaria_Dig,
          Fecha_Cert_De_Secundaria_Dig,
          Cert_Total_Bachillerat_Dig,
          Fecha_Cert_Total_Bach_Dig,
          Certificado_Total_Lic_Dig,
          Fecha_Certificado_Tot_Lic_Dig,
          Certificado_Total_Maestria_Dig,
          Fecha_Cert_Total_Maestria_Dig,
          Cert_Tot_Especial_Dig,
          Fecha_Cert_Tot_Especial_Dig,
          Cert_Tot_Lic_AP_Dig,
          Fecha_Cert_Tot_Lic_AP__Dig, 
          Cert_Diploma_Titu_Dig,
          Fecha_Cert_Diploma_Titu_Dig, 
          Pago,
          Fecha_Pago,
          Ultimo_Grado_De_Estud,
          Fecha_Ultimo_Grado_De_Estud,
          Cedula_De_Grado_Digital,
          Fecha_Cedula_De_Grado_Dig,
          Cedula_Profesional_Digital,
          Fecha_Cedula_Profesional_Dig,
          Comprobante_De_Domicilio,
          Fecha_Comp_De_Dom,
          CURP,
          Fecha_CURP,
          Titulo_Digital,
          Fecha_Titulo_Digital,
          Grado_Digital,
          Fecha_Grado_Digital, 
          Equivalencia_De_Estudios_Dig,
          Fecha_Equiv_De_Estudios_Dig,
          Formato_Inscripcion_Alumn_Dig,
          Fecha_Formato_Inscr_Alumn_Dig,
          Identificacion_Oficial,
          Fecha_Identificacion_Oficial,
          Predictamen_De_Equivalencia,
          Fecha_Predictamen_De_Equiv,
          Solicitud_De_Admision,
          Fecha_Solicitud_De_Admision,
          Carta_Poder,
          Fecha_Solicitud_Carta_Poder,
          Dictamen_Revalidacion_Org,
          Fech_Dic_Rev_Org,
          Dictamen_Revalidacion_Dig,
          Fech_Dict_Reval_Dig,
          Dictamen_Sep_Dig, 
          Fech_Dict_Sep_Dig,
          Dictamen_Sep_Original,
          Fech_Dictamen_Sep_Ori,
          Email,
          Estatus_egreso
FROM (
with decision1 as  (SELECT distinct    
                                 d.sarappd_pidm PIDM,
                                 p.saradap_program_1 PROGRAMA,
                                 d.sarappd_apdc_code decision,
                                 d.sarappd_user usuario,
                                 d.sarappd_apdc_date fecha_des,
                                 p.saradap_term_code_entry periodo,
                                 p.saradap_curr_rule_1 currule
                                FROM sarappd d,saradap p
                                 WHERE 1=1
                                 AND d.sarappd_pidm=p.saradap_pidm
                                 AND d.sarappd_appl_no=p.saradap_appl_no
                                 and d.sarappd_term_code_entry=p.saradap_term_code_entry
                                 AND p.saradap_appl_no=(SELECT MAX(a1.saradap_appl_no)
                                                       FROM SARADAP a1
                                                       WHERE 1=1
                                                       AND a1.saradap_pidm = p.saradap_pidm
                                                       )
                                 AND d.sarappd_appl_no =(SELECT MAX (c1.sarappd_appl_no)
                                                        FROM sarappd c1
                                                        WHERE 1=1
                                                        AND d.sarappd_pidm = c1.sarappd_pidm
                                                        AND d.sarappd_term_code_entry = c1.sarappd_term_code_entry)
                                 AND d.sarappd_seq_no=(SELECT MAX (c1.sarappd_seq_no)
                                                        FROM sarappd c1
                                                        WHERE 1=1
                                                        AND c1.sarappd_pidm=d.sarappd_pidm  
                                                        AND c1.sarappd_term_code_entry=d.sarappd_term_code_entry)                   
                  )       
        SELECT DISTINCT 
                   a.SORLCUR_CAMP_CODE Campus,
                   a.SORLCUR_LEVL_CODE Nivel,
                   a.SORLCUR_TERM_CODE_CTLG periodo_de_catalogo,
                   a.SORLCUR_PROGRAM Programa,
                   rle.SMRPRLE_PROGRAM_DESC Descripcion_Programa,
                   d.spriden_id Matricula,
                   d.SPRIDEN_LAST_NAME||d.SPRIDEN_FIRST_NAME nombre,      
                   STVSTYP_DESC Tipo_de_ingreso,
                   (select st.STVSTST_DESC
                           from STVSTST st
                           where 1=1
                           AND tdn.sgbstdn_stst_code=st.stvstst_code) Estatus,
                        des.decision decision,
                        des.usuario usuario_decision,
                        des.fecha_des fecha_Decision,
                   a.SORLCUR_START_DATE Fecha_Inicio,
                   nvl((select max( SARCHKL_CKST_CODE)
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACNO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Acta_Orig,
                   nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACNO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Acta_Orig,                        
                        nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPLO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_Parcial,                       
                        nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPLO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Certificado_Parcial,                       
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Compromiso_Orig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Compromiso_Orig,     
                   nvl((select MAX(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CALO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Autentic_Certi_Bach_Orig,
                   nvl((select MAX(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CALO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') F_Carta_Aut_Certi_Bach_Orig,
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Protes_Decir_Verdad_Orig,
                    nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Car_Prot_Decir_Verd_Orig,
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CRDO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Responsiva_Orig,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CRDO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                             AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Responsiva_Orig,
                   nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_De_Secundaria_Orig,
                    nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Certif_De_Sec_Orig,
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBO')                     
                          and SARCHKL_PIDM =a.sorlcur_pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM                         
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Total_Bachillerat_Orig,
                   nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBO')
                         and SARCHKL_PIDM =a.sorlcur_pidm                       
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Total_Bach_Orig,
                   nvl((select max( SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                      AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certif_Tot_Lic_Orig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Lic_Orig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Maes_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Maes_Orig,                         
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTEO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Especial_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTEO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Especial_Orig,                      
                      nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Lic_AP_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Lic_AP__Orig,                        
                     nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Diploma_Titu_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Diploma_Titu_Orig,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQIO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Equivalencia_De_Estudios_Orig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQIO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Equiv_De_Estudios_Orig,
                    nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO4O')
                          and SARCHKL_PIDM =a.sorlcur_pidm                     
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Fotografias_Infantil_4_BN_M,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO4O')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Foto_Infantil_4_BN_M,
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO6O')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Fotografias_Infantil_6_BN_M,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO6O')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Foto_Infantil_6_BN_M,
                    nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FCOO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Fotografias_Cert_4_Ova_Creden,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FCOO')
                          and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Foto_Cert_4_Ova_Creden,
                    nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FT6O')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Fotografias_Titulo_6_b_n,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FT6O')
                          and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Fotografias_Titulo_6_b_n,              
                     nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILO')
                          and SARCHKL_PIDM =a.sorlcur_pidm
                            AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Formato_Inscripcion_Alumn_Orig,
                     nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILO')
                           and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Form_Inscr_Alumn_Orig,
                     nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Constancia_Laboral_Original,
                     nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Const_Laboral_Orig,
                     nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACND')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Acta_De_Nacimiento_Digital,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACND')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Acta_De_Nac_Digital,
                   nvl((select  max(SARCHKL_CKST_CODE)
                         from SARCHKL,SARAPPD
                         where SARCHKL_ADMR_CODE in ('CALD')
                           and SARCHKL_PIDM =a.sorlcur_pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Autentic_Certi_Ba_Dig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CALD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Car_Auten_Certi_Ba_Dig,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAMD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Motivos_Digital,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAMD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Motivos_Digital,
                   nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Protes_Decir_Verdad_Dig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cart_Prot_Decir_Verd_Dig,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Constancia_Laboral_Digital,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Const_Lab_Dig,
                  nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Compromiso,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Comp,
                  nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_De_Secundaria_Dig,
                  nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_De_Secundaria_Dig,              
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBD')
                       and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Cert_Total_Bachillerat_Dig,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Total_Bach_Dig,
                 nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_Total_Lic_Dig,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Certificado_Tot_Lic_Dig,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_Total_Maestria_Dig,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Total_Maestria_Dig,  
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTED')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Especial_Dig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTED')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Especial_Dig,                      
                      nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Lic_AP_Dig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Lic_AP__Dig,                        
                     nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Diploma_Titu_Dig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Diploma_Titu_Dig,      
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('PAGD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                            AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Pago,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('PAGD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Pago,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CUGD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Ultimo_Grado_De_Estud,
                 nvl((select max (to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CUGD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Ultimo_Grado_De_Estud,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEGD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cedula_De_Grado_Digital,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEGD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cedula_De_Grado_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEPD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cedula_Profesional_Digital,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEPD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                            AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cedula_Profesional_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CODD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Comprobante_De_Domicilio,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CODD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Comp_De_Dom,
                 nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CURD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') CURP,
                 nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CURD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_CURP,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('TITD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Titulo_Digital,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('TITD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Titulo_Digital,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('GRAD')
                          and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Grado_Digital,
                 nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('GRAD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Grado_Digital,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQUD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Equivalencia_De_Estudios_Dig,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQUD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Equiv_De_Estudios_Dig,
                 nvl((select  max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Formato_Inscripcion_Alumn_Dig,
                 nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Formato_Inscr_Alumn_Dig,
                 nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('IDOD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Identificacion_Oficial,
                 nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('IDOD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Identificacion_Oficial,
                 nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('PRED')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Predictamen_De_Equivalencia,
                 nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL, SARAPPD
                        where SARCHKL_ADMR_CODE in ('PRED')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Predictamen_De_Equiv,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('SOAD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Solicitud_De_Admision,
                 nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('SOAD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Solicitud_De_Admision,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAPO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Carta_Poder,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAPO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Solicitud_Carta_Poder,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Revalidacion_Org,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dic_Rev_Org,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRV')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Revalidacion_Dig,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRV')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dict_Reval_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Sep_Dig,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dict_Sep_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Sep_Original,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dictamen_Sep_Ori,
                   NVL((SELECT  MAX (gore.goremal_email_address)
                                               FROM goremal gore
                                              WHERE gore.goremal_pidm=spriden_pidm 
                                                AND gore.goremal_emal_code = 'PRIN'
                                                AND gore.goremal_status_ind = 'A'
                                                AND gore.goremal_surrogate_id =(SELECT  MAX (gore1.goremal_surrogate_id)
                                                                                        FROM goremal gore1
                                                                                       WHERE 1=1
                                                                                         AND gore.goremal_pidm =gore1.goremal_pidm
                                                                                         AND gore.goremal_emal_code =gore1.goremal_emal_code
                                                                                         AND gore.goremal_status_ind =gore1.goremal_status_ind)) , 'NA') Email,
                    NVL((SELECT MAX(SARACMT_COMMENT_TEXT )
                                                FROM SARACMT 
                                               WHERE SARACMT_PIDM = SPRIDEN_PIDM 
                                                 AND SARACMT_ORIG_CODE in ('EGTL', 'EGEX', 'EGRE')),'NA') Estatus_egreso
--                    'PARTE1' PARTE    
            FROM sorlcur a,spriden d,smrprle rle,sgbstdn tdn,stvstyp b,sztdtec tec,decision1 des
           WHERE 1=1
             AND a.sorlcur_pidm = d.spriden_pidm(+)
             AND d.spriden_change_ind is null
             AND tec.sztdtec_camp_code = a.sorlcur_camp_code
             AND a.sorlcur_pidm =tdn.sgbstdn_pidm(+)
             AND a.sorlcur_program= tec.sztdtec_program(+)  
             AND tdn.sgbstdn_program_1= a.sorlcur_program
             AND a.sorlcur_pidm=des.pidm
             AND a.sorlcur_curr_rule=des.currule
             AND a.sorlcur_program=des.programa 
             AND a.sorlcur_lmod_code ='LEARNER'
--             and tdn.sgbstdn_term_code_eff=a.sorlcur_term_code     
             AND tdn.sgbstdn_activity_date=(SELECT  max(d1.sgbstdn_activity_date)
                                                   FROM sgbstdn d1
                                                  WHERE 1=1
                                                    AND d1.sgbstdn_pidm=tdn.sgbstdn_pidm
                                                    AND d1.sgbstdn_program_1=tdn.sgbstdn_program_1
                                                    AND d1.sgbstdn_term_code_eff= tdn.sgbstdn_term_code_eff
                                                    )
             AND a.sorlcur_program=rle.smrprle_program 
             AND tdn.sgbstdn_styp_code= b.stvstyp_code (+)   
             AND tdn.sgbstdn_term_code_eff=(SELECT MAX( d1.sgbstdn_term_code_eff)
                                                   FROM sgbstdn d1
                                                  WHERE 1=1
                                                    AND d1.sgbstdn_pidm=tdn.sgbstdn_pidm
                                                    AND d1.sgbstdn_program_1=tdn.sgbstdn_program_1
                                                    AND d1.sgbstdn_levl_code=tdn.sgbstdn_levl_code 
                                                    )        
             AND a.sorlcur_seqno=(SELECT MAX(a1.sorlcur_seqno)
                                             FROM sorlcur a1
                                            WHERE 1=1
                                              AND a1.sorlcur_pidm= a.sorlcur_pidm
                                              AND a1.sorlcur_program =a.sorlcur_program
                                              AND a1.sorlcur_term_code=a.sorlcur_term_code
                                              and a1.SORLCUR_LMOD_CODE = 'LEARNER'
                                              )     
             AND a.sorlcur_key_seqno=(SELECT MAX(a1.sorlcur_key_seqno)
                                      FROM sorlcur a1
                                     WHERE 1=1
                                       AND a1.sorlcur_pidm= a.sorlcur_pidm
                                       AND a1.sorlcur_program =a.sorlcur_program
                                       AND a1.sorlcur_term_code=a.sorlcur_term_code
                                       AND a1.sorlcur_lmod_code='LEARNER')   
             AND a.SORLCUR_TERM_CODE = (SELECT MAX (a1.SORLCUR_TERM_CODE) 
                                          FROM sorlcur a1
                                         WHERE 1=1
                                           and a.sorlcur_pidm  = a1.sorlcur_pidm 
                                           AND a.SORLCUR_KEY_SEQNO = a1.SORLCUR_KEY_SEQNO
                                           AND a.sorlcur_program = a1.sorlcur_program
                                           )
--              and ( ( p_campus is not null and p_campus = a.sorlcur_camp_code) or p_campus is null )
--              and ( ( p_nivel is not null and p_nivel = a.sorlcur_levl_code) or p_campus is null )
--              and ( ( p_programa is not null and p_programa = a.sorlcur_program) or p_programa is null )
                AND a.sorlcur_camp_code  = NVL( p_campus,a.sorlcur_camp_code)
                 AND a.sorlcur_levl_code  = NVL( p_nivel,a.sorlcur_levl_code ) 
                 AND a.sorlcur_program    = NVL( p_programa,a.sorlcur_program)
      UNION
        SELECT DISTINCT 
                   a.SORLCUR_CAMP_CODE Campus,
                   a.SORLCUR_LEVL_CODE Nivel,
                   a.SORLCUR_TERM_CODE_CTLG periodo_de_catalogo,
                   a.SORLCUR_PROGRAM Programa,
                   rle.SMRPRLE_PROGRAM_DESC Descripcion_Programa,
                   c.spriden_id Matricula,
                   c.SPRIDEN_LAST_NAME||c.SPRIDEN_FIRST_NAME nombre,      
                   ( select STVSTYP_DESC
                             from STVSTYP,sgbstdn tdn
                             where 1=1
                             AND stvstyp_code=tdn.sgbstdn_styp_code
                             AND tdn.sgbstdn_pidm=a.sorlcur_pidm
                             AND tdn.sgbstdn_term_code_eff=a.sorlcur_term_code
                             AND tdn.sgbstdn_program_1= a.sorlcur_program )Tipo_de_ingreso,
                   (SELECT st.stvstst_desc
                            FROM stvstst st,sgbstdn tdn
                           WHERE 1=1
                             AND st.stvstst_code=tdn.sgbstdn_stst_code
                             AND tdn.sgbstdn_pidm=a.sorlcur_pidm
                             AND tdn.sgbstdn_term_code_eff=a.sorlcur_term_code
                             AND tdn.sgbstdn_program_1= a.sorlcur_program) Estatus,
                    d.SARAPPD_APDC_CODE Decision,
                    d.SARAPPD_USER usuario_decision, 
                    d.SARAPPD_APDC_DATE Fecha_decision,
                   a.SORLCUR_START_DATE Fecha_Inicio,
                  nvl((select max( SARCHKL_CKST_CODE)
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACNO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Acta_Orig,
                   nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACNO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Acta_Orig,                       
                        nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPLO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_Parcial,                       
                        nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPLO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Certificado_Parcial,                      
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Compromiso_Orig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Compromiso_Orig,
                   nvl((select MAX(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CALO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Autentic_Certi_Bach_Orig,
                   nvl((select MAX(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CALO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') F_Carta_Aut_Certi_Bach_Orig,                    
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Protes_Decir_Verdad_Orig,
                    nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Car_Prot_Decir_Verd_Orig,
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CRDO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Responsiva_Orig,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CRDO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                             AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Responsiva_Orig,
                    nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_De_Secundaria_Orig,
                    nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Certif_De_Sec_Orig,    
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBO')                     
                          and SARCHKL_PIDM =a.sorlcur_pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM                         
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Total_Bachillerat_Orig,
                   nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBO')
                         and SARCHKL_PIDM =a.sorlcur_pidm                       
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Total_Bach_Orig,
                   nvl((select max( SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                      AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certif_Tot_Lic_Orig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Lic_Orig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Maes_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Maes_Orig,                         
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTEO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Especial_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTEO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Especial_Orig,                      
                      nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Lic_AP_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Lic_AP__Orig,                        
                     nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Diploma_Titu_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Diploma_Titu_Orig,                       
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQIO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Equivalencia_De_Estudios_Orig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQIO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Equiv_De_Estudios_Orig,
                    nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO4O')
                          and SARCHKL_PIDM =a.sorlcur_pidm                     
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Fotografias_Infantil_4_BN_M,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO4O')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Foto_Infantil_4_BN_M,
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO6O')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Fotografias_Infantil_6_BN_M,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO6O')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Foto_Infantil_6_BN_M,
                    nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FCOO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Fotografias_Cert_4_Ova_Creden,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FCOO')
                          and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Foto_Cert_4_Ova_Creden,
                    nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FT6O')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Fotografias_Titulo_6_b_n,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FT6O')
                          and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fecha_Fotografias_Titulo_6_b_n,          
                     nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILO')
                          and SARCHKL_PIDM =a.sorlcur_pidm
                            AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Formato_Inscripcion_Alumn_Orig,
                     nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILO')
                           and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Form_Inscr_Alumn_Orig,
                     nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Constancia_Laboral_Original,
                     nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Const_Laboral_Orig,
                     nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACND')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Acta_De_Nacimiento_Digital,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACND')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Acta_De_Nac_Digital,
                   nvl((select  max(SARCHKL_CKST_CODE)
                         from SARCHKL,SARAPPD
                         where SARCHKL_ADMR_CODE in ('CALD')
                           and SARCHKL_PIDM =a.sorlcur_pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Autentic_Certi_Ba_Dig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CALD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Car_Auten_Certi_Ba_Dig,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAMD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Motivos_Digital,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAMD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Motivos_Digital,
                   nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Protes_Decir_Verdad_Dig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cart_Prot_Decir_Verd_Dig,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Constancia_Laboral_Digital,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Const_Lab_Dig,
                  nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Compromiso,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Comp,
                  nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_De_Secundaria,
                  nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_De_Secundaria,        
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBD')
                       and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Total_Bachillerat_Digita,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Total_Bach_Dig,
                 nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_Total_Lic_Dig,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Certificado_Tot_Lic_Dig,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_Total_Maestria_Dig,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Total_Maestria_Dig,      
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTED')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Especial_Dig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTED')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Especial_Dig,                      
                      nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Lic_AP_Dig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Lic_AP__Dig,                        
                     nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Diploma_Titu_Dig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Diploma_Titu_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('PAGD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                            AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Pago,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('PAGD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Pago,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CUGD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Ultimo_Grado_De_Estud,
                 nvl((select max (to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CUGD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Ultimo_Grado_De_Estud,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEGD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cedula_De_Grado_Digital,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEGD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cedula_De_Grado_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEPD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cedula_Profesional_Digital,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEPD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                            AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cedula_Profesional_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CODD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Comprobante_De_Domicilio,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CODD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Comp_De_Dom,
                 nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CURD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') CURP,
                 nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CURD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_CURP,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('TITD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Titulo_Digital,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('TITD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Titulo_Digital,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('GRAD')
                          and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Grado_Digital,
                 nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('GRAD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Grado_Digital,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQUD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Equivalencia_De_Estudios_Dig,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQUD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Equiv_De_Estudios_Dig,
                 nvl((select  max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Formato_Inscripcion_Alumn_Dig,
                 nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Formato_Inscr_Alumn_Dig,
                 nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('IDOD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Identificacion_Oficial,
                 nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('IDOD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Identificacion_Oficial,
                 nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('PRED')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Predictamen_De_Equivalencia,
                 nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL, SARAPPD
                        where SARCHKL_ADMR_CODE in ('PRED')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Predictamen_De_Equiv,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('SOAD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Solicitud_De_Admision,
                 nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('SOAD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Solicitud_De_Admision,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAPO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Carta_Poder,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAPO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Solicitud_Carta_Poder,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRO')   
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Revalidacion_Org,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dic_Rev_Org,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRV')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Revalidacion_Dig,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRV')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dict_Reval_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICD')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Sep_Dig,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICD')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dict_Sep_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICO')
                         and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Sep_Original,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICO')
                        and SARCHKL_PIDM =a.sorlcur_pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dictamen_Sep_Ori,
                   NVL((SELECT  MAX (gore.goremal_email_address)
                                               FROM goremal gore
                                              WHERE gore.goremal_pidm=spriden_pidm 
                                                AND gore.goremal_emal_code = 'PRIN'
                                                AND gore.goremal_status_ind = 'A'
                                                AND gore.goremal_surrogate_id =(SELECT  MAX (gore1.goremal_surrogate_id)
                                                                                        FROM goremal gore1
                                                                                       WHERE 1=1
                                                                                         AND gore.goremal_pidm =gore1.goremal_pidm
                                                                                         AND gore.goremal_emal_code =gore1.goremal_emal_code
                                                                                         AND gore.goremal_status_ind =gore1.goremal_status_ind)) , 'NA') Email,
                    NVL((SELECT MAX(SARACMT_COMMENT_TEXT )
                                                FROM SARACMT 
                                               WHERE SARACMT_PIDM = SPRIDEN_PIDM 
                                                 AND SARACMT_ORIG_CODE in ('EGTL', 'EGEX', 'EGRE')),'NA') Estatus_egreso
--                    'PARTE2' PARTE                                  
           FROM sorlcur a, spriden c,smrprle rle,saradap p,sarappd d
           WHERE 1=1
           AND a.sorlcur_pidm = c.spriden_pidm(+)
           AND c.spriden_change_ind is null
           AND a.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
                            FROM sorlcur c1
                            WHERE 1=1
                            AND a.sorlcur_pidm= c1.sorlcur_pidm
                            AND a.sorlcur_program = c1.sorlcur_program)     
             AND a.sorlcur_program= rle.smrprle_program
             AND a.sorlcur_pidm = p.saradap_pidm
             AND P.SARADAP_PIDM = d.SARAPPD_PIDM
             AND d.sarappd_pidm=p.saradap_pidm
                                 AND p.saradap_appl_no=(SELECT MAX(a1.saradap_appl_no)
                                                       FROM SARADAP a1
                                                       WHERE 1=1
                                                       AND a1.saradap_pidm = p.saradap_pidm
                                                       and a1.SARADAP_PROGRAM_1=p.SARADAP_PROGRAM_1
                                                       )
                                 AND d.sarappd_appl_no =(SELECT MAX (c1.sarappd_appl_no)
                                                        FROM sarappd c1
                                                        WHERE 1=1
                                                        AND d.sarappd_pidm = c1.sarappd_pidm
                                                        )
                                 AND d.sarappd_seq_no=(SELECT MAX (c1.sarappd_seq_no)
                                                        FROM sarappd c1
                                                        WHERE 1=1
                                                        AND c1.sarappd_pidm=d.sarappd_pidm
                                                        and d.sarappd_appl_no=c1.sarappd_appl_no  
                                                        ) 
--                 and ( ( p_campus is not null and p_campus = a.sorlcur_camp_code) or p_campus is null )
--                 and ( ( p_nivel is not null and p_nivel = a.sorlcur_levl_code) or p_campus is null )
--                 and ( ( p_programa is not null and p_programa = a.sorlcur_program) or p_programa is null )
                 AND a.sorlcur_camp_code  = NVL( p_campus,a.sorlcur_camp_code)
                 AND a.sorlcur_levl_code  = NVL( p_nivel,a.sorlcur_levl_code ) 
                 AND a.sorlcur_program    = NVL( p_programa,a.sorlcur_program)
     )
                 )
                 
                 loop
                              l_row.campus                 := c.Campus;
                              l_row.Nivel                  := c.Nivel;
                              l_row.periodo_de_catalogo    := c.periodo_de_catalogo;
                              l_row.Programa               := c.Programa;                           
                              l_row.Descripcion_Programa   := c.Descripcion_Programa;
                              l_row.Matricula              := c.Matricula;
                              l_row.nombre                 := c.nombre;
                              l_row.Tipo_de_ingreso        := c.Tipo_de_ingreso;
                              l_row.Estatus                := c.Estatus;
                              l_row.Decision               := c.Decision;
                              l_row.usuario_decision       := c.usuario_decision;
                              l_row.Fecha_decision         := c.Fecha_decision;
                              l_row.Fecha_Inicio           := c.Fecha_Inicio;
                              l_row.Acta_Orig              := c.Acta_Orig;
                              l_row.Fecha_Acta_Orig        := c.Fecha_Acta_Orig;
                              l_row.Certificado_Parcial    := c.Certificado_Parcial;
                              l_row.Fecha_Certificado_Parcial := c.Fecha_Certificado_Parcial;
                              l_row.Carta_Compromiso_Orig          := c.Carta_Compromiso_Orig;
                              l_row.Fecha_Carta_Compromiso_Orig    := c.Fecha_Carta_Compromiso_Orig;
                              l_row.Carta_Autentic_Certi_Bach_Orig := c.Carta_Autentic_Certi_Bach_Orig;
                              l_row.F_Carta_Aut_Certi_Bach_Orig    := c.F_Carta_Aut_Certi_Bach_Orig;
                              l_row.Carta_Protes_Decir_Verdad_Orig := c.Carta_Protes_Decir_Verdad_Orig;
                              l_row.Fecha_Car_Prot_Decir_Verd_Orig := c.Fecha_Car_Prot_Decir_Verd_Orig;
                              l_row.Carta_Responsiva_Orig          := c.Carta_Responsiva_Orig;
                              l_row.Fecha_Carta_Responsiva_Orig    := c.Fecha_Carta_Responsiva_Orig;
                              l_row.Certificado_De_Secundaria_Orig := c.Certificado_De_Secundaria_Orig;
                              l_row.Fecha_Certif_De_Sec_Orig       := c.Fecha_Certif_De_Sec_Orig;       
                              l_row.Cert_Total_Bachillerat_Orig    := c.Cert_Total_Bachillerat_Orig;
                              l_row.Fecha_Cert_Total_Bach_Orig     := c.Fecha_Cert_Total_Bach_Orig;
                              l_row.Certif_Tot_Lic_Orig            := c.Certif_Tot_Lic_Orig;
                              l_row.Fecha_Cert_Tot_Lic_Orig        := c.Fecha_Cert_Tot_Lic_Orig;
                              l_row.Cert_Tot_Maes_Orig             := c.Cert_Tot_Maes_Orig;
                              l_row.Fecha_Cert_Tot_Maes_Orig       := c.Fecha_Cert_Tot_Maes_Orig;
                              l_row.Cert_Tot_Especial_Orig         := c.Cert_Tot_Especial_Orig;
                              l_row.Fecha_Cert_Tot_Especial_Orig   := c.Fecha_Cert_Tot_Especial_Orig;
                              l_row.Cert_Tot_Lic_AP_Orig           := c.Cert_Tot_Lic_AP_Orig;
                              l_row.Fecha_Cert_Tot_Lic_AP__Orig    := c.Fecha_Cert_Tot_Lic_AP__Orig;
                              l_row.Cert_Diploma_Titu_Orig         := c.Cert_Diploma_Titu_Orig;
                              l_row.Fecha_Cert_Diploma_Titu_Orig   := c.Fecha_Cert_Diploma_Titu_Orig;
                              l_row.Equivalencia_De_Estudios_Orig  := c.Equivalencia_De_Estudios_Orig;
                              l_row.Fecha_Equiv_De_Estudios_Orig   := c.Fecha_Equiv_De_Estudios_Orig;
                              l_row.Fotografias_Infantil_4_BN_M    := c.Fotografias_Infantil_4_BN_M;
                              l_row.Fecha_Foto_Infantil_4_BN_M     := c.Fecha_Foto_Infantil_4_BN_M;
                              l_row.Fotografias_Infantil_6_BN_M    := c.Fotografias_Infantil_6_BN_M;
                              l_row.Fecha_Foto_Infantil_6_BN_M     := c.Fecha_Foto_Infantil_6_BN_M;
                              l_row.Fotografias_Cert_4_Ova_Creden  := c.Fotografias_Cert_4_Ova_Creden;
                              l_row.Fecha_Foto_Cert_4_Ova_Creden   := c.Fecha_Foto_Cert_4_Ova_Creden;
                              l_row.Fotografias_Titulo_6_b_n       := c.Fotografias_Titulo_6_b_n;
                              l_row.Fecha_Fotografias_Titulo_6_b_n := c.Fecha_Fotografias_Titulo_6_b_n;
                              l_row.Formato_Inscripcion_Alumn_Orig := c.Formato_Inscripcion_Alumn_Orig;
                              l_row.Fecha_Form_Inscr_Alumn_Orig    := c.Fecha_Form_Inscr_Alumn_Orig;
                              l_row.Constancia_Laboral_Original    := c.Constancia_Laboral_Original;
                              l_row.Fecha_Const_Laboral_Orig       := c.Fecha_Const_Laboral_Orig;
                              l_row.Acta_De_Nacimiento_Digital     := c.Acta_De_Nacimiento_Digital;
                              l_row.Fecha_Acta_De_Nac_Digital      := c.Fecha_Acta_De_Nac_Digital;
                              l_row.Carta_Autentic_Certi_Ba_Dig    := c.Carta_Autentic_Certi_Ba_Dig;
                              l_row.Fecha_Car_Auten_Certi_Ba_Dig   := c.Fecha_Car_Auten_Certi_Ba_Dig;
                              l_row.Carta_Motivos_Digital          := c.Carta_Motivos_Digital;
                              l_row.Fecha_Carta_Motivos_Digital    := c.Fecha_Carta_Motivos_Digital;
                              l_row.Carta_Protes_Decir_Verdad_Dig  := c.Carta_Protes_Decir_Verdad_Dig;
                              l_row.Fecha_Cart_Prot_Decir_Verd_Dig := c.Fecha_Cart_Prot_Decir_Verd_Dig;
                              l_row.Constancia_Laboral_Digital     := c.Constancia_Laboral_Digital;
                              l_row.Fecha_Const_Lab_Dig            := c.Fecha_Const_Lab_Dig;
                              l_row.Carta_Compromiso               := c.Carta_Compromiso;
                              l_row.Fecha_Carta_Comp               := c.Fecha_Carta_Comp;
                              l_row.Certificado_De_Secundaria_Dig  := c.Certificado_De_Secundaria_Dig;
                              l_row.Fecha_Cert_De_Secundaria_Dig   := c.Fecha_Cert_De_Secundaria_Dig;
                              l_row.Cert_Total_Bachillerat_Dig     := c.Cert_Total_Bachillerat_Dig;
                              l_row.Fecha_Cert_Total_Bach_Dig      := c.Fecha_Cert_Total_Bach_Dig;
                              l_row.Certificado_Total_Lic_Dig      := c.Certificado_Total_Lic_Dig;
                              l_row.Fecha_Certificado_Tot_Lic_Dig  := c.Fecha_Certificado_Tot_Lic_Dig;
                              l_row.Certificado_Total_Maestria_Dig := c.Certificado_Total_Maestria_Dig;
                              l_row.Fecha_Cert_Total_Maestria_Dig  := c.Fecha_Cert_Total_Maestria_Dig;
                              l_row.Cert_Tot_Especial_Dig          := c.Cert_Tot_Especial_Dig;
                              l_row.Fecha_Cert_Tot_Especial_Dig    := c.Fecha_Cert_Tot_Especial_Dig;
                              l_row.Cert_Tot_Lic_AP_Dig            := c.Cert_Tot_Lic_AP_Dig;
                              l_row.Fecha_Cert_Tot_Lic_AP__Dig     := c.Fecha_Cert_Tot_Lic_AP__Dig; 
                              l_row.Cert_Diploma_Titu_Dig          := c.Cert_Diploma_Titu_Dig;
                              l_row.Fecha_Cert_Diploma_Titu_Dig    := c.Fecha_Cert_Diploma_Titu_Dig; 
                              l_row.Pago                           := c.Pago;
                              l_row.Fecha_Pago                     := c.Fecha_Pago;
                              l_row.Ultimo_Grado_De_Estud          := c.Ultimo_Grado_De_Estud;
                              l_row.Fecha_Ultimo_Grado_De_Estud    := c.Fecha_Ultimo_Grado_De_Estud;
                              l_row.Cedula_De_Grado_Digital        := c.Cedula_De_Grado_Digital;
                              l_row.Fecha_Cedula_De_Grado_Dig      := c.Fecha_Cedula_De_Grado_Dig;
                              l_row.Cedula_Profesional_Digital     := c.Cedula_Profesional_Digital;
                              l_row.Fecha_Cedula_Profesional_Dig   := c.Fecha_Cedula_Profesional_Dig;
                              l_row.Comprobante_De_Domicilio       := c.Comprobante_De_Domicilio;
                              l_row.Fecha_Comp_De_Dom              := c.Fecha_Comp_De_Dom;
                              l_row.CURP                           := c.CURP;
                              l_row.Fecha_CURP                     := c.Fecha_CURP;
                              l_row.Titulo_Digital                 := c.Titulo_Digital;
                              l_row.Fecha_Titulo_Digital           := c.Fecha_Titulo_Digital;
                              l_row.Grado_Digital                  := c.Grado_Digital;
                              l_row.Fecha_Grado_Digital            := c.Fecha_Grado_Digital; 
                              l_row.Equivalencia_De_Estudios_Dig   := c.Equivalencia_De_Estudios_Dig;
                              l_row.Fecha_Equiv_De_Estudios_Dig    := c.Fecha_Equiv_De_Estudios_Dig;
                              l_row.Formato_Inscripcion_Alumn_Dig  := c.Formato_Inscripcion_Alumn_Dig;
                              l_row.Fecha_Formato_Inscr_Alumn_Dig  := c.Fecha_Formato_Inscr_Alumn_Dig;
                              l_row.Identificacion_Oficial         := c.Identificacion_Oficial;
                              l_row.Fecha_Identificacion_Oficial   := c.Fecha_Identificacion_Oficial;
                              l_row.Predictamen_De_Equivalencia    := c.Predictamen_De_Equivalencia;
                              l_row.Fecha_Predictamen_De_Equiv     := c.Fecha_Predictamen_De_Equiv;
                              l_row.Solicitud_De_Admision          := c.Solicitud_De_Admision;
                              l_row.Fecha_Solicitud_De_Admision    := c.Fecha_Solicitud_De_Admision;
                              l_row.Carta_Poder                    := c.Carta_Poder;
                              l_row.Fecha_Solicitud_Carta_Poder    := c.Fecha_Solicitud_Carta_Poder;
                              l_row.Dictamen_Revalidacion_Org      := c.Dictamen_Revalidacion_Org;
                              l_row.Fech_Dic_Rev_Org               := c.Fech_Dic_Rev_Org;
                              l_row.Dictamen_Revalidacion_Dig      := c.Dictamen_Revalidacion_Dig;
                              l_row.Fech_Dict_Reval_Dig            := c.Fech_Dict_Reval_Dig;
                              l_row.Dictamen_Sep_Dig               := c.Dictamen_Sep_Dig;
                              l_row.Fech_Dict_Sep_Dig              := c.Fech_Dict_Sep_Dig;
                              l_row.Dictamen_Sep_Original          := c.Dictamen_Sep_Original;
                              l_row.Fech_Dictamen_Sep_Ori          := c.Fech_Dictamen_Sep_Ori;
                              l_row.Email                          := c.Email;
                              l_row.Estatus_egreso                 := c.Estatus_egreso;
                        PIPE ROW (l_row);
  
                 end loop;
    
        
        RETURN;
    END;
END pkg_funciones_pipelined;
/

DROP PUBLIC SYNONYM PKG_FUNCIONES_PIPELINED;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FUNCIONES_PIPELINED FOR BANINST1.PKG_FUNCIONES_PIPELINED;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_FUNCIONES_PIPELINED TO PUBLIC;
