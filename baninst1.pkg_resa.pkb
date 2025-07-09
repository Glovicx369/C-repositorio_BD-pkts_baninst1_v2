DROP PACKAGE BODY BANINST1.PKG_RESA;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_Resa
IS
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 -- Author : glovicx
 -- Created : 05.Oct.2015
 -- Purpose : PKT con todas las utilerias que utiliza para el desarrollo V2 Resa.
 ---CHANGE GLOVICX    09 ENERO 2019...
 --  SE MODIFICA LA FUNCION  F_UPDATE_SPREMRG PARA ACTUALIZAR LOS DATOS DE FACTURACION DESDE SIU
 -- SE CAMBIA LA FUNCION PARA GENERAR LOS ID O MATRICULAS AHORA ES UNA SECUENCIA CON SU NUMERACIÓN INDEPENDIENTES POR CAMPUS GLOVICX 14/12/2020
---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

vsalida VARCHAR(100);
vid_u VARCHAR2(9);
vpidm_u INTEGER(8);
vperson varchar2(1);
vnum_sal NUMBER(3);
vappl_no_admin number(3);
lv_msgerr varchar2(2000);

PROCEDURE sp_sobterm ( pterm in varchar2 default null , cur_sobterm OUT pkg_Resa.sobterm_type ) is

vtipo varchar2(12);

begin

vtipo := pterm;

open cur_sobterm for select SOBPTRM_START_DATE, SOBPTRM_WEEKS
 from sobptrm
 where (SOBPTRM_TERM_CODE = vtipo or vtipo is null ) ;
end sp_sobterm;

FUNCTION sp_per_vigentes ( nivel in varchar2 , campus in varchar2) Return pkg_Resa.periodos_type
IS
 cur_periodos BANINST1.pkg_Resa.periodos_type;
 vl_error varchar2(2500);

 begin

 open cur_periodos for select distinct stvterm_code codigo, stvterm_code||' '||stvterm_desc periodo
                                                        from stvterm, sobptrm, szvcamp, sztperi, sztptrm
                                                        where sobptrm_ptrm_code='1'
                                                        and     (trunc(sysdate) between trunc(sobptrm_start_date) and  trunc(sobptrm_end_date)  or  ( trunc(sobptrm_start_date) > trunc(sysdate)))
                                                        and    sobptrm_term_code=stvterm_code
                                                        and    szvcamp_camp_code=campus
                                                        and    sztperi_camp_code=szvcamp_camp_code
                                                        and    sztperi_levl_code=nivel
                                                        and    substr(stvterm_code,5,1)=to_char(sztperi_perio)
                                                        and    substr(stvterm_code,1,2)=szvcamp_camp_alt_code
                                                        and    sztperi_camp_code=sztptrm_camp_code
                                                        and    sztperi_levl_code=sztptrm_levl_code
                                                        and    sobptrm_term_code=sztptrm_term_code
                                          --              and    sobptrm_start_date >= trunc(sysdate)-7
                                                       order by stvterm_code;

                return cur_periodos;
    Exception
            When others  then
               vl_error := 'PKG_RESA.ERROR.sp_per_vigentes: ' || sqlerrm;
           return cur_periodos;
    end sp_per_vigentes;

PROCEDURE sp_rates ( ptipo  in varchar2 default null, cur_rate  OUT pkg_Resa.rates_type  )   is

vtipo  varchar2(1);
begin

vtipo   := ptipo;

open cur_rate for select stvrate_code, stvrate_desc
                            from stvrate
                            where (  substr(stvrate_code,1,1)  =  vtipo    or   substr(stvrate_code,1,1)   in ('P','C','A','J') or  vtipo is null  )
                              order by 1 desc;


null;
end sp_rates;


PROCEDURE sp_products  (  cur_products  OUT pkg_Resa.products_type  )   is

begin

open cur_products    for     select   TBBDETC_DETAIL_CODE, TBBDETC_DESC, TBBDETC_AMOUNT
                                        from tbbdetc
                                           where TBBDETC_PAYT_CODE = 'A'  ;

null;
end sp_products;


PROCEDURE sp_campus  (  cur_campus   OUT pkg_Resa.campus_type  )    is

begin

open cur_campus    for   select STVCAMP_CODE, STVCAMP_DESC    from stvcamp;


null;
end sp_campus;

PROCEDURE sp_nivel    (  ptipo  in varchar2 default null ,  cur_nivels  OUT pkg_Resa.levl_type  )  is


vtipo  varchar2(4);

begin

vtipo   := ptipo;

open cur_nivels  for   select  distinct STVLEVL_CODE, STVLEVL_DESC
                                  from STVLEVL  nlv , SOBCURR sob
                                  where nlv.STVLEVL_CODE  =  sob.SOBCURR_LEVL_CODE
                                  and (SOBCURR_CAMP_CODE =   vtipo  or  vtipo is null)  ;



end sp_nivel;

PROCEDURE sp_program  ( pcamp  in varchar2 default null,  plevl    in varchar2 default null,    cur_programs  OUT pkg_Resa.programs_type  )  is

vcamp  varchar2(5);
vlevl  varchar2(4);

begin

vcamp   := pcamp;
vlevl  := plevl;

open cur_programs for  select  SMRPRLE_LEVL_CODE, SMRPRLE_PROGRAM, SMRPRLE_PROGRAM_DESC
                                    from smrprle
                                        where (SMRPRLE_CAMP_CODE = vcamp or vcamp is  null )
                                        and     (SMRPRLE_LEVL_CODE  = vlevl    or  vlevl is  null );




end sp_program;


procedure sp_matching (  p_entity_cde  varchar2 default null , p_last_name varchar2 default null  , p_first_name varchar2 default null  ,
 p_ssn varchar2 default null  , p_street_line2 varchar2 default null  , p_street_line3  varchar2 default null  , p_city   varchar2 default null   ,
 p_stat_code   varchar2 default null   ,p_zip  varchar2 default null   , p_natn_code  varchar2 default null , p_cnty_code  varchar2 default null  ,
 p_phone_area   varchar2 default null  ,  p_phone_number  varchar2 default null  , p_phone_ext varchar2 default null,
 p_birth_day   varchar2 default null  , p_birth_mon varchar2 default null  ,p_birth_year varchar2 default null ,
 p_sex  varchar2 default null  , p_email_address varchar2 default null  , p_atyp_code varchar2 default null  , p_tele_code  varchar2 default null  ,
 p_emal_code  varchar2 default null  ,  p_asrc_code   varchar2 default null, p_cmsc_code  varchar2 ,p_id_code  varchar2, p_addid  varchar2, ps_match  OUT  varchar2 , cur_matching  OUT  pkg_Resa.match_type   )   is
  /*
  proceso que se encarga de hacer el match  o la comparacion para ver si una persona ya existe en la bd de banner
  los procesos nativos se configuran en la forma GOAMTCH.
  ahi va la regla de validacion  que se mandaen la segunda parte del proceso.
  los campos que esten configurados en este forma son los que va tomar unicamente aun que aqui por este proceso le enviemos todos
  solo va tomar los que fueron indicados o configurados en esa forma.
  author:  glovicx...
  date  :  05 oct  2015


  */
 lv_match_ind  varchar2(10);
 lv_save_pidm  spriden.spriden_pidm%TYPE;




  begin

  /* Primera  parte  >>    insert data fields into general matching temp table */
  gokcmpk.p_insert_gotcmme(
      p_last_name   => p_last_name,     ----'Ledesma/HernÃ¡ndez',
      p_first_name  => p_first_name , ----'Anamaria',
      p_entity_cde  => p_entity_cde,    ----P
      p_email_address => p_email_address , ---- 'al.h12@hotmail.com',
      p_ssn                =>  p_ssn ,
      p_street_line2    => p_street_line2,
      p_street_line3   => p_street_line3,
      p_city               => p_city,
      p_stat_code     =>  p_stat_code,
      p_zip               => p_zip,
      p_natn_code    => p_natn_code,
      p_cnty_code     => p_cnty_code,
      p_phone_area   =>  p_phone_area,
      p_phone_number => p_phone_number,
      p_phone_ext      => p_phone_ext,
      p_birth_day     => p_birth_day,
      p_birth_mon  =>  p_birth_mon,
      p_birth_year   => p_birth_year,
      p_sex             => p_sex,
      p_atyp_code         => p_atyp_code,
      p_tele_code        => p_tele_code,
      p_emal_code     => p_emal_code,
      p_asrc_code      => p_asrc_code,
      p_addid_code    => p_id_code, --  esete campo son los 2 primeros nuemros de ID   que hacen referencia al  campus = CAMP
      p_addid             => p_addid  --      este es la descripcion del campus.  = 01
--
      );
  COMMIT;

  /*    segunda parte  >     Execute common matching procedure */
  gokcmpk.p_common_matching(
      p_cmsc_code        => p_cmsc_code,    ----'PERSONA',
      p_match_status_out => lv_match_ind,
      p_match_pidm_out   => lv_save_pidm);
  /* Call function to retrieve current ID */
  /* valid values       */
  /*   M - MATCH        */
  /*   N - NEW          */
  /*   S - SELECT from GOVCMRT;      */
  --------Tercera parte   salidas --------------
  if lv_match_ind = 'M' then
   -- dbms_output.put_line ('La persona ya existe   El pidm es:  ' || lv_save_pidm || ' Matricula es:  ' || gb_common.f_get_id (lv_save_pidm)  ||'  Campus:   '||  p_addid );
    ps_match  := ('La persona ya existe   El pidm es:  ' || lv_save_pidm || ' Matricula es:  ' || gb_common.f_get_id (lv_save_pidm)  ||'  Campus:   '||  p_addid );

    open cur_matching  for   SELECT go.*,  s.spriden_pidm, s.spriden_id, gm.GOREMAL_EMAIL_ADDRESS, SP.SPBPERS_BIRTH_DATE
                                            FROM gotcmme go, spriden s , goremal gm, spbpers sp
                                            where s.spriden_pidm = gm.goremal_pidm
                                            and   s.spriden_pidm =  SP.SPBPERS_PIDM
                                            and s.spriden_pidm = lv_save_pidm
                                            and ( GM.GOREMAL_EMAL_CODE like ('%')  OR  GM.GOREMAL_EMAL_CODE IS NULL)  ;

     --open cur_matching  for   SELECT   * FROM gotcmme;
   elsif  lv_match_ind = 'S' then
    --dbms_output.put_line ('Indicador  ' || lv_match_ind || '  Existen posibles Coincidencias.  ' || lv_save_pidm);
      ps_match  :=   ('Indicador  ' || lv_match_ind || '  Existen posibles Coincidencias.  ' || lv_save_pidm);
    open cur_matching  for   SELECT go.*,  s.spriden_pidm, s.spriden_id, gm.GOREMAL_EMAIL_ADDRESS, SP.SPBPERS_BIRTH_DATE
                                            FROM gotcmme go, spriden s , goremal gm, spbpers sp
                                            where s.spriden_pidm = gm.goremal_pidm
                                            and   s.spriden_pidm =  SP.SPBPERS_PIDM
                                            and s.spriden_pidm = lv_save_pidm
                                            and ( GM.GOREMAL_EMAL_CODE like ('%')  OR  GM.GOREMAL_EMAL_CODE IS NULL)  ;
    else

    --dbms_output.put_line  ('Indicador  ' || lv_match_ind || '  No Existen Coincidencias.  ' || lv_save_pidm);
      ps_match  :=   ('Indicador  ' || lv_match_ind || '  No Existen Coincidencias.  ');


  end if;




  end  sp_matching;


PROCEDURE    sp_match_type  (  cur_match_type   OUT pkg_Resa.match2_type  )  is

begin
open cur_match_type  for SELECT  GORCMSR_CMSC_CODE   FROM gorcmsr;

end sp_match_type;


/**/
  /* Persona general*/
  FUNCTION sp_general (P_LAST_NAME           VARCHAR2,
                       P_FIST_NAME           VARCHAR2,
                       P_ENTITY_IND          VARCHAR2,
                       p_campus              VARCHAR2,
                       vs_id             OUT VARCHAR2,
                       vs_pidm           OUT VARCHAR2,
                       v_matricula    IN     VARCHAR2 DEFAULT NULL,
                       v_pidm         IN     VARCHAR2 DEFAULT NULL
                       )  RETURN  VARCHAR2
  IS
     vl_error   VARCHAR2 (2500) := 'Exito';
     VL_ID      NUMBER;
  BEGIN
     IF v_matricula IS NULL THEN
  --      DBMS_OUTPUT.PUT_LINE('Registro uno');

      BEGIN
         vperson := P_ENTITY_IND;
         --vid_u := GB_COMMON.f_generate_id();   ------SE TIENENN QUE IR COMO VARIABLES GLOBALES PARA LOS DEMAS PROCESOS
         --select general.id_sequence.nextval into vid_u from dual;
         --vid_u := GZ_UTLCOMMON.f_genera_id (p_campus);

           vid_u :=  BANINST1.F_ID_CAMPUS(p_campus);


         --- vs_id  := p_campus||substr(vid_u,3,9);
         --DBMS_OUTPUT.PUT_LINE(vid_u);
         vpidm_u := GB_COMMON.f_generate_pidm ();
         --DBMS_OUTPUT.PUT_LINE(vpidm_u);
         gb_identification.p_create (P_ID_INOUT     => vid_u,
                                     P_LAST_NAME    => INITCAP (P_LAST_NAME),
                                     P_FIRST_NAME   => INITCAP(P_FIST_NAME),
                                     P_PIDM_INOUT   => vpidm_u,
                                     P_ROWID_OUT    => Vsalida,
                                     p_entity_ind   => vperson);
--         BANINST1.gb_identification.p_create(vid_u, 'gutierrez', 'stephi',vpidm_u,vsalida, vperson);
         ---DBMS_OUTPUT.PUT_LINE('GENERA ID  ' ||vs_id || 'GENERA PIDM  '|| vpidm_u  );
         vs_id := vid_u;
         vs_pidm := vpidm_u;
         VL_ID :=NULL;
         COMMIT;
      EXCEPTION
      WHEN OTHERS
      THEN
      vl_error := 'Se presento el Error al crear el registro '||sqlerrm;
      END;


      IF VL_ERROR = 'Exito' THEN

        BEGIN
            SELECT COUNT(SPRIDEN_ID)
              INTO VL_ID
              FROM SPRIDEN
             WHERE SPRIDEN_PIDM = vpidm_u
             AND SPRIDEN_CHANGE_IND IS NULL;
        EXCEPTION
        WHEN OTHERS THEN
        VL_ID:= 0;
        vs_id:= NULL;
        vs_pidm:=NULL;
        END;

        IF VL_ID = 0 THEN
        VL_ERROR:= 'No existe registro en SPRIDEN ';
        END IF;

      END IF;

      RETURN vl_error;

    ELSIF  v_matricula IS NOT NULL  and v_pidm is null THEN
  -- DBMS_OUTPUT.PUT_LINE('Registro dos' ||'*'||v_matricula||'*'||v_pidm);
      BEGIN
         UPDATE SPRIDEN
            SET SPRIDEN_FIRST_NAME = P_FIST_NAME,
            SPRIDEN_LAST_NAME = P_LAST_NAME
            WHERE SPRIDEN_ID= v_matricula;
            commit;
            RETURN vl_error;
      EXCEPTION
          WHEN OTHERS
          THEN
          vl_error := 'Se presento el Error al actualizar el registro '||sqlerrm;
       RETURN vl_error;
      END;

    ELSIF  v_matricula IS NOT NULL  and v_pidm is not  null THEN
      vpidm_u := NULL;
      --DBMS_OUTPUT.PUT_LINE('Registro TRES' ||'*'||v_matricula||'*'||v_pidm);
      BEGIN

             vpidm_u := GB_COMMON.f_generate_pidm ();

                If vl_error = 'Exito' then
                    Begin
                               Insert into spriden
                                select    vpidm_u,
                                             v_matricula,
                                             SPRIDEN_LAST_NAME ,
                                             SPRIDEN_FIRST_NAME ,
                                             SPRIDEN_MI ,
                                             null  ,
                                             SPRIDEN_ENTITY_IND  ,
                                             sysdate  ,
                                             'V-2'   ,
                                             'SIU-VENTA'       ,
                                             SPRIDEN_SEARCH_LAST_NAME  ,
                                             SPRIDEN_SEARCH_FIRST_NAME   ,
                                             SPRIDEN_SEARCH_MI ,
                                             SPRIDEN_SOUNDEX_LAST_NAME,
                                             SPRIDEN_SOUNDEX_FIRST_NAME,
                                             SPRIDEN_NTYP_CODE,
                                             SPRIDEN_CREATE_USER,
                                             SPRIDEN_CREATE_DATE ,
                                             'V-2',
                                             SPRIDEN_CREATE_FDMN_CODE,
                                             SPRIDEN_SURNAME_PREFIX,
                                             NULL ,
                                             SPRIDEN_VERSION,
                                             'V-2',
                                             SPRIDEN_VPDI_CODE
                                from spriden
                                where spriden_pidm = v_pidm
                                AND SPRIDEN_CHANGE_IND IS  NULL;
                         Exception
                        When Others then
                        vl_error := 'Se presento un Error al insertar doble registro'||sqlerrm;
                      End;
                End if;
                 vs_pidm := vpidm_u;
              RETURN  vl_error;
      EXCEPTION
          WHEN OTHERS
          THEN
          vl_error := 'Se represento el error al insertar doble registro general '||sqlerrm;
           RETURN vl_error;
      END;
    END IF;
  RETURN vl_error;
  EXCEPTION
      WHEN OTHERS
      THEN
   RETURN 'ERROR PKG_RESA.sp_general: ';
  END sp_general;

/**/


/*
FUNCTION sp_general (P_LAST_NAME    VARCHAR2, P_FIST_NAME    VARCHAR2,  P_ENTITY_IND   VARCHAR2, p_campus  varchar2,     vs_id  out varchar2, vs_pidm out varchar2 ) Return Varchar2
IS

vl_error varchar2(2500):=null;

 BEGIN

 vperson  := P_ENTITY_IND ;

 ---  vid_u := GB_COMMON.f_generate_id();   ------SE TIENENN QUE IR COMO VARIABLES GLOBALES PARA LOS DEMAS PROCESOS
  --select general.id_sequence.nextval into vid_u from dual;
    vid_u := GZ_UTLCOMMON.f_genera_id(p_campus);

 --- vs_id  := p_campus||substr(vid_u,3,9);

  --DBMS_OUTPUT.PUT_LINE(vid_u);
  vpidm_u := GB_COMMON.f_generate_pidm();

  --DBMS_OUTPUT.PUT_LINE(vpidm_u);
  gb_identification.p_create(P_ID_INOUT => vid_u, P_LAST_NAME => P_LAST_NAME, P_FIRST_NAME => P_FIST_NAME, P_PIDM_INOUT => Vpidm_u, P_ROWID_OUT => Vsalida, p_entity_ind => vperson);
-- BANINST1.gb_identification.p_create(vid_u, 'gutierrez', 'stephi',vpidm_u,vsalida, vperson);

  ---DBMS_OUTPUT.PUT_LINE('GENERA ID  ' ||vs_id || 'GENERA PIDM  '|| vpidm_u  );

    vs_id  := vid_u;
    vs_pidm  := vpidm_u;
commit;
vl_error:='Proceso Exitoso';
Return vl_error;

Exception
    When Others then
     vl_error:= 'ERROR PKG_RESA.sp_general: ' ||sqlerrm;
     Return vl_error;

END sp_general;

*/


   FUNCTION sp_carga_identficador (vpidm_u VARCHAR2, P_ADDITIONAL_ID    VARCHAR2 , P_ADID_CODE    VARCHAR2, P_USER_ID    VARCHAR2, P_DATA_ORIGIN    VARCHAR2) RETURN VARCHAR2
   is

    vl_error varchar2(2500) :=null;

    begin

      GB_ADDITIONAL_IDENT.P_CREATE(vpidm_u, P_ADDITIONAL_ID, P_ADID_CODE, 'SistemaV2' , 'Resa', vsalida);
      --dbms_output.put_line('GENERA IDENTIFICADOR  '|| P_ADID_CODE );

    commit;
    vl_error:='Proceso Exitoso';
    Return vl_error;

    Exception
        When Others then
            vl_error:= 'Error PKG_RESA.sp_carga_identficador: ' ||sqlerrm;
            Return vl_error;

    end sp_carga_identficador;


    FUNCTION  sp_persona (vpidm_u  varchar2,  P_BIRTH_DATE    DATE, P_SEX    VARCHAR2,   P_EMAL_CODE    varchar2  ,P_MAIL_ADDRESS  varchar2 ) RETURN Varchar2
    is
    vl_error varchar2(2500):=null;
    vl_v Varchar2(2500);
    begin


            GB_BIO.P_CREATE(p_pidm => vpidm_u, p_birth_date => P_BIRTH_DATE, p_sex => upper(P_SEX), p_rowid_out => vsalida);
              --dbms_output.put_line('GENERA PERSONA BDAY '||vpidm_u );

      --------------------------aqui va el llamado a procedure  crea NIP-----------

                    vl_v:=sp_mail(vpidm_u, P_EMAL_CODE, P_MAIL_ADDRESS );
                    pkg_resa.sp_create_pin ( vpidm_u);
      commit;

             --para generar el legal name
        update SPBPERS
            set SPBPERS_LEGAL_NAME = (select replace (SPRIDEN_LAST_NAME,'/',' ')|| ' ' || SPRIDEN_FIRST_NAME FROM SPRIDEN WHERE SPRIDEN_PIDM = vpidm_u and SPRIDEN_CHANGE_IND is null)
        where SPBPERS_PIDM= vpidm_u;
        commit;



   for c in ( select spbpers_pidm ,translate ( UPPER(SPBPERS_LEGAL_NAME), 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU') legal
            from spbpers Where spbpers_pidm = vpidm_u
            ) loop

   update spbpers
   set SPBPERS_LEGAL_NAME = c.legal
   Where spbpers_pidm = c.spbpers_pidm;


   End loop;

Commit;



        vl_error:= 'Proceso Exitoso';
        Return vl_error;

    Exception
        when others then
        vl_error := 'Error PKG_RESA.sp_persona: '||sqlerrm;
        Return vl_error;

    end sp_persona;

--    PROCEDURE sp_mail(vpidm_u varchar2, P_EMAL_CODE    VARCHAR2, P_MAIL_ADDRESS    VARCHAR2 )
--    is
--    vl_tipo varchar2(1);
--    begin
--
--                    if P_EMAL_CODE = 'PRIN' THEN vl_tipo:='Y';
--                    ELSE vl_tipo:='N';
--                    END IF;
--
--              GB_EMAIL.P_CREATE(p_pidm => vpidm_u, p_emal_code => P_EMAL_CODE , p_email_address =>P_MAIL_ADDRESS, p_rowid_out => vsalida);
--              --dbms_output.put_line('GENERA MAIL '||P_EMAL_CODE );
--
--
--    end sp_mail;

--SE GENERA LA FUNCIÓN  PARA CACHAR EL ERROR--



FUNCTION sp_mail(vpidm_u in varchar2 default null, P_EMAL_CODE    VARCHAR2, P_MAIL_ADDRESS    VARCHAR2,  v_matricula  IN  VARCHAR2 DEFAULT NULL, old_pidm in varchar2 DEFAULT NULL ) RETURN Varchar2
    is
    vl_tipo varchar2(1);
    vl_error Varchar2(2500):=null;
   -- vpidm_u VARCHAR(12);

BEGIN
    IF  v_matricula IS NULL THEN

                   IF P_EMAL_CODE = 'PRIN' THEN
                        vl_tipo:='Y';
                   ELSE
                        vl_tipo:='N';
                   END IF;

                  If  vl_tipo ='Y' then
                       BEGIN
                              GB_EMAIL.P_CREATE(p_pidm => vpidm_u,
                                                            p_emal_code => P_EMAL_CODE ,
                                                            p_email_address =>P_MAIL_ADDRESS,
                                                            p_preferred_ind => 'Y',
                                                            p_rowid_out => vsalida);
                              --dbms_output.put_line('GENERA MAIL '||P_EMAL_CODE );
                            RETURN 'Proceso  PKG_RESA.sp_mail Exitoso';
                       Exception
                             When others then
                             Return 'Error PKG_RESA.sp_mai';
                       END;
                  ElsIF  vl_tipo ='N' then
                       BEGIN
                              GB_EMAIL.P_CREATE(p_pidm => vpidm_u,
                                                            p_emal_code => P_EMAL_CODE ,
                                                            p_email_address =>P_MAIL_ADDRESS,
                                                            p_preferred_ind => 'N',
                                                            p_rowid_out => vsalida);
                              --dbms_output.put_line('GENERA MAIL '||P_EMAL_CODE );
                            RETURN 'Proceso  PKG_RESA.sp_mail Exitoso';
                       Exception
                             When others then
                             Return 'Error PKG_RESA.sp_mai';
                       END;
                  End if;
   ELSIF v_matricula IS NOT NULL and old_pidm is null THEN
            BEGIN

                    UPDATE GOREMAL
                    SET GOREMAL_EMAIL_ADDRESS = P_MAIL_ADDRESS,
                    GOREMAL_USER_ID = user, GOREMAL_PREFERRED_IND = 'Y'
                    WHERE GOREMAL_PIDM = (select spriden_pidm from spriden where spriden_id = v_matricula) AND GOREMAL_EMAL_CODE = 'PRIN';
                    COMMIT;
                    RETURN 'Actualización de correo exitoso';
                 EXCEPTION
                   when others then
                   RETURN 'Error al actualizar correo, PIDM erroneo';
            END;

    ELSIF v_matricula IS NOT NULL and old_pidm is not null THEN
            BEGIN

                    Insert into GOREMAL
                    select vpidm_u,
                             GOREMAL_EMAL_CODE,
                             GOREMAL_EMAIL_ADDRESS,
                             GOREMAL_STATUS_IND ,
                             GOREMAL_PREFERRED_IND,
                             sysdate,
                             'V2-SIU',
                             GOREMAL_COMMENT,
                             GOREMAL_DISP_WEB_IND,
                             'V2-SIU',
                             NULL,
                             GOREMAL_VERSION,
                             GOREMAL_VPDI_CODE
                    from GOREMAL
                    where GOREMAL_pidm = old_pidm;

                    COMMIT;
                    RETURN 'Creacion  de correo exitoso Nueva Solicitud';
                 EXCEPTION
                   when others then
                   RETURN 'Error al actualizar correo, PIDM erroneo';
            END;
    END IF;
END sp_mail;

FUNCTION sp_telefono (p_matricula varchar2, P_TELE_CODE    VARCHAR2, P_TELE_LADA VARCHAR2,  P_PHONO_NUMBER VARCHAR2, v_matricula IN VARCHAR2 DEFAULT NULL, old_pidm in varchar2 DEFAULT NULL)Return Varchar2
is

     lv_pidm  varchar2(12):=null;
     v_tele_code varchar2(50) := P_TELE_CODE;
     vl_error varchar2(250):= 'EXITO';

   BEGIN
       lv_pidm := fget_pidm (p_matricula);
       
--        -------------------- Validad que exista el telefono ----------------------
--        Begin 
--        
--            Select count(*)
--            from SPRTELE
--            where SPRTELE_pidm = lv_pidm
--            and SPRTELE_TELE_CODE = P_TELE_CODE 
--        
--        
--        End;
       

            IF  v_matricula is null THEN
            
               dbms_output.put_line  ('Entrada 1 ' ||v_matricula);
                BEGIN
                          GB_TELEPHONE.P_CREATE(p_pidm => lv_pidm,
                                                                  p_tele_code => P_TELE_CODE,
                                                                  p_phone_area => P_TELE_LADA,
                                                                  p_phone_number => P_PHONO_NUMBER,
                                                                  p_primary_ind => 'Y',
                                                                  p_rowid_out => vsalida,
                                                                  p_seqno_out => vnum_sal);
                                                                  
                         If vl_error = 'EXITO' Then
                            Commit; 
                         Else
                            rollback;
                         End if ;                                         

                         Return vl_error;
                        EXCEPTION
                            WHEN OTHERS THEN
                            vl_error := 'Error PKG_RESA AL  CREAR TELEFONO: '||sqlerrm;
                           Return vl_error;
               END;

           Elsif v_matricula is not null and old_pidm is null then
           dbms_output.put_line  ('Entrada 2 ' ||v_matricula);
               IF  v_matricula is not null  and v_tele_code ='RESI' then
               dbms_output.put_line  ('Entrada 3 ' ||v_matricula);
                BEGIN
                        UPDATE SPRTELE
                        SET SPRTELE_PHONE_AREA= P_TELE_LADA,
                        SPRTELE_PHONE_NUMBER = P_TELE_LADA||P_PHONO_NUMBER
                        where SPRTELE_PIDM = lv_pidm
                        AND SPRTELE_TELE_CODE = 'RESI';
                          Return vl_error;
                        EXCEPTION
                            WHEN OTHERS THEN
                            vl_error := 'Error PKG_RESA AL ACTIALIZAR TELEFONO PRINCIPAL: '||sqlerrm;
                           Return vl_error;
                           
                         If vl_error = 'EXITO' Then
                            Commit; 
                         Else
                            rollback;
                         End if;                           

                END;
                END IF;

               IF    v_matricula is not null  and v_tele_code ='CELU' then
               dbms_output.put_line  ('Entrada 4 ' ||v_matricula);
                BEGIN
                        UPDATE SPRTELE
                        SET SPRTELE_PHONE_AREA= P_TELE_LADA,
                        SPRTELE_PHONE_NUMBER = P_TELE_LADA||P_PHONO_NUMBER
                        where SPRTELE_PIDM = lv_pidm
                        AND SPRTELE_TELE_CODE = 'CELU';
                        Commit; 
                          Return vl_error;
                        EXCEPTION
                            WHEN OTHERS THEN
                            vl_error := 'Error PKG_RESA AL ACTIALIZAR TELEFONO CELULAR: '||sqlerrm;
                           Return vl_error;

                END;
                
                     If vl_error = 'EXITO' Then
                        Commit; 
                     Else
                        rollback;
                     End if;                    
                END IF;
            Elsif v_matricula is not null and old_pidm is not null then
            lv_pidm := fget_pidm (v_matricula);

                 Begin
                    Insert into SPRTELE
                    select lv_pidm,
                             SPRTELE_SEQNO,
                             SPRTELE_TELE_CODE,
                             sysdate,
                             SPRTELE_PHONE_AREA,
                             SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER,
                             SPRTELE_PHONE_EXT,
                             SPRTELE_STATUS_IND,
                             SPRTELE_ATYP_CODE,
                             SPRTELE_ADDR_SEQNO,
                             SPRTELE_PRIMARY_IND,
                             SPRTELE_UNLIST_IND,
                             SPRTELE_COMMENT,
                             SPRTELE_INTL_ACCESS,
                             'SIU-V2',
                             'SIU-V2',
                             SPRTELE_CTRY_CODE_PHONE,
                             null,
                             null,
                             null
                    From SPRTELE
                    Where SPRTELE_pidm =  old_pidm;
                          Return vl_error;
                        EXCEPTION
                            WHEN OTHERS THEN
                            vl_error := 'Error PKG_RESA AL ACTIALIZAR TELEFONO PRINCIPAL: '||sqlerrm;
                           Return vl_error;
                 End;
                 
                     If vl_error = 'EXITO' Then
                        Commit; 
                     Else
                        rollback;
                     End if;                     
                 
            END IF;

            

END sp_telefono;

FUNCTION  sp_admision  (vpidm_u  VARCHAR2, P_TERM_CODE_ENTRY    VARCHAR2, P_APST_CODE    VARCHAR2, P_MAINT_IND    VARCHAR2,
                            P_STYP_CODE    VARCHAR2, P_ADMT_CODE    VARCHAR2, P_RESD_CODE    VARCHAR2,   p_rate varchar2, p_apdc_code  varchar2, p_appl_no  number ) Return Varchar2
is
    vl_error Varchar2(2500):='EXITO';
    max_seqno number;

    begin

      dbms_output.put_line('llega' || p_apdc_code || '*'||p_appl_no);

       if p_apdc_code is null and p_appl_no is not null  then

         dbms_output.put_line('entes Entra 45');

            begin

                    vappl_no_admin := p_appl_no;
                  SB_ADMISSIONSAPPLICATION.P_CREATE(p_pidm => vpidm_u, p_term_code_entry => P_TERM_CODE_ENTRY, p_appl_no_inout => vappl_no_admin, p_appl_date =>sysdate,
                  p_apst_code =>P_APST_CODE, p_apst_date => sysdate,  p_maint_ind => P_MAINT_IND, p_styp_code => P_STYP_CODE, p_admt_code =>P_ADMT_CODE, p_resd_code =>P_RESD_CODE,
                  p_rowid_out => vsalida);



                  update SARADAP
                  set SARADAP_RATE_CODE   = p_rate
                  where SARADAP_PIDM   = vpidm_u
                  and  SARADAP_TERM_CODE_ENTRY  = P_TERM_CODE_ENTRY
                  and SARADAP_APPL_NO    = vappl_no_admin;
                  commit;
                --  vl_error:='Exito en nueva solicitud';
                  return vl_error;
                  dbms_output.put_line('Salida ' ||vl_error);
            exception when others then
                  vl_error :='Error en nueva solicitud'||sqlerrm;
                  dbms_output.put_line('Salida ' ||vl_error);
                  return vl_error;
            end;



       elsif p_apdc_code = '45'  and  p_appl_no >= 1 then
            dbms_output.put_line('Entra 45');

                begin

                vappl_no_admin := p_appl_no;

                    begin
                          SB_ADMISSIONSAPPLICATION.P_CREATE(p_pidm => vpidm_u, p_term_code_entry => P_TERM_CODE_ENTRY, p_appl_no_inout => vappl_no_admin, p_appl_date =>sysdate,
                          p_apst_code =>P_APST_CODE, p_apst_date => sysdate,  p_maint_ind => P_MAINT_IND, p_styp_code => P_STYP_CODE, p_admt_code =>P_ADMT_CODE, p_resd_code =>P_RESD_CODE,
                          p_rowid_out => vsalida);

                          dbms_output.put_line('salida '||vsalida);

                          vappl_no_admin := p_appl_no;
                          dbms_output.put_line('salidas '||vsalida);

                          update SARADAP
                          set SARADAP_RATE_CODE   = p_rate
                          where SARADAP_PIDM   = vpidm_u
                          and  SARADAP_TERM_CODE_ENTRY  = P_TERM_CODE_ENTRY
                          and SARADAP_APPL_NO    = vappl_no_admin;
                          commit;
                      --    vl_error:='Exito en segunda solicitud';
                    Exception when others then
                          vl_error :='Error en segunda solicitud'||sqlerrm;
                     end;

                    Begin
                            select nvl(max(sarappd_seq_no),0) +1
                                into max_seqno
                            from sarappd
                            where sarappd_pidm = vpidm_u
                            and SARAPPD_TERM_CODE_ENTRY  = p_term_code_entry
                            and SARAPPD_APPL_NO  =  p_appl_no;
                    Exception
                    when others then
                        vl_error :='Error al obtener la secuencia para ppd'||sqlerrm;
                         dbms_output.put_line ('Errorx' ||vl_error);
                    End;

                    --dbms_output.put_line('maxima secuencia '||max_seqno);

                    begin
                      insert into sarappd values(vpidm_u, p_term_code_entry, p_appl_no, max_seqno, sysdate, p_apdc_code, 'U', sysdate, user, 'V2-SIU', Null, Null, Null, Null );
                       --  vl_error:='Insert exitoso segunda solicitud';
                      Exception when others then
                      vl_error:='Error al insertar'||vpidm_u ||'*'||p_term_code_entry ||'*'||p_appl_no ||'*'||max_seqno||'*'||p_apdc_code ||'*'||sqlerrm;
                     end;

               end;
               Commit;

       end if;

       -- vl_error:='Proceso segunda solicitud Exitoso';
        Return vl_error;
    Exception
       When others then
       vl_error:='Error PKG_RESA.sp_admision: ' ||sqlerrm;
       Return vl_error;
    end sp_admision;



--FUNCION CREADA PARA CACHAR EL  ERROR--
FUNCTION sp_campus (vpidm_u VARCHAR2, P_TERM_CODE_ENTRY    VARCHAR2, vappl_no_admin    NUMBER,  P_LEVL_CODE    VARCHAR2, P_CAMP_CODE    VARCHAR2, P_COLL_CODE_1    VARCHAR2, P_DEGC_CODE_1    VARCHAR2, P_MAJR_CODE_1    VARCHAR2, P_PROGRAM_1    VARCHAR2  )Return Varchar
is
    vl_error Varchar(2500):='EXITO';
begin
  -- actualiza la admisiÃ³n
    BANINST1.DML_SARADAP.p_update_curriculum(p_pidm => vpidm_u, p_term_code_entry => P_TERM_CODE_ENTRY, p_appl_no  =>vappl_no_admin, p_levl_code => P_LEVL_CODE,
    p_camp_code =>P_CAMP_CODE, p_coll_code_1 =>P_COLL_CODE_1, p_degc_code_1 =>P_DEGC_CODE_1, p_majr_code_1 => P_MAJR_CODE_1 , p_program_1 =>P_PROGRAM_1,
    p_rowid => vsalida);
  --dbms_output.put_line('GENERA  CAMPUS  '|| vpidm_u );
  commit;

 -- vl_error:='Proceso Exitoso';
  Return vl_error;

Exception
    When others then
    vl_error:='Error PKG.sp_campus: ' || sqlerrm;
    Return vl_error;

end sp_campus;



--FUNCION CREADA PARA CACHAR UN  ERROR--
FUNCTION sp_insarchkl (vpidm_u  number, P_TERM_CODE_ENTRY    VARCHAR2, vappl_no_admin  varchar2  ) Return Varchar2
        is
        --NUMBER,  P_LEVL_CODE    VARCHAR2, P_CAMP_CODE  VARCHAR2, P_PROGRAM_1  varchar2 )  is
        /*
        proceso   que inserta los documentos que debe entregar o subir un alumno a la escuela que se  esta matriculando
        los documentos van a depender de acuerdo a la  escuela nivel y estatus del alumno
        en este caso toods los datos que se necesitan los obtenenos en elcursor de saradap
        y la configuracion de los documentos la tenemos de SARCHKB de acuerdo al  nivel campus, y esttaus
        */



        lv_nivel    varchar2(4);
        lv_apst    varchar2(4);
        lv_admt   varchar2(6);
        lv_pidm   varchar2(12);
        lv_admr   varchar2(6);
        lv_mandatory_ind    varchar2(1);
        lv_camp   varchar2(6);
        chkb_term_code   varchar2(12);
        vl_error varchar(2500):=null;
         ---saradap_row saradap%rowtype;
         ---saradap_rowid  varchar2(18) := '';
        -- CURSOR saradap_C is
        --   select SARADAP_LEVL_CODE  nivel, SARADAP_APST_CODE  apst, SARADAP_ADMT_CODE  admt, SARADAP_CAMP_CODE  camp, saradap_pidm pidm
        --    from saradap
        --   where saradap_pidm = vpidm_u
        --   and saradap_term_code_entry = p_term
        --   and saradap_appl_no = pappl_no
        -- --  and  SARADAP_APST_CODE   = 'P'
        --   and   SARADAP_CAMP_CODE  =   P_CAMP_CODE
        --and    SARADAP_PROGRAM_1   =  P_PROGRAM_1
        --AND SARADAP_LEVL_CODE   = P_LEVL_CODE ;
        --
        --cursor c_sarchkb(vcamp varchar2, vlevl  varchar2, vadmt  varchar2)  is
        -- SELECT  SARCHKB_ADMR_CODE, SARCHKB_CAMP_CODE,  SARCHKB_LEVL_CODE, SARCHKB_ADMT_CODE, SARCHKB_MANDATORY_IND
        --   FROM   SARCHKB--@trng
        --   where SARCHKB_CAMP_CODE  = vcamp --'UTL'
        --   and    SARCHKB_LEVL_CODE    = vlevl -- 'LI'
        --   and  SARCHKB_ADMT_CODE   =  vadmt ; -- 'RE' ;



begin

        -------aqui  es  lo mismo la matricula en realidad es el  pidm  por eso lo pasamos directo
        ----vpidm_u :=   BANINST1.fget_pidm(p_matricula);

        --dbms_output.put_line('GENERA  DOCUMENTOS 1  '|| vpidm_u );


        SAKCHKB.P_sarchkb_InsChecklist(vpidm_u , P_TERM_CODE_ENTRY , vappl_no_admin );
        --dbms_output.put_line('GENERA  DOCUMENTOS 1  '|| vpidm_u|| ' per '|| P_TERM_CODE_ENTRY|| ' no appl  '  || vappl_no_admin  );

        --
        --  open saradap_C ;
        --  fetch saradap_C into lv_nivel,lv_apst, lv_admt, lv_camp,  vpidm_u  ;
        --  --dbms_output.put_line('GENERA  DOCUMENTOS 2  '|| lv_nivel||'-'||lv_apst||'-'||lv_admt||'-'||lv_camp||'-'||vpidm_u );
        --  if saradap_C%Notfound then
        --    close saradap_C;
        --    --dbms_output.put_line('DATOS NO ENCONTRADOS EN SARADAP');
        --    return;
        --  end if;
        --  ----------------aqui se va crear el cursor de los diferentes documentos que se van a insertar como lo explico TAVO en la tabla
        --  ------------sarchkb_c y de acuerdo al numero de documentos que se recuperan en este curso son los que va insertar.
        --
        --           open c_sarchkb(lv_camp, lv_nivel, lv_admt) ;
        --           loop
        --             fetch c_sarchkb  into lv_admr,lv_camp,lv_nivel,lv_admt  , lv_mandatory_ind;
        --      --       dbms_output.put_line('DATOS  EN SARCHKB   ' ||lv_admr||'-'|| lv_nivel   );
        --             if c_sarchkb%Notfound then
        --                close c_sarchkb;
        --                return;
        --        --        dbms_output.put_line('DATOS NO ENCONTRADOS EN SARCHKB');
        --
        --              end if;
        --             exit when c_sarchkb%notfound;
        --
        --
        --          --     dbms_output.put_line('GENERA  DOCUMENTOS 3  '|| lv_admr||'-'|| lv_admt );
        --            INSERT INTO SARCHKL
        --                ( SARCHKL_PIDM, SARCHKL_TERM_CODE_ENTRY, SARCHKL_APPL_NO, SARCHKL_ADMR_CODE, SARCHKL_MANDATORY_IND,
        --                  SARCHKL_PRINT_IND, SARCHKL_ACTIVITY_DATE, SARCHKL_SOURCE,  SARCHKL_SOURCE_DATE, SARCHKL_CKST_CODE, SARCHKL_VERSION )
        --               VALUES( vpidm_u, p_term, pappl_no, lv_admr, lv_mandatory_ind,
        --                  'Y', sysdate, 'S', sysdate,'NORECIBIDO', 0);
        --
        --             end loop;  -- loop for checklist
        --            close c_sarchkb;
        --       COMMIT;
        --CLOSE saradap_C;

vl_error:='Proceso Exitoso';
Return vl_error;
Exception
    When others then
        vl_error:='Error PKG_RESA.sp_insarchkl: ' ||sqlerrm;
        Return vl_error;

 --dbms_output.put_line('GENERA  DOCUMENTOS 4  '|| vpidm_u );
end sp_insarchkl ;



-- SE GENERA LA  FUNCIÓN PARA CACHAR EL ERROR--

FUNCTION  sp_sorlcurfos ( p_matricula VARCHAR2 , P_TERM_CODE_ENTRY VARCHAR2, vappl_no_admin NUMBER,  P_LEVL_CODE VARCHAR2, P_CAMP_CODE  VARCHAR2,
                                        P_PROGRAM_1  varchar2 ,P_fecha_inicio_periodo varchar2, P_PTRM_CODE VARCHAR2, p_costo varchar2 default null   ) Return  Varchar2
IS

vl_error Varchar2(2500):='EXITO';
lv_mayor      number:=0;       ----numero de area de salida
lv_mayor_code  varchar2(8);  ----- codigo de area de salida
lv_menor     number:=0;        --- numero de salida de concentracion
lv_menor_code  varchar2(8);   ---- codigo de  salida de concentracion
lv_menor2     number:=0;        --- numero de salida de concentracion2
lv_menor_code2  varchar2(8);   ---- codigo de  salida de concentracion2
lv_comidin  varchar2(10);
vsecuencia number :=1;
vsp number :=0;
lv_regla number:=0;

    CURSOR C_SORFOS ( VPIDM  varchar2, VTERM  varchar2, VLEVL  varchar2,VAPPL NUMBER, vcamp  varchar2 , vprog  varchar2 ) IS
        SELECT SARADAP_TERM_CODE_ENTRY  SARAD_TERM,
        SARADAP_APPL_NO,
        SARADAP_LEVL_CODE  SARAD_LEVL,
        SARADAP_CAMP_CODE  SARAD_CAMP,
        SARADAP_COLL_CODE_1   SARAD_COLL,
        SARADAP_DEGC_CODE_1   SARAD_DEG,
        SARADAP_PROGRAM_1    SARAD_PROG,
        SARADAP_MAJR_CODE_1   SARAD_MAJR,
        (SELECT SOBCURR_CURR_RULE
            FROM SOBCURR
            WHERE SOBCURR_PROGRAM = SA.SARADAP_PROGRAM_1
            and   SOBCURR_LEVL_CODE  = sa.SARADAP_LEVL_CODE
            and   SOBCURR_CAMP_CODE   = sa.SARADAP_CAMP_CODE) as  SARAD_rule
            FROM SARADAP SA
            WHERE  SARADAP_PIDM  = VPIDM
            AND SARADAP_TERM_CODE_ENTRY  = VTERM
            AND SARADAP_LEVL_CODE   = VLEVL
            AND  SARADAP_APPL_NO  =  VAPPL
            and   SARADAP_CAMP_CODE  =   vcamp
            and    SARADAP_PROGRAM_1   =  vprog  ;

        MAXNO   NUMBER:= 0;
        lv_pidm  NUMBER;

 MAXNO1   NUMBER:= 0;
  MAXNO2   NUMBER:= 0;


cursor c_mayor(lv_programa  varchar2)  is
select  a.SZTDTEC_TERM_CODE periodo,  a.SZTDTEC_MAJR_CODE, a.SZTDTEC_CMJR_RULE
    from SZTDTEC a
    Where a.SZTDTEC_PROGRAM = lv_programa
    And a.SZTDTEC_CAMP_CODE = P_CAMP_CODE
    And a.SZTDTEC_TERM_CODE  = (select max (b.SZTDTEC_TERM_CODE)
                                                     from  SZTDTEC b
                                                     Where b.SZTDTEC_PROGRAM = a.SZTDTEC_PROGRAM
                                                     And b.SZTDTEC_CAMP_CODE = a.SZTDTEC_CAMP_CODE
                                                     );


cursor c_menor(lv_programa varchar2 )  is
select a.SZTDTEC_TERM_CODE periodo, a.SZTDTEC_MAJR_CODE_CONC, a.SZTDTEC_CCON_RULE,
             a.SZTDTEC_MAJR_CODE_CONC2, a.SZTDTEC_CCON_RULE2
    from SZTDTEC a
    Where a.SZTDTEC_PROGRAM = lv_programa
     And a.SZTDTEC_CAMP_CODE = P_CAMP_CODE
    And a.SZTDTEC_TERM_CODE  = (select max (b.SZTDTEC_TERM_CODE)
                                                     from  SZTDTEC b
                                                     Where b.SZTDTEC_PROGRAM = a.SZTDTEC_PROGRAM
                                                     And b.SZTDTEC_CAMP_CODE = a.SZTDTEC_CAMP_CODE
                                                     );




BEGIN

        ----aqui la matricula en realidad es el pidm   por eso se pasa directo
        lv_pidm := p_matricula;
        BEGIN
        SELECT  nvl(max(SORLCUR_SEQNO), 0)  + 1   into  MAXNO
        FROM SORLCUR
        WHERE 1=1
        AND SORLCUR_PIDM = lv_pidm
--        AND SORLCUR_LMOD_CODE = 'LEARNER'
        ;

EXCEPTION
 WHEN OTHERS THEN
 MAXNO:=0;
 --lv_pidm:= 0;
END;


Begin
    Update SORLCUR
    set SORLCUR_PRIORITY_NO = 99
    where 1=1
    AND SORLCUR_CACT_CODE != 'CHANGE'
    And SORLCUR_LMOD_CODE in ( 'LEARNER', 'OUTCOME')
    And SORLCUR_PIDM = lv_pidm;
    Commit;
Exception
    When Others then
        null;

End;


Begin
        Update SORLFOS
        set SORLFOS_PRIORITY_NO = 99
        Where SORLFOS_LCUR_SEQNO  = (select SORLCUR_SEQNO
                                     from SORLCUR
                                     Where SORLCUR_PIDM = lv_pidm
                                     And SORLCUR_CACT_CODE != 'CHANGE'
                                     And SORLCUR_LMOD_CODE  in ( 'LEARNER', 'OUTCOME')
)
        And SORLFOS_PIDM = lv_pidm;
        Commit;
Exception
    When Others then
        null;
End;


Begin
        SELECT  nvl(max(SORLCUR_KEY_SEQNO), 0)  + 1
            Into vsp
        from sorlcur
        where sorlcur_pidm = lv_pidm
        and SORLCUR_LMOD_CODE = 'LEARNER';
Exception
    When Others then
        vsp :=1;
End;



--DBMS_OUTPUT.PUT_LINE ( ' SORFOLS  2  '|| lv_pidm||'-'||MAXNO);

FOR RESAR  IN C_SORFOS(lv_pidm, P_TERM_CODE_ENTRY,P_LEVL_CODE, vappl_no_admin,P_CAMP_CODE,P_PROGRAM_1 )  LOOP
      --  DBMS_OUTPUT.PUT_LINE ( ' SORFOLS  3  '|| lv_pidm||'-'||MAXNO);


------- BUSCA EL MAYOY   Y EL AREA DE CONCENTACION

        open c_mayor(resar.SARAD_PROG);
        fetch c_mayor into lv_comidin, lv_mayor_code , lv_mayor;
        close c_mayor;

        open c_menor(resar.SARAD_PROG);
        fetch c_menor into lv_comidin,  lv_menor_code, lv_menor, lv_menor_code2, lv_menor2;
        close c_menor;


     Begin

                    Insert into SORLCUR values (
                                                             lv_pidm,                        --SORLCUR_PIDM
                                                             MAXNO,                                     --SORLCUR_SEQNO
                                                             'ADMISSIONS',                                   --SORLCUR_LMOD_CODE
                                                             resar.SARAD_TERM,                     --SORLCUR_TERM_CODE
                                                             vappl_no_admin, --vappl_no_admin,                          --SORLCUR_KEY_SEQNO
                                                             vsecuencia,                                      --SORLCUR_PRIORITY_NO
                                                             'N',                                               --SORLCUR_ROLL_IND
                                                             'ACTIVE',                                        --SORLCUR_CACT_CODE
                                                             'SistemaV2',                                       --SORLCUR_USER_ID
                                                             'Resa',                                          --SORLCUR_DATA_ORIGIN
                                                             SYSDATE,                                     --SORLCUR_ACTIVITY_DATE
                                                             resar.SARAD_LEVL,                --SORLCUR_LEVL_CODE
                                                             resar.SARAD_COLL,             --SORLCUR_COLL_CODE
                                                             resar.SARAD_DEG,          --SORLCUR_DEGC_CODE
                                                             lv_comidin,        --SORLCUR_TERM_CODE_CTLG
                                                             NULL,                                             --SORLCUR_TERM_CODE_END
                                                             resar.SARAD_TERM,       --SORLCUR_TERM_CODE_MATRIC
                                                             null,       --SORLCUR_TERM_CODE_ADMIT
                                                             null,                  --SORLCUR_ADMT_CODE
                                                             resar.SARAD_CAMP,                  --SORLCUR_CAMP_CODE
                                                             resar.SARAD_PROG,                   --SORLCUR_PROGRAM
                                                             P_fecha_inicio_periodo,                     --SORLCUR_START_DATE
                                                             null,                                                --SORLCUR_END_DATE
                                                             resar.SARAD_rule,                                            --SORLCUR_CURR_RULE
                                                             null,                                               --SORLCUR_ROLLED_SEQNO
                                                             null,--c.SGBSTDN_STYP_CODE,                  --SORLCUR_STYP_CODE
                                                             null,                                                --SORLCUR_RATE_CODE
                                                             null,                                                 --SORLCUR_LEAV_CODE
                                                             null,                                                 --SORLCUR_LEAV_FROM_DATE
                                                             null,                                                 --SORLCUR_LEAV_TO_DATE
                                                             null,                                                 --SORLCUR_EXP_GRAD_DATE
                                                             null,                                                 --SORLCUR_TERM_CODE_GRAD
                                                             null,                                                 --SORLCUR_ACYR_CODE
                                                             p_costo,                                                 --SORLCUR_SITE_CODE
                                                            null, --c.SARADAP_APPL_NO,                      --SORLCUR_APPL_SEQNO
                                                             null,                                              --SORLCUR_APPL_KEY_SEQNO
                                                             'SistemaV2',                                       --SORLCUR_USER_ID_UPDATE
                                                             SYSDATE,                                      --SORLCUR_ACTIVITY_DATE_UPDATE
                                                              null,                                             --SORLCUR_GAPP_SEQNO
                                                              'Y',                                             --SORLCUR_CURRENT_CDE
                                                              null,                                             --SORLCUR_SURROGATE_ID
                                                              null,                                             --SORLCUR_VERSION
                                                               P_PTRM_CODE);                              --SORLCUR_VPDI_CODE);

--  DBMS_OUTPUT.PUT_LINE ( ' GENERA SORLCUR     '|| lv_pidm||'-'||MAXNO||'-'||resar.SARAD_PROG||'-'||resar.SARAD_rule);

   Exception
   when others then
      vl_error := 'Se presento un error al insertar en SORLCUR '|| sqlerrm;
     --   DBMS_OUTPUT.PUT_LINE ( ' Error al generar solcur_1     '|| lv_pidm||'-'||MAXNO||'-'||resar.SARAD_PROG||'-'||resar.SARAD_rule||'*'||lv_comidin||'*'||sqlerrm);
    End;




------SE INSERTA  EL REGISTO DE ARE MAYOR DE SALIDA -----
 --DBMS_OUTPUT.PUT_LINE ( 'salida solfrcur_!!  MAYOR  '||lv_mayor_code || '   menor  '||   lv_menor_code|| ' consecutiv ' || MAXNO );

  If lv_mayor_code is not null then

               Begin
                    SELECT  nvl(max(SORLFOS_SEQNO), 0)  + 1   into  MAXNO2
                    FROM SORLFOS
                    WHERE SORLFOS_PIDM = lv_pidm
                    ANd SORLFOS_LCUR_SEQNO =MAXNO ;
               Exception
               when Others then
                MAXNO2 :=1;
               End;


                 Begin
                         Insert into SORLFOS VALUES(
                                                                    lv_pidm,                             --SORLFOS_PIDM
                                                                    MAXNO,                          --SORLFOS_LCUR_SEQNO
                                                                    MAXNO2,                                       --SORLFOS_SEQNO
                                                                    'MAJOR',                                           --SORLFOS_LFST_CODE
                                                                    resar.SARAD_TERM,                  --SORLFOS_TERM_CODE
                                                                    vsecuencia,                                       --SORLFOS_PRIORITY_NO
                                                                    'INPROGRESS',                                 --SORLFOS_CSTS_CODE
                                                                    'ACTIVE',                 --SORLFOS_CACT_CODE
                                                                    'SistemaV2',                                            --SORLFOS_DATA_ORIGIN
                                                                    'Resa',                                         --SORLFOS_USER_ID
                                                                    SYSDATE,                                     --SORLFOS_ACTIVITY_DATE
                                                                    lv_mayor_code,                                         --SORLFOS_MAJR_CODE
                                                                    lv_comidin,                --SORLFOS_TERM_CODE_CTLG
                                                                    null,                                               --SORLFOS_TERM_CODE_END
                                                                    null,                                                --SORLFOS_DEPT_CODE
                                                                    null,            --SORLFOS_MAJR_CODE_ATTACH   *************+ Se quita la variable cuando es MAJOR   vmayor
                                                                    lv_mayor,              --SORLFOS_LFOS_RULE****************  Regla de la carrera, se toma de la tabla SOBCURR.
                                                                    null,                 --SORLFOS_CONC_ATTACH_RULE
                                                                    null,                 --SORLFOS_START_DATE
                                                                    null,                 --SORLFOS_END_DATE
                                                                    null,                 --SORLFOS_TMST_CODE
                                                                    null,                 --SORLFOS_ROLLED_SEQNO
                                                                    'SistemaV2',     --SORLFOS_USER_ID_UPDATE
                                                                    SYSDATE,         --SORLFOS_ACTIVITY_DATE_UPDATE
                                                                    Null,                --SORLFOS_CURRENT_CDE
                                                                    null,                --SORLFOS_SURROGATE_ID
                                                                    null,                --SORLFOS_VERSION
                                                                    null                 --SORLFOS_VPDI_CODE
                                                            );




                commit;

                 Exception
                   when others then
                    --  DBMS_OUTPUT.PUT_LINE  ('Error en Concentracion1'||sqlerrm);
                      vl_error := 'Se presento un error al insertar en SORLCUR Concentracion1 '|| sqlerrm;
                 End;

 End if;


If lv_menor_code is not null then
   vsecuencia := vsecuencia +1;

            Begin
                SELECT  nvl(max(SORLFOS_SEQNO), 0)  + 1   into  MAXNO2
                FROM SORLFOS
                WHERE SORLFOS_PIDM = lv_pidm
                ANd SORLFOS_LCUR_SEQNO =MAXNO ;
           Exception
           when Others then
            MAXNO2 :=1;
           End;


            Begin
            -- SE INSERTA EL AREA DE CONCENTRACION DE  SALIDA----

                Insert into SORLFOS VALUES(
                                                            lv_pidm,                             --SORLFOS_PIDM
                                                            MAXNO,                          --SORLFOS_LCUR_SEQNO
                                                            MAXNO2,                                       --SORLFOS_SEQNO
                                                            'CONCENTRATION',                                           --SORLFOS_LFST_CODE
                                                            resar.SARAD_TERM,                  --SORLFOS_TERM_CODE
                                                            vsecuencia,                                       --SORLFOS_PRIORITY_NO
                                                            'INPROGRESS',                                 --SORLFOS_CSTS_CODE
                                                            'ACTIVE',                 --SORLFOS_CACT_CODE
                                                            'SistemaV2',                                            --SORLFOS_DATA_ORIGIN
                                                            'Resa',                                         --SORLFOS_USER_ID
                                                            SYSDATE,                                     --SORLFOS_ACTIVITY_DATE
                                                            lv_menor_code,                                         --SORLFOS_MAJR_CODE
                                                            lv_comidin,                --SORLFOS_TERM_CODE_CTLG
                                                            null,                                               --SORLFOS_TERM_CODE_END
                                                            null,                                                --SORLFOS_DEPT_CODE
                                                            lv_mayor_code,            --SORLFOS_MAJR_CODE_ATTACH
                                                            lv_menor,              --SORLFOS_LFOS_RULE****************  Regla de la carrera, se toma de la tabla SOBCURR.
                                                            lv_mayor,                 --SORLFOS_CONC_ATTACH_RULE   ****************  Regla de la carrera, se toma de la tabla SOBCURR
                                                            null,                 --SORLFOS_START_DATE
                                                            null,                 --SORLFOS_END_DATE
                                                            null,                 --SORLFOS_TMST_CODE
                                                            null,                 --SORLFOS_ROLLED_SEQNO
                                                            'SistemaV2',                 --SORLFOS_USER_ID_UPDATE
                                                            SYSDATE,                --SORLFOS_ACTIVITY_DATE_UPDATE
                                                            null,                --SORLFOS_CURRENT_CDE
                                                            null,                --SORLFOS_SURROGATE_ID
                                                            null,                --SORLFOS_VERSION
                                                            null                --SORLFOS_VPDI_CODE
                                );




               Exception
               when others then
                 -- DBMS_OUTPUT.PUT_LINE  ('Error en Salida 1'||sqlerrm);
                  vl_error := 'Se presento un error al insertar en SORLCUR Salida1 '|| sqlerrm;
                End;
End if;

            Begin
                SELECT  nvl(max(SORLFOS_SEQNO), 0)  + 1   into  MAXNO1
                FROM SORLFOS
                WHERE SORLFOS_PIDM = lv_pidm
                ANd SORLFOS_LCUR_SEQNO =MAXNO ;
           Exception
           when Others then
            MAXNO1 :=1;
           End;


If lv_menor_code2 is not null then
vsecuencia := vsecuencia +1;

                Begin
                -- SE INSERTA EL AREA DE CONCENTRACION DE  SALIDA 2 ----

                        Insert into SORLFOS VALUES(
                                                                    lv_pidm,                             --SORLFOS_PIDM
                                                                    MAXNO,                          --SORLFOS_LCUR_SEQNO
                                                                    MAXNO1,                                       --SORLFOS_SEQNO
                                                                    'CONCENTRATION',                                           --SORLFOS_LFST_CODE
                                                                    resar.SARAD_TERM,                  --SORLFOS_TERM_CODE
                                                                    vsecuencia,                                       --SORLFOS_PRIORITY_NO
                                                                    'INPROGRESS',                                 --SORLFOS_CSTS_CODE
                                                                    'ACTIVE',                 --SORLFOS_CACT_CODE
                                                                    'SistemaV2',                                            --SORLFOS_DATA_ORIGIN
                                                                    'Resa',                                         --SORLFOS_USER_ID
                                                                    SYSDATE,                                     --SORLFOS_ACTIVITY_DATE
                                                                    lv_menor_code2,  --SORLFOS_MAJR_CODE
                                                                    lv_comidin,                --SORLFOS_TERM_CODE_CTLG
                                                                    null,                                               --SORLFOS_TERM_CODE_END
                                                                    null,                                                --SORLFOS_DEPT_CODE
                                                                    lv_mayor_code,            --SORLFOS_MAJR_CODE_ATTACH
                                                                   lv_menor2,              --SORLFOS_LFOS_RULE****************  Regla de la carrera, se toma de la tabla SOBCURR.
                                                                   lv_mayor ,                 --SORLFOS_CONC_ATTACH_RULE
                                                                    null,                 --SORLFOS_START_DATE
                                                                    null,                 --SORLFOS_END_DATE
                                                                    null,                 --SORLFOS_TMST_CODE
                                                                    null,                 --SORLFOS_ROLLED_SEQNO
                                                                    'SistemaV2',                 --SORLFOS_USER_ID_UPDATE
                                                                    SYSDATE,                --SORLFOS_ACTIVITY_DATE_UPDATE
                                                                    null,                --SORLFOS_CURRENT_CDE
                                                                    null,                --SORLFOS_SURROGATE_ID
                                                                    null,                --SORLFOS_VERSION
                                                                    null                --SORLFOS_VPDI_CODE
                                        );


                   Exception
                   when others then
               --   DBMS_OUTPUT.PUT_LINE  ('Error en Salida 2'||sqlerrm);
                  vl_error := 'Se presento un error al insertar en SORLCUR Salida2 '|| sqlerrm;
                    End;
End if;



end loop;

--DBMS_OUTPUT.PUT_LINE ( ' GENERA SORLCURFOS   '|| lv_pidm||'-'||MAXNO);




lv_mayor      :=0;       ----numero de area de salida
lv_menor      :=0;        --- numero de salida de concentracion
lv_menor2    :=0;        --- numero de salida de concentracion2
lv_regla      :=0;       ----numero de regla
lv_comidin    := null;    --- Periodo de Catalogo
lv_menor_code := null;
lv_menor_code2:= null;
lv_mayor_code := null;



Begin
            select  a.SZTDTEC_TERM_CODE periodo,  a.SZTDTEC_MAJR_CODE, a.SZTDTEC_CMJR_RULE, SOBCURR_CURR_RULE
            Into lv_comidin, lv_mayor_code, lv_mayor, lv_regla
            from SZTDTEC a, SOBCURR
            Where a.SZTDTEC_PROGRAM = P_PROGRAM_1
             And SOBCURR_CAMP_CODE = a.SZTDTEC_CAMP_CODE
            And a.SZTDTEC_CAMP_CODE = P_CAMP_CODE
            And a.SZTDTEC_PROGRAM = SOBCURR_PROGRAM
            And a.SZTDTEC_TERM_CODE  = (select max (b.SZTDTEC_TERM_CODE)
                                                             from  SZTDTEC b
                                                             Where b.SZTDTEC_PROGRAM = a.SZTDTEC_PROGRAM);
Exception
    When Others then
   --   DBMS_OUTPUT.PUT_LINE  ('Se presento un error al obtener la regla_1 ' || Sqlerrm);
       vl_error := 'Se presento un error al obtener la regla_1  '|| sqlerrm;
End;


Begin
select   a.SZTDTEC_MAJR_CODE_CONC, a.SZTDTEC_CCON_RULE,
             a.SZTDTEC_MAJR_CODE_CONC2, a.SZTDTEC_CCON_RULE2
    Into lv_menor_code, lv_menor, lv_menor_code2, lv_menor2
    from SZTDTEC a
    Where a.SZTDTEC_PROGRAM = P_PROGRAM_1
    And a.SZTDTEC_CAMP_CODE = P_CAMP_CODE
    And a.SZTDTEC_TERM_CODE  = (select max (b.SZTDTEC_TERM_CODE)
                                                     from  SZTDTEC b
                                                     Where b.SZTDTEC_PROGRAM = a.SZTDTEC_PROGRAM);
Exception
    When Others then
 --     DBMS_OUTPUT.PUT_LINE  ('Se presento un error al obtener la regla_2 ' || Sqlerrm);
       vl_error := 'Se presento un error al obtener la regla_2  '|| sqlerrm;
End;




        Begin
                update saradap
                  set saradap_majr_code_1   =   lv_mayor_code,
                        saradap_majr_code_conc_1   =  lv_menor_code,
                        SARADAP_MAJR_CODE_CONC_1_2   =  lv_menor_code2 ,
                        SARADAP_TERM_CODE_CTLG_1 = lv_comidin,
                        SARADAP_CURR_RULE_1 = lv_regla,
                        SARADAP_CMJR_RULE_1_1 = lv_mayor,
                        SARADAP_CCON_RULE_11_1  = lv_menor,
                        SARADAP_CCON_RULE_11_2 = lv_menor2,
                        SARADAP_DATA_ORIGIN = 'resa',
                        SARADAP_USER_ID = user
                where   SARADAP_PIDM     =  lv_pidm
                and       SARADAP_LEVL_CODE   = P_LEVL_CODE
                and       SARADAP_CAMP_CODE  =  P_CAMP_CODE
                and       SARADAP_PROGRAM_1    =  P_PROGRAM_1
                And       SARADAP_APPL_NO = vappl_no_admin;

                commit;
        Exception
           when others then
            --  DBMS_OUTPUT.PUT_LINE  ('Error en Actualizacion en Concentracion_2' || Sqlerrm);
              vl_error := 'Se presento el error al actualizar SARADAP  Concentracion_2  '|| sqlerrm;
        End;


Return vl_error;

Exception
    When others then
        vl_error:='Error  pkg_RESA.sp_sorlcurfos: '||sqlerrm;
        Return vl_error;
end sp_sorlcurfos;




--SE GENERA LA FUNCION DEL PROCEDIMIENTO SOBRECARGADO, PARA CACHAR EL ERROR--

FUNCTION  sp_rate_plan ( p_rate varchar2, p_camp  varchar2,    cur_rate_plan  OUT pkg_Resa.rates_plan_type ) Return Varchar2
is
    vl_error Varchar2(2500):=Null;

    cursor c_planes (p_rate varchar2 )  is
    SELECT STVRATE_CODE  code_rate, STVRATE_DESC  rate_desc
    FROM STVRATE
    JOIN
    WHERE substr(STVRATE_CODE,1,1) = 'P'
    and   STVRATE_CODE   IN (p_rate);

    v_rate  number := 0;

begin

        v_rate  := substr(p_rate,2,2);

        --el resultado de estoa querys lo vamos a guardar en un typo registro para enviarla como cursor de salida


        IF    (v_rate)   > 0  and (v_rate)  < 13  then

        --open cur_rate_plan  for   select SMRPRLE_PROGRAM, SMRPRLE_PROGRAM_DESC, SMRPRLE_LEVL_CODE, SMRPRLE_CAMP_CODE
        --                                        from  smrprle sp, sobcurr cu inner join cu
        --                                      on cu_PROGRAM = sp_PROGRAM
        --                                        where SMRPRLE_CAMP_CODE = p_camp
        --                                         and CU.SOBCURR_PROGRAM       =  PR.SMRPRLE_PROGRAM
        --                                           AND  CU.SOBCURR_CAMP_CODE  =
        --                                        and   SMRPRLE_PROGRAM  like ('UTLL%');
        null;
        ELSIF  v_rate  in  (31,43)  then
         open cur_rate_plan  for   select SMRPRLE_PROGRAM, SMRPRLE_PROGRAM_DESC, SMRPRLE_LEVL_CODE, SMRPRLE_CAMP_CODE
                                                from  SMRPRLE
                                                inner join SOBCURR
                                                on SOBCURR_PROGRAM = SMRPRLE_PROGRAM
                                                where SMRPRLE_CAMP_CODE = p_camp
                                                and   SMRPRLE_PROGRAM  not like ('UTLLID%');

        ELSIF  v_rate  in (48,36)  then
        open cur_rate_plan  for   select SMRPRLE_PROGRAM, SMRPRLE_PROGRAM_DESC, SMRPRLE_LEVL_CODE, SMRPRLE_CAMP_CODE
                                                from  SMRPRLE
                                                inner join SOBCURR
                                                on SOBCURR_PROGRAM = SMRPRLE_PROGRAM
                                                where SMRPRLE_CAMP_CODE = p_camp
                                                and   SMRPRLE_PROGRAM   like ('UTLLID%');
        END IF;
vl_error:='Proceso Exitoso';
Return vl_error;
EXCEPTION
 WHEN OTHERS THEN
    vl_error:='Error   PKG_RESA.sp_rate_plan: '||sqlerrm;
    Return vl_error;

 --null;
 --lv_pidm:= 0;
end sp_rate_plan ;

FUNCTION   f_get_object ( p_name  varchar2)  return  varchar2  is

    vs_retorna    varchar2(6):= 'false';
    vcuenta        number;
    vl_error Varchar(2500):=Null;

begin

     select count(1)    INTO  vcuenta
                                        from all_objects
                                        where owner <> 'SYS'
                                        and object_type in ('FUNCTION','PACKAGE', 'PROCEDURE')
                                        and upper(object_name)  =  upper(p_name) ;  ---- like (''||p_name ||'%');


        IF vcuenta  > 0 then
        vs_retorna  := 'TRUE';
        end if;
        return (vs_retorna);

Return vl_error;
Exception
    When others then
        vl_error:='Error'||sqlerrm;
        Return vl_error;
end f_get_object;

FUNCTION sp_addres (p_pidm   NUMBER, p_atyp_code   varchar2, P_CITY   VARCHAR2 ,  P_STREET_LINE1 VARCHAR2  default null, P_STREET_LINE2  VARCHAR2  default null,
                                P_STREET_LINE3 VARCHAR2  default null, P_STAT_CODE VARCHAR2  default null, P_ZIP VARCHAR2  default null, P_CNTY_CODE VARCHAR2  default null,
                                P_NATN_CODE VARCHAR2  default null ) Return Varchar2
IS

    MAX_ADD    NUMBER:=0;
    lv_tele_code    varchar2(4);
    vl_error Varchar(2500):=Null;
    vl_existe number:=0;


BEGIN



        Begin         
            Select count(*)
                into vl_existe
            from SPRADDR
            where 1=1
          And SPRADDR_PIDM = p_pidm
          And SPRADDR_ATYP_CODE = p_atyp_code;          
        Exception
            When Others then 
                vl_existe:=0;
        End;


        If vl_existe = 0 then 
        
                Begin 
                    SELECT NVL(MAX(SPRADDR_SEQNO),0)  MAX
                    INTO  MAX_ADD
                    FROM  SPRADDR
                    WHERE SPRADDR_PIDM = p_pidm;
                Exception
                    When Others then
                       MAX_ADD:=1;  
                End;
        

                Begin 

                        insert into  SPRADDR  (
                        SPRADDR_PIDM,
                        SPRADDR_ATYP_CODE,---   pendiente
                        SPRADDR_SEQNO,  ----interno secq
                        SPRADDR_CITY,
                        SPRADDR_ACTIVITY_DATE,
                        SPRADDR_STREET_LINE1, ---calle, numero ext, num inte
                        SPRADDR_STREET_LINE2, --colonia
                        SPRADDR_STREET_LINE3, --  entre que calles  referencias
                        SPRADDR_STAT_CODE, -- estado- provincia
                        SPRADDR_ZIP, ---c.p.
                        SPRADDR_CNTY_CODE, -- delg o municipio
                        SPRADDR_NATN_CODE, --- cod pais
                        SPRADDR_STATUS_IND,  --- default    Y
                        SPRADDR_USER,    --user
                        SPRADDR_DATA_ORIGIN,   ---resa
                        SPRADDR_USER_ID----user
                        )
                        values (  p_pidm, p_atyp_code,  1,  P_CITY, SYSDATE,  P_STREET_LINE1, P_STREET_LINE2, P_STREET_LINE3, P_STAT_CODE, P_ZIP, P_CNTY_CODE,P_NATN_CODE, null , 'SistemaV2','Resa','SistemaV2' );
                        vl_error:='Proceso Exitoso';
                Exception
                    When Others then
                        vl_error:='Se presento un error al insertar la direccion' ||sqlerrm;
                End;



                -- Actualiza el tipo de Dirección asociado al teléfono
                 begin
                    select stvatyp_tele_code 
                        into  lv_tele_code
                    from stvatyp
                    where stvatyp_code=p_atyp_code;
                 exception when others then
                     lv_tele_code:=null;
                 end;

                 If lv_tele_code is not null then 
                

                     Begin 
                         update sprtele 
                            set sprtele_atyp_code=p_atyp_code, 
                                sprtele_addr_seqno=1, 
                                sprtele_primary_ind='Y'
                         where sprtele_pidm=p_pidm
                         and     sprtele_tele_code=lv_tele_code;
                         vl_error:='Proceso Exitoso';
                     Exception
                        When Others then 
                            vl_error:='Se presento un error al actualizar el tipo de la direccion' ||sqlerrm;
                     End;
                 
                 End if;

        End if;
        commit;
        Return vl_error;
        
Exception
    When others then
        vl_error:='Error'||sqlerrm;
        Return vl_error;

END sp_addres;


procedure  sp_create_pin ( pidm  number)   is   --create or replace sp_pin()  is


vs_pin  varchar2(2000);

begin

   IF goktpty.F_Create_Pin_Ok('SGBSTDN') THEN
    --vs_pin   :=  goktpty.p_get_global_pidm;
         BANINST1.GOKTPTY.P_Insert_Gobtpac(pidm, vs_pin);
   END IF;

--dbms_output.put_line( '  pin ....' ||  vs_pin);
----genera el PIN segun fecha de nacimiento
-----  ddmmyy
-- los digitos de dia--mes--y aÃ±o los ultimos  digitos

commit;
EXCEPTION
 WHEN OTHERS THEN
lv_msgerr  :=  'ERROR PKG_Resa.sp_create_pin: '||SQLERRM;

end sp_create_pin;

FUNCTION sp_saaratt(vpidm_u    number, P_TERM_CODE_ENTRY   varchar2, p_appl_no in number default null, ATTS_CODE in  varchar2 ) Return Varchar2
is

lv_maxapp    number:=0;
vl_error Varchar(2500):='EXITO';
vl_appl_no number:=0;
vl_existe number :=0;

BEGIN

  dbms_output.put_line('llega sraatt primer solicitud' || ATTS_CODE || '*'||p_appl_no ||'*'||P_TERM_CODE_ENTRY);




  if p_appl_no is null then
  vl_appl_no:=1;
  vl_existe :=0;


      Begin
        Select count(1)
        Into vl_existe
        from SARAATT
        Where SARAATT_PIDM = vpidm_u
        And SARAATT_TERM_CODE = P_TERM_CODE_ENTRY
        And SARAATT_APPL_NO  = p_appl_no
        And SARAATT_ATTS_CODE = ATTS_CODE;

      Exception
        When Others then
        vl_existe :=0;
      End;

    If vl_existe = 0 then
               begin

                     dbms_output.put_line('llega sraatt primer solicitud' || ATTS_CODE || '*'||vl_appl_no ||'*'||P_TERM_CODE_ENTRY);

                    insert into  SARAATT
                    (SARAATT_PIDM,
                    SARAATT_TERM_CODE,
                    SARAATT_APPL_NO,
                    SARAATT_ATTS_CODE,
                    SARAATT_ACTIVITY_DATE,
                    --SARAATT_SURROGATE_ID,
                    --SARAATT_VERSION,
                    SARAATT_USER_ID,
                    SARAATT_DATA_ORIGIN,
                    SARAATT_VPDI_CODE)
                    values(vpidm_u , P_TERM_CODE_ENTRY, vl_appl_no , ATTS_CODE , sysdate, 'SistemaV2', 'Resa' , null);

                     -- vl_error:='Proceso Exitoso para la primer solicitud';

                      dbms_output.put_line('Salida '||vl_error);

               Exception
                when Others then
                vl_error := 'Se presento el error '||sqlerrm ||' en la tabla SARAATT';
                dbms_output.put_line('Salida '||vl_error);
               end;

               vl_existe :=0;
               Begin
                       Select count(*)
                        Into vl_existe
                       from SARCHRT
                       where SARCHRT_PIDM = vpidm_u
                       And SARCHRT_TERM_CODE_ENTRY = P_TERM_CODE_ENTRY
                       And SARCHRT_APPL_NO = vl_appl_no
                       And SARCHRT_CHRT_CODE = P_TERM_CODE_ENTRY;
               Exception
                When Others then
                  vl_existe :=0;
               End;

               If  vl_existe = 0 then
                       Begin
                            Insert into SARCHRT values (vpidm_u,
                                                                    P_TERM_CODE_ENTRY,
                                                                    vl_appl_no,
                                                                    P_TERM_CODE_ENTRY,
                                                                    sysdate,
                                                                    null,
                                                                    null,
                                                                    'SistemaV2',
                                                                    'Resa',
                                                                    null);

                       --   vl_error:='Proceso Exitoso para la primer solicitud SARCHRT';
                          dbms_output.put_line('Salida '||vl_error);
                       Exception
                        When Others then
                         vl_error := 'Se presento el error '||sqlerrm ||' en la tabla SARCHRT';
                         dbms_output.put_line('Salida '||vl_error);
                       End;
               End If;
    End if;

  else

  dbms_output.put_line('llega sraatt primer solicitud' || ATTS_CODE || '*'||vl_appl_no ||'*'||P_TERM_CODE_ENTRY);

  vl_existe :=0;

      Begin
        Select count(1)
        Into vl_existe
        from SARAATT
        Where SARAATT_PIDM = vpidm_u
        And SARAATT_TERM_CODE = P_TERM_CODE_ENTRY
        And SARAATT_APPL_NO  = p_appl_no
        And SARAATT_ATTS_CODE = ATTS_CODE;

      Exception
        When Others then
        vl_existe :=0;
      End;

            If vl_existe = 0 then

                    begin
                        insert into  SARAATT
                        (SARAATT_PIDM,
                        SARAATT_TERM_CODE,
                        SARAATT_APPL_NO,
                        SARAATT_ATTS_CODE,
                        SARAATT_ACTIVITY_DATE,
                        --SARAATT_SURROGATE_ID,
                        --SARAATT_VERSION,
                        SARAATT_USER_ID,
                        SARAATT_DATA_ORIGIN,
                        SARAATT_VPDI_CODE)
                        values(vpidm_u , P_TERM_CODE_ENTRY, p_appl_no , ATTS_CODE , sysdate, 'SistemaV2', 'Resa' , null);
                    --    vl_error:='Proceso Exitoso para la segunda solicitud SARAATT';
                        dbms_output.put_line('Salida '||vl_error);
                     Exception
                        When Others then
                            vl_error := 'Se presento el error '||sqlerrm ||' en la tabla SARAATT';
                    end;


               vl_existe :=0;
               Begin
                       Select count(*)
                        Into vl_existe
                       from SARCHRT
                       where SARCHRT_PIDM = vpidm_u
                       And SARCHRT_TERM_CODE_ENTRY = P_TERM_CODE_ENTRY
                       And SARCHRT_APPL_NO = vl_appl_no
                       And SARCHRT_CHRT_CODE = P_TERM_CODE_ENTRY;
               Exception
                When Others then
                  vl_existe :=0;
               End;

               If  vl_existe = 0 then

                   Begin
                    Insert into SARCHRT values (vpidm_u,
                                                            P_TERM_CODE_ENTRY,
                                                            p_appl_no,
                                                            P_TERM_CODE_ENTRY,
                                                            sysdate,
                                                            null,
                                                            null,
                                                            'SistemaV2',
                                                            'Resa',
                                                            null);

                  --    vl_error:='Proceso Exitoso para la segunda solicitud SARCHRT';
                      dbms_output.put_line('Salida '||vl_error);
                   Exception
                    When Others then
                     vl_error := 'Se presento el error '||sqlerrm ||' en la tabla SARCHRT';
                     dbms_output.put_line('Salida '||vl_error);
                   End;

               End if;
            End if;
  end if;
    commit;
    Return vl_error;
    Exception
     WHEN OTHERS THEN
        vl_error:='Error PKG_RESA.sp_saaratt'||sqlerrm;
        Return vl_error;
    end sp_saaratt;

--SE CREA LA FUNCIÓN PARA CACHAR UN ERROR--

FUNCTION  sp_SPREMRG  ( p_pidm number,  p_fname varchar2,  p_lnames varchar2,  p_rectcode  varchar2 , p_cnty varchar2, p_stat varchar2, p_natn  varchar2 , p_zip  varchar2, p_mi varchar2, p_stt_line1 varchar2, p_stt_line2 varchar2,  p_stt_line3 varchar2, p_city varchar2, p_phone varchar2, p_rg_fs  varchar2, p_cfdi  varchar2 ) Return Varchar2
is
    max_sprem    number:=0;
    vl_error Varchar(2500):=Null;
begin

        select    NVL(max(SPREMRG_PRIORITY),0) + 1 into max_sprem
        from SPREMRG
        where  SPREMRG_PIDM  = p_pidm;

        INSERT INTO SPREMRG
        (
        SPREMRG_PIDM,
        SPREMRG_PRIORITY,
        SPREMRG_LAST_NAME,
        SPREMRG_FIRST_NAME,
        SPREMRG_ACTIVITY_DATE,
        --SPREMRG_SURROGATE_ID,
        --SPREMRG_VERSION,
        SPREMRG_MI,
        SPREMRG_STREET_LINE1,
        SPREMRG_STREET_LINE2,
        SPREMRG_STREET_LINE3,
        SPREMRG_STREET_LINE4,
        SPREMRG_CITY,
        SPREMRG_STAT_CODE,
        SPREMRG_NATN_CODE,
        SPREMRG_ZIP,
        --SPREMRG_PHONE_AREA,
        SPREMRG_PHONE_NUMBER,
        --SPREMRG_PHONE_EXT,
        SPREMRG_RELT_CODE,
        --SPREMRG_ATYP_CODE,
        SPREMRG_DATA_ORIGIN,
        SPREMRG_USER_ID,
        SPREMRG_RG_FS,
        SPREMRG_CFDI

        --SPREMRG_SURNAME_PREFIX,
        --SPREMRG_CTRY_CODE_PHONE,
        --SPREMRG_HOUSE_NUMBER,
        --SPREMRG_STREET_LINE4,
        --SPREMRG_VPDI_CODE
         )
        VALUES( p_pidm, max_sprem,  p_lnames, p_fname,  sysdate,p_mi,p_stt_line1, p_stt_line2, p_stt_line3, p_cnty,  p_city , p_stat, p_natn, p_zip,p_phone,  p_rectcode, 'Resa','SistemaV2',p_rg_fs,p_cfdi);

commit;
vl_error:='Proceso Exitoso';
Return vl_error;
Exception
 When others then
    vl_error := 'ERROR PKG_RESA.sp_SPREMRG: '||sqlerrm ;

end sp_SPREMRG;


FUNCTION sp_saracmt  (p_pidm  number, p_periodo varchar2, p_texto  varchar2, p_orig varchar2, p_appl_no in number) Return Varchar2
 is

        vmax_cmt     number:=0;
        vmax_appl    number:=0;
        lv_msgerr varchar2(2500):=Null;

begin

        SELECT   NVL(MAX(SARACMT_SEQNO),0) + 1 INTO vmax_cmt
        FROM SARACMT
        where   SARACMT_PIDM  = p_pidm;

--        Begin
--            select NVL(max(SARADAP_APPL_NO),0) +1 into vmax_appl
--            from saradap
--            where saradap_pidm = p_pidm;
--
--        Exception
--        when Others then
--         vmax_appl := 1;
--        End;

dbms_output.put_line('Param  '||p_pidm||'* ' ||p_appl_no||'* ' ||vmax_cmt||'* ' ||p_orig||'* ' ||p_texto);
     begin
        insert into  saracmt(
        SARACMT_PIDM,
        SARACMT_TERM_CODE,
        SARACMT_APPL_NO,
        SARACMT_SEQNO,
        SARACMT_ORIG_CODE,
        SARACMT_ACTIVITY_DATE,
        SARACMT_COMMENT_TEXT,
        --SARACMT_SURROGATE_ID
        --SARACMT_VERSION
        SARACMT_USER_ID,
        SARACMT_DATA_ORIGIN
        --SARACMT_VPDI_CODE
         )
        VALUES (p_pidm, p_periodo ,p_appl_no,  vmax_cmt, p_orig, sysdate, p_texto,  'SistemaV2', 'Resa' ) ;
        commit;
         Exception
      When others then
            lv_msgerr  :='ERROR PKG_-RESA.sp_saracmt'||sqlerrm;
            return(lv_msgerr);
     end;

       lv_msgerr:='Proceso Exitoso';
    Return (lv_msgerr);

Exception
 When others then
    lv_msgerr  :='ERROR PKG_-RESA.sp_saracmt'||sqlerrm;
--dbms_output.put_line (lv_msgerr);

end sp_saracmt;


FUNCTION  sp_sorins ( p_pidm  number, p_INTS_CODE   varchar2  )Return Varchar2
is
        vl_error Varchar2(2500):=Null;

begin

        insert into  sorints(
        SORINTS_PIDM,
        SORINTS_INTS_CODE,
        SORINTS_ACTIVITY_DATE,
        --SORINTS_SURROGATE_ID
        --SORINTS_VERSION
        SORINTS_USER_ID,
        SORINTS_DATA_ORIGIN
        --SORINTS_VPDI_CODE
        )
        VALUES( p_pidm, p_INTS_CODE, SYSDATE, 'SistemaV2', 'Resa');

commit;
vl_error:='Proceso Exitoso';
Return vl_error;
Exception
 When others then
    vl_error  :='ERROR PKG_RESA.sp_sorins: '||sqlerrm;

end sp_sorins;


FUNCTION  sp_actualiza_persona ( p_pidm  number, p_MRTL_CODE varchar2)Return Varchar2
is
    vl_error Varchar2(2500):=Null;

-- proceso que actualiza el estatus matrimonial de un persona valores:
-----C    casado
-----S    soltero
-----glovix  24.nov.2015

begin

update  spbpers
set   SPBPERS_MRTL_CODE   = p_MRTL_CODE
        --,SPBPERS_LEGAL_NAME = (SELECT SPRIDEN_LAST_NAME || ' ' || SPRIDEN_FIRST_NAME FROM SPRIDEN WHERE SPRIDEN_PIDM = p_pidm and SPRIDEN_CHANGE_IND IS NULL)  ESTE CAMPO YA SE ACTUALIZA DESDE QUE SE GENERA LA PERSONA
where  SPBPERS_PIDM  = p_pidm;
commit;

update spbpers set spbpers_citz_code=(select decode(spraddr_natn_code,'148','ME',null,null,'EXT') from spraddr
                                                          where spraddr_pidm=p_pidm
                                                          and     spraddr_atyp_code='NA')
where spbpers_pidm=p_pidm;

commit;
vl_error:='Proceso exitoso';
Return vl_error;

EXCEPTION
 WHEN OTHERS THEN
vl_error  :=  'Error PKG_RESA.sp_actualiza_persona: ' ||SQLERRM;
Return vl_error;

end  sp_actualiza_persona;

FUNCTION   sp_tbbestu    ( p_pidm  number, p_code_exemp   varchar2,   p_term_code varchar2 ) Return Varchar2
is

    lv_msgerr Varchar2(2500):=Null;
    vl_existe number :=0;
    vl_existe_p2 number;
    vl_PRIORITY number;
/*
proceso que inserta las becas que tiene un alumno por period
glovicx  24.nov.2015

*/

--Begin
--null;
--End;


        begin
                    vl_existe :=0;

                Begin
                    select count(1)
                        into vl_existe
                    from TBBESTU
                    where TBBESTU_PIDM   = p_pidm
                    and TBBESTU_TERM_CODE = p_term_code
                    and TBBESTU_EXEMPTION_CODE = p_code_exemp;
            exception
                When Others then
                  vl_existe:=0;
            End;

            If vl_existe = 0 then

                Begin
                        select count(1)
                        into vl_existe_p2
                        from TBBESTU
                        where TBBESTU_PIDM   = p_pidm
                        and TBBESTU_TERM_CODE = p_term_code;
                exception
                    When Others then
                      vl_existe:=0;
                End;

                If vl_existe_p2 = 0 then

                        Begin
                                INSERT INTO  TBBESTU (
                                TBBESTU_PIDM,
                                TBBESTU_EXEMPTION_CODE,
                                TBBESTU_TERM_CODE,
                                TBBESTU_ACTIVITY_DATE,
                                TBBESTU_STUDENT_EXPT_ROLL_IND,
                                TBBESTU_USER_ID,
                                TBBESTU_EXEMPTION_PRIORITY, --------
                                --TBBESTU_DEL_IND,
                                --TBBESTU_TERM_CODE_EXPIRATION,
                                --TBBESTU_MAX_STUDENT_AMOUNT,
                                --TBBESTU_SURROGATE_ID,
                                --TBBESTU_VERSION,
                                TBBESTU_DATA_ORIGIN
                                --TBBESTU_VPDI_CODE
                                )
                                VALUES (  p_pidm, p_code_exemp, p_term_code, sysdate, 'Y', 'SistemaV2',1, 'Resa');
                                lv_msgerr:='Proceso exitoso';
                        Exception
                            When Others then
                                lv_msgerr:='Se presento el errro '||sqlerrm;
                        End;

                else
                        UPDATE TBBESTU
                        SET TBBESTU_DEL_IND = 'Y'
                        WHERE TBBESTU_PIDM   = p_pidm
                        AND TBBESTU_TERM_CODE = p_term_code;

                        Begin
                                select a.TBBESTU_EXEMPTION_PRIORITY+1
                                into vl_PRIORITY
                                from TBBESTU a
                                where a.TBBESTU_PIDM   = p_pidm
                                and a.TBBESTU_TERM_CODE = p_term_code
                                and a.TBBESTU_ACTIVITY_DATE = (select max(a1.TBBESTU_ACTIVITY_DATE)
                                                               from TBBESTU a1
                                                               where a1.TBBESTU_PIDM = a.TBBESTU_PIDM
                                                               and a1.TBBESTU_TERM_CODE= a.TBBESTU_TERM_CODE)
                                ;
                        exception
                            When Others then
                              vl_PRIORITY:=0;
                        End;

                        Begin
                                INSERT INTO  TBBESTU (
                                TBBESTU_PIDM,
                                TBBESTU_EXEMPTION_CODE,
                                TBBESTU_TERM_CODE,
                                TBBESTU_ACTIVITY_DATE,
                                TBBESTU_STUDENT_EXPT_ROLL_IND,
                                TBBESTU_USER_ID,
                                TBBESTU_EXEMPTION_PRIORITY, --------
                                --TBBESTU_DEL_IND,
                                --TBBESTU_TERM_CODE_EXPIRATION,
                                --TBBESTU_MAX_STUDENT_AMOUNT,
                                --TBBESTU_SURROGATE_ID,
                                --TBBESTU_VERSION,
                                TBBESTU_DATA_ORIGIN
                                --TBBESTU_VPDI_CODE
                                )
                                VALUES (  p_pidm, p_code_exemp, p_term_code, sysdate, 'Y', 'SistemaV2',vl_PRIORITY, 'Resa');
                                lv_msgerr:='Proceso exitoso';
                        Exception
                            When Others then
                                lv_msgerr:='Se presento el errro '||sqlerrm;
                        End;

                end if;

            End if;

commit;

Return lv_msgerr;
Exception
 When others then
    lv_msgerr  :='Error PKG_RESA.sp_tbbestu'||sqlerrm;
    Return lv_msgerr;
end sp_tbbestu;

FUNCTION sp_sgrdisa(p_pidm  number, p_term_code varchar2, p_disa_code varchar2, p_medi_code varchar2, p_spsr_code varchar2 , p_primary varchar2) Return Varchar2
is
    lv_msgerr Varchar2(2500):=Null;
begin
        insert into SGRDISA (
        SGRDISA_PIDM,
        SGRDISA_TERM_CODE,
        SGRDISA_DISA_CODE,
        SGRDISA_ACTIVITY_DATE,
        SGRDISA_MEDI_CODE,
        SGRDISA_SPSR_CODE,
        SGRDISA_PRIMARY_IND,
        --SGRDISA_SURROGATE_ID,
        --SGRDISA_VERSION,
        SGRDISA_USER_ID,
        SGRDISA_DATA_ORIGIN
        --SGRDISA_VPDI_CODE
        )
        VALUES(p_pidm, p_term_code, p_disa_code, sysdate, p_medi_code, p_spsr_code,p_primary , 'SistemaV2', 'Resa');

commit;
lv_msgerr:='Proceso exitoso';
Return lv_msgerr;
Exception
 When others then
    lv_msgerr:='Error PKG_RESA.sp_sgrdisa: '||sqlerrm;
end sp_sgrdisa ;

FUNCTION sp_sorhsch (p_pidm number, p_sbgi_code varchar2, p_graduaton varchar2, p_gpa varchar2 ) Return Varchar2
is
        lv_msgerr Varchar2(2500):=Null;
begin

        insert into  SORHSCH(
        SORHSCH_PIDM,
        SORHSCH_SBGI_CODE,
        SORHSCH_ACTIVITY_DATE,
        --SORHSCH_SURROGATE_ID,
        SORHSCH_VERSION,----
        SORHSCH_GRADUATION_DATE,
        SORHSCH_GPA,
        --SORHSCH_CLASS_RANK
        --SORHSCH_CLASS_SIZE
        --SORHSCH_PERCENTILE
        --SORHSCH_DPLM_CODE
        --SORHSCH_COLL_PREP_IND
        --SORHSCH_TRANS_RECV_DATE
        --SORHSCH_ADMR_CODE
        SORHSCH_USER_ID,
        SORHSCH_DATA_ORIGIN
        --SORHSCH_VPDI_CODE
        )
        values ( p_pidm, p_sbgi_code, sysdate, 0, to_date(p_graduaton, 'dd/mm/yyyy'), p_gpa, 'SistemaV2', 'Resa' );

commit;
lv_msgerr:='Proceso exitoso';
Return lv_msgerr;
Exception
 When others then
    lv_msgerr  :='Error PKG_RESA.sp_sorhsch'||SQLERRM;
    Return lv_msgerr;
end  sp_sorhsch;

FUNCTION sp_sordegr  (p_pidm number, p_sbgi_code varchar2,  p_degc_code varchar2, p_gpa_tr varchar2, p_degc_year varchar2 ) Return Varchar2
is
        lv_max_seq  number:= 0;
        lv_count_sp  number:=0;
        lv_msgerr Varchar2(2500):=Null;
begin

        select   nvl(max(SORDEGR_DEGR_SEQ_NO),0)+1  into lv_max_seq
        from SORDEGR
        where SORDEGR_PIDM= p_pidm;

        ------  esta tabla debe ir primero el insert  por que tiene una relacion con la siguiente
        select count(1)  into lv_count_sp
        from sorpcol
        where SORPCOL_PIDM  = p_pidm
        and  SORPCOL_SBGI_CODE =  p_sbgi_code ;

        IF lv_count_sp = 0 then

        insert into sorpcol (
        SORPCOL_PIDM  ,
        SORPCOL_SBGI_CODE,
        SORPCOL_ACTIVITY_DATE,
        --SORPCOL_SURROGATE_ID
        SORPCOL_VERSION  )
        values ( p_pidm  , p_sbgi_code , sysdate, 0 );
        end if;

        insert into SORDEGR (
        SORDEGR_PIDM,
        SORDEGR_SBGI_CODE,
        SORDEGR_DEGR_SEQ_NO,
        SORDEGR_ACTIVITY_DATE,
        --SORDEGR_SURROGATE_ID,
        SORDEGR_VERSION,-----------------------
        SORDEGR_DEGC_CODE,
        --SORDEGR_ATTEND_FROM,
        --SORDEGR_ATTEND_TO,
        --SORDEGR_HOURS_TRANSFERRED,
        SORDEGR_GPA_TRANSFERRED,
        --SORDEGR_DEGC_DATE,
        SORDEGR_DEGC_YEAR,
        --SORDEGR_COLL_CODE,
        --SORDEGR_HONR_CODE,
        --SORDEGR_TERM_DEGREE,
        --SORDEGR_EGOL_CODE,
        --SORDEGR_PRIMARY_IND,
        SORDEGR_DATA_ORIGIN,
        SORDEGR_USER_ID
        --SORDEGR_VPDI_CODE
        )
        values (  p_pidm, p_sbgi_code, lv_max_seq, sysdate, 0, p_degc_code, p_gpa_tr, p_degc_year, 'Resa', 'SistemaV2' );
commit;
lv_msgerr:='Proceso exitoso';
Return lv_msgerr;
Exception
 When others then
    lv_msgerr  :='Error PKG_RESA.sp_sordegr'||SQLERRM;
    Return lv_msgerr;
end  sp_sordegr;


FUNCTION  sp_sobsbgi ( p_sbgi  varchar2,  p_city  varchar2, p_st1 varchar2, p_st2 varchar2, p_st3 varchar2, p_stat varchar2, p_cnty varchar2, p_zip varchar2, p_natn varchar2, p_house varchar2, p_st4 varchar2)Return Varchar2
is

        lv_msgerr Varchar2(2500):=Null;
begin

        insert into SOBSBGI(
        SOBSBGI_SBGI_CODE,
        SOBSBGI_CITY,
        SOBSBGI_ACTIVITY_DATE,
        --SOBSBGI_SURROGATE_ID,
        --SOBSBGI_VERSION,
        SOBSBGI_STREET_LINE1,
        SOBSBGI_STREET_LINE2,
        SOBSBGI_STREET_LINE3,
        SOBSBGI_STAT_CODE,
        SOBSBGI_CNTY_CODE,
        SOBSBGI_ZIP,
        SOBSBGI_NATN_CODE,
        SOBSBGI_HOUSE_NUMBER,
        SOBSBGI_STREET_LINE4,
        SOBSBGI_USER_ID,
        SOBSBGI_DATA_ORIGIN
        --SOBSBGI_VPDI_CODE
        )
        values (p_sbgi ,p_city ,sysdate, p_st1 , p_st2 , p_st3 , p_stat , p_cnty , p_zip , p_natn , p_house , p_st4, 'SistemaV2', 'Resa'  );

commit;
lv_msgerr:='Proceso exitoso';
Return lv_msgerr;
Exception
 When others then
    lv_msgerr  :='Error PKG_RESA.sp_sobsbgi: '||SQLERRM;
    Return  lv_msgerr;
end  sp_sobsbgi;

FUNCTION sp_sorfolk(p_pidm number, p_relt_code varchar2, p_parent_l varchar2, p_parent_f varchar2, p_parent_deegr varchar2) Return Varchar2
is
--p_parent_me  varchar2  default null, p_name_pre varchar2  default null, p_name_suf varchar2  default null,
                              --p_atyp_code varchar2   default null,p_deceased varchar2   default null, p_parent_empl  varchar2  default null , p_parent_job varchar2  default null, p_parent_deegr varchar2  default null, p_surname varchar2   default null  )


begin

        insert into SORFOLK(
        SORFOLK_PIDM,
        SORFOLK_RELT_CODE,
        SORFOLK_PARENT_LAST,
        SORFOLK_PARENT_FIRST,
        SORFOLK_ACTIVITY_DATE,
        SORFOLK_PARENT_DEGREE,
        --SORFOLK_SURROGATE_ID,
        --SORFOLK_VERSION  , -----------Y----
        --SORFOLK_PARENT_MI,
        --SORFOLK_PARENT_NAME_PREFIX,
        --SORFOLK_PARENT_NAME_SUFFIX,
        SORFOLK_ATYP_CODE,
        --SORFOLK_DECEASED_IND,
        --SORFOLK_PARENT_EMPLOYER,
        --SORFOLK_PARENT_JOB_TITLE,
        --SORFOLK_SURNAME_PREFIX,
        SORFOLK_USER_ID,
        SORFOLK_DATA_ORIGIN
        --SORFOLK_VPDI_CODE
        )
        values ( p_pidm , p_relt_code , p_parent_l , p_parent_f , sysdate, p_parent_deegr, 'RF', 'SistemaV2','Resa'); --p_parent_me , p_name_pre , p_name_suf ,
                     --p_atyp_code ,p_deceased , p_parent_empl  , p_parent_job, p_parent_deegr , p_surname, user, 'Resa' );

commit;
lv_msgerr:='Proceso exitoso';
Return lv_msgerr;
Exception
 When others then
    lv_msgerr  :=  'Error PKG_RESA.sp_sorfolk: '||SQLERRM;
    Return lv_msgerr;
end sp_sorfolk;

--FUNCION CREADA PARA CACHAR EL  ERROR--

FUNCTION   sp_carga_ini (vpidm_u  number, P_TERM_CODE_ENTRY    VARCHAR2, P_APST_CODE    VARCHAR2, P_MAINT_IND    VARCHAR2, P_STYP_CODE    VARCHAR2,
                                        P_ADMT_CODE    VARCHAR2, P_RESD_CODE    VARCHAR2, P_LEVL_CODE    VARCHAR2, P_CAMP_CODE    VARCHAR2, P_COLL_CODE_1    VARCHAR2,
                                        P_DEGC_CODE_1 VARCHAR2, P_MAJR_CODE_1 VARCHAR2, P_PROGRAM_1 VARCHAR2 , P_ADDITIONAL_ID  VARCHAR2 , P_ADID_CODE VARCHAR2,
                                        P_USER_ID VARCHAR2, P_DATA_ORIGIN VARCHAR2, ATTS_CODE  VARCHAR2,  p_rate VARCHAR2, p_inicio_periodo VARCHAR2, P_PTRM_CODE VARCHAR2,
                                        p_apdc_code in varchar2, p_appl_no in number,p_costo in Varchar2 default null) Return Varchar2
IS
    vl_error Varchar2(2500):='Proceso Exitoso';
    v_sal Varchar2(2500);
       v_sal2 Varchar2(2500);
          v_sal3 Varchar2(2500);
             v_sal4 Varchar2(2500);
                v_sal5 Varchar2(2500);
    vl_RESD_CODE varchar2(2):= null;

begin
        ----este es el llamado principal de aqui se van ejecutando los demas procesos
        --sp_general (P_LAST_NAME, P_FIST_NAME,P_ENTITY_IND, p_campus ) ;
        --sp_carga_identficador (vpidm_u,P_ADDITIONAL_ID , P_ADID_CODE, P_USER_ID , P_DATA_ORIGIN )  ;   ok  1
        --sp_persona (vpidm_u, P_BIRTH_DATE, P_SEX ) ;
        --sp_mail(vpidm_u, P_EMAL_CODE, P_MAIL_ADDRESS );
        --sp_telefono (vpidm_u, P_TELE_CODE, P_PHONO_NUMBER );


       If P_RESD_CODE not in ('N', 'E') then
           vl_RESD_CODE:='N';
       ElsIf P_RESD_CODE is null then 
           vl_RESD_CODE:='N';
       Elsif P_RESD_CODE in ('N', 'E') then
           vl_RESD_CODE:= P_RESD_CODE;
       End if;
 

        v_sal:=sp_admision     (vpidm_u, P_TERM_CODE_ENTRY, P_APST_CODE, P_MAINT_IND, P_STYP_CODE, P_ADMT_CODE, vl_RESD_CODE, p_rate,  p_apdc_code, p_appl_no);
                 DBMS_OUTPUT.PUT_LINE('salida '||v_sal);
        v_sal2:=sp_campus       (vpidm_u,P_TERM_CODE_ENTRY, vappl_no_admin, P_LEVL_CODE, P_CAMP_CODE, P_COLL_CODE_1 , P_DEGC_CODE_1 , P_MAJR_CODE_1 , P_PROGRAM_1  );
        DBMS_OUTPUT.PUT_LINE('salida2 '||v_sal2);
        v_sal3:=sp_sorlcurfos    (vpidm_u , P_TERM_CODE_ENTRY , vappl_no_admin ,  P_LEVL_CODE, P_CAMP_CODE, P_PROGRAM_1, p_inicio_periodo, P_PTRM_CODE,p_costo ) ;
        DBMS_OUTPUT.PUT_LINE('salida3 '||v_sal3);
        v_sal4:=fn_niveles         (vpidm_u, P_CAMP_CODE, P_TERM_CODE_ENTRY, P_PROGRAM_1, P_USER_ID,  P_DATA_ORIGIN, p_appl_no);
        DBMS_OUTPUT.PUT_LINE('salida4 '||v_sal4);
        v_sal5:=sp_saaratt        (vpidm_u , P_TERM_CODE_ENTRY, p_appl_no, ATTS_CODE) ;
        DBMS_OUTPUT.PUT_LINE('salida5 '||v_sal5);
            PKG_FREEMIUM.cancela_sgbstdn(vpidm_u);  ----- Este proceso cancelara el registro de SGBSTDN, cuando entran a traves del proyecto de FREEMIUM y existe cancelacion de Venta
        --
        --p_vsid          := vid_u;
        --p_vspidm    :=  vpidm_u;


 If v_sal = 'EXITO' then
        vl_error :='Proceso Exitoso';
Else
     vl_error := v_sal;
 End if;


If vl_error ='Proceso Exitoso' then
   commit;
Else
    rollback;
End if;
Return vl_error;
Exception
 When others then
    lv_msgerr  :='Error PKG_RESA.sp_carga_ini: '||SQLERRM;
    Return vl_error;
end sp_carga_ini;


FUNCTION   sp_carga_sarchkl (VPIDM_U  number, P_TERM_CODE_ENTRY    VARCHAR2, NO_ADMIN    NUMBER, ADMR_CODE    VARCHAR2, MANDATORY_IND    VARCHAR2,
                                        RECEIVE_DATE    VARCHAR2, COMENTARIO    VARCHAR2, CREATE_DATE    VARCHAR2, CKST_CODE    VARCHAR2) Return Varchar2
IS
    vl_error Varchar2(2500):=Null;
    v_sal Varchar2(2500);
    contador number;
    mandatory varchar2(1);

begin

       select count(*) into contador from sarchkl
       where sarchkl_pidm=VPIDM_U and sarchkl_term_code_entry=P_TERM_CODE_ENTRY
       and     sarchkl_appl_no=NO_ADMIN and sarchkl_admr_code=ADMR_CODE;
       dbms_output.put_line('contador:'||contador);

       if contador=0 then
          if MANDATORY_IND='Y' then
             mandatory:='Y';
          else
             mandatory:=null;
          end if;
          insert into sarchkl values(VPIDM_U, P_TERM_CODE_ENTRY, NO_ADMIN, ADMR_CODE, mandatory, null,null,null,null, to_date(RECEIVE_DATE,'dd/mm/rrrr'), COMENTARIO, null, 'S',
          to_date(CREATE_DATE,'dd/mm/rrrr'), sysdate, 'Y', 'BASELINE', CKST_CODE, null, null, 'BANINST1', 'Doctos', null);
          dbms_output.put_line('inserta registro:');
       else
           update sarchkl set sarchkl_mandatory_ind=mandatory,
                                      sarchkl_receive_date=to_date(RECEIVE_DATE,'dd/mm/rrrr'),
                                      sarchkl_comment=COMENTARIO,
                                      sarchkl_source_date=to_date(CREATE_DATE,'dd/mm/rrrr'),
                                      sarchkl_ckst_code=CKST_CODE
            where sarchkl_pidm=VPIDM_U and sarchkl_term_code_entry=P_TERM_CODE_ENTRY
            and     sarchkl_appl_no=NO_ADMIN and sarchkl_admr_code=ADMR_CODE;
            dbms_output.put_line('actualiza registro:');
       end if;

commit;
vl_error:='Proceso Exitoso';
Return vl_error;
Exception
 When others then
    vl_error  :='Error PKG_RESA.sp_carga_sarchkl: '||SQLERRM;
    Return vl_error;
end sp_carga_sarchkl;


Function fn_seguro  (pn_pidm in number,
                              pv_contrato in varchar2,
                              pv_detail_code in varchar2,
                              pd_fecha_ini date,
                              pd_fecha_fin date,
                              pv_inciso varchar2,
                              pv_user varchar2,
                              pv_marca varchar2,
                              pv_modelo varchar2,
                              pv_serie varchar2,
                              pv_imei varchar2,
                              pv_beneficiario varchar2
                              ) Return Varchar2

       is


vl_secuencia number:=0;
vl_error varchar2(2500):=null;

Begin

        Begin
              Insert into SZTSEGU values (pn_pidm,
                                                        pv_inciso,
                                                        pd_fecha_ini,
                                                        pd_fecha_fin,
                                                        pv_detail_code,
                                                        pv_contrato,
                                                        pv_user,
                                                        sysdate);

        Exception
            When Others then
             vl_error := 'Se presento un Error al Insertar cabecera en el Paquete pkg_Resa.fn_seguro' ||sqlerrm;
        End;

      If vl_error is null then

         Begin

            select nvl(max(SZTDSEG_SEQ_NUM), 0)+1 secuencia
            Into vl_secuencia
            from SZTDSEG
            Where SZTSEGU_PIDM = pn_pidm
            And SZTSEGU_CONTRATO = pv_contrato
            And SZTSEGU_FECH_INI = pd_fecha_ini
            And SZTSEGU_FECH_FIN = pd_fecha_fin;
         Exception
         When others then
           vl_secuencia:= 1;
           vl_error :=  'Se presento un Error al obtener la secuencia en el Paquete pkg_Resa.fn_seguro' ||sqlerrm;

         End;

     End if;

      If vl_error is null then



          Begin
                    Insert into SZTDSEG Values (pn_pidm,
                                                              pv_contrato,
                                                              pd_fecha_ini,
                                                              pd_fecha_fin,
                                                              vl_secuencia,
                                                              pv_marca,
                                                              pv_modelo,
                                                              pv_serie,
                                                              pv_imei,
                                                              pv_beneficiario,
                                                              pv_user,
                                                              sysdate);
          Exception
                When Others then
                 vl_error := 'Se presento un Error al Insertar Detalle en el Paquete pkg_Resa.fn_seguro' ||sqlerrm;
          End;


        End if;



        Return vl_error;

Exception
                When Others then
                 vl_error := 'Se presento un Error general en el Paquete pkg_Resa.fn_seguro' ||sqlerrm;
                  Return vl_error;


End;



FUNCTION fn_niveles (p_pidm number, P_CAMP_CODE Varchar2, P_TERM_CODE_ENTRY Varchar2, P_PROGRAM_1 Varchar2, P_USER_ID VARCHAR2, P_DATA_ORIGIN VARCHAR2, p_appl_no Varchar2) Return Varchar2
is

vl_error varchar2(2500):='EXITO';
vl_appl_no number:=0;

BEGIN
             IF p_appl_no is null then
                vl_appl_no:=1;

                Begin

                           For  c in (Select a.SZTDTEC_ATTS_CODE
                                            from sztdtec a
                                            Where a.SZTDTEC_CAMP_CODE = P_CAMP_CODE
                                            And a.SZTDTEC_PROGRAM = P_PROGRAM_1
                                            And a.SZTDTEC_TERM_CODE = (select max (a1.SZTDTEC_TERM_CODE)
                                                                                          from SZTDTEC a1
                                                                                          Where a1.SZTDTEC_PROGRAM = a.SZTDTEC_PROGRAM)

                           ) loop
                                                      dbms_output.put_line('llega a fn_niveles '||c.SZTDTEC_ATTS_CODE);
                                         Insert into SARAATT values (
                                                                                    p_pidm,        --SARAATT_PIDM
                                                                                    P_TERM_CODE_ENTRY,        --SARAATT_TERM_CODE
                                                                                    vl_appl_no,         --SARAATT_APPL_NO
                                                                                    c.SZTDTEC_ATTS_CODE,        --SARAATT_ATTS_CODE
                                                                                    sysdate,        --SARAATT_ACTIVITY_DATE
                                                                                    null,        --SARAATT_SURROGATE_ID
                                                                                    null,        --SARAATT_VERSION
                                                                                    P_USER_ID,         --SARAATT_USER_ID
                                                                                    P_DATA_ORIGIN,        --SARAATT_DATA_ORIGIN
                                                                                    null);          --SARAATT_VPDI_CODE

                           End Loop;
                          Return vl_error;
                Exception
                When Others then
                vl_error := 'Se presento un error al insertar en  fn_niveles para primer solicitud'||sqlerrm;
                End;

             ELSE

              begin
                For  c in (Select a.SZTDTEC_ATTS_CODE
                                            from sztdtec a
                                            Where a.SZTDTEC_CAMP_CODE = P_CAMP_CODE
                                            And a.SZTDTEC_PROGRAM = P_PROGRAM_1
                                            And a.SZTDTEC_TERM_CODE = (select max (a1.SZTDTEC_TERM_CODE)
                                                                                          from SZTDTEC a1
                                                                                          Where a1.SZTDTEC_PROGRAM = a.SZTDTEC_PROGRAM)

                           ) loop
                                                      dbms_output.put_line('llega a fn_niveles '||c.SZTDTEC_ATTS_CODE);
                                         Insert into SARAATT values (
                                                                                    p_pidm,        --SARAATT_PIDM
                                                                                    P_TERM_CODE_ENTRY,        --SARAATT_TERM_CODE
                                                                                    p_appl_no,         --SARAATT_APPL_NO
                                                                                    c.SZTDTEC_ATTS_CODE,        --SARAATT_ATTS_CODE
                                                                                    sysdate,        --SARAATT_ACTIVITY_DATE
                                                                                    null,        --SARAATT_SURROGATE_ID
                                                                                    null,        --SARAATT_VERSION
                                                                                    P_USER_ID,         --SARAATT_USER_ID
                                                                                    P_DATA_ORIGIN,        --SARAATT_DATA_ORIGIN
                                                                                    null);          --SARAATT_VPDI_CODE

                  End Loop;
                  Return vl_error;
                  Exception
                  When Others then
                  vl_error := 'Se presento un error al insertar en  fn_niveles para segunda solicitud'  ||sqlerrm;
             end;
             END IF;
             commit;
             Return vl_error;
             Exception
             When Others then
             vl_error := 'Se presento un error general en fn_niveles tud'  ||sqlerrm;
             Return vl_error;
END;

Function fn_proceden  (pn_pidm in number,    --- Funcion que registra la escuela de procedencia
                              pv_grado in varchar2,
                              pv_procedencia in varchar2,
                              pd_fechaEstudio varchar2,
                              pd_promedia number,
                              pv_user_id  varchar2,
                              p_data_origin varchar2
                              ) Return Varchar2

Is
vl_error varchar2(2500):=null;

Begin

        If pv_grado = 'LICE' then


               Begin

                             Insert into SORPCOL  Values (
                                                                            pn_pidm,           --SORPCOL_PIDM
                                                                            pv_procedencia,  --SORPCOL_SBGI_CODE
                                                                            null,                     --SORPCOL_TRANS_RECV_DATE
                                                                            null,                    --SORPCOL_TRANS_REV_DATE
                                                                            null,                    --SORPCOL_OFFICIAL_TRANS
                                                                            null,                    --SORPCOL_ADMR_CODE
                                                                            sysdate,               --SORPCOL_ACTIVITY_DATE
                                                                            p_data_origin,       --SORPCOL_DATA_ORIGIN
                                                                            pv_user_id,           --SORPCOL_USER_ID
                                                                            null,                    --SORPCOL_SURROGATE_ID
                                                                            null,                    --SORPCOL_VERSION
                                                                            null);                    --SORPCOL_VPDI_CODE

               Exception
                When others then
                  vl_error:= 'Se presento el Error al insertar en la tabla SORPCOL en el paquete pkg_Resa.fn_proceden:= ' ||sqlerrm;
               End;




             Begin

                    If   vl_error is null then
                      Insert into SORDEGR values (  pn_pidm,           --SORDEGR_PIDM
                                                                  pv_procedencia, ---SORDEGR_SBGI_CODE
                                                                  pv_grado,         ---      SORDEGR_DEGC_CODE
                                                                  1,                     --- SORDEGR_DEGR_SEQ_NO
                                                                  null,                      ---SORDEGR_ATTEND_FROM
                                                                  null,                      ---SORDEGR_ATTEND_TO
                                                                  null,                      ---SORDEGR_HOURS_TRANSFERRED
                                                                  pd_promedia,                      ---SORDEGR_GPA_TRANSFERRED
                                                                  null,                      ---SORDEGR_DEGC_DATE
                                                                  substr (pd_fechaEstudio, 7, 10),--- SORDEGR_DEGC_YEAR
                                                                  null,                    ---SORDEGR_COLL_CODE
                                                                  null,                    ---SORDEGR_HONR_CODE
                                                                  sysdate,               --- SORDEGR_ACTIVITY_DATE
                                                                  null,                    --- SORDEGR_TERM_DEGREE
                                                                  null,                   ---     SORDEGR_EGOL_CODE
                                                                  null,                   ---     SORDEGR_PRIMARY_IND
                                                                  p_data_origin,    ---    SORDEGR_DATA_ORIGIN
                                                                  pv_user_id,         ---    SORDEGR_USER_ID
                                                                  null,                   ---     SORDEGR_SURROGATE_ID
                                                                  null,                   ---  SORDEGR_VERSION
                                                                  null);                  --- SORDEGR_VPDI_CODE
                    End if;
               Exception
                When others then
                  vl_error:= 'Se presento el Error al insertar en la tabla SORDEGR en el paquete pkg_Resa.fn_proceden:= ' ||sqlerrm;
               End;


         Else

              Begin

                      Insert into  SORHSCH values (
                                                                 pn_pidm,   --SORHSCH_PIDM
                                                                 pv_procedencia,   --SORHSCH_SBGI_CODE
                                                                  to_date(pd_fechaEstudio, 'dd/mm/rrrr'),   --SORHSCH_GRADUATION_DATE
                                                                 pd_promedia,   --SORHSCH_GPA
                                                                 null,   --SORHSCH_CLASS_RANK
                                                                 null,   --SORHSCH_CLASS_SIZE
                                                                 null,   --SORHSCH_PERCENTILE
                                                                 null,   --SORHSCH_DPLM_CODE
                                                                 null,   --SORHSCH_COLL_PREP_IND
                                                                 null,   --SORHSCH_TRANS_RECV_DATE
                                                                 sysdate,   --SORHSCH_ACTIVITY_DATE
                                                                 null,   --SORHSCH_ADMR_CODE
                                                                pv_user_id,    --SORHSCH_USER_ID
                                                                p_data_origin,    --SORHSCH_DATA_ORIGIN
                                                                null,    --SORHSCH_SURROGATE_ID
                                                                null,    --SORHSCH_VERSION
                                                                null);    --SORHSCH_VPDI_CODE

              Exception
                When others then
                  vl_error:= 'Se presento el Error al insertar en la tabla SORHSCH en el paquete pkg_Resa.fn_proceden:= ' ||sqlerrm;
              End;

        End if;

        Return vl_error;

Exception
When others then
       vl_error:= 'Se presento el Error a nivel General en el paquete pkg_Resa.fn_proceden:= ' ||sqlerrm;

 Return vl_error;

End;

FUNCTION sp_insert_venf(pidm in  number, cuenta varchar2, adid_code varchar2, user_id varchar2, data_origin varchar2, periodo varchar2, appl_no in number ) return varchar2 is

-- appl_no number;
mensaje varchar2(200);

begin
-- select nvl(max(saradap_appl_no),1) into appl_no from saradap
--  where saradap_pidm=pidm;
        begin
            insert into saracmt values(pidm, periodo, appl_no, (select nvl(max(saracmt_seqno),0) +1 from saracmt where saracmt_pidm=pidm and saracmt_appl_no = appl_no), cuenta, adid_code, sysdate, null,null, user_id, data_origin, null);
            commit;
            mensaje:='Operación exitosa';
            exception when others then
            mensaje:=sqlerrm;
        end;
        return mensaje;
end;



FUNCTION venf_canf_update(p_pidm in number, p_term_code in varchar2,  p_applno in number, p_tetxt in varchar2, p_orig_code in varchar2) Return Varchar2 is
vl_mensaje varchar2(200):='Exito al actualizar saracmt';

BEGIN

    if p_pidm is null or p_term_code is null or p_applno is null or p_tetxt is null  or p_orig_code is null then
        vl_mensaje:='algún parametro vacio';
    else
            begin
                update saracmt set  saracmt_comment_text = p_tetxt
                where
                saracmt_pidm=p_pidm
                and saracmt_term_code = p_term_code
                and saracmt_appl_no= p_applno
                and saracmt_orig_code = p_orig_code;
                commit;
                exception when others then
                vl_mensaje:='Error al actualizar sarcmt '||sqlerrm;
            end;
            return vl_mensaje;
    end if;
END;

FUNCTION sp_insert_tzcondr(p_pidm in number, p_tran_num in number, p_pay_id in varchar2, p_amount in number,  p_detail_code in varchar2, p_trans_date in varchar2 ) Return varchar2
is
    mensaje varchar2(250);


        begin
        insert into TZCONDR values(p_pidm, p_tran_num, p_pay_id, p_amount, p_detail_code, p_trans_date);
        commit;
        exception
        when others then
        mensaje:='Error al insertar en TZCONDR'||sqlerrm;
        return mensaje;
        end;

FUNCTION sp_insert_tzdocta(p_pidm in number default null, p_term_code in varchar2 default null, p_appl_no in number default null, p_gross_price in number default null, p_discount in number default null, p_cond in number default null,
                                         p_cond_price in number default null, p_mens in number default null, p_pay_date in number default null, p_program_code in varchar2 default null) Return varchar2
is
    mensaje varchar2(250)  := 'Exito tzdocta';
    vl_existe number :=0;



   begin

    if p_pidm is null or p_term_code is null or p_appl_no  is null or p_gross_price is null or p_discount is null or p_cond is null or  p_cond_price is null or p_mens is null or p_pay_date is null or p_program_code is null  then
        mensaje:='Parametro vacio';


    else

            vl_existe :=0;

            Begin
                Select count(1)
                    Into vl_existe
                from TZDOCTA
                where TZDOCTA_PIDM = p_pidm
                and TZDOCTA_TERM_CODE = p_term_code
                and TZDOCTA_APPL_NO = p_appl_no;
            Exception
                When Others then
                  vl_existe :=0;
            End;


                 begin
                        insert into TZDOCTA values (p_pidm, p_term_code, p_appl_no, p_gross_price, p_discount, p_cond,p_cond_price, p_mens, p_pay_date, null, null, null, p_program_code, TRUNC(SYSDATE));
                        commit;
                        return mensaje;
                exception
                when others then
                mensaje:='Error al insertar en TZDOCTA'||sqlerrm;
                end;
     end if;
     commit;
     return mensaje;
  Exception
When Others then
mensaje := 'Errro General '||sqlerrm;
rollback;
return mensaje;
end;

FUNCTION sp_insert_tzacrys(p_pidm in number default null, p_term_code in number default null, p_appl_no in number default null, p_acrys in varchar2 default null) Return varchar2
is
    mensaje varchar2(250) := ' Exito tzacrys' ;
    seq_no number:=0;

begin

       if  p_pidm is null or p_term_code is null or p_appl_no is null or p_acrys is null then
               mensaje:='Parametro vacio' ;
       else


         begin
                begin
                    select  nvl(max(TZACRYS_SEQ_NO),0)+1
                    into seq_no
                    from TZACRYS
                    where TZACRYS_DOCTA_PIDM = p_pidm
                    and TZACRYS_DOCTA_TERM_CODE = p_term_code
                    and TZACRYS_APPL_NO = p_appl_no;
                Exception
                When Others then
                   seq_no:= 1;
                end;

                begin
                insert into TAISMGR.TZACRYS values(p_pidm, p_term_code, p_appl_no, p_acrys, seq_no);
                exception
                when others then
                mensaje:='Error al insertar en TZACRYS'||sqlerrm;
                end;
        end;
      end if;
      commit;
     return mensaje;
  end;

  FUNCTION f_insert_sarappd_dec40 (p_pidm in number default null, p_term_code_entry in Varchar2 default null, p_appl_no in number default null, p_usuario in varchar2 default null) Return Varchar2
    is

    vl_msje Varchar2(250):= 'Exito';
    max_seq_no number:=0;

    BEGIN
        IF p_pidm is null or p_term_code_entry is null or p_appl_no is null  then
            vl_msje:='Parametro nullo';


        ELSE

            BEGIN

                  BEGIN
                    SELECT nvl(max(SARAPPD_SEQ_NO),0)+1
                    into max_seq_no
                    FROM SARAPPD
                    WHERE SARAPPD_PIDM = p_pidm
                    AND SARAPPD_TERM_CODE_ENTRY = p_term_code_entry
                    AND    SARAPPD_APPL_NO    = p_appl_no;
                Exception
                when others then
                vl_msje:='Error al obtener la max solicitud'||sqlerrm;
                END;

                BEGIN
                    INSERT INTO SARAPPD VALUES(p_pidm, p_term_code_entry, p_appl_no, max_seq_no, sysdate, '45','U', sysdate, p_usuario,'SIU', null, null,null,null);
                Exception
                when others then
                vl_msje:='Error al insertar en SARAPPD'||sqlerrm;
                END;

            END;

        END IF;
        commit;
        Return vl_msje;
        Exception
        when others then
        vl_msje:='Error_general'||sqlerrm;
        Rollback;
        Return vl_msje;
    END;

    FUNCTION f_cancela_sol_dec40(p_pidm in number, p_term_code_entry in Varchar2, p_appl_no in number )Return Varchar2
    is

    vl_msje Varchar2(250):= 'Exito';

    BEGIN

          IF  p_pidm IS NULL OR p_term_code_entry IS NULL THEN
                 vl_msje:='Parametro nulo';
          ELSE

            begin
             for c in (select SARAPPD_PIDM, SARAPPD_APDC_CODE, SARAPPD_APPL_NO
               from saradap, sarappd
               where SARAPPD_PIDM= SARADAP_PIDM
               and SARAPPD_APPL_NO = SARADAP_APPL_NO
               and SARAPPD_TERM_CODE_ENTRY= SARADAP_TERM_CODE_ENTRY
               and saradap_pidm = p_pidm
               and saradap_term_code_entry= p_term_code_entry
               and SARAPPD_APDC_CODE=  '40'
               )

               loop
                   update saradap
                        set saradap_apst_code = 'X'
                   where saradap_pidm = c.SARAPPD_PIDM
                   and SARADAP_TERM_CODE_ENTRY = p_term_code_entry
                   and SARADAP_APPL_NO = c.SARAPPD_APPL_NO;

               end loop;
              Exception
            When Others then
               vl_msje := 'Se presento el error al cancelar la solicitud anterior '||sqlerrm;
            end;
          END IF;
          If vl_msje = 'Exito' then
          commit;
          Else
              Rollback;
           End if;
          return vl_msje;
    Exception when others then
    vl_msje := 'Error al actualizar SARADAP_APST_CODE'||' '||sqlerrm;
    rollback;
    Return vl_msje;
     END;


--Función generada para insertar alumnos INBEC en GORADID  desde persona general--

     FUNCTION insrt_goradid_inbec(p_pidm in number default null) Return Varchar2
        is
            vl_msje Varchar2(250):='Exito al insertar GORADID';

        BEGIN

        IF p_pidm is null  then

            vl_msje:='Parametro nulo';

        ELSE
         begin
            insert into GORADID values(p_pidm, 'Alumno de IMBEC', 'INBE', user, sysdate, 'SistemaV2',null, 0,null);
         Exception
         When others then
         vl_msje:='Error al insertar GORADID'||sqlerrm;
         end;
        END IF;
        commit;
        Return vl_msje;
        Exception
        When others then
        vl_msje:='Error general'||sqlerrm;
        Rollback;
        END;

FUNCTION F_UPDATE_SPREMRG (p_pidm in number, p_last_name in varchar2, p_firts_name in varchar2, p_mi in varchar2, p_street1 in varchar2, p_street2 in varchar2, p_street3 in varchar2,  p_city in varchar2, p_stat_code in varchar2, p_zip in varchar2 , p_rg_fs in varchar2, p_cfdi in varchar2, p_street4 in varchar2) Return Varchar2


    IS
         vl_msje Varchar2(250):='Exito al insertar SPREMRG';

    BEGIN

        UPDATE SPREMRG  G
                    SET SPREMRG_LAST_NAME       = NVL(p_last_name,G.SPREMRG_LAST_NAME ),
                    SPREMRG_FIRST_NAME          = NVL(p_firts_name,'.'),
                    SPREMRG_MI                  = NVL(p_mi,G.SPREMRG_MI),
                    SPREMRG_STREET_LINE1        = NVL(p_street1,G.SPREMRG_STREET_LINE1),
                    SPREMRG_STREET_LINE2        = NVL(p_street2,G.SPREMRG_STREET_LINE2),
                    SPREMRG_STREET_LINE3        = NVL(p_street3,G.SPREMRG_STREET_LINE3),
                    SPREMRG_STREET_LINE4        = NVL(p_street4,G.SPREMRG_STREET_LINE3),
                    SPREMRG_CITY                = NVL(p_city,G.SPREMRG_CITY),
                    SPREMRG_STAT_CODE           = NVL(p_stat_code,G.SPREMRG_STAT_CODE),
                    SPREMRG_ZIP                 = NVL(p_zip,G.SPREMRG_ZIP),
                    SPREMRG_ACTIVITY_DATE       = sysdate,
                    SPREMRG_DATA_ORIGIN         ='SIU_FACT',
                    SPREMRG_USER_ID             = USER,
                    SPREMRG_RG_FS               = p_rg_fs,
                    SPREMRG_CFDI                = p_cfdi
                    WHERE SPREMRG_PIDM  = p_pidm
                      AND spremrg_relt_code = 'I'
                      AND spremrg_priority = ( SELECT MAX(S.spremrg_priority) FROM spremrg S WHERE  S.spremrg_pidm = p_pidm  ) ;

    commit;
    Return vl_msje;
exception
when others then
vl_msje:= 'Error al actualizar SPREMRG' || sqlerrm;
END;

FUNCTION f_insert_pass(p_pidm in number, p_id in varchar2, p_pass in varchar2) return varchar2 -- V1 FER 09/03/2023
IS

vl_msje varchar2 (250):='Exito';
vl_contar number := 3;

 BEGIN

      IF  p_pass IS NULL THEN
            vl_msje:='Parametro de contrasenia nulo';

            vl_contar := NULL;
      ELSE

            BEGIN

                SELECT COUNT (gztpass_pidm) VL_CONTAR
                INTO vl_contar
                FROM gztpass
                WHERE 1=1
                AND gztpass_pidm = p_pidm;

--                DBMS_OUTPUT.PUT_LINE (vl_contar);
                EXCEPTION WHEN OTHERS THEN
                vl_msje:='Error 1'||SQLERRM;

            end;

                    if vl_contar >= 1 then


                        begin

                        UPDATE gztpass
                        SET gztpass_pin = p_pass,
                        gztpass_date_update = sysdate,
                        GZTPASS_STATUS = '0' 
                        WHERE 1=1
                        AND gztpass_pidm = p_pidm;

                        UPDATE goztpac
                        SET goztpac_pin = sha1(p_pass),
                            GOZTPAC_STAT_IND = '1'
                        WHERE 1=1
                        AND goztpac_pidm = p_pidm;

                        EXCEPTION WHEN OTHERS THEN
                        vl_msje:='Error2'||sqlerrm;
                        end;

                    END IF ;

                    COMMIT;

                          IF  vl_contar = 0 THEN

                               BEGIN
                                 INSERT INTO gztpass VALUES (p_pidm, p_id, p_pass,'0', user, sysdate,null, null);
                                 INSERT INTO goztpac VALUES (p_pidm, p_id,sha1(p_pass),'N', 'N','1');

                               EXCEPTION WHEN OTHERS THEN
                               vl_msje:='Error3'||sqlerrm;
                               END;

                          END IF;

                         COMMIT;
      END IF;

      RETURN vl_contar;

 END f_insert_pass;

--vl_msje varchar2 (250):='Exito';
--
--    BEGIN
--
--      if  p_pass is null then
--            vl_msje:='Parametro de contrasenia nulo';
--      else
--           begin
--             insert into GZTPASS values (p_pidm, p_id, p_pass,'0', user, sysdate,null, null);
--             insert into GOZTPAC values (p_pidm, p_id,sha1(p_pass),'N', 'N','1');
--           exception when others then
--           vl_msje:='Error'||sqlerrm;
--           end;
--        end if;
--
--    commit;
--    return vl_msje;
--    END f_insert_pass;
--
-- Ejecutado como Juan Jesús Corona Mirdanda 15102019

FUNCTION selct_goradid_curp(p_pidm in number) Return Varchar2
        is
            vl_msje Varchar2(250);
            vcurp   Varchar2(18);

        BEGIN
          select distinct GORADID_ADDITIONAL_ID
            INTO vcurp
            from GORADID
            where GORADID_ADID_CODE = 'CURP'
            and GORADID_PIDM = p_pidm;

        Return vcurp;
        Exception
        When others then
        vcurp:='NO CURP';
        --NULL;
        Return vcurp;

        END selct_goradid_curp;

FUNCTION updte_goradid_curp(p_pidm in number, p_curp IN varchar2 ) Return Varchar2
        is
            vl_msje Varchar2(250):='CURP Insertado con Exito' ;
           -- vcurp   Varchar2(18);

        BEGIN
          UPDATE  GORADID
            SET  GORADID_ADDITIONAL_ID = p_curp
            where GORADID_ADID_CODE = 'CURP'
            and GORADID_PIDM = p_pidm;

        Return vl_msje;

        Exception
        When others then
        vl_msje:='NO CURP';

        END updte_goradid_curp;
  FUNCTION insert_goradid_curp(p_pidm in number, p_curp IN varchar2 ) Return Varchar2
        is
            vl_msje Varchar2(250):='CURP Insertado con Exito' ;
           -- vcurp   Varchar2(18);

      BEGIN
          insert into goradid(GORADID_PIDM,
                            GORADID_ADDITIONAL_ID,
                            GORADID_ADID_CODE,
                            GORADID_USER_ID,
                            GORADID_ACTIVITY_DATE,
                            GORADID_DATA_ORIGIN,
                            GORADID_SURROGATE_ID,
                            GORADID_VERSION)
                            --GORADID_VPDI_CODE,
          values ( p_pidm, p_curp,'CURP', 'SIU_FACTURA', SYSDATE, 'SIU',0,0 );

          vl_msje :='CURP Insertado con Exito' ;
          COMMIT;

        Return vl_msje;

      Exception
        When others then
        vl_msje:=SQLERRM;

        Return vl_msje;

        END insert_goradid_curp;

FUNCTION updte_SPREMRG_RELT_CODE(p_pidm in number, p_prioridad in number) Return Varchar2
        is
            vl_msje Varchar2(250):='SPREMRG_RELT_CODE Insertado con Exito' ;
           -- vcurp   Varchar2(18);

        BEGIN

            delete SPREMRG
            where 1= 1
            And SPREMRG_PIDM = p_pidm
            And  SPREMRG_PRIORITY = p_prioridad;


        Return (vl_msje);

        Exception
        When others then
        vl_msje:='NO FACTURA';

        END updte_SPREMRG_RELT_CODE;
--
-- FER 0/08/2019
     FUNCTION insrt_goradid_empresarial (p_pidm in number default null) Return Varchar2
        is
            vl_msjes Varchar2(250):='Exito al insertar GORADID';

        BEGIN

        IF p_pidm is null  then

            vl_msjes:='Parametro nulo';

        ELSE
         begin
            insert into GORADID values(p_pidm, 'Alumno de Empresarial', 'UTLE', user, sysdate, 'SistemaV2',null, 0,null);
         Exception
         When others then
         vl_msjes:='Error al insertar GORADID'||sqlerrm;
         end;
        END IF;
        commit;
        Return vl_msjes;
        Exception
        When others then
        vl_msjes:='Error general'||sqlerrm;
        Rollback;
        END;

--
--
FUNCTION insrt_goradid_convertia (p_pidm in number default null) Return Varchar2  --FER 19/08/2019
        is
            vl_msjes Varchar2(250):='Exito al insertar GORADID';

        BEGIN

        IF p_pidm is null  then

            vl_msjes:='Parametro nulo';

        ELSE
         begin
            insert into GORADID values(p_pidm, 'ALUMNO DE CONVERTIA', 'CONV', user, sysdate, 'SistemaV2',null, 0,null);
         Exception
         When others then
         vl_msjes:='Error al insertar GORADID'||sqlerrm;
         end;
        END IF;
        commit;
        Return vl_msjes;
        Exception
        When others then
        vl_msjes:='Error general'||sqlerrm;
        Rollback;
        END;


     FUNCTION inserta_etiqueta(p_pidm in number, p_adid_code in varchar2, p_adid_id in varchar2) Return Varchar2
        is
            vl_msje Varchar2(250):='Exito al insertar Etiqueta';
            vl_existe number :=0;

        BEGIN

        IF p_pidm is null  then

            vl_msje:='Parametro nulo';

        ELSE

                Begin
                        Select count(1)
                            Into vl_existe
                            from GORADID
                        Where GORADID_PIDM = p_pidm
                        And GORADID_ADID_CODE  = p_adid_code;
                 Exception
                    When Others then
                        vl_existe :=0;
                End;

                If vl_existe =0 then

                         begin
                            insert into GORADID values(p_pidm, p_adid_id, p_adid_code, user, sysdate, 'SistemaV2',null, 0,null);
                         Exception
                         When others then
                         vl_msje:='Error al insertar Etiqueta'||sqlerrm;
                         end;
                  End if;
        END IF;
        commit;
        Return vl_msje;
        Exception
        When others then
        vl_msje:='Error general'||sqlerrm;
        Rollback;
        END;

FUNCTION insrt_goradid_izzi (p_pidm IN NUMBER DEFAULT NULL) RETURN VARCHAR2  --FER 13/01/2020
        is
            vl_msjes VARCHAR2(250):='EXITO AL INSERTAR GORADID';

        BEGIN

        IF p_pidm IS NULL  THEN

            vl_msjes:='PARAMETRO NULO';

        ELSE

         BEGIN
            insert into GORADID values(p_pidm, 'ALUMNO IZZI', 'IZZI', user, sysdate, 'SistemaV2',null, 0,null);

         EXCEPTION
         WHEN OTHERS THEN
         vl_msjes:='Error al insertar GORADID'||SQLERRM;

         END;

        END IF;

        COMMIT;

        Return vl_msjes;
        Exception
        When others then
        vl_msjes:='Error general'||sqlerrm;
        Rollback;

        END;

    FUNCTION inserta_etiqueta_fecha(p_pidm in number, p_adid_code in varchar2, p_adid_id in varchar2, f_fecha in date) Return Varchar2
        is
            vl_msje Varchar2(250):='Exito al insertar Etiqueta';
            vl_existe number :=0;

        BEGIN

        IF p_pidm is null  then

            vl_msje:='Parametro nulo';

        ELSE

                Begin
                        Select count(1)
                            Into vl_existe
                            from GORADID
                        Where GORADID_PIDM = p_pidm
                        And GORADID_ADID_CODE  = p_adid_code;
                 Exception
                    When Others then
                        vl_existe :=0;
                End;

                If vl_existe =0 then

                         begin
                            insert into GORADID values(p_pidm, p_adid_id, p_adid_code, user, trunc (f_fecha), 'SistemaV2',null, 0,null);
                         Exception
                         When others then
                         vl_msje:='Error al insertar Etiqueta'||sqlerrm;
                         end;
                  End if;
        END IF;
        commit;
        Return vl_msje;
        Exception
        When others then
        vl_msje:='Error general'||sqlerrm;
        Rollback;
        END inserta_etiqueta_fecha;
        

FUNCTION sp_insert_coes(pidm in  number, cuenta varchar2, adid_code varchar2, user_id varchar2, data_origin varchar2, periodo varchar2, appl_no in number ) return varchar2 is

-- appl_no number;
mensaje varchar2(200);

begin
-- select nvl(max(saradap_appl_no),1) into appl_no from saradap
--  where saradap_pidm=pidm;
        begin
            insert into saracmt values(pidm, periodo, appl_no, (select nvl(max(saracmt_seqno),0) +1 from saracmt where saracmt_pidm=pidm and saracmt_appl_no = appl_no), cuenta, adid_code, sysdate, null,null, user_id, data_origin, null);
            commit;
            mensaje:='Operación exitosa';
            exception when others then
            mensaje:=sqlerrm;
        end;
        return mensaje;
end;


END pkg_Resa;
/

DROP PUBLIC SYNONYM PKG_RESA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_RESA FOR BANINST1.PKG_RESA;


GRANT EXECUTE ON BANINST1.PKG_RESA TO CONSULTA;
