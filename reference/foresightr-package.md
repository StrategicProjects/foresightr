# foresightr: Forecasts Chosen by What Would Have Worked

Time series forecasting that replays the past before trusting a model: a
rolling-origin backtest refits every candidate at each origin, the
choice is made by out-of-sample error, and prediction intervals are
quantiles of the errors actually observed, for each horizon and for
totals of the next periods. Models include seasonal 'ARIMA' by exact
maximum likelihood with automatic orders, exponential smoothing in state
space form, a 'Prophet'-style trend with changepoints and events,
'TBATS', 'STL' and 'MSTL' decompositions, Croston's method and
ensembles. The computations are done by the 'Rust' crate 'foresight'.

## See also

Useful links:

- <https://github.com/StrategicProjects/foresightr>

- <https://strategicprojects.github.io/foresightr/>

- Report bugs at
  <https://github.com/StrategicProjects/foresightr/issues>

## Author

**Maintainer**: André Leite <leite@castlab.org>
([ORCID](https://orcid.org/0000-0002-4718-9766))

Authors:

- André Leite <leite@castlab.org>
  ([ORCID](https://orcid.org/0000-0002-4718-9766))

- Marcos Wasiliew <marcos.wasiliew@gmail.com>
  ([ORCID](https://orcid.org/0009-0004-4694-3159))

- Hugo Vasconcelos <hugo.vasconcelos@ufpe.br>
  ([ORCID](https://orcid.org/0000-0001-6249-0920))

- Carlos Amorim <carlos.agaf@ufpe.br>
  ([ORCID](https://orcid.org/0000-0001-6315-8305))

- Diogo Bezerra <diogo.bezerra@ufpe.br>
  ([ORCID](https://orcid.org/0000-0002-1216-8674))
