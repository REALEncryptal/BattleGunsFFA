local MarketplaceService = game:GetService("MarketplaceService")
local Controller = {}

local ProductData
function Controller:Init()
    ProductData = shared.Import "ProductData"

    -- Connect events
    MarketplaceService.PromptPurchaseFinished:Connect(Controller.PromptPurchaseFinished)
end

-- Events
function Controller.PromptPurchaseFinished(Player:Player, AssetID, WasPurchased:boolean)
    if not WasPurchased then return end

    local ProductData = Controller:GetProductFromID(AssetID)
    if not ProductData then return end

    if ProductData.PlayerJoined then
        ProductData.PlayerJoined(Player)
    end
end

function Controller.PlayerAdded(Player)
    -- Check if player owns any products and run the PlayerJoined function
    for _, Product in pairs(ProductData) do
        if Product.Type ~= Enum.InfoType.GamePass then return end
        local Success, IsOwned = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, Product.AssetID)
        end)

        if Success and IsOwned then
            Product.PlayerJoined(Player)
        end
    end
end

-- Methods
function Controller:GetProductData(Name)
    if not ProductData[Name] then
        warn("Product not found")
        return
    end

    return ProductData[Name]
end

function Controller:GetProductInfo(Name)
    local Product = ProductData[Name]

    if not Product then
        warn("Product not found")
        return
    end

    return MarketplaceService:GetProductInfo(Product.AssetID, Product.Type)
end

function Controller:GetProductFromID(AssetID)
    for _, Product in pairs(ProductData) do
        if Product.AssetID == AssetID then
            return Product
        end
    end

    warn("Product not found")
    return nil
end

return Controller