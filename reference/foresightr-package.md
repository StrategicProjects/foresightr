# foresightr: Forecasts Chosen by What Would Have Worked

Time series forecasting that replays the past before trusting a model: a
rolling-origin backtest, Tashman (2000)
[doi:10.1016/S0169-2070(00)00065-0](https://doi.org/10.1016/S0169-2070%2800%2900065-0)
, refits every candidate at each origin, the choice is made by
out-of-sample error, and prediction intervals are quantiles of the
errors actually observed, for each horizon and for totals of the next
periods. Models include seasonal ARIMA by exact maximum likelihood with
automatic orders, Hyndman and Khandakar (2008)
[doi:10.18637/jss.v027.i03](https://doi.org/10.18637/jss.v027.i03) ;
exponential smoothing in state space form, Hyndman, Koehler, Snyder and
Grose (2002)
[doi:10.1016/S0169-2070(01)00110-8](https://doi.org/10.1016/S0169-2070%2801%2900110-8)
; the Theta method, Assimakopoulos and Nikolopoulos (2000)
[doi:10.1016/S0169-2070(00)00066-2](https://doi.org/10.1016/S0169-2070%2800%2900066-2)
; a trend with changepoints and events in the manner of Taylor and
Letham (2018)
[doi:10.1080/00031305.2017.1380080](https://doi.org/10.1080/00031305.2017.1380080)
; TBATS, De Livera, Hyndman and Snyder (2011)
[doi:10.1198/jasa.2011.tm09771](https://doi.org/10.1198/jasa.2011.tm09771)
; seasonal-trend decompositions by LOESS for one or several seasonal
periods, Bandara, Hyndman and Bergmeir (2021)
[doi:10.48550/arXiv.2107.13462](https://doi.org/10.48550/arXiv.2107.13462)
; the method of Croston (1972)
[doi:10.1057/jors.1972.50](https://doi.org/10.1057/jors.1972.50) for
intermittent demand; and ensembles. The computations are done by the
'Rust' crate 'foresight', bundled with the package.

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

Other contributors:

- The authors of the dependency Rust crates (see inst/AUTHORS file for
  details) \[contributor\]
