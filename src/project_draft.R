# ---
# title: "Reproducible Research 2021: Live analysis of betting odds for tennis matches"
# author:
# - "Rafał Rysiejko"
# - "Michał Sałach"
# date: "May 2021"
# output:
#  prettydoc::html_pretty:
#    theme: cayman
# params:
#  money:
#    label: "Money to bet"
#    value: 1000
#    min: 1
#  expected_return:
#    label: "Expected return, if the favourite wins (fraction of money to bet)"
#    value: 0.1
#    min: 0.01
#  adverse_return:
#    label: "Accepted return, if the favourite will not win (fraction of money to bet)"
#    value: -0.2
#    min: -1
# ---

#+ r setup, include = FALSE

#### Libraries ####
library(tidyverse)  # tidyverse 1.3.1

# Note: I use the function if_any() from dplyr 1.0.5, which was not included in some of the 
# earlier versions of the package.

#### Data ####

#data <- read_csv('data_060521_163644.csv') # Old Data
data <- read_csv('data_270521_001719.csv') # New data 27.05

#### Analysis ####

## (tymczasowe)
# Note: in general `x` in the code should be substituted with `params$x` for the parameters underneath,
# and the lines below should be deleted, but for now (for working in the script) they are useful.
money <- params$money
expected_return <- params$expected_return
adverse_return <- params$adverse_return

money <- 1000
expected_return <- 0.1
adverse_return <- -0.2

##

# A list of bookmakers
bookmakers <- c('eFortuna', 'STS', 'Betclic', 'Betfan', 'Pzbuk', 'Lvbet', 'Totolotek')

bookmakers_links <- c('https://www.efortuna.pl/',
                      'https://www.sts.pl/',
                      'https://www.betclic.pl/',
                      'https://betfan.pl/zaklady-bukmacherskie',
                      'https://www.pzbuk.pl/pl',
                      'https://lvbet.pl/pl/',
                      'https://www.totolotek.pl/pl')

bookmakers_df <- data.frame(bookmakers,bookmakers_links)

# Add a match identifier and a boolean for whether a match is ongoing, or future (it's the case
# when there is no data for games).
# Then transform data to long format (match-bookmaker-value in separate columns) and count max
# and min offers for both players in a match.

# Translate Polish tennis specific terms and countries name to english
dict <- read_csv('rafal/translation-20210524.csv')
for (i in 1:length(dict$pl)) {
  
  data$event <- as.data.frame(sapply(data$event,gsub,pattern=dict[i,]$pl,replacement=dict[i,]$angl))

}

data <- as.data.frame(do.call(cbind, data)) %>% rename(event=`sapply(data$event, gsub, pattern = dict[i, ]$pl, replacement = dict[i, ]$angl)`)
data <- data %>% mutate(gender = case_when(str_detect(event, "Womens") ~ "W",
                                     str_detect(event, "WTP") ~ "W",
                                     TRUE ~ "M"))


data <- data %>%
  mutate(match_id = row_number(), .before = event) %>%
  mutate(match_current = if_else(if_any(contains('_games'), function(x)
    is.na(x)),
    0, 1), .after = match_time) %>%
  pivot_longer(cols = (paste0('player_1_', bookmakers)),
               names_to = 'player_1_bookmaker',
               values_to = 'player_1_odds') %>%
  pivot_longer(cols = (paste0('player_2_', bookmakers)),
               names_to = 'player_2_bookmaker',
               values_to = 'player_2_odds') %>%
  mutate(
    player_1_bookmaker = str_replace(player_1_bookmaker, 'player_1_', ''),
    player_2_bookmaker = str_replace(player_2_bookmaker, 'player_2_', '')
  ) %>%
  group_by(match_id) %>%
  mutate(
    player_1_odds_max = max(player_1_odds, na.rm = TRUE),
    player_1_odds_min = min(player_1_odds, na.rm = TRUE),
    player_2_odds_max = max(player_2_odds, na.rm = TRUE),
    player_2_odds_min = min(player_2_odds, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(!(if_any(contains('_odds_'), function(x)
    is.infinite(x))))  # See the note below.

# Note: warnings signify that there are matches for which there is no offer (NAs for all
# bookmakers). It may happen that a future match has currently no betting odds, or that all 
# are crossed out by the bookmakers. We are not worried by that. The values of 
# `player_1_odds_max`, `player_1_odds_max`, `player_1_odds_max` and `player_1_odds_max` will be 
# then Inf/-Inf, and we filter them out.

# ---

#+ r min_adverse, include = FALSE

# Given the expected return ((1+expected_return)*money in the case when the favourite wins),
# count the adverse return (when the favourite loses). Filter out offers when potential loss
# exceeds the adverse return and sort descending.
# (Favourite is the player whose win guarantees expected return.)

data_min_adverse <- data %>%
  group_by(match_id) %>%
  mutate(to_bet_1_if_1_favourite = (1+expected_return)*money/player_1_odds_max,
         to_bet_2_if_1_favourite = money-to_bet_1_if_1_favourite,
         win_2_bet_1 = to_bet_2_if_1_favourite*player_2_odds_max,
         win_2_bet_1_return = (win_2_bet_1-money)/money,
         to_bet_2_if_2_favourite = (1+expected_return)*money/player_2_odds_max,
         to_bet_1_if_2_favourite = money-to_bet_2_if_2_favourite,
         win_1_bet_2 = to_bet_1_if_2_favourite*player_1_odds_max,
         win_1_bet_2_return = (win_1_bet_2-money)/money,
         better_adverse_return = max(win_2_bet_1_return, win_1_bet_2_return)) %>%
  ungroup() %>% 
  filter(player_1_odds == player_1_odds_max,
         player_2_odds == player_2_odds_max,
         better_adverse_return >= adverse_return,
         to_bet_1_if_1_favourite <= money,
         to_bet_1_if_2_favourite >= 0,
         to_bet_2_if_2_favourite <= money,
         to_bet_2_if_1_favourite >= 0) %>%
  mutate(better_favourite = if_else(win_1_bet_2 > win_2_bet_1, '2', '1'),
         better_non_favourite = if_else(better_favourite == '1', '2', '1')) %>% 
  arrange(desc(better_adverse_return))

#' Having `r money` PLN, the best bet to do right now in order to have `r 100*expected_return`% return 
#' in the case of a favourite win and minimal loss in the case of the favourite loss is to bet 
#' `r round(pull(data_min_adverse[paste0('to_bet_', data_min_adverse$better_favourite[1], '_if_', data_min_adverse$better_favourite[1], '_favourite')])[1], 2)` 
#' PLN on `r pull(data_min_adverse[paste0('player_', data_min_adverse$better_favourite[1])])[1]`
#' (`r pull(data_min_adverse[paste0('player_', data_min_adverse$better_favourite[1], '_nationality')])[1]`,
#' ATP ranking: `r pull(data_min_adverse[paste0('player_', data_min_adverse$better_favourite[1], '_rank')])[1]`)
#' on `r pull(data_min_adverse[paste0('player_', data_min_adverse$better_favourite[1], '_bookmaker')])[1]`
#' (betting odds: `r pull(data_min_adverse[paste0('player_', data_min_adverse$better_favourite[1], '_odds')])[1]`)
#' and `r round(pull(data_min_adverse[paste0('to_bet_', data_min_adverse$better_non_favourite[1], '_if_', data_min_adverse$better_favourite[1], '_favourite')])[1], 2)` 
#' PLN on `r pull(data_min_adverse[paste0('player_', data_min_adverse$better_non_favourite[1])])[1]`
#' (`r pull(data_min_adverse[paste0('player_', data_min_adverse$better_non_favourite[1], '_nationality')])[1]`,
#' ATP ranking: `r pull(data_min_adverse[paste0('player_', data_min_adverse$better_non_favourite[1], '_rank')])[1]`) 
#' on `r pull(data_min_adverse[paste0('player_', data_min_adverse$better_non_favourite[1], '_bookmaker')])[1]` 
#' (betting odds: `r pull(data_min_adverse[paste0('player_', data_min_adverse$better_non_favourite[1], '_odds')])[1]`, 
#' expected return: `r round(pull(data_min_adverse[paste0('win_', data_min_adverse$better_non_favourite[1], '_bet_', data_min_adverse$better_favourite[1])])[1], 2)` 
#' PLN, that is `r round(100*pull(data_min_adverse[paste0('win_', data_min_adverse$better_non_favourite[1], '_bet_', data_min_adverse$better_favourite[1], '_return')])[1], 2)`%) 
#' in `r pull(data_min_adverse['event'])[1]` (starting `r pull(data_min_adverse['match_time'])[1]`).

#+ r temporary_comment_1, include = FALSE

## dodać score, przetlumaczyć event i zrelatywizować treść w zależności od tego,
## czy mecz trwa (jeśli trwa, dodać aktualny wynik i kto serwuje). Dodać linki do bukmacherów.

# ---

#+ r max_return, include = FALSE

# Given the maximal accepted loss in the case when the favourite loses (adverse_return), 
# maximize the expected_return (return when the favourite wins).

data_max_return <- data %>%
  group_by(match_id) %>%
  mutate(to_bet_1_if_2_favourite = (1+adverse_return)*money/player_1_odds_max,
         to_bet_2_if_2_favourite = money-to_bet_1_if_2_favourite,
         to_bet_2_if_1_favourite = (1+adverse_return)*money/player_2_odds_max,         
         to_bet_1_if_1_favourite = money-to_bet_2_if_1_favourite,
         win_1_bet_1 = to_bet_1_if_1_favourite*player_1_odds_max,
         win_1_bet_1_return = (win_1_bet_1-money)/money,
         win_2_bet_2 = to_bet_2_if_2_favourite*player_2_odds_max,
         win_2_bet_2_return = (win_2_bet_2-money)/money,
         better_return = max(win_1_bet_1_return, win_2_bet_2_return)) %>% 
  ungroup() %>% 
  filter(player_1_odds == player_1_odds_max,
         player_2_odds == player_2_odds_max,
         better_return >= expected_return,
         to_bet_1_if_1_favourite <= money,
         to_bet_1_if_2_favourite >= 0,
         to_bet_2_if_2_favourite <= money,
         to_bet_2_if_1_favourite >= 0) %>%
  mutate(better_favourite = if_else(win_2_bet_2 > win_1_bet_1, '2', '1'),
         better_non_favourite = if_else(better_favourite == '1', '2', '1')) %>% 
  arrange(desc(better_return))

#' Having `r money` PLN, the best bet to do right now in order to have `r 100*adverse_return`% return 
#' in the case of a favourite loss and maximal return in the case of the favourite win is to bet 
#' `r round(pull(data_max_return[paste0('to_bet_', data_max_return$better_non_favourite[1], '_if_', data_max_return$better_favourite[1], '_favourite')])[1], 2)` 
#' PLN on `r pull(data_max_return[paste0('player_', data_max_return$better_non_favourite[1])])[1]`
#' (`r pull(data_max_return[paste0('player_', data_max_return$better_non_favourite[1], '_nationality')])[1]`,
#' ATP ranking: `r pull(data_max_return[paste0('player_', data_max_return$better_non_favourite[1], '_rank')])[1]`) 
#' on `r pull(data_max_return[paste0('player_', data_max_return$better_non_favourite[1], '_bookmaker')])[1]` 
#' (betting odds: `r pull(data_max_return[paste0('player_', data_max_return$better_non_favourite[1], '_odds')])[1]`, 
#' expected return: `r round(pull(data_max_return[paste0('win_', data_max_return$better_favourite[1], '_bet_', data_max_return$better_favourite[1])])[1], 2)` 
#' PLN, that is `r round(100*pull(data_max_return[paste0('win_', data_max_return$better_favourite[1], '_bet_', data_max_return$better_favourite[1], '_return')])[1], 2)`%) 
#' and `r round(pull(data_max_return[paste0('to_bet_', data_max_return$better_favourite[1], '_if_', data_max_return$better_favourite[1], '_favourite')])[1], 2)` 
#' PLN on `r pull(data_max_return[paste0('player_', data_max_return$better_favourite[1])])[1]`
#' (`r pull(data_max_return[paste0('player_', data_max_return$better_favourite[1], '_nationality')])[1]`,
#' ATP ranking: `r pull(data_max_return[paste0('player_', data_max_return$better_favourite[1], '_rank')])[1]`)
#' on `r pull(data_max_return[paste0('player_', data_max_return$better_favourite[1], '_bookmaker')])[1]`
#' (betting odds: `r pull(data_max_return[paste0('player_', data_max_return$better_favourite[1], '_odds')])[1]`)
#' in `r pull(data_max_return['event'])[1]` (starting `r pull(data_max_return['match_time'])[1]`).

#+ r temporary_comment_2, include = FALSE

## j.w.: dodać score, przetlumaczyć event i zrelatywizować treść w zależności od tego,
## czy mecz trwa (jeśli trwa, dodać aktualny wynik i kto serwuje). Dodać linki do bukmacherów.

## Jak widać w obu podejściach trafiamy na ten sam, aktualnie najlepszy, układ ofert. Czy tak
## będzie zawsze?

# ---

# Co dodać: 
# - tłumczenie zm. `event` (np. używając str_replace()) - a najlepiej rozbić zm `event` na typ wydarzenia
# (ATP, WTA, Challenger, inne), płać (men, women, mixed) i wydarzenie (tylko dla informacji, można spróbować
# przetłumaczyć); i ze zmiennymi `gender` i `event_type` też zrobić analizę. - done
# - dodać linki do stron bukmacherów w tekście - done
# - dodać disclaimer, że zakłady to hazard i 18+, a praca ma charakter badawczo-analityczny - done
# - na koniec połaczyć scraper w R i generator raportów

