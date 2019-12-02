object Paraller_Runner: TParaller_Runner
  Left = 0
  Top = 0
  Caption = 'Paraller_Runner'
  ClientHeight = 779
  ClientWidth = 1408
  Color = 8553090
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnResize = RefreshGraphs
  DesignSize = (
    1408
    779)
  PixelsPerInch = 96
  TextHeight = 13
  object pcMainPages: TPageControl
    Left = 199
    Top = 3
    Width = 1209
    Height = 775
    ActivePage = tsLog
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
    object tsFitness: TTabSheet
      Caption = 'Fitness'
      DesignSize = (
        1201
        747)
      object imgFitness: TImage
        Left = 3
        Top = 3
        Width = 1195
        Height = 741
        Anchors = [akLeft, akTop, akRight, akBottom]
        ExplicitWidth = 1188
        ExplicitHeight = 610
      end
    end
    object tsGenes: TTabSheet
      Caption = 'Genes'
      ImageIndex = 1
      DesignSize = (
        1201
        747)
      object imgGenes: TImage
        Left = 3
        Top = 3
        Width = 1194
        Height = 741
        Anchors = [akLeft, akTop, akRight, akBottom]
        ExplicitHeight = 736
      end
      object tbGeneSwitch: TTrackBar
        Left = 3
        Top = 3
        Width = 486
        Height = 33
        Anchors = []
        Max = 25
        Position = 10
        TabOrder = 0
        Visible = False
        OnChange = tbGeneSwitchChange
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Times'
      ImageIndex = 2
      DesignSize = (
        1201
        747)
      object imgTimes: TImage
        Left = 3
        Top = 3
        Width = 1195
        Height = 741
        Anchors = [akLeft, akTop, akRight, akBottom]
        ExplicitHeight = 736
      end
    end
    object tsLog: TTabSheet
      Caption = 'Log'
      ImageIndex = 3
      object mLog: TMemo
        Left = 0
        Top = 0
        Width = 1201
        Height = 747
        Align = alClient
        Color = 2631720
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clActiveCaption
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
  end
  object gbGA: TGroupBox
    Left = 8
    Top = 260
    Width = 185
    Height = 269
    Caption = 'GA parameters'
    Color = 11842740
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentBackground = False
    ParentColor = False
    ParentFont = False
    TabOrder = 0
    object lGenerations: TLabel
      Left = 93
      Top = 22
      Width = 62
      Height = 13
      Caption = 'Generations:'
    end
    object lPopulation: TLabel
      Left = 3
      Top = 22
      Width = 54
      Height = 13
      Caption = 'Population:'
    end
    object lTournament: TLabel
      Left = 3
      Top = 69
      Width = 125
      Height = 13
      Caption = 'Individuals in tournament:'
    end
    object lResetGene: TLabel
      Left = 3
      Top = 116
      Width = 109
      Height = 13
      Caption = 'Probability reset gene:'
    end
    object lNormalMutation: TLabel
      Left = 3
      Top = 163
      Width = 142
      Height = 13
      Caption = 'Probability (normal mutation):'
    end
    object lVariance: TLabel
      Left = 3
      Top = 210
      Width = 133
      Height = 13
      Caption = 'Variance (normal mutation):'
    end
    object seGenerations: TSpinEdit
      Left = 93
      Top = 41
      Width = 89
      Height = 22
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxValue = 1000000
      MinValue = 1
      ParentFont = False
      TabOrder = 0
      Value = 10
    end
    object sePopulation: TSpinEdit
      Left = 3
      Top = 41
      Width = 89
      Height = 22
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxValue = 1000000
      MinValue = 1
      ParentFont = False
      TabOrder = 1
      Value = 10
    end
    object eStartVariance: TEdit
      Left = 3
      Top = 229
      Width = 89
      Height = 21
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      Text = '0.1'
    end
    object eEndVariance: TEdit
      Left = 93
      Top = 229
      Width = 89
      Height = 21
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      Text = '0.1'
    end
    object eEndGaussMut: TEdit
      Left = 93
      Top = 182
      Width = 89
      Height = 21
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      Text = '0.1'
    end
    object eStartResetGene: TEdit
      Left = 3
      Top = 135
      Width = 89
      Height = 21
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      Text = '0.1'
    end
    object eEndResetGene: TEdit
      Left = 93
      Top = 135
      Width = 89
      Height = 21
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      Text = '0.1'
    end
    object eStartGaussMut: TEdit
      Left = 3
      Top = 182
      Width = 89
      Height = 21
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      Text = '0.1'
    end
    object seEndTournament: TSpinEdit
      Left = 93
      Top = 88
      Width = 89
      Height = 22
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxValue = 1000000
      MinValue = 1
      ParentFont = False
      TabOrder = 8
      Value = 10
    end
    object seStartTournament: TSpinEdit
      Left = 3
      Top = 88
      Width = 89
      Height = 22
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxValue = 1000000
      MinValue = 1
      ParentFont = False
      TabOrder = 9
      Value = 10
    end
  end
  object gbSim: TGroupBox
    Left = 8
    Top = 3
    Width = 185
    Height = 251
    Caption = 'Simulation parameters'
    Color = 11842740
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentBackground = False
    ParentColor = False
    ParentFont = False
    TabOrder = 2
    object lThreads: TLabel
      Left = 3
      Top = 205
      Width = 43
      Height = 13
      Caption = 'Threads:'
    end
    object lMaps: TLabel
      Left = 3
      Top = 158
      Width = 29
      Height = 13
      Caption = 'Maps:'
    end
    object lDuration: TLabel
      Left = 93
      Top = 158
      Width = 72
      Height = 13
      Caption = 'Duration (min):'
    end
    object lClasses: TLabel
      Left = 3
      Top = 20
      Width = 40
      Height = 13
      Caption = 'Classes:'
    end
    object seThreads: TSpinEdit
      Left = 3
      Top = 221
      Width = 89
      Height = 22
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxValue = 1000000
      MinValue = 1
      ParentFont = False
      TabOrder = 0
      Value = 10
    end
    object seMaps: TSpinEdit
      Left = 3
      Top = 177
      Width = 89
      Height = 22
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxValue = 1000000
      MinValue = 1
      ParentFont = False
      TabOrder = 1
      Value = 10
    end
    object seDuration: TSpinEdit
      Left = 93
      Top = 177
      Width = 89
      Height = 22
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxValue = 1000000
      MinValue = 0
      ParentFont = False
      TabOrder = 2
      Value = 60
    end
    object lbClasses: TListBox
      Left = 3
      Top = 39
      Width = 179
      Height = 113
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 13
      Items.Strings = (
        'TKMRunnerGA_CityBuilder'
        'TKMRunnerGA_CityPlanner'
        'TKMRunnerGA_Farm'
        'TKMRunnerGA_Forest'
        'TKMRunnerGA_HandLogistics'
        'TKMRunnerGA_Manager'
        'TKMRunnerGA_Quarry'
        'TKMRunnerGA_RoadPlanner'
        'TKMRunnerGA_TestParRun')
      ParentFont = False
      TabOrder = 3
    end
  end
  object gbLoad: TGroupBox
    Left = 8
    Top = 535
    Width = 185
    Height = 146
    Caption = 'Load simulation'
    Color = 11842740
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentBackground = False
    ParentColor = False
    ParentFont = False
    TabOrder = 3
    object lClass: TLabel
      Left = 3
      Top = 22
      Width = 29
      Height = 13
      Caption = 'Class:'
    end
    object lDate: TLabel
      Left = 3
      Top = 68
      Width = 27
      Height = 13
      Caption = 'Date:'
      Color = clBlack
      ParentColor = False
    end
    object cbBackupClass: TComboBox
      Left = 3
      Top = 41
      Width = 179
      Height = 21
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = 'cbBackupClass'
      OnChange = cbBackupClassChange
    end
    object cbBackupDate: TComboBox
      Left = 3
      Top = 87
      Width = 179
      Height = 21
      Color = 2631720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = 'cbBackupDate'
    end
    object bLoad: TButton
      Left = 3
      Top = 114
      Width = 179
      Height = 23
      Caption = 'Load'
      TabOrder = 2
      OnClick = bLoadClick
    end
  end
  object bRunSimulation: TButton
    Left = 8
    Top = 687
    Width = 185
    Height = 42
    Caption = 'Run'
    TabOrder = 4
    OnClick = bRunSimulationClick
  end
end
