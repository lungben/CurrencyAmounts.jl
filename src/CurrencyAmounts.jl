module CurrencyAmounts

export Currency, CurrencyAmount, ExchangeRate

import Base: +, -, *, /, ≈

struct Currency{T} end
Currency(c:: AbstractString) = Currency{Symbol(uppercase(c))}()

Base.Broadcast.broadcastable(c:: Currency) = Ref(c) # treat it as a scalar in broadcasting

struct CurrencyAmount{T <: Number, C <: Currency}
    amount:: T
end

CurrencyAmount(x:: Number, ::C) where C <: Currency = CurrencyAmount{typeof(x), C}(x)

Base.Broadcast.broadcastable(c:: CurrencyAmount) = Ref(c) # treat it as a scalar in broadcasting
≈(x:: CurrencyAmount{T1, C}, y:: CurrencyAmount{T2, C}) where {C <: Currency, T1 <: Number, T2 <: Number} = x.amount ≈ y.amount

# construction of CurrencyAmount using multiplication
*(x:: Number, c:: Currency) = CurrencyAmount(x, c)

## CurrencyAmount arithmetics

# Addition and subtraction are only defined between equal currencies
+(x:: CurrencyAmount{T1, C}, y:: CurrencyAmount{T2, C}) where {C <: Currency, T1 <: Number, T2 <: Number} = CurrencyAmount(x.amount + y.amount, C())
-(x:: CurrencyAmount{T1, C}, y:: CurrencyAmount{T2, C}) where {C <: Currency, T1 <: Number, T2 <: Number} = CurrencyAmount(x.amount - y.amount, C())

*(x:: CurrencyAmount{T1, C}, y:: Number) where {C <: Currency, T1 <: Number} = CurrencyAmount(x.amount * y, C())
*(x:: Number, y:: CurrencyAmount) = y*x

# only division of a CurrencyAmount by a scalar is defined, not vice versa because this would give dimension of 1/Currency.
/(x:: CurrencyAmount{T1, C}, y:: Number) where {C <: Currency, T1 <: Number} = CurrencyAmount(x.amount / y, C())

struct ExchangeRate{T <: Number, BaseCurrency <: Currency, QuoteCurrency <: Currency}
    rate:: T
end

Base.Broadcast.broadcastable(c:: ExchangeRate) = Ref(c) # treat it as a scalar in broadcasting

## Exchange Rates
ExchangeRate(x:: Number, ::BaseCurrency, ::QuoteCurrency) where {BaseCurrency <: Currency, QuoteCurrency <: Currency} = ExchangeRate{typeof(x), BaseCurrency, QuoteCurrency}(x)

≈(x:: ExchangeRate{<: Number, C1, C2}, y:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = x.rate ≈ y.rate

# in a currency fraction, the QuoteCurrency is the numerator and the BaseCurrency the denominator
/(x:: CurrencyAmount{T1, C1}, y:: CurrencyAmount{T2, C2}) where {C1 <: Currency, C2 <: Currency, T1 <: Number, T2 <: Number} = ExchangeRate(x.amount/y.amount, C2(), C1())

# exchange rate arithmetics
*(x:: ExchangeRate{T1, C1, C2}, y:: Number) where {C1 <: Currency, C2 <: Currency, T1 <: Number} = ExchangeRate(x.rate * y, C1(), C2())
*(x:: Number, y:: ExchangeRate) = y*x

/(x:: ExchangeRate{T1, C1, C2}, y:: Number) where {C1 <: Currency, C2 <: Currency, T1 <: Number} = ExchangeRate(x.rate / y, C1(), C2())
/(y:: Number, x:: ExchangeRate{T1, C1, C2}) where {C1 <: Currency, C2 <: Currency, T1 <: Number} = ExchangeRate(y / x.rate, C2(), C1())
+(x:: ExchangeRate{<: Number, C1, C2}, y:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = ExchangeRate(x.rate + y.rate, C1(), C2())
-(x:: ExchangeRate{<: Number, C1, C2}, y:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = ExchangeRate(x.rate - y.rate, C1(), C2())

# currency conversions

*(x:: CurrencyAmount{<: Number, C1}, y:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = CurrencyAmount(x.amount * y.rate, C2())
*(x:: ExchangeRate, y:: CurrencyAmount) = y*x

/(x:: CurrencyAmount{<: Number, C2}, y:: ExchangeRate{<: Number, C1, C2}) where {C1 <: Currency, C2 <: Currency} = CurrencyAmount(x.amount / y.rate, C1())

end
