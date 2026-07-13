local Theme = {
    -- Fonts
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,

    -- Monochrome glass palette. Existing keys remain public for custom themes.
    Background = Color3.fromRGB(8, 9, 11),
    PanelBackground = Color3.fromRGB(22, 23, 27),
    Accent = Color3.fromRGB(238, 239, 242),
    AccentHover = Color3.fromRGB(255, 255, 255),
    SecondaryBackground = Color3.fromRGB(31, 32, 37),
    TabInactive = Color3.fromRGB(18, 19, 22),
    TabActive = Color3.fromRGB(37, 38, 43),
    TextPrimary = Color3.fromRGB(246, 246, 248),
    TextSecondary = Color3.fromRGB(194, 195, 200),
    TextMuted = Color3.fromRGB(126, 128, 136),
    Stroke = Color3.fromRGB(235, 236, 240),

    -- Semantic aliases
    Surface = Color3.fromRGB(22, 23, 27),
    SurfaceElevated = Color3.fromRGB(28, 29, 34),
    SurfaceHover = Color3.fromRGB(38, 39, 45),
    SurfaceActive = Color3.fromRGB(43, 44, 50),
    Focus = Color3.fromRGB(250, 250, 252),
    Success = Color3.fromRGB(205, 207, 211),
    Error = Color3.fromRGB(225, 226, 230),

    -- Transparencies
    BackgroundTransparency = 0.08,
    PanelTransparency = 0.22,
    StrokeTransparency = 0.88,
    PanelStrokeTransparency = 0.91,
    HoverStrokeTransparency = 0.5,
    FocusStrokeTransparency = 0.28,
    ActiveStrokeTransparency = 0.62,
    BorderTransparency = 0.9,
    GlassTransparency = 0.18,
    ContentTransparency = 0.42,
    TabTransparency = 0.38,
    HoverTransparency = 0.22,
    ActiveTransparency = 0.12,
    ScrollBarTransparency = 0.55,

    -- Spacing
    SpacingXS = 4,
    SpacingSM = 8,
    SpacingMD = 12,
    SpacingLG = 16,
    SpacingXL = 24,

    -- Radii
    CornerRadius = UDim.new(0, 12),
    WindowCornerRadius = UDim.new(0, 18),
    CardCornerRadius = UDim.new(0, 14),
    FieldCornerRadius = UDim.new(0, 12),
    PillCornerRadius = UDim.new(1, 0)
}

return Theme
