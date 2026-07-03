# Gap 265 - Estrutura de Implementacao

Este diretorio consolida a nova implementacao de Descarga do GAP 265 usando a carga ja entregue como referencia tecnica.

## Referencias principais

- [EF_GAP_265_DESCARGA.md](../EF_GAP_265_DESCARGA.md)
- [ESTRUTURA_GAP_265.md](ESTRUTURA_GAP_265.md)
- Pacote base da carga: `ZPQ2C_265_20260703_082358`

## Organizacao

- [inbound](inbound/)
- [outbound](outbound/)
- [objetos_comuns](objetos_comuns/)

## Regra de uso

- `outbound` recebe tudo que gera arquivo SAP -> PCS, inclusive cancelamento U201.
- `inbound` recebe tudo que le arquivo PCS -> SAP e persiste retorno.
- `objetos_comuns` recebe o que for compartilhado entre os dois fluxos, sem duplicar logica.

## Diretriz tecnica

O desenvolvimento deve seguir o mesmo caminho tecnico da carga:

- classe core por fluxo
- runner manual para teste
- job/APJ para execucao batch
- TVARVC para caminhos e parametros
- AL11 para arquivos
- classe de mensagens dedicada
- persistencia e log com commit transacional
