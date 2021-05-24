---
title: "Reproducible Research 2021: Live analysis of betting odds for tennis matches"
author:
- "Rafal Rysiejko"
- "Michal Salach"
date: "May 2021"
output:
 prettydoc::html_pretty:
   theme: cayman
params:
 money:
   label: "Money to bet"
   value: 1000
   min: 1
 expected_return:
   label: "Expected return, if the favourite wins (fraction of money to bet)"
   value: 0.1
   min: 0.01
 adverse_return:
   label: "Accepted return, if the favourite will not win (fraction of money to bet)"
   value: -0.2
   min: -1
---



## Including Plots

You can also embed plots, for example:



