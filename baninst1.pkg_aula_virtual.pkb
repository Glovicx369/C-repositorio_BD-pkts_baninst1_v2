DROP PACKAGE BODY BANINST1.PKG_AULA_VIRTUAL;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_AULA_VIRTUAL
IS
FUNCTION f_sps_out (p_matricula in varchar) RETURN PKG_AULA_VIRTUAL.sps_out
   AS
                s_out PKG_AULA_VIRTUAL.sps_out;
                lv_bloque VARCHAR2(5);
                lv_fecha_ini_sel DATE;
                lv_fecha_ini_sel_n DATE;
                lv_bimestre VARCHAR2(5);
                lv_fecha_fin_sel DATE;
                lv_nivel VARCHAR2(3);
                lv_fecha_inicio_curso DATE;
                lv_tipo_alumno VARCHAR2(3);
                lv_campus VARCHAR2(5);
                lv_fecha_ini DATE;

    BEGIN
          begin 
            SELECT a.campus,
                   to_date('01/01/2000','dd/mm/yyyy')
              into lv_campus, lv_fecha_ini_sel_n
              FROM tztprog a
             WHERE     a.matricula = p_matricula
                   AND a.sp IN (SELECT MAX (b.sp)
                                  FROM tztprog b
                                 WHERE b.matricula = a.matricula);
          EXCEPTION WHEN OTHERS THEN 
          lv_campus := null;
          end;
          
          
          begin 
                 SELECT bloque,
                        fecha_ini_sel,
                        bimestre,
                        fecha_fin_sel,
                        nivel,
                        fecha_inicio_curso ,
                        tipo_alumno
                  INTO lv_bloque,  
                       lv_fecha_ini_sel,
                       lv_bimestre,
                       lv_fecha_fin_sel,
                       lv_nivel,
                       lv_fecha_inicio_curso ,
                       lv_tipo_alumno
                  FROM( 
                           SELECT DISTINCT decode( SZTPRONO_PTRM_CODE,'L1E','B2','L2A','B2',SUBSTR (SZTPRONO_PTRM_CODE,3,1)) bloque,SZTALGO_FECHA_INICIO_INSC FECHA_INI_Sel,
                                   (SELECT SUM (BIMESTRE)
                                       FROM (select COUNT (distinct SFRSTCR_PTRM_CODE)BIMESTRE,SFRSTCR_term_CODE PERIODIO
                                                        from sfrstcr a
                                                        where 1 = 1
                                                        and a.SFRSTCR_RSTS_CODE ='RE'
                                                        and a.SFRSTCR_STSP_KEY_SEQUENCE =sp
                                                        and a.sfrstcr_pidm = SZTPRONO_PIDM
                                                        AND SUBSTR(A.sfrstcr_term_code,5,1)NOT IN(8,9)
                                                       GROUP BY SFRSTCR_term_CODE
                                                       ORDER BY 2 DESC))BIMESTRE,
                                                       SZTALGO_FECHA_FIN_INSC fecha_fin_Sel,
                                                       nivel, 
                                                       fecha_inicio fecha_inicio_Curso,
                                                       SGBSTDN_STYP_CODE Tipo_Alumno
                        FROM SZTPRONO, SZTGPME, tztprog,sztalgo
                        WHERE 1=1
                        AND SZTPRONO_MATERIA_LEGAL=SZTGPME_SUBJ_CRSE
                        AND PIDM=SZTPRONO_PIDM
                        AND SZTPRONO_PROGRAM=PROGRAMA
                        AND SZTPRONO_ID=p_matricula
                        and SZTPRONO_FECHA_INICIO=SZTALGO_FECHA_ANT
                        AND SZTGPME_START_DATE=SZTALGO_FECHA_ANT
                        and SZTPRONO_NO_REGLA=(select max (a.SZTPRONO_NO_REGLA)
                                                   from SZTPRONO a
                                                   where 1=1
                                                   and a.SZTPRONO_ID=p_matricula
                                                   and A.SZTPRONO_FECHA_INICIO=SZTALGO_FECHA_ANT)
                        and ESTATUS in ('MA')
                        order by SZTALGO_FECHA_INICIO_INSC desc)
                         WHERE 1=1
                         AND FECHA_INI_Sel IS NOT NULL
                         and rownum<=1;
          exception when others then 
           lv_bloque := null; 
           lv_fecha_ini_sel := null; 
           lv_bimestre := null; 
           lv_fecha_fin_sel := null; 
           lv_nivel := null; 
           lv_fecha_inicio_curso := null; 
           lv_tipo_alumno := null;                
          end;          
          
          if lv_fecha_ini_sel is null then 
          lv_fecha_ini := lv_fecha_ini_sel_n;
          else
          lv_fecha_ini := lv_fecha_ini_sel;
          end if;
          
                 open s_out
                 for
                    select  lv_bloque bloque,  
                       lv_fecha_ini fecha_ini_sel,
                       lv_bimestre bimestre,
                       lv_fecha_fin_sel fecha_fin_sel,
                       lv_campus campus,
                       lv_nivel nivel,
                       lv_fecha_inicio_curso fecha_inicio_curso ,
                       lv_tipo_alumno tipo_alumno
                      from dual;             
                     RETURN (s_out);
                     
            END f_sps_out;  
FUNCTION f_sps_curri_out (p_matricula in varchar,p_shortname in varchar) RETURN PKG_AULA_VIRTUAL.spscur_out
   AS
                sc_out PKG_AULA_VIRTUAL.spscur_out;

    BEGIN
                 open sc_out
                 for     
                       select decode((count(materia)),1,1,null,0)materia,decode(fecha_ini,null,sysdate,fecha_ini)fecha_ini
                       from(
                        select distinct a.SZTPRONO_MATERIA_LEGAL materia, a.SZTPRONO_FECHA_INICIO fecha_ini
                        FROM SZTPRONO a, SZTGPME b, tztprog c
                        WHERE 1=1
                        AND a.SZTPRONO_MATERIA_LEGAL=b.SZTGPME_SUBJ_CRSE
                        AND c.PIDM=a.SZTPRONO_PIDM
                        AND a.SZTPRONO_PROGRAM=c.PROGRAMA
                        and SZTGPME_START_DATE=SZTPRONO_FECHA_INICIO
                        AND SZTPRONO_ID= p_matricula--'010107368'
                        and ESTATUS in ('MA')
                        and SZTPRONO_ESTATUS_ERROR<>'S'
                          and a.SZTPRONO_MATERIA_LEGAL  not in  (select SZTALMT_MATERIA
                                       from SZTALMT
                                       where 1=1)
                        AND b.SZTGPME_CRSE_MDLE_CODE=p_shortname --'AB024_1_0801_L1C123';
                       )group by fecha_ini
                     ;
                        
                     RETURN (sc_out);
                     
            END f_sps_curri_out;  
 Function  f_sps_val (p_pidm number  ,p_regla number,p_fecha_inicio_regla date default null ) Return varchar2 

is
vl_valida number;
vl_return varchar2(100);
begin

     begin 
         select count (*) 
         into vl_valida 
         from SZTPRSIU
         where 1=1
         and SZTPRSIU_PIDM=p_pidm
         and SZTPRSIU_NO_REGLA=p_regla
          and SZTPRSIU_IND_INSC in ('S', 'P')
         and trunc (SZTPRSIU_FECHA_INICIO)= nvl (p_fecha_inicio_regla, SZTPRSIU_FECHA_INICIO);
     Exception
        When OThers then 
         vl_valida:=0;
     end;

 if  vl_valida>=1 then
   
   vl_return :='true';
   
 else 
    vl_return:='false';
    
  end if;

return(vl_return);
end; 
end;
/

DROP PUBLIC SYNONYM PKG_AULA_VIRTUAL;

CREATE OR REPLACE PUBLIC SYNONYM PKG_AULA_VIRTUAL FOR BANINST1.PKG_AULA_VIRTUAL;
