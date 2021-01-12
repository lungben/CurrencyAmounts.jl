using CurrencyAmounts
using Statistics
using Test

@currencies USD, EUR, GBP, CHF

@testset "CurrencyAmounts.jl" begin
    
    @test EUR == Currency{:EUR}()

    @test 4USD == CurrencyAmounts.CurrencyAmount{Int64,Currency{:USD}}(4)
    @test 4USD + 5.5USD == 9.5USD
    @test 4USD - 5.5USD == -1.5USD
    @test 4.5USD * 2 == 9.0USD
    @test 4*4.5USD * 2 == 36.0USD
    @test 8USD / 2 == 4.0USD
    @test 8USD / 2 ≈ 4.0USD
    @test 6EUR / 3EUR == 2.0
    @test 4USD/USD == 4.0
    @test -4USD == CurrencyAmounts.CurrencyAmount{Int64,Currency{:USD}}(-4)
    @test zero(3EUR) == 0EUR
    @test zero(typeof(3.5EUR)) == 0.0EUR
    @test 3EUR < 3.1EUR
    @test 6.8USD > 6.7USD
    @test_throws MethodError 2EUR < 5USD
    @test isfinite(3USD)
    @test !isfinite(Inf * USD)

    @test Statistics.middle(4EUR, 5EUR) == 4.5EUR
    @test median([2EUR, 4EUR, 5EUR, 8EUR]) == 4.5EUR
    @test isnan(4EUR) == false
    @test isnan(NaN*EUR) == true

    # invalid operations
    @test_throws MethodError 2 / 8USD
    @test_throws MethodError 3USD * 4USD
    @test_throws MethodError 4USD + 3EUR
    @test_throws MethodError 4USD - 3EUR

    # exchange rates
    rate_eur_usd = 1.2USD / 1EUR
    @test rate_eur_usd == ExchangeRate{Float64,Currency{:EUR},Currency{:USD}}(1.2) == ExchangeRate(1.2, EUR, USD)
    @test 2.4USD / 2EUR == rate_eur_usd
    @test rate_eur_usd * 2 == 2.4USD / 1EUR
    @test rate_eur_usd/2 == ExchangeRate{Float64,Currency{:EUR},Currency{:USD}}(0.6)
    @test 1/rate_eur_usd == ExchangeRate{Float64,Currency{:USD},Currency{:EUR}}(1/1.2)
    @test rate_eur_usd + 2*rate_eur_usd == 3*rate_eur_usd
    @test ExchangeRate(2.2, EUR, USD) - rate_eur_usd ≈ ExchangeRate(1.0, EUR, USD)
    @test_throws ErrorException ExchangeRate(1, EUR, EUR)

    @test rate_eur_usd / rate_eur_usd == 1
    @test (2.4USD / EUR) / rate_eur_usd == 2

    # triangulation
    @test (1.2USD/EUR) / (0.8USD/GBP) ≈ (1.2/0.8)*GBP/EUR
    @test (1.2USD/EUR) / (1.1GBP/EUR) ≈ (1.2/1.1)*USD/GBP
    @test (1.2USD/EUR) * (2.2EUR/GBP) ≈ (1.2*2.2)*USD/GBP
    @test (1.2USD/EUR) * (1.1GBP/USD) ≈ (1.2*1.1)*GBP/EUR

    @test Statistics.middle(rate_eur_usd, 2*rate_eur_usd) == 1.5rate_eur_usd
    @test isnan(rate_eur_usd) == false

    # currency conversions
    @test 3EUR * rate_eur_usd ≈ 3.6USD
    @test rate_eur_usd * 3EUR == 3EUR * rate_eur_usd
    @test_throws MethodError 3USD * rate_eur_usd # dimensions do not match
    @test 3USD / rate_eur_usd == 2.5EUR

    # test pretty printing
    io = IOBuffer(append=true)
    print(io, EUR)
    @test read(io, String) == "EUR"
    print(io, 100.5EUR)
    @test read(io, String) == "100.5 EUR"
    print(io, 1.2USD/EUR)
    @test read(io, String) == "1.2 USD/EUR"

    # conversions
    @test convert(EUR, 2.4USD, 1.2USD/EUR) == 2.0EUR
    @test convert(USD, 2EUR, 1.2USD/EUR) == 2.4USD
    @test convert(USD, 4USD, 1.2USD/EUR) == 4USD
    @test convert(GBP, 4USD, 1.2USD/EUR) === missing

    exchange_rates = (1.2USD/EUR, 1.3EUR/GBP, 1.56USD/GBP)
    @test convert(GBP, 5.2EUR, exchange_rates) == 4.0GBP
    @test convert(CHF, 5.2USD, exchange_rates) === missing # this exchange rate is not given, no automatic triangulation performed

end
