### A plot for what offers there are on average (all bookmakers) for bookmakers' favourites
### and non-favourites vs. whether a match is ongoing or future

data %>%
  rowwise() %>% 
  mutate(bookmakers_favourite_odds = if_else(player_1_odds < player_2_odds, player_1_odds, player_2_odds),
         bookmakers_non_favourite_odds = if_else(player_1_odds < player_2_odds, player_2_odds, player_1_odds)) %>%
  select(match_id, match_current, bookmakers_favourite_odds, bookmakers_non_favourite_odds) %>% 
  group_by(match_id) %>% 
  mutate(favourite = mean(bookmakers_favourite_odds, na.rm = TRUE),
         non_favourite = mean(bookmakers_non_favourite_odds, na.rm = TRUE)) %>% 
  slice_head(n = 1) %>% 
  ungroup() %>% 
  pivot_longer(cols = c(favourite, non_favourite), values_to = 'odds',
               names_to = 'is_bookmakers_favourite') %>%
  select(-c(bookmakers_favourite_odds, bookmakers_non_favourite_odds)) %>% 
  group_by(match_current) %>% 
  mutate(no_matches = dplyr::n()) %>% 
  ungroup() %>% 
  group_by(match_current, is_bookmakers_favourite) %>% 
  mutate(odds = mean(odds, na.rm = TRUE)) %>% 
  slice_head(n = 1) %>% 
  ggplot(aes(x = odds, y = is_bookmakers_favourite, fill = as.factor(no_matches))) +
  geom_col() +
  coord_flip() +
  labs(y = '', 
       title = "Average offers: bookmakers' favourites vs non-favourites\nand ongoing matches vs future ones",
       fill = 'maches') +
  scale_x_continuous(breaks = function(x) seq(0, ceiling(x[2]), .5)) +
  facet_wrap(~ match_current, labeller = as_labeller(c(`0` = 'future', `1` = 'ongoing'))) +
  theme(legend.position = c(0.5, 2)) +
  theme_minimal()

### Boxplots for betting odds - separately for bookmakers' favourites and non-favourites

data %>%
  rowwise() %>% 
  mutate(bookmakers_favourite_odds = if_else(player_1_odds < player_2_odds, player_1_odds, player_2_odds),
         bookmakers_non_favourite_odds = if_else(player_1_odds < player_2_odds, player_2_odds, player_1_odds)) %>%
  select(match_id, bookmakers_favourite_odds, bookmakers_non_favourite_odds) %>% 
  distinct(bookmakers_favourite_odds, bookmakers_non_favourite_odds) %>% 
  pivot_longer(cols = c(bookmakers_favourite_odds, bookmakers_non_favourite_odds), values_to = 'odds',
               names_to = 'is_bookmakers_favourite') %>%
  mutate(is_bookmakers_favourite = fct_recode(is_bookmakers_favourite, 'favourite' = 'bookmakers_favourite_odds',
                                              'non_favourite' = 'bookmakers_non_favourite_odds')) %>% 
  ggplot(aes(x = is_bookmakers_favourite, y = odds)) +
  geom_boxplot(color = 'black') +
  geom_jitter(aes(color = is_bookmakers_favourite), width = .25, alpha = .25, show.legend = FALSE) +
  labs(title = "Bookmakers' offers distribution for favourites\nand non-favourites",
       x = '') +
  scale_y_continuous(breaks = function(x) seq(0, ceiling(x[2]), .5)) +
  theme_minimal()
