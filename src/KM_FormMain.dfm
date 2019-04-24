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
  DesignSize = (
    521
    785)
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
  object GroupBox1: TGroupBox
    Left = 320
    Top = 8
    Width = 193
    Height = 736
    Anchors = [akTop, akRight]
    Caption = ' Development controls '
    TabOrder = 1
    object GroupBox4: TGroupBox
      Left = 8
      Top = 474
      Width = 177
      Height = 89
      Caption = ' Graphics tweaks '
      TabOrder = 4
      object Label3: TLabel
        Left = 100
        Top = 16
        Width = 27
        Height = 13
        Caption = 'Angle'
      end
      object Label4: TLabel
        Left = 100
        Top = 32
        Width = 27
        Height = 13
        Caption = 'Angle'
      end
      object Label1: TLabel
        Left = 100
        Top = 64
        Width = 60
        Height = 13
        Caption = 'Building step'
      end
      object Label7: TLabel
        Left = 100
        Top = 48
        Width = 27
        Height = 13
        Caption = 'Angle'
      end
      object tbAngleX: TTrackBar
        Left = 4
        Top = 16
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
        Left = 4
        Top = 32
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
      object tbBuildingStep: TTrackBar
        Left = 4
        Top = 64
        Width = 95
        Height = 17
        Max = 100
        TabOrder = 2
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = ControlsUpdate
      end
      object tbAngleZ: TTrackBar
        Left = 4
        Top = 48
        Width = 95
        Height = 17
        Max = 90
        Min = -90
        PageSize = 5
        Frequency = 5
        TabOrder = 3
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = ControlsUpdate
      end
    end
    object GroupBox3: TGroupBox
      Left = 8
      Top = 416
      Width = 177
      Height = 57
      Caption = ' User Interface '
      TabOrder = 3
      object chkUIControlsBounds: TCheckBox
        Left = 8
        Top = 16
        Width = 97
        Height = 17
        Caption = 'Controls bounds'
        TabOrder = 0
        OnClick = ControlsUpdate
      end
      object chkUITextBounds: TCheckBox
        Left = 8
        Top = 32
        Width = 81
        Height = 17
        Caption = 'Text bounds'
        TabOrder = 1
        OnClick = ControlsUpdate
      end
      object chkUIControlsID: TCheckBox
        Left = 110
        Top = 16
        Width = 58
        Height = 17
        Caption = 'Ctrls ID'
        TabOrder = 2
        OnClick = ControlsUpdate
      end
    end
    object chkSuperSpeed: TCheckBox
      Left = 8
      Top = 85
      Width = 75
      Height = 17
      Hint = 'Autosave is disabled while on very fast speedup'
      Caption = 'Speed x200'
      TabOrder = 0
      OnClick = chkSuperSpeedClick
    end
    object RGPlayer: TRadioGroup
      Left = 8
      Top = 16
      Width = 177
      Height = 65
      Caption = ' Select player '
      Columns = 4
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
        '12')
      TabOrder = 7
      OnClick = RGPlayerClick
    end
    object Button_Stop: TButton
      Left = 96
      Top = 85
      Width = 89
      Height = 17
      Caption = 'Stop the game'
      TabOrder = 1
      OnClick = Button_StopClick
    end
    object GroupBox2: TGroupBox
      Left = 8
      Top = 248
      Width = 177
      Height = 168
      Caption = ' AI '
      TabOrder = 2
      object Label5: TLabel
        Left = 107
        Top = 132
        Width = 32
        Height = 13
        Caption = 'Margin'
        Visible = False
      end
      object Label6: TLabel
        Left = 107
        Top = 148
        Width = 47
        Height = 13
        Caption = 'Threshold'
        Visible = False
      end
      object chkShowOwnership: TCheckBox
        Left = 8
        Top = 48
        Width = 86
        Height = 17
        Caption = 'Ownership'
        TabOrder = 0
        OnClick = ControlsUpdate
      end
      object chkShowNavMesh: TCheckBox
        Left = 8
        Top = 80
        Width = 86
        Height = 17
        Caption = 'Navmesh'
        TabOrder = 1
        OnClick = ControlsUpdate
      end
      object chkShowAvoid: TCheckBox
        Left = 8
        Top = 64
        Width = 86
        Height = 17
        Caption = 'Avoid building'
        TabOrder = 2
        OnClick = ControlsUpdate
      end
      object chkShowBalance: TCheckBox
        Left = 8
        Top = 16
        Width = 97
        Height = 17
        Caption = 'AI balance text'
        TabOrder = 3
        OnClick = ControlsUpdate
      end
      object chkShowDefences: TCheckBox
        Left = 100
        Top = 96
        Width = 97
        Height = 17
        Caption = 'Defences'
        TabOrder = 4
        OnClick = ControlsUpdate
      end
      object chkBuildAI: TCheckBox
        Left = 8
        Top = 32
        Width = 86
        Height = 17
        Caption = 'Build AI'
        TabOrder = 5
        OnClick = ControlsUpdate
      end
      object chkCombatAI: TCheckBox
        Left = 8
        Top = 96
        Width = 86
        Height = 17
        Caption = 'Combat AI'
        TabOrder = 6
        OnClick = ControlsUpdate
      end
      object chkAIEye: TCheckBox
        Left = 100
        Top = 32
        Width = 97
        Height = 17
        Caption = 'AI Eye'
        TabOrder = 7
        OnClick = ControlsUpdate
      end
      object tbOwnMargin: TTrackBar
        Left = 3
        Top = 132
        Width = 101
        Height = 17
        Max = 255
        Min = 64
        Position = 64
        TabOrder = 8
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        Visible = False
        OnChange = ControlsUpdate
      end
      object tbOwnThresh: TTrackBar
        Left = 3
        Top = 148
        Width = 101
        Height = 17
        Max = 255
        Min = 64
        Position = 64
        TabOrder = 9
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        Visible = False
        OnChange = ControlsUpdate
      end
      object chkBevel: TCheckBox
        Left = 100
        Top = 16
        Width = 88
        Height = 17
        Caption = 'Bevel'
        Checked = True
        State = cbChecked
        TabOrder = 10
        OnClick = ControlsUpdate
      end
      object chkShowSoil: TCheckBox
        Left = 100
        Top = 48
        Width = 88
        Height = 17
        Caption = 'Soil'
        TabOrder = 11
        OnClick = ControlsUpdate
      end
      object chkShowFlatArea: TCheckBox
        Left = 100
        Top = 64
        Width = 88
        Height = 17
        Caption = 'Flat area'
        TabOrder = 12
        OnClick = ControlsUpdate
      end
      object chkShowEyeRoutes: TCheckBox
        Left = 100
        Top = 80
        Width = 88
        Height = 17
        Caption = 'Routes'
        TabOrder = 13
        OnClick = ControlsUpdate
      end
    end
    object GroupBox5: TGroupBox
      Left = 8
      Top = 104
      Width = 177
      Height = 145
      Caption = ' Debug render '
      TabOrder = 5
      object Label2: TLabel
        Left = 100
        Top = 16
        Width = 49
        Height = 13
        Caption = 'Passability'
      end
      object tbPassability: TTrackBar
        Left = 4
        Top = 16
        Width = 95
        Height = 17
        Max = 14
        PageSize = 1
        TabOrder = 0
        ThumbLength = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = ControlsUpdate
      end
      object chkShowRoutes: TCheckBox
        Left = 8
        Top = 56
        Width = 81
        Height = 17
        Caption = 'Unit routes'
        TabOrder = 1
        OnClick = ControlsUpdate
      end
      object chkShowWires: TCheckBox
        Left = 8
        Top = 40
        Width = 89
        Height = 17
        Caption = 'Terrain wires'
        TabOrder = 2
        OnClick = ControlsUpdate
      end
      object chkSelectionBuffer: TCheckBox
        Left = 8
        Top = 72
        Width = 97
        Height = 17
        Caption = 'Select. buffer'
        TabOrder = 3
        OnClick = ControlsUpdate
      end
      object chkShowTerrainIds: TCheckBox
        Left = 90
        Top = 40
        Width = 79
        Height = 17
        Caption = 'Terrain IDs'
        TabOrder = 4
        OnClick = ControlsUpdate
      end
      object chkShowTerrainKinds: TCheckBox
        Left = 90
        Top = 56
        Width = 79
        Height = 17
        Caption = 'Ter. Kinds'
        TabOrder = 5
        OnClick = ControlsUpdate
      end
      object chkTilesGrid: TCheckBox
        Left = 90
        Top = 72
        Width = 79
        Height = 17
        Caption = 'Tiles grid'
        TabOrder = 6
        OnClick = ControlsUpdate
      end
      object chkShowGameTick: TCheckBox
        Left = 8
        Top = 88
        Width = 97
        Height = 17
        Caption = 'Game tick'
        TabOrder = 7
        OnClick = ControlsUpdate
      end
      object chkSkipRender: TCheckBox
        Left = 8
        Top = 104
        Width = 89
        Height = 17
        Caption = 'Skip Render'
        TabOrder = 8
        OnClick = ControlsUpdate
      end
      object chkSkipSound: TCheckBox
        Left = 8
        Top = 120
        Width = 89
        Height = 17
        Caption = 'Skip Sound'
        TabOrder = 9
        OnClick = ControlsUpdate
      end
      object chkUIDs: TCheckBox
        Left = 90
        Top = 104
        Width = 79
        Height = 17
        Caption = 'UIDs by T'
        TabOrder = 10
        OnClick = ControlsUpdate
      end
      object chkSelectedObjInfo: TCheckBox
        Left = 90
        Top = 120
        Width = 84
        Height = 17
        Caption = 'Selection Info'
        TabOrder = 11
        OnClick = ControlsUpdate
      end
      object chkShowFPS: TCheckBox
        Left = 90
        Top = 88
        Width = 97
        Height = 17
        Caption = 'FPS'
        TabOrder = 12
        OnClick = ControlsUpdate
      end
    end
    object GroupBoxLogs: TGroupBox
      Left = 8
      Top = 562
      Width = 177
      Height = 170
      Caption = 'Logs'
      TabOrder = 6
      object chkLogDelivery: TCheckBox
        Left = 8
        Top = 16
        Width = 65
        Height = 17
        Caption = 'Delivery'
        TabOrder = 0
        OnClick = ControlsUpdate
      end
      object chkLogCommands: TCheckBox
        Left = 100
        Top = 16
        Width = 73
        Height = 17
        Caption = 'Commands'
        TabOrder = 1
        OnClick = ControlsUpdate
      end
      object chkLogNetConnection: TCheckBox
        Left = 8
        Top = 32
        Width = 95
        Height = 17
        Caption = 'Net connection'
        Checked = True
        State = cbChecked
        TabOrder = 2
        OnClick = ControlsUpdate
      end
      object RGLogNetPackets: TRadioGroup
        Left = 8
        Top = 66
        Width = 161
        Height = 78
        Caption = 'Net packets log level'
        ItemIndex = 0
        Items.Strings = (
          'None '
          'All but commands/ping/fps'
          'All but ping/fps'
          'All packets')
        TabOrder = 3
        OnClick = ControlsUpdate
      end
      object chkLogsShowInChat: TCheckBox
        Left = 8
        Top = 146
        Width = 137
        Height = 17
        Caption = 'Show logs in MP chat'
        TabOrder = 4
        OnClick = ControlsUpdate
      end
      object chkLogRngChecks: TCheckBox
        Left = 100
        Top = 32
        Width = 73
        Height = 17
        Caption = 'RngChecks'
        TabOrder = 5
        OnClick = ControlsUpdate
      end
      object chkLogGameTick: TCheckBox
        Left = 8
        Top = 48
        Width = 87
        Height = 17
        Caption = 'Game tick'
        TabOrder = 6
        OnClick = ControlsUpdate
      end
    end
  end
  object OpenDialog1: TOpenDialog
    InitialDir = '.'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 80
    Top = 8
  end
  object MainMenu1: TMainMenu
    Left = 16
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
      object N4: TMenuItem
        Caption = '-'
      end
      object ReloadSettings: TMenuItem
        Caption = 'Reload settings.ini'
        OnClick = ReloadSettingsClick
      end
      object SaveSettings: TMenuItem
        Caption = 'Save settings.ini'
        OnClick = SaveSettingsClick
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
      object Debug_ShowPanel: TMenuItem
        Caption = 'Show Debug panel'
        OnClick = Debug_ShowPanelClick
      end
      object ExportMainMenu: TMenuItem
        Caption = 'Export MainMenu'
        OnClick = Debug_ExportMenuClick
      end
      object Debug_EnableCheats: TMenuItem
        Caption = 'Debug Cheats'
        OnClick = Debug_EnableCheatsClick
      end
      object ExportUIPages: TMenuItem
        Caption = 'Export UI pages'
        OnClick = Debug_ExportUIPagesClick
      end
      object ShowLogistics: TMenuItem
        Caption = 'Show Logistics'
        OnClick = ShowLogisticsClick
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
    end
    object About1: TMenuItem
      Caption = 'About..'
      OnClick = AboutClick
    end
  end
  object SaveDialog1: TSaveDialog
    Left = 144
    Top = 8
  end
end
