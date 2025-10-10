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
    Left = 224
    Top = 48
    Width = 35
    Height = 13
    Caption = 'Status:'
  end
  object btnProcess: TButton
    Left = 8
    Top = 64
    Width = 209
    Height = 25
    Caption = 'Process'
    TabOrder = 0
    OnClick = btnProcessClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 96
    Width = 737
    Height = 353
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
    Left = 8
    Top = 24
    Width = 97
    Height = 16
    Caption = 'Serf carry'
    TabOrder = 3
  end
  object chkUnitActions: TCheckBox
    Left = 8
    Top = 8
    Width = 97
    Height = 16
    Caption = 'Unit actions'
    TabOrder = 4
  end
  object chkUnitThoughts: TCheckBox
    Left = 8
    Top = 40
    Width = 97
    Height = 16
    Caption = 'Unit thoughts'
    TabOrder = 5
  end
  object chkTrees: TCheckBox
    Left = 112
    Top = 8
    Width = 97
    Height = 16
    Caption = 'Trees'
    TabOrder = 6
  end
  object chkHouseActions: TCheckBox
    Left = 112
    Top = 24
    Width = 97
    Height = 16
    Caption = 'House actions'
    TabOrder = 7
  end
  object chkBeasts: TCheckBox
    Left = 112
    Top = 40
    Width = 97
    Height = 16
    Caption = 'House beasts'
    TabOrder = 8
  end
  object pbProgress: TProgressBar
    Left = 224
    Top = 64
    Width = 521
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
    TabOrder = 10
  end
end
