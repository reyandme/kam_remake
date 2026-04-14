object Form2: TForm2
  Left = 244
  Top = 289
  Caption = 'Testing_GameTests'
  ClientHeight = 641
  ClientWidth = 1097
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    1097
    641)
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 247
    Width = 35
    Height = 13
    Caption = 'Cycles:'
  end
  object Label2: TLabel
    Left = 187
    Top = 376
    Width = 15
    Height = 13
    Alignment = taRightJustify
    Caption = '     '
  end
  object Label4: TLabel
    Left = 103
    Top = 247
    Width = 72
    Height = 13
    Caption = 'Duration (min):'
  end
  object Label5: TLabel
    Left = 187
    Top = 356
    Width = 15
    Height = 13
    Alignment = taRightJustify
    Caption = '     '
  end
  object Label6: TLabel
    Left = 184
    Top = 396
    Width = 18
    Height = 13
    Alignment = taRightJustify
    Caption = '      '
  end
  object Label7: TLabel
    Left = 8
    Top = 288
    Width = 28
    Height = 13
    Caption = 'Seed:'
  end
  object Label8: TLabel
    Left = 184
    Top = 416
    Width = 18
    Height = 13
    Alignment = taRightJustify
    Caption = '      '
  end
  object Label9: TLabel
    Left = 8
    Top = 335
    Width = 18
    Height = 13
    Caption = '      '
  end
  object Label10: TLabel
    Left = 8
    Top = 376
    Width = 18
    Height = 13
    Caption = '      '
  end
  object Label11: TLabel
    Left = 8
    Top = 396
    Width = 18
    Height = 13
    Caption = '      '
  end
  object Label12: TLabel
    Left = 184
    Top = 436
    Width = 18
    Height = 13
    Alignment = taRightJustify
    Caption = '      '
  end
  object btnTryFoundSeed: TButton
    Left = 8
    Top = 488
    Width = 184
    Height = 38
    Caption = 'Try Found Seed'
    Enabled = False
    TabOrder = 13
    OnClick = btnTryFoundSeedClick
  end
  object btnRun: TButton
    Left = 8
    Top = 532
    Width = 89
    Height = 38
    Caption = 'Run'
    Enabled = False
    TabOrder = 0
    OnClick = btnRunClick
  end
  object btnRunAll: TButton
    Left = 103
    Top = 576
    Width = 89
    Height = 38
    Caption = 'Run All'
    Enabled = False
    TabOrder = 10
    OnClick = btnRunAllClick
  end
  object seCycles: TSpinEdit
    Left = 8
    Top = 264
    Width = 89
    Height = 22
    MaxValue = 1000000
    MinValue = 1
    TabOrder = 1
    Value = 1
  end
  object lblDelay: TLabel
    Left = 106
    Top = 360
    Width = 31
    Height = 13
    Caption = 'Delay:'
  end
  object seDelay: TSpinEdit
    Left = 106
    Top = 376
    Width = 72
    Height = 22
    MaxValue = 10000
    MinValue = 0
    TabOrder = 14
    Value = 0
  end
  object ListBox1: TListBox
    Left = 8
    Top = 8
    Width = 185
    Height = 113
    ItemHeight = 13
    TabOrder = 2
    OnClick = ListBox1Click
  end
  object clbCategories: TCheckListBox
    Left = 8
    Top = 127
    Width = 185
    Height = 113
    ItemHeight = 13
    TabOrder = 11
    OnClick = clbCategoriesClick
  end
  object PageControl1: TPageControl
    Left = 208
    Top = 8
    Width = 881
    Height = 625
    ActivePage = TabSheet5
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 3
    object TabSheet5: TTabSheet
      Caption = 'Test Summary'
      ImageIndex = 5
      object moResults: TMemo
        Left = 0
        Top = 0
        Width = 873
        Height = 597
        Align = alClient
        Font.Name = 'Courier New'
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object Render: TTabSheet
      Caption = 'Render'
      ImageIndex = 4
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 873
        Height = 597
        Align = alClient
        Caption = 'Panel1'
        TabOrder = 0
      end
    end
  end
  object chkRender: TCheckBox
    Left = 8
    Top = 576
    Width = 57
    Height = 17
    Caption = 'Render'
    TabOrder = 4
  end
  object chkThrottleRender: TCheckBox
    Left = 8
    Top = 596
    Width = 89
    Height = 17
    Caption = 'Throttle FPS'
    Checked = True
    State = cbChecked
    TabOrder = 12
  end
  object seDuration: TSpinEdit
    Left = 103
    Top = 264
    Width = 89
    Height = 22
    MaxValue = 1000000
    MinValue = 0
    TabOrder = 5
    Value = 10
  end
  object seSeed: TSpinEdit
    Left = 8
    Top = 307
    Width = 89
    Height = 22
    MaxValue = 2000000000
    MinValue = 0
    TabOrder = 6
    Value = 4
  end
  object rgAIType: TRadioGroup
    Left = 106
    Top = 292
    Width = 96
    Height = 53
    Caption = 'AI type'
    ItemIndex = 1
    Items.Strings = (
      'Classic'
      'Advanced')
    TabOrder = 7
  end
  object btnStop: TButton
    Left = 103
    Top = 532
    Width = 89
    Height = 38
    Caption = 'Stop'
    Enabled = False
    TabOrder = 8
    OnClick = btnStopClick
  end
  object btnPause: TButton
    Left = 104
    Top = 576
    Width = 89
    Height = 21
    Caption = 'Pause'
    Enabled = False
    TabOrder = 9
    Visible = False
    OnClick = btnPauseClick
  end
end
