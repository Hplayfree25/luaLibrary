local Theme = {
    -- Fonts
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
    
    -- Colors (Refined Minimalist Dark)
    Background = Color3.fromRGB(12, 12, 14),             -- Deep obsidian gray
    PanelBackground = Color3.fromRGB(20, 20, 24),        -- Slate panel fill
    Accent = Color3.fromRGB(70, 130, 200),               -- Premium muted steel blue
    AccentHover = Color3.fromRGB(85, 145, 215),          -- Slate blue slightly brighter
    SecondaryBackground = Color3.fromRGB(30, 30, 36),   -- Component container/knob color
    TabInactive = Color3.fromRGB(16, 16, 20),
    TabActive = Color3.fromRGB(28, 28, 34),
    TextPrimary = Color3.fromRGB(255, 255, 255),         -- Pure white
    TextSecondary = Color3.fromRGB(200, 200, 205),       -- Muted light gray
    TextMuted = Color3.fromRGB(120, 120, 125),           -- Darker gray
    Stroke = Color3.fromRGB(255, 255, 255),              -- Thin overlay white stroke
    
    -- Transparencies
    BackgroundTransparency = 0.05,
    PanelTransparency = 0.4,
    StrokeTransparency = 0.94,                           -- Extremely faint white lines
    PanelStrokeTransparency = 0.96,                      -- Barely visible borders for premium feel
    
    -- Misc
    CornerRadius = UDim.new(0, 6),
    WindowCornerRadius = UDim.new(0, 10)
}

return Theme
