# GAP 265 - Objetos Comuns

Este diretorio deve conter tudo que for compartilhado entre inbound e outbound da Descarga.

## Criterio de inclusao

Colocar aqui apenas o que for reutilizado nos dois fluxos ou o que for base tecnica transversal do GAP.

## Candidatos naturais

- classe de mensagens comum, se o desenho final optar por uma so message class para o GAP
- constantes e tipos compartilhados de layout PCS
- utilitarios de TVARVC e AL11 que nao sejam exclusivos de um fluxo
- estruturas de dominio e tipos auxiliares comuns
- definicoes de log ou helper de resumo de execucao

## Regra de segregacao

- se a logica so existe no outbound, fica em `outbound`
- se a logica so existe no inbound, fica em `inbound`
- se a logica e compartilhada ou transversal, fica aqui

## Repositorio tecnico

Usar a carga como referencia para evitar duplicacao desnecessaria:

- helper de parametrizacao via TVARVC
- padrao de mensagem e severity
- padrao de log e commit
- padrao de leitura/gravação de arquivos em AL11
