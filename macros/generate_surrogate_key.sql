{% macro generate_surrogate_key(columns) -%}
  {{ "md5(concat(" ~ columns | join(', ') ~ "))" }}
{%- endmacro %}
