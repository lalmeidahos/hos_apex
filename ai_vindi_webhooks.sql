create or replace TRIGGER  "AI_VINDI_WEBHOOKS"
  after insert on "VINDI_WEBHOOKS"
  for each row
begin

    VINDI_EVENT(
        p_cnpjcpf => :NEW.cnpjcpf,
        p_event   => :NEW.event,
        p_webhook_id => :NEW.id
    );


end;
