DROP PACKAGE BODY BANINST1.PKG_VALIDA_PRONO;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_valida_prono
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


     Begin
            delete tmp_valida_faltantes
            where pidm = ppidm
            And PROGRAMA = pprograma
            and regla  = p_regla;
     Exception
        When Others then
            null;
     End;


       v_cur := BANINST1.PKG_DASHBOARD_ALUMNO.F_DASHBOARD_AVCU_OUT_prono ( ppidm,pprograma,'PRONO');

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
   
end;
/

DROP PUBLIC SYNONYM PKG_VALIDA_PRONO;

CREATE OR REPLACE PUBLIC SYNONYM PKG_VALIDA_PRONO FOR BANINST1.PKG_VALIDA_PRONO;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_VALIDA_PRONO TO PUBLIC;
