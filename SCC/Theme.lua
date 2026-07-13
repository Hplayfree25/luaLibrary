local Theme = {
    -- Fonts
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,

    -- Colors (Modern Dark)
    Background = Color3.fromRGB(10, 12, 16),
    PanelBackground = Color3.fromRGB(20, 23, 30),
    Accent = Color3.fromRGB(96, 165, 250),
    AccentHover = Color3.fromRGB(125, 184, 255),
    SecondaryBackground = Color3.fromRGB(29, 33, 43),
    TabInactive = Color3.fromRGB(15, 18, 24),
    TabActive = Color3.fromRGB(27, 31, 40),
    TextPrimary = Color3.fromRGB(244, 247, 252),
    TextSecondary = Color3.fromRGB(184, 191, 204),
    TextMuted = Color3.fromRGB(119, 128, 145),
    Stroke = Color3.fromRGB(148, 163, 184),

    -- Additional semantic colors
    Surface = Color3.fromRGB(20, 23, 30),
    SurfaceElevated = Color3.fromRGB(25, 29, 38),
    SurfaceHover = Color3.fromRGB(34, 39, 50),
    Focus = Color3.fromRGB(96, 165, 250),
    Success = Color3.fromRGB(74, 222, 128),
    Error = Color3.fromRGB(248, 113, 113),

    -- Transparencies
    BackgroundTransparency = 0.05,
    PanelTransparency = 0.08,
    StrokeTransparency = 0.72,
    PanelStrokeTransparency = 0.82,

    -- Spacing
    SpacingXS = 4,
    SpacingSM = 8,
    SpacingMD = 12,
    SpacingLG = 16,
    SpacingXL = 24,

    -- Misc
    CornerRadius = UDim.new(0, 6),
    WindowCornerRadius = UDim.new(0, 10)
}

return Theme
