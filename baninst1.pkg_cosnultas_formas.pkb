DROP PACKAGE BODY BANINST1.PKG_COSNULTAS_FORMAS;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_cosnultas_formas is
--
--

    FUNCTION f_lv_grupo_sinc (p_pidm number,
                              p_regla number) return t_tab PIPELINED
    IS l_row t_grupo_sinc;
    begin
    
        for c in (
                  select distinct  x.MATERIA,
                                   x.GRUPO,
                                   x.DESCRIPCION,
                                   x.SZSTUME_RSTS_CODE,
                                   SZSTUME_SEQ_NO
                    from
                    (
                        select DISTINCT  SZSTUME_SUBJ_CODE materia,
                                     case When SZSTUME_TERM_NRC like '%X' Then
                                            SUBSTR(SZSTUME_TERM_NRC,-3,3)
                                          else 
                                            SUBSTR(SZSTUME_TERM_NRC,-2)    
                                     end grupo ,
                                     SZSTUME_RSTS_CODE,
                                     SZSTUME_SEQ_NO,
                                     DECODE(SZSTUME_GRDE_CODE_FINAL,0,NULL,SZSTUME_GRDE_CODE_FINAL) calificacion,
                                     SZTPRONO_PROGRAM programa,
                                     (select SCRSYLN_LONG_COURSE_TITLE
                                      from SCRSYLN
                                      WHERE 1 = 1
                                      AND SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB  =SZSTUME_SUBJ_CODE) descripcion
                    from szstume me1,
                         sztprono ono
                    where 1 = 1
                    AND me1.szstume_pidm = ono.sztprono_pidm
                    and me1.szstume_no_regla = ono.sztprono_no_regla
--                    and me1.szstume_subj_code not in (select distinct ZSTPARA_PARAM_ID
--                                                      from ZSTPARA
--                                                     where 1 = 1
--                                                      and ZSTPARA_MAPA_ID in  ('MATERIAS_EXTRAC','MATERIAS_CESA','MATERIAS_IEBS'))
                    and szstume_no_regla =p_regla
                    AND SZSTUME_PIDM = p_pidm
--                    AND DECODE(SZSTUME_GRDE_CODE_FINAL,0,NULL,SZSTUME_GRDE_CODE_FINAL) is null
                    and SZSTUME_SEQ_NO  = (select max(SZSTUME_SEQ_NO)
                                           from szstume me2
                                           where 1 = 1
                                           and me1.szstume_no_regla = me2.szstume_no_regla
                                           and me1.SZSTUME_PIDM = me2.SZSTUME_PIDM
                                           and me1.SZSTUME_SUBJ_CODE_COMP = me2.SZSTUME_SUBJ_CODE_COMP
                                           and me1.SZSTUME_RSTS_CODE ='RE'
                                           )
                    )x
        )loop
        
        
             l_row.materia:=c.materia;
             l_row.GRUPO := c.GRUPO;
             l_row.DESCRIPCION := c.DESCRIPCION;
             PIPE ROW (l_row);
        
        end loop;
    
    
    
    end;                                

--
--      
end;
/

DROP PUBLIC SYNONYM PKG_COSNULTAS_FORMAS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_COSNULTAS_FORMAS FOR BANINST1.PKG_COSNULTAS_FORMAS;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_COSNULTAS_FORMAS TO PUBLIC;
