object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'KMR Animation Interpolator'
  ClientHeight = 625
  ClientWidth = 753
  Color = clBtnFace
  Constraints.MinHeight = 512
  Constraints.MinWidth = 512
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  DesignSize = (
    753
    625)
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 453
    Width = 21
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = 'Log:'
  end
  object Label2: TLabel
    Left = 8
    Top = 112
    Width = 35
    Height = 13
    Caption = 'Status:'
  end
  object Label3: TLabel
    Left = 232
    Top = 64
    Width = 67
    Height = 13
    Caption = 'Resume from:'
  end
  object Label4: TLabel
    Left = 8
    Top = 64
    Width = 67
    Height = 13
    Caption = 'Resume from:'
  end
  object Label5: TLabel
    Left = 120
    Top = 64
    Width = 67
    Height = 13
    Caption = 'Resume from:'
  end
  object btnProcess: TButton
    Left = 344
    Top = 8
    Width = 105
    Height = 97
    Caption = 'Process'
    TabOrder = 0
    OnClick = btnProcessClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 160
    Width = 737
    Height = 289
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object memoLog: TMemo
    Left = 8
    Top = 472
    Width = 737
    Height = 145
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 2
  end
  object chkSerfCarry: TCheckBox
    Left = 232
    Top = 24
    Width = 97
    Height = 16
    Caption = 'Serf carry \3'
    TabOrder = 3
  end
  object chkUnitActions: TCheckBox
    Left = 232
    Top = 8
    Width = 97
    Height = 16
    Caption = 'Unit actions \3'
    TabOrder = 4
  end
  object chkUnitThoughts: TCheckBox
    Left = 232
    Top = 40
    Width = 105
    Height = 16
    Caption = 'Unit thoughts \3'
    TabOrder = 5
  end
  object chkTrees: TCheckBox
    Left = 8
    Top = 8
    Width = 97
    Height = 16
    Caption = 'Trees \1'
    TabOrder = 6
  end
  object chkHouseActions: TCheckBox
    Left = 120
    Top = 8
    Width = 105
    Height = 16
    Caption = 'House actions \2'
    TabOrder = 7
  end
  object chkBeasts: TCheckBox
    Left = 120
    Top = 24
    Width = 105
    Height = 16
    Caption = 'House beasts \2'
    TabOrder = 8
  end
  object pbProgress: TProgressBar
    Left = 8
    Top = 128
    Width = 737
    Height = 25
    Step = 1
    TabOrder = 9
  end
  object cbLogVerbose: TCheckBox
    Left = 32
    Top = 453
    Width = 97
    Height = 16
    Anchors = [akLeft, akBottom]
    Caption = 'Log verbose'
    Checked = True
    State = cbChecked
    TabOrder = 10
  end
  object seUnitsResumeFrom: TSpinEdit
    Left = 232
    Top = 80
    Width = 105
    Height = 22
    MaxValue = 99999
    MinValue = 9300
    TabOrder = 11
    Value = 9300
  end
  object seTreesResumeFrom: TSpinEdit
    Left = 8
    Top = 80
    Width = 105
    Height = 22
    MaxValue = 99999
    MinValue = 260
    TabOrder = 12
    Value = 260
  end
  object seHousesResumeFrom: TSpinEdit
    Left = 120
    Top = 80
    Width = 105
    Height = 22
    MaxValue = 99999
    MinValue = 2100
    TabOrder = 13
    Value = 2100
  end
end
