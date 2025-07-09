DROP PACKAGE BODY BANINST1.PKG_ALUMNO_SIU;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_alumno_siu as

procedure p_log(p_fecha_inicio date, 
                p_campus varchar2 , 
                p_nivel varchar2, 
                p_term_code varchar2,  
                p_pidm  number,
                p_text  varchar2) as
begin

    null;
--    BEgin 
--        Insert into sztbsiu values (
--                SEQ_SZTBSIU.NextVal,
--                p_pidm, p_campus, p_nivel,p_term_code,
--                p_text,user,sysdate);
--        Commit;
--    Exception When Others Then Null;
--    End;
end;                


--Consulta Regla Maxima donde el alumno está parado con respecto fecha inicio
function f_consulta_regla(p_fecha_inicio in out date, 
                            p_campus varchar2 , 
                            p_nivel varchar2, 
                            p_term_code varchar2,  
                            p_ptrm_code varchar2,  
                            p_pidm  number) return number as              
    l_retorna number;
    l_fecha_ini date;
    
    lc_ptrm_code varchar2(10);
    lc_periodo_code varchar2(20);
    

begin                   

    FOR c IN (
               SELECT DISTINCT
                              sfrstcr_term_code periodo,
                              sfrstcr_ptrm_code ptrm,
                              ssbsect_ptrm_start_date fecha_ini
    --                                                              sfrstcr_stsp_key_sequence sp 
    --                                                              study_path
                FROM ssbsect a,
                     sfrstcr c,
                     shrgrde
                WHERE 1 = 1
                AND ssbsect_term_code = sfrstcr_term_code
                and sfrstcr_pidm=p_pidm
                AND c.sfrstcr_crn = ssbsect_crn
                AND c.sfrstcr_levl_code = shrgrde_levl_code
                AND (c.sfrstcr_grde_code = shrgrde_code
                                                    OR c.sfrstcr_grde_code IS NULL)
                AND a.ssbsect_ptrm_start_date IN
                                                 (SELECT MAX (a1.ssbsect_ptrm_start_date)
                                                  FROM SSBSECT a1
                                                  WHERE 1 = 1
                                                  AND a1.ssbsect_term_code = a.ssbsect_term_code
                                                  AND a1.ssbsect_crn =a.ssbsect_crn)
                and c.sfrstcr_term_code = (SElect MAx(x.sfrstcr_term_code) from sfrstcr x where x.sfrstcr_pidm = c.sfrstcr_pidm
                                            and substr(x.sfrstcr_term_code,5,1) not in (8,9) --quitamos nivelaciones
                                            )
                Order by ssbsect_ptrm_start_date desc 
    )
    LOOP
        lc_ptrm_code := c.ptrm;
        lc_periodo_code := c.periodo;
        dbms_output.put_line('Obtiene periodo actual del alumno:'||lc_periodo_code||' ptrm:'||lc_ptrm_code);
        exit;
    END LOOP;




    begin   
    
            Select mAX(sztalgo_no_regla), Max(sztalgo_fecha_new)
            into l_retorna, p_fecha_inicio
            from sztalgo
            Where  sztalgo_camp_code = p_campus
            and sztalgo_levl_code = p_nivel
            and sztalgo_term_code = lc_periodo_code
            and sztalgo_ptrm_code = lc_ptrm_code
            and SZTALGO_FECHA_INICIO_INSC is not null
            and SZTALGO_FECHA_FIN_INSC is not null
            and NVL(sztalgo_estatus_cerrado,'N') = 'N'
            and trunc(sysdate) between SZTALGO_FECHA_INICIO_INSC and SZTALGO_FECHA_FIN_INSC;
        
    exception when others then
           l_retorna:=99; p_fecha_inicio:=to_date('01/01/1999','dd/mm/yyyy');
    end;   
    
    p_log(p_fecha_inicio,p_campus,p_nivel,p_term_code,p_pidm,'Encontro regla max:'||l_retorna||' con fecha inicio:'||p_fecha_inicio||
                ' periodo actual del alumno:'||lc_periodo_code||' ptrm:'||lc_ptrm_code);
    
    return(l_retorna);
    
    
end f_consulta_regla;

--Baja Dashboard del alumno por el momento no se usa.
Procedure p_baja_dashboard(p_regla number, p_pidm number, p_campus varchar2, p_nivel varchar2 ) is

lc_programa sorlcur.Sorlcur_Program%Type;


Cursor cur_secuencia is
    WITH secuencia
         AS (  SELECT DISTINCT
                               smrpcmt_program AS programa,
                               smrpcmt_term_code_eff periodo,
                               REGEXP_SUBSTR (smrpcmt_text,'[^|"]+',1,1)AS id_materia,
                               TO_NUMBER (smrpcmt_text_seqno)AS id_secuencia,
                               NVL (sztmaco_matpadre,REGEXP_SUBSTR (smrpcmt_text,'[^|"]+',1,1))id_materia_gpo
                FROM smrpcmt,
                     sztmaco
                WHERE  1 = 1
                AND smrpcmt_text IS NOT NULL
                AND REGEXP_SUBSTR (smrpcmt_text,'[^|"]+',1,1) = sztmaco_mathijo(+)
                AND smrpcmt_program = lc_programa
                ORDER BY 4
              )
              SELECT DISTINCT fal.per,
                              fal.area,
                              fal.materia,
                              fal.nombre_mat,
                              fal.califica,
                              fal.tipo,
                              fal.pidm,
                              fal.matricula,
                              TO_NUMBER (sec.id_secuencia) id_secuencia,
                              fal.materia_padre,
                              rul.smrarul_subj_code subj,
                              rul.smrarul_crse_numb_low crse,
                              p_campus campus,
                              p_nivel nivel,
                              p_regla,
                              0 l_sp,
                              fal.aprobadas_curr,
                              fal.curso_curr,
                              fal.total_curr
                FROM tmp_valida_faltantes fal
                JOIN secuencia sec ON fal.programa = sec.Programa
                                   AND fal.materia_padre = sec.id_materia_gpo
                                   AND lc_programa = SEC.periodo
                JOIN smrarul rul ON  rul.smrarul_subj_code|| rul.smrarul_crse_numb_low = fal.materia
                        and smrarul_area=fal.area
                WHERE 1 = 1
                AND fal.PIDM = p_pidm
                AND fal.programa = lc_programa
                AND regla = p_regla
                AND materia NOT LIKE 'SESO%'
                AND materia NOT LIKE 'OPT%'
                ORDER BY 9;
                
begin    
      BEGIN

         DELETE materia_faltante_lic
         WHERE regla = p_regla
         and pidm = p_pidm;

         DELETE saturn.tmp_valida_faltantes
         WHERE regla = p_regla
         and pidm = p_pidm;

         COMMIT;
      END;
              

        --GetPrograma
        Begin 
            Select Distinct A.Sorlcur_Program Programa
                Into lc_programa 
                from sorlcur A,
                    SGBSTDN  B
                where  A.SORLCUR_LMOD_CODE = 'LEARNER'
                and A.sorlcur_pidm=p_pidm
                and b.SGBSTDN_PIDM=sorlcur_pidm
                and B.SGBSTDN_STST_CODE = 'MA'
                       AND A.SORLCUR_PIDM = B.SGBSTDN_PIDM
                       AND A.SORLCUR_PROGRAM = B.SGBSTDN_PROGRAM_1
                AND A.SORLCUR_SEQNO IN
                       (SELECT MAX (A1.SORLCUR_SEQNO)
                          FROM SORLCUR A1
                         WHERE     A.SORLCUR_PIDM = A1.SORLCUR_PIDM
                               AND A.SORLCUR_PROGRAM = A1.SORLCUR_PROGRAM
                               AND A.SORLCUR_LMOD_CODE = A1.SORLCUR_LMOD_CODE)
                AND B.SGBSTDN_TERM_CODE_EFF IN
                               (SELECT MAX (B1.SGBSTDN_TERM_CODE_EFF)
                                  FROM SGBSTDN B1
                                 WHERE     B.SGBSTDN_PIDM = B1.SGBSTDN_PIDM
                                       AND B.SGBSTDN_PROGRAM_1 = B1.SGBSTDN_PROGRAM_1) ;
                                   
        Exception When No_data_Found Then
                    lc_programa := null;
                  When Others Then     
                    lc_programa := null;
        End;

        If lc_programa is not null Then
                    --baja dashboard
                    BEGIN
                       PKG_VALIDA_PRONO.P_VALIDA_FALTA (p_pidm,
                                                        lc_programa,
                                                        p_regla);
                                                        
                            dbms_output.put_line('Entro dashboard programa:'||lc_programa);
                                                        
                    END;  

                    --Ordena materias en base a la secuencia de SMAPROG
                     FOR d IN cur_secuencia LOOP
                            begin
                            dbms_output.put_line('Entro secuencia dasch');

                                INSERT INTO MATERIA_FALTANTE_LIC
                                                         VALUES (d.per,
                                                                 d.area,
                                                                 d.materia,
                                                                 d.nombre_mat,
                                                                 d.califica,
                                                                 d.tipo,
                                                                 d.pidm,
                                                                 d.matricula,
                                                                 d.id_secuencia,
                                                                 d.materia_padre,
                                                                 d.subj,
                                                                 d.crse,
                                                                 d.campus,
                                                                 d.nivel,
                                                                 p_regla,
                                                                 d.l_sp,
                                                                 d.aprobadas_curr,
                                                                 d.curso_curr,
                                                                 d.total_curr);
                                    dbms_output.put_line('Sec:'||d.id_secuencia||'materia: '||d.materia||' nombre:'||d.nombre_mat||' tipo'||d.tipo||
                                                ' Aprobadas: '||d.aprobadas_curr||' encurso: '||d.curso_curr||' totalcursadas: '||d.total_curr);                                                                 
                            exception when others then
                                null;
                            end;
                     END LOOP;

                    COMMIT;
        End if;
               

End p_baja_dashboard; 


--Consutla materias activas
function f_consulta_materias_activas(p_fecha_inicio date,
                                p_no_regla number,
                                p_campus varchar2 , 
                                p_nivel varchar2, 
                                p_term_code varchar2,  
                                p_pidm  number) return SYS_REFCURSOR as
    
v_cursor SYS_REFCURSOR;
ln_cmat number:=0;
begin            

    BEGIN  -- Revisa que el alumno tenga una en P ya no debe mostras materias
        select 1 into ln_cmat
        from sztprsiu
        WHERE  sztprsiu_no_regla = p_no_regla
            AND sztprsiu_ind_insc = 'P'
            AND SZTPRsiu_PIDM= p_pidm;

    EXCEPTION WHEN OTHERS THEN
       ln_cmat:=0;
    END;
   
   if ln_cmat = 0 Then
       PKG_ALGORITMO_pidm.p_alumnos_pidm(p_no_regla, p_pidm);  
       PKG_ALGORITMO_pidm.p_programa_x_pidm(p_no_regla, p_pidm);   
       PKG_ALGORITMO_pidm.p_alumnos_x_pidm(p_no_regla, p_pidm);   
       PKG_ALGORITMO_pidm.P_MATERIAS_PIDM_SIU(p_no_regla, p_pidm);
   end if;
    
    Open v_cursor FOR 
        Select distinct SZTPRSIU_ID MATRICULA, 
            SZTPRSIU_PROGRAM PROGRAMA, 
            SZTPRSIU_materia_legal MATERIA_LEGAL,
            nvl((select SCRSYLN_LONG_COURSE_TITLE from SCRSYLN
                    WHERE  SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB  = SZTPRSIU_MATERIA_LEGAL
               ),'SIN ESPECIFICAR') NOMBRE_MATERIA,
            sztprsiu_ind_insc materia_inscrita
	    FROM SZTPRSIU
        where  SZTPRSIU_NO_REGLA = p_no_regla
--        and ln_cmat=0
        and SZTPRSIU_PIDM = p_pidm;

--            Select * from MATERIA_FALTANTE_LIC 
--                where pidm=p_pidm and regla=p_no_regla;

        
Return v_cursor;    
    
end f_consulta_materias_activas;

--Alta o baja de materia seleccionada desde SIU
function f_abc_materias(p_fecha_inicio date,
                                p_no_regla number,
                                p_campus varchar2 , 
                                p_nivel varchar2, 
                                p_term_code varchar2,  
                                p_pidm  number,
                                p_materia_legal varchar2,
                                p_abc  number   --1 Alta, 2 Baja
                         ) return varchar2 as
    
lv_return   varchar2(4000):='OK';
lc_count    number:=0;
begin            

    if p_abc in (1,2) Then 

        Begin
            Update SZTPRSIU Set SZTPRSIU_IND_INSC = Case When p_abc = 1 Then 'S' else 'N' end
                Where SZTPRSIU_NO_REGLA = p_no_regla
                    and SZTPRSIU_PIDM = p_pidm
                    and SZTPRSIU_materia_legal= p_materia_legal;
            lc_count:=SQL%ROWCOUNT;
        Exception When Others Then lc_count:=0;
        End;
        if lc_count = 0 Then 
            lv_return:='Error: no se encontró alumno pidm:'||p_pidm||' en regla:'||p_no_regla||' materia:'||p_materia_legal;
        else    
            commit;
        end if;
    else
        lv_return:='Error: Opcion p_abc invalida'||p_abc;
    end if;
        
    Return lv_return;    
    
end f_abc_materias;

--Pronostica los alumnos de SIU y los envia a la tabla de pronostico
function  p_prono_alumnos(p_regla number, p_pidm number default null) return varchar2 as
lc_dummy number:=0;
ln_sec number;
lc_msj varchar2(500);
Begin
    Begin
        update sztprsiu set sztprsiu_ind_insc='S' 
            Where sztprsiu_no_REgla=p_regla
            and sztprsiu_pidm=nvl(p_pidm, sztprsiu_pidm)
            and sztprsiu_ind_insc='P'
            and Not Exists(Select 1 from sztprono 
                        Where sztprono_pidm = sztprsiu_pidm
                            and sztprono_no_regla=sztprsiu_no_regla
                            and sztprono_materia_legal = sztprsiu_materia_legal);
        Commit;
        
    End;

    FOR pob IN (Select *  --alumnos con materias seleccionadas
                from sztprsiu
                    Where sztprsiu_pidm= NVL(p_pidm,sztprsiu_pidm)
                    and sztprsiu_no_regla=p_regla
                    and SZTPRSIU_IND_INSC='S'
                Union All
                select   p1.*  --alumnos con materias NO seleccionadas
                    from sztprsiu p1
                    where p1.sztprsiu_no_regla=p_regla
                    and sztprsiu_secuencia=1
                    and not exists(Select 1 from sztprsiu p2 
                                    where p2.sztprsiu_pidm = p1.sztprsiu_pidm
                                    and p2.sztprsiu_no_regla=p1.sztprsiu_no_regla
                                    and p2.sztprsiu_ind_insc='S')                  
                ) 
    LOOP
        begin 
            Select count(sztprono_pidm)+1 into ln_sec
            from sztprono 
                Where sztprono_no_regla=p_regla
                and sztprono_pidm = pob.sztprsiu_pidm;
        Exception When Others Then ln_sec:=1;
        End;

--        dbms_output.put_line('Alumno:'||pob.sztprsiu_id||' materia'||pob.sztprsiu_materia_legal||' ln_sec:'||ln_sec);        
              dbms_output.put_line(pob.SZTPRSIU_PIDM
              ||'-'||pob.SZTPRSIU_ID
              ||'-'||pob.SZTPRSIU_TERM_CODE
              ||'-'||pob.SZTPRSIU_PROGRAM
              ||'-'||pob.SZTPRSIU_MATERIA_LEGAL
              ||'-'||pob.SZTPRSIU_SECUENCIA
              ||'-'||pob.SZTPRSIU_NO_REGLA
              ||'-');        
        BEGIN
            INSERT INTO SATURN.SZTPRONO  (
               SZTPRONO_PIDM
              ,SZTPRONO_ID
              ,SZTPRONO_TERM_CODE
              ,SZTPRONO_PROGRAM
              ,SZTPRONO_MATERIA_LEGAL
              ,SZTPRONO_SECUENCIA
              ,SZTPRONO_PTRM_CODE
              ,SZTPRONO_MATERIA_BANNER
              ,SZTPRONO_COMENTARIO
              ,SZTPRONO_FECHA_INICIO
              ,SZTPRONO_PTRM_CODE_NW
              ,SZTPRONO_FECHA_INICIO_NW
              ,SZTPRONO_AVANCE
              ,SZTPRONO_NO_REGLA
              ,SZTPRONO_USUARIO
              ,SZTPRONO_STUDY_PATH
              ,SZTPRONO_RATE
              ,SZTPRONO_JORNADA
              ,SZTPRONO_ACTIVITY_DATE
              ,SZTPRONO_CUATRI
              ,SZTPRONO_TIPO_INICIO
              ,SZTPRONO_JORNADA_DOS
              ,SZTPRONO_ENVIO_MOODL
              ,SZTPRONO_ENVIO_HORARIOS
              ,SZTPRONO_ESTATUS
              ,SZTPRONO_ESTATUS_ERROR
              ,SZTPRONO_DESCRIPCION_ERROR
              ,SZTPRONO_GRUPO_ASIG
              )
            VALUES
              (
               pob.SZTPRSIU_PIDM
              ,to_char(pob.SZTPRSIU_ID)
              ,to_char(pob.SZTPRSIU_TERM_CODE)
              ,pob.SZTPRSIU_PROGRAM
              ,pob.SZTPRSIU_MATERIA_LEGAL
               ,ln_sec--,pob.SZTPRSIU_SECUENCIA
              ,pob.SZTPRSIU_PTRM_CODE
              ,pob.SZTPRSIU_MATERIA_BANNER
              ,pob.SZTPRSIU_COMENTARIO
              ,pob.SZTPRSIU_FECHA_INICIO
              ,pob.SZTPRSIU_PTRM_CODE_NW
              ,pob.SZTPRSIU_FECHA_INICIO_NW
              ,pob.SZTPRSIU_AVANCE
              ,pob.SZTPRSIU_NO_REGLA
              ,pob.SZTPRSIU_USUARIO
              ,pob.SZTPRSIU_STUDY_PATH
              ,pob.SZTPRSIU_RATE
              ,pob.SZTPRSIU_JORNADA
              ,sysdate --,pob.SZTPRSIU_ACTIVITY_DATE
              ,pob.SZTPRSIU_CUATRI
              ,pob.SZTPRSIU_TIPO_INICIO
              ,pob.SZTPRSIU_JORNADA_DOS
              ,pob.SZTPRSIU_ENVIO_MOODL
              ,pob.SZTPRSIU_ENVIO_HORARIOS
              ,pob.SZTPRSIU_ESTATUS
              ,pob.SZTPRSIU_ESTATUS_ERROR
              ,pob.SZTPRSIU_DESCRIPCION_ERROR
              ,pob.SZTPRSIU_GRUPO_ASIG
              );

            lc_dummy:=lc_dummy+1;
                
            p_log(pob.SZTPRSIU_FECHA_INICIO,
                    SUBSTR(pob.SZTPRSIU_PROGRAM,1,3),
                    SUBSTR(pob.SZTPRSIU_PROGRAM,4,2),
                    pob.SZTPRSIU_TERM_CODE,
                    pob.SZTPRSIU_PIDM,
                    'Alumno pronosticado e insertado en prono con secuencia:' ||to_char(ln_sec)||' con materia:'||pob.sztprsiu_materia_legal );
             
            Update Sztprsiu set SZTPRSIU_IND_INSC='P'
                Where sztprsiu_no_regla=p_regla
                and sztprsiu_pidm=pob.sztprsiu_pidm
                and sztprsiu_materia_legal=pob.sztprsiu_materia_legal;
                
        EXCEPTION
            WHEN  OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('ERROR al insert en sztprono con pidm:'||p_pidm||' regla:'||p_regla||' error:'||sqlerrm);
                lc_dummy:=lc_dummy-1;
                p_log(pob.SZTPRSIU_FECHA_INICIO,
                        SUBSTR(pob.SZTPRSIU_PROGRAM,1,3),
                        SUBSTR(pob.SZTPRSIU_PROGRAM,4,2),
                        pob.SZTPRSIU_TERM_CODE,
                        pob.SZTPRSIU_PIDM,
                        'ERROR al inserta en prono:'||sqlerrm);
                       
        END;
        
        
    END LOOP;


    if lc_dummy  > 0 then
        lc_msj:= 'Total de alumnos-materias pronosticados:'||lc_dummy;        
        Commit;
    else
        lc_msj:= 'Warning: no existe alumnos SIU para pronosticar de la regla: '||p_regla;
        Rollback;
    End if;

    dbms_output.put_line(lc_msj);
    
    Return lc_msj;
Exception When Others Then 
    dbms_output.put_line('Error en p_prono_alum_pidm: '||sqlerrm);
    Rollback;
End p_prono_alumnos;



End pkg_alumno_siu;
/

DROP PUBLIC SYNONYM PKG_ALUMNO_SIU;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ALUMNO_SIU FOR BANINST1.PKG_ALUMNO_SIU;
