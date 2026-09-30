# Charts, drawn with ggplot2.

ink <- "#1f2430"
muted <- "#5d6478"
faint <- "#e7e9f0"
brand <- "#5b43d6"
# categorical slots, validated for the light surface (colour-blind safe in
# this order); the lighter two need the direct labels the charts carry
series_colours <- c("#2a78d6", "#eb6834", "#1baf7a", "#eda100")

#' The theme of the package's charts
#'
#' A quiet theme on top of [ggplot2::theme_minimal()]: horizontal grid lines
#' only, muted axes, the title aligned with the plot.
#'
#' @param base_size Base font size.
#' @param base_family Base font family.
#' @return A ggplot2 theme.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(data.frame(x = 1:10, y = cumsum(rnorm(10))), aes(x, y)) +
#'   geom_line() +
#'   theme_foresight()
theme_foresight <- function(base_size = 11, base_family = "") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", colour = ink, size = ggplot2::rel(1.2),
                                         margin = ggplot2::margin(b = 4)),
      plot.subtitle = ggplot2::element_text(colour = muted, margin = ggplot2::margin(b = 12)),
      plot.caption = ggplot2::element_text(colour = muted, size = ggplot2::rel(0.8), hjust = 0,
                                           margin = ggplot2::margin(t = 10)),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.margin = ggplot2::margin(14, 18, 10, 14),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = faint, linewidth = 0.4),
      axis.text = ggplot2::element_text(colour = muted),
      axis.title = ggplot2::element_text(colour = muted, size = ggplot2::rel(0.9)),
      axis.ticks.x = ggplot2::element_line(colour = faint),
      legend.position = "top",
      legend.justification = "left",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour = ink),
      strip.text = ggplot2::element_text(face = "bold", colour = ink, hjust = 0)
    )
}

# Times of a `ts` as dates for monthly and quarterly data, numbers otherwise.
as_time <- function(t, frequency) {
  if (!frequency %in% c(4, 12)) return(t)
  year <- floor(t + 1e-9)
  month <- round((t - year) * 12) + 1
  as.Date(sprintf("%04d-%02d-01", as.integer(year), as.integer(month)))
}

thousands <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)

#' Charts of a backtest or a decomposition
#'
#' `autoplot()` draws, with ggplot2:
#'
#' * `type = "forecast"`: the last observations and the forecast of a
#'   candidate with its empirical intervals;
#' * `type = "accuracy"`: the error of the best candidates by horizon;
#' * `type = "ranking"`: every candidate by its score, the chosen one
#'   highlighted;
#'
#' and, for a decomposition, the series, the trend, each seasonal pattern and
#' the remainder. `plot()` draws the same chart. Both return a ggplot object,
#' which can be themed and annotated further.
#'
#' @param object,x A result of [backtest()] or of [decompose_stl()] /
#'   [decompose_mstl()].
#' @param type What to draw.
#' @param candidate A candidate name, for `type = "forecast"`; by default
#'   the chosen one.
#' @param history How many of the last observations to show.
#' @param top How many of the best candidates, for `type = "accuracy"`.
#' @param ... Not used.
#' @return A ggplot object.
#' @examples
#' \donttest{
#' bt <- backtest(AirPassengers, origins = 24)
#' autoplot(bt)
#' autoplot(bt, "accuracy")
#' autoplot(decompose_stl(log(AirPassengers), seasonal_window = 13))
#' }
#' @name autoplot.foresight_backtest
#' @importFrom ggplot2 autoplot .data
#' @export
autoplot.foresight_backtest <- function(object, type = c("forecast", "accuracy", "ranking"),
                                        candidate = object$best, history = 48, top = 4, ...) {
  switch(match.arg(type),
         forecast = forecast_chart(object, candidate, history),
         accuracy = accuracy_chart(object, top),
         ranking = ranking_chart(object))
}

#' @rdname autoplot.foresight_backtest
#' @export
plot.foresight_backtest <- function(x, type = c("forecast", "accuracy", "ranking"),
                                    candidate = x$best, history = 48, top = 4, ...) {
  p <- autoplot.foresight_backtest(x, type = type, candidate = candidate, history = history,
                                   top = top)
  print(p)
  invisible(p)
}

forecast_chart <- function(bt, candidate, history) {
  report <- bt$candidates[[candidate]]
  if (is.null(report)) abort("no candidate named ", candidate, ".")
  y <- bt$series$values
  n <- length(y)
  tsp <- bt$series$tsp
  frequency <- if (is.null(tsp)) 1 else tsp[3]
  at <- if (is.null(tsp)) seq_len(n) else tsp[1] + (seq_len(n) - 1) / frequency
  ahead <- if (is.null(tsp)) n + report$forecast$horizon else report$forecast$time
  shown <- max(1, n - history + 1):n
  past <- data.frame(time = as_time(at[shown], frequency), value = y[shown])
  # the forecast starts from the last observation, so the line is continuous
  future <- data.frame(time = as_time(c(at[n], ahead), frequency),
                       mean = c(y[n], report$forecast$mean))
  levels <- sort(bt$levels, decreasing = TRUE)
  bands <- do.call(rbind, lapply(levels, function(l) {
    data.frame(time = future$time, level = l,
               lower = c(y[n], report$forecast[[paste0("lower_", level_names(l))]]),
               upper = c(y[n], report$forecast[[paste0("upper_", level_names(l))]]))
  }))
  alphas <- stats::setNames(seq(0.14, 0.34, length.out = length(levels)), levels)
  last <- future[nrow(future), ]
  # each band labelled at its upper edge, kept apart from the next
  edge <- vapply(levels, function(l) max(bands$upper[bands$level == l & bands$time == last$time]), 0)
  gap <- 0.06 * diff(range(c(past$value, bands$lower, bands$upper)))
  for (i in seq_along(edge)[-1]) edge[i] <- min(edge[i], edge[i - 1] - gap)
  labels <- data.frame(time = last$time, level = levels, y = edge,
                       text = paste0(level_names(levels), "%"))
  score <- bt$ranking$score[bt$ranking$name == candidate]
  ggplot2::ggplot() +
    ggplot2::geom_ribbon(data = bands,
                         ggplot2::aes(x = .data$time, ymin = .data$lower, ymax = .data$upper,
                                      group = .data$level, alpha = factor(.data$level)),
                         fill = brand) +
    ggplot2::scale_alpha_manual(values = alphas, guide = "none") +
    ggplot2::geom_vline(xintercept = past$time[nrow(past)], colour = muted, linewidth = 0.3,
                        linetype = "22") +
    ggplot2::geom_line(data = past, ggplot2::aes(.data$time, .data$value), colour = ink,
                       linewidth = 0.55) +
    ggplot2::geom_line(data = future, ggplot2::aes(.data$time, .data$mean), colour = brand,
                       linewidth = 0.9) +
    ggplot2::geom_point(data = past[nrow(past), ], ggplot2::aes(.data$time, .data$value),
                        colour = ink, fill = "white", shape = 21, size = 2.2, stroke = 0.8) +
    ggplot2::geom_text(data = labels, ggplot2::aes(.data$time, .data$y, label = .data$text),
                       colour = muted, size = 3, hjust = -0.25, vjust = 0.5) +
    ggplot2::scale_y_continuous(labels = thousands) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(
      title = report$name,
      subtitle = sprintf("Forecast with the %s empirical intervals \u00b7 %s %.2f over %d origins",
                         paste(paste0(level_names(sort(bt$levels)), "%"), collapse = " and "),
                         toupper(bt$metric), score, bt$origins),
      x = NULL, y = NULL
    ) +
    theme_foresight() +
    ggplot2::theme(plot.margin = ggplot2::margin(14, 34, 10, 14))
}

accuracy_chart <- function(bt, top) {
  top <- check_count(top, "top", min = 1)
  best <- utils::head(bt$ranking$name[order(bt$ranking$score)], min(top, length(series_colours)))
  rows <- do.call(rbind, lapply(best, function(name) {
    a <- bt$candidates[[name]]$accuracy
    data.frame(candidate = name, horizon = a$horizon, error = a[[bt$metric]])
  }))
  rows$candidate <- factor(rows$candidate, levels = best)
  unit <- if (bt$metric %in% c("mape")) " (%)" else ""
  ggplot2::ggplot(rows, ggplot2::aes(.data$horizon, .data$error, colour = .data$candidate)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 2.4, shape = 21, fill = "white", stroke = 0.9) +
    ggplot2::scale_colour_manual(values = series_colours) +
    ggplot2::scale_x_continuous(breaks = seq_len(bt$horizon)) +
    ggplot2::guides(colour = ggplot2::guide_legend(nrow = 2, byrow = TRUE)) +
    ggplot2::labs(title = "Error by horizon",
                  subtitle = sprintf("The %d best candidates over %d origins", length(best),
                                     bt$origins),
                  x = "Periods ahead", y = paste0(toupper(bt$metric), unit)) +
    theme_foresight()
}

ranking_chart <- function(bt) {
  r <- bt$ranking[is.finite(bt$ranking$score), ]
  r$name <- factor(r$name, levels = r$name[order(r$score, decreasing = TRUE)])
  ggplot2::ggplot(r, ggplot2::aes(.data$score, .data$name)) +
    ggplot2::geom_col(ggplot2::aes(fill = .data$chosen), width = 0.62) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", .data$score)), hjust = -0.2,
                       size = 3, colour = muted) +
    ggplot2::scale_fill_manual(values = c(`TRUE` = brand, `FALSE` = "#c9cddb"), guide = "none") +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.12))) +
    ggplot2::labs(title = "Candidates by out-of-sample error",
                  subtitle = sprintf("%s averaged over %d horizons and %d origins; the chosen one in colour",
                                     toupper(bt$metric), bt$horizon, bt$origins),
                  x = NULL, y = NULL) +
    theme_foresight() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                   panel.grid.major.x = ggplot2::element_line(colour = faint, linewidth = 0.4),
                   axis.text.y = ggplot2::element_text(colour = ink))
}

#' @rdname autoplot.foresight_backtest
#' @export
autoplot.foresight_decomposition <- function(object, ...) {
  n <- length(object$trend)
  tsp <- stats::tsp(object$trend)
  frequency <- if (is.null(tsp)) 1 else tsp[3]
  at <- if (is.null(tsp)) seq_len(n) else tsp[1] + (seq_len(n) - 1) / frequency
  seasonal <- as.matrix(object$seasonal)
  parts <- c(list(Series = as.numeric(object$seasonally_adjusted) + rowSums(seasonal),
                  Trend = as.numeric(object$trend)),
             stats::setNames(lapply(seq_len(ncol(seasonal)), function(j) seasonal[, j]),
                             sprintf("Seasonal (period %d)", object$periods)),
             list(Remainder = as.numeric(object$remainder)))
  rows <- do.call(rbind, lapply(names(parts), function(p) {
    data.frame(component = p, time = as_time(at, frequency), value = parts[[p]])
  }))
  rows$component <- factor(rows$component, levels = names(parts))
  lines <- rows[rows$component != "Remainder", ]
  rest <- rows[rows$component == "Remainder", ]
  ggplot2::ggplot() +
    ggplot2::geom_line(data = lines, ggplot2::aes(.data$time, .data$value), colour = ink,
                       linewidth = 0.5) +
    ggplot2::geom_hline(data = data.frame(component = factor("Remainder", levels = names(parts))),
                        ggplot2::aes(yintercept = 0), colour = faint) +
    ggplot2::geom_segment(data = rest, ggplot2::aes(x = .data$time, xend = .data$time, y = 0,
                                                    yend = .data$value), colour = brand,
                          linewidth = 0.4) +
    ggplot2::facet_wrap(~component, ncol = 1, scales = "free_y") +
    ggplot2::labs(
      title = "Decomposition",
      subtitle = sprintf("Strength of the trend %.2f \u00b7 of seasonality %s",
                         object$trend_strength,
                         paste(sprintf("%.2f", object$seasonal_strength), collapse = ", ")),
      x = NULL, y = NULL
    ) +
    theme_foresight() +
    ggplot2::theme(panel.spacing.y = ggplot2::unit(10, "pt"))
}

#' @rdname autoplot.foresight_backtest
#' @export
plot.foresight_decomposition <- function(x, ...) {
  p <- autoplot.foresight_decomposition(x)
  print(p)
  invisible(p)
}

#' @export
ggplot2::autoplot
