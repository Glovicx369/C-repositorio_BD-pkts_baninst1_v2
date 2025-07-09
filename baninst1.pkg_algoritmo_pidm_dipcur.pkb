DROP PACKAGE BODY BANINST1.PKG_ALGORITMO_PIDM_DIPCUR;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_ALGORITMO_PIDM_DIPCUR AS
/******************************************************************************
   NAME:       PKG_ALGORITMO_PIDM_DIPLO_CURSOS
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        31/01/2023      flopezlo       1. Created this package.  v1.0
******************************************************************************/
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


PROCEDURE p_valida_falta (ppidm IN NUMBER, pprograma IN VARCHAR2,p_regla number)
   IS
      v_cur   SYS_REFCURSOR;
      vcred_materia2  VARCHAR2(10);
      l_materia_padre VARCHAR2(20);
      l_sql varchar2(500);
      l_pidm number;
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

--
--     Begin
--            delete tmp_valida_faltantes
--            where pidm = ppidm
--            And PROGRAMA = pprograma
--            and regla  = p_regla;
--     Exception
--        When Others then
--            null;
--     End;


       v_cur := BANINST1.PKG_DASHBOARD_ALUMNO.f_dashboard_avcu_out( ppidm,pprograma,'PRONO');

      LOOP
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

              l_materia_padre:=get_materia_padre(materia);

              DBMS_OUTPUT.PUT_LINE('matriculas '||matricula||' tipo '||tipo||' materia: '||materia);

            --raise_application_error (-20002,'Error '||sqlerrm);

            IF tipo IN ('PC','NA')  then

                   begin

                    select spriden_pidm
                    into l_pidm
                    from spriden
                    where 1 = 1
                    and spriden_id = matricula
                    and spriden_change_ind is null;

                   exception when others then
                        null;
                   end;

                   begin
    --
                      insert into saturn.tmp_valida_faltantes
                       values
                       (
                       matricula,
                      nombre,
                      pprograma,
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
                      total_tall,
                      p_regla,
                      l_materia_padre,
                      l_pidm
                      );
                    DBMS_OUTPUT.PUT_LINE('Inserta: matriculas '||matricula||' tipo '||tipo||' materia: '||materia);
                   exception when others then
                        DBMS_OUTPUT.PUT_LINE('matriculas '||matricula||' nombre  '||nombre||' pprograma '||pprograma||' estatus '||estatus||' per '||per||' area '||area||' nombre_area '||nombre_area||' materia '||materia||' nombre_mat '||nombre_mat||'Error '||sqlerrm);
                        --raise_application_error (-20002,'Error '||sqlerrm);
                   end;



            end if;

                  commit;

         EXIT WHEN v_cur%NOTFOUND;


      END LOOP;

      CLOSE v_cur;


   EXCEPTION WHEN OTHERS THEN

     DBMS_OUTPUT.PUT_LINE('matricula '||matricula||' nombre  '||nombre||' pprograma '||pprograma||' estatus '||estatus||' per '||per||' area '||area||' nombre_area '||nombre_area||' materia '||materia||' nombre_mat '||nombre_mat||' error -->'||sqlerrm);


   END p_valida_falta;

PROCEDURE p_alumnos_pidm (p_regla NUMBER,
                          p_pidm  NUMBER)IS


vl_existe Number:=0;
vl_existe_1 Number:=0;
vl_existe_anual number:=0;

Begin

    DBMS_OUTPUT.PUT_LINE('Inicia ');

    DELETE AS_ALUMNOS
    WHERE 1 = 1
    AND  AS_ALUMNOS_NO_REGLA =P_REGLA
    and SGBSTDN_PIDM = p_pidm;

    DELETE REL_PROGRAMAXALUMNO
    WHERE 1 = 1
    AND REL_PROGRAMAXALUMNO_NO_REGLA = p_regla
    and SGBSTDN_PIDM = p_pidm;

    DELETE REL_ALUMNOS_X_ASIGNAR
    WHERE 1 = 1
    AND SVRPROY_PIDM = p_pidm;

    COMMIT;

    Begin

        select count(1)
        Into vl_existe
        from SZTALGO
        Where SZTALGO_TIPO_CARGA = 'Regular'
        AND SZTALGO_NO_REGLA=P_REGLA;

        DBMS_OUTPUT.PUT_LINE('Entra  al 3 ' ||vl_existe);
    Exception
    when others then
      vl_existe :=0;

    END;


    Begin

        select count(1)
        Into vl_existe_1
        from SZTALGO
        Where SZTALGO_TIPO_CARGA = 'Continuo'
        AND SZTALGO_NO_REGLA=P_REGLA;

        DBMS_OUTPUT.PUT_LINE('Entra  al 3.1'||vl_existe_1);
    Exception
    when others then
      vl_existe_1 :=0;

    END;

    Begin

        select count(1)
        Into vl_existe_anual
        from SZTALGO
        Where SZTALGO_TIPO_CARGA = 'Anual'
        AND SZTALGO_NO_REGLA=P_REGLA;

        DBMS_OUTPUT.PUT_LINE('Entra  al 3 ' ||vl_existe);
    Exception
    when others then
      vl_existe :=0;

    END;


  IF vl_existe >= 1 then

    DBMS_OUTPUT.PUT_LINE('Entra  al 4');


       For c in (
        select DISTINCT
                            A.SGBSTDN_PIDM SGBSTDN_PIDM,
                            SPRIDEN_ID as id_Alumno,
                            regexp_substr(SPRIDEN_LAST_NAME, '[^/]*') as ApellidoPaterno,
                            NVL(substr(regexp_substr(SPRIDEN_LAST_NAME, '/[^/]*'),2), 0) as ApellidoMaterno,
                            SPRIDEN_FIRST_NAME as Nombres,
                            TO_CHAR(NVL(TRUNC(MONTHS_BETWEEN(SYSDATE, SPBPERS_BIRTH_DATE) / 12), 0)) as Edad,
                            d.Res_Calle,
                            d.Res_Colonia,
                            d.Res_CP,
                            d.Id_Ciudad,
                            '0' as Id_TipoJornada,
                            d.Id_Estado,
                            d.Id_Pais,
                            NVL(SGBSTDN_CAMP_CODE, 0) as Campus,
                            NVL(SPBPERS_SEX, 0) as Id_Genero,
                           -- TO_CHAR(NVL(SPBPERS_BIRTH_DATE, '1/01/1900'),'DD/MM/YYYY') as FechaNacimiento,
                            case when SGBSTDN_STST_CODE IN ('AS','MA','PR') then 'A'
                            else 'I'
                            end as id_EstadoActivo,
                            aa.SORLCUR_START_DATE FECHA_INICIO,
                            A.SGBSTDN_STYP_CODE estatus,
                            SORLCUR_ADMT_CODE equi,
                            SGBSTDN_LEVL_CODE
                        from SGBSTDN A , SPRIDEN, SPBPERS ,STVCAMP, SZTDTEC ,
                        sgrstsp, SORLCUR aa , SZTALGO, (select a.SPRADDR_PIDM ,
                                                                                                    NVL(a.SPRADDR_STREET_LINE1, 0) as Res_Calle,
                                                                                                    NVL(a.SPRADDR_STREET_LINE2, 0) as Res_Colonia,
                                                                                                    substr(NVL(a.SPRADDR_ZIP,'0'),1,5) as Res_CP,
                                                                                                    NVL(a.SPRADDR_CNTY_CODE, '00000') as Id_Ciudad,
                                                                                                    NVL(a.SPRADDR_STAT_CODE, '00') as Id_Estado,
                                                                                                    NVL(a.SPRADDR_NATN_CODE, 'XX') as Id_Pais
                                                                                                 from SPRADDR a
                                                                                                Where a.SPRADDR_SURROGATE_ID = (select max (a1.SPRADDR_SURROGATE_ID)
                                                                                                                                                    from SPRADDR a1
                                                                                                                                                    where   a1.SPRADDR_PIDM =  a.SPRADDR_PIDM)) d
                        where A.SGBSTDN_PIDM = SPRIDEN_PIDM
                        And SPRIDEN_CHANGE_IND is NULL
                        And A.SGBSTDN_PIDM = SPBPERS_PIDM (+)
                        And A.SGBSTDN_CAMP_CODE = STVCAMP_CODE
                        And A.SGBSTDN_PIDM = sgrstsp_PIDM
                        And SGRSTSP_STSP_CODE != 'IN'
                        And aa.SORLCUR_PIDM = SGBSTDN_PIDM
                        And aa.SORLCUR_CAMP_CODE =    A.SGBSTDN_CAMP_CODE
                        And aa.SORLCUR_PROGRAM    =    A.sgbstdn_program_1
                        and aa.SORLCUR_LMOD_CODE = 'LEARNER'
                        And aa.SORLCUR_ROLL_IND = 'Y'
                        And aa.SORLCUR_CACT_CODE = 'ACTIVE'
                        AND SZTALGO_NO_REGLA=P_REGLA
                        And aa.SORLCUR_SEQNO = (select max (aa1.SORLCUR_SEQNO)
                                                                   from SORLCUR aa1
                                                                   Where aa.sorlcur_pidm = aa1.sorlcur_pidm
                                                                   And aa.SORLCUR_PROGRAM = aa1.SORLCUR_PROGRAM
                                                                   And  aa.SORLCUR_LMOD_CODE =  aa1.SORLCUR_LMOD_CODE
                                                                   and aa.SORLCUR_ROLL_IND = aa1.SORLCUR_ROLL_IND
                                                                   And aa.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE)
                        And a.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
                                                        from sgbstdn b1
                                                        Where a.sgbstdn_pidm = b1.sgbstdn_pidm
                                                        And a.sgbstdn_program_1 = b1.sgbstdn_program_1)
                        And  aa.SORLCUR_CAMP_CODE = SZTALGO_CAMP_CODE
                        And aa.SORLCUR_LEVL_CODE = SZTALGO_LEVL_CODE
--                        And aa.SORLCUR_START_DATE  in (select SZTALGO_FECHA_ANT
--                                                                      from SZTALGO, SFRSTCR ax
--                                                                      Where  aa.SORLCUR_CAMP_CODE = SZTALGO_CAMP_CODE
--                                                                       And aa.SORLCUR_LEVL_CODE = SZTALGO_LEVL_CODE
--                                                                       And aa.sorlcur_pidm = ax.SFRSTCR_pidm
--                                                                       and SZTALGO_CAMP_CODE = ax.SFRSTCR_CAMP_CODE
--                                                                       And SZTALGO_LEVL_CODE = ax.SFRSTCR_LEVL_CODE
--                                                                       AND SZTALGO_NO_REGLA=P_REGLA
--                                                                       and ax.SFRSTCR_TERM_CODE = (select max (ax1.SFRSTCR_TERM_CODE)
--                                                                                                                         from SFRSTCR ax1
--                                                                                                                         Where ax.SFRSTCR_pidm = ax1.SFRSTCR_pidm
--                                                                                                                         And ax.SFRSTCR_CAMP_CODE = ax1.SFRSTCR_CAMP_CODE
--                                                                                                                         And ax.SFRSTCR_LEVL_CODE = ax1.SFRSTCR_LEVL_CODE
--                                                                                                                        And ax.SFRSTCR_PTRM_CODE = ax1.SFRSTCR_PTRM_CODE)
--                                                                      And  SZTALGO_PTRM_CODE = ax.SFRSTCR_PTRM_CODE (+)
--                                                                       )
                         And   A.SGBSTDN_PIDM = d.SPRADDR_PIDM (+)
                        And aa.sorlcur_camp_code =SZTDTEC_CAMP_CODE
                        And aa.SORLCUR_PROGRAM  = SZTDTEC_PROGRAM
                        And aa.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                        And SZTDTEC_PERIODICIDAD = 1
                        and A.SGBSTDN_STYP_CODE IN('C','F','N','R')
                        and A.SGBSTDN_PIDM = p_pidm
                        UNION
                        select DISTINCT
                                   A.SGBSTDN_PIDM SGBSTDN_PIDM,
                                   SPRIDEN_ID as id_Alumno,
                                   regexp_substr(SPRIDEN_LAST_NAME, '[^/]*') as ApellidoPaterno,
                                   NVL(substr(regexp_substr(SPRIDEN_LAST_NAME, '/[^/]*'),2), 0) as ApellidoMaterno,
                                   SPRIDEN_FIRST_NAME as Nombres,
                                   TO_CHAR(NVL(TRUNC(MONTHS_BETWEEN(SYSDATE, SPBPERS_BIRTH_DATE) / 12), 0)) as Edad,
                                   d.Res_Calle,
                                   d.Res_Colonia,
                                   d.Res_CP,
                                   d.Id_Ciudad,
                                   '0' as Id_TipoJornada,
                                   d.Id_Estado,
                                   d.Id_Pais,
                                   NVL(SGBSTDN_CAMP_CODE, 0) as Campus,
                                   NVL(SPBPERS_SEX, 0) as Id_Genero,
                                  -- TO_CHAR(NVL(SPBPERS_BIRTH_DATE, '1/01/1900'),'DD/MM/YYYY') as FechaNacimiento,
                                   case when SGBSTDN_STST_CODE IN ('AS','MA','PR') then 'A'
                                   else 'I'
                                   end as id_EstadoActivo,
                                   aa.SORLCUR_START_DATE FECHA_INICIO,
                                   A.SGBSTDN_STYP_CODE estatus,
                                   SORLCUR_ADMT_CODE equi,
                                   SGBSTDN_LEVL_CODE
                    from SGBSTDN A ,
                         SPRIDEN,
                         SPBPERS ,
                         STVCAMP,
                         SZTDTEC ,
                         sgrstsp,
                         SORLCUR aa ,
                         SZTALGO,
                         (select a.SPRADDR_PIDM ,
                                 NVL(a.SPRADDR_STREET_LINE1, 0) as Res_Calle,
                                 NVL(a.SPRADDR_STREET_LINE2, 0) as Res_Colonia,
                                 substr(NVL(a.SPRADDR_ZIP,'0'),1,5) as Res_CP,
                                 NVL(a.SPRADDR_CNTY_CODE, '00000') as Id_Ciudad,
                                 NVL(a.SPRADDR_STAT_CODE, '00') as Id_Estado,
                                 NVL(a.SPRADDR_NATN_CODE, 'XX') as Id_Pais
                          from SPRADDR a
                          Where a.SPRADDR_SURROGATE_ID = (select max (a1.SPRADDR_SURROGATE_ID)
                                                         from SPRADDR a1
                                                         where   a1.SPRADDR_PIDM =  a.SPRADDR_PIDM)
                         ) d
                    where A.SGBSTDN_PIDM = SPRIDEN_PIDM
                    And SPRIDEN_CHANGE_IND is NULL
                    And A.SGBSTDN_PIDM = SPBPERS_PIDM (+)
                    And A.SGBSTDN_CAMP_CODE = STVCAMP_CODE
                    --AND SPRIDEN_ID ='010000548'
                    And A.SGBSTDN_PIDM = sgrstsp_PIDM
                    And aa.SORLCUR_PIDM = SGBSTDN_PIDM
                    And aa.SORLCUR_PROGRAM    =    A.sgbstdn_program_1
                    And aa.SORLCUR_CAMP_CODE =    A.SGBSTDN_CAMP_CODE
                    AND SZTALGO_NO_REGLA=p_regla
                    And  aa.SORLCUR_CAMP_CODE = SZTALGO_CAMP_CODE
                    And aa.SORLCUR_LEVL_CODE = SZTALGO_LEVL_CODE
                    And aa.sorlcur_camp_code =SZTDTEC_CAMP_CODE
                    And aa.SORLCUR_PROGRAM  = SZTDTEC_PROGRAM
                    And aa.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                    And aa.SORLCUR_SEQNO = (select max (aa1.SORLCUR_SEQNO)
                                                               from SORLCUR aa1
                                                               Where aa.sorlcur_pidm = aa1.sorlcur_pidm
                                                               And aa.SORLCUR_PROGRAM = aa1.SORLCUR_PROGRAM
                                                               And  aa.SORLCUR_LMOD_CODE =  aa1.SORLCUR_LMOD_CODE
                                                               and aa.SORLCUR_ROLL_IND = aa1.SORLCUR_ROLL_IND
                                                               And aa.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE)
                    And A.SGBSTDN_PIDM = d.SPRADDR_PIDM (+)
                    And a.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
                                                    from sgbstdn b1
                                                    Where a.sgbstdn_pidm = b1.sgbstdn_pidm
                                                    And a.sgbstdn_program_1 = b1.sgbstdn_program_1)
                    And SGRSTSP_STSP_CODE = 'AS'
                    and aa.SORLCUR_LMOD_CODE = 'LEARNER'
                    And aa.SORLCUR_ROLL_IND = 'Y'
                    And aa.SORLCUR_CACT_CODE = 'ACTIVE'
                    and A.SGBSTDN_STYP_CODE IN ('R','F','N','C')
                    and A.SGBSTDN_PIDM = p_pidm
                    And SZTDTEC_PERIODICIDAD = 1
                    AND SZTALGO_FECHA_NEW =  SORLCUR_START_DATE
                    and to_char(SORLCUR_START_DATE,'DD/MM/RRRR') in (select distinct TO_CHAR(SZTALGO_FECHA_NEW,'DD/MM/RRRR')
                                                                     from sztalgo
                                                                     where 1 = 1
                                                                     and sztalgo_no_regla = p_regla)

             ) loop


                begin
                   Insert into AS_ALUMNOS values (
                                                                     c.SGBSTDN_PIDM
                                                                    ,c.ID_ALUMNO
                                                                    ,c.APELLIDOPATERNO
                                                                    ,c.APELLIDOMATERNO
                                                                    ,c.NOMBRES
                                                                    ,c.EDAD
                                                                    ,c.RES_CALLE
                                                                    ,c.SGBSTDN_LEVL_CODE
                                                                    ,c.RES_CP
                                                                    ,c.ID_CIUDAD
                                                                    ,c.ID_TIPOJORNADA
                                                                    ,c.ID_ESTADO
                                                                    ,c.ID_PAIS
                                                                    ,c.CAMPUS
                                                                    ,c.ID_GENERO
                                                                    ,null--c.FECHANACIMIENTO
                                                                    ,c.ID_ESTADOACTIVO
                                                                    ,c.FECHA_INICIO
                                                                    ,SYSDATE
                                                                    ,USER
                                                                    ,p_regla
                                                                    ,c.estatus
                                                                    ,c.equi
                                                                    );

                    DBMS_OUTPUT.PUT_LINE('Inserta ');

                    Commit;


                 EXCEPTION WHEN OTHERS THEN

                    DBMS_OUTPUT.PUT_LINE('Entra  al 5 '||sqlerrm);
                 END;

             End loop;
                Commit;

  End if;

  If  vl_existe_1 >= 1 then
  DBMS_OUTPUT.PUT_LINE('Entra  al 6');


       For c in (

        select DISTINCT
                            A.SGBSTDN_PIDM SGBSTDN_PIDM,
                            SPRIDEN_ID as id_Alumno,
                            regexp_substr(SPRIDEN_LAST_NAME, '[^/]*') as ApellidoPaterno,
                            NVL(substr(regexp_substr(SPRIDEN_LAST_NAME, '/[^/]*'),2), 0) as ApellidoMaterno,
                            SPRIDEN_FIRST_NAME as Nombres,
                            TO_CHAR(NVL(TRUNC(MONTHS_BETWEEN(SYSDATE, SPBPERS_BIRTH_DATE) / 12), 0)) as Edad,
                            d.Res_Calle,
                            d.Res_Colonia,
                            d.Res_CP,
                            d.Id_Ciudad,
                            '0' as Id_TipoJornada,
                            d.Id_Estado,
                            d.Id_Pais,
                            NVL(SGBSTDN_CAMP_CODE, 0) as Campus,
                            NVL(SPBPERS_SEX, 0) as Id_Genero,
--                            TO_CHAR(NVL(SPBPERS_BIRTH_DATE, '1/01/1900'),'DD/MM/YYYY') as FechaNacimiento,
                            case when SGBSTDN_STST_CODE IN ('AS','MA','PR') then 'A'
                            else 'I'
                            end as id_EstadoActivo,
                            aa.SORLCUR_START_DATE FECHA_INICIO,
                            A.SGBSTDN_STYP_CODE estatus,
                            SORLCUR_ADMT_CODE equi,
                            SGBSTDN_LEVL_CODE
                        from SGBSTDN A , SPRIDEN, SPBPERS, SZTDTEC
                               ,STVCAMP, sgrstsp, SORLCUR aa , SZTALGO, (select a.SPRADDR_PIDM ,
                                                                                                    NVL(a.SPRADDR_STREET_LINE1, 0) as Res_Calle,
                                                                                                    NVL(a.SPRADDR_STREET_LINE2, 0) as Res_Colonia,
                                                                                                    substr(NVL(a.SPRADDR_ZIP,'0'),1,5) as Res_CP,
                                                                                                    NVL(a.SPRADDR_CNTY_CODE, '00000') as Id_Ciudad,
                                                                                                    NVL(a.SPRADDR_STAT_CODE, '00') as Id_Estado,
                                                                                                    NVL(a.SPRADDR_NATN_CODE, 'XX') as Id_Pais
                                                                                                 from SPRADDR a
                                                                                                Where a.SPRADDR_SURROGATE_ID = (select max (a1.SPRADDR_SURROGATE_ID)
                                                                                                                                                    from SPRADDR a1
                                                                                                                                                    where   a1.SPRADDR_PIDM =  a.SPRADDR_PIDM)) d
                        where A.SGBSTDN_PIDM = SPRIDEN_PIDM
                        And SPRIDEN_CHANGE_IND is NULL
                        And A.SGBSTDN_PIDM = SPBPERS_PIDM (+)
                        And A.SGBSTDN_CAMP_CODE = STVCAMP_CODE
                        And A.SGBSTDN_PIDM = sgrstsp_PIDM
                        And SGRSTSP_STSP_CODE = 'AS'
                        And aa.SORLCUR_PIDM = SGBSTDN_PIDM
                        And aa.SORLCUR_CAMP_CODE =    A.SGBSTDN_CAMP_CODE
                        And aa.SORLCUR_PROGRAM    =    A.sgbstdn_program_1
                        and aa.SORLCUR_LMOD_CODE = 'LEARNER'
                        And aa.SORLCUR_ROLL_IND = 'Y'
                        And aa.SORLCUR_CACT_CODE = 'ACTIVE'
                        AND SZTALGO_NO_REGLA=P_REGLA
                        And aa.SORLCUR_SEQNO = (select max (aa1.SORLCUR_SEQNO)
                                                                   from SORLCUR aa1
                                                                   Where aa.sorlcur_pidm = aa1.sorlcur_pidm
                                                                   And aa.SORLCUR_PROGRAM = aa1.SORLCUR_PROGRAM
                                                                   And  aa.SORLCUR_LMOD_CODE =  aa1.SORLCUR_LMOD_CODE
                                                                   And aa.SORLCUR_ROLL_IND = aa1.SORLCUR_ROLL_IND
                                                                   And aa.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE)
                        And a.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
                                                        from sgbstdn b1
                                                        Where a.sgbstdn_pidm = b1.sgbstdn_pidm
                                                        And a.sgbstdn_program_1 = b1.sgbstdn_program_1)
                        And  aa.SORLCUR_CAMP_CODE = SZTALGO_CAMP_CODE
                        And aa.SORLCUR_LEVL_CODE = SZTALGO_LEVL_CODE
--                        And aa.SORLCUR_START_DATE  in (select SZTALGO_FECHA_ANT
--                                                       from SZTALGO, SFRSTCR ax
--                                                       where  SZTALGO_TIPO_CARGA != 'Regular'
--                                                       and  aa.SORLCUR_CAMP_CODE = SZTALGO_CAMP_CODE
--                                                       And aa.SORLCUR_LEVL_CODE = SZTALGO_LEVL_CODE
--                                                       And aa.sorlcur_pidm = ax.SFRSTCR_pidm
--                                                       and SZTALGO_CAMP_CODE = ax.SFRSTCR_CAMP_CODE
--                                                       And SZTALGO_LEVL_CODE = ax.SFRSTCR_LEVL_CODE
--                                                       AND SZTALGO_NO_REGLA=P_REGLA
--                                                       and ax.SFRSTCR_TERM_CODE = (select max (ax1.SFRSTCR_TERM_CODE)
--                                                                                   from SFRSTCR ax1
--                                                                                   Where ax.SFRSTCR_pidm = ax1.SFRSTCR_pidm
--                                                                                   And ax.SFRSTCR_CAMP_CODE = ax1.SFRSTCR_CAMP_CODE
--                                                                                   And ax.SFRSTCR_LEVL_CODE = ax1.SFRSTCR_LEVL_CODE
--                                                                                   And ax.SFRSTCR_PTRM_CODE = ax1.SFRSTCR_PTRM_CODE)
--                                                       And  SZTALGO_PTRM_CODE = ax.SFRSTCR_PTRM_CODE (+)
--                                                        )
                       And A.SGBSTDN_PIDM = D.SPRADDR_PIDM (+)
                       And aa.sorlcur_camp_code =SZTDTEC_CAMP_CODE
                       And aa.SORLCUR_PROGRAM  = SZTDTEC_PROGRAM
                       And aa.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                       And SZTDTEC_PERIODICIDAD = 2
                       and A.SGBSTDN_STYP_CODE IN('C','F','N','R')
                       and A.SGBSTDN_PIDM = p_pidm
                       UNION
                       select DISTINCT
                                   A.SGBSTDN_PIDM SGBSTDN_PIDM,
                                   SPRIDEN_ID as id_Alumno,
                                   regexp_substr(SPRIDEN_LAST_NAME, '[^/]*') as ApellidoPaterno,
                                   NVL(substr(regexp_substr(SPRIDEN_LAST_NAME, '/[^/]*'),2), 0) as ApellidoMaterno,
                                   SPRIDEN_FIRST_NAME as Nombres,
                                   TO_CHAR(NVL(TRUNC(MONTHS_BETWEEN(SYSDATE, SPBPERS_BIRTH_DATE) / 12), 0)) as Edad,
                                   d.Res_Calle,
                                   d.Res_Colonia,
                                   d.Res_CP,
                                   d.Id_Ciudad,
                                   '0' as Id_TipoJornada,
                                   d.Id_Estado,
                                   d.Id_Pais,
                                   NVL(SGBSTDN_CAMP_CODE, 0) as Campus,
                                   NVL(SPBPERS_SEX, 0) as Id_Genero,
--                                   TO_CHAR(NVL(SPBPERS_BIRTH_DATE, '1/01/1900'),'DD/MM/YYYY') as FechaNacimiento,
                                   case when SGBSTDN_STST_CODE IN ('AS','MA','PR') then 'A'
                                   else 'I'
                                   end as id_EstadoActivo,
                                   aa.SORLCUR_START_DATE FECHA_INICIO,
                                   A.SGBSTDN_STYP_CODE estatus,
                                   SORLCUR_ADMT_CODE equi,
                                   SGBSTDN_LEVL_CODE
                    from SGBSTDN A ,
                         SPRIDEN,
                         SPBPERS ,
                         STVCAMP,
                         SZTDTEC ,
                         sgrstsp,
                         SORLCUR aa ,
                         SZTALGO,
                         (select a.SPRADDR_PIDM ,
                                 NVL(a.SPRADDR_STREET_LINE1, 0) as Res_Calle,
                                 NVL(a.SPRADDR_STREET_LINE2, 0) as Res_Colonia,
                                 substr(NVL(a.SPRADDR_ZIP,'0'),1,5) as Res_CP,
                                 NVL(a.SPRADDR_CNTY_CODE, '00000') as Id_Ciudad,
                                 NVL(a.SPRADDR_STAT_CODE, '00') as Id_Estado,
                                 NVL(a.SPRADDR_NATN_CODE, 'XX') as Id_Pais
                          from SPRADDR a
                          Where a.SPRADDR_SURROGATE_ID = (select max (a1.SPRADDR_SURROGATE_ID)
                                                         from SPRADDR a1
                                                         where   a1.SPRADDR_PIDM =  a.SPRADDR_PIDM)
                         ) d
                    where A.SGBSTDN_PIDM = SPRIDEN_PIDM
                    And SPRIDEN_CHANGE_IND is NULL
                    And A.SGBSTDN_PIDM = SPBPERS_PIDM (+)
                    And A.SGBSTDN_CAMP_CODE = STVCAMP_CODE
                    --AND SPRIDEN_ID ='010000548'
                    And A.SGBSTDN_PIDM = sgrstsp_PIDM
                    And aa.SORLCUR_PIDM = SGBSTDN_PIDM
                    And aa.SORLCUR_PROGRAM    =    A.sgbstdn_program_1
                    And aa.SORLCUR_CAMP_CODE =    A.SGBSTDN_CAMP_CODE
                    AND SZTALGO_NO_REGLA=p_regla
                    And  aa.SORLCUR_CAMP_CODE = SZTALGO_CAMP_CODE
                    And aa.SORLCUR_LEVL_CODE = SZTALGO_LEVL_CODE
                    And aa.sorlcur_camp_code =SZTDTEC_CAMP_CODE
                    And aa.SORLCUR_PROGRAM  = SZTDTEC_PROGRAM
                    And aa.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                    And aa.SORLCUR_SEQNO = (select max (aa1.SORLCUR_SEQNO)
                                                               from SORLCUR aa1
                                                               Where aa.sorlcur_pidm = aa1.sorlcur_pidm
                                                               And aa.SORLCUR_PROGRAM = aa1.SORLCUR_PROGRAM
                                                               And  aa.SORLCUR_LMOD_CODE =  aa1.SORLCUR_LMOD_CODE
                                                               and aa.SORLCUR_ROLL_IND = aa1.SORLCUR_ROLL_IND
                                                               And aa.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE)
                    And A.SGBSTDN_PIDM = d.SPRADDR_PIDM (+)
                    And a.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
                                                    from sgbstdn b1
                                                    Where a.sgbstdn_pidm = b1.sgbstdn_pidm
                                                    And a.sgbstdn_program_1 = b1.sgbstdn_program_1)
                    And SGRSTSP_STSP_CODE = 'AS'
                    and aa.SORLCUR_LMOD_CODE = 'LEARNER'
                    And aa.SORLCUR_ROLL_IND = 'Y'
                    And aa.SORLCUR_CACT_CODE = 'ACTIVE'
                    and A.SGBSTDN_STYP_CODE IN ('R','F','N','C')
                    And SZTDTEC_PERIODICIDAD = 2
                    AND SZTALGO_FECHA_NEW =  SORLCUR_START_DATE
                    and A.SGBSTDN_PIDM = p_pidm
                    and to_char(SORLCUR_START_DATE,'DD/MM/YYYY') in (select distinct TO_CHAR(SZTALGO_FECHA_NEW,'DD/MM/YYYY')
                                                                       from sztalgo
                                                                       where 1 = 1
                                                                       and sztalgo_no_regla = p_regla)
          ) loop
                DBMS_OUTPUT.PUT_LINE('alumno  ');

                BEGIN
                   Insert into AS_ALUMNOS values (
                                                                    c.SGBSTDN_PIDM
                                                                    ,c.ID_ALUMNO
                                                                    ,c.APELLIDOPATERNO
                                                                    ,c.APELLIDOMATERNO
                                                                    ,c.NOMBRES
                                                                    ,c.EDAD
                                                                    ,c.RES_CALLE
                                                                    ,c.SGBSTDN_LEVL_CODE
                                                                    ,c.RES_CP
                                                                    ,c.ID_CIUDAD
                                                                    ,c.ID_TIPOJORNADA
                                                                    ,c.ID_ESTADO
                                                                    ,c.ID_PAIS
                                                                    ,c.CAMPUS
                                                                    ,c.ID_GENERO
                                                                    ,null
                                                                    ,c.ID_ESTADOACTIVO
                                                                    ,c.FECHA_INICIO
                                                                    ,SYSDATE
                                                                    ,USER
                                                                    ,P_regla
                                                                    ,c.estatus
                                                                    ,c.equi
                                                                    );
               EXCEPTION WHEN OTHERS THEN

                DBMS_OUTPUT.PUT_LINE('Entra  al 7');

               END;
             End loop;

             Commit;

  End IF;


  If  vl_existe_anual >= 1 then
  DBMS_OUTPUT.PUT_LINE('Entra  al 6');


       For c in (

                SELECT distinct e.SGBSTDN_PIDM,
                                    d.SPRIDEN_ID as id_Alumno,
                                    regexp_substr(d.SPRIDEN_LAST_NAME, '[^/]*') as ApellidoPaterno,
                                    NVL(substr(regexp_substr(d.SPRIDEN_LAST_NAME, '/[^/]*'),2), 0) as ApellidoMaterno,
                                    d.SPRIDEN_FIRST_NAME as Nombres,
                                    TO_CHAR(NVL(TRUNC(MONTHS_BETWEEN(SYSDATE,s.SPBPERS_BIRTH_DATE) / 12), 0)) as Edad,
                                    NVL(x.SPRADDR_STREET_LINE1, 0) as Res_Calle,
                                    NVL(x.SPRADDR_STREET_LINE2, 0) as Res_Colonia,
                                    substr(NVL(x.SPRADDR_ZIP,'0'),1,5) as Res_CP,
                                    NVL(x.SPRADDR_CNTY_CODE, '00000') as Id_Ciudad,
                                    '0' as Id_TipoJornada,
                                    NVL(x.SPRADDR_STAT_CODE, '00') as Id_Estado,
                                    NVL(x.SPRADDR_NATN_CODE, 'XX') as Id_Pais,
                                    NVL(e.SGBSTDN_CAMP_CODE, 0) as Campus,
                                    NVL(s.SPBPERS_SEX, 0) as Id_Genero,
                                    TO_CHAR(NVL(s.SPBPERS_BIRTH_DATE, '1/01/1900'),'DD/MM/YYYY') as FechaNacimiento,
                                    case when e.SGBSTDN_STST_CODE IN ('AS','MA','PR') then 'A'
                                      else 'I'
                                    end as id_EstadoActivo,
                                    a.SORLCUR_START_DATE FECHA_INICIO,
                                    e.SGBSTDN_STYP_CODE estatus,
                                    a.sorlcur_admt_code equi,
                                    A.SORLCUR_RATE_CODE
                    FROM sorlcur a
                    join sgbstdn e on sgbstdn_pidm = a.sorlcur_pidm
                                  AND a.SORLCUR_PROGRAM   = e.sgbstdn_program_1
                                  AND a.SORLCUR_CAMP_CODE = e.SGBSTDN_CAMP_CODE
                                  AND e.SGBSTDN_TERM_CODE_EFF = (SELECT max (b1.SGBSTDN_TERM_CODE_EFF)
                                                                  FROM sgbstdn b1
                                                                  WHERE 1 = 1
                                                                  AND e.sgbstdn_pidm = b1.sgbstdn_pidm
                                                                  AND e.sgbstdn_program_1 = b1.sgbstdn_program_1)
                                  AND e.SGBSTDN_STYP_CODE IN ('R','F','N','C')
                    JOIN spriden d on d.spriden_change_ind is null
                                  AND d.spriden_pidm = a.sorlcur_pidm
                    left join SPBPERS s on s.SPBPERS_PIDM =   a.sorlcur_pidm
                    left join SPRADDR x on a.sorlcur_pidm = x.SPRADDR_PIDM
                                       AND x.SPRADDR_SURROGATE_ID = (SELECT max (a1.SPRADDR_SURROGATE_ID)
                                                                     FROM SPRADDR a1
                                                                     WHERE   a1.SPRADDR_PIDM =  x.SPRADDR_PIDM)
                    WHERE 1 = 1
                    AND  a.sorlcur_pidm=p_pidm
                    AND a.SORLCUR_LMOD_CODE = 'LEARNER'
                    AND a.SORLCUR_ROLL_IND = 'Y'
                    AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                    AND a.SORLCUR_CAMP_CODE ='UTS'
                    AND a.SORLCUR_LEVL_CODE IN ('EC','ID')
                    AND substr(a.sorlcur_program,4,1)in ('D','C')
                    AND a.SORLCUR_SEQNO = (SELECT max (aa1.SORLCUR_SEQNO)
                                            FROM SORLCUR aa1
                                            WHERE 1 = 1
                                            AND a.sorlcur_pidm = aa1.sorlcur_pidm
                                            AND a.SORLCUR_PROGRAM = aa1.SORLCUR_PROGRAM
                                            AND a.SORLCUR_LMOD_CODE =  aa1.SORLCUR_LMOD_CODE
                                            AND a.SORLCUR_ROLL_IND = aa1.SORLCUR_ROLL_IND
                                            AND a.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE)
            AND EXISTS (SELECT NULL
                                FROM SZTALGO b
                                WHERE 1 = 1
                                AND b.sztalgo_no_regla = P_regla
                                AND b.SZTALGO_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                AND b.SZTALGO_LEVL_CODE  =a.SORLCUR_LEVL_CODE
                                AND b.SZTALGO_FECHA_NEW = A.SORLCUR_START_DATE
                                 )
            UNION
            SELECT distinct e.SGBSTDN_PIDM,
                                    d.SPRIDEN_ID as id_Alumno,
                                    regexp_substr(d.SPRIDEN_LAST_NAME, '[^/]*') as ApellidoPaterno,
                                    NVL(substr(regexp_substr(d.SPRIDEN_LAST_NAME, '/[^/]*'),2), 0) as ApellidoMaterno,
                                    d.SPRIDEN_FIRST_NAME as Nombres,
                                    TO_CHAR(NVL(TRUNC(MONTHS_BETWEEN(SYSDATE,s.SPBPERS_BIRTH_DATE) / 12), 0)) as Edad,
                                    NVL(x.SPRADDR_STREET_LINE1, 0) as Res_Calle,
                                    NVL(x.SPRADDR_STREET_LINE2, 0) as Res_Colonia,
                                    substr(NVL(x.SPRADDR_ZIP,'0'),1,5) as Res_CP,
                                    NVL(x.SPRADDR_CNTY_CODE, '00000') as Id_Ciudad,
                                    '0' as Id_TipoJornada,
                                    NVL(x.SPRADDR_STAT_CODE, '00') as Id_Estado,
                                    NVL(x.SPRADDR_NATN_CODE, 'XX') as Id_Pais,
                                    NVL(e.SGBSTDN_CAMP_CODE, 0) as Campus,
                                    NVL(s.SPBPERS_SEX, 0) as Id_Genero,
                                    TO_CHAR(NVL(s.SPBPERS_BIRTH_DATE, '1/01/1900'),'DD/MM/YYYY') as FechaNacimiento,
                                    case when e.SGBSTDN_STST_CODE IN ('AS','MA','PR') then 'A'
                                      else 'I'
                                    end as id_EstadoActivo,
                                    a.SORLCUR_START_DATE FECHA_INICIO,
                                    e.SGBSTDN_STYP_CODE estatus,
                                    a.sorlcur_admt_code equi,
                                    A.SORLCUR_RATE_CODE
                    FROM sorlcur a
                    join sgbstdn e on sgbstdn_pidm = a.sorlcur_pidm
                                  AND a.SORLCUR_PROGRAM   = e.sgbstdn_program_1
                                  AND a.SORLCUR_CAMP_CODE = e.SGBSTDN_CAMP_CODE
                                  AND e.SGBSTDN_TERM_CODE_EFF = (SELECT max (b1.SGBSTDN_TERM_CODE_EFF)
                                                                  FROM sgbstdn b1
                                                                  WHERE 1 = 1
                                                                  AND e.sgbstdn_pidm = b1.sgbstdn_pidm
                                                                  AND e.sgbstdn_program_1 = b1.sgbstdn_program_1)
                                  AND e.SGBSTDN_STYP_CODE IN ('R','F','N','C')
                    JOIN spriden d on d.spriden_change_ind is null
                                  AND d.spriden_pidm = a.sorlcur_pidm
                    left join SPBPERS s on s.SPBPERS_PIDM =   a.sorlcur_pidm
                    left join SPRADDR x on a.sorlcur_pidm = x.SPRADDR_PIDM
                                       AND x.SPRADDR_SURROGATE_ID = (SELECT max (a1.SPRADDR_SURROGATE_ID)
                                                                     FROM SPRADDR a1
                                                                     WHERE   a1.SPRADDR_PIDM =  x.SPRADDR_PIDM)
                    WHERE 1 = 1
                    AND  a.sorlcur_pidm=p_pidm
                    AND a.SORLCUR_LMOD_CODE = 'LEARNER'
                    AND a.SORLCUR_ROLL_IND = 'Y'
                    AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                    AND a.SORLCUR_CAMP_CODE ='EAF'
                    AND a.SORLCUR_LEVL_CODE IN ('EC','ID')
--                    AND substr(a.sorlcur_program,4,1)='D'
                    AND a.SORLCUR_SEQNO = (SELECT max (aa1.SORLCUR_SEQNO)
                                            FROM SORLCUR aa1
                                            WHERE 1 = 1
                                            AND a.sorlcur_pidm = aa1.sorlcur_pidm
                                            AND a.SORLCUR_PROGRAM = aa1.SORLCUR_PROGRAM
                                            AND a.SORLCUR_LMOD_CODE =  aa1.SORLCUR_LMOD_CODE
                                            AND a.SORLCUR_ROLL_IND = aa1.SORLCUR_ROLL_IND
                                            AND a.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE)
            AND EXISTS (SELECT NULL
                                FROM SZTALGO b
                                WHERE 1 = 1
                                AND b.sztalgo_no_regla = P_regla
                                AND b.SZTALGO_CAMP_CODE = a.SORLCUR_CAMP_CODE
                                AND b.SZTALGO_LEVL_CODE  =a.SORLCUR_LEVL_CODE
                                AND b.SZTALGO_FECHA_NEW = A.SORLCUR_START_DATE
                                 )

          ) loop
                DBMS_OUTPUT.PUT_LINE('alumno  ');

                BEGIN
                   Insert into AS_ALUMNOS values (
                                                                    c.SGBSTDN_PIDM
                                                                    ,c.ID_ALUMNO
                                                                    ,c.APELLIDOPATERNO
                                                                    ,c.APELLIDOMATERNO
                                                                    ,c.NOMBRES
                                                                    ,c.EDAD
                                                                    ,c.RES_CALLE
                                                                    ,c.Res_Colonia
                                                                    ,c.RES_CP
                                                                    ,c.ID_CIUDAD
                                                                    ,c.ID_TIPOJORNADA
                                                                    ,c.ID_ESTADO
                                                                    ,c.ID_PAIS
                                                                    ,c.CAMPUS
                                                                    ,c.ID_GENERO
                                                                    ,null
                                                                    ,c.ID_ESTADOACTIVO
                                                                    ,c.FECHA_INICIO
                                                                    ,SYSDATE
                                                                    ,USER
                                                                    ,P_regla
                                                                    ,c.estatus
                                                                    ,c.equi
                                                                    );
               EXCEPTION WHEN OTHERS THEN

                DBMS_OUTPUT.PUT_LINE('Entra  al 7');

               END;
             End loop;

             Commit;

  End IF;


END p_alumnos_pidm;

 PROCEDURE p_programa_x_pidm (P_REGLA NUMBER,
                                 p_pidm  NUMBER)IS
  vl_existe         NUMBER;
      l_term_code_eff   VARCHAR2 (100);
      l_equi            VARCHAR2 (100);
      l_rate            VARCHAR2 (100);
      l_programa        VARCHAR2 (100);
      l_sp              NUMBER;
      l_type_code       VARCHAR2 (100);
      l_fecha_incio     DATE;
      l_periodo_ctl     VARCHAR2 (100);
      l_nivel           VARCHAR2 (100);
      l_estatus         VARCHAR2 (100);
      l_jornada         VARCHAR2 (100);
   --l_contar  number;

   --tztprog

   BEGIN
      --BEGIN PKG_DEVENGAMIENTO.P_ALUMNO;  END;

      DELETE rel_programaxalumno
      WHERE rel_programaxalumno_no_regla = p_regla
      and SGBSTDN_PIDM = p_pidm;

      COMMIT;

      DELETE rel_programaxalumno
      WHERE rel_programaxalumno_no_regla IS NULL;

      COMMIT;

      FOR c
         IN (SELECT sgbstdn_pidm,
                    id_alumno,
                    campus,
                    NULL concentracion,
                    NULL area_de_salida,
                    NULL area_de_salida2,
                    NULL TIPO_JORNADA,
                    as_alumnos_equi equi,
                    RES_COLONIA  nivel,-- se uso para la nivel
                    cur.sorlcur_program programa,
                    cur.sorlcur_key_seqno SP
             FROM as_alumnos,sorlcur cur
             WHERE     1 = 1
             AND as_alumnos_no_regla = p_regla
             AND sgbstdn_pidm=cur.sorlcur_pidm
             AND id_estadoactivo = 'A'
             and SGBSTDN_PIDM = p_pidm
             AND cur.sorlcur_lmod_code = 'LEARNER'
             AND cur.sorlcur_roll_ind = 'Y'
             AND cur.sorlcur_cact_code = 'ACTIVE'
             AND cur.SORLCUR_LEVL_CODE IN ('EC','ID')
             AND cur.sorlcur_seqno = (SELECT MAX (aa1.sorlcur_seqno)
                                       FROM sorlcur aa1
                                       WHERE     cur.sorlcur_pidm = aa1.sorlcur_pidm
                                       AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
                                       AND cur.sorlcur_roll_ind = aa1.sorlcur_roll_ind
                                       AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code
                                       AND cur.SORLCUR_LEVL_CODE = aa1.SORLCUR_LEVL_CODE
                                       AND cur.SORLCUR_PROGRAM=aa1.SORLCUR_PROGRAM
                                      )
             )
      LOOP

--        BEGIN
--
--            SELECT DISTINCT sorlcur_program, cur.sorlcur_key_seqno
--            INTO l_programa, l_sp
--            FROM sorlcur cur
--            WHERE     1 = 1
--            AND cur.sorlcur_pidm = c.sgbstdn_pidm
--            AND cur.sorlcur_lmod_code = 'LEARNER'
--            AND cur.sorlcur_roll_ind = 'Y'
--            AND cur.sorlcur_cact_code = 'ACTIVE'
--            and cur.SORLCUR_LEVL_CODE =c.nivel
--            AND cur.sorlcur_seqno =
--                                   (SELECT MAX (aa1.sorlcur_seqno)
--                                    FROM sorlcur aa1
--                                    WHERE     cur.sorlcur_pidm = aa1.sorlcur_pidm
--                                    AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
--                                    AND cur.sorlcur_roll_ind = aa1.sorlcur_roll_ind
--                                    AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code
--                                    AND cur.SORLCUR_LEVL_CODE = aa1.SORLCUR_LEVL_CODE
--                                    );
--
--         EXCEPTION WHEN OTHERS THEN
--               NULL;
--         END;


         BEGIN

            SELECT MAX (b1.sgbstdn_term_code_eff)
            INTO l_term_code_eff
            FROM sgbstdn b1
            WHERE 1 = 1
            AND b1.sgbstdn_pidm = c.sgbstdn_pidm;
--            AND b1.sgbstdn_program_1 = l_programa;

         EXCEPTION WHEN OTHERS THEN
               NULL;
         END;


         BEGIN

             SELECT DISTINCT sgbstdn_styp_code,
                            sgbstdn_stst_code
             INTO l_type_code,
                 l_estatus
             FROM sgbstdn b1
             WHERE 1 = 1
             AND b1.sgbstdn_pidm = c.sgbstdn_pidm
             AND b1.sgbstdn_program_1 = c.programa OR b1.SGBSTDN_PROGRAM_2 = c.programa
             AND b1.sgbstdn_term_code_eff =
                                            (SELECT MAX (b2.sgbstdn_term_code_eff)
                                             FROM sgbstdn b2
                                             WHERE 1 = 1
                                             AND b2.sgbstdn_pidm = b1.sgbstdn_pidm
--                                             AND b2.sgbstdn_program_1 = b1.sgbstdn_program_1
                                             );
         EXCEPTION WHEN OTHERS THEN
               NULL;
         END;


         BEGIN

            SELECT DISTINCT cur.sorlcur_term_code_ctlg ctlg,
                            cur.sorlcur_levl_code,
                            cur.sorlcur_rate_code,
                            cur.sorlcur_start_date
            INTO l_periodo_ctl,
                 l_nivel,
                 l_rate,
                 l_fecha_incio
            FROM sorlcur cur
            WHERE     1 = 1
            AND cur.sorlcur_pidm = c.sgbstdn_pidm
            AND cur.sorlcur_lmod_code = 'LEARNER'
            AND cur.sorlcur_roll_ind = 'Y'
            AND cur.sorlcur_cact_code = 'ACTIVE'
            AND cur.sorlcur_key_seqno = c.sp
            AND cur.sorlcur_program = c.programa
            AND cur.sorlcur_seqno =
                                   (SELECT MAX (c1x.sorlcur_seqno)
                                    FROM sorlcur c1x
                                    WHERE 1 = 1
                                    AND cur.sorlcur_pidm = c1x.sorlcur_pidm
                                    AND cur.sorlcur_lmod_code = c1x.sorlcur_lmod_code
                                    AND cur.sorlcur_roll_ind =c1x.sorlcur_roll_ind
                                    AND cur.sorlcur_cact_code =c1x.sorlcur_cact_code
                                    AND cur.sorlcur_program =c1x.sorlcur_program
                                    AND cur.sorlcur_key_seqno = c1x.sorlcur_key_seqno);
         EXCEPTION WHEN OTHERS THEN
               l_periodo_ctl := '000000';
         END;

         BEGIN

--            SELECT CASE
--                      WHEN l_nivel IN ('MA') AND sgrsatt_atts_code IS NULL
--                      THEN
--                         '1MN2'
--                      WHEN l_nivel IN ('MS') AND sgrsatt_atts_code IS NULL
--                      THEN
--                         '1AN2'
--                      WHEN l_nivel = 'LI' AND sgrsatt_atts_code IS NULL
--                      THEN
--                         '1LC4'
--                      ELSE
--                         sgrsatt_atts_code
--                   END
--                      tipo_jornada
--            INTO l_jornada
--            FROM SGRSATT b
--            WHERE     1 = 1
--            AND sgrsatt_pidm = c.sgbstdn_pidm
--            AND sgrsatt_stsp_key_sequence = l_sp
--            And regexp_like(b.SGRSATT_ATTS_CODE, '^[0-9]')
--            AND b.sgrsatt_surrogate_id IN
--                                         (SELECT MAX (b1.sgrsatt_surrogate_id)
--                                          FROM sgrsatt b1
--                                          WHERE 1 = 1
--                                          AND b.sgrsatt_pidm = b1.sgrsatt_pidm
--                                          AND b.sgrsatt_stsp_key_sequence = b1.sgrsatt_stsp_key_sequence);
            SELECT
               CASE
               WHEN l_nivel IN ('MA') AND sgrsatt_atts_code IS NULL
               THEN
               '1MN2'
               WHEN l_nivel IN ('MS') AND sgrsatt_atts_code IS NULL
               THEN
               '1AN2'
               WHEN l_nivel = 'LI' AND sgrsatt_atts_code IS NULL
               THEN
               '1LC2'
               ELSE
               sgrsatt_atts_code
               END tipo_jornada
               INTO l_jornada
            FROM sgrsatt T
            WHERE t.sgrsatt_pidm = c.sgbstdn_pidm
            AND t.sgrsatt_stsp_key_sequence =c.sp
            AND REGEXP_LIKE (t.sgrsatt_atts_code , '^[0-9]')
            AND SUBSTR(t.sgrsatt_term_code_eff,5,1) NOT IN (8,9)
            AND t.sgrsatt_term_code_eff = (SELECT MAX(sgrsatt_term_code_eff)
                                            FROM sgrsatt tt
                                            WHERE tt.sgrsatt_pidm = t.sgrsatt_pidm
                                            AND tt.sgrsatt_stsp_key_sequence= t.sgrsatt_stsp_key_sequence
                                            AND SUBSTR(tt.sgrsatt_term_code_eff,5,2) NOT IN (8,9)
                                            AND REGEXP_LIKE (tt.sgrsatt_atts_code , '^[0-9]'))
            AND t.sgrsatt_activity_date = (SELECT MAX(sgrsatt_activity_date)
            FROM sgrsatt t1
            WHERE t1.sgrsatt_pidm = t.sgrsatt_pidm
            AND t1.sgrsatt_stsp_key_sequence = t.sgrsatt_stsp_key_sequence
            AND t1.sgrsatt_term_code_eff = t.sgrsatt_term_code_eff
            AND SUBSTR(t1.sgrsatt_term_code_eff,5,2) NOT IN (8,9)
            AND REGEXP_LIKE (t1.sgrsatt_atts_code , '^[0-9]')) ;


         EXCEPTION WHEN OTHERS THEN
               NULL;
         END;


         BEGIN
            INSERT INTO rel_programaxalumno
                                     VALUES (c.sgbstdn_pidm,
                                             c.id_alumno,
                                             c.campus,
                                             c.programa,
                                             l_term_code_eff,
                                             l_jornada,
                                             c.concentracion,
                                             c.area_de_salida,
                                             c.sp,
                                             l_type_code,
                                             c.area_de_salida2,
                                             l_fecha_incio,
                                             l_periodo_ctl,
                                             l_rate,
                                             l_nivel,
                                             0,
                                             p_regla,
                                             user,
                                             l_type_code,
                                             c.equi);
         EXCEPTION WHEN OTHERS THEN
               DBMS_OUTPUT.put_line ('Error al insertar REL_PROGRAMAXALUMNO ' || SQLERRM);
         END;


      END LOOP;

      --raise_application_error (-20002,'No se cargaron materias desde el dashboard');

--      begin
--
--            pkg_algoritmo_pidm.p_alumnos_x_pidm(p_regla,p_pidm);
--      exception when others then
--       raise_application_error (-20002,sqlerrm);
----        NULL;
--      end;

      COMMIT;


   END;

PROCEDURE p_alumnos_x_pidm (P_REGLA NUMBER,
                            p_pidm  NUMBER)
                             IS
      vl_existe               NUMBER;
      l_valida_campus_nivel   NUMBER;
--      l_materia_agp           VARCHAR2 (20);
      l_contador              NUMBER := 0;
      l_equi                  VARCHAR2 (20);
--      l_sql                   VARCHAR2 (500);
      l_periodo_ctl           VARCHAR2 (20);
      l_sp                    NUMBER;
      l_periodicidad          VARCHAR2 (1);
      l_ptrm                  VARCHAR2 (10);
      l_semis                 VARCHAR2 (10);
      l_cuenta_sfr            number;
--      l_bim                   varchar2(3);
      l_term_code             varchar2(6);
--      l_contar_algo           number;
--      l_contar_pr             number;
--      l_valida_alumno         number;
      l_contador_tope         number:=0;
      l_contador_tope2        number:=0;
      l_contador_tope3        number:=0;
      l_antcipado             VARCHAR2 (1);
      l_type_code             VARCHAR2 (3);
      l_contar_inc            number;
      vl_borraUIN             NUMBER;
      --Jpg@Create@Mar22
      lc_PC constant varchar2(2):='PC';
      lc_NA constant varchar2(2):='NA';
      lc_AP constant varchar2(2):='AP';
      lc_EC constant varchar2(2):='EC';
      lc_0  constant varchar2(1):='0';
      l_cuenta_prop number;
   BEGIN

      --raise_application_error (-20002,'entra a alumno 1.0');
     --

      BEGIN
         DELETE rel_alumnos_x_asignar                    --alumnos por materia
         WHERE rel_alumnos_x_asignar_no_regla = p_regla
         and SVRPROY_PIDM = p_pidm;
         COMMIT;
      END;

      BEGIN

         DELETE rel_alumnos_x_asignar                    --alumnos por materia
         WHERE rel_alumnos_x_asignar_no_regla IS NULL;

         --  And ID_ALUMNO = '010568329';
         COMMIT;
      END;


      BEGIN

         DELETE materia_faltante_lic
         WHERE regla = p_regla
         and pidm = p_pidm;

         COMMIT;
      END;

      BEGIN

         DELETE saturn.tmp_valida_faltantes
         WHERE 1 = 1
         AND regla = p_regla
         and pidm = p_pidm;

         COMMIT;
      END;

      --
      BEGIN
         FOR c
                IN (SELECT DISTINCT
                                   sgbstdn_pidm,
                                   programa,
                                   rel_programaxalumno_no_regla regla
                    FROM REL_PROGRAMAXALUMNO
                    WHERE     1 = 1
                    AND REL_PROGRAMAXALUMNO_no_regla = p_regla
                    and SGBSTDN_PIDM = p_pidm
                  -- and ID_ALUMNO = '240218844'
                    --AND ID_ALUMNO in ('200216999','010004917')
                   -- and id_alumno in ('010000290','010193800')
                    )
             LOOP

               -- raise_application_error (-20002,'entra a alumno 2.0');

                BEGIN
                   PKG_ALGORITMO_PIDM_DIPCUR.P_VALIDA_FALTA (c.SGBSTDN_PIDM,
                                                    c.PROGRAMA,
                                                    p_regla);
                END;

            dbms_output.put_line('entra a dashboard ');



                COMMIT;

               -- raise_application_error (-20002,'entra a alumno 1.1');

             END LOOP;
      END;




      FOR alumno
         IN (SELECT DISTINCT sgbstdn_pidm pidm,
                             programa programa,
                             campus,
                             nivel,
                             periodo_catalogo
               FROM rel_programaxalumno
               WHERE 1 = 1
               AND rel_programaxalumno_no_regla = P_REGLA
               and SGBSTDN_PIDM = p_pidm
                    )
      LOOP



         BEGIN



            dbms_output.put_line('entra a alumno ');



            SELECT DISTINCT
                           c.sorlcur_term_code_ctlg ctlg, c.sorlcur_key_seqno
            INTO l_periodo_ctl, l_sp
            FROM sorlcur c
            WHERE     1 = 1
            AND c.sorlcur_pidm = alumno.pidm
            AND c.sorlcur_lmod_code = 'LEARNER'
            AND c.sorlcur_roll_ind = 'Y'
            AND c.sorlcur_cact_code = 'ACTIVE'
            AND c.sorlcur_program = alumno.programa
            AND c.sorlcur_seqno =
                                   (SELECT MAX (c1x.sorlcur_seqno)
                                    FROM sorlcur c1x
                                    WHERE     c1x.sorlcur_pidm = c.sorlcur_pidm
                                    AND c1x.sorlcur_lmod_code = c.sorlcur_lmod_code
                                    AND c1x.sorlcur_roll_ind =  c.sorlcur_roll_ind
                                    AND c1x.sorlcur_cact_code = c.sorlcur_cact_code
                                    AND c1x.sorlcur_program = c.sorlcur_program
                                    );

         EXCEPTION WHEN OTHERS THEN
               l_periodo_ctl := '000000';
         END;

         dbms_output.put_line('periodo de catalogo '||alumno.periodo_catalogo);

         FOR d
            IN (WITH secuencia
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
                            AND smrpcmt_program = alumno.programa
--                            and smrpcmt_term_code_eff =alumno.periodo_catalogo
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
                                          alumno.campus,
                                          alumno.nivel,
                                          p_regla,
                                          l_sp,
                                          fal.aprobadas_curr,
                                          fal.curso_curr,
                                          fal.total_curr
                            FROM tmp_valida_faltantes fal
                            JOIN secuencia sec ON fal.programa = sec.Programa
                                               AND fal.materia_padre = sec.id_materia_gpo
                                               AND alumno.periodo_catalogo = SEC.periodo
                            JOIN smrarul rul ON  rul.smrarul_subj_code|| rul.smrarul_crse_numb_low = fal.materia
                                    and smrarul_area=fal.area
                            WHERE 1 = 1
                            AND fal.PIDM = alumno.pidm
                            AND fal.programa = alumno.programa
                            AND regla = p_regla
                            AND materia NOT LIKE 'SESO%'
                            AND materia NOT LIKE 'OPT%'
--                            AND materia NOT IN ('L2DE147', 'L2DE131')
                            ORDER BY 9
                )
         LOOP
                dbms_output.put_line('Entro a materia falta');

                --raise_application_error (-20002,'entra a alumno 1.3');

                begin

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
                                                     l_sp,
                                                     d.aprobadas_curr,
                                                     d.curso_curr,
                                                     d.total_curr);
                exception when others then
--                        raise_application_error (-20002,'entra a alumno 1.2 '||sqlerrm);
                    null;
                end;
         END LOOP;

         COMMIT;
      END LOOP;




      BEGIN

        SELECT COUNT(*)
        INTO l_valida_campus_nivel
        FROM sztalgo lgo,
             zstpara ara
        WHERE 1 = 1
        and lgo.sztalgo_no_regla = p_regla
        AND ara.zstpara_mapa_id='CAMP_PRONO'
        AND ara.zstpara_param_id = sztalgo_camp_code
        and ara.zstpara_param_valor = sztalgo_levl_code
        and sztalgo_levl_code ='LI';

      EXCEPTION WHEN OTHERS THEN
            NULL;
      END;

      dbms_output.put_line('Valor nivel  '||l_valida_campus_nivel);


      IF l_valida_campus_nivel > 0 THEN

        dbms_output.put_line('Entra a lic ');

         FOR t IN (SELECT *
                   FROM materia_faltante_lic
                   WHERE 1 = 1
                   AND regla = p_regla
                   and pidm = p_pidm
--                   and matricula ='010001149'
                   )
                 LOOP
--        dbms_output.put_line('Entra a lic 33');
                    l_contador_tope:=l_contador_tope+1;

                    l_contador_tope2:=t.APROBADAS+t.CURSOS;

                    l_contador_tope3:=l_contador_tope+l_contador_tope2;

                    FOR c IN (
                               --Frank@04.07.22 Se actualiza este query al masivo.
--alumnos nuevos ingresos o futuros sin horarios
                              SELECT DISTINCT
                                              NVL (f.stvterm_acyr_code,TO_CHAR (SYSDATE, 'yyyy'))AS Año,
                                              c.sztalgo_term_code_new AS id_ciclo,
                                              c.sztalgo_ptrm_code_new AS id_periodo,
                                              a.id_alumno AS id_alumno,
                                              d.PIDM,
                                              a.programa AS id_programa,
                                              d.materia AS clave_materia,
                                              lc_0 AS id_grupo,
                                              lc_0  AS id_matricula,
                                               a.campus,
                                              lc_0 AS Id_Tutor,
                                              b.sobptrm_start_date AS dta_inicio_bimestre,
                                              b.sobptrm_end_date AS dta_fin_bimestre,
                                              d.secuencia AS secuencia,
                                              c.sztalgo_term_code_new svrproy_term_code,
                                              a.study_path as study_path,
                                              a.sgbstdn_pidm svrproy_pidm,
                                              d.smrarul_subj_code,
                                              d.smrarul_crse_numb_low,
                                              TRUNC (c.sztalgo_fecha_new) FECHA_INICIO,
                                              d.materia_padre,
                                              rel_programaxalumno_estatus estatus,
                                              d.APROBADAS,
                                              d.CURSOS,
                                              d.TOTAL_CURR
                               FROM rel_programaxalumno a,
                                    sobptrm b,
                                    sztalgo c,
                                    materia_faltante_lic d,
                                    stvterm f,
                                              (
                                               SELECT DISTINCT
                                                              sfrstcr_ptrm_code pperiodo,
                                                              sfrstcr_pidm,
                                                              ssbsect_ptrm_start_date,
                                                              sfrstcr_stsp_key_sequence,
                                                              sfrstcr_term_code periodo,
                                                              sfrstcr_stsp_key_sequence
                                                              study_path
                                                FROM ssbsect a,
                                                     sfrstcr c,
                                                     shrgrde
                                                WHERE 1 = 1
                                                AND ssbsect_term_code = sfrstcr_term_code
                                                and sfrstcr_pidm=t.pidm
                                                AND c.sfrstcr_crn = ssbsect_crn
                                                AND c.sfrstcr_levl_code = shrgrde_levl_code
                                                AND sfrstcr_RSTS_CODE ='RE'
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
                                               ) pperiodo
                                WHERE 1 = 1
                                AND a.campus = c.sztalgo_camp_code
                                AND c.sztalgo_term_code_new = f.stvterm_code
AND NVL(pperiodo.PERIODO,sztalgo_term_code_new)=F.STVTERM_CODE
                                AND c.sztalgo_term_code = pperiodo.periodo(+)
                    AND c.sztalgo_ptrm_code = pperiodo.pperiodo(+) --sustituye lo de abajo
AND ( c.sztalgo_ptrm_code = NVL(pperiodo.pperiodo,c.sztalgo_ptrm_code)  --Se pone para capturar alumnos que ya esten escritos en el mismo periodo y parte periodo actual, son
        OR c.sztalgo_ptrm_code_NEW = NVL(pperiodo.pperiodo,c.sztalgo_ptrm_code_NEW) ) --Alumnos que se necesita asignar materia ya inscritos
                                AND fecha_inicio <= sztalgo_fecha_new
and NVL(pperiodo.PERIODO,a.periodo) = b.sobptrm_term_code
and NVL(pperiodo.PERIODO,a.periodo) = c.sztalgo_term_code_new
and ( NVL(pperiodo.PERIODO,a.periodo) = c.sztalgo_term_code_new
    OR      NVL(pperiodo.PERIODO,a.periodo) = c.sztalgo_term_code)
and c.sztalgo_ptrm_code_new = Case When pkg_algoritmo.f_consulta_activos(0, a.sgbstdn_pidm) > 0 Then --Alumnos RE-CON
                                            (Select Max(x.sztalgo_ptrm_code_new)
                                            from sztalgo x
                                            where x.sztalgo_term_code_new=c.sztalgo_term_code_new
                                            and A.fecha_inicio <= x.sztalgo_fecha_new
                                                and x.sztalgo_camp_code = c.sztalgo_camp_code
                                            and x.sztalgo_no_regla=c.sztalgo_no_regla)
                                   Else         --Alumnos NI-FU
                                            (Select Min(x.sztalgo_ptrm_code_new)
                                            from sztalgo x
                                            where x.sztalgo_term_code_new=c.sztalgo_term_code_new
                                            and A.fecha_inicio <= x.sztalgo_fecha_new
                                                and x.sztalgo_camp_code = c.sztalgo_camp_code
                                            and x.sztalgo_no_regla=c.sztalgo_no_regla)
                              End
                                  AND (b.sobptrm_ptrm_code = c.sztalgo_ptrm_code)
                                AND c.sztalgo_no_regla =a.rel_programaxalumno_no_regla
                                AND c.sztalgo_no_regla = t.regla                --RLS
                                AND d.materia = t.materia
                                AND d.pidm = t.pidm
--and a.id_alumno=:ID
                                AND a.sgbstdn_pidm = d.pidm
-- and d.pidm =480153
                                AND a.rel_programaxalumno_no_regla = d.regla
                                AND a.study_path = d.sp
                                AND a.sgbstdn_pidm = pperiodo.sfrstcr_pidm(+)
                                AND a.study_path = pperiodo.sfrstcr_stsp_key_sequence(+)
                                AND TRUNC (a.FECHA_INICIO) >= TRUNC (pperiodo.ssbsect_ptrm_start_date(+))
                                AND a.study_path = pperiodo.study_path(+)
--                                 AND d.tipo IN ('PC', 'NA')
                                AND d.tipo IN (lc_PC,lc_NA)
                                AND d.materia_padre NOT IN
                                                           (SELECT xx1.materia_padre
                                                            FROM materia_faltante_lic xx1
                                                            WHERE 1 = 1
                                                            AND d.pidm = xx1.pidm
--                                                             AND xx1.tipo in ('AP', 'EC')
                                                            AND xx1.tipo in (lc_AP, lc_EC)
                                                            AND d.regla = xx1.regla
                                                            )
                               ORDER BY 4, 13, 14
                           )
                    LOOP

                       dbms_output.put_line('Entra a consulta  normal campus '||c.campus);

                       BEGIN

                          SELECT DISTINCT sorlcur_admt_code
                          INTO l_equi
                          FROM sorlcur cur
                          WHERE     1 = 1
                          AND cur.sorlcur_program = c.id_programa
                          AND cur.sorlcur_pidm = c.svrproy_pidm
                          AND cur.sorlcur_lmod_code = 'LEARNER'
                          AND cur.sorlcur_roll_ind = 'Y'
                          AND cur.sorlcur_cact_code = 'ACTIVE'
                          AND cur.sorlcur_seqno =
                                                  (SELECT MAX (aa1.sorlcur_seqno)
                                                   FROM sorlcur aa1
                                                   WHERE 1 = 1
                                                   AND cur.sorlcur_pidm = aa1.sorlcur_pidm
                                                   AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
                                                   AND cur.sorlcur_roll_ind =aa1.sorlcur_roll_ind
                                                   AND cur.sorlcur_cact_code =aa1.sorlcur_cact_code
                                                   AND cur.sorlcur_program = aa1.sorlcur_program);
                       EXCEPTION WHEN OTHERS THEN
                             NULL;
                       END;

                       l_contador := l_contador + 1;

                       BEGIN

                          SELECT COUNT(*)
                          INTO l_cuenta_sfr
                          FROM sfrstcr
                          WHERE 1 = 1
                          AND sfrstcr_pidm = c.pidm
                          AND sfrstcr_stsp_key_sequence =c.study_path
                          AND sfrstcr_rsts_code ='RE';

                       EXCEPTION WHEN OTHERS THEN
                          NULL;
                       END;

                       BEGIN

                           SELECT DISTINCT zstpara_param_valor
                           INTO l_ptrm
                           FROM zstpara
                           WHERE 1 = 1
                           AND zstpara_mapa_id ='PTR_NI'
                           AND zstpara_param_desc =c.id_periodo;

                       EXCEPTION WHEN OTHERS THEN
                            l_ptrm:=c.id_periodo;
                       END;

                      dbms_output.put_line('Nuevo xxx '||c.estatus||' '||l_cuenta_sfr);

                       IF c.estatus IN ('N','F') AND  l_cuenta_sfr = 0 OR c.estatus ='R' THEN

                            dbms_output.put_line('Nuevo rrr');

                            BEGIN

                                SELECT DISTINCT zstpara_param_valor
                                INTO l_ptrm
                                FROM zstpara
                                WHERE 1 = 1
                                AND zstpara_mapa_id ='PTR_NI'
                                AND zstpara_param_desc =c.id_periodo;

                            EXCEPTION WHEN OTHERS THEN
                                 NULL;
                            END;

                            begin

                                select distinct SZTALGO_TERM_CODE_NEW
                                into l_term_code
                                from sztalgo
                                where 1 = 1
                                and sztalgo_no_regla = p_regla
                                and SZTALGO_PTRM_CODE = l_ptrm
                                and SZTALGO_CAMP_CODE= c.campus;


                            exception when others then
                                dbms_output.put_line('Error '||sqlerrm||' Regla '||' Ptrm '||l_ptrm ||' c.id_periodo '||c.id_periodo||' campus '|| substr(c.id_programa,1,3));
                            end;



                            dbms_output.put_line('Entra -->'||c.id_periodo);

                            if l_ptrm  = c.id_periodo then

                                l_contador_tope:= c.APROBADAS+ c.CURSOS;

                                l_contador_tope:=l_contador_tope+1;

                                dbms_output.put_line('Contador tope '||l_contador_tope);

                                  BEGIN

                                    INSERT INTO rel_alumnos_x_asignar
                                                             VALUES (c.año,
                                                                     l_term_code,
                                                                     l_ptrm,
                                                                     c.id_alumno,
                                                                     c.id_programa,
                                                                     c.clave_materia,
                                                                     c.id_grupo,
                                                                     c.id_matricula,
                                                                     c.campus,
                                                                     c.id_tutor,
                                                                     c.dta_inicio_bimestre,
                                                                     c.dta_fin_bimestre,
                                                                     c.secuencia,
                                                                     l_term_code,
                                                                     c.study_path,
                                                                     c.svrproy_pidm,
                                                                     c.materia_padre,
                                                                     c.smrarul_subj_code,
                                                                     c.smrarul_crse_numb_low,
                                                                     c.fecha_inicio,
                                                                     0,
                                                                     p_regla,
                                                                     user,
                                                                     null,
                                                                     l_equi,
                                                                     NULL);
                                  EXCEPTION WHEN OTHERS  THEN
                                        NULL;
                                  END;

                            else

                                BEGIN

                                    INSERT INTO rel_alumnos_x_asignar
                                                             VALUES (c.año,
                                                                     l_term_code,
                                                                     l_ptrm,
                                                                     c.id_alumno,
                                                                     c.id_programa,
                                                                     c.clave_materia,
                                                                     c.id_grupo,
                                                                     c.id_matricula,
                                                                     c.campus,
                                                                     c.id_tutor,
                                                                     c.dta_inicio_bimestre,
                                                                     c.dta_fin_bimestre,
                                                                     c.secuencia,
                                                                     l_term_code,
                                                                     c.study_path,
                                                                     c.svrproy_pidm,
                                                                     c.materia_padre,
                                                                     c.smrarul_subj_code,
                                                                     c.smrarul_crse_numb_low,
                                                                     c.fecha_inicio,
                                                                     0,
                                                                     p_regla,
                                                                     user,
                                                                     null,
                                                                     l_equi,
                                                                     NULL);
                                  EXCEPTION WHEN OTHERS  THEN
                                        NULL;
                                  END;

                            end if;

                            commit;

                            l_contador_tope:=0;

                       ELSE

                          dbms_output.put_line('Nuevo valida');

                          begin

                              SELECT DISTINCT sztalgo_term_code_new
                              into l_term_code
                              from sztalgo
                              where 1 = 1
                              and sztalgo_no_regla = p_regla
                              and SZTALGO_PTRM_CODE = c.id_periodo
                              and SZTALGO_CAMP_CODE= substr(c.id_programa,1,3)
                              AND SZTALGO_PTRM_CODE <>l_ptrm;


                          exception when others then
                              --dbms_output.put_line('aqui esta el pex '||' periodo '||c.id_periodo||' '||c.id_ciclo||' ptrm new '||l_ptrm);
                              null;
                          end;


                          dbms_output.put_line('aqui esta el pex '||' periodo '||c.id_periodo||' '||c.id_ciclo||' ptrm new '||l_ptrm);


                          begin

                            select distinct sztalgo_anticipado
                            into l_antcipado
                            from sztalgo
                            where 1 = 1
                            and sztalgo_no_regla = p_regla;

                          exception when others then
                            null;
                          end;


                          if l_antcipado ='S' then

                                BEGIN

                                      INSERT INTO rel_alumnos_x_asignar
                                                               VALUES (c.año,
                                                                       c.id_ciclo,
                                                                       c.id_periodo,
                                                                       c.id_alumno,
                                                                       c.id_programa,
                                                                       c.clave_materia,
                                                                       c.id_grupo,
                                                                       c.id_matricula,
                                                                       c.campus,
                                                                       c.id_tutor,
                                                                       c.dta_inicio_bimestre,
                                                                       c.dta_fin_bimestre,
                                                                       c.secuencia,
                                                                       c.id_ciclo,
                                                                       c.study_path,
                                                                       c.svrproy_pidm,
                                                                       c.materia_padre,
                                                                       c.smrarul_subj_code,
                                                                       c.smrarul_crse_numb_low,
                                                                       c.fecha_inicio,
                                                                       0,
                                                                       p_regla,
                                                                       user,
                                                                       null,
                                                                       l_equi,
                                                                       NULL);
                                    EXCEPTION WHEN OTHERS  THEN
                                          NULL;
                                    END;

                                commit;
                          else


                              IF c.id_periodo != l_ptrm then



                                    BEGIN

                                      INSERT INTO rel_alumnos_x_asignar
                                                               VALUES (c.año,
                                                                       c.id_ciclo,
                                                                       c.id_periodo,
                                                                       c.id_alumno,
                                                                       c.id_programa,
                                                                       c.clave_materia,
                                                                       c.id_grupo,
                                                                       c.id_matricula,
                                                                       c.campus,
                                                                       c.id_tutor,
                                                                       c.dta_inicio_bimestre,
                                                                       c.dta_fin_bimestre,
                                                                       c.secuencia,
                                                                       c.id_ciclo,
                                                                       c.study_path,
                                                                       c.svrproy_pidm,
                                                                       c.materia_padre,
                                                                       c.smrarul_subj_code,
                                                                       c.smrarul_crse_numb_low,
                                                                       c.fecha_inicio,
                                                                       0,
                                                                       p_regla,
                                                                       user,
                                                                       null,
                                                                       l_equi,
                                                                       NULL);
                                    EXCEPTION WHEN OTHERS  THEN
                                          NULL;
                                    END;

                                commit;

                              ELSE
                                    BEGIN

                                      INSERT INTO rel_alumnos_x_asignar
                                                               VALUES (c.año,
                                                                       c.id_ciclo,
                                                                       c.id_periodo,
                                                                       c.id_alumno,
                                                                       c.id_programa,
                                                                       c.clave_materia,
                                                                       c.id_grupo,
                                                                       c.id_matricula,
                                                                       c.campus,
                                                                       c.id_tutor,
                                                                       c.dta_inicio_bimestre,
                                                                       c.dta_fin_bimestre,
                                                                       c.secuencia,
                                                                       c.id_ciclo,
                                                                       c.study_path,
                                                                       c.svrproy_pidm,
                                                                       c.materia_padre,
                                                                       c.smrarul_subj_code,
                                                                       c.smrarul_crse_numb_low,
                                                                       c.fecha_inicio,
                                                                       0,
                                                                       p_regla,
                                                                       user,
                                                                       null,
                                                                       l_equi,
                                                                       NULL);
                                    EXCEPTION WHEN OTHERS  THEN
                                          NULL;
                                    END;

                                commit;


                              END IF;

                          end if;

                       END IF;

                    END LOOP;

                    dbms_output.put_line('vueltas  '||l_contador_tope||' tope2 '||l_contador_tope2);

                    --exit when l_contador_tope3 =t.TOTAL_CURR;


                 END LOOP;

                 l_contador_tope:= 0;
                 l_contador_tope2:=0;
                 l_contador_tope3:=0;


      ELSE
         l_contador := 0;

         dbms_output.put_line('Entra a mestria ');

         FOR c
            IN (
                SELECT DISTINCT
                                NVL (f.stvterm_acyr_code, TO_CHAR (SYSDATE, 'yyyy')) AS año,
                                c.sztalgo_term_code_new as id_ciclo,
                                null id_periodo,
                                a.id_alumno as id_alumno,
                                a.programa as id_programa,
                                d.materia as clave_materia,
                                '0' as id_grupo,
                                '0' as id_matricula,
                                a.campus AS Campus,
                                '0' as id_tutor,
                                b.sobptrm_start_date as dta_inicio_bimestre,
                                null dta_fin_bimestre,
                                d.secuencia AS Secuencia,
                                c.sztalgo_term_code_new svrproy_term_code,
                                a.study_path as study_path,
                                a.sgbstdn_pidm svrproy_pidm,
                                d.smrarul_subj_code,
                                d.smrarul_crse_numb_low,
                                TRUNC (c.sztalgo_fecha_new) FECHA_INICIO,
                                d.materia_padre,
                                rel_programaxalumno_estatus estatus,
                                d.nivel,
                                a.periodo_catalogo,
                                d.APROBADAS,
                                d.CURSOS,
                                d.TOTAL_CURR
                  FROM rel_programaxalumno a,
                       sobptrm b,
                       sztalgo c,
                       materia_faltante_lic d,
                       stvterm f,
                      (
                       SELECT DISTINCT
                                      sfrstcr_ptrm_code pperiodo,
                                      sfrstcr_pidm,
                                      ssbsect_ptrm_start_date,
                                      sfrstcr_stsp_key_sequence,
                                      sfrstcr_term_code periodo,
                                      sfrstcr_stsp_key_sequence
                                      study_path
                        FROM ssbsect a,
                             sfrstcr c,
                             shrgrde
                        WHERE 1 = 1
                        AND ssbsect_term_code = sfrstcr_term_code
                        and sfrstcr_pidm = p_pidm
                        AND c.sfrstcr_crn = ssbsect_crn
                        AND c.sfrstcr_levl_code = shrgrde_levl_code
                        AND sfrstcr_RSTS_CODE ='RE'
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
                       ) pperiodo
                  WHERE 1 = 1
                  AND a.campus = c.sztalgo_camp_code
--                  AND c.sztalgo_term_code_new = f.stvterm_code
AND NVL(pperiodo.PERIODO,sztalgo_term_code_new)=F.STVTERM_CODE
                    AND c.sztalgo_term_code = pperiodo.periodo(+)
--                    AND c.sztalgo_ptrm_code = pperiodo.pperiodo(+) --sustituye lo de abajo
AND ( c.sztalgo_ptrm_code = NVL(pperiodo.pperiodo,c.sztalgo_ptrm_code)  --Se pone para capturar alumnos que ya esten escritos en el mismo periodo y parte periodo actual, son
        OR c.sztalgo_ptrm_code_NEW = NVL(pperiodo.pperiodo,c.sztalgo_ptrm_code_NEW) ) --Alumnos que se necesita asignar materia ya inscritos
                    AND fecha_inicio <= sztalgo_fecha_new
--                  AND c.sztalgo_term_code_new = b.sobptrm_term_code
and NVL(pperiodo.PERIODO,a.periodo) = b.sobptrm_term_code
--and NVL(pperiodo.PERIODO,a.periodo) = c.sztalgo_term_code_new
and ( NVL(pperiodo.PERIODO,a.periodo) = c.sztalgo_term_code_new
    OR      NVL(pperiodo.PERIODO,a.periodo) = c.sztalgo_term_code)
and c.sztalgo_ptrm_code_new = Case When pkg_algoritmo.f_consulta_activos(0, a.sgbstdn_pidm) > 0 Then --Alumnos RE-CON
                                            (Select Max(x.sztalgo_ptrm_code_new)
                                            from sztalgo x
                                            where x.sztalgo_term_code_new=c.sztalgo_term_code_new
                                            and A.fecha_inicio <= x.sztalgo_fecha_new
                                                and x.sztalgo_camp_code = c.sztalgo_camp_code
                                            and x.sztalgo_no_regla=c.sztalgo_no_regla)
                                   Else         --Alumnos NI-FU
                                            (Select Min(x.sztalgo_ptrm_code_new)
                                            from sztalgo x
                                            where x.sztalgo_term_code_new=c.sztalgo_term_code_new
                                            and A.fecha_inicio <= x.sztalgo_fecha_new
                                                and x.sztalgo_camp_code = c.sztalgo_camp_code
                                            and x.sztalgo_no_regla=c.sztalgo_no_regla)
                              End
                                  AND b.sobptrm_ptrm_code = c.sztalgo_ptrm_code
                  AND c.sztalgo_no_regla = a.rel_programaxalumno_no_regla
                  AND c.sztalgo_no_regla = p_regla                  --RLS
                  AND a.sgbstdn_pidm = d.pidm
                  AND a.rel_programaxalumno_no_regla = d.regla
                  AND a.study_path = d.sp
                  AND a.sgbstdn_pidm = pperiodo.SFRSTCR_PIDM(+)
                  AND a.study_path = pperiodo.sfrstcr_stsp_key_sequence(+)
                  AND TRUNC (a.fecha_inicio) >= TRUNC (pperiodo.ssbsect_ptrm_start_date(+))
                  AND a.study_path = pperiodo.study_path(+)
                  AND d.tipo IN ('PC', 'NA')
                  and a.sgbstdn_pidm = p_pidm
                  AND d.materia_padre NOT IN
                                          (SELECT xx1.materia_padre
                                           FROM materia_faltante_lic xx1
                                           WHERE  1 = 1
                                           AND d.pidm = xx1.pidm
                                           AND xx1.tipo IN ('AP', 'EC')
                                           AND d.REGLA = xx1.REGLA)
                ORDER BY 4, 13, 14)
         LOOP

            BEGIN

               SELECT DISTINCT sztdtec_periodicidad
               INTO l_periodicidad
               FROM sztdtec
               WHERE 1 = 1
               AND sztdtec_program = c.id_programa
               AND sztdtec_term_code = c.periodo_catalogo;

            EXCEPTION WHEN OTHERS THEN
                NULL;
            END;

            BEGIN

               SELECT DISTINCT SZTDTEC_MOD_TYPE
               INTO l_semis
               FROM sztdtec
               WHERE  1 = 1
               AND sztdtec_program = c.id_programa
               AND sztdtec_term_code = c.periodo_catalogo;

            EXCEPTION WHEN OTHERS THEN
                  NULL;
            END;

          If substr(c.id_programa,4,2)in ('DI','CU') THEN

               BEGIN

                   SELECT DISTINCT a.SORLCUR_VPDI_CODE
                   INTO l_ptrm
                   FROM SORLCUR a
                   WHERE 1 = 1
                   AND a.SORLCUR_PROGRAM =C.id_programa
                   AND a.SORLCUR_PIDM= C.svrproy_pidm
                   AND A.sorlcur_seqno = (SELECT MAX (aa1.sorlcur_seqno)
                                                   FROM sorlcur aa1
                                                   WHERE 1 = 1
                                                   AND aa1.sorlcur_pidm=A.sorlcur_pidm
                                                   AND AA1.SORLCUR_LMOD_CODE='LEARNER'
                                                   AND aa1.sorlcur_program=a.sorlcur_program
                                                   );

               EXCEPTION WHEN OTHERS THEN
                      dbms_output.put_line(sqlerrm);
                   null;
               END;

          ELSE

             BEGIN

                SELECT sztcopp_ptm
                INTO l_ptrm
                FROM sztcopp
                WHERE 1 = 1
                AND sztcopp_campus = c.campus
                AND sztcopp_nivel = c.nivel
                AND sztcopp_so = l_semis
                AND sztcopp_periodicad = l_periodicidad
                and sztcopp_no_regla = p_regla;

             EXCEPTION WHEN OTHERS THEN
                   dbms_output.put_line('error 1--> '||sqlerrm);
             END;

          end if;

            BEGIN

               SELECT DISTINCT sorlcur_admt_code
               INTO l_equi
               FROM sorlcur cur
               WHERE 1 = 1
               AND cur.sorlcur_program = c.id_programa
               AND cur.sorlcur_pidm = c.svrproy_pidm
               AND cur.sorlcur_lmod_code = 'LEARNER'
               AND cur.sorlcur_roll_ind = 'Y'
               AND cur.sorlcur_cact_code = 'ACTIVE'
               AND cur.sorlcur_seqno =
                                      (SELECT MAX (aa1.sorlcur_seqno)
                                       FROM SORLCUR aa1
                                       WHERE 1 = 1
                                       AND cur.sorlcur_pidm = aa1.sorlcur_pidm
                                       AND cur.sorlcur_lmod_code = aa1.sorlcur_lmod_code
                                       AND cur.sorlcur_roll_ind =  aa1.sorlcur_roll_ind
                                       AND cur.sorlcur_cact_code = aa1.sorlcur_cact_code
                                       AND cur.sorlcur_program = aa1.sorlcur_program);

            EXCEPTION WHEN OTHERS THEN
                  l_equi := 'RE';
            END;

----Frank@Add@Jul22 se agrega conteo cursos propedeuticos
--            BEGIN
--               SELECT COUNT(Distinct SZTPTRM_MATERIA)
--               INTO l_cuenta_prop
--               FROM sztptrm
--               WHERE 1 = 1
--               AND sztptrm_propedeutico = 1
--               AND sztptrm_term_code =c.id_ciclo
----               AND sztptrm_ptrm_code =l_ptrm
--               AND sztptrm_program =c.id_programa;
--            EXCEPTION WHEN OTHERS THEN
--                  NULL;
--            END;
----
             dbms_output.put_line('CAMPUS '|| c.campus||' nivel '||c.nivel||' semis '||l_semis||
                ' periodicidad '||l_periodicidad||' Periodo Catalgo '||c.periodo_catalogo||' Ptrm '||l_ptrm||
                ' lcuenta_propeu: '||l_cuenta_prop||' id_ciclo  '||c.id_ciclo||
                ' id_programa '||c.id_programa );


            l_contador := l_contador + 1;

--            if c.aprobadas+c.cursos < c.total_curr + l_cuenta_prop then  --Frank@Add@Jul22 se agrega conteo cursos propedeuticos
            if c.aprobadas+c.cursos < c.total_curr  then  --Frank@Add@Jul22 se agrega conteo cursos propedeuticos

                BEGIN
                   INSERT INTO rel_alumnos_x_asignar
                                        VALUES (c.año,
                                                c.id_ciclo,
                                                l_ptrm,
                                                c.id_alumno,
                                                c.id_programa,
                                                c.clave_materia,
                                                c.id_grupo,
                                                c.id_matricula,
                                                c.campus,
                                                c.id_tutor,
                                                c.dta_inicio_bimestre,
                                                c.dta_fin_bimestre,
                                                c.secuencia,
                                                c.svrproy_term_code,
                                                c.study_path,
                                                c.svrproy_pidm,
                                                c.materia_padre,
                                                c.smrarul_subj_code,
                                                c.smrarul_crse_numb_low,
                                                c.fecha_inicio,
                                                0,
                                                p_regla,
                                                user,
                                                null,
                                                l_equi,
                                                c.periodo_catalogo);

                          dbms_output.put_line('Inserto 1 ');

                EXCEPTION WHEN OTHERS THEN
                     dbms_output.put_line('Error al insertar dashboard '||sqlerrm);
                END;


            end if;

            commit;


         END LOOP;

      END IF;

--      begin p_prereq(p_regla,p_pidm); end;
--      COMMIT;

    for c in (SELECT ID_CICLO,
                       ID_PERIODO,
                        b.campus,
                        b.nivel nivel,
                        a.rel_alumnos_x_asignar_no_regla regla,
                        a.secuencia,
                        a.SVRPROY_PIDM pidm,
                        a.STUDY_PATH pt,
                        a.clave_materia_agp,
                        a.tipo_equi t_ingreso
                  FROM rel_alumnos_x_asignar a
                  JOIN REL_PROGRAMAXALUMNO b on b.SGBSTDN_PIDM = a.SVRPROY_PIDM
                                            AND b.REL_PROGRAMAXALUMNO_NO_REGLA = a.REL_ALUMNOS_X_ASIGNAR_NO_REGLA
                  WHERE 1 = 1
                  AND rel_alumnos_x_asignar_no_regla = p_regla
                  and SVRPROY_PIDM = p_pidm
                  order by secuencia asc

                )loop

                    dbms_output.put_line('entra a uts 1 campus '||c.campus);

                    IF c.campus ='UIN' then

                            vl_borraUIN := BANINST1.F_CALCULA_QA (c.ID_CICLO,c.pt,c.pidm,c.t_ingreso,c.regla,c.ID_PERIODO,c.nivel);

                       IF vl_borraUIN < 5 then

                          BEGIN
                                DELETE rel_alumnos_x_asignar
                                WHERE 1 = 1
                                AND rel_alumnos_x_asignar_no_regla = c.regla
                                AND SVRPROY_PIDM = p_pidm
                                AND CLAVE_MATERIA_AGP IN (SELECT DISTINCT SZTPINC_MATERIA
                                                              FROM sztpinc
                                                              WHERE 1 = 1
                                                              AND sztpinc_campus ='UIN'
                                                              AND sztpinc_nivel ='MA'
                                                              AND SZTPINC_QA='Q5');
                             EXCEPTION WHEN OTHERS THEN
                             NULL;
                            END;

                       ELSE
                        EXIT  ;

                       END IF;

                       BEGIN

                           DELETE rel_alumnos_x_asignar
                           WHERE 1 = 1
                           AND rel_alumnos_x_asignar_no_regla = c.REGLA
                           AND SVRPROY_PIDM = c.pidm
                           AND CLAVE_MATERIA_AGP NOT in (SELECT DISTINCT SZTPINC_MATERIA
                                                         FROM sztpinc
                                                         WHERE 1 = 1
                                                         AND sztpinc_campus ='UIN'
                                                         AND sztpinc_nivel ='MA'
                                                         AND SZTPINC_ACTIVO ='S');
                       exception when others then
                           null;
                       end;



                    elsIF c.campus ='INC' then

                      dbms_output.put_line('entra a inc ');

                       BEGIN

                              SELECT COUNT(*)
                              INTO l_cuenta_sfr
                              FROM sfrstcr
                              WHERE 1 = 1
                              AND sfrstcr_pidm = c.pidm
                              AND sfrstcr_stsp_key_sequence =c.PT
                              AND sfrstcr_rsts_code ='RE';

                       EXCEPTION WHEN OTHERS THEN
                          NULL;
                       END;

                       BEGIN

                           SELECT distinct REL_PROGRAMAXALUMNO_ESTATUS
                           INTO l_type_code
                           FROM REL_PROGRAMAXALUMNO
                           WHERE 1 = 1
                           AND REL_PROGRAMAXALUMNO_NO_REGLA =c.REGLA
                           AND SGBSTDN_PIDM = c.pidm;


                       exception when others then
                            null;
                       end;


                       IF l_type_code IN ('N','F') AND  l_cuenta_sfr = 0 OR l_type_code ='R' THEN

--                     para pronostico de INC

                          dbms_output.put_line('entra a inc v1 ');

                            BEGIN

                                DELETE
                                FROM rel_alumnos_x_asignar rxa
                                WHERE 1 = 1
                                AND ID_CICLO ='252241'
                                AND rel_alumnos_x_asignar_no_regla = c.REGLA
                                AND SVRPROY_PIDM = c.pidm;

                            exception when others then
                                null;
                            end;

                            update rel_alumnos_x_asignar set ID_PERIODO ='M0A'
                            WHERE 1 = 1
                            AND rel_alumnos_x_asignar_no_regla = p_regla
                            AND SVRPROY_PIDM = c.pidm;



                       ELSE

                            dbms_output.put_line('entra a inc v2 ');
--
--                            BEGIN
--
--                                DELETE
--                                FROM rel_alumnos_x_asignar rxa
--                                WHERE 1 = 1
--                                AND ID_CICLO ='252242'
--                                AND rel_alumnos_x_asignar_no_regla = c.rel_alumnos_x_asignar_no_regla
--                                AND SVRPROY_PIDM = c.pidm;
--
--                            exception when others then
--                                null;
--                            end;

                            update rel_alumnos_x_asignar set ID_PERIODO ='M2A'
                            WHERE 1 = 1
                            AND rel_alumnos_x_asignar_no_regla = p_regla
                            AND SVRPROY_PIDM = c.pidm;


--
                       END IF;

                        BEGIN

                            SELECT COUNT(*)
                            INTO l_contar_inc
                            FROM rel_alumnos_x_asignar rxa
                            WHERE 1 = 1
                            AND rel_alumnos_x_asignar_no_regla = c.REGLA
                            AND CLAVE_MATERIA_AGP = c.CLAVE_MATERIA_AGP
                            AND SVRPROY_PIDM = c.pidm
                            AND campus = c.campus
                            AND substr(rxa.ID_PROGRAMA,4,2)=c.nivel
                            AND CLAVE_MATERIA_AGP in (SELECT SZTPINC_MATERIA
                                                      FROM  sztpinc
                                                      WHERE 1 = 1
                                                      AND sztpinc_activo ='S'
--                                                      AND SZTPINC_SECUENCIA = c.SECUENCIA
                                                     -- AND SZTPINC_QA = to_char('Q'||get_qa(rxa.ID_PROGRAMA,rxa.SVRPROY_PIDM))
                                                      );

                        exception when others then
                            null;
                        end;


                        dbms_output.put_line('entra a inc v3 contar  '||l_contar_inc);


--                        IF l_contar_inc =0 then
--
--                            BEGIN
--
--                                DELETE
--                                FROM rel_alumnos_x_asignar rxa
--                                WHERE 1 = 1
--                                AND rel_alumnos_x_asignar_no_regla = c.rel_alumnos_x_asignar_no_regla
--                                AND SVRPROY_PIDM = c.pidm
--                                AND CLAVE_MATERIA_AGP = c.CLAVE_MATERIA_AGP;
--
--                            exception when others then
--                                null;
--                            end;
--
--                        end IF;

                    elsIF c.campus IN ('UTS','EAF')  then

                           dbms_output.put_line('entra a uts 2 ');

                           IF c.nivel in ('EC','ID') then

                                dbms_output.put_line('entra a uts 3 ');

                                 FOR D IN (SELECT distinct SOBPTRM_PTRM_CODE ptrm,
                                                            SOBPTRM_START_DATE fecha_inicio,
                                                            ZSTPARA_PARAM_DESC secuencia
                                            FROM SOBPTRM a
                                           JOIN ZSTPARA b on b.ZSTPARA_mapa_ID ='PRONO_EC'
                                                          AND B.ZSTPARA_PARAM_ID= (SELECT x.SZTALGO_PTRM_CODE_NEW
                                                                     FROM sztalgo x
                                                                     WHERE 1 = 1
                                                                     AND x.sztalgo_no_regla =c.regla
--                                                                     AND SUBSTR (x.SZTALGO_PTRM_CODE_NEW,2,1) in ('D','3') --Jpg@Modify240123
                                                                     )
                                            WHERE 1 = 1
                                            AND a.SOBPTRM_PTRM_CODE=ZSTPARA_PARAM_VALOR
                                            AND SOBPTRM_TERM_CODE =C.ID_CICLO
                                            order by 3 asc
                                            )loop

                                                IF c.secuencia = D.secuencia then

                                                dbms_output.put_line('secuencia a '||c.secuencia||' secuencia b '||d.secuencia||' ptrm '||d.ptrm);


                                                    UPDATE rel_alumnos_x_asignar set ID_PERIODO = d.ptrm,
                                                                                     FECHA_INICIO = d.fecha_inicio
                                                    WHERE 1 = 1
                                                    AND SVRPROY_PIDM = c.pidm
                                                    AND rel_alumnos_x_asignar_no_regla = C.regla
--                                                    AND secuencia<>1
                                                    AND secuencia=d.secuencia;
--                                                    AND SUBSTR(ID_PERIODO,1,1)= SUBSTR(d.ptrm,3,1);
                                                 --
                                                end IF;

                                            END LOOP;

                                            commit;


                           end IF;

                    end IF;


                END LOOP;


   END;

   --
   --
   PROCEDURE P_MATERIAS_PIDM_NI (P_REGLA NUMBER,
                                 p_pidm  NUMBER)
   IS


    vl_numero number:=0;
    vl_contador number:=0;
    vl_avance number :=0;
    vl_fecha_ing date;
    vl_tipo_ini number;
    vl_tipo_jornada varchar2(1):= null;
    vl_qa_avance number :=0;
    vl_parte_bim number :=0;
    vl_tip_ini varchar2(10):= null;
    vl_asignacion number:=0;
    val_max number:=0;
    vl_Error Varchar2(2000) := 'EXITO';
    l_ptrm_algo varchar2(10);
    l_itera number:=0;
    l_cuenta_registro number;
    l_cuenta_sfr number;
    l_cuenta_semi number;
    l_bim NUMBER;
    l_sp number;
    l_cuenta_grade number;
    l_cuenta_asma number;
    l_cuenta_prop number;
    -- P_REGLA NUMBER :=4;
    l_semis varchar2(2);
    l_cuenta_para_campus number:=0;
    l_existe_alumno NUMBER:=0;
    l_valida_asma number;
    l_curso_p varchar2(100);
    l_cuenta_nin number;
    VL_campus NUMBER;
    VL_NIVEL varchar2(2);

BEGIN

    l_cuenta_para_campus:=0;

    DBMS_OUTPUT.PUT_LINE('Entra  al 1 sss ');


    l_itera:=0;

        FOR alumno IN (
                      SELECT DISTINCT id_alumno,
                                       id_ciclo,
                                       id_programa,
                                       svrproy_pidm,
                                       id_periodo,
                                        (SELECT DISTINCT sztdtec_periodicidad
                                         from SZTDTEC
                                         where 1 = 1
                                         and SZTDTEC_PROGRAM = ID_PROGRAMA
                                         and SZTDTEC_TERM_CODE = periodo_catalogo
                                         ) periodicidad,
                                         null rate,
                                         null jornada,
                                         SUBSTR(id_programa,1,3)campus,
                                         SUBSTR(id_programa,4,2) nivel,
                                         null jornada_com,
                                         rel_alumnos_x_asignar_no_regla sztprvn_no_regla,
                                         tipo_equi equi,
                                         periodo_catalogo,
                                         STUDY_PATH sp
                      FROM rel_alumnos_x_asignar
                      WHERE 1 = 1
                      AND rel_alumnos_x_asignar_no_regla = p_regla
                      AND SVRPROY_PIDM = p_pidm


      ) Loop


            DBMS_OUTPUT.PUT_LINE('Entra  al 6 ');

            vl_fecha_ing := NULL;
            vl_tipo_ini  := NULL;

            BEGIN

                 SELECT DISTINCT MIN(TO_DATE(ssbsect_ptrm_start_date)) fecha_inicio,
                                 MIN(SUBSTR(ssbsect_ptrm_code,2,1)) pperiodo
                 INTO vl_fecha_ing,
                      vl_tipo_ini
                 FROM sfrstcr a,
                      ssbsect b,
                      sorlcur c
                 WHERE 1 = 1
                 AND a.sfrstcr_term_code = b.ssbsect_term_code
                 AND a.sfrstcr_crn = b.ssbsect_crn
                 AND a.sfrstcr_rsts_code = 'RE'
                 AND b.ssbsect_ptrm_start_date =(SELECT MIN (b1.ssbsect_ptrm_start_date)
                                                 FROM ssbsect b1
                                                 WHERE 1 = 1
                                                 AND b.ssbsect_term_code = b1.ssbsect_term_code
                                                 and b.ssbsect_crn = b1.ssbsect_crn
                                                 )
                 AND sfrstcr_pidm =alumno.svrproy_pidm
                 AND sfrstcr_pidm = c.sorlcur_pidm
                 AND c.sorlcur_program = alumno.id_programa
                 AND c.sorlcur_lmod_code = 'LEARNER'
                 AND c.sorlcur_roll_ind = 'Y'
                 AND c.sorlcur_cact_code ='ACTIVE'
                 AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
                                        FROM sorlcur c1
                                        WHERE c.sorlcur_pidm = c1.sorlcur_pidm
                                        AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code
                                        AND c.sorlcur_roll_ind = c1.sorlcur_roll_ind
                                        AND c.sorlcur_cact_code = c1.sorlcur_cact_code
                                        AND c.sorlcur_program = c1.sorlcur_program
                                        )
                 AND sfrstcr_stsp_key_sequence =    c.sorlcur_key_seqno;


            EXCEPTION WHEN OTHERS THEN
                vl_fecha_ing:= NULL;
                vl_tipo_ini := NULL;
            END;


            BEGIN

                SELECT MIN (x.fecha_inicio) fecha,
                      SUBSTR (x.pperiodo, 2,1) inicio
                INTO vl_fecha_ing,
                     vl_tipo_ini
                FROM (
                        SELECT DISTINCT MIN (SSBSECT_PTRM_START_DATE) fecha_inicio,
                                       SFRSTCR_pidm pidm,
                                       b.SSBSECT_TERM_CODE Periodo,
                                       SSBSECT_PTRM_CODE pperiodo
                        FROM SFRSTCR a,
                             SSBSECT b,
                             sorlcur c
                        WHERE 1 = 1
                        and a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                        AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                        AND a.SFRSTCR_RSTS_CODE = 'RE'
                        AND b.SSBSECT_PTRM_START_DATE =
                                                         (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                                          FROM SSBSECT b1
                                                          WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                          AND b.SSBSECT_CRN = b1.SSBSECT_CRN
                                                          )
                        and  SFRSTCR_pidm =alumno.SVRPROY_PIDM
                        and SFRSTCR_pidm = c.sorlcur_pidm
                        and c.sorlcur_program = alumno.ID_PROGRAMA
                        and c.SORLCUR_LMOD_CODE = 'LEARNER'
                        And c.SORLCUR_ROLL_IND = 'Y'
                        and c.SORLCUR_CACT_CODE ='ACTIVE'
                        and SSBSECT_PTRM_CODE not in 'SS1'
                        and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
                                                                 from sorlcur c1
                                                                 where c.sorlcur_pidm = c1.sorlcur_pidm
                                                                 and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                                 and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                                 and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                                 and c.sorlcur_program = c1.sorlcur_program)
                        and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
                        GROUP BY SFRSTCR_pidm,
                                 b.SSBSECT_TERM_CODE ,
                                 SSBSECT_PTRM_CODE
                            order by 1,3 asc
                    )  x
                    where 1 = 1
                    and rownum = 1
                    group by x.Periodo, x.pperiodo
                    order by 2 asc;

                                if vl_tipo_ini = 0 then

                                    vl_tipo_ini:=2;

                                end if;

                                 DBMS_OUTPUT.PUT_LINE('Recupera aqui en este lugar -->'||vl_tipo_ini);

            Exception
                When Others then
                   Begin

                     select   min (x.fecha_inicio) fecha,
                              substr (x.pperiodo, 2,1) inicio
                        Into vl_fecha_ing,
                              vl_tipo_ini
                        from (
                                SELECT DISTINCT MIN (SSBSECT_PTRM_START_DATE) fecha_inicio,
                                                SFRSTCR_pidm pidm,
                                                b.SSBSECT_TERM_CODE Periodo,
                                                SSBSECT_PTRM_CODE pperiodo
                                FROM SFRSTCR a,
                                     SSBSECT b,
                                     sorlcur c
                                WHERE 1 = 1
                                AND a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                                AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                                AND a.SFRSTCR_RSTS_CODE = 'RE'
                                AND b.SSBSECT_PTRM_START_DATE =
                                                                 (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                                                  FROM SSBSECT b1
                                                                  WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                                  AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                                and  SFRSTCR_pidm =alumno.SVRPROY_PIDM
                                and SFRSTCR_pidm = c.sorlcur_pidm
                                and c.sorlcur_program = alumno.ID_PROGRAMA
                                and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                And c.SORLCUR_ROLL_IND = 'Y'
                                and c.SORLCUR_CACT_CODE ='ACTIVE'
                                and SSBSECT_PTRM_CODE not in 'SS1'
                                and c.SORLCUR_SEQNO = (
                                                       select max (c1.SORLCUR_SEQNO)
                                                       from sorlcur c1
                                                       where c.sorlcur_pidm = c1.sorlcur_pidm
                                                       and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                       and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                       and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                       and c.sorlcur_program = c1.sorlcur_program
                                                       )
                                and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
                                    GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE , SSBSECT_PTRM_CODE
                                    order by 1,3 asc
                            )  x
                            where rownum = 1
                            group by x.Periodo, x.pperiodo
                            order by 2 asc;

                        EXCEPTION WHEN OTHERS THEN

                            begin
                                    select   min (x.fecha_inicio) fecha,
                                             substr (x.pperiodo, 2,1) inicio
                                    Into vl_fecha_ing,
                                         vl_tipo_ini
                                    from (
                                        SELECT DISTINCT MIN (SSBSECT_PTRM_START_DATE) fecha_inicio,
                                                        SFRSTCR_pidm pidm,
                                                        b.SSBSECT_TERM_CODE Periodo,
                                                        SSBSECT_PTRM_CODE pperiodo
                                        FROM SFRSTCR a,
                                             SSBSECT b,
                                             sorlcur c
                                        WHERE 1 = 1
                                        AND a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                                        AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                                        AND a.SFRSTCR_RSTS_CODE != 'RE'
                                        AND b.SSBSECT_PTRM_START_DATE =
                                                                         (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                                                          FROM SSBSECT b1
                                                                          WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                                          AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                                        and  SFRSTCR_pidm =alumno.SVRPROY_PIDM
                                        and SFRSTCR_pidm = c.sorlcur_pidm
                                        and c.sorlcur_program = alumno.ID_PROGRAMA
                                        and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                        And c.SORLCUR_ROLL_IND = 'Y'
                                        and c.SORLCUR_CACT_CODE ='ACTIVE'
                                        and SSBSECT_PTRM_CODE not in 'SS1'
                                        and c.SORLCUR_SEQNO = (
                                                               select max (c1.SORLCUR_SEQNO)
                                                               from sorlcur c1
                                                               where c.sorlcur_pidm = c1.sorlcur_pidm
                                                               and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                               and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                               and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                               and c.sorlcur_program = c1.sorlcur_program
                                                               )
                                        and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
                                            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE , SSBSECT_PTRM_CODE
                                            order by 1,3 asc
                                    )  x
                                    where rownum = 1
                                    group by x.Periodo, x.pperiodo
                                    order by 2 asc;

                                    if vl_tipo_ini = 0 then

                                        vl_tipo_ini:=2;

                                    end if;

                            exception when others then

                                     begin

                                        select distinct substr (SZTALGO_PTRM_CODE_NEW, 2,1)
                                        into vl_tipo_ini
                                        from sztalgo
                                        where 1 = 1
                                        and sztalgo_no_regla = p_regla
                                        and rownum = 1;

                                     exception when others then
                                        null;
                                     end;
    --
                                     begin

                                        select distinct c.SORLCUR_START_DATE
                                        into vl_fecha_ing
                                        from sorlcur c
                                        where 1 = 1
                                        and c.sorlcur_pidm = alumno.SVRPROY_PIDM
                                        and c.sorlcur_program = alumno.ID_PROGRAMA
                                        and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                        And c.SORLCUR_ROLL_IND = 'Y'
                                        and c.SORLCUR_CACT_CODE ='ACTIVE'
                                        and c.SORLCUR_SEQNO = (
                                                               select max (c1.SORLCUR_SEQNO)
                                                               from sorlcur c1
                                                               where c.sorlcur_pidm = c1.sorlcur_pidm
                                                               and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                               and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                               and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                               and c.sorlcur_program = c1.sorlcur_program
                                                               );


                                     exception when others then
                                        null;
                                     end;
    --
    --


                            end;


                        End;
            End;

            DBMS_OUTPUT.PUT_LINE('Entra  al 8 Fecha '||vl_fecha_ing||' Inicio '||vl_tipo_ini);
            dbms_output.put_line ('Recupera el tipo de ingreso '||vl_fecha_ing|| '*'||vl_tipo_ini);

            If vl_tipo_ini = 0 or  vl_tipo_ini is null then

                vl_tipo_ini :=1;

            End if;

            DBMS_OUTPUT.PUT_LINE('Entra  al 9 ' ||vl_tipo_ini);

            vl_tipo_jornada:= null;

            vl_tip_ini:='NO';

            If vl_tipo_ini is not null then ----------> Si no puedo obtener el tipo de ingreso no registro al alumno --------------

                DBMS_OUTPUT.PUT_LINE('Entra  valor envio '||alumno.ID_PROGRAMA||'*'||alumno.SVRPROY_PIDM);

                Begin
                         select distinct substr (b.STVATTS_CODE, 3, 1) dato
                             Into vl_tipo_jornada
                         from SGRSATT a, STVATTS b, sorlcur c
                         where a.SGRSATT_ATTS_CODE = b.STVATTS_CODE
                         and a.SGRSATT_TERM_CODE_EFF = (select max ( a1.SGRSATT_TERM_CODE_EFF)
                                                        from SGRSATT a1
                                                        Where a.SGRSATT_PIDM = a1.SGRSATT_PIDM
                                                        and a1.SGRSATT_ATTS_CODE = a1.SGRSATT_ATTS_CODE
                                                        And regexp_like(a1.SGRSATT_ATTS_CODE, '^[0-9]') )
                         and regexp_like(a.SGRSATT_ATTS_CODE, '^[0-9]')
                         and SGRSATT_PIDM =  alumno.SVRPROY_PIDM
                         and a.SGRSATT_PIDM = c.sorlcur_pidm
                         and c.sorlcur_program = alumno.ID_PROGRAMA
                         and c.SORLCUR_LMOD_CODE = 'LEARNER'
                         And c.SORLCUR_ROLL_IND = 'Y'
                         and c.SORLCUR_CACT_CODE ='ACTIVE'
                         and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
                                                from sorlcur c1
                                                where c.sorlcur_pidm = c1.sorlcur_pidm
                                                and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                and c.sorlcur_program = c1.sorlcur_program)
                         and a.SGRSATT_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO;

                         DBMS_OUTPUT.PUT_LINE('Entra  al 10 tipo de Jornada '||vl_tipo_jornada);

                Exception
                When Others then

                   IF alumno.campus  in ('UTL','UMM')  and alumno.NIVEL  in ('MA') then
                     vl_tipo_jornada := 'N';
                   ELSIF alumno.campus  in ('UTL','UMM')  and alumno.NIVEL  in ('LI') then
                     vl_tipo_jornada := 'C';
                   ELSE
                     vl_tipo_jornada := 'N';
                   END IF;
                   --dbms_output.put_line ('Error al recuperar la jornada cursada '||sqlerrm);
                End;

                IF alumno.campus  in ('UTL','UMM','UIN')  and alumno.NIVEL  in ('MA') and vl_tipo_jornada != 'N' then
                      vl_tipo_jornada := 'N';
                ELSIF alumno.campus  in ('UTL','UMM','UIN','COL')  and alumno.NIVEL  in ('LI') and vl_tipo_jornada = 'R' then
                     vl_tipo_jornada := 'R';
                END IF;

                dbms_output.put_line ('recuperar la jornada cursada '||vl_tipo_jornada);
                DBMS_OUTPUT.PUT_LINE('Entra  al 11 ');

                vl_qa_avance :=0;
          ----- Se obtiene el numero de QA que lleva cursados el alumno  -----------------
                     Begin

                              SELECT count (distinct a.SFRSTCR_TERM_CODE) Periodo
                                 Into vl_qa_avance
                             FROM SFRSTCR a, SSBSECT b, sorlcur c
                            WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                                  AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                             --     And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB not  in ('L1HB401', 'IND00001', 'L1HB405', 'L1HB404', 'L1HB403', 'L1HP401', 'L1HB402', 'UTEL001')
                                 AND a.SFRSTCR_RSTS_CODE = 'RE'
                                  AND b.SSBSECT_PTRM_START_DATE =
                                         (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                            FROM SSBSECT b1
                                           WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                 AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                            and SFRSTCR_pidm = c.sorlcur_pidm
                            and c.sorlcur_program =   alumno.ID_PROGRAMA
                            and c.SORLCUR_LMOD_CODE = 'LEARNER'
                            And c.SORLCUR_ROLL_IND = 'Y'
                            and c.SORLCUR_CACT_CODE ='ACTIVE'
                            and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
                                                                     from sorlcur c1
                                                                     where c.sorlcur_pidm = c1.sorlcur_pidm
                                                                     and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                                     and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                                     and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                                     and c.sorlcur_program = c1.sorlcur_program)
                            and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
                            and  SFRSTCR_pidm = alumno.SVRPROY_PIDM
--                            And SFRSTCR_TERM_CODE not in (select distinct SZTALGO_TERM_CODE_NEW
--                                                                                from sztalgo
--                                                                                where SZTALGO_NO_REGLA = P_REGLA)
                         GROUP BY SFRSTCR_pidm ;

                     Exception
                         When Others then
                                 Begin
                                     SELECT count (distinct a.SFRSTCR_TERM_CODE) Periodo
                                         Into vl_qa_avance
                                     FROM SFRSTCR a, SSBSECT b, sorlcur c
                                    WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                                          AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                                    --   And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB not  in ('L1HB401', 'IND00001', 'L1HB405', 'L1HB404', 'L1HB403', 'L1HP401', 'L1HB402', 'UTEL001')
                                         AND a.SFRSTCR_RSTS_CODE != 'RE'
                                          AND b.SSBSECT_PTRM_START_DATE =
                                                 (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                                    FROM SSBSECT b1
                                                   WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                         AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                                    and SFRSTCR_pidm = c.sorlcur_pidm
                                    and c.sorlcur_program =   alumno.ID_PROGRAMA
                                    and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                    And c.SORLCUR_ROLL_IND = 'Y'
                                    and c.SORLCUR_CACT_CODE ='ACTIVE'
                                    and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
                                                                             from sorlcur c1
                                                                             where c.sorlcur_pidm = c1.sorlcur_pidm
                                                                             and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                                             and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                                             and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                                             and c.sorlcur_program = c1.sorlcur_program)
                                    and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
                                    and  SFRSTCR_pidm = alumno.SVRPROY_PIDM
--                                    And SFRSTCR_TERM_CODE not in (select distinct SZTALGO_TERM_CODE_NEW
--                                                                                from sztalgo
--                                                                                where SZTALGO_NO_REGLA = P_REGLA)
                                    GROUP BY SFRSTCR_pidm ;
                                 exception
                                 When Others then
                                   vl_qa_avance :=0;
                                 End;
                           dbms_output.put_line ('Error al recuperar el QA cursado '||sqlerrm);
                         vl_qa_avance :=1;
                     End;

                         dbms_output.put_line (' recuperar el QA cursado '||vl_qa_avance||' Programa '||alumno.ID_PROGRAMA);
          --------- Se obtiene el bimestre que se esta cursando ------------------------

                     vl_parte_bim :=null;


                 If vl_parte_bim is null then
                    vl_parte_bim := vl_tipo_ini;
                 End if;

                 IF vl_qa_avance >= 20 THEN
                    vl_qa_avance:=20;
                 END IF;


                 -- se calcuala el bimestre en donde esta cursando
                 IF vl_qa_avance IN (0,1) THEN

                     l_bim:=1;

                 ELSIF vl_qa_avance> 1 THEN

                     l_bim:=2;

                 END IF;

                 dbms_output.put_line ('BimestreSSS '||l_bim);

                 DBMS_OUTPUT.PUT_LINE('Entra  al 15 campus XXX '||alumno.campus||' nivel '||alumno.nivel);

                 If vl_parte_bim is  not null then----------> Si no existe parte de periodo no se incluye al alumno

                    --programación para Lic.
                    BEGIN

                        SELECT COUNT(*)
                        INTO l_cuenta_para_campus
                        FROM zstpara
                        WHERE 1 = 1
                        AND zstpara_mapa_id='CAMP_PRONO'
                        and zstpara_param_id  = alumno.campus
                         AND zstpara_param_valor = alumno.nivel
                        AND zstpara_param_valor ='LI';

                    EXCEPTION WHEN OTHERS THEN
                        l_cuenta_para_campus:=0;
                    END;

                    if l_cuenta_para_campus > 0 then


                        DBMS_OUTPUT.PUT_LINE('entra a para  avanceSSS '||vl_qa_avance||' sztasgn_jorn_code '||vl_tipo_jornada||' sztasgn_inso_code '||vl_tip_ini);

                         For asigna in (
                                         SELECT (sztasgn_crse_numb + sztasgn_opt_numb ) asignacion
                                         FROM sztasgn
                                         WHERE 1 = 1
                                         AND sztasgn_camp_code = alumno.campus
                                         AND sztasgn_levl_code = alumno.nivel
                                         AND sztasgn_qnumb = 'Q'||NVL(vl_qa_avance,1)
                                         AND sztasgn_bim_numb in( 'B'||l_bim)
                                         AND sztasgn_jorn_code = vl_tipo_jornada
                                         AND sztasgn_inso_code = vl_tip_ini
                                         UNION
                                         SELECT (sztasgn_crse_numb + sztasgn_opt_numb ) asignacion
                                         FROM sztasgn
                                         WHERE 1 = 1
                                         AND sztasgn_camp_code = alumno.campus
                                         AND sztasgn_levl_code = alumno.nivel
                                         AND sztasgn_qnumb = 'Q'||NVL(vl_qa_avance,1)
                                         AND sztasgn_jorn_code = DECODE(vl_tipo_jornada,'N','I',vl_tipo_jornada)
                                         AND sztasgn_inso_code = vl_tip_ini

                                        ) loop

                                               DBMS_OUTPUT.PUT_LINE('entra a para  avance XXX '||vl_qa_avance||' tipo de Jornada '||vl_tipo_jornada||' tip ini '||vl_tip_ini);

                                            vl_contador :=0;

                                            For materia in (

                                                            SELECT DISTINCT a.id_alumno,
                                                                            a.id_ciclo,
                                                                            a.id_programa,
                                                                            a.clave_materia_agp materia,
                                                                            a.secuencia,
                                                                            a.svrproy_pidm,--, a.ID_PERIODO,
                                                                            a.clave_materia materia_banner,
                                                                            a.fecha_inicio,
                                                                            c.study_path,
                                                                            a.rel_alumnos_x_asignar_cuatri cuatrimestre,
                                                                            c.rel_programaxalumno_estatus estatus,
                                                                            a.id_periodo ptrm
                                                            FROM rel_alumnos_x_asignar a,
                                                                 rel_programaxalumno c
                                                            WHERE 1 = 1
                                                            AND a.svrproy_pidm = alumno.svrproy_pidm
                                                            AND a.materias_excluidas = 0
                                                            AND c.sgbstdn_pidm= a.svrproy_pidm
                                                            AND a.id_periodo IS NOT NULL
                                                            AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
                                                            AND a.rel_alumnos_x_asignar_no_regla = p_regla
                                                            AND a.materias_excluidas = 0
                                                            AND  (a.svrproy_pidm, clave_materia, a.rel_alumnos_x_asignar_no_regla)  NOT IN (SELECT sztprono_pidm,
                                                                                                                                                   sztprono_materia_banner,
                                                                                                                                                   sztprono_no_regla
                                                                                                                                            FROM sztprono
                                                                                                                                            where 1 = 1
                                                                                                                                            AND  sztprono_pidm =  a.svrproy_pidm
                                                                                                                                            AND  sztprono_no_regla = p_regla )
                                                             and exists (select null
                                                                            from sztgpme
                                                                            where 1 = 1
                                                                            and SZTGPME_no_regla = p_regla
                                                                            and SZTGPME_SUBJ_CRSE= a.clave_materia_agp)
                                                            order by 1, cuatrimestre,SECUENCIA , materia
                                                            ) Loop

                                                                   DBMS_OUTPUT.PUT_LINE('entra a para  avance 3 '||vl_qa_avance||' tipo de Jornada '||vl_tipo_jornada||' tip ini '||vl_tip_ini);

                                                                begin

                                                                   SELECT COUNT(*)
                                                                   INTO l_cuenta_prop
                                                                   FROM sztptrm
                                                                   WHERE 1 = 1
                                                                   AND sztptrm_propedeutico = 1
                                                                   AND sztptrm_term_code =materia.id_ciclo
                                                                   AND sztptrm_ptrm_code =alumno.id_periodo
                                                                   AND sztptrm_program =materia.id_programa;

                                                                exception when others then
                                                                   null;
                                                                end;

                                                                begin

                                                                    SELECT distinct SZTPTRM_MATERIA
                                                                    INTO l_curso_p
                                                                    FROM sztptrm
                                                                    WHERE 1 = 1
                                                                    AND sztptrm_propedeutico = 1
                                                                    AND sztptrm_term_code =materia.id_ciclo
                                                                    AND sztptrm_ptrm_code =alumno.id_periodo
                                                                    AND sztptrm_program =materia.id_programa;

                                                                exception when others then
                                                                   null;
                                                                end;

                                                                BEGIN

                                                                    SELECT COUNT(*)
                                                                    INTO l_cuenta_sfr
                                                                    FROM SFRSTCR
                                                                    WHERE 1 = 1
                                                                    AND sfrstcr_pidm = materia.svrproy_pidm
                                                                    AND sfrstcr_stsp_key_sequence =materia.study_path
                                                                    AND sfrstcr_rsts_code ='RE';

                                                                 EXCEPTION WHEN OTHERS THEN
                                                                    NULL;
                                                                 END;


                                                                if l_cuenta_prop >= 1 /*and vl_qa_avance =1*/ and materia.estatus IN('N','F','R') and l_cuenta_sfr = 0 then


                                                                    begin

                                                                        select count(*)
                                                                        into l_existe_alumno
                                                                        from sztprono
                                                                        where 1 = 1
                                                                        and sztprono_no_regla = p_regla
                                                                        and sztprono_pidm =materia.svrproy_pidm;

                                                                    exception when others then
                                                                        null;
                                                                    end;


                                                                    if l_existe_alumno = 0 then

                                                                                 vl_contador :=1;

                                                                                --raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);

                                                                                BEGIN

                                                                                     INSERT INTO sztninc VALUES (materia.svrproy_pidm,
                                                                                                                 materia.id_ciclo,
                                                                                                                 alumno.id_periodo,
                                                                                                                 SYSDATE,
                                                                                                                 alumno.nivel,
                                                                                                                 alumno.campus,
                                                                                                                 USER,
                                                                                                                 'PRONOSTICO',
                                                                                                                 l_curso_p,
                                                                                                                 l_curso_p,
                                                                                                                 materia.fecha_inicio,
                                                                                                                 p_regla
                                                                                                                 );
                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                     null;
                                                                                END;

                                                                                Commit;

                                                                                dbms_output.put_line(' contador '||vl_contador||' regla '||p_regla);

                                                                               exit when vl_contador=ASIGNA.ASIGNACION;

                                                                               commit;

                                                                    end if;

                                                                else

                                                                            begin

                                                                                select count(*)
                                                                                into l_existe_alumno
                                                                                from sztprono
                                                                                where 1 = 1
                                                                                and sztprono_no_regla = p_regla
                                                                                and sztprono_pidm =materia.svrproy_pidm;

                                                                            exception when others then
                                                                                null;
                                                                            end;

                                                                            DBMS_OUTPUT.PUT_LINE('Existe el alumno '||l_existe_alumno);

                                                                            if l_existe_alumno = 0 then

                                                                                 vl_contador := vl_contador +1;

                                                                                --raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);

                                                                                BEGIN

                                                                                     INSERT INTO sztninc VALUES (materia.svrproy_pidm,
                                                                                                                 materia.id_ciclo,
                                                                                                                 alumno.id_periodo,
                                                                                                                 SYSDATE,
                                                                                                                 alumno.nivel,
                                                                                                                 alumno.campus,
                                                                                                                 USER,
                                                                                                                 'PRONOSTICO',
                                                                                                                 materia.materia,
                                                                                                                 materia.materia_banner,
                                                                                                                 materia.fecha_inicio,
                                                                                                                 p_regla
                                                                                                                 );
                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                     null;
                                                                                END;

                                                                                Commit;

                                                                                dbms_output.put_line(' contador '||vl_contador||' regla '||p_regla);

                                                                               exit when vl_contador=ASIGNA.ASIGNACION;

                                                                               commit;

                                                                            end if;


                                                                 end if;

                                                            end loop materia;

                                                            DBMS_OUTPUT.PUT_LINE('entra a asgn '||vl_contador||' Asignacion '||ASIGNA.ASIGNACION);

                                                            vl_contador:=0;


                                        end loop asigna;

                    end if;

                    l_cuenta_para_campus:=null;

                    BEGIN

                        SELECT COUNT(*)
                        INTO l_cuenta_para_campus
                        FROM zstpara
                        WHERE 1 = 1
                        AND zstpara_mapa_id='CAMP_PRONO'
                        AND zstpara_param_id  = alumno.campus
                        AND zstpara_param_valor = alumno.nivel
                        AND zstpara_param_valor in('MA','MS','DO','EC');

                    EXCEPTION WHEN OTHERS THEN
                        l_cuenta_para_campus:=0;
                    END;

                    IF l_cuenta_para_campus > 0 THEN

                        IF vl_parte_bim = 2 THEN

                            vl_qa_avance := vl_qa_avance +1;

                            vl_parte_bim := 1;

                        ELSIF  vl_parte_bim = 1 THEN

                            vl_qa_avance := vl_qa_avance +1;

                        ELSIF  vl_parte_bim = 3 THEN

                            vl_qa_avance := vl_qa_avance +1;

                        ELSIF  vl_parte_bim = 0 THEN

                            vl_parte_bim := vl_parte_bim +1;

                        END IF;
--
                        IF vl_tipo_ini = 0 THEN

                            vl_tip_ini := 'AN';

                        ELSIF vl_tipo_ini IN (1,3, 2,4) THEN

                            vl_tip_ini := 'NO';

                        END IF;

                        vl_asignacion := 0;
                        val_max :=0;

                         IF alumno.periodicidad = 1 THEN

                         dbms_output.put_line ('salida1 '||alumno.campus ||'*'||alumno.NIVEL||'*'||'Q'||vl_qa_avance||'*'||'B'||vl_parte_bim||'*'||vl_tip_ini);

                         DBMS_OUTPUT.PUT_LINE('Entra  al 36 ');


                              BEGIN

                                  SELECT COUNT (DISTINCT sztasma_qnumb)
                                      Into val_max
                                  FROM sztasma
                                  WHERE  1 = 1
                                  AND sztasma_camp_code = alumno.campus
                                  AND sztasma_levl_code = alumno.nivel
                                  AND sztasma_bim_numb is not null;

                                       DBMS_OUTPUT.PUT_LINE('Entra  al 37 val_max '||val_max);
                              EXCEPTION WHEN OTHERS THEN
                                val_max :=0;
                              END;

                              DBMS_OUTPUT.PUT_LINE('Entra  al 38 vl_qa_avance '||vl_qa_avance||' tipo inicio '||vl_tip_ini);

                              IF vl_parte_bim = 4 THEN

                                vl_parte_bim:=2;

                              END IF;

                              --vl_qa_avance := 2;


                         ELSIF alumno.periodicidad = 2 THEN

                           dbms_output.put_line ('salida2 '||alumno.campus ||'*'||alumno.NIVEL||'*'||'Q'||vl_qa_avance||'*'||'B'||vl_parte_bim||'*--> '||vl_tip_ini);

                           DBMS_OUTPUT.PUT_LINE('Entra  al 40 ');

                              BEGIN

                                  SELECT COUNT (DISTINCT sztasma_qnumb)
                                  INTO val_max
                                  FROM sztasma
                                  WHERE sztasma_camp_code = alumno.campus
                                  AND sztasma_levl_code = alumno.nivel
                                  AND sztasma_bim_numb is not null;

                                       DBMS_OUTPUT.PUT_LINE('Entra  al 41 val_max '||val_max);
                              EXCEPTION WHEN OTHERS THEN
                                val_max :=0;
                              END;

                              IF alumno.campus ='UMM' THEN

                                   vl_asignacion :=3;

                              END IF;


                         end if;

                         vl_contador :=0;
                                     DBMS_OUTPUT.PUT_LINE('Entra  al 44 aqui avance '||vl_qa_avance);
                                       For materia in (
                                                       SELECT DISTINCT a.id_alumno,
                                                                       a.id_ciclo,
                                                                       a.id_programa,
                                                                       a.clave_materia_agp materia,
                                                                       a.secuencia,
                                                                       a.svrproy_pidm,--, a.ID_PERIODO,
                                                                       a.clave_materia materia_banner,
                                                                       a.fecha_inicio,
                                                                       c.study_path,
                                                                       a.rel_alumnos_x_asignar_cuatri cuatrimestre,
                                                                       rel_programaxalumno_estatus estatus
                                                       FROM rel_alumnos_x_asignar a,
                                                            rel_programaxalumno c
                                                       WHERE 1 = 1
                                                       AND a.svrproy_pidm = alumno.svrproy_pidm
                                                       AND a.materias_excluidas = 0
                                                       AND c.sgbstdn_pidm= a.svrproy_pidm
                                                       AND a.id_periodo is not null
                                                       AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
                                                       AND a.rel_alumnos_x_asignar_no_regla = p_regla
--                                                        and exists (select null
--                                                                            from sztgpme
--                                                                            where 1 = 1
--                                                                            and SZTGPME_no_regla = p_regla
--                                                                            and SZTGPME_SUBJ_CRSE= a.clave_materia_agp)
            --                                           and a.ID_ALUMNO='010044146'
                                                       union
                                                       -- curso introductorio
                                                        SELECT DISTINCT a.id_alumno,
                                                                        a.id_ciclo,
                                                                        a.id_programa,
                                                                        a.clave_materia_agp materia,
                                                                        a.secuencia,
                                                                        a.svrproy_pidm,--, a.ID_PERIODO,
                                                                        a.clave_materia materia_banner,
                                                                        a.fecha_inicio,
                                                                        c.study_path,
                                                                        a.rel_alumnos_x_asignar_cuatri cuatrimestre,
                                                                        rel_programaxalumno_estatus estatus
                                                        FROM rel_alumnos_x_asignar a,
                                                             rel_programaxalumno c
                                                        WHERE 1 = 1
                                                        AND a.svrproy_pidm = alumno.svrproy_pidm
                                                        AND a.materias_excluidas = 0
                                                        AND c.sgbstdn_pidm= a.svrproy_pidm
                                                        AND a.id_periodo is not null
                                                        AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
                                                        AND a.rel_alumnos_x_asignar_no_regla = p_regla
                                                        and exists (select null
                                                                    from sztgpme
                                                                    where 1 = 1
                                                                    and SZTGPME_no_regla = p_regla
                                                                    and SZTGPME_SUBJ_CRSE= 'M1HB401'
                                                                    )
                                                        ORDER BY 1, cuatrimestre ,secuencia , materia

                                          ) LOOP

                                                  vl_contador := vl_contador +1;
                                                  dbms_output.put_line ('Contador  ' || vl_contador);
                                                  DBMS_OUTPUT.PUT_LINE('Entra  al 45 estatus '||materia.estatus);



                                                 BEGIN

                                                    SELECT COUNT(*)
                                                    INTO l_cuenta_asma
                                                    FROM ZSTPARA
                                                    WHERE 1 = 1
                                                    AND zstpara_mapa_id ='ASMA_MAT'
                                                    AND zstpara_param_desc ='Q'||vl_qa_avance
                                                    AND zstpara_param_id = materia.id_programa;

                                                 EXCEPTION WHEN OTHERS THEN
                                                    NULL;
                                                 END;

                                                 IF l_cuenta_asma > 0 THEN

                                                     BEGIN

                                                        select DISTINCT zstpara_param_valor
                                                        into vl_asignacion
                                                        FROM zstpara
                                                        WHERE 1 = 1
                                                        AND zstpara_mapa_id ='ASMA_MAT'
                                                        AND zstpara_param_desc ='Q'||vl_qa_avance
                                                        and zstpara_param_id = materia.id_programa;

                                                     EXCEPTION WHEN OTHERS THEN
                                                        NULL;
                                                     END;

                                                 ELSE

                                                     begin

                                                        select count(*)
                                                        into l_cuenta_asma
                                                        from sztasma
                                                        where 1 = 1
                                                        and SZTASMA_CAMP_CODE = alumno.campus
                                                        and SZTASMA_LEVL_CODE = alumno.nivel
                                                        and SZTASMA_PROGRAMA =materia.id_programa;

                                                    exception when others then
                                                        l_cuenta_asma:=0;
                                                    end;



                                                    if l_cuenta_asma > 0  and vl_qa_avance > 5 then

                                                        DBMS_OUTPUT.PUT_LINE('Entra  a asma '||l_cuenta_asma);

                                                        BEGIN
                                                              SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                              INTO vl_asignacion
                                                              FROM sztasma
                                                              WHERE sztasma_camp_code = alumno.campus
                                                              AND sztasma_levl_code = alumno.nivel
                                                              AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                              AND sztasma_bim_numb IS NULL
                                                              AND sztasma_inso_code = vl_tip_ini
                                                              and SZTASMA_PROGRAMA =materia.id_programa;

                                                              DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion);
                                                         EXCEPTION WHEN OTHERS THEN
                                                             vl_asignacion :=0;

                                                              IF alumno.campus IN ('UMM','UIN') THEN
                                                                  vl_asignacion :=2;
                                                              END IF;

                                                         END;

                                                          --cuando pasa del maximo q
                                                         if vl_qa_avance   >= val_max then

                                                            vl_asignacion:=4;

                                                         end if;

                                                    else
                                                        --raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);

                                                         l_valida_asma:=0;

                                                            BEGIN
                                                                  SELECT count(*)
                                                                  INTO l_valida_asma
                                                                  FROM sztasma
                                                                  WHERE sztasma_camp_code = alumno.campus
                                                                  AND sztasma_levl_code = alumno.nivel
                                                                  AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                                  AND sztasma_bim_numb ='B'||l_bim
                                                                  AND sztasma_inso_code = vl_tip_ini
                                                                  and SZTASMA_PROGRAMA = materia.id_programa;

                                                                  DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion);
                                                            EXCEPTION WHEN OTHERS THEN
                                                                null;

                                                            END;

                                                            DBMS_OUTPUT.PUT_LINE(' valores '||l_valida_asma||' avance '||vl_qa_avance||' Bimestre '||l_bim||' inicio '||vl_tip_ini||' Programa '||materia.id_programa);

                                                            if l_valida_asma = 0 then

                                                                     DBMS_OUTPUT.PUT_LINE(' valores cero cero');

                                                                     BEGIN
                                                                          SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                                          INTO vl_asignacion
                                                                          FROM sztasma
                                                                          WHERE sztasma_camp_code = alumno.campus
                                                                          AND sztasma_levl_code = alumno.nivel
                                                                          AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                                          AND sztasma_bim_numb = 'B'||l_bim
                                                                          AND sztasma_inso_code = vl_tip_ini
                                                                          and SZTASMA_PROGRAMA IS NULL;

                                                                          DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion||'2850');
                                                                     EXCEPTION WHEN OTHERS THEN
                                                                         vl_asignacion :=0;

                                                                          IF alumno.campus IN ('UMM','UIN') THEN
                                                                              vl_asignacion :=3;
                                                                          END IF;

                                                                     END;

                                                                     DBMS_OUTPUT.PUT_LINE(' valores de asignacion  '||vl_asignacion);

                                                                     --cuando pasa del maximo q
                                                                     if vl_qa_avance   >= val_max then

                                                                        vl_asignacion:=4;

                                                                     end if;

                                                            elsif l_valida_asma > 0 then

                                                                 BEGIN
                                                                      SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                                      INTO vl_asignacion
                                                                      FROM sztasma
                                                                      WHERE sztasma_camp_code = alumno.campus
                                                                      AND sztasma_levl_code = alumno.nivel
                                                                      AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                                      AND sztasma_bim_numb ='B'||l_bim
                                                                      AND sztasma_inso_code = vl_tip_ini
                                                                      and SZTASMA_PROGRAMA = materia.id_programa;

                                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion);
                                                                 EXCEPTION WHEN OTHERS THEN
                                                                     vl_asignacion :=0;

                                                                      IF alumno.campus ='UMM' THEN
                                                                          vl_asignacion :=3;
                                                                      END IF;

                                                                 END;

                                                            end if;

                                                    end if;


                                                 END IF;

                                                 DBMS_OUTPUT.PUT_LINE('Periodicidad '||alumno.PERIODICIDAD||' Periodo 2'||alumno.ID_PERIODO);

                                                 begin

                                                    SELECT COUNT(*)
                                                    INTO l_cuenta_prop
                                                    FROM sztptrm
                                                    WHERE 1 = 1
                                                    AND sztptrm_propedeutico = 1
                                                    AND sztptrm_term_code =materia.id_ciclo
                                                    AND sztptrm_ptrm_code =alumno.id_periodo
                                                    AND sztptrm_program =materia.id_programa;

                                                 exception when others then
                                                    null;
                                                 end;

                                                 DBMS_OUTPUT.PUT_LINE('Periodo '||materia.ID_CICLO||' Ptrm '||alumno.ID_PERIODO||' Programa '||materia.ID_PROGRAMA||' Matricula '||materia.ID_ALUMNO||' Prope '||l_cuenta_prop);
                                                 --macana1

                                                 BEGIN

                                                    SELECT COUNT(*)
                                                    INTO l_cuenta_sfr
                                                    FROM SFRSTCR
                                                    WHERE 1 = 1
                                                    AND sfrstcr_pidm = materia.svrproy_pidm
                                                    AND sfrstcr_stsp_key_sequence =materia.study_path
                                                    AND sfrstcr_rsts_code ='RE';

                                                 EXCEPTION WHEN OTHERS THEN
                                                    NULL;
                                                 END;

                                                 DBMS_OUTPUT.PUT_LINE('Entra  al asma '||l_cuenta_prop||' cuenta matyerias '||l_cuenta_sfr||' Avance '||vl_qa_avance);

                                                if l_cuenta_prop >= 1 /*and vl_qa_avance =1*/ and materia.estatus IN('N','F') and l_cuenta_sfr = 0 then

                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 47000 '||l_cuenta_prop);

                                                   begin

                                                       select count(*)
                                                       into l_existe_alumno
                                                       from sztprono
                                                       where 1 = 1
                                                       and sztprono_no_regla = p_regla
                                                       and sztprono_pidm =materia.svrproy_pidm;

                                                   exception when others then
                                                       null;
                                                   end;

                                                    if l_existe_alumno = 0 then


                                                        BEGIN

                                                            INSERT INTO sztninc VALUES (materia.svrproy_pidm,
                                                                                        materia.id_ciclo,
                                                                                        alumno.id_periodo,
                                                                                        SYSDATE,
                                                                                        alumno.nivel,
                                                                                        alumno.campus,
                                                                                        USER,
                                                                                        'PRONOSTICO',
                                                                                        'M1HB401',
                                                                                        'M1HB401',
                                                                                        materia.fecha_inicio,
                                                                                        p_regla
                                                                                        );
                                                        EXCEPTION WHEN OTHERS THEN
                                                             null;
                                                        END;

                                                        commit;

                                                        EXIT WHEN vl_contador=1;

                                                    END IF;

                                                ELSE

                                                    begin

                                                       select count(*)
                                                       into l_existe_alumno
                                                       from sztprono
                                                       where 1 = 1
                                                       and sztprono_no_regla = p_regla
                                                       and sztprono_pidm =materia.svrproy_pidm;

                                                   exception when others then
                                                       null;
                                                   end;

                                                   DBMS_OUTPUT.PUT_LINE('existe en prono '||l_existe_alumno);

                                                    if l_existe_alumno = 0 then


                                                        DBMS_OUTPUT.PUT_LINE('Llego al insert '||l_existe_alumno);


                                                         BEGIN

                                                             INSERT INTO baninst1.sztninc VALUES (materia.svrproy_pidm,
                                                                                         materia.id_ciclo,
                                                                                         alumno.id_periodo,
                                                                                         SYSDATE,
                                                                                         alumno.nivel,
                                                                                         alumno.campus,
                                                                                         USER,
                                                                                         'PRONOSTICO',
                                                                                         materia.materia,
                                                                                         materia.materia_banner,
                                                                                         materia.fecha_inicio,
                                                                                         p_regla
                                                                                         );
                                                         EXCEPTION WHEN OTHERS THEN
                                                              DBMS_OUTPUT.PUT_LINE('error '||sqlerrm);
                                                         END;



                                                         COMMIT;

                                                         select count(*)
                                                         into l_cuenta_nin
                                                         from sztninc
                                                         where 1 = 1
                                                         and sztninc_no_regla = p_regla;

                                                        DBMS_OUTPUT.PUT_LINE('Pidm '||materia.svrproy_pidm||' Ciclo  '||materia.id_ciclo||' Periodo '||alumno.id_periodo||' Nivel '||alumno.nivel||' Campus '||alumno.campus||' Materia '||materia.materia||' Banner '||materia.materia_banner||' Fecha Inicio '||materia.fecha_inicio||' Regla '||p_regla||' Ni '||l_cuenta_nin);


                                                        EXIT WHEN vl_contador= vl_asignacion;

                                                        commit;

                                                    END IF;

                                                END IF;
                                                 --banda


                                          END LOOP Materia;
                                          vl_contador :=0;

                            dbms_output.put_line ('Entra a Maestria Parte de bimestre ' ||vl_parte_bim);

                    END IF;




                 End if;

            Else
                     null;
              dbms_output.put_line ('Entra a Maestria Parte de bimestre ' ||vl_parte_bim);
            End if;
                    BEGIN

                             SELECT DISTINCT  SORLCUR_LEVL_CODE
                             INTO VL_NIVEL
                             FROM sorlcur c
                             WHERE 1 = 1
                             AND sorlcur_pidm =alumno.svrproy_pidm
                             AND c.sorlcur_program = alumno.id_programa
                             AND c.sorlcur_lmod_code = 'LEARNER'
                             AND c.sorlcur_roll_ind = 'Y'
                             AND c.sorlcur_cact_code ='ACTIVE'
                             AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
                                                    FROM sorlcur c1
                                                    WHERE c.sorlcur_pidm = c1.sorlcur_pidm
                                                    AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code
                                                    AND c.sorlcur_roll_ind = c1.sorlcur_roll_ind
                                                    AND c.sorlcur_cact_code = c1.sorlcur_cact_code
                                                    AND c.sorlcur_program = c1.sorlcur_program
                                                    );
                            EXCEPTION WHEN OTHERS THEN
                            VL_NIVEL:=NULL;
                        END;


                       BEGIN

                        SELECT COUNT(*)
                        INTO VL_campus
                        FROM zstpara
                        WHERE 1 = 1
                        AND zstpara_mapa_id='CAMP_PRONO'
                        AND zstpara_param_id  = alumno.campus
                        AND zstpara_param_valor = VL_NIVEL
                        AND zstpara_param_valor in('EC');

                        EXCEPTION WHEN OTHERS THEN
                            VL_campus:=0;
                        END;



                       IF VL_CAMPUS=1 THEN
                           vl_contador:=0;

                                   BEGIN
                                      SELECT COUNT (a.clave_materia)
                                      INTO vl_asignacion
                                      FROM rel_alumnos_x_asignar a
                                      WHERE 1 = 1
                                      AND a.svrproy_pidm = alumno.svrproy_pidm
                                      AND a.materias_excluidas = 0
                                      AND a.id_periodo is not null
                                      AND a.rel_alumnos_x_asignar_no_regla = p_regla ;

                                      EXCEPTION WHEN OTHERS THEN

                                       vl_asignacion:=6;

                                      END;

                                     BEGIN

                                       SELECT COUNT(*)
                                       INTO vl_contador
                                       FROM SZTNINC
                                       WHERE 1=1
                                       AND SZTNINC_PIDM = alumno.svrproy_pidm
                                       AND SZTNINC_NO_REGLA=p_regla
                                       and SZTNINC_PTRM_CODE=alumno.id_periodo;

                                      EXCEPTION WHEN OTHERS THEN

                                            DBMS_OUTPUT.PUT_LINE('error '||sqlerrm);
                                       END;
                       DBMS_OUTPUT.PUT_LINE('ENTRA DIPLO ');

                                                  For materia in
                                                  (
                                                           SELECT DISTINCT a.id_alumno,
                                                                       a.id_ciclo,
                                                                       a.ID_PERIODO,
                                                                       a.id_programa,
                                                                       a.clave_materia_agp materia,
                                                                       a.secuencia,
                                                                       a.svrproy_pidm,--, a.ID_PERIODO,
                                                                       a.clave_materia materia_banner,
                                                                       a.fecha_inicio,
                                                                       c.study_path,
                                                                       a.rel_alumnos_x_asignar_cuatri cuatrimestre,
                                                                       rel_programaxalumno_estatus estatus
                                                       FROM rel_alumnos_x_asignar a,
                                                            rel_programaxalumno c
                                                       WHERE 1 = 1
                                                       AND a.svrproy_pidm = alumno.svrproy_pidm
                                                       AND a.materias_excluidas = 0
                                                       AND c.sgbstdn_pidm= a.svrproy_pidm
                                                       AND a.id_periodo is not null
                                                       AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
                                                       AND a.rel_alumnos_x_asignar_no_regla = p_regla
                                                      AND  (a.svrproy_pidm, a.clave_materia, a.rel_alumnos_x_asignar_no_regla)  NOT IN (SELECT SZTNINC_PIDM,SZTNINC_SUBJ_CODE,SZTNINC_NO_REGLA
                                                                                                                                           FROM SZTNINC
                                                                                                                                           WHERE 1=1
                                                                                                                                           AND SZTNINC_PIDM = a.svrproy_pidm
                                                                                                                                           AND SZTNINC_NO_REGLA=p_regla)
                                                       order by a.secuencia asc
                                                 )
                                                  LOOP



                                                       IF  vl_contador<=vl_asignacion THEN

                                                          BEGIN
                                                               DBMS_OUTPUT.PUT_LINE('INSERTA DIPLO');
                                                             INSERT INTO baninst1.sztninc VALUES (
                                                                                         materia.svrproy_pidm,
                                                                                         materia.id_ciclo,
                                                                                         materia.ID_PERIODO,
                                                                                         SYSDATE,
                                                                                         VL_NIVEL,
                                                                                         alumno.campus,
                                                                                         USER,
                                                                                         'PRONOSTICO',
                                                                                         materia.materia,
                                                                                         materia.materia_banner,
                                                                                         materia.fecha_inicio,
                                                                                         p_regla
                                                                                         );
                                                                                         COMMIT;
                                                         EXCEPTION WHEN OTHERS THEN

                                                              DBMS_OUTPUT.PUT_LINE('error '||sqlerrm);
                                                         END;
                                                       END IF;
                                                  END LOOP;

                         END IF;

            DBMS_OUTPUT.PUT_LINE('Itera  '||l_itera);



      End Loop alumno;

--       begin
--            (P_REGLA ,p_pidm);
--       end;

      commit;


 END;

    PROCEDURE P_MATERIAS_PIDM (P_REGLA NUMBER,
                               p_pidm  NUMBER)
    IS
    vl_numero number:=0;
    vl_contador number:=0;
    vl_avance number :=0;
    vl_fecha_ing date;
    vl_tipo_ini number;
    vl_tipo_jornada varchar2(1):= null;
    vl_qa_avance number :=0;
    vl_parte_bim number :=0;
    vl_tip_ini varchar2(10):= null;
    vl_asignacion number:=0;
    val_max number:=0;
    vl_Error Varchar2(2000) := 'EXITO';
    l_ptrm_algo varchar2(10);
    l_itera number:=0;
    l_cuenta_registro number;

    l_cuenta_sfr number;
    l_cuenta_semi number;

    l_bim NUMBER;
    l_sp number;







    l_cuenta_grade number;

    l_cuenta_asma number;
    l_cuenta_prop number;
    l_semis varchar2(2);
    l_cuenta_para_campus number:=0;
    l_anticipado varchar2(1);
    l_anticipo_r varchar2(1):= null;
    l_tipo_alu varchar2(2):= null;
    l_valida_asma number;
    l_curso_p varchar2(100);
    l_aprobatoria varchar2(10);
    l_cuenta_sfr_campus number;
    l_free  varchar2(10);
    l_cuenta_free number;
    l_asigna_free number;
    l_cuenta_eje  number;
    l_secuencia  number;
    l_materia_iebs varchar2(20);
    l_cuneta_semi number;

    l_cuenta_nivel number;

    l_nivel        VARCHAR2(2);
    l_cuenta_iebs number;

    l_cuenta_unicef number;

    l_cuenta_onu    number;
    l_cuenta_uba    number;
    l_cuenta_p      NUMBER;
    l_ptrm_pi       VARCHAR2(3);


BEGIN

    l_cuenta_para_campus:=0;

    DBMS_OUTPUT.PUT_LINE('Entra  al 1 xx ');

    BEGIN
        DELETE sztprono
        WHERE 1 = 1
        AND sztprono_no_regla = p_regla
        AND SZTPRONO_PIDM= p_pidm;

        COMMIT;

    EXCEPTION WHEN OTHERS THEN
       raise_application_error (-20002,'Error al insertar a tabla de paso 1 '|| SQLERRM||' '||SQLCODE);
    END;

   l_itera:=0;

    FOR alumno IN (
                      SELECT DISTINCT id_alumno,
                                       id_ciclo,
                                       id_programa,
                                       svrproy_pidm,
                                       id_periodo,
                                        (SELECT DISTINCT sztdtec_periodicidad
                                         FROM SZTDTEC
                                         WHERE 1 = 1
                                         AND SZTDTEC_PROGRAM = ID_PROGRAMA
                                         AND SZTDTEC_TERM_CODE = periodo_catalogo
                                         ) periodicidad,
                                         null rate,
                                         null jornada,
                                         campus,
                                         (SELECT distinct NIVEL
                                         FROM REL_PROGRAMAXALUMNO
                                         WHERE 1 = 1
                                         AND REL_PROGRAMAXALUMNO_NO_REGLA = REL_ALUMNOS_X_ASIGNAR_NO_REGLA
                                         AND SGBSTDN_PIDM = SVRPROY_PIDM
                                         ) nivel,
                                         null jornada_com,
                                         rel_alumnos_x_asignar_no_regla sztprvn_no_regla,
                                         tipo_equi equi,
                                         periodo_catalogo,
                                         fecha_inicio,
                                         (SELECT distinct REL_PROGRAMAXALUMNO_ESTATUS
                                         FROM REL_PROGRAMAXALUMNO
                                         WHERE 1 = 1
                                         AND REL_PROGRAMAXALUMNO_NO_REGLA = REL_ALUMNOS_X_ASIGNAR_NO_REGLA
                                         AND SGBSTDN_PIDM = SVRPROY_PIDM
                                         AND rownum = 1
                                         ) estatus,
                                         STUDY_PATH sp
                      FROM rel_alumnos_x_asignar
                      WHERE 1 = 1
                      AND rel_alumnos_x_asignar_no_regla = p_regla
                      and svrproy_pidm = p_pidm
      ) Loop


            --DBMS_OUTPUT.PUT_LINE('Entra  al 6 '||alumno.id_alumno);

            vl_fecha_ing := NULL;
            vl_tipo_ini  := NULL;
            l_anticipo_r := null;
            l_tipo_alu := null;



            BEGIN

                 SELECT DISTINCT MIN(TO_DATE(ssbsect_ptrm_start_date)) fecha_inicio,
                                 MIN(SUBSTR(ssbsect_ptrm_code,2,1)) pperiodo
                 INTO vl_fecha_ing,
                      vl_tipo_ini
                 FROM sfrstcr a,
                      ssbsect b,
                      sorlcur c
                 WHERE 1 = 1
                 AND a.sfrstcr_term_code = b.ssbsect_term_code
                 AND a.sfrstcr_crn = b.ssbsect_crn
                 AND a.sfrstcr_rsts_code = 'RE'
                 AND b.ssbsect_ptrm_start_date =(SELECT MIN (b1.ssbsect_ptrm_start_date)
                                                 FROM ssbsect b1
                                                 WHERE 1 = 1
                                                 AND b.ssbsect_term_code = b1.ssbsect_term_code
                                                 AND b.ssbsect_crn = b1.ssbsect_crn
                                                 )
                 AND sfrstcr_pidm =alumno.svrproy_pidm
                 AND sfrstcr_pidm = c.sorlcur_pidm
                 AND c.sorlcur_program = alumno.id_programa
                 AND c.sorlcur_lmod_code = 'LEARNER'
                 AND c.sorlcur_roll_ind = 'Y'
                 AND c.sorlcur_cact_code ='ACTIVE'
                 AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
                                        FROM sorlcur c1
                                        WHERE c.sorlcur_pidm = c1.sorlcur_pidm
                                        AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code
                                        AND c.sorlcur_roll_ind = c1.sorlcur_roll_ind
                                        AND c.sorlcur_cact_code = c1.sorlcur_cact_code
                                        AND c.sorlcur_program = c1.sorlcur_program
                                        )
                 AND sfrstcr_stsp_key_sequence =    c.sorlcur_key_seqno;


            EXCEPTION WHEN OTHERS THEN
                vl_fecha_ing:= NULL;
                vl_tipo_ini := NULL;
            END;

            dbms_output.put_line ('Recupera el tipo de ingreso '||SUBSTR(alumno.ID_PERIODO,2,1));

            IF vl_fecha_ing IS NULL AND vl_tipo_ini is null THEN

                vl_fecha_ing:=alumno.FECHA_INICIO;

                BEGIN
                    vl_tipo_ini:=SUBSTR(alumno.ID_PERIODO,2,1);
                exception when others then
                    vl_tipo_ini:=1;
                end;

            END IF;

            DBMS_OUTPUT.PUT_LINE('Entra  al 8 Fecha '||vl_fecha_ing||' Inicio '||vl_tipo_ini);
            dbms_output.put_line ('Recupera el tipo de ingreso '||vl_fecha_ing|| '*'||vl_tipo_ini);

            IF vl_tipo_ini = 0 or  vl_tipo_ini is null then

                vl_tipo_ini :=1;
                l_anticipo_r :=0;
                vl_tip_ini:='AN';

            else
                vl_tip_ini:='NO';

            End IF;
          --
            DBMS_OUTPUT.PUT_LINE('Entra  al 9 ' ||vl_tipo_ini||' Tipo de inicio '||vl_tip_ini);

            vl_tipo_jornada:= null;

--            vl_tip_ini:='NO';

            IF vl_tipo_ini is not null then ----------> Si no puedo obtener el tipo de ingreso no registro al alumno --------------

                DBMS_OUTPUT.PUT_LINE('Entra  valor envio '||alumno.ID_PROGRAMA||'*'||alumno.SVRPROY_PIDM);


                BEGIN


                    SELECT distinct  substr (TIPO_JORNADA, 3, 1) dato,TIPO_JORNADA, REL_PROGRAMAXALUMNO_ESTATUS
                    INTO vl_tipo_jornada, alumno.jornada_com,  l_tipo_alu
                    FROM REL_PROGRAMAXALUMNO
                    WHERE 1 = 1
                    AND REL_PROGRAMAXALUMNO_no_regla = p_regla
                    AND SGBSTDN_PIDM = alumno.SVRPROY_PIDM;


                exception when others then

                         BEGIN
                         SELECT distinct substr (b.STVATTS_CODE, 3, 1) dato,b.STVATTS_CODE
                             INTO vl_tipo_jornada,alumno.jornada_com
                         FROM SGRSATT a, STVATTS b, sorlcur c
                         WHERE a.SGRSATT_ATTS_CODE = b.STVATTS_CODE
                         AND a.SGRSATT_TERM_CODE_EFF = (SELECT max ( a1.SGRSATT_TERM_CODE_EFF)
                                                        FROM SGRSATT a1
                                                        WHERE a.SGRSATT_PIDM = a1.SGRSATT_PIDM
                                                        AND a1.SGRSATT_ATTS_CODE = a1.SGRSATT_ATTS_CODE
                                                        AND regexp_like(a1.SGRSATT_ATTS_CODE, '^[0-9]') )
                         AND regexp_like(a.SGRSATT_ATTS_CODE, '^[0-9]')
                         AND SGRSATT_PIDM =  alumno.SVRPROY_PIDM
                         AND a.SGRSATT_PIDM = c.sorlcur_pidm
                         AND c.sorlcur_program = alumno.ID_PROGRAMA
                         AND c.SORLCUR_LMOD_CODE = 'LEARNER'
                         AND c.SORLCUR_ROLL_IND = 'Y'
                         AND c.SORLCUR_CACT_CODE ='ACTIVE'
                         AND c.SORLCUR_SEQNO = (SELECT max (c1.SORLCUR_SEQNO)
                                                FROM sorlcur c1
                                                WHERE c.sorlcur_pidm = c1.sorlcur_pidm
                                                AND c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                AND c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                AND c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                AND c.sorlcur_program = c1.sorlcur_program)
                         AND a.SGRSATT_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO;

                         DBMS_OUTPUT.PUT_LINE('Entra  al 10 tipo de Jornada '||vl_tipo_jornada);

                    Exception
                    When Others then

                       IF alumno.campus  in ('UTL','UMM')  AND alumno.NIVEL  in ('MA') then
                         vl_tipo_jornada := 'N';
                       ELSIF alumno.campus  in ('UTL','UMM')  AND alumno.NIVEL  in ('LI') then
                         vl_tipo_jornada := 'C';
                       ELSE
                         vl_tipo_jornada := 'N';
                       END IF;
                      -- dbms_output.put_line ('Error al recuperar la jornada cursada '||sqlerrm);
                    End;
                end;




                IF alumno.campus  in ('UTL','UMM','UIN')  AND alumno.NIVEL  in ('MA') AND vl_tipo_jornada != 'N' then
                      vl_tipo_jornada := 'N';
                ELSIF alumno.campus  in ('UTL','UMM','UIN','COL')  AND alumno.NIVEL  in ('LI') AND vl_tipo_jornada = 'R' then
                     vl_tipo_jornada := 'R';
                END IF;

                dbms_output.put_line ('recuperar la jornada cursada '||vl_tipo_jornada);
                DBMS_OUTPUT.PUT_LINE('Entra  al 11 ');

                vl_qa_avance :=0;
          ----- Se obtiene el numero de QA que lleva cursados el alumno  -----------------
                 BEGIN

                    vl_qa_avance:=F_CALCULA_QA(alumno.id_ciclo,
                                               alumno.sp,
                                               alumno.svrproy_pidm,
                                               vl_tip_ini,
                                               p_regla,
                                               alumno.id_periodo,
                                               alumno.nivel);
                        DBMS_OUTPUT.PUT_LINE('QA AVANCE  '||vl_qa_avance);
                 end;

                 BEGIN
                     SELECT distinct SFRSTCR_PTRM_CODE
                     into l_ptrm_pi
                     FROM SFRSTCR a
                     WHERE 1 = 1
                     AND a.sfrstcr_pidm = alumno.svrproy_pidm
                     AND a.sfrstcr_stsp_key_sequence =alumno.sp
                     AND SUBSTR(A.sfrstcr_term_code,5,1)NOT IN(8,9)
                     AND a.sfrstcr_rsts_code ='RE'
                     AND a.sfrstcr_term_code =(select min(b.sfrstcr_term_code)
                                               from sfrstcr b
                                               where 1 = 1
                                               and a.sfrstcr_pidm = b.sfrstcr_pidm
                                               and a.sfrstcr_stsp_key_sequence =b.sfrstcr_stsp_key_sequence
                                               and a.sfrstcr_rsts_code = b.sfrstcr_rsts_code
                                               AND SUBSTR(b.sfrstcr_term_code,5,1)NOT IN(8,9)
                                               );
                                 DBMS_OUTPUT.PUT_LINE('PARTE DE PERIODO '|| l_ptrm_pi);
                 EXCEPTION WHEN OTHERS THEN
                     NULL;
                 END;

                 if l_ptrm_pi is null then

                     l_ptrm_pi:=alumno.id_periodo;

                 end if;

                 --dbms_output.put_line (' recuperar el QA cursado '||vl_qa_avance||' Programa '||alumno.ID_PROGRAMA);
          --------- Se obtiene el bimestre que se esta cursANDo ------------------------

                 vl_parte_bim :=null;

                 IF vl_parte_bim is null then
                    vl_parte_bim := vl_tipo_ini;
                 End IF;

                 IF vl_qa_avance >= 20 THEN
                    vl_qa_avance:=20;
                 END IF;

                dbms_output.put_line ('Bimestre '||l_bim||'*Parte Bimestre'||vl_parte_bim||' NIVEL:'||alumno.nivel);

                 --DBMS_OUTPUT.PUT_LINE('Entra  al 15 campus '||alumno.campus||' nivel '||alumno.nivel);

                 IF vl_parte_bim is  not null then----------> Si no existe parte de periodo no se incluye al alumno


                    --programación para Lic.
                    BEGIN

                        SELECT COUNT(*)
                        INTO l_cuenta_para_campus
                        FROM zstpara
                        WHERE 1 = 1
                        AND zstpara_mapa_id='CAMP_PRONO'
                        AND zstpara_param_id  = alumno.campus
                         AND zstpara_param_valor = alumno.nivel
                        AND zstpara_param_valor ='LI';

                    EXCEPTION WHEN OTHERS THEN
                        l_cuenta_para_campus:=0;
                    END;


                    IF l_cuenta_para_campus > 0 then

                      --  DBMS_OUTPUT.PUT_LINE('LLEna al campus');

                        BEGIN

                           l_bim :=F_CALCULA_BIM(alumno.id_ciclo,
                                                     alumno.sp,
                                                     alumno.svrproy_pidm,
                                                     vl_tip_ini,
                                                     'Q'||vl_qa_avance,
                                                     p_regla,
                                                     alumno.id_periodo,
                                                     alumno.nivel);
                          DBMS_OUTPUT.PUT_LINE('BIMESTRE ' ||L_BIM);
                        EXCEPTION WHEN OTHERS THEN
                            NULL;
                        END;

                        BEGIN

                            SELECT COUNT (DISTINCT sztasgn_qnumb)
                                INTO val_max
                            FROM sztasgn
                            WHERE  1 = 1
                            AND sztasgn_camp_code = alumno.campus
                            AND sztasgn_levl_code = alumno.nivel
                            AND sztasgn_bim_numb is not null;

                           --      DBMS_OUTPUT.PUT_LINE('Entra  al 37 val_max '||val_max);
                        EXCEPTION WHEN OTHERS THEN
                          val_max :=0;
                        END;


                        IF vl_qa_avance >= val_max then

                            vl_qa_avance:=val_max;

                        end IF;



                        DBMS_OUTPUT.PUT_LINE('Entra a Licenciatura avance v1-->'||vl_qa_avance||' bim '||l_bim||' vl_tipo_jornada '||vl_tipo_jornada||' tipo ini '||vl_tip_ini);

                         For asigna in (
                                         SELECT (sztasgn_crse_numb + sztasgn_opt_numb ) asignacion
                                         FROM sztasgn
                                         WHERE 1 = 1
                                         AND sztasgn_camp_code = alumno.campus
                                         AND sztasgn_levl_code = alumno.nivel
                                         AND sztasgn_qnumb = 'Q'||NVL(vl_qa_avance,1)
                                         AND sztasgn_bim_numb in( 'B'||l_bim)
                                         AND sztasgn_jorn_code = DECODE(vl_tipo_jornada,'N','I',vl_tipo_jornada)
                                         AND sztasgn_inso_code = vl_tip_ini
                                         AND sztasgn_camp_code != 'UVE'
                                         UNION
                                         SELECT (sztasgn_crse_numb + sztasgn_opt_numb ) asignacion
                                         FROM sztasgn
                                         WHERE 1 = 1
                                         AND sztasgn_camp_code = alumno.campus
                                         AND sztasgn_levl_code = alumno.nivel
                                         AND sztasgn_qnumb = 'Q'||NVL(vl_qa_avance,1)
--                                         AND sztasgn_bim_numb in( 'B'||l_bim)
                                         AND sztasgn_jorn_code = DECODE(vl_tipo_jornada,'N','I',vl_tipo_jornada)
                                         AND sztasgn_inso_code = 'NO'
                                         AND sztasgn_camp_code = 'UVE'

                                        ) loop
                                        --
                                            DBMS_OUTPUT.PUT_LINE('No entre en asigna');

                                             l_free :=f_conslta_freemium(alumno.svrproy_pidm);

                                             BEGIN

                                                SELECT COUNT(*)
                                                INTO l_cuenta_free
                                                FROM GORADID
                                                WHERE 1 = 1
                                                AND goradid_pidm= alumno.svrproy_pidm
                                                AND GORADID_ADID_CODE = l_free;


                                             EXCEPTION WHEN OTHERS THEN
                                                l_cuenta_free:=0;
                                             END;

                                             IF l_cuenta_free > 0 AND alumno.estatus in ('F','N') then


                                                 BEGIN

                                                    SELECT DISTINCT to_number(ZSTPARA_PARAM_VALOR)
                                                    INTO l_asigna_free
                                                    FROM zstpara
                                                    WHERE 1 = 1
                                                    AND ZSTPARA_MAPA_ID ='FREEMIUM_MAT'
                                                    AND ZSTPARA_PARAM_ID =l_free;
                                                 exception when others then
                                                    l_asigna_free:=0;
                                                 end;

                                                 asigna.asignacion:=l_asigna_free;

                                             end IF;


                                             DBMS_OUTPUT.PUT_LINE('No entre en asigna '||l_cuenta_free||' codigo '||l_free);

                                            vl_contador :=0;

                                            For materia in (

                                                            SELECT DISTINCT a.id_alumno,
                                                                            a.id_ciclo,
                                                                            a.id_programa,
                                                                            a.clave_materia_agp materia,
                                                                            a.secuencia,
                                                                            a.svrproy_pidm,--, a.ID_PERIODO,
                                                                            a.clave_materia materia_banner,
                                                                            a.fecha_inicio,
                                                                            c.study_path,
                                                                            a.rel_alumnos_x_asignar_cuatri cuatrimestre,
                                                                            c.rel_programaxalumno_estatus estatus,
                                                                            a.id_periodo ptrm
                                                            FROM rel_alumnos_x_asignar a,
                                                                 rel_programaxalumno c
                                                            WHERE 1 = 1
                                                            AND a.svrproy_pidm = alumno.svrproy_pidm
                                                            AND a.materias_excluidas = 0
                                                            AND c.sgbstdn_pidm= a.svrproy_pidm
                                                            AND a.id_periodo IS NOT NULL
                                                            AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
                                                            AND a.rel_alumnos_x_asignar_no_regla = p_regla
                                                            AND a.materias_excluidas = 0
                                                            AND  (a.svrproy_pidm, clave_materia, a.rel_alumnos_x_asignar_no_regla)  NOT IN (SELECT sztprono_pidm,
                                                                                                                                                   sztprono_materia_banner,
                                                                                                                                                   sztprono_no_regla
                                                                                                                                            FROM sztprono
                                                                                                                                            WHERE 1 = 1
                                                                                                                                            AND  sztprono_pidm =  a.svrproy_pidm
                                                                                                                                            AND  sztprono_no_regla = p_regla )
                                                            order by 1, cuatrimestre,SECUENCIA , materia
                                                            ) Loop



                                                                BEGIN

                                                                   SELECT COUNT(*)
                                                                   INTO l_cuenta_prop
                                                                   FROM sztptrm
                                                                   WHERE 1 = 1
                                                                   AND sztptrm_propedeutico = 1
                                                                   AND sztptrm_term_code =materia.id_ciclo
                                                                   AND sztptrm_ptrm_code =alumno.id_periodo
                                                                   AND sztptrm_program =materia.id_programa;

                                                                exception when others then
                                                                   null;
                                                                end;

                                                                BEGIN

                                                                    SELECT distinct SZTPTRM_MATERIA
                                                                    INTO l_curso_p
                                                                    FROM sztptrm
                                                                    WHERE 1 = 1
                                                                    AND sztptrm_propedeutico = 1
                                                                    AND sztptrm_term_code =materia.id_ciclo
                                                                    AND sztptrm_ptrm_code =alumno.id_periodo
                                                                    AND sztptrm_program =materia.id_programa;

                                                                exception when others then
                                                                   null;
                                                                end;

                                                                BEGIN

                                                                    SELECT COUNT(*)
                                                                    INTO l_cuenta_sfr
                                                                    FROM SFRSTCR
                                                                    WHERE 1 = 1
                                                                    AND sfrstcr_pidm = materia.svrproy_pidm
                                                                    AND sfrstcr_stsp_key_sequence =materia.study_path
                                                                    AND sfrstcr_rsts_code ='RE';

                                                                EXCEPTION WHEN OTHERS THEN
                                                                   NULL;
                                                                END;


                                                                -- para acreditar curso en UVE

                                                                BEGIN

                                                                   SELECT  COUNT(*)
                                                                    INTO l_cuenta_sfr_campus
                                                                    FROM SFRSTCR cr,
                                                                          ssbsect ct
                                                                    WHERE 1 = 1
                                                                    AND cr.sfrstcr_term_code = ct.ssbsect_term_code
                                                                    AND cr.sfrstcr_crn = ct.ssbsect_crn
                                                                    AND cr.sfrstcr_pidm =materia.svrproy_pidm
                                                                    AND cr.sfrstcr_stsp_key_sequence =materia.study_path
                                                                    AND cr.sfrstcr_rsts_code ='RE'
                                                                    AND CT.SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB =l_curso_p
                                                                    AND cr.SFRSTCR_GRDE_CODE in (SELECT distinct SHRGRDE_CODE
                                                                                                  FROM SHRGRDE
                                                                                                  WHERE 1 = 1
                                                                                                  AND SHRGRDE_LEVL_CODE =alumno.nivel
                                                                                                  AND SHRGRDE_PASSED_IND ='Y');

                                                                EXCEPTION WHEN OTHERS THEN
                                                                  NULL;
                                                                END;


                                                               DBMS_OUTPUT.PUT_LINE('Entra  al asma '||l_cuenta_prop||' cuenta matyerias '||l_cuenta_sfr||
                                                                                    ' cuenta campus '||l_cuenta_sfr_campus||' Sp '||materia.study_path||
                                                                                    ' Avamce '||vl_qa_avance||' l_bim: '||l_bim);

                                                                IF alumno.campus ='UVE' then

                                                                        IF l_cuenta_prop >= 1  AND materia.estatus IN('N','F'/*,'R'*/) AND l_cuenta_sfr = 0 AND l_cuenta_sfr_campus = 0 then

                                                                                vl_contador := 1;

                                                                               DBMS_OUTPUT.PUT_LINE('Entra  al asma '||l_cuenta_prop||' cuenta matyerias '||l_cuenta_sfr||' cuenta campus '||l_cuenta_sfr_campus||' Sp '||materia.study_path||' Avamce '||vl_qa_avance||' Contador '||vl_contador);

                                                                               BEGIN

                                                                                    INSERT INTO sztprono VALUES ( materia.SVRPROY_PIDM,
                                                                                                                  materia.ID_ALUMNO,
                                                                                                                  materia.ID_CICLO,
                                                                                                                  materia.ID_PROGRAMA,
                                                                                                                  l_curso_p,
                                                                                                                  vl_contador,
                                                                                                                  materia.ptrm,
                                                                                                                  l_curso_p,
                                                                                                                  'x',
                                                                                                                  materia.FECHA_INICIO,
                                                                                                                  'B'||l_bim,
                                                                                                                  NULL,
                                                                                                                  vl_avance,
                                                                                                                  P_REGLA,
                                                                                                                  USER,
                                                                                                                  materia.STUDY_PATH,
                                                                                                                  alumno.RATE,
                                                                                                                  alumno.jornada_com,
                                                                                                                  sysdate,
                                                                                                                  'Q'||vl_qa_avance,
                                                                                                                  vl_tip_ini,
                                                                                                                  vl_tipo_jornada,
                                                                                                                  'N',
                                                                                                                  'N',
                                                                                                                  materia.estatus,
                                                                                                                  'N',
                                                                                                                  null,
                                                                                                                  materia.secuencia
                                                                                                                   );
                                                                                    commit;

                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                    NULL;
                                                                                END;

                --                                                                Commit;
                                                                                exit when vl_contador=ASIGNA.ASIGNACION;


--                                                                        ELSIF l_cuenta_sfr_campus > 0 then
--
--                                                                            nulL;

                                                                        else
                                                                                vl_contador:=vl_contador+1;

                                                                                DBMS_OUTPUT.PUT_LINE('Entra  al asma '||l_cuenta_prop||' cuenta matyerias '||l_cuenta_sfr||' cuenta campus '||l_cuenta_sfr_campus||' Sp '||materia.study_path||' Avamce '||vl_qa_avance||' Contador '||vl_contador);

                                                                                BEGIN

                                                                                    INSERT INTO sztprono VALUES ( materia.SVRPROY_PIDM,
                                                                                                                  materia.ID_ALUMNO,
                                                                                                                  materia.ID_CICLO,
                                                                                                                  materia.ID_PROGRAMA,
                                                                                                                  materia.Materia,
                                                                                                                  vl_contador,
                                                                                                                  materia.ptrm,
                                                                                                                  materia.Materia_Banner,
                                                                                                                  'x',
                                                                                                                  materia.FECHA_INICIO,
                                                                                                                  'B'||l_bim,
                                                                                                                  NULL,
                                                                                                                  vl_avance,
                                                                                                                  P_REGLA,
                                                                                                                  USER,
                                                                                                                  materia.STUDY_PATH,
                                                                                                                  alumno.RATE,
                                                                                                                  alumno.jornada_com,
                                                                                                                  sysdate,
                                                                                                                  'Q'||vl_qa_avance,
                                                                                                                  vl_tip_ini,
                                                                                                                  vl_tipo_jornada,
                                                                                                                  'N',
                                                                                                                  'N',
                                                                                                                  materia.estatus,
                                                                                                                  'N',
                                                                                                                  null,
                                                                                                                  materia.secuencia
                                                                                                                   );
                                                                                    commit;

                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                    NULL;
                                                                                END;
                --                                                                Commit;
                                                                                exit when vl_contador=ASIGNA.ASIGNACION;

                                                                        end IF;


                                                                ELSE
                                                                                    DBMS_OUTPUT.PUT_LINE('PROPEDEUTICO ' ||l_cuenta_prop || 'MATERIA ESTATUS ' ||materia.estatus|| 'CUENTA SFR '||l_cuenta_sfr);
                                                                        IF l_cuenta_prop >= 1 /*AND vl_qa_avance =1*/ AND materia.estatus IN('N','F') AND l_cuenta_sfr = 0 then

                                                                                vl_contador := 1;


                                                                                BEGIN
                                                                                         DBMS_OUTPUT.PUT_LINE('ENTRA INSERTA');
                                                                                    INSERT INTO sztprono VALUES ( materia.SVRPROY_PIDM,
                                                                                                                  materia.ID_ALUMNO,
                                                                                                                  materia.ID_CICLO,
                                                                                                                  materia.ID_PROGRAMA,
                                                                                                                  l_curso_p,
                                                                                                                  vl_contador,
                                                                                                                  materia.ptrm,
                                                                                                                  l_curso_p,
                                                                                                                  'x',
                                                                                                                  materia.FECHA_INICIO,
                                                                                                                  'B'||l_bim,
                                                                                                                  NULL,
                                                                                                                  vl_avance,
                                                                                                                  P_REGLA,
                                                                                                                  USER,
                                                                                                                  materia.STUDY_PATH,
                                                                                                                  alumno.RATE,
                                                                                                                  alumno.jornada_com,
                                                                                                                  sysdate,
                                                                                                                  'Q'||vl_qa_avance,
                                                                                                                  vl_tip_ini,
                                                                                                                  vl_tipo_jornada,
                                                                                                                  'N',
                                                                                                                  'N',
                                                                                                                  materia.estatus,
                                                                                                                  'N',
                                                                                                                  null,
                                                                                                                  materia.secuencia
                                                                                                                   );
                                                                                    commit;

                                                                                EXCEPTION WHEN OTHERS THEN
                                                                                    dbms_output.put_line('Valor '||vl_contador||' Asigna '||ASIGNA.ASIGNACION||' '||sqlerrm);
                                                                                END;

                                                                                dbms_output.put_line('Valor '||vl_contador||' Asigna '||ASIGNA.ASIGNACION);

                                                                                Commit;

                                                                                exit when vl_contador=ASIGNA.ASIGNACION;

                                                                        else

                                                                             DBMS_OUTPUT.PUT_LINE('ENTRA  2 ');
                                                                           --IF l_cuenta_eje = 0 then

                                                                                vl_contador := vl_contador +1;

                                                                            --end IF;


                                                                            BEGIN

                                                                                SELECT nvl(max(sztprono_secuencia),0)+1
                                                                                INTO l_secuencia
                                                                                FROM sztprono
                                                                                WHERE 1 = 1
                                                                                AND sztprono_no_regla = P_REGLA
                                                                                AND sztprono_pidm = materia.SVRPROY_PIDM;

                                                                            exception when others then
                                                                                null;
                                                                            end;


                                                                            BEGIN
                                                                                      DBMS_OUTPUT.PUT_LINE('ENTRA  INSERTA 2 ');
                                                                                INSERT INTO sztprono VALUES ( materia.SVRPROY_PIDM,
                                                                                                              materia.ID_ALUMNO,
                                                                                                              materia.ID_CICLO,
                                                                                                              materia.ID_PROGRAMA,
                                                                                                              materia.Materia,
                                                                                                              l_secuencia,
                                                                                                              materia.ptrm,
                                                                                                              materia.Materia_Banner,
                                                                                                              'x',
                                                                                                              materia.FECHA_INICIO,
                                                                                                              'B'||l_bim,
                                                                                                              NULL,
                                                                                                              vl_avance,
                                                                                                              P_REGLA,
                                                                                                              USER,
                                                                                                              materia.STUDY_PATH,
                                                                                                              alumno.RATE,
                                                                                                              alumno.jornada_com,
                                                                                                              sysdate,
                                                                                                              'Q'||vl_qa_avance,
                                                                                                              vl_tip_ini,
                                                                                                              vl_tipo_jornada,
                                                                                                              'N',
                                                                                                              'N',
                                                                                                              materia.estatus,
                                                                                                              'N',
                                                                                                              null,
                                                                                                              materia.secuencia
                                                                                                               );

                                                                            EXCEPTION WHEN OTHERS THEN
                                                                                dbms_output.put_line('Error -->'||sqlerrm);
                                                                              --  raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);
                                                                            END;

                                                                            commit;



                                                                                exit when vl_contador = ASIGNA.ASIGNACION;

                                                                        end IF;

                                                                end IF;

                                                                Commit;

                                                            END LOOP materia;

                                                            DBMS_OUTPUT.PUT_LINE('entra a asgn '||vl_contador||' Asignacion '||ASIGNA.ASIGNACION);

                                                            vl_contador:=0;
                                                            ASIGNA.ASIGNACION:=0;


                                        END LOOP asigna;

                    end IF;

                    l_cuenta_para_campus:=null;

                    BEGIN

                        SELECT COUNT(*)
                        INTO l_cuenta_para_campus
                        FROM zstpara
                        WHERE 1 = 1
                        AND zstpara_mapa_id='CAMP_PRONO'
                        AND zstpara_param_id  = alumno.campus
                        AND zstpara_param_valor = alumno.nivel
                        AND zstpara_param_valor in('MA','MS','DO');

                    EXCEPTION WHEN OTHERS THEN
                        l_cuenta_para_campus:=0;
                    END;

                dbms_output.put_line ('CAMPUS MA MS DO  CUENTA_PARA_CAMPUS'||l_cuenta_para_campus||
                                      ' - '||alumno.campus||' - '||alumno.nivel  );

                    IF l_cuenta_para_campus > 0 THEN

                        DBMS_OUTPUT.PUT_LINE('Entra a maestria 2588'||' alumno.periodicidad:'||alumno.periodicidad);
                       -- dbms_output.put_line('Avance '||vl_qa_avance);

                        vl_asignacion := 0;
                        val_max :=0;

                        l_ptrm_pi:=NULL;

                        BEGIN

--                            select CASE WHEN ptrm_pi ='A4B' THEN 'A0B'
--                                        WHEN ptrm_pi ='M4B' THEN 'M0B'
--                                        WHEN ptrm_pi ='A4D' THEN 'A1A'
--                                        WHEN ptrm_pi ='M4D' THEN 'M1A'
--                                        WHEN ptrm_pi ='A3C' THEN 'A0C'
--                                        WHEN ptrm_pi ='M3C' THEN 'M0C'
--                                        WHEN ptrm_pi ='A3A' THEN 'A0A'
--                                        WHEN ptrm_pi ='M3A' THEN 'M0A'
--                                        WHEN ptrm_pi ='A3B' THEN 'A0B'
--                                        WHEN ptrm_pi ='M3B' THEN 'M0B'
--                                        WHEN ptrm_pi ='A3D' THEN 'A1A'
--                                        WHEN ptrm_pi ='M3D' THEN 'M1A'
--                                   ELSE
--                                         ptrm_pi
--                                   END ptrm_pi
--                            into l_ptrm_pi
--                            from
--                            (
--                                SELECT distinct min(SFRSTCR_PTRM_CODE) ptrm_pi
--                                FROM SFRSTCR a
--                                WHERE 1 = 1
--                                AND a.sfrstcr_pidm = alumno.svrproy_pidm
--                                AND a.sfrstcr_stsp_key_sequence =alumno.sp
--                                AND SUBSTR(A.sfrstcr_term_code,5,1)NOT IN(8,9)
--                                AND a.sfrstcr_rsts_code ='RE'
--                                AND sfrstcr_term_code =(select min(b.sfrstcr_term_code)
--                                                        from sfrstcr b
--                                                        where 1 = 1
--                                                        and a.sfrstcr_pidm = b.sfrstcr_pidm
--                                                        and a.sfrstcr_stsp_key_sequence =b.sfrstcr_stsp_key_sequence
--                                                        and a.sfrstcr_rsts_code = b.sfrstcr_rsts_code
--                                                        )
--                               AND a.sfrstcr_ptrm_code = (SELECT min (d1.sfrstcr_ptrm_code)
--                                                          FROM sfrstcr D1
--                                                          WHERE 1=1
--                                                          AND a.sfrstcr_pidm = d1.sfrstcr_pidm
--                                                           AND a.sfrstcr_term_code = d1.sfrstcr_term_code
--                                                          AND a.sfrstcr_rsts_code = d1.sfrstcr_rsts_code
--                                                           )
--                             );

                            select DISTINCT ptrm_pi
                            into l_ptrm_pi
                            from
                            (
                                    select CASE WHEN ptrm_pi ='A4B' THEN 'A0B'
                                                                    WHEN ptrm_pi ='M4B' THEN 'M0B'
                                                                    WHEN ptrm_pi ='A4D' THEN 'A1A'
                                                                    WHEN ptrm_pi ='M4D' THEN 'M1A'
                                                                    WHEN ptrm_pi ='A3C' THEN 'A0C'
                                                                    WHEN ptrm_pi ='M3C' THEN 'M0C'
                                                                    WHEN ptrm_pi ='A3A' THEN 'A0A'
                                                                    WHEN ptrm_pi ='M3A' THEN 'M0A'
                                                                    WHEN ptrm_pi ='A3B' THEN 'A0B'
                                                                    WHEN ptrm_pi ='M3B' THEN 'M0B'
                                                                    WHEN ptrm_pi ='A3D' THEN 'A1A'
                                                                    WHEN ptrm_pi ='M3D' THEN 'M1A'
                                                               ELSE
                                                                     ptrm_pi
                                                               END ptrm_pi,
                                                               fecha
                            --                            into l_ptrm_pi
                                                        from
                                                        (
                                                            SELECT distinct SFRSTCR_PTRM_CODE ptrm_pi,SFRSTCR_ACTIVITY_DATE fecha
                                                            FROM SFRSTCR a
                                                            WHERE 1 = 1
                                                            AND a.sfrstcr_pidm = alumno.svrproy_pidm
                                                            AND a.sfrstcr_stsp_key_sequence =alumno.sp
                                                            AND SUBSTR(A.sfrstcr_term_code,5,1)NOT IN(8,9)
                                                            AND a.sfrstcr_rsts_code ='RE'
                                                            AND sfrstcr_term_code =(select min(b.sfrstcr_term_code)
                                                                                    from sfrstcr b
                                                                                    where 1 = 1
                                                                                    and a.sfrstcr_pidm = b.sfrstcr_pidm
                                                                                    and a.sfrstcr_stsp_key_sequence =b.sfrstcr_stsp_key_sequence
                                                                                    and a.sfrstcr_rsts_code = b.sfrstcr_rsts_code
                                                                                    )
                                                           AND a.sfrstcr_ptrm_code = (SELECT min (d1.sfrstcr_ptrm_code)
                                                                                      FROM sfrstcr D1
                                                                                      WHERE 1=1
                                                                                      AND a.sfrstcr_pidm = d1.sfrstcr_pidm
                                                                                      AND a.sfrstcr_term_code = d1.sfrstcr_term_code
                                                                                      AND a.sfrstcr_rsts_code = d1.sfrstcr_rsts_code
                                                                                       )
                                                         )
                            )where 1 = 1
                            and fecha = (select min(fecha)
                                        from
                                        (
                                                select CASE WHEN ptrm_pi ='A4B' THEN 'A0B'
                                                                                WHEN ptrm_pi ='M4B' THEN 'M0B'
                                                                                WHEN ptrm_pi ='A4D' THEN 'A1A'
                                                                                WHEN ptrm_pi ='M4D' THEN 'M1A'
                                                                                WHEN ptrm_pi ='A3C' THEN 'A0C'
                                                                                WHEN ptrm_pi ='M3C' THEN 'M0C'
                                                                                WHEN ptrm_pi ='A3A' THEN 'A0A'
                                                                                WHEN ptrm_pi ='M3A' THEN 'M0A'
                                                                                WHEN ptrm_pi ='A3B' THEN 'A0B'
                                                                                WHEN ptrm_pi ='M3B' THEN 'M0B'
                                                                                WHEN ptrm_pi ='A3D' THEN 'A1A'
                                                                                WHEN ptrm_pi ='M3D' THEN 'M1A'
                                                                           ELSE
                                                                                 ptrm_pi
                                                                           END ptrm_pi,
                                                                           fecha
                                                                    from
                                                                    (
                                                                        SELECT distinct SFRSTCR_PTRM_CODE ptrm_pi,SFRSTCR_ACTIVITY_DATE fecha
                                                                        FROM SFRSTCR a
                                                                        WHERE 1 = 1
                                                                        AND a.sfrstcr_pidm = alumno.svrproy_pidm
                                                                        AND a.sfrstcr_stsp_key_sequence =alumno.sp
                                                                        AND SUBSTR(A.sfrstcr_term_code,5,1)NOT IN(8,9)
                                                                        AND sfrstcr_term_code =(select min(b.sfrstcr_term_code)
                                                                                                from sfrstcr b
                                                                                                where 1 = 1
                                                                                                and a.sfrstcr_pidm = b.sfrstcr_pidm
                                                                                                and a.sfrstcr_stsp_key_sequence =b.sfrstcr_stsp_key_sequence
                                                                                                and a.sfrstcr_rsts_code = b.sfrstcr_rsts_code
                                                                                                )
                                                                       AND a.sfrstcr_ptrm_code = (SELECT min (d1.sfrstcr_ptrm_code)
                                                                                                  FROM sfrstcr D1
                                                                                                  WHERE 1=1
                                                                                                  AND a.sfrstcr_pidm = d1.sfrstcr_pidm
                                                                                                  AND a.sfrstcr_term_code = d1.sfrstcr_term_code
                                                                                                  AND a.sfrstcr_rsts_code = d1.sfrstcr_rsts_code
                                                                                                   )
                                                                     )
                                        )where 1 = 1);
                        EXCEPTION WHEN OTHERS THEN
                           l_ptrm_pi:=alumno.ID_PERIODO;
                        END;


                        IF alumno.periodicidad = 1 THEN

                         --  DBMS_OUTPUT.PUT_LINE('Entra  al 36 2685 '||l_ptrm_pi);

                           dbms_output.put_line ('Periodosss '||alumno.id_ciclo||' Sp '||alumno.sp||' Pidm '||alumno.svrproy_pidm||' Tipo de Inicio '||vl_tip_ini||
                           ' Avance '||vl_qa_avance||' REGLA '||p_regla||alumno.ID_PERIODO||' l_ptrm_pi '||l_ptrm_pi||' AVANCE'||alumno.nivel);

                          l_bim:=null;

                           BEGIN

                               l_bim :=F_CALCULA_BIM(alumno.id_ciclo,
                                                     alumno.sp,
                                                     alumno.svrproy_pidm,
                                                     vl_tip_ini,
                                                     'Q'||vl_qa_avance,
                                                     p_regla,
                                                     alumno.ID_PERIODO,
                                                     alumno.nivel);
                           EXCEPTION WHEN OTHERS THEN
                               NULL;
                           END;

                            --raise_application_error (-20002,'Ciclo '||alumno.id_ciclo||' Sp '||alumno.sp||' Pidm '|| alumno.svrproy_pidm||' Tipo Ini '||vl_tip_ini||' Avance '||'Q'||vl_qa_avance||' Regla '||p_regla||' Pi '||l_ptrm_pi||' Nivel '||alumno.nivel);

                           DBMS_OUTPUT.PUT_LINE('Bimbo '||l_bim||' Matricula '||alumno.ID_ALUMNO);


                             BEGIN

                                 SELECT COUNT (DISTINCT sztasma_qnumb)
                                     INTO val_max
                                 FROM sztasma
                                 WHERE  1 = 1
                                 AND sztasma_camp_code = alumno.campus
                                 AND sztasma_levl_code = alumno.nivel
                                 AND sztasma_bim_numb is not null;

                                  --    DBMS_OUTPUT.PUT_LINE('Entra  al 37 val_max '||val_max||' campus '||alumno.campus||' Nivel '|| alumno.nivel);
                             EXCEPTION WHEN OTHERS THEN
                               val_max :=0;
                             END;

                             --DBMS_OUTPUT.PUT_LINE('Entra  al 38 vl_qa_avance '||vl_qa_avance||' tipo inicio '||vl_tip_ini);

                             IF vl_parte_bim = 4 THEN

                               vl_parte_bim:=2;

                             END IF;


                        ELSIF alumno.periodicidad = 2 THEN

                         -- dbms_output.put_line ('salida2 '||alumno.campus ||'*'||alumno.NIVEL||'*'||'Q'||vl_qa_avance||'*'||'B'||vl_parte_bim||'*--> '||vl_tip_ini);

                          --DBMS_OUTPUT.PUT_LINE('Entra  al 40 ');

                             BEGIN

                                 SELECT COUNT (DISTINCT sztasma_qnumb)
                                 INTO val_max
                                 FROM sztasma
                                 WHERE sztasma_camp_code = alumno.campus
                                 AND sztasma_levl_code = alumno.nivel
                                 AND sztasma_bim_numb is  null;

                                  --    DBMS_OUTPUT.PUT_LINE('Entra  al 41 val_max '||val_max);
                             EXCEPTION WHEN OTHERS THEN
                               val_max :=0;
                             END;

                             BEGIN

                                l_bim :=F_CALCULA_BIM(alumno.id_ciclo,
                                                           alumno.sp,
                                                           alumno.svrproy_pidm,
                                                           vl_tip_ini,
                                                           'Q'||vl_qa_avance,
                                                           p_regla,
                                                           l_ptrm_pi,
                                                           alumno.nivel);

                             EXCEPTION WHEN OTHERS THEN
                                 NULL;
                             END;

                             IF alumno.campus ='UMM' THEN

                                  vl_asignacion :=3;

                             END IF;



                        end IF;

                         vl_contador :=0;
                                   --  DBMS_OUTPUT.PUT_LINE('Entra  al 44 aqui avance '||vl_qa_avance||','||l_bim);
                                       For materia in (
                                                       SELECT DISTINCT a.id_alumno,
                                                                       a.id_ciclo,
                                                                       a.id_programa,
                                                                       a.clave_materia_agp materia,
                                                                       a.secuencia,
                                                                       a.svrproy_pidm,--, a.ID_PERIODO,
                                                                       a.clave_materia materia_banner,
                                                                       a.fecha_inicio,
                                                                       c.study_path,
                                                                       a.rel_alumnos_x_asignar_cuatri cuatrimestre,
                                                                       rel_programaxalumno_estatus estatus
                                                       FROM rel_alumnos_x_asignar a,
                                                            rel_programaxalumno c
                                                       WHERE 1 = 1
                                                       AND a.svrproy_pidm = alumno.svrproy_pidm
                                                       AND a.materias_excluidas = 0
                                                       AND c.sgbstdn_pidm= a.svrproy_pidm
                                                       AND a.id_periodo is not null
                                                       AND A.STUDY_PATH=C.STUDY_PATH
                                                       AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
                                                       AND a.rel_alumnos_x_asignar_no_regla = p_regla
--                                                       AND a.ID_ALUMNO='010331823'
                                                       ORDER BY 1, cuatrimestre ,secuencia , materia

                                          ) LOOP

                                                 DBMS_OUTPUT.PUT_LINE('Entra  al 44 aqui avance '||vl_qa_avance||','||l_bim);

                                                  BEGIN

                                                      SELECT COUNT(*)
                                                      INTO l_cuenta_eje
                                                      FROM ZSTPARA
                                                      WHERE 1 = 1
                                                      AND ZSTPARA_MAPA_ID = 'MATERIAS_IEBS'
                                                      AND ZSTPARA_PARAM_ID = materia.Materia;

                                                  exception when others then
                                                      null;
                                                  end;

                                                  IF l_cuenta_eje = 0 then

                                                    vl_contador := vl_contador +1;
                                                    dbms_output.put_line ('Contador  ' || vl_contador);
                                                    DBMS_OUTPUT.PUT_LINE('Entra  al 45 estatus '||materia.estatus);

                                                  end IF;

                                                 BEGIN

                                                     SELECT nvl(max(sztprono_secuencia),0)+1
                                                     INTO l_secuencia
                                                     FROM sztprono
                                                     WHERE 1 = 1
                                                     AND sztprono_no_regla = P_REGLA
                                                     AND sztprono_pidm = materia.SVRPROY_PIDM;

                                                 exception when others then
                                                     null;
                                                 end;

                                                 BEGIN

                                                    SELECT COUNT(*)
                                                    INTO l_cuenta_asma
                                                    FROM ZSTPARA
                                                    WHERE 1 = 1
                                                    AND zstpara_mapa_id ='ASMA_MAT'
                                                    AND zstpara_param_desc ='Q'||vl_qa_avance
                                                    AND zstpara_param_id = materia.id_programa;

                                                 EXCEPTION WHEN OTHERS THEN
                                                    NULL;
                                                 END;

                                                  DBMS_OUTPUT.PUT_LINE('Cuenta asma '||l_cuenta_asma);

                                                 IF l_cuenta_asma > 0 THEN

                                                     BEGIN

                                                        SELECT DISTINCT zstpara_param_valor
                                                        INTO vl_asignacion
                                                        FROM zstpara
                                                        WHERE 1 = 1
                                                        AND zstpara_mapa_id ='ASMA_MAT'
                                                        AND zstpara_param_desc ='Q'||vl_qa_avance
                                                        AND zstpara_param_id = materia.id_programa;

                                                     EXCEPTION WHEN OTHERS THEN
                                                        NULL;
                                                     END;

                                                 ELSE

                                                    BEGIN

                                                        SELECT COUNT(*)
                                                        INTO l_cuenta_asma
                                                        FROM sztasma
                                                        WHERE 1 = 1
                                                        AND SZTASMA_CAMP_CODE = alumno.campus
                                                        AND SZTASMA_LEVL_CODE = alumno.nivel
                                                        AND SZTASMA_PROGRAMA =materia.id_programa
                                                        AND SZTASMA_PTRM_CODE = l_ptrm_pi;

                                                    exception when others then
                                                        l_cuenta_asma:=0;
                                                    end;


                                                    DBMS_OUTPUT.PUT_LINE('Cuenta asma '||l_cuenta_asma||' avance '||vl_qa_avance);


                                                    IF l_cuenta_asma > 0  AND vl_qa_avance > 5 then

                                                        DBMS_OUTPUT.PUT_LINE('Entra  a asma xx1 '||l_cuenta_asma);



                                                        BEGIN
                                                              SELECT distinct (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                              INTO vl_asignacion
                                                              FROM sztasma
                                                              WHERE sztasma_camp_code = alumno.campus
                                                              AND sztasma_levl_code = alumno.nivel
                                                              AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                              AND sztasma_bim_numb IS NULL
                                                              AND sztasma_inso_code = vl_tip_ini
                                                              AND SZTASMA_PROGRAMA =materia.id_programa
                                                              AND SZTASMA_PTRM_CODE = l_ptrm_pi;

                                                              DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion uno '||vl_asignacion);
                                                        EXCEPTION WHEN OTHERS THEN
                                                            vl_asignacion :=0;

                                                             IF alumno.campus ='UMM' THEN
                                                                 vl_asignacion :=3;
                                                             END IF;

                                                        END;

                                                         --cuANDo pasa del maximo q
                                                       IF vl_qa_avance   >= val_max then

                                                          vl_asignacion:=4;

                                                       end IF;

                                                       IF vl_asignacion  IS NULL OR vl_asignacion = 0 THEN

                                                           vl_asignacion:=2;

                                                       END IF;

                                                       DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion dos '||vl_asignacion);

                                                    else

                                                       DBMS_OUTPUT.PUT_LINE('Entra  a asma xx2 '||l_cuenta_asma);

                                                       IF alumno.periodicidad = 1 THEN

                                                            DBMS_OUTPUT.PUT_LINE('VALIDACION PARA CONFIGURACION POR BIMESTRE 2837');

                                                            -- VALIDACION PARA CONFIGURACION POR BIMESTRE Y DISTINCION POR ASMA

                                                            IF alumno.id_programa in ('UTLMADVFED','UTSMSVBNAS','UTLMAAIFED','UTSMSAINAS') then

                                                                l_bim:=2;

                                                            end IF;

                                                            l_valida_asma:=0;

                                                            BEGIN
                                                                  SELECT COUNT(*)
                                                                  INTO l_valida_asma
                                                                  FROM sztasma
                                                                  WHERE sztasma_camp_code = alumno.campus
                                                                  AND sztasma_levl_code = alumno.nivel
                                                                  AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                                  AND sztasma_bim_numb ='B'||l_bim
                                                                  AND sztasma_inso_code = vl_tip_ini
                                                                  AND SZTASMA_PROGRAMA = materia.id_programa
                                                                  AND SZTASMA_PTRM_CODE = l_ptrm_pi;

                                                                  DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion OCHO '||vl_asignacion);
                                                            EXCEPTION WHEN OTHERS THEN
                                                                null;

                                                            END;

                                                            DBMS_OUTPUT.PUT_LINE(' valida asma '||l_valida_asma||' campus  '||alumno.campus||' nivel  '||alumno.nivel||' avance '||vl_qa_avance||' Bim '||l_bim||' Tipo Ini  '||vl_tip_ini||' Ptrm '||alumno.ID_PERIODO);

                                                            IF l_valida_asma = 0 then



                                                                     BEGIN
                                                                          SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                                          INTO vl_asignacion
                                                                          FROM sztasma
                                                                          WHERE sztasma_camp_code = alumno.campus
                                                                          AND sztasma_levl_code = alumno.nivel
                                                                          AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                                          AND sztasma_bim_numb = 'B'||l_bim
                                                                          AND sztasma_inso_code = vl_tip_ini
                                                                          and SZTASMA_PTRM_CODE = alumno.ID_PERIODO
                                                                          AND SZTASMA_PROGRAMA IS NULL;

                                                                     EXCEPTION WHEN OTHERS THEN
                                                                         vl_asignacion :=0;

                                                                          IF alumno.campus ='UMM' THEN
                                                                              vl_asignacion :=3;

                                                                          END IF;

                                                                     END;

                                                                     DBMS_OUTPUT.PUT_LINE(' ENTRA 1  en este lugar vl_tip_ini '||vl_tip_ini||' l_ptrm_pi '||l_ptrm_pi||' vl_asignacion '||vl_asignacion);

                                                                     if vl_qa_avance > 5 then

                                                                        vl_asignacion:=2;

                                                                     end if;

                                                                     --cuANDo pasa del maximo q
                                                                     IF vl_qa_avance   >= val_max then

                                                                        vl_asignacion:=4;

                                                                     end IF;

                                                                     DBMS_OUTPUT.PUT_LINE(' ENTRA campus  '||alumno.campus||' total materias '||vl_asignacion);

                                                                     IF alumno.campus ='INC' then
                                                                        vl_asignacion :=2;
                                                                      end IF;

                                                            elsIF l_valida_asma > 0 then

                                                            DBMS_OUTPUT.PUT_LINE('Entra 2');

                                                                -- REVISIAR CON ALDO POR QUE NO ESTABA CON LA CONFIGURACION M1A 010047009
                                                                 BEGIN
                                                                      SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                                      INTO vl_asignacion
                                                                      FROM sztasma
                                                                      WHERE sztasma_camp_code = alumno.campus
                                                                      AND sztasma_levl_code = alumno.nivel
                                                                      AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                                      AND sztasma_bim_numb ='B'||l_bim
                                                                      AND sztasma_inso_code = vl_tip_ini
                                                                      AND SZTASMA_PROGRAMA = materia.id_programa
                                                                      AND SZTASMA_PTRM_CODE = l_ptrm_pi;

                                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion tres '||vl_asignacion);
                                                                 EXCEPTION WHEN OTHERS THEN
                                                                     vl_asignacion :=0;

                                                                      IF alumno.campus ='UMM' THEN
                                                                          vl_asignacion :=3;
                                                                      END IF;

                                                                 END;

                                                            end IF;

                                                             DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion||'2868');

                                                       ELSE
                                                            DBMS_OUTPUT.PUT_LINE('Entra  al 43 tipo ini  '||vl_tip_ini||' Programa '||materia.id_programa);

                                                            IF alumno.nivel ='DO' then

                                                                DBMS_OUTPUT.PUT_LINE('Entra  a Doctorado campus '||alumno.campus||' Nivel '||alumno.nivel||' Avance '||vl_qa_avance||' ini '||vl_tip_ini||' programa '||materia.id_programa);


                                                                 BEGIN
                                                                      SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                                      INTO vl_asignacion
                                                                      FROM sztasma
                                                                      WHERE sztasma_camp_code = alumno.campus
                                                                      AND sztasma_levl_code = alumno.nivel
                                                                      AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                                      AND sztasma_bim_numb IS NULL
                                                                      AND sztasma_inso_code = vl_tip_ini;
                                                                    --  AND SZTASMA_PROGRAMA = materia.id_programa
                                                                     -- AND SZTASMA_PTRM_CODE = alumno.ID_PERIODO;

                                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion cuatro '||vl_asignacion);
                                                                 EXCEPTION WHEN OTHERS THEN
                                                                     vl_asignacion :=0;

                                                                      IF alumno.campus ='UMM' THEN
                                                                          vl_asignacion :=3;
                                                                      END IF;

                                                                 END;
--
                                                                 dbms_output.put_line('Excepciones '||vl_qa_avance||' maximo '||val_max);

                                                                 IF vl_qa_avance   >= val_max then

                                                                    vl_asignacion:=4;

                                                                 end IF;

                                                            else

                                                                 BEGIN
                                                                      SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                                      INTO vl_asignacion
                                                                      FROM sztasma
                                                                      WHERE sztasma_camp_code = alumno.campus
                                                                      AND sztasma_levl_code = alumno.nivel
                                                                      AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                                      AND sztasma_bim_numb IS NULL
                                                                      AND sztasma_inso_code = vl_tip_ini
                                                                      and SZTASMA_PTRM_CODE = alumno.ID_PERIODO
                                                                      AND SZTASMA_PROGRAMA IS NULL;

                                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion cinco '||vl_asignacion);
                                                                 EXCEPTION WHEN OTHERS THEN
                                                                     vl_asignacion :=0;

                                                                      IF alumno.campus IN ('UMM','UIN') THEN
                                                                          vl_asignacion :=3;
                                                                      END IF;

                                                                 END;

                                                                 --cuANDo pasa del maximo q
                                                                 dbms_output.put_line('Excepciones '||vl_qa_avance||' maximo '||val_max);

                                                                 IF vl_qa_avance   >= val_max then

                                                                    vl_asignacion:=4;

                                                                 end IF;

                                                             end IF;

                                                             DBMS_OUTPUT.PUT_LINE('Asignacion '||vl_asignacion);

                                                        END IF;

                                                    end IF;


                                                 END IF;

                                                 DBMS_OUTPUT.PUT_LINE('Periodicidad '||alumno.PERIODICIDAD||' Periodo 2'||alumno.ID_PERIODO);

                                                 BEGIN

                                                    SELECT COUNT(*)
                                                    INTO l_cuenta_prop
                                                    FROM sztptrm
                                                    WHERE 1 = 1
                                                    AND sztptrm_propedeutico = 1
                                                    AND sztptrm_term_code =materia.id_ciclo
                                                    AND sztptrm_ptrm_code =alumno.id_periodo
                                                    AND sztptrm_program =materia.id_programa;

                                                 exception when others then
                                                    null;
                                                 end;

                                                 DBMS_OUTPUT.PUT_LINE('Periodo '||materia.ID_CICLO||' Ptrm '||alumno.ID_PERIODO||' Programa '||materia.ID_PROGRAMA||' Matricula '||materia.ID_ALUMNO||' Prope '||l_cuenta_prop);
                                                 --macana1

                                                 BEGIN

                                                    SELECT COUNT(*)
                                                    INTO l_cuenta_sfr
                                                    FROM SFRSTCR
                                                    WHERE 1 = 1
                                                    AND sfrstcr_pidm = materia.svrproy_pidm
                                                    AND sfrstcr_stsp_key_sequence =materia.study_path
                                                    AND sfrstcr_rsts_code ='RE';

                                                 EXCEPTION WHEN OTHERS THEN
                                                    NULL;
                                                 END;

                                                 DBMS_OUTPUT.PUT_LINE('Entra  al asma '||l_cuenta_prop||' cuenta matyerias '||l_cuenta_sfr||' Avance '||vl_qa_avance||' l_bim:'||l_bim);

                                                IF l_cuenta_prop >= 1 /*AND vl_qa_avance =1*/ AND materia.estatus IN('N','F','R') AND l_cuenta_sfr = 0 then

                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 47000 '||l_cuenta_prop);

                                                      BEGIN
                                                                  INSERT INTO sztprono VALUES ( materia.svrproy_pidm,
                                                                                                materia.id_alumno,
                                                                                                materia.id_ciclo,
                                                                                                materia.id_programa,
                                                                                                'M1HB401',
                                                                                                vl_contador,
                                                                                                alumno.id_periodo,
                                                                                                'M1HB401',
                                                                                                'x',
                                                                                                materia.fecha_inicio,
                                                                                                'B'||l_bim,
                                                                                                null,
                                                                                                vl_avance,
                                                                                                p_regla,
                                                                                                user,
                                                                                                materia.study_path,
                                                                                                alumno.rate,
                                                                                                alumno.jornada_com,
                                                                                                sysdate,
                                                                                                'Q'||vl_qa_avance,
                                                                                                vl_tip_ini,
                                                                                                vl_tipo_jornada,
                                                                                                'N',
                                                                                                'N',
                                                                                                materia.estatus,
                                                                                                'N',
                                                                                                null,
                                                                                                materia.secuencia
                                                                                                );

                                                      EXCEPTION WHEN OTHERS THEN
                                                         NULL;
                                                      END;

                                                    EXIT WHEN vl_contador=1;

                                                ELSE

                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 48000 '||l_cuenta_prop);


                                                      BEGIN
                                                                  INSERT INTO sztprono VALUES ( materia.svrproy_pidm,
                                                                                                materia.id_alumno,
                                                                                                materia.id_ciclo,
                                                                                                materia.id_programa,
                                                                                                materia.materia,
                                                                                                l_secuencia,
                                                                                                alumno.id_periodo,
                                                                                                materia.materia_banner,
                                                                                                'x',
                                                                                                materia.fecha_inicio,
                                                                                                'B'||l_bim,
                                                                                                null,
                                                                                                vl_avance,
                                                                                                p_regla,
                                                                                                user,
                                                                                                materia.study_path,
                                                                                                alumno.rate,
                                                                                                alumno.jornada_com,
                                                                                                sysdate,
                                                                                                'Q'||vl_qa_avance,
                                                                                                vl_tip_ini,
                                                                                                vl_tipo_jornada,
                                                                                                'N',
                                                                                                'N',
                                                                                                materia.estatus,
                                                                                                'N',
                                                                                                null,
                                                                                                materia.secuencia
                                                                                                );

--                                                        commit;
                                                      EXCEPTION  WHEN OTHERS THEN
                                                         NULL;
                                                      END;


                                                      DBMS_OUTPUT.PUT_LINE('Macana Semis '||l_semis||' Programa  '||materia.ID_PROGRAMA||' Ptrm'||alumno.ID_PERIODO||' Contador '||vl_contador||' Asignacion '||vl_asignacion);

                                                      COMMIT;


                                                    EXIT WHEN vl_contador>=vl_asignacion;

                                                END IF;
                                                 --bANDa


                                          END LOOP Materia;
                                          vl_contador :=0;
                                          l_bim:=null;

                            dbms_output.put_line ('Entra a Maestria Parte de bimestre ' ||vl_parte_bim);

                    END IF;


                    l_cuenta_para_campus:=null;

                    BEGIN

                        SELECT COUNT(*)
                        INTO l_cuenta_para_campus
                        FROM zstpara
                        WHERE 1 = 1
                        AND zstpara_mapa_id='CAMP_PRONO'
                        AND zstpara_param_id  = alumno.campus
                        AND zstpara_param_valor = alumno.nivel
                        AND zstpara_param_valor in('EC','ID');

                    EXCEPTION WHEN OTHERS THEN
                        l_cuenta_para_campus:=0;
                    END;

                    IF l_cuenta_para_campus > 0 THEN

                         dbms_output.put_line ('Entra a Ec');

                         vl_contador :=0;

                         For materia in (
                                         SELECT DISTINCT a.id_alumno,
                                                         a.id_ciclo,
                                                         a.id_programa,
                                                         a.clave_materia_agp materia,
                                                         a.secuencia,
                                                         a.svrproy_pidm,--, a.ID_PERIODO,
                                                         a.clave_materia materia_banner,
                                                         a.fecha_inicio,
                                                         c.study_path,
                                                         a.rel_alumnos_x_asignar_cuatri cuatrimestre,
                                                         rel_programaxalumno_estatus estatus,
                                                         a.ID_PERIODO,
                                                         C.FECHA_INICIO fecha_inicio_2
                                         FROM rel_alumnos_x_asignar a,
                                              rel_programaxalumno c
                                         WHERE 1 = 1
                                         AND a.svrproy_pidm = alumno.svrproy_pidm
                                         AND a.materias_excluidas = 0
                                         AND c.sgbstdn_pidm= a.svrproy_pidm
                                         AND a.id_periodo is not null
                                         and a.ID_PROGRAMA=c.PROGRAMA
                                         AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
                                         AND a.rel_alumnos_x_asignar_no_regla = p_regla
            --                             AND a.ID_ALUMNO='010044146'
                                         ORDER BY 1, cuatrimestre ,secuencia , materia

                                          ) LOOP

                                            DBMS_OUTPUT.PUT_LINE('Entra  Ec 2');

                                              BEGIN
                                                   SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                   INTO vl_asignacion
                                                   FROM sztasma
                                                   WHERE sztasma_camp_code = alumno.campus
                                                   AND sztasma_levl_code = alumno.nivel
                                                   AND sztasma_qnumb = 'Q'||1
                                                   AND sztasma_bim_numb ='B'||1
                                                   AND sztasma_inso_code = 'NO'
                                                   AND SZTASMA_PROGRAMA = materia.ID_PROGRAMA
                                                   AND SZTASMA_PTRM_CODE = alumno.ID_PERIODO;

                                                   DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion cinco '||vl_asignacion);
                                              EXCEPTION WHEN OTHERS THEN
                                                null;

                                              END;

                                              DBMS_OUTPUT.PUT_LINE('Entra  Ec 2 asignacion '||vl_asignacion);

                                              BEGIN

                                                  SELECT nvl(max(sztprono_secuencia),0)+1
                                                  INTO l_secuencia
                                                  FROM sztprono
                                                  WHERE 1 = 1
                                                  AND sztprono_no_regla = P_REGLA
                                                  AND sztprono_pidm = materia.SVRPROY_PIDM;

                                              exception when others then
                                                  null;
                                              end;

                                              BEGIN

                                               INSERT INTO sztprono VALUES ( materia.SVRPROY_PIDM,
                                                                            materia.ID_ALUMNO,
                                                                            materia.ID_CICLO,
                                                                            materia.ID_PROGRAMA,
                                                                            materia.materia,
                                                                            materia.secuencia,
                                                                            materia.ID_PERIODO,
                                                                            materia.materia_banner,
                                                                            'a',
                                                                            materia.fecha_inicio,
                                                                            'B'||1,
                                                                            materia.fecha_inicio,
                                                                            vl_avance,
                                                                            P_REGLA,
                                                                            USER,
                                                                            materia.STUDY_PATH,
                                                                            alumno.RATE,
                                                                            alumno.jornada_com,
                                                                            sysdate,
                                                                            'Q'||vl_qa_avance,
                                                                            vl_tip_ini,
                                                                            vl_tipo_jornada,
                                                                            'N',
                                                                            'N',
                                                                            materia.estatus,
                                                                            'N',
                                                                            null,
                                                                            materia.secuencia
                                                                             );

                                              EXCEPTION WHEN OTHERS THEN
                                                  dbms_output.put_line('Error -->'||sqlerrm);
                                                  null;
                                              END;

                                          END LOOP;

                    END IF;


                 End IF;

            Else
                     null;
              dbms_output.put_line ('Entra a Maestria Parte de bimestre ' ||vl_parte_bim);
            End IF;

            DBMS_OUTPUT.PUT_LINE('Itera  '||l_itera);


      END LOOP alumno;

--       begin
--            p_alianzas_pronostico_pidm(P_REGLA ,p_pidm);
--       end;
--
     commit;

--      Begin
--          p_ajuste_130 (p_regla);
--          Commit;
--      End;
--

 END;



--    l_itera:=0;
--
--        FOR alumno IN (
--                      SELECT DISTINCT id_alumno,
--                                       id_ciclo,
--                                       id_programa,
--                                       svrproy_pidm,
--                                       id_periodo,
--                                        (SELECT DISTINCT sztdtec_periodicidad
--                                         from SZTDTEC
--                                         where 1 = 1
--                                         and SZTDTEC_PROGRAM = ID_PROGRAMA
--                                         and SZTDTEC_TERM_CODE = periodo_catalogo
--                                         ) periodicidad,
--                                         null rate,
--                                         null jornada,
--                                         SUBSTR(id_programa,1,3)campus,
--                                         SUBSTR(id_programa,4,2) nivel,
--                                         null jornada_com,
--                                         rel_alumnos_x_asignar_no_regla sztprvn_no_regla,
--                                         tipo_equi equi,
--                                         periodo_catalogo,
--                                         fecha_inicio,
--                                         (select distinct REL_PROGRAMAXALUMNO_ESTATUS
--                                         from REL_PROGRAMAXALUMNO
--                                         where 1 = 1
--                                         and REL_PROGRAMAXALUMNO_NO_REGLA = REL_ALUMNOS_X_ASIGNAR_NO_REGLA
--                                         and SGBSTDN_PIDM = SVRPROY_PIDM
--                                         and rownum = 1
--                                         ) estatus
--                      FROM rel_alumnos_x_asignar
--                      WHERE 1 = 1
--                      AND rel_alumnos_x_asignar_no_regla = p_regla
--                      AND SVRPROY_PIDM = p_pidm
--
--      ) Loop
--
--
--            DBMS_OUTPUT.PUT_LINE('Entra  al 6 ');
--
--            vl_fecha_ing := NULL;
--            vl_tipo_ini  := NULL;
--
--            BEGIN
--
--                 SELECT DISTINCT MIN(TO_DATE(ssbsect_ptrm_start_date)) fecha_inicio,
--                                 MIN(SUBSTR(ssbsect_ptrm_code,2,1)) pperiodo
--                 INTO vl_fecha_ing,
--                      vl_tipo_ini
--                 FROM sfrstcr a,
--                      ssbsect b,
--                      sorlcur c
--                 WHERE 1 = 1
--                 AND a.sfrstcr_term_code = b.ssbsect_term_code
--                 AND a.sfrstcr_crn = b.ssbsect_crn
--                 AND a.sfrstcr_rsts_code = 'RE'
--                 AND b.ssbsect_ptrm_start_date =(SELECT MIN (b1.ssbsect_ptrm_start_date)
--                                                 FROM ssbsect b1
--                                                 WHERE 1 = 1
--                                                 AND b.ssbsect_term_code = b1.ssbsect_term_code
--                                                 and b.ssbsect_crn = b1.ssbsect_crn
--                                                 )
--                 AND sfrstcr_pidm =alumno.svrproy_pidm
--                 AND sfrstcr_pidm = c.sorlcur_pidm
--                 AND c.sorlcur_program = alumno.id_programa
--                 AND c.sorlcur_lmod_code = 'LEARNER'
--                 AND c.sorlcur_roll_ind = 'Y'
--                 AND c.sorlcur_cact_code ='ACTIVE'
--                 AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
--                                        FROM sorlcur c1
--                                        WHERE c.sorlcur_pidm = c1.sorlcur_pidm
--                                        AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code
--                                        AND c.sorlcur_roll_ind = c1.sorlcur_roll_ind
--                                        AND c.sorlcur_cact_code = c1.sorlcur_cact_code
--                                        AND c.sorlcur_program = c1.sorlcur_program
--                                        )
--                 AND sfrstcr_stsp_key_sequence =    c.sorlcur_key_seqno;
--
--
--            EXCEPTION WHEN OTHERS THEN
--                vl_fecha_ing:= NULL;
--                vl_tipo_ini := NULL;
--            END;
--
--
--            BEGIN
--
--                SELECT MIN (x.fecha_inicio) fecha,
--                      SUBSTR (x.pperiodo, 2,1) inicio
--                INTO vl_fecha_ing,
--                     vl_tipo_ini
--                FROM (
--                        SELECT DISTINCT MIN (SSBSECT_PTRM_START_DATE) fecha_inicio,
--                                       SFRSTCR_pidm pidm,
--                                       b.SSBSECT_TERM_CODE Periodo,
--                                       SSBSECT_PTRM_CODE pperiodo
--                        FROM SFRSTCR a,
--                             SSBSECT b,
--                             sorlcur c
--                        WHERE 1 = 1
--                        and a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
--                        AND a.SFRSTCR_CRN = b.SSBSECT_CRN
--                        AND a.SFRSTCR_RSTS_CODE = 'RE'
--                        AND b.SSBSECT_PTRM_START_DATE =
--                                                         (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
--                                                          FROM SSBSECT b1
--                                                          WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
--                                                          AND b.SSBSECT_CRN = b1.SSBSECT_CRN
--                                                          )
--                        and  SFRSTCR_pidm =alumno.SVRPROY_PIDM
--                        and SFRSTCR_pidm = c.sorlcur_pidm
--                        and c.sorlcur_program = alumno.ID_PROGRAMA
--                        and c.SORLCUR_LMOD_CODE = 'LEARNER'
--                        And c.SORLCUR_ROLL_IND = 'Y'
--                        and c.SORLCUR_CACT_CODE ='ACTIVE'
--                        and SSBSECT_PTRM_CODE not in 'SS1'
--                        and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
--                                                                 from sorlcur c1
--                                                                 where c.sorlcur_pidm = c1.sorlcur_pidm
--                                                                 and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
--                                                                 and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
--                                                                 and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
--                                                                 and c.sorlcur_program = c1.sorlcur_program)
--                        and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
--                        GROUP BY SFRSTCR_pidm,
--                                 b.SSBSECT_TERM_CODE ,
--                                 SSBSECT_PTRM_CODE
--                            order by 1,3 asc
--                    )  x
--                    where 1 = 1
--                    and rownum = 1
--                    group by x.Periodo, x.pperiodo
--                    order by 2 asc;
--
--                                if vl_tipo_ini = 0 then
--
--                                    vl_tipo_ini:=2;
--
--                                end if;
--
--                                 DBMS_OUTPUT.PUT_LINE('Recupera aqui en este lugar -->'||vl_tipo_ini);
--
--            Exception
--                When Others then
--                   Begin
--
--                     select   min (x.fecha_inicio) fecha,
--                              substr (x.pperiodo, 2,1) inicio
--                        Into vl_fecha_ing,
--                              vl_tipo_ini
--                        from (
--                                SELECT DISTINCT MIN (SSBSECT_PTRM_START_DATE) fecha_inicio,
--                                                SFRSTCR_pidm pidm,
--                                                b.SSBSECT_TERM_CODE Periodo,
--                                                SSBSECT_PTRM_CODE pperiodo
--                                FROM SFRSTCR a,
--                                     SSBSECT b,
--                                     sorlcur c
--                                WHERE 1 = 1
--                                AND a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
--                                AND a.SFRSTCR_CRN = b.SSBSECT_CRN
--                                AND a.SFRSTCR_RSTS_CODE = 'RE'
--                                AND b.SSBSECT_PTRM_START_DATE =
--                                                                 (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
--                                                                  FROM SSBSECT b1
--                                                                  WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
--                                                                  AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
--                                and  SFRSTCR_pidm =alumno.SVRPROY_PIDM
--                                and SFRSTCR_pidm = c.sorlcur_pidm
--                                and c.sorlcur_program = alumno.ID_PROGRAMA
--                                and c.SORLCUR_LMOD_CODE = 'LEARNER'
--                                And c.SORLCUR_ROLL_IND = 'Y'
--                                and c.SORLCUR_CACT_CODE ='ACTIVE'
--                                and SSBSECT_PTRM_CODE not in 'SS1'
--                                and c.SORLCUR_SEQNO = (
--                                                       select max (c1.SORLCUR_SEQNO)
--                                                       from sorlcur c1
--                                                       where c.sorlcur_pidm = c1.sorlcur_pidm
--                                                       and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
--                                                       and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
--                                                       and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
--                                                       and c.sorlcur_program = c1.sorlcur_program
--                                                       )
--                                and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
--                                    GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE , SSBSECT_PTRM_CODE
--                                    order by 1,3 asc
--                            )  x
--                            where rownum = 1
--                            group by x.Periodo, x.pperiodo
--                            order by 2 asc;
--
--                        EXCEPTION WHEN OTHERS THEN
--
--                            begin
--                                    select   min (x.fecha_inicio) fecha,
--                                             substr (x.pperiodo, 2,1) inicio
--                                    Into vl_fecha_ing,
--                                         vl_tipo_ini
--                                    from (
--                                        SELECT DISTINCT MIN (SSBSECT_PTRM_START_DATE) fecha_inicio,
--                                                        SFRSTCR_pidm pidm,
--                                                        b.SSBSECT_TERM_CODE Periodo,
--                                                        SSBSECT_PTRM_CODE pperiodo
--                                        FROM SFRSTCR a,
--                                             SSBSECT b,
--                                             sorlcur c
--                                        WHERE 1 = 1
--                                        AND a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
--                                        AND a.SFRSTCR_CRN = b.SSBSECT_CRN
--                                        AND a.SFRSTCR_RSTS_CODE != 'RE'
--                                        AND b.SSBSECT_PTRM_START_DATE =
--                                                                         (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
--                                                                          FROM SSBSECT b1
--                                                                          WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
--                                                                          AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
--                                        and  SFRSTCR_pidm =alumno.SVRPROY_PIDM
--                                        and SFRSTCR_pidm = c.sorlcur_pidm
--                                        and c.sorlcur_program = alumno.ID_PROGRAMA
--                                        and c.SORLCUR_LMOD_CODE = 'LEARNER'
--                                        And c.SORLCUR_ROLL_IND = 'Y'
--                                        and c.SORLCUR_CACT_CODE ='ACTIVE'
--                                        and SSBSECT_PTRM_CODE not in 'SS1'
--                                        and c.SORLCUR_SEQNO = (
--                                                               select max (c1.SORLCUR_SEQNO)
--                                                               from sorlcur c1
--                                                               where c.sorlcur_pidm = c1.sorlcur_pidm
--                                                               and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
--                                                               and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
--                                                               and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
--                                                               and c.sorlcur_program = c1.sorlcur_program
--                                                               )
--                                        and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
--                                            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE , SSBSECT_PTRM_CODE
--                                            order by 1,3 asc
--                                    )  x
--                                    where rownum = 1
--                                    group by x.Periodo, x.pperiodo
--                                    order by 2 asc;
--
--                                    if vl_tipo_ini = 0 then
--
--                                        vl_tipo_ini:=2;
--
--                                    end if;
--
--                            exception when others then
--
--                                     begin
--
--                                        select distinct substr (SZTALGO_PTRM_CODE_NEW, 2,1)
--                                        into vl_tipo_ini
--                                        from sztalgo
--                                        where 1 = 1
--                                        and sztalgo_no_regla = p_regla
--                                        and rownum = 1;
--
--                                     exception when others then
--                                        null;
--                                     end;
--    --
--                                     begin
--
--                                        select distinct c.SORLCUR_START_DATE
--                                        into vl_fecha_ing
--                                        from sorlcur c
--                                        where 1 = 1
--                                        and c.sorlcur_pidm = alumno.SVRPROY_PIDM
--                                        and c.sorlcur_program = alumno.ID_PROGRAMA
--                                        and c.SORLCUR_LMOD_CODE = 'LEARNER'
--                                        And c.SORLCUR_ROLL_IND = 'Y'
--                                        and c.SORLCUR_CACT_CODE ='ACTIVE'
--                                        and c.SORLCUR_SEQNO = (
--                                                               select max (c1.SORLCUR_SEQNO)
--                                                               from sorlcur c1
--                                                               where c.sorlcur_pidm = c1.sorlcur_pidm
--                                                               and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
--                                                               and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
--                                                               and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
--                                                               and c.sorlcur_program = c1.sorlcur_program
--                                                               );
--
--
--                                     exception when others then
--                                        null;
--                                     end;
--    --
--    --
--
--
--                            end;
--
--
--                        End;
--            End;
--
--            DBMS_OUTPUT.PUT_LINE('Entra  al 8 Fecha '||vl_fecha_ing||' Inicio '||vl_tipo_ini);
--            dbms_output.put_line ('Recupera el tipo de ingreso '||vl_fecha_ing|| '*'||vl_tipo_ini);
--
--            If vl_tipo_ini = 0 or  vl_tipo_ini = null then
--
--                vl_tipo_ini :=1;
--
--            End if;
--
--            DBMS_OUTPUT.PUT_LINE('Entra  al 9 ' ||vl_tipo_ini);
--
--            vl_tipo_jornada:= null;
--
--            vl_tip_ini:='NO';
--
--            If vl_tipo_ini is not null then ----------> Si no puedo obtener el tipo de ingreso no registro al alumno --------------
--
--                DBMS_OUTPUT.PUT_LINE('Entra  valor envio '||alumno.ID_PROGRAMA||'*'||alumno.SVRPROY_PIDM);
--
--                Begin
--                         select distinct substr (b.STVATTS_CODE, 3, 1) dato
--                             Into vl_tipo_jornada
--                         from SGRSATT a, STVATTS b, sorlcur c
--                         where a.SGRSATT_ATTS_CODE = b.STVATTS_CODE
--                         and a.SGRSATT_TERM_CODE_EFF = (select max ( a1.SGRSATT_TERM_CODE_EFF)
--                                                        from SGRSATT a1
--                                                        Where a.SGRSATT_PIDM = a1.SGRSATT_PIDM
--                                                        and a1.SGRSATT_ATTS_CODE = a1.SGRSATT_ATTS_CODE
--                                                        And regexp_like(a1.SGRSATT_ATTS_CODE, '^[0-9]') )
--                         and regexp_like(a.SGRSATT_ATTS_CODE, '^[0-9]')
--                         and SGRSATT_PIDM =  alumno.SVRPROY_PIDM
--                         and a.SGRSATT_PIDM = c.sorlcur_pidm
--                         and c.sorlcur_program = alumno.ID_PROGRAMA
--                         and c.SORLCUR_LMOD_CODE = 'LEARNER'
--                         And c.SORLCUR_ROLL_IND = 'Y'
--                         and c.SORLCUR_CACT_CODE ='ACTIVE'
--                         and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
--                                                from sorlcur c1
--                                                where c.sorlcur_pidm = c1.sorlcur_pidm
--                                                and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
--                                                and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
--                                                and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
--                                                and c.sorlcur_program = c1.sorlcur_program)
--                         and a.SGRSATT_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO;
--
--                         DBMS_OUTPUT.PUT_LINE('Entra  al 10 tipo de Jornada '||vl_tipo_jornada);
--
--                Exception
--                When Others then
--
--                   IF alumno.campus  in ('UTL','UMM')  and alumno.NIVEL  in ('MA') then
--                     vl_tipo_jornada := 'N';
--                   ELSIF alumno.campus  in ('UTL','UMM')  and alumno.NIVEL  in ('LI') then
--                     vl_tipo_jornada := 'C';
--                   ELSE
--                     vl_tipo_jornada := 'N';
--                   END IF;
--                   --dbms_output.put_line ('Error al recuperar la jornada cursada '||sqlerrm);
--                End;
--
--                IF alumno.campus  in ('UTL','UMM','UIN')  and alumno.NIVEL  in ('MA') and vl_tipo_jornada != 'N' then
--                      vl_tipo_jornada := 'N';
--                ELSIF alumno.campus  in ('UTL','UMM','UIN','COL')  and alumno.NIVEL  in ('LI') and vl_tipo_jornada = 'R' then
--                     vl_tipo_jornada := 'R';
--                ELSIF alumno.campus  in ('UNI')  and alumno.NIVEL  in ('LI') and vl_tipo_jornada = 'N' then
--                      vl_tipo_jornada := 'I';
--
--                END IF;
--
--                dbms_output.put_line ('recuperar la jornada cursada '||vl_tipo_jornada);
--                DBMS_OUTPUT.PUT_LINE('Entra  al 11 ');
--
--                vl_qa_avance :=0;
--          ----- Se obtiene el numero de QA que lleva cursados el alumno  -----------------
--                     Begin
--
--                              SELECT count (distinct a.SFRSTCR_TERM_CODE) Periodo
--                                 Into vl_qa_avance
--                             FROM SFRSTCR a, SSBSECT b, sorlcur c
--                            WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
--                                  AND a.SFRSTCR_CRN = b.SSBSECT_CRN
--                             --     And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB not  in ('L1HB401', 'IND00001', 'L1HB405', 'L1HB404', 'L1HB403', 'L1HP401', 'L1HB402', 'UTEL001')
--                                 AND a.SFRSTCR_RSTS_CODE = 'RE'
--                                  AND b.SSBSECT_PTRM_START_DATE =
--                                         (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
--                                            FROM SSBSECT b1
--                                           WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
--                                                 AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
--                            and SFRSTCR_pidm = c.sorlcur_pidm
--                            and c.sorlcur_program =   alumno.ID_PROGRAMA
--                            and c.SORLCUR_LMOD_CODE = 'LEARNER'
--                            And c.SORLCUR_ROLL_IND = 'Y'
--                            and c.SORLCUR_CACT_CODE ='ACTIVE'
--                            and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
--                                                                     from sorlcur c1
--                                                                     where c.sorlcur_pidm = c1.sorlcur_pidm
--                                                                     and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
--                                                                     and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
--                                                                     and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
--                                                                     and c.sorlcur_program = c1.sorlcur_program)
--                            and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
--                            and  SFRSTCR_pidm = alumno.SVRPROY_PIDM
----                            And SFRSTCR_TERM_CODE not in (select distinct SZTALGO_TERM_CODE_NEW
----                                                                                from sztalgo
----                                                                                where SZTALGO_NO_REGLA = P_REGLA)
--                         GROUP BY SFRSTCR_pidm ;
--
--                     Exception
--                         When Others then
--                                 Begin
--                                     SELECT count (distinct a.SFRSTCR_TERM_CODE) Periodo
--                                         Into vl_qa_avance
--                                     FROM SFRSTCR a, SSBSECT b, sorlcur c
--                                    WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
--                                          AND a.SFRSTCR_CRN = b.SSBSECT_CRN
--                                    --   And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB not  in ('L1HB401', 'IND00001', 'L1HB405', 'L1HB404', 'L1HB403', 'L1HP401', 'L1HB402', 'UTEL001')
--                                         AND a.SFRSTCR_RSTS_CODE != 'RE'
--                                          AND b.SSBSECT_PTRM_START_DATE =
--                                                 (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
--                                                    FROM SSBSECT b1
--                                                   WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
--                                                         AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
--                                    and SFRSTCR_pidm = c.sorlcur_pidm
--                                    and c.sorlcur_program =   alumno.ID_PROGRAMA
--                                    and c.SORLCUR_LMOD_CODE = 'LEARNER'
--                                    And c.SORLCUR_ROLL_IND = 'Y'
--                                    and c.SORLCUR_CACT_CODE ='ACTIVE'
--                                    and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
--                                                                             from sorlcur c1
--                                                                             where c.sorlcur_pidm = c1.sorlcur_pidm
--                                                                             and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
--                                                                             and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
--                                                                             and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
--                                                                             and c.sorlcur_program = c1.sorlcur_program)
--                                    and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
--                                    and  SFRSTCR_pidm = alumno.SVRPROY_PIDM
----                                    And SFRSTCR_TERM_CODE not in (select distinct SZTALGO_TERM_CODE_NEW
----                                                                                from sztalgo
----                                                                                where SZTALGO_NO_REGLA = P_REGLA)
--                                    GROUP BY SFRSTCR_pidm ;
--                                 exception
--                                 When Others then
--                                   vl_qa_avance :=0;
--                                 End;
--                           dbms_output.put_line ('Error al recuperar el QA cursado '||sqlerrm);
--                         vl_qa_avance :=1;
--                     End;
--
--                         dbms_output.put_line (' recuperar el QA cursado '||vl_qa_avance||' Programa '||alumno.ID_PROGRAMA);
--          --------- Se obtiene el bimestre que se esta cursando ------------------------
--
--                     vl_parte_bim :=null;
--
--
--                 If vl_parte_bim is null then
--                    vl_parte_bim := vl_tipo_ini;
--                 End if;
--
--                 IF vl_qa_avance >= 20 THEN
--                    vl_qa_avance:=20;
--                 END IF;
--
--
--                 -- se calcuala el bimestre en donde esta cursando
--                 IF vl_qa_avance IN (0,1) THEN
--
--                     l_bim:=1;
--
--                 ELSIF vl_qa_avance> 1 THEN
--
--                     l_bim:=2;
--
--                 END IF;
--
--                 dbms_output.put_line ('Bimestre '||l_bim);
--
--                 DBMS_OUTPUT.PUT_LINE('Entra  al 15 campus '||alumno.campus||' nivel '||alumno.nivel);
--
--                 If vl_parte_bim is  not null then----------> Si no existe parte de periodo no se incluye al alumno
--
--                    --programación para Lic.
--                    BEGIN
--
--                        SELECT COUNT(*)
--                        INTO l_cuenta_para_campus
--                        FROM zstpara
--                        WHERE 1 = 1
--                        AND zstpara_mapa_id='CAMP_PRONO'
--                        and zstpara_param_id  = alumno.campus
--                         AND zstpara_param_valor = alumno.nivel
--                        AND zstpara_param_valor ='LI';
--
--                    EXCEPTION WHEN OTHERS THEN
--                        l_cuenta_para_campus:=0;
--                    END;
--
--                    if l_cuenta_para_campus > 0 then
--
--
--                        IF vl_parte_bim = 2 THEN
--
--                            vl_qa_avance := vl_qa_avance +1;
--
--                            vl_parte_bim := 1;
--
--                        ELSIF  vl_parte_bim = 1 THEN
--
--                            vl_qa_avance := vl_qa_avance +1;
--
--                        ELSIF  vl_parte_bim = 3 THEN
--
--                            vl_qa_avance := vl_qa_avance +1;
--
--                        ELSIF  vl_parte_bim = 0 THEN
--
--                            vl_parte_bim := vl_parte_bim +1;
--
--                        END IF;
--
--
--                        DBMS_OUTPUT.PUT_LINE('entra a para  avance '||vl_qa_avance||' tipo de Jornada '||vl_tipo_jornada||' tip ini '||vl_tip_ini);
--
--
--                        IF vl_qa_avance > 20 then
--
--                            vl_qa_avance:=20;
--
--                        END IF;
--
--                         For asigna in (
--                                         SELECT (sztasgn_crse_numb + sztasgn_opt_numb ) asignacion
--                                         FROM sztasgn
--                                         WHERE 1 = 1
--                                         AND sztasgn_camp_code = alumno.campus
--                                         AND sztasgn_levl_code = alumno.nivel
--                                         AND sztasgn_qnumb = 'Q'||NVL(vl_qa_avance,1)
--                                         AND sztasgn_bim_numb in( 'B'||l_bim)
--                                         AND sztasgn_jorn_code = vl_tipo_jornada
--                                         AND sztasgn_inso_code = vl_tip_ini
--                                         and alumno.campus !='UVE'
--                                         UNION
--                                         SELECT (sztasgn_crse_numb + sztasgn_opt_numb ) asignacion
--                                         FROM sztasgn
--                                         WHERE 1 = 1
--                                         AND sztasgn_camp_code = alumno.campus
--                                         AND sztasgn_levl_code = alumno.nivel
--                                         AND sztasgn_qnumb = 'Q'||NVL(vl_qa_avance,1)
--                                         AND sztasgn_jorn_code = DECODE(vl_tipo_jornada,'N','I',vl_tipo_jornada)
--                                         AND sztasgn_inso_code = vl_tip_ini
--                                         and alumno.campus ='UVE'
--
--                                        ) loop
--
--                                            l_free :=f_conslta_freemium(alumno.svrproy_pidm);
--
--
--                                            BEGIN
--
--                                                SELECT COUNT(*)
--                                                INTO l_cuenta_free
--                                                FROM GORADID
--                                                WHERE 1 = 1
--                                                AND goradid_pidm= p_pidm
--                                                AND GORADID_ADID_CODE = l_free;
--
--
--                                             EXCEPTION WHEN OTHERS THEN
--                                                l_cuenta_free:=0;
--                                             END;
--
--                                             if l_cuenta_free > 0 and alumno.estatus in ('F','N') then
--
--
--                                                 begin
--
--                                                    SELECT DISTINCT to_number(ZSTPARA_PARAM_VALOR)
--                                                    into l_asigna_free
--                                                    FROM zstpara
--                                                    WHERE 1 = 1
--                                                    AND ZSTPARA_MAPA_ID ='FREEMIUM_MAT'
--                                                    and ZSTPARA_PARAM_ID =l_free;
--                                                 exception when others then
--                                                    l_asigna_free:=0;
--                                                 end;
--
--                                                 asigna.asignacion:=l_asigna_free;
--
--                                             end if;
--
--
--
--                                            vl_contador :=0;
--
--                                            For materia in (
--
--                                                            SELECT DISTINCT a.id_alumno,
--                                                                            a.id_ciclo,
--                                                                            a.id_programa,
--                                                                            a.clave_materia_agp materia,
--                                                                            a.secuencia,
--                                                                            a.svrproy_pidm,--, a.ID_PERIODO,
--                                                                            a.clave_materia materia_banner,
--                                                                            a.fecha_inicio,
--                                                                            c.study_path,
--                                                                            a.rel_alumnos_x_asignar_cuatri cuatrimestre,
--                                                                            c.rel_programaxalumno_estatus estatus,
--                                                                            a.id_periodo ptrm
--                                                            FROM rel_alumnos_x_asignar a,
--                                                                 rel_programaxalumno c
--                                                            WHERE 1 = 1
--                                                            AND a.svrproy_pidm = alumno.svrproy_pidm
--                                                            AND a.materias_excluidas = 0
--                                                            AND c.sgbstdn_pidm= a.svrproy_pidm
--                                                            AND a.id_periodo IS NOT NULL
--                                                            AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
--                                                            AND a.rel_alumnos_x_asignar_no_regla = p_regla
--                                                            AND a.materias_excluidas = 0
--                                                            AND  (a.svrproy_pidm, clave_materia, a.rel_alumnos_x_asignar_no_regla)  NOT IN (SELECT sztprono_pidm,
--                                                                                                                                                   sztprono_materia_banner,
--                                                                                                                                                   sztprono_no_regla
--                                                                                                                                            FROM sztprono
--                                                                                                                                            where 1 = 1
--                                                                                                                                            AND  sztprono_pidm =  a.svrproy_pidm
--                                                                                                                                            AND  sztprono_no_regla = p_regla )
--                                                            order by 1, cuatrimestre,SECUENCIA , materia
--                                                            ) Loop
--
--                                                                begin
--
--                                                                   SELECT COUNT(*)
--                                                                   INTO l_cuenta_prop
--                                                                   FROM sztptrm
--                                                                   WHERE 1 = 1
--                                                                   AND sztptrm_propedeutico = 1
--                                                                   AND sztptrm_term_code =materia.id_ciclo
--                                                                   AND sztptrm_ptrm_code =alumno.id_periodo
--                                                                   AND sztptrm_program =materia.id_programa;
--
--                                                                exception when others then
--                                                                   null;
--                                                                end;
--
--                                                                begin
--
--                                                                    SELECT distinct SZTPTRM_MATERIA
--                                                                    INTO l_curso_p
--                                                                    FROM sztptrm
--                                                                    WHERE 1 = 1
--                                                                    AND sztptrm_propedeutico = 1
--                                                                    AND sztptrm_term_code =materia.id_ciclo
--                                                                    AND sztptrm_ptrm_code =alumno.id_periodo
--                                                                    AND sztptrm_program =materia.id_programa;
--
--                                                                exception when others then
--                                                                   null;
--                                                                end;
--
--                                                                BEGIN
--
--                                                                    SELECT COUNT(*)
--                                                                    INTO l_cuenta_sfr
--                                                                    FROM SFRSTCR
--                                                                    WHERE 1 = 1
--                                                                    AND sfrstcr_pidm = materia.svrproy_pidm
--                                                                    AND sfrstcr_stsp_key_sequence =materia.study_path
--                                                                    AND sfrstcr_rsts_code ='RE';
--
--                                                                EXCEPTION WHEN OTHERS THEN
--                                                                   NULL;
--                                                                END;
--
--
--                                                                 if l_cuenta_prop >= 1 /*and vl_qa_avance =1*/ and materia.estatus IN('N','F','R') and l_cuenta_sfr = 0 then
--
--                                                                        Begin
--
--                                                                            Insert into sztprono values ( materia.SVRPROY_PIDM,
--                                                                                                          materia.ID_ALUMNO,
--                                                                                                          materia.ID_CICLO,
--                                                                                                          materia.ID_PROGRAMA,
--                                                                                                          l_curso_p,
--                                                                                                          vl_contador,
--                                                                                                          materia.ptrm,
--                                                                                                         l_curso_p,
--                                                                                                          'xx',
--                                                                                                          materia.FECHA_INICIO,
--                                                                                                          NULL,
--                                                                                                          NULL,
--                                                                                                          vl_avance,
--                                                                                                          P_REGLA,
--                                                                                                          USER,
--                                                                                                          materia.STUDY_PATH,
--                                                                                                          alumno.RATE,
--                                                                                                          alumno.jornada_com,
--                                                                                                          sysdate,
--                                                                                                          'Q'||vl_qa_avance,
--                                                                                                          vl_tip_ini,
--                                                                                                          vl_tipo_jornada,
--                                                                                                          'N',
--                                                                                                          'N',
--                                                                                                          materia.estatus,
--                                                                                                          'N',
--                                                                                                          null,
--                                                                                                          null
--                                                                                                           );
--                                                                            commit;
--
--                                                                        EXCEPTION WHEN OTHERS THEN
--                                                                            NULL;
--                                                                        END;
--        --                                                                Commit;
--                                                                        exit when vl_contador=ASIGNA.ASIGNACION;
--
--                                                                 else
--
--
--                                                                        vl_contador := vl_contador +1;
--
--                                                                        Begin
--
--                                                                            Insert into sztprono values ( materia.SVRPROY_PIDM,
--                                                                                                          materia.ID_ALUMNO,
--                                                                                                          materia.ID_CICLO,
--                                                                                                          materia.ID_PROGRAMA,
--                                                                                                          materia.Materia,
--                                                                                                          vl_contador,
--                                                                                                          materia.ptrm,
--                                                                                                          materia.Materia_Banner,
--                                                                                                          'x',
--                                                                                                          materia.FECHA_INICIO,
--                                                                                                          NULL,
--                                                                                                          NULL,
--                                                                                                          vl_avance,
--                                                                                                          P_REGLA,
--                                                                                                          USER,
--                                                                                                          materia.STUDY_PATH,
--                                                                                                          alumno.RATE,
--                                                                                                          alumno.jornada_com,
--                                                                                                          sysdate,
--                                                                                                          'Q'||vl_qa_avance,
--                                                                                                          vl_tip_ini,
--                                                                                                          vl_tipo_jornada,
--                                                                                                          'N',
--                                                                                                          'N',
--                                                                                                          materia.estatus,
--                                                                                                          'N',
--                                                                                                          null,
--                                                                                                          null
--                                                                                                           );
--                                                                            commit;
--
--                                                                        EXCEPTION WHEN OTHERS THEN
--                                                                            NULL;
--                                                                        END;
--        --                                                                Commit;
--                                                                        exit when vl_contador=ASIGNA.ASIGNACION;
--
--                                                                 end if;
--
--                                                            end loop materia;
--
--                                                            DBMS_OUTPUT.PUT_LINE('entra a asgn '||vl_contador||' Asignacion '||ASIGNA.ASIGNACION);
--
--                                                            vl_contador:=0;
--
--
--                                        end loop asigna;
--
--                    end if;
--
--                    l_cuenta_para_campus:=null;
--
--                    BEGIN
--
--                        SELECT COUNT(*)
--                        INTO l_cuenta_para_campus
--                        FROM zstpara
--                        WHERE 1 = 1
--                        AND zstpara_mapa_id='CAMP_PRONO'
--                        AND zstpara_param_id  = alumno.campus
--                        AND zstpara_param_valor = alumno.nivel
--                        AND zstpara_param_valor in('MA','MS','DO');
--
--                    EXCEPTION WHEN OTHERS THEN
--                        l_cuenta_para_campus:=0;
--                    END;
--
--                    IF l_cuenta_para_campus > 0 THEN
--
--                    dbms_output.put_line('Entra a doctorado');
--
----
--                        IF vl_parte_bim = 2 THEN
--
--                            vl_qa_avance := vl_qa_avance +1;
--                            vl_parte_bim := 1;
--
--                        ELSIF  vl_parte_bim = 1 THEN
--
--                            vl_qa_avance := vl_qa_avance +1;
--
--                        ELSIF  vl_parte_bim = 3 THEN
--
--                            vl_qa_avance := vl_qa_avance +1;
--
--                        ELSIF  vl_parte_bim = 0 THEN
--
--                            vl_parte_bim := vl_parte_bim +1;
--
--                        END IF;
--
--
--                        IF vl_tipo_ini = 0 THEN
--
--                            vl_tip_ini := 'AN';
--
--                        ELSIF vl_tipo_ini IN (1,3, 2,4) THEN
--
--                            vl_tip_ini := 'NO';
--
--                        END IF;
--
--                        vl_asignacion := 0;
--                        val_max :=0;
--
--                         IF alumno.periodicidad = 1 THEN
--
--                         dbms_output.put_line ('salida1 '||alumno.campus ||'*'||alumno.NIVEL||'*'||'Q'||vl_qa_avance||'*'||'B'||vl_parte_bim||'*'||vl_tip_ini);
--
--                         DBMS_OUTPUT.PUT_LINE('Entra  al 36 ');
--
--
--                              BEGIN
--
--                                  SELECT COUNT (DISTINCT sztasma_qnumb)
--                                      Into val_max
--                                  FROM sztasma
--                                  WHERE  1 = 1
--                                  AND sztasma_camp_code = alumno.campus
--                                  AND sztasma_levl_code = alumno.nivel
--                                  AND sztasma_bim_numb is not null;
--
--                                       DBMS_OUTPUT.PUT_LINE('Entra  al 37 val_max '||val_max);
--                              EXCEPTION WHEN OTHERS THEN
--                                val_max :=0;
--                              END;
--
--                              DBMS_OUTPUT.PUT_LINE('Entra  al 38 vl_qa_avance '||vl_qa_avance||' tipo inicio '||vl_tip_ini);
--
--                              IF vl_parte_bim = 4 THEN
--
--                                vl_parte_bim:=2;
--
--                              END IF;
--
--                              --vl_qa_avance := 2;
--
--
--                         ELSIF alumno.periodicidad = 2 THEN
--
--                           dbms_output.put_line ('salida2 '||alumno.campus ||'*'||alumno.NIVEL||'*'||'Q'||vl_qa_avance||'*'||'B'||vl_parte_bim||'*--> '||vl_tip_ini);
--
--                           DBMS_OUTPUT.PUT_LINE('Entra  al 40 ');
--
--                              BEGIN
--
--                                  SELECT COUNT (DISTINCT sztasma_qnumb)
--                                  INTO val_max
--                                  FROM sztasma
--                                  WHERE sztasma_camp_code = alumno.campus
--                                  AND sztasma_levl_code = alumno.nivel
--                                  AND sztasma_bim_numb is not null;
--
--                                       DBMS_OUTPUT.PUT_LINE('Entra  al 41 val_max '||val_max);
--                              EXCEPTION WHEN OTHERS THEN
--                                val_max :=0;
--                              END;
--
--                              IF alumno.campus ='UMM' THEN
--
--                                   vl_asignacion :=3;
--
--                              END IF;
--
----
----                              IF vl_qa_avance >= 3 THEN
----
----                                  vl_asignacion:=3;
----                              elsif vl_qa_avance < 3 then
----
----                                  vl_asignacion:=2;
----
----                              end if;
--
--                         end if;
--
--                         vl_contador :=0;
--                                     DBMS_OUTPUT.PUT_LINE('Entra  al 44 aqui avance '||vl_qa_avance);
--                                       For materia in (
--                                                       SELECT DISTINCT a.id_alumno,
--                                                                       a.id_ciclo,
--                                                                       a.id_programa,
--                                                                       a.clave_materia_agp materia,
--                                                                       a.secuencia,
--                                                                       a.svrproy_pidm,--, a.ID_PERIODO,
--                                                                       a.clave_materia materia_banner,
--                                                                       a.fecha_inicio,
--                                                                       c.study_path,
--                                                                       a.rel_alumnos_x_asignar_cuatri cuatrimestre,
--                                                                       rel_programaxalumno_estatus estatus
--                                                       FROM rel_alumnos_x_asignar a,
--                                                            rel_programaxalumno c
--                                                       WHERE 1 = 1
--                                                       AND a.svrproy_pidm = alumno.svrproy_pidm
--                                                       AND a.materias_excluidas = 0
--                                                       AND c.sgbstdn_pidm= a.svrproy_pidm
--                                                       AND a.id_periodo is not null
--                                                       AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
--                                                       AND a.rel_alumnos_x_asignar_no_regla = p_regla
--            --                                           and a.ID_ALUMNO='010044146'
--                                                       ORDER BY 1, cuatrimestre ,secuencia , materia
--
--                                          ) LOOP
--
--                                                  vl_contador := vl_contador +1;
--                                                  dbms_output.put_line ('Contador  ' || vl_contador);
--                                                  DBMS_OUTPUT.PUT_LINE('Entra  al 45 estatus '||materia.estatus);
--
--
--
--                                                 BEGIN
--
--                                                    SELECT COUNT(*)
--                                                    INTO l_cuenta_asma
--                                                    FROM ZSTPARA
--                                                    WHERE 1 = 1
--                                                    AND zstpara_mapa_id ='ASMA_MAT'
--                                                    AND zstpara_param_desc ='Q'||vl_qa_avance
--                                                    AND zstpara_param_id = materia.id_programa;
--
--                                                 EXCEPTION WHEN OTHERS THEN
--                                                    NULL;
--                                                 END;
--
--                                                 IF l_cuenta_asma > 0 THEN
--
--                                                     BEGIN
--
--                                                        select DISTINCT zstpara_param_valor
--                                                        into vl_asignacion
--                                                        FROM zstpara
--                                                        WHERE 1 = 1
--                                                        AND zstpara_mapa_id ='ASMA_MAT'
--                                                        AND zstpara_param_desc ='Q'||vl_qa_avance
--                                                        and zstpara_param_id = materia.id_programa;
--
--                                                     EXCEPTION WHEN OTHERS THEN
--                                                        NULL;
--                                                     END;
--
--                                                 ELSE
--
--                                                     begin
--
--                                                        select count(*)
--                                                        into l_cuenta_asma
--                                                        from sztasma
--                                                        where 1 = 1
--                                                        and SZTASMA_CAMP_CODE = alumno.campus
--                                                        and SZTASMA_LEVL_CODE = alumno.nivel
--                                                        and SZTASMA_PROGRAMA =materia.id_programa;
--
--                                                    exception when others then
--                                                        l_cuenta_asma:=0;
--                                                    end;
--
--
--
--                                                    if l_cuenta_asma > 0  and vl_qa_avance > 5 then
--
--                                                        DBMS_OUTPUT.PUT_LINE('Entra  a asma '||l_cuenta_asma);
--
--                                                        BEGIN
--                                                              SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
--                                                              INTO vl_asignacion
--                                                              FROM sztasma
--                                                              WHERE sztasma_camp_code = alumno.campus
--                                                              AND sztasma_levl_code = alumno.nivel
--                                                              AND sztasma_qnumb = 'Q'||vl_qa_avance
--                                                              AND sztasma_bim_numb IS NULL
--                                                              AND sztasma_inso_code = vl_tip_ini
--                                                              and SZTASMA_PROGRAMA =materia.id_programa;
--
--                                                              DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion||' aqui reviso ');
--                                                         EXCEPTION WHEN OTHERS THEN
--                                                             vl_asignacion :=0;
--
--                                                              IF alumno.campus ='UMM' THEN
--                                                                  vl_asignacion :=3;
--                                                              END IF;
--
--                                                         END;
--
--                                                          --cuando pasa del maximo q
--                                                         if vl_qa_avance   >= val_max then
--
--                                                            vl_asignacion:=4;
--
--                                                            dbms_output.put_line('Entra al maximo');
--
--                                                         end if;
--
--                                                    else
--                                                        --raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);
--
--
--                                                       IF alumno.periodicidad = 1 THEN
--
--                                                            -- VALIDACION PARA CONFIGURACION POR BIMESTRE
--
--                                                             BEGIN
--                                                                  SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
--                                                                  INTO vl_asignacion
--                                                                  FROM sztasma
--                                                                  WHERE sztasma_camp_code = alumno.campus
--                                                                  AND sztasma_levl_code = alumno.nivel
--                                                                  AND sztasma_qnumb = 'Q'||vl_qa_avance
--                                                                  AND sztasma_bim_numb = 'B'||l_bim
--                                                                  AND sztasma_inso_code = vl_tip_ini
--                                                                  and SZTASMA_PROGRAMA IS NULL;
--
--                                                                  DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion);
--                                                             EXCEPTION WHEN OTHERS THEN
--                                                                 vl_asignacion :=0;
--
--                                                                  IF alumno.campus ='UMM' THEN
--                                                                      vl_asignacion :=3;
--                                                                  END IF;
--
--                                                             END;
--
--                                                             --cuando pasa del maximo q
--                                                             if vl_qa_avance   >= val_max then
--
--                                                                vl_asignacion:=4;
--
--                                                             end if;
--
--                                                       ELSE
--
--                                                             l_valida_asma:=0;
--
--
--                                                            DBMS_OUTPUT.PUT_LINE('Entra  por aca campus '||alumno.campus||' nivel '||alumno.nivel||' avance '||vl_qa_avance||' Bim '||l_bim||' inso code '||vl_tip_ini||' Programa '||materia.id_programa||' periodicidad '||alumno.periodicidad);
--
--                                                            BEGIN
--                                                                  SELECT count(*)
--                                                                  INTO l_valida_asma
--                                                                  FROM sztasma
--                                                                  WHERE sztasma_camp_code = alumno.campus
--                                                                  AND sztasma_levl_code = alumno.nivel
--                                                                  AND sztasma_qnumb = 'Q'||vl_qa_avance
----                                                                  AND sztasma_bim_numb ='B'||l_bim
--                                                                  AND sztasma_inso_code = vl_tip_ini
--                                                                  and SZTASMA_PROGRAMA = materia.id_programa;
--
--                                                                  DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion||' por aca ');
--                                                            EXCEPTION WHEN OTHERS THEN
--                                                                null;
--
--                                                            END;
--
--                                                            DBMS_OUTPUT.PUT_LINE(' valor '||l_valida_asma||' avance '||vl_qa_avance||' Bimestre '||l_bim||' inicio '||vl_tip_ini||' Programa '||materia.id_programa);
--
--                                                            if l_valida_asma = 0 then
--
--                                                                     BEGIN
--                                                                          SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
--                                                                          INTO vl_asignacion
--                                                                          FROM sztasma
--                                                                          WHERE sztasma_camp_code = alumno.campus
--                                                                          AND sztasma_levl_code = alumno.nivel
--                                                                          AND sztasma_qnumb = 'Q'||vl_qa_avance
--                                                                          AND sztasma_bim_numb  IS NULL
--                                                                          AND sztasma_inso_code = vl_tip_ini
--                                                                          and SZTASMA_PROGRAMA IS NULL;
--
--                                                                          DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion||'2850');
--                                                                     EXCEPTION WHEN OTHERS THEN
--                                                                         vl_asignacion :=0;
--
--                                                                          IF alumno.campus ='UMM' THEN
--                                                                              vl_asignacion :=3;
--                                                                          END IF;
--
--                                                                     END;
--
--                                                                     --cuando pasa del maximo q
--                                                                     if vl_qa_avance   >= val_max then
--
--                                                                        vl_asignacion:=4;
--
--                                                                     end if;
--
--                                                            elsif l_valida_asma > 0 then
--
--                                                                 BEGIN
--                                                                      SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
--                                                                      INTO vl_asignacion
--                                                                      FROM sztasma
--                                                                      WHERE sztasma_camp_code = alumno.campus
--                                                                      AND sztasma_levl_code = alumno.nivel
--                                                                      AND sztasma_qnumb = 'Q'||vl_qa_avance
----                                                                      AND sztasma_bim_numb ='B'||l_bim
--                                                                      AND sztasma_inso_code = vl_tip_ini
--                                                                      and SZTASMA_PROGRAMA = materia.id_programa;
--
--                                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion);
--                                                                 EXCEPTION WHEN OTHERS THEN
--                                                                     vl_asignacion :=0;
--
--                                                                      IF alumno.campus ='UMM' THEN
--                                                                          vl_asignacion :=3;
--                                                                      END IF;
--
--                                                                 END;
--
--                                                            end if;
--
--                                                       END IF;
--
--                                                    end if;
--
--
--                                                 END IF;
--
--                                                 DBMS_OUTPUT.PUT_LINE('Periodicidad '||alumno.PERIODICIDAD||' Periodo 2'||alumno.ID_PERIODO);
--
--                                                 begin
--
--                                                    SELECT COUNT(*)
--                                                    INTO l_cuenta_prop
--                                                    FROM sztptrm
--                                                    WHERE 1 = 1
--                                                    AND sztptrm_propedeutico = 1
--                                                    AND sztptrm_term_code =materia.id_ciclo
--                                                    AND sztptrm_ptrm_code =alumno.id_periodo
--                                                    AND sztptrm_program =materia.id_programa;
--
--                                                 exception when others then
--                                                    null;
--                                                 end;
--
--                                                 DBMS_OUTPUT.PUT_LINE('Periodo '||materia.ID_CICLO||' Ptrm '||alumno.ID_PERIODO||' Programa '||materia.ID_PROGRAMA||' Matricula '||materia.ID_ALUMNO||' Prope '||l_cuenta_prop);
--                                                 --macana1
--
--                                                 BEGIN
--
--                                                    SELECT COUNT(*)
--                                                    INTO l_cuenta_sfr
--                                                    FROM SFRSTCR
--                                                    WHERE 1 = 1
--                                                    AND sfrstcr_pidm = materia.svrproy_pidm
--                                                    AND sfrstcr_stsp_key_sequence =materia.study_path
--                                                    AND sfrstcr_rsts_code ='RE';
--
--                                                 EXCEPTION WHEN OTHERS THEN
--                                                    NULL;
--                                                 END;
--
--                                                 DBMS_OUTPUT.PUT_LINE('Entra  al asma '||l_cuenta_prop||' cuenta matyerias '||l_cuenta_sfr||' Avance '||vl_qa_avance);
--
--                                                if l_cuenta_prop >= 1 /*and vl_qa_avance =1*/ and materia.estatus IN('N','F') and l_cuenta_sfr = 0 then
--
--                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 47000 '||l_cuenta_prop);
--
--                                                      BEGIN
--                                                                  INSERT INTO sztprono VALUES ( materia.svrproy_pidm,
--                                                                                                materia.id_alumno,
--                                                                                                materia.id_ciclo,
--                                                                                                materia.id_programa,
--                                                                                                'M1HB401',
--                                                                                                vl_contador,
--                                                                                                alumno.id_periodo,
--                                                                                                'M1HB401',
--                                                                                                'x',
--                                                                                                materia.fecha_inicio,
--                                                                                                null,
--                                                                                                null,
--                                                                                                vl_avance,
--                                                                                                p_regla,
--                                                                                                user,
--                                                                                                materia.study_path,
--                                                                                                alumno.rate,
--                                                                                                alumno.jornada_com,
--                                                                                                sysdate,
--                                                                                                'Q'||vl_qa_avance,
--                                                                                                vl_tip_ini,
--                                                                                                vl_tipo_jornada,
--                                                                                                'N',
--                                                                                                'N',
--                                                                                                materia.estatus,
--                                                                                                'N',
--                                                                                                null,
--                                                                                                null
--                                                                                                );
----                                                      COMMIT;
--
--                                                      EXCEPTION WHEN OTHERS THEN
--                                                         NULL;
--                                                      END;
--
--                                                    EXIT WHEN vl_contador=1;
--
--                                                ELSE
--
--                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 48000 '||l_cuenta_prop||' Asignacion '||vl_asignacion);
--
--                                                      BEGIN
--                                                                  INSERT INTO sztprono VALUES ( materia.svrproy_pidm,
--                                                                                                materia.id_alumno,
--                                                                                                materia.id_ciclo,
--                                                                                                materia.id_programa,
--                                                                                                materia.materia,
--                                                                                                vl_contador,
--                                                                                                alumno.id_periodo,
--                                                                                                materia.materia_banner,
--                                                                                                'x',
--                                                                                                materia.fecha_inicio,
--                                                                                                null,
--                                                                                                null,
--                                                                                                vl_avance,
--                                                                                                p_regla,
--                                                                                                user,
--                                                                                                materia.study_path,
--                                                                                                alumno.rate,
--                                                                                                alumno.jornada_com,
--                                                                                                sysdate,
--                                                                                                'Q'||vl_qa_avance,
--                                                                                                vl_tip_ini,
--                                                                                                vl_tipo_jornada,
--                                                                                                'N',
--                                                                                                'N',
--                                                                                                materia.estatus,
--                                                                                                'N',
--                                                                                                null,
--                                                                                                null
--                                                                                                );
--
----                                                        commit;
--                                                      EXCEPTION  WHEN OTHERS THEN
--                                                         NULL;
--                                                      END;
--
--
--                                                       DBMS_OUTPUT.PUT_LINE('Macana Semis '||l_semis||' Programa  '||materia.ID_PROGRAMA||' Ptrm'||alumno.ID_PERIODO);
--
--                                                      COMMIT;
--
--
--                                                    EXIT WHEN vl_contador=vl_asignacion;
--
--                                                END IF;
--                                                 --banda
--
--
--                                          END LOOP Materia;
--                                          vl_contador :=0;
--
--                            dbms_output.put_line ('Entra a Maestria Parte de bimestre ' ||vl_parte_bim);
--
--                    END IF;
--
--
--
--
--                 End if;
--
--            Else
--                     null;
--              dbms_output.put_line ('Entra a Maestria Parte de bimestre ' ||vl_parte_bim);
--            End if;
--
--            DBMS_OUTPUT.PUT_LINE('Itera  '||l_itera);
--
--
--      End Loop alumno;
--
--      commit;
--
-- END;

   PROCEDURE p_materias_pidm_tume (P_REGLA NUMBER,
                                    p_pidm  NUMBER,
                                    p_materia_legal varchar2)
    as
    --
    --
        l_retorna varchar2(200):='EXITO';

   vl_numero number:=0;
    vl_contador number:=0;
    vl_avance number :=0;
    vl_fecha_ing date;
    vl_tipo_ini number;
    vl_tipo_jornada varchar2(1):= null;
    vl_qa_avance number :=0;
    vl_parte_bim number :=0;
    vl_tip_ini varchar2(10):= null;
    vl_asignacion number:=0;
    val_max number:=0;
    vl_Error Varchar2(2000) := 'EXITO';
    l_ptrm_algo varchar2(10);











    l_itera number:=0;
    l_cuenta_registro number;
    l_cuenta_sfr number;
    l_cuenta_semi number;
    l_bim NUMBER;
    l_sp number;
    l_cuenta_grade number;
    l_cuenta_asma number;
    l_cuenta_prop number;
    -- P_REGLA NUMBER :=4;
    l_semis varchar2(2);
    l_cuenta_para_campus number:=0;
    l_cuenta_materia number;


BEGIN

    l_cuenta_para_campus:=0;

    DBMS_OUTPUT.PUT_LINE('Entra  al 1 ');

    --raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);

    BEGIN
        DELETE sztprono
        WHERE 1 = 1
        AND sztprono_no_regla = p_regla
        AND SZTPRONO_PIDM= p_pidm
        and sztprono_materia_legal = p_materia_legal;

        COMMIT;

    EXCEPTION WHEN OTHERS THEN
       raise_application_error (-20002,'Error al insertar a tabla de paso 1 '|| SQLERRM||' '||SQLCODE);
    END;



    l_itera:=0;

    begin

         SELECT count(*)
         into l_cuenta_materia
         FROM rel_alumnos_x_asignar
         WHERE 1 = 1
         AND rel_alumnos_x_asignar_no_regla = p_regla
         AND SVRPROY_PIDM = p_pidm
         and CLAVE_MATERIA_AGP = p_materia_legal;

    exception when others then

        null;
    end;

    if l_cuenta_materia > 0 then

        FOR alumno IN (
                      SELECT DISTINCT id_alumno,
                                       id_ciclo,
                                       id_programa,
                                       svrproy_pidm,
                                       id_periodo,
                                        (SELECT DISTINCT sztdtec_periodicidad
                                         from SZTDTEC
                                         where 1 = 1
                                         and SZTDTEC_PROGRAM = ID_PROGRAMA
                                         and SZTDTEC_TERM_CODE = periodo_catalogo
                                         ) periodicidad,
                                         null rate,
                                         null jornada,
                                         SUBSTR(id_programa,1,3)campus,
                                         SUBSTR(id_programa,4,2) nivel,
                                         null jornada_com,
                                         rel_alumnos_x_asignar_no_regla sztprvn_no_regla,
                                         tipo_equi equi,
                                         periodo_catalogo
                      FROM rel_alumnos_x_asignar
                      WHERE 1 = 1
                      AND rel_alumnos_x_asignar_no_regla = p_regla
                      AND SVRPROY_PIDM = p_pidm
                      and CLAVE_MATERIA_AGP = p_materia_legal

      ) Loop


            DBMS_OUTPUT.PUT_LINE('Entra  al 6 ');

            vl_fecha_ing := NULL;
            vl_tipo_ini  := NULL;

            BEGIN

                 SELECT DISTINCT MIN(TO_DATE(ssbsect_ptrm_start_date)) fecha_inicio,
                                 MIN(SUBSTR(ssbsect_ptrm_code,2,1)) pperiodo
                 INTO vl_fecha_ing,
                      vl_tipo_ini
                 FROM sfrstcr a,
                      ssbsect b,
                      sorlcur c
                 WHERE 1 = 1
                 AND a.sfrstcr_term_code = b.ssbsect_term_code
                 AND a.sfrstcr_crn = b.ssbsect_crn
                 AND a.sfrstcr_rsts_code = 'RE'
                 AND b.ssbsect_ptrm_start_date =(SELECT MIN (b1.ssbsect_ptrm_start_date)
                                                 FROM ssbsect b1
                                                 WHERE 1 = 1
                                                 AND b.ssbsect_term_code = b1.ssbsect_term_code
                                                 and b.ssbsect_crn = b1.ssbsect_crn
                                                 )
                 AND sfrstcr_pidm =alumno.svrproy_pidm
                 AND sfrstcr_pidm = c.sorlcur_pidm
                 AND c.sorlcur_program = alumno.id_programa
                 AND c.sorlcur_lmod_code = 'LEARNER'
                 AND c.sorlcur_roll_ind = 'Y'
                 AND c.sorlcur_cact_code ='ACTIVE'
                 AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
                                        FROM sorlcur c1
                                        WHERE c.sorlcur_pidm = c1.sorlcur_pidm
                                        AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code
                                        AND c.sorlcur_roll_ind = c1.sorlcur_roll_ind
                                        AND c.sorlcur_cact_code = c1.sorlcur_cact_code
                                        AND c.sorlcur_program = c1.sorlcur_program
                                        )
                 AND sfrstcr_stsp_key_sequence =    c.sorlcur_key_seqno;


            EXCEPTION WHEN OTHERS THEN
                vl_fecha_ing:= NULL;
                vl_tipo_ini := NULL;
            END;


            BEGIN

                SELECT MIN (x.fecha_inicio) fecha,
                      SUBSTR (x.pperiodo, 2,1) inicio
                INTO vl_fecha_ing,
                     vl_tipo_ini
                FROM (
                        SELECT DISTINCT MIN (SSBSECT_PTRM_START_DATE) fecha_inicio,
                                       SFRSTCR_pidm pidm,
                                       b.SSBSECT_TERM_CODE Periodo,
                                       SSBSECT_PTRM_CODE pperiodo
                        FROM SFRSTCR a,
                             SSBSECT b,
                             sorlcur c
                        WHERE 1 = 1
                        and a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                        AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                        AND a.SFRSTCR_RSTS_CODE = 'RE'
                        AND b.SSBSECT_PTRM_START_DATE =
                                                         (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                                          FROM SSBSECT b1
                                                          WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                          AND b.SSBSECT_CRN = b1.SSBSECT_CRN
                                                          )
                        and  SFRSTCR_pidm =alumno.SVRPROY_PIDM
                        and SFRSTCR_pidm = c.sorlcur_pidm
                        and c.sorlcur_program = alumno.ID_PROGRAMA
                        and c.SORLCUR_LMOD_CODE = 'LEARNER'
                        And c.SORLCUR_ROLL_IND = 'Y'
                        and c.SORLCUR_CACT_CODE ='ACTIVE'
                        and SSBSECT_PTRM_CODE not in 'SS1'
                        and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
                                                                 from sorlcur c1
                                                                 where c.sorlcur_pidm = c1.sorlcur_pidm
                                                                 and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                                 and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                                 and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                                 and c.sorlcur_program = c1.sorlcur_program)
                        and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
                        GROUP BY SFRSTCR_pidm,
                                 b.SSBSECT_TERM_CODE ,
                                 SSBSECT_PTRM_CODE
                            order by 1,3 asc
                    )  x
                    where 1 = 1
                    and rownum = 1
                    group by x.Periodo, x.pperiodo
                    order by 2 asc;

                                if vl_tipo_ini = 0 then

                                    vl_tipo_ini:=2;

                                end if;

                                 DBMS_OUTPUT.PUT_LINE('Recupera aqui en este lugar -->'||vl_tipo_ini);

            Exception
                When Others then
                   Begin

                     select   min (x.fecha_inicio) fecha,
                              substr (x.pperiodo, 2,1) inicio
                        Into vl_fecha_ing,
                              vl_tipo_ini
                        from (
                                SELECT DISTINCT MIN (SSBSECT_PTRM_START_DATE) fecha_inicio,
                                                SFRSTCR_pidm pidm,
                                                b.SSBSECT_TERM_CODE Periodo,
                                                SSBSECT_PTRM_CODE pperiodo
                                FROM SFRSTCR a,
                                     SSBSECT b,
                                     sorlcur c
                                WHERE 1 = 1
                                AND a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                                AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                                AND a.SFRSTCR_RSTS_CODE = 'RE'
                                AND b.SSBSECT_PTRM_START_DATE =
                                                                 (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                                                  FROM SSBSECT b1
                                                                  WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                                  AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                                and  SFRSTCR_pidm =alumno.SVRPROY_PIDM
                                and SFRSTCR_pidm = c.sorlcur_pidm
                                and c.sorlcur_program = alumno.ID_PROGRAMA
                                and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                And c.SORLCUR_ROLL_IND = 'Y'
                                and c.SORLCUR_CACT_CODE ='ACTIVE'
                                and SSBSECT_PTRM_CODE not in 'SS1'
                                and c.SORLCUR_SEQNO = (
                                                       select max (c1.SORLCUR_SEQNO)
                                                       from sorlcur c1
                                                       where c.sorlcur_pidm = c1.sorlcur_pidm
                                                       and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                       and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                       and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                       and c.sorlcur_program = c1.sorlcur_program
                                                       )
                                and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
                                    GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE , SSBSECT_PTRM_CODE
                                    order by 1,3 asc
                            )  x
                            where rownum = 1
                            group by x.Periodo, x.pperiodo
                            order by 2 asc;

                        EXCEPTION WHEN OTHERS THEN

                            begin
                                    select   min (x.fecha_inicio) fecha,
                                             substr (x.pperiodo, 2,1) inicio
                                    Into vl_fecha_ing,
                                         vl_tipo_ini
                                    from (
                                        SELECT DISTINCT MIN (SSBSECT_PTRM_START_DATE) fecha_inicio,
                                                        SFRSTCR_pidm pidm,
                                                        b.SSBSECT_TERM_CODE Periodo,
                                                        SSBSECT_PTRM_CODE pperiodo
                                        FROM SFRSTCR a,
                                             SSBSECT b,
                                             sorlcur c
                                        WHERE 1 = 1
                                        AND a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                                        AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                                        AND a.SFRSTCR_RSTS_CODE != 'RE'
                                        AND b.SSBSECT_PTRM_START_DATE =
                                                                         (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                                                          FROM SSBSECT b1
                                                                          WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                                          AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                                        and  SFRSTCR_pidm =alumno.SVRPROY_PIDM
                                        and SFRSTCR_pidm = c.sorlcur_pidm
                                        and c.sorlcur_program = alumno.ID_PROGRAMA
                                        and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                        And c.SORLCUR_ROLL_IND = 'Y'
                                        and c.SORLCUR_CACT_CODE ='ACTIVE'
                                        and SSBSECT_PTRM_CODE not in 'SS1'
                                        and c.SORLCUR_SEQNO = (
                                                               select max (c1.SORLCUR_SEQNO)
                                                               from sorlcur c1
                                                               where c.sorlcur_pidm = c1.sorlcur_pidm
                                                               and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                               and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                               and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                               and c.sorlcur_program = c1.sorlcur_program
                                                               )
                                        and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
                                            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE , SSBSECT_PTRM_CODE
                                            order by 1,3 asc
                                    )  x
                                    where rownum = 1
                                    group by x.Periodo, x.pperiodo
                                    order by 2 asc;

                                    if vl_tipo_ini = 0 then

                                        vl_tipo_ini:=2;

                                    end if;

                            exception when others then

                                     begin

                                        select distinct substr (SZTALGO_PTRM_CODE_NEW, 2,1)
                                        into vl_tipo_ini
                                        from sztalgo
                                        where 1 = 1
                                        and sztalgo_no_regla = p_regla
                                        and rownum = 1;

                                     exception when others then
                                        null;
                                     end;
    --
                                     begin

                                        select distinct c.SORLCUR_START_DATE
                                        into vl_fecha_ing
                                        from sorlcur c
                                        where 1 = 1
                                        and c.sorlcur_pidm = alumno.SVRPROY_PIDM
                                        and c.sorlcur_program = alumno.ID_PROGRAMA
                                        and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                        And c.SORLCUR_ROLL_IND = 'Y'
                                        and c.SORLCUR_CACT_CODE ='ACTIVE'
                                        and c.SORLCUR_SEQNO = (
                                                               select max (c1.SORLCUR_SEQNO)
                                                               from sorlcur c1
                                                               where c.sorlcur_pidm = c1.sorlcur_pidm
                                                               and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                               and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                               and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                               and c.sorlcur_program = c1.sorlcur_program
                                                               );


                                     exception when others then
                                        null;
                                     end;
    --
    --


                            end;


                        End;
            End;

            DBMS_OUTPUT.PUT_LINE('Entra  al 8 Fecha '||vl_fecha_ing||' Inicio '||vl_tipo_ini);
            dbms_output.put_line ('Recupera el tipo de ingreso '||vl_fecha_ing|| '*'||vl_tipo_ini);

            If vl_tipo_ini = 0 or  vl_tipo_ini is null then

                vl_tipo_ini :=1;

            End if;

            DBMS_OUTPUT.PUT_LINE('Entra  al 9 ' ||vl_tipo_ini);

            vl_tipo_jornada:= null;

            vl_tip_ini:='NO';

            If vl_tipo_ini is not null then ----------> Si no puedo obtener el tipo de ingreso no registro al alumno --------------

                DBMS_OUTPUT.PUT_LINE('Entra  valor envio '||alumno.ID_PROGRAMA||'*'||alumno.SVRPROY_PIDM);

                Begin
                         select distinct substr (b.STVATTS_CODE, 3, 1) dato
                             Into vl_tipo_jornada
                         from SGRSATT a, STVATTS b, sorlcur c
                         where a.SGRSATT_ATTS_CODE = b.STVATTS_CODE
                         and a.SGRSATT_TERM_CODE_EFF = (select max ( a1.SGRSATT_TERM_CODE_EFF)
                                                        from SGRSATT a1
                                                        Where a.SGRSATT_PIDM = a1.SGRSATT_PIDM
                                                        and a1.SGRSATT_ATTS_CODE = a1.SGRSATT_ATTS_CODE
                                                        And regexp_like(a1.SGRSATT_ATTS_CODE, '^[0-9]') )
                         and regexp_like(a.SGRSATT_ATTS_CODE, '^[0-9]')
                         and SGRSATT_PIDM =  alumno.SVRPROY_PIDM
                         and a.SGRSATT_PIDM = c.sorlcur_pidm
                         and c.sorlcur_program = alumno.ID_PROGRAMA
                         and c.SORLCUR_LMOD_CODE = 'LEARNER'
                         And c.SORLCUR_ROLL_IND = 'Y'
                         and c.SORLCUR_CACT_CODE ='ACTIVE'
                         and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
                                                from sorlcur c1
                                                where c.sorlcur_pidm = c1.sorlcur_pidm
                                                and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                and c.sorlcur_program = c1.sorlcur_program)
                         and a.SGRSATT_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO;

                         DBMS_OUTPUT.PUT_LINE('Entra  al 10 tipo de Jornada '||vl_tipo_jornada);

                Exception
                When Others then

                   IF alumno.campus  in ('UTL','UMM')  and alumno.NIVEL  in ('MA') then
                     vl_tipo_jornada := 'N';
                   ELSIF alumno.campus  in ('UTL','UMM')  and alumno.NIVEL  in ('LI') then
                     vl_tipo_jornada := 'C';
                   ELSE
                     vl_tipo_jornada := 'N';
                   END IF;
                   --dbms_output.put_line ('Error al recuperar la jornada cursada '||sqlerrm);
                End;

                IF alumno.campus  in ('UTL','UMM','UIN')  and alumno.NIVEL  in ('MA') and vl_tipo_jornada != 'N' then
                      vl_tipo_jornada := 'N';
                ELSIF alumno.campus  in ('UTL','UMM','UIN','COL')  and alumno.NIVEL  in ('LI') and vl_tipo_jornada = 'R' then
                     vl_tipo_jornada := 'R';
                END IF;

                dbms_output.put_line ('recuperar la jornada cursada '||vl_tipo_jornada);
                DBMS_OUTPUT.PUT_LINE('Entra  al 11 ');

                vl_qa_avance :=0;
          ----- Se obtiene el numero de QA que lleva cursados el alumno  -----------------
                     Begin

                              SELECT count (distinct a.SFRSTCR_TERM_CODE) Periodo
                                 Into vl_qa_avance
                             FROM SFRSTCR a, SSBSECT b, sorlcur c
                            WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                                  AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                             --     And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB not  in ('L1HB401', 'IND00001', 'L1HB405', 'L1HB404', 'L1HB403', 'L1HP401', 'L1HB402', 'UTEL001')
                                 AND a.SFRSTCR_RSTS_CODE = 'RE'
                                  AND b.SSBSECT_PTRM_START_DATE =
                                         (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                            FROM SSBSECT b1
                                           WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                 AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                            and SFRSTCR_pidm = c.sorlcur_pidm
                            and c.sorlcur_program =   alumno.ID_PROGRAMA
                            and c.SORLCUR_LMOD_CODE = 'LEARNER'
                            And c.SORLCUR_ROLL_IND = 'Y'
                            and c.SORLCUR_CACT_CODE ='ACTIVE'
                            and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
                                                                     from sorlcur c1
                                                                     where c.sorlcur_pidm = c1.sorlcur_pidm
                                                                     and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                                     and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                                     and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                                     and c.sorlcur_program = c1.sorlcur_program)
                            and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
                            and  SFRSTCR_pidm = alumno.SVRPROY_PIDM
--                            And SFRSTCR_TERM_CODE not in (select distinct SZTALGO_TERM_CODE_NEW
--                                                                                from sztalgo
--                                                                                where SZTALGO_NO_REGLA = P_REGLA)
                         GROUP BY SFRSTCR_pidm ;

                     Exception
                         When Others then
                                 Begin
                                     SELECT count (distinct a.SFRSTCR_TERM_CODE) Periodo
                                         Into vl_qa_avance
                                     FROM SFRSTCR a, SSBSECT b, sorlcur c
                                    WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                                          AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                                    --   And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB not  in ('L1HB401', 'IND00001', 'L1HB405', 'L1HB404', 'L1HB403', 'L1HP401', 'L1HB402', 'UTEL001')
                                         AND a.SFRSTCR_RSTS_CODE != 'RE'
                                          AND b.SSBSECT_PTRM_START_DATE =
                                                 (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                                    FROM SSBSECT b1
                                                   WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                         AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                                    and SFRSTCR_pidm = c.sorlcur_pidm
                                    and c.sorlcur_program =   alumno.ID_PROGRAMA
                                    and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                    And c.SORLCUR_ROLL_IND = 'Y'
                                    and c.SORLCUR_CACT_CODE ='ACTIVE'
                                    and c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
                                                                             from sorlcur c1
                                                                             where c.sorlcur_pidm = c1.sorlcur_pidm
                                                                             and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
                                                                             and c.SORLCUR_ROLL_IND = c1.SORLCUR_ROLL_IND
                                                                             and c.SORLCUR_CACT_CODE = c1.SORLCUR_CACT_CODE
                                                                             and c.sorlcur_program = c1.sorlcur_program)
                                    and SFRSTCR_STSP_KEY_SEQUENCE =    c.SORLCUR_KEY_SEQNO
                                    and  SFRSTCR_pidm = alumno.SVRPROY_PIDM
--                                    And SFRSTCR_TERM_CODE not in (select distinct SZTALGO_TERM_CODE_NEW
--                                                                                from sztalgo
--                                                                                where SZTALGO_NO_REGLA = P_REGLA)
                                    GROUP BY SFRSTCR_pidm ;
                                 exception
                                 When Others then
                                   vl_qa_avance :=0;
                                 End;
                           dbms_output.put_line ('Error al recuperar el QA cursado '||sqlerrm);
                         vl_qa_avance :=1;
                     End;

                         dbms_output.put_line (' recuperar el QA cursado '||vl_qa_avance||' Programa '||alumno.ID_PROGRAMA);
          --------- Se obtiene el bimestre que se esta cursando ------------------------

                     vl_parte_bim :=null;


                 If vl_parte_bim is null then
                    vl_parte_bim := vl_tipo_ini;
                 End if;

                 IF vl_qa_avance >= 20 THEN
                    vl_qa_avance:=20;
                 END IF;


                 -- se calcuala el bimestre en donde esta cursando
                 IF vl_qa_avance IN (0,1) THEN

                     l_bim:=1;

                 ELSIF vl_qa_avance> 1 THEN

                     l_bim:=2;

                 END IF;

                 dbms_output.put_line ('Bimestre '||l_bim);

                 DBMS_OUTPUT.PUT_LINE('Entra  al 15 campus '||alumno.campus||' nivel '||alumno.nivel);

                 If vl_parte_bim is  not null then----------> Si no existe parte de periodo no se incluye al alumno

                    --programación para Lic.
                    BEGIN

                        SELECT COUNT(*)
                        INTO l_cuenta_para_campus
                        FROM zstpara
                        WHERE 1 = 1
                        AND zstpara_mapa_id='CAMP_PRONO'
                        and zstpara_param_id  = alumno.campus
                         AND zstpara_param_valor = alumno.nivel
                        AND zstpara_param_valor ='LI';

                    EXCEPTION WHEN OTHERS THEN
                        l_cuenta_para_campus:=0;
                    END;

                    if l_cuenta_para_campus > 0 then


                        IF vl_parte_bim = 2 THEN

                            vl_qa_avance := vl_qa_avance +1;

                            vl_parte_bim := 1;

                        ELSIF  vl_parte_bim = 1 THEN

                            vl_qa_avance := vl_qa_avance +1;

                        ELSIF  vl_parte_bim = 3 THEN

                            vl_qa_avance := vl_qa_avance +1;

                        ELSIF  vl_parte_bim = 0 THEN

                            vl_parte_bim := vl_parte_bim +1;

                        END IF;


                        DBMS_OUTPUT.PUT_LINE('entra a para  avance '||vl_qa_avance||' tipo de Jornada '||vl_tipo_jornada||' tip ini '||vl_tip_ini);

                         For asigna in (
                                         SELECT (sztasgn_crse_numb + sztasgn_opt_numb ) asignacion
                                         FROM sztasgn
                                         WHERE 1 = 1
                                         AND sztasgn_camp_code = alumno.campus
                                         AND sztasgn_levl_code = alumno.nivel
                                         AND sztasgn_qnumb = 'Q'||NVL(vl_qa_avance,1)
                                         AND sztasgn_bim_numb in( 'B'||l_bim)
                                         AND sztasgn_jorn_code = vl_tipo_jornada
                                         AND sztasgn_inso_code = vl_tip_ini

                                        ) loop



                                            vl_contador :=0;

                                            For materia in (

                                                            SELECT DISTINCT a.id_alumno,
                                                                            a.id_ciclo,
                                                                            a.id_programa,
                                                                            a.clave_materia_agp materia,
                                                                            a.secuencia,
                                                                            a.svrproy_pidm,--, a.ID_PERIODO,
                                                                            a.clave_materia materia_banner,
                                                                            a.fecha_inicio,
                                                                            c.study_path,
                                                                            a.rel_alumnos_x_asignar_cuatri cuatrimestre,
                                                                            c.rel_programaxalumno_estatus estatus,
                                                                            a.id_periodo ptrm
                                                            FROM rel_alumnos_x_asignar a,
                                                                 rel_programaxalumno c
                                                            WHERE 1 = 1
                                                            AND a.svrproy_pidm = alumno.svrproy_pidm
                                                            AND a.materias_excluidas = 0
                                                            AND c.sgbstdn_pidm= a.svrproy_pidm
                                                            AND a.id_periodo IS NOT NULL
                                                            AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
                                                            AND a.rel_alumnos_x_asignar_no_regla = p_regla
                                                            AND a.materias_excluidas = 0
                                                            AND  (a.svrproy_pidm, clave_materia, a.rel_alumnos_x_asignar_no_regla)  NOT IN (SELECT sztprono_pidm,
                                                                                                                                                   sztprono_materia_banner,
                                                                                                                                                   sztprono_no_regla
                                                                                                                                            FROM sztprono
                                                                                                                                            where 1 = 1
                                                                                                                                            AND  sztprono_pidm =  a.svrproy_pidm
                                                                                                                                            AND  sztprono_no_regla = p_regla )
                                                            order by 1, cuatrimestre,SECUENCIA , materia
                                                            ) Loop

                                                                vl_contador := vl_contador +1;

                                                                Begin

                                                                    Insert into sztprono values ( materia.SVRPROY_PIDM,
                                                                                                  materia.ID_ALUMNO,
                                                                                                  materia.ID_CICLO,
                                                                                                  materia.ID_PROGRAMA,
                                                                                                  p_materia_legal,
                                                                                                  vl_contador,
                                                                                                  materia.ptrm,
                                                                                                  p_materia_legal,
                                                                                                  'MATERIA',
                                                                                                  materia.FECHA_INICIO,
                                                                                                  'B'||l_bim,
                                                                                                  NULL,
                                                                                                  vl_avance,
                                                                                                  P_REGLA,
                                                                                                  USER,
                                                                                                  materia.STUDY_PATH,
                                                                                                  alumno.RATE,
                                                                                                  alumno.jornada_com,
                                                                                                  sysdate,
                                                                                                  'Q'||vl_qa_avance,
                                                                                                  vl_tip_ini,
                                                                                                  vl_tipo_jornada,
                                                                                                  'S',
                                                                                                  'N',
                                                                                                  materia.estatus,
                                                                                                  'N',
                                                                                                  null,
                                                                                                  null
                                                                                                   );
                                                                    commit;

                                                                EXCEPTION WHEN OTHERS THEN
                                                                    NULL;
                                                                END;
--                                                                Commit;
                                                                exit when vl_contador=1;

                                                            end loop materia;

                                                            DBMS_OUTPUT.PUT_LINE('entra a asgn '||vl_contador||' Asignacion '||ASIGNA.ASIGNACION);

                                                            vl_contador:=0;


                                        end loop asigna;

                    end if;

                    l_cuenta_para_campus:=null;

                    BEGIN

                        SELECT COUNT(*)
                        INTO l_cuenta_para_campus
                        FROM zstpara
                        WHERE 1 = 1
                        AND zstpara_mapa_id='CAMP_PRONO'
                        AND zstpara_param_id  = alumno.campus
                        AND zstpara_param_valor = alumno.nivel
                        AND zstpara_param_valor in('MA','MS','DO');

                    EXCEPTION WHEN OTHERS THEN
                        l_cuenta_para_campus:=0;
                    END;

                    IF l_cuenta_para_campus > 0 THEN
--
--                        IF vl_parte_bim = 2 THEN
--
--                            vl_qa_avance := vl_qa_avance +1;
--                            vl_parte_bim := 1;
--
--                        ELSIF  vl_parte_bim = 1 THEN
--
--                            vl_qa_avance := vl_qa_avance +1;
--
--                        ELSIF  vl_parte_bim = 3 THEN
--
--                            vl_qa_avance := vl_qa_avance +1;
--
--                        ELSIF  vl_parte_bim = 0 THEN
--
--                            vl_parte_bim := vl_parte_bim +1;
--
--                        END IF;
--
--
--                        IF vl_tipo_ini = 0 THEN
--
--                            vl_tip_ini := 'AN';
--
--                        ELSIF vl_tipo_ini IN (1,3, 2,4) THEN
--
--                            vl_tip_ini := 'NO';
--
--                        END IF;

                        vl_asignacion := 0;
                        val_max :=0;

                         IF alumno.periodicidad = 1 THEN

                         dbms_output.put_line ('salida1 '||alumno.campus ||'*'||alumno.NIVEL||'*'||'Q'||vl_qa_avance||'*'||'B'||vl_parte_bim||'*'||vl_tip_ini);

                         DBMS_OUTPUT.PUT_LINE('Entra  al 36 ');


                              BEGIN

                                  SELECT COUNT (DISTINCT sztasma_qnumb)
                                      Into val_max
                                  FROM sztasma
                                  WHERE  1 = 1
                                  AND sztasma_camp_code = alumno.campus
                                  AND sztasma_levl_code = alumno.nivel
                                  AND sztasma_bim_numb is not null;

                                       DBMS_OUTPUT.PUT_LINE('Entra  al 37 val_max '||val_max);
                              EXCEPTION WHEN OTHERS THEN
                                val_max :=0;
                              END;

                              DBMS_OUTPUT.PUT_LINE('Entra  al 38 vl_qa_avance '||vl_qa_avance||' tipo inicio '||vl_tip_ini);

                              IF vl_parte_bim = 4 THEN

                                vl_parte_bim:=2;

                              END IF;

                              --vl_qa_avance := 2;


                         ELSIF alumno.periodicidad = 2 THEN

                           dbms_output.put_line ('salida2 '||alumno.campus ||'*'||alumno.NIVEL||'*'||'Q'||vl_qa_avance||'*'||'B'||vl_parte_bim||'*--> '||vl_tip_ini);

                           DBMS_OUTPUT.PUT_LINE('Entra  al 40 ');

                              BEGIN

                                  SELECT COUNT (DISTINCT sztasma_qnumb)
                                  INTO val_max
                                  FROM sztasma
                                  WHERE sztasma_camp_code = alumno.campus
                                  AND sztasma_levl_code = alumno.nivel
                                  AND sztasma_bim_numb is not null;

                                       DBMS_OUTPUT.PUT_LINE('Entra  al 41 val_max '||val_max);
                              EXCEPTION WHEN OTHERS THEN
                                val_max :=0;
                              END;

                              IF alumno.campus ='UMM' THEN

                                   vl_asignacion :=3;

                              END IF;

--
--                              IF vl_qa_avance >= 3 THEN
--
--                                  vl_asignacion:=3;
--                              elsif vl_qa_avance < 3 then
--
--                                  vl_asignacion:=2;
--
--                              end if;

                         end if;

                         vl_contador :=0;
                                     DBMS_OUTPUT.PUT_LINE('Entra  al 44 aqui avance '||vl_qa_avance);
                                       For materia in (
                                                       SELECT DISTINCT a.id_alumno,
                                                                       a.id_ciclo,
                                                                       a.id_programa,
                                                                       a.clave_materia_agp materia,
                                                                       a.secuencia,
                                                                       a.svrproy_pidm,--, a.ID_PERIODO,
                                                                       a.clave_materia materia_banner,
                                                                       a.fecha_inicio,
                                                                       c.study_path,
                                                                       a.rel_alumnos_x_asignar_cuatri cuatrimestre,
                                                                       rel_programaxalumno_estatus estatus
                                                       FROM rel_alumnos_x_asignar a,
                                                            rel_programaxalumno c
                                                       WHERE 1 = 1
                                                       AND a.svrproy_pidm = alumno.svrproy_pidm
                                                       AND a.materias_excluidas = 0
                                                       AND c.sgbstdn_pidm= a.svrproy_pidm
                                                       AND a.id_periodo is not null
                                                       AND a.rel_alumnos_x_asignar_no_regla  = rel_programaxalumno_no_regla
                                                       AND a.rel_alumnos_x_asignar_no_regla = p_regla
            --                                           and a.ID_ALUMNO='010044146'
                                                       ORDER BY 1, cuatrimestre ,secuencia , materia

                                          ) LOOP

                                                  vl_contador := vl_contador +1;
                                                  dbms_output.put_line ('Contador  ' || vl_contador);
                                                  DBMS_OUTPUT.PUT_LINE('Entra  al 45 estatus '||materia.estatus);



                                                 BEGIN

                                                    SELECT COUNT(*)
                                                    INTO l_cuenta_asma
                                                    FROM ZSTPARA
                                                    WHERE 1 = 1
                                                    AND zstpara_mapa_id ='ASMA_MAT'
                                                    AND zstpara_param_desc ='Q'||vl_qa_avance
                                                    AND zstpara_param_id = materia.id_programa;

                                                 EXCEPTION WHEN OTHERS THEN
                                                    NULL;
                                                 END;

                                                 IF l_cuenta_asma > 0 THEN

                                                     BEGIN

                                                        select DISTINCT zstpara_param_valor
                                                        into vl_asignacion
                                                        FROM zstpara
                                                        WHERE 1 = 1
                                                        AND zstpara_mapa_id ='ASMA_MAT'
                                                        AND zstpara_param_desc ='Q'||vl_qa_avance
                                                        and zstpara_param_id = materia.id_programa;

                                                     EXCEPTION WHEN OTHERS THEN
                                                        NULL;
                                                     END;

                                                 ELSE

                                                     begin

                                                        select count(*)
                                                        into l_cuenta_asma
                                                        from sztasma
                                                        where 1 = 1
                                                        and SZTASMA_CAMP_CODE = alumno.campus
                                                        and SZTASMA_LEVL_CODE = alumno.nivel
                                                        and SZTASMA_PROGRAMA =materia.id_programa;

                                                    exception when others then
                                                        l_cuenta_asma:=0;
                                                    end;



                                                    if l_cuenta_asma > 0  and vl_qa_avance > 5 then

                                                        DBMS_OUTPUT.PUT_LINE('Entra  a asma '||l_cuenta_asma);

                                                        BEGIN
                                                              SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                              INTO vl_asignacion
                                                              FROM sztasma
                                                              WHERE sztasma_camp_code = alumno.campus
                                                              AND sztasma_levl_code = alumno.nivel
                                                              AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                              AND sztasma_bim_numb IS NULL
                                                              AND sztasma_inso_code = vl_tip_ini
                                                              and SZTASMA_PROGRAMA =materia.id_programa;

                                                              DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion);
                                                         EXCEPTION WHEN OTHERS THEN
                                                             vl_asignacion :=0;

                                                              IF alumno.campus ='UMM' THEN
                                                                  vl_asignacion :=3;
                                                              END IF;

                                                         END;

                                                          --cuando pasa del maximo q
                                                         if vl_qa_avance   >= val_max then

                                                            vl_asignacion:=4;

                                                         end if;

                                                    else
                                                        --raise_application_error (-20002,'Error al obtener valores de  spriden  '|| SQLCODE||' Error: '||SQLERRM);


                                                       IF alumno.periodicidad = 1 THEN

                                                            -- VALIDACION PARA CONFIGURACION POR BIMESTRE

                                                             BEGIN
                                                                  SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                                  INTO vl_asignacion
                                                                  FROM sztasma
                                                                  WHERE sztasma_camp_code = alumno.campus
                                                                  AND sztasma_levl_code = alumno.nivel
                                                                  AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                                  AND sztasma_bim_numb = 'B'||l_bim
                                                                  AND sztasma_inso_code = vl_tip_ini
                                                                  and SZTASMA_PROGRAMA IS NULL;

                                                                  DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion);
                                                             EXCEPTION WHEN OTHERS THEN
                                                                 vl_asignacion :=0;

                                                                  IF alumno.campus ='UMM' THEN
                                                                      vl_asignacion :=3;
                                                                  END IF;

                                                             END;

                                                             --cuando pasa del maximo q
                                                             if vl_qa_avance   >= val_max then

                                                                vl_asignacion:=4;

                                                             end if;

                                                       ELSE

                                                             BEGIN
                                                                  SELECT (sztasma_crse_numb + nvl(sztasma_opt_numb,0) ) asignacion
                                                                  INTO vl_asignacion
                                                                  FROM sztasma
                                                                  WHERE sztasma_camp_code = alumno.campus
                                                                  AND sztasma_levl_code = alumno.nivel
                                                                  AND sztasma_qnumb = 'Q'||vl_qa_avance
                                                                  AND sztasma_bim_numb IS NULL
                                                                  AND sztasma_inso_code = vl_tip_ini
                                                                  and SZTASMA_PROGRAMA IS NULL;

                                                                  DBMS_OUTPUT.PUT_LINE('Entra  al 43 vl_asignacion '||vl_asignacion);
                                                             EXCEPTION WHEN OTHERS THEN
                                                                 vl_asignacion :=0;

                                                                  IF alumno.campus ='UMM' THEN
                                                                      vl_asignacion :=3;
                                                                  END IF;

                                                             END;

                                                             --cuando pasa del maximo q
                                                             if vl_qa_avance   >= val_max then

                                                                vl_asignacion:=4;

                                                             end if;

                                                       END IF;

                                                    end if;


                                                 END IF;

                                                 DBMS_OUTPUT.PUT_LINE('Periodicidad '||alumno.PERIODICIDAD||' Periodo 2'||alumno.ID_PERIODO);

                                                 begin

                                                    SELECT COUNT(*)
                                                    INTO l_cuenta_prop
                                                    FROM sztptrm
                                                    WHERE 1 = 1
                                                    AND sztptrm_propedeutico = 1
                                                    AND sztptrm_term_code =materia.id_ciclo
                                                    AND sztptrm_ptrm_code =alumno.id_periodo
                                                    AND sztptrm_program =materia.id_programa;

                                                 exception when others then
                                                    null;
                                                 end;

                                                 DBMS_OUTPUT.PUT_LINE('Periodo '||materia.ID_CICLO||' Ptrm '||alumno.ID_PERIODO||' Programa '||materia.ID_PROGRAMA||' Matricula '||materia.ID_ALUMNO||' Prope '||l_cuenta_prop);
                                                 --macana1

                                                 BEGIN

                                                    SELECT COUNT(*)
                                                    INTO l_cuenta_sfr
                                                    FROM SFRSTCR
                                                    WHERE 1 = 1
                                                    AND sfrstcr_pidm = materia.svrproy_pidm
                                                    AND sfrstcr_stsp_key_sequence =materia.study_path
                                                    AND sfrstcr_rsts_code ='RE';

                                                 EXCEPTION WHEN OTHERS THEN
                                                    NULL;
                                                 END;

                                                 DBMS_OUTPUT.PUT_LINE('Entra  al asma '||l_cuenta_prop||' cuenta matyerias '||l_cuenta_sfr||' Avance '||vl_qa_avance);

--                                                if l_cuenta_prop >= 1 /*and vl_qa_avance =1*/ and materia.estatus IN('N','F') and l_cuenta_sfr = 0 then
--
--                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 47000 '||l_cuenta_prop);
--
--                                                      BEGIN
--                                                                  INSERT INTO sztprono VALUES ( materia.svrproy_pidm,
--                                                                                                materia.id_alumno,
--                                                                                                materia.id_ciclo,
--                                                                                                materia.id_programa,
--                                                                                                'M1HB401',
--                                                                                                vl_contador,
--                                                                                                alumno.id_periodo,
--                                                                                                'M1HB401',
--                                                                                                'x',
--                                                                                                materia.fecha_inicio,
--                                                                                                null,
--                                                                                                null,
--                                                                                                vl_avance,
--                                                                                                p_regla,
--                                                                                                user,
--                                                                                                materia.study_path,
--                                                                                                alumno.rate,
--                                                                                                alumno.jornada_com,
--                                                                                                sysdate,
--                                                                                                'Q'||vl_qa_avance,
--                                                                                                vl_tip_ini,
--                                                                                                vl_tipo_jornada,
--                                                                                                'N',
--                                                                                                'N',
--                                                                                                materia.estatus,
--                                                                                                'N',
--                                                                                                null,
--                                                                                                null
--                                                                                                );
----                                                      COMMIT;
--
--                                                      EXCEPTION WHEN OTHERS THEN
--                                                         NULL;
--                                                      END;
--
--                                                    EXIT WHEN vl_contador=1;
--
--                                                ELSE

                                                      DBMS_OUTPUT.PUT_LINE('Entra  al 48000 '||l_cuenta_prop);

                                                      BEGIN
                                                                  INSERT INTO sztprono VALUES ( materia.svrproy_pidm,
                                                                                                materia.id_alumno,
                                                                                                materia.id_ciclo,
                                                                                                materia.id_programa,
                                                                                                p_materia_legal,
                                                                                                vl_contador,
                                                                                                alumno.id_periodo,
                                                                                                p_materia_legal,
                                                                                                'MATERIA',
                                                                                                materia.fecha_inicio,
                                                                                                'B'||l_bim,
                                                                                                null,
                                                                                                vl_avance,
                                                                                                p_regla,
                                                                                                user,
                                                                                                materia.study_path,
                                                                                                alumno.rate,
                                                                                                alumno.jornada_com,
                                                                                                sysdate,
                                                                                                'Q'||vl_qa_avance,
                                                                                                vl_tip_ini,
                                                                                                vl_tipo_jornada,
                                                                                                'S',
                                                                                                'N',
                                                                                                materia.estatus,
                                                                                                'N',
                                                                                                null,
                                                                                                null
                                                                                                );

--                                                        commit;
                                                      EXCEPTION  WHEN OTHERS THEN
                                                         NULL;
                                                      END;


                                                       DBMS_OUTPUT.PUT_LINE('Macana Semis '||l_semis||' Programa  '||materia.ID_PROGRAMA||' Ptrm'||alumno.ID_PERIODO);

                                                      COMMIT;


                                                    EXIT WHEN vl_contador=vl_asignacion;

--                                                END IF;
                                                 --banda


                                          END LOOP Materia;
                                          vl_contador :=0;

                            dbms_output.put_line ('Entra a Maestria Parte de bimestre ' ||vl_parte_bim);

                    END IF;




                 End if;

            Else
                     null;
              dbms_output.put_line ('Entra a Maestria Parte de bimestre ' ||vl_parte_bim);
            End if;

            DBMS_OUTPUT.PUT_LINE('Itera  '||l_itera);


      End Loop alumno;

      commit;

    else

        raise_application_error (-20002,' Esta Materia no esta en su dashboard, por favor revisa SIU para ver que materias puede tomar');


    end if;

 END;

 --
 --
 PROCEDURE p_prereq(p_regla NUMBER,
                    p_pidm  number)
    AS
        l_contar_pr   NUMBER:=0;

    BEGIN


        FOR C IN (SELECT *
                  FROM rel_alumnos_x_asignar
                  WHERE 1 = 1
                  AND rel_alumnos_x_asignar_no_regla = p_regla
                  AND SVRPROY_PIDM = p_pidm
                  )
                   LOOP

                       BEGIN

                           SELECT COUNT(*)
                           INTO l_contar_pr
                           FROM scrrtst
                           WHERE 1 = 1
                           AND scrrtst_subj_code||scrrtst_crse_numb = c.clave_materia;

                       EXCEPTION WHEN OTHERS THEN
                           NULL;
                       END;

                       IF l_contar_pr >0 THEN

                           FOR d IN ( SELECT  *
                                      FROM scrrtst
                                      WHERE 1 = 1
                                      AND scrrtst_subj_code||scrrtst_crse_numb = c.clave_materia
                                     )LOOP

                                        FOR x IN (
                                                   SELECT rde.shrgrde_passed_ind aprodado,
                                                          ct.ssbsect_crn crn,
                                                          ct.ssbsect_term_code term_code,
                                                          shrgrde_code calificacion
                                                   FROM  ssbsect ct
                                                   JOIN  sfrstcr cr ON  cr.sfrstcr_term_code = ct.ssbsect_term_code
                                                                    AND cr.sfrstcr_term_code = ct.ssbsect_term_code
                                                                    AND cr.sfrstcr_crn =ct.ssbsect_crn
                                                   JOIN shrgrde rde ON  rde.shrgrde_levl_code = cr.sfrstcr_levl_code
                                                                    AND rde.shrgrde_code =  cr.sfrstcr_grde_code
                                                   WHERE 1 = 1
                                                   AND ssbsect_subj_code||ssbsect_crse_numb =d.scrrtst_subj_code_preq||d.scrrtst_crse_numb_preq
                                                   AND sfrstcr_pidm = c.svrproy_pidm
                                                   AND sfrstcr_rsts_code ='RE'

                                                 )
                                                 LOOP

                                                       IF x.aprodado ='N' THEN

                                                           BEGIN

                                                               DELETE rel_alumnos_x_asignar
                                                               WHERE 1  = 1
                                                               AND rel_alumnos_x_asignar_no_regla = c.rel_alumnos_x_asignar_no_regla
                                                               AND clave_materia =c.clave_materia
                                                               AND svrproy_pidm =c.svrproy_pidm;


                                                           EXCEPTION WHEN OTHERS THEN
                                                               NULL;
                                                           END;

                                                       END IF;

                                                 END LOOP;


                                     END LOOP;

                       END  IF;

                   END LOOP;

                   COMMIT;

    END;
--
--
    procedure p_ejecutivo_pidm (P_REGLA NUMBER, p_pidm  NUMBER)
    is
        l_contar            number;
        l_cuneta_semi       number;
        l_contador          number:=0;
        l_diferencia_grupo  number;
        l_short_name        varchar2(30);
        l_prof              varchar2(20);
        l_pidm              number;
        l_pwd               varchar2(100);
        l_pwd_alumno        varchar2(100);
        l_cuenta_grupo      number;
        l_cuenta_grupo_ieps number;
        l_cuenta_nivel      number;
        l_nivel             varchar2(2);
        l_contar_ejecutivos number:=0;
        l_contar_cesa       number:=0;
        l_cuenta_alol       number;
        l_cuenta_prono      number;
        l_fecha_inicio      date;
        l_cuenta_unicef     number;
        l_cueneta_prope     number;
        l_cueneta_cesa      NUMBER;
    BEGIN

       --raise_application_error (-20002,'No se cargaron materias desde el dashboard');

       begin

           select count(*)
           into l_cuenta_nivel
           from sztalgo
           where 1 = 1
           and sztalgo_no_regla = p_regla
           and SZTALGO_LEVL_CODE ='LI';

       exception when others then
           l_cuenta_nivel:=0;
       end;


       IF l_cuenta_nivel > 0 THEN

           l_nivel :='LI';
       ELSE

           l_nivel :='MA';
       END IF;

        BEGIN


            select count(*)
            into l_contar_ejecutivos
            from szstume
            where 1 = 1
            and szstume_no_regla = p_regla
            and szstume_pidm = p_pidm
            and szstume_subj_code in (select
                                        ZSTPARA_PARAM_ID materia
                                     from ZSTPARA
                                     where 1 = 1
                                     and ZSTPARA_MAPA_ID = 'MATERIAS_EXTRAC'
                                     AND ZSTPARA_PARAM_DESC =l_nivel);


        exception when others then
            null;
        end;

        BEGIN


            select count(*)
            into l_contar_cesa
            from szstume
            where 1 = 1
            and szstume_no_regla = p_regla
            and szstume_pidm = p_pidm
            and szstume_subj_code in (select
                                        ZSTPARA_PARAM_ID materia
                                     from ZSTPARA
                                     where 1 = 1
                                     and ZSTPARA_MAPA_ID = 'MATERIAS_CESA'
                                     AND ZSTPARA_PARAM_DESC =l_nivel);


        exception when others then
            null;
        end;

        dbms_output.put_line('Cuenta ejecutivos '||l_contar_ejecutivos||' Contar Cesa '||l_contar_cesa);

        if l_contar_ejecutivos = 0 or l_contar_cesa = 0 then

          -- raise_application_error (-20002,'entra 1');

           DELETE sztsemi
           WHERE 1 = 1
           AND sztsemi_NO_REGLA = P_REGLA
           and sztsemi_pidm = p_pidm;

           COMMIT;


           for c in (select distinct a.szstume_id matricula,
                                     a.szstume_pidm pidm,
                                     b.SZTPRONO_PROGRAM programa,
                                     b.SZTPRONO_FECHA_INICIO fecha_inicio
                 from szstume a
                 join sztprono b on a.szstume_pidm = b.sztprono_pidm
                              and a.szstume_no_regla = b.sztprono_no_regla
                 where 1 = 1
                 and a.szstume_no_regla = p_regla
                 and a.szstume_pidm = p_pidm
                 order by 1
                 )loop


                     BEGIN
                         SELECT COUNT(*)
                         INTO l_cuneta_semi
                         FROM sztdtec
                         WHERE 1 = 1
                         AND SZTDTEC_PROGRAM = C.programa
                         AND SZTDTEC_MOD_TYPE ='S';
                     EXCEPTION WHEN OTHERS THEN
                         NULL;
                     END;

                      dbms_output.put_line('entra semi '||l_cuneta_semi);

                     IF l_cuneta_semi > 0 THEN


                         l_contador:=l_contador+1;

                         BEGIN

                             INSERT INTO sztsemi VALUES(
                                                         c.pidm,
                                                         c.matricula,
                                                         c.programa,
                                                         l_contador,
                                                         p_regla,
                                                         sysdate,
                                                         user
                                                       );
                         EXCEPTION WHEN OTHERS THEN
                             dbms_output.put_line('Error '||sqlerrm);
                         END;

                     END IF;
--
                     begin

                        select distinct sztalol_fecha_inicio
                        into l_fecha_inicio
                        from SZTALOL
                        where 1 = 1
                        and sztalol_pidm = c.pidm
                        and SZTALOL_ESTATUS ='A';

                    exception when others then
                        null;
                    end;

                    dbms_output.put_line('Fecha Inicio variable  '||l_fecha_inicio||' fecha inicio cursor '||c.fecha_inicio);

                    if l_fecha_inicio > c.fecha_inicio  then

                      null;

                    elsif l_fecha_inicio <=  c.fecha_inicio then

                      update sztalol set sztalol_no_regla = p_regla,
                                         sztalol_fecha_inicio =c.fecha_inicio
                      where 1 = 1
                      and sztalol_pidm = c.pidm
                      and SZTALOL_ESTATUS ='A';

                    end if;


                 end loop;

                 begin

                   select count(*)
                   into l_contar
                   from sztsemi
                   where 1 = 1
                   and sztsemi_no_regla = p_regla;


                 exception when others then
                   null;
                 end;


--                 if l_contar > 0 then

                   l_contador:=0;

                   for c in (select ZSTPARA_PARAM_SEC secuencia,
                                    ZSTPARA_PARAM_ID materia,
                                    ZSTPARA_PARAM_DESC descripcion,
                                    ZSTPARA_PARAM_VALOR grupo
                             from ZSTPARA
                             where 1 = 1
                             and ZSTPARA_MAPA_ID = 'MATERIAS_EXTRAC'
                             AND ZSTPARA_PARAM_DESC = l_nivel
                           )loop

                                   dbms_output.put_line('entra a materias pako');


                                   for d in (select *
                                             from sztgpme
                                             where 1 = 1
                                             and sztgpme_no_regla = p_regla
                                             and SZTGPME_SUBJ_CRSE in (select  ZSTPARA_PARAM_ID materia
                                                                       from ZSTPARA
                                                                       where 1 = 1
                                                                       and ZSTPARA_MAPA_ID = 'MATERIAS_EXTRAC'
                                                                       AND ZSTPARA_PARAM_DESC = l_nivel)
                                             )loop

                                               l_contador:=l_contador+1;


                                                dbms_output.put_line('entra a materias semi 2pako2'||C.MATERIA||C.GRUPO);

                                                 for x in (select distinct sztsemi_pidm pidm,
                                                                        SZTSEMI_ID matricula
                                                            from sztsemi
                                                            where 1 = 1
                                                            and sztsemi_no_regla = p_regla
                                                            and sztsemi_pidm = p_pidm
--                                                             AND NOT EXISTS (select null
--                                                                             from goradid
--                                                                             where 1 = 1
--                                                                             and goradid_pidm = sztsemi_pidm
--                                                                             and GORADID_ADID_CODE ='CESA')
                                                            union
                                                            select distinct sztalol_pidm pidm,
                                                                            sztalol_id matricula
                                                            from sztalol
                                                            where 1 = 1
                                                            and sztalol_no_regla = p_regla
                                                            AND sztalol_pidm = p_pidm
                                                            and SZTALOL_ESTATUS ='A'
--                                                            AND NOT EXISTS (select null
--                                                                            from goradid
--                                                                            where 1 = 1
--                                                                            and goradid_pidm = sztalol_pidm
--                                                                            and GORADID_ADID_CODE ='CESA')
                                                           )loop

                                                                   begin

                                                                       select GOZTPAC_PIN
                                                                       into l_pwd_alumno
                                                                       from GOZTPAC pac
                                                                       where 1 = 1
                                                                       and pac.GOZTPAC_pidm =x.pidm
                                                                       and rownum = 1;

                                                                   exception when others then
                                                                       null;
                                                                   end;



                                                                   begin
                                                                        dbms_output.put_line('INSERTA EN SZSTUME');
                                                                          insert into SZSTUME values(c.materia||c.grupo,
                                                                                                     x.pidm,
                                                                                                     x.matricula,
                                                                                                     sysdate,
                                                                                                     user,
                                                                                                     0,
                                                                                                     null,
                                                                                                     l_pwd_alumno,
                                                                                                     null,
                                                                                                     1,
                                                                                                     'RE',
                                                                                                     0,
                                                                                                     c.materia,
                                                                                                     null,-- c.nivel,
                                                                                                     null,
                                                                                                     null,--  c.ptrm,
                                                                                                     null,
                                                                                                     null,
                                                                                                     null,
                                                                                                     null,
                                                                                                     c.materia,
                                                                                                     d.SZTGPME_START_DATE,--  c.inicio_clases,
                                                                                                     P_REGLA,
                                                                                                     1,
                                                                                                     1,
                                                                                                     0,
                                                                                                     null
                                                                                                     );



                                                                   exception when others then
                                                                        dbms_output.put_line(' Error al insertar '||sqlerrm);
                                                                   end;

                                                                  --dbms_output.put_line('Inserta alumno '||x.SZTSEMI_ID);

                                                           end loop;


                                                 exit when  l_contador= c.secuencia;

                                             end loop;


                           end loop;

           dbms_output.put_line('entra a materias cesa 0 ');

           for c in (select ZSTPARA_PARAM_SEC secuencia,
                                    ZSTPARA_PARAM_ID materia,
                                    ZSTPARA_PARAM_DESC descripcion,
                                    ZSTPARA_PARAM_VALOR grupo
                             from ZSTPARA
                             where 1 = 1
                             and ZSTPARA_MAPA_ID = 'MATERIAS_CESA'
                             AND ZSTPARA_PARAM_DESC = l_nivel
                           )loop

                                  dbms_output.put_line('entra a materias cesa 1 ');


                                  --raise_application_error (-20002,'Entra 100');


                                   for d in (select *
                                             from sztgpme
                                             where 1 = 1
                                             and sztgpme_no_regla = p_regla
                                             and SZTGPME_SUBJ_CRSE in (select  ZSTPARA_PARAM_ID materia
                                                                       from ZSTPARA
                                                                       where 1 = 1
                                                                       and ZSTPARA_MAPA_ID = 'MATERIAS_CESA'
                                                                       AND ZSTPARA_PARAM_DESC = l_nivel)
                                             )loop

                                               l_contador:=l_contador+1;


                                               --raise_application_error (-20002,'Entra 2');

                                                dbms_output.put_line('entra a materias semi 2');

                                                 for x in (
                                                             select distinct a.sztalol_pidm pidm,
                                                                            a.sztalol_id matricula,
                                                                            (SELECT DISTINCT c.sztprono_ptrm_code
                                                                             FROM sztprono c
                                                                             WHERE     1 = 1
                                                                             AND c.sztprono_no_regla = a.sztalol_no_regla
                                                                             AND c.sztprono_pidm = a.sztalol_pidm
                                                                             AND ROWNUM = 1) ptrm
                                                            from sztalol a
                                                            where 1 = 1
                                                            and a.sztalol_no_regla = p_regla
                                                            AND sztalol_pidm = p_pidm
                                                            and a.SZTALOL_ESTATUS ='A'
                                                            AND EXISTS (select null
                                                                            from goradid b
                                                                            where 1 = 1
                                                                            and b.goradid_pidm = a.sztalol_pidm
                                                                            and b.GORADID_ADID_CODE ='CESA')
                                                           )loop

                                                               if x.ptrm in ('L1E','L1A','L2A','M1A','A1A','L0A','M0B','A0B') then

                                                                   begin

                                                                       select GOZTPAC_PIN
                                                                       into l_pwd_alumno
                                                                       from GOZTPAC pac
                                                                       where 1 = 1
                                                                       and pac.GOZTPAC_pidm =x.pidm
                                                                       and rownum = 1;

                                                                   exception when others then
                                                                       null;
                                                                   end;

                                                                --   raise_application_error (-20002,'Entra 3');

                                                                   begin

                                                                          insert into SZSTUME values(c.materia||c.grupo,
                                                                                                     x.pidm,
                                                                                                     x.matricula,
                                                                                                     sysdate,
                                                                                                     user,
                                                                                                     0,
                                                                                                     null,
                                                                                                     l_pwd_alumno,
                                                                                                     null,
                                                                                                     1,
                                                                                                     'RE',
                                                                                                     0,
                                                                                                     c.materia,
                                                                                                     null,-- c.nivel,
                                                                                                     null,
                                                                                                     null,--  c.ptrm,
                                                                                                     null,
                                                                                                     null,
                                                                                                     null,
                                                                                                     null,
                                                                                                     c.materia,
                                                                                                     d.SZTGPME_START_DATE,--  c.inicio_clases,
                                                                                                     P_REGLA,
                                                                                                     1,
                                                                                                     1,
                                                                                                     0,
                                                                                                     null
                                                                                                     );



                                                                   exception when others then
                                                                        dbms_output.put_line(' Error al insertar '||sqlerrm);
                                                                   end;

                                                                  --dbms_output.put_line('Inserta alumno '||x.SZTSEMI_ID);

                                                               end if;

                                                           end loop;


                                                 exit when  l_contador= c.secuencia;

                                             end loop;


                           end loop;


           begin

            select count(*)
            into l_cuenta_unicef
            from sztprono
            where 1 = 1
            and sztprono_no_regla = P_REGLA
            and sztprono_pidm = p_pidm
            AND SZTPRONO_MATERIA_LEGAL='UNICM01'
            and exists(select null
                       from sztalmt
                       where 1 = 1
                       and sztalmt_materia= sztprono_materia_legal
                       and SZTALMT_ALIANZA not in ('COUR','TAEX'));

           exception when others then
                null;
           end;

             dbms_output.put_line('entra a materias  CUENTA UNICEF' ||l_cuenta_unicef);


           begin

            select count(*)
            into l_cueneta_prope
            from sztprono
            where 1 = 1
            and sztprono_no_regla = P_REGLA
            and sztprono_pidm = p_pidm
            and sztprono_materia_legal like 'M1HB401%';

           exception when others then
                null;
           end;


           begin

            select count(*)
            into l_cueneta_cesa
            from szstume
            where 1 = 1
            and szstume_no_regla = P_REGLA
            and szstume_pidm = p_pidm
            and szstume_subj_code like 'CESA%';

           exception when others then
                null;
           end;

           if l_cuenta_unicef = 1  and l_nivel ='LI' then
               dbms_output.put_line('BORRA UNICEF 1');
                delete szstume
                where 1 = 1
                and szstume_no_regla = p_regla
                and szstume_pidm = p_pidm
                and szstume_subj_code in (select  distinct ZSTPARA_PARAM_ID materia
                                                                      from ZSTPARA
                                                                      where 1 = 1
                                                                      and ZSTPARA_MAPA_ID = 'EJECUTIVAS_INTR');


           elsif l_cuenta_unicef = 2 and l_nivel ='LI' then

              dbms_output.put_line('BORRA UNICEF 2');
                delete szstume
                where 1 = 1
                and szstume_no_regla = p_regla
                and szstume_pidm = p_pidm
                and szstume_subj_code in ('SEL001','SEL002');



           end if;

           if l_cuenta_unicef = 1  and l_nivel ='MA' then
                dbms_output.put_line('BORRA UNICEF 3');
                delete szstume
                where 1 = 1
                and szstume_no_regla = p_regla
                and szstume_pidm = p_pidm
--                AND szstume_subj_code='SEM002'
                and szstume_subj_code in (select  distinct ZSTPARA_PARAM_ID materia
                                                                      from ZSTPARA
                                                                      where 1 = 1
                                                                      and ZSTPARA_MAPA_ID = 'EJECUTIVAS_INTR');


           elsif l_cuenta_unicef = 2 and l_nivel ='MA' then
             dbms_output.put_line('BORRA UNICEF 4');

                delete szstume
                where 1 = 1
                and szstume_no_regla = p_regla
                and szstume_pidm = p_pidm
                and szstume_subj_code in ('SEM001','SEM002');


           end if;

           if l_cueneta_prope > 0 and l_nivel ='MA' then
           dbms_output.put_line('BORRA UNICEF 5');
                delete szstume
                where 1 = 1
                and szstume_no_regla = p_regla
                and szstume_pidm = p_pidm
                and szstume_subj_code in (select  distinct ZSTPARA_PARAM_ID materia
                                                                      from ZSTPARA
                                                                      where 1 = 1
                                                                      and ZSTPARA_MAPA_ID = 'EJECUTIVAS_INTR');
           end if;


           if l_cueneta_cesa > 0 and l_nivel IN ('LI','MA') then
                dbms_output.put_line('BORRA UNICEF 6');
                delete szstume
                where 1 = 1
                and szstume_no_regla = p_regla
                and szstume_pidm = p_pidm
                and szstume_subj_code in (select  distinct ZSTPARA_PARAM_ID materia
                                                                      from ZSTPARA
                                                                      where 1 = 1
                                                                      and ZSTPARA_MAPA_ID = 'EJECUTIVAS_INTR');
           end if;

           if l_cuenta_unicef > 2 and l_nivel in('MA','DO','LI') then
               dbms_output.put_line('BORRA UNICEF 7');
                delete szstume
                where 1 = 1
                and szstume_no_regla = p_regla
                and szstume_pidm = p_pidm
--                AND szstume_subj_code='SEL002'
                and szstume_subj_code in (select  distinct ZSTPARA_PARAM_ID materia
                                          from ZSTPARA
                                          where 1 = 1
                                          and ZSTPARA_MAPA_ID = 'EJECUTIVAS_INTR');

           end if;

           if l_cuenta_unicef > 1 and l_nivel in('MA','DO','LI') then

                delete szstume
                where 1 = 1
                and szstume_no_regla = p_regla
                and szstume_pidm = p_pidm
                and exists (select null
                           from sztalmt
                           where 1 = 1
                           and SZTALMT_MATERIA = szstume_subj_code
                           and SZTALMT_ALIANZA ='EJEC');

           end if;


           commit;

        end if;


        commit;

    END;
--
--
    function f_up_selling(p_fecha_inicio date,
                          p_programa varchar2,
                          p_pidm  number,
                          p_nivel varchar2) return varchar2
    is
        l_retorna     varchar2(500):='EXITO';
        l_matricula   varchar2(10);
        l_contador    number;
        l_regla       number;
        l_pwd_alumno varchar2(500);

        l_nivel      varchar2(2);
    begin

        begin

            select spriden_id
            into l_matricula
            from spriden
            where 1 =  1
            and spriden_change_ind is null
            and spriden_pidm = p_pidm;

        exception when others then
            null;
        end;

        BEGIN

            l_contador:=l_contador+1;

            INSERT INTO sztalol  VALUES(
                                        p_pidm,
                                        l_matricula,
                                        p_programa,
                                        p_fecha_inicio,
                                        p_fecha_inicio,
                                        null,
                                        sysdate,
                                        user,
                                        'A'
                                      );
        EXCEPTION WHEN OTHERS THEN
            l_retorna:=('Error '||sqlerrm);
        END;


        if l_retorna ='EXITO' then

            commit;
        else

            rollback;
        end if;

        return(l_retorna);

    end;
--
--
    function f_valida_ups(p_fecha_inicio date,
                          p_pidm  number,
                          p_campus varchar,
                          p_nivel  varchar
                          ) return varchar2
    is
        l_retorna         varchar2(200);
        l_cuenta_szstume1  number;
        l_cuenta_szstume2  number;
        l_regla           number;
        l_nivel           varchar2(2);
        l_cuenta_nivel    number;
    begin


      --  insert into borrame(PIDM,FECHA_INICIO,OBSERVACION) values (p_pidm,p_fecha_inicio,p_fecha_inicio);

       -- commit;

       begin

        select DISTINCT sztalgo_no_regla
        into l_regla
       from sztalgo
       where 1 = 1
       and SZTALGO_FECHA_NEW = p_fecha_inicio
       and sztalgo_camp_code = p_campus
       and SZTALGO_LEVL_CODE = p_nivel;

       exception when others then
           l_regla := 0;
       end;

       dbms_output.put_line('Regla '||l_regla);

       begin

           select count(*)
           into l_cuenta_nivel
           from sztalgo
           where 1 = 1
           and sztalgo_no_regla = l_regla
           and SZTALGO_LEVL_CODE ='LI';

       exception when others then
           l_cuenta_nivel:=0;
       end;


       IF l_cuenta_nivel > 0 THEN

           l_nivel :='LI';
       ELSE

           l_nivel :='MA';
       END IF;


       begin

           select count(*)
           into l_cuenta_szstume1
           from szstume
           where 1 = 1
           and SZSTUME_no_regla = l_regla
           and szstume_pidm = p_pidm
           and SZSTUME_SUBJ_CODE in (select  ZSTPARA_PARAM_ID materia
                                                                      from ZSTPARA
                                                                      where 1 = 1
                                                                      and ZSTPARA_MAPA_ID = 'MATERIAS_EXTRAC'
                                                                      AND ZSTPARA_PARAM_DESC = l_nivel);
       exception when others then
           null;
       end;

       begin

           select count(*)
           into l_cuenta_szstume2
           from szstume
           where 1 = 1
           and SZSTUME_no_regla = l_regla
           and szstume_pidm = p_pidm;

       exception when others then
           null;
       end;


       if l_regla <> 0 then


           if l_cuenta_szstume2 > 0  and  l_cuenta_szstume1 = 0  then

               l_retorna:='N';

           elsif l_cuenta_szstume1 = 0 and l_cuenta_szstume2 = 0 then

               l_retorna:='N';


           elsif l_cuenta_szstume2 = 0 and l_cuenta_szstume1 =0 then

               l_retorna:='P';

           else


               l_retorna:='S';

           end if;

       else

           l_retorna:=p_fecha_inicio;

       end if;

       return(l_retorna);

    end;
--
--
 PROCEDURE p_alianzas_pronostico_pidm(P_REGLA NUMBER,
                                      p_pidm  NUMBER)
    as
    p_alianza varchar(10);
       l_avance              number;

 begin

       dbms_output.put_line('Entra a p_alianzas_pronostico_pidm -->'||1);

    for c in ( SELECT distinct (SELECT  SUBSTR(SMRPRLE_PROGRAM_DESC,1,1)||lower(SUBSTR(SMRPRLE_PROGRAM_DESC,1,100))
                            FROM SMRPRLE
                            WHERE 1 = 1
                            AND SMRPRLE_PROGRAM = SZTPRONO_PROGRAM) nombre,
                            SZTPRONO_PROGRAM programa,
                            sztprono_pidm pidm,
                            sztprono_id matricula,
                             SZTPRONO_CUATRI||','||SZTPRONO_PTRM_CODE_NW avance,
                            sztalmt_alianza alianza, --'CIFA' alianza,
                            SZTPRONO_TIPO_INICIO tipo_inicio,
                            sztprono_no_regla regla
                    FROM sztprono
                    join sztalmt on sztalmt_materia=sztprono_materia_legal
                    WHERE 1 = 1
                    AND sztprono_no_regla = p_regla
                    and sztprono_pidm = p_pidm
                    AND EXISTS (SELECT NULL
                                FROM GORADID
                                WHERE 1 = 1
                                AND GORADID_PIDM = SZTPRONO_PIDM
                                AND  GORADID_ADID_CODE = sztalmt_alianza) --='CIFA')
                    )loop


                        BEGIN

                          SELECT MAX(zstpara_param_id)
                          INTO l_avance
                          FROM ZSTPARA
                          WHERE 1 = 1
                          AND zstpara_mapa_id ='INSCRIPCIONES'
                          AND zstpara_param_valor = c.avance
                          AND zstpara_param_desc = c.tipo_inicio;

                        exception when others then
                            null;
                        end;

                        BEGIN


                        -- dbms_output.put_line (' PImd '||d.pidm||' Matricula '||d.matricula||'  Alianza '||c.alianza||' Avance '||l_avance||' Regla '||d.regla||' materias para '||l_materias_para||' matereias alianza '||l_materias_alianza||' Tipo Inicio '||d.tipo_inicio);

                          INSERT INTO sztalian VALUES (c.pidm,
                                                       c.matricula,
                                                       c.programa,
                                                       c.alianza,
                                                       l_avance,
                                                       c.regla,
                                                       'N',
                                                       0,
                                                       0,
                                                       c.tipo_inicio,
                                                       'PR'
                                                       );

                        EXCEPTION WHEN OTHERS THEN
                         NULL;
                        END;

                        COMMIT;
                    end loop;


    FOR pob IN (
            SELECT distinct SZTALIAN_ALIANZA alianza,
                            SZTALIAN_ID matricula,
                            sztalian_no_regla regla,
                            sztalian_pidm pidm
               FROM sztalian
               where 1 = 1
               AND sztalian_flex ='PD'
               AND sztalian_no_regla = p_regla
               AND sztalian_pidm = p_pidm
    ) LOOP

       if pob.alianza = p_alianza Then continue; end if;

       p_alianza := pob.alianza;

            if pob.alianza in ('CIFA','MUBA','UNIC','IEBS','MONU','FCBK') Then

                dbms_output.put_line('CarruselAlum:'||pob.matricula||' Alianza:'||pob.alianza||' Regla:'||pob.regla);

                pkg_alianzas.p_carrusel_pidm(pob.regla,pob.alianza,pob.pidm);
            end if;

            if pob.alianza in ('EJEC','SENI','GADS','MICR','TABL','CLOU','CESA','COUR','COLL') Then
                dbms_output.put_line('NOCarruselAlum:'||pob.matricula||' Alianza:'||pob.alianza||' Regla:'||pob.regla);

                pkg_alianzas.p_no_carrusel_pidm(pob.regla,pob.alianza,pob.pidm);
            end if;

    END LOOP;
end;

end PKG_ALGORITMO_PIDM_DIPCUR;
/

DROP PUBLIC SYNONYM PKG_ALGORITMO_PIDM_DIPCUR;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ALGORITMO_PIDM_DIPCUR FOR BANINST1.PKG_ALGORITMO_PIDM_DIPCUR;
