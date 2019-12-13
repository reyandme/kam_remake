object FormLogistics: TFormLogistics
  Left = 0
  Top = 0
  Caption = 'FormLogistics'
  ClientHeight = 615
  ClientWidth = 707
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object TabControl1: TTabControl
    Left = 0
    Top = 0
    Width = 700
    Height = 617
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    Tabs.Strings = (
      'Deliveries'
      'Offers'
      'Demands')
    TabIndex = 0
    OnChange = TabControl1Change
    object DeliveriesList: TListView
      Left = 4
      Top = 24
      Width = 692
      Height = 589
      Align = alClient
      Columns = <
        item
          Caption = '#'
          Width = 30
        end
        item
          Caption = 'Hand'
          Width = 40
        end
        item
          Caption = 'Resource'
          Width = 100
        end
        item
          Caption = 'From house'
          Width = 120
        end
        item
          Caption = 'FrID'
          Width = 70
        end
        item
          Caption = 'To'
          Width = 120
        end
        item
          Caption = 'ToID'
          Width = 70
        end
        item
          Caption = 'Serf'
          Width = 70
        end>
      HideSelection = False
      RowSelect = True
      SortType = stBoth
      TabOrder = 1
      ViewStyle = vsReport
    end
    object DemandsList: TListView
      Left = 4
      Top = 24
      Width = 692
      Height = 589
      Align = alClient
      Columns = <
        item
          Caption = '#'
          Width = 30
        end
        item
          Caption = 'Hand'
          Width = 40
        end
        item
          Caption = 'Resource'
          Width = 100
        end
        item
          Caption = 'To'
          Width = 120
        end
        item
          Caption = 'ToID'
          Width = 70
        end
        item
          Caption = 'Type'
          Width = 60
        end
        item
          Caption = 'Importance'
          Width = 60
        end
        item
          Caption = 'Performed'
          Width = 70
        end
        item
          Caption = 'Deleted'
          Width = 60
        end>
      RowSelect = True
      TabOrder = 2
      ViewStyle = vsReport
      Visible = False
    end
    object OffersList: TListView
      Left = 4
      Top = 24
      Width = 692
      Height = 589
      Align = alClient
      Columns = <
        item
          Caption = '#'
          Width = 30
        end
        item
          Caption = 'Hand'
          Width = 40
        end
        item
          Caption = 'Resource'
          Width = 100
        end
        item
          Caption = 'HouseFrom'
          Width = 120
        end
        item
          Caption = 'FromID'
          Width = 70
        end
        item
          Caption = 'Count'
          Width = 50
        end
        item
          Caption = 'Performed'
          Width = 70
        end
        item
          Caption = 'Deleted'
          Width = 60
        end>
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
      Visible = False
    end
  end
end
