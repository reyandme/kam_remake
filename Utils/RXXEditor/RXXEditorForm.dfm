object RXXForm1: TRXXForm1
  Left = 72
  Top = 90
  Caption = 'RXX Editor'
  ClientHeight = 514
  ClientWidth = 473
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 40
    Width = 54
    Height = 13
    Caption = 'Contents:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 224
    Top = 40
    Width = 65
    Height = 13
    Caption = 'Main image'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label3: TLabel
    Left = 224
    Top = 290
    Width = 68
    Height = 13
    Caption = 'Mask image'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object btnAdd: TButton
    Left = 8
    Top = 474
    Width = 81
    Height = 25
    Caption = 'Add Image ...'
    Enabled = False
    TabOrder = 0
    OnClick = btnAddClick
  end
  object btnSaveRXX: TButton
    Left = 96
    Top = 8
    Width = 81
    Height = 25
    Caption = 'Save RXX ...'
    Enabled = False
    TabOrder = 1
    OnClick = btnSaveRXXClick
  end
  object lbSpritesList: TListBox
    Left = 8
    Top = 56
    Width = 209
    Height = 412
    ItemHeight = 13
    TabOrder = 2
    OnClick = lbSpritesListClick
  end
  object btnLoadRXX: TButton
    Left = 8
    Top = 8
    Width = 81
    Height = 25
    Caption = 'Load RXX ...'
    TabOrder = 3
    OnClick = btnLoadRXXClick
  end
  object btnDelete: TButton
    Left = 96
    Top = 474
    Width = 81
    Height = 25
    Caption = 'Delete image'
    Enabled = False
    TabOrder = 4
    OnClick = btnDeleteClick
  end
  object btnReplace: TButton
    Left = 224
    Top = 250
    Width = 105
    Height = 25
    Caption = 'Replace image ...'
    Enabled = False
    TabOrder = 5
    OnClick = btnReplaceClick
  end
  object btnExport: TButton
    Left = 336
    Top = 250
    Width = 97
    Height = 25
    Caption = 'Export image ...'
    Enabled = False
    TabOrder = 6
    OnClick = btnExportClick
  end
  object Panel1: TPanel
    Left = 224
    Top = 56
    Width = 242
    Height = 162
    BevelOuter = bvLowered
    TabOrder = 7
    object Image1: TImage
      Left = 1
      Top = 1
      Width = 240
      Height = 160
      Align = alClient
      Proportional = True
      Stretch = True
      Transparent = True
      ExplicitLeft = 24
      ExplicitTop = -56
      ExplicitWidth = 209
      ExplicitHeight = 169
    end
  end
  object Panel2: TPanel
    Left = 224
    Top = 306
    Width = 242
    Height = 162
    BevelOuter = bvLowered
    TabOrder = 8
    object Image2: TImage
      Left = 1
      Top = 1
      Width = 240
      Height = 160
      Align = alClient
      Proportional = True
      Stretch = True
      Transparent = True
      ExplicitLeft = 233
      ExplicitTop = 33
    end
  end
  object btnMaskReplace: TButton
    Left = 224
    Top = 474
    Width = 105
    Height = 25
    Caption = 'Replace mask ...'
    Enabled = False
    TabOrder = 9
    OnClick = btnMaskReplaceClick
  end
  object btnMaskExport: TButton
    Left = 336
    Top = 474
    Width = 97
    Height = 25
    Caption = 'Export mask ...'
    Enabled = False
    TabOrder = 10
    OnClick = btnMaskExportClick
  end
  object edtPivotX: TSpinEdit
    Left = 352
    Top = 32
    Width = 57
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 11
    Value = 0
    OnChange = PivotChange
  end
  object edtPivotY: TSpinEdit
    Left = 408
    Top = 32
    Width = 57
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 12
    Value = 0
    OnChange = PivotChange
  end
  object chkHasMask: TCheckBox
    Left = 400
    Top = 290
    Width = 65
    Height = 15
    Caption = 'Has mask'
    Enabled = False
    TabOrder = 13
    OnClick = chkHasMaskClick
  end
  object chbImageStretch: TCheckBox
    Left = 224
    Top = 224
    Width = 241
    Height = 18
    Cursor = crHandPoint
    Caption = 'Stretch'
    Checked = True
    State = cbChecked
    TabOrder = 14
    OnClick = chbImageStretchClick
  end
  object OpenDialog1: TOpenDialog
    OnShow = OpenDialog1Show
    Filter = 'Supported images (*.bmp;*.png)|*.bmp;*.png'
    Options = [ofAllowMultiSelect, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Select images'
    Left = 32
    Top = 72
  end
  object SaveDialog1: TSaveDialog
    OnShow = SaveDialog1Show
    DefaultExt = '*.rxx'
    Filter = 'RXX packages (*.rxx)|*.rxx'
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 32
    Top = 128
  end
end
