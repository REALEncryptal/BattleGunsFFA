local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Controller = {}

local ProductData, Constants
function Controller:Init()
    ProductData = shared.Import "ProductData"
    Constants = shared.Import "Constants"
end

function Controller:GetProductData(Name)
    if not ProductData[Name] then
        Constants:Debug("[MonetizationController] Product not found: " .. Name)
        return
    end

    return ProductData[Name]
end

function Controller:GetProductInfo(Name)
    local Product = ProductData[Name]

    if not Product then
        Constants:Debug("[MonetizationController] Product not found: " .. Name)
        return
    end

    return MarketplaceService:GetProductInfo(Product.AssetID, Product.Type)
end

function Controller:PromptPurchase(Name)
    local Product = ProductData[Name]

    if not Product then
        Constants:Debug("[MonetizationController] Product not found: " .. Name)
        return
    end

    if Product.Type == Enum.InfoType.GamePass then
        MarketplaceService:PromptGamePassPurchase(LocalPlayer, Product.AssetID)
    else
        MarketplaceService:PromptProductPurchase(LocalPlayer, Product.AssetID)
    end
end

return Controller