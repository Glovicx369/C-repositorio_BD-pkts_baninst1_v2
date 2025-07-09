DROP PACKAGE BODY BANINST1.PKG_ABCC;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_abcc is

    function f_monetos_abcc (p_evento varchar2, p_sp number, p_pidm number,p_estatus varchar2, p_user varchar2)
    return varchar2 is
        l_retorna varchar2(200):='EXITO';
        l_maximor_horarios varchar2(20);
        l_vaor_biracora varchar2(200);
        l_contador      number:=0;
        l_conse_sorlcur number;
    begin
    
        dbms_output.put_line('Entra 1 ');    
    
        if p_evento ='CAMBIO_ETSTAUS' THEN
        
            for c in (select *
                      from tztprog
                      where 1 = 1
                      and pidm = p_pidm
                      and SP = p_sp
                      and rownum = 1
                       )loop
                       
                           BEGIN
                                select max(SFRSTCR_TERM_CODE)
                                into l_maximor_horarios
                                from  SFRSTCR a
                                where 1 = 1
                                and A.SFRSTCR_PIDM = c.pidm
                              --  and A.SFRSTCR_STSP_KEY_SEQUENCE = p_sp
                                --and trunc (SSBSECT_PTRM_START_DATE) = to_Date(f_fecha_inicio_old, 'dd/mm/yyyy')
                                and substr (a.SFRSTCR_TERM_CODE,5,1)<>8
                                and A.SFRSTCR_TERM_CODE =(select max(a1.SFRSTCR_TERM_CODE)
                                                        from  SFRSTCR a1
                                                        where 1 = 1
                                                        AND A.SFRSTCR_PIDM = a1.SFRSTCR_PIDM
                                                        and A.SFRSTCR_STSP_KEY_SEQUENCE  = a1.SFRSTCR_STSP_KEY_SEQUENCE 
                                                        and substr (a1.SFRSTCR_TERM_CODE,5,1)<>8
                                                        );
                           EXCEPTION WHEN OTHERS THEN
                            NULL;
                           END;       
                           
                           IF l_maximor_horarios IS NULL THEN
                            
                              l_maximor_horarios:=c.MATRICULACION;
                           
                           END IF;
                       
                           if p_estatus ='BT' then
                           
                               dbms_output.put_line('Periodo matriculacion '||c.MATRICULACION||' Periodo Mayor '||l_maximor_horarios);
                           
                               --if c.MATRICULACION = l_maximor_horarios then 
                               
                                     BEGIN
                                     
                                        update sgbstdn a set sgbstdn_stst_code= p_estatus,--'BI'
                                                           SGBSTDN_STYP_CODE='D',
                                                           SGBSTDN_ACTIVITY_DATE = SYSDATE,
                                                           SGBSTDN_USER_ID = USER
                                        where 1 = 1
                                        AND a.sgbstdn_pidm=c.pidm
                                        and a.sgbstdn_program_1=c.programa
                                        AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                        FROM sgbstdn a1
                                                                        WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
                                                                        and a1.sgbstdn_program_1  = a.sgbstdn_program_1                                
                                                                                                         );
                                        
                                     EXCEPTION WHEN OTHERS THEN
                                        l_retorna:='No se pudo cambiar el estatus '||sqlerrm;
                                     END;  
                                     
--                               else
--                                     for x in (select *
--                                               from sgbstdn a 
--                                               where 1 = 1
--                                               AND a.sgbstdn_pidm=c.pidm
--                                               and a.sgbstdn_program_1=c.programa
--                                               AND a.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
--                                                                               FROM sgbstdn a1
--                                                                               WHERE a1.sgbstdn_pidm = a.sgbstdn_pidm
--                                                                               and a1.sgbstdn_program_1  = a.sgbstdn_program_1                                
--                                                                                                        )
--                                             )loop
--                                             
--                                                BEGIN
--                                                        insert into sgbstdn values(x.SGBSTDN_PIDM,
--                                                                                   x.SGBSTDN_TERM_CODE_EFF,
--                                                                                   p_estatus,
--                                                                                   x.SGBSTDN_LEVL_CODE,
--                                                                                   'D',
--                                                                                   x.SGBSTDN_TERM_CODE_MATRIC,
--                                                                                   x.SGBSTDN_TERM_CODE_ADMIT,
--                                                                                   x.SGBSTDN_EXP_GRAD_DATE,
--                                                                                   x.SGBSTDN_CAMP_CODE,
--                                                                                   x.SGBSTDN_FULL_PART_IND,
--                                                                                   x.SGBSTDN_SESS_CODE,
--                                                                                   x.SGBSTDN_RESD_CODE,
--                                                                                   x.SGBSTDN_COLL_CODE_1,
--                                                                                   x.SGBSTDN_DEGC_CODE_1,
--                                                                                   x.SGBSTDN_MAJR_CODE_1,
--                                                                                   x.SGBSTDN_MAJR_CODE_MINR_1,
--                                                                                   x.SGBSTDN_MAJR_CODE_MINR_1_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_1,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_1_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_1_3,
--                                                                                   x.SGBSTDN_COLL_CODE_2,
--                                                                                   x.SGBSTDN_DEGC_CODE_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_MINR_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_MINR_2_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_2_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_2_3,
--                                                                                   x.SGBSTDN_ORSN_CODE,
--                                                                                   x.SGBSTDN_PRAC_CODE,
--                                                                                   x.SGBSTDN_ADVR_PIDM,
--                                                                                   x.SGBSTDN_GRAD_CREDIT_APPR_IND,
--                                                                                   x.SGBSTDN_CAPL_CODE,
--                                                                                   x.SGBSTDN_LEAV_CODE,
--                                                                                   x.SGBSTDN_LEAV_FROM_DATE,
--                                                                                   x.SGBSTDN_LEAV_TO_DATE,
--                                                                                   x.SGBSTDN_ASTD_CODE,
--                                                                                   x.SGBSTDN_TERM_CODE_ASTD,
--                                                                                   x.SGBSTDN_RATE_CODE,
--                                                                                   SYSDATE,
--                                                                                   x.SGBSTDN_MAJR_CODE_1_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_2_2,
--                                                                                   x.SGBSTDN_EDLV_CODE,
--                                                                                   x.SGBSTDN_INCM_CODE,
--                                                                                   x.SGBSTDN_ADMT_CODE,
--                                                                                   x.SGBSTDN_EMEX_CODE,
--                                                                                   x.SGBSTDN_APRN_CODE,
--                                                                                   x.SGBSTDN_TRCN_CODE,
--                                                                                   x.SGBSTDN_GAIN_CODE,
--                                                                                   x.SGBSTDN_VOED_CODE,
--                                                                                   x.SGBSTDN_BLCK_CODE,
--                                                                                   x.SGBSTDN_TERM_CODE_GRAD,
--                                                                                   x.SGBSTDN_ACYR_CODE,
--                                                                                   x.SGBSTDN_DEPT_CODE,
--                                                                                   x.SGBSTDN_SITE_CODE,
--                                                                                   x.SGBSTDN_DEPT_CODE_2,
--                                                                                   x.SGBSTDN_EGOL_CODE,
--                                                                                   x.SGBSTDN_DEGC_CODE_DUAL,
--                                                                                   x.SGBSTDN_LEVL_CODE_DUAL,
--                                                                                   x.SGBSTDN_DEPT_CODE_DUAL,
--                                                                                   x.SGBSTDN_COLL_CODE_DUAL,
--                                                                                   x.SGBSTDN_MAJR_CODE_DUAL,
--                                                                                   x.SGBSTDN_BSKL_CODE,
--                                                                                   x.SGBSTDN_PRIM_ROLL_IND,
--                                                                                   x.SGBSTDN_PROGRAM_1,
--                                                                                   x.SGBSTDN_TERM_CODE_CTLG_1,
--                                                                                   x.SGBSTDN_DEPT_CODE_1_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_121,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_122,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_123,
--                                                                                   x.SGBSTDN_SECD_ROLL_IND,
--                                                                                   x.SGBSTDN_TERM_CODE_ADMIT_2,
--                                                                                   x.SGBSTDN_ADMT_CODE_2,
--                                                                                   x.SGBSTDN_PROGRAM_2,
--                                                                                   x.SGBSTDN_TERM_CODE_CTLG_2,
--                                                                                   x.SGBSTDN_LEVL_CODE_2,
--                                                                                   x.SGBSTDN_CAMP_CODE_2,
--                                                                                   x.SGBSTDN_DEPT_CODE_2_2,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_221,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_222,
--                                                                                   x.SGBSTDN_MAJR_CODE_CONC_223,
--                                                                                   x.SGBSTDN_CURR_RULE_1,
--                                                                                   x.SGBSTDN_CMJR_RULE_1_1,
--                                                                                   x.SGBSTDN_CCON_RULE_11_1,
--                                                                                   x.SGBSTDN_CCON_RULE_11_2,
--                                                                                   x.SGBSTDN_CCON_RULE_11_3,
--                                                                                   x.SGBSTDN_CMJR_RULE_1_2,
--                                                                                   x.SGBSTDN_CCON_RULE_12_1,
--                                                                                   x.SGBSTDN_CCON_RULE_12_2,
--                                                                                   x.SGBSTDN_CCON_RULE_12_3,
--                                                                                   x.SGBSTDN_CMNR_RULE_1_1,
--                                                                                   x.SGBSTDN_CMNR_RULE_1_2,
--                                                                                   x.SGBSTDN_CURR_RULE_2,
--                                                                                   x.SGBSTDN_CMJR_RULE_2_1,
--                                                                                   x.SGBSTDN_CCON_RULE_21_1,
--                                                                                   x.SGBSTDN_CCON_RULE_21_2,
--                                                                                   x.SGBSTDN_CCON_RULE_21_3,
--                                                                                   x.SGBSTDN_CMJR_RULE_2_2,
--                                                                                   x.SGBSTDN_CCON_RULE_22_1,
--                                                                                   x.SGBSTDN_CCON_RULE_22_2,
--                                                                                   x.SGBSTDN_CCON_RULE_22_3,
--                                                                                   x.SGBSTDN_CMNR_RULE_2_1,
--                                                                                   x.SGBSTDN_CMNR_RULE_2_2,
--                                                                                   x.SGBSTDN_PREV_CODE,
--                                                                                   x.SGBSTDN_TERM_CODE_PREV,
--                                                                                   x.SGBSTDN_CAST_CODE,
--                                                                                   x.SGBSTDN_TERM_CODE_CAST,
--                                                                                   'SZFABCC_V2',
--                                                                                   USER,
--                                                                                   x.SGBSTDN_SCPC_CODE,
--                                                                                   null,
--                                                                                   x.SGBSTDN_VERSION,
--                                                                                   X.SGBSTDN_VPDI_CODE);
--                                                EXCEPTION WHEN OTHERS THEN
--                                                
--                                                    l_retorna:='No se puede insertar en sgbstdn '||sqlerrm;
--                                                
--                                                END;   
--                                                           
--                                             end loop;
--                                     
                                     if l_retorna ='EXITO' then
                                     
                                            l_contador:= 0;  
                                            
                                            FOR t in (select *
                                                      from sorlcur b
                                                      where 1 = 1
                                                      and b.sorlcur_pidm =C.PIDM
                                                      AND b.sorlcur_lmod_code = 'LEARNER'
                                                      AND b.sorlcur_roll_ind = 'Y'
                                                      AND b.sorlcur_cact_code = 'ACTIVE'
                                                      AND b.SORLCUR_KEY_SEQNO = c.sp
                                                      AND b.sorlcur_seqno = 
                                                                           (SELECT MAX (c1x.sorlcur_seqno)
                                                                            FROM sorlcur c1x
                                                                            WHERE     c1x.sorlcur_pidm = b.sorlcur_pidm
                                                                            AND c1x.sorlcur_lmod_code = b.sorlcur_lmod_code
                                                                            AND c1x.sorlcur_roll_ind =  b.sorlcur_roll_ind
                                                                            AND c1x.sorlcur_cact_code = b.sorlcur_cact_code
                                                                            )    
                                                      )loop
                                                      
                                                            l_contador:=l_contador+1;
                                                            
                                                            begin
                                                            
                                                                 SELECT NVL (MAX (sorlcur_seqno), 0) + 1
                                                                 INTO l_conse_sorlcur
                                                                 FROM sorlcur
                                                                 WHERE sorlcur_pidm = t.sorlcur_pidm;
                                                            
                                                            exception when others then
                                                                null;
                                                            end;
                                                            
                                                            
                                                            begin
                                                            
                                                                insert into sorlcur values (t.sorlcur_pidm,
                                                                                            l_conse_sorlcur,
                                                                                            t.sorlcur_lmod_code,
                                                                                            t.SORLCUR_TERM_CODE,
                                                                                            t.sorlcur_key_seqno,
                                                                                            t.sorlcur_priority_no,
                                                                                            'N',
                                                                                            'INACTIVE',
                                                                                            USER,
                                                                                            'SZFABCC',
                                                                                            SYSDATE,
                                                                                            t.sorlcur_levl_code,
                                                                                            t.sorlcur_coll_code,
                                                                                            t.sorlcur_degc_code,
                                                                                            t.sorlcur_term_code_ctlg,
                                                                                            l_maximor_horarios,
                                                                                            t.sorlcur_term_code_matric,
                                                                                            t.sorlcur_term_code_admit,
                                                                                            t.sorlcur_admt_code,
                                                                                            t.sorlcur_camp_code,
                                                                                            t.sorlcur_program,
                                                                                            t.sorlcur_start_date,
                                                                                            t.sorlcur_end_date,
                                                                                            t.sorlcur_curr_rule,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            t.SORLCUR_RATE_CODE,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            USER,
                                                                                            SYSDATE,
                                                                                            NULL,
                                                                                            t.SORLCUR_CURRENT_CDE,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL);
                                                            
                                                            exception when others then
                                                                l_retorna:='No se actualizar el registro en sorlcur '||sqlerrm;
                                                            end;
                                                            
                                                            IF l_retorna ='EXITO' then
                                                            
                                                                 FOR w
                                                                  IN (  SELECT *
                                                                         FROM sorlfos
                                                                         WHERE sorlfos_pidm = t.sorlcur_pidm
                                                                         AND sorlfos_lcur_seqno = t.sorlcur_seqno
                                                                         ORDER BY sorlfos_seqno
                                                                      )loop
                                                                      
                                                                          begin
                                                                          
                                                                              INSERT INTO sorlfos
                                                                                    VALUES (w.sorlfos_pidm,
                                                                                            l_conse_sorlcur,
                                                                                            w.sorlfos_seqno,
                                                                                            w.sorlfos_lfst_code,
                                                                                            w.SORLFOS_TERM_CODE,
                                                                                            w.sorlfos_priority_no,
                                                                                            'CHANGED',
                                                                                            'INACTIVE',
                                                                                            'SZFABCC',
                                                                                            USER,
                                                                                            SYSDATE,
                                                                                            w.sorlfos_majr_code,
                                                                                            w.sorlfos_term_code_ctlg,
                                                                                            w.SORLFOS_TERM_CODE,
                                                                                            NULL,
                                                                                            w.sorlfos_majr_code_attach,
                                                                                            w.sorlfos_lfos_rule,
                                                                                            w.sorlfos_conc_attach_rule,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            USER,
                                                                                            SYSDATE,
                                                                                            w.SORLFOS_CURRENT_CDE,
                                                                                            NULL,
                                                                                            NULL,
                                                                                            NULL);
                                                                          
                                                                          exception when others then
                                                                              l_retorna:='No se puede insertar a sorlfos '||sqlerrm;
                                                                          end;
                                                                      
                                                                          if l_retorna='EXITO' then
                                                                          
                                                                            l_vaor_biracora:=f_bitacora_abcc(p_evento,c.sp,c.pidm,p_estatus,p_user);
                                                                            
                                                                            dbms_output.put_line('Contador  t-->'||l_contador);
                                            
                                            
                                                                                    if l_vaor_biracora ='EXITO' then
                                                                                    
                                                                                       begin
                                                                                        
                                                                                            UPDATE sgrstsp SET SGRSTSP_STSP_CODE = 'IN'
                                                                                            WHERE  1 = 1
                                                                                            and sgrstsp_pidm = C.PIDM
                                                                                            AND sgrstsp_key_seqno = c.sp;
                                                                                            
                                                                                       exception when others then
                                                                                            l_retorna:='No se puede actualizar el estatus '||sqlerrm;
                                                                                       end;     
                                                                                    
                                                                                    
                                                                                    end if;
                                                                                    
                                                                                    if l_vaor_biracora ='EXITO' then
                                                                                        commit;
                                                                                    else
                                                                                    
                                                                                        rollback;
                                                                                    
                                                                                    end if;
                                                                          
                                                                                exit when l_contador = 1;
                                                                          
                                                                          
                                                                          end if;
                                                                      
                                                                      end loop;
                                                      
                                                            end if;
                                                            
                                                            exit when l_contador = 1;
                                                      
                                                      end loop;
                                                      
                                                      
                                     
                                     end if;
                                     
                                     
                           end if;           
                                  
                       
                       END LOOP;
        
        END IF;    
        
        return l_retorna;
    
    end;
    
    function f_bitacora_abcc ( p_evento varchar2,p_sp number, p_pidm number,p_estatus varchar2,p_user varchar2)
      return varchar2
      IS
      l_retorna varchar2(200):='EXITO';
      l_max_sgrscmt number;
      l_descripcion varchar2(2000);
      l_maximor_horarios varchar2(20);
      l_contador number:=0;
      l_codigo_domi varchar2(500);
      l_desc_domi varchar2(500);

    BEGIN
        
        dbms_output.put_line('entra bitacora 1');

        Begin
        
          SELECT NVL(MAX(a.SGRSCMT_SEQ_NO),0)+1
          INTO l_max_sgrscmt
          FROM  SGRSCMT a
          WHERE a.SGRSCMT_PIDM  = p_pidm
          AND a.SGRSCMT_TERM_CODE = (SELECT MAX (a1.SGRSCMT_TERM_CODE)
                                     FROM SGRSCMT a1
                                     WHERE a1.SGRSCMT_PIDM = a.SGRSCMT_PIDM
                                     and a1.SGRSCMT_TERM_CODE  = a.SGRSCMT_TERM_CODE);
          
        Exception  When Others then 
            l_max_sgrscmt :=1;
        End;
        
        l_contador:=0;
        
        dbms_output.put_line('bitacora entra 2 -->'||l_contador);
        
        for c in (select *
                          from tztprog
                          where 1 = 1
                          and pidm = p_pidm
                          and SP = p_sp
                          AND ROWNUM = 1
                           )loop
                           
                              l_contador:=l_contador+1;
                           
                          dbms_output.put_line('entra 3 for x--> '||l_contador);
                           
                               begin
                                   INSERT INTO SGBSTDB
                                   SELECT N.*,c.FECHA_INICIO, l_max_sgrscmt, c.sp
                                   FROM SGBSTDN N 
                                   where 1 = 1
                                   AND n.sgbstdn_pidm=c.pidm
                                   and n.sgbstdn_program_1=c.programa
                                   AND n.sgbstdn_term_code_eff = (SELECT MAX (a1.sgbstdn_term_code_eff)
                                                                   FROM sgbstdn a1
                                                                   WHERE a1.sgbstdn_pidm = n.sgbstdn_pidm
                                                                   and a1.sgbstdn_program_1  = n.sgbstdn_program_1                                
                                                                                                    );
                               exception when others then
                                    l_retorna:='No se puede insertar SGBSTDB '||sqlerrm;
                                     dbms_output.put_line('error inserta SGBSTDB '||l_retorna);
                               end;
                               
         --                      dbms_output.put_line('entra 4');
                               
                               if l_retorna ='EXITO' then
                               
                                  dbms_output.put_line('entra 5' ||l_retorna);
                               
                                   if p_evento ='CAMBIO_ETSTAUS' then
                                    
             --                        dbms_output.put_line('entra a evento  '||p_evento);
                                    
                                        l_descripcion:=UPPER('CAMBIO_ESTATUS'||':'||' Estatus Anterior '||C.ESTATUS||' Estatus  Nuevo '||p_estatus||' Usuario '||user||' Fecha '||Sysdate);
                                        
                                   elsif p_evento ='BAJA_DOMI' then
                                   
                                        begin
            
                                            select listagg( GORADID_ADID_CODE ||',')WITHIN GROUP (ORDER BY GORADID_ADID_CODE) codigo_domi
                                            INTO l_codigo_domi
                                            from goradid            
                                            where 1 = 1
                                            and goradid_pidm = p_pidm
                                            AND EXISTS (SELECT NULL
                                                        FROM ZSTPARA
                                                        WHERE 1 = 1
                                                        AND ZSTPARA_MAPA_ID='PORCENTAJE_DOM'
                                                        AND ZSTPARA_PARAM_ID = GORADID_ADID_CODE );
                                                        
                                        exception when others then
                                            null;
                                        end;
                                            
                                        
                                        begin
                                        
                                            select listagg( GORADID_ADDITIONAL_ID ||',')WITHIN GROUP (ORDER BY GORADID_ADDITIONAL_ID) desc_domi
                                                INTO l_desc_domi
                                                from goradid a           
                                                where 1 = 1
                                                and goradid_pidm = p_pidm
                                                AND EXISTS (SELECT NULL
                                                            FROM ZSTPARA
                                                            WHERE 1 = 1
                                                            AND ZSTPARA_MAPA_ID='PORCENTAJE_DOM'
                                                            AND ZSTPARA_PARAM_ID = GORADID_ADID_CODE );
                                                        
                                         exception when others then
                                            null;
                                        end;               
                                        l_descripcion:=UPPER('BAJA_DOMI, Codigo Goradid: '||l_codigo_domi||' '||l_desc_domi||' Usuario '||p_user||' Fecha '||Sysdate);
                                    
                                   end if;
                                   
               --                    dbms_output.put_line('entra 5 '||l_descripcion);
                                    
                                   BEGIN
                                        select max(SFRSTCR_TERM_CODE)
                                        into l_maximor_horarios
                                        from  SFRSTCR a
                                        where 1 = 1
                                        and A.SFRSTCR_PIDM = c.pidm
                                        and A.SFRSTCR_STSP_KEY_SEQUENCE = p_sp
                                        and substr (a.SFRSTCR_TERM_CODE,5,1)<>8
                                        and A.SFRSTCR_TERM_CODE =(select max(a1.SFRSTCR_TERM_CODE)
                                                                from  SFRSTCR a1
                                                                where 1 = 1
                                                                AND A.SFRSTCR_PIDM = a1.SFRSTCR_PIDM
                                                                and A.SFRSTCR_STSP_KEY_SEQUENCE  = a1.SFRSTCR_STSP_KEY_SEQUENCE 
                                                                and substr (a1.SFRSTCR_TERM_CODE,5,1)<>8
                                                                );
                                   EXCEPTION WHEN OTHERS THEN
                                    NULL;
                                   END;       
                                   
                                   IF l_maximor_horarios IS NULL THEN
                                    
                                      l_maximor_horarios:=c.MATRICULACION;
                                   
                                   END IF;
                                   
                                  dbms_output.put_line('entra descripcion '||l_descripcion||' for '||l_contador);
                                   
                                   
                                   if l_descripcion is not null then
                                        
                                       BEgin

                                            INSERT INTO SGRSCMT (
                                               SGRSCMT_PIDM
                                           , SGRSCMT_SEQ_NO
                                           , SGRSCMT_TERM_CODE
                                           , SGRSCMT_COMMENT_TEXT
                                           , SGRSCMT_ACTIVITY_DATE
                                           , SGRSCMT_DATA_ORIGIN
                                           , SGRSCMT_USER_ID
                                           , SGRSCMT_VPDI_CODE
                                            )
                                            VALUES (
                                               c.pidm
                                             , l_max_sgrscmt
                                             , l_maximor_horarios
                                             , l_descripcion
                                             , SYSDATE
                                             , 'SSB'
                                             , user
                                             ,C.SP
                                            );
                                       Exception when Others then 
                                            l_retorna:= ('Error Bitacora3 '||sqlerrm);
                                       End;
                                    
                                   end if;
                                   
                               
                               end if;
                               
                                exit when l_contador = 1;
                           
                           END LOOP;
                           
                           return l_retorna;
                           
        
    END;
FUNCTION F_GENERA_SP (P_PIDM NUMBER,p_programa varchar2 )RETURN NUMBER is
 
L_SP NUMBER;

BEGIN 

    BEGIN
    
       SELECT DISTINCT 
            cur.sorlcur_key_seqno
            into l_sp
       FROM sorlcur cur
       WHERE     1 = 1
       AND cur.sorlcur_pidm = p_pidm
       and cur.sorlcur_program=p_programa
       AND cur.sorlcur_lmod_code = 'LEARNER'
       AND cur.sorlcur_roll_ind = 'Y'
       AND cur.sorlcur_cact_code = 'ACTIVE'
       AND cur.sorlcur_seqno =(SELECT MAX (aa1.sorlcur_seqno)
                               FROM sorlcur aa1
                               WHERE cur.sorlcur_pidm = aa1.sorlcur_pidm
                               AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
                               AND cur.sorlcur_roll_ind = aa1.sorlcur_roll_ind
                               AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code);

    EXCEPTION WHEN OTHERS THEN 
    
    L_SP := 1;
    
    END;
     
     
    RETURN l_sp ;
    
 END f_genera_sp ;
 
 Function F_Vigencia (p_pidm in number, p_evento in varchar2) Return varchar2 
 Is 
 
 vl_exito varchar2(250):= 'EXITO';
 l_dias number;
 l_fecha_candado date;
 l_fecha_inicio date;
 
 
 Begin
         
            Begin 
                     SELECT DISTINCT ZSTPARA_PARAM_VALOR
                      into l_dias
                    FROM zstpara
                    WHERE     1 = 1
                    AND zstpara_mapa_id = 'ABCC_VIG'
                    and ZSTPARA_PARAM_ID =p_evento;   
            Exception
                When others then 
                    l_dias:=0;
            End;
 
            Begin           

                        select distinct SORLCUR_START_DATE
                         Into l_fecha_inicio
                        FROM SORLCUR A
                        WHERE 1 = 1
                        and A.SORLCUR_PIDM = p_pidm
                        AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                        AND A.SORLCUR_ROLL_IND  = 'Y'
                        AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                        AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                                   FROM SORLCUR A1
                                                                   WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                   AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM) ;           
            
            
            Exception
                When others then 
                l_fecha_inicio:=sysdate;    
            End;
 
 
            l_fecha_candado:= to_date(l_fecha_inicio+l_dias);
            
           
    
            IF to_date(l_fecha_candado)+1 <= to_date(SYSDATE) THEN
                
                If p_evento ='CF' then 
                        vl_exito := 'El periodo para realizar cambios de Fecha de Inicio de clases se cerro el dia '||to_char (l_fecha_candado,'dd/mm/rrrr');
                ElsIf p_evento ='CC' then                        
                    vl_exito := 'El periodo para realizar cambios de inicio de Ciclo  se cerro el dia '||to_char (l_fecha_candado,'dd/mm/rrrr');
                End if;
            else 
                vl_exito:= 'EXITO';
            END IF;    
 
            Return vl_exito;
 
 End F_Vigencia;
 

   Function F_Valida_costo (p_pidm number , p_evento in varchar2, p_servicio in varchar2) Return number 
Is

vl_existe varchar2(4);
vl_codigo number:=0;
vl_salida number:=null;
vl_costo number:=0;
vl_matricula varchar2(9);

Begin
           
--        Begin 
--            select count(*)
--                Into vl_codigo
--           from SFBETRM
--           where SFBETRM_PIDM = p_pidm
--           and SFBETRM_RGRE_CODE = p_evento;
--        Exception
--            When Others then 
--                vl_codigo:= 0;
--                dbms_output.put_line('Error 1 '||sqlerrm);
--        End;
--        
--         dbms_output.put_line('Recupera Bitacora '||vl_codigo);
--        
--        If vl_codigo > 0 then 
        
         dbms_output.put_line('Entra a buscar Costo '||vl_codigo);
        
                Begin 
                        SELECT DISTINCT  svrrsso_serv_amount
                            Into vl_costo 
                        FROM 
                        svrrsrv A,
                        svrrsso,
                        svvsrvc
                        WHERE 1=1
                        AND  a.svrrsrv_srvc_code = svrrsso_srvc_code
                        AND a.svrrsrv_seq_no = svrrsso_rsrv_seq_no
                        AND svvsrvc_code = svrrsso_srvc_code
                        AND svrrsrv_inactive_ind = 'Y'
                        AND a.svrrsrv_web_ind = 'Y'
                        AND a.svrrsrv_seq_no =  BANINST1.bvgkptcl.F_apply_rule_protocol (p_pidm, A.SVRRSRV_SRVC_CODE)
                        and a.svrrsrv_srvc_code=p_servicio;
                Exception
                    When Others then 
                         vl_costo:=0;   
                         dbms_output.put_line('Error 2 '||sqlerrm);
                End;
                
                dbms_output.put_line('Recupera Costo '||vl_costo);
        
                vl_salida:= vl_costo;
--        Else
--                  vl_salida:= 0;
--        End if;
        
        Return vl_salida;

End F_Valida_costo;


FUNCTION f_fecha_inicio_out (p_pidm in number, p_programa in varchar2) RETURN pkg_abcc.co1_out
           AS
           
           l_tipo_ingreso varchar2(2);
           fecha_out pkg_abcc.co1_out;
           l_nivel varchar2(2);
           l_pperiodos varchar2(500):= null;
           l_query varchar2(5000):= null;
           l_fecha date:= null;
           
           Begin 
              
                    Begin
                                                    
                        select distinct SORLCUR_ADMT_CODE, SORLCUR_levl_code, SORLCUR_START_DATE
                        Into l_TIPO_INGRESO, l_nivel, l_fecha
                        FROM SORLCUR A
                        WHERE 1 = 1
                        and A.SORLCUR_PIDM = p_pidm
                        AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                        AND A.SORLCUR_ROLL_IND  = 'Y'
                        AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                        AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                                   FROM SORLCUR A1
                                                                   WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                   AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM);                                             
                    Exception
                    when others then
                       l_TIPO_INGRESO:= null;
                       l_nivel := null;
                       l_fecha:= null;
                    End;
                    
            
                    
                   If l_nivel ='LI' and l_TIPO_INGRESO ='EQ' then 

                            dbms_output.put_line('entra 1');                   
                           
                           BEGIN
                                          open fecha_out
                                            FOR
                                                select distinct Fecha_Inicio
                                                from  (
                                                            Select distinct Fecha_Inicio, numero
                                                            from (   
                                                                     select distinct ROW_NUMBER() OVER (ORDER BY sobptrm_start_date) AS numero,   to_char (sobptrm_start_date,'dd/mm/rrrr') Fecha_Inicio
                                                                        from sztptrm, sobptrm
                                                                        where sztptrm_term_code = sobptrm_term_code
                                                                        and sztptrm_ptrm_code = sobptrm_ptrm_code
                                                                       and SZTPTRM_PTRM_CODE in ('L0A','L1A')
                                                                        and SZTPTRM_PROGRAM =p_programa
                                                                        And trunc (sobptrm_start_date) >  trunc (l_fecha)
                                                                        and sobptrm_term_code >=  (Select distinct SGBSTDN_TERM_CODE_EFF
                                                                                                                    from sgbstdn a
                                                                                                                    where 1= 1
                                                                                                                    and a.SGBSTDN_PIDM = p_pidm
                                                                                                                    and a.SGBSTDN_PROGRAM_1 = p_programa
                                                                                                                    And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)   
                                                                                                                                                                            from sgbstdn a1
                                                                                                                                                                            where 1= 1
                                                                                                                                                                            and a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                                                                                                                            and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1))
                                                                        AND TRUNC(sobptrm_start_date) >= TRUNC(SYSDATE) -SZTPTRM_ADICIONAL
                                                                        AND SZTPTRM_VISIBLE != 0 
                                                                   )
                                                                where 1= 1
                                                                      and numero <= 2
                                                ) 
                                                 order by 1; 

                                        RETURN (fecha_out);
                           End;
                           
                   Elsif   l_nivel ='MA' and l_TIPO_INGRESO ='EQ' then  
                     dbms_output.put_line('entra 2'); 
                   
                           BEGIN
                                          open fecha_out
                                            FOR
                                                select distinct Fecha_Inicio
                                                from  (
                                                            Select distinct Fecha_Inicio , numero
                                                            from (                                           
                                                                        select distinct ROW_NUMBER() OVER (ORDER BY sobptrm_start_date) AS numero,   to_char (sobptrm_start_date,'dd/mm/rrrr') Fecha_Inicio
                                                                        from sztptrm, sobptrm
                                                                        where sztptrm_term_code = sobptrm_term_code
                                                                        and sztptrm_ptrm_code = sobptrm_ptrm_code
                                                                       and SZTPTRM_PTRM_CODE in ('M0B','M1A')
                                                                       And trunc (sobptrm_start_date) >  trunc (l_fecha)
                                                                        and SZTPTRM_PROGRAM =p_programa
                                                                        and sobptrm_term_code >=  (Select distinct SGBSTDN_TERM_CODE_EFF
                                                                                                                    from sgbstdn a
                                                                                                                    where 1= 1
                                                                                                                    and a.SGBSTDN_PIDM = p_pidm
                                                                                                                    and a.SGBSTDN_PROGRAM_1 = p_programa
                                                                                                                    And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)   
                                                                                                                                                                            from sgbstdn a1
                                                                                                                                                                            where 1= 1
                                                                                                                                                                            and a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                                                                                                                            and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1))
                                                                        AND TRUNC(sobptrm_start_date) >= TRUNC(SYSDATE) -SZTPTRM_ADICIONAL
                                                                        AND SZTPTRM_VISIBLE != 0 
                                                                       )
                                                                    where 1= 1
                                                                          and numero <= 2
                                                        ) 
                                                        order by 1;

                                        RETURN (fecha_out);
                           End;                   
                   
                   Elsif   l_nivel ='MS' and l_TIPO_INGRESO ='EQ' then  
                   dbms_output.put_line('entra 3');
                   
                           BEGIN
                                          open fecha_out
                                            FOR
                                                    select distinct Fecha_Inicio
                                                    from  (
                                                                Select distinct Fecha_Inicio , numero
                                                                from (           
                                                                         select distinct ROW_NUMBER() OVER (ORDER BY sobptrm_start_date) AS numero,   to_char (sobptrm_start_date,'dd/mm/rrrr') Fecha_Inicio
                                                                            from sztptrm, sobptrm
                                                                            where sztptrm_term_code = sobptrm_term_code
                                                                            and sztptrm_ptrm_code = sobptrm_ptrm_code
                                                                           and SZTPTRM_PTRM_CODE in ('A0B','A1A')
                                                                           And trunc (sobptrm_start_date) >  trunc (l_fecha)
                                                                            and SZTPTRM_PROGRAM =p_programa
                                                                            and sobptrm_term_code >=  (Select distinct SGBSTDN_TERM_CODE_EFF
                                                                                                                        from sgbstdn a
                                                                                                                        where 1= 1
                                                                                                                        and a.SGBSTDN_PIDM = p_pidm
                                                                                                                        and a.SGBSTDN_PROGRAM_1 = p_programa
                                                                                                                        And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)   
                                                                                                                                                                                from sgbstdn a1
                                                                                                                                                                                where 1= 1
                                                                                                                                                                                and a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                                                                                                                                and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1))
                                                                            AND TRUNC(sobptrm_start_date) >= TRUNC(SYSDATE) -SZTPTRM_ADICIONAL
                                                                            AND SZTPTRM_VISIBLE != 0 
                                                                           )
                                                                        where 1= 1
                                                                              and numero <= 2
                                                        ) 
                                                         order by 1;

                                        RETURN (fecha_out);
                           End;                   
                   Else   
                   dbms_output.put_line('entra 4');
                           BEGIN
                                          open fecha_out
                                            FOR
                                                select distinct Fecha_Inicio
                                                from  (
                                                            Select  distinct Fecha_Inicio, numero
                                                            from (                                           
                                                                        select distinct ROW_NUMBER() OVER (ORDER BY sobptrm_start_date) AS numero,   to_char (sobptrm_start_date,'dd/mm/rrrr') Fecha_Inicio
                                                                                                        from sztptrm, sobptrm
                                                                                                        where sztptrm_term_code = sobptrm_term_code
                                                                                                        and sztptrm_ptrm_code = sobptrm_ptrm_code
                                                                                              --         and SZTPTRM_PTRM_CODE in ('A0B','A1A')
                                                                                                        And trunc (sobptrm_start_date) >  trunc (l_fecha)
                                                                                                        and SZTPTRM_PROGRAM =p_programa
                                                                                                        and sobptrm_term_code >=  (Select distinct SGBSTDN_TERM_CODE_EFF
                                                                                                                                                    from sgbstdn a
                                                                                                                                                    where 1= 1
                                                                                                                                                    and a.SGBSTDN_PIDM = p_pidm
                                                                                                                                                    and a.SGBSTDN_PROGRAM_1 = p_programa
                                                                                                                                                    And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)   
                                                                                                                                                                                                            from sgbstdn a1
                                                                                                                                                                                                            where 1= 1
                                                                                                                                                                                                            and a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                                                                                                                                                            and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1))
                                                                                                        AND TRUNC(sobptrm_start_date) >= TRUNC(SYSDATE) -SZTPTRM_ADICIONAL
                                                                                                        AND SZTPTRM_VISIBLE != 0 
                                                                   )
                                                                where 1= 1
                                                                      and numero <= 2
                                                ) 
                                                 order by 1 desc;

                                        RETURN (fecha_out);
                           End;                   
                  
                          
                   End if;
             
            END f_fecha_inicio_out;


procedure bitacora (vl_pidm in number, vl_periodo in varchar2, vl_sp in number, vl_programa in varchar2, vl_comentario in varchar2, vl_origen in varchar2, F_Fecha_Ini_Old in varchar2)

as

  vn_sec_SGRSCMT number:=0;
  l_descripcion varchar2(2000):= null;
  
    Begin 
    
    dbms_output.put_line('entra bitacora1');
        
        Begin
              SELECT NVL(MAX(SGRSCMT_SEQ_NO),0)+1
            INTO vn_sec_SGRSCMT
          FROM SGRSCMT
          WHERE SGRSCMT_PIDM  = vl_pidm
          AND SGRSCMT_TERM_CODE = vl_periodo;
        Exception
                When Others then 
                  vn_sec_SGRSCMT :=1;
        End;

         l_descripcion:=   vl_comentario;--||' ' ||vl_periodo ||' '||vl_programa;

dbms_output.put_line('entra bitacora1 cadena '||l_descripcion);

                      
        BEgin

             INSERT INTO SGRSCMT (
                SGRSCMT_PIDM
            , SGRSCMT_SEQ_NO
            , SGRSCMT_TERM_CODE
            , SGRSCMT_COMMENT_TEXT
            , SGRSCMT_ACTIVITY_DATE
            , SGRSCMT_DATA_ORIGIN
            , SGRSCMT_USER_ID
            , SGRSCMT_VPDI_CODE
             )
             VALUES (
                vl_pidm
              , vn_sec_SGRSCMT
              , vl_periodo
              , l_descripcion
              , SYSDATE
              ,vl_origen
              , user
              , vl_sp
             );
        Exception
                When Others then 
                dbms_output.put_line('error  bitacora1 cadena '||sqlerrm);       
        End;


    Begin
        
     INSERT INTO SGBSTDB
                   
                   SELECT N.*,F_Fecha_Ini_Old, vn_sec_SGRSCMT, vl_sp
                   FROM SGBSTDN N 
                   WHERE N.SGBSTDN_PIDM = vl_pidm
                   AND N.SGBSTDN_TERM_CODE_EFF = vl_periodo;
                   
                   --:MINI_PERFIL.PERIODO;
    Exception
            When Others then 
                dbms_output.put_line('error  bitacora2 cadena '||sqlerrm);       
    End;



Exception
    when others then 
        null;
End bitacora;  

PROCEDURE ESTATUS_RAZON (P_PIDM VARCHAR2,
                                             P_ESTS_CODE_NEW VARCHAR2,
                                             P_RAZON VARCHAR2,
                                             f_fecha_inicio_nw VARCHAR2,
                                             P_PROGRAMA VARCHAR2
                         )IS
                         
  lv_existe NUMBER;   
  vl_exito varchar2(500):= 'EXITO';      
  VL_TZTPUNI   NUMBER;  
  ------------
  P_PERIODO varchar2(6); 
  P_SP number;
  f_fecha_inicio_old varchar2(12):= null;
  p_comentario varchar2(500):= null;
  vl_periodo_act varchar2(6):= null;
  vl_periodo_nw varchar2(6):= null;
  vl_bandera varchar2(10):=null;
  vl_sec_act number;
             
                         
BEGIN
            Begin 

                    Select distinct SGBSTDN_TERM_CODE_EFF
                        Into P_PERIODO
                    from sgbstdn a
                    where 1= 1
                    and a.SGBSTDN_PIDM = p_pidm
                    and a.SGBSTDN_PROGRAM_1 = p_programa
                    And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)   
                                                                            from sgbstdn a1
                                                                            where 1= 1
                                                                            and a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                            and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1);
            Exception
                When others then 
                    P_PERIODO:= null;
            End;




        dbms_output.put_line(' Parametros de  Entrada Pidm: ' ||P_PIDM ||'P_ESTS_CODE_NEW: '||P_ESTS_CODE_NEW ||' P_RAZON: '||P_RAZON ||' f_fecha_inicio_nw: '||f_fecha_inicio_nw ||' Periodo: '||P_PERIODO);
        
        Begin
        
                select distinct sp
                    Into P_SP
                from tztprog a 
                where a.pidm = p_pidm
                and a.programa = p_programa
                and a.sp = (Select max (a1.sp)
                                    from tztprog a1
                                    where a.pidm = a1.pidm
                                    and a.programa = a1.programa);        
        Exception
            When Others then 
                P_SP := 1;
        End;        
        
        
        

            Begin

                        select distinct  to_char (SORLCUR_START_DATE,'dd/mm/rrrr')
                         Into f_fecha_inicio_old
                        FROM SORLCUR A
                        WHERE 1 = 1
                        and A.SORLCUR_PIDM = p_pidm
                        AND A.SORLCUR_PROGRAM =P_PROGRAMA
                        AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                        AND A.SORLCUR_ROLL_IND  = 'Y'
                        AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                        AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                                   FROM SORLCUR A1
                                                                   WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                  -- AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                                                   )  ;                                      
                                        
                                        
                                      
            Exception
                When others then 
                    f_fecha_inicio_old := null;
            End;

 dbms_output.put_line('Dato Entrada ' ||P_SP||' '||f_fecha_inicio_old);

          IF (sb_enrollment.f_exists( P_PIDM  , P_PERIODO )<>'Y')  THEN
          
                                Begin 
          
                                dbms_output.put_line('Entra1 ' ||vl_exito);                                        
                                
                                                INSERT INTO SFBETRM (
                                                             SFBETRM_TERM_CODE, SFBETRM_PIDM, SFBETRM_ESTS_CODE, SFBETRM_ESTS_DATE, SFBETRM_MHRS_OVER,
                                                             SFBETRM_AR_IND, SFBETRM_ASSESSMENT_DATE, SFBETRM_ADD_DATE, SFBETRM_ACTIVITY_DATE, SFBETRM_RGRE_CODE, 
                                                             SFBETRM_TMST_CODE, SFBETRM_TMST_DATE, SFBETRM_TMST_MAINT_IND, SFBETRM_USER, SFBETRM_REFUND_DATE, 
                                                             SFBETRM_DATA_ORIGIN, SFBETRM_INITIAL_REG_DATE, SFBETRM_MIN_HRS, SFBETRM_MINH_SRCE_CDE, SFBETRM_MAXH_SRCE_CDE,
                                                             SFBETRM_SURROGATE_ID, SFBETRM_VERSION, SFBETRM_USER_ID, SFBETRM_VPDI_CODE)
                                                VALUES ( P_PERIODO, P_PIDM ,  'EL'/*'EL'*/, SYSDATE, 999999.999, 
                                                         'N',  NULL,   SYSDATE,   SYSDATE, P_RAZON, 
                                                         '',   NULL,   '',  USER, NULL,
                                                         'SSB',   SYSDATE  , 0.000,  'M','M',
                                                           null, null, null, null);
                                                    Commit;
                                Exception
                                    When others then
                                        vl_exito:= 'Error al insertar en  SFBETRM ' || sqlerrm;       
                                        dbms_output.put_line('error1 ' ||vl_exito);                   
                                End;
                                
                                If vl_exito ='EXITO' then
                                dbms_output.put_line('Entra2 ' ||vl_exito);
                                
                                    Begin 
                                             INSERT INTO SFRENSP (SFRENSP_TERM_CODE, SFRENSP_PIDM,
                                                         SFRENSP_KEY_SEQNO, SFRENSP_ESTS_CODE, SFRENSP_ESTS_DATE,
                                                         SFRENSP_ADD_DATE, SFRENSP_ACTIVITY_DATE,
                                                         SFRENSP_USER, SFRENSP_DATA_ORIGIN, 
                                                         SFRENSP_SURROGATE_ID, SFRENSP_VERSION, SFRENSP_USER_ID, SFRENSP_VPDI_CODE)
                                            VALUES (P_PERIODO, P_PIDM , 
                                                        P_SP,  'EL'/* 'EL'*/,  SYSDATE,   
                                                        SYSDATE,  SYSDATE,     
                                                        USER , 'SSB',
                                                         null, null, null, null );
                                                         Commit;
                                    Exception
                                        When Others then 
                                          vl_exito:= 'Error al insertar en  SFRENSP ' || sqlerrm;            
                                          dbms_output.put_line('error2 ' ||vl_exito);                     
                                    End;
                                                 
                                End if;
                            
          ELSE

                    dbms_output.put_line('Entra 3 ');                 
                                FOR TRM IN (
                                                        SELECT C.SFBETRM_ESTS_DATE, C.SFBETRM_ADD_DATE, C.SFBETRM_ESTS_CODE, C.SFBETRM_TERM_CODE
                                                      FROM   SFBETRM C
                                                      WHERE  C.sfbetrm_pidm = P_PIDM
                                                      and c.SFBETRM_TERM_CODE = P_PERIODO

                               ) LOOP                              
                                            Begin 
                                                    Update SFBETRM
                                                    set SFBETRM_ESTS_CODE = 'EL'/*'EL'*/,
                                                        SFBETRM_RGRE_CODE =P_RAZON,
                                                        SFBETRM_ACTIVITY_DATE = SYSDATE,
                                                        SFBETRM_DATA_ORIGIN = 'SSB',
                                                        SFBETRM_USER_ID = USER
                                                    where SFBETRM_PIDM = P_PIDM
                                                    And SFBETRM_TERM_CODE = TRM.SFBETRM_TERM_CODE
                                                    And SFBETRM_ESTS_CODE = TRM.SFBETRM_ESTS_CODE;
                                                    Commit;
                                            Exception
                                                When  Others then 
                                                    null;
                                            End;
                                        
                                            Begin 
                                                    select count (*)
                                                        Into lv_existe
                                                    from SFRENSP
                                                    where SFRENSP_PIDM = P_PIDM
                                                    and SFRENSP_TERM_CODE = TRM.SFBETRM_TERM_CODE
                                                    And SFRENSP_KEY_SEQNO = P_SP;
                                                    
                                            Exception
                                                When Others then 
                                                  lv_existe:=0;  
                                            End;
                                       
                                            If lv_existe >= 1 then 
                                                  Begin
                                                          Update SFRENSP
                                                          set SFRENSP_ESTS_CODE = 'EL',/*'EL'*/
                                                              SFRENSP_ACTIVITY_DATE = SYSDATE,
                                                              SFRENSP_DATA_ORIGIN = 'SSB',
                                                              SFRENSP_USER_ID = USER
                                                          where SFRENSP_PIDM = P_PIDM
                                                          and SFRENSP_TERM_CODE = TRM.SFBETRM_TERM_CODE--CASE VN_INSERTA WHEN 1 THEN vc_periodo_horarios ELSE :MINI_PERFIL.PERIODO END
                                                          And SFRENSP_KEY_SEQNO = P_SP;
                                                          Commit;
                                                  Exception 
                                                  When Others then 
                                                    null;
                                                  End;
                                            Elsif lv_existe = 0 then 
                                                   Begin 
                                                          Insert into SFRENSP values (  TRM.SFBETRM_TERM_CODE,--CASE VN_INSERTA WHEN 1 THEN vc_periodo_horarios ELSE :MINI_PERFIL.PERIODO END,
                                                                                        P_PIDM, 
                                                                                        P_SP,
                                                                                      'EL',
                                                                                        TRM.SFBETRM_ESTS_DATE,--vd_ESTS_DATE,
                                                                                        TRM.SFBETRM_ADD_DATE,--vd_ADD_DATE,
                                                                                        sysdate,
                                                                                        user,--'MIGRA',
                                                                                        'SSB',--'UTEL',
                                                                                        null,
                                                                                        null,
                                                                                        user,--'MIGRA',
                                                                                        NULL);
                                                              Commit;
                                                   Exception
                                                    When Others then
                                                        null;                                     
                                                   End;
                                                   
                                            End if;
                               END LOOP;
                               
          END IF;
          

           vl_exito := pkg_abcc.f_baja_materias ('BI',
                                                                  to_date (f_fecha_inicio_old,'dd/mm/rrrr'),
                                                                  p_programa,
                                                                  P_PIDM
                                                                    );
            Commit;
           dbms_output.put_line('baja_materia  '||vl_exito); 
          
          ----------- Cambio el estatus en SORLCUR -------------------------
          
          Begin 
           dbms_output.put_line('Entra 4 ');            
          
                    UPDATE sorlcur 
                        SET sorlcur_start_date = to_date (f_fecha_inicio_nw,'dd/mm/rrrr'),
                               sorlcur_data_origin = 'SSB',
                               sorlcur_activity_date = SYSDATE,
                               sorlcur_user_id = USER
                    WHERE sorlcur_pidm = P_PIDM
                    AND sorlcur_program = P_PROGRAMA
                    AND sorlcur_lmod_code = 'LEARNER'
                    And trunc (sorlcur_start_date) = to_date (f_fecha_inicio_old,'dd/mm/rrrr');
                    Commit;
          Exception
            When Others then 
                null;       
                dbms_output.put_line('Error 4 '||sqlerrm);              
          End;
    

                                             
----------------------------------- Hace el proceso de cancelacion de Financiera ---------------------------
 dbms_output.put_line('Cancelacion Financiera ');        

      for cx in (
                                
                        SELECT DISTINCT
                               a.sfrstcr_pidm Pidm,
                               a.sfrstcr_term_code Periodo,
                               a.sfrstcr_ptrm_code Pperiodo,
                               SSBSECT_PTRM_START_DATE Fecha_Inicio,
                               ssbsect_ptrm_end_date Fecha_Fin,
                               a.sfrstcr_camp_code Campus,
                               a.sfrstcr_levl_code Nivel
                        FROM ssbsect, 
                             sfrstcr a
                        WHERE ssbsect_term_code = a.sfrstcr_term_code
                        AND ssbsect_crn = a.sfrstcr_crn
                        AND ssbsect_ptrm_code = a.sfrstcr_ptrm_code
                         and substr(a.sfrstcr_term_code,5,1) not in ('8','9')
                        --AND a.sfrstcr_stsp_key_sequence = P_SP
                        and trunc (SSBSECT_PTRM_START_DATE) = to_Date(f_fecha_inicio_old, 'dd/mm/yyyy')
                        AND a.sfrstcr_pidm = P_PIDM
                        AND a.sfrstcr_term_code =
                                               (SELECT MAX (b.sfrstcr_term_code)
                                                FROM sfrstcr b
                                                WHERE b.sfrstcr_pidm = a.sfrstcr_pidm
                                                And  b.sfrstcr_stsp_key_sequence = a.sfrstcr_stsp_key_sequence
                                                and substr(b.sfrstcr_term_code,5,1) not in ('8','9'))

        ) loop

              vl_exito:= 'EXITO';
              dbms_output.put_line('Cancelacion Financiera Entra ');

                     vl_exito :=  pkg_finanzas.f_actu_tzfacce (
                                                                                     p_pidm              => P_PIDM,
                                                                                     p_periodo          => P_PERIODO,
                                                                                     p_fecha_nueva   => to_date (f_fecha_inicio_nw,'dd/mm/rrrr'),
                                                                                     p_fecha_old       => to_date (f_fecha_inicio_old,'dd/mm/rrrr'),
                                                                                     p_per_nuevo      => P_PERIODO,
                                                                                     p_programa       => P_PROGRAMA,
                                                                                     p_campus          => cx.campus,
                                                                                     p_nivel              => cx.nivel);
                                            Commit;                                                         
                                            dbms_output.put_line('salida facce  '||vl_exito);
                                                                                     
                     vl_exito:=PKG_FINANZAS_DINAMICOS.F_CAMBIO_FECHA_PADI ( P_PIDM, 
                                                                                                                         P_PERIODO, 
                                                                                                                         to_date (f_fecha_inicio_nw,'dd/mm/rrrr'),
                                                                                                                         to_date (f_fecha_inicio_old,'dd/mm/rrrr'), 
                                                                                                                         P_PERIODO, 
                                                                                                                         P_PROGRAMA);
                                              Commit;       
                                            dbms_output.put_line('salida dinamicoa  '||vl_exito);

                     vl_exito :=  pkg_abcc.f_baja_economica (
                                                                                       pn_pidm           => P_PIDM,
                                                                                       pn_campus       => cx.campus,
                                                                                       pn_nivel            => cx.nivel,
                                                                                       pn_estatus        => 'CF', 
                                                                                       pn_programa     => null, 
                                                                                       pn_periodo        => P_PERIODO,
                                                                                       pn_fecha_baja   => TO_DATE (SYSDATE,'dd/mm/rrrr'),
                                                                                       pn_fecha_inicio   => to_date (f_fecha_inicio_old,'dd/mm/rrrr'), 
                                                                                       pn_fecha_fin      => TO_DATE (SYSDATE,'dd/mm/rrrr'),
                                                                                       pn_keyseqno       => P_SP);

                                        Commit;
                                        dbms_output.put_line('salida bajaeconomica  '||vl_exito);

                     IF vl_exito != 'EXITO' THEN
                            null;
                     ELSE

                            BEGIN
                                        UPDATE TZTORDR
                                        SET TZTORDR_ESTATUS       = 'N',
                                            TZTORDR_ACTIVITY_DATE = SYSDATE,
                                            TZTORDR_DATA_ORIGIN   = 'SSB',
                                            TZTORDR_USER          = USER
                                          WHERE TZTORDR_PIDM      = P_PIDM
                                           AND TZTORDR_CAMPUS     =  cx.campus
                                           AND TZTORDR_NIVEL      = cx.nivel
                                           AND TZTORDR_PROGRAMA   = P_PROGRAMA
                                           AND TZTORDR_CONTADOR   = (SELECT  MAX(SFRSTCR_VPDI_CODE)
                                                                                                     FROM SFRSTCR
                                                                                                     WHERE SFRSTCR_PIDM     =P_PIDM 
                                                                                                     and SFRSTCR_LEVL_CODE  = cx.nivel
                                                                                                     and SFRSTCR_CAMP_CODE  =cx.campus) ;
                                          Commit;
                            EXCEPTION WHEN OTHERS THEN
                                vl_exito:='Se presento un error al actualizar la Orden de Compra '|| sqlerrm;
                                dbms_output.put_line('error 5  '||vl_exito);
                            END;
                            
                     /*  SE CANCELA EL AJUSTE DE PAGO UNICO PARA PARA CALCULAR NUEVA FECHA DE APLICACIÓN */


                             BEGIN
                                SELECT COUNT (*)
                                INTO vl_tztpuni
                                FROM tztpuni
                                WHERE tztpuni_pidm = P_PIDM
                                AND tztpuni_fecha_inicio =to_date (f_fecha_inicio_old,'dd/mm/rrrr')
                                AND tztpuni_chech_final IS NULL;                        
                             EXCEPTION WHEN OTHERS THEN
                                   vl_tztpuni := 0;
                             END;

                             IF vl_tztpuni > 0 THEN
                                vl_exito := pkg_finanzas.f_can_uni (P_PIDM,
                                                                                    to_date (f_fecha_inicio_old,'dd/mm/rrrr'));
                                                Commit;

                                BEGIN
                                   UPDATE tztpuni 
                                    SET tztpuni_fecha_inicio = to_date (f_fecha_inicio_nw,'dd/mm/rrrr'),
                                           tztpuni_prox_fecha = NULL
                                    WHERE tztpuni_pidm =P_PIDM
                                    AND tztpuni_fecha_inicio = to_date (f_fecha_inicio_old,'dd/mm/rrrr')
                                    AND tztpuni_chech_final IS NULL;
                                    Commit;
                                Exception
                                    When others then 
                                         vl_exito:='Se presento un error al actualizar la Orden de Compra de Pago Unico '|| sqlerrm;   
                                END;
                                
                             END IF;                            
                            
                     


                     END IF;

        End Loop;
        
       dbms_output.put_line('llega a Bitacora  '||vl_exito);
       
       p_comentario:=null;
        If P_RAZON ='CF' then  ---> Los comentarios se deben de crecer de acuerdo al tipo de servicio
              dbms_output.put_line('Entra al comentario  '||p_comentario);
         p_comentario := 'Cambio de Fecha Solictado por el alumno SSB ' ||P_PERIODO ||
                                                                                                       '  '||P_PROGRAMA || ' Fecha de inicio anterior ' 
                                                                                                           || f_fecha_inicio_old || ' Fecha de inicio Nueva '
                                                                                                           || f_fecha_inicio_nw ;
                                                                                                           
       --     p_comentario := 'Cambio de Fecha Solictado por el alumno SSB ' ||P_PERIODO ||P_PROGRAMA || f_fecha_inicio_old|| f_fecha_inicio_nw ;                                                                                                           
                                                                                                           
                    dbms_output.put_line('Salida a Comentario  '||p_comentario);                                                                                        
                                                                                                           
        End if;
        
        dbms_output.put_line('llega a Comentario  '||p_comentario);
                                                                                                                    
        pkg_abcc.bitacora (P_PIDM, 
                                    P_PERIODO, 
                                    P_SP, 
                                    P_PROGRAMA, 
                                    p_comentario, 
                                    'SSB',
                                    f_fecha_inicio_old);   
          Commit;          
          
        vl_periodo_act:= null;  
        vl_sec_act := null;
        Begin 
                    Select distinct SORLCUR_TERM_CODE, SORLCUR_SEQNO
                        into vl_periodo_act, vl_sec_act
                    from sorlcur a
                    WHERE a.sorlcur_pidm = P_PIDM
                    AND a.sorlcur_program = P_PROGRAMA
                    AND a.sorlcur_lmod_code = 'LEARNER'
                    And trunc (a.sorlcur_start_date) = to_date (f_fecha_inicio_nw,'dd/mm/rrrr')
                    And a.SORLCUR_SEQNO in (select max (a1.SORLCUR_SEQNO)
                                                            from sorlcur a1
                                                            Where a.sorlcur_pidm = a1.sorlcur_pidm
                                                            and a.sorlcur_program = a1.sorlcur_program
                                                            And a.sorlcur_lmod_code = a1.sorlcur_lmod_code
                                                            And a.sorlcur_start_date = a1.sorlcur_start_date
                                                            );
         Exception
            When Others then
                    vl_periodo_act := null;
        End;
          
        vl_periodo_Nw:= null;
        Begin 
                Select distinct SZTPTRM_TERM_CODE
                    Into vl_periodo_Nw
                from SZTPTRM
                join SOBPTRM on SOBPTRM_TERM_CODE = SZTPTRM_TERM_CODE 
                      And SOBPTRM_PTRM_CODE = SZTPTRM_PTRM_CODE 
                where 1= 1
                And SZTPTRM_PROGRAM =  P_PROGRAMA
                And trunc (SOBPTRM_START_DATE)  = to_date (f_fecha_inicio_nw,'dd/mm/rrrr')
                And SZTPTRM_VISIBLE = 1;
        Exception
            When Others then 
                null;
        End;
         
        If vl_periodo_Nw != vl_periodo_Act then 
        
           vl_bandera:= null;
        
             Begin 
                   
                        Insert into SORLCUR
                                    Select distinct 
                                        SORLCUR_PIDM
                                        ,SORLCUR_SEQNO +1                 
                                        ,SORLCUR_LMOD_CODE            
                                        ,vl_periodo_Nw         
                                        ,SORLCUR_KEY_SEQNO         
                                        ,SORLCUR_PRIORITY_NO          
                                        ,SORLCUR_ROLL_IND             
                                        ,SORLCUR_CACT_CODE        
                                        ,user              
                                        ,'SSB'        
                                        ,sysdate   
                                        ,SORLCUR_LEVL_CODE         
                                        ,SORLCUR_COLL_CODE         
                                        ,SORLCUR_DEGC_CODE           
                                        ,SORLCUR_TERM_CODE_CTLG     
                                        ,SORLCUR_TERM_CODE_END     
                                        ,SORLCUR_TERM_CODE_MATRIC  
                                        ,SORLCUR_TERM_CODE_ADMIT  
                                        ,SORLCUR_ADMT_CODE           
                                        ,SORLCUR_CAMP_CODE         
                                        ,SORLCUR_PROGRAM              
                                        ,SORLCUR_START_DATE         
                                        ,SORLCUR_END_DATE             
                                        ,SORLCUR_CURR_RULE           
                                        ,SORLCUR_ROLLED_SEQNO         
                                        ,SORLCUR_STYP_CODE             
                                        ,SORLCUR_RATE_CODE            
                                        ,SORLCUR_LEAV_CODE             
                                        ,SORLCUR_LEAV_FROM_DATE       
                                        ,SORLCUR_LEAV_TO_DATE          
                                        ,SORLCUR_EXP_GRAD_DATE         
                                        ,SORLCUR_TERM_CODE_GRAD 
                                        ,SORLCUR_ACYR_CODE 
                                        ,SORLCUR_SITE_CODE  
                                        ,SORLCUR_APPL_SEQNO    
                                        ,SORLCUR_APPL_KEY_SEQNO  
                                        ,sysdate  
                                        ,sysdate 
                                        ,SORLCUR_GAPP_SEQNO    
                                        ,SORLCUR_CURRENT_CDE    
                                        ,null    
                                        ,null          
                                        ,SORLCUR_VPDI_CODE      
                                    from sorlcur a
                                    WHERE a.sorlcur_pidm = P_PIDM
                                    AND a.sorlcur_program = P_PROGRAMA
                                    AND a.sorlcur_lmod_code = 'LEARNER'
                                    And trunc (a.sorlcur_start_date) = to_date (f_fecha_inicio_nw,'dd/mm/rrrr')
                                    And a.SORLCUR_SEQNO in (select max (a1.SORLCUR_SEQNO)
                                                                            from sorlcur a1
                                                                            Where a.sorlcur_pidm = a1.sorlcur_pidm
                                                                            and a.sorlcur_program = a1.sorlcur_program
                                                                            And a.sorlcur_lmod_code = a1.sorlcur_lmod_code
                                                                            And a.sorlcur_start_date = a1.sorlcur_start_date
                                                                            );  
                          vl_bandera:= 'EXITO';                                                                                                       
             Exception
                When Others then 
                    vl_bandera:= 'ERROR';                                            
             End;
             
             If vl_bandera = 'EXITO' then 
                 Begin 
                        Update sorlcur a
                        set SORLCUR_ROLL_IND = 'N',
                              SORLCUR_CACT_CODE = 'INACTIVE'
                        WHERE a.sorlcur_pidm = P_PIDM
                        AND a.sorlcur_program = P_PROGRAMA
                        AND a.sorlcur_lmod_code = 'LEARNER'
                        And a.SORLCUR_SEQNO = vl_sec_act
                        and SORLCUR_TERM_CODE = vl_periodo_Act;
                        
                        vl_bandera:= 'EXITO';
                 Exception
                    When Others then 
                         vl_bandera:= 'ERROR';               
                 End;
             End if;
             
             If vl_bandera = 'EXITO' then 
                 Begin 
                        Insert into SORLFOS
                        Select distinct 
                        SORLFOS_PIDM
                        ,SORLFOS_LCUR_SEQNO+1
                        ,SORLFOS_SEQNO
                        ,SORLFOS_LFST_CODE 
                        ,vl_periodo_Nw 
                        ,SORLFOS_PRIORITY_NO 
                        ,SORLFOS_CSTS_CODE 
                        ,SORLFOS_CACT_CODE
                        ,'SSB'
                        ,user 
                        ,sysdate  
                        ,SORLFOS_MAJR_CODE   
                        ,SORLFOS_TERM_CODE_CTLG 
                        ,SORLFOS_TERM_CODE_END 
                        ,SORLFOS_DEPT_CODE        
                        ,SORLFOS_MAJR_CODE_ATTACH  
                        ,SORLFOS_LFOS_RULE     
                        ,SORLFOS_CONC_ATTACH_RULE    
                        ,SORLFOS_START_DATE      
                        ,SORLFOS_END_DATE           
                        ,SORLFOS_TMST_CODE         
                        ,SORLFOS_ROLLED_SEQNO      
                        ,user    
                        ,sysdate 
                        ,SORLFOS_CURRENT_CDE    
                        ,null      
                        ,SORLFOS_VERSION       
                        ,SORLFOS_VPDI_CODE       
                        from sorlfos
                        where 1= 1
                        and sorlfos_pidm = P_PIDM
                        And SORLFOS_LCUR_SEQNO = vl_sec_act 
                        ;
                        vl_bandera:= 'EXITO';
                 Exception
                    When Others then 
                         vl_bandera:= 'ERROR';               
                 End;
             End if;             
             
             If vl_bandera = 'EXITO' then 
                 Begin 
                        Update SORLFOS a
                        set SORLFOS_CACT_CODE = 'INACTIVE',
                              SORLFOS_DATA_ORIGIN = 'SSB',
                              SORLFOS_USER_ID = user,
                              SORLFOS_ACTIVITY_DATE = sysdate,
                              SORLFOS_USER_ID_UPDATE = user,
                              SORLFOS_ACTIVITY_DATE_UPDATE = sysdate
                        WHERE 1=1
                        and sorlfos_pidm = P_PIDM
                        And SORLFOS_LCUR_SEQNO = vl_sec_act 
                        ;
                        vl_bandera:= 'EXITO';
                 Exception
                    When Others then 
                         vl_bandera:= 'ERROR';               
                 End;
             End if;             
        
        End if; 
          
        
        Begin 
                select distinct SGBSTDN_TERM_CODE_EFF
                    Into vl_periodo_Act
                from sgbstdn a
                where 1=1
                and a.SGBSTDN_PIDM = P_PIDM
                And a.SGBSTDN_PROGRAM_1  = P_PROGRAMA
                And a.SGBSTDN_TERM_CODE_EFF =  (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                         from SGBSTDN a1
                                                                         Where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                         And a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1)  ;     
        Exception
            When Others then 
                vl_periodo_Act:= null;
        End;
        
        If vl_periodo_Nw != vl_periodo_Act then 
            Begin
                    Insert into SGBSTDN 
                    select   SGBSTDN_PIDM                
                    ,vl_periodo_Nw    
                    ,SGBSTDN_STST_CODE           
                    ,SGBSTDN_LEVL_CODE        
                    ,SGBSTDN_STYP_CODE            
                    ,SGBSTDN_TERM_CODE_MATRIC    
                    ,SGBSTDN_TERM_CODE_ADMIT      
                    ,SGBSTDN_EXP_GRAD_DATE     
                    ,SGBSTDN_CAMP_CODE            
                    ,SGBSTDN_FULL_PART_IND       
                    ,SGBSTDN_SESS_CODE           
                    ,SGBSTDN_RESD_CODE            
                    ,SGBSTDN_COLL_CODE_1         
                    ,SGBSTDN_DEGC_CODE_1           
                    ,SGBSTDN_MAJR_CODE_1         
                    ,SGBSTDN_MAJR_CODE_MINR_1      
                    ,SGBSTDN_MAJR_CODE_MINR_1_2    
                    ,SGBSTDN_MAJR_CODE_CONC_1     
                    ,SGBSTDN_MAJR_CODE_CONC_1_2   
                    ,SGBSTDN_MAJR_CODE_CONC_1_3    
                    ,SGBSTDN_COLL_CODE_2           
                    ,SGBSTDN_DEGC_CODE_2         
                    ,SGBSTDN_MAJR_CODE_2          
                    ,SGBSTDN_MAJR_CODE_MINR_2     
                    ,SGBSTDN_MAJR_CODE_MINR_2_2    
                    ,SGBSTDN_MAJR_CODE_CONC_2      
                    ,SGBSTDN_MAJR_CODE_CONC_2_2    
                    ,SGBSTDN_MAJR_CODE_CONC_2_3    
                    ,SGBSTDN_ORSN_CODE             
                    ,SGBSTDN_PRAC_CODE             
                    ,SGBSTDN_ADVR_PIDM             
                    ,SGBSTDN_GRAD_CREDIT_APPR_IND  
                    ,SGBSTDN_CAPL_CODE             
                    ,SGBSTDN_LEAV_CODE             
                    ,SGBSTDN_LEAV_FROM_DATE       
                    ,SGBSTDN_LEAV_TO_DATE         
                    ,SGBSTDN_ASTD_CODE            
                    ,SGBSTDN_TERM_CODE_ASTD        
                    ,SGBSTDN_RATE_CODE             
                    ,sysdate         
                    ,SGBSTDN_MAJR_CODE_1_2        
                    ,SGBSTDN_MAJR_CODE_2_2         
                    ,SGBSTDN_EDLV_CODE            
                    ,SGBSTDN_INCM_CODE            
                    ,SGBSTDN_ADMT_CODE             
                    ,SGBSTDN_EMEX_CODE             
                    ,SGBSTDN_APRN_CODE            
                    ,SGBSTDN_TRCN_CODE            
                    ,SGBSTDN_GAIN_CODE            
                    ,SGBSTDN_VOED_CODE             
                    ,SGBSTDN_BLCK_CODE            
                    ,SGBSTDN_TERM_CODE_GRAD      
                    ,SGBSTDN_ACYR_CODE           
                    ,SGBSTDN_DEPT_CODE           
                    ,SGBSTDN_SITE_CODE           
                    ,SGBSTDN_DEPT_CODE_2           
                    ,SGBSTDN_EGOL_CODE           
                    ,SGBSTDN_DEGC_CODE_DUAL      
                    ,SGBSTDN_LEVL_CODE_DUAL     
                    ,SGBSTDN_DEPT_CODE_DUAL    
                    ,SGBSTDN_COLL_CODE_DUAL       
                    ,SGBSTDN_MAJR_CODE_DUAL   
                    ,SGBSTDN_BSKL_CODE         
                    ,SGBSTDN_PRIM_ROLL_IND      
                    ,SGBSTDN_PROGRAM_1          
                    ,SGBSTDN_TERM_CODE_CTLG_1     
                    ,SGBSTDN_DEPT_CODE_1_2      
                    ,SGBSTDN_MAJR_CODE_CONC_121  
                    ,SGBSTDN_MAJR_CODE_CONC_122  
                    ,SGBSTDN_MAJR_CODE_CONC_123  
                    ,SGBSTDN_SECD_ROLL_IND     
                    ,SGBSTDN_TERM_CODE_ADMIT_2   
                    ,SGBSTDN_ADMT_CODE_2      
                    ,SGBSTDN_PROGRAM_2          
                    ,SGBSTDN_TERM_CODE_CTLG_2   
                    ,SGBSTDN_LEVL_CODE_2      
                    ,SGBSTDN_CAMP_CODE_2        
                    ,SGBSTDN_DEPT_CODE_2_2     
                    ,SGBSTDN_MAJR_CODE_CONC_221   
                    ,SGBSTDN_MAJR_CODE_CONC_222   
                    ,SGBSTDN_MAJR_CODE_CONC_223   
                    ,SGBSTDN_CURR_RULE_1         
                    ,SGBSTDN_CMJR_RULE_1_1       
                    ,SGBSTDN_CCON_RULE_11_1     
                    ,SGBSTDN_CCON_RULE_11_2    
                    ,SGBSTDN_CCON_RULE_11_3     
                    ,SGBSTDN_CMJR_RULE_1_2       
                    ,SGBSTDN_CCON_RULE_12_1    
                    ,SGBSTDN_CCON_RULE_12_2     
                    ,SGBSTDN_CCON_RULE_12_3    
                    ,SGBSTDN_CMNR_RULE_1_1     
                    ,SGBSTDN_CMNR_RULE_1_2      
                    ,SGBSTDN_CURR_RULE_2        
                    ,SGBSTDN_CMJR_RULE_2_1       
                    ,SGBSTDN_CCON_RULE_21_1     
                    ,SGBSTDN_CCON_RULE_21_3     
                    ,SGBSTDN_CCON_RULE_21_2     
                    ,SGBSTDN_CMJR_RULE_2_2       
                    ,SGBSTDN_CCON_RULE_22_1     
                    ,SGBSTDN_CCON_RULE_22_2      
                    ,SGBSTDN_CCON_RULE_22_3     
                    ,SGBSTDN_CMNR_RULE_2_1      
                    ,SGBSTDN_CMNR_RULE_2_2      
                    ,SGBSTDN_PREV_CODE            
                    ,SGBSTDN_TERM_CODE_PREV     
                    ,SGBSTDN_CAST_CODE           
                    ,SGBSTDN_TERM_CODE_CAST    
                    ,'SSB'        
                    ,user             
                    ,SGBSTDN_SCPC_CODE           
                    ,null      
                    ,SGBSTDN_VERSION             
                    ,SGBSTDN_VPDI_CODE        
                    from sgbstdn a
                    where 1=1
                    and a.SGBSTDN_PIDM = P_PIDM
                    And a.SGBSTDN_PROGRAM_1  = P_PROGRAMA
                    And a.SGBSTDN_TERM_CODE_EFF =  (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                             from SGBSTDN a1
                                                                             Where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                             And a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1)  ;                 
                    vl_bandera:= 'EXITO';
                 Exception
                    When Others then 
                         vl_bandera:= 'ERROR';               
                 End;
        
        
        End if;          
                                    
        
        If vl_exito ='EXITO' then 
           Commit;
        Else
            rollback;
       End if;                                      

    
END ESTATUS_RAZON;


PROCEDURE MATERIAS_AB(P_PERIODO  in VARCHAR2,
                                        P_CODE_NEW in VARCHAR2,
                                        P_CODE_HOLD in VARCHAR2,
                                        F_Fecha_Ini_Old in date,
                                        P_sp in number ,
                                        P_pidm in number 
                       )IS
    l_retorna VARCHAR2(100);                       
BEGIN
    
--    message('entra ab1 ');
--    message('entra ab1 ');
    
  for cal in (
  
                    select count(SFRSTCR_GRDE_CODE) calif, sfrstcr_crn,SFRSTCR_TERM_CODE
                    from ssbsect, sfrstcr
                    where SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE
                    and SSBSECT_CRN    = SFRSTCR_CRN
                    and SSBSECT_PTRM_CODE=SFRSTCR_PTRM_CODE
                    and SFRSTCR_RSTS_CODE = NVL(P_CODE_HOLD,SFRSTCR_RSTS_CODE)--'DD'
                    and SFRSTCR_STSP_KEY_SEQUENCE = P_sp
                    and sfrstcr_pidm= P_pidm
                    and SFRSTCR_TERM_CODE = NVL(P_PERIODO,SFRSTCR_TERM_CODE)
                    and substr(sfrstcr_term_code,5,1) not in ('8','9')
                    And trunc (SSBSECT_PTRM_START_DATE) = trunc (F_Fecha_Ini_Old)
                    group by sfrstcr_crn,SFRSTCR_TERM_CODE
                    
     ) loop
                                                
                       if cal.calif = 0 then
                            
                            
                            if P_CODE_NEW in ('BD', 'DD') then
                                      update sfrstcr 
                                      set sfrstcr_rsts_code=P_CODE_NEW,-- 'RE'
                                            SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                            SFRSTCR_USER_ID = USER,
                                            SFRSTCR_BILL_HR  = 0,
                                            SFRSTCR_CREDIT_HR = 0,
                                            SFRSTCR_BILL_HR_HOLD = 0,
                                            SFRSTCR_CREDIT_HR_HOLD = 0,
                                            SFRSTCR_ERROR_FLAG = 'D',
                                            SFRSTCR_class_sort_key  = 1,
                                            SFRSTCR_DATA_ORIGIN ='SSB'
                                      where sfrstcr_pidm=P_pidm
                                      and sfrstcr_term_code= cal.SFRSTCR_TERM_CODE--P_PERIODO
                                      and sfrstcr_crn = cal.sfrstcr_crn
                                      AND SFRSTCR_GRDE_CODE IS NULL;
                            else      
                                  update sfrstcr set sfrstcr_rsts_code=P_CODE_NEW,-- 'RE'
                                                         SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                                         SFRSTCR_USER_ID = USER,
                                                         SFRSTCR_DATA_ORIGIN ='SSB',
                                                         SFRSTCR_ERROR_FLAG = 'D',
                                                         SFRSTCR_class_sort_key = 1
                                      where sfrstcr_pidm=P_pidm
                                      and sfrstcr_term_code= cal.SFRSTCR_TERM_CODE--P_PERIODO
                                      and sfrstcr_crn = cal.sfrstcr_crn
                                      AND SFRSTCR_GRDE_CODE IS NULL;
                              
                            end if;
                                
                            Begin 

                                    update sfrareg 
                                    set sfrareg_rsts_code= P_CODE_NEW,--'RE'
                                        SFRAREG_ACTIVITY_DATE = SYSDATE,
                                        SFRAREG_USER_ID = USER
                                     where sfrareg_pidm=P_pidm
                                    and sfrareg_term_code= cal.SFRSTCR_TERM_CODE--P_PERIODO --c.term 
                                    and sfrareg_crn=cal.sfrstcr_crn;
                            Exception
                                When others then 
                                    null;
                            End;
                
                       end if;

                                            
     end loop;                        
                   
END MATERIAS_AB;


 FUNCTION f_baja_materias(
                                    p_estatus varchar2,
                                    p_fecha_inicio date,
                                    p_programa varchar2,
                                    p_pidm    number
                                    )RETURN   varchar2
        is
        l_programa          varchar2(20);
        l_sp                number;
        l_retorna           varchar2(500):='EXITO';
        l_fecha_inicio_sor  date;
        l_matricula         varchar2(10);
        l_campus            varchar2(5);
        l_nivel             varchar2(5);
        l_periodo           varchar2(10);
        l_regla             number;
        l_materias_re       number;
        l_materias_dd       number;
        l_secuen_max        number;
        l_estatus           varchar2(10);
        l_contar_horario    number;
        l_acredita          varchar2(1);
        VL_FECHA_BAJA   DATE ;

    BEGIN

        l_matricula:=f_matricula(p_pidm);

        BEGIN

           SELECT DISTINCT sorlcur_program,
                           cur.sorlcur_key_seqno,
                           sorlcur_start_date,
                           sorlcur_camp_code,
                           sorlcur_levl_code,
                           sorlcur_term_code
           INTO l_programa,
                l_sp,
                l_fecha_inicio_sor,
                l_campus,
                l_nivel,
                l_periodo
           FROM sorlcur cur
           WHERE     1 = 1
           AND cur.sorlcur_pidm = p_pidm
           and cur.sorlcur_program = p_programa
           AND cur.sorlcur_seqno =
                                  (SELECT MAX (aa1.sorlcur_seqno)
                                   FROM sorlcur aa1
                                   WHERE     cur.sorlcur_pidm = aa1.sorlcur_pidm
                                   and cur.sorlcur_program = aa1.sorlcur_program 
                                   );

        EXCEPTION WHEN OTHERS THEN
              l_retorna:='No se puede obtener la fecha de inicio para esta matricula '||l_matricula||' '||sqlerrm;
        END;

        --dbms_output.put_line('Estar date '||l_fecha_inicio_sor||' matricula '||l_matricula);


        l_estatus:= p_estatus;

        IF l_estatus ='BI' then
            l_estatus:='BT';
        end if;


        IF l_estatus IN ('BI','BT','BD','CV') then

          --  dbms_output.put_line('entra 1 4409');

            begin

                SELECT count(*)
                into l_contar_horario
                FROM ssbsect ,
                     sfrstcr
                WHERE 1 = 1
                AND ssbsect_term_code = sfrstcr_term_code
                AND ssbsect_crn = sfrstcr_crn
                AND ssbsect_ptrm_start_date =l_fecha_inicio_sor
                AND sfrstcr_grde_code is  null
                AND substr(ssbsect_term_code,5,1) not in (8,9)
                AND sfrstcr_pidm = p_pidm;

            exception when others then
                null;
            end;

            --dbms_output.put_line('Horario '||l_contar_horario);

            if l_contar_horario > 0 then

                    FOR C IN (SELECT ssbsect_crn crn,
                                     ssbsect_term_code term_code,
                                     sfrstcr_ptrm_code ptrm,
                                     sfrstcr_pidm pidm
                              FROM ssbsect ,
                                   sfrstcr
                              WHERE 1 = 1
                              AND ssbsect_term_code = sfrstcr_term_code
                              AND ssbsect_crn = sfrstcr_crn
                              AND ssbsect_ptrm_start_date =l_fecha_inicio_sor
                              AND sfrstcr_grde_code is  null
                              AND substr(ssbsect_term_code,5,1) not in (8,9)
        --                      AND sfrstcr_rsts_code ='RE'
                              AND sfrstcr_pidm = p_pidm
                              )
                              LOOP




                               --  dbms_output.put_line('Entra a horario');

                                  BEGIN

                                    UPDATE SFRSTCR SET sfrstcr_rsts_code ='DD',
                                                       SFRSTCR_USER_ID = user,
                                                       SFRSTCR_DATA_ORIGIN ='Baja desde SSB',
                                                       SFRSTCR_USER = user,
                                                       SFRSTCR_ACTIVITY_DATE=sysdate
                                    WHERE 1 = 1
                                    AND sfrstcr_pidm = c.pidm
                                    AND sfrstcr_term_code =c.term_code
                                    AND sfrstcr_ptrm_code = c.ptrm
                                    AND sfrstcr_crn  =c.crn;

                                  EXCEPTION WHEN OTHERS THEN
                                      l_retorna:='No se pudo actualizar el registro sfctcr '||sqlerrm;
                                  END;


                                  IF l_retorna = 'EXITO' then

                                    FOR d IN (
                                              select *
                                              from sztprono
                                              where 1 = 1
                                              and SZTPRONO_PTRM_CODE = c.ptrm
                                              and SZTPRONO_TERM_CODE = c.term_code
                                              and sztprono_pidm = c.pidm
                                              and exists (select null
                                                            from szstume
                                                            where 1 = 1
                                                            and szstume_no_regla = sztprono_no_regla
                                                            and szstume_subj_code = sztprono_materia_legal
                                                            and szstume_pidm = sztprono_pidm
                                                            AND SZSTUME_STAT_IND = '1'
                                                            )
        --                                      AND sztprono_envio_horarios ='S'
                                              )loop

                                               --       dbms_output.put_line('Entra a prono ');

                                                      BEGIN

                                                        SELECT COUNT(*)
                                                        INTO l_materias_re
                                                        FROM szstume
                                                        WHERE 1 = 1
                                                        AND szstume_pidm = d.sztprono_pidm
                                                        AND szstume_no_regla = d.sztprono_no_regla
                                                        AND SZSTUME_SUBJ_CODE_COMP =d.sztprono_materia_legal
                                                        and SZSTUME_RSTS_CODE ='RE';


                                                      EXCEPTION WHEN OTHERS THEN
                                                            NULL;
                                                      END;

                                                      BEGIN

                                                        SELECT COUNT(*)
                                                        INTO l_materias_dd
                                                        FROM szstume
                                                        WHERE 1 = 1
                                                        AND szstume_pidm = d.sztprono_pidm
                                                        AND szstume_no_regla = d.sztprono_no_regla
                                                        AND SZSTUME_SUBJ_CODE_COMP =d.sztprono_materia_legal
                                                        and SZSTUME_RSTS_CODE ='DD';

                                                      EXCEPTION WHEN OTHERS THEN
                                                            NULL;
                                                      END;

--

                                                      if l_materias_re = 1 AND   l_materias_dd =0 then

                                                             for x in (select *
                                                                       from szstume
                                                                       where 1= 1
                                                                       and szstume_no_regla = d.sztprono_no_regla
                                                                       and szstume_subj_code_comp =d.sztprono_materia_legal
                                                                       and szstume_id = d.sztprono_id

                                                                       )
                                                                       loop

                                                                              --  dbms_output.put_line('Entra a szstume ');

                                                                              --  dbms_output.put_line('Estar date '||l_fecha_inicio_sor||' matricula '||l_matricula||' crn '||c.crn||' pperiodo '||c.ptrm||' term code '||c.term_code||' grupo '||x.szstume_term_nrc||' REGLA '||d.sztprono_no_regla);

                                                                                 --dbms_output.put_line('Entra a cursor x  ');

                                                                                BEGIN

                                                                                    SELECT MAX(NVL(szstume_seq_no,0))+1
                                                                                    INTO l_secuen_max
                                                                                    FROM szstume
                                                                                    WHERE 1 = 1
                                                                                    AND szstume_no_regla = d.sztprono_no_regla
                                                                                    and szstume_pidm = x.szstume_pidm
                                                                                    AND szstume_subj_code_comp  = d.sztprono_materia_legal
                                                                                    AND szstume_term_nrc =x.szstume_term_nrc ;

                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                    --l_retorna:='No se encontro secuencia maxima '||sqlerrm;
                                                                                    null;
                                                                                END;

                                                                                BEGIN

                                                                                   INSERT INTO szstume VALUES(x.szstume_term_nrc,
                                                                                                               x.szstume_pidm,
                                                                                                               x.szstume_id,
                                                                                                               SYSDATE,
                                                                                                               USER,
                                                                                                               0,
                                                                                                               'BAJAS SSB',
                                                                                                               X.SZSTUME_PWD,
                                                                                                               NULL,
                                                                                                               l_secuen_max,
                                                                                                               'DD',
                                                                                                               NULL,
                                                                                                               x.szstume_subj_code_comp,
                                                                                                               NULL,-- c.nivel,
                                                                                                               NULL,
                                                                                                               NULL,--  c.ptrm,
                                                                                                               NULL,
                                                                                                               null,
                                                                                                               NULL,
                                                                                                               NULL,
                                                                                                               x.szstume_subj_code_comp,
                                                                                                               d.sztprono_fecha_inicio,--  c.inicio_clases,
                                                                                                               d.sztprono_no_regla,
                                                                                                               NULL,
                                                                                                               1,
                                                                                                               0,
                                                                                                               null
                                                                                                               );
                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                   l_retorna:='No se pudo insertar en szstume '||sqlerrm;
                                                                                END;

                                                                              --  dbms_output.put_line('Inerto baja  ');

                                                                                if l_retorna ='EXITO' then

                                                                                    BEGIN

                                                                                        UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                                                            sztprono_envio_horarios ='N',
                                                                                                            sztprono_descripcion_error ='Baja desde SBB'
                                                                                        WHERE 1 = 1
                                                                                        AND sztprono_materia_legal = x.szstume_subj_code_comp
                                                                                        AND sztprono_pidm = x.szstume_pidm
                                                                                        AND sztprono_no_regla = d.sztprono_no_regla
                                                                                        AND sztprono_fecha_inicio =d.sztprono_fecha_inicio;

                                                                                    EXCEPTION WHEN OTHERS THEN
                                                                                        l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
                                                                                    END;

                                                                                end if;



                                                                       end loop;


                                                      end if;


                                              end loop;

                                  else

                                    rollback;

                                  end if;



                              END LOOP;

            else


                begin

                    select distinct sztprono_no_regla
                    into l_regla
                    from sztprono no1
                    where 1 = 1
                    and sztprono_pidm = p_pidm
                    and sztprono_no_regla = (select max(sztprono_no_regla)
                                             from sztprono no2
                                             where 1 = 1
                                             and no2.sztprono_pidm = no1.sztprono_pidm
                                             and exists (select null
                                                         from szstume
                                                         where 1 = 1
                                                         and szstume_pidm = no2.sztprono_pidm
                                                         and szstume_no_regla = no2.sztprono_no_regla)
                                             ) ;


                exception when others then
                    null;
                end;

             --   dbms_output.put_line(' regla '||l_regla);

                 for c in (
                            select distinct SZTPRONO_ID,
                                            sztprono_no_regla,
                                           sztprono_materia_legal,
                                           sztprono_fecha_inicio,
                                              get_crn_regla(ono.sztprono_pidm,
                                                               null,
                                                               ono.sztprono_materia_legal,
                                                               ono.sztprono_no_regla
                                                               )crn,
                                            sztprono_pidm pidm,
                                            sztprono_term_code term_code,
                                            sztprono_ptrm_code ptrm
                            from sztprono ono
                            where 1 = 1
                            and sztprono_no_regla = l_regla
                            and sztprono_pidm = p_pidm
                            and SZTPRONO_DESCRIPCION_ERROR is null
                            order by 2
                            )
                            loop

                                  begin

                                    select count(*)
                                    into l_acredita
                                    from SFRSTCR
                                    where 1 = 1
                                    and sfrstcr_pidm = c.pidm
                                    AND sfrstcr_term_code =c.term_code
                                    AND sfrstcr_ptrm_code = c.ptrm
                                    AND sfrstcr_grde_code is not null
                                    AND sfrstcr_crn  =    c.crn;

                                  exception when others then
                                    null;
                                  end;

                               --   dbms_output.put_line('Acredita '||l_acredita);

                                  if l_acredita=0 then

                                      BEGIN

                                        UPDATE SFRSTCR SET sfrstcr_rsts_code ='DD',
                                                           SFRSTCR_USER_ID = user,
                                                           SFRSTCR_DATA_ORIGIN ='Baja desde SSB',
                                                           SFRSTCR_USER = user,
                                                           SFRSTCR_ACTIVITY_DATE=sysdate
                                        WHERE 1 = 1
                                        AND sfrstcr_pidm = c.pidm
                                        AND sfrstcr_term_code =c.term_code
                                        AND sfrstcr_ptrm_code = c.ptrm
                                        AND sfrstcr_grde_code is  null
                                        AND sfrstcr_crn  =c.crn;

                                      EXCEPTION WHEN OTHERS THEN
                                          l_retorna:='No se pudo actualizar el registro sfctcr '||sqlerrm;
                                      END;

                                       -- dbms_output.put_line('Entra a szstume '||' regla '||l_regla);

                                    for x in (select *
                                              from szstume
                                              where 1= 1
                                              and szstume_no_regla = c.sztprono_no_regla
                                              and szstume_subj_code_comp =c.sztprono_materia_legal
                                              and szstume_id = c.sztprono_id
                                              )
                                              loop

                                                      -- dbms_output.put_line('Entra a szstume ');

                                                       BEGIN

                                                           SELECT MAX(NVL(szstume_seq_no,0))+1
                                                           INTO l_secuen_max
                                                           FROM szstume
                                                           WHERE 1 = 1
                                                           AND szstume_no_regla = c.sztprono_no_regla
                                                           and szstume_pidm = x.szstume_pidm
                                                           AND szstume_subj_code_comp  = c.sztprono_materia_legal
                                                           AND szstume_term_nrc =x.szstume_term_nrc ;

                                                       EXCEPTION WHEN OTHERS THEN
                                                           --l_retorna:='No se encontro secuencia maxima '||sqlerrm;
                                                           null;
                                                       END;

                                                       BEGIN

                                                          INSERT INTO szstume VALUES(x.szstume_term_nrc,
                                                                                      x.szstume_pidm,
                                                                                      x.szstume_id,
                                                                                      SYSDATE,
                                                                                      USER,
                                                                                      0,
                                                                                      'BAJAS SSB',
                                                                                      X.SZSTUME_PWD,
                                                                                      NULL,
                                                                                      l_secuen_max,
                                                                                      'DD',
                                                                                      NULL,
                                                                                      x.szstume_subj_code_comp,
                                                                                      NULL,-- c.nivel,
                                                                                      NULL,
                                                                                      NULL,--  c.ptrm,
                                                                                      NULL,
                                                                                      null,
                                                                                      NULL,
                                                                                      NULL,
                                                                                      x.szstume_subj_code_comp,
                                                                                      c.sztprono_fecha_inicio,--  c.inicio_clases,
                                                                                      c.sztprono_no_regla,
                                                                                      NULL,
                                                                                      1,
                                                                                      0,
                                                                                      null
                                                                                      );
                                                       EXCEPTION WHEN OTHERS THEN
                                                          l_retorna:='No se pudo insertar en szstume '||sqlerrm;
                                                       END;

                                                  --     dbms_output.put_line('Inerto baja  ');

                                                       if l_retorna ='EXITO' then

                                                           BEGIN

                                                               UPDATE sztprono SET sztprono_estatus_error ='S',
                                                                                   sztprono_envio_horarios ='N',
                                                                                   sztprono_descripcion_error ='Baja desde SSB'
                                                               WHERE 1 = 1
                                                               AND sztprono_materia_legal = x.szstume_subj_code_comp
                                                               AND sztprono_pidm = x.szstume_pidm
                                                               AND sztprono_no_regla = c.sztprono_no_regla
                                                               AND sztprono_fecha_inicio =c.sztprono_fecha_inicio;

                                                           EXCEPTION WHEN OTHERS THEN
                                                               l_retorna:='No se puede actualaizar en sztprono '||sqlerrm;
                                                           END;

                                                       end if;



                                              end loop;

                                  end if;

                            end loop;


            end if;



        end if;

        if l_retorna ='EXITO' then

               commit;

        else

            rollback;


        end if;



        RETURN(l_retorna);

    END f_baja_materias;

FUNCTION f_periodos_out (p_pidm in number, p_programa in varchar2) RETURN pkg_abcc.per_out
           AS
           
           l_tipo_ingreso varchar2(2);
           periodo_out pkg_abcc.per_out;
           l_nivel varchar2(2);
           l_pperiodos varchar2(500):= null;
           l_query varchar2(5000):= null;
           l_campus  varchar2(3):= null;
           p_periodo varchar2(6):=null;
           
           Begin 
              
                    Begin
                               select distinct TIPO_INGRESO, nivel, campus
                                   Into l_TIPO_INGRESO, l_nivel, l_campus
                                from tztprog a
                                where a.pidm = p_pidm
                                and a.programa = p_programa
                                And a.estatus not in ('CP')
                                And a.sp in  (select max (a1.sp)
                                                    from tztprog a1
                                                    Where a.pidm = a1.pidm
                                                     and a1.programa = p_programa
                                                    );        
                                                                                                            
                    Exception
                    when others then
                       l_TIPO_INGRESO:= null;
                       l_nivel := null;
                        l_campus := null;
                       
                    End;
                    

                    Begin 

                            Select distinct SGBSTDN_TERM_CODE_EFF
                                Into p_periodo
                            from sgbstdn a
                            where 1= 1
                            and a.SGBSTDN_PIDM = p_pidm
                            and a.SGBSTDN_PROGRAM_1 = p_programa
                            And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)   
                                                                                    from sgbstdn a1
                                                                                    where 1= 1
                                                                                    and a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                                    and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1);
                    Exception
                        When others then 
                            p_periodo:= null;
                    End;            
                    
        

                            dbms_output.put_line('entra 1');                   
                           
                           BEGIN
                                          open periodo_out
                                            FOR
                                                select distinct Periodo
                                                from  (
                                                            Select distinct Periodo , numero
                                                            from (   
                                                                 select ROW_NUMBER() OVER (ORDER BY SZTPTRM_TERM_CODE) AS numero,   SZTPTRM_TERM_CODE Periodo
                                                                from sztptrm, sobptrm
                                                                where sztptrm_term_code = sobptrm_term_code
                                                                and sztptrm_ptrm_code = sobptrm_ptrm_code
                                                               And SZTPTRM_VISIBLE = 1
                                                                And sztptrm_term_code > p_periodo
                                                                and SZTPTRM_CAMP_CODE = l_campus
                                                                and SZTPTRM_LEVL_CODE = l_nivel
                                                                AND SZTPTRM_PROGRAM = p_programa
                                                             )
                                                        )
                                                where 1= 1
                                                      and numero = 1
                                                order by 1 desc;

                                        RETURN (periodo_out);
                           End;
                           
   
                  

             
            END f_periodos_out;


  FUNCTION f_fecha_inicio_per_out (p_pidm in number, p_programa in varchar2, p_periodo in varchar2) RETURN pkg_abcc.fper_out
           AS
           
          
                per_fecha_out pkg_abcc.fper_out;
                l_nivel varchar2(2);
                l_pperiodos varchar2(500):= null;
                l_query varchar2(5000):= null;
                l_tipo_ingreso varchar2(2);
                f_fecha_inicio_old date;
           
           Begin 
              
           
                    Begin
                                                
                                select distinct SORLCUR_ADMT_CODE, SORLCUR_levl_code, trunc (SORLCUR_START_DATE)
                                 Into l_TIPO_INGRESO, l_nivel, f_fecha_inicio_old
                                FROM SORLCUR A
                                WHERE 1 = 1
                                and A.SORLCUR_PIDM = p_pidm
                                AND A.SORLCUR_PROGRAM =P_PROGRAMA
                                AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                                AND A.SORLCUR_ROLL_IND  = 'Y'
                                AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                                AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                                           FROM SORLCUR A1
                                                                           WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                          -- AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                                                           )  ;                                      
                    Exception
                        When others then 
                            f_fecha_inicio_old := null;
                            l_TIPO_INGRESO:= null; 
                            l_nivel:= null;
                    End;
           
           
           
                     If l_nivel ='LI' and l_TIPO_INGRESO ='EQ' then 
                            
                                dbms_output.put_line('entra 1');                   
                               
                               BEGIN
                                              open per_fecha_out
                                                FOR
                                                    select Fecha_Inicio
                                                    from  (
                                                                Select Fecha_Inicio , numero
                                                                from (                                           
                                                                            select ROW_NUMBER() OVER (ORDER BY sobptrm_start_date) AS numero,   to_char (sobptrm_start_date,'dd/mm/rrrr') Fecha_Inicio
                                                                                                                from sztptrm, sobptrm
                                                                                                                where sztptrm_term_code = sobptrm_term_code
                                                                                                                and sztptrm_ptrm_code = sobptrm_ptrm_code
                                                                                                                AND SZTPTRM_PROGRAM = p_programa
                                                                                                                and sztptrm_term_code = p_periodo
                                                                                                                and SZTPTRM_PTRM_CODE in ('L0A','L1A')
                                                                                                                and trunc (sobptrm_start_date) > trunc (f_fecha_inicio_old)
                                                                       )
                                                                    where 1= 1
                                                                          and numero <= 2
                                                    ) 
                                                     order by 1 desc;                                                    

                                            RETURN (per_fecha_out);
                               End;
                               
                   Elsif   l_nivel ='MA' and l_TIPO_INGRESO ='EQ' then  

                            dbms_output.put_line('entra 2');                   
                               
                               BEGIN
                                              open per_fecha_out
                                                FOR
                                                    select Fecha_Inicio
                                                    from  (
                                                                Select Fecha_Inicio , numero
                                                                from (                                           
                                                                            select ROW_NUMBER() OVER (ORDER BY sobptrm_start_date) AS numero,   to_char (sobptrm_start_date,'dd/mm/rrrr') Fecha_Inicio
                                                                                                                from sztptrm, sobptrm
                                                                                                                where sztptrm_term_code = sobptrm_term_code
                                                                                                                and sztptrm_ptrm_code = sobptrm_ptrm_code
                                                                                                                AND SZTPTRM_PROGRAM = p_programa
                                                                                                                and sztptrm_term_code = p_periodo
                                                                                                                and SZTPTRM_PTRM_CODE in ('M0B','M1A')
                                                                                                                and trunc (sobptrm_start_date) > trunc (f_fecha_inicio_old)
                                                                       )
                                                                    where 1= 1
                                                                          and numero <= 2
                                                    ) 
                                                     order by 1 desc;                                                    

                                            RETURN (per_fecha_out);
                               End;
      
                     Elsif   l_nivel ='MS' and l_TIPO_INGRESO ='EQ' then  

                            dbms_output.put_line('entra 3');                   
                               
                               BEGIN
                                              open per_fecha_out
                                                FOR
                                                    select Fecha_Inicio
                                                    from  (
                                                                Select Fecha_Inicio , numero
                                                                from (                                           
                                                                            select ROW_NUMBER() OVER (ORDER BY sobptrm_start_date) AS numero,   to_char (sobptrm_start_date,'dd/mm/rrrr') Fecha_Inicio
                                                                                                                from sztptrm, sobptrm
                                                                                                                where sztptrm_term_code = sobptrm_term_code
                                                                                                                and sztptrm_ptrm_code = sobptrm_ptrm_code
                                                                                                                AND SZTPTRM_PROGRAM = p_programa
                                                                                                                and sztptrm_term_code = p_periodo
                                                                                                                and SZTPTRM_PTRM_CODE in  ('A0B','A1A')
                                                                                                                and trunc (sobptrm_start_date) > trunc (f_fecha_inicio_old)
                                                                       )
                                                                    where 1= 1
                                                                          and numero <= 2
                                                    ) 
                                                     order by 1 desc;                                                    

                                            RETURN (per_fecha_out);
                               End;
        
                    Else
                            dbms_output.put_line('entra 4');                   
                               
                               BEGIN
                                              open per_fecha_out
                                                FOR
                                                    select Fecha_Inicio
                                                    from  (
                                                                Select Fecha_Inicio , numero
                                                                from (                                           
                                                                            select ROW_NUMBER() OVER (ORDER BY sobptrm_start_date) AS numero,   to_char (sobptrm_start_date,'dd/mm/rrrr') Fecha_Inicio
                                                                                                                from sztptrm, sobptrm
                                                                                                                where sztptrm_term_code = sobptrm_term_code
                                                                                                                and sztptrm_ptrm_code = sobptrm_ptrm_code
                                                                                                                AND SZTPTRM_PROGRAM = p_programa
                                                                                                                and sztptrm_term_code = p_periodo
                                                                                                             --   and SZTPTRM_PTRM_CODE in  ('A0B','A1A')
                                                                                                                and trunc (sobptrm_start_date) > trunc (f_fecha_inicio_old)
                                                                       )
                                                                    where 1= 1
                                                                          and numero <= 2
                                                    ) 
                                                     order by 1 desc;                                                    

                                            RETURN (per_fecha_out);
                               End;                    
                    
                    End if;
           
            
            END f_fecha_inicio_per_out;





PROCEDURE P_CAMBIO_CICLO  (P_PIDM VARCHAR2,
                                             P_ESTS_CODE_NEW VARCHAR2,
                                             P_RAZON VARCHAR2,
                                             P_periodo varchar2,
                                             f_fecha_inicio_nw date,
                                             P_PROGRAMA VARCHAR2
                         )IS
                         
  lv_existe NUMBER;   
  vl_exito varchar2(500):= 'EXITO';      
  VL_TZTPUNI   NUMBER;  
  ------------
  P_PERIODO_Ant varchar2(6):= null;
  P_PPERIODO varchar2(6):= null;
  P_SP number;
  f_fecha_inicio_old varchar2(12):=null;
  p_comentario varchar2(500):= null;
  lv_secuencia number:=0;
  vn_existe_sgrchrt number:=0;
  vtzdocta number:=0;
             
                         
BEGIN

            
            Begin
                    SELECT NVL (MAX (sorlcur_seqno), 0) + 1
                            INTO lv_secuencia
                    FROM sorlcur
                    WHERE sorlcur_pidm = P_PIDM;
            Exception
                When Others then 
                  lv_secuencia:=1;
            End;

            dbms_output.put_line('Se obtiene secuencia sorlcur '||lv_secuencia);         

            Begin 

                    Select distinct SGBSTDN_TERM_CODE_EFF
                        Into P_PERIODO_Ant
                    from sgbstdn a
                    where 1= 1
                    and a.SGBSTDN_PIDM = p_pidm
                    and a.SGBSTDN_PROGRAM_1 = p_programa
                    And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)   
                                                                            from sgbstdn a1
                                                                            where 1= 1
                                                                            and a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                            and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1);
            Exception
                When others then 
                    P_PERIODO_Ant:= null;
            End;
            
            
             dbms_output.put_line('Se obtiene secuencia sgbstdn '||P_PERIODO_Ant);    

            Begin            
                    select distinct SZTPTRM_PTRM_CODE
                        Into P_PPERIODO
                    from sztptrm, sobptrm
                    where sztptrm_term_code = sobptrm_term_code
                    and sztptrm_ptrm_code = sobptrm_ptrm_code
                    AND SZTPTRM_PROGRAM = p_programa
                    and sztptrm_term_code = p_periodo
                    And trunc (sobptrm_start_date)   = trunc (f_fecha_inicio_nw);
            Exception
                When Others then
                   P_PPERIODO:= null;         
            End;
            
 dbms_output.put_line('Se obtiene secuencia P_PPERIODO '||P_PPERIODO);                
            

        If P_PERIODO_Ant = P_PERIODO and  P_PERIODO is not null then 
               vl_exito :='Para aplicar el cambio de ciclo, debera de selecccionar un nuevo Ciclo';
               dbms_output.put_line('Salida uno  '||vl_exito);    
                  
        Elsif  P_PERIODO_Ant != P_PERIODO and  P_PERIODO is not null then  
                
                    Begin 
                            select distinct sp
                              Into  P_SP
                            from tztprog a 
                            where a.pidm = p_pidm
                            and a.programa = P_PROGRAMA
                            and a.sp = (Select max (a1.sp)
                                                from tztprog a1
                                                where a.pidm = a1.pidm
                                                and a.programa = a1.programa);         
                    Exception
                        When others then 
                         P_SP:=1;   
                    End;


                    Begin
                      
                       select distinct to_char (SORLCUR_START_DATE,'dd/mm/rrrr')
                         Into f_fecha_inicio_old
                        FROM SORLCUR A
                        WHERE 1 = 1
                        and A.SORLCUR_PIDM = p_pidm
                        AND A.SORLCUR_PROGRAM =P_PROGRAMA
                        AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                        AND A.SORLCUR_ROLL_IND  = 'Y'
                        AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                        AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                                   FROM SORLCUR A1
                                                                   WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                  -- AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                                                   )  ;                                                        
                                                  
                    Exception
                        When others then 
                            f_fecha_inicio_old := null;
                    End;

                     dbms_output.put_line('tztprog SP  '||P_SP||' '||f_fecha_inicio_old);  
                     vl_exito:= 'EXITO';

                  IF (sb_enrollment.f_exists( P_PIDM  , P_PERIODO )<>'Y')  THEN
                  
                            dbms_output.put_line('sb_enrollment '||P_PIDM||' '||P_PERIODO);  
                  
                                        Begin 
                  
                                        dbms_output.put_line('Entra1 ' ||vl_exito);                                        
                                                        INSERT INTO SFBETRM (
                                                                     SFBETRM_TERM_CODE, SFBETRM_PIDM, SFBETRM_ESTS_CODE, SFBETRM_ESTS_DATE, SFBETRM_MHRS_OVER,
                                                                     SFBETRM_AR_IND, SFBETRM_ASSESSMENT_DATE, SFBETRM_ADD_DATE, SFBETRM_ACTIVITY_DATE, SFBETRM_RGRE_CODE, 
                                                                     SFBETRM_TMST_CODE, SFBETRM_TMST_DATE, SFBETRM_TMST_MAINT_IND, SFBETRM_USER, SFBETRM_REFUND_DATE, 
                                                                     SFBETRM_DATA_ORIGIN, SFBETRM_INITIAL_REG_DATE, SFBETRM_MIN_HRS, SFBETRM_MINH_SRCE_CDE, SFBETRM_MAXH_SRCE_CDE,
                                                                     SFBETRM_SURROGATE_ID, SFBETRM_VERSION, SFBETRM_USER_ID, SFBETRM_VPDI_CODE)
                                                        VALUES ( P_PERIODO, P_PIDM ,  'EL'/*'EL'*/, SYSDATE, 999999.999, 
                                                                 'N',  NULL,   SYSDATE,   SYSDATE, P_RAZON, 
                                                                 '',   NULL,   '',  USER, NULL,
                                                                 'SSB',   SYSDATE  , 0.000,  'M','M',
                                                                   null, null, null, null);
                                                         Commit;
                                        Exception
                                            When others then
                                                vl_exito:= 'Error al insertar en  SFBETRM ' || sqlerrm;       
                                                dbms_output.put_line('error1 ' ||vl_exito);                   
                                        End;
                                        
                                        If vl_exito ='EXITO' then
                                               dbms_output.put_line('Entra2 ' ||vl_exito);
                                        
                                                Begin 
                                                         INSERT INTO SFRENSP (SFRENSP_TERM_CODE, SFRENSP_PIDM,
                                                                     SFRENSP_KEY_SEQNO, SFRENSP_ESTS_CODE, SFRENSP_ESTS_DATE,
                                                                     SFRENSP_ADD_DATE, SFRENSP_ACTIVITY_DATE,
                                                                     SFRENSP_USER, SFRENSP_DATA_ORIGIN, 
                                                                     SFRENSP_SURROGATE_ID, SFRENSP_VERSION, SFRENSP_USER_ID, SFRENSP_VPDI_CODE)
                                                        VALUES (P_PERIODO, P_PIDM , 
                                                                    P_SP,  'EL'/* 'EL'*/,  SYSDATE,   
                                                                    SYSDATE,  SYSDATE,     
                                                                    USER , 'SSB',
                                                                     null, null, null, null );
                                                        Commit;
                                                Exception
                                                    When Others then 
                                                      vl_exito:= 'Error al insertar en  SFRENSP ' || sqlerrm;            
                                                      dbms_output.put_line('error2 ' ||vl_exito);                     
                                                End;
                                                         
                                        End if;
                                    
                  ELSE

                            dbms_output.put_line('Entra 3 ');                 
                                        FOR TRM IN (
                                                                SELECT C.SFBETRM_ESTS_DATE, C.SFBETRM_ADD_DATE, C.SFBETRM_ESTS_CODE, C.SFBETRM_TERM_CODE
                                                              FROM   SFBETRM C
                                                              WHERE  C.sfbetrm_pidm = P_PIDM
                                                              and c.SFBETRM_TERM_CODE = P_PERIODO

                                       ) LOOP                              
                                                    Begin 
                                                            Update SFBETRM
                                                            set SFBETRM_ESTS_CODE = 'EL'/*'EL'*/,
                                                                SFBETRM_RGRE_CODE = P_RAZON,
                                                                SFBETRM_ACTIVITY_DATE = SYSDATE,
                                                                SFBETRM_DATA_ORIGIN = 'SSB',
                                                                SFBETRM_USER_ID = USER
                                                            where SFBETRM_PIDM = P_PIDM
                                                            And SFBETRM_TERM_CODE = TRM.SFBETRM_TERM_CODE
                                                            And SFBETRM_ESTS_CODE = TRM.SFBETRM_ESTS_CODE;
                                                            Commit;
                                                    Exception
                                                        When  Others then 
                                                       vl_exito:= 'Error al Update en  SFBETRM ' || sqlerrm;            
                                                      dbms_output.put_line('error2X ' ||vl_exito);      
                                                    End;
                                                
                                                    Begin 
                                                            select count (*)
                                                                Into lv_existe
                                                            from SFRENSP
                                                            where SFRENSP_PIDM = P_PIDM
                                                            and SFRENSP_TERM_CODE = TRM.SFBETRM_TERM_CODE
                                                            And SFRENSP_KEY_SEQNO = P_SP;
                                                            
                                                    Exception
                                                        When Others then 
                                                          lv_existe:=0;  
                                                    End;
                                               
                                                    If lv_existe >= 1 then 
                                                          Begin
                                                                  Update SFRENSP
                                                                  set SFRENSP_ESTS_CODE = 'EL',/*'EL'*/
                                                                      SFRENSP_ACTIVITY_DATE = SYSDATE,
                                                                      SFRENSP_DATA_ORIGIN = 'SSB',
                                                                      SFRENSP_USER_ID = USER
                                                                  where SFRENSP_PIDM = P_PIDM
                                                                  and SFRENSP_TERM_CODE = TRM.SFBETRM_TERM_CODE--CASE VN_INSERTA WHEN 1 THEN vc_periodo_horarios ELSE :MINI_PERFIL.PERIODO END
                                                                  And SFRENSP_KEY_SEQNO = P_SP;
                                                                  Commit;
                                                          Exception 
                                                          When Others then 
                                                               vl_exito:= 'Error al Update en  SFRENSP ' || sqlerrm;            
                                                                     dbms_output.put_line('error3X ' ||vl_exito);    
                                                          End;
                                                    Elsif lv_existe = 0 then 
                                                           Begin 
                                                                  Insert into SFRENSP values (  TRM.SFBETRM_TERM_CODE,--CASE VN_INSERTA WHEN 1 THEN vc_periodo_horarios ELSE :MINI_PERFIL.PERIODO END,
                                                                                                P_PIDM, 
                                                                                                P_SP,
                                                                                              'EL',
                                                                                                TRM.SFBETRM_ESTS_DATE,--vd_ESTS_DATE,
                                                                                                TRM.SFBETRM_ADD_DATE,--vd_ADD_DATE,
                                                                                                sysdate,
                                                                                                user,--'MIGRA',
                                                                                                'SSB',--'UTEL',
                                                                                                null,
                                                                                                null,
                                                                                                user,--'MIGRA',
                                                                                                NULL);
                                                                    Commit;
                                                           Exception
                                                            When Others then
                                                                   vl_exito:= 'Error al Insertar en  SFRENSP ' || sqlerrm;            
                                                                dbms_output.put_line('error4X ' ||vl_exito);                                        
                                                           End;
                                                           
                                                    End if;
                                       END LOOP;
                                       
                  END IF;
                  
                  
                  ----------- Cambio el estatus en SORLCUR -------------------------
                  
                  Begin 
     
                  
                        For cx in (     
                   
                                        Select *
                                        from sorlcur a
                                        WHERE a.sorlcur_pidm = P_PIDM
                                        AND a.sorlcur_program =P_PROGRAMA
                                        AND a.sorlcur_lmod_code = 'LEARNER'
                                        And a.SORLCUR_CACT_CODE = 'ACTIVE'
                                        and a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
                                                                                from SORLCUR a1
                                                                                Where a.sorlcur_pidm = a1.sorlcur_pidm
                                                                                And a.sorlcur_program = a1.sorlcur_program
                                                                                And a.sorlcur_lmod_code = a1.sorlcur_lmod_code
                                                                                And a.SORLCUR_CACT_CODE = a1.SORLCUR_CACT_CODE
                                                                                )
                            
                         ) loop
                         
                         
                                    ---- Desactiva el registro actual --------
                                    
                                    dbms_output.put_line('salida loop  ' ||cx.SORLCUR_PIDM ||','||cx.sorlcur_program||','|| cx.sorlcur_program||','||cx.sorlcur_lmod_code||','||cx.SORLCUR_CACT_CODE);        
                                    
                                   Begin 
                                            Update sorlcur 
                                            set SORLCUR_ROLL_IND = 'N',
                                                  SORLCUR_CACT_CODE = 'INACTIVE',
                                                  SORLCUR_CURRENT_CDE ='N',
                                                  SORLCUR_PRIORITY_NO = 99,
                                                  SORLCUR_USER_ID = user,
                                                  SORLCUR_DATA_ORIGIN ='SSB',
                                                  SORLCUR_USER_ID_UPDATE = user,
                                                  SORLCUR_ACTIVITY_DATE_UPDATE = sysdate
                                            Where 1 =1
                                         And SORLCUR_PIDM = cx.SORLCUR_PIDM
                                         AND sorlcur_program = cx.sorlcur_program
                                        AND sorlcur_lmod_code = cx.sorlcur_lmod_code
                                        And SORLCUR_CACT_CODE = cx.SORLCUR_CACT_CODE;
                                        Commit;
                                        dbms_output.put_line('Exito xx1 ' );     
                                   Exception
                                    When others then 
                                      vl_exito:= 'Error xx1 al Update sorlcur '||sqlerrm;
                                        dbms_output.put_line('Error xx1 ' ||vl_exito);        
                                   End;
                                   
                                   
                                   Begin
                                   
                                             update  sorlfos
                                             set SORLFOS_CACT_CODE = 'INACTIVE',
                                             SORLFOS_CURRENT_CDE = 'N',
                                             SORLFOS_PRIORITY_NO = 99,
                                             SORLFOS_USER_ID_UPDATE = user,
                                             SORLFOS_USER_ID = user,
                                             SORLFOS_ACTIVITY_DATE = sysdate,
                                             SORLFOS_ACTIVITY_DATE_UPDATE = sysdate
                                              where 1 = 1
                                              and sorlfos_pidm =  cx.SORLCUR_PIDM
                                              And  SORLFOS_LCUR_SEQNO = cx.SORLCUR_SEQNO;
                                              Commit;
                                               dbms_output.put_line('Exito xx2 ' );     
                                   Exception
                                    When Others then 
                                         vl_exito:= 'Error xx2 al Update sorlfos '||sqlerrm;
                                        dbms_output.put_line('Error xx2 ' ||vl_exito);    
                                   End;
                         
                         
                                Begin
                                
                                    Insert into sorlcur values (
                                                                            cx.SORLCUR_PIDM
                                                                            ,lv_secuencia
                                                                            ,cx.SORLCUR_LMOD_CODE
                                                                            ,P_periodo
                                                                            ,cx.SORLCUR_KEY_SEQNO
                                                                            ,1
                                                                            ,'Y'
                                                                            ,'ACTIVE'
                                                                            ,USER
                                                                            ,'SSB'
                                                                            ,SYSDATE
                                                                            ,cx.SORLCUR_LEVL_CODE
                                                                            ,cx.SORLCUR_COLL_CODE
                                                                            ,cx.SORLCUR_DEGC_CODE
                                                                            ,cx.SORLCUR_TERM_CODE_CTLG
                                                                            ,cx.SORLCUR_TERM_CODE_END
                                                                            ,cx.SORLCUR_TERM_CODE_MATRIC
                                                                            ,P_periodo
                                                                            ,cx.SORLCUR_ADMT_CODE
                                                                            ,cx.SORLCUR_CAMP_CODE
                                                                            ,cx.SORLCUR_PROGRAM
                                                                            ,trunc (f_fecha_inicio_nw)
                                                                            ,null
                                                                            ,cx.SORLCUR_CURR_RULE
                                                                            ,cx.SORLCUR_ROLLED_SEQNO
                                                                            ,cx.SORLCUR_STYP_CODE
                                                                            ,cx.SORLCUR_RATE_CODE
                                                                            ,cx.SORLCUR_LEAV_CODE
                                                                            ,cx.SORLCUR_LEAV_FROM_DATE
                                                                            ,cx.SORLCUR_LEAV_TO_DATE
                                                                            ,cx.SORLCUR_EXP_GRAD_DATE
                                                                            ,cx.SORLCUR_TERM_CODE_GRAD
                                                                            ,cx.SORLCUR_ACYR_CODE
                                                                            ,cx.SORLCUR_SITE_CODE
                                                                            ,cx.SORLCUR_APPL_SEQNO
                                                                            ,cx.SORLCUR_APPL_KEY_SEQNO
                                                                            ,USER
                                                                            ,SYSDATE
                                                                            ,cx.SORLCUR_GAPP_SEQNO
                                                                            ,'Y'
                                                                            ,null
                                                                            ,null
                                                                            ,P_PPERIODO);
                                            Commit;
                                    dbms_output.put_line('Exito xx3 ' );
                                
                                Exception
                                    When Others then 
                                         vl_exito:= 'Error xx3 al Insert sorcur '||sqlerrm;
                                        dbms_output.put_line('Error xx3 ' ||vl_exito);   
                                End;
                         
                                lv_existe:=0;
                                For cx1 in (
                                
                                                Select *
                                                from sorlfos 
                                                Where SORLFOS_PIDM =  cx.SORLCUR_PIDM
                                                And SORLFOS_LCUR_SEQNO = cx.SORLCUR_SEQNO
                                                
                                 ) loop
                                            
                                            lv_existe := lv_existe +1;    
                                             dbms_output.put_line('Secuencia sorlfos ' ||lv_existe);   
                                            Begin 
                                                    Insert into sorlfos values (
                                                                                        cx1.SORLFOS_PIDM
                                                                                        ,lv_secuencia
                                                                                        ,cx1.SORLFOS_SEQNO
                                                                                        ,cx1.SORLFOS_LFST_CODE
                                                                                        ,P_periodo
                                                                                        ,lv_existe
                                                                                        ,cx1.SORLFOS_CSTS_CODE
                                                                                        ,'ACTIVE'
                                                                                        ,'SSB'
                                                                                        ,user
                                                                                        ,sysdate
                                                                                        ,cx1.SORLFOS_MAJR_CODE
                                                                                        ,cx1.SORLFOS_TERM_CODE_CTLG
                                                                                        ,cx1.SORLFOS_TERM_CODE_END
                                                                                        ,cx1.SORLFOS_DEPT_CODE
                                                                                        ,cx1.SORLFOS_MAJR_CODE_ATTACH
                                                                                        ,cx1.SORLFOS_LFOS_RULE
                                                                                        ,cx1.SORLFOS_CONC_ATTACH_RULE
                                                                                        ,cx1.SORLFOS_START_DATE
                                                                                        ,cx1.SORLFOS_END_DATE
                                                                                        ,cx1.SORLFOS_TMST_CODE
                                                                                        ,cx1.SORLFOS_ROLLED_SEQNO
                                                                                        ,user
                                                                                        ,sysdate
                                                                                        ,cx1.SORLFOS_CURRENT_CDE
                                                                                        ,null
                                                                                        ,null
                                                                                        ,null
                                                                                        );    
                                                    Commit;
                                                   dbms_output.put_line('Exito xx4 ' );                                        
                                            Exception
                                                When Others then 
                                                                      vl_exito:= 'Error xx4 al Insert sorlfos '||sqlerrm;
                                        dbms_output.put_line('Error xx4 ' ||vl_exito);   
                                            End;


                                End loop;
                         
                         End loop;
                            
                            
                  Exception
                    When Others then 
                        null;       
                        dbms_output.put_line('Error 4 loop '||sqlerrm);              
                  End;

                                   
                 BEGIN
                           INSERT INTO sgrsatt (sgrsatt_pidm,
                                                sgrsatt_term_code_eff,
                                                sgrsatt_atts_code,
                                                sgrsatt_activity_date,
                                                sgrsatt_stsp_key_sequence)
                              SELECT sgrsatt_pidm,
                                     P_periodo,
                                     sgrsatt_atts_code,
                                     SYSDATE,
                                     sgrsatt_stsp_key_sequence
                                FROM sgrsatt
                               WHERE     sgrsatt_pidm = p_pidm
                                     AND sgrsatt_term_code_eff =P_PERIODO_Ant
                                     AND sgrsatt_stsp_key_sequence =  P_SP;
                             Commit;
                                       dbms_output.put_line('Exito xx5 ' );     
                 EXCEPTION
                   WHEN OTHERS THEN
                        null;
                      dbms_output.put_line ('Error al insertar  SGRSATT ' || SQLERRM);
                 END;                  
                 
                 
                 ------- Cambia de estatus al cambio de ciclo
                Begin
                 
                          update  sgbstdn a
                            Set SGBSTDN_STST_CODE = 'CC',
                                 SGBSTDN_ACTIVITY_DATE = sysdate,
                                 SGBSTDN_DATA_ORIGIN ='SSB',
                                 SGBSTDN_USER_ID = user,
                                 SGBSTDN_PRIM_ROLL_IND = 'N'
                            where 1= 1
                            and a.SGBSTDN_PIDM = p_pidm
                            and a.SGBSTDN_PROGRAM_1 = p_programa
                            And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)   
                                                                                    from sgbstdn a1
                                                                                    where 1= 1
                                                                                    and a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                                    and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1);   
                            Commit;
                           dbms_output.put_line('Exito xx5 ' );     
                Exception
                    When Others then 
                        dbms_output.put_line ('Error5xx al Update  sgbstdn ' || SQLERRM);
                End;
                 
                  

                Begin 

                        Insert into sgbstdn 
                        Select a.SGBSTDN_PIDM
                                ,P_periodo
                                ,'MA'
                                ,a.SGBSTDN_LEVL_CODE
                                ,a.SGBSTDN_STYP_CODE
                                ,a.SGBSTDN_TERM_CODE_MATRIC
                                ,a.SGBSTDN_TERM_CODE_ADMIT
                                ,a.SGBSTDN_EXP_GRAD_DATE
                                ,a.SGBSTDN_CAMP_CODE
                                ,a.SGBSTDN_FULL_PART_IND
                                ,a.SGBSTDN_SESS_CODE
                                ,a.SGBSTDN_RESD_CODE
                                ,a.SGBSTDN_COLL_CODE_1
                                ,a.SGBSTDN_DEGC_CODE_1
                                ,a.SGBSTDN_MAJR_CODE_1
                                ,a.SGBSTDN_MAJR_CODE_MINR_1
                                ,a.SGBSTDN_MAJR_CODE_MINR_1_2
                                ,a.SGBSTDN_MAJR_CODE_CONC_1
                                ,a.SGBSTDN_MAJR_CODE_CONC_1_2
                                ,a.SGBSTDN_MAJR_CODE_CONC_1_3
                                ,a.SGBSTDN_COLL_CODE_2
                                ,a.SGBSTDN_DEGC_CODE_2
                                ,a.SGBSTDN_MAJR_CODE_2
                                ,a.SGBSTDN_MAJR_CODE_MINR_2
                                ,a.SGBSTDN_MAJR_CODE_MINR_2_2
                                ,a.SGBSTDN_MAJR_CODE_CONC_2
                                ,a.SGBSTDN_MAJR_CODE_CONC_2_2
                                ,a.SGBSTDN_MAJR_CODE_CONC_2_3
                                ,a.SGBSTDN_ORSN_CODE
                                ,a.SGBSTDN_PRAC_CODE
                                ,a.SGBSTDN_ADVR_PIDM
                                ,a.SGBSTDN_GRAD_CREDIT_APPR_IND
                                ,a.SGBSTDN_CAPL_CODE
                                ,a.SGBSTDN_LEAV_CODE
                                ,a.SGBSTDN_LEAV_FROM_DATE
                                ,a.SGBSTDN_LEAV_TO_DATE
                                ,a.SGBSTDN_ASTD_CODE
                                ,a.SGBSTDN_TERM_CODE_ASTD
                                ,a.SGBSTDN_RATE_CODE
                                ,sysdate
                                ,a.SGBSTDN_MAJR_CODE_1_2
                                ,a.SGBSTDN_MAJR_CODE_2_2
                                ,a.SGBSTDN_EDLV_CODE
                                ,a.SGBSTDN_INCM_CODE
                                ,a.SGBSTDN_ADMT_CODE
                                ,a.SGBSTDN_EMEX_CODE
                                ,a.SGBSTDN_APRN_CODE
                                ,a.SGBSTDN_TRCN_CODE
                                ,a.SGBSTDN_GAIN_CODE
                                ,a.SGBSTDN_VOED_CODE
                                ,a.SGBSTDN_BLCK_CODE
                                ,a.SGBSTDN_TERM_CODE_GRAD
                                ,a.SGBSTDN_ACYR_CODE
                                ,a.SGBSTDN_DEPT_CODE
                                ,a.SGBSTDN_SITE_CODE
                                ,a.SGBSTDN_DEPT_CODE_2
                                ,a.SGBSTDN_EGOL_CODE
                                ,a.SGBSTDN_DEGC_CODE_DUAL
                                ,a.SGBSTDN_LEVL_CODE_DUAL
                                ,a.SGBSTDN_DEPT_CODE_DUAL
                                ,a.SGBSTDN_COLL_CODE_DUAL
                                ,a.SGBSTDN_MAJR_CODE_DUAL
                                ,a.SGBSTDN_BSKL_CODE
                                ,a.SGBSTDN_PRIM_ROLL_IND
                                ,a.SGBSTDN_PROGRAM_1
                                ,a.SGBSTDN_TERM_CODE_CTLG_1
                                ,a.SGBSTDN_DEPT_CODE_1_2
                                ,a.SGBSTDN_MAJR_CODE_CONC_121
                                ,a.SGBSTDN_MAJR_CODE_CONC_122
                                ,a.SGBSTDN_MAJR_CODE_CONC_123
                                ,a.SGBSTDN_SECD_ROLL_IND
                                ,a.SGBSTDN_TERM_CODE_ADMIT_2
                                ,a.SGBSTDN_ADMT_CODE_2
                                ,a.SGBSTDN_PROGRAM_2
                                ,a.SGBSTDN_TERM_CODE_CTLG_2
                                ,a.SGBSTDN_LEVL_CODE_2
                                ,a.SGBSTDN_CAMP_CODE_2
                                ,a.SGBSTDN_DEPT_CODE_2_2
                                ,a.SGBSTDN_MAJR_CODE_CONC_221
                                ,a.SGBSTDN_MAJR_CODE_CONC_222
                                ,a.SGBSTDN_MAJR_CODE_CONC_223
                                ,a.SGBSTDN_CURR_RULE_1
                                ,a.SGBSTDN_CMJR_RULE_1_1
                                ,a.SGBSTDN_CCON_RULE_11_1
                                ,a.SGBSTDN_CCON_RULE_11_2
                                ,a.SGBSTDN_CCON_RULE_11_3
                                ,a.SGBSTDN_CMJR_RULE_1_2
                                ,a.SGBSTDN_CCON_RULE_12_1
                                ,a.SGBSTDN_CCON_RULE_12_2
                                ,a.SGBSTDN_CCON_RULE_12_3
                                ,a.SGBSTDN_CMNR_RULE_1_1
                                ,a.SGBSTDN_CMNR_RULE_1_2
                                ,a.SGBSTDN_CURR_RULE_2
                                ,a.SGBSTDN_CMJR_RULE_2_1
                                ,a.SGBSTDN_CCON_RULE_21_1
                                ,a.SGBSTDN_CCON_RULE_21_2
                                ,a.SGBSTDN_CCON_RULE_21_3
                                ,a.SGBSTDN_CMJR_RULE_2_2
                                ,a.SGBSTDN_CCON_RULE_22_1
                                ,a.SGBSTDN_CCON_RULE_22_2
                                ,a.SGBSTDN_CCON_RULE_22_3
                                ,a.SGBSTDN_CMNR_RULE_2_1
                                ,a.SGBSTDN_CMNR_RULE_2_2
                                ,a.SGBSTDN_PREV_CODE
                                ,a.SGBSTDN_TERM_CODE_PREV
                                ,a.SGBSTDN_CAST_CODE
                                ,a.SGBSTDN_TERM_CODE_CAST
                                ,'SSB'
                                ,user
                                ,a.SGBSTDN_SCPC_CODE
                                ,null
                                ,null
                                ,null
                        from sgbstdn a
                        where 1= 1
                        and a.SGBSTDN_PIDM = p_pidm
                        and a.SGBSTDN_PROGRAM_1 = p_programa
                        And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)   
                                                                                from sgbstdn a1
                                                                                where 1= 1
                                                                                and a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                                and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1);
                         Commit;                                                       
                       dbms_output.put_line('Exito xx6 ' );                                                           
                                                                                
                Exception
                    When others then 
                       dbms_output.put_line ('Error6xx al Insert  sgbstdn ' || SQLERRM);
                End;
 
                vn_existe_sgrchrt:=0;
                Begin
                        SELECT COUNT (*)
                              INTO vn_existe_sgrchrt
                          FROM sgrchrt
                         WHERE  sgrchrt_pidm = p_pidm
                         AND sgrchrt_term_code_eff = P_PERIODO_Ant
                         AND sgrchrt_stsp_key_sequence =p_sp;
                Exception
                    When Others then 
                       vn_existe_sgrchrt:=0;            
                End;

                IF vn_existe_sgrchrt > 0  THEN
                    Begin     
                              UPDATE sgrchrt 
                                SET sgrchrt_active_ind = NULL
                              WHERE sgrchrt_pidm = p_pidm
                              AND sgrchrt_term_code_eff = P_PERIODO_Ant
                              AND sgrchrt_stsp_key_sequence = p_sp;
                             Commit;
                    Exception   
                        When Others then 
                         null;
                    End;                          
                END IF;
            
                vn_existe_sgrchrt:=0;

               Begin  
                        SELECT COUNT (*)
                            INTO vn_existe_sgrchrt
                        FROM sgrchrt
                        WHERE 1 =1
                        AND sgrchrt_pidm = p_pidm
                        AND sgrchrt_term_code_eff =P_periodo
                        AND sgrchrt_stsp_key_sequence =p_sp;
               Exception
                When Others then 
                    vn_existe_sgrchrt:=0;
               End;
               
               
                IF vn_existe_sgrchrt = 0 THEN
                    Begin 
                
                               INSERT INTO sgrchrt (sgrchrt_pidm,
                                                    sgrchrt_term_code_eff,
                                                    sgrchrt_chrt_code,
                                                    sgrchrt_activity_date,
                                                    sgrchrt_stsp_key_sequence,
                                                    sgrchrt_active_ind)
                                    VALUES (p_pidm,
                                                P_PERIODO_Ant,
                                                P_PERIODO_Ant,
                                                SYSDATE,
                                                p_sp,
                                                'Y');
                                 Commit;
                    Exception
                        When Others then
                            null;
                    End;
                ELSE
                    Begin 
                           UPDATE sgrchrt
                              SET sgrchrt_active_ind = 'Y'
                            WHERE sgrchrt_pidm = p_pidm
                                  AND sgrchrt_term_code_eff = P_PERIODO_Ant
                                  AND sgrchrt_stsp_key_sequence =  p_sp;
                           Commit;
                    Exception
                        When Others then
                            null;
                    End;
                END IF;


                   
        ----------------------------------- Hace el proceso de cancelacion de Financiera ---------------------------
        
                    Begin 
                            SELECT NVL (COUNT (tzdocta_pidm), 0)
                                 INTO vtzdocta
                              FROM tzdocta
                             WHERE     tzdocta_pidm = p_pidm
                             AND tzdocta_term_code = P_periodo;
                    Exception
                        When Others then 
                              vtzdocta:=0;
                    End;

                    IF vtzdocta > 0 THEN
                        
                        Begin 
                               UPDATE tzdocta 
                                    SET tzdocta_term_code =P_PERIODO_Ant,
                                            tzdocta_ind = NULL,
                                            tzdocta_observaciones = NULL,
                                            tzdocta_activity_date = SYSDATE
                                WHERE tzdocta_pidm = p_pidm
                                AND tzdocta_term_code = P_PERIODO_Ant
                                AND tzdocta_appl_no =
                                                     (SELECT MAX (tzdocta_appl_no)
                                                      FROM tzdocta
                                                      WHERE tzdocta_pidm =p_pidm
                                                      AND tzdocta_term_code =P_PERIODO_Ant);
                               Commit;
                        Exception
                            when others then
                                null;
                        End;
                    END IF;          
        
        
           dbms_output.put_line('Cancelacion Financiera ');        

              for cx in (
                                        
                                SELECT DISTINCT
                                       a.sfrstcr_pidm Pidm,
                                       a.sfrstcr_term_code Periodo,
                                       a.sfrstcr_ptrm_code Pperiodo,
                                       SSBSECT_PTRM_START_DATE Fecha_Inicio,
                                       ssbsect_ptrm_end_date Fecha_Fin,
                                       a.sfrstcr_camp_code Campus,
                                       a.sfrstcr_levl_code Nivel
                                FROM ssbsect, 
                                     sfrstcr a
                                WHERE ssbsect_term_code = a.sfrstcr_term_code
                                AND ssbsect_crn = a.sfrstcr_crn
                                AND ssbsect_ptrm_code = a.sfrstcr_ptrm_code
                                 and substr(a.sfrstcr_term_code,5,1) not in ('8','9')
                            --    AND a.sfrstcr_stsp_key_sequence = P_SP
                              and trunc (SSBSECT_PTRM_START_DATE) = to_Date(f_fecha_inicio_old, 'dd/mm/yyyy')
                                AND a.sfrstcr_pidm = P_PIDM
                                AND a.sfrstcr_term_code =
                                                       (SELECT MAX (b.sfrstcr_term_code)
                                                        FROM sfrstcr b
                                                        WHERE b.sfrstcr_pidm = a.sfrstcr_pidm
                                                        And  b.sfrstcr_stsp_key_sequence = a.sfrstcr_stsp_key_sequence
                                                        and substr(b.sfrstcr_term_code,5,1) not in ('8','9'))
        --                                                
          

                ) loop

                      vl_exito:= 'EXITO';
                      dbms_output.put_line('Cancelacion Financiera Entra ');

                             vl_exito :=  pkg_finanzas.f_actu_tzfacce (
                                                                                             p_pidm              => P_PIDM,
                                                                                             p_periodo          => P_PERIODO,
                                                                                             p_fecha_nueva   => trunc (f_fecha_inicio_nw),
                                                                                             p_fecha_old       => to_date (f_fecha_inicio_old,'dd/mm/rrrr'),
                                                                                             p_per_nuevo      => P_PERIODO,
                                                                                             p_programa       => p_programa,
                                                                                             p_campus          => cx.campus,
                                                                                             p_nivel              => cx.nivel);
                                                Commit;
                          dbms_output.put_line('salida facce  '||vl_exito);
                                                                                             
                             vl_exito:=PKG_FINANZAS_DINAMICOS.F_CAMBIO_FECHA_PADI ( P_PIDM, 
                                                                                                                                 P_PERIODO, 
                                                                                                                                 trunc (f_fecha_inicio_nw),
                                                                                                                                 to_date (f_fecha_inicio_old,'dd/mm/rrrr'), 
                                                                                                                                 P_PERIODO, 
                                                                                                                                 P_PROGRAMA);
                                Commit;                             
                            dbms_output.put_line('salida dinamicoa  '||vl_exito);

                             vl_exito :=  pkg_abcc.f_baja_economica (
                                                                                               pn_pidm           => P_PIDM,
                                                                                               pn_campus       => cx.campus,
                                                                                               pn_nivel            => cx.nivel,
                                                                                               pn_estatus        => 'CC', 
                                                                                               pn_programa     => null, 
                                                                                               pn_periodo        => P_PERIODO,
                                                                                               pn_fecha_baja   => TO_DATE (SYSDATE,'dd/mm/rrrr'),
                                                                                               pn_fecha_inicio   => to_date (f_fecha_inicio_old,'dd/mm/rrrr'), 
                                                                                               pn_fecha_fin      => TO_DATE (SYSDATE,'dd/mm/yyyy'),
                                                                                               pn_keyseqno       => P_SP);
                                Commit;
                            dbms_output.put_line('salida bajaeconomica  '||vl_exito);

                             IF vl_exito != 'EXITO' THEN
                                    null;
                             ELSE

                                    BEGIN
                                                UPDATE TZTORDR
                                                SET TZTORDR_ESTATUS       = 'N',
                                                    TZTORDR_ACTIVITY_DATE = SYSDATE,
                                                    TZTORDR_DATA_ORIGIN   = 'SSB',
                                                    TZTORDR_USER          = USER
                                                  WHERE TZTORDR_PIDM      = P_PIDM
                                                   AND TZTORDR_CAMPUS     =  cx.campus
                                                   AND TZTORDR_NIVEL      = cx.nivel
                                                   AND TZTORDR_PROGRAMA   = P_PROGRAMA
                                                   AND TZTORDR_CONTADOR   = (SELECT  MAX(SFRSTCR_VPDI_CODE)
                                                                                                             FROM SFRSTCR
                                                                                                             WHERE SFRSTCR_PIDM     =P_PIDM 
                                                                                                             and SFRSTCR_LEVL_CODE  = cx.nivel
                                                                                                             and SFRSTCR_CAMP_CODE  =cx.campus) ;
                                                    Commit;
                                    EXCEPTION WHEN OTHERS THEN
                                        vl_exito:='Se presento un error al actualizar la Orden de Compra '|| sqlerrm;
                                        dbms_output.put_line('error 5  '||vl_exito);
                                    END;
                                    
                             /*  SE CANCELA EL AJUSTE DE PAGO UNICO PARA PARA CALCULAR NUEVA FECHA DE APLICACIÓN */


                                     BEGIN
                                        SELECT COUNT (*)
                                        INTO vl_tztpuni
                                        FROM tztpuni
                                        WHERE tztpuni_pidm = P_PIDM
                                        AND tztpuni_fecha_inicio =to_date (f_fecha_inicio_old,'dd/mm/rrrr')
                                        AND tztpuni_chech_final IS NULL;                        
                                     EXCEPTION WHEN OTHERS THEN
                                           vl_tztpuni := 0;
                                     END;

                                     IF vl_tztpuni > 0 THEN
                                        vl_exito := pkg_finanzas.f_can_uni (P_PIDM,
                                                                                            to_date (f_fecha_inicio_old,'dd/mm/rrrr'));

                                        BEGIN
                                           UPDATE tztpuni 
                                            SET tztpuni_fecha_inicio = trunc (f_fecha_inicio_nw),
                                                              tztpuni_prox_fecha = NULL
                                            WHERE tztpuni_pidm =P_PIDM
                                            AND tztpuni_fecha_inicio = to_date (f_fecha_inicio_old,'dd/mm/rrrr')
                                            AND tztpuni_chech_final IS NULL;
                                           Commit;
                                        Exception
                                            When others then 
                                                 vl_exito:='Se presento un error al actualizar la Orden de Compra de Pago Unico '|| sqlerrm;   
                                        END;
                                        
                                     END IF;                            
                                    
                             
                                       vl_exito := pkg_abcc.f_baja_materias ('BI',
                                                                                              to_date (f_fecha_inicio_old,'dd/mm/rrrr'),
                                                                                              p_programa,
                                                                                              P_PIDM
                                                                                                );    
                                     Commit; 
                                      dbms_output.put_line('baja_materia  '||vl_exito); 
                             END IF;

                End Loop;
                
               dbms_output.put_line('bitacora salida  '||vl_exito);
               
               p_comentario:=null;
                If P_RAZON ='CF' then  ---> Los comentarios se deben de crecer de acuerdo al tipo de servicio
                    p_comentario := 'Cambio de Fecha Solictado por el alumno SSB ' ||P_PERIODO ||'  '||P_PROGRAMA ||'  '|| 'Fecha de inicio anterior '|| f_fecha_inicio_old ||'  '|| 'Fecha de inicio Nueva '|| to_char (f_fecha_inicio_nw,'dd/mm/yyyy' );
                Elsif P_RAZON ='CC' then  ---> Los comentarios se deben de crecer de acuerdo al tipo de servicio
                    p_comentario := 'Cambio de Ciclo Solictado por el alumno SSB, Programa '||P_PROGRAMA||
                                             ' Periodo Anterior' ||P_PERIODO_Ant ||'  '|| 'Fecha de inicio anterior '|| f_fecha_inicio_old ||'  '|| 'Periodo Nuevo' ||P_periodo || 'Fecha de inicio Nueva '|| to_char (f_fecha_inicio_nw,'dd/mm/yyyy');                    
                End if;
                                                                                                                            
                pkg_abcc.bitacora (P_PIDM, 
                                            P_PERIODO, 
                                            P_SP, 
                                            P_PROGRAMA, 
                                            p_comentario, 
                                            'SSB',
                                            f_fecha_inicio_old);
                  Commit;           
        
        End if;
        
       If vl_exito ='EXITO' then 
           Commit;
       Else
            rollback;
       End if;                                      

    
END P_CAMBIO_CICLO;



 Procedure Job_cambio_Fecha 
    as
    
    Begin
    
       For cx in (

                        select distinct a.SVRSVPR_PROTOCOL_SEQ_NO No_Servicio, 
                                            a.SVRSVPR_PIDM pidm, 
                                            a.SVRSVPR_SRVC_CODE Servicio, 
                                            a.SVRSVPR_PROTOCOL_AMOUNT Monto, 
                                            b.SVRSVAD_ADDL_DATA_CDE Programa,
                                             d.SVRSVAD_ADDL_DATA_CDE Periodo,
                                            c.SVRSVAD_ADDL_DATA_CDE Fecha_Inicio, 
                                            a.SVRSVPR_SRVS_CODE Estatus, 
                                            a.SVRSVPR_ACTIVITY_DATE Fecha_Servicio
                        from SVRSVPR a
                        left join SVRSVAD b on b.SVRSVAD_PROTOCOL_SEQ_NO = a.SVRSVPR_PROTOCOL_SEQ_NO and b.SVRSVAD_ADDL_DATA_SEQ = 1
                        left join SVRSVAD c on c.SVRSVAD_PROTOCOL_SEQ_NO = a.SVRSVPR_PROTOCOL_SEQ_NO and c.SVRSVAD_ADDL_DATA_SEQ  = 6
                        left join SVRSVAD d on d.SVRSVAD_PROTOCOL_SEQ_NO = a.SVRSVPR_PROTOCOL_SEQ_NO and d.SVRSVAD_ADDL_DATA_SEQ  = 4
                        where 1=1
                        and trunc (SVRSVPR_ACTIVITY_DATE) >=  trunc (sysdate) -10
                        and SVRSVPR_PROTOCOL_AMOUNT > 0
                       and SVRSVPR_DELIVERY_DATE is null
                        and (SVRSVPR_SRVC_CODE, SVRSVPR_SRVS_CODE) in (select ZSTPARA_PARAM_ID , ZSTPARA_PARAM_VALOR
                                                                                                             FROM zstpara
                                                                                                            WHERE zstpara_mapa_id = 'PROCESO_AUTOSER'
                                                                                                            )

        ) loop
                    
                If cx.servicio = 'CAFE' then     
                    
                dbms_output.put_line('Entra a Cambio d Fecha '||cx.servicio);
                     
                                    Begin 
                                              pkg_abcc.ESTATUS_RAZON (cx.pidm,
                                                                                         'DD',
                                                                                         'CF',
                                                                                         cx.fecha_inicio,
                                                                                         cx.programa);   
                                    Exception
                                        When Others then 
                                            null;
                                    End;     
                ElsIf cx.servicio = 'CACI' then 
                
                              dbms_output.put_line('Entra a Cambio d Ciclo '||cx.servicio);
                                    Begin
                                          pkg_abcc.P_CAMBIO_CICLO  (cx.pidm,
                                                                                      'RE',
                                                                                     'CC',
                                                                                     cx.Periodo,
                                                                                      cx.fecha_inicio,
                                                                                     cx.programa);                 
                                    Exception
                                        When Others then 
                                            null;
                                    End;     
                End if;    
                                                            
                Begin
                        update SVRSVPR
                        set SVRSVPR_DELIVERY_DATE = sysdate
                        where SVRSVPR_PROTOCOL_SEQ_NO = cx.NO_SERVICIO
                        and SVRSVPR_PIDM = cx.pidm;
                Exception
                    When Others then 
                        null;
                End;
                                
        End loop;
        Commit;
        
End Job_cambio_Fecha;

FUNCTION F_BAJA_ECONOMICA (PN_PIDM IN NUMBER,
                           PN_CAMPUS IN VARCHAR2,
                           PN_NIVEL IN VARCHAR2,
                           PN_ESTATUS IN VARCHAR2 ,
                           PN_PROGRAMA VARCHAR2 DEFAULT NULL,
                           PN_PERIODO VARCHAR2,
                           PN_FECHA_BAJA DATE,
                           PN_FECHA_INICIO DATE,
                           PN_FECHA_FIN DATE,
                           PN_KEYSEQNO NUMBER) RETURN VARCHAR2
IS

/* Actualizado 08/10/2021 por jrezaoli
    se agrega cancelacion de accesorios por código especifico
*/

VL_ERROR                    VARCHAR2(1000):= 'EXITO';
VL_EXISTE_CONF              NUMBER:=0;
VL_PAGO_BAJA                NUMBER :=0;
VL_CARGO_BAJA               NUMBER :=0;
VL_SEMANA                   VARCHAR2(3):= NULL;
VL_INSCRIP_CODE             VARCHAR2(4);
VL_DESCRIPCION              VARCHAR2(250):= NULL;
VL_TRANSACCION              NUMBER :=0;
VL_PERIODO                  VARCHAR2(6):= NULL;
VL_PARCIAL_CODE             VARCHAR2(4);
VC_CONTA                    NUMBER:=0;
VL_PARTE                    VARCHAR(4):= NULL;
VL_RATE                     VARCHAR2(6);
VL_NUMPAG                   NUMBER :=0;
VL_EXISTE_DETAIL            VARCHAR2(6);
VL_PERIODO_A                VARCHAR2(9);
VL_EXIS_CONTRA              VARCHAR(6);
VL_MONTO_PAGADO             VARCHAR(6);
VL_CODIGO_AJ                VARCHAR(6);
VL_EXIS_AJUST               VARCHAR(6);
VL_COD_CONTRA               VARCHAR(9);
VL_DESC_CONTRA              VARCHAR(50);
VL_EXISTE_CSH               VARCHAR(9);
VL_CSH_MONTO                VARCHAR(9);
VL_CSH_PAG                  VARCHAR(9);
VL_AJUSTA_CSH               VARCHAR(9);
VL_CARGO_TRAM               VARCHAR(50);
VL_MONTO_TRAM               VARCHAR(10);
VL_VALIDA_TRAM              VARCHAR(10);
VL_ENTRA                    VARCHAR (10);
VL_EXIS_CONTRA_2            VARCHAR2(10);
VL_AJUSTE                   VARCHAR(500);
VL_CONDONACION              VARCHAR2 (4);
VL_CONDONACION_DESC         VARCHAR2(50);
VL_ENTRA_COND               VARCHAR2(3);
VL_ENTRA_COND_2             NUMBER;
VL_EXI_CONF                 NUMBER;
VL_1SS                      NUMBER;
VL_1SS_NUM                  NUMBER;
VL_1SS_PPER                 VARCHAR2(4);
VL_1SS_2                    NUMBER;
VL_1SS_PPL                  VARCHAR2(11);
VL_MATRICULA                VARCHAR2(11);
VL_MESCONTENCION            NUMBER;
VL_PROGR                    VARCHAR2(11);
VL_FUNCION                  VARCHAR2(200);
VL_PROMOCION                NUMBER;
VL_PROMOCION_MONTO          NUMBER;
VL_PROMOCION_TRAN           NUMBER;
VL_PROMOCION_VIG            DATE;
VL_PROMOCION_PERIODO        VARCHAR2(11);
VL_APL_AJUSTE               VARCHAR2(500);
VL_CART_UTL                 VARCHAR2(500);
VL_DIAS_AJUSTE              NUMBER;
VL_AJUSTA                   NUMBER;
VL_CAN_BECA                 VARCHAR2(500);
VL_COD_CANCELA              VARCHAR2(5);
VL_MES_CONTE                NUMBER;

CURSOR C_CONF IS
           ----- Se busca que exista la configuracion en la tabla de SZVBAEC  -----
          SELECT  COUNT(*),SZVBAEC_SEMANA_INI, SZVBAEC_SEMANA_FIN, SZVBAEC_PAGO_REQ, SZVBAEC_CONCEPTO_CARGO
                     , SZVBAEC_AJUSTE_TUI, SZVBAEC_CONCEPTO_TUI, SZVBAEC_PORCENT_TUI
                     , SZVBAEC_AJUSTE_PARC_VEN, SZVBAEC_CONCEPTO_PARC_VEN, SZVBAEC_PORCENT_PARC_VEN
                     , SZVBAEC_AJUSTE_PARC_XVEN, SZVBAEC_CONCEPTO_PARC_XVEN, SZVBAEC_PORCENT_PARC_XVEN
                     , SZVBAEC_AJUSTE_ACCE, SZVBAEC_CONCEPTO_ACCE, SZVBAEC_PORCENT_ACCE
                     , SZVBAEC_AJUSTE_BECA, SZVBAEC_CONCEPTO_BECA, SZVBAEC_PORCENT_BECA
                     , SZVBAEC_AJUSTE_DESCTO, SZVBAEC_CONCEPTO_DESCTO, SZVBAEC_PORCENT_DESCTO
                     , SZVBAEC_AJUSTE_INTERES, SZVBAEC_CONCEPTO_INTERES, SZVBAEC_PORCENT_INTERES
                     , SZVBAEC_AJUSTE_PLAN_VEN, SZVBAEC_CONCEPTO_PLAN_VEN, SZVBAEC_PORCENT_PLAN_VEN
                     , SZVBAEC_AJUSTE_PLAN_XVEN, SZVBAEC_CONCEPTO_PLAN_XVEN, SZVBAEC_PORCENT_PLAN_XVEN
            FROM SZVBAEC
            WHERE SZVBAEC_CAMP_CODE = PN_CAMPUS
            AND SZVBAEC_LEVL_CODE = PN_NIVEL
            AND SZVBAEC_STST_CODE = PN_ESTATUS
            AND NVL(SZVBAEC_PROGRAM_CODE,'0') = NVL(PN_PROGRAMA,NVL(SZVBAEC_PROGRAM_CODE,'0'))
            GROUP BY
                       SZVBAEC_SEMANA_INI, SZVBAEC_SEMANA_FIN, SZVBAEC_PAGO_REQ, SZVBAEC_CONCEPTO_CARGO
                     , SZVBAEC_AJUSTE_TUI, SZVBAEC_CONCEPTO_TUI, SZVBAEC_PORCENT_TUI
                     , SZVBAEC_AJUSTE_PARC_VEN, SZVBAEC_CONCEPTO_PARC_VEN, SZVBAEC_PORCENT_PARC_VEN
                     , SZVBAEC_AJUSTE_PARC_XVEN, SZVBAEC_CONCEPTO_PARC_XVEN, SZVBAEC_PORCENT_PARC_XVEN
                     , SZVBAEC_AJUSTE_ACCE, SZVBAEC_CONCEPTO_ACCE, SZVBAEC_PORCENT_ACCE
                     , SZVBAEC_AJUSTE_BECA, SZVBAEC_CONCEPTO_BECA, SZVBAEC_PORCENT_BECA
                     , SZVBAEC_AJUSTE_DESCTO, SZVBAEC_CONCEPTO_DESCTO, SZVBAEC_PORCENT_DESCTO
                     , SZVBAEC_AJUSTE_INTERES, SZVBAEC_CONCEPTO_INTERES, SZVBAEC_PORCENT_INTERES
                     , SZVBAEC_AJUSTE_PLAN_VEN, SZVBAEC_CONCEPTO_PLAN_VEN, SZVBAEC_PORCENT_PLAN_VEN
                     , SZVBAEC_AJUSTE_PLAN_XVEN, SZVBAEC_CONCEPTO_PLAN_XVEN, SZVBAEC_PORCENT_PLAN_XVEN;

BEGIN

  FOR  CF IN C_CONF LOOP

    VL_ERROR := 'EXITO';
    VL_PARTE := NULL;

   BEGIN
     SELECT MAX (SFRSTCR_PTRM_CODE)
       INTO VL_PARTE
       FROM SFRSTCR A
      WHERE     A.SFRSTCR_PIDM = PN_PIDM
            AND A.SFRSTCR_STSP_KEY_SEQUENCE = PN_KEYSEQNO
            AND SUBSTR (A.SFRSTCR_TERM_CODE, 5, 1)  != '8'
            AND A.SFRSTCR_TERM_CODE = (SELECT MAX (A1.SFRSTCR_TERM_CODE)
                                         FROM SFRSTCR A1
                                        WHERE     A.SFRSTCR_PIDM = A1.SFRSTCR_PIDM
                                              AND A.SFRSTCR_STSP_KEY_SEQUENCE = A1.SFRSTCR_STSP_KEY_SEQUENCE)
            AND A.SFRSTCR_CRN IN (SELECT (SSBSECT_CRN)
                                    FROM SSBSECT
                                   WHERE SSBSECT_PTRM_START_DATE = PN_FECHA_INICIO);
   EXCEPTION
    WHEN OTHERS THEN
   VL_PARTE:=NULL;
   END;

   BEGIN
     SELECT  COUNT(*)
       INTO VL_EXI_CONF
       FROM SZVBAEC
      WHERE     SZVBAEC_CAMP_CODE = PN_CAMPUS
            AND SZVBAEC_LEVL_CODE = PN_NIVEL
            AND SZVBAEC_STST_CODE = PN_ESTATUS
            AND NVL(SZVBAEC_PROGRAM_CODE,'0') = NVL(PN_PROGRAMA,NVL(SZVBAEC_PROGRAM_CODE,'0'));
   EXCEPTION
   WHEN OTHERS THEN
   VL_EXISTE_CONF:=0;
   END;

   IF  VL_EXI_CONF > 0 THEN
--   DBMS_OUTPUT.PUT_LINE(CF.SZVBAEC_SEMANA_INI||'-'||CF.SZVBAEC_SEMANA_FIN);
     BEGIN
       IF CF.SZVBAEC_PAGO_REQ = 'S' THEN
          BEGIN
            SELECT SUM (TBRAPPL_AMOUNT) PAGADO, X.PAGO CARGO
              INTO VL_PAGO_BAJA ,VL_CARGO_BAJA
              FROM TBRAPPL B , (SELECT A1.TBRACCD_AMOUNT PAGO, A1.TBRACCD_TRAN_NUMBER
                                  FROM TBRACCD A1
                                 WHERE      A1.TBRACCD_PIDM = PN_PIDM
                                        AND A1.TBRACCD_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_CARGO
                                        AND A1.TBRACCD_TRAN_NUMBER IN (SELECT MAX (A2.TBRACCD_TRAN_NUMBER)
                                                                         FROM TBRACCD A2
                                                                        WHERE     A1.TBRACCD_PIDM = A2.TBRACCD_PIDM
                                                                              AND A1.TBRACCD_DETAIL_CODE = A2.TBRACCD_DETAIL_CODE)) X
             WHERE     B.TBRAPPL_PIDM = PN_PIDM
                   AND B.TBRAPPL_CHG_TRAN_NUMBER = (SELECT A.TBRACCD_TRAN_NUMBER
                                                      FROM TBRACCD A
                                                     WHERE     A.TBRACCD_PIDM = B.TBRAPPL_PIDM
                                                           AND A.TBRACCD_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_CARGO)
                   AND B.TBRAPPL_CHG_TRAN_NUMBER = X.TBRACCD_TRAN_NUMBER
                   AND B.TBRAPPL_REAPPL_IND IS NULL
             GROUP BY X.PAGO;
          EXCEPTION
          WHEN OTHERS THEN
          VL_PAGO_BAJA :=0;
          VL_CARGO_BAJA :=0;
          END;

          IF  VL_PAGO_BAJA < VL_CARGO_BAJA  OR  VL_CARGO_BAJA = 0 THEN
           VL_ERROR := 'No se a liquidado el 100%  del pago por parte del alumno para el proceso de Baja ';
          END IF;

       END IF;

     END;

     VL_SEMANA:=ROUND ((PN_FECHA_BAJA - PN_FECHA_INICIO)  / 7);

--     DBMS_OUTPUT.PUT_LINE('Aqui valida las semanas<<<<'||VL_SEMANA||'----'||PN_FECHA_BAJA||'----'||PN_FECHA_INICIO);

     IF VL_SEMANA >= 0 THEN

       IF VL_SEMANA BETWEEN CF.SZVBAEC_SEMANA_INI AND CF.SZVBAEC_SEMANA_FIN THEN
          ---------------------------------------------------------------------------------------------------------------
          ----Inicia el proceso para los ajustes de cada concepto marcado------------------------------------------------
          ---- Valida que se tenga que ajustar la Colegiatura -----------------------------------------------------------

         IF CF.SZVBAEC_AJUSTE_TUI = 'S' THEN

           BEGIN
             SELECT DISTINCT ZSTPARA_PARAM_VALOR
               INTO VL_INSCRIP_CODE
               FROM ZSTPARA
              WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA' AND ZSTPARA_PARAM_ID = 'INSCRIPCION_CARGO';
           EXCEPTION
           WHEN OTHERS THEN
             VL_INSCRIP_CODE := NULL;
           END;

           BEGIN
             SELECT DISTINCT TBBDETC_DESC
               INTO VL_DESCRIPCION
               FROM TBBDETC
              WHERE TBBDETC_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_TUI;
           EXCEPTION
           WHEN OTHERS THEN
             VL_DESCRIPCION := NULL;
           END;

           IF VL_INSCRIP_CODE IS NOT NULL THEN

             FOR COLEG IN (

                  SELECT  B.TBRACCD_PIDM PIDM,
                          B.TBRACCD_BALANCE MONTO,
                          B.TBRACCD_TRAN_NUMBER SECUENCIA,
                          B.TBRACCD_BALANCE*(CF.SZVBAEC_PORCENT_TUI/*vp_inscrip_porc*//100) DESCUENTO,
                          SPRIDEN_ID ID,
                          TBRACCD_STSP_KEY_SEQUENCE, TBRACCD_PERIOD, --RLS20180131
                          TBRACCD_TERM_CODE PERIODO
                    FROM TBRACCD B, SPRIDEN
                   WHERE     B.TBRACCD_PIDM = PN_PIDM
                         AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                         FROM TBBDETC
                                                        WHERE TBBDETC_DCAT_CODE = VL_INSCRIP_CODE
                                                              AND SUBSTR (TBBDETC_DETAIL_CODE,1,2) = SUBSTR (B.TBRACCD_TERM_CODE,1,2)
                                                              AND TBBDETC_DETC_ACTIVE_IND = 'Y'
                                                              AND TBBDETC_TAXT_CODE = PN_NIVEL)
                         AND B.TBRACCD_BALANCE > 0
                         AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                         AND SPRIDEN_CHANGE_IND IS NULL
             ) LOOP

               BEGIN
                 SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                   INTO VL_TRANSACCION
                   FROM TBRACCD
                  WHERE TBRACCD_PIDM=COLEG.PIDM;
               EXCEPTION
               WHEN OTHERS THEN
               VL_TRANSACCION:=0;
               END;

               BEGIN
                SELECT FGET_PERIODO_GENERAL(SUBSTR(COLEG.ID,1,2))
                  INTO VL_PERIODO FROM DUAL;
               EXCEPTION
               WHEN OTHERS THEN
               VL_PERIODO := '000000';
               END;

               BEGIN
                   INSERT
                     INTO TBRACCD
                   VALUES (
                           COLEG.PIDM,                                         -- TBRACCD_PIDM
                           VL_TRANSACCION,                                     -- TBRACCD_TRAN_NUMBER
                           COLEG.PERIODO,                                      -- TBRACCD_TERM_CODE
                           CF.SZVBAEC_CONCEPTO_TUI,                            -- TBRACCD_DETAIL_CODE
                           USER,                                               -- TBRACCD_USER
                           SYSDATE,                                            -- TBRACCD_ENTRY_DATE
                           NVL(COLEG.DESCUENTO,0)* -1,                         -- TBRACCD_AMOUNT
                           NVL(COLEG.DESCUENTO,0) * -1,                        -- TBRACCD_BALANCE
                           SYSDATE,                                            -- TBRACCD_EFFECTIVE_DATE
                           NULL,                                               -- TBRACCD_BILL_DATE
                           NULL,                                               -- TBRACCD_DUE_DATE
                           VL_DESCRIPCION,                                     -- TBRACCD_DESC
                           NULL,                                               -- TBRACCD_RECEIPT_NUMBER
                           COLEG.SECUENCIA,                                    -- TBRACCD_TRAN_NUMBER_PAID
                           NULL,                                               -- TBRACCD_CROSSREF_PIDM
                           NULL,                                               -- TBRACCD_CROSSREF_NUMBER
                           NULL,                                               -- TBRACCD_CROSSREF_DETAIL_CODE
                           'T',                                                -- TBRACCD_SRCE_CODE
                           'Y',                                                -- TBRACCD_ACCT_FEED_IND
                           SYSDATE,                                            -- TBRACCD_ACTIVITY_DATE
                           0,                                                  -- TBRACCD_SESSION_NUMBER
                           NULL,                                               -- TBRACCD_CSHR_END_DATE
                           NULL,                                               -- TBRACCD_CRN
                           NULL,                                               -- TBRACCD_CROSSREF_SRCE_CODE
                           NULL,                                               -- TBRACCD_LOC_MDT
                           NULL,                                               -- TBRACCD_LOC_MDT_SEQ
                           NULL,                                               -- TBRACCD_RATE
                           NULL,                                               -- TBRACCD_UNITS
                           NULL,                                               -- TBRACCD_DOCUMENT_NUMBER
                           SYSDATE,                                            -- TBRACCD_TRANS_DATE
                           NULL,                                               -- TBRACCD_PAYMENT_ID
                           NULL,                                               -- TBRACCD_INVOICE_NUMBER
                           NULL,                                               -- TBRACCD_STATEMENT_DATE
                           NULL,                                               -- TBRACCD_INV_NUMBER_PAID
                           'MXN',                                              -- TBRACCD_CURR_CODE
                           NULL,                                               -- TBRACCD_EXCHANGE_DIFF
                           NULL,                                               -- TBRACCD_FOREIGN
                           NULL,                                               -- TBRACCD_LATE_DCAT_CODE
                           PN_FECHA_INICIO,                                    -- TBRACCD_FEED_DATE
                           NULL,                                               -- TBRACCD_FEED_DOC_CODE
                           NULL,                                               -- TBRACCD_ATYP_CODE
                           NULL,                                               -- TBRACCD_ATYP_SEQNO
                           NULL,                                               -- TBRACCD_CARD_TYPE_VR
                           NULL,                                               -- TBRACCD_CARD_EXP_DATE_VR
                           NULL,                                               -- TBRACCD_CARD_AUTH_NUMBER_VR
                           NULL,                                               -- TBRACCD_CROSSREF_DCAT_CODE
                           NULL,                                               -- TBRACCD_ORIG_CHG_IND
                           NULL,                                               -- TBRACCD_CCRD_CODE
                           NULL,                                               -- TBRACCD_MERCHANT_ID
                           NULL,                                               -- TBRACCD_TAX_REPT_YEAR
                           NULL,                                               -- TBRACCD_TAX_REPT_BOX
                           NULL,                                               -- TBRACCD_TAX_AMOUNT
                           NULL,                                               -- TBRACCD_TAX_FUTURE_IND
                           'AUTOMATICO',                                       -- TBRACCD_DATA_ORIGIN
                           'AUTOMATICO',                                       -- TBRACCD_CREATE_SOURCE
                           NULL,                                               -- TBRACCD_CPDT_IND
                           NULL,                                               -- TBRACCD_AIDY_CODE
                           NVL (COLEG.TBRACCD_STSP_KEY_SEQUENCE,PN_KEYSEQNO),  -- TBRACCD_STSP_KEY_SEQUENCE
                           NVL(COLEG.TBRACCD_PERIOD,VL_PARTE),                 -- TBRACCD_PERIOD
                           NULL,                                               -- TBRACCD_SURROGATE_ID
                           NULL,                                               -- TBRACCD_VERSION
                           USER,                                               -- TBRACCD_USER_ID
                           NULL );                                             -- TBRACCD_VPDI_CODE
               EXCEPTION
               WHEN OTHERS THEN
               VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para colegiatura en TBRACCD '||SQLERRM;
               END;

             END LOOP COLEG;

             VL_TRANSACCION :=0;
             VL_PERIODO := NULL;
             VL_DESCRIPCION:=NULL;

             BEGIN
                SELECT DISTINCT TBBDETC_DESC
                  INTO VL_DESCRIPCION
                  FROM TBBDETC
                 WHERE TBBDETC_DETAIL_CODE = 'PLPA';
             EXCEPTION
             WHEN OTHERS THEN
             VL_DESCRIPCION := NULL;
             END;

              FOR PPAGOS IN (
                             SELECT DISTINCT ZSTPARA_PARAM_VALOR CATEGORIA
                               FROM ZSTPARA
                               WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA' AND ZSTPARA_PARAM_ID = 'INSCRIP_CARGO_PPL'
             ) LOOP

                  FOR PPAGO IN (

                      SELECT  B.TBRACCD_PIDM PIDM,
                              B.TBRACCD_BALANCE MONTO,
                              B.TBRACCD_TRAN_NUMBER SECUENCIA,
                              ROUND(B.TBRACCD_BALANCE*(CF.SZVBAEC_PORCENT_TUI/*vp_inscrip_porc*//100)) DESCUENTO,
                              SPRIDEN_ID ID,
                              TBRACCD_STSP_KEY_SEQUENCE,
                              TBRACCD_PERIOD, --RLS20180131
                              TBRACCD_TERM_CODE PERIODO
                        FROM TBRACCD B, SPRIDEN
                       WHERE      B.TBRACCD_PIDM = PN_PIDM
                              AND B.TBRACCD_BALANCE < 0
                              AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                              AND SPRIDEN_CHANGE_IND IS NULL
                              AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                              FROM TBBDETC
                                                             WHERE     TBBDETC_DCAT_CODE = PPAGOS.CATEGORIA
                                                                   AND TBBDETC_DETC_ACTIVE_IND = 'Y')
                              AND B.TBRACCD_TRAN_NUMBER NOT IN (SELECT TBRAPPL_PAY_TRAN_NUMBER
                                                                  FROM TBRAPPL
                                                                 WHERE     TBRAPPL_PIDM = B.TBRACCD_PIDM
                                                                       AND TBRAPPL_REAPPL_IND IS NULL)

               )LOOP

                 BEGIN
                    SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                      INTO VL_TRANSACCION
                      FROM TBRACCD
                     WHERE TBRACCD_PIDM=PPAGO.PIDM;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_TRANSACCION:=0;
                 END;

                 BEGIN
                    INSERT
                      INTO TBRACCD
                    VALUES (
                            PPAGO.PIDM,                                         -- TBRACCD_PIDM
                            VL_TRANSACCION,                                     -- TBRACCD_TRAN_NUMBER
                            PPAGO.PERIODO,                                      -- TBRACCD_TERM_CODE
                            'PLPA',                                             -- TBRACCD_DETAIL_CODE
                            USER,                                               -- TBRACCD_USER
                            SYSDATE,                                            -- TBRACCD_ENTRY_DATE
                            NVL(PPAGO.DESCUENTO,0) ,                            -- TBRACCD_AMOUNT
                            NVL(PPAGO.DESCUENTO,0)*-1 ,                         -- TBRACCD_BALANCE
                            SYSDATE,                                            -- TBRACCD_EFFECTIVE_DATE
                            NULL,                                               -- TBRACCD_BILL_DATE
                            NULL,                                               -- TBRACCD_DUE_DATE
                            VL_DESCRIPCION,                                     -- TBRACCD_DESC
                            NULL,                                               -- TBRACCD_RECEIPT_NUMBER
                            PPAGO.SECUENCIA,                                    -- TBRACCD_TRAN_NUMBER_PAID
                            NULL,                                               -- TBRACCD_CROSSREF_PIDM
                            NULL,                                               -- TBRACCD_CROSSREF_NUMBER
                            NULL,                                               -- TBRACCD_CROSSREF_DETAIL_CODE
                            'T',                                                -- TBRACCD_SRCE_CODE
                            'Y',                                                -- TBRACCD_ACCT_FEED_IND
                            SYSDATE,                                            -- TBRACCD_ACTIVITY_DATE
                            0,                                                  -- TBRACCD_SESSION_NUMBER
                            NULL,                                               -- TBRACCD_CSHR_END_DATE
                            NULL,                                               -- TBRACCD_CRN
                            NULL,                                               -- TBRACCD_CROSSREF_SRCE_CODE
                            NULL,                                               -- TBRACCD_LOC_MDT
                            NULL,                                               -- TBRACCD_LOC_MDT_SEQ
                            NULL,                                               -- TBRACCD_RATE
                            NULL,                                               -- TBRACCD_UNITS
                            NULL,                                               -- TBRACCD_DOCUMENT_NUMBER
                            SYSDATE,                                            -- TBRACCD_TRANS_DATE
                            NULL,                                               -- TBRACCD_PAYMENT_ID
                            NULL,                                               -- TBRACCD_INVOICE_NUMBER
                            NULL,                                               -- TBRACCD_STATEMENT_DATE
                            NULL,                                               -- TBRACCD_INV_NUMBER_PAID
                            'MXN',                                              -- TBRACCD_CURR_CODE
                            NULL,                                               -- TBRACCD_EXCHANGE_DIFF
                            NULL,                                               -- TBRACCD_FOREIGN
                            NULL,                                               -- TBRACCD_LATE_DCAT_CODE
                            PN_FECHA_INICIO,                                    -- TBRACCD_FEED_DATE
                            NULL,                                               -- TBRACCD_FEED_DOC_CODE
                            NULL,                                               -- TBRACCD_ATYP_CODE
                            NULL,                                               -- TBRACCD_ATYP_SEQNO
                            NULL,                                               -- TBRACCD_CARD_TYPE_VR
                            NULL,                                               -- TBRACCD_CARD_EXP_DATE_VR
                            NULL,                                               -- TBRACCD_CARD_AUTH_NUMBER_VR
                            NULL,                                               -- TBRACCD_CROSSREF_DCAT_CODE
                            NULL,                                               -- TBRACCD_ORIG_CHG_IND
                            NULL,                                               -- TBRACCD_CCRD_CODE
                            NULL,                                               -- TBRACCD_MERCHANT_ID
                            NULL,                                               -- TBRACCD_TAX_REPT_YEAR
                            NULL,                                               -- TBRACCD_TAX_REPT_BOX
                            NULL,                                               -- TBRACCD_TAX_AMOUNT
                            NULL,                                               -- TBRACCD_TAX_FUTURE_IND
                            'AUTOMATICO',                                       -- TBRACCD_DATA_ORIGIN
                            'AUTOMATICO',                                       -- TBRACCD_CREATE_SOURCE
                            NULL,                                               -- TBRACCD_CPDT_IND
                            NULL,                                               -- TBRACCD_AIDY_CODE
                            NVL (PPAGO.TBRACCD_STSP_KEY_SEQUENCE,PN_KEYSEQNO),  -- TBRACCD_STSP_KEY_SEQUENCE
                            NVL (PPAGO.TBRACCD_PERIOD,VL_PARTE) ,               -- TBRACCD_PERIOD
                            NULL,                                               -- TBRACCD_SURROGATE_ID
                            NULL,                                               -- TBRACCD_VERSION
                            USER,                                               -- TBRACCD_USER_ID
                            NULL );                                             -- TBRACCD_VPDI_CODE
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para Plan de Pagos de Colegiatura  en TBRACCD '||SQLERRM;
                 END;

               END LOOP PPAGO;
             END LOOP PPAGOS;
           END IF;
         END IF;
        ---------------------------------------------------------------------------------------------------------
        --------------------------------- Proceso de Parcialidades VENCIDAS--------------------------------------
        ---------------------------------------------------------------------------------------------------------
         VL_RATE := NULL;

         BEGIN
           SELECT DISTINCT SUBSTR (SGBSTDN_RATE_CODE, 1, 1) RATE
             INTO VL_RATE
             FROM SGBSTDN A,   SPRIDEN C
            WHERE     A.SGBSTDN_PIDM = C.SPRIDEN_PIDM
                  AND C.SPRIDEN_CHANGE_IND IS NULL
                  AND C.SPRIDEN_PIDM = PN_PIDM
                  AND A.SGBSTDN_TERM_CODE_EFF IN ( SELECT MAX (A1.SGBSTDN_TERM_CODE_EFF)
                                                     FROM SGBSTDN A1
                                                    WHERE     A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                          AND A.SGBSTDN_PROGRAM_1 = A1.SGBSTDN_PROGRAM_1);
         EXCEPTION
         WHEN OTHERS THEN
         VL_RATE :=NULL;
         END;

--         DBMS_OUTPUT.PUT_LINE(VL_RATE);

         IF VL_RATE = 'P'  THEN
           IF CF.SZVBAEC_AJUSTE_PLAN_VEN = 'S' AND PN_ESTATUS != 'BA' THEN

             BEGIN
               SELECT DISTINCT TBBDETC_DESC
                 INTO VL_DESCRIPCION
                 FROM TBBDETC
                WHERE TBBDETC_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_PLAN_VEN;
             EXCEPTION
             WHEN OTHERS THEN
             VL_DESCRIPCION := NULL;
             END;

             FOR PLANES_VEN IN (

                        SELECT DISTINCT ZSTPARA_PARAM_VALOR CATEGORIA
                          FROM ZSTPARA
                         WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA' AND ZSTPARA_PARAM_ID = 'PLAN_VEN_CARGO'
             ) LOOP
              ---------------------------------------------------------------------------------------------------------
              ------------------ valida que se tenga la categoria correcta para Planes Vencidos  ----------------------
              ---------------------------------------------------------------------------------------------------------
              FOR CARGO IN (

                      SELECT  B.TBRACCD_PIDM PIDM,
                              B.TBRACCD_AMOUNT MONTO,
                              B.TBRACCD_TRAN_NUMBER SECUENCIA,
                              (B.TBRACCD_AMOUNT- NVL((SELECT SUM(TBRACCD_AMOUNT)
                                                       FROM TBRACCD
                                                      WHERE     TBRACCD_PIDM = B.TBRACCD_PIDM
                                                            AND TBRACCD_CREATE_SOURCE = 'CANCELA DINA'
                                                            AND TBRACCD_TRAN_NUMBER_PAID = B.TBRACCD_TRAN_NUMBER
                                                            ),0))*(CF.SZVBAEC_PORCENT_PLAN_VEN/100) DESCUENTO,
                              SPRIDEN_ID ID,
                              TBRACCD_STSP_KEY_SEQUENCE ,
                              TBRACCD_PERIOD, --RLS20180131
                              TBRACCD_TERM_CODE PERIODO,
                              TBRACCD_EFFECTIVE_DATE FECHA_EFFECTIVA,
                              TBRACCD_RECEIPT_NUMBER
                        FROM TBRACCD B, SPRIDEN
                       WHERE     B.TBRACCD_PIDM = PN_PIDM
                             AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                             FROM TBBDETC
                                                            WHERE     TBBDETC_DCAT_CODE = PLANES_VEN.CATEGORIA
                                                                  AND SUBSTR (TBBDETC_DETAIL_CODE,1,2) = SUBSTR (B.TBRACCD_TERM_CODE,1,2)
                                                                  AND TBBDETC_DETC_ACTIVE_IND = 'Y' )
                             AND TO_CHAR(TRUNC(B.TBRACCD_EFFECTIVE_DATE),'MM/RRRR') < TO_CHAR(TO_DATE(PN_FECHA_BAJA,'DD/MM/YY'),'MM/RRRR')
                             AND B.TBRACCD_EFFECTIVE_DATE >= PN_FECHA_INICIO
                             AND (SELECT EXTRACT(YEAR FROM TRUNC(B.TBRACCD_EFFECTIVE_DATE))FROM DUAL) <= (SELECT EXTRACT(YEAR FROM PN_FECHA_BAJA) FROM DUAL)
                             AND B.TBRACCD_TRAN_NUMBER NOT IN (SELECT TBRAPPL_PAY_TRAN_NUMBER
                                                                 FROM TBRAPPL
                                                                WHERE TBRAPPL_PIDM = B.TBRACCD_PIDM AND TBRAPPL_REAPPL_IND IS NULL)
                             AND TRUNC(B.TBRACCD_ENTRY_DATE) = (SELECT MAX(TRUNC(A2.TBRACCD_ENTRY_DATE))
                                                                  FROM TBRACCD A2
                                                                 WHERE     A2.TBRACCD_PIDM = B.TBRACCD_PIDM
                                                                       AND A2.TBRACCD_DETAIL_CODE = B.TBRACCD_DETAIL_CODE)
                             AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                             AND SPRIDEN_CHANGE_IND IS NULL
                       ORDER BY B.TBRACCD_TRAN_NUMBER

               ) LOOP

                 BEGIN
                   SELECT A1.TBRAPPL_PAY_TRAN_NUMBER
                     INTO VL_NUMPAG
                     FROM TBRAPPL A1
                    WHERE     A1.TBRAPPL_PIDM = CARGO.PIDM
                          AND A1.TBRAPPL_CHG_TRAN_NUMBER =  CARGO.SECUENCIA
                          AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                            FROM TBRAPPL A
                                                           WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                                 AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_NUMPAG :=0;
                 END;

                 BEGIN
                   SELECT B.TBRACCD_DETAIL_CODE
                     INTO VL_EXISTE_DETAIL
                     FROM TBRACCD B
                    WHERE     B.TBRACCD_PIDM = CARGO.PIDM
                          AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_EXISTE_DETAIL :=0;
                 END;

                 BEGIN

                   IF CF.SZVBAEC_CONCEPTO_PLAN_VEN <> VL_EXISTE_DETAIL THEN

                     BEGIN
                       SELECT COUNT (ZSTPARA_PARAM_VALOR)
                         INTO VL_EXIS_CONTRA_2
                         FROM ZSTPARA
                        WHERE ZSTPARA_MAPA_ID = 'DET_CODE_CART'
                              AND ZSTPARA_PARAM_ID = 'PARC_ANTERIOR'
                              AND ZSTPARA_PARAM_VALOR = SUBSTR(VL_EXISTE_DETAIL,3,2);
                     EXCEPTION
                     WHEN OTHERS THEN
                     VL_EXIS_CONTRA_2:=0;
                     END;

                     IF VL_EXIS_CONTRA_2 = 0 THEN

                       PKG_FINANZAS.P_DESAPLICA_PAGOS (CARGO.PIDM, CARGO.SECUENCIA) ;

--                       DBMS_OUTPUT.PUT_LINE('cargo ' ||CARGO.MONTO ||'*'||CARGO.SECUENCIA ||'*'||CARGO.DESCUENTO );

                       VL_TRANSACCION :=0;
                       VL_PERIODO     := NULL;
                       VL_AJUSTA      := NULL;

                      /* VALIDACION EN VASE A LOS 20 DIAS DESPUES DE LA FECHA DE INICIO
                         ACTUALIZADO: JREZAOLI
                         FECHA: 04/09/2020  */

                       BEGIN
                         SELECT TO_NUMBER(ZSTPARA_PARAM_VALOR)
                           INTO VL_DIAS_AJUSTE
                           FROM ZSTPARA
                          WHERE     ZSTPARA_MAPA_ID = 'DIAS_BAJADT'
                                AND ZSTPARA_PARAM_ID = 'GENERAL';

                       END;

                       IF PN_ESTATUS IN ('BD','BT') THEN

                         IF LAST_DAY(TRUNC(SYSDATE)) > LAST_DAY(TRUNC(CARGO.FECHA_EFFECTIVA)) THEN
                           VL_AJUSTA:= 0;
                         ELSE

                           IF LAST_DAY(TRUNC(SYSDATE)) < LAST_DAY(TRUNC(CARGO.FECHA_EFFECTIVA)) THEN
                             VL_AJUSTA:= 1;
                           ELSE

                             IF LAST_DAY(TRUNC(SYSDATE)) = LAST_DAY(TRUNC(PN_FECHA_INICIO)) THEN

                               IF TRUNC(SYSDATE) <= TRUNC(PN_FECHA_INICIO)+VL_DIAS_AJUSTE THEN
                                 VL_AJUSTA:= 1;
                               ELSE
                                 VL_AJUSTA:= 0;
                               END IF;

                             ELSE

                               IF TRUNC(SYSDATE) <= TRUNC(TRUNC(SYSDATE)-(TO_CHAR(TRUNC(SYSDATE),'DD')-1))+VL_DIAS_AJUSTE THEN
                                 VL_AJUSTA:= 1;
                               ELSE
                                 VL_AJUSTA:= 0;
                               END IF;

                             END IF;

                           END IF;

                         END IF;

                       ELSE
                         VL_AJUSTA:= 1;
                       END IF;

                       IF VL_AJUSTA = 1 THEN

                           BEGIN
                              SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                                INTO VL_TRANSACCION
                                FROM TBRACCD
                               WHERE TBRACCD_PIDM=CARGO.PIDM;
                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_TRANSACCION:=0;
                           END;

                           BEGIN
                             INSERT
                               INTO TBRACCD
                             VALUES (
                                    CARGO.PIDM,   -- TBRACCD_PIDM
                                    VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                                    CARGO.PERIODO,    -- TBRACCD_TERM_CODE
                                    CF.SZVBAEC_CONCEPTO_PLAN_VEN,--??vp_acceso_code,     ---TBRACCD_DETAIL_CODE
                                    USER,     ---TBRACCD_USER
                                    SYSDATE,     --TBRACCD_ENTRY_DATE
                                    NVL(CARGO.DESCUENTO,0),
                                    NVL(CARGO.DESCUENTO,0) * -1,    ---TBRACCD_BALANCE
                                    SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                                    NULL,    --TBRACCD_BILL_DATE
                                    NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                    VL_DESCRIPCION,    -- TBRACCD_DESC
                                    CARGO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                                    CARGO.SECUENCIA,     --TBRACCD_TRAN_NUMBER_PAID
                                    NULL,     --TBRACCD_CROSSREF_PIDM
                                    NULL,    --TBRACCD_CROSSREF_NUMBER
                                    NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                    'T',    --TBRACCD_SRCE_CODE
                                    'Y',    --TBRACCD_ACCT_FEED_IND
                                    SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                    0,        --TBRACCD_SESSION_NUMBER
                                    NULL,    -- TBRACCD_CSHR_END_DATE
                                    NULL,     --TBRACCD_CRN
                                    NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                    NULL,     -- TBRACCD_LOC_MDT
                                    NULL,     --TBRACCD_LOC_MDT_SEQ
                                    NULL,     -- TBRACCD_RATE
                                    NULL,     --TBRACCD_UNITS
                                    NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                    SYSDATE,  -- TBRACCD_TRANS_DATE
                                    NULL,        -- TBRACCD_PAYMENT_ID
                                    NULL,     -- TBRACCD_INVOICE_NUMBER
                                    NULL,     -- TBRACCD_STATEMENT_DATE
                                    NULL,     -- TBRACCD_INV_NUMBER_PAID
                                    'MXN',     -- TBRACCD_CURR_CODE
                                    NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                    NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                    NULL,     -- TBRACCD_LATE_DCAT_CODE
                                    PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                                    NULL,     -- TBRACCD_FEED_DOC_CODE
                                    NULL,     -- TBRACCD_ATYP_CODE
                                    NULL,     -- TBRACCD_ATYP_SEQNO
                                    NULL,     -- TBRACCD_CARD_TYPE_VR
                                    NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                    NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                    NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                    NULL,     -- TBRACCD_ORIG_CHG_IND
                                    NULL,     -- TBRACCD_CCRD_CODE
                                    NULL,     -- TBRACCD_MERCHANT_ID
                                    NULL,     -- TBRACCD_TAX_REPT_YEAR
                                    NULL,     -- TBRACCD_TAX_REPT_BOX
                                    NULL,     -- TBRACCD_TAX_AMOUNT
                                    NULL,     -- TBRACCD_TAX_FUTURE_IND
                                    'AUTOMATICOp',     -- TBRACCD_DATA_ORIGIN
                                    'AUTOMATICOp',   -- TBRACCD_CREATE_SOURCE
                                    NULL,     -- TBRACCD_CPDT_IND
                                    NULL,     --TBRACCD_AIDY_CODE
                                    NVL(CARGO.TBRACCD_STSP_KEY_SEQUENCE , PN_KEYSEQNO),    --TBRACCD_STSP_KEY_SEQUENCE
                                    NVL(CARGO.TBRACCD_PERIOD ,VL_PARTE),     --TBRACCD_PERIOD
                                    NULL,    --TBRACCD_SURROGATE_ID
                                    NULL,     -- TBRACCD_VERSION
                                    USER,     --TBRACCD_USER_ID
                                    NULL );     --TBRACCD_VPDI_CODE
                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para planes vencidos en TBRACCD '||SQLERRM;
                           END;

                           BEGIN
                             SELECT COUNT(*)
                               INTO VL_PROMOCION
                               FROM TBRACCD
                              WHERE     TBRACCD_PIDM = CARGO.PIDM
                                    AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                                    AND TBRACCD_TRAN_NUMBER_PAID = CARGO.SECUENCIA;
                           END;

                           IF VL_PROMOCION > 0 AND PN_ESTATUS NOT IN ('CC','CF') THEN

                             BEGIN
                               SELECT TBRACCD_AMOUNT,TBRACCD_TRAN_NUMBER,TBRACCD_EFFECTIVE_DATE,TBRACCD_TERM_CODE
                                 INTO VL_PROMOCION_MONTO,VL_PROMOCION_TRAN,VL_PROMOCION_VIG,VL_PROMOCION_PERIODO
                                 FROM TBRACCD
                                WHERE     TBRACCD_PIDM = CARGO.PIDM
                                      AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                                      AND TBRACCD_TRAN_NUMBER_PAID = CARGO.SECUENCIA;
                             END;

                             IF VL_PROMOCION_VIG <= TRUNC(SYSDATE) THEN
                                  VL_PROMOCION_VIG:= TRUNC(SYSDATE);
                             ELSE
                                  VL_PROMOCION_VIG:=VL_PROMOCION_VIG;
                             END IF;

                             VL_APL_AJUSTE := PKG_FINANZAS.SP_APLICA_AJUSTE ( CARGO.PIDM,
                                                                              VL_PROMOCION_TRAN,
                                                                              SUBSTR(CARGO.PERIODO,1,2)||'ON',
                                                                              VL_PROMOCION_MONTO,
                                                                              VL_PROMOCION_PERIODO,
                                                                              'CANCELACION DE PROMOCION',
                                                                              SYSDATE,
                                                                              NULL,
                                                                              NULL,
                                                                              NULL,
                                                                              'SZFABCC');

                             BEGIN
                                UPDATE TBRACCD
                                   SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
                                 WHERE     TBRACCD_PIDM = CARGO.PIDM
                                       AND TBRACCD_DETAIL_CODE = SUBSTR(CARGO.PERIODO,1,2)||'ON'
                                       AND TBRACCD_USER = 'SZFABCC'
                                       AND TRUNC(TBRACCD_EFFECTIVE_DATE) = VL_PROMOCION_VIG;
                             EXCEPTION
                             WHEN OTHERS THEN
                             VL_ERROR :=' Errror al actualizar saldo Saldo>>  ' || SQLERRM ;
                             END;

                           END IF;

                           IF  CARGO.DESCUENTO = CARGO.MONTO THEN

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
                                WHERE     TBRACCD_PIDM = CARGO.PIDM
                                      AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
                             EXCEPTION
                              WHEN OTHERS THEN
                                VL_ERROR :=' Errror al actualizar saldo Pago>>  ' || SQLERRM ;
                             END;

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC',
                                      TBRACCD_TRAN_NUMBER_PAID = NULL
                                WHERE     TBRACCD_PIDM = CARGO.PIDM
                                      AND TBRACCD_TRAN_NUMBER = CARGO.SECUENCIA;
                             EXCEPTION
                             WHEN OTHERS THEN
                             VL_ERROR :=' Errror al actualizar saldo Saldo>>  ' || SQLERRM ;
                             END;

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_TRAN_NUMBER_PAID = NULL
                                WHERE     TBRACCD_PIDM = CARGO.PIDM
                                      AND TBRACCD_TRAN_NUMBER_PAID = CARGO.SECUENCIA
                                      AND (TBRACCD_CREATE_SOURCE != 'CANCELA DINA' OR TBRACCD_CREATE_SOURCE IS NULL)
                                      AND TBRACCD_TRAN_NUMBER != VL_TRANSACCION;
                             EXCEPTION
                             WHEN OTHERS THEN
                             VL_ERROR :=' Errror al actualizar saldo Saldo>>  ' || SQLERRM ;
                             END;

                           END IF;
                       END IF;
                     END IF;
                   END IF;
                 END;
               END LOOP CARGO;
             END LOOP PLANES_VEN;
           END IF;

         ELSE

           VL_DESCRIPCION := NULL;
           VL_PARCIAL_CODE := NULL;

           IF CF.SZVBAEC_AJUSTE_PARC_VEN = 'S' THEN

--            DBMS_OUTPUT.PUT_LINE(CF.SZVBAEC_AJUSTE_PARC_VEN);

             BEGIN
               SELECT DISTINCT ZSTPARA_PARAM_VALOR
                 INTO VL_PARCIAL_CODE
                 FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA' AND ZSTPARA_PARAM_ID = 'PARC_VEN_CARGO';
             EXCEPTION
             WHEN OTHERS THEN
               VL_PARCIAL_CODE := NULL;
             END;

             BEGIN
               SELECT DISTINCT TBBDETC_DESC
                 INTO VL_DESCRIPCION
                 FROM TBBDETC
                WHERE TBBDETC_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_PARC_VEN;
             EXCEPTION
             WHEN OTHERS THEN
               VL_DESCRIPCION := NULL;
             END;
               ---------------------------------------------------------------------------------------------------------
               ------------------ valida que se tenga la categoria  correcta para parcialidades  -----------------------
               ---------------------------------------------------------------------------------------------------------
             IF VL_PARCIAL_CODE IS NOT NULL AND PN_ESTATUS != 'BA' THEN

--               DBMS_OUTPUT.PUT_LINE('Entra 1***' ||PN_PIDM || '***'||VL_PARCIAL_CODE|| '***'||PN_FECHA_BAJA||'***'||PN_FECHA_INICIO||'***'||PN_FECHA_FIN);

               FOR PARCIAL IN (

                       SELECT B.TBRACCD_PIDM PIDM,
                              B.TBRACCD_AMOUNT MONTO,
                              B.TBRACCD_TRAN_NUMBER SECUENCIA,
                              (B.TBRACCD_AMOUNT- NVL((SELECT SUM(TBRACCD_AMOUNT)
                                                       FROM TBRACCD
                                                      WHERE     TBRACCD_PIDM = B.TBRACCD_PIDM
                                                            AND TBRACCD_CREATE_SOURCE = 'CANCELA DINA'
                                                            AND TBRACCD_TRAN_NUMBER_PAID = B.TBRACCD_TRAN_NUMBER
                                                            ),0))*(CF.SZVBAEC_PORCENT_PARC_VEN/100) DESCUENTO,
                              SPRIDEN_ID ID,
                              TBRACCD_STSP_KEY_SEQUENCE,
                              TBRACCD_PERIOD, --RLS20180131,
                              TBRACCD_TERM_CODE PERIODO,
                              TBRACCD_EFFECTIVE_DATE FECHA_EFFECTIVA,
                              TBRACCD_RECEIPT_NUMBER
                         FROM TBRACCD B, SPRIDEN
                        WHERE     B.TBRACCD_PIDM = PN_PIDM
                              AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                              FROM TBBDETC
                                                             WHERE     TBBDETC_DCAT_CODE = VL_PARCIAL_CODE
                                                                   AND SUBSTR (TBBDETC_DETAIL_CODE,1,2)  = SUBSTR (B.TBRACCD_TERM_CODE,1,2)
                                                                   AND TBBDETC_DETC_ACTIVE_IND = 'Y' )
                              AND TRUNC(B.TBRACCD_EFFECTIVE_DATE) < (SELECT TRUNC(TO_DATE(PN_FECHA_BAJA))-(TO_NUMBER(TO_CHAR(TO_DATE(PN_FECHA_BAJA),'DD'))-1)FROM DUAL)
                              AND B.TBRACCD_EFFECTIVE_DATE >= PN_FECHA_INICIO
                              AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                              AND SPRIDEN_CHANGE_IND IS NULL
                              AND TBRACCD_DOCUMENT_NUMBER IS NULL
                        ORDER BY B.TBRACCD_TRAN_NUMBER

               )LOOP

--                 DBMS_OUTPUT.PUT_LINE('CURSOR***PARCIALIDADES VENCIDAS');

                 BEGIN
                   SELECT NVL(MAX(A1.TBRAPPL_PAY_TRAN_NUMBER),0)
                     INTO VL_NUMPAG
                     FROM TBRAPPL A1
                    WHERE A1.TBRAPPL_PIDM = PARCIAL.PIDM
                      AND A1.TBRAPPL_CHG_TRAN_NUMBER =  PARCIAL.SECUENCIA
                      AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                       FROM TBRAPPL A
                                                      WHERE A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                        AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_NUMPAG :=0;
                 END;

--                 DBMS_OUTPUT.PUT_LINE(PARCIAL.PIDM||'-'||PARCIAL.SECUENCIA||'/'||VL_NUMPAG);

                 BEGIN
                   SELECT B.TBRACCD_DETAIL_CODE
                     INTO VL_EXISTE_DETAIL
                     FROM TBRACCD B
                    WHERE B.TBRACCD_PIDM = PARCIAL.PIDM
                      AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;

                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_EXISTE_DETAIL :=0;
                 END;

--                 DBMS_OUTPUT.PUT_LINE(VL_EXISTE_DETAIL);

                 BEGIN
--                  DBMS_OUTPUT.PUT_LINE(CF.SZVBAEC_CONCEPTO_PARC_VEN||'/'||VL_EXISTE_DETAIL);

                   IF CF.SZVBAEC_CONCEPTO_PARC_VEN <> VL_EXISTE_DETAIL THEN

                     BEGIN
                       SELECT COUNT (ZSTPARA_PARAM_VALOR)
                         INTO VL_EXIS_CONTRA_2
                         FROM ZSTPARA
                        WHERE     ZSTPARA_MAPA_ID = 'DET_CODE_CART'
                              AND ZSTPARA_PARAM_ID = 'PARC_ANTERIOR'
                              AND ZSTPARA_PARAM_VALOR = SUBSTR(VL_EXISTE_DETAIL,3,2);
                     EXCEPTION
                     WHEN OTHERS THEN
                     VL_EXIS_CONTRA_2:=0;
                     END;

                     IF VL_EXIS_CONTRA_2 = 0 THEN

--                       DBMS_OUTPUT.PUT_LINE(CF.SZVBAEC_CONCEPTO_PARC_VEN||'/'||VL_EXISTE_DETAIL);

                       VL_TRANSACCION :=0;
                       VL_PERIODO     := NULL;
                       VL_AJUSTA      := NULL;

                       BEGIN
                         SELECT TO_NUMBER(ZSTPARA_PARAM_VALOR)
                           INTO VL_DIAS_AJUSTE
                           FROM ZSTPARA
                          WHERE     ZSTPARA_MAPA_ID = 'DIAS_BAJADT'
                                AND ZSTPARA_PARAM_ID = 'GENERAL';

                       END;

                       IF PN_ESTATUS IN ('BD','BT') THEN

                         IF LAST_DAY(TRUNC(SYSDATE)) > LAST_DAY(TRUNC(PARCIAL.FECHA_EFFECTIVA)) THEN
                           VL_AJUSTA:= 0;
                         ELSE

                           IF LAST_DAY(TRUNC(SYSDATE)) < LAST_DAY(TRUNC(PARCIAL.FECHA_EFFECTIVA)) THEN
                             VL_AJUSTA:= 1;
                           ELSE

                             IF LAST_DAY(TRUNC(SYSDATE)) = LAST_DAY(TRUNC(PN_FECHA_INICIO)) THEN

                               IF TRUNC(SYSDATE) <= TRUNC(PN_FECHA_INICIO)+VL_DIAS_AJUSTE THEN
                                 VL_AJUSTA:= 1;
                               ELSE
                                 VL_AJUSTA:= 0;
                               END IF;

                             ELSE

                               IF TRUNC(SYSDATE) <= TRUNC(TRUNC(SYSDATE)-(TO_CHAR(TRUNC(SYSDATE),'DD')-1))+VL_DIAS_AJUSTE THEN
                                 VL_AJUSTA:= 1;
                               ELSE
                                 VL_AJUSTA:= 0;
                               END IF;

                             END IF;

                           END IF;

                         END IF;

                       ELSE
                         VL_AJUSTA:= 1;
                       END IF;

                       IF VL_AJUSTA = 1 THEN

                           VL_CAN_BECA:= PKG_FINANZAS_REZA.F_AJ_CAN_BECA ( PN_PIDM,
                                                                           PARCIAL.SECUENCIA,
                                                                           PN_FECHA_INICIO,
                                                                           'CANCELACION');

                           BEGIN
                             SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                               INTO VL_TRANSACCION
                               FROM TBRACCD
                              WHERE TBRACCD_PIDM=PARCIAL.PIDM;
                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_TRANSACCION:=0;
                           END;

                           BEGIN
                             SELECT FGET_PERIODO_GENERAL(SUBSTR(PARCIAL.ID,1,2))
                               INTO VL_PERIODO
                               FROM DUAL;
                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_PERIODO := '000000';
                           END;

--                           DBMS_OUTPUT.PUT_LINE(VL_PERIODO||'<<<<'||PARCIAL.ID);

                           PKG_FINANZAS.P_DESAPLICA_PAGOS (PARCIAL.PIDM, PARCIAL.SECUENCIA) ;

--                           DBMS_OUTPUT.PUT_LINE('entra desaplica pagos');

                           BEGIN
                             INSERT
                               INTO TBRACCD
                             VALUES (
                                        PARCIAL.PIDM,   -- TBRACCD_PIDM
                                        VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                                        PARCIAL.PERIODO,    -- TBRACCD_TERM_CODE
                                        CF.SZVBAEC_CONCEPTO_PARC_VEN,--vp_parcial_code,     ---TBRACCD_DETAIL_CODE
                                        USER,     ---TBRACCD_USER
                                        SYSDATE,     --TBRACCD_ENTRY_DATE
                                        NVL(PARCIAL.DESCUENTO,0),
                                        NVL(PARCIAL.DESCUENTO,0) * -1,    ---TBRACCD_BALANCE
                                        SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                                        NULL,    --TBRACCD_BILL_DATE
                                        NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                        VL_DESCRIPCION,    -- TBRACCD_DESC
                                        PARCIAL.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                                        PARCIAL.SECUENCIA,     --TBRACCD_TRAN_NUMBER_PAID
                                        NULL,     --TBRACCD_CROSSREF_PIDM
                                        NULL,    --TBRACCD_CROSSREF_NUMBER
                                        NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                        'T',    --TBRACCD_SRCE_CODE
                                        'Y',    --TBRACCD_ACCT_FEED_IND
                                        SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                        0,        --TBRACCD_SESSION_NUMBER
                                        NULL,    -- TBRACCD_CSHR_END_DATE
                                        NULL,     --TBRACCD_CRN
                                        NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                        NULL,     -- TBRACCD_LOC_MDT
                                        NULL,     --TBRACCD_LOC_MDT_SEQ
                                        NULL,     -- TBRACCD_RATE
                                        NULL,     --TBRACCD_UNITS
                                        NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                        SYSDATE,  -- TBRACCD_TRANS_DATE
                                        NULL,        -- TBRACCD_PAYMENT_ID
                                        NULL,     -- TBRACCD_INVOICE_NUMBER
                                        NULL,     -- TBRACCD_STATEMENT_DATE
                                        NULL,     -- TBRACCD_INV_NUMBER_PAID
                                        'MXN',     -- TBRACCD_CURR_CODE
                                        NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                        NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                        NULL,     -- TBRACCD_LATE_DCAT_CODE
                                        PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                                        NULL,     -- TBRACCD_FEED_DOC_CODE
                                        NULL,     -- TBRACCD_ATYP_CODE
                                        NULL,     -- TBRACCD_ATYP_SEQNO
                                        NULL,     -- TBRACCD_CARD_TYPE_VR
                                        NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                        NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                        NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                        NULL,     -- TBRACCD_ORIG_CHG_IND
                                        NULL,     -- TBRACCD_CCRD_CODE
                                        NULL,     -- TBRACCD_MERCHANT_ID
                                        NULL,     -- TBRACCD_TAX_REPT_YEAR
                                        NULL,     -- TBRACCD_TAX_REPT_BOX
                                        NULL,     -- TBRACCD_TAX_AMOUNT
                                        NULL,     -- TBRACCD_TAX_FUTURE_IND
                                        'AUTOMATICOa',     -- TBRACCD_DATA_ORIGIN
                                        'AUTOMATICOa',   -- TBRACCD_CREATE_SOURCE
                                        NULL,     -- TBRACCD_CPDT_IND
                                        NULL,     --TBRACCD_AIDY_CODE
                                        NVL (PARCIAL.TBRACCD_STSP_KEY_SEQUENCE,PN_KEYSEQNO),     --TBRACCD_STSP_KEY_SEQUENCE
                                        NVL (PARCIAL.TBRACCD_PERIOD,VL_PARTE),     --TBRACCD_PERIOD
                                        NULL,    --TBRACCD_SURROGATE_ID
                                        NULL,     -- TBRACCD_VERSION
                                        USER,     --TBRACCD_USER_ID
                                        NULL );     --TBRACCD_VPDI_CODE

                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para Parcialidad en TBRACCD '||SQLERRM;
                           END;

--                          DBMS_OUTPUT.PUT_LINE('EXITO TBRACCD PRCIALIDADES VENCIDAS');

                           BEGIN
                             SELECT COUNT(*)
                               INTO VL_PROMOCION
                               FROM TBRACCD
                              WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                    AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                                    AND TBRACCD_TRAN_NUMBER_PAID = PARCIAL.SECUENCIA;
                           END;

                           IF VL_PROMOCION > 0 AND PN_ESTATUS NOT IN ('CC','CF') THEN

                             BEGIN
                               SELECT TBRACCD_AMOUNT,TBRACCD_TRAN_NUMBER,TBRACCD_EFFECTIVE_DATE,TBRACCD_TERM_CODE
                                 INTO VL_PROMOCION_MONTO,VL_PROMOCION_TRAN,VL_PROMOCION_VIG,VL_PROMOCION_PERIODO
                                 FROM TBRACCD
                                WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                      AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                                      AND TBRACCD_TRAN_NUMBER_PAID = PARCIAL.SECUENCIA;
                             END;

                             IF VL_PROMOCION_VIG <= TRUNC(SYSDATE) THEN
                                 VL_PROMOCION_VIG:= TRUNC(SYSDATE);
                             ELSE
                                 VL_PROMOCION_VIG:=VL_PROMOCION_VIG;
                             END IF;

                             VL_APL_AJUSTE:= PKG_FINANZAS.SP_APLICA_AJUSTE ( PARCIAL.PIDM,
                                                                             VL_PROMOCION_TRAN,
                                                                             SUBSTR(PARCIAL.PERIODO,1,2)||'ON',
                                                                             VL_PROMOCION_MONTO,
                                                                             VL_PROMOCION_PERIODO,
                                                                             'CANCELACION DE PROMOCION',
                                                                             SYSDATE,
                                                                             NULL,
                                                                             NULL,
                                                                             NULL,
                                                                             'SZFABCC');

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
                                WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                      AND TBRACCD_DETAIL_CODE = SUBSTR(PARCIAL.PERIODO,1,2)||'ON'
                                      AND TBRACCD_USER = 'SZFABCC'
                                      AND TRUNC(TBRACCD_EFFECTIVE_DATE) = VL_PROMOCION_VIG;
                             EXCEPTION
                             WHEN OTHERS THEN
                              VL_ERROR :=' Errror al actualizar saldo Saldo>>  ' || SQLERRM ;
                             END;

                           END IF;

                           IF  PARCIAL.DESCUENTO = PARCIAL.MONTO THEN

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
                                WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                      AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
                             END;

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC',
                                      TBRACCD_TRAN_NUMBER_PAID = NULL
                                WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                      AND TBRACCD_TRAN_NUMBER = PARCIAL.SECUENCIA;
                             END;

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_TRAN_NUMBER_PAID = NULL
                                WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                      AND TBRACCD_TRAN_NUMBER_PAID = PARCIAL.SECUENCIA
                                      AND (TBRACCD_CREATE_SOURCE != 'CANCELA DINA' OR TBRACCD_CREATE_SOURCE IS NULL)
                                      AND TBRACCD_TRAN_NUMBER != VL_TRANSACCION;
                             END;

                           END IF;

                       END IF;
                     END IF;
                   END IF;
                 END;
               END LOOP PARCIAL;
             END IF;
           END IF;
         END IF;
         ---------------------------------------------------------------------------------------------------------
         --------------------------------- Proceso de Parcialidades POR VENCER------------------------------------
         ---------------------------------------------------------------------------------------------------------
         IF VL_RATE = 'P' THEN

           IF CF.SZVBAEC_AJUSTE_PLAN_XVEN = 'S' AND PN_ESTATUS != 'BA' THEN

             BEGIN
               SELECT DISTINCT TBBDETC_DESC
                 INTO VL_DESCRIPCION
                 FROM TBBDETC
                WHERE TBBDETC_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_PLAN_XVEN;--??vP_acceso_code;
             EXCEPTION
             WHEN OTHERS THEN
             VL_DESCRIPCION := NULL;
             END;

              FOR PLANES_XVEN IN (
                                  SELECT DISTINCT ZSTPARA_PARAM_VALOR CATEGORIA
                                    FROM ZSTPARA
                                   WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA' AND ZSTPARA_PARAM_ID = 'PLAN_XVEN_CARGO'
             )LOOP
              ---------------------------------------------------------------------------------------------------------
              ------------------ valida que se tenga la categoria correcta para Planes Por Vencer ---------------------
              ---------------------------------------------------------------------------------------------------------
                FOR CARGO IN (
                                  SELECT  B.TBRACCD_PIDM PIDM,
                                          B.TBRACCD_AMOUNT MONTO,
                                          B.TBRACCD_TRAN_NUMBER SECUENCIA,
                                          (B.TBRACCD_AMOUNT- NVL((SELECT SUM(TBRACCD_AMOUNT)
                                                       FROM TBRACCD
                                                      WHERE     TBRACCD_PIDM = B.TBRACCD_PIDM
                                                            AND TBRACCD_CREATE_SOURCE = 'CANCELA DINA'
                                                            AND TBRACCD_TRAN_NUMBER_PAID = B.TBRACCD_TRAN_NUMBER
                                                            ),0))*(CF.SZVBAEC_PORCENT_PLAN_XVEN/100) DESCUENTO,
                                          SPRIDEN_ID ID,
                                          TBRACCD_STSP_KEY_SEQUENCE ,
                                          TBRACCD_PERIOD, --RLS20180131
                                          TBRACCD_TERM_CODE PERIODO,
                                          TBRACCD_EFFECTIVE_DATE FECHA_EFFECTIVA,
                                          TBRACCD_RECEIPT_NUMBER
                                    FROM TBRACCD B, SPRIDEN
                                   WHERE     B.TBRACCD_PIDM = PN_PIDM
                                         AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                         FROM TBBDETC
                                                                        WHERE     TBBDETC_DCAT_CODE = PLANES_XVEN.CATEGORIA
                                                                              AND SUBSTR (TBBDETC_DETAIL_CODE,1,2) = SUBSTR (B.TBRACCD_TERM_CODE,1,2)
                                                                              AND TBBDETC_DETC_ACTIVE_IND = 'Y')
                                         AND TRUNC(B.TBRACCD_EFFECTIVE_DATE) >= TO_DATE('01'||SUBSTR(PN_FECHA_BAJA,3,10))
                                         AND B.TBRACCD_TRAN_NUMBER NOT IN (SELECT TBRAPPL_PAY_TRAN_NUMBER
                                                                             FROM TBRAPPL
                                                                            WHERE     TBRAPPL_PIDM = B.TBRACCD_PIDM
                                                                                  AND TBRAPPL_REAPPL_IND IS NULL)
                                         AND TRUNC(B.TBRACCD_ENTRY_DATE) = (SELECT MAX(TRUNC(A2.TBRACCD_ENTRY_DATE))
                                                                              FROM TBRACCD A2
                                                                             WHERE     A2.TBRACCD_PIDM = B.TBRACCD_PIDM
                                                                                   AND A2.TBRACCD_DETAIL_CODE = B.TBRACCD_DETAIL_CODE)
                                         AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                                         AND SPRIDEN_CHANGE_IND IS NULL
                                   ORDER BY B.TBRACCD_TRAN_NUMBER

               ) LOOP
--                  DBMS_OUTPUT.PUT_LINE('POR VENCER PLAN'||'---'||'CURSOR');

                 BEGIN
                   SELECT NVL(MAX(A1.TBRAPPL_PAY_TRAN_NUMBER),0)
                     INTO VL_NUMPAG
                     FROM TBRAPPL A1
                    WHERE     A1.TBRAPPL_PIDM = CARGO.PIDM
                          AND A1.TBRAPPL_CHG_TRAN_NUMBER =  CARGO.SECUENCIA
                          AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                            FROM TBRAPPL A
                                                           WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                                 AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_NUMPAG :=0;
                 END;

--                 DBMS_OUTPUT.PUT_LINE('POR VENCER PLAN 1'||'---'||VL_NUMPAG);

                 BEGIN
                   SELECT B.TBRACCD_DETAIL_CODE
                     INTO VL_EXISTE_DETAIL
                     FROM TBRACCD B
                    WHERE     B.TBRACCD_PIDM = CARGO.PIDM
                          AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_EXISTE_DETAIL :=0;
                 END;

--                 DBMS_OUTPUT.PUT_LINE('POR VENCER PLAN 2'||'---'||VL_EXISTE_DETAIL);

                 BEGIN

--                   DBMS_OUTPUT.PUT_LINE('ENTRA POR VENCER PLAN'||CF.SZVBAEC_CONCEPTO_PLAN_XVEN||'***'||VL_EXISTE_DETAIL);

                   IF CF.SZVBAEC_CONCEPTO_PLAN_XVEN <> VL_EXISTE_DETAIL THEN

                     BEGIN
                       SELECT COUNT (ZSTPARA_PARAM_VALOR)
                         INTO VL_EXIS_CONTRA_2
                         FROM ZSTPARA
                        WHERE     ZSTPARA_MAPA_ID = 'DET_CODE_CART'
                              AND ZSTPARA_PARAM_ID = 'PARC_ANTERIOR'
                              AND ZSTPARA_PARAM_VALOR = SUBSTR(VL_EXISTE_DETAIL,3,2);
                     EXCEPTION
                     WHEN OTHERS THEN
                     VL_EXIS_CONTRA_2:=0;
                     END;

                     IF VL_EXIS_CONTRA_2 = 0 THEN
--                       DBMS_OUTPUT.PUT_LINE('ENTRA POR VENCER PLAN 2'||CF.SZVBAEC_CONCEPTO_PLAN_XVEN||'***'||VL_EXISTE_DETAIL);

                       VL_TRANSACCION :=0;
                       VL_PERIODO     := NULL;
                       VL_AJUSTA      :=NULL;

                       BEGIN
                         SELECT TO_NUMBER(ZSTPARA_PARAM_VALOR)
                           INTO VL_DIAS_AJUSTE
                           FROM ZSTPARA
                          WHERE     ZSTPARA_MAPA_ID = 'DIAS_BAJADT'
                                AND ZSTPARA_PARAM_ID = 'GENERAL';

                       END;

                       IF PN_ESTATUS IN ('BD','BT') THEN

                         IF LAST_DAY(TRUNC(SYSDATE)) > LAST_DAY(TRUNC(CARGO.FECHA_EFFECTIVA)) THEN
                           VL_AJUSTA:= 0;
                         ELSE

                           IF LAST_DAY(TRUNC(SYSDATE)) < LAST_DAY(TRUNC(CARGO.FECHA_EFFECTIVA)) THEN
                             VL_AJUSTA:= 1;
                           ELSE

                             IF LAST_DAY(TRUNC(SYSDATE)) = LAST_DAY(TRUNC(PN_FECHA_INICIO)) THEN

                               IF TRUNC(SYSDATE) <= TRUNC(PN_FECHA_INICIO)+VL_DIAS_AJUSTE THEN
                                 VL_AJUSTA:= 1;
                               ELSE
                                 VL_AJUSTA:= 0;
                               END IF;

                             ELSE

                               IF TRUNC(SYSDATE) <= TRUNC(TRUNC(SYSDATE)-(TO_CHAR(TRUNC(SYSDATE),'DD')-1))+VL_DIAS_AJUSTE THEN
                                 VL_AJUSTA:= 1;
                               ELSE
                                 VL_AJUSTA:= 0;
                               END IF;

                             END IF;

                           END IF;

                         END IF;

                       ELSE
                         VL_AJUSTA:= 1;
                       END IF;

                       IF VL_AJUSTA = 1 THEN

                           BEGIN
                              SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                                INTO VL_TRANSACCION
                                FROM TBRACCD
                               WHERE TBRACCD_PIDM=CARGO.PIDM;
                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_TRANSACCION:=0;
                           END;

                           BEGIN
                             SELECT FGET_PERIODO_GENERAL(SUBSTR(CARGO.ID,1,2))
                               INTO VL_PERIODO
                               FROM DUAL;
                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_PERIODO := '000000';
                           END;

                           BEGIN
                             INSERT
                               INTO TBRACCD
                             VALUES (
                                      CARGO.PIDM,   -- TBRACCD_PIDM
                                      VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                                      CARGO.PERIODO,    -- TBRACCD_TERM_CODE
                                      CF.SZVBAEC_CONCEPTO_PLAN_XVEN,--??vp_acceso_code,     ---TBRACCD_DETAIL_CODE
                                      USER,     ---TBRACCD_USER
                                      SYSDATE,     --TBRACCD_ENTRY_DATE
                                      NVL(CARGO.DESCUENTO,0),
                                      NVL(CARGO.DESCUENTO,0) * -1,    ---TBRACCD_BALANCE
                                      SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                                      NULL,    --TBRACCD_BILL_DATE
                                      NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                      VL_DESCRIPCION,    -- TBRACCD_DESC
                                      CARGO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                                      CARGO.SECUENCIA,     --TBRACCD_TRAN_NUMBER_PAID
                                      NULL,     --TBRACCD_CROSSREF_PIDM
                                      NULL,    --TBRACCD_CROSSREF_NUMBER
                                      NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                      'T',    --TBRACCD_SRCE_CODE
                                      'Y',    --TBRACCD_ACCT_FEED_IND
                                      SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                      0,        --TBRACCD_SESSION_NUMBER
                                      NULL,    -- TBRACCD_CSHR_END_DATE
                                      NULL,     --TBRACCD_CRN
                                      NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                      NULL,     -- TBRACCD_LOC_MDT
                                      NULL,     --TBRACCD_LOC_MDT_SEQ
                                      NULL,     -- TBRACCD_RATE
                                      NULL,     --TBRACCD_UNITS
                                      NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                      SYSDATE,  -- TBRACCD_TRANS_DATE
                                      NULL,        -- TBRACCD_PAYMENT_ID
                                      NULL,     -- TBRACCD_INVOICE_NUMBER
                                      NULL,     -- TBRACCD_STATEMENT_DATE
                                      NULL,     -- TBRACCD_INV_NUMBER_PAID
                                      'MXN',     -- TBRACCD_CURR_CODE
                                      NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                      NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                      NULL,     -- TBRACCD_LATE_DCAT_CODE
                                      PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                                      NULL,     -- TBRACCD_FEED_DOC_CODE
                                      NULL,     -- TBRACCD_ATYP_CODE
                                      NULL,     -- TBRACCD_ATYP_SEQNO
                                      NULL,     -- TBRACCD_CARD_TYPE_VR
                                      NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                      NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                      NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                      NULL,     -- TBRACCD_ORIG_CHG_IND
                                      NULL,     -- TBRACCD_CCRD_CODE
                                      NULL,     -- TBRACCD_MERCHANT_ID
                                      NULL,     -- TBRACCD_TAX_REPT_YEAR
                                      NULL,     -- TBRACCD_TAX_REPT_BOX
                                      NULL,     -- TBRACCD_TAX_AMOUNT
                                      NULL,     -- TBRACCD_TAX_FUTURE_IND
                                      'AUTOMATICOb',     -- TBRACCD_DATA_ORIGIN
                                      'AUTOMATICOb',   -- TBRACCD_CREATE_SOURCE
                                      NULL,     -- TBRACCD_CPDT_IND
                                      NULL,     --TBRACCD_AIDY_CODE
                                      NVL(CARGO.TBRACCD_STSP_KEY_SEQUENCE ,PN_KEYSEQNO),     --TBRACCD_STSP_KEY_SEQUENCE
                                      NVL(CARGO.TBRACCD_PERIOD , VL_PARTE),     --TBRACCD_PERIOD
                                      NULL,    --TBRACCD_SURROGATE_ID
                                      NULL,     -- TBRACCD_VERSION
                                      USER,     --TBRACCD_USER_ID
                                      NULL );     --TBRACCD_VPDI_CODE
                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para Planes en TBRACCD '||SQLERRM;
                           END;

                           BEGIN
                             SELECT COUNT(*)
                               INTO VL_PROMOCION
                               FROM TBRACCD
                              WHERE     TBRACCD_PIDM = CARGO.PIDM
                                    AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                                    AND TBRACCD_TRAN_NUMBER_PAID = CARGO.SECUENCIA;
                           END;

                           IF VL_PROMOCION > 0 AND PN_ESTATUS NOT IN ('CC','CF') THEN

                             BEGIN
                               SELECT TBRACCD_AMOUNT,TBRACCD_TRAN_NUMBER,TBRACCD_EFFECTIVE_DATE,TBRACCD_TERM_CODE
                                 INTO VL_PROMOCION_MONTO,VL_PROMOCION_TRAN,VL_PROMOCION_VIG,VL_PROMOCION_PERIODO
                                 FROM TBRACCD
                                WHERE     TBRACCD_PIDM = CARGO.PIDM
                                      AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                                      AND TBRACCD_TRAN_NUMBER_PAID = CARGO.SECUENCIA;
                             END;

                             IF VL_PROMOCION_VIG <= TRUNC(SYSDATE) THEN
                                  VL_PROMOCION_VIG:= TRUNC(SYSDATE);
                             ELSE
                                  VL_PROMOCION_VIG:=VL_PROMOCION_VIG;
                             END IF;

                              VL_APL_AJUSTE:= PKG_FINANZAS.SP_APLICA_AJUSTE ( CARGO.PIDM,
                                                                              VL_PROMOCION_TRAN,
                                                                              SUBSTR(CARGO.PERIODO,1,2)||'ON',
                                                                              VL_PROMOCION_MONTO,
                                                                              VL_PROMOCION_PERIODO,
                                                                              'CANCELACION DE PROMOCION',
                                                                              SYSDATE,
                                                                              NULL,
                                                                              NULL,
                                                                              NULL,
                                                                              'SZFABCC');

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
                                WHERE     TBRACCD_PIDM = CARGO.PIDM
                                      AND TBRACCD_DETAIL_CODE = SUBSTR(CARGO.PERIODO,1,2)||'ON'
                                      AND TBRACCD_USER = 'SZFABCC'
                                       AND TRUNC(TBRACCD_EFFECTIVE_DATE) = VL_PROMOCION_VIG;

                             EXCEPTION
                             WHEN OTHERS THEN
                             VL_ERROR :=' Errror al actualizar saldo Saldo>>  ' || SQLERRM ;
                             END;

                           END IF;

                           IF CARGO.DESCUENTO = CARGO.MONTO THEN

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
                                WHERE     TBRACCD_PIDM = CARGO.PIDM
                                      AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
                             END;

                              BEGIN
                                UPDATE TBRACCD
                                   SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC',
                                       TBRACCD_TRAN_NUMBER_PAID = NULL
                                 WHERE     TBRACCD_PIDM = CARGO.PIDM
                                       AND TBRACCD_TRAN_NUMBER = CARGO.SECUENCIA;
                              END;

                              BEGIN
                                 UPDATE TBRACCD
                                    SET TBRACCD_TRAN_NUMBER_PAID = NULL
                                  WHERE     TBRACCD_PIDM = CARGO.PIDM
                                        AND TBRACCD_TRAN_NUMBER_PAID = CARGO.SECUENCIA
                                        AND (TBRACCD_CREATE_SOURCE != 'CANCELA DINA' OR TBRACCD_CREATE_SOURCE IS NULL)
                                        AND TBRACCD_TRAN_NUMBER != VL_TRANSACCION;
                              END;

                           END IF;
                       END IF;
                     END IF;
                   END IF;
                 END;
               END LOOP CARGO;
             END LOOP PLANES_XVEN;
           END IF;

         ELSE

           VL_DESCRIPCION := NULL;
           VL_PARCIAL_CODE := NULL;

--           DBMS_OUTPUT.PUT_LINE(CF.SZVBAEC_AJUSTE_PARC_XVEN);

           IF CF.SZVBAEC_AJUSTE_PARC_XVEN = 'S' THEN

             BEGIN
                 SELECT DISTINCT ZSTPARA_PARAM_VALOR
                     INTO VL_PARCIAL_CODE
                 FROM ZSTPARA
                 WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA'
                 AND ZSTPARA_PARAM_ID = 'PARC_XVEN_CARGO';
             EXCEPTION
             WHEN OTHERS THEN
               VL_PARCIAL_CODE := NULL;
             END;

--             DBMS_OUTPUT.PUT_LINE(VL_PARCIAL_CODE);


             BEGIN
                     SELECT DISTINCT TBBDETC_DESC
                         INTO VL_DESCRIPCION
                     FROM TBBDETC
                     WHERE TBBDETC_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_PARC_XVEN;--vp_parcial_code;
             EXCEPTION
             WHEN OTHERS THEN
               VL_DESCRIPCION := NULL;
             END;
             ---------------------------------------------------------------------------------------------------------
             ------------------ valida que se tenga la categoria  correcta para parcialidades  -----------------------
             ---------------------------------------------------------------------------------------------------------
             IF VL_PARCIAL_CODE IS NOT NULL AND PN_ESTATUS != 'BA' THEN
--                DBMS_OUTPUT.PUT_LINE('ENTRA POR VENCER JORNADA' ||PN_PIDM || '*'||VL_PARCIAL_CODE|| '*'||PN_NIVEL||'*'||PN_PERIODO||'*'||PN_FECHA_BAJA);

                FOR PARCIAL IN (

                          SELECT  B.TBRACCD_PIDM PIDM,
                                  B.TBRACCD_AMOUNT- NVL((SELECT NVL(SUM(TBRACCD_AMOUNT),0)
                                                       FROM TBRACCD
                                                      WHERE     TBRACCD_PIDM = B.TBRACCD_PIDM
                                                            AND TBRACCD_CREATE_SOURCE = 'CANCELA DINA'
                                                            AND TBRACCD_TRAN_NUMBER_PAID = B.TBRACCD_TRAN_NUMBER
                                                            ),0) MONTO,
                                  B.TBRACCD_TRAN_NUMBER SECUENCIA,
                                  (B.TBRACCD_AMOUNT- NVL((SELECT NVL(SUM(TBRACCD_AMOUNT),0)
                                                       FROM TBRACCD
                                                      WHERE     TBRACCD_PIDM = B.TBRACCD_PIDM
                                                            AND TBRACCD_CREATE_SOURCE = 'CANCELA DINA'
                                                            AND TBRACCD_TRAN_NUMBER_PAID = B.TBRACCD_TRAN_NUMBER
                                                            ),0))*(CF.SZVBAEC_PORCENT_PARC_XVEN/100) DESCUENTO,
                                  SPRIDEN_ID ID,
                                  TBRACCD_EFFECTIVE_DATE,
                                  TBRACCD_STSP_KEY_SEQUENCE,
                                  TBRACCD_PERIOD, --RLS20180131
                                  TBRACCD_TERM_CODE PERIODO,
                                  TBRACCD_EFFECTIVE_DATE FECHA_EFFECTIVA,
                                  TBRACCD_RECEIPT_NUMBER
                            FROM TBRACCD B, SPRIDEN
                           WHERE     B.TBRACCD_PIDM = PN_PIDM
                                 AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                 FROM TBBDETC
                                                                WHERE     TBBDETC_DCAT_CODE = VL_PARCIAL_CODE
                                                                      AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2 )  = SUBSTR (B.TBRACCD_TERM_CODE, 1, 2)
                                                                      AND TBBDETC_DETC_ACTIVE_IND = 'Y')
                                 AND TRUNC(B.TBRACCD_EFFECTIVE_DATE) >= TO_DATE('01/'||TO_CHAR(TO_DATE(PN_FECHA_INICIO,'DD/MM/YY')+12,'MM/YYYY'),'DD/MM/YYYY')
                                 AND TRUNC(B.TBRACCD_EFFECTIVE_DATE) >= TO_DATE('01/'||TO_CHAR(TO_DATE(PN_FECHA_BAJA,'DD/MM/YY'),'MM/YYYY'),'DD/MM/YYYY')
                                 AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                 AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                                 AND SPRIDEN_CHANGE_IND IS NULL
                           ORDER BY B.TBRACCD_TRAN_NUMBER

               )LOOP

--                 DBMS_OUTPUT.PUT_LINE('POR VENCER JORNADA CURSOR   -'||PARCIAL.SECUENCIA
--                                                                    ||'-'||PARCIAL.PIDM
--                                                                    ||'-'||CF.SZVBAEC_CONCEPTO_PARC_XVEN
--                                                                    ||'-'||PARCIAL.DESCUENTO
--                                                                    ||'-'||PN_FECHA_INICIO
--                                                                    ||'-'||PN_FECHA_BAJA);

                 BEGIN
                   SELECT NVL(MAX(A1.TBRAPPL_PAY_TRAN_NUMBER),0)
                     INTO VL_NUMPAG
                     FROM TBRAPPL A1
                    WHERE     A1.TBRAPPL_PIDM = PARCIAL.PIDM
                          AND A1.TBRAPPL_CHG_TRAN_NUMBER =  PARCIAL.SECUENCIA
                          AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                            FROM TBRAPPL A
                                                           WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                                 AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_NUMPAG :=0;
                 END;

--                 DBMS_OUTPUT.PUT_LINE('POR VENCER JORNADA 1'||'---'||VL_NUMPAG);

                 BEGIN
                   SELECT B.TBRACCD_DETAIL_CODE
                     INTO VL_EXISTE_DETAIL
                     FROM TBRACCD B
                    WHERE     B.TBRACCD_PIDM = PARCIAL.PIDM
                          AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_EXISTE_DETAIL :=0;
                 END;

--                 DBMS_OUTPUT.PUT_LINE('POR VENCER JORNADA 2'||'---'||VL_EXISTE_DETAIL);

                 BEGIN

--                   DBMS_OUTPUT.PUT_LINE('POR VENCER JORNADA 3'||'---'||CF.SZVBAEC_CONCEPTO_PARC_XVEN||'---'||VL_EXISTE_DETAIL);

                   IF CF.SZVBAEC_CONCEPTO_PARC_XVEN <> NVL(VL_EXISTE_DETAIL,0) THEN

--                     DBMS_OUTPUT.PUT_LINE(CF.SZVBAEC_CONCEPTO_PARC_XVEN||'-'||VL_EXISTE_DETAIL);

                     BEGIN

                             SELECT COUNT (ZSTPARA_PARAM_VALOR)
                             INTO VL_EXIS_CONTRA_2
                             FROM ZSTPARA
                             WHERE ZSTPARA_MAPA_ID = 'DET_CODE_CART'
                             AND ZSTPARA_PARAM_ID = 'PARC_ANTERIOR'
                             AND ZSTPARA_PARAM_VALOR = SUBSTR(VL_EXISTE_DETAIL,3,2);

                     EXCEPTION
                     WHEN OTHERS THEN
                     VL_EXIS_CONTRA_2:=0;
                     END;

                     IF VL_EXIS_CONTRA_2 = 0 THEN

                       VL_TRANSACCION :=0;
                       VL_PERIODO := NULL;

                       BEGIN
                         SELECT TO_NUMBER(ZSTPARA_PARAM_VALOR)
                           INTO VL_DIAS_AJUSTE
                           FROM ZSTPARA
                          WHERE     ZSTPARA_MAPA_ID = 'DIAS_BAJADT'
                                AND ZSTPARA_PARAM_ID = 'GENERAL';

                       END;

                       IF PN_ESTATUS IN ('BD','BT') THEN

                         IF LAST_DAY(TRUNC(SYSDATE)) > LAST_DAY(TRUNC(PARCIAL.FECHA_EFFECTIVA)) THEN
                           VL_AJUSTA:= 0;
                         ELSE

                           IF LAST_DAY(TRUNC(SYSDATE)) < LAST_DAY(TRUNC(PARCIAL.FECHA_EFFECTIVA)) THEN
                             VL_AJUSTA:= 1;
                           ELSE

                             IF LAST_DAY(TRUNC(SYSDATE)) = LAST_DAY(TRUNC(PN_FECHA_INICIO)) THEN

                               IF TRUNC(SYSDATE) <= TRUNC(PN_FECHA_INICIO)+VL_DIAS_AJUSTE THEN
                                 VL_AJUSTA:= 1;
                               ELSE
                                 VL_AJUSTA:= 0;
                               END IF;

                             ELSE

                               IF TRUNC(SYSDATE) <= TRUNC(TRUNC(SYSDATE)-(TO_CHAR(TRUNC(SYSDATE),'DD')-1))+VL_DIAS_AJUSTE THEN
                                 VL_AJUSTA:= 1;
                               ELSE
                                 VL_AJUSTA:= 0;
                               END IF;

                             END IF;

                           END IF;

                         END IF;

                       ELSE
                         VL_AJUSTA:= 1;
                       END IF;

                       IF VL_AJUSTA = 1 THEN

                           VL_CAN_BECA:= PKG_FINANZAS_REZA.F_AJ_CAN_BECA ( PN_PIDM,
                                                                           PARCIAL.SECUENCIA,
                                                                           PN_FECHA_INICIO,
                                                                           'CANCELACION');

                           BEGIN
                              SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                                INTO VL_TRANSACCION
                                FROM TBRACCD
                               WHERE TBRACCD_PIDM=PARCIAL.PIDM;
                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_TRANSACCION:=0;
                           END;

--                           DBMS_OUTPUT.PUT_LINE('Entra ' ||PN_PIDM || '*'||PARCIAL.SECUENCIA|| '*'||PARCIAL.TBRACCD_EFFECTIVE_DATE||'*'||PARCIAL.TBRACCD_PERIOD||'*'||PARCIAL.MONTO);

                           PKG_FINANZAS.P_DESAPLICA_PAGOS (PARCIAL.PIDM, PARCIAL.SECUENCIA) ;

--                           DBMS_OUTPUT.PUT_LINE('DESAPLICA PAGOS POR VENCER JORNADA');

                           BEGIN
                               INSERT INTO TBRACCD
                               VALUES (
                                       PARCIAL.PIDM,   -- TBRACCD_PIDM
                                       VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                                       PARCIAL.PERIODO,    -- TBRACCD_TERM_CODE
                                       CF.SZVBAEC_CONCEPTO_PARC_XVEN,--vp_parcial_code,     ---TBRACCD_DETAIL_CODE
                                       USER,     ---TBRACCD_USER
                                       SYSDATE,     --TBRACCD_ENTRY_DATE
                                       NVL(PARCIAL.DESCUENTO,0),
                                       NVL(PARCIAL.DESCUENTO,0) * -1,    ---TBRACCD_BALANCE
                                       SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                                       NULL,    --TBRACCD_BILL_DATE
                                       NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                       VL_DESCRIPCION,    -- TBRACCD_DESC
                                       PARCIAL.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                                       PARCIAL.SECUENCIA,     --TBRACCD_TRAN_NUMBER_PAID
                                       NULL,     --TBRACCD_CROSSREF_PIDM
                                       NULL,    --TBRACCD_CROSSREF_NUMBER
                                       NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                       'T',    --TBRACCD_SRCE_CODE
                                       'Y',    --TBRACCD_ACCT_FEED_IND
                                       SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                       0,        --TBRACCD_SESSION_NUMBER
                                       NULL,    -- TBRACCD_CSHR_END_DATE
                                       NULL,     --TBRACCD_CRN
                                       NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                       NULL,     -- TBRACCD_LOC_MDT
                                       NULL,     --TBRACCD_LOC_MDT_SEQ
                                       NULL,     -- TBRACCD_RATE
                                       NULL,     --TBRACCD_UNITS
                                       NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                       SYSDATE,  -- TBRACCD_TRANS_DATE
                                       NULL,        -- TBRACCD_PAYMENT_ID
                                       NULL,     -- TBRACCD_INVOICE_NUMBER
                                       NULL,     -- TBRACCD_STATEMENT_DATE
                                       NULL,     -- TBRACCD_INV_NUMBER_PAID
                                       'MXN',     -- TBRACCD_CURR_CODE
                                       NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                       NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                       NULL,     -- TBRACCD_LATE_DCAT_CODE
                                       PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                                       NULL,     -- TBRACCD_FEED_DOC_CODE
                                       NULL,     -- TBRACCD_ATYP_CODE
                                       NULL,     -- TBRACCD_ATYP_SEQNO
                                       NULL,     -- TBRACCD_CARD_TYPE_VR
                                       NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                       NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                       NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                       NULL,     -- TBRACCD_ORIG_CHG_IND
                                       NULL,     -- TBRACCD_CCRD_CODE
                                       NULL,     -- TBRACCD_MERCHANT_ID
                                       NULL,     -- TBRACCD_TAX_REPT_YEAR
                                       NULL,     -- TBRACCD_TAX_REPT_BOX
                                       NULL,     -- TBRACCD_TAX_AMOUNT
                                       NULL,     -- TBRACCD_TAX_FUTURE_IND
                                       'AUTOMATICOc',     -- TBRACCD_DATA_ORIGIN
                                       'AUTOMATICOc',   -- TBRACCD_CREATE_SOURCE
                                       NULL,     -- TBRACCD_CPDT_IND
                                       NULL,     --TBRACCD_AIDY_CODE
                                       NVL (PARCIAL.TBRACCD_STSP_KEY_SEQUENCE,PN_KEYSEQNO),     --TBRACCD_STSP_KEY_SEQUENCE
                                       NVL(PARCIAL.TBRACCD_PERIOD,VL_PARTE),     --TBRACCD_PERIOD
                                       NULL,    --TBRACCD_SURROGATE_ID
                                       NULL,     -- TBRACCD_VERSION
                                       USER,     --TBRACCD_USER_ID
                                       NULL );     --TBRACCD_VPDI_CODE
                           EXCEPTION
                           WHEN OTHERS THEN
                           VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para Parcialidad en TBRACCD '||SQLERRM;
                           END;


                           IF PARCIAL.DESCUENTO = PARCIAL.MONTO THEN

                             BEGIN
                              SELECT COUNT(*)
                                INTO VL_PROMOCION
                                FROM TBRACCD
                               WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                     AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                                     AND TBRACCD_TRAN_NUMBER_PAID = PARCIAL.SECUENCIA;
                             END;

                             IF VL_PROMOCION > 0 AND PN_ESTATUS NOT IN ('CC','CF') THEN

                                 BEGIN
                                   SELECT TBRACCD_AMOUNT,TBRACCD_TRAN_NUMBER,TBRACCD_EFFECTIVE_DATE,TBRACCD_TERM_CODE
                                     INTO VL_PROMOCION_MONTO,VL_PROMOCION_TRAN,VL_PROMOCION_VIG,VL_PROMOCION_PERIODO
                                     FROM TBRACCD
                                    WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                          AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                                          AND TBRACCD_TRAN_NUMBER_PAID = PARCIAL.SECUENCIA;
                                 END;

                                IF VL_PROMOCION_VIG <= TRUNC(SYSDATE) THEN
                                    VL_PROMOCION_VIG:= TRUNC(SYSDATE);
                                ELSE
                                    VL_PROMOCION_VIG:=VL_PROMOCION_VIG;
                                END IF;

                                VL_APL_AJUSTE:= PKG_FINANZAS.SP_APLICA_AJUSTE ( PARCIAL.PIDM,
                                                                                VL_PROMOCION_TRAN,
                                                                                SUBSTR(PARCIAL.PERIODO,1,2)||'ON',
                                                                                VL_PROMOCION_MONTO,
                                                                                VL_PROMOCION_PERIODO,
                                                                                'CANCELACION DE PROMOCION',
                                                                                SYSDATE,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL,
                                                                                'SZFABCC');

                                 BEGIN
                                   UPDATE TBRACCD
                                      SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
                                    WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                          AND TBRACCD_DETAIL_CODE = SUBSTR(PARCIAL.PERIODO,1,2)||'ON'
                                          AND TBRACCD_USER = 'SZFABCC'
                                          AND TRUNC(TBRACCD_EFFECTIVE_DATE) = VL_PROMOCION_VIG;
                                 END;

                             END IF;

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
                                WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                      AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
                             END;

                             BEGIN
                               UPDATE TBRACCD
                                  SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC',
                                      TBRACCD_TRAN_NUMBER_PAID = NULL
                                WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                      AND TBRACCD_TRAN_NUMBER = PARCIAL.SECUENCIA;
                             END;

                             BEGIN
                                UPDATE TBRACCD
                                   SET TBRACCD_TRAN_NUMBER_PAID = NULL
                                 WHERE     TBRACCD_PIDM = PARCIAL.PIDM
                                       AND TBRACCD_TRAN_NUMBER_PAID = PARCIAL.SECUENCIA
                                       AND (TBRACCD_CREATE_SOURCE != 'CANCELA DINA' OR TBRACCD_CREATE_SOURCE IS NULL)
                                       AND TBRACCD_TRAN_NUMBER != VL_TRANSACCION;
                             END;

                           END IF;
                       END IF;
                     END IF;
                   END IF;
                 END;
               END LOOP PARCIAL;
             END IF;
           END IF;
         END IF;
         ---------------------------------------------------------------------------------------------------------
         ---------------------------------Proceso par aplicar ajustes status BA regla de finanzas-----------------
         ---------------------------------------------------------------------------------------------------------

       IF PN_ESTATUS = 'BA' THEN
--         DBMS_OUTPUT.PUT_LINE('ENTRA PRIMER IF ='||PN_ESTATUS);
--         DBMS_OUTPUT.PUT_LINE('PIDM ='||PN_PIDM);
--         DBMS_OUTPUT.PUT_LINE('FECHA INICIO ='||PN_FECHA_INICIO);

            FOR ADEUDO IN (

                    SELECT B.TBRACCD_PIDM PIDM,
                                       B.TBRACCD_AMOUNT MONTO,
                                       B.TBRACCD_TRAN_NUMBER SECUENCIA,
                                       (B.TBRACCD_AMOUNT- NVL((SELECT SUM(TBRACCD_AMOUNT)
                                                                FROM TBRACCD
                                                               WHERE     TBRACCD_PIDM = B.TBRACCD_PIDM
                                                                     AND TBRACCD_CREATE_SOURCE = 'CANCELA DINA'
                                                                     AND TBRACCD_TRAN_NUMBER_PAID = B.TBRACCD_TRAN_NUMBER
                                                                     ),0))*(100/100) DESCUENTO, ----AGREGAR DATO A LA TABLA
                                       SPRIDEN_ID ID,
                                       TBRACCD_STSP_KEY_SEQUENCE,
                                       TBRACCD_PERIOD PARTE, --RLS20180131,
                                       TBRACCD_TERM_CODE PERIODO,
                                       TBRACCD_EFFECTIVE_DATE FECHA_EFFECTIVA,
                                       TBRACCD_RECEIPT_NUMBER
                                  FROM TBRACCD B, SPRIDEN
                                 WHERE     B.TBRACCD_PIDM = PN_PIDM
                                       AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                       FROM TBBDETC
                                                                      WHERE     TBBDETC_DCAT_CODE = 'COL'
                                                                            AND SUBSTR (TBBDETC_DETAIL_CODE,1,2)  = SUBSTR (B.TBRACCD_TERM_CODE,1,2)
                                                                            AND TBBDETC_DETC_ACTIVE_IND = 'Y' )
---        -                               AND TRUNC(B.TBRACCD_EFFECTIVE_DATE) < (SELECT TRUNC(TO_DATE('30/12/2021'))-(TO_NUMBER(TO_CHAR(TO_DATE('30/12/2021'),'DD'))-1)FROM DUAL)
                                       AND B.TBRACCD_EFFECTIVE_DATE >= PN_FECHA_INICIO
--                                       AND B.TBRACCD_FEED_DATE = PN_FECHA_INICIO
                                       AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                                       AND SPRIDEN_CHANGE_IND IS NULL
                                       AND TBRACCD_DOCUMENT_NUMBER IS NULL
                                       AND B.TBRACCD_TRAN_NUMBER = (SELECT MAX (TBRACCD_TRAN_NUMBER)
                                                                   FROM TBRACCD
                                                                  WHERE TBRACCD_PIDM = B.TBRACCD_PIDM
                                                                        AND TBRACCD_CREATE_SOURCE = B.TBRACCD_CREATE_SOURCE
--                                                                        AND TBRACCD_FEED_DATE = B.TBRACCD_FEED_DATE
                                                                        AND TBRACCD_DOCUMENT_NUMBER IS NULL)
         ORDER BY B.TBRACCD_TRAN_NUMBER



         )LOOP


--         DBMS_OUTPUT.PUT_LINE('POR VENCER -'||ADEUDO.SECUENCIA
--                                                ||'-'||ADEUDO.PIDM
----                                                ||'-'||CF.SZVBAEC_CONCEPTO_PARC_XVEN
--                                                ||'-'||ADEUDO.DESCUENTO
--                                                ||'-'||ADEUDO.FECHA_EFFECTIVA);

           BEGIN
             SELECT NVL(MAX(A1.TBRAPPL_PAY_TRAN_NUMBER),0)
               INTO VL_NUMPAG
               FROM TBRAPPL A1
              WHERE A1.TBRAPPL_PIDM = PN_PIDM
                AND A1.TBRAPPL_CHG_TRAN_NUMBER = ADEUDO.SECUENCIA
                AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                 FROM TBRAPPL A
                                                WHERE A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                  AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
           EXCEPTION
           WHEN OTHERS THEN
           VL_NUMPAG :=0;
           END;

--           DBMS_OUTPUT.PUT_LINE(ADEUDO.PIDM||'-'||ADEUDO.SECUENCIA||'/'||VL_NUMPAG);

           BEGIN
             SELECT B.TBRACCD_DETAIL_CODE
               INTO VL_EXISTE_DETAIL
               FROM TBRACCD B
              WHERE B.TBRACCD_PIDM = ADEUDO.PIDM
                AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;

           EXCEPTION
           WHEN OTHERS THEN
           VL_EXISTE_DETAIL :=0;
           END;

--              DBMS_OUTPUT.PUT_LINE(VL_EXISTE_DETAIL);

---        -      BEGIN
---        -       DBMS_OUTPUT.PUT_LINE(CF.SZVBAEC_CONCEPTO_PARC_VEN||'/'||VL_EXISTE_DETAIL);

           IF CF.SZVBAEC_CONCEPTO_PARC_XVEN <> VL_EXISTE_DETAIL THEN
---        -      IF '01Y4' <> '01M3' THEN
--              DBMS_OUTPUT.PUT_LINE ('ENTRA AL IF =' ||VL_EXISTE_DETAIL);
             BEGIN
               SELECT COUNT (ZSTPARA_PARAM_VALOR)
                 INTO VL_EXIS_CONTRA_2
                 FROM ZSTPARA
                WHERE     ZSTPARA_MAPA_ID = 'DET_CODE_CART'
                      AND ZSTPARA_PARAM_ID = 'PARC_ANTERIOR'
                      AND ZSTPARA_PARAM_VALOR = SUBSTR(VL_EXISTE_DETAIL,3,2);
             EXCEPTION
             WHEN OTHERS THEN
             VL_EXIS_CONTRA_2:=0;
             END;

--             DBMS_OUTPUT.PUT_LINE ('VL_EXIS_CONTRA_2 =' ||VL_EXIS_CONTRA_2);

             IF VL_EXIS_CONTRA_2 = 0 THEN
--             DBMS_OUTPUT.PUT_LINE ('VL_EXIS_CONTRA_2 =' ||VL_EXIS_CONTRA_2);
---        -       DBMS_OUTPUT.PUT_LINE(CF.SZVBAEC_CONCEPTO_PARC_VEN||'/'||VL_EXISTE_DETAIL);

               VL_TRANSACCION :=0;
               VL_PERIODO     := NULL;
               VL_AJUSTA      := NULL;

               BEGIN
                 SELECT TO_NUMBER(ZSTPARA_PARAM_VALOR)
                   INTO VL_DIAS_AJUSTE
                   FROM ZSTPARA
                  WHERE     ZSTPARA_MAPA_ID = 'DIAS_BAJADT'
                        AND ZSTPARA_PARAM_ID = 'GENERAL';

               END;
--              DBMS_OUTPUT.PUT_LINE ('VL_DIAS_AJUSTE =' ||VL_DIAS_AJUSTE);

               IF TRUNC(SYSDATE) <= TRUNC(TRUNC(SYSDATE)-(TO_CHAR(TRUNC(SYSDATE),'DD')-1))+VL_DIAS_AJUSTE THEN
                 VL_AJUSTA:= 1;
                 ELSE
                 VL_AJUSTA:= 0;
               END IF;

--              DBMS_OUTPUT.PUT_LINE ('VL_AJUSTA_4=' ||VL_AJUSTA);

             END IF;

           END IF;


           IF VL_AJUSTA = 1 THEN
--           DBMS_OUTPUT.PUT_LINE ('VL_AJUSTA_5=' ||VL_AJUSTA);

               VL_CAN_BECA:= PKG_FINANZAS_REZA.F_AJ_CAN_BECA ( PN_PIDM,
                                                               ADEUDO.SECUENCIA,
                                                               PN_FECHA_INICIO,
                                                               'CANCELACION');

             BEGIN
               SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                 INTO VL_TRANSACCION
                 FROM TBRACCD
                WHERE TBRACCD_PIDM=ADEUDO.PIDM;
             EXCEPTION
             WHEN OTHERS THEN
             VL_TRANSACCION:=0;
             END;

             BEGIN
               SELECT FGET_PERIODO_GENERAL(SUBSTR(ADEUDO.ID,1,2))
                 INTO VL_PERIODO
                 FROM DUAL;
             EXCEPTION
             WHEN OTHERS THEN
             VL_PERIODO := '000000';
             END;

--             DBMS_OUTPUT.PUT_LINE(VL_PERIODO||'<<<<'||ADEUDO.ID);

             PKG_FINANZAS.P_DESAPLICA_PAGOS (ADEUDO.PIDM, ADEUDO.SECUENCIA) ;

--             DBMS_OUTPUT.PUT_LINE('entra desaplica pagos');

             BEGIN

              FOR I IN 1..1 LOOP

               INSERT
                 INTO TBRACCD
               VALUES (
                          ADEUDO.PIDM,   -- TBRACCD_PIDM
                          VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                          ADEUDO.PERIODO,    -- TBRACCD_TERM_CODE
---        -                  CF.SZVBAEC_CONCEPTO_PARC_XVEN,--vp_ADEUDO_code,     ---TBRACCD_DETAIL_CODE
                          SUBSTR(ADEUDO.PERIODO,1,2)||'Y4',
                          USER,     ---TBRACCD_USER
                          SYSDATE,     --TBRACCD_ENTRY_DATE
                          NVL(ADEUDO.DESCUENTO,0),
                          NVL(ADEUDO.DESCUENTO,0) * -1,    ---TBRACCD_BALANCE
                          SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                          NULL,    --TBRACCD_BILL_DATE
                          NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
---        -                VL_DESCRIPCION,    -- TBRACCD_DESC
                          'AJUSTE BAJA TEMPORAL',
                          ADEUDO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                          ADEUDO.SECUENCIA,     --TBRACCD_TRAN_NUMBER_PAID
                          NULL,     --TBRACCD_CROSSREF_PIDM
                          NULL,    --TBRACCD_CROSSREF_NUMBER
                          NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                          'T',    --TBRACCD_SRCE_CODE
                          'Y',    --TBRACCD_ACCT_FEED_IND
                          SYSDATE,  --TBRACCD_ACTIVITY_DATE
                          0,        --TBRACCD_SESSION_NUMBER
                          NULL,    -- TBRACCD_CSHR_END_DATE
                          NULL,     --TBRACCD_CRN
                          NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                          NULL,     -- TBRACCD_LOC_MDT
                          NULL,     --TBRACCD_LOC_MDT_SEQ
                          NULL,     -- TBRACCD_RATE
                          NULL,     --TBRACCD_UNITS
                          NULL,     -- TBRACCD_DOCUMENT_NUMBER
                          SYSDATE,  -- TBRACCD_TRANS_DATE
                          NULL,        -- TBRACCD_PAYMENT_ID
                          NULL,     -- TBRACCD_INVOICE_NUMBER
                          NULL,     -- TBRACCD_STATEMENT_DATE
                          NULL,     -- TBRACCD_INV_NUMBER_PAID
                          'MXN',     -- TBRACCD_CURR_CODE
                          NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                          NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                          NULL,     -- TBRACCD_LATE_DCAT_CODE
                          PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                          NULL,     -- TBRACCD_FEED_DOC_CODE
                          NULL,     -- TBRACCD_ATYP_CODE
                          NULL,     -- TBRACCD_ATYP_SEQNO
                          NULL,     -- TBRACCD_CARD_TYPE_VR
                          NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                          NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                          NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                          NULL,     -- TBRACCD_ORIG_CHG_IND
                          NULL,     -- TBRACCD_CCRD_CODE
                          NULL,     -- TBRACCD_MERCHANT_ID
                          NULL,     -- TBRACCD_TAX_REPT_YEAR
                          NULL,     -- TBRACCD_TAX_REPT_BOX
                          NULL,     -- TBRACCD_TAX_AMOUNT
                          NULL,     -- TBRACCD_TAX_FUTURE_IND
                          'AUTOMATICOa',     -- TBRACCD_DATA_ORIGIN
                          'AUTOMATICOa',   -- TBRACCD_CREATE_SOURCE
                          NULL,     -- TBRACCD_CPDT_IND
                          NULL,     --TBRACCD_AIDY_CODE
                          ADEUDO.TBRACCD_STSP_KEY_SEQUENCE,  -- TBRACCD_STSP_KEY_SEQUENCE
                          ADEUDO.PARTE,                 -- TBRACCD_PERIOD
                          NULL,    --TBRACCD_SURROGATE_ID
                          NULL,     -- TBRACCD_VERSION
                          USER,     --TBRACCD_USER_ID
                          NULL );     --TBRACCD_VPDI_CODE

             END LOOP;

             EXCEPTION
             WHEN OTHERS THEN
             VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para ADEUDOidad en TBRACCD '||SQLERRM;
             END;

--             DBMS_OUTPUT.PUT_LINE('EXITO TBRACCD PRCIALIDADES VENCIDAS');

             BEGIN
               SELECT COUNT(*)
                 INTO VL_PROMOCION
                 FROM TBRACCD
                WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                      AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                      AND TBRACCD_TRAN_NUMBER_PAID = ADEUDO.SECUENCIA;
             END;

             IF VL_PROMOCION > 0 AND PN_ESTATUS NOT IN ('CC','CF') THEN

             VL_PROMOCION_MONTO:=NULL;
             VL_PROMOCION_TRAN:=NULL;
             VL_PROMOCION_VIG:=NULL;
             VL_PROMOCION_PERIODO:=NULL;


               BEGIN
                 SELECT TBRACCD_AMOUNT,TBRACCD_TRAN_NUMBER,TBRACCD_EFFECTIVE_DATE,TBRACCD_TERM_CODE
                   INTO VL_PROMOCION_MONTO,VL_PROMOCION_TRAN,VL_PROMOCION_VIG,VL_PROMOCION_PERIODO
                   FROM TBRACCD
                  WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                        AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) = 'M3'
                        AND TBRACCD_TRAN_NUMBER_PAID = ADEUDO.SECUENCIA;
               END;

               IF VL_PROMOCION_VIG <= TRUNC(SYSDATE) THEN
                   VL_PROMOCION_VIG:= TRUNC(SYSDATE);
               ELSE
                   VL_PROMOCION_VIG:=VL_PROMOCION_VIG;
               END IF;

               VL_APL_AJUSTE:= PKG_FINANZAS.SP_APLICA_AJUSTE ( ADEUDO.PIDM,
                                                               VL_PROMOCION_TRAN,
                                                               SUBSTR(ADEUDO.PERIODO,1,2)||'ON',
                                                               VL_PROMOCION_MONTO,
                                                               VL_PROMOCION_PERIODO,
                                                               'CANCELACION DE PROMOCION',
                                                               SYSDATE,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               'SZFABCC');

               BEGIN
                 UPDATE TBRACCD
                    SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
                  WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                        AND TBRACCD_DETAIL_CODE = SUBSTR(ADEUDO.PERIODO,1,2)||'ON'
                        AND TBRACCD_USER = 'SZFABCC'
                        AND TRUNC(TBRACCD_EFFECTIVE_DATE) = VL_PROMOCION_VIG;
               EXCEPTION
               WHEN OTHERS THEN
                VL_ERROR :=' Errror al actualizar saldo Saldo>>  ' || SQLERRM ;
               END;

             END IF;

             IF  ADEUDO.DESCUENTO = ADEUDO.MONTO THEN

               BEGIN
                 UPDATE TBRACCD
                    SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC'
                  WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                        AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
               END;

               BEGIN
                 UPDATE TBRACCD
                    SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC',
                        TBRACCD_TRAN_NUMBER_PAID = NULL
                  WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                        AND TBRACCD_TRAN_NUMBER = ADEUDO.SECUENCIA;
               END;

               BEGIN
                 UPDATE TBRACCD
                    SET TBRACCD_TRAN_NUMBER_PAID = NULL
                  WHERE     TBRACCD_PIDM = ADEUDO.PIDM
                        AND TBRACCD_TRAN_NUMBER_PAID = ADEUDO.SECUENCIA
                        AND (TBRACCD_CREATE_SOURCE != 'CANCELA DINA' OR TBRACCD_CREATE_SOURCE IS NULL)
                        AND TBRACCD_TRAN_NUMBER != VL_TRANSACCION;
               END;

             END IF;

           END IF;

            END LOOP ADEUDO;

       END IF;




         ---------------------------------------------------------------------------------------------------------
         --------------------------------- Proceso de Accesorios--------------------------------------------------
         ---------------------------------------------------------------------------------------------------------
         IF CF.SZVBAEC_AJUSTE_ACCE = 'S' THEN

           FOR ACCESO IN (
                          SELECT DISTINCT ZSTPARA_PARAM_VALOR CATEGORIA
                            FROM ZSTPARA
                           WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA' AND ZSTPARA_PARAM_ID = 'ACCESORIO_CARGO'
           )LOOP
             ---------------------------------------------------------------------------------------------------------
             ------------------ valida que se tenga la categoria correcta para Accesorios  ---------------------------
             ---------------------------------------------------------------------------------------------------------
             FOR CARGO IN (
                            SELECT B.TBRACCD_PIDM PIDM,
                                   B.TBRACCD_AMOUNT MONTO,
                                   B.TBRACCD_TRAN_NUMBER SECUENCIA,
                                   B.TBRACCD_DETAIL_CODE CODIGO,
                                   B.TBRACCD_AMOUNT*(CF.SZVBAEC_PORCENT_ACCE/*vp_acceso_porc*//100) DESCUENTO,
                                   SPRIDEN_ID ID,
                                   TBRACCD_STSP_KEY_SEQUENCE,
                                   TBRACCD_PERIOD, --RLS20180131
                                   TBRACCD_TERM_CODE PERIODO,
                                   TBRACCD_RECEIPT_NUMBER
                              FROM TBRACCD B, SPRIDEN
                             WHERE     B.TBRACCD_PIDM = PN_PIDM
                                   AND SUBSTR(B.TBRACCD_DETAIL_CODE,3,2) != 'QI'
                                   AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                   FROM TBBDETC
                                                                  WHERE     TBBDETC_DCAT_CODE IN ACCESO.CATEGORIA
                                                                        AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2 )  = SUBSTR (B.TBRACCD_TERM_CODE, 1, 2)
                                                                        AND TBBDETC_DETC_ACTIVE_IND = 'Y' )
                                   AND B.TBRACCD_BALANCE > 0
                                   AND TRUNC(B.TBRACCD_EFFECTIVE_DATE) >= TO_CHAR (TO_DATE(PN_FECHA_INICIO,'dd/mm/yyyy'))
                                   AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                                   AND SPRIDEN_CHANGE_IND IS NULL

             ) LOOP
               BEGIN
                 SELECT MAX(A1.TBRAPPL_PAY_TRAN_NUMBER)
                   INTO VL_NUMPAG
                   FROM TBRAPPL A1
                  WHERE      A1.TBRAPPL_PIDM = CARGO.PIDM
                         AND A1.TBRAPPL_CHG_TRAN_NUMBER =  CARGO.SECUENCIA
                         AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                           FROM TBRAPPL A
                                                          WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                                AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
               EXCEPTION
               WHEN OTHERS THEN
               VL_NUMPAG :=0;
               END;


               BEGIN
                 SELECT B.TBRACCD_DETAIL_CODE
                   INTO VL_EXISTE_DETAIL
                   FROM TBRACCD B
                  WHERE     B.TBRACCD_PIDM = CARGO.PIDM
                        AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;
               EXCEPTION
               WHEN OTHERS THEN
               VL_EXISTE_DETAIL :=0;
               END;

               BEGIN

                 IF CF.SZVBAEC_CONCEPTO_ACCE <> VL_EXISTE_DETAIL THEN

                   VL_TRANSACCION :=0;
                   VL_PERIODO := NULL;

                   BEGIN
                     SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                       INTO VL_TRANSACCION
                       FROM TBRACCD
                      WHERE TBRACCD_PIDM=CARGO.PIDM;
                   EXCEPTION
                       WHEN OTHERS THEN
                         VL_TRANSACCION:=0;
                   END;

                   BEGIN
                     SELECT FGET_PERIODO_GENERAL(SUBSTR(CARGO.ID,1,2))
                       INTO VL_PERIODO
                       FROM DUAL;
                   EXCEPTION
                   WHEN OTHERS THEN
                      VL_PERIODO := '000000';
                   END;

                   BEGIN
                      SELECT SUBSTR(CARGO.CODIGO,1,2)||ZSTPARA_PARAM_VALOR
                        INTO VL_COD_CANCELA
                        FROM ZSTPARA
                       WHERE     ZSTPARA_MAPA_ID = 'ABCC_DIFERIDO'
                             AND ZSTPARA_PARAM_ID = SUBSTR(CARGO.CODIGO,3,2);
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_COD_CANCELA:=CF.SZVBAEC_CONCEPTO_ACCE;
                   END;

                   BEGIN
                     SELECT DISTINCT TBBDETC_DESC
                       INTO VL_DESCRIPCION
                       FROM TBBDETC
                      WHERE TBBDETC_DETAIL_CODE = VL_COD_CANCELA;
                   EXCEPTION
                   WHEN OTHERS THEN
                     VL_DESCRIPCION := NULL;
                   END;

                   BEGIN
                     INSERT
                       INTO TBRACCD
                     VALUES (
                            CARGO.PIDM,   -- TBRACCD_PIDM
                            VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                            CARGO.PERIODO,    -- TBRACCD_TERM_CODE
                            VL_COD_CANCELA , ---TBRACCD_DETAIL_CODE
                            USER,     ---TBRACCD_USER
                            SYSDATE,     --TBRACCD_ENTRY_DATE
                            NVL(CARGO.DESCUENTO,0),
                            NVL(CARGO.DESCUENTO,0) * -1,    ---TBRACCD_BALANCE
                            SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                            NULL,    --TBRACCD_BILL_DATE
                            NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                            VL_DESCRIPCION,    -- TBRACCD_DESC
                            CARGO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                            CARGO.SECUENCIA,     --TBRACCD_TRAN_NUMBER_PAID
                            NULL,     --TBRACCD_CROSSREF_PIDM
                            NULL,    --TBRACCD_CROSSREF_NUMBER
                            NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                            'T',    --TBRACCD_SRCE_CODE
                            'Y',    --TBRACCD_ACCT_FEED_IND
                            SYSDATE,  --TBRACCD_ACTIVITY_DATE
                            0,        --TBRACCD_SESSION_NUMBER
                            NULL,    -- TBRACCD_CSHR_END_DATE
                            NULL,     --TBRACCD_CRN
                            NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                            NULL,     -- TBRACCD_LOC_MDT
                            NULL,     --TBRACCD_LOC_MDT_SEQ
                            NULL,     -- TBRACCD_RATE
                            NULL,     --TBRACCD_UNITS
                            NULL,     -- TBRACCD_DOCUMENT_NUMBER
                            SYSDATE,  -- TBRACCD_TRANS_DATE
                            NULL,        -- TBRACCD_PAYMENT_ID
                            NULL,     -- TBRACCD_INVOICE_NUMBER
                            NULL,     -- TBRACCD_STATEMENT_DATE
                            NULL,     -- TBRACCD_INV_NUMBER_PAID
                            'MXN',     -- TBRACCD_CURR_CODE
                            NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                            NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                            NULL,     -- TBRACCD_LATE_DCAT_CODE
                            PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                            NULL,     -- TBRACCD_FEED_DOC_CODE
                            NULL,     -- TBRACCD_ATYP_CODE
                            NULL,     -- TBRACCD_ATYP_SEQNO
                            NULL,     -- TBRACCD_CARD_TYPE_VR
                            NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                            NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                            NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                            NULL,     -- TBRACCD_ORIG_CHG_IND
                            NULL,     -- TBRACCD_CCRD_CODE
                            NULL,     -- TBRACCD_MERCHANT_ID
                            NULL,     -- TBRACCD_TAX_REPT_YEAR
                            NULL,     -- TBRACCD_TAX_REPT_BOX
                            NULL,     -- TBRACCD_TAX_AMOUNT
                            NULL,     -- TBRACCD_TAX_FUTURE_IND
                            'AUTOMATICO',     -- TBRACCD_DATA_ORIGIN
                            'AUTOMATICO',   -- TBRACCD_CREATE_SOURCE
                            NULL,     -- TBRACCD_CPDT_IND
                            NULL,     --TBRACCD_AIDY_CODE
                            NVL(CARGO.TBRACCD_STSP_KEY_SEQUENCE,PN_KEYSEQNO),    --TBRACCD_STSP_KEY_SEQUENCE
                            NVL(CARGO.TBRACCD_PERIOD,VL_PARTE),    --TBRACCD_PERIOD
                            NULL,    --TBRACCD_SURROGATE_ID
                            NULL,     -- TBRACCD_VERSION
                            USER,     --TBRACCD_USER_ID
                            NULL );     --TBRACCD_VPDI_CODE
                   EXCEPTION
                       WHEN OTHERS THEN
                         VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para Accesorios en TBRACCD '||SQLERRM;
                   END;

                   IF CARGO.DESCUENTO = CARGO.MONTO THEN

                     BEGIN
                       INSERT
                         INTO TBRAPPL
                       VALUES (
                                CARGO.PIDM,               --TBRAPPL_PIDM
                                VL_TRANSACCION,               --TBRAPPL_PAY_TRAN_NUMBER
                                CARGO.SECUENCIA,               --TBRAPPL_CHG_TRAN_NUMBER
                                CARGO.DESCUENTO,              --TBRAPPL_AMOUNT
                                NULL,             --TBRAPPL_DIRECT_PAY_IND
                                NULL,              --TBRAPPL_REAPPL_IND
                                USER,              --TBRAPPL_USER
                                'Y',              --TBRAPPL_ACCT_FEED_IND
                                SYSDATE,              --TBRAPPL_ACTIVITY_DATE
                                NULL,              --TBRAPPL_FEED_DATE
                                'Y',              --TBRAPPL_FEED_DOC_CODE
                                NULL,              --TBRAPPL_CPDT_TRAN_NUMBER
                                NULL,              --TBRAPPL_DIRECT_PAY_TYPE
                                NULL,              --TBRAPPL_INV_NUMBER_PAID
                                NULL,              --TBRAPPL_SURROGATE_ID
                                NULL,              --TBRAPPL_VERSION
                                USER,              --TBRAPPL_USER_ID
                                'AJ',              --TBRAPPL_DATA_ORIGIN
                                NULL);              --TBRAPPL_VPDI_CODE
                     EXCEPTION
                     WHEN OTHERS THEN
                     VL_TRANSACCION :=' Errror al Insertar aplicacion de pagos 1  ' || SQLERRM ;
                     END;

                     BEGIN
                       UPDATE TBRACCD
                          SET TBRACCD_BALANCE = 0
                        WHERE     TBRACCD_PIDM = CARGO.PIDM
                              AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
                     END;

                     BEGIN
                       UPDATE TBRACCD
                          SET TBRACCD_BALANCE = 0
                        WHERE     TBRACCD_PIDM = CARGO.PIDM
                              AND TBRACCD_TRAN_NUMBER = CARGO.SECUENCIA;
                     END;

                   END IF;
                 END IF;
               END;
             END LOOP CARGO;
           END LOOP ACCESO;
         END IF;
         ---------------------------------------------------------------------------------------------------------
         --------------------------------- Proceso de BECAS------ ------------------------------------------------
         ---------------------------------------------------------------------------------------------------------
         IF CF.SZVBAEC_AJUSTE_BECA = 'S' THEN

           BEGIN
             SELECT DISTINCT TBBDETC_DESC
               INTO VL_DESCRIPCION
               FROM TBBDETC
              WHERE TBBDETC_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_BECA;--??vP_acceso_code;
           EXCEPTION
           WHEN OTHERS THEN
             VL_DESCRIPCION := NULL;
           END;

           FOR DESCU IN (
                         SELECT DISTINCT ZSTPARA_PARAM_VALOR CATEGORIA
                           FROM ZSTPARA
                          WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA' AND ZSTPARA_PARAM_ID = 'BECA_CARGO'
           )LOOP
             ---------------------------------------------------------------------------------------------------------
             ------------------ valida que se tenga la categoria correcta para BECAS --------- ---------------
             ---------------------------------------------------------------------------------------------------------
             FOR CARGO IN (
                            SELECT B.TBRACCD_PIDM PIDM,
                                   B.TBRACCD_BALANCE MONTO,
                                   B.TBRACCD_TRAN_NUMBER SECUENCIA,
                                   B.TBRACCD_BALANCE*(CF.SZVBAEC_PORCENT_BECA/*vp_descuento_porc*//100) DESCUENTO,
                                   SPRIDEN_ID ID,
                                   TBRACCD_STSP_KEY_SEQUENCE,
                                   TBRACCD_PERIOD, --RLS20180131
                                   TBRACCD_TERM_CODE PERIODO,
                                   TBRACCD_RECEIPT_NUMBER
                              FROM TBRACCD B, SPRIDEN
                             WHERE     B.TBRACCD_PIDM = PN_PIDM
                                   AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                          FROM TBBDETC
                                                                          WHERE TBBDETC_DCAT_CODE = DESCU.CATEGORIA
                                                                         AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2 )  = SUBSTR (B.TBRACCD_TERM_CODE, 1, 2)
                                                                         AND TBBDETC_DETC_ACTIVE_IND = 'Y'
                                                                         AND TBBDETC_TAXT_CODE = PN_NIVEL
                                                                          )
                                   AND B.TBRACCD_BALANCE < 0
                                   AND TRUNC(B.TBRACCD_EFFECTIVE_DATE) <= TO_CHAR (TO_DATE(PN_FECHA_BAJA,'dd/mm/yyyy'))
                                   AND TRUNC(B.TBRACCD_EFFECTIVE_DATE) >= TO_CHAR (TO_DATE(PN_FECHA_INICIO,'dd/mm/yyyy'))
                                   AND B.TBRACCD_TERM_CODE = PN_PERIODO
                                   AND B.TBRACCD_TRAN_NUMBER NOT IN (SELECT TBRAPPL_PAY_TRAN_NUMBER
                                                                                               FROM TBRAPPL
                                                                                               WHERE TBRAPPL_PIDM = B.TBRACCD_PIDM
                                                                                               AND TBRAPPL_REAPPL_IND IS NULL)
                                   AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                                   AND SPRIDEN_CHANGE_IND IS NULL

             )LOOP
               BEGIN
                 SELECT MAX(A1.TBRAPPL_CHG_TRAN_NUMBER)
                   INTO VL_NUMPAG
                   FROM TBRAPPL A1
                  WHERE     A1.TBRAPPL_PIDM = CARGO.PIDM
                        AND A1.TBRAPPL_PAY_TRAN_NUMBER =  CARGO.SECUENCIA
                        AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                          FROM TBRAPPL A
                                                         WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                               AND A.TBRAPPL_PAY_TRAN_NUMBER =  A1.TBRAPPL_PAY_TRAN_NUMBER);
               EXCEPTION
               WHEN OTHERS THEN
               VL_NUMPAG :=NULL;
               END;

               BEGIN
                 SELECT B.TBRACCD_DETAIL_CODE
                   INTO VL_EXISTE_DETAIL
                   FROM TBRACCD B
                  WHERE     B.TBRACCD_PIDM = CARGO.PIDM
                        AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;
               EXCEPTION
               WHEN OTHERS THEN
               VL_EXISTE_DETAIL :=NULL;
               END;

               BEGIN

                 IF CF.SZVBAEC_CONCEPTO_BECA <> VL_EXISTE_DETAIL THEN

--                   DBMS_OUTPUT.PUT_LINE('cargo ' ||CARGO.MONTO ||'*'||CARGO.SECUENCIA ||'*'||CARGO.DESCUENTO );

                   VL_TRANSACCION :=0;
                   VL_PERIODO := NULL;

                   BEGIN
                          SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                           INTO VL_TRANSACCION
                          FROM TBRACCD
                          WHERE TBRACCD_PIDM=CARGO.PIDM;
                   EXCEPTION
                       WHEN OTHERS THEN
                         VL_TRANSACCION:=0;
                   END;

                   BEGIN
                    SELECT FGET_PERIODO_GENERAL(SUBSTR(CARGO.ID,1,2))
                           INTO VL_PERIODO
                    FROM DUAL;
                   EXCEPTION
                   WHEN OTHERS THEN
                      VL_PERIODO := '000000';
                   END;


                   BEGIN
                     INSERT
                       INTO TBRACCD
                     VALUES (
                            CARGO.PIDM,   -- TBRACCD_PIDM
                            VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                            CARGO.PERIODO,    -- TBRACCD_TERM_CODE
                            CF.SZVBAEC_CONCEPTO_BECA,--??vp_acceso_code,     ---TBRACCD_DETAIL_CODE
                            USER,     ---TBRACCD_USER
                            SYSDATE,     --TBRACCD_ENTRY_DATE
                            NVL(CARGO.DESCUENTO,0),
                            NVL(CARGO.DESCUENTO,0) * -1,    ---TBRACCD_BALANCE
                            SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                            NULL,    --TBRACCD_BILL_DATE
                            NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                            VL_DESCRIPCION,    -- TBRACCD_DESC
                            CARGO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                            CARGO.SECUENCIA,     --TBRACCD_TRAN_NUMBER_PAID
                            NULL,     --TBRACCD_CROSSREF_PIDM
                            NULL,    --TBRACCD_CROSSREF_NUMBER
                            NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                            'T',    --TBRACCD_SRCE_CODE
                            'Y',    --TBRACCD_ACCT_FEED_IND
                            SYSDATE,  --TBRACCD_ACTIVITY_DATE
                            0,        --TBRACCD_SESSION_NUMBER
                            NULL,    -- TBRACCD_CSHR_END_DATE
                            NULL,     --TBRACCD_CRN
                            NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                            NULL,     -- TBRACCD_LOC_MDT
                            NULL,     --TBRACCD_LOC_MDT_SEQ
                            NULL,     -- TBRACCD_RATE
                            NULL,     --TBRACCD_UNITS
                            NULL,     -- TBRACCD_DOCUMENT_NUMBER
                            SYSDATE,  -- TBRACCD_TRANS_DATE
                            NULL,        -- TBRACCD_PAYMENT_ID
                            NULL,     -- TBRACCD_INVOICE_NUMBER
                            NULL,     -- TBRACCD_STATEMENT_DATE
                            NULL,     -- TBRACCD_INV_NUMBER_PAID
                            'MXN',     -- TBRACCD_CURR_CODE
                            NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                            NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                            NULL,     -- TBRACCD_LATE_DCAT_CODE
                            PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                            NULL,     -- TBRACCD_FEED_DOC_CODE
                            NULL,     -- TBRACCD_ATYP_CODE
                            NULL,     -- TBRACCD_ATYP_SEQNO
                            NULL,     -- TBRACCD_CARD_TYPE_VR
                            NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                            NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                            NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                            NULL,     -- TBRACCD_ORIG_CHG_IND
                            NULL,     -- TBRACCD_CCRD_CODE
                            NULL,     -- TBRACCD_MERCHANT_ID
                            NULL,     -- TBRACCD_TAX_REPT_YEAR
                            NULL,     -- TBRACCD_TAX_REPT_BOX
                            NULL,     -- TBRACCD_TAX_AMOUNT
                            NULL,     -- TBRACCD_TAX_FUTURE_IND
                            'AUTOMATICO',     -- TBRACCD_DATA_ORIGIN
                            'AUTOMATICO',   -- TBRACCD_CREATE_SOURCE
                            NULL,     -- TBRACCD_CPDT_IND
                            NULL,     --TBRACCD_AIDY_CODE
                            NVL(CARGO.TBRACCD_STSP_KEY_SEQUENCE, PN_KEYSEQNO),   --TBRACCD_STSP_KEY_SEQUENCE
                            NVL (CARGO.TBRACCD_PERIOD, VL_PARTE),    --TBRACCD_PERIOD
                            NULL,    --TBRACCD_SURROGATE_ID
                            NULL,     -- TBRACCD_VERSION
                            USER,     --TBRACCD_USER_ID
                            NULL );     --TBRACCD_VPDI_CODE
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para BECAS en TBRACCD '||SQLERRM;
                   END;

                 END IF;
               END;
             END LOOP CARGO;
           END LOOP DESCU;
         END IF;
         ---------------------------------------------------------------------------------------------------------
         --------------------------------- Proceso de Descuentos -------------------------------------------------
         ---------------------------------------------------------------------------------------------------------
         IF CF.SZVBAEC_AJUSTE_DESCTO = 'S' THEN

           BEGIN
             SELECT DISTINCT TBBDETC_DESC
               INTO VL_DESCRIPCION
               FROM TBBDETC
              WHERE TBBDETC_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_DESCTO;
           EXCEPTION
           WHEN OTHERS THEN
           VL_DESCRIPCION := NULL;
           END;

           FOR DESCU IN (
                         SELECT DISTINCT ZSTPARA_PARAM_VALOR CATEGORIA
                           FROM ZSTPARA
                          WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA' AND ZSTPARA_PARAM_ID = 'DESCUENTO_CARGO'
           )LOOP
             ---------------------------------------------------------------------------------------------------------
             ------------------ valida que se tenga la categoria correcta para Descuentos  ---------------------------
             ---------------------------------------------------------------------------------------------------------
             FOR CARGO IN (
                          SELECT B.TBRACCD_PIDM PIDM,
                                 B.TBRACCD_AMOUNT MONTO,
                                 B.TBRACCD_TRAN_NUMBER SECUENCIA,
                                 B.TBRACCD_AMOUNT*(CF.SZVBAEC_PORCENT_DESCTO/*vp_descuento_porc*//100) DESCUENTO,
                                 SPRIDEN_ID ID,
                                 TBRACCD_STSP_KEY_SEQUENCE,
                                 TBRACCD_PERIOD, --RLS20180131
                                 TBRACCD_TERM_CODE PERIODO,
                                 TBRACCD_RECEIPT_NUMBER
                            FROM TBRACCD B, SPRIDEN
                           WHERE     B.TBRACCD_PIDM = PN_PIDM
                                 AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                 FROM TBBDETC
                                                                WHERE     TBBDETC_DCAT_CODE IN DESCU.CATEGORIA
                                                                      AND SUBSTR (TBBDETC_DETAIL_CODE,1,2) = SUBSTR (B.TBRACCD_TERM_CODE,1,2)
                                                                      AND TBBDETC_DETC_ACTIVE_IND = 'Y')
                                 AND B.TBRACCD_TERM_CODE = PN_PERIODO
                                 AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                                 AND SPRIDEN_CHANGE_IND IS NULL

             )LOOP

               BEGIN
                 SELECT MAX(A1.TBRAPPL_CHG_TRAN_NUMBER)
                   INTO VL_NUMPAG
                   FROM TBRAPPL A1
                  WHERE     A1.TBRAPPL_PIDM = CARGO.PIDM
                        AND A1.TBRAPPL_PAY_TRAN_NUMBER =  CARGO.SECUENCIA
                        AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                          FROM TBRAPPL A
                                                         WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                               AND A.TBRAPPL_PAY_TRAN_NUMBER =  A1.TBRAPPL_PAY_TRAN_NUMBER);
               EXCEPTION
               WHEN OTHERS THEN
               VL_NUMPAG :=NULL;
               END;

               BEGIN
                 SELECT B.TBRACCD_DETAIL_CODE
                   INTO VL_EXISTE_DETAIL
                   FROM TBRACCD B
                  WHERE     B.TBRACCD_PIDM = PN_PIDM
                        AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;
               EXCEPTION
               WHEN OTHERS THEN
               VL_EXISTE_DETAIL :=NULL;
               END;

               BEGIN

                 IF CF.SZVBAEC_CONCEPTO_DESCTO <> VL_EXISTE_DETAIL THEN

                   VL_TRANSACCION :=0;
                   VL_PERIODO := NULL;

                   BEGIN
                          SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                           INTO VL_TRANSACCION
                          FROM TBRACCD
                          WHERE TBRACCD_PIDM=CARGO.PIDM;
                   EXCEPTION
                       WHEN OTHERS THEN
                         VL_TRANSACCION:=0;
                   END;

                   BEGIN
                    SELECT FGET_PERIODO_GENERAL(SUBSTR(CARGO.ID,1,2))
                           INTO VL_PERIODO
                    FROM DUAL;
                   EXCEPTION
                   WHEN OTHERS THEN
                      VL_PERIODO := '000000';
                   END;


                   BEGIN
                     INSERT
                       INTO TBRACCD
                     VALUES (
                            CARGO.PIDM,   -- TBRACCD_PIDM
                            VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                            CARGO.PERIODO,    -- TBRACCD_TERM_CODE
                            CF.SZVBAEC_CONCEPTO_DESCTO,--??vp_acceso_code,     ---TBRACCD_DETAIL_CODE
                            USER,     ---TBRACCD_USER
                            SYSDATE,     --TBRACCD_ENTRY_DATE
                            NVL(CARGO.DESCUENTO,0),
                            NVL(CARGO.DESCUENTO,0),    ---TBRACCD_BALANCE
                            SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                            NULL,    --TBRACCD_BILL_DATE
                            NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                            VL_DESCRIPCION,    -- TBRACCD_DESC
                            CARGO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                            CARGO.SECUENCIA,     --TBRACCD_TRAN_NUMBER_PAID
                            NULL,     --TBRACCD_CROSSREF_PIDM
                            NULL,    --TBRACCD_CROSSREF_NUMBER
                            NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                            'T',    --TBRACCD_SRCE_CODE
                            'Y',    --TBRACCD_ACCT_FEED_IND
                            SYSDATE,  --TBRACCD_ACTIVITY_DATE
                            0,        --TBRACCD_SESSION_NUMBER
                            NULL,    -- TBRACCD_CSHR_END_DATE
                            NULL,     --TBRACCD_CRN
                            NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                            NULL,     -- TBRACCD_LOC_MDT
                            NULL,     --TBRACCD_LOC_MDT_SEQ
                            NULL,     -- TBRACCD_RATE
                            NULL,     --TBRACCD_UNITS
                            NULL,     -- TBRACCD_DOCUMENT_NUMBER
                            SYSDATE,  -- TBRACCD_TRANS_DATE
                            NULL,        -- TBRACCD_PAYMENT_ID
                            NULL,     -- TBRACCD_INVOICE_NUMBER
                            NULL,     -- TBRACCD_STATEMENT_DATE
                            NULL,     -- TBRACCD_INV_NUMBER_PAID
                            'MXN',     -- TBRACCD_CURR_CODE
                            NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                            NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                            NULL,     -- TBRACCD_LATE_DCAT_CODE
                            PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                            NULL,     -- TBRACCD_FEED_DOC_CODE
                            NULL,     -- TBRACCD_ATYP_CODE
                            NULL,     -- TBRACCD_ATYP_SEQNO
                            NULL,     -- TBRACCD_CARD_TYPE_VR
                            NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                            NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                            NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                            NULL,     -- TBRACCD_ORIG_CHG_IND
                            NULL,     -- TBRACCD_CCRD_CODE
                            NULL,     -- TBRACCD_MERCHANT_ID
                            NULL,     -- TBRACCD_TAX_REPT_YEAR
                            NULL,     -- TBRACCD_TAX_REPT_BOX
                            NULL,     -- TBRACCD_TAX_AMOUNT
                            NULL,     -- TBRACCD_TAX_FUTURE_IND
                            'AUTOMATICO',     -- TBRACCD_DATA_ORIGIN
                            'AUTOMATICO',   -- TBRACCD_CREATE_SOURCE
                            NULL,     -- TBRACCD_CPDT_IND
                            NULL,     --TBRACCD_AIDY_CODE
                            NVL( CARGO.TBRACCD_STSP_KEY_SEQUENCE ,PN_KEYSEQNO),     --TBRACCD_STSP_KEY_SEQUENCE
                            NVL(CARGO.TBRACCD_PERIOD , VL_PARTE),    --TBRACCD_PERIOD
                            NULL,    --TBRACCD_SURROGATE_ID
                            NULL,     -- TBRACCD_VERSION
                            USER,     --TBRACCD_USER_ID
                            NULL );     --TBRACCD_VPDI_CODE
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para Descuento en TBRACCD '||SQLERRM;
                   END;

                   IF  CARGO.DESCUENTO = CARGO.MONTO THEN

                     BEGIN
                       INSERT
                         INTO TBRAPPL
                       VALUES (
                                CARGO.PIDM,               --TBRAPPL_PIDM
                                CARGO.SECUENCIA,               --TBRAPPL_PAY_TRAN_NUMBER
                                VL_TRANSACCION,               --TBRAPPL_CHG_TRAN_NUMBER
                                CARGO.DESCUENTO,              --TBRAPPL_AMOUNT
                                'Y',             --TBRAPPL_DIRECT_PAY_IND
                                NULL,              --TBRAPPL_REAPPL_IND
                                USER,              --TBRAPPL_USER
                                'Y',              --TBRAPPL_ACCT_FEED_IND
                                SYSDATE,              --TBRAPPL_ACTIVITY_DATE
                                NULL,              --TBRAPPL_FEED_DATE
                                NULL,              --TBRAPPL_FEED_DOC_CODE
                                NULL,              --TBRAPPL_CPDT_TRAN_NUMBER
                                'T',              --TBRAPPL_DIRECT_PAY_TYPE
                                NULL,              --TBRAPPL_INV_NUMBER_PAID
                                NULL,              --TBRAPPL_SURROGATE_ID
                                NULL,              --TBRAPPL_VERSION
                                USER,              --TBRAPPL_USER_ID
                                'AJ',              --TBRAPPL_DATA_ORIGIN
                                NULL);              --TBRAPPL_VPDI_CODE
                     EXCEPTION
                     WHEN OTHERS THEN
                     VL_TRANSACCION :=' Errror al Insertar aplicacion de pagos 1  ' || SQLERRM ;
                     END;

                     BEGIN
                       UPDATE TBRACCD
                          SET TBRACCD_BALANCE = 0
                        WHERE     TBRACCD_PIDM = CARGO.PIDM
                              AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
                     END;

                     BEGIN
                       UPDATE TBRACCD
                          SET TBRACCD_BALANCE = 0,TBRACCD_TRAN_NUMBER_PAID = VL_TRANSACCION
                        WHERE     TBRACCD_PIDM = CARGO.PIDM
                              AND TBRACCD_TRAN_NUMBER = CARGO.SECUENCIA;
                     END;

                   END IF;
                 END IF;
               END;
             END LOOP CARGO;
           END LOOP DESCU;

           BEGIN
            UPDATE TBBESTU A
               SET A.TBBESTU_DEL_IND = 'D',
                   A.TBBESTU_STUDENT_EXPT_ROLL_IND = 'N'
             WHERE     A.TBBESTU_PIDM = PN_PIDM
                   AND A.TBBESTU_EXEMPTION_CODE IN (SELECT MAX (A1.TBBESTU_EXEMPTION_CODE)
                                                      FROM TBBESTU A1
                                                     WHERE A.TBBESTU_PIDM = A1.TBBESTU_PIDM)
                   AND TBBESTU_DEL_IND IS NULL;
           EXCEPTION
           WHEN OTHERS THEN
              VL_ERROR := 'Se presento el error al actualizar el descuento' || SQLERRM;

           END;

         END IF;
         ---------------------------------------------------------------------------------------------------------
         --------------------------------- Proceso INTERESES------------------------------------------------------
         ---------------------------------------------------------------------------------------------------------
--         DBMS_OUTPUT.PUT_LINE('VALIDACION_1 = '||PN_ESTATUS);
--         DBMS_OUTPUT.PUT_LINE('VALIDACION_2 = '||PN_FECHA_BAJA);
--         DBMS_OUTPUT.PUT_LINE('VALIDACION_3 = '||PN_FECHA_FIN);
--         DBMS_OUTPUT.PUT_LINE('VALIDACION_4 = '||PN_FECHA_INICIO);
--         DBMS_OUTPUT.PUT_LINE('VALIDACION_4 = '||DESCU.CATEGORIA);

         IF CF.SZVBAEC_AJUSTE_INTERES = 'S' AND PN_ESTATUS != 'BA' THEN
--         DBMS_OUTPUT.PUT_LINE('ENTRA AL PRIMER IF_5 = ');
           BEGIN
             SELECT DISTINCT TBBDETC_DESC
               INTO VL_DESCRIPCION
               FROM TBBDETC
              WHERE TBBDETC_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_INTERES;--??vP_acceso_code;
           EXCEPTION
           WHEN OTHERS THEN
           VL_DESCRIPCION := NULL;
           END;

           FOR DESCU IN (
                         SELECT DISTINCT ZSTPARA_PARAM_VALOR CATEGORIA
                           FROM ZSTPARA
                          WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA' AND ZSTPARA_PARAM_ID = 'INTERES_CARGO'
           )LOOP
                ---------------------------------------------------------------------------------------------------------
                ------------------ valida que se tenga la categoria correcta para INTERES  ------------------------------
                ---------------------------------------------------------------------------------------------------------
             FOR CARGO IN (
                         SELECT  B.TBRACCD_PIDM PIDM,
                                 B.TBRACCD_AMOUNT MONTO,
                                 B.TBRACCD_TRAN_NUMBER SECUENCIA,
                                 B.TBRACCD_AMOUNT*(CF.SZVBAEC_PORCENT_INTERES/*vp_descuento_porc*//100) DESCUENTO,
                                 SPRIDEN_ID ID,
                                 TBRACCD_STSP_KEY_SEQUENCE ,
                                 TBRACCD_PERIOD, --RLS20180131
                                 TBRACCD_TERM_CODE PERIODO,
                                 TBRACCD_RECEIPT_NUMBER
                           FROM TBRACCD B, SPRIDEN
                          WHERE     B.TBRACCD_PIDM = PN_PIDM
                                AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                FROM TBBDETC
                                                               WHERE TBBDETC_DCAT_CODE = DESCU.CATEGORIA
                                                                     AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2 )  = SUBSTR (B.TBRACCD_TERM_CODE, 1, 2)
                                                                     AND TBBDETC_DETC_ACTIVE_IND = 'Y')
                                AND TO_CHAR(TRUNC(B.TBRACCD_EFFECTIVE_DATE),'MM/YY') <= TO_CHAR(TO_DATE(PN_FECHA_BAJA,'DD/MM/YY'),'MM/YY')
                                AND TRUNC(B.TBRACCD_EFFECTIVE_DATE) >= TO_CHAR (TO_DATE(PN_FECHA_INICIO,'dd/mm/yy'))
                                AND B.TBRACCD_EFFECTIVE_DATE IN (SELECT(B1.TBRACCD_EFFECTIVE_DATE)
                                                                   FROM TBRACCD B1
                                                                  WHERE     TRUNC(B.TBRACCD_EFFECTIVE_DATE) >= TO_CHAR (TO_DATE(PN_FECHA_INICIO,'dd/mm/yy'))
                                                                        AND TO_CHAR(TRUNC(B.TBRACCD_EFFECTIVE_DATE),'MM/YY') <= TO_CHAR(TO_DATE(PN_FECHA_FIN,'DD/MM/YY'),'MM/YY'))
                                AND B.TBRACCD_TRAN_NUMBER NOT IN (SELECT TBRAPPL_PAY_TRAN_NUMBER
                                                                    FROM TBRAPPL
                                                                   WHERE     TBRAPPL_PIDM = B.TBRACCD_PIDM
                                                                         AND TBRAPPL_REAPPL_IND IS NULL)
                                AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                                AND SPRIDEN_CHANGE_IND IS NULL
                          ORDER BY B.TBRACCD_TRAN_NUMBER

             )LOOP

               BEGIN
                 SELECT MAX(A1.TBRAPPL_PAY_TRAN_NUMBER)
                   INTO VL_NUMPAG
                   FROM TBRAPPL A1
                  WHERE     A1.TBRAPPL_PIDM = PN_PIDM
                        AND A1.TBRAPPL_CHG_TRAN_NUMBER =  CARGO.SECUENCIA
                        AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                          FROM TBRAPPL A
                                                         WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                               AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
               EXCEPTION
               WHEN OTHERS THEN
               VL_NUMPAG :=0;
               END;

               BEGIN
                 SELECT B.TBRACCD_DETAIL_CODE
                   INTO VL_EXISTE_DETAIL
                   FROM TBRACCD B
                  WHERE     B.TBRACCD_PIDM = PN_PIDM
                        AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;
               EXCEPTION
               WHEN OTHERS THEN
               VL_EXISTE_DETAIL :=0;
               END;

               BEGIN

                 IF CF.SZVBAEC_CONCEPTO_INTERES <> VL_EXISTE_DETAIL THEN

                   VL_TRANSACCION :=0;
                   VL_PERIODO := NULL;

                   BEGIN
                     SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                       INTO VL_TRANSACCION
                       FROM TBRACCD
                      WHERE TBRACCD_PIDM=CARGO.PIDM;
                   EXCEPTION
                       WHEN OTHERS THEN
                         VL_TRANSACCION:=0;
                   END;

                   BEGIN
                     SELECT FGET_PERIODO_GENERAL(SUBSTR(CARGO.ID,1,2))
                       INTO VL_PERIODO
                       FROM DUAL;
                   EXCEPTION
                   WHEN OTHERS THEN
                      VL_PERIODO := '000000';
                   END;

                   PKG_FINANZAS.P_DESAPLICA_PAGOS (CARGO.PIDM, CARGO.SECUENCIA) ;

                    BEGIN
                       INSERT
                         INTO TBRACCD
                       VALUES (
                                CARGO.PIDM,   -- TBRACCD_PIDM
                                VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                                CARGO.PERIODO,    -- TBRACCD_TERM_CODE
                                CF.SZVBAEC_CONCEPTO_INTERES,--??vp_acceso_code,     ---TBRACCD_DETAIL_CODE
                                USER,     ---TBRACCD_USER
                                SYSDATE,     --TBRACCD_ENTRY_DATE
                                NVL(CARGO.DESCUENTO,0),
                                NVL(CARGO.DESCUENTO,0) * -1,    ---TBRACCD_BALANCE
                                SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                                NULL,    --TBRACCD_BILL_DATE
                                NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                VL_DESCRIPCION,    -- TBRACCD_DESC
                                CARGO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                                CARGO.SECUENCIA,     --TBRACCD_TRAN_NUMBER_PAID
                                NULL,     --TBRACCD_CROSSREF_PIDM
                                NULL,    --TBRACCD_CROSSREF_NUMBER
                                NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                'T',    --TBRACCD_SRCE_CODE
                                'Y',    --TBRACCD_ACCT_FEED_IND
                                SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                0,        --TBRACCD_SESSION_NUMBER
                                NULL,    -- TBRACCD_CSHR_END_DATE
                                NULL,     --TBRACCD_CRN
                                NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                NULL,     -- TBRACCD_LOC_MDT
                                NULL,     --TBRACCD_LOC_MDT_SEQ
                                NULL,     -- TBRACCD_RATE
                                NULL,     --TBRACCD_UNITS
                                NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                SYSDATE,  -- TBRACCD_TRANS_DATE
                                NULL,        -- TBRACCD_PAYMENT_ID
                                NULL,     -- TBRACCD_INVOICE_NUMBER
                                NULL,     -- TBRACCD_STATEMENT_DATE
                                NULL,     -- TBRACCD_INV_NUMBER_PAID
                                'MXN',     -- TBRACCD_CURR_CODE
                                NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                NULL,     -- TBRACCD_LATE_DCAT_CODE
                                PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                                NULL,     -- TBRACCD_FEED_DOC_CODE
                                NULL,     -- TBRACCD_ATYP_CODE
                                NULL,     -- TBRACCD_ATYP_SEQNO
                                NULL,     -- TBRACCD_CARD_TYPE_VR
                                NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                NULL,     -- TBRACCD_ORIG_CHG_IND
                                NULL,     -- TBRACCD_CCRD_CODE
                                NULL,     -- TBRACCD_MERCHANT_ID
                                NULL,     -- TBRACCD_TAX_REPT_YEAR
                                NULL,     -- TBRACCD_TAX_REPT_BOX
                                NULL,     -- TBRACCD_TAX_AMOUNT
                                NULL,     -- TBRACCD_TAX_FUTURE_IND
                                'AUTOMATICO',     -- TBRACCD_DATA_ORIGIN
                                'AUTOMATICO',   -- TBRACCD_CREATE_SOURCE
                                NULL,     -- TBRACCD_CPDT_IND
                                NULL,     --TBRACCD_AIDY_CODE
                                NVL (CARGO.TBRACCD_STSP_KEY_SEQUENCE,PN_KEYSEQNO) ,     --TBRACCD_STSP_KEY_SEQUENCE
                                NVL (CARGO.TBRACCD_PERIOD ,VL_PARTE),     --TBRACCD_PERIOD
                                NULL,    --TBRACCD_SURROGATE_ID
                                NULL,     -- TBRACCD_VERSION
                                USER,     --TBRACCD_USER_ID
                                NULL );     --TBRACCD_VPDI_CODE
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para INTERESES en TBRACCD '||SQLERRM;
                   END;


                   IF  CARGO.DESCUENTO = CARGO.MONTO THEN

                     BEGIN
                       INSERT
                         INTO TBRAPPL
                       VALUES (
                                CARGO.PIDM,               --TBRAPPL_PIDM
                                VL_TRANSACCION,               --TBRAPPL_PAY_TRAN_NUMBER
                                CARGO.SECUENCIA,               --TBRAPPL_CHG_TRAN_NUMBER
                                CARGO.DESCUENTO,              --TBRAPPL_AMOUNT
                                NULL,             --TBRAPPL_DIRECT_PAY_IND
                                NULL,              --TBRAPPL_REAPPL_IND
                                USER,              --TBRAPPL_USER
                                'Y',              --TBRAPPL_ACCT_FEED_IND
                                SYSDATE,              --TBRAPPL_ACTIVITY_DATE
                                NULL,              --TBRAPPL_FEED_DATE
                                'Y',              --TBRAPPL_FEED_DOC_CODE
                                NULL,              --TBRAPPL_CPDT_TRAN_NUMBER
                                NULL,              --TBRAPPL_DIRECT_PAY_TYPE
                                NULL,              --TBRAPPL_INV_NUMBER_PAID
                                NULL,              --TBRAPPL_SURROGATE_ID
                                NULL,              --TBRAPPL_VERSION
                                USER,              --TBRAPPL_USER_ID
                                'AJ',              --TBRAPPL_DATA_ORIGIN
                                NULL);              --TBRAPPL_VPDI_CODE
                     EXCEPTION
                     WHEN OTHERS THEN
                       VL_TRANSACCION :=' Errror al Insertar aplicacion de pagos 1  ' || SQLERRM ;
                     END;

                     BEGIN
                       UPDATE TBRACCD
                          SET TBRACCD_BALANCE = 0
                        WHERE     TBRACCD_PIDM = CARGO.PIDM
                              AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
                     END;

                     BEGIN
                       UPDATE TBRACCD
                          SET TBRACCD_BALANCE = 0
                        WHERE     TBRACCD_PIDM = CARGO.PIDM
                              AND TBRACCD_TRAN_NUMBER = CARGO.SECUENCIA;
                     END;

                   END IF;
                 END IF;
               END;
             END LOOP CARGO;
           END LOOP DESCU;

         ELSIF CF.SZVBAEC_AJUSTE_INTERES = 'S' AND PN_ESTATUS = 'BA' THEN
--         DBMS_OUTPUT.PUT_LINE('ENTRA AL SEGUNDO IF_6 = ');
           BEGIN
               SELECT DISTINCT TBBDETC_DESC
                 INTO VL_DESCRIPCION
                 FROM TBBDETC
                WHERE TBBDETC_DETAIL_CODE = CF.SZVBAEC_CONCEPTO_INTERES;--??vP_acceso_code;
           EXCEPTION
           WHEN OTHERS THEN
           VL_DESCRIPCION := NULL;
           END;

               FOR DESCU IN (
                             SELECT DISTINCT ZSTPARA_PARAM_VALOR CATEGORIA
                               FROM ZSTPARA
                              WHERE ZSTPARA_MAPA_ID = 'CONFIGURA_BAJA' AND ZSTPARA_PARAM_ID = 'INTERES_CARGO'
           )LOOP
                ---------------------------------------------------------------------------------------------------------
                ------------------ valida que se tenga la categoria correcta para INTERES  ------------------------------
                ---------------------------------------------------------------------------------------------------------
             FOR CARGO IN (
                         SELECT  B.TBRACCD_PIDM PIDM,
                                 B.TBRACCD_AMOUNT MONTO,
                                 B.TBRACCD_TRAN_NUMBER SECUENCIA,
                                 B.TBRACCD_AMOUNT*(CF.SZVBAEC_PORCENT_INTERES/*vp_descuento_porc*//100) DESCUENTO,
                                 SPRIDEN_ID ID,
                                 TBRACCD_STSP_KEY_SEQUENCE ,
                                 TBRACCD_PERIOD, --RLS20180131
                                 TBRACCD_TERM_CODE PERIODO,
                                 TBRACCD_RECEIPT_NUMBER
                           FROM TBRACCD B, SPRIDEN
                          WHERE     B.TBRACCD_PIDM = PN_PIDM
                                AND B.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                FROM TBBDETC
                                                               WHERE TBBDETC_DCAT_CODE = DESCU.CATEGORIA
                                                                     AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2 )  = SUBSTR (B.TBRACCD_TERM_CODE, 1, 2)
                                                                     AND TBBDETC_DETC_ACTIVE_IND = 'Y')
                                AND TO_CHAR(TRUNC(B.TBRACCD_EFFECTIVE_DATE),'MM/YY') >= TO_CHAR(TO_DATE(PN_FECHA_FIN,'DD/MM/YY'),'MM/YY')
                                AND TRUNC(B.TBRACCD_EFFECTIVE_DATE) >= TO_CHAR (TO_DATE(PN_FECHA_INICIO,'dd/mm/yy'))
--                                AND B.TBRACCD_EFFECTIVE_DATE IN (SELECT(B1.TBRACCD_EFFECTIVE_DATE)
--                                                                   FROM TBRACCD B1
--                                                                  WHERE     TRUNC(B.TBRACCD_EFFECTIVE_DATE) >= TO_CHAR (TO_DATE(PN_FECHA_INICIO,'dd/mm/yy'))
--                                                                        AND TO_CHAR(TRUNC(B.TBRACCD_EFFECTIVE_DATE),'MM/YY') <= TO_CHAR(TO_DATE(PN_FECHA_FIN,'DD/MM/YY'),'MM/YY'))
                                AND B.TBRACCD_TRAN_NUMBER NOT IN (SELECT TBRAPPL_PAY_TRAN_NUMBER
                                                                    FROM TBRAPPL
                                                                   WHERE     TBRAPPL_PIDM = B.TBRACCD_PIDM
                                                                         AND TBRAPPL_REAPPL_IND IS NULL)
                                AND B.TBRACCD_PIDM = SPRIDEN_PIDM
                                AND SPRIDEN_CHANGE_IND IS NULL
                          ORDER BY B.TBRACCD_TRAN_NUMBER

             )LOOP

               BEGIN
                 SELECT MAX(A1.TBRAPPL_PAY_TRAN_NUMBER)
                   INTO VL_NUMPAG
                   FROM TBRAPPL A1
                  WHERE     A1.TBRAPPL_PIDM = PN_PIDM
                        AND A1.TBRAPPL_CHG_TRAN_NUMBER =  CARGO.SECUENCIA
                        AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                          FROM TBRAPPL A
                                                         WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                               AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
               EXCEPTION
               WHEN OTHERS THEN
               VL_NUMPAG :=0;
               END;

               BEGIN
                 SELECT B.TBRACCD_DETAIL_CODE
                   INTO VL_EXISTE_DETAIL
                   FROM TBRACCD B
                  WHERE     B.TBRACCD_PIDM = PN_PIDM
                        AND B.TBRACCD_TRAN_NUMBER = VL_NUMPAG;
               EXCEPTION
               WHEN OTHERS THEN
               VL_EXISTE_DETAIL :=0;
               END;

               BEGIN

                 IF CF.SZVBAEC_CONCEPTO_INTERES <> VL_EXISTE_DETAIL THEN

                   VL_TRANSACCION :=0;
                   VL_PERIODO := NULL;

                   BEGIN
                     SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                       INTO VL_TRANSACCION
                       FROM TBRACCD
                      WHERE TBRACCD_PIDM=CARGO.PIDM;
                   EXCEPTION
                       WHEN OTHERS THEN
                         VL_TRANSACCION:=0;
                   END;

                   BEGIN
                     SELECT FGET_PERIODO_GENERAL(SUBSTR(CARGO.ID,1,2))
                       INTO VL_PERIODO
                       FROM DUAL;
                   EXCEPTION
                   WHEN OTHERS THEN
                      VL_PERIODO := '000000';
                   END;

                   PKG_FINANZAS.P_DESAPLICA_PAGOS (CARGO.PIDM, CARGO.SECUENCIA) ;

                    BEGIN
                       INSERT
                         INTO TBRACCD
                       VALUES (
                                CARGO.PIDM,   -- TBRACCD_PIDM
                                VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                                CARGO.PERIODO,    -- TBRACCD_TERM_CODE
                                CF.SZVBAEC_CONCEPTO_INTERES,--??vp_acceso_code,     ---TBRACCD_DETAIL_CODE
                                USER,     ---TBRACCD_USER
                                SYSDATE,     --TBRACCD_ENTRY_DATE
                                NVL(CARGO.DESCUENTO,0),
                                NVL(CARGO.DESCUENTO,0) * -1,    ---TBRACCD_BALANCE
                                SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                                NULL,    --TBRACCD_BILL_DATE
                                NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                VL_DESCRIPCION,    -- TBRACCD_DESC
                                CARGO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                                CARGO.SECUENCIA,     --TBRACCD_TRAN_NUMBER_PAID
                                NULL,     --TBRACCD_CROSSREF_PIDM
                                NULL,    --TBRACCD_CROSSREF_NUMBER
                                NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                'T',    --TBRACCD_SRCE_CODE
                                'Y',    --TBRACCD_ACCT_FEED_IND
                                SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                0,        --TBRACCD_SESSION_NUMBER
                                NULL,    -- TBRACCD_CSHR_END_DATE
                                NULL,     --TBRACCD_CRN
                                NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                NULL,     -- TBRACCD_LOC_MDT
                                NULL,     --TBRACCD_LOC_MDT_SEQ
                                NULL,     -- TBRACCD_RATE
                                NULL,     --TBRACCD_UNITS
                                NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                SYSDATE,  -- TBRACCD_TRANS_DATE
                                NULL,        -- TBRACCD_PAYMENT_ID
                                NULL,     -- TBRACCD_INVOICE_NUMBER
                                NULL,     -- TBRACCD_STATEMENT_DATE
                                NULL,     -- TBRACCD_INV_NUMBER_PAID
                                'MXN',     -- TBRACCD_CURR_CODE
                                NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                NULL,     -- TBRACCD_LATE_DCAT_CODE
                                PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                                NULL,     -- TBRACCD_FEED_DOC_CODE
                                NULL,     -- TBRACCD_ATYP_CODE
                                NULL,     -- TBRACCD_ATYP_SEQNO
                                NULL,     -- TBRACCD_CARD_TYPE_VR
                                NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                NULL,     -- TBRACCD_ORIG_CHG_IND
                                NULL,     -- TBRACCD_CCRD_CODE
                                NULL,     -- TBRACCD_MERCHANT_ID
                                NULL,     -- TBRACCD_TAX_REPT_YEAR
                                NULL,     -- TBRACCD_TAX_REPT_BOX
                                NULL,     -- TBRACCD_TAX_AMOUNT
                                NULL,     -- TBRACCD_TAX_FUTURE_IND
                                'AUTOMATICO',     -- TBRACCD_DATA_ORIGIN
                                'AUTOMATICO',   -- TBRACCD_CREATE_SOURCE
                                NULL,     -- TBRACCD_CPDT_IND
                                NULL,     --TBRACCD_AIDY_CODE
                                NVL (CARGO.TBRACCD_STSP_KEY_SEQUENCE,PN_KEYSEQNO) ,     --TBRACCD_STSP_KEY_SEQUENCE
                                NVL (CARGO.TBRACCD_PERIOD ,VL_PARTE),     --TBRACCD_PERIOD
                                NULL,    --TBRACCD_SURROGATE_ID
                                NULL,     -- TBRACCD_VERSION
                                USER,     --TBRACCD_USER_ID
                                NULL );     --TBRACCD_VPDI_CODE
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_ERROR := 'Se presento el siguiente error al momento de insertar ajuste para INTERESES en TBRACCD '||SQLERRM;
                   END;


                   IF  CARGO.DESCUENTO = CARGO.MONTO THEN

                     BEGIN
                       INSERT
                         INTO TBRAPPL
                       VALUES (
                                CARGO.PIDM,               --TBRAPPL_PIDM
                                VL_TRANSACCION,               --TBRAPPL_PAY_TRAN_NUMBER
                                CARGO.SECUENCIA,               --TBRAPPL_CHG_TRAN_NUMBER
                                CARGO.DESCUENTO,              --TBRAPPL_AMOUNT
                                NULL,             --TBRAPPL_DIRECT_PAY_IND
                                NULL,              --TBRAPPL_REAPPL_IND
                                USER,              --TBRAPPL_USER
                                'Y',              --TBRAPPL_ACCT_FEED_IND
                                SYSDATE,              --TBRAPPL_ACTIVITY_DATE
                                NULL,              --TBRAPPL_FEED_DATE
                                'Y',              --TBRAPPL_FEED_DOC_CODE
                                NULL,              --TBRAPPL_CPDT_TRAN_NUMBER
                                NULL,              --TBRAPPL_DIRECT_PAY_TYPE
                                NULL,              --TBRAPPL_INV_NUMBER_PAID
                                NULL,              --TBRAPPL_SURROGATE_ID
                                NULL,              --TBRAPPL_VERSION
                                USER,              --TBRAPPL_USER_ID
                                'AJ',              --TBRAPPL_DATA_ORIGIN
                                NULL);              --TBRAPPL_VPDI_CODE
                     EXCEPTION
                     WHEN OTHERS THEN
                       VL_TRANSACCION :=' Errror al Insertar aplicacion de pagos 1  ' || SQLERRM ;
                     END;

                     BEGIN
                       UPDATE TBRACCD
                          SET TBRACCD_BALANCE = 0
                        WHERE     TBRACCD_PIDM = CARGO.PIDM
                              AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
                     END;

                     BEGIN
                       UPDATE TBRACCD
                          SET TBRACCD_BALANCE = 0
                        WHERE     TBRACCD_PIDM = CARGO.PIDM
                              AND TBRACCD_TRAN_NUMBER = CARGO.SECUENCIA;
                     END;

                   END IF;
                 END IF;
               END;
             END LOOP CARGO;
           END LOOP DESCU;
         END IF;

--         DBMS_OUTPUT.PUT_LINE('pn_estatus  INICIO---'||PN_ESTATUS );

         IF PN_ESTATUS IN ('CC','CF') THEN

           BEGIN
             SELECT COUNT (*)
               INTO VL_ENTRA
               FROM TBRACCD A
              WHERE     A.TBRACCD_PIDM = PN_PIDM
             And a.tbraccd_amount > 0
                    AND SUBSTR (A.TBRACCD_DETAIL_CODE ,3,4 ) IN (SELECT(ZSTPARA_PARAM_ID)
                                                                    FROM ZSTPARA
                                                                   WHERE ZSTPARA_MAPA_ID = 'CANC_CAMCFV');
                    -- AND A.TBRACCD_DOCUMENT_NUMBER IS NULL; ---> Se apaga para cancelar todos los accesorios que estan en este rubro 
           EXCEPTION
           WHEN OTHERS THEN
           VL_ENTRA:=0;
           END;

           IF VL_ENTRA > 0 THEN

             FOR ALUMNO IN (

                           SELECT  A.TBRACCD_TRAN_NUMBER TRANS,
                                   B.SPRIDEN_ID,
                                   A.TBRACCD_PIDM,
                                   A.TBRACCD_TRAN_NUMBER_PAID PAGA,
                                   A.TBRACCD_TERM_CODE,
                                   A.TBRACCD_DETAIL_CODE CODIGO_DETALLE,
                                   A.TBRACCD_DESC,
                                   A.TBRACCD_AMOUNT,
                                   A.TBRACCD_BALANCE,
                                   C.TBBDETC_TYPE_IND TIPO,
                                   A.TBRACCD_DOCUMENT_NUMBER,
                                   TBRACCD_RECEIPT_NUMBER
                             FROM TBRACCD A,SPRIDEN B,TBBDETC C
                            WHERE     A.TBRACCD_PIDM = B.SPRIDEN_PIDM
                                  AND B.SPRIDEN_CHANGE_IND IS NULL
                                  And a.tbraccd_amount > 0
                                  --AND TBRACCD_DOCUMENT_NUMBER IS NULL -- Se apaga para cancelar todos los accesorios que estan en este rubro 
                                  AND C.TBBDETC_DETAIL_CODE = A.TBRACCD_DETAIL_CODE
                                  AND SUBSTR (A.TBRACCD_DETAIL_CODE ,3,4 ) IN (SELECT(ZSTPARA_PARAM_ID)
                                                                                 FROM ZSTPARA
                                                                                WHERE ZSTPARA_MAPA_ID = 'CANC_CAMCFV')
                                  AND A.TBRACCD_PIDM = PN_PIDM
                                  AND TRUNC(TBRACCD_EFFECTIVE_DATE) >= PN_FECHA_INICIO
                            ORDER BY 1

             )LOOP

               BEGIN
                 SELECT ZSTPARA_PARAM_VALOR
                   INTO VL_EXIS_CONTRA
                   FROM ZSTPARA
                  WHERE     ZSTPARA_PARAM_ID = SUBSTR (ALUMNO.CODIGO_DETALLE,3,4 )
                        AND ZSTPARA_MAPA_ID = 'CANC_CAMCFV';
               EXCEPTION
               WHEN OTHERS THEN
               VL_EXIS_CONTRA := 0;
               END;

               IF ALUMNO.TIPO = 'C' THEN
                 BEGIN
                   SELECT A1.TBRAPPL_PAY_TRAN_NUMBER
                     INTO VL_NUMPAG
                     FROM TBRAPPL A1
                    WHERE     A1.TBRAPPL_PIDM = PN_PIDM
                          AND A1.TBRAPPL_CHG_TRAN_NUMBER =  ALUMNO.TRANS
                          AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                            FROM TBRAPPL A
                                                           WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                                 AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_NUMPAG:=0;
                 END;
               ELSIF ALUMNO.TIPO = 'P' THEN
                 BEGIN
                   SELECT A1.TBRAPPL_CHG_TRAN_NUMBER
                     INTO VL_NUMPAG
                     FROM TBRAPPL A1
                    WHERE     A1.TBRAPPL_PIDM = PN_PIDM
                          AND A1.TBRAPPL_PAY_TRAN_NUMBER =  ALUMNO.TRANS
                          AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                            FROM TBRAPPL A
                                                           WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                                 AND A.TBRAPPL_PAY_TRAN_NUMBER =  A1.TBRAPPL_PAY_TRAN_NUMBER);
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_NUMPAG:=0;
                 END;
               END IF;

               BEGIN
                 SELECT TBRACCD_AMOUNT,TBRACCD_DETAIL_CODE
                   INTO VL_MONTO_PAGADO,VL_CODIGO_AJ
                   FROM TBRACCD
                  WHERE     TBRACCD_PIDM = PN_PIDM
                        AND TBRACCD_TRAN_NUMBER = VL_NUMPAG;
               EXCEPTION
                WHEN OTHERS THEN
                VL_MONTO_PAGADO :=0;
                VL_CODIGO_AJ := '0000';
               END;

               IF SUBSTR(VL_CODIGO_AJ,3,2) <> VL_EXIS_CONTRA THEN

                 BEGIN
                   SELECT COUNT (ZSTPARA_PARAM_VALOR)
                     INTO VL_EXIS_CONTRA_2
                     FROM ZSTPARA
                    WHERE     ZSTPARA_MAPA_ID = 'DET_CODE_CART'
                          AND ZSTPARA_PARAM_ID = 'PARC_ANTERIOR'
                          AND ZSTPARA_PARAM_VALOR = SUBSTR(VL_EXISTE_DETAIL,3,2);
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_EXIS_CONTRA_2:=0;
                 END;

                 IF VL_EXIS_CONTRA_2 = 0 THEN

                   PKG_FINANZAS.P_DESAPLICA_PAGOS (ALUMNO.TBRACCD_PIDM, ALUMNO.TRANS);

--                   DBMS_OUTPUT.PUT_LINE('INSERTA CONTRA PARTE'||'/'||VL_EXIS_CONTRA||'/'||VL_MONTO_PAGADO);

                   BEGIN
                     SELECT NVL (MAX(TBRACCD_TRAN_NUMBER) , 0)+1
                       INTO VL_TRANSACCION
                       FROM TBRACCD
                      WHERE TBRACCD_PIDM =  ALUMNO.TBRACCD_PIDM;
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_TRANSACCION := 1;
                   END;

--                   DBMS_OUTPUT.PUT_LINE('Secuencia '||VL_TRANSACCION);

                   BEGIN
                     SELECT TBBDETC_DETAIL_CODE, TBBDETC_DESC
                       INTO VL_COD_CONTRA, VL_DESC_CONTRA
                       FROM TBBDETC
                      WHERE SUBSTR(TBBDETC_DETAIL_CODE,1,2) = SUBSTR(ALUMNO.SPRIDEN_ID,1,2)
                           AND SUBSTR (TBBDETC_DETAIL_CODE,3,4) = VL_EXIS_CONTRA;
                   EXCEPTION
                   WHEN OTHERS THEN
                       VL_COD_CONTRA:= NULL;
                       VL_DESC_CONTRA := NULL;
                   END;

--                   DBMS_OUTPUT.PUT_LINE(VL_COD_CONTRA||'/'||VL_DESC_CONTRA||'/'||VL_EXIS_CONTRA);

                   IF ALUMNO.TIPO = 'C' THEN

                     INSERT
                       INTO TBRACCD
                     VALUES (
                              ALUMNO.TBRACCD_PIDM,   -- TBRACCD_PIDM
                              VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                              ALUMNO.TBRACCD_TERM_CODE,    -- TBRACCD_TERM_CODE
                              VL_COD_CONTRA,     ---TBRACCD_DETAIL_CODE
                              USER,     ---TBRACCD_USER
                              SYSDATE,     --TBRACCD_ENTRY_DATE
                              ALUMNO.TBRACCD_AMOUNT,
                              (ALUMNO.TBRACCD_AMOUNT)*-1,    ---TBRACCD_BALANCE
                              SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                              NULL,    --TBRACCD_BILL_DATE
                              NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                              VL_DESC_CONTRA,    -- TBRACCD_DESC
                              ALUMNO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                              ALUMNO.TRANS,     --TBRACCD_TRAN_NUMBER_PAID
                              NULL,     --TBRACCD_CROSSREF_PIDM
                              NULL,    --TBRACCD_CROSSREF_NUMBER
                              NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                              'T',    --TBRACCD_SRCE_CODE
                              'Y',    --TBRACCD_ACCT_FEED_IND
                              SYSDATE,  --TBRACCD_ACTIVITY_DATE
                              0,        --TBRACCD_SESSION_NUMBER
                              NULL,    -- TBRACCD_CSHR_END_DATE
                              NULL,     --TBRACCD_CRN
                              NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                              NULL,     -- TBRACCD_LOC_MDT
                              NULL,     --TBRACCD_LOC_MDT_SEQ
                              NULL,     -- TBRACCD_RATE
                              NULL,     --TBRACCD_UNITS
                              'SZFABCC',     -- TBRACCD_DOCUMENT_NUMBER
                              SYSDATE,  -- TBRACCD_TRANS_DATE
                              NULL,        -- TBRACCD_PAYMENT_ID
                              NULL,     -- TBRACCD_INVOICE_NUMBER
                              NULL,     -- TBRACCD_STATEMENT_DATE
                              NULL,     -- TBRACCD_INV_NUMBER_PAID
                              'MXN',     -- TBRACCD_CURR_CODE
                              NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                              NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                              NULL,     -- TBRACCD_LATE_DCAT_CODE
                              PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                              NULL,     -- TBRACCD_FEED_DOC_CODE
                              NULL,     -- TBRACCD_ATYP_CODE
                              NULL,     -- TBRACCD_ATYP_SEQNO
                              NULL,     -- TBRACCD_CARD_TYPE_VR
                              NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                              NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                              NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                              NULL,     -- TBRACCD_ORIG_CHG_IND
                              NULL,     -- TBRACCD_CCRD_CODE
                              NULL,     -- TBRACCD_MERCHANT_ID
                              NULL,     -- TBRACCD_TAX_REPT_YEAR
                              NULL,     -- TBRACCD_TAX_REPT_BOX
                              NULL,     -- TBRACCD_TAX_AMOUNT
                              NULL,     -- TBRACCD_TAX_FUTURE_IND
                              'Banner',     -- TBRACCD_DATA_ORIGIN
                              'VMRL',   -- TBRACCD_CREATE_SOURCE
                              NULL,     -- TBRACCD_CPDT_IND
                              NULL,     --TBRACCD_AIDY_CODE
                              PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                              VL_PARTE,     --TBRACCD_PERIOD
                              NULL,    --TBRACCD_SURROGATE_ID
                              NULL,     -- TBRACCD_VERSION
                              USER,     --TBRACCD_USER_ID
                              NULL );     --TBRACCD_VPDI_CODE

--                     DBMS_OUTPUT.PUT_LINE('1'||'/'||VL_ERROR);

                   ELSIF ALUMNO.TIPO = 'P' THEN

                     INSERT
                       INTO TBRACCD
                     VALUES (
                              ALUMNO.TBRACCD_PIDM,   -- TBRACCD_PIDM
                              VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                              ALUMNO.TBRACCD_TERM_CODE,    -- TBRACCD_TERM_CODE
                              VL_COD_CONTRA,     ---TBRACCD_DETAIL_CODE
                              USER,     ---TBRACCD_USER
                              SYSDATE,     --TBRACCD_ENTRY_DATE
                              ALUMNO.TBRACCD_AMOUNT,
                              ALUMNO.TBRACCD_AMOUNT,    ---TBRACCD_BALANCE
                              SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                              NULL,    --TBRACCD_BILL_DATE
                              NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                              VL_DESC_CONTRA,    -- TBRACCD_DESC
                              ALUMNO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                              NULL,     --TBRACCD_TRAN_NUMBER_PAID
                              NULL,     --TBRACCD_CROSSREF_PIDM
                              NULL,    --TBRACCD_CROSSREF_NUMBER
                              NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                              'T',    --TBRACCD_SRCE_CODE
                              'Y',    --TBRACCD_ACCT_FEED_IND
                              SYSDATE,  --TBRACCD_ACTIVITY_DATE
                              0,        --TBRACCD_SESSION_NUMBER
                              NULL,    -- TBRACCD_CSHR_END_DATE
                              NULL,     --TBRACCD_CRN
                              NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                              NULL,     -- TBRACCD_LOC_MDT
                              NULL,     --TBRACCD_LOC_MDT_SEQ
                              NULL,     -- TBRACCD_RATE
                              NULL,     --TBRACCD_UNITS
                              'SZFABCC',     -- TBRACCD_DOCUMENT_NUMBER
                              SYSDATE,  -- TBRACCD_TRANS_DATE
                              NULL,        -- TBRACCD_PAYMENT_ID
                              NULL,     -- TBRACCD_INVOICE_NUMBER
                              NULL,     -- TBRACCD_STATEMENT_DATE
                              NULL,     -- TBRACCD_INV_NUMBER_PAID
                              'MXN',     -- TBRACCD_CURR_CODE
                              NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                              NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                              NULL,     -- TBRACCD_LATE_DCAT_CODE
                              PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                              NULL,     -- TBRACCD_FEED_DOC_CODE
                              NULL,     -- TBRACCD_ATYP_CODE
                              NULL,     -- TBRACCD_ATYP_SEQNO
                              NULL,     -- TBRACCD_CARD_TYPE_VR
                              NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                              NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                              NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                              NULL,     -- TBRACCD_ORIG_CHG_IND
                              NULL,     -- TBRACCD_CCRD_CODE
                              NULL,     -- TBRACCD_MERCHANT_ID
                              NULL,     -- TBRACCD_TAX_REPT_YEAR
                              NULL,     -- TBRACCD_TAX_REPT_BOX
                              NULL,     -- TBRACCD_TAX_AMOUNT
                              NULL,     -- TBRACCD_TAX_FUTURE_IND
                              'Banner',     -- TBRACCD_DATA_ORIGIN
                              'VMRL',   -- TBRACCD_CREATE_SOURCE
                              NULL,     -- TBRACCD_CPDT_IND
                              NULL,     --TBRACCD_AIDY_CODE
                              PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                              VL_PARTE,     --TBRACCD_PERIOD
                              NULL,    --TBRACCD_SURROGATE_ID
                              NULL,     -- TBRACCD_VERSION
                              USER,     --TBRACCD_USER_ID
                              NULL );     --TBRACCD_VPDI_CODE

                   END IF;

                   BEGIN
                     UPDATE TBRACCD
                        SET TBRACCD_DOCUMENT_NUMBER = 'SZFABCC',
                            TBRACCD_TRAN_NUMBER_PAID = NULL
                      WHERE     TBRACCD_PIDM = PN_PIDM
                            AND TBRACCD_TRAN_NUMBER IN (ALUMNO.TRANS,VL_TRANSACCION);
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_ERROR :=' Errror al actualizar saldo Pago>>  ' || SQLERRM ;
                   END;

                   IF ALUMNO.TIPO = 'P' THEN

                        UPDATE TBRACCD
                           SET TBRACCD_TRAN_NUMBER_PAID =  VL_TRANSACCION
                         WHERE     TBRACCD_PIDM = ALUMNO.TBRACCD_PIDM
                               AND TBRACCD_TRAN_NUMBER =  ALUMNO.TRANS;
                   ELSE

                        UPDATE TBRACCD
                           SET TBRACCD_TRAN_NUMBER_PAID = ALUMNO.TRANS
                         WHERE     TBRACCD_PIDM = ALUMNO.TBRACCD_PIDM
                               AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;

                   END IF;

--                   DBMS_OUTPUT.PUT_LINE('Termina AJUSTES CAMBIO CICLO Y CAMBIO FECHA');

                 END IF;
               END IF;
             END LOOP;
           END IF;
--             DBMS_OUTPUT.PUT_LINE('pn_estatus  1---'||PN_ESTATUS );
         ELSIF PN_ESTATUS = 'CV' THEN

--           DBMS_OUTPUT.PUT_LINE('pn_estatus  2---'||PN_ESTATUS );

           BEGIN
             SELECT COUNT(*)
               INTO VL_ENTRA
               FROM TBRACCD A,SPRIDEN B,TBBDETC C
              WHERE A.TBRACCD_PIDM = B.SPRIDEN_PIDM
                    AND B.SPRIDEN_CHANGE_IND IS NULL
                    AND C.TBBDETC_DETAIL_CODE = A.TBRACCD_DETAIL_CODE
                    AND SUBSTR (A.TBRACCD_DETAIL_CODE ,3,4 ) IN (SELECT(ZSTPARA_PARAM_ID)
                                                                   FROM ZSTPARA
                                                                  WHERE ZSTPARA_MAPA_ID = 'CANC_DEC40')
                    AND C.TBBDETC_DCAT_CODE NOT IN ('TUI','DSP','LPC')
                    AND A.TBRACCD_DESC NOT LIKE ('DSI COLE%')
                    AND A.TBRACCD_PIDM = PN_PIDM;
           EXCEPTION
           WHEN OTHERS THEN
           VL_ENTRA:=0;
           END;

           IF VL_ENTRA > 0 THEN

             FOR ALUMNO IN (

                           SELECT A.TBRACCD_TRAN_NUMBER TRANS,
                                  B.SPRIDEN_ID,
                                  A.TBRACCD_PIDM,
                                  A.TBRACCD_TRAN_NUMBER_PAID PAGA,
                                  A.TBRACCD_TERM_CODE,
                                  A.TBRACCD_DETAIL_CODE CODIGO_DETALLE,
                                  A.TBRACCD_DESC,
                                  A.TBRACCD_AMOUNT,
                                  A.TBRACCD_BALANCE,
                                  C.TBBDETC_TYPE_IND TIPO,
                                  A.TBRACCD_DOCUMENT_NUMBER,
                                  TBRACCD_RECEIPT_NUMBER
                             FROM TBRACCD A,SPRIDEN B,TBBDETC C
                            WHERE     A.TBRACCD_PIDM = B.SPRIDEN_PIDM
                                  AND B.SPRIDEN_CHANGE_IND IS NULL
                                  AND C.TBBDETC_DETAIL_CODE = A.TBRACCD_DETAIL_CODE
                                  AND SUBSTR (A.TBRACCD_DETAIL_CODE ,3,4 ) IN (SELECT ZSTPARA_PARAM_ID
                                                                                 FROM ZSTPARA
                                                                                WHERE ZSTPARA_MAPA_ID = 'CANC_DEC40')
                                  AND C.TBBDETC_DCAT_CODE NOT IN ('TUI','DSP','LPC')
                                  AND A.TBRACCD_DESC NOT LIKE ('DSI COLE%')
                                  AND A.TBRACCD_PIDM = PN_PIDM
                                  AND a.TBRACCD_DOCUMENT_NUMBER IS NULL
                            ORDER BY 1


             ) LOOP

               BEGIN
                 SELECT ZSTPARA_PARAM_VALOR
                   INTO VL_EXIS_CONTRA
                   FROM ZSTPARA
                  WHERE     ZSTPARA_PARAM_ID = SUBSTR (ALUMNO.CODIGO_DETALLE,3,4 )
                        AND ZSTPARA_MAPA_ID = 'CANC_DEC40';
               EXCEPTION
               WHEN OTHERS THEN
               VL_EXIS_CONTRA := 0;
               END;

--               DBMS_OUTPUT.PUT_LINE('vl_exis_contra'||'/'||VL_EXIS_CONTRA||'/'||ALUMNO.TRANS);

               IF ALUMNO.TIPO = 'C' THEN
                 BEGIN
                   SELECT A1.TBRAPPL_PAY_TRAN_NUMBER
                     INTO VL_NUMPAG
                     FROM TBRAPPL A1
                    WHERE     A1.TBRAPPL_PIDM = ALUMNO.TBRACCD_PIDM
                          AND A1.TBRAPPL_CHG_TRAN_NUMBER =  ALUMNO.TRANS
                          AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                            FROM TBRAPPL A
                                                           WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                                 AND A.TBRAPPL_CHG_TRAN_NUMBER =  A1.TBRAPPL_CHG_TRAN_NUMBER);
                 END;
               ELSIF ALUMNO.TIPO = 'P' THEN
                 BEGIN
                   SELECT A1.TBRAPPL_CHG_TRAN_NUMBER
                     INTO VL_NUMPAG
                     FROM TBRAPPL A1
                    WHERE     A1.TBRAPPL_PIDM = ALUMNO.TBRACCD_PIDM
                          AND A1.TBRAPPL_PAY_TRAN_NUMBER =  ALUMNO.TRANS
                          AND A1.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (A.TBRAPPL_ACTIVITY_DATE)
                                                            FROM TBRAPPL A
                                                           WHERE     A.TBRAPPL_PIDM = A1.TBRAPPL_PIDM
                                                                 AND A.TBRAPPL_PAY_TRAN_NUMBER =  A1.TBRAPPL_PAY_TRAN_NUMBER);
                 END;
               END IF;

--               DBMS_OUTPUT.PUT_LINE('vl_numpag'||'/'||VL_NUMPAG||'/'||VL_EXIS_CONTRA);

               BEGIN
                 SELECT TBRACCD_AMOUNT,TBRACCD_DETAIL_CODE
                   INTO VL_MONTO_PAGADO,VL_CODIGO_AJ
                   FROM TBRACCD
                  WHERE     TBRACCD_PIDM = ALUMNO.TBRACCD_PIDM
                        AND TBRACCD_TRAN_NUMBER = VL_NUMPAG;
               EXCEPTION
                WHEN OTHERS THEN
                VL_MONTO_PAGADO :=0;
                VL_CODIGO_AJ := '0000';
               END;

--               DBMS_OUTPUT.PUT_LINE('INCERTA CONTRA PARTE'||'/'||VL_EXIS_CONTRA||'+++'||VL_CODIGO_AJ);

               IF VL_EXIS_CONTRA <> SUBSTR (VL_CODIGO_AJ,3,4 ) THEN

                 BEGIN
                   SELECT COUNT (ZSTPARA_PARAM_VALOR)
                     INTO VL_EXIS_CONTRA_2
                     FROM ZSTPARA
                    WHERE     ZSTPARA_MAPA_ID = 'DET_CODE_CART'
                          AND ZSTPARA_PARAM_ID = 'PARC_ANTERIOR'
                          AND ZSTPARA_PARAM_VALOR = SUBSTR(VL_EXISTE_DETAIL,3,2);
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_EXIS_CONTRA_2:=0;
                 END;

                 IF VL_EXIS_CONTRA_2 = 0 THEN

                   PKG_FINANZAS.P_DESAPLICA_PAGOS (ALUMNO.TBRACCD_PIDM, ALUMNO.TRANS);

--                   DBMS_OUTPUT.PUT_LINE('INSERTA CONTRA PARTE'||'/'||VL_EXIS_CONTRA||'/'||VL_MONTO_PAGADO);

                   BEGIN
                     SELECT NVL (MAX(TBRACCD_TRAN_NUMBER) , 0)+1
                       INTO VL_TRANSACCION
                       FROM TBRACCD
                      WHERE TBRACCD_PIDM =  ALUMNO.TBRACCD_PIDM;
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_TRANSACCION := 1;
                   END;

--                   DBMS_OUTPUT.PUT_LINE('Secuencia '||VL_TRANSACCION||'----'|| ALUMNO.SPRIDEN_ID||'----'|| VL_EXIS_CONTRA);

                   VL_EXIS_CONTRA := (SUBSTR(ALUMNO.SPRIDEN_ID,1,2)||VL_EXIS_CONTRA);

--                   DBMS_OUTPUT.PUT_LINE(VL_EXIS_CONTRA);

                   BEGIN
                     SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC
                       INTO VL_COD_CONTRA, VL_DESC_CONTRA
                       FROM TBBDETC
                      WHERE TBBDETC_DETAIL_CODE = VL_EXIS_CONTRA;
                   EXCEPTION
                   WHEN OTHERS THEN
                   RAISE_APPLICATION_ERROR (-20002,'Contando ><'||VL_EXIS_CONTRA||'ZZZZZZZZZ'||SQLERRM);
                   END;

--                   DBMS_OUTPUT.PUT_LINE(VL_COD_CONTRA||'/'||VL_DESC_CONTRA||'/'||VL_EXIS_CONTRA);

                   IF ALUMNO.TIPO = 'C' THEN
                     BEGIN
                         INSERT
                           INTO TBRACCD
                         VALUES (
                                  ALUMNO.TBRACCD_PIDM,   -- TBRACCD_PIDM
                                  VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                                  ALUMNO.TBRACCD_TERM_CODE,    -- TBRACCD_TERM_CODE
                                  VL_COD_CONTRA,     ---TBRACCD_DETAIL_CODE
                                  USER,     ---TBRACCD_USER
                                  SYSDATE,     --TBRACCD_ENTRY_DATE
                                  ALUMNO.TBRACCD_AMOUNT,
                                  (ALUMNO.TBRACCD_AMOUNT)*-1,    ---TBRACCD_BALANCE
                                  SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                                  NULL,    --TBRACCD_BILL_DATE
                                  NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                  VL_DESC_CONTRA,    -- TBRACCD_DESC
                                  ALUMNO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                                  ALUMNO.TRANS,     --TBRACCD_TRAN_NUMBER_PAID
                                  NULL,     --TBRACCD_CROSSREF_PIDM
                                  NULL,    --TBRACCD_CROSSREF_NUMBER
                                  NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                  'T',    --TBRACCD_SRCE_CODE
                                  'Y',    --TBRACCD_ACCT_FEED_IND
                                  SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                  0,        --TBRACCD_SESSION_NUMBER
                                  NULL,    -- TBRACCD_CSHR_END_DATE
                                  NULL,     --TBRACCD_CRN
                                  NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                  NULL,     -- TBRACCD_LOC_MDT
                                  NULL,     --TBRACCD_LOC_MDT_SEQ
                                  NULL,     -- TBRACCD_RATE
                                  NULL,     --TBRACCD_UNITS
                                  NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                  SYSDATE,  -- TBRACCD_TRANS_DATE
                                  NULL,        -- TBRACCD_PAYMENT_ID
                                  NULL,     -- TBRACCD_INVOICE_NUMBER
                                  NULL,     -- TBRACCD_STATEMENT_DATE
                                  NULL,     -- TBRACCD_INV_NUMBER_PAID
                                  'MXN',     -- TBRACCD_CURR_CODE
                                  NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                  NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                  NULL,     -- TBRACCD_LATE_DCAT_CODE
                                  PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                                  NULL,     -- TBRACCD_FEED_DOC_CODE
                                  NULL,     -- TBRACCD_ATYP_CODE
                                  NULL,     -- TBRACCD_ATYP_SEQNO
                                  NULL,     -- TBRACCD_CARD_TYPE_VR
                                  NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                  NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                  NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                  NULL,     -- TBRACCD_ORIG_CHG_IND
                                  NULL,     -- TBRACCD_CCRD_CODE
                                  NULL,     -- TBRACCD_MERCHANT_ID
                                  NULL,     -- TBRACCD_TAX_REPT_YEAR
                                  NULL,     -- TBRACCD_TAX_REPT_BOX
                                  NULL,     -- TBRACCD_TAX_AMOUNT
                                  NULL,     -- TBRACCD_TAX_FUTURE_IND
                                  'Banner',     -- TBRACCD_DATA_ORIGIN
                                  'AUTOM',   -- TBRACCD_CREATE_SOURCE
                                  NULL,     -- TBRACCD_CPDT_IND
                                  NULL,     --TBRACCD_AIDY_CODE
                                  PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                                  VL_PARTE,     --TBRACCD_PERIOD
                                  NULL,    --TBRACCD_SURROGATE_ID
                                  NULL,     -- TBRACCD_VERSION
                                  USER,     --TBRACCD_USER_ID
                                  NULL );     --TBRACCD_VPDI_CODE
                     END;

                     BEGIN
                       INSERT
                         INTO TBRAPPL
                       VALUES (
                                 ALUMNO.TBRACCD_PIDM,               --TBRAPPL_PIDM
                                 VL_TRANSACCION,               --TBRAPPL_PAY_TRAN_NUMBER
                                 ALUMNO.TRANS,               --TBRAPPL_CHG_TRAN_NUMBER
                                 ALUMNO.TBRACCD_AMOUNT ,              --TBRAPPL_AMOUNT
                                 NULL,             --TBRAPPL_DIRECT_PAY_IND
                                 NULL,              --TBRAPPL_REAPPL_IND
                                 USER,              --TBRAPPL_USER
                                 'Y',              --TBRAPPL_ACCT_FEED_IND
                                 SYSDATE,              --TBRAPPL_ACTIVITY_DATE
                                 NULL,              --TBRAPPL_FEED_DATE
                                 'Y',              --TBRAPPL_FEED_DOC_CODE
                                 NULL,              --TBRAPPL_CPDT_TRAN_NUMBER
                                 NULL,              --TBRAPPL_DIRECT_PAY_TYPE
                                 NULL,              --TBRAPPL_INV_NUMBER_PAID
                                 NULL,              --TBRAPPL_SURROGATE_ID
                                 NULL,              --TBRAPPL_VERSION
                                 USER,              --TBRAPPL_USER_ID
                                 'AJ',              --TBRAPPL_DATA_ORIGIN
                                 NULL);              --TBRAPPL_VPDI_CODE
                     EXCEPTION
                     WHEN OTHERS THEN
                     VL_TRANSACCION :=' Errror al Insertar aplicacion de pagos 1  ' || SQLERRM ;
                     END;

                   ELSIF ALUMNO.TIPO = 'P' THEN

                     BEGIN
                       INSERT
                         INTO TBRACCD
                       VALUES (
                                ALUMNO.TBRACCD_PIDM,   -- TBRACCD_PIDM
                                VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                                ALUMNO.TBRACCD_TERM_CODE,    -- TBRACCD_TERM_CODE
                                VL_COD_CONTRA,     ---TBRACCD_DETAIL_CODE
                                USER,     ---TBRACCD_USER
                                SYSDATE,     --TBRACCD_ENTRY_DATE
                                ALUMNO.TBRACCD_AMOUNT,
                                ALUMNO.TBRACCD_AMOUNT,    ---TBRACCD_BALANCE
                                SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                                NULL,    --TBRACCD_BILL_DATE
                                NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                VL_DESC_CONTRA,    -- TBRACCD_DESC
                                ALUMNO.TBRACCD_RECEIPT_NUMBER,     --TBRACCD_RECEIPT_NUMBER
                                NULL,     --TBRACCD_TRAN_NUMBER_PAID
                                NULL,     --TBRACCD_CROSSREF_PIDM
                                NULL,    --TBRACCD_CROSSREF_NUMBER
                                NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                'T',    --TBRACCD_SRCE_CODE
                                'Y',    --TBRACCD_ACCT_FEED_IND
                                SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                0,        --TBRACCD_SESSION_NUMBER
                                NULL,    -- TBRACCD_CSHR_END_DATE
                                NULL,     --TBRACCD_CRN
                                NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                NULL,     -- TBRACCD_LOC_MDT
                                NULL,     --TBRACCD_LOC_MDT_SEQ
                                NULL,     -- TBRACCD_RATE
                                NULL,     --TBRACCD_UNITS
                                NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                SYSDATE,  -- TBRACCD_TRANS_DATE
                                NULL,        -- TBRACCD_PAYMENT_ID
                                NULL,     -- TBRACCD_INVOICE_NUMBER
                                NULL,     -- TBRACCD_STATEMENT_DATE
                                NULL,     -- TBRACCD_INV_NUMBER_PAID
                                'MXN',     -- TBRACCD_CURR_CODE
                                NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                NULL,     -- TBRACCD_LATE_DCAT_CODE
                                PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                                NULL,     -- TBRACCD_FEED_DOC_CODE
                                NULL,     -- TBRACCD_ATYP_CODE
                                NULL,     -- TBRACCD_ATYP_SEQNO
                                NULL,     -- TBRACCD_CARD_TYPE_VR
                                NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                NULL,     -- TBRACCD_ORIG_CHG_IND
                                NULL,     -- TBRACCD_CCRD_CODE
                                NULL,     -- TBRACCD_MERCHANT_ID
                                NULL,     -- TBRACCD_TAX_REPT_YEAR
                                NULL,     -- TBRACCD_TAX_REPT_BOX
                                NULL,     -- TBRACCD_TAX_AMOUNT
                                NULL,     -- TBRACCD_TAX_FUTURE_IND
                                'Banner',     -- TBRACCD_DATA_ORIGIN
                                'AUTOM',   -- TBRACCD_CREATE_SOURCE
                                NULL,     -- TBRACCD_CPDT_IND
                                NULL,     --TBRACCD_AIDY_CODE
                                PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                                VL_PARTE,     --TBRACCD_PERIOD
                                NULL,    --TBRACCD_SURROGATE_ID
                                NULL,     -- TBRACCD_VERSION
                                USER,     --TBRACCD_USER_ID
                                NULL );     --TBRACCD_VPDI_CODE
                     END;
--                     DBMS_OUTPUT.PUT_LINE('Termina contra parte CARGO');

                     BEGIN
                       INSERT
                         INTO TBRAPPL
                       VALUES (
                                ALUMNO.TBRACCD_PIDM,               --TBRAPPL_PIDM
                                ALUMNO.TRANS,               --TBRAPPL_PAY_TRAN_NUMBER
                                VL_TRANSACCION,               --TBRAPPL_CHG_TRAN_NUMBER
                                ALUMNO.TBRACCD_AMOUNT ,              --TBRAPPL_AMOUNT
                                NULL,             --TBRAPPL_DIRECT_PAY_IND
                                NULL,              --TBRAPPL_REAPPL_IND
                                USER,              --TBRAPPL_USER
                                'Y',              --TBRAPPL_ACCT_FEED_IND
                                SYSDATE,              --TBRAPPL_ACTIVITY_DATE
                                NULL,              --TBRAPPL_FEED_DATE
                                'Y',              --TBRAPPL_FEED_DOC_CODE
                                NULL,              --TBRAPPL_CPDT_TRAN_NUMBER
                                NULL,              --TBRAPPL_DIRECT_PAY_TYPE
                                NULL,              --TBRAPPL_INV_NUMBER_PAID
                                NULL,              --TBRAPPL_SURROGATE_ID
                                NULL,              --TBRAPPL_VERSION
                                USER,              --TBRAPPL_USER_ID
                                'AJ',              --TBRAPPL_DATA_ORIGIN
                                NULL);              --TBRAPPL_VPDI_CODE
                     EXCEPTION
                     WHEN OTHERS THEN
                       VL_TRANSACCION :=' Errror al Insertar aplicacion de pagos>>  ' || SQLERRM ;
                     END;

                   END IF;

                   BEGIN
                     UPDATE TBRACCD
                        SET TBRACCD_BALANCE = 0
                      WHERE     TBRACCD_PIDM = PN_PIDM
                            AND TBRACCD_TRAN_NUMBER = ALUMNO.TRANS;
                   END;

                   BEGIN
                     UPDATE TBRACCD
                        SET TBRACCD_BALANCE = 0
                      WHERE     TBRACCD_PIDM = PN_PIDM
                            AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
                   END;

                   IF ALUMNO.TIPO = 'P' THEN
                      UPDATE TBRACCD
                         SET TBRACCD_TRAN_NUMBER_PAID =  VL_TRANSACCION
                       WHERE     TBRACCD_PIDM = ALUMNO.TBRACCD_PIDM
                             AND TBRACCD_TRAN_NUMBER =  ALUMNO.TRANS;
                   END IF;
--                   DBMS_OUTPUT.PUT_LINE('Termina AJUSTES');
                 END IF;
               END IF;
             END LOOP;
           END IF;

           BEGIN
             SELECT COUNT (*)
               INTO VL_ENTRA
               FROM TBRACCD
              WHERE     TBRACCD_PIDM = PN_PIDM
                    AND TBRACCD_DETAIL_CODE IN (SELECT(TBBDETC_DETAIL_CODE)
                                                  FROM TBBDETC
                                                 WHERE TBBDETC_DCAT_CODE = 'CSH')
                    AND TBRACCD_DESC NOT LIKE ('%CTRACGO%');
           EXCEPTION
           WHEN OTHERS THEN
           VL_ENTRA:=0;
           END;

--           DBMS_OUTPUT.PUT_LINE('VL_ENTRA 1<<<'||VL_ENTRA);

           IF VL_ENTRA > 0 THEN

--             DBMS_OUTPUT.PUT_LINE('VL_ENTRA 2<<<'||VL_ENTRA);
             FOR CASH IN (
                          SELECT TBRACCD_DETAIL_CODE CODIGO,TBRACCD_AMOUNT MONTO, TBRACCD_TRAN_NUMBER TRANS,TBRACCD_TERM_CODE
                            FROM TBRACCD
                           WHERE     TBRACCD_PIDM = PN_PIDM
                                 AND TBRACCD_DETAIL_CODE IN (SELECT(TBBDETC_DETAIL_CODE)
                                                               FROM TBBDETC
                                                              WHERE TBBDETC_DCAT_CODE = 'CSH')
                                 AND TBRACCD_DESC NOT LIKE ('%CTRACGO%')

             )LOOP

               BEGIN
                 SELECT NVL(MAX(A.TBRAPPL_CHG_TRAN_NUMBER),0)
                   INTO VL_CSH_PAG
                   FROM TBRAPPL A
                  WHERE     A.TBRAPPL_PIDM = PN_PIDM
                        AND A.TBRAPPL_PAY_TRAN_NUMBER = CASH.TRANS
                        AND A.TBRAPPL_ACTIVITY_DATE = (SELECT MAX (B.TBRAPPL_ACTIVITY_DATE)
                                                         FROM TBRAPPL B
                                                        WHERE     B.TBRAPPL_PIDM = A.TBRAPPL_PIDM
                                                              AND B.TBRAPPL_PAY_TRAN_NUMBER = A.TBRAPPL_PAY_TRAN_NUMBER);
               EXCEPTION
               WHEN OTHERS THEN
               VL_ERROR :=' Errror CASH 1>>  ' || SQLERRM ;
               END;

--               DBMS_OUTPUT.PUT_LINE('CASH 1---'||VL_CSH_PAG);

               BEGIN
                 SELECT TBRACCD_DETAIL_CODE
                   INTO VL_AJUSTA_CSH
                   FROM TBRACCD
                  WHERE TBRACCD_PIDM =  PN_PIDM
                        AND TBRACCD_TRAN_NUMBER = VL_CSH_PAG
                        AND TBRACCD_DETAIL_CODE IN (SELECT(TBBDETC_DETAIL_CODE)
                                                      FROM TBBDETC
                                                     WHERE TBBDETC_DCAT_CODE IN ('CSH','PYG'));
               EXCEPTION
               WHEN OTHERS THEN
               VL_AJUSTA_CSH := NULL;
               END;

--               DBMS_OUTPUT.PUT_LINE('CASH 2---'||VL_AJUSTA_CSH);

               IF VL_AJUSTA_CSH IS  NULL THEN

                 PKG_FINANZAS.P_DESAPLICA_PAGOS (PN_PIDM, CASH.TRANS);

--                 DBMS_OUTPUT.PUT_LINE('INSERTA CONTRA PARTE CASH'||'/'||VL_EXIS_CONTRA||'/'||VL_MONTO_PAGADO);

                 BEGIN

                       SELECT NVL (MAX(TBRACCD_TRAN_NUMBER) , 0)+1
                       INTO VL_TRANSACCION
                       FROM TBRACCD
                       WHERE TBRACCD_PIDM =  PN_PIDM;

                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_TRANSACCION := 1;
                 END;

                 BEGIN
                   INSERT
                     INTO TBRACCD
                   VALUES (
                            PN_PIDM,   -- TBRACCD_PIDM
                            VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                            CASH.TBRACCD_TERM_CODE,    -- TBRACCD_TERM_CODE
                            SUBSTR(CASH.TBRACCD_TERM_CODE,1,2)||'1F',     ---TBRACCD_DETAIL_CODE
                            USER,     ---TBRACCD_USER
                            SYSDATE,     --TBRACCD_ENTRY_DATE
                            CASH.MONTO,
                            CASH.MONTO,    ---TBRACCD_BALANCE
                            SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                            NULL,    --TBRACCD_BILL_DATE
                            NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                            'OTROS INGRESOS A RESULTADOS',    -- TBRACCD_DESC
                            NULL,     --TBRACCD_RECEIPT_NUMBER
                            NULL,     --TBRACCD_TRAN_NUMBER_PAID
                            NULL,     --TBRACCD_CROSSREF_PIDM
                            NULL,    --TBRACCD_CROSSREF_NUMBER
                            NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                            'T',    --TBRACCD_SRCE_CODE
                            'Y',    --TBRACCD_ACCT_FEED_IND
                            SYSDATE,  --TBRACCD_ACTIVITY_DATE
                            0,        --TBRACCD_SESSION_NUMBER
                            NULL,    -- TBRACCD_CSHR_END_DATE
                            NULL,     --TBRACCD_CRN
                            NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                            NULL,     -- TBRACCD_LOC_MDT
                            NULL,     --TBRACCD_LOC_MDT_SEQ
                            NULL,     -- TBRACCD_RATE
                            NULL,     --TBRACCD_UNITS
                            NULL,     -- TBRACCD_DOCUMENT_NUMBER
                            SYSDATE,  -- TBRACCD_TRANS_DATE
                            NULL,        -- TBRACCD_PAYMENT_ID
                            NULL,     -- TBRACCD_INVOICE_NUMBER
                            NULL,     -- TBRACCD_STATEMENT_DATE
                            NULL,     -- TBRACCD_INV_NUMBER_PAID
                            'MXN',     -- TBRACCD_CURR_CODE
                            NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                            NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                            NULL,     -- TBRACCD_LATE_DCAT_CODE
                            PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                            NULL,     -- TBRACCD_FEED_DOC_CODE
                            NULL,     -- TBRACCD_ATYP_CODE
                            NULL,     -- TBRACCD_ATYP_SEQNO
                            NULL,     -- TBRACCD_CARD_TYPE_VR
                            NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                            NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                            NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                            NULL,     -- TBRACCD_ORIG_CHG_IND
                            NULL,     -- TBRACCD_CCRD_CODE
                            NULL,     -- TBRACCD_MERCHANT_ID
                            NULL,     -- TBRACCD_TAX_REPT_YEAR
                            NULL,     -- TBRACCD_TAX_REPT_BOX
                            NULL,     -- TBRACCD_TAX_AMOUNT
                            NULL,     -- TBRACCD_TAX_FUTURE_IND
                            'Banner',     -- TBRACCD_DATA_ORIGIN
                            'AUTOM',   -- TBRACCD_CREATE_SOURCE
                            NULL,     -- TBRACCD_CPDT_IND
                            NULL,     --TBRACCD_AIDY_CODE
                            PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                            VL_PARTE,     --TBRACCD_PERIOD
                            NULL,    --TBRACCD_SURROGATE_ID
                            NULL,     -- TBRACCD_VERSION
                            USER,     --TBRACCD_USER_ID
                            NULL );     --TBRACCD_VPDI_CODE
                 END;

                 BEGIN
                   INSERT
                     INTO TBRAPPL
                   VALUES (
                           PN_PIDM,               --TBRAPPL_PIDM
                           CASH.TRANS,               --TBRAPPL_PAY_TRAN_NUMBER
                           VL_TRANSACCION,               --TBRAPPL_CHG_TRAN_NUMBER
                           CASH.MONTO,              --TBRAPPL_AMOUNT
                           NULL,             --TBRAPPL_DIRECT_PAY_IND
                           NULL,              --TBRAPPL_REAPPL_IND
                           USER,              --TBRAPPL_USER
                           'Y',              --TBRAPPL_ACCT_FEED_IND
                           SYSDATE,              --TBRAPPL_ACTIVITY_DATE
                           NULL,              --TBRAPPL_FEED_DATE
                           'Y',              --TBRAPPL_FEED_DOC_CODE
                           NULL,              --TBRAPPL_CPDT_TRAN_NUMBER
                           NULL,              --TBRAPPL_DIRECT_PAY_TYPE
                           NULL,              --TBRAPPL_INV_NUMBER_PAID
                           NULL,              --TBRAPPL_SURROGATE_ID
                           NULL,              --TBRAPPL_VERSION
                           USER,              --TBRAPPL_USER_ID
                           'AJ',              --TBRAPPL_DATA_ORIGIN
                           NULL);              --TBRAPPL_VPDI_CODE
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_TRANSACCION :=' Errror al Insertar aplicacion de pagos>>  ' || SQLERRM ;
                 END;

                 BEGIN
                   UPDATE TBRACCD
                      SET TBRACCD_BALANCE = 0
                    WHERE     TBRACCD_PIDM = PN_PIDM
                          AND TBRACCD_TRAN_NUMBER = CASH.TRANS;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_ERROR :=' Errror CASH 3 >>  ' || SQLERRM ;
                 END;

                 BEGIN
                   UPDATE TBRACCD
                      SET TBRACCD_BALANCE = 0
                    WHERE     TBRACCD_PIDM = PN_PIDM
                          AND TBRACCD_TRAN_NUMBER = VL_TRANSACCION;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_ERROR :=' Errror CASH 4 >>  ' || SQLERRM ;
                 END;

                 BEGIN
                   UPDATE TBRACCD
                      SET TBRACCD_TRAN_NUMBER_PAID = VL_TRANSACCION
                    WHERE     TBRACCD_PIDM = PN_PIDM
                          AND TBRACCD_TRAN_NUMBER = CASH.TRANS;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_ERROR :=' Errror al actualizar saldo Saldo>>  ' || SQLERRM ;
                 END;

               END IF;
             END LOOP;
           END IF;
--             DBMS_OUTPUT.PUT_LINE('VL_ENTRA 3<<<'||VL_ENTRA);
         END IF;
         -- SE INSERTA EL TRAMITE DE CAMBIO DE CICLO, CAMBIO FECHA INICIO, BAJA DEFINITIVA O BAJA TEMPORAL ---
 --        IF PN_ESTATUS = 'CC' THEN VL_CARGO_TRAM := (SUBSTR(PN_PERIODO,1,2)||'AM'); END IF;
   --      IF PN_ESTATUS = 'CF' THEN VL_CARGO_TRAM := (SUBSTR(PN_PERIODO,1,2)||'AO'); END IF;
         IF PN_ESTATUS = 'BD' THEN VL_CARGO_TRAM := (SUBSTR(PN_PERIODO,1,2)||'AH'); END IF;
         IF PN_ESTATUS = 'BT' THEN VL_CARGO_TRAM := (SUBSTR(PN_PERIODO,1,2)||'AI'); END IF;
         IF PN_ESTATUS = 'CV' THEN VL_CARGO_TRAM := (SUBSTR(PN_PERIODO,1,2)||'G7'); END IF;
         IF PN_ESTATUS = 'CP' THEN VL_CARGO_TRAM := (SUBSTR(PN_PERIODO,1,2)||'AR'); END IF;
--         IF PN_ESTATUS = 'BA' THEN VL_CARGO_TRAM := (SUBSTR(PN_PERIODO,1,2)||'AI'); END IF;-------SE DESCARTA CARGO DE BAJA TEMPORAL A PETICION DE FINANZAS

--         DBMS_OUTPUT.PUT_LINE('VL_ENTRA 4<<<'||VL_CARGO_TRAM);

         IF PN_ESTATUS IN ('BD','BT','CV','CP') THEN----------------------SE ELIMINA STATUS 'BA' PARA EVITAR CARGO DE LA BAJA

           BEGIN
             SELECT COUNT(ZSTPARA_PARAM_VALOR)
               INTO VL_ENTRA_COND_2
               FROM ZSTPARA
              WHERE     ZSTPARA_MAPA_ID = 'COND_TRAMI'
                    AND ZSTPARA_PARAM_ID = PN_CAMPUS
                    AND ZSTPARA_PARAM_VALOR = PN_NIVEL;
           EXCEPTION
           WHEN OTHERS THEN
           VL_ENTRA_COND:=0;
           END;
           --- VALIDA SI EL TRAMITE ES GRATIS PARA EL CAMPUS Y NIVEL ---------
           -------------------------------------------------------------------
           IF VL_ENTRA_COND_2 = 0 THEN

             BEGIN
               SELECT TBBDETC_DESC,TBBDETC_AMOUNT
                 INTO VL_DESC_CONTRA,VL_MONTO_TRAM
                 FROM TBBDETC
                WHERE TBBDETC_DETAIL_CODE = VL_CARGO_TRAM;
             EXCEPTION
             WHEN OTHERS THEN
             NULL;
             END;
--             DBMS_OUTPUT.PUT_LINE('vl_valida_tram 2<<<'||VL_DESC_CONTRA||'ZZZZZZZZZ'||VL_VALIDA_TRAM);

             BEGIN
               SELECT NVL (MAX(TBRACCD_TRAN_NUMBER) , 0)+1
                 INTO VL_TRANSACCION
                 FROM TBRACCD
                WHERE TBRACCD_PIDM =  PN_PIDM;
             EXCEPTION
             WHEN OTHERS THEN
             VL_TRANSACCION := 1;
             END;

             BEGIN
               SELECT COUNT (TBRACCD_DETAIL_CODE)
                 INTO VL_1SS
                 FROM TBRACCD
                WHERE     TBRACCD_PIDM = PN_PIDM
                      AND TBRACCD_DETAIL_CODE = VL_CARGO_TRAM
                      AND TBRACCD_USER =  'WWW_USER'
                      AND TBRACCD_TERM_CODE = PN_PERIODO;
             EXCEPTION
             WHEN OTHERS THEN
             VL_1SS:= 0;
             END;
             --- VALIDA SI YA EXISTE EL TRAMITE SOLICITADO POR EL AUTOSERVICIO ---
             ---------------------------------------------------------------------
             IF VL_1SS = 0 THEN

               BEGIN
                 INSERT
                   INTO TBRACCD
                 VALUES (
                         PN_PIDM,   -- TBRACCD_PIDM
                         VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                         PN_PERIODO,    -- TBRACCD_TERM_CODE
                         VL_CARGO_TRAM,     ---TBRACCD_DETAIL_CODE
                         USER,     ---TBRACCD_USER
                         SYSDATE,     --TBRACCD_ENTRY_DATE
                         VL_MONTO_TRAM,
                         VL_MONTO_TRAM,    ---TBRACCD_BALANCE
                         SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                         NULL,    --TBRACCD_BILL_DATE
                         NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                         VL_DESC_CONTRA,    -- TBRACCD_DESC
                         NULL,     --TBRACCD_RECEIPT_NUMBER
                         NULL,     --TBRACCD_TRAN_NUMBER_PAID
                         NULL,     --TBRACCD_CROSSREF_PIDM
                         NULL,    --TBRACCD_CROSSREF_NUMBER
                         NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                         'T',    --TBRACCD_SRCE_CODE
                         'Y',    --TBRACCD_ACCT_FEED_IND
                         SYSDATE,  --TBRACCD_ACTIVITY_DATE
                         0,        --TBRACCD_SESSION_NUMBER
                         NULL,    -- TBRACCD_CSHR_END_DATE
                         NULL,     --TBRACCD_CRN
                         NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                         NULL,     -- TBRACCD_LOC_MDT
                         NULL,     --TBRACCD_LOC_MDT_SEQ
                         NULL,     -- TBRACCD_RATE
                         NULL,     --TBRACCD_UNITS
                         NULL,     -- TBRACCD_DOCUMENT_NUMBER
                         SYSDATE,  -- TBRACCD_TRANS_DATE
                         NULL,        -- TBRACCD_PAYMENT_ID
                         NULL,     -- TBRACCD_INVOICE_NUMBER
                         NULL,     -- TBRACCD_STATEMENT_DATE
                         NULL,     -- TBRACCD_INV_NUMBER_PAID
                         'MXN',     -- TBRACCD_CURR_CODE
                         NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                         NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                         NULL,     -- TBRACCD_LATE_DCAT_CODE
                         PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                         NULL,     -- TBRACCD_FEED_DOC_CODE
                         NULL,     -- TBRACCD_ATYP_CODE
                         NULL,     -- TBRACCD_ATYP_SEQNO
                         NULL,     -- TBRACCD_CARD_TYPE_VR
                         NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                         NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                         NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                         NULL,     -- TBRACCD_ORIG_CHG_IND
                         NULL,     -- TBRACCD_CCRD_CODE
                         NULL,     -- TBRACCD_MERCHANT_ID
                         NULL,     -- TBRACCD_TAX_REPT_YEAR
                         NULL,     -- TBRACCD_TAX_REPT_BOX
                         NULL,     -- TBRACCD_TAX_AMOUNT
                         NULL,     -- TBRACCD_TAX_FUTURE_IND
                         'Banner',     -- TBRACCD_DATA_ORIGIN
                         'AUTOM',   -- TBRACCD_CREATE_SOURCE
                         NULL,     -- TBRACCD_CPDT_IND
                         NULL,     --TBRACCD_AIDY_CODE
                         PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                         VL_PARTE,     --TBRACCD_PERIOD
                         NULL,    --TBRACCD_SURROGATE_ID
                         NULL,     -- TBRACCD_VERSION
                         USER,     --TBRACCD_USER_ID
                         NULL );     --TBRACCD_VPDI_CODE
               EXCEPTION
               WHEN OTHERS THEN
               RAISE_APPLICATION_ERROR (-20002,'Contando BB'||SQLERRM||'<>'|| PN_CAMPUS||'<>'||PN_NIVEL||'<>'||PN_ESTATUS||'<>'||PN_PERIODO||'<>'||PN_FECHA_BAJA||'<>'||PN_FECHA_INICIO||'<>'||PN_FECHA_FIN||'<>'||PN_KEYSEQNO);
               END;

             END IF;

           ELSIF VL_ENTRA_COND_2 > 0 THEN

             BEGIN
               SELECT COUNT(ZSTPARA_PARAM_ID)
                 INTO VL_ENTRA_COND
                 FROM ZSTPARA
                WHERE     ZSTPARA_MAPA_ID = 'COND_TRAMI'
                      AND ZSTPARA_PARAM_ID = PN_ESTATUS;
             EXCEPTION
             WHEN OTHERS THEN
             VL_ENTRA_COND:=0;
             END;

             IF VL_ENTRA_COND >= 1 THEN

               BEGIN
                 SELECT (SUBSTR(PN_PERIODO,1,2)||ZSTPARA_PARAM_VALOR)
                   INTO VL_CONDONACION
                   FROM ZSTPARA
                  WHERE     ZSTPARA_MAPA_ID = 'COND_TRAMI'
                        AND ZSTPARA_PARAM_ID = PN_ESTATUS;
               EXCEPTION
               WHEN OTHERS THEN
               RAISE_APPLICATION_ERROR (-20002,'Contando vl_condonacion'||VL_CARGO_TRAM||'<>'||SQLERRM);
               END;

               BEGIN
                 SELECT COUNT(A.TBRACCD_DETAIL_CODE)
                   INTO VL_VALIDA_TRAM
                   FROM TBRACCD A
                  WHERE     A.TBRACCD_PIDM = PN_PIDM
                        AND SUBSTR(A.TBRACCD_DETAIL_CODE,3,2) IN ('AM','AO')
                        AND TBRACCD_USER != 'WWW_USER';
               EXCEPTION
               WHEN OTHERS THEN
               RAISE_APPLICATION_ERROR (-20002,'Contando vl_valida_tram'||VL_CARGO_TRAM||'<>'||SQLERRM);
               END;

--               DBMS_OUTPUT.PUT_LINE('vl_valida_tram 1 REZA<<<'||VL_VALIDA_TRAM);

               --- VALIDA SI ES SU PRIMER TRAMITE PARA CONDONAR ---------------------------
               -----------------------------------------------------------------------------

               IF VL_VALIDA_TRAM = 0 THEN

                 BEGIN
                   SELECT TBBDETC_DESC,TBBDETC_AMOUNT
                     INTO VL_DESC_CONTRA,VL_MONTO_TRAM
                     FROM TBBDETC
                    WHERE TBBDETC_DETAIL_CODE = VL_CARGO_TRAM;
                 EXCEPTION
                 WHEN OTHERS THEN
                 NULL;
                 END;

--                 DBMS_OUTPUT.PUT_LINE('vl_valida_tram 2<<<'||VL_DESC_CONTRA||'ZZZZZZZZZ'||VL_VALIDA_TRAM);

                 BEGIN
                   SELECT NVL (MAX(TBRACCD_TRAN_NUMBER) , 0)+1
                     INTO VL_TRANSACCION
                     FROM TBRACCD
                    WHERE TBRACCD_PIDM =  PN_PIDM;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_TRANSACCION := 1;
                 END;

                 BEGIN
                   SELECT COUNT (TBRACCD_DETAIL_CODE)
                     INTO VL_1SS
                     FROM TBRACCD
                    WHERE     TBRACCD_PIDM = PN_PIDM
                          AND TBRACCD_DETAIL_CODE = VL_CARGO_TRAM
                          AND TBRACCD_USER =  'WWW_USER'
                          AND TBRACCD_TERM_CODE = PN_PERIODO;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_1SS:= 0;
                 END;

                 --- VALIDA SI TIENE TRAMITE SOLICITADO POR EL AUTOSERVICIO-----------
                 ---------------------------------------------------------------------
                 IF VL_1SS = 0 THEN

                   BEGIN
                     SELECT COUNT (TBRACCD_DETAIL_CODE)
                       INTO VL_1SS_2
                       FROM TBRACCD
                      WHERE     TBRACCD_PIDM = PN_PIDM
                            AND TBRACCD_DETAIL_CODE = VL_CARGO_TRAM
                            AND TBRACCD_USER =  'WWW_USER';
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_1SS_2:= 0;
                   END;

                   IF VL_1SS_2 = 0 THEN

                     BEGIN
                       INSERT
                         INTO TBRACCD
                       VALUES (
                               PN_PIDM,   -- TBRACCD_PIDM
                               VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                               PN_PERIODO,    -- TBRACCD_TERM_CODE
                               VL_CARGO_TRAM,     ---TBRACCD_DETAIL_CODE
                               USER,     ---TBRACCD_USER
                               SYSDATE,     --TBRACCD_ENTRY_DATE
                               VL_MONTO_TRAM,
                               VL_MONTO_TRAM,    ---TBRACCD_BALANCE
                               SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                               NULL,    --TBRACCD_BILL_DATE
                               NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                               VL_DESC_CONTRA,    -- TBRACCD_DESC
                               NULL,     --TBRACCD_RECEIPT_NUMBER
                               NULL,     --TBRACCD_TRAN_NUMBER_PAID
                               NULL,     --TBRACCD_CROSSREF_PIDM
                               NULL,    --TBRACCD_CROSSREF_NUMBER
                               NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                               'T',    --TBRACCD_SRCE_CODE
                               'Y',    --TBRACCD_ACCT_FEED_IND
                               SYSDATE,  --TBRACCD_ACTIVITY_DATE
                               0,        --TBRACCD_SESSION_NUMBER
                               NULL,    -- TBRACCD_CSHR_END_DATE
                               NULL,     --TBRACCD_CRN
                               NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                               NULL,     -- TBRACCD_LOC_MDT
                               NULL,     --TBRACCD_LOC_MDT_SEQ
                               NULL,     -- TBRACCD_RATE
                               NULL,     --TBRACCD_UNITS
                               NULL,     -- TBRACCD_DOCUMENT_NUMBER
                               SYSDATE,  -- TBRACCD_TRANS_DATE
                               NULL,        -- TBRACCD_PAYMENT_ID
                               NULL,     -- TBRACCD_INVOICE_NUMBER
                               NULL,     -- TBRACCD_STATEMENT_DATE
                               NULL,     -- TBRACCD_INV_NUMBER_PAID
                               'MXN',     -- TBRACCD_CURR_CODE
                               NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                               NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                               NULL,     -- TBRACCD_LATE_DCAT_CODE
                               PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                               NULL,     -- TBRACCD_FEED_DOC_CODE
                               NULL,     -- TBRACCD_ATYP_CODE
                               NULL,     -- TBRACCD_ATYP_SEQNO
                               NULL,     -- TBRACCD_CARD_TYPE_VR
                               NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                               NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                               NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                               NULL,     -- TBRACCD_ORIG_CHG_IND
                               NULL,     -- TBRACCD_CCRD_CODE
                               NULL,     -- TBRACCD_MERCHANT_ID
                               NULL,     -- TBRACCD_TAX_REPT_YEAR
                               NULL,     -- TBRACCD_TAX_REPT_BOX
                               NULL,     -- TBRACCD_TAX_AMOUNT
                               NULL,     -- TBRACCD_TAX_FUTURE_IND
                               'Banner',     -- TBRACCD_DATA_ORIGIN
                               'AUTOM',   -- TBRACCD_CREATE_SOURCE
                               NULL,     -- TBRACCD_CPDT_IND
                               NULL,     --TBRACCD_AIDY_CODE
                               PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                               VL_PARTE,     --TBRACCD_PERIOD
                               NULL,    --TBRACCD_SURROGATE_ID
                               NULL,     -- TBRACCD_VERSION
                               USER,     --TBRACCD_USER_ID
                               NULL );     --TBRACCD_VPDI_CODE
                     EXCEPTION
                     WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR (-20002,'Contando BB'||SQLERRM||'<>'|| PN_CAMPUS||'<>'||PN_NIVEL||'<>'||PN_ESTATUS||'<>'||PN_PERIODO||'<>'||PN_FECHA_BAJA||'<>'||PN_FECHA_INICIO||'<>'||PN_FECHA_FIN||'<>'||PN_KEYSEQNO);
                     END;

--                     DBMS_OUTPUT.PUT_LINE('AQUI AQUI AQUI AQUI<<<'||VL_VALIDA_TRAM);

                     BEGIN
                       SELECT TBBDETC_DESC
                         INTO VL_CONDONACION_DESC
                         FROM TBBDETC
                        WHERE TBBDETC_DETAIL_CODE = VL_CONDONACION;
                     EXCEPTION
                     WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR (-20002,'Contando CC'||SQLERRM);
                     END;

                     VL_AJUSTE:= PKG_FINANZAS.SP_APLICA_AJUSTE ( PN_PIDM, VL_TRANSACCION, VL_CONDONACION, VL_MONTO_TRAM, PN_PERIODO, VL_CONDONACION_DESC, SYSDATE, PN_KEYSEQNO, PN_FECHA_INICIO, VL_PARTE, USER );

--                     DBMS_OUTPUT.PUT_LINE('AQUI VL_AJUSTE<<<'||VL_AJUSTE);

                   ELSIF VL_1SS_2 > 0 THEN

                     BEGIN
                       INSERT
                         INTO TBRACCD
                       VALUES (
                               PN_PIDM,   -- TBRACCD_PIDM
                               VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                               PN_PERIODO,    -- TBRACCD_TERM_CODE
                               VL_CARGO_TRAM,     ---TBRACCD_DETAIL_CODE
                               USER,     ---TBRACCD_USER
                               SYSDATE,     --TBRACCD_ENTRY_DATE
                               VL_MONTO_TRAM,
                               VL_MONTO_TRAM,    ---TBRACCD_BALANCE
                               SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                               NULL,    --TBRACCD_BILL_DATE
                               NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                               VL_DESC_CONTRA,    -- TBRACCD_DESC
                               NULL,     --TBRACCD_RECEIPT_NUMBER
                               NULL,     --TBRACCD_TRAN_NUMBER_PAID
                               NULL,     --TBRACCD_CROSSREF_PIDM
                               NULL,    --TBRACCD_CROSSREF_NUMBER
                               NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                               'T',    --TBRACCD_SRCE_CODE
                               'Y',    --TBRACCD_ACCT_FEED_IND
                               SYSDATE,  --TBRACCD_ACTIVITY_DATE
                               0,        --TBRACCD_SESSION_NUMBER
                               NULL,    -- TBRACCD_CSHR_END_DATE
                               NULL,     --TBRACCD_CRN
                               NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                               NULL,     -- TBRACCD_LOC_MDT
                               NULL,     --TBRACCD_LOC_MDT_SEQ
                               NULL,     -- TBRACCD_RATE
                               NULL,     --TBRACCD_UNITS
                               NULL,     -- TBRACCD_DOCUMENT_NUMBER
                               SYSDATE,  -- TBRACCD_TRANS_DATE
                               NULL,        -- TBRACCD_PAYMENT_ID
                               NULL,     -- TBRACCD_INVOICE_NUMBER
                               NULL,     -- TBRACCD_STATEMENT_DATE
                               NULL,     -- TBRACCD_INV_NUMBER_PAID
                               'MXN',     -- TBRACCD_CURR_CODE
                               NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                               NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                               NULL,     -- TBRACCD_LATE_DCAT_CODE
                               PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                               NULL,     -- TBRACCD_FEED_DOC_CODE
                               NULL,     -- TBRACCD_ATYP_CODE
                               NULL,     -- TBRACCD_ATYP_SEQNO
                               NULL,     -- TBRACCD_CARD_TYPE_VR
                               NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                               NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                               NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                               NULL,     -- TBRACCD_ORIG_CHG_IND
                               NULL,     -- TBRACCD_CCRD_CODE
                               NULL,     -- TBRACCD_MERCHANT_ID
                               NULL,     -- TBRACCD_TAX_REPT_YEAR
                               NULL,     -- TBRACCD_TAX_REPT_BOX
                               NULL,     -- TBRACCD_TAX_AMOUNT
                               NULL,     -- TBRACCD_TAX_FUTURE_IND
                               'Banner',     -- TBRACCD_DATA_ORIGIN
                               'AUTOM',   -- TBRACCD_CREATE_SOURCE
                               NULL,     -- TBRACCD_CPDT_IND
                               NULL,     --TBRACCD_AIDY_CODE
                               PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                               VL_PARTE,     --TBRACCD_PERIOD
                               NULL,    --TBRACCD_SURROGATE_ID
                               NULL,     -- TBRACCD_VERSION
                               USER,     --TBRACCD_USER_ID
                               NULL );     --TBRACCD_VPDI_CODE

--                              DBMS_OUTPUT.PUT_LINE('AQUI AQUI AQUI AQUI 1 <<<'||VL_VALIDA_TRAM);


                     EXCEPTION
                     WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR (-20002,'Contando BB'||SQLERRM||'<>'|| PN_CAMPUS||'<>'||PN_NIVEL||'<>'||PN_ESTATUS||'<>'||PN_PERIODO||'<>'||PN_FECHA_BAJA||'<>'||PN_FECHA_INICIO||'<>'||PN_FECHA_FIN||'<>'||PN_KEYSEQNO);
                     END;

                   END IF;

                 ELSIF VL_1SS > 0 THEN
                   --- VALIDA SI ES EL PRIMER TRAMITE SOLICITADO POR EL AUTOSERVICIO --
                   --------------------------------------------------------------------
                   BEGIN
                     SELECT COUNT(TBRACCD_DETAIL_CODE)
                       INTO VL_1SS_2
                       FROM TBRACCD
                      WHERE     TBRACCD_PIDM = PN_PIDM
                            AND TBRACCD_DETAIL_CODE = VL_CARGO_TRAM
                            AND TBRACCD_USER =  'WWW_USER';
                   EXCEPTION
                   WHEN OTHERS THEN
                   VL_1SS:= 0;
                   END;

                   IF VL_1SS = 1 THEN
                     --- VALIDA SI EL TRAMITE DEL AUTOSERVICIO TIENE CONDONACION -----
                     -----------------------------------------------------------------
                     BEGIN
                        SELECT NVL((SELECT TBRACCD_DETAIL_CODE
                                    FROM TBRACCD
                                    WHERE TBRACCD_PIDM = PPL.TBRAPPL_PIDM
                                    AND TBRACCD_TRAN_NUMBER = PPL.TBRAPPL_PAY_TRAN_NUMBER
                                    AND TBRACCD_DETAIL_CODE = VL_CONDONACION),'SIN AJUSTE')
                          INTO VL_1SS_PPL
                          FROM TBRAPPL PPL
                         WHERE     PPL.TBRAPPL_PIDM = PN_PIDM
                               AND PPL.TBRAPPL_CHG_TRAN_NUMBER = (SELECT TBRACCD_TRAN_NUMBER
                                                                    FROM TBRACCD
                                                                   WHERE     TBRACCD_PIDM = PPL.TBRAPPL_PIDM
                                                                         AND TBRACCD_DETAIL_CODE = VL_CARGO_TRAM
                                                                         AND TBRACCD_USER =  'WWW_USER')
                               AND PPL.TBRAPPL_ACTIVITY_DATE = (SELECT MAX(A1.TBRAPPL_ACTIVITY_DATE)
                                                                  FROM TBRAPPL A1
                                                                 WHERE A1.TBRAPPL_PIDM = PPL.TBRAPPL_PIDM
                                                                       AND A1.TBRAPPL_CHG_TRAN_NUMBER= PPL.TBRAPPL_CHG_TRAN_NUMBER);
                     EXCEPTION
                     WHEN OTHERS THEN
                     VL_1SS_PPL:= 'SIN AJUSTE';
                     END;

                     IF VL_1SS_PPL = 'SIN AJUSTE' THEN

                       BEGIN
                         SELECT TBRACCD_TRAN_NUMBER,TBRACCD_PERIOD
                           INTO VL_1SS_NUM,VL_1SS_PPER
                           FROM TBRACCD
                          WHERE     TBRACCD_PIDM = PN_PIDM
                                AND TBRACCD_DETAIL_CODE = VL_CARGO_TRAM
                                AND TBRACCD_USER =  'WWW_USER';
                       EXCEPTION
                       WHEN OTHERS THEN
                       VL_1SS_NUM:= NULL;
                       VL_1SS_PPER:= NULL;
                       END;

                       PKG_FINANZAS.P_DESAPLICA_PAGOS (PN_PIDM, VL_1SS_NUM);

                       BEGIN
                         SELECT TBBDETC_DESC
                           INTO VL_CONDONACION_DESC
                           FROM TBBDETC
                          WHERE TBBDETC_DETAIL_CODE = VL_CONDONACION;
                       EXCEPTION
                       WHEN OTHERS THEN
                       RAISE_APPLICATION_ERROR (-20002,'Contando CC'||SQLERRM);
                       END;

                       VL_AJUSTE:= PKG_FINANZAS.SP_APLICA_AJUSTE ( PN_PIDM,
                                                                   VL_1SS_NUM,
                                                                   VL_CONDONACION,
                                                                   VL_MONTO_TRAM,
                                                                   PN_PERIODO,
                                                                   VL_CONDONACION_DESC,
                                                                   SYSDATE,
                                                                   PN_KEYSEQNO,
                                                                   PN_FECHA_INICIO,
                                                                   VL_1SS_PPER,
                                                                   USER );

                     ELSE

                       BEGIN
                         INSERT
                           INTO TBRACCD
                         VALUES (
                                  PN_PIDM,   -- TBRACCD_PIDM
                                  VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                                  PN_PERIODO,    -- TBRACCD_TERM_CODE
                                  VL_CARGO_TRAM,     ---TBRACCD_DETAIL_CODE
                                  USER,     ---TBRACCD_USER
                                  SYSDATE,     --TBRACCD_ENTRY_DATE
                                  VL_MONTO_TRAM,
                                  VL_MONTO_TRAM,    ---TBRACCD_BALANCE
                                  SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                                  NULL,    --TBRACCD_BILL_DATE
                                  NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                                  VL_DESC_CONTRA,    -- TBRACCD_DESC
                                  NULL,     --TBRACCD_RECEIPT_NUMBER
                                  NULL,     --TBRACCD_TRAN_NUMBER_PAID
                                  NULL,     --TBRACCD_CROSSREF_PIDM
                                  NULL,    --TBRACCD_CROSSREF_NUMBER
                                  NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                                  'T',    --TBRACCD_SRCE_CODE
                                  'Y',    --TBRACCD_ACCT_FEED_IND
                                  SYSDATE,  --TBRACCD_ACTIVITY_DATE
                                  0,        --TBRACCD_SESSION_NUMBER
                                  NULL,    -- TBRACCD_CSHR_END_DATE
                                  NULL,     --TBRACCD_CRN
                                  NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                                  NULL,     -- TBRACCD_LOC_MDT
                                  NULL,     --TBRACCD_LOC_MDT_SEQ
                                  NULL,     -- TBRACCD_RATE
                                  NULL,     --TBRACCD_UNITS
                                  NULL,     -- TBRACCD_DOCUMENT_NUMBER
                                  SYSDATE,  -- TBRACCD_TRANS_DATE
                                  NULL,        -- TBRACCD_PAYMENT_ID
                                  NULL,     -- TBRACCD_INVOICE_NUMBER
                                  NULL,     -- TBRACCD_STATEMENT_DATE
                                  NULL,     -- TBRACCD_INV_NUMBER_PAID
                                  'MXN',     -- TBRACCD_CURR_CODE
                                  NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                                  NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                                  NULL,     -- TBRACCD_LATE_DCAT_CODE
                                  PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                                  NULL,     -- TBRACCD_FEED_DOC_CODE
                                  NULL,     -- TBRACCD_ATYP_CODE
                                  NULL,     -- TBRACCD_ATYP_SEQNO
                                  NULL,     -- TBRACCD_CARD_TYPE_VR
                                  NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                                  NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                                  NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                                  NULL,     -- TBRACCD_ORIG_CHG_IND
                                  NULL,     -- TBRACCD_CCRD_CODE
                                  NULL,     -- TBRACCD_MERCHANT_ID
                                  NULL,     -- TBRACCD_TAX_REPT_YEAR
                                  NULL,     -- TBRACCD_TAX_REPT_BOX
                                  NULL,     -- TBRACCD_TAX_AMOUNT
                                  NULL,     -- TBRACCD_TAX_FUTURE_IND
                                  'Banner',     -- TBRACCD_DATA_ORIGIN
                                  'AUTOM',   -- TBRACCD_CREATE_SOURCE
                                  NULL,     -- TBRACCD_CPDT_IND
                                  NULL,     --TBRACCD_AIDY_CODE
                                  PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                                  VL_PARTE,     --TBRACCD_PERIOD
                                  NULL,    --TBRACCD_SURROGATE_ID
                                  NULL,     -- TBRACCD_VERSION
                                  USER,     --TBRACCD_USER_ID
                                  NULL );     --TBRACCD_VPDI_CODE
                       EXCEPTION
                       WHEN OTHERS THEN
                       RAISE_APPLICATION_ERROR (-20002,'Contando BB'||SQLERRM||'<>'|| PN_CAMPUS||'<>'||PN_NIVEL||'<>'||PN_ESTATUS||'<>'||PN_PERIODO||'<>'||PN_FECHA_BAJA||'<>'||PN_FECHA_INICIO||'<>'||PN_FECHA_FIN||'<>'||PN_KEYSEQNO);
                       END;

                     END IF;
                   END IF;
                 END IF;

               ELSIF VL_VALIDA_TRAM > 0 THEN

--                 DBMS_OUTPUT.PUT_LINE('vl_valida_tram 1.1 <<<'||VL_VALIDA_TRAM);

                 BEGIN
                   SELECT TBBDETC_DESC,TBBDETC_AMOUNT
                     INTO VL_DESC_CONTRA,VL_MONTO_TRAM
                     FROM TBBDETC
                    WHERE TBBDETC_DETAIL_CODE = VL_CARGO_TRAM;
                 EXCEPTION
                 WHEN OTHERS THEN
                 RAISE_APPLICATION_ERROR (-20002,'Contando DD'||SQLERRM);
                 END;

--                 DBMS_OUTPUT.PUT_LINE('vl_valida_tram 2<<<'||VL_DESC_CONTRA);

                 BEGIN
                   SELECT NVL (MAX(TBRACCD_TRAN_NUMBER) , 0)+1
                     INTO VL_TRANSACCION
                     FROM TBRACCD
                    WHERE TBRACCD_PIDM =  PN_PIDM;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_TRANSACCION := 1;
                 END;

                 BEGIN
                   SELECT COUNT (TBRACCD_DETAIL_CODE)
                     INTO VL_1SS
                     FROM TBRACCD
                    WHERE     TBRACCD_PIDM = PN_PIDM
                          AND TBRACCD_DETAIL_CODE = VL_CARGO_TRAM
                          AND TBRACCD_USER =  'WWW_USER'
                          AND TBRACCD_TERM_CODE = PN_PERIODO;
                 EXCEPTION
                 WHEN OTHERS THEN
                 VL_1SS:= 0;
                 END;

                 IF VL_1SS = 0 THEN

                   BEGIN
                     INSERT
                       INTO TBRACCD
                     VALUES (
                              PN_PIDM,   -- TBRACCD_PIDM
                              VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                              PN_PERIODO,    -- TBRACCD_TERM_CODE
                              VL_CARGO_TRAM,     ---TBRACCD_DETAIL_CODE
                              USER,     ---TBRACCD_USER
                              SYSDATE,     --TBRACCD_ENTRY_DATE
                              VL_MONTO_TRAM,
                              VL_MONTO_TRAM,    ---TBRACCD_BALANCE
                              SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                              NULL,    --TBRACCD_BILL_DATE
                              NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                              VL_DESC_CONTRA,    -- TBRACCD_DESC
                              NULL,     --TBRACCD_RECEIPT_NUMBER
                              NULL,     --TBRACCD_TRAN_NUMBER_PAID
                              NULL,     --TBRACCD_CROSSREF_PIDM
                              NULL,    --TBRACCD_CROSSREF_NUMBER
                              NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                              'T',    --TBRACCD_SRCE_CODE
                              'Y',    --TBRACCD_ACCT_FEED_IND
                              SYSDATE,  --TBRACCD_ACTIVITY_DATE
                              0,        --TBRACCD_SESSION_NUMBER
                              NULL,    -- TBRACCD_CSHR_END_DATE
                              NULL,     --TBRACCD_CRN
                              NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                              NULL,     -- TBRACCD_LOC_MDT
                              NULL,     --TBRACCD_LOC_MDT_SEQ
                              NULL,     -- TBRACCD_RATE
                              NULL,     --TBRACCD_UNITS
                              NULL,     -- TBRACCD_DOCUMENT_NUMBER
                              SYSDATE,  -- TBRACCD_TRANS_DATE
                              NULL,        -- TBRACCD_PAYMENT_ID
                              NULL,     -- TBRACCD_INVOICE_NUMBER
                              NULL,     -- TBRACCD_STATEMENT_DATE
                              NULL,     -- TBRACCD_INV_NUMBER_PAID
                              'MXN',     -- TBRACCD_CURR_CODE
                              NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                              NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                              NULL,     -- TBRACCD_LATE_DCAT_CODE
                              PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                              NULL,     -- TBRACCD_FEED_DOC_CODE
                              NULL,     -- TBRACCD_ATYP_CODE
                              NULL,     -- TBRACCD_ATYP_SEQNO
                              NULL,     -- TBRACCD_CARD_TYPE_VR
                              NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                              NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                              NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                              NULL,     -- TBRACCD_ORIG_CHG_IND
                              NULL,     -- TBRACCD_CCRD_CODE
                              NULL,     -- TBRACCD_MERCHANT_ID
                              NULL,     -- TBRACCD_TAX_REPT_YEAR
                              NULL,     -- TBRACCD_TAX_REPT_BOX
                              NULL,     -- TBRACCD_TAX_AMOUNT
                              NULL,     -- TBRACCD_TAX_FUTURE_IND
                              'Banner',     -- TBRACCD_DATA_ORIGIN
                              'AUTOM',   -- TBRACCD_CREATE_SOURCE
                              NULL,     -- TBRACCD_CPDT_IND
                              NULL,     --TBRACCD_AIDY_CODE
                              PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                              VL_PARTE,     --TBRACCD_PERIOD
                              NULL,    --TBRACCD_SURROGATE_ID
                              NULL,     -- TBRACCD_VERSION
                              USER,     --TBRACCD_USER_ID
                              NULL );     --TBRACCD_VPDI_CODE
                   EXCEPTION
                   WHEN OTHERS THEN
                   RAISE_APPLICATION_ERROR (-20002,'Contando EE'||SQLERRM||'<>'|| PN_CAMPUS||'<>'||PN_NIVEL||'<>'||PN_ESTATUS||'<>'||PN_PERIODO||'<>'||PN_FECHA_BAJA||'<>'||PN_FECHA_INICIO||'<>'||PN_FECHA_FIN||'<>'||PN_KEYSEQNO);
                   END;
                 END IF;
               END IF;

             ELSIF VL_ENTRA_COND = 0 THEN

               BEGIN
                 SELECT TBBDETC_DESC,TBBDETC_AMOUNT
                   INTO VL_DESC_CONTRA,VL_MONTO_TRAM
                   FROM TBBDETC
                  WHERE TBBDETC_DETAIL_CODE = VL_CARGO_TRAM;
               EXCEPTION
               WHEN OTHERS THEN
               RAISE_APPLICATION_ERROR (-20002,'Contando FF'||SQLERRM);
               END;

--               DBMS_OUTPUT.PUT_LINE('vl_valida_tram 2<<<'||VL_DESC_CONTRA);

               BEGIN
                 SELECT NVL (MAX(TBRACCD_TRAN_NUMBER) , 0)+1
                   INTO VL_TRANSACCION
                   FROM TBRACCD
                  WHERE TBRACCD_PIDM =  PN_PIDM;
               EXCEPTION
               WHEN OTHERS THEN
               VL_TRANSACCION := 1;
               END;

               BEGIN
                 SELECT COUNT (TBRACCD_DETAIL_CODE)
                   INTO VL_1SS
                   FROM TBRACCD
                  WHERE     TBRACCD_PIDM = PN_PIDM
                        AND TBRACCD_DETAIL_CODE = VL_CARGO_TRAM
                        AND TBRACCD_USER =  'WWW_USER'
                        AND TBRACCD_TERM_CODE = PN_PERIODO;
               EXCEPTION
               WHEN OTHERS THEN
               VL_1SS:= 0;
               END;

               IF VL_1SS = 0 THEN

                 BEGIN
                   INSERT
                     INTO TBRACCD
                   VALUES (
                             PN_PIDM,   -- TBRACCD_PIDM
                             VL_TRANSACCION,     --TBRACCD_TRAN_NUMBER
                             PN_PERIODO,    -- TBRACCD_TERM_CODE
                             VL_CARGO_TRAM,     ---TBRACCD_DETAIL_CODE
                             USER,     ---TBRACCD_USER
                             SYSDATE,     --TBRACCD_ENTRY_DATE
                             VL_MONTO_TRAM,
                             VL_MONTO_TRAM,    ---TBRACCD_BALANCE
                             SYSDATE,     -- TBRACCD_EFFECTIVE_DATE
                             NULL,    --TBRACCD_BILL_DATE
                             NULL,    --TBRACCD_DUE_DATTBRACCD_UNITSTBRACCD_ACTIVITY_DATEE
                             VL_DESC_CONTRA,    -- TBRACCD_DESC
                             NULL,     --TBRACCD_RECEIPT_NUMBER
                             NULL,     --TBRACCD_TRAN_NUMBER_PAID
                             NULL,     --TBRACCD_CROSSREF_PIDM
                             NULL,    --TBRACCD_CROSSREF_NUMBER
                             NULL,       --TBRACCD_CROSSREF_DETAIL_CODE
                             'T',    --TBRACCD_SRCE_CODE
                             'Y',    --TBRACCD_ACCT_FEED_IND
                             SYSDATE,  --TBRACCD_ACTIVITY_DATE
                             0,        --TBRACCD_SESSION_NUMBER
                             NULL,    -- TBRACCD_CSHR_END_DATE
                             NULL,     --TBRACCD_CRN
                             NULL,     --TBRACCD_CROSSREF_SRCE_CODE
                             NULL,     -- TBRACCD_LOC_MDT
                             NULL,     --TBRACCD_LOC_MDT_SEQ
                             NULL,     -- TBRACCD_RATE
                             NULL,     --TBRACCD_UNITS
                             NULL,     -- TBRACCD_DOCUMENT_NUMBER
                             SYSDATE,  -- TBRACCD_TRANS_DATE
                             NULL,        -- TBRACCD_PAYMENT_ID
                             NULL,     -- TBRACCD_INVOICE_NUMBER
                             NULL,     -- TBRACCD_STATEMENT_DATE
                             NULL,     -- TBRACCD_INV_NUMBER_PAID
                             'MXN',     -- TBRACCD_CURR_CODE
                             NULL,     -- TBRACCD_EXCHANGE_DIFF   ----------******* Se gurada la referencia del cargo
                             NULL,    -- TBRACCD_FOREIGN_TBRACCD_EXCHANGE_DIFFTBRACCD_PAYMENT_IDAMOUNT
                             NULL,     -- TBRACCD_LATE_DCAT_CODE
                             PN_FECHA_INICIO,     -- TBRACCD_FEED_DATE
                             NULL,     -- TBRACCD_FEED_DOC_CODE
                             NULL,     -- TBRACCD_ATYP_CODE
                             NULL,     -- TBRACCD_ATYP_SEQNO
                             NULL,     -- TBRACCD_CARD_TYPE_VR
                             NULL,     -- TBRACCD_CARD_EXP_DATE_VR
                             NULL,     -- TBRACCD_CARD_AUTH_NUMBER_VR
                             NULL,     -- TBRACCD_CROSSREF_DCAT_CODE
                             NULL,     -- TBRACCD_ORIG_CHG_IND
                             NULL,     -- TBRACCD_CCRD_CODE
                             NULL,     -- TBRACCD_MERCHANT_ID
                             NULL,     -- TBRACCD_TAX_REPT_YEAR
                             NULL,     -- TBRACCD_TAX_REPT_BOX
                             NULL,     -- TBRACCD_TAX_AMOUNT
                             NULL,     -- TBRACCD_TAX_FUTURE_IND
                             'Banner',     -- TBRACCD_DATA_ORIGIN
                             'AUTOM',   -- TBRACCD_CREATE_SOURCE
                             NULL,     -- TBRACCD_CPDT_IND
                             NULL,     --TBRACCD_AIDY_CODE
                             PN_KEYSEQNO,     --TBRACCD_STSP_KEY_SEQUENCE
                             VL_PARTE,     --TBRACCD_PERIOD
                             NULL,    --TBRACCD_SURROGATE_ID
                             NULL,     -- TBRACCD_VERSION
                             USER,     --TBRACCD_USER_ID
                             NULL );     --TBRACCD_VPDI_CODE

                 EXCEPTION
                 WHEN OTHERS THEN
                 RAISE_APPLICATION_ERROR (-20002,'Contando GG'||SQLERRM||'<>'|| PN_CAMPUS||'<>'||PN_NIVEL||'<>'||PN_ESTATUS||'<>'||PN_PERIODO||'<>'||PN_FECHA_BAJA||'<>'||PN_FECHA_INICIO||'<>'||PN_FECHA_FIN||'<>'||PN_KEYSEQNO);
                 END;

               END IF;
             END IF;
           END IF;

         ELSIF PN_ESTATUS = 'BI' THEN ------INSERTA EL CARGO DE MES CONTENCION--03/01/2022 SE CAMBIO INDICADOR BI PARA EVITAR EL CARGO A SOLICITUD DE FINANZAS

--          DBMS_OUTPUT.PUT_LINE('MES CONTENCION VALIDACION '||PN_PIDM);

           BEGIN
             SELECT A.TBRACCD_AMOUNT
               INTO VL_MESCONTENCION
               FROM TBRACCD A
              WHERE     A.TBRACCD_PIDM = PN_PIDM
                    AND A.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                    FROM TBBDETC
                                                   WHERE     TBBDETC_DCAT_CODE = 'COL'
                                                         AND TBBDETC_DESC LIKE'COLEGIATURA %'
                                                         AND TBBDETC_DESC NOT LIKE'%NOTA%'
                                                         AND TBBDETC_DESC  != 'COLEGIATURA EXTRAORDINARIO')
                    AND A.TBRACCD_TRAN_NUMBER = (SELECT MAX (A1.TBRACCD_TRAN_NUMBER)
                                                   FROM TBRACCD A1
                                                  WHERE     A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                                                        AND A1.TBRACCD_DETAIL_CODE = A.TBRACCD_DETAIL_CODE);
           EXCEPTION
           WHEN OTHERS THEN
           VL_MESCONTENCION:= NULL;
           END;

--           DBMS_OUTPUT.PUT_LINE('MES CONTENCION VALIDACION 2 '||VL_MESCONTENCION);

           BEGIN
             SELECT DISTINCT SPRIDEN_ID
               INTO VL_MATRICULA
               FROM SPRIDEN
              WHERE     SPRIDEN_PIDM = PN_PIDM
                    AND SPRIDEN_CHANGE_IND IS NULL;
           EXCEPTION
           WHEN OTHERS THEN
           VL_MATRICULA:= 'ERROR';
           END;

           BEGIN
             SELECT DISTINCT SORLCUR_PROGRAM
               INTO VL_PROGR
               FROM SORLCUR A
              WHERE     A.SORLCUR_PIDM = PN_PIDM
                    AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                    AND A.SORLCUR_KEY_SEQNO = PN_KEYSEQNO;
           EXCEPTION
           WHEN OTHERS THEN
           VL_PROGR:= NULL;
           END;
           
           BEGIN         
             SELECT COUNT(ZSTPARA_PARAM_VALOR)
               INTO VL_MES_CONTE
               FROM ZSTPARA
              WHERE     ZSTPARA_MAPA_ID = 'MES_CONTE'
                    AND ZSTPARA_PARAM_ID = PN_CAMPUS
                    AND ZSTPARA_PARAM_VALOR = PN_NIVEL;
           EXCEPTION
           WHEN OTHERS THEN
           VL_MES_CONTE:=0;
           END;

--           DBMS_OUTPUT.PUT_LINE('MES CONTENCION VALIDACION 3 '||VL_MATRICULA||' =  '||VL_PROGR);

           IF VL_MESCONTENCION IS NOT NULL
              AND VL_MATRICULA != 'ERROR'AND VL_MES_CONTE >0 
              THEN

--             DBMS_OUTPUT.PUT_LINE('MES CONTENCION VALIDACION 3.1 '||VL_MATRICULA);
             BEGIN

               VL_FUNCION:= PKG_FINANZAS.FN_INSER_TRAM (VL_MATRICULA,
                                                        VL_MESCONTENCION,
                                                        SUBSTR(VL_MATRICULA,1,2)||'34',
                                                        'MES CONTENCION',
                                                        SYSDATE,
                                                        USER,
                                                        'CARGO MES CONTENCION BTI',
                                                        'MXN',
                                                        'SZFCABA',
                                                        VL_PROGR );

             END;
--             DBMS_OUTPUT.PUT_LINE('MES CONTENCION VALIDACION 4 '||SUBSTR(VL_MATRICULA,1,2)||'34');
           END IF;
         END IF;

       ELSE
         VL_ERROR := 'El Numero de Semanas cursadas por el alumno ('||VL_SEMANA ||') no esta dentro del Rango de Semanas para la aplicacion de la Baja configurada en SZFBAEC';
       END IF;

     ELSIF VL_SEMANA < 0 THEN
        VL_ERROR:= 'EXITO';
     ELSE
       VL_ERROR :='Fecha Inicio:'||PN_FECHA_INICIO||'. No Semanas:'||VL_SEMANA||'. No Existe la configuración para procesar esta baja por no contar con numero de semanas';
     END IF;

   ELSIF VL_EXI_CONF = 0 THEN
     VL_ERROR := 'No Existe la configuración para procesar esta baja Campus ' ||PN_CAMPUS ||' Nivel ' ||PN_NIVEL ||' Estatus3 '|| PN_ESTATUS ||' Programa '|| PN_PROGRAMA;
   END IF;

   VC_CONTA:=VC_CONTA+1;

--   DBMS_OUTPUT.PUT_LINE(VL_ERROR);

   IF PN_ESTATUS IN ('BD','BT','CV','BI','BA') THEN

     BEGIN
       DELETE GORADID
        WHERE GORADID_ADID_CODE = 'UTLX' AND GORADID_PIDM = PN_PIDM;
     END;

     BEGIN
        UPDATE SZTUTLX
           SET SZTUTLX_DISABLE_IND   = 'I',
               SZTUTLX_USER_UPDATE   = USER,
               SZTUTLX_DATE_UPDATE   = SYSDATE,
               SZTUTLX_STAT_IND      = 0,
               SZTUTLX_USER_BLOQUEO = 'pkg_abcc.baja_economica',
               SZTUTLX_ACTIVITY_BLOQUEO = sysdate
         WHERE     SZTUTLX_PIDM = PN_PIDM;
     END;

     BEGIN
       SELECT DISTINCT SPRIDEN_ID
         INTO VL_MATRICULA
         FROM SPRIDEN
        WHERE SPRIDEN_PIDM = PN_PIDM AND SPRIDEN_CHANGE_IND IS NULL;
     EXCEPTION
     WHEN OTHERS THEN
     VL_MATRICULA:= 'ERROR';
     END;

     VL_CART_UTL:= PKG_FINANZAS.F_MEMBRESIA_UTLX( VL_MATRICULA,
                                                  'CANCELA',
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL);

   END IF;

   IF VL_ERROR != 'EXITO' THEN
      ROLLBACK;
   ELSE
      COMMIT;
      EXIT;
   END IF;

 END LOOP;

RETURN VL_ERROR;
-- DBMS_OUTPUT.PUT_LINE(VL_ERROR);
END F_BAJA_ECONOMICA;


PROCEDURE ESTATUS_RAZON_PAGO (P_PIDM VARCHAR2,
                             P_ESTS_CODE_NEW VARCHAR2,
                             P_RAZON VARCHAR2,
                             f_fecha_inicio_nw VARCHAR2,
                             P_PROGRAMA VARCHAR2
                         )IS
                         
  lv_existe NUMBER;   
  vl_exito varchar2(500):= 'EXITO';      
  VL_TZTPUNI   NUMBER;  
  ------------
  P_PERIODO varchar2(6); 
  P_SP number;
  f_fecha_inicio_old varchar2(12):= null;
  p_comentario varchar2(500):= null;
  vl_periodo_act varchar2(6):= null;
  vl_periodo_nw varchar2(6):= null;
  vl_bandera varchar2(10):=null;
  vl_sec_act number;
             
                         
BEGIN
            Begin 

                    Select distinct SGBSTDN_TERM_CODE_EFF
                        Into P_PERIODO
                    from sgbstdn a
                    where 1= 1
                    and a.SGBSTDN_PIDM = p_pidm
                    and a.SGBSTDN_PROGRAM_1 = p_programa
                    And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)   
                                                    from sgbstdn a1
                                                    where 1= 1
                                                    and a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                    and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1);
            Exception
                When others then 
                    P_PERIODO:= null;
            End;




        --dbms_output.put_line(' Parametros de  Entrada Pidm: ' ||P_PIDM ||'P_ESTS_CODE_NEW: '||P_ESTS_CODE_NEW ||' P_RAZON: '||P_RAZON ||' f_fecha_inicio_nw: '||f_fecha_inicio_nw ||' Periodo: '||P_PERIODO);
        
        Begin
        
                select distinct sp
                    Into P_SP
                from tztprog a 
                where a.pidm = p_pidm
                and a.programa = p_programa
                and a.sp = (Select max (a1.sp)
                                    from tztprog a1
                                    where a.pidm = a1.pidm
                                    and a.programa = a1.programa);        
        Exception
            When Others then 
                P_SP := 1;
        End;        
        
        
        

            Begin

                        select distinct  to_char (SORLCUR_START_DATE,'dd/mm/rrrr')
                         Into f_fecha_inicio_old
                        FROM SORLCUR A
                        WHERE 1 = 1
                        and A.SORLCUR_PIDM = p_pidm
                        AND A.SORLCUR_PROGRAM =P_PROGRAMA
                        AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                        AND A.SORLCUR_ROLL_IND  = 'Y'
                        AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                        AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                                                   FROM SORLCUR A1
                                                                   WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                                  -- AND A1.SORLCUR_PROGRAM = A.SORLCUR_PROGRAM
                                                                   )  ;                                      
                                        
                                        
                                      
            Exception
                When others then 
                    f_fecha_inicio_old := null;
            End;

 --dbms_output.put_line('Dato Entrada ' ||P_SP||' '||f_fecha_inicio_old);

          IF (sb_enrollment.f_exists( P_PIDM  , P_PERIODO )<>'Y')  THEN
          
                                Begin 
          
                                --dbms_output.put_line('Entra1 ' ||vl_exito);                                        
                                
                                                INSERT INTO SFBETRM (
                                                             SFBETRM_TERM_CODE, SFBETRM_PIDM, SFBETRM_ESTS_CODE, SFBETRM_ESTS_DATE, SFBETRM_MHRS_OVER,
                                                             SFBETRM_AR_IND, SFBETRM_ASSESSMENT_DATE, SFBETRM_ADD_DATE, SFBETRM_ACTIVITY_DATE, SFBETRM_RGRE_CODE, 
                                                             SFBETRM_TMST_CODE, SFBETRM_TMST_DATE, SFBETRM_TMST_MAINT_IND, SFBETRM_USER, SFBETRM_REFUND_DATE, 
                                                             SFBETRM_DATA_ORIGIN, SFBETRM_INITIAL_REG_DATE, SFBETRM_MIN_HRS, SFBETRM_MINH_SRCE_CDE, SFBETRM_MAXH_SRCE_CDE,
                                                             SFBETRM_SURROGATE_ID, SFBETRM_VERSION, SFBETRM_USER_ID, SFBETRM_VPDI_CODE)
                                                VALUES ( P_PERIODO, P_PIDM ,  'EL'/*'EL'*/, SYSDATE, 999999.999, 
                                                         'N',  NULL,   SYSDATE,   SYSDATE, P_RAZON, 
                                                         '',   NULL,   '',  USER, NULL,
                                                         'SSB',   SYSDATE  , 0.000,  'M','M',
                                                           null, null, null, null);
                                                  --  Commit;
                                Exception
                                    When others then
                                        vl_exito:= 'Error al insertar en  SFBETRM ' || sqlerrm;       
                                        --dbms_output.put_line('error1 ' ||vl_exito);                   
                                End;
                                
                                If vl_exito ='EXITO' then
                                --dbms_output.put_line('Entra2 ' ||vl_exito);
                                
                                    Begin 
                                             INSERT INTO SFRENSP (SFRENSP_TERM_CODE, SFRENSP_PIDM,
                                                         SFRENSP_KEY_SEQNO, SFRENSP_ESTS_CODE, SFRENSP_ESTS_DATE,
                                                         SFRENSP_ADD_DATE, SFRENSP_ACTIVITY_DATE,
                                                         SFRENSP_USER, SFRENSP_DATA_ORIGIN, 
                                                         SFRENSP_SURROGATE_ID, SFRENSP_VERSION, SFRENSP_USER_ID, SFRENSP_VPDI_CODE)
                                            VALUES (P_PERIODO, P_PIDM , 
                                                        P_SP,  'EL'/* 'EL'*/,  SYSDATE,   
                                                        SYSDATE,  SYSDATE,     
                                                        USER , 'SSB',
                                                         null, null, null, null );
                                                        -- Commit;
                                    Exception
                                        When Others then 
                                          vl_exito:= 'Error al insertar en  SFRENSP ' || sqlerrm;            
                                          --dbms_output.put_line('error2 ' ||vl_exito);                     
                                    End;
                                                 
                                End if;
                            
          ELSE

                    --dbms_output.put_line('Entra 3 ');                 
                                FOR TRM IN (
                                                        SELECT C.SFBETRM_ESTS_DATE, C.SFBETRM_ADD_DATE, C.SFBETRM_ESTS_CODE, C.SFBETRM_TERM_CODE
                                                      FROM   SFBETRM C
                                                      WHERE  C.sfbetrm_pidm = P_PIDM
                                                      and c.SFBETRM_TERM_CODE = P_PERIODO

                               ) LOOP                              
                                            Begin 
                                                    Update SFBETRM
                                                    set SFBETRM_ESTS_CODE = 'EL'/*'EL'*/,
                                                        SFBETRM_RGRE_CODE =P_RAZON,
                                                        SFBETRM_ACTIVITY_DATE = SYSDATE,
                                                        SFBETRM_DATA_ORIGIN = 'SSB',
                                                        SFBETRM_USER_ID = USER
                                                    where SFBETRM_PIDM = P_PIDM
                                                    And SFBETRM_TERM_CODE = TRM.SFBETRM_TERM_CODE
                                                    And SFBETRM_ESTS_CODE = TRM.SFBETRM_ESTS_CODE;
                                                   -- Commit;
                                            Exception
                                                When  Others then 
                                                    null;
                                            End;
                                        
                                            Begin 
                                                    select count (*)
                                                        Into lv_existe
                                                    from SFRENSP
                                                    where SFRENSP_PIDM = P_PIDM
                                                    and SFRENSP_TERM_CODE = TRM.SFBETRM_TERM_CODE
                                                    And SFRENSP_KEY_SEQNO = P_SP;
                                                    
                                            Exception
                                                When Others then 
                                                  lv_existe:=0;  
                                            End;
                                       
                                            If lv_existe >= 1 then 
                                                  Begin
                                                          Update SFRENSP
                                                          set SFRENSP_ESTS_CODE = 'EL',/*'EL'*/
                                                              SFRENSP_ACTIVITY_DATE = SYSDATE,
                                                              SFRENSP_DATA_ORIGIN = 'SSB',
                                                              SFRENSP_USER_ID = USER
                                                          where SFRENSP_PIDM = P_PIDM
                                                          and SFRENSP_TERM_CODE = TRM.SFBETRM_TERM_CODE--CASE VN_INSERTA WHEN 1 THEN vc_periodo_horarios ELSE :MINI_PERFIL.PERIODO END
                                                          And SFRENSP_KEY_SEQNO = P_SP;
                                                         -- Commit;
                                                  Exception 
                                                  When Others then 
                                                    null;
                                                  End;
                                            Elsif lv_existe = 0 then 
                                                   Begin 
                                                          Insert into SFRENSP values (  TRM.SFBETRM_TERM_CODE,--CASE VN_INSERTA WHEN 1 THEN vc_periodo_horarios ELSE :MINI_PERFIL.PERIODO END,
                                                                                        P_PIDM, 
                                                                                        P_SP,
                                                                                        'EL',
                                                                                        TRM.SFBETRM_ESTS_DATE,--vd_ESTS_DATE,
                                                                                        TRM.SFBETRM_ADD_DATE,--vd_ADD_DATE,
                                                                                        sysdate,
                                                                                        user,--'MIGRA',
                                                                                        'SSB',--'UTEL',
                                                                                        null,
                                                                                        null,
                                                                                        user,--'MIGRA',
                                                                                        NULL);
                                                            --  Commit;
                                                   Exception
                                                    When Others then
                                                        null;                                     
                                                   End;
                                                   
                                            End if;
                               END LOOP;
                               
          END IF;
          

           vl_exito := pkg_abcc.f_baja_materias ('BI',
                                                  to_date (f_fecha_inicio_old,'dd/mm/rrrr'),
                                                  p_programa,
                                                  P_PIDM
                                                    );
       ---Commit;
           --dbms_output.put_line('baja_materia  '||vl_exito); 
          
          ----------- Cambio el estatus en SORLCUR -------------------------
          
          Begin 
           --dbms_output.put_line('Entra 4 ');            
          
                    UPDATE sorlcur 
                        SET sorlcur_start_date = to_date (f_fecha_inicio_nw,'dd/mm/rrrr'),
                               sorlcur_data_origin = 'SSB',
                               sorlcur_activity_date = SYSDATE,
                               sorlcur_user_id = USER
                    WHERE sorlcur_pidm = P_PIDM
                    AND sorlcur_program = P_PROGRAMA
                    AND sorlcur_lmod_code = 'LEARNER'
                    And trunc (sorlcur_start_date) = to_date (f_fecha_inicio_old,'dd/mm/rrrr');
                  --  Commit;
          Exception
            When Others then 
                null;       
                --dbms_output.put_line('Error 4 '||sqlerrm);              
          End;
    

                                             
----------------------------------- Hace el proceso de cancelacion de Financiera ---------------------------
 --dbms_output.put_line('Cancelacion Financiera ');        

      for cx in (
                                
                        SELECT DISTINCT
                               a.sfrstcr_pidm Pidm,
                               a.sfrstcr_term_code Periodo,
                               a.sfrstcr_ptrm_code Pperiodo,
                               SSBSECT_PTRM_START_DATE Fecha_Inicio,
                               ssbsect_ptrm_end_date Fecha_Fin,
                               a.sfrstcr_camp_code Campus,
                               a.sfrstcr_levl_code Nivel
                        FROM ssbsect, 
                             sfrstcr a
                        WHERE ssbsect_term_code = a.sfrstcr_term_code
                        AND ssbsect_crn = a.sfrstcr_crn
                        AND ssbsect_ptrm_code = a.sfrstcr_ptrm_code
                         and substr(a.sfrstcr_term_code,5,1) not in ('8','9')
                        --AND a.sfrstcr_stsp_key_sequence = P_SP
                        and trunc (SSBSECT_PTRM_START_DATE) = to_Date(f_fecha_inicio_old, 'dd/mm/yyyy')
                        AND a.sfrstcr_pidm = P_PIDM
                        AND a.sfrstcr_term_code =
                                               (SELECT MAX (b.sfrstcr_term_code)
                                                FROM sfrstcr b
                                                WHERE b.sfrstcr_pidm = a.sfrstcr_pidm
                                                And  b.sfrstcr_stsp_key_sequence = a.sfrstcr_stsp_key_sequence
                                                and substr(b.sfrstcr_term_code,5,1) not in ('8','9'))

        ) loop

              vl_exito:= 'EXITO';
              --dbms_output.put_line('Cancelacion Financiera Entra ');

                     vl_exito :=  pkg_finanzas.f_actu_tzfacce (
                                                                 p_pidm              => P_PIDM,
                                                                 p_periodo          => P_PERIODO,
                                                                 p_fecha_nueva   => to_date (f_fecha_inicio_nw,'dd/mm/rrrr'),
                                                                 p_fecha_old       => to_date (f_fecha_inicio_old,'dd/mm/rrrr'),
                                                                 p_per_nuevo      => P_PERIODO,
                                                                 p_programa       => P_PROGRAMA,
                                                                 p_campus          => cx.campus,
                                                                 p_nivel              => cx.nivel);
                                            --Commit;                                                         
                                            --dbms_output.put_line('salida facce  '||vl_exito);
                                                                                     
                     vl_exito:=PKG_FINANZAS_DINAMICOS.F_CAMBIO_FECHA_PADI ( P_PIDM, 
                                                                             P_PERIODO, 
                                                                             to_date (f_fecha_inicio_nw,'dd/mm/rrrr'),
                                                                             to_date (f_fecha_inicio_old,'dd/mm/rrrr'), 
                                                                             P_PERIODO, 
                                                                             P_PROGRAMA);
                                           --   Commit;       
                                            --dbms_output.put_line('salida dinamicoa  '||vl_exito);

                     vl_exito :=  pkg_abcc.f_baja_economica (
                                                               pn_pidm           => P_PIDM,
                                                               pn_campus       => cx.campus,
                                                               pn_nivel            => cx.nivel,
                                                               pn_estatus        => 'BI', 
                                                               pn_programa     => null, 
                                                               pn_periodo        => P_PERIODO,
                                                               pn_fecha_baja   => TO_DATE (SYSDATE,'dd/mm/rrrr'),
                                                               pn_fecha_inicio   => to_date (f_fecha_inicio_old,'dd/mm/rrrr'), 
                                                               pn_fecha_fin      => TO_DATE (SYSDATE,'dd/mm/rrrr'),
                                                               pn_keyseqno       => P_SP);

                                       -- Commit;
                                        --dbms_output.put_line('salida bajaeconomica  '||vl_exito);

                     IF vl_exito != 'EXITO' THEN
                            null;
                     ELSE

                            BEGIN
                                        UPDATE TZTORDR
                                        SET TZTORDR_ESTATUS       = 'N',
                                            TZTORDR_ACTIVITY_DATE = SYSDATE,
                                            TZTORDR_DATA_ORIGIN   = 'SSB',
                                            TZTORDR_USER          = USER
                                          WHERE TZTORDR_PIDM      = P_PIDM
                                           AND TZTORDR_CAMPUS     =  cx.campus
                                           AND TZTORDR_NIVEL      = cx.nivel
                                           AND TZTORDR_PROGRAMA   = P_PROGRAMA
                                           AND TZTORDR_CONTADOR   = (SELECT  MAX(SFRSTCR_VPDI_CODE)
                                                                     FROM SFRSTCR
                                                                     WHERE SFRSTCR_PIDM     =P_PIDM 
                                                                     and SFRSTCR_LEVL_CODE  = cx.nivel
                                                                     and SFRSTCR_CAMP_CODE  =cx.campus) ;
                                       --   Commit;
                            EXCEPTION WHEN OTHERS THEN
                                vl_exito:='Se presento un error al actualizar la Orden de Compra '|| sqlerrm;
                                --dbms_output.put_line('error 5  '||vl_exito);
                            END;
                            
                     /*  SE CANCELA EL AJUSTE DE PAGO UNICO PARA PARA CALCULAR NUEVA FECHA DE APLICACIÓN */


                             BEGIN
                                SELECT COUNT (*)
                                INTO vl_tztpuni
                                FROM tztpuni
                                WHERE tztpuni_pidm = P_PIDM
                                AND tztpuni_fecha_inicio =to_date (f_fecha_inicio_old,'dd/mm/rrrr')
                                AND tztpuni_chech_final IS NULL;                        
                             EXCEPTION WHEN OTHERS THEN
                                   vl_tztpuni := 0;
                             END;

                             IF vl_tztpuni > 0 THEN
                                vl_exito := pkg_finanzas.f_can_uni (P_PIDM, to_date (f_fecha_inicio_old,'dd/mm/rrrr'));
                                              --  Commit;

                                BEGIN
                                   UPDATE tztpuni 
                                    SET tztpuni_fecha_inicio = to_date (f_fecha_inicio_nw,'dd/mm/rrrr'),
                                           tztpuni_prox_fecha = NULL
                                    WHERE tztpuni_pidm =P_PIDM
                                    AND tztpuni_fecha_inicio = to_date (f_fecha_inicio_old,'dd/mm/rrrr')
                                    AND tztpuni_chech_final IS NULL;
                                  --  Commit;
                                Exception
                                    When others then 
                                         vl_exito:='Se presento un error al actualizar la Orden de Compra de Pago Unico '|| sqlerrm;   
                                END;
                                
                             END IF;                            
                            
                     


                     END IF;

        End Loop;
        
       --dbms_output.put_line('llega a Bitacora  '||vl_exito);
       
       p_comentario:=null;
        If P_RAZON ='CF' then  ---> Los comentarios se deben de crecer de acuerdo al tipo de servicio
              --dbms_output.put_line('Entra al comentario  '||p_comentario);
         p_comentario := 'Cambio de Fecha Solictado por el alumno SSB ' ||P_PERIODO ||
                                                                       '  '||P_PROGRAMA || ' Fecha de inicio anterior ' 
                                                                           || f_fecha_inicio_old || ' Fecha de inicio Nueva '
                                                                           || f_fecha_inicio_nw ;
                                                                                                           
       --     p_comentario := 'Cambio de Fecha Solictado por el alumno SSB ' ||P_PERIODO ||P_PROGRAMA || f_fecha_inicio_old|| f_fecha_inicio_nw ;                                                                                                           
                                                                                                           
                    --dbms_output.put_line('Salida a Comentario  '||p_comentario);                                                                                        
                                                                                                           
        End if;
        
        --dbms_output.put_line('llega a Comentario  '||p_comentario);
                                                                                                                    
        pkg_abcc.bitacora (P_PIDM, 
                                    P_PERIODO, 
                                    P_SP, 
                                    P_PROGRAMA, 
                                    p_comentario, 
                                    'SSB',
                                    f_fecha_inicio_old);   
        --  Commit;          
          
        vl_periodo_act:= null;  
        vl_sec_act := null;
        Begin 
                    Select distinct SORLCUR_TERM_CODE, SORLCUR_SEQNO
                        into vl_periodo_act, vl_sec_act
                    from sorlcur a
                    WHERE a.sorlcur_pidm = P_PIDM
                    AND a.sorlcur_program = P_PROGRAMA
                    AND a.sorlcur_lmod_code = 'LEARNER'
                    And trunc (a.sorlcur_start_date) = to_date (f_fecha_inicio_nw,'dd/mm/rrrr')
                    And a.SORLCUR_SEQNO in (select max (a1.SORLCUR_SEQNO)
                                                            from sorlcur a1
                                                            Where a.sorlcur_pidm = a1.sorlcur_pidm
                                                            and a.sorlcur_program = a1.sorlcur_program
                                                            And a.sorlcur_lmod_code = a1.sorlcur_lmod_code
                                                            And a.sorlcur_start_date = a1.sorlcur_start_date
                                                            );
         Exception
            When Others then
                    vl_periodo_act := null;
        End;
          
        vl_periodo_Nw:= null;
        Begin 
                Select distinct SZTPTRM_TERM_CODE
                    Into vl_periodo_Nw
                from SZTPTRM
                join SOBPTRM on SOBPTRM_TERM_CODE = SZTPTRM_TERM_CODE 
                      And SOBPTRM_PTRM_CODE = SZTPTRM_PTRM_CODE 
                where 1= 1
                And SZTPTRM_PROGRAM =  P_PROGRAMA
                And trunc (SOBPTRM_START_DATE)  = to_date (f_fecha_inicio_nw,'dd/mm/rrrr')
                And SZTPTRM_VISIBLE = 1;
        Exception
            When Others then 
                null;
        End;
         
        If vl_periodo_Nw != vl_periodo_Act then 
        
           vl_bandera:= null;
        
             Begin 
                   
                        Insert into SORLCUR
                                    Select distinct 
                                        SORLCUR_PIDM
                                        ,SORLCUR_SEQNO +1                 
                                        ,SORLCUR_LMOD_CODE            
                                        ,vl_periodo_Nw         
                                        ,SORLCUR_KEY_SEQNO         
                                        ,SORLCUR_PRIORITY_NO          
                                        ,SORLCUR_ROLL_IND             
                                        ,SORLCUR_CACT_CODE        
                                        ,user              
                                        ,'SSB'        
                                        ,sysdate   
                                        ,SORLCUR_LEVL_CODE         
                                        ,SORLCUR_COLL_CODE         
                                        ,SORLCUR_DEGC_CODE           
                                        ,SORLCUR_TERM_CODE_CTLG     
                                        ,SORLCUR_TERM_CODE_END     
                                        ,SORLCUR_TERM_CODE_MATRIC  
                                        ,SORLCUR_TERM_CODE_ADMIT  
                                        ,SORLCUR_ADMT_CODE           
                                        ,SORLCUR_CAMP_CODE         
                                        ,SORLCUR_PROGRAM              
                                        ,SORLCUR_START_DATE         
                                        ,SORLCUR_END_DATE             
                                        ,SORLCUR_CURR_RULE           
                                        ,SORLCUR_ROLLED_SEQNO         
                                        ,SORLCUR_STYP_CODE             
                                        ,SORLCUR_RATE_CODE            
                                        ,SORLCUR_LEAV_CODE             
                                        ,SORLCUR_LEAV_FROM_DATE       
                                        ,SORLCUR_LEAV_TO_DATE          
                                        ,SORLCUR_EXP_GRAD_DATE         
                                        ,SORLCUR_TERM_CODE_GRAD 
                                        ,SORLCUR_ACYR_CODE 
                                        ,SORLCUR_SITE_CODE  
                                        ,SORLCUR_APPL_SEQNO    
                                        ,SORLCUR_APPL_KEY_SEQNO  
                                        ,sysdate  
                                        ,sysdate 
                                        ,SORLCUR_GAPP_SEQNO    
                                        ,SORLCUR_CURRENT_CDE    
                                        ,null    
                                        ,null          
                                        ,SORLCUR_VPDI_CODE      
                                    from sorlcur a
                                    WHERE a.sorlcur_pidm = P_PIDM
                                    AND a.sorlcur_program = P_PROGRAMA
                                    AND a.sorlcur_lmod_code = 'LEARNER'
                                    And trunc (a.sorlcur_start_date) = to_date (f_fecha_inicio_nw,'dd/mm/rrrr')
                                    And a.SORLCUR_SEQNO in (select max (a1.SORLCUR_SEQNO)
                                                                            from sorlcur a1
                                                                            Where a.sorlcur_pidm = a1.sorlcur_pidm
                                                                            and a.sorlcur_program = a1.sorlcur_program
                                                                            And a.sorlcur_lmod_code = a1.sorlcur_lmod_code
                                                                            And a.sorlcur_start_date = a1.sorlcur_start_date
                                                                            );  
                          vl_bandera:= 'EXITO';                                                                                                       
             Exception
                When Others then 
                    vl_bandera:= 'ERROR';                                            
             End;
             
             If vl_bandera = 'EXITO' then 
                 Begin 
                        Update sorlcur a
                        set SORLCUR_ROLL_IND = 'N',
                              SORLCUR_CACT_CODE = 'INACTIVE'
                        WHERE a.sorlcur_pidm = P_PIDM
                        AND a.sorlcur_program = P_PROGRAMA
                        AND a.sorlcur_lmod_code = 'LEARNER'
                        And a.SORLCUR_SEQNO = vl_sec_act
                        and SORLCUR_TERM_CODE = vl_periodo_Act;
                        
                        vl_bandera:= 'EXITO';
                 Exception
                    When Others then 
                         vl_bandera:= 'ERROR';               
                 End;
             End if;
             
             If vl_bandera = 'EXITO' then 
                 Begin 
                        Insert into SORLFOS
                        Select distinct 
                        SORLFOS_PIDM
                        ,SORLFOS_LCUR_SEQNO+1
                        ,SORLFOS_SEQNO
                        ,SORLFOS_LFST_CODE 
                        ,vl_periodo_Nw 
                        ,SORLFOS_PRIORITY_NO 
                        ,SORLFOS_CSTS_CODE 
                        ,SORLFOS_CACT_CODE
                        ,'SSB'
                        ,user 
                        ,sysdate  
                        ,SORLFOS_MAJR_CODE   
                        ,SORLFOS_TERM_CODE_CTLG 
                        ,SORLFOS_TERM_CODE_END 
                        ,SORLFOS_DEPT_CODE        
                        ,SORLFOS_MAJR_CODE_ATTACH  
                        ,SORLFOS_LFOS_RULE     
                        ,SORLFOS_CONC_ATTACH_RULE    
                        ,SORLFOS_START_DATE      
                        ,SORLFOS_END_DATE           
                        ,SORLFOS_TMST_CODE         
                        ,SORLFOS_ROLLED_SEQNO      
                        ,user    
                        ,sysdate 
                        ,SORLFOS_CURRENT_CDE    
                        ,null      
                        ,SORLFOS_VERSION       
                        ,SORLFOS_VPDI_CODE       
                        from sorlfos
                        where 1= 1
                        and sorlfos_pidm = P_PIDM
                        And SORLFOS_LCUR_SEQNO = vl_sec_act 
                        ;
                        vl_bandera:= 'EXITO';
                 Exception
                    When Others then 
                         vl_bandera:= 'ERROR';               
                 End;
             End if;             
             
             If vl_bandera = 'EXITO' then 
                 Begin 
                        Update SORLFOS a
                        set SORLFOS_CACT_CODE = 'INACTIVE',
                              SORLFOS_DATA_ORIGIN = 'SSB',
                              SORLFOS_USER_ID = user,
                              SORLFOS_ACTIVITY_DATE = sysdate,
                              SORLFOS_USER_ID_UPDATE = user,
                              SORLFOS_ACTIVITY_DATE_UPDATE = sysdate
                        WHERE 1=1
                        and sorlfos_pidm = P_PIDM
                        And SORLFOS_LCUR_SEQNO = vl_sec_act 
                        ;
                        vl_bandera:= 'EXITO';
                 Exception
                    When Others then 
                         vl_bandera:= 'ERROR';               
                 End;
             End if;             
        
        End if; 
          
        
        Begin 
                select distinct SGBSTDN_TERM_CODE_EFF
                    Into vl_periodo_Act
                from sgbstdn a
                where 1=1
                and a.SGBSTDN_PIDM = P_PIDM
                And a.SGBSTDN_PROGRAM_1  = P_PROGRAMA
                And a.SGBSTDN_TERM_CODE_EFF =  (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                         from SGBSTDN a1
                                                                         Where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                         And a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1)  ;     
        Exception
            When Others then 
                vl_periodo_Act:= null;
        End;
        
        If vl_periodo_Nw != vl_periodo_Act then 
            Begin
                    Insert into SGBSTDN 
                    select   SGBSTDN_PIDM                
                    ,vl_periodo_Nw    
                    ,SGBSTDN_STST_CODE           
                    ,SGBSTDN_LEVL_CODE        
                    ,SGBSTDN_STYP_CODE            
                    ,SGBSTDN_TERM_CODE_MATRIC    
                    ,SGBSTDN_TERM_CODE_ADMIT      
                    ,SGBSTDN_EXP_GRAD_DATE     
                    ,SGBSTDN_CAMP_CODE            
                    ,SGBSTDN_FULL_PART_IND       
                    ,SGBSTDN_SESS_CODE           
                    ,SGBSTDN_RESD_CODE            
                    ,SGBSTDN_COLL_CODE_1         
                    ,SGBSTDN_DEGC_CODE_1           
                    ,SGBSTDN_MAJR_CODE_1         
                    ,SGBSTDN_MAJR_CODE_MINR_1      
                    ,SGBSTDN_MAJR_CODE_MINR_1_2    
                    ,SGBSTDN_MAJR_CODE_CONC_1     
                    ,SGBSTDN_MAJR_CODE_CONC_1_2   
                    ,SGBSTDN_MAJR_CODE_CONC_1_3    
                    ,SGBSTDN_COLL_CODE_2           
                    ,SGBSTDN_DEGC_CODE_2         
                    ,SGBSTDN_MAJR_CODE_2          
                    ,SGBSTDN_MAJR_CODE_MINR_2     
                    ,SGBSTDN_MAJR_CODE_MINR_2_2    
                    ,SGBSTDN_MAJR_CODE_CONC_2      
                    ,SGBSTDN_MAJR_CODE_CONC_2_2    
                    ,SGBSTDN_MAJR_CODE_CONC_2_3    
                    ,SGBSTDN_ORSN_CODE             
                    ,SGBSTDN_PRAC_CODE             
                    ,SGBSTDN_ADVR_PIDM             
                    ,SGBSTDN_GRAD_CREDIT_APPR_IND  
                    ,SGBSTDN_CAPL_CODE             
                    ,SGBSTDN_LEAV_CODE             
                    ,SGBSTDN_LEAV_FROM_DATE       
                    ,SGBSTDN_LEAV_TO_DATE         
                    ,SGBSTDN_ASTD_CODE            
                    ,SGBSTDN_TERM_CODE_ASTD        
                    ,SGBSTDN_RATE_CODE             
                    ,sysdate         
                    ,SGBSTDN_MAJR_CODE_1_2        
                    ,SGBSTDN_MAJR_CODE_2_2         
                    ,SGBSTDN_EDLV_CODE            
                    ,SGBSTDN_INCM_CODE            
                    ,SGBSTDN_ADMT_CODE             
                    ,SGBSTDN_EMEX_CODE             
                    ,SGBSTDN_APRN_CODE            
                    ,SGBSTDN_TRCN_CODE            
                    ,SGBSTDN_GAIN_CODE            
                    ,SGBSTDN_VOED_CODE             
                    ,SGBSTDN_BLCK_CODE            
                    ,SGBSTDN_TERM_CODE_GRAD      
                    ,SGBSTDN_ACYR_CODE           
                    ,SGBSTDN_DEPT_CODE           
                    ,SGBSTDN_SITE_CODE           
                    ,SGBSTDN_DEPT_CODE_2           
                    ,SGBSTDN_EGOL_CODE           
                    ,SGBSTDN_DEGC_CODE_DUAL      
                    ,SGBSTDN_LEVL_CODE_DUAL     
                    ,SGBSTDN_DEPT_CODE_DUAL    
                    ,SGBSTDN_COLL_CODE_DUAL       
                    ,SGBSTDN_MAJR_CODE_DUAL   
                    ,SGBSTDN_BSKL_CODE         
                    ,SGBSTDN_PRIM_ROLL_IND      
                    ,SGBSTDN_PROGRAM_1          
                    ,SGBSTDN_TERM_CODE_CTLG_1     
                    ,SGBSTDN_DEPT_CODE_1_2      
                    ,SGBSTDN_MAJR_CODE_CONC_121  
                    ,SGBSTDN_MAJR_CODE_CONC_122  
                    ,SGBSTDN_MAJR_CODE_CONC_123  
                    ,SGBSTDN_SECD_ROLL_IND     
                    ,SGBSTDN_TERM_CODE_ADMIT_2   
                    ,SGBSTDN_ADMT_CODE_2      
                    ,SGBSTDN_PROGRAM_2          
                    ,SGBSTDN_TERM_CODE_CTLG_2   
                    ,SGBSTDN_LEVL_CODE_2      
                    ,SGBSTDN_CAMP_CODE_2        
                    ,SGBSTDN_DEPT_CODE_2_2     
                    ,SGBSTDN_MAJR_CODE_CONC_221   
                    ,SGBSTDN_MAJR_CODE_CONC_222   
                    ,SGBSTDN_MAJR_CODE_CONC_223   
                    ,SGBSTDN_CURR_RULE_1         
                    ,SGBSTDN_CMJR_RULE_1_1       
                    ,SGBSTDN_CCON_RULE_11_1     
                    ,SGBSTDN_CCON_RULE_11_2    
                    ,SGBSTDN_CCON_RULE_11_3     
                    ,SGBSTDN_CMJR_RULE_1_2       
                    ,SGBSTDN_CCON_RULE_12_1    
                    ,SGBSTDN_CCON_RULE_12_2     
                    ,SGBSTDN_CCON_RULE_12_3    
                    ,SGBSTDN_CMNR_RULE_1_1     
                    ,SGBSTDN_CMNR_RULE_1_2      
                    ,SGBSTDN_CURR_RULE_2        
                    ,SGBSTDN_CMJR_RULE_2_1       
                    ,SGBSTDN_CCON_RULE_21_1     
                    ,SGBSTDN_CCON_RULE_21_3     
                    ,SGBSTDN_CCON_RULE_21_2     
                    ,SGBSTDN_CMJR_RULE_2_2       
                    ,SGBSTDN_CCON_RULE_22_1     
                    ,SGBSTDN_CCON_RULE_22_2      
                    ,SGBSTDN_CCON_RULE_22_3     
                    ,SGBSTDN_CMNR_RULE_2_1      
                    ,SGBSTDN_CMNR_RULE_2_2      
                    ,SGBSTDN_PREV_CODE            
                    ,SGBSTDN_TERM_CODE_PREV     
                    ,SGBSTDN_CAST_CODE           
                    ,SGBSTDN_TERM_CODE_CAST    
                    ,'SSB'        
                    ,user             
                    ,SGBSTDN_SCPC_CODE           
                    ,null      
                    ,SGBSTDN_VERSION             
                    ,SGBSTDN_VPDI_CODE        
                    from sgbstdn a
                    where 1=1
                    and a.SGBSTDN_PIDM = P_PIDM
                    And a.SGBSTDN_PROGRAM_1  = P_PROGRAMA
                    And a.SGBSTDN_TERM_CODE_EFF =  (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                             from SGBSTDN a1
                                                                             Where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                             And a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1)  ;                 
                    vl_bandera:= 'EXITO';
                 Exception
                    When Others then 
                         vl_bandera:= 'ERROR';               
                 End;
        
        
        End if;          
                                    
        
--        If vl_exito ='EXITO' then 
--           Commit;
--        Else
--            rollback;
--       End if;                                      

    
END ESTATUS_RAZON_PAGO;

PROCEDURE EJECUTA_MASIVO_PAGO IS 


     Begin 
     
           For cx in (
           
                        SElect SVRSVPR_ACCD_TRAN_NUMBER Transaccion, SVRSVPR_PIDM Pidm, SVRSVPR_SRVS_CODE Estatus, 
                               SVRSVPR_PROTOCOL_SEQ_NO Tramite, tbraccd_amount Monto, tbraccd_balance Balance, SVRSVPR_SRVC_CODE Servicio, 
                               (
                                select sum (TBRAPPL_AMOUNT) monto
                                                from tbrappl
                                                where 1= 1
                                                And tbrappl_pidm = SVRSVPR_PIDM
                                                and TBRAPPL_CHG_TRAN_NUMBER = SVRSVPR_ACCD_TRAN_NUMBER
                                                and (tbrappl_pidm, TBRAPPL_PAY_TRAN_NUMBER ) in (select tbraccd_pidm, TBRACCD_TRAN_NUMBER
                                                                                                                                 from tbraccd, TZTNCD 
                                                                                                                                 where tbraccd_detail_code = TZTNCD_CODE
                                                                                                                                 And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion', 'Financieras')) 
                                                and TBRAPPL_REAPPL_IND is null
                               ) Pago,
                               b.SVRSVAD_ADDL_DATA_CDE Programa, c.SVRSVAD_ADDL_DATA_CDE Fecha_Inicio
                        from SVRSVPR
                        join tbraccd on tbraccd_pidm = SVRSVPR_PIDM and SVRSVPR_ACCD_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                        left join SVRSVAD b on b.SVRSVAD_PROTOCOL_SEQ_NO = SVRSVPR_PROTOCOL_SEQ_NO and b.SVRSVAD_ADDL_DATA_SEQ = 1
                        left join SVRSVAD c on c.SVRSVAD_PROTOCOL_SEQ_NO = SVRSVPR_PROTOCOL_SEQ_NO and c.SVRSVAD_ADDL_DATA_SEQ  = 6
                        where SVRSVPR_SRVC_CODE in ('CAFE', 'CACI')
                        And SVRSVPR_PROTOCOL_AMOUNT > 0
                        And SVRSVPR_SRVS_CODE in ('CL', 'PA')
                        And trunc (SVRSVPR_ACTIVITY_DATE) = trunc (sysdate)
                        And SVRSVPR_VPDI_CODE is null

     
            ) loop




                 If cx.monto = cx.PAGO then ------> Valida que este pagado con Dinero 
                 


                     If cx.programa is not null and cx.fecha_inicio is not null then 
                     
                     --   dbms_output.put_line('Entra al Proceso de Baja  ');
                 
                             BANINST1.PKG_ABCC.ESTATUS_RAZON_PAGO ( P_PIDM              => cx.pidm,
                                                                    P_ESTS_CODE_NEW     => 'DD',
                                                                    P_RAZON             => cx.Servicio,
                                                                    F_FECHA_INICIO_NW   => cx.fecha_inicio,
                                                                    P_PROGRAMA          => cx.programa);
                            
                              Begin
                                    Update SVRSVPR
                                    set SVRSVPR_VPDI_CODE = 'AP'
                                    where 1=1
                                    And SVRSVPR.SVRSVPR_PIDM = cx.pidm 
                                    And SVRSVPR_ACCD_TRAN_NUMBER = cx.TRANSACCION
                                    And SVRSVPR_PROTOCOL_SEQ_NO = cx.tramite;
                              Exception
                                When Others then 
                                    null;
                              End;                                         
                                                                    
                                                                    
                     End if;
                      
                 
                 End if ;
                 
                 
        End Loop;
        Commit;
    End EJECUTA_MASIVO_PAGO;




end pkg_abcc;
/

DROP PUBLIC SYNONYM PKG_ABCC;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ABCC FOR BANINST1.PKG_ABCC;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_ABCC TO PUBLIC;
