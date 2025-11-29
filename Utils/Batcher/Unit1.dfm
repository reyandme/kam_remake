object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Batcher'
  ClientHeight = 454
  ClientWidth = 883
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  PixelsPerInch = 96
  DesignSize = (
    883
    454)
  TextHeight = 13
  object Button1: TButton
    Left = 24
    Top = 64
    Width = 185
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Mass rename sprites'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 24
    Top = 104
    Width = 121
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Check goals count'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Memo1: TMemo
    Left = 360
    Top = 25
    Width = 476
    Height = 296
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object Button4: TButton
    Left = 24
    Top = 128
    Width = 121
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Rip time goals'
    TabOrder = 3
    OnClick = Button4Click
  end
  object btnUnXorAll: TButton
    Left = 288
    Top = 336
    Width = 121
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'unXOR all maps'
    TabOrder = 4
    OnClick = btnXorAllClick
  end
  object btnXorAll: TButton
    Left = 288
    Top = 365
    Width = 121
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'XOR all maps'
    TabOrder = 5
    OnClick = btnXorAllClick
  end
  object Button7: TButton
    Left = 24
    Top = 152
    Width = 121
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Show message goals'
    TabOrder = 6
    OnClick = Button7Click
  end
  object Button8: TButton
    Left = 24
    Top = 176
    Width = 185
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Append user players to MP maps'
    TabOrder = 7
    OnClick = Button8Click
  end
  object Button5: TButton
    Left = 24
    Top = 200
    Width = 185
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Add AI players to MP maps'
    TabOrder = 8
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 24
    Top = 264
    Width = 185
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Add AI auto config to MP maps'
    TabOrder = 9
    OnClick = Button6Click
  end
  object Button9: TButton
    Left = 423
    Top = 336
    Width = 154
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Fix script text'
    TabOrder = 10
    OnClick = Button9Click
  end
  object btnCheckColor: TButton
    Left = 7
    Top = 336
    Width = 258
    Height = 25
    Hint = 
      'Check if there is color specified in *.dat file for every player' +
      ' by either SET_MAP_COLOR or SET_RGB_COLOR command'
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Check all maps set color explicitly'
    TabOrder = 11
    OnClick = btnCheckColorClick
  end
  object btnSetDefColor: TButton
    Left = 7
    Top = 365
    Width = 258
    Height = 25
    Hint = 
      'Add SET_RGB_COLOR command for players without color commands in ' +
      '*.dat for all maps'
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Set all maps missing colors explicitly with defaults'
    TabOrder = 12
    OnClick = btnCheckColorClick
  end
  object btnRemoveNewRemap: TButton
    Left = 7
    Top = 394
    Width = 258
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Remove SET_NEW_REMAP from all maps'
    TabOrder = 13
    OnClick = btnRemoveNewRemapClick
  end
  object btnDeleteUnusedSetMapColor: TButton
    Left = 7
    Top = 423
    Width = 258
    Height = 25
    Hint = 
      'Some maps have both SET_MAP_COLOR and SET_RGB_COLOR, SET_MAP_COL' +
      'OR is always coming first, means SET_RGB_COLOR is always overrid' +
      'ing color previously set by SET_MAP_COLOR. 4th button finds all ' +
      'such maps and deletes SET_MAP_COLOR command.'
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Delete unused SET_MAP_COLOR for all maps'
    TabOrder = 14
    OnClick = btnDeleteUnusedSetMapColorClick
  end
  object Button10: TButton
    Left = 24
    Top = 227
    Width = 321
    Height = 25
    Hint = 'Add Advanced AI players to MP maps'
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Add AdvancedAI to MP maps, where Human+AI players'
    TabOrder = 15
    OnClick = Button10Click
  end
  object Button11: TButton
    Left = 423
    Top = 365
    Width = 154
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'LF -> CRLF all maps'
    TabOrder = 16
    OnClick = Button11Click
  end
  object Button12: TButton
    Left = 423
    Top = 394
    Width = 154
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'LF -> CRLF all Units *.pas'
    TabOrder = 17
    OnClick = Button12Click
  end
  object Button13: TButton
    Left = 615
    Top = 336
    Width = 170
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Resave all maps'
    TabOrder = 18
    OnClick = Button13Click
  end
  object Button14: TButton
    Left = 213
    Top = 200
    Width = 132
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Add missing AI players'
    TabOrder = 19
    OnClick = Button14Click
  end
  object Button15: TButton
    Left = 24
    Top = 307
    Width = 241
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Generate Utils DCC_UnitSearchPath for .dproj'
    TabOrder = 20
    OnClick = Button15Click
  end
  object Button16: TButton
    Left = 615
    Top = 394
    Width = 170
    Height = 25
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Rebuild anim tiles into plain form'
    TabOrder = 21
    OnClick = Button16Click
  end
end
