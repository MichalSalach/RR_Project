# Reproducible Research 2021: Live analysis of betting odds for tennis matches

## Introduction

The goal of the project is to search for the most profitable bets to make on the tennis matches for a given moment. 
We consider 7 popular Polish bookmakers ([eFortuna](https://www.efortuna.pl/), [STS](https://www.sts.pl/), [Betclic](https://www.betclic.pl/), 
[Betfan](https://betfan.pl/zaklady-bukmacherskie), [Pzbuk](https://www.pzbuk.pl/pl), [Lvbet](https://lvbet.pl/pl/) and 
[Totolotek](https://www.totolotek.pl/pl)), whose betting odds are reported on an ongoing basis on [flashscore.pl/tennis](flashscore.pl/tennis). 
We are interested in the end results only (who wins), and only in the matches that are ongoing or scheduled for a given day. It may be safely assumed 
that each match will have a winner. It is also pretty always the case that for each match there is a favourite of the bookmakers (the bookmakers do not 
have to be unanimous, or it may in principle happen that the the odds for both players are the same - this does not cause a problem for our analysis). 
A favourite of a bookamaker in a given match is the player for whom offers are lower (closer to 1). Other than that, there is also a favourite of a client 
of the bookmaker - this is the player, whose win would grant the client a profit. Given that in reality offers for both players are greater than 1, a client 
does not have to bet all their money on a favourite in order to achieve some profit. The remaining amount of money the client would bet on a non-favourite as a 
form of insurance in the case of misfortune (favourite loses). A no-risk bet is therefore a bet in which there is a proportion of money to bet, such that a 
client of a bookmaker has a profit also when their favourite loses. For example in betting odds for a player A (the bookamaker's favourite) are 1.5 and for a 
player B are 3.5, a client may bet 700 PLN on a player A and 300 PLN on a player B, granting a win of 1050 PLN (5% profit) in both cases. Such bets rather do 
not happen in reality, but the aim of the project is find the offers that come the closest to this, for any moment in time.

In our analysis we are looking for the best bets to make from two angles: minimizing loss and maximizing return. Hence, we use two notions of 
profitability: in the first sense, we are interested in bets that would give a client minimal loss, having fixed on some level expected return 
in the case of the client's favourite win. In the second sense, we are looking for bets that would give a client maximal return in the case of 
thier favourites win, having fixed on some level the loss in the adverse case.

The report will therefore accept 3 meta-prameters: *money* (money to bet, default 1000 PLN), *expected_return* (default 0.1) and *adverse_return* 
(default -0.2).

## User's Guide
1. Clone repository to your local storage.
2. Open project using RR_Project.rproject file.
3. Run the Scraping_flashscore_tennis_R.R or Scraping_flashscore_tennis.ipynb (faster) file from the *src* folder.  Scrapped data file with its timestamp 
will be available in the *data* folder.
4. The most recent data will be used to create report by default. If you wish to create a report for past data, please specify the data file in 
the line 82 of the report.Rmd file.
5. Open file run.R from the *src* folder.
6. Load the function render_report.
7. You may specify own parameters: `money to bet`, `expected return` and `adverse return`.
8. Run the function with specified parameters.
10. Generated a html report with its timestamp will be in folder *report*. 

In the repository you shuold curently find some data files scraped on June 3, 2021 (in the *data* folder), as well a report generated for that data
(in the *report* folder). In the *data* folder you should find the file *translation.csv*, which is used by *report.Rmd* to translate some proper names
occuring in the tennis events' names from Polish to English. 

**Please note**  that running our scaper on late hours is unlikely to produce any results, since there may be no more matches scheduled for that day and no betting odds.

