
return {
    -- Starter market offers.  Coin values are obtained from the itemValues table.
    starterMarketOffers = {
        -- {item_to_receive, item_to_give}

        -- e.g. get "coin" for "steam-engine"
        -- sell "steam-engine" for "coin"
        {"coin", "steam-engine"},

        -- e.g. get "copper-cable" for "coin"
        -- buy "copper-cable" with "coin"
        {"copper-cable", "coin"},

        {"wood", "inserter"},
        {"electric-mining-drill", "stone-wall"},
        {"landfill", "coal"},

    },

    -- Chance of a chunk to contain a market.
    baseMarketChance = 0.25,

    -- The chance that a market trade will be through coins, whether it's to buy or to sell an item.
    chanceOfCoinTrade = 0.5,

    -- Chance that a coin trade is a "sell" type of trade instead of a "buy" type of trade.
    chanceOfSellTrade = 0.75,

    -- The number of trades that a market can offer.
    tradesPerMarketMin = 3,
    tradesPerMarketMax = 5,

    -- Number of trade offers in a super chunk's market.
    superChunkMarketTrades = 8,

    -- When a market trade takes item A and gives item B, the value of B is no less than this portion of the value of A.
    -- The lower this is, the more trades you'll find of high-value items selling for low-value items.
    -- Should not be more than 1.
    -- This logic is here to prevent the really weird trades from generating like "sell 1 space science pack for 38 flamethrower ammo".
    tradeRelativeValueLower = 0.9,

    -- When a market trade takes item A and gives item B, the value of B is no more than this portion of the value of A.
    -- The higher this is, the more trades you'll find of low-value items selling for high-value items.
    -- Should not be less than 1.
    tradeRelativeValueUpper = 9.5,
}
