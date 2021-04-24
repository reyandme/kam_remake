object FormMain: TFormMain
  Left = 221
  Top = 419
  HelpType = htKeyword
  BorderStyle = bsNone
  ClientHeight = 785
  ClientWidth = 521
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poDesigned
  Scaled = False
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnKeyUp = FormKeyUp
  OnMouseWheel = FormMouseWheel
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar1: TStatusBar
    Left = 0
    Top = 765
    Width = 521
    Height = 20
    Panels = <
      item
        Text = 'KMR r7000+ / OpenGL 4.0.0 - Build 9.99.99.99999'
        Width = 275
      end
      item
        Text = 'Map size: 999x999'
        Width = 110
      end
      item
        Text = 'Cursor: 1999:1999'
        Width = 105
      end
      item
        Text = 'Tile: 999.9:999.9 [999:999]'
        Width = 140
      end
      item
        Text = 'Time: 99:99:99'
        Width = 90
      end
      item
        Text = '999.9 FPS (999)'
        Width = 85
      end
      item
        Text = 'Obj: 99999999'
        Width = 90
      end
      item
        Text = 'Control ID: 9999'
        Width = 80
      end>
  end
  object mainGroup: TCategoryPanelGroup
    Left = 261
    Top = 0
    Width = 260
    Height = 765
    VertScrollBar.Tracking = True
    Align = alRight
    DoubleBuffered = False
    HeaderFont.Charset = DEFAULT_CHARSET
    HeaderFont.Color = clWindowText
    HeaderFont.Height = -11
    HeaderFont.Name = 'Tahoma'
    HeaderFont.Style = []
    HeaderHeight = 18
    HeaderStyle = hsThemed
    ParentDoubleBuffered = False
    TabOrder = 1
    object cpMisc: TCategoryPanel
      Top = 337
      Height = 24
      Caption = 'Misc'
      Collapsed = True
      TabOrder = 0
      ExpandedHeight = 144
      object chkBevel: TCheckBox
        Left = 168
        Top = 100
        Width = 88
        Height = 17
        Caption = 'Bevel'
        Checked = True
        State = cbChecked
        TabOrder = 0
        OnClick = ControlsUpdate
      end
      object rgDebugFont: TRadioGroup
        Left = 8
        Top = 8
        Width = 209
        Height = 85
        Caption = 'Debug Font'
        Columns = 2
        Ctl3D = True
        ItemIndex = 7
        Items.Strings = (
          'fntAntiqua'
          'fntGame'
          'fntGrey'
          'fntMetal'
          'fntMini'
          'fntOutline'
          'fntArial'
          'fntMonospaced')
        ParentCtl3D = False
        TabOrder = 1
        OnClick = ControlsUpdate
        OnExit = radioGroupExit
      end
    end
    object cpLogs: TCategoryPanel
      Top = 313
      Height = 24
      Caption = 'Logs'
      Collapsed = True
      TabOrder = 1
      ExpandedHeight = 198
      object chkLogCommands: TCheckBox
        Left = 120
        Top = 8
        Width = 97
        Height = 17
        Caption = 'GIP commands'
        TabOrder = 0
        OnClick = ControlsUpdate
      end
      object chkLogDelivery: TCheckBox
        Left = 8
        Top = 8
        Width = 65
        Height = 17
        Caption = 'Delivery'
        TabOrder = 1
        OnClick = ControlsUpdate
      end
      object chkLogGameTick: TCheckBox
        Left = 8
        Top = 40
        Width = 87
        Height = 17
        Caption = 'Game tick'
        TabOrder = 2
        OnClick = ControlsUpdate
      end
      object chkLogNetConnection: TCheckBox
        Left = 8
        Top = 24
        Width = 95
        Height = 17
        Caption = 'Net connection'
        Checked = True
        State = cbChecked
        TabOrder = 3
        OnClick = ControlsUpdate
      end
      object chkLogRngChecks: TCheckBox
        Left = 120
        Top = 40
        Width = 97
        Height = 17
        Caption = 'Random Checks'
        TabOrder = 4
        OnClick = ControlsUpdate
      end
      object chkLogShowInChat: TCheckBox
        Left = 8
        Top = 138
        Width = 129
        Height = 17
        Caption = 'Show logs in MP chat'
        TabOrder = 5
        OnClick = ControlsUpdate
      end
      object RGLogNetPackets: TRadioGroup
        Left = 8
        Top = 58
        Width = 161
        Height = 78
        Caption = 'Net packets log level'
        ItemIndex = 0
        Items.Strings = (
          'None '
          'All but commands/ping/fps'
          'All but ping/fps'
          'All packets')
        TabOrder = 6
        OnClick = ControlsUpdate
        OnExit = radioGroupExit
      end
      object chkLogSkipTempCmd: TCheckBox
        Left = 120
        Top = 24
        Width = 121
        Height = 17
        Caption = 'Skip temp commands'
        Checked = True
        State = cbChecked
        TabOrder = 7
        OnClick = ControlsUpdate
      end
      object chkLogShowInGUI: TCheckBox
        Left = 8
        Top = 156
        Width = 106
        Height = 17
        Caption = 'Show logs in GUI'
        TabOrder = 8
        OnClick = ControlsUpdate
      end
      object chkLogUpdateForGUI: TCheckBox
        Left = 120
        Top = 156
        Width = 113
        Height = 17
        Caption = 'Update log for GUI'
        TabOrder = 9
        OnClick = ControlsUpdate
      end
    end
    object cpGraphicTweaks: TCategoryPanel
      Top = 289
      Height = 24
      Caption = 'Graphic tweaks'
      Collapsed = True
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 2
      ExpandedHeight = 153
      object Label1: TLabel
        Left = 101
        Top = 55
        Width = 60
        Height = 13
        Caption = 'Building step'
      end
      object Label3: TLabel
        Left = 101
        Top = 7
        Width = 27
        Height = 13
        Caption = 'Angle'
      end
      object Label4: TLabel
        Left = 101
        Top = 23
        Width = 27
        Height = 13
        Caption = 'Angle'
      end
      object Label7: TLabel
        Left = 101
        Top = 39
        Width = 27
        Height = 13
        Caption = 'Angle'
      end
      object lblWaterLight: TLabel
        Left = 101
        Top = 74
        Width = 51
        Height = 13
        Caption = 'Water light'
      end
      object tbAngleX: TTrackBar
        Left = 5
        Top = 7
        Width = 95
        Height = 17
        Max = 90
        Min = -90
        PageSize = 5
        Frequency = 5
        TabOrder = 0
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = ControlsUpdate
      end
      object tbAngleY: TTrackBar
        Left = 5
        Top = 23
        Width = 95
        Height = 17
        Max = 90
        Min = -90
        PageSize = 5
        Frequency = 5
        TabOrder = 1
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = ControlsUpdate
      end
      object tbAngleZ: TTrackBar
        Left = 2
        Top = 42
        Width = 95
        Height = 17
        Max = 90
        Min = -90
        PageSize = 5
        Frequency = 5
        TabOrder = 2
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = ControlsUpdate
      end
      object tbBuildingStep: TTrackBar
        Left = 5
        Top = 55
        Width = 95
        Height = 17
        Max = 100
        TabOrder = 3
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = ControlsUpdate
      end
      object chkSnowHouses: TCheckBox
        Left = 8
        Top = 93
        Width = 86
        Height = 17
        Caption = 'Snow houses'
        TabOrder = 4
        OnClick = ControlsUpdate
      end
      object chkInterpolatedRender: TCheckBox
        Left = 8
        Top = 109
        Width = 113
        Height = 17
        Caption = 'Interpolated render'
        TabOrder = 5
        OnClick = ControlsUpdate
      end
      object tbWaterLight: TTrackBar
        Left = 5
        Top = 74
        Width = 95
        Height = 17
        Max = 200
        Position = 130
        TabOrder = 6
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = ControlsUpdate
      end
    end
    object cpUserInreface: TCategoryPanel
      Top = 265
      Height = 24
      Caption = 'User Interface'
      Collapsed = True
      TabOrder = 3
      ExpandedHeight = 85
      object chkUIControlsBounds: TCheckBox
        Left = 8
        Top = 8
        Width = 97
        Height = 17
        Caption = 'Controls bounds'
        TabOrder = 0
        OnClick = ControlsUpdate
      end
      object chkUIControlsID: TCheckBox
        Left = 120
        Top = 8
        Width = 73
        Height = 17
        Caption = 'Controls IDs'
        TabOrder = 1
        OnClick = ControlsUpdate
      end
      object chkUITextBounds: TCheckBox
        Left = 120
        Top = 24
        Width = 81
        Height = 17
        Caption = 'Text bounds'
        TabOrder = 2
        OnClick = ControlsUpdate
      end
      object chkUIFocusedControl: TCheckBox
        Left = 8
        Top = 24
        Width = 106
        Height = 17
        Caption = 'Focused control'
        TabOrder = 3
        OnClick = ControlsUpdate
      end
      object chkUIControlOver: TCheckBox
        Left = 8
        Top = 40
        Width = 113
        Height = 17
        Caption = 'Control mouse over'
        TabOrder = 4
        OnClick = ControlsUpdate
      end
      object chkSkipRenderText: TCheckBox
        Left = 120
        Top = 39
        Width = 105
        Height = 17
        Caption = 'Skip render text'
        TabOrder = 5
        OnClick = ControlsUpdate
      end
    end
    object cpPerfLogs: TCategoryPanel
      Top = 241
      Height = 24
      Caption = 'Perf Logs'
      Collapsed = True
      TabOrder = 4
      ExpandedHeight = 660
    end
    object cpAI: TCategoryPanel
      Top = 217
      Height = 24
      Caption = 'AI'
      Collapsed = True
      TabOrder = 5
      object Label5: TLabel
        Left = 202
        Top = 111
        Width = 32
        Height = 13
        Caption = 'Margin'
        Visible = False
      end
      object Label6: TLabel
        Left = 202
        Top = 134
        Width = 47
        Height = 13
        Caption = 'Threshold'
        Visible = False
      end
      object chkAIEye: TCheckBox
        Left = 120
        Top = 57
        Width = 58
        Height = 17
        Caption = 'Eye'
        TabOrder = 0
        OnClick = ControlsUpdate
      end
      object chkBuild: TCheckBox
        Left = 120
        Top = 41
        Width = 58
        Height = 17
        Caption = 'Build'
        TabOrder = 1
        OnClick = ControlsUpdate
      end
      object chkCombat: TCheckBox
        Left = 8
        Top = 41
        Width = 86
        Height = 17
        Caption = 'Combat'
        TabOrder = 2
        OnClick = ControlsUpdate
      end
      object chkShowAvoid: TCheckBox
        Left = 120
        Top = 25
        Width = 86
        Height = 17
        Caption = 'Avoid building'
        TabOrder = 3
        OnClick = ControlsUpdate
      end
      object chkShowBalance: TCheckBox
        Left = 120
        Top = 8
        Width = 58
        Height = 17
        Caption = 'Balance'
        TabOrder = 4
        OnClick = ControlsUpdate
      end
      object chkShowDefences: TCheckBox
        Left = 8
        Top = 75
        Width = 97
        Height = 17
        Caption = 'Defences'
        TabOrder = 5
        OnClick = ControlsUpdate
      end
      object chkShowEyeRoutes: TCheckBox
        Left = 184
        Top = 88
        Width = 65
        Height = 17
        Caption = 'Routes'
        TabOrder = 6
        OnClick = ControlsUpdate
      end
      object chkShowFlatArea: TCheckBox
        Left = 184
        Top = 73
        Width = 65
        Height = 17
        Caption = 'Flat area'
        TabOrder = 7
        OnClick = ControlsUpdate
      end
      object chkShowNavMesh: TCheckBox
        Left = 8
        Top = 8
        Width = 86
        Height = 17
        Caption = 'Navmesh'
        TabOrder = 8
        OnClick = ControlsUpdate
      end
      object chkShowOwnership: TCheckBox
        Left = 8
        Top = 24
        Width = 86
        Height = 17
        Caption = 'Ownership'
        TabOrder = 9
        OnClick = ControlsUpdate
      end
      object chkShowSoil: TCheckBox
        Left = 184
        Top = 57
        Width = 65
        Height = 17
        Caption = 'Soil'
        TabOrder = 10
        OnClick = ControlsUpdate
      end
      object tbOwnMargin: TTrackBar
        Left = 103
        Top = 111
        Width = 101
        Height = 17
        Max = 255
        Min = 64
        Position = 64
        TabOrder = 11
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        Visible = False
        OnChange = ControlsUpdate
      end
      object tbOwnThresh: TTrackBar
        Left = 103
        Top = 134
        Width = 101
        Height = 17
        Max = 255
        Min = 64
        Position = 64
        TabOrder = 12
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        Visible = False
        OnChange = ControlsUpdate
      end
      object chkSupervisor: TCheckBox
        Left = 8
        Top = 105
        Width = 97
        Height = 17
        Caption = 'Supervisor'
        TabOrder = 13
        OnClick = ControlsUpdate
      end
      object chkShowDefencesAnimate: TCheckBox
        Left = 25
        Top = 89
        Width = 56
        Height = 17
        Caption = 'Animate'
        TabOrder = 14
        OnClick = ControlsUpdate
      end
      object chkShowArmyVectorField: TCheckBox
        Left = 8
        Top = 121
        Width = 72
        Height = 17
        Caption = 'Vector Field'
        TabOrder = 15
        OnClick = ControlsUpdate
      end
      object chkShowClusters: TCheckBox
        Left = 8
        Top = 136
        Width = 72
        Height = 17
        Caption = 'Clusters'
        TabOrder = 16
        OnClick = ControlsUpdate
      end
      object chkShowAlliedGroups: TCheckBox
        Left = 8
        Top = 151
        Width = 89
        Height = 17
        Caption = 'Allied Groups'
        TabOrder = 17
        OnClick = ControlsUpdate
      end
      object chkPathfinding: TCheckBox
        Left = 25
        Top = 58
        Width = 86
        Height = 17
        Caption = 'Pathfinding'
        TabOrder = 18
        OnClick = ControlsUpdate
      end
    end
    object cpScripting: TCategoryPanel
      Top = 193
      Height = 24
      Caption = 'Scripting'
      Collapsed = True
      TabOrder = 6
      ExpandedHeight = 50
      object chkDebugScripting: TCheckBox
        Left = 8
        Top = 8
        Width = 97
        Height = 17
        Hint = 
          'Show exect error position (col/row/module), but significantly sl' +
          'ow down script execution'
        Caption = 'Debug Scripting '
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        OnClick = ControlsUpdate
      end
    end
    object cpGameAdv: TCategoryPanel
      Top = 169
      Height = 24
      Caption = 'Game additional'
      Collapsed = True
      TabOrder = 7
      ExpandedHeight = 136
      object chkLoadUnsupSaves: TCheckBox
        Left = 12
        Top = 8
        Width = 157
        Height = 17
        Caption = 'Allow load unsupported saves'
        TabOrder = 0
        OnClick = ControlsUpdate
      end
      object RGPlayer: TRadioGroup
        Left = 8
        Top = 30
        Width = 225
        Height = 75
        BiDiMode = bdLeftToRight
        Caption = ' Select player '
        Columns = 6
        ItemIndex = 0
        Items.Strings = (
          '1'
          '2'
          '3'
          '4'
          '5'
          '6'
          '7'
          '8'
          '9'
          '10'
          '11'
          '12'
          '13'
          '14'
          '15'
          '16'
          '17'
          '18')
        ParentBiDiMode = False
        TabOrder = 1
        OnClick = RGPlayerClick
        OnExit = radioGroupExit
      end
    end
    object cpDebugInput: TCategoryPanel
      Top = 145
      Height = 24
      Caption = 'Debug Input'
      Collapsed = True
      TabOrder = 8
      ExpandedHeight = 210
      object gbFindObjByUID: TGroupBox
        Left = 8
        Top = 28
        Width = 225
        Height = 91
        Caption = 'Find object by UID'
        Enabled = False
        TabOrder = 0
        object Label14: TLabel
          Left = 8
          Top = 43
          Width = 79
          Height = 13
          Caption = 'Selected G/U/H'
        end
        object Label15: TLabel
          Left = 112
          Top = 44
          Width = 79
          Height = 13
          Caption = 'Selected Warrior'
        end
        object Label13: TLabel
          Left = 86
          Top = 19
          Width = 22
          Height = 13
          Caption = 'UID:'
        end
        object seFindObjByUID: TSpinEdit
          Left = 112
          Top = 16
          Width = 97
          Height = 22
          MaxValue = 2147483647
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = ControlsUpdate
        end
        object btFindObjByUID: TButton
          Left = 8
          Top = 16
          Width = 60
          Height = 20
          Caption = 'Find'
          TabOrder = 1
          OnClick = btFindObjByUIDClick
        end
        object seEntityUID: TSpinEdit
          Left = 8
          Top = 62
          Width = 90
          Height = 22
          MaxValue = 2147483647
          MinValue = -2147483648
          TabOrder = 2
          Value = 0
          OnChange = ControlsUpdate
        end
        object seWarriorUID: TSpinEdit
          Left = 112
          Top = 63
          Width = 97
          Height = 22
          MaxValue = 2147483647
          MinValue = -2147483648
          TabOrder = 3
          Value = 0
          OnChange = ControlsUpdate
        end
      end
      object GroupBox2: TGroupBox
        Left = 8
        Top = 122
        Width = 225
        Height = 62
        Caption = 'Debug input'
        TabOrder = 1
        object Label10: TLabel
          Left = 8
          Top = 16
          Width = 27
          Height = 13
          Caption = 'Value'
        end
        object Label11: TLabel
          Left = 112
          Top = 16
          Width = 21
          Height = 13
          Caption = 'Text'
        end
        object seDebugValue: TSpinEdit
          Left = 8
          Top = 32
          Width = 90
          Height = 22
          TabStop = False
          MaxValue = 2147483647
          MinValue = -2147483648
          TabOrder = 0
          Value = 0
          OnChange = ControlsUpdate
        end
        object edDebugText: TEdit
          AlignWithMargins = True
          Left = 112
          Top = 32
          Width = 105
          Height = 21
          TabStop = False
          TabOrder = 1
          OnChange = ControlsUpdate
        end
      end
      object chkFindObjByUID: TCheckBox
        Left = 8
        Top = 6
        Width = 145
        Height = 17
        Caption = 'Enable '#39'Find object by UID'#39
        TabOrder = 2
        OnClick = ControlsUpdate
      end
    end
    object cpDebugRender: TCategoryPanel
      Top = 121
      Height = 24
      Caption = 'Debug Render'
      Collapsed = True
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 9
      ExpandedHeight = 360
      object Label2: TLabel
        Left = 136
        Top = 5
        Width = 49
        Height = 13
        Caption = 'Passability'
      end
      object chkHands: TCheckBox
        Left = 120
        Top = 264
        Width = 76
        Height = 17
        Caption = 'Hands'
        TabOrder = 0
        OnClick = ControlsUpdate
      end
      object chkSelectedObjInfo: TCheckBox
        Left = 120
        Top = 248
        Width = 84
        Height = 17
        Caption = 'Selection Info'
        TabOrder = 1
        OnClick = ControlsUpdate
      end
      object chkSelectionBuffer: TCheckBox
        Left = 8
        Top = 56
        Width = 97
        Height = 17
        Caption = 'Unit hitbox'
        TabOrder = 2
        OnClick = ControlsUpdate
      end
      object chkShowFPS: TCheckBox
        Left = 120
        Top = 303
        Width = 76
        Height = 17
        Caption = 'FPS'
        TabOrder = 3
        OnClick = ControlsUpdate
      end
      object chkShowGameTick: TCheckBox
        Left = 120
        Top = 319
        Width = 76
        Height = 17
        Caption = 'Game tick'
        TabOrder = 4
        OnClick = ControlsUpdate
      end
      object chkShowRoutes: TCheckBox
        Left = 8
        Top = 24
        Width = 81
        Height = 17
        Caption = 'Unit routes'
        TabOrder = 5
        OnClick = ControlsUpdate
      end
      object chkShowTerrainIds: TCheckBox
        Left = 120
        Top = 24
        Width = 79
        Height = 17
        Caption = 'Terrain IDs'
        TabOrder = 6
        OnClick = ControlsUpdate
      end
      object chkShowTerrainKinds: TCheckBox
        Left = 120
        Top = 40
        Width = 79
        Height = 17
        Caption = 'Terrain Kinds'
        TabOrder = 7
        OnClick = ControlsUpdate
      end
      object chkShowWires: TCheckBox
        Left = 8
        Top = 40
        Width = 76
        Height = 17
        Caption = 'Terrain wires'
        TabOrder = 8
        OnClick = ControlsUpdate
      end
      object chkSkipRender: TCheckBox
        Left = 8
        Top = 72
        Width = 81
        Height = 17
        Caption = 'Skip Render'
        TabOrder = 9
        OnClick = ControlsUpdate
      end
      object chkSkipSound: TCheckBox
        Left = 8
        Top = 88
        Width = 81
        Height = 17
        Caption = 'Skip Sound'
        TabOrder = 10
        OnClick = ControlsUpdate
      end
      object chkTilesGrid: TCheckBox
        Left = 8
        Top = 303
        Width = 79
        Height = 17
        Caption = 'Tiles grid'
        TabOrder = 11
        OnClick = ControlsUpdate
      end
      object chkUIDs: TCheckBox
        Left = 120
        Top = 232
        Width = 79
        Height = 17
        Caption = 'UIDs by T'
        TabOrder = 12
        OnClick = ControlsUpdate
      end
      object tbPassability: TTrackBar
        Left = 2
        Top = 4
        Width = 128
        Height = 17
        Max = 14
        PageSize = 1
        TabOrder = 13
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = ControlsUpdate
      end
      object chkJamMeter: TCheckBox
        Left = 120
        Top = 88
        Width = 79
        Height = 17
        Caption = 'Jam meter'
        TabOrder = 14
        OnClick = ControlsUpdate
      end
      object chkShowTerrainOverlays: TCheckBox
        Left = 120
        Top = 56
        Width = 95
        Height = 17
        Caption = 'Terrain overlays'
        TabOrder = 15
        OnClick = ControlsUpdate
      end
      object chkHeight: TCheckBox
        Left = 120
        Top = 72
        Width = 105
        Height = 17
        Caption = 'Terrain height'
        TabOrder = 16
        OnClick = ControlsUpdate
      end
      object chkTreeAge: TCheckBox
        Left = 120
        Top = 120
        Width = 79
        Height = 17
        Caption = 'Tree age'
        TabOrder = 17
        OnClick = ControlsUpdate
      end
      object chkFieldAge: TCheckBox
        Left = 120
        Top = 136
        Width = 79
        Height = 17
        Caption = 'Field age'
        TabOrder = 18
        OnClick = ControlsUpdate
      end
      object chkTileLock: TCheckBox
        Left = 120
        Top = 152
        Width = 79
        Height = 17
        Caption = 'Tile lock'
        TabOrder = 19
        OnClick = ControlsUpdate
      end
      object chkTileOwner: TCheckBox
        Left = 120
        Top = 168
        Width = 79
        Height = 17
        Caption = 'Tile owner'
        TabOrder = 20
        OnClick = ControlsUpdate
      end
      object chkTileUnit: TCheckBox
        Left = 120
        Top = 184
        Width = 79
        Height = 17
        Caption = 'Tile Unit'
        TabOrder = 21
        OnClick = ControlsUpdate
      end
      object chkVertexUnit: TCheckBox
        Left = 120
        Top = 200
        Width = 79
        Height = 17
        Caption = 'Vertex Unit'
        TabOrder = 22
        OnClick = ControlsUpdate
      end
      object chkTileObject: TCheckBox
        Left = 120
        Top = 104
        Width = 79
        Height = 17
        Caption = 'Objects ID'
        TabOrder = 23
        OnClick = ControlsUpdate
      end
      object chkShowDefencePos: TCheckBox
        Left = 8
        Top = 248
        Width = 110
        Height = 17
        Caption = 'Show defence pos'
        TabOrder = 24
        OnClick = ControlsUpdate
      end
      object chkShowUnitRadius: TCheckBox
        Left = 8
        Top = 232
        Width = 110
        Height = 17
        Caption = 'Show unit radius'
        TabOrder = 25
        OnClick = ControlsUpdate
      end
      object chkShowTowerRadius: TCheckBox
        Left = 8
        Top = 216
        Width = 110
        Height = 17
        Caption = 'Show tower radius'
        TabOrder = 26
        OnClick = ControlsUpdate
      end
      object chkShowMiningRadius: TCheckBox
        Left = 8
        Top = 200
        Width = 110
        Height = 17
        Caption = 'Show mining radius'
        TabOrder = 27
        OnClick = ControlsUpdate
      end
      object chkShowOverlays: TCheckBox
        Left = 8
        Top = 184
        Width = 97
        Height = 17
        Caption = 'Show overlays'
        Checked = True
        State = cbChecked
        TabOrder = 28
        OnClick = ControlsUpdate
      end
      object chkShowUnits: TCheckBox
        Left = 8
        Top = 168
        Width = 79
        Height = 17
        Caption = 'Show units'
        Checked = True
        State = cbChecked
        TabOrder = 29
        OnClick = ControlsUpdate
      end
      object chkShowHouses: TCheckBox
        Left = 8
        Top = 152
        Width = 97
        Height = 17
        Caption = 'Show houses'
        Checked = True
        State = cbChecked
        TabOrder = 30
        OnClick = ControlsUpdate
      end
      object chkShowObjects: TCheckBox
        Left = 8
        Top = 136
        Width = 105
        Height = 17
        Caption = 'Show objects'
        Checked = True
        State = cbChecked
        TabOrder = 31
        OnClick = ControlsUpdate
      end
      object chkShowFlatTerrain: TCheckBox
        Left = 8
        Top = 264
        Width = 97
        Height = 17
        Caption = 'Show flat terrain'
        TabOrder = 32
        OnClick = ControlsUpdate
      end
      object chkGIP: TCheckBox
        Left = 120
        Top = 280
        Width = 41
        Height = 17
        Caption = 'GIP'
        TabOrder = 33
        OnClick = ControlsUpdate
      end
      object chkPaintSounds: TCheckBox
        Left = 8
        Top = 104
        Width = 81
        Height = 17
        Caption = 'Paint Sounds'
        TabOrder = 34
        OnClick = ControlsUpdate
      end
      object chkGipAsBytes: TCheckBox
        Left = 167
        Top = 280
        Width = 66
        Height = 17
        Caption = 'as Bytes'
        TabOrder = 35
        OnClick = ControlsUpdate
      end
    end
    object cpGameControls: TCategoryPanel
      Top = 0
      Height = 121
      Caption = 'Game'
      TabOrder = 10
      object Label8: TLabel
        Left = 70
        Top = 30
        Width = 83
        Height = 13
        Caption = 'Pause before tick'
      end
      object Label9: TLabel
        Left = 24
        Top = 54
        Width = 129
        Height = 13
        Caption = 'Make savepoint before tick'
      end
      object Label12: TLabel
        Left = 92
        Top = 78
        Width = 61
        Height = 13
        Caption = 'Custom seed'
      end
      object chkSuperSpeed: TCheckBox
        Left = 8
        Top = 5
        Width = 75
        Height = 17
        Hint = 'Autosave is disabled while on very fast speedup'
        Caption = 'Speed x200'
        TabOrder = 0
        OnClick = chkSuperSpeedClick
      end
      object Button_Stop: TButton
        Left = 135
        Top = 5
        Width = 89
        Height = 17
        Caption = 'Stop the game'
        TabOrder = 1
        OnClick = Button_StopClick
      end
      object sePauseBeforeTick: TSpinEdit
        Left = 159
        Top = 28
        Width = 66
        Height = 22
        Ctl3D = True
        MaxValue = 9999999
        MinValue = 0
        ParentCtl3D = False
        TabOrder = 2
        Value = 0
        OnChange = ControlsUpdate
      end
      object seMakeSaveptBeforeTick: TSpinEdit
        Left = 159
        Top = 52
        Width = 66
        Height = 22
        Ctl3D = True
        MaxValue = 9999999
        MinValue = 0
        ParentCtl3D = False
        TabOrder = 3
        Value = 0
        OnChange = ControlsUpdate
      end
      object seCustomSeed: TSpinEdit
        Left = 159
        Top = 76
        Width = 66
        Height = 22
        Ctl3D = True
        MaxValue = 9999999
        MinValue = 0
        ParentCtl3D = False
        TabOrder = 4
        Value = 0
        OnChange = ControlsUpdate
      end
    end
  end
  object OpenDialog1: TOpenDialog
    InitialDir = '.'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 24
    Top = 64
  end
  object MainMenu1: TMainMenu
    Left = 24
    Top = 8
    object File1: TMenuItem
      Caption = 'File'
      object OpenMissionMenu: TMenuItem
        Caption = 'Start mission...'
        OnClick = Open_MissionMenuClick
      end
      object MenuItem1: TMenuItem
        Caption = 'Edit mission...'
        OnClick = MenuItem1Click
      end
      object SaveEditableMission1: TMenuItem
        Caption = 'Save editable mission...'
        Enabled = False
        OnClick = SaveEditableMission1Click
      end
      object N5: TMenuItem
        Caption = '-'
      end
      object LoadSavThenRpl: TMenuItem
        Caption = 'Load .sav then .rpl'
        OnClick = LoadSavThenRplClick
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object ReloadSettings: TMenuItem
        Caption = 'Reload settings'
        OnClick = ReloadSettingsClick
      end
      object SaveSettings: TMenuItem
        Caption = 'Save settings'
        OnClick = SaveSettingsClick
      end
      object N7: TMenuItem
        Caption = '-'
      end
      object ReloadLibx: TMenuItem
        Caption = 'Reload Libx (translations)'
        OnClick = ReloadLibxClick
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
        OnClick = ExitClick
      end
    end
    object Debug1: TMenuItem
      Caption = 'Debug'
      object Debug_PrintScreen: TMenuItem
        Caption = 'PrintScreen'
        OnClick = Debug_PrintScreenClick
      end
      object N8: TMenuItem
        Caption = '-'
      end
      object Debug_EnableCheats: TMenuItem
        Caption = 'Debug Cheats'
        OnClick = Debug_EnableCheatsClick
      end
      object Debug_UnlockCmpMissions: TMenuItem
        Caption = 'Unlock campaigns missions'
        OnClick = Debug_UnlockCmpMissionsClick
      end
      object N9: TMenuItem
        Caption = '-'
      end
      object Debug_ShowPanel: TMenuItem
        Caption = 'Show Debug panel'
        OnClick = Debug_ShowPanelClick
      end
      object Debug_ShowLogistics: TMenuItem
        Caption = 'Show Logistics'
        OnClick = Debug_ShowLogisticsClick
      end
    end
    object Export1: TMenuItem
      Caption = 'Export Data'
      object Resources1: TMenuItem
        Caption = 'Resources'
        object Export_Fonts1: TMenuItem
          Caption = 'Fonts'
          OnClick = Export_Fonts1Click
        end
        object Export_Sounds1: TMenuItem
          Caption = 'Sounds'
          OnClick = Export_Sounds1Click
        end
        object Other1: TMenuItem
          Caption = '-'
          Enabled = False
        end
        object Export_TreesRX: TMenuItem
          Caption = 'Trees.rx'
          OnClick = Export_TreesRXClick
        end
        object Export_HousesRX: TMenuItem
          Caption = 'Houses.rx'
          OnClick = Export_HousesRXClick
        end
        object Export_UnitsRX: TMenuItem
          Caption = 'Units.rx'
          OnClick = Export_UnitsRXClick
        end
        object Export_GUIRX: TMenuItem
          Caption = 'GUI.rx'
          OnClick = Export_GUIClick
        end
        object Export_GUIMainRX: TMenuItem
          Caption = 'GUI Main.rx'
          OnClick = Export_GUIMainRXClick
        end
        object Export_Custom: TMenuItem
          Caption = 'Custom'
          OnClick = Export_CustomClick
        end
        object Export_Tileset: TMenuItem
          Caption = 'Tileset'
          OnClick = Export_TilesetClick
        end
      end
      object AnimData1: TMenuItem
        Caption = '-'
        Enabled = False
      end
      object Export_TreeAnim1: TMenuItem
        Caption = 'Tree Anim'
        OnClick = Export_TreeAnim1Click
      end
      object Export_HouseAnim1: TMenuItem
        Caption = 'House Anim'
        OnClick = Export_HouseAnim1Click
      end
      object Export_UnitAnim1: TMenuItem
        Caption = 'Unit Anim'
        object UnitAnim_All: TMenuItem
          Caption = 'All'
          OnClick = UnitAnim_AllClick
        end
        object N3: TMenuItem
          Caption = '-'
        end
        object Soldiers: TMenuItem
          Caption = 'Soldiers'
          OnClick = SoldiersClick
        end
        object Civilians1: TMenuItem
          Caption = 'Civilians'
          OnClick = Civilians1Click
        end
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object ResourceValues1: TMenuItem
        Caption = 'Resource Values'
        OnClick = ResourceValues1Click
      end
      object Export_Deliverlists1: TMenuItem
        Caption = 'Deliver lists'
        OnClick = Export_Deliverlists1Click
      end
      object HousesDat1: TMenuItem
        Caption = 'Houses Dat'
        OnClick = HousesDat1Click
      end
      object ScriptData1: TMenuItem
        Caption = 'Script Data'
        OnClick = Export_ScriptDataClick
      end
      object N6: TMenuItem
        Caption = '-'
      end
      object GameStats: TMenuItem
        Caption = 'Game statistics'
        object ExportGameStats: TMenuItem
          Caption = 'Export'
          Enabled = False
          OnClick = ExportGameStatsClick
        end
        object ValidateGameStats: TMenuItem
          Caption = 'Validate'
          OnClick = ValidateGameStatsClick
        end
      end
      object N10: TMenuItem
        Caption = '-'
      end
      object ExportMainMenu: TMenuItem
        Caption = 'Export MainMenu'
        OnClick = Debug_ExportMenuClick
      end
      object ExportUIPages: TMenuItem
        Caption = 'Export UI pages'
        OnClick = Debug_ExportUIPagesClick
      end
      object N11: TMenuItem
        Caption = '-'
      end
      object mnExportRngChecks: TMenuItem
        Caption = 'Random checks'
        OnClick = mnExportRngChecksClick
      end
      object mnExportRPL: TMenuItem
        Caption = 'GIC from .rpl'
        OnClick = mnExportRPLClick
      end
    end
    object About1: TMenuItem
      Caption = 'About..'
      OnClick = AboutClick
    end
  end
  object SaveDialog1: TSaveDialog
    Left = 24
    Top = 120
  end
end
