DROP PACKAGE BODY BANINST1.PKG_NIVELACION_GRUPOS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_NIVELACION_GRUPOS  AS
 ------nueva version para la generacion de extraordinarios masivos por grupos----
 -----glovicx  28/02/2019----
 -----



Function f_ptrm ( ffecha  date) return varchar2  is

lv_nivel      varchar2(80);

begin
null;



return(lv_nivel);
EXCEPTION WHEN OTHERS THEN 
--dbms_output.put_line('no esta en rango' || sqlerrm);
   return('NA');


END f_ptrm;


FUNCTION F_MATERIAS_FORMA(PMATERIA VARCHAR2) RETURN VARCHAR2 IS

crn           number;
lv_nivel      varchar2(80);

BEGIN
  -- message( 'funcion  '|| lv_code);
   select distinct SSBSECT_CRSE_TITLE
     INTO lv_nivel
      from  ssbsect b
        where 1=1
        and SSBSECT_CRSE_TITLE  is not null
        and  B.SSBSECT_SUBJ_CODE||B.SSBSECT_CRSE_NUMB =PMATERIA;
    
    
  return(lv_nivel);
EXCEPTION WHEN OTHERS THEN 
--dbms_output.put_line('  error en materia' || sqlerrm);
   return('NA');


END F_MATERIAS_FORMA;

FUNCTION F_DOCENTE_FORMA(PDOCENTE VARCHAR2) RETURN VARCHAR2 IS


lv_nivel      varchar2(80);
BEGIN
  -- message( 'funcion  '|| lv_code);
   select  SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME
     INTO lv_nivel
        from  SIBINST b, spriden p
          where SIBINST_PIDM  = spriden_pidm
                and  SPRIDEN_LAST_NAME  is not null
                and SIBINST_FCST_CODE  = 'AC'
                and SIBINST_SCHD_IND = 'Y'
                and SPRIDEN_CHANGE_IND is null
                AND  spriden_pidm  =  fget_pidm( PDOCENTE) ;
               
    
  return(lv_nivel);
EXCEPTION WHEN OTHERS THEN 

   return('NA');
--dbms_output.put_line('  error en profesor' || sqlerrm);
END F_DOCENTE_FORMA;

FUNCTION F_materia_legal(pmatehija VARCHAR2, pnivel varchar2 ) RETURN VARCHAR2 IS


lv_mlegal      varchar2(80);
BEGIN
  -- message( 'funcion  '|| lv_code);
   select SZTMACO_MATPADRE  mate_legal   
   INTO lv_mlegal
        from  SZTMACO
           where  SZTMACO_MATHIJO  =  pmatehija 
             and   SZTMACO_LEVL_CODE  =  pnivel ;
               
    
  return(lv_mlegal);
EXCEPTION WHEN OTHERS THEN 

   return('NA');
--dbms_output.put_line('  error en Materia legal' || sqlerrm);
END F_materia_legal;

procedure p_crea_masivo_horario(p_semanas number, pcupo number, pperiodo  varchar2, ppcampus varchar2, ppnivel varchar2 ) is

vl_existe     number:=0; 
period_cur    varchar2(20);
parteper_cur  varchar2(5);
vmate_padre    varchar2(20);
vl_secuencia    number;
crn           number:=0;
ptrm_code    varchar2(5);
vfecha_ini   date;
vfecha_fin    date;
vsubj         varchar2(5);
vcrse         varchar2(5);
vtitle        varchar2(100);
vcredits     varchar2(10);
vbills       varchar2(20);
gmod        VARCHAR2(2);
vschd       varchar2(10);
vdata_orig   varchar2(12);
crn2         VARCHAR2(5);
vlevel_hijo     varchar2(12);
vsqlerrm     VARCHAR2(2000);
VPERIODOMS    VARCHAR2(12);


cursor c_materias is
select SZTNIVE_CAMPUS as campus,SZTNIVE_NIVEL as nivel,SZTNIVE_MATERIA as materia,SZTNIVE_DOCENTE as docente,SZTNIVE_VALIDA as valida
from sztnive z
where z.SZTNIVE_VALIDA = 1
and   Z.SZTNIVE_CAMPUS  = ppcampus
and   Z.SZTNIVE_NIVEL   = ppnivel
--AND   Z.SZTNIVE_GENERADOR   IS NULL
---and rownum < 3
order by SZTNIVE_NIVEL,SZTNIVE_MATERIA
;


begin
null;



FOR  c in c_materias  loop

FOR  jump in  1..p_semanas   loop


--------nueva versio segun vic para todos los niveles li, ma entra alreves en maco entra por el padre y recupera los hijos en un for ---glovicx 13/11/2018


-----------------aqui va looop de maco ---

  for x in (  select SZTMACO_MATHIJO mate_hijo   
                    from  SZTMACO
                       where  SZTMACO_MATPADRE =  c.materia 
                         and   SZTMACO_LEVL_CODE  =  c.nivel ) loop
                         
                         

vsubj       := '';
vcrse       := ''; 
vtitle      := '';
vcredits    := '';
vbills      := '';
vschd       := '';
ptrm_code   := '';
vfecha_ini  := '';
vfecha_fin  := '';
vdata_orig  := '';
crn         := '';
ptrm_code   := '';
vlevel_hijo := '';
vsubj       := '';
vcrse       := ''; 
vtitle      := '';
vcredits    := '';
vbills      := '';
vschd       := '';
ptrm_code   := '';
vfecha_ini  := '';
vfecha_fin  := '';
vdata_orig  := '';
crn         := '';
ptrm_code   := '';
vlevel_hijo := '';
                         
            -----------------saco el nivel--por que el nivel que viene desde el parametro no srve para master----------------
            begin
                    select distinct  SCRLEVL_LEVL_CODE  --,SCRLEVL_SUBJ_CODE, SCRLEVL_CRSE_NUMB
                    INTO  vlevel_hijo  -- , vsubj, vcrse
                    from SCRLEVL
                     where trim(SCRLEVL_SUBJ_CODE)||trim(SCRLEVL_CRSE_NUMB)  in trim(x.mate_hijo)
                    ;

             exception when others then 
                        --dbms_output.put_line('NO se encontro NIVEL la materia hija en  SCRLEVL::   '||x.mate_hijo||' /-/ ' ||pperiodo||'--'|| crn||'-'||ptrm_code );
                 begin
                  select SCRLEVL_LEVL_CODE,SCRLEVL_SUBJ_CODE, SCRLEVL_CRSE_NUMB
                    INTO  vlevel_hijo , vsubj, vcrse
                    from SCRLEVL
                     where SCRLEVL_SUBJ_CODE = substr (trim(x.mate_hijo),1,4)
                     and SCRLEVL_CRSE_NUMB   =  substr (trim(x.mate_hijo),5,9);
                   
                  exception when others then   
                 vlevel_hijo :=  null;  --  c.nivel;
                     --dbms_output.put_line('NO se encontro NIVEL la materia hija en  SCRLEVL:2:   '||x.mate_hijo||' /-/ ' ||pperiodo||'--'|| crn||'-'||ptrm_code );
                 end;
             end;  
  
  

case 
when c.nivel = 'LI'then   
vdata_orig  := 'SZFHOMNLI';
when c.nivel = 'MA'then
vdata_orig  := 'SZFHOMNMA';
when c.nivel = 'MS'then
vdata_orig  := 'SZFHOMNMS';
end case;

   --DBMS_OUTPUT.PUT_LINE('00.- VALIDA NIVEL DEL HIJO :   ' || x.mate_hijo||' <-> '||vlevel_hijo  ) ;
                        
    IF vlevel_hijo != 'MS'  then          
         
         vsubj :=  substr (trim(x.mate_hijo),1,4);
         vcrse :=  substr (trim(x.mate_hijo),5,5);
         
         
                  --////---------------valida que no exista ya el CRN  creado------  aqui entra para MAESTRIA Y LICENCIATURA 
                    ---------valida que la parte de periodo este capturada para poder crear el curso----
                       begin 
                         
                          --DBMS_OUTPUT.PUT_LINE('1.- MANDA MATERIA HIJO A MA/LI::   ' || vsubj||'/'||vcrse||'<->'||vlevel_hijo  ) ;
                         SELECT DISTINCT count(1) ,SO.SOBPTRM_PTRM_CODE codigo, so.SOBPTRM_START_DATE, so.SOBPTRM_END_DATE ---, SO.SOBPTRM_TERM_CODE, so.SOBPTRM_DESC
                                INTO  vl_existe,   ptrm_code, vfecha_ini, vfecha_fin
                                    FROM stvterm, sobptrm  SO ---, spriden
                                   WHERE     SUBSTR (so.SOBPTRM_TERM_CODE, 5, 1) = '8'
                                         AND LENGTH (so.SOBPTRM_PTRM_CODE) = 3
                                         AND sobptrm_term_code = stvterm_code
                                         and substr(SO.SOBPTRM_PTRM_CODE,1,1) =  DECODE(c.nivel,'LI' , 'L','MA','M', 'MS','N')              ----esto es para licenciatura
                                         and  SO.SOBPTRM_TERM_CODE  =  pperiodo
                                         and  so.SOBPTRM_PTRM_CODE  =  (  select min(SOBPTRM_PTRM_CODE ) from sobptrm  SO1  
                                                                                            where  SUBSTR (so1.SOBPTRM_TERM_CODE, 5, 1) = '8'
                                                                                                AND LENGTH (so1.SOBPTRM_PTRM_CODE) = 3
                                                                                                and substr(SO1.SOBPTRM_PTRM_CODE,1,1) = DECODE(c.nivel,'LI' , 'L','MA','M', 'MS','N')    ----esto es para licenciatura
                                                                                                and SO1.SOBPTRM_TERM_CODE  = SO.SOBPTRM_TERM_CODE 
                                                                                                and not exists   ( select  bb1.SSBSECT_TERM_CODE,bb1.SSBSECT_PTRM_CODE
                                                                                                       from ssbsect bb1  where
                                                                                                        bb1.SSBSECT_TERM_CODE = SO1.SOBPTRM_TERM_CODE
                                                                                                        AND bb1.SSBSECT_PTRM_CODE = SO1.SOBPTRM_PTRM_CODE
                                                                                                        AND bb1.SSBSECT_SUBJ_CODE||bb1.SSBSECT_CRSE_NUMB = x.mate_hijo )--c.materia
                                                                                            
                                                                                            )
                                         
                        group by SO.SOBPTRM_PTRM_CODE , so.SOBPTRM_START_DATE, so.SOBPTRM_END_DATE ;        
                         Exception
                        When Others then 
                          vl_existe  := 0;
                          ptrm_code := null;
                          vfecha_ini := null;
                           --dbms_output.put_line('Error al recuperar datos de grupo PTRM  '||sqlerrm);
                       End;   
                        
                      --  dbms_output.put_line('Paso 1.1.1 despus de validar ssbsect1  '|| vl_existe  );
                        
                
                  
                begin  
                  select distinct count(1)  --, B3.SSBSECT_PTRM_CODE ptrm_code, B3.SSBSECT_PTRM_START_DATE f_ini, B3.SSBSECT_PTRM_END_DATE f_fin
                    INTO  vl_existe   ---,   ptrm_code, vfecha_ini, vfecha_fin
                      from ssbsect b3
                        where b3.SSBSECT_TERM_CODE= pperiodo
                          and b3.ssbsect_subj_code||b3.ssbsect_crse_numb = x.mate_hijo ---c.materia
                            and B3.SSBSECT_PTRM_CODE  = ptrm_code
                         group by B3.SSBSECT_PTRM_CODE, B3.SSBSECT_PTRM_START_DATE , B3.SSBSECT_PTRM_END_DATE  ;
                 Exception  when others then
                     vl_existe  := 0;
                      --dbms_output.put_line('Error al recuperar grupo ESTA BIEN:: '||sqlerrm);
                end;

             --dbms_output.put_line('Paso 2 despues de valida ssbsect:.. '|| vl_existe ||'-'|| pperiodo|| '--'|| x.mate_hijo||'-'||ptrm_code||'-'||vfecha_ini  );
                

             If vl_existe = 0 then 
              --dbms_output.put_line('Paso 3 dentro existe  ');
                
                                   -------------AQUI se crea el nuevo CRN--- para el grupo-------
                            Begin 
                                select nvl(max(ssbsect_crn),1000)+1 
                                     into crn 
                                from ssbsect where ssbsect_term_code= pperiodo;
                              Exception
                                 When Others then 
                                   crn := null;
                                  
                             End;                       
                           --dbms_output.put_line('Paso 4 despues de crear el CRN  '|| crn  );
              
                                        
                  ----------------------recupero la materia semapara-----
                       begin
                          select   SCBCRSE_TITLE, SCBCRSE_CREDIT_HR_LOW, SCBCRSE_BILL_HR_LOW, SCRSCHD_SCHD_CODE
                             INTO  vtitle, vcredits, vbills,vschd
                         from SCBCRSE ce, SCRSCHD hd
                         where SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB = hd.SCRSCHD_SUBJ_CODE||SCRSCHD_CRSE_NUMB
                          and SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB = c.materia ;----AQUI LE PUSE LA MATERIA PADRE POR QUE SOLO BUSCO DATOS GENERALES ESTA BIEN

                         Exception
                        When Others then 
                          vsubj := NULL; --ptrm_code := null;
                          vsqlerrm := 'No esta la materia hija en SCBCRSE::  ' ;
                          raise_application_error (-20002,vsqlerrm|| x.mate_hijo||'  <---> '|| sqlerrm);
                        --dbms_output.put_line('Error al recuperar datos de grupo EXTRAS  '||sqlerrm);
                       end;
                       
                       
                       --  dbms_output.put_line('Paso 6 despus de validar ssbsect2  ');   
                        begin
                            select scrgmod_gmod_code
                                  into gmod
                            from scrgmod
                              where scrgmod_subj_code||scrgmod_crse_numb  =  x.mate_hijo
                                and     scrgmod_default_ind='D';
                        exception when others then
                            gmod:='1';
                        end;          
                        
        --                  begin
        --               
        --                    select SCRLEVL_LEVL_CODE,SCRLEVL_SUBJ_CODE, SCRLEVL_CRSE_NUMB
        --                    INTO  vlevel_hijo , vsubj, vcrse
        --                    from SCRLEVL
        --                     where SCRLEVL_SUBJ_CODE||SCRLEVL_CRSE_NUMB  = x.mate_hijo --  'M1ME101-'  --esta es la materia hija
        --                    ;
        --
        --                   exception when others then 
        --                        dbms_output.put_line('NO se encontro NIVEL la materia hija en  SCRLEVL::   ' ||pperiodo||'--'|| crn||'-'||ptrm_code );
        --
        --                     end;  
        --                        
             ----------------------inserta el nuevo grupo CRN
              Begin
              
                IF crn IS NOT NULL AND  ptrm_code IS NOT NULL  THEN 
                        --DBMS_OUTPUT.PUT_LINE('2.- ENTRA 1RA PARTE MA Y LI '||x.mate_hijo||'<-->' ||ptrm_code||'<->'||crn )  ;        
                 Insert into ssbsect values (
                                       pperiodo,     --SSBSECT_TERM_CODE
                                       crn,     --SSBSECT_CRN
                                       ptrm_code  ,     --SSBSECT_PTRM_CODE
                                       vsubj,     --SSBSECT_SUBJ_CODE
                                       vcrse,     --SSBSECT_CRSE_NUMB
                                       '01',   --para este siempre va ser grupo 01  --SSBSECT_SEQ_NUMB
                                       'A',    --SSBSECT_SSTS_CODE
                                       vschd,    --SSBSECT_SCHD_CODE
                                       c.campus,    --SSBSECT_CAMP_CODE
                                       vtitle,   --SSBSECT_CRSE_TITLE
                                       vcredits,   --SSBSECT_CREDIT_HRS
                                       vbills,   --SSBSECT_BILL_HRS
                                       gmod,   --SSBSECT_GMOD_CODE
                                       null,  --SSBSECT_SAPR_CODE
                                       null, --SSBSECT_SESS_CODE
                                       null,  --SSBSECT_LINK_IDENT
                                       null,  --SSBSECT_PRNT_IND
                                       'Y',  --SSBSECT_GRADABLE_IND
                                       null,  --SSBSECT_TUIW_IND
                                       0, --SSBSECT_REG_ONEUP
                                       0, --SSBSECT_PRIOR_ENRL
                                       0, --SSBSECT_PROJ_ENRL
                                       pcupo, --SSBSECT_MAX_ENRL
                                       0,--SSBSECT_ENRL
                                        pcupo,--SSBSECT_SEATS_AVAIL
                                       null,--SSBSECT_TOT_CREDIT_HRS
                                       '0',--SSBSECT_CENSUS_ENRL
                                       vfecha_ini,--SSBSECT_CENSUS_ENRL_DATE
                                       sysdate,--SSBSECT_ACTIVITY_DATE
                                       vfecha_ini,--SSBSECT_PTRM_START_DATE
                                       vfecha_fin,--SSBSECT_PTRM_END_DATE
                                       p_semanas,--SSBSECT_PTRM_WEEKS
                                       null,--SSBSECT_RESERVED_IND
                                       null, --SSBSECT_WAIT_CAPACITY
                                       null,--SSBSECT_WAIT_COUNT
                                       null,--SSBSECT_WAIT_AVAIL
                                       null,--SSBSECT_LEC_HR
                                       null,--SSBSECT_LAB_HR
                                       null,--SSBSECT_OTH_HR
                                       null,--SSBSECT_CONT_HR
                                       null,--SSBSECT_ACCT_CODE
                                       null,--SSBSECT_ACCL_CODE
                                       null,--SSBSECT_CENSUS_2_DATE
                                       null,--SSBSECT_ENRL_CUT_OFF_DATE
                                       null,--SSBSECT_ACAD_CUT_OFF_DATE
                                       null,--SSBSECT_DROP_CUT_OFF_DATE
                                       null,--SSBSECT_CENSUS_2_ENRL
                                       'Y',--SSBSECT_VOICE_AVAIL
                                       'N',--SSBSECT_CAPP_PREREQ_TEST_IND
                                       null,--SSBSECT_GSCH_NAME
                                       null,--SSBSECT_BEST_OF_COMP
                                       null,--SSBSECT_SUBSET_OF_COMP
                                       'NOP',--SSBSECT_INSM_CODE
                                       null,--SSBSECT_REG_FROM_DATE
                                       null,--SSBSECT_REG_TO_DATE
                                       null,--SSBSECT_LEARNER_REGSTART_FDATE
                                       null,--SSBSECT_LEARNER_REGSTART_TDATE
                                       null,--SSBSECT_DUNT_CODE
                                       null,--SSBSECT_NUMBER_OF_UNITS
                                       0,--SSBSECT_NUMBER_OF_EXTENSIONS
                                       vdata_orig,--SSBSECT_DATA_ORIGIN
                                       user,--SSBSECT_USER_ID
                                       'MOOD',--SSBSECT_INTG_CDE
                                       'B',--SSBSECT_PREREQ_CHK_METHOD_CDE
                                       user,--SSBSECT_KEYWORD_INDEX_ID
                                       null,--SSBSECT_SCORE_OPEN_DATE
                                       null,--SSBSECT_SCORE_CUTOFF_DATE
                                       null,--SSBSECT_REAS_SCORE_OPEN_DATE
                                       null,--SSBSECT_REAS_SCORE_CTOF_DATE
                                       null,--SSBSECT_SURROGATE_ID
                                       null,--SSBSECT_VERSION
                                       null);--SSBSECT_VPDI_CODE    
                     commit;
                                
                           Begin 
                                insert into sirasgn values(
                                            PPERIODO ,
                                            crn, 
                                            fget_pidm(c.docente), 
                                            '01', 
                                            100, 
                                            null, 
                                            100,'Y', null, null,  
                                            sysdate, null,null,null,null, vdata_orig, USER, null, null, null, null,  null,null);
                                            
                           --dbms_output.put_line('3.- SE ha insertado el profesor LI O MA> ' ||(jump) ||'--'||pperiodo||'--'|| crn||'-'|| c.docente );
                    Exception
                     When Others then 
                        null;
                         --dbms_output.put_line('Error al INSERTAR NUEVO PROFE '||sqlerrm);
                                End;
                                 UPDATE SZTNIVE Z
                                  SET Z.SZTNIVE_GENERADOR    = 1
                                  WHERE  Z.SZTNIVE_CAMPUS      = PPCAMPUS
                                       AND     Z.SZTNIVE_NIVEL    = c.nivel
                                       AND     Z.SZTNIVE_MATERIA  = x.mate_hijo
                                       AND     Z.SZTNIVE_DOCENTE  =  c.docente
                                       AND     Z.SZTNIVE_VALIDA   = 1  ;
                        
                 end if;
           
             End;
         end if;
                     
         
   ELSIF  vlevel_hijo = 'MS'  then ---si es materia hija de nivel MASTER..  SI SE INSERTA
   
          
          vsubj :=  substr (trim(x.mate_hijo),1,4);
         vcrse :=  substr (trim(x.mate_hijo),5,5);
         
       -------CONVIERTE EL PERIODO  A MASTER---
       VPERIODOMS  := '02'||SUBSTR(pperiodo,3,8);
   
        --DBMS_OUTPUT.PUT_LINE('4.- INICIA MATERIA HIJO MS:   ' ||vsubj||'/'|| vcrse ||'<->'||ptrm_code|| '<-->'||vlevel_hijo   ) ;
            
            begin 
                 
                  
                 SELECT DISTINCT count(1) ,SO.SOBPTRM_PTRM_CODE codigo, so.SOBPTRM_START_DATE, so.SOBPTRM_END_DATE ---, SO.SOBPTRM_TERM_CODE, so.SOBPTRM_DESC
                        INTO  vl_existe,   ptrm_code, vfecha_ini, vfecha_fin
                            FROM stvterm, sobptrm  SO ---, spriden
                           WHERE     SUBSTR (so.SOBPTRM_TERM_CODE, 5, 1) = '8'
                                 AND LENGTH (so.SOBPTRM_PTRM_CODE) = 3
                                 AND sobptrm_term_code = stvterm_code
                                 and substr(SO.SOBPTRM_PTRM_CODE,1,1) =  'N' --DECODE(vlevel_hijo,'LI' , 'L','MA','M', 'MS','N')              ----esto es para licenciatura
                                 and  SO.SOBPTRM_TERM_CODE  =  VPERIODOMS
                                 and  so.SOBPTRM_PTRM_CODE  =  (  select min(SOBPTRM_PTRM_CODE ) from sobptrm  SO1  
                                                                                    where  SUBSTR (so1.SOBPTRM_TERM_CODE, 5, 1) = '8'
                                                                                        AND LENGTH (so1.SOBPTRM_PTRM_CODE) = 3
                                                                                        and substr(SO1.SOBPTRM_PTRM_CODE,1,1) = 'N' -- DECODE(vlevel_hijo,'LI' , 'L','MA','M', 'MS','N')    ----esto es para licenciatura
                                                                                        and SO1.SOBPTRM_TERM_CODE  = SO.SOBPTRM_TERM_CODE 
                                                                                        and not exists   ( select  bb1.SSBSECT_TERM_CODE,bb1.SSBSECT_PTRM_CODE
                                                                                               from ssbsect bb1  where
                                                                                                bb1.SSBSECT_TERM_CODE = SO1.SOBPTRM_TERM_CODE
                                                                                                AND bb1.SSBSECT_PTRM_CODE = SO1.SOBPTRM_PTRM_CODE
                                                                                                AND bb1.SSBSECT_SUBJ_CODE||bb1.SSBSECT_CRSE_NUMB = x.mate_hijo )--c.materia
                                                                             )
                                 
                group by SO.SOBPTRM_PTRM_CODE , so.SOBPTRM_START_DATE, so.SOBPTRM_END_DATE ;        
                 Exception
                When Others then 
                  vl_existe  := 0;
                  ptrm_code := null;
                  vfecha_ini := null;
                   --dbms_output.put_line('Error al recuperar datos de grupo PTRM  '||sqlerrm);
               End;   
   
             --dbms_output.put_line('4.00 iniciando MS PARA MATERIA  /'||  x.mate_hijo||'/'||vl_existe||'/'|| ptrm_code );
   
         IF  vl_existe > 0 THEN 
             
             -------------------SE RECALCULA EL CRN
                          -------------AQUI se crea el nuevo CRN--- para el grupo-------
            Begin 
                select nvl(max(ssbsect_crn),1000)+1 
                     into crn2 
                from ssbsect where ssbsect_term_code=VPERIODOMS ;
                
              Exception
                 When Others then 
                   crn2 := null;
             End;    
                  ----------------------recupero la materia semapara-----
                       begin
                          select   SCBCRSE_TITLE, SCBCRSE_CREDIT_HR_LOW, SCBCRSE_BILL_HR_LOW, SCRSCHD_SCHD_CODE
                             INTO  vtitle, vcredits, vbills,vschd
                         from SCBCRSE ce, SCRSCHD hd
                         where SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB = hd.SCRSCHD_SUBJ_CODE||SCRSCHD_CRSE_NUMB
                          and SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB = c.materia ;----AQUI LE PUSE LA MATERIA PADRE POR QUE SOLO BUSCO DATOS GENERALES ESTA BIEN

                         Exception
                        When Others then 
                          --vsubj := NULL; --ptrm_code := null;
                          
                          vsqlerrm := 'No esta la materia hija en SCBCRSE::  ' ;
                          raise_application_error (-20002,vsqlerrm|| x.mate_hijo||'  <---> '|| sqlerrm);
                       -- dbms_output.put_line('Error al recuperar datos de grupo EXTRAS  '||sqlerrm);
                       end;
                       
                       
                       --  dbms_output.put_line('Paso 6 despus de validar ssbsect2  ');   
                        begin
                            select scrgmod_gmod_code
                                  into gmod
                            from scrgmod
                              where scrgmod_subj_code||scrgmod_crse_numb  =  x.mate_hijo
                                and     scrgmod_default_ind='D';
                        exception when others then
                            gmod:='1';
                        end;          
                        
        --              
                           
                     ----------------------------------------------
                 begin              
            --  DBMS_OUTPUT.PUT_LINE(' ESTA DENTRO DE MASTER :.'|| x.mate_hijo|| '<-->'||vlevel_hijo   );
                    Insert into ssbsect values (
                               VPERIODOMS, ---   '02'||SUBSTR( VPERIODOMS,3,8),     --SSBSECT_TERM_CODE
                               crn2,     --SSBSECT_CRN
                               ptrm_code, ---'N'||SUBSTR(ptrm_code,2,3 ),  ------ ptrm_code,     --SSBSECT_PTRM_CODE
                               vsubj,     --SSBSECT_SUBJ_CODE
                               vcrse,     --SSBSECT_CRSE_NUMB
                               '01',   --para este siempre va ser grupo 01  --SSBSECT_SEQ_NUMB
                               'A',    --SSBSECT_SSTS_CODE
                               vschd,    --SSBSECT_SCHD_CODE
                               c.campus,    --SSBSECT_CAMP_CODE
                               vtitle,   --SSBSECT_CRSE_TITLE
                               vcredits,   --SSBSECT_CREDIT_HRS
                               vbills,   --SSBSECT_BILL_HRS
                               gmod,   --SSBSECT_GMOD_CODE
                               null,  --SSBSECT_SAPR_CODE
                               null, --SSBSECT_SESS_CODE
                               null,  --SSBSECT_LINK_IDENT
                               null,  --SSBSECT_PRNT_IND
                               'Y',  --SSBSECT_GRADABLE_IND
                               null,  --SSBSECT_TUIW_IND
                               0, --SSBSECT_REG_ONEUP
                               0, --SSBSECT_PRIOR_ENRL
                               0, --SSBSECT_PROJ_ENRL
                               pcupo, --SSBSECT_MAX_ENRL
                               0,--SSBSECT_ENRL
                                pcupo,--SSBSECT_SEATS_AVAIL
                               null,--SSBSECT_TOT_CREDIT_HRS
                               '0',--SSBSECT_CENSUS_ENRL
                               vfecha_ini,--SSBSECT_CENSUS_ENRL_DATE
                               sysdate,--SSBSECT_ACTIVITY_DATE
                               vfecha_ini,--SSBSECT_PTRM_START_DATE
                               vfecha_fin,--SSBSECT_PTRM_END_DATE
                               p_semanas,--SSBSECT_PTRM_WEEKS
                               null,--SSBSECT_RESERVED_IND
                               null, --SSBSECT_WAIT_CAPACITY
                               null,--SSBSECT_WAIT_COUNT
                               null,--SSBSECT_WAIT_AVAIL
                               null,--SSBSECT_LEC_HR
                               null,--SSBSECT_LAB_HR
                               null,--SSBSECT_OTH_HR
                               null,--SSBSECT_CONT_HR
                               null,--SSBSECT_ACCT_CODE
                               null,--SSBSECT_ACCL_CODE
                               null,--SSBSECT_CENSUS_2_DATE
                               null,--SSBSECT_ENRL_CUT_OFF_DATE
                               null,--SSBSECT_ACAD_CUT_OFF_DATE
                               null,--SSBSECT_DROP_CUT_OFF_DATE
                               null,--SSBSECT_CENSUS_2_ENRL
                               'Y',--SSBSECT_VOICE_AVAIL
                               'N',--SSBSECT_CAPP_PREREQ_TEST_IND
                               null,--SSBSECT_GSCH_NAME
                               null,--SSBSECT_BEST_OF_COMP
                               null,--SSBSECT_SUBSET_OF_COMP
                               'NOP',--SSBSECT_INSM_CODE
                               null,--SSBSECT_REG_FROM_DATE
                               null,--SSBSECT_REG_TO_DATE
                               null,--SSBSECT_LEARNER_REGSTART_FDATE
                               null,--SSBSECT_LEARNER_REGSTART_TDATE
                               null,--SSBSECT_DUNT_CODE
                               null,--SSBSECT_NUMBER_OF_UNITS
                               0,--SSBSECT_NUMBER_OF_EXTENSIONS
                               'SZFHOMNMS',--SSBSECT_DATA_ORIGIN
                               user,--SSBSECT_USER_ID
                               'MOOD',--SSBSECT_INTG_CDE
                               'B',--SSBSECT_PREREQ_CHK_METHOD_CDE
                               user,--SSBSECT_KEYWORD_INDEX_ID
                               null,--SSBSECT_SCORE_OPEN_DATE
                               null,--SSBSECT_SCORE_CUTOFF_DATE
                               null,--SSBSECT_REAS_SCORE_OPEN_DATE
                               null,--SSBSECT_REAS_SCORE_CTOF_DATE
                               null,--SSBSECT_SURROGATE_ID
                               null,--SSBSECT_VERSION
                               null);--SSBSECT_VPDI_CODE
                          COMMIT;
                         --DBMS_OUTPUT.PUT_LINE('4.- INSERTA MATERIA HIJO MS:   ' || x.mate_hijo||'<->'||ptrm_code|| '<-->'||vlevel_hijo   ) ;
                     exception when others then
                        null;--DBMS_OUTPUT.PUT_LINE('4.- ERROR::  MATERIA HIJO MS:   ' || x.mate_hijo||'<->'||ptrm_code|| '<-->'||vlevel_hijo   ) ;
                     end;              
                              -------------------------------AHORA INSERTA EL PROFESOR PARA ESTA MATERIA  DE MASTER---------------------         
                           Begin 
                                insert into sirasgn values(
                                            VPERIODOMS ,
                                            crn2, 
                                            fget_pidm(c.docente), 
                                            '01', 
                                            100, 
                                            null, 
                                            100,'Y', null, null,  
                                            sysdate, null,null,null,null, vdata_orig, USER, null, null, null, null,  null,null);
                                            
                           --dbms_output.put_line('5.-  SE ha insertado el profesor  MS>>  ' ||(jump) ||'--'||VPERIODOMS||'--'|| crn2||'-'|| c.docente );
                            Exception
                        When Others then 
                        null;
                         --dbms_output.put_line('Error al INSERTAR NUEVO PROFE '||sqlerrm);
                        End;
                                                     
                       
                           -----------------------SI LLEGA HASTA ACA  SIN ERROR ENTONCES ACTUALIZA EL VAMPO DE GENERADOR
            UPDATE SZTNIVE Z
              SET Z.SZTNIVE_GENERADOR    = 1
              WHERE  Z.SZTNIVE_CAMPUS      = PPCAMPUS
                   AND     Z.SZTNIVE_NIVEL    = vlevel_hijo
                   AND     Z.SZTNIVE_MATERIA  = x.mate_hijo
                   AND     Z.SZTNIVE_DOCENTE  =  c.docente
                   AND     Z.SZTNIVE_VALIDA   = 1  ;
                        
                          
                          
                          
                   END IF;  ----TERMINA CIES EL NIVEL MS
             END IF; ----TERMINA EL PRIMER FILTRO DE MASTER
           
           
         ---END IF;                                                                       
               
                                            
 /*      Exception
       When Others then 
         null;
          dbms_output.put_line('Error al INSERTAR EL NUEVO GRUPO'||sqlerrm);
           raise_application_error (-20002,'inserta MASTER--materia hijo  '|| x.mate_hijo||'  <--->'|| sqlerrm);
                    null;

  ---     End;
  */
           -----//******  se inserta el profesor ***//////----
          --   dbms_output.put_line('Paso 7 despus de INSERTAR ssbsect1  ');   
           
         
                                     
        
 
  --end if;



commit;
end loop; --- final  de maco
 --dbms_output.put_line('-----------*************************------------------');
---end if; --- fin general inicial 
end loop;----semana
    -- dbms_output.put_line('--------------------------------------------------');
end loop;  ----final materias

exception when others then
 raise_application_error (-20002,'ERror GRal--'|| sqlerrm);

null;

null;

end p_crea_masivo_horario;



BEGIN
NULL;


end PKG_NIVELACION_GRUPOS;
/

DROP PUBLIC SYNONYM PKG_NIVELACION_GRUPOS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_NIVELACION_GRUPOS FOR BANINST1.PKG_NIVELACION_GRUPOS;
