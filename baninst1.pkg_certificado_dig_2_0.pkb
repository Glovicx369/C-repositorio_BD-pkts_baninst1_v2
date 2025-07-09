DROP PACKAGE BODY BANINST1.PKG_CERTIFICADO_DIG_2_0;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_CERTIFICADO_DIG_2_0
AS
   /*   se modifico paraa la version del MEC 2.0  13 febero 2019   glovicx
   ultima version 17/09/2019 se hace para liberar la version de firmado de SIU.
   modifica glovicx 19/05/2020 van los cambio para los nuevos programas segem que contienen una letra al final de las materias de segem
   última modificación 25/05/2020  se corrige los ID_materias que no salian
   ÚLTIMA MODIFICACION 07072020 SE AJUSTO PARA CERTIFICADOS PARCIALES CUALQUIER ESTATUS DEL ALUMNO glovicx
   modif 25 ene 2021 par aque acepte las calificaciones alfanumericas como "AC"  glovicx
   modif 31/03/2021  se cambia p_inicio una nueva regla para los certifcados paciales y totales glovicx
   modif 25/03/022 se sealiza el ajuste para que tome los representantes legales de forma automatica segun los
   parametros que se le envian desde la forma glovicx 25/03/022
    */

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
   vxml_inicio          VARCHAR2 (400);
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
   nombre_mat           VARCHAR2 (100);
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
   v_fech_exp           VARCHAR2 (30);
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
   p_responsable        number;
    vpromediox     float := 0.0;
    vsumcalif  number:= 0;
    vnumate   number:= 0;
    pmodo    NUMBER:= 0;
    
   ------------------------------------------------------------------NUEVA VERSION CAMBIO DE TABLA-----------------------
   CURSOR c_alumnos (pprograma  VARCHAR2, ppidm  NUMBER) IS
        SELECT f.SZTRECE_PIDM_CERTIF AS pidm,
               f.SZTRECE_PROGRAM_CERTIF AS programa,
               PE.SPBPERS_SEX SEXO
          FROM SZTRECE F, SPBPERS PE
         WHERE     F.SZTRECE_PIDM_CERTIF = PE.SPBPERS_PIDM
               AND F.SZTRECE_PROGRAM_CERTIF = pprograma
               ---IF pindica = 3 then-----ENTONCES ES UN REPROCESO
               AND SZTRECE_XML_IND =
                      (SELECT DECODE (pindica,
                                      3, 'NOT NULL',
                                      2, 'is null',
                                      1, 'is null')
                         FROM DUAL) -----cero significa que aun no se genera su archivo xml
               AND F.SZTRECE_PIDM_CERTIF = NVL (ppidm, F.SZTRECE_PIDM_CERTIF)
      ORDER BY 1 DESC;

   CURSOR c_alumnos2 (
      pprograma    VARCHAR2,
      ppidm        NUMBER)
   IS
        SELECT f.SZTRECE_PIDM_CERTIF AS pidm,
               f.SZTRECE_PROGRAM_CERTIF AS programa,
               PE.SPBPERS_SEX SEXO
          FROM SZTRECE F, SPBPERS PE
         WHERE     F.SZTRECE_PIDM_CERTIF = PE.SPBPERS_PIDM
               AND F.SZTRECE_PROGRAM_CERTIF = pprograma
               --and SZTRECE_XML_IND  is null-----TRES SIGNIFOCA QUE ES REPROCESO Y GENERA LOS DOS ARCHIVOS
               AND F.SZTRECE_PIDM_CERTIF = NVL (ppidm, F.SZTRECE_PIDM_CERTIF)
      ORDER BY 1 DESC;


   CURSOR c_parametros (
      p_valor    VARCHAR2,
      p_desc     VARCHAR2)
   IS
        SELECT                                --ZSTPARA_PARAM_VALOR  as valor,
              ZSTPARA_PARAM_DESC AS descr, ZSTPARA_PARAM_ID AS idv
          FROM zstpara z
         WHERE     ZSTPARA_MAPA_ID = 'CERT_DIGITAL'
               AND ZSTPARA_PARAM_VALOR = p_valor
               AND z.ZSTPARA_PARAM_DESC = NVL (p_desc, z.ZSTPARA_PARAM_DESC)
      ORDER BY 1;

   vvalor               VARCHAR2 (30);
   vdescr               VARCHAR2 (100);
   vidv                 VARCHAR2 (10);
   vnombre_inst         VARCHAR2 (100);
   v_intidad_fed        VARCHAR2 (100);
   v_pcampus            VARCHAR2 (5);
   p_valor              VARCHAR2 (20);
   v_cargo              VARCHAR2 (30);
   v_carrera            VARCHAR2 (50);
   vtipoPeriodo         VARCHAR2 (30);
   v_ncarrera           VARCHAR2 (120);
   v_tipoCE             VARCHAR2 (20);
   PTIPO_CERT           VARCHAR2 (10);
   v_IDgenero           NUMBER;
   v_tipoper            VARCHAR2 (14);
   v_no_apelld          NUMBER;



   FUNCTION encode_base64 (base IN VARCHAR2)
      RETURN VARCHAR2
   IS
      resultado   VARCHAR2 (32000);
   BEGIN
      resultado :=
         UTL_RAW.cast_to_varchar2 (
            UTL_ENCODE.base64_encode (UTL_RAW.cast_to_raw (TRIM (base))));

      --DBMS_OUTPUT.put_line ('Encode ' || resultado);

      RETURN (resultado);
   END encode_base64;

   FUNCTION decode_base64 (base IN VARCHAR2)
      RETURN VARCHAR2
   IS
      resultado   VARCHAR2 (32000);
   BEGIN
      resultado :=
         UTL_RAW.cast_to_varchar2 (
            UTL_ENCODE.base64_decode (UTL_RAW.cast_to_raw (base)));

      --resultado := utl_encode.text_encode( base ,'WE8ISO8859P1', UTL_ENCODE.BASE64);

      --DBMS_OUTPUT.put_line ('Encode ' || resultado);

      RETURN (resultado);
   END decode_base64;

   FUNCTION encript_base64 (base IN VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      NULL;
   END encript_base64;

PROCEDURE P_genera_xml (ppidm IN NUMBER, pprograma IN VARCHAR2)
   IS
      v_cur          SYS_REFCURSOR;
      vcred_materia2  VARCHAR2(12);
      vquita_ltr      varchar2(1):='N';
      vtamaño         number:=0;
      materia2        varchar2(14);
      vserror         varchar2(1000);
      VMATERIAV2      VARCHAR2(2);
      no_cred_esp     number:= 0;
      VCATALOG        varchar2(12);

     vobservac     varchar2(20);
     vpromedio    varchar2(10);
     vaprobatoria varchar2(10);
     vcredt         varchar2(10);
     v_codigo VARCHAR2(100);
      v_calificacion VARCHAR2(10);
      v_max_calificacion NUMBER;
      VNIVEL VARCHAR2(4);
      vobligada   varchar2(1):='N';
      

   BEGIN
      NULL;
      vpidm:= ppidm;
      v_prog:= pprograma;
      VNIVEL := SUBSTR(PPROGRAMA,4,2);

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
      vcred_materia  := '';
      vcred_materia2  := '';
      vcred_obtn  := 0;
      v_mate_cursada :=0;
      vtamaño      := 0;
      VMATERIAV2    := '';
      VCATALOG      := null;
       vobservac    := '';
     vpromedio    := '';
     vaprobatoria  := '';
     vcredt        := '';
     vsumcalif  := 0;
     vnumate   := 0;

      --dbms_output.put_line('antes de mandar el proceso dasboar_alumno');
        -- se cambia la forma de conseguir las materias esto es para saber si es una materia ORDINARA o NIVELACIÖn nuev aregla 14.11.2022
      ---v_cur := BANINST1.f_avcu_cert_dig (vpidm, v_prog);
      -- v_cur := BANINST1.PKG_DASHBOARD_ALUMNO.F_DASHBOARD_AVCU_OUT ( vpidm,v_prog,substr(user,1,9) );
       v_cur := BANINST1.PKG_DASHBOARD_ALUMNO.f_dashboard_hiac_out (vpidm, v_prog);
      --dbms_output.put_line('despues de mandar el proceso dasboar_alumno:: '||vpidm ||'-'||v_prog );
      LOOP
         FETCH v_cur
         INTO nombre,
              matricula,
              Programa,
              per,
              nombre_area,
              materia,
              nombre_mat,
              estatus, --equiv a periodo
             califica,
             tipo,  --equiv letra
              n_area, --equiv a avance
              vpromedio,
              vaprobatoria,
              vcredt,
              vobservac;

         EXIT WHEN v_cur%NOTFOUND;

      vtamaño        := 0;------se reinicia cada pasada la variable
      vcred_materia  := '';
      vcred_materia2 := '';
      materia2       := '';
      VMATERIAV2     := '';
      no_cred_esp    :=0;

          --dbms_output.put_line('aqui van los datosINI >> '||'-'||nombre||'-'||matricula||'-'||Programa||'-'||per||'-'||nombre_area||'-'||materia||'-'||nombre_mat||'-'||califica||'->'||estatus||'-'||tipo||'-'||
            --  n_area||'-'|| vpromedio||'-'|| vaprobatoria||'-'|| vcredt||'-'||vobservac);

         BEGIN
            ----------------en esta tabla estan las materias que son de equivalencia o revalidacion son muy pocas.
            --select decode(count(1),1,70,100)
            --INTO   v_observ
            --from SHRTRCR
            --where (trim(SHRTRCR_TRANS_COURSE_NAME)||trim(SHRTRCR_TRANS_COURSE_NUMBERS)) = materia
            --and  SHRTRCR_PIDM  = vpidm;
            SELECT DECODE (COUNT (1), 1, 70, 100)
              INTO v_observ
              FROM shrtrce
             WHERE     shrtrce_pidm = vpidm
                   AND (shrtrce_subj_code || shrtrce_crse_numb) = materia;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_observ := '';
               --dbms_output.put_line('error shretce sqlerrm:: '||sqlerrm );

         END;

         ---------------------SI LA MATERIA ES 70 O EQUIVALENCIA  ENTONCES LA RECALCULA SU PERIODO O CICLO----
        --dbms_output.put_line('despues de mandar el proceso dasboar_alumno:: '||MATRICULA ||'-'||NOMBRE||'-'|| PROGRAMA );
         IF v_observ = 70     THEN

            BEGIN
               SELECT SUBSTR (SGRSCMT_COMMENT_TEXT, 10, 7)
                 INTO v_ciclo
                 FROM SGRSCMT MT
                WHERE     SGRSCMT_PIDM = vpidm      ----FGET_PIDM('010003935')
                 and   SUBSTR (SGRSCMT_COMMENT_TEXT, 1, 8) like ('DICTAMEN%')
--                 AND SGRSCMT_TERM_CODE =
--                             (SELECT MAX (SGRSCMT_TERM_CODE)
--                                FROM SGRSCMT GG
--                               WHERE GG.SGRSCMT_PIDM = MT.SGRSCMT_PIDM);
                    ;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_ciclo := '000000';
                    -- dbms_output.put_line('error SGRSCMT sqlerrm:: '||sqlerrm );
            END;

            ------------busca el ID de la materia  para las que son equvalencias-------
            BEGIN
               SELECT SCBCRSE_CONT_HR_HIGH,SCBCRSE_CREDIT_HR_LOW
                 INTO v_id_materia, vcred_materia
                 FROM scbcrse bs
                WHERE (SCBCRSE_SUBJ_CODE || SCBCRSE_CRSE_NUMB) =  materia;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_id_materia := 'ERR';
                  vcred_materia := '';
                     dbms_output.put_line('error scbcrse sqlerrm:: '||materia||'-'||  v_id_materia);
            END;
         --   dbms_output.put_line('recupera ID materia EQUIVALENCIA ::  '||materia||'-'||  v_id_materia);

       ELSE     ------------***********     ES UNA MATERIA   ORDINARIA = 100
                --   dbms_output.put_line('recupera ID materia ORDINARIA ::  '||materia );
                ----- se agrega la funcion pata ver si es NIVELACIÖN(71) o ordinaria
            IF  vobservac !='ORD' THEN -- AQUI CAMBIA A NIVELACION
             v_observ  := 71;
            END IF;


            BEGIN
               ----------de aqui toma el numero de materia segun sep para certificados
               SELECT distinct SCBCRSE_CONT_HR_HIGH,
                      --SHRTCKN_TERM_CODE
                      (SELECT distinct SUBSTR (STVTERM_DESC, 1, 6)
                         FROM STVTERM
                        WHERE STVTERM_CODE = CK.SHRTCKN_TERM_CODE)
                         AS TERM,
                         SCBCRSE_CREDIT_HR_LOW
                 INTO v_id_materia, v_ciclo,vcred_materia
                  FROM scbcrse bs, SHRTCKN ck, SFRSTCR f
                WHERE     (SCBCRSE_SUBJ_CODE || SCBCRSE_CRSE_NUMB) =  materia
                      AND bs.SCBCRSE_SUBJ_CODE = ck.SHRTCKN_SUBJ_CODE
                      AND bs.SCBCRSE_CRSE_NUMB = ck.SHRTCKN_CRSE_NUMB
                      and F.SFRSTCR_CRN        = ck.SHRTCKN_CRN
                      AND F.SFRSTCR_TERM_CODE  = ck.SHRTCKN_TERM_CODE
                      and SFRSTCR_RSTS_CODE    = 'RE'
                      and F.SFRSTCR_PIDM       = ck.SHRTCKN_PIDM
                      AND SHRTCKN_PIDM = vpidm;
            EXCEPTION
               WHEN OTHERS
               THEN
                 -- dbms_output.put_line ('no  se encontro materias>> '|| materia  );

                  BEGIN
                     SELECT DISTINCT SCBCRSE_CONT_HR_HIGH,SCBCRSE_CREDIT_HR_LOW
                       INTO v_id_materia,vcred_materia
                       FROM scbcrse bs
                      WHERE (SCBCRSE_SUBJ_CODE || SCBCRSE_CRSE_NUMB) = materia;

                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_id_materia := 'ERR';
                        vcred_materia := '';
                          dbms_output.put_line('error scbcrse sqlerrm:: '||sqlerrm );
                  END;


             BEGIN
                    SELECT distinct  ((SELECT SUBSTR (STVTERM_DESC, 1, 6)
                                  FROM STVTERM
                                   WHERE STVTERM_CODE = B.SSBSECT_TERM_CODE))
                                     AS TERM
                           INTO v_ciclo
                      FROM SFRSTCR f, ssbsect b
                        WHERE     F.SFRSTCR_CRN = B.SSBSECT_CRN
                              AND F.SFRSTCR_TERM_CODE = B.SSBSECT_TERM_CODE
                              AND F.SFRSTCR_PIDM = vpidm
                              AND SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB =    materia
                               and SFRSTCR_RSTS_CODE  = 'RE'
                      ORDER BY SFRSTCR_RSTS_CODE, SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB;
               EXCEPTION   WHEN OTHERS    THEN

                        --dbms_output.put_line('error en el ciclo   '||v_ciclo ||'-'|| sqlerrm  );
                   begin
                        SELECT SORLCUR_TERM_CODE_CTLG
                          INTO v_ciclo
                          FROM sorlcur so
                         WHERE     sorlcur_pidm = vpidm
                               AND sorlcur_program = pprograma
                               AND SORLCUR_LMOD_CODE = 'LEARNER'
                              -- AND SORLCUR_CACT_CODE = 'ACTIVE'
                               AND SORLCUR_TERM_CODE IN
                                      (SELECT MAX (SORLCUR_TERM_CODE)
                                         FROM sorlcur s1
                                        WHERE     s1.sorlcur_pidm = vpidm
                                              AND s1.sorlcur_program =
                                                     pprograma
                                              AND s1.SORLCUR_LMOD_CODE =
                                                     'LEARNER'
                                              --AND s1.SORLCUR_CACT_CODE = 'ACTIVE'
                                                     );
                    EXCEPTION   WHEN OTHERS   THEN
                       v_ciclo := '';
                  END;
            END;
           end;
           --dbms_output.put_line('  aqui recupero el id de la materia '||v_id_materia ||'-ciclo--'||v_ciclo   );
         END IF;

       --dbms_output.put_line('  antes de evaluar CALIFICACION '||v_id_materia ||'-calificacion--'||califica   );

         IF califica = '10.0'  THEN
            v_califica := SUBSTR (califica, 1, INSTR (califica, '.') - 1);

          ELSIF   califica in ('5.0','NP','NA','' ) then
            v_califica := null;
            califica := null;-- para que no truene al momento de hacer la suma

            ELSIF  califica = '6.0' and substr(v_prog,4,2)  != 'LI'  then
             v_califica := null;

              ELSIF califica = 'AC'  THEN
                v_califica := califica;
                califica := null;-- para que no truene al momento de hacer la suma
                 -- dbms_output.put_line('  dentro de "AC" -- evaluar CALIFICACION '||v_id_materia ||'-calificacion--'||v_califica   );
                 ELSE
                    v_califica :=califica||0;

         END IF;

         --v_califica := to_number(v_califica);
        -- v_califica := SUBSTR (califica, 1, INSTR (califica, '.') - 1);
        -- v_califica := v_califica||

        -----aqui se busca los creditos especiales del paramtrizador regla para los programas que tienen materias con creditos difrentes
        ----  regla fernando 07/12/021
        ---- se busca el periodo de catalogo del alumno
        --BUSCO EL PERIODO DE CATALOGO PARA LOS ALUMNOS CON BAJAS EN EL PARAMETRIZADOR
           BEGIN
            SELECT DISTINCT CTLG
              INTO VCATALOG
            FROM TZTPROG
            WHERE 1=1
            AND PIDM  = vpidm
            AND PROGRAMA  = pprograma
            /*AND ESTATUS IN ( select distinct ZSTPARA_PARAM_VALOR
                                from zstpara
                                where 1=1
                                and ZSTPARA_MAPA_ID = 'ESTATUS_CERTIF'
                                and ZSTPARA_PARAM_ID = 'CP'  )
             */
             ;

           EXCEPTION WHEN OTHERS THEN
             VCATALOG := NULL;
             dbms_output.put_line('>>error no encontro CTLG ::  '||vpidm ||'-'||v_prog);
           END;



            begin


                select SZT_NO_CREDITOS
                     INTO no_cred_esp
                   from sztcred
                    where  1=1
                      and SZT_CVE_PROGRAMA = pprograma
                      and SZT_CVE_MATERIA  = materia
                      and SZT_PERIOD_CTLG  = VCATALOG
                    ;



            exception when others then
            no_cred_esp := 0;

            end;

            if no_cred_esp > 0 then  --si cred_esp tiene info se sutituye la variable x los nuevos cred glovicx 07/12/021
              dbms_output.put_line('>>entro a creditos especiales ::  '||vpidm ||'-'||pprograma||'-'||VCATALOG||'-'|| no_cred_esp);
               vcred_materia := no_cred_esp;
            end if;



          IF  (vcred_materia) > 0  and califica is not null  then  --------materias obligatorias-----
           vcred_obtn := vcred_obtn + vcred_materia;

           -- nueva regla vamos a calcular el promedio a mano glovicx 10.11.2022
           vsumcalif :=  vsumcalif + califica;
           vnumate  := vnumate +1;


           --dbms_output.put_line('>>en la suma calificacion  ::  '||vpidm ||'-'||pprograma||'-'||vnumate||'-'|| califica||'->'|| vsumcalif);


              OPEN c_parametros ('ASIGNATURA', 'OBLIGATORIA');
                  FETCH c_parametros
                  INTO vdescr, vidv;
                  vid_asignatura := vidv;
                  v_asignatura   := vdescr;
                  --dbms_output.put_line('>>>>CARgos 1  '||v_idcargo || ' - '|| v_cargo);
                  CLOSE c_parametros;

              --dbms_output.put_line('creditos obtenidos.. '||maTERIA||'-->'||vcred_obtn);
           else
               OPEN c_parametros ('ASIGNATURA', 'OPTATIVA');
                  FETCH c_parametros
                  INTO vdescr, vidv;
                  vid_asignatura := vidv;
                  v_asignatura   := vdescr;
                  --dbms_output.put_line('>>>>CARgos 2  '||v_idcargo || ' - '|| v_cargo);
                  CLOSE c_parametros;
           END IF;


           ---AQUI VALIDAMOS LOS NOMBRE DE MATERIAS SI ESTAN EN LA TABLA ENTONCES NO PASAN GLOVICX 21/10/021
           BEGIN

                SELECT DISTINCT 'NA'
                    INTO VMATERIAV2
                    FROM SZTALMT
                      WHERE 1=1
                        AND SZTALMT_MATERIA = materia;

           EXCEPTION WHEN OTHERS THEN
           VMATERIAV2 := NULL;
           END;


        -- dbms_output.PUT_LINE(' este es  CALIFICACIONxx '||v_califica||'-'||materia);
         -----------------valida que sea materia decreditos es decir excluimos a las materias cursor propedeuticos-----
                 -- dbms_output.PUT_LINE(' este es  paso2 '||v_califica||'-'||materia  );

      IF  materia like ('%HE%')
      OR  materia like ('%HB%')
      OR  materia like ('%SESO%')
      OR  VMATERIAV2 = 'NA'
      OR  v_califica is null or  v_califica = '0'  then
      -----aqui se le ponen las materias que no quieres que salgan como servicio soc.
         NULL;
           --dbms_output.PUT_LINE(' este es talleres CALIFICACION '||v_califica);
       ELSE
        --dbms_output.PUT_LINE(' este es DENTROO  ANTES CALIFICACIONZZ '||v_califica);
              -----nueva regla si es un taller de cualquier materia MENOS derecho le tiene que poner "AC"
            IF materia like ('%HE%') or  materia like ('%HB%')  AND v_prog NOT IN ('UNALIDDESG','UTLLIDDESE','UTLLIDDFED'  ) THEN
              -- v_califica := 'AC';
             null;
            END IF;
            ------------------------------carga los valors nuevos----
            /*vxml_califica2 :='
            <Asignatura  idAsignatura="'||v_id_materia||'" ciclo="'||v_ciclo||'" calificacion="'||v_califica|| '"  idObservaciones="'||v_observ||'"'||
            ' nombre="'||nombre_mat||'" claveAsignatura="' || materia ||'"'||
            '  />';
            */
           --  dbms_output.PUT_LINE(' este es DENTROO  talleres CALIFICACIONxx '||v_califica);
            if instr(materia,'.',1)-1 > 0  then  --------para quietarle los punto y guines a las materias
             materia:= substr(materia,1, instr(materia,'.',1)-1);
             else
             materia := materia;
            end if;


           -- dbms_output.put_line('nueva materia...'||materia  );

            if instr(vcred_materia,'.',1) = 0  then
               --  if vcred_materia in (5,10) then
                --  vcred_materia2:= vcred_materia;
                 -- else
                  vcred_materia2:= vcred_materia||'.00';
                 --end if;
                 -- vcred_materia2:= vcred_materia;

            elsif length(substr(vcred_materia,3,4)) >= 2 then
            null;
              -- dbms_output.put_line('CREDITOS COMPLETOS...nvo credito:::::: '||materia || '---'|| vcred_materia );

            vcred_materia2:= vcred_materia;
            else
             vcred_materia2:= vcred_materia||'0';
               --dbms_output.put_line('nueva CREDITOS...nvo credito:::::: '||materia || '---'|| vcred_materia2 );
            end if;

              ----se utiliza el parametrizador para checar todos los programas que esten aqui se les quite la última letra PROG FEDERALES
              --solo para obtener el ID_MATERIA TODO LO DEMAS SE QUE IGUAL
            --  a la materia
              begin
                select 'Y'
                 into vquita_ltr
                from zstpara
                where ZSTPARA_MAPA_ID = 'QUITAR_ULT_LETR'
                and  ZSTPARA_PARAM_ID = v_prog
                ;

             exception when others then
               vquita_ltr :='N';
             end;

            IF vquita_ltr = 'Y'  then
                vtamaño := length(materia);
              materia2 := substr(materia,1,vtamaño-1);
             -- INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3,VALOR4)
               -- VALUES('cert_ QUITA LETRA1',materia2, materia,v_prog);


                  BEGIN
                     SELECT DISTINCT SCBCRSE_CONT_HR_HIGH
                       INTO v_id_materia
                       FROM scbcrse bs
                      WHERE (SCBCRSE_SUBJ_CODE || SCBCRSE_CRSE_NUMB) = materia2;

                     --   INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3,VALOR4)
                    --    VALUES('cert_ QUITA LETRA2',materia2, materia,v_id_materia);

                  EXCEPTION   WHEN OTHERS     THEN
                      begin
                       SELECT DISTINCT SCBCRSE_CONT_HR_HIGH
                       INTO v_id_materia
                       FROM scbcrse bs
                      WHERE (SCBCRSE_SUBJ_CODE || SCBCRSE_CRSE_NUMB) = materia;
                       -- INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3,VALOR4)
                       -- VALUES('cert_ QUITA LETRA2',materia2, materia,v_id_materia);
                      exception when others then
                          v_id_materia := 'ERR';
                      end;

                  END;

            ELSE
            materia2 := materia;

            end if;

                   
            
          vxml_califica2 :='
<Asignatura  nombre="'
               || nombre_mat
               || '" claveAsignatura="'
               ||  materia2
               || '" creditos="'
               || vcred_materia2
               || '" idTipoAsignatura="'
               || vid_asignatura
               || '" tipoAsignatura="'
               || v_asignatura
               || '" idObservaciones="'
               || v_observ
               || '" calificacion="'
               || v_califica
               || '" ciclo="'
               || v_ciclo
               || '" idAsignatura="'
               || v_id_materia
|| '"/>';


            --<Asignatura nombre="'||nombre_mat||'" idAsignatura="'||v_id_materia||'" ciclo="'||v_ciclo||'" calificacion="'||v_califica||'" idObservaciones="'||v_observ||'" claveAsignatura="' || materia||'"/>';
            --v_calificaciones := v_calificaciones ||'|'||v_id_materia||'|'||v_ciclo||'|'||v_califica;
            v_calificaciones :=
                  v_calificaciones
               || v_id_materia
               || '|'
               || v_ciclo
               || '|'
               || v_califica
               || '|'
               || vid_asignatura
               || '|'
               || vcred_materia2
               || '|'
               ;

            vxml_califica3 := vxml_califica3 || vxml_califica2;
            -- v_asignadas := v_asignadas +1;
            -- v_total_mat := v_total_mat + 1;
            --DBMS_OUTPUT.put_line (vxml_califica2);

                   if  califica is not null  then ------no debe contar para el total
                  v_mate_cursada  := v_mate_cursada +1;  -- aqui si van todas es total
                  end if;

            IF v_mate_cursada = 49 and v_prog in ( 'UTLLIDDFED','UTLLIDEFED','UTLLIDIFED' ) AND v_numero in ( '20160552','20160550','20150083','20150082','20160554') then

           --VCONTADOR2 := VCONTADOR2 +1;
         --  DBMS_OUTPUT.put_line ('>>>>>Entra a 49 matriculas derecho  '||v_mate_cursada  );
            CLOSE v_cur;
           exit;

         end if;



         END IF;
        -- DBMS_OUTPUT.put_line ('>>>>>al final de IF   '||v_mate_cursada||'-'||califica  );
         -------hace el contador de materias para contar con las optativas mec 2.0  glovicx----


        EXIT WHEN v_cur%NOTFOUND;
      END LOOP;

      ----- calculamos el promedio gral
      vpromediox := (vsumcalif/vnumate);
      DBMS_OUTPUT.put_line ('salida promedio  general---- ' ||( vpromediox)||'--'|| vsumcalif ||'/'|| vnumate   );

        IF V_CUR%ISOPEN THEN
       CLOSE v_cur;
       END IF;

   EXCEPTION
      WHEN OTHERS
      THEN
      vserror  := sqlerrm;
         DBMS_OUTPUT.put_line ('salida error general---- ' || vserror);
        -- raise_application_error (-20002, 'ERROR en genera AVCU ' || SQLERRM);
         NULL;
   END P_genera_xml;

   PROCEDURE p_genera_dgair (pcadena      IN CLOB,
                             ppidalumno   IN VARCHAR2,
                             pprograma    IN VARCHAR2)
   IS
      salida        UTL_FILE.FILE_TYPE;
      nom_archivo   VARCHAR2 (160);
      directorio    VARCHAR2 (90);
      mserr         VARCHAR2 (3000);
   BEGIN
      NULL;

      --dbms_output.put_line(' salida archivo DGAIR-------  '|| ppidalumno);
      nom_archivo :=
            'Dgair2'
         || '_'
         || ppidalumno
         || '_'
         || TO_CHAR (SYSDATE, 'DDMMYYYY')
         || TO_CHAR (SYSDATE, 'HH24MISS')
         || '.txt';
      -- dbms_output.put_line(' nomnbrev  archivo DGAIR-------  '|| nom_archivo);
      salida :=
         UTL_FILE.fopen ('ARCHXML',
                         nom_archivo,
                         'W',
                         32767);

      --dbms_output.put_line(' salida open  ');
      UTL_FILE.PUT_LINE (salida, TRIM(pcadena));
      --UTL_FILE.PUT_LINE(salida,'\n');
      UTL_FILE.fclose (salida);

      IF UTL_FILE.is_open (salida)
      THEN
        --- UTL_FILE.fclose_all;
         UTL_FILE.FCLOSE(salida);
         DBMS_OUTPUT.put_line ('Closed All');
      END IF;

    EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('salida ' || SQLERRM);
        -- raise_application_error (-20002, 'ERROR en genera DGAIR_FILE ' || SQLERRM);

   END p_genera_dgair;

   PROCEDURE p_archivo_xml (pcadena      IN CLOB,
                            ppidalumno   IN VARCHAR2,
                            pprograma    IN VARCHAR2)
   IS
      salida        UTL_FILE.FILE_TYPE;
      nom_archivo   VARCHAR2 (160);
      directorio    VARCHAR2 (90);
      mserr         VARCHAR2 (3000);
      --text_raw      RAW (32767);
       text          VARCHAR2 (32767);
     -- text         RAW (32767);
      text_raw      RAW (32767);
      filehandler   UTL_FILE.file_type;
   BEGIN
      NULL;

      text :=  (pcadena);
      --DBMS_OUTPUT.put_line ('generar XML_1:: '|| sqlerrm);
      nom_archivo :=
            'XML2'
         || '_'
         || ppidalumno
         || '_'
         || TO_CHAR (SYSDATE, 'DDMMYYYY')
         || TO_CHAR (SYSDATE, 'HH24MISS')
         || '.xml';
        -- DBMS_OUTPUT.put_line ('generar XML_2:: '|| sqlerrm);
      --convert it to raw encoded text
      --text_raw := UTL_I18N.string_to_raw (text, 'UTF8');  -------text es mi cadena AL32UTF8
      text_raw := UTL_I18N.string_to_raw (TRIM (text), 'AL32UTF8');
      -- open the file with the nchar for new encoding in the Directory BBSIS
      filehandler :=
         UTL_FILE.fopen_nchar ('ARCHXML',
                               nom_archivo,
                               'w',
                               32767);
      --DBMS_OUTPUT.put_line ('generar XML_3:: '|| sqlerrm);
      -- write the bom section
      --UTL_FILE.put_nchar (filehandler, UTL_I18N.raw_to_nchar (bom_raw, 'UTF8'));
      -- Now. write out the rest of our text retrieved from Oracle with its UTF8 encoding
      --UTL_FILE.put_nchar (filehandler, UTL_I18N.raw_to_nchar (text_raw, 'UTF8'));
      UTL_FILE.put_nchar (
         filehandler,
         UTL_I18N.raw_to_nchar (TRIM(text_raw), 'AL32UTF8'));
         --DBMS_OUTPUT.put_line ('generar XML_4:: '|| sqlerrm);
      -- Close the unicode (UTF8) encoded text file
      UTL_FILE.fclose (filehandler);

      --UTL_FILE.PUT_LINE(salida,'\n');
     -- UTL_FILE.fclose (filehandler);

      IF UTL_FILE.is_open (filehandler)
      THEN
         UTL_FILE.fclose_all;
        -- DBMS_OUTPUT.put_line ('Closed All');
      END IF;
     --DBMS_OUTPUT.put_line ('generar XML_5:: '|| sqlerrm);
    begin
      UPDATE SZTRECE
         SET SZTRECE_XML_IND = 1
       WHERE     SZTRECE_PIDM_CERTIF = vpidm
             AND SZTRECE_PROGRAM_CERTIF = pprograma
             AND SZTRECE_VAL_FIRMA   = 0;
    exception when others then
      null;
    end;
       --DBMS_OUTPUT.put_line ('generar XML_6:: '|| sqlerrm);
     exception when others then
     NULL;
     --DBMS_OUTPUT.put_line ('error al generar XML_:: '|| sqlerrm);


   END p_archivo_xml;


   PROCEDURE p_archivo_xml2 (pcadena      IN CLOB,
                             ppidalumno   IN VARCHAR2,
                             pprograma    IN VARCHAR2)
   IS
      salida        UTL_FILE.FILE_TYPE;
      nom_archivo   VARCHAR2 (150);
      directorio    VARCHAR2 (90);
      mserr         VARCHAR2 (2000);
   BEGIN
      NULL;

      --dbms_output.put_line(' salida archivo DGAIR-------  '|| ppidalumno);
      nom_archivo :=
            'XML2'
         || '_'
         || ppidalumno
         || '_'
         || TO_CHAR (SYSDATE, 'HH24MISS')
         || '.xml';
      -- dbms_output.put_line(' nomnbrev  archivo DGAIR-------  '|| nom_archivo);
      salida :=
         UTL_FILE.fopen ('ARCHXML',
                         nom_archivo,
                         'W',
                         32767);
      --dbms_output.put_line(' salida open  ');
      UTL_FILE.PUT_LINE (salida, vxml_inicio);
      UTL_FILE.PUT_LINE (salida, vxml_respon);
      UTL_FILE.PUT_LINE (salida, vxml_entidad);
      UTL_FILE.PUT_LINE (salida, soap_request);
      UTL_FILE.PUT_LINE (salida, soap_respond);
      UTL_FILE.PUT_LINE (salida, vxml_alumno);
      UTL_FILE.PUT_LINE (salida, vxml_expedicion);
      UTL_FILE.PUT_LINE (salida, vxml_califica);
      UTL_FILE.PUT_LINE (salida, vxml_califica3);
      UTL_FILE.PUT_LINE (salida, vxml_fin);
      --UTL_FILE.PUT_LINE(salida,'\n');
      UTL_FILE.fclose (salida);

      IF UTL_FILE.is_open (salida)
      THEN
         UTL_FILE.fclose_all;
         --DBMS_OUTPUT.put_line ('Closed All');
      END IF;
   END p_archivo_xml2;


PROCEDURE P_inicio (ppidm       IN NUMBER,
                       pprograma   IN VARCHAR2,
                       pindica     IN  NUMBER,
                       ptipo       IN NUMBER,
                       p_responsable in number,
                       pmodo  IN number default 0)
   IS


      v_no_apelld2   NUMBER;
      v_encode64     VARCHAR2 (10000);
      term_ctlgo     VARCHAR2(12);
      VCATALOG       VARCHAR2(8);
      no_cred_esp     NUMBER:=0;
      vnivel         varchar2(2);
      vcampus        varchar2(3);
      vno_ciclo     varchar2(8);
      vextranjero    VARCHAR2(12);
      v_palabra      varchar2(20);
      vobligada      varchar2(2):='Y';



   BEGIN
      NULL;

      --
      --DBMS_OUTPUT.put_line ('pasoO 1   ' || ppidm || '--' || pprograma);
    

     -- vxml_inicio := '<?xml version="1.0" encoding="UTF-8"?>';
   vxml_inicio :='<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' ;

vxml_fin := ('
</Asignaturas>');
vxml_fin := vxml_fin || '
</Dec>';


      OPEN c_parametros ('ENTIDAD_FED', 'CIUDAD DE MÉXICO');

      FETCH c_parametros
      INTO vdescr, vidv;

      v_ent_fed := vidv;
      v_intidad_fed := vdescr;

      --dbms_output.put_line('>>>>ENtidad fed  '||v_ent_fed || ' - '|| v_intidad_fed);
      CLOSE c_parametros;

      OPEN c_parametros ('CAMPUS', NULL);

      FETCH c_parametros
      INTO vdescr, vidv;

      v_idcamp := vidv;
      v_pcampus := vdescr;

      --dbms_output.put_line('>>>>CAMpus   '||v_idcamp || ' - '|| v_pcampus);
      CLOSE c_parametros;

      OPEN c_parametros ('INSTITUCIONES', NULL);

      FETCH c_parametros
      INTO vdescr, vidv;

      v_idinstituto := vidv;
      vnombre_inst := vdescr;

      --dbms_output.put_line('>>>>INstituto   '||v_idinstituto || ' - '|| vnombre_inst);
--      CLOSE c_parametros;
--
--      OPEN c_parametros ('CARGOS', 'DIRECTOR');
--
--      FETCH c_parametros
--      INTO vdescr, vidv;
--
--      v_idcargo := vidv;
--      v_cargo := vdescr;



      --dbms_output.put_line('>>>>CARgos   '||v_idcargo || ' - '|| v_cargo);
      CLOSE c_parametros;

      IF ptipo = 2
      THEN
         PTIPO_CERT := 'TOTAL';
      ELSE
         PTIPO_CERT := 'PARCIAL';
      END IF; --ptipoC;  ---este valor viene de una valiable externa que el operador escoje si es tipo total o parcial

      OPEN c_parametros ('CATALOGO_TIPO_CERTIFICACION', PTIPO_CERT);

      FETCH c_parametros
      INTO vdescr, vidv;

      v_tipo_certificado := vidv;
      v_tipoCE := vdescr;

      --dbms_output.put_line('>>>>TIPO certificacion   '||v_tipo_certificado || ' - '|| v_tipoCE);
      CLOSE c_parametros;

        /*

        aqui va la funcion que calcula   el numero de periodos
          para la version 3.0   glovicx 18/02/022
             */

             begin

               select distinct t.nivel, t.campus
                   INTO vnivel, vcampus
                from tztprog t
                 where 1=1
                  and  t.pidm = PPIDM
                  and  T.PROGRAMA  = pprograma;


                --DBMS_OUTPUT.PUT_LINE('despues de nivel SEJM:'||vprograma||'-'||  vnivel );
           EXCEPTION WHEN OTHERS THEN

                begin
                   select SORLCUR_LEVL_CODE, SORLCUR_CAMP_CODE
                      INTO   vnivel, vcampus
                    from sorlcur s1
                   where 1=1
                   and sorlcur_pidm = PPIDM
                   and SORLCUR_SEQNO = (select max (SORLCUR_SEQNO)  from sorlcur s2
                                            where 1=1
                                              and s1.sorlcur_pidm = s2.sorlcur_pidm  );


                  EXCEPTION WHEN OTHERS THEN

                    vnivel    := null;
                    vcampus   := null;


                  end;


          END;


          
      v_promedio2   := '';
      v_promedio    := '';
      v_idcarrera := '';

      --IF pindica = 3 then-----ENTONCES ES UN REPROCESO
      FOR jump IN c_alumnos2 (pprograma, ppidm)
      LOOP
         --dbms_output.put_line('REPROCESOOO XML   '||  vpidm );

         --ELSE

         --FOR  jump in c_alumnos(pprograma, ppidm  )  loop
         --END IF;

         vpidm := jump.pidm;
         v_prog := jump.programa;
         --v_nivel := jump.nivel;
         --v_avances := jump.avances;
         --v_curp_alumn := jump.curp_alum;
         v_genero := jump.sexo;
         --v_campus     := jump.campus;

         --------------CALCULA EL FOLIO CONTROL CONSECUTIVO POR CADA ALUMNO---
         v_folio_ctrl := 0; ---- REVISAR QUE VALOR BEBE TENER SIEMPRE EL MISMO O VARIA

         BEGIN
            SELECT NVL (MAX (SZTRECE_FOLIO_CONTROL), 0) + 1
              INTO v_folio_ctrl
              FROM SZTRECE;
         END;

         --DBMS_OUTPUT.put_line (
--            ' pidm ajecutando  ' || jump.pidm || '--' || v_prog);

         BEGIN
           SELECT DISTINCT
           substr(TRANSLATE(UPPER(S.SPRIDEN_LAST_NAME),
                     'áéíóúÁÉÍÓÚüÜ',
                     'aeiouAEIOUuU'), 1, INSTR(S.SPRIDEN_LAST_NAME,'/')-1)  paterno  ,       
            substr(TRANSLATE(UPPER(S.SPRIDEN_LAST_NAME),
                                 'áéíóúÁÉÍÓÚüÜ',
                                 'aeiouAEIOUuU'),INSTR(S.SPRIDEN_LAST_NAME,'/')+1 )  materno  ,       
           REGEXP_REPLACE(
                       TRANSLATE(UPPER(S.SPRIDEN_FIRST_NAME),
                                 'áéíóúÁÉÍÓÚüÜ',
                                 'aeiouAEIOUuU'),
                       '[^a-z_A-Z0-9 ]', ' '
                       ) AS nombre,                 
                      TO_CHAR (sp.SPBPERS_BIRTH_DATE, 'YYYY-MM-DD')
                   || 'T'
                   || TO_CHAR (sp.SPBPERS_BIRTH_DATE, 'HH24:MI:SS')
                      AS fech_nac,
                   S.SPRIDEN_ID,
                   sorlcur_CAMP_CODE,
                   sorlcur_LEVL_CODE
              INTO v_paterno_alumn,
                   v_materno_alumn2,
                   v_nombre_alumn,
                   v_fech_nac_alumn,
                   v_nu_control,
                   v_campus,
                   v_nivel
              FROM spriden s, spbpers sp, sorlcur sc
             WHERE     spriden_pidm = vpidm
                    AND S.SPRIDEN_PIDM = SP.SPBPERS_PIDM
                   AND S.SPRIDEN_PIDM = Sc.Sorlcur_PIDM
                     and Sc.sorlcur_PROGRAM  =  v_prog
                   AND S.SPRIDEN_CHANGE_IND IS NULL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_materno_alumn := '';
               v_nombre_alumn := '';
               v_fech_nac_alumn := '';
               v_nu_control := '';

               ----vmsjerr  :=   SQLERRM;
               vmsjerror := 'Se presento un Error Spriden>  ' || SQLERRM;
               --DBMS_OUTPUT.put_line (vmsjerror);
         END;

        ---- aqui va una modificación para el curp en los para los extranjeros glovicx 16.04.2024
        begin
           
           select 'EXTRANJERO'
             INTO  vextranjero
              from SZVCAMP p
                where 1=1
                and P.SZVCAMP_COUNTRY != 'MEX'
                and P.SZVCAMP_CAMP_ALT_CODE  = substr(v_nu_control,1,2) ;
                
        EXCEPTION WHEN OTHERS  THEN
           vextranjero := 'NULL';
               
         END;
        
        IF vextranjero = 'EXTRANJERO' THEN 
          v_curp_alumn := 'EXTRANJERO';
          
          
         ELSE
        
         BEGIN
            SELECT upper(GORADID_ADDITIONAL_ID)
              INTO v_curp_alumn
              FROM GORADID
             WHERE GORADID_PIDM = PPIDM AND GORADID_ADID_CODE = 'CURP';
         EXCEPTION
            WHEN OTHERS
            THEN
               v_curp_alumn := 'ERROR';
         END;

        END IF;
        
        
        

         IF v_genero = 'M'
         THEN
            v_genero := 'HOMBRE';
         ELSE
            v_genero := 'MUJER';
         END IF;

         OPEN c_parametros ('CATALOGO_GENERO', v_genero );

         FETCH c_parametros
         INTO vdescr, vidv;

         v_IDgenero := vidv;
         CLOSE c_parametros;
-----------------------------calcula el niverl de estudios  mec v2.0 --------+
--------AQUI CONFIGURA EL NIVEL---
       SELECT DECODE( v_nivel, 'LI', 'LICENCIATURA',
                         'MA','MAESTRÍA'  ) NIVEL
             INTO    v_nivel
          FROM DUAL;

         OPEN c_parametros ('NIVEL_ESTUDIOS', UPPER(v_nivel));

         FETCH c_parametros
         INTO vdescr, vidv;

         v_idnvl := vidv;
         v_nvl := vdescr;

         --v_tipoCE := vdescr;
         ----dbms_output.put_line('>>>>GENero  '||v_genero || ' - '|| v_IDgenero);
         CLOSE c_parametros;

       IF  PTIPO_CERT = 'PARCIAL' THEN
       dbms_output.put_line('>>estoy en parcial::  '||PTIPO_CERT);
       NULL;
       --BUSCO EL PERIODO DE CATALOGO PARA LOS ALUMNOS CON BAJAS EN EL PARAMETRIZADOR
           BEGIN
            SELECT DISTINCT CTLG
              INTO VCATALOG
            FROM TZTPROG
            WHERE 1=1
            AND PIDM  = PPIDM
            AND PROGRAMA  = v_prog
            AND ESTATUS IN ( select distinct ZSTPARA_PARAM_VALOR
                                from zstpara
                                where 1=1
                                and ZSTPARA_MAPA_ID = 'ESTATUS_CERTIF'
                                and ZSTPARA_PARAM_ID = 'CP'  );

           EXCEPTION WHEN OTHERS THEN
             VCATALOG := NULL;
             --dbms_output.put_line('>>error no encontro CTLG parcial ::  '||PPIDM ||'-'||v_prog);
           END;
       --------AHORA BUSCA LOS DATOS DEL RVOE--
          BEGIN
            SELECT DISTINCT
                   zt.SZTDTEC_NUM_RVOE AS numrvoe,
                   zt.SZTDTEC_ID_CERTIFICA AS id_cert,
                      TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'YYYY-MM-DD')
                   || 'T'
                   || TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'HH24:MI:SS')
                      AS fech_rvoe,
                   SZTDTEC_CLVE_RVOE AS cveplan-- , decode(SZTDTEC_PERIODICIDAD,1,'BIMESTRAL', 2,'CUATRIMESTRAL',3,'SEMESTRAL',4,'ANUAL') PERIODICIDAD
                   ,
                   SZTDTEC_PERIODICIDAD_SEP ID_PER,
                   DECODE (SZTDTEC_PERIODICIDAD_SEP,
                           91, 'SEMESTRE',
                           92, 'BIMESTRE',
                           93, 'CUATRIMESTRE',
                           94, 'TETRAMESTRE',
                           260, 'TRIMESTRE',
                           261, 'MODULAR',
                           262, 'ANUAL')
                      PERIODICIDAD,
                     --trim(replace( SZTDTEC_PROGRAMA_COMP,'Ejecutivo','')),
                      trim (zt.SZTDTEC_PROGRAMA_COMP),
                   SZTDTEC_ID_CARRERA
              INTO v_numero,
                   v_carrera,
                   v_fec_exp,
                   v_cve_plan,
                   v_tipo_perd,
                   vtipoPeriodo,
                   v_ncarrera,
                   v_idcarrera
              FROM sztdtec zt
             WHERE     SZTDTEC_CAMP_CODE = v_campus
                   AND SZTDTEC_PROGRAM = v_prog
                   --and  SZTDTEC_STATUS  = 'ACTIVO'
                   AND SZTDTEC_TERM_CODE = VCATALOG;
         EXCEPTION WHEN OTHERS  THEN
               v_numero := '';
               v_carrera := '';
               v_fec_exp := '';
               v_idcarrera := '';
         END;

       ELSE-------AQUI ES CERTIFICADO TOTAL
       BEGIN
            SELECT DISTINCT CTLG
              INTO VCATALOG
            FROM TZTPROG
            WHERE 1=1
            AND PIDM  = PPIDM
            AND PROGRAMA  = v_prog
            AND ESTATUS IN ( select distinct ZSTPARA_PARAM_VALOR
                                from zstpara
                                where 1=1
                                and ZSTPARA_MAPA_ID = 'ESTATUS_CERTIF'
                                and ZSTPARA_PARAM_ID != 'CP'  );

           EXCEPTION WHEN OTHERS THEN
             VCATALOG := '000000';
             --dbms_output.put_line('>>error no encontro CTLG total ::  '||PPIDM ||'-'||v_prog);
           END;

         -----------------------calcula el programa para certificado---

         BEGIN
            SELECT DISTINCT
                   zt.SZTDTEC_NUM_RVOE AS numrvoe,
                   zt.SZTDTEC_ID_CERTIFICA AS id_cert,
                      TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'YYYY-MM-DD')
                   || 'T'
                   || TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'HH24:MI:SS')
                      AS fech_rvoe,
                   SZTDTEC_CLVE_RVOE AS cveplan-- , decode(SZTDTEC_PERIODICIDAD,1,'BIMESTRAL', 2,'CUATRIMESTRAL',3,'SEMESTRAL',4,'ANUAL') PERIODICIDAD
                   ,
                   SZTDTEC_PERIODICIDAD_SEP ID_PER,
                   DECODE (SZTDTEC_PERIODICIDAD_SEP,
                           91, 'SEMESTRE',
                           92, 'BIMESTRE',
                           93, 'CUATRIMESTRE',
                           94, 'TETRAMESTRE',
                           260, 'TRIMESTRE',
                           261, 'MODULAR',
                           262, 'ANUAL')
                      PERIODICIDAD,
                     --trim(replace( SZTDTEC_PROGRAMA_COMP,'Ejecutivo','')),
                      trim (zt.SZTDTEC_PROGRAMA_COMP),
                   SZTDTEC_ID_CARRERA
              INTO v_numero,
                   v_carrera,
                   v_fec_exp,
                   v_cve_plan,
                   v_tipo_perd,
                   vtipoPeriodo,
                   v_ncarrera,
                   v_idcarrera
              FROM sztdtec zt
             WHERE     SZTDTEC_CAMP_CODE = v_campus
                   AND SZTDTEC_PROGRAM = v_prog
                   --and  SZTDTEC_STATUS  = 'ACTIVO'
                   AND SZTDTEC_TERM_CODE =
                          (SELECT distinct SORLCUR_TERM_CODE_CTLG
                             FROM sorlcur cu
                            WHERE     sorlcur_pidm = vpidm
                                  AND SORLCUR_LMOD_CODE = 'LEARNER'
                                  AND SORLCUR_CACT_CODE = 'ACTIVE'
                                  AND SORLCUR_PROGRAM = v_prog
                                  AND SORLCUR_TERM_CODE =
                                         (SELECT MAX (SORLCUR_TERM_CODE)
                                            FROM sorlcur dd
                                           WHERE     DD.SORLCUR_PIDM =   cu.sorlcur_pidm
                                                 AND DD.SORLCUR_PROGRAM =  CU.SORLCUR_PROGRAM
                                                 AND dd.SORLCUR_LMOD_CODE =  'LEARNER'
                                                 AND dd.SORLCUR_CACT_CODE =  'ACTIVE'
                                           ));


             EXCEPTION WHEN OTHERS THEN
             null;

                 BEGIN
                      SELECT DISTINCT
                       zt.SZTDTEC_NUM_RVOE AS numrvoe,
                       zt.SZTDTEC_ID_CERTIFICA AS id_cert,
                          TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'YYYY-MM-DD')
                       || 'T'
                       || TO_CHAR (ZT.SZTDTEC_FECHA_RVOE, 'HH24:MI:SS')
                          AS fech_rvoe,
                       zt.SZTDTEC_CLVE_RVOE AS cveplan-- , decode(SZTDTEC_PERIODICIDAD,1,'BIMESTRAL', 2,'CUATRIMESTRAL',3,'SEMESTRAL',4,'ANUAL') PERIODICIDAD
                       ,
                       zt.SZTDTEC_PERIODICIDAD_SEP ID_PER,
                       DECODE (zt.SZTDTEC_PERIODICIDAD_SEP,
                               91, 'SEMESTRE',
                               92, 'BIMESTRE',
                               93, 'CUATRIMESTRE',
                               94, 'TETRAMESTRE',
                               260, 'TRIMESTRE',
                               261, 'MODULAR',
                               262, 'ANUAL')
                          PERIODICIDAD,
                        -- trim(replace( SZTDTEC_PROGRAMA_COMP,'Ejecutivo','')),
                         trim (zt.SZTDTEC_PROGRAMA_COMP),
                       zt.SZTDTEC_ID_CARRERA
                  INTO v_numero,
                       v_carrera,
                       v_fec_exp,
                       v_cve_plan,
                       v_tipo_perd,
                       vtipoPeriodo,
                       v_ncarrera,
                       v_idcarrera
                  FROM sztdtec zt
                 WHERE  1=1   
                       and zt.SZTDTEC_CAMP_CODE = v_campus
                       AND zt.SZTDTEC_PROGRAM = v_prog
                       --and  SZTDTEC_STATUS  = 'ACTIVO'
                       AND zt.SZTDTEC_TERM_CODE =
                              (SELECT distinct SORLCUR_TERM_CODE_CTLG
                                 FROM sorlcur cu
                                WHERE     sorlcur_pidm = vpidm
                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                     -- AND SORLCUR_CACT_CODE = 'ACTIVE'
                                      AND SORLCUR_PROGRAM = v_prog
                                      AND SORLCUR_TERM_CODE =
                                             (SELECT MAX (SORLCUR_TERM_CODE)
                                                FROM sorlcur dd
                                               WHERE     DD.SORLCUR_PIDM =   cu.sorlcur_pidm
                                                     AND DD.SORLCUR_PROGRAM =  CU.SORLCUR_PROGRAM
                                                     AND dd.SORLCUR_LMOD_CODE =  'LEARNER'
                                                   --  AND dd.SORLCUR_CACT_CODE =  'ACTIVE'
                                               )
                                                and rownum < 2)
                         ;



              EXCEPTION WHEN OTHERS THEN

                   v_numero := '';
                   v_carrera := '';
                   v_fec_exp := '';
                   v_idcarrera := '';
             END;

            end;


       END IF;
       ------ en esta secion se hace el replace de los nombres de las carreras que tengan una palabra clave
       ---- dentro de su estructura para ello se usa un PARA con las palabras glovicx 23.04.2024
       
       -- v_ncarrera  esta variable trae el nombre completo del programa original se recorre el cursor
         FOR jump2 in (select ZSTPARA_PARAM_VALOR palabra
                            from zstpara
                            where 1=1
                            and ZSTPARA_MAPA_ID = 'OMIT_NOMB_ALIAN')  LOOP
            
            v_palabra := jump2.palabra;
            
              IF INSTR(v_ncarrera, v_palabra) > 0 THEN
                v_ncarrera := REPLACE(v_ncarrera, v_palabra, ' ');
                --v_encontrado := TRUE;
                --EXIT;
            END IF;
         
       
       
         END LOOP;
         
             -----------  aqui van los calculos para los nuevos ciclo glovicx 14.12.2023
                begin
                 --se quito esta funcion ahora se obtiene mediante un PARA
              --vno_ciclo :=  BANINST1.PKG_CERTIFICADO_DIG_2_0.F_curso_actual ( PPIDM , PPROGRAMA  , vnivel , vcampus   );
               ------nueva funcionalidad regla de america glovicx  27.10.2023 
                select distinct ZSTPARA_PARAM_VALOR as NO_ciclos
                  INTO vno_ciclo
                from zstpara
                where 1=1
                and ZSTPARA_MAPA_ID  = 'CICLO_GRUP'
                and ZSTPARA_PARAM_ID =  v_numero
                and ZSTPARA_PARAM_DESC =  VCATALOG;

             exception when others then       
               vno_ciclo := 0;
               --dbms_output.put_line('error en no de ciclos: '||v_numero||'-'||  VCATALOG ||sqlerrm  );
             end;
         
             --dbms_output.put_line('saliendo de no de ciclos: '||v_numero ||'-'|| VCATALOG ||'-'||vno_ciclo );
             
      ---------se realiza el ajuste para que busque por el parametro de entrada p_responsable glovicx 25/03/022
         BEGIN
            SELECT
                   ce.SZTREDC_NOMBRE,
                   ce.SZTREDC_PATERNO,
                   ce.SZTREDC_MATERNO,
                   ce.SZTREDC_CURP,
                   ce.SZTREDC_NO_CERTIFICADO,
                   ce.SZTREDC_CVE_FIRMA,
                   ce.SZTREDC_IDCARGO id_rep,
                   z.ZSTPARA_PARAM_DESC cargo
              INTO 
                   v_nombre_resp,
                   v_paterno_resp,
                   v_materno_resp,
                   v_curp_resp,
                   v_no_cert,
                   v_firma,
                   v_idcargo,
                   v_cargo
              FROM  SZTREDC CE,zstpara z
                 WHERE  1=1
                    and z.ZSTPARA_MAPA_ID = 'CERT_DIGITAL'
                    and   z.ZSTPARA_PARAM_VALOR  = 'CARGOS'
                    and  ce.SZTREDC_IDCARGO  = z.ZSTPARA_PARAM_ID
                    and  ce.SZTREDC_IDCARGO = p_responsable
                    AND  CE.SZTREDC_ESTATUS = 1;


         EXCEPTION
            WHEN OTHERS
            THEN
               v_no_cert := '';
               vsello := '';
               vdetcert := '';
              -- vsalida := sqlerrm;
               
                dbms_output.put_line ( 'error en representante '||sqlerrm  );
         END;

         v_tipo_cert := 5; ---- REVISAR QUE VALOR BEBE TENER SIEMPRE EL MISMO O VARIA
         ----v_nu_control  := 9999; SE SACA DE ID DE SPRIDEN CONSULTA DE ARRIBA

        /* dbms_output.put_line ( 'calcula representante: '||
                   v_nombre_resp||'-'||
                   v_paterno_resp||'-'||
                   v_materno_resp||'-'||
                   v_curp_resp||'-'||
                   v_no_cert );
            */

         --vxml_entidad := '<Ipes idEntidadFederativa="'||v_ent_fed||'" entidadFederativa="'||v_intidad_fed ||'" campus="'||v_pcampus||'" idCampus="'||v_idcamp||'" idNombreInstitucion="'|| v_idinstituto||'"  nombreInstitucion="'|| vnombre_inst||'">' ;
         --------------se cambio el orden    paa SEP---

vxml_entidad :='
<ServicioFirmante idEntidad="'|| v_idinstituto|| '"/> ';

vxml_entidad := vxml_entidad ||'
<Ipes   nombreInstitucion="'
            || vnombre_inst
            || '" idNombreInstitucion="'
            || v_idinstituto
            || '" idCampus="'
            || v_idcamp
            || '" campus="'
            || v_pcampus
            || '" entidadFederativa="'
            || v_intidad_fed
            || '" idEntidadFederativa="'
            || v_ent_fed
|| '">';
         --soap_request := '<Responsable idCargo="'||v_idcargo ||'" curp="'||v_curp_resp||'" segundoApellido="'||v_materno_resp||'" primerApellido="'||v_paterno_resp||'" nombre="'||v_nombre_resp||'"/>'||
      soap_request :='
<Responsable nombre="'
            || v_nombre_resp
            || '" primerApellido="'
            || v_paterno_resp
            || '" segundoApellido="'
            || v_materno_resp
            || '" curp="'
            || TRIM (v_curp_resp)
            || '"  idCargo="'
            || v_idcargo
            || '"  cargo="'
            || v_cargo
            || '"/>'
            || --dbms_output.put_line ( 'paso aqui 2 ');
               '
</Ipes>';
         -- v_fech_exp :=  trunc(SYSDATE)-2;
         -- dbms_output.put_line ( 'paso aqui 2xxx '||v_fech_exp   );
           v_fech_exp := TO_CHAR (trunc(sysdate)-2, 'YYYY-MM-DD')|| 'T' || '00:00:00';
          -- dbms_output.put_line ( 'paso aqui 3xxx '||v_fech_exp   );
         --vxml_expedicion:='
         --<Expedicion idLugarExpedicion="'||v_ent_fed||'" fecha="'|| v_fech_exp ||'" idTipoCertificacion="'||v_tipo_certificado||'" tipoCertificacion="'||v_tipoCE||  '"/>';
         --dbms_output.put_line ( 'paso aqui 3 ');
         --DBMS_OUTPUT.put_line (' alumno ' || v_materno_alumn);
         vxml_expedicion :='
<Expedicion tipoCertificacion="'
            || v_tipoCE
            || '" idTipoCertificacion="'
            || v_tipo_certificado
            || '" fecha="'
            || v_fech_exp
            || '" idLugarExpedicion="'
            || v_ent_fed
|| '"/>';


         ---------separa  los apellidos an dos-----  se quita esta parte 
        /* v_no_apelld := INSTR (v_materno_alumn, ' ');
         v_paterno_alumn := SUBSTR (v_materno_alumn, 1, v_no_apelld - 1);
--         DBMS_OUTPUT.put_line (
--            ' paterno  ' || v_paterno_alumn || '-' || v_no_apelld);
         v_no_apelld2 :=
            INSTR (v_materno_alumn,
                   ' ',
                   1,
                   2);
         v_materno_alumn2 :=
            SUBSTR (v_materno_alumn,
                    v_no_apelld + 1,
                    v_no_apelld2 - v_no_apelld - 1);

--         DBMS_OUTPUT.put_line (
--            ' MATERNO  ' || v_materno_alumn2 || '-' || v_no_apelld);
         v_nombre_alumn := SUBSTR (v_materno_alumn, v_no_apelld2 + 1, 50);
--         DBMS_OUTPUT.put_line (
--            ' NOMBRE  ' || v_nombre_alumn || '-' || v_no_apelld2);
     */
         --vxml_respon :='<Dec xmlns="https://www.siged.sep.gob.mx/certificados/" noCertificadoResponsable="' || v_no_cert ||'"
         -- certificadoResponsable="' || vdetcert ||'"
         -- sello="'||vsello|| '"folioControl="'||v_folio_ctrl||'" tipoCertificado="'||v_tipo_cert||'" version="1.0">';
        begin
          v_total_mat := BANINST1.PKG_DATOS_ACADEMICOS.TOTAL_MATE2 (vpidm, v_prog);
        exception when others then
        v_total_mat := 0;
        end;

        begin
        v_promedio  := BANINST1.PKG_DATOS_ACADEMICOS.promedio1 (vpidm, v_prog); -----hay que ver como se eejcuta par que no salgan los mensajes de este proceso
        exception when others then
        v_promedio := 0;
        end;
         --nvl(v_promedio,9.999);
          ----- calculamos el promedio gral
--DBMS_OUTPUT.put_line ('salida promedio heredado--- ' ||( vpromediox)||'--'|| vsumcalif ||'/'|| vnumate   );
         --select decode(v_promedio,0,9.99) into v_promedio from dual;
         --select decode(v_promedio,0,9.99) into vpromediox from dual;
         --SELECT  TO_CHAR(v_promedio, '99.99') into v_promedio   FROM DUAL;
         --SELECT  TO_CHAR(vpromediox, '99.99') into v_promedio2   FROM DUAL;
            --DBMS_OUTPUT.put_line ('pROMEDIOxxxx:: '|| v_promedio2 ||'--'|| v_promedio);

         --SELECT SUBSTR (v_promedio, 1, 3) INTO v_promedio2 FROM DUAL;
          v_promedio2 := substr (vpromediox,1,(instr( vpromediox,'.')+2));
            --v_promedio2:= substr(vpromediox,;
        IF length(v_promedio2) = 1 then
             v_promedio2 := v_promedio2||'.00';
        elsif    length(substr(v_promedio2,3,2)) = 1  then
              v_promedio2 := v_promedio2||'0';
        elsif length(v_promedio2) > 4 then
              v_promedio2 := substr(v_promedio2,1,4);
         end if;



         Salida_dat :=
            (   ''
             || '|'
             || ''
             || '|'
             || '3.0'
             || '|'
             || v_tipo_cert
              || '|'
             || v_idinstituto
             || '|'
             || v_idinstituto
             || '|'
             || v_idcamp
             || '|'
             || v_ent_fed
             || '|'
             || v_curp_resp
             || '|'
             || v_idcargo
             || '|'
             || v_numero
             || '|'
             || v_fec_exp
             || '|'
             || v_idcarrera
             || '|'
             || v_tipo_perd
             || '|'
             || v_cve_plan
             || '|'
             || v_nu_control
             || '|'
             || upper(v_curp_alumn)
             || '|'
             || v_nombre_alumn
             || '|'
             || v_paterno_alumn
             || '|'
             || v_materno_alumn2
             || '|'
             || v_IDgenero
             || '|'
             || v_fech_nac_alumn
             || '|'
             || ''
             || '|'
             || ''
             || '|'
             || v_tipo_certificado
             || '|'
             || v_fech_exp
             || '|'
             || v_ent_fed
             || '|'
             || v_mate_cursada
             || '|'
             || v_total_mat
             || '|'
             || v_promedio2
             || '|'
             || v_calificaciones
             || '|');

         --DBMS_OUTPUT.PUT_LINE (' SALIDAUNO:: ' || Salida_dat);


         ---------se cambia   para ser igual a sep---
    vxml_respon :='
<Dec  version="3.0"'
|| ' tipoCertificado="'
|| v_tipo_cert
|| '" folioControl="'
|| v_folio_ctrl
|| '"
sello="'
|| TRIM ('x')
|| '"
certificadoResponsable="'
|| TRIM (v_firma)
|| '"
noCertificadoResponsable="'
|| TRIM (v_no_cert)
|| '"
xmlns="https://www.siged.sep.gob.mx/certificados/"'
|| '>';

         /*vxml_respon :='<Dec xmlns="https://www.siged.sep.gob.mx/certificados/" noCertificadoResponsable="' || v_no_cert ||'"
          certificadoResponsable="' || vdetcert ||'"
          sello="'||vsello|| '"
          folioControl="'||v_folio_ctrl||'" tipoCertificado="'||v_tipo_cert||'" version="1.0">';
         */

  ------------------calcula el programa para ver 2.0  y se calcula el periodo de catalogo de gaston para saber si es un RVOe abierto o cerrado
   v_clvecarrera:= v_prog;

        begin
            select SGBSTDN_TERM_CODE_CTLG_1
             INTO term_ctlgo
            from sgbstdn s
            where s.SGBSTDN_PIDM = vpidm
            and  s.SGBSTDN_PROGRAM_1 = v_clvecarrera
          --  and  s.SGBSTDN_LEVL_CODE  = 'MA'
            and  s.SGBSTDN_TERM_CODE_EFF = ( select max(SGBSTDN_TERM_CODE_EFF) from  sgbstdn ss
                                                    where s.SGBSTDN_PIDM      = ss.SGBSTDN_PIDM
                                                    and   s.SGBSTDN_PROGRAM_1 = ss.SGBSTDN_PROGRAM_1
                                                    and   s.SGBSTDN_LEVL_CODE = ss.SGBSTDN_LEVL_CODE )
                                                    ;
        exception when others then
           select SGBSTDN_TERM_CODE_CTLG_1
             INTO term_ctlgo
            from sgbstdn s
            where s.SGBSTDN_PIDM = vpidm
            and  s.SGBSTDN_PROGRAM_1 = v_clvecarrera
          --  and  s.SGBSTDN_LEVL_CODE  = 'MA'
            and  s.SGBSTDN_TERM_CODE_EFF ='000000';

        end;

  --------nueva validacion para ver si son creditos especiales o normales glovicx 06/01/2022
             begin


                select count(SZT_NO_CREDITOS)
                     INTO no_cred_esp
                   from sztcred
                    where  1=1
                      and SZT_CVE_PROGRAMA = v_prog
                    --  and SZT_PERIOD_CTLG  = v_ciclo
                    ;



            exception when others then
            no_cred_esp := 0;

            end;


  --------------------------valida la calificacion minima aprobatoria, calf_minima y calf maxima---
           begin
               select distinct  substr(SMBPGEN_GRDE_CODE_MIN,1,instr(SMBPGEN_GRDE_CODE_MIN,'.')) ||'00', '5','10',
                CASE WHEN  LENGTH(SUBSTR(SMBPGEN_REQ_CREDITS_OVERALL,INSTR(SMBPGEN_REQ_CREDITS_OVERALL,'.')+1,3))= 1 THEN SMBPGEN_REQ_CREDITS_OVERALL||'0'
                     WHEN  LENGTH(SUBSTR(SMBPGEN_REQ_CREDITS_OVERALL,INSTR(SMBPGEN_REQ_CREDITS_OVERALL,'.')+1,3))= 2 THEN TO_CHAR(SMBPGEN_REQ_CREDITS_OVERALL)
                   ELSE  (SMBPGEN_REQ_CREDITS_OVERALL)||'.00'
                END CREDT_TOT
           into v_calf_min_aprob, v_calf_min, v_calf_max, vcred_total
            from SMBPGEN GE
            where GE.SMBPGEN_PROGRAM = v_clvecarrera
            AND    GE.SMBPGEN_TERM_CODE_EFF = term_ctlgo ;

           exception when others then

           select distinct substr(SMBPGEN_GRDE_CODE_MIN,1,instr(SMBPGEN_GRDE_CODE_MIN,'.')) ||'00', '5','10',SMBPGEN_REQ_CREDITS_OVERALL||'00'
           into v_calf_min_aprob, v_calf_min, v_calf_max, vcred_total
            from SMBPGEN
            where SMBPGEN_PROGRAM = v_clvecarrera
              and  SMBPGEN_TERM_CODE_EFF = '000000';
           end;


         --dbms_output.put_line ( 'paso aqui 4 ');
         soap_respond :='
<Rvoe  numero="'
            || v_numero
            || '" fechaExpedicion="'
            || v_fec_exp
            || '"/>';
    soap_respond:= soap_respond
            ||'<Carrera  idCarrera="'
            || v_idcarrera
            || '" claveCarrera="'
            || v_carrera
            || '" nombreCarrera="'
            || trim(v_ncarrera)
            || '" idTipoPeriodo="'
            || v_tipo_perd
            || '" tipoPeriodo="'
            || vtipoPeriodo
            || '"
            clavePlan="'
            || v_cve_plan
            || '" idNivelEstudios="'
            || v_idnvl
            || '" nivelEstudios="'
            || v_nvl
            || '" calificacionMinima="'
            || v_calf_min
            || '" calificacionMaxima="'
            || v_calf_max
            || '" calificacionMinimaAprobatoria="'
            || v_calf_min_aprob
            || '"/>';
         --dbms_output.put_line ( 'paso aqui 5 ');

         ---------------------------se cambia el orden de xml----
         --soap_respond:= '<Rvoe fechaExpedicion="'||v_fec_exp||'" numero="'||v_numero||'"/>'||
         --'<Carrera clavePlan="'||v_cve_plan||'" idTipoPeriodo="'||v_tipo_perd||'" idCarrera="'||v_idcarrera||'"/>';

         vxml_alumno :='
<Alumno  numeroControl="'
            || v_nu_control
            || '" curp="'
            || upper(v_curp_alumn)
            || '"  nombre="'
            || v_nombre_alumn
            || '" primerApellido="'
            || TRIM (v_paterno_alumn)
            || '" segundoApellido="'
            || TRIM (v_materno_alumn2)
            || '" idGenero="'
            || v_IDgenero
            || '" fechaNacimiento="'
            || v_fech_nac_alumn
|| '"/>';
         --dbms_output.put_line ( 'paso aqui 6');
         --vxml_alumno:='<Alumno curp="'||v_curp_alumn||'" segundoApellido="'||trim(v_materno_alumn2)||'" primerApellido="'||trim(v_paterno_alumn)||'"  nombre="'||v_nombre_alumn||'" fechaNacimiento="'||v_fech_nac_alumn ||'" idGenero="'||v_IDgenero ||'" numeroControl="'||v_nu_control|| '"/>';



         --DBMS_OUTPUT.put_line (
--               'paso aqui 6.2'
--            || ' promediox '
--            || v_promedio2
--            || 'promedio orig '
--            || v_promedio);


     PKG_CERTIFICADO_DIG_2_0.P_genera_xml (vpidm, v_prog);            -----genera las variables de
-----------------------------se calculan los creditos totales
         DBMS_OUTPUT.put_line ('salida promedio heredado--2xx--- ' ||( vpromediox)||'--'|| vsumcalif ||'/'|| vnumate   );
         --SELECT  TO_CHAR(vpromediox, '99.99') into v_promedio2   FROM DUAL;
        --   to_char(vcred_obtn,'9999D99');
        v_promedio2 := substr (vpromediox,1,(instr( vpromediox,'.')+2));
        -- dbms_output.put_line('formato de promedio2xx-- '||   v_promedio2 );
        
        IF length(v_promedio2) = 1 then
             v_promedio2 := v_promedio2||'.00';
        elsif    length(substr(v_promedio2,3,2)) = 1  then
              v_promedio2 := v_promedio2||'0';
        elsif length(v_promedio2) > 4 then
              v_promedio2 := substr(v_promedio2,1,4);
         end if;
      --  dbms_output.put_line('formato de promedio3xx-- '||   v_promedio2 );
      
       ----valida y ajusta los crditos totales si es cred especiales o no'' glovicx 06/01/2022
        IF no_cred_esp > 0 THEN
          null;
          --- SE QUITO ESTA IGUALACIÓN PARA QUE SE VEAN LOS ERRRORES POSIBLES GLOVICX 18/01/2024
        --vcred_total  := vcred_obtn;
        END IF;


      vxml_califica :='
<Asignaturas total="'
            || v_total_mat
            || '" asignadas="'
            || v_mate_cursada 
            || '" promedio="'
            || TRIM (v_promedio2)
            || '" totalCreditos="'
            ||  trim(to_char(vcred_total,'9999D99'))
            || '" creditosObtenidos="'
            ||    trim(to_char(vcred_obtn,'9999D99'))
            ||   '" numeroCiclos="'
            ||    vno_ciclo
            || '">';
         --vxml_califica := '<Asignaturas promedio="'||trim(v_promedio2)||'" asignadas="'||v_total_mat||'" total="'||v_total_mat||'">';


--         DBMS_OUTPUT.put_line (vxml_inicio);
--         DBMS_OUTPUT.put_line (vxml_respon);
--         DBMS_OUTPUT.put_line (vxml_entidad);
--         DBMS_OUTPUT.put_line (soap_request);
--         DBMS_OUTPUT.put_line (soap_respond);
--         DBMS_OUTPUT.put_line (vxml_alumno);
--         DBMS_OUTPUT.put_line (vxml_expedicion);
--         DBMS_OUTPUT.put_line (vxml_califica);
--         DBMS_OUTPUT.put_line (vxml_fin);


         ------------------------------------------inserta las cadenas xml y dat   para el certificado------------
         --update SZTRECE
         --   SET   SZTRECE_CHAIN_XML = vxml_inicio || vxml_respon || vxml_entidad|| soap_request ||soap_respond|| vxml_alumno || vxml_expedicion|| vxml_califica||vxml_califica3|| vxml_fin
         --where SZTRECE_PIDM_CERTIF  = vpidm
         --and  SZTRECE_PROGRAM_CERTIF  = v_prog;


        -- DBMS_OUTPUT.put_line (
--               '|'
--             || ''
--             || '|'
--             || '2.0'
--             || '|'
--             || v_tipo_cert
--             || '|'
--             || v_idinstituto
--             || '|'
--             || v_idcamp
--             || '|'
--             || v_ent_fed
--             || '|'
--             || v_curp_resp
--             || '|'
--             || v_idcargo
--             || '|'
--             || v_numero
--             || '|'
--             || v_fec_exp
--             || '|'
--             || v_idcarrera
--             || '|'
--             || v_tipo_perd
--             || '|'
--             || v_cve_plan
--             || '|'
--             || v_idnvl
--             || '|'
--             || v_calf_min
--             || '|'
--             || v_calf_max
--             || '|'
--             || v_calf_min_aprob
--             || '|'
--             || v_nu_control
--             || '|'
--             || upper(v_curp_alumn)
--             || '|'
--             || UPPER (v_nombre_alumn)
--             || '|'
--             || UPPER (v_paterno_alumn)
--             || '|'
--             || UPPER (v_materno_alumn2)
--             || '|'
--             || v_IDgenero
--             || '|'
--             || v_fech_nac_alumn
--             || '|'
--             || ''
--             || '|'
--             || ''
--             || '|'
--             || v_tipo_certificado
--             || '|'
--             || v_fech_exp
--             || '|'
--             || v_ent_fed
--             || '|'
--             || v_total_mat
--             || '|'
--             || v_total_mat
--             || '|'
--             || v_promedio2
--             || '|'
--             || trim(to_char(vcred_total,'9999D99'))
--             || '|'
--             ||  trim(to_char(vcred_obtn,'9999D99'))
--             || '|'
--             || v_calificaciones
--             || '|');

         -------perimero vaciamos la  variables antes de llenarla
         salida_dat := '';

         ------------------esta linea genera toda la linea del archivo dgair  COMPLETO POR ALUMNO-------
         ---  se puso numero de certificado del representante este es el bueno
         salida_dat :=
            (   '|'
             || ''
             || '|'
             || '3.0'
             || '|'
             || v_tipo_cert
             || '|'
             || v_idinstituto
             || '|'
             || v_idinstituto
             || '|'
             || v_idcamp
             || '|'
             || v_ent_fed
             || '|'
             || v_curp_resp
             || '|'
             || v_idcargo
             || '|'
             || v_numero
             || '|'
             || v_fec_exp
             || '|'
             || v_idcarrera
             || '|'
             || v_tipo_perd
             || '|'
             || v_cve_plan
             || '|'
             || v_idnvl
             || '|'
             || v_calf_min
             || '|'
             || v_calf_max
             || '|'
             || v_calf_min_aprob
             || '|'
             || v_nu_control
             || '|'
             || upper(v_curp_alumn)
             || '|'
             || UPPER (v_nombre_alumn)
             || '|'
             || UPPER (v_paterno_alumn)
             || '|'
             || UPPER (v_materno_alumn2)
             || '|'
             || v_IDgenero
             || '|'
             || v_fech_nac_alumn
             || '|'
             || v_tipo_certificado
             || '|'
             || v_fech_exp
             || '|'
             || v_ent_fed
             || '|'
             || v_mate_cursada
             || '|'
             || v_total_mat
             || '|'
             || v_promedio2
             || '|'
             ||  trim(to_char(vcred_total,'9999D99'))
             || '|'
             || trim(to_char(vcred_obtn,'9999D99'))
             || '|'
             ||  vno_ciclo
             || '|'
             || v_calificaciones
             || '|');

         vxml_total :=
               vxml_inicio
            || vxml_respon
            || vxml_entidad
            || soap_request
            || soap_respond
            || vxml_alumno
            || vxml_expedicion
            || vxml_califica
            || vxml_califica3
            || vxml_fin;

        -- v_encode64 := encode_base64 (TRIM (salida_dat));
         --v_encode64  := encript_base64(salida_dat);  ---nuevo 29oct 2018
        --- vsello   := v_encode64;
         vdetcert := v_firma;

         ----dbms_output.put_line ( 'sello digital  '|| vsello );

         UPDATE SZTRECE
            SET SZTRECE_CHAIN_DAT = TRIM (salida_dat),
                SZTRECE_CHAIN_XML = vxml_total,
                SZTRECE_ACTIVITY_DATE = SYSDATE,
                SZTRECE_FOLIO_CONTROL = v_folio_ctrl,
                SZTRECE_SELLO = TRIM ('x'),
                SZTRECE_DET_CERTIFICA = vdetcert,
                SZTRECE_ID = v_nu_control,
                SZTRECE_IDRESPONSABLE = p_responsable
          WHERE     SZTRECE_PIDM_CERTIF = vpidm
                AND SZTRECE_PROGRAM_CERTIF = v_prog
                AND SZTRECE_MODO   = PMODO
                ;

         /* aqui genera el archivo fisico dgair  para cada alumno  */
         IF pindica = 1  THEN
         
           -- p_genera_dgair (TRIM (salida_dat), v_nu_control, v_prog);
           NULL;
              UPDATE SZTRECE
                  SET   SZTRECE_XML_IND = 1
                  WHERE SZTRECE_XML_IND IS NULL;
                  COMMIT;
            dbms_output.put_line('Se ejecuta el XML2 '||pindica ||' -- '|| v_nu_control  ) ;
         ELSIF pindica = 2
         THEN
              ---------------------------actualiza los registros que no esten completados por el usuario-------
                UPDATE SZTRECE
                  SET   SZTRECE_XML_IND = 1
                  WHERE SZTRECE_XML_IND IS NULL;
                  COMMIT;
            --dbms_output.put_line('Se ejecuta el XML2 '||pindica ||' -- '|| v_nu_control  ) ;
           -- p_archivo_xml (vxml_total, v_nu_control, v_prog);
         --p_archivo_xml2( vxml_total , v_nu_control, v_prog );
         ELSIF pindica = 3
         THEN
         NULL;
            --insert into twpaso (valor1,valor2,valor3) values ( 'inserta xml', sysdate, pindica); commit;
          --   p_genera_dgair (TRIM (salida_dat), v_nu_control, v_prog);
          --   p_archivo_xml (vxml_total, v_nu_control, v_prog);
         --p_archivo_xml2  ( vxml_total,v_nu_control,v_prog);

         END IF;
      END LOOP;

      COMMIT;
   END P_inicio;


function  f_cuenta_firmas return number
   IS
   vconta  number:=0;


   begin

   ---------para saber si hay certificados para firmar

       select count(*)
       into vconta
          from SZTRECE zt
            where SZTRECE_VAL_FIRMA = 0 -- ya fue revisado esta listo para encriptar
            and ZT.SZTRECE_XML_IND = 1 --ya fue revisado elxml
            ;
       return (vconta);
   exception when others then
     vconta := 0;
     return (vconta);

  END f_cuenta_firmas;

function  f_sel_certificados return  BANINST1.PKG_CERTIFICADO_DIG_2_0.firmas_type
   IS
   vconta  number:=0;
    c_id_firmas BANINST1.PKG_CERTIFICADO_DIG_2_0.firmas_type;

   ---------para saber si hay certificados para firmar

 begin



        open c_id_firmas for
                select  datos.representante, datos.matricula, datos.programa, datos.fecha, datos.usuario, datos.firma, ff.SZTRECE_CHAIN_DAT,
                        datos.cve_program, datos.pidm
                    from ( select DISTINCT  DC.SZTREDC_TITULO||'-'||DC.SZTREDC_NOMBRE representante, sf.SZTRECE_ID matricula, TT.SZTDTEC_PROGRAMA_COMP programa
                                 , sf.SZTRECE_ACTIVITY_DATE fecha, sf.SZTRECE_USUARIO_SIU  usuario, sf.SZTRECE_VAL_FIRMA firma
                         , SF.SZTRECE_PROGRAM_CERTIF cve_program,
                         SF.SZTRECE_PIDM_CERTIF pidm
                    from SZTRECE sf, SZTREDC dc, sztdtec tt
                    where sf.SZTRECE_IDRESPONSABLE = dc.SZTREDC_IDCARGO
                    and  sf.SZTRECE_VAL_FIRMA = 0 -- ya fue revisado esta listo para encriptar
                    and  sf.SZTRECE_XML_IND = 1 --ya fue revisado elxml
                    and  SF.SZTRECE_PROGRAM_CERTIF  = TT.SZTDTEC_PROGRAM
                    and  DC.SZTREDC_ESTATUS = 1
                                and  sf.SZTRECE_MODO  = (select MAX(t2.SZTRECE_MODO)  
                                                            from SZTRECE t2
                                                               where 1=1
                                                                 and sf.SZTRECE_PIDM_CERTIF = t2.SZTRECE_PIDM_CERTIF
                                                                  and sf.SZTRECE_PROGRAM_CERTIF    = t2.SZTRECE_PROGRAM_CERTIF  )

                ) datos, SZTRECE ff
                      where 1=1
                            and datos.matricula = ff.SZTRECE_ID
                            and datos.cve_program   = ff.SZTRECE_PROGRAM_CERTIF
                             and  ff.SZTRECE_MODO  = (select MAX(t2.SZTRECE_MODO)  
                                                            from SZTRECE t2
                                                               where 1=1
                                                                 and ff.SZTRECE_PIDM_CERTIF = t2.SZTRECE_PIDM_CERTIF
                                                                  and ff.SZTRECE_PROGRAM_CERTIF    = t2.SZTRECE_PROGRAM_CERTIF  )

                ORDER BY 4 DESC  ;
         vconta := sql%rowcount;



       return c_id_firmas;
    Exception
            When others  then
               ---vl_error := 'PKG_SERV_SIU_ERROR.c_id_firmas: ' || sqlerrm;
           return c_id_firmas;

  END f_sel_certificados;

 function f_update_sello (ppidm number, pprog varchar2, psello clob  ) return varchar2
   IS
   vconta  number:=0;
   c_id_firmas BANINST1.PKG_CERTIFICADO_DIG_2_0.firmas_type;
   VXML      CLOB;
   VDATOS    CLOB;
   VREGESA   VARCHAR2(10);
   VMATRICULA  VARCHAR2(15);
   ---------para saber si hay certificados para firmar

 begin
      BEGIN
         UPDATE SZTRECE z
            SET  z.SZTRECE_ACTIVITY_DATE = SYSDATE,
                 Z.SZTRECE_FECHA_SIU     = SYSDATE,
                 z.SZTRECE_SELLO       = TRIM (psello),
                 z.SZTRECE_XML_IND     = 2,
                 z.SZTRECE_VAL_FIRMA   = 1
                -- z.SZTRECE_USER        = USER
          WHERE 1=1     
             and z.SZTRECE_PIDM_CERTIF = ppidm
             AND z.SZTRECE_PROGRAM_CERTIF = pprog
             and z.SZTRECE_MODO  =  (select MAX(t2.SZTRECE_MODO)  
                                            from SZTRECE t2
                                               where 1=1
                                                 and z.SZTRECE_PIDM_CERTIF = t2.SZTRECE_PIDM_CERTIF
                                                  and z.SZTRECE_PROGRAM_CERTIF    = t2.SZTRECE_PROGRAM_CERTIF  );

          COMMIT;
        EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR EN UPDATE SZTREC 1X2:: '|| SQLERRM  );
        END;

            -----------------------AQUI HAY QUE METER LA GENERACION DE LOS ARCHIVOS --- SE SUPONE QUE SI LLEGO AQUI
        ---------------- ES POR QUE YA FUE REVISADO Y YA LO FIRMO EL REPRESENTANTE---------------
         VREGESA :=   BANINST1.PKG_CERTIFICADO_DIG_2_0.f_complete_xml (ppidm , pprog ) ;
      IF VREGESA = 'EXITO' THEN
         begin
            select Z.sztrece_chain_xml XMLS,
                   Z.SZTRECE_CHAIN_DAT DATOS,
                   Z.SZTRECE_ID IDS
               INTO VXML, VDATOS, VMATRICULA
              FROM  SZTRECE z
                WHERE 1=1 
                 and Z.SZTRECE_PIDM_CERTIF    = ppidm
                 AND Z.SZTRECE_PROGRAM_CERTIF = pprog
                 and z.SZTRECE_MODO  =  (select MAX(t2.SZTRECE_MODO)  
                                            from SZTRECE t2
                                               where 1=1
                                                 and z.SZTRECE_PIDM_CERTIF = t2.SZTRECE_PIDM_CERTIF
                                                  and z.SZTRECE_PROGRAM_CERTIF    = t2.SZTRECE_PROGRAM_CERTIF  );

         exception when others then
           VXML    := NULL;
           VDATOS  := NULL;
         end;
         DBMS_LOCK.SLEEP (2);
         --  p_genera_dgair (TRIM (VDATOS), VMATRICULA, pprog);
           DBMS_LOCK.SLEEP (2);
         --  p_archivo_xml (TRIM(VXML), VMATRICULA, pprog);


         return('EXITO' );
      END IF;

    Exception
            When others  then
               ---vl_error := 'PKG_SERV_SIU_ERROR.c_id_firmas: ' || sqlerrm;
           return ('error'||sqlerrm);

  END f_update_sello;

FUNCTION  P_XML_DATOS  ( ppidm number, pprogrms  varchar2  )  RETURN BANINST1.PKG_CERTIFICADO_DIG_2_0.xml_type
 is

-- esta función es para ver un XML y cadenas en SIU x matricula es la primer pantalla edicion certificados
 vconta  number:=0;
    C_XML_DATOS BANINST1.PKG_CERTIFICADO_DIG_2_0.xml_type;

begin
          open C_XML_DATOS for
                            select T1.SZTRECE_ID, T1.SZTRECE_PROGRAM_CERTIF, T1.SZTRECE_CHAIN_DAT, T1.SZTRECE_CHAIN_XML
                            from SZTRECE T1
                            where 1=1
                            and T1.SZTRECE_PIDM_CERTIF = nvl(ppidm, T1.SZTRECE_PIDM_CERTIF)
                            and T1.SZTRECE_PROGRAM_CERTIF  = nvl( pprogrms, T1.SZTRECE_PROGRAM_CERTIF)
                            and T1.SZTRECE_MODO  =  (select MAX(t2.SZTRECE_MODO)  
                                                       from SZTRECE t2
                            where 1=1
                                                           and t1.SZTRECE_PIDM_CERTIF = t2.SZTRECE_PIDM_CERTIF
                                                           and t1.SZTRECE_PROGRAM_CERTIF    = t2.SZTRECE_PROGRAM_CERTIF  )

                            order by 1 DESC;


RETURN C_XML_DATOS;

END P_XML_DATOS;

FUNCTION P_XML_UPDATE( ppidm number, pprogrms  varchar2 , PDGAIR CLOB, PXML CLOB, pUSER  varchar2  )  RETURN VARCHAR2
 is

 vconta  number:=0;
 --   C_XML_DATOS BANINST1.PKG_CERTIFICADO_DIG_2_0.xml_type;
    --------- esta funcion actualiza los cambios que sufrio la cadena original o el xml en el editor y se guardan
    ------- glovicx despues abra que generar los archivos pero con estas nuevas cadenas y xml
begin

            UPDATE SZTRECE T1
            SET  T1.SZTRECE_CHAIN_DAT  = PDGAIR,
                 T1.SZTRECE_CHAIN_XML  = PXML,
                 T1.SZTRECE_XML_IND     = 1,
                 T1.SZTRECE_VAL_FIRMA   = 0,
                 T1.SZTRECE_ACTIVITY_DATE = SYSDATE,
                 T1.SZTRECE_FECHA_SIU     = SYSDATE,
                 T1.SZTRECE_USUARIO_SIU     = pUSER
             WHERE 1=1 
               AND T1.SZTRECE_PIDM_CERTIF = nvl(ppidm, T1.SZTRECE_PIDM_CERTIF)
               and T1.SZTRECE_PROGRAM_CERTIF  = pprogrms
               and T1.SZTRECE_MODO  =  (select NVL(MAX(t2.SZTRECE_MODO),0)  
                                                       from SZTRECE t2
                                                         where 1=1
                                                           and t1.SZTRECE_PIDM_CERTIF = t2.SZTRECE_PIDM_CERTIF
                                                           and t1.SZTRECE_PROGRAM_CERTIF    = t2.SZTRECE_PROGRAM_CERTIF  );



COMMIT;


RETURN 'EXITO';
EXCEPTION WHEN OTHERS THEN
--RETURN 'EXITO'|| SQLERRM;
dbms_output.put_line('erroir gral en actualiza datos xml '||  sqlerrm);
end P_XML_UPDATE;

function f_complete_xml (ppidm number, pprogram varchar2  ) return varchar2 is

 vsello1       CLOB;

begin --INICIAL

begin

        SELECT  REPLACE (Z.sztrece_chain_xml, 'sello="x"', 'sello="'||trim(Z.sztrece_sello)||'"')  modifica_xml
           into  vsello1
          FROM SZTRECE z
           WHERE 1=1 
            AND Z.SZTRECE_PIDM_CERTIF = ppidm
            and Z.SZTRECE_PROGRAM_CERTIF  = pprogram 
            and Z.SZTRECE_MODO  =  (select MAX(t2.SZTRECE_MODO)  
                                                       from SZTRECE t2
                                                         where 1=1
                                                           and Z.SZTRECE_PIDM_CERTIF = t2.SZTRECE_PIDM_CERTIF
                                                           and Z.SZTRECE_PROGRAM_CERTIF    = t2.SZTRECE_PROGRAM_CERTIF  );


EXCEPTION WHEN OTHERS THEN
      BEGIN 
       SELECT  REPLACE (Z.sztrece_chain_xml, 'sello="', 'sello="x"') modifica_xml
        into  vsello1
        FROM SZTRECE z
        WHERE 1=1
        AND Z.SZTRECE_PIDM_CERTIF = ppidm
        and Z.SZTRECE_PROGRAM_CERTIF  = pprogram
        and Z.SZTRECE_MODO  =  (select MAX(t2.SZTRECE_MODO)  
                                                       from SZTRECE t2
                                                         where 1=1
                                                           and Z.SZTRECE_PIDM_CERTIF = t2.SZTRECE_PIDM_CERTIF
                                                           and Z.SZTRECE_PROGRAM_CERTIF    = t2.SZTRECE_PROGRAM_CERTIF  );
      EXCEPTION WHEN OTHERS THEN
      VSELLO1 := 'X';
      
      END;
END;

--insert into twpasow(valor1, valor6) values('XML',substr(vsello1,1,499)
     BEGIN

        update sztrece Z
         set Z.sztrece_chain_xml = vsello1,
             Z.SZTRECE_ACTIVITY_DATE = sysdate,
             Z.SZTRECE_FECHA_SIU     = SYSDATE
        WHERE 1=1
         and Z.SZTRECE_PIDM_CERTIF = ppidm
         and Z.SZTRECE_PROGRAM_CERTIF  = pprogram
         and Z.SZTRECE_MODO  =  (select MAX(t2.SZTRECE_MODO)  
                                                       from SZTRECE t2
                                                         where 1=1
                                                           and Z.SZTRECE_PIDM_CERTIF = t2.SZTRECE_PIDM_CERTIF
                                                           and Z.SZTRECE_PROGRAM_CERTIF    = t2.SZTRECE_PROGRAM_CERTIF  );
     
        
     EXCEPTION WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('Error en update sztrece: ' || sqlerrm  );
     END;
        
        commit;
        RETURN ('EXITO');

EXCEPTION WHEN OTHERS THEN
RETURN('ERROR_XML');

end f_complete_xml;




function F_curso_actual ( PPIDM NUMBER, PPROGRAMA  VARCHAR2, PNIVEL VARCHAR2, PCAMPUS VARCHAR2  )  RETURN  VARCHAR2
IS

VSALIDA          VARCHAR2(100):='EXITO';
VSEM_ACTUAL      VARCHAR2(100);
vperiodo_act     VARCHAR2(20);
vperiodo_sep     VARCHAR2(10);
Vciclo_gtlg      VARCHAR2(14);
vcalificacion    varchar2(100);
vstudy            number:=0;
no_div            number:=0;


BEGIN

------calcula ciclo---
        begin

        select t1.CTLG     , sp
           into Vciclo_gtlg ,vstudy
        from tztprog t1
        where 1=1
        and t1.pidm = PPIDM
        and t1.programa  = Pprograma
        and   t1.sp = ( select max(t2.sp)
               from tztprog t2
                  where 1=1
                  and t2.pidm = t1.PIDM
                  and T2.PROGRAMA = t1.programa  ) -- se agrego esta validación 22.06.022
        ;
        exception when others then
        VSALIDA  := SQLERRM;
        DBMS_OUTPUT.PUT_LINE('SALIDA ERROR: CALCULAR CICLOS TZTPROG  '|| VSALIDA     );
        end;



        ------- CALCULA NO RVOE--
         BEGIN

            select distinct  SZTDTEC_PERIODICIDAD_SEP
            INTO vperiodo_sep
            from  SZTDTEC zt
            where 1=1
            and  zt.SZTDTEC_CAMP_CODE = PCAMPUS
            and  zt.SZTDTEC_PROGRAM  = PPROGRAMA
            and  zt.SZTDTEC_TERM_CODE  = Vciclo_gtlg
            ;

           -- DBMS_OUTPUT.put_line ('DATOS DE   RVOE:  ' ||Vciclo_gtlg ||'--'|| vperiodo_sep );

          EXCEPTION   WHEN OTHERS     THEN
                   --VSALIDA := SQLERRM;

                if substr(PPROGRAMA,4,2) in ( 'LI', 'DO')  then
                    vperiodo_sep  := 'cuatrimestre';
                 else
                 vperiodo_sep  := 'bimestre';
                 end if;




  END;


--DBMS_OUTPUT.put_line ('AL CALCULAR  bimetrs y cuatri:  '||Vciclo_gtlg ||'-'|| vperiodo_sep ||'-'||substr(VSALIDA,1,100)   );

      IF (vperiodo_sep = '1' OR vperiodo_sep IS NULL ) THEN


               if substr(PPROGRAMA,4,2) in ( 'LI', 'DO')  then
                    vperiodo_sep  := 'cuatrimestre';
                 else
                 vperiodo_sep  := 'bimestre';
                 end if;

         --DBMS_OUTPUT.put_line ('LA VARIABLE ES NULA :  '||vperiodo_sep );

      ELSE

        begin


                select distinct lower(ZSTPARA_PARAM_DESC)
                INTO vperiodo_act
                from ZSTPARA p
                where p.ZSTPARA_MAPA_ID LIKE'%CERT_DIGITAL%'
                AND   p.ZSTPARA_PARAM_VALOR = 'CATALOGO_TIPO_PERIODO'
                and   p.ZSTPARA_PARAM_ID    =  vperiodo_sep
                ;



         exception when otherS   then
         vperiodo_act := NULL;

         VSALIDA := SQLERRM;

         --DBMS_OUTPUT.put_line ('EROOR AL CALCULAR PERIODO ACTUAL:  '||Vciclo_gtlg ||'-'|| VSALIDA   );
         end;

      END IF;


   -- DBMS_OUTPUT.put_line ('YA TIENE TODAS LAS VARIABLES VA CALCULAR EL PERIODO:  '||PPIDM||'-'||PPROGRAMA||'-'||PCAMPUS||'-'||PNIVEL||'-'||Vciclo_gtlg
     --                           ||'-'||vperiodo_sep||'-'|| vperiodo_act );

        IF pnivel = 'LI' then

             --vcalificacion  := ( '6.0,7.0,8.0,9.0,10.0'  );
              no_div         := 4;
             --dbms_output.put_line(' estoy  en nivel '|| pnivel ||' - '||vcalificacion||' - '||  no_div  );

            begin
                 SELECT  case when ROUND(SUM(DATOS.MATERIA)/no_div, 0) in ('01','03') then ROUND(SUM(DATOS.MATERIA)/no_div, 0)
                 when ROUND(SUM(DATOS.MATERIA)/no_div, 0) in ('02') then ROUND(SUM(DATOS.MATERIA)/no_div, 0)
                 when ROUND(SUM(DATOS.MATERIA)/no_div, 0) in ('04','05','06') then ROUND(SUM(DATOS.MATERIA)/no_div, 0)
                 when ROUND(SUM(DATOS.MATERIA)/no_div, 0) in ('07') then ROUND(SUM(DATOS.MATERIA)/no_div, 0)
                 when ROUND(SUM(DATOS.MATERIA)/no_div, 0) in ('08') then ROUND(SUM(DATOS.MATERIA)/no_div, 0)
                 when ROUND(SUM(DATOS.MATERIA)/no_div, 0) in ('09') then ROUND(SUM(DATOS.MATERIA)/no_div, 0)
                 when ROUND(SUM(DATOS.MATERIA)/no_div, 0) in ('10') THEN ROUND(SUM(DATOS.MATERIA)/no_div, 0)
                 when ROUND(SUM(DATOS.MATERIA)/no_div, 0) in ('11','12') then ROUND(SUM(DATOS.MATERIA) /no_div, 0)
                end periodos
               into VSEM_ACTUAL
                    FROM
                    (
                    select distinct  COUNT (BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB)  MATERIA
                    from sfrstcr f, ssbsect bb
                    where 1=1
                    and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                    and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                    and f.SFRSTCR_PIDM = ppidm
                    and F.SFRSTCR_RSTS_CODE  = 'RE'
                    and substr(F.SFRSTCR_TERM_CODE,5,1)  not in (8,9)
                    and F.SFRSTCR_GRDE_CODE  IN ( '6.0','7.0','8.0','9.0','10.0')
                    and F.SFRSTCR_GRDE_CODE   not in ( 'NP','NA')
                    and f.SFRSTCR_STSP_KEY_SEQUENCE = vstudy
                    AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%H%')
                    AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%SESO%')
                    UNION
                    select distinct  count(BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB) MATERIA
                    from sfrstcr f, ssbsect bb
                    where 1=1
                    and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                    and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                    and f.SFRSTCR_PIDM = ppidm
                    and F.SFRSTCR_RSTS_CODE  = 'RE'
                    and substr(F.SFRSTCR_TERM_CODE,5,1)  not in (8,9)
                    and F.SFRSTCR_GRDE_CODE  IS NULL
                    and f.SFRSTCR_STSP_KEY_SEQUENCE = vstudy
                    AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%H%')
                    AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%SESO%')
                    ) DATOS

                    ;



             exception when others then
               VSEM_ACTUAL := null;
               VSALIDA := SQLERRM;
              DBMS_OUTPUT.PUT_LINE('ERROR EN SEMESTRE LETRAS:  '|| PPROGRAMA||'-'||ppidm||'-'||pnivel||'-'||pCAMPUS||'-++--'||VSEM_ACTUAL );
             end;



         elsif pnivel IN  ('MA', 'DO')   then

            -- vcalificacion  :=  '   and F.SFRSTCR_GRDE_CODE  IN '|| '(''7.0'''||',''8.0'''||',''9.0'''||',''10.0'')';
             no_div         := 2;
             dbms_output.put_line(' estoy  en nivel '|| pnivel ||' - '||vcalificacion||' - '||  no_div  );


            BEGIN

              select max(datos.NOMBRE_AREa)
               INTO VSEM_ACTUAL
                from (
                select DISTINCT case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)
                 when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)
                 when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)
                 when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)
                 when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)
                 when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)
                 when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)
                 when substr(smrpaap_area,9,2) in ('11') then substr(smrpaap_area,9,2)
                 when substr(smrpaap_area,9,2) in ('12') then substr(smrpaap_area,9,2)
                 else vperiodo_act
                end
                else vperiodo_act
                end   nombre_area

                 from SMBAGEN ge, smrpaap ma, smrarul ru,ZSTPARA, smralib li
                where 1=1
                    and ge.SMBAGEN_ACTIVE_IND='Y'
                    and GE.SMBAGEN_AREA  = ma.SMRPAAP_AREA --'UTLTSS0310'
                    and ma.SMRPAAP_TERM_CODE_EFF=ge.SMBAGEN_TERM_CODE_EFF
                    and ru.SMRARUL_AREA  = ma.SMRPAAP_AREA
                    and LI.SMRALIB_AREA  = ma.SMRPAAP_AREA
                    and  ma.SMRPAAP_PROGRAM   = PPROGRAMA  --'UTELIAAFED'
                    and SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW in ( select -- SFRSTCR_TERM_CODE,
                                             BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB  MATERIA
                                            from sfrstcr f, ssbsect bb
                                            where 1=1
                                            and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
                                            and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
                                            and f.SFRSTCR_PIDM = PPIDM
                                            and substr(F.SFRSTCR_TERM_CODE,5,1)  not in (8,9)
                                            AND f.SFRSTCR_TERM_CODE = ( SELECT MAX(f2.SFRSTCR_TERM_CODE)
                                                                   FROM SFRSTCR F2, ssbsect bb2
                                                                    WHERE 1=1
                                                                    AND F.SFRSTCR_PIDM  =  F2.SFRSTCR_PIDM
                                                                     and F2.SFRSTCR_CRN  = BB2.SSBSECT_CRN
                                                                     and substr(F.SFRSTCR_TERM_CODE,5,1)  not in (8,9)
                                                                      and F2.SFRSTCR_TERM_CODE  = BB2.SSBSECT_TERM_CODE
                                                                       AND BB2.SSBSECT_SUBJ_CODE||BB2.SSBSECT_CRSE_NUMB NOT LIKE('%H%')
                                                                       AND BB2.SSBSECT_SUBJ_CODE||BB2.SSBSECT_CRSE_NUMB NOT LIKE('%SESO%') )
                                            AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%H%')
                                            AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%SESO%') )
                and ZSTPARA_MAPA_ID='ORDEN_CUATRIMES'
                and  SMRALIB_LEVL_CODE  = Pnivel --'LI'
                and  SUBSTR(ZSTPARA_PARAM_ID,1,3) = PCAMPUS --'UTL'
                )  datos
                order by datos.NOMBRE_AREA desc;


          EXCEPTION WHEN OTHERS  THEN
            VSEM_ACTUAL:= null;
          DBMS_OUTPUT.PUT_LINE('ERROR EN SEMESTRE LETRAS:  '|| PPROGRAMA||'-'||ppidm||'-'||pnivel||'-'||pCAMPUS||'-++--'||VSEM_ACTUAL );
          END;



        end if;

--DBMS_OUTPUT.PUT_LINE('al final de FCURSO ACTUAL:  '|| PPROGRAMA||'-'||ppidm||'-'||pnivel||'-'||pCAMPUS||'-'|| VSALIDA );

IF VSALIDA = 'EXITO'  THEN

RETURN VSEM_ACTUAL;

ELSE
RETURN 0;

END IF;


EXCEPTION WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('ERROR EN FCURSO ACTUAL:  '|| PPROGRAMA||'-'||ppidm||'-'||pnivel||'-'||pCAMPUS||'-'|| VSALIDA );
RETURN VSALIDA;

END F_curso_actual;


FUNCTION F_DESCARGA_XML (PMATRICULA VARCHAR2, PTIPO VARCHAR2, PFINI VARCHAR2, PFIN VARCHAR2  ) RETURN PKG_CERTIFICADO_DIG_2_0.DESCARGA_type IS

DOCUMENTOS_DESCARGAS  PKG_CERTIFICADO_DIG_2_0.DESCARGA_type;

vl_error     VARCHAR2(500);


BEGIN

--DBMS_OUTPUT.PUT_LINE('FECHAS '||PFINI ||'<'|| PFIN  );

--IF PFINI < PFIN  THEN

--DBMS_OUTPUT.PUT_LINE('FECHAS '||PFINI ||'<'|| PFIN  );

OPEN  DOCUMENTOS_DESCARGAS  for 
                   SELECT *
                            FROM
                            (
                            SELECT DATOS.MATRICULA, DATOS.PROGRAMA, DATOS.FECHA,
                            CASE WHEN DATOS.TIPO = 'C'  THEN 'C'
                                 WHEN DATOS.TIPO = 'T' AND SUBSTR(DATOS.PROGRAMA,4,2) = 'LI' THEN 'T'
                                  ELSE 'G'
                         END TIPO,
                         datos.nivel
                        FROM (select z.SZTRECE_ID matricula, z.SZTRECE_PROGRAM_CERTIF PROGRAMA, z.SZTRECE_ACTIVITY_DATE FECHA, 'C' TIPO, SUBSTR(z.SZTRECE_PROGRAM_CERTIF,4,2) nivel
                               from sztrece z
                            where 1=1
                            --and SZTRECE_VAL_FIRMA  = 2
                                and z.SZTRECE_XML_IND     = 2
                                and TRUNC(z.SZTRECE_ACTIVITY_DATE) between (Pfini) and (Pfin)
                                and Z.SZTRECE_MODO  =  (select MAX(t2.SZTRECE_MODO)  
                                                               from SZTRECE t2
                                                         where 1=1
                                                           and Z.SZTRECE_PIDM_CERTIF = t2.SZTRECE_PIDM_CERTIF
                                                           and Z.SZTRECE_PROGRAM_CERTIF    = t2.SZTRECE_PROGRAM_CERTIF  )
                            UNION
                       SELECT t1.SZTTIDI_ID MATRICULA, t1.SZTTIDI_PROGRAM PROGRAMA , t1.SZTTIDI_ACTIVITY_DATE FECHA,'T' TIPO, SUBSTR(t1.SZTTIDI_PROGRAM,4,2) nivel
                          FROM SZTTIDI t1
                            WHERE 1=1
                            AND t1.SZTTIDI_XML_IND = 2
                            AND t1.SZTTIDI_VAL_FIRMA      = 2
                            and TRUNC(t1.SZTTIDI_ACTIVITY_DATE) between (Pfini) and (Pfin)
                            and T1.SZTTIDI_MODO = (select MAX(t2.SZTTIDI_MODO)  
                                                       from szttidi t2
                                                         where 1=1
                                                           and t1.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                           and t1.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  )
                            ORDER BY 3 DESC
                            ) DATOS
                            WHERE 1=1
                            ) DATOS2
                            WHERE 1=1
                            AND DATOS2.TIPO = NVL(UPPER(PTIPO), DATOS2.TIPO)
                            AND DATOS2.MATRICULA = NVL(PMATRICULA, DATOS2.MATRICULA)
                            ;

  return DOCUMENTOS_DESCARGAS;




 Exception
            When others  then
               vl_error := 'PKG_QR_DIG.DOCUMENTOS_DESCARGAS: ' || sqlerrm;
           return DOCUMENTOS_DESCARGAS;


END F_DESCARGA_XML;

FUNCTION F_INSERTA_REGS (PRESPONSABLE NUMBER, PPIDM NUMBER,PPROGRAM VARCHAR2, PACTIVY_IND NUMBER default 1, PUSER VARCHAR2,PMODO NUMBER )  
RETURN VARCHAR2
IS

-- ESTA FUNCION  es para insertar el nuevo xml o el regenerado xml de los certificados de esta forma se puede llevar 
--  una bitacora de regeneraciones glovicx 18.07.2024
VMATRICULA   VARCHAR2(16);
VSALIDA      VARCHAR2(300):= 'EXITO';


BEGIN

VMATRICULA := F_GetSpridenID(PPIDM);

       begin
                        
        insert into SZTRECE
        (SZTRECE_IDRESPONSABLE,
        SZTRECE_PIDM_CERTIF,
        SZTRECE_PROGRAM_CERTIF,
        SZTRECE_ACTIVY_IND,
        SZTRECE_ACTIVITY_DATE,
        SZTRECE_ID,
        SZTRECE_USER,
        SZTRECE_VAL_FIRMA,
        SZTRECE_XML_IND,
        SZTRECE_MODO,
        SZTRECE_FECHA_BANNER  )
        values(PRESPONSABLE,PPIDM, PPROGRAM, PACTIVY_IND,sysdate,VMATRICULA,PUSER, 0,1,PMODO, SYSDATE);
        exception when others  then
            null;
            VSALIDA := 'eRROR AL INSERTAR EN ZTRECE'||SQLERRM;
            
        end;

COMMIT;

  RETURN (VSALIDA);
                    
EXCEPTION WHEN OTHERS THEN 
VSALIDA := 'ERROR GRAL AL INSERTAR EN ZTRECE' || SQLERRM;

END F_INSERTA_REGS;



BEGIN

   P_inicio (ppidm,
             pprograma,
             pindica,
             ptipo,
             p_responsable);
   NULL;
EXCEPTION
   WHEN OTHERS
   THEN
      NULL;
END PKG_CERTIFICADO_DIG_2_0;
/

DROP PUBLIC SYNONYM PKG_CERTIFICADO_DIG_2_0;

CREATE OR REPLACE PUBLIC SYNONYM PKG_CERTIFICADO_DIG_2_0 FOR BANINST1.PKG_CERTIFICADO_DIG_2_0;


GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO CONSULTA WITH GRANT OPTION;

GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO SIU_CONN_BI WITH GRANT OPTION;

GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO SIU_CONN_EAFIT WITH GRANT OPTION;

GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO SIU_CONN_UMD WITH GRANT OPTION;

GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO SIU_CONN1 WITH GRANT OPTION;

GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO SIU_CONN2 WITH GRANT OPTION;

GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO SIU_CONN3 WITH GRANT OPTION;

GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO SIU_CONN4 WITH GRANT OPTION;

GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO SIU_CONN5 WITH GRANT OPTION;

GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO SIU_CONN6 WITH GRANT OPTION;

GRANT EXECUTE ON BANINST1.PKG_CERTIFICADO_DIG_2_0 TO SPOTLIGHT_USER WITH GRANT OPTION;
