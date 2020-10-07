using CurrencyAmounts
using Test

@currencies USD, EUR

@testset "CurrencyAmounts.jl" begin
    
    @test EUR == Currency{:EUR}()

    @test 4USD == CurrencyAmounts.CurrencyAmount{Int64,Currency{:USD}}(4)
    @test 4USD + 5.5USD == 9.5USD
    @test 4USD - 5.5USD == -1.5USD
    @test 4.5USD * 2 == 9.0USD
    @test 4*4.5USD * 2 == 36.0USD
    @test 8USD / 2 == 4.0USD
    @test 8USD / 2 ≈ 4.0USD

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

    # currency conversions
    @test 3EUR * rate_eur_usd ≈ 3.6USD
    @test rate_eur_usd * 3EUR == 3EUR * rate_eur_usd
    @test_throws MethodError 3USD * rate_eur_usd # dimensions do not match
    @test 3USD / rate_eur_usd == 2.5EUR

end
