local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Controller = {}

local ProductData
function Controller:Init()
    ProductData = shared.Import "ProductData"
end

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

function Controller:PromptPurchase(Name)
    local Product = ProductData[Name]

    if not Product then
        warn("Product not found")
        return
    end

    if Product.Type == Enum.InfoType.GamePass then
        MarketplaceService:PromptGamePassPurchase(LocalPlayer, Product.AssetID)
    else
        MarketplaceService:PromptProductPurchase(LocalPlayer, Product.AssetID)
    end
end

return Controller