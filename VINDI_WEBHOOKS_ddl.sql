--------------------------------------------------------
--  DDL for Table VINDI_WEBHOOKS
--------------------------------------------------------

  CREATE TABLE "VINDI_WEBHOOKS" (
    "ID" NUMBER,
    "DATA" TIMESTAMP (6),
    "STATUS" VARCHAR2(100),
    "CNPJCPF" VARCHAR2(20),
    "TENANTID" NUMBER,
    "EVENT" CLOB
) ;
