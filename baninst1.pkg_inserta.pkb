DROP PACKAGE BODY BANINST1.PKG_INSERTA;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_inserta
is

Function   inscripcion(iden in varchar2, per in varchar2,  subj in varchar2, crse in varchar2, parte in varchar2, n_prog varchar2, title in varchar2, cred in decimal, calif in varchar2, iden2 varchar2, crn varchar2,sp in number ) Return varchar2 

is

periodo varchar2(6);
n_crn    varchar2(5);
n_seq_numb  varchar2(3);
campus varchar2(3);
conta_ptrm number;
conta number;
conta2 number;
ptrm varchar2(3);
inicio date;
fin date;
weeks number;
pidm number;
tckn number;
tckg number;
--stsp number;
conta_per number;
vl_exito varchar2(2500):='EXITO';
vl_parte varchar2 (6);
vl_existe number:=0;
crn_1 number :=0;
n_nivel varchar2(2):= null;
n_orden number :=0;
vl_calif varchar2(5);
vl_escuela varchar2(5):= null;
vl_gmod varchar2(3):= null;




begin

dbms_output.put_line('primera : '|| iden ||'*'||iden2);
        n_nivel := substr  (n_prog, 4, 2) ;
        
    Begin       
            select distinct SOBCURR_LEVL_CODE
            Into n_nivel
            from SOBCURR
            where SOBCURR_PROGRAM = n_prog;
    Exception
        When Others then
            n_nivel := null;        
    End;   
    
    Begin
        select spriden_pidm 
            into pidm 
         from spriden
        where spriden_id=iden 
        and spriden_change_ind is null;
    Exception
    When Others then 
       vl_exito:='Error al buscar Persona: '||sqlerrm;
    End;

    dbms_output.put_line('Persona: '||pidm);

    vl_gmod:= null;        
    Begin
        select distinct nvl (SFRSTCR_GMOD_CODE,1) 
            Into vl_gmod
        from sfrstcr
        where 1=1
        and sfrstcr_pidm = pidm
        and SFRSTCR_TERM_CODE = per
        And SFRSTCR_RSTS_CODE ='RE'
        And SFRSTCR_PTRM_CODE = parte
        and SFRSTCR_RESERVED_KEY =subj||crse;
    Exception
    When Others then 
        vl_gmod:= 1;
    End;

    
    
    If substr (iden, 1,2) != substr (iden2, 1, 2) then 
        dbms_output.put_line('Entra a buscar: '|| parte);
        
        If parte != '1' then 

               vl_parte := substr (parte, 2, 2);
               dbms_output.put_line('corta: '|| vl_parte);
               If substr  (n_prog, 4, 2)  = 'MA' then
                  vl_parte := 'M'||vl_parte;
                   
                  dbms_output.put_line('ma: '|| vl_parte);
               ElsIf substr  (n_prog, 4, 2)  = 'MS' then
                  vl_parte := 'A'||vl_parte;
                  dbms_output.put_line('ms: '|| vl_parte);
               ElsIf substr  (n_prog, 4, 2)  = 'BA' then
                  vl_parte := 'B'||vl_parte;
                  dbms_output.put_line('ba: '|| vl_parte);
               ElsIf substr  (n_prog, 4, 2)  = 'LI' then
                  vl_parte := 'L'||vl_parte;
                  dbms_output.put_line('ba: '|| vl_parte);
               End if;
        Else

        
            Begin
                Select a.SZTPTRM_PTRM_CODE
                    into vl_parte
                from sztptrm a
                where a.SZTPTRM_PROGRAM = n_prog
                and a.SZTPTRM_TERM_CODE like '%'|| substr (per, 3, 4)
                and a.SZTPTRM_PTRM_CODE in (select min (a1.SZTPTRM_PTRM_CODE)
                                                                 from SZTPTRM a1
                                                                 where a.SZTPTRM_PROGRAM = a1.SZTPTRM_PROGRAM
                                                                 and a.SZTPTRM_TERM_CODE = a1.SZTPTRM_TERM_CODE);
            Exception
            When Others then 
              vl_parte := null; 
              vl_exito := 'Crear configuracion para la parte de periodo  del programa ' || n_prog ||' en el periodo '|| substr (iden, 1,2) ||substr (per, 3, 4) || ' en la Forma SZTPART';  
        
            End;
            
        End if;       
               
    Else
       vl_parte := parte;
    End if;      

    --periodo:=substr(iden,1,2)||substr(per,3,4);
 dbms_output.put_line('Parte de Periodo: '|| vl_parte);
 
 If   vl_exito = 'EXITO' then
           Begin
            select count(*) 
                into conta_per
            from stvterm
            where stvterm_code=substr(iden,1,2)||substr(per,3,4);
          Exception
          when others then 
           dbms_output.put_line('Error en STVTERM: '|| sqlerrm);
           conta_per :=0;
          End;
        dbms_output.put_line('conta_per:'||conta_per||' periodo:'||substr(iden,1,2)||substr(per,3,4));
        
        if conta_per=0 then
        
            Begin 
                   select distinct z2.dato_destino
                     into periodo
                  from migra.tmp_catalogo z1, migra.tmp_catalogo z2
                  where z1.clave_catalogo='PERIODO' and z1.dato_destino=per
                  and     z2.clave_catalogo='PERIODO' and z1.dato_origen=z2.dato_origen and z2.col_aux2=substr(iden,2,1);
            Exception
                When Others then 
                  periodo := null;
                  dbms_output.put_line('Erro al buscar Tmp_Catalogo: '||sqlerrm);
            End;
          
        else
           periodo:=substr(iden,1,2)||substr(per,3,4);
        end if;
        dbms_output.put_line('busca tmp_catalogo:'||periodo);

        begin
        select  to_number(substr (ssbsect_crn,2,6)) CRN, ssbsect_seq_numb  
        into n_crn, n_seq_numb 
        from ssbsect sb
        where ssbsect_term_code=periodo and ssbsect_subj_code=subj and ssbsect_crse_numb=crse
        and    to_number(substr (ssbsect_crn,2,6)) in (select min(to_number(substr (ssbsect_crn,2,6))) 
        from ssbsect sb1
                       where sb.ssbsect_term_code=sb1.ssbsect_term_code and sb.ssbsect_subj_code=sb1.ssbsect_subj_code and sb.ssbsect_crse_numb=sb1.ssbsect_crse_numb);
        exception when others then
            n_crn:=null; n_seq_numb:=null;
            dbms_output.put_line('ErroR BUSCAR GRUPO: '||sqlerrm);
        End;

        dbms_output.put_line('Busca Grupo:'||n_crn ||'*'||n_seq_numb);

        Begin
                     select szvcamp_camp_code 
                        into campus from szvcamp
                    where szvcamp_camp_alt_code=substr(iden,1,2);
        Exception 
        When Others then 
         campus := null;
         dbms_output.put_line('Erro al buscar Campus: '||sqlerrm);
        End;            
        
        Begin

                select  count(*) into conta_ptrm
                from sobptrm
                where  sobptrm_term_code=periodo and sobptrm_ptrm_code=vl_parte;
          Exception 
        When Others then 
         conta_ptrm := '0';
         dbms_output.put_line('Erro al buscar vl_parte de Periodo: '||sqlerrm);
        End;            
                    
        if conta_ptrm=0 then
           ptrm:='1';
        else
           ptrm:=vl_parte;
        end if;
                    
          
                  dbms_output.put_line('Valores para Pperiodo;'||periodo||'vl_parte:'||vl_parte);       
        Begin
                    select sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
                    into inicio, fin, weeks
                    from sobptrm
                    where sobptrm_term_code=periodo and sobptrm_ptrm_code=vl_parte;
                    dbms_output.put_line('saida Pperiodo;'||inicio||'seman:'||fin||'*'||weeks);
            Exception 
        When Others then 
         inicio := null;
         fin := null;
         vl_exito:= 'Error al obtener Fecha de Inicio: '||sqlerrm;
        End;            
                  
                    
      
        if vl_exito != 'Exito'  then

               crn_1 :=0;
               vl_escuela := null;

                Begin 
                        Select distinct count(1)
                        into crn_1
                        from ssbsect 
                        where ssbsect_term_code= periodo
                    --    And SSBSECT_PTRM_CODE = parte
                        and  substr (ssbsect_crn,1,1) = substr (vl_parte,1,1);
                Exception
                    When Others then 
                      crn_1 :=0;
                End;     
                                    
                 dbms_output.put_line('RECUPERO crn_1 ' ||crn_1 ||'*'||periodo);        
                                    
                If crn_1 >= 1 then 
                              dbms_output.put_line('ENTRO POR EL 1  ' ||'*'||periodo||'*'||vl_parte);
                   Begin

                            select nvl(max(crn),1000)+1 
                                   into n_crn
                            from
                            (
                            select case when 
                            substr(SSBSECT_CRN,1,1) in('L','M','A','D','N','B', 'X', 'O') then to_number(substr(SSBSECT_CRN,2,100))+1
                            else
                            to_number(SSBSECT_CRN)                
                            end crn
                            from ssbsect 
                            where ssbsect_term_code= periodo);

                             
                             dbms_output.put_line('RECUPERO EL CRN' ||'*'||n_crn);
                   Exception   
                            When Others then  
                                n_crn := null;
                                dbms_output.put_line('ERROR EN EL 1 ' ||periodo ||sqlerrm);
                   End;                                            


                Else
                       dbms_output.put_line('ENTRO POR EL 2' ||'*'||crn_1||'*'||vl_parte);
                         Begin 
                            select nvl(max(crn),1000)+1 
                                   into n_crn
                            from
                            (
                            select case when 
                            substr(SSBSECT_CRN,1,1) in ('L','M','A','D','N','B', 'X','O') then to_number(substr(SSBSECT_CRN,2,100))+1
                            else
                            to_number(SSBSECT_CRN)                
                            end crn
                            from ssbsect 
                            where ssbsect_term_code= periodo);
                          Exception
                                When Others then 
                                     Begin
                                                 select nvl(max(to_number(substr (ssbsect_crn,2,6))),0)+1 
                                                     into n_crn 
                                                from ssbsect a 
                                                where a.ssbsect_term_code= periodo
                                              --  And a.SSBSECT_PTRM_CODE = parte
                                            --     And substr (a.ssbsect_crn, 1, 1)  = vl_parte
                                                 ;
                                                                     
                                     Exception   
                                                When Others then  
                                                    n_crn := null;
                                                 dbms_output.put_line('ERROR EN EL 2-3' ||periodo ||sqlerrm);
                                     End;                                            


                               dbms_output.put_line('ERROR EN EL 2-1' ||periodo ||sqlerrm);

                         End;     
                                                     
                End if;                   
                                                 
                If length (n_crn) between  1 and 4  then 
                   dbms_output.put_line('EL VALOR DE LA CADENA' ||n_crn );
                                                    
                      n_crn := substr (vl_parte,1,1)||n_crn;
                      dbms_output.put_line('Salida de la corrida ' ||n_crn );  
                ElsIf length (n_crn) between  5 and 5  then   
                  dbms_output.put_line('VALOR DEL CRN  ' ||n_crn );     
                   n_crn := n_crn ;
                dbms_output.put_line('NUEVO VALOR DEL CRN  ' ||n_crn );   
                End if;   
                
               If   length (n_crn) between  2 and 5  then 
--                    pkg_utilerias.p_ejecuta_rolado_fecha_mat(iden,null);
--                    Commit; 
               
                 dbms_output.put_line('ENTRA A REALIZAR LOS INSERT' ||n_crn );
                        Begin
                                            
                            insert into ssbsect values (periodo, n_crn, vl_parte, subj, crse, '01', 'A', 'ENL', campus, title, null, null, vl_gmod, null,null, null, null, 'Y', null, 0,0,0, 50, 0, 50, cred, 0, inicio, sysdate,
                             inicio, fin, weeks, null, 0,0,0, null,null, null, null,null,null, null, null,null,null, null, 'Y', 'N', null, null, null, 'NOP', null,null, null, null, null,null, 0, '01', USER, null, 'B', 
                             null,null, null, null,null,null, null, null);
                             dbms_output.put_line('Inserta ssbsec ' ||n_crn );  
                                             
                        Exception
--                                 WHEN DUP_VAL_ON_INDEX THEN
--                                        NULL;                        
                        When Others then 
                           vl_exito := 'Error al crear nuevo grupo ssbsect: '||sqlerrm;
                        End;
                                             
                        Begin     
                                             
                            insert into ssrmeet values(periodo, n_crn, null,null, null, null,null,null, sysdate, inicio, fin, '01', null,null, null, null,null,null,null, 'ENL', null, cred, null, 0, null, null, null, 'CLVI',
                            'CONVALIDACION', USER, null, null, null);      
                       --     dbms_output.put_line('Inserta ssrmeet ' ||n_crn );
                                            
                        Exception
--                                 WHEN DUP_VAL_ON_INDEX THEN
--                                        NULL;                        
                        When Others then 
                           vl_exito:= 'Error al crear ssrmeet: '||sqlerrm;
                        End;

                
                        conta:=0;
                                        
                        Begin
                            select count(*) 
                                into conta
                            from sfbetrm
                            where sfbetrm_pidm=pidm and sfbetrm_term_code=periodo;
                        Exception
                        When Others then 
                           dbms_output.put_line('Error al buscar sfbetrm: '||sqlerrm);
                           conta:=0;
                        End;

                        if conta = 0 then               
                                    
                            Begin
                                insert into sfbetrm  values(periodo, pidm, 'EL', sysdate, 99.99, 'Y', null, sysdate, sysdate, null, null, null, null, USER, null, 'CONVALIDACION', null, 0, null, null, null, null, USER, null);
                            Exception
--                                 WHEN DUP_VAL_ON_INDEX THEN
--                                        NULL;                            
                            When Others then 
                               vl_exito:='Error al insertar sfbetrm: '||sqlerrm;
                            End;
                                            
                                            
                        end if;

--                        Begin
--                            select distinct max(sorlcur_key_seqno) into stsp
--                            from sorlcur
--                            where sorlcur_pidm=pidm 
--                            And SORLCUR_LMOD_CODE ='LEARNER'
--                            and sorlcur_program=n_prog;
--                        Exception
--                        When Others then 
--                            stsp :=0;
--                        End;
               
                        begin
                        
                        select distinct SOBCURR_COLL_CODE
                        Into vl_escuela
                        from SOBCURR
                        where SOBCURR_PROGRAM = n_prog;       
                        Exception   
                        When Others then 
                            vl_escuela := null;
                        End;
               
                        If sp > 0 then 

                               Begin
                                        Select count (1)
                                          into  vl_existe
                                        from sfrstcr
                                        where SFRSTCR_TERM_CODE = periodo
                                        and SFRSTCR_PIDM = pidm
                                        and SFRSTCR_CRN = n_crn
                                        And  SFRSTCR_STSP_KEY_SEQUENCE = sp;
                               Exception
                                when Others then 
                                  vl_existe :=0;
                               End;

                               If vl_existe = 0 then 
                                       
                                      Begin
                                        select distinct SFRSTCR_VPDI_CODE
                                            Into n_orden 
                                        from sfrstcr
                                        Where SFRSTCR_TERM_CODE = periodo
                                        And SFRSTCR_PIDM = pidm
                                        And SFRSTCR_CRN = crn
                                        And  SFRSTCR_STSP_KEY_SEQUENCE = sp;
                                      Exception
                                        When Others then 
                                         n_orden := null;
                                      End;
               
                                     /*     -------------- Ajuste generado para no cambiar los porcentajes de las materias Victor
                                      If calif = '5' then vl_calif :='5.0';
                                      elsif  calif = '6' then vl_calif := '6.0';
                                      elsif  calif = '7' then vl_calif :='7.0';  
                                      elsif  calif = '8' then vl_calif :='8.0';  
                                      elsif  calif = '9' then vl_calif :='9.0';  
                                      elsif  calif = '10' then vl_calif :='10.0';    
                                      else
                                            vl_calif := calif;
                                      End if;
                                    */  ---------------------------- Se apaga este codigo para que la calificacion pase como esta en el programa anterior ..
                                      
                                      vl_calif:= null;
                                       vl_calif := calif;
                                      
                                       Begin
                                                insert into sfrstcr values( periodo, pidm, n_crn, null, 1, vl_parte, 'RE', sysdate, null, null, 3, null, cred,null, cred, vl_gmod, calif , null, sysdate,  null,null,null,null,null,null,null,null,null,null,null,null, sysdate, sysdate, n_nivel, campus, 
                                                null,null,null,null,null,null,null,null,null,null,null,'CONVALIDACION', null,null,null,null,null,null,null,null,null,null, sp, null, n_seq_numb, null, null,null, null, USER, n_orden);
                                                Commit;           
                                                        
                                       Exception
--                                       WHEN DUP_VAL_ON_INDEX THEN
--                                        NULL;                                       
                                        When Others then 
                                           vl_exito:='Error al insertar sfrstcr: '||sqlerrm;
                                       End;
                               End if;
                               vl_existe :=0; 
                               
                              Begin
                                        Select count (1)
                                            into vl_existe
                                        from sfrareg
                                        where SFRAREG_TERM_CODE = periodo
                                        and SFRAREG_PIDM = pidm
                                        and SFRAREG_CRN = n_crn;
                               Exception
                                when Others then 
                                  vl_existe :=0;
                               End;
               
                               If vl_existe = 0 then 
                                   
                                    Begin
                                     insert into sfrareg values(pidm, periodo, n_crn, 0, 'RE', inicio, fin, 'N', 'N', sysdate, user, null,null,null,null,null,null,null,null, 'CONVALIDACION', sysdate, null, null, null);
                                    Exception
--                                    WHEN DUP_VAL_ON_INDEX THEN
--                                        NULL;                                    
                                    When Others then 
                                       vl_exito:='Error al insertar sfrareg: '||periodo||'*'||vl_parte||'*'||inicio||'*'||fin||'*'||weeks;
                                       
                                    End;
                               End if;
                        End if;            
                
                        tckn:= null;
                        Begin
                                select nvl(max(shrtckn_seq_no),0) +1 
                                    into tckn 
                                 from shrtckn
                                 where shrtckn_pidm=pidm
                                 And shrtckn_term_code = periodo;
                        Exception
                            When Others then 
                            tckn :=0;
                               dbms_output.put_line('Error al Buscar shrtckn: '||sqlerrm);
                        End;

                      conta:=0;
                        
                        Begin
                           select count(*) 
                                into conta 
                            from shrttrm
                            where shrttrm_pidm=pidm 
                            and shrttrm_term_code=periodo;
                        Exception
                            When Others then 
                            conta :=0;
                               dbms_output.put_line('Error al Buscar shrttrm: '||sqlerrm);
                        End;
                
                        if conta=0 then
                        
                           Begin
                                insert into shrttrm values(pidm, periodo, 'S', 'N', 'G', sysdate, null, null, null, null, null, null, null, null, sysdate, null, null, null, null, null, null, null, null, null, null, null, USER, 'CONVALIDACION', null);
                           Exception
--                                 WHEN DUP_VAL_ON_INDEX THEN
--                                        NULL;                           
                                When Others then 
                                conta :=0;
                                   vl_exito:='Error al Insertar shrttrm: '||sqlerrm;
                           End;
                                    
                                    
                        end if;
                
                        Begin
                            select count(*) 
                             into conta2 
                            from shrtckn
                            where shrtckn_pidm=pidm 
                            and shrtckn_term_code=periodo 
                            and shrtckn_crn=n_crn
                            And SHRTCKN_STSP_KEY_SEQUENCE = sp;
                        Exception
                            When Others then 
                            conta2 :=0;
                               vl_exito:='Error al buscar shrtckn: '||sqlerrm;
                        End;
                    
                
                        if conta2 > 0 then
                          NULL;  
                          
                                dbms_output.put_line(pidm||' '||periodo||' '||tckn||' '||n_crn||' '||subj||' '||crse);
                        else
                            
                            Begin
                                    insert into shrtckn values(pidm, periodo, tckn, n_crn, subj, crse, vl_escuela, campus, '9990', null, null, title, null, null, null, sysdate, vl_parte, n_seq_numb, inicio, fin, null, 'ENL', null, null, null, null, title, 
                                    sp, null, null, USER, 'CONVALIDACION', null);
                                    Commit;
                            Exception
--                                 WHEN DUP_VAL_ON_INDEX THEN
--                                        NULL;                            
                                When Others then 
                                   vl_exito:='Error al insert shrtckn: '||vl_parte ||' '||sqlerrm;
                            End;
                                  
    
                            tckn:= null;
                            Begin
                                select SHRTCKN_SEQ_NO
                                    Into tckn
                                from shrtckn
                                where shrtckn_PIDM = pidm
                                and SHRTCKN_STSP_KEY_SEQUENCE = sp
                                And SHRTCKN_CRN  = n_crn
                                and SHRTCKN_SUBJ_CODE = subj
                                And SHRTCKN_CRSE_NUMB = crse;
                            Exception
                                When Others then 
                                    tckn:= null;
                            End;
                            
                            vl_calif:= null;
                            Begin
                                 Select SFRSTCR_GRDE_CODE
                                    Into vl_calif
                                from sfrstcr
                                where sfrstcr_pidm =pidm 					
                                And SFRSTCR_STSP_KEY_SEQUENCE = sp
                                and SFRSTCR_CRN = n_crn
                                and SFRSTCR_TERM_CODE  = periodo;
                            Exception
                                When Others then 
                                vl_calif:= null;
                            End;

                        Begin
                                select nvl(max(SHRTCKG_SEQ_NO),0) +1 
                                    into tckg
                                 from shrtckg
                                 where SHRTCKG_PIDM=pidm
                                 And SHRTCKG_TERM_CODE = periodo
                                 And SHRTCKG_TCKN_SEQ_NO = tckn;
                                 
                        Exception
                            When Others then 
                            tckg :=0;
                           --    dbms_output.put_line('Error al Buscar shrtckn: '||sqlerrm);
                        End;
                            
                                  
                            Begin
                                insert into shrtckg values(pidm, periodo, tckn, tckg, null, calif,vl_gmod,cred, 'OE', null, sysdate, USER, sysdate, 'EQUIVA', periodo, 'CONVALIDACION', USER, cred, null, null, null, null);
                            Exception
                             WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;
                                When Others then 
                                   vl_exito:='Error al insert shrtckg: '||sqlerrm;
                            End;
                                
                            Begin
                            insert into shrtckl values(pidm, periodo, tckn, n_nivel, sysdate, 'Y', null, null, USER, 'CONVALIDACION', null);
                            Exception
                                 WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;
                                When Others then 
                                   vl_exito:='Error al insert shrtckl: '||sqlerrm;
                            End;
                                
                                
                        end if;
             
              --  commit;
                   
                        conta2:=0;
                        select count(*) 
                            into conta2 
                        from shrdgmr
                        where shrdgmr_pidm=pidm and shrdgmr_program=n_prog
                        And SHRDGMR_STSP_KEY_SEQUENCE = sp;
                    
                    
                    
                        if conta2 = 0 then
                           pkg_inserta.shrdgmr(pidm, n_prog, sp);
                        end if;
              Else
                vl_exito := 'ERROR AL ENTRAR A REALIZAR LOS INSERT111' ||n_crn;
                dbms_output.put_line('ERROR AL ENTRAR A REALIZAR LOS INSERT' ||n_crn);    
               End if;
                
        
        else
                dbms_output.put_line('valor Mayor al maximo ' ||length (n_crn) ||'*'||n_crn);         
                --vl_exito:= 'valor Mayor al maximo ' ||length (n_crn);     
                vl_exito :='valor Mayor al maximo ' ||length (n_crn) ||'*'||n_crn;         
                                   
        End if;        
    
 Else
  NULL;
    dbms_output.put_line('No tiene CRN y Fecha de INICio ' ||crn_1 ||'*'||periodo);                         
 End if;    
dbms_output.put_line('Error GEneral: '||vl_exito);

If vl_exito = 'EXITO' then
  Commit;
Else 
    Rollback;
End if;

Return vl_exito;

Exception
When Others then 
  vl_exito:= 'Error General ' ||sqlerrm;        
  Return vl_exito;
end inscripcion;

procedure shrdgmr(pidm in number, n_prog varchar2, sp in number )
is

vmaxima_shr NUMBER :=0;
Vgrado Varchar2(50):= null;
vl_contador number:=0;
vl_periodo varchar2(6);


 Begin

           
                     For c in (  
                     
                     
                     Select  distinct a.SGBSTDN_pidm, 
                                                                      a.SGBSTDN_LEVL_CODE, 
                                                                      a.SGBSTDN_COLL_CODE_1, 
                                                                      a.sgbstdn_majr_code_1, 
                                                                      a.sgbstdn_majr_code_conc_1, 
                                                                      a.sgbstdn_majr_code_conc_1_2, 
                                                                      a.SGBSTDN_TERM_CODE_Eff, 
                                                                      a.SGBSTDN_CAMP_CODE, 
                                                                      a.SGBSTDN_PROGRAM_1 , 
                                                                      a.SGBSTDN_DEGC_CODE_1, 
                                                                      a.SGBSTDN_CCON_RULE_11_2, 
                                                                      a.SGBSTDN_CCON_RULE_11_1,
                                                                      a.SGBSTDN_CMJR_RULE_1_1, 
                                                                      a.SGBSTDN_CURR_RULE_1,
                                                                      a.SGBSTDN_TERM_CODE_CTLG_1,
                                                                      b.SORLCUR_KEY_SEQNO
                                                 from   sgbstdn a , SORLCUR b
                                                  Where b.SORLCUR_PIDM = A.SGBSTDN_PIDM 
                                                  And b.SORLCUR_LMOD_CODE =   'LEARNER'
                                                  And b.SORLCUR_PROGRAM = A.SGBSTDN_PROGRAM_1
                                                   And a.SGBSTDN_STYP_CODE = 'C'
                                                   And  a.SGBSTDN_TERM_CODE_EFF in (select max (b.SGBSTDN_TERM_CODE_EFF)
                                                                                            from sgbstdn b
                                                                                            Where a.sgbstdn_pidm = b.sgbstdn_pidm
                                                                                            And a.sgbstdn_levl_code = b.sgbstdn_levl_code
                                                                                            and A.SGBSTDN_PROGRAM_1 = b.SGBSTDN_PROGRAM_1)
                                                   And a.sgbstdn_pidm not in (select SHRDGMR_pidm a1
                                                                                            from SHRDGMR a1    
                                                                                            Where a1.SHRDGMR_LEVL_CODE = a.SGBSTDN_LEVL_CODE
                                                                                           And a1.SHRDGMR_PROGRAM = a.SGBSTDN_PROGRAM_1
                                                                                            And a1.SHRDGMR_CAMP_CODE = a.Sgbstdn_CAMP_CODE)
                                                  And a.sgbstdn_pidm = pidm and a.sgbstdn_program_1=  n_prog      
                                                  And b.SORLCUR_KEY_SEQNO = sp
                                                  order by 1                 
                                                  
                                                                                                                                                                                            
                                    ) loop
                                    
                                    
                             Begin
                             select a.SGBSTDN_TERM_CODE_EFF
                             Into vl_periodo
                             from sgbstdn a
                             Where a.SGBSTDN_PIDM = c.SGBSTDN_pidm
                             And a.SGBSTDN_LEVL_CODE = c.SGBSTDN_LEVL_CODE
                             And a.SGBSTDN_PROGRAM_1 = c.SGBSTDN_PROGRAM_1
                             And a.SGBSTDN_CAMP_CODE = c.SGBSTDN_CAMP_CODE
                             And a.SGBSTDN_TERM_CODE_EFF = (select min(a1.SGBSTDN_TERM_CODE_EFF)
                                                                                     from sgbstdn a1
                                                                                     Where a1.SGBSTDN_PIDM = a.SGBSTDN_pidm
                                                                                     And a1.SGBSTDN_LEVL_CODE = a.SGBSTDN_LEVL_CODE
                                                                                     And a1.SGBSTDN_PROGRAM_1 = a.SGBSTDN_PROGRAM_1
                                                                                     And a1.SGBSTDN_CAMP_CODE = a.SGBSTDN_CAMP_CODE);
                             Exception
                             When Others then 
                                 vl_periodo := c.SGBSTDN_TERM_CODE_Eff;
                             End;       
           
                             Begin
                                        Select Nvl(Max(SHRDGMR_SEQ_NO),0) + 1
                                        Into vmaxima_shr
                                        from SHRDGMR
                                        Where SHRDGMR_PIDM = c.SGBSTDN_PIDM;
                             Exception
                                   When Others then 
                                   --DBMS_OUTPUT.PUT_LINE('Se presento un error al obtener la secuencia maxima para la tabla SHRDGMR' ||sqlerrm );
                                   vmaxima_shr:=1;     
                             End;         
                                               
                             Begin
                                      ----- Obtener el  estatus del grado -----
                                          Select PKG_PROGRAMAS_ACADEM.F_CONVERSION_DESTINO('STVDEGS', '0', NULL) EstatusGrado 
                                          Into Vgrado
                                          from dual;                                       

                             Exception
                                   When Others then 
                                   --DBMS_OUTPUT.PUT_LINE('Se presento un error al obtener el valor del estatus del grado' ||sqlerrm );
                                   Vgrado:='SO';     
                             End;         
          


                             Begin
                                            Insert into SHRDGMR values(
                                                                                      c.SGBSTDN_pidm,              --SHRDGMR_PIDM
                                                                                      vmaxima_shr,              --SHRDGMR_SEQ_NO
                                                                                      c.SGBSTDN_DEGC_CODE_1,              --SHRDGMR_DEGC_CODE
                                                                                      Vgrado, --SHRDGMR_DEGS_CODE ----- Se aplica cambio por solicitud de Montserrat 15-07-2016 se quita la variable y se pone fijo
                                                                                      c.SGBSTDN_LEVL_CODE,              --SHRDGMR_LEVL_CODE
                                                                                     c.SGBSTDN_COLL_CODE_1,               --SHRDGMR_COLL_CODE_1
                                                                                     c.sgbstdn_majr_code_1,               --SHRDGMR_MAJR_CODE_1
                                                                                     null,         --SHRDGMR_MAJR_CODE_MINR_1
                                                                                     c.sgbstdn_majr_code_conc_1,               --SHRDGMR_MAJR_CODE_CONC_1
                                                                                     null,               --SHRDGMR_COLL_CODE_2
                                                                                     null,               --SHRDGMR_MAJR_CODE_2
                                                                                     null,               --SHRDGMR_MAJR_CODE_MINR_2
                                                                                     null,                --SHRDGMR_MAJR_CODE_CONC_2
                                                                                     sysdate,                 --SHRDGMR_APPL_DATE
                                                                                     null,              --SHRDGMR_GRAD_DATE
                                                                                     null,              --SHRDGMR_ACYR_CODE_BULLETIN
                                                                                    sysdate,          --SHRDGMR_ACTIVITY_DATE
                                                                                      null,              --SHRDGMR_MAJR_CODE_MINR_1_2
                                                                                      c.sgbstdn_majr_code_conc_1_2,              --SHRDGMR_MAJR_CODE_CONC_1_2
                                                                                      null,              --SHRDGMR_MAJR_CODE_CONC_1_3
                                                                                      null,              --SHRDGMR_MAJR_CODE_MINR_2_2
                                                                                      null,              --SHRDGMR_MAJR_CODE_CONC_2_2
                                                                                      null,              --SHRDGMR_MAJR_CODE_CONC_2_3
                                                                                      vl_periodo,              --SHRDGMR_TERM_CODE_STUREC
                                                                                      null,              --SHRDGMR_MAJR_CODE_1_2
                                                                                      null,              --SHRDGMR_MAJR_CODE_2_2
                                                                                      c.SGBSTDN_CAMP_CODE,              --SHRDGMR_CAMP_CODE
                                                                                      null,              --SHRDGMR_TERM_CODE_GRAD
                                                                                      null,              --SHRDGMR_ACYR_CODE
                                                                                      null,              --SHRDGMR_GRST_CODE
                                                                                      null,              --SHRDGMR_FEE_IND
                                                                                      null,              --SHRDGMR_FEE_DATE
                                                                                      USER,              --SHRDGMR_AUTHORIZED
                                                                                      null,              --SHRDGMR_TERM_CODE_COMPLETED
                                                                                      null,              --SHRDGMR_DEGC_CODE_DUAL
                                                                                      null,              --SHRDGMR_LEVL_CODE_DUAL
                                                                                      null,              --SHRDGMR_DEPT_CODE_DUAL
                                                                                      null,              --SHRDGMR_COLL_CODE_DUAL
                                                                                      null,              --SHRDGMR_MAJR_CODE_DUAL
                                                                                      null,              --SHRDGMR_DEPT_CODE
                                                                                      null,              --SHRDGMR_DEPT_CODE_2
                                                                                      c.SGBSTDN_PROGRAM_1,              --SHRDGMR_PROGRAM
                                                                                      c.SGBSTDN_TERM_CODE_CTLG_1,              --SHRDGMR_TERM_CODE_CTLG_1
                                                                                      null,              --SHRDGMR_DEPT_CODE_1_2
                                                                                      null,              --SHRDGMR_DEPT_CODE_2_2
                                                                                      null,              --SHRDGMR_MAJR_CODE_CONC_121
                                                                                      null,              --SHRDGMR_MAJR_CODE_CONC_122
                                                                                      null,              --SHRDGMR_MAJR_CODE_CONC_123
                                                                                      null,                    --SHRDGMR_TERM_CODE_CTLG_2
                                                                                      null,              --SHRDGMR_CAMP_CODE_2
                                                                                      null,              --SHRDGMR_MAJR_CODE_CONC_221
                                                                                      null,              --SHRDGMR_MAJR_CODE_CONC_222
                                                                                      null,              --SHRDGMR_MAJR_CODE_CONC_223
                                                                                      c.SGBSTDN_CURR_RULE_1,              --SHRDGMR_CURR_RULE_1
                                                                                      C.SGBSTDN_CMJR_RULE_1_1,              --SHRDGMR_CMJR_RULE_1_1
                                                                                      C.SGBSTDN_CCON_RULE_11_1,              --SHRDGMR_CCON_RULE_11_1
                                                                                      C.SGBSTDN_CCON_RULE_11_2,              --SHRDGMR_CCON_RULE_11_2
                                                                                      null,              --SHRDGMR_CCON_RULE_11_3
                                                                                      null,              --SHRDGMR_CMJR_RULE_1_2
                                                                                      null,              --SHRDGMR_CCON_RULE_12_1
                                                                                      null,              --SHRDGMR_CCON_RULE_12_2
                                                                                      null,              --SHRDGMR_CCON_RULE_12_3
                                                                                      null,              --SHRDGMR_CMNR_RULE_1_1
                                                                                      null,              --SHRDGMR_CMNR_RULE_1_2
                                                                                      null,              --SHRDGMR_CURR_RULE_2
                                                                                      null,              --SHRDGMR_CMJR_RULE_2_1
                                                                                      null,             --SHRDGMR_CCON_RULE_21_1
                                                                                      null,              --SHRDGMR_CCON_RULE_21_2
                                                                                      null,              --SHRDGMR_CCON_RULE_21_3
                                                                                      null,              --SHRDGMR_CMJR_RULE_2_2
                                                                                      null,             --SHRDGMR_CCON_RULE_22_1
                                                                                      null,              --SHRDGMR_CCON_RULE_22_2
                                                                                      null,               --SHRDGMR_CCON_RULE_22_3
                                                                                      null,               --SHRDGMR_CMNR_RULE_2_1
                                                                                      null,              --SHRDGMR_CMNR_RULE_2_2
                                                                                      'UTEL',              --SHRDGMR_DATA_ORIGIN
                                                                                      'CONVALIDACION',              --SHRDGMR_USER_ID
                                                                                      sp,              --SHRDGMR_STSP_KEY_SEQUENCE
                                                                                      null,              --SHRDGMR_SURROGATE_ID
                                                                                      null,              --SHRDGMR_VERSION
                                                                                      null              --SHRDGMR_VPDI_CODE
                                                                                                );         
                             Exception
                               When Others then 
                                    NULL;                                                                    
                             End;    
           
           
                                  for c1 in (select SORLCUR_PIDM ,SORLCUR_SEQNO ,SORLCUR_LMOD_CODE ,SORLCUR_TERM_CODE ,SORLCUR_KEY_SEQNO
                                                   ,SORLCUR_PRIORITY_NO ,SORLCUR_ROLL_IND ,SORLCUR_CACT_CODE ,SORLCUR_USER_ID
                                                    ,SORLCUR_DATA_ORIGIN,SORLCUR_ACTIVITY_DATE  ,SORLCUR_LEVL_CODE ,SORLCUR_COLL_CODE
                                                    ,SORLCUR_DEGC_CODE ,SORLCUR_TERM_CODE_CTLG  ,SORLCUR_TERM_CODE_END ,SORLCUR_TERM_CODE_MATRIC
                                                    ,SORLCUR_TERM_CODE_ADMIT, SORLCUR_ADMT_CODE ,SORLCUR_CAMP_CODE ,SORLCUR_PROGRAM
                                                    ,SORLCUR_START_DATE ,SORLCUR_END_DATE ,SORLCUR_CURR_RULE  ,SORLCUR_ROLLED_SEQNO
                                                    ,SORLCUR_STYP_CODE ,SORLCUR_RATE_CODE  ,SORLCUR_LEAV_CODE ,SORLCUR_LEAV_FROM_DATE
                                                    ,SORLCUR_LEAV_TO_DATE ,SORLCUR_EXP_GRAD_DATE  ,SORLCUR_TERM_CODE_GRAD ,SORLCUR_ACYR_CODE
                                                    ,SORLCUR_SITE_CODE ,SORLCUR_APPL_SEQNO  ,SORLCUR_APPL_KEY_SEQNO  ,SORLCUR_USER_ID_UPDATE
                                                    ,SORLCUR_ACTIVITY_DATE_UPDATE ,SORLCUR_GAPP_SEQNO ,SORLCUR_CURRENT_CDE ,SORLCUR_SURROGATE_ID
                                                    ,SORLCUR_VERSION ,SORLCUR_VPDI_CODE 
                                                  from sorlcur S
                                                  Where SORLCUR_PIDM = c.SGBSTDN_pidm
                                                  And SORLCUR_LMOD_CODE = 'LEARNER'
                                                  And SORLCUR_SEQNO IN (SELECT MAX(SORLCUR_SEQNO) FROM SORLCUR SS
                                                           WHERE S.SORLCUR_PIDM=SS.SORLCUR_PIDM AND S.SORLCUR_PROGRAM=SS.SORLCUR_PROGRAM AND S.SORLCUR_LMOD_CODE=SS.SORLCUR_LMOD_CODE)
                                     --             And SORLCUR_ROLL_IND = 'Y'
                                     --             And SORLCUR_CACT_CODE = 'ACTIVE'
                                     --             And SORLCUR_APPL_KEY_SEQNO is not null
                                                  --And SORLCUR_CURRENT_CDE = 'Y'
                                                  And SORLCUR_PROGRAM  = c.SGBSTDN_PROGRAM_1
                                                  And sorlcur_pidm = pidm
                                                  And SORLCUR_KEY_SEQNO = sp
                                                    ) loop
                                          
                                                 Begin
                                                        Select nvl (max (SORLCUR_SEQNO), 0) +1
                                                        Into vl_contador
                                                        from sorlcur
                                                        Where  SORLCUR_PIDM = c.SGBSTDN_pidm
                                                        And SORLCUR_KEY_SEQNO = sp;
                                                 Exception
                                                 When others then 
                                                   vl_contador :=1;                                                 
                                                 End;
                                                
                                                Begin
                                                             Insert into sorlcur values  (
                                                                                                    c1.SORLCUR_PIDM,
                                                                                                    vl_contador, --SORLCUR_SEQNO
                                                                                                    'OUTCOME',
                                                                                                    c1.SORLCUR_TERM_CODE,
                                                                                                    c1.SORLCUR_KEY_SEQNO,
                                                                                                    c1.SORLCUR_PRIORITY_NO,
                                                                                                    'N',
                                                                                                    c1.SORLCUR_CACT_CODE,
                                                                                                    'CONVALIDACION',
                                                                                                    c1.SORLCUR_DATA_ORIGIN,
                                                                                                    c1.SORLCUR_ACTIVITY_DATE,
                                                                                                    c1.SORLCUR_LEVL_CODE,
                                                                                                    c1.SORLCUR_COLL_CODE,
                                                                                                    c1.SORLCUR_DEGC_CODE,
                                                                                                    c1.SORLCUR_TERM_CODE_CTLG,
                                                                                                    null,--SORLCUR_TERM_CODE_END
                                                                                                    null, --SORLCUR_TERM_CODE_MATRIC
                                                                                                    null, --SORLCUR_TERM_CODE_ADMIT
                                                                                                    null, --SORLCUR_ADMT_CODE
                                                                                                    c1.SORLCUR_CAMP_CODE,
                                                                                                    c1.SORLCUR_PROGRAM,
                                                                                                    c1.SORLCUR_START_DATE,
                                                                                                    c1.SORLCUR_END_DATE,
                                                                                                    c1.SORLCUR_CURR_RULE,
                                                                                                    null, --SORLCUR_ROLLED_SEQNO
                                                                                                    c1.SORLCUR_STYP_CODE,
                                                                                                    c1.SORLCUR_RATE_CODE,
                                                                                                    c1.SORLCUR_LEAV_CODE,
                                                                                                    c1.SORLCUR_LEAV_FROM_DATE,
                                                                                                    c1.SORLCUR_LEAV_TO_DATE,
                                                                                                    c1.SORLCUR_EXP_GRAD_DATE,
                                                                                                    c1.SORLCUR_TERM_CODE_GRAD,
                                                                                                    c1.SORLCUR_ACYR_CODE,
                                                                                                    c1.SORLCUR_SITE_CODE,
                                                                                                    null, --SORLCUR_APPL_SEQNO
                                                                                                    null, --SORLCUR_APPL_KEY_SEQNO
                                                                                                    c1.SORLCUR_USER_ID_UPDATE,
                                                                                                    c1.SORLCUR_ACTIVITY_DATE_UPDATE,
                                                                                                    c1.SORLCUR_GAPP_SEQNO,
                                                                                                    null, --SORLCUR_CURRENT_CDE
                                                                                                    null, --SORLCUR_SURROGATE_ID,
                                                                                                    null, --SORLCUR_VERSION
                                                                                                    null );--SORLCUR_VPDI_CODE
                                                                                                    
                                                Exception
                                                       When Others then 
                                                            NULL;                                                                                            
                                                End;    
                                                                                  
                                                
                                                
                                                For c2 in (select SORLFOS_PIDM
                                                                ,SORLFOS_LCUR_SEQNO,SORLFOS_SEQNO
                                                                ,SORLFOS_LFST_CODE,SORLFOS_TERM_CODE
                                                                ,SORLFOS_PRIORITY_NO,SORLFOS_CSTS_CODE
                                                                ,SORLFOS_CACT_CODE,SORLFOS_DATA_ORIGIN
                                                                ,SORLFOS_USER_ID,SORLFOS_ACTIVITY_DATE
                                                                ,SORLFOS_MAJR_CODE,SORLFOS_TERM_CODE_CTLG
                                                                ,SORLFOS_TERM_CODE_END,SORLFOS_DEPT_CODE
                                                                ,SORLFOS_MAJR_CODE_ATTACH,SORLFOS_LFOS_RULE
                                                                ,SORLFOS_CONC_ATTACH_RULE,SORLFOS_START_DATE
                                                                ,SORLFOS_END_DATE,SORLFOS_TMST_CODE
                                                                ,SORLFOS_ROLLED_SEQNO,SORLFOS_USER_ID_UPDATE
                                                                ,SORLFOS_ACTIVITY_DATE_UPDATE,SORLFOS_CURRENT_CDE
                                                                ,SORLFOS_SURROGATE_ID,SORLFOS_VERSION
                                                                ,SORLFOS_VPDI_CODE
                                                                from sorlfos
                                                                Where SORLFOS_PIDM = c1.SORLCUR_PIDM
                                                                And SORLFOS_LCUR_SEQNO  = c1.SORLCUR_SEQNO
                                                                And sorlfos_pidm = pidm ) loop
                                                                
                                                                Begin
                                                                        insert into sorlfos values ( c2.SORLFOS_PIDM
                                                                                                               ,vl_contador -- SORLFOS_LCUR_SEQNO
                                                                                                                ,c2.SORLFOS_SEQNO
                                                                                                                ,c2.SORLFOS_LFST_CODE
                                                                                                                ,c2.SORLFOS_TERM_CODE
                                                                                                                ,c2.SORLFOS_PRIORITY_NO
                                                                                                                ,c2.SORLFOS_CSTS_CODE
                                                                                                                ,c2.SORLFOS_CACT_CODE
                                                                                                                ,c2.SORLFOS_DATA_ORIGIN
                                                                                                                ,'CONVALIDACION'
                                                                                                                ,c2.SORLFOS_ACTIVITY_DATE
                                                                                                                ,c2.SORLFOS_MAJR_CODE
                                                                                                                ,c2.SORLFOS_TERM_CODE_CTLG
                                                                                                                ,c2.SORLFOS_TERM_CODE_END
                                                                                                                ,c2.SORLFOS_DEPT_CODE
                                                                                                                ,c2.SORLFOS_MAJR_CODE_ATTACH
                                                                                                                ,c2.SORLFOS_LFOS_RULE
                                                                                                                ,c2.SORLFOS_CONC_ATTACH_RULE
                                                                                                                ,c2.SORLFOS_START_DATE
                                                                                                                ,c2.SORLFOS_END_DATE
                                                                                                                ,c2.SORLFOS_TMST_CODE
                                                                                                                ,null--SORLFOS_ROLLED_SEQNO
                                                                                                                ,c2.SORLFOS_USER_ID_UPDATE
                                                                                                                ,c2.SORLFOS_ACTIVITY_DATE_UPDATE
                                                                                                                ,null--SORLFOS_CURRENT_CDE
                                                                                                                ,null  --SORLFOS_SURROGATE_ID
                                                                                                                ,null -- SORLFOS_VERSION
                                                                                                                ,null); --SORLFOS_VPDI_CODE             
                                                                                                                
                                                                Exception
                                                                       When Others then 
                                                                        NULL;                                                                                                                  
                                                                End;    
                                                                                                                                                           
                                                                
                                                                
                                                                
                                                End loop C2;
                                                                                        

                                End loop C1;
                                
                   End loop c;            
    
           --     Commit;
                
                Begin
                
                    Delete shrtckd
                    where  SHRTCKD_PIDM = pidm ;
             --       Commit;    
                
                    insert into shrtckd
                    select shrtckn_pidm,shrtckn_term_code, shrtckn_seq_no, shrdgmr_seq_no, sysdate, 'Y', null, null, user, 'CONVALIDACION', null
                    from shrtckn, shrdgmr
                    where shrtckn_pidm=shrdgmr_pidm
                    and     shrtckn_course_comment=shrdgmr_program
                    and   SHRDGMR_PIDM  = pidm
                    order by shrtckn_pidm, shrtckn_seq_no;
                  --  commit;
                    Exception
                When Others then 
                   null;    
                End;
                
  
                Begin
                
                    delete from shrtrcd
                    where  SHRTRCD_PIDM = pidm;
                  --  commit;
                    
                    insert into shrtrcd
                    select shrtrcr_pidm, shrtrcr_trit_seq_no, shrtrcr_tram_seq_no, shrtrcr_seq_no, shrdgmr_seq_no, sysdate, 'Y', null, null, USER, 'CONVALIDACION', null
                    from shrtrcr, shrdgmr
                    where shrtrcr_pidm=shrdgmr_pidm
                    and     shrtrcr_program=shrdgmr_program
                    and   SHRDGMR_PIDM  = pidm
                    order by shrtrcr_pidm;
              --      commit;
                Exception
                When Others then 
                   null;    
                End;

 --Commit;

End shrdgmr;


procedure bitacora (pidm in number, vl_periodo in varchar2, sp in number, vl_programa in varchar2)

as

  vn_sec_SGRSCMT number:=0;
  l_descripcion varchar2(2000):= null;
  
Begin 
    
    Begin
          SELECT NVL(MAX(SGRSCMT_SEQ_NO),0)+1
        INTO vn_sec_SGRSCMT
      FROM SGRSCMT
      WHERE SGRSCMT_PIDM  = pidm
      AND SGRSCMT_TERM_CODE = vl_periodo;
    Exception
            When Others then 
              vn_sec_SGRSCMT :=1;
    End;

     l_descripcion:=    'CONVALIDACION: '||vl_periodo ||' '||vl_programa;


                  
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
            pidm
          , vn_sec_SGRSCMT
          , vl_periodo
          , l_descripcion
          , SYSDATE
          , 'SZFCONV'
          , user
          , sp
         );
    Exception
             WHEN DUP_VAL_ON_INDEX THEN
                    NULL;    
            When Others then 
            null;         
    End;


Exception
    when others then 
        null;
End bitacora;


Function   inscripcion_conv(iden in varchar2, per in varchar2,  subj in varchar2, crse in varchar2, parte in varchar2, n_prog varchar2, title in varchar2, cred in decimal, calif in varchar2, iden2 varchar2, crn varchar2, fecha_inicial varchar2, sp in number ) Return varchar2 

is

periodo varchar2(6);
n_crn    varchar2(5);
n_seq_numb  varchar2(3);
campus varchar2(3);
conta_ptrm number;
conta number;
conta2 number;
ptrm varchar2(3);
inicio date;
fin date;
weeks number;
pidm number;
tckn number;
tckg  number;
--stsp number;
conta_per number;
vl_exito varchar2(2500):='EXITO';
vl_parte varchar2 (6);
vl_existe number:=0;
crn_1 number :=0;
n_nivel varchar2(2):= null;
n_orden number :=0;
vl_calif varchar2(5);
vl_escuela varchar2(5):= null;
per1 varchar2(6):= null;

vl_bloque1 varchar2(2):= null;
vl_bloque2 number:= null;
vl_bloque3 number:= null;
vl_bloque4 varchar2(4):= null;

vl_numero number:=0;
vl_gmod   varchar2(3):= null;





begin


            Begin
                select spriden_pidm 
                    into pidm 
                 from spriden
                where spriden_id=iden 
                and spriden_change_ind is null;
            Exception
            When Others then 
               vl_exito:='Error al buscar Persona: '||sqlerrm;
            End;

            vl_gmod:= null;        
            Begin
                select distinct nvl (SFRSTCR_GMOD_CODE,1) 
                    Into vl_gmod
                from sfrstcr
                where 1=1
                and sfrstcr_pidm = pidm
                and SFRSTCR_TERM_CODE = per
                And SFRSTCR_RSTS_CODE ='RE'
                And SFRSTCR_PTRM_CODE = parte
                and SFRSTCR_RESERVED_KEY =subj||crse;
            Exception
            When Others then 
                vl_gmod:= 1;
            End;




    vl_bloque1 := substr (per, 1,2);
    vl_bloque2 := substr (per, 3,2);
    vl_bloque3 := substr (per, 5,2);

    If        vl_bloque2||vl_bloque3 = '1642' then vl_bloque4 := '1943';
        ElsIf vl_bloque2||vl_bloque3 = '1643' then vl_bloque4 := '1943';
        ElsIf vl_bloque2||vl_bloque3 = '1741' then vl_bloque4 := '1943';
        ElsIf vl_bloque2||vl_bloque3 = '1742' then vl_bloque4 := '1943';
        ElsIf vl_bloque2||vl_bloque3 = '1743' then vl_bloque4 := '1943';
        ElsIf vl_bloque2||vl_bloque3 = '1841' then vl_bloque4 := '2041';
        ElsIf vl_bloque2||vl_bloque3 = '1842' then vl_bloque4 := '2042';
        ElsIf vl_bloque2||vl_bloque3 = '1843' then vl_bloque4 := '2043';
        ElsIf vl_bloque2||vl_bloque3 = '1941' then vl_bloque4 := '2141';
        ElsIf vl_bloque2||vl_bloque3 = '1942' then vl_bloque4 := '2142';
        ElsIf vl_bloque2||vl_bloque3 = '1943' then vl_bloque4 := '2143';
        ElsIf vl_bloque2||vl_bloque3 = '2041' then vl_bloque4 := '2241';
        ElsIf vl_bloque2||vl_bloque3 = '2042' then vl_bloque4 := '2242';
        ElsIf vl_bloque2||vl_bloque3 = '2043' then vl_bloque4 := '2243';
        ElsIf vl_bloque2||vl_bloque3 = '2141' then vl_bloque4 := '2341';
        ElsIf vl_bloque2||vl_bloque3 = '2142' then vl_bloque4 := '2342';
        ElsIf vl_bloque2||vl_bloque3 = '2143' then vl_bloque4 := '2343';
        -------------------------------------------------------------------------
        ElsIf vl_bloque2||vl_bloque3 = '2241' then vl_bloque4 := '2441';
        ElsIf vl_bloque2||vl_bloque3 = '2242' then vl_bloque4 := '2442';
        ElsIf vl_bloque2||vl_bloque3 = '2243' then vl_bloque4 := '2443';  
        ElsIf vl_bloque2||vl_bloque3 = '2341' then vl_bloque4 := '2541';
        ElsIf vl_bloque2||vl_bloque3 = '2342' then vl_bloque4 := '2542';
        ElsIf vl_bloque2||vl_bloque3 = '2343' then vl_bloque4 := '2543';      
        ElsIf vl_bloque2||vl_bloque3 = '2441' then vl_bloque4 := '2641';
        ElsIf vl_bloque2||vl_bloque3 = '2442' then vl_bloque4 := '2642';
        ElsIf vl_bloque2||vl_bloque3 = '2443' then vl_bloque4 := '2643';      
        ElsIf vl_bloque2||vl_bloque3 = '2541' then vl_bloque4 := '2741';
        ElsIf vl_bloque2||vl_bloque3 = '2542' then vl_bloque4 := '2742';
        ElsIf vl_bloque2||vl_bloque3 = '2543' then vl_bloque4 := '2743';       
        ElsIf vl_bloque2||vl_bloque3 = '2641' then vl_bloque4 := '2841';
        ElsIf vl_bloque2||vl_bloque3 = '2642' then vl_bloque4 := '2842';
        ElsIf vl_bloque2||vl_bloque3 = '2643' then vl_bloque4 := '2843';      
        ElsIf vl_bloque2||vl_bloque3 = '2741' then vl_bloque4 := '2941';
        ElsIf vl_bloque2||vl_bloque3 = '2742' then vl_bloque4 := '2942';
        ElsIf vl_bloque2||vl_bloque3 = '2743' then vl_bloque4 := '2943';       
    
          
    End if;
    
    per1:= vl_bloque1||vl_bloque4;
    
    Begin 
        select  count(1)
            Into vl_numero
        from sfrstcr
        where sfrstcr_pidm = pidm
        And SFRSTCR_STSP_KEY_SEQUENCE = sp
        And SFRSTCR_TERM_CODE = per1;
    Exception
        When Others then 
            vl_numero :=0;
    End;
    
    If vl_numero >= 4 then 
    
        vl_bloque2 := substr (per1, 3,2);
        vl_bloque3 := substr (per1, 5,2);
        If vl_bloque3 = 43 then 
           vl_bloque3 := 41;
           vl_bloque2 := vl_bloque2 +1;
        ElsIf vl_bloque3 = 41 then 
            vl_bloque3 := 42;
        ElsIf vl_bloque3 = 43 then 
            vl_bloque3 := 43;            
        end if;
    
        per1:= vl_bloque1||vl_bloque2||vl_bloque3;
    
    End if;
    
    Begin       
            select distinct SOBCURR_LEVL_CODE
            Into n_nivel
            from SOBCURR
            where SOBCURR_PROGRAM = n_prog;
    Exception
        When Others then
            n_nivel := null;        
    End;        
        
    If substr (iden, 1,2) != substr (iden2, 1, 2) then 
        --dbms_output.put_line('Entra a buscar: '|| parte);
        
        If parte != '1' then 

               vl_parte := substr (parte, 2, 2);
               --dbms_output.put_line('corta: '|| vl_parte);
               If substr  (n_prog, 4, 2)  = 'MA' then
                  vl_parte := 'M'||vl_parte;
                   
                --  dbms_output.put_line('ma: '|| vl_parte);
               ElsIf substr  (n_prog, 4, 2)  = 'MS' then
                  vl_parte := 'A'||vl_parte;
                 -- dbms_output.put_line('ms: '|| vl_parte);
               ElsIf substr  (n_prog, 4, 2)  = 'BA' then
                  vl_parte := 'B'||vl_parte;
                --  dbms_output.put_line('ba: '|| vl_parte);
               ElsIf substr  (n_prog, 4, 2)  = 'LI' then
                  vl_parte := 'L'||vl_parte;
                 -- dbms_output.put_line('ba: '|| vl_parte);
               End if;
        Else

        
            Begin
                Select a.SZTPTRM_PTRM_CODE
                    into vl_parte
                from sztptrm a
                where a.SZTPTRM_PROGRAM = n_prog
                and a.SZTPTRM_TERM_CODE like '%'|| substr (per1, 3, 4)
                and a.SZTPTRM_PTRM_CODE in (select min (a1.SZTPTRM_PTRM_CODE)
                                                                 from SZTPTRM a1
                                                                 where a.SZTPTRM_PROGRAM = a1.SZTPTRM_PROGRAM
                                                                 and a.SZTPTRM_TERM_CODE = a1.SZTPTRM_TERM_CODE);
            Exception
            When Others then 
              vl_parte := null; 
              vl_exito := 'Crear configuracion para la parte de periodo  del programa ' || n_prog ||' en el periodo '|| substr (iden, 1,2) ||substr (per1, 3, 4) || ' en la Forma SZTPART';  
        
            End;
            
        End if;       
               
    Else
       vl_parte := parte;
    End if;      

    --periodo:=substr(iden,1,2)||substr(per,3,4);
 --dbms_output.put_line('Parte de Periodo: '|| vl_parte);
 
 If   vl_exito = 'EXITO' then
           Begin
            select count(*) 
                into conta_per
            from stvterm
            where stvterm_code=substr(iden,1,2)||substr(per1,3,4);
          Exception
          when others then 
      --     dbms_output.put_line('Error en STVTERM: '|| sqlerrm);
           conta_per :=0;
          End;
       -- dbms_output.put_line('conta_per:'||conta_per||' periodo:'||substr(iden,1,2)||substr(per,3,4));
        
        if conta_per=0 then
        
            Begin 
                   select distinct z2.dato_destino
                     into periodo
                  from migra.tmp_catalogo z1, migra.tmp_catalogo z2
                  where z1.clave_catalogo='PERIODO' and z1.dato_destino=per1
                  and     z2.clave_catalogo='PERIODO' and z1.dato_origen=z2.dato_origen and z2.col_aux2=substr(iden,2,1);
            Exception
                When Others then 
                  periodo := null;
                --  dbms_output.put_line('Erro al buscar Tmp_Catalogo: '||sqlerrm);
            End;
          
        else
           periodo:=substr(iden,1,2)||substr(per1,3,4);
        end if;
        dbms_output.put_line('busca tmp_catalogo:'||periodo);

        begin
        select  to_number(substr (ssbsect_crn,2,6)) CRN, ssbsect_seq_numb  
        into n_crn, n_seq_numb 
        from ssbsect sb
        where ssbsect_term_code=periodo and ssbsect_subj_code=subj and ssbsect_crse_numb=crse
        and    to_number(substr (ssbsect_crn,2,6)) in (select min(to_number(substr (ssbsect_crn,2,6))) 
        from ssbsect sb1
                       where sb.ssbsect_term_code=sb1.ssbsect_term_code and sb.ssbsect_subj_code=sb1.ssbsect_subj_code and sb.ssbsect_crse_numb=sb1.ssbsect_crse_numb);
        exception when others then
            n_crn:=null; n_seq_numb:=null;
       --     dbms_output.put_line('ErroR BUSCAR GRUPO: '||sqlerrm);
        End;

        dbms_output.put_line('Busca Grupo:'||n_crn ||'*'||n_seq_numb);

        Begin
                     select szvcamp_camp_code 
                        into campus from szvcamp
                    where szvcamp_camp_alt_code=substr(iden,1,2);
        Exception 
        When Others then 
         campus := null;
       --  dbms_output.put_line('Erro al buscar Campus: '||sqlerrm);
        End;            
        
        Begin

                select  count(*) into conta_ptrm
                from sobptrm
                where  sobptrm_term_code=periodo and sobptrm_ptrm_code=vl_parte;
          Exception 
        When Others then 
         conta_ptrm := '0';
      --   dbms_output.put_line('Erro al buscar vl_parte de Periodo: '||sqlerrm);
        End;            
                    
        if conta_ptrm=0 then
           ptrm:='1';
        else
           ptrm:=vl_parte;
        end if;
                    
          
                  dbms_output.put_line('Valores para Pperiodo;'||periodo||'vl_parte:'||vl_parte);       
        Begin
                    select sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
                    into inicio, fin, weeks
                    from sobptrm
                    where sobptrm_term_code=periodo and sobptrm_ptrm_code=vl_parte;
                    dbms_output.put_line('saida Pperiodo;'||inicio||'seman:'||fin||'*'||weeks);
            Exception 
        When Others then 
         inicio := null;
         fin := null;
         vl_exito:= 'Error al obtener Fecha de Inicio: '||sqlerrm;
        End;            
                  
                    
      
        if vl_exito != 'Exito'  then

               crn_1 :=0;
               vl_escuela := null;

                Begin 
                        Select distinct count(1)
                        into crn_1
                        from ssbsect 
                        where ssbsect_term_code= periodo
                    --    And SSBSECT_PTRM_CODE = parte
                        and  substr (ssbsect_crn,1,1) = substr (vl_parte,1,1);
                Exception
                    When Others then 
                      crn_1 :=0;
                End;     
                                    
             --    dbms_output.put_line('RECUPERO crn_1 ' ||crn_1 ||'*'||periodo);        
                                    
                If crn_1 >= 1 then 
                            --  dbms_output.put_line('ENTRO POR EL 1  ' ||'*'||periodo||'*'||vl_parte);
                   Begin

                            select nvl(max(crn),1000)+1 
                                   into n_crn
                            from
                            (
                            select case when 
                            substr(SSBSECT_CRN,1,1) in ('L','M','A','D','N','B', 'X', 'O') then to_number(substr(SSBSECT_CRN,2,100))+1
                            else
                            to_number(SSBSECT_CRN)                
                            end crn
                            from ssbsect 
                            where ssbsect_term_code= periodo);

                             
                            -- dbms_output.put_line('RECUPERO EL CRN' ||'*'||n_crn);
                   Exception   
                            When Others then  
                                n_crn := null;
                             --   dbms_output.put_line('ERROR EN EL 1 ' ||periodo ||sqlerrm);
                   End;                                            


                Else
                             --   dbms_output.put_line('ENTRO POR EL 2' ||'*'||crn_1||'*'||vl_parte);
                         Begin 
                            select nvl(max(crn),1000)+1 
                                   into n_crn
                            from
                            (
                            select case when 
                            substr(SSBSECT_CRN,1,1) in ('L','M','A','D','N','B', 'X','O') then to_number(substr(SSBSECT_CRN,2,100))+1
                            else
                            to_number(SSBSECT_CRN)                
                            end crn
                            from ssbsect 
                            where ssbsect_term_code= periodo);
                          Exception
                                When Others then 
                                     Begin
                                                 select nvl(max(to_number(substr (ssbsect_crn,2,6))),0)+1 
                                                     into n_crn 
                                                from ssbsect a 
                                                where a.ssbsect_term_code= periodo
                                              --  And a.SSBSECT_PTRM_CODE = parte
                                            --     And substr (a.ssbsect_crn, 1, 1)  = vl_parte
                                                 ;
                                                                     
                                     Exception   
                                                When Others then  
                                                    n_crn := null;
                                                --    dbms_output.put_line('ERROR EN EL 2-3' ||periodo ||sqlerrm);
                                     End;                                            


                              --  dbms_output.put_line('ERROR EN EL 2-1' ||periodo ||sqlerrm);

                         End;     
                                                     
                End if;                   
                                                 
                If length (n_crn) between  1 and 4  then 
                  --  dbms_output.put_line('EL VALOR DE LA CADENA' ||n_crn );
                                                    
                      n_crn := substr (vl_parte,1,1)||n_crn;
                    --  dbms_output.put_line('Salida de la corrida ' ||n_crn );  
                ElsIf length (n_crn) between  5 and 5  then   
               --   dbms_output.put_line('VALOR DEL CRN  ' ||n_crn );     
                   n_crn := n_crn ;
              --  dbms_output.put_line('NUEVO VALOR DEL CRN  ' ||n_crn );   
                End if;   
                
                If   length (n_crn) between  2 and 5  then 
               --  dbms_output.put_line('ENTRA A REALIZAR LOS INSERT' ||n_crn );
--                    pkg_utilerias.p_ejecuta_rolado_fecha_mat(iden,null);
--                    Commit; 

                        Begin
                                            
                            insert into ssbsect values (periodo, n_crn, vl_parte, subj, crse, '01', 'A', 'ENL', campus, title, null, null, vl_gmod, null,null, null, null, 'Y', null, 0,0,0, 50, 0, 50, cred, 0, inicio, sysdate,
                             inicio, fin, weeks, null, 0,0,0, null,null, null, null,null,null, null, null,null,null, null, 'Y', 'N', null, null, null, 'NOP', null,null, null, null, null,null, 0, '01', USER, null, 'B', 
                             null,null, null, null,null,null, null, null);
                            -- dbms_output.put_line('Inserta ssbsec ' ||n_crn );  
                                             
                        Exception
                                 WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;                        
                        When Others then 
                           vl_exito := 'Error al crear nuevo grupo ssbsect: '||sqlerrm;
                        End;
                                             
                        Begin     
                                             
                            insert into ssrmeet values(periodo, n_crn, null,null, null, null,null,null, sysdate, inicio, fin, '01', null,null, null, null,null,null,null, 'ENL', null, cred, null, 0, null, null, null, 'CLVI',
                            'CONVALIDACION', USER, null, null, null);      
                       --     dbms_output.put_line('Inserta ssrmeet ' ||n_crn );
                                            
                        Exception
                                   WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;                      
                        When Others then 
                           vl_exito:= 'Error al crear ssrmeet: '||sqlerrm;
                        End;

                


                   --     dbms_output.put_line('Persona: '||pidm);

                        conta:=0;
                                        
                        Begin
                            select count(*) 
                                into conta
                            from sfbetrm
                            where sfbetrm_pidm=pidm and sfbetrm_term_code=periodo;
                        Exception
                        When Others then 
                       --    dbms_output.put_line('Error al buscar sfbetrm: '||sqlerrm);
                           conta:=0;
                        End;

                        if conta = 0 then               
                                    
                            Begin
                                insert into sfbetrm  values(periodo, pidm, 'EL', sysdate, 99.99, 'Y', null, sysdate, sysdate, null, null, null, null, USER, null, 'CONVALIDACION', null, 0, null, null, null, null, USER, null);
                            Exception
                                 WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;                            
                            When Others then 
                               vl_exito:='Error al insertar sfbetrm: '||sqlerrm;
                            End;
                                            
                                            
                        end if;

               
                        begin
                        
                        select distinct SOBCURR_COLL_CODE
                        Into vl_escuela
                        from SOBCURR
                        where SOBCURR_PROGRAM = n_prog;       
                        Exception   
                        When Others then 
                            vl_escuela := null;
                        End;
               
                        If sp > 0 then 

                               Begin
                                        Select count (1)
                                          into  vl_existe
                                        from sfrstcr
                                        where SFRSTCR_TERM_CODE = periodo
                                        and SFRSTCR_PIDM = pidm
                                        and SFRSTCR_CRN = n_crn;
                               Exception
                                when Others then 
                                  vl_existe :=0;
                               End;

                               If vl_existe = 0 then 
                                       
                                      Begin
                                        select distinct SFRSTCR_VPDI_CODE
                                            Into n_orden 
                                        from sfrstcr
                                        Where SFRSTCR_TERM_CODE = periodo
                                        And SFRSTCR_PIDM = pidm
                                        And SFRSTCR_CRN = crn;
                                      Exception
                                        When Others then 
                                         n_orden := null;
                                      End;

                                      
                                     /*     -------------- Ajuste generado para no cambiar los porcentajes de las materias Victor
                                      If calif = '5' then vl_calif :='5.0';
                                      elsif  calif = '6' then vl_calif := '6.0';
                                      elsif  calif = '7' then vl_calif :='7.0';  
                                      elsif  calif = '8' then vl_calif :='8.0';  
                                      elsif  calif = '9' then vl_calif :='9.0';  
                                      elsif  calif = '10' then vl_calif :='10.0';    
                                      else
                                            vl_calif := calif;
                                      End if;
                                    */  ---------------------------- Se apaga este codigo para que la calificacion pase como esta en el programa anterior ..
                                      
                                      vl_calif:= null;
                                       vl_calif := calif;                                      
                                      
                                      
                                      
                                       Begin
                                                insert into sfrstcr values( periodo, pidm, n_crn, null, 1, vl_parte, 'RE', sysdate, null, null, 3, null, cred,null, cred, vl_gmod, calif , null, sysdate,  null,null,null,null,null,null,null,null,null,null,null,null, sysdate, sysdate, n_nivel, campus, 
                                                null,null,null,null,null,null,null,null,null,null,null,'CONVALIDACION', null,null,null,null,null,null,null,null,null,null, sp, null, n_seq_numb, null, null,null, null, USER, n_orden);
                                                        
                                       Exception
                                            WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;                                       
                                        When Others then 
                                           vl_exito:='Error al insertar sfrstcr: '||sqlerrm;
                                       End;
                               End if;
                               vl_existe :=0; 
                               
                              Begin
                                        Select count (1)
                                            into vl_existe
                                        from sfrareg
                                        where SFRAREG_TERM_CODE = periodo
                                        and SFRAREG_PIDM = pidm
                                        and SFRAREG_CRN = n_crn;
                               Exception
                                when Others then 
                                  vl_existe :=0;
                               End;
               
                               If vl_existe = 0 then 
                                   
                                    Begin
                                     insert into sfrareg values(pidm, periodo, n_crn, 0, 'RE', inicio, fin, 'N', 'N', sysdate, user, null,null,null,null,null,null,null,null, 'CONVALIDACION', sysdate, null, null, null);
                                    Exception
                                        WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;                                    
                                    When Others then 
                                       vl_exito:='Error al insertar sfrareg: '||periodo||'*'||vl_parte||'*'||inicio||'*'||fin||'*'||weeks;
                                       
                                    End;
                               End if;
                        End if;            
                
         
                        Begin
                                select nvl(max(shrtckn_seq_no),0) +1 
                                    into tckn 
                                 from shrtckn
                                 where shrtckn_pidm=pidm
                                 And shrtckn_term_code = periodo;
                                 
                        Exception
                            When Others then 
                            tckn :=0;
                           --    dbms_output.put_line('Error al Buscar shrtckn: '||sqlerrm);
                        End;

                      conta:=0;
                        
                        Begin
                           select count(*) 
                                into conta 
                            from shrttrm
                            where shrttrm_pidm=pidm 
                            and shrttrm_term_code=periodo;
                        Exception
                            When Others then 
                            conta :=0;
                            --   dbms_output.put_line('Error al Buscar shrttrm: '||sqlerrm);
                        End;
                
                        if conta=0 then
                        
                           Begin
                                insert into shrttrm values(pidm, periodo, 'S', 'N', 'G', sysdate, null, null, null, null, null, null, null, null, sysdate, null, null, null, null, null, null, null, null, null, null, null, USER, 'CONVALIDACION', null);
                           Exception
                                 WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;                           
                                When Others then 
                                conta :=0;
                                   vl_exito:='Error al Insertar shrttrm: '||sqlerrm;
                           End;
                                    
                                    
                        end if;
                
                        Begin
                            select count(*) 
                             into conta2 
                            from shrtckn
                            where shrtckn_pidm=pidm 
                            and shrtckn_term_code=periodo 
                            and shrtckn_crn=n_crn;
                        Exception
                            When Others then 
                            conta2 :=0;
                               vl_exito:='Error al buscar shrtckn: '||sqlerrm;
                        End;
                    
                
                        if conta2 > 0 then
                          NULL;  -- dbms_output.put_line(pidm||' '||periodo||' '||tckn||' '||n_crn||' '||subj||' '||crse);
                        else
                            
                            Begin
                                    insert into shrtckn values(pidm, periodo, tckn, n_crn, subj, crse, vl_escuela, campus, '9990', null, null, title, null, null, null, sysdate, vl_parte, n_seq_numb, inicio, fin, null, 'ENL', null, null, null, null, title, 
                                    sp, null, null, USER, 'CONVALIDACION', null);
                            Exception
                                 WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;                            
                                When Others then 
                                   vl_exito:='Error al insert shrtckn: '||vl_parte ||' '||sqlerrm;
                            End;
                              
                        tckg:= null;            
 
                        Begin
                                select nvl(max(SHRTCKG_SEQ_NO),0) +1 
                                    into tckg
                                 from shrtckg
                                 where SHRTCKG_PIDM=pidm
                                 And SHRTCKG_TERM_CODE = periodo
                                 And SHRTCKG_TCKN_SEQ_NO = tckn;
                                 
                        Exception
                            When Others then 
                            tckg :=0;
                           --    dbms_output.put_line('Error al Buscar shrtckn: '||sqlerrm);
                        End;

                           
                            
                              
                            Begin
                                insert into shrtckg values(pidm, periodo, tckn, tckg, null, calif,vl_gmod,cred, 'OE', null, sysdate, USER, sysdate, 'EQUIVA', periodo, 'CONVALIDACION', USER, cred, null, null, null, null);
                            Exception
                                 WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;                            
                                When Others then 
                                   vl_exito:='Error al insert shrtckg: '||sqlerrm;
                            End;
                                
                            Begin
                            insert into shrtckl values(pidm, periodo, tckn, n_nivel, sysdate, 'Y', null, null, USER, 'CONVALIDACION', null);
                            Exception
                                 WHEN DUP_VAL_ON_INDEX THEN
                                        NULL;                            
                                When Others then 
                                   vl_exito:='Error al insert shrtckl: '||sqlerrm;
                            End;
                                
                                
                        end if;
             
                        --  commit;
                   
                        conta2:=0;
                        select count(*) into conta2 from shrdgmr
                        where shrdgmr_pidm=pidm and shrdgmr_program=n_prog;
                    
                    
                    
                        if conta2 = 0 then
                           pkg_inserta.shrdgmr(pidm, n_prog, sp);
                        end if;
                Else
                    vl_exito := 'ERROR AL ENTRAR A REALIZAR LOS INSERT222' ||n_crn;
                        --  dbms_output.put_line('ERROR AL ENTRAR A REALIZAR LOS INSERT' ||n_crn ;     
                End if;
                
        
        else
             --   dbms_output.put_line('valor Mayor al maximo ' ||length (n_crn) ||'*'||n_crn);         
                --vl_exito:= 'valor Mayor al maximo ' ||length (n_crn);     
                vl_exito :='valor Mayor al maximo ' ||length (n_crn) ||'*'||n_crn;         
                                   
        End if;        
    
 Else
  NULL;--  dbms_output.put_line('No tiene CRN y Fecha de INICio ' ||crn_1 ||'*'||periodo);                         
 End if;    
--dbms_output.put_line('Error GEneral: '||vl_exito);

If vl_exito = 'EXITO' then
  Commit;
Else 
    Rollback;
End if;

Return vl_exito;

Exception
When Others then 
  vl_exito:= 'Error General ' ||sqlerrm;        
  Return vl_exito;
end inscripcion_conv;


procedure borra_horario (pidm in number, sp in number ) is 

Begin

        For c in (
        
                        select *
                        from sfrstcr
                        where SFRSTCR_PIDM =  pidm
                        And SFRSTCR_STSP_KEY_SEQUENCE = sp
                        
                    ) loop
---------------------------------------------
                
                    For c1 in (

                                    Select *
                                    from shrtckn
                                    where SHRTCKN_PIDM = c.SFRSTCR_PIDM
                                    And SHRTCKN_STSP_KEY_SEQUENCE = c.SFRSTCR_STSP_KEY_SEQUENCE
                                    And SHRTCKN_CRN = c.SFRSTCR_CRN
                                    
                                  ) loop
----------------------------------------------------------

                                    Begin 
                                        delete shrtckg
                                        Where SHRTCKG_PIDM = c1.SHRTCKN_PIDM
                                        And SHRTCKG_TCKN_SEQ_NO  = c1.SHRTCKN_SEQ_NO
                                        And SHRTCKG_TERM_CODE = c1.SHRTCKN_TERM_CODE;
                                   Exception
                                    When Others then 
                                        null;     
                                   End;

                                   Begin
                                        delete  shrtckl
                                        where SHRTCKL_PIDM = c1.SHRTCKN_PIDM
                                        And SHRTCKL_TERM_CODE = c1.SHRTCKN_TERM_CODE
                                        And SHRTCKL_TCKN_SEQ_NO =  c1.SHRTCKN_SEQ_NO;
                                   Exception
                                    When Others then 
                                        null;     
                                   End;                                        

                                   Begin 
                                            delete shrchrt
                                            Where SHRCHRT_PIDM = c1.SHRTCKN_PIDM
                                            And SHRCHRT_TERM_CODE  = c1.SHRTCKN_TERM_CODE;
                                   Exception
                                    When Others then 
                                        null;     
                                   End;                                     

                                  Begin
                                        delete shrttrm
                                        Where SHRTTRM_PIDM =c1.SHRTCKN_PIDM
                                        And SHRTTRM_TERM_CODE = c1.SHRTCKN_TERM_CODE;
                                  Exception
                                    When Others then 
                                        null;     
                                  End ;
                
                                   Begin
                                            delete shrtgpa
                                            Where SHRTGPA_PIDM = c1.SHRTCKN_PIDM
                                            And SHRTGPA_TERM_CODE = c1.SHRTCKN_TERM_CODE;
                                    Exception
                                    When Others then 
                                        null;     
                                   End;                                          

                                   Begin
                                            delete shrtckn
                                            where SHRTCKN_PIDM = c1.SHRTCKN_PIDM
                                            And SHRTCKN_STSP_KEY_SEQUENCE = c1.SHRTCKN_STSP_KEY_SEQUENCE
                                            And SHRTCKN_CRN = c1.SHRTCKN_CRN;
                                   Exception
                                    When Others then 
                                        null;     
                                   End;                                          
                                                                         
                                  Begin
                                            delete sfrstcr
                                            where SFRSTCR_PIDM = c1.SHRTCKN_PIDM
                                            And SFRSTCR_STSP_KEY_SEQUENCE = c1.SHRTCKN_STSP_KEY_SEQUENCE
                                            And SFRSTCR_CRN = c1.SHRTCKN_CRN;
                                  Exception
                                    When Others then 
                                        null;     
                                  End;                                                                
                                  
                    End Loop;
                    Commit;
           End Loop;
           

End borra_horario;

end pkg_inserta;
/

DROP PUBLIC SYNONYM PKG_INSERTA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_INSERTA FOR BANINST1.PKG_INSERTA;
