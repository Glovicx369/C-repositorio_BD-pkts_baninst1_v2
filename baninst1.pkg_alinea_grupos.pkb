DROP PACKAGE BODY BANINST1.PKG_ALINEA_GRUPOS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_ALINEA_GRUPOS 
AS


    function f_alinea_pidm ( p_regla number,
                             p_matricula varchar2,
                             p_materia_legal varchar2,
                             p_grupo varchar2
                             )
                             return varchar2
                             is

    l_retorna varchar2(1000):='EXITO';
    vl_salida varchar2(2500):= null;


    begin
              
       
        FOR C IN(
                   
                   select *
                   from
                   (
                       select get_crn_grupo(ono.sztprono_pidm,
                                             null,
                                             ono.SZTPRONO_MATERIA_LEGAL,
                                             ono.sztprono_no_regla
                                             ) grupo_horario,  
                                             p_grupo,
                                             get_crn_regla(ono.sztprono_pidm,
                                             null,
                                             ono.SZTPRONO_MATERIA_LEGAL,
                                             ono.sztprono_no_regla
                                             ) crn,
                            ono.*                                         
                        from sztprono ono
                        where 1 = 1
                        and sztprono_no_regla = p_regla
                        and sztprono_id = p_matricula
                        and sztprono_materia_legal =p_materia_legal
                    )                    
                )loop
                
                   begin
                
                       update szstume set SZSTUME_TERM_NRC =  c.sztprono_materia_legal||p_grupo
                       where 1 = 1
                       and szstume_no_regla = c.sztprono_no_regla
                       and SZSTUME_SUBJ_CODE = c.sztprono_materia_legal
                       and szstume_pidm = c.sztprono_pidm
                       AND SZSTUME_RSTS_CODE ='RE';
                       
                    
                   EXCEPTION WHEN OTHERS THEN
                       l_retorna:='No se pudo actualizar el registro sfctcr '||sqlerrm;
                   END;
                 
                
                   if l_retorna ='EXITO' then   
                    
                
                       BEGIN
                 
                         DELETE SFRSTCR 
                         WHERE 1 = 1
                         AND sfrstcr_pidm = c.sztprono_pidm
                         AND sfrstcr_term_code =c.sztprono_term_code
                         AND sfrstcr_ptrm_code = c.sztprono_ptrm_code
                         AND sfrstcr_crn  =c.crn;
                         
                       EXCEPTION WHEN OTHERS THEN
                           l_retorna:='No se pudo actualizar el registro sfctcr '||sqlerrm;
                       END;
                       
                           
                       BEGIN           
                                                
                           UPDATE sztprono SET sztprono_estatus_error ='N',
                                               sztprono_envio_horarios ='N',
                                               sztprono_descripcion_error =NULL,
                                               SZTPRONO_USUARIO =USER
                           WHERE 1 = 1 
                           AND sztprono_materia_legal = C.sztprono_materia_legal
                           AND sztprono_pidm = C.sztprono_pidm
                           AND sztprono_no_regla = c.sztprono_no_regla;
                           
                       EXCEPTION WHEN OTHERS THEN
                           l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
                       END;
                       
                       IF  l_retorna ='EXITO' then
                
                        
                            commit;
                            
                       else
                        
                            rollback;    
                        
                        
                       end if;
                       
                       For d in (
                                 
                                    Select distinct to_char (SZSTUME_START_DATE,'dd/mm/rrrr') fecha_ini, 
                                                                    SZSTUME_SUBJ_CODE_COMP Materia, 
                                                                    SZSTUME_PIDM Pidm, 
                                                                    SZSTUME_TERM_NRC termnrc, 
                                                                    SZSTUME_SEQ_NO secuencia,
                                                                    SZSTUME_NO_REGLA Regla,
                                                                    SZSTUME_ID,
                                                                    SZTPRONO_ENVIO_MOODL,
                                                                    SZTPRONO_ENVIO_HORARIOS                                                                
                                    from SZSTUME a, sztprono b
                                    WHERE 1= 1
                                    And a.SZSTUME_NO_REGLA = b.SZTPRONO_NO_REGLA
                                    And a.SZSTUME_ID = b.SZTPRONO_ID
                                    And a.SZSTUME_SUBJ_CODE_COMP = b.SZTPRONO_MATERIA_LEGAL
                                    And b.SZTPRONO_ENVIO_MOODL ='S'
                                    And b.SZTPRONO_ESTATUS_ERROR = 'N'
                                    And b.SZTPRONO_ENVIO_HORARIOS = 'N'
                                    And a.SZSTUME_NO_REGLA = c.sztprono_no_regla
                                    And a.SZSTUME_STAT_IND = '1'
                                   And SZSTUME_pIDm = c.sztprono_pidm
                                    And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                from SZSTUME a1
                                                                                Where a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                                                And a.SZSTUME_STAT_IND = a1.SZSTUME_STAT_IND
                                                                                And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA)
                                    order by 2, 4
                                    
                                     
                                
                                ) loop
                                
                                If d.fecha_ini is not null  and d.materia is not null then 
                                        BEGIN

                                                vl_salida := null;
                                          PKG_FORMA_MOODLE.P_INSCR_INDIVIDUAL_DD (d.fecha_ini,d.regla,d.materia,d.pidm, 'RE', d.secuencia, vl_salida  );
                                        Exception
                                            When Others then 
                                                null;
                                                
                                        END;

                                End if;
                                Commit;
                             End Loop;
                       
                       
                   end if;       
                  
                
                end loop;
                
                
                RETURN(l_retorna);
                
                
                
    end;            
--
--
    function f_alinea_masivo return varchar2
    is
         l_retorna varchar2(1000):='EXITO';
         vl_salida varchar2(2500):= null;


    begin

        for c in(
                    select *
                    from
                    (
                    select
                              get_crn_grupo(ono.sztprono_pidm,
                                             null,
                                             ono.SZTPRONO_MATERIA_LEGAL,
                                             mal.regla
                                             ) grupo_horario,
                                             mal.GRUPO,  
                                             mal.materia,
                                             get_crn_regla(ono.sztprono_pidm,
                                             null,
                                             ono.SZTPRONO_MATERIA_LEGAL,
                                             mal.regla
                                             ) crn,
                                             mal.CALIFICACION, 
                                             mal.docente,                  
                              ono.*                                         
                        from malas mal,
                             sztprono ono
                        where 1 = 1
                        and ono.sztprono_no_regla = mal.regla
                        and ono.sztprono_materia_legal = mal.materia
                        and ono.sztprono_id = mal.matricula     
                    )
                    where 1 = 1
                    and grupo_horario != GRUPO
                    
                )loop
                
                   BEGIN
             
                          DELETE SFRSTCR 
                           WHERE 1 = 1
                           AND sfrstcr_pidm = c.sztprono_pidm
                           AND sfrstcr_term_code =c.sztprono_term_code
                           AND sfrstcr_ptrm_code = c.sztprono_ptrm_code
                           AND sfrstcr_crn  =c.crn;
                     
                   EXCEPTION WHEN OTHERS THEN
                       l_retorna:='No se pudo actualizar el registro sfctcr '||sqlerrm;
                   END;
                   
                   if l_retorna ='EXITO' then   
                       
                       BEGIN           
                                                
                           UPDATE sztprono SET sztprono_estatus_error ='N',
                                               sztprono_envio_horarios ='N',
                                               sztprono_descripcion_error =NULL,
                                               SZTPRONO_USUARIO =USER
                           WHERE 1 = 1 
                           AND sztprono_materia_legal = C.sztprono_materia_legal
                           AND sztprono_pidm = C.sztprono_pidm
                           AND sztprono_no_regla = c.sztprono_no_regla;
                           
                       EXCEPTION WHEN OTHERS THEN
                           l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
                       END;
                       
                   end if;   
                   
                   IF  l_retorna ='EXITO' then
                
                    
                        commit;
                        
                   else
                    
                        rollback;    
                    
                    
                   end if;
                       
                       For d in (
                                 
                                    Select distinct to_char (SZSTUME_START_DATE,'dd/mm/rrrr') fecha_ini, 
                                                                    SZSTUME_SUBJ_CODE_COMP Materia, 
                                                                    SZSTUME_PIDM Pidm, 
                                                                    SZSTUME_TERM_NRC termnrc, 
                                                                    SZSTUME_SEQ_NO secuencia,
                                                                    SZSTUME_NO_REGLA Regla,
                                                                    SZSTUME_ID,
                                                                    SZTPRONO_ENVIO_MOODL,
                                                                    SZTPRONO_ENVIO_HORARIOS                                                                
                                    from SZSTUME a, sztprono b
                                    WHERE 1= 1
                                    And a.SZSTUME_NO_REGLA = b.SZTPRONO_NO_REGLA
                                    And a.SZSTUME_ID = b.SZTPRONO_ID
                                    And a.SZSTUME_SUBJ_CODE_COMP = b.SZTPRONO_MATERIA_LEGAL
                                    And b.SZTPRONO_ENVIO_MOODL ='S'
                                    And b.SZTPRONO_ESTATUS_ERROR = 'N'
                                    And b.SZTPRONO_ENVIO_HORARIOS = 'N'
                                    And a.SZSTUME_NO_REGLA = c.sztprono_no_regla
                                    And a.SZSTUME_STAT_IND = '1'
                                   And SZSTUME_pIDm = c.sztprono_pidm
                                    And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                from SZSTUME a1
                                                                                Where a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                                                And a.SZSTUME_STAT_IND = a1.SZSTUME_STAT_IND
                                                                                And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA)
                                    order by 2, 4
                                    
                                     
                                
                                ) loop
                                
                                If d.fecha_ini is not null  and d.materia is not null then 
                                        BEGIN

                                                vl_salida := null;
                                          PKG_FORMA_MOODLE.P_INSCR_INDIVIDUAL_DD (d.fecha_ini,d.regla,d.materia,d.pidm, 'RE', d.secuencia, vl_salida  );
                                        Exception
                                            When Others then 
                                                null;
                                                
                                        END;

                                End if;
                                Commit;
                             End Loop;
                
                end loop;
                
                IF  l_retorna ='EXITO' then
                
                
                    commit;
                    
                else
                
                    rollback;    
                
                
                end if;
                
                RETURN(l_retorna);

    end;--    
    
end;
/

DROP PUBLIC SYNONYM PKG_ALINEA_GRUPOS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ALINEA_GRUPOS FOR BANINST1.PKG_ALINEA_GRUPOS;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_ALINEA_GRUPOS TO PUBLIC;
