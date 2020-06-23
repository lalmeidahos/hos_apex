create or replace PROCEDURE "VINDI_EVENT" (	    
    p_cnpjcpf       IN  varchar2,
    p_event         IN  clob,
    p_webhook_id    IN  number
)
IS
    l_event         varchar2(100);

Begin

	APEX_JSON.parse(p_event);

    -->> Buscar tipo de evento    
    l_event := APEX_JSON.get_varchar2(p_path => 'event.type');
    if l_event = 'bill_created' then       
        VINDI_BILL_CREATED(	
                p_cnpjcpf => p_cnpjcpf,            
                p_event   => p_event,            
                p_webhook_id => p_webhook_id        
            );

    end if;

    if l_event = 'bill_paid' then       
        VINDI_BILL_PAID(	
                p_cnpjcpf => p_cnpjcpf,            
                p_event   => p_event,            
                p_webhook_id => p_webhook_id        
            );

    end if;


    if l_event = 'bill_canceled' then       
        VINDI_BILL_CANCELED(	
                p_cnpjcpf => p_cnpjcpf,            
                p_event   => p_event,            
                p_webhook_id => p_webhook_id        
            );
    
        end if;


End;
