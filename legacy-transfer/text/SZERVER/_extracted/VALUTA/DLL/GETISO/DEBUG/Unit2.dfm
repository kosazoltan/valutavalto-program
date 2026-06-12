object Form2: TForm2
  Left = 440
  Top = 283
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 195
  ClientWidth = 539
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
  object CITIPANEL: TPanel
    Left = 0
    Top = 0
    Width = 537
    Height = 193
    BevelOuter = bvNone
    Color = clActiveCaption
    TabOrder = 0
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 537
      Height = 193
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 40
      Top = 32
      Width = 436
      Height = 25
      Caption = 'V'#193'LASZD KI AZ '#193'LLAMPOLG'#193'RS'#193'GOT '
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Elephant'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object CITICOMBO: TComboBox
      Left = 40
      Top = 72
      Width = 433
      Height = 30
      DropDownCount = 16
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ItemHeight = 22
      ParentFont = False
      TabOrder = 0
      OnChange = CITICOMBOChange
    end
    object CITIOKEGOMB: TBitBtn
      Left = 64
      Top = 144
      Width = 201
      Height = 25
      Cursor = crHandPoint
      Caption = #193'LLAMPOLG'#193'RS'#193'G RENDBEN'
      TabOrder = 1
      OnClick = COUNTRYOKEGOMBClick
    end
    object CITIMEGSEMGOMB: TBitBtn
      Left = 272
      Top = 144
      Width = 201
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM V'#193'LASZTOK'
      TabOrder = 2
      OnClick = COUNTRYMEGSEMGOMBClick
    end
  end
  object ORSZAGPANEL: TPanel
    Left = -666
    Top = 0
    Width = 537
    Height = 193
    BevelOuter = bvNone
    Color = clLime
    TabOrder = 1
    Visible = False
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 537
      Height = 193
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label2: TLabel
      Left = 120
      Top = 24
      Width = 304
      Height = 25
      Caption = 'V'#193'LASZD KI AZ ORSZ'#193'GOT'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Elephant'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object COUNTRYCOMBO: TComboBox
      Left = 48
      Top = 72
      Width = 425
      Height = 30
      DropDownCount = 16
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ItemHeight = 22
      ParentFont = False
      TabOrder = 0
      OnChange = COUNTRYCOMBOChange
    end
    object COUNTRYOKEGOMB: TBitBtn
      Left = 64
      Top = 144
      Width = 201
      Height = 25
      Cursor = crHandPoint
      Caption = 'ORSZ'#193'G RENDBEN'
      TabOrder = 1
      OnClick = COUNTRYOKEGOMBClick
    end
    object COUNTRYMEGSEMGOMB: TBitBtn
      Left = 272
      Top = 144
      Width = 201
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM V'#193'LASZTOK'
      TabOrder = 2
      OnClick = COUNTRYMEGSEMGOMBClick
    end
  end
  object ISOQUERY: TIBQuery
    Database = ISODBASE
    Transaction = ISOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 16
  end
  object ISODBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\ISOCODES.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ISOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 16
  end
  object ISOTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ISODBASE
    AutoStopAction = saNone
    Left = 72
    Top = 16
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 408
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
    Left = 448
    Top = 24
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 488
    Top = 24
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPOTimer
    Left = 24
    Top = 136
  end
end
