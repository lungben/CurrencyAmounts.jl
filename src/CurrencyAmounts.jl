module CurrencyAmounts

export Currency, CurrencyAmount, ExchangeRate, @currencies

import Base: +, -, *, /, ≈

"""
Currency type, e.g. EUR, USD.
"""
struct Currency{T} end

Currency(c:: Symbol) = Currency{c}()
Currency(c:: AbstractString) = Currency(Symbol(c))

Base.Broadcast.broadcastable(c:: Currency) = Ref(c) # treat it as a scalar in broadcasting
Base.show(io:: IO, c:: Currency{T}) where {T} = print(io, string(T))


"""
    @currencies(syms)

Creates one or more currency definitions, these are global constants of type `Currency{T}`.

Example:

    @currencies EUR, USD, GBP
    @currencies EUR

the latter is equivalent to

    const EUR = Currency(:EUR)

"""
macro currencies(syms)
    args = syms isa Expr ? syms.args : [syms]
    for nam in args
        ccy = CurrencyAmounts.Currency{nam}()
        @eval __module__ const $nam = $ccy
    end
end

"""
    CurrencyAmount(x:: Number, c:: Currency)

Amount of a specific currency, i.e. a combination of a numeric value and a currency type.

Examples:

    CurrencyAmount(100.5, EUR) # assumes `@currencies EUR` has been called before
    100.5EUR # equivalent constructor
"""
struct CurrencyAmount{T <: Number, C <: Currency}
    amount:: T
end

CurrencyAmount(x:: Number, ::C) where C <: Currency = CurrencyAmount{typeof(x), C}(x)

Base.Broadcast.broadcastable(c:: CurrencyAmount) = Ref(c) # treat it as a scalar in broadcasting
Base.show(io:: IO, c:: CurrencyAmount{<: Number, C}) where {C} = print(io, c.amount, " ", C())
≈(x:: CurrencyAmount{T1, C}, y:: CurrencyAmount{T2, C}) where {C <: Currency, T1 <: Number, T2 <: Number} = x.amount ≈ y.amount

# construction of CurrencyAmount using multiplication
*(x:: Number, c:: Currency) = CurrencyAmount(x, c)

## CurrencyAmount arithmetics

# Addition and subtraction are only defined between equal currencies
+(x:: CurrencyAmount{T1, C}, y:: CurrencyAmount{T2, C}) where {C <: Currency, T1 <: Number, T2 <: Number} = CurrencyAmount(x.amount + y.amount, C())
-(x:: CurrencyAmount{T1, C}, y:: CurrencyAmount{T2, C}) where {C <: Currency, T1 <: Number, T2 <: Number} = CurrencyAmount(x.amount - y.amount, C())
-(x:: CurrencyAmount{T1, C}) where {C <: Currency, T1 <: Number} = CurrencyAmount(-x.amount, C())

*(x:: CurrencyAmount{T1, C}, y:: Number) where {C <: Currency, T1 <: Number} = CurrencyAmount(x.amount * y, C())
*(x:: Number, y:: CurrencyAmount) = y*x

# only division of a CurrencyAmount by a scalar is defined, not vice versa because this would give dimension of 1/Currency.
/(x:: CurrencyAmount{T1, C}, y:: Number) where {C <: Currency, T1 <: Number} = CurrencyAmount(x.amount / y, C())

# division of 2 amounts with the same currency gives a dimensionless result
/(x:: CurrencyAmount{<: Number, C}, y:: CurrencyAmount{<: Number, C}) where {C <: Currency} = x.amount / y.amount


"""
    ExchangeRate(x:: Number, ::BaseCurrency, ::QuoteCurrency)

Exchange rate between two currencies.
"""
struct ExchangeRate{T <: Number, BaseCurrency <: Currency, QuoteCurrency <: Currency}
    rate:: T
    function ExchangeRate{T, C1, C2}(x) where {T, C1, C2}
        C1 == C2 && error("currencies must be different")
        x > 0 || error("exchange rate must be positive")
        new{T, C1, C2}(x)
    end
end

Base.Broadcast.broadcastable(c:: ExchangeRate) = Ref(c) # treat it as a scalar in broadcasting
Base.show(io:: IO, c:: ExchangeRate{<: Number, C1, C2}) where {C1, C2} = print(io, c.rate, " ", C2(), "/", C1())

## Exchange Rates
ExchangeRate(x:: Number, ::BaseCurrency, ::QuoteCurrency) where {BaseCurrency <: Currency, QuoteCurrency <: Currency} = ExchangeRate{typeof(x), BaseCurrency, QuoteCurrency}(x)

≈(x:: ExchangeRate{<: Number, C1, C2}, y:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = x.rate ≈ y.rate

# in a currency fraction, the QuoteCurrency is the numerator and the BaseCurrency the denominator
/(x:: CurrencyAmount{T1, C1}, y:: CurrencyAmount{T2, C2}) where {C1 <: Currency, C2 <: Currency, T1 <: Number, T2 <: Number} = ExchangeRate(x.amount/y.amount, C2(), C1())
/(x:: CurrencyAmount, y:: Currency) = x / CurrencyAmount(1, y) # allowing syntax 1.2EUR/USD

# exchange rate arithmetics
*(x:: ExchangeRate{T1, C1, C2}, y:: Number) where {C1 <: Currency, C2 <: Currency, T1 <: Number} = ExchangeRate(x.rate * y, C1(), C2())
*(x:: Number, y:: ExchangeRate) = y*x

/(x:: ExchangeRate{T1, C1, C2}, y:: Number) where {C1 <: Currency, C2 <: Currency, T1 <: Number} = ExchangeRate(x.rate / y, C1(), C2())
/(y:: Number, x:: ExchangeRate{T1, C1, C2}) where {C1 <: Currency, C2 <: Currency, T1 <: Number} = ExchangeRate(y / x.rate, C2(), C1())
+(x:: ExchangeRate{<: Number, C1, C2}, y:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = ExchangeRate(x.rate + y.rate, C1(), C2())
-(x:: ExchangeRate{<: Number, C1, C2}, y:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = ExchangeRate(x.rate - y.rate, C1(), C2())

## currency conversions

# conversions using arithmetics
*(x:: CurrencyAmount{<: Number, C1}, y:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = CurrencyAmount(x.amount * y.rate, C2())
*(x:: ExchangeRate, y:: CurrencyAmount) = y*x

/(x:: CurrencyAmount{<: Number, C2}, y:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = CurrencyAmount(x.amount / y.rate, C1())

# explicit "smart" conversions

"""
   convert(target_currency:: Currency, amount:: CurrencyAmount, exchange_rate:: ExchangeRate):: CurrencyAmount
   
Converts the amount` to target currency using the given `exchange_rate`. If a conversion is not possible using this exchange rate, `missing` is returned.
"""
Base.convert(:: C2, amount:: CurrencyAmount{<: Number, C1}, rate:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = amount * rate
Base.convert(:: C1, amount:: CurrencyAmount{<: Number, C2}, rate:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = amount / rate
Base.convert(:: C1, amount:: CurrencyAmount{<: Number, C1}, :: ExchangeRate) where {C1 <: Currency} = amount # source and target currency are equal, do nothing
Base.convert(::Currency, ::CurrencyAmount, ::ExchangeRate) = missing


"""
   convert(target_currency:: Currency, amount:: CurrencyAmount, exchange_rate_iterable):: CurrencyAmount
   
Converts the amount` to target currency using one of the given rates in the `exchange_rate_iterable`. If a conversion is not possible using one of the exchange rate, `missing` is returned.
"""
function Base.convert(:: C1, amount:: CurrencyAmount{<: Number, C2}, itr) where {C1 <: Currency, C2 <: Currency}
    for exchange_rate in itr
        exchange_rate isa ExchangeRate || error("iterable must contain exchange rates")
        res = convert(C1(), amount, exchange_rate)
        if !ismissing(res)
            return res
        end
    end
    return missing
end

end
