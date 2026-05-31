local Theme = {
    -- Fonts
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
    
    -- Colors
    Background = Color3.fromRGB(12, 12, 16),
    PanelBackground = Color3.fromRGB(25, 25, 30),
    Accent = Color3.fromRGB(100, 150, 255),
    AccentHover = Color3.fromRGB(120, 170, 255),
    SecondaryBackground = Color3.fromRGB(40, 40, 45),
    TabInactive = Color3.fromRGB(20, 20, 25),
    TabActive = Color3.fromRGB(40, 40, 50),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(240, 240, 240),
    TextMuted = Color3.fromRGB(150, 150, 150),
    Stroke = Color3.fromRGB(255, 255, 255),
    
    -- Transparencies
    BackgroundTransparency = 0.1,
    PanelTransparency = 0.6,
    StrokeTransparency = 0.85,
    PanelStrokeTransparency = 0.92,
    
    -- Misc
    CornerRadius = UDim.new(0, 8),
    WindowCornerRadius = UDim.new(0, 12)
}

return Theme
