DROP PACKAGE BODY BANINST1.PKG_NIVE_AULA;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_NIVE_AULA is

/*
se agrego la validacion para obtener el último periodo de los que existan configurados
para EXTR y TISU
glovicx 16/02/021

cambio para la sincronizacion de EXTR y TISU  para que use la fecha de la parte del periodo. de cuando escogioel extraordinario  glovicx 22/02/021
SE AGREGA LA FUNCION PARA LA BITACORA DE ERRORES Y QUE NO SE DUPLIQUEN GLOVICX 27/07/2021
-- último cambio 05/09 para alinear que inserte gpos- profes y alumnos glovicx
ultima modificación glovicx 09-01-2025
-- SE AGREGA MODIFICACION NIVE_CERO Y CIENTIFICA GLOVICX 23.3.25
*/


function f_inst_SZTGPME (pmate_padre  varchar, pmate_hijo varchar,pptrm varchar2,pfini varchar2,
             pnivel  varchar2, pcampus varchar2,pshort_name varchar2,vperiodo varchar2, vfini2 varchar2 ) return varchar2  IS




vnom_curso      varchar2(150);
vseqno          number:= 0; --consutivo por gpo pregunta a vic como funciona
vrcount         number:=0;
VBITACORA       VARCHAR2(100);
VERROR          VARCHAR2(800);
vextra_gpo      number:=0;

---  SE LE AGREGO UN NUEVO VALOR DE IDIOMA  AL INSERT ES HARD CORE REGLA DE ALEX 02.05.2024 GLOVICX

begin
null;
--DBMS_OUTPUT.put_line('Estoy en inserta GRUPO:  '|| pmate_padre);
---calcular el titulo dela materia
   begin

                select SCRSYLN_LONG_COURSE_TITLE
                    INTO  vnom_curso
                    from SCRSYLN
                         where 1=1
                              and SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB = pmate_padre    ;
   exception when others then
        vnom_curso  := null;
   end;


--DBMS_OUTPUT.put_line('Entra buscar el curso de la mate: ' || vnom_curso ||'-'|| pmate_padre||'-->>--'||vperiodo  );

---- primero validamos primero por periodo el normal --
            begin
              
              Select   distinct  max(gp.SZTGPME_NIVE_SEQNO)  --  seqno_nive
                   into  vseqno
                from SZTGPME gp
                    where 1=1
                   and SUBSTR(gp.SZTGPME_TERM_NRC_COMP,3,6) =     SUBSTR(vperiodo,3,6)
                    and gp.SZTGPME_TERM_NRC = pmate_padre||'01'
                    and gp.SZTGPME_PTRM_CODE  = pptrm -- se puso este nivel para DTMA por que cambia entre MA y DO  NO afecta para NIVE glovicx 21.02.2025
                    and GP.SZTGPME_NO_REGLA  = 99 ;

             exception when others then
                 -- si no lo encuentra es que ya cambio el periodo al segundo o tercero
                      vseqno  := 0;
                  DBMS_OUTPUT.put_line('Entra error al recuperar seqno_1 viejo:SZTGPME  ' || vseqno ||'-'||pmate_padre );


             end;


           -- DBMS_OUTPUT.put_line('Entra validacion1  seqno_1 viejo: ' || vseqno  );

        IF  vseqno  IS NULL or vseqno = 0  THEN

         --DBMS_OUTPUT.put_line('Entra NOOO recupera el seqno NO existe para ese periodoVICX: ' || vseqno||' - '|| vperiodo  );
         -- recupera el mwximo del period mas alto
        BEGIN
        Select nvl(MAX(gp.SZTGPME_NIVE_SEQNO),0)+1  seqno_nive
           into  vextra_gpo
        from SZTGPME gp
        where 1=1
        and GP.SZTGPME_NO_REGLA  = 99
        and gp.SZTGPME_TERM_NRC = pmate_padre||'01';

        EXCEPTION WHEN OTHERS THEN
        NULL;
        vextra_gpo := 1;
        
         --DBMS_OUTPUT.put_line(' el seqno NO lo pede calcular : ' || vseqno  );
        END;

       vseqno := 0;



     END IF;



-------obtenemos el consecutivo, para el campo SZTGPME_NIVE_SEQNO debera ser 1 numero consecutivo por cada
--  periodo sabiendo que solo hay tres periodos por año
         --primero tengo que buscar si existe la materia y el periodo completo de las NIVE
    IF  pcampus IN ('UNI','UIN')   THEN
        begin
              Select   distinct  max(gp.SZTGPME_NIVE_SEQNO) --  seqno_nive
                   into  vseqno
                from SZTGPME gp
                    where 1=1
                   and gp.SZTGPME_TERM_NRC = pmate_padre||'01'
                  -- and SUBSTR(gp.SZTGPME_TERM_NRC_COMP,3,6) =     SUBSTR(vperiodo,3,6)
                   AND GP.SZTGPME_START_DATE  = vfini2   ----se valida la fecha de inicio para UIN
                   and GP.SZTGPME_TERM_NRC_COMP    is not null    --se le puso esta validación por que entraton muchos reg en blanco glovicx 01/06/021
                   and GP.SZTGPME_NO_REGLA  = 99 ;
            DBMS_OUTPUT.put_line('Entra SISIII recuperar seqno_ calcula nuevo UIN: ' || vseqno  );
        exception when others then
        -- si no lo encuentra es que ya cambio el periodo al segundo o tercero
          vseqno  := 0;


        end;


         if vseqno IS NULL OR vseqno = 0  THEN
           --DBMS_OUTPUT.put_line('DESPUES DE recuperar seqno_ OTRAVEZZZ  nuevo UIN: ' || vseqno  );

                begin
                      Select distinct  NVL(max(gp.SZTGPME_NIVE_SEQNO),1)  +1 --  seqno_nive le sunma uno por que es fecha de inicio diferente mismo periodo glovicx 01/06/2021
                           into  vextra_gpo
                        from SZTGPME gp
                            where 1=1
                            and gp.SZTGPME_TERM_NRC = pmate_padre||'01'
                           -- and SUBSTR(gp.SZTGPME_TERM_NRC_COMP,3,6) =     SUBSTR(vperiodo,3,6)
                           and GP.SZTGPME_TERM_NRC_COMP    is not null    --se le puso esta validación por que entraton muchos reg en blanco glovicx 01/06/021
                           and GP.SZTGPME_NO_REGLA  = 99
                            ;
                   -- DBMS_OUTPUT.put_line('Entra SISIII recuperar seqno_ calcula nuevo UIN: ' || vseqno  );
                exception when others then
                -- si no lo encuentra es que ya cambio el periodo al segundo o tercero
                  vseqno  := 1;
                --DBMS_OUTPUT.put_line('Entra error al recuperar seqno_ calcula nuevo UIN: ' || vseqno  );
                  VERROR  := SUBSTR(SQLERRM,1,100);
                    -- VBITACORA := F_BITSIU( 'SZTGPME_MAX_UIN',NULL,'NIVE_AULA',vseqno,Pmate_padre,pmate_hijo,vperiodo,SYSDATE,substr(Pmate_padre,1,14),pnivel,vfini2,pcampus,NULL,
                     ---           NULL,NULL,NULL,NULL,'NO inserto en SZTGPME',VERROR,NULL,NULL,NULL,NULL );


                end;


            vseqno := 0;


         end if;
  END IF;


    

--DBMS_OUTPUT.put_line('Entra validacion4 exception, no existe y cre buevo: ' || vseqno||'-'||vfini2 ||'-'|| vextra_gpo );

   --DBMS_OUTPUT.put_line('Entra valida si existe el grupo xx  existe = : ' || vextra_gpo||'-'||pmate_padre||'-'||pcampus ||'-'||pnivel||'-'||vseqno );

  IF vseqno =  0  then
  
        begin
        ---  insertamos los valores en la tabla de grupos
        insert into SZTGPME(
        SZTGPME_TERM_NRC, ----mat padre + grupo
        SZTGPME_SUBJ_CRSE, --- mat padre emir me dijo que la cambiara
        SZTGPME_TITLE,          ----nombre del cuso
        SZTGPME_STAT_IND,     ---0
        SZTGPME_USER_ID,      ---user
        SZTGPME_ACTIVITY_DATE, -----sysdate
        SZTGPME_PTRM_CODE,      --ptrm
        SZTGPME_START_DATE,   --fecha inicio
        SZTGPME_MAX_ENRL,          --500
        SZTGPME_LEVL_CODE,       ---nivel
        SZTGPME_CAMP_CODE,    -----camp
        SZTGPME_SUBJ_CRSE_COMP, --mat padre
        SZTGPME_CRSE_MDLE_CODE, ---funcion de short name
        SZTGPME_NO_REGLA,    ---99
        SZTGPME_NIVE_SEQNO,    ----consecutivo exclusivo de nive empezando desde 2
        SZTGPME_TERM_NRC_COMP,  -- vperiodo
        SZTGPME_GRUPO ,        ---aqui va simpre 1  por el grupo 01
        SZTGPME_IDIOMA
        )
        VALUES ( pmate_padre||'01', pmate_padre,vnom_curso,0 ,user, sysdate, pptrm,vfini2,500,pnivel, pcampus,pmate_padre  ,pshort_name,99,vextra_gpo,vperiodo,1,'E' );
        vrcount   := sql%rowcount;
        --DBMS_OUTPUT.put_line('Registros insertados SZTGPME : '||sql%rowcount);

        exception WHEN DUP_VAL_ON_INDEX THEN
            NULL;
        DBMS_OUTPUT.put_line('ERROR AL  insertados DUPLICA SZTGPME : '||pmate_padre||'01'|| pCAMPUS||'-'||PNIVEL||'-'||vseqno||'-'|| sql%rowcount||' - '||SQLERRM);
         when others then
        VERROR   := sqlerrm;
        --VBITACORA := F_BITSIU( 'SZTGPME',NULL,'NIVE_AULA',vseqno,Pmate_padre,pmate_hijo,vperiodo,SYSDATE,substr(Pmate_padre,1,14),pnivel,vfini2,pcampus,NULL,
          --                      NULL,NULL,NULL,NULL,'NO inserto en SZTGPME',VERROR,NULL,NULL,NULL,NULL );

        DBMS_OUTPUT.put_line('ERROR AL  insertados SZTGPME : '||pmate_padre||'01'|| pCAMPUS||'-'||PNIVEL||'-'||vseqno||'-'|| sql%rowcount||' - '||SQLERRM);
        null;
        end;

  ELSE ---SI ENTRA EN ESTA SECCION ES QUE SI EXISTE ENTONCES NO LO INSERTA PERO SI MANDA EXITO GLOVICX
   vrcount := 1;
  END IF;


vseqno:=0;

IF vrcount > 0 then
return 'EXITO';
else
return(VERROR);
end if;

exception when others then
DBMS_OUTPUT.put_line('ERROR GRAAL  insertados SZTGPME : '|| '->' ||SQLERRM);
--VBITACORA := F_BITSIU( 'SZTGPME',NULL,'NIVE_AULA',vseqno,Pmate_padre,pmate_hijo,vperiodo,SYSDATE,substr(Pmate_padre,1,14),pnivel,vfini2,pcampus,NULL,
  --                              NULL,NULL,NULL,NULL,'NO inserto en SZTGPME',VERROR,NULL,NULL,NULL,NULL );
return(VERROR);





end f_inst_SZTGPME;


function f_inst_SZSGNME (pmate_padre  varchar, Ppidm number,pptrm varchar2, pfini  varchar2,vperiodo varchar2 ) return varchar2  IS

vprof_pwd      varchar2(300);
vseqno         number:= 0;
vrcount        number:=0;
VBITACORA      VARCHAR2(100);
VERROR         VARCHAR2(200);
VPROFE_EXTRA   number:=0;
vseqno2         number:= 0;


-- SE AGREGA UN NUEVO VALOR DE COLUMNA IDIOMA EN EL INSERT REGLA DE ALEX 02.05.2024 GLOVICX

begin
null;

----sacamos el psw del profesor

----- buscar los pasword para los profesores y para los  alumnos
                        begin

                           select GOZTPAC_PIN
                           into vprof_pwd
                           from GOZTPAC pac
                           where 1 = 1
                           and pac.GOZTPAC_pidm =Ppidm
                           and rownum = 1;

                        exception when others then
                            DBMS_OUTPUT.put_line(' Error al obtener pwd '||sqlerrm||' pidm '||Ppidm);
                           null;
                           VERROR  := SQLERRM;
                        end;



     --NUEVA VALIDACION BUSCAMOS EL SEQNO DEL GRUPO QUE YA EXISTE X QUE DEBEN TENER EL MISMO SEQNO GRUPOS Y MAESTROS
     ---  NUEVA MODIFICACION GLOVICX 16.05.2024
            begin
              
              Select   distinct  max(gp.SZTGPME_NIVE_SEQNO)  --  seqno_nive
                   into  vseqno
                from SZTGPME gp
                   where 1=1
                    and SUBSTR(gp.SZTGPME_TERM_NRC_COMP,3,6) =     SUBSTR(vperiodo,3,6)
                    and gp.SZTGPME_TERM_NRC = pmate_padre||'01'
                    and gp.SZTGPME_PTRM_CODE  = pptrm -- se puso este nivel para DTMA por que cambia entre MA y DO  NO afecta para NIVE glovicx 21.02.2025
                    and GP.SZTGPME_NO_REGLA  = 99 ;
                  
                
                 VPROFE_EXTRA  := 0; ----si encuentra el seqno padre y por eso VPROFE_EXTRA = 0 
             exception when others then
                 -- si no lo encuentra es que ya cambio el periodo al segundo o tercero
                      vseqno  := 0;
                  DBMS_OUTPUT.put_line('Entra error al recuperar seqno_1 viejo: ' || vseqno ||'-'||pmate_padre );


             end;


           --DBMS_OUTPUT.put_line('Entra validacion1  seqno_1 DEL GRUPO: ' || vseqno  );

    ----VALIDAMOS SI EXISTE EL PROFESOR YA EN LA TABLA
     BEGIN

       SELECT  NVL(MAX(SZSGNME_NIVE_SEQNO),0) MAXIM
           INTO VPROFE_EXTRA
         FROM  SZSGNME
         WHERE 1=1
         AND SZSGNME_TERM_NRC =pmate_padre||'01'
         AND SZSGNME_NO_REGLA = 99
         and SZSGNME_PTRM     = pptrm -- se puso este nivel para DTMA por que cambia entre MA y DO  NO afecta para NIVE glovicx 21.02.2025
         and SZSGNME_START_DATE = (pfini)
         ;
               --dbms_output.put_line('si si si encontro profe_materia'||pmate_padre||'01' ||'-'||pfini ||'-'||vseqno );
      EXCEPTION WHEN OTHERS THEN
         --dbms_output.put_line('error no encontro profe_materia:  '||pmate_padre||'01' ||'-'||pfini ||'-'||vseqno );
        VPROFE_EXTRA  := 0;
        VERROR  := SQLERRM;

     END;

      IF VPROFE_EXTRA >= 1 then
    vrcount := 1;--ya existe el grupo maestro y fecha de inicio manda exito
    end if;



        IF  vseqno  IS NULL or vseqno = 0 THEN

          VPROFE_EXTRA := 0;


           begin
             Select  nvl(MAX(GN.SZSGNME_NIVE_SEQNO),1) +1  seqno_nive
               into  vseqno
            from SZSGNME GN
            where 1=1
            AND GN.SZSGNME_TERM_NRC =pmate_padre||'01'
            --AND SZSGNME_SEQ_NO  = 1
            AND GN.SZSGNME_NO_REGLA = 99
             ;

            exception when others then
            vseqno  := 0;
            --VERROR  := SQLERRM;
            DBMS_OUTPUT.put_line('Entra NOOO recupera el seqno NO existe para ese periodo XX : ' || vseqno||' - '|| vperiodo  );
            end;
            
             begin
             Select  nvl(MAX(GN.SZSGNME_SEQ_NO),1) +1  seqno_nive
               into  vseqno2
            from SZSGNME GN
            where 1=1
            AND GN.SZSGNME_TERM_NRC = pmate_padre||'01'
            --AND SZSGNME_SEQ_NO  = 1
            AND GN.SZSGNME_NO_REGLA = 99
             ;

            exception when others then
            vseqno2  := 1;
            --VERROR  := SQLERRM;
            DBMS_OUTPUT.put_line('Entra NOOO recupera el seqno NO existe para ese periodo XX : ' || vseqno||' - '|| vperiodo  );
            end;


        end if;



--DBMS_OUTPUT.put_line('Salida de seqno_ calcula nuevo: ' || vseqno ||'--'|| VPROFE_EXTRA );


  IF VPROFE_EXTRA = 0 THEN


        begin
        insert into SZSGNME (  SZSGNME_TERM_NRC,   --materiap + gpo 01
        SZSGNME_PIDM,           --pidm
        SZSGNME_ACTIVITY_DATE,  ---sysdate
        SZSGNME_USER_ID,     -----user
        SZSGNME_STAT_IND,   --- default 0
        --SZSGNME_OBS,    --null
        SZSGNME_PWD,   --null mando pasword
        --SZSGNME_ASGNMDLE_ID, ---null
        SZSGNME_FCST_CODE,    --'AC'
        SZSGNME_SEQ_NO,    ----null-- que lleva aqui
        --SZNME_POBI_SEQ_NO,  ----null
        SZSGNME_PTRM,     --ptrm
        SZSGNME_START_DATE,  --fini
        SZSGNME_NO_REGLA,  --99
        --SZSGNME_SECUENCIA,  --null  que lleva aqui
        SZSGNME_NIVE_SEQNO,
        SZSGNME_IDIOMA 
          )
        VALUES( pmate_padre||'01', PPIDM, sysdate, user, 0,vprof_pwd,'AC',vseqno2,pptrm,pfini,99,vseqno,'E');
        vrcount   := sql%rowcount;
        --DBMS_OUTPUT.put_line('Registros insertados SZSGNME : '||sql%rowcount);

        exception WHEN DUP_VAL_ON_INDEX THEN
            NULL;
         DBMS_OUTPUT.put_line('Error inserta DUPLICA profe '|| pmate_padre||'01'||'-'||  pfini||'-'||VERROR );
        when others then
        --DBMS_OUTPUT.put_line('Erroe al insertar el szsgnme:  ');
        null;
        VERROR  := SQLERRM;
         --DBMS_OUTPUT.put_line('Error inserta profe '|| pmate_padre||'01'||'-'||  pfini||'-'||VERROR );
        end;


vrcount := 1;
ELSE
-- SI ESTRA EN ESTA SEECION ES QUE YA ENCONTRO AL MAESTRO, NO LO INSERTA PERO REGRESA EXITO GLOVICX
vrcount := 1;

END IF;


IF vrcount > 0 then
return 'EXITO';
else
return(VERROR);
end if;

EXCEPTION WHEN OTHERS THEN
null;
dbms_output.put_line('ERROR gral en carga profes '||pmate_padre||'01' ||'-'||pfini ||'-'||vseqno||'-'||VERROR );
--VBITACORA := F_BITSIU( 'SZSGNME',PPIDM,'NIVE_AULA',vseqno,Pmate_padre,pptrm,pfini,SYSDATE,substr(Pmate_padre,1,14),vrcount,vperiodo,NULL,NULL,
  --                              NULL,NULL,NULL,NULL,'NO-inserto en SZSGNME',VERROR,NULL,NULL,NULL,NULL );

return(VERROR);

end f_inst_SZSGNME;

function f_inst_SZSTUME (pmate_padre  varchar2, ppidm number,pmatricula varchar2,pf_ini  varchar2, vperiodo varchar2,pseqno number ,pstatus varchar2 ) return varchar2  IS

--se realiza un cambio para la cancelación de EXTR
vpwd            Varchar2(200);
vmax_seq        number:= 0;
vseqno          number:= 0;
vrcount         number:=0;
existe_horario  number:=0;
vestatus        varchar2(2);
VBITACORA       varchar2(100);
verror          varchar2(200);
vzstume2        number:=0;

begin
null;
---si no trae un estatus entonces se lo agregamos si trae estatus es una cancelacion de EXTR
--regla de Vic RMZ 28/05/021 para UIN.
-- se puso un doble  candado para que No se inserte doble los registros de sztume glovicx 26.05.2025

IF pstatus is null then
vestatus := 'RE';

ELSE
vestatus  := pstatus;
end if;


---haya que buscar los pasword para los profesores y para los  alumnos
            begin

               select GOZTPAC_PIN
               into vpwd
               from GOZTPAC pac
               where 1 = 1
               and pac.GOZTPAC_pidm =Ppidm
               and rownum = 1;

            exception when others then
                --DBMS_OUTPUT.put_line(' Error al obtener pwd '||sqlerrm||' pidm '||Ppidm);
               null;
               vpwd:='';
            end;

      begin

         select 1
             into  vzstume2
         from SZSTUME
          where 1=1
             and SZSTUME_PIDM = Ppidm
             and SZSTUME_NO_REGLA = 99
             and SZSTUME_TERM_NRC = pmate_padre||'01'
             and SZSTUME_POBI_SEQ_NO  =  pseqno  ;

      exception when others then
        vzstume2  := 0;
             -- DBMS_OUTPUT.PUT_LINE(' SALIDA no EXISTE MATERIA SEQNO:: '|| vzstume2 );
      end;
      
      
          begin
            select nvl(max(SZSTUME_SEQ_NO),0) + 1
             into  vmax_seq
            from SZSTUME
            where 1=1
             and SZSTUME_PIDM = Ppidm
            and SZSTUME_NO_REGLA = 99
             and SZSTUME_TERM_NRC = pmate_padre||'01';

            exception  when no_data_found  then
                       
        vmax_seq := 1;
        --DBMS_OUTPUT.PUT_LINE('ERROE AL RECUPERAR EL MAXSEQNO X ALUMNO');
        verror  := sqlerrm;

      end;


--DBMS_OUTPUT.put_line('antes de recupera seqno: ' || vseqno ||'-'||pmate_padre||'-'||vperiodo );
--primero tengo que buscar si existe la materia y el periodo completo de las NIVE
 ---OJO estoy recuperando el mismo que se inserto en el grupo para que no se pierda el orden - integridad
        begin
        Select  NVL(MAX(gp.SZTGPME_NIVE_SEQNO),1)  seqno_nive
           into  vseqno
        from SZTGPME gp
        where 1=1
         and gp.SZTGPME_TERM_NRC = pmate_padre||'01'
         and SUBSTR(gp.SZTGPME_TERM_NRC_COMP,3,6) =     SUBSTR(vperiodo,3,6)
        and GP.SZTGPME_NO_REGLA  = 99 ;

        exception when others then
           DBMS_OUTPUT.put_line('Entra error al recuperar seqno_ calcula nuevo: ' || vseqno  );

                vseqno  := 0;
                verror  := sqlerrm;
         end;
   -- DBMS_OUTPUT.put_line('DESPUES DE recuperar seqno_: ' || vseqno  );

          begin

            select  distinct SFRSTCR_PIDM
              into existe_horario
               from SFRSTCR
                 where 1=1
                  and SFRSTCR_PIDM    = ppidm
                   and  SUBSTR ( SFRSTCR_TERM_CODE  , 5, 1) = '8'
                   and SFRSTCR_RSTS_CODE = 'RE'
                    and SFRSTCR_RESERVED_KEY in ( select  distinct SZTMACO_MATHIJO
                                                       from sztmaco
                                                          where 1=1
                                                          AND  SZTMACO_MATPADRE =    pmate_padre )
               ;

          exception when others then
                             begin
                              select  distinct SFRSTCR_PIDM
                                     into existe_horario
                                     from SFRSTCR f
                                     where 1=1
                                      and SFRSTCR_PIDM    = ppidm
                                      and  SUBSTR ( F.SFRSTCR_TERM_CODE  , 5, 1) = '8'
                                      and SFRSTCR_RSTS_CODE = 'RE'
                                      and SFRSTCR_RESERVED_KEY in ( select  distinct SZTMACO_MATPADRE
                                                                           from sztmaco
                                                                              where 1=1
                                                                              AND  SZTMACO_MATHIJO =    pmate_padre );

                              exception when others then
                                existe_horario := 0;
                                verror  := sqlerrm;
                             end;

          end;

--DBMS_OUTPUT.put_line('Salida de seqno_ calcula SZTUME nuevo: ' || existe_horario ||'-'||ppidm );
 IF SUBSTR ( vperiodo  , 5, 1) = '7'  then
    existe_horario := 1; -- es producion cientifica u segun regla de fernando NO lleva materia sembrada en SFRSTCR 17.01.2025 glovicx 
    end if;

--DBMS_OUTPUT.put_line('Salida de seqno_ calcula SZTUME nuevo: ' || existe_horario ||'-'||vzstume2 );
  IF existe_horario >= 1 and vzstume2 = 0  then

    BEGIN
    insert into SZSTUME
    (
    SZSTUME_TERM_NRC, --materia padre
    SZSTUME_PIDM,
    SZSTUME_ID,
    SZSTUME_ACTIVITY_DATE,
    SZSTUME_USER_ID,
    SZSTUME_STAT_IND,  --0 siempre
    SZSTUME_PWD,         ----psw
    SZSTUME_SEQ_NO,   --   ---consecutivo por alumno y materia si mandas el mismo alumno misma materia 2 veces el consecutivo sera 1, 2 asi tantas veces se pueda
    SZSTUME_RSTS_CODE,  --estatus RE
    SZSTUME_SUBJ_CODE,   -- materia
    SZSTUME_SUBJ_CODE_COMP, --materia
    SZSTUME_START_DATE, --inicio de ciclo
    SZSTUME_NO_REGLA,  --99 siempre
    SZSTUME_NIVE_SEQNO,
    SZSTUME_POBI_SEQ_NO
    )
    values (
    pmate_padre||'01',
    ppidm,
    pmatricula,
    sysdate,
    user,
    0,
    vpwd,
    vmax_seq,
    vestatus,
    pmate_padre,
    pmate_padre,
    pf_ini,
    99,
    vseqno,
    pseqno
    );
    vrcount   := sql%rowcount;
    --DBMS_OUTPUT.put_line('Registros insertados SZSTUME : '||sql%rowcount||'-'||pmate_padre||'01'||'-'||ppidm||'-'||pseqno);

    exception when others then
           verror  := sqlerrm;
           
            DBMS_OUTPUT.put_line('Error  en inserta Alumno SZSTUME :  '||verror  );
              null;
             
     end;

else
    --manda a la bitacora que el alumno no se pudo syncronizar por que no se encontro su horario
    null;
--insert into TBITSIU( MATRICULA,PIDM,CODIGO,SEQNO,ESTATUS, MATERIA, VALOR16)
--values(pmatricula, ppidm, 'NIVEX', pseqno,'ERRO', pmate_padre, 'NO SE ENCONTRO HORARIO PARA SINCRONIZAR') ;
--commit;

end if;

IF vrcount > 0 then
COMMIT;
return 'EXITO';
COMMIT;
else
return('ERROR');
end if;

exception when others then
verror  := sqlerrm; 
  --DBMS_OUTPUT.PUT_LINE('eRROR EN PROCESO GENERAL DE INSERTA SZTUME ALUMNO'|| VERROR );

end f_inst_SZSTUME;

procedure  p_main (ppidm  IN number default null, pndate IN number default 0)  is
/*
proceso anomino para funcion de migrar al aula las nivelaciones
se busca el universo de los alumnos que pidieron una nivelación
-- agrega union para que tome los EXTR de UIN aun sin pago esta regla la dio Vic Rmz 28/05/021
*/
cursor c_nivelacion is
SELECT *
FROM (
SELECT DATOS.SEQNO, DATOS.PIDM, DATOS.TRANUM,DATOS.MATERIA,DATOS.PERIODO,DATOS.CODE,
 ( SELECT case when DATOS.CODE  = 'DTMA' then
   
       TO_DATE(nvl(VA2.SVRSVAD_ADDL_DATA_DESC,'01/01/2000' ),'DD/MM/YYYY' )
     
     ELSE 
      TO_DATE(
      SUBSTR(va2.SVRSVAD_ADDL_DATA_DESC,1,decode(INSTR(va2.SVRSVAD_ADDL_DATA_DESC,'-AL-',1),0,10, INSTR(va2.SVRSVAD_ADDL_DATA_DESC,'-AL-',1))-1)
     , 'DD/MM/YYYY' )
  end    
   from svrsvpr v1,SVRSVAD VA2
            where 1=1
            AND v1.SVRSVPR_PROTOCOL_SEQ_NO = DATOS.SEQNO
            AND v1.SVRSVPR_PIDM      = DATOS.PIDM
            and V1.SVRSVPR_PROTOCOL_SEQ_NO  = VA2.SVRSVAD_PROTOCOL_SEQ_NO
            and va2.SVRSVAD_ADDL_DATA_SEQ = '7') FECHA_INICIOS
             ,datos.SVRSVPR_SRVS_CODE as codecl
FROM (
select v.SVRSVPR_PROTOCOL_SEQ_NO as seqno, v.SVRSVPR_PIDM pidm,  v.SVRSVPR_ACCD_TRAN_NUMBER  tranum
, case when  v.SVRSVPR_SRVC_CODE  = 'DTMA' then
    TRIM(substr(VA.SVRSVAD_ADDL_DATA_DESC,(instr(VA.SVRSVAD_ADDL_DATA_DESC,',',1)+1 ),9))
else
va.SVRSVAD_ADDL_DATA_CDE
end   materia
,v.SVRSVPR_TERM_CODE periodo
,v.SVRSVPR_SRVC_CODE   code
,v.SVRSVPR_SRVS_CODE
from SVRSVPR  v, SVRSVAD va
WHERE 1=1
and v.SVRSVPR_SRVC_CODE in ('NIVE', 'NABA', 'DTMA')
and v.SVRSVPR_SRVS_CODE in ('PA', 'CL', 'EC')
and v.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
and va.SVRSVAD_ADDL_DATA_SEQ in (2)
and V.SVRSVPR_RECEPTION_DATE  >= ('09/11/2020')--inicio en produccion
AND  SVRSVPR_PIDM = nvl(ppidm, SVRSVPR_PIDM )
AND NOT EXISTS ( SELECT 1 FROM SZSTUME z1 WHERE 1=1
                                and z1.SZSTUME_PIDM = v.SVRSVPR_PIDM  --138278
                                and z1.SZSTUME_POBI_SEQ_NO  = v.SVRSVPR_PROTOCOL_SEQ_NO
                               and  z1.SZSTUME_RSTS_CODE  = 'RE'
                                and z1.SZSTUME_NO_REGLA = 99)
UNION
select v.SVRSVPR_PROTOCOL_SEQ_NO as seqno, v.SVRSVPR_PIDM pidm,  v.SVRSVPR_ACCD_TRAN_NUMBER  tranum
,va.SVRSVAD_ADDL_DATA_CDE   materia ,
v.SVRSVPR_TERM_CODE periodo,
v.SVRSVPR_SRVC_CODE   code
,v.SVRSVPR_SRVS_CODE
from SVRSVPR  v, SVRSVAD va
WHERE 1=1
and v.SVRSVPR_SRVC_CODE in ('EXTR','TISU')
and v.SVRSVPR_SRVS_CODE in ('PA')
and v.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
and va.SVRSVAD_ADDL_DATA_SEQ in (2)
and V.SVRSVPR_RECEPTION_DATE  >= ('11/12/2020')--inicio en produccion
and v.SVRSVPR_CAMP_CODE   != 'UIN'
--AND  SVRSVPR_PIDM in  (2324769449 )
AND  SVRSVPR_PIDM = nvl(ppidm, SVRSVPR_PIDM )
AND NOT EXISTS ( SELECT 1 FROM SZSTUME WHERE 1=1
                                and SZSTUME_PIDM = v.SVRSVPR_PIDM  --138278
                               and SZSTUME_POBI_SEQ_NO  = v.SVRSVPR_PROTOCOL_SEQ_NO
                                and SZSTUME_NO_REGLA = 99)
union
select v.SVRSVPR_PROTOCOL_SEQ_NO as seqno, v.SVRSVPR_PIDM pidm,  v.SVRSVPR_ACCD_TRAN_NUMBER  tranum
,va.SVRSVAD_ADDL_DATA_CDE   materia ,
v.SVRSVPR_TERM_CODE periodo,
v.SVRSVPR_SRVC_CODE   code
,v.SVRSVPR_SRVS_CODE
--V.SVRSVPR_CAMP_CODE  campus
from SVRSVPR  v, SVRSVAD va
WHERE 1=1
and v.SVRSVPR_SRVC_CODE in ('EXTR')
and v.SVRSVPR_SRVS_CODE != ('CA')
and v.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
and va.SVRSVAD_ADDL_DATA_SEQ in (2)
and V.SVRSVPR_RECEPTION_DATE  >= ('31/05/2021')--inicio en produccion
and v.SVRSVPR_CAMP_CODE   = 'UIN'
--AND  SVRSVPR_PIDM in  (24913999999 )
AND  SVRSVPR_PIDM = nvl(ppidm, SVRSVPR_PIDM )
AND NOT EXISTS ( SELECT 1 FROM SZSTUME WHERE 1=1
                                and SZSTUME_PIDM = v.SVRSVPR_PIDM  --138278
                                and SZSTUME_RSTS_CODE  = 'RE'
                                and SZSTUME_POBI_SEQ_NO  = v.SVRSVPR_PROTOCOL_SEQ_NO
                                and SZSTUME_NO_REGLA = 99)
) DATOS
) DATOS2
WHERE 1=1
AND trunc(DATOS2.FECHA_INICIOS) BETWEEN  TRUNC(SYSDATE)-30 AND TRUNC(SYSDATE)+ PNDATE  ---NUEVO AJUSTE PARA CENTRAR A UN MES HACIA A TRAS LAS FECHAS GLOVICX 09.01.2025
UNION
SELECT DATOS3.SEQNO, DATOS3.PIDM, DATOS3.TRANUM,DATOS3.MATERIA,DATOS3.PERIODO,DATOS3.CODE,
  TO_DATE((SELECT TO_CHAR(TO_DATE(DATOS1.FECHA1,'MM/dd/YYYY'), 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH') FECHAGBL
FROM
(SELECT SUBSTR(SVRSVAD_ADDL_DATA_DESC,1,10) FECHA1
      FROM  svrsvpr vv,SVRSVAD VA2
            where 1=1
              and Vv.SVRSVPR_SRVC_CODE IN ('NIVG')
              AND  Vv.SVRSVPR_PROTOCOL_SEQ_NO in (DATOS3.SEQNO)
              AND  Vv.SVRSVPR_PIDM    IN (DATOS3.PIDM)
              and Vv.SVRSVPR_PROTOCOL_SEQ_NO  = VA2.SVRSVAD_PROTOCOL_SEQ_NO
              and va2.SVRSVAD_ADDL_DATA_SEQ = '7'
  ) DATOS1
  ), 'DD/MM/YYYY') AS  FECHA_INICIOS
  ,SVRSVPR_SRVS_CODE as codecl
FROM (
select v.SVRSVPR_PROTOCOL_SEQ_NO as seqno, v.SVRSVPR_PIDM pidm,  v.SVRSVPR_ACCD_TRAN_NUMBER  tranum
,va.SVRSVAD_ADDL_DATA_CDE materia
,v.SVRSVPR_TERM_CODE periodo
,v.SVRSVPR_SRVC_CODE   code
,v.SVRSVPR_SRVS_CODE
from SVRSVPR  v, SVRSVAD va
WHERE 1=1
and v.SVRSVPR_SRVC_CODE in ('NIVG')
and v.SVRSVPR_SRVS_CODE in ('PA','CL','EC')
and v.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
and va.SVRSVAD_ADDL_DATA_SEQ in (2)
AND  v.SVRSVPR_PIDM = nvl(ppidm, v.SVRSVPR_PIDM )
AND NOT EXISTS (SELECT 1 FROM SZSTUME WHERE 1=1
                                and SZSTUME_PIDM = v.SVRSVPR_PIDM  --138278
                               and SZSTUME_POBI_SEQ_NO  = v.SVRSVPR_PROTOCOL_SEQ_NO
                               and SZSTUME_RSTS_CODE  = 'RE'
                                and SZSTUME_NO_REGLA = 99)
)DATOS3
WHERE 1=1
ORDER BY 7 DESC
;

vdiasem         varchar2(12);
vdia_ejec       varchar2(12);
vfini           varchar2(12);
vffin           varchar2(12);
VPAGO_VALIDA    varchar2(15);
vmateriap       varchar2(14);
vmateriah       varchar2(14);
vsalida_gpo     varchar2(6);
vsalida_mast    varchar2(6);
vsalida_alum    varchar2(6);
vmatricula      varchar2(14);
vptrm           varchar2(5);
vnivel          varchar2(5);
vcampus         varchar2(5);
vshort_name     varchar2(50);
vperiodo        varchar2(12);
verror          varchar2(500);
id_profesor     varchar2(12);
pidm_prof       number;
vfini2          varchar2(20);
valum_pwd       varchar2(300);
VNO_DIA         NUMBER:= 0;
VNO_DIA2        NUMBER:= 0;
vsysdate        varchar2(14);
VSZTGPME        number:=0;
--pndate             number:=5;
vpidm           number;
vseqno          number;
vstatus         varchar2(4):= 'RE';
VEXISTE         number:= 0;
VBITACORA      VARCHAR2(100);
valida_ingl   varchar2(1):='N';

begin

        --vamos a borrar los datos de la tabla de bitacora para solo trar los de la ultima ejecución
--       BEGIN
--            delete from tbitsiu
--                where 1=1
--                 and  CODIGO = 'NIVE_AULA';
--
--       EXCEPTION WHEN OTHERS THEN
--        NULL;
--        END;


----para moverve en el tiempo hacia atras o adelante
If pndate = 0 then
vsysdate := trunc(sysdate);
else
vsysdate := trunc(sysdate)+pndate;
end IF;

 --DBMS_OUTPUT.put_line('Iniciamos el proceso regs ANTES DE LOOP: ' || vsysdate);

FOR jump in  c_nivelacion LOOP
----LIMPIA VALORES
vdiasem      :=NULL;
vdia_ejec    :=NULL;
vfini           :=NULL;
vffin           :=NULL;
VPAGO_VALIDA     :=NULL;
vmateriap    := null;
vmateriah     := null;
vptrm           := null;
vnivel          := null;
vcampus      := null;
vshort_name    := null;
vperiodo        := null;
verror           := 'EXITO';
VNO_DIA     := 0;
VNO_DIA2     := 0;
vpidm           :=0;
vseqno         :=0;
vstatus       := 'RE';


  -- DBMS_OUTPUT.put_line('Iniciamos el proceso regs: ' ||'-'||  jump.PIDM||'-'||jump.tranum||'-'||jump.seqno||'-'||jump.materia  );
----asigo pidm y seqno
vpidm           :=jump.PIDM;
vseqno         :=jump.seqno;


begin
    select distinct matricula, campus, nivel
     INTO vmatricula , vcampus, vnivel
   from tztprog
   where 1=1
       and  pidm =  jump.PIDM
       and sp  = ( select max(sp)  from tztprog  where 1=1 and  pidm =  jump.PIDM );

exception when others then
vmatricula := null;
verror  := 'no se pudo obtener tztprog';
end;

--priemro validamos que realmente este pagado---se ajusta para cuendo es nive costo cero
   IF jump.codecl in  ('CL','EC')   then  ---- esto es para costo cero glovicx 04.12.2023
   
     VPAGO_VALIDA := 'PAGADO';
   else
         BEGIN

           -----------------se cambia por la funcion de VIC ramirez
               SELECT F_VALIDA_PAGO_ACCESORIO ( jump.PIDM, jump.tranum)AS RESULTADO
                 INTO VPAGO_VALIDA
                 FROM DUAL ;


         exception when others then
           VPAGO_VALIDA := null;
         end;
   END IF;
         
             --DBMS_OUTPUT.put_line('Paso valida si esta pagado: ' ||jump.pidm||'-'||VPAGO_VALIDA);
         -----identificamos el dia de la semana que selecciono el pago--
         begin
             select  VA.SVRSVAD_ADDL_DATA_DESC
             into vdiasem
                from SVRSVPR  v, SVRSVAD va
                WHERE 1=1
                --and  trunc(V.SVRSVPR_RECEPTION_DATE) >= trunc(sysdate)-7
                and SVRSVPR_SRVC_CODE IN ('NIVE','NIVG', 'EXTR','TISU', 'NABA')
                and SVRSVPR_SRVS_CODE in ('PA','AC','CL','EC' )
                and v.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                and SVRSVAD_ADDL_DATA_SEQ in (9)
                and V.SVRSVPR_PIDM        = jump.pidm
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = jump.seqno
                ;

          exception when others then
          vdiasem := 'LUNES' ;
          --verror  := 'no se pudo obtener dia de la semana';
          end;

          IF JUMP.CODE IN ('EXTR','TISU') THEN

            vdiasem  := 'LUNES' ;

          END IF;

        IF jump.code IN ( 'NIVE' , 'EXTR','TISU', 'NABA', 'DTMA') THEN

          BEGIN
          SELECT
          case WHEN vdiasem = 'LUNES' THEN  1
                 WHEN   vdiasem = 'MARTES' THEN   2
               WHEN   vdiasem = 'MIÉRCOLES' THEN 3
               WHEN   vdiasem = 'JUEVES' THEN  4
               WHEN   vdiasem = 'VIERNES' THEN 5
           END AS DIASS
            INTO VNO_DIA
           FROM DUAL;

          EXCEPTION WHEN OTHERS THEN
            VNO_DIA :=0;
          END;

        ELSE ---- INGLES

           BEGIN
          SELECT
          case WHEN vdiasem = 'MONDAY' THEN  1
                 WHEN   vdiasem = 'TUESDAY' THEN   2
               WHEN   vdiasem = 'WEDNESDAY' THEN 3
               WHEN   vdiasem = 'THURSDAY ' THEN  4
               WHEN   vdiasem = 'FRYDAY' THEN 5
           END AS DIASS
            INTO VNO_DIA
           FROM DUAL;

          EXCEPTION WHEN OTHERS THEN
            VNO_DIA :=0;
          END;


        END IF;

            --DBMS_OUTPUT.put_line('Paso valida dia de la sem acc: ' ||jump.pidm||'- '||vdiasem);
 ----------revisamos la parte de periodo que escogio el alumno fechas ini y fin
       
   IF jump.code = 'DTMA'  THEN 
        
     BEGIN
        select  SVRSVAD_ADDL_DATA_DESC FFINI ,   SVRSVAD_ADDL_DATA_CDE  ptrm
           INTO  vfini,  vptrm
                from SVRSVPR  v, SVRSVAD va
              WHERE 1=1
               -- and  trunc(V.SVRSVPR_RECEPTION_DATE) >= trunc(sysdate)-7
                and v.SVRSVPR_SRVC_CODE = 'DTMA'
                and v.SVRSVPR_SRVS_CODE in ('CL', 'PA' )
                and v.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                and va.SVRSVAD_ADDL_DATA_SEQ in (7)
                and V.SVRSVPR_PIDM        = jump.pidm
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = jump.seqno;
            exception when others then
            vfini := null;
        
            vptrm  := null;
            verror  := 'no se pudo obtener fechas ini -fin:  '||SQLERRM;
            dbms_output.put_line('error en fechas INI  DTMA '|| verror  );
            end;
     
     ELSE
 
          begin
             select   substr(va.SVRSVAD_ADDL_DATA_DESC,1,instr(va.SVRSVAD_ADDL_DATA_DESC,'-')-1) fini
                  ,substr(va.SVRSVAD_ADDL_DATA_DESC,instr(va.SVRSVAD_ADDL_DATA_DESC,'-',2,2)+1) ffin
                  ,SVRSVAD_ADDL_DATA_CDE  ptrm
                 INTO  vfini, vffin, vptrm
                from SVRSVPR  v, SVRSVAD va
                WHERE 1=1
               -- and  trunc(V.SVRSVPR_RECEPTION_DATE) >= trunc(sysdate)-7
                and v.SVRSVPR_SRVC_CODE IN ('NIVE','NIVG', 'EXTR','TISU', 'NABA')
                and v.SVRSVPR_SRVS_CODE in ('PA','AC','CL','EC' )
                and v.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                and va.SVRSVAD_ADDL_DATA_SEQ in (7)
                  and V.SVRSVPR_PIDM        = jump.pidm
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = jump.seqno;
            exception when others then
            vfini := null;
            vffin := null;
            vptrm  := null;
            verror  := 'no se pudo obtener fechas ini -fin';
            end;
    END IF;
     --  DBMS_OUTPUT.put_line('Paso valida fechas INI y FIN acc: ' ||jump.pidm||'-'||vfini||'-'||vffin||'--->'||vptrm||'-'|| vdiasem);
------revisamos que dia es hoy dia de la ejecucion
        begin

            select to_char(sysdate+pndate, 'DAY', 'NLS_DATE_LANGUAGE=SPANISH')
            INTO vdia_ejec
            from dual;
         exception when others then
            vdia_ejec := null;
            --DBMS_OUTPUT.put_line('error en calcular dia se la semana  '||sqlerrm  );
        end;
     

      begin
                -- SELECT TO_CHAR(sysdate,'D') AS day_week FROM dual;
            select to_char(sysdate+pndate,'D')  ---, 'NLS_DATE_LANGUAGE=SPANISH' ))
            INTO VNO_DIA2
            from dual;
         exception when others then
            VNO_DIA2 := null;
           --DBMS_OUTPUT.put_line('error en calcular NUmero se la semana  '||sqlerrm  );
        end;

     --DBMS_OUTPUT.put_line('Paso valida dia de ejecucion: ' ||jump.pidm||'-'||vdia_ejec||'->>'||vdiasem||'-'||VNO_DIA2);

--------recupero materia padre e hijo---de mako
        begin

        select DISTINCT SZTMACO_MATHIJO, SZTMACO_MATPADRE
             INTO     vmateriah,vmateriap
        from sztmaco
        where 1=1
         AND  SZTMACO_MATHIJO =  (jump.materia);
         --and  SZTMACO_CAMP_CODE  = vcampus
         --and  SZTMACO_LEVL_CODE  = vnivel;


        exception when others then

            begin
               select DISTINCT SZTMACO_MATHIJO, SZTMACO_MATPADRE
                     INTO     vmateriah,vmateriap
                from sztmaco
                where 1=1
                 AND  SZTMACO_MATHIJO =  (jump.materia);
               
                 --and  SZTMACO_CAMP_CODE  in ('UTL', 'UVE');
             exception when others then
                  verror  := 'no se pudo obtener materia padre -hijo  '|| jump.materia||'-'||vcampus;
             end;



        end;


  IF jump.code = 'EXTR'  THEN

  -- la parte del periodo Y LA FECHA DE INICIO  ya esta calculada arriba para todos la que  escogio el alumno--
  --vptrm
  --vfini

         --------buca el periodo que le coresponde segun la parte del periodo y esa seva como parametroi de FEcha INI
         begin
                 select *
                         INTO   vperiodo
                    from (
                        SELECT DISTINCT sobptrm_term_code codigo --, sobptrm_start_date --,   SPRIDEN_PIDM PIDM,SOBPTRM_PTRM_CODE,SOBPTRM_START_DATE

                                  FROM  sobptrm so, spriden
                                       WHERE  1=1
                                      --   AND   trunc(sysdate+0) between to_char(sobptrm_start_date,'dd/MM/YYYY') and to_char(sobptrm_end_date,'dd/MM/YYYY')
                                              --and SOBPTRM_PTRM_CODE = '1'
                                              and  SUBSTR (SO.SOBPTRM_TERM_CODE, 5, 1) = '8'
                                              AND  SUBSTR (SO.SOBPTRM_TERM_CODE, 5, 2) IN (81,82,83  )
                                             and substr(SO.sobptrm_term_code,1,2)   = SUBSTR(F_GETSPRIDENID(jump.pidm),1,2)
                                             and SO.SOBPTRM_END_DATE  >= sysdate
                                             AND SO.SOBPTRM_PTRM_CODE  = vptrm
                                             AND SO.SOBPTRM_START_DATE  = vfini
                                             order by 1 desc

                          ) data
                          where 1=1
                          and rownum <= 1;

               -- vperiodo :=  vperiodo;
                ---nueva regla que se dio en la junta del dia 22/02/021  VictorR y Fernando
                -- para los casos de EXTR y TISU si lleva la fecha de inicio de la parte del periodo glovicx

               vfini2 :=  vfini;

           exception when others then
          vperiodo := null;
          vfini2     := vfini;
          DBMS_OUTPUT.put_line('error en calcular el periodo y finicio EXTR:  '|| sqlerrm);
          end;

 ELSIF  jump.code = 'TISU'  THEN
 
    begin
         select *
                 INTO   vperiodo
             from (
                SELECT DISTINCT sobptrm_term_code codigo --, sobptrm_start_date --,   SPRIDEN_PIDM PIDM,SOBPTRM_PTRM_CODE,SOBPTRM_START_DATE

                          FROM  sobptrm so, spriden
                               WHERE  1=1
                              --   AND   trunc(sysdate+0) between to_char(sobptrm_start_date,'dd/MM/YYYY') and to_char(sobptrm_end_date,'dd/MM/YYYY')
                                      --and SOBPTRM_PTRM_CODE = '1'
                                      and  SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                                      AND  SUBSTR (SOBPTRM_TERM_CODE, 5, 2) IN (84,85,86)
                                     and substr(sobptrm_term_code,1,2)   = SUBSTR(F_GETSPRIDENID(jump.pidm),1,2)
                                     and SOBPTRM_END_DATE  >= sysdate
                                     AND SO.SOBPTRM_PTRM_CODE  = vptrm
                                     AND SO.SOBPTRM_START_DATE  = vfini

                                     order by 1 desc

                  ) data
                  where 1=1
                  and rownum <2;

     vperiodo := vperiodo;
       ---nueva regla que se dio en la junta del dia 22/02/021  VictorR y Fernando
        -- para los casos de EXTR y TISU si lleva la fecha de inicio de la parte del periodo glovicx

       vfini2 :=  vfini;

    exception when others then
      vperiodo := null;
      vfini2     := vfini;
      --DBMS_OUTPUT.put_line('error en calcular el periodo y finicio TISU:  '|| sqlerrm);
      end;


ELSE
    ---aqui entran las NIVELACIONES GRAL DE UTL Y LATAM-------GLOBAL NUEVAS
       /*
           regla de acuerdo junta 02 oct 2020 siempre se ve va poner la primer parte de periodo del inicio del ciclo
              para cualquier caso sera L01, M01m A01
        */
        
   
   IF jump.code = 'DTMA'  THEN  -- se ontiene la fecha de inicia cientifica glovicx 16.01.2025
       
          begin
                 SELECT DISTINCT SO.sobptrm_term_code codigo, SO.sobptrm_start_date, SO.SOBPTRM_END_DATE --,   SPRIDEN_PIDM PIDM,SOBPTRM_PTRM_CODE,SOBPTRM_START_DATE
                       INTO   vperiodo , vfini2, VFFIN
                          FROM  sobptrm so
                               WHERE  1=1
                               AND   trunc(sysdate+0) between to_char(sobptrm_start_date,'dd/MM/YYYY') and to_char(sobptrm_end_date,'dd/MM/YYYY')
                                  and  SOBPTRM_PTRM_CODE  = vptrm
                               and  SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '7'
                               and substr(sobptrm_term_code,1,2)   = SUBSTR(F_GETSPRIDENID(jump.pidm),1,2);

             exception when others then
                  vperiodo := null;
                  vfini2     := null;
                  --DBMS_OUTPUT.put_line('error en calcular el periodo y finicio  NIVE'|| sqlerrm);
             end;
         --DBMS_OUTPUT.put_line('saliendo periodo y finicio DTMA: '|| vperiodo||'-'||vfini2  );
        
   
        
   else
             IF vnivel = 'LI'  then
               vptrm := 'L01';
               elsif  vnivel = 'MA'  then
              vptrm := 'M01';
              elsif   vnivel = 'MS'  then
                vptrm := 'A01';
              elsif   vnivel = 'BA'  then
                vptrm := 'B01';
              end if;


     begin
         SELECT DISTINCT sobptrm_term_code codigo, sobptrm_start_date --,   SPRIDEN_PIDM PIDM,SOBPTRM_PTRM_CODE,SOBPTRM_START_DATE
               INTO   vperiodo , vfini2
                          FROM  sobptrm so
                       WHERE  1=1
                       AND   trunc(sysdate+0) between to_char(sobptrm_start_date,'dd/MM/YYYY') and to_char(sobptrm_end_date,'dd/MM/YYYY')
                              and SOBPTRM_PTRM_CODE = '1'
                              and  SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                             and substr(sobptrm_term_code,1,2)   = SUBSTR(F_GETSPRIDENID(jump.pidm),1,2);

     exception when others then
          vperiodo := null;
          vfini2     := null;
          --DBMS_OUTPUT.put_line('error en calcular el periodo y finicio'|| sqlerrm);
     end;
    end if;
    

       BEGIN

        select DISTINCT 'Y'
            into valida_ingl
          from zstpara
                     where 1=1
                      and ZSTPARA_PARAM_ID = vcampus
                      and ZSTPARA_MAPA_ID like ('%COES_INGLES%');
         exception when others then
         valida_ingl := 'N';
       END;

      if valida_ingl = 'Y' then
         vperiodo := vperiodo;

        elsif  vnivel = 'MS'  then

            vperiodo := vperiodo;
            
        elsif  vnivel = 'BA'  then  ---para bachillerato se queda igual el periodo como sale en el query
        
             vperiodo := vperiodo;
        else
        
            vperiodo :=  '01'||substr(vperiodo,3,6); --- revisar si para internancional se queda igual ??
      end if;


END IF;


  --DBMS_OUTPUT.put_line('XX en calcular el periodo y finicio:  '||jump.pidm || '-'||  vfini2 ||'-'||vmateriap  );
        ---------obtenemos el short_name
        begin
        select  BANINST1.f_get_short_name (vptrm,vperiodo, vmateriap, vfini2)
        INTO vshort_name
        from dual;
         exception when others then
                --DBMS_OUTPUT.put_line('ERROR  al calcular shorname');
                vshort_name := null;
                verror := 'No pudo generar shortname';
         end;

-----hay que buscar el id  y pidm del profesor que es el titular de la materia
begin

  select distinct ZSTPARA_PARAM_VALOR matricula_profe, fget_pidm( ZSTPARA_PARAM_VALOR )  pidm_profe
      INTO  id_profesor,  pidm_prof
    from ZSTPARA
    where ZSTPARA_MAPA_ID = 'DOCENTE_NIVELAC'
    and  ZSTPARA_PARAM_ID =  vmateriap
    and rownum < 2;


    exception when others then
     id_profesor:= null;
     pidm_prof  := null;
      --DBMS_OUTPUT.PUT_LINE(' NO --EXISTE profesor  MP_>'||vmateriap||'  -MT>: '|| jump.materia);
      ---SE AGREGO ESTA VALIDACION PARA QUE NO ESTE LLENANDO LA TABLA DE BITACOTA N VECES EL MISMO REG.GLOVICX 29/06/021
--      begin
--        select COUNT(1)
--         INTO VEXISTE
--        FROM  TBITSIU
--        WHERE 1=1
--        AND PIDM  = vpidm
--        AND SEQNO = vseqno   ;
--      EXCEPTION WHEN OTHERS THEN
--        VEXISTE := 0;
--      END;
--
--      IF VEXISTE = 0 THEN
--       -- VBITACORA := F_BITSIU(  F_GetSpridenID(vpidm),vpidm,'NIVE_AULA',vseqno,NULL,NULL,NULL,SYSDATE,substr(vmateriap,1,14),NULL,NULL,NULL,NULL,
--         --                           NULL,NULL,NULL,NULL,'NO -- EXISTE profesor  MP',NULL,NULL,NULL,NULL,NULL );
--      NULL;
--      
--      END IF;

    end;

        IF  jump.code = 'EXTR' AND vcampus in ('UNI','UIN')   THEN
                  --valida si ya existe la materia insertada en el grupo-- si existe se la salta y solo inserta sztume ESTA ES SOLO extra y UNI GLOVICX 01/02/021
                  begin

                    Select  1--NVL(MAX(gp.SZTGPME_NIVE_SEQNO),1)  seqno_nive
                       into  VSZTGPME
                    from SZTGPME gp
                    where 1=1
                    and gp.SZTGPME_TERM_NRC = vmateriap||'01'
                     and gp.SZTGPME_TERM_NRC_COMP =  vperiodo
                    and GP.SZTGPME_NO_REGLA  = 99
                    AND GP.SZTGPME_START_DATE  =  vfini2
                    AND GP.SZTGPME_NIVE_SEQNO  = ( SELECT MAX( G2.SZTGPME_NIVE_SEQNO )
                                                         FROM SZTGPME G2
                                                             WHERE 1=1
                                                                and gp.SZTGPME_TERM_NRC = G2.SZTGPME_TERM_NRC
                                                                and gp.SZTGPME_TERM_NRC_COMP =  G2.SZTGPME_TERM_NRC_COMP
                                                                and GP.SZTGPME_NO_REGLA  = 99 )  ;
                exception when others then
                  VSZTGPME := 0;
                end;

         ELSIF   jump.code = 'DTMA'   THEN
            dbms_output.put_line('dentro de DTMA SZTGPME ');
                 begin

                    Select  1--NVL(MAX(gp.SZTGPME_NIVE_SEQNO),1)  seqno_nive
                       into  VSZTGPME
                    from SZTGPME gp
                    where 1=1
                    and gp.SZTGPME_TERM_NRC = vmateriap||'01'
                    and SUBSTR(gp.SZTGPME_TERM_NRC_COMP,3,6) =  SUBSTR(vperiodo,3,6)
                    and gp.SZTGPME_PTRM_CODE    = vptrm 
                    and GP.SZTGPME_NO_REGLA  = 99
                    AND GP.SZTGPME_NIVE_SEQNO  = ( SELECT MAX( G2.SZTGPME_NIVE_SEQNO )
                                                                             FROM SZTGPME G2
                                                                             WHERE 1=1
                                                                            and gp.SZTGPME_TERM_NRC = G2.SZTGPME_TERM_NRC
                                                                            and gp.SZTGPME_TERM_NRC_COMP =  G2.SZTGPME_TERM_NRC_COMP
                                                                            and gp.SZTGPME_PTRM_CODE  = g2.SZTGPME_PTRM_CODE 
                                                                            and GP.SZTGPME_NO_REGLA  = 99   )  ;
                exception when others then
                  VSZTGPME := 0;
                  dbms_output.put_line('ERROOOR  dentro de DTMA SZTGPME '||vmateriap||'-'||vperiodo||'-'|| vptrm  );
                end;
          dbms_output.put_line('saliendo  de DTMA SZTGPME '|| VSZTGPME );
         

          ELSE  --AQUI ES NIVES
                --valida si ya existe la materia insertada en el grupo-- si existe se la salta y solo inserta sztume ESTA SECCION ES PARA TODOS
                  begin

                    Select  1--NVL(MAX(gp.SZTGPME_NIVE_SEQNO),1)  seqno_nive
                       into  VSZTGPME
                    from SZTGPME gp
                    where 1=1
                    and gp.SZTGPME_TERM_NRC = vmateriap||'01'
                    and SUBSTR(gp.SZTGPME_TERM_NRC_COMP,3,6) =  SUBSTR(vperiodo,3,6)
                    and GP.SZTGPME_NO_REGLA  = 99
                    AND GP.SZTGPME_NIVE_SEQNO  = ( SELECT MAX( G2.SZTGPME_NIVE_SEQNO )
                                                                             FROM SZTGPME G2
                                                                             WHERE 1=1
                                                                            and gp.SZTGPME_TERM_NRC = G2.SZTGPME_TERM_NRC
                                                                            and gp.SZTGPME_TERM_NRC_COMP =  G2.SZTGPME_TERM_NRC_COMP
                                                                            and GP.SZTGPME_NO_REGLA  = 99   )  ;
                exception when others then
                  VSZTGPME := 0;
                end;

          END IF;

  -- se hace el ajuste de fecha de global
  IF   jump.code = 'NIVG'  then

   BEGIN
    select TO_DATE(TO_CHAR(TO_DATE(vfini,'MM/dd/YYYY'), 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH'), 'DD/MM/YYYY')
    INTO vfini
    from dual ;

    select TO_DATE(TO_CHAR(TO_DATE(vffin,'MM/dd/YYYY'), 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH'), 'DD/MM/YYYY')
    INTO vffin
    from dual ;
    EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(' ERROE EN CAMBIO DE FECHAS INGLES '|| SQLERRM);
    END;

  END IF;
/*
 DBMS_OUTPUT.PUT_LINE(' EXISTE O NO EL GRUPO INICIAL  '||VSZTGPME||'-'||vmateriap||'01'||'-'||jump.pidm||'-'||vperiodo||'-'||VPAGO_VALIDA|| '->'|| verror||'<<'|| vshort_name||'-*'||vfini||'-*'|| vffin||
                           '--'||TRIM(vdia_ejec)||'--'|| TRIM(vdiasem) );

*/


IF verror = 'EXITO'  and vperiodo is not null and vshort_name is not null  THEN
-- lo primero que hay que validar si los registros estan en la semana de fechas inicio y fino mejor dicho si el sysdate
-- esta entre esas fechas si si esta o cae entonces sigue sino se elimina
    IF  upper(VPAGO_VALIDA) = 'PAGADO' THEN
       --DBMS_OUTPUT.put_line('Paso valida PAGADO2: ' ||jump.pidm||'--'||VPAGO_VALIDA|| ' -fechas sysdate ' );
        --IF  to_char(vsysdate,'DD/MM/YYYY') between  vfini and vffin then
        IF  trunc(sysdate)+0 between  vfini and vffin then
         --DBMS_OUTPUT.put_line('Paso valida fecha ejecuta DIA HOY: ' ||jump.pidm||'--'||vfini||'-'||vffin);
          ----VALIDA QUE EL DIA QUE ESCOGIO EL ALUMNO SEA EL DIA DE HOY
           --DBMS_OUTPUT.put_line('ANTESSSS  valida DIASXX: ' ||jump.pidm||'--'|| TRIM(vdia_ejec) ||'-'||TRIM(vdiasem));
           IF   TRIM(vdia_ejec) = TRIM(vdiasem)  THEN
                 --DBMS_OUTPUT.put_line('Paso valida DIASXX: ' ||jump.pidm||'--'|| vdia_ejec ||'-'||vdiasem);
             --SI YA PASO TODAS LAS VALIDACIONES HASTA AQUI SE PUEDE USAR UNA BANDERA O
             ---- AQUI PONER LA SINCRONIZACION O INSERTS A LAS TABLAS DE SINCRONIZACION. mediante funciones locales
             ---vperiodo va en lugar de
              IF   VSZTGPME = 1 then
                 vsalida_gpo  :='EXITO';
              --   vsalida_mast  :='EXITO';
              ELSE
              vsalida_gpo :=  BANINST1.PKG_NIVE_AULA.f_inst_SZTGPME (vmateriap, vmateriah,vptrm,vperiodo,vnivel,vcampus,vshort_name,vperiodo, vfini2);
                --DBMS_OUTPUT.put_line('INSERTA--CON TODO, 1 : ' ||jump.pidm||'--'||vsalida_gpo);
              END IF;

              IF  vsalida_gpo = 'EXITO' AND  pidm_prof is not null  then

                vsalida_mast := BANINST1.PKG_NIVE_AULA.f_inst_SZSGNME (vmateriap, pidm_prof,vptrm, vfini2, vperiodo );
                  --DBMS_OUTPUT.put_line('INSERTA--CON PROFE, 1 : ' ||jump.pidm||'--'||vsalida_gpo||'-'||vsalida_mast);
              else
                 vsalida_mast  :='Error'; ----se agrego esta else para que setee la variable y no pase el sig insert glovicx 01/06/021
              END IF;

            ----------solo inserta el alumno el grupo y maestro ya existen este siempre lo va ejecutar si o si
                     IF   vsalida_mast  = 'EXITO' and pidm_prof is not null  THEN
                      vsalida_alum :=     BANINST1.PKG_NIVE_AULA.f_inst_SZSTUME (vmateriap  , jump.pidm,vmatricula , vfini2, vperiodo,vseqno, vstatus) ;
                       --DBMS_OUTPUT.put_line('INSERTO EN ZSRUME 1  : ' ||jump.pidm||'--'|| vmateriap ||'-'||vfini2||'-'|| vperiodo||' >= '||vseqno);
                     END IF;

           else
                --DBMS_OUTPUT.put_line('FUERA valida DIAS: ' ||jump.pidm||'--'|| vdia_ejec ||'-'||vdiasem||'-'|| VNO_DIA2||' >= '||VNO_DIA||'--'||vfini||'-'||vffin);
                  ---aqui debe de entrar cuando sea la misma semana pero el dia ya haya pasado
                  --ejemplo SI lo pidio para el dia Martes y hoy es jueve lo debe dejar pasar
                  -- ejemplo NO  lo pidio para el dia jueves y hoy es martes no lo debe dejar pasar
                  IF VNO_DIA2 >= VNO_DIA  THEN

                        IF   VSZTGPME = 1 then
                             vsalida_gpo  :='EXITO';
                          --   vsalida_mast  :='EXITO';
                          ELSE
                          vsalida_gpo :=  BANINST1.PKG_NIVE_AULA.f_inst_SZTGPME (vmateriap, vmateriah,vptrm,vperiodo,vnivel,vcampus,vshort_name,vperiodo, vfini2);
                            --DBMS_OUTPUT.put_line('INSERTA--CON TODO, 1 : ' ||jump.pidm||'--'||vsalida_gpo);
                        END IF;

                          IF  vsalida_gpo = 'EXITO' AND  pidm_prof is not null  then

                            vsalida_mast := BANINST1.PKG_NIVE_AULA.f_inst_SZSGNME (vmateriap, pidm_prof,vptrm, vfini2, vperiodo );
                               --DBMS_OUTPUT.put_line('INSERTA--CON PROFE, 2 : ' ||jump.pidm||'--'||vsalida_gpo||'-'||vsalida_mast);
                          else
                             vsalida_mast  :='Error'; ----se agrego esta else para que setee la variable y no pase el sig insert glovicx 01/06/021
                          END IF;

                              ----este caso tambien siempre lo hace si o si  para este else
                         IF   vsalida_mast  = 'EXITO' and pidm_prof is not null  THEN
                          vsalida_alum :=     BANINST1.PKG_NIVE_AULA.f_inst_SZSTUME (vmateriap  , jump.pidm,vmatricula ,vfini2, vperiodo,vseqno,vstatus) ;
                          --DBMS_OUTPUT.put_line('INSErTO EN ZSTUME 2  : ' ||jump.pidm||'--'|| vmateriap ||'-'||vfini2||'-'|| vperiodo||' >= '||vseqno);
                         END IF;


                    end if; --IF dias XX




             END IF; -- dia LUNES=LUNES


        else  ------para todos los que caen despues de la fechs del rango

          --DBMS_OUTPUT.put_line('Fuera de rango valida fecha ejecuta: ' ||jump.pidm||'--'||vfini||'-'||vffin||' -fech_sysd-' );
        ----si no entre sl if es por que las fecha del dia de hoy no coincide con el rango
         -- se puede evaluar aqui que sysdate sea menor a la fecha de inicio si es correcto.
         -- tambien desde aqui ya puedo mandar los insertsss a las tablas preintermedias
           IF trunc(sysdate)+pndate  >= vfini then  -- quiere decir que ya pago pero se paso su dia de inicio

                IF   VSZTGPME = 1 then
                         vsalida_gpo  :='EXITO';
                         vsalida_mast  :='EXITO';
                 elsif  pidm_prof is not null  then

                      vsalida_gpo    :=     BANINST1.PKG_NIVE_AULA.f_inst_SZTGPME (vmateriap, vmateriah,vptrm,vperiodo,vnivel,vcampus,vshort_name,vperiodo, vfini2);
                     --         DBMS_OUTPUT.put_line('INSERTA--CON PAGO, fechas 2: ' ||jump.pidm||'--'||vsalida_gpo);
                         IF vsalida_gpo = 'EXITO'  and pidm_prof is not null THEN
                          vsalida_mast :=     BANINST1.PKG_NIVE_AULA.f_inst_SZSGNME (vmateriap  , pidm_prof,vptrm, vfini2, vperiodo );
                               --DBMS_OUTPUT.put_line('INSERTA--CON PROFE, 2 : ' ||jump.pidm||'--'||vsalida_gpo||'-'||vsalida_mast);
                          else
                          vsalida_mast  :='Error'; ----se agrego esta else para que setee la variable y no pase el sig insert glovicx 01/06/021
                         END IF;

                 end if;
                                ----este caso tambien siempre lo hace si o si  para este else
                         IF   vsalida_mast  = 'EXITO'  and pidm_prof is not null THEN
                          vsalida_alum :=     BANINST1.PKG_NIVE_AULA.f_inst_SZSTUME (vmateriap  , jump.pidm,vmatricula ,vfini2, vperiodo,vseqno,vstatus) ;
                         END IF;




           end if;


        END IF;  -- aqui termina sysdata between fechaini y ffin

    else --- AQUI CAEN LOS QUE NO ESTAN PAGADOS



     ---ESTA SECCION ES SOLO PARA UIN INSURGENTE QUE ELLOS NO PAGAN Y SE LE DEBE DE SINCRONIZAR AL AULA REGLA DE VIC RMZ EN JUNTA 27/05/021 GLOVICX 31/05/021


        IF upper(VPAGO_VALIDA) != 'CANCELADO' AND vcampus = 'UIN'   THEN
          IF  trunc(sysdate)+pndate between  vfini and vffin then
            -- DBMS_OUTPUT.put_line('UIN--Paso valida fecha ejecuta: ' ||jump.pidm||'--'||vfini||'-'||vffin||'-'||vstatus);
          ----VALIDA QUE EL DIA QUE ESCOGIO EL ALUMNO SEA EL DIA DE HOY
            IF    TRIM(vdia_ejec) = TRIM(vdiasem)   THEN
               --  DBMS_OUTPUT.put_line('UIN--Paso valida DIASXX: ' ||jump.pidm||'--'|| vdia_ejec ||'-'||vdiasem);
             --SI YA PASO TODAS LAS VALIDACIONES HASTA AQUI SE PUEDE USAR UNA BANDERA O
             ---- AQUI PONER LA SINCRONIZACION O INSERTS A LAS TABLAS DE SINCRONIZACION. mediante funciones locales
             ---vperiodo va en lugar de
                  IF   VSZTGPME = 1 then
                     vsalida_gpo  :='EXITO';
                     vsalida_mast  :='EXITO';
                  elsif  pidm_prof is not null  then
                    vsalida_gpo    :=     BANINST1.PKG_NIVE_AULA.f_inst_SZTGPME (vmateriap, vmateriah,vptrm,vperiodo,vnivel,vcampus,vshort_name,vperiodo, vfini2);
                    --         DBMS_OUTPUT.put_line('UIN--INSERTA--CON TODO, 1 : ' ||jump.pidm||'--'||vsalida_gpo);
                     IF vsalida_gpo = 'EXITO'  and pidm_prof is not null THEN
                      vsalida_mast :=     BANINST1.PKG_NIVE_AULA.f_inst_SZSGNME (vmateriap  , pidm_prof,vptrm, vfini2, vperiodo );
                           --DBMS_OUTPUT.put_line('INSERTA--CON PROFE, 4 : ' ||jump.pidm||'--'||vsalida_gpo||'-'||vsalida_mast);
                      else
                      vsalida_mast  :='Error'; ----se agrego esta else para que setee la variable y no pase el sig insert glovicx 01/06/021
                     END IF;
                   end if;
                 ----------solo inserta el alumno el grupo y maestro ya existen este siempre lo va ejecutar si o si
                     IF   vsalida_mast  = 'EXITO' and pidm_prof is not null  THEN
                      vsalida_alum :=     BANINST1.PKG_NIVE_AULA.f_inst_SZSTUME (vmateriap  , jump.pidm,vmatricula , vfini2, vperiodo,vseqno, vstatus) ;
                     END IF;

            ELSE
                --  DBMS_OUTPUT.put_line('UIN--FUERA valida DIAS: ' ||jump.pidm||'--'|| vdia_ejec ||'-'||vdiasem||'-'|| VNO_DIA2||' >= '||VNO_DIA||'-'||vstatus);
                  ---aqui debe de entrar cuando sea la misma semana pero el dia ya haya pasado
                  --ejemplo SI lo pidio para el dia Martes y hoy es jueve lo debe dejar pasar
                  -- ejemplo NO  lo pidio para el dia jueves y hoy es martes no lo debe dejar pasar
                  IF VNO_DIA2 >= VNO_DIA  THEN

                       IF   VSZTGPME = 1 then
                         vsalida_gpo  :='EXITO';
                         vsalida_mast  :='EXITO';
                       elsif  pidm_prof is not null  then
                        vsalida_gpo    :=     BANINST1.PKG_NIVE_AULA.f_inst_SZTGPME (vmateriap, vmateriah,vptrm,vperiodo,vnivel,vcampus,vshort_name,vperiodo, vfini2);
                          --    DBMS_OUTPUT.put_line('UIN__INSERTA--CON PAGO, fechas 2: ' ||jump.pidm||'--'||vsalida_gpo||'-'||vstatus);
                         IF vsalida_gpo = 'EXITO' and pidm_prof is not null  THEN
                          vsalida_mast :=     BANINST1.PKG_NIVE_AULA.f_inst_SZSGNME (vmateriap  , pidm_prof,vptrm, vfini2, vperiodo );
                               --DBMS_OUTPUT.put_line('INSERTA--CON PROFE, 5 : ' ||jump.pidm||'--'||vsalida_gpo||'-'||vsalida_mast);
                         else
                         vsalida_mast  :='Error'; ----se agrego esta else para que setee la variable y no pase el sig insert glovicx 01/06/021
                         END IF;


                       end if;
                                ----este caso tambien siempre lo hace si o si  para este else
                         IF vsalida_mast  = 'EXITO' and pidm_prof is not null  THEN
                          vsalida_alum :=     BANINST1.PKG_NIVE_AULA.f_inst_SZSTUME (vmateriap  , jump.pidm,vmatricula ,vfini2, vperiodo,vseqno,vstatus) ;
                         END IF;


                   END IF;
            END IF;


           END IF;


        END IF;
     END IF;

--DBMS_OUTPUT.put_line('ERROR CON ALGUNA VARIABLE ' ||jump.pidm||'--'||verror);
END IF; -- NO HUBO ERRORRS verror  ES EXITO

--DBMS_OUTPUT.put_line('FINALIZA EL ALUMNO ' ||jump.pidm||'--'||vseqno||'-'||vstatus||'-'|| verror);
end loop;


COMMIT;
---------SE EJECUTA EL NUEVO PROCESO PARA ALINEAR LOS SEQNOS, GRUPO, PROFE, ALUMNO GLOVICX 21/11/2023 PROYECTO DE ALEX BAJAS CALIFICACIONES NIVE
PKG_NIVE_AULA.P_ALINEA_SEQNOS;

exception when others then
verror := SQLERRM;
--ROLLBACK;
--VBITACORA := F_BITSIU( 'P_MAIN',PPIDM,'NIVE_AULA',vseqno,null,vptrm,vfini2,SYSDATE,substr(vmateriap,1,14),null,vperiodo,NULL,NULL,
  --                             NULL,NULL,NULL,NULL,'ERROR GRAL P_MAIN',VERROR,NULL,NULL,NULL,NULL );

end  p_main;



PROCEDURE P_MAIL_HTML IS

--
--proceso que crea y envia un emil  en formato  HTML a una lista de usuaios es un proceso temporal que se va ejecutar mediante un job
-- glovicx    22/04/021----
--

     p_to            varchar2(50);--:=  'vsanchro@utel.edu.mx';--'emontadi@utel.edu.mx ';'vramirlo@utel.edu.mx '
    p_from           varchar2(50):= 'victor.ramirez@s4learning.com';
    p_subject        varchar2(50):= 'Sincronización:';
    p_text           varchar2(50):= 'texto normal';
    p_html           varchar2(32767):= 'texto HTML';
    p_smtp_hostname  varchar2(50):= '10.1.47.12';
    p_smtp_portnum   varchar2(50):= '26';
    VERROR           VARCHAR2(200);


    l_boundary      varchar2(255) default 'a1b2c3d4e3f2g1';
    l_connection    utl_smtp.connection;
    l_body_html     clob := empty_clob;  --This LOB will be the email message
    l_offset        number;
    l_ammount       number;
    l_temp          varchar2(32767) default null;
    vbody          varchar2(6000);
    vseparador      varchar2(50);

cursor c_grupos is
  SELECT SUM (XX.cuenta) Grupos_enviados,
                       XX.estatus Estado_sync,
                        COUNT(XX.Total1) Total_sync,
                        XX.regla Regla
                --  INTO   vgpo_enviados,   vgpo_sync, vgpo_total_sync, vgpo_regla
                FROM
                (SELECT COUNT(SZTGPME_TERM_NRC) cuenta,
                    SZTGPME_NO_REGLA regla,
                    COUNT(SZTGPME_STAT_IND)Total1,
                    CASE WHEN
                    SZTGPME_STAT_IND = '0' THEN 'Pendientes'
                    WHEN
                    SZTGPME_STAT_IND = '1' THEN 'Sincronizados'
                    WHEN
                    SZTGPME_STAT_IND = '2' THEN 'Error'
                    WHEN
                    SZTGPME_STAT_IND = '5' THEN 'En validación'
                    END estatus
                    FROM SZTGPME
                    WHERE 1=1
                    AND SZTGPME_NO_REGLA IN (SELECT ZSTPARA_PARAM_VALOR
                                             FROM ZSTPARA
                                             WHERE 1=1
                                             AND ZSTPARA_MAPA_ID = 'MONITOR_SYNC')
                    GROUP BY SZTGPME_TERM_NRC, SZTGPME_NO_REGLA, SZTGPME_STAT_IND
                )XX
                WHERE 1=1
                GROUP BY XX.cuenta, XX.regla,XX.Total1, XX.estatus
                ORDER BY 4 ASC;


cursor c_profesor is
        SELECT COUNT(XX.cuenta) Docentes_enviados,
                     XX.estatus Estado_sync,
                     COUNT(XX.Total1) Total_sync,
                     XX.regla Regla
                     FROM
                     (SELECT SZSGNME_TERM_NRC cuenta,
                      SZSGNME_NO_REGLA regla,
                      SZSGNME_STAT_IND Total1,
                      CASE WHEN
                                SZSGNME_STAT_IND = '0' THEN 'Pendientes'
                                WHEN
                                SZSGNME_STAT_IND = '1' THEN 'Sincronizados'
                                WHEN
                                SZSGNME_STAT_IND = '2' THEN 'Error'
                                WHEN
                                SZSGNME_STAT_IND = '5' THEN 'En validación'
                      END estatus
                      FROM SZSGNME
                      WHERE 1=1
                      AND SZSGNME_NO_REGLA IN (SELECT ZSTPARA_PARAM_VALOR
                                             FROM ZSTPARA
                                             WHERE 1=1
                                             AND ZSTPARA_MAPA_ID = 'MONITOR_SYNC')
                      GROUP BY SZSGNME_TERM_NRC, SZSGNME_STAT_IND, SZSGNME_NO_REGLA
                      )XX
                      WHERE 1=1
                      GROUP BY XX.regla, XX.estatus, XX.Total1
                      ORDER BY 4 ASC;

cursor c_alumnos is
SELECT
SZSTUME_NO_REGLA regla,
CASE WHEN
        SZSTUME_STAT_IND = '0' THEN 'Pendientes'
        WHEN
        SZSTUME_STAT_IND = '1' THEN 'Sincronizados'
        WHEN
        SZSTUME_STAT_IND = '2' THEN 'Error'
        WHEN
        SZSTUME_STAT_IND = '5' THEN 'En validación'
END estatus,
count(*) Cantidad
FROM SZSTUME
WHERE 1=1
AND  SZSTUME_RSTS_CODE = 'RE'
AND SZSTUME_NO_REGLA IN (SELECT ZSTPARA_PARAM_VALOR
                     FROM ZSTPARA
                     WHERE 1=1
                     AND ZSTPARA_MAPA_ID = 'MONITOR_SYNC')
GROUP BY SZSTUME_NO_REGLA, SZSTUME_STAT_IND
order by 1,2;





cursor c_calificacion is
SELECT count(*)Calificacion_Alumno, decode (SZSTUME_PTRM,'1', 'Descargada', '0','En Espera') Estatus, SZSTUME_NO_REGLA Regla
       FROM SZSTUME
       WHERE 1=1
       AND SZSTUME_NO_REGLA IN  (SELECT ZSTPARA_PARAM_VALOR
                                                     FROM ZSTPARA
                                                     WHERE 1=1
                                                     AND ZSTPARA_MAPA_ID = 'MONITOR_SYNC_GR')
       and SZSTUME_PTRM is not null
       group by SZSTUME_PTRM, SZSTUME_NO_REGLA
       order by 3,1;



BEGIN
NULL;



vseparador := '<hr>    </hr>';

----------------------------------aqui empiza grupos-------------------
p_html:= '<html>
    <head>
        <title>Sincronización</title>
    </head>
    <body>
       <H1>Relación de estadísticas de Grupos,Docentes, Alumnos  </H1>
       '||chr(10)||chr(13);




vbody  := vbody|| '<table "width: 100%; height: 275px; border="1" >
  <tr>
    <th bgcolor="LightGray"  >Grupos   Enviados</th>
    <th bgcolor="LightGray" >Avance</th>
    <th bgcolor="LightGray" >Regla</th>
   </tr>
  '
  ;
for   jump in c_grupos loop

vbody  := vbody|| ' <tr>
        <td>'||jump.Grupos_enviados||'</td>
        <td>'||JUMP.Total_sync||'  '||JUMP.Estado_sync||'</td>
        <td>'||JUMP.REGLA||'</td>';
END loop;


vbody := vbody||  '</tr>
  <tr>
  <td>    </td>
  </tr>
</table>'||chr(10)||chr(13)||vseparador;

--------------------------------------------aqui empieza los profesores------------



vbody  := vbody|| '<table "width: 100%; height: 275px; border="1" >
  <tr>
    <th bgcolor="LightGray">Docentes Enviados</th>
    <th bgcolor="LightGray">Avance</th>
    <th bgcolor="LightGray">Regla</th>
   </tr>
  '
  ;
for   jump in c_profesor loop

vbody  := vbody|| ' <tr>
        <td>'||jump.Docentes_enviados||'</td>
        <td>'||JUMP.Total_sync||'  '||JUMP.Estado_sync||'</td>
        <td>'||JUMP.REGLA||'</td>';
END loop;


vbody := vbody||  '</tr>
  <tr>
  <td>    </td>
  </tr>
</table>'||chr(10)||chr(13)||vseparador;


----------------------------------------aqui empizan los alumnos-----------------------------



vbody  := vbody|| '<table "width: 100%; height: 275px; border="1">
  <tr>
    <th bgcolor="LightGray" > Regla</th>
    <th bgcolor="LightGray" >Estatus - Alumnos </th>
    <th bgcolor="LightGray">Cantidad</th>
   </tr>
  '
  ;


for   jump in c_alumnos loop

vbody  := vbody|| ' <tr>
        <td>'||jump.regla||'</td>
        <td>'||JUMP.estatus||'</td>
        <td>'||JUMP.cantidad||'</td>';
END loop;


vbody := vbody||  '</tr>
  <tr>
  <td>    </td>
  </tr>
</table>'||chr(10)||chr(13)||vseparador;

----------------------------------------aqui empizan las Calificaciones-----------------------------



vbody  := vbody|| '<table "width: 100%; height: 275px; border="1">
  <tr>
    <th bgcolor="LightGray" > Regla</th>
    <th bgcolor="LightGray" >Calificacion-Aluimno </th>
    <th bgcolor="LightGray">Estatus</th>
   </tr>
  '
  ;


for   jump in c_calificacion loop

vbody  := vbody|| ' <tr>
        <td>'||jump.regla||'</td>
        <td>'||JUMP.estatus||'</td>
        <td>'||JUMP.Calificacion_Alumno||'</td>';
END loop;


vbody := vbody||  '</tr>
  <tr>
  <td>    </td>
  </tr>
</table>'||chr(10)||chr(13)||vseparador;




p_html:=p_html|| vbody||chr(13)||  'ULTIMA EJECUCIÓN:'|| TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')||chr(13)||'
</body>
</html>
';


FOR NIN  IN (select ZSTPARA_PARAM_VALOR MAIL
                        from zstpara
                        WHERE 1=1
                        AND  ZSTPARA_MAPA_ID = 'SIU_MAIL_COPIA'
                        AND ZSTPARA_PARAM_ID = 'SYNCRO'
                        --and ZSTPARA_PARAM_SEC = 83
                        ORDER BY 1
                        )  LOOP

p_to := NIN.MAIL;

--DBMS_OUTPUT.PUT_LINE(' PROCESO -- ENVIA MAIL   '|| p_to );
 PKG_NIVE_AULA.P_ENVIA_MAIL(p_to  ,p_html    );

END LOOP;


EXCEPTION WHEN OTHERS THEN
    VERROR := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('ERROR GRAL ENVIA MAIL   '|| VERROR );


END P_MAIL_HTML;


PROCEDURE P_MAIL_NIVE_HTML IS

--
--proceso que crea y envia un emil  en formato  HTML  DE TODOS LOS ESTATUS DE LAS NIVELACIONES
-- glovicx   04/10/2021----
--

     p_to            varchar2(50);--:=  'vsanchro@utel.edu.mx';--'emontadi@utel.edu.mx ';'vramirlo@utel.edu.mx '
    p_from           varchar2(50):= 'victor.ramirez@s4learning.com';
    p_subject        varchar2(50):= 'Sincronización_NIVE:';
    p_text           varchar2(50):= 'texto normal';
    p_html           varchar2(32767):= 'texto HTML';
    p_smtp_hostname  varchar2(50):= '10.1.47.12';
    p_smtp_portnum   varchar2(50):= '26';
    VERROR           VARCHAR2(200);


    l_boundary      varchar2(255) default 'a1b2c3d4e3f2g1';
    l_connection    utl_smtp.connection;
    l_body_html     clob := empty_clob;  --This LOB will be the email message
    l_offset        number;
    l_ammount       number;
    l_temp          varchar2(32767) default null;
    vbody          varchar2(8000);
    vseparador      varchar2(50);
    vfini2          varchar2(20);
    vperiodo        VARCHAR2(20);
    ACCS_PIDM       number;
    ACCS_SEQNO      number:=0;
    vcount_gpo      number:=0;
    vcount_profe_ok    number:=0;
    vcount_profe_NO    number:=0;
    vcount_alum_OK     number:=0;
    vcount_alum_NO    number:=0;
    vcount_alum       number:=0;
    vestatus_0        number:=0;
    vestatus_1        number:=0;
    vestatus          number:=0;
    vestatus_E        number:=0;
    VGPO_MATERIA      number:=0;
    VGPO_ESTATUS      number:=0;
    VGPO_ESTATUS_0    number:=0;
    VGPO_ESTATUS_1    number:=0;
    VGPO_ESTATUS_E    number:=0;
    VGPO_FINI         varchar2(20);
    VGPO_MATERIA_OK    number:=0;
    VGPO_MATERIA_no    number:=0;
    vmateriap          varchar2(20);
    vbody_gpo          varchar2(8000);
    vbody_prof         varchar2(8000);
    VPRFE_MATERIA      number:=0;
    VPRFE_MATERIA_OK   number:=0;
    VPRFE_MATERIA_NO   number:=0;
    VPRFE_ESTATUS      number:=0;
    VPRFE_ESTATUS_0    number:=0;
    VPRFE_ESTATUS_1    number:=0;
    VPRFE_ESTATUS_E    number:=0;
    no_profesor        number:=0;
    vno_mate_prof      varchar2(2000);

cursor c_ACCESORIO_NIVE is
  SELECT DATOS2.SEQNO num_acc, DATOS2.PIDM pidm,datos2.code,datos2.materia, datos2.FECHA_INICIOS
FROM (
SELECT DATOS.SEQNO, DATOS.PIDM, DATOS.MATERIA,DATOS.CODE,
     TO_DATE ( ( select  DISTINCT SUBSTR(SVRSVAD_ADDL_DATA_DESC,1,decode(INSTR(SVRSVAD_ADDL_DATA_DESC,'-AL-',1),0,10, INSTR(SVRSVAD_ADDL_DATA_DESC,'-AL-',1))-1) as descrt
            from svrsvpr v,SVRSVAD VA
            where 1=1
            AND  SVRSVPR_PROTOCOL_SEQ_NO in (DATOS.SEQNO)
              AND  SVRSVPR_PIDM    IN (DATOS.PIDM)
               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
             and va.SVRSVAD_ADDL_DATA_SEQ = '7'
              ) ,'DD/MM/YYYY') FECHA_INICIOS
FROM (
select v.SVRSVPR_PROTOCOL_SEQ_NO as seqno, v.SVRSVPR_PIDM pidm,  v.SVRSVPR_ACCD_TRAN_NUMBER  tranum
,va.SVRSVAD_ADDL_DATA_CDE materia
,v.SVRSVPR_TERM_CODE periodo
,v.SVRSVPR_SRVC_CODE   code
from SVRSVPR  v, SVRSVAD va
WHERE 1=1
and v.SVRSVPR_SRVC_CODE in ('NIVE')
and v.SVRSVPR_SRVS_CODE in ('PA')
and v.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
and va.SVRSVAD_ADDL_DATA_SEQ in (2)
and V.SVRSVPR_RECEPTION_DATE  >= ('09/11/2020')--inicio en produccion
UNION
select v.SVRSVPR_PROTOCOL_SEQ_NO as seqno, v.SVRSVPR_PIDM pidm,  v.SVRSVPR_ACCD_TRAN_NUMBER  tranum
,va.SVRSVAD_ADDL_DATA_CDE   materia ,
v.SVRSVPR_TERM_CODE periodo,
v.SVRSVPR_SRVC_CODE   code
from SVRSVPR  v, SVRSVAD va
WHERE 1=1
and v.SVRSVPR_SRVC_CODE in ('EXTR','TISU')
and v.SVRSVPR_SRVS_CODE in ('PA')
and v.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
and va.SVRSVAD_ADDL_DATA_SEQ in (2)
and V.SVRSVPR_RECEPTION_DATE  >= ('11/12/2020')--inicio en produccion
and v.SVRSVPR_CAMP_CODE   != 'UIN'
union
select v.SVRSVPR_PROTOCOL_SEQ_NO as seqno, v.SVRSVPR_PIDM pidm,  v.SVRSVPR_ACCD_TRAN_NUMBER  tranum
,va.SVRSVAD_ADDL_DATA_CDE   materia ,
v.SVRSVPR_TERM_CODE periodo,
v.SVRSVPR_SRVC_CODE   code
from SVRSVPR  v, SVRSVAD va
WHERE 1=1
and v.SVRSVPR_SRVC_CODE in ('EXTR')
and v.SVRSVPR_SRVS_CODE != ('CA')
and v.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
and va.SVRSVAD_ADDL_DATA_SEQ in (2)
and V.SVRSVPR_RECEPTION_DATE  >= ('31/05/2021')--inicio en produccion
and v.SVRSVPR_CAMP_CODE   = 'UIN'
) DATOS
) DATOS2
WHERE 1=1
AND trunc(DATOS2.FECHA_INICIOS) between  trunc(sysdate)-5  and trunc(sysdate)+1
ORDER BY 1 DESC
;




BEGIN
NULL;







vseparador := '<hr>    </hr>';

----------------------------------aqui empiza grupos-------------------
p_html:= '<html>
    <head>
        <title>Sincronización NIVE</title>
    </head>
    <body>
       <H1>Relación de estadísticas de Grupos,Docentes, Alumnos
            NIVELACIONES </H1>
       '||chr(10)||chr(13);



FOR ACCS IN c_ACCESORIO_NIVE  LOOP
IF ACCS.code = 'EXTR'  THEN

         --------buca el periodo que le coresponde segun la parte del periodo y esa seva como parametroi de FEcha INI
 begin
         select *
                 INTO   vperiodo , vfini2
            from (
                SELECT DISTINCT sobptrm_term_code codigo, to_char(sobptrm_start_date,'DD/MM/YYYY') --,   SPRIDEN_PIDM PIDM,SOBPTRM_PTRM_CODE,SOBPTRM_START_DATE

                          FROM  sobptrm so, spriden
                               WHERE  1=1
                              --   AND   trunc(sysdate+0) between to_char(sobptrm_start_date,'dd/MM/YYYY') and to_char(sobptrm_end_date,'dd/MM/YYYY')
                                      and SOBPTRM_PTRM_CODE IN (select DISTINCT SUBSTR(ZSTPARA_PARAM_VALOR,1,3)
                                                                    From zstpara
                                                                    where 1=1
                                                                    and ZSTPARA_MAPA_ID in ('EXTRA_PART!=1' )
                                                                    UNION
                                                                    select DISTINCT SUBSTR(ZSTPARA_PARAM_VALOR,5,3)
                                                                    From zstpara
                                                                    where 1=1
                                                                    and ZSTPARA_MAPA_ID in ('EXTRA_PART!=1' )
                                                                     )
                                      and  SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                                      AND  SUBSTR (SOBPTRM_TERM_CODE, 5, 2) IN (81,82,83  )
                                     and substr(sobptrm_term_code,1,2)   = SUBSTR(F_GETSPRIDENID(ACCS_pidm),1,2)
                                     and SOBPTRM_END_DATE  >= sysdate

                                     order by 1 desc

                  ) data
                  where 1=1
                  and rownum <2;

        vperiodo :=  vperiodo;
        ---nueva regla que se dio en la junta del dia 22/02/021  VictorR y Fernando
        -- para los casos de EXTR y TISU si lleva la fecha de inicio de la parte del periodo glovicx



exception when others then
  vperiodo := null;

  --DBMS_OUTPUT.put_line('error en calcular el periodo y finicio EXTR:  '|| sqlerrm);
  end;

 ELSIF  ACCS.code = 'TISU'  THEN
begin
         select *
                 INTO   vperiodo , vfini2
             from (
                SELECT DISTINCT sobptrm_term_code codigo, to_char(sobptrm_start_date,'DD/MM/YYYY') --,   SPRIDEN_PIDM PIDM,SOBPTRM_PTRM_CODE,SOBPTRM_START_DATE

                          FROM  sobptrm so, spriden
                               WHERE  1=1
                              --   AND   trunc(sysdate+0) between to_char(sobptrm_start_date,'dd/MM/YYYY') and to_char(sobptrm_end_date,'dd/MM/YYYY')
                                      and SOBPTRM_PTRM_CODE IN (select DISTINCT SUBSTR(ZSTPARA_PARAM_VALOR,1,3)
                                                                    From zstpara
                                                                    where 1=1
                                                                    and ZSTPARA_MAPA_ID in ('EXTRA_PART!=1' )
                                                                    UNION
                                                                    select DISTINCT SUBSTR(ZSTPARA_PARAM_VALOR,5,3)
                                                                    From zstpara
                                                                    where 1=1
                                                                    and ZSTPARA_MAPA_ID in ('EXTRA_PART!=1' )
                                                                     )
                                      and  SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                                      AND  SUBSTR (SOBPTRM_TERM_CODE, 5, 2) IN (84,85,86)
                                     and substr(sobptrm_term_code,1,2)   = SUBSTR(F_GETSPRIDENID(ACCS.pidm),1,2)
                                     and SOBPTRM_END_DATE  >= sysdate

                                     order by 1 desc

                  ) data
                  where 1=1
                  and rownum <2;



exception when others then
  vperiodo := null;

  --DBMS_OUTPUT.put_line('error en calcular el periodo y finicio TISU:  '|| sqlerrm);
  end;

ELSE

begin
         SELECT DISTINCT sobptrm_term_code codigo, to_char(sobptrm_start_date,'DD/MM/YYYY') --,   SPRIDEN_PIDM PIDM,SOBPTRM_PTRM_CODE,SOBPTRM_START_DATE
               INTO   vperiodo , vfini2
                  FROM  sobptrm so, spriden
                       WHERE  1=1
                       AND   trunc(sysdate+0) between to_char(sobptrm_start_date,'dd/MM/YYYY') and to_char(sobptrm_end_date,'dd/MM/YYYY')
                              and SOBPTRM_PTRM_CODE = '1'
                              and  SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                              -- AND  SUBSTR (SOBPTRM_TERM_CODE, 5, 2) IN (84,85,86)
                             and substr(sobptrm_term_code,1,2)   = SUBSTR(F_GETSPRIDENID(ACCS.pidm),1,2);

        exception when others then
          vperiodo := null;
          vfini2     := null;
          --DBMS_OUTPUT.put_line('error en calcular el periodo y finicio'|| sqlerrm);
          end;





END IF;
            -----convertimos a la materia padre
      begin
        select  SZTMACO_MATPADRE
             INTO vmateriap
        from sztmaco
        where 1=1
         AND  SZTMACO_MATHIJO =  (ACCS.materia) ;
      exception when others then
        --DBMS_OUTPUT.put_line('ERROR  al calcular mako'||  jump.materia);
        verror  := 'no se pudo obtener materia padre'|| ACCS.materia;
      end;


---- hacer comparacion vs stume para ver cuantos han caido--
    begin
          select count(*) Cantidad,SZSTUME_STAT_IND estatus
              into vcount_alum,vestatus
            FROM SZSTUME  ZE
            WHERE 1=1
            AND  ZE.SZSTUME_RSTS_CODE = 'RE'
            AND  ZE.SZSTUME_NO_REGLA = 99
            AND  ZE.SZSTUME_PIDM  = ACCS.PIDM
            AND  ZE.SZSTUME_POBI_SEQ_NO = ACCS.num_acc
            group by SZSTUME_STAT_IND;

       -- vcount_alum_OK := vcount_alum_OK+1;

    exception when others then
     vcount_alum := 0;
     vestatus    := NULL;
    end;

    if vcount_alum >= 1 then

        vcount_alum_OK := vcount_alum_OK+1;
     else
      vcount_alum_NO := vcount_alum_NO +1 ;
     end if;


    IF vestatus = 0  then
       vestatus_0 := vestatus_0 +1;
     elsif vestatus = 1  then
        vestatus_1 := vestatus_1 +1;
     elsif vestatus > 1 then
       vestatus_E := vestatus_e +1;

    end if;

    ACCS_SEQNO  := ACCS_SEQNO+1;

  --dbms_output.put_line('datos alumnos '|| ACCS.PIDM ||'-'|| ACCS.num_acc||'-'||vestatus||'-++'||vcount_alum_OK||'->>'||vcount_alum_NO ||'-'|| ACCS.FECHA_INICIOS );

    --------------------------------------------aqui empieza loS GRUPOS-----------
        BEGIN
            SELECT COUNT(SZTGPME_TERM_NRC) cuenta,SZTGPME_STAT_IND --,SZTGPME_START_DATE
                   INTO VGPO_MATERIA, VGPO_ESTATUS  --, VGPO_FINI
                FROM SZTGPME
                WHERE 1=1
                AND SZTGPME_NO_REGLA =99
                AND SZTGPME_TERM_NRC LIKE (vmateriap||'%')
                AND to_char(SZTGPME_START_DATE,'DD/MM/YYYY')   = to_char(to_date(vfini2, 'DD/MM/YYYY'),'DD/MM/YYYY')
                GROUP BY SZTGPME_TERM_NRC,  SZTGPME_STAT_IND,SZTGPME_START_DATE
            ORDER BY 1 ;

          EXCEPTION WHEN OTHERS THEN
           VGPO_MATERIA:= 0;
           VGPO_ESTATUS:= null;
           VGPO_FINI   := null;
           -- dbms_output.put_line('ERROR EN GRUPOS '|| ACCS.PIDM);
        END;


 dbms_output.put_line('datos GRUPOS '|| ACCS.PIDM ||'-'|| vmateriap||'-'||VGPO_MATERIA||'-'|| vfini2);

    IF VGPO_MATERIA >= 1 THEN
        VGPO_MATERIA_OK  := VGPO_MATERIA_OK +1;
     ELSE
        VGPO_MATERIA_NO  := VGPO_MATERIA_NO +1;
     END IF;

     IF VGPO_ESTATUS = 0 THEN
        VGPO_ESTATUS_0 := VGPO_ESTATUS_0 +1;
      ELSIF VGPO_ESTATUS = 1 THEN
        VGPO_ESTATUS_1 := VGPO_ESTATUS_1 +1;
      ELSIF VGPO_ESTATUS > 1 THEN
          VGPO_ESTATUS_E := VGPO_ESTATUS_E +1;
      END IF;


-----------aqui van los profesore---------
    begin
         SELECT distinct count(SZSGNME_TERM_NRC) cuenta,SZSGNME_STAT_IND --,SZSGNME_START_DATE
            into VPRFE_MATERIA, VPRFE_ESTATUS
           FROM SZSGNME
            WHERE 1=1
                AND SZSGNME_NO_REGLA =99
                AND SZSGNME_TERM_NRC LIKE (vmateriap||'%')
                AND  to_char(SZSGNME_START_DATE,'DD/MM/YYYY')   = to_char(to_date(vfini2, 'DD/MM/YYYY'),'DD/MM/YYYY')
                GROUP BY  SZSGNME_STAT_IND, SZSGNME_START_DATE
                ;
     exception when others then
     VPRFE_MATERIA := 0;
     VPRFE_ESTATUS  := NULL;
     end;


    dbms_output.put_line('datos PROFESOR '|| ACCS.PIDM ||'-'|| vmateriap||'-'||VPRFE_MATERIA||'-'|| vfini2);

    IF VPRFE_MATERIA >= 1 THEN
        VPRFE_MATERIA_OK  := VPRFE_MATERIA_OK +1;
     ELSE
        VPRFE_MATERIA_NO  := VPRFE_MATERIA_NO +1;
     END IF;

     IF VPRFE_ESTATUS = 0 THEN
        VPRFE_ESTATUS_0 := VPRFE_ESTATUS_0 +1;
      ELSIF VGPO_ESTATUS = 1 THEN
        VPRFE_ESTATUS_1 := VPRFE_ESTATUS_1 +1;
      ELSIF VGPO_ESTATUS > 1 THEN
         VPRFE_ESTATUS_E := VPRFE_ESTATUS_E +1;
      END IF;

    ---------materias sin profesor en aztpara----


    begin

      select distinct count(ZSTPARA_PARAM_VALOR) --ZSTPARA_PARAM_VALOR matricula_profe, fget_pidm( ZSTPARA_PARAM_VALOR )  pidm_profe
        INTO  no_profesor
        from ZSTPARA
        where ZSTPARA_MAPA_ID = 'DOCENTE_NIVELAC'
        and  ZSTPARA_PARAM_ID LIKE (vmateriap||'%');

    exception when others then
        no_profesor := 0;
    end;

    if no_profesor = 0 then
     vno_mate_prof  := ',
     '|| vno_mate_prof||',
     '||vmateriap ;

    end if;



END loop;  --END LOOP PRINCIPAL

       /*
        dbms_output.put_line('NUmero de Accesorios  total:  '|| ACCS_SEQNO );
        dbms_output.put_line('SZTUME  alumnos EXISTEN '|| vcount_alum_OK );
        dbms_output.put_line('SZTUME  alumnos NO EXISTEN  '|| vcount_alum_NO );
        dbms_output.put_line('SZTUME  alumnos estatus 0  '|| vestatus_0 );
        dbms_output.put_line('SZTUME  alumnos estatus 1 '|| vestatus_1 );
        ------------------
        dbms_output.put_line('SZTGPME Materia existe '|| VGPO_MATERIA_OK );
        dbms_output.put_line('SZTGPME Materia No existe '|| VGPO_MATERIA_NO );
        dbms_output.put_line('SZTGPME estatus 0 '|| VGPO_ESTATUS_0 );
        dbms_output.put_line('SZTGPME status 1 '|| VGPO_ESTATUS_1 );
        -------------
        dbms_output.put_line('SZSGNME Materia existe '|| VPRFE_MATERIA_OK );
        dbms_output.put_line('SZSGNME Materia NO existe '|| VPRFE_MATERIA_NO );
        dbms_output.put_line('SZSGNME status 0 '|| VPRFE_ESTATUS_0 );
        dbms_output.put_line('SZSGNME status 1 '|| VPRFE_ESTATUS_1 );
        dbms_output.put_line('SZSGNME status E '|| VPRFE_ESTATUS_E );
        dbms_output.put_line('NO existe profe para materia '|| vno_mate_prof );
      */



 --aquivan grupos y prodes

vbody  := vbody||' <table "width: 100%; height: 275px; border="1" >
  <tr>
    <th bgcolor="LightGray">GRUPOS:</th>
    <th bgcolor="LightGray">Avance</th>
    </tr>
     <TR>
          <TD>'||'SZTGPME Grupos  EXISTEN '||'</TD> <TD>'|| VGPO_MATERIA_OK||' </TD>
     </TR> <TR>
          <TD>'||'SZTGPME Grupos NO EXISTEN  '||'</TD> <TD>'||VGPO_MATERIA_NO||'</TD>
     </TR> <TR>
          <TD>'||'SZTGPME Grupos no sincronizado '||'</TD> <TD>'||VGPO_ESTATUS_0||'</TD>
     </TR> <TR>
          <TD>'||'SZTGPME Grupos sincronizado '||'</TD> <TD>'||VGPO_ESTATUS_1||'</TD>
     </TR> <TR>
          <TD>'||'SZTGPME Grupos estatus Err'||'</TD> <TD>'||VGPO_ESTATUS_E||'</TD>
      </TR> <TR>
      </TR>
</TABLE>';


vbody  := vbody||' <table "width: 100%; height: 275px; border="1" >
  <tr>
    <th bgcolor="LightGray">PROFESORES:</th>
    <th bgcolor="LightGray">Avance</th>
    </tr>
     <TR>
          <TD>'||'SZSGNME Profesor  EXISTEN '||'</TD> <TD>'|| VPRFE_MATERIA_OK||' </TD>
     </TR> <TR>
          <TD>'||'SZSGNME Profesor NO EXISTEN  '||'</TD> <TD>'||VPRFE_MATERIA_NO||'</TD>
     </TR> <TR>
          <TD>'||'SZSGNME Profesor no sincronizado '||'</TD> <TD>'||VPRFE_ESTATUS_0||'</TD>
     </TR> <TR>
          <TD>'||'SZSGNME Profesor sincronizado '||'</TD> <TD>'||VPRFE_ESTATUS_1||'</TD>
     </TR> <TR>
          <TD>'||'SZSGNME Profesor estatus Err'||'</TD> <TD>'||VPRFE_ESTATUS_E||'</TD>
      </TR> <TR>
      </TR>
</TABLE>';

vbody  := vbody||' <table "width: 100%; height: 275px; border="1" >
  <tr>
    <th bgcolor="LightGray">ALUMNOS:</th>
    <th bgcolor="LightGray">Avance</th>
    </tr>
     <TR>
          <TD bgcolor="LightGray" ><B>'||'Total de Nivelaciones ' ||'</TD> <TD bgcolor="LightGray" bold > <B>'|| ACCS_SEQNO||'</B> </TD>
     </TR> <TR>
          <TD>'||'SZTUME  alumnos EXISTEN '||'</TD> <TD>'||vcount_alum_OK||'</TD>
     </TR> <TR>
          <TD>'||'SZTUME  alumnos NO EXISTEN '||'</TD> <TD>'||vcount_alum_NO||'</TD>
     </TR> <TR>
          <TD>'||'SZTUME  alumnos no sincronizado '||'</TD> <TD>'||vestatus_0||'</TD>
     </TR> <TR>
          <TD>'||'SZTUME  alumnos sincronizado '||'</TD> <TD>'||vestatus_1||'</TD>
      </TR> <TR>
          <TD>'||'SZTUME  alumnos estatus Err '||'</TD> <TD>'||vestatus_E||'</TD>
       </TR> <TR>
</TR>
</TABLE>';


vbody  := vbody||' <table "width: 100%; height: 275px; border="1" >
  <tr>
    <th bgcolor="LightGray">SIN PROFESOR</th>
    <th bgcolor="LightGray">Avance</th>
    </tr>
     <TR>
          <TD>'||'No existe materia en SZTPARA'||'</TD>
      <TR>    <TD>'|| vno_mate_prof||' </TD>
       </TR> <TR>

 </TR> <TR>
      </TR>
</TABLE>';


-------------
vbody := vbody||  '</tr>
  <tr>
  <td>    </td>
  </tr>
</table>'||chr(10)||chr(13)||vseparador;



p_html:=p_html|| vbody||chr(13)||  'ULTIMA EJECUCIÓN:'|| TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')||chr(13)||'
</body>
</html>
';


dbms_output.put_line('SALIDA HTML : '|| vbody ||vbody_gpo||vbody_prof);


FOR NIN  IN (select ZSTPARA_PARAM_VALOR MAIL
                        from zstpara
                        WHERE 1=1
                        AND  ZSTPARA_MAPA_ID = 'SIU_MAIL_COPIA'
                        AND ZSTPARA_PARAM_ID = 'SYNCRO_NIVE'
                        --and ZSTPARA_PARAM_SEC = 83
                        ORDER BY 1
                        )  LOOP

p_to := NIN.MAIL;

--DBMS_OUTPUT.PUT_LINE(' PROCESO -- ENVIA MAIL   '|| p_to );
PKG_NIVE_AULA.P_ENVIA_MAIL(p_to  ,p_html    );

END LOOP;




EXCEPTION WHEN OTHERS THEN
    VERROR := SQLERRM;
    DBMS_OUTPUT.PUT_LINE('ERROR GRAL ENVIA MAIL   '|| VERROR );


END P_MAIL_NIVE_HTML;


PROCEDURE P_ENVIA_MAIL(p_to  varchar2,p_html varchar2   ) IS
  --  p_to            varchar2(50);--:=  'vsanchro@utel.edu.mx';--'emontadi@utel.edu.mx ';'vramirlo@utel.edu.mx '
    p_from           varchar2(50):= 'victor.ramirez@s4learning.com';
    p_subject        varchar2(550):= 'SINCRONIZACIÓN';
    p_text           varchar2(50):= 'texto normal';
    --p_html           varchar2(32767):= 'texto HTML';
    p_smtp_hostname  varchar2(50):= '10.1.47.12';
    p_smtp_portnum   varchar2(50):= '26';
    VERROR           VARCHAR2(200);


    l_boundary      varchar2(255) default 'a1b2c3d4e3f2g1';
    l_connection    utl_smtp.connection;
    l_body_html     clob := empty_clob;  --This LOB will be the email message
    l_offset        number;
    l_ammount       number;
    l_temp          varchar2(32767) default null;

BEGIN


    l_connection := utl_smtp.open_connection( p_smtp_hostname, p_smtp_portnum );
    utl_smtp.helo( l_connection, p_smtp_hostname );
    utl_smtp.mail( l_connection, p_from );
    utl_smtp.rcpt( l_connection, p_to );

    l_temp := l_temp || 'MIME-Version: 1.0' ||  chr(13) || chr(10);
    l_temp := l_temp || 'To: ' || p_to || chr(13) || chr(10);
    l_temp := l_temp || 'From: ' || p_from || chr(13) || chr(10);
    l_temp := l_temp || 'Subject: ' || p_subject || chr(13) || chr(10);
    l_temp := l_temp || 'Reply-To: ' || p_from ||  chr(13) || chr(10);
    l_temp := l_temp || 'Content-Type: multipart/alternative; boundary=' ||
                         chr(34) || l_boundary ||  chr(34) || chr(13) ||
                         chr(10);

    ----------------------------------------------------
    -- Write the headers
    dbms_lob.createtemporary( l_body_html, false, 10 );
    dbms_lob.write(l_body_html,length(l_temp),1,l_temp);


    ----------------------------------------------------
    -- Write the text boundary
    l_offset := dbms_lob.getlength(l_body_html) + 1;
    l_temp   := '--' || l_boundary || chr(13)||chr(10);
    l_temp   := l_temp || 'content-type: text/plain; charset=us-ascii' ||
                  chr(13) || chr(10) || chr(13) || chr(10);
    dbms_lob.write(l_body_html,length(l_temp),l_offset,l_temp);

    ----------------------------------------------------
    -- Write the plain text portion of the email
    l_offset := dbms_lob.getlength(l_body_html) + 1;
    dbms_lob.write(l_body_html,length(p_text),l_offset,p_text);

    ----------------------------------------------------
    -- Write the HTML boundary
    l_temp   := chr(13)||chr(10)||chr(13)||chr(10)||'--' || l_boundary ||
                    chr(13) || chr(10);
    l_temp   := l_temp || 'content-type: text/html;' ||
                   chr(13) || chr(10) || chr(13) || chr(10);
    l_offset := dbms_lob.getlength(l_body_html) + 1;
    dbms_lob.write(l_body_html,length(l_temp),l_offset,l_temp);

    ----------------------------------------------------
    -- Write the HTML portion of the message
    l_offset := dbms_lob.getlength(l_body_html) + 1;
    dbms_lob.write(l_body_html,length(p_html),l_offset,p_html);

    ----------------------------------------------------
    -- Write the final html boundary
    l_temp   := chr(13) || chr(10) || '--' ||  l_boundary || '--' || chr(13);
    l_offset := dbms_lob.getlength(l_body_html) + 1;
    dbms_lob.write(l_body_html,length(l_temp),l_offset,l_temp);


    ----------------------------------------------------
    -- Send the email in 1900 byte chunks to UTL_SMTP
    l_offset  := 1;
    l_ammount := 1900;
    utl_smtp.open_data(l_connection);
    while l_offset < dbms_lob.getlength(l_body_html) loop
        utl_smtp.write_data(l_connection,
                            dbms_lob.substr(l_body_html,l_ammount,l_offset));
        l_offset  := l_offset + l_ammount ;
        l_ammount := least(1900,dbms_lob.getlength(l_body_html) - l_ammount);
    end loop;
    utl_smtp.close_data(l_connection);
    utl_smtp.quit( l_connection );
    dbms_lob.freetemporary(l_body_html);




END P_ENVIA_MAIL;


PROCEDURE P_ALINEA_SEQNOS is

vfech_ini  varchar2(16);
vregla     number := 99;
vsalida   VARCHAR2(100):= 'EXITO';
VcountGNME   number:= 0;


begin
  begin
        select MAX(TO_DATE(PE.SZTGPME_START_DATE,'DD/MM/YYYY')) 
          INTO vfech_ini
           from SZTGPME PE
            where 1=1
              and  PE.SZTGPME_NO_REGLA = vregla
              AND PE.SZTGPME_CAMP_CODE NOT IN ( 'UIN','UNI');
  
  exception when others then
    vfech_ini := null;
  end;

FOR jump in (SELECT DISTINCT PE.SZTGPME_TERM_NRC gmateria, pe.SZTGPME_NIVE_SEQNO gseqno,ge.SZSGNME_NIVE_SEQNO mseqno,ze.
              SZSTUME_PIDM pidm, ze.SZSTUME_NIVE_SEQNO pidm_seqno,ZE.SZSTUME_POBI_SEQ_NO num_accesorio
              FROM SZSTUME ze, SZSGNME ge,SZTGPME PE
               WHERE 1=1 
                and ZE.SZSTUME_NO_REGLA = vregla
                AND ZE.SZSTUME_START_DATE = vfech_ini
                AND ZE.SZSTUME_NO_REGLA   = GE.SZSGNME_NO_REGLA
                AND ZE.SZSTUME_NO_REGLA   = PE.SZTGPME_NO_REGLA
                AND ZE.SZSTUME_START_DATE = GE.SZSGNME_START_DATE
                AND ZE.SZSTUME_START_DATE = PE.SZTGPME_START_DATE
                AND ZE.SZSTUME_TERM_NRC   = GE.SZSGNME_TERM_NRC
                AND ZE.SZSTUME_TERM_NRC   = PE.SZTGPME_TERM_NRC
               and (pe.SZTGPME_NIVE_SEQNO != ze.SZSTUME_NIVE_SEQNO  
                    or   pe.SZTGPME_NIVE_SEQNO != GE.SZSGNME_NIVE_SEQNO )
               --  AND ZE.SZSTUME_TERM_NRC = 'L1AD10401'
                order by 1) loop

     begin
           SELECT count(SZSGNME_NIVE_SEQNO)
               into VcountGNME
                 FROM SZSGNME GE
                  where 1=1
                        and ge.SZSGNME_NO_REGLA = vregla
                        and ge.SZSGNME_START_DATE = vfech_ini
                        and ge.SZSGNME_TERM_NRC = jump.gmateria;   
                        
                            
       exception when others then
            VcountGNME := 0;
            VSALIDA := SQLERRM;                 
       
       
       end;
           -- dbms_output.put_line('encontro mas 1 rgs  '|| jump.gmateria ||'-'||VcountGNME  );    
       
       IF VcountGNME > 1  then
        
         begin
              delete  
                 FROM SZSGNME GE
                  where 1=1
                        and ge.SZSGNME_NO_REGLA = vregla
                        and ge.SZSGNME_START_DATE = vfech_ini
                        and ge.SZSGNME_TERM_NRC = jump.gmateria
                        and GE.SZSGNME_NIVE_SEQNO = (select min(g2.SZSGNME_NIVE_SEQNO) from SZSGNME g2
                                                      where 1=1 
                                                        and  ge.SZSGNME_NO_REGLA = g2.SZSGNME_NO_REGLA
                                                        and ge.SZSGNME_START_DATE = g2.SZSGNME_START_DATE
                                                        and ge.SZSGNME_TERM_NRC   = g2.SZSGNME_TERM_NRC )
                       and rownum < 2 ;      
                                                        
             --dbms_output.put_line('se booro 1 regs  '|| jump.gmateria   );                                            
         exception when others then
            VcountGNME := 0;
            VSALIDA := SQLERRM; 
         
         end;
       
       end if;
       
           --actualiza el seqno de profesores
            begin
                UPDATE SZSGNME ge
                 SET  ge.SZSGNME_NIVE_SEQNO = jump.gseqno
                    where 1=1
                    and ge.SZSGNME_NO_REGLA = vregla
                    and ge.SZSGNME_START_DATE = vfech_ini
                    and ge.SZSGNME_TERM_NRC   = jump.gmateria
                    and ge.SZSGNME_NIVE_SEQNO = (select max(SZSGNME_NIVE_SEQNO) from SZSGNME g2
                                                  where 1=1 
                                                    and  ge.SZSGNME_NO_REGLA = g2.SZSGNME_NO_REGLA
                                                    and ge.SZSGNME_START_DATE = g2.SZSGNME_START_DATE
                                                    and ge.SZSGNME_TERM_NRC   = g2.SZSGNME_TERM_NRC )
                                                    ;
                 
              exception when others then
              vsalida  := 'error en actualiza profesor '|| sqlerrm;
               DBMS_OUTPUT.PUT_LINE('EROOORR  DE UPDATE PROFESOR:'||jump.gmateria||'-'||jump.gseqno||'-'||vfech_ini|| '->'|| vsalida  );
             end;
   

     --DBMS_OUTPUT.PUT_LINE('SALIDA DE UPDATE PROFESOR:'||jump.gmateria||'-'||jump.gseqno||'-'|| vsalida  );
     ---- actualiza los alumnos el eqno
   ---- actualiza los alumnos el eqno

      begin
           update  SZSTUME ze
               set  ze.SZSTUME_NIVE_SEQNO  = jump.gseqno
            WHERE 1=1 
                and ze.SZSTUME_NO_REGLA = vregla
                and ze.SZSTUME_START_DATE = vfech_ini
                and ze.SZSTUME_TERM_NRC   =  jump.gmateria
                and ze.SZSTUME_PIDM       = jump.pidm
                and ze.SZSTUME_POBI_SEQ_NO = jump.num_accesorio;
      
      
      
        exception when others then
      vsalida  := 'error en actualiza alumno '|| sqlerrm;
     end;

  --DBMS_OUTPUT.PUT_LINE('SALIDA DE UPDATE alumno:'||jump.gmateria||'-'||jump.gseqno||'-'||jump.pidm||'-'||jump.num_accesorio||'-'|| vsalida  );


commit;
end loop;


exception when others then
      vsalida  := 'error en general del proceso '|| sqlerrm;

end P_ALINEA_SEQNOS;


end PKG_NIVE_AULA ;
/

DROP PUBLIC SYNONYM PKG_NIVE_AULA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_NIVE_AULA FOR BANINST1.PKG_NIVE_AULA;


GRANT EXECUTE ON BANINST1.PKG_NIVE_AULA TO PUBLIC;
