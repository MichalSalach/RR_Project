#### Libraries ####

library(tidyverse)   # 1.3.1
library(httr)        # 1.4.2
library(rvest)       # 1.0.0
library(lubridate)   # 1.7.10
library(jsonlite)    # 1.7.2
library(eList)       # 0.2.0

#### Scraping live betting odds from flashscore.pl/tenis ####

# Prepare a data frame
data <- data.frame(event = character(), 
                   match_time = character(),
                   player_1 = character(), 
                   player_2 = character(),
                   player_1_score_sets = integer(),
                   player_1_score_games = character(),
                   player_1_score_points = character(),
                   player_2_score_sets = integer(),
                   player_2_score_games = character(),
                   player_2_score_points = character(), 
                   serving = character(),
                   player_1_nationality = character(), 
                   player_2_nationality = character(),
                   player_1_rank = character(),
                   player_2_rank = character(),
                   player_1_link = character(),
                   player_2_link = character(),
                   player_1_eFortuna = double(),
                   player_2_eFortuna = double(),
                   player_1_STS = double(),
                   player_2_STS = double(),
                   player_1_Betclic = double(),
                   player_2_Betclic = double(),
                   player_1_Betfan = double(),
                   player_2_Betfan = double(),
                   player_1_Pzbuk = double(),
                   player_2_Pzbuk = double(),
                   player_1_Lvbet = double(),
                   player_2_Lvbet = double(),
                   player_1_Totolotek = double(),
                   player_2_Totolotek = double(),
                   stringsAsFactors = FALSE)

# Retrieve data file for the main page for today's matches, including current scores
headers = c('Accept' = '*/*',
            'Accept-Encoding' = 'gzip, deflate, br',
            'Accept-Language' = 'pl,en-US;q=0.7,en;q=0.3',
            'Connection' = 'keep-alive',
            'Host' = 'd.flashscore.pl',
            'Referer' = 'https://d.flashscore.pl/x/feed/proxy-fetch',
            'TE' = 'Trailers',
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0',
            'x-fsign' = 'SW9D1eZo')

main_page <- GET('https://d.flashscore.pl/x/feed/f_2_0_2_pl_1',
                 add_headers(.headers = headers))

# Split the data for the matches (Note: the 1st element of `matches` will not be a match, but we do not 
# worry, because this element will be filtered out in the next step.)
matches <- str_split(content(main_page), '¬~AA÷', simplify = TRUE)

# It seems that that the ended/cancelled/interrupted matches contain the tag '¬AB÷3', the current ones - 
# '¬AB÷2', and the future ones - '¬AB÷1'. We will keep only those matches, for which there are active/
# future bets.
matches <- matches[str_detect(matches, '¬AB÷1') | str_detect(matches, '¬AB÷2')]

for (match in matches){
  
  # Create the result vector
  new_row <- {}
  # And also create a vector for the sake of conveniently catching errors
  new_row_error <- {}
  
  # Retrieve match ID that will be used for retriving detailed information for the match (betting odds)
  match_id <- str_extract(match, '.*?¬AD÷') %>% 
    str_sub(1, -5)
  
  url <- paste0('https://www.flashscore.pl/mecz/', match_id, '/#zestawienie-kursow/home-away/koniec-meczu')
  
  # Retrieve match time
  new_row['match_time'] <- str_extract(match, '¬AD÷.*?¬ADE÷') %>% 
    str_sub(5, -6) %>% 
    as.numeric() %>% 
    as_datetime(tz = 'Europe/Warsaw') %>% 
    toString()
  
  # Retrieve current match score from the file (if match not started, NA is returned) 
  # and strip the score from unnecesary symbols 
  player_1_score <- str_extract(match, '¬AG÷.*?¬OA÷') %>% 
    str_sub(5, -5)
  
  player_2_score <- str_extract(match, '¬AH÷.*?¬OB÷') %>% 
    str_sub(5, -5)
  
  # Split it into sets, games and points
  if (!is.na(player_1_score)){
    
    # (Possibly remove the part of the score accounting for tie-break points.)
    player_1_score <- str_replace(player_1_score, '¬D.÷\\d+', '')
    player_1_score <- str_split(player_1_score, '¬.*?÷', simplify = TRUE)
    new_row['player_1_score_sets'] <- player_1_score[1]
    new_row['player_1_score_games'] <- paste(player_1_score[2:(length(player_1_score)-1)], collapse = ' ')
    new_row['player_1_score_points'] <- last(player_1_score)
    
  } else {
    
    new_row['player_1_score_sets'] <- 0
    new_row['player_1_score_games'] <- ''
    new_row['player_1_score_points'] <- ''
  }
  
  # The same for player 2
  if (!is.na(player_2_score)){
    
    player_2_score <- str_replace(player_2_score, '¬D.÷\\d+', '')
    player_2_score <- str_split(player_2_score, '¬.*?÷', simplify = TRUE)
    new_row['player_2_score_sets'] <- player_2_score[1]
    new_row['player_2_score_games'] <- paste(player_2_score[2:(length(player_2_score)-1)], collapse = ' ')
    new_row['player_2_score_points'] <- last(player_2_score)
    
  } else {
    
    new_row['player_2_score_sets'] <- 0
    new_row['player_2_score_games'] <- ''
    new_row['player_2_score_points'] <- ''
  }
  
  # Retrieve information on who is serving right now. It seems that '¬WC÷1' signifies that it is the 1st 
  # player, and '¬WC÷2' - the 2nd player.
  if (str_detect(match, '¬WC÷1')){
    new_row['serving'] <- 'player_1'
    } else if (str_detect(match, '¬WC÷2')){
      new_row['serving'] <- 'player_2'
    } else new_row['serving'] <- NA

  new_row_error <- tryCatch({
    
    match_page <- read_html(url)

    # Retrieve the event title from the the match's site
    new_row['event'] <- html_attr(html_elements(match_page, 'meta')[6], 'content')
    
    # Retrieve players' names
    players <- html_attr(html_elements(match_page, 'meta')[5], 'content') %>% 
      str_split(' - ', simplify = TRUE)
    new_row['player_1'] <- players[1]
    new_row['player_2'] <- players[2] 

    # Retrieve a JS part containing some details on the players
    details <- html_text2(html_elements(match_page, 'script')[2]) %>% 
      str_sub(22, -2) %>% 
      fromJSON(flatten = TRUE)
    
    details_player_1 <- details$participantsData$home
    details_player_2 <- details$participantsData$away

    # Retrieve players' nationality
    # In the case of doubles, seprate the information by ' / '.
    
    new_row['player_1_nationality'] <- Paste(for (player in details_player_1$country) if 
                                             (!is_empty(player)) player else '', 
                                             collapse = ' / ')
    new_row['player_2_nationality'] <- Paste(for (player in details_player_2$country) if 
                                             (!is_empty(player)) player else '', 
                                             collapse = ' / ')
    
    # Retrieve players' rankings
    # In the case of doubles, seprate the information by ' / '.
    new_row['player_1_rank'] <- Paste(for (player in details_player_1$rank) if 
                                      (!is_empty(unlist(player))) unlist(player)[2] else '', 
                                      collapse = ' / ')
    new_row['player_2_rank'] <- Paste(for (player in details_player_2$rank) if 
                                      (!is_empty(unlist(player))) unlist(player)[2] else '', 
                                      collapse = ' / ')
    
    # Retrieve links to players' pages on flashscore.pl
    # In the case of doubles, seprate the information by ' / '.
    new_row['player_1_link'] <- Paste(for (player in details_player_1$detail_link) if (!is_empty(player)) 
      str_replace_all(player, '/zawodnik/', 'https://www.flashscore.pl/zawodnik/') else '', 
                                      collapse = ' / ')
    new_row['player_2_link'] <- Paste(for (player in details_player_2$detail_link) if (!is_empty(player)) 
      str_replace_all(player, '/zawodnik/', 'https://www.flashscore.pl/zawodnik/') else '', 
                                      collapse = ' / ')
    
    # In case of no error, it will be convenient to escape tryCatch function this way
    return(0)
    
  }, error = function(e) {
    new_row['event'] = NA
    # In case of failure, we can use another method of retrieving players' names and natialities, 
    # not using the match_page, but the main_page instead.
    details_player_1 <- str_extract(match, '¬AE÷.*?¬JA÷') %>% 
      str_split(' \\(', simplify = TRUE)
    details_player_2 <- str_extract(match, '¬AF÷.*?¬JB÷') %>% 
      str_split(' \\(', simplify = TRUE)
    new_row['player_1'] <- str_sub(details_player_1[1], 5)
    new_row['player_1_nationality'] <- str_sub(details_player_1[2], 1, -6)
    new_row['player_2'] <- str_sub(details_player_2[1], 5)
    new_row['player_2_nationality'] <- str_sub(details_player_2[2], 1, -6)
    new_row['player_1_rank'] <- NA
    new_row['player_2_rank'] <- NA
    new_row['player_1_link'] <- NA
    new_row['player_2_link'] <- NA
    
    return(new_row)
  })
  
  # If an error occured, assign the result of the tryCatch function to the new_row variable
  if (length(new_row_error) > length(new_row)) new_row <- new_row_error; new_row_error <- {}
  
  new_row_error <- tryCatch({
    
    # Retrieve a file including betting odds from the match's site
    match_odds <- GET(paste0('https://d.flashscore.pl/x/feed/df_od_1_', match_id), 
                      add_headers(.headers = headers))
    
    # Retrieve the part of data including end of match betting odds
    match_odds <- match_odds %>% 
      content() %>% 
      str_extract('(home-away).*?(Set 1)')
    
    # In R, if the retrieved file were empty, this section would evaluate further ending up with
    # NULL (not NA) values for betting odds, causing an error in apending the new row to the data frame.
    # Therefore we want to raise an error in this case and jump to the error-handiling part. In Python
    # version of the scaper, it is not needed.
    # if (is_empty(match_odds)) stop()
    
    # It seems that invalid (crossed-out) odds are those that end up with '¬OG÷0', and the valid ones
    # end up with '¬OG÷1'.
    valid_odds <- match_odds %>% 
      str_extract_all('¬OD÷.*?¬OG÷.', simplify = TRUE) %>%
      str_subset('1$') %>% 
      paste(collapse = '')
    
    # Retrieve the lists of the bookmakers' names and the odds, then strip from unnecessary symbols.
    # Split on the last change of the odds and take the last value.
    bookmakers <- valid_odds %>% 
      str_extract_all('¬OD.*?¬OPI', simplify = TRUE) %>% 
      str_sub(5, -5)
    
    player_1_odds <-  valid_odds %>% 
      str_extract_all('¬XB÷.*?¬XC', simplify = TRUE) %>% 
      str_sub(5, -4)
    
    player_2_odds <-  valid_odds %>% 
      str_extract_all('¬XC÷.*?¬OG', simplify = TRUE) %>% 
      str_sub(5, -4)
    
    player_1_odds <- Vec(for (o in player_1_odds) last(str_split(o, '\\[.\\]', simplify = TRUE)), 
                         drop.names = TRUE)
    
    player_2_odds <- Vec(for (o in player_2_odds) last(str_split(o, '\\[.\\]', simplify = TRUE)), 
                         drop.names = TRUE)
    
    # Assign betting odds for 7 possible bookmakers, for both players.
    # (Regex is used to produce an appropriate form of a variable (column name).)
    for (bookmaker in c('eFortuna.pl', 'STS.pl', 'Betclic.pl', 'Betfan.pl',
                        'Lvbet.pl', 'Pzbukpl', 'Totolotek.pl')){
      
      new_row[paste0('player_1_', str_extract(bookmaker, '\\w*(?=[\\.p])'))] <-
        player_1_odds[match(bookmaker, bookmakers)]
      new_row[paste0('player_2_', str_extract(bookmaker, '\\w*(?=[\\.p])'))] <-
        player_2_odds[match(bookmaker, bookmakers)]
    }
    
    return(0)
    
  }, error = function(e){
    
    for (bookmaker in c('eFortuna.pl', 'STS.pl', 'Betclic.pl', 'Betfan.pl',
                        'Lvbet.pl', 'Pzbukpl', 'Totolotek.pl')){
      
      new_row[paste0('player_1_', str_extract(bookmaker, '\\w*(?=[\\.p])'))] <- NA
      new_row[paste0('player_2_', str_extract(bookmaker, '\\w*(?=[\\.p])'))] <- NA
    }
    return(new_row)
  })
  
  # If an error occured, assign the result of the tryCatch function to the new_row variable
  if (length(new_row_error) > length(new_row)) new_row <- new_row_error
  
  # Append the new row to the data frame
  data <- rbind(data, as.data.frame(t(new_row)))
  
}

scraping_time <- now()
scraping_time <- format(scraping_time, '%d%m%y_%H%M%S')

# If one wants to export the data...
write_csv(data, paste0('data_', scraping_time, '.csv'))

# And later import it...
# data <- read_csv('data_040521_190955.csv')

# The data should be identical as that scraped with Python, perhaps the date-time column will require
# turning to string, in order to be displyed correctly on page.
