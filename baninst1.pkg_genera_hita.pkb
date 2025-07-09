DROP PACKAGE BODY BANINST1.PKG_GENERA_HITA;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_genera_HITA 
AS
   /*   se modifico paraa la version del MEC 2.0  13 febero 2019   glovicx  */
   vsello               CLOB;
   vdetcert             CLOB;
   v_firma              CLOB;

   salida               UTL_FILE.FILE_TYPE;
   nom_archivo          VARCHAR2 (40);
   directorio           VARCHAR2 (90);
   salida_dat           VARCHAR2 (32000);
   l_xmltype            XMLTYPE;

   soap_request         VARCHAR2 (5000);
   soap_respond         VARCHAR2 (5000);
   vxml_inicio          VARCHAR2 (200);
   vxml_respon          VARCHAR2 (10000);
   vxml_entidad         VARCHAR2 (9000);
   vxml_expedicion      VARCHAR2 (9000);
   vxml_alumno          VARCHAR2 (9000);
   vxml_califica        VARCHAR2 (9000);
   vxml_fin             VARCHAR2 (60);
   vxml_califica2       VARCHAR2 (9000);
   vxml_califica3       CLOB;
   vxml_total           CLOB;

   v_nivel              VARCHAR2 (15) DEFAULT NULL;
   v_campus             VARCHAR2 (6) DEFAULT NULL;
   v_prog               VARCHAR2 (14) DEFAULT NULL;
   v_moneda             VARCHAR2 (4) DEFAULT NULL;
   vpidm                NUMBER;
   vmsjerror            VARCHAR2 (1000);

   v_no_cert            VARCHAR2 (1000);
   v_cert_resp          VARCHAR2 (5000);
   v_sello              VARCHAR2 (9000);
   v_folio_ctrl         NUMBER;
   v_tipo_cert          NUMBER;
   v_ent_fed            VARCHAR2 (2);
   v_idcamp             VARCHAR2 (8);
   v_idinstituto        NUMBER;
   v_idcargo            NUMBER;
   v_curp_resp          VARCHAR2 (20);
   v_materno_resp       VARCHAR2 (80);
   v_paterno_resp       VARCHAR2 (80);
   v_nombre_resp        VARCHAR2 (50);
   v_fec_exp            VARCHAR2 (30);
   v_numero             NUMBER;
   v_cve_plan           NUMBER;
   v_tipo_perd          NUMBER;
   v_idcarrera          NUMBER;
   v_curp_alumn         VARCHAR2 (20);
   v_materno_alumn      VARCHAR2 (80);
   v_materno_alumn2     VARCHAR2 (80);
   v_paterno_alumn      VARCHAR2 (80);
   v_nombre_alumn       VARCHAR2 (50);
   v_fech_nac_alumn     VARCHAR2 (30);
   v_genero             VARCHAR2 (20);
   v_id_genero          NUMBER;
   v_nu_control         VARCHAR2 (12);
   v_idexp              VARCHAR2 (3);
   v_fecha              VARCHAR2 (20);
   v_tipo_certificado   NUMBER;
   v_promedio           FLOAT;
   v_promedio2          VARCHAR2 (7);
   v_asignadas          NUMBER;
   v_total_mat          FLOAT;
   v_observ             NUMBER;
   v_califica           avance1.calif%TYPE;                    ---varchar2(6);
   v_ciclo              VARCHAR2 (10);
   v_id_materia         VARCHAR2 (8);
   v_avances            NUMBER;
   ---------------------------------------
   matricula            spriden.spriden_id%TYPE;
   nombre               VARCHAR2 (200);
   Programa             VARCHAR2 (90);
   estatus              VARCHAR2 (60);
   per                  NUMBER;                           -- avance1.per%type;
   area                 avance1.area%TYPE;
   nombre_area          avance1.nombre_area%TYPE;
   materia              VARCHAR2 (60);
   nombre_mat           VARCHAR2 (200);
   califica             avance1.calif%TYPE;
   ord                  NUMBER;                           -- avance1.per%type;
   tipo                 VARCHAR2 (80);
   n_area               VARCHAR2 (90);
   hoja                 NUMBER;                            --avance1.per%type;
   aprobadas_curr       NUMBER;
   no_aprobadas_curr    NUMBER;
   curso_curr           NUMBER;
   por_cursar_curr      NUMBER;
   total_curr           NUMBER;
   avance_curr          NUMBER;
   aprobadas_tall       NUMBER;
   no_aprobadas_tall    NUMBER;
   curso_tall           NUMBER;
   por_cursar_tall      NUMBER;
   total_tall           NUMBER;
   ppidm                NUMBER; --:=59308; ----parametro de entrada  del procedimento
   pprograma            VARCHAR2 (15); ----parametro de entrada del procedimiento
   v_calificaciones     VARCHAR2 (10000);
   v_fech_exp           VARCHAR2 (20);
   pindica              NUMBER;
   ptipo                NUMBER;
   v_clvecarrera        VARCHAR2 (14);
   v_idnvl              NUMBER;
   v_nvl                VARCHAR2(12);
   v_calf_min           VARCHAR2(9);
   v_calf_max           VARCHAR2(9);
   v_calf_min_aprob     VARCHAR2(9);
   vcred_total          VARCHAR2(9);     
   vcred_obtn           NUMBER:=0;  
   vcred_materia        NUMBER;
   vid_asignatura       VARCHAR2(3);
   v_asignatura         VARCHAR2(14);       
   v_mate_cursada       number:=0;
       
    vl_campus varchar2(10):= null;
    vl_nivel varchar2(10):= null;
    vl_sp number:=0;
    vl_program_des varchar2(250):= null;
    vl_TIPO_INGRESO varchar2(10):= null;
    vl_TIPO_INGRESO_DESC varchar2(250) := null;
    vl_SGBSTDN_STYP_CODE varchar2(10):= null;   
    vl_catalogo varchar2(6):= null;
     vl_promedio varchar2(20):= null;
    

    
    
   
   
PROCEDURE p_carga_hita (ppidm IN NUMBER, pprograma IN VARCHAR2, psp in number)
   IS
      v_cur   SYS_REFCURSOR;
      vcred_materia2  VARCHAR2(10);
      l_materia_padre VARCHAR2(20); 
      l_sql varchar2(500);
      l_pidm number;
      l_max number :=0;
      vl_aprobadas number:=0;
      vl_aprob number :=0; 
      vl_total number:=0;
      vl_x_cursar number:=0;
      
      vl_TOT_MAT number:=0;
      vl_APROB_MAT number:=0;
      vl_E_CURSO number:=0;
      vl_estatus varchar2(50);
      
      
    
      
      
   BEGIN
      


      v_calificaciones := '';                        ----inicaliza la variable
      vxml_califica3 := '';                          ----inicaliza la variable

      matricula := '';
      nombre := '';
      Programa := '';
      estatus := '';
      per := '';
      area := '';
      nombre_area := '';
      materia := '';
      nombre_mat := '';
      califica := '';
      ord := '';
      tipo := '';
      n_area := '';
      hoja := '';
      aprobadas_curr := '';
      no_aprobadas_curr := '';
      curso_curr := '';
      por_cursar_curr := '';
      total_curr := '';
      avance_curr := '';
      aprobadas_tall := '';
      no_aprobadas_tall := '';
      curso_tall := '';
      por_cursar_tall := '';
      total_tall := '';
      vcred_materia  := '';
      vcred_materia2  := '';
      vcred_obtn  := 0;
      v_mate_cursada :=0;
      l_max:=0;
      
     
     Begin 
            delete SZTHITA
            where SZTHITA_PIDM = ppidm
            And SZTHITA_PROG = pprograma;
     Exception
        When Others then
            null;
     End;
     Commit;
     
      DBMS_OUTPUT.PUT_LINE('Entra a generar los registros  '||ppidm);
    
       --v_cur := BANINST1.PKG_DASHBOARD_ALUMNO.f_dashboard_avcu_out_prono_new ( ppidm,pprograma,'HITA', psp);
       v_cur := BANINST1.PKG_DASHBOARD_ALUMNO.f_dashboard_avcu_out ( ppidm,pprograma,'HITA');

      LOOP
      
       --DBMS_OUTPUT.PUT_LINE('Entra en el Loop  '||ppidm);
        l_max:= l_max +1;
      
         FETCH v_cur
         INTO matricula,
              nombre,
              Programa,
              estatus,
              per,
              area,
              nombre_area,
              materia,
              nombre_mat,
              califica,
              ord,
              tipo,
              n_area,
              hoja,
              aprobadas_curr,
              no_aprobadas_curr,
              curso_curr,
              por_cursar_curr,
              total_curr,
              avance_curr,
              aprobadas_tall,
              no_aprobadas_tall,
              curso_tall,
              por_cursar_tall,
              total_tall;
              
              
            --raise_application_error (-20002,'Error '||sqlerrm);
            
            DBMS_OUTPUT.PUT_LINE('Matricula:'||matricula||' programa: '||Programa ||'materia: '||materia);
              
          --  IF tipo IN ('PC','NA', 'AP')  then
                    
               -- DBMS_OUTPUT.PUT_LINE('Contador '||l_max);
            
                   Begin 
                        Select distinct a.campus, a.nivel, a.sp, a.ESTATUS_D,  a.CTLG, a.TIPO_INGRESO, a.TIPO_INGRESO_DESC, a.SGBSTDN_STYP_CODE,
                        PKG_DATOS_ACADEMICOS.promedio1(a.pidm, a.programa) promedio,
                        (Select distinct SZTDTEC_PROGRAMA_COMP
                            from sztdtec a
                            where a.SZTDTEC_PROGRAM = a.programa
                            and a.SZTDTEC_TERM_CODE = (select max (a1.SZTDTEC_TERM_CODE)
                                                        from sztdtec a1
                                                        Where a.SZTDTEC_PROGRAM = a1.SZTDTEC_PROGRAM)
                        ) Nombre
                         Into vl_campus, vl_nivel, vl_sp,vl_estatus, vl_catalogo, vl_TIPO_INGRESO, vl_TIPO_INGRESO_DESC, vl_SGBSTDN_STYP_CODE, vl_promedio, vl_program_des
                        from TZTPROG_HIST a
                        Where 1=1
                        And a.pidm =  ppidm
                        And a.programa = pprograma
                        And a.sp = (select max (a1.sp)
                                     from TZTPROG_HIST a1
                                    Where a.pidm = a1.pidm
                                    And a1.programa = pprograma
                                   );
                   Exception
                    When Others then 
                    vl_campus:= null;
                    vl_nivel:= null;
                    vl_sp := 0;
                    vl_program_des := null;
                    vl_catalogo:='000000';
                    vl_TIPO_INGRESO := null;
                    vl_TIPO_INGRESO_DESC := null;
                    vl_SGBSTDN_STYP_CODE := null;
                    vl_promedio:= null;
                     DBMS_OUTPUT.PUT_LINE('Error al recuperar registros   '||sqlerrm);
                   End;

              
                    If aprobadas_curr > total_curr then 
                       aprobadas_curr := total_curr;
                      
                    End if;


                    DBMS_OUTPUT.PUT_LINE('Valores '||aprobadas_curr ||'*'||no_aprobadas_curr||'*'||curso_curr||'*'||por_cursar_curr||'*'||avance_curr);

                   begin   
                  
                      insert into SZTHITA
                       values
                       (
                       ppidm,  --> SZTHITA_PIDM
                       matricula, --> SZTHITA_ID
                      nombre,  --> SZTHITA_NOMBRE
                      vl_campus, --> SZTHITA_CAMP
                      vl_nivel,  --> SZTHITA_LEVL
                      pprograma, --> SZTHITA_PROG
                      vl_program_des, --> SZTHITA_N_PROG
                      vl_estatus,   --> SZTHITA_STATUS
                      aprobadas_curr, --> SZTHITA_APROB
                      no_aprobadas_curr, --> SZTHITA_REPROB
                      curso_curr,   --> SZTHITA_E_CURSO
                      por_cursar_curr, --> SZTHITA_X_CURSAR 
                      total_curr,  --> SZTHITA_TOT_MAT
                      avance_curr, --> SZTHITA_AVANCE
                      vl_promedio,           --> SZTHITA_PROMEDIO ---> crear el promedio
                      vl_sp,  --> SZTHITA_STUDY
                      vl_catalogo, --> SZTHITA_PER_CATALOGO
                      null, --> SZTHITA_MAJOR
                      null, --> SZTHITA_CONCENT1
                      null, --> SZTHITA_CONCENT2
                      vl_TIPO_INGRESO, -->  SZTHITA_M_DESC
                      vl_TIPO_INGRESO_DESC, --> SZTHITA_C1_DESC
                      vl_SGBSTDN_STYP_CODE  --> SZTHITA_C2_DESC
                      );
                      commit;
                   --DBMS_OUTPUT.PUT_LINE('insertar en SZTHITA   ');
                   exception when others then
                    --DBMS_OUTPUT.PUT_LINE('ERROR al insertar en SZTHITA'||sqlerrm);
                    null;
                   end;                      
                   
        
       --  EXIT WHEN v_cur%NOTFOUND;
       EXIT WHEN l_max =1;

        
      END LOOP;
      Commit;
      CLOSE v_cur;
      
      Begin
            Select x.contar
                Into vl_aprobadas
            from (
            select distinct count(*) contar, APR
            from  avance_n
            where pidm_alu = ppidm
            And APR in ('AP','EQ')
            and USUARIO_SIU= 'HITA'
            group by APR
            ) x;
      Exception 
        When others then
            vl_aprobadas:=0;
      End;
      
      --DBMS_OUTPUT.PUT_LINE('Salida '||vl_aprobadas ||'*'||aprobadas_curr);
      
      If vl_aprobadas != aprobadas_curr then 
      
           --DBMS_OUTPUT.PUT_LINE('ENTRA 1 ');
      
            Begin 
                 Update SZTHITA
                 set SZTHITA_APROB = vl_aprobadas
                 where SZTHITA_PIDM = ppidm
                 And SZTHITA_PROG = pprograma;
            Exception
                When Others then 
                    null;
            End;
            Commit;
      
      End if;

            vl_aprob:=0; 
            vl_total:=0;


      Begin
        Select SZTHITA_APROB, SZTHITA_TOT_MAT
            into vl_aprob, vl_total
        from SZTHITA
        Where SZTHITA_PIDM = ppidm
        And SZTHITA_PROG = pprograma;
      Exception
        When Others then
            vl_aprob:=0; 
            vl_total:=0;
      End;
      
      If vl_aprob > vl_total then 
      
       --DBMS_OUTPUT.PUT_LINE('ENTRA 2 ');
      
          Begin
            Update SZTHITA
            set SZTHITA_APROB = vl_total,
                SZTHITA_E_CURSO = 0,
                SZTHITA_X_CURSAR = 0
            where SZTHITA_PIDM = ppidm
            And SZTHITA_PROG = pprograma;
            Commit;
          Exception
            When Others then 
                null;
          End;
      
      End if;
  

      vl_TOT_MAT :=0;
      vl_APROB_MAT :=0;
      vl_E_CURSO :=0;    
      
      Begin
      
          select nvl (SZTHITA_TOT_MAT,0), nvl (SZTHITA_APROB,0), nvl (SZTHITA_E_CURSO,0)
           Into vl_TOT_MAT, vl_APROB_MAT, vl_E_CURSO
          from SZTHITA
          where 1=1 
          and SZTHITA_PIDM = ppidm
          And SZTHITA_PROG = pprograma;
      Exception
        When Others then 
            vl_TOT_MAT :=0;
            vl_APROB_MAT :=0;
            vl_E_CURSO :=0; 
      End;
      
      
      vl_x_cursar:=0;
      
      vl_x_cursar := vl_TOT_MAT - ( vl_APROB_MAT + vl_E_CURSO);
      
      If vl_x_cursar < 0 then 
         vl_x_cursar:=0;
      End if; 
      
       --DBMS_OUTPUT.PUT_LINE('ENTRA 3 '|| vl_TOT_MAT ||'*'||vl_APROB_MAT ||'*'||vl_E_CURSO||'*'||vl_x_cursar);
       
      Begin
        Update SZTHITA
        set SZTHITA_X_CURSAR = vl_x_cursar
        where SZTHITA_PIDM = ppidm
        And SZTHITA_PROG = pprograma;
        Commit;
      Exception
        When Others then 
            null;
      End;
      
  

      Begin

            For cx in (

                        select *
                        from szthita
                        where SZTHITA_STATUS ='EGRESADO'
                        And SZTHITA_PIDM = ppidm
                        
                     ) loop
                     
                        Begin
                            Update szthita
                            set SZTHITA_APROB = cx.SZTHITA_TOT_MAT,
                                SZTHITA_E_CURSO = 0,
                                SZTHITA_X_CURSAR = 0,
                                SZTHITA_AVANCE = 100
                            where 1=1
                            And SZTHITA_PIDM = cx.SZTHITA_PIDM
                            and SZTHITA_PROG = cx.SZTHITA_PROG
                            And SZTHITA_STUDY = cx.SZTHITA_STUDY;
                        Exception
                            When Others then 
                                null;
                        End;
                     
                        Commit;

            End loop;
            
      End;

      
      
   EXCEPTION WHEN OTHERS THEN
   
    -- DBMS_OUTPUT.PUT_LINE('matricula '||matricula||' nombre  '||nombre||' pprograma '||pprograma||' estatus '||estatus||' per '||per||' area '||area||' nombre_area '||nombre_area||' materia '||materia||' nombre_mat '||nombre_mat||' error -->'||sqlerrm);
      null;
   
   END p_carga_hita;   
   

 Procedure p_ejecuta_hita_UTLLI
 is
 
 --pkg_d_academicos.p_cargatztprog_hist  --> Se debe de invocar esta para cargar el TZTPROG exclusivo para HITA
 
 
 Begin
 
        Begin 
 
            For cx in (
 
                         Select distinct a.pidm, a.matricula, a.programa, a.sp
                        from TZTPROG_HIST a
                        Where 1=1
                        And a.campus in ('UTL')
                        And a.nivel in ('LI')
                        and a.estatus not in ( 'CP', 'CC', 'PO', 'CM',  'CV')
                        And a.sp = (select max (a1.sp)
                                     from TZTPROG_HIST a1
                                    Where a.pidm = a1.pidm
                                    And a.campus = a1.campus
                                    ANd a.nivel = a1.nivel
                                    And a.estatus = a1.estatus
                                    And a1.programa = a.programa
                                  )
                         --And a.matricula ='010108981'
                       order by 2,3
             )loop
             
                    PKG_genera_HITA.p_carga_hita( cx.pidm, cx.programa, cx.sp);
             End loop;
             Commit;             
      Exception
        When others then 
        null;       
      End;
 
End p_ejecuta_hita_UTLLI;
 
 Procedure p_ejecuta_hita_UTL
 is
 
 --pkg_d_academicos.p_cargatztprog_hist  --> Se debe de invocar esta para cargar el TZTPROG exclusivo para HITA
 
 
 Begin
 
        Begin 
 
            For cx in (
 
                         Select distinct a.pidm, a.matricula, a.programa, a.sp
                        from TZTPROG_HIST a
                        Where 1=1
                        And a.campus in ('UTL')
                        And a.nivel not in ('LI')
                        and a.estatus not in ( 'CP', 'CC', 'PO', 'CM',  'CV')
                        And a.sp = (select max (a1.sp)
                                     from TZTPROG_HIST a1
                                    Where a.pidm = a1.pidm
                                    And a.campus = a1.campus
                                    ANd a.nivel = a1.nivel
                                    And a.estatus = a1.estatus
                                    And a1.programa = a.programa
                                  )
                      -- And a.matricula ='010674195'
                       order by 2,3
             )loop
             
                    PKG_genera_HITA.p_carga_hita( cx.pidm, cx.programa, cx.sp);
             End loop;
             Commit;             
      Exception
        When others then 
        null;       
      End;
 
End p_ejecuta_hita_UTL;

 Procedure p_ejecuta_hita_UTS
 is
 
 --pkg_d_academicos.p_cargatztprog_hist  --> Se debe de invocar esta para cargar el TZTPROG exclusivo para HITA
 
 
 Begin
 
        Begin 
 
            For cx in (
 
                         Select distinct a.pidm, a.matricula, a.programa, a.sp
                        from TZTPROG_HIST a
                        Where 1=1
                        And a.campus in ('UTS')
                      --  And a.nivel not in ('LI')
                        and a.estatus not in ( 'CP', 'CC', 'PO', 'CM',  'CV')
                        And a.sp = (select max (a1.sp)
                                     from TZTPROG_HIST a1
                                    Where a.pidm = a1.pidm
                                    And a.campus = a1.campus
                                    ANd a.nivel = a1.nivel
                                    And a.estatus = a1.estatus
                                    And a1.programa = a.programa
                                  )
                       order by 2,3
             )loop
             
                    PKG_genera_HITA.p_carga_hita( cx.pidm, cx.programa, cx.sp);
             End loop;
             Commit;             
      Exception
        When others then 
        null;       
      End;
 
End p_ejecuta_hita_UTS;


 Procedure p_ejecuta_hita_PER
 is
 
 --pkg_d_academicos.p_cargatztprog_hist  --> Se debe de invocar esta para cargar el TZTPROG exclusivo para HITA
 
 
 Begin
 
        Begin 
 
            For cx in (
 
                         Select distinct a.pidm, a.matricula, a.programa, a.sp
                        from TZTPROG_HIST a
                        Where 1=1
                        And a.campus in ('PER')
                        and a.estatus not in ( 'CP', 'CC', 'PO', 'CM',  'CV')
                        --And a.matricula = '240242684'
                      --  And a.nivel not in ('LI')
                        And a.sp = (select max (a1.sp)
                                     from TZTPROG_HIST a1
                                    Where a.pidm = a1.pidm
                                    And a.campus = a1.campus
                                    ANd a.nivel = a1.nivel
                                    And a.estatus = a1.estatus
                                    And a1.programa = a.programa
                                  )
                       order by 2,3
             )loop
             
                    PKG_genera_HITA.p_carga_hita( cx.pidm, cx.programa, cx.sp);
             End loop;
             Commit;             
      Exception
        When others then 
        null;       
      End;
 
End p_ejecuta_hita_PER;


 Procedure p_ejecuta_hita_COL
 is
 
 --pkg_d_academicos.p_cargatztprog_hist  --> Se debe de invocar esta para cargar el TZTPROG exclusivo para HITA
 
 
 Begin
 
        Begin 
 
            For cx in (
 
                         Select distinct a.pidm, a.matricula, a.programa, a.sp
                        from TZTPROG_HIST a
                        Where 1=1
                      --  and a.matricula ='200324416'
                        And a.campus in ('COL')
                        and a.estatus not in ( 'CP', 'CC', 'PO', 'CM',  'CV')
                      --  And a.nivel not in ('LI')
                        And a.sp = (select max (a1.sp)
                                     from TZTPROG_HIST a1
                                    Where a.pidm = a1.pidm
                                    And a.campus = a1.campus
                                    ANd a.nivel = a1.nivel
                                    And a.estatus = a1.estatus
                                    And a1.programa = a.programa
                                  )
                       order by 2,3
             )loop
             
                    PKG_genera_HITA.p_carga_hita( cx.pidm, cx.programa, cx.sp);
             End loop;
             Commit;             
      Exception
        When others then 
        null;       
      End;
 
End p_ejecuta_hita_COL;

 Procedure p_ejecuta_hita_ECU
 is
 
 --pkg_d_academicos.p_cargatztprog_hist  --> Se debe de invocar esta para cargar el TZTPROG exclusivo para HITA
 
 
 Begin
 
        Begin 
 
            For cx in (
 
                         Select distinct a.pidm, a.matricula, a.programa, a.sp
                        from TZTPROG_HIST a
                        Where 1=1
                        And a.campus in ('ECU')
                        and a.estatus not in ( 'CP', 'CC', 'PO', 'CM',  'CV')
                      --  And a.nivel not in ('LI')
                        And a.sp = (select max (a1.sp)
                                     from TZTPROG_HIST a1
                                    Where a.pidm = a1.pidm
                                    And a.campus = a1.campus
                                    ANd a.nivel = a1.nivel
                                    And a.estatus = a1.estatus
                                    And a1.programa = a.programa
                                  )
                       order by 2,3
             )loop
             
                    PKG_genera_HITA.p_carga_hita( cx.pidm, cx.programa, cx.sp);
             End loop;
             Commit;             
      Exception
        When others then 
        null;       
      End;
 
End p_ejecuta_hita_ECU;


 Procedure p_ejecuta_hita_ALL
 is
 
 --pkg_d_academicos.p_cargatztprog_hist  --> Se debe de invocar esta para cargar el TZTPROG exclusivo para HITA
 
 
 Begin
 
        Begin 
 
            For cx in (
 
                         Select distinct a.pidm, a.matricula, a.programa, a.sp
                        from TZTPROG_HIST a
                        Where 1=1
                        And a.campus not in ('UTL', 'UTS', 'PER', 'COL','ECU')
                        and a.estatus not in ( 'CP', 'CC', 'PO', 'CM',  'CV')
                      --  And a.nivel not in ('LI')
                        And a.sp = (select max (a1.sp)
                                     from TZTPROG_HIST a1
                                    Where a.pidm = a1.pidm
                                    And a.campus = a1.campus
                                    ANd a.nivel = a1.nivel
                                    And a.estatus = a1.estatus
                                    And a1.programa = a.programa
                                  )
                       order by 2,3
             )loop
             
                    PKG_genera_HITA.p_carga_hita( cx.pidm, cx.programa, cx.sp);
             End loop;
             Commit;             
      Exception
        When others then 
        null;       
      End;
 
End p_ejecuta_hita_all;




end;
/

DROP PUBLIC SYNONYM PKG_GENERA_HITA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_GENERA_HITA FOR BANINST1.PKG_GENERA_HITA;
