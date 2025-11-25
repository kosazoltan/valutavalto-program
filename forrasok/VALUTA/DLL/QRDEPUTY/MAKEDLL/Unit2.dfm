object Form2: TForm2
  Left = 192
  Top = 124
  BorderStyle = bsNone
  Caption = 'Adatk'#252'ld'#233's a NAV-os p'#233'nzt'#225'rg'#233'pre'
  ClientHeight = 403
  ClientWidth = 388
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object ALAPPANEL: TPanel
    Left = 0
    Top = 0
    Width = 385
    Height = 401
    BevelOuter = bvNone
    Color = 11599871
    TabOrder = 0
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 385
      Height = 401
      Align = alClient
      Brush.Color = clGray
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label4: TLabel
      Left = 16
      Top = 80
      Width = 363
      Height = 22
      Caption = 'A TRANZAKCI'#211' ADATAINAK '#193'TK'#220'LD'#201'SE_'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Stencil'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label6: TLabel
      Left = 80
      Top = 104
      Width = 233
      Height = 22
      Caption = 'A NAV-OS P'#201'NZT'#193'RG'#201'PRE.'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Stencil'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label7: TLabel
      Left = 144
      Top = 144
      Width = 95
      Height = 17
      Caption = 'TRANZAKCI'#211':'
      Font.Charset = ANSI_CHARSET
      Font.Color = clYellow
      Font.Height = -16
      Font.Name = 'Britannic Bold'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label8: TLabel
      Left = 160
      Top = 208
      Width = 58
      Height = 17
      Caption = 'VALUTA:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clYellow
      Font.Height = -16
      Font.Name = 'Britannic Bold'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label9: TLabel
      Left = 160
      Top = 272
      Width = 56
      Height = 17
      Caption = 'FORINT:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clYellow
      Font.Height = -16
      Font.Name = 'Britannic Bold'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object MERETPANEL: TPanel
      Left = 56
      Top = 424
      Width = 33
      Height = 41
      BevelOuter = bvNone
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object MEHETGOMB: TBitBtn
      Left = 8
      Top = 364
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'MEHET AZ ADAT'#193'TVITEL'
      Enabled = False
      TabOrder = 0
      OnClick = MEHETGOMBClick
    end
    object MEGSEMGOMB: TBitBtn
      Left = 200
      Top = 364
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'NE  K'#220'LDJE '#193'T AZ ADATOKAT'
      TabOrder = 3
      OnClick = MEGSEMGOMBClick
    end
    object QRTAKARO: TPanel
      Left = -777
      Top = 5
      Width = 640
      Height = 640
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 1
      Visible = False
      object Shape1: TShape
        Left = 144
        Top = 152
        Width = 337
        Height = 329
        Brush.Color = clRed
        Pen.Width = 3
        Shape = stCircle
      end
      object Label1: TLabel
        Left = 240
        Top = 240
        Width = 150
        Height = 29
        Caption = 'OLVASSA BE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -24
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label2: TLabel
        Left = 160
        Top = 304
        Width = 305
        Height = 29
        Caption = 'A MINDJ'#193'RT MEGJELEN'#336
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -24
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label3: TLabel
        Left = 256
        Top = 368
        Width = 128
        Height = 29
        Caption = 'QR-K'#211'DOT'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -24
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
    end
    object N1PANEL: TPanel
      Left = 16
      Top = 4
      Width = 353
      Height = 33
      BevelOuter = bvNone
      Caption = ' '
      Color = clGray
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
    object TRANZPANEL: TPanel
      Left = 24
      Top = 168
      Width = 329
      Height = 25
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 5
    end
    object VALPANEL: TPanel
      Left = 16
      Top = 232
      Width = 329
      Height = 25
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 6
    end
    object HUFPANEL: TPanel
      Left = 24
      Top = 296
      Width = 329
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 7
    end
    object N2PANEL: TPanel
      Left = 16
      Top = 32
      Width = 353
      Height = 33
      BevelOuter = bvNone
      Caption = ' '
      Color = clGray
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
    object DISPLAYGOMB: TBitBtn
      Left = 200
      Top = 332
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'PARANCS KIJELZ'#201'SE'
      TabOrder = 9
      OnClick = DISPLAYGOMBClick
    end
    object MEMOPANEL: TPanel
      Left = -1200
      Top = 8
      Width = 369
      Height = 353
      BevelOuter = bvNone
      TabOrder = 10
      Visible = False
      object MEMO: TMemo
        Left = 0
        Top = 0
        Width = 369
        Height = 353
        Align = alClient
        BorderStyle = bsNone
        Color = clWhite
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Lines.Strings = (
          '')
        ParentFont = False
        TabOrder = 0
      end
    end
    object SUREPANEL: TPanel
      Left = 8
      Top = 328
      Width = 369
      Height = 65
      BevelOuter = bvNone
      Caption = ' '
      Color = clRed
      TabOrder = 11
      Visible = False
      object Label5: TLabel
        Left = 24
        Top = 8
        Width = 318
        Height = 26
        Caption = 'KIJ'#214'TT A PAPIR A P'#201'NZT'#193'RG'#201'PB'#336'L ?'
        Font.Charset = ANSI_CHARSET
        Font.Color = clYellow
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object IGENRENDBENGOMB: TBitBtn
        Left = 8
        Top = 36
        Width = 105
        Height = 21
        Cursor = crHandPoint
        Caption = 'IGEN RENDBEN'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnClick = IGENRENDBENGOMBClick
      end
      object UJRAKULDOGOMB: TBitBtn
        Left = 136
        Top = 36
        Width = 105
        Height = 21
        Cursor = crHandPoint
        Caption = #218'JRA KIK'#220'LD'#214'M'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = UJRAKULDOGOMBClick
      end
      object MRGSEMGOMB: TBitBtn
        Left = 256
        Top = 36
        Width = 105
        Height = 21
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
        OnClick = MRGSEMGOMBClick
      end
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 296
    Top = 8
  end
end
