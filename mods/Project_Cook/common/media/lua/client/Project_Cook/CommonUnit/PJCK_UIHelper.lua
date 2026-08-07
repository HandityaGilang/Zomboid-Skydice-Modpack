PJCK_UIHelper = {}

PJCK_UIHelper.textureCache = {}
PJCK_UIHelper.outlineTextureCache = {}
PJCK_UIHelper.isLoaded = false
PJCK_UIHelper.DEFAULT_SCALE_FACTOR = 1.0

-- ----------------------------------------- --
-- 初始化和资源加载
-- ----------------------------------------- --

function PJCK_UIHelper.loadTextures()
    if PJCK_UIHelper.isLoaded then return end
    
    -- 加载普通数字贴图 (0-9)
    for i = 0, 9 do
        PJCK_UIHelper.textureCache[tostring(i)] = getTexture("media/ui/Project_Cook/numbers/" .. i .. ".png")
    end
    
    -- 加载描边数字贴图 (0-9)
    for i = 0, 9 do
        PJCK_UIHelper.outlineTextureCache[tostring(i)] = getTexture("media/ui/Project_Cook/numbers_outline/" .. i .. ".png")
    end

    PJCK_UIHelper.outlineTextureCache["M"] = getTexture("media/ui/Project_Cook/numbers_outline/M.png")
    PJCK_UIHelper.outlineTextureCache["L"] = getTexture("media/ui/Project_Cook/numbers_outline/L.png")
    PJCK_UIHelper.outlineTextureCache["/"] = getTexture("media/ui/Project_Cook/numbers_outline/Slash.png")
    PJCK_UIHelper.outlineTextureCache["?"] = getTexture("media/ui/Project_Cook/numbers_outline/Query.png")
    PJCK_UIHelper.outlineTextureCache[":"] = getTexture("media/ui/Project_Cook/numbers_outline/Colon.png")
    PJCK_UIHelper.outlineTextureCache["."] = getTexture("media/ui/Project_Cook/numbers_outline/dot.png")
    PJCK_UIHelper.outlineTextureCache["S"] = getTexture("media/ui/Project_Cook/numbers_outline/S.png")

    
    PJCK_UIHelper.isLoaded = true
end

-- ----------------------------------------- --
-- 计算文本宽度
-- ----------------------------------------- --

function PJCK_UIHelper.measureTextWidth(text, size, useOutline)
    if not PJCK_UIHelper.isLoaded then
        PJCK_UIHelper.loadTextures()
    end
    
    local cache = useOutline and PJCK_UIHelper.outlineTextureCache or PJCK_UIHelper.textureCache
    local totalWidth = 0
    
    for i = 1, #text do
        local char = string.sub(text, i, i)
        local texture = cache[char]
        
        if texture then
            -- 获取单个字符贴图的原始尺寸
            local charWidth = texture:getWidth()
            local charHeight = texture:getHeight()
            -- 根据目标高度计算缩放后的宽度
            local scale = size / charHeight
            totalWidth = totalWidth + (charWidth * scale)
        end
    end
    
    return totalWidth
end


-- 文本自动缩略方法
function PJCK_UIHelper.truncateText(text, maxWidth, font, suffix)
    if not text or text == "" then
        return ""
    end

    font = font or UIFont.Small
    suffix = suffix or "..."
    
    local originalWidth = getTextManager():MeasureStringX(font, text)

    if originalWidth <= maxWidth then
        return text
    end

    local suffixWidth = getTextManager():MeasureStringX(font, suffix)

    if suffixWidth >= maxWidth then
        return ""
    end

    local textMaxWidth = maxWidth - suffixWidth

    local left = 1
    local right = string.len(text)
    local bestLength = 0
    
    while left <= right do
        local mid = math.floor((left + right) / 2)
        local truncatedText = string.sub(text, 1, mid)
        local truncatedWidth = getTextManager():MeasureStringX(font, truncatedText)
        
        if truncatedWidth <= textMaxWidth then
            bestLength = mid
            left = mid + 1
        else
            right = mid - 1
        end
    end

    if bestLength == 0 then
        return suffix
    end

    local finalText = string.sub(text, 1, bestLength)
    return finalText .. suffix
end

-- ----------------------------------------- --
-- 绘制函数
-- ----------------------------------------- --

function PJCK_UIHelper.renderText(panel, text, x, y, size, alpha, r, g, b, useOutline)
    if not PJCK_UIHelper.isLoaded then
        PJCK_UIHelper.loadTextures()
    end
    
    local cache = useOutline and PJCK_UIHelper.outlineTextureCache or PJCK_UIHelper.textureCache
    local currentX = x
    
    for i = 1, #text do
        local char = string.sub(text, i, i)
        local texture = cache[char]
        
        if texture then
            -- 获取当前字符贴图的原始尺寸
            local charWidth = texture:getWidth()
            local charHeight = texture:getHeight()
            
            -- 根据目标高度计算缩放比例
            local scale = size / charHeight
            local scaledWidth = charWidth * scale
            
            -- 绘制字符
            panel:drawTextureScaled(
                texture, 
                currentX, 
                y, 
                scaledWidth, 
                size,
                alpha, r, g, b
            )
            
            currentX = currentX + scaledWidth
        end
    end
    
    return currentX - x
end

-- 绘制三段式贴图
function PJCK_UIHelper.drawThreeSlice(panel, x, y, width, height, leftTexture, middleTexture, rightTexture, alpha, r, g, b)

    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    
    -- 设置默认颜色
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    
    -- 获取左右两段的原始尺寸
    local leftOriginalWidth = leftTexture:getWidth()
    local leftOriginalHeight = leftTexture:getHeight()
    local rightOriginalWidth = rightTexture:getWidth()
    local rightOriginalHeight = rightTexture:getHeight()
    
    -- 计算左右两段的实际宽度（保持比例）
    local heightRatio = height / leftOriginalHeight
    local leftActualWidth = math.floor(leftOriginalWidth * heightRatio)
    
    heightRatio = height / rightOriginalHeight
    local rightActualWidth = math.floor(rightOriginalWidth * heightRatio)
    
    local minSidesWidth = leftActualWidth + rightActualWidth
    
    -- 如果总宽度小于最小宽度，按照比例处理
    if width <= minSidesWidth then
        local leftRatio = leftActualWidth / minSidesWidth
        leftActualWidth = math.floor(width * leftRatio)
        rightActualWidth = width - leftActualWidth
        
        panel:drawTextureScaled(leftTexture, x, y, leftActualWidth, height, alpha, r, g, b)
        panel:drawTextureScaled(rightTexture, x + leftActualWidth, y, rightActualWidth, height, alpha, r, g, b)
    else
        -- 计算中间段的宽度
        local middleWidth = width - leftActualWidth - rightActualWidth
        
        -- 绘制左段
        panel:drawTextureScaled(leftTexture, x, y, leftActualWidth, height, alpha, r, g, b)
        
        -- 绘制中段
        panel:drawTextureScaled(middleTexture, x + leftActualWidth, y, middleWidth, height, alpha, r, g, b)
        
        -- 绘制右段
        panel:drawTextureScaled(rightTexture, x + leftActualWidth + middleWidth, y, rightActualWidth, height, alpha, r, g, b)
    end
end

-- 绘制垂直三段式贴图
function PJCK_UIHelper.drawVerticalThreeSlice(panel, x, y, width, height, topTexture, middleTexture, bottomTexture, alpha, r, g, b)

    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    
    -- 设置默认颜色
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    
    -- 获取上下两段的原始尺寸
    local topOriginalWidth = topTexture:getWidth()
    local topOriginalHeight = topTexture:getHeight()
    local bottomOriginalWidth = bottomTexture:getWidth()
    local bottomOriginalHeight = bottomTexture:getHeight()
    
    -- 计算上下两段的实际高度（保持比例）
    local widthRatio = width / topOriginalWidth
    local topActualHeight = math.floor(topOriginalHeight * widthRatio)
    
    widthRatio = width / bottomOriginalWidth
    local bottomActualHeight = math.floor(bottomOriginalHeight * widthRatio)
    
    local minSidesHeight = topActualHeight + bottomActualHeight
    
    -- 如果总高度小于最小高度，按比例调整上下两段
    if height <= minSidesHeight then
        local topRatio = topActualHeight / minSidesHeight
        topActualHeight = math.floor(height * topRatio)
        bottomActualHeight = height - topActualHeight
        
        panel:drawTextureScaled(topTexture, x, y, width, topActualHeight, alpha, r, g, b)
        panel:drawTextureScaled(bottomTexture, x, y + topActualHeight, width, bottomActualHeight, alpha, r, g, b)
    else
        -- 计算中间段的高度
        local middleHeight = height - topActualHeight - bottomActualHeight
        
        -- 绘制上段
        panel:drawTextureScaled(topTexture, x, y, width, topActualHeight, alpha, r, g, b)
        
        -- 绘制中段
        panel:drawTextureScaled(middleTexture, x, y + topActualHeight, width, middleHeight, alpha, r, g, b)
        
        -- 绘制下段
        panel:drawTextureScaled(bottomTexture, x, y + topActualHeight + middleHeight, width, bottomActualHeight, alpha, r, g, b)
    end
end

-- 绘制九段式贴图
function PJCK_UIHelper.drawNineSlice(panel, x, y, width, height, textures, alpha, r, g, b)
    
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    
    -- 设置默认颜色
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    
    -- 获取四个角的原始尺寸
    local cornerTopLeftWidth = textures.topLeft:getWidth()
    local cornerTopLeftHeight = textures.topLeft:getHeight()
    local cornerTopRightWidth = textures.topRight:getWidth()
    local cornerTopRightHeight = textures.topRight:getHeight()
    local cornerBottomLeftWidth = textures.bottomLeft:getWidth()
    local cornerBottomLeftHeight = textures.bottomLeft:getHeight()
    local cornerBottomRightWidth = textures.bottomRight:getWidth()
    local cornerBottomRightHeight = textures.bottomRight:getHeight()
    
    -- 计算最小宽度和高度
    local minWidth = cornerTopLeftWidth + cornerTopRightWidth
    local minHeight = cornerTopLeftHeight + cornerBottomLeftHeight
    
    -- 计算统一的缩放比例（取较小值确保等比缩放）
    local scale = 1.0
    if width < minWidth then
        scale = width / minWidth
    end
    if height < minHeight and (height / minHeight) < scale then
        scale = height / minHeight
    end
    
    -- 使用统一比例缩放四个角的尺寸
    local actualCornerTopLeftWidth = math.floor(cornerTopLeftWidth * scale)
    local actualCornerTopLeftHeight = math.floor(cornerTopLeftHeight * scale)
    local actualCornerTopRightWidth = math.floor(cornerTopRightWidth * scale)
    local actualCornerTopRightHeight = math.floor(cornerTopRightHeight * scale)
    local actualCornerBottomLeftWidth = math.floor(cornerBottomLeftWidth * scale)
    local actualCornerBottomLeftHeight = math.floor(cornerBottomLeftHeight * scale)
    local actualCornerBottomRightWidth = math.floor(cornerBottomRightWidth * scale)
    local actualCornerBottomRightHeight = math.floor(cornerBottomRightHeight * scale)
    
    -- 计算边缘和中间部分的尺寸
    local middleWidth = width - actualCornerTopLeftWidth - actualCornerTopRightWidth
    local middleHeight = height - actualCornerTopLeftHeight - actualCornerBottomLeftHeight
    
    -- 如果空间不足，进行特殊处理
    if middleWidth < 0 then
        -- 根据宽度比例调整角落宽度
        local totalCornerWidth = actualCornerTopLeftWidth + actualCornerTopRightWidth
        actualCornerTopLeftWidth = math.floor(width * (actualCornerTopLeftWidth / totalCornerWidth))
        actualCornerTopRightWidth = width - actualCornerTopLeftWidth
        actualCornerBottomLeftWidth = actualCornerTopLeftWidth
        actualCornerBottomRightWidth = actualCornerTopRightWidth
        middleWidth = 0
    end
    
    if middleHeight < 0 then
        -- 根据高度比例调整角落高度
        local totalCornerHeight = actualCornerTopLeftHeight + actualCornerBottomLeftHeight
        actualCornerTopLeftHeight = math.floor(height * (actualCornerTopLeftHeight / totalCornerHeight))
        actualCornerBottomLeftHeight = height - actualCornerTopLeftHeight
        actualCornerTopRightHeight = actualCornerTopLeftHeight
        actualCornerBottomRightHeight = actualCornerBottomLeftHeight
        middleHeight = 0
    end
    
    -- 绘制四个角
    panel:drawTextureScaled(textures.topLeft, x, y, 
                           actualCornerTopLeftWidth, actualCornerTopLeftHeight, 
                           alpha, r, g, b)
    
    panel:drawTextureScaled(textures.topRight, 
                           x + width - actualCornerTopRightWidth, y, 
                           actualCornerTopRightWidth, actualCornerTopRightHeight, 
                           alpha, r, g, b)
    
    panel:drawTextureScaled(textures.bottomLeft, 
                           x, y + height - actualCornerBottomLeftHeight, 
                           actualCornerBottomLeftWidth, actualCornerBottomLeftHeight, 
                           alpha, r, g, b)
    
    panel:drawTextureScaled(textures.bottomRight, 
                           x + width - actualCornerBottomRightWidth, y + height - actualCornerBottomRightHeight, 
                           actualCornerBottomRightWidth, actualCornerBottomRightHeight, 
                           alpha, r, g, b)
    
    -- 绘制边缘
    if middleWidth > 0 then
        -- 上边缘
        panel:drawTextureScaled(textures.top, 
                               x + actualCornerTopLeftWidth, y, 
                               middleWidth, actualCornerTopLeftHeight, 
                               alpha, r, g, b)
        
        -- 下边缘
        panel:drawTextureScaled(textures.bottom, 
                               x + actualCornerBottomLeftWidth, y + height - actualCornerBottomLeftHeight, 
                               middleWidth, actualCornerBottomLeftHeight, 
                               alpha, r, g, b)
    end
    
    if middleHeight > 0 then
        -- 左边缘
        panel:drawTextureScaled(textures.left, 
                               x, y + actualCornerTopLeftHeight, 
                               actualCornerTopLeftWidth, middleHeight, 
                               alpha, r, g, b)
        
        -- 右边缘
        panel:drawTextureScaled(textures.right, 
                               x + width - actualCornerTopRightWidth, y + actualCornerTopRightHeight, 
                               actualCornerTopRightWidth, middleHeight, 
                               alpha, r, g, b)
    end
    
    -- 绘制中间部分
    if middleWidth > 0 and middleHeight > 0 then
        panel:drawTextureScaled(textures.middle, 
                               x + actualCornerTopLeftWidth, y + actualCornerTopLeftHeight, 
                               middleWidth, middleHeight, 
                               alpha, r, g, b)
    end
end


return PJCK_UIHelper