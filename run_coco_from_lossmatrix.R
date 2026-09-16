################################################################################
# Reproduce the COCO five-method comparison from the SAVED loss matrix.
# No Python / detector / reticulate needed: the detector's output is already
# stored in coco_loss_matrix.rds (loss_mat, set_sizes_mat, Lambda, m, B, ...).
# This runs your original Block 8-9 code verbatim on that saved matrix.
################################################################################

RDS_PATH <- "E:/coco_dataset/coco_loss_matrix.rds"   # <-- point to your saved loss matrix
stopifnot(file.exists(RDS_PATH))
dat <- readRDS(RDS_PATH)

loss_mat       <- dat$loss_mat
set_sizes_mat  <- dat$set_sizes_mat
Lambda         <- dat$Lambda
m              <- dat$m
B              <- dat$B
n_images       <- nrow(loss_mat)

# ---- Block 8 parameters (identical to the original script) ----
N_CAL  <- 2500
N_TEST <- 800
ALPHA  <- 0.33
N_SIMS <- 3000
N_BOOT <- 200
method_names <- c("CRC", "CRC-C", "Loss Mono", "Risk Mono", "CRC-NM")
n_methods <- length(method_names)

D_mn <- B * sqrt(log(2 * m) / (2 * N_CAL)) + B / (2 * sqrt(2 * N_CAL * log(2 * m)))
ALPHA_PRIME <- ALPHA - D_mn

cat(sprintf("Loss matrix: %d images x %d grid points\n", n_images, m))
cat(sprintf("m=%d  B=%.1f  alpha=%.3f  D(m,n)=%.6f  alpha'=%.6f\n",
            m, B, ALPHA, D_mn, ALPHA_PRIME))
cat(sprintf("Loss params: gamma=%.2f K0=%d TAU=%d ; lambda in [%.3f, %.3f]\n\n",
            dat$loss_params$gamma, dat$loss_params$K0, dat$loss_params$TAU,
            min(Lambda), max(Lambda)))

mono_right <- function(x) rev(cummax(rev(x)))

# ---- selection rules (verbatim from the original script) ----
select_crc <- function(loss_mat_sub, level, B_val = 1.0) {
  n <- nrow(loss_mat_sub)
  R_hat <- colMeans(loss_mat_sub, na.rm = TRUE)
  R_hat_plus <- (n * R_hat + B_val) / (n + 1)
  idx <- which(R_hat_plus <= level)
  if (length(idx) > 0) list(index = min(idx), feasible = TRUE, curve = R_hat_plus)
  else               list(index = which.min(R_hat_plus), feasible = FALSE, curve = R_hat_plus)
}
select_loss_mono <- function(loss_mat_sub, level, B_val = 1.0) {
  n <- nrow(loss_mat_sub)
  loss_mono <- t(apply(loss_mat_sub, 1, mono_right))
  R_tilde <- colMeans(loss_mono, na.rm = TRUE)
  R_tilde_plus <- (n * R_tilde + B_val) / (n + 1)
  idx <- which(R_tilde_plus <= level)
  if (length(idx) > 0) list(index = min(idx), feasible = TRUE, curve = R_tilde_plus)
  else               list(index = which.min(R_tilde_plus), feasible = FALSE, curve = R_tilde_plus)
}
select_risk_mono <- function(loss_mat_sub, level, B_val = 1.0) {
  n <- nrow(loss_mat_sub)
  R_hat <- colMeans(loss_mat_sub, na.rm = TRUE)
  R_hat_mono <- mono_right(R_hat)
  R_hat_mono_plus <- (n * R_hat_mono + B_val) / (n + 1)
  idx <- which(R_hat_mono_plus <= level)
  if (length(idx) > 0) list(index = min(idx), feasible = TRUE, curve = R_hat_mono_plus)
  else               list(index = which.min(R_hat_mono_plus), feasible = FALSE, curve = R_hat_mono_plus)
}
estimate_beta <- function(loss_mat_sub, level, n_boot, B_val = 1.0) {
  n <- nrow(loss_mat_sub)
  full_sel <- select_crc(loss_mat_sub, level, B_val = B_val)
  R_full <- mean(loss_mat_sub[, full_sel$index], na.rm = TRUE)
  deltas <- numeric(n_boot)
  for (b in seq_len(n_boot)) {
    boot_rows <- sample.int(n, n, replace = TRUE)
    L_boot <- loss_mat_sub[boot_rows, , drop = FALSE]
    boot_sel <- select_crc(L_boot, level, B_val = B_val)
    deltas[b] <- abs(mean(L_boot[, boot_sel$index], na.rm = TRUE) - R_full)
  }
  as.numeric(quantile(deltas, 0.90, na.rm = TRUE))
}

all_risk <- matrix(NA_real_, N_SIMS, n_methods)
all_setsize <- matrix(NA_real_, N_SIMS, n_methods)
all_lambda <- matrix(NA_real_, N_SIMS, n_methods)
all_feasible <- matrix(NA, N_SIMS, n_methods)

set.seed(42)
for (sim in seq_len(N_SIMS)) {
  idx <- sample(n_images)
  cal_idx  <- idx[1:N_CAL]
  test_idx <- idx[(N_CAL + 1):(N_CAL + N_TEST)]
  sub_cal_L  <- loss_mat[cal_idx, , drop = FALSE]
  sub_test_L <- loss_mat[test_idx, , drop = FALSE]
  sub_test_S <- set_sizes_mat[test_idx, , drop = FALSE]

  beta_hat   <- estimate_beta(sub_cal_L, ALPHA, N_BOOT, B_val = B)
  alpha_crcc <- max(ALPHA - beta_hat, 0.01)

  sels <- list(
    select_crc(sub_cal_L, ALPHA,       B_val = B),
    select_crc(sub_cal_L, alpha_crcc,  B_val = B),
    select_loss_mono(sub_cal_L, ALPHA, B_val = B),
    select_risk_mono(sub_cal_L, ALPHA, B_val = B),
    select_crc(sub_cal_L, ALPHA_PRIME, B_val = B)
  )
  for (k in 1:n_methods) {
    li <- sels[[k]]$index
    all_risk[sim, k]     <- mean(sub_test_L[, li], na.rm = TRUE)
    all_setsize[sim, k]  <- mean(sub_test_S[, li], na.rm = TRUE)
    all_lambda[sim, k]   <- Lambda[li]
    all_feasible[sim, k] <- sels[[k]]$feasible
  }
}

cat(sprintf("%-11s %10s %9s %10s %9s %9s\n",
            "Method","MeanRisk","Viol%","MeanSize","MeanLam","Feas%"))
cat(paste(rep("-",64),collapse=""),"\n")
for (k in 1:n_methods)
  cat(sprintf("%-11s %10.4f %9.1f %10.2f %9.3f %9.1f\n",
      method_names[k], mean(all_risk[,k]), 100*mean(all_risk[,k]>ALPHA),
      mean(all_setsize[,k]), mean(all_lambda[,k]), 100*mean(all_feasible[,k])))

saveRDS(list(all_risk=all_risk, all_setsize=all_setsize, all_lambda=all_lambda,
             all_feasible=all_feasible, method_names=method_names,
             ALPHA=ALPHA, ALPHA_PRIME=ALPHA_PRIME, D_mn=D_mn),
        "coco_five_method_results_REGEN.rds")
cat("\nSaved: coco_five_method_results_REGEN.rds\n")
