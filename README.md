# RR_Project
Reproducible Research Summer 2021 classes Final Project - Automated reports based on live betting odds for tennis matches

## To do (analysis-report part):

1. Introduction

We serach for the most profitable bets to make on the tennis matches for a given moment. We consider
7 popular Polish bookmakers, whose betting odds are reported on an ongoing basis on [flashscore.pl/tennis](flashscore.pl/tennis).
We are interested in the end results only (who wins), and only in the matches that are ongoing or scheduled for a given day.
It may be safely assumed that each match will have a winner. It is also pretty always the case that for each match there is
a favourite of the bookmakers (the bookmakers do not have to be unanimous, or it may in principle happen that the the odds for
both players are the same - this does not cause a problem for our analysis). A favourite of a bookamaker in a given match is 
the player for whom offers are lower (closer to 1). Other than that, there is also a favourite of a client of the bookmaker - this is the
player, whose win would grant the client a profit. Given that in reality offers for both players are greater than 1, a client 
does not have to bet all their money on a favourite in order to achieve *some* profit. The remaining amount of money the client
would bet on a non-favourite as a form of insurance in the case of misfortune (favourite loses). A no-risk bet is therefore a bet
in which there is a proportion of money to bet, such that a client of a bookmaker has a profit also when their favourite loses.
For example in betting odds for a player A (the bookamaker's favourite) are 1.5 and for a player B are 3.5, a client may bet 700 PLN 
on a player A and 300 PLN on a player B, granting a win of 1050 PLN (5% profit) in both cases. Such bets rather do not happen in reality,
but the aim of the project is find the offers that come the closest to this, for any moment in time.

In our analysis we are looking for the best bets to make from two angles: minimizing loss and maximizing return. Hence, we use two
notions of profitability: in the first sense, we are interested in bets that would give a client minimal loss, having fixed on some level
expected return in the case of the client's favourite win. In the second sense, we are looking for bets that would
give a client maximal return in the case of thier favourites win, having fixed on some level the loss in the adverse case.

The report will therefore accept 3 meta-prameters: `money` (money to bet, defaul 1000 PLN), `expected_return` (defaul 0.1)
and `adverse_return` (default -0.2).

3. The report will tell a user:
- what is the best bet to make right now in order to achieve the expected return and minimise loss (what money to bet
on whom, in what proportions), all bookmakers (combinations) allowed;
- what is the best bet to make right now in the sense of maximizing the return, having loss fixed at the accepted level
- for all 7 bookmakers - the 2 abovementioned offers (so the best bets on eFortuna, STS, etc.), desirably sorted from the
best to the worst;
- "trade-off" plots showing how much adverse return (usually loss) one must accept, given that one want to ensure x % of return
in the case when the favourite wins. f(x) may be calculated for a couple of data points, for instance for `expected_return` equal 1%, 2%, 3%, 
4%, 5%, 10%, 15%, 20%, 25%, 30%, 40%, 50%. This should be done for the best odd(s) overally, and the best odds for particular bookmakers 
(perhaps a plot with 7 lines);
- the same "trade-off" plot can be used for the case show average odds and the worse odds;
- the same or similar plot should be made to illustrate whether there is a relation between profitability and:
 * whether the favourite of a client is the same or different as the favourite of a bookmaker
 * gender (male, female, mixed)
 * type of tournament (ATP, WTA, Challenger, other)
 * whether the match is ongoing or future
 * possibly also in connection to the current score, for ongoing matches.
- a hypothesis may also be considered: is the profitablity higher in case of close odds (no obvious candidate) or very distinct
odds?

4. The report may of course also include some macro statistics such as: how many matches are currently live, how many mathers are scheduled
for today, how many bookmakers offers' are listed for a match on averge, how many offers there are for all bookmakers.

**Note** that running our scaper on late hours is unlikely to produce any results, since there may be no more matches scheduled for that day and
no betting odds.
