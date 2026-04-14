object Form2: TForm2
  Left = 244
  Top = 289
  Caption = 'Testing_GameTests'
  ClientHeight = 633
  ClientWidth = 1065
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 392
    Width = 35
    Height = 13
    Caption = 'Cycles:'
  end
  object Label2: TLabel
    Left = 176
    Top = 408
    Width = 15
    Height = 13
    Alignment = taRightJustify
    Caption = '     '
  end
  object Label7: TLabel
    Left = 8
    Top = 432
    Width = 28
    Height = 13
    Caption = 'Seed:'
  end
  object lblDelay: TLabel
    Left = 104
    Top = 432
    Width = 31
    Height = 13
    Caption = 'Delay:'
  end
  object Label3: TLabel
    Left = 8
    Top = 256
    Width = 27
    Height = 13
    Caption = 'Tags:'
  end
  object Label5: TLabel
    Left = 8
    Top = 8
    Width = 30
    Height = 13
    Caption = 'Tests:'
  end
  object btnTryFoundSeed: TButton
    Left = 8
    Top = 496
    Width = 184
    Height = 33
    Caption = 'Try Found Seed'
    Enabled = False
    TabOrder = 10
    OnClick = btnTryFoundSeedClick
  end
  object btnRun: TButton
    Left = 8
    Top = 536
    Width = 89
    Height = 33
    Caption = 'Run'
    Enabled = False
    TabOrder = 0
    OnClick = btnRunClick
  end
  object btnRunAll: TButton
    Left = 104
    Top = 576
    Width = 89
    Height = 33
    Caption = 'Run All'
    Enabled = False
    TabOrder = 7
    OnClick = btnRunAllClick
  end
  object seCycles: TSpinEdit
    Left = 8
    Top = 408
    Width = 81
    Height = 22
    MaxValue = 1000000
    MinValue = 1
    TabOrder = 1
    Value = 1
  end
  object seDelay: TSpinEdit
    Left = 104
    Top = 448
    Width = 81
    Height = 22
    MaxValue = 10000
    MinValue = 0
    TabOrder = 11
    Value = 0
  end
  object ListBox1: TListBox
    Left = 8
    Top = 24
    Width = 185
    Height = 225
    ItemHeight = 13
    TabOrder = 2
    OnClick = ListBox1Click
  end
  object clbCategories: TCheckListBox
    Left = 8
    Top = 272
    Width = 185
    Height = 113
    ItemHeight = 17
    TabOrder = 8
    OnClick = clbCategoriesClick
  end
  object pcMain: TPageControl
    Left = 200
    Top = 8
    Width = 857
    Height = 617
    ActivePage = tsLog
    TabOrder = 3
    object tsLog: TTabSheet
      Caption = 'Log'
      ImageIndex = 5
      object meLog: TMemo
        Left = 0
        Top = 0
        Width = 849
        Height = 589
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object tsRender: TTabSheet
      Caption = 'Render'
      ImageIndex = 4
      object pnlRender: TPanel
        Left = 0
        Top = 0
        Width = 849
        Height = 589
        Align = alClient
        Caption = 'pnlRender'
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
    Top = 600
    Width = 89
    Height = 17
    Caption = 'Throttle FPS'
    Checked = True
    State = cbChecked
    TabOrder = 9
  end
  object seSeed: TSpinEdit
    Left = 8
    Top = 448
    Width = 81
    Height = 22
    MaxValue = 2000000000
    MinValue = 0
    TabOrder = 5
    Value = 4
  end
  object btnStop: TButton
    Left = 104
    Top = 536
    Width = 89
    Height = 33
    Caption = 'Stop'
    Enabled = False
    TabOrder = 6
    OnClick = btnStopClick
  end
end
