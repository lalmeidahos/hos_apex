create or replace PROCEDURE "VINDI_BILL_CREATED" (	    
    p_cnpjcpf       IN  varchar2,
    p_event         IN  clob,
    p_webhook_id    IN  number
)
IS

    l_clientes_record       clientes%rowtype;
    l_titulos_record        contasreceber%rowtype;
    l_notificacoes_record   notificacoes%rowtype;

    l_valor                 varchar2(50);

    l_cliente_id            number;

    l_centro_custos_id      number;
    l_plan_id               number;

    l_categoria_id          number;
    l_product_id            number;

    l_status_titulo_id      number;


    l_cnpj_tenant           varchar2(50);  -- 14 sem formatação
    l_cpf_tenant            varchar2(50);  -- 11 sem formatação
    l_tenant_id             number;
    l_tenant_api_key        varchar2(100);

	l_total			        number;
	l_pages_total	        number;
	l_page   		        number;
	l_contador		        number;

    l_count 		        pls_integer;

    l_customer_id           number;
    l_myData                varchar2(50);
    l_myVencimento          varchar2(50);
    l_documento             number;

Begin

    -->> Buscar id do tenant    
    if length(p_cnpjcpf) > 11 then        
        l_cnpj_tenant := formatar_cnpj(p_cnpjcpf);
        l_cpf_tenant  := null;

        select id
        into l_tenant_id
        from tenants
        where cnpj = l_cnpj_tenant;

    else
        l_cnpj_tenant := null;
        l_cpf_tenant  := formatar_cpf(p_cnpjcpf);

        select id
        into l_tenant_id
        from tenants
        where cpf = l_cpf_tenant;

    end if;


    -->> Buscar API Key do cliente    
    select api_key
    into l_tenant_api_key
    from tenants_prefs
    where tenant_id = l_tenant_id
    and tipo = 'API Vindi';

    -->> Atualizar Planos    
    vindi_buscar_planos(
        p_api_key => l_tenant_api_key,        
        p_tenant_id	=> l_tenant_id    
    );

    -->> Atualizar Produtos    
    vindi_buscar_produtos(
        p_api_key => l_tenant_api_key,        
        p_tenant_id	=> l_tenant_id    
    );

	APEX_JSON.parse(p_event);

	-->> Buscar id do cliente na Vindi    
    l_customer_id  := APEX_JSON.get_number(p_path => 'event.data.bill.customer.id');
    
    -->> Buscar id do plano na Vindi    
    l_plan_id := APEX_JSON.get_number(p_path => 'event.data.bill.subscription.plan.id');
    
    -->> Buscar id do produto na Vindi    
    l_product_id := APEX_JSON.get_number(p_path => 'event.data.bill.bill_items[1].product.id');

    -->> Data de emissão    
    l_myData := APEX_JSON.get_varchar2(p_path => 'event.created_at');    
    l_mydata := substr(l_myData, 1, 10);

    -->> Data de vencimento    
    l_myVencimento := APEX_JSON.get_varchar2(p_path => 'event.data.bill.charges[1].due_at');    
    l_myVencimento := substr(l_myVencimento, 1, 10);

    -->> Valor do titulo    
    l_valor := APEX_JSON.get_varchar2(p_path => 'event.data.bill.amount');    
    --l_valor := replace(l_valor, '.', ',');
    
    -->> Documento    
    l_documento := APEX_JSON.get_number(p_path => 'event.data.bill.id');    

    -->> Busca o id do cliente no sistema local. Se não existir, cria um novo cadastro.    
    l_cliente_id := vindi_get_customer(
            p_api_key       => l_tenant_api_key,            
            p_customer_id   => l_customer_id,            
            p_tenant_id     => l_tenant_id        
        );


    -->> Buscar centro de custos correspondente ao plano Vindi    
    -- select id
    -- into l_centro_custos_id
    -- from centrosresultados
    -- where vindi_plan_id = l_plan_id
    -- and tenantid = l_tenant_id;
    Begin
        Select centrocustosid
        into l_centro_custos_id
        from centros_vindi_plans
        where vindi_plan_id = l_plan_id
        and tenantid = l_tenant_id;
    Exception
        when no_data_found then
            l_centro_custos_id := null;
        when others then
            l_centro_custos_id := null;
        end;


    -->> Buscar centro de custos correspondente ao produto Vindi    
    --   Realiza a busca apenas se for uma venda avulsa...
    if l_centro_custos_id is null then
        Begin
            Select centroid
            into l_centro_custos_id
            from centros_vindi_products
            where vindi_product_id = l_product_id
            and tenantid = l_tenant_id;
        Exception
            when no_data_found then
                l_centro_custos_id := null;
            when others then
                l_centro_custos_id := null;
            end;
    end if;


    -->> Buscar categoria correspondente ao produto Vindi        
    Begin
        select categoriaid
        into l_categoria_id
        from categ_vindi_products
        where vindi_product_id = l_product_id
        and tenantid = l_tenant_id;
    Exception
        when no_data_found then
            l_categoria_id := null;
        when others then
            l_categoria_id := null;
        end;

    -->> Buscar status do novo titulo    
    select id
    into l_status_titulo_id
    from statustitulos
    where nome = 'Pendente';

    if l_centro_custos_id is not null 
        and l_categoria_id is not null then

        -->> Criar novo registro        
        l_titulos_record.id                 := null;
        l_titulos_record.clienteid          := l_cliente_id;
        l_titulos_record.centrocustosid     := l_centro_custos_id;
        l_titulos_record.categoriacustosid  := l_categoria_id;
        l_titulos_record.documento          := to_char(l_documento);
        l_titulos_record.dataemissao        := to_date(l_myData, 'YYYY-MM-DD');        
        l_titulos_record.datavencimento     := to_date(l_myVencimento, 'YYYY-MM-DD');        
        l_titulos_record.recorrente         := 'Não';        
        l_titulos_record.parcelado          := 'Não';        
        l_titulos_record.valortotal         := to_number(l_valor);
        l_titulos_record.valor              := to_number(l_valor);
        l_titulos_record.saldo              := to_number(l_valor);
        l_titulos_record.statusid           := l_status_titulo_id;
        l_titulos_record.tenantid           := l_tenant_id;
        l_titulos_record.codigo_out         := l_documento;
        l_titulos_record.observacoes        := '';
        insert into contasreceber values l_titulos_record;

        -->> Criar log do webhook        
        insert into vindi_wh_log (id, webhook_id, tenant_id, titulo_id, data, type, status, valor)
        values (null, p_webhook_id, l_tenant_id, to_char(l_documento), sysdate, 'Bill_Created', 'Processado', to_number(l_valor));
        
        -->> Criar notificação         
        l_notificacoes_record.data   := sysdate;
        l_notificacoes_record.tipo   := 'Vindi';        
        l_notificacoes_record.status := 'Nova';        
        l_notificacoes_record.tenantid := l_tenant_id;

        l_notificacoes_record.titulo := 'Novo Título';        
        l_notificacoes_record.texto  := 'Novo título criado na Vindi.';
        
        insert into notificacoes values l_notificacoes_record;

    else

        insert into vindi_log values(null, sysdate, 'Nova Fatura', 'Erro tentando criar fatura.', l_tenant_api_key, l_tenant_id);

        -->> Criar notificação         
        l_notificacoes_record.data   := sysdate;
        l_notificacoes_record.tipo   := 'Vindi';        
        l_notificacoes_record.status := 'Nova';        
        l_notificacoes_record.tenantid := l_tenant_id;

        l_notificacoes_record.titulo := 'Erro';        
        l_notificacoes_record.texto  := 'Erro criando fatura Vindi. Verifique a configuração de Centros de Resultados e Categorias';
        
        insert into notificacoes values l_notificacoes_record;

    end if;

End;
