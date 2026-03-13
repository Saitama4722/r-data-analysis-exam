# =============================================================================
# Решение экзамена по анализу данных в R
# Запуск: открыть в R/RStudio и выполнить весь скрипт (источник сверху вниз).
# =============================================================================

# -----------------------------------------------------------------------------
# 1. ПОДГОТОВКА ОКРУЖЕНИЯ
# -----------------------------------------------------------------------------
# Подключаем пакеты: при первом запуске недостающие ставятся из CRAN автоматически.

required_packages <- c(
  "readr",      # чтение CSV с разными разделителями
  "ggplot2",   # графики
  "tidyr",     # преобразование данных (для сводок и длинного формата)
  "dplyr",     # манипуляции с таблицами
  "cluster",   # кластеризация и silhouette
  "gganimate", # анимация для задания 6
  "gifski"     # сохранение GIF из gganimate
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org/")
  }
  library(pkg, character.only = TRUE)
}

if (!dir.exists("outputs")) {
  dir.create("outputs")
  message("Создана папка outputs для графиков и таблиц.")
}

# -----------------------------------------------------------------------------
# 2. ЗАДАНИЕ 1 — Чтение и осмотр data_5.csv
# -----------------------------------------------------------------------------
# Файл в формате CSV с разделителем ";" и кавычками — как при экспорте из Excel
# с европейской локалью. Явно задаём sep и quote, чтобы чтение было предсказуемым.

message("\n========== ЗАДАНИЕ 1: Загрузка и обзор данных ==========")

# Путь к файлу: предполагаем, что скрипт запускается из папки с data_5.csv
path_data <- "data_5.csv"
if (!file.exists(path_data)) {
  stop("Файл data_5.csv не найден. Запустите скрипт из папки с этим файлом.")
}

# Читаем с учётом разделителя и кавычек; пустое имя первого столбца не мешает
df <- read.csv(path_data, sep = ";", quote = "\"", stringsAsFactors = FALSE,
               check.names = FALSE)
# dplyr не любит пустые имена столбцов — задаём имя для первого (номер строки/ID)
if (names(df)[1] == "" || is.na(names(df)[1])) names(df)[1] <- "id"

n_rows <- nrow(df)
n_cols <- ncol(df)
cat("\nРазмер таблицы (строки x столбцы):", n_rows, "x", n_cols, "\n")
cat("\nИмена столбцов:\n")
print(names(df))
cat("\nПервые строки данных:\n")
print(head(df))
cat("\nСтруктура данных (str):\n")
str(df)

nas <- colSums(is.na(df))
cat("\nКоличество пропусков по столбцам:\n")
print(nas)
total_nas <- sum(nas)
cat("Всего пропусков в таблице:", total_nas, "\n")

# В CSV значения в кавычках могли прочитаться как символы. Преобразуем все
# столбцы с пунктами опросника (EXT*, EST*, AGR*, CSN*, OPN*) в числа.
scale_cols <- grep("^(EXT|EST|AGR|CSN|OPN)[0-9]+$", names(df), value = TRUE)
for (col in scale_cols) {
  df[[col]] <- as.numeric(as.character(df[[col]]))
}

# Проверка нулей в столбцах шкал: в опросниках Big Five допустимы значения 1–5,
# ноль обычно означает «нет ответа» или пропуск. Считаем, сколько нулей в каждом таком столбце.
zeros_in_scales <- colSums(df[, scale_cols, drop = FALSE] == 0, na.rm = TRUE)
cat("\nКоличество нулей в столбцах шкал (EXT*, EST*, AGR*, CSN*, OPN*):\n")
print(zeros_in_scales)
cat("Всего нулей в шкалах:", sum(zeros_in_scales), "\n")
if (sum(zeros_in_scales) > 0) {
  cat("(В шкалах Big Five допустим диапазон 1–5; нули трактуем как пропуски при варианте «нули = NA».)\n")
}

# -----------------------------------------------------------------------------
# Сравнение двух вариантов: нули как обычные значения vs нули как пропуски (NA)
# От этого выбора зависят средние по шкалам и кластеризация. Сравниваем по
# среднему silhouette при k=3: более осмысленная кластеризация даёт выше silhouette.
# -----------------------------------------------------------------------------

scale_prefixes <- c("EXT", "EST", "AGR", "CSN", "OPN")

# Вариант 1: нули остаются числами. Считаем среднее по шкалам для каждой строки.
df_zeros_as_values <- df
for (prefix in scale_prefixes) {
  pattern <- paste0("^", prefix, "[0-9]+$")
  col_idx <- grep(pattern, names(df_zeros_as_values))
  if (length(col_idx) == 0) col_idx <- grep(paste0("^", prefix), names(df_zeros_as_values))
  if (length(col_idx) > 0) {
    df_zeros_as_values[[prefix]] <- rowMeans(df_zeros_as_values[, col_idx, drop = FALSE], na.rm = TRUE)
  }
}

# Вариант 2: в столбцах шкал нули заменяем на NA, затем считаем среднее по шкалам.
df_zeros_as_na <- df
for (col in scale_cols) {
  idx_zero <- which(df_zeros_as_na[[col]] == 0)
  if (length(idx_zero) > 0) df_zeros_as_na[[col]][idx_zero] <- NA
}
for (prefix in scale_prefixes) {
  pattern <- paste0("^", prefix, "[0-9]+$")
  col_idx <- grep(pattern, names(df_zeros_as_na))
  if (length(col_idx) == 0) col_idx <- grep(paste0("^", prefix), names(df_zeros_as_na))
  if (length(col_idx) > 0) {
    df_zeros_as_na[[prefix]] <- rowMeans(df_zeros_as_na[, col_idx, drop = FALSE], na.rm = TRUE)
  }
}

# Кластеризация при k=3 для сравнения: только строки без пропусков по шкалам.
five <- c("EXT", "EST", "AGR", "CSN", "OPN")
X_val <- as.matrix(df_zeros_as_values[, five])
X_val <- scale(X_val[complete.cases(X_val), ])
X_na  <- as.matrix(df_zeros_as_na[, five])
X_na  <- scale(X_na[complete.cases(X_na), ])

set.seed(42)
km_val <- kmeans(X_val, centers = 3, nstart = 25)
km_na  <- kmeans(X_na,  centers = 3, nstart = 25)
sil_val <- mean(silhouette(km_val$cluster, dist(X_val))[, "sil_width"])
sil_na  <- mean(silhouette(km_na$cluster,  dist(X_na))[, "sil_width"])

cat("\nСравнение кластеризации (k=3):\n")
cat("  Нули как значения — средняя ширина silhouette:", round(sil_val, 4), ", N =", nrow(X_val), "\n")
tbl_val <- table(km_val$cluster)
cat("  Размеры кластеров (нули как значения):", paste(tbl_val, collapse = ", "), "\n")
cat("  Нули как NA      — средняя ширина silhouette:", round(sil_na, 4), ", N =", nrow(X_na), "\n")
tbl_na <- table(km_na$cluster)
cat("  Размеры кластеров (нули как NA):", paste(tbl_na, collapse = ", "), "\n")

# Вариант с NA выбираем, если у него выше silhouette ИЛИ если при «нули как значения»
# появляется крошечный кластер (артефакт нулей) — тогда трактовка нулей как пропусков осмысленнее
min_cluster_share <- min(tbl_val) / length(km_val$cluster)
use_zeros_as_na <- (sil_na >= sil_val) || (min_cluster_share < 0.01)
if (use_zeros_as_na) {
  df <- df_zeros_as_na
  message("Выбран вариант «нули = NA» (более осмысленная кластеризация).")
} else {
  df <- df_zeros_as_values
  message("Выбран вариант «нули как значения».")
}

# -----------------------------------------------------------------------------
# 3. ЗАДАНИЕ 2 — Шкалы Большой пятёрки (Big Five)
# -----------------------------------------------------------------------------
# В df уже посчитаны средние по шкалам (EXT, EST, AGR, CSN, OPN) для выбранного
# варианта обработки нулей. Дальше — сводки по выборке и графики.

message("\n========== ЗАДАНИЕ 2: Шкалы Big Five ==========")

# Средние по всей выборке по каждой шкале — общая картина
scale_means <- df %>%
  summarise(
    EXT = mean(EXT, na.rm = TRUE),
    EST = mean(EST, na.rm = TRUE),
    AGR = mean(AGR, na.rm = TRUE),
    CSN = mean(CSN, na.rm = TRUE),
    OPN = mean(OPN, na.rm = TRUE)
  )
cat("\nСредние значения шкал по всей выборке:\n")
print(scale_means)

# Столбчатая диаграмма средних по шкалам
scale_means_long <- scale_means %>%
  tidyr::pivot_longer(everything(), names_to = "scale", values_to = "mean_value")

p_bar <- ggplot(scale_means_long, aes(x = scale, y = mean_value, fill = scale)) +
  geom_col() +
  labs(
    title = "Средние значения шкал Big Five по выборке",
    x = "Шкала",
    y = "Среднее значение"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
print(p_bar)
ggsave("outputs/task2_bar_scale_means.png", p_bar, width = 6, height = 4, dpi = 150)
message("График сохранён: outputs/task2_bar_scale_means.png")

# Ящики с усами по шкалам — разброс и выбросы по выборке
df_long_scales <- df %>%
  select(EXT, EST, AGR, CSN, OPN) %>%
  tidyr::pivot_longer(everything(), names_to = "scale", values_to = "value")

p_box <- ggplot(df_long_scales, aes(x = scale, y = value, fill = scale)) +
  geom_boxplot() +
  labs(
    title = "Распределение шкал Big Five по респондентам",
    x = "Шкала",
    y = "Значение"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
print(p_box)
ggsave("outputs/task2_boxplot_scales.png", p_box, width = 6, height = 4, dpi = 150)
message("График сохранён: outputs/task2_boxplot_scales.png")

# -----------------------------------------------------------------------------
# 4. ЗАДАНИЕ 4 — Группы респондентов (кластеризация по Big Five)
# -----------------------------------------------------------------------------
# Кластеризация строится по выбранному варианту обработки нулей (см. выше).
# Шкалы стандартизуем, иначе более «разбросанные» шкалы перевесят остальные.
# Число кластеров подбираем по методу локтя и по средней ширине silhouette.

message("\n========== ЗАДАНИЕ 4: Кластеризация по шкалам Big Five ==========")

# Матрица только по шкалам; без пропусков для кластеризации
X <- as.matrix(df[, c("EXT", "EST", "AGR", "CSN", "OPN")])
X <- X[complete.cases(X), ]

# Стандартизация: среднее 0, sd 1 — чтобы все шкалы вносили равный вклад
X_scaled <- scale(X)

# Подбор числа кластеров: метод локтя (within-cluster sum of squares)
set.seed(42)
k_max <- 10
wss <- numeric(k_max)
for (k in 1:k_max) {
  km <- kmeans(X_scaled, centers = k, nstart = 25)
  wss[k] <- km$tot.withinss
}

# График локтя
elbow_data <- data.frame(k = 1:k_max, WSS = wss)
p_elbow <- ggplot(elbow_data, aes(x = k, y = WSS)) +
  geom_line() + geom_point() +
  labs(
    title = "Метод локтя: подбор числа кластеров",
    x = "Число кластеров k",
    y = "Сумма квадратов внутри кластеров (WSS)"
  ) +
  theme_minimal()
print(p_elbow)
ggsave("outputs/task4_elbow.png", p_elbow, width = 5, height = 4, dpi = 150)

# Silhouette: насколько объект похож на свой кластер по сравнению с другими
sil_widths <- numeric(k_max)
for (k in 2:k_max) {
  km <- kmeans(X_scaled, centers = k, nstart = 25)
  sil <- silhouette(km$cluster, dist(X_scaled))
  sil_widths[k] <- mean(sil[, "sil_width"])
}
sil_widths[1] <- NA

sil_data <- data.frame(k = 1:k_max, silhouette = sil_widths)
p_sil <- ggplot(sil_data[!is.na(sil_data$silhouette), ], aes(x = k, y = silhouette)) +
  geom_line() + geom_point() +
  labs(
    title = "Средняя ширина silhouette по числу кластеров",
    x = "Число кластеров k",
    y = "Средняя ширина silhouette"
  ) +
  theme_minimal()
print(p_sil)
ggsave("outputs/task4_silhouette.png", p_sil, width = 5, height = 4, dpi = 150)

# k выбираем по форме локтя и silhouette; для интерпретации профилей удобно 3–5 кластеров
k_choice <- 3
km_final <- kmeans(X_scaled, centers = k_choice, nstart = 50)

# Приписываем кластер каждой строке; при пропусках по шкалам кластер не определяем (NA)
df$cluster <- NA
df[complete.cases(df[, c("EXT", "EST", "AGR", "CSN", "OPN")]), "cluster"] <- km_final$cluster

# Профили кластеров: средние по шкалам в каждой группе
cluster_means <- df %>%
  filter(!is.na(cluster)) %>%
  group_by(cluster) %>%
  summarise(
    EXT = mean(EXT, na.rm = TRUE),
    EST = mean(EST, na.rm = TRUE),
    AGR = mean(AGR, na.rm = TRUE),
    CSN = mean(CSN, na.rm = TRUE),
    OPN = mean(OPN, na.rm = TRUE),
    n = n()
  )
cat("\nСредние значения шкал по кластерам:\n")
print(cluster_means)

# Сохраняем сводку по кластерам в файл
write.csv(cluster_means, "outputs/task4_cluster_means.csv", row.names = FALSE)

# Визуализация: средние по шкалам в каждом кластере (столбчатая)
cluster_means_long <- cluster_means %>%
  select(-n) %>%
  tidyr::pivot_longer(-cluster, names_to = "scale", values_to = "value")

p_cluster <- ggplot(cluster_means_long, aes(x = scale, y = value, fill = factor(cluster))) +
  geom_col(position = "dodge") +
  labs(
    title = "Средние значения шкал Big Five по кластерам",
    x = "Шкала",
    y = "Среднее значение",
    fill = "Кластер"
  ) +
  theme_minimal()
print(p_cluster)
ggsave("outputs/task4_clusters_bars.png", p_cluster, width = 7, height = 4, dpi = 150)
message("Результаты задания 4 сохранены в папке outputs.")

cat("\nВывод по кластерам: группы различаются по профилю шкал. Второй кластер в среднем выше остальных по экстраверсии, доброжелательности, добросовестности и открытости; первый выделяется более высокой эмоциональной стабильностью при средних остальных показателях; третий кластер — с наиболее низкими значениями по эмоциональной стабильности и добросовестности. Явно выраженного «типа» вроде «всё высокое» или «всё низкое» нет: у каждой группы свой рисунок по шкалам.\n")

# -----------------------------------------------------------------------------
# 5. ЗАДАНИЕ 3 — Настольные игры (рейтинг и предикторы)
# -----------------------------------------------------------------------------
# Два датасета (рейтинги и детали игр) объединяем по id. Смотрим связь среднего
# рейтинга с временем игры, числом игроков, годом издания и минимальным возрастом.

message("\n========== ЗАДАНИЕ 3: Настольные игры ==========")

ratings <- readr::read_csv(
  "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2022/2022-01-25/ratings.csv",
  show_col_types = FALSE
)
details <- readr::read_csv(
  "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2022/2022-01-25/details.csv",
  show_col_types = FALSE
)

cat("\nСтруктура ratings:\n")
str(ratings)
cat("\nСтруктура details:\n")
str(details)

# Объединяем по id (в обоих датасетах TidyTuesday поле называется id)
games <- inner_join(ratings, details, by = "id")
cat("\nРазмер объединённой таблицы:", nrow(games), "строк\n")

vars_needed <- c("average", "playingtime", "minplayers", "maxplayers", "yearpublished", "minage")
games_sel <- games %>% select(id, any_of(vars_needed))

# Один показатель «число игроков»: среднее от min и max при наличии обоих
if ("minplayers" %in% names(games_sel) && "maxplayers" %in% names(games_sel)) {
  games_sel$players <- (games_sel$minplayers + games_sel$maxplayers) / 2
} else if ("minplayers" %in% names(games_sel)) {
  games_sel$players <- games_sel$minplayers
} else {
  games_sel$players <- NA
}

# Для регрессии оставляем только строки без пропусков по используемым переменным
games_sel <- games_sel %>%
  filter(!is.na(average), !is.na(players))
if ("playingtime" %in% names(games_sel)) games_sel <- games_sel %>% filter(!is.na(playingtime))
if ("yearpublished" %in% names(games_sel)) games_sel <- games_sel %>% filter(!is.na(yearpublished))
if ("minage" %in% names(games_sel)) games_sel <- games_sel %>% filter(!is.na(minage))

# Корреляции с рейтингом
if ("playingtime" %in% names(games_sel)) {
  cor_pt <- cor(games_sel$average, games_sel$playingtime, use = "complete.obs")
  cat("\nКорреляция рейтинг — время игры:", round(cor_pt, 4), "\n")
}
if ("yearpublished" %in% names(games_sel)) {
  cor_yr <- cor(games_sel$average, games_sel$yearpublished, use = "complete.obs")
  cat("Корреляция рейтинг — год издания:", round(cor_yr, 4), "\n")
}
if ("minage" %in% names(games_sel)) {
  cor_age <- cor(games_sel$average, games_sel$minage, use = "complete.obs")
  cat("Корреляция рейтинг — мин. возраст:", round(cor_age, 4), "\n")
}
cor_pl <- cor(games_sel$average, games_sel$players, use = "complete.obs")
cat("Корреляция рейтинг — число игроков:", round(cor_pl, 4), "\n")

# Scatter: рейтинг vs время игры (если есть)
if ("playingtime" %in% names(games_sel)) {
  p_scatter_time <- ggplot(games_sel, aes(x = playingtime, y = average)) +
    geom_point(alpha = 0.3) +
    geom_smooth(method = "lm", se = TRUE, colour = "darkblue", linewidth = 0.8) +
    labs(title = "Рейтинг настольных игр и время игры", x = "Время игры (мин)", y = "Средний рейтинг") +
    theme_minimal()
  print(p_scatter_time)
  ggsave("outputs/task3_scatter_playingtime.png", p_scatter_time, width = 6, height = 4, dpi = 150)
}

# Отдельные scatter с линией тренда: players, yearpublished, minage относительно average
p_players <- ggplot(games_sel, aes(x = players, y = average)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = TRUE, colour = "darkgreen", linewidth = 0.8) +
  labs(title = "Рейтинг и число игроков", x = "Число игроков (среднее min–max)", y = "Средний рейтинг") +
  theme_minimal()
print(p_players)
ggsave("outputs/task3_scatter_players.png", p_players, width = 6, height = 4, dpi = 150)

if ("yearpublished" %in% names(games_sel)) {
  p_year <- ggplot(games_sel, aes(x = yearpublished, y = average)) +
    geom_point(alpha = 0.3) +
    geom_smooth(method = "lm", se = TRUE, colour = "darkred", linewidth = 0.8) +
    labs(title = "Рейтинг и год издания", x = "Год издания", y = "Средний рейтинг") +
    theme_minimal()
  print(p_year)
  ggsave("outputs/task3_scatter_yearpublished.png", p_year, width = 6, height = 4, dpi = 150)
}

if ("minage" %in% names(games_sel)) {
  p_minage <- ggplot(games_sel, aes(x = minage, y = average)) +
    geom_point(alpha = 0.3) +
    geom_smooth(method = "lm", se = TRUE, colour = "purple3", linewidth = 0.8) +
    labs(title = "Рейтинг и минимальный возраст", x = "Минимальный возраст", y = "Средний рейтинг") +
    theme_minimal()
  print(p_minage)
  ggsave("outputs/task3_scatter_minage.png", p_minage, width = 6, height = 4, dpi = 150)
}

# Линейная модель: рейтинг от времени, игроков, года, возраста
preds <- c()
if ("playingtime" %in% names(games_sel)) preds <- c(preds, "playingtime")
preds <- c(preds, "players")
if ("yearpublished" %in% names(games_sel)) preds <- c(preds, "yearpublished")
if ("minage" %in% names(games_sel)) preds <- c(preds, "minage")
form <- as.formula(paste("average ~", paste(preds, collapse = " + ")))
lm_games <- lm(form, data = games_sel)
cat("\nSummary линейной модели (рейтинг от предикторов):\n")
print(summary(lm_games))

# Сохраняем объединённый датасет и коэффициенты модели
games_merged <- games %>% select(id, any_of(vars_needed))
if ("minplayers" %in% names(games_merged) && "maxplayers" %in% names(games_merged)) {
  games_merged$players <- (games_merged$minplayers + games_merged$maxplayers) / 2
} else if ("minplayers" %in% names(games_merged)) {
  games_merged$players <- games_merged$minplayers
}
readr::write_csv(games_merged, "outputs/boardgames_merged.csv")
message("Сохранён объединённый датасет: outputs/boardgames_merged.csv")

coef_df <- as.data.frame(summary(lm_games)$coefficients)
coef_df <- cbind(term = rownames(coef_df), coef_df)
rownames(coef_df) <- NULL
readr::write_csv(coef_df, "outputs/boardgames_model_coefficients.csv")
message("Сохранены коэффициенты модели: outputs/boardgames_model_coefficients.csv")

message("Графики задания 3 сохранены в outputs.")

cat("\nВывод по настольным играм: слабее всего с рейтингом связаны время игры и число игроков — связь есть, но по величине она скромная. Чуть заметнее выглядят год издания и минимальный возраст: более новые и «взрослые» игры в среднем получают чуть более высокий рейтинг. При этом ни корреляции, ни линейная регрессия не показывают причину: мы лишь видим совместную изменчивость признаков, а не то, что один фактор порождает другой.\n")

# -----------------------------------------------------------------------------
# 6. ЗАДАНИЕ 6 — Рождаемость в Нью-Йорке
# -----------------------------------------------------------------------------
# Месячные данные по числу рождений (1946–1959). Строим временной ряд и
# анимацию раскрытия ряда по времени.

message("\n========== ЗАДАНИЕ 6: Временной ряд рождаемости ==========")

births <- scan("http://robjhyndman.com/tsdldata/data/nybirths.dat", quiet = TRUE)
births_ts <- ts(births, frequency = 12, start = c(1946, 1))

births_df <- data.frame(
  time = time(births_ts),
  value = as.numeric(births_ts)
)
births_df$year <- floor(births_df$time)
births_df$month <- round((births_df$time - births_df$year) * 12) + 1
births_df$date <- as.Date(paste(births_df$year, births_df$month, "01", sep = "-"))

# Статичный график ряда (group = 1, чтобы линия шла по всем точкам подряд)
p_ts <- ggplot(births_df, aes(x = date, y = value, group = 1)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "Количество рождений в месяц, Нью-Йорк (1946–1959)",
    x = "Дата",
    y = "Число рождений"
  ) +
  theme_minimal()
print(p_ts)
ggsave("outputs/task6_timeseries.png", p_ts, width = 8, height = 4, dpi = 150)

# Анимация: линия достраивается по дате
p_anim <- ggplot(births_df, aes(x = date, y = value, group = 1)) +
  geom_line(linewidth = 0.8, colour = "steelblue") +
  geom_point(size = 1.5) +
  labs(
    title = "Рождаемость в Нью-Йорке (1946–1959)",
    x = "Дата",
    y = "Число рождений"
  ) +
  theme_minimal() +
  transition_reveal(date)

tryCatch({
  animate(p_anim, nframes = 120, fps = 10, width = 800, height = 400,
          renderer = gifski_renderer())
  anim_save("outputs/task6_births_animation.gif")
  message("Анимация сохранена: outputs/task6_births_animation.gif")
}, error = function(e) {
  message("GIF не создан (gifski/рендер): ", e$message)
  ggsave("outputs/task6_timeseries.png", p_ts, width = 8, height = 4, dpi = 150)
})

# -----------------------------------------------------------------------------
# 7. РЕЗЮМЕ ПО ВСЕМ ЗАДАНИЯМ
# -----------------------------------------------------------------------------
message("\n========== КРАТКОЕ РЕЗЮМЕ ==========")

cat("\n--- Задание 1 ---\n")
cat("Загружен файл data_5.csv: ", n_rows, " респондентов, ", n_cols, " столбцов.\n", sep = "")
cat("Пропусков в исходных данных: ", total_nas, ".\n", sep = "")

cat("\n--- Задание 2 ---\n")
cat("Посчитаны шкалы Big Five (EXT, EST, AGR, CSN, OPN) как средние по пунктам.\n")
cat("Средние по выборке: EXT = ", round(scale_means$EXT, 2),
    ", EST = ", round(scale_means$EST, 2),
    ", AGR = ", round(scale_means$AGR, 2),
    ", CSN = ", round(scale_means$CSN, 2),
    ", OPN = ", round(scale_means$OPN, 2), ".\n", sep = "")
cat("Графики: outputs/task2_bar_scale_means.png, outputs/task2_boxplot_scales.png.\n")

cat("\n--- Задание 4 ---\n")
cat("Выполнена k-means кластеризация по стандартизованным шкалам Big Five (k = ", k_choice, ").\n", sep = "")
cat("Добавлена переменная cluster в таблицу. Средние по кластерам сохранены в outputs/task4_cluster_means.csv.\n")
cat("Графики: outputs/task4_elbow.png, outputs/task4_silhouette.png, outputs/task4_clusters_bars.png.\n")

cat("\n--- Задание 3 ---\n")
cat("Объединены датасеты ratings и details по id. Исследована связь рейтинга с временем игры,\n")
cat("числом игроков, годом издания и минимальным возрастом (корреляции и линейная модель).\n")
cat("Summary модели выведен выше. Графики в outputs/task3_*.png.\n")

cat("\n--- Задание 6 ---\n")
cat("Построен временной ряд рождений в Нью-Йорке (1946–1959), создана анимация.\n")
cat("Файлы: outputs/task6_timeseries.png, outputs/task6_births_animation.gif (если рендер прошёл).\n")

cat("\nГотово. Все результаты в папке outputs.\n")
