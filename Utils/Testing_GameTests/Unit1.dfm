object Form2: TForm2
  Left = 244
  Top = 289
  Caption = 'Testing_GameTests'
  ClientHeight = 633
  ClientWidth = 1185
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  DesignSize = (
    1185
    633)
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
  object btnRunOne: TButton
    Left = 8
    Top = 496
    Width = 89
    Height = 25
    Caption = 'Run One'
    Enabled = False
    TabOrder = 0
    OnClick = btnRunOneClick
  end
  object btnRunAll: TButton
    Left = 8
    Top = 528
    Width = 89
    Height = 25
    Caption = 'Run All'
    Enabled = False
    TabOrder = 6
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
    TabOrder = 9
    Value = 0
  end
  object lbTests: TListBox
    Left = 8
    Top = 24
    Width = 225
    Height = 225
    ItemHeight = 13
    TabOrder = 2
    OnClick = lbTestsClick
  end
  object clbTags: TCheckListBox
    Left = 8
    Top = 272
    Width = 225
    Height = 113
    ItemHeight = 13
    TabOrder = 7
    OnClick = clbTagsClick
  end
  object chkRender: TCheckBox
    Left = 104
    Top = 480
    Width = 57
    Height = 17
    Caption = 'Render'
    TabOrder = 3
    OnClick = chkRenderClick
  end
  object chkThrottleRender: TCheckBox
    Left = 104
    Top = 504
    Width = 89
    Height = 17
    Caption = 'Throttle FPS'
    Checked = True
    State = cbChecked
    TabOrder = 8
  end
  object seSeed: TSpinEdit
    Left = 8
    Top = 448
    Width = 81
    Height = 22
    MaxValue = 2000000000
    MinValue = 0
    TabOrder = 4
    Value = 4
  end
  object btnStop: TButton
    Left = 8
    Top = 592
    Width = 89
    Height = 25
    Caption = 'Stop'
    Enabled = False
    TabOrder = 5
    OnClick = btnStopClick
  end
  object Panel1: TPanel
    Left = 240
    Top = 8
    Width = 937
    Height = 617
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Panel1'
    TabOrder = 10
    object Splitter1: TSplitter
      Left = 481
      Top = 1
      Width = 4
      Height = 615
      ResizeStyle = rsUpdate
      ExplicitLeft = 401
    end
    object pnlRender: TPanel
      Left = 1
      Top = 1
      Width = 480
      Height = 615
      Align = alLeft
      Caption = 'pnlRender'
      TabOrder = 0
    end
    object meLog: TMemo
      Left = 485
      Top = 1
      Width = 451
      Height = 615
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 1
      ExplicitLeft = -480
      ExplicitTop = -348
      ExplicitWidth = 929
      ExplicitHeight = 589
    end
  end
end
