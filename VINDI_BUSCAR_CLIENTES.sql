create or replace PROCEDURE "VINDI_BUSCAR_CLIENTES" (
	p_api_key	IN	varchar2,
	p_tenant_id	IN	number
)
IS

	l_vindi_customers_record	vindi_customers%rowtype;
	l_total			number;
	l_pages_total	number;
	l_page   		number;
	l_contador		number;

	l_response 		clob;
    l_count 		pls_integer;

    l_header_name 	varchar2(200);
    l_header_value 	varchar2(200);
    l_key_base64    varchar2(200);

    l_page_more     number;

Begin

	-->> Limpar dados anteriores
	delete from vindi_customers
	where tenant_id = p_tenant_id;

    l_key_base64 := UTL_ENCODE.TEXT_ENCODE(p_api_key, NULL, UTL_ENCODE.BASE64);

	-->> primeira chamada para obter cabeçalhos
	apex_web_service.g_request_headers(1).name := 'Content-Type';   
	    apex_web_service.g_request_headers(1).value := 'application/json';  
	    apex_web_service.g_request_headers(2).name := 'Authorization';  
	    apex_web_service.g_request_headers(2).value := 'Basic ' || l_key_base64;  

	l_response := apex_web_service.make_rest_request(
	  p_url => 'http://vindiapi.localhost:3000/api/v1/customers?page=1'
	  , p_http_method => 'GET'
	);

	APEX_JSON.parse(l_response);

	-->> Encontrar cabeçalho com total de registros 
	--   para calcular número de chamadas a API
	for i in 1.. apex_web_service.g_headers.count loop
	  l_Header_Name := apex_web_service.g_headers(i).name;
	  l_Header_Value := apex_web_service.g_headers(i).value;

	  exit when l_Header_Name = 'total';
	end loop;

	l_total := to_number(l_Header_Value);

	l_pages_total := l_total / 25;


    l_page_more := l_pages_total - trunc(l_pages_total);

    if l_page_more > 0 then
       l_pages_total := trunc(l_pages_total) + 1;
    else
       l_pages_total := trunc(l_pages_total);
    end if;


    if l_pages_total <= 1 then
       l_pages_total := 1;
    end if;

	-->> Chamadas reais para parse de dados
	for p in 1 .. l_pages_total LOOP
		l_response := apex_web_service.make_rest_request(
		  p_url => 'http://vindiapi.localhost:3000/api/v1/customers?page=' || to_char(p)
		  , p_http_method => 'GET'
		);

		APEX_JSON.parse(l_response);

		l_count := APEX_JSON.get_count(p_path => 'customers');

        if l_count is null or l_count <= 0 then
           l_count := 1;
        end if;

        -->> dbms_output.put_line('Total: ' || l_pages_total || ' - Página: ' || p);


		for i in 1 .. l_count LOOP

            -->> dbms_output.put_line('Total: ' || l_count || ' - Contagem: ' || i);

			-->> Criação do registro em vindi_customers
            l_vindi_customers_record.NAME                           := APEX_JSON.get_varchar2(p_path => 'customers[%d].name', p0 => i);
            l_vindi_customers_record.EMAIL                          := APEX_JSON.get_varchar2(p_path => 'customers[%d].email', p0 => i);
            l_vindi_customers_record.REGISTRY_CODE                  := APEX_JSON.get_varchar2(p_path => 'customers[%d].registry_code', p0 => i);
            l_vindi_customers_record.CODE                           := APEX_JSON.get_varchar2(p_path => 'customers[%d].code', p0 => i);
            l_vindi_customers_record.NOTES                          := APEX_JSON.get_varchar2(p_path => 'customers[%d].notes', p0 => i);
            l_vindi_customers_record.STATUS                         := APEX_JSON.get_varchar2(p_path => 'customers[%d].status', p0 => i);
            l_vindi_customers_record.CREATED_AT                     := APEX_JSON.get_varchar2(p_path => 'customers[%d].created_at', p0 => i);
            l_vindi_customers_record.UPDATED_AT                     := APEX_JSON.get_varchar2(p_path => 'customers[%d].updated_at', p0 => i);
            l_vindi_customers_record.ADDRESS_STREET                 := APEX_JSON.get_varchar2(p_path => 'customers[%d].address.street', p0 => i);
            l_vindi_customers_record.ADDRESS_NUMBER                 := APEX_JSON.get_varchar2(p_path => 'customers[%d].address.number', p0 => i);
            l_vindi_customers_record.ADDRESS_ADDITIONAL_DETAILS     := APEX_JSON.get_varchar2(p_path => 'customers[%d].address.additional_details', p0 => i);
            l_vindi_customers_record.ADDRESS_ZIPCODE                := APEX_JSON.get_varchar2(p_path => 'customers[%d].address.zipcode', p0 => i);
            l_vindi_customers_record.ADDRESS_NEIGHBORHOOD           := APEX_JSON.get_varchar2(p_path => 'customers[%d].address.neighborhood', p0 => i);
            l_vindi_customers_record.ADDRESS_CITY                   := APEX_JSON.get_varchar2(p_path => 'customers[%d].address.city', p0 => i);
            l_vindi_customers_record.ADDRESS_STATE                  := APEX_JSON.get_varchar2(p_path => 'customers[%d].address.state', p0 => i);
            l_vindi_customers_record.ADDRESS_COUNTRY                := APEX_JSON.get_varchar2(p_path => 'customers[%d].address.country', p0 => i);
            l_vindi_customers_record.CUSTOMER_ID                    := APEX_JSON.get_number(p_path => 'customers[%d].id', p0 => i);
            -- l_vindi_customers_record.PHONE                          := APEX_JSON.get_varchar2(p_path => customers[%d].phones, p0 => i);
            l_vindi_customers_record.TENANT_ID                      := p_tenant_id;

			insert into vindi_customers values l_vindi_customers_record;

		END LOOP;


	END LOOP;

End;
