setwd('C:/Users/salac/Desktop/Reproducible Research/RR_Project')

#### Libraries ####

library(tidyverse)  # tidyverse 1.3.1

# Note: I use the function if_any() from dplyr 1.0.5, which was not included in some of the 
# earlier versions of the package.

#### Data ####

data <- read_csv('data_290421_100301.csv')

#### Analysis ####

# Sum of money to bet
money <- 1000

# Expected return, if the favourite wins (% of money to bet)
expected_return <- .1

# Accepted return, if the favourite will not win (% of money to bet)
adverse_return <- -.2

# A list of bookmakers
bookmakers <- c('eFortuna', 'STS', 'Betclic', 'Betfan', 'Pzbuk', 'Lvbet', 'Totolotek')

# bookmakers_links <- c()  # dodać!

# Add a match identifier and a boolean for whether a match is ongoing, or future (it's the case
# when there is no data for games).
# Then transform data to long format (match-bookmaker-value in separate columns) and count max
# and min offers for both players in a match.

data <- data %>%
  mutate(match_id = row_number(), .before = event) %>% 
  mutate(match_current = if_else(if_any(contains('_games'), function(x) is.na(x)),
                                 0, 1), .after = match_time) %>% 
  pivot_longer(cols = (paste0('player_1_', bookmakers)), names_to = 'player_1_bookmaker',
                       values_to = 'player_1_odds') %>% 
  pivot_longer(cols = (paste0('player_2_', bookmakers)), names_to = 'player_2_bookmaker',
               values_to = 'player_2_odds') %>% 
  mutate(player_1_bookmaker = str_replace(player_1_bookmaker, 'player_1_', ''),
         player_2_bookmaker = str_replace(player_2_bookmaker, 'player_2_', '')) %>% 
  group_by(match_id) %>% 
  mutate(player_1_odds_max = max(player_1_odds, na.rm = TRUE),
         player_1_odds_min = min(player_1_odds, na.rm = TRUE),    
         player_2_odds_max = max(player_2_odds, na.rm = TRUE),  
         player_2_odds_min = min(player_2_odds, na.rm = TRUE)) %>% 
  ungroup() %>% 
  filter(!(if_any(contains('_odds_'), function(x) is.infinite(x))))  # See the note below.

# Note: warnings signify that there are matches for which there is no offer (NAs for all
# bookmakers). It may happen that a future match has currently no betting odds, or that all 
# are crossed out by the bookmakers. We are not worried by that. The values of 
# `player_1_odds_max`, `player_1_odds_max`, `player_1_odds_max` and `player_1_odds_max` will be 
# then Inf/-Inf, and we filter them out.

# ---
  
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

cat('Having ', money, ' PLN, the best bet to do right now in order to have ', 
    100*expected_return, '% return in the case of a favourite win and minimal loss in 
    the case of the favourite loss (given the minimal accepted return from the adverse scenario
    of ', 100*adverse_return, '%), is to bet ', 
    round(pull(data_min_adverse[paste0('to_bet_', data_min_adverse$better_favourite[1], '_if_',
                            data_min_adverse$better_favourite[1], '_favourite')])[1], 2),
    ' PLN on ',
    pull(data_min_adverse[paste0('player_', data_min_adverse$better_favourite[1])])[1], ' (',
    pull(data_min_adverse[paste0('player_', data_min_adverse$better_favourite[1], 
                                 '_nationality')])[1], '., ATP ranking: ',
    pull(data_min_adverse[paste0('player_', data_min_adverse$better_favourite[1], 
                                 '_rank')])[1],  
    ') on ', 
    pull(data_min_adverse[paste0('player_', data_min_adverse$better_favourite[1], 
                                 '_bookmaker')])[1], ' (betting odds: ',
    pull(data_min_adverse[paste0('player_', data_min_adverse$better_favourite[1],
                                 '_odds')])[1], ') and ',
    round(pull(data_min_adverse[paste0('to_bet_', data_min_adverse$better_non_favourite[1], '_if_',
                                       data_min_adverse$better_favourite[1], '_favourite')])[1], 2),
    ' PLN on ',
    pull(data_min_adverse[paste0('player_', data_min_adverse$better_non_favourite[1])])[1], ' (',
    pull(data_min_adverse[paste0('player_', data_min_adverse$better_non_favourite[1], 
                                 '_nationality')])[1], '., ATP ranking: ',
    pull(data_min_adverse[paste0('player_', data_min_adverse$better_non_favourite[1], 
                                 '_rank')])[1], ') on ',
    pull(data_min_adverse[paste0('player_', data_min_adverse$better_non_favourite[1], 
                                 '_bookmaker')])[1], ' (betting odds: ',
    pull(data_min_adverse[paste0('player_', data_min_adverse$better_non_favourite[1],
                                 '_odds')])[1], ', expected return: ',
    round(pull(data_min_adverse[paste0('win_', data_min_adverse$better_non_favourite[1],
                                 '_bet_', data_min_adverse$better_favourite[1])])[1], 2),  
    ' PLN, that is ',
    round(100*pull(data_min_adverse[paste0('win_', data_min_adverse$better_non_favourite[1],
                                 '_bet_', data_min_adverse$better_favourite[1], '_return')])[1], 2),
    '%) in ',
    pull(data_min_adverse['event'])[1], ' (starting ',
    pull(data_min_adverse['match_time'])[1], ').',
    sep = '')  
    # dodać score, przetlumaczyć event i zrelatywizować treść w zależności od tego,
    # czy mecz trwa

# ---

# Given the maximal accepted loss in the case when the favourite loses (adverse_return), 
# maximize the expected_return (return when the favourite wins).

# data_max_return <-

# Co dodać: 
# - tłumczenie zm. `event` (np. używając str_replace())
# - linki do stron bukmacherów w tekście; tu albo w scraperze
