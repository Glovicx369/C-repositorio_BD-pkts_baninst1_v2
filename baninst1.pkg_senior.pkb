DROP PACKAGE BODY BANINST1.PKG_SENIOR;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_SENIOR
as
     function F_ALUMNOS_SENIOR (p_pidm number,p_fecha_incio date, p_materia_padre varchar2, p_periodo varchar2, p_ptrm_code varchar2)
     return varchar2
     as
        l_retorna   varchar2(100):='EXITO';
        l_matricula varchar2(10);
     begin

        begin

            select distinct spriden_id
            into l_matricula
            from spriden
            where 1 = 1
            and spriden_change_ind is null
            and spriden_pidm = p_pidm;

        exception when others then
            null;
        end;

        begin
            insert into SZTSENR VALUES(p_pidm,
                                       l_matricula,
                                       p_fecha_incio,
                                       p_materia_padre,
                                       '1',
                                       SYSDATE,
                                       USER,
                                       'SSEN',
                                       null,
                                     null,
                                     p_periodo,
                                     p_ptrm_code
                                       );


        exception when others then
            l_retorna:='ERROR '||sqlerrm;
        end;

        if l_retorna='EXITO' then

            commit;

        else

            rollback;

        end if;

        return l_retorna;
     end;
--
--
     function F_ALUMNOS_COUR (p_pidm number,p_fecha_incio date,p_programa varchar2,p_origen varchar2)
     return varchar2
     as
        l_retorna   varchar2(100):='EXITO';
        l_matricula varchar2(10);
        l_contar    number;
     begin

        begin

            select distinct spriden_id
            into l_matricula
            from spriden
            where 1 = 1
            and spriden_change_ind is null
            and spriden_pidm = p_pidm;

        exception when others then
            null;
        end;

        begin

            select count(*)
            into l_contar
            from SZTSENR
            where 1 = 1
            and SZTSENR_pidm = p_pidm
            and SZTSENR_ESTATUS = '0';

        exception when others then
            null;
        end;

        if l_contar = 0 then

            BEGIN

                INSERT INTO SZTSENR VALUES(P_PIDM,
                                           l_matricula,
                                           p_fecha_incio,
                                           null,
                                           '1',
                                           SYSDATE,
                                           USER,
                                           'COUR',
                                           p_programa,
                                           p_origen,
                                         null,
                                         null
                                           );


            exception when others then
                l_retorna:='ERROR '||sqlerrm;
            end;


        else

            BEGIN

                UPDATE SZTSENR SET  SZTSENR_ESTATUS ='1'
                where 1 = 1
                and SZTSENR_pidm = p_pidm;

            EXCEPTION WHEN OTHERS THEN
                l_retorna:='No se puede actualizar '||sqlerrm;
            END;


        end if;

        if l_retorna='EXITO' then

            commit;

        else

            rollback;

        end if;

        return l_retorna;
     end;
--
--
    function f_cancela_cour (p_pidm number)
    return varchar2
    is
        l_retorna varchar2(100):='EXITO';
    begin

        BEGIN

            UPDATE SZTSENR SET  SZTSENR_ESTATUS ='0'
            where 1 = 1
            and SZTSENR_pidm = p_pidm;


        EXCEPTION WHEN OTHERS THEN
            l_retorna:='No se puede actualizar '||sqlerrm;
        END;
        RETURN l_retorna;

        if l_retorna ='EXITO' then

            commit;
        else
            rollback;
        end if;

    end;
--
--
    function f_valida_bimestre(p_matricula varchar2,
                               p_nivel     varchar2)
    return varchar2
    is
        l_no_insc      number;
        l_retorna      varchar2(100);
        l_cuenta_para  NUMBER;
    begin


        SELECT COUNT (*)
        into l_no_insc
        from (
             SELECT DISTINCT  (z.SFRSTCR_term_CODE || z.SFRSTCR_ptrm_CODE) p_periodo
             FROM sfrstcr Z
             WHERE 1=1
             AND z.SFRSTCR_PIDM = fget_pidm(p_matricula)
             AND z.SFRSTCR_RSTS_CODE = 'RE'
             AND z.SFRSTCR_ptrm_CODE NOT IN ('M0A', 'M0C', 'A0A', 'A0C')
             AND SUBSTR (z.SFRSTCR_TERM_CODE, 5,1)NOT IN ('8', '9')
             AND z.SFRSTCR_STSP_KEY_SEQUENCE = (SELECT MAX (z1.sfrstcr_stsp_key_sequence)
                                                FROM sfrstcr z1
                                                WHERE 1=1
                                                AND z.SFRSTCR_PIDM = z1.SFRSTCR_PIDM )
                                                );
        begin

            SELECT COUNT(*)
            into l_cuenta_para
            from zstpara
            where 1 = 1
            and ZSTPARA_MAPA_ID ='BIMETRES_1SS'
            and ZSTPARA_PARAM_ID = substr(p_matricula,1,2)||','||p_nivel
            and l_no_insc  between ZSTPARA_PARAM_DESC and ZSTPARA_PARAM_VALOR;

        exception when others then
            l_cuenta_para:=null;
        end;

        if l_cuenta_para > 0 then

            l_retorna:='EXITO';

        else
            l_retorna:='Fuera de rango bim '||'B'||l_no_insc;

        end if;

        return(l_retorna);
    end;
--
--
    function f_fech_cour_fil (p_matricula varchar2,
                              p_nivel     varchar2)
    return date
    IS
        l_fecha_min date;
    BEGIN

       begin

            select MIN(SOBPTRM_START_DATE)
            into l_fecha_min
            from sobptrm
            where 1 = 1
            and SOBPTRM_START_DATE between sysdate  and SOBPTRM_END_DATE
            AND SUBSTR(SOBPTRM_TERM_CODE,1,5) NOT IN (8,9)
            and substr(SOBPTRM_TERM_CODE,1,2) =substr(p_matricula,1,2)
            and exists(select *
                       from zstpara
                       where 1 = 1
                       and ZSTPARA_MAPA_ID ='UPSELLING'
                       and  ZSTPARA_PARAM_ID = SOBPTRM_PTRM_CODE
                       and  substr(ZSTPARA_PARAM_ID,1,1)=DECODE(p_nivel,'MS','A',substr(p_nivel,1,1))
                        );

       exception when others then
            l_fecha_min:=null;
       end;

       return l_fecha_min;

    END;

------
------
function F_ALUMNOS_COUR_FIL (P_PIDM NUMBER, P_FECHA_INCIO DATE,P_ORIGEN VARCHAR2) RETURN VARCHAR IS

        l_retorna   varchar2(100):='EXITO';
        l_matricula varchar2(10);
        l_program VARCHAR2 (20) := NULL;
        l_contar    number;
     begin

        begin

            select distinct spriden_id
            into l_matricula
            from spriden
            where 1 = 1
            and spriden_change_ind is null
            and spriden_pidm = p_pidm;

        exception when others then
            null;
        end;


        begin

            select count(*)
            into l_contar
            from SZTSENR
            where 1 = 1
            and SZTSENR_pidm = p_pidm
            AND SZTSENR_ORIGEN=P_ORIGEN
            and SZTSENR_ESTATUS = '0';

        exception when others then
            null;
        end;

        if l_contar = 0 then

            BEGIN
                   l_program:=pkg_senior.fget_PROGRAMA(P_PIDM);

                INSERT INTO SZTSENR VALUES(P_PIDM,
                                           l_matricula,
                                           p_fecha_incio,
                                           null,
                                           '1',
                                           SYSDATE,
                                           USER,
                                           'COUR',
                                           l_program,
                                           P_ORIGEN,
                                           null,
                                           null
                                           );


            exception when others then
                l_retorna:='ERROR '||sqlerrm;
            end;


        else

            BEGIN

                UPDATE SZTSENR SET  SZTSENR_ESTATUS ='1'
                where 1 = 1
                and SZTSENR_pidm = p_pidm
                AND SZTSENR_ORIGEN=P_ORIGEN ;

            EXCEPTION WHEN OTHERS THEN
                l_retorna:='No se puede actualizar '||sqlerrm;
            END;


        end if;

        if l_retorna='EXITO' then

            commit;

        else

            rollback;

        end if;

        return l_retorna;
     end;

     FUNCTION fget_PROGRAMA(P_PIDM NUMBER) RETURN VARCHAR IS
  V_PROGRAMA VARCHAR(20);

         BEGIN
          BEGIN

              select distinct x.programa
                    into  V_PROGRAMA
                    from tztprog X
                    where 1 = 1
                    and x.pidm = p_pidm
                    and SP = (select max (x1.sp)
                                    from tztprog x1
                                    where 1=1
                                    and x.PIDM = x1.pidm
                                    );
        --            dbms_output.put_line('PROGRAMA'||' '||V_PROGRAMA);
               exception
               when no_data_found then
               NULL;


           END;
          RETURN(V_PROGRAMA);
         END;

end;
/

DROP PUBLIC SYNONYM PKG_SENIOR;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SENIOR FOR BANINST1.PKG_SENIOR;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_SENIOR TO PUBLIC;
