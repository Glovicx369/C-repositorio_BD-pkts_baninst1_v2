DROP PACKAGE BODY BANINST1.PKG_PAGOS_AUT;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_PAGOS_AUT AS
--Create by FrankPérez  Date: Mayo.2023
--Automatización de apliaciones de pagos por medio de tgrappl & tvrappl
--  
          PROCEDURE p_tgrappl_nosleep_air (
                      p_process          IN VARCHAR2,
                      p_nosleep_user_id  IN VARCHAR2,
                      p_jprm_code        IN VARCHAR2,
                      p_new_id           IN varchar2,
                      p_tipomat         IN VARCHAR2,
                      p_id              IN Number
                                          )
          IS
            lv_one_up_no            number(9);
            lv_printer              gjbpdft.gjbpdft_value%type;
            lv_form_name            gtvsdax.gtvsdax_external_code%type;
            lv_gjbpdft_row          gjbpdft%rowtype;
            lc_return_msg           varchar2(500);

                FUNCTION load_gjbprun RETURN VARCHAR2 IS
                    lc_dummy number:=0;
                    lc_result varchar2(400):='EXITO';
                    
                      CURSOR gjbpdft_c IS
                        select *
                          from gjbpdft
                         where gjbpdft_job       = p_process
                           and gjbpdft_jprm_code = p_jprm_code
                           and gjbpdft_user_id   = p_nosleep_user_id;
                BEGIN
            -- Obtain next one-up number and delete any residual GJBPRUN.
                  w_plsql_stmnt := 'BEGIN goknosl.p_next_one_up_no(:a); END;';
                  EXECUTE IMMEDIATE w_plsql_stmnt
                       USING IN OUT lv_one_up_no ;
                  w_plsql_stmnt := 'BEGIN goknosl.p_clear_gjbprun(:a, :b); END;';
                  EXECUTE IMMEDIATE w_plsql_stmnt
                              USING p_process, lv_one_up_no ;

                  w_plsql_stmnt := 'BEGIN goknosl.p_form_name_for_process(:a, :b); END;';
                  EXECUTE IMMEDIATE w_plsql_stmnt
                       USING IN OUT lv_form_name, p_process ;


                  open gjbpdft_c;
                  LOOP
                    fetch gjbpdft_c into lv_gjbpdft_row;
                    exit when gjbpdft_c%notfound;
                    IF lv_gjbpdft_row.gjbpdft_number = '01' THEN
                      lv_gjbpdft_row.gjbpdft_value := p_new_id;
                    END IF;
                    BEGIN
                        begin
                          insert into gjbprun
                                     (gjbprun_job,
                                      gjbprun_one_up_no,
                                      gjbprun_number,
                                      gjbprun_activity_date,
                                      gjbprun_value)
                               values(p_process,
                                      lv_one_up_no,
                                      lv_gjbpdft_row.gjbpdft_number,
                                      SYSDATE,
                                      lv_gjbpdft_row.gjbpdft_value);
                        lc_dummy:=1;
                        --    dbms_output.put_line(p_process||' '||lv_one_up_no||' '||lv_gjbpdft_row.gjbpdft_number||' '||lv_gjbpdft_row.gjbpdft_value||' SQL%COUNT '||SQL%ROWCOUNT);
                        exception when others then
                            dbms_output.put_line('Error:'||sqlerrm||' '||p_process||' '||lv_one_up_no||' '||lv_gjbpdft_row.gjbpdft_number||' '||lv_gjbpdft_row.gjbpdft_value);
                            lc_result:='Error:'||sqlerrm||' '||p_process||' '||lv_one_up_no||' '||lv_gjbpdft_row.gjbpdft_number||' '||lv_gjbpdft_row.gjbpdft_value;
                            lc_dummy:=0;
                        end;                
                    END;
                  END LOOP;
                  close gjbpdft_c;
                  if lc_dummy=0 Then
                        return lc_result;
                  else 
                        return lc_result;
                  end if;
                END load_gjbprun;

          BEGIN

                lc_return_msg:=load_gjbprun;
                
                if lc_return_msg = 'EXITO' then
                       
                        p_submit_gjajobs (
                              p_process_name => lower(p_process),
                              p_process_type => 'C',
                              p_user_id      => w_null_varchar2_value,
                              p_password     => w_null_varchar2_value,
                              p_one_up       => lv_one_up_no,
                              p_printer      => lv_printer,
                              p_form_name    => lv_form_name,
                              p_submit_time  => w_null_varchar2_value,
                              p_return_msg   => lc_return_msg
                                             );
                                     
                        p_track_pagod(  p_id         => p_id,
                                        p_one_up_no  => lv_one_up_no,
                                        p_matricula => p_new_id,
                                        p_msg       => lc_return_msg,
                                        p_filelog   => 'tvrappl_'||lv_one_up_no||'.log',
                                        p_filelis   => 'tvrappl_'||lv_one_up_no||'.lis',
                                        p_tipomat   =>  p_tipomat);
                else
                        p_track_pagod(  p_id         => p_id,
                                        p_one_up_no  => -99,
                                        p_matricula => p_new_id,
                                        p_msg       => lc_return_msg,
                                        p_tipomat   =>  p_tipomat);
                end if;                                       
                             
--dbms_output.put_line(p_process||' '||lv_one_up_no||' '||lv_printer||' '||lv_form_name);

          END p_tgrappl_nosleep_air;
          
  PROCEDURE p_submit_gjajobs (
              p_process_name IN VARCHAR2,
              p_process_type IN VARCHAR2,
              p_user_id      IN VARCHAR2,
              p_password     IN VARCHAR2,
              p_one_up       IN VARCHAR2,
              p_printer      IN VARCHAR2,
              p_form_name    IN VARCHAR2,
              p_submit_time  IN VARCHAR2,
              p_return_msg   OUT VARCHAR2
                             )
  IS

     jobsub_shell             gtvsdax.gtvsdax_external_code%type default NULL;


     return_pipe          varchar2(30)   := NULL;
     command_type         varchar2(4)    := 'HOST';

     command_string       varchar2(100);
     max_wait_send        integer        := 30;
     max_size             integer        := 8192;
     max_wait_receive     integer        := 30;

     send_status          number;
     receive_status       number;
     return_message       varchar2(80);

     nosleep_user_id    constant varchar2(20)   :=  'NOSLEEP';
     nosleep_pw         varchar2(20);
     nosleep_pw_hexstring     VARCHAR2(32) := NULL;
     
     CURSOR nosleep_pw_c IS
     select gtvsdax_desc || substr(gtvsdax_external_code,1,2)
       from gtvsdax
      where gtvsdax_internal_code_group = nosleep_user_id
        and gtvsdax_internal_code       = 'DEBUG'
        and gtvsdax_internal_code_seqno = 1;     

  BEGIN
    BEGIN
       RETURN_PIPE := GOKDBMS.PIPE_UNIQUE_SESSION_NAME;
       GOKDBMS.PIPE_PURGE(RETURN_PIPE);     

        jobsub_shell := 'gjajobs.shl';

         OPEN  nosleep_pw_c;
         FETCH nosleep_pw_c into nosleep_pw_hexstring;
         CLOSE nosleep_pw_c;
         GSPCRPU.P_UNAPPLY_V02(hextoraw(nosleep_pw_hexstring),nosleep_pw);

        command_string := jobsub_shell            || ' ' ||
                       p_process_name          || ' ' ||
                       p_process_type          || ' ' ||
                       lower(nosleep_user_id)  || ' ' ||
                       nosleep_pw              || ' ' ||
                       p_one_up                || ' ' ||
                       p_printer               || ' ' ||
                       p_form_name             || ' ' ||
                       p_submit_time           || ' ';


--        dbms_output.put_line('pipe:'||command_string);
       GOKDBMS.pipe_pack_message (command_type);
       GOKDBMS.pipe_pack_message (command_string);
       GOKDBMS.pipe_pack_message (return_pipe);
-- --
       send_status := GOKDBMS.pipe_send_message ('GURJOBS', max_wait_send, max_size);
       IF send_status = 0 THEN
            receive_status := GOKDBMS.pipe_receive_message (return_pipe, max_wait_receive);
            IF receive_status = 0 then
                GOKDBMS.pipe_unpack_message (return_message);  
                P_RETURN_MSG:= return_message;
            ELSE 
                P_RETURN_MSG:= 'Estatus de pipe 1:'||receive_status;
            END IF;
        ELSE 
            P_RETURN_MSG:= 'Estatus de pipe 2:'||receive_status;
       END IF;

    EXCEPTION
        WHEN OTHERS THEN
          p_return_msg:='Error ejecutar p_submit_gjajobs: '||sqlerrm;
    END;
  END p_submit_gjajobs;

   PROCEDURE p_track_pagoe( p_id  number,
                            p_msg  varchar2 default null,
                            p_fecini date default null,
                            p_fecfin date default null,
                            p_totdom number default null,
                            p_totres number default null) is
        lc_count number:=0;
   BEGIN
        begin
            Select 1 into lc_count
            from tztbepm 
            Where id = p_id;
        Exception When Others Then lc_count:=0;
        End;
        IF lc_count=0 THEN
            BEgin
                Insert into tztbepm 
                    values (p_id,
                            p_msg,
                            p_fecini,
                            p_fecfin,
                            sysdate,
                            p_totdom,
                            p_totres,
                            user);
                    COMMIT;

            EXCEPTION WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('ERROR EN p_track_pagoe: '||SQLERRM);
            END;
                        
        else
            BEgin
                Update tztbepm Set
                            msg= Nvl(p_msg,msg),
                            fec_ini=Nvl(p_fecini,fec_ini),
                            fec_fin=Nvl(p_fecfin,fec_fin),
                            tot_dom=Nvl(p_totdom,tot_dom),
                            tot_res=Nvl(p_totres,tot_res),
                            usuario=user, 
                            fec_act=sysdate
                 Where id=p_id;
                    COMMIT;

            EXCEPTION WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('ERROR EN p_track_pagoe: '||SQLERRM);
            END;        
        END IF;
        
   END  p_track_pagoe;

   PROCEDURE p_track_pagod( p_id in number,
                            p_one_up_no  number,                            
                            p_matricula varchar2,
                            p_msg in varchar2 default null,
                            p_filelog varchar2 default null,
                            p_filelis varchar2 default null,
                            p_tipomat varchar2 default null) is
   BEGIN
          BEgin
                Insert into tztbdpm 
                    values (p_id,
                            p_one_up_no,
                            p_matricula,
                            p_msg,
                            p_filelog,
                            p_filelis,
                            p_tipomat,
                            sysdate,
                            user);
                    COMMIT;

            EXCEPTION WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('ERROR EN p_track_pagod: '||SQLERRM);
            END;
   END  p_track_pagod;  
   
   PROCEDURE p_app_pagos is
        Cursor Alum_Dom is
            select distinct tztdomp_matricula id
                    from TZTDOMP ;
--                    where rownum <55;

        Cursor Alum_Rest is
            select distinct TZTRESP_MATRICULA id
                    from TZTRESP ;
--                    where rownum <55;
                    
        lc_id       number;            
        lc_totdom   number:=0;
        lc_totres   number:=0;
        
   BEGIN
    --Inicia Procesar alumnos con pagos domiciliados
    lc_id:=TZSBEPM.NextVal;
    dbms_output.put_line(TO_CHAR(sysdate, 'DD/MM/YYYY HH24:MI:SS')||'->Inicia Ejecución Alumnos Pagos Domiciliados');    
    p_track_pagoe(  p_id        => lc_id,
                    p_msg       => 'Inicia Ejecución Alumnos Pagos Domiciliados',
                    p_fecini    => sysdate);  
                      
    FOR pob IN Alum_Dom LOOP
                baninst1.pkg_pagos_aut.p_tgrappl_nosleep_air (
                              p_process             =>'TVRAPPL',
                              p_nosleep_user_id     =>'USUARIO04',
                              p_jprm_code           =>'APLICA PAGOS',
                              p_new_id            => pob.id,
                              p_tipomat           => 'D',
                              p_id                => lc_id
                                          );
                commit;                                            
                lc_totdom:=lc_totdom+1;

    END LOOP;
    p_track_pagoe(  p_id  => lc_id,
                    p_msg  => 'Finaliza Alumnos Pagos Domiciliados', 
--                    p_fecfin =>sysdate,
                    p_totdom =>lc_totdom);
    dbms_output.put_line(TO_CHAR(sysdate, 'DD/MM/YYYY HH24:MI:SS')||'->Finaliza Ejecución Alumnos Pagos Domiciliados');    
                    
----------------------------
    --Inicia Procesar alumnos con pagos RESTANTES    
    p_track_pagoe(  p_id        => lc_id,
                    p_msg       => 'Inicia Ejecución Alumnos Pagos Restantes',
                    p_fecini    => sysdate);  
     dbms_output.put_line(TO_CHAR(sysdate, 'DD/MM/YYYY HH24:MI:SS')||'->Inicia Ejecución Alumnos Pagos Restantes');    
                     
    FOR pob IN Alum_Rest LOOP
                baninst1.pkg_pagos_aut.p_tgrappl_nosleep_air (
                              p_process             =>'TVRAPPL',
                              p_nosleep_user_id     =>'USUARIO04',
                              p_jprm_code           =>'APLICA PAGOS',
                              p_new_id            => pob.id,
                              p_tipomat           => 'R',
                              p_id                => lc_id
                                          );
                commit;                                            
                lc_totres:=lc_totres+1;
                DBMS_LOCK.SLEEP(0.5);
    END LOOP;
    p_track_pagoe(  p_id  => lc_id,
                    p_msg  => 'Finaliza Alumnos Pagos Restantes', 
                    p_fecfin =>sysdate,
                    p_totres =>lc_totres);
     dbms_output.put_line(TO_CHAR(sysdate, 'DD/MM/YYYY HH24:MI:SS')||'->Finaliza Ejecución Alumnos Pagos Restantes');    
                    
    Commit;
    Exception When Others Then
        p_track_pagoe(  p_id  => lc_id,
                        p_msg  => 'Finaliza proceso p_app_pagos con error:'||sqlerrm,
                        p_fecfin =>sysdate);
                   
   END p_app_pagos;         

END PKG_PAGOS_AUT;
/

DROP PUBLIC SYNONYM PKG_PAGOS_AUT;

CREATE OR REPLACE PUBLIC SYNONYM PKG_PAGOS_AUT FOR BANINST1.PKG_PAGOS_AUT;
