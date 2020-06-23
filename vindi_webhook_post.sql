declare
    l_event         clob;
    l_status        varchar2(100);
    l_data          date;
    l_cnpjcpf       varchar2(20);

    l_cnpj_tenant   varchar2(50);  -- 14 sem formatação
    l_cpf_tenant    varchar2(50);  -- 11 sem formatação

    l_tenant_id     number;

    l_event_type    varchar2(50);
    l_codigo_out    number;
    l_titulo_id     number;
begin

    -->> url para post:
    --  vindi/{cnpjcpf}

    -->> :cnpjcpf, é o parâmetro de entrada na url
    -->> :status, é o retorno numérico. Por exemplo, 200.
    -->> :body, é um parâmetro implícito, que carrega o payload json.

    l_event   := V_BLOBTOCLOB(:body);
    l_data    := sysdate;
    l_status  := 'Pendente';
    l_cnpjcpf := :cnpjcpf;


    APEX_JSON.parse(l_event);

    -->> Buscar tipo de evento
    l_event_type := APEX_JSON.get_varchar2(p_path => 'event.type');


    if l_event_type = 'bill_paid' then

        -->> Forma de contornar a api assíncrona da Vindi.
        -->> Em alguns casos, o pagamento chega antes da criação do título
        dbms_lock.sleep(5);

        -->> Buscar id do tenant
        if length(l_cnpjcpf) > 11 then
            l_cnpj_tenant := formatar_cnpj(l_cnpjcpf);
            l_cpf_tenant  := null;

            select id
            into l_tenant_id
            from tenants
            where cnpj = l_cnpj_tenant;

        else
            l_cnpj_tenant := null;
            l_cpf_tenant  := formatar_cpf(l_cnpjcpf);

            select id
            into l_tenant_id
            from tenants
            where cpf = l_cpf_tenant;

        end if;


        -->> Codigo do titulo na Vindi
        l_codigo_out := APEX_JSON.get_number(p_path => 'event.data.bill.id');


        -->> Buscar titulo no sistema local
        --   Encontrando, devolver http 200, caso contrário, 404
        Begin
            select id
            into l_titulo_id
            from contasreceber
            where codigo_out = l_codigo_out
            and tenantid = l_tenant_id;
        Exception
            when no_data_found then
                l_titulo_id := null;
            when others then
                l_titulo_id := null;
        end;

        if l_titulo_id is not null and l_titulo_id > 0 then

            insert into vindi_webhooks(id, event, data, status, cnpjcpf)
                values (null, l_event, l_data, l_status, l_cnpjcpf);

            :status := 200;
        else
            insert into vindi_wh_log( id, webhook_id, tenant_id, titulo_id, data, type, status, valor)
                values(null, null, l_tenant_id, to_char(l_codigo_out), sysdate, 'Bill_Paid', 'Não Encontrado', 0);

            :status := 404;
        end if;

    else
        insert into vindi_wh_log( id, webhook_id, tenant_id, titulo_id, data, type, status, valor)
            values(null, null, null, null, sysdate, l_event_type, 'Registrado', 0);

        insert into vindi_webhooks(id, event, data, status, cnpjcpf)
            values (null, l_event, l_data, l_status, l_cnpjcpf);

        :status := 200;


    end if;


end;
