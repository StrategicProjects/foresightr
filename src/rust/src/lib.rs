//! R bindings of the Rust crate `foresight`.
//!
//! The R side validates and normalises every argument and builds the model
//! specifications (plain lists); this side turns them into the crate's models
//! and returns plain vectors and lists, which the R side shapes into data
//! frames. Nothing here calls back into R while the crate computes, so the
//! backtest can run on all cores.

use std::collections::HashMap;
use std::sync::Arc;

use extendr_api::prelude::*;
use fs::decompose::{Mstl, SeasonalWindow, Stl};
use fs::models as m;

type Result<T> = extendr_api::Result<T>;

fn fail<T>(message: impl Into<String>) -> Result<T> {
    Err(Error::Other(message.into()))
}

// ---------------------------------------------------------------- specs

type Spec = HashMap<String, Robj>;

fn spec_of(robj: &Robj) -> Result<Spec> {
    match robj.as_list() {
        Some(list) => HashMap::try_from(list),
        None => fail("a model specification must be a list"),
    }
}

fn field<'a>(spec: &'a Spec, key: &str) -> Option<&'a Robj> {
    spec.get(key).filter(|r| !r.is_null())
}

fn real(spec: &Spec, key: &str) -> Option<f64> {
    field(spec, key).and_then(|r| r.as_real())
}

fn count(spec: &Spec, key: &str) -> Option<usize> {
    real(spec, key).map(|x| x as usize)
}

fn flag(spec: &Spec, key: &str) -> Option<bool> {
    field(spec, key).and_then(|r| r.as_bool())
}

fn text(spec: &Spec, key: &str) -> Option<String> {
    field(spec, key)
        .and_then(|r| r.as_str())
        .map(str::to_string)
}

fn reals(spec: &Spec, key: &str) -> Option<Vec<f64>> {
    field(spec, key).and_then(|r| r.as_real_vector())
}

fn counts(spec: &Spec, key: &str) -> Option<Vec<usize>> {
    reals(spec, key).map(|v| v.into_iter().map(|x| x as usize).collect())
}

/// A model shared between the R objects and the threads of a backtest.
#[derive(Clone)]
struct Shared(Arc<dyn fs::Model>);

impl fs::Model for Shared {
    fn name(&self) -> String {
        self.0.name()
    }

    fn description(&self) -> String {
        self.0.description()
    }

    fn fit(&self, y: fs::Series<'_>) -> Option<Box<dyn fs::Fitted>> {
        self.0.fit(y)
    }
}

/// Models whose estimate says more than the forecasts.
#[derive(Clone)]
enum Rich {
    Arima(m::Arima),
    ArimaX(m::ArimaX),
    AutoArima(m::AutoArima),
    Ets(m::Ets),
    AutoEts(m::AutoEts),
    Prophet(m::Prophet),
    Tbats(m::Tbats),
}

struct Built {
    model: Shared,
    rich: Option<Rich>,
    name: String,
    description: String,
}

impl Built {
    fn of(model: impl fs::Model + 'static, rich: Option<Rich>) -> Self {
        Built {
            name: model.name(),
            description: model.description(),
            model: Shared(Arc::new(model)),
            rich,
        }
    }

    fn candidate(&self) -> fs::Candidate {
        fs::Candidate::new(self.model.clone()).named(self.name.clone(), self.description.clone())
    }
}

fn regressors(robj: &Robj) -> Result<fs::Regressors> {
    let Some(list) = robj.as_list() else {
        return fail("regressors must be a list of numeric columns");
    };
    let mut r = fs::Regressors::new();
    for (name, column) in list.iter() {
        let Some(values) = column.as_real_vector() else {
            return fail(format!("regressor {name} is not numeric"));
        };
        r = r.with(name, values);
    }
    Ok(r)
}

fn criterion(spec: &Spec) -> Result<m::Criterion> {
    match text(spec, "criterion").as_deref().unwrap_or("aicc") {
        "aicc" => Ok(m::Criterion::Aicc),
        "aic" => Ok(m::Criterion::Aic),
        "bic" => Ok(m::Criterion::Bic),
        other => fail(format!("unknown criterion {other}")),
    }
}

fn build(robj: &Robj) -> Result<Built> {
    let spec = spec_of(robj)?;
    let kind = text(&spec, "kind").unwrap_or_default();
    let mut built = match kind.as_str() {
        "mean" => Built::of(m::Mean, None),
        "naive" => Built::of(m::Naive, None),
        "drift" => Built::of(m::Drift, None),
        "seasonal_naive" => {
            if flag(&spec, "growth").unwrap_or(false) {
                Built::of(m::SeasonalNaive::with_growth(), None)
            } else {
                Built::of(m::SeasonalNaive::new(), None)
            }
        }
        "theta" => Built::of(m::Theta, None),
        "holt_winters" => Built::of(m::HoltWinters, None),
        "log_linear" => {
            let mut l = m::LogLinear::new();
            if let Some(n) = count(&spec, "window") {
                l = l.window(n);
            }
            if let Some(index) = reals(&spec, "deflator") {
                l = l.deflated_by(index);
            }
            Built::of(l, None)
        }
        "arima" => {
            let o = counts(&spec, "order").unwrap_or(vec![0, 1, 1]);
            let s = counts(&spec, "seasonal").unwrap_or(vec![0, 0, 0]);
            let mut a = m::Arima::new(o[0], o[1], o[2]).seasonal(s[0], s[1], s[2]);
            if let Some(c) = flag(&spec, "constant") {
                a = a.constant(c);
            }
            match field(&spec, "regressors") {
                Some(r) => {
                    let x = a.with_regressors(regressors(r)?);
                    Built::of(x.clone(), Some(Rich::ArimaX(x)))
                }
                None => Built::of(a, Some(Rich::Arima(a))),
            }
        }
        "auto_arima" => {
            let mut a = m::AutoArima::new().criterion(criterion(&spec)?);
            a.d = count(&spec, "d");
            a.seasonal_d = count(&spec, "seasonal_d");
            if let Some(o) = counts(&spec, "max_order") {
                a = a.max_orders(o[0], o[1], o[2], o[3]);
            }
            if let Some(r) = field(&spec, "regressors") {
                a = a.regressors(regressors(r)?);
            }
            Built::of(a.clone(), Some(Rich::AutoArima(a)))
        }
        "ets" => {
            let code = text(&spec, "code").unwrap_or_default();
            let Some(e) = m::Ets::from_code(&code) else {
                return fail(format!("{code:?} is not an ETS code"));
            };
            Built::of(e, Some(Rich::Ets(e)))
        }
        "auto_ets" => {
            let e = m::AutoEts::new().criterion(criterion(&spec)?);
            Built::of(e, Some(Rich::AutoEts(e)))
        }
        "prophet" => {
            let mut p = m::Prophet::new();
            if let Some(n) = count(&spec, "changepoints") {
                p = p.changepoints(n);
            }
            if let Some(x) = real(&spec, "changepoint_range") {
                p = p.changepoint_range(x);
            }
            if let Some(x) = real(&spec, "changepoint_prior_scale") {
                p = p.changepoint_prior_scale(x);
            }
            if let Some(x) = real(&spec, "seasonality_prior_scale") {
                p = p.seasonality_prior_scale(x);
            }
            if let Some(k) = count(&spec, "fourier_order") {
                p = p.fourier_order(k);
            }
            if let Some(x) = real(&spec, "event_prior_scale") {
                p = p.event_prior_scale(x);
            }
            // positions arrive 0-based from the R side
            if let Some(events) = field(&spec, "events").and_then(|r| r.as_list()) {
                for (name, positions) in events.iter() {
                    let at: Vec<usize> = positions
                        .as_real_vector()
                        .unwrap_or_default()
                        .into_iter()
                        .map(|x| x as usize)
                        .collect();
                    p = p.event(name, &at);
                }
            }
            if let Some(steps) = field(&spec, "steps").and_then(|r| r.as_list()) {
                for (name, from) in steps.iter() {
                    p = p.step(name, from.as_real().unwrap_or(0.0) as usize);
                }
            }
            Built::of(p.clone(), Some(Rich::Prophet(p)))
        }
        "tbats" => {
            let mut t = m::Tbats::new(&reals(&spec, "periods").unwrap_or_default());
            if let Some(h) = counts(&spec, "harmonics") {
                t = t.harmonics(&h);
            }
            if let Some(b) = flag(&spec, "box_cox") {
                t = t.box_cox(b);
            }
            if let Some(b) = flag(&spec, "trend") {
                t = t.trend(b);
            }
            if let Some(b) = flag(&spec, "damped") {
                t = t.damped(b);
            }
            if let Some(b) = flag(&spec, "arma_errors") {
                t = t.arma_errors(b);
            }
            if let Some(o) = counts(&spec, "arma_orders") {
                t = t.arma_orders(o[0], o[1]);
            }
            Built::of(t.clone(), Some(Rich::Tbats(t)))
        }
        "croston" => {
            let variant = match text(&spec, "variant").as_deref().unwrap_or("croston") {
                "croston" => m::Intermittent::Croston,
                "sba" => m::Intermittent::Sba,
                "tsb" => m::Intermittent::Tsb,
                other => return fail(format!("unknown Croston variant {other}")),
            };
            let mut c = m::Croston::new().variant(variant);
            if let Some(a) = real(&spec, "alpha") {
                c = c.alpha(a);
            }
            if let Some(b) = real(&spec, "beta") {
                c = c.beta(b);
            }
            if flag(&spec, "optimised").unwrap_or(false) {
                c = c.optimised();
            }
            Built::of(c, None)
        }
        "decomposed" => {
            let Some(inner) = field(&spec, "model") else {
                return fail("model_decomposed() needs a model");
            };
            let inner = build(inner)?;
            let mut d =
                m::Decomposed::new(inner.model).robust(flag(&spec, "robust").unwrap_or(false));
            if let Some(p) = counts(&spec, "periods") {
                d = d.periods(&p);
            }
            Built::of(d, None)
        }
        "ensemble" => {
            let Some(members) = field(&spec, "members").and_then(|r| r.as_list()) else {
                return fail("model_ensemble() needs a list of models");
            };
            let mut candidates = Vec::new();
            for member in members.values() {
                candidates.push(build(&member)?.candidate());
            }
            let weighting = match text(&spec, "weighting")
                .as_deref()
                .unwrap_or("inverse_error")
            {
                "inverse_error" => m::Weighting::InverseError,
                "equal" => m::Weighting::Equal,
                "median" => m::Weighting::Median,
                "stacked" => m::Weighting::Stacked,
                other => return fail(format!("unknown weighting {other}")),
            };
            let mut e = m::Ensemble::new(candidates).weighting(weighting);
            if let Some(n) = count(&spec, "origins") {
                e = e.origins(n);
            }
            if let Some(h) = count(&spec, "horizon") {
                e = e.horizon(h);
            }
            if let Some(k) = count(&spec, "top") {
                e = e.top(k);
            }
            Built::of(e, None)
        }
        "transformed" => {
            let Some(inner) = field(&spec, "model") else {
                return fail("model_box_cox() needs a model");
            };
            let inner = build(inner)?.model;
            if text(&spec, "lambda").as_deref() == Some("guerrero") {
                Built::of(fs::Transformed::auto(inner), None)
            } else {
                let lambda = real(&spec, "lambda").unwrap_or(0.0);
                Built::of(fs::Transformed::box_cox(inner, lambda), None)
            }
        }
        other => return fail(format!("unknown model kind {other:?}")),
    };
    if let Some(name) = text(&spec, "name") {
        built.name = name;
    }
    if let Some(description) = text(&spec, "description") {
        built.description = description;
    }
    Ok(built)
}

fn series(values: &[f64], period: f64, phase: f64) -> fs::Series<'_> {
    fs::Series::new(values, period as usize).with_phase(phase as usize)
}

/// Name and description of a model specification.
/// @noRd
#[extendr]
fn rs_model_label(spec: Robj) -> Result<Vec<String>> {
    let b = build(&spec)?;
    Ok(vec![b.name, b.description])
}

// ---------------------------------------------------------------- fits

enum Estimate {
    Plain(Box<dyn fs::Fitted>),
    Arima(m::ArimaFit),
    Ets(m::EtsFit),
    Prophet(m::ProphetFit),
    Tbats(m::TbatsFit),
}

impl Estimate {
    fn fitted(&self) -> &dyn fs::Fitted {
        match self {
            Estimate::Plain(f) => f.as_ref(),
            Estimate::Arima(f) => f,
            Estimate::Ets(f) => f,
            Estimate::Prophet(f) => f,
            Estimate::Tbats(f) => f,
        }
    }
}

struct FitBox(Estimate);

fn names_values(params: &[(String, f64)]) -> List {
    list!(
        names = params.iter().map(|p| p.0.clone()).collect::<Vec<_>>(),
        values = params.iter().map(|p| p.1).collect::<Vec<_>>()
    )
}

fn opt(x: Option<f64>) -> f64 {
    x.unwrap_or(f64::NAN)
}

/// Fits a model; returns what was estimated and a pointer for forecasting.
/// @noRd
#[extendr]
fn rs_fit(spec: Robj, values: Vec<f64>, period: f64, phase: f64) -> Result<List> {
    let b = build(&spec)?;
    let y = series(&values, period, phase);
    let estimate = match &b.rich {
        Some(Rich::Arima(a)) => a.estimate(y).map(Estimate::Arima),
        Some(Rich::ArimaX(a)) => a.estimate(y).map(Estimate::Arima),
        Some(Rich::AutoArima(a)) => a.select(y).map(Estimate::Arima),
        Some(Rich::Ets(e)) => e.estimate(y).map(Estimate::Ets),
        Some(Rich::AutoEts(e)) => e.select(y).map(Estimate::Ets),
        Some(Rich::Prophet(p)) => p.estimate(y).map(Estimate::Prophet),
        Some(Rich::Tbats(t)) => t.select(y).map(Estimate::Tbats),
        None => fs::Model::fit(&b.model, y).map(Estimate::Plain),
    };
    let Some(estimate) = estimate else {
        return fail(format!(
            "{}: the series is too short, not finite, or otherwise unsuitable for the model",
            b.name
        ));
    };
    let params = estimate.fitted().params();
    let empty: Vec<f64> = Vec::new();
    let (loglik, aic, aicc, bic, residuals, details) = match &estimate {
        Estimate::Plain(_) => (f64::NAN, f64::NAN, f64::NAN, f64::NAN, empty, List::new(0)),
        Estimate::Arima(f) => {
            let (p, d, q) = f.order();
            let (sp, sd, sq) = f.seasonal_order();
            (
                f.log_likelihood,
                f.aic,
                f.aicc,
                f.bic,
                f.residuals.clone(),
                list!(
                    order = vec![p as f64, d as f64, q as f64],
                    seasonal_order = vec![sp as f64, sd as f64, sq as f64],
                    period = f.period() as f64,
                    ar = f.ar.clone(),
                    ma = f.ma.clone(),
                    seasonal_ar = f.seasonal_ar.clone(),
                    seasonal_ma = f.seasonal_ma.clone(),
                    constant = opt(f.constant),
                    regression = names_values(&f.regression),
                    sigma2 = f.sigma2
                ),
            )
        }
        Estimate::Ets(f) => (
            f.log_likelihood,
            f.aic,
            f.aicc,
            f.bic,
            f.residuals.clone(),
            list!(
                code = f.model().code(),
                alpha = f.alpha,
                beta = opt(f.beta),
                gamma = opt(f.gamma),
                phi = opt(f.phi),
                sigma2 = f.sigma2,
                fitted = f.fitted.clone(),
                initial_seasonal = f.initial_seasonal().to_vec()
            ),
        ),
        Estimate::Prophet(f) => {
            let bends = f.changepoints();
            (
                f64::NAN,
                f64::NAN,
                f64::NAN,
                f64::NAN,
                empty,
                list!(
                    changepoints = bends.iter().map(|b| b.0 as f64 + 1.0).collect::<Vec<_>>(),
                    rate_changes = bends.iter().map(|b| b.1).collect::<Vec<_>>(),
                    effects = names_values(&f.effects()),
                    sigma = f.sigma(),
                    fitted = f.fitted()
                ),
            )
        }
        Estimate::Tbats(f) => {
            let seasonal = f.seasonal();
            let (p, q) = f.arma();
            let (alpha, beta) = f.smoothing();
            (
                f.likelihood(),
                f.aic(),
                f64::NAN,
                f64::NAN,
                f.residuals().to_vec(),
                list!(
                    periods = seasonal.iter().map(|s| s.0).collect::<Vec<_>>(),
                    harmonics = seasonal.iter().map(|s| s.1 as f64).collect::<Vec<_>>(),
                    lambda = opt(f.lambda()),
                    trend = f.trend().is_some(),
                    damping = opt(f.trend()),
                    arma = vec![p as f64, q as f64],
                    smoothing = vec![alpha, beta]
                ),
            )
        }
    };
    Ok(list!(
        model = b.name,
        description = b.description,
        params = names_values(&params),
        log_likelihood = loglik,
        aic = aic,
        aicc = aicc,
        bic = bic,
        residuals = residuals,
        details = details,
        pointer = ExternalPtr::new(FitBox(estimate))
    ))
}

/// Forecasts from a fit.
/// @noRd
#[extendr]
fn rs_predict(pointer: Robj, h: f64) -> Result<Vec<f64>> {
    let fit: &ExternalPtr<FitBox> = (&pointer)
        .try_into()
        .map_err(|_| Error::Other("the fit is no longer in memory: fit the model again".into()))?;
    Ok(fit.0.fitted().forecast(h as usize))
}

/// Fits and forecasts in one go.
/// @noRd
#[extendr]
fn rs_forecast(spec: Robj, values: Vec<f64>, period: f64, phase: f64, h: f64) -> Result<Vec<f64>> {
    let b = build(&spec)?;
    fs::Model::forecast(&b.model, series(&values, period, phase), h as usize).ok_or_else(|| {
        Error::Other(format!(
            "{}: the series is too short, not finite, or otherwise unsuitable for the model",
            b.name
        ))
    })
}

// ---------------------------------------------------------------- backtest

/// Row-major `[horizon][level]`.
fn flat_bands(rows: &[fs::HorizonStats], cumulative: bool, lower: bool) -> Vec<f64> {
    rows.iter()
        .flat_map(|r| if cumulative { &r.cumulative } else { &r.bands })
        .map(|b| if lower { b.lower } else { b.upper })
        .collect()
}

/// Row-major `[point][level]`.
fn flat_points(points: &[fs::Point], lower: bool) -> Vec<f64> {
    points
        .iter()
        .flat_map(|p| &p.intervals)
        .map(|i| if lower { i.lower } else { i.upper })
        .collect()
}

fn candidate_list(c: &fs::CandidateReport) -> List {
    let h = &c.horizons;
    let cumulative: Vec<fs::Point> = (1..=c.forecast.len())
        .filter_map(|k| c.cumulative(k))
        .collect();
    list!(
        name = c.name.clone(),
        description = c.description.clone(),
        components = c.components.clone(),
        score = c.score,
        params = names_values(&c.params),
        n = h.iter().map(|x| x.n as f64).collect::<Vec<_>>(),
        mape = h.iter().map(|x| opt(x.mape)).collect::<Vec<_>>(),
        bias = h.iter().map(|x| opt(x.bias)).collect::<Vec<_>>(),
        mae = h.iter().map(|x| opt(x.mae)).collect::<Vec<_>>(),
        rmse = h.iter().map(|x| opt(x.rmse)).collect::<Vec<_>>(),
        mase = h.iter().map(|x| opt(x.mase)).collect::<Vec<_>>(),
        band_lower = flat_bands(h, false, true),
        band_upper = flat_bands(h, false, false),
        cumulative_band_lower = flat_bands(h, true, true),
        cumulative_band_upper = flat_bands(h, true, false),
        trajectories = c.trajectories.iter().flatten().copied().collect::<Vec<_>>(),
        mean = c.forecast.iter().map(|p| p.mean).collect::<Vec<_>>(),
        lower = flat_points(&c.forecast, true),
        upper = flat_points(&c.forecast, false),
        cumulative_mean = cumulative.iter().map(|p| p.mean).collect::<Vec<_>>(),
        cumulative_lower = flat_points(&cumulative, true),
        cumulative_upper = flat_points(&cumulative, false)
    )
}

/// Runs a backtest.
/// @noRd
#[extendr]
#[allow(clippy::too_many_arguments)]
fn rs_backtest(
    values: Vec<f64>,
    period: f64,
    phase: f64,
    candidates: List,
    origins: f64,
    horizon: f64,
    min_train: f64,
    window: f64,
    combine: f64,
    levels: Vec<f64>,
    metric: &str,
    parallel: bool,
) -> Result<List> {
    let metric = match metric {
        "mape" => fs::Metric::Mape,
        "mae" => fs::Metric::Mae,
        "rmse" => fs::Metric::Rmse,
        "mase" => fs::Metric::Mase,
        other => return fail(format!("unknown metric {other}")),
    };
    let mut models = Vec::new();
    for spec in candidates.values() {
        models.push(build(&spec)?.candidate());
    }
    let config = fs::Backtest {
        origins: origins as usize,
        horizon: horizon as usize,
        min_train: min_train as usize,
        window: (!window.is_nan()).then_some(window as usize),
        combine: combine as usize,
        levels: levels.clone(),
        metric,
        parallel,
    };
    let Some(report) = config.run(series(&values, period, phase), &models) else {
        return fail("the series is too short for the backtest (see min_train) or not finite");
    };
    let all: Vec<Robj> = report
        .candidates
        .iter()
        .map(|c| candidate_list(c).into())
        .collect();
    Ok(list!(
        candidates = List::from_values(all),
        chosen = report.chosen as f64 + 1.0,
        origins = report.origins as f64,
        first_origin = report.first_origin as f64 + 1.0,
        horizon = report.horizon as f64,
        levels = levels
    ))
}

// ---------------------------------------------------------------- decomposition

fn decomposition(d: fs::decompose::Decomposition) -> List {
    let strengths: Vec<f64> = (0..d.seasonal.len())
        .map(|i| opt(d.seasonal_strength(i)))
        .collect();
    let seasonal: Vec<Robj> = d.seasonal.iter().map(|s| s.clone().into()).collect();
    list!(
        periods = d.periods.iter().map(|p| *p as f64).collect::<Vec<_>>(),
        trend = d.trend.clone(),
        seasonal = List::from_values(seasonal),
        remainder = d.remainder.clone(),
        trend_strength = d.trend_strength(),
        seasonal_strength = strengths
    )
}

/// STL.
/// @noRd
#[extendr]
#[allow(clippy::too_many_arguments)]
fn rs_stl(
    values: Vec<f64>,
    period: f64,
    seasonal_window: f64,
    trend_window: f64,
    low_pass_window: f64,
    degrees: Vec<f64>,
    robust: bool,
    inner: f64,
    outer: f64,
) -> Result<List> {
    let window = if seasonal_window.is_nan() {
        SeasonalWindow::Periodic
    } else {
        SeasonalWindow::Span(seasonal_window as usize)
    };
    let mut s = Stl::new(period as usize, window).robust(robust);
    if !trend_window.is_nan() {
        s = s.trend_window(trend_window as usize);
    }
    if !low_pass_window.is_nan() {
        s = s.low_pass_window(low_pass_window as usize);
    }
    if degrees.len() == 3 {
        s = s.degrees(
            degrees[0] as usize,
            degrees[1] as usize,
            degrees[2] as usize,
        );
    }
    if !inner.is_nan() || !outer.is_nan() {
        let (i, o) = if robust { (1.0, 15.0) } else { (2.0, 0.0) };
        let pick = |x: f64, d: f64| if x.is_nan() { d } else { x } as usize;
        s = s.iterations(pick(inner, i), pick(outer, o));
    }
    match s.decompose(&values) {
        Some(d) => Ok(decomposition(d)),
        None => fail("STL needs two full cycles of finite values and a valid window"),
    }
}

/// MSTL.
/// @noRd
#[extendr]
fn rs_mstl(
    values: Vec<f64>,
    periods: Vec<f64>,
    windows: Vec<f64>,
    iterations: f64,
    robust: bool,
) -> Result<List> {
    let periods: Vec<usize> = periods.into_iter().map(|p| p as usize).collect();
    let mut s = Mstl::new(&periods).robust(robust);
    if !windows.is_empty() {
        let w: Vec<usize> = windows.into_iter().map(|p| p as usize).collect();
        s = s.seasonal_windows(&w);
    }
    if !iterations.is_nan() {
        s = s.iterations(iterations as usize);
    }
    match s.decompose(&values) {
        Some(d) => Ok(decomposition(d)),
        None => fail("MSTL needs a period that fits twice in the series"),
    }
}

// ---------------------------------------------------------------- cleaning

/// Fills gaps.
/// @noRd
#[extendr]
fn rs_interpolate(values: Vec<f64>, period: f64) -> Result<Vec<f64>> {
    fs::clean::interpolate(&values, period as usize)
        .ok_or_else(|| Error::Other("nothing to interpolate from".into()))
}

/// Finds outliers (1-based positions).
/// @noRd
#[extendr]
fn rs_outliers(values: Vec<f64>, period: f64) -> Result<List> {
    let found = fs::clean::outliers(&values, period as usize)
        .ok_or_else(|| Error::Other("the series is too short".into()))?;
    Ok(list!(
        index = found
            .iter()
            .map(|o| o.index as f64 + 1.0)
            .collect::<Vec<_>>(),
        value = found.iter().map(|o| o.value).collect::<Vec<_>>(),
        replacement = found.iter().map(|o| o.replacement).collect::<Vec<_>>()
    ))
}

/// Fills gaps and replaces outliers.
/// @noRd
#[extendr]
fn rs_clean(values: Vec<f64>, period: f64) -> Result<Vec<f64>> {
    fs::clean::clean(&values, period as usize)
        .ok_or_else(|| Error::Other("the series is too short".into()))
}

// ---------------------------------------------------------------- diagnostics

/// @noRd
#[extendr]
fn rs_acf(values: Vec<f64>, max_lag: f64) -> Vec<f64> {
    fs::diagnostics::acf(&values, max_lag as usize)
}

/// @noRd
#[extendr]
fn rs_kpss(values: Vec<f64>) -> f64 {
    opt(fs::diagnostics::kpss(&values))
}

/// @noRd
#[extendr]
fn rs_ndiffs(values: Vec<f64>, max: f64) -> f64 {
    fs::diagnostics::ndiffs(&values, max as usize) as f64
}

/// @noRd
#[extendr]
fn rs_nsdiffs(values: Vec<f64>, period: f64) -> f64 {
    fs::diagnostics::nsdiffs(&values, period as usize) as f64
}

/// @noRd
#[extendr]
fn rs_seasonal_strength(values: Vec<f64>, period: f64) -> f64 {
    opt(fs::diagnostics::seasonal_strength(&values, period as usize))
}

/// @noRd
#[extendr]
fn rs_box_cox(values: Vec<f64>, lambda: f64, inverse: bool) -> Vec<f64> {
    let t = fs::BoxCox::new(lambda);
    values
        .into_iter()
        .map(|v| if inverse { t.invert(v) } else { t.apply(v) })
        .collect()
}

/// @noRd
#[extendr]
fn rs_guerrero(values: Vec<f64>, period: f64, phase: f64) -> f64 {
    opt(fs::BoxCox::guerrero(series(&values, period, phase)).map(|b| b.lambda()))
}

/// @noRd
#[extendr]
fn rs_accuracy(actual: Vec<f64>, forecast: Vec<f64>, measure: &str) -> Result<f64> {
    Ok(opt(match measure {
        "mape" => fs::accuracy::mape(&actual, &forecast),
        "bias" => fs::accuracy::bias(&actual, &forecast),
        "mae" => fs::accuracy::mae(&actual, &forecast),
        "rmse" => fs::accuracy::rmse(&actual, &forecast),
        other => return fail(format!("unknown measure {other}")),
    }))
}

/// @noRd
#[extendr]
fn rs_mase(actual: Vec<f64>, forecast: Vec<f64>, train: Vec<f64>, period: f64) -> f64 {
    opt(fs::accuracy::mase_scale(&train, period as usize)
        .and_then(|scale| fs::accuracy::mase(&actual, &forecast, scale)))
}

// ---------------------------------------------------------------- regressors

fn columns(r: fs::Regressors) -> List {
    let values: Vec<Robj> = r.columns().iter().map(|c| c.clone().into()).collect();
    List::from_names_and_values(r.names().to_vec(), values).unwrap_or_else(|_| List::new(0))
}

/// @noRd
#[extendr]
fn rs_fourier(period: f64, order: f64, rows: f64) -> List {
    columns(fs::Regressors::fourier(
        period,
        order as usize,
        rows as usize,
    ))
}

/// @noRd
#[extendr]
fn rs_seasonal_dummies(period: f64, rows: f64) -> List {
    columns(fs::Regressors::seasonal_dummies(
        period as usize,
        rows as usize,
    ))
}

extendr_module! {
    mod foresightr;
    fn rs_model_label;
    fn rs_fit;
    fn rs_predict;
    fn rs_forecast;
    fn rs_backtest;
    fn rs_stl;
    fn rs_mstl;
    fn rs_interpolate;
    fn rs_outliers;
    fn rs_clean;
    fn rs_acf;
    fn rs_kpss;
    fn rs_ndiffs;
    fn rs_nsdiffs;
    fn rs_seasonal_strength;
    fn rs_box_cox;
    fn rs_guerrero;
    fn rs_accuracy;
    fn rs_mase;
    fn rs_fourier;
    fn rs_seasonal_dummies;
}
