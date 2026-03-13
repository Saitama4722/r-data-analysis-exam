# Personality and Behavioral Data Analysis in R

## Project overview

This repository contains an end-to-end data analysis project implemented in R. The workflow covers data loading and preprocessing, computation of psychological scales (Big Five), respondent clustering, analysis of a board games dataset, and time series visualization. All steps are implemented in a single reproducible script; tables and figures are written to an output directory.

## Dataset description

The main input dataset (`data_5.csv`) holds questionnaire responses for the Big Five personality dimensions. Each dimension is measured by 10 items:

- **EXT** — Extraversion (EXT1–EXT10)
- **EST** — Emotional stability (EST1–EST10)
- **AGR** — Agreeableness (AGR1–AGR10)
- **CSN** — Conscientiousness (CSN1–CSN10)
- **OPN** — Openness to experience (OPN1–OPN10)

Item responses are on a 1–5 scale. The file uses semicolon as separator and quoted values (European-style CSV export). Zero values are treated as missing when they improve clustering interpretability.

Additional data are loaded from external sources: board games ratings and details (TidyTuesday), and monthly birth counts in New York City (1946–1959).

## Analytical workflow

1. **Data loading and preprocessing** — Read `data_5.csv`, inspect structure and missing values, convert scale columns to numeric, and choose zero-handling (as value vs as NA) using k-means silhouette comparison.
2. **Big Five scale calculation** — Aggregate item scores into five scale means per respondent, compute sample means per scale, and produce bar and box plots.
3. **Respondent clustering** — Standardize the five scales, select number of clusters via elbow and silhouette methods, run k-means (k = 3), assign cluster labels, and visualize cluster profiles.
4. **Board games dataset analysis** — Merge ratings and details by game id, build derived variables (e.g. average number of players), compute correlations with average rating, fit linear regression, and save scatter plots and model coefficients.
5. **Time series visualization** — Load monthly birth data, build a time series object, plot the full series, and create an animated GIF showing the series unfolding over time.

## Methods used

- Descriptive statistics and aggregation of questionnaire scales
- Missing value handling (zeros as NA where appropriate)
- k-means clustering with standardized features
- Elbow method (within-cluster sum of squares) for choosing k
- Silhouette analysis for cluster quality
- Correlation analysis and linear regression (board games vs rating)
- Time series representation and animated visualization (gganimate, gifski)

## Results

- **Big Five scales** — Scale means (EXT, EST, AGR, CSN, OPN) are computed per respondent; sample-level means and distributions are summarized and plotted.
- **Respondent groups** — Three clusters are identified with distinct personality profiles; one cluster shows higher emotional stability, another higher extraversion/agreeableness/conscientiousness/openness, and the third lower emotional stability and conscientiousness.
- **Board games** — Merged dataset and regression coefficients are saved; rating is weakly associated with playing time and number of players, and somewhat more with year published and minimum age.
- **Births time series** — Static plot and animated GIF illustrate monthly birth counts in New York (1946–1959), including seasonal pattern and trend.

## Project structure

```
r_data_analysis_exam
│
├── solution.R
├── data_5.csv
├── README.md
├── outputs
│   ├── boardgames_merged.csv
│   ├── boardgames_model_coefficients.csv
│   ├── task2_bar_scale_means.png
│   ├── task2_boxplot_scales.png
│   ├── task3_scatter_*.png
│   ├── task4_elbow.png
│   ├── task4_silhouette.png
│   ├── task4_clusters_bars.png
│   ├── task4_cluster_means.csv
│   ├── task6_timeseries.png
│   └── task6_births_animation.gif
```

The `outputs` folder is created by the script if missing. PNG and GIF files appear after a full run; only CSV outputs may be present if the script was run partially or graphics were skipped.

## How to run the project

1. Install [R](https://www.r-project.org/) (and optionally [RStudio](https://www.rstudio.com/)).
2. Place `solution.R` and `data_5.csv` in the same directory; set that directory as the working directory.
3. Open `solution.R` and run the entire script (e.g. Source in RStudio). Internet access is required for board games and birth data downloads.
4. Missing R packages (`readr`, `ggplot2`, `tidyr`, `dplyr`, `cluster`, `gganimate`, `gifski`) are installed from CRAN on first run.
5. Results are written to the `outputs` folder.

## Technologies used

- R
- tidyverse (readr, tidyr, dplyr)
- ggplot2
- cluster (silhouette)
- gganimate
- gifski

## Author

GitHub: [Saitama4722](https://github.com/Saitama4722)

---

# Анализ личностных и поведенческих данных в R

## Обзор проекта

Репозиторий содержит полноценный проект анализа данных на R. В нём реализованы загрузка и предобработка данных, расчёт психологических шкал Big Five, кластеризация респондентов, анализ датасета настольных игр и визуализация временного ряда. Все этапы выполняются одним воспроизводимым скриптом; таблицы и графики сохраняются в отдельную папку.

## Описание данных

Основной входной файл (`data_5.csv`) содержит ответы респондентов по опроснику Big Five. Каждая из пяти шкал представлена 10 пунктами:

- **EXT** — экстраверсия (EXT1–EXT10)
- **EST** — эмоциональная стабильность (EST1–EST10)
- **AGR** — доброжелательность (AGR1–AGR10)
- **CSN** — добросовестность (CSN1–CSN10)
- **OPN** — открытость опыту (OPN1–OPN10)

Ответы по пунктам заданы в шкале 1–5. Файл в формате CSV с разделителем «;» и значениями в кавычках (экспорт из Excel с европейской локалью). Нули в пунктах при необходимости трактуются как пропуски для улучшения интерпретации кластеризации.

Дополнительные данные загружаются из внешних источников: рейтинги и описания настольных игр (TidyTuesday) и месячные данные по числу рождений в Нью-Йорке (1946–1959).

## Аналитический процесс

1. **Загрузка и предобработка данных** — чтение `data_5.csv`, осмотр структуры и пропусков, приведение столбцов шкал к числовому типу, выбор стратегии обработки нулей (как значение или как NA) по качеству k-means (silhouette).
2. **Расчёт шкал Big Five** — агрегация пунктов в средние по пяти шкалам для каждого респондента, средние по выборке, столбчатые диаграммы и ящики с усами.
3. **Кластеризация респондентов** — стандартизация пяти шкал, подбор числа кластеров методом локтя и по silhouette, k-means (k = 3), присвоение меток кластеров и визуализация профилей.
4. **Анализ датасета настольных игр** — объединение рейтингов и описаний по id игры, формирование переменных (например, среднее число игроков), корреляции с рейтингом, линейная регрессия, сохранение графиков и коэффициентов модели.
5. **Визуализация временного ряда** — загрузка месячных данных по рождаемости, построение ряда, статичный график и анимированный GIF с раскрытием ряда по времени.

## Используемые методы

- Описательная статистика и агрегация пунктов опросника в шкалы
- Обработка пропусков (нули как NA при необходимости)
- Кластеризация k-means по стандартизованным признакам
- Метод локтя (сумма квадратов внутри кластеров) для выбора k
- Анализ silhouette для оценки качества кластеров
- Корреляционный анализ и линейная регрессия (признаки игр и рейтинг)
- Представление временного ряда и анимированная визуализация (gganimate, gifski)

## Результаты

- **Шкалы Big Five** — для каждого респондента вычислены средние по шкалам (EXT, EST, AGR, CSN, OPN); по выборке получены средние и распределения, построены графики.
- **Группы респондентов** — выделены три кластера с разными профилями: один с более высокой эмоциональной стабильностью, другой с более высокими экстраверсией, доброжелательностью, добросовестностью и открытостью, третий с более низкими эмоциональной стабильностью и добросовестностью.
- **Настольные игры** — сохранены объединённый датасет и коэффициенты регрессии; рейтинг слабее связан с временем игры и числом игроков, несколько заметнее — с годом издания и минимальным возрастом.
- **Временной ряд рождаемости** — статичный график и анимация показывают месячную динамику числа рождений в Нью-Йорке (1946–1959), включая сезонность и тренд.

## Структура проекта

```
r_data_analysis_exam
│
├── solution.R
├── data_5.csv
├── README.md
├── outputs
│   ├── boardgames_merged.csv
│   ├── boardgames_model_coefficients.csv
│   ├── task2_bar_scale_means.png
│   ├── task2_boxplot_scales.png
│   ├── task3_scatter_*.png
│   ├── task4_elbow.png
│   ├── task4_silhouette.png
│   ├── task4_clusters_bars.png
│   ├── task4_cluster_means.csv
│   ├── task6_timeseries.png
│   └── task6_births_animation.gif
```

Папка `outputs` создаётся скриптом при отсутствии. Файлы PNG и GIF появляются после полного прогона; в репозитории могут быть только CSV, если скрипт выполнялся частично или без сохранения графики.

## Запуск проекта

1. Установите [R](https://www.r-project.org/) (при желании — [RStudio](https://www.rstudio.com/)).
2. Разместите `solution.R` и `data_5.csv` в одной папке и сделайте её рабочей директорией.
3. Откройте `solution.R` и выполните весь скрипт (например, через «Source» в RStudio). Для загрузки данных настольных игр и рождаемости нужен доступ в интернет.
4. Недостающие пакеты (`readr`, `ggplot2`, `tidyr`, `dplyr`, `cluster`, `gganimate`, `gifski`) при первом запуске устанавливаются из CRAN.
5. Результаты записываются в папку `outputs`.

## Используемые технологии

- R
- tidyverse (readr, tidyr, dplyr)
- ggplot2
- cluster (silhouette)
- gganimate
- gifski

## Автор

GitHub: [Saitama4722](https://github.com/Saitama4722)
