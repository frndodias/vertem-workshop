CREATE OR REFRESH MATERIALIZED VIEW dim_cliente
    COMMENT 'Visao corrente dos clientes, derivada do SCD Tipo 2'
AS SELECT
    cliente_id,
    nome,
    cidade,
    segmento,
    __START_AT AS valido_desde
   FROM dim_cliente_scd2
   WHERE __END_AT IS NULL
;