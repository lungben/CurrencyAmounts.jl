[![Build Status](https://travis-ci.com/lungben/CurrencyAmounts.jl.svg?branch=master)](https://travis-ci.com/lungben/CurrencyAmounts.jl)
[![codecov](https://codecov.io/gh/lungben/CurrencyAmounts.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/lungben/CurrencyAmounts.jl)

# CurrencyAmounts

When working with currency amounts and exchange rates, it is very easy to do mistakes, e.g. summing up amounts in different currencies or applying an exchange rate for currency conversion in the wrong direction (what does 1.2 EURUSD mean again???).

This little package provides currency-aware data types for amounts and exchange rates, together with mathematical operations between them. These operations are intrinsically safe, operations which are mathematically invalid or produce non-currency or currency-pair results are not defined.

The currency (pair) information is encoded in the type system, therefore it has zero run-time cost (if type stable code is written).

## Usage

    @currencies USD, EUR, GBP, CHF # define currencies as constants in global scope

    4USD + 5.5USD # 9.5USD
    4USD + 3EUR # not allowed throws MethodError

    4USD * 2 # 8USD
    4USD*3USD # invalid because dimension Currency^2 usually does not make sense, MethodError

    rate_eur_usd = 1.2USD / 1EUR # define exchange rate
    3EUR * rate_eur_usd # 3.6USD
    3USD * rate_eur_usd # dimensions do not match, MethodError
    3USD / rate_eur_usd # 2.5EUR

## Related Packages

The following package provides similar functionality for currencies and currency amounts:

https://github.com/JuliaFinance/Currencies.jl

The main differences are:

* Currencies.jl is more general, it aims supporting general assets. This package focuses on currency amounts and exchange rates.
* Currencies.jl does not define exchange rates and mathematical operations between currency amounts and / or exchange rates (yet?).
