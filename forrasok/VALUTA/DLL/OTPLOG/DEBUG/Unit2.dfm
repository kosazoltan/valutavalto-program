object Form2: TForm2
  Left = 203
  Top = 123
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 481
  ClientWidth = 835
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 835
    Height = 481
    Align = alClient
    Brush.Color = clBtnFace
    Pen.Width = 3
  end
  object Label2: TLabel
    Left = 128
    Top = 24
    Width = 613
    Height = 38
    Caption = 'OTP TERMIN'#193'L LOG KIOLVAS'#193'SA'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Elephant'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object NAPTARPANEL: TPanel
    Left = 168
    Top = 104
    Width = 537
    Height = 305
    Color = clMoneyGreen
    TabOrder = 0
    object Label1: TLabel
      Left = 128
      Top = 8
      Width = 303
      Height = 34
      Caption = 'v'#225'lassza ki a kiv'#225'nt napot'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object NAPTAR: TCalendar
      Left = 24
      Top = 88
      Width = 497
      Height = 168
      Cursor = crHandPoint
      StartOfWeek = 0
      TabOrder = 0
      OnChange = NAPTARChange
    end
    object PREHONAP: TBitBtn
      Left = 24
      Top = 56
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'El'#246'z'#337' h'#243'nap'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = PREHONAPClick
    end
    object DATUMPANEL: TPanel
      Left = 184
      Top = 56
      Width = 177
      Height = 25
      Caption = '2020.12.31'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object NEXTHONAP: TBitBtn
      Left = 368
      Top = 56
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#246'vetkez'#337' h'#243'nap'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = NEXTHONAPClick
    end
    object NAPOKEGOMB: TBitBtn
      Left = 24
      Top = 264
      Width = 241
      Height = 25
      Cursor = crHandPoint
      Caption = 'Ezt a napot k'#233'rem'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = NAPOKEGOMBClick
    end
    object NAPTARVISSZAGOMB: TBitBtn
      Left = 272
      Top = 264
      Width = 241
      Height = 25
      Cursor = crHandPoint
      Caption = 'Vissza a f'#337'men'#369're'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = NAPTARVISSZAGOMBClick
    end
  end
  object LOGPANEL: TPanel
    Left = -1987
    Top = 80
    Width = 815
    Height = 393
    BevelOuter = bvNone
    TabOrder = 1
    Visible = False
    object LOGBOX: TListBox
      Left = 16
      Top = 48
      Width = 785
      Height = 305
      BorderStyle = bsNone
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ItemHeight = 14
      ParentFont = False
      ScrollWidth = 1850
      TabOrder = 0
    end
    object logPanelcim: TPanel
      Left = 16
      Top = 16
      Width = 785
      Height = 25
      BevelOuter = bvNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object ujnapgomb: TBitBtn
      Left = 336
      Top = 360
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A NAPT'#193'RHOZ'
      TabOrder = 2
      OnClick = ujnapgombClick
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 16
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
    Left = 80
    Top = 16
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 8
    Top = 48
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 8
    Top = 16
  end
end
