--[[
    SaveInstance
    30/01/2026
    By: Matt.T <3

    Improved upon by ava.png
    13/09/2026

    Exports the instance(s) into a rblx format and sets to clipboard.
]]

-- Export filters (set to nil to disable)
local DEFAULT_CONFIG = {

    root = game, -- change to whatever instance you want to export from

    -- Services
    includeServices = nil, -- e.g. { Workspace = true, ReplicatedStorage = true }
    excludeServices = nil, -- e.g. { Players = true }

    -- Instance class
    includeClassNames = nil, -- e.g. { Part = true, MeshPart = true }
    excludeClassNames = nil, -- e.g. { Terrain = true }

    -- Instance name
    includeNames = nil, -- e.g. { Baseplate = true }
    excludeNames = nil, -- e.g. { Camera = true }

    -- Pattern name
    includeNamePatterns = nil, -- e.g. { '^NPC_' }
    excludeNamePatterns = nil, -- e.g. { '^Temp' }

    -- If true, children of a filtered-out parent can still be exported
    includeChildrenOfFiltered = false,

    -- Script decompilation
    decompileScripts = false,

    -- Exclude Players
    excludePlayers = true,

    -- Mini console at bottom left
    showConsole = true,
}

_G.CONFIG = _G.CONFIG or DEFAULT_CONFIG

local Workspace = game:GetService('Workspace')
local Players = game:GetService('Players')
local Camera = Workspace.CurrentCamera

local PLAYER_NAME_SET = nil

local KNOWN_PROPERTIES = {
    Workspace = {
        'Archivable',
        'CurrentCamera',
        'DistributedGameTime',
        'InsertPoint',
        'Name',
        'Parent',
        'UniqueId',
        'Origin',
        'PrimaryPart',
        'Scale',
        'WorldPivot',
        'AllowThirdPartySales',
        'ClientAnimatorThrottling',
        'FallenPartsDestroyHeight',
        'FallHeightEnabled',
        'FluidForces',
        'GlobalWind',
        'Gravity',
        'MeshPartHeadsAndAccessories',
        'PathfindingUseImprovedSearch',
        'PhysicsSteppingMethod',
        'PlayerCharacterDestroyBehavior',
        'RenderingCacheOptimizations',
        'Retargeting',
        'SandboxedInstanceMode',
        'SignalBehavior',
        'Terrain',
        'TouchesUseCollisionGroups',
        'TouchEventsUseCollisionGroups',
        'AirDensity',
        'RejectCharacterDeletions',
        'LuauTypeCheckMode',
        'UseNewLuauTypeSolver',
        'StreamingEnabled',
    },

    Camera = {
        'Archivable',
        'CFrame',
        'ClassName',
        'Focus',
        'HeadLocked',
        'HeadScale',
        'Name',
        'NearPlaneZ',
        'Parent',
        'UniqueId',
        'ViewportSize',
        'VRTiltAndRollEnabled',
        'Origin',
        'PivotOffset',
        'CameraSubject',
        'CameraType',
        'DiagonalFieldOfView',
        'FieldOfView',
        'FieldOfViewMode',
        'MaxAxisFieldOfView',
        'CollisionGroup',
        'CustomPhysicalProperties',
    },

    Terrain = {
        'Decoration',
        'GrassLength',
        'MaterialColors',
        'WaterColor',
        'WaterReflectance',
        'WaterTransparency',
        'WaterWaveSize',
        'WaterWaveSpeed',
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'CollisionGroup',
        'CustomPhysicalProperties',
    },

    Model = {
        'LevelOfDetail',
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'Origin',
        'PrimaryPart',
        'Scale',
        'WorldPivot',
    },

    Part = {
        'BrickColor',
        'CastShadow',
        'Color',
        'Material',
        'MaterialVariant',
        'Reflectance',
        'Transparency',
        'Archivable',
        'ClassName',
        'Locked',
        'Name',
        'Parent',
        'ResizeableFaces',
        'ResizeIncrement',
        'UniqueId',
        'Size',
        'CFrame',
        'Origin',
        'PivotOffset',
        'EnableFluidForces',
        'CanCollide',
        'CanTouch',
        'CollisionGroup',
        'Anchored',
        'CenterOfMass',
        'CurrentPhysicalProperties',
        'CustomPhysicalProperties',
        'Mass',
        'Massless',
        'RootPriority',
        'Shape',
        'AssemblyLinearVelocity',
        'AssemblyAngularVelocity',
        'AssemblyCenterOfMass',
        'AssemblyMass',
        'AssemblyRootPart',
        'BackSurface',
        'BottomSurface',
        'FrontSurface',
        'LeftSurface',
        'RightSurface',
        'TopSurface',
    },

    MeshPart = {
        'BrickColor',
        'CastShadow',
        'Color',
        'DoubleSided',
        'Material',
        'MaterialVariant',
        'MeshContent',
        'MeshId',
        'Reflectance',
        'RenderFidelity',
        'TextureContent',
        'TextureID',
        'Transparency',
        'Archivable',
        'ClassName',
        'Locked',
        'MeshSize',
        'Name',
        'Parent',
        'ResizeableFaces',
        'ResizeIncrement',
        'UniqueId',
        'Size',
        'CFrame',
        'Origin',
        'PivotOffset',
        'EnableFluidForces',
        'FluidFidelity',
        'CanCollide',
        'CanTouch',
        'CollisionFidelity',
        'CollisionGroup',
        'Anchored',
        'CenterOfMass',
        'CurrentPhysicalProperties',
        'CustomPhysicalProperties',
        'Mass',
        'Massless',
        'RootPriority',
        'AssemblyLinearVelocity',
        'AssemblyAngularVelocity',
        'AssemblyCenterOfMass',
        'AssemblyMass',
        'AssemblyRootPart',
    },

    Humanoid = {
        'Archivable',
        'CameraOffset',
        'ClassName',
        'DisplayDistanceType',
        'DisplayName',
        'HealthDisplayDistance',
        'HealthDisplayType',
        'Name',
        'NameDisplayDistance',
        'NameOcclusion',
        'Parent',
        'RigType',
        'RootPart',
        'UniqueId',
        'BreakJointsOnDeath',
        'EvaluateStateMachine',
        'RequiresNeck',
        'AutoRotate',
        'FloorMaterial',
        'Jump',
        'MoveDirection',
        'PlatformStand',
        'SeatPart',
        'Sit',
        'TargetPoint',
        'WalkToPart',
        'WalkToPoint',
        'AutomaticScalingEnabled',
        'Health',
        'HipHeight',
        'MaxHealth',
        'MaxSlopeAngle',
        'WalkSpeed',
        'AutoJumpEnabled',
        'JumpPower',
        'UseJumpPower',
    },

    Accessory = {
        'Archivable',
        'AccessoryType',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'AttachmentPoint',
    },

    BodyColors = {
        'HeadColor',
        'HeadColor3',
        'LeftArmColor',
        'LeftArmColor3',
        'LeftLegColor',
        'LeftLegColor3',
        'RightArmColor',
        'RightArmColor3',
        'RightLegColor',
        'RightLegColor3',
        'TorsoColor',
        'TorsoColor3',
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
    },

    Pants = {
        'Color3',
        'PantsTemplate',
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
    },

    Shirt = {
        'Color3',
        'ShirtTemplate',
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
    },

    LocalScript = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'Enabled',
    },

    Script = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'Enabled',
    },

    NumberValue = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'Value',
    },

    StringValue = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'Value',
    },

    BindableFunction = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
    },

    Attachment = {
        'Visible',
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'CFrame',
        'Axis',
        'SecondaryAxis',
        'WorldCFrame',
        'WorldAxis',
        'WorldSecondaryAxis',
    },

    Vector3Value = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'Value',
    },

    WrapLayer = {
        'CageMeshContent',
        'CageMeshId',
        'CageOrigin',
        'ImportOrigin',
        'Order',
        'Puffiness',
        'ReferenceMeshContent',
        'ReferenceMeshId',
        'ReferenceOrigin',
        'Archivable',
        'CageOriginWorld',
        'ClassName',
        'ImportOriginWorld',
        'Name',
        'Parent',
        'ReferenceOriginWorld',
        'UniqueId',
        'AutoSkin',
        'Enabled',
        'Color',
        'DebugMode',
        'BindOffset',
        'ShrinkFactor',
    },

    SurfaceAppearance = {
        'AlphaMode',
        'Color',
        'ColorMap',
        'MetalnessMap',
        'NormalMap',
        'RoughnessMap',
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
    },

    Weld = {
        'Archivable',
        'C0',
        'C1',
        'ClassName',
        'Name',
        'Parent',
        'Part0',
        'Part1',
        'UniqueId',
        'Active',
        'Enabled',
    },

    HumanoidDescription = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'UseAvatarSettings',
        'AccessoryBlob',
        'BackAccessory',
        'FaceAccessory',
        'FrontAccessory',
        'HairAccessory',
        'HatAccessory',
        'NeckAccessory',
        'ShoulderAccessory',
        'WaistAccessory',
        'ClimbAnimation',
        'FallAnimation',
        'IdleAnimation',
        'JumpAnimation',
        'MoodAnimation',
        'RunAnimation',
        'SwimAnimation',
        'WalkAnimation',
        'HeadColor',
        'LeftArmColor',
        'LeftLegColor',
        'RightArmColor',
        'RightLegColor',
        'TorsoColor',
        'Face',
        'Head',
        'LeftArm',
        'LeftLeg',
        'RightArm',
        'RightLeg',
        'Torso',
        'GraphicTShirt',
        'Pants',
        'Shirt',
        'BodyTypeScale',
        'DepthScale',
        'HeadScale',
        'HeightScale',
        'ProportionScale',
        'WidthScale',
    },

    AccessoryDescription = {
        'Archivable',
        'AccessoryType',
        'AssetId',
        'ClassName',
        'Instance',
        'IsLayered',
        'Name',
        'Order',
        'Parent',
        'Position',
        'Puffiness',
        'Rotation',
        'Scale',
        'UniqueId',
    },

    BodyPartDescription = {
        'Archivable',
        'AssetId',
        'BodyPart',
        'ClassName',
        'Color',
        'Instance',
        'Name',
        'Parent',
        'UniqueId',
    },

    RemoteFunction = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
    },

    RemoteEvent = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
    },

    ModuleScript = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
    },

    ColorGradingEffect = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'Enabled',
        'TonemapperPreset',
    },

    BloomEffect = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'Enabled',
        'Intensity',
        'Size',
        'Threshold',
    },

    ParticleEmitter = {
        'Archivable', 'Enabled', 'Name', 'Parent', 'UniqueId',
        'Acceleration', 'Brightness', 'Color', 'Drag', 'EmissionDirection',
        'FlipbookBlendFrames', 'FlipbookFramerate', 'FlipbookSizeX', 'FlipbookSizeY', 'FlipbookLayout', 'FlipbookMode', 'FlipbookStartRandom',
        'Lifetime', 'LightEmission', 'LightInfluence', 'LocalTransparencyModifier', 'LockedToPart', 'Orientation',
        'Rate', 'RotSpeed', 'Rotation', 'Shape', 'ShapeInOut', 'ShapePartial',
        'ShapeStyle', 'Size', 'Speed', 'SpreadAngle', 'Squash', 'TimeScale',
        'Transparency', 'VelocityInheritance', 'VelocitySpread', 'WindAffectsDrag', 'ZOffset',
    },

    Beam = {
        'Archivable', 'Enabled', 'Name', 'Parent', 'UniqueId',
        'Attachment0', 'Attachment1', 'Brightness', 'Color', 'CurveSize0',
        'CurveSize1', 'FaceCamera', 'LightEmission', 'LightInfluence',
        'Segments', 'TextureLength', 'TextureMode', 'TextureSpeed',
        'Transparency', 'Width0', 'Width1', 'ZOffset',
    },

    Trail = {
        'Archivable', 'Enabled', 'Name', 'Parent', 'UniqueId',
        'Attachment0', 'Attachment1', 'Brightness', 'Color', 'FaceCamera',
        'Lifetime', 'LightEmission', 'LightInfluence', 'MaxLength',
        'MinLength', 'TextureLength', 'TextureMode', 'Transparency',
        'WidthScale',
    },

    SpecialMesh = {
        'Archivable', 'Name', 'Parent', 'UniqueId',
        'MeshType', 'Offset', 'Scale', 'VertexColor',
    },

    Sound = {
        'Archivable',
        'ClassName',
        'Name',
        'Parent',
        'UniqueId',
        'PlayOnRemove',
        'IsLoaded',
        'TimeLength',
        'RollOffMaxDistance',
        'RollOffMinDistance',
        'RollOffMode',
        'Looped',
        'PlaybackLoudness',
        'PlaybackRegionsEnabled',
        'PlaybackSpeed',
        'Playing',
        'TimePosition',
        'Volume',
        'SoundGroup',
    },
}

-- Extra property coverage for classes that commonly carry assets/effects/UI state.
-- Kept separate from the original table so this remains easy to extend.
local EXTRA_KNOWN_PROPERTIES = {
    Animation = { 'Archivable', 'Name', 'Parent', 'UniqueId' },
    AudioPlayer = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'AssetId', 'AutoLoad', 'AutoPlay', 'Looping', 'LoopRegion', 'PlaybackRegion', 'PlaybackSpeed', 'TimePosition', 'Volume' },
    VideoFrame = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'Looped', 'Playing', 'RollOffMaxDistance', 'RollOffMinDistance', 'RollOffMode', 'TimePosition', 'Volume' },
    VideoPlayer = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'AutoLoadInStudio', 'AutoPlayInStudio', 'Looping', 'PlaybackSpeed', 'TimePosition', 'Volume' },
    Decal = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'Color3', 'Face', 'Transparency', 'ZIndex' },
    Texture = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'Color3', 'Face', 'OffsetStudsU', 'OffsetStudsV', 'StudsPerTileU', 'StudsPerTileV', 'Transparency', 'ZIndex' },
    SurfaceAppearance = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'AlphaMode', 'Color', 'EmissiveStrength', 'EmissiveTint', 'ResampleMode' },
    MaterialVariant = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'AlphaMode', 'BaseMaterial', 'CustomPhysicalProperties', 'EmissiveStrength', 'EmissiveTint', 'MaterialPattern', 'StudsPerTile' },
    Sky = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'CelestialBodiesShown', 'MoonAngularSize', 'SkyboxOrientation', 'StarCount', 'SunAngularSize' },
    Tool = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'CanBeDropped', 'Enabled', 'Grip', 'GripForward', 'GripPos', 'GripRight', 'GripUp', 'ManualActivationOnly', 'RequiresHandle', 'ToolTip' },
    ClickDetector = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'MaxActivationDistance' },
    DragDetector = { 'Archivable', 'Name', 'Parent', 'UniqueId' },
    ImageLabel = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'ImageColor3', 'ImageRectOffset', 'ImageRectSize', 'ImageTransparency', 'ResampleMode', 'ScaleType', 'SliceCenter', 'SliceScale', 'TileSize' },
    ImageButton = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'AutoButtonColor', 'HoverImage', 'ImageColor3', 'ImageRectOffset', 'ImageRectSize', 'ImageTransparency', 'PressedImage', 'ResampleMode', 'ScaleType', 'SliceCenter', 'SliceScale', 'TileSize' },
    ImageHandleAdornment = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'AlwaysOnTop', 'CFrame', 'Color3', 'Size', 'Transparency', 'ZIndex' },
    CharacterMesh = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'BodyPart' },
    WrapLayer = { 'Archivable', 'Name', 'Parent', 'UniqueId', 'AutoSkin', 'BindOffset', 'Color', 'DebugMode', 'Enabled', 'Order', 'Puffiness', 'ReferenceOrigin', 'ShrinkFactor' },
    WrapTarget = { 'Archivable', 'Name', 'Parent', 'UniqueId' },
    Beam = { 'Archivable', 'Enabled', 'Name', 'Parent', 'UniqueId', 'Attachment0', 'Attachment1', 'Brightness', 'Color', 'CurveSize0', 'CurveSize1', 'FaceCamera', 'LightEmission', 'LightInfluence', 'Segments', 'TextureLength', 'TextureMode', 'TextureSpeed', 'Transparency', 'Width0', 'Width1', 'ZOffset' },
    Trail = { 'Archivable', 'Enabled', 'Name', 'Parent', 'UniqueId', 'Attachment0', 'Attachment1', 'Brightness', 'Color', 'FaceCamera', 'Lifetime', 'LightEmission', 'LightInfluence', 'MaxLength', 'MinLength', 'TextureLength', 'TextureMode', 'Transparency', 'WidthScale' },
}

for className, props in pairs(EXTRA_KNOWN_PROPERTIES) do
    local list = KNOWN_PROPERTIES[className]
    if type(list) ~= 'table' then
        list = {}
        KNOWN_PROPERTIES[className] = list
    end
    local seen = {}
    for _, p in ipairs(list) do seen[p] = true end
    for _, p in ipairs(props) do
        if not seen[p] then
            list[#list + 1] = p
            seen[p] = true
        end
    end
end

-- Properties that contain Roblox asset/content IDs.
-- These are written as <Content> values instead of ordinary strings.
local CONTENT_PROPS_BY_CLASSNAME = {
    MeshPart = { 'MeshId', 'MeshContent', 'TextureID', 'TextureId', 'TextureContent' },
    SpecialMesh = { 'MeshId', 'TextureId' },
    CharacterMesh = { 'MeshId', 'BaseTextureId', 'OverlayTextureId' },

    ParticleEmitter = { 'Texture', 'TextureContent' },
    Beam = { 'Texture', 'TextureContent' },
    Trail = { 'Texture', 'TextureContent' },

    Decal = { 'Texture', 'TextureContent' },
    Texture = { 'Texture', 'TextureContent' },
    SurfaceAppearance = {
        'ColorMap', 'ColorMapContent',
        'MetalnessMap', 'MetalnessMapContent',
        'NormalMap', 'NormalMapContent',
        'RoughnessMap', 'RoughnessMapContent',
        'EmissiveMaskContent', 'TexturePackContent',
    },
    MaterialVariant = {
        'ColorMap', 'ColorMapContent',
        'MetalnessMap', 'MetalnessMapContent',
        'NormalMap', 'NormalMapContent',
        'RoughnessMap', 'RoughnessMapContent',
        'EmissiveMaskContent',
    },

    Shirt = { 'ShirtTemplate' },
    Pants = { 'PantsTemplate' },
    ShirtGraphic = { 'Graphic' },

    ImageLabel = { 'Image', 'ImageContent' },
    ImageButton = { 'Image', 'ImageContent', 'HoverImage', 'PressedImage' },
    ImageHandleAdornment = { 'Image' },

    Tool = { 'TextureId' },
    ClickDetector = { 'CursorIcon', 'CursorIconContent' },
    DragDetector = { 'CursorIcon', 'CursorIconContent' },

    VideoFrame = { 'Video', 'VideoContent' },
    VideoPlayer = { 'VideoContent' },

    Sound = { 'SoundId', 'AudioContent' },
    AudioPlayer = { 'Asset', 'AudioContent' },
    Animation = { 'AnimationId', 'AnimationContent' },

    Sky = {
        'SkyboxBk', 'SkyboxDn', 'SkyboxFt', 'SkyboxLf', 'SkyboxRt', 'SkyboxUp',
        'SkyboxBackContent', 'SkyboxDownContent', 'SkyboxFrontContent',
        'SkyboxLeftContent', 'SkyboxRightContent', 'SkyboxUpContent',
        'SunTextureId', 'SunTextureContent', 'MoonTextureId', 'MoonTextureContent',
    },

    WrapLayer = { 'CageMeshId', 'CageMeshContent', 'ReferenceMeshId', 'ReferenceMeshContent' },
    WrapTarget = { 'CageMeshId', 'CageMeshContent' },
}

-- Numeric asset IDs use int64 in Roblox XML; writing these as floats can be ignored.
local INT64_PROPERTIES_BY_CLASSNAME = {
    HumanoidDescription = {
        BackAccessory = false, FaceAccessory = false, FrontAccessory = false, HairAccessory = false,
        HatAccessory = false, NeckAccessory = false, ShoulderAccessory = false, WaistAccessory = false,
        ClimbAnimation = true, FallAnimation = true, IdleAnimation = true, JumpAnimation = true,
        MoodAnimation = true, RunAnimation = true, SwimAnimation = true, WalkAnimation = true,
        Face = true, Head = true, LeftArm = true, LeftLeg = true, RightArm = true, RightLeg = true,
        Torso = true, GraphicTShirt = true, Pants = true, Shirt = true,
    },
    AccessoryDescription = { AssetId = true },
    BodyPartDescription = { AssetId = true },
}

local EXCLUDED_PROPERTIES = {
    Name = true,
    Parent = true,
    ClassName = true,
    UniqueId = true,
    PrimaryPart = true,
    CFrame = true,
    Size = true,
    Anchored = true,
    CanCollide = true,
    CanQuery = true,
    CanTouch = true,
    Massless = true,
    CastShadow = true,
    Locked = true,
    Transparency = true,
    Reflectance = true,
    Color = true,
    BrickColor = true,
    Material = true,
    CollisionGroupId = true,
    Velocity = true,
    AssemblyLinearVelocity = true,

    MeshId = true,
    TextureId = true,
    TextureID = true,
    MeshContent = true,
    TextureContent = true,
    MoonTextureId = true,
    SunTextureId = true,
    SkyboxUp = true,
    SkyboxRt = true,
    SkyboxLf = true,
    SkyboxFt = true,
    SkyboxDn = true,
    SkyboxBk = true,
    OverlayTextureId = true,
    MetalnessMap = true,
    RoughnessMap = true,
    NormalMap = true,
    ColorMap = true,
    Video = true,
    Image = true,
    Graphic = true,
    PantsTemplate = true,
    ShirtTemplate = true,
    Texture = true,
    AnimationId = true,
    AudioContent = true,
    SoundId = true,
}

local CLASS_HANDLERS = {}
local VALUE_BASE_HANDLERS = {}


local function createProgressBar()
    local width = 380
    local height = 18
    local yPad = 48

    local panel = Drawing.new('Square')
    panel.Filled = true
    panel.Thickness = 1
    panel.Color = Color3.new(0, 0, 0)
    panel.Transparency = 0.75
    panel.Visible = true

    local outline = Drawing.new('Square')
    outline.Filled = false
    outline.Thickness = 1
    outline.Color = Color3.new(1, 1, 1)
    outline.Visible = true

    local back = Drawing.new('Square')
    back.Filled = true
    back.Thickness = 1
    back.Color = Color3.new(0, 0, 0)
    back.Transparency = 0.55
    back.Visible = true

    local fill = Drawing.new('Square')
    fill.Filled = true
    fill.Thickness = 1
    fill.Color = Color3.new(0.2, 0.8, 0.35)
    fill.Transparency = 1
    fill.Visible = true

    local label = Drawing.new('Text')
    label.Size = 13
    label.Center = true
    label.Outline = true
    label.Color = Color3.new(1, 1, 1)
    label.Visible = true

    local function safeDestroy(obj)
        if obj then
            obj:Remove()
        end
    end

    local TEXT_Y_OFFSET = 6

    local function setLayout()
        local vp = Camera.ViewportSize
        local x = (vp.X / 2) - (width / 2)
        local y = yPad

        panel.Position = Vector2.new(x - 6, y - 6)
        panel.Size = Vector2.new(width + 12, height + 12)

        outline.Position = Vector2.new(x, y)
        outline.Size = Vector2.new(width, height)
        back.Position = Vector2.new(x + 1, y + 1)
        back.Size = Vector2.new(width - 2, height - 2)

        label.Position = Vector2.new(vp.X / 2, y + (height / 2) - (label.Size / 2) + TEXT_Y_OFFSET)
        return x, y
    end

    local x0, y0 = setLayout()

    return {
        update = function(current, total, text)
            local vp = Camera.ViewportSize
            local desiredX = (vp.X / 2) - (width / 2)
            if desiredX ~= x0 then
                x0, y0 = setLayout()
            end

            local pct = 0
            if type(total) == 'number' and total > 0 then
                pct = math.max(0, math.min(1, (current or 0) / total))
            end

            fill.Position = Vector2.new(x0 + 2, y0 + 2)
            fill.Size = Vector2.new(math.floor((width - 4) * pct), height - 4)

            if text then
                label.Text = text
            else
                label.Text = string.format('%d/%d (%.1f%%)', current or 0, total or 0, pct * 100)
            end
        end,
        destroy = function()
            safeDestroy(panel)
            safeDestroy(outline)
            safeDestroy(back)
            safeDestroy(fill)
            safeDestroy(label)
        end,
    }
end

local function createMiniConsole()
    local width = 520
    local lineHeight = 16
    local lines = 7
    local pad = 8

    local panel = Drawing.new('Square')
    panel.Filled = true
    panel.Thickness = 1
    panel.Color = Color3.new(0, 0, 0)
    panel.Transparency = 0.65
    panel.Visible = true
    panel.ZIndex = 100

    local outline = Drawing.new('Square')
    outline.Filled = false
    outline.Thickness = 1
    outline.Color = Color3.new(1, 1, 1)
    outline.Visible = true
    outline.ZIndex = 101

    local textLines = {}
    for i = 1, lines do
        local t = Drawing.new('Text')
        t.Size = 13
        t.Center = false
        t.Outline = true
        t.Color = Color3.new(1, 1, 1)
        t.Visible = true
        t.ZIndex = 102
        textLines[i] = t
    end

    local function safeDestroy(obj)
        if obj then
            obj:Remove()
        end
    end

    local function setLayout()
        local vp = Camera.ViewportSize
        local height = (lines * lineHeight) + (pad * 2)
        local x = 10
        local y = vp.Y - height - 10
        if vp.Y == nil or vp.Y < (height + 20) then
            y = 10
        end
        if vp.X ~= nil and vp.X < (width + 20) then
            x = 10
        end

        panel.Position = Vector2.new(x, y)
        panel.Size = Vector2.new(width, height)

        outline.Position = Vector2.new(x, y)
        outline.Size = Vector2.new(width, height)

        for i, t in ipairs(textLines) do
            t.Position = Vector2.new(x + pad, y + pad + ((i - 1) * lineHeight))
        end
    end

    setLayout()

    local entries = {}
    local counter = 0

    local function clipText(text)
        text = tostring(text or '')
        local fontSize = textLines[1] and textLines[1].Size or 13
        local approxCharWidth = fontSize * 0.6
        local safety = 14
        local maxChars = math.floor((width - (pad * 2) - safety) / approxCharWidth)
        if maxChars < 5 then
            return text
        end
        if #text > maxChars then
            return text:sub(1, maxChars - 3) .. '...'
        end
        return text
    end

    local function refresh()
        setLayout()
        for i = 1, lines do
            local idx = #entries - lines + i
            local text = entries[idx] or ''
            textLines[i].Text = clipText(text)
        end
    end

    return {
        log = function(text)
            counter = counter + 1
            entries[#entries + 1] = string.format('#%d %s', counter, text)
            refresh()
        end,
        setCurrent = function(text)
            counter = counter + 1
            entries[#entries + 1] = string.format('#%d %s', counter, text)
            refresh()
        end,
        done = function(text)
            counter = counter + 1
            entries[#entries + 1] = string.format('#%d %s', counter, text)
            refresh()
        end,
        destroy = function()
            safeDestroy(panel)
            safeDestroy(outline)
            for _, t in ipairs(textLines) do
                safeDestroy(t)
            end
        end,
    }
end

local function xmlEscape(value)
    local s = tostring(value)
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    s = s:gsub('"', "&quot;")
    s = s:gsub("'", "&apos;")
    return s
end

local function safeGet(inst, prop)
    local ok, v = pcall(function()
        return inst[prop]
    end)
    if ok then
        return v
    end
    return nil
end

local function buildPlayerNameSet()
    if not _G.CONFIG.excludePlayers then
        return nil
    end
    local set = {}
    local localPlayer = safeGet(Players, 'LocalPlayer')
    if localPlayer then
        local lpName = safeGet(localPlayer, 'Name')
        if type(lpName) == 'string' then
            set[lpName] = true
        end
    end
    local ok, list = pcall(function()
        return Players:GetPlayers()
    end)
    if ok and type(list) == 'table' then
        for _, player in ipairs(list) do
            local name = safeGet(player, 'Name')
            if type(name) == 'string' then
                set[name] = true
            end
        end
    end
    return set
end

local function tryDecompileScript(inst)
    if not _G.CONFIG.decompileScripts then
        return nil
    end
    local className = inst.ClassName
    if className == 'Script' then
        return 'Decompile failed: Matcha decompile method can only decompile LocalScripts and ModuleScripts)'
    end
    if className ~= 'LocalScript' and className ~= 'ModuleScript' then
        return nil
    end
    local maxAttempts = 10
    for attempt = 1, maxAttempts do
        local ok, src = pcall(decompile, inst)
        if ok and type(src) == 'string' and src ~= '' then
            if string.find(src, 'Unable to fetch', 1, true) then
                -- retry
            else
                return src
            end
        else
            return 'Decompile empty'
        end

        if attempt < maxAttempts then
            task.wait(0.1)
        end
    end
    return nil
end

local function nameMatchesPatterns(name, patterns)
    if type(patterns) ~= 'table' then
        return false
    end
    for _, pattern in ipairs(patterns) do
        if type(pattern) == 'string' and string.match(name, pattern) then
            return true
        end
    end
    return false
end

local function shouldExportInstance(inst)
    local className = inst.ClassName
    if _G.CONFIG.excludeClassNames and _G.CONFIG.excludeClassNames[className] then
        return false
    end
    if _G.CONFIG.includeClassNames and not _G.CONFIG.includeClassNames[className] then
        return false
    end

    local name = safeGet(inst, 'Name')
    if type(name) == 'string' then
        if _G.CONFIG.excludePlayers and className == 'Model' and PLAYER_NAME_SET and PLAYER_NAME_SET[name] then
            local okDesc = pcall(function()
                return inst:IsDescendantOf(Workspace)
            end)
            if okDesc then
                return false
            end
        end
        if _G.CONFIG.excludeNames and _G.CONFIG.excludeNames[name] then
            return false
        end
        if _G.CONFIG.includeNames and not _G.CONFIG.includeNames[name] then
            return false
        end
        if _G.CONFIG.excludeNamePatterns and nameMatchesPatterns(name, _G.CONFIG.excludeNamePatterns) then
            return false
        end
        if _G.CONFIG.includeNamePatterns and not nameMatchesPatterns(name, _G.CONFIG.includeNamePatterns) then
            return false
        end
    end

    return true
end

local function shouldExportService(inst)
    local name = safeGet(inst, 'Name')
    if type(name) ~= 'string' then
        return true
    end
    if _G.CONFIG.excludePlayers and name == 'Players' then
        return false
    end
    if _G.CONFIG.excludeServices and _G.CONFIG.excludeServices[name] then
        return false
    end
    if _G.CONFIG.includeServices and not _G.CONFIG.includeServices[name] then
        return false
    end
    return true
end

local function push(out, s)
    out[#out + 1] = s
end

local function writeTag(out, tagName, attrs, inner)
    if attrs then
        local keys = {}
        for k in pairs(attrs) do
            keys[#keys + 1] = k
        end
        table.sort(keys)
        local buf = { "<", tagName }
        for _, k in ipairs(keys) do
            local v = attrs[k]
            if v ~= nil then
                buf[#buf + 1] = " "
                buf[#buf + 1] = k
                buf[#buf + 1] = "=\""
                buf[#buf + 1] = xmlEscape(v)
                buf[#buf + 1] = "\""
            end
        end
        buf[#buf + 1] = ">"
        push(out, table.concat(buf))
    else
        push(out, "<" .. tagName .. ">")
    end

    if inner ~= nil then
        push(out, inner)
    end

    push(out, "</" .. tagName .. ">")
end

local function writeBool(out, name, v)
    writeTag(out, 'bool', { name = name }, v and 'true' or 'false')
end

local function writeInt(out, name, v)
    writeTag(out, 'int', { name = name }, tostring(v))
end

local function writeInt64(out, name, v)
    writeTag(out, 'int64', { name = name }, tostring(math.floor(v)))
end

local function writeFloat(out, name, v)
    writeTag(out, 'float', { name = name }, tostring(v))
end

local function writeDouble(out, name, v)
    writeTag(out, 'double', { name = name }, tostring(v))
end

local function writeString(out, name, v)
    writeTag(out, 'string', { name = name }, xmlEscape(v))
end

local function normalizeAssetUrl(v)
    if v == nil then
        return nil
    end

    local t = type(v)
    if t == 'string' then
        if v == '' then
            return nil
        end
        return v
    end

    if t == 'number' then
        return 'rbxassetid://' .. tostring(math.floor(v))
    end

    local uri = safeGet(v, 'Uri') or safeGet(v, 'URI') or safeGet(v, 'uri')
    if uri ~= nil then
        return normalizeAssetUrl(uri)
    end

    local value = safeGet(v, 'Value') or safeGet(v, 'value')
    if value ~= nil then
        return normalizeAssetUrl(value)
    end

    local id = safeGet(v, 'Id') or safeGet(v, 'id')
    if id ~= nil then
        return normalizeAssetUrl(id)
    end

    local s = tostring(v)
    if s:find('rbxasset', 1, true) or s:find('http://', 1, true) or s:find('https://', 1, true) then
        return s
    end
    return nil
end

local function writeContent(out, name, url)
    local normalized = normalizeAssetUrl(url)
    if normalized == nil then
        return
    end
    push(out, '<Content name="' .. xmlEscape(name) .. '">')
    push(out, '<url>' .. xmlEscape(normalized) .. '</url>')
    push(out, '</Content>')
end

local function writeBrickColor(out, name, bc)
    if bc == nil then
        return
    end
    local number = safeGet(bc, 'Number')
    if type(number) == 'number' then
        writeTag(out, 'BrickColor', { name = name }, tostring(math.floor(number)))
        return
    end
    local bcName = safeGet(bc, 'Name')
    if type(bcName) == 'string' then
        writeTag(out, 'BrickColor', { name = name }, xmlEscape(bcName))
        return
    end
end

local function writeVector3(out, name, v)
    if v == nil then
        return
    end
    local x, y, z = v.X, v.Y, v.Z
    if x == nil or y == nil or z == nil then
        return
    end
    push(out, '<Vector3 name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'X', nil, tostring(x))
    writeTag(out, 'Y', nil, tostring(y))
    writeTag(out, 'Z', nil, tostring(z))
    push(out, '</Vector3>')
end

local function writeColor3(out, name, v)
    if v == nil then
        return
    end
    local r, g, b = v.R, v.G, v.B
    if r == nil or g == nil or b == nil then
        return
    end

    local maxc = math.max(tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0)
    if maxc > 1.001 then
        if maxc <= 255 then
            r, g, b = r / 255, g / 255, b / 255
        end
    end

    local function clamp01(x)
        x = tonumber(x) or 0
        if x < 0 then return 0 end
        if x > 1 then return 1 end
        return x
    end
    r, g, b = clamp01(r), clamp01(g), clamp01(b)

    push(out, '<Color3 name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'R', nil, tostring(r))
    writeTag(out, 'G', nil, tostring(g))
    writeTag(out, 'B', nil, tostring(b))
    push(out, '</Color3>')
end

local function writeCoordinateFrame(out, name, cf, fallbackPos, fallbackOrientation)
    local ok, x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = pcall(function()
        if cf == nil then
            return nil
        end
        if type(cf.GetComponents) == 'function' then
            return cf:GetComponents()
        end
        return cf:components()
    end)

    local function hasFallbackPos()
        return fallbackPos ~= nil and fallbackPos.X ~= nil and fallbackPos.Y ~= nil and fallbackPos.Z ~= nil
    end

    if (not ok) or x == nil then
        if not hasFallbackPos() then
            return
        end
        x, y, z = fallbackPos.X, fallbackPos.Y, fallbackPos.Z
        r00, r01, r02 = 1, 0, 0
        r10, r11, r12 = 0, 1, 0
        r20, r21, r22 = 0, 0, 1
    end

    if hasFallbackPos() and tonumber(x) == 0 and tonumber(y) == 0 and tonumber(z) == 0 then
        if fallbackPos.X ~= 0 or fallbackPos.Y ~= 0 or fallbackPos.Z ~= 0 then
            x, y, z = fallbackPos.X, fallbackPos.Y, fallbackPos.Z
        end
    end

    local function rotValid(a, b, c, d, e, f, g, h, i)
        if a == nil or b == nil or c == nil or d == nil or e == nil or f == nil or g == nil or h == nil or i == nil then
            return false
        end
        local s = math.abs(a) + math.abs(b) + math.abs(c) + math.abs(d) + math.abs(e) + math.abs(f) + math.abs(g) + math.abs(h) + math.abs(i)
        return s > 0.5
    end

    if not rotValid(r00, r01, r02, r10, r11, r12, r20, r21, r22) then
        local o = fallbackOrientation
        if o ~= nil and o.X ~= nil and o.Y ~= nil and o.Z ~= nil then
            local rx = math.rad(o.X)
            local ry = math.rad(o.Y)
            local rz = math.rad(o.Z)
            local cx, sx = math.cos(rx), math.sin(rx)
            local cy, sy = math.cos(ry), math.sin(ry)
            local cz, sz = math.cos(rz), math.sin(rz)

            r00 = cz * cy
            r01 = cz * sy * sx - sz * cx
            r02 = cz * sy * cx + sz * sx

            r10 = sz * cy
            r11 = sz * sy * sx + cz * cx
            r12 = sz * sy * cx - cz * sx

            r20 = -sy
            r21 = cy * sx
            r22 = cy * cx
        else
            r00, r01, r02 = 1, 0, 0
            r10, r11, r12 = 0, 1, 0
            r20, r21, r22 = 0, 0, 1
        end
    end

    push(out, '<CoordinateFrame name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'X', nil, tostring(x))
    writeTag(out, 'Y', nil, tostring(y))
    writeTag(out, 'Z', nil, tostring(z))
    writeTag(out, 'R00', nil, tostring(r00))
    writeTag(out, 'R01', nil, tostring(r01))
    writeTag(out, 'R02', nil, tostring(r02))
    writeTag(out, 'R10', nil, tostring(r10))
    writeTag(out, 'R11', nil, tostring(r11))
    writeTag(out, 'R12', nil, tostring(r12))
    writeTag(out, 'R20', nil, tostring(r20))
    writeTag(out, 'R21', nil, tostring(r21))
    writeTag(out, 'R22', nil, tostring(r22))
    push(out, '</CoordinateFrame>')
end

local function writeToken(out, name, v)
    writeTag(out, 'token', { name = name }, tostring(v))
end

local function writeRef(out, name, referent)
    writeTag(out, 'Ref', { name = name }, referent or 'null')
end

local function writeVector2(out, name, v)
    if v == nil then return end
    local x, y = safeGet(v, 'X'), safeGet(v, 'Y')
    if type(x) ~= 'number' or type(y) ~= 'number' then return end
    push(out, '<Vector2 name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'X', nil, tostring(x))
    writeTag(out, 'Y', nil, tostring(y))
    push(out, '</Vector2>')
end

local function writeNumberRange(out, name, v)
    local minV, maxV = safeGet(v, 'Min'), safeGet(v, 'Max')
    if type(minV) ~= 'number' or type(maxV) ~= 'number' then return end
    writeTag(out, 'NumberRange', { name = name }, tostring(minV) .. ' ' .. tostring(maxV) .. ' ')
end

local function writeNumberSequence(out, name, v)
    local keypoints = safeGet(v, 'Keypoints')
    if type(keypoints) ~= 'table' then return end
    local parts = {}
    for _, kp in ipairs(keypoints) do
        local t = safeGet(kp, 'Time')
        local value = safeGet(kp, 'Value')
        local envelope = safeGet(kp, 'Envelope') or 0
        if type(t) == 'number' and type(value) == 'number' and type(envelope) == 'number' then
            parts[#parts + 1] = tostring(t)
            parts[#parts + 1] = tostring(value)
            parts[#parts + 1] = tostring(envelope)
        end
    end
    if #parts > 0 then
        writeTag(out, 'NumberSequence', { name = name }, table.concat(parts, ' ') .. ' ')
    end
end

local function writeColorSequence(out, name, v)
    local keypoints = safeGet(v, 'Keypoints')
    if type(keypoints) ~= 'table' then return end
    local parts = {}
    for _, kp in ipairs(keypoints) do
        local t = safeGet(kp, 'Time')
        local value = safeGet(kp, 'Value')
        local r = value and safeGet(value, 'R')
        local g = value and safeGet(value, 'G')
        local b = value and safeGet(value, 'B')
        local envelope = safeGet(kp, 'Envelope') or 0
        if type(t) == 'number' and type(r) == 'number' and type(g) == 'number' and type(b) == 'number' then
            parts[#parts + 1] = tostring(t)
            parts[#parts + 1] = tostring(r)
            parts[#parts + 1] = tostring(g)
            parts[#parts + 1] = tostring(b)
            parts[#parts + 1] = tostring(type(envelope) == 'number' and envelope or 0)
        end
    end
    if #parts > 0 then
        writeTag(out, 'ColorSequence', { name = name }, table.concat(parts, ' ') .. ' ')
    end
end

local function writeUDim(out, name, v)
    local scale, offset = safeGet(v, 'Scale'), safeGet(v, 'Offset')
    if type(scale) ~= 'number' or type(offset) ~= 'number' then return end
    push(out, '<UDim name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'S', nil, tostring(scale))
    writeTag(out, 'O', nil, tostring(math.floor(offset)))
    push(out, '</UDim>')
end

local function writeUDim2(out, name, v)
    local x, y = safeGet(v, 'X'), safeGet(v, 'Y')
    if x == nil or y == nil then return end
    local xs, xo = safeGet(x, 'Scale'), safeGet(x, 'Offset')
    local ys, yo = safeGet(y, 'Scale'), safeGet(y, 'Offset')
    if type(xs) ~= 'number' or type(xo) ~= 'number' or type(ys) ~= 'number' or type(yo) ~= 'number' then return end
    push(out, '<UDim2 name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'XS', nil, tostring(xs))
    writeTag(out, 'XO', nil, tostring(math.floor(xo)))
    writeTag(out, 'YS', nil, tostring(ys))
    writeTag(out, 'YO', nil, tostring(math.floor(yo)))
    push(out, '</UDim2>')
end

local function writeRect(out, name, v)
    local minV, maxV = safeGet(v, 'Min'), safeGet(v, 'Max')
    if minV == nil or maxV == nil then return end
    local minX, minY = safeGet(minV, 'X'), safeGet(minV, 'Y')
    local maxX, maxY = safeGet(maxV, 'X'), safeGet(maxV, 'Y')
    if type(minX) ~= 'number' or type(minY) ~= 'number' or type(maxX) ~= 'number' or type(maxY) ~= 'number' then return end
    push(out, '<Rect2D name="' .. xmlEscape(name) .. '">')
    push(out, '<min>')
    writeTag(out, 'X', nil, tostring(minX))
    writeTag(out, 'Y', nil, tostring(minY))
    push(out, '</min>')
    push(out, '<max>')
    writeTag(out, 'X', nil, tostring(maxX))
    writeTag(out, 'Y', nil, tostring(maxY))
    push(out, '</max>')
    push(out, '</Rect2D>')
end

local function writePhysicalProperties(out, name, v)
    if v == nil then return end
    local density = safeGet(v, 'Density')
    local friction = safeGet(v, 'Friction')
    local elasticity = safeGet(v, 'Elasticity')
    local frictionWeight = safeGet(v, 'FrictionWeight')
    local elasticityWeight = safeGet(v, 'ElasticityWeight')
    if type(density) ~= 'number' then return end
    push(out, '<PhysicalProperties name="' .. xmlEscape(name) .. '">')
    writeTag(out, 'CustomPhysics', nil, 'true')
    writeTag(out, 'Density', nil, tostring(density))
    writeTag(out, 'Friction', nil, tostring(friction or 0))
    writeTag(out, 'Elasticity', nil, tostring(elasticity or 0))
    writeTag(out, 'FrictionWeight', nil, tostring(frictionWeight or 0))
    writeTag(out, 'ElasticityWeight', nil, tostring(elasticityWeight or 0))
    push(out, '</PhysicalProperties>')
end

local function writeFont(out, name, v)
    if v == nil then return end
    local family = safeGet(v, 'Family')
    local weight = safeGet(v, 'Weight')
    local style = safeGet(v, 'Style')
    local cachedFaceId = safeGet(v, 'CachedFaceId')
    push(out, '<Font name="' .. xmlEscape(name) .. '">')

    local familyUrl = normalizeAssetUrl(family)
    if familyUrl ~= nil then
        push(out, '<Family><url>' .. xmlEscape(familyUrl) .. '</url></Family>')
    end

    local wv = weight and safeGet(weight, 'Value')
    if type(wv) ~= 'number' and type(weight) == 'number' then wv = weight end
    if type(wv) == 'number' then writeTag(out, 'Weight', nil, tostring(math.floor(wv))) end

    local styleName = style and safeGet(style, 'Name')
    if type(styleName) ~= 'string' then
        local sv = style and safeGet(style, 'Value')
        styleName = (sv == 1) and 'Italic' or 'Normal'
    end
    writeTag(out, 'Style', nil, xmlEscape(styleName))

    local cachedUrl = normalizeAssetUrl(cachedFaceId)
    if cachedUrl ~= nil then
        push(out, '<CachedFaceId><url>' .. xmlEscape(cachedUrl) .. '</url></CachedFaceId>')
    end
    push(out, '</Font>')
end

local function getRobloxType(v)
    local ok, result = pcall(function()
        if typeof then return typeof(v) end
        return nil
    end)
    return ok and result or nil
end

local function writeAny(out, name, v, state)
    if v == nil then return end

    local rtype = getRobloxType(v)

    if rtype == 'Content' then writeContent(out, name, v); return end
    if rtype == 'EnumItem' then
        local ev = safeGet(v, 'Value')
        if type(ev) == 'number' then writeToken(out, name, ev) end
        return
    end
    if rtype == 'Instance' then
        local ref = state and state.referentOf and state.referentOf[v] or nil
        writeRef(out, name, ref)
        return
    end
    if rtype == 'CFrame' then writeCoordinateFrame(out, name, v); return end
    if rtype == 'Vector3' then writeVector3(out, name, v); return end
    if rtype == 'Vector2' then writeVector2(out, name, v); return end
    if rtype == 'Color3' then writeColor3(out, name, v); return end
    if rtype == 'BrickColor' then writeBrickColor(out, name, v); return end
    if rtype == 'NumberRange' then writeNumberRange(out, name, v); return end
    if rtype == 'NumberSequence' then writeNumberSequence(out, name, v); return end
    if rtype == 'ColorSequence' then writeColorSequence(out, name, v); return end
    if rtype == 'UDim' then writeUDim(out, name, v); return end
    if rtype == 'UDim2' then writeUDim2(out, name, v); return end
    if rtype == 'Rect' then writeRect(out, name, v); return end
    if rtype == 'PhysicalProperties' then writePhysicalProperties(out, name, v); return end
    if rtype == 'Font' then writeFont(out, name, v); return end

    local tv = type(v)
    if tv == 'boolean' then writeBool(out, name, v); return end
    if tv == 'number' then writeFloat(out, name, v); return end
    if tv == 'string' then writeString(out, name, v); return end

    -- Fallbacks for executors where typeof() is incomplete.
    local enumValue = safeGet(v, 'Value')
    if type(enumValue) == 'number' and safeGet(v, 'EnumType') ~= nil then
        writeToken(out, name, enumValue)
        return
    end

    local className = safeGet(v, 'ClassName')
    if state and state.referentOf and type(className) == 'string' then
        writeRef(out, name, state.referentOf[v])
        return
    end

    local okCf = pcall(function()
        if type(v.GetComponents) == 'function' then return v:GetComponents() end
        return v:components()
    end)
    if okCf then writeCoordinateFrame(out, name, v); return end

    local x, y, z = safeGet(v, 'X'), safeGet(v, 'Y'), safeGet(v, 'Z')
    if type(x) == 'number' and type(y) == 'number' and type(z) == 'number' then
        writeVector3(out, name, v)
        return
    end

    local r, g, b = safeGet(v, 'R'), safeGet(v, 'G'), safeGet(v, 'B')
    if type(r) == 'number' and type(g) == 'number' and type(b) == 'number' then
        writeColor3(out, name, v)
        return
    end

    -- Unknown userdata is intentionally skipped instead of writing a bogus string
    -- that Roblox will reject for the actual property type.
end

local function isContentProperty(className, prop)
    local list = CONTENT_PROPS_BY_CLASSNAME[className]
    if type(list) ~= 'table' then return false end
    for _, p in ipairs(list) do
        if p == prop then return true end
    end
    return false
end

local function isInt64Property(className, prop)
    local map = INT64_PROPERTIES_BY_CLASSNAME[className]
    return type(map) == 'table' and map[prop] == true
end

local function writeContentProps(out, inst, className)
    local list = CONTENT_PROPS_BY_CLASSNAME[className]
    if not list then return end
    for _, prop in ipairs(list) do
        writeContent(out, prop, safeGet(inst, prop))
    end
end

local function writeSpecProperties(out, inst, state)
    local list = KNOWN_PROPERTIES[inst.ClassName]
    if type(list) ~= 'table' then return end
    for _, prop in ipairs(list) do
        if not EXCLUDED_PROPERTIES[prop] and not isContentProperty(inst.ClassName, prop) then
            local v = safeGet(inst, prop)
            if isInt64Property(inst.ClassName, prop) then
                if type(v) == 'number' then writeInt64(out, prop, v) end
            else
                writeAny(out, prop, v, state)
            end
        end
    end
end

-- Some executors expose getproperties(instance). If present, use it as a bonus
-- discovery layer for properties not covered by the static API list above.
local function getPropertyEnumerator()
    local candidates = {}
    local ok, env = pcall(function()
        if type(getgenv) == 'function' then return getgenv() end
        return nil
    end)
    if ok and type(env) == 'table' then candidates[#candidates + 1] = env end
    candidates[#candidates + 1] = _G
    for _, e in ipairs(candidates) do
        local f = rawget(e, 'getproperties')
        if type(f) == 'function' then return f end
    end
    return nil
end

local PROPERTY_ENUMERATOR = getPropertyEnumerator()

local BASEPART_MANUAL = {
    CFrame=true, Size=true, Anchored=true, CanCollide=true, CanQuery=true, CanTouch=true,
    Massless=true, CastShadow=true, Locked=true, Transparency=true, Reflectance=true,
    Color=true, BrickColor=true, CollisionGroupId=true, Material=true, Velocity=true,
    AssemblyLinearVelocity=true,
}

local function staticallyHandled(inst, prop)
    if prop == 'Name' or prop == 'Parent' or prop == 'ClassName' or prop == 'UniqueId' then return true end
    if isContentProperty(inst.ClassName, prop) or isInt64Property(inst.ClassName, prop) then return true end
    if inst:IsA('BasePart') and BASEPART_MANUAL[prop] then return true end
    local list = KNOWN_PROPERTIES[inst.ClassName]
    if type(list) == 'table' then
        for _, p in ipairs(list) do if p == prop then return true end end
    end
    if inst:IsA('ValueBase') and prop == 'Value' then return true end
    return false
end

local function writeDynamicProperties(out, inst, state)
    if type(PROPERTY_ENUMERATOR) ~= 'function' then return end
    local ok, props = pcall(PROPERTY_ENUMERATOR, inst)
    if not ok or type(props) ~= 'table' then return end

    local names = {}
    for k, v in pairs(props) do
        if type(k) == 'string' then
            names[#names + 1] = k
        elseif type(v) == 'string' then
            names[#names + 1] = v
        end
    end
    table.sort(names)

    local seen = {}
    for _, prop in ipairs(names) do
        if not seen[prop] and not staticallyHandled(inst, prop) then
            seen[prop] = true
            local v = safeGet(inst, prop)
            if v ~= nil then
                -- Conservative asset-name heuristic for newly-added Roblox content properties.
                local lower = string.lower(prop)
                local looksContent = lower:find('texture', 1, true)
                    or lower:find('content', 1, true)
                    or lower:find('image', 1, true)
                    or lower:find('animationid', 1, true)
                    or lower:find('soundid', 1, true)
                    or lower:find('meshid', 1, true)
                    or lower:find('cursoricon', 1, true)
                    or lower:find('colormap', 1, true)
                    or lower:find('normalmap', 1, true)
                    or lower:find('roughnessmap', 1, true)
                    or lower:find('metalnessmap', 1, true)
                if looksContent then
                    local normalized = normalizeAssetUrl(v)
                    if normalized ~= nil then
                        writeContent(out, prop, v)
                    else
                        writeAny(out, prop, v, state)
                    end
                else
                    writeAny(out, prop, v, state)
                end
            end
        end
    end
end

local function writeBasePartProperties(out, inst)
    local posFallback = safeGet(inst, 'Position')
    writeCoordinateFrame(out, 'CFrame', safeGet(inst, 'CFrame'), posFallback, safeGet(inst, 'Orientation'))
    writeVector3(out, 'Size', safeGet(inst, 'Size'))

    writeBool(out, 'Anchored', safeGet(inst, 'Anchored'))
    writeBool(out, 'CanCollide', safeGet(inst, 'CanCollide'))
    writeBool(out, 'CanQuery', safeGet(inst, 'CanQuery'))
    writeBool(out, 'CanTouch', safeGet(inst, 'CanTouch'))
    writeBool(out, 'Massless', safeGet(inst, 'Massless'))
    writeBool(out, 'CastShadow', safeGet(inst, 'CastShadow'))
    writeBool(out, 'Locked', safeGet(inst, 'Locked'))

    writeFloat(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeFloat(out, 'Reflectance', safeGet(inst, 'Reflectance'))

    writeColor3(out, 'Color', safeGet(inst, 'Color'))
    writeBrickColor(out, 'BrickColor', safeGet(inst, 'BrickColor'))

    local cgid = safeGet(inst, 'CollisionGroupId')
    if type(cgid) == 'number' then
        writeInt(out, 'CollisionGroupId', math.floor(cgid))
    end

    local mat = safeGet(inst, 'Material')
    local matValue = safeGet(mat, 'Value')
    if type(matValue) == 'number' then
        writeToken(out, 'Material', matValue)
    end

    writeVector3(out, 'Velocity', safeGet(inst, 'Velocity'))
    writeVector3(out, 'AssemblyLinearVelocity', safeGet(inst, 'AssemblyLinearVelocity'))
end

CLASS_HANDLERS.MeshPart = function(out, inst, _state)
end

CLASS_HANDLERS.Decal = function(out, inst, _state)

    writeFloat(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeColor3(out, 'Color3', safeGet(inst, 'Color3'))

    local face = safeGet(inst, 'Face')
    local faceValue = safeGet(face, 'Value')
    if type(faceValue) == 'number' then
        writeToken(out, 'Face', faceValue)
    end
end

CLASS_HANDLERS.Texture = function(out, inst, _state)
    writeFloat(out, 'StudsPerTileU', safeGet(inst, 'StudsPerTileU'))
    writeFloat(out, 'StudsPerTileV', safeGet(inst, 'StudsPerTileV'))

    writeFloat(out, 'Transparency', safeGet(inst, 'Transparency'))
    writeColor3(out, 'Color3', safeGet(inst, 'Color3'))

    local face = safeGet(inst, 'Face')
    local faceValue = safeGet(face, 'Value')
    if type(faceValue) == 'number' then
        writeToken(out, 'Face', faceValue)
    end
end

CLASS_HANDLERS.ParticleEmitter = function(out, inst, _state)
end

CLASS_HANDLERS.SpecialMesh = function(out, inst, _state)
end

CLASS_HANDLERS.CharacterMesh = function(out, inst, _state)
    local bp = safeGet(inst, 'BodyPart')
    local bpValue = safeGet(bp, 'Value')
    if type(bpValue) == 'number' then
        writeToken(out, 'BodyPart', bpValue)
    end
end

CLASS_HANDLERS.SurfaceAppearance = function(out, inst, _state)
end

CLASS_HANDLERS.Shirt = function(out, inst, _state)
end

CLASS_HANDLERS.Pants = function(out, inst, _state)
end

CLASS_HANDLERS.ShirtGraphic = function(out, inst, _state)
end

CLASS_HANDLERS.ImageLabel = function(out, inst, _state)
end

CLASS_HANDLERS.ImageButton = function(out, inst, _state)
end

CLASS_HANDLERS.Motor6D = function(out, inst, state)
    writeCoordinateFrame(out, 'C0', safeGet(inst, 'C0'))
    writeCoordinateFrame(out, 'C1', safeGet(inst, 'C1'))
    writeCoordinateFrame(out, 'Transform', safeGet(inst, 'Transform'))

    local p0 = safeGet(inst, 'Part0')
    local p1 = safeGet(inst, 'Part1')
    if state and state.referentOf then
        writeRef(out, 'Part0', state.referentOf[p0])
        writeRef(out, 'Part1', state.referentOf[p1])
    end

    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
end

CLASS_HANDLERS.Weld = function(out, inst, state)
    writeCoordinateFrame(out, 'C0', safeGet(inst, 'C0'))
    writeCoordinateFrame(out, 'C1', safeGet(inst, 'C1'))

    local p0 = safeGet(inst, 'Part0')
    local p1 = safeGet(inst, 'Part1')
    if state and state.referentOf then
        writeRef(out, 'Part0', state.referentOf[p0])
        writeRef(out, 'Part1', state.referentOf[p1])
    end

    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
end

CLASS_HANDLERS.WeldConstraint = function(out, inst, state)
    local p0 = safeGet(inst, 'Part0')
    local p1 = safeGet(inst, 'Part1')
    if state and state.referentOf then
        writeRef(out, 'Part0', state.referentOf[p0])
        writeRef(out, 'Part1', state.referentOf[p1])
    end
    writeBool(out, 'Enabled', safeGet(inst, 'Enabled'))
end

CLASS_HANDLERS.Attachment = function(out, inst, _state)
    writeCoordinateFrame(out, 'CFrame', safeGet(inst, 'CFrame'))
    writeVector3(out, 'Axis', safeGet(inst, 'Axis'))
    writeVector3(out, 'SecondaryAxis', safeGet(inst, 'SecondaryAxis'))
end

CLASS_HANDLERS.Accessory = function(out, inst, _state)
    writeCoordinateFrame(out, 'AttachmentPoint', safeGet(inst, 'AttachmentPoint'))
    local at = safeGet(inst, 'AccessoryType')
    local atValue = safeGet(at, 'Value')
    if type(atValue) == 'number' then
        writeToken(out, 'AccessoryType', atValue)
    end
end

CLASS_HANDLERS.TextLabel = function(out, inst, _state)
    writeString(out, 'Text', safeGet(inst, 'Text'))
end

local function writeScriptSource(out, inst)
    local src = tryDecompileScript(inst)
    if src then
        local name = safeGet(inst, 'Name') or 'Script'
        writeString(out, 'Source', src)
    end
end

CLASS_HANDLERS.LocalScript = function(out, inst, _state)
    writeScriptSource(out, inst)
end

CLASS_HANDLERS.ModuleScript = function(out, inst, _state)
    writeScriptSource(out, inst)
end

CLASS_HANDLERS.Script = function(out, inst, _state)
    writeScriptSource(out, inst)
end

CLASS_HANDLERS.BodyColors = function(out, inst, _state)
    writeBrickColor(out, 'HeadColor', safeGet(inst, 'HeadColor'))
    writeBrickColor(out, 'LeftArmColor', safeGet(inst, 'LeftArmColor'))
    writeBrickColor(out, 'RightArmColor', safeGet(inst, 'RightArmColor'))
    writeBrickColor(out, 'LeftLegColor', safeGet(inst, 'LeftLegColor'))
    writeBrickColor(out, 'RightLegColor', safeGet(inst, 'RightLegColor'))
    writeBrickColor(out, 'TorsoColor', safeGet(inst, 'TorsoColor'))
    writeColor3(out, 'HeadColor3', safeGet(inst, 'HeadColor3'))
    writeColor3(out, 'LeftArmColor3', safeGet(inst, 'LeftArmColor3'))
    writeColor3(out, 'RightArmColor3', safeGet(inst, 'RightArmColor3'))
    writeColor3(out, 'LeftLegColor3', safeGet(inst, 'LeftLegColor3'))
    writeColor3(out, 'RightLegColor3', safeGet(inst, 'RightLegColor3'))
    writeColor3(out, 'TorsoColor3', safeGet(inst, 'TorsoColor3'))
end

CLASS_HANDLERS.Model = function(out, inst, state)
    if not state or not state.referentOf then
        return
    end
    local pp = safeGet(inst, 'PrimaryPart')
    if pp ~= nil then
        writeRef(out, 'PrimaryPart', state.referentOf[pp])
    end
end

VALUE_BASE_HANDLERS.ObjectValue = function(out, _inst, state, v)
    local ref = state.referentOf[v]
    writeRef(out, 'Value', ref)
end

VALUE_BASE_HANDLERS.BoolValue = function(out, _inst, _state, v)
    writeBool(out, 'Value', v)
end

VALUE_BASE_HANDLERS.IntValue = function(out, _inst, _state, v)
    if type(v) == 'number' then
        writeInt(out, 'Value', math.floor(v))
    end
end

VALUE_BASE_HANDLERS.NumberValue = function(out, _inst, _state, v)
    if type(v) == 'number' then
        writeDouble(out, 'Value', v)
    end
end

VALUE_BASE_HANDLERS.FloatValue = function(out, _inst, _state, v)
    if type(v) == 'number' then
        writeDouble(out, 'Value', v)
    end
end

VALUE_BASE_HANDLERS.StringValue = function(out, _inst, _state, v)
    writeString(out, 'Value', v)
end

VALUE_BASE_HANDLERS.Color3Value = function(out, _inst, _state, v)
    writeColor3(out, 'Value', v)
end

local function writeKnownProperties(out, inst, state)
    writeAny(out, 'Name', safeGet(inst, 'Name'), state)

    if inst:IsA('BasePart') then
        writeBasePartProperties(out, inst)
    end

    -- Asset/content properties are handled centrally so a class does not need
    -- a dedicated CLASS_HANDLER just to preserve its asset IDs (for example
    -- Sound.SoundId or Animation.AnimationId).
    writeContentProps(out, inst, inst.ClassName)

    local classHandler = CLASS_HANDLERS[inst.ClassName]
    if classHandler then
        classHandler(out, inst, state)
    end

    writeSpecProperties(out, inst, state)
    writeDynamicProperties(out, inst, state)
end

local function writeValueBaseValue(out, inst, state)
    if not inst:IsA('ValueBase') then
        return
    end

    local v = safeGet(inst, 'Value')
    if v == nil then
        return
    end

    local handler = VALUE_BASE_HANDLERS[inst.ClassName]
    if handler then
        handler(out, inst, state, v)
        return
    end

    writeAny(out, 'Value', v)
end

local function writeItem(out, inst, state)
    if state.visited[inst] then
        return
    end
    state.visited[inst] = true

    if not shouldExportInstance(inst) then
        if _G.CONFIG.includeChildrenOfFiltered then
            for _, child in ipairs(inst:GetChildren()) do
                writeItem(out, child, state)
            end
        end
        return
    end

    state.processed = (state.processed or 0) + 1
    if state.progress then
        local every = state.progressEvery or 25
        if (state.processed == 1) or (state.processed % every == 0) or (state.processed == state.total) then
            state.progress.update(
                state.processed,
                state.total,
                string.format('Exporting %d/%d (%.1f%%)', state.processed, state.total, (state.total > 0 and (state.processed / state.total) or 0) * 100)
            )
            if state.console then
                local name = safeGet(inst, 'Name')
                local className = inst.ClassName
                state.console.setCurrent(string.format('Exporting: %s (%s)', name or '?', className))
            end
        end
    end

    local referent = state.referentOf[inst]
    if referent == nil then
        state.dynamicId = (state.dynamicId or state.total or 0) + 1
        referent = 'RBX' .. tostring(state.dynamicId)
        state.referentOf[inst] = referent
    end

    local className = inst.ClassName
    push(out, "<Item class=\"" .. xmlEscape(className) .. "\" referent=\"" .. referent .. "\">")
    push(out, "<Properties>")
    writeKnownProperties(out, inst, state)

    writeValueBaseValue(out, inst, state)

    push(out, "</Properties>")

    for _, child in ipairs(inst:GetChildren()) do
        writeItem(out, child, state)
    end

    push(out, "</Item>")
end

local function exportToXml(root)
    local out = {}
    PLAYER_NAME_SET = buildPlayerNameSet()
    push(out, "<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    push(out, '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">')
    push(out, '<External>null</External>')
    local pb = createProgressBar()
    local console = _G.CONFIG.showConsole and createMiniConsole() or nil
    pb.update(0, 1, 'Indexing instances...')
    if console then
        console.log('Indexing instances...')
    end

    local referentOf = {}
    local visited = {}
    local ordered = {}
    local function collect(inst)
        if visited[inst] then
            return
        end
        visited[inst] = true
        if not shouldExportInstance(inst) then
            if _G.CONFIG.includeChildrenOfFiltered then
                for _, child in ipairs(inst:GetChildren()) do
                    collect(child)
                end
            end
            return
        end
        ordered[#ordered + 1] = inst
        for _, child in ipairs(inst:GetChildren()) do
            collect(child)
        end
    end

    local exportRoots = root:GetChildren()
    for _, child in ipairs(exportRoots) do
        if shouldExportService(child) then
            collect(child)
        elseif _G.CONFIG.includeChildrenOfFiltered then
            for _, grandChild in ipairs(child:GetChildren()) do
                collect(grandChild)
            end
        end
    end

    for i, inst in ipairs(ordered) do
        referentOf[inst] = 'RBX' .. tostring(i)
    end

    local total = #ordered
    pb.update(0, total, string.format('Exporting 0/%d (0.0%%)', total))

    local state = {
        visited = {},
        processed = 0,
        total = total,
        progress = pb,
        console = console,
        progressEvery = 25,
        referentOf = referentOf,
    }

    for _, child in ipairs(root:GetChildren()) do
        if shouldExportService(child) then
            writeItem(out, child, state)
        elseif _G.CONFIG.includeChildrenOfFiltered then
            for _, grandChild in ipairs(child:GetChildren()) do
                writeItem(out, grandChild, state)
            end
        end
    end
    push(out, "</roblox>")

    pb.update(total, total, 'Done')
    if console then
        console.done('Finished export')
    end
    pb.destroy()
    if console then
        console.destroy()
    end

    return table.concat(out, "\n")
end

local xml = exportToXml(_G.CONFIG.root)

setclipboard(xml)
