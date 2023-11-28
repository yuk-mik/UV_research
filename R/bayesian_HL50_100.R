#########
## load("Cases/Uncanny.Rda")
Uncanny_HL <- read.xlsx('path/file', na.string = '')

###外れ値検出，削除（z-score）
z_scores <- scale(Uncanny_HL[, 2])
threshold <- 2
outlier_indices <- which(abs(z_scores) > threshold)
Uncanny_HL_z <- Uncanny_HL[-outlier_indices,]

attach(Uncanny_HL)
## mystudy
## huMech:Humanlikenessscore
## avg_like:N400component

###Humanlikenessscoreを標準化する
z_scores_HL <- scale(Uncanny_HL$Humanlikenessscore)
Uncanny_HL$Humanlikenessscore <- z_scores_HL[, 1]

z_scores_N400 <- scale(Uncanny_HL$N400component)
Uncanny_HL$N400component <- z_scores_N400[, 1]

M_poly_3 <-
  Uncanny_HL %>%
  mutate(
    huMech_0 = 1,
    huMech_1 = Humanlikenessscore,
    huMech_2 = Humanlikenessscore^2,
    huMech_3 = Humanlikenessscore^3,
  ) %>%
  stan_glm(N400component ~  huMech_1 + huMech_2 + huMech_3,
           family = gaussian(link = "identity"),
           # prior = normal(0, 0.01), 
           # prior_intercept = normal(0, 100),
           # prior_aux = gamma(0.001, 0.001),
           data = ., iter = 5000, seed = 1234
  )

P_poly_3 <- posterior(M_poly_3)

T_coef <- coef(P_poly_3)
T_coef

#####
# MCMCでの分布表示
posterior <- as.array(M_poly_3)

library("bayesplot")
library("ggplot2")
library("rstanarm")

color_scheme_set("red")
mcmc_intervals(posterior, pars = c("huMech_1", "huMech_2", "huMech_3"))

mcmc_areas(
  posterior, 
  pars = c("huMech_1", "huMech_2", "huMech_3"),
  prob = 0.8, # 80% intervals
  prob_outer = 0.99, # 99%
  point_est = "mean"
)

color_scheme_set("green")
mcmc_hist(posterior, pars = c("huMech_1", "huMech_2", "huMech_3"))

#####

library(polynom)

poly <- polynomial(T_coef$center) # UC function on center
dpoly <- deriv(poly) # 1st derivative
ddpoly <- deriv(dpoly) # 2nd derivative
stat_pts <- solve(dpoly) # finding stat points
slopes <- as.function(ddpoly)(stat_pts) # slope at stat points
trough <- stat_pts[slopes > 0] # local minimum

cat("The trough is most likely at a huMech score of ", round(trough, 2))

devtools::install_github("schmettow/uncanny")

P_trough <-
  P_poly_3 %>%
  filter(type == "fixef") %>%
  select(chain, iter, fixef, value) %>%
  spread(fixef, value) %>%
  select(Intercept, starts_with("huMech")) %>%
  mutate(trough = uncanny::trough(.)) %>%
  gather(key = parameter)

P_trough %>%
  group_by(parameter) %>%
  summarize(
    center = median(value, na.rm = T),
    lower = quantile(value, .025, na.rm = T),
    upper = quantile(value, .975, na.rm = T)
  ) 

Uncanny_HL$M_poly_3 <- predict(M_poly_3)$center

gridExtra::grid.arrange(
  Uncanny_HL %>%
    ggplot(aes(x = Humanlikenessscore, y = N400component)) +
    labs(x = "Human-likeness score", y = "N400 component") +
    geom_point(size = .7) +
    geom_smooth(aes(y = M_poly_3), se = F),
  P_trough %>%
    filter(parameter == "trough") %>%
    ggplot(aes(x = value)) +
    labs(x = "Human-likeness score") +
    geom_density() +
    xlim(-1, 1.75), 
  heights = c(.7, .3)
)

## UV Certainty that trough exists:
cert_trough <- 1 - mean(is.na(P_trough))
cat("Certainty that trough exists:", cert_trough)

post_pred(M_poly_3, thin = 100) %>%
  left_join(Uncanny_HL, by = "X1") %>%
  ggplot(aes(x = Humanlikenessscore, y = value, group = iter)) +
  stat_smooth(geom = "line", se = FALSE)

## model summary
summary_model <- summary(M_poly_3, probs = c(0.025,0.5,0.975))

## data export(csv)
sheetList<-list("T_coef"=T_coef, "trough" = trough, "summary_" = summary_model)
# write.xlsx(sheetList, "path/file")
write.xlsx(sheetList, "path/file")
