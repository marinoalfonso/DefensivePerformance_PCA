# =============================================================================
# helpers.R
# Reusable utility functions for DefensivePerformance_PCA
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Data loading & cleaning
# -----------------------------------------------------------------------------

#' Load and merge defensive stats for the top 5 European leagues
#'
#' @param season_end_year Integer. The year in which the season ends (e.g. 2024).
#' @return A cleaned data.frame with renamed columns, ready for analysis.
load_defensive_data <- function(season_end_year = 2024) {
  if (!requireNamespace("worldfootballR", quietly = TRUE))
    stop("Please install the 'worldfootballR' package.")

  df_ITA <- worldfootballR::fb_season_team_stats("ITA", "M", season_end_year, "1st", "defense")[1:20, ]
  df_GER <- worldfootballR::fb_season_team_stats("GER", "M", season_end_year, "1st", "defense")[1:18, ]
  df_FRA <- worldfootballR::fb_season_team_stats("FRA", "M", season_end_year, "1st", "defense")[1:18, ]
  df_SPA <- worldfootballR::fb_season_team_stats("ESP", "M", season_end_year, "1st", "defense")[1:20, ]
  df_ENG <- worldfootballR::fb_season_team_stats("ENG", "M", season_end_year, "1st", "defense")[1:20, ]

  df <- rbind(df_ITA, df_GER, df_FRA, df_SPA, df_ENG)
  clean_defensive_data(df)
}


#' Remove non-informative columns and standardise variable names
#'
#' @param df Raw data.frame as returned by \code{load_defensive_data()}.
#' @return Cleaned data.frame.
clean_defensive_data <- function(df) {
  df <- subset(df,
               select = -c(Competition_Name, Gender, Country, Season_End_Year,
                           Team_or_Opponent, Num_Players, Mins_Per_90,
                           Tkl_plus_Int, Blocks_Blocks))

  df <- dplyr::rename(df,
                      Tkl           = Tkl_Tackles,
                      TklWin        = TklW_Tackles,
                      Def.3rd_Tkl   = `Def 3rd_Tackles`,
                      Mid.3rd_Tkl   = `Mid 3rd_Tackles`,
                      Att.3rd_Tkl   = `Att 3rd_Tackles`,
                      Tkl_Drib      = Tkl_Challenges,
                      Atmp_Drib     = Att_Challenges,
                      Tkl_Drib.Perc = Tkl_percent_Challenges,
                      Lost_Drib     = Lost_Challenges,
                      Sh_Blk        = Sh_Blocks,
                      Pass_Blk      = Pass_Blocks)
  df
}


#' Extract the numeric sub-matrix and set row names to squad names
#'
#' @param df Cleaned data.frame from \code{clean_defensive_data()}.
#' @return Numeric data.frame with squads as row names.
make_numerical_data <- function(df) {
  nd <- df[, 2:15]
  rownames(nd) <- df$Squad
  nd
}


# -----------------------------------------------------------------------------
# 2. Visualisation helpers
# -----------------------------------------------------------------------------

#' Compute percentile ranks (0–100) for every column of a data.frame
#'
#' @param df Numeric data.frame.
#' @return data.frame of the same dimensions with percentile ranks.
calculate_percentiles <- function(df) {
  as.data.frame(apply(df, 2, function(x) rank(x, ties.method = "min") / length(x) * 100))
}


#' Draw a radar (spider) chart for a single team
#'
#' @param data       Numeric data.frame (rows = teams, cols = variables).
#' @param squad_index Integer row index of the team to plot.
#' @param title      Character string for the chart title.
#' @param color      Color for the polygon fill and border.
radar_chart <- function(data, squad_index, title, color) {
  if (!requireNamespace("fmsb",   quietly = TRUE)) stop("Install 'fmsb'.")
  if (!requireNamespace("scales", quietly = TRUE)) stop("Install 'scales'.")

  percentiles <- calculate_percentiles(data)
  squad_data  <- percentiles[squad_index, , drop = FALSE]
  squad_data  <- rbind(rep(100, ncol(squad_data)),
                       rep(0,   ncol(squad_data)),
                       squad_data)

  fmsb::radarchart(squad_data, axistype = 1,
                   pcol       = color,
                   pfcol      = scales::alpha(color, 0.5),
                   plwd       = 2,
                   cglcol     = "grey", cglty = 1,
                   axislabcol = "grey",
                   caxislabels = seq(0, 100, 20),
                   cglwd      = 0.8,
                   vlcex      = 0.8)
  title(main = title)
}


#' Create radar charts for all teams in a single league
#'
#' @param league_data  Numeric data.frame for one league (rows = teams).
#' @param league_name  Character string for the overall title.
#' @param color        Polygon color.
#' @param ncols        Number of columns in the panel layout (default 4).
create_league_radar_charts <- function(league_data, league_name, color, ncols = 4) {
  squads <- rownames(league_data)
  nrows  <- ceiling(length(squads) / ncols)
  par(mfrow = c(nrows, ncols), mar = c(2, 2, 2, 1), oma = c(0, 0, 4, 0))
  for (i in seq_along(squads)) {
    radar_chart(league_data, i, squads[i], color)
  }
  mtext(league_name, outer = TRUE, cex = 2.5)
  par(mfrow = c(1, 1))
}


# -----------------------------------------------------------------------------
# 3. Modelling helpers
# -----------------------------------------------------------------------------

#' Fit a full multiple linear regression for TklWin and apply backward selection
#'
#' @param numerical_data Numeric data.frame (output of \code{make_numerical_data()}).
#' @return A list with elements \code{full} and \code{backward} (both \code{lm} objects).
fit_tklwin_model <- function(numerical_data) {
  full <- lm(TklWin ~ Def.3rd_Tkl + Att.3rd_Tkl + Mid.3rd_Tkl +
               Int + Tkl_Drib + Sh_Blk + Pass_Blk + Err + Lost_Drib + Clr,
             data = numerical_data)

  backward <- step(full, direction = "backward", trace = 0)
  list(full = full, backward = backward)
}


#' Run the four standard regression diagnostic tests
#'
#' @param model An \code{lm} object (typically the backward-selected model).
#' @param data  The data.frame used to fit \code{model}.
#' @return Invisibly returns a named list of test results.
run_diagnostics <- function(model, data) {
  cat("--- Student's t-test on residuals ---\n")
  tt <- t.test(model$residuals)
  print(tt)

  cat("\n--- Shapiro-Wilk normality test ---\n")
  sw <- shapiro.test(model$residuals)
  print(sw)

  cat("\n--- Breusch-Pagan homoscedasticity test ---\n")
  bp <- lmtest::bptest(formula(model), data = data)
  print(bp)

  cat("\n--- Durbin-Watson autocorrelation test ---\n")
  dw <- lmtest::dwtest(model, data = data)
  print(dw)

  invisible(list(t_test = tt, shapiro = sw, bp_test = bp, dw_test = dw))
}
