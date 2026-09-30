# foresightr

Previsão de séries temporais em R que escolhe o modelo pelo que teria
dado certo.

O `foresightr` ajusta vários modelos a uma série, refaz o passado para
ver como cada um teria se saído, escolhe pelo erro fora da amostra e dá
faixas tiradas dos erros de fato observados, inclusive para o total dos
próximos k períodos.

Os modelos, o backtest e as ferramentas são o crate Rust
[foresight](https://github.com/milkway/foresight), compilado dentro do
pacote: os números são os do crate e o backtest usa todos os núcleos. O
lado R não depende de nada além do R base.

**Site:** <https://strategicprojects.github.io/foresightr/>

## Instalação

``` r

remotes::install_github("StrategicProjects/foresightr")
```

A instalação pelo código-fonte compila o Rust e precisa dele
(<https://rustup.rs>); no Windows, também do alvo GNU:
`rustup target add x86_64-pc-windows-gnu`.

## Uso

``` r

library(foresightr)
bt <- backtest(AirPassengers)   # 36 origens, 12 meses à frente, 11 modelos
bt$forecast                     # previsão com faixas de 80% e 95%
total_forecast(bt, 6)           # total dos próximos seis meses, com faixa própria
plot(bt)
```

## O que tem

- Modelos: média, ingênuo, tendência, sazonal ingênuo, Theta,
  Holt-Winters, regressão log-linear (com deflator opcional), ARIMA
  sazonal por máxima verossimilhança exata (com regressores), ARIMA
  automático, família ETS com escolha automática, Prophet (quebras de
  tendência, eventos e degraus), TBATS e Croston, SBA e TSB para demanda
  intermitente.
- Decomposição STL e MSTL, e qualquer modelo sobre a série
  dessazonalizada.
- Ensemble: média, mediana, pesos pelo inverso do erro ou pesos
  empilhados.
- Limpeza: preenchimento de falhas e troca de valores atípicos.
- Backtest por origem móvel em todos os núcleos, com MAPE, MAE, RMSE,
  MASE e viés por horizonte e faixas empíricas.

Os números são os do crate Rust, conferido com os pacotes `forecast` e
`prophet` do R; os mesmos métodos existem em Python (`pyforesight`) e Go
(`foresight-go`).

## Autores

André Leite, Marcos Wasiliew, Hugo Vasconcelos, Carlos Amorim e Diogo
Bezerra.

## Licença

MIT.
