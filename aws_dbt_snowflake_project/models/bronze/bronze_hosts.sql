{{
  config(
    materialized = 'incremental',
    )
}}

SELECT * FROM {{source('staging','hosts')}}
{% if is_incremental() %}
WHERE CREATED_AT > (select COALESCE(max(CREATED_AT),'1900-01-01') from {{this}})
{% endif %} 
