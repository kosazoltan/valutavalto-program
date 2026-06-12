object ZARAS: TZARAS
  Left = 184
  Top = 101
  BorderStyle = bsNone
  Caption = 'ZARAS'
  ClientHeight = 746
  ClientWidth = 1088
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape3: TShape
    Left = 0
    Top = 0
    Width = 1024
    Height = 768
    Brush.Color = 16311512
    Pen.Width = 8
  end
  object Shape1: TShape
    Left = 160
    Top = 40
    Width = 777
    Height = 97
    Brush.Color = 11599871
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 200
    Top = 48
    Width = 699
    Height = 41
    Caption = 'AUT'#211'P'#193'LYA MATRICA  '#201'S MOBILFELT'#214'LT'#201'S '
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 360
    Top = 88
    Width = 331
    Height = 41
    Caption = 'FELAD'#193'S  '#201'S  LIST'#193'K'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object MENUSHAPE: TShape
    Left = 312
    Top = 272
    Width = 449
    Height = 210
    Brush.Color = 11599871
    Pen.Width = 3
    Shape = stRoundRect
  end
  object PILLGOMB: TBitBtn
    Left = 344
    Top = 348
    Width = 393
    Height = 25
    Cursor = crHandPoint
    Caption = 'PILLANATNYI FORINTK'#201'SZLET'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = PILLGOMBClick
    OnEnter = NAPZARGOMBEnter
    OnExit = NAPZARGOMBExit
    OnMouseMove = NAPZARGOMBMouseMove
  end
  object PENZATADGOMB: TBitBtn
    Left = 344
    Top = 308
    Width = 393
    Height = 25
    Cursor = crHandPoint
    Caption = 'P'#201'NZ'#193'TAD'#193'S - P'#201'NZ'#193'TV'#201'TEL'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = PENZATADGOMBClick
    OnEnter = NAPZARGOMBEnter
    OnExit = NAPZARGOMBExit
    OnMouseMove = NAPZARGOMBMouseMove
  end
  object LISTAKGOMB: TBitBtn
    Left = 344
    Top = 388
    Width = 393
    Height = 25
    Cursor = crHandPoint
    Caption = 'FORGALMI LIST'#193'K'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = LISTAKGOMBClick
    OnEnter = NAPZARGOMBEnter
    OnExit = NAPZARGOMBExit
    OnMouseMove = NAPZARGOMBMouseMove
  end
  object VISSZAGOMB: TBitBtn
    Left = 344
    Top = 428
    Width = 393
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA A F'#336'MEN'#220'RE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = VISSZAGOMBClick
    OnEnter = NAPZARGOMBEnter
    OnExit = NAPZARGOMBExit
    OnMouseMove = NAPZARGOMBMouseMove
  end
  object PILLPANEL: TPanel
    Left = 20
    Top = 408
    Width = 473
    Height = 321
    BevelOuter = bvNone
    Color = 11599871
    TabOrder = 2
    object Shape8: TShape
      Left = 0
      Top = 0
      Width = 473
      Height = 321
      Brush.Color = 11599871
      Pen.Color = clMoneyGreen
      Pen.Width = 12
    end
    object Label3: TLabel
      Left = 64
      Top = 72
      Width = 340
      Height = 28
      Caption = 'A KERESKED'#201'S PILLANATNYI'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 128
      Top = 128
      Width = 226
      Height = 28
      Caption = 'FORINT K'#201'SZLETE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object pillallpanel: TPanel
      Left = 56
      Top = 176
      Width = 361
      Height = 57
      BevelOuter = bvNone
      Caption = '420.000.000 Ft'
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -48
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object PILLBACKGOMB: TBitBtn
      Left = 184
      Top = 256
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = PILLBACKGOMBClick
    end
  end
  object PENZATADOPANEL: TPanel
    Left = 216
    Top = 668
    Width = 1008
    Height = 501
    BevelOuter = bvNone
    Color = 16311512
    TabOrder = 5
    object Shape2: TShape
      Left = 184
      Top = 80
      Width = 633
      Height = 41
      Brush.Color = 11599871
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Shape7: TShape
      Left = 184
      Top = 136
      Width = 633
      Height = 265
      Brush.Color = 11599871
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Shape5: TShape
      Left = 296
      Top = 24
      Width = 393
      Height = 41
      Pen.Width = 2
      Shape = stRoundRect
    end
    object TRANZAKCIOPANEL: TPanel
      Left = 192
      Top = 82
      Width = 617
      Height = 36
      BevelOuter = bvNone
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
    end
    object PENZATADBACKGOMB: TBitBtn
      Left = 856
      Top = 456
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A MEN'#220'RE'
      TabOrder = 0
      OnClick = PENZATADBACKGOMBClick
    end
    object TRANZPANEL: TPanel
      Left = 200
      Top = 152
      Width = 601
      Height = 233
      BevelOuter = bvNone
      Color = 11599871
      TabOrder = 1
      object Label10: TLabel
        Left = 112
        Top = 40
        Width = 217
        Height = 31
        Caption = 'BIZONYLATSZ'#193'M:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -27
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object OSSZEGLABEL: TLabel
        Left = 88
        Top = 136
        Width = 233
        Height = 31
        Caption = #193'TADOTT '#214'SSZEG:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -27
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object DATUMLABEL: TLabel
        Left = 128
        Top = 88
        Width = 194
        Height = 31
        Caption = #193'TAD'#193'S KELTE:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -27
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object HIDEEDITFT: TEdit
        Left = 336
        Top = 136
        Width = 89
        Height = 21
        TabOrder = 0
        Text = 'HIDEEDITFT'
        OnChange = HIDEEDITFTChange
        OnEnter = HIDEEDITFTEnter
        OnExit = HIDEEDITFTExit
        OnKeyDown = HIDEEDITFTKeyDown
      end
      object BIZONYLATPANEL: TPanel
        Left = 344
        Top = 35
        Width = 105
        Height = 41
        BevelOuter = bvNone
        Caption = 'F-000001'
        Color = 11599871
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 1
      end
      object FORINTPANEL: TPanel
        Left = 328
        Top = 128
        Width = 169
        Height = 41
        Cursor = crHandPoint
        BevelOuter = bvNone
        Caption = '10 000 000 Ft'
        Color = 11599871
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clRed
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
        OnClick = FORINTPANELClick
      end
      object DATUMPANEL: TPanel
        Left = 336
        Top = 80
        Width = 169
        Height = 41
        Cursor = crHandPoint
        BevelOuter = bvNone
        Caption = '2009.02.05'
        Color = 11599871
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -27
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
      end
      object ATADOGOMB: TBitBtn
        Left = 104
        Top = 192
        Width = 203
        Height = 25
        Cursor = crHandPoint
        Caption = #193'TAD'#193'S K'#214'NYVELHET'#214
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clGray
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 4
        OnClick = ATADOGOMBClick
        OnEnter = NAPZARGOMBEnter
        OnExit = NAPZARGOMBExit
        OnMouseMove = NAPZARGOMBMouseMove
      end
      object MEGSEMGOMB: TBitBtn
        Left = 320
        Top = 192
        Width = 201
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clGray
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 5
        OnClick = MEGSEMGOMBClick
        OnEnter = NAPZARGOMBEnter
        OnExit = NAPZARGOMBExit
        OnMouseMove = NAPZARGOMBMouseMove
      end
    end
    object penzatadogomb: TBitBtn
      Left = 304
      Top = 32
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'P'#201'NZ'#193'TAD'#193'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = penzatadogombClick
    end
    object PENZATVEVOGOMB: TBitBtn
      Left = 496
      Top = 32
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'P'#201'NZ'#193'TV'#201'TEL'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = PENZATVEVOGOMBClick
    end
    object PENZTARVALASZTOPANEL: TPanel
      Left = 16
      Top = 72
      Width = 681
      Height = 361
      BevelOuter = bvNone
      Color = 16311512
      TabOrder = 4
      object Shape4: TShape
        Left = 24
        Top = 32
        Width = 633
        Height = 257
        Pen.Width = 2
        Shape = stRoundRect
      end
      object Shape6: TShape
        Left = 152
        Top = 304
        Width = 385
        Height = 41
        Pen.Width = 2
        Shape = stRoundRect
      end
      object PENZTARRACS: TDBGrid
        Left = 48
        Top = 56
        Width = 593
        Height = 201
        BorderStyle = bsNone
        Color = clWhite
        DataSource = penztarSOURCE
        FixedColor = 11599871
        Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        OnCellClick = PENZTARRACSCellClick
        OnKeyDown = PENZTARRACSKeyDown
        Columns = <
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'PENZTARKOD'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Times New Roman'
            Font.Style = [fsItalic]
            Title.Alignment = taCenter
            Title.Caption = 'P'#201'NZT'#193'R'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -19
            Title.Font.Name = 'Times New Roman'
            Title.Font.Style = [fsItalic]
            Width = 106
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'PENZTARNEV'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Times New Roman'
            Font.Style = [fsItalic]
            Title.Alignment = taCenter
            Title.Caption = 'P'#201'NZT'#193'R NEVE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -19
            Title.Font.Name = 'Times New Roman'
            Title.Font.Style = [fsItalic]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'PENZTARCIM'
            Font.Charset = EASTEUROPE_CHARSET
            Font.Color = clWindowText
            Font.Height = -13
            Font.Name = 'Times New Roman'
            Font.Style = [fsItalic]
            Title.Alignment = taCenter
            Title.Caption = 'P'#201'NZT'#193'R CIME'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -19
            Title.Font.Name = 'Times New Roman'
            Title.Font.Style = [fsItalic]
            Visible = True
          end>
      end
      object valasztoGomb: TBitBtn
        Left = 160
        Top = 312
        Width = 185
        Height = 25
        Cursor = crHandPoint
        Caption = 'EZT V'#193'LASZTOM'
        TabOrder = 1
        OnClick = valasztoGombClick
      end
      object megsemvalasztogomb: TBitBtn
        Left = 344
        Top = 312
        Width = 185
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM V'#193'LASZTOK'
        TabOrder = 2
        OnClick = megsemvalasztogombClick
      end
    end
  end
  object LISTAPANEL: TPanel
    Left = 24
    Top = 86
    Width = 993
    Height = 555
    Color = clSkyBlue
    TabOrder = 6
    object TRADERACS: TDBGrid
      Left = 8
      Top = 56
      Width = 969
      Height = 449
      Color = 13697023
      DataSource = DataSource1
      FixedColor = 10551295
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      ReadOnly = True
      TabOrder = 0
      TitleFont.Charset = EASTEUROPE_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -16
      TitleFont.Name = 'Times New Roman'
      TitleFont.Style = [fsBold, fsItalic]
      OnCellClick = TRADERACSCellClick
      OnDblClick = TRADERACSDblClick
      OnKeyUp = TRADERACSKeyUp
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'TIPUS'
          Title.Alignment = taCenter
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Width = 56
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'DATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUM'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Width = 74
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'BIZONYLATSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'BIZONYLAT'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'FIZETENDO'
          Title.Alignment = taCenter
          Title.Caption = #214'SSZEG'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Width = 78
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'TRANZAKCIO'
          Title.Alignment = taCenter
          Title.Caption = 'TRANZ.'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Width = 121
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'RENDSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'RENDSZ'#193'M'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Width = 115
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'KATEGORIA'
          Title.Alignment = taCenter
          Title.Caption = 'KATEG.'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Width = 76
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'STARTDATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUMT'#211'L'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'ENDDATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUMIG'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'COUNTRYNAME'
          Title.Alignment = taCenter
          Title.Caption = 'ORSZ'#193'G'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'REFERENCEID'
          Title.Alignment = taCenter
          Title.Caption = 'REFER'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'SZOLGALTATO'
          Title.Alignment = taCenter
          Title.Caption = 'SZOLG'#193'LTAT'#211
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'MS Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'SZOLGALTATAS'
          Title.Alignment = taCenter
          Title.Caption = 'SZOLGALTAT'#193'S'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'MS Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'PENZTAROSNEV'
          Title.Alignment = taCenter
          Title.Caption = 'P'#201'NZT'#193'ROS'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'IDO'
          Title.Caption = 'ID'#336
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TELEFONSZAM'
          Width = 159
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'STORNO'
          Title.Alignment = taCenter
          Visible = True
        end>
    end
    object LEVKOMBO: TComboBox
      Left = 416
      Top = 8
      Width = 89
      Height = 39
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ItemHeight = 31
      ParentFont = False
      TabOrder = 1
      Text = '2010'
      OnChange = LEVKOMBOChange
    end
    object LHONAPKOMBO: TComboBox
      Left = 520
      Top = 8
      Width = 225
      Height = 35
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 27
      ParentFont = False
      TabOrder = 2
      Text = 'SZEPTEMBER'
      OnChange = LEVKOMBOChange
    end
    object lvisszaGOMB: TBitBtn
      Left = 768
      Top = 520
      Width = 179
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A MEN'#220'RE'
      TabOrder = 3
      OnClick = lvisszaGOMBClick
    end
    object STORNOGOMB: TBitBtn
      Left = 88
      Top = 520
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'BIZONYLAT STORN'#211'Z'#193'SA'
      TabOrder = 4
      OnClick = STORNOGOMBClick
    end
  end
  object TRADEQUERY: TIBQuery
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object TRADEDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\TRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TRADETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object TRADETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRADEDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object TRADETABLA: TIBTable
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'TIPUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end
      item
        Name = 'BIZONYLATSZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 8
      end
      item
        Name = 'KATEGORIA'
        Attributes = [faFixed]
        DataType = ftString
        Size = 33
      end
      item
        Name = 'STARTDATUM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'ENDDATUM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'TELEFONSZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 12
      end
      item
        Name = 'RENDSZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'COUNTRYNAME'
        Attributes = [faFixed]
        DataType = ftString
        Size = 30
      end
      item
        Name = 'REFERENCEID'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end
      item
        Name = 'TRANZAKCIO'
        Attributes = [faFixed]
        DataType = ftString
        Size = 12
      end
      item
        Name = 'FIZETENDO'
        DataType = ftInteger
      end
      item
        Name = 'PENZTAROSNEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end
      item
        Name = 'DATUM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'IDO'
        Attributes = [faFixed]
        DataType = ftString
        Size = 8
      end
      item
        Name = 'SZOLGALTATO'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'SZOLGALTATAS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 30
      end
      item
        Name = 'UGYFELSZAM'
        DataType = ftInteger
      end
      item
        Name = 'UGYFELNEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end
      item
        Name = 'UGYFELCIM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 40
      end
      item
        Name = 'TARSPENZTAR'
        Attributes = [faFixed]
        DataType = ftString
        Size = 4
      end
      item
        Name = 'ELKULDVE'
        DataType = ftSmallint
      end
      item
        Name = 'STORNO'
        DataType = ftSmallint
      end>
    StoreDefs = True
    TableName = 'TRAD1111'
    Left = 8
    Top = 40
    object TRADETABLATIPUS: TIBStringField
      FieldName = 'TIPUS'
      FixedChar = True
      Size = 1
    end
    object TRADETABLABIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      FixedChar = True
      Size = 8
    end
    object TRADETABLAKATEGORIA: TIBStringField
      FieldName = 'KATEGORIA'
      FixedChar = True
      Size = 33
    end
    object TRADETABLASTARTDATUM: TIBStringField
      FieldName = 'STARTDATUM'
      FixedChar = True
      Size = 10
    end
    object TRADETABLAENDDATUM: TIBStringField
      FieldName = 'ENDDATUM'
      FixedChar = True
      Size = 10
    end
    object TRADETABLATELEFONSZAM: TIBStringField
      FieldName = 'TELEFONSZAM'
      FixedChar = True
      Size = 12
    end
    object TRADETABLARENDSZAM: TIBStringField
      FieldName = 'RENDSZAM'
      FixedChar = True
      Size = 10
    end
    object TRADETABLACOUNTRYNAME: TIBStringField
      FieldName = 'COUNTRYNAME'
      FixedChar = True
      Size = 30
    end
    object TRADETABLAREFERENCEID: TIBStringField
      FieldName = 'REFERENCEID'
      FixedChar = True
      Size = 25
    end
    object TRADETABLATRANZAKCIO: TIBStringField
      FieldName = 'TRANZAKCIO'
      FixedChar = True
      Size = 12
    end
    object TRADETABLAFIZETENDO: TIntegerField
      FieldName = 'FIZETENDO'
    end
    object TRADETABLAPENZTAROSNEV: TIBStringField
      FieldName = 'PENZTAROSNEV'
      FixedChar = True
      Size = 25
    end
    object TRADETABLADATUM: TIBStringField
      FieldName = 'DATUM'
      FixedChar = True
      Size = 10
    end
    object TRADETABLAIDO: TIBStringField
      FieldName = 'IDO'
      FixedChar = True
      Size = 8
    end
    object TRADETABLASZOLGALTATO: TIBStringField
      FieldName = 'SZOLGALTATO'
      FixedChar = True
      Size = 10
    end
    object TRADETABLASZOLGALTATAS: TIBStringField
      FieldName = 'SZOLGALTATAS'
      FixedChar = True
      Size = 30
    end
    object TRADETABLAUGYFELSZAM: TIntegerField
      FieldName = 'UGYFELSZAM'
    end
    object TRADETABLAUGYFELNEV: TIBStringField
      FieldName = 'UGYFELNEV'
      FixedChar = True
      Size = 25
    end
    object TRADETABLAUGYFELCIM: TIBStringField
      FieldName = 'UGYFELCIM'
      FixedChar = True
      Size = 40
    end
    object TRADETABLATARSPENZTAR: TIBStringField
      FieldName = 'TARSPENZTAR'
      FixedChar = True
      Size = 4
    end
    object TRADETABLAELKULDVE: TSmallintField
      FieldName = 'ELKULDVE'
    end
    object TRADETABLASTORNO: TSmallintField
      FieldName = 'STORNO'
    end
  end
  object DataSource1: TDataSource
    DataSet = TRADEQUERY
    Left = 32
    Top = 304
  end
  object PENZTARQUERY: TIBQuery
    Database = PENZTARDBASE
    Transaction = PENZTARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 8
    Top = 136
  end
  object PENZTARDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PENZTARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 136
  end
  object PENZTARTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PENZTARDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 136
  end
  object penztarSOURCE: TDataSource
    DataSet = PENZTARQUERY
    Left = 40
    Top = 248
  end
end
